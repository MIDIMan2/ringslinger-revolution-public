-- Ringslinger Revolution - Toasty Death Code
-- Sourced from MRCE with a bit of help from Xian

-- Initialise the player's color tracking variables.
addHook("PlayerSpawn", function(player)
	if player.spectator then return end
	if player.rsrinfo.preburncolor ~= nil then
		player.rsrinfo.color = player.rsrinfo.preburncolor
		player.rsrinfo.preburncolor = nil
		-- Make sure to allow the player to render again...
		player.mo.flags2 = $ & ~MF2_DONTDRAW
	end
end)

-- Get the game to recognise what a death to fire/exploding damage is.
addHook("MobjDeath", function(player, inflictor, source, dmg)
	if dmg == DMG_FIRE or dmg == DMG_NUKE or RSR.MOBJ_INFO[inflictor.type].explosive or player.rsrinfo.explodeTime > 0 == true then
		player.rsrinfo.preburncolor = player.color
		if player.rsrinfo.explodeTime > 0 then
			player.rsrinfo.explodeOnTimer = true
			player.rsrinfo.haveIExplodedYet = false
		end
	end
end, MT_PLAYER)

-- Reduce the player to ash if they died of fire/exploding damage.
addHook("PlayerThink", function(player)
	if p.spectator then return end
	if player.rsrinfo and player.rsrinfo.valid and player.rsrinfo.preburncolor and player.playerstate == PST_DEAD then
		player.mo.colorized = true
		player.mo.color = SKINCOLOR_CARBON
		-- Only run this if we haven't exploded from rsr_explode yet.
		if not (leveltime % 2) and player.mo.z > player.mo.floorz and not player.rsrinfo.haveIExplodedYet then
			A_BossScream(player.mo, 0, MT_FIREBALLTRAIL)
		end
		-- Only run this if we're rigged to explode from rsr_explode.
		if player.rsrinfo.explodeOnTimer then
			if player.rsrinfo.explodeTime > 0 then
				player.rsrinfo.explodeTime = $ - 1
			else
				-- Only do the explosion once!
				if not player.rsrinfo.haveIExplodedYet then
					P_SpawnMobjFromMobj(player,0,0,0,MT_SONIC3KBOSSEXPLODE)
					S_StartSound(player,sfx_cvxpld)
					player.rsrinfo.haveIExplodedYet = true
				end
				-- Convincingly make it look like the player's ragdoll disappeared.
				P_InstaThrust(player,66,0)
				player.mo.flags2 = $|MF2_DONTDRAW
			end
		end
	end
end)