--!strict
-- The round-end callouts (system 56): what makes each of ACE, TEAM ACE,
-- FLAWLESS, CLUTCH and THRIFTY, which one a round won with several gets,
-- the sides too small for them, deaths that don't count, a life brought
-- back and someone leaving, what each side's banner says, and what a
-- loadout's worth.

local RoundCallouts = require("../src/shared/Match/RoundCallouts")
local H = require("./Harness")

local check = H.check

H.section("Round-end callouts (system 56)")

local P = RoundCallouts.Params
local decide = RoundCallouts.decide

-- Players: A, B and C on side 1, X, Y and Z on side 2.
local A, B, C, X, Y, Z = 1, 2, 3, 11, 12, 13

-- A round gone live with these on side 1 and these on side 2.
local function live(ours: { number }, theirs: { number }, worth: { [number]: number }?): RoundCallouts.Round
	local sides: { [number]: number } = {}
	for _, id in ours do
		sides[id] = 1
	end
	for _, id in theirs do
		sides[id] = 2
	end
	return RoundCallouts.begin(sides, worth)
end

local died = RoundCallouts.died

do
	local r = live({ A, B }, { X, Y })
	died(r, X, A)
	died(r, Y, A)
	check("one of the winners killing every enemy is an ace", decide(r, 1) == "ace")

	r = live({ A, B, C }, { X, Y, Z })
	died(r, X, A)
	died(r, Y, A)
	died(r, Z, B)
	check("not when someone else killed one of them", decide(r, 1) ~= "ace")

	r = live({ A, B }, { X, Y })
	died(r, X, A)
	died(r, Y, nil)
	check("nor when one died with nobody killing them", decide(r, 1) ~= "ace")

	r = live({ A, B }, { X, Y })
	died(r, B, X)
	died(r, X, A)
	died(r, Y, A)
	check("a teammate killed first leaves it an ace", decide(r, 1) == "ace")
end

do
	local r = live({ A, B, C }, { X, Y, Z })
	died(r, X, A)
	died(r, Y, B)
	died(r, B, Z)
	died(r, Z, C)
	check("each of the winners killing an enemy is a team ace, even one who died after", decide(r, 1) == "teamAce")

	r = live({ A, B, C }, { X, Y })
	died(r, X, A)
	died(r, Y, B)
	check("against fewer, as many of them killing one as there were enemies", decide(r, 1) == "teamAce")

	r = live({ A, B, C }, { X, Y, Z })
	died(r, C, X)
	died(r, X, A)
	died(r, Y, B)
	died(r, Z, nil)
	check("not if one of them killed nobody", decide(r, 1) == nil)

	r = live({ A, B }, { X, Y })
	died(r, X, A)
	died(r, A, B)
	died(r, Y, nil)
	check("killing a teammate isn't a kill for it", decide(r, 1) == nil)
end

do
	local r = live({ A, B, C }, { X, Y, Z })
	died(r, X, A)
	died(r, Y, B)
	died(r, Z, nil)
	check("none of the winners dying is a flawless", decide(r, 1) == "flawless")

	r = live({ A, B }, { X, Y })
	check("so is a round won with nobody dying, as on time", decide(r, 2) == "flawless")

	r = live({ A, B, C }, { X, Y, Z })
	died(r, A, X)
	RoundCallouts.revived(r, A)
	died(r, X, B)
	died(r, Y, C)
	died(r, Z, nil)
	check("a winner brought back still died: no flawless", decide(r, 1) == nil)
end

do
	local r = live({ A, B }, { X, Y })
	died(r, A, X)
	died(r, X, B)
	died(r, Y, nil)
	check("the winners down to their last against two, and winning, is a clutch", decide(r, 1) == "clutch")

	r = live({ A }, { X, Y })
	died(r, X, A)
	died(r, Y, nil)
	check("so is a win alone from the start against two", decide(r, 1) == "clutch")

	r = live({ A, B }, { X, Y })
	died(r, X, nil)
	died(r, A, Y)
	died(r, Y, B)
	check("but not from one against one", decide(r, 1) == nil)

	r = live({ A, B }, { X, Y })
	died(r, X, nil)
	died(r, A, Y)
	RoundCallouts.revived(r, X)
	died(r, Y, B)
	died(r, X, nil)
	check("one against one becomes one against two as an enemy's brought back", decide(r, 1) == "clutch")

	r = live({ A, B, C }, { X, Y })
	RoundCallouts.left(r, A)
	died(r, B, X)
	died(r, X, C)
	died(r, Y, nil)
	check("someone leaving is out of it: the side's down to its last sooner", decide(r, 1) == "clutch")
end

do
	local full, eco = RoundCallouts.worth({ "vandal", "classic", "heavy" }), RoundCallouts.worth({ "", "classic", "" })
	local gap = P.thrifty.value
	-- Nothing else holds: X killed, then A, and Y down with nobody killing them.
	local function played(worth: { [number]: number }?): RoundCallouts.Round
		local r = live({ A, B }, { X, Y }, worth)
		died(r, X, A)
		died(r, A, Y)
		died(r, Y, nil)
		return r
	end
	check(
		"the winners' loadouts worth 2500 less on average is thrifty",
		decide(played({ [A] = eco, [B] = 800, [X] = full, [Y] = full }), 1) == "thrifty"
	)
	check(
		"from exactly that much",
		decide(played({ [A] = 0, [B] = 0, [X] = gap, [Y] = gap }), 1) == "thrifty"
			and decide(played({ [A] = 1, [B] = 0, [X] = gap, [Y] = gap }), 1) == nil
	)
	check(
		"averaged over each side: one loadout that much cheaper isn't",
		decide(played({ [A] = 0, [B] = 4000, [X] = 4000, [Y] = 4000 }), 1) == nil
	)
	check("and not where nothing's bought", decide(played(nil), 1) == nil)
end

do
	local r = live({ A, B }, { X, Y }, { [A] = 0, [B] = 0, [X] = 9000, [Y] = 9000 })
	died(r, X, A)
	died(r, Y, A)
	check("an ace comes before a flawless and thrifty", decide(r, 1) == "ace")

	r = live({ A, B }, { X, Y })
	died(r, X, A)
	died(r, Y, B)
	check("a team ace before a flawless", decide(r, 1) == "teamAce")

	r = live({ A, B, C }, { X, Y, Z })
	died(r, A, X)
	died(r, B, X)
	died(r, X, C)
	died(r, Y, C)
	died(r, Z, C)
	check("an ace before a clutch", decide(r, 1) == "ace")

	r = live({ A }, { X, Y }, { [A] = 0, [X] = 9000, [Y] = 9000 })
	died(r, X, A)
	died(r, Y, nil)
	check("a clutch before thrifty", decide(r, 1) == "clutch")
end

do
	local r = live({ A }, { X })
	died(r, X, A)
	check("one a side, a round won by a kill has none", decide(r, 1) == nil)

	r = live({ A }, { X, Y })
	died(r, X, A)
	died(r, Y, A)
	check("one killing both of two is an ace", decide(r, 1) == "ace")

	r = live({ A, B }, { X })
	died(r, X, A)
	check("two against one won without dying is a flawless, but no ace or team ace", decide(r, 1) == "flawless")
end

do
	local r = live({ A, B }, { X, Y })
	died(r, X, A)
	died(r, X, B)
	died(r, Y, A)
	died(r, Z, A)
	check("a death not in the round, or a second, changes nothing", r.kills[B] == nil and decide(r, 1) == "ace")
end

do
	local title = RoundCallouts.title
	check("the winners' banner names the callout", title("ace", true) == "ACE" and title("teamAce", true) == "TEAM ACE")
	check("or reads ROUND WON without one", title(nil, true) == "ROUND WON")
	check("the losers' reads ROUND LOST", title(nil, false) == "ROUND LOST" and title("ace", false) == "ROUND LOST")
	check("but they're shown a flawless too", title("flawless", false) == "FLAWLESS" and title("flawless", true) == "FLAWLESS")
	check("and not a clutch or thrifty", title("clutch", false) == "ROUND LOST" and title("thrifty", false) == "ROUND LOST")
end

do
	local worth = RoundCallouts.worth
	check("a loadout's worth is its guns' and shield's prices", worth({ "vandal", "sheriff", "heavy" }) == 2900 + 800 + 1000)
	check("an empty slot, the Classic and the knife are worth nothing", worth({ "", "classic", "knife" }) == 0)
	check("nor is what isn't sold", worth({ "spike", "kunai" }) == 0)
end

do
	local ok = true
	for _, param in P do
		ok = ok and (param.status == "confirmed" or param.status == "community" or param.status == "estimate") and #param.source > 0
	end
	check("every number carries a status and a source", ok)
end

return nil
