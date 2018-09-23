local nk = require("nakama")

local function matchmaker_matched(context, matchmaker_users)
	if #matchmaker_users ~= 2 then
		return nil
	end

	return nk.match_create("match", {debug = true, presences = matchmaker_users})
end

nk.register_matchmaker_matched(matchmaker_matched)
