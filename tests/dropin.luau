--!strict
-- Matches that never stop (system 21): who plays on which side, the same in
-- Skirmish and the spike rounds (Roster). Someone joining goes on the side
-- with fewer players: in a buy phase they spawn at once, later they're down
-- until the next round, and once both sides are full they wait in line for
-- a place. The sides are evened out before each round, everyone has a
-- record this match in either mode, and the victory screen has its time.

local ArenaConfig = require("../src/shared/Arena/ArenaConfig")
local ArenaRules = require("../src/shared/Arena/ArenaRules")
local MatchConfig = require("../src/shared/Match/MatchConfig")
local MatchRules = require("../src/shared/Match/MatchRules")
local Roster = require("../src/shared/Match/Roster")
local H = require("./Harness")

local check = H.check

local AR = ArenaConfig.Rules
local MR = MatchConfig.Rules

local function same(a: { number }, b: { number }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

H.section("Drop-in tests")

-- The sides -------------------------------------------------------------------

do
	local s: Roster.Sides = { members = {}, queue = {}, joins = 0, hurt = {} }
	check("the first to join goes on side 1", Roster.openSide(s, 2) == 1)
	Roster.add(s, 1, 2, true, 0)
	check("the next on the side with fewer players", Roster.openSide(s, 2) == 2)
	for id = 2, 4 do
		Roster.add(s, id, 2, true, 0)
	end
	local queued = Roster.add(s, 5, 2, true, 0) == nil
	check(
		"with both sides full, nobody else gets a place: they're first in line",
		Roster.openSide(s, 2) == nil and queued and Roster.placeInLine(s, 5) == 1
	)
	local left = Roster.remove(s, 2)
	check("someone leaving opens a place for the first in line", left and Roster.nextInLine(s, 2) == 5 and #s.queue == 0)

	local b: Roster.Sides = { members = {}, queue = {}, joins = 0, hurt = {} }
	for id = 1, 5 do
		Roster.add(b, id, 5, true, 0)
	end
	b.members[2].side = 1 -- as if two of side 2 had left: 4-1
	local moved = Roster.balance(b)
	check(
		"4-1 is evened out to 3-2 by moving the last to join the bigger side",
		moved and Roster.sideOf(b, 5) == 2 and Roster.count(b, 1, false) == 3 and Roster.count(b, 2, false) == 2
	)
	check("3-2 is even enough: nobody moves", not Roster.balance(b))
end

-- Dropping in -------------------------------------------------------------------

do
	local s = ArenaRules.new()
	ArenaRules.join(s, 1, 0)
	ArenaRules.join(s, 2, 0)
	local spawned = ArenaRules.join(s, 3, 1)
	check(
		"Skirmish, joining in the buy phase: on the side with fewer players (side 1 when level), spawned at once",
		same(spawned, { 3 }) and ArenaRules.sideOf(s, 3) == 1 and s.members[3].alive
	)
	ArenaRules.step(s, s.phaseEndsAt)
	spawned = ArenaRules.join(s, 4, s.phaseEndsAt + 1)
	check(
		"joining a round under way: on the other side, down until the next round",
		#spawned == 0 and ArenaRules.sideOf(s, 4) == 2 and not s.members[4].alive and s.phase == "live"
	)
	ArenaRules.died(s, 2, 30, 1)
	check("they count as down: their side's last player falling ends the round", s.phase == "roundOver" and s.roundWinner == 1)
	spawned = ArenaRules.step(s, s.phaseEndsAt)
	check("then they spawn with everyone for the next round", same(spawned, { 1, 2, 3, 4 }) and s.members[4].alive)
	check("and the round they sat out doesn't count toward their average", s.members[4].rounds == 0 and s.members[2].rounds == 1)
end

do
	local s = ArenaRules.new()
	for id = 1, 4 do
		ArenaRules.join(s, id, 0)
	end
	local spawned = ArenaRules.join(s, 5, 1)
	check(
		"with both sides full (two a side), the next to join waits in line, on no side",
		#spawned == 0 and s.members[5] == nil and Roster.placeInLine(s, 5) == 1 and ArenaRules.sideOf(s, 5) == nil
	)
	ArenaRules.join(s, 6, 1)
	check("first come, first served", Roster.placeInLine(s, 6) == 2)
	check("joining again changes nothing", #ArenaRules.join(s, 5, 2) == 0 and Roster.placeInLine(s, 5) == 1 and #s.queue == 2)
	ArenaRules.step(s, s.phaseEndsAt)
	spawned = ArenaRules.leave(s, 2, 20)
	check(
		"someone leaving mid-round gives their place to the first in line, down until the next round",
		#spawned == 0 and ArenaRules.sideOf(s, 5) == 2 and not s.members[5].alive and Roster.placeInLine(s, 6) == 1
	)
	check("and the round goes on: their teammate is still up", s.phase == "live")
	ArenaRules.leave(s, 6, 21)
	check("leaving the line takes you out of it", #s.queue == 0 and Roster.placeInLine(s, 6) == nil)

	local b = ArenaRules.new()
	for id = 1, 5 do
		ArenaRules.join(b, id, 0)
	end
	spawned = ArenaRules.leave(b, 1, 1)
	check(
		"in a buy phase, the place's new player spawns at once",
		same(spawned, { 5 }) and ArenaRules.sideOf(b, 5) == 1 and b.members[5].alive
	)
end

do
	local s = MatchRules.new("standard")
	for id = 1, 6 do
		MatchRules.join(s, id, 0)
	end
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.leave(s, 2, 10)
	MatchRules.leave(s, 4, 11)
	check(
		"the spike rounds: players leaving can leave a round under way at 3-1",
		Roster.count(s, 1, false) == 3 and Roster.count(s, 2, false) == 1 and s.phase == "live"
	)
	MatchRules.died(s, 6, 20, 1)
	MatchRules.step(s, s.phaseEndsAt)
	check(
		"before the next round, the last to join the bigger side moves across: 2-2",
		MatchRules.sideOf(s, 5) == 2 and Roster.count(s, 1, false) == 2 and Roster.count(s, 2, false) == 2 and s.phase == "buy"
	)
	check(
		"paid for the round they won before they moved",
		s.members[5].credits == MatchConfig.Credits.start.value + MatchConfig.Credits.win.value
	)
	check(
		"and they play it on their new side, from a spot of their own",
		s.members[5].alive and MatchRules.spotOf(s, 5) == 1 and MatchRules.spotOf(s, 6) == 2
	)

	local q = MatchRules.new("standard")
	for id = 1, 2 * MR.sideSize.value do
		MatchRules.join(q, id, 0)
	end
	MatchRules.join(q, 99, 0)
	check("five a side: the eleventh waits in line", q.members[99] == nil and Roster.placeInLine(q, 99) == 1)
	MatchRules.step(q, q.phaseEndsAt)
	MatchRules.leave(q, 1, 5)
	local m = q.members[99]
	check(
		"and takes the place of the first to leave, with the credits to start on",
		m ~= nil and m.side == 1 and not m.alive and m.credits == MatchConfig.Credits.start.value
	)
end

-- The record in Skirmish --------------------------------------------------------

do
	local s = ArenaRules.new()
	for id = 1, 4 do
		ArenaRules.join(s, id, 0)
	end
	ArenaRules.step(s, s.phaseEndsAt)
	ArenaRules.damaged(s, 3, 2, 60)
	ArenaRules.damaged(s, 1, 2, 90)
	ArenaRules.died(s, 2, 10, 1)
	local killer = s.members[1]
	check(
		"Skirmish keeps the record: a kill, scored by the enemies alive for it, and an assist",
		killer.kills == 1 and killer.score == 90 + Roster.killScore(2) and s.members[3].assists == 1 and s.members[2].deaths == 1,
		string.format("score %d", killer.score)
	)
	ArenaRules.damaged(s, 4, 3, 40)
	ArenaRules.damaged(s, 1, 3, 40)
	check("damage to a teammate scores nothing", killer.score == 90 + Roster.killScore(2))
	ArenaRules.died(s, 4, 11, 1)
	check(
		"the round's second kill adds the multikill bonus",
		killer.kills == 2 and killer.score == 90 + Roster.killScore(2) + Roster.killScore(1) + MatchConfig.Score.multiKill.value
	)
	check("and the round counts for everyone in it", killer.rounds == 1 and s.members[4].rounds == 1)

	-- Side 1 wins the rest, and the victory screen shows.
	local t = 100
	while s.phase ~= "matchOver" do
		ArenaRules.step(s, s.phaseEndsAt)
		ArenaRules.step(s, s.phaseEndsAt)
		t += 10
		ArenaRules.died(s, 2, t, 1)
		ArenaRules.died(s, 4, t, 3)
	end
	check(
		"the victory screen shows for its time before the next match",
		s.phaseEndsAt == t + AR.matchOverTime.value and s.matchWinner == 1,
		string.format("%.1f s", s.phaseEndsAt - t)
	)
	check("with the match's record still there to show", killer.kills > 2)
	ArenaRules.step(s, s.phaseEndsAt) -- to the vote for the next map (system 22)
	ArenaRules.step(s, s.phaseEndsAt)
	check("which a new match clears", killer.kills == 0 and killer.score == 0 and killer.rounds == 0 and s.round == 1)
	check(
		"the victory screen is the same length in both modes (estimate)",
		AR.matchOverTime.value == MR.matchOverTime.value and AR.matchOverTime.status == "estimate"
	)
end

return nil
