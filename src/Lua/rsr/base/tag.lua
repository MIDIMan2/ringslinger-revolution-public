-- Ringslinger Revolution - Tag Gametype Adjustments

--[[
Tag in RSR has its own rules:
- The number of seekers scales with how many players there are in a game (1 seeker for every 6 players).
- Hiders have a debuff that makes them take 1.5x more damage and prevents them from crit healing.
- If hiders get killed by their own explosives, they become seekers.
]]

RSR.TAG_HIDERRATIO = 6

--- Lua reimplementation of P_CheckSurvivors, since it's not exposed to Lua.
---@param player player_t|nil
RSR.TagCheckSurvivors = function(player)
	local survivors = 0
	local taggers = 0
	local spectators = 0
	local numPlayers = 0
	local survivorIndex = 0
	local survivorArray = {}

	for curPlayer in players.iterate do
		if not Valid(curPlayer) then continue end
		if curPlayer.spectator then
			spectators = $+1
		elseif (curPlayer.pflags & PF_TAGIT) and curPlayer.quittime < 30*TICRATE then
			taggers = $+1
		elseif not (curPlayer.pflags & PF_GAMETYPEOVER) and curPlayer.quittime < 30*TICRATE then
			table.insert(survivorArray, #curPlayer)
			survivors = $+1
			if Valid(player) and player == curPlayer then
				survivorIndex = survivors
			end
		end
		numPlayers = $+1
	end

	if numPlayers <= 0 then return end -- Don't go any further if no players were found.

	if not taggers then --If there are no taggers, pick a survivor at random to be it.
		--Exception for hide and seek. If a round has started and the IT player leaves, end the round.
		if (gametyperules & GTR_HIDEFROZEN) and leveltime >= (CV_FindVar("hidetime").value * TICRATE) then
			print("The IT player has left the game.")
			if server then COM_BufInsertText(server, "exitlevel") end
			return
		end

		if survivors then
			if not survivorIndex then survivorIndex = P_RandomKey(survivors) + 1 end
			local newTagger = survivorArray[survivorIndex]

			print(players[newTagger].name.." is now IT!") -- Tell everyone who is it!
			players[newTagger].pflags = $|PF_TAGIT

			survivors = $-1 --Get rid of the player we just made IT.

			--Yeah, we have an eligible tagger, but we may not have anybody for them to tag!
			--If there is only one player waiting on the game to fill or spectators to enter the game, don't bother.
			if not survivors and (numPlayers - spectators) > 1 then
				print("All players have been tagged!")
				if server then COM_BufInsertText(server, "exitlevel") end
			end

			return
		end

		--If we reach this point, no player can replace the one that was IT.
		--Unless it is one player waiting on a game, end the round.
		if (numPlayers - spectators) > 1 then
			print("There are no players able to become IT.")
			if server then COM_BufInsertText(server, "exitlevel") end
		end

		return
	end

	if survivors and RSR.TAG_HIDERRATIO > 1 then
		local numTaggers = ((taggers + survivors - 1) / RSR.TAG_HIDERRATIO) + 1 -- Calculate the number of taggers there should be in the map (including the one already in the map)
		local taggedOne = false
		while taggers < numTaggers do -- Turn some survivors into taggers
			if not survivorIndex or taggedOne then
				survivorIndex = P_RandomKey(survivors) + 1
				taggedOne = true
			end
			local newTagger = survivorArray[survivorIndex]

			print(players[newTagger].name.." is now IT!") -- Tell everyone who is it!
			players[newTagger].pflags = $|PF_TAGIT

			survivors = $-1 --Get rid of the player we just made IT.
			table.remove(survivorArray, survivorIndex) -- Remove that player from the survivor array so we don't mark the same player as a tagger.

			taggers = $+1
		end
	end

	--If there are taggers, but no survivors, end the round.
	--Except when the tagger is by themself and the rest of the game are spectators.
	if not survivors and (numPlayers - spectators) > 1 then
		print("All players have been tagged!")
		if server then COM_BufInsertText(server, "exitlevel") end
	end
end

--- Partial Lua port of P_InitTagGametype that accounts for RSR Tag's seeker count rules.
RSR.TagMapLoad = function()
	if not (RSR.GamemodeActive() and G_TagGametype()) then return end -- Only run this in RSR Tag/H&S maps
	local numPlayers = 0
	local survivorsActive = {}

	-- Check for active survivors (ingame, not spectator, not quitting)
	for player in players.iterate do
		if not Valid(player) then continue end
		if player.spectator or player.quittime then continue end
		if not (player.pflags & PF_TAGIT) then table.insert(survivorsActive, #player) end -- Only count hiders in the table
		numPlayers = $+1
	end

	if not numPlayers then return end -- Let P_InitTagGametype handle the "No players available" message
	if RSR.TAG_HIDERRATIO < 2 then return end -- This will make everyone a seeker, so don't do that

	local numTaggers = (numPlayers - 1) / RSR.TAG_HIDERRATIO -- For every 6 players, there should be 1 tagger.
	while numTaggers > 0 do
		local randomIndex = P_RandomKey(#survivorsActive) + 1
		players[survivorsActive[randomIndex]].pflags = $|PF_TAGIT
		table.remove(survivorsActive, randomIndex)
		numTaggers = $-1
	end
end
