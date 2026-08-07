-- Ringslinger Revolution - Screen Effects HUD

--- Draws screen effects based on the player's powerups.
---@param v videolib
---@param player player_t
RSR.HUDEffects = function(v, player)
    if not RSR.CV_ScreenEffects.value then return end -- Don't display the screen effects if they're turned off
    if not RSR.GamemodeActive() then return end
	if not (v and Valid(player) and player.rsrinfo) then return end

    -- Speed lines for the "Super Sneakers" powerup
    if (RSR.CV_ScreenEffects.value & 1) and RSR.HasPowerup(player, RSR.POWERUP_SPEED) then
		local scale = FixedDiv(v.height(), 200)
		local xOffset = min(0, (v.width()*FRACUNIT - 320*scale)/2) -- Make sure the graphics don't overlap each other, but also don't display a gap from the edge of the screen on non-green resolutions
        local vFlags = V_PERPLAYER|V_NOSCALESTART|V_NOSCALEPATCH|V_ADD|V_HUDTRANSHALF
		local frame = ((leveltime/3) % 4)
		v.drawScaled(xOffset, 0, scale, v.cachePatch("RSRSPED"..tostring(frame + 1)), vFlags)
		frame = ($ + 2) % 4 -- Offset the right side's animation frame by 2 so it doesn't look like a mirrored image
		v.drawScaled(v.width()*FRACUNIT - xOffset, 0, scale, v.cachePatch("RSRSPED"..tostring(frame + 1)), vFlags|V_FLIP)
	end

    -- Sparkles for the "Invincibility" powerup
    if (RSR.CV_ScreenEffects.value & 2) and RSR.HasPowerup(player, RSR.POWERUP_INVINCIBILITY) then
        local vFlags = V_SNAPTOBOTTOM|V_PERPLAYER|V_HUDTRANSHALF|V_ADD
        -- Draw 4 sparkles in a zig-zag pattern on each side of the screen, offsetting each sparkle's animation frame by 1
        local frame = 0
        for i = 0, 3 do
            frame = abs(((leveltime/3 + 5 - i) % 8) - 4)
            v.drawScaled(16*FRACUNIT + (i & 1) * 32*FRACUNIT, 184*FRACUNIT - i*32*FRACUNIT, 2*FRACUNIT, v.getSpritePatch(SPR_RSIV, frame), vFlags|V_SNAPTOLEFT)
            v.drawScaled(304*FRACUNIT - (i & 1) * 32*FRACUNIT, 184*FRACUNIT - i*32*FRACUNIT, 2*FRACUNIT, v.getSpritePatch(SPR_RSIV, frame), vFlags|V_SNAPTORIGHT)
        end
    end
end
