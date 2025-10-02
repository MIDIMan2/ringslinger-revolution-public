---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Grenade Weapon

RSR.AddAmmo("GRENADE", {
	amount = 10,
	maxamount = 100,
	motype = MT_RSR_PICKUP_GRENADE
})

RSR.AddWeapon("GRENADE", {
	ammotype = RSR.AMMO_GRENADE,
	ammoamount = 10,
	ammoalt = 2,
	class = 5,
	delay = 10,
	delayspeed = 5,
	delayalt = 35,
	delayaltspeed = 18,
	emerald = EMERALD5,
	icon = "RSRGRNDI",
	name = "Grenade Ring",
	namealt = "Stickybomb",
	pickup = MT_RSR_PICKUP_GRENADE,
	states = {
		draw = "S_GRENADE_DRAW",
		ready = "S_GRENADE_READY",
		holster = "S_GRENADE_HOSLTER",
		attack = "S_GRENADE_ATTACK",
		attackalt = "S_GRENADE_ATTACKALT"
	}
})

-- --------------------------------
-- PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_GRENADE] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_GRENADE,
	seesound = sfx_grndfr,
-- 	reactiontime = 2*TICRATE + 2,
	reactiontime = 55,
	attacksound = sfx_gbeep,
	painchance = 192*FRACUNIT,
	deathstate = S_RSR_RINGEXPLODE,
	deathsound = sfx_pop,
	speed = 50*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 35,
	activesound = sfx_s3k5d,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_BOUNCE|MF_GRENADEBOUNCE
}

states[S_RSR_PROJECTILE_GRENADE] =	{SPR_RSBG,	FF_ANIMATE|FF_FULLBRIGHT,	-1,	nil,	17,	2,	S_NULL}

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_GRENADE)
---@param mo mobj_t
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end
	if mo.health <= 0 then return end
	if not (mo.flags & MF_MISSILE) then return end

	-- Smoke particles
	RSR.ProjectileGhostTimer(mo, true)

	if mo.fuse % TICRATE == 0 then
		S_StartSound(mo, mo.info.attacksound)
	end

	local hitFloor = mo.z + mo.momz <= mo.floorz
	local hitCeiling = mo.z + mo.height + mo.momz >= mo.ceilingz

	if hitFloor or hitCeiling then
		if Valid(mo.subsector) and Valid(mo.subsector.sector) then
			local curSector = mo.subsector.sector
			if (hitFloor and curSector.floorpic == "F_SKY1" and curSector.floorheight == mo.floorz)
			or (hitCeiling and curSector.ceilingpic == "F_SKY1" and curSector.ceilingheight == mo.ceilingz) then
				P_RemoveMobj(mo)
				return
			end
		end
	end

	if mo.threshold < 3 then
		if (hitFloor and P_MobjFlip(mo) == 1)
		or (hitCeiling and P_MobjFlip(mo) == -1) then
			mo.threshold = $+1

			mo.momx = 3*$/5
			mo.momy = 3*$/5
-- 			mo.momz = -2*$/3
		end

		return
	elseif mo.threshold < 4 then
		mo.threshold = $+1
		mo.momx = 0
		mo.momy = 0
		mo.momz = 0
		return
	end
end, MT_RSR_PROJECTILE_GRENADE)
---@param mo mobj_t
addHook("MobjFuse", function(mo)
	if not Valid(mo) then return end

	P_ExplodeMissile(mo)
	return true
end, MT_RSR_PROJECTILE_GRENADE)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_GRENADE)
---@param mo mobj_t
---@param line line_t
addHook("MobjMoveBlocked", function(mo, _, line)
	if not Valid(mo) then return end

	-- Don't bounce against the sky
	if Valid(line) and P_CheckSkyHit(mo, line) then
		P_RemoveMobj(mo)
		return true
	end
end, MT_RSR_PROJECTILE_GRENADE)

-- --------------------------------
-- ALTFIRE PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_GRENADE_STICKYBOMB] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_GRENADE,
	seesound = sfx_gratfr,
	seestate = S_RSR_PROJECTILE_GRENADE_STICKYBOMB,
-- 	reactiontime = 2*TICRATE + 2,
	reactiontime = 128,
	attacksound = sfx_stikbp,
	painchance = 320*FRACUNIT,
	deathstate = S_RSR_RINGEXPLODE,
	deathsound = sfx_stikbm,
	xdeathstate = S_RSR_PROJECTILE_GRENADE_STICKYBOMB_DETONATE,
	speed = 45*FRACUNIT,
	radius = 19*FRACUNIT,
	height = 19*FRACUNIT,
	damage = 25,
	activesound = sfx_s3k5d,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_BOUNCE|MF_GRENADEBOUNCE|MF_STICKY
}

states[S_RSR_PROJECTILE_GRENADE_STICKYBOMB] =			{SPR_RSBG,	S|FF_FULLBRIGHT,	-1,	nil,	0,	0,	S_NULL}
states[S_RSR_PROJECTILE_GRENADE_STICKYBOMB_DETONATE] =	{SPR_RSBG,	T|FF_FULLBRIGHT,	7,	nil,	0,	0,	S_RSR_RINGEXPLODE}
states[S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND] =				{SPR_RSBG,	U|FF_FULLBRIGHT,	-1,	nil,	0,	0,	S_NULL}
states[S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND_DETONATE] =	{SPR_RSBG,	V|FF_FULLBRIGHT,	7,	nil,	0,	0,	S_RSR_RINGEXPLODE}

--- Activates the sticky bomb altfire of the Grenade ring.
---@param mo mobj_t
RSR.GrenadeStickyBombActivate = function(mo)
	if not Valid(mo) then return end

	S_StartSound(mo, mo.info.activesound)
	mo.momx, mo.momy, mo.momz = 0, 0, 0 -- Full stop!
	mo.flags = $|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT -- Stay there!
	mo.flags = $ & ~MF_STICKY -- Don't check again!
	S_StartSound(mo, sfx_gratrm)
end

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_GRENADE_STICKYBOMB)
---@param mo mobj_t
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end
	if mo.health <= 0 then return end
	if not (mo.flags & MF_MISSILE) then return end

	if mo.rsrBounced then
		mo.rsrBounced = $-1
	end

	-- Only do the proximity check when stuck to a wall
	if not (mo.flags & MF_STICKY) then
		local proxDist = FixedMul(96*FRACUNIT, mo.scale)

		searchBlockmap("objects", function(missile, enemy)
			if not (Valid(missile) and Valid(enemy)) then return end
			if enemy == missile then return end -- Don't detonate because you detected yourself
			if missile.target == enemy then return end -- Don't detonate because you detected your source
			if not (enemy.flags & MF_SHOOTABLE) or (enemy.flags & MF_MONITOR) then return end -- Monitors can't be blown up with splash damage
			if RSR.PlayersAreTeammates(missile.target.player, enemy.player) then return end -- Don't detonate because you detected a teammate

			local rsrInfo = RSR.MOBJ_INFO[enemy.type]
			if rsrInfo and rsrInfo.nothomable then return end -- Don't detonate because you detected a non-homable object (blast executor...)

			local dist = max(0, FixedHypot(FixedHypot(enemy.x - missile.x, enemy.y - missile.y), (enemy.z + enemy.height/2) - (missile.z + missile.height/2)) - enemy.radius)
			if dist > proxDist then return end

			-- Make sure the grenade ring can actually see the target before detonating
			if not P_CheckSight(missile, enemy) then return end

			S_StartSound(missile, sfx_gratrd)
			missile.health = 0
			missile.fuse = 0
			if missile.state == S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND then
				missile.state = S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND_DETONATE
			else
				missile.state = missile.info.xdeathstate
			end
			return true -- Stop the blockmap search
		end, mo, mo.x - proxDist, mo.x + proxDist, mo.y - proxDist, mo.y + proxDist)
	else
		-- Ghost trail
		RSR.ProjectileGhostTimer(mo)
	end

	if mo.fuse % 50 == 0 then
		--- Stickybomb beeps
		S_StartSound(mo, mo.info.attacksound)
	end
	if mo.fuse % 3 == 0 then
		--- Flings smoke, only do this when stuck to a wall
		if not (mo.flags & MF_STICKY) then
        	local spark = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_SMOKE)
			if Valid(spark) then
				-- Randomize the smoke's momentum
				spark.momx = RSR.RandomFixedRange(spark.scale, 3*spark.scale)
				spark.momy = RSR.RandomFixedRange(spark.scale, 3*spark.scale)
				spark.momz = RSR.RandomFixedRange(0, 3*spark.scale)
				if P_RandomChance(FRACUNIT/2) then spark.momx = -$ end
				if P_RandomChance(FRACUNIT/2) then spark.momy = -$ end
				if P_RandomChance(FRACUNIT/2) then spark.momz = -$ end
				-- Make the smoke shrink to scale 0 in roughly 2 seconds
				spark.scalespeed = spark.scale/70
				spark.destscale = 0
				spark.tics = 70
			end
		end
	end

	local hitFloor = mo.z + mo.momz <= mo.floorz
	local hitCeiling = mo.z + mo.height + mo.momz >= mo.ceilingz

	if (mo.flags & MF_STICKY) and (hitFloor or hitCeiling) then
		if Valid(mo.subsector) and Valid(mo.subsector.sector) then
			local curSector = mo.subsector.sector
			if (hitFloor and curSector.floorpic == "F_SKY1" and curSector.floorheight == mo.floorz)
			or (hitCeiling and curSector.ceilingpic == "F_SKY1" and curSector.ceilingheight == mo.ceilingz) then
				P_RemoveMobj(mo)
				return
			end
		end

		RSR.GrenadeStickyBombActivate(mo)
		mo.state = S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND

		-- Make the stickybomb stick to the plane it hits and flip it as necessary
		if hitFloor then
			mo.z = mo.floorz
			if P_MobjFlip(mo) == -1 then
				mo.eflags = $ & ~MFE_VERTICALFLIP
				mo.flags2 = $ & ~MF2_OBJECTFLIP
			end
		else
			mo.z = mo.ceilingz - mo.height
			if P_MobjFlip(mo) == 1 then
				mo.eflags = $|MFE_VERTICALFLIP
				mo.flags2 = $|MF2_OBJECTFLIP
			end
		end
	end
end, MT_RSR_PROJECTILE_GRENADE_STICKYBOMB)
---@param mo mobj_t
addHook("MobjFuse", function(mo)
	if not Valid(mo) then return end

	S_StartSound(mo, sfx_gratrd)
	mo.health = 0
	if mo.state == S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND then
		mo.state = S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND_DETONATE
	else
		mo.state = mo.info.xdeathstate
	end
	return true
end, MT_RSR_PROJECTILE_GRENADE_STICKYBOMB)
addHook("MobjMoveCollide", function(tmthing, thing)
	if not (Valid(tmthing) and Valid(thing)) then return end
	if not (tmthing.flags & MF_MISSILE) then return end

	-- Don't run collision code if the projectile flew over or under the target
	if tmthing.z > thing.z + thing.height
	or thing.z > tmthing.z + tmthing.height then
		return
	end

	if Valid(tmthing.target) then
		-- Don't hit the source of the projectile
		if thing == tmthing.target then
			return
		end
	end

	-- Go through players (unless friendlyfire is on) and bots
	if Valid(thing.player) then
		if Valid(tmthing.target) and Valid(tmthing.target.player) and RSR.PlayersAreTeammates(tmthing.target.player, thing.player)
		and not RSR.CheckFriendlyFire() then
			return false
		end

		if thing.player.bot then
			local bot = thing.player.bot

			-- Pass through 2-player bots
			if bot == BOT_2PAI or bot == BOT_2PHUMAN then
				return false
			end
		end
	end

	if not (thing.flags & MF_SHOOTABLE) then return end

	if tmthing.rsrBounced then
		return false
	end

	P_DamageMobj(thing, tmthing, tmthing.target, tmthing.info.damage)
	tmthing.momx = -$
	tmthing.momy = -$
	tmthing.rsrBounced = 4 -- Add a timer so the stickybomb doesn't get stuck on an object

	return false
end, MT_RSR_PROJECTILE_GRENADE_STICKYBOMB)
---@param mo mobj_t
addHook("MobjMoveBlocked", function(mo, _, line)
	if not Valid(mo) then return end

	-- Don't stick to the sky
	if Valid(line) and (mo.flags & MF_STICKY) then
		if P_CheckSkyHit(mo, line) then
			P_RemoveMobj(mo)
			return true
		end

		RSR.GrenadeStickyBombActivate(mo)
		mo.state = mo.info.seestate

		-- Make the sticky bomb actually stick to the wall instead of floating in the air
		local destX, destY = P_ClosestPointOnLineBound(mo.x, mo.y, line)
		local lineAngle = R_PointToAngle2(0, 0, line.dx, line.dy) + ANGLE_90
		if P_PointOnLineSide(mo.x, mo.y, line) then lineAngle = $ + ANGLE_180 end
		destX = $ - FixedMul(mo.radius/4, cos(lineAngle))
		destY = $ - FixedMul(mo.radius/4, sin(lineAngle))
		mo.angle = lineAngle
		P_MoveOrigin(mo, destX, destY, mo.z)
		return true
	end
end, MT_RSR_PROJECTILE_GRENADE_STICKYBOMB)

-- --------------------------------
-- PICKUP
-- --------------------------------

mobjinfo[MT_RSR_PICKUP_GRENADE] = {
	--$Name Grenade Pickup
	--$Sprite RSWGA0
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
	doomednum = 344,
	spawnstate = S_RSR_PICKUP_GRENADE,
	seestate = S_RSR_PICKUP_GRENADE_PANEL,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	radius = 16*FRACUNIT,
	height = 28*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_PICKUP_GRENADE] =			{SPR_RSWG,	FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}
states[S_RSR_PICKUP_GRENADE_PANEL] =	{SPR_RSWG,	I|FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}

addHook("MobjSpawn", RSR.ItemMobjSpawn, MT_RSR_PICKUP_GRENADE)
addHook("MapThingSpawn", RSR.WeaponMapThingSpawn, MT_RSR_PICKUP_GRENADE)
addHook("TouchSpecial", function(special, toucher)
	return RSR.WeaponTouchSpecial(special, toucher, RSR.WEAPON_GRENADE)
end, MT_RSR_PICKUP_GRENADE)
addHook("MobjFuse", RSR.WeaponMobjFuse, MT_RSR_PICKUP_GRENADE)
addHook("MobjThinker", RSR.WeaponPickupThinker, MT_RSR_PICKUP_GRENADE)

-- --------------------------------
-- ACTIONS & STATES
-- --------------------------------

local pspractions = PSprites.ACTIONS

--- Fires a Grenade ring from the player.
---@param player player_t
pspractions.A_GrenadeAttack = function(player, args)
	if not (Valid(player) and Valid(player.mo)) then return end

	RSR.SetWeaponDelay(player)

	local missile = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_GRENADE, player.mo.angle, player.cmd.aiming<<16)
	if Valid(missile) then
-- 		missile.rsrExplosiveRing = true -- Let the grenade ring deal knockback to the player on top of explosion knockback
		P_SetObjectMomZ(missile, FRACUNIT, true)
-- 		missile.fuse = missile.info.reactiontime
		-- Reaction time is being used for splash damage
		missile.fuse = 2*TICRATE + 2
	end
	RSR.TakeAmmoFromReadyWeapon(player, 1)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

--- Fires a Proximity Grenade ring from the player.
pspractions.A_GrenadeAttackAlt = function(player, args)
	if not (Valid(player) and Valid(player.mo)) then return end

	RSR.SetWeaponDelay(player, nil, nil, true)

	local missile = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_GRENADE_STICKYBOMB, player.mo.angle, player.cmd.aiming<<16)
	if Valid(missile) then
-- 		missile.rsrExplosiveRing = true -- Let the grenade ring deal knockback to the player on top of explosion knockback
		P_SetObjectMomZ(missile, FRACUNIT, true)
-- 		missile.fuse = missile.info.reactiontime
		-- Reaction time is being used for splash damage
		missile.fuse = 10*TICRATE + 2
	end
	RSR.TakeAmmoFromReadyWeapon(player, 2)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

local psprstates = PSprites.STATES

-- Draw
psprstates["S_GRENADE_DRAW"] =	{"RSRGRND",	"A",	1,	"A_RSRWeaponDraw",		{},	"S_GRENADE_DRAW"}
-- Holster
psprstates["S_GRENADE_HOLSTER"] =	{"RSRGRND",	"A",	1,	"A_RSRWeaponHolster",	{},	"S_GRENADE_HOLSTER"}
-- Ready
psprstates["S_GRENADE_READY"] =	{"RSRGRND",	"A",	1,	"A_RSRWeaponReady",	{},	"S_GRENADE_READY"}
-- Attack
psprstates["S_GRENADE_ATTACK"] =	{"RSRGRND",	"A",	0,	"A_GrenadeAttack",	{},	"S_GRENADE_RECOVER"}
-- Attack Alt
psprstates["S_GRENADE_ATTACKALT"] =	{"RSRGRND",	"A",	0,	"A_GrenadeAttackAlt",	{},	"S_GRENADE_RECOVER"}
-- Recover
psprstates["S_GRENADE_RECOVER"] =	{"RSRGRND",	"A",	1,	"A_RSRWeaponRecover",	{},	"S_GRENADE_RECOVER"}
