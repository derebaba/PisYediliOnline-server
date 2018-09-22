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
	local cards = {}
	for i = 1, 52, 1
	do
		table.insert(cards, i)
	end
	local deck = shuffle(cards)

	print(("match_init match_id: %s"):format(context.match_id))

	local gamestate = {
		presences = {},
		deck = deck
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

	print(#presences)

	local directions = {}
	for i = 1, 4, 1
	do
		table.insert(directions, i)
	end

	directions = shuffle(directions)

	local turn = directions[0]

	local players = {}

	for _, presence in ipairs(presences) do
		local cards = {}
		for i = 1, 7, 1 do
			table.insert(cards, table.remove(state.deck))
		end

		presence.cards = cards;
		presence.direction = table.remove(directions)
		if(turn == presence.direction) then
			table.insert(cards, table.remove(state.deck))
		end

		local player = {
			cards = #presence.cards,
			direction = presence.direction,
			username = presence.username
		}
		table.insert(players, player)
	end

	for index, presence in ipairs(presences) do
		state.presences[presence.session_id] = presence

		local message = {
			cards = presence.cards,
			players = players,
			turn = turn,
			deckSize = 52 - #presences * 7 - 1
		}

		print(("message: %s"):format(nk.json_encode(message)))

		dispatcher.broadcast_message(1, nk.json_encode(message), {presence})
	end

	return state
end

function M.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = nil
	end
	return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
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
