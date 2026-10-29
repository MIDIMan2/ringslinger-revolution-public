-- Ringslinger Revolution - Waves HUD

--- Draws an enemy counter in "Waves" stages to the HUD.
---@param v videolib
RSR.HUDWavesEnemyCount = function(v)
	if not v then return end
	if not RSR.WavesGamemodeActive() then return end

	v.draw(4, 17, v.cachePatch("RSREGGM"), V_SNAPTOLEFT|V_SNAPTOTOP|V_HUDTRANS|V_PERPLAYER)
	v.drawNum(64, 19, #RSR.WAVE_ENEMIES, V_SNAPTOLEFT|V_SNAPTOTOP|V_HUDTRANS|V_PERPLAYER)
end

--- Draws an enemy radar to the HUD.
---@param v videolib
---@param player player_t
---@param thiscam camera_t
RSR.HUDWavesEnemyRadar = function(v, player, thiscam)
	if not v then return end
	if not RSR.WavesGamemodeActive() then return end
	if not Valid(player) and Valid(player.realmo) then return end

	-- Display an enemy radar to make enemies easier to find in large maps
	if #RSR.WAVE_ENEMIES then
		for _, enemy in ipairs(RSR.WAVE_ENEMIES) do
			if not Valid(enemy) then continue end
			RSR.HUDRadarTarget(v, player, thiscam, "RSREGGM", enemy, 8*FRACUNIT)
		end
	end
end

--- Draws the wave text for "Waves" stages to the HUD.
---@param v videolib
RSR.HUDWaves = function(v)
	if not v then return end
	if not RSR.WavesGamemodeActive() then return end

	if RSR.WAVE_HUDTIMER <= TICRATE/3 then return end

	local offsetX = 0
	if RSR.WAVE_HUDTIMER > RSR.WAVE_HUDTIMER_MAX - (2*TICRATE/3) then
		offsetX = 384*(FRACUNIT - ease.outback(FixedDiv(RSR.WAVE_HUDTIMER_MAX - RSR.WAVE_HUDTIMER, 2*TICRATE/3)))
	elseif RSR.WAVE_HUDTIMER > TICRATE/3 and RSR.WAVE_HUDTIMER <= TICRATE then
		offsetX = -384*(FRACUNIT - ease.outback(FixedDiv(RSR.WAVE_HUDTIMER - TICRATE/3, 2*TICRATE/3)))
	end

	local waveString = ""
	if RSR.WAVE_OVER then
		waveString = "Stage Over..."
	elseif RSR.WAVE_ENEMYCOUNT then
		waveString = "Wave "..RSR.WAVE_NUM.." Start"
	elseif RSR.WAVE_NUM <= RSR.WAVE_NUM_MAX then
		waveString = "Wave "..RSR.WAVE_NUM.." Complete!"
	else
		waveString = "Stage Complete!"
	end

	v.drawLevelTitle(160 - v.levelTitleWidth(waveString)/2 + offsetX/FRACUNIT, 92, waveString, V_PERPLAYER)
end
