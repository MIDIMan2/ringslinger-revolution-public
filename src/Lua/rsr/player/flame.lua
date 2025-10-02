-- Ringslinger Revolution - Player Flame Shield Trail
-- Borrowed from Retro Monitors

-- Spawn fire particles if the player has an "Inferno" shield
---@param mo mobj_t
addHook("MobjThinker", function(mo)
	if not RSR.GamemodeActive() then return end -- Only works in RSR maps
	if not (mo and mo.valid and mo.target and mo.target.valid) then return end
	if mo.rsrInfernoFire then return end

	local player = mo.target.player
	if not (player and player.valid) then
		mo.rsrInfernoFire = true
		return
	end

	-- Spindash dust should only become fire if the player has an "Inferno" shield
	if (player.powers[pw_shield] & SH_NOSTACK) ~= SH_FLAMEAURA then
		mo.rsrInfernoFire = true
		return
	end

	if not mo.rsrInfernoFire then
		mo.state = S_SPINDUST_FIRE1
		mo.rsrInfernoFire = true
	end
end, MT_SPINDUST)

--- Spawns a flame trail behind the player if they have a Flame Shield and are spinning on the ground.
---@param player player_t
RSR.PlayerFlameShieldTick = function(player)
	if not (player and player.valid and player.mo and player.mo.valid) then return end
	if (player.powers[pw_shield] & SH_NOSTACK) ~= SH_FLAMEAURA then return end

	if (player.pflags & PF_SPINNING) and player.speed > 4*player.mo.scale
	and P_IsObjectOnGround(player.mo) and (leveltime & 1) then
		P_ElementalFire(player)
	end
end
