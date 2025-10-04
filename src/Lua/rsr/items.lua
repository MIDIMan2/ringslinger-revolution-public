---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Mobjs

local folder = "rsr/items"

local dofolder = function(file)
	dofile(folder.."/"..file)
end

--- Makes the player's screen fade gold for 1/3rd of a second.
---@param player player_t
RSR.BonusFade = function(player)
	if not Valid(player) then return end

	RSR.SetScreenFade(player, 64, FRACUNIT/2, TICRATE/3)
end

--- Makes the item invisible instead of deleting it if it is set to respawn.
---@param actor mobj_t
---@param var1 integer
---@param var2 integer
RSR.A_SetItemDeathState = function(actor, var1, var2)
	if not Valid(actor) then return end
	if not ((actor.flags2 & MF2_DONTRESPAWN) or (actor.info.flags & MF_MISSILE)) then actor.state = S_INVISIBLE end
end

states[S_RSR_SPARK] =		{SPR_RSPK,	A|FF_TRANS40,				1,	nil,						0,	0,	S_RSR_SPARK2}
states[S_RSR_SPARK2] =		{SPR_RSPK,	B|FF_TRANS50|FF_ANIMATE,	3,	nil,						2,	1,	S_RSR_SPARK3}
states[S_RSR_SPARK3] =		{SPR_RSPK,	A|FF_TRANS60|FF_ANIMATE,	3,	nil,						2,	1,	S_RSR_SPARK4}
states[S_RSR_SPARK4] =		{SPR_RSPK,	D|FF_TRANS70,				1,	nil,						0,	0,	S_RSR_SPARK5}
states[S_RSR_SPARK5] =		{SPR_RSPK,	A|FF_TRANS70|FF_ANIMATE,	2,	nil,						1,	1,	S_RSR_SPARK6}
states[S_RSR_SPARK6] =		{SPR_RSPK,	C|FF_TRANS80|FF_ANIMATE,	2,	nil,						1,	1,	S_RSR_SPARK7}
states[S_RSR_SPARK7] =		{SPR_RSPK,	A|FF_TRANS80,				1,	nil,						0,	0,	S_RSR_SPARK8}
states[S_RSR_SPARK8] =		{SPR_RSPK,	B|FF_TRANS90|FF_ANIMATE,	3,	nil,						2,	1,	S_RSR_ITEM_DEATH}
states[S_RSR_ITEM_DEATH] =	{SPR_NULL,	A,							0,	RSR.A_SetItemDeathState,	0,	0,	S_NULL}

states[S_RSR_TELEFOG] =			{SPR_RSTF,	A|FF_FULLBRIGHT|FF_TRANS50|FF_ANIMATE,	28,	nil,	13,	2,	S_RSR_TELEFOG_SOUND}
states[S_RSR_TELEFOG_SOUND] =	{SPR_NULL,	A,										70,	nil,	0,	0,	S_NULL}

dofolder("functions.lua")
dofolder("health.lua")
dofolder("powerups.lua")
dofolder("actions.lua")
dofolder("monitors.lua")
dofolder("emeralds.lua")
