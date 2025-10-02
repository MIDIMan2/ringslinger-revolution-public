-- Ringslinger Revolution - PSprite Base Actions

RSR.IsPSpritesValid = function(player)
	return (Valid(player) and player.rsrinfo and player.psprites)
end

--- Checks if the player has ammo.
---@param player player_t
---@param ammoType integer|nil Type of ammo to check for (Default is the current weapon's ammo type).
---@param ammoAmount integer|nil Amount of ammo to check for (Default is 1).
RSR.CheckAmmo = function(player, ammoType, ammoAmount)
	if not (Valid(player) and player.rsrinfo) then return end

	if ammoType == nil then
		if not player.rsrinfo.readyWeapon then return end
		ammoType = RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].ammotype
	end

	if ammoAmount == nil then ammoAmount = 1 end

	if player.rsrinfo.ammo[ammoType] >= ammoAmount then
		return true
	end

	return false
end

--- Draws the given weapon for the player.
---@param player player_t
---@param weapon integer|nil Weapon to draw (RSR.WEAPON_ constant).
---@param force boolean|nil Forces the player to draw the weapon, even if they can't.
RSR.DrawWeapon = function(player, weapon, force)
	if not (Valid(player) and player.rsrinfo) then return end
	if not force and not RSR.CanUseWeapons(player) then return end

	local newstate = "S_NONE"

	local psprite = PSprites.GetPSprite(player, PSprites.PSPR_WEAPON)
	if not psprite then return end

	if weapon == nil then weapon = player.rsrinfo.pendingWeapon end
	newstate = RSR.WEAPON_INFO[weapon].states.draw

	player.rsrinfo.pendingWeapon = -1
	psprite.y = RSR.LOWER_OFFSET

	PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, newstate)
end

--- Fires the player's current weapon.
---@param player player_t
RSR.FireWeapon = function(player)
	if not (RSR.IsPSpritesValid(player) and Valid(player.mo)) then return end

	if not RSR.CheckAmmo(player) then return end
	if RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].states.attack == nil then return end

	PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].states.attack)
	player.drawangle = player.mo.angle
end

--- Fires the player current weapon using its altfire.
---@param player player_t
RSR.FireWeaponAlt = function(player)
	if not (RSR.IsPSpritesValid(player) and Valid(player.mo)) then return end

	local ammoAlt = RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].ammoalt
	if not RSR.CheckAmmo(player, nil, ammoAlt) then
		-- Make sure the player doesn't have infinity and any ammo
		if not (RSR.HasPowerup(player, RSR.POWERUP_INFINITY) and RSR.CheckAmmo(player)) then return end
	end
	if RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].states.attackalt == nil then return end

	PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].states.attackalt)
	player.drawangle = player.mo.angle
	return true
end

--- Checks if the player's pendingWeapon variable is not -1, then draws the weapon.
---@param player player_t
RSR.CheckPendingWeapon = function(player)
	if not (Valid(player) and player.rsrinfo) then return end

	if player.rsrinfo.pendingWeapon ~= -1 then
		local psprite = PSprites.GetPSprite(player, PSprites.PSPR_WEAPON)
		if psprite then
			psprite.y = RSR.LOWER_OFFSET
		end

		player.rsrinfo.readyWeapon = player.rsrinfo.pendingWeapon
		RSR.DrawWeapon(player)
		return true
	end
end

local pspractions = PSprites.ACTIONS

--- Plays a sound from the player. Argument 1 is the sound to play (sfx_ constant).
---@param player player_t
pspractions.A_StartSound = function(player, args)
	if not (Valid(player) and Valid(player.mo)) then return end

	S_StartSound(player.mo, args[1])
end

--- Moves a psprite layer to the coordinates given. Argument 1 is the ID of the psprite to move, Arguments 2 & 3 are the x and y coordinates, respectively, and Argument 4 makes the psprite move relative to its previous position.
---@param player player_t
pspractions.A_LayerOffset = function(player, args)
	if not RSR.IsPSpritesValid(player) then return end

	local psprite = PSprites.GetPSprite(player, args[1])
	if not psprite then return end

	local x = args[2] or 0
	local y = args[3] or 0

	local relative = args[4] or false

	if relative then
		psprite.x = $ + x
		psprite.y = $ + y
		return
	end

	psprite.x = x
	psprite.y = y
end

--- Lowers the player's current weapon and draws their pendingWeapon. Currently unused.
---@param player player_t
pspractions.A_RSRWeaponHolster = function(player, args)
	if not RSR.IsPSpritesValid(player) then return end

	local psprite = PSprites.GetPSprite(player, PSprites.PSPR_WEAPON)
	if not psprite then return end

	psprite.y = $ + RSR.RAISE_SPEED
	if psprite.y < RSR.LOWER_OFFSET then return end

	psprite.y = RSR.LOWER_OFFSET

	player.rsrinfo.readyWeapon = player.rsrinfo.pendingWeapon
	RSR.DrawWeapon(player)
end

--- Raises the player's current weapon.
---@param player player_t
pspractions.A_RSRWeaponDraw = function(player, args)
	if not RSR.IsPSpritesValid(player) then return end

	if RSR.CheckPendingWeapon(player) then return end

	local psprite = PSprites.GetPSprite(player, PSprites.PSPR_WEAPON)
	if not psprite then return end

	psprite.y = $ - RSR.RAISE_SPEED
	if psprite.y > RSR.UPPER_OFFSET then return end

	psprite.y = RSR.UPPER_OFFSET
	PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].states.ready)
end

--- Constantly checks if the player is holding the fire or altfire button, then fires the weapon.
---@param player player_t
pspractions.A_RSRWeaponReady = function(player, args)
	if not RSR.IsPSpritesValid(player) then return end

	local rsrinfo = player.rsrinfo
	if not RSR.CanUseWeapons(player) then
		if rsrinfo.weaponDelayOrig then rsrinfo.weaponDelayOrig = 0 end
		if rsrinfo.weaponDelay then rsrinfo.weaponDelay = 0 end

		if rsrinfo.readyWeapon ~= RSR.WEAPON_NONE then
			local origWeapon = rsrinfo.readyWeapon
			rsrinfo.readyWeapon = RSR.WEAPON_NONE
			RSR.DrawWeapon(player, RSR.WEAPON_NONE, true)
			if origWeapon > RSR.WEAPON_NONE then
				rsrinfo.pendingWeapon = origWeapon
			end
		end
		rsrinfo.useZoom = false
		return
	end
	if RSR.CheckPendingWeapon(player) then
		rsrinfo.useZoom = false
		return
	end

	local weaponInfo = RSR.WEAPON_INFO[player.rsrinfo.readyWeapon]
	if (player.cmd.buttons & BT_FIRENORMAL) and (player.powers[pw_super] or RSR.PlayerHasEmerald(player, weaponInfo.emerald)) then
		if weaponInfo.altzoom and RSR.CheckAmmo(player) then
			rsrinfo.useZoom = true
		else
			if RSR.FireWeaponAlt(player) then return end
			-- Make sure the player has an a altfire attack state and ammo at all before making the sound
			if not (rsrinfo.lastbuttons & BT_FIRENORMAL) and RSR.CheckAmmo(player) and weaponInfo.states.attackalt then
				S_StartSound(nil, sfx_noammo, player)
			end
		end
	elseif weaponInfo.altzoom and rsrinfo.useZoom then
		rsrinfo.useZoom = false
	end

	if (player.cmd.buttons & BT_ATTACK) then
		RSR.FireWeapon(player)
		return
	end
end

--- Shifts the player's weapon psprite's y coordinate based on their weaponDelay.
---@param player player_t
pspractions.A_RSRWeaponRecover = function(player, args)
	if not RSR.IsPSpritesValid(player) then return end

	local psprite = PSprites.GetPSprite(player, PSprites.PSPR_WEAPON)
	if not psprite then return end

	local rsrinfo = player.rsrinfo

	if player.rsrinfo.weaponDelay <= 0 then
		player.rsrinfo.weaponDelay = 0
		player.rsrinfo.weaponDelayOrig = 0
		psprite.y = RSR.UPPER_OFFSET
		PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].states.ready)
		return
	end

	local weaponInfo = RSR.WEAPON_INFO[player.rsrinfo.readyWeapon]
	if (player.cmd.buttons & BT_FIRENORMAL) and weaponInfo.altzoom and RSR.CheckAmmo(player) and (player.powers[pw_super] or RSR.PlayerHasEmerald(player, weaponInfo.emerald)) then
		rsrinfo.useZoom = true
	elseif weaponInfo.altzoom and rsrinfo.useZoom then
		rsrinfo.useZoom = false
	end

	if rsrinfo.weaponDelayOrig == 1 then
		-- Hack to make sure the weapon visibly goes down while firing
		psprite.y = RSR.UPPER_OFFSET + 128 * ease.inquad(rsrinfo.weaponDelay*FRACUNIT/2)
	else
		psprite.y = RSR.UPPER_OFFSET + 128 * ease.inquad(rsrinfo.weaponDelay*FRACUNIT/rsrinfo.weaponDelayOrig)
	end
	player.rsrinfo.weaponDelay = $-1
end

--- Checks if the player has enough ammo for their current weapon. If not, the player will automatically switch to the highest priority weapon in the same class. Argument 1 skips the readyWeapon ammo check.
---@param player player_t
pspractions.A_RSRCheckAmmo = function(player, args)
	if not RSR.IsPSpritesValid(player) then return end

	if not args[1] and RSR.CheckAmmo(player) then return end

	player.rsrinfo.weaponDelayOrig = 0
	player.rsrinfo.weaponDelay = 0

	-- Automatically switch to the lowest priority weapon in the current weapon class (or the next available class) if the player ran out of ammo.
	-- This is currently only used for the rail and basic rings, since they share a class.
	local class = RSR.WEAPON_INFO[player.rsrinfo.readyWeapon].class or 1 -- If class is RSR.WEAPON_NONE switch to 1
	for i = 1, 7 do
		for j = #RSR.CLASS_TO_WEAPON[class], 1, -1 do
			local weapon = RSR.CLASS_TO_WEAPON[class][j]
			if not args[1] and weapon == player.rsrinfo.readyWeapon then continue end -- If argument 1 is true, then skip the readyWeapon check
			if RSR.CheckAmmo(player, RSR.WEAPON_INFO[weapon].ammotype) then
				player.rsrinfo.readyWeapon = weapon
				RSR.DrawWeapon(player, weapon)
				return true
			end
		end
		class = RSR.GetWeaponClass($+1)
	end

	RSR.DrawWeapon(player, RSR.WEAPON_NONE, true)
	return true
end
