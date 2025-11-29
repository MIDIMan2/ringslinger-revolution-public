-- Ringslinger Revolution - Title Screen HUD

RSR.TITLE_INFO = {
	tics = 16
}

addHook("HUD", function(v)
	if not v then return end

	local scale = FixedDiv(v.height()*FRACUNIT, 200*FRACUNIT)
	local xOffset = (v.width()*FRACUNIT - 320*scale)/2

	v.drawScaled(
		xOffset,
		-FixedMul(200 * ease.inquad(RSR.TITLE_INFO.tics*FRACUNIT/16), scale),
		scale/4,
		v.cachePatch("RSRTITLE"),
		V_NOSCALEPATCH|V_NOSCALESTART
	)

	-- TODO: Figure out why this doesn't work for a split second when quitting to the title screen from a level
-- 	if leveltime < 35 then
-- 		v.fadeScreen(31, 10)
-- 	elseif RSR.TITLE_INFO.tics > 0 then
-- 		v.fadeScreen(0, 10*FixedDiv(RSR.TITLE_INFO.tics, 16)/FRACUNIT)
-- 	end
end, "title")

-- TODO: Make this into a function later...
addHook("MapLoad", function(mapnum)
	if mapnum ~= titlemap then return end

	RSR.TITLE_INFO = {
		tics = 16
	}
end)

-- TODO: Make this into a function later...
addHook("ThinkFrame", function()
	if not titlemapinaction then return end
	if leveltime < 35 then return end

	local titleInfo = RSR.TITLE_INFO

	if titleInfo.tics > 0 then titleInfo.tics = $-1 end
end)
