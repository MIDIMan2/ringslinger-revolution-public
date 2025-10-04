-- Ringslinger Rev - Enemy Thinker Table

RSR.ENEMY_THINKERS = {}

-- Reset the thinkers table every map change
RSR.EnemyThinkersMapChange = function(mapnum)
	RSR.ENEMY_THINKERS = {}
end

RSR.EnemyThinkersThinkFrame = function()
	if not RSR.GamemodeActive() then return end -- This hook should only run in RSR

	local key = 1

	while key <= #RSR.ENEMY_THINKERS do
		---@type mobj_t
		local enemy = RSR.ENEMY_THINKERS[key]
		if not (Valid(enemy) and enemy.health > 0) then
			if Valid(enemy) then enemy.flags2 = $ & ~MF2_DONTDRAW end
			table.remove(RSR.ENEMY_THINKERS, key)
			continue
		end

		if enemy.rsrEnemyBlink then
			enemy.flags2 = $ ^^ MF2_DONTDRAW
			enemy.rsrEnemyBlink = $-1

			if enemy.rsrEnemyBlink <= 0 then
				enemy.flags2 = $ & ~MF2_DONTDRAW
				enemy.rsrEnemyBlink = nil
				enemy.rsrIsThinker = nil
				table.remove(RSR.ENEMY_THINKERS, key)
				continue
			end
		else
			enemy.flags2 = $ & ~MF2_DONTDRAW
			enemy.rsrEnemyBlink = nil
			enemy.rsrIsThinker = nil
			table.remove(RSR.ENEMY_THINKERS, key)
			continue
		end

		key = $+1
	end
end
