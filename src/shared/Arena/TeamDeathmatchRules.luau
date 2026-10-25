--!strict
-- Team Deathmatch (system 27), as plain state the offline tests can play:
-- the reference's Team Deathmatch on the spike rounds' maps
-- (TeamDeathmatchConfig):
--   * two sides of five, each with a spawn room of its own: the map's
--     attackers' spawn for side 1, its defenders' for side 2. Anyone over
--     waits in line for a place (Roster, system 21), and anyone joining
--     spawns at once
--   * each match starts with its pre-game, everyone held in their spawn room,
--     and then has 9 minutes 30 seconds in four stages: the first side to 100
--     kills wins, or at the time limit the side with more, and a tie is a
--     draw
--   * each stage has loadouts to pick from, a gun and the shield that comes
--     with it, and everyone carries the one they've picked for the stage
--     under way, with the sidearm they've picked for the first. Picks are
--     made outside a match, in line, while down, or in the spawn room; a new
--     stage's loadout is handed over a moment into it, or at once in the
--     spawn room, and a pick changed is handed over there, in the pre-game,
--     or with the next life
--   * the dead come back after 1.5 s in their side's spawn room, and can't be
--     hurt for 15 s unless they fire or leave it; from then on they burn
--     while they stay in it, and anyone in the other side's room burns at
--     once
--   * the map has pickups, up from each match's start to its end (system
--     28): weapon spawners, each with a gun of the stage's, one at random,
--     taken by running over it into an empty slot or with F in place of the
--     loadout's gun there, which comes back once it's spent or dropped (G
--     destroys it), or with the next stage's loadout; a spawner taken has
--     another gun after a wait, and each new stage gives them all new ones.
--     Recovery Orbs, run over to mend health and shield over a few seconds,
--     leave a zone a moment that mends the taker's allies as they walk into
--     it, and come back after a wait. The Ultimate Orbs come up together, a
--     while into the match and then every so often, each worth ultimate
--     points to whoever runs over it
--   * after the victory screen everyone votes for the next map, as in the
--     spike rounds (system 25, MapVote)
-- With no rounds to even the sides out between, they're evened out as
-- someone leaves, and whoever moves across spawns again on their new side.
-- With nobody on a side it waits, everyone coming back after the respawn
-- time and nothing going in the record, and once there's someone on each a
-- match starts over, from its pre-game.
--
-- No Roblox APIs here: the server's Arena module says who joins, leaves,
-- hurts, dies, fires, picks and stands where, and what time it is; it spawns
-- whoever these functions return, on the kit kitOf has for them, and hands
-- a new one over when rearms says to. PickupsServer says who runs over
-- what, mends them as mended says, and puts the spawners' guns on the
-- ground, where GroundGunsServer has them taken.

local ArenaConfig = require("./ArenaConfig")
local TeamDeathmatchConfig = require("./TeamDeathmatchConfig")
local MapPlan = require("../Match/MapPlan")
local MapVote = require("../Match/MapVote")
local Roster = require("../Match/Roster")
local SpikeMaps = require("../Match/SpikeMaps")
local WeaponConfig = require("../Weapons/WeaponConfig")

local A = ArenaConfig.Rules
local T = TeamDeathmatchConfig.Rules
local STAGES = TeamDeathmatchConfig.Stages
local GUNS = TeamDeathmatchConfig.SpawnerGuns

export type Phase = "waiting" | "pregame" | "live" | "matchOver" | "vote"

-- Which spawn room someone stands in: their side's, or the other side's.
export type Room = "own" | "enemy"

-- A weapon spawner (system 28): the gun on it, if it has one, and once it's
-- been taken, when it has another.
export type Spawner = { gun: TeamDeathmatchConfig.SpawnerGun?, readyAt: number? }
-- A Recovery Orb or an Ultimate Orb: whether it's up, and a Recovery Orb
-- taken, when it's up again.
export type Orb = { up: boolean, readyAt: number? }
-- What a Recovery Orb taken leaves where it was, for the taker's side,
-- until it ends: who it's mended already.
export type Zone = { position: vector, side: number, endsAt: number, served: { [number]: boolean } }
-- A Recovery Orb's buff on someone: mended up to `from`, until `ends`.
export type Buff = { from: number, ends: number }
-- The guns spawners have lent someone, by slot, in the stage they took them.
export type Lent = { stage: number, guns: { [number]: string } }

export type PickupKind = "recovery" | "ultimate"

export type State = {
	phase: Phase,
	members: { [number]: Roster.Member },
	queue: { number }, -- who's waiting for a place (Roster)
	joins: number,
	hurt: Roster.Hurt,
	score: { number }, -- by side: its kills this match
	match: number, -- counts the matches, from 1
	-- pregame: when the match starts; live: the time limit; matchOver and
	-- vote: when the next phase starts.
	phaseEndsAt: number,
	liveAt: number, -- when the match under way started, its pre-game over
	stage: number, -- the stage under way, from 1 (the first outside a match)
	stageAt: number, -- when it started
	matchWinner: number?, -- the side that won; nil for a draw
	-- By anyone playing or in line: the loadout they've picked for each
	-- stage, by its number in the stage's list. By member: the stage the kit
	-- they hold is for, when their life started, when their spawn protection
	-- ends, and while they're in a spawn room that burns them, when it next
	-- does.
	picks: { [number]: { number } },
	kitStage: { [number]: number },
	spawnedAt: { [number]: number },
	safeUntil: { [number]: number },
	burnAt: { [number]: number },
	-- The map's pickups (system 28), by their numbers in its lists
	-- (TeamDeathmatchConfig.Pickups): its weapon spawners, its Recovery Orbs
	-- and its Ultimate Orbs, and when the Ultimate Orbs next come up; the
	-- zones Recovery Orbs taken leave; and by member, the Recovery Orb's
	-- buff on them, the guns spawners have lent them, and whether their
	-- loadout's gun is owed back, a lent gun gone.
	spawners: { Spawner },
	recovery: { Orb },
	ultimate: { Orb },
	ultimateAt: number,
	zones: { Zone },
	mending: { [number]: Buff },
	lent: { [number]: Lent },
	owed: { [number]: boolean },
	-- Whose abilities start over with their next life: everyone's as a match
	-- starts, and each player's with their first life in it (AbilityServer).
	fresh: { [number]: boolean },
	-- The maps a match can be played on (keys of SpikeMaps.Maps), the one
	-- being played, and after a match the vote for the next.
	maps: { string },
	map: string,
	vote: MapVote.Vote?,
	roll: MapVote.Roll,
	version: number, -- goes up on every change, so the server knows to tell clients
}

local TeamDeathmatchRules = {}

-- The spawn rooms, by side: the map's attackers' spawn for side 1, its
-- defenders' for side 2.
TeamDeathmatchRules.ROOMS = { "AttackerSpawn", "DefenderSpawn" }

-- On `maps`, all three of the spike rounds' if none are given, the first
-- match on one of them at random; `roll` is the dice, math.random's unless
-- a test has its own.
function TeamDeathmatchRules.new(maps: { string }?, roll: MapVote.Roll?): State
	local pool = maps or SpikeMaps.MAPS
	local dice: MapVote.Roll = roll or math.random
	local s: State = {
		phase = "waiting",
		members = {},
		queue = {},
		joins = 0,
		hurt = {},
		score = { 0, 0 },
		match = 1,
		phaseEndsAt = 0,
		liveAt = 0,
		stage = 1,
		stageAt = 0,
		matchWinner = nil,
		picks = {},
		kitStage = {},
		spawnedAt = {},
		safeUntil = {},
		burnAt = {},
		spawners = {},
		recovery = {},
		ultimate = {},
		ultimateAt = math.huge,
		zones = {},
		mending = {},
		lent = {},
		owed = {},
		fresh = {},
		maps = pool,
		map = pool[dice(#pool)],
		vote = nil,
		roll = dice,
		version = 0,
	}
	TeamDeathmatchRules.clearPickups(s)
	return s
end

local manned = Roster.manned

-- The stage `elapsed` seconds into a match: each but the last lasts the
-- stage time, and the last the rest of the match.
function TeamDeathmatchRules.stageAt(elapsed: number): number
	return math.clamp(math.floor(elapsed / T.stageTime.value) + 1, 1, #STAGES)
end

-- How many seconds into a match a stage starts.
function TeamDeathmatchRules.stageStart(stage: number): number
	return (stage - 1) * T.stageTime.value
end

-- A new match: on the map the vote picked, if there was one, with
-- everyone's record cleared and no kills on either side.
local function newMatch(s: State)
	local vote = s.vote
	if vote then
		s.map = MapVote.winner(vote, s.roll)
		s.vote = nil
	end
	s.match += 1
	s.matchWinner = nil
	s.score = { 0, 0 }
	for _, m in s.members do
		Roster.clearRecord(m)
	end
	table.clear(s.hurt)
	TeamDeathmatchRules.clearPickups(s)
end

-- A match starts with its pre-game: the sides evened out, and everyone
-- spawning now in their side's room, on the first stage's loadouts.
local function startMatch(s: State, now: number): { number }
	if s.phase == "matchOver" or s.phase == "vote" then
		newMatch(s)
	end
	Roster.balance(s)
	s.phase = "pregame"
	s.phaseEndsAt = now + T.preGame.value
	s.stage, s.stageAt = 1, now
	s.matchWinner = nil
	s.score = { 0, 0 }
	table.clear(s.hurt)
	table.clear(s.burnAt)
	table.clear(s.lent)
	table.clear(s.owed)
	local out = {}
	for id, m in s.members do
		m.alive = true
		m.respawnAt = nil
		m.roundKills = 0
		m.played = true
		s.fresh[id] = true
		table.insert(out, id)
	end
	table.sort(out)
	s.version += 1
	return out
end

-- A gun for a weapon spawner: one of the stage's, at random.
local function rollGun(s: State): TeamDeathmatchConfig.SpawnerGun
	local list = GUNS[s.stage] or GUNS[1]
	return list[s.roll(#list)]
end

-- Every spawner with a new gun of the stage's: as the match starts, and as
-- each stage does.
local function restock(s: State)
	for _, spawner in s.spawners do
		spawner.gun, spawner.readyAt = rollGun(s), nil
	end
end

-- The pre-game is over and the match under way, from its first stage, with
-- everyone alive protected in their room as if they'd just spawned. The
-- pickups come up: a gun on every spawner and every Recovery Orb, and the
-- Ultimate Orbs a while in.
local function begin(s: State, now: number)
	s.phase = "live"
	s.liveAt = now
	s.phaseEndsAt = now + T.timeLimit.value
	s.stage, s.stageAt = 1, now
	for id, m in s.members do
		if m.alive then
			s.spawnedAt[id] = now
			s.safeUntil[id] = now + T.protectTime.value
		end
	end
	restock(s)
	for _, orb in s.recovery do
		orb.up, orb.readyAt = true, nil
	end
	s.ultimateAt = now + T.ultimateFirst.value
	s.version += 1
end

-- The match is over, won by `side`, or drawn with none: the victory
-- screen, for its time. The dead stay down.
local function finish(s: State, side: number?, now: number)
	s.matchWinner = side
	s.phase = "matchOver"
	s.phaseEndsAt = now + A.matchOverTime.value
	for _, m in s.members do
		m.respawnAt = nil
	end
	table.clear(s.safeUntil)
	table.clear(s.burnAt)
	TeamDeathmatchRules.clearPickups(s)
	s.version += 1
end

-- A side is empty: back to waiting, the match given up (a vote under way
-- ends there, and the next match is on the same map), and anyone dead comes
-- back after the respawn time.
local function wait(s: State, now: number)
	if s.phase ~= "waiting" then
		s.vote = nil
		newMatch(s)
	end
	s.phase = "waiting"
	s.stage, s.stageAt = 1, now
	table.clear(s.burnAt)
	-- The pickups go, and with them the guns spawners lent: outside a match
	-- everyone's on their loadout (rearms).
	TeamDeathmatchRules.clearPickups(s)
	table.clear(s.lent)
	table.clear(s.owed)
	for _, m in s.members do
		if not m.alive then
			m.respawnAt = now + T.respawnTime.value
		end
	end
	s.version += 1
end

-- Puts someone on a side with a place (Roster). Returns who to spawn now:
-- them, unless the match is over, or everyone as they make the numbers for
-- a match to start. With both sides full they're in line.
local function admit(s: State, id: number, now: number): { number }
	local spawnsNow = s.phase ~= "matchOver" and s.phase ~= "vote"
	local m = Roster.add(s, id, T.sideSize.value, spawnsNow, 0)
	s.version += 1
	if not m then
		return {}
	end
	s.fresh[id] = true
	if s.phase == "waiting" and manned(s) then
		return startMatch(s, now)
	end
	return if spawnsNow then { id } else {}
end

-- Someone joins. Returns who to spawn now.
function TeamDeathmatchRules.join(s: State, id: number, now: number): { number }
	if s.members[id] or Roster.placeInLine(s, id) then
		return {}
	end
	return admit(s, id, now)
end

-- Someone leaves, playing or in line, with their picks and their vote if
-- they had one. A place they leave goes to whoever's first in line, and if
-- that leaves the sides two or more apart, the last to join the bigger
-- moves across. Returns who to spawn now: whoever came in from the line,
-- and whoever moved across, on their new side.
function TeamDeathmatchRules.leave(s: State, id: number, now: number): { number }
	local playing = s.members[id] ~= nil
	if not Roster.remove(s, id) then
		return {}
	end
	s.picks[id], s.kitStage[id], s.spawnedAt[id], s.safeUntil[id], s.burnAt[id] = nil, nil, nil, nil, nil
	s.mending[id], s.lent[id], s.owed[id], s.fresh[id] = nil, nil, nil, nil
	local vote = s.vote
	if vote then
		MapVote.drop(vote, id)
	end
	s.version += 1
	if not playing then
		return {}
	end
	local out: { number } = {}
	local nextInLine = Roster.nextInLine(s, T.sideSize.value)
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
		if m.side ~= sides[other] and not table.find(out, other) and (s.phase == "pregame" or s.phase == "live") then
			-- Moved across: they play on, on their new side, from its room.
			m.alive = true
			m.respawnAt = nil
			table.insert(out, other)
		end
	end
	return out
end

-- Someone has been damaged by someone else: in a match, damage to an enemy
-- scores, and is an assist if a teammate of the attacker then kills them in
-- the same life (Roster).
function TeamDeathmatchRules.damaged(s: State, attacker: number, victim: number, amount: number)
	if s.phase == "live" and Roster.damaged(s, attacker, victim, amount) then
		s.version += 1
	end
end

-- Someone has died, killed by `killer` if anyone: in a match, a death in the
-- record, and for an enemy killer a kill for their side, which wins the
-- match at the kill target. They come back after the respawn time, unless
-- the match is over, on their loadout.
function TeamDeathmatchRules.died(s: State, id: number, now: number, killer: number?)
	local m = s.members[id]
	if not m or not m.alive then
		return
	end
	m.alive = false
	s.spawnedAt[id], s.safeUntil[id], s.burnAt[id] = nil, nil, nil
	-- A lent gun goes with them, and the buff on them.
	s.mending[id], s.lent[id], s.owed[id] = nil, nil, nil
	s.version += 1
	if s.phase == "waiting" or s.phase == "pregame" or s.phase == "live" then
		m.respawnAt = now + T.respawnTime.value
	end
	if s.phase == "live" then
		Roster.recordDeath(s, id, killer)
	end
	m.roundKills = 0
	s.hurt[id] = nil
	local by = if killer then s.members[killer] else nil
	if s.phase ~= "live" or not by or by.side == m.side then
		return
	end
	s.score[by.side] += 1
	if s.score[by.side] >= T.killTarget.value then
		finish(s, by.side, now)
	end
end

-- Someone's new life has started, at `now`: they can't be hurt for the
-- protection's time, unless they fire or leave their room.
function TeamDeathmatchRules.spawned(s: State, id: number, now: number)
	if s.members[id] then
		s.spawnedAt[id] = now
		s.safeUntil[id] = now + T.protectTime.value
		s.burnAt[id] = nil
	end
end

-- Someone's spawn protection is over before its time: they've fired (or
-- swung, or scoped), or stepped out of their spawn room. Returns whether
-- they had it.
function TeamDeathmatchRules.unprotect(s: State, id: number): boolean
	if s.safeUntil[id] == nil then
		return false
	end
	s.safeUntil[id] = nil
	return true
end

-- Whether someone's spawn protection is on.
function TeamDeathmatchRules.safe(s: State, id: number, now: number): boolean
	local untilTime = s.safeUntil[id]
	return untilTime ~= nil and now < untilTime
end

-- Which spawn room feet at `feet` (in the map's own metres) stand in on the
-- spike map `key`, for someone on `side`: their side's, the other side's, or
-- neither (nil). The HUD asks it of your own feet.
function TeamDeathmatchRules.roomAt(key: string, side: number, feet: vector): Room?
	local plan = SpikeMaps.Maps[key]
	if not plan then
		return nil
	end
	for i, name in TeamDeathmatchRules.ROOMS do
		local r = plan.room(name)
		if r and feet.x >= r.x0 and feet.x <= r.x1 and feet.z >= r.z0 and feet.z <= r.z1 then
			return if i == side then "own" else "enemy"
		end
	end
	return nil
end

-- Which spawn room someone playing stands in, with their feet at `feet`.
function TeamDeathmatchRules.roomOf(s: State, id: number, feet: vector): Room?
	local side = Roster.sideOf(s, id)
	return if side then TeamDeathmatchRules.roomAt(s.map, side, feet) else nil
end

-- Whether someone alive burns now for the spawn room they stand in (`room`,
-- roomOf's): in a match, their own once they've been alive the stay time,
-- the other side's at once, and either every burn interval while they're
-- in it.
function TeamDeathmatchRules.burns(s: State, id: number, now: number, room: Room?): boolean
	local m = s.members[id]
	local since = s.spawnedAt[id] or now
	local due = m ~= nil and m.alive and s.phase == "live" and (room == "enemy" or (room == "own" and now >= since + T.stayTime.value))
	if not due then
		s.burnAt[id] = nil
		return false
	end
	local at = s.burnAt[id]
	if at and now < at then
		return false
	end
	s.burnAt[id] = now + T.burnInterval.value
	return true
end

-- The pickups' clock, in a match: spawners taken have another gun once their
-- wait is over, Recovery Orbs taken come back after theirs, the Ultimate
-- Orbs come up together, and zones end.
local function pickupsStep(s: State, now: number)
	for _, spawner in s.spawners do
		local at = spawner.readyAt
		if not spawner.gun and at and now >= at then
			spawner.gun, spawner.readyAt = rollGun(s), nil
			s.version += 1
		end
	end
	for _, orb in s.recovery do
		local at = orb.readyAt
		if not orb.up and at and now >= at then
			orb.up, orb.readyAt = true, nil
			s.version += 1
		end
	end
	if now >= s.ultimateAt then
		for _, orb in s.ultimate do
			orb.up = true
		end
		while s.ultimateAt <= now do
			s.ultimateAt += T.ultimateEvery.value
		end
		s.version += 1
	end
	for i = #s.zones, 1, -1 do
		if now >= s.zones[i].endsAt then
			table.remove(s.zones, i)
			s.version += 1
		end
	end
end

-- Moves the clock on: the dead come back, the pre-game ends, the stages
-- follow one another, each with new guns on the spawners, the pickups come
-- and go, and the match ends at its time limit. Returns who to spawn now.
function TeamDeathmatchRules.step(s: State, now: number): { number }
	if s.phase == "waiting" or s.phase == "pregame" or s.phase == "live" then
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
		if s.phase == "pregame" and now >= s.phaseEndsAt then
			begin(s, now)
		elseif s.phase == "live" then
			local stage = TeamDeathmatchRules.stageAt(now - s.liveAt)
			if stage ~= s.stage then
				s.stage = stage
				s.stageAt = s.liveAt + TeamDeathmatchRules.stageStart(stage)
				restock(s)
				s.version += 1
			end
			pickupsStep(s, now)
			if now >= s.phaseEndsAt then
				-- Time's up: the side with more kills wins, and a tie's a draw.
				local a, b = s.score[1], s.score[2]
				finish(s, if a > b then 1 elseif b > a then 2 else nil, now)
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
function TeamDeathmatchRules.vote(s: State, id: number, option: number): boolean
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

-- Ends the phase now, for testing (Workspace's MatchConfig.SKIP): the
-- pre-game, the victory screen or the vote. In a match it moves on to the
-- next stage's start, and in the last ends it as if its time were up.
function TeamDeathmatchRules.skip(s: State, now: number)
	if s.phase == "live" and s.stage < #STAGES then
		local shift = s.liveAt + TeamDeathmatchRules.stageStart(s.stage + 1) - now
		s.liveAt -= shift
		s.phaseEndsAt -= shift
		s.version += 1
	elseif s.phase == "pregame" or s.phase == "live" or s.phase == "matchOver" or s.phase == "vote" then
		s.phaseEndsAt = now
		s.version += 1
	end
end

-- Loadouts --------------------------------------------------------------------------

-- The loadout someone has picked for a stage: by default its first.
function TeamDeathmatchRules.loadoutOf(s: State, id: number, stage: number): TeamDeathmatchConfig.Loadout
	local list = STAGES[stage] or STAGES[1]
	local picks = s.picks[id]
	local index = if picks then picks[stage] else nil
	return list[index or 1] or list[1]
end

-- What someone has picked for each stage, by the loadout's number in the
-- stage's list.
function TeamDeathmatchRules.picksOf(s: State, id: number): { number }
	local out = {}
	local picks = s.picks[id]
	for stage in STAGES do
		out[stage] = if picks and picks[stage] then picks[stage] else 1
	end
	return out
end

-- Whether someone may pick a loadout now, as the reference lets them "at
-- the start of the match or anytime you're in the Spawn Room": in line,
-- outside a match under way, while down (they're back in the room in a
-- moment), or in their own spawn room (`inRoom`).
function TeamDeathmatchRules.canPick(s: State, id: number, inRoom: boolean?): boolean
	local m = s.members[id]
	if not m then
		return Roster.placeInLine(s, id) ~= nil
	end
	return s.phase ~= "live" or not m.alive or inRoom == true
end

-- Someone picks the loadout `index` of `stage`'s list, if they may now
-- (canPick). Returns whether it counted: a loadout there is, and not the
-- one they had.
function TeamDeathmatchRules.pick(s: State, id: number, stage: number, index: number, inRoom: boolean?): boolean
	local list = STAGES[stage]
	if not list or not list[index] or not TeamDeathmatchRules.canPick(s, id, inRoom) then
		return false
	end
	local picks = s.picks[id]
	if not picks then
		picks = TeamDeathmatchRules.picksOf(s, id)
		s.picks[id] = picks
	end
	if picks[stage] == index then
		return false
	end
	picks[stage] = index
	s.version += 1
	return true
end

-- What someone carries in the stage under way, by slot, and the shield they
-- wear ("" for none): the stage's loadout, its gun in its slot, the first
-- stage's sidearm unless the stage's gun is a sidearm too, and the knife,
-- always; but a gun a spawner lent them in this stage in its slot, until
-- it's gone. Nil if they're not playing.
function TeamDeathmatchRules.kitOf(s: State, id: number): ({ string }?, string)
	if not s.members[id] then
		return nil, ""
	end
	local pick = TeamDeathmatchRules.loadoutOf(s, id, s.stage)
	local kit = { "", TeamDeathmatchRules.loadoutOf(s, id, 1).gun, "knife" }
	local def = WeaponConfig.Defs[pick.gun]
	if def and (def.slot == 1 or def.slot == 2) then
		kit[def.slot] = pick.gun
	end
	local lent = s.lent[id]
	if lent and lent.stage == s.stage then
		for slot, gun in lent.guns do
			kit[slot] = gun
		end
	end
	return kit, pick.shield
end

-- Someone has been handed the kit kitOf has for them, for the stage under
-- way: as their life starts, or as rearms lets them have it. Nothing's owed
-- them now, and a gun lent in another stage is gone.
function TeamDeathmatchRules.armed(s: State, id: number)
	if not s.members[id] then
		return
	end
	local lent = s.lent[id]
	if lent and lent.stage ~= s.stage then
		s.lent[id] = nil
		s.version += 1
	end
	if s.owed[id] then
		s.owed[id] = nil
		s.version += 1
	end
	if s.kitStage[id] ~= s.stage then
		s.kitStage[id] = s.stage
		s.version += 1
	end
end

-- Whether someone alive is to be handed the kit kitOf has for them now, in
-- place of what they hold, with `inRoom` whether they stand in their side's
-- spawn room: anywhere while waiting or in the pre-game; in a match, in
-- their room, anywhere once a lent gun's gone, or anywhere once a stage
-- their kit isn't for has been under way the swap's delay.
function TeamDeathmatchRules.rearms(s: State, id: number, now: number, inRoom: boolean): boolean
	local m = s.members[id]
	if not m or not m.alive or s.phase == "matchOver" or s.phase == "vote" then
		return false
	elseif s.phase ~= "live" or inRoom or s.owed[id] then
		return true
	end
	return (s.kitStage[id] or 0) < s.stage and now >= s.stageAt + T.swapDelay.value
end

-- Pickups (system 28) ---------------------------------------------------------------

-- Where the map played has its pickups, in its own metres (nil for a map
-- with none).
function TeamDeathmatchRules.pickupsOf(s: State): TeamDeathmatchConfig.Pickups?
	return TeamDeathmatchConfig.Pickups[s.map]
end

-- Every pickup of the map played empty or down, and no zones or buffs: as
-- the rules start, with each new map, and outside a match.
function TeamDeathmatchRules.clearPickups(s: State)
	local plan = TeamDeathmatchRules.pickupsOf(s)
	s.spawners, s.recovery, s.ultimate = {}, {}, {}
	if plan then
		for i in plan.spawners do
			s.spawners[i] = { gun = nil, readyAt = nil }
		end
		for i in plan.recovery do
			s.recovery[i] = { up = false, readyAt = nil }
		end
		for i in plan.ultimate do
			s.ultimate[i] = { up = false, readyAt = nil }
		end
	end
	s.ultimateAt = math.huge
	table.clear(s.zones)
	table.clear(s.mending)
	s.version += 1
end

-- Whether feet at `feet` run over a pickup standing at `at`, both in the
-- map's own metres.
local function runsOver(feet: vector, at: vector, range: number): boolean
	local d = at - feet
	return math.abs(d.y) <= T.orbHeight.value and d.x * d.x + d.z * d.z <= range * range
end

-- The Recovery Orb's buff starts on someone, at `now`, anew if it was on.
local function mend(s: State, id: number, now: number)
	s.mending[id] = { from = now, ends = now + T.recoveryTime.value }
	s.version += 1
end

-- What someone alive at `feet` (in the map's own metres) runs over now, in a
-- match. A Recovery Orb starts its buff on them, and leaves a zone where it
-- was that starts it on each of their side who walks into it while it
-- lasts, once; an Ultimate Orb's points are theirs. Returns the kind of orb
-- they took, if any (none for a zone).
function TeamDeathmatchRules.pickUp(s: State, id: number, feet: vector, now: number): PickupKind?
	local m = s.members[id]
	local plan = TeamDeathmatchRules.pickupsOf(s)
	if not m or not m.alive or s.phase ~= "live" or not plan then
		return nil
	end
	for _, zone in s.zones do
		if zone.side == m.side and not zone.served[id] and now < zone.endsAt and runsOver(feet, zone.position, T.zoneRadius.value) then
			zone.served[id] = true
			mend(s, id, now)
		end
	end
	for i, orb in s.recovery do
		local at = plan.recovery[i]
		if orb.up and runsOver(feet, at, T.orbRange.value) then
			orb.up, orb.readyAt = false, now + T.recoveryWait.value
			table.insert(s.zones, { position = at, side = m.side, endsAt = now + T.zoneTime.value, served = { [id] = true } })
			mend(s, id, now)
			return "recovery"
		end
	end
	for i, orb in s.ultimate do
		if orb.up and runsOver(feet, plan.ultimate[i], T.orbRange.value) then
			orb.up = false
			s.version += 1
			return "ultimate"
		end
	end
	return nil
end

-- How much of the Recovery Orb's buff someone has had since this last asked
-- for them, as a share of their most health and shield to mend them by:
-- over the buff's time, its share in all, evenly. The buff's over once it's
-- all had. Nothing for anyone without it.
function TeamDeathmatchRules.mended(s: State, id: number, now: number): number
	local buff = s.mending[id]
	if not buff then
		return 0
	end
	local upTo = math.min(now, buff.ends)
	local share = math.max(upTo - buff.from, 0) / T.recoveryTime.value * T.recoveryShare.value
	buff.from = upTo
	if upTo >= buff.ends then
		s.mending[id] = nil
		s.version += 1
	end
	return share
end

-- The gun on the spawner `index` (by its number in the map's list), if it
-- has one now.
function TeamDeathmatchRules.spawnerGun(s: State, index: number): TeamDeathmatchConfig.SpawnerGun?
	local spawner = s.spawners[index]
	return if spawner then spawner.gun else nil
end

-- Someone alive takes the gun on the spawner `index`: it stands empty for
-- its wait, and the gun is lent them in its slot for the stage under way,
-- in place of their loadout's, which comes back once it's gone (returned),
-- or with the next stage's loadout. Returns whether there was one to take.
function TeamDeathmatchRules.take(s: State, id: number, index: number, now: number): boolean
	local spawner = s.spawners[index]
	local m = s.members[id]
	local gun = if spawner then spawner.gun else nil
	local def = if gun then WeaponConfig.Defs[gun.gun] else nil
	if not spawner or not gun or not def or not m or not m.alive or (def.slot ~= 1 and def.slot ~= 2) then
		return false
	end
	spawner.gun, spawner.readyAt = nil, now + T.spawnerWait.value
	local held = s.lent[id]
	local lent: Lent = if held and held.stage == s.stage then held else { stage = s.stage, guns = {} }
	lent.guns[def.slot] = gun.gun
	s.lent[id] = lent
	s.version += 1
	return true
end

-- The gun a spawner has lent someone in `slot`, for the stage under way or
-- one before its loadout's handed over, if any.
function TeamDeathmatchRules.lentOf(s: State, id: number, slot: number): string?
	local lent = s.lent[id]
	return if lent then lent.guns[slot] else nil
end

-- Whether kitOf has a lent gun in `slot` for someone: one lent in the stage
-- under way. One lent in a stage before is in their hands until the new
-- stage's loadout is, but not in the kit.
function TeamDeathmatchRules.lends(s: State, id: number, slot: number): boolean
	local lent = s.lent[id]
	return lent ~= nil and lent.stage == s.stage and lent.guns[slot] ~= nil
end

-- A gun lent someone in `slot` is gone: spent, or destroyed with G. Their
-- loadout's gun is owed back, at once wherever they are (rearms).
function TeamDeathmatchRules.returned(s: State, id: number, slot: number)
	local lent = s.lent[id]
	if not lent or not lent.guns[slot] then
		return
	end
	lent.guns[slot] = nil
	if next(lent.guns) == nil then
		s.lent[id] = nil
	end
	s.owed[id] = true
	s.version += 1
end

-- Whether someone's abilities start over with the life they're spawning
-- into: as a match starts, and with their first life in it. Asking takes
-- the answer: it's yes once.
function TeamDeathmatchRules.startsOver(s: State, id: number): boolean
	local fresh = s.fresh[id] == true
	s.fresh[id] = nil
	return fresh
end

-- The role on the map of a side's spawn room: the attackers' for side 1, the
-- defenders' for side 2.
function TeamDeathmatchRules.roleOf(side: number): MapPlan.Role
	return if side == 1 then "attack" else "defend"
end

TeamDeathmatchRules.sideOf = Roster.sideOf

-- Which of their side's spawn spots someone takes (Roster).
TeamDeathmatchRules.spotOf = Roster.spotOf

return TeamDeathmatchRules
