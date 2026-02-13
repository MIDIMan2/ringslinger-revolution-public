-- Ringslinger Revolution - Console Variables/Commands

RSR.CVRANDMG_PARTIAL = 1
RSR.CVRANDMG_DOOM = 2

-- Randomises all incoming damage to all entities through damage.lua. Parameters - None: all damage is fixed. Partial: all damage deals a fixed base portion added to a modulated random element. Doom: all damage is fully randomised akin to Doom '93
RSR.CV_RandomDamage = CV_RegisterVar({
	name = "rsr_randomdamage",
	defaultvalue = "None",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {
		None = 0,
		Partial = RSR.CVRANDMG_PARTIAL,
		Doom = RSR.CVRANDMG_DOOM
	}
})

RSR.CVVIEWMODEL_NONE = 0
RSR.CVVIEWMODEL_RIGHT = 1
RSR.CVVIEWMODEL_LEFT = 2
RSR.CVVIEWMODEL_CENTER = 3

-- Lets the player choose the position of their "viewmodel"
RSR.CV_Viewmodel = CV_RegisterVar({
	name = "rsr_viewmodel",
	defaultvalue = "Right",
	flags = CV_SAVE,
	PossibleValue = {
		Off = RSR.CVVIEWMODEL_NONE,
		Right = RSR.CVVIEWMODEL_RIGHT,
		Left = RSR.CVVIEWMODEL_LEFT,
		Center = RSR.CVVIEWMODEL_CENTER
	}
})

-- Lets homing rings target and kill spectators
RSR.CV_Viewmodel2 = CV_RegisterVar({
	name = "rsr_viewmodel2",
	defaultvalue = "Right",
	flags = CV_SAVE,
	PossibleValue = {
		Off = RSR.CVVIEWMODEL_NONE,
		Right = RSR.CVVIEWMODEL_RIGHT,
		Left = RSR.CVVIEWMODEL_LEFT,
		Center = RSR.CVVIEWMODEL_CENTER
	}
})

-- Lets homing rings target and kill spectators
RSR.CV_Ghostbusters = CV_RegisterVar({
	name = "rsr_ghostbusters",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Lets non-IT players use weapons in Tag
RSR.CV_LaserTag = CV_RegisterVar({
	name = "rsr_lasertag",
	defaultvalue = "True",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Makes players die from any amount of damage
RSR.CV_InstaGib = CV_RegisterVar({
	name = "rsr_instagib",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Makes armor act as a second health bar
RSR.CV_ArmorSwitch = CV_RegisterVar({
	name = "rsr_armorswitch",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Gives everyone the Speed Shoes speed boost
RSR.CV_GottaGoFast = CV_RegisterVar({
	name = "rsr_gottagofast",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Gives everyone the Speed Shoes fire rate boost
RSR.CV_UltraRapidFire = CV_RegisterVar({
	name = "rsr_ultrarapidfire",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Permanently enables the tripled melee damage part of Invincibility buffs. "Tyson" mode makes this STACK with Invincibility for a x9 multiplier...
RSR.CV_FistsForGuns = CV_RegisterVar({
	name = "rsr_fistsforguns",
	defaultvalue = "Off",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {
		Off = 0,
		On = RSR.CVPUNCHOUT_ON,
		Tyson = RSR.CVPUNCHOUT_TYSON,
	}
})

RSR.CVPUNCHOUT_ON = 1
RSR.CVPUNCHOUT_TYSON = 2

-- Makes players lose their emeralds when "de-supering"
RSR.CV_SuperBurnout = CV_RegisterVar({
	name = "rsr_superburnout",
	defaultvalue = "True",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

RSR.CVSUPERWPN_RAIL = 1
RSR.CVSUPERWPN_BFR = 2
RSR.CVSUPERWPN_ASMAP = 3
RSR.CVSUPERWPN_RANDOM = 4
RSR.CVSUPERWPN_ALTERNATE = 5

-- Sets superweapons that spawn in the map. Rail/BFR forces all superweapon spawnpoints to spawn Rail/BFR. AsMap doesn't override superweapon spawns (in case both are on the same map), Random respawns a random one each time, Alternate goes back and forth between both each respawn
-- TODO: implementation at all, this will have to come later when BFR exists. BFR is here but very, very unfinished
RSR.CV_Superweapon = CV_RegisterVar({
	name = "rsr_superweapon",
	defaultvalue = "AsMap",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {
		None = 0,
		Rail = RSR.CVSUPERWPN_RAIL,
		BFR = RSR.CVSUPERWPN_BFR,
		AsMap = RSR.CVSUPERWPN_ASMAP,
		Random = RSR.CVSUPERWPN_RANDOM,
		Alternate = RSR.CVSUPERWPN_ALTERNATE,
	}
})

RSR.CVPOWERRING_INFINITY = 1
RSR.CVPOWERRING_QUAD = 2
RSR.CVPOWERRING_ASMAP = 3
RSR.CVPOWERRING_RANDOM = 4
RSR.CVPOWERRING_ALTERNATE = 5

-- Sets power-rings that spawn in the map. Infinity/QuadDamage forces all superweapon spawnpoints to spawn Infinity/QuadDamage. AsMap doesn't override power-ring spawns (in case both are on the same map), Random respawns a random one each time, Alternate goes back and forth between both each respawn
-- TODO: implementation at all, this will have to come later when Quad Damage exists
RSR.CV_PowerRing = CV_RegisterVar({
	name = "rsr_powerring",
	defaultvalue = "AsMap",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {
		None = 0,
		Infinity = RSR.CVPOWERRING_INFINITY,
		QuadDamage = RSR.CVPOWERRING_QUAD,
		AsMap = RSR.CVPOWERRING_ASMAP,
		Random = RSR.CVPOWERRING_RANDOM,
		Alternate = RSR.CVPOWERRING_ALTERNATE,
	}
})

RSR.CVSHIELD_PASSIVE = 1
RSR.CVSHIELD_ACTIVE = 2
RSR.CVSHIELD_ALL = 3

-- Toggles what part of Shield Effects is valid, if any
-- TODO: Figure out how to disable certain passives, like underwater breathing(?)
RSR.CV_ShieldEffects = CV_RegisterVar({
	name = "rsr_shieldeffects",
	defaultvalue = "All",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {
		None = 0,
		Passive = RSR.CVSHIELD_PASSIVE,
		Active = RSR.CVSHIELD_ACTIVE,
		All = RSR.CVSHIELD_ALL
	}
})

-- Makes players explode when killed
RSR.CV_LastLaugh = CV_RegisterVar({
	name = "rsr_lastlaugh",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

RSR.CVINFAMMO_ON = 1
RSR.CVINFAMMO_TOOMUCH = 2

-- Makes firing weapons cost no munitions. "TooMuch" enables infinite superweapons...
RSR.CV_InfiniteAmmo = CV_RegisterVar({
	name = "rsr_infiniteammo",
	defaultvalue = "Off",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {
		Off = 0,
		On = RSR.CVINFAMMO_ON,
		TooMuch = RSR.CVINFAMMO_TOOMUCH
	}
})

-- Makes players gain 50 EHP (effective hit points) when scoring a kill
RSR.CV_TheReaping = CV_RegisterVar({
	name = "rsr_thereaping",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Allows players to heal past 100
RSR.CV_LimitBreak = CV_RegisterVar({
	name = "rsr_limitbreak",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Inverts the normal and alternate firemodes
-- TODO: this is probably bugged. Should this affect the superweapons?
RSR.CV_StrangerRings = CV_RegisterVar({
	name = "rsr_strangerrings",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

RSR.CVREGEN_HEALTH = 1
RSR.CVREGEN_ARMOR = 2
RSR.CVREGEN_BOTH = 3 -- This should always be 3 so the previous two enums can be used as flags.
RSR.CVREGEN_OVERFLOW = 4
RSR.CVREGEN_REVERSE = 5
RSR.CVREGEN_ALTERNATING = 6

-- Makes players to regenerate 1 of something per second if enabled
RSR.CV_TitleCard = CV_RegisterVar({
	name = "rsr_titlecard",
	defaultvalue = "Off",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {
		Off = 0,
		Health = RSR.CVREGEN_HEALTH,
		Armor = RSR.CVREGEN_ARMOR,
		Both = RSR.CVREGEN_BOTH,
		Overflow = RSR.CVREGEN_OVERFLOW,
		Reverse = RSR.CVREGEN_REVERSE,
		Alternating = RSR.CVREGEN_ALTERNATING
	}
})

--- Checks if the player can use any of the kill commands.
---@param player player_t
---@param skipMessage boolean|nil Skips printing a message to the player's console log.
---@return boolean
RSR.CanUseKillCMD = function(player, skipMessage)
	if not RSR.GamemodeActive() then
		if not skipMessage then CONS_Printf(player, "You must be in a Ringslinger Revolution level or gametype to use this.") end
		return false
	end

	if not (netgame or multiplayer) then
		if not skipMessage then CONS_Printf(player, "You can't use this in Single Player! Use \"retry\" instead.") end
		return false
	end

	-- if G_PlatformGametype() then
	-- 	print("You can't use this in co-op, race, or competition! Use \"suicide\" instead.")
	-- 	return false
	-- end

	if not (Valid(player) and Valid(player.realmo)) then return false end

	if player.playerstate == PST_DEAD then
		if not skipMessage then CONS_Printf(player, "You're already dead!") end
		return false
	end

	return true
end

COM_AddCommand("rsr_kill", function(player, _)
	if not RSR.CanUseKillCMD(player) then return end
	if player.rsrinfo then player.rsrinfo.deathFlags = $|RSR.DEATH_REMOVEDEATHMASK|RSR.DEATH_USEDKILLCMD end
	P_DamageMobj(player.realmo, nil, nil, 1, DMG_INSTAKILL)
end)

COM_AddCommand("rsr_explode", function(player, _)
	if not RSR.CanUseKillCMD(player) then return end
	if player.rsrinfo then player.rsrinfo.deathFlags = $|RSR.DEATH_REMOVEDEATHMASK|RSR.DEATH_GOTBURNT|RSR.DEATH_USEDEXPLODECMD end
	P_DamageMobj(player.realmo, nil, nil, 1, DMG_INSTAKILL)
end)

COM_AddCommand("rsr_disintegrate", function(player, _)
	if not RSR.CanUseKillCMD(player) then return end
	if player.rsrinfo then player.rsrinfo.deathFlags = $|RSR.DEATH_REMOVEDEATHMASK|RSR.DEATH_USEDDISINTEGRATECMD end
	P_DamageMobj(player.realmo, nil, nil, 1, DMG_INSTAKILL)
end)

COM_AddCommand("rsr_killallplayers", function()
	for player in players.iterate do
		if not (Valid(player) and RSR.CanUseKillCMD(player, true)) then continue end
		if player.rsrinfo then
			player.rsrinfo.deathFlags = $|RSR.DEATH_REMOVEDEATHMASK
			if P_RandomRange(1, 10) == 5 then
				player.rsrinfo.deathFlags = $|RSR.DEATH_USEDDISINTEGRATECMD
			elseif P_RandomRange(1, 5) == 2 then
				player.rsrinfo.deathFlags = $|RSR.DEATH_GOTBURNT|RSR.DEATH_USEDEXPLODECMD
			else
				player.rsrinfo.deathFlags = $|RSR.DEATH_USEDKILLCMD
			end
		end
		P_DamageMobj(player.realmo, nil, nil, 1, DMG_INSTAKILL)
	end
end, COM_ADMIN)

if not RSR.DEV_MODE then return end

RSR.COM_GetEmeralds = function(player, arg)
	if not (Valid(player) and player.rsrinfo) then return end

	if (gametyperules & GTR_POWERSTONES) then
		player.powers[pw_emeralds] = 127
	else
		emeralds = 127
	end
	player.rsrinfo.hype = RSR.MAX_HYPE
end

RSR.COM_GetWeapons = function(player, arg)
	if not (Valid(player) and player.rsrinfo) then return end
	for i = 1, RSR.WEAPON_MAX - 1 do RSR.GiveWeapon(player, i, 999) end
end

RSR.COM_GetHealth = function(player, arg)
	if not (Valid(player) and player.rsrinfo) then return end
	RSR.GiveHealth(player, 200, true)
	RSR.GiveArmor(player, 200, true)
end

COM_AddCommand("rsr_getemeralds", RSR.COM_GetEmeralds)
COM_AddCommand("rsr_getweapons", RSR.COM_GetWeapons)
COM_AddCommand("rsr_gethealth", RSR.COM_GetHealth)
COM_AddCommand("rsr_geteverything", function(player, arg)
	RSR.COM_GetEmeralds(player, arg)
	RSR.COM_GetWeapons(player, arg)
	RSR.COM_GetHealth(player, arg)
end)

COM_AddCommand("rsr_killallenemies", function(player, arg)
	for mo in mobjs.iterate() do
		if not (Valid(mo) and (mo.flags & MF_ENEMY)) then continue end
		P_KillMobj(mo)
	end
end)
