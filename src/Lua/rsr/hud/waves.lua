-- Ringslinger Revolution - Waves HUD

RSR.HUDWavesEnemyCount = function(v)
	if not v then return end
	if not RSR.WavesGamemodeActive() then return end

	v.draw(4, 17, v.cachePatch("RSREGGM"), V_SNAPTOLEFT|V_SNAPTOTOP|V_HUDTRANS|V_PERPLAYER)
	v.drawNum(64, 19, #RSR.WAVE_ENEMIES, V_SNAPTOLEFT|V_SNAPTOTOP|V_HUDTRANS|V_PERPLAYER)
end

RSR.HUDWavesEnemyRadar = function(v, player, thiscam)
	if not v then return end
	if not RSR.WavesGamemodeActive() then return end

	-- Display an enemy radar to make enemies easier to find in large maps
	if #RSR.WAVE_ENEMIES then
		for _, enemy in ipairs(RSR.WAVE_ENEMIES) do
			if not Valid(enemy) then continue end
			-- Shout-outs to Lunewulff, Skydusk, and MRCE for the (original) R_World2Screen3 function
			local result = R_World2Screen3FPS(v, player, thiscam, {x = enemy.x, y = enemy.y, z = enemy.z + enemy.height/2})
			local minScale, maxScale = FRACUNIT/32, FRACUNIT/8
			if result and result.onScreen then
				if not P_CheckSight(player.realmo, enemy) then
					minScale, maxScale = FRACUNIT/16, FRACUNIT/4
				end
				if result.scale > maxScale then continue end
				local transScale = 0
				if result.scale > minScale then
					transScale = FixedDiv(result.scale - minScale, maxScale - minScale)
				end
				-- R_World2Screen3 automatically adjusts for splitscreen, so roughly undo the adjustments
				if splitscreen then result.y = $*2 + (v.height()/v.dupy() - 200)*FRACUNIT/2 end
				local transFlag = FixedMul(9, min(transScale, FRACUNIT))*V_10TRANS
				local eggmanPatch = v.cachePatch("RSREGGM")
				v.drawCropped(
					160*FRACUNIT + (160*FRACUNIT - result.x) - 64*result.scale,
					result.y - 64*result.scale,
					8*max(FRACUNIT/32, result.scale),
					8*max(FRACUNIT/32, result.scale),
					eggmanPatch,
					V_PERPLAYER|transFlag,
					nil,
					0,
					0,
					eggmanPatch.width*FRACUNIT,
					eggmanPatch.height*FRACUNIT
				)
			end
		end
	end
end

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
