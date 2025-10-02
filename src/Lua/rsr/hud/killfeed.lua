-- Ringslinger Revolution - Killfeed HUD

RSR.KILLFEED_MESSAGES = {}
RSR.KILLFEED_OFFSET = 0
RSR.KILLFEED_HEIGHT = 18
RSR.KILLFEED_FADE_TIMER = TICRATE/2
RSR.KILLFEED_TICS = 4*TICRATE

RSR.KILLFEED_DMG_INFO = {
	[DMG_WATER] = {
		icon = "RSRELEMI", -- TODO: Replace this with a clearer icon
		obituaryMobj = "had too much poison to drink",
		obituarySector = "was poisoned"
	},
	[DMG_FIRE] = {
		icon = "RSRFLAMI",
		obituaryMobj = "burned to death",
		obituarySector = "melted in lava"
	},
	[DMG_ELECTRIC] = {
		icon = "RSRTHNDI",
		obituary = "got electrocuted"
	},
	[DMG_SPIKE] = {
		icon = "RSRSPIKE",
		obituary = "got spiked"
	},
	[DMG_NUKE] = {
		icon = "RSRARMAI",
		obituaryMobj = "got nuked by %s's Armageddon blast",
		obituarySector = "got nuked"
	},
	[DMG_DROWNED] = {
		icon = "RSRDROWN",
		obituary = "drowned"
	},
	[DMG_SPACEDROWN] = {
		icon = "RSRDROWN",
		obituary = "drowned in space"
	},
	[DMG_DEATHPIT] = {
		icon = "RSRPIT",
		obituary = "fell into a pit"
	},
	[DMG_CRUSHED] = {
		icon = "RSRCRUSH",
		obituary = "was crushed"
	},
	[DMG_SPECTATOR] = {
		icon = "RSRSPECT",
		obituary = "became a spectator"
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

--- Gets the information needed for some killfeed variables
RSR.KillfeedGetMobjInfo = function(moType)
	if not (moType and RSR.MOBJ_INFO[moType]) then return "RSREGGM", "projectile", "killed" end
	return RSR.MOBJ_INFO[moType].killfeedIcon or "RSREGGM", RSR.MOBJ_INFO[moType].killfeedName or "projectile", RSR.MOBJ_INFO[moType].killfeedObituary or "killed"
end

--- Adds a message to the killfeed.
---@param victim player_t
---@param inflictor mobj_t
---@param attacker player_t
---@param damagetype integer
RSR.KillfeedAdd = function(victim, inflictor, attacker, damagetype)
	if not Valid(victim) then return end

	if #RSR.KILLFEED_MESSAGES >= 4 then
		table.remove(RSR.KILLFEED_MESSAGES, 1)
	end

	local victimName = string.format("%s%s%s", RSR_CHATCOLORCODE(victim), victim.name, RSR_CHATCOLORENDCODE(victim))
	local inflictorPatch = "RSREGGM" -- Always show Eggman for unknown causes of death
	local inflictorName = "The Shredded Cheese Man" -- We shouldn't be seeing these
	local obituary = "caused the mysterious disappearance of" -- How do you get this to happen
	local meleeRandInt = RSR.RandomFixedRange(1,4)
	local infReflected = false
	local attackerName = nil
	local highlight = false
	local skincolor = nil

	if not Valid(inflictor) then
		if victim.rsrinfo and victim.rsrinfo.forceInflictorType and RSR.MOBJ_INFO[victim.rsrinfo.forceInflictorType] then
			inflictorPatch, inflictorName, obituary = RSR.KillfeedGetMobjInfo(victim.rsrinfo.forceInflictorType)
			if victim.rsrinfo.forceInflictorReflected then infReflected = true end
		elseif damagetype then
			damagetype = $ & ~(DMG_CANHURTSELF)
			if RSR.KILLFEED_DMG_INFO[damagetype] and RSR.KILLFEED_DMG_INFO[damagetype].icon then inflictorPatch = RSR.KILLFEED_DMG_INFO[damagetype].icon end
		end
	else
		-- forceInflictorType should override the actual inflictor (used for Amy's hearts)
		if victim.rsrinfo and victim.rsrinfo.forceInflictorType and RSR.MOBJ_INFO[victim.rsrinfo.forceInflictorType] then
			inflictorPatch, inflictorName, obituary = RSR.KillfeedGetMobjInfo(victim.rsrinfo.forceInflictorType)
			if victim.rsrinfo.forceInflictorReflected then infReflected = true end
		elseif RSR.MOBJ_INFO[inflictor.type] then
			inflictorPatch, inflictorName, obituary = RSR.KillfeedGetMobjInfo(inflictor.type)
			if inflictor.rsrForceReflected then infReflected = true end
		elseif damagetype then
			damagetype = $ & ~(DMG_CANHURTSELF)
			if RSR.KILLFEED_DMG_INFO[damagetype] and RSR.KILLFEED_DMG_INFO[damagetype].icon then inflictorPatch = RSR.KILLFEED_DMG_INFO[damagetype].icon end
		elseif Valid(inflictor.player) and inflictor.player.rsrinfo then
			local infShield = (inflictor.player.powers[pw_shield] & SH_NOSTACK)
			if infShield and RSR.SHIELD_INFO[infShield]
			and (inflictor.player.pflags & PF_SHIELDABILITY) and not (infShield == SH_ATTRACT and not inflictor.player.rsrinfo.homing) then
				inflictorPatch = RSR.SHIELD_INFO[infShield].icon or "RSRARMRI"
				inflictorName = RSR.SHIELD_INFO[infShield].name or "Shield"
				if RSR.SHIELD_INFO[infShield].obituary then obituary = RSR.SHIELD_INFO[infShield].obituary end
			elseif inflictor.player.powers[pw_super] then
				inflictorPatch = "RSRSUPRI"
				inflictorName = "super form"
			elseif RSR.HasPowerup(inflictor.player, RSR.POWERUP_INVINCIBILITY) or inflictor.player.powers[pw_invulnerability] then
				inflictorPatch = "RSRINVNI"
				inflictorName = "invincibility"
			elseif inflictor.player.charability2 == CA2_MELEE then
				inflictorPatch = "RSRHAMMR"
				inflictorName = "Piko Piko Hammer"
				if RSR.SKIN_INFO[skins[inflictor.player.skin].name] then
					inflictorPatch = RSR.SKIN_INFO[skins[inflictor.player.skin].name].meleeicon
					inflictorName = RSR.SKIN_INFO[skins[inflictor.player.skin].name].meleename
				end
			else
				inflictorPatch = "RSRMELEE"
				inflictorName = "melee"
				if meleeRandInt == 1 then
					obituary = "punched out"
				elseif meleeRandInt == 2 then
					obituary = "threw hands with"
				elseif meleeRandInt == 3 then
					obituary = "beat up"
				else
					obituary = "KO'd"
				end
				skincolor = inflictor.player.skincolor
			end
		end
	end

	if Valid(attacker) then
		attackerName = string.format("%s%s%s", RSR_CHATCOLORCODE(attacker), attacker.name, RSR_CHATCOLORENDCODE(attacker))
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

	-- TODO: Revive this for 2.2.16
	-- Alternative killfeed so players can see what they did in the logs
	-- print(
	-- 	string.format("%s's %s%s %s %s.",
	-- 		attackerName or "",
	-- 		infReflected and "reflected " or "",
	-- 		inflictorName,
	-- 		obituary,
	-- 		victimName
	-- 	)
	-- )

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

--- Draws the killfeed to the HUD.
RSR.HUDKillfeed = function(v)
	if not v then return end
	if not RSR.GamemodeActive() then return end

	-- Go through each killfeed message and draw them to the screen
	for key, info in ipairs(RSR.KILLFEED_MESSAGES) do
		if not info then continue end

		local bgColor = 31
		if info.highlight then bgColor = 0 end

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
		if info.infReflected then -- Show if the projectile was reflected
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
