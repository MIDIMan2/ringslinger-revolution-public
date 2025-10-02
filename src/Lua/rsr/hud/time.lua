-- Ringslinger Revolution - Time HUD

RSR.TIME_TO_RACENUM = {
	"RACE1",
	"RACE2",
	"RACE3"
}

--- Port of P_AutoPause, which is used in the racenum drawing code.
---@return boolean
RSR.AutoPause = function()
	-- Don't pause even on menu-up or focus-lost in netgames or record attack
	if netgame or modeattacking or gamestate == GS_TITLESCREEN or (marathonmode and gamestate == GS_INTERMISSION) then
		return false
	end

	return menuactive -- Can't use window_notinfocus
end

--- Draws the Race countdown to the HUD.
---@param time tic_t
RSR.HUDRaceNum = function(v, time)
	if not v then return end
	time = $ or 0

	local height, bounce = 0, 0
	local racenum = nil

	time = $+TICRATE
	height = ((3*200)/4) - 8
	bounce = TICRATE - (1 + (time % TICRATE))

	if RSR.TIME_TO_RACENUM[time/TICRATE] then
		racenum = RSR.TIME_TO_RACENUM[time/TICRATE]
	else
		racenum = "RACEGO"
	end

	if bounce < 3 then
		height = $ - (2 - bounce)
		if not (RSR.AutoPause() or paused) and not bounce then
			S_StartSound(nil, racenum == "RACEGO" and sfx_s3kad or sfx_s3ka7)
		end
	end
	racenum = v.cachePatch($)
	v.draw((320 - racenum.width)/2, height, racenum, V_PERPLAYER)
end

-- This function borrows a LOT from ST_drawTime in st_stuff.c in SRB2's source code
--- Draws the player's current time to the HUD.
---@param player player_t
RSR.HUDTime = function(v, player)
	if not RSR.GamemodeActive() then return end
	if not (v and Valid(player)) then return end

	local seconds, minutes, tictrn, tics = 0, 0, 0, 0
	local downwards = false

	local hidetime = CV_FindVar("hidetime").value

	-- objectplacing is not exposed, so ignore it

	-- Counting down the hidetime?
	if (gametyperules & GTR_STARTCOUNTDOWN) and player.realtime <= hidetime*TICRATE then
		tics = (hidetime*TICRATE - player.realtime)
		if tics < 3*TICRATE then
			RSR.HUDRaceNum(v, tics)
		end
		tics = $+(TICRATE-1) -- Match the race num
		downwards = true
	else
		-- Hidetime finish!
		if (gametyperules & GTR_STARTCOUNTDOWN) and player.realtime < (hidetime+1)*TICRATE then
			RSR.HUDRaceNum(v, hidetime*TICRATE - player.realtime)
		end

		local timelimitintics = timelimit * 60 * TICRATE
		if G_TagGametype() then
			timelimitintics = $ + (hidetime * TICRATE)
		end

		-- Time limit?
		if (gametyperules & GTR_TIMELIMIT) and timelimit then
			if timelimitintics > player.realtime then
				tics = timelimitintics - player.realtime
				if tics < 3*TICRATE then
					RSR.HUDRaceNum(v, tics)
				end
				tics = $ + (TICRATE-1) -- match the race num
			else -- Overtime!
				tics = 0
			end
			downwards = true
		-- Post-hidetime normal.
		elseif (gametyperules & GTR_STARTCOUNTDOWN) then
			tics = player.realtime - hidetime*TICRATE
		elseif mapheaderinfo[gamemap].countdown then
			local maxtime = 0
			tics = mapheaderinfo[gamemap].countdown * TICRATE
			for player in players.iterate() do
				if not Valid(player) then continue end
				if player.starposttime > maxtime then
					maxtime = player.starposttime
				end
				tics = $-maxtime
			end
			downwards = true
		else
			tics = player.realtime
		end
	end

	minutes = G_TicsToMinutes(tics, true)
	seconds = G_TicsToSeconds(tics)
	tictrn = G_TicsToCentiseconds(tics)

	downwards = ($ and (tics < 30*TICRATE) and (leveltime/5 & 1) and not stoppedclock) -- overtime?

	local vFlags = V_SNAPTOLEFT|V_SNAPTOTOP|V_HUDTRANS|V_PERPLAYER
	local timePatch = "RSRTIME"
	if downwards then timePatch = "RSRRTIME" end
	v.draw(6, 3, v.cachePatch(timePatch), vFlags)

	if downwards then return end -- overtime!

	local timetic = CV_FindVar("timerres").value -- This console variable is cv_timetic internally, because consistency is overrated
	local timeX = 40
	if timetic == 3 then
		v.drawNum(timeX + 24, 3, tics, vFlags)
	else
		v.drawNum(timeX, 3, minutes, vFlags)
		v.draw(timeX, 3, v.cachePatch("STTCOLON"), vFlags)
		v.drawPaddedNum(timeX + 24, 3, seconds, 2, vFlags)

		if timetic == 1 or timetic == 2 or modeattacking or marathonmode then
			v.draw(timeX + 24, 3, v.cachePatch("STTPERIO"), vFlags)
			v.drawPaddedNum(timeX + 48, 3, tictrn, 2, vFlags)
		end
	end
end
