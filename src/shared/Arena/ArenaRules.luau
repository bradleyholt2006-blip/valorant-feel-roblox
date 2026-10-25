--!strict
-- The arena's rounds (system 7), as plain state the offline tests can play,
-- following the reference's Skirmish:
--   * two sides, and everyone spawns on theirs at the start of each round
--   * a buy phase first, held in spawn behind a barrier, to choose weapons
--   * then the round, with no timer, until one side has nobody left alive;
--     the other side scores
--   * the first side to winScore takes the match, and the next starts at 0-0
-- With nobody on one of the sides it waits, and anyone who dies comes back
-- after respawnTime.
--
-- Who plays on which side is Roster's (system 21), as in the spike rounds:
-- two a side, as in the reference's 2v2 queue, joining in a buy phase or
-- while waiting spawns at once, joining later waits for the next round, and
-- the sides are evened out before each round. So is the match's record,
-- for the scoreboard and the victory screen: kills, deaths, assists and
-- the combat score, counted in a round and after it, not while waiting for
-- an opponent or once the match is won.
--
-- No Roblox APIs here: the server's Arena module says who joins, leaves and
-- dies and what time it is, and spawns whoever these functions return, dead
-- or alive.

local ArenaConfig = require("./ArenaConfig")
local Roster = require("../Match/Roster")

local R = ArenaConfig.Rules

export type Phase = "waiting" | "buy" | "live" | "roundOver" | "matchOver"

export type Member = Roster.Member

export type State = {
	phase: Phase,
	members: { [number]: Member },
	queue: { number }, -- who's waiting for a place (Roster)
	joins: number,
	score: { number }, -- by side
	match: number, -- counts the matches, from 1, so the server knows a new one has started
	round: number, -- the round being played, or just played (0 before the first)
	phaseEndsAt: number, -- buy, roundOver and matchOver: when the next phase starts
	roundWinner: number?, -- the side that won the round just played
	matchWinner: number?,
	-- By member: who on the other side has damaged their life under way,
	-- for the assists when they die.
	hurt: Roster.Hurt,
	version: number, -- goes up on every change, so the server knows to tell clients
}

local ArenaRules = {}

ArenaRules.SIDES = 2

function ArenaRules.new(): State
	return {
		phase = "waiting",
		members = {},
		queue = {},
		joins = 0,
		score = { 0, 0 },
		match = 1,
		round = 0,
		phaseEndsAt = 0,
		roundWinner = nil,
		matchWinner = nil,
		hurt = {},
		version = 0,
	}
end

local count, manned = Roster.count, Roster.manned

local function newMatch(s: State)
	s.score = { 0, 0 }
	s.match += 1
	s.round = 0
	s.matchWinner = nil
	for _, m in s.members do
		Roster.clearRecord(m)
	end
	table.clear(s.hurt)
end

-- Everyone comes back, in their spawn, for the next round's buy phase, with
-- the sides evened out.
local function startRound(s: State, now: number): { number }
	if s.phase == "matchOver" then
		newMatch(s)
	end
	Roster.balance(s)
	s.round += 1
	s.phase = "buy"
	s.phaseEndsAt = now + (if s.round == 1 then R.firstBuyTime.value else R.buyTime.value)
	s.roundWinner = nil
	table.clear(s.hurt)
	local out = {}
	for id, m in s.members do
		m.alive = true
		m.respawnAt = nil
		m.roundKills = 0
		m.played = true
		table.insert(out, id)
	end
	table.sort(out)
	s.version += 1
	return out
end

-- The round is over once a side has nobody left alive. It can't end with
-- both sides down: the first side out ends it, and the dead stay down until
-- the next round.
local function checkRoundEnd(s: State, now: number)
	local alive1, alive2 = count(s, 1, true), count(s, 2, true)
	if alive1 > 0 and alive2 > 0 then
		return
	end
	local winner = if alive1 == 0 then 2 else 1
	s.roundWinner = winner
	s.score[winner] += 1
	Roster.roundPlayed(s)
	if s.score[winner] >= R.winScore.value then
		s.phase = "matchOver"
		s.matchWinner = winner
		s.phaseEndsAt = now + R.matchOverTime.value
	else
		s.phase = "roundOver"
		s.phaseEndsAt = now + R.roundOverTime.value
	end
	s.version += 1
end

-- A side is empty: back to waiting. The score stays, unless the match was
-- already won, and anyone dead comes back after the respawn time.
local function wait(s: State, now: number)
	if s.phase == "matchOver" then
		newMatch(s)
	end
	s.phase = "waiting"
	s.roundWinner = nil
	for _, m in s.members do
		if not m.alive then
			m.respawnAt = now + R.respawnTime.value
		end
	end
	s.version += 1
end

local function inRound(s: State): boolean
	return s.phase == "buy" or s.phase == "live"
end

-- Puts someone on a side with a place (Roster). Returns who to spawn now:
-- them, in a buy phase or while waiting for an opponent, or everyone when
-- they make the numbers for a round to start. Later they're down until the
-- next round starts, and with both sides full they're in line.
local function admit(s: State, id: number, now: number): { number }
	local spawnsNow = s.phase == "waiting" or s.phase == "buy"
	local m = Roster.add(s, id, R.sideSize.value, spawnsNow, 0)
	s.version += 1
	if not m then
		return {}
	end
	if s.phase == "waiting" and manned(s) then
		return startRound(s, now)
	end
	return if spawnsNow then { id } else {}
end

-- Someone joins. Returns who to spawn now.
function ArenaRules.join(s: State, id: number, now: number): { number }
	if s.members[id] or Roster.placeInLine(s, id) then
		return {}
	end
	return admit(s, id, now)
end

-- Someone leaves, playing or in line. A place they leave goes to whoever's
-- first in line, as if they'd just joined. Returns who to spawn now.
function ArenaRules.leave(s: State, id: number, now: number): { number }
	local playing = s.members[id] ~= nil
	if not Roster.remove(s, id) then
		return {}
	end
	s.version += 1
	if not playing then
		return {}
	end
	local out: { number } = {}
	local nextInLine = Roster.nextInLine(s, R.sideSize.value)
	if nextInLine then
		out = admit(s, nextInLine, now)
	end
	if not manned(s) then
		if s.phase ~= "waiting" then
			wait(s, now)
		end
	elseif inRound(s) then
		-- They may have been the last one standing on their side.
		checkRoundEnd(s, now)
	end
	return out
end

-- Whether what happens now goes in the match's record: in a round or after
-- one, not while waiting for an opponent or once the match is won.
local function recorded(s: State): boolean
	return s.phase ~= "waiting" and s.phase ~= "matchOver"
end

-- Someone has been damaged by someone else, `amount` taken from their health
-- and shield: damage to an enemy scores, and is an assist if a teammate of
-- the attacker then kills them in the same life.
function ArenaRules.damaged(s: State, attacker: number, victim: number, amount: number)
	if recorded(s) and Roster.damaged(s, attacker, victim, amount) then
		s.version += 1
	end
end

-- Someone has died, killed by `killer` if anyone: in the record, a death,
-- and a kill and its score for an enemy killer, with an assist for each of
-- their teammates who damaged this life.
function ArenaRules.died(s: State, id: number, now: number, killer: number?)
	local m = s.members[id]
	if not m or not m.alive then
		return
	end
	m.alive = false
	if recorded(s) then
		Roster.recordDeath(s, id, killer)
	end
	s.hurt[id] = nil
	s.version += 1
	if s.phase == "waiting" then
		m.respawnAt = now + R.respawnTime.value
	elseif inRound(s) then
		checkRoundEnd(s, now)
	end
end

-- Moves the clock on. Returns who to spawn now.
function ArenaRules.step(s: State, now: number): { number }
	if s.phase == "waiting" then
		local out = {}
		for id, m in s.members do
			local at = m.respawnAt
			if not m.alive and at and now >= at then
				m.alive = true
				m.respawnAt = nil
				table.insert(out, id)
			end
		end
		if #out > 0 then
			table.sort(out)
			s.version += 1
		end
		return out
	end
	if now < s.phaseEndsAt then
		return {}
	end
	if s.phase == "buy" then
		s.phase = "live"
		s.version += 1
	elseif s.phase == "roundOver" or s.phase == "matchOver" then
		return startRound(s, now)
	end
	return {}
end

ArenaRules.sideOf = Roster.sideOf

-- Which of their side's spawn spots someone takes (Roster).
ArenaRules.spotOf = Roster.spotOf

-- The spawn barriers hold everyone in during the buy phase.
function ArenaRules.barriersUp(s: State): boolean
	return s.phase == "buy"
end

-- Whether someone may buy now (the buy menu, and the debug keys): in the buy
-- phase, as in the reference, and any time while there's nobody to play
-- against.
function ArenaRules.canPick(s: State, id: number): boolean
	return s.members[id] ~= nil and (s.phase == "buy" or s.phase == "waiting")
end

return ArenaRules
