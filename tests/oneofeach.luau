--!strict
-- One of each agent on a side (system 48). An agent a teammate has locked
-- in is taken: it can't be selected or locked in, and a selection it's
-- taken from moves back to the agent the player plays, or else to the
-- first that's free. Of windows closing at once on one agent, the first
-- player on the server keeps it. The two sides can both play an agent. A
-- window is for a side of a match: someone moved across picks again, and
-- so does someone back in a match to find their agent taken; halftime
-- swaps who attacks, not who's on which side, so nobody picks then. With
-- fewer agents than a side has players, once every agent is taken none is.

local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AgentSelect = require("../src/shared/Abilities/AgentSelect")
local ArenaConfig = require("../src/shared/Arena/ArenaConfig")
local TeamDeathmatchConfig = require("../src/shared/Arena/TeamDeathmatchConfig")
local MatchConfig = require("../src/shared/Match/MatchConfig")
local MatchRules = require("../src/shared/Match/MatchRules")
local H = require("./Harness")

local check = H.check

local TIME = AbilityConfig.Select.time.value
local JETT = AbilityConfig.DEFAULT_AGENT
-- Other agents to pick from, for the rules alone, which don't look at kits.
local OTHER, THIRD = "other", "third"
local FREE = AgentSelect.FREE
-- The two sides of a match, as where a player is for picking.
local SIDE1, SIDE2 = "m:1", "m:2"

local function count(t: { [number]: string }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

-- Where each of `ids` is for picking in the spike rounds `s` (the server's
-- first mode started).
local function spikeMoments(s: MatchRules.State, ids: { number }): { [number]: string? }
	local out: { [number]: string? } = {}
	for _, id in ids do
		out[id] = AgentSelect.moment("spike", s.phase, s.match, 1, MatchRules.sideOf(s, id))
	end
	return out
end

H.section("One of each agent on a side (system 48)")

-- The agents --------------------------------------------------------------------------------

do
	local n = #AgentSelect.pickable()
	local spike, tdm = MatchConfig.Rules.sideSize.value, TeamDeathmatchConfig.Rules.sideSize.value
	local skirmish = ArenaConfig.Rules.sideSize.value
	check(
		"as many agents can be picked as a side of the spike rounds or Team Deathmatch has places, and more than Skirmish's",
		n >= spike and n >= tdm and n > skirmish,
		string.format("%d agents, sides of %d, %d and %d", n, spike, tdm, skirmish)
	)
end

-- Where a player is -------------------------------------------------------------------------

do
	local one = AgentSelect.moment("spike", "buy", 2, 1, 1)
	local two = AgentSelect.moment("spike", "buy", 2, 1, 2)
	check("each side of a match has a key of its own", one ~= nil and two ~= nil and one ~= two)
	check(
		"which it keeps through the match",
		AgentSelect.moment("spike", "planted", 2, 1, 1) == one and AgentSelect.moment("spike", "roundOver", 2, 1, 1) == one
	)
end

-- Taken --------------------------------------------------------------------------------------

do
	local agents = { JETT, OTHER, THIRD }
	local taken = AgentSelect.takenOf(agents, { JETT })
	check("an agent a teammate has locked in is taken", taken[JETT] == true and not taken[OTHER] and not taken[THIRD])
	taken = AgentSelect.takenOf(agents, { JETT, THIRD, JETT })
	check("and so is each that teammates have", taken[JETT] == true and taken[THIRD] == true and not taken[OTHER])
	taken = AgentSelect.takenOf(agents, { THIRD, OTHER, JETT })
	check("but once every agent is taken none is, as some must be played twice", next(taken) == nil)
end

-- On a side ----------------------------------------------------------------------------------

do
	local a = AgentSelect.new({ JETT, OTHER, THIRD })
	local ids = { 1, 2, 3 }
	local where: { [number]: string? } = { [1] = SIDE1, [2] = SIDE1, [3] = SIDE2 }
	AgentSelect.step(a, ids, where, 0)
	local p1, p2, p3 = AgentSelect.pickOf(a, 1), AgentSelect.pickOf(a, 2), AgentSelect.pickOf(a, 3)
	check(
		"a match opens everyone's window, each on the agent they play",
		p1.status == "open" and p2.status == "open" and p3.status == "open" and p1.selected == JETT and p2.selected == JETT
	)
	check("nothing's taken until a teammate locks in", next(AgentSelect.taken(a, 2)) == nil)
	check(
		"so teammates can both select one agent",
		AgentSelect.select(a, 2, THIRD) and AgentSelect.select(a, 2, JETT) and p1.selected == JETT and p2.selected == JETT
	)
	check("player 1 locks in Jett", AgentSelect.lock(a, 1) == nil and p1.status == "locked" and p1.agent == JETT)
	local taken = AgentSelect.taken(a, 2)
	check("and it's taken from their teammate", taken[JETT] == true and not taken[OTHER] and not taken[THIRD])
	check("who can't select it", not AgentSelect.select(a, 2, JETT))
	check(
		"nor lock it in, selected before it was taken: their window stays open",
		AgentSelect.lock(a, 2) == nil and p2.status == "open" and p2.closesAt == TIME
	)
	AgentSelect.step(a, ids, where, 1)
	check("and their selection moves to the first agent that's free, as the one they play is taken", p2.selected == OTHER)
	check(
		"the other side can play Jett too",
		next(AgentSelect.taken(a, 3)) == nil and AgentSelect.lock(a, 3) == nil and p3.status == "locked" and p3.agent == JETT
	)
	check("an agent that's free can be selected and locked in", AgentSelect.select(a, 2, THIRD) and AgentSelect.lock(a, 2) == THIRD)
	check("one of each on the side", p1.agent == JETT and p2.agent == THIRD and p2.status == "locked")
end

do
	local a = AgentSelect.new({ JETT, OTHER, THIRD })
	local ids = { 1, 2 }
	AgentSelect.step(a, ids, { [1] = FREE, [2] = FREE }, 0)
	AgentSelect.select(a, 2, OTHER)
	AgentSelect.lock(a, 2)
	local side: { [number]: string? } = { [1] = SIDE1, [2] = SIDE1 }
	AgentSelect.step(a, ids, side, 1)
	local p2 = AgentSelect.pickOf(a, 2)
	AgentSelect.select(a, 1, THIRD)
	AgentSelect.select(a, 2, THIRD)
	AgentSelect.lock(a, 1)
	AgentSelect.step(a, ids, side, 2)
	check("a selection taken moves back to the agent they play, when that's free", p2.selected == OTHER)
end

-- Time running out ---------------------------------------------------------------------------

do
	local a = AgentSelect.new()
	local ids = { 1, 2, 3, 4, 5 }
	local side: { [number]: string? } = {}
	for _, id in ids do
		side[id] = SIDE1
	end
	AgentSelect.step(a, ids, side, 0)
	local changed = AgentSelect.step(a, ids, side, TIME)
	local agents = {}
	for _, id in ids do
		table.insert(agents, AgentSelect.agentOf(a, id))
	end
	local played = table.concat(agents, ", ")
	local first = table.move(AgentSelect.pickable(), 1, #ids, 1, {})
	check(
		"a side of five on Jett, nobody picking: as the windows close, the first on the server keeps her and the rest take the first that's free",
		played == table.concat(first, ", "),
		played
	)
	check("one of each agent, four of them new", count(changed) == 4 and changed[1] == nil)
end

do
	local a = AgentSelect.new({ JETT, OTHER, THIRD })
	local ids = { 1, 2 }
	local side: { [number]: string? } = { [1] = SIDE1, [2] = SIDE1 }
	AgentSelect.step(a, ids, side, 0)
	AgentSelect.select(a, 1, THIRD)
	AgentSelect.select(a, 2, THIRD)
	local changed = AgentSelect.step(a, ids, side, TIME)
	check("two windows closing at once on one agent: the first player on the server keeps it", changed[1] == THIRD)
	check("and the other plays on as before", changed[2] == nil and AgentSelect.agentOf(a, 2) == JETT)
end

-- Fewer agents than places -------------------------------------------------------------------

do
	local a = AgentSelect.new({ JETT, OTHER })
	local ids = { 1, 2, 3 }
	AgentSelect.step(a, ids, { [1] = SIDE1, [2] = SIDE1, [3] = SIDE1 }, 0)
	AgentSelect.lock(a, 1)
	AgentSelect.select(a, 2, OTHER)
	AgentSelect.lock(a, 2)
	check("with two agents and three on a side, once both are taken neither is", next(AgentSelect.taken(a, 3)) == nil)
	check("so the third can play either", AgentSelect.select(a, 3, OTHER) and AgentSelect.lock(a, 3) == OTHER)
end

-- Back in a match ----------------------------------------------------------------------------

do
	local a = AgentSelect.new({ JETT, OTHER, THIRD })
	local ids = { 1, 2 }
	local p1, p2 = AgentSelect.pickOf(a, 1), AgentSelect.pickOf(a, 2)
	AgentSelect.step(a, ids, { [1] = SIDE1 }, 0)
	AgentSelect.lock(a, 1)
	AgentSelect.step(a, ids, {}, 1)
	AgentSelect.step(a, ids, { [2] = SIDE1 }, 2)
	check(
		"off the side, a player holds no agent: someone joining can lock in theirs",
		next(AgentSelect.taken(a, 2)) == nil and AgentSelect.lock(a, 2) == nil and p2.status == "locked" and p2.agent == JETT
	)
	local both: { [number]: string? } = { [1] = SIDE1, [2] = SIDE1 }
	AgentSelect.step(a, ids, both, 3)
	check("back in the match to find their agent taken, they've another window", p1.status == "open" and p1.closesAt == 3 + TIME)
	check("on one that's free", p1.selected == OTHER and p1.agent == JETT)
	local changed = AgentSelect.step(a, ids, both, 3 + TIME)
	check("which is theirs as it closes", changed[1] == OTHER and p1.status == "locked")
	AgentSelect.step(a, ids, { [2] = SIDE1 }, 20)
	AgentSelect.step(a, ids, both, 21)
	check("back to find their agent free, they play on, locked in", p1.status == "locked" and p1.agent == OTHER)
end

do
	local a = AgentSelect.new({ JETT, OTHER, THIRD })
	local ids = { 1, 2 }
	local side: { [number]: string? } = { [1] = SIDE1, [2] = SIDE1 }
	AgentSelect.step(a, ids, side, 0)
	AgentSelect.lock(a, 1)
	AgentSelect.select(a, 2, OTHER)
	AgentSelect.lock(a, 2)
	AgentSelect.step(a, ids, { [1] = FREE, [2] = FREE }, 10)
	check(
		"waiting for players mid-match, picking is free: teammates can play one agent",
		AgentSelect.select(a, 1, THIRD)
			and AgentSelect.lock(a, 1) == THIRD
			and AgentSelect.select(a, 2, THIRD)
			and AgentSelect.lock(a, 2) == THIRD
	)
	AgentSelect.step(a, ids, side, 20)
	local p1, p2 = AgentSelect.pickOf(a, 1), AgentSelect.pickOf(a, 2)
	check("as the match carries on, the first on the server keeps it", p1.status == "locked" and p1.agent == THIRD)
	check("and the other has a window, on the first agent that's free", p2.status == "open" and p2.selected == JETT)
end

-- The spike rounds, played -------------------------------------------------------------------

do
	local a = AgentSelect.new()
	local s = MatchRules.new("standard")
	local ids = { 1, 2, 3, 4, 5, 6 }
	for _, id in ids do
		MatchRules.join(s, id, 0)
	end
	AgentSelect.step(a, ids, spikeMoments(s, ids), 0)
	local p5, p6 = AgentSelect.pickOf(a, 5), AgentSelect.pickOf(a, 6)
	AgentSelect.select(a, 5, "sova")
	AgentSelect.lock(a, 5)
	check(
		"players 5 and 6, on the two sides, can both lock in Sova",
		MatchRules.sideOf(s, 5) ~= MatchRules.sideOf(s, 6) and AgentSelect.select(a, 6, "sova") and AgentSelect.lock(a, 6) == "sova"
	)
	AgentSelect.step(a, ids, spikeMoments(s, ids), TIME)
	local p1, p3 = AgentSelect.pickOf(a, 1), AgentSelect.pickOf(a, 3)
	check(
		"as the windows close, player 3 has the first agent player 1's Jett leaves free",
		p1.agent == JETT and p3.agent == AgentSelect.pickable()[2] and p1.status == "locked" and p3.status == "locked"
	)

	MatchRules.step(s, s.phaseEndsAt)
	local t = s.phaseEndsAt - 1
	MatchRules.leave(s, 2, t)
	MatchRules.leave(s, 4, t)
	AgentSelect.step(a, ids, spikeMoments(s, ids), t)
	MatchRules.died(s, 6, t, 1)
	MatchRules.step(s, s.phaseEndsAt)
	t = s.phaseEndsAt - 1
	local key = p5.match
	AgentSelect.step(a, ids, spikeMoments(s, ids), t)
	check("before the next round, player 5 moves across to even the sides", MatchRules.sideOf(s, 5) == 2 and s.phase == "buy")
	check("and has a window for the new side", p5.status == "open" and p5.match ~= key and p5.closesAt == t + TIME)
	check("Sova taken there, on the first agent that's free", p5.selected == JETT and p6.agent == "sova")
	check(
		"while the teammates they left keep theirs, locked in",
		p1.status == "locked" and p1.agent == JETT and p3.status == "locked" and p3.agent == AgentSelect.pickable()[2]
	)
	local changed = AgentSelect.step(a, ids, spikeMoments(s, ids), t + TIME)
	check("as it closes, Jett's theirs", changed[5] == JETT and p5.status == "locked")
end

do
	local a = AgentSelect.new()
	local s = MatchRules.new("standard")
	local ids = { 1, 2 }
	MatchRules.join(s, 1, 0)
	MatchRules.join(s, 2, 0)
	AgentSelect.step(a, ids, spikeMoments(s, ids), 0)
	local p1, p2 = AgentSelect.pickOf(a, 1), AgentSelect.pickOf(a, 2)
	local key1, key2 = p1.match, p2.match
	local half = MatchConfig.Formats.standard.halfRounds.value
	local t = 0
	for _ = 1, 200 do
		if s.round > half then
			break
		end
		t += 1
		MatchRules.skip(s, t)
		MatchRules.step(s, t)
		AgentSelect.step(a, ids, spikeMoments(s, ids), t)
	end
	check(
		"at halftime the sides swap attacking for defending, not players",
		s.round == half + 1 and s.attackers == 2 and MatchRules.sideOf(s, 1) == 1 and MatchRules.sideOf(s, 2) == 2
	)
	check(
		"so nobody picks again: both locked in, on the same sides of the match",
		p1.status == "locked" and p2.status == "locked" and p1.match == key1 and p2.match == key2
	)
end

return nil
