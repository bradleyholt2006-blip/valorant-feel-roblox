--!strict
-- Deathmatch (system 26), as plain state the offline tests can play: the
-- reference's FFA Deathmatch on the spike rounds' maps (DeathmatchConfig):
--   * everyone for themselves, up to 14 at once, and anyone over waits in
--     line for a place (system 21). Each player is a side of their own, so
--     the record (Roster) counts a kill of anyone else, and damage to anyone
--     someone else then kills is an assist
--   * the first to 40 kills wins the match, or after 9 minutes whoever has
--     the most, the first to that many on a tie
--   * the dead come back after 1.5 s, anywhere on the map (DeathmatchSpawns
--     picks where), with the guns they had: every gun is free, any time
--   * every death in a match leaves a health pack where it fell, for 10 s,
--     and whoever alive walks over it first takes it (the server heals them
--     and reloads the gun in their hands, as it does a killer's)
--   * after the victory screen everyone votes for the next map, as in the
--     spike rounds (system 25, MapVote)
-- With fewer than two playing it waits, everyone coming back after the
-- respawn time and nothing going in the record, and the match starts over,
-- everyone spawning, once there's a second.
--
-- No Roblox APIs here: the server's Arena module says who joins, leaves,
-- hurts, dies where and stands where, and what time it is, and spawns
-- whoever these functions return.

local ArenaConfig = require("./ArenaConfig")
local DeathmatchConfig = require("./DeathmatchConfig")
local MapVote = require("../Match/MapVote")
local Roster = require("../Match/Roster")
local SpikeMaps = require("../Match/SpikeMaps")
local WeaponConfig = require("../Weapons/WeaponConfig")

local A = ArenaConfig.Rules
local D = DeathmatchConfig.Rules

export type Phase = "waiting" | "live" | "matchOver" | "vote"

-- A health pack on the floor: where, in the map's own metres, and until when.
export type Pack = { id: number, position: vector, expiresAt: number }

export type State = {
	phase: Phase,
	members: { [number]: Roster.Member },
	queue: { number }, -- who's waiting for a place, first in line first
	joins: number,
	hurt: Roster.Hurt,
	match: number, -- counts the matches, from 1
	phaseEndsAt: number, -- live: the time limit; matchOver and vote: when the next phase starts
	winner: number?, -- whoever won
	-- By member: when they got to the kills they have, so the first there
	-- leads a tie.
	reached: { [number]: number },
	packs: { Pack },
	packCount: number, -- packs dropped so far, for each one's id
	-- The maps a match can be played on (keys of SpikeMaps.Maps), the one
	-- being played, and after a match the vote for the next.
	maps: { string },
	map: string,
	vote: MapVote.Vote?,
	roll: MapVote.Roll,
	version: number, -- goes up on every change, so the server knows to tell clients
}

local DeathmatchRules = {}

-- On `maps`, all three of the spike rounds' if none are given, the first
-- match on one of them at random; `roll` is the dice, math.random's unless
-- a test has its own.
function DeathmatchRules.new(maps: { string }?, roll: MapVote.Roll?): State
	local pool = maps or SpikeMaps.MAPS
	local dice: MapVote.Roll = roll or math.random
	return {
		phase = "waiting",
		members = {},
		queue = {},
		joins = 0,
		hurt = {},
		match = 1,
		phaseEndsAt = 0,
		winner = nil,
		reached = {},
		packs = {},
		packCount = 0,
		maps = pool,
		map = pool[dice(#pool)],
		vote = nil,
		roll = dice,
		version = 0,
	}
end

-- How many are playing, not waiting in line.
function DeathmatchRules.count(s: State): number
	local n = 0
	for _ in s.members do
		n += 1
	end
	return n
end

local count = DeathmatchRules.count

-- Whether `a` is ahead of `b`: more kills, or as many and there first, or
-- there at the same time and in the server first.
local function ahead(s: State, a: number, b: number): boolean
	local ma, mb = s.members[a], s.members[b]
	if ma.kills ~= mb.kills then
		return ma.kills > mb.kills
	end
	local ra, rb = s.reached[a] or 0, s.reached[b] or 0
	if ra ~= rb then
		return ra < rb
	end
	return ma.order < mb.order
end

-- Whoever leads, or nil with nobody playing.
function DeathmatchRules.leader(s: State): number?
	local best: number? = nil
	for id in s.members do
		if best == nil or ahead(s, id, best) then
			best = id
		end
	end
	return best
end

-- Someone's place in the match, 1 for whoever leads; nil if they're not
-- playing.
function DeathmatchRules.placeOf(s: State, id: number): number?
	if not s.members[id] then
		return nil
	end
	local place = 1
	for other in s.members do
		if other ~= id and ahead(s, other, id) then
			place += 1
		end
	end
	return place
end

-- A new match: on the map the vote picked, if there was one, with
-- everyone's record cleared and nothing on the floor.
local function newMatch(s: State)
	local vote = s.vote
	if vote then
		s.map = MapVote.winner(vote, s.roll)
		s.vote = nil
	end
	s.match += 1
	s.winner = nil
	for _, m in s.members do
		Roster.clearRecord(m)
	end
	table.clear(s.hurt)
	table.clear(s.packs)
end

-- The match starts: everyone spawning now.
local function startMatch(s: State, now: number): { number }
	if s.phase == "matchOver" or s.phase == "vote" then
		newMatch(s)
	end
	s.phase = "live"
	s.phaseEndsAt = now + D.timeLimit.value
	s.winner = nil
	table.clear(s.hurt)
	table.clear(s.packs)
	local out = {}
	for id, m in s.members do
		m.alive = true
		m.respawnAt = nil
		m.roundKills = 0
		m.played = true
		s.reached[id] = now
		table.insert(out, id)
	end
	table.sort(out)
	s.version += 1
	return out
end

-- The match is won by `id`: the victory screen, for its time. The dead stay
-- down, and the packs go.
local function win(s: State, id: number, now: number)
	s.winner = id
	s.phase = "matchOver"
	s.phaseEndsAt = now + A.matchOverTime.value
	for _, m in s.members do
		m.respawnAt = nil
	end
	table.clear(s.packs)
	s.version += 1
end

-- Fewer than two are playing: back to waiting, the match given up (a vote
-- under way ends there, and the next match is on the same map), and anyone
-- dead comes back after the respawn time.
local function wait(s: State, now: number)
	if s.phase ~= "waiting" then
		s.vote = nil
		newMatch(s)
	end
	s.phase = "waiting"
	table.clear(s.packs)
	for _, m in s.members do
		if not m.alive then
			m.respawnAt = now + D.respawnTime.value
		end
	end
	s.version += 1
end

-- Puts someone in the match, if it has a place, as a side of their own.
-- Returns who to spawn now: them, unless the match is over, or everyone as
-- they make the two a match needs. With every place taken they're in line.
local function admit(s: State, id: number, now: number): { number }
	s.version += 1
	if count(s) >= D.players.value then
		table.insert(s.queue, id)
		return {}
	end
	local spawnsNow = s.phase == "waiting" or s.phase == "live"
	s.joins += 1
	s.members[id] = {
		side = s.joins,
		order = s.joins,
		alive = spawnsNow,
		respawnAt = nil,
		credits = 0,
		startCredits = 0,
		kills = 0,
		deaths = 0,
		assists = 0,
		score = 0,
		rounds = 0,
		roundKills = 0,
		played = spawnsNow,
	}
	s.reached[id] = now
	if s.phase == "waiting" and count(s) >= 2 then
		return startMatch(s, now)
	end
	return if spawnsNow then { id } else {}
end

-- Someone joins. Returns who to spawn now.
function DeathmatchRules.join(s: State, id: number, now: number): { number }
	if s.members[id] or Roster.placeInLine(s, id) then
		return {}
	end
	return admit(s, id, now)
end

-- Someone leaves, playing or in line, with their vote if they had one. A
-- place they leave goes to whoever's first in line, and with fewer than two
-- left the match is given up. Returns who to spawn now: whoever came in
-- from the line.
function DeathmatchRules.leave(s: State, id: number, now: number): { number }
	local playing = s.members[id] ~= nil
	if not Roster.remove(s, id) then
		return {}
	end
	s.reached[id] = nil
	local vote = s.vote
	if vote then
		MapVote.drop(vote, id)
	end
	s.version += 1
	if not playing then
		return {}
	end
	local out: { number } = {}
	local nextInLine = table.remove(s.queue, 1)
	if nextInLine then
		out = admit(s, nextInLine, now)
	end
	if s.phase ~= "waiting" and count(s) < 2 then
		wait(s, now)
	end
	return out
end

-- Someone has been damaged by someone else: in a match, it scores, and
-- counts toward an assist (Roster).
function DeathmatchRules.damaged(s: State, attacker: number, victim: number, amount: number)
	if s.phase == "live" and Roster.damaged(s, attacker, victim, amount) then
		s.version += 1
	end
end

-- Someone has died with their feet at `position` (in the map's own metres),
-- killed by `killer` if anyone: in a match, a death in the record and for
-- anyone else a kill, which wins the match at the kill target, an assist for
-- everyone else who hurt this life, and a health pack where they fell. They
-- come back after the respawn time, unless the match is over.
function DeathmatchRules.died(s: State, id: number, now: number, killer: number?, position: vector?)
	local m = s.members[id]
	if not m or not m.alive then
		return
	end
	m.alive = false
	m.roundKills = 0
	s.version += 1
	if s.phase == "waiting" or s.phase == "live" then
		m.respawnAt = now + D.respawnTime.value
	end
	local hurt = s.hurt[id]
	if s.phase ~= "live" then
		s.hurt[id] = nil
		return
	end
	Roster.recordDeath(s, id, killer)
	-- Everyone's on a side of their own, so anyone else who hurt them helped.
	if hurt then
		for other in hurt do
			local helper = s.members[other]
			if helper and other ~= killer and other ~= id then
				helper.assists += 1
			end
		end
	end
	s.hurt[id] = nil
	if position then
		s.packCount += 1
		table.insert(s.packs, { id = s.packCount, position = position, expiresAt = now + D.packTime.value })
	end
	local by = if killer and killer ~= id then s.members[killer] else nil
	if killer and by then
		s.reached[killer] = now
		if by.kills >= D.killTarget.value then
			win(s, killer, now)
		end
	end
end

-- Someone stands with their feet at `position` (in the map's own metres):
-- if they're alive, the first health pack under them is theirs, and off the
-- floor. Returns it, or nil.
function DeathmatchRules.pickUp(s: State, id: number, position: vector, now: number): Pack?
	local m = s.members[id]
	if not m or not m.alive then
		return nil
	end
	for i, pack in s.packs do
		local d = pack.position - position
		if now < pack.expiresAt and math.abs(d.y) <= D.packHeight.value and d.x * d.x + d.z * d.z <= D.packRange.value ^ 2 then
			table.remove(s.packs, i)
			s.version += 1
			return pack
		end
	end
	return nil
end

-- Moves the clock on: packs left too long go, the dead come back, and the
-- match ends at its time limit. Returns who to spawn now.
function DeathmatchRules.step(s: State, now: number): { number }
	for i = #s.packs, 1, -1 do
		if now >= s.packs[i].expiresAt then
			table.remove(s.packs, i)
			s.version += 1
		end
	end
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
			-- Time's up: whoever leads wins.
			local leader = DeathmatchRules.leader(s)
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
function DeathmatchRules.vote(s: State, id: number, option: number): boolean
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
function DeathmatchRules.skip(s: State, now: number)
	if s.phase == "live" or s.phase == "matchOver" or s.phase == "vote" then
		s.phaseEndsAt = now
		s.version += 1
	end
end

-- Whether someone may buy, or change guns any other way: whenever they're
-- alive, in a match or waiting for one.
function DeathmatchRules.canPick(s: State, id: number): boolean
	local m = s.members[id]
	return m ~= nil and m.alive and (s.phase == "live" or s.phase == "waiting")
end

-- The most rounds a kill's reload puts in the magazine of the gun `id`:
-- the Ares and the Odin get 30 back, any other gun as many as it takes to
-- fill it (nil).
function DeathmatchRules.reloadFor(id: string?): number?
	local def = if id then WeaponConfig.Defs[id] else nil
	return if def and def.category == "heavy" then D.heavyReload.value else nil
end

DeathmatchRules.sideOf = Roster.sideOf

return DeathmatchRules
