local nk = require("nakama")

local M = {}

--  https://gist.github.com/Uradamus/10323382
local function shuffle(tbl)
	local size = #tbl
	for i = size, 1, -1 do
		local rand = math.random(size)
		tbl[i], tbl[rand] = tbl[rand], tbl[i]
	end
	return tbl
end

function M.match_init(context, setupstate)
	print(("match_init match_id: %s"):format(context.match_id))
	--	initialize deck and shuffle
	local deck = {}
	for i = 0, 51, 1 do
		table.insert(deck, i)
	end
	deck = shuffle(deck)
	--	end initialize deck

	print("match_init number of players: ", #setupstate.presences)
	local directions = {}
	for i = 0, #setupstate.presences - 1, 1
	do
		table.insert(directions, i)
	end

	directions = shuffle(directions)

	local turn = directions[1]	--	first direction to start (1 is first index in Lua)

	local players = {}	--	players will be sent as a message

	--	deal cards to everyone
	for _, presence in ipairs(setupstate.presences) do
		presence = presence.presence
		setupstate.presences[presence.session_id] = presence

		local cards = {}
		for i = 1, 7, 1 do
			table.insert(cards, table.remove(deck))
		end

		presence.cards = cards;
		presence.direction = table.remove(directions)

		--	first player gets +1 card
		if(turn == presence.direction) then
			table.insert(cards, table.remove(deck))
		end

		local player = {
			cardCount = #presence.cards,
			direction = presence.direction,
			username = presence.username
		}
		table.insert(players, player)
	end

	print("match_init setupstate.presences: ", nk.json_encode(setupstate.presences))
	--	initialize gamestate
	local gamestate = {
		presences = setupstate.presences,
		deck = deck,
		players = players,
		turn = turn,
		pile = {}
	}
	local tickrate = 1 -- per sec
	local label = ""
	return gamestate, tickrate, label
end

function M.match_join_attempt(context, dispatcher, tick, state, presence)
	local acceptuser = true
	return state, acceptuser
end

function M.match_join(context, dispatcher, tick, state, presences)
	local presence = table.remove(presences)	--	this is supposed to be the only presence
	print("match_join presence: ", nk.json_encode(presence))
	local gameStartMessage = {
		cards = state.presences[presence.session_id].cards,
		players = state.players,
		turn = state.turn,
		deckSize = #state.deck
	}

	print(("message: %s"):format(nk.json_encode(gameStartMessage)))

	dispatcher.broadcast_message(1, nk.json_encode(gameStartMessage), {presence})
	return state
end

function M.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = nil
	end
	return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
	--[[
	if (#state.presences < state.required_player_count) then
		nk.logger_info(("Not enough players yet have %q need %q."):format(#state.presences, state.required_player_count))
		if (ticks > 2400) then
			nk.logger_info("Not enough players joined after 2400 ticks. Match stopped.")
			return nil
		end
		return state
	end
	]]--
	for _, presence in pairs(state.presences) do
		--print(("Presence %s match: %s"):format(presence.session_id, context.match_id))
	end
	for _, message in ipairs(messages) do
		print(("Received %s from %s"):format(message.sender.username, message.data))
		local decoded = nk.json_decode(message.data)
		for k, v in pairs(decoded) do
			print(("Message key %s contains value %s"):format(k, v))
		end
		-- PONG message back to sender
		dispatcher.broadcast_message(1, message.data, {state.presences[message.sender.session_id]})
	end
	return state
end

return M
