local nk = require("nakama")

local mh = {}

local function shuffleTable(tbl)
	local size = #tbl
	for i = size, 1, -1 do
		local rand = math.random(size)
		tbl[i], tbl[rand] = tbl[rand], tbl[i]
	end
	return tbl
end

local giveCardToPresence = function (state, dispatcher, presence, cardCountToBeDrawn)

	local drawnCards = {}
	for i = 1, cardCountToBeDrawn, 1 do
		local card = table.remove(state.deck)
		table.insert(drawnCards, card)
		table.insert(presence.cards, card)
	end

	state.pile7Count = 0
	state.lastCardA = false

	local cardDrawMessage = {
		drawnCards = drawnCards
	}

	dispatcher.broadcast_message(2, nk.json_encode(cardDrawMessage), {presence})

	local cardDrawBroadcastMessage = {
		direction = presence.direction,
		cardCount = cardCountToBeDrawn,
		deckSize = #state.deck
	}

	dispatcher.broadcast_message(3, nk.json_encode(cardDrawBroadcastMessage))
end

function mh.drawCard(context, dispatcher, tick, state, message)
	local cardCountToBeDrawn = nk.json_decode(message.data)
	local senderPresence = state.presences[message.sender.session_id];

	giveCardToPresence(state, dispatcher, senderPresence, cardCountToBeDrawn)
end

function mh.playCard(context, dispatcher, tick, state, message)
	local playCardMessage = nk.json_decode(message.data)

	print(("playCardMessage received from %s: %s"):format(message.sender.username, message.data))

	local card = playCardMessage.cardId;
	local senderPresence = state.presences[message.sender.session_id];

	for i = 1, #senderPresence.cards, 1 do
		if (senderPresence.cards[i] == card) then
			table.insert(state.pile, table.remove(senderPresence.cards, i))
			break
		end
	end

	dispatcher.broadcast_message(4, nk.json_encode(playCardMessage))

	if (state.turnCount > #state.players) then
		local pile7Count = state.pile7Count
		state.pile7Count = 0
		state.lastCardA = false
		state.jiletSuit = playCardMessage.jiletSuit
		--	not first round
		if (card % 13 == 0) then
			state.lastCardA = true;
		elseif (card % 13 == 6) then
			state.pile7Count = pile7Count + 1
		elseif (card % 13 == 9) then
			state.clockwise = not state.clockwise
		elseif (card % 13 == 0) then
		end
	end

	mh.endTurn(context, dispatcher, tick, state, message)
end

function mh.endTurn(context, dispatcher, tick, state, message)
	
	state.turnCount = state.turnCount + 1

	if (state.clockwise) then
		state.directionIndex = state.directionIndex + 1

		if (state.directionIndex == #state.players + 1) then
			state.directionIndex = 1
		end
	else
		state.directionIndex = state.directionIndex - 1

		if (state.directionIndex == 0) then
			state.directionIndex = #state.players
		end
	end

	state.turn = state.directions[state.directionIndex]

	local passTurnMessage = {
		direction = state.turn,
		pile7Count = state.pile7Count,
		lastCardA = state.lastCardA,
		turnCount = state.turnCount
	}
	print(("end turn message: %s"):format(nk.json_encode(passTurnMessage)))

	dispatcher.broadcast_message(5, nk.json_encode(passTurnMessage))
end

function mh.shuffle(context, dispatcher, tick, state, message)

	local topCard = table.remove(state.pile)

	local size = #state.pile
	for i = size, 1, -1 do
		local rand = math.random(size)
		state.pile[i], state.pile[rand] = state.pile[rand], state.pile[i]
	end

	state.deck = state.pile
	state.pile = {}
	-- mem leak might occur
	table.insert(state.pile, topCard)

	print("deck size: ", #state.deck)
	print("pile size: ", #state.pile)

	local shuffleMessage = {
		deckSize = #state.deck,
		topCard = topCard
		-- topSuit will be used when jilet gets integrated
	}

	dispatcher.broadcast_message(6, nk.json_encode(shuffleMessage))
end


return mh