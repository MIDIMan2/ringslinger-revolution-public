-- Ringslinger Revolution - Weapons

local folder = "rsr/weapon"

local dofolder = function(file)
	dofile(folder.."/"..file)
end

-- Initialize weapons, ammo, and psprites

PSprites.AddPSpriteID("WEAPON")

RSR.LOWER_OFFSET = 128*FRACUNIT
RSR.UPPER_OFFSET = 0
RSR.RAISE_SPEED = 12*FRACUNIT

if not RSR.CLASS_TO_WEAPON then
	RSR.CLASS_TO_WEAPON = {}
	for i = 1, 7 do
		RSR.CLASS_TO_WEAPON[i] = {}
	end
end

-- Used for co-op respawning
if not RSR.AMMO_INFO then
	---@type rsrammoinfo_t[]
	RSR.AMMO_INFO = {}
end

--- Adds a new ammo type to RSR.
---@param name string Name of the ammo type to add (can be accessed as "RSR.AMMO_NAMEHERE" afterwards).
---@param info rsrammoinfo_t Table containing info for the ammo type.
RSR.AddAmmo = function(name, info)
	if not (name and info) then
		print("\x82WARNING:\x80 Unable to add ammo "..tostring(name).."!")
		return
	end

	RSR.AddEnum("AMMO", name)
	local ammo = RSR["AMMO_"..name]
	RSR.AMMO_INFO[ammo] = info
end

if not RSR.WEAPON_INFO then
	---@type rsrweaponinfo_t[]
	RSR.WEAPON_INFO = {}
end

--- Adds a new weapon type to RSR.
---@param name string Name of the weaponDelay type to add (can be accessed as "RSR.WEAPON_NAMEHERE" afterwards).
---@param info rsrweaponinfo_t Table containing info for the weapon type.
RSR.AddWeapon = function(name, info)
	if not (name and info) then
		print("\x82WARNING:\x80 Unable to add weapon "..tostring(name).."!")
		return
	end

	RSR.AddEnum("WEAPON", name, true)
	local weapon = RSR["WEAPON_"..name]
	RSR.WEAPON_INFO[weapon] = info
	if not info.name then RSR.WEAPON_INFO[weapon].name = "Unnamed" end
	if info.class then
		if not RSR.CLASS_TO_WEAPON[info.class] then RSR.CLASS_TO_WEAPON[info.class] = {} end
		local classTable = RSR.CLASS_TO_WEAPON[info.class]
		table.insert(classTable, weapon)
		table.sort(classTable, function(a, b)
			return ((info.classpriority or 0) > (RSR.WEAPON_INFO[b].classpriority or 0))
		end)

		for tSlot, tWeapon in ipairs(classTable) do
			RSR.WEAPON_INFO[tWeapon].slot = tSlot
		end
	end
end

RSR.AddWeapon("NONE", {
	states = {
		draw = "S_NONE_READY",
		ready = "S_NONE_READY",
		holster = "S_NONE_HOLSTER"
	}
})

--- Returns the ammo info for the given weapon.
---@param weapon integer Weapon type to get ammo info for (WEAPON_ constant)
---@return rsrammoinfo_t|nil
RSR.GetAmmoInfoFromWeapon = function(weapon)
	if not weapon then return end
	if not (RSR.WEAPON_INFO[weapon] and RSR.WEAPON_INFO[weapon].ammotype) then return end
	local ammoType = RSR.WEAPON_INFO[weapon].ammotype

	return RSR.AMMO_INFO[ammoType]
end

--- Adds the given amount to the player's ammo pool.
---@param player player_t
---@param amount integer|nil Amount of ammo to give.
---@param ammoType integer Type of ammo to give (RSR.AMMO_ constant).
RSR.GiveAmmo = function(player, amount, ammoType)
	if not (Valid(player) and player.rsrinfo) then return end
	amount = $ or 0

	local rsrinfo = player.rsrinfo

	if not RSR.AMMO_INFO[ammoType] then return end
	local ammoMax = RSR.AMMO_INFO[ammoType].maxamount
	if ammoMax == nil then
		print("\x82WARNING:\x80 Maximum ammo for "..tostring(ammoType).." could not be determined! Defaulting to 50...")
		ammoMax = 50
	end
	rsrinfo.ammo[ammoType] = min(ammoMax, $ + amount)
end

--- Takes away the given amount from the player's ammo pool.
---@param player player_t
---@param amount integer|nil Amount of ammo to take.
---@param ammoType integer Type of ammo to take (RSR.AMMO_ constant).
---@param ignoreInfinity boolean|nil If true, ammo will be taken away even if the player has the infinity powerup.
RSR.TakeAmmo = function(player, amount, ammoType, ignoreInfinity)
	if not (Valid(player) and player.rsrinfo) then return end
	if not ignoreInfinity and RSR.HasPowerup(player, RSR.POWERUP_INFINITY) then return end -- Don't deplete ammo if the player has the infinity powerup
	amount = $ or 0

	local rsrinfo = player.rsrinfo

	rsrinfo.ammo[ammoType] = max(0, $ - amount)
end

--- Calls RSR.TakeAmmo using the player's weapon's ammo type.
---@param player player_t
---@param amount integer|nil Amount of ammo to take.
---@param ignoreInfinity boolean|nil If true, ammo will be taken away even if the player has the infinity powerup.
RSR.TakeAmmoFromReadyWeapon = function(player, amount, ignoreInfinity)
	if not (Valid(player) and player.rsrinfo) then return end
	RSR.TakeAmmo(player, amount or 0, RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].ammotype, ignoreInfinity)
end

--- Checks if the player can use their weapon rings.
---@param player player_t
RSR.CanUseWeapons = function(player)
	if not Valid(player) then return false end

	-- Don't let non-IT players use weapons unless rsr_lasertag is true
	if G_TagGametype() and not (player.pflags & PF_TAGIT) and not RSR.CV_LaserTag.value then return false end

	-- Don't let skins with their own weapon system use RSR weapons
	if RSR.SKIN_INFO[skins[player.skin].name] and RSR.SKIN_INFO[skins[player.skin].name].noweapons then return false end

	return true
end

--- Gives a weapon to the player.
---@param player player_t
---@param weapon integer Weapon to give the player (RSR.WEAPON_ constant).
---@param newAmount integer|nil If set to a number, this gives the player that amount of ammo for the given weapon.
RSR.GiveWeapon = function(player, weapon, newAmount)
	if not (Valid(player) and player.rsrinfo) then return end

	local rsrinfo = player.rsrinfo
	local hadWeapon = false
	for _, hasWeapon in ipairs(rsrinfo.weapons) do
		if not hasWeapon then continue end

		-- If the player has a weapon at all, don't switch weapons
		hadWeapon = true
		break
	end

	local hadAmmo = RSR.CheckAmmo(player)

	rsrinfo.weapons[weapon] = true
	local weaponInfo = RSR.WEAPON_INFO[weapon]
	if weaponInfo and weaponInfo.ammotype then
		local ammoInfo = RSR.AMMO_INFO[weaponInfo.ammotype]
		local ammoAmount = 0
		if newAmount ~= nil then
			ammoAmount = newAmount
		elseif ammoInfo and ammoInfo.amount then
			ammoAmount = ammoInfo.amount
		end
		RSR.GiveAmmo(player, ammoAmount, weaponInfo.ammotype)
	end
	if not hadWeapon then -- Switch the player's weapon if they didn't have any weapons
		rsrinfo.pendingWeapon = weapon
	elseif not hadAmmo then -- Switch the player's weapon if they didn't have any ammo for their currently held one
		rsrinfo.pendingWeapon = weapon
	end
end

--- Returns the delay in tics from firing the given weapon.
---@param weapon integer|nil Weapon to get the delay for.
---@param speed boolean|nil If true, return the super sneakers delay value.
---@param useAlt boolean|nil If true, return the altfire delay value.
RSR.GetWeaponDelay = function(weapon, speed, useAlt)
	if weapon == nil then return 1 end

	local info = RSR.WEAPON_INFO[weapon]
	if not info then return 1 end

	if useAlt then
		if speed and info.delayaltspeed ~= nil then return info.delayaltspeed end
		if info.delayalt ~= nil then return info.delayalt end
	end

	if speed and info.delayspeed ~= nil then return info.delayspeed end
	if info.delay == nil then return 1 end
	return info.delay
end

--- Automatically sets both weaponDelay and weaponDelayOrig for the player.
---@param player player_t
---@param weapon integer|nil Weapon to set the delay for.
---@param speed boolean|nil If true, use the super sneakers delay value.
---@param useAlt boolean|nil If true, use the altfire delay value.
RSR.SetWeaponDelay = function(player, weapon, speed, useAlt)
	if not (Valid(player) and player.rsrinfo) then return end
	if weapon == nil then weapon = player.rsrinfo.readyWeapon end
	if speed == nil then speed = (player.powers[pw_sneakers] or player.powers[pw_super]) and true end

	local weaponDelay = RSR.GetWeaponDelay(weapon, speed, useAlt)
	if not speed and (player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT then -- Don't affect weaponDelay if the player has the super sneakers powerup
		weaponDelay = max(weaponDelay >= 2 and 2 or 1, FixedMul($, 3*FRACUNIT/4)) -- weaponDelay * 0.75; Don't go lower than 2, unless the weaponDelay was set to 1
	end

	player.rsrinfo.weaponDelay = weaponDelay
	player.rsrinfo.weaponDelayOrig = weaponDelay
end

--- MobjSpawn hook code for projectiles.
---@param mo mobj_t
RSR.ProjectileSpawn = function(mo)
	if not Valid(mo) then return end
	mo.shadowscale = 2*FRACUNIT/3
	mo.rsrProjectile = true
	mo.rsrGhostTimer = 4
end

--- MobjMoveCollide hook code for projectiles.
---@param tmthing mobj_t
---@param thing mobj_t
RSR.ProjectileMoveCollide = function(tmthing, thing)
	if not (Valid(tmthing) and Valid(thing)) then return end
	if not (tmthing.flags & MF_MISSILE) then return end

	-- Don't run collision code if the projectile flew over or under the target
	if tmthing.z > thing.z + thing.height
	or thing.z > tmthing.z + tmthing.height then
		return
	end

	if Valid(tmthing.target) then
		-- Don't hit the source of the projectile
		if thing == tmthing.target then
			return
		end
	end

	-- Go through players (unless friendlyfire is on) and bots
	if Valid(thing.player) then
		if Valid(tmthing.target) and Valid(tmthing.target.player) and RSR.PlayersAreTeammates(tmthing.target.player, thing.player)
		and not RSR.CheckFriendlyFire() then
			return false
		end

		if thing.player.bot then
			local bot = thing.player.bot

			-- Pass through 2-player bots
			if bot == BOT_2PAI or bot == BOT_2PHUMAN then
				return false
			end
		end
	end

	if not (thing.flags & MF_SHOOTABLE) then return end

	-- Consider using a hook here in the future

	local damage = tmthing.info.damage
	if tmthing.rsrDamage then damage = tmthing.rsrDamage end
	P_DamageMobj(thing, tmthing, tmthing.target, damage)
	if Valid(tmthing) then P_ExplodeMissile(tmthing) end
	return false
end

--- Spawns ghost mobjs from the given projectile.
---@param mo mobj_t The projectile.
---@param doSmoke boolean|nil Spawns smoke instead of ghosts around the projectile if set to true.
RSR.ProjectileGhostTimer = function(mo, doSmoke)
	if not Valid(mo) then return end
	if not ((mo.flags & MF_MISSILE) and mo.health > 0) then return end

	mo.rsrGhostTimer = $-1
	if mo.rsrGhostTimer < 1 then
		if doSmoke then
			P_SpawnMobjFromMobj(
				mo,
				RSR.RandomFixedRange(-mo.info.radius, mo.info.radius),
				RSR.RandomFixedRange(-mo.info.radius, mo.info.radius),
				RSR.RandomFixedRange(0, mo.info.height),
				MT_SMOKE
			)
		else
			P_SpawnGhostMobj(mo)
		end
		mo.rsrGhostTimer = 4
	end
end

--- Default function for SKIN_INFO's touchWeapon hook.
---@param special mobj_t The weapon pickup being touched.
---@param toucher mobj_t The player object touching the weapon.
---@param weaponType integer The weapon to give the player (RSR.WEAPON_* constants).
RSR.TouchWeaponDefault = function(special, toucher, weaponType)
	local player = toucher.player

	-- Don't pick up the weapon if the player can't use it (e.g. Non-tagged players in Tag gametypes)
	if not RSR.CanUseWeapons(player) then return true end

	local rsrinfo = player.rsrinfo

	-- Don't pick up the weapon if the player already has it
	local coopMode = false
	if ((multiplayer or netgame) and G_CoopGametype()) and special.rsrDontDespawn then
		if rsrinfo.weapons[weaponType] then return true end
		coopMode = true
	end

	-- Don't pick up the weapon if the player has the maximum amount of ammo
	local ammoInfo = RSR.GetAmmoInfoFromWeapon(weaponType)
	local ammoType = RSR.WEAPON_INFO[weaponType].ammotype
	if ammoInfo and ammoInfo.maxamount and rsrinfo.ammo[ammoType] >= ammoInfo.maxamount then return true end

	local isPanel = special.rsrIsPanel or false
	if not isPanel and RSR.WEAPON_INFO[weaponType].canbepanel == false then
		isPanel = true
	end

	local ammoAmount = nil
	if special.rsrAmmoAmount then -- Used in co-op and match when the player spills their ammo
		ammoAmount = special.rsrAmmoAmount
	elseif not isPanel then -- If the pickup is not a panel, give half the typical ammo
		ammoAmount = (RSR.WEAPON_INFO[weaponType].ammoamount or 0) / 2
	end
	RSR.GiveWeapon(player, weaponType, ammoAmount)

	-- Don't remove the pickup if it's marked to not despawn in a co-op map.
	if coopMode then
		S_StartSound(special, special.info.deathsound)
		return true
	end

	RSR.SetItemFuse(special)
end

--- TouchSpecial hook code for weapon pickups.
---@param special mobj_t
---@param toucher mobj_t
---@param weaponType integer
RSR.WeaponTouchSpecial = function(special, toucher, weaponType)
	if not (Valid(special) and Valid(toucher) and weaponType) then return end
	local player = toucher.player
	if not (Valid(player) and player.rsrinfo) then return end

	local skinInfo = RSR.SKIN_INFO[skins[player.skin].name]
	if skinInfo and skinInfo.hooks and skinInfo.hooks.touchWeapon then
		local returnValue = skinInfo.hooks.touchWeapon(special, toucher, weaponType)
		if returnValue ~= nil then
			return returnValue
		end
	end

	return RSR.SKIN_INFO["DEFAULT"].hooks.touchWeapon(special, toucher, weaponType)
end

--- MapThingSpawn hook code for weapon pickups
---@param mo mobj_t
---@param mthing mapthing_t
RSR.WeaponMapThingSpawn = function(mo, mthing)
	if not (Valid(mo) and Valid(mthing)) then return end

	RSR.ItemMapThingSpawn(mo, mthing)

	-- Just in case the Object gets removed due to the map being a non-RSR map...
	if not Valid(mo) then return end

	-- Don't let weapon pickups despawn in co-op
	if mthing.args[1] then
		mo.rsrDontDespawn = true
	end

	-- Spawn as a panel unless explicitly told not to
	if not mthing.args[2] and mo.info.seestate ~= S_NULL then
		mo.state = mo.info.seestate
		mo.rsrIsPanel = true
	end
end

--- MobjThinker hook code for weapon pickups.
---@param mo mobj_t
RSR.WeaponPickupThinker = function(mo)
	if not Valid(mo) then return end

	-- Make the pickup flicker to show the player it's about to disappear
	if mo.fuse and mo.fuse < 2*TICRATE and (mo.flags2 & MF2_DONTRESPAWN) then
		-- Only flicker if the pickup hasn't been picked up
		if mo.health then
			mo.flags2 = $ ^^ MF2_DONTDRAW
		else
			mo.flags2 = $ & ~MF2_DONTDRAW
		end
	end

	-- Make the pickup spawn ghosts of itself if it doesn't despawn in co-op
	if multiplayer and G_CoopGametype() then
		if (leveltime % 4) == 0 and mo.rsrDontDespawn then
			local ghost = P_SpawnGhostMobj(mo)
			if Valid(ghost) then
				ghost.momx = P_RandomRange(-2, 2)*mo.scale
				ghost.momy = P_RandomRange(-2, 2)*mo.scale
				ghost.momz = P_RandomRange(-2, 2)*mo.scale
				ghost.fuse = TICRATE/4
				ghost.blendmode = AST_ADD
			end
		end
	end
end

--- Makes the given weapon pickup respawn when its fuse reaches 0.
---@param mo mobj_t
RSR.WeaponMobjFuse = function(mo)
	if not Valid(mo) then return end
	if (mo.flags2 & MF2_DONTRESPAWN) then return end

	local itemType = mo.type

	local newItem = P_SpawnMobjFromMobj(mo, 0, 0, 0, itemType)
	if Valid(newItem) then
		newItem.flags2 = mo.flags2
		newItem.spawnpoint = mo.spawnpoint
		newItem.rsrIsPanel = mo.rsrIsPanel

		if newItem.rsrIsPanel and mo.info.seestate ~= S_NULL then
			newItem.state = newItem.info.seestate
		end
		newItem.rsrAmmoAmount = mo.rsrAmmoAmount

		if Valid(mo.rsrSpawner) then -- Check the item spawners in wave stages
			newItem.rsrSpawner = mo.tracer
			mo.rsrSpawner.tracer = newItem
		end
		RSR.SpawnTeleportFog(newItem, -24*FRACUNIT)
	end

	P_RemoveMobj(mo)
end

dofolder("basic.lua")
dofolder("scatter.lua")
dofolder("auto.lua")
dofolder("bounce.lua")
dofolder("grenade.lua")
dofolder("bomb.lua")
dofolder("homing.lua")
dofolder("rail.lua")
