---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Explosion Weapon

RSR.AddAmmo("BOMB", {
	amount = 10,
	maxamount = 100,
	motype = MT_RSR_PICKUP_BOMB
})

RSR.AddWeapon("BOMB", {
	ammotype = RSR.AMMO_BOMB,
	ammoamount = 10,
	ammoalt = 3,
	lowammo = 4,
	lowammoalt = 7,
	lowammosound = sfx_bombla,
	lowammosoundalt = sfx_boatla,
	class = 4,
	delay = 36,
	delayspeed = 18,
	delayalt = 70,
	delayaltspeed = 35,
	emerald = EMERALD4,
	icon = "RSRBOMBI",
	name = "Explosion Ring",
	namealt = "Self-Propel",
	pickup = MT_RSR_PICKUP_BOMB,
	states = {
		draw = "S_BOMB_DRAW",
		ready = "S_BOMB_READY",
		holster = "S_BOMB_HOLSTER",
		attack = "S_BOMB_ATTACK",
		attackalt = "S_BOMB_ATTACKALT"
	}
})

-- --------------------------------
-- PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_BOMB] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_BOMB,
	seesound = sfx_bombfr,
	reactiontime = 62,
	painchance = 224*FRACUNIT,
	deathstate = S_RSR_RINGEXPLODE,
	deathsound = sfx_pop,
	speed = 60*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 4,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

mobjinfo[MT_RSR_PROJECTILE_BOMB_MISSILEFORM] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_BOMB,
	seesound = sfx_boatfr,
	reactiontime = 37,
	painchance = 256*FRACUNIT,
	deathstate = S_RSR_RINGEXPLODE,
	deathsound = sfx_pop,
	speed = 60*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 1,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

states[S_RSR_PROJECTILE_BOMB] =	{SPR_RSWE,	FF_ANIMATE|FF_FULLBRIGHT,	-1,	nil,	15,	1,	S_NULL}

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_BOMB)
-- Explosion Ring thinker code
---@param mo mobj_t
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end
	if mo.health <= 0 then return end
	if not (mo.flags & MF_MISSILE) then return end

	RSR.ProjectileTravelSound(mo) -- Travelling sound
	RSR.ProjectileGhostTimer(mo, MT_SMOKE) -- Smoke particles
end, MT_RSR_PROJECTILE_BOMB)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_BOMB)

-- --------------------------------
-- ALTFIRE PROJECTILE
-- --------------------------------

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_BOMB_MISSILEFORM)
-- Self-Propel thinker code
---@param mo mobj_t
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end
	if mo.health <= 0 then return end
	if not (mo.flags & MF_MISSILE) then return end

	RSR.ProjectileGhostTimer(mo, MT_SMOKE) -- Smoke particles
end, MT_RSR_PROJECTILE_BOMB_MISSILEFORM)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_BOMB_MISSILEFORM)

-- --------------------------------
-- PICKUP
-- --------------------------------

mobjinfo[MT_RSR_PICKUP_BOMB] = {
	--$Name Explosion Pickup
	--$Sprite RSWEA0
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
	doomednum = 345,
	spawnstate = S_RSR_PICKUP_BOMB,
	seestate = S_RSR_PICKUP_BOMB_PANEL,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	radius = 24*FRACUNIT,
	height = 28*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_PICKUP_BOMB] =			{SPR_RSWE,	FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	15,	3,	S_NULL}
states[S_RSR_PICKUP_BOMB_PANEL] =	{SPR_RSWE,	Q|FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}

addHook("MobjSpawn", RSR.ItemMobjSpawn, MT_RSR_PICKUP_BOMB)
addHook("MapThingSpawn", RSR.WeaponMapThingSpawn, MT_RSR_PICKUP_BOMB)
addHook("TouchSpecial", function(special, toucher)
	return RSR.WeaponTouchSpecial(special, toucher, RSR.WEAPON_BOMB)
end, MT_RSR_PICKUP_BOMB)
addHook("MobjFuse", RSR.WeaponMobjFuse, MT_RSR_PICKUP_BOMB)
addHook("MobjThinker", RSR.WeaponPickupThinker, MT_RSR_PICKUP_BOMB)

-- --------------------------------
-- ACTIONS & STATES
-- --------------------------------

-- Explosion Ring WeaponReady code
---@param player player_t
---@param weaponInfo rsrweaponinfo_t
RSR.addHook("WeaponReady", function(player, weaponInfo, args)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	local rsrinfo = player.rsrinfo

	if (player.cmd.buttons & BT_FIRENORMAL) and (player.powers[pw_super] or RSR.PlayerHasEmerald(player, weaponInfo.emerald)) then
		if RSR.FireWeaponAlt(player) then return true end
		-- Make sure the player has an a altfire attack state and ammo at all before making the sound
		if not (rsrinfo.lastbuttons & BT_FIRENORMAL) and RSR.CheckAmmo(player) and weaponInfo.states.attackalt then
			S_StartSound(nil, sfx_noammo, player)
		end
	end

	if (player.cmd.buttons & BT_ATTACK) and (not (rsrinfo.lastbuttons & BT_ATTACK) or rsrinfo.canHoldFire) then
		RSR.FireWeapon(player)
		return true
	end

	return true
end, RSR.WEAPON_BOMB)

local pspractions = PSprites.ACTIONS

--- Fires an Explosion ring from the player.
---@param player player_t
pspractions.A_BombAttack = function(player, args)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	RSR.SetWeaponDelay(player)
	RSR.TakeAmmoFromReadyWeapon(player, 1)
	RSR.PlayLowAmmoSound(player, nil, nil)
	RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_BOMB, player.mo.angle, player.cmd.aiming<<16)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

--- Fires a Self-Propel Explosion ring from the player.
---@param player player_t
pspractions.A_BombAttackAlt = function(player, args)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	RSR.SetWeaponDelay(player, nil, nil, true)
	RSR.TakeAmmoFromReadyWeapon(player, RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].ammoalt)
	RSR.PlayLowAmmoSound(player, nil, true)

	local bomb = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_BOMB_MISSILEFORM, player.mo.angle, player.cmd.aiming<<16)
	if Valid(bomb) then P_ExplodeMissile(bomb) end

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

local psprstates = PSprites.STATES

-- Draw
psprstates["S_BOMB_DRAW"] =	{"RSRBOMB",	"A",	1,	"A_RSRWeaponDraw",		{},	"S_BOMB_DRAW"}
-- Holster
psprstates["S_BOMB_HOLSTER"] =	{"RSRBOMB",	"A",	1,	"A_RSRWeaponHolster",	{},	"S_BOMB_HOLSTER"}
-- Ready
psprstates["S_BOMB_READY"] =	{"RSRBOMB",	"A",	1,	"A_RSRWeaponReady",	{},	"S_BOMB_READY"}
-- Attack
psprstates["S_BOMB_ATTACK"] =	{"RSRBOMB",	"A",	0,	"A_BombAttack",	{},		"S_BOMB_RECOVER"}
-- Attack Alt
psprstates["S_BOMB_ATTACKALT"] =	{"RSRBOMB",	"A",	0,	"A_BombAttackAlt",	{},	"S_BOMB_RECOVER"}
-- Recover
psprstates["S_BOMB_RECOVER"] =	{"RSRBOMB",	"A",	1,	"A_RSRWeaponRecover",	{},	"S_BOMB_RECOVER"}
