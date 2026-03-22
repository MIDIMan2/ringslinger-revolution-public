-- Ringslinger Revolution - Effects HUD

--- Draws effects based on the player's powerups.
---@param v videolib
---@param player player_t
RSR.HUDEffects = function(v, player)
    if not RSR.GamemodeActive() then return end
	if not (v and Valid(player) and player.rsrinfo) then return end

    -- Speed lines for the "Super Sneakers" powerup
    if RSR.HasPowerup(player, RSR.POWERUP_SPEED) then
		local scale = FixedDiv(v.height(), 200)
		local xOffset = min(0, (v.width()*FRACUNIT - 320*scale)/2) -- Make sure the graphics don't overlap each other, but also don't display a gap from the edge of the screen on non-green resolutions
		local frame = ((leveltime/3) % 4)
		v.drawScaled(xOffset, 0, scale, v.cachePatch("RSRSPED"..tostring(frame + 1)), V_PERPLAYER|V_SNAPTOLEFT|V_NOSCALESTART|V_NOSCALEPATCH|V_ADD|V_HUDTRANSHALF)
		frame = ($ + 2) % 4
		v.drawScaled(v.width()*FRACUNIT - xOffset, 0, scale, v.cachePatch("RSRSPED"..tostring(frame + 1)), V_PERPLAYER|V_SNAPTOLEFT|V_NOSCALESTART|V_NOSCALEPATCH|V_FLIP|V_ADD|V_HUDTRANSHALF)
	end

    -- Sparkles for the "Invincibility" powerup (TODO: Replace with a different effect)
    local hasInvin, _, invinTics = RSR.HasPowerup(player, RSR.POWERUP_INVINCIBILITY)
    if hasInvin and (invinTics > 3*TICRATE or (leveltime & 1)) then
        v.drawScaled(16*FRACUNIT, 208*FRACUNIT, 4*FRACUNIT, v.getSpritePatch(SPR_IVSP, leveltime % 32), V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_PERPLAYER)
        v.drawScaled(304*FRACUNIT, 208*FRACUNIT, 4*FRACUNIT, v.getSpritePatch(SPR_IVSP, leveltime % 32), V_SNAPTOBOTTOM|V_SNAPTORIGHT|V_PERPLAYER|V_FLIP)
    end
end
