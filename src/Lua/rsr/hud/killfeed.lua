-- Ringslinger Revolution - Killfeed HUD

---@type rsrkillfeedentry_t[]
RSR.KILLFEED_MESSAGES = {}
RSR.KILLFEED_OFFSET = 0
RSR.KILLFEED_HEIGHT = 18
RSR.KILLFEED_FADE_TIMER = TICRATE/2
RSR.KILLFEED_TICS = 4*TICRATE

RSR.KILLFEED_DMG_INFO = {
	[DMG_WATER] = {
		icon = "RSRELEMI", -- TODO: Replace this with a clearer icon
		obituaryMobj = {
			attacker = "$a poisoned $v.",
			solo = "$v had too much poison to drink."
		},
		obituarySector = {
			attacker = "$a volunteered $v for a chemistry experiment.",
			solo = "$v became a chemistry demonstration."
		}
	},
	[DMG_FIRE] = {
		icon = "RSRFLAMI",
		obituaryMobj = {
			attacker = "$a incinerated $v.",
			solo = "$v became very toasty."
		},
		obituarySector = {
			attacker = "$a threw $v into lava.",
			solo = "$v melted in lava."
		}
	},
	[DMG_ELECTRIC] = {
		icon = "RSRTHNDI",
		obituary = {
			attacker = "$a electrocuted $v.",
			solo = "$v proved conductive.",
		}
	},
	[DMG_SPIKE] = {
		icon = "RSRSPIKE",
		obituary = {
			attacker = "$v walked into a spike whilst trying to escape $a.",
			solo = "$v got spiked.",
		}
	},
	[DMG_NUKE] = {
		icon = "RSRARMAI",
		obituary = {
			attacker = "$a's Armageddon Shield nuked $v.",
			solo = "$v is blasting off again.",
		}
	},
	[DMG_INSTAKILL] = {
		obituary = {
			solo = "$v spontaneously combusted.",
		}
	},
	[DMG_DROWNED] = {
		icon = "RSRDROWN",
		obituary = {
			attacker = "$a thought $v was a fish.",
			solo = "$v drowned.",
		}
	},
	[DMG_SPACEDROWN] = {
		icon = "RSRDROWN",
		obituary = {
			attacker = "$a threw $v out the airlock.",
			solo = "$v asphyxiated.",
		}
	},
	[DMG_DEATHPIT] = {
		icon = "RSRPIT",
		obituary = {
			attacker = "$a gave $v a little push.",
			solo = "$v didn't stick the landing.",
		}
	},
	[DMG_CRUSHED] = {
		icon = "RSRCRUSH",
		obituary = {
			attacker = "$a flattened $v.",
			solo = "$v was crushed.",
		}
	},
	[DMG_SPECTATOR] = {
		icon = "RSRSPECT",
		obituary = {
			attacker = "$a showed that $v couldn't take the heat.",
			solo = "$v went to the shadow realm.",
		}
	}
}

local RSR_CHATCOLOR_TO_TEXTCOLOR = {
	[V_MAGENTAMAP] =	"\x81",
	[V_YELLOWMAP] =		"\x82",
	[V_GREENMAP] =		"\x83",
	[V_BLUEMAP] =		"\x84",
	[V_REDMAP] =		"\x85",
	[V_GRAYMAP] =		"\x86",
	[V_ORANGEMAP] =		"\x87",
	[V_SKYMAP] =		"\x88",
	[V_PURPLEMAP] =		"\x89",
	[V_AQUAMAP] =		"\x8A",
	[V_PERIDOTMAP] =	"\x8B",
	[V_AZUREMAP] =		"\x8C",
	[V_BROWNMAP] =		"\x8D",
	[V_ROSYMAP] =		"\x8E",
	[V_INVERTMAP] =		"\x8F",
}

-- The following two functions are based off of CTFTEAMCODE and CTFTEAMENDCODE from SRB2's C code
local RSR_CHATCOLORCODE = function(pl)
	if not Valid(pl) then return "" end

	if pl.ctfteam then
		if pl.ctfteam == 1 then return "\x85" end
		return "\x84"
	elseif pl.skincolor and skincolors[pl.skincolor].chatcolor then
		return RSR_CHATCOLOR_TO_TEXTCOLOR[skincolors[pl.skincolor].chatcolor] or ""
	end

	return ""
end

local RSR_CHATCOLORENDCODE = function(pl)
	if not Valid(pl) then return "" end

	if pl.ctfteam or (pl.skincolor and skincolors[pl.skincolor].chatcolor) then
		return "\x80"
	end

	return ""
end

--- Gets the necessary mobj-related info for killfeed variables.
---@param moType mobjtype_t
---@param hasAttacker boolean|nil
---@param hurtSelf boolean|nil
RSR.KillfeedGetMobjInfo = function(moType, hasAttacker, hurtSelf)
	if not (moType and RSR.MOBJ_INFO[moType] and RSR.MOBJ_INFO[moType].killfeedObituary) then return end
	if type(RSR.MOBJ_INFO[moType].killfeedObituary) ~= "table" then
		print("\x82WARNING:\x80 killfeedObituary for Object type"..moType.." has not been converted to the new format!")
		return RSR.MOBJ_INFO[moType].killfeedIcon, nil
	end

	local obituary = nil
	if hurtSelf and RSR.MOBJ_INFO[moType].killfeedObituary.hurtself then
		obituary = RSR.MOBJ_INFO[moType].killfeedObituary.hurtself
	elseif hasAttacker and RSR.MOBJ_INFO[moType].killfeedObituary.attacker then
		obituary = RSR.MOBJ_INFO[moType].killfeedObituary.attacker
	elseif RSR.MOBJ_INFO[moType].killfeedObituary.solo then
		obituary = RSR.MOBJ_INFO[moType].killfeedObituary.solo
	end

	return RSR.MOBJ_INFO[moType].killfeedIcon, obituary
end

--- Adds an entry to the killfeed and prints a death message to the console.
---@param victimName string
---@param attackerName string|nil
---@param inflictorPatch string|nil Default is "RSREGGM".
---@param infReflected boolean|nil
---@param highlight boolean|nil
---@param skincolor skincolornum_t|nil
---@param obituary string|nil Default is "$v died.".
RSR.KillfeedPrint = function(victimName, attackerName, inflictorPatch, infReflected, highlight, skincolor, obituary)
	if not victimName then return end -- We can't display a message if there is no victim!
	inflictorPatch = $ or "RSREGGM" -- Always show Eggman for unknown causes of death
	obituary = $ or "$v died." -- Default message

	-- Alternative killfeed so players can see what they did in the logs
	local newString = string.gsub(obituary, "(%$%w?)", {
		["$a"] = attackerName or "The Shredded Cheese Man",
		["$r"] = infReflected and "reflected " or "",
		["$v"] = victimName,
	})
	print(newString)

	table.insert(RSR.KILLFEED_MESSAGES, {
		victim = victimName,
		inflictor = inflictorPatch,
		infReflected = infReflected,
		attacker = attackerName,
		highlight = highlight,
		skincolor = skincolor,
		tics = RSR.KILLFEED_TICS
	})
end

--- Gets the necessary damagetype-related info for killfeed varaibles.
---@param damageType integer
---@param hasInflictor boolean|nil
---@param hasAttacker boolean|nil
RSR.KillfeedGetDmgInfo = function(damageType, hasInflictor, hasAttacker)
	if not (damageType and RSR.KILLFEED_DMG_INFO[damageType & ~DMG_CANHURTSELF]) then return end
	local hurtSelf = (damageType & DMG_CANHURTSELF) and true or false
	damageType = $ & ~DMG_CANHURTSELF
	local obituary = nil
	local obituaryInfo = nil
	if hasInflictor and RSR.KILLFEED_DMG_INFO[damageType].obituaryMobj then
		obituaryInfo = RSR.KILLFEED_DMG_INFO[damageType].obituaryMobj
	elseif not hasInflictor and RSR.KILLFEED_DMG_INFO[damageType].obituarySector then
		obituaryInfo = RSR.KILLFEED_DMG_INFO[damageType].obituarySector
	elseif RSR.KILLFEED_DMG_INFO[damageType].obituary then
		obituaryInfo = RSR.KILLFEED_DMG_INFO[damageType].obituary
	end

	if obituaryInfo then
		if hurtSelf and obituaryInfo.hurtself then
			obituary = obituaryInfo.hurtself
		elseif hasAttacker and obituaryInfo.attacker then
			obituary = obituaryInfo.attacker
		elseif obituaryInfo.solo then
			obituary = obituaryInfo.solo
		end
	end

	return RSR.KILLFEED_DMG_INFO[damageType].icon, obituary
end

--- Adds a message to the killfeed.
---@param victim player_t
---@param inflictor mobj_t
---@param attacker player_t|nil
---@param damagetype integer
RSR.KillfeedAdd = function(victim, inflictor, attacker, damagetype)
	if not Valid(victim) then return end
	if #RSR.KILLFEED_MESSAGES >= 4 then table.remove(RSR.KILLFEED_MESSAGES, 1) end -- Remove the first message in the queue to make room for the new one

	local hookEvent, hookName = RSR.findEvent("KillfeedMsg")
	if hookEvent then
		for i, v in ipairs(hookEvent) do
			if v.typedef and hookEvent.typefor ~= nil then
				if not Valid(inflictor) or hookEvent.typefor(inflictor, v.typedef) == false then continue end
			end
			local result = RSR.tryRunHook(hookName, v, victim, inflictor, attacker, damagetype)
			if result then return end
		end
	end

	local victimName = string.format("%s%s%s", RSR_CHATCOLORCODE(victim), victim.name, RSR_CHATCOLORENDCODE(victim))
	local inflictorPatch = nil
	-- local obituary = "$a caused the mysterious disappearance of $v." -- How do you get this to happen. Indicates error if seen! (keeping this line as a comment, because it's funny -MIDIMan)
	local obituary = nil
	local meleeRandInt = 0
	if P_RandomRange(1,100) == 42 then
		meleeRandInt = 5
	else
		meleeRandInt = P_RandomRange(1,4)
	end
	local infReflected = false
	local attackerName = nil
	local highlight = false
	local skincolor = nil

	if Valid(attacker) then
		attackerName = string.format("%s%s%s", RSR_CHATCOLORCODE(attacker), attacker.name, RSR_CHATCOLORENDCODE(attacker))
	end

	if victim.rsrinfo and victim.rsrinfo.forceInflictorType and RSR.MOBJ_INFO[victim.rsrinfo.forceInflictorType] then
		inflictorPatch, obituary = RSR.KillfeedGetMobjInfo(victim.rsrinfo.forceInflictorType, Valid(attacker) and true or false, (damagetype & DMG_CANHURTSELF) and true or false)
		if victim.rsrinfo.forceInflictorReflected then infReflected = true end
	elseif Valid(inflictor) and RSR.MOBJ_INFO[inflictor.type] then
		inflictorPatch, obituary = RSR.KillfeedGetMobjInfo(inflictor.type, Valid(attacker) and true or false, (damagetype & DMG_CANHURTSELF) and true or false)
		if inflictor.rsrForceReflected then infReflected = true end
	elseif damagetype then
		inflictorPatch, obituary = RSR.KillfeedGetDmgInfo(damagetype, Valid(inflictor) and true or false, Valid(attacker) and true or false)
	elseif Valid(inflictor) and Valid(inflictor.player) and inflictor.player.rsrinfo then
		local infShield = (inflictor.player.powers[pw_shield] & SH_NOSTACK)
		if infShield and RSR.SHIELD_INFO[infShield]
		and (inflictor.player.pflags & PF_SHIELDABILITY) and not (infShield == SH_ATTRACT and not inflictor.player.rsrinfo.homing) then
			inflictorPatch = RSR.SHIELD_INFO[infShield].icon or "RSRARMRI"
			obituary = "$a's Shield killed $v."
			if RSR.SHIELD_INFO[infShield].obituary then obituary = RSR.SHIELD_INFO[infShield].obituary end
		elseif inflictor.player.powers[pw_super] then
			inflictorPatch = "RSRSUPRI"
			obituary = "$a's Super form defeated $v in righteous combat."
		elseif RSR.HasPowerup(inflictor.player, RSR.POWERUP_INVINCIBILITY) or inflictor.player.powers[pw_invulnerability] then
			inflictorPatch = "RSRINVNI"
			obituary = "$a's invincibility bested $v."
		elseif inflictor.player.charability2 == CA2_MELEE then
			if RSR.SKIN_INFO[skins[inflictor.player.skin].name] then
				inflictorPatch = RSR.SKIN_INFO[skins[inflictor.player.skin].name].meleeicon
				obituary = RSR.SKIN_INFO[skins[inflictor.player.skin].name].meleeobituary
			else
				inflictorPatch = RSR.SKIN_INFO["DEFAULT"].meleeicon
				obituary = RSR.SKIN_INFO["DEFAULT"].meleeobituary
			end
		else
			inflictorPatch = "RSRMELEE"
			if meleeRandInt == 1 then
				obituary = "$a punched out $v."
			elseif meleeRandInt == 2 then
				obituary = "$a threw hands with $v."
			elseif meleeRandInt == 3 then
				obituary = "$a beat up $v."
			elseif meleeRandInt == 5 then
				obituary = "$v death.melee.inflictor.$a"
			else
				obituary = "$a KO'd $v."
			end
			skincolor = inflictor.player.skincolor
		end
	elseif (victim.rsrinfo.deathFlags & RSR.DEATH_USEDKILLCMD) then
		obituary = "$v stopped being."
		if Valid(attacker) then obituary = "$a jumpscared $v." end
	elseif (victim.rsrinfo.deathFlags & RSR.DEATH_USEDEXPLODECMD) then
		inflictorPatch = "RSRXPLD"
		obituary = "$v's head asplode."
		if Valid(attacker) then obituary = "$a made $v blow a fuse." end
	elseif (victim.rsrinfo.deathFlags & RSR.DEATH_USEDDISINTEGRATECMD) then
		inflictorPatch = "RSRDISNT"
		obituary = "$v was abducted by aliens."
		if Valid(attacker) then obituary = "$a abducted $v." end
	elseif (victim.rsrinfo.deathFlags & RSR.DEATH_SWITCHEDTEAMS) then
		inflictorPatch = "RSRSWTCH"
		obituary = "$v abandoned their team."
		if Valid(attacker) and not RSR.PlayersAreTeammates(victim, attacker) then obituary = "$a joined $v's cause." end
	end

	-- Don't show highlighted backgrounds in splitscreen
	if not splitscreen and victim.rsrinfo and victim.rsrinfo.attackerInfo then
		for _, info in ipairs(victim.rsrinfo.attackerInfo) do
			if not info then continue end
			if Valid(info.player) and info.player == consoleplayer then
				highlight = true
			end
		end
	end

	RSR.KillfeedPrint(victimName, attackerName, inflictorPatch, infReflected, highlight, skincolor, obituary)
end

--- Draws the killfeed to the HUD.
---@param v videolib
RSR.HUDKillfeed = function(v)
	if not v then return end
	if not RSR.GamemodeActive() then return end

	-- Go through each killfeed message and draw them to the screen
	for key, info in ipairs(RSR.KILLFEED_MESSAGES) do
		if not info then continue end

		local bgColor = 31 -- Black
		if info.highlight then bgColor = 0 end -- White

		local inflictorPatch = v.cachePatch(info.inflictor)
		local patchWidth = 16
		local patchHeight = 16

		if Valid(inflictorPatch) then
			patchWidth = inflictorPatch.width
			patchHeight = inflictorPatch.height
		end

		local x = 318
		local y = 2 + ((key - 1) * RSR.KILLFEED_HEIGHT) + RSR.KILLFEED_OFFSET
		local flags = V_SNAPTOTOP|V_SNAPTORIGHT|V_PERPLAYER
		local flagsHalfTrans = V_SNAPTOTOP|V_SNAPTORIGHT|V_PERPLAYER|V_50TRANS

		if info.tics <= RSR.KILLFEED_FADE_TIMER then
			local strength = 10 * abs(info.tics - RSR.KILLFEED_FADE_TIMER) / RSR.KILLFEED_FADE_TIMER
			local transMap = strength<<V_ALPHASHIFT
			if strength > 9 then transMap = 0 end
			flags = $|transMap

			transMap = (strength/2 + 5)<<V_ALPHASHIFT
			if strength > 9 then transMap = 0 end
			flagsHalfTrans = ($ & ~V_ALPHAMASK)|transMap
		end

		local colormap = nil
		if info.skincolor then colormap = v.getColormap(TC_DEFAULT, info.skincolor) end

		local bgWidth = v.stringWidth(info.victim, 0, "thin") + patchWidth + 2
		if info.infReflected then bgWidth = $ + patchWidth + 2 end
		if info.attacker then bgWidth = $ + v.stringWidth(info.attacker, 0, "thin") + 2 end
		local bgX = x - bgWidth

		v.drawFill(bgX - 1, y - 1, bgWidth + 2, 18, bgColor|flagsHalfTrans)

		v.drawString(x, y + patchHeight/4, info.victim, flags|V_ALLOWLOWERCASE, "thin-right") -- Show the victim
		x = $ - v.stringWidth(info.victim, 0, "thin") - patchWidth - 2
		v.draw(x, y, inflictorPatch, flags, colormap) -- Show the inflictor: Player, projectile, or otherwise
		if info.infReflected then -- Show the Force Shield icon if the projectile was reflected
			x = $ - patchWidth - 2
			v.draw(x, y, v.cachePatch("RSRFORCI"), flags, colormap)
		end
		if info.attacker then -- Show the attacker, if there was one
			x = $ - 2
			v.drawString(x, y + patchHeight/4, info.attacker, flags|V_ALLOWLOWERCASE, "thin-right")
		end
	end
end

--- Runs the HUD thinker for the killfeed.
RSR.HUDKillfeedThinkFrame = function()
	local key = 1

	while key <= #RSR.KILLFEED_MESSAGES do
		local info = RSR.KILLFEED_MESSAGES[key]
		if not info then key = $+1; continue end

		info.tics = $-1
		if info.tics <= 0 then
			table.remove(RSR.KILLFEED_MESSAGES, key)
			if #RSR.KILLFEED_MESSAGES > 0 then
				RSR.KILLFEED_OFFSET = $ + RSR.KILLFEED_HEIGHT
			end
			continue
		end

		key = $+1
	end

	if RSR.KILLFEED_OFFSET > 0 then RSR.KILLFEED_OFFSET = $-1 end
end

--- Resets the killfeed when the map changes.
RSR.HUDKillfeedMapChange = function()
	RSR.KILLFEED_MESSAGES = {}
end
