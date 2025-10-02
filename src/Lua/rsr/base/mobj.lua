---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Mobj Functions

--- Deals splash damage from the center of an Object with a given radius.
---@param mo mobj_t Object to deal splash damage from.
---@param bombDist integer|fixed_t|nil Radius of the splash damage (Default is 128*FRACUNIT).
---@param thrustDist integer|fixed_t|nil Radius of the splash damage to thrust Objects from (Default is 1.2x the bombDist).
---@param bombDamage integer|nil Maximum damage dealt to the Object from splash damage (Default is 90).
---@param fullDist integer|fixed_t|nil Maximum radius from the splash center to deal full damage (Default is 0.375x the bombDist).
---@param thrustDamage integer|nil Maximum thrust dealt to the Object from splash damage (Default is 20).
---@param aimThrust boolean|nil Makes mo's target get thrusted in the direction its aiming (used for the Explosion ring's altfire).
RSR.Explode = function(mo, bombDist, thrustDist, bombDamage, fullDist, thrustDamage, aimThrust)
	if not Valid(mo) then return end
	if bombDist == nil then bombDist = 128*FRACUNIT end
	if thrustDist == nil then thrustDist = 6*bombDist/5 end
	if not bombDamage then bombDamage = 90 end
	if fullDist == nil then fullDist = 3*bombDist/8 end
	if not thrustDamage then thrustDamage = 20 end

	bombDist = FixedMul($, mo.scale)
	thrustDist = FixedMul($, mo.scale)
	fullDist = FixedMul($, mo.scale)

	mo.rsrProjectile = nil
	mo.rsrRealDamage = true
	mo.rsrDontThrust = true -- The damage thrust code conflicts with the explosion thrust code, so disable it

	searchBlockmap("objects", function(bomb, enemy)
		if not (Valid(bomb) and Valid(enemy)) then return end
		if enemy == bomb then return end -- Don't damage yourself!
		if enemy.health <= 0 then return end -- Don't damage enemies with 0 health
		if not (enemy.flags & MF_SHOOTABLE) then return end -- Don't damage non-shootable objects
		if Valid(bomb.target) and RSR.PlayersAreTeammates(bomb.target.player, enemy.player) then return end -- Don't apply knockback to teammates

		-- Make an exception for MT_BLASTEXECUTOR so the breakable wall in Jade Valley works
		if enemy.type ~= MT_BLASTEXECUTOR and not P_CheckSight(bomb, enemy) then return end
		local source = bomb.target
		local damagetype = 0
		if enemy == bomb.target then source = nil end
		-- TODO: Uncomment this when 2.2.16 comes out and fixes being able to score points from hurting yourself
		-- (This is not an exaggeration, you can literally give yourself points by hurting yourself in Match with DMG_CANHURTSELF)
		-- if enemy == bomb.target then damagetype = $|DMG_CANHURTSELF end

		local distXY = FixedHypot(enemy.x - bomb.x, enemy.y - bomb.y)
		local distZ = (enemy.z + enemy.height/2) - (bomb.z + bomb.height/2)
		local dist = max(0, FixedHypot(distXY, distZ)) -- Consider subtracting enemy.radius to make larger enemies easier to kill
-- 		if dist < 0 then dist = 0 end

		-- Don't destroy monitors with splash damage
		if not (enemy.info.flags & MF_MONITOR) then
			if dist <= bombDist then
				local damage = bombDamage * min(FixedDiv(bombDist - dist, max(bombDist - fullDist, mo.scale)), FRACUNIT) / FRACUNIT
				if damage > 0 then
					P_DamageMobj(enemy, bomb, source, damage, damagetype)
				end
			end
		end

		if not Valid(enemy) then return end -- Sanity check in case the enemy was removed

		if dist <= thrustDist then
			local angle = R_PointToAngle2(bomb.x, bomb.y, enemy.x, enemy.y)
			local pitch = R_PointToAngle2(0, bomb.z + bomb.height/2, distXY, enemy.z + enemy.height/2)

			local enemyAngle = enemy.angle
			local enemyPitch = enemy.pitch
			if Valid(enemy.player) then
				enemyPitch = enemy.player.cmd.aiming<<16
			end
			local aheadX = enemy.x + FixedMul(cos(enemyAngle), cos(enemyPitch))
			local aheadY = enemy.y + FixedMul(sin(enemyAngle), cos(enemyPitch))
			local aheadZ = enemy.z + enemy.height/2 + sin(enemyPitch)

			-- Assume the player fired point blank at a wall
			if dist <= 2*bomb.radius then
				angle = R_PointToAngle2(aheadX, aheadY, enemy.x, enemy.y)
				pitch = R_PointToAngle2(0, aheadZ, FixedHypot(aheadX - enemy.x, aheadY - enemy.y), enemy.z + enemy.height/2)
			end

			-- enemy.flags wasn't working with gold monitors, so we check enemy.info.flags instead
			if not (enemy.info.flags & (MF_BOSS|MF_MONITOR)) then -- Don't thrust bosses or monitors
				local thrust = thrustDamage * FixedDiv(thrustDist - dist, thrustDist)
				-- Reverse the thrust if aimThrust is active
				if aimThrust and enemy == bomb.target then
					thrust = -$
				end

				-- Don't fling the enemy horizontally, if the player fired right under them
				if FixedHypot(aheadX - enemy.x, aheadY - enemy.y) > 0 then
					enemy.momx = $ + FixedMul(thrust, FixedMul(cos(angle), cos(pitch)))
					enemy.momy = $ + FixedMul(thrust, FixedMul(sin(angle), cos(pitch)))

					-- Fixes a bug where the player doesn't get thrusted while standing still
					if Valid(enemy.player) then
						enemy.player.rmomx = enemy.momx + enemy.player.cmomx
						enemy.player.rmomy = enemy.momy + enemy.player.cmomy
					end
				end

				enemy.momz = $ + FixedMul(thrust, sin(pitch))
			end
		end
	end, mo, mo.x - bombDist, mo.x + bombDist, mo.y - bombDist, mo.y + bombDist)

	P_StartQuake(bombDamage*FRACUNIT, 12, {x = mo.x, y = mo.y, z = mo.z + mo.height/2}, thrustDist)
-- 	P_StartQuake(bombDamage*FRACUNIT, 12, nil, nil)

	mo.rsrRealDamage = nil
end

--- Returns the damage dealt from a detonated Armageddon Shield, depending on how far away the target and the blast center were.
---@param target mobj_t Object getting damaged.
---@param inflictor mobj_t Origin of the detonation.
RSR.GetArmageddonDamage = function(target, inflictor)
	if not (Valid(target) and Valid(inflictor)) then return 0 end

	local dist = FixedHypot(FixedHypot(target.x - inflictor.x, target.y - inflictor.y), target.z - inflictor.z)
	-- TODO: Figure out if there's a way to increase P_BlackOw's distance???
	local bombDist = 1536*inflictor.scale -- [[1536*FRACUNIT]] is wha t the [NUKE] uses for its blast radius
	local fullDist = FixedMul(bombDist, FRACUNIT/3) -- bombDist * 0.333 or bombDist/3
	if dist <= bombDist then
		local bombDamage = 99 * min(FixedDiv(bombDist - dist, max(bombDist - fullDist, inflictor.scale)), FRACUNIT) / FRACUNIT
		if bombDamage > 0 then
			return bombDamage
		end
	end

	return 0
end

--- Makes the actor explode like an Explosion Ring or Grenade Ring, but for RSR.
---@param mo mobj_t
A_RSRRingExplode = function(mo, var1, var2)
	if not Valid(mo) then return end

	local sparkleState = S_NULL
	if G_GametypeHasTeams() and Valid(mo.target) and Valid(mo.target.player) then
		if mo.target.player.ctfteam == 1 then
			sparkleState = S_NIGHTSPARKLESUPER1 -- Red
		end
	elseif RSR.MOBJ_INFO[mo.type] and RSR.MOBJ_INFO[mo.type].sparklestate then
		sparkleState = RSR.MOBJ_INFO[mo.type].sparklestate
	end

	for d = 0, 15 do
		P_SpawnParaloop(
			mo.x,
			mo.y,
			mo.z + mo.height/2,
			FixedMul(mo.info.painchance, mo.scale),
			16,
			MT_NIGHTSPARKLE,
			d * ANGLE_22h,
			sparkleState,
			true
		)
	end
	S_StartSound(mo, sfx_prloop)

	if RSR.MOBJ_INFO[mo.type] then
		local rsrMobjInfo = RSR.MOBJ_INFO[mo.type]
		RSR.Explode(mo, mo.info.painchance, nil, mo.info.reactiontime, rsrMobjInfo.fulldamage, rsrMobjInfo.thrustdamage, rsrMobjInfo.aimthrust)
	else
		RSR.Explode(mo, mo.info.painchance, nil, mo.info.reactiontime)
	end
end

states[S_RSR_RINGEXPLODE] =	{SPR_NULL,	0,	0,	A_RSRRingExplode,	0,	0,	S_RSR_XPLD1}

states[S_RSR_XPLD1] =		{SPR_BOM1,	A,				2,	A_ShadowScream,	0,	0,	S_RSR_XPLD2}
states[S_RSR_XPLD2] =		{SPR_BOM1,	B,				2,	nil,			0,	0,	S_RSR_XPLD3}
states[S_RSR_XPLD3] =		{SPR_BOM1,	C|FF_ANIMATE,	6,	nil,			1,	3,	S_RSR_XPLD4}
states[S_RSR_XPLD4] =		{SPR_BOM1,	E|FF_ANIMATE,	8,	nil,			1,	4,	S_RSR_XPLDSOUND}
states[S_RSR_XPLDSOUND] =	{SPR_NULL,	A,				60,	nil,			0,	0,	S_NULL}

states[S_RSR_NIGHTSPARKLE_GRENADE] =	{SPR_NULL,	0,	0,	A_Dye,	0,	SKINCOLOR_MOSS,	S_NIGHTSPARKLE1}
states[S_RSR_NIGHTSPARKLE_BOMB] =		{SPR_NULL,	0,	0,	A_Dye,	0,	SKINCOLOR_JET,	S_NIGHTSPARKLE1}
states[S_RSR_NIGHTSPARKLE_WASP] =		{SPR_NULL,	0,	0,	A_Dye,	0,	SKINCOLOR_TOPAZ,	S_NIGHTSPARKLE1}

states[S_RSR_INVINSPARKLE] =	{SPR_RSIV,	A|FF_FULLBRIGHT|FF_ANIMATE,	6,	nil,	5,	1,	S_RSR_INVINSPARKLE2}
states[S_RSR_INVINSPARKLE2] =	{SPR_RSIV,	E|FF_FULLBRIGHT,			1,	nil,	0,	0,	S_RSR_INVINSPARKLE3}
states[S_RSR_INVINSPARKLE3] =	{SPR_RSIV,	D|FF_FULLBRIGHT,			1,	nil,	0,	0,	S_RSR_INVINSPARKLE4}
states[S_RSR_INVINSPARKLE4] =	{SPR_RSIV,	C|FF_FULLBRIGHT,			1,	nil,	0,	0,	S_RSR_INVINSPARKLE5}
states[S_RSR_INVINSPARKLE5] =	{SPR_RSIV,	B|FF_FULLBRIGHT,			1,	nil,	0,	0,	S_RSR_INVINSPARKLE6}
states[S_RSR_INVINSPARKLE6] =	{SPR_RSIV,	A|FF_FULLBRIGHT,			1,	nil,	0,	0,	S_NULL}
