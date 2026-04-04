-- Ringslinger Revolution - Heads-Up Display

local folder = "rsr/hud"

local dofolder = function(file)
	dofile(folder.."/"..file)
end

--- Lua reimplementation of V_DrawTallNum, with string colormap support.
---@param v videolib
---@param x integer
---@param y integer
---@param flags integer
---@param num integer
RSR.HUDDrawTallNum = function(v, x, y, num, flags)
	local tallnum = {}
	tallnum[0] = v.cachePatch("STTNUM0")
	local w = tallnum[0].width
	local neg
	local colormap = v.getStringColormap(flags & V_CHARCOLORMASK)
	flags = $ & ~V_CHARCOLORMASK

	if (flags & (V_NOSCALESTART|V_NOSCALEPATCH)) then
		w = $ * v.dupx()
	end

	neg = num < 0
	if neg then num = -num end

	-- draw the number
	repeat
		x = $ - w
		if not tallnum[num % 10] then
			tallnum[num % 10] = v.cachePatch("STTNUM"..tostring(num % 10))
		end
		v.draw(x, y, tallnum[num % 10], flags, colormap)
		num = $ / 10
	until not num

	-- draw a minus sign if necessary
	if neg then
		v.draw(x - w, y, v.cachePatch("STTMINUS"), flags, colormap)
	end
end

-- dofolder("title.lua") -- TODO: Uncomment this when the title screen is finished...
dofolder("time.lua")
dofolder("emeralds.lua")
dofolder("hype.lua")
dofolder("powerups.lua")
dofolder("effects.lua")
dofolder("psprites.lua")
dofolder("screenfade.lua")
dofolder("weaponbar.lua")
dofolder("bosshealth.lua")
dofolder("waves.lua")
dofolder("flagradar.lua")
dofolder("killfeed.lua")

--- Draws the player's health to the HUD.
---@param v videolib
---@param player player_t
RSR.HUDHealth = function(v, player)
	if not (v and Valid(player) and player.rsrinfo) then return end

	local vFlags = V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_HUDTRANS|V_PERPLAYER
	if player.rsrinfo.ehpFlash and player.rsrinfo.ehpFlash.tics then
		if ((player.rsrinfo.ehpFlash.tics/player.rsrinfo.ehpFlash.frequency) & 1) then
			vFlags = $|player.rsrinfo.ehpFlash.color
		end
	elseif player.rsrinfo.health and player.rsrinfo.health + player.rsrinfo.armor <= RSR.CRIT_EHP then
		if ((leveltime/35) & 1) then
			vFlags = $|V_GRAYMAP
		end
	end

	v.draw(6, 186, v.cachePatch("RSRHLTH"), vFlags & ~V_CHARCOLORMASK)
	if (vFlags & V_CHARCOLORMASK) then
		RSR.HUDDrawTallNum(v, 48, 186, player.rsrinfo.health, vFlags)
	else
		v.drawNum(48, 186, player.rsrinfo.health, vFlags)
	end
end

--- Draws the player's armor to the HUD.
---@param v videolib
---@param player player_t
RSR.HUDArmor = function(v, player)
	if not (v and Valid(player) and player.rsrinfo) then return end

	local armorIcon = "RSRARMR"
	local shield = player.powers[pw_shield] & SH_NOSTACK
	if (shield & SH_FORCE) then shield = SH_FORCE end
	if shield and RSR.SHIELD_INFO[shield] and RSR.SHIELD_INFO[shield].icon then armorIcon = RSR.SHIELD_INFO[shield].icon end
	local armorPatch = v.cachePatch(armorIcon)

	local vFlags = V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_HUDTRANS|V_PERPLAYER
	if player.rsrinfo.ehpFlash and player.rsrinfo.ehpFlash.tics then
		if ((player.rsrinfo.ehpFlash.tics/player.rsrinfo.ehpFlash.frequency) & 1) then
			vFlags = $|player.rsrinfo.ehpFlash.color
		end
	elseif player.rsrinfo.health and player.rsrinfo.health + player.rsrinfo.armor <= RSR.CRIT_EHP then
		if ((leveltime/35) & 1) then
			vFlags = $|V_GRAYMAP
		end
	end

	if Valid(armorPatch) then
		local armorXOffset = -((armorPatch.width - 11)/2)
		local armorYOffset = -((armorPatch.height - 11)/2)
		v.draw(6 + armorXOffset, 170 + armorYOffset, armorPatch, vFlags & ~V_CHARCOLORMASK)
	end
	if (vFlags & V_CHARCOLORMASK) then
		RSR.HUDDrawTallNum(v, 48, 170, player.rsrinfo.armor, vFlags)
	else
		v.drawNum(48, 170, player.rsrinfo.armor, vFlags)
	end
end

RSR.HUD_SCOPE_ARROWS = {
	[0] = "RSRSCPA1",
	[1] = "RSRSCPA2",
	[2] = "RSRSCPA3",
	[3] = "RSRSCPA4",
	[4] = "RSRSCPA4",
	[5] = "RSRSCPA5",
	[6] = "RSRSCPA6",
	[7] = "RSRSCPA7",
	[8] = "RSRSCPA8",
	[9] = "RSRSCPA8"
}

--- Draws the player's scope to the HUD.
---@param v videolib
---@param player player_t
RSR.HUDScope = function(v, player, thiscam)
	if not (v and Valid(player) and player.rsrinfo) then return end

	if player.rsrinfo.fovZoom then
		local arrowFrame = player.rsrinfo.fovZoom/2
		local arrowUp = RSR.HUD_SCOPE_ARROWS[arrowFrame]
		local arrowDown = RSR.HUD_SCOPE_ARROWS[arrowFrame + 5]
		local arrowX, arrowY = 160, 100
		-- TODO: Make the third-person scope more accurate
		-- if thiscam and thiscam.chase then
		-- 	local result = R_World2Screen3FPS(v, player, thiscam, {
		-- 		x = player.realmo.x + 1024*FixedMul(cos(player.realmo.angle), cos(player.cmd.aiming<<16)),
		-- 		y = player.realmo.y + 1024*FixedMul(sin(player.realmo.angle), cos(player.cmd.aiming<<16)),
		-- 		z = player.viewz + 1024*sin(player.cmd.aiming<<16)
		-- 	})
		-- 	arrowX = result.x/FRACUNIT
		-- 	arrowY = result.y/FRACUNIT
		-- end

		-- Sonic 2 Death Egg Robot target sprites ripped by Paraemon
		v.draw(arrowX, arrowY, v.cachePatch("RSRSCOPE"), V_PERPLAYER)
		v.draw(arrowX - 48 + 8*arrowFrame, arrowY - 48 + 8*arrowFrame, v.cachePatch(arrowUp), V_PERPLAYER)
		v.draw(arrowX - 48 + 8*arrowFrame, arrowY + 48 - 8*arrowFrame, v.cachePatch(arrowDown), V_PERPLAYER)
		v.draw(arrowX + 48 - 8*arrowFrame, arrowY - 48 + 8*arrowFrame, v.cachePatch(arrowUp), V_PERPLAYER|V_FLIP)
		v.draw(arrowX + 48 - 8*arrowFrame, arrowY + 48 - 8*arrowFrame, v.cachePatch(arrowDown), V_PERPLAYER|V_FLIP)
	end
end

RSR.LAST_HUDTYPE = {}

RSR.HUD_CHARMODNAMES = {}

RSR.VANILLA_HUD_ITEMS = {
	"score",
	"time",
	"rings",
	"lives",
	"powerups",
	"weaponrings",
	"powerstones",
	"nightsrings",
	"nightstime",
	"nightsrecords"
}

RSR.HUD_ITEMS = {
	{"rsr_wavesenemyradar", RSR.HUDWavesEnemyRadar, 0},
	{"rsr_effects", RSR.HUDEffects, 0},
	
	{"rsr_scope", RSR.HUDScope, 1},
	{"rsr_psprites", RSR.HUDPSprites, 2},

	{"rsr_powerups", RSR.HUDPowerups, 3},
	{"rsr_weaponbar", RSR.HUDWeaponBar, 3},

	{"rsr_health", RSR.HUDHealth, 3},
	{"rsr_armor", RSR.HUDArmor, 3},

	{"rsr_emeralds", RSR.HUDEmeralds, 3},
	{"rsr_hypemeter", RSR.HUDHypeMeter, 3},

	{"rsr_bosshealth", RSR.HUDBossHealth, 3},
	{"rsr_time", RSR.HUDTime, 3},
	{"rsr_wavesenemycount", RSR.HUDWavesEnemyCount, 3},

	{"rsr_waves", RSR.HUDWaves, 4},
	{"rsr_flagradar", RSR.HUDCTFFlagRadar, 4},
	{"rsr_vendetta", RSR.HUDVendettaPing, 4},
	{"rsr_killfeed", RSR.HUDKillfeed, 4},

	{"rsr_screenfade", RSR.HUDScreenFade, 32},

	{"matchemeralds", nil, nil}, -- MRCE compatibility
}

for _, huditem in ipairs(RSR.VANILLA_HUD_ITEMS) do
	if not huditem then continue end
	-- RSR.LAST_HUDTYPE[huditem] = customhud.CheckType(huditem)
	RSR.LAST_HUDTYPE[huditem] = "vanilla"
end

for _, hudItemInfo in ipairs(RSR.HUD_ITEMS) do
	if not hudItemInfo then continue end
	-- Instead of putting the player skin check in the HUD functions themselves,
	-- we make a new function to call them after the skin check instead.
	-- This lets modders use the HUD drawing functions outside of customhud,
	-- even if the player's skin has "nohud" enabled.
	customhud.SetupItem(hudItemInfo[1], "rsr", function(v, player, thiscam)
		-- Don't call the HUD function if the player's skin has "nohud" enabled
		if (Valid(player) and RSR.SKIN_INFO[skins[player.skin].name] and RSR.SKIN_INFO[skins[player.skin].name].nohud) then return end
		if hudItemInfo[2] then hudItemInfo[2](v, player, thiscam) end
	end, "game", hudItemInfo[3])
	RSR.LAST_HUDTYPE[hudItemInfo[1]] = customhud.CheckType(hudItemInfo[1])
end

--- Automatically toggles the RSR HUD based on the current level
---@param player player_t
RSR.ToggleHUDItems = function(player)
	if not (Valid(player) and P_IsLocalPlayer(player)) then return end -- Don't run this function for non-local players
	for _, huditem in ipairs(RSR.VANILLA_HUD_ITEMS) do
		local checkType = customhud.CheckType(huditem)
		if checkType ~= "rsr" and not RSR.HUD_CHARMODNAMES[checkType] then
			RSR.LAST_HUDTYPE[huditem] = checkType
		end
		if RSR.GamemodeActive() then
			customhud.SetupItem(huditem, "rsr")
		else
			customhud.SetupItem(huditem, RSR.LAST_HUDTYPE[huditem])
		end
	end
	for _, hudItemInfo in ipairs(RSR.HUD_ITEMS) do
		local checkType = customhud.CheckType(hudItemInfo[1])
		if checkType ~= "rsr" and not RSR.HUD_CHARMODNAMES[checkType] then
			RSR.LAST_HUDTYPE[hudItemInfo[1]] = checkType
		end
		if RSR.GamemodeActive() then
			customhud.SetupItem(hudItemInfo[1], "rsr")
		elseif RSR.LAST_HUDTYPE[hudItemInfo[1]] ~= "vanilla" then
			customhud.SetupItem(hudItemInfo[1], RSR.LAST_HUDTYPE[hudItemInfo[1]])
		end
	end
end
