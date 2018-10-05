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
	print(("playCard - %s played %s"):format(message.sender.username, nk.json_decode(message.data)))

end


return mh