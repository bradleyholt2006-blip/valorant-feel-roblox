--!strict
-- Rounds played for the spike (system 13), as plain state the offline tests
-- can play, following the reference's standard match:
--   * two sides: one attacks, with the spike, and the other defends; they
--     swap after a half (halfRounds), keeping the score
--   * each round starts with a buy phase, everyone held in their spawn
--     behind barriers, then gives the attackers roundTime to plant
--   * the attackers win a round by killing every defender or by the spike
--     going off; the defenders by killing every attacker before a plant, by
--     the clock running out before one, or by defusing it. Once it's
--     planted, killing every attacker isn't enough: it must be defused
--   * then a post-round phase, when nothing changes the result any more
--   * the first side to winScore takes the match. Tied a round short of it
--     at the end of regulation, the format's overtime decides: one more
--     round on the second half's sides, or rounds on alternate sides until
--     a side leads by two
-- With nobody on one of the sides it waits, and anyone who dies comes back
-- after respawnTime.
--
-- And the maps (system 25): the first match on one of SpikeMaps' at random,
-- and after each match's victory screen everyone votes for the next, as in
-- Skirmish (MapVote, with Skirmish's voteChoices and voteTime).
--
-- Who plays on which side is Roster's (system 21): someone who joins in a
-- buy phase, or while waiting for an opponent, spawns at once, and anyone
-- joining later waits for the next round to start; once both sides are full
-- they wait in line for a place, and the sides are evened out before each
-- round.
--
-- And the economy (system 14): each member's credits, and each side's
-- losses in a row. Everyone starts each half on Credits.start; each round
-- after pays, as it starts, for how the last one went: a win, a loss (more
-- for each in a row), or less for a loss survived; a kill pays the killer
-- and a plant every attacker, as they happen; nobody holds more than the
-- cap; and every overtime round starts everyone on Credits.overtime.
-- Swiftplay pays its own schedule in place of the win and the loss.
--
-- And the match's record (system 16), for the scoreboard, which Roster
-- keeps: each member's kills, deaths and assists, and their combat score
-- (MatchConfig.Score): damage to enemies, kills by how many enemies were
-- alive, and more for each kill after the first in a round. Everything
-- counts in a round and after it, not while waiting for an opponent or once
-- the match is won. And what each member had as the round started, which
-- the other side sees.
--
-- No Roblox APIs here: the server says who joins, leaves and dies, when the
-- spike is planted, defused or goes off, and what time it is, and spawns
-- whoever these functions return, dead or alive.

local ArenaConfig = require("../Arena/ArenaConfig")
local MapVote = require("./MapVote")
local MatchConfig = require("./MatchConfig")
local Roster = require("./Roster")
local SpikeMaps = require("./SpikeMaps")

local R = MatchConfig.Rules
local C = MatchConfig.Credits

export type Phase = "waiting" | "buy" | "live" | "planted" | "roundOver" | "matchOver" | "vote"
-- How a round was won.
export type Reason = "eliminated" | "detonated" | "defused" | "time"

export type Member = Roster.Member

export type State = {
	format: MatchConfig.Format,
	formatKey: string, -- its key in MatchConfig.Formats
	phase: Phase,
	members: { [number]: Member },
	queue: { number }, -- who's waiting for a place (Roster)
	joins: number,
	score: { number }, -- by side
	match: number, -- counts the matches, from 1, so the server knows a new one has started
	round: number, -- the round being played, or just played (0 before the first)
	attackers: number, -- the side attacking this round
	-- buy: when the round starts; live: when the clock runs out; planted:
	-- when the spike goes off; roundOver, matchOver and vote: when the next
	-- phase starts.
	phaseEndsAt: number,
	roundWinner: number?, -- the side that won the round just played
	reason: Reason?, -- and how
	matchWinner: number?,
	streak: { number }, -- by side: the rounds it has lost in a row
	spikePlanted: boolean, -- in the round being played, or just played
	-- By member: who on the other side has damaged their life under way,
	-- for the assists when they die (system 16).
	hurt: Roster.Hurt,
	-- The maps a match can be played on (keys of SpikeMaps.Maps), the one
	-- being played, and after a match the vote for the next (system 25).
	maps: { string },
	map: string,
	vote: MapVote.Vote?,
	roll: MapVote.Roll,
	version: number, -- goes up on every change, so the server knows to tell clients
}

-- What a round pays each side as the next starts, for winning it and for
-- losing it.
export type Payout = { won: number, lost: number }

local MatchRules = {}

MatchRules.SIDES = 2

-- A match in one of MatchConfig.Formats, by its key; the default format for
-- any other. On `maps`, all of SpikeMaps' if none are given, the first match
-- on one of them at random; `roll` is the dice, math.random's unless a test
-- has its own.
function MatchRules.new(format: string?, maps: { string }?, roll: MapVote.Roll?): State
	local key = if format and MatchConfig.Formats[format] then format else MatchConfig.DEFAULT_FORMAT
	local pool = maps or SpikeMaps.MAPS
	local dice: MapVote.Roll = roll or math.random
	return {
		format = MatchConfig.Formats[key],
		formatKey = key,
		phase = "waiting",
		members = {},
		queue = {},
		joins = 0,
		score = { 0, 0 },
		match = 1,
		round = 0,
		attackers = 1,
		phaseEndsAt = 0,
		roundWinner = nil,
		reason = nil,
		matchWinner = nil,
		streak = { 0, 0 },
		spikePlanted = false,
		hurt = {},
		maps = pool,
		map = pool[dice(#pool)],
		vote = nil,
		roll = dice,
		version = 0,
	}
end

-- The side attacking round `round`: side 1 in the first half, side 2 in the
-- second and in a sudden death; in a win-by-two overtime they take turns,
-- side 1 first.
function MatchRules.attackersIn(format: MatchConfig.Format, round: number): number
	local half = format.halfRounds.value
	if round <= half then
		return 1
	elseif round <= 2 * half or format.overtime == "suddenDeath" then
		return 2
	end
	return if (round - 2 * half) % 2 == 1 then 1 else 2
end

-- Whether round `round` is past regulation.
function MatchRules.overtime(format: MatchConfig.Format, round: number): boolean
	return round > 2 * format.halfRounds.value
end

-- How round `round` starts the ultimate's points (system 50,
-- AbilitySim.roundPoints): "match" for the first, "half" for the first of
-- the second half, "overtime" for one past regulation (a sudden death's
-- too), and "round" for any other.
export type RoundKind = "match" | "half" | "overtime" | "round"
function MatchRules.roundKind(format: MatchConfig.Format, round: number): RoundKind
	if round <= 1 then
		return "match"
	elseif round == format.halfRounds.value + 1 then
		return "half"
	elseif MatchRules.overtime(format, round) then
		return "overtime"
	end
	return "round"
end

local count, manned = Roster.count, Roster.manned

-- Whether the sides swap after round `round`: at the half, and after each
-- round of a win-by-two overtime.
function MatchRules.swapsAfter(format: MatchConfig.Format, round: number): boolean
	return MatchRules.attackersIn(format, round + 1) ~= MatchRules.attackersIn(format, round)
end

-- The side that has won a match on the score a - b, if either has: the
-- first to winScore or, tied a round short of it under a win-by-two
-- overtime, the first two rounds ahead.
function MatchRules.winner(format: MatchConfig.Format, a: number, b: number): number?
	local win = format.winScore.value
	if format.overtime == "winByTwo" and a >= win - 1 and b >= win - 1 then
		if a - b >= 2 then
			return 1
		elseif b - a >= 2 then
			return 2
		end
		return nil
	end
	if a >= win then
		return 1
	elseif b >= win then
		return 2
	end
	return nil
end

-- Which sides win the match if they win the next round, on the score a - b.
function MatchRules.matchPointOf(format: MatchConfig.Format, a: number, b: number): { boolean }
	return { MatchRules.winner(format, a + 1, b) == 1, MatchRules.winner(format, a, b + 1) == 2 }
end

-- What round `round` pays as the next starts, to the side that wins it and
-- to the side that loses it, `streak` the rounds the loser had lost in a row
-- before it; nil when the next round starts everyone over (a new half, or
-- overtime). Someone on the losing side who survives it, as an attacker
-- without the spike planted or as a defender after it went off, gets
-- Credits.survived instead (standard only).
function MatchRules.payout(format: MatchConfig.Format, round: number, streak: number): Payout?
	local half = format.halfRounds.value
	local nextRound = round + 1
	if MatchRules.overtime(format, nextRound) or nextRound == half + 1 or nextRound <= 1 then
		return nil
	end
	if format.economy == "swiftplay" then
		local step = MatchConfig.Swiftplay[(nextRound - 1) % half + 1]
		if not step then
			return nil
		end
		local bonus = step.won
		return { won = step.all.value + (if bonus then bonus.value else 0), lost = step.all.value }
	end
	return { won = C.win.value, lost = C.loss[math.min(streak + 1, #C.loss)].value }
end

local function give(m: Member, amount: number)
	m.credits = math.min(m.credits + amount, C.cap.value)
end

local function champion(s: State): number?
	return MatchRules.winner(s.format, s.score[1], s.score[2])
end

-- On the map the vote picked, if there was one.
local function newMatch(s: State)
	local vote = s.vote
	if vote then
		s.map = MapVote.winner(vote, s.roll)
		s.vote = nil
	end
	s.score = { 0, 0 }
	s.match += 1
	s.round = 0
	s.matchWinner = nil
	for _, m in s.members do
		Roster.clearRecord(m)
	end
	table.clear(s.hurt)
end

local function buyTime(s: State): number
	local half = s.format.halfRounds.value
	local round = s.round
	if round == 1 or round == half + 1 or round > 2 * half then
		return R.firstBuyTime.value
	end
	return R.buyTime.value
end

-- Whether someone lost the round just played and survived it, on its terms:
-- attacking, with the spike never planted; defending, with it gone off.
local function survivedLoss(s: State, m: Member): boolean
	if not m.alive or m.side == s.roundWinner then
		return false
	end
	return if m.side == s.attackers then not s.spikePlanted else s.reason == "detonated"
end

-- Credits for the round about to start, s.round + 1: the half's or
-- overtime's to start on, or the pay for the round just played, if it was
-- played out (not when it starts again after a wait).
local function payFor(s: State)
	local format = s.format
	local nextRound = s.round + 1
	local half = format.halfRounds.value
	if MatchRules.overtime(format, nextRound) or nextRound == 1 or nextRound == half + 1 then
		local amount = if MatchRules.overtime(format, nextRound) then C.overtime.value else C.start.value
		for _, m in s.members do
			m.credits = amount
		end
		s.streak = { 0, 0 }
		return
	end
	local winner = s.roundWinner
	if format.economy == "swiftplay" then
		local pay = MatchRules.payout(format, s.round, 0)
		if pay then
			for _, m in s.members do
				give(m, if m.side == winner then pay.won else pay.lost)
			end
		end
		return
	end
	if not winner then
		return
	end
	local loser = 3 - winner
	local pay = MatchRules.payout(format, s.round, s.streak[loser])
	if pay then
		for _, m in s.members do
			give(m, if m.side == winner then pay.won elseif survivedLoss(s, m) then C.survived.value else pay.lost)
		end
	end
	s.streak[winner] = 0
	s.streak[loser] += 1
end

-- Everyone comes back, in their side's spawn, for the next round's buy
-- phase, paid for the last round on the side they played it for, and then
-- with the sides evened out.
local function startRound(s: State, now: number): { number }
	if s.phase == "matchOver" or s.phase == "vote" then
		newMatch(s)
	end
	payFor(s)
	Roster.balance(s)
	s.round += 1
	s.attackers = MatchRules.attackersIn(s.format, s.round)
	s.phase = "buy"
	s.phaseEndsAt = now + buyTime(s)
	s.roundWinner = nil
	s.reason = nil
	s.spikePlanted = false
	table.clear(s.hurt)
	local out = {}
	for id, m in s.members do
		m.alive = true
		m.respawnAt = nil
		m.startCredits = m.credits
		m.roundKills = 0
		m.played = true
		table.insert(out, id)
	end
	table.sort(out)
	s.version += 1
	return out
end

local function endRound(s: State, winner: number, reason: Reason, now: number)
	s.roundWinner = winner
	s.reason = reason
	s.score[winner] += 1
	Roster.roundPlayed(s)
	local won = champion(s)
	if won then
		s.phase = "matchOver"
		s.matchWinner = won
		s.phaseEndsAt = now + R.matchOverTime.value
	else
		s.phase = "roundOver"
		s.phaseEndsAt = now + R.postRoundTime.value
	end
	s.version += 1
end

local function inRound(s: State): boolean
	return s.phase == "buy" or s.phase == "live" or s.phase == "planted"
end

-- A side with nobody left alive loses the round, unless it's the attackers
-- with the spike planted: then only a defuse or the spike decides it. It
-- can't end with both sides down: the first side out ends it.
local function checkElimination(s: State, now: number)
	if not inRound(s) then
		return
	end
	local attack = s.attackers
	local defend = 3 - attack
	if count(s, defend, true) == 0 then
		endRound(s, attack, "eliminated", now)
	elseif s.phase ~= "planted" and count(s, attack, true) == 0 then
		endRound(s, defend, "eliminated", now)
	end
end

-- A side is empty: back to waiting. The score stays, unless the match was
-- already won, and anyone dead comes back after the respawn time. A vote
-- under way ends there, and the next match is on the same map, as whoever's
-- left plays on in it.
local function wait(s: State, now: number)
	if s.phase == "matchOver" or s.phase == "vote" then
		s.vote = nil
		newMatch(s)
	end
	s.phase = "waiting"
	s.roundWinner = nil
	s.reason = nil
	for _, m in s.members do
		if not m.alive then
			m.respawnAt = now + R.respawnTime.value
		end
	end
	s.version += 1
end

-- Puts someone on a side with a place (Roster), with Credits.start, or
-- overtime's credits in overtime. Returns who to spawn now: them, in a buy
-- phase or while waiting for an opponent, or everyone when they make the
-- numbers for a round to start. Later they're down until the next round
-- starts, and with both sides full they're in line.
local function admit(s: State, id: number, now: number): { number }
	local credits = if MatchRules.overtime(s.format, s.round) then C.overtime.value else C.start.value
	local spawnsNow = s.phase == "waiting" or s.phase == "buy"
	local m = Roster.add(s, id, R.sideSize.value, spawnsNow, credits)
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
function MatchRules.join(s: State, id: number, now: number): { number }
	if s.members[id] or Roster.placeInLine(s, id) then
		return {}
	end
	return admit(s, id, now)
end

-- Someone leaves, playing or in line, with their vote if they had one. A
-- place they leave goes to whoever's first in line, as if they'd just
-- joined. Returns who to spawn now.
function MatchRules.leave(s: State, id: number, now: number): { number }
	local playing = s.members[id] ~= nil
	if not Roster.remove(s, id) then
		return {}
	end
	local vote = s.vote
	if vote then
		MapVote.drop(vote, id)
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
	else
		-- They may have been the last one standing on their side.
		checkElimination(s, now)
	end
	return out
end

-- Whether what happens now goes in the match's record: in a round or after
-- one, not while waiting for an opponent or once the match is won.
local function recorded(s: State): boolean
	return s.phase ~= "waiting" and s.phase ~= "matchOver" and s.phase ~= "vote"
end

-- What a kill scores, and a combat score averaged over the rounds played:
-- Roster's.
MatchRules.killScore = Roster.killScore
MatchRules.average = Roster.average

-- Someone has been damaged by someone else, `amount` taken from their health
-- and shield. Damage to an enemy scores, and is an assist if a teammate of
-- the attacker then kills them in the same life.
function MatchRules.damaged(s: State, attacker: number, victim: number, amount: number)
	if recorded(s) and Roster.damaged(s, attacker, victim, amount) then
		s.version += 1
	end
end

-- Someone has died, killed by `killer` if anyone: a kill of someone on the
-- other side, while a round is played, pays the killer. It goes in the
-- record: a death, and a kill and its score for an enemy killer, with an
-- assist for each of their teammates who damaged this life.
function MatchRules.died(s: State, id: number, now: number, killer: number?)
	local m = s.members[id]
	if not m or not m.alive then
		return
	end
	m.alive = false
	local by = if killer then s.members[killer] else nil
	if by and by.side ~= m.side and (s.phase == "live" or s.phase == "planted") then
		give(by, C.kill.value)
	end
	if recorded(s) then
		Roster.recordDeath(s, id, killer)
	end
	s.hurt[id] = nil
	s.version += 1
	if s.phase == "waiting" then
		m.respawnAt = now + R.respawnTime.value
	else
		checkElimination(s, now)
	end
end

-- Whether `by` can bring `id` back with Sage's Resurrection now (system
-- 39): while the round's played, `by` alive and `id` down, on one side.
function MatchRules.canRevive(s: State, by: number, id: number): boolean
	local a, b = s.members[by], s.members[id]
	return a ~= nil and b ~= nil and a.alive and not b.alive and a.side == b.side and (s.phase == "live" or s.phase == "planted")
end

-- Someone brought back by Sage's Resurrection, alive again as they burst
-- out (system 39). Only while the round's played, and only someone down.
-- Returns whether they are.
function MatchRules.revived(s: State, id: number): boolean
	local m = s.members[id]
	if not m or m.alive or (s.phase ~= "live" and s.phase ~= "planted") then
		return false
	end
	m.alive = true
	s.version += 1
	return true
end

-- Whether `id` can take over the bot `bot` now (system 62): in a format
-- that has it (MatchConfig's takeOver, not Competitive's), while the
-- round's played, `id` down and `bot` alive, on one side. The rules know
-- no bots: the server says which is one.
function MatchRules.canTakeOver(s: State, id: number, bot: number): boolean
	return s.format.takeOver and (s.phase == "live" or s.phase == "planted") and Roster.canTakeOver(s, id, bot)
end

-- `id` takes over `bot` (system 62): alive again in its place for the rest
-- of the round, and it down, with no death in the record (Roster.takeOver),
-- so each side has as many alive as before. Returns whether they did.
function MatchRules.tookOver(s: State, id: number, bot: number): boolean
	if not MatchRules.canTakeOver(s, id, bot) then
		return false
	end
	Roster.takeOver(s, id, bot)
	s.version += 1
	return true
end

-- The spike has been planted, to go off at `detonateAt`: the round's clock
-- gives way to the spike's, and every attacker is paid for it, alive or
-- not. Too late once the round is over.
function MatchRules.planted(s: State, detonateAt: number)
	if s.phase ~= "live" then
		return
	end
	s.phase = "planted"
	s.phaseEndsAt = detonateAt
	s.spikePlanted = true
	for _, m in s.members do
		if m.side == s.attackers then
			give(m, C.plant.value)
		end
	end
	s.version += 1
end

function MatchRules.defused(s: State, now: number)
	if s.phase == "planted" and now < s.phaseEndsAt then
		endRound(s, 3 - s.attackers, "defused", now)
	end
end

function MatchRules.detonated(s: State, now: number)
	if s.phase == "planted" then
		endRound(s, s.attackers, "detonated", now)
	end
end

-- Ends the phase now, for testing: the buy phase, the round (as its clock
-- running out), the wait for the next round, the victory screen or the
-- vote. Not a planted spike's countdown, which the spike keeps.
function MatchRules.skip(s: State, now: number)
	if s.phase == "buy" or s.phase == "live" or s.phase == "roundOver" or s.phase == "matchOver" or s.phase == "vote" then
		s.phaseEndsAt = now
		s.version += 1
	end
end

-- Moves the clock on. Returns who to spawn now.
function MatchRules.step(s: State, now: number): { number }
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
		s.phaseEndsAt = now + R.roundTime.value
		s.version += 1
	elseif s.phase == "live" then
		endRound(s, 3 - s.attackers, "time", now)
	elseif s.phase == "planted" then
		endRound(s, s.attackers, "detonated", now)
	elseif s.phase == "matchOver" and #s.maps > 1 then
		s.vote = MapVote.new(s.maps, ArenaConfig.Rules.voteChoices.value, s.roll)
		s.phase = "vote"
		s.phaseEndsAt = now + ArenaConfig.Rules.voteTime.value
		s.version += 1
	elseif s.phase == "roundOver" or s.phase == "matchOver" or s.phase == "vote" then
		return startRound(s, now)
	end
	return {}
end

-- Someone votes for the next map, by its number in the vote's list, or
-- changes their vote: anyone the rules know, playing or in line, while the
-- vote is on. Returns whether it counted.
function MatchRules.vote(s: State, id: number, option: number): boolean
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

MatchRules.sideOf = Roster.sideOf

-- Whether someone's side attacks this round.
function MatchRules.attacking(s: State, id: number): boolean
	local m = s.members[id]
	return m ~= nil and m.side == s.attackers
end

-- Which of their side's spawn spots someone takes (Roster).
MatchRules.spotOf = Roster.spotOf

-- The spawn barriers hold everyone in during the buy phase.
function MatchRules.barriersUp(s: State): boolean
	return s.phase == "buy"
end

-- Whether someone may buy now (the buy menu, and the debug keys): in the buy
-- phase, as in the reference, and any time while there's nobody to play
-- against.
function MatchRules.canPick(s: State, id: number): boolean
	return s.members[id] ~= nil and (s.phase == "buy" or s.phase == "waiting")
end

-- Whether the attackers may plant now: only while the round is live.
function MatchRules.canPlant(s: State): boolean
	return s.phase == "live"
end

-- Whether the round being played starts a half: everyone back on the
-- starting kit.
function MatchRules.startsHalf(s: State): boolean
	return s.round == 1 or s.round == s.format.halfRounds.value + 1
end

-- Whether the sides swap after the round being played.
function MatchRules.lastOfHalf(s: State): boolean
	return s.round == s.format.halfRounds.value
end

-- Which sides win the match if they win the next round.
function MatchRules.matchPoint(s: State): { boolean }
	return MatchRules.matchPointOf(s.format, s.score[1], s.score[2])
end

-- Someone's credits, if they're playing.
function MatchRules.credits(s: State, id: number): number?
	local m = s.members[id]
	return if m then m.credits else nil
end

-- Spends `amount` of someone's credits, a refund if it's negative, if they
-- have that many. Returns whether they did.
function MatchRules.spend(s: State, id: number, amount: number): boolean
	local m = s.members[id]
	if not m or amount > m.credits then
		return false
	end
	if amount ~= 0 then
		m.credits = math.min(m.credits - amount, C.cap.value)
		s.version += 1
	end
	return true
end

return MatchRules
