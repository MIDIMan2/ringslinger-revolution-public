---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Health and Shield Pickups
-- Sprites are heavily inspired by Samsara's health pickup sprites

--- Gives health to the player.
---@param player player_t
---@param health integer Amount of health to give the player (Default is 1).
---@param isBonus boolean|nil If true, the player's health will go past 100 and up to 200.
RSR.GiveHealth = function(player, health, isBonus)
	if not (Valid(player) and player.rsrinfo) then return false end
	-- Don't run this function if the player's skin has been exempt from the damage system
	if RSR.SKIN_INFO[skins[player.skin].name] and RSR.SKIN_INFO[skins[player.skin].name].nodamage then return false end
	if health == nil then health = 1 end

	if not isBonus and player.rsrinfo.health >= RSR.MAX_HEALTH then return false end

	local maxHealth = RSR.MAX_HEALTH
	if isBonus then maxHealth = RSR.MAX_HEALTH_BONUS end

	player.rsrinfo.health = min($ + health, maxHealth)
	return true
end

--- Gives armor to the player.
---@param player player_t
---@param armor integer Amount of armor to give the player (Default is 1).
---@param isBonus boolean|nil If true, the player's armor will go past 100 and up to 200.
RSR.GiveArmor = function(player, armor, isBonus)
	if not (Valid(player) and player.rsrinfo) then return false end
	-- Don't run this function if the player's skin has been exempt from the damage system
	if RSR.SKIN_INFO[skins[player.skin].name] and RSR.SKIN_INFO[skins[player.skin].name].nodamage then return false end
	if armor == nil then armor = 1 end

	if not isBonus and player.rsrinfo.armor >= RSR.MAX_ARMOR then return false end

	local maxArmor = RSR.MAX_HEALTH
	if isBonus then maxArmor = RSR.MAX_ARMOR_BONUS end

	player.rsrinfo.armor = min($ + armor, maxArmor)
	return true
end

--- Gives hype to the player.
---@param player player_t
---@param hype integer Amount of hype to give the player (Default is 1).
RSR.GiveHype = function(player, hype)
	if not (Valid(player) and player.rsrinfo) then return false end
	-- Don't run this function if the player's skin has been exempt from the damage system
	if RSR.SKIN_INFO[skins[player.skin].name] and RSR.SKIN_INFO[skins[player.skin].name].nodamage then return false end
	if not (emeralds == 127 or player.powers[pw_emeralds] == 127) then return false end -- Don't give hype if the player doesn't have all the emeralds.
	if hype == nil then hype = 1 end

	if player.rsrinfo.hype >= RSR.MAX_HYPE then return false end

	player.rsrinfo.hype = min($ + hype, RSR.MAX_HYPE)
	return true
end

--- MobjSpawn hook code for health pickups.
---@param mo mobj_t
RSR.HealthMobjSpawn = function(mo)
	if not Valid(mo) then return end

	mo.shadowscale = 2*FRACUNIT/3
	mo.rsrFloatOffset = FixedAngle(P_RandomKey(360)*FRACUNIT)

	if not (netgame or multiplayer) then
		mo.flags2 = $|MF2_DONTRESPAWN
	end
end

--- Default function for SKIN_INFO's touchHealth hook
---@param special mobj_t The powerup pickup being touched.
---@param toucher mobj_t The player object touching the pickup.
---@param health integer The amount of health given to the player by the pickup.
RSR.TouchHealthDefault = function(special, toucher, health)
	local player = toucher.player

	if not RSR.GiveHealth(player, health) then return true end
	RSR.BonusFade(player)
	RSR.SetItemFuse(special)
end

--- TouchSpecial hook code for health pickups.
---@param special mobj_t
---@param toucher mobj_t
---@param health integer
RSR.HealthTouchSpecial = function(special, toucher, health)
	if not (Valid(special) and Valid(toucher)) then return end
	local player = toucher.player
	if not (Valid(player) and player.rsrinfo) then return end

	-- local hookValue = hookLib.RunHook("RSR_HealthTouchSpecial", special, toucher, health)
	-- if hookValue ~= nil then
	-- 	if Valid(special) and special.health <= 0 then RSR.SetItemFuse(special) end
	-- 	return hookValue
	-- end

	local skinInfo = RSR.SKIN_INFO[skins[player.skin].name]
	if skinInfo and skinInfo.hooks and skinInfo.hooks.touchHealth then
		local returnValue = skinInfo.hooks.touchHealth(special, toucher, health)
		if returnValue ~= nil then
			return returnValue
		end
	end

	return RSR.SKIN_INFO["DEFAULT"].hooks.touchHealth(special, toucher, health)
end

--- Default function for SKIN_INFO's touchArmor hook
---@param special mobj_t The powerup pickup being touched.
---@param toucher mobj_t The player object touching the pickup.
---@param armor integer The amount of armor given to the player by the pickup.
RSR.TouchArmorDefault = function(special, toucher, armor)
	local player = toucher.player

	if not RSR.GiveArmor(player, armor) then return true end
	RSR.BonusFade(player)
	RSR.SetItemFuse(special)
end

--- TouchSpecial hook code for armor pickups.
---@param special mobj_t
---@param toucher mobj_t
---@param armor integer
RSR.ArmorTouchSpecial = function(special, toucher, armor)
	if not (Valid(special) and Valid(toucher)) then return end
	local player = toucher.player
	if not (Valid(player) and player.rsrinfo) then return end

	-- local hookValue = hookLib.RunHook("RSR_ArmorTouchSpecial", special, toucher, armor)
	-- if hookValue ~= nil then
	-- 	if Valid(special) and special.health <= 0 then RSR.SetItemFuse(special) end
	-- 	return hookValue
	-- end

	local skinInfo = RSR.SKIN_INFO[skins[player.skin].name]
	if skinInfo and skinInfo.hooks and skinInfo.hooks.touchArmor then
		local returnValue = skinInfo.hooks.touchArmor(special, toucher, armor)
		if returnValue ~= nil then
			return returnValue
		end
	end

	return RSR.SKIN_INFO["DEFAULT"].hooks.touchArmor(special, toucher, armor)
end

mobjinfo[MT_RSR_HEALTH_SMALL] = {
	--$Name Small Health
	--$Sprite RSHTA0
	--$Category Ringslinger Revolution
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	doomednum = 350,
	spawnstate = S_RSR_HEALTH_SMALL,
	deathstate = S_RSR_ITEM_DEATH,
	deathsound = sfx_ncitem,
	radius = 16*FRACUNIT,
	height = 24*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_HEALTH_SMALL] =	{SPR_RSHT,	A|FF_ADD,	-1,	nil,	0,	0,	S_NULL}

addHook("MobjSpawn", RSR.HealthMobjSpawn, MT_RSR_HEALTH_SMALL)
addHook("MapThingSpawn", RSR.ItemMapThingSpawn, MT_RSR_HEALTH_SMALL)
addHook("MobjThinker", RSR.ItemFloatThinker, MT_RSR_HEALTH_SMALL)
addHook("MobjFuse", RSR.ItemMobjFuse, MT_RSR_HEALTH_SMALL)
addHook("TouchSpecial", function(special, toucher)
	return RSR.HealthTouchSpecial(special, toucher, 10)
end, MT_RSR_HEALTH_SMALL)

mobjinfo[MT_RSR_HEALTH] = {
	--$Name Medium Health
	--$Sprite RSHTB0
	--$Category Ringslinger Revolution
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	doomednum = 351,
	spawnstate = S_RSR_HEALTH,
	deathstate = S_RSR_ITEM_DEATH,
	deathsound = sfx_ncitem,
	radius = 16*FRACUNIT,
	height = 24*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_HEALTH] =	{SPR_RSHT,	B|FF_ADD,	-1,	nil,	0,	0,	S_NULL}

addHook("MobjSpawn", RSR.HealthMobjSpawn, MT_RSR_HEALTH)
addHook("MapThingSpawn", RSR.ItemMapThingSpawn, MT_RSR_HEALTH)
addHook("MobjThinker", RSR.ItemFloatThinker, MT_RSR_HEALTH)
addHook("MobjFuse", RSR.ItemMobjFuse, MT_RSR_HEALTH)
addHook("TouchSpecial", function(special, toucher)
	return RSR.HealthTouchSpecial(special, toucher, 25)
end, MT_RSR_HEALTH)

mobjinfo[MT_RSR_HEALTH_BIG] = {
	--$Name Big Health
	--$Sprite RSHTC0
	--$Category Ringslinger Revolution
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	doomednum = 352,
	spawnstate = S_RSR_HEALTH_BIG,
	deathstate = S_RSR_ITEM_DEATH,
	deathsound = sfx_ncitem,
	radius = 16*FRACUNIT,
	height = 24*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_HEALTH_BIG] =	{SPR_RSHT,	C|FF_ADD,	-1,	nil,	0,	0,	S_NULL}

addHook("MobjSpawn", RSR.HealthMobjSpawn, MT_RSR_HEALTH_BIG)
addHook("MapThingSpawn", RSR.ItemMapThingSpawn, MT_RSR_HEALTH_BIG)
addHook("MobjThinker", RSR.ItemFloatThinker, MT_RSR_HEALTH_BIG)
addHook("MobjFuse", RSR.ItemMobjFuse, MT_RSR_HEALTH_BIG)
addHook("TouchSpecial", function(special, toucher)
	return RSR.HealthTouchSpecial(special, toucher, 50)
end, MT_RSR_HEALTH_BIG)

mobjinfo[MT_RSR_ARMOR_SMALL] = {
	--$Name Small Armor
	--$Sprite RSHTD0
	--$Category Ringslinger Revolution
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	doomednum = 353,
	spawnstate = S_RSR_ARMOR_SMALL,
	deathstate = S_RSR_ITEM_DEATH,
	deathsound = sfx_shield,
	radius = 16*FRACUNIT,
	height = 24*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_ARMOR_SMALL] =	{SPR_RSHT,	D|FF_ADD,	-1,	nil,	0,	0,	S_NULL}

addHook("MobjSpawn", RSR.HealthMobjSpawn, MT_RSR_ARMOR_SMALL)
addHook("MapThingSpawn", RSR.ItemMapThingSpawn, MT_RSR_ARMOR_SMALL)
addHook("MobjThinker", RSR.ItemFloatThinker, MT_RSR_ARMOR_SMALL)
addHook("MobjFuse", RSR.ItemMobjFuse, MT_RSR_ARMOR_SMALL)
addHook("TouchSpecial", function(special, toucher)
	return RSR.ArmorTouchSpecial(special, toucher, 10)
end, MT_RSR_ARMOR_SMALL)

mobjinfo[MT_RSR_ARMOR] = {
	--$Name Medium Armor
	--$Sprite RSHTE0
	--$Category Ringslinger Revolution
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	doomednum = 354,
	spawnstate = S_RSR_ARMOR,
	deathstate = S_RSR_ITEM_DEATH,
	deathsound = sfx_shield,
	radius = 16*FRACUNIT,
	height = 24*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_ARMOR] =	{SPR_RSHT,	E|FF_ADD,	-1,	nil,	0,	0,	S_NULL}

addHook("MobjSpawn", RSR.HealthMobjSpawn, MT_RSR_ARMOR)
addHook("MapThingSpawn", RSR.ItemMapThingSpawn, MT_RSR_ARMOR)
addHook("MobjThinker", RSR.ItemFloatThinker, MT_RSR_ARMOR)
addHook("MobjFuse", RSR.ItemMobjFuse, MT_RSR_ARMOR)
addHook("TouchSpecial", function(special, toucher)
	return RSR.ArmorTouchSpecial(special, toucher, 25)
end, MT_RSR_ARMOR)

mobjinfo[MT_RSR_ARMOR_BIG] = {
	--$Name Big Armor
	--$Sprite RSHTF0
	--$Category Ringslinger Revolution
	--$Arg0 "Float?"
	--$Arg0Tooltip "This raises the object by 24 fracunits."
	--$Arg0Type 11
	--$Arg0Enum yesno
	doomednum = 355,
	spawnstate = S_RSR_ARMOR_BIG,
	deathstate = S_RSR_ITEM_DEATH,
	deathsound = sfx_shield,
	radius = 16*FRACUNIT,
	height = 24*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

states[S_RSR_ARMOR_BIG] =	{SPR_RSHT,	F|FF_ADD,	-1,	nil,	0,	0,	S_NULL}

addHook("MobjSpawn", RSR.HealthMobjSpawn, MT_RSR_ARMOR_BIG)
addHook("MapThingSpawn", RSR.ItemMapThingSpawn, MT_RSR_ARMOR_BIG)
addHook("MobjThinker", RSR.ItemFloatThinker, MT_RSR_ARMOR_BIG)
addHook("MobjFuse", RSR.ItemMobjFuse, MT_RSR_ARMOR_BIG)
addHook("TouchSpecial", function(special, toucher)
	return RSR.ArmorTouchSpecial(special, toucher, 50)
end, MT_RSR_ARMOR_BIG)
