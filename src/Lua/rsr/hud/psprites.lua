-- Ringslinger Revolution - PSprites HUD

--[[
RSR.BLENDMODE_TO_VFLAG = {
	[AST_ADD] = V_ADD,
	[AST_SUBTRACT] = V_SUBTRACT,
	[AST_REVERSESUBTRACT] = V_REVERSESUBTRACT,
	[AST_MODULATE] = V_MODULATE
}
]]

--- Table for replacing a PSprite's frame in realtime based on rsr_viewmodel
RSR.VIEWMODEL_FRAMES = {}

--- Sets a replacement frame for the given PSprite sprite/frame combo based on the given viewmodel orientation.
---@param sprite string
---@param frame string
---@param viewmodelOrient integer
---@param newFrame string
RSR.SetPSpriteViewmodelFrame = function(sprite, frame, viewmodelOrient, newFrame)
	if not (sprite and frame and viewmodelOrient and newFrame) then return end
	if not RSR.VIEWMODEL_FRAMES[sprite] then RSR.VIEWMODEL_FRAMES[sprite] = {} end
	if not RSR.VIEWMODEL_FRAMES[sprite][frame] then RSR.VIEWMODEL_FRAMES[sprite][frame] = {} end
	if not RSR.VIEWMODEL_FRAMES[sprite][frame][viewmodelOrient] then RSR.VIEWMODEL_FRAMES[sprite][frame][viewmodelOrient] = {} end
	RSR.VIEWMODEL_FRAMES[sprite][frame][viewmodelOrient] = newFrame
end

-- Red Ring
RSR.SetPSpriteViewmodelFrame("RSRBASC",	"A",	RSR.CVVIEWMODEL_LEFT,	"C")
RSR.SetPSpriteViewmodelFrame("RSRBASC",	"B",	RSR.CVVIEWMODEL_LEFT,	"D")
RSR.SetPSpriteViewmodelFrame("RSRBASC",	"A",	RSR.CVVIEWMODEL_CENTER,	"E")
RSR.SetPSpriteViewmodelFrame("RSRBASC",	"B",	RSR.CVVIEWMODEL_CENTER,	"F")

-- Scatter Ring
RSR.SetPSpriteViewmodelFrame("RSRSCTR",	"A",	RSR.CVVIEWMODEL_LEFT,	"B")
RSR.SetPSpriteViewmodelFrame("RSRSCTR",	"A",	RSR.CVVIEWMODEL_CENTER,	"C")

-- Automatic Ring
RSR.SetPSpriteViewmodelFrame("RSRAUTO",	"A",	RSR.CVVIEWMODEL_LEFT,	"B")
RSR.SetPSpriteViewmodelFrame("RSRAUTO",	"A",	RSR.CVVIEWMODEL_CENTER,	"C")

-- Explosion Ring
RSR.SetPSpriteViewmodelFrame("RSRBOMB",	"A",	RSR.CVVIEWMODEL_LEFT,	"B")
RSR.SetPSpriteViewmodelFrame("RSRBOMB",	"A",	RSR.CVVIEWMODEL_CENTER,	"C")

-- Grenade Ring
RSR.SetPSpriteViewmodelFrame("RSRGRND",	"A",	RSR.CVVIEWMODEL_LEFT,	"B")
RSR.SetPSpriteViewmodelFrame("RSRGRND",	"A",	RSR.CVVIEWMODEL_CENTER,	"C")

-- Bounce Ring
RSR.SetPSpriteViewmodelFrame("RSRBNCE",	"A",	RSR.CVVIEWMODEL_LEFT,	"B")
RSR.SetPSpriteViewmodelFrame("RSRBNCE",	"A",	RSR.CVVIEWMODEL_CENTER,	"C")

-- Homing Ring
RSR.SetPSpriteViewmodelFrame("RSRHOMG",	"A",	RSR.CVVIEWMODEL_LEFT,	"B")
RSR.SetPSpriteViewmodelFrame("RSRHOMG",	"A",	RSR.CVVIEWMODEL_CENTER,	"C")

-- Rail Ring
RSR.SetPSpriteViewmodelFrame("RSRRAIL",	"A",	RSR.CVVIEWMODEL_LEFT,	"B")
RSR.SetPSpriteViewmodelFrame("RSRRAIL",	"A",	RSR.CVVIEWMODEL_CENTER,	"C")

--- Gets a replacement frame for the given PSprite sprite/frame combo based on the given viewmodel orientation.
---@param sprite string
---@param frame string
---@param viewmodelOrient integer
RSR.GetPSPriteViewmodelFrame = function(sprite, frame, viewmodelOrient)
	if not (sprite and frame and viewmodelOrient) then return frame end
	if not RSR.VIEWMODEL_FRAMES[sprite] then return frame end
	if not RSR.VIEWMODEL_FRAMES[sprite][frame] then return frame end
	if not RSR.VIEWMODEL_FRAMES[sprite][frame][viewmodelOrient] then return frame end
	return RSR.VIEWMODEL_FRAMES[sprite][frame][viewmodelOrient]
end

--- Draws the player's psprites to the HUD.
---@param v videolib
---@param player player_t
---@param thiscam camera_t
RSR.HUDPSprites = function(v, player, thiscam)
	if not RSR.GamemodeActive() then return end
	if RSR.CV_Viewmodel.value == RSR.CVVIEWMODEL_NONE then return end
	if not (v and Valid(player) and Valid(player.mo) and player.rsrinfo and thiscam) then return end
	if not (not thiscam.chase and player.psprites) then return end

	local scale = FixedDiv(v.height(), 200)
	local xOffset = (v.width()*FRACUNIT - 320*scale)/2
	local yOffset = 32*scale
	local vFlags = V_NOSCALESTART|V_NOSCALEPATCH|V_SNAPTOBOTTOM|V_PERPLAYER
	-- if RSR.CV_Viewmodel.value == RSR.CVVIEWMODEL_LEFT then vFlags = $|V_FLIP end -- TODO: V_FLIP doesn't work in v.drawCropped yet, working on an MR to fix that

	for _, pspr in ipairs(player.psprites) do
		if not pspr then continue end

		if not pspr.state then continue end
		local x, y, sprite = 0, 0, nil

		x = pspr.x or 0
		y = pspr.y or 0

		if player.rsrinfo.bob then
			x = $ + player.rsrinfo.bob.x
			y = $ + player.rsrinfo.bob.y
		end

		local hasOrientSprite = false
		if pspr.sprite and pspr.frame then
			local frame = RSR.GetPSPriteViewmodelFrame(pspr.sprite, pspr.frame, RSR.CV_Viewmodel.value)
			if frame ~= pspr.frame then hasOrientSprite = true end
			sprite = pspr.sprite..frame
		end

		-- Add more features to frameargs in the future???
		local framebright = false
		if pspr.frameargs then framebright = true end

		if not sprite then continue end

		local patch = v.cachePatch(sprite)

		local skin = TC_DEFAULT
		local color = SKINCOLOR_NONE
		local transmap = nil

		if G_GametypeHasTeams() then
			if player.ctfteam == 2 then
				transmap = "RSRTeamBlue"
			-- The red ring is already red, so don't bother recoloring it
			elseif player.ctfteam == 1 and (pspr.sprite and pspr.sprite ~= "RSRBASC") then
				transmap = "RSRTeamRed"
			end
		end

		-- TODO: Revive my old MR adding translation map support to v.getSectorColormap so I can use it here
		local colormap = v.getColormap(skin, color, transmap)

		if not hasOrientSprite then
			if RSR.CV_Viewmodel.value == RSR.CVVIEWMODEL_LEFT then
				-- x = 320*FRACUNIT - $ -- TODO: Use this when my MR fixing V_FLIP for drawCropped gets merged
				x = (patch.leftoffset)*FRACUNIT - $
			elseif RSR.CV_Viewmodel.value == RSR.CVVIEWMODEL_CENTER then
				x = $ - 113*FRACUNIT
			end
		end

		-- drawCropped automatically crops the bottom of the patch for splitscreen, so use it instead of drawStretched
		v.drawCropped(
			FixedMul(x, scale) + xOffset,
			FixedMul(y, scale) + yOffset,
			scale,
			scale,
			patch,
			vFlags,
			colormap,
			0,
			0,
			patch.width*FRACUNIT,
			patch.height*FRACUNIT
		)
	end
end
