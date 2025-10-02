-- Ringslinger Revolution - HUD Weapon Bar

--- Draws the player's weapon bar to the HUD.
---@param player player_t
RSR.HUDWeaponBar = function(v, player)
	if not RSR.GamemodeActive() then return end
	if not (v and Valid(player) and player.rsrinfo) then return end
	if not RSR.CanUseWeapons(player) then return end

	local rsrinfo = player.rsrinfo

	local x = 92
	local y = 176

	local curWeapon = rsrinfo.readyWeapon
	if rsrinfo.pendingWeapon ~= -1 then curWeapon = rsrinfo.pendingWeapon end

	local curClass = RSR.WEAPON_INFO[curWeapon].class or 0
	local curSlot = RSR.WEAPON_INFO[curWeapon].slot

	for class, weapons in ipairs(RSR.CLASS_TO_WEAPON) do
		local i = 1
		local weaponsList = {}

		while i <= #weapons do
			local slot = i
			local notCurSlot = false

			if class == curClass then
				slot = ((i + curSlot - 1) % #weapons) + 1
				if slot ~= curSlot then
					notCurSlot = true
				end
			end

			local weapon = weapons[slot]

			local weaponInfo = RSR.WEAPON_INFO[weapon]
			if not weaponInfo then
				i = $+1
				continue
			end

			local ammo = rsrinfo.ammo[weaponInfo.ammotype]

			if not rsrinfo.weapons[weapon] then
				ammo = 0
			end

			if weaponInfo.powerweapon and ammo == 0 then
				i = $+1
				continue
			end

			local weaponToInsert = {
				weapon = weapon,
				ammo = ammo,
				ammoType = weaponInfo.ammotype,
				class = class,
				icon = weaponInfo.icon,
				notCurSlot = notCurSlot
			}

			table.insert(weaponsList, 1, weaponToInsert)

			i = $+1
		end

		-- There's probably a better way to do this that doesn't involve two loops...
		for key, info in ipairs(weaponsList) do
			if not info then continue end

			local transFlag = V_HUDTRANS
			if info.ammo <= 0 or player.playerstate ~= PST_LIVE
			or info.notCurSlot or (key > 1 and info.class ~= curClass) then
				transFlag = V_HUDTRANSHALF
			end

			local maxFlag = 0
			if info.ammo >= RSR.AMMO_INFO[info.ammoType].maxamount then maxFlag = V_YELLOWMAP end

			local yOffset = -18 * (key - 1)

			v.draw(x, y + yOffset, v.cachePatch(info.icon), V_SNAPTOBOTTOM|transFlag|V_PERPLAYER)
			if info.ammo and player.playerstate == PST_LIVE then
				v.drawString(x + 16, y + 9 + yOffset, tostring(info.ammo), maxFlag|V_SNAPTOBOTTOM|transFlag|V_PERPLAYER, "thin-right")
			end
		end

		x = $+20
	end

	if curClass > 0 and player.playerstate == PST_LIVE then
		local weaponDelayScale = 0
		if rsrinfo.weaponDelayOrig > 0 then
			weaponDelayScale = ease.outquad(rsrinfo.weaponDelay*FRACUNIT/70)
		end
		v.draw(92 + ((curClass - 1)*20) - 2, y - 2 - ((19*weaponDelayScale)/FRACUNIT), v.cachePatch("CURWEAP"), V_SNAPTOBOTTOM|V_HUDTRANS|V_PERPLAYER)
	end
end
