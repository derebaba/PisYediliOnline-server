local nk = require("nakama")

local mh = {}

local giveCardToPresence = function (state, dispatcher, presence)
	local card = table.remove(state.deck)

	table.insert(presence.cards, card)

	dispatcher.broadcast_message(2, nk.json_encode(card), {presence})

	dispatcher.broadcast_message(3, nk.json_encode(presence.direction))
end

function mh.drawCard(context, dispatcher, tick, state, message)
	local senderPresence = state.presences[message.sender.session_id];

	giveCardToPresence(state, dispatcher, senderPresence)
end

function mh.playCard(context, dispatcher, tick, state, message)
	local card = nk.json_decode(message.data)

	print(("playCard - %s played %s"):format(message.sender.username, card))

	state.turnCount = state.turnCount + 1

	local senderPresence = state.presences[message.sender.session_id];

	for i = 1, #senderPresence.cards, 1 do
		if (senderPresence.cards[i] == card) then
			table.insert(state.pile, table.remove(senderPresence.cards, i))
			break
		end
	end

	local playCardMessage = {
		playerDirection = state.turn,
		cardId = card
	}
	dispatcher.broadcast_message(4, nk.json_encode(playCardMessage))

	print("play card - state.directions", nk.json_encode(state.directions))

	local nextPlayerDirection = state.directions[((state.turnCount - 1) % #state.players) + 1]
	state.turn = nextPlayerDirection
	state.mustDraw = 0

	local passTurnMessage = {
		direction = nextPlayerDirection,
		mustDraw = state.mustDraw
	}
	print(("playCard - pass turn message: %s"):format(nk.json_encode(passTurnMessage)))

	if (card % 13 == 0) then
		--local drawingPlayer = state.players[]
	end

	dispatcher.broadcast_message(5, nk.json_encode(passTurnMessage))
end


return mh