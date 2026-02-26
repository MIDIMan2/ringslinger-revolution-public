-- Ringslinger Revolution - Vanilla RS Object Conversion

RSR.MAP_HAS_RSR_MOBJS = false

RSR.RSMOBJ_TO_RSRMOBJ = {
	[MT_RING] = {
		motype = MT_RSR_PICKUP_BASIC,
		canbechained = true,
		ammo = 1
	},
	[MT_REDTEAMRING] = {
		motype = MT_RSR_PICKUP_BASIC,
		canbechained = true,
		ammo = 1
	},
	[MT_BLUETEAMRING] = {
		motype = MT_RSR_PICKUP_BASIC,
		canbechained = true,
		ammo = 1
	},
	[MT_SCATTERRING] = {
		motype = MT_RSR_PICKUP_SCATTER
	},
	[MT_SCATTERPICKUP] = {
		motype = MT_RSR_PICKUP_SCATTER,
		ispanel = true
	},
	[MT_AUTOMATICRING] = {
		motype = MT_RSR_PICKUP_AUTO
	},
	[MT_AUTOPICKUP] = {
		motype = MT_RSR_PICKUP_AUTO,
		ispanel = true
	},
	[MT_BOUNCERING] = {
		motype = MT_RSR_PICKUP_BOUNCE
	},
	[MT_BOUNCEPICKUP] = {
		motype = MT_RSR_PICKUP_BOUNCE,
		ispanel = true
	},
	[MT_GRENADERING] = {
		motype = MT_RSR_PICKUP_GRENADE
	},
	[MT_GRENADEPICKUP] = {
		motype = MT_RSR_PICKUP_GRENADE,
		ispanel = true
	},
	[MT_EXPLOSIONRING] = {
		motype = MT_RSR_PICKUP_BOMB
	},
	[MT_EXPLODEPICKUP] = {
		motype = MT_RSR_PICKUP_BOMB,
		ispanel = true
	},
	[MT_RAILRING] = {
		motype = MT_RSR_PICKUP_HOMING,
		alttype = MT_RSR_PICKUP_RAIL
	},
	[MT_RAILPICKUP] = {
		motype = MT_RSR_PICKUP_HOMING,
		ispanel = true
	},
	[MT_INFINITYRING] = {
		motype = MT_RSR_POWERUP_INFINITY
	},
	[MT_RING_BOX] = {
		motype = {MT_RSR_HEALTH, MT_RSR_ARMOR},
		srmtype = MT_INVULN_BOX,
		zoffset = 24*FRACUNIT,
		floatoffset = true,
		ignorerandommonitor = true,
		dontremove = true
	},
	[MT_RING_REDBOX] = {
		motype = {MT_RSR_HEALTH, MT_RSR_ARMOR},
		floatoffset = true,
		zoffset = 24*FRACUNIT,
		dontremove = true
	},
	[MT_RING_BLUEBOX] = {
		motype = {MT_RSR_HEALTH, MT_RSR_ARMOR},
		floatoffset = true,
		zoffset = 24*FRACUNIT,
		dontremove = true
	},
	[MT_PITY_BOX] = {
		srmtype = MT_1UP_BOX,
		dontremove = true
	},
	[MT_FORCE_BOX] = {
		srmtype = MT_1UP_BOX,
		dontremove = true
	},
	[MT_RECYCLER_BOX] = {
		srmtype = MT_1UP_BOX,
		dontremove = true
	},
	[MT_WHIRLWIND_BOX] = {
		srmtype = MT_INVULN_BOX,
		dontremove = true
	},
	[MT_MIXUP_BOX] = {
		srmtype = MT_INVULN_BOX,
		dontremove = true
	},
	[MT_ELEMENTAL_BOX] = {
		motype = MT_BUBBLEWRAP_BOX,
		srmtype = MT_ATTRACT_BOX,
		dontremove = true
	},
	[MT_FLAMEAURA_BOX] = {
		srmtype = MT_ATTRACT_BOX,
		dontremove = true
	},
	[MT_BUBBLEWRAP_BOX] = {
		srmtype = MT_ARMAGEDDON_BOX,
		dontremove = true
	},
	[MT_THUNDERCOIN_BOX] = {
		srmtype = MT_ARMAGEDDON_BOX,
		dontremove = true
	},
	[MT_SNEAKERS_BOX] = {
		srmtype = MT_ARMAGEDDON_BOX,
		dontremove = true
	},
	[MT_ELEMENTAL_GOLDBOX] = {
		motype = MT_BUBBLEWRAP_GOLDBOX,
		dontremove = true
	}
}

RSR.REMOVE_SHIELDS = {
	[MT_ELEMENTAL_BOX] = {
		motype = MT_PITY_BOX
	},
	[MT_FORCE_BOX] = {
		motype = MT_PITY_BOX
	},
	[MT_WHIRLWIND_BOX] = {
		motype = MT_RING_BOX
	},
	[MT_BUBBLEWRAP_BOX] = {
		motype = MT_RING_BOX
	},
	[MT_FLAMEAURA_BOX] = {
		motype = MT_RING_BOX
	},
	[MT_THUNDERCOIN_BOX] = {
		motype = MT_PITY_BOX
	},
	[MT_ARMAGEDDON_BOX] = {
		motype = MT_1UP_BOX
	},
	[MT_ATTRACT_BOX] = {
		motype = MT_INVULN_BOX
	}
}

--- Converts an item's object type using the given convertTable.
---@param mo mobj_t Object to convert.
---@param convertTable table|nil Table to use for converting object types. Default is RSR.RSMOBJ_TO_RSRMOBJ.
---@param altType string|nil Determines which variable to use for setting the Object type instead of motype, granted it exists.
RSR.ConvertMapItem = function(mo, convertTable, altType)
	if not Valid(mo) then return end
	if not convertTable then convertTable = RSR.RSMOBJ_TO_RSRMOBJ end
	if not convertTable[mo.type] then return end
	local moInfo = convertTable[mo.type]

	-- TODO: Rewrite this to use a custom UDMF field for 2.2.16
	if (mo.info.flags & MF_MONITOR) and (mo.flags2 & (MF2_STRONGBOX|MF2_AMBUSH)) and moInfo.ignorerandommonitor then
		return
	end

	local origDamage = mo.info.damage
	-- TODO: Apparently, there's a bug where the blockmap isn't refreshed when mo.radius is set, but only when mo.scale is set
	-- Set mo.scale here, or wait until 2.2.16 comes out (if it fixes this...)
	local moType = moInfo.motype
	if altType and moInfo[altType] then moType = moInfo[altType] end
	if not moType then return end
	if type(moType) == "table" then
		if Valid(mo.spawnpoint) then
			mo.type = moType[(#mo.spawnpoint % #moType) + 1] -- Choose which type to use based on the mobj's spawnpoint number and the number of entries in the table
		else
			mo.type = moType[1] -- Just use the first type in the table
		end
	else
		mo.type = moType
	end

	-- TODO: Apparently, there's a bug where the blockmap isn't refreshed when mo.radius is set, but only when mo.scale is set
	-- Set mo.scale here, or wait until 2.2.16 comes out (if it fixes this...)
	if Valid(mo.spawnpoint) then
		mo.radius = FixedMul(mo.info.radius, mo.spawnpoint.scale)
		mo.height = FixedMul(mo.info.height, mo.spawnpoint.scale)
	else
		mo.radius = mo.info.radius
		mo.height = mo.info.height
	end
	mo.flags = mo.info.flags
	if moInfo.ispanel and mo.info.seestate ~= S_NULL then
		mo.rsrIsPanel = true
		mo.state = mo.info.seestate
	else
		-- Don't set to spawnstate if the object is a strong random monitor
		if (mo.flags & MF_MONITOR) and (mo.flags2 & MF2_STRONGBOX) and origDamage ~= mo.info.damage then
			if Valid(mo.rsrStrongBoxIcon) then
				if mo.type == MT_1UP_BOX then
					P_RemoveMobj(mo.rsrStrongBoxIcon) -- Don't spawn an icon if the monitor is an Extra Life monitor
				else
					local sprite, frame = SPR_TVMY, C
					if mo.info.damage ~= MT_UNKNOWN then
						sprite = states[mobjinfo[mo.info.damage].spawnstate].sprite
						frame = (states[mobjinfo[mo.info.damage].spawnstate].frame & FF_FRAMEMASK)
					end
					mo.rsrStrongBoxIcon.sprite = sprite
					mo.rsrStrongBoxIcon.frame = frame
				end
			end
		else
			mo.state = mo.info.spawnstate
		end
	end
	if moInfo.ammo ~= nil then mo.rsrAmmoAmount = moInfo.ammo end
	if moInfo.zoffset then
		local zScale = FRACUNIT
		if Valid(mo.spawnpoint) then zScale = mo.spawnpoint.scale end
		if Valid(mo.spawnpoint) and (mo.spawnpoint.options & MTF_OBJECTFLIP) then
			mo.z = $ - FixedMul(moInfo.zoffset, zScale)
		else
			mo.z = $ + FixedMul(moInfo.zoffset, zScale)
		end
	end
	if moInfo.floatoffset then mo.rsrFloatOffset = FixedAngle(P_RandomKey(360)*FRACUNIT) end
	mo.shadowscale = 2*FRACUNIT/3
end

RSR.ConvertItemsMapLoad = function()
	if not (RSR.GamemodeActive() and G_RingSlingerGametype()) then return end
	if RSR.MAP_HAS_RSR_MOBJS then
		for mo in mobjs.iterate() do
			if not Valid(mo) then continue end
			if not RSR.RSMOBJ_TO_RSRMOBJ[mo.type] then continue end
			-- TODO: The second part of this if statement only works in 2.2.16+
			if RSR.RSMOBJ_TO_RSRMOBJ[mo.type].dontremove then
			-- and not (Valid(mo.spawnpoint) and mo.spawnpoint.customargs and mo.spawnpoint.customargs.rsrremove) then
				continue
			end
			mo.flags2 = $|MF2_DONTRESPAWN
			P_RemoveMobj(mo)
		end
		return
	end

	local altQueue = {}
	for mo in mobjs.iterate() do
		if not Valid(mo) then continue end
		if not (gametyperules & GTR_TEAMFLAGS) -- This automatic script can't be properly balanced for CTF autogens
		and RSR.RSMOBJ_TO_RSRMOBJ[mo.type] and RSR.RSMOBJ_TO_RSRMOBJ[mo.type].alttype then -- Track the placement of all Vanilla-Rail pickups for later use.
			table.insert(altQueue, mo) -- Add later objects to the bottom of the queue! (Note from MIDIMan: I found this to make more sense map-wise than the other way around).
			continue
		end
		local typeVar = nil -- Defaults to motype when passed into RSR.ConvertMapItem
		if (mo.flags & MF_MONITOR) and (mo.flags2 & MF2_STRONGBOX) then typeVar = "srmtype" end
		RSR.ConvertMapItem(mo, nil, typeVar)
	end

	-- Find the last object added to the altfire stack and convert it to the alttype Object type; this is so that a singular Rail pickup automatically spawns in a semi-natural position in converted vanilla maps.
	for key, mo in ipairs(altQueue) do
		if key == 1 then
			RSR.ConvertMapItem(mo, nil, "alttype")
		else
			RSR.ConvertMapItem(mo)
		end
	end
end

-- TODO: Merge this into RSR.ConvertItemsMapLoad, eventually.
RSR.RemoveShieldsMapLoad = function()
	if not (RSR.GamemodeActive() and G_RingSlingerGametype() and (not RSR.CV_ShieldEffects.value)) then return end

	if RSR.MAP_HAS_RSR_MOBJS then
		for mo in mobjs.iterate() do
			if not Valid(mo) then continue end
			if not RSR.REMOVE_SHIELDS[mo.type] then continue end
			mo.flags2 = $|MF2_DONTRESPAWN
			mo.fuse = 1 -- Using P_RemoveMobj causes a "next thinker invalidated during iteration" error, so do this instead
		end
		return
	end

	if not RSR.CV_ShieldEffects.value then -- Extra failsafe to make sure this only runs if ShieldEffects are off!
		for mo in mobjs.iterate() do RSR.ConvertMapItem(mo, RSR.REMOVE_SHIELDS) end
	end
end

-- Reset this variable in case there are no RSR mobjs in the map.
RSR.ConvertItemsMapChange = function()
	RSR.MAP_HAS_RSR_MOBJS = false
end