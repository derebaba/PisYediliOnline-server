local nk = require("nakama")

local function matchmaker_matched(context, matchmaker_users)
	return nk.match_create("match", {debug = true, presences = matchmaker_users})
end

nk.register_matchmaker_matched(matchmaker_matched)
