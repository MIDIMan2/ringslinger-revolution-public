---@diagnostic disable: missing-fields
-- Ringslinger Revolution - Cybrak 2016
-- Created in SOC by orbitalviolet for 72HR-UDMF, ported to Lua, optimized, and edited by MIDIMan
-- Used with permission from orbitalviolet

-- If you plan to use this outside of Ringslinger Revolution,
-- make sure to replace instances of "Valid(varName)" with "(varName and varName.valid)"

-- Freeslots have been moved to "freeslots.lua"

addHook("BossDeath", function(mo)
	if not Valid(mo) then return end

	mo.flags = ($ & ~(MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT)|MF_NOCLIP)

	S_StartSound(mo, sfx_befall)

	-- Borrowed from Retro Bosses' 2.0 Brak
	for i = 0, 15, 1 do
		local angle = i*ANGLE_22h -- Replacement for i*FINEANGLE/16
		local thrust = 64*FRACUNIT
		local xoffs = FixedMul(sin(angle), thrust)
		local yoffs = FixedMul(cos(angle), thrust)

		local explode = P_SpawnMobjFromMobj(mo, xoffs, yoffs, 0, MT_EXPLODE)
		if Valid(explode) then
			thrust = 16*explode.scale
			explode.momx = FixedMul(sin(angle), thrust)
			explode.momy = FixedMul(cos(angle), thrust)
		end
	end

	return true
end, MT_CYBRAK2016)

-- the big boi

mobjinfo[MT_CYBRAK2016] = {
	--$Name Cybrak 2016
	--$Sprite BRAKB1
	--$Category Bosses
	--$Flags4Text End level on death
	--$Arg0 Boss ID
	--$Arg1 "End level on death?"
	--$Arg1Type 11
	--$Arg1Enum noyes
	doomednum = 2016, -- Originally 666, but UglyKnux uses it
	spawnstate = S_CYBRAK2016_SPAWN,
	spawnhealth = 6,
	seestate = S_CYBRAK2016_INITBOSSHEALTH,
	seesound = sfx_bewar2,
	reactiontime = 15,
	painstate = S_CYBRAK2016_BIGOWIE,
	painsound = sfx_behurt,
	deathstate = S_CYBRAK2016_ITDIES,
	deathsound = sfx_s3kb4,
	speed = 40,
	radius = 48*FRACUNIT,
	height = 160*FRACUNIT,
-- 	mass = 100,
	damage = 3,
	activesound = sfx_bewar1,
	flags = MF_SPECIAL|MF_BOSS|MF_SHOOTABLE
}


-- railgun target marker

mobjinfo[MT_CYBRAK2016_WATCHYOASS] = {
	doomednum = -1,
	spawnstate = S_CYBRAK2016_TARGET,
	spawnhealth = 1000,
-- 	reactiontime = 8,
	speed = 10*FRACUNIT,
	radius = 32*FRACUNIT,
	height = 64*FRACUNIT,
-- 	mass = 100,
	damage = 1,
	flags = MF_NOBLOCKMAP|MF_RUNSPAWNFUNC|MF_NOGRAVITY
}


-- railgun slug

mobjinfo[MT_CYBRAK2016_SLUG] = {
	doomednum = -1,
	spawnstate = S_CYBRAK2016_SSPAWN,
	spawnhealth = 1000,
	seesound = sfx_trfire,
-- 	reactiontime = 8,
	deathsound = sfx_rail2,
	speed = 170*FRACUNIT,
	radius = 8*FRACUNIT,
	height = 16*FRACUNIT,
-- 	mass = 100,
	damage = 32*FRACUNIT,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}


-- stomp shockwave

mobjinfo[MT_CYBRAK2016_SPARK] = {
	doomednum = -1,
	spawnstate = S_SSPK1,
	spawnhealth = 1,
-- 	reactiontime = 8,
	speed = 50*FRACUNIT,
	radius = 8*FRACUNIT,
	height = 8*FRACUNIT,
-- 	mass = 100,
	damage = 1,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}


-- blade swing projectile

mobjinfo[MT_CYBRAK2016_SLASH] = {
	doomednum = -1,
	spawnstate = S_CYBRAK2016_SLASH1,
	spawnhealth = 1,
-- 	reactiontime = 8,
	speed = 113*FRACUNIT,
	radius = 64*FRACUNIT,
	height = 3*FRACUNIT,
-- 	mass = 100,
	damage = 1,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
}


-- This is probably not the best way to initialize boss health, but it'll have to do for now
A_RSRInitBossHealth = function(actor, var1, var2)
	if not Valid(actor) then return end

	RSR.CURRENT_BOSS = actor
end


-- boss handler between attacks: look for target, wait a bit to give them some room, choose attack

states[S_CYBRAK2016_SPAWN] =	{SPR_BRAK,	A,	1,	A_Look,	0,	0,	S_CYBRAK2016_LMAO}

states[S_CYBRAK2016_LMAO] =	{SPR_BRAK,	A,	1,	A_Look,	0,	0,	S_CYBRAK2016_LMAO}

states[S_CYBRAK2016_INITBOSSHEALTH] =			{SPR_BRAK,	A,	0,	A_RSRInitBossHealth,	0,	0,								S_CYBRAK2016_ITSMYENEMYSTAND}
states[S_CYBRAK2016_ITSMYENEMYSTAND] =			{SPR_BRAK,	A,	1,	A_FaceTarget,			0,	0,								S_CYBRAK2016_STANDINGTHEREMENACINGLY}
states[S_CYBRAK2016_STANDINGTHEREMENACINGLY] =	{SPR_BRAK,	A,	1,	A_Repeat,				69,	S_CYBRAK2016_ITSMYENEMYSTAND,	S_CYBRAK2016_TIMETOCHOOSE}

-- free attack choice handler, tries: rockets, dashing, blade, railgun or napalm

-- These aren't actually used, so comment them out
-- local RSR_CYBRAK_ATTACK_ROCKET =	1
-- local RSR_CYBRAK_ATTACK_DASH =		2
-- local RSR_CYBRAK_ATTACK_BLADE =		3
-- local RSR_CYBRAK_ATTACK_RAILGUN =	4
-- local RSR_CYBRAK_ATTACK_NAPALM =	5

local RSR_CYBRAK_ATTACK_STATES = {
	S_CYBRAK2016_ROCKETDIRECTION,
	S_CYBRAK2016_DASHPREP,
	S_CYBRAK2016_SWING,
	S_CYBRAK2016_QUICKSCOPE,
	S_CYBRAK2016_AIRSTRIKE
}

A_RSRCybrakRandomAttack = function(actor, var1, var2)
	if not Valid(actor) then return end

	local attackMax = 5

	local attackNum = P_RandomRange(1, attackMax)
	-- Make Cybrak always use his rocket attack first
	if not actor.rsrCybrakRocket then
		attackNum = 1
		actor.rsrCybrakRocket = true
	end

	-- Remember the last attack Brak did so he doesn't do it again
	while attackNum == actor.cusval do
		attackNum = $+1
		if attackNum > attackMax then attackNum = 1 end
	end

	actor.extravalue2 = 0 -- Reset for A_Repeat
	actor.state = RSR_CYBRAK_ATTACK_STATES[attackNum] or S_NULL
	if not Valid(actor) then
		print("\x82WARNING:\x80 Cybrak2016's attack state was not found! Debug this: "..tostring(attackNum))
		return
	end

	actor.cvmem = actor.cusval
	actor.cusval = attackNum
end

states[S_CYBRAK2016_TIMETOCHOOSE] =	{SPR_BRAK,	A,	0,	A_RSRCybrakRandomAttack,	0,	0,	S_CYBRAK2016_LMAO}

-- this used to also allow him to move backward while firing rockets, but all that did was make him back himself into too many corners

states[S_CYBRAK2016_ROCKETDIRECTION] =	{SPR_BRAK,	A,	0,	nil,	0,	0,	S_CYBRAK2016_ROCKET}

-- the dashing section

-- this randomises which dash he performs

A_RSRCybrakDashPrep = function(actor, var1, var2)
	if not Valid(actor) then return end

	A_FaceTarget(actor, 0, 0)
	A_PlaySound(actor, sfx_s3kc5s, 0+1<<16)
end

A_RSRCybrakDashSides = function(actor, var1, var2)
	if not Valid(actor) then return end

	A_PlaySound(actor, sfx_zoom, 0+1<<16)
	P_SpawnGhostMobj(actor)

	if P_RandomChance(FRACUNIT/2) then
		P_Thrust(actor, actor.angle - ANGLE_90, 40*actor.scale)
		return
	end

	P_Thrust(actor, actor.angle + ANGLE_90, 40*actor.scale)
end

A_RSRCybrakDashForward = function(actor, var1, var2)
	if not Valid(actor) then return end

	A_PlaySound(actor, sfx_zoom, 0+1<<16)
	P_SpawnGhostMobj(actor)
	P_Thrust(actor, actor.angle, 67*actor.scale)
end

states[S_CYBRAK2016_DASHPREP] =		{SPR_BRAK,	A,	16,	A_RSRCybrakDashPrep,	0,						0,							S_CYBRAK2016_DASHCHOICE}
states[S_CYBRAK2016_DASHCHOICE] =	{SPR_BRAK,	A,	0,	A_RandomState,			S_CYBRAK2016_DASHSIDES,	S_CYBRAK2016_DASHFORWARD,	S_CYBRAK2016_LMAO}

states[S_CYBRAK2016_DASHSIDES] =	{SPR_BRAK,	A,	30,	A_RSRCybrakDashSides,	0,	0,	S_CYBRAK2016_TIMETOCHOOSE}

-- forward dashing preparation since this one's a bit different

states[S_CYBRAK2016_DASHPREPF] =	{SPR_BRAK,	A,	16,	A_RSRCybrakDashPrep,	0,	0,	S_CYBRAK2016_DASHFORWARD}
states[S_CYBRAK2016_DASHFORWARD] =	{SPR_BRAK,	A,	30,	A_RSRCybrakDashForward,	0,	0,	S_CYBRAK2016_MELEE}

-- handles brak's stomp attack after the forward dash: look at target, play a sound, launch the projectiles, wait a moment

states[S_CYBRAK2016_MELEE] =		{SPR_BRAK,	E,	5,	A_FaceTarget,	0,							0,			S_CYBRAK2016_MELEE2}
states[S_CYBRAK2016_MELEE2] =		{SPR_BRAK,	F,	5,	A_FaceTarget,	0,							0,			S_CYBRAK2016_MELEESOUND}
states[S_CYBRAK2016_MELEESOUND] =	{SPR_BRAK,	G,	1,	A_PlaySound,	sfx_bestep,					0+1<<16,	S_CYBRAK2016_MELEESOUND2}
states[S_CYBRAK2016_MELEESOUND2] =	{SPR_BRAK,	G,	1,	A_PlaySound,	sfx_bestp2,					0+1<<16,	S_CYBRAK2016_MELEEATKHIT}
states[S_CYBRAK2016_MELEEATKHIT] =	{SPR_BRAK,	G,	1,	A_MultiShot,	32+MT_CYBRAK2016_SPARK<<16,	-40,		S_CYBRAK2016_MELEEATK}
states[S_CYBRAK2016_MELEEATK] =		{SPR_BRAK,	G,	0,	A_FaceTarget,	0,							0,			S_CYBRAK2016_TIMETOCHOOSE}

-- rocket spam forward: move, face target, fire, play stomp sound every so often, repeat; uses tons of states to animate his walk cycle (Not anymore! --MIDIMan)

A_RSRCybrakRocket = function(actor, var1, var2)
	if not Valid(actor) then return end

	P_InstaThrust(actor, actor.angle, 7*actor.scale)
	A_FaceTarget(actor, 0, 0)
	A_BrakFireShot(actor, MT_CYBRAKDEMON_MISSILE, 0)
	if var1 then
		local stepSound = sfx_bestep
		if var2 then
			stepSound = sfx_bestp2
		end
		A_PlaySound(actor, stepSound, 0+1<<16)
	end
end

states[S_CYBRAK2016_ROCKET] =		{SPR_BRAK,	B,	8,	A_RSRCybrakRocket,	0,	0,						S_CYBRAK2016_ROCKET2}
states[S_CYBRAK2016_ROCKET2] =		{SPR_BRAK,	C,	8,	A_RSRCybrakRocket,	0,	0,						S_CYBRAK2016_ROCKET3}
states[S_CYBRAK2016_ROCKET3] =		{SPR_BRAK,	D,	8,	A_RSRCybrakRocket,	1,	0,						S_CYBRAK2016_ROCKET4}
states[S_CYBRAK2016_ROCKET4] =		{SPR_BRAK,	E,	8,	A_RSRCybrakRocket,	0,	0,						S_CYBRAK2016_ROCKET5}
states[S_CYBRAK2016_ROCKET5] =		{SPR_BRAK,	F,	8,	A_RSRCybrakRocket,	0,	0,						S_CYBRAK2016_ROCKET6}
states[S_CYBRAK2016_ROCKET6] =		{SPR_BRAK,	G,	8,	A_RSRCybrakRocket,	1,	1,						S_CYBRAK2016_ROCKETREPEAT}
states[S_CYBRAK2016_ROCKETREPEAT] =	{SPR_BRAK,	B,	8,	A_Repeat,			2,	S_CYBRAK2016_ROCKET,	S_CYBRAK2016_TIMETOCHOOSE}

-- blade swing attack: face target, telegraph, play attack sound, launch destroyer blade

A_RSRCybrakSwing = function(actor, var1, var2)
	if not Valid(actor) then return end

	A_FaceTarget(actor, 0, 0)
	A_PlaySound(actor, sfx_bewar4, 0+1<<16)
end

A_RSRCybrakSlash = function(actor, var1, var2)
	if not Valid(actor) then return end

	A_FaceTarget(actor, 0, 0)
	A_PlaySound(actor, sfx_s3k5e, 0+1<<16)
	A_TrapShot(actor, MT_CYBRAK2016_SLASH, 0)
end

states[S_CYBRAK2016_SWING] =	{SPR_BRAK,	I,	28,	A_RSRCybrakSwing,	0,	0,	S_CYBRAK2016_SLASH}
states[S_CYBRAK2016_SLASH] =	{SPR_BRAK,	U,	27,	A_RSRCybrakSlash,	0,	0,	S_CYBRAK2016_TIMETOCHOOSE}

-- brak railgun attack: spawn the target marker, play a sound, give the player ample fucking warning, cave in their skull

states[S_CYBRAK2016_QUICKSCOPE] =	{SPR_BRAK,	H,	1,	A_VileTarget,	MT_CYBRAK2016_WATCHYOASS,	0,							S_CYBRAK2016_QUICKSOUND}
states[S_CYBRAK2016_QUICKSOUND] =	{SPR_BRAK,	H,	0,	A_PlaySound,	sfx_bechrg,					0+1<<16,					S_CYBRAK2016_QUICKCHARGE}
states[S_CYBRAK2016_QUICKCHARGE] =	{SPR_BRAK,	H,	1,	A_FaceTarget,	0,							0,							S_CYBRAK2016_QUICKREPEAT}
states[S_CYBRAK2016_QUICKREPEAT] =	{SPR_BRAK,	H,	1,	A_Repeat,		140,						S_CYBRAK2016_QUICKCHARGE,	S_CYBRAK2016_RAILGUN}
states[S_CYBRAK2016_RAILGUN] =		{SPR_BRAK,	H,	5,	A_BrakFireShot,	MT_CYBRAK2016_SLUG,			0,							S_CYBRAK2016_TIMETOCHOOSE}

-- target marker handler, just normal archvile attack things

states[S_CYBRAK2016_TARGET] =		{SPR_TARG,	A|FF_TRANS80,	1,	A_VileFire,	0,	0,						S_CYBRAK2016_TARGET2}
states[S_CYBRAK2016_TARGET2] =		{SPR_TARG,	A|FF_TRANS90,	1,	A_VileFire,	0,	0,						S_CYBRAK2016_TARGCHASE}
states[S_CYBRAK2016_TARGCHASE] =	{SPR_NULL,	A,				0,	A_Repeat,	70,	S_CYBRAK2016_TARGET,	S_NULL}

-- napalm: telegraph, drop the thing, wait a moment

states[S_CYBRAK2016_AIRSTRIKE] =	{SPR_BRAK,	A,	1,			A_FaceTarget,	0,									0,			S_CYBRAK2016_AIRSIREN}
states[S_CYBRAK2016_AIRSIREN] =		{SPR_BRAK,	A,	1*TICRATE,	A_PlaySound,	sfx_bewar3,							0+1<<16,	S_CYBRAK2016_AIRDROP}
states[S_CYBRAK2016_AIRDROP] =		{SPR_BRAK,	V,	8,			A_BrakLobShot,	MT_CYBRAKDEMON_NAPALM_BOMB_LARGE,	96,			S_CYBRAK2016_AIRCOVER}
states[S_CYBRAK2016_AIRCOVER] =		{SPR_BRAK,	A,	1,			A_FaceTarget,	0,									0,			S_CYBRAK2016_TIMETOCHOOSE}

-- pain: recover state is there to ensure he either forward dashes or back rockets after being whacked

A_RSRCybrakRecover = function(actor, var1, var2)
	if not Valid(actor) then return end

	actor.flags2 = $ & ~MF2_FRET
	A_RandomState(actor, var1, var2)
end

states[S_CYBRAK2016_BIGOWIE] =	{SPR_BRAK,	S,	1*TICRATE,	A_Pain,				0,							0,						S_CYBRAK2016_RECOVER}
states[S_CYBRAK2016_RECOVER] =	{SPR_BRAK,	S,	0,			A_RSRCybrakRecover,	S_CYBRAK2016_ROCKET,		S_CYBRAK2016_DASHPREPF,	S_CYBRAK2016_LMAO}

-- death lmao: wait 2 tics for some reason, explode 26 times, fall over; removes his flags so that he goes down the elevator if he dies on it

states[S_CYBRAK2016_ITDIES] =			{SPR_BRAK,	S,	2,	A_Repeat,		1,				S_CYBRAK2016_ITDIES,	S_CYBRAK2016_EXPLODE}
states[S_CYBRAK2016_EXPLODE] =			{SPR_BRAK,	S,	2,	A_BossScream,	0,				MT_SONIC3KBOSSEXPLODE,	S_CYBRAK2016_EXPLODEONLOOP}
states[S_CYBRAK2016_EXPLODEONLOOP] =	{SPR_BRAK,	S,	0,	A_Repeat,		54,				S_CYBRAK2016_EXPLODE,	S_CYBRAK2016_OOPS}
states[S_CYBRAK2016_OOPS] =				{SPR_BRAK,	N,	14,	A_PlaySound,	sfx_bedie2,		0,						S_CYBRAK2016_TEETER}
states[S_CYBRAK2016_TEETER] =			{SPR_BRAK,	O,	7,	nil,			0,				0,						S_CYBRAK2016_EEP}
states[S_CYBRAK2016_EEP] =				{SPR_BRAK,	P,	5,	nil,			0,				0,						S_CYBRAK2016_THEBIGGERTHEYARE}
states[S_CYBRAK2016_THEBIGGERTHEYARE] =	{SPR_BRAK,	Q,	3,	nil,			0,				0,						S_CYBRAK2016_THUNK}
states[S_CYBRAK2016_THUNK] =			{SPR_BRAK,	R,	-1,	A_BossDeath,	0,				0,						S_NULL}

-- unused back dash states

states[S_CYBRAK2016_DASHBACKP] =	{SPR_BRAK,	A,	1,	A_FaceTarget,	0,			0,			S_CYBRAK2016_DASHFACEB}
states[S_CYBRAK2016_DASHFACEB] =	{SPR_BRAK,	A,	20,	A_PlaySound,	sfx_s3kc5s,	0+1<<16,	S_CYBRAK2016_DASHFACEB2}
states[S_CYBRAK2016_DASHFACEB2] =	{SPR_BRAK,	A,	1,	A_PlaySound,	sfx_zoom,	0+1<<16,	S_CYBRAK2016_DASHBACK}
states[S_CYBRAK2016_DASHBACK] =		{SPR_BRAK,	A,	40,	A_Thrust,		-40,		0,			S_CYBRAK2016_LMAO}

-- railgun slug state

states[S_CYBRAK2016_SSPAWN] =	{SPR_JETF,	A,	1,	A_SetObjectFlags2,	MF2_RAILRING,	2,	S_CYBRAK2016_SSPAWN}

-- destroyer blade state

states[S_CYBRAK2016_SLASH1] =	{SPR_CBSW,	A,	1,	nil,	0,	0,	S_CYBRAK2016_SLASH1}
