-- Ringslinger Revolution - Libraries

local folder = "rsr/libs"

local dofolder = function(file)
	dofile(folder.."/"..file)
end

dofolder("hooklib.lua") -- Hook Library by Snu (TODO: Remove this since it's not needed anymore)
dofolder("sprkizard_worldtoscreen.lua") -- WorldToScreen by Lunewulff and Skydusk
dofolder("lib_customhud.lua") -- Custom HUD library by TehRealSalt and Skydusk (edited by MIDIMan)

-- TODO: Remove these since they're not needed anymore
hookLib.valuemodes["RSR_WeaponTouchSpecial"] = HL_LASTFUNC
hookLib.valuemodes["RSR_PowerupTouchSpecial"] = HL_LASTFUNC
hookLib.valuemodes["RSR_HealthTouchSpecial"] = HL_LASTFUNC
hookLib.valuemodes["RSR_ArmorTouchSpecial"] = HL_LASTFUNC
