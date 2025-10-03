-- Ringslinger Revolution - Base Scripts

local folder = "rsr/base"

local dofolder = function(file)
	dofile(folder.."/"..file)
end

dofolder("globals.lua")
dofolder("hooks.lua")
dofolder("utilities.lua")
dofolder("mobj.lua")
dofolder("mobjinfo.lua")
dofolder("gametypes.lua")
dofolder("convertitems.lua")
dofolder("waves.lua")
