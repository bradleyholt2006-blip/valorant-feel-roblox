--!strict
-- Who plays on each of the two sides (system 21), the same for the arena's
-- rounds (ArenaRules) and the spike rounds (MatchRules), as plain state the
-- offline tests can play:
--   * someone joins the side with fewer players (side 1 when level) while
--     it has a place: a side holds as many as the mode's teams, and anyone
--     over waits in line, first come first served, for a place to open
--   * before a round starts, the sides are evened out: while one has two or
--     more players than the other, the last to join it moves across, as a
--     Counter-Strike server balances its teams between rounds
--   * each member's record this match (system 16): kills, deaths, assists
--     and the combat score (MatchConfig.Score). An assist is damage to an
--     enemy a teammate then kills in the same life
--
-- No Roblox APIs here: the modes say who joins, leaves, hurts and dies, and
-- when what happens goes in the record.

local MatchConfig = require("./MatchConfig")

local S = MatchConfig.Score

export type Member = {
	side: number,
	order: number, -- when they joined, for their spawn spot and who moves across
	alive: boolean,
	respawnAt: number?, -- while waiting: when they come back
	-- The spike rounds' credits (system 14), and what they had as the round
	-- started, which the other side's scoreboard shows of them (system 16).
	-- Nothing in the arena.
	credits: number,
	startCredits: number,
	-- The match's record (system 16).
	kills: number,
	deaths: number,
	assists: number,
	score: number, -- combat score, every round so far
	rounds: number, -- rounds played to their end, for its average
	roundKills: number, -- kills this round, for the multikill bonus
	-- In this round from its start: not someone who joined it under way, so
	-- a round they sat out doesn't pull their average down.
	played: boolean,
}

-- By member: who on the other side has damaged their life under way, for
-- the assists when they die.
export type Hurt = { [number]: { [number]: boolean } }

-- What of a mode's state this keeps.
export type Sides = {
	members: { [number]: Member },
	queue: { number }, -- who's waiting for a place, first in line first
	joins: number,
	hurt: Hurt,
}

local Roster = {}

Roster.SIDES = 2

function Roster.count(s: Sides, side: number, aliveOnly: boolean): number
	local n = 0
	for _, m in s.members do
		if m.side == side and (m.alive or not aliveOnly) then
			n += 1
		end
	end
	return n
end

-- Both sides have someone on them.
function Roster.manned(s: Sides): boolean
	return Roster.count(s, 1, false) > 0 and Roster.count(s, 2, false) > 0
end

-- The side someone joining goes on, with `size` the most a side holds: the
-- one with fewer players, side 1 when level; nil when both are full.
function Roster.openSide(s: Sides, size: number): number?
	local a, b = Roster.count(s, 1, false), Roster.count(s, 2, false)
	local side = if b < a then 2 else 1
	return if math.min(a, b) < size then side else nil
end

-- Puts someone on the side with a place, alive or not, with `credits`.
-- Returns them, or nil once both sides are full and they're in line.
function Roster.add(s: Sides, id: number, size: number, alive: boolean, credits: number): Member?
	local side = Roster.openSide(s, size)
	if not side then
		table.insert(s.queue, id)
		return nil
	end
	s.joins += 1
	local m: Member = {
		side = side,
		order = s.joins,
		alive = alive,
		respawnAt = nil,
		credits = credits,
		startCredits = credits,
		kills = 0,
		deaths = 0,
		assists = 0,
		score = 0,
		rounds = 0,
		roundKills = 0,
		played = alive,
	}
	s.members[id] = m
	return m
end

-- Takes someone out, playing or in line. Returns whether they were either.
function Roster.remove(s: Sides, id: number): boolean
	local index = table.find(s.queue, id)
	if index then
		table.remove(s.queue, index)
		return true
	end
	if not s.members[id] then
		return false
	end
	s.members[id] = nil
	s.hurt[id] = nil
	return true
end

-- Whoever's first in line, taken out of it, if a side has a place for them.
function Roster.nextInLine(s: Sides, size: number): number?
	if #s.queue == 0 or not Roster.openSide(s, size) then
		return nil
	end
	return table.remove(s.queue, 1)
end

-- Where someone stands in line: 1 for the next to play; nil if they're not
-- in it.
function Roster.placeInLine(s: Sides, id: number): number?
	return table.find(s.queue, id)
end

-- Evens the sides out: while one has two or more players than the other, the
-- last to join it moves across. Returns whether anyone moved.
function Roster.balance(s: Sides): boolean
	local moved = false
	while true do
		local a, b = Roster.count(s, 1, false), Roster.count(s, 2, false)
		if math.abs(a - b) < 2 then
			return moved
		end
		local from = if a > b then 1 else 2
		local last: Member? = nil
		for _, m in s.members do
			if m.side == from and (last == nil or m.order > last.order) then
				last = m
			end
		end
		if not last then
			return moved
		end
		last.side = 3 - from
		moved = true
	end
end

function Roster.sideOf(s: Sides, id: number): number?
	local m = s.members[id]
	return if m then m.side else nil
end

-- Which of their side's spawn spots someone takes: 1 for the first on that
-- side, 2 for the next, and so on.
function Roster.spotOf(s: Sides, id: number): number?
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

-- The record -------------------------------------------------------------------

function Roster.clearRecord(m: Member)
	m.kills, m.deaths, m.assists = 0, 0, 0
	m.score, m.rounds, m.roundKills = 0, 0, 0
end

-- A round has been played to its end: it counts toward the average of
-- everyone who was in it from its start.
function Roster.roundPlayed(s: Sides)
	for _, m in s.members do
		if m.played then
			m.rounds += 1
		end
	end
end

-- What a kill scores, with `alive` enemies alive for it, the one killed
-- among them.
function Roster.killScore(alive: number): number
	return S.kill[math.clamp(alive, 1, #S.kill)].value
end

-- A combat score averaged over the rounds played (at least one), to the
-- nearest point: the scoreboard's ACS.
function Roster.average(score: number, rounds: number): number
	return math.floor(score / math.max(rounds, 1) + 0.5)
end

-- Damage to an enemy, `amount` taken from their health and shield, scores
-- for the attacker and counts toward an assist. Returns whether it went in
-- the record: not to or from a teammate, or anyone not playing.
function Roster.damaged(s: Sides, attacker: number, victim: number, amount: number): boolean
	local by, m = s.members[attacker], s.members[victim]
	if not by or not m or by.side == m.side or amount <= 0 then
		return false
	end
	by.score += amount * S.damage.value
	local hurt = s.hurt[victim]
	if not hurt then
		hurt = {}
		s.hurt[victim] = hurt
	end
	hurt[attacker] = true
	return true
end

-- A death goes in the record, with `killer` if anyone: a death, and for an
-- enemy killer a kill, scored by how many enemies were alive for it (call it
-- once they're down), with an assist for each of the killer's teammates who
-- damaged this life.
function Roster.recordDeath(s: Sides, id: number, killer: number?)
	local m = s.members[id]
	if not m then
		return
	end
	m.deaths += 1
	local by = if killer then s.members[killer] else nil
	if not by or by.side == m.side then
		return
	end
	by.kills += 1
	by.roundKills += 1
	local multi = if by.roundKills > 1 then S.multiKill.value else 0
	by.score += Roster.killScore(Roster.count(s, m.side, true) + 1) + multi
	local hurt = s.hurt[id]
	if hurt then
		for other in hurt do
			local helper = s.members[other]
			if other ~= killer and helper and helper.side == by.side then
				helper.assists += 1
			end
		end
	end
end

return Roster
