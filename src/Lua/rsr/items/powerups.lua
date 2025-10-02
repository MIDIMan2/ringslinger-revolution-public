---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Powerups

if not RSR.POWERUP_INFO then
	RSR.POWERUP_INFO = {}
end

--- Adds a new powerup to RSR.
---@param name string Name of the powerups to add (can be accessed as "RSR.POWERUP_NAMEHERE" afterwards).
---@param info rsrpowerupinfo_t Table containing info for the powerup.
RSR.AddPowerup = function(name, info)
	if not (name and info) then
		print("\x82WARNING:\x80 Unable to add powerup "..tostring(name).."!")
		return
	end

	RSR.AddEnum("POWERUP", name)
	local ammo = RSR["POWERUP_"..name]
	RSR.POWERUP_INFO[ammo] = info
end

RSR.AddPowerup("INFINITY", {
	icon = "RSRINFNI",
	tics = 15*TICRATE
})

RSR.AddPowerup("SPEED", {
	icon = "RSRSPEDI",
	power = pw_sneakers,
	tics = 20*TICRATE
})

RSR.AddPowerup("INVINCIBILITY", {
	icon = "RSRINVNI",
	power = pw_invulnerability,
	tics = 20*TICRATE
})

-- RSR.AddPowerup("SUPER", {
-- 	icon = "RSRSUPRI",
-- 	tics = 30*TICRATE
-- })

--- Gives a powerup to the player.
---@param player player_t
---@param powerup integer Powerup to give the player (RSR.POWERUP_ constant).
---@param addTics integer|nil Amount of tics to add to the powerup if it exists in the player's powerup table.
RSR.GivePowerup = function(player, powerup, addTics)
	if not (Valid(player) and player.rsrinfo and player.rsrinfo.powerups and powerup) then return end

	if not RSR.POWERUP_INFO[powerup] then return end
	local powerupInfo = RSR.POWERUP_INFO[powerup]

	local powerups = player.rsrinfo.powerups
	local hasPowerup, key = RSR.HasPowerup(player, powerup)

	local powerupTics = powerupInfo.tics or (20*TICRATE) -- Make sure tics is never nil

	if hasPowerup then
		if addTics then
			powerups[key].tics = min($ + addTics, powerupTics)
			if powerupInfo.power ~= nil then
				player.powers[powerupInfo.power] = powerups[key].tics
			end
			return
		end
		table.remove(powerups, key)
	end

	table.insert(powerups, {
		powerup = powerup,
		tics = powerupTics
	})
	if powerupInfo.power ~= nil then
		player.powers[powerupInfo.power] = powerupTics
	end
end

--- Default function for SKIN_INFO's touchWeapon hook
---@param special mobj_t The powerup pickup being touched.
---@param toucher mobj_t The player object touching the pickup.
---@param powerup integer The powerup to give the player (RSR.POWERUP_* constants).
RSR.TouchPowerupDefault = function(special, toucher, powerup)
	RSR.GivePowerup(toucher.player, powerup)
	RSR.BonusFade(toucher.player)
	RSR.SetItemFuse(special)
end

--- TouchSpecial hook code for powerups.
---@param special mobj_t
---@param toucher mobj_t
---@param powerupType integer
RSR.PowerupTouchSpecial = function(special, toucher, powerupType)
	if not (Valid(special) and Valid(toucher)) then return end
	local player = toucher.player
	if not (Valid(player) and player.rsrinfo) then return end

	-- local hookValue = hookLib.RunHook("RSR_PowerupTouchSpecial", special, toucher, powerup)
	-- if hookValue ~= nil then
	-- 	if Valid(special) and special.health <= 0 then RSR.SetItemFuse(special) end
	-- 	return hookValue
	-- end

	local skinInfo = RSR.SKIN_INFO[skins[player.skin].name]
	if skinInfo and skinInfo.hooks and skinInfo.hooks.touchPowerup then
		local returnValue = skinInfo.hooks.touchPowerup(special, toucher, powerupType)
		if returnValue ~= nil then
			return returnValue
		end
	end

	return RSR.SKIN_INFO["DEFAULT"].hooks.touchPowerup(special, toucher, powerupType)
end

mobjinfo[MT_RSR_POWERUP_INFINITY] = {
	--$Name Infinity Powerup
	--$Sprite RSPIA0
	--$Category Ringslinger Revolution/Powerups
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	doomednum = 356,
	spawnstate = S_RSR_POWERUP_INFINITY,
	deathstate = S_RSR_ITEM_DEATH,
	deathsound = sfx_ncitem,
	radius = 16*FRACUNIT,
	height = 28*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_POWERUP_INFINITY] =	{SPR_RSPI,	FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	15,	3,	S_NULL}

addHook("MobjSpawn", RSR.HealthMobjSpawn, MT_RSR_POWERUP_INFINITY)
addHook("MapThingSpawn", RSR.ItemMapThingSpawn, MT_RSR_POWERUP_INFINITY)
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end
	RSR.ItemFlingSpark(mo, 0, FRACUNIT/2, 25) -- Smaller sparks! :o
	RSR.ItemFloatThinker(mo)
end, MT_RSR_POWERUP_INFINITY)
addHook("MobjFuse", RSR.ItemMobjFuse, MT_RSR_POWERUP_INFINITY)
addHook("TouchSpecial", function(special, toucher)
	return RSR.PowerupTouchSpecial(special, toucher, RSR.POWERUP_INFINITY)
end, MT_RSR_POWERUP_INFINITY)
