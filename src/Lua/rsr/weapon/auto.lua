---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Automatic Weapon

RSR.AddAmmo("AUTO", {
	amount = 80,
	maxamount = 800,
	motype = MT_RSR_PICKUP_AUTO
})

RSR.AddWeapon("AUTO", {
	ammotype = RSR.AMMO_AUTO,
	ammoamount = 80,
	ammoalt = 3,
	class = 3,
	delay = 2,
	delayspeed = 1,
	delayalt = 4,
	delayaltspeed = 2,
	emerald  = EMERALD3,
	icon = "RSRAUTOI",
	name = "Automatic Ring",
	namealt = "Spray&Pray",
	pickup = MT_RSR_PICKUP_AUTO,
	states = {
		draw = "S_AUTO_DRAW",
		ready = "S_AUTO_READY",
		holster = "S_AUTO_HOSLTER",
		attack = "S_AUTO_ATTACK",
		attackalt = "S_AUTO_ATTACKALT"
	}
})

-- --------------------------------
-- PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_AUTO] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_AUTO,
	seesound = sfx_autofr,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	speed = 90*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 14,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_AUTO)
addHook("MobjThinker", RSR.ProjectileGhostTimer, MT_RSR_PROJECTILE_AUTO)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_AUTO)

-- --------------------------------
-- ALTFIRE PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_AUTO_SNP] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_AUTO,
	seesound = sfx_atatfr,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	speed = 80*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 10,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

states[S_RSR_PROJECTILE_AUTO] =	{SPR_RSBA,	FF_ANIMATE|FF_FULLBRIGHT,	-1,	nil,	6,	1,	S_NULL}

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_AUTO_SNP)
addHook("MobjThinker", RSR.ProjectileGhostTimer, MT_RSR_PROJECTILE_AUTO_SNP)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_AUTO_SNP)

-- --------------------------------
-- PICKUP
-- --------------------------------

mobjinfo[MT_RSR_PICKUP_AUTO] = {
	--$Name Automatic Pickup
	--$Sprite RSWAA0
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
	doomednum = 342,
	spawnstate = S_RSR_PICKUP_AUTO,
	seestate = S_RSR_PICKUP_AUTO_PANEL,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	radius = 16*FRACUNIT,
	height = 28*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_PICKUP_AUTO] =			{SPR_RSWA,	FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}
states[S_RSR_PICKUP_AUTO_PANEL] =	{SPR_RSWA,	I|FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}

addHook("MobjSpawn", RSR.ItemMobjSpawn, MT_RSR_PICKUP_AUTO)
addHook("MapThingSpawn", RSR.WeaponMapThingSpawn, MT_RSR_PICKUP_AUTO)
addHook("TouchSpecial", function(special, toucher)
	return RSR.WeaponTouchSpecial(special, toucher, RSR.WEAPON_AUTO)
end, MT_RSR_PICKUP_AUTO)
addHook("MobjFuse", RSR.WeaponMobjFuse, MT_RSR_PICKUP_AUTO)
addHook("MobjThinker", RSR.WeaponPickupThinker, MT_RSR_PICKUP_AUTO)

-- --------------------------------
-- ACTIONS & STATES
-- --------------------------------

local pspractions = PSprites.ACTIONS

--- Fires an Automatic ring from the player.
---@param player player_t
pspractions.A_AutoAttack = function(player, args)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	RSR.SetWeaponDelay(player)
	RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_AUTO, player.mo.angle, player.cmd.aiming<<16)
	RSR.TakeAmmoFromReadyWeapon(player, 1)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

--- Fires three "super" Automatic rings from the player.
---@param player player_t
pspractions.A_AutoAttackAlt = function(player, args)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	RSR.SetWeaponDelay(player, nil, nil, true)

	local angle = player.mo.angle
	local pitch = player.cmd.aiming<<16

	for i = 0, 2 do
		local angleOffset = FixedAngle(P_RandomRange(5,-5)*FRACUNIT/2) -- Random horizontal spread between 2.5 and -2.5 degrees
		local pitchOffset = FixedAngle(P_RandomRange(4,-4)*FRACUNIT/2) -- Random vertical spread between 2 and -2 degrees
		local leadSplit = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_AUTO_SNP, angle + angleOffset, pitch + pitchOffset)
		if Valid(leadSplit) then
			-- Make it smaller
			leadSplit.rsrOrigScale = leadSplit.scale
			leadSplit.scalespeed = leadSplit.scale/3
			leadSplit.destscale = 9*leadSplit.scale/10
		end
	end
	RSR.TakeAmmoFromReadyWeapon(player, 3)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

local psprstates = PSprites.STATES

-- Draw
psprstates["S_AUTO_DRAW"] =	{"RSRAUTO",	"A",	1,	"A_RSRWeaponDraw",		{},	"S_AUTO_DRAW"}
-- Holster
psprstates["S_AUTO_HOLSTER"] =	{"RSRAUTO",	"A",	1,	"A_RSRWeaponHolster",	{},	"S_AUTO_HOLSTER"}
-- Ready
psprstates["S_AUTO_READY"] =	{"RSRAUTO",	"A",	1,	"A_RSRWeaponReady",	{},	"S_AUTO_READY"}
-- Attack
psprstates["S_AUTO_ATTACK"] =	{"RSRAUTO",	"A",	0,	"A_AutoAttack",		{},	"S_AUTO_RECOVER"}
-- Attack Super
psprstates["S_AUTO_ATTACKALT"] =	{"RSRAUTO",	"A",	0,	"A_AutoAttackAlt",		{},	"S_AUTO_RECOVER"}
-- Recover
psprstates["S_AUTO_RECOVER"] =	{"RSRAUTO",	"A",	1,	"A_RSRWeaponRecover",	{},	"S_AUTO_RECOVER"}
