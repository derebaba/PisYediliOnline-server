local nk = require("nakama")

local mh = {}

function mh.drawCard(context, dispatcher, tick, state, message)
	local drawCardMessage = {
		card = table.remove(state.deck)
	}

	local senderPresence = state.presences[message.sender.session_id];
	table.insert(senderPresence.cards, drawCardMessage.card)

	dispatcher.broadcast_message(2, nk.json_encode(drawCardMessage), {senderPresence})

	dispatcher.broadcast_message(3, nk.json_encode(senderPresence.direction))
end

return mh