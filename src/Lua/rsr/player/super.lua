-- Ringslinger Revolution - Super Form Code
-- Massive additional thanks to Sylve for helping out with this particular script

-- Function that causes super players to emit sparks wildly
---@param mo mobj_t
RSR.SuperFlingSpark = function(mo)
	if not Valid(mo) then return end

	if (leveltime % 3 == 0) then -- Don't spawn super sparks every frame
		local spark = P_SpawnMobjFromMobj(mo, 0, 0, FixedDiv(mo.height, mo.scale)/2, MT_SUPERSPARK)
		if Valid(spark) then
			spark.dontdrawforviewmobj = mo -- Prevents super sparks from obscuring the player's view in first-person

			-- Randomize the spark's momentum
			spark.momx = RSR.RandomFixedRange(spark.scale, 5*spark.scale)
			spark.momy = RSR.RandomFixedRange(spark.scale, 5*spark.scale)
			spark.momz = RSR.RandomFixedRange(0, 5*spark.scale)
			if P_RandomChance(FRACUNIT/2) then spark.momx = -$ end
			if P_RandomChance(FRACUNIT/2) then spark.momy = -$ end
			if P_RandomChance(FRACUNIT/2) then spark.momz = -$ end

			-- Make the spark shrink to scale 0 in roughly 1 second
			spark.scalespeed = spark.scale/25
			spark.destscale = 0
			spark.fuse = 25
		end
	end
end

RSR.PlayerSuperTick = function(player)
	if not (Valid(player) and player.rsrinfo) then return end

	if player.powers[pw_super] then
		if player.rsrinfo.hype > 0 then
			RSR.SuperFlingSpark(player.mo)
			player.charflags = $|SF_SUPER
			player.rings = 2
			player.rsrinfo.hype = $-1
		else
			if not (skins[player.skin].flags & SF_SUPER) then player.charflags = $ & ~SF_SUPER end
			player.rings = 0
		end
		return
	end

	if player.rsrinfo.hype >= RSR.TRIGGER_HYPE then
		player.charflags = $|SF_SUPER -- Allow non-super players to go super
		player.rings = 50 -- The player must have 50 rings to turn super
	else
		player.rings = 0
	end

	-- Don't let the player lose their emeralds when detransforming
	if player.playerstate == PST_LIVE and not player.powers[pw_emeralds] and player.rsrinfo.lastemeralds then
		-- for spawner in mobjs.iterate() do
		-- 	if not (Valid(spawner) and spawner.type == MT_EMERALDSPAWN) then return end
		-- 	spawner.threshold = 0 -- Reset the counter so the emeralds don't spawn
		-- end
		player.powers[pw_emeralds] = player.rsrinfo.lastemeralds
	end
end
