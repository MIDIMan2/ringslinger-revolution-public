-- Ringslinger Revolutions - "Hype" Meter HUD

RSR.DISPLAY_HYPE_BAR = false
RSR.DISPLAY_HYPE_BAR2 = false
RSR.DISPLAY_HYPE_TIMER_MAX = TICRATE/3
RSR.DISPLAY_HYPE_TIMER = 0
RSR.DISPLAY_HYPE_TIMER2 = 0

--- Draws the player's emeralds to the HUD.
---@param player player_t
RSR.HUDHypeMeter = function(v, player)
	if not RSR.GamemodeActive() then return end
	if not (v and Valid(player) and player.rsrinfo) then return end

	-- drawNum always right-aligns the text, so adjust it to make it centered
	-- local hypeNumXOffset = 8*tostring(player.rsrinfo.hype):len()/2

	local displayHypeTimer = RSR.DISPLAY_HYPE_TIMER
	local displayHypeBar = RSR.DISPLAY_HYPE_BAR

	if splitscreen and player == secondarydisplayplayer then
		displayHypeTimer = RSR.DISPLAY_HYPE_TIMER2
		displayHypeBar = RSR.DISPLAY_HYPE_BAR2
	end

	if not (displayHypeBar or displayHypeTimer) then return end

	local barY = 195
	local barHeight = 4
	if displayHypeTimer > 0 then
		if displayHypeBar then
			barY = $ + (2*barHeight * ease.inquad(displayHypeTimer*FRACUNIT/RSR.DISPLAY_HYPE_TIMER_MAX))/FRACUNIT
		else
			barY = $ + 2*barHeight - (2*barHeight * ease.outquad(displayHypeTimer*FRACUNIT/RSR.DISPLAY_HYPE_TIMER_MAX))/FRACUNIT
		end
	end

	local vFlags = V_SNAPTOBOTTOM|V_PERPLAYER|V_HUDTRANS

	-- v.draw(89, barY, v.cachePatch("RSRHYPEB"), vFlags)
	v.drawCropped(89*FRACUNIT, barY*FRACUNIT, FRACUNIT, FRACUNIT, v.cachePatch("RSRHYPEB"), vFlags, nil, 0, 0,
		142*FRACUNIT,
		4*FRACUNIT
	)
	if player.powers[pw_super] and Valid(player.mo) and not (player.mo.state >= S_PLAY_SUPER_TRANS1 and player.mo.state <= S_PLAY_SUPER_TRANS6) then
		v.drawCropped(90*FRACUNIT, (barY + 1)*FRACUNIT, FRACUNIT, FRACUNIT, v.cachePatch("RSRHYPES"), vFlags, v.getColormap(TC_DEFAULT, player.mo.color), 0, 0,
			FixedMul(140*FRACUNIT, FixedDiv(player.rsrinfo.hype, RSR.MAX_HYPE)),
			2*FRACUNIT
		)
	else
		if player.rsrinfo.hype < RSR.TRIGGER_HYPE then
			v.drawCropped(90*FRACUNIT, (barY + 1)*FRACUNIT, FRACUNIT, FRACUNIT, v.cachePatch("RSRHYPEF"), vFlags, nil, 0, 0,
				FixedMul(140*FRACUNIT, FixedDiv(player.rsrinfo.hype, RSR.MAX_HYPE)),
				2*FRACUNIT
			)
		else
			local patch = "RSRHYPEG"
			if (leveltime & 4) then patch = "RSRHYPEH" end
			v.drawCropped(90*FRACUNIT, (barY + 1)*FRACUNIT, FRACUNIT, FRACUNIT, v.cachePatch(patch), vFlags, nil, 0, 0,
				FixedMul(140*FRACUNIT, FixedDiv(player.rsrinfo.hype, RSR.MAX_HYPE)),
				2*FRACUNIT
			)
		end
	end
	-- For testing purposes only
	-- v.drawString(160 + hypeNumXOffset, barY - 3, player.rsrinfo.hype or 0, vFlags, "right")
end

--- Runs the HUD thinker for the boss's health bar.
RSR.HUDHypeThinkFrame = function()
	if not RSR.GamemodeActive() then return end -- This hook should only run in RSR

	for player in players.iterate do
		if not P_IsLocalPlayer(player) then continue end
		if player == secondarydisplayplayer then
			if RSR.DISPLAY_HYPE_TIMER2 > 0 then RSR.DISPLAY_HYPE_TIMER2 = $-1 end

			local checkEmeralds = false
			if not (RSR.GAMETYPE_INFO[gametype] and RSR.GAMETYPE_INFO[gametype].nosuper) and ((not G_RingSlingerGametype() and emeralds == 127) or player.powers[pw_emeralds] == 127) then
				checkEmeralds = true
			end

			if (checkEmeralds and not RSR.DISPLAY_HYPE_BAR2)
			or (not checkEmeralds and RSR.DISPLAY_HYPE_BAR2) then
				RSR.DISPLAY_HYPE_BAR2 = not $
				RSR.DISPLAY_HYPE_TIMER2 = RSR.DISPLAY_HYPE_TIMER_MAX
			end
			continue
		end

		if RSR.DISPLAY_HYPE_TIMER > 0 then
			RSR.DISPLAY_HYPE_TIMER = $-1
		end

		local checkEmeralds = false
		if not (RSR.GAMETYPE_INFO[gametype] and RSR.GAMETYPE_INFO[gametype].nosuper) and ((not G_RingSlingerGametype() and emeralds == 127) or player.powers[pw_emeralds] == 127) then
			checkEmeralds = true
		end

		if (checkEmeralds and not RSR.DISPLAY_HYPE_BAR)
		or (not checkEmeralds and RSR.DISPLAY_HYPE_BAR) then
			RSR.DISPLAY_HYPE_BAR = not $
			RSR.DISPLAY_HYPE_TIMER = RSR.DISPLAY_HYPE_TIMER_MAX
		end
	end
end

--- Resets the hype bar's HUD info when the map changes.
RSR.HUDHypeMapChange = function(_)
	RSR.DISPLAY_HYPE_BAR = false
	RSR.DISPLAY_HYPE_BAR2 = false
	RSR.DISPLAY_HYPE_TIMER = 0
	RSR.DISPLAY_HYPE_TIMER2 = 0
end
