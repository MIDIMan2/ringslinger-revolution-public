-- Ringslinger Revolution - Player

local folder = "rsr/player"

local dofolder = function(file)
	dofile(folder.."/"..file)
end

dofolder("chasecam.lua")

dofolder("damage.lua")
dofolder("weaponchoice.lua")
dofolder("starpost.lua")
dofolder("powerups.lua")
dofolder("super.lua")
dofolder("homing.lua")
dofolder("flame.lua")
dofolder("ghostbusters.lua")
dofolder("skininfo.lua")

dofolder("screenfade.lua")

--- Initializes the player's weapon variables.
---@param player player_t
RSR.PlayerWeaponsInit = function(player)
	if not (Valid(player) and player.rsrinfo) then return end

	local rsrinfo = player.rsrinfo

	rsrinfo.weapons = {}
	for i = RSR.WEAPON_NONE + 1, RSR.WEAPON_MAX - 1 do
		rsrinfo.weapons[i] = false
	end

	rsrinfo.ammo = {}
	for i = RSR.AMMO_BASIC, RSR.AMMO_MAX do
		rsrinfo.ammo[i] = 0
	end

	rsrinfo.readyWeapon = RSR.WEAPON_NONE
	rsrinfo.pendingWeapon = -1

	rsrinfo.weaponDelay = 0
	rsrinfo.weaponDelayOrig = 0
end

--- Initializes the player's variables for RSR.
---@param player player_t
RSR.PlayerInit = function(player)
	if not Valid(player) then return end

	if not player.rsrinfo then
		player.rsrinfo = {}
	end

	local rsrinfo = player.rsrinfo
	rsrinfo.lastbuttons = player.lastbuttons
	rsrinfo.lastexiting = player.exiting
	rsrinfo.lastemeralds = player.powers[pw_emeralds]

	RSR.PlayerHealthInit(player)
	RSR.PlayerWeaponsInit(player)
	RSR.PlayerPowerupsInit(player)

	RSR.PlayerStarpostDataInit(player)

	rsrinfo.bob = {x = 0, y = 0}

	RSR.PlayerScreenFadeInit(player)

	PSprites.PlayerPSpritesInit(player)
	PSprites.PlayerPSpritesReset(player)

	-- Use our own homing variable for homing onto players,
	-- since SRB2 automatically sets player.homing to 0 if the player isn't targetting an enemy
	rsrinfo.homing = 0
	rsrinfo.homingThreshold = 0

	rsrinfo.basicCharge = 0 -- Used for the Red Ring's altfire; See weapon/basic.lua for more information
	rsrinfo.basicChargeSound = 0 -- Used for the Red Ring's altfire; See weapon/basic.lua for more information
	rsrinfo.basicChargeDontTakeAmmo = false -- Used for the Red Ring's altfire; See weapon/basic.lua for more information
	rsrinfo.scatterFlak = nil -- Used for the Scatter Ring's altfire; See weapon/scatter.lua for more information
	rsrinfo.bounceMega = nil -- Used for the Bounce Ring's altfire; See weapon/bounce.lua for more information
	rsrinfo.waspTime = RSR.HOMING_WASP_MAX -- Used for the Homing Ring's altfire; See weapon/homing.lua for more information

	rsrinfo.useZoom = false
	rsrinfo.fovZoom = 0

	RSR.PlayerSetChasecam(player, false)

	-- Reset normalspeed in case the attraction shield messed with it
	player.normalspeed = skins[player.skin].normalspeed
	-- rsrinfo.boostNormalspeed = false

	player.rsrPrevSkin = player.skin
end

-- Deinitializes the player's variables for RSR.
---@param player player_t
RSR.PlayerDeinit = function(player)
	if not Valid(player) then return end

	-- Store starpost data for special stages in case the next map uses RSRKeepInv
	if G_IsSpecialStage(gamemap) and player.rsrinfo and player.rsrinfo.starpostData then
		player.rsrStarpostData = {}

		if player.rsrinfo.starpostData.ammo ~= nil then player.rsrStarpostData.ammo = RSR.DeepCopy(player.rsrinfo.starpostData.ammo) end
		if player.rsrinfo.starpostData.weapons ~= nil then player.rsrStarpostData.weapons = RSR.DeepCopy(player.rsrinfo.starpostData.weapons) end
		if player.rsrinfo.starpostData.readyWeapon ~= nil then player.rsrStarpostData.readyWeapon = player.rsrinfo.starpostData.readyWeapon end
		if player.rsrinfo.starpostData.shields ~= nil then player.rsrStarpostData.shields = player.rsrinfo.starpostData.shields end
	end

	-- Reset normalspeed in case the attraction shield messed with it
	player.normalspeed = skins[player.skin].normalspeed

	player.rsrinfo = nil
	-- player.psprites = nil -- TODO: Figure out where and how to de-initialize the RSR psprites...
end

--- Initializes the player's RSR variables on spawn.
---@param player player_t
RSR.PlayerSpawn = function(player)
	if not Valid(player) then return end
	if not RSR.GamemodeActive() then
		if player.rsrPrevSkin == nil then player.rsrPrevSkin = player.skin end
		RSR.ToggleHUDItems(player) -- Originally, players that joined mid-game would have overlapping HUDS; Not anymore!
		return
	end

	RSR.PlayerInit(player)
	RSR.PlayerStarpostDataSpawn(player)
	RSR.ToggleHUDItems(player) -- Originally, players that joined mid-game would have overlapping HUDS; Not anymore!

	if (multiplayer or netgame) then
		if G_RingSlingerGametype() and not player.spectator and Valid(player.mo) then
			RSR.SpawnTeleportFog(player.mo, nil, sfx_rsrsp1)
		end

		-- Late join Waves map (Partially borrowed from P_SpawnPlayer)
		if RSR.WavesGamemodeActive() and leveltime > 0 then
			player.spectator = true
			player.outofcoop = true
			player.pflags = $ & ~PF_FINISHED -- PF_FINISHED makes player.exiting become 0 in P_PlayerThink, so remove it
			local foundPlayer = false
			for player2 in players.iterate() do
				if not Valid(player2) then continue end
				if player2.playerstate ~= PST_LIVE then continue end
				if player2.spectator then continue end
				foundPlayer = true
			end
			-- Softlock prevention for when all players are kicked from a dedicated server right as they finish the level
			if not foundPlayer then
				player.exiting = (14*TICRATE)/5 + 1
			end

			return
		end
	end
end

--- PlayerThink hook code for the player.
---@param player player_t
RSR.PlayerThink = function(player)
	if not Valid(player) then return end

	if player.rsrPrevSkin ~= nil and player.skin ~= player.rsrPrevSkin then RSR.ToggleHUDItems(player) end
	player.rsrPrevSkin = player.skin

	if not Valid(player.mo) then -- TODO: Might want to rewrite this for 2.3
		if RSR.GamemodeActive() and Valid(player.realmo) and player.spectator then
			RSR.PlayerGhostbustersTick(player)
		end
		return
	end

	-- Don't run this hook unless we're in the Ringslinger gamemode
	if not RSR.GamemodeActive() then
		if player.rsrinfo then RSR.PlayerDeinit(player) end
		return
	end

	if player.playerstate == PST_LIVE then
		RSR.PlayerFlameShieldTick(player)
		RSR.PlayerHomingThink(player)
		RSR.PlayerWeaponChoiceTick(player)
		-- Give the player a speed boost if they have the attraction shield (unless they have speed shoes or super)
		-- TODO: This might break some momentum and/or character mods...
		-- if (player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT and not (player.powers[pw_sneakers] or player.powers[pw_super]) then
		-- 	player.normalspeed = FixedMul(skins[player.skin].normalspeed, 13*FRACUNIT/10) -- normalspeed * 1.3
		-- 	player.rsrinfo.boostNormalspeed = true
		-- elseif player.rsrinfo.boostNormalspeed then
		-- 	player.normalspeed = skins[player.skin].normalspeed
		-- 	player.rsrinfo.boostNormalspeed = false
		-- end
	end

	if player.playerstate == PST_DEAD then
		-- Force momentum on the player if they have died
		if player.mo.rsrPrevMomX or player.mo.rsrPrevMomY or player.mo.rsrPrevMomZ then
			player.mo.momx = $ + (player.mo.rsrPrevMomX or 0)
			player.mo.momy = $ + (player.mo.rsrPrevMomY or 0)
			player.mo.momz = $ + (player.mo.rsrPrevMomZ or 0) -- TODO: This is supposed to make the player go up...
			player.mo.rsrPrevMomX = 0
			player.mo.rsrPrevMomY = 0
			player.mo.rsrPrevMomZ = 0
		end
		-- TODO: Comment this out if it causes memory issues
		local horiMom = FixedDiv(FixedHypot(player.mo.momx, player.mo.momy), player.mo.scale)
		if horiMom > 8*FRACUNIT then
			player.mo.spriteroll = $ - FixedAngle(min(45*FRACUNIT, horiMom/2))
		end
		player.mo.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
		if player.mo.fuse < TICRATE then player.mo.flags2 = $ ^^ MF2_DONTDRAW end
	end

	-- Don't let the NiGHTS timer time out on the player in "Waves" maps
	if G_IsSpecialStage(gamemap) and player.nightstime then
		player.nightstime = -1
	end

	local destBobY = 0
	local bobAngle = FixedDiv((leveltime%45)*FRACUNIT, 45*FRACUNIT/2) * 360
	local bobAmount = FixedDiv(player.bob, player.mo.scale) -- TODO: Might have to change this when the default value of movebob is decreased to 0.25
	if P_IsObjectOnGround(player.mo) then
		destBobY = FixedMul(bobAmount, sin(FixedAngle(-bobAngle))/2) + bobAmount/2
	else
		-- destBobY = FixedMul(player.mo.momz, abs(player.mo.momz))/2
		destBobY = max(min(3*player.mo.momz, 24*FRACUNIT), -8*FRACUNIT) + (FixedMul(bobAmount/2, sin(FixedAngle(-bobAngle))/2) + bobAmount/4)
	end

	-- Smooth the movement of the weapon bob
	-- Based off of Snap the Sentinel v3.1's code
	player.rsrinfo.bob.y = $ + (destBobY - $)/4

	if player.rsrinfo.useZoom then
		if not player.rsrinfo.fovZoom then S_StartSound(player.mo, sfx_scope) end
		if player.rsrinfo.fovZoom < 9 then
			player.rsrinfo.fovZoom = $+1
		end
		player.fovadd = -30*FRACUNIT
	else
		if player.rsrinfo.fovZoom then S_StartSound(player.mo, sfx_epocs) end
		player.rsrinfo.fovZoom = 0
	end

	if player.rsrinfo.weaponDelay then player.drawangle = player.mo.angle end

	PSprites.TickPSpritesBegin(player)

	RSR.PlayerDamageTick(player)
	RSR.PlayerPowerupsTick(player)
	RSR.PlayerSuperTick(player)

	PSprites.TickPSprites(player)
	RSR.ScreenFadeTick(player)

	RSR.PlayerStarpostDataTick(player)

	player.rsrinfo.lastshield = player.powers[pw_shield] & SH_NOSTACK
	player.rsrinfo.lastsneakers = player.powers[pw_sneakers]
	player.rsrinfo.lastbuttons = player.cmd.buttons
	player.rsrinfo.lastexiting = player.exiting
	player.rsrinfo.lastemeralds = player.powers[pw_emeralds]

	if player.playerstate == PST_LIVE then
		player.mo.rsrPrevMomX = player.mo.momx
		player.mo.rsrPrevMomY = player.mo.momy
		player.mo.rsrPrevMomZ = player.mo.momz
	end

	-- Override the default weapons controls, unless the player's skin doesn't use RSR's weapons (then let the character handle it instead)
	if not (RSR.SKIN_INFO[player.mo.skin] and RSR.SKIN_INFO[player.mo.skin].noweapons) then
		player.pflags = $|PF_ATTACKDOWN
		player.cmd.buttons = $ & ~(BT_WEAPONNEXT|BT_WEAPONPREV|BT_WEAPONMASK)
	end
end

RSR.PlayerMobjFuse = function(mo)
	if not RSR.GamemodeActive() then return end
	if not (Valid(mo) and Valid(mo.player) and mo.player.playerstate == PST_DEAD) then return end
	-- Stop the player's momentum when the fuse runs out while dead
	mo.momx = 0
	mo.momy = 0
	mo.momz = 0
end

addHook("PlayerSpawn", RSR.PlayerSpawn)
addHook("PlayerThink", RSR.PlayerThink)
addHook("ShieldSpecial", RSR.PlayerShieldSpecial)
addHook("AbilitySpecial", RSR.PlayerAbilitySpecial)
addHook("MobjDamage", RSR.PlayerDamage, MT_PLAYER)
addHook("ShouldDamage", RSR.PlayerShouldDamage, MT_PLAYER)
addHook("MobjCollide", RSR.PlayerMelee, MT_PLAYER)
addHook("MobjMoveCollide", RSR.PlayerMelee, MT_PLAYER)
addHook("MobjDeath", RSR.PlayerDeath, MT_PLAYER)
addHook("TeamSwitch", RSR.TeamSwitch)
addHook("MobjFuse", RSR.PlayerMobjFuse, MT_PLAYER)

-- Override HurtMsg in favor of the killfeed
addHook("HurtMsg", function()
	if RSR.GamemodeActive() then return true end
end)
