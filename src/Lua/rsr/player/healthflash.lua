-- Ringslinger Revolution - Health Flash System

--- Initializes the player's health flash system.
---@param player player_t
RSR.PlayerEHPFlashInit = function(player)
	if not (Valid(player) and player.rsrinfo) then return end

	player.rsrinfo.ehpFlash = {
		tics = 0,
		frequency = 0,
		color = 0
	}
end

--- Sets variables for the player's health flash.
---@param player player_t
---@param color integer
---@param tics tic_t
---@param frequency tic_t
RSR.SetEHPFlash = function(player, color, tics, frequency)
	if not (Valid(player) and player.rsrinfo and player.rsrinfo.ehpFlash) then return end
	if color == nil or frequency == nil or tics == nil then return end

	local ehpFlash = player.rsrinfo.ehpFlash
	ehpFlash.color = color
	ehpFlash.frequency = frequency
	ehpFlash.tics = tics
end

--- Runs the thinker for the player's health flash.
---@param player player_t
RSR.PlayerEHPFlashTick = function(player)
	if not (Valid(player) and player.rsrinfo and player.rsrinfo.ehpFlash) then return end

	if player.rsrinfo.ehpFlash.tics > 0 then
		player.rsrinfo.ehpFlash.tics = $-1
	end
end
