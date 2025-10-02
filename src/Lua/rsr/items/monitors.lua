-- Ringslinger Revolution - Monitors
-- Special Thanks to:
-- - orbitalviolet - for coming up with the randomization values and making the "strong random monitor" sprite
-- - Sylve - for allowing the use of Cool RS's "strong random monitor" code
-- - DaJumpJump, Flareguy - for ideas for the strong random monitor

A_RSRStrongBoxThinker = function(actor, var1, var2)
	if not Valid(actor) then return end

	if actor.info.damage ~= MT_1UP_ICON and not Valid(actor.rsrStrongBoxIcon) then
		local icon = P_SpawnMobjFromMobj(actor, 0, 0, 0, MT_OVERLAY)
		if Valid(icon) then
			icon.state = S_RSR_STRONGBOX_ICON
			local sprite, frame = SPR_TVMY, C
			if actor.info.damage ~= MT_UNKNOWN then
				sprite = states[mobjinfo[actor.info.damage].spawnstate].sprite
				frame = (states[mobjinfo[actor.info.damage].spawnstate].frame & FF_FRAMEMASK)
			end
			icon.sprite = sprite
			icon.frame = frame
			icon.target = actor
			actor.rsrStrongBoxIcon = icon
		end
	end

	if actor.state ~= S_RSR_STRONGBOX_FLICKER and actor.type == MT_1UP_BOX then
		A_1upThinker(actor, var1, var2)
		if actor.sprite == SPR_TV1P then
			actor.sprite = SPR_RSMN
			actor.frame = D
		end
	end

	if Valid(actor.rsrStrongBoxIcon) then
		if actor.state == S_RSR_STRONGBOX_FLICKER then
			actor.rsrStrongBoxIcon.flags2 = $|MF2_DONTDRAW
		else
			actor.rsrStrongBoxIcon.flags2 = $ & ~MF2_DONTDRAW
		end
	end
end

states[S_RSR_STRONGBOX] =			{SPR_RSMN,	A,	2,	A_RSRStrongBoxThinker,	0,	0,	S_RSR_STRONGBOX_FLICKER}
states[S_RSR_STRONGBOX_FLICKER] =	{SPR_RSMN,	C,	1,	A_RSRStrongBoxThinker,	1,	0,	S_RSR_STRONGBOX}
states[S_RSR_STRONGBOX_POP1] =		{SPR_RSMN,	A,	4,	nil,					0,	0,	S_RSR_STRONGBOX_POP2}
states[S_RSR_STRONGBOX_POP2] =		{SPR_RSMN,	B,	-1,	nil,					0,	0,	S_NULL}

states[S_RSR_STRONGBOX_ICON] =	{SPR_UNKN,	A,	-1,	nil,	0,	14,	S_RSR_STRONGBOX_ICON}

RSR.MONITOR_TYPES = {}

--- MapThingSpawn hook code for monitors.
---@param mo mobj_t
---@param mthing mapthing_t
RSR.MonitorMapThingSpawn = function(mo, mthing)
	if not RSR.GamemodeActive() then return end
	if not (Valid(mo) and Valid(mthing)) then return end
	if RSR.WavesGamemodeActive() then mo.flags2 = $|MF2_DONTRESPAWN end -- Monitors not spawned by a waves spawner don't respawn
	if not G_RingSlingerGametype() or not ((mthing.options & MTF_OBJECTSPECIAL) or mthing.args[1] == 2) then return end
	mo.state = S_RSR_STRONGBOX
	mo.tics = $+1 -- Just in case the monitor is a 1-up monitor
end

RSR.MonitorMobjThinker = function(mo)
	if not RSR.GamemodeActive() then return end
	if not (Valid(mo) and mo.health > 0 and (mo.flags2 & MF2_STRONGBOX)) then return end
	RSR.ItemFlingSpark(mo, mo.info.height/3, 2*FRACUNIT/3, 30)
end

--- Sets the monitor's fuse upon death.
---@param target mobj_t
---@param source mobj_t
RSR.MonitorMobjDeath = function(target, _, source)
	if not RSR.GamemodeActive() then return end -- Don't run this code outside of RSR.
	if not (Valid(target) and Valid(source)) then return end
	if (target.flags2 & MF2_DONTRESPAWN) then return end
	-- if not Valid(target.rsrSpawner) then return end -- Don't respawn if the monitor doesn't come from a spawner

	if Valid(source.player) then
		if (target.flags & MF_MONITOR) then
			target.target = source
			source.player.numboxes = $+1
			-- Set respawn time
			if not (netgame or multiplayer) or RSR.WavesGamemodeActive() then
				target.fuse = 30*TICRATE + 2
			elseif CV_FindVar("respawnitem").value then
				target.fuse = CV_FindVar("respawnitemtime").value * TICRATE
			end

			-- Make respawn time for random strong monitors 1.5x as long
			if (target.flags2 & MF2_STRONGBOX) then
				target.fuse = FixedMul($, 3*FRACUNIT/2) -- target.fuse * 1.5
			end
		end
	end

	target.state = target.info.deathstate
	return true
end

--- MobjRemoved hook code for monitors.
---@param mo mobj_t
RSR.MonitorMobjRemoved = function(mo)
	if not RSR.GamemodeActive() then return end
	if not (Valid(mo) and Valid(mo.rsrStrongBoxIcon)) then return end
	P_RemoveMobj(mo.rsrStrongBoxIcon)
end

RSR.MONITOR_RANDOMS = {
	{MT_RING_BOX,		0,	8},
	{MT_PITY_BOX,		0,	8},
	{MT_FORCE_BOX,		0,	9},
	{MT_WHIRLWIND_BOX,	0,	9},
	{MT_BUBBLEWRAP_BOX,	0,	9},
	{MT_FLAMEAURA_BOX,	0,	9},
	{MT_RECYCLER_BOX,	0,	2},
	{MT_MIXUP_BOX,		0,	4},
	{MT_SNEAKERS_BOX,	0,	6},
	{MT_1UP_BOX,		4,	0},
	{MT_INVULN_BOX,		2,	0},
	{MT_ARMAGEDDON_BOX,	5,	0},
	{MT_ATTRACT_BOX,	5,	0},
}

--- Gets a random weak or strong monitor Object type based on the monitor Object given.
---@param mo mobj_t
RSR.GetWeakOrStrongMonitor = function(mo)
	if not Valid(mo) then return MT_UNKNOWN end -- This should NEVER happen.

	local spawnchance = {}
	local numchoices = 0

	for _, monitorInfo in ipairs(RSR.MONITOR_RANDOMS) do
		local boxamt = monitorInfo[3]
		if (mo.flags2 & MF2_STRONGBOX) then boxamt = monitorInfo[2] end

		for i = boxamt, 1, -1 do
			spawnchance[numchoices] = monitorInfo[1]
			numchoices = $+1
		end
	end

	return spawnchance[P_RandomKey(numchoices)]
end

--- Lua port of P_MonitorFuseThink using special values for RSR.
---@param mo mobj_t
RSR.MonitorFuseThink = function(mo)
	if not RSR.GamemodeActive() then return end
	if not Valid(mo) then return end

	local newmobj

	if (not G_CoopGametype() or RSR.WavesGamemodeActive()) and mo.info.speed ~= 0
	and (mo.flags2 & (MF2_AMBUSH|MF2_STRONGBOX)) then
		newmobj = P_SpawnMobjFromMobj(mo, 0, 0, 0, RSR.GetWeakOrStrongMonitor(mo))
	else
		newmobj = P_SpawnMobjFromMobj(mo, 0, 0, 0, mo.type)
	end

	if Valid(newmobj) then
		newmobj.flags2 = mo.flags2
		if (newmobj.flags2 & MF2_STRONGBOX) then
			newmobj.state = S_RSR_STRONGBOX
		end
		if Valid(mo.rsrSpawner) then -- Check the item spawners in wave stages
			newmobj.rsrSpawner = mo.rsrSpawner
			mo.rsrSpawner.tracer = newmobj
		end
		RSR.SpawnTeleportFog(newmobj, -8*FRACUNIT)
	end
	P_RemoveMobj(mo)

	return true
end

--- Adds the given Object type to the list of monitors in RSR, automatically applying the necessary hooks to them. Must be called in an AddonLoaded hook.
---@param monitorType mobjtype_t
RSR.AddMonitorType = function(monitorType)
	if RSR.MONITOR_TYPES[monitorType] then
		print("\x82WARNING:\x80 Monitor type "..monitorType.." has already been added to RSR's list!")
		return
	end

	addHook("MapThingSpawn", RSR.MonitorMapThingSpawn, monitorType)
	addHook("MobjThinker", RSR.MonitorMobjThinker, monitorType)
	addHook("MobjDeath", RSR.MonitorMobjDeath, monitorType)
	addHook("MobjFuse", RSR.MonitorFuseThink, monitorType)
	addHook("MobjRemoved", RSR.MonitorMobjRemoved, monitorType)
	RSR.MONITOR_TYPES[monitorType] = true
end

RSR.AddMonitorType(MT_RING_BOX)
RSR.AddMonitorType(MT_PITY_BOX)
RSR.AddMonitorType(MT_ATTRACT_BOX)
RSR.AddMonitorType(MT_FORCE_BOX)
RSR.AddMonitorType(MT_ARMAGEDDON_BOX)
RSR.AddMonitorType(MT_WHIRLWIND_BOX)
RSR.AddMonitorType(MT_ELEMENTAL_BOX)
RSR.AddMonitorType(MT_SNEAKERS_BOX)
RSR.AddMonitorType(MT_INVULN_BOX)
RSR.AddMonitorType(MT_1UP_BOX)
RSR.AddMonitorType(MT_EGGMAN_BOX)
RSR.AddMonitorType(MT_MIXUP_BOX)
RSR.AddMonitorType(MT_MYSTERY_BOX)
RSR.AddMonitorType(MT_GRAVITY_BOX)
RSR.AddMonitorType(MT_RECYCLER_BOX)
RSR.AddMonitorType(MT_SCORE1K_BOX)
RSR.AddMonitorType(MT_SCORE10K_BOX)
RSR.AddMonitorType(MT_FLAMEAURA_BOX)
RSR.AddMonitorType(MT_BUBBLEWRAP_BOX)
RSR.AddMonitorType(MT_THUNDERCOIN_BOX)

-- Developer note: To add your own monitor types to RSR's list, use this function in an AddonLoaded hook.
