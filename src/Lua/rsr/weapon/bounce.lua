---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Bounce Weapon

RSR.AddAmmo("BOUNCE", {
	amount = 16,
	maxamount = 160,
	motype = MT_RSR_PICKUP_BOUNCE
})

RSR.AddWeapon("BOUNCE", {
	ammotype = RSR.AMMO_BOUNCE,
	ammoamount = 16,
	ammoalt = 3,
	class = 4,
	delay = 7,
	delayspeed = 4,
	delayalt = 35,
	delayaltspeed = 17,
	emerald = EMERALD4,
	icon = "RSRBNCEI",
	name = "Bounce Ring",
	namealt = "Goldburster",
	pickup = MT_RSR_PICKUP_BOUNCE,
	states = {
		draw = "S_BOUNCE_DRAW",
		ready = "S_BOUNCE_READY",
		holster = "S_BOUNCE_HOSLTER",
		attack = "S_BOUNCE_ATTACK",
		attackalt = "S_BOUNCE_ATTACKALT"
	}
})

-- --------------------------------
-- PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_BOUNCE] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_BOUNCE,
	seesound = sfx_boncfr,
-- 	reactiontime = 2*TICRATE,
	painchance = 9,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	speed = 90*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 17,
	activesound = sfx_bnce1,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY|MF_BOUNCE|MF_GRENADEBOUNCE
}

mobjinfo[MT_RSR_PROJECTILE_BOUNCE_MEGABOMB_SUBMUNITION] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_BOUNCE,
	seesound = sfx_boncfr,
-- 	reactiontime = 2*TICRATE,
	painchance = 9,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	speed = 60*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 17,
	activesound = sfx_bnce1,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY|MF_BOUNCE|MF_GRENADEBOUNCE
}

states[S_RSR_PROJECTILE_BOUNCE] =	{SPR_RSWB,	FF_ANIMATE|FF_FULLBRIGHT,	-1,	nil,	15,	1,	S_NULL}

--- Shoots a bunch of Bounce rings in a rough sphere shape.
---@param actor mobj_t
RSR.A_BounceMegaBomb = function(actor, var1, var2)
	if not Valid(actor) then return end

	P_StartQuake(96*FRACUNIT, 12, {x = actor.x, y = actor.y, z = actor.z + actor.height/2}, 192*actor.scale)
	for i = -2, 2 do
		for j = 0, 3 do
			local bounceAngle = actor.angle + (j * ANGLE_90)
			if i == 0 then bounceAngle = $ + ANGLE_45 end
			local bouncePitch = i * ANGLE_45

			local bounceRing = P_SpawnMobjFromMobj(actor, 0, 0, actor.info.height/2, MT_RSR_PROJECTILE_BOUNCE_MEGABOMB_SUBMUNITION)
			if Valid(bounceRing) then
				if actor.rsrOrigScale then bounceRing.scale = actor.rsrOrigScale end
				bounceRing.angle = bounceAngle
				bounceRing.pitch = bouncePitch
				bounceRing.target = actor.target -- Don't let players hurt themselves with a bounce mega bomb
				bounceRing.rsrProjectile = true
				if Valid(bounceRing.target) then RSR.ColorTeamMissile(bounceRing, bounceRing.target.player) end

				RSR.MoveMissile(bounceRing, bounceRing.angle, bounceRing.pitch)
			end

			if i == -2 or i == 2 then break end -- Only spawn one
		end
	end
end

--- Increments the Bounce ring's bounce count (threshold).
---@param mo mobj_t
RSR.BounceIncrementCount = function(mo)
	if not Valid(mo) then return end

	-- Use threshold as a "bounce count" of sorts
	mo.threshold = $+1
	mo.rsrDamage = max(1, $-2) -- Don't let the damage value go lower than 1
	if mo.threshold > mo.info.painchance then
		P_ExplodeMissile(mo)
		return
	end

	S_StartSound(mo, mo.info.activesound)
end

--- MobjSpawn hook code for the Bounce Ring.
---@param mo mobj_t
RSR.BounceSpawn = function(mo)
	if not Valid(mo) then return end
	RSR.ProjectileSpawn(mo)
	mo.rsrDamage = mo.info.damage
end

--- MobjThinker hook code for the Bounce Ring.
---@param mo mobj_t
RSR.BounceThinker = function(mo)
	if not Valid(mo) then return end
	if not (mo.flags & MF_MISSILE) then return end

	RSR.ProjectileGhostTimer(mo)

	if mo.rsrBounced then
		mo.rsrBounced = $-1
	end

	-- SRB2 has a hardcoded hack specifically for grenade rings (and Brak's napalm bombs)
	-- to make them stop when they hit the ground while their vertical momentum is less than their scale.
	-- This code attempts to prevent that from happening by setting the bounce ring's momentum to its previous momentum.
	-- A hack to prevent another hack. How interesting...
	if not (mo.momx or mo.momy or mo.momz) then
		mo.momx = mo.rsrPrevMomX
		mo.momy = mo.rsrPrevMomY
		mo.momz = mo.rsrPrevMomZ
	end

	local hitFloor = mo.z + mo.momz <= mo.floorz
	local hitCeiling = mo.z + mo.height + mo.momz >= mo.ceilingz
	if hitFloor or hitCeiling then
		RSR.BounceIncrementCount(mo)

		if P_MobjFlip(mo)*mo.momz < 0 then
			mo.momz = $*2 -- Try to cancel out the division by 2 done on MF_GRENADEBOUNCE objects
		end

		if Valid(mo.subsector) and Valid(mo.subsector.sector) then
			local curSector = mo.subsector.sector
			if (hitFloor and curSector.floorpic == "F_SKY1" and curSector.floorheight == mo.floorz)
			or (hitCeiling and curSector.ceilingpic == "F_SKY1" and curSector.ceilingheight == mo.ceilingz) then
				P_RemoveMobj(mo)
				return
			end
		end
	end

	mo.rsrPrevMomX = mo.momx
	mo.rsrPrevMomY = mo.momy
	mo.rsrPrevMomZ = mo.momz
end

--- MobjMoveCollide hook code for the Bounce Ring.
---@param tmthing mobj_t
---@param thing mobj_t
RSR.BounceMoveCollide = function(tmthing, thing)
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

	P_DamageMobj(thing, tmthing, tmthing.target, tmthing.rsrDamage)
	tmthing.momx = -$
	tmthing.momy = -$
	tmthing.rsrBounced = 4 -- Add a timer so the bounce ring doesn't get stuck on an object

	RSR.BounceIncrementCount(tmthing)
	return false
end

--- MobjMoveBlocked hook code for the Bounce Ring.
---@param mo mobj_t
---@param line line_t
RSR.BounceMoveBlocked = function(mo, _, line)
	if not Valid(mo) then return end

	-- Don't bounce against the sky
	if Valid(line) and P_CheckSkyHit(mo, line) then
		P_RemoveMobj(mo)
		return true
	end

	-- Make sure the bounce ring maintains the same speed it had before it bounced off the wall
	local oldSpeed = FixedHypot(FixedHypot(mo.momx, mo.momy), mo.momz)
	P_BounceMove(mo)
	local newSpeed = FixedHypot(FixedHypot(mo.momx, mo.momy), mo.momz)

	if oldSpeed and newSpeed then
		local scale = FixedDiv(oldSpeed, newSpeed)

		mo.momx = FixedMul($, scale)
		mo.momy = FixedMul($, scale)
		mo.momz = FixedMul($, scale)
	end

	RSR.BounceIncrementCount(mo)
	return true
end

addHook("MobjSpawn", RSR.BounceSpawn, MT_RSR_PROJECTILE_BOUNCE)
addHook("MobjThinker", RSR.BounceThinker, MT_RSR_PROJECTILE_BOUNCE)
addHook("MobjMoveCollide", RSR.BounceMoveCollide, MT_RSR_PROJECTILE_BOUNCE)
addHook("MobjMoveBlocked", RSR.BounceMoveBlocked, MT_RSR_PROJECTILE_BOUNCE)
addHook("MobjSpawn", RSR.BounceSpawn, MT_RSR_PROJECTILE_BOUNCE_MEGABOMB_SUBMUNITION)
addHook("MobjThinker", RSR.BounceThinker, MT_RSR_PROJECTILE_BOUNCE_MEGABOMB_SUBMUNITION)
addHook("MobjMoveCollide", RSR.BounceMoveCollide, MT_RSR_PROJECTILE_BOUNCE_MEGABOMB_SUBMUNITION)
addHook("MobjMoveBlocked", RSR.BounceMoveBlocked, MT_RSR_PROJECTILE_BOUNCE_MEGABOMB_SUBMUNITION)

-- --------------------------------
-- ALTFIRE PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_BOUNCE_MEGABOMB] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_BOUNCE,
	seesound = sfx_bcatfr,
	deathstate = S_RSR_PROJECTILE_BOUNCE_MEGABOMB,
	deathsound = sfx_bcmega,
	speed = 60*FRACUNIT,
	radius = 22*FRACUNIT,
	height = 22*FRACUNIT,
	damage = 35,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

states[S_RSR_PROJECTILE_BOUNCE_MEGABOMB] =	{SPR_RSWB,	FF_FULLBRIGHT,	0,	RSR.A_BounceMegaBomb,	0,	0,	S_WPLD1}

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_BOUNCE_MEGABOMB)
addHook("MobjThinker", RSR.ProjectileGhostTimer, MT_RSR_PROJECTILE_BOUNCE_MEGABOMB)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_BOUNCE_MEGABOMB)

-- --------------------------------
-- PICKUP
-- --------------------------------

mobjinfo[MT_RSR_PICKUP_BOUNCE] = {
	--$Name Bounce Pickup
	--$Sprite RSWBA0
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
	doomednum = 343,
	spawnstate = S_RSR_PICKUP_BOUNCE,
	seestate = S_RSR_PICKUP_BOUNCE_PANEL,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	radius = 16*FRACUNIT,
	height = 28*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_PICKUP_BOUNCE] =		{SPR_RSWB,	FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	15,	3,	S_NULL}
states[S_RSR_PICKUP_BOUNCE_PANEL] =	{SPR_RSWB,	Q|FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}

addHook("MobjSpawn", RSR.ItemMobjSpawn, MT_RSR_PICKUP_BOUNCE)
addHook("MapThingSpawn", RSR.WeaponMapThingSpawn, MT_RSR_PICKUP_BOUNCE)
addHook("TouchSpecial", function(special, toucher)
	return RSR.WeaponTouchSpecial(special, toucher, RSR.WEAPON_BOUNCE)
end, MT_RSR_PICKUP_BOUNCE)
addHook("MobjFuse", RSR.WeaponMobjFuse, MT_RSR_PICKUP_BOUNCE)
addHook("MobjThinker", RSR.WeaponPickupThinker, MT_RSR_PICKUP_BOUNCE)

-- --------------------------------
-- ACTIONS & STATES
-- --------------------------------

local pspractions = PSprites.ACTIONS

--- Constantly checks if the player is holding the fire or altfire button, then fires the Bounce ring.
---@param player player_t
pspractions.A_BounceReady = function(player, args)
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
		if Valid(rsrinfo.bounceMega) and (rsrinfo.bounceMega.flags & MF_MISSILE) then
			P_ExplodeMissile(rsrinfo.bounceMega)
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

--- Fires a Bounce ring from the player.
---@param player player_t
pspractions.A_BounceAttack = function(player, args)
	if not (Valid(player) and Valid(player.mo)) then return end

	RSR.SetWeaponDelay(player)
	RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_BOUNCE, player.mo.angle, player.cmd.aiming<<16)
	RSR.TakeAmmoFromReadyWeapon(player, 1)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

--- Fires a Goldburster ring from the player.
---@param player player_t
pspractions.A_BounceAttackAlt = function(player, args)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	-- Hack to prevents the recover action from immediately detonating the Goldburster ring
	player.rsrinfo.lastbuttons = $|BT_FIRENORMAL

	RSR.SetWeaponDelay(player, nil, nil, true)
	local missile = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_BOUNCE_MEGABOMB, player.mo.angle, player.cmd.aiming<<16)
	if Valid(missile) then
		missile.rsrOrigScale = missile.scale
		missile.scalespeed = missile.scale/4
		missile.destscale = 2 * missile.scale
		player.rsrinfo.bounceMega = missile
	end
	RSR.TakeAmmoFromReadyWeapon(player, 3)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

--- Shifts the player's weapon psprite's y coordinate based on their weaponDelay, and lets the player detonate their last Goldburster.
---@param player player_t
pspractions.A_BounceRecover = function(player, args)
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

	if Valid(rsrinfo.bounceMega) and (rsrinfo.bounceMega.flags & MF_MISSILE) and (player.cmd.buttons & BT_FIRENORMAL) and not (rsrinfo.lastbuttons & BT_FIRENORMAL)then
		P_ExplodeMissile(rsrinfo.bounceMega)
	end
end

local psprstates = PSprites.STATES

-- Draw
psprstates["S_BOUNCE_DRAW"] =	{"RSRBNCE",	"A",	1,	"A_RSRWeaponDraw",		{},	"S_BOUNCE_DRAW"}
-- Holster
psprstates["S_BOUNCE_HOLSTER"] =	{"RSRBNCE",	"A",	1,	"A_RSRWeaponHolster",	{},	"S_BOUNCE_HOLSTER"}
-- Ready
psprstates["S_BOUNCE_READY"] =	{"RSRBNCE",	"A",	1,	"A_BounceReady",	{},	"S_BOUNCE_READY"}
-- Attack
psprstates["S_BOUNCE_ATTACK"] =	{"RSRBNCE",	"A",	0,	"A_BounceAttack",	{},	"S_BOUNCE_RECOVER"}
-- Attack Alt
psprstates["S_BOUNCE_ATTACKALT"] =	{"RSRBNCE",	"A",	0,	"A_BounceAttackAlt",	{},	"S_BOUNCE_RECOVER"}
-- Recover
psprstates["S_BOUNCE_RECOVER"] =	{"RSRBNCE",	"A",	1,	"A_BounceRecover",	{},	"S_BOUNCE_RECOVER"}
