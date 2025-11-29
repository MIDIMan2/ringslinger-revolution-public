--[[
	l_worldtoscreen.lua
	(sprkizard)
	(‎Aug 19, ‎2021, ‏‎22:51:56)
	Desc: WIP

	Usage: TODO
]]


-- Attempt at optimalization by Sky Dusk
-- Edited by MIDIMan to fix first person issues until 2.2.16

local A270 = ANGLE_270
local A90 = ANGLE_90

local FU160 = 160 << FRACBITS
local FU100 = 100 << FRACBITS

local fDiv = FixedDiv
local fMul = FixedMul

local tToAngle2 = R_PointToAngle2
local tToDist2 = R_PointToDist2
local tang = tan
local cose = cos

---@class projectedObj
---@field x 		number|fixed_t
---@field y 		number|fixed_t
---@field scale 	number|fixed_t
---@field onscreen 	boolean

-- Returns info that can be used to render info on the hud relative to an in-level object
---@param vis 		any Anything that has x, y, z coordinates + angle and aiming angles (horizontal and vertical) Can be either the display player's player object, or the global variable `camera` to get the local camera position instead.
---@param target 	any Anything that has x, y, z coordinates
---@return projectedObj
local function R_WorldToScreen2(vis, target)
	-- Getting diffenential angle between camera and angle between camera and object
	local sx = vis.angle - tToAngle2(vis.x, vis.y, target.x, target.y)
	-- Get the h distance from the target
	local hdist = tToDist2(vis.x, vis.y, target.x, target.y)
	-- Visibility check
	local visible = (sx < A90 or sx > A270)

	return {
		x = visible and 160*tang(sx) + FU160 or sx,
		y = FU100 + 160*(tang(vis.aiming) - fDiv(target.z-vis.z, 1+fMul(hdist, cose(sx)))),

		scale = fDiv(FU160, hdist),
		onscreen = visible
	}
end

-- TODO: Replace this with the original function when 2.2.16 comes out
local function R_World2Screen3FPS(v, player, cam, point, reverse)
	local BASEVIDWIDTH = BASEVIDWIDTH or 320
	local BASEVIDHEIGHT = BASEVIDHEIGHT or 200

	local viewpointAngle, viewpointAiming, viewpointRoll

	local screenWidth, screenHeight
	local screenHalfW, screenHalfH

	local baseFov = 90*FRACUNIT
	local fovDiff, fov, fovTangent, fg

	local h, da, dp

	local cameraNum = displayplayer and 0 or secondarydisplayplayer and 1
	local viewangle = cam.angle
	local viewx, viewy = cam.x, cam.y
	local viewz = cam.z
	if not cam.chase and player.realmo and player.realmo.valid then
		viewangle = player.realmo.angle
		viewx, viewy = player.realmo.x, player.realmo.y
		viewz = player.viewz
	end
	local result = {}

	result.x = 0
	result.y = 0
	result.scale = FRACUNIT
	result.onScreen = false

	if reverse then
		viewpointAngle = viewangle + ANGLE_180
		viewpointAiming = InvAngle(player.aiming)
		viewpointRoll = player.viewrollangle
	else
		viewpointAngle = viewangle
		viewpointAiming = cam.chase and cam.aiming or player.aiming
		viewpointRoll = InvAngle(player.viewrollangle)
	end
	local vdupx = v.dupx()
	local vdupy = v.dupy()
	screenWidth = v.width()/vdupx
	screenHeight = v.height()/vdupy

	if splitscreen then
		screenHeight = $>>1
	end

	screenHalfW = (screenWidth >> 1) << FRACBITS
	screenHalfH = (screenHeight >> 1) << FRACBITS

	fovDiff = CV_FindVar("fov").value - baseFov
	fov = ((baseFov - fovDiff) / 2) - (player.fovadd / 2)
	fovTangent = tan(FixedAngle(fov))

	if splitscreen then
		-- TODO: Merge this with the MRCE version when I figure out the exact fovTangent value to use
		if CV_FindVar("renderer").value == 2 then
			fovTangent = 3*fovTangent/5 -- Close enough
		else
			fovTangent = 10*fovTangent/17
		end
	end

	fg = (screenWidth >> 1) * fovTangent

	h = R_PointToDist2(point.x, point.y, viewx, viewy)
	da = viewpointAngle - R_PointToAngle2(viewx, viewy, point.x, point.y)
	dp = viewpointAiming - R_PointToAngle2(0, 0, h, viewz)

	if reverse then
		da = -$
	end

	// Set results relative to top left!
	result.x = FixedMul(tan(da), fg)
	result.y = FixedMul((tan(viewpointAiming) - FixedDiv((point.z - viewz), 1 + FixedMul(cos(da), h))), fg)

	result.angle = da
	result.pitch = dp
	result.fov = fg

	// Rotate for screen roll...
	if viewpointRoll then
		local tempx = result.x
		result.x = FixedMul(cos(viewpointRoll), tempx) - FixedMul(sin(viewpointRoll), result.y)
		result.y = FixedMul(sin(viewpointRoll), tempx) + FixedMul(cos(viewpointRoll), result.y)
	end

	// Flipped screen?
	if player.pflags & PF_FLIPCAM then
		result.x = -$
	end

	// Center results.
	result.x = ($)+screenHalfW
	result.y = $+screenHalfH

	result.scale = FixedDiv(screenHalfW, h+1)

	result.onScreen = (not ((abs(da) > ANG60) or (abs(viewpointAiming - R_PointToAngle2(0, 0, h, (viewz - point.z))) > ANGLE_45)))
	--print(result.onScreen)

	// Cheap dirty hacks for some split-screen related cases
	if (result.x < 0 or result.x > (screenWidth << FRACBITS)) then
		result.onScreen = false
	end
	if (result.y < 0 or result.y > (screenHeight << FRACBITS)) then
		result.onScreen = false
	end

	// adjust to non-green-resolution screen coordinates
	result.x = $-((v.width()/vdupx) - BASEVIDWIDTH)<<(FRACBITS-1)
	result.y = $-((v.height()/vdupy) - BASEVIDHEIGHT)<<(FRACBITS-1)
	local xdiv = v.width() / 2

	return result
end

rawset(_G, "R_WorldToScreen2", R_WorldToScreen2)
rawset(_G, "R_World2Screen3FPS", R_World2Screen3FPS)
