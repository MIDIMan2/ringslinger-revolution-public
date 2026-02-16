-- Ringslinger Revolution - Console Variables/Commands

-- --------------------------------
-- CLIENT CVARS
-- --------------------------------

RSR.CVVIEWMODEL_NONE = 0
RSR.CVVIEWMODEL_RIGHT = 1
RSR.CVVIEWMODEL_LEFT = 2
RSR.CVVIEWMODEL_CENTER = 3

-- Lets the player set their viewmodel's orientation.
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

-- Lets the second player set their viewmodel's orientation.
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

RSR.CVKILLFEED_NONE = 0
RSR.CVKILLFEED_TEXT = 1
RSR.CVKILLFEED_ICON = 2
RSR.CVKILLFEED_BOTH = 3 -- Should be the previous two combined

-- Lets the player set how the killfeed should be displayed.
RSR.CV_Killfeed = CV_RegisterVar({
	name = "rsr_killfeed",
	defaultvalue = "Both",
	flags = CV_SAVE,
	PossibleValue = {
		Off = RSR.CVKILLFEED_NONE,
		Text = RSR.CVKILLFEED_TEXT,
		Icon = RSR.CVKILLFEED_ICON,
		Both = RSR.CVKILLFEED_BOTH
	}
})

-- --------------------------------
-- SERVER CVARS
-- --------------------------------

-- Lets homing rings target and kill spectators.
RSR.CV_Ghostbusters = CV_RegisterVar({
	name = "rsr_ghostbusters",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Lets non-IT players use weapons in Tag.
RSR.CV_LaserTag = CV_RegisterVar({
	name = "rsr_lasertag",
	defaultvalue = "True",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- --------------------------------
-- COMMANDS
-- --------------------------------

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
