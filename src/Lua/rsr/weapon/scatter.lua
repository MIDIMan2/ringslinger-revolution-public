---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Scatter Weapon

RSR.AddAmmo("SCATTER", {
	amount = 20,
	maxamount = 50,
	motype = MT_RSR_PICKUP_SCATTER
})

RSR.AddWeapon("SCATTER", {
	ammotype = RSR.AMMO_SCATTER,
	ammoamount = 20,
	ammoalt = 1,
	class = 2,
	delay = 31,
	delayspeed = 16,
	delayalt = 31,
	delayaltspeed = 16,
	emerald = EMERALD2,
	icon = "RSRSCTRI",
	name = "Scatter Ring",
	namealt = "Mass Slug",
	pickup = MT_RSR_PICKUP_SCATTER,
	states = {
		draw = "S_SCATTER_DRAW",
		ready = "S_SCATTER_READY",
		holster = "S_SCATTER_HOSLTER",
		attack = "S_SCATTER_ATTACK",
		attackalt = "S_SCATTER_ATTACKALT"
	}
})

-- --------------------------------
-- PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_SCATTER] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_SCATTER,
	seesound = sfx_sctrfr,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	speed = 90*FRACUNIT,
	radius = 22*FRACUNIT,
	height = 22*FRACUNIT,
	damage = 19,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

states[S_RSR_PROJECTILE_SCATTER] =	{SPR_RSBS,	FF_FULLBRIGHT,	-1,	nil,	0,	0,	S_NULL}

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_SCATTER)
addHook("MobjThinker", RSR.ProjectileGhostTimer, MT_RSR_PROJECTILE_SCATTER)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_SCATTER)

mobjinfo[MT_RSR_PROJECTILE_SCATTER_FLAKCANNON_SUBMUNITION] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_SCATTER,
	seesound = sfx_sctrfr,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	speed = 45*FRACUNIT,
	radius = 22*FRACUNIT,
	height = 22*FRACUNIT,
	damage = 16,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_SCATTER_FLAKCANNON_SUBMUNITION)
addHook("MobjThinker", RSR.ProjectileGhostTimer, MT_RSR_PROJECTILE_SCATTER_FLAKCANNON_SUBMUNITION)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_SCATTER_FLAKCANNON_SUBMUNITION)

-- --------------------------------
-- ALTFIRE PROJECTILE
-- --------------------------------

--- Specialized version of P_ExplodeMissile that handles the Mass Slug's speed.
---@param mo mobj_t
RSR.ScatterFlakExplode = function(mo)
	if not Valid(mo) then return end

	mo.rsrPrevMomX = mo.momx
	mo.rsrPrevMomY = mo.momy
	mo.rsrPrevMomZ = mo.momz
	P_ExplodeMissile(mo)
end

--- Shoots a slightly more concentrated Scatter cluster.
---@param actor mobj_t
RSR.A_ScatterFlakCannon = function(actor, var1, var2)
	if not Valid(actor) then return end

	local hitFloor = actor.z <= actor.floorz
	local hitCeiling = actor.z + actor.height >= actor.ceilingz

	if hitFloor or hitCeiling then
		---@type pslope_t
		local slope = nil
		if hitFloor then
			if Valid(actor.floorrover) then
				slope = actor.floorrover.t_slope
			elseif Valid(actor.subsector) and Valid(actor.subsector.sector) then
				slope = actor.subsector.sector.f_slope
			end
		elseif hitCeiling then
			if Valid(actor.ceilingrover) then
				slope = actor.ceilingrover.b_slope
			elseif Valid(actor.subsector) and Valid(actor.subsector.sector) then
				slope = actor.subsector.sector.c_slope
			end
		end

		if Valid(slope) then
			-- TODO: Use the vector library for this when 2.2.16 comes out.
			local scatterVector = {
				x = FixedMul(cos(actor.angle), cos(actor.pitch)),
				y = FixedMul(sin(actor.angle), cos(actor.pitch)),
				z = sin(actor.pitch)
			}
			local normalVector = {
				x = slope.normal.x,
				y = slope.normal.y,
				z = slope.normal.z
			}
			local dotProduct = FixedMul(scatterVector.x, normalVector.x) + FixedMul(scatterVector.y, normalVector.y) + FixedMul(scatterVector.z, normalVector.z)

			-- Special thanks to this link for the calculation:
			-- https://gamedev.stackexchange.com/questions/23672/determine-resulting-angle-of-wall-collision
			local tempVector = {
				x = scatterVector.x - 2 * FixedMul(FixedMul(dotProduct, normalVector.x), normalVector.x),
				y = scatterVector.y - 2 * FixedMul(FixedMul(dotProduct, normalVector.y), normalVector.y),
				z = scatterVector.z - 2 * FixedMul(FixedMul(dotProduct, normalVector.z), normalVector.z)
			}

			actor.angle = R_PointToAngle2(0, 0, tempVector.x, tempVector.y)
			actor.pitch = R_PointToAngle2(0, 0, FixedHypot(tempVector.x, tempVector.y), tempVector.z)
		else
			actor.pitch = -$
		end
	end

	local flakAngleOffset = FixedAngle(6*FRACUNIT/2) -- 1.5 * ANG2, roughly
	local flakPitchOffset = FixedAngle(4*FRACUNIT/2) -- 1.0 * ANG2, roughly
	local flakSpeed = FixedHypot(FixedHypot(actor.rsrPrevMomX or 0, actor.rsrPrevMomY or 0), actor.rsrPrevMomZ or 0)

	for i = -1, 1 do
		if i == 0 then -- When the central projectile is spawned, iterate 3 times
			for j = -1, 1 do -- Modulate pitch instead of angle
				local flakShot = P_SpawnMobjFromMobj(actor, 0, 0, actor.info.height/2, MT_RSR_PROJECTILE_SCATTER_FLAKCANNON_SUBMUNITION)
				if Valid(flakShot) then
					if actor.rsrOrigScale then flakShot.scale = actor.rsrOrigScale end
					flakShot.angle = actor.angle
					flakShot.pitch = actor.pitch + (flakPitchOffset * j)
					flakShot.target = actor.target -- Don't let players hurt themselves with a Mass Slug
					flakShot.rsrProjectile = true
					if Valid(flakShot.target) then RSR.ColorTeamMissile(flakShot, flakShot.target.player) end

					RSR.MoveMissile(flakShot, flakShot.angle, flakShot.pitch, flakSpeed)
				end
			end
		else -- Modulate angle this time
			local flakShot = P_SpawnMobjFromMobj(actor, 0, 0, actor.info.height/2, MT_RSR_PROJECTILE_SCATTER_FLAKCANNON_SUBMUNITION)
			if Valid(flakShot) then
				if actor.rsrOrigScale then flakShot.scale = actor.rsrOrigScale end
				flakShot.angle = actor.angle + (flakAngleOffset * i)
				flakShot.pitch = actor.pitch
				flakShot.target = actor.target -- Don't let players hurt themselves with a Mass Slug
				flakShot.rsrProjectile = true
				if Valid(flakShot.target) then RSR.ColorTeamMissile(flakShot, flakShot.target.player) end

				RSR.MoveMissile(flakShot, flakShot.angle, flakShot.pitch, flakSpeed)
			end
		end
	end
end

mobjinfo[MT_RSR_PROJECTILE_SCATTER_FLAKCANNON] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_SCATTER,
	seesound = sfx_scatfr,
	deathstate = S_RSR_PROJECTILE_SCATTER_FLAKCANNON,
	deathsound = sfx_scatxp,
	speed = 80*FRACUNIT,
	radius = 22*FRACUNIT,
	height = 22*FRACUNIT,
	damage = 50,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

states[S_RSR_PROJECTILE_SCATTER_FLAKCANNON] =	{SPR_RSBS,	FF_FULLBRIGHT,	0,	RSR.A_ScatterFlakCannon,	0,	0,	S_WPLD1}

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_SCATTER_FLAKCANNON)
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end
	RSR.ProjectileGhostTimer(mo)
	if not (mo.flags & MF_MISSILE) then return end
	mo.rsrPrevMomX = mo.momx
	mo.rsrPrevMomY = mo.momy
	mo.rsrPrevMomZ = mo.momz
end, MT_RSR_PROJECTILE_SCATTER_FLAKCANNON)
---@param tmthing mobj_t
---@param thing mobj_t
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

	---@type integer|INT32
	local damage = tmthing.info.damage
	if tmthing.rsrDamage then damage = tmthing.rsrDamage end
	P_DamageMobj(thing, tmthing, tmthing.target, damage)
	if Valid(tmthing) then
		tmthing.angle = $ + ANGLE_180
		P_ExplodeMissile(tmthing)
	end
	return false
end, MT_RSR_PROJECTILE_SCATTER_FLAKCANNON)
---@param mo mobj_t
---@param thing mobj_t
---@param line line_t
addHook("MobjMoveBlocked", function(mo, thing, line)
	if not (Valid(mo) and (mo.flags & MF_MISSILE)) then return end

	if Valid(line) then
		-- Don't bounce against the sky
		-- TODO: It still happens in that one Scatter ring alcove in Jade Valley, because P_CheckSkyHit is buggy.
		if P_CheckSkyHit(mo, line) then
			P_RemoveMobj(mo)
			return true
		end

		P_BounceMove(mo)
		mo.angle = R_PointToAngle2(0, 0, mo.momx, mo.momy)
		return
	end

	if Valid(thing) then
		mo.angle = $ + ANGLE_180
	end
end, MT_RSR_PROJECTILE_SCATTER_FLAKCANNON)

-- --------------------------------
-- PICKUP
-- --------------------------------

mobjinfo[MT_RSR_PICKUP_SCATTER] = {
	--$Name Scatter Pickup
	--$Sprite RSWSA0
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
	doomednum = 341,
	spawnstate = S_RSR_PICKUP_SCATTER,
	seestate = S_RSR_PICKUP_SCATTER_PANEL,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	radius = 16*FRACUNIT,
	height = 28*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_PICKUP_SCATTER] =			{SPR_RSWS,	FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}
states[S_RSR_PICKUP_SCATTER_PANEL] =	{SPR_RSWS,	I|FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}

addHook("MobjSpawn", RSR.ItemMobjSpawn, MT_RSR_PICKUP_SCATTER)
addHook("MapThingSpawn", RSR.WeaponMapThingSpawn, MT_RSR_PICKUP_SCATTER)
addHook("TouchSpecial", function(special, toucher)
	return RSR.WeaponTouchSpecial(special, toucher, RSR.WEAPON_SCATTER)
end, MT_RSR_PICKUP_SCATTER)
addHook("MobjFuse", RSR.WeaponMobjFuse, MT_RSR_PICKUP_SCATTER)
addHook("MobjThinker", RSR.WeaponPickupThinker, MT_RSR_PICKUP_SCATTER)

-- --------------------------------
-- ACTIONS & STATES
-- --------------------------------

local pspractions = PSprites.ACTIONS

--- Constantly checks if the player is holding the fire or altfire button, then fires the Bounce Ring.
---@param player player_t
pspractions.A_ScatterReady = function(player, args)
	if not RSR.IsPSpritesValid(player) then return end

	local rsrinfo = player.rsrinfo

	if not RSR.CanUseWeapons(player) then
		if rsrinfo.weaponDelayOrig then rsrinfo.weaponDelayOrig = 0 end
		if rsrinfo.weaponDelay then rsrinfo.weaponDelay = 0 end

		if rsrinfo.readyWeapon ~= RSR.WEAPON_NONE then
			local origWeapon = rsrinfo.readyWeapon
			rsrinfo.readyWeapon = RSR.WEAPON_NONE
			RSR.DrawWeapon(player, RSR.WEAPON_NONE, true)
			if origWeapon > RSR.WEAPON_NONE then
				rsrinfo.pendingWeapon = origWeapon
			end
		end
		return
	end
	if RSR.CheckPendingWeapon(player) then return end

	local weaponInfo = RSR.WEAPON_INFO[player.rsrinfo.readyWeapon]
	if (player.cmd.buttons & BT_FIRENORMAL) and not (rsrinfo.lastbuttons & BT_FIRENORMAL) and (player.powers[pw_super] or RSR.PlayerHasEmerald(player, weaponInfo.emerald)) then
		if Valid(rsrinfo.scatterFlak) and (rsrinfo.scatterFlak.flags & MF_MISSILE) then
			P_ExplodeMissile(rsrinfo.scatterFlak)
			return
		end
		if RSR.FireWeaponAlt(player) then return end
		-- Make sure the player has an a altfire attack state and ammo at all before making the sound
		if not (rsrinfo.lastbuttons & BT_FIRENORMAL) and RSR.CheckAmmo(player) and weaponInfo.states.attackalt then
			S_StartSound(nil, sfx_noammo, player)
		end
	end

	if (player.cmd.buttons & BT_ATTACK) then
		RSR.FireWeapon(player)
		return
	end
end

--- Fires five scatter rings from the player.
---@param player player_t
pspractions.A_ScatterAttack = function(player, args)
	if not (Valid(player) and Valid(player.mo)) then return end

	RSR.SetWeaponDelay(player)

	local angle = player.mo.angle
	local pitch = player.cmd.aiming<<16

	local angleOffset = FixedAngle(7*FRACUNIT/2) -- 1.75 * ANG2, roughly
	local pitchOffset = FixedAngle(5*FRACUNIT/2) -- 1.25 * ANG2, roughly

	RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_SCATTER, angle, pitch)
	RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_SCATTER, angle + angleOffset, pitch)
	RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_SCATTER, angle, pitch + pitchOffset)
	RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_SCATTER, angle - angleOffset, pitch)
	RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_SCATTER, angle, pitch - pitchOffset)
	RSR.TakeAmmoFromReadyWeapon(player, 1)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

--- Fires a Scatter Mass Slug ring from the player.
---@param player player_t
pspractions.A_ScatterAttackAlt = function(player, args)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	-- Hack to prevents the recover action from immediately detonating the Goldburster ring
	player.rsrinfo.lastbuttons = $|BT_FIRENORMAL

	RSR.SetWeaponDelay(player, nil, nil, true)
	local missile = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_SCATTER_FLAKCANNON, player.mo.angle, player.cmd.aiming<<16)
	if Valid(missile) then
		missile.rsrOrigScale = missile.scale
		missile.scalespeed = missile.scale/4
		missile.destscale = 2 * missile.scale
		player.rsrinfo.scatterFlak = missile
	end
	RSR.TakeAmmoFromReadyWeapon(player, 1)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

--- Shifts the player's weapon psprite's y coordinate based on their weaponDelay, and lets the player detonate their last Mass Slug.
---@param player player_t
pspractions.A_ScatterRecover = function(player, args)
	if not RSR.IsPSpritesValid(player) then return end

	local psprite = PSprites.GetPSprite(player, PSprites.PSPR_WEAPON)
	if not psprite then return end

	local rsrinfo = player.rsrinfo

	if player.rsrinfo.weaponDelay <= 0 then
		player.rsrinfo.weaponDelay = 0
		player.rsrinfo.weaponDelayOrig = 0
		psprite.y = RSR.UPPER_OFFSET
		PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].states.ready)
		return
	end

	if rsrinfo.weaponDelayOrig == 1 then
		-- Hack to make sure the weapon visibly goes down while firing
		psprite.y = RSR.UPPER_OFFSET + 128 * ease.inquad(rsrinfo.weaponDelay*FRACUNIT/2)
	else
		psprite.y = RSR.UPPER_OFFSET + 128 * ease.inquad(rsrinfo.weaponDelay*FRACUNIT/rsrinfo.weaponDelayOrig)
	end
	player.rsrinfo.weaponDelay = $-1

	if Valid(rsrinfo.scatterFlak) and (rsrinfo.scatterFlak.flags & MF_MISSILE) and (player.cmd.buttons & BT_FIRENORMAL) and not (rsrinfo.lastbuttons & BT_FIRENORMAL) then
		P_ExplodeMissile(rsrinfo.scatterFlak)
	end
end

local psprstates = PSprites.STATES

-- Draw
psprstates["S_SCATTER_DRAW"] =	{"RSRSCTR",	"A",	1,	"A_RSRWeaponDraw",	{},	"S_SCATTER_DRAW"}
-- Holster
psprstates["S_SCATTER_HOLSTER"] =	{"RSRSCTR",	"A",	1,	"A_RSRWeaponHolster",	{},	"S_SCATTER_HOLSTER"}
-- Ready
psprstates["S_SCATTER_READY"] =	{"RSRSCTR",	"A",	1,	"A_ScatterReady",	{},	"S_SCATTER_READY"}
-- Attack
psprstates["S_SCATTER_ATTACK"] =	{"RSRSCTR",	"A",	0,	"A_ScatterAttack",	{},	"S_SCATTER_RECOVER"}
-- Attack Alt
psprstates["S_SCATTER_ATTACKALT"] =	{"RSRSCTR",	"A",	0,	"A_ScatterAttackAlt",	{},	"S_SCATTER_RECOVER"}
-- Recover
psprstates["S_SCATTER_RECOVER"] =	{"RSRSCTR",	"A",	1,	"A_ScatterRecover",	{},	"S_SCATTER_RECOVER"}
