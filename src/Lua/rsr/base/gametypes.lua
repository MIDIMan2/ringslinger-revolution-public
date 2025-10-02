-- Ringslinger Revolution - Gametypes

-- These are meant for maps that don't use the Lua.RingslingerRev parameter.

-- RSR Match

G_AddGametype({
	name = "RSR Match",
	identifier = "rsrmatch",
	typeoflevel = TOL_MATCH|TOL_RSRMATCH,
	rules = GTR_RINGSLINGER|GTR_FIRSTPERSON|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_OVERTIME|GTR_POWERSTONES|GTR_DEATHMATCHSTARTS|GTR_SPAWNINVUL|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_DEATHPENALTY,
	intermissiontype = int_match,
	headercolor = 66,
	defaultpointlimit = 0,
	defaulttimelimit = 10,
	description = "Sling rings at your foes in a free-for-all battle. Use the special weapon rings to your advantage! Uses RSR rules.",
})

RSR.AddGametype(GT_RSRMATCH)

-- RSR Team Match

G_AddGametype({
	name = "RSR Team Match",
	identifier = "rsrteammatch",
	typeoflevel = TOL_MATCH|TOL_RSRMATCH,
	rules = GTR_RINGSLINGER|GTR_FIRSTPERSON|GTR_SPECTATORS|GTR_TEAMS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_OVERTIME|GTR_DEATHMATCHSTARTS|GTR_SPAWNINVUL|GTR_RESPAWNDELAY|GTR_PITYSHIELD,
	intermissiontype = int_teammatch,
	headerleftcolor = 153,
	headerrightcolor = 37,
	defaultpointlimit = 0,
	defaulttimelimit = 10,
	description = "Sling rings at your foes in a color-coded battle. Use the special weapon rings to your advantage! Uses RSR rules.",
})

RSR.AddGametype(GT_RSRTEAMMATCH)

-- RSR Tag

G_AddGametype({
	name = "RSR Tag",
	identifier = "rsrtag",
	typeoflevel = TOL_TAG|TOL_RSRTAG,
	rules = GTR_RINGSLINGER|GTR_FIRSTPERSON|GTR_TAG|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_BLINDFOLDED|GTR_DEATHMATCHSTARTS|GTR_SPAWNINVUL|GTR_RESPAWNDELAY,
	intermissiontype = int_match,
	headercolor = 123,
	defaultpointlimit = 0,
	defaulttimelimit = 10,
	description = "Whoever's IT has to hunt down everyone else. If you get caught, you have to turn on your former friends! Uses RSR rules.",
})

RSR.AddGametype(GT_RSRTAG)

-- RSR Hide and Seek

G_AddGametype({
	name = "RSR Hide and Seek",
	identifier = "rsrhideandseek",
	typeoflevel = TOL_TAG|TOL_RSRTAG,
	rules = GTR_RINGSLINGER|GTR_FIRSTPERSON|GTR_TAG|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_HIDEFROZEN|GTR_BLINDFOLDED|GTR_DEATHMATCHSTARTS|GTR_SPAWNINVUL|GTR_RESPAWNDELAY,
	intermissiontype = int_match,
	headercolor = 150,
	defaultpointlimit = 0,
	defaulttimelimit = 10,
	description = "Try and find a good hiding place in these maps - we dare you. Uses RSR rules.",
})

RSR.AddGametype(GT_RSRHIDEANDSEEK)

-- RSR CTF

G_AddGametype({
	name = "RSR CTF",
	identifier = "rsrctf",
	typeoflevel = TOL_CTF|TOL_RSRCTF,
	rules = GTR_RINGSLINGER|GTR_FIRSTPERSON|GTR_SPECTATORS|GTR_TEAMS|GTR_TEAMFLAGS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_OVERTIME|GTR_POWERSTONES|GTR_DEATHMATCHSTARTS|GTR_SPAWNINVUL|GTR_RESPAWNDELAY|GTR_PITYSHIELD,
	intermissiontype = int_ctf,
	headerleftcolor = 37,
	headerrightcolor = 153,
	defaulttimelimit = 0,
	defaultpointlimit = 5,
	description = "Steal the flag from the enemy's base and bring it back to your own, but watch out - they could just as easily steal yours! Uses RSR rules.",
})

RSR.AddGametype(GT_RSRCTF)
