---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Grenade Weapon
-- TODO: Use MobjHitFloor and MobjHitCeiling when 2.2.16 comes out

RSR.STICKYBOMB_CHARGE_MAX = 3*TICRATE/2

RSR.AddAmmo("GRENADE", {
	amount = 10,
	maxamount = 50,
	motype = MT_RSR_PICKUP_GRENADE
})

RSR.AddWeapon("GRENADE", {
	ammotype = RSR.AMMO_GRENADE,
	ammoamount = 10,
	ammoalt = 1,
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
		attackalt = "S_GRENADE_ATTACKALT_SOUND"
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
	reactiontime = 50,
	attacksound = sfx_gbeep,
	painchance = 192*FRACUNIT,
	deathstate = S_RSR_RINGEXPLODELOW,
	deathsound = sfx_pop,
	speed = 50*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 15,
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

	RSR.ProjectileTravelSound(mo) -- Travelling sound
	RSR.ProjectileGhostTimer(mo, MT_SMOKE) -- Smoke particles

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
	reactiontime = 48,
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

states[S_RSR_PROJECTILE_GRENADE_STICKYBOMB] =					{SPR_RSBG,	S|FF_FULLBRIGHT,	-1,	nil,	0,	0,	S_NULL}
states[S_RSR_PROJECTILE_GRENADE_STICKYBOMB_ARMED] =				{SPR_RSBG,	T|FF_FULLBRIGHT,	-1,	nil,	0,	0,	S_NULL}
states[S_RSR_PROJECTILE_GRENADE_STICKYBOMB_DETONATE] =			{SPR_RSBG,	U|FF_FULLBRIGHT,	7,	nil,	0,	0,	S_RSR_RINGEXPLODE}
states[S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND] =				{SPR_RSBG,	V|FF_FULLBRIGHT,	-1,	nil,	0,	0,	S_NULL}
states[S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND_ARMED] =		{SPR_RSBG,	W|FF_FULLBRIGHT,	-1,	nil,	0,	0,	S_NULL}
states[S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND_DETONATE] =	{SPR_RSBG,	X|FF_FULLBRIGHT,	7,	nil,	0,	0,	S_RSR_RINGEXPLODE}

--- Starts the arming process of the Stickybomb.
---@param mo mobj_t
RSR.GrenadeStickyBombActivate = function(mo)
	if not Valid(mo) then return end

	S_StartSound(mo, mo.info.activesound)
	mo.momx, mo.momy, mo.momz = 0, 0, 0 -- Full stop!
	mo.flags = $|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT -- Stay there!
	mo.flags = $ & ~MF_STICKY -- Don't check again!
	S_StartSound(mo, sfx_gratrm) -- Play the "stick" sound
	mo.fuse = 41-- Arming fuse (roughly 1.184 seconds, length of arming sound)
	S_StartSound(mo, sfx_stikrm) -- Play arming sound
end

addHook("MobjSpawn", function(mo)
	if not Valid(mo) then return end
	mo.cusval = 0
	RSR.ProjectileSpawn(mo)
end, MT_RSR_PROJECTILE_GRENADE_STICKYBOMB)
---@param mo mobj_t
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end
	if mo.health <= 0 then return end
	if not (mo.flags & MF_MISSILE) then return end

	if mo.rsrBounced then mo.rsrBounced = $-1 end

	-- Only do the proximity check when stuck to a wall and armed
	if not (mo.flags & MF_STICKY) then
		if mo.cusval then
			RSR.ProximityDetonate(mo, 96*FRACUNIT, function(missile)
				S_StartSound(missile, sfx_gratrd)
				missile.health = 0
				missile.fuse = 0
				if missile.state == S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND_ARMED then
					missile.state = S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND_DETONATE
				else
					missile.state = missile.info.xdeathstate
				end
			end)
		end
	else
		RSR.ProjectileTravelSound(mo) -- Travelling sound
		RSR.ProjectileGhostTimer(mo) -- Ghost trail
	end

	-- Make the Stickybomb beep and fling smoke when armed
	if mo.cusval then
		if mo.fuse % 50 == 0 then S_StartSound(mo, mo.info.attacksound) end
		if mo.fuse % 3 then
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
			if (hitFloor and (curSector.floorpic == "F_SKY1" or curSector.damagetype == SD_DEATHPITNOTILT or curSector.damagetype == SD_DEATHPITTILT) and curSector.floorheight == mo.floorz)
			or (hitCeiling and (curSector.ceilingpic == "F_SKY1" or curSector.damagetype == SD_DEATHPITNOTILT or curSector.damagetype == SD_DEATHPITTILT) and curSector.ceilingheight == mo.ceilingz) then
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

	if not mo.cusval then
		mo.cusval = 1
		-- Reaction time is being used for splash damage
		mo.fuse = 10*TICRATE + 2
		S_StopSoundByID(mo, sfx_stikrm) -- Stop the arming sound
		S_StartSound(mo, sfx_stikrn) -- Armed sound
		if mo.state == S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND then
			mo.state = S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND_ARMED
		else
			mo.state = S_RSR_PROJECTILE_GRENADE_STICKYBOMB_ARMED
		end
		return true
	end

	S_StartSound(mo, sfx_gratrd)
	mo.health = 0
	if mo.state == S_RSR_PROJECTILE_GRENADE_STICKYBOMBGROUND_ARMED then
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
	radius = 24*FRACUNIT,
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
	RSR.TakeAmmoFromReadyWeapon(player, 1)

	local missile = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_GRENADE, player.mo.angle, player.cmd.aiming<<16)
	if Valid(missile) then
		P_SetObjectMomZ(missile, FRACUNIT, true)
		-- Reaction time is being used for splash damage
		missile.fuse = 2*TICRATE + 2
	end

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

--- Fires a Proximity Grenade ring from the player.
---@param player player_t
pspractions.A_GrenadeAttackAlt = function(player, args)
	if not (Valid(player) and Valid(player.mo)) then return end

	if RSR.CheckPendingWeapon(player) then
		player.rsrinfo.stickyCharge = RSR.STICKYBOMB_CHARGE_MAX -- Reset stickyCharge here to prevent weirdness
		return
	end

	pspractions.A_LayerOffset(player, args)
	if player.rsrinfo.stickyCharge > 0 then
		local decrement = 1
		-- Decrement waspTime faster if the player has speed shoes, is super, or has an Attraction Shield
		if player.powers[pw_sneakers] or player.powers[pw_super]
		or ((player.powers[pw_shield] & SH_NOSTACK == SH_ATTRACT) and (leveltime & 1)) then
			decrement = 2
		end
		print(decrement)
		player.rsrinfo.stickyCharge = max($ - decrement, 0)
	end

	if not (player.cmd.buttons & BT_FIRENORMAL) or not (RSR.PlayerHasEmerald(player, EMERALD7) or player.powers[pw_super]) then
		S_StopSoundByID(player.mo, sfx_gratch)
		RSR.SetWeaponDelay(player, nil, nil, true)
		RSR.TakeAmmoFromReadyWeapon(player, RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].ammoalt)

		local throwScale = FixedDiv((RSR.STICKYBOMB_CHARGE_MAX - player.rsrinfo.stickyCharge) / (RSR.STICKYBOMB_CHARGE_MAX/5), 5)

		local missile = RSR.SpawnPlayerMissile(
			player.mo,
			MT_RSR_PROJECTILE_GRENADE_STICKYBOMB,
			player.mo.angle,
			player.cmd.aiming<<16,
			nil,
			FixedMul(mobjinfo[MT_RSR_PROJECTILE_GRENADE_STICKYBOMB].speed, throwScale)
		)
		if Valid(missile) then
			P_SetObjectMomZ(missile, throwScale, true)
		end
		player.rsrinfo.stickyCharge = RSR.HOMING_WASP_MAX

		if pspractions.A_RSRCheckAmmo(player, {}) then return end
		PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, "S_GRENADE_RECOVER")
	end
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
psprstates["S_GRENADE_ATTACKALT_SOUND"] =	{"RSRGRND",	"A",	0,	"A_StartSound",			{sfx_gratch},	"S_GRENADE_ATTACKALT_LOWER"} -- TODO: Replace the sound
psprstates["S_GRENADE_ATTACKALT_LOWER"] =	{"RSRGRND",	"AAAA",	1,	"A_GrenadeAttackAlt",	{PSprites.PSPR_WEAPON,	0,	8*FRACUNIT,	true},	"S_GRENADE_ATTACKALT"}
psprstates["S_GRENADE_ATTACKALT"] =			{"RSRGRND",	"A",	1,	"A_GrenadeAttackAlt",	{},	"S_GRENADE_ATTACKALT"}
-- Recover
psprstates["S_GRENADE_RECOVER"] =	{"RSRGRND",	"A",	1,	"A_RSRWeaponRecover",	{},	"S_GRENADE_RECOVER"}
