--!strict
-- The maps the spike rounds are played on (system 25), by key: Outpost, the
-- small one (MatchMap), and Quarry and Foundry, for five a side. A server
-- playing the spike rounds starts its first match on one of them at random,
-- and after each match's victory screen everyone votes for the next
-- (MatchRules, MapVote), as in Skirmish. Each is built at its own origin,
-- all at once, so a new map is only a matter of where everyone spawns.

local Foundry = require("./Foundry")
local MapPlan = require("./MapPlan")
local MatchMap = require("./MatchMap")
local Quarry = require("./Quarry")

local SpikeMaps = {}

-- By key, which is each map's LAYOUT too.
SpikeMaps.Maps = {
	outpost = MatchMap,
	quarry = Quarry,
	foundry = Foundry,
} :: { [string]: MapPlan.Map }

-- The keys, in the order the vote shows them.
SpikeMaps.MAPS = { "outpost", "quarry", "foundry" }

return SpikeMaps
