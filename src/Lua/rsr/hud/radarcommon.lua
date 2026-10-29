-- Ringslinger Revolution - Radar HUD Commonalities

--- Draws an icon over the given target.
---@param v videolib
---@param player player_t
---@param thiscam camera_t
---@param iconName string
---@param target mobj_t Object to draw the icon over.
---@param iconScale fixed_t?
RSR.HUDRadarTarget = function(v, player, thiscam, iconName, target, iconScale)
	if not (v and Valid(player) and Valid(player.realmo) and Valid(target)) then return false end
	if not iconScale then iconScale = FRACUNIT end

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
		local iconPatch = v.cachePatch(iconName)
		local transFlag = FixedMul(9, min(transScale, FRACUNIT))*V_10TRANS
		v.drawCropped(
			result.x - FixedMul(iconPatch.width*result.scale/2, iconScale),
			result.y - FixedMul(iconPatch.height*result.scale/2, iconScale),
			FixedMul(iconScale, max(FRACUNIT/32, result.scale)),
			FixedMul(iconScale, max(FRACUNIT/32, result.scale)),
			iconPatch,
			V_PERPLAYER|transFlag,
			nil,
			0,
			0,
			iconPatch.width*FRACUNIT,
			iconPatch.height*FRACUNIT
		)
		return true
	end
end
