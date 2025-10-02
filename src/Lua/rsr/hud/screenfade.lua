-- Ringslinger Revolution - Screen Fade HUD

--- Draws the player's screen fade to the HUD.
---@param player player_t
RSR.HUDScreenFade = function(v, player)
	if not RSR.GamemodeActive() then return end
	if not (v and Valid(player) and player.rsrinfo and player.rsrinfo.screenFade) then return end

	local screenFade = player.rsrinfo.screenFade
	if screenFade.tics > 0 and screenFade.origTics > 0 then
		local strength = screenFade.tics * (10*screenFade.strength/FRACUNIT) / screenFade.origTics
		strength = max(0, min(10, $)) -- Clamp the strength value so it doesn't go outside the range 0 - 10
-- 		v.fadeScreen(screenFade.color, strength)
		if strength > 0 then
			local transFlag = 0
			if strength < 10 then
				transFlag = (10 - strength) << V_ALPHASHIFT
			end
			v.drawFill(0, 0, v.width(), v.height(), screenFade.color|transFlag|V_NOSCALESTART|V_PERPLAYER)
		end
	end
end
