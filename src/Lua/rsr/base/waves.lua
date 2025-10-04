---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Waves Level Code

-- Main Code

RSR.WAVE_NUM = 0
RSR.WAVE_NUM_MAX = 3
RSR.WAVE_TIMER_MAX = 5*TICRATE
RSR.WAVE_TIMER = RSR.WAVE_TIMER_MAX
RSR.WAVE_SPAWNERS = {}
RSR.WAVE_ENEMIES = {}
RSR.WAVE_ENEMYCOUNT = 0
RSR.WAVE_HUDTIMER = 0
RSR.WAVE_HUDTIMER_MAX = 5*TICRATE
RSR.WAVE_LINEDEFTAGS = {}
RSR.WAVE_OVER = false

RSR.WavesGamemodeActive = function()
	if RSR.GamemodeActive() and (G_IsSpecialStage(gamemap) or (mapheaderinfo[gamemap] and mapheaderinfo[gamemap].rsrwaves)) then return true end
	return false
end

RSR.WavesMapLoad = function()
	if not RSR.WavesGamemodeActive() then return end
	stagefailed = true -- Assume the stage is failed until at least one player completes it
	if mapheaderinfo[gamemap] and mapheaderinfo[gamemap].rsrwavestags then
		for tString in string.gmatch(mapheaderinfo[gamemap].rsrwavestags, "[^,]+") do
			if tonumber(tString) == nil then
				print("\x82WARNING:\x80 Linedef tag couldn't be converted to a number in RSRWaveTags parameter!")
				continue
			end
			table.insert(RSR.WAVE_LINEDEFTAGS, tonumber(tString))
		end
	end
end

RSR.WavesThinkFrame = function()
	if not RSR.WavesGamemodeActive() then return end

	-- Decrement the enemy count if an enemy has died or been removed
	local enemyIndex = 1
	while enemyIndex <= #RSR.WAVE_ENEMIES do
		local enemy = RSR.WAVE_ENEMIES[enemyIndex]
		if not (Valid(enemy) and enemy.health)  then
			RSR.WAVE_ENEMYCOUNT = $-1
			table.remove(RSR.WAVE_ENEMIES, enemyIndex)
			continue
		end
		enemyIndex = $+1
	end

	if RSR.WAVE_HUDTIMER then RSR.WAVE_HUDTIMER = $-1 end

	if RSR.WAVE_NUM > RSR.WAVE_NUM_MAX then return end

	local stillAlive = false
	for player in players.iterate() do
		if not (Valid(player) and Valid(player.mo)) then continue end

		if player.nightstime and player.playerstate ~= PST_DEAD then
			stillAlive = true
		elseif not (player.exiting or (player.pflags & PF_FINISHED)) then
			-- Setting exiting to -1 prevents playersforexit from affecting Waves stages
			player.exiting = -1
			player.pflags = ($ & ~(PF_GLIDING|PF_BOUNCING))|PF_FINISHED
			player.nightstime = 0
			S_StartSound(nil, sfx_s3k66, player)
		end
	end

	if not stillAlive then
		RSR.WAVE_NUM = RSR.WAVE_NUM_MAX + 1
		-- Force everyone to exit the stage upon failure
		for player in players.iterate() do
			if not Valid(player) then continue end
			player.exiting = (14*TICRATE)/5 + 1
		end
		RSR.WAVE_OVER = true
		RSR.WAVE_HUDTIMER = RSR.WAVE_HUDTIMER_MAX
	end

	if RSR.WAVE_TIMER then
		RSR.WAVE_TIMER = $-1
		if not RSR.WAVE_TIMER then
			RSR.WAVE_NUM = $+1
			if RSR.WAVE_LINEDEFTAGS[RSR.WAVE_NUM] then
				P_LinedefExecute(RSR.WAVE_LINEDEFTAGS[RSR.WAVE_NUM])
			end
			if RSR.WAVE_NUM > RSR.WAVE_NUM_MAX and stillAlive then
				for player in players.iterate do
					if not Valid(player) then continue end
					P_DoPlayerExit(player, true)
					if not G_IsSpecialStage(gamemap) then continue end
					if not Valid(player.mo) or player.spectator then continue end

					local emmo = P_SpawnMobjFromMobj(player.mo, 0, 0, player.mo.height, MT_GOTEMERALD)
					if not Valid(emmo) then continue end
					emmo.target = player.mo
					emmo.state = emmo.info.meleestate + RSR.GetNextEmerald()

					if player.powers[pw_carry] ~= CR_NIGHTSMODE then player.powers[pw_carry] = CR_NONE end

					player.mo.tracer = emmo
					emmo.drawonlyforplayer = player
					emmo.dontdrawforviewmobj = player.mo
				end
				if G_IsSpecialStage(gamemap) then
					S_StartSound(nil, sfx_cgot)
					emeralds = $|(1<<RSR.GetNextEmerald())
				else
					S_StartSound(nil, sfx_wvpass)
				end
				-- COM_BufInsertText(server, "cecho STAGE COMPLETE;")
				stagefailed = false
				RSR.WAVE_HUDTIMER = RSR.WAVE_HUDTIMER_MAX
				-- S_FadeOutStopMusic(3*MUSICRATE)
				return
			end
			for num, spawner in ipairs(RSR.WAVE_SPAWNERS) do
				if not Valid(spawner) then continue end
				if not (spawner.threshold & (1<<(RSR.WAVE_NUM - 1))) then continue end
				spawner.reactiontime = 3*TICRATE + (num % 12)*TICRATE/3
				if spawner.type == MT_RSR_ENEMYSPAWNER then RSR.WAVE_ENEMYCOUNT = $+1 end
			end
			S_StartSound(nil, sfx_wvstrt) -- Sound usage heavily inspired by Chaos Mode
			RSR.WAVE_HUDTIMER = RSR.WAVE_HUDTIMER_MAX
			-- COM_BufInsertText(server, "cecho WAVE "..RSR.WAVE_NUM.." START;")
		end
		return
	end

	if not RSR.WAVE_ENEMYCOUNT and RSR.WAVE_NUM <= RSR.WAVE_NUM_MAX then
		S_StartSound(nil, sfx_wvdone)
		-- COM_BufInsertText(server, "cecho WAVE COMPLETE;")
		RSR.WAVE_TIMER = RSR.WAVE_TIMER_MAX
		RSR.WAVE_HUDTIMER = RSR.WAVE_HUDTIMER_MAX
		for _, spawner in ipairs(RSR.WAVE_SPAWNERS) do
			if not Valid(spawner) then continue end
			if spawner.type ~= MT_RSR_ITEMSPAWNER then continue end
			if not (spawner.threshold & (1<<(RSR.WAVE_NUM - 1))) then continue end
			-- Remove the currently spawned item from the wave
			if Valid(spawner.tracer) then
				-- Don't spawn the teleport fog if the pickup has already been picked up
				if spawner.tracer.health or (spawner.tracer.flags & MF_MONITOR) then
					local zOffset = -24*FRACUNIT
					if (spawner.tracer.flags & MF_MONITOR) then zOffset = -8*FRACUNIT end
					RSR.SpawnTeleportFog(spawner.tracer, zOffset)
				end
				P_RemoveMobj(spawner.tracer)
			end
			spawner.reactiontime = 0
		end
	end
end

RSR.WavesMapChange = function()
	RSR.WAVE_NUM = 0
	RSR.WAVE_TIMER = RSR.WAVE_TIMER_MAX
	RSR.WAVE_SPAWNERS = {}
	RSR.WAVE_ENEMIES = {}
	RSR.WAVE_ENEMYCOUNT = 0
	RSR.WAVE_HUDTIMER = 0
	RSR.WAVE_LINEDEFTAGS = {}
	RSR.WAVE_OVER = false
end

-- Spawners

RSR.CheckFreeslot = function(name)
	return pcall(function()
		return constants[name]
	end)
end

-- Enemy Spawner

addHook("MapThingSpawn", function(mo, mthing)
	if not (Valid(mo) and Valid(mthing)) then return end
	if not RSR.WavesGamemodeActive() then
		P_RemoveMobj(mo) -- This could be a REALLY bad idea.
		return
	end

	mo.threshold = mthing.args[0]
	table.insert(RSR.WAVE_SPAWNERS, mo)
end, MT_RSR_ENEMYSPAWNER)

addHook("MobjThinker", function(mo)
	if not RSR.WavesGamemodeActive() then return end
	if not Valid(mo) then return end

	if mo.reactiontime then
		mo.reactiontime = $-1
		if not mo.reactiontime then
			if not RSR.CheckFreeslot(mo.spawnpoint.stringargs[0]) then
				print("\x82WARNING:\x80 Invalid mobj type "..mo.spawnpoint.stringargs[0].."!")
				RSR.WAVE_ENEMYCOUNT = $-1
				return
			end
			local enemy = P_SpawnMobjFromMobj(mo, 0, 0, 0, constants[mo.spawnpoint.stringargs[0]])
			if Valid(enemy) then
				table.insert(RSR.WAVE_ENEMIES, enemy)
				enemy.angle = mo.angle
				RSR.EnemySetBlink(enemy, 3*TICRATE/2)
				RSR.SpawnTeleportFog(enemy, 0, sfx_rsrsp2)
			end
		end
	end
end, MT_RSR_ENEMYSPAWNER)

mobjinfo[MT_RSR_ENEMYSPAWNER] = {
	--$Name Waves Enemy Spawner
	--$Sprite POSSA1
	--$Category Ringslinger Revolution
	--$Arg0 "Wave #s"
	--$Arg0Type 12
	--$Arg0Tooltip "Use this to specify what wave(s) the spawner should work in (out of 3)."
	--$Arg0Enum {1 = "Wave 1"; 2 = "Wave 2"; 4 = "Wave 3";}
	--$StringArg0 "Object type"
	doomednum = 360,
	spawnstate = S_INVISIBLE,
	spawnhealth = 1000,
	radius = 24*FRACUNIT,
	height = 48*FRACUNIT,
	flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_SCENERY|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING
}

-- Item Spawner

RSR.ITEMRESPAWNER_DONTFLOAT = 1
RSR.ITEMRESPAWNER_NOTPANEL = 2
RSR.ITEMRESPAWNER_STRONGBOX = 4
RSR.ITEMRESPAWNER_WEAKBOX = 8
RSR.ITEMRESPAWNER_DONTRESPAWN = 16

addHook("MapThingSpawn", function(mo, mthing)
	if not (Valid(mo) and Valid(mthing)) then return end
	if not RSR.WavesGamemodeActive() then
		P_RemoveMobj(mo) -- This could be a REALLY bad idea.
		return
	end

	mo.movedir = mthing.args[0] -- Store the flags in a variable for easy access
	mo.threshold = mthing.args[1]
	table.insert(RSR.WAVE_SPAWNERS, mo)
end, MT_RSR_ITEMSPAWNER)

addHook("MobjThinker", function(mo)
	if not RSR.WavesGamemodeActive() then return end
	if not Valid(mo) then return end

	if mo.reactiontime then
		mo.reactiontime = $-1
		if not mo.reactiontime then
			if not RSR.CheckFreeslot(mo.spawnpoint.stringargs[0]) then
				print("\x82WARNING:\x80 Invalid mobj type "..mo.spawnpoint.stringargs[0].."!")
				return
			end
			local itemType = constants[mo.spawnpoint.stringargs[0]]
			local itemZ = 0
			if not (mo.movedir & RSR.ITEMRESPAWNER_DONTFLOAT) and not (mobjinfo[itemType].flags & MF_MONITOR) then itemZ = 24*FRACUNIT end
			local item = P_SpawnMobjFromMobj(mo, 0, 0, itemZ, itemType)
			if Valid(item) then
				-- Don't respawn the item if the map creator doesn't want it to respawn
				if (mo.movedir & RSR.ITEMRESPAWNER_DONTRESPAWN) then
					item.flags2 = $|MF2_DONTRESPAWN
				else
					item.flags2 = $ & ~MF2_DONTRESPAWN
				end
				if not (mo.movedir & RSR.ITEMRESPAWNER_NOTPANEL) and item.info.seestate ~= S_NULL then
					item.state = item.info.seestate
					item.rsrIsPanel = true
				end
				if (mobjinfo[itemType].flags & MF_MONITOR) then
					if (mo.movedir & RSR.ITEMRESPAWNER_STRONGBOX) then item.flags2 = $|MF2_STRONGBOX end
					if (mo.movedir & RSR.ITEMRESPAWNER_WEAKBOX) then item.flags2 = $|MF2_AMBUSH end
				end
				mo.tracer = item
				item.rsrSpawner = mo
				RSR.SpawnTeleportFog(item, -itemZ)
			end
		end
	end
end, MT_RSR_ITEMSPAWNER)

mobjinfo[MT_RSR_ITEMSPAWNER] = {
	--$Name Waves Item Spawner
	--$Sprite RSHTC0
	--$Category Ringslinger Revolution
	--$Arg0 "Flags"
	--$Arg0Type 12
	--$Arg0Enum {1 = "Don't float (non-monitors only)"; 2 = "Don't spawn as panel (weapons only)"; 4 = "Strong random (monitors only)"; 8 = "Weak random (monitors only)"; 16 = "Don't respawn";}
	--$Arg1 "Wave #s"
	--$Arg1Type 12
	--$Arg1Tooltip "Use this to specify what wave(s) the spawner should work in (out of 3)."
	--$Arg1Enum {1 = "Wave 1"; 2 = "Wave 2"; 4 = "Wave 3";}
	--$StringArg0 "Object type"
	doomednum = 361,
	spawnstate = S_INVISIBLE,
	spawnhealth = 1000,
	radius = 24*FRACUNIT,
	height = 48*FRACUNIT,
	flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_SCENERY|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING
}
