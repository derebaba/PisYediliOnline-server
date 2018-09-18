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
  cards = shuffle(cards)

  print(("match_init sid: %s"):format(context.session_id))

  local playerPresences = {}
  for i = 1, #setupstate.expected_users, 1 do
	table.insert(playerPresences, setupstate.expected_users[i].presence)
  end

  for k, v in pairs(context) do
	print(("context k: %s, v:%s"):format(k, v))
  end

  local gamestate = {
    presences = playerPresences
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
  for _, presence in ipairs(presences) do
	state.presences[presence.session_id] = presence
	print(("Joined match sid: %s"):format(presence.session_id))
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
	print(("Presence %s match: %s"):format(presence.session_id, context.match_id))
    for key, value in ipairs(presence) do
      print(("k: %s v: %s"):format(key, value))
    end
  end
  for _, message in ipairs(messages) do
    print(("Received %s from %s"):format(message.sender.username, message.data))
    local decoded = nk.json_decode(message.data)
    for k, v in pairs(decoded) do
      print(("Message key %s contains value %s"):format(k, v))
    end
    -- PONG message back to sender
    dispatcher.broadcast_message(1, message, message.sender.session_id, nil)
  end
  return state
end

return M
