-- Ringslinger Revolution - Attraction Shield for Deathmatch

--- Version of P_LookForEnemies that also looks for players.
---@param player player_t
---@param maxDist fixed_t|nil Maximum distance to search for enemies (Default is RING_DIST).
---@param searchEnemies boolean|nil
---@param searchSpectators boolean|nil
---@return mobj_t|nil
RSR.PlayerLookForEnemies = function(player, maxDist, searchEnemies, searchSpectators)
	if not (Valid(player) and Valid(player.mo)) then return end

	local closestMo
	if maxDist == nil then maxDist = RING_DIST end
	maxDist = FixedMul($, player.mo.scale)
	local span = ANGLE_90
	local dist = 0
	local closestDist = 0

	searchBlockmap("objects", function(pmo, enemy)
		if not (Valid(pmo) and Valid(enemy)) then return end
		if (enemy.flags & MF_NOCLIPTHING) then return end
		if enemy.health <= 0 then return end -- Dead
		if not (Valid(enemy.player) or (searchEnemies and (enemy.flags & (MF_ENEMY|MF_BOSS)) and (enemy.flags & MF_SHOOTABLE))) then return end -- Not a player or a shootable enemy/boss
		-- if not Valid(enemy.player) then return end -- Not a player
		if enemy == pmo then return end

		if Valid(enemy.player) then
			if RSR.PlayersAreTeammates(player, enemy.player) then return end -- Is a teammate

			if not enemy.player.rsrinfo then return end -- Not in RSR mode
			if enemy.player.rsrinfo.hurtByMelee then return end -- Has melee cooldown
			-- if enemy.player.powers[pw_invulnerability] then return end -- Has invincibility (commented out because it's funny)
			if enemy.player.powers[pw_flashing] then return end -- Is flashing
			if enemy.player.spectator and not searchSpectators then return end -- Is a spectator and searchSpectators is false
		end

		local zDist = (pmo.z + pmo.height/2) - (enemy.z + enemy.height/2)
		dist = R_PointToDist2(0, 0, pmo.x - enemy.x, pmo.y - enemy.y)

		-- Don't home upwards!
		if (pmo.eflags & MFE_VERTICALFLIP) then
			if enemy.z + enemy.height < pmo.z + pmo.height - FixedMul(MAXSTEPMOVE, pmo.scale) then
				return
			end
		elseif enemy.z > pmo.z + FixedMul(MAXSTEPMOVE, pmo.scale) then
			return
		end

		dist = R_PointToDist2(0, 0, dist, zDist)
		if dist > maxDist then return end -- Out of range

		if (twodlevel or pmo.flags2 & MF2_TWOD)
		and abs(pmo.y - enemy.y) > pmo.radius then
			return -- Not in your 2D plane
		end

		if Valid(closestMo) and dist > closestDist then return end

		local angleTo = R_PointToAngle2(
			pmo.x + P_ReturnThrustX(pmo, pmo.angle, pmo.radius),
			pmo.y + P_ReturnThrustY(pmo, pmo.angle, pmo.radius),
			enemy.x,
			enemy.y
		)
		local angleDelta = AngleFixed(angleTo - pmo.angle + span)
-- 		if angleDelta > 180*FRACUNIT then angleDelta = $ - 360*FRACUNIT end
		if angleDelta > 2*AngleFixed(span) then return end -- Behind back

		if not P_CheckSight(pmo, enemy) then return end -- Out of sight

		closestMo = enemy
		closestDist = dist
	end, player.mo, player.mo.x - maxDist, player.mo.x + maxDist,
	player.mo.y - maxDist, player.mo.y + maxDist)

	return closestMo
end

--- Version of P_HomingAttack that specifically targets players instead of enemies.
---@param player player_t Source player.
---@param player2 player_t Player being targetted.
RSR.PlayerHomingAttack = function(player, player2)
	if not (Valid(player) and Valid(player.mo) and Valid(player2) and Valid(player2.realmo) and player2.rsrinfo) then return false end
	-- Use realmo in case we're targetting a spectator

	local zDist = 0
	local ns = 0

	if (player2.realmo.flags & MF_NOCLIPTHING) then return false end
	if player2.realmo.health <= 0 then return false end
	if player2.rsrinfo.hurtByMelee then return false end

	-- Change angle
	player.mo.angle = R_PointToAngle2(player.mo.x, player.mo.y, player2.realmo.x, player2.realmo.y)
	player.drawangle = player.mo.angle

	-- Change slope
	zDist = player2.realmo.z - player.mo.z
	if P_MobjFlip(player.mo) == -1 then zDist = (player2.realmo.z + player2.realmo.height) - (player.mo.z + player.mo.height) end
	local dist = FixedHypot(FixedHypot(player2.realmo.x - player.mo.x, player2.realmo.y - player.mo.y), zDist)

	if dist < 1 then dist = 1 end

	if player.charability == CA_HOMINGTHOK and not (player.pflags & PF_SHIELDABILITY) then
		ns = FixedDiv(FixedMul(player.actionspd, player.mo.scale), 3*FRACUNIT/2)
	else
		ns = FixedMul(45*FRACUNIT, player.mo.scale)
	end

	player.mo.momx = FixedMul(FixedDiv(player2.realmo.x - player.mo.x, dist), ns)
	player.mo.momy = FixedMul(FixedDiv(player2.realmo.y - player.mo.y, dist), ns)
	player.mo.momz = FixedMul(FixedDiv(zDist, dist), ns)

	return true
end

--- Spawns a lock on indicator when the player can lock on to another player. Based off of P_DoJumpStuff and P_PlayerShieldThink.
---@param player player_t
RSR.PlayerLockOnThink = function(player)
	if not Valid(player) then return end

	local lockOnThok, visual

	if (player.pflags & PF_JUMPSTASIS) then return end

	if player.charability == CA_HOMINGTHOK and not (player.homing or player.rsrinfo.homing) and (player.pflags & PF_JUMPED)
	and (not (player.pflags & PF_THOKKED) or (player.charflags & SF_MULTIABILITY)) then
		lockOnThok = RSR.PlayerLookForEnemies(player, nil, nil, RSR.CV_Ghostbusters.value and true or false)
		if Valid(lockOnThok) and P_IsLocalPlayer(player) then
			visual = P_SpawnMobj(lockOnThok.x, lockOnThok.y, lockOnThok.z, MT_LOCKON)
			if Valid(visual) then
				visual.target = lockOnThok
				visual.drawonlyforplayer = player
			end
		end
	end

	if not ((player.pflags & PF_JUMPED) and not player.exiting and not P_PlayerInPain(player)) then return end
	if P_IsObjectOnGround(player.mo) or player.climbing or player.powers[pw_carry] then return end
	if (gametyperules & GTR_TEAMFLAGS) and player.gotflag then return end
	if (player.pflags & (PF_GLIDING|PF_SLIDING|PF_SHIELDABILITY)) then return end

	local lockOnShield

	if not player.powers[pw_super] and not (player.pflags & PF_SPINDOWN) -- TODO: Replace PF_SPINDOWN when 2.3 comes out(?)
	and (not (player.pflags & PF_THOKKED) or ((player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT and player.secondjump == UINT8_MAX)) then
		if (player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT and not (player.charflags & SF_NOSHIELDABILITY) then
			lockOnShield = RSR.PlayerLookForEnemies(player, nil, nil, RSR.CV_Ghostbusters.value and true or false)
			if Valid(lockOnShield) then
				if P_IsLocalPlayer(player) then
					local dovis = true
					if lockOnShield == lockOnThok then
						if (leveltime & 2) then
							dovis = false
						elseif Valid(visual) then
							P_RemoveMobj(visual)
						end
					end

					if dovis then
						visual = P_SpawnMobj(lockOnShield.x, lockOnShield.y, lockOnShield.z, MT_LOCKON)
						if Valid(visual) then
							visual.target = lockOnShield
							visual.drawonlyforplayer = player
							P_SetMobjStateNF(visual, visual.info.spawnstate+1)
						end
					end
				end
			end
		end
	end
end

--- Handles when the player can homing attack a player or not.
---@param player player_t
RSR.PlayerHomingThink = function(player)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	if player.rsrinfo.homingThreshold and not player.rsrinfo.homing then
		player.rsrinfo.homingThreshold = 0
	end

	RSR.PlayerLockOnThink(player)

	if (player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT
	and (player.pflags & PF_SHIELDABILITY) then
		if player.rsrinfo.homing and Valid(player.mo.tracer) then
			if not RSR.PlayerHomingAttack(player, player.mo.tracer.player) then
				player.pflags = $ & ~PF_SHIELDABILITY
				player.secondjump = UINT8_MAX
				P_SetObjectMomZ(player.mo, 6*FRACUNIT)
				if (player.mo.eflags & MFE_UNDERWATER) then
					player.mo.momz = FixedMul($, FRACUNIT/3)
				end
				player.rsrinfo.homing = 0
			end
		end

		-- If you're not jumping, then obviously you wouldn't be homing
		if not (player.pflags & PF_JUMPED) then
			player.rsrinfo.homing = 0
		end
	elseif player.charability == CA_HOMINGTHOK then
		-- If you've got a target, chase after it!
		if player.rsrinfo.homing and Valid(player.mo.tracer) then
			P_SpawnThokMobj(player)

			-- But if you don't, then stop homing.
			if not RSR.PlayerHomingAttack(player, player.mo.tracer.player) then
				if (player.mo.eflags & MFE_UNDERWATER) then
					P_SetObjectMomZ(player.mo, FixedDiv(457*FRACUNIT, 72*FRACUNIT))
				else
					P_SetObjectMomZ(player.mo, 10*FRACUNIT)
				end

				player.mo.momx = 0
				player.mo.momy = 0
				player.rsrinfo.homing = 0

				local player2 = player.mo.tracer.player
				if Valid(player2) and player2.rsrinfo and player2.rsrinfo.hurtByMelee then
					P_InstaThrust(player.mo, player.mo.angle, -(player.speed / 8))
				end

				player.mo.state = S_PLAY_SPRING
				player.pflags = ($ & ~PF_THOKKED)|PF_NOJUMPDAMAGE
			end
		end

		-- If you're not jumping, then obviously you wouldn't be homing
		if not (player.pflags & PF_JUMPED) then
			player.rsrinfo.homing = 0
		end
	else
		player.rsrinfo.homing = 0
	end

	if player.rsrinfo.homing then player.rsrinfo.homing = $-1 end
end

--- ShieldSpecial hook code for the player. Handles when the player can homing attack another player with an Attraction Shield.
---@param player player_t
RSR.PlayerShieldSpecial = function(player)
	if not RSR.GamemodeActive() then return end
	if not G_RingSlingerGametype() then return end
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	if player.powers[pw_super] or (player.pflags & PF_SPINDOWN) -- TODO: Replace PF_SPINDOWN when 2.3 comes out(?)
	or ((player.pflags & PF_THOKKED) and not ((player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT and player.secondjump == UINT8_MAX)) then
		return
	end

	if (player.powers[pw_shield] & SH_NOSTACK) ~= SH_ATTRACT then return end

	local lockOnShield = RSR.PlayerLookForEnemies(player, nil, nil, RSR.CV_Ghostbusters.value and true or false)
	if not Valid(lockOnShield) then return end -- Don't mess with the default behavior if a player wasn't found

	player.pflags = $|PF_THOKKED|PF_SHIELDABILITY
	player.pflags = $ & ~PF_SPINNING
	player.rsrinfo.homing = 2

	player.mo.tracer = lockOnShield
	player.mo.target = lockOnShield

	if Valid(lockOnShield) then
		player.mo.angle = R_PointToAngle2(player.mo.x, player.mo.y, lockOnShield.x, lockOnShield.y)
		player.pflags = $ & ~PF_NOJUMPDAMAGE
		player.mo.state = S_PLAY_ROLL
		S_StartSound(player.mo, sfx_s3k40)
		player.rsrinfo.homing = 3*TICRATE
	else
		S_StartSound(player.mo, sfx_s3ka6)
	end

	return true
end

--- AbilityShield hook code for the player. Handles when the player can homing attack another player with the Homing Thok.
---@param player player_t
RSR.PlayerAbilitySpecial = function(player)
	if not RSR.GamemodeActive() then return end
	if not G_RingSlingerGametype() then return end
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	if player.charability ~= CA_HOMINGTHOK then return end

	local lockOnThok = RSR.PlayerLookForEnemies(player, nil, nil, RSR.CV_Ghostbusters.value and true or false)
	if not Valid(lockOnThok) then return end -- Don't mess with the default behavior if a player wasn't found

	local actionspd = player.actionspd

	if (player.charflags & SF_DASHMODE) then
		actionspd = max($, FixedDiv(player.speed, player.mo.scale))
	end

	if (player.mo.eflags & MFE_UNDERWATER) then
		actionspd = $/2
	end

	P_InstaThrust(player.mo, player.mo.angle, FixedMul(actionspd, player.mo.scale)/2)

	if twodlevel then
		player.mo.momx = $/2
		player.mo.momy = $/2
	end

	player.mo.tracer = lockOnThok
	player.mo.target = lockOnThok

	if Valid(lockOnThok) then
		player.mo.state = S_PLAY_ROLL
		player.mo.angle = R_PointToAngle2(player.mo.x, player.mo.y, lockOnThok.x, lockOnThok.y)
		player.rsrinfo.homing = 3*TICRATE
	else
		player.mo.state = S_PLAY_FALL
		player.pflags = $ & ~PF_JUMPED
		player.mo.height = P_GetPlayerHeight(player)
	end
	player.pflags = $ & ~PF_NOJUMPDAMAGE

	player.drawangle = player.mo.angle

	if player.mo.info.attacksound and not player.spectator then
		S_StartSound(player.mo, player.mo.info.attacksound)
	end

	P_SpawnThokMobj(player)

	player.pflags = ($ & ~(PF_SPINNING|PF_STARTDASH))|PF_THOKKED

	return true
end

-- Make the Attraction Shield work with rsrinfo.homing instead of just homing
---@param mo mobj_t
addHook("MobjThinker", function(mo)
	if not RSR.GamemodeActive() then return end -- Don't run this code outside of RSR maps
	if not Valid(mo) then return end
	if not (mo.flags2 & MF2_SHIELD) then return end

	if Valid(mo.target) and Valid(mo.target.player) and mo.target.player.rsrinfo
	and mo.target.player.rsrinfo.homing and (mo.target.player.pflags & PF_SHIELDABILITY) then
		mo.state = mo.info.painstate
		mo.tics = $+1
	end
end, MT_ATTRACT_ORB)
