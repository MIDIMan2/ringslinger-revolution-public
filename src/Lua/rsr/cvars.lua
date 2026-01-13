-- Ringslinger Revolution - Console Variables/Commands

RSR.CVVIEWMODEL_NONE = 0
RSR.CVVIEWMODEL_RIGHT = 1
RSR.CVVIEWMODEL_LEFT = 2
RSR.CVVIEWMODEL_CENTER = 3

-- Lets homing rings target and kill spectators
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
RSR.CV_Ghostbusters = CV_RegisterVar({
	name = "rsr_ghostbusters",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Lets non-IT players use weapons in Tag
RSR.CV_LaserTag = CV_RegisterVar({
	name = "rsr_lasertag",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

--- Checks if the player can use any of the kill commands.
---@param player player_t
---@return boolean
RSR.CanUserKillCMD = function(player)
	if not RSR.GamemodeActive() then
		print("You must be in a Ringslinger Revolution level or gametype to use this.")
		return false
	end

	if not (netgame or multiplayer) then
		print("You can't use this in Single Player! Use \"retry\" instead.")
		return false
	end

	if G_PlatformGametype() then
		print("You can't use this in co-op, race, or competition! Use \"suicide\" instead.")
		return false
	end

	if not (Valid(player) and Valid(player.realmo)) then return false end

	if player.playerstate == PST_DEAD then
		CONS_Printf(player, "You're already dead!")
		return false
	end

	return true
end

COM_AddCommand("rsr_kill", function(player, _)
	if not RSR.CanUserKillCMD(player) then return end
	if player.rsrinfo then player.rsrinfo.deathFlags = $|RSR.DEATH_REMOVEDEATHMASK|RSR.DEATH_USEDKILLCMD end
	P_DamageMobj(player.realmo, nil, nil, 1, DMG_INSTAKILL)
end)

COM_AddCommand("rsr_explode", function(player, _)
	if not RSR.CanUserKillCMD(player) then return end
	if player.rsrinfo then player.rsrinfo.deathFlags = $|RSR.DEATH_REMOVEDEATHMASK|RSR.DEATH_GOTBURNT|RSR.DEATH_USEDEXPLODECMD end
	P_DamageMobj(player.realmo, nil, nil, 1, DMG_INSTAKILL)
end)

COM_AddCommand("rsr_disintegrate", function(player, _)
	if not RSR.CanUserKillCMD(player) then return end
	if player.rsrinfo then player.rsrinfo.deathFlags = $|RSR.DEATH_REMOVEDEATHMASK|RSR.DEATH_USEDDISINTEGRATECMD end
	P_DamageMobj(player.realmo, nil, nil, 1, DMG_INSTAKILL)
end)

if not RSR.DEV_MODE then return end

COM_AddCommand("rsr_getemeralds", function(player, arg)
	if not (Valid(player) and player.rsrinfo) then return end

	if (gametyperules & GTR_POWERSTONES) then
		player.powers[pw_emeralds] = 127
	else
		emeralds = 127
	end
	player.rsrinfo.hype = RSR.MAX_HYPE
end)

COM_AddCommand("rsr_getweapons", function(player, arg)
	if not (Valid(player) and player.rsrinfo) then return end
	for i = 1, RSR.WEAPON_MAX - 1 do RSR.GiveWeapon(player, i, 999) end
end)

COM_AddCommand("rsr_killallenemies", function(player, arg)
	for mo in mobjs.iterate() do
		if not (Valid(mo) and (mo.flags & MF_ENEMY)) then continue end
		P_KillMobj(mo)
	end
end)
