-- Ringslinger Revolutions - Emeralds HUD

--- Draws the player's emeralds to the HUD.
---@param player player_t
RSR.HUDEmeralds = function(v, player)
	if not RSR.GamemodeActive() then return end
	if not (v and Valid(player) and player.rsrinfo) then return end
	
	local workX = 96
	local workY = 183
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
			v.draw(workX, workY, v.cachePatch("TEMER"..i), V_SNAPTOBOTTOM|V_HUDTRANS|V_PERPLAYER)
		end
		workX = $+20
	end
end
