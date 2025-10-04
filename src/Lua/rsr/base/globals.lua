-- Ringslinger Revolution - Globals

if not RSR then
	rawset(_G, "RSR", {})
end

RSR.MAX_HEALTH = 100
RSR.MAX_ARMOR = 100
RSR.TRIGGER_HYPE = 1750

RSR.MAX_HEALTH_BONUS = 200
RSR.MAX_ARMOR_BONUS = 200
RSR.MAX_HYPE = 3000

RSR.RSR_GAMETYPES = {}

--- Makes the given gametype use RSR logic.
---@param gameType UINT32
RSR.AddGametype = function(gameType)
	if not gameType then return end
	RSR.RSR_GAMETYPES[gameType] = true
end

--- Returns true if the current map is a Ringslinger Revolution map.
RSR.GamemodeActive = function()
	if not (RSR.RSR_GAMETYPES[gametype] or mapheaderinfo[gamemap].ringslingerrev) then return false end
	return true
end

--- Creates an enum with the given prefix and name
---@param prefix string
---@param name string
---@param startAtZero boolean|nil
RSR.AddEnum = function(prefix, name, startAtZero)
	if not (prefix and name) then
		print("\x82WARNING:\x80 Unable to add enum with missing prefix and/or name!")
		return
	end

	if RSR[prefix.."_"..name] then
		print("\x82WARNING:\x80 Enum "..prefix.."_"..name.." already exists!")
		return
	end

	-- Make sure the max value exists before adding an enum
	if not RSR[prefix.."_MAX"] then RSR[prefix.."_MAX"] = 0 end

	RSR[prefix.."_MAX"] = $+1

	if startAtZero then
		RSR[prefix.."_"..name] = RSR[prefix.."_MAX"] - 1
		return
	end

	RSR[prefix.."_"..name] = RSR[prefix.."_MAX"]
end
