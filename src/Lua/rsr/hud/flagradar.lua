-- Ringslinger Revolution - Flag Radar HUD

--- Draws a radar for flagrunners (and an indicator if the player has the flag) to the HUD.
---@param v videolib
---@param player player_t
---@param thiscam camera_t
RSR.HUDCTFFlagRadar = function(v, player, thiscam)
	if not v then return end
	if not RSR.GamemodeActive() then return end -- Only run in RSR maps
	if not (gametyperules & GTR_TEAMFLAGS) then return end -- Only run in CTF maps
	if not Valid(player) and Valid(player.realmo) then return end

	-- Display an indicator if the player has a flag
	if player.gotflag then
		local flagIconPatch = "RSRRFLAG"
		if player.gotflag == GF_BLUEFLAG then flagIconPatch = "RSRBFLAG" end
		local y = 180
		if player.rsrinfo and player.rsrinfo.powerups then
			y = $ - (#player.rsrinfo.powerups * RSR.POWERUP_YOFFSET) -- Don't draw on top of the powerups HUD
		end
		v.draw(300, y, v.cachePatch(flagIconPatch), V_PERPLAYER|V_HUDTRANS|V_SNAPTOBOTTOM|V_SNAPTORIGHT)
	end

	local iconScale = 2*FRACUNIT

	if Valid(redflag) and redflag.fuse > 1 then RSR.HUDRadarTarget(v, player, thiscam, "RFLAGICO", redflag, iconScale) end
	if Valid(blueflag) and blueflag.fuse > 1 then RSR.HUDRadarTarget(v, player, thiscam, "BFLAGICO", blueflag, iconScale) end

	-- Display a flagrunner radar
	for player2 in players.iterate do
		if not (Valid(player2) and Valid(player2.mo)) then continue end
		if not player2.gotflag or player == player2 then continue end -- Make sure the player is holding a flag and is not ourselves!
		if not RSR.HUDRadarTarget(v, player, thiscam, player2.gotflag == GF_BLUEFLAG and "BFLAGICO" or "RFLAGICO", player2.mo, iconScale) then continue end
	end
end
