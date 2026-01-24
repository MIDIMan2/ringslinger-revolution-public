-- Ringslinger Revolution - Toasty Death Code
-- Sourced from MRCE with a bit of help from Xian

--- Get the game to recognise what a death to fire/exploding damage is.
---@param player player_t
---@param inflictor mobj_t|nil
---@param damagetype integer|nil
RSR.PlayerToastyDeath = function(player, inflictor, damagetype)
	if not (Valid(player) and player.rsrinfo) then return end
	damagetype = $ or 0
	if damagetype == DMG_FIRE or damagetype == DMG_NUKE
	or (Valid(inflictor) and RSR.MOBJ_INFO[inflictor.type] and RSR.MOBJ_INFO[inflictor.type].explosive) then
		player.rsrinfo.deathFlags = $|RSR.DEATH_GOTBURNT
	end
end

--- Reduce the player to ash if they died of fire/exploding damage.
---@param player player_t
RSR.PlayerToastyTick = function(player)
	if not (Valid(player) and Valid(player.mo) and player.rsrinfo and (player.rsrinfo.deathFlags & RSR.DEATH_GOTBURNT)) then return end

	-- player.mo.colorized = true
	-- player.mo.color = SKINCOLOR_CARBON
	player.mo.translation = "RSRBurnt"
	if (player.rsrinfo.deathFlags & RSR.DEATH_USEDEXPLODECMD) and player.mo.fuse > 3*TICRATE/4 then player.mo.fuse = 3*TICRATE/4 end
	-- Only run this if we haven't exploded from rsr_explode yet.
	if not (leveltime % 2) and player.mo.fuse and (player.mo.z > player.mo.floorz and player.mo.z + player.mo.height < player.mo.ceilingz) and not (player.mo.eflags & MFE_UNDERWATER) then
		A_BossScream(player.mo, 0, MT_FIREBALLTRAIL)
		if not (leveltime % 4) then S_StartSound(player.mo, sfx_s3kc2s) end
	end
end
