-- Ringslinger Revolution - Item Functions

--- Spawns teleport fog from the given Object.
---@param mo mobj_t
---@param zOffset fixed_t|nil
---@param sound integer|nil
RSR.SpawnTeleportFog = function(mo, zOffset, sound)
	if not Valid(mo) then return end
	if not sound then sound = sfx_rsrsp3 end
	zOffset = $ or 0

	local telefog = P_SpawnMobjFromMobj(mo, 0, 0, zOffset, MT_UNKNOWN)
	if Valid(telefog) then
		S_StartSound(telefog, sound)
		telefog.state = S_RSR_TELEFOG
		telefog.dispoffset = -1
		-- if zOffset then telefog.z = $ + P_MobjFlip(telefog)*FixedMul(zOffset, telefog.scale) end
	end
end

--- MapThingSpawn hook code for items.
---@param mo mobj_t
---@param mthing mapthing_t
RSR.ItemMapThingSpawn = function(mo, mthing)
	if not Valid(mo) then return end
	if not RSR.GamemodeActive() then
		-- Don't spawn in non-RSR gametypes
		P_RemoveMobj(mo)
		return
	end
	if not RSR.MAP_HAS_RSR_MOBJS then RSR.MAP_HAS_RSR_MOBJS = true end
	if not Valid(mthing) then mo.flags2 = $|MF2_DONTRESPAWN end -- Items don't have spawnpoints if they're spawned by custom chain setups.
	if mthing.args[0] then return end

	local flip = (mthing.options & MTF_OBJECTFLIP)
	local offset = FixedMul(24*FRACUNIT, mthing.scale)

	if flip then
		mo.z = $ - offset
	else
		mo.z = $ + offset
	end
end

--- Makes the item "move" up and down in the air.
---@param mo mobj_t
RSR.ItemFloatThinker = function(mo)
	if not Valid(mo) then return end

	mo.spriteyoffset = P_MobjFlip(mo)*8*sin((128*leveltime)<<19 + (mo.rsrFloatOffset or 0))
end

--- MobjSpawn hook code for items.
---@param mo mobj_t
RSR.ItemMobjSpawn = function(mo)
	if not Valid(mo) then return end

	mo.shadowscale = 2*FRACUNIT/3

	if not (netgame or multiplayer) then
		mo.flags2 = $|MF2_DONTRESPAWN
	end
end

--- Sets the item's fuse according to `respawnitemtime` if it is set to respawn.
---@param mo mobj_t
RSR.SetItemFuse = function(mo)
	if not Valid(mo) then return end

	if not (mo.flags2 & MF2_DONTRESPAWN) then
		if RSR.WavesGamemodeActive() then
			mo.fuse = 30*TICRATE + 2
		else
			mo.fuse = (CV_FindVar("respawnitemtime").value or 0)*TICRATE + 2
		end

		-- Make respawn time for power items 1.5x as long
		if RSR.MOBJ_INFO[mo.type] and RSR.MOBJ_INFO[mo.type].poweritem then
			mo.fuse = FixedMul($, 3*FRACUNIT/2) -- mo.fuse * 1.5
		end
	end
end

--- MobjFuse hook code for items.
---@param mo mobj_t
RSR.ItemMobjFuse = function(mo)
	if not Valid(mo) then return end
	if (mo.flags2 & MF2_DONTRESPAWN) then return end

	local itemType = mo.type

	local newItem = P_SpawnMobjFromMobj(mo, 0, 0, 0, itemType)
	if Valid(newItem) then
		newItem.flags2 = mo.flags2
		newItem.spawnpoint = mo.spawnpoint
		if Valid(mo.rsrSpawner) then -- Check the item spawners in wave stages
			newItem.rsrSpawner = mo.tracer
			mo.rsrSpawner.tracer = newItem
		end
		RSR.SpawnTeleportFog(newItem, -24*FRACUNIT)
	end

	P_RemoveMobj(mo)
end

--- Flings a spark from the Object given.
---@param mo mobj_t
---@param zOffset fixed_t|nil Vertical spawn offset of the spark.
---@param sparkScale fixed_t|nil Scale of the spark. Default is FRACUNIT.
---@param sparkTics tic_t|nil Duration of the spark. Default is 25.
RSR.ItemFlingSpark = function(mo, zOffset, sparkScale, sparkTics)
	if not Valid(mo) then return end
	if mo.health <= 0 then return end -- Don't spawn sparks if the item has been collected
	if zOffset == nil then zOffset = mo.info.height/2 end
	if sparkTics == nil then sparkTics = 25 end
	if (leveltime % 3 == 0) then -- Don't spawn super sparks every frame
		local spark = P_SpawnMobjFromMobj(mo, 0, 0, zOffset, MT_SUPERSPARK)
		if Valid(spark) then
			if sparkScale ~= nil then spark.scale = FixedMul($, sparkScale) end

			-- Randomize the spark's momentum
			spark.momx = RSR.RandomFixedRange(spark.scale, 5*spark.scale)
			spark.momy = RSR.RandomFixedRange(spark.scale, 5*spark.scale)
			spark.momz = RSR.RandomFixedRange(0, 5*spark.scale)
			if P_RandomChance(FRACUNIT/2) then spark.momx = -$ end
			if P_RandomChance(FRACUNIT/2) then spark.momy = -$ end
			if P_RandomChance(FRACUNIT/2) then spark.momz = -$ end

			-- Make the spark shrink to scale 0 in roughly 1 second
			spark.scalespeed = spark.scale/sparkTics
			spark.destscale = 0
			spark.tics = sparkTics
		end
	end
end
