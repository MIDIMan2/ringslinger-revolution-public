-- Ringslinger Revolution - Base Scripts

local folder = "rsr/base"

local dofolder = function(file)
	dofile(folder.."/"..file)
end

dofolder("globals.lua")
dofolder("utilities.lua")
dofolder("mobj.lua")
dofolder("info.lua")
dofolder("gametypes.lua")
dofolder("convertitems.lua")
dofolder("waves.lua")
