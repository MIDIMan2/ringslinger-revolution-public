-- Player Sprites Library - Created by MIDIMan
-- Heavily inspired by Doom's Player Sprites HUD system

---@class psprite_t
---@field state pspritestate_t Current state from PSprites.STATES.
---@field sprite string Sprite prefix.
---@field frame string Frame index (A-Z typically, but it can be anything as long as its a single-character string).
---@field frameargs boolean Arguments for the current frame (Currently only handles fullbright sprites).
---@field animframe integer Current string index (used if the frame has more than one character).
---@field x fixed_t X-coordinate of the psprite.
---@field y fixed_t Y-coordinate of the psprite.
---@field tics integer Time until the next state is run.
---@field processPending boolean Determines if the tics timer should go down or not.

---@class pspritestate_t
---@field sprite string
---@field frame string
---@field tics tic_t
---@field action string
---@field args table
---@field nextstate string

if not PSprites then rawset(_G, "PSprites", {}) end

--- Creates an enum with the given prefix and name
---@param id string
PSprites.AddPSpriteID = function(id)
	if not id then
		print("\x82WARNING:\x80 Unable to add psprite with missing id!")
		return
	end

	if PSprites["PSPR_"..id] then
		print("\x82WARNING:\x80 PSprite ID ".."PSPR_"..id.." already exists!")
		return
	end

	-- Make sure the max value exists before adding an enum
	if not PSprites.PSPR_MAX then PSprites.PSPR_MAX = 0 end

	PSprites.PSPR_MAX = $+1
	PSprites["PSPR_"..id] = PSprites.PSPR_MAX
end


-- Store weapon states/animations in a table
if not PSprites.STATES then
	---@type pspritestate_t[]
	PSprites.STATES = {}
end
local psprstates = PSprites.STATES

-- WeaponNull (There should be at least one state already in the weapon table)
psprstates["S_NONE"] =			{nil,	nil,	-1,	nil,				{},	"S_NONE"}
psprstates["S_NONE_READY"] =	{nil,	nil,	1,	"A_RSRWeaponReady",	{},	"S_NONE_READY"}
psprstates["S_NONE_HOLSTER"] =	{nil,	nil,	1,	"A_RSRWeaponHolster",	{},	"S_NONE_HOLSTER"}

-- Store PSprite actions in a table of strings to keep them netsafe
if not PSprites.ACTIONS then
	PSprites.ACTIONS = {}
end
local pspractions = PSprites.ACTIONS

--- Returns a new psprite using default values.
---@return psprite_t
PSprites.PSpriteNew = function()
	return {
		state = psprstates["S_NONE"],
		sprite = nil,
		frame = nil,
		animframe = 0,
		x = 0,
		y = 0,
		tics = -1,
		processPending = true
	}
end

--- Creates a new psprite for the player with a given ID.
---@param player player_t
---@param id integer
PSprites.NewPSprite = function(player, id)
	if not Valid(player) then return end
-- 	if not player.psprites then
-- 		PSprites.PlayerPspritesInit(player)
-- 	end

	player.psprites[id] = PSprites.PSpriteNew()
end

--- Initializes the player's psprites system.
---@param player player_t
PSprites.PlayerPSpritesInit = function(player)
	if not Valid(player) then return end

	player.psprites = {}

	for i = 1, PSprites.PSPR_MAX do
		PSprites.NewPSprite(player, i)
	end
end

--- Gets a psprite from the player using an ID.
---@param player player_t
---@param id integer ID of the psprite (PSPR_ constant).
PSprites.GetPSprite = function(player, id)
	if not (Valid(player) and player.psprites) then return end
	return player.psprites[id]
end

--- Sets the player's psprite's state using the given ID.
---@param player player_t
---@param id integer PSprite ID.
---@param newState string|pspritestate_t State to set the PSprite to (can be a string or a state from PSprites.STATES).
---@param pending boolean|nil
PSprites.SetPSpriteState = function(player, id, newState, pending)
	local psprite = PSprites.GetPSprite(player, id)
	if psprite == nil then return end
	if pending == nil then pending = false end

	-- local stateName = newState
	if type(newState) == "string" then
		if not psprstates[newState] then
			CONS_Printf(player, "\x82WARNING:\x80 State "..tostring(newState).." not found!")
			return
		end

		newState = psprstates[$]
	end

	if newState == nil then
		CONS_Printf(player, "\x82WARNING:\x80 State "..tostring(newState).." not found!")
		return
	end

	psprite.processPending = pending
	if psprite.state ~= newState then psprite.animframe = 0 end

	-- This could result in an endless loop, so change this if necessary
	repeat
		if newState == nil then
			psprite.tics = -1
			break
		end
		psprite.state = newState

		-- Tics
		if newState.tics ~= nil then
			psprite.tics = newState.tics
		elseif newState[3] ~= nil then
			psprite.tics = newState[3]
		else
			psprite.tics = -1
		end

		local sprite

		-- Sprite
		if newState.sprite ~= nil then
			sprite = newState.sprite
		elseif newState[1] ~= nil then
			sprite = newState[1]
		else
			sprite = nil
		end

		-- Don't change the sprite if the state specifies not to
		if sprite ~= "####" then
			psprite.sprite = sprite
		end

		-- Frame
		local weaponframe = "A"

		psprite.frameargs = nil
		if newState.frame then
			if type(newState.frame) == "string" then
				weaponframe = newState.frame
			elseif type(newState.frame) == "table" then
				weaponframe = newState.frame[1]
				psprite.frameargs = newState.frame[2]
			end
		elseif newState[2] then
			if type(newState[2]) == "string" then
				weaponframe = newState[2]
			elseif type(newState[2]) == "table" then
				weaponframe = newState[2][1]
				psprite.frameargs = newState[2][2]
			end
		end

		-- Animation Frame
		if weaponframe:len() > 1 then
			psprite.animframe = $+1

			if psprite.animframe > weaponframe:len() - 1 then
				weaponframe = string.sub($, psprite.animframe, psprite.animframe)
				psprite.animframe = 0
			else
				weaponframe = string.sub($, psprite.animframe, psprite.animframe)
			end
		else
			psprite.animframe = 0
		end

		-- Don't change the animation frame if the state specifies not to
		if weaponframe ~= "#" then
			psprite.frame = weaponframe
		end

		-- Action
		local args = {}

		if newState.args then
			args = newState.args
		elseif newState[5] then
			args = newState[5]
		end

		if newState.action and pspractions[newState.action] then
			pspractions[newState.action](player, args)
		elseif newState[4] and pspractions[newState[4]] then
			pspractions[newState[4]](player, args)
		end

		if psprite.state == psprstates["S_NONE"] then break end

		-- Next State
		if newState.nextstate then
			newState = psprstates[newState.nextstate]
		elseif newState[6] then
			newState = psprstates[newState[6]]
		else
			newState = psprstates["S_NONE"]
		end
	until psprite.tics ~= 0
end

--- Resets the player's psprites to their defaults.
---@param player player_t
PSprites.PlayerPSpritesReset = function(player)
	if not (Valid(player) and player.psprites) then return end

	for _, pspr in ipairs(player.psprites) do
		pspr = PSprites.PSpriteNew()
	end

	PSprites.SetPSpriteState(player, PSprites.PSPR_WEAPON, "S_NONE_READY")
end

--- Runs thinker code for the player's psprite with the given ID.
PSprites.PSpriteTick = function(player, id)
	if not (Valid(player) and player.psprites) then return end

	local psprite = PSprites.GetPSprite(player, id)

	if psprite == nil then
		print("\x82WARNING:\x80 PSprite with ID "..tostring(id).." not found!")
		return
	end

	if not psprite.processPending then return end
	if psprite.tics == -1 then return end

	psprite.tics = $-1
	if not psprite.tics then
		---@type string|pspritestate_t
		local nextState = "S_NONE"

		if psprite.animframe then
			nextState = psprite.state
		else
			if psprite.state.nextstate then
				nextState = psprstates[psprite.state.nextstate]
			elseif psprite.state[6] then
				nextState = psprstates[psprite.state[6]]
			end
		end

		PSprites.SetPSpriteState(player, id, nextState)
	end
end

--- Resets the processPending value for each psprite.
---@param player player_t
PSprites.TickPSpritesBegin = function(player)
	if not (Valid(player) and player.psprites) then return end

	for _, pspr in ipairs(player.psprites) do
		if not pspr then continue end
		pspr.processPending = true
	end
end

--- Runs thinker code for all the player's psprites.
PSprites.TickPSprites = function(player)
	if not (Valid(player) and player.psprites) then return end

	for id, pspr in ipairs(player.psprites) do
		PSprites.PSpriteTick(player, id)
	end
end
