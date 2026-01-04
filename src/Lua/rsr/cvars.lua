-- Ringslinger Revolution - Console Variables/Commands

-- Randomises all incoming damage to all entities through damage.lua. Parameters - None: all damage is fixed. Partial: all damage deals a fixed base portion added to a modulated random element. Doom: all damage is fully randomised akin to Doom '93
RSR.CV_RandomDamage = CV_RegisterVar({
	name = "rsr_randomdamage",
	defaultvalue = "None",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {"None","Partial","Doom"}
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
-- TODO: implement this
RSR.CV_GottaGoFast = CV_RegisterVar({
	name = "rsr_gottagofast",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Gives everyone the Speed Shoes fire rate boost
-- TODO: implement this
RSR.CV_UltraRapidFire = CV_RegisterVar({
	name = "rsr_ultrarapidfire",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Gives everyone the tripled melee damage from Invincibility
RSR.CV_FistsForGuns = CV_RegisterVar({
	name = "rsr_fistsforguns",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Makes players lose their emeralds when "de-supering"
RSR.CV_SuperBurnout = CV_RegisterVar({
	name = "rsr_superburnout",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Sets superweapons that spawn in the map. Rail/BFR forces all superweapon spawnpoints to spawn Rail/BFR. AsMap doesn't override superweapon spawns (in case both are on the same map), Random respawns a random one each time, Alternate goes back and forth between both each respawn
-- TODO: implementation at all, this will have to come later when BFR exists. BFR is here but very, very unfinished
RSR.CV_Superweapon = CV_RegisterVar({
	name = "rsr_superweapon",
	defaultvalue = "Rail",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {"Rail","BFR","AsMap","Random","Alternate","None"}
})

-- Sets power-rings that spawn in the map. Infinity/QuadDamage forces all superweapon spawnpoints to spawn Infinity/QuadDamage. AsMap doesn't override power-ring spawns (in case both are on the same map), Random respawns a random one each time, Alternate goes back and forth between both each respawn
-- TODO: implementation at all, this will have to come later when Quad Damage exists
RSR.CV_PowerRing = CV_RegisterVar({
	name = "rsr_powerring",
	defaultvalue = "Infinity",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {"Infinity","QuadDamage","AsMap","Random","Alternate","None"}
})

-- Toggles what part of Shield Effects is valid, if any
-- TODO: still need to figure out how to properly disable shield actives, if that can even be done
RSR.CV_ShieldEffects = CV_RegisterVar({
	name = "rsr_shieldeffects",
	defaultvalue = "All",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {"All","Passive","Active","None"}
})

-- Makes players explode when killed
-- TODO: implementation at all
RSR.CV_LastLaugh = CV_RegisterVar({
	name = "rsr_lastlaugh",
	defaultvalue = "False",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

-- Makes firing weapons cost no munitions. "TooMuch" enables infinite superweapons...
RSR.CV_InfiniteAmmo = CV_RegisterVar({
	name = "rsr_infiniteammo",
	defaultvalue = "Off",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {"Off","On","TooMuch"}
})

-- Makes players gain 50 EHP when scoring a kill
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

-- Makes players to regenerate 1 of something per second if enabled
RSR.CV_TitleCard = CV_RegisterVar({
	name = "rsr_titlecard",
	defaultvalue = "Off",
	flags = CV_NETVAR|CV_SHOWMODIF,
	PossibleValue = {"Off", "Health", "Armor", "Overflow", "Reverse", "Alternating", "Both"}
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

if not RSR.DEV_MODE then return end

COM_AddCommand("rsr_getemeralds", function(player, arg)
	if not Valid(player) then return end

	if (gametyperules & GTR_POWERSTONES) then
		player.powers[pw_emeralds] = 127
	else
		emeralds = 127
	end
	player.rsrinfo.hype = RSR.MAX_HYPE
end)

COM_AddCommand("rsr_killallenemies", function(player, arg)
	for mo in mobjs.iterate() do
		if not (Valid(mo) and (mo.flags & MF_ENEMY)) then continue end
		P_KillMobj(mo)
	end
end)
