-- Ringslinger Revolution - Actions

RSR.MonitorGamemodeCheck = function(mo)
	return (RSR.GamemodeActive() and Valid(mo) and Valid(mo.target) and Valid(mo.target.player))
end

--- P_DustRing ported from C to Lua, since it's not exposed for some reason.
---@param mobjtype mobjtype_t
---@param div integer
---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param radius fixed_t
---@param speed fixed_t
---@param initscale fixed_t
---@param scale fixed_t
RSR.P_DustRing = function(mobjtype, div, x, y, z, radius, speed, initscale, scale)
	local ang = FixedAngle(FixedDiv(360*FRACUNIT, div*FRACUNIT))

	for i = 0, div - 1 do
		local dust = P_SpawnMobj(x, y, z, mobjtype)
		if not Valid(dust) then continue end

		dust.angle = ang*i + ANGLE_90
		P_SetScale(dust, FixedMul(initscale, scale), true)
		dust.destscale = FixedMul(4*FRACUNIT + P_RandomFixed(), scale)
		dust.scalespeed = scale/24
		P_Thrust(dust, ang*i, speed + FixedMul(P_RandomFixed(), scale))
		dust.momz = P_SignedRandom()*scale/64
	end
end

-- Just so I don't have to make a new TNT barrel object
---@param actor mobj_t
A_TNTExplode = function(actor, var1, var2)
	if not (RSR.GamemodeActive() and Valid(actor)) then
		super(actor, var1, var2)
		return
	end

	if Valid(actor.tracer) then
		actor.tracer.tracer = nil
		actor.tracer = nil
	end

	actor.flags = $|MF_NOCLIP|MF_NOGRAVITY|MF_NOBLOCKMAP
	actor.flags2 = $|MF2_EXPLOSION
	if actor.info.deathsound then
		S_StartSound(actor, actor.info.deathsound)
	end

	RSR.Explode(actor, 256*FRACUNIT, nil, 60)

	P_StartQuake(9*FRACUNIT, TICRATE/6, {actor.x, actor.y, actor.z}, 512*FRACUNIT)

	if var1 then
		RSR.P_DustRing(var1, 4, actor.x, actor.y, actor.z + actor.height, 64, 0, FRACUNIT, actor.scale)
		RSR.P_DustRing(var1, 6, actor.x, actor.y, actor.z + actor.height/2, 96, FRACUNIT, FRACUNIT, actor.scale)
	end

	actor.destscale = $*4
end

---@param actor mobj_t
A_MonitorPop = function(actor, var1, var2)
	super(actor, var1, var2)
	if not (RSR.GamemodeActive() and Valid(actor)) then return end
	if not (actor.flags2 & MF2_STRONGBOX) then return end
	if Valid(actor.rsrStrongBoxIcon) then P_RemoveMobj(actor.rsrStrongBoxIcon) end
	actor.state = S_RSR_STRONGBOX_POP1
end

---@param actor mobj_t
A_RingBox = function(actor, var1, var2)
	if not RSR.MonitorGamemodeCheck(actor) then
		super(actor, var1, var2)
		return
	end

	local player = actor.target.player
	RSR.BonusFade(player)
	RSR.GiveHealth(player, RSR.MAX_HEALTH) -- TODO: Maybe make this not always give 100 health, since the action is used to give different amounts of rings
	S_StartSound(actor.target, sfx_ncitem)
-- 	super(actor, var1, var2)
end

---@param actor mobj_t
A_GiveShield = function(actor, var1, var2)
	if not RSR.MonitorGamemodeCheck(actor) then
		super(actor, var1, var2)
		return
	end

	local player = actor.target.player

	-- Special case for the Pity Shield
	if var1 == SH_PITY then
		RSR.GiveArmor(player, RSR.MAX_ARMOR)
		RSR.BonusFade(player)
		S_StartSound(actor.target, sfx_ncitem)
		return
	end

	RSR.GiveArmor(player, 10)
	RSR.BonusFade(player)
	super(actor, var1, var2)
end

---@param actor mobj_t
A_ExtraLife = function(actor, var1, var2)
	if not RSR.MonitorGamemodeCheck(actor) then
		super(actor, var1, var2)
		return
	end

	local player = actor.target.player
	RSR.BonusFade(player)
	RSR.GiveHealth(player, RSR.MAX_HEALTH_BONUS, true)
	RSR.GiveArmor(player, RSR.MAX_ARMOR_BONUS, true)
	S_StartSound(actor.target, sfx_ncitem)

	if actor.type == MT_1UP_ICON and Valid(actor.tracer) then
		-- Use the overlay sprite if the player has a life icon
		actor.sprite = SPR_TV1P
	end

-- 	super(actor, var1, var2)
end

---@param actor mobj_t
A_Invincibility = function(actor, var1, var2)
	if not RSR.MonitorGamemodeCheck(actor) then
		super(actor, var1, var2)
		return
	end

	local player = actor.target.player
	RSR.BonusFade(player)
	RSR.GivePowerup(player, RSR.POWERUP_INVINCIBILITY)
	S_StartSound(actor.target, sfx_ncitem)
-- 	super(actor, var1, var2)
end

---@param actor mobj_t
A_SuperSneakers = function(actor, var1, var2)
	if not RSR.MonitorGamemodeCheck(actor) then
		super(actor, var1, var2)
		return
	end

	local player = actor.target.player
	RSR.BonusFade(player)
	RSR.GivePowerup(player, RSR.POWERUP_SPEED)
	S_StartSound(actor.target, sfx_ncitem)
-- 	super(actor, var1, var2)
end

---@param actor mobj_t
A_EggmanBox = function(actor, var1, var2)
	if not RSR.MonitorGamemodeCheck(actor) then
		super(actor, var1, var2)
		return
	end

	actor.rsrRealDamage = true
	actor.rsrDontThrust = true
	P_DamageMobj(actor.target, actor, actor, 15, 0)
	actor.rsrRealDamage = nil
	actor.rsrDontThrust = nil
-- 	super(actor, var1, var2)
end

-- Create our own NUMPOWERS since the actual NUMPOWERS isn't exposed to Lua for some reason...
-- TODO: Make sure this lines up with the actual NUMPOWERS after 2.2.15
local RSR_NUMPOWERS = pw_strong + 1

---@param actor mobj_t
A_RecyclePowers = function(actor, var1, var2)
	if not RSR.MonitorGamemodeCheck(actor) then
		super(actor, var1, var2)
		return
	end

	local i, j, k, numplayers = 0, 0, 0, 0

	local playerslist = {}
	local postscramble = {}

	local powers = {}
	for l = 0, #players do
		powers[i+1] = {}
		i = $+1
	end
	i = 0
	local weapons = {}
	local weaponheld = {}
	local ammo = {}
	local armor = {}
	local powerups = {}
	local lastemeralds = {}
	local hype = {}

	if not multiplayer then
		S_StartSound(actor, sfx_lose)
		return
	end

	numplayers = 0

	-- Count the number of players in the game
	i, j = 0, 0
	while i < #players do
		local player = players[i]
		if player and player.valid and player.mo and player.mo.valid and player.mo.health > 0 and player.rsrinfo and player.playerstate == PST_LIVE
		and not player.exiting and not ((netgame or multiplayer) and player.spectator) then
			numplayers = $+1
			postscramble[j+1] = i
			playerslist[j+1] = i

			-- Save powers
			k = 0
			while k < RSR_NUMPOWERS do
				powers[i+1][k+1] = player.powers[k]
				k = $+1
			end
			--1.1: ring weapons too
			weapons[i+1] = player.rsrinfo.weapons
			weaponheld[i+1] = player.rsrinfo.readyWeapon
			ammo[i+1] = player.rsrinfo.ammo
			armor[i+1] = player.rsrinfo.armor
			powerups[i+1] = player.rsrinfo.powerups
			lastemeralds[i+1] = player.rsrinfo.lastemeralds
			hype[i+1] = player.rsrinfo.hype

			j = $+1
		end

		i = $+1
	end

	if numplayers <= 1 then
		S_StartSound(actor, sfx_lose)
		return -- Nobody to touch!
	end

	--shuffle the post scramble list, whee!
	-- hardcoded 0-1 to 1-0 for two players
	if numplayers == 2 then
		postscramble[1] = playerslist[2]
		postscramble[2] = playerslist[1]
	else
		j = 0
		while j < numplayers do
			local tempint = 0

			i = j + ((P_RandomByte() + leveltime) % (numplayers - j))
			tempint = postscramble[j+1]
			postscramble[j+1] = postscramble[i+1]
			postscramble[i+1] = tempint

			j = $+1
		end
	end

	-- now assign!
	i = 0
	while i < numplayers do
		local send_pl = playerslist[i+1]
		local recv_pl = postscramble[i+1]

-- 		print(string.format("sending player %s's items to %s", send_pl, recv_pl))

		j = 0
		while j < RSR_NUMPOWERS do
			if j == pw_flashing or j == pw_underwater or j == pw_spacetime or j == pw_carry
			or j == pw_tailsfly or j == pw_extralife or j == pw_nocontrol or j == pw_super
			or j == pw_pushing or j == pw_justsprung or j == pw_noautobrake or j == pw_justlaunched
			or j == pw_ignorelatch then
				j = $+1
				continue
			end
			players[recv_pl].powers[j] = powers[send_pl+1][j+1] or 0

			j = $+1
		end

		--1.1: weapon rings too
		if players[recv_pl].rsrinfo then
			players[recv_pl].rsrinfo.weapons = weapons[send_pl+1]
			players[recv_pl].rsrinfo.ammo = ammo[send_pl+1]
			-- Reset weapon info
			if RSR.CanUseWeapons(players[recv_pl]) then
				players[recv_pl].rsrinfo.readyWeapon = weaponheld[send_pl+1]
			end
			players[recv_pl].rsrinfo.weaponDelay = 0
			players[recv_pl].rsrinfo.weaponDelayOrig = 0
			if RSR.CanUseWeapons(players[recv_pl]) then
				-- Check available weapons first, and THEN draw WEAPON_NONE if none were found
				PSprites.ACTIONS.A_RSRCheckAmmo(players[recv_pl], {true})
			end

			players[recv_pl].rsrinfo.armor = armor[send_pl+1]
			players[recv_pl].rsrinfo.powerups = powerups[send_pl+1]
			players[recv_pl].rsrinfo.lastemeralds = lastemeralds[send_pl+1]
			players[recv_pl].rsrinfo.hype = hype[send_pl+1]
		end

		P_SpawnShieldOrb(players[recv_pl])
		if P_IsLocalPlayer(players[recv_pl]) then
			P_RestoreMusic(players[recv_pl])
		end
		P_FlashPal(players[recv_pl], PAL_RECYCLE, 10)

		i = $+1
	end

	S_StartSound(nil, sfx_gravch) --heh, the sound effect I used is already in
end
