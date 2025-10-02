-- Ringslinger Revolution - Weapon Choice System

--- Gets the player's current weapon's class.
---@param classNum integer
RSR.GetWeaponClass = function(classNum)
	if classNum == nil then
		print("\x82WARNING:\x80 classNum set to nil in RSR.GetWeaponClass! Defaulting to 1...")
		return 1
	end

	if classNum > #RSR.CLASS_TO_WEAPON then
		classNum = 1
	elseif classNum < 1 then
		classNum = #RSR.CLASS_TO_WEAPON
	end

	return classNum
end

--- Gets "next" weapon in the player's inventory based on the offset.
---@param weapon integer The player's current weapon (RSR.WEAPON_ constant).
---@param offset integer|nil Offset from the current weapon.
RSR.GetNextOrPrevWeapon = function(weapon, offset)
	if weapon == nil then return end
	if offset == nil then offset = 1 end
	if weapon <= RSR.WEAPON_NONE or weapon >= RSR.WEAPON_MAX then return end

	local info = RSR.WEAPON_INFO[weapon]
	local class = info.class
	local slot = info.slot
	local weaponNum = 0

	repeat
		if RSR.CLASS_TO_WEAPON[class] then
			slot = $+offset
			if slot > #RSR.CLASS_TO_WEAPON[class] then
				class = RSR.GetWeaponClass($+offset)
				slot = 1
			elseif slot < 1 then
				class = RSR.GetWeaponClass($+offset)
				slot = #RSR.CLASS_TO_WEAPON[class]
			end
			weaponNum = $+1
			continue
		end

		class = RSR.GetWeaponClass($+offset)
		weaponNum = $+1
	until (RSR.CLASS_TO_WEAPON[class] and RSR.CLASS_TO_WEAPON[class][slot]) or weaponNum >= RSR.WEAPON_MAX

	-- Return the same weapon if the repeat loop has been broken by weaponNum
	if weaponNum >= RSR.WEAPON_MAX then
		return weapon
	end
	return RSR.CLASS_TO_WEAPON[class][slot]
end

--- Handles player weapon switching.
---@param player player_t
RSR.PlayerWeaponChoiceTick = function(player)
	if not (Valid(player) and player.rsrinfo) then return end

	local rsrinfo = player.rsrinfo

	-- Don't change weapons if the player can't use them or isn't holding one
	if rsrinfo.readyWeapon == RSR.WEAPON_NONE or not RSR.CanUseWeapons(player) then return end

	local newWeapon
	if not (rsrinfo.lastbuttons & (BT_WEAPONNEXT|BT_WEAPONPREV|BT_WEAPONMASK)) then
		-- Allow the player to change weapons with the next and previous buttons
		if (player.cmd.buttons & BT_WEAPONNEXT) then
			newWeapon = rsrinfo.readyWeapon
			if rsrinfo.pendingWeapon ~= -1 then newWeapon = rsrinfo.pendingWeapon end

			local weaponCount = 0
			repeat
				newWeapon = RSR.GetNextOrPrevWeapon($, 1)
				weaponCount = $+1
			until (rsrinfo.weapons[newWeapon] and RSR.CheckAmmo(player, RSR.WEAPON_INFO[newWeapon].ammotype)) or weaponCount >= RSR.WEAPON_MAX

			if weaponCount >= RSR.WEAPON_MAX then
				newWeapon = nil
			end
		elseif (player.cmd.buttons & BT_WEAPONPREV) then
			newWeapon = rsrinfo.readyWeapon
			if rsrinfo.pendingWeapon ~= -1 then newWeapon = rsrinfo.pendingWeapon end

			local weaponCount = 0
			repeat
				newWeapon = RSR.GetNextOrPrevWeapon($, -1)
				weaponCount = $+1
			until (rsrinfo.weapons[newWeapon] and RSR.CheckAmmo(player, RSR.WEAPON_INFO[newWeapon].ammotype)) or weaponCount >= RSR.WEAPON_MAX

			if weaponCount >= RSR.WEAPON_MAX then
				newWeapon = nil
			end
		end

		-- Allow the player to instantly switch to a specified weapon
		if (player.cmd.buttons & BT_WEAPONMASK) and (player.cmd.buttons & BT_WEAPONMASK) ~= ((rsrinfo.lastbuttons or 0) & BT_WEAPONMASK) then
			local weaponSlot = RSR.WEAPON_INFO[rsrinfo.readyWeapon].slot

			local tempClass = player.cmd.buttons & BT_WEAPONMASK
			local tempSlot = weaponSlot
			if RSR.CLASS_TO_WEAPON[tempClass] then
				local maxWeapons = #RSR.CLASS_TO_WEAPON[tempClass]
				local tempWeapon = rsrinfo.readyWeapon

				if RSR.WEAPON_INFO[rsrinfo.readyWeapon].class == tempClass then
					repeat
						tempSlot = $-1
						if tempSlot <= 0 then tempSlot = maxWeapons end
						tempWeapon = RSR.CLASS_TO_WEAPON[tempClass][tempSlot]
					until (rsrinfo.weapons[tempWeapon] and RSR.CheckAmmo(player, RSR.WEAPON_INFO[tempWeapon].ammotype)) or tempSlot == weaponSlot
				else
					tempSlot = maxWeapons
					tempWeapon = RSR.CLASS_TO_WEAPON[tempClass][tempSlot]
					local foundWeapon = false

					while tempSlot > 0 do
						if rsrinfo.weapons[tempWeapon] and RSR.CheckAmmo(player, RSR.WEAPON_INFO[tempWeapon].ammotype) then
							foundWeapon = true
							break
						end

						tempSlot = $-1
						tempWeapon = RSR.CLASS_TO_WEAPON[tempClass][tempSlot]
					end

					if not foundWeapon then tempWeapon = rsrinfo.readyWeapon end
				end

				weaponSlot = tempSlot
				newWeapon = tempWeapon
			end
		end
	end

	-- Don't let newWeapon go above or below the weapon constant definitions
	if newWeapon ~= nil then
		if rsrinfo.readyWeapon ~= newWeapon then
			if Valid(player.mo) then S_StartSound(player.mo, sfx_wepchg) end
			rsrinfo.pendingWeapon = newWeapon
		end
	end
end
