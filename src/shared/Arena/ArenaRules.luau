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
-- No Roblox APIs here: the server's Arena module says who joins, leaves and
-- dies and what time it is, and spawns whoever these functions return, dead
-- or alive.

local ArenaConfig = require("./ArenaConfig")

local R = ArenaConfig.Rules

export type Phase = "waiting" | "buy" | "live" | "roundOver" | "matchOver"

export type Member = {
	side: number,
	order: number, -- when they joined, for their spawn spot
	alive: boolean,
	respawnAt: number?, -- while waiting: when they come back
}

export type State = {
	phase: Phase,
	members: { [number]: Member },
	joins: number,
	score: { number }, -- by side
	match: number, -- counts the matches, from 1, so the server knows a new one has started
	round: number, -- the round being played, or just played (0 before the first)
	phaseEndsAt: number, -- buy, roundOver and matchOver: when the next phase starts
	roundWinner: number?, -- the side that won the round just played
	matchWinner: number?,
	version: number, -- goes up on every change, so the server knows to tell clients
}

local ArenaRules = {}

ArenaRules.SIDES = 2

function ArenaRules.new(): State
	return {
		phase = "waiting",
		members = {},
		joins = 0,
		score = { 0, 0 },
		match = 1,
		round = 0,
		phaseEndsAt = 0,
		roundWinner = nil,
		matchWinner = nil,
		version = 0,
	}
end

local function count(s: State, side: number, aliveOnly: boolean): number
	local n = 0
	for _, m in s.members do
		if m.side == side and (m.alive or not aliveOnly) then
			n += 1
		end
	end
	return n
end

-- Both sides have someone on them.
local function manned(s: State): boolean
	return count(s, 1, false) > 0 and count(s, 2, false) > 0
end

local function newMatch(s: State)
	s.score = { 0, 0 }
	s.match += 1
	s.round = 0
	s.matchWinner = nil
end

-- Everyone comes back, in their spawn, for the next round's buy phase.
local function startRound(s: State, now: number): { number }
	if s.phase == "matchOver" then
		newMatch(s)
	end
	s.round += 1
	s.phase = "buy"
	s.phaseEndsAt = now + (if s.round == 1 then R.firstBuyTime.value else R.buyTime.value)
	s.roundWinner = nil
	local out = {}
	for id, m in s.members do
		m.alive = true
		m.respawnAt = nil
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

-- Someone joins, on the side with fewer players (side 1 when level).
-- Returns who to spawn now: them, or everyone when they make the numbers
-- for a round to start.
function ArenaRules.join(s: State, id: number, now: number): { number }
	if s.members[id] then
		return {}
	end
	s.joins += 1
	local side = if count(s, 2, false) < count(s, 1, false) then 2 else 1
	s.members[id] = { side = side, order = s.joins, alive = true, respawnAt = nil }
	s.version += 1
	if s.phase == "waiting" and manned(s) then
		return startRound(s, now)
	end
	return { id }
end

function ArenaRules.leave(s: State, id: number, now: number)
	if not s.members[id] then
		return
	end
	s.members[id] = nil
	s.version += 1
	if not manned(s) then
		if s.phase ~= "waiting" then
			wait(s, now)
		end
	elseif inRound(s) then
		-- They may have been the last one standing on their side.
		checkRoundEnd(s, now)
	end
end

function ArenaRules.died(s: State, id: number, now: number)
	local m = s.members[id]
	if not m or not m.alive then
		return
	end
	m.alive = false
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

function ArenaRules.sideOf(s: State, id: number): number?
	local m = s.members[id]
	return if m then m.side else nil
end

-- Which of their side's spawn spots someone takes: 1 for the first on that
-- side, 2 for the next, and so on.
function ArenaRules.spotOf(s: State, id: number): number?
	local m = s.members[id]
	if not m then
		return nil
	end
	local n = 1
	for _, other in s.members do
		if other.side == m.side and other.order < m.order then
			n += 1
		end
	end
	return n
end

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
