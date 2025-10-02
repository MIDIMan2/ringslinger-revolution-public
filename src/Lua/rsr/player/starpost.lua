-- Ringslinger Revolution - Starpost Data System

--- Saves starpost data for the player.
---@param player player_t
RSR.PlayerStarpostDataSave = function(player)
	if G_IsSpecialStage(gamemap) then return end -- Don't save starpost data in a special stage
	if not (Valid(player) and player.rsrinfo) then return end
	local rsrinfo = player.rsrinfo

	local data = rsrinfo.starpostData
	if not data then return end

	data.ammo = RSR.DeepCopy(rsrinfo.ammo)
	data.weapons = RSR.DeepCopy(rsrinfo.weapons)
	data.readyWeapon = rsrinfo.readyWeapon
	data.shields = player.powers[pw_shield] or nil
end

--- Initializes the player's startpost data for RSR.
---@param player player_t
RSR.PlayerStarpostDataInit = function(player)
	if not (Valid(player) and player.rsrinfo) then return end
	if G_IsSpecialStage(gamemap) then -- Don't save starpost data in a special stage
		if not player.rsrinfo.starpostData then player.rsrinfo.starpostData = {} end
		return
	end

	local dontKeepData = ((not (mapheaderinfo[gamemap] and mapheaderinfo[gamemap].rsrkeepinv) and player.starpostnum == 0) or not G_CoopGametype())

	-- Only reset starpost data if RSRKeepInv is not in the level header and the level is not a Special Stage, or the level is not a SP/Coop level
	if not player.rsrinfo.starpostData or dontKeepData then
		player.rsrinfo.starpostData = {}
	end

	if player.rsrStarpostData then
		if not dontKeepData then
			player.rsrinfo.starpostData.ammo = RSR.DeepCopy(player.rsrStarpostData.ammo)
			player.rsrinfo.starpostData.weapons = RSR.DeepCopy(player.rsrStarpostData.weapons)
			player.rsrinfo.starpostData.readyWeapon = player.rsrStarpostData.readyWeapon
			player.rsrinfo.starpostData.shields = player.rsrStarpostData.shields
		end

		player.rsrStarpostData = nil
	end

	if player.starpostnum == 0 and mapheaderinfo[gamemap] and mapheaderinfo[gamemap].rsrweaponstart then
		local data = player.rsrinfo.starpostData
		if data.ammo == nil then data.ammo = RSR.DeepCopy(player.rsrinfo.ammo) end
		if data.weapons == nil then data.weapons = RSR.DeepCopy(player.rsrinfo.weapons) end

		for wString in string.gmatch(mapheaderinfo[gamemap].rsrweaponstart, "[^,]+") do
			local info = {}

			for aString in string.gmatch(wString, "[^:]+") do table.insert(info, aString:upper()) end

			if not (info[1] and RSR["WEAPON_"..info[1]]) then
				print("\x82WARNING:\x80 Weapon type "..info[1].." not found in RSRWeaponStart parameter!")
				continue
			end

			if info[2] == nil then
				print("\x82WARNING:\x80 Ammo count not found for weapon "..info[1].." in RSRWeaponStart parameter! Please use a \":\" to separate the weapon name and ammo count!")
				continue
			elseif tonumber(info[2]) == nil then
				print("\x82WARNING:\x80 Ammo count couldn't be converted to a number for weapon "..info[1].." in RSRWeaponStart parameter!")
				continue
			end

			data.weapons[RSR["WEAPON_"..info[1]]] = true
			if not data.readyWeapon then data.readyWeapon = RSR["WEAPON_"..info[1]] end
			local ammoType = RSR.WEAPON_INFO[RSR["WEAPON_"..info[1]]].ammotype
			data.ammo[ammoType] = min($ + tonumber(info[2]), RSR.AMMO_INFO[ammoType].maxamount or 0)
-- 			print("WARNING: Incorrect format for RSRWeaponStart! Read the PK3's README for details!")
		end
	end
	player.rsrinfo.starpostNum = player.starpostnum
end

--- Loads the player's starpost data on spawn.
---@param player player_t
RSR.PlayerStarpostDataSpawn = function(player)
	if G_IsSpecialStage(gamemap) then return end -- Don't save starpost data in a special stage
	if not (Valid(player) and player.rsrinfo) then return end
	local rsrinfo = player.rsrinfo

	if not rsrinfo.starpostData then return end

	local data = rsrinfo.starpostData
	-- if data.health ~= nil then rsrinfo.health = data.health end
	-- if data.armor ~= nil then rsrinfo.armor = data.armor end
	if data.ammo ~= nil then rsrinfo.ammo = RSR.DeepCopy(data.ammo) end
	if (multiplayer or netgame) and G_CoopGametype() then
		for ammo, amount in ipairs(rsrinfo.ammo) do
			if not (RSR.AMMO_INFO[ammo] and RSR.AMMO_INFO[ammo].amount) then continue end
			if amount <= RSR.AMMO_INFO[ammo].amount then continue end -- Make sure the player already had ammo in their inventory

			rsrinfo.ammo[ammo] = RSR.AMMO_INFO[ammo].amount
		end
	end
	if data.weapons ~= nil then rsrinfo.weapons = RSR.DeepCopy(data.weapons) end
	if data.readyWeapon ~= nil then
		rsrinfo.readyWeapon = data.readyWeapon
		PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, RSR.WEAPON_INFO[rsrinfo.readyWeapon].states.ready)
	end
	if data.shields ~= nil then
-- 		player.powers[pw_shield] = data.shields
		P_SwitchShield(player, data.shields)
		rsrinfo.armor = 10 -- Give the player back SOME armor if they had a shield
	end
end

--- Automatically runs RSR.PlayerStarpostDataSave when the player has passed a starpost or cleared the level.
---@param player player_t
RSR.PlayerStarpostDataTick = function(player)
	if G_IsSpecialStage(gamemap) then return end -- Don't save starpost data in a special stage
	if not (Valid(player) and player.rsrinfo) then return end
	local rsrinfo = player.rsrinfo

	if player.starpostnum ~= rsrinfo.starpostNum or (player.exiting and not rsrinfo.lastexiting) then
		rsrinfo.starpostNum = player.starpostnum

		RSR.PlayerStarpostDataSave(player)
	end
end
