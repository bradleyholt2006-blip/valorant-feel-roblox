--!strict
-- Rejoining a match (system 69): a player who leaves the spike rounds'
-- match under way keeps their place in it, their record, side and credits
-- held and paid each round as their side is, and joining again puts them
-- back on their side. A bot gives way on their side (BotFill), and their
-- career counts the match as leaving if they're away at its end or back
-- too late to have played half of it (CareerRules). Another server finds
-- the held place by its entry (ServerList).

local BotFill = require("../src/shared/Bots/BotFill")
local CareerRules = require("../src/shared/Career/CareerRules")
local MatchConfig = require("../src/shared/Match/MatchConfig")
local MatchRules = require("../src/shared/Match/MatchRules")
local ServerList = require("../src/shared/Match/ServerList")
local H = require("./Harness")

local check = H.check

local C = MatchConfig.Credits
local SIZE = MatchConfig.Rules.sideSize.value

H.section("Rejoin tests")

-- Ends the buy phase of the round under way.
local function goLive(s: MatchRules.State)
	if s.phase == "buy" then
		MatchRules.step(s, s.phaseEndsAt)
	end
end

-- Moves on from the round's end to the next round's buy phase.
local function nextRound(s: MatchRules.State)
	if s.phase == "roundOver" or s.phase == "matchOver" then
		MatchRules.step(s, s.phaseEndsAt)
	end
end

-- Plays the round under way to `side`'s win and starts the next.
local function win(s: MatchRules.State, side: number)
	goLive(s)
	MatchRules.decide(s, side, s.phaseEndsAt - 50)
	nextRound(s)
end

-- A 2v2: 1 and 3 on side 1, 2 and 4 on side 2, at round 1's buy phase.
local function twoVsTwo(format: string?): MatchRules.State
	local s = MatchRules.new(format)
	for id = 1, 4 do
		MatchRules.join(s, id, 0)
	end
	return s
end

-- The place held -----------------------------------------------------------------

do
	local s = twoVsTwo()
	win(s, 1)
	goLive(s)
	MatchRules.died(s, 2, s.phaseEndsAt - 60, 1)
	local kills, credits = s.members[1].kills, s.members[1].credits
	MatchRules.leave(s, 1, s.phaseEndsAt - 59, true)
	local away = s.away[1]
	check(
		"a player leaving a match under way has their place held: out of the match, their record and credits kept",
		s.members[1] == nil and MatchRules.held(s, 1) and away ~= nil and away.kills == kills and away.credits == credits
	)
	check("...on their side, and not alive", away ~= nil and away.side == 1 and not away.alive)

	local b = MatchRules.new()
	MatchRules.join(b, 1, 0)
	MatchRules.leave(b, 1, 1, true)
	check("before the match's first round, nobody's place is held", not MatchRules.held(b, 1) and b.members[1] == nil)
	local c = twoVsTwo()
	win(c, 1)
	MatchRules.leave(c, 3, 1)
	check("nor without being held (a bot's)", not MatchRules.held(c, 3))
end

do
	local s = twoVsTwo()
	win(s, 1)
	local before = s.members[1].credits
	MatchRules.leave(s, 1, 1, true)
	win(s, 2)
	local away = s.away[1]
	check(
		"a place held is paid each round as its side is: round 2 lost, a first loss's pay",
		away ~= nil and away.credits == math.min(before + C.loss[1].value, C.cap.value)
	)
	for _ = 1, 10 do
		win(s, 2)
	end
	check("...and starts the second half on the half's credits", s.round == 13 and away ~= nil and away.credits == C.start.value)
end

-- Back -------------------------------------------------------------------------------

do
	local s = twoVsTwo()
	win(s, 1)
	goLive(s)
	MatchRules.died(s, 2, s.phaseEndsAt - 60, 1)
	MatchRules.leave(s, 1, s.phaseEndsAt - 59, true)
	local spawned = MatchRules.join(s, 1, s.phaseEndsAt - 58)
	local m = s.members[1]
	check(
		"back during a round: on their side, down until the next, their record as it was",
		m ~= nil and m.side == 1 and not m.alive and not m.played and m.kills == 1 and #spawned == 0 and not MatchRules.held(s, 1)
	)
	check("...and marked as having left, for their career", m ~= nil and m.left == true)
	nextRound(s)
	MatchRules.step(s, s.phaseEndsAt)
	nextRound(s)
	local m2 = s.members[1]
	check("...then alive as the next round starts", m2 ~= nil and m2.alive and s.phase == "buy")
	MatchRules.leave(s, 1, s.phaseEndsAt - 1, true)
	local again = MatchRules.join(s, 1, s.phaseEndsAt - 1)
	check("back in a buy phase: alive at once", #again == 1 and again[1] == 1 and s.members[1].alive)
end

do
	-- 5v5, with 1 away and 11 (a bot, say) in their place.
	local s = MatchRules.new()
	for id = 1, 2 * SIZE do
		MatchRules.join(s, id, 0)
	end
	win(s, 2)
	goLive(s)
	MatchRules.leave(s, 1, s.phaseEndsAt - 60, true)
	MatchRules.join(s, 11, s.phaseEndsAt - 59)
	check("a place held can be filled meanwhile, on its side", s.members[11] ~= nil and s.members[11].side == 1)
	MatchRules.join(s, 1, s.phaseEndsAt - 58)
	check(
		"back with both sides full: first in line, the place still held",
		s.queue[1] == 1 and MatchRules.held(s, 1) and s.members[1] == nil
	)
	MatchRules.join(s, 12, s.phaseEndsAt - 57)
	MatchRules.leave(s, 11, s.phaseEndsAt - 56)
	local m = s.members[1]
	check(
		"...and back on their side as its stand-in leaves, ahead of anyone who joined the line after",
		m ~= nil and m.side == 1 and not MatchRules.held(s, 1) and s.queue[1] == 12
	)
	MatchRules.leave(s, 3, s.phaseEndsAt - 55, true)
	MatchRules.join(s, 3, s.phaseEndsAt - 54)
	MatchRules.leave(s, 3, s.phaseEndsAt - 53)
	check("one who leaves the line again keeps their place held", MatchRules.held(s, 3) and s.members[3] == nil and s.queue[1] ~= 3)
end

do
	local s = twoVsTwo()
	win(s, 1)
	MatchRules.leave(s, 1, 1, true)
	for _ = 1, 12 do
		win(s, 2)
	end
	goLive(s)
	MatchRules.decide(s, 2, s.phaseEndsAt - 50)
	check("the match over, the place is still held until the next match", s.phase == "matchOver" and MatchRules.held(s, 1))
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.step(s, s.phaseEndsAt)
	check("...and let go as the next starts", s.match == 2 and not MatchRules.held(s, 1))
end

-- The bot that gives way -------------------------------------------------------------

do
	local bots: { BotFill.Seat } = {
		{ id = -1, side = 1, alive = true, order = 1 },
		{ id = -2, side = 1, alive = false, order = 2 },
		{ id = -3, side = 2, alive = true, order = 3 },
		{ id = -4, side = 2, alive = true, order = 4 },
		{ id = -5, side = 2, alive = true, order = 5 },
	}
	local _, out = BotFill.plan(10, 6, bots, "live", 2)
	check("a player back for side 2 mid-round: no bot leaves while side 2's are all alive", #out == 0)
	local _, without = BotFill.plan(10, 6, bots, "live")
	check("...where without one coming back, the one down leaves", #without == 1 and without[1] == -2)
	bots[4].alive = false
	local _, down = BotFill.plan(10, 6, bots, "live", 2)
	check("...and side 2's, once it's down", #down == 1 and down[1] == -4)
	bots[4].alive = true
	local _, calm = BotFill.plan(10, 6, bots, "buy", 1)
	check("in a buy phase, side 1's, though side 2 has more bots", #calm == 1 and (calm[1] == -1 or calm[1] == -2))
	local _, none = BotFill.plan(10, 8, { bots[3], bots[4], bots[5] }, "buy", 1)
	check("with no bot on that side, as without one coming back", #none == 1 and none[1] == -5)
end

-- The career -------------------------------------------------------------------------

local function player(side: number, rounds: number, extra: { away: boolean?, left: boolean? }?): CareerRules.Player
	return {
		side = side,
		kills = 3,
		deaths = 2,
		assists = 1,
		score = 200 * rounds,
		rounds = rounds,
		bot = false,
		away = if extra then extra.away else nil,
		left = if extra then extra.left else nil,
	}
end

local function mmrOf(_: number, _: CareerRules.Player): number
	return 1000
end

local ids = 0
local function newId(): string
	ids += 1
	return "r" .. ids
end

do
	local match: CareerRules.Match = {
		mode = "competitive",
		winner = 1,
		score = { 13, 7 },
		rounds = 20,
		winScore = 13,
		players = {
			[1] = player(1, 20),
			[2] = player(1, 6, { away = true }),
			[3] = player(1, 0, { away = true }),
			[4] = player(1, 12, { left = true }),
			[5] = player(1, 8, { left = true }),
			[6] = player(2, 20),
		},
	}
	local results = CareerRules.results(match, mmrOf, newId)
	check("Competitive: away at its end, having played a round, is a loss", results[2] ~= nil and results[2].outcome == "lost")
	check("...with none played, nothing", results[3] == nil)
	check("back in time for half its rounds, the match as for everyone else (won)", results[4] ~= nil and results[4].outcome == "won")
	check("back too late for half of them, a loss", results[5] ~= nil and results[5].outcome == "lost")
	check("...and the rest as before", results[1].outcome == "won" and results[6].outcome == "lost")
	match.mode = "swiftplay"
	local swift = CareerRules.results(match, mmrOf, newId)
	check("Swiftplay: away at its end, or back too late, counts for nothing", swift[2] == nil and swift[5] == nil)
	check("...and back in time, as for everyone", swift[4] ~= nil and swift[4].outcome == "won")
end

-- Another server -----------------------------------------------------------------------

do
	local held = ServerList.decodeHeld(ServerList.encodeHeld({ server = "r:abc", mode = "competitive" }))
	check("a held place's entry comes back as written", held ~= nil and held.server == "r:abc" and held.mode == "competitive")
	check(
		"and one missing anything is no entry",
		ServerList.decodeHeld({ server = "r:abc" }) == nil and ServerList.decodeHeld("r:abc") == nil
	)
	local line: ServerList.Line = {
		key = "r:abc",
		mode = "competitive",
		players = 8,
		playing = 7,
		cap = 10,
		max = 12,
		job = nil,
		code = "code",
		at = 1000,
	}
	if held then
		check("its server, up to date and reachable, can be sent back to", ServerList.canRejoin(line, held, 1010, 45))
		check("...not once its line is stale", not ServerList.canRejoin(line, held, 1100, 45))
		line.mode = "swiftplay"
		check("...nor once it plays another mode", not ServerList.canRejoin(line, held, 1010, 45))
		line.mode = "competitive"
		line.code = nil
		check("...nor without a way there", not ServerList.canRejoin(line, held, 1010, 45))
	end
end

return nil
