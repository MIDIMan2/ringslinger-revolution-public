-- Ringslinger Revolution - Libraries

local folder = "rsr/libs"

local dofolder = function(file)
	dofile(folder.."/"..file)
end

dofolder("sprkizard_worldtoscreen.lua") -- WorldToScreen by Lunewulff and Skydusk
dofolder("lib_customhud.lua") -- Custom HUD library by TehRealSalt and Skydusk (edited by MIDIMan)