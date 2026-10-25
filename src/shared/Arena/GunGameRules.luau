--!strict
-- Gun game (system 23), as plain state the offline tests can play: Counter-
-- Strike's Arms Race in the arena's hall, with the reference's guns
-- (GunGameConfig):
--   * two sides, as in Arms Race, but each player climbs a ladder of guns of
--     their own: a kill with the gun of their level moves them up to the
--     next, which is in their hands at once. The last level is the knife
--   * the first to make a kill on the last level wins the match, for
--     themselves and their side; or after the time limit, whoever's furthest
--     up (Escalation's rule)
--   * a knife kill also knocks the one killed down a level, unless they're
--     on the first, as in Arms Race
--   * the dead come back after the respawn time, in their side's room, on
--     their level's gun, and can't be hurt for a moment after they spawn,
--     or until they fire
--   * each match's ladder has one gun of each of GunGameConfig.Tiers, at
--     random, and after its victory screen everyone votes for the next
--     map, as in Skirmish (system 22, MapVote)
-- Who plays on which side is Roster's (system 21): someone joining spawns
-- at once, on the first gun, and anyone over the side's size waits in line.
-- With no rounds to even the sides out between, they're evened out as
-- someone leaves, and whoever moves across spawns again on their new side.
-- With nobody on a side it waits, everyone coming back after the respawn
-- time and nobody moving up, and the match starts over, everyone on the
-- first gun, once there's someone on each.
--
-- No Roblox APIs here: the server's Arena module says who joins, leaves,
-- spawns, fires and dies, with what, and what time it is, and spawns whoever
-- these functions return, on the gun of their level (kitOf).

local ArenaConfig = require("./ArenaConfig")
local ArenaLayout = require("./ArenaLayout")
local GunGameConfig = require("./GunGameConfig")
local MapVote = require("../Match/MapVote")
local Roster = require("../Match/Roster")
local WeaponConfig = require("../Weapons/WeaponConfig")

local A = ArenaConfig.Rules
local G = GunGameConfig.Rules

export type Phase = "waiting" | "live" | "matchOver" | "vote"

export type State = {
	phase: Phase,
	members: { [number]: Roster.Member },
	queue: { number }, -- who's waiting for a place (Roster)
	joins: number,
	hurt: Roster.Hurt,
	score: { number }, -- by side: the highest level on it, for the top bar
	match: number, -- counts the matches, from 1
	phaseEndsAt: number, -- live: the time limit; matchOver and vote: when the next phase starts
	matchWinner: number?, -- the side of the one who won
	winner: number?, -- the one who won
	-- The match's guns, a level each; the last is the knife.
	ladder: { string },
	-- By member: their level, the kills they've made on it, when they got
	-- there (who's further up, on a tie) and when their spawn protection
	-- ends.
	levels: { [number]: number },
	progress: { [number]: number },
	since: { [number]: number },
	safeUntil: { [number]: number },
	-- The maps a match can be played on (keys of ArenaLayout.Maps), the one
	-- being played, and after a match the vote for the next (system 22).
	maps: { string },
	map: string,
	vote: MapVote.Vote?,
	roll: MapVote.Roll,
	version: number, -- goes up on every change, so the server knows to tell clients
}

local GunGameRules = {}

-- A ladder of guns: one from each tier, at random, none twice.
function GunGameRules.rollLadder(roll: MapVote.Roll): { string }
	local out: { string } = {}
	for _, tier in GunGameConfig.Tiers do
		local left = {}
		for _, id in tier do
			if not table.find(out, id) then
				table.insert(left, id)
			end
		end
		table.insert(out, left[roll(#left)])
	end
	return out
end

-- On `maps`, all three of the arena's if none are given, the first match on
-- one of them at random; `roll` is the dice, math.random's unless a test
-- has its own.
function GunGameRules.new(maps: { string }?, roll: MapVote.Roll?): State
	local pool = maps or ArenaLayout.MAPS
	local dice: MapVote.Roll = roll or math.random
	local map = pool[dice(#pool)]
	return {
		phase = "waiting",
		members = {},
		queue = {},
		joins = 0,
		hurt = {},
		score = { 0, 0 },
		match = 1,
		phaseEndsAt = 0,
		matchWinner = nil,
		winner = nil,
		ladder = GunGameRules.rollLadder(dice),
		levels = {},
		progress = {},
		since = {},
		safeUntil = {},
		maps = pool,
		map = map,
		vote = nil,
		roll = dice,
		version = 0,
	}
end

local manned = Roster.manned

-- Someone's level, from the first.
local function setLevel(s: State, id: number, level: number, now: number)
	s.levels[id] = level
	s.progress[id] = 0
	s.since[id] = now
end

-- Each side's highest level.
local function updateScore(s: State)
	local best = { 0, 0 }
	for id, m in s.members do
		best[m.side] = math.max(best[m.side], s.levels[id] or 1)
	end
	s.score = best
end

-- Whoever's furthest up: the highest level, then the most kills on it, then
-- the first there, then the first to join.
function GunGameRules.leader(s: State): number?
	local best: number? = nil
	for id, m in s.members do
		local b = if best then s.members[best] else nil
		if not best or not b then
			best = id
			continue
		end
		local level, bestLevel = s.levels[id] or 1, s.levels[best] or 1
		local kills, bestKills = s.progress[id] or 0, s.progress[best] or 0
		local since, bestSince = s.since[id] or 0, s.since[best] or 0
		if
			level > bestLevel
			or (level == bestLevel and kills > bestKills)
			or (level == bestLevel and kills == bestKills and since < bestSince)
			or (level == bestLevel and kills == bestKills and since == bestSince and m.order < b.order)
		then
			best = id
		end
	end
	return best
end

-- A new match: on the map the vote picked, if there was one, with a new
-- ladder and everyone's record cleared.
local function newMatch(s: State)
	local vote = s.vote
	if vote then
		s.map = MapVote.winner(vote, s.roll)
		s.vote = nil
	end
	s.ladder = GunGameRules.rollLadder(s.roll)
	s.match += 1
	s.matchWinner, s.winner = nil, nil
	for _, m in s.members do
		Roster.clearRecord(m)
	end
	table.clear(s.hurt)
end

-- The match starts: everyone on the first gun, spawning now, with the sides
-- evened out.
local function startMatch(s: State, now: number): { number }
	if s.phase == "matchOver" or s.phase == "vote" then
		newMatch(s)
	end
	Roster.balance(s)
	s.phase = "live"
	s.phaseEndsAt = now + G.timeLimit.value
	s.matchWinner, s.winner = nil, nil
	table.clear(s.hurt)
	local out = {}
	for id, m in s.members do
		setLevel(s, id, 1, now)
		m.alive = true
		m.respawnAt = nil
		m.roundKills = 0
		m.played = true
		table.insert(out, id)
	end
	table.sort(out)
	updateScore(s)
	s.version += 1
	return out
end

-- The match is won by `id`: the victory screen, for its time.
local function win(s: State, id: number, now: number)
	local m = s.members[id]
	s.winner = id
	s.matchWinner = if m then m.side else nil
	s.phase = "matchOver"
	s.phaseEndsAt = now + A.matchOverTime.value
	for _, member in s.members do
		member.respawnAt = nil
	end
	s.version += 1
end

-- A side is empty: back to waiting, the match given up (a vote under way
-- ends there, and the next match is on the same map), everyone back on the
-- first gun, and anyone dead comes back after the respawn time.
local function wait(s: State, now: number)
	if s.phase ~= "waiting" then
		s.vote = nil
		newMatch(s)
	end
	s.phase = "waiting"
	for id, m in s.members do
		setLevel(s, id, 1, now)
		if not m.alive then
			m.respawnAt = now + G.respawnTime.value
		end
	end
	updateScore(s)
	s.version += 1
end

-- Puts someone on a side with a place (Roster), on the first gun. Returns
-- who to spawn now: them, unless the match is over, or everyone when they
-- make the numbers for a match to start. With both sides full they're in
-- line.
local function admit(s: State, id: number, now: number): { number }
	local spawnsNow = s.phase == "waiting" or s.phase == "live"
	local m = Roster.add(s, id, G.sideSize.value, spawnsNow, 0)
	s.version += 1
	if not m then
		return {}
	end
	setLevel(s, id, 1, now)
	if s.phase == "waiting" and manned(s) then
		return startMatch(s, now)
	end
	updateScore(s)
	return if spawnsNow then { id } else {}
end

-- Someone joins. Returns who to spawn now.
function GunGameRules.join(s: State, id: number, now: number): { number }
	if s.members[id] or Roster.placeInLine(s, id) then
		return {}
	end
	return admit(s, id, now)
end

-- Someone leaves, playing or in line, with their vote if they had one. A
-- place they leave goes to whoever's first in line, and if that leaves the
-- sides two or more apart, the last to join the bigger moves across.
-- Returns who to spawn now: whoever came in from the line, and whoever
-- moved across, on their new side.
function GunGameRules.leave(s: State, id: number, now: number): { number }
	local playing = s.members[id] ~= nil
	if not Roster.remove(s, id) then
		return {}
	end
	s.levels[id], s.progress[id], s.since[id], s.safeUntil[id] = nil, nil, nil, nil
	local vote = s.vote
	if vote then
		MapVote.drop(vote, id)
	end
	s.version += 1
	if not playing then
		return {}
	end
	local out: { number } = {}
	local nextInLine = Roster.nextInLine(s, G.sideSize.value)
	if nextInLine then
		out = admit(s, nextInLine, now)
	end
	if s.phase == "waiting" then
		return out
	end
	local sides: { [number]: number } = {}
	for other, m in s.members do
		sides[other] = m.side
	end
	Roster.balance(s)
	if not manned(s) then
		wait(s, now)
		return out
	end
	for other, m in s.members do
		if m.side ~= sides[other] and not table.find(out, other) then
			-- Moved across: they play on, on their new side, from its room.
			if s.phase == "live" then
				m.alive = true
				m.respawnAt = nil
				table.insert(out, other)
			end
		end
	end
	updateScore(s)
	return out
end

-- Whether what happens now goes in the match's record and moves anyone up:
-- in a match, not while waiting for an opponent or once it's won.
local function recorded(s: State): boolean
	return s.phase == "live"
end

-- Someone has been damaged by someone else: damage to an enemy scores, and
-- is an assist if a teammate of the attacker then kills them in the same
-- life (Roster).
function GunGameRules.damaged(s: State, attacker: number, victim: number, amount: number)
	if recorded(s) and Roster.damaged(s, attacker, victim, amount) then
		s.version += 1
	end
end

-- Someone has died, killed by `killer` with `weapon` if anyone: a death in
-- the record, and for an enemy killer a kill that moves them a step up the
-- ladder, and wins them the match on its last level. A knife kill also
-- knocks the one killed down a level. They come back after the respawn
-- time, unless the match is over.
function GunGameRules.died(s: State, id: number, now: number, killer: number?, weapon: string?)
	local m = s.members[id]
	if not m or not m.alive then
		return
	end
	m.alive = false
	s.safeUntil[id] = nil
	s.hurt[id] = nil
	s.version += 1
	if s.phase == "waiting" or s.phase == "live" then
		m.respawnAt = now + G.respawnTime.value
	end
	if not recorded(s) then
		return
	end
	local by = if killer then s.members[killer] else nil
	Roster.recordDeath(s, id, killer)
	if not killer or not by or by.side == m.side then
		return
	end
	if weapon == "knife" and (s.levels[id] or 1) > 1 then
		setLevel(s, id, s.levels[id] - 1, now)
	end
	local level = s.levels[killer] or 1
	s.progress[killer] = (s.progress[killer] or 0) + 1
	if s.progress[killer] >= G.killsPerLevel.value then
		if level >= #s.ladder then
			updateScore(s)
			win(s, killer, now)
			return
		end
		setLevel(s, killer, level + 1, now)
	end
	updateScore(s)
end

-- Someone's new life has started, at `now`: they can't be hurt for the
-- protection's time, unless they fire.
function GunGameRules.spawned(s: State, id: number, now: number)
	if s.members[id] then
		s.safeUntil[id] = now + G.protectTime.value
	end
end

-- Someone has fired (or swung, or scoped): their spawn protection is over.
-- Returns whether they had it.
function GunGameRules.fired(s: State, id: number): boolean
	if s.safeUntil[id] == nil then
		return false
	end
	s.safeUntil[id] = nil
	return true
end

-- Whether someone's spawn protection is on.
function GunGameRules.safe(s: State, id: number, now: number): boolean
	local untilTime = s.safeUntil[id]
	return untilTime ~= nil and now < untilTime
end

-- Moves the clock on. Returns who to spawn now.
function GunGameRules.step(s: State, now: number): { number }
	if s.phase == "waiting" or s.phase == "live" then
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
		if s.phase == "live" and now >= s.phaseEndsAt then
			-- Time's up: whoever's furthest up wins.
			local leader = GunGameRules.leader(s)
			if leader then
				win(s, leader, now)
			end
		end
		return out
	end
	if now < s.phaseEndsAt then
		return {}
	end
	if s.phase == "matchOver" and #s.maps > 1 then
		s.vote = MapVote.new(s.maps, A.voteChoices.value, s.roll)
		s.phase = "vote"
		s.phaseEndsAt = now + A.voteTime.value
		s.version += 1
		return {}
	end
	return startMatch(s, now)
end

-- Someone votes for the next map, by its number in the vote's list, or
-- changes their vote: anyone the rules know, playing or in line, while the
-- vote is on. Returns whether it counted.
function GunGameRules.vote(s: State, id: number, option: number): boolean
	local vote = s.vote
	if s.phase ~= "vote" or not vote or not (s.members[id] or Roster.placeInLine(s, id)) then
		return false
	end
	if not MapVote.cast(vote, id, option) then
		return false
	end
	s.version += 1
	return true
end

-- Ends the phase now, for testing (Workspace's MatchConfig.SKIP): the match
-- as if its time were up, the victory screen or the vote.
function GunGameRules.skip(s: State, now: number)
	if s.phase == "live" or s.phase == "matchOver" or s.phase == "vote" then
		s.phaseEndsAt = now
		s.version += 1
	end
end

-- Someone's level, from 1; nil if they're not playing.
function GunGameRules.levelOf(s: State, id: number): number?
	return if s.members[id] then s.levels[id] or 1 else nil
end

-- The gun of someone's level (a WeaponConfig id).
function GunGameRules.gunOf(s: State, id: number): string?
	local level = GunGameRules.levelOf(s, id)
	return if level then s.ladder[level] else nil
end

-- What someone carries on their level, by slot: its gun in its slot, and
-- the knife, always. On the last level, the knife alone.
function GunGameRules.kitOf(s: State, id: number): { string }?
	local gun = GunGameRules.gunOf(s, id)
	if not gun then
		return nil
	end
	local kit = { "", "", "knife" }
	local def = WeaponConfig.Defs[gun]
	if def and (def.slot == 1 or def.slot == 2) then
		kit[def.slot] = gun
	end
	return kit
end

GunGameRules.sideOf = Roster.sideOf

-- Which of their side's spawn spots someone takes (Roster).
GunGameRules.spotOf = Roster.spotOf

return GunGameRules
