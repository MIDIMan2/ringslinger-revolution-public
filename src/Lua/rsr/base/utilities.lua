-- Ringslinger Revolution - Utility Functions

if not Valid then
	--- Returns true if the given userdata exists and is valid
	---@param thing mobj_t|player_t|skin_t|mapthing_t|sector_t|subsector_t|line_t|side_t|vertex_t|ffloor_t|pslope_t|polyobj_t|taglist_t|patch_t|nil
	rawset(_G, "Valid", function(thing)
		return (thing and thing.valid)
	end)
end

-- Special thanks to amperbee for this function
if not P_ClosestPointOnLineBound then
	--- Version of P_ClosestPointOnLine that restricts the X and Y coordinates to be within the line.
	---@param x fixed_t
	---@param y fixed_t
	---@param line line_t
	rawset(_G, "P_ClosestPointOnLineBound", function(x, y, line)
		local px,py = P_ClosestPointOnLine(x, y, line) -- not bound
		local v1,v2 = line.v1,line.v2 -- get line vertexes

		-- get the lowest and the highest values for each axis
		local xL,xH = min(v1.x, v2.x),max(v1.x, v2.x)
		local yL,yH = min(v1.y, v2.y),max(v1.y, v2.y)

		-- ensure that the returned variables can not exceed these bounds
		-- if H is HIGH, and L is LOW, and $ is our value:
		-- min(H, $) will return H if $ > H, or $ otherwise
		-- max(L, $) will return L if $ < L, or $ otherwise
		px = min(xH, max(xL, $))
		py = min(yH, max(yL, $))

		-- return that
		return px,py
	end)
end

-- Used to be P_RandomFixedRange, changed when I found out this is already a function in other mods...

--- Returns a random fixed-point number between a and b.
---@param a fixed_t|integer
---@param b fixed_t|integer
RSR.RandomFixedRange = function(a, b)
	local diff = b - a
	local result = FixedMul(diff, P_RandomFixed()) + a
	return result
end

RSR.DeepCopy = function(table)
	local newTable = {}
	for k, v in ipairs(table) do
		if type(v) == "table" then
			newTable[k] = RSR.DeepCopy(v)
			continue
		end

		newTable[k] = v
	end
	return newTable
end

--- Returns a new angle inbetween angle and destAngle using maxTurn. Based off of Snap the Sentinel v3.1's code.
---@param angle angle_t Initial angle (Default is 0).
---@param destAngle angle_t Destination angle (Default is 0).
---@param maxTurn angle_t|fixed_t|nil Maximum turning angle (Default is ANGLE_22h).
RSR.AngleTowardsAngle = function(angle, destAngle, maxTurn)
	angle = $ or 0
	destAngle = $ or 0
	if maxTurn == nil then maxTurn = ANGLE_22h end
	maxTurn = AngleFixed($)
	if maxTurn > 180*FRACUNIT then
		maxTurn = $ - 360*FRACUNIT
	end

	local delta = AngleFixed(angle - destAngle)
	if delta > 180*FRACUNIT then
		delta = $ - 360*FRACUNIT
	end

	if maxTurn < abs(delta) then
		if delta > 0 then
			angle = $ - FixedAngle(maxTurn)
		else
			angle = $ + FixedAngle(maxTurn)
		end
	else
		angle = destAngle
	end

	return angle
end

--- Moves a missile in the direction of the given angle and slope/pitch
---@param missile mobj_t
---@param angle angle_t
---@param slope angle_t
---@param speed fixed_t|nil
RSR.MoveMissile = function(missile, angle, slope, speed)
	if not Valid(missile) then return end
	if not speed then speed = missile.info.speed end
	missile.angle = angle

	-- Missile can't move if it has 0 speed
	if not speed then return end
	missile.momx = P_ReturnThrustX(missile, angle, FixedMul(missile.scale, speed))
	missile.momy = P_ReturnThrustY(missile, angle, FixedMul(missile.scale, speed))

	if slope then
		missile.momx = FixedMul($, cos(slope))
		missile.momy = FixedMul($, cos(slope))

		P_SetObjectMomZ(missile, FixedMul(speed, P_MobjFlip(missile)*sin(slope)))
	end
end

--- Changes the missile's color to match the player's team color, unless the gametype does not have teams
---@param missile mobj_t
---@param player player_t
RSR.ColorTeamMissile = function(missile, player)
	if not (Valid(missile) and Valid(player)) then return end
	if not G_GametypeHasTeams() then return end

	if player.ctfteam == 2 then
		missile.translation = "RSRTeamBlue"
	elseif player.ctfteam == 1 then
		missile.translation = "RSRTeamRed"
	end
end

--- Reflects a missile given the old and new one.
---@param source mobj_t
---@param oldMissile mobj_t
---@param newMissile mobj_t
RSR.ReflectMissile = function(source, oldMissile, newMissile)
	if not (Valid(source) and Valid(oldMissile) and Valid(newMissile)) then return nil end

	newMissile.rsrForceReflected = true
	P_SetOrigin(newMissile, oldMissile.x, oldMissile.y, oldMissile.z)
	newMissile.scale = oldMissile.scale
	newMissile.momx = -oldMissile.momx
	newMissile.momy = -oldMissile.momy
	newMissile.momz = -oldMissile.momz
	newMissile.angle = oldMissile.angle + ANGLE_180
	newMissile.pitch = InvAngle(oldMissile.pitch)
	-- Angle and pitch are already handled in SpawnPlayerMissile and SpawnRailRing
	if Valid(oldMissile.target) and (Valid(oldMissile.tracer) and oldMissile.tracer ~= oldMissile.target) then
		oldMissile.tracer = oldMissile.target
	end
	newMissile.color = oldMissile.color
	newMissile.colorized = oldMissile.colorized
	newMissile.translation = oldMissile.translation
	newMissile.rsrProjectile = oldMissile.rsrProjectile
	newMissile.rsrDamage = oldMissile.rsrDamage
	newMissile.rsrRealDamage = oldMissile.rsrRealDamage
	newMissile.rsrOrigScale = oldMissile.rsrOrigScale

	-- Fixes a bug where the killfeed uses the placeholder Eggman icon
	-- if a player with a Force Shield was killed
	if Valid(source.player) and source.player.rsrinfo and source.player.rsrinfo.health <= 0 then
		source.player.rsrinfo.forceInflictorType = oldMissile.type
		-- This line makes no sense in the context of this if-statement, so it has been commented out
-- 		target.player.rsrinfo.forceInflictorReflected = missile.rsrForceReflected
	end

	-- Don't let rail rings pierce through Force Shield players
	oldMissile.rsrRailCantPierce = true

	return newMissile
end

--- Spawns a missile Object at the value of its Speed Object type property, assuming source is a player. Automatically sets rsrProjectile to true for the spawned missile.
---@param source mobj_t Source of the spawned missile. Assumed to be a player.
---@param missileType mobjtype_t Object type of the spawned missile.
---@param angle angle_t|nil Angle of the spawned missile.
---@param slope angle_t|nil Pitch of the spawned missile.
---@param reflected mobj_t|nil If set to an Object, this makes the spawned missile act as a reflected version using this Object's properties.
---@param speed fixed_t|integer|nil Sets the speed of the missile (default is missileType's Speed property).
---@param sound integer|nil Determines what sound to use for the spawned missile (uses sfx_* constants).
RSR.SpawnPlayerMissile = function(source, missileType, angle, slope, reflected, speed, sound)
	if not Valid(source) then return end
	missileType = $ or MT_JETTBULLET
	angle = $ or source.angle
	slope = $ or 0

	local spawnHeight = 41*FixedDiv(source.height, source.scale)/48 - (mobjinfo[missileType].height/2)
	local missile = P_SpawnMobjFromMobj(source, 0, 0, spawnHeight, missileType)
	if not Valid(missile) then return end
	if not sound and missile.info.seesound then sound = missile.info.seesound end
	if sound then S_StartSound(source, sound) end

	missile.target = source
	if Valid(reflected) then
		RSR.ReflectMissile(source, reflected, missile)
		if not Valid(missile) then return end
		angle = missile.angle
		slope = missile.pitch
	else
		RSR.ColorTeamMissile(missile, source.player)
		missile.angle = angle
		missile.pitch = slope
	end
	missile.rsrProjectile = true
	if not speed then speed = missile.info.speed end

	-- Move the projectile if it's being blocked by a wall beside or behind the player
	missile.flags = $ & ~MF_MISSILE -- Don't collide with objects
	if not P_TryMove(missile, missile.x, missile.y, true) then
		local moveRadius = FixedMul(missile.radius, 8*FRACUNIT/5)
		for i = 0, 4 do
			local checkAngle = 0
			if i == 1 then
				checkAngle = ANGLE_45
			elseif i == 2 then
				checkAngle = ANGLE_90
			elseif i == 3 then
				checkAngle = -ANGLE_45
			elseif i == 4 then
				checkAngle = -ANGLE_90
			end

			if P_TryMove(
				missile,
				missile.x + P_ReturnThrustX(nil, missile.angle + checkAngle, moveRadius),
				missile.y + P_ReturnThrustY(nil, missile.angle + checkAngle, moveRadius),
				true
			) then
				break
			end
		end
	end
	if (missile.info.flags & MF_MISSILE) then missile.flags = $|MF_MISSILE end -- Reapply the MF_MISSILE flag if it had one before the check
	RSR.MoveMissile(missile, angle, slope, speed)

	if not Valid(missile) then return end
	if not speed then return missile end

	-- Make sure the player can't outrun their projectiles
	-- Based off of Snap the Sentinel v3.1's code
	local missileSpeed = FixedMul(speed, missile.scale)
	local angleOffset = source.angle - R_PointToAngle2(0, 0, source.momx, source.momy)

	local fracOffset = AngleFixed(angleOffset)
	if fracOffset > 180*FRACUNIT then fracOffset = $ - 360*FRACUNIT end

	if fracOffset > -90*FRACUNIT and fracOffset < 90*FRACUNIT then
		local sourceSpeed = FixedMul(
			FixedHypot(FixedHypot(source.momx, source.momy), source.momz),
			abs(cos(angleOffset))
		)
		local speedScale = FixedDiv(sourceSpeed + missileSpeed, missileSpeed)
		missile.momx = FixedMul($, speedScale)
		missile.momy = FixedMul($, speedScale)
		missile.momz = FixedMul($, speedScale)
	end

	return missile
end

--- Spawns a reflected missile from the player.
---@param source mobj_t
---@param missile mobj_t
RSR.SpawnReflectedMissile = function(source, missile)
	if not (Valid(source) and Valid(missile)) then return end

	if not missile.rsrForceReflected then
		if missile.rsrProjectile then
			if RSR.MOBJ_INFO[missile.type] and RSR.MOBJ_INFO[missile.type].railring then
				RSR.SpawnRailRing(source, missile.angle, missile.pitch, missile)
			else
				RSR.SpawnPlayerMissile(source, missile.type, missile.angle, missile.pitch, missile)
			end
		else
			local newMissile = P_SpawnPlayerMissile(source, missile.type, missile.flags2)
			if Valid(newMissile) then
				newMissile.angle = missile.angle
				newMissile.pitch = missile.pitch
			end
			RSR.ReflectMissile(source, missile, newMissile)
		end
	end
end

--- Checks if friendlyfire is on or not.
---@return boolean
RSR.CheckFriendlyFire = function()
	if CV_FindVar("friendlyfire").value or (gametyperules & GTR_FRIENDLYFIRE) then return true end
	return false
end

--- Returns true if the players given are teammates.
---@param player player_t
---@param player2 player_t
RSR.PlayersAreTeammates = function(player, player2)
	if not (Valid(player) and Valid(player2)) then return end

	-- If the gametype is a co-op gametype, they are teammates
	if (gametyperules & GTR_FRIENDLY) then return true end
	-- If the gametype uses teams and both players have an equal ctfteam value, they are teammates
	if (gametyperules & GTR_TEAMS) and player.ctfteam == player2.ctfteam then return true end
	-- If the gametype is Tag (or H&S) and both players are IT (or not IT), they are teammates
	if G_TagGametype() and (player.pflags & PF_TAGIT) == (player2.pflags & PF_TAGIT) then return true end

	-- Otherwise, they are NOT teammates
	return false
end

--- Returns true if the player given has the "Purple Debuff".
---@param player player_t
RSR.PlayerHasPurpleDebuff = function(player)
	if not Valid(player) then return false end
	if (gametyperules & GTR_TEAMFLAGS) and player.gotflag then return true end -- Player has a flag in CTF
	if G_TagGametype() and not (player.pflags & PF_TAGIT) then return true end -- Player is a hider in Tag/H&S
	return false
end

--- Port of P_GetNextEmerald since it's not exposed.
RSR.GetNextEmerald = function()
	if gamemap >= sstage_start and gamemap <= sstage_end then return (gamemap - sstage_start) end
	if gamemap >= smpstage_start and gamemap <= smpstage_end then return (gamemap - smpstage_start) end
	return 0
end

--- Returns true if the player has the given emerald.
---@param player player_t
---@param emerald integer Emerald to check for (EMERALDN constant, where N is a number from 1 to 7).
RSR.PlayerHasEmerald = function(player, emerald)
	if not emerald then return false end

	-- If the gametype is ringslinger, check pw_emeralds
	if G_RingSlingerGametype() and Valid(player) then
		return (player.powers[pw_emeralds] & emerald) and true
	end

	-- If the map is a Special Stage, check gamemap and sstage_start/smpstage_start
	if G_IsSpecialStage(gamemap) then
		if gamemap >= sstage_start and gamemap <= sstage_end then return (1<<(gamemap - sstage_start + 1) - 1) & emerald end
		if gamemap >= smpstage_start and gamemap <= smpstage_end then return (1<<(gamemap - smpstage_start + 1) - 1) & emerald end
	end

	return (emeralds & emerald)
end

--- Returns a randomized damage value based on rsr_randomdamage.
---@param damage integer
RSR.GetRandomDamage = function(damage)
	if not damage then return 0 end
	-- Randomise damage if RandomDamage is enabled
	if RSR.CV_RandomDamage.value == RSR.CVRANDMG_PARTIAL then
		local baseMod = damage * 3*FRACUNIT/4
		local randomMod = RSR.RandomFixedRange(0, FixedRound(damage * FRACUNIT/2))
		return max(1, FixedRound(baseMod + randomMod)/FRACUNIT)
	elseif RSR.CV_RandomDamage.value == RSR.CVRANDMG_DOOM then
		local doomMod = damage*FRACUNIT/4
		local doomRandom = P_RandomRange(1, 8)*FRACUNIT
		return max(1, FixedRound(FixedMul(doomMod, doomRandom))/FRACUNIT)
	end

	return damage
end

--- Causes a missile to explode when an enemy comes within a certain radius of it.
---@param mo mobj_t
---@param proxDist fixed_t Maximum distance to check for detonation if enemy walks within.
---@param proxCallback function Callback function to run when the radius check succeeds.
RSR.ProximityDetonate = function(mo, proxDist, proxCallback)
	if not Valid(mo) then return end
	if proxDist == nil then proxDist = 96*FRACUNIT end
	if mo.rsrOrigScale then
		proxDist = FixedMul($, mo.rsrOrigScale)
	else
		proxDist = FixedMul($, mo.scale)
	end

	searchBlockmap("objects", function(missile, enemy)
		if not (Valid(missile) and Valid(enemy)) then return end
		if enemy == missile then return end -- Don't detonate because you detected yourself
		if missile.target == enemy then return end -- Don't detonate because you detected your source
		if not (enemy.flags & MF_SHOOTABLE) or (enemy.flags & MF_MONITOR) then return end -- Monitors can't be blown up with splash damage
		if RSR.PlayersAreTeammates(missile.target.player, enemy.player) then return end -- Don't detonate because you detected a teammate

		local rsrInfo = RSR.MOBJ_INFO[enemy.type]
		if rsrInfo and rsrInfo.nothomable then return end -- Don't detonate because you detected a non-homable object (blast executor...)

		local dist = max(0, FixedHypot(FixedHypot(enemy.x - missile.x, enemy.y - missile.y), (enemy.z + enemy.height/2) - (missile.z + missile.height/2)) - enemy.radius)
		if dist > proxDist then return end

		-- Make sure the missile can actually see the target before detonating
		if not P_CheckSight(missile, enemy) then return end

		if proxCallback then proxCallback(missile, enemy) end
		return true -- Stop the blockmap search
	end, mo, mo.x - proxDist, mo.x + proxDist, mo.y - proxDist, mo.y + proxDist)
end
