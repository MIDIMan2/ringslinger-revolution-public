---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Player Health System

RSR.HOMING_THRESHOLD_THOK = 40
RSR.HOMING_THRESHOLD_ATTRACT = 45

RSR.HITSOUND_HIT = 1
RSR.HITSOUND_ARMOR = 2
RSR.HITSOUND_BREAK = 3
RSR.HITSOUND_INVIN = 4
RSR.HITSOUND_ASSIST = 5
RSR.HITSOUND_KILL = 6

RSR.HITSOUND_TO_SFX = {
	[RSR.HITSOUND_HIT] = sfx_rsrhit,
	[RSR.HITSOUND_ARMOR] = sfx_rsrarm,
	[RSR.HITSOUND_BREAK] = sfx_rsrinv,
	[RSR.HITSOUND_INVIN] = sfx_rsriht,
	[RSR.HITSOUND_ASSIST] = sfx_rsrast,
	[RSR.HITSOUND_KILL] = sfx_rsrkil
}

RSR.DEATH_REMOVEDEATHMASK = 1
RSR.DEATH_MAKESPECTATOR = 2

addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end

	if mo.z + mo.momz <= mo.floorz or mo.z + mo.height + mo.momz >= mo.ceilingz then
		mo.momz = -$
	end
end, MT_RSR_DAMAGE_SPLATTER)

addHook("MobjMoveBlocked", function(mo)
	if not Valid(mo) then return end

	-- Make sure the damage splatter maintains the same speed it had before it bounced off the wall
	local oldSpeed = FixedHypot(FixedHypot(mo.momx, mo.momy), mo.momz)
	P_BounceMove(mo)
	local newSpeed = FixedHypot(FixedHypot(mo.momx, mo.momy), mo.momz)

	if oldSpeed and newSpeed then
		local scale = FixedDiv(oldSpeed, newSpeed)

		mo.momx = FixedMul($, scale)
		mo.momy = FixedMul($, scale)
		mo.momz = FixedMul($, scale)
	end

	return true
end, MT_RSR_DAMAGE_SPLATTER)

mobjinfo[MT_RSR_DAMAGE_SPLATTER] = {
	doomednum = -1,
	spawnstate = S_RSR_DAMAGE_SPLATTER,
	speed = 15*FRACUNIT,
	radius = 16*FRACUNIT,
	height = 32*FRACUNIT,
	flags = MF_NOBLOCKMAP|MF_NOGRAVITY -- I would add MF_SCENERY, but MobjMoveBlocked doesn't run for MF_SCENERY objects...
}

states[S_RSR_DAMAGE_SPLATTER] =	{SPR_THOK,	A|FF_TRANS50,	64,	nil,	0,	0,	S_NULL}

--- Spawns a bucnh of splatter particles from the Object. Higher damage means more and bigger particles.
---@param target mobj_t
---@param damage integer
RSR.SpawnDamageSplatter = function(target, damage)
	if not Valid(target) then return end
	if not damage then return end

	local tensScale = damage/10
	for i = 0, 3 + tensScale do
		local bleed = P_SpawnMobjFromMobj(target, 0, 0, target.info.height/2, MT_RSR_DAMAGE_SPLATTER)
		if Valid(bleed) then
			bleed.dontdrawforviewmobj = target -- Prevents the splatter from obscuring the player's view in first-person
			bleed.color = target.color -- Make the splatter's color match that of its source
-- 			if tensScale <= 4 or P_RandomKey(1) then
-- 				bleed.scale = $/2
-- 			end

			-- Tiered damage fades based on severity of damage taken
			if damage < 16 then -- Hit by "standard" ring/melee attack
				bleed.scale = FixedMul($, RSR.RandomFixedRange(FRACUNIT/4, FRACUNIT/3))
			elseif damage < 49 then -- Hit by "empowered" ring/melee attack
				bleed.scale = FixedMul($, RSR.RandomFixedRange(FRACUNIT/3, FRACUNIT/2))
			elseif damage < 100 then -- Exploded
				bleed.scale = FixedMul($, RSR.RandomFixedRange(FRACUNIT/2, FRACUNIT))
			else -- Something has gone terribly, terribly wrong
				bleed.scale = FixedMul($, RSR.RandomFixedRange(FRACUNIT, 3*FRACUNIT/2))
			end

			-- Randomize the splatter's momentum
			bleed.momx = RSR.RandomFixedRange(bleed.scale, 5*bleed.scale)
			bleed.momy = RSR.RandomFixedRange(bleed.scale, 5*bleed.scale)
			bleed.momz = RSR.RandomFixedRange(0, 5*bleed.scale)
			if P_RandomChance(FRACUNIT/2) then bleed.momx = -$ end
			if P_RandomChance(FRACUNIT/2) then bleed.momy = -$ end
			if P_RandomChance(FRACUNIT/2) then bleed.momz = -$ end

			-- Make the splatter shrink to scale 0 in roughly 3 seconds
			bleed.scalespeed = bleed.scale/64
			bleed.destscale = 0
			bleed.tics = 64
		end
	end
end

--- Initializes the player's health system
---@param player player_t
RSR.PlayerHealthInit = function(player)
	if not (Valid(player) and player.rsrinfo) then return end
	local rsrinfo = player.rsrinfo

	rsrinfo.health = RSR.MAX_HEALTH
-- 	rsrinfo.health = 1 -- For testing purposes only
	rsrinfo.armor = 0

	rsrinfo.hype = 0

	rsrinfo.hurtByEnemy = 0
	rsrinfo.hurtByMelee = 0
	rsrinfo.hurtByMap = 0
	rsrinfo.attackKnockback = false
	rsrinfo.hitSound = 0
	rsrinfo.deathFlags = 0
	rsrinfo.attackerInfo = {}
	rsrinfo.knockedByAttacker = false -- TODO: Maybe remove this since it's not being used for assists anymore???

	if G_RingSlingerGametype() then -- Replaces the Pity Shield with a "pity armor start" feature
		if (player.powers[pw_shield] & SH_NOSTACK) then
			rsrinfo.armor = $ + 25
			P_RemoveShield(player) -- Don't spawn with a shield in deathmatch
		end
	end
end

--- Handles damage timers for the player.
---@param player player_t
RSR.PlayerDamageTick = function(player)
	if not (Valid(player) and player.rsrinfo) then return end
	local rsrinfo = player.rsrinfo

	if rsrinfo.hurtByEnemy > 0 then rsrinfo.hurtByEnemy = max(0, $-1) end
	if rsrinfo.hurtByMelee > 0 then rsrinfo.hurtByMelee = max(0, $-1) end
	if rsrinfo.hurtByMap > 0 then rsrinfo.hurtByMap = max(0, $-1) end
	if rsrinfo.attackKnockback then rsrinfo.attackKnockback = false end
	if rsrinfo.hitSound then
		if RSR.HITSOUND_TO_SFX[rsrinfo.hitSound] then
			S_StartSound(nil, RSR.HITSOUND_TO_SFX[rsrinfo.hitSound], player)
		end
		rsrinfo.hitSound = 0
	end
	-- Remove invalid players from attackerInfo
	local i = 1
	while i <= #rsrinfo.attackerInfo do
		local info = rsrinfo.attackerInfo[i]
		if not info then i = $+1; continue end
		if not Valid(info.player) then
			table.remove(rsrinfo.attackerInfo, i)
			continue
		end
		i = $+1
	end
	if rsrinfo.knockedByAttacker then
		if Valid(player.mo) and P_IsObjectOnGround(player.mo) and FixedHypot(player.rmomx, player.rmomy) < 20*player.mo.scale then
			rsrinfo.knockedByAttacker = false
		end
	end
end

--- Adds an attacker to the player's table of attackers
---@param player player_t
---@param attacker player_t
---@param damage integer
RSR.PlayerAddAttacker = function(player, attacker, damage)
	if not (Valid(player) and player.rsrinfo and Valid(attacker) and damage) then return end
	if not player.rsrinfo.attackerInfo then return end
	if player == attacker or RSR.PlayersAreTeammates(player, attacker) then return end -- Don't add teammates or yourself to the list

	-- Make sure the attacker hasn't already been added to attackerInfo
	local prevDamage = 0
	for key, info in ipairs(player.rsrinfo.attackerInfo) do
		if not info then continue end
		if Valid(info.player) and info.player == attacker then
			prevDamage = info.damage
			table.remove(player.rsrinfo.attackerInfo, key)
			break
		end
	end

	player.rsrinfo.knockedByAttacker = true
	table.insert(player.rsrinfo.attackerInfo, 1, {
		player = attacker,
		damage = prevDamage + damage
	})
end

--- Helper function for getting the damage value of a given inflictor.
---@param target mobj_t
---@param inflictor mobj_t
---@param source mobj_t
---@param damagetype integer
RSR.GetInflictorDamage = function(target, inflictor, source, damage, damagetype)
	if not (Valid(target) and Valid(inflictor)) then return end

	local damageInfo = {
		damage = damage,
		infInfo = RSR.MOBJ_INFO[inflictor.type],
		hurtByEnemy = false,
		hurtByMelee = false,
		knockbackScale = FRACUNIT
	}

	if inflictor.rsrProjectile then -- The inflictor is an RSR-registered projectile
		-- ProjectileMoveCollide already sets the damage value, but we'll do it again just in case
		if not inflictor.rsrDamage then -- rsrDamage is used by the bounce ring to determine how much damage is dealt, so don't override it
			damageInfo.damage = inflictor.info.damage -- Maybe use MOBJ_INFO damage here???
		end
	elseif Valid(inflictor.player) then -- The inflictor is a player
		if damagetype == DMG_NUKE then
			damageInfo.damage = RSR.GetArmageddonDamage(target, inflictor)
		else
			damageInfo.hurtByMelee = true
		end
	elseif not inflictor.rsrRealDamage then -- The inflictor is something else
		if damageInfo.infInfo and damageInfo.infInfo.damage ~= nil then
			damageInfo.damage = damageInfo.infInfo.damage
		else
			damageInfo.damage = 15
		end

		-- Player-fired projectiles should always be treated as RSR projectiles
		if not (Valid(source) and Valid(source.player)) then
			damageInfo.hurtByEnemy = true
		end
	end

	-- Set the knockback scale if RSR.MOBJ_INFO has one
	if damageInfo.infInfo and damageInfo.infInfo.knockback ~= nil then
		damageInfo.knockbackScale = damageInfo.infInfo.knockback
	end

	return damageInfo
end

--- MobjDamage hook code for player Objects.
---@param target mobj_t
---@param inflictor mobj_t
---@param source mobj_t
---@param damage integer
---@param damagetype integer
RSR.PlayerDamage = function(target, inflictor, source, damage, damagetype)
	if not RSR.GamemodeActive() then return end
	if not Valid(target) then return end
	if target.health <= 0 then return end
	local player = target.player

	if RSR.SKIN_INFO[target.skin] and RSR.SKIN_INFO[target.skin].nodamage then return end

	-- Don't run this code if the target is not a player in RSR
	if not (Valid(player) and player.rsrinfo) then return end

	-- Don't run this code if DMG_DEATHMASK is in effect
	if ((damagetype or 0) & DMG_DEATHMASK) then return end

	local knockbackScale = FRACUNIT

	local hurtByEnemy = false
	local hurtByMelee = false
	local infInfo = nil

	if Valid(inflictor) then
		local damageInfo = RSR.GetInflictorDamage(target, inflictor, source, damage, damagetype)
		if damageInfo then
			damage = damageInfo.damage
			infInfo = damageInfo.infInfo
			hurtByEnemy = damageInfo.hurtByEnemy
			hurtByMelee = damageInfo.hurtByMelee
			knockbackScale = damageInfo.knockbackScale
		end
	end

	-- Set hurt timers for certain conditions
	if hurtByEnemy then player.rsrinfo.hurtByEnemy = TICRATE end
	if hurtByMelee then player.rsrinfo.hurtByMelee = TICRATE end

	local saved = 0
	-- local shieldSaved = 0
	local rsrinfo = player.rsrinfo
	local hurtSound = sfx_rsrhrt
	local serverHurtSound = sfx_rsrpmp

	-- Multiply damage taken by 1.5x if the player has a flag or is a runner in Tag gametypes
	-- TODO: Make a sound indicator for this??
	if ((gametyperules & GTR_TEAMFLAGS) and player.gotflag)
	or (G_TagGametype() and not (player.pflags & PF_TAGIT)) then
		damage = FixedMul($, 3*FRACUNIT/2)
	end

	local shield = (player.powers[pw_shield] & SH_NOSTACK)

	-- Handles Attraction Shield homing break
	if player.rsrinfo.homing then
		-- Tracks how much damage you've accumulated through your lock-on
		player.rsrinfo.homingThreshold = $ + damage

		-- If you exceed the break threshold, revokes Maxwell's equations for electromagnetism, plays a sound to let everyone nearby know of that, and cancels your melee hurtbox 
		if shield == SH_ATTRACT and (player.pflags & PF_SHIELDABILITY) then
			if (player.rsrinfo.homingThreshold > RSR.HOMING_THRESHOLD_ATTRACT) or (player.rsrinfo.armor < 1) then
				P_ResetPlayer(player)
				player.rsrinfo.homing = 0
				S_StartSound(player.mo, sfx_s3ka6)
				target.state = S_PLAY_PAIN
				P_SetObjectMomZ(player.mo, 8*FRACUNIT)
			end
		elseif player.charability == CA_HOMINGTHOK then
			if player.rsrinfo.homingThreshold > RSR.HOMING_THRESHOLD_THOK then
				P_ResetPlayer(player)
				player.rsrinfo.homing = 0
				S_StartSound(player.mo, sfx_s3k90)
				target.state = S_PLAY_PAIN
				P_SetObjectMomZ(player.mo, 4*FRACUNIT)
			end
		end
	end

	RSR.SpawnDamageSplatter(target, damage)

	-- Reroute all damage to hype while super
	if player.powers[pw_super] then
		rsrinfo.hype = max($ - (damage*2), 0)
		damage = 0
	-- Otherwise the player loses a bit of hype every time they take damage
	else
		rsrinfo.hype = max($ - damage/2, 0)
	end
	local hadArmor = false
	-- Attraction Shield grants you damage resistance
	if shield == SH_ATTRACT then
		damage = $ * 3 / 4
	end
	-- Health saving while you have armor
	if rsrinfo.armor and not player.powers[pw_super] then
		saved = damage/2

		-- (DEPRECATED) Attraction Shield is less affected by armor loss than other shields (it still only saves the same amount of health though)
		-- if (player.powers[pw_shield] & SH_ATTRACT) then
		--	shieldSaved = saved * 3 / 4
		-- else
		--	shieldSaved = saved
		-- end

		saved = min($, rsrinfo.armor)

		rsrinfo.armor = max($ - saved, 0) -- Make sure armor doesn't go below 0
		if rsrinfo.armor < 1 then -- If the player runs out of armor, play the shieldbreak sound
			hadArmor = true
			S_StartSound(player.mo, sfx_rsrcrk)
		else
			hurtSound = sfx_rsraht
			serverHurtSound = sfx_rsrsmp
		end
		damage = $ - saved

		if Valid(inflictor) then
			for i = 0, 3 do
				local spark = P_SpawnMobjFromMobj(target, 0, 0, FixedDiv(target.height, target.scale)/2, MT_SUPERSPARK)
				if Valid(spark) then
					spark.dontdrawforviewmobj = target
					spark.scale = FixedMul($, 2*FRACUNIT/3)
					-- Randomize the spark's momentum
					spark.momx = RSR.RandomFixedRange(spark.scale, 16*spark.scale)
					spark.momy = RSR.RandomFixedRange(spark.scale, 16*spark.scale)
					spark.momz = RSR.RandomFixedRange(0, 16*spark.scale)
					if P_RandomChance(FRACUNIT/2) then spark.momx = -$ end
					if P_RandomChance(FRACUNIT/2) then spark.momy = -$ end
					if P_RandomChance(FRACUNIT/2) then spark.momz = -$ end

					-- Make the spark shrink to scale 0 in roughly 1/3rd of a second
					spark.scalespeed = spark.scale/12
					spark.destscale = 0
					spark.tics = 12
				end
			end
		end
	end

	-- Use this for giving hype on hit and armor to players who manually detonated their Armageddon Shield
	local damageReal = min(damage, rsrinfo.health)

	rsrinfo.health = max($ - damage, 0) -- Make sure health doesn't go below 0

	if Valid(source) and Valid(source.player) then
		RSR.PlayerAddAttacker(player, source.player, damage)
		-- Give the source player an armor boost if the damage was from a manually detonated Armageddon Blast
		if damagetype == DMG_NUKE and (source.player.pflags & PF_SHIELDABILITY) and source.player.rsrinfo.armor > 0 then
			RSR.GiveArmor(source.player, damageReal)
			RSR.BonusFade(source.player)
			S_StartSound(nil, sfx_shield, source.player)
		end
		-- Give the source player hype if they have all the emeralds
		RSR.GiveHype(source.player, damageReal) -- Emerald check is handled in the function itself
	end

	-- Tiered damage fades based on severity of damage taken
	if damage < 16 then -- Hit by "standard" ring/melee attack
		RSR.SetScreenFade(player, 35, FRACUNIT/2, TICRATE/3)
	elseif damage < 49 then -- Hit by "empowered" ring/melee attack
		RSR.SetScreenFade(player, 35, FRACUNIT/2, TICRATE/2)
	elseif damage < 100 then -- Exploded
		RSR.SetScreenFade(player, 35, FRACUNIT, TICRATE/2)
	else -- Something has gone terribly, terribly wrong
		RSR.SetScreenFade(player, 35, FRACUNIT, TICRATE)
	end

	if shield then
		-- Reflect projectiles if the player has a Force Shield (also causes homing rings to rebel against their master)
		if (player.powers[pw_shield] & SH_FORCE) and Valid(inflictor) and (inflictor.flags & MF_MISSILE)
		and not ((infInfo and (infInfo.dontreflect or infInfo.explosive)) or (inflictor.flags & (MF_ENEMY|MF_GRENADEBOUNCE))) then
			RSR.SpawnReflectedMissile(target, inflictor)
		end

		-- Reduce knockback if the player has a Whirlwind Shield
		if shield == SH_WHIRLWIND and Valid(inflictor) and (inflictor.flags & MF_MISSILE) and not (infInfo and infInfo.explosive) then
			knockbackScale = $/2
		end

		-- Remove shields and auto-det Armageddon when shields or health fall below 1
		if rsrinfo.armor < 1 or rsrinfo.health < 1 then
			if shield then -- Only play the sound if the player had a shield
				hurtSound = sfx_shldls
				serverHurtSound = sfx_shldls
			end
			if (player.powers[pw_shield] & SH_FORCEHP) then
				player.powers[pw_shield] = $ & ~SH_FORCEHP
			end
			if shield == SH_ARMAGEDDON then
				P_BlackOw(player)
			end
			P_RemoveShield(player)
		end
	end

	-- TODO: Insert code for rumble support here when it gets exposed to Lua

	-- Apply knockback to the target if the inflictor allows it
	if Valid(inflictor) and not inflictor.rsrDontThrust
	and (not player.rsrinfo.homing or (player.rsrinfo.homing and Valid(inflictor.player) and inflictor.player.rsrinfo and inflictor.player.rsrinfo.homing)) then
		local ang = R_PointToAngle2(inflictor.x, inflictor.y, target.x, target.y)
		if FixedHypot(FixedHypot(inflictor.x - target.x, inflictor.y - target.y), inflictor.z - target.z) < FRACUNIT then
			ang = target.angle + ANGLE_180
		end
		local thrust = damage * (FRACUNIT / (2^3)) * 100 / 100 -- Originally divided by target.info.mass

		P_Thrust(target, ang, FixedMul(knockbackScale, thrust))

		-- Knock the player into the air if they were melee'd by another player
		if Valid(inflictor.player) and damagetype ~= DMG_NUKE then
			P_ResetPlayer(player)
			target.z = $+P_MobjFlip(target)
			target.state = S_PLAY_PAIN
			if shield == SH_WHIRLWIND then -- Whirlwind melee knockback halving
				P_SetObjectMomZ(target, 4*FRACUNIT)
			else
				P_SetObjectMomZ(target, 8*FRACUNIT)
			end
			if player.rsrinfo.attackKnockback then
				if inflictor.player.rsrinfo and inflictor.player.rsrinfo.attackKnockback then
					S_StartSound(target, sfx_s3k90)
				end
				target.momx = -$/2
				target.momy = -$/2
				player.rsrinfo.attackKnockback = false
			else
				local meleeMom = FixedHypot(inflictor.momx, inflictor.momy)
				if shield == SH_WHIRLWIND then -- Whirlwind melee knockback halving
					P_Thrust(target, ang, FixedMul(knockbackScale/2, meleeMom/4))
				else
					P_Thrust(target, ang, FixedMul(knockbackScale, meleeMom/2))
				end
			end
		end

		-- So the player can get flung during death
		target.rsrPrevMomX = target.momx
		target.rsrPrevMomY = target.momy
		target.rsrPrevMomZ = target.momz - P_MobjFlip(target)*FixedMul(7*FRACUNIT, target.scale) -- Negate SOME of the upward fling we get from dying normally

		-- Do this to prevent the player from standing still when thrusted while not moving
		player.rmomx = target.momx + player.cmomx
		player.rmomy = target.momy + player.cmomy
	end

	if rsrinfo.health <= 0 then
		player.powers[pw_shield] = SH_NONE
		player.rings = 0
		if G_IsSpecialStage(gamemap) then return RSR.PlayerForceDeath(player, inflictor, source, damage, damagetype) end
		return
	end

	if P_IsLocalPlayer(player) then
		S_StartSound(nil, hurtSound, player)
	else
		S_StartSound(target, serverHurtSound)
	end
	if Valid(source) and Valid(source.player) and source.player.rsrinfo
	and source.player ~= player and not RSR.PlayersAreTeammates(player, source.player) then
		if rsrinfo.armor > 0 then
			source.player.rsrinfo.hitSound = RSR.HITSOUND_ARMOR
		else
			if hadArmor then
				source.player.rsrinfo.hitSound = RSR.HITSOUND_BREAK
			elseif not source.player.rsrinfo.hitSound then -- Don't interrupt armor hitsounds
				source.player.rsrinfo.hitSound = RSR.HITSOUND_HIT
			end
		end
	end
	return true
end

--- Forces player death with DMG_DEATHMASK if the player's health is less than 0.
---@param player player_t
---@param inflictor mobj_t
---@param source mobj_t
---@param damage integer
---@param damagetype integer
RSR.PlayerForceDeath = function(player, inflictor, source, damage, damagetype)
	if not Valid(player) then return end
	damagetype = $ or 0

	if player.rsrinfo.health > 0 then
		return false
	else
		-- Force death if the player's health is 0
		if not (damagetype & DMG_DEATHMASK) then
-- 			player.rsrinfo.removeDeathMask = true
			player.rsrinfo.deathFlags = $|RSR.DEATH_REMOVEDEATHMASK
		end
		-- This is an ugly hack to get around SRB2 not tagging the hider if Amy's hearts are the inflictor
		if Valid(inflictor) and inflictor.type == MT_LHRT then
			player.rsrinfo.forceInflictorType = MT_LHRT
			player.rsrinfo.forceInflictorReflected = inflictor.rsrForceReflected
			inflictor = source
		end
		P_DamageMobj(player.mo, inflictor, source, damage, damagetype|DMG_DEATHMASK)
		return true
	end
end

--- Hacky function that forces player death when the vanilla game can't.
---@param player player_t
---@param inflictor mobj_t
---@param source mobj_t
---@param damage integer
---@param damagetype integer
RSR.PlayerSourceShouldDamage = function(player, inflictor, source, damage, damagetype)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end
	if not Valid(source) then
		return (player.powers[pw_super] and true) or nil
	end

	if Valid(source.player) and RSR.PlayersAreTeammates(player, source.player) then
		if player == source.player or not RSR.CheckFriendlyFire() then -- If the player is not damaging themselves and friendly fire is not enabled, don't deal damage
			return false
		else -- Otherwise, force damage and (possibly) death
			return true
		end
	end

	-- Force Tag gametypes to use RSR's health system
	if G_TagGametype() then
		if not ((player.pflags & PF_TAGIT) and not RSR.CV_LaserTag.value) then
			RSR.PlayerDamage(player.mo, inflictor, source, damage, damagetype)
		end
		return RSR.PlayerForceDeath(player, inflictor, source, damage, damagetype)
	end

	-- Force Special Stages to use RSR's health system
	if G_IsSpecialStage(gamemap) then
		RSR.PlayerDamage(player.mo, inflictor, source, damage, damagetype)
		return RSR.PlayerForceDeath(player, inflictor, source, damage, damagetype)
	end

	-- Force Amy's hearts to deal damage to other players
	if Valid(inflictor) and inflictor.type == MT_LHRT then return true end
	-- Force damage while super
	if player.powers[pw_super] then return true end
end

--- ShouldDamage hook code for players.
---@param target mobj_t Target of the damage.
---@param inflictor mobj_t Inflictor of the damage.
---@param source mobj_t Source of the damage.
---@param damage integer Amount of damage dealt to the target.
---@param damagetype integer Type of damage inflicted onto the target (DMG_ constants).
RSR.PlayerShouldDamage = function(target, inflictor, source, damage, damagetype)
	if not RSR.GamemodeActive() then return end
	if not Valid(target) then return end
	damagetype = $ or 0 -- TODO: See if this is even necessary

	if RSR.SKIN_INFO[target.skin] and RSR.SKIN_INFO[target.skin].nodamage then return end

	local player = target.player
	if not (Valid(player) and player.rsrinfo) then return end
	local rsrinfo = player.rsrinfo

	if (player.pflags & PF_GODMODE) or player.exiting then return end

	if (damagetype & DMG_DEATHMASK) then
		-- No crazy shenanigans if the player drowned, fell down a pit, etc.
		if not (Valid(inflictor) or Valid(source))
		and not (damagetype == DMG_INSTAKILL and (rsrinfo.deathFlags & RSR.DEATH_REMOVEDEATHMASK)) then
			target.rsrPrevMomX = 0
			target.rsrPrevMomY = 0
			target.rsrPrevMomZ = 0
		end
		return
	end

	if player.powers[pw_flashing]
	or (player.powers[pw_invulnerability] and not player.powers[pw_super])
	or (player.powers[pw_strong] & STR_GUARD) then
		if player.powers[pw_invulnerability] and Valid(inflictor) then
			if not Valid(inflictor.player) then -- Only works for projectiles, not melee or terrain
				S_StartSound(target, sfx_rsrpng)
				if Valid(source) and Valid(source.player) and source.player.rsrinfo then
					source.player.rsrinfo.hitSound = RSR.HITSOUND_INVIN
				end
				for i = 0, 3 do
					local spark = P_SpawnMobjFromMobj(target, 0, 0, FixedDiv(target.height, target.scale)/2, MT_UNKNOWN)
					if Valid(spark) then
						spark.state = S_RSR_INVINSPARKLE
						spark.dontdrawforviewmobj = target
						-- Randomize the spark's momentum
						spark.momx = RSR.RandomFixedRange(spark.scale, 16*spark.scale)
						spark.momy = RSR.RandomFixedRange(spark.scale, 16*spark.scale)
						spark.momz = RSR.RandomFixedRange(0, 16*spark.scale)
						if P_RandomChance(FRACUNIT/2) then spark.momx = -$ end
						if P_RandomChance(FRACUNIT/2) then spark.momy = -$ end
						if P_RandomChance(FRACUNIT/2) then spark.momz = -$ end
					end
				end
			elseif Valid(inflictor.player) and inflictor.player.powers[pw_invulnerability]
			and rsrinfo.attackKnockback and not rsrinfo.hurtByMelee then
				-- Hopefully putting these two lines at the top will fix C stack overflow issues
				rsrinfo.attackKnockback = false
				rsrinfo.hurtByMelee = TICRATE
				P_ResetPlayer(player)
				target.z = $+P_MobjFlip(target)
				target.state = S_PLAY_PAIN
				if (player.powers[pw_shield] & SH_NOSTACK) == SH_WHIRLWIND then -- Whirlwind melee knockback halving
					P_SetObjectMomZ(target, 4*FRACUNIT)
				else
					P_SetObjectMomZ(target, 8*FRACUNIT)
				end
				if inflictor.player.rsrinfo and inflictor.player.rsrinfo.attackKnockback then
					S_StartSound(target, sfx_s3k90)
				end
				target.momx = -$/2
				target.momy = -$/2
			end
		end
		return false -- This is required for special stages
	end

	if player.powers[pw_carry] == CR_NIGHTSMODE
	or player.powers[pw_carry] == CR_NIGHTSFALL then
		return
	end

	if G_TagGametype() and leveltime <= CV_FindVar("hidetime").value * TICRATE then return end

	local shield = player.powers[pw_shield]
	if damagetype == DMG_FIRE and (shield & SH_PROTECTFIRE) then return end
	if damagetype == DMG_WATER and (shield & SH_PROTECTWATER) then return end
	if damagetype == DMG_ELECTRIC and (shield & SH_PROTECTELECTRIC) then return end
	if damagetype == DMG_SPIKE and (shield & SH_PROTECTSPIKE) then return end

	if RSR.HasPowerup(player, RSR.POWERUP_INVINCIBILITY) and not player.powers[pw_super] then
		if Valid(inflictor) and (inflictor.flags & MF_SHOOTABLE) and not inflictor.rsrEnemyBlink
		and not Valid(inflictor.player) then -- This code was meant for enemies only
			P_DamageMobj(inflictor, target, target, 1)
		end
		return false
	end

	if Valid(inflictor) then
		if not (inflictor.rsrProjectile or inflictor.rsrRealDamage or Valid(inflictor.player)) and rsrinfo.hurtByEnemy then return false end
		if Valid(inflictor.player) then
			if rsrinfo.hurtByMelee then return false end
			if RSR.PlayersAreTeammates(player, inflictor.player) and not RSR.CheckFriendlyFire() then return false end
		end
		if inflictor.rsrEnemyBlink then return false end
		return RSR.PlayerSourceShouldDamage(player, inflictor, source, damage, damagetype)
	end

	if Valid(source) then
		return RSR.PlayerSourceShouldDamage(player, inflictor, source, damage, damagetype)
	end

	-- Assume the damage was dealt by the level geometry if there is no inflictor or source
	-- if not ((leveltime & 0x1f) or rsrinfo.hurtByMap) then
	if not rsrinfo.hurtByMap then
		RSR.PlayerDamage(target, inflictor, source, 10, damagetype)
		rsrinfo.hurtByMap = TICRATE
	end

	if rsrinfo.health <= 0 then return end

	return false
end

--- TeamSwitch hook code for when the player switches to the "spectator" team.
---@param player player_t
---@param team integer
RSR.TeamSwitch = function(player, team)
	if not (Valid(player) and player.rsrinfo) then return end

	if team == 0 then player.rsrinfo.deathFlags = $|RSR.DEATH_MAKESPECTATOR end
end

--- MobjDeath hook code for players.
---@param target mobj_t Object that dies.
---@param inflictor mobj_t Object that caused the target's death.
---@param source mobj_t Object that indirectly caused the target's death (usually related to the inflictor, but can be nil).
---@param damagetype integer Type of damage inflicted on the target (DMG_ constants).
RSR.PlayerDeath = function(target, inflictor, source, damagetype)
	if not RSR.GamemodeActive() then return end
	if not Valid(target) then return end

	local player = target.player
	if not (Valid(player) and player.rsrinfo) then return end

	local rsrinfo = player.rsrinfo

	-- Don't let the player's lives counter go down
	if player.lives ~= INFLIVES then player.lives = $+1 end

	-- Force-depower a super player who has died while still super
	rsrinfo.hype = 0

	rsrinfo.pendingWeapon = RSR.WEAPON_NONE
	rsrinfo.useZoom = false
	RSR.PlayerSetChasecam(player, true)

	-- Only run this code in multiplayer gamemodes
	if multiplayer or netgame then
		if G_RingSlingerGametype() then
			local sourcePlayer = Valid(source) and source.player or nil
			if #rsrinfo.attackerInfo then
				sourcePlayer = rsrinfo.attackerInfo[1].player
			end

			if (rsrinfo.deathFlags & RSR.DEATH_REMOVEDEATHMASK) then damagetype = $ & ~DMG_DEATHMASK end
			if damagetype == DMG_INSTAKILL and (rsrinfo.deathFlags & RSR.DEATH_MAKESPECTATOR) then damagetype = DMG_SPECTATOR end
			RSR.KillfeedAdd(player, inflictor, sourcePlayer, damagetype)
			rsrinfo.deathFlags = 0
			-- Reset forceInflictorType and forceInflictorReflected so they don't linger around
			rsrinfo.forceInflictorType = nil
			rsrinfo.forceInflictorReflected = nil

			if Valid(sourcePlayer) then -- Only run this if a player is the source of this kill
				if sourcePlayer.powers[pw_super] then -- Player is super
					RSR.GiveHype(sourcePlayer, 400) -- Give bonus hype for killing an enemy player
					-- Give the player an indicator that they just got hype
					RSR.BonusFade(sourcePlayer)
				end

				-- TODO: Give the time boost for only one of these powerups???
				-- Give the source player a time boost if they have invincibility
				if RSR.HasPowerup(sourcePlayer, RSR.POWERUP_INVINCIBILITY) then
					RSR.GivePowerup(sourcePlayer, RSR.POWERUP_INVINCIBILITY, 10*TICRATE)
				end

				-- Give the source player a time boost if they have infinity
				if RSR.HasPowerup(sourcePlayer, RSR.POWERUP_INFINITY) then
					RSR.GivePowerup(sourcePlayer, RSR.POWERUP_INFINITY, 10*TICRATE)
				end
			end

			-- Melee attacks always have the player object be the inflictor
			if Valid(inflictor) and Valid(inflictor.player) and inflictor.player.rsrinfo then
				if (inflictor.player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT -- Player has an Attraction Shield
				and (inflictor.player.pflags & PF_SHIELDABILITY) -- Player is using the Attraction Shield
				and inflictor.player.rsrinfo.homing -- Player is homing
				and (Valid(inflictor.tracer) and inflictor.tracer == target) then -- Player is targeting us
					RSR.GiveArmor(inflictor.player, 100)
					-- Give the player an indicator that they just got armor
					RSR.BonusFade(inflictor.player)
					S_StartSound(nil, sfx_attrsg, inflictor.player)
				end
			end

			local wasHiding = (G_TagGametype() and (gametyperules & GTR_HIDEFROZEN) and not (player.pflags & PF_GAMETYPEOVER))

			if Valid(sourcePlayer) and sourcePlayer.rsrinfo
			and sourcePlayer ~= player and not RSR.PlayersAreTeammates(player, sourcePlayer) then
				sourcePlayer.rsrinfo.hitSound = RSR.HITSOUND_KILL
				-- We now make sure to award points to the last attacker even if the player voluntarily jumped off a cliff or something because it turns out you can use that to reverse-killsteal
				-- Points are already awarded to seekers in H&S if a player dies
				if not wasHiding and not (Valid(source) and Valid(source.player)) and #rsrinfo.attackerInfo then
					P_AddPlayerScore(sourcePlayer, 100)
				end
			end

			-- Points are already awarded to seekers in H&S if a player dies
			if not wasHiding and Valid(sourcePlayer) and #rsrinfo.attackerInfo > 1 then
				local lastInfo = rsrinfo.attackerInfo[1]
				-- We also prevent reverse-assiststealing??? That was a thing apparently
				for i = 2, #rsrinfo.attackerInfo do
					local info = rsrinfo.attackerInfo[i]
					if not info then continue end -- Make sure the attacker info exists
					-- Only award score if the attacker dealt more damage than the killer
					if (info.damage or 0) < (lastInfo.damage or 0) then continue end
					-- Don't give score to spectators
					if not Valid(info.player) or info.player.spectator then continue end

					if info.player.rsrinfo then
						info.player.rsrinfo.hitSound = RSR.HITSOUND_ASSIST
					end
					P_AddPlayerScore(info.player, 50)
				end
			end

			rsrinfo.attackerInfo = {} -- Clear attackerInfo since we've already died
		end

		-- Let players keep their weapons and some of their ammo when dying in co-op
		if G_CoopGametype() and rsrinfo.starpostData then
			local starpostData = rsrinfo.starpostData
			starpostData.weapons = RSR.DeepCopy(rsrinfo.weapons)
			starpostData.ammo = RSR.DeepCopy(rsrinfo.ammo)
			starpostData.readyWeapon = rsrinfo.readyWeapon

			for ammoType, ammoAmount in ipairs(rsrinfo.ammo) do
				local newAmount = RSR.AMMO_INFO[ammoType].amount
				if starpostData.ammo[ammoType] <= newAmount then continue end
				starpostData.ammo[ammoType] = newAmount
			end
		end

		-- Do this here so players blowing themselves up can still spill emeralds
		if (gametyperules & GTR_POWERSTONES) then
			-- lastemeralds is a hack that gets around P_KillPlayer resetting pw_emeralds to 0
			player.powers[pw_emeralds] = rsrinfo.lastemeralds or 0
			P_PlayerEmeraldBurst(player, false)
			player.powers[pw_emeralds] = 0
		end

		for weapon, inInventory in ipairs(rsrinfo.weapons) do
			if not inInventory then continue end
			---@type rsrweaponinfo_t
			local weaponInfo = RSR.WEAPON_INFO[weapon]
			if not (weaponInfo and weaponInfo.pickup) then continue end
			-- local ammoInfo = RSR.AMMO_INFO[weaponInfo.ammotype]
			local ammoAmount = rsrinfo.ammo[weaponInfo.ammotype]
			if ammoAmount < 1 then continue end
			-- if (G_CoopGametype() or G_RingSlingerGametype()) and ammoAmount <= ammoInfo.amount then continue end

			local angle = FixedAngle(weapon * (360*FRACUNIT / #rsrinfo.weapons))

			local pickup = P_SpawnMobjFromMobj(target, 0, 0, FRACUNIT, weaponInfo.pickup)
			if Valid(pickup) then
				-- if G_CoopGametype() or G_RingSlingerGametype() and ammoAmount >= ammoInfo.amount then
				-- 	pickup.rsrAmmoAmount = ammoAmount - ammoInfo.amount
				-- else
					pickup.rsrAmmoAmount = ammoAmount
				-- end
				if pickup.info.seestate then pickup.state = pickup.info.seestate end
				pickup.flags = $ & ~(MF_NOGRAVITY|MF_NOCLIPHEIGHT)
				pickup.flags2 = $|MF2_DONTRESPAWN
				pickup.fuse = 12*TICRATE -- Don't linger forever
				P_SetObjectMomZ(pickup, 3*FRACUNIT)
				P_InstaThrust(pickup, angle, 3*pickup.scale)
			end
		end
	end

	if mapheaderinfo[gamemap] and mapheaderinfo[gamemap].rsrloseinvondeath then rsrinfo.starpostData = {} end
end

--- Handles collision between two player Objects, and deals melee damage when possible.
---@param pmo mobj_t
---@param pmo2 mobj_t
RSR.PlayerMelee = function(pmo, pmo2)
	if not RSR.GamemodeActive() then return end
-- 	if not G_RingSlingerGametype() then return end -- Only works in deathmatch and CTF (NOT ANYMORE)
	if not (Valid(pmo) and Valid(pmo2)) then return end

	if not (Valid(pmo.player) and pmo.player.rsrinfo and Valid(pmo2.player) and pmo2.player.rsrinfo) then return end -- Only for players

	local player = pmo.player
	local player2 = pmo2.player

	if RSR.PlayersAreTeammates(player, player2) and not RSR.CheckFriendlyFire() then return end -- Don't hurt teammates unless friendlyfire is on

	-- Height check
	if not (pmo.z <= pmo2.z + pmo2.height
	and pmo2.z <= pmo.z + pmo.height) then
		return
	end

	local meleeBaseDamage = 15
	local meleeBaseDamage2 = 15
	local meleeMult = 1
	local meleeMult2 = 1

	local shield = (player.powers[pw_shield] & SH_NOSTACK)
	local shield2 = (player2.powers[pw_shield] & SH_NOSTACK)

	-- This big chunk of elifs sets melee damage to use in the interaction based on the players' shields and powerups
	-- -orbitalviolet

	-- 30 damage for Flame Dash, 40 damage for Bubble Bounce, and 65 for Elemental Stomp due to how restrictive it is
	-- Attraction gets a slight boost to 20 to help the melee playstyle
	-- -orbitalviolet

	-- Damage values are stored in RSR.SHIELD_INFO (located in rsr/base/info.lua)
	-- -MIDIMan
	if ((shield ~= SH_ATTRACT and (player.pflags & PF_SHIELDABILITY)) or (shield == SH_ATTRACT and player.rsrinfo.homing))
	and RSR.SHIELD_INFO[shield] and RSR.SHIELD_INFO[shield].meleedamage then
		meleeBaseDamage = RSR.SHIELD_INFO[shield].meleedamage
	end

	if ((shield2 ~= SH_ATTRACT and (player2.pflags & PF_SHIELDABILITY)) or (shield2 == SH_ATTRACT and player2.rsrinfo.homing))
	and RSR.SHIELD_INFO[shield2] and RSR.SHIELD_INFO[shield2].meleedamage then
		meleeBaseDamage2 = RSR.SHIELD_INFO[shield2].meleedamage
	end

	-- Invincibility or Super: x3 damage
	if RSR.HasPowerup(player, RSR.POWERUP_INVINCIBILITY) or player.powers[pw_invulnerability] or player.powers[pw_super] then
		meleeMult = 3
	else
		meleeMult = 1
	end

	if RSR.HasPowerup(player2, RSR.POWERUP_INVINCIBILITY) or player2.powers[pw_invulnerability] or player2.powers[pw_super] then
		meleeMult2 = 3
	else
		meleeMult2 = 1
	end

	local playerDamage = meleeBaseDamage * meleeMult
	local playerDamage2 = meleeBaseDamage2 * meleeMult2

	local touchTag = (G_TagGametype() and CV_FindVar("touchtag").value)

	-- Handle cases where players can harm each other
	if P_PlayerCanDamage(player, pmo2) and P_PlayerCanDamage(player2, pmo) and not (player.rsrinfo.hurtByMelee and player2.rsrinfo.hurtByMelee) then
		player.rsrinfo.attackKnockback = true
		player2.rsrinfo.attackKnockback = true
		if not player2.rsrinfo.hurtByMelee then
			P_DamageMobj(pmo2, pmo, pmo, playerDamage/2)
		end
		if not player.rsrinfo.hurtByMelee then
			P_DamageMobj(pmo, pmo2, pmo2, playerDamage2/2)
		end
		-- Don't let touchtag deal additional damage
		return false
	end

	if (P_PlayerCanDamage(player, pmo2) or touchTag) and not player2.rsrinfo.hurtByMelee then
		P_DamageMobj(pmo2, pmo, pmo, playerDamage)
	end

	if (P_PlayerCanDamage(player2, pmo) or touchTag) and not player.rsrinfo.hurtByMelee then
		P_DamageMobj(pmo, pmo2, pmo2, playerDamage2)
	end

	-- Don't let touchtag deal additional damage
	if touchTag then return false end
end
