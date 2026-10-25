--!strict
-- The vote for the next map (system 22): after a match's victory screen,
-- everyone in the server votes between maps chosen at random, the most
-- votes wins, and a tie or no votes at all is settled at random. Then the
-- next match starts on the winner. With one map there's no vote, and a side
-- emptying during it ends it there, on the same map.

local ArenaConfig = require("../src/shared/Arena/ArenaConfig")
local ArenaLayout = require("../src/shared/Arena/ArenaLayout")
local ArenaRules = require("../src/shared/Arena/ArenaRules")
local MapVote = require("../src/shared/Match/MapVote")
local Roster = require("../src/shared/Match/Roster")
local H = require("./Harness")

local check = H.check

local R = ArenaConfig.Rules

-- Dice that roll what they're told, in turn, then 1s, and never more than
-- the number of sides.
local function dice(...: number): MapVote.Roll
	local rolls = { ... }
	local i = 0
	return function(n: number): number
		i += 1
		local r = rolls[i] or 1
		assert(r >= 1 and r <= n, "a roll off the dice")
		return r
	end
end

local function same(a: { string }, b: { string }): boolean
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

H.section("Map vote tests")

-- The vote ----------------------------------------------------------------------

do
	local pool = { "A", "B", "C", "D", "E" }
	local v = MapVote.new(pool, 3, dice(5, 1, 2))
	check("three of five maps, chosen at random, shown in the pool's order", same(v.options, { "A", "C", "E" }))
	check("all three of three", same(MapVote.new(ArenaLayout.MAPS, 3, dice(2, 2, 1)).options, { "A", "B", "C" }))
	check("and all there are, with fewer than asked for", same(MapVote.new({ "A", "B" }, 3, dice()).options, { "A", "B" }))

	local w = MapVote.new({ "A", "B", "C" }, 3, dice())
	check("a vote counts", MapVote.cast(w, 1, 2) and MapVote.tally(w)[2] == 1)
	check("the same vote again changes nothing", not MapVote.cast(w, 1, 2))
	check(
		"no vote for an option that isn't there",
		not MapVote.cast(w, 2, 0) and not MapVote.cast(w, 2, 4) and not MapVote.cast(w, 2, 1.5) and not MapVote.cast(w, 2, 0 / 0)
	)
	check("a vote can be changed, and still counts once", MapVote.cast(w, 1, 3) and same(MapVote.tally(w) :: any, { 0, 0, 1 } :: any))
	MapVote.cast(w, 2, 1)
	MapVote.cast(w, 3, 1)
	check("the most votes wins", MapVote.winner(w, dice()) == "A")
	check("someone leaving takes their vote", MapVote.drop(w, 2) and not MapVote.drop(w, 2) and MapVote.tally(w)[1] == 1)
	check(
		"a tie is settled at random between the maps tied for the most",
		MapVote.winner(w, dice(2)) == "C" and MapVote.winner(w, dice(1)) == "A"
	)
	local none = MapVote.new({ "A", "B", "C" }, 3, dice())
	check("with no votes, any of them, at random", MapVote.winner(none, dice(3)) == "C" and MapVote.winner(none, dice(2)) == "B")
end

-- After a match --------------------------------------------------------------------

-- Plays to the end of the match: side 1 wins every round.
local function toMatchOver(s: ArenaRules.State): number
	local t = 0
	while s.phase ~= "matchOver" do
		t = math.max(t, s.phaseEndsAt)
		if s.phase == "live" then
			ArenaRules.skip(s, t)
		else
			ArenaRules.step(s, t)
		end
	end
	return t
end

do
	-- Dice: B for the first match, then A, B and C for the vote.
	local s = ArenaRules.new(nil, dice(2, 1, 1, 1))
	check("the first match is on one of the three, at random", s.map == "B" and #s.maps == 3)
	for id = 1, 5 do
		ArenaRules.join(s, id, 0)
	end
	local t = toMatchOver(s)
	check("a match won, the victory screen first", s.phase == "matchOver" and s.score[1] == R.winScore.value and s.vote == nil)
	check("nobody votes during it", not ArenaRules.vote(s, 1, 1))
	t = s.phaseEndsAt
	local spawned = ArenaRules.step(s, t)
	local vote = s.vote
	check(
		"then the vote: three maps, for its time, nobody spawning",
		#spawned == 0
			and s.phase == "vote"
			and vote ~= nil
			and same(vote.options, { "A", "B", "C" })
			and s.phaseEndsAt == t + R.voteTime.value,
		string.format("%s, %.1f s", s.phase, s.phaseEndsAt - t)
	)
	local before = s.version
	check("a player votes", ArenaRules.vote(s, 1, 3) and s.version > before)
	check("so does someone waiting in line", Roster.placeInLine(s, 5) == 1 and ArenaRules.vote(s, 5, 3))
	check("not someone the rules don't know", not ArenaRules.vote(s, 99, 3))
	ArenaRules.vote(s, 2, 1)
	ArenaRules.vote(s, 3, 1)
	ArenaRules.leave(s, 3, t + 1)
	check("someone leaving takes their vote with them", vote ~= nil and same(MapVote.tally(vote) :: any, { 1, 0, 2 } :: any))
	ArenaRules.damaged(s, 2, 1, 50)
	ArenaRules.died(s, 1, t + 2, 2)
	check("nothing during the vote goes in the record", s.members[2].kills == 0 and s.members[2].score == 0)
	check("the vote lasts its time", #ArenaRules.step(s, s.phaseEndsAt - 0.01) == 0 and s.phase == "vote")
	spawned = ArenaRules.step(s, s.phaseEndsAt)
	check(
		"then the next match starts on the most voted for, at 0-0, everyone spawning",
		s.map == "C" and s.phase == "buy" and s.round == 1 and s.score[1] == 0 and s.vote == nil and #spawned == 4 and s.match == 2
	)
end

do
	-- A tie: the dice pick A for the first match, all three for the vote,
	-- then the second of the two tied.
	local s = ArenaRules.new(nil, dice(1, 1, 1, 1, 2))
	for id = 1, 2 do
		ArenaRules.join(s, id, 0)
	end
	toMatchOver(s)
	ArenaRules.step(s, s.phaseEndsAt)
	ArenaRules.vote(s, 1, 1)
	ArenaRules.vote(s, 2, 3)
	ArenaRules.step(s, s.phaseEndsAt)
	check("a tie is settled at random between the two", s.map == "C")

	local quiet = ArenaRules.new(nil, dice(1, 1, 1, 1, 2))
	for id = 1, 2 do
		ArenaRules.join(quiet, id, 0)
	end
	toMatchOver(quiet)
	ArenaRules.step(quiet, quiet.phaseEndsAt)
	ArenaRules.step(quiet, quiet.phaseEndsAt)
	check("with no votes, any of the three", quiet.map == "B")
end

do
	local s = ArenaRules.new({ "A" })
	for id = 1, 2 do
		ArenaRules.join(s, id, 0)
	end
	toMatchOver(s)
	local spawned = ArenaRules.step(s, s.phaseEndsAt)
	check(
		"with one map there's no vote: the next match starts after the victory screen",
		s.phase == "buy" and s.round == 1 and #spawned == 2 and s.map == "A"
	)

	local e = ArenaRules.new(nil, dice(3))
	for id = 1, 2 do
		ArenaRules.join(e, id, 0)
	end
	toMatchOver(e)
	ArenaRules.step(e, e.phaseEndsAt)
	ArenaRules.vote(e, 1, 1)
	ArenaRules.leave(e, 2, e.phaseEndsAt - 5)
	check(
		"a side emptying during the vote ends it there: waiting, at 0-0, on the same map",
		e.phase == "waiting" and e.vote == nil and e.map == "C" and e.score[1] == 0 and e.match == 2
	)

	local j = ArenaRules.new()
	for id = 1, 2 do
		ArenaRules.join(j, id, 0)
	end
	toMatchOver(j)
	ArenaRules.step(j, j.phaseEndsAt)
	spawned = ArenaRules.join(j, 3, j.phaseEndsAt - 10)
	check(
		"joining during the vote: down until the next match, with a vote",
		#spawned == 0 and not j.members[3].alive and ArenaRules.vote(j, 3, 2)
	)
	spawned = ArenaRules.step(j, j.phaseEndsAt)
	check("and spawning with everyone for it", #spawned == 3 and j.members[3].alive)
end

do
	local s = ArenaRules.new()
	ArenaRules.join(s, 1, 0)
	ArenaRules.join(s, 2, 0)
	ArenaRules.skip(s, 1)
	ArenaRules.step(s, 1)
	check("skipping the buy phase starts the round (for testing)", s.phase == "live")
	ArenaRules.skip(s, 2)
	check("skipping the round gives it to side 1, as Skirmish's rounds have no clock", s.phase == "roundOver" and s.score[1] == 1)
	ArenaRules.skip(s, 3)
	check("and skipping the wait starts the next", #ArenaRules.step(s, 3) == 2 and s.round == 2)
end

return nil
