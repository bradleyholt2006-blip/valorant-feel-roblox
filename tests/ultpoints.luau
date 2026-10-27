--!strict
-- The ultimate's points across a match of the spike rounds (system 50):
-- which kind of start each round is (MatchRules.roundKind), and how that
-- start sets the points (AbilitySim.roundPoints), as AbilityServer runs
-- them after the kit's own: a match's or a half's first starts them over,
-- at none or at Swiftplay's two; an overtime round puts everyone three
-- short of full; and any other pays what the last round's deaths earned.

local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local MatchConfig = require("../src/shared/Match/MatchConfig")
local MatchRules = require("../src/shared/Match/MatchRules")
local H = require("./Harness")

local check = H.check

local P = AbilityConfig.Points
local STANDARD = MatchConfig.Formats.standard
local COMPETITIVE = MatchConfig.Formats.competitive
local SWIFT = MatchConfig.Formats.swiftplay
local C, Q, E = AbilityConfig.C, AbilityConfig.Q, AbilityConfig.E

-- A kit of `agent`'s with `points` of its ultimate.
local function kit(agent: string, points: number): AbilitySim.State
	local k = AbilitySim.new(agent)
	k.points = points
	return k
end

-- A round of kind `kind` starting for `k`, as AbilityServer.roundStarted
-- has it: the kit's own start, then its points. Returns the points.
local function started(k: AbilitySim.State, kind: AbilitySim.RoundKind, owed: number, swiftplay: boolean): number
	if kind == "match" then
		AbilitySim.reset(k)
	elseif kind == "half" then
		AbilitySim.newHalf(k)
	else
		AbilitySim.newRound(k)
	end
	AbilitySim.roundPoints(k, kind, owed, swiftplay)
	return k.points
end

H.section("The ultimate's points across a match (system 50)")

-- The numbers ------------------------------------------------------------------

check(
	"Swiftplay starts each half on 2 points, 3 for an ultimate of 9 (Patches 5.12 and 10.10)",
	P.swiftplay.value == 2 and P.swiftplay.status == "confirmed" and P.swiftplayNine.value == 3 and P.swiftplayNine.status == "confirmed"
)
check(
	"an overtime round puts everyone 3 short of full (community; Patch 1.03 had 4)",
	P.overtimeShort.value == 3 and P.overtimeShort.status == "community"
)
check("a death is still worth a point", P.death.value == 1)

-- Which start each round is ------------------------------------------------------

do
	local function kinds(format: MatchConfig.Format, rounds: { number }): string
		local out = {}
		for _, round in rounds do
			table.insert(out, MatchRules.roundKind(format, round))
		end
		return table.concat(out, " ")
	end
	check(
		"standard: round 1 a match's, 13 a half's, 25 (the sudden death) overtime's, the rest plain",
		kinds(STANDARD, { 1, 2, 12, 13, 14, 24, 25 }) == "match round round half round round overtime"
	)
	check(
		"competitive: every round from 25 on overtime's",
		kinds(COMPETITIVE, { 13, 24, 25, 26, 27, 40 }) == "half round overtime overtime overtime overtime"
	)
	check(
		"Swiftplay: round 1 a match's, 5 a half's, 9 (the sudden death) overtime's",
		kinds(SWIFT, { 1, 2, 4, 5, 8, 9 }) == "match round round half round overtime"
	)
	check(
		"a half's first round is where the sides swap and the kit starts its half",
		MatchRules.roundKind(STANDARD, STANDARD.halfRounds.value + 1) == "half"
			and MatchRules.swapsAfter(STANDARD, STANDARD.halfRounds.value)
			and MatchRules.roundKind(SWIFT, SWIFT.halfRounds.value + 1) == "half"
			and MatchRules.swapsAfter(SWIFT, SWIFT.halfRounds.value)
	)
end

-- A match's start ---------------------------------------------------------------

do
	check("a new match: no points", started(kit("jett", 5), "match", 0, false) == 0)
	check("Swiftplay's: 2 of Jett's 8", started(kit("jett", 5), "match", 0, true) == 2)
	check("and 2 of Sage's 7", started(kit("sage", 0), "match", 0, true) == 2)
	local nine = kit("jett", 0)
	nine.need = 9
	check("an ultimate of 9 starts Swiftplay's on 3", started(nine, "match", 0, true) == 3)
	local none = kit(AbilityConfig.NO_AGENT, 0)
	check("a kit with no ultimate starts on none, Swiftplay or not", started(none, "match", 0, true) == 0)
	check("a death owed from before the match is dropped", started(kit("jett", 0), "match", 2, false) == 0)
end

-- A half's start ------------------------------------------------------------------

do
	check("the half wipes a full ultimate", started(kit("jett", 8), "half", 0, false) == 0)
	check("and any part of one", started(kit("sova", 3), "half", 0, false) == 0)
	check("Swiftplay's half starts everyone on 2, more or less than they had", started(kit("jett", 7), "half", 0, true) == 2)
	check("from none too", started(kit("omen", 0), "half", 0, true) == 2)
	check("a death in the half's last round earns nothing across it", started(kit("jett", 4), "half", 1, false) == 0)
	local k = kit("jett", 8)
	k.charges[C], k.charges[Q] = 2, 1
	started(k, "half", 0, false)
	check(
		"the kit's half still takes what was bought, and the signature's free charge stays",
		k.charges[C] == 0 and k.charges[Q] == 0 and k.charges[E] == 1
	)
end

-- An overtime round -----------------------------------------------------------------

do
	check("overtime puts Jett on 5 of 8", started(kit("jett", 0), "overtime", 0, false) == 5)
	check("Sova on 5 of 8", started(kit("sova", 2), "overtime", 0, false) == 5)
	check(
		"and Phoenix, Sage and Omen on 4 of 7",
		started(kit("phoenix", 0), "overtime", 0, false) == 4
			and started(kit("sage", 6), "overtime", 0, false) == 4
			and started(kit("omen", 3), "overtime", 0, false) == 4
	)
	check("a full ultimate kept from regulation goes down to 5", started(kit("jett", 8), "overtime", 0, false) == 5)
	check("every overtime round, whatever the last left", started(kit("jett", 2), "overtime", 0, false) == 5)
	check("a death owed is no more than that", started(kit("jett", 5), "overtime", 1, false) == 5)
	check("Swiftplay's sudden death the same", started(kit("jett", 2), "overtime", 0, true) == 5)
	local none = kit(AbilityConfig.NO_AGENT, 0)
	check("a kit with no ultimate stays on none", started(none, "overtime", 0, false) == 0)
	local k = kit("jett", 6)
	k.charges[C] = 2
	started(k, "overtime", 0, false)
	check("the charges carry on as any round's", k.charges[C] == 2)
end

-- Any other round -------------------------------------------------------------------

do
	check("a round with no death keeps what was had", started(kit("jett", 3), "round", 0, false) == 3)
	check("a death last round is paid as this one starts", started(kit("jett", 3), "round", 1, false) == 4)
	check("Swiftplay's the same", started(kit("jett", 3), "round", 1, true) == 4)
	check("up to what the ultimate needs, and no more", started(kit("jett", 8), "round", 1, false) == 8)
	check("Sage's 7 the same", started(kit("sage", 7), "round", 1, false) == 7)
	local k = kit("jett", 4)
	AbilitySim.died(k, 0)
	check("in the spike rounds a death itself adds nothing", k.points == 4)
	AbilitySim.died(k)
	check("elsewhere it still adds its point at once", k.points == 5)
end

-- A whole match ------------------------------------------------------------------

do
	-- Jett through a standard match: a kill and a death in round 1, two
	-- kills in round 12 to fill it unspent, a death in round 12, then
	-- overtime.
	local k = kit("jett", 0)
	local seen = {}
	local function round(n: number, owed: number, swiftplay: boolean, format: MatchConfig.Format)
		table.insert(seen, started(k, MatchRules.roundKind(format, n), owed, swiftplay))
	end
	round(1, 0, false, STANDARD)
	AbilitySim.killed(k)
	AbilitySim.died(k, 0)
	round(2, 1, false, STANDARD)
	k.points = 7
	AbilitySim.killed(k)
	AbilitySim.killed(k)
	AbilitySim.died(k, 0)
	round(13, 1, false, STANDARD)
	k.points = 8
	round(25, 0, false, STANDARD)
	check(
		"a standard match: none at the start, 2 for a kill and the death owed, full and lost at the half, 5 in the sudden death",
		table.concat(seen, " ") == "0 2 0 5"
	)
	table.clear(seen)
	k = kit("jett", 0)
	round(1, 0, true, SWIFT)
	AbilitySim.killed(k)
	round(2, 1, true, SWIFT)
	round(5, 0, true, SWIFT)
	round(9, 0, true, SWIFT)
	check(
		"a Swiftplay match: 2 at the start, 4 after a kill and a death, 2 at the half, 5 in the sudden death",
		table.concat(seen, " ") == "2 4 2 5"
	)
end

return nil
