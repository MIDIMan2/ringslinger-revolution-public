-- Ringslinger Revolution - Enemy Damage

RSR.ENEMY_LIST = {}

--- Sets the enemy's blink timer and adds it to RSR.ENEMY_THINKERS.
---@param mo mobj_t Enemy to set the blink timer for.
---@param timer tic_t|nil Amount of blink time to give the enemy (Default is TICRATE/3 or 11).
RSR.EnemySetBlink = function(mo, timer)
	if not Valid(mo) then return end
	if timer == nil then timer = TICRATE/3 end

	if not mo.rsrIsThinker then
		table.insert(RSR.ENEMY_THINKERS, mo)
	end
	mo.rsrIsThinker = true
	mo.rsrEnemyBlink = timer
end

--- Gets the health scale based on the enemy's object type
---@param moType mobjtype_t|nil
---@return integer healthScale Default is 30.
RSR.GetEnemyHealthScale = function(moType)
	local healthScale = 30
	if moType and RSR.MOBJ_INFO[moType] and RSR.MOBJ_INFO[moType].health then
		healthScale = (RSR.MOBJ_INFO[moType].health / mobjinfo[moType].spawnhealth)
	end
	return healthScale
end

--- Makes the given enemy face the source and alerts other enemies to their presence.
---@param target mobj_t Enemy to alert.
---@param source mobj_t Player object to target.
RSR.AlertNearbyEnemies = function(target, source)
	if not (Valid(target) and Valid(source)) then return end
	if Valid(target.target) then return end -- Don't run this code if the enemy is already targetting a player

	target.angle = R_PointToAngle2(target.x, target.y, source.x, source.y)
	target.target = source

	local searchRadius = 1024*target.scale

	searchBlockmap("objects", function(targetMo, enemyMo)
		if not (Valid(targetMo) and Valid(enemyMo)) then return end
		-- TODO: There is a bug where enemies that fired at a TNT barrel face nearby exploded enemies
		-- The ideal solution would be to check if enemyMo == source, but "source" is the TNT barrel
		-- Figure out how to prevent that, eventually
		if (enemyMo.flags & (MF_ENEMY|MF_SHOOTABLE)) ~= (MF_ENEMY|MF_SHOOTABLE) then return end
		if Valid(enemyMo.target) then return end

		local distXY = FixedHypot(enemyMo.x - targetMo.x, enemyMo.y - targetMo.y)
		local dist = FixedHypot(distXY, enemyMo.z - targetMo.z)

		if dist > searchRadius then return end

		enemyMo.angle = R_PointToAngle2(enemyMo.x, enemyMo.y, targetMo.x, targetMo.y)
	end, target, target.x - searchRadius, target.x + searchRadius, target.y - searchRadius, target.y + searchRadius)
end

--- Decrements the enemy's health by the damage value given.
---@param target mobj_t
---@param source mobj_t|nil
---@param damage integer
---@param healthScale integer
RSR.EnemyDecrementHealth = function(target, source, damage, healthScale)
	if not (Valid(target) and damage) then return -1, false end
	if not healthScale then healthScale = RSR.GetEnemyHealthScale(target.type) end
	if Valid(source) and Valid(source.player) then RSR.GiveHype(source.player, min(damage, target.rsrHealth)) end
	target.rsrHealth = max(0, $ - damage)

	local triggerPainState = false

	local painChance = RSR.MOBJ_INFO[target.type].painchance
	if painChance == nil then painChance = -1 end

	-- Decrease the target's health until it matches its snapHealth divided by its health scale
	while FixedCeil((target.rsrHealth * FRACUNIT) / healthScale) < target.health * FRACUNIT do
		target.health = $ - 1
		if painChance == -1 then triggerPainState = true end
	end
	if painChance ~= -1 and P_RandomByte() < painChance and not (target.flags2 & MF2_SKULLFLY) then triggerPainState = true end

	return painChance, triggerPainState
end

--- Sets the enemy's health based on damage dealt to it.
---@param target mobj_t Enemy that took damage.
---@param inflictor mobj_t
---@param source mobj_t
---@param damage integer Amount of damage dealt.
---@param damagetype integer Type of damage dealt.
RSR.EnemySetHealth = function(target, inflictor, source, damage, damagetype)
	if not Valid(target) then return end
	if not damage then return end

	local hookEvent, hookName = RSR.findEvent("EnemySetHealth")
	if hookEvent then
		for i, v in ipairs(hookEvent) do
			if hookEvent.typefor ~= nil then
				if hookEvent.typefor(target, v.typedef) == false then continue end
			end
			local result = RSR.tryRunHook(hookName, v, target, inflictor, source, damage, damagetype)
			if result == true then return end
		end
	end

	local healthScale = RSR.GetEnemyHealthScale(target.type)

	-- Handles enemies that regenerate their health
	if not target.rsrHealth and target.health then
		target.rsrHealth = target.health*healthScale
		target.rsrSpawnHealth = target.rsrHealth
		target.rsrKilled = nil
	end

	if target.rsrHealth > target.health * healthScale then
		target.rsrHealth = target.health * healthScale
	end

	local painChance, triggerPainState = RSR.EnemyDecrementHealth(target, source, damage, healthScale)

	if target.health < 1 or target.rsrHealth < 1 then
		target.rsrKilled = true
		if (target.flags & MF_MISSILE) then
			P_ExplodeMissile(target)
		else
			P_KillMobj(target, inflictor, source, damagetype)
		end
		if Valid(source) and Valid(source.player) then RSR.GiveHype(source.player, 50) end -- Give a 50 hype bonus for killing an enemy
	else
		RSR.EnemySetBlink(target)
		if not triggerPainState and painChance == -1 then S_StartSound(target, sfx_dmpain) end
		RSR.AlertNearbyEnemies(target, source)

		if not (RSR.MOBJ_INFO[target.type] and RSR.MOBJ_INFO[target.type].nopainstate) then
			if triggerPainState and target.info.painstate then
				target.state = target.info.painstate
				target.flags2 = $|MF2_FRET
			end
		end
	end
end

--- ShouldDamage hook code for enemies.
---@param target mobj_t
---@param inflictor mobj_t
---@param source mobj_t
---@param damage integer
---@param damagetype integer
RSR.EnemyShouldDamage = function(target, inflictor, source, damage, damagetype)
	if not RSR.GamemodeActive() then return end -- Only run this code in Ringslinger Revolution maps
	if not (Valid(target) and (target.flags & (MF_ENEMY|MF_BOSS))) then return end -- Only run this hook for enemies and bosses
	if Valid(target.player) then return end -- Don't override the player's ShouldDamage hook

	local hookEvent, hookName = RSR.findEvent("EnemyShouldDamage")
	if hookEvent then
		for i, v in ipairs(hookEvent) do
			if hookEvent.typefor ~= nil then
				if hookEvent.typefor(target, v.typedef) == false then continue end
			end
			local result = RSR.tryRunHook(hookName, v, target, inflictor, source, damage, damagetype)
			if result then return end
		end
	end

	local rsrDamage = false
	local inflictorIsPlayer = false

	if Valid(inflictor) then
		if Valid(inflictor.player) then
			inflictorIsPlayer = true
		elseif RSR.MOBJ_INFO[inflictor.type] and RSR.MOBJ_INFO[inflictor.type].damage and (Valid(source) and Valid(source.player)) then
			-- Makes projectiles fired from players deal custom damage
			damage = RSR.MOBJ_INFO[inflictor.type].damage
			rsrDamage = true
		end

		if inflictor.rsrProjectile or inflictor.rsrDamage or inflictor.rsrRealDamage then
			rsrDamage = true
		end
	end

	if not rsrDamage then
		damage = 10

		if damagetype ~= DMG_NUKE then
			if target.rsrEnemyBlink then
				return false
			end
		end

		if inflictorIsPlayer then
			-- Fixes a bug where using an Armageddon Shield makes the player bounce off of the air
			if damagetype == DMG_NUKE then
				damage = RSR.GetArmageddonDamage(target, inflictor)
			elseif RSR.HasPowerup(inflictor.player, RSR.POWERUP_INVINCIBILITY) or inflictor.player.powers[pw_super] then
				damage = RSR.MOBJ_INFO[target.type].health / target.info.spawnhealth
			end
		else
			return
		end
	end

	RSR.EnemySetHealth(target, inflictor, source, damage, damagetype)

	return false
end

--- TouchSpecial hook code for enemies.
---@param special mobj_t
---@param toucher mobj_t
RSR.EnemyTouchSpecial = function(special, toucher)
	if not RSR.GamemodeActive() then return end -- Only run this code in Ringslinger Revolution maps
	if not (Valid(special) and Valid(toucher)) then return end

	local hookEvent, hookName = RSR.findEvent("EnemyTouchSpecial")
	if hookEvent then
		for i, v in ipairs(hookEvent) do
			if hookEvent.typefor ~= nil then
				if hookEvent.typefor(special, v.typedef) == false then continue end
			end
			local result = RSR.tryRunHook(hookName, v, special, toucher)
			if result then return end
		end
	end

	---@type player_t
	local player = toucher.player
	if not Valid(player) then return end

	-- Fixes a bug where the player can get stuck in an enemy while jumping/spinning into it
	if (special.flags & (MF_ENEMY|MF_BOSS)) and (special.rsrEnemyBlink) then return true end

	if P_PlayerCanDamage(player, special) then
		if (special.type == MT_PTERABYTE and special.target == toucher and special.extravalue1) then return end -- Can't hurt a Pterabyte if it's trying to pick you up

		if (player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT and (player.pflags & PF_SHIELDABILITY) then
			player.pflags = $ & ~PF_SHIELDABILITY -- Make the Attraction Shield chainable
			player.secondjump = UINT8_MAX
		end
		player.homing = 0 -- Make the Attraction Shield not constantly lock on to the enemy

		if special.info.spawnhealth < 2 then
			toucher.momx = -$
			toucher.momy = -$
			if player.charability == CA_FLY and player.panim == PA_ABILITY then
				toucher.momz = -$/2
			elseif (player.pflags & PF_GLIDING) and not P_IsObjectOnGround(toucher) then
				player.pflags = $ & ~(PF_GLIDING|PF_JUMPED|PF_NOJUMPDAMAGE)
				toucher.state = S_PLAY_FALL
				toucher.momz = $ + (P_MobjFlip(toucher) * (player.speed / 8))
				toucher.momx = 7*$/8
				toucher.momy = 7*$/8
				-- Hack to prevent the gliding player from getting hurt when hitting the enemy at certain angles
				P_DamageMobj(special, toucher, toucher, 1, 0)
				player.powers[pw_flashing] = 1
			elseif player.powers[pw_strong] & STR_DASH and player.panim == PA_DASH then
				P_DoPlayerPain(player, special, special)
				-- Hack to prevent the dashing player from not dealing damage at all
				P_DamageMobj(special, toucher, toucher, 1, 0)
			end
		end
	end
end

--- Adds the given Object type to the list of enemies in RSR, automatically applying the necessary hooks to them. Must be called in an AddonLoaded hook.
---@param enemyType mobjtype_t
RSR.AddEnemyHooks = function(enemyType)
	if not enemyType then return end
	if RSR.ENEMY_LIST[enemyType] then return end

	-- TODO: Integrate RSR.MOBJ_INFO into this?

	addHook("ShouldDamage", RSR.EnemyShouldDamage, enemyType)
	addHook("TouchSpecial", RSR.EnemyTouchSpecial, enemyType)

	RSR.ENEMY_LIST[enemyType] = true
end

addHook("AddonLoaded", function()
	-- *** IMPORTANT ***
	-- Keep this consistent with the enemies in MOBJ_INFO
	RSR.AddEnemyHooks(MT_BLUECRAWLA)
	RSR.AddEnemyHooks(MT_REDCRAWLA)
	RSR.AddEnemyHooks(MT_GFZFISH)
	RSR.AddEnemyHooks(MT_GOLDBUZZ)
	RSR.AddEnemyHooks(MT_REDBUZZ)
	RSR.AddEnemyHooks(MT_DETON)
	RSR.AddEnemyHooks(MT_POPUPTURRET)
	RSR.AddEnemyHooks(MT_SPRINGSHELL)
	RSR.AddEnemyHooks(MT_YELLOWSHELL)
	RSR.AddEnemyHooks(MT_SKIM)
	RSR.AddEnemyHooks(MT_JETJAW)
	RSR.AddEnemyHooks(MT_CRUSHSTACEAN)
	RSR.AddEnemyHooks(MT_BANPYURA)
	RSR.AddEnemyHooks(MT_ROBOHOOD)
	RSR.AddEnemyHooks(MT_FACESTABBER)
	RSR.AddEnemyHooks(MT_EGGGUARD)
	RSR.AddEnemyHooks(MT_VULTURE)
	RSR.AddEnemyHooks(MT_GSNAPPER)
	RSR.AddEnemyHooks(MT_MINUS)
	RSR.AddEnemyHooks(MT_CANARIVORE)
	RSR.AddEnemyHooks(MT_UNIDUS)
	RSR.AddEnemyHooks(MT_PTERABYTE)
	RSR.AddEnemyHooks(MT_PYREFLY)
	RSR.AddEnemyHooks(MT_DRAGONBOMBER)
	RSR.AddEnemyHooks(MT_JETTBOMBER)
	RSR.AddEnemyHooks(MT_JETTGUNNER)
	RSR.AddEnemyHooks(MT_SPINCUSHION)
	RSR.AddEnemyHooks(MT_SNAILER)
	RSR.AddEnemyHooks(MT_PENGUINATOR)
	RSR.AddEnemyHooks(MT_POPHAT)
	RSR.AddEnemyHooks(MT_CRAWLACOMMANDER)
	RSR.AddEnemyHooks(MT_SPINBOBERT)
	RSR.AddEnemyHooks(MT_CACOLANTERN)
	RSR.AddEnemyHooks(MT_HANGSTER)
	RSR.AddEnemyHooks(MT_HIVEELEMENTAL)
	RSR.AddEnemyHooks(MT_BUMBLEBORE)
	RSR.AddEnemyHooks(MT_BUGGLE)
	RSR.AddEnemyHooks(MT_POINTY)
	RSR.AddEnemyHooks(MT_EGGMOBILE)
	RSR.AddEnemyHooks(MT_EGGMOBILE2)
	RSR.AddEnemyHooks(MT_EGGMOBILE3)
	RSR.AddEnemyHooks(MT_EGGMOBILE4)
	RSR.AddEnemyHooks(MT_FANG)
	RSR.AddEnemyHooks(MT_METALSONIC_BATTLE)
	RSR.AddEnemyHooks(MT_BLACKEGGMAN)
 	RSR.AddEnemyHooks(MT_CYBRAKDEMON)
	RSR.AddEnemyHooks(MT_CYBRAK2016)
end)
