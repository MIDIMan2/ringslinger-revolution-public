---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Bright Fluorescent Weapon
-- TODO: double-line-of-sight check explosion, tendrils to nearby targets. For reference: Quake2 BFG-10000

RSR.AddAmmo("BFR", {
	amount = 1,
	maxamount = 10,
	motype = MT_RSR_PICKUP_BFR
})

RSR.AddWeapon("BFR", {
	ammotype = RSR.AMMO_BFR,
	ammoamount = 1,
	canbepanel = false,
	class = 1,
	classpriority = 3,
	delay = 87,
	delayspeed = 60,
	emerald = EMERALD1,
	icon = "RSRRAILI",
	name = "Bright Fluorescent Ring",
	pickup = MT_RSR_PICKUP_RAIL,
	powerweapon = true,
	altzoom = true,
	states = {
		draw = "S_BFR_DRAW",
		ready = "S_BFR_READY",
		holster = "S_BFR_HOSLTER",
		attack = "S_BFR_ATTACK"
	}
})

-- --------------------------------
-- PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_BFR] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_BFR,
	seesound = sfx_bombfr,
	reactiontime = 200,
	painchance = 2048*FRACUNIT,
	deathstate = S_RSR_RINGEXPLODE,
	deathsound = sfx_pop,
	speed = 12*FRACUNIT,
	radius = 1*FRACUNIT,
	height = 1*FRACUNIT,
	damage = 200,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

states[S_RSR_PROJECTILE_BFR] =	{SPR_RSWS,	FF_FULLBRIGHT,	-1,	nil,	0,	0,	S_NULL}

---@param mo mobj_t
addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_BFR)
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end
	if mo.health <= 0 then return end
	if not (mo.flags & MF_MISSILE) then return end

	-- Smoke particles
	RSR.ProjectileGhostTimer(mo, true)
end, MT_RSR_PROJECTILE_BFR)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_BFR)

-- --------------------------------
-- PICKUP
-- --------------------------------

mobjinfo[MT_RSR_PICKUP_BFR] = {
	--$Name Bright Fluorescent Pickup
	--$Sprite RSWIA0
	--$Category Ringslinger Revolution/Weapons
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	--$Arg1 "Don't despawn in co-op"
	--$Arg1Type 11
	--$Arg1Enum offon
	doomednum = 348,
	spawnstate = S_RSR_PICKUP_BFR,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	radius = 16*FRACUNIT,
	height = 28*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_PICKUP_BFR] =	{SPR_RSWI,	FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	15,	3,	S_NULL}

addHook("MobjSpawn", RSR.ItemMobjSpawn, MT_RSR_PICKUP_BFR)
addHook("MapThingSpawn", RSR.WeaponMapThingSpawn, MT_RSR_PICKUP_BFR)
addHook("TouchSpecial", function(special, toucher)
	return RSR.WeaponTouchSpecial(special, toucher, RSR.WEAPON_BFR)
end, MT_RSR_PICKUP_BFR)
addHook("MobjFuse", RSR.WeaponMobjFuse, MT_RSR_PICKUP_BFR)
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end
	RSR.ItemFlingSpark(mo, mo.info.height/3, FRACUNIT/2, 25) -- Smaller sparks! :o
	RSR.WeaponPickupThinker(mo)
end, MT_RSR_PICKUP_BFR)

-- --------------------------------
-- ACTIONS & STATES
-- --------------------------------

local pspractions = PSprites.ACTIONS

--- Fires a Bright Fluorescent ring from the player after a 0.9 second charge-up.
---@param player player_t
pspractions.A_BFRAttack = function(player, args)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	if RSR.CheckPendingWeapon(player) then
		local bfrTime = 31
		return
	end

	if bfrTime > 0 then
		bfrTime = $ - 1
	else
		RSR.SetWeaponDelay(player)

		local bfr = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_BFR, player.mo.angle, player.cmd.aiming<<16)
		RSR.TakeAmmoFromReadyWeapon(player, 1)

		if pspractions.A_RSRCheckAmmo(player, {}) then return end
	end
end

local pspractions = PSprites.ACTIONS

-- Draw
psprstates["S_BFR_DRAW"] =	{"RSRRAIL",	"A",	1,	"A_RSRWeaponDraw",		{},	"S_BFR_DRAW"}
-- Holster
psprstates["S_BFR_HOLSTER"] =	{"RSRRAIL",	"A",	1,	"A_RSRWeaponHolster",	{},	"S_BFR_HOLSTER"}
-- Ready
psprstates["S_BFR_READY"] =	{"RSRRAIL",	"A",	1,	"A_RSRWeaponReady",	{},	"S_BFR_READY"} -- TODO: Check lastbuttons so the player doesn't accidently fire a BFR when switching weapons
-- Attack
psprstates["S_BFR_ATTACK"] =	{"RSRRAIL",	"A",	0,	"A_BFRAttack",		{},	"S_BFR_RECOVER"}
-- Recover
psprstates["S_BFR_RECOVER"] =	{"RSRRAIL",	"A",	1,	"A_RSRWeaponRecover",	{},	"S_BFR_RECOVER"}
