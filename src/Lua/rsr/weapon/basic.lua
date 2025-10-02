---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Basic Weapon

RSR.AddAmmo("BASIC", {
	amount = 40,
	maxamount = 320,
	motype = MT_RSR_PICKUP_BASIC
})

RSR.AddWeapon("BASIC", {
	ammotype = RSR.AMMO_BASIC,
	ammoamount = 40,
	ammoalt = 1,
	canbepanel = false,
	class = 1,
	classpriority = 1,
	delay = 7,
	delayspeed = 4,
	delayalt = 20,
	delayaltspeed = 10,
	emerald = EMERALD1,
	icon = "RSRBASCI",
	name = "Red Ring",
	namealt = "Charged Shot",
	pickup = MT_RSR_PICKUP_BASIC,
	states = {
		draw = "S_BASIC_DRAW",
		ready = "S_BASIC_READY",
		holster = "S_BASIC_HOSLTER",
		attack = "S_BASIC_ATTACK",
		attackalt = "S_BASIC_ATTACKALT_CHOOSE"
	}
})

-- --------------------------------
-- PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_BASIC] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_BASIC,
	seesound = sfx_redfir,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	speed = 90*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 15,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

states[S_RSR_PROJECTILE_BASIC] =	{SPR_RSBR,	FF_ANIMATE|FF_FULLBRIGHT,	-1,	nil,	7,	1,	S_NULL}

addHook("MobjSpawn", RSR.ProjectileSpawn, MT_RSR_PROJECTILE_BASIC)
addHook("MobjThinker", RSR.ProjectileGhostTimer, MT_RSR_PROJECTILE_BASIC)
addHook("MobjMoveCollide", RSR.ProjectileMoveCollide, MT_RSR_PROJECTILE_BASIC)

-- --------------------------------
-- ALTFIRE PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_BASIC_CHARGED] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_BASIC,
	seesound = sfx_redal4,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	speed = 70*FRACUNIT,
	radius = 25*FRACUNIT,
	height = 25*FRACUNIT,
	damage = 20,
	activesound = sfx_rsrcmp,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

addHook("MobjSpawn", function(mo)
	if not Valid(mo) then return end

	RSR.ProjectileSpawn(mo)
	mo.rsrChargeHitList = {}
end, MT_RSR_PROJECTILE_BASIC_CHARGED)
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end

	RSR.ProjectileGhostTimer(mo)
	if (leveltime & 1) then
		mo.color = SKINCOLOR_SALMON
	else
		mo.color = SKINCOLOR_RED
	end
end, MT_RSR_PROJECTILE_BASIC_CHARGED)
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

	if not tmthing.rsrChargeHitList[thing] then
		S_StartSound(tmthing, tmthing.info.activesound) -- Play the charged ring hit sound to signify the charged ring actually hit something
		P_DamageMobj(thing, tmthing, tmthing.target, tmthing.rsrDamage or tmthing.info.damage)
		if not (Valid(tmthing) and Valid(thing)) then return false end
		tmthing.rsrChargeHitList[thing] = true
	end
	return false
end, MT_RSR_PROJECTILE_BASIC_CHARGED)

-- --------------------------------
-- PICKUP
-- --------------------------------

mobjinfo[MT_RSR_PICKUP_BASIC] = {
	--$Name Basic Pickup
	--$Sprite RSWRA0
	--$Category Ringslinger Revolution/Weapons
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	--$Arg1 "Don't despawn in co-op"
	--$Arg1Type 11
	--$Arg1Enum offon
	doomednum = 340,
	spawnstate = S_RSR_PICKUP_BASIC,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	radius = 16*FRACUNIT,
	height = 28*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_PICKUP_BASIC] =	{SPR_RSWR,	FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	7,	3,	S_NULL}

addHook("MobjSpawn", RSR.ItemMobjSpawn, MT_RSR_PICKUP_BASIC)
addHook("MapThingSpawn", RSR.WeaponMapThingSpawn, MT_RSR_PICKUP_BASIC)
addHook("TouchSpecial", function(special, toucher)
	return RSR.WeaponTouchSpecial(special, toucher, RSR.WEAPON_BASIC)
end, MT_RSR_PICKUP_BASIC)
addHook("MobjFuse", RSR.WeaponMobjFuse, MT_RSR_PICKUP_BASIC)
addHook("MobjThinker", RSR.WeaponPickupThinker, MT_RSR_PICKUP_BASIC)

-- --------------------------------
-- ACTIONS & STATES
-- --------------------------------

--- Fires a Charge Shot ring from the player.
---@param player player_t
---@param rsrinfo rsrinfo_t
---@param chargeSound integer
RSR.SpawnBasicAlt = function(player, rsrinfo, chargeSound)
	if not (Valid(player) and rsrinfo) then return end

	local addDamage = 60
	local addChargeSpeed = 20*FRACUNIT
	local addScale = 3*FRACUNIT/2
	if rsrinfo.basicCharge < 35 then
		local chargeScale = ease.outquad(FixedDiv(rsrinfo.basicCharge, 35))
		addDamage = FixedMul($, chargeScale)
		addChargeSpeed = FixedMul($, chargeScale)
		addScale = FixedMul($, chargeScale)
	else
		local chargeScale = FixedDiv(min(rsrinfo.basicCharge - 35, 29), 29)
		addDamage = $ + FixedMul(19, chargeScale)
		addChargeSpeed = $ + 10*chargeScale
		addScale = $ + FixedMul(FRACUNIT/2, chargeScale)
	end

	local altSound = sfx_redal1 + min(3, 2*addScale/FRACUNIT)
	local missile = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_BASIC_CHARGED, player.mo.angle, player.cmd.aiming<<16, nil, 90*FRACUNIT + addChargeSpeed, altSound)
	if Valid(missile) then
		missile.scale = FixedMul($, FRACUNIT/2 + addScale)
		missile.rsrDamage = 20 + addDamage
	end

	rsrinfo.basicCharge = 0
	rsrinfo.basicChargeSound = 0
	rsrinfo.basicChargeDontTakeAmmo = false
	if chargeSound then S_StopSoundByID(player.mo, chargeSound) end
end

local pspractions = PSprites.ACTIONS

--- Fires a Red ring from the player.
---@param player player_t
pspractions.A_BasicAttack = function(player, args)
	if not (Valid(player) and Valid(player.mo)) then return end

	RSR.SetWeaponDelay(player)

	local missile = RSR.SpawnPlayerMissile(player.mo, MT_RSR_PROJECTILE_BASIC, player.mo.angle, player.cmd.aiming<<16)
	if Valid(missile) and not (missile.color or missile.translation) then
		missile.color = SKINCOLOR_RED
	end
	RSR.TakeAmmoFromReadyWeapon(player, 1)

	if pspractions.A_RSRCheckAmmo(player, {}) then return end
end

pspractions.A_BasicAttackAltChoose = function(player, args)
	if not RSR.IsPSpritesValid(player) then return end

	-- Reset these variables just in case...
	player.rsrinfo.basicCharge = 0
	player.rsrinfo.basicChargeSound = 0
	player.rsrinfo.basicChareeDontTakeAmmo = false

	-- Use the "ATTACKALTSPEED" state if the player has speed shoes or is super.
	if player.powers[pw_sneakers] or player.powers[pw_super] then
		PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, "S_BASIC_ATTACKALTSPEED")
	-- Otherwise, use the "ATTACKALTATTRACT" state if the player has the Attraction Shield.
	elseif (player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT then
		PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, "S_BASIC_ATTACKALTATTRACT")
	end
end

--- Fires a Charge Shot ring from the player. Behavior heavily inspired by Snap the Sentinel's Static Charger.
---@param player player_t
pspractions.A_BasicAttackAlt = function(player, args)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end
	local rsrinfo = player.rsrinfo

	local chargeSound = sfx_thok -- This should NEVER play.
	local prevSound = nil
	local playSound = nil
	if rsrinfo.basicChargeSound >= 64 then -- Play the looped "holding charge" sound
		chargeSound = sfx_chloop
		prevSound = sfx_csftcp
		if rsrinfo.basicChargeSound == 64 then playSound = true end
	elseif rsrinfo.basicChargeSound >= 35 then -- Play the initial "holding charge" sound
		chargeSound = sfx_csftcp
		prevSound = sfx_rrchrg
		if rsrinfo.basicChargeSound == 35 then playSound = true end
	elseif rsrinfo.basicChargeSound >= 0 then -- Play the initial charge sound
		chargeSound = sfx_rrchrg
		if rsrinfo.basicChargeSound == 0 then playSound = true end
	end

	if playSound then
		if prevSound then S_StopSoundByID(player.mo, prevSound) end
		S_StartSound(player.mo, chargeSound)
	end

	if player.powers[pw_sneakers] or player.powers[pw_super] then -- Super sneakers and super makes charge rings charge faster
		rsrinfo.basicCharge = min($+2, 64)
		if rsrinfo.basicChargeSound < 34 then rsrinfo.basicChargeSound = $+1 end
	else
		if (rsrinfo.basicCharge % 4) == 0 and (player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT then
			rsrinfo.basicCharge = min($+2, 64)
			if rsrinfo.basicChargeSound < 34 then rsrinfo.basicChargeSound = $+1 end
		else
			rsrinfo.basicCharge = min($+1, 64)
		end
	end
	rsrinfo.basicChargeSound = $+1
	if rsrinfo.basicChargeSound > 92 then
		rsrinfo.basicChargeSound = $ - 29
	end

	local forceFire = false
	if not RSR.CanUseWeapons(player) or RSR.CheckPendingWeapon(player) then
		RSR.SpawnBasicAlt(player, rsrinfo, chargeSound)
		return
	end

	if args[1] then
		if rsrinfo.basicCharge > 35 then
			rsrinfo.basicChargeDontTakeAmmo = not $
		end

		if not rsrinfo.basicChargeDontTakeAmmo then
			if not RSR.CheckAmmo(player) then
				forceFire = true
			else
				RSR.TakeAmmoFromReadyWeapon(player, 1)
			end
		end
	end

	-- Force the player to fire a Charge Shot ring if they no longer have the super powerup or the green emerald.
	if not (RSR.PlayerHasEmerald(player, EMERALD1) or player.powers[pw_super]) then forceFire = true end

	if forceFire or not (player.cmd.buttons & BT_FIRENORMAL) then
		RSR.SetWeaponDelay(player, nil, nil, true)

		RSR.SpawnBasicAlt(player, rsrinfo, chargeSound)

		if pspractions.A_RSRCheckAmmo(player, {}) then return end
		PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, "S_BASIC_RECOVER")
	end
end

local psprstates = PSprites.STATES

-- Draw
psprstates["S_BASIC_DRAW"] =	{"RSRBASC",	"A",	1,	"A_RSRWeaponDraw",	{},	"S_BASIC_DRAW"}
-- Holster
psprstates["S_BASIC_HOLSTER"] =	{"RSRBASC",	"A",	1,	"A_RSRWeaponHolster",	{},	"S_BASIC_HOLSTER"}
-- Ready
psprstates["S_BASIC_READY"] =	{"RSRBASC",	"A",	1,	"A_RSRWeaponReady",	{},	"S_BASIC_READY"}
-- Attack
psprstates["S_BASIC_ATTACK"] =		{"RSRBASC",	"A",	0,	"A_BasicAttack",	{},	"S_BASIC_RECOVER"}
-- Attack Alt
psprstates["S_BASIC_ATTACKALT_CHOOSE"] =	{"RSRBASC",	"B",	0,	"A_BasicAttackAltChoose",	{},		"S_BASIC_ATTACKALT"}
psprstates["S_BASIC_ATTACKALT"]  =			{"RSRBASC",	"B",	1,	"A_BasicAttackAlt",			{true},	"S_BASIC_ATTACKALT2"}
psprstates["S_BASIC_ATTACKALT2"] =			{"RSRBASC",	"BAA",	1,	"A_BasicAttackAlt",			{},		"S_BASIC_ATTACKALT"}
psprstates["S_BASIC_ATTACKALTATTRACT"]  =	{"RSRBASC",	"B",	1,	"A_BasicAttackAlt",			{true},	"S_BASIC_ATTACKALTATTRACT2"}
psprstates["S_BASIC_ATTACKALTATTRACT2"] =	{"RSRBASC",	"BA",	1,	"A_BasicAttackAlt",			{},		"S_BASIC_ATTACKALTATTRACT3"}
psprstates["S_BASIC_ATTACKALTATTRACT3"]  =	{"RSRBASC",	"A",	1,	"A_BasicAttackAlt",			{true},	"S_BASIC_ATTACKALTATTRACT4"}
psprstates["S_BASIC_ATTACKALTATTRACT4"] =	{"RSRBASC",	"BB",	1,	"A_BasicAttackAlt",			{},		"S_BASIC_ATTACKALTATTRACT5"}
psprstates["S_BASIC_ATTACKALTATTRACT5"]  =	{"RSRBASC",	"A",	1,	"A_BasicAttackAlt",			{true},	"S_BASIC_ATTACKALTATTRACT6"}
psprstates["S_BASIC_ATTACKALTATTRACT6"] =	{"RSRBASC",	"AB",	1,	"A_BasicAttackAlt",			{},		"S_BASIC_ATTACKALTATTRACT7"}
psprstates["S_BASIC_ATTACKALTATTRACT7"]  =	{"RSRBASC",	"B",	1,	"A_BasicAttackAlt",			{true},	"S_BASIC_ATTACKALTATTRACT8"}
psprstates["S_BASIC_ATTACKALTATTRACT8"] =	{"RSRBASC",	"AA",	1,	"A_BasicAttackAlt",			{},		"S_BASIC_ATTACKALTATTRACT"}
psprstates["S_BASIC_ATTACKALTSPEED"]  =		{"RSRBASC",	"B",	1,	"A_BasicAttackAlt",			{true},	"S_BASIC_ATTACKALTSPEED2"}
psprstates["S_BASIC_ATTACKALTSPEED2"] =		{"RSRBASC",	"A",	1,	"A_BasicAttackAlt",			{},		"S_BASIC_ATTACKALTSPEED"}
-- Recover
psprstates["S_BASIC_RECOVER"] =	{"RSRBASC",	"A",	1,	"A_RSRWeaponRecover",	{},	"S_BASIC_RECOVER"}
