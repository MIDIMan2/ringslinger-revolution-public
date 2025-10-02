---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Rail Weapon

RSR.AddAmmo("RAIL", {
	amount = 1,
	maxamount = 10,
	motype = MT_RSR_PICKUP_RAIL
})

RSR.AddWeapon("RAIL", {
	ammotype = RSR.AMMO_RAIL,
	ammoamount = 1,
	canbepanel = false,
	class = 1,
	classpriority = 2,
	delay = 60,
	delayspeed = 30,
	emerald = EMERALD1,
	icon = "RSRRAILI",
	name = "Rail Ring",
	pickup = MT_RSR_PICKUP_RAIL,
	powerweapon = true,
	altzoom = true,
	states = {
		draw = "S_RAIL_DRAW",
		ready = "S_RAIL_READY",
		holster = "S_RAIL_HOSLTER",
		attack = "S_RAIL_ATTACK"
	}
})

-- --------------------------------
-- PROJECTILE
-- --------------------------------

mobjinfo[MT_RSR_PROJECTILE_RAIL] = {
	doomednum = -1,
	spawnstate = S_RSR_PROJECTILE_RAIL,
	seesound = sfx_railgn,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	speed = 60*FRACUNIT,
	radius = 16*FRACUNIT,
	height = 16*FRACUNIT,
	damage = 250, -- Might be too OP in deathmatch... (It wasn't. It's PEAK comedy. -orbitalviolet)
	activesound = sfx_railht,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}

states[S_RSR_PROJECTILE_RAIL] =	{SPR_RSWS,	FF_FULLBRIGHT,	-1,	nil,	0,	0,	S_NULL}

---@param mo mobj_t
addHook("MobjSpawn", function(mo)
	if not Valid(mo) then return end

	RSR.ProjectileSpawn(mo)
	mo.rsrRailHitList = {}
	mo.rsrRailHitCount = 0
end, MT_RSR_PROJECTILE_RAIL)
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

	if not tmthing.rsrRailHitList[thing] then
		S_StartSound(thing, tmthing.info.activesound) -- Play the rail hit sound to signify the rail actually hit something
		P_DamageMobj(thing, tmthing, tmthing.target, tmthing.info.damage)
		if not (Valid(tmthing) and Valid(thing)) then return false end
		tmthing.rsrRailHitList[thing] = true
		if tmthing.rsrRailHitCount > 0 then -- If the rail hits multiple enemies, play the TF2 Machina sound effect each time (yes, this is how it works in TF2)
			S_StartSound(nil, sfx_mchina)
		end
		if Valid(tmthing.target) and Valid(tmthing.target.player) and not RSR.PlayersAreTeammates(tmthing.target.player, thing.player) then -- Only add Machina sound effects if the target is an enemy player!
			tmthing.rsrRailHitCount = $ + 1
		end
	end
	return false
end, MT_RSR_PROJECTILE_RAIL)
---@param mo mobj_t
---@param line line_t
addHook("MobjMoveBlocked", function(mo, _, line)
	if not (Valid(mo) and Valid(line)) then return end
	mo.cusval = 1 -- Use this to check whether the rail ring hit a wall or not
	mo.angle = R_PointToAngle2(0, 0, line.dx, line.dy) - ANGLE_90
end, MT_RSR_PROJECTILE_RAIL)
---@param mo mobj_t
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end

	-- Reset the hit list every frame
	mo.rsrRailHitList = {}
end, MT_RSR_PROJECTILE_RAIL)

-- --------------------------------
-- PICKUP
-- --------------------------------

mobjinfo[MT_RSR_PICKUP_RAIL] = {
	--$Name Rail Pickup
	--$Sprite RSWIA0
	--$Category Ringslinger Revolution/Weapons
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	--$Arg1 "Don't despawn in co-op"
	--$Arg1Type 11
	--$Arg1Enum offon
	doomednum = 347,
	spawnstate = S_RSR_PICKUP_RAIL,
	deathstate = S_RSR_SPARK,
	deathsound = sfx_itemup,
	radius = 16*FRACUNIT,
	height = 28*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_PICKUP_RAIL] =	{SPR_RSWI,	FF_ANIMATE|FF_GLOBALANIM,	-1,	nil,	15,	3,	S_NULL}

addHook("MobjSpawn", RSR.ItemMobjSpawn, MT_RSR_PICKUP_RAIL)
addHook("MapThingSpawn", RSR.WeaponMapThingSpawn, MT_RSR_PICKUP_RAIL)
addHook("TouchSpecial", function(special, toucher)
	return RSR.WeaponTouchSpecial(special, toucher, RSR.WEAPON_RAIL)
end, MT_RSR_PICKUP_RAIL)
addHook("MobjFuse", RSR.WeaponMobjFuse, MT_RSR_PICKUP_RAIL)
addHook("MobjThinker", function(mo)
	if not Valid(mo) then return end
	RSR.ItemFlingSpark(mo, mo.info.height/3, FRACUNIT/2, 25) -- Smaller sparks! :o
	RSR.WeaponPickupThinker(mo)
end, MT_RSR_PICKUP_RAIL)

-- --------------------------------
-- ACTIONS & STATES
-- --------------------------------

--- Version of RSR.SpawnPlayerMissile that spawns a rail ring from the Object.
---@param mo mobj_t
---@param angle angle_t|nil
---@param pitch angle_t|nil
---@param reflected mobj_t|nil
RSR.SpawnRailRing = function(mo, angle, pitch, reflected)
	if not Valid(mo) then return end
	local rail = RSR.SpawnPlayerMissile(mo, MT_RSR_PROJECTILE_RAIL, angle, pitch, reflected)
	if not Valid(rail) then return end -- Sanity check
	local missRadius = 4*rail.radius
	local missList = {}
	local hitList = {}

	for i = 1, 256 do
		if not Valid(rail) then break end

		-- This might cause performance issues...
		searchBlockmap("objects", function(missile, enemy)
			if not (Valid(missile) and Valid(enemy)) then return end
			if not Valid(enemy.player) then return end
			if enemy.health <= 0 then return end -- Don't play the miss sound for dead players!
			if missList[enemy.player] then return end -- Don't play the miss sound more than once for the same player
			if missile.target == enemy then return end

			if max(0, FixedHypot(FixedHypot(enemy.x - missile.x, enemy.y - missile.y), (enemy.z + enemy.height/2) - (missile.z + missile.height/2)) - enemy.radius) > missRadius then
				return
			end

			missList[enemy] = true
		end, rail, rail.x - missRadius, rail.x + missRadius, rail.y - missRadius, rail.y + missRadius)

		if (i & 1) then
			local spark = P_SpawnMobjFromMobj(rail, 0, 0, 0, MT_UNKNOWN)
			if Valid(spark) then
				spark.state = S_RSR_SPARK
				spark.flags2 = $|MF2_DONTRESPAWN -- Don't linger around...
				-- spark.blendmode = AST_ADD
				spark.translation = "RSRTeamRed" -- The rail's slug is red, so the sparkle trail should be too
				RSR.ColorTeamMissile(spark, mo.player)
			end
		end

		-- TODO: Use matrix math for this when 2.2.16 comes out
		local outerSpark = P_SpawnMobjFromMobj(
			rail,
			P_ReturnThrustX(mo, mo.angle + ANGLE_90, FixedMul(cos(mo.roll), 24*FRACUNIT)),
			P_ReturnThrustY(mo, mo.angle + ANGLE_90, FixedMul(cos(mo.roll), 24*FRACUNIT)),
			FixedMul(sin(mo.roll), 32*FRACUNIT),
			MT_UNKNOWN
		)
		if Valid(outerSpark) then
			outerSpark.state = S_RSR_SPARK
			outerSpark.flags2 = $|MF2_DONTRESPAWN -- Don't linger around...
			outerSpark.blendmode = AST_ADD
			outerSpark.color = SKINCOLOR_AETHER -- The rail's coil is a metallic light blue, so the outer sparkle trail should be too
			outerSpark.colorized = true
			P_InstaThrust(outerSpark, mo.angle + ANGLE_90, FixedMul(cos(mo.roll), 4*FRACUNIT))
			outerSpark.momz = FixedMul(sin(mo.roll), 4*FRACUNIT)
		end
		mo.roll = $ + ANGLE_45

		if P_RailThinker(rail) then
			if Valid(rail) then hitList = rail.rsrRailHitList end
			break
		end

		hitList = rail.rsrRailHitList
	end

	for pmo, _ in pairs(missList) do
		if not (Valid(pmo) and Valid(pmo.player) and pmo.health > 0) then continue end
		if hitList and hitList[pmo] then continue end -- Don't play the sound if the "missed" player was actually hit
		S_StartSound(nil, sfx_railms, pmo.player)
	end

	if Valid(rail) then
		S_StartSound(rail, rail.info.activesound)
		-- Borrowed from P_Earthquake
		local ns = FixedMul(256*FRACUNIT, rail.scale)/12
		local fa = 0
		for i = 0, 15 do
			fa = i*ANGLE_22h
			local spark = P_SpawnMobjFromMobj(rail, 0, 0, 0, MT_SUPERSPARK)
			if Valid(spark) then
				if rail.cusval then -- If the rail hit a wall
					P_InstaThrust(spark, rail.angle + ANGLE_90, FixedMul(cos(fa), ns))
					spark.momz = FixedMul(sin(fa), ns)
				else -- If the rail hit a surface
					spark.momx = FixedMul(sin(fa), ns)
					spark.momy = FixedMul(cos(fa), ns)
				end
			end
		end
		if not (Valid(mo.player) and P_IsLocalPlayer(mo.player)) then
			P_StartQuake(192*FRACUNIT, 24, {x = rail.x, y = rail.y, z = rail.z + rail.height/2}, 192*rail.scale)
		end
	end

	return rail
end

local pspractions = PSprites.ACTIONS

--- Fires a Rail ring from the player.
---@param player player_t
pspractions.A_RailAttack = function(player, args)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo) then return end

	S_StartSound(nil, sfx_railec)

	RSR.SetWeaponDelay(player)
	RSR.SpawnRailRing(player.mo, player.mo.angle, player.cmd.aiming<<16)

	if P_IsLocalPlayer(player) then
 		-- P_StartQuake(64*FRACUNIT, 12, {x = player.mo.x, y = player.mo.y, z = player.mo.z + player.mo.height/2}, 64*player.mo.scale)
		P_StartQuake(64*FRACUNIT, 12, nil, nil)
	end

	-- Force the rail ring to take ammo away even if the player has the infinity powerup
	RSR.TakeAmmoFromReadyWeapon(player, 1, true)

	if pspractions.A_RSRCheckAmmo(player, {}) then
		player.rsrinfo.useZoom = false
		return
	end
end

local psprstates = PSprites.STATES

-- Draw
psprstates["S_RAIL_DRAW"] =	{"RSRRAIL",	"A",	1,	"A_RSRWeaponDraw",		{},	"S_RAIL_DRAW"}
-- Holster
psprstates["S_RAIL_HOLSTER"] =	{"RSRRAIL",	"A",	1,	"A_RSRWeaponHolster",	{},	"S_RAIL_HOLSTER"}
-- Ready
psprstates["S_RAIL_READY"] =	{"RSRRAIL",	"A",	1,	"A_RSRWeaponReady",	{},	"S_RAIL_READY"} -- TODO: Check lastbuttons so the player doesn't accidently fire a rail ring when switching weapons
-- Attack
psprstates["S_RAIL_ATTACK"] =	{"RSRRAIL",	"A",	0,	"A_RailAttack",		{},	"S_RAIL_RECOVER"}
-- Recover
psprstates["S_RAIL_RECOVER"] =	{"RSRRAIL",	"A",	1,	"A_RSRWeaponRecover",	{},	"S_RAIL_RECOVER"}
