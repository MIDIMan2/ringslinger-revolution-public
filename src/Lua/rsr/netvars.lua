-- Ringslinger Revolution - NetVars

addHook("NetVars", function(network)
	RSR.ENEMY_THINKERS = network($)
	-- PSprites.STATES = network($) -- TODO: Removing this may not actually cause netsync issues at all...
	RSR.CURRENT_BOSS = network($)
	RSR.WAVE_NUM = network($)
	RSR.WAVE_TIMER = network($)
	RSR.WAVE_SPAWNERS = network($)
	RSR.WAVE_ENEMIES = network($)
	RSR.WAVE_ENEMYCOUNT = network($)
	RSR.WAVE_LINEDEFTAGS = network($)
	RSR.WAVE_OVER = network($)
	RSR.MAP_HAS_RSR_MOBJS = network($)
end)
