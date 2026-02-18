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
	[MT_ELEMENTAL_BOX] = {
		motype = MT_BUBBLEWRAP_BOX,
		dontremove = true
	},
	[MT_ELEMENTAL_GOLDBOX] = {
		motype = MT_BUBBLEWRAP_GOLDBOX,
		dontremove = true
	}
}

--- Sets the given Object's info based on its new type.
---@param mo mobj_t
---@param moInfo table
---@param origDamage integer
RSR.ConvertItemsSetMobjInfo = function(mo, moInfo, origDamage)
	if not (Valid(mo) and moInfo) then return end
	if origDamage == nil then origDamage = 0 end

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
				local sprite, frame = SPR_TVMY, C
				if mo.info.damage ~= MT_UNKNOWN and mo.info.damage ~= MT_1UP_ICON then
					sprite = states[mobjinfo[mo.info.damage].spawnstate].sprite
					frame = (states[mobjinfo[mo.info.damage].spawnstate].frame & FF_FRAMEMASK)
				end
				mo.rsrStrongBoxIcon.sprite = sprite
				mo.rsrStrongBoxIcon.frame = frame
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

--- Sets the given Object's type based on the type given.
---@param mo mobj_t
---@param moType mobjtype_t|table
RSR.ConvertItemsSetMobjType = function(mo, moType)
	if not (Valid(mo) and moType) then return end
	if type(moType) == "table" then
		if Valid(mo.spawnpoint) then
			mo.type = moType[(#mo.spawnpoint % #moType) + 1] -- Choose which type to use based on the mobj's spawnpoint number and the number of entries in the table
		else
			mo.type = moType[1] -- Just use the first type in the table
		end
	else
		mo.type = moType
	end
end

RSR.ConvertItemsMapLoad = function()
	if not (RSR.GamemodeActive() and G_RingSlingerGametype()) then return end
	if RSR.GAMETYPE_INFO[gametype] == "Capture The Flag" then return end -- This automatic script can't be properly balanced for CTF autogens
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
		if not RSR.RSMOBJ_TO_RSRMOBJ[mo.type] then continue end
		local moInfo = RSR.RSMOBJ_TO_RSRMOBJ[mo.type]

		-- TODO: Rewrite this to use a custom UDMF field for 2.2.16
		if (mo.info.flags & MF_MONITOR) and (mo.flags2 & (MF2_STRONGBOX|MF2_AMBUSH)) and moInfo.ignorerandommonitor then
			continue
		end

		if moInfo.alttype then -- Track the placement of all Vanilla-Rail pickups for later use.
			table.insert(altQueue, mo) -- Add later objects to the bottom of the queue! (Note from MIDIMan: I found this to make more sense map-wise than the other way around).
			continue
		end
		local origDamage = mo.info.damage
		RSR.ConvertItemsSetMobjType(mo, moInfo.motype)
		RSR.ConvertItemsSetMobjInfo(mo, moInfo, origDamage)
	end

	-- Find the last object added to the altfire stack and convert it to the alttype Object type; this is so that a singular Rail pickup automatically spawns in a semi-natural position in converted vanilla maps.
	for key, mo in ipairs(altQueue) do
		if not (Valid(mo) and RSR.RSMOBJ_TO_RSRMOBJ[mo.type]) then continue end
		local moInfo = RSR.RSMOBJ_TO_RSRMOBJ[mo.type]
		local origDamage = mo.info.damage
		if key == 1 then
			RSR.ConvertItemsSetMobjType(mo, moInfo.alttype)
			RSR.ConvertItemsSetMobjInfo(mo, moInfo, origDamage)
		else
			RSR.ConvertItemsSetMobjType(mo, moInfo.motype)
			RSR.ConvertItemsSetMobjInfo(mo, moInfo, origDamage)
		end
	end
end

-- Reset this variable in case there are no RSR mobjs in the map.
RSR.ConvertItemsMapChange = function()
	RSR.MAP_HAS_RSR_MOBJS = false
end
