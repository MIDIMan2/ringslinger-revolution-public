-- Ringslinger Revolution - init.lua
-- This script is required for loading the mod's Lua scripts in the right order
-- DO NOT REMOVE THIS FILE

local folder = "rsr"
local function dofolder(file)
	dofile(folder.."/"..file)
end

dofolder("freeslots.lua")
dofolder("libs.lua")
dofolder("base.lua")
dofolder("cvars.lua")
dofolder("psprites.lua")
dofolder("items.lua")
dofolder("enemy.lua")
dofolder("weapon.lua")
dofolder("player.lua")
dofolder("hud.lua")
dofolder("hooks.lua")
dofolder("netvars.lua")
