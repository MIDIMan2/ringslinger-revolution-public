---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Homing Weapon

RSR.HOMING_WASP_MAX = 21

RSR.AddAmmo("HOMING", {
	amount = 10,
	maxamount = 50,
	motype = MT_RSR_PICKUP_HOMING
})

RSR.AddWeapon("HOMING", {
	ammotype = RSR.AMMO_HOMING,
	ammoamount = 10,
	ammoalt = 3,
	class = 7,
	delay = 12,
	delayspeed = 6,
	delayalt = 60,
	delayaltspeed = 30,
	emerald = EMERALD7,
	icon = "RSRHOMGI",
	name = "Homing Ring",
	namealt = "Router RPB",
	pickup = MT_RSR_PICKUP_HOMING,
	states = {
		draw = "S_HOMING_DRAW",
		ready = "S_HOMING_READY",
		holster = "S_HOMING_HOSLTER",
		attack = "S_HOMING_ATTACK",
		attackalt = "S_HOMING_ATTACKALT_SOUND"
	}
})

-- --------------------------------
-- PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_HOMING] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_HOMING,
	seesound = sfx_homifr,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	speed = 90*FRACUNIT,
	radius = 19*FRACUNIT,
	height = 19*FRACUNIT,
	damage = 19,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

states[S_RSR_PROJECTILE_HOMING] =	{SPR_RSBH,	FF_ANIMATE|FF_FULLBRIGHT,	-1,	nil,	6,	2,	S_NULL}

--- Check if the enemy is within the missile's angle and pitch range.
---@param missile mobj_t
---@param enemy mobj_t
RSR.HomingRingAngleCheck = function(missile, enemy)
	if not (Valid(missile) and Valid(enemy)) then return end

	-- Don't target enemies outside the missile's angle search!
	local angleTo = R_PointToAngle2(missile.x, missile.y, enemy.x, enemy.y)
	local distTo = R_PointToDist2(missile.x, missile.y, enemy.x, enemy.y)
	local pitchTo = R_PointToDist2(0, missile.z + missile.height/2, distTo, enemy.z + enemy.height/2)
	local angleDelta = AngleFixed(angleTo - missile.angle)
	local pitchDelta = AngleFixed(pitchTo - missile.pitch)

	if angleDelta > 180*FRACUNIT then angleDelta = $ - 360*FRACUNIT end
	if pitchDelta > 180*FRACUNIT then pitchDelta = $ - 360*FRACUNIT end

	if abs(angleDelta) > 30*FRACUNIT then return end
	if abs(pitchDelta) > 30*FRACUNIT then return end

	return true
end

--- MobjThinker hook code for the Homing Ring.
---@param mo mobj_t
---@param radius fixed_t|nil
---@param noPlayerSpeed boolean|nil
RSR.HomingRingThinker = function(mo, radius, noPlayerSpeed)
	if not Valid(mo) then return end
	if not (mo.flags & MF_MISSILE) then return end

	-- Produce smoke if the homing ring is locked onto a target
	if not Valid(mo.tracer) then
		RSR.ProjectileGhostTimer(mo)
		if mo.rsrLockOnSound then mo.rsrLockOnSound = nil end
	else
		RSR.ProjectileGhostTimer(mo, true)
	end

	local tracer = mo.tracer
	if not (Valid(tracer) and tracer.health > 0) then
		if radius == nil then radius = 640*FRACUNIT end
		radius = FixedMul($, mo.scale)
		local xShift = FixedMul(radius/2, cos(mo.angle))
		local yShift = FixedMul(radius/2, sin(mo.angle))
		local x1 = mo.x + xShift - radius
		local x2 = mo.x + xShift + radius
		local y1 = mo.y + yShift - radius
		local y2 = mo.y + yShift + radius

		local bestDist = 2*radius
		local bestTracer = nil
		local bestDistEnemy = 2*radius
		local bestTracerEnemy = nil

		searchBlockmap("objects", function(missile, enemy)
			if not (Valid(missile) and Valid(enemy) and enemy.health > 0) then return end
			if missile.target == enemy then return end -- Don't target the projectile's source
			if not (enemy.flags & MF_SHOOTABLE) then return end
			if RSR.MOBJ_INFO[enemy.type] and RSR.MOBJ_INFO[enemy.type].nothomable then return end
-- 			if not Valid(enemy.player) then return end -- Only target players!

			if not P_CheckSight(missile, enemy) then return end -- Don't target enemies outside the missile's view!
			-- Don't target teammates
			if Valid(missile.target) and Valid(missile.target.player) and Valid(enemy.player) then
				if RSR.PlayersAreTeammates(missile.target.player, enemy.player) or (gametyperules & GTR_FRIENDLY) then return end
				if enemy.player.spectator and not RSR.CV_Ghostbusters.value then return end -- Don't target spectators if rsr_ghostbusters is false
			end

			-- Don't target enemies outside the missile's distance search!
			local dist = FixedHypot(FixedHypot(enemy.x - missile.x, enemy.y - missile.y), enemy.z - missile.z)
			if dist <= bestDist and RSR.HomingRingAngleCheck(missile, enemy) then
				bestDist = dist
				bestTracer = enemy
			end

			if ((enemy.flags & (MF_ENEMY|MF_BOSS)) or Valid(enemy.player))
			and dist <= bestDistEnemy and RSR.HomingRingAngleCheck(missile, enemy) then
				bestDistEnemy = dist
				bestTracerEnemy = enemy
			end
		end, mo, x1, x2, y1, y2)
		-- Prioritize enemies and non-teammate players over other shootables
		if Valid(bestTracerEnemy) then
			mo.tracer = bestTracerEnemy
			-- Don't need to check for mo.tracer here since bestTracerEnemy has already been checked
			S_StartSound(mo, sfx_homitg)
			return
		end
		mo.tracer = bestTracer
		if Valid(mo.tracer) then S_StartSound(mo, sfx_homitg) end
		return
	end

	local player = mo.tracer.player

	local angleTurn = ANGLE_22h
	if Valid(player) then
		-- Alert the player that they're being targetted by a homing ring
		if not mo.rsrLockOnSound then
			S_StartSound(mo.tracer, sfx_homiwn, player)
			mo.rsrLockOnSound = true
		end
		angleTurn = FixedAngle(4*FRACUNIT)
	end
	local angleTo = R_PointToAngle2(mo.x, mo.y, tracer.x, tracer.y)
	local distTo = R_PointToDist2(mo.x, mo.y, tracer.x, tracer.y)
	local pitchTo = R_PointToAngle2(0, mo.z + mo.height/2, distTo, tracer.z + tracer.height/2)

	mo.angle = RSR.AngleTowardsAngle($, angleTo, angleTurn)
	mo.pitch = RSR.AngleTowardsAngle($, pitchTo, angleTurn)

	local curSpeed = FixedHypot(FixedHypot(mo.momx, mo.momy), mo.momz)
	if not noPlayerSpeed and Valid(player) then -- Try to catch up with players, similar to the Deton
		curSpeed = player.normalspeed
		-- TODO: player.speed might cause problems
		if player.speed > player.normalspeed then curSpeed = FixedDiv(player.speed, tracer.scale) end -- Go faster if the player is going faster than their normalspeed
		curSpeed = FixedMul(3*$/4, tracer.scale)
	end

	P_InstaThrust(mo, mo.angle, FixedMul(cos(mo.pitch), curSpeed))
	mo.momz = FixedMul(sin(mo.pitch), curSpeed)
end

---@param mo mobj_t
addHook("MobjSpawn", function(mo)
	if not Valid(mo) then return end
	RSR.ProjectileSpawn(mo)
	mo.rsrLockOnSound = nil
	-- Remove the MF_NOBLOCKMAP flag if rsr_ghostbusters is on
	-- searchBlockmap will NOT work otherwise
	-- This could be a bad idea
	if RSR.CV_Ghostbusters.value then
		mo.flags = $ & ~MF_NOBLOCKMAP
	end
end, MT_RSR_PROJECTILE_HOMING)
addHook("MobjThinker", RSR.HomingRingThinker, MT_RSR_PROJECTILE_HOMING)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_HOMING)

-- --------------------------------
-- ALTFIRE PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_HOMING_BOMB] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_HOMING_BOMB,
	seesound = sfx_hoatfr,
	reactiontime = 35,
	painchance = 128*FRACUNIT,
	deathstate = S_RSR_RINGEXPLODE,
	deathsound = sfx_pop,
	speed = 80*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 19,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

states[S_RSR_PROJECTILE_HOMING_BOMB] =	{SPR_RSBH,	H|FF_ANIMATE|FF_FULLBRIGHT,	-1,	nil,	6,	1,	S_NULL}

---@param mo mobj_t
addHook("MobjSpawn", function(mo)
	if not Valid(mo) then return end
	RSR.ProjectileSpawn(mo)
	mo.rsrLockOnSound = nil
	-- Remove the MF_NOBLOCKMAP flag if rsr_ghostbusters is on
	-- searchBlockmap will NOT work otherwise
	-- This could be a bad idea
	if RSR.CV_Ghostbusters.value then
		mo.flags = $ & ~MF_NOBLOCKMAP
	end
end, MT_RSR_PROJECTILE_HOMING_BOMB)
addHook("MobjThinker", function(mo)
	return RSR.HomingRingThinker(mo, 1536*FRACUNIT, true)
end, MT_RSR_PROJECTILE_HOMING_BOMB)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_HOMING_BOMB)

-- --------------------------------
-- PICKUP
-- --------------------------------

mobjinfo[MT_RSR_PICKUP_HOMING] = {
	--$Name Homing Pickup
	--$Sprite RSWHA0
	--$Category Ringslinger Revolution/Weapons
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	--$Arg1 "Don't despawn in co-op"
	--$Arg1Type 11
	--$Arg1Enum offon
	--$Arg2 "Spawn as panel"
	--$Arg2Tooltip "Panels give the player more ammo."
	--$Arg2Type 11
	--$Arg2Enum yesno
	doomednum = 346,
	spawnstate = S_RSR_PICKUP_HOMING,
	seestate = S_RSR_PICKUP_HOMING_PANEL,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	radius = 16*FRACUNIT,
	height = 28*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_PICKUP_HOMING] =		{SPR_RSWH,	FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}
states[S_RSR_PICKUP_HOMING_PANEL] =	{SPR_RSWH,	I|FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}

addHook("MobjSpawn", RSR.ItemMobjSpawn, MT_RSR_PICKUP_HOMING)
addHook("MapThingSpawn", RSR.WeaponMapThingSpawn, MT_RSR_PICKUP_HOMING)
addHook("TouchSpecial", function(special, toucher)
	return RSR.WeaponTouchSpecial(special, toucher, RSR.WEAPON_HOMING)
end, MT_RSR_PICKUP_HOMING)
addHook("MobjFuse", RSR.WeaponMobjFuse, MT_RSR_PICKUP_HOMING)
addHook("MobjThinker", RSR.WeaponPickupThinker, MT_RSR_PICKUP_HOMING)

-- --------------------------------
-- ACTIONS & STATES
-- --------------------------------

local pspractions = PSprites.ACTIONS

--- Fires a Homing ring from the player.
---@param player player_t
pspractions.A_HomingAttack = function(player, args)
	if not (Valid(player) and Valid(player.mo)) then return end

	RSR.SetWeaponDelay(player)
	RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_HOMING, player.mo.angle, player.cmd.aiming<<16)
	RSR.TakeAmmoFromReadyWeapon(player, 1)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

--- Fires a Homing Bomb ring from the player.
---@param player player_t
pspractions.A_HomingAttackAlt = function(player, args)
	if not (Valid(player) and Valid(player.mo)) then return end

	if RSR.CheckPendingWeapon(player) then
		player.rsrinfo.waspTime = RSR.HOMING_WASP_MAX -- Reset waspTime here to prevent weirdness
		return
	end

	pspractions.A_LayerOffset(player, args)

	local lockOn = RSR.PlayerLookForEnemies(player, 2048*FRACUNIT, true, RSR.CV_Ghostbusters.value and true or false)
	if Valid(lockOn) then
		local visual = P_SpawnMobj(lockOn.x, lockOn.y, lockOn.z, MT_LOCKON)
		if Valid(visual) then
			visual.target = lockOn
			visual.drawonlyforplayer = player
			visual.alpha = FixedDiv(RSR.HOMING_WASP_MAX - player.rsrinfo.waspTime, RSR.HOMING_WASP_MAX)
		end
		player.rsrinfo.waspTime = $ - 1
		if (player.rsrinfo.waspTime == 0) then
			S_StartSound(lockOn, sfx_hoatpt)
		end
	end

	if not (player.cmd.buttons & BT_FIRENORMAL) or not (RSR.PlayerHasEmerald(player, EMERALD7) or player.powers[pw_super]) then
		S_StopSoundByID(player.mo, sfx_hoatsk)
		if Valid(lockOn) and (player.rsrinfo.waspTime < 1) then
			RSR.SetWeaponDelay(player)
			local homing = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_HOMING_BOMB, player.mo.angle, player.cmd.aiming<<16)
			if Valid(homing) then
				homing.tracer = lockOn
				-- Make it bigger
				homing.rsrOrigScale = homing.scale
				homing.scalespeed = homing.scale/3
				homing.destscale = 3*homing.scale/2
			end
			if Valid(lockOn) then
				S_StartSound(lockOn, sfx_hoattg)
			end
			RSR.TakeAmmoFromReadyWeapon(player, 3)
			player.rsrinfo.waspTime = RSR.HOMING_WASP_MAX

			if pspractions.A_RSRCheckAmmo(player, {}) then return end
			PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, "S_HOMING_RECOVER")
		else
			S_StartSound(player.mo, sfx_hoatno)
			player.rsrinfo.waspTime = RSR.HOMING_WASP_MAX
			pspractions.A_LayerOffset(player, {args[1], 0, 32*FRACUNIT})
			PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, "S_HOMING_ATTACKALT_RAISE")
		end
	end
end

local psprstates = PSprites.STATES

-- Draw
psprstates["S_HOMING_DRAW"] =	{"RSRHOMG",	"A",	1,	"A_RSRWeaponDraw",	{},	"S_HOMING_DRAW"}
-- Holster
psprstates["S_HOMING_HOLSTER"] =	{"RSRHOMG",	"A",	1,	"A_RSRWeaponHolster",	{},	"S_HOMING_HOLSTER"}
-- Ready
psprstates["S_HOMING_READY"] =	{"RSRHOMG",	"A",	1,	"A_RSRWeaponReady",	{},	"S_HOMING_READY"}
-- Attack
psprstates["S_HOMING_ATTACK"] =	{"RSRHOMG",	"A",	0,	"A_HomingAttack",	{},	"S_HOMING_RECOVER"}
-- Attack Alt
psprstates["S_HOMING_ATTACKALT_SOUND"] =	{"RSRHOMG",	"A",	0,	"A_StartSound",			{sfx_hoatsk},	"S_HOMING_ATTACKALT_LOWER"}
psprstates["S_HOMING_ATTACKALT_LOWER"] =	{"RSRHOMG",	"AAAA",	1,	"A_HomingAttackAlt",	{PSprites.PSPR_WEAPON,	0,	8*FRACUNIT,	true},	"S_HOMING_ATTACKALT"}
psprstates["S_HOMING_ATTACKALT"] =			{"RSRHOMG",	"A",	1,	"A_HomingAttackAlt",	{},	"S_HOMING_ATTACKALT"}
psprstates["S_HOMING_ATTACKALT_RAISE"] =	{"RSRHOMG",	"AAAA",	1,	"A_LayerOffset",		{PSprites.PSPR_WEAPON,	0,	-8*FRACUNIT,	true},	"S_HOMING_READY"}
-- Recover
psprstates["S_HOMING_RECOVER"] =	{"RSRHOMG",	"A",	1,	"A_RSRWeaponRecover",	{},	"S_HOMING_RECOVER"}
