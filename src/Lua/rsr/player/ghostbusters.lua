-- Ringslinger Revolution - rsr_ghostbusters Player Logic

--- Handles "rsr_ghostbusters" command logic. It gets around some hardcoded behavior where spectators can't be collided with at all.
---@param player player_t
RSR.PlayerGhostbustersTick = function(player)
	if not RSR.CV_Ghostbusters.value then return end -- rsr_ghostbusters should be on!
	if not (Valid(player) and Valid(player.realmo) and player.spectator) then return end -- This code should only run for spectators!
	if player.playerstate == PST_DEAD then return end -- Don't run this code if the player is dead!

	searchBlockmap("objects", function(pmo, mo)
		if not (Valid(pmo) and Valid(mo)) then return end
		if pmo == mo then return end
		-- Only homing projectiles and players should be detected
		if not (((mo.type == MT_RSR_PROJECTILE_HOMING or mo.type == MT_RSR_PROJECTILE_HOMING_BOMB) and (mo.flags & MF_MISSILE))
		or (Valid(mo.player) and mo.player.rsrinfo and mo.player.rsrinfo.homing and Valid(mo.tracer) and mo.tracer == pmo)) then
			return
		end
		if mo.health <= 0 then return end

		local blockDist = mo.radius + pmo.radius
		if abs(mo.x - pmo.x) >= blockDist or abs(mo.y - pmo.y) >= blockDist then
			return -- Didn't hit it
		end

		if pmo.z > mo.z + mo.height then return end -- Overhead
		if pmo.z + pmo.height < mo.z then return end -- Underneath

		if Valid(mo.player) then
			P_DamageMobj(pmo, mo, mo, 1, DMG_SPECTATOR)
		else
			P_DamageMobj(pmo, mo, mo.target, 1, DMG_SPECTATOR)
		end
		if Valid(mo) and not Valid(mo.player) then P_ExplodeMissile(mo) end
	end, player.realmo,
	player.realmo.x - 2*player.realmo.radius, player.realmo.x + 2*player.realmo.radius,
	player.realmo.y - 2*player.realmo.radius, player.realmo.y + 2*player.realmo.radius)
end
