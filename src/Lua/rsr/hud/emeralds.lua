-- Ringslinger Revolutions - Emeralds HUD

RSR.HUD_EMERALDS_COORDS = {
	[EMERALD1] = {x = 0, y = -11},
	[EMERALD2] = {x = 9, y = -5},
	[EMERALD3] = {x = 9, y = 5},
	[EMERALD4] = {x = 0, y = 11},
	[EMERALD5] = {x = -9, y = 5},
	[EMERALD6] = {x = -9, y = -5},
	[EMERALD7] = {x = 0, y = 0},
}

--- Draws the player's emeralds to the HUD.
---@param v videolib
---@param player player_t
RSR.HUDEmeralds = function(v, player)
	if not RSR.GamemodeActive() then return end
	if not (v and Valid(player) and player.rsrinfo) then return end

	-- Use an alternate HUD if altfires are disabled in the map or gamemode
	if not RSR.PlayersCanUseAltfires() then
		local vFlags = V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_HUDTRANS|V_PERPLAYER
		for i = 1, 7 do
			local curEmerald = 1<<(i - 1)
			if RSR.PlayerHasEmerald(player, curEmerald) then
				v.draw(
					23 + RSR.HUD_EMERALDS_COORDS[curEmerald].x,
					146 + RSR.HUD_EMERALDS_COORDS[curEmerald].y,
					v.cachePatch("TEMER"..i),
					vFlags
				)
			end
			-- workX = $+8
		end
		return
	end

	local workX = 96
	local workY = 183
	local vFlags = V_SNAPTOBOTTOM|V_HUDTRANS|V_PERPLAYER
	for i = 1, 7 do -- powerstones
		workY = 183
		if RSR.PlayerHasEmerald(player, 1<<(i - 1)) then
			for index, weapon in ipairs(RSR.CLASS_TO_WEAPON[i]) do
				-- Don't count power weapons (rail ring)
				if RSR.WEAPON_INFO[weapon] and RSR.WEAPON_INFO[weapon].powerweapon
				and not player.rsrinfo.ammo[RSR.WEAPON_INFO[weapon].ammotype] then
					continue
				end
				workY = $ - 18
			end
			v.draw(workX, workY, v.cachePatch("TEMER"..i), vFlags)
		end
		workX = $+20
	end
end
