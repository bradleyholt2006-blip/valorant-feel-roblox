--!strict
-- Agent select (system 29). Once a match, each player has a window, from
-- its start or from when they join it under way: what they've selected is
-- locked in as it closes, unless they lock it in before, and it's theirs
-- until the match is over. Where it's free (the course, a mode waiting for
-- players) an agent locked in is theirs at once. Nobody picks in gun game
-- or deathmatch, between matches, or off a side. A new agent's kit sells
-- back what was bought into the last one's. And every agent has what the
-- menu and the wire need.

local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local AgentSelect = require("../src/shared/Abilities/AgentSelect")
local ArenaConfig = require("../src/shared/Arena/ArenaConfig")
local ArenaRules = require("../src/shared/Arena/ArenaRules")
local TeamDeathmatchConfig = require("../src/shared/Arena/TeamDeathmatchConfig")
local MatchConfig = require("../src/shared/Match/MatchConfig")
local MapVote = require("../src/shared/Match/MapVote")
local Shop = require("../src/shared/Weapons/Shop")
local H = require("./Harness")

local check = H.check

local TIME = AbilityConfig.Select.time.value
local JETT = AbilityConfig.DEFAULT_AGENT
-- A second agent to pick from, for the rules alone, which don't look at
-- kits.
local OTHER = "other"
local FREE = AgentSelect.FREE

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

-- Each of `ids`' picks moved on at `now`, as Skirmish's rules `s` have them
-- (the server's first mode started): the agents they play now, by id, for
-- those that changed.
local function stepAll(a: AgentSelect.State, s: ArenaRules.State, ids: { number }, now: number): { [number]: string }
	local changed = {}
	for _, id in ids do
		local moment = AgentSelect.moment("skirmish", s.phase, s.match, 1, s.members[id] ~= nil)
		local agent = AgentSelect.update(a, id, moment, now)
		if agent then
			changed[id] = agent
		end
	end
	return changed
end

local function count(t: { [number]: string }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

H.section("Agent select (system 29)")

-- The numbers ------------------------------------------------------------------------------

do
	check("the window is 10 s, ours", TIME == 10 and AbilityConfig.Select.time.status == "estimate")
	local skirmish = ArenaConfig.Rules.firstBuyTime.value
	local spike = MatchConfig.Rules.firstBuyTime.value
	local preGame = TeamDeathmatchConfig.Rules.preGame.value
	check(
		"inside every mode's first phase: Skirmish's buy phase, the spike rounds' and Team Deathmatch's pre-game",
		TIME < skirmish and TIME < spike and TIME < preGame,
		string.format("%g s against %g, %g and %g", TIME, skirmish, spike, preGame)
	)
end

-- The agents -------------------------------------------------------------------------------

do
	local pickable = AgentSelect.pickable()
	check("Jett can be picked", table.find(pickable, JETT) ~= nil)
	local playable = true
	for _, id in pickable do
		local any = false
		for _, ability in AbilityConfig.Agents[id].abilities do
			any = any or AbilitySim.playable(ability)
		end
		playable = playable and any
	end
	check("and every agent that can be picked has an ability that can be played", playable)
	local named, slotted, passives, wired = true, true, true, true
	for index, id in AbilityConfig.AgentIds do
		local agent = AbilityConfig.Agents[id]
		named = named and agent ~= nil and agent.id == id and agent.name ~= "" and agent.role ~= ""
		for slot = AbilityConfig.C, AbilityConfig.X do
			local def = AbilityConfig.abilityOf(id, slot)
			slotted = slotted and def ~= nil and def.slot == slot
		end
		local passive = agent and agent.passive
		passives = passives and (passive == nil or AbilityConfig.Passives[passive] ~= nil)
		wired = wired and AbilityConfig.AgentIndex[id] == index
	end
	check("every agent has its name and role", named)
	check("and an ability in each of C, Q, E and X, in its own slot", slotted)
	check("and what its passive does, if it has one", passives)
	check("and its index on the wire, which comes back to it", wired)
	check("Jett is a Duelist", AbilityConfig.Agents[JETT].role == "Duelist")
end

-- Where a player is -------------------------------------------------------------------------

do
	check("the course is free", AgentSelect.moment(nil, "", 0, 0, false) == FREE)
	check("so is a mode waiting for players", AgentSelect.moment("skirmish", "waiting", 3, 1, true) == FREE)
	local key = AgentSelect.moment("skirmish", "buy", 3, 1, true)
	check("a match under way has its key", key ~= nil and key ~= FREE)
	local same = true
	for _, phase in { "live", "roundOver" } do
		same = same and AgentSelect.moment("skirmish", phase, 3, 1, true) == key
	end
	check("through every phase of it", same)
	check("the next match has another", AgentSelect.moment("skirmish", "buy", 4, 1, true) ~= key)
	check("and so does the same match once the mode starts over", AgentSelect.moment("skirmish", "buy", 3, 2, true) ~= key)
	check("as does another mode's", AgentSelect.moment("spike", "buy", 3, 1, true) ~= key)
	local spike = AgentSelect.moment("spike", "planted", 1, 1, true)
	local tdm = AgentSelect.moment("teamdeathmatch", "pregame", 1, 1, true)
	check("the spike rounds and Team Deathmatch pick too", spike ~= nil and spike ~= FREE and tdm ~= nil and tdm ~= FREE)
	check(
		"but nobody between matches",
		AgentSelect.moment("skirmish", "matchOver", 3, 1, true) == nil and AgentSelect.moment("skirmish", "vote", 3, 1, true) == nil
	)
	check("nor off a side, in line or in the Play menu", AgentSelect.moment("skirmish", "buy", 3, 1, false) == nil)
	check(
		"nor in gun game or deathmatch, with no abilities",
		AgentSelect.moment("gungame", "live", 1, 1, true) == nil and AgentSelect.moment("deathmatch", "waiting", 1, 1, true) == nil
	)
end

do
	check("on the kit at once on the course", AgentSelect.swapsNow(nil, true, false))
	check("while they're down", AgentSelect.swapsNow("live", false, false))
	check(
		"while a mode waits, in a buy phase and in the pre-game",
		AgentSelect.swapsNow("waiting", true, false)
			and AgentSelect.swapsNow("buy", true, false)
			and AgentSelect.swapsNow("pregame", true, false)
	)
	check("and in their own spawn room", AgentSelect.swapsNow("live", true, true))
	check(
		"but alive in a round, its end or a planted spike's, with the next life",
		not AgentSelect.swapsNow("live", true, false)
			and not AgentSelect.swapsNow("roundOver", true, false)
			and not AgentSelect.swapsNow("planted", true, false)
	)
end

-- Picking ------------------------------------------------------------------------------------

do
	local a = AgentSelect.new({ JETT, OTHER })
	local pick = AgentSelect.pickOf(a, 1)
	check("a new player plays the default agent, with nothing to pick", pick.agent == JETT and pick.status == "none")
	check("and can't select one", not AgentSelect.select(a, 1, OTHER) and pick.selected == JETT)
	check("nor lock one in", AgentSelect.lock(a, 1) == nil and pick.agent == JETT)

	check("where it's free, nothing changes by itself", AgentSelect.update(a, 1, FREE, 0) == nil and pick.status == "free")
	check("and an agent can be selected", AgentSelect.select(a, 1, OTHER) and pick.selected == OTHER and pick.agent == JETT)
	check("but not one that can't be picked", not AgentSelect.select(a, 1, "nobody") and pick.selected == OTHER)
	check("locked in, it's theirs at once", AgentSelect.lock(a, 1) == OTHER and pick.agent == OTHER and pick.status == "free")
	AgentSelect.select(a, 1, JETT)
	check("and they can pick again", AgentSelect.lock(a, 1) == JETT and pick.agent == JETT)
	check("locking in what they play changes nothing", AgentSelect.lock(a, 1) == nil and pick.agent == JETT)

	check(
		"off a side, nobody picks",
		AgentSelect.update(a, 1, nil, 1) == nil and pick.status == "none" and not AgentSelect.select(a, 1, OTHER)
	)
	AgentSelect.leave(a, 1)
	check("and someone who leaves starts over if they come back", a.picks[1] == nil and AgentSelect.agentOf(a, 1) == JETT)
end

-- A window ------------------------------------------------------------------------------------

do
	local a = AgentSelect.new({ JETT, OTHER })
	local pick = AgentSelect.pickOf(a, 1)
	check("a match opens a window", AgentSelect.update(a, 1, "m1", 100) == nil and pick.status == "open" and pick.closesAt == 100 + TIME)
	check("with the agent they play selected", pick.selected == JETT)
	check("they select another", AgentSelect.select(a, 1, OTHER) and pick.selected == OTHER and pick.agent == JETT)
	check("and select again", AgentSelect.select(a, 1, JETT) and AgentSelect.select(a, 1, OTHER) and pick.selected == OTHER)
	check("it's open until its time is up", AgentSelect.update(a, 1, "m1", 100 + TIME - 0.01) == nil and pick.status == "open")
	check(
		"when what's selected is locked in",
		AgentSelect.update(a, 1, "m1", 100 + TIME) == OTHER and pick.agent == OTHER and pick.status == "locked"
	)
	check("and it's theirs: they can't select", not AgentSelect.select(a, 1, JETT) and pick.selected == OTHER)
	check("nor lock in again", AgentSelect.lock(a, 1) == nil and pick.agent == OTHER)
	check("however long the match goes on", AgentSelect.update(a, 1, "m1", 1000) == nil and pick.status == "locked")

	check("between matches nobody picks", AgentSelect.update(a, 1, nil, 1001) == nil and pick.status == "none")
	check(
		"and the next match opens another window",
		AgentSelect.update(a, 1, "m2", 1002) == nil and pick.status == "open" and pick.selected == OTHER
	)
	check("locked in before its time", AgentSelect.select(a, 1, JETT) and AgentSelect.lock(a, 1) == JETT and pick.status == "locked")
	check("it's closed at once", pick.closesAt == 0 and not AgentSelect.select(a, 1, OTHER))
	check("and nothing more comes of its time", AgentSelect.update(a, 1, "m2", 1002 + TIME) == nil and pick.agent == JETT)

	AgentSelect.update(a, 1, "m3", 2000)
	check(
		"selecting nothing, they play on as before",
		AgentSelect.update(a, 1, "m3", 2000 + TIME) == nil and pick.agent == JETT and pick.status == "locked"
	)

	AgentSelect.update(a, 1, "m4", 3000)
	AgentSelect.select(a, 1, OTHER)
	check(
		"out of the match while it's open, what's selected is locked in",
		AgentSelect.update(a, 1, nil, 3001) == OTHER and pick.status == "none"
	)
	check("and back in it, there's no other window", AgentSelect.update(a, 1, "m4", 3002) == nil and pick.status == "locked")

	AgentSelect.update(a, 1, "m5", 4000)
	AgentSelect.select(a, 1, JETT)
	check("so it is as picking goes free", AgentSelect.update(a, 1, FREE, 4001) == JETT and pick.status == "free")
	AgentSelect.select(a, 1, OTHER)
	AgentSelect.lock(a, 1)
	check(
		"and an agent picked there carries on into the match",
		AgentSelect.update(a, 1, "m5", 4002) == nil and pick.agent == OTHER and pick.status == "locked"
	)

	AgentSelect.update(a, 1, "m6", 5000)
	AgentSelect.select(a, 1, JETT)
	check("straight into another match, the last window's pick is locked in", AgentSelect.update(a, 1, "m7", 5001) == JETT)
	check(
		"and the new match's window opens on it",
		pick.status == "open" and pick.match == "m7" and pick.selected == JETT and pick.closesAt == 5001 + TIME
	)
end

-- Skirmish, played --------------------------------------------------------------------------

do
	local a = AgentSelect.new({ JETT, OTHER })
	local s = ArenaRules.new(nil, dice(1, 1, 1, 1))
	local everyone = { 1, 2, 3, 4 }
	ArenaRules.join(s, 1, 0)
	stepAll(a, s, everyone, 0)
	check("alone, waiting for an opponent, it's free", s.phase == "waiting" and AgentSelect.pickOf(a, 1).status == "free")
	AgentSelect.select(a, 1, OTHER)
	check("so player 1 plays another agent at once", AgentSelect.lock(a, 1) == OTHER)

	ArenaRules.join(s, 2, 1)
	stepAll(a, s, everyone, 1)
	local p1, p2 = AgentSelect.pickOf(a, 1), AgentSelect.pickOf(a, 2)
	check("an opponent starts the match, and both have a window", s.phase == "buy" and p1.status == "open" and p2.status == "open")
	check("each on the agent they play", p1.selected == OTHER and p2.selected == JETT)
	check("that closes inside the buy phase", p1.closesAt == 1 + TIME and p1.closesAt < s.phaseEndsAt)
	AgentSelect.select(a, 2, OTHER)
	AgentSelect.select(a, 1, JETT)
	check("player 1 locks in", AgentSelect.lock(a, 1) == JETT and p1.status == "locked")
	local changed = stepAll(a, s, everyone, 1 + TIME)
	check(
		"and as the window closes, player 2's selection is locked in",
		count(changed) == 1 and changed[2] == OTHER and p2.status == "locked"
	)

	ArenaRules.step(s, s.phaseEndsAt)
	stepAll(a, s, everyone, s.phaseEndsAt)
	check("the round goes live with both locked in", s.phase == "live" and p1.status == "locked" and p2.status == "locked")

	ArenaRules.join(s, 3, 30)
	stepAll(a, s, everyone, 30)
	local p3 = AgentSelect.pickOf(a, 3)
	check("someone joining under way has a window of their own", s.members[3] ~= nil and p3.status == "open" and p3.closesAt == 30 + TIME)
	check("from the same match", p3.match == p1.match)

	-- To the match's end, side 1 winning every round, and on to the next.
	local t = 40
	local function skip()
		ArenaRules.skip(s, t)
		ArenaRules.step(s, t)
		stepAll(a, s, everyone, t)
		t += 1
	end
	for _ = 1, 40 do
		if s.phase == "matchOver" then
			break
		end
		skip()
	end
	check("between matches nobody picks", s.phase == "matchOver" and p1.status == "none" and p2.status == "none" and p3.status == "none")
	local before = s.match
	for _ = 1, 4 do
		if s.match ~= before then
			break
		end
		skip()
	end
	check(
		"the next match opens everyone's window again",
		s.match == before + 1 and s.phase == "buy" and p1.status == "open" and p2.status == "open" and p3.status == "open"
	)
	check("each on the agent they played", p1.selected == JETT and p2.selected == OTHER and p3.selected == JETT)
	changed = stepAll(a, s, everyone, t + TIME)
	check("and nobody picking, they play on as before", count(changed) == 0 and p1.agent == JETT and p2.agent == OTHER)

	ArenaRules.leave(s, 2, t + 20)
	stepAll(a, s, everyone, t + 20)
	check("a side empties: waiting, and it's free", s.phase == "waiting" and p1.status == "free")
	AgentSelect.select(a, 1, OTHER)
	check("so player 1 changes agent at once", AgentSelect.lock(a, 1) == OTHER)
	ArenaRules.join(s, 4, t + 30)
	stepAll(a, s, everyone, t + 30)
	local p4 = AgentSelect.pickOf(a, 4)
	check("and as an opponent comes, the match carries on", s.phase == "buy" and s.match == before + 1)
	check("with player 1's window gone and the new player's open", p1.status == "locked" and p1.agent == OTHER and p4.status == "open")
end

-- Selling back -------------------------------------------------------------------------------

do
	local s = Shop.new()
	local cloudburst, updraft = Shop.item("cloudburst"), Shop.item("updraft")
	assert(cloudburst and updraft)
	Shop.buyCharge(s, cloudburst)
	Shop.buyCharge(s, cloudburst)
	Shop.buyCharge(s, updraft)
	local price = 2 * cloudburst.price + updraft.price
	check("a new agent's kit sells back every charge bought this buy phase", Shop.sellCharges(s) == price, string.format("%d", price))
	check("and they're gone", next(s.charges) == nil and Shop.sellCharges(s) == 0)
end

return nil
