-- Ringslinger Revolution - Flag Radar HUD

--- Draws a flag icon over the given target.
---@param v videolib
---@param player player_t
---@param thiscam camera_t
---@param target mobj_t Object to draw the flag icon over.
---@param useBlueFlag boolean|nil
RSR.HUDCTFFlagRadarTarget = function(v, player, thiscam, target, useBlueFlag)
	if not (v and Valid(player) and Valid(player.realmo) and Valid(target)) then return false end

	-- Shout-outs to Lunewulff, Skydusk, and MRCE for the (original) R_World2Screen3 function
	local result = R_World2Screen3FPS(v, player, thiscam, {x = target.x, y = target.y, z = target.z + target.height/2})
	local minScale, maxScale = FRACUNIT/32, FRACUNIT/8
	if result and result.onScreen then
		if not P_CheckSight(player.realmo, target) then
			minScale, maxScale = FRACUNIT/16, FRACUNIT/4
		end
		if result.scale > maxScale then return false end
		local transScale = 0
		if result.scale > minScale then
			transScale = FixedDiv(result.scale - minScale, maxScale - minScale)
		end
		-- R_World2Screen3 automatically adjusts for splitscreen, so roughly undo the adjustments
		if splitscreen then result.y = $*2 + (v.height()/v.dupy() - 200)*FRACUNIT/2 end
		local flagPatch = "RFLAGICO"
		if useBlueFlag then flagPatch = "BFLAGICO" end
		local transFlag = FixedMul(9, min(transScale, FRACUNIT))*V_10TRANS
		flagPatch = v.cachePatch($)
		v.drawCropped(
			result.x - 46*result.scale,
			result.y - 31*result.scale,
			2*max(FRACUNIT/32, result.scale),
			2*max(FRACUNIT/32, result.scale),
			flagPatch,
			V_PERPLAYER|transFlag,
			nil,
			0,
			0,
			flagPatch.width*FRACUNIT,
			flagPatch.height*FRACUNIT
		)
		return true
	end
end

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

	if Valid(redflag) and redflag.fuse > 1 then RSR.HUDCTFFlagRadarTarget(v, player, thiscam, redflag) end
	if Valid(blueflag) and blueflag.fuse > 1 then RSR.HUDCTFFlagRadarTarget(v, player, thiscam, blueflag, true) end

	-- Display a flagrunner radar
	for player2 in players.iterate do
		if not (Valid(player2) and Valid(player2.mo)) then continue end
		if not player2.gotflag or player == player2 then continue end -- Make sure the player is holding a flag and is not ourselves!
		if not RSR.HUDCTFFlagRadarTarget(v, player, thiscam, player2.mo, player2.gotflag == GF_BLUEFLAG) then continue end
	end
end
