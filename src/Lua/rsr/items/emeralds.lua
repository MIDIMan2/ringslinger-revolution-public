-- Ringslinger Revolution - Power Stones

-- If the current map is an RSR map with the "Power Stones" rule, use a hack to let players transform into super forms
RSR.EmeraldsMapLoad = function()
	if not (RSR.GamemodeActive() and (gametyperules & GTR_POWERSTONES)) then return end
	emeralds = 127
end

--- TouchSpecial hook code for collectible emeralds.
---@param special mobj_t
---@param toucher mobj_t
RSR.EmeraldTouchSpecial = function(special, toucher)
	if not RSR.GamemodeActive() then return end -- Only run this code in RSR maps
	if not (Valid(special) and Valid(toucher)) then return end
	if not (Valid(toucher.player) and toucher.player.rsrinfo) then return end
	local player = toucher.player ---@type player_t

	if player.bot and player.bot ~= BOT_MPAI then return end

	if (special.threshold) then
		player.powers[pw_emeralds] = $|special.info.speed
		if player.powers[pw_emeralds] == 127 then player.rsrinfo.hype = max($, RSR.TRIGGER_HYPE) end
	else
		return
	end

	if Valid(special.target) and special.target.type == MT_EMERALDSPAWN then
		if Valid(special.target.target) then special.target.target = nil end

		special.target.threshold = 0

		special.target = nil
	end

	S_StartSound(toucher, special.info.deathsound)
	P_KillMobj(special, nil, toucher, 0)
	special.shadowscale = 0
	return true -- Overwrite the vanilla behavior
end

--- MobjThinker hook code for emeralds flinging sparks.
---@param mo mobj_t
RSR.EmeraldFlingSpark = function(mo)
	if not RSR.GamemodeActive() then return end
	if not Valid(mo) then return end
	RSR.ItemFlingSpark(mo, -8*FRACUNIT, nil, 35) -- Emeralds spawn bigger sparks
end

addHook("TouchSpecial", RSR.EmeraldTouchSpecial, MT_EMERALD1)
addHook("TouchSpecial", RSR.EmeraldTouchSpecial, MT_EMERALD2)
addHook("TouchSpecial", RSR.EmeraldTouchSpecial, MT_EMERALD3)
addHook("TouchSpecial", RSR.EmeraldTouchSpecial, MT_EMERALD4)
addHook("TouchSpecial", RSR.EmeraldTouchSpecial, MT_EMERALD5)
addHook("TouchSpecial", RSR.EmeraldTouchSpecial, MT_EMERALD6)
addHook("TouchSpecial", RSR.EmeraldTouchSpecial, MT_EMERALD7)
addHook("MobjThinker", RSR.EmeraldFlingSpark, MT_EMERALD1)
addHook("MobjThinker", RSR.EmeraldFlingSpark, MT_EMERALD2)
addHook("MobjThinker", RSR.EmeraldFlingSpark, MT_EMERALD3)
addHook("MobjThinker", RSR.EmeraldFlingSpark, MT_EMERALD4)
addHook("MobjThinker", RSR.EmeraldFlingSpark, MT_EMERALD5)
addHook("MobjThinker", RSR.EmeraldFlingSpark, MT_EMERALD6)
addHook("MobjThinker", RSR.EmeraldFlingSpark, MT_EMERALD7)

---@param special mobj_t
---@param toucher mobj_t
addHook("TouchSpecial", function(special, toucher)
	if not RSR.GamemodeActive() then return end -- Only run this code in RSR maps
	if not (Valid(special) and Valid(toucher)) then return end
	if not Valid(toucher.player) then return end

	---@type player_t
	local player = toucher.player

	if not P_CanPickupItem(player, true) or player.tossdelay then
		return
	end

	player.powers[pw_emeralds] = $|special.threshold
	if toucher.player.powers[pw_emeralds] == 127 then toucher.player.rsrinfo.hype = RSR.TRIGGER_HYPE end

	S_StartSound(toucher, special.info.deathsound)
	P_KillMobj(special, nil, toucher, 0)
	special.shadowscale = 0
	return true -- Overwrite the vanilla behavior
end, MT_FLINGEMERALD)

---@param mo mobj_t
addHook("MobjThinker", function(mo)
	if not RSR.GamemodeActive() then return end -- Only run this code in RSR maps
	if not Valid(mo) then return end
	if mo.fuse and mo.fuse < 2*TICRATE then mo.flags2 = $ ^^ MF2_DONTDRAW end
end, MT_FLINGEMERALD)

addHook("TouchSpecial", function(special, toucher)
	if not RSR.GamemodeActive() then return end -- Only run this code in RSR maps
	if not (Valid(toucher.player) and toucher.player.rsrinfo) then return end
	local player = toucher.player ---@type player_t

	if not RSR.PlayerHasAllEmeralds(player) then return end
	RSR.GiveHealth(player, 50, nil, true)
	RSR.GiveArmor(player, 50, nil, true)
	player.rsrinfo.hype = max($, RSR.TRIGGER_HYPE)
end, MT_TOKEN)
