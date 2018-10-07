local nk = require("nakama")

local mh = {}

function mh.drawCard(context, dispatcher, tick, state, message)
	local card = table.remove(state.deck)

	local senderPresence = state.presences[message.sender.session_id];
	table.insert(senderPresence.cards, card)

	dispatcher.broadcast_message(2, nk.json_encode(card), {senderPresence})

	dispatcher.broadcast_message(3, nk.json_encode(senderPresence.direction))
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

	dispatcher.broadcast_message(4, message.data)

	print("play card -- state.directions", nk.json_encode(state.directions))
	print(("playCard - next player: %s"):format(state.directions[(state.turnCount % #state.players) + 1]))

	local nextPlayerDirection = state.directions[(state.turnCount % #state.players) + 1]

	dispatcher.broadcast_message(5, nk.json_encode(nextPlayerDirection))
end


return mh