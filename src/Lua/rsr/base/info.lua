 ---@diagnostic disable: missing-fields
 -- Ringslinger Revolution - Info Tables

 -- --------------------------------
 -- MOBJ INFO
 -- --------------------------------

if not RSR.MOBJ_INFO then
	---@type rsrmobjinfo_t[]
	RSR.MOBJ_INFO = {}
end

-- Enemies/Bosses
RSR.MOBJ_INFO[MT_BLUECRAWLA] = {health = 40, damage = 10}
RSR.MOBJ_INFO[MT_REDCRAWLA] = {health = 55, damage = 15}
RSR.MOBJ_INFO[MT_GFZFISH] = {health = 15, damage = 10}
RSR.MOBJ_INFO[MT_GOLDBUZZ] = {health = 35, damage = 10}
RSR.MOBJ_INFO[MT_REDBUZZ] = {health = 55, damage = 15}
RSR.MOBJ_INFO[MT_DETON] = {health = 1, damage = 40}
RSR.MOBJ_INFO[MT_POPUPTURRET] = {health = 1, damage = 10}
RSR.MOBJ_INFO[MT_SPRINGSHELL] = {health = 55, damage = 10}
RSR.MOBJ_INFO[MT_YELLOWSHELL] = {health = 95, damage = 15}
RSR.MOBJ_INFO[MT_SKIM] = {health = 25, damage = 10}
RSR.MOBJ_INFO[MT_JETJAW] = {health = 100, damage = 20}
RSR.MOBJ_INFO[MT_CRUSHSTACEAN] = {health = 125, damage = 20}
RSR.MOBJ_INFO[MT_BANPYURA] = {health = 140, damage = 1}
RSR.MOBJ_INFO[MT_ROBOHOOD] = {health = 30, damage = 5}
RSR.MOBJ_INFO[MT_FACESTABBER] = {health = 250, damage = 45, nopainstate = true}
RSR.MOBJ_INFO[MT_EGGGUARD] = {health = 15, damage = 25}
RSR.MOBJ_INFO[MT_VULTURE] = {health = 75, damage = 25}
RSR.MOBJ_INFO[MT_GSNAPPER] = {health = 125, damage = 20}
RSR.MOBJ_INFO[MT_MINUS] = {health = 1, damage = 35}
RSR.MOBJ_INFO[MT_CANARIVORE] = {health = 125, damage = 10, nosplashthrust = true}
RSR.MOBJ_INFO[MT_UNIDUS] = {health = 117, damage = 10}
RSR.MOBJ_INFO[MT_PTERABYTE] = {health = 55, damage = 15}
RSR.MOBJ_INFO[MT_PYREFLY] = {health = 125, damage = 25}
RSR.MOBJ_INFO[MT_DRAGONBOMBER] = {health = 222, damage = 20}
RSR.MOBJ_INFO[MT_JETTBOMBER] = {health = 75, damage = 15}
RSR.MOBJ_INFO[MT_JETTGUNNER] = {health = 50, damage = 15}
RSR.MOBJ_INFO[MT_SPINCUSHION] = {health = 70, damage = 10}
RSR.MOBJ_INFO[MT_SNAILER] = {health = 125, damage = 10}
RSR.MOBJ_INFO[MT_PENGUINATOR] = {health = 55, damage = 20}
RSR.MOBJ_INFO[MT_POPHAT] = {health = 65, damage = 10}
RSR.MOBJ_INFO[MT_CRAWLACOMMANDER] = {health = 195, damage = 15}
RSR.MOBJ_INFO[MT_SPINBOBERT] = {health = 1, damage = 10}
RSR.MOBJ_INFO[MT_CACOLANTERN] = {health = 145, damage = 30}
RSR.MOBJ_INFO[MT_HANGSTER] = {health = 55, damage = 40}
RSR.MOBJ_INFO[MT_HIVEELEMENTAL] = {health = 240, damage = 10, nosplashthrust = true}
RSR.MOBJ_INFO[MT_BUMBLEBORE] = {health = 1, damage = 20}
RSR.MOBJ_INFO[MT_BUGGLE] = {health = 85, damage = 20}
RSR.MOBJ_INFO[MT_POINTY] = {health = 125, damage = 25}
RSR.MOBJ_INFO[MT_EGGMOBILE] = {health = 3000, damage = 15}
RSR.MOBJ_INFO[MT_EGGMOBILE2] = {health = 3000, damage = 15}
RSR.MOBJ_INFO[MT_EGGMOBILE3] = {health = 3000, damage = 15}
RSR.MOBJ_INFO[MT_FAKEMOBILE] = {health = 130, damage = 15}
RSR.MOBJ_INFO[MT_EGGMOBILE4] = {health = 3000, damage = 15}
RSR.MOBJ_INFO[MT_FANG] = {health = 1850, damage = 25}
RSR.MOBJ_INFO[MT_METALSONIC_BATTLE] = {health = 1850, damage = 40}
RSR.MOBJ_INFO[MT_BLACKEGGMAN] = {health = 6250, damage = 20}
RSR.MOBJ_INFO[MT_CYBRAKDEMON] = {health = 5500, damage = 30}
RSR.MOBJ_INFO[MT_CYBRAK2016] = {health = 4500, damage = 40}

-- Ringslinger Projectiles
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_BASIC] = {
	knockback = 3*FRACUNIT,
	killfeedIcon = "RSRBASCI",
	killfeedName = "Red Ring",
	killfeedObituary = {
		attacker = "$a's $rRed Ring humiliated $v.",
		solo = "$v was humiliated by a $rRed Ring."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_BASIC_CHARGED] = {
	knockback = 6*FRACUNIT,
	travelsound = sfx_rrchab,
	traveltimer = 12,
	killfeedIcon = "RSRBSALI",
	killfeedName = "Charged Shot",
	killfeedObituary = {
		attacker = "$a's $rCharged Shot punched through $v.",
		solo = "$v was punched through by a $rCharged Shot."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_SCATTER] = {
	knockback = 6*FRACUNIT,
	killfeedIcon = "RSRSCTRI",
	killfeedName = "Scatter Ring",
	killfeedObituary = {
		attacker = "$a's $rScatter Ring scattered $v.",
		solo = "$v was scattered by a $rScatter Ring."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_SCATTER_FLAKCANNON] = {
	knockback = 3*FRACUNIT,
	killfeedIcon = "RSRSCALI",
	killfeedName = "Mass Scrambler",
	killfeedObituary = {
		attacker = "$a's $rMass Scrambler blasted $v.",
		solo = "$v was blasted by a $rMass Scrambler."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_SCATTER_FLAKCANNON_SUBMUNITION] = {
	knockback = 9*FRACUNIT,
	dontreflect = true,
	explosive = true,
	sparklestate = S_RSR_NIGHTSPARKLE_SCRAMBLER,
	thrustdamage = 3, -- Roughly 1/6th of 20
	travelsound = sfx_scatab,
	traveltimer = 6,
	killfeedIcon = "RSRSCALI",
	killfeedName = "Mass Scrambler bomblet",
	killfeedObituary = {
		attacker = "$a's $rMass Scrambler bomblets scrambled $v.",
		hurtself = "$v got scrambled by their own Mass Scrambler bomblets.",
		solo = "$v was scrambled by $rMass Scrambler bomblets."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_AUTO] = {
	knockback = 1*FRACUNIT/4,
	killfeedIcon = "RSRAUTOI",
	killfeedName = "Automatic Ring",
	killfeedObituary = {
		attacker = "$a's $rAutomatic Ring riddled $v with holes.",
		solo = "$v was riddled with holes by an $rAutomatic Ring."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_AUTO_SNP] = {
	knockback = 1*FRACUNIT/4,
	killfeedIcon = "RSRAUALI",
	killfeedName = "Spray&Pray",
	killfeedObituary = {
		attacker = "$a's $rSpray&Pray overwhelmed $v.",
		solo = "$v was overwhelmed by $rSpray&Pray."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_BOUNCE] = {
	knockback = 6*FRACUNIT,
	killfeedIcon = "RSRBNCEI",
	killfeedName = "Bounce Ring",
	killfeedObituary = {
		attacker = "$a's $rBounce Ring bounced $v.",
		solo = "$v was bounced by a $rBounce Ring."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_BOUNCE_MEGABOMB] = {
	knockback = 9*FRACUNIT,
	dontreflect = true,
	explosive = true,
	killfeedIcon = "RSRBNALI",
	killfeedName = "Goldburster",
	killfeedObituary = {
		attacker = "$a's $rGoldburster gave $v a headache.",
		solo = "$v contracted a concussion from a $rGoldburster."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_BOUNCE_MEGABOMB_SUBMUNITION] = {
	knockback = 6*FRACUNIT,
	killfeedIcon = "RSRBNALI",
	killfeedName = "Goldburster debris",
	killfeedObituary = {
		attacker = "$a's $rGoldburster debris pinballed $v.",
		solo = "$v was pinballed by $rGoldburster debris."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_GRENADE] = {
	knockback = 6*FRACUNIT,
	dontreflect = true,
	explosive = true,
	sparklestate = S_RSR_NIGHTSPARKLE_GRENADE,
	travelsound = sfx_grndab,
	traveltimer = 6,
	killfeedIcon = "RSRGRNDI",
	killfeedName = "Grenade Ring",
	killfeedObituary = {
		attacker = "$a's $rGrenade Ring fragged $v.",
		hurtself = "$v fragged themself with a Grenade Ring.",
		solo = "$v was fragged by a $rGrenade Ring."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_GRENADE_STICKYBOMB] = {
	knockback = 6*FRACUNIT,
	dontreflect = true,
	explosive = true,
	sparklestate = S_RSR_NIGHTSPARKLE_GRENADE,
	travelsound = sfx_gratab,
	traveltimer = 67,
	nosplashthrust = true,
	nothomable = true,
	killfeedIcon = "RSRGRALI",
	killfeedName = "Stickybomb",
	killfeedObituary = {
		attacker = "$v tripped over $a's $rStickybomb.",
		hurtself = "$v forgot they placed a Stickybomb there.",
		solo = "$v stepped on a $rStickybomb."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_BOMB] = {
	knockback = 3*FRACUNIT,
	dontreflect = true,
	explosive = true,
	sparklestate = S_RSR_NIGHTSPARKLE_BOMB,
	travelsound = sfx_bombab,
	traveltimer = 6,
	killfeedIcon = "RSRBOMBI",
	killfeedName = "Explosion Ring",
	killfeedObituary = {
		attacker = "$a's Explosion Ring exploded $v.",
		hurtself = "$v blew themself up with an Explosion Ring.",
		solo = "$v was exploded by an Explosion Ring."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_BOMB_MISSILEFORM] = {
	knockback = 3*FRACUNIT,
	dontreflect = true,
	explosive = true,
	thrustdamage = 30,
	aimthrust = true,
	sparklestate = S_RSR_NIGHTSPARKLE_BOMB,
	killfeedIcon = "RSRBMALI",
	killfeedName = "Self-Propel",
	killfeedObituary = {
		attacker = "$v stood too close to $a for Self-Proplusion.",
		hurtself = "$v propelled themself elsewhere.",
		solo = "$v was collaterally damaged by a Self-Propel."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_HOMING] = {
	knockback = 1*FRACUNIT/4,
	alertsound = sfx_homict,
	alerttimer = 31,
	travelsound = sfx_homiab,
	killfeedIcon = "RSRHOMGI",
	killfeedName = "Homing Ring",
	killfeedObituary = {
		attacker = "$a's $rHoming Ring hunted down $v.",
		solo = "$v was hunted down by a $rHoming Ring."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_HOMING_BOMB] = {
	knockback = 3*FRACUNIT,
	dontreflect = true,
	explosive = true,
	sparklestate = S_RSR_NIGHTSPARKLE_WASP,
	alertsound = sfx_hoatct,
	travelsound = sfx_hoatab,
	alerttimer = 695, -- That's a big number.
	killfeedIcon = "RSRHMALI",
	killfeedName = "Router RPB",
	killfeedObituary = {
		attacker = "$a's Router RPB stung $v.",
		hurtself = "$v stung themself with a Router RPB.",
		solo = "$v was stung by a Router RPB."
	}
}
RSR.MOBJ_INFO[MT_RSR_PROJECTILE_RAIL] = {
	knockback = 12*FRACUNIT,
	railring = true,
	killfeedIcon = "RSRRAILI",
	killfeedName = "Rail Ring",
	killfeedObituary = {
		attacker = "$a's $rRail Ring unmade $v.",
		solo = "$v was unmade by a $rRail Ring."
	}
}
RSR.MOBJ_INFO[MT_CORK] = {
	damage = 40,
	knockback = 6*FRACUNIT,
	killfeedIcon = "RSRGUN",
	killfeedName = "popgun",
	killfeedObituary = {
		attacker = "$a shot $v with a $rpopgun.",
		solo = "$v was shot by a $rpopgun cork."
	}
}
RSR.MOBJ_INFO[MT_LHRT] = {
	damage = 10,
	knockback = 9*FRACUNIT,
	killfeedIcon = "RSRHEART",
	killfeedObituary = {
		attacker = "$a's $rheart waged war and peace on $v.",
		solo = "A $rheart waged war and peace on $v."
	}
}

-- Enemy Projectiles
RSR.MOBJ_INFO[MT_JETTBULLET] = {damage = 10}
RSR.MOBJ_INFO[MT_MINE] = {damage = 20}
RSR.MOBJ_INFO[MT_TURRETLASER] = {damage = 5}
RSR.MOBJ_INFO[MT_CRUSHCLAW] = {damage = 35}
RSR.MOBJ_INFO[MT_ARROW] = {damage = 30}
RSR.MOBJ_INFO[MT_UNIBALL] = {damage = 25}
RSR.MOBJ_INFO[MT_POINTYBALL] = {damage = 25}
RSR.MOBJ_INFO[MT_DRAGONMINE] = {damage = 65}
RSR.MOBJ_INFO[MT_ROCKET] = {damage = 15}
RSR.MOBJ_INFO[MT_POPSHOT] = {damage = 25}
RSR.MOBJ_INFO[MT_SPINBOBERT_FIRE1] = {damage = 30}
RSR.MOBJ_INFO[MT_SPINBOBERT_FIRE2] = {damage = 30}
RSR.MOBJ_INFO[MT_LASER] = {damage = 30}
RSR.MOBJ_INFO[MT_EGGMOBILE_FIRE] = {damage = 15}
RSR.MOBJ_INFO[MT_GOOP] = {damage = 30}
RSR.MOBJ_INFO[MT_EGGMOBILE2_POGO] = {damage = 45}
RSR.MOBJ_INFO[MT_TORPEDO] = {damage = 35}
RSR.MOBJ_INFO[MT_TORPEDO2] = {damage = 35}
RSR.MOBJ_INFO[MT_EGGMOBILE4_MACE] = {damage = 40}
RSR.MOBJ_INFO[MT_FBOMB] = {damage = 45}
RSR.MOBJ_INFO[MT_ENERGYBALL] = {damage = 45}
RSR.MOBJ_INFO[MT_CYBRAK2016_SLUG] = {damage = 65}
RSR.MOBJ_INFO[MT_CYBRAK2016_SPARK] = {damage = 40}
RSR.MOBJ_INFO[MT_CYBRAK2016_SLASH] = {damage = 15}
RSR.MOBJ_INFO[MT_CYBRAKDEMON_MISSILE] = {damage = 20}
RSR.MOBJ_INFO[MT_CYBRAKDEMON_NAPALM_BOMB_LARGE] = {damage = 20}
RSR.MOBJ_INFO[MT_CYBRAKDEMON_NAPALM_BOMB_SMALL] = {damage = 10}
RSR.MOBJ_INFO[MT_CYBRAKDEMON_NAPALM_FLAMES] = {damage = 5}
RSR.MOBJ_INFO[MT_CYBRAKDEMON_FLAMESHOT] = {damage = 15}
RSR.MOBJ_INFO[MT_CYBRAKDEMON_FLAMEREST] = {damage = 5}
RSR.MOBJ_INFO[MT_CYBRAKDEMON_VILE_EXPLOSION] = {damage = 40}
RSR.MOBJ_INFO[MT_SMALLMACE] = {damage = 10}
RSR.MOBJ_INFO[MT_BIGMACE] = {damage = 20}
RSR.MOBJ_INFO[MT_SMALLFIREBAR] = {damage = 10}
RSR.MOBJ_INFO[MT_BIGFIREBAR] = {damage = 20}
RSR.MOBJ_INFO[MT_SPIKE] = {damage = 10}
RSR.MOBJ_INFO[MT_WALLSPIKE] = {damage = 10}

-- Pickups/Powerups
RSR.MOBJ_INFO[MT_RSR_PICKUP_RAIL] = {poweritem = true}
RSR.MOBJ_INFO[MT_RSR_POWERUP_INFINITY] = {poweritem = true}

-- Miscellaneous
RSR.MOBJ_INFO[MT_MINECART] = {
	killfeedIcon = "RSRMNCRT",
	killfeedObituary = {
		attacker = "$a derailed $v.",
		solo = "$v went off the rails."
	}
}
RSR.MOBJ_INFO[MT_TNTBARREL] = {
	explosive = true,
	killfeedIcon = "RSRTNT",
	killfeedObituary = {
		attacker = "$a blew $v to smithereens with a TNT barrel.",
		solo = "$v bought an ACME TNT barrel."
	}
}
RSR.MOBJ_INFO[MT_BLASTEXECUTOR] = {health = 1, nothomable = true, nosplashsightcheck = true, nosplashthrust = true} -- Don't let homing rings home in on blast executors

-- --------------------------------
 -- SHIELD INFO
 -- --------------------------------

if not RSR.SHIELD_INFO then
	---@type rsrshieldinfo_t[]
	RSR.SHIELD_INFO = {}
end

RSR.SHIELD_INFO[SH_NONE] = {
	armorpercent = FRACUNIT/2,
	damagepercent = FRACUNIT
}

RSR.SHIELD_INFO[SH_WHIRLWIND] = {
	icon = "RSRWINDI",
	name = "Whirlwind Shield"
}
RSR.SHIELD_INFO[SH_ARMAGEDDON] = {
	icon = "RSRARMAI",
	name = "Armageddon Shield"
}
RSR.SHIELD_INFO[SH_ELEMENTAL] = {
	icon = "RSRELEMI",
	name = "Elemental Shield",
	obituary = "$a's Elemental Shield stomped $v.",
	meleedamage = 65
}
RSR.SHIELD_INFO[SH_ATTRACT] = {
	icon = "RSRATTRI",
	name = "Attraction Shield",
	obituary = "$a's Attraction Shield shocked $v.",
	meleedamage = 15,
	damagepercent = 3*FRACUNIT/4
}
RSR.SHIELD_INFO[SH_FORCE] = {
	icon = "RSRFORCI",
	name = "Force Shield"
}
RSR.SHIELD_INFO[SH_FLAMEAURA] = {
	icon = "RSRFLAMI",
	name = "Flame Shield",
	obituary = "$a's Flame Shield burned $v.",
	meleedamage = 30
}
RSR.SHIELD_INFO[SH_BUBBLEWRAP] = {
	icon = "RSRBUBLI",
	name = "Bubble Shield",
	obituary = "$a's Bubble Shield squashed $v.",
	meleedamage = 40
}
RSR.SHIELD_INFO[SH_THUNDERCOIN] = {
	icon = "RSRTHNDI",
	name = "Thunder Shield"
}
