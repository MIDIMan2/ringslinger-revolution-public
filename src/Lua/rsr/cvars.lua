-- Ringslinger Revolution - Console Variables/Commands

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

COM_AddCommand("rsr_kill", function(player, _)
	if not RSR.GamemodeActive() then
		print("You must be in a Ringslinger Revolution level or gametype to use this.")
		return
	end

	if not (netgame or multiplayer) then
		print("You can't use this in Single Player! Use \"retry\" instead.")
		return
	end

	if G_PlatformGametype() then
		print("You can't use this in co-op, race, or competition! Use \"suicide\" instead.")
		return
	end

	if not (Valid(player) and Valid(player.realmo)) then return end
	if player.rsrinfo then player.rsrinfo.deathFlags = $|RSR.DEATH_REMOVEDEATHMASK end
	P_DamageMobj(player.realmo, nil, nil, 1, DMG_INSTAKILL)
end)

-- TODO: Remove or comment this out for public releases
-- COM_AddCommand("rsr_getemeralds", function(player, arg)
-- 	if not Valid(player) then return end

-- 	if (gametyperules & GTR_POWERSTONES) then
-- 		player.powers[pw_emeralds] = 127
-- 	else
-- 		emeralds = 127
-- 	end
-- 	player.rsrinfo.hype = RSR.MAX_HYPE
-- end)

-- TODO: Remove or comment this out for public releases
-- COM_AddCommand("rsr_killallenemies", function(player, arg)
-- 	for mo in mobjs.iterate() do
-- 		if not (Valid(mo) and (mo.flags & MF_ENEMY)) then continue end
-- 		P_KillMobj(mo)
-- 	end
-- end)
