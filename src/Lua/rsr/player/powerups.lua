-- Ringslinger Revolution - Powerups System

--- Initializes the player's powerups table.
---@param player player_t
RSR.PlayerPowerupsInit = function(player)
	if not (Valid(player) and player.rsrinfo) then return end

	-- Reset this in any situation a player is spawned
	player.rsrinfo.powerups = {}
end

--- Returns true if the player has the given powerup.
---@param player player_t
---@param powerup integer Powerup to check for (RSR.POWERUP_ constant).
RSR.HasPowerup = function(player, powerup)
	if not (Valid(player) and player.rsrinfo) then return end
	if powerup == nil then powerup = 0 end

	for key, power in ipairs(player.rsrinfo.powerups) do
		if not power then continue end

		if power.powerup == powerup then
			return true, key
		end
	end

	return false
end

--- Runs the thinker(s) for the player's powerups
---@param player player_t
RSR.PlayerPowerupsTick = function(player)
	if not (Valid(player) and player.rsrinfo and player.rsrinfo.powerups) then return end

	local powerups = player.rsrinfo.powerups
	if not powerups then return end

	local key = 1
	while key <= #powerups do
		local power = powerups[key]

		if not power then
			table.remove(powerups, key)
			continue
		end

		power.tics = $-1

		if power.tics < 1 then
			table.remove(powerups, key)
			continue
		end

		key = $+1
	end
end
