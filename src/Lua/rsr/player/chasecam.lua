-- Ringslinger Revolution - Player Chasecam Function(s)

--- Sets the local player's chasecam
---@param player player_t
---@param toggle boolean
RSR.PlayerSetChasecam = function(player, toggle)
	if not Valid(player) then return end
	if toggle == nil then toggle = false end

	-- Only set chasecam for local players
	if player == secondarydisplayplayer then
		camera2.chase = toggle
	elseif player == consoleplayer then
		camera.chase = toggle
	end
end
