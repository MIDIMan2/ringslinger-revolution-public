-- Ringslinger Revolution - Powerups HUD

RSR.POWERUP_YOFFSET = 18

--- Draws the player's active powerups to the HUD.
---@param v videolib
---@param player player_t
RSR.HUDPowerups = function(v, player)
	if not RSR.GamemodeActive() then return end
	if not (v and Valid(player) and player.rsrinfo) then return end

	local rsrinfo = player.rsrinfo
	if not (rsrinfo.powerups or #rsrinfo.powerups) then return end

	local x = 288
	local y = 188
	local vflags = V_PERPLAYER|V_SNAPTOBOTTOM|V_SNAPTORIGHT

	for key, power in ipairs(rsrinfo.powerups) do
		if not power then continue end
		local powerup = power.powerup

		if not RSR.POWERUP_INFO[powerup] then continue end

		local icon = RSR.POWERUP_INFO[powerup].icon or "RSRBASCI"
		local patch = v.cachePatch(icon)

		local colormap = nil
		if icon == "RSRSUPRI" then colormap = v.getColormap(player.skin, player.skincolor) end

		if Valid(patch) and power.tics > 3*TICRATE or (leveltime & 1) then
			local yOffset = -RSR.POWERUP_YOFFSET * (key - 1)
			v.draw(x - patch.width/2, y - patch.height/2 + yOffset, patch, vflags, colormap)
			v.drawNum(x + 28, y - 6 + yOffset, G_TicsToSeconds(power.tics), vflags)
		end
	end
end
