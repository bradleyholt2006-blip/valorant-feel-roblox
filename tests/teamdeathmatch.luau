--!strict
-- Team Deathmatch (system 27): two sides of five on the spike rounds' maps,
-- each spawning in a room of its own. A pre-game, then 9.5 minutes in four
-- stages: first to 100 kills, or the side with more when the time's up, or
-- a draw. Each stage has loadouts to pick from, a gun and its shield, handed
-- over a moment into the stage or at once in the spawn room. The dead are
-- back in 1.5 s, protected for 15 s, and burn if they stay in the room after
-- that, as anyone does in the other side's. Then the victory screen and the
-- vote for the next map.

local ArenaConfig = require("../src/shared/Arena/ArenaConfig")
local TeamDeathmatchConfig = require("../src/shared/Arena/TeamDeathmatchConfig")
local TeamDeathmatchRules = require("../src/shared/Arena/TeamDeathmatchRules")
local Health = require("../src/shared/Combat/Health")
local MapVote = require("../src/shared/Match/MapVote")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local H = require("./Harness")

local check = H.check

local A = ArenaConfig.Rules
local T = TeamDeathmatchConfig.Rules
local STAGES = TeamDeathmatchConfig.Stages
local R = TeamDeathmatchRules

-- Dice that roll what they're told, in turn, then 1s, and never more than
-- the number of sides.
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

local function same(a: { any }, b: { any }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

-- Players 1 to n joined at time 0 (odd ids on side 1, even on side 2), on
-- Outpost; with two or more, in the pre-game.
local function lobby(n: number): TeamDeathmatchRules.State
	local s = R.new(nil, dice())
	for id = 1, n do
		R.join(s, id, 0)
	end
	return s
end

-- The same, with the match under way from time `T.preGame`.
local function match(n: number): TeamDeathmatchRules.State
	local s = lobby(n)
	R.step(s, T.preGame.value)
	return s
end

-- `killer` kills `id` `times` times at `now`, each coming straight back.
local function kills(s: TeamDeathmatchRules.State, killer: number, id: number, times: number, now: number)
	for _ = 1, times do
		R.died(s, id, now, killer)
		s.members[id].alive = true
		s.members[id].respawnAt = nil
	end
end

-- A spot's feet, in the map's own metres, in each of the map's spawn rooms.
local function inside(name: string): vector
	local r = SpikeMaps.Maps.outpost.room(name)
	assert(r, name)
	return vector.create((r.x0 + r.x1) / 2, 0, (r.z0 + r.z1) / 2)
end

H.section("Team Deathmatch tests")

-- The rules' numbers ------------------------------------------------------------------

do
	local labelled = true
	for _, param in T do
		labelled = labelled
			and param.value > 0
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every number is more than zero, with a status and a source", labelled)
	check(
		"5v5, first to 100 kills in 9 minutes 30, back in 1.5 s and protected for 15: Riot's",
		T.sideSize.value == 5
			and T.killTarget.value == 100
			and T.timeLimit.value == 570
			and T.respawnTime.value == 1.5
			and T.protectTime.value == 15
			and T.stayTime.value == 15
			and T.sideSize.status == "confirmed"
			and T.killTarget.status == "confirmed"
			and T.timeLimit.status == "confirmed"
	)
	local last = T.timeLimit.value - R.stageStart(#STAGES)
	check(
		"four stages: 75 s each but the last, which has the rest, 345 s (the wiki's)",
		#STAGES == 4 and T.stageTime.value == 75 and last == 345 and T.stageTime.status == "community"
	)
	check("a 20 s pre-game, the wiki's", T.preGame.value == 20 and T.preGame.status == "community")
	check(
		"the stages' times, in order",
		R.stageAt(0) == 1
			and R.stageAt(74.9) == 1
			and R.stageAt(75) == 2
			and R.stageAt(150) == 3
			and R.stageAt(225) == 4
			and R.stageAt(569) == 4
			and R.stageAt(-1) == 1
			and R.stageAt(1e6) == 4
	)
end

do
	local guns, shields, sidearms, primaries = true, true, true, true
	for stage, list in STAGES do
		for _, loadout in list do
			local def = WeaponConfig.Defs[loadout.gun]
			guns = guns and def ~= nil and (def.slot == 1 or def.slot == 2)
			shields = shields and (loadout.shield == "" or WeaponConfig.Shields[loadout.shield] ~= nil)
			if def and stage == 1 then
				sidearms = sidearms and def.slot == 2
			elseif def and loadout.gun ~= "sheriff" then
				primaries = primaries and def.slot == 1
			end
		end
	end
	check("every loadout is a gun of ours, with a shield of ours or none", guns and shields)
	check("the first stage's are sidearms, carried on through the match", sidearms)
	check("and after it primaries, but stage 2's Sheriff", primaries)
	check(
		"the Classic with a Regen Shield (Patch 9.11), and the Sheriff with Light Armor (Patch 8.0)",
		STAGES[1][1].gun == "classic"
			and STAGES[1][1].shield == "regen"
			and STAGES[2][1].gun == "sheriff"
			and STAGES[2][1].shield == "light"
	)
	check(
		"the last stage the Phantom and the Vandal, in Heavy Armor",
		#STAGES[4] == 2 and STAGES[4][1].gun == "phantom" and STAGES[4][2].gun == "vandal" and STAGES[4][2].shield == "heavy"
	)

	-- The burn's numbers, as its source says.
	local hp = Health.new(WeaponConfig.Health.maxHealth.value, "heavy")
	local burns = 0
	while hp.alive and burns < 100 do
		Health.apply(hp, T.burnDamage.value, burns * T.burnInterval.value)
		burns += 1
	end
	check("ten burns kill from full health in Heavy Armor, 4.5 s from the first", burns == 10, tostring(burns))
end

-- The spawn rooms ----------------------------------------------------------------------

do
	for _, key in SpikeMaps.MAPS do
		local plan = SpikeMaps.Maps[key]
		local s = R.new({ key }, dice())
		R.join(s, 1, 0)
		R.join(s, 2, 0)
		local ok = true
		for side = 1, 2 do
			local spots = plan.spots(R.roleOf(side))
			ok = ok and #spots >= T.sideSize.value
			for _, spot in spots do
				ok = ok and R.roomOf(s, side, spot.feet) == "own" and R.roomOf(s, 3 - side, spot.feet) == "enemy"
			end
		end
		check(plan.NAME .. ": a spot for each of five in each side's room, in it, and in the other side's for the other", ok)
	end
	local s = lobby(2)
	check("side 1 in the attackers' room, side 2 in the defenders'", R.roleOf(1) == "attack" and R.roleOf(2) == "defend")
	check(
		"out in the map is neither room",
		R.roomOf(s, 1, vector.zero) == nil and R.roomOf(s, 1, inside("AttackerSpawn")) == "own" and R.roomOf(s, 3, vector.zero) == nil
	)
end

-- Joining, the pre-game and the line -----------------------------------------------------

do
	local s = R.new(nil, dice())
	check("on one of the spike rounds' maps", s.map == "outpost" and same(s.maps, SpikeMaps.MAPS))
	local first = R.join(s, 1, 0)
	check("alone, waiting for an opponent, spawning at once", s.phase == "waiting" and same(first, { 1 }))
	local both = R.join(s, 2, 3)
	check(
		"a second player starts the pre-game: everyone spawns, for 20 s",
		s.phase == "pregame" and same(both, { 1, 2 }) and s.phaseEndsAt == 3 + T.preGame.value
	)
	check("one a side", R.sideOf(s, 1) == 1 and R.sideOf(s, 2) == 2 and R.spotOf(s, 1) == 1)
	check("anyone joining the pre-game spawns at once", same(R.join(s, 3, 4), { 3 }) and R.sideOf(s, 3) == 1)
	R.died(s, 3, 5, 2)
	check("nothing goes in the record before the match", s.members[2].kills == 0 and s.members[3].deaths == 0 and s.score[2] == 0)
	check("and the dead come back after the respawn time", same(R.step(s, 5 + T.respawnTime.value), { 3 }))
	R.spawned(s, 3, 6.5)
	R.step(s, 3 + T.preGame.value)
	check(
		"the match starts as the pre-game ends, from the first stage, for 9.5 minutes",
		s.phase == "live" and s.stage == 1 and s.liveAt == 23 and s.phaseEndsAt == 23 + T.timeLimit.value
	)
	check(
		"with everyone protected in their room as if they'd just spawned",
		R.safe(s, 1, 23 + T.protectTime.value - 0.01) and not R.safe(s, 1, 23 + T.protectTime.value) and s.spawnedAt[3] == 23
	)
	check("anyone joining the match spawns at once", same(R.join(s, 4, 30), { 4 }) and R.sideOf(s, 4) == 2)

	local full = lobby(10)
	check("ten fill both sides", R.sideOf(full, 9) == 1 and R.sideOf(full, 10) == 2)
	check("an eleventh waits in line", #R.join(full, 11, 1) == 0 and full.queue[1] == 11 and full.members[11] == nil)
	check("and picks a loadout from it", R.pick(full, 11, 2, 2) and R.picksOf(full, 11)[2] == 2)
	local back = R.leave(full, 4, 2)
	check("someone leaving makes a place for them, and they spawn", same(back, { 11 }) and R.sideOf(full, 11) == 2)
	check("with the loadouts they picked in line", R.picksOf(full, 11)[2] == 2 and R.picksOf(full, 4)[2] == 1)
end

do
	local s = match(2)
	local out = R.leave(s, 2, 30)
	check("with nobody left on a side, back to waiting", s.phase == "waiting" and #out == 0 and s.match == 2)
	R.join(s, 5, 31)
	check("and a match starts over, from its pre-game, once there's someone on each", s.phase == "pregame")

	local four = match(5) -- 1, 3 and 5 on side 1; 2 and 4 on side 2
	R.died(four, 2, 30, 1)
	local moved = R.leave(four, 4, 31)
	check(
		"sides two apart even out: the last to join the bigger moves across and spawns",
		same(moved, { 5 }) and R.sideOf(four, 5) == 2 and four.members[5].alive
	)
	check("the kills they made stay with their old side", four.score[1] == 1 and four.score[2] == 0)
end

-- Kills, the score and the end ---------------------------------------------------------

do
	local s = match(4)
	local t = T.preGame.value + 10
	R.damaged(s, 3, 2, 40)
	R.died(s, 2, t, 1)
	check("an enemy's kill is a kill for their side", s.score[1] == 1 and s.score[2] == 0 and s.members[1].kills == 1)
	check("and damage before it an assist for the killer's teammate", s.members[3].assists == 1)
	check("a death in the record", s.members[2].deaths == 1 and not s.members[2].alive)
	check("back after 1.5 s", #R.step(s, t + T.respawnTime.value - 0.01) == 0 and same(R.step(s, t + T.respawnTime.value), { 2 }))
	R.died(s, 4, t + 2, nil)
	check("a death nobody caused is a death alone", s.members[4].deaths == 1 and s.score[1] == 1 and s.score[2] == 0)
	R.step(s, t + 4)
	R.died(s, 3, t + 5, 1)
	check("and a teammate's kill no kill at all", s.score[1] == 1 and s.members[1].kills == 1)

	R.step(s, t + 7)
	kills(s, 1, 2, T.killTarget.value - 2, t + 8)
	check("one short of 100, still on", s.phase == "live" and s.score[1] == T.killTarget.value - 1)
	R.died(s, 2, t + 9, 1)
	check(
		"the side to 100 kills first wins",
		s.phase == "matchOver"
			and s.matchWinner == 1
			and s.score[1] == T.killTarget.value
			and s.phaseEndsAt == t + 9 + A.matchOverTime.value
	)
	check("nobody comes back during the victory screen", #R.step(s, t + 12) == 0 and not s.members[2].alive)
	R.died(s, 4, t + 13, 1)
	check("and nothing goes in the record then", s.score[1] == T.killTarget.value and s.members[4].deaths == 1)

	R.step(s, s.phaseEndsAt)
	local vote = s.vote
	check("then the vote for the next map", s.phase == "vote" and vote ~= nil and #vote.options == A.voteChoices.value)
	R.vote(s, 1, 3)
	R.vote(s, 2, 3)
	local voted = if vote then vote.options[3] else nil
	local again = R.step(s, s.phaseEndsAt)
	check(
		"then the next match on the map voted for, from its pre-game, everyone spawning",
		s.phase == "pregame" and s.map == voted and s.match == 2 and same(again, { 1, 2, 3, 4 })
	)
	check(
		"with the record and the score cleared",
		s.members[1].kills == 0 and s.score[1] == 0 and s.score[2] == 0 and s.matchWinner == nil and s.stage == 1
	)
end

do
	local s = match(2)
	kills(s, 2, 1, 3, 30)
	kills(s, 1, 2, 2, 31)
	R.step(s, T.preGame.value + T.timeLimit.value - 0.01)
	check("on until the time limit", s.phase == "live")
	R.step(s, T.preGame.value + T.timeLimit.value)
	check("then the side with more kills wins", s.phase == "matchOver" and s.matchWinner == 2)

	local tie = match(2)
	kills(tie, 2, 1, 2, 30)
	kills(tie, 1, 2, 2, 31)
	R.step(tie, T.preGame.value + T.timeLimit.value)
	check("and a tie is a draw", tie.phase == "matchOver" and tie.matchWinner == nil)
end

-- Stages and loadouts --------------------------------------------------------------------

do
	local s = match(2)
	local start = s.liveAt
	R.step(s, start + T.stageTime.value - 0.01)
	check("the first stage for its time", s.stage == 1)
	R.step(s, start + T.stageTime.value + 0.2)
	check("then the second, from when it was due", s.stage == 2 and s.stageAt == start + T.stageTime.value)
	R.step(s, start + 3 * T.stageTime.value)
	check("then the fourth for the rest of the match", s.stage == 4 and s.stageAt == start + R.stageStart(4))
	R.step(s, s.phaseEndsAt - 1)
	check("and no fifth", s.stage == 4 and s.phase == "live")
end

do
	local s = lobby(2)
	local kit, shield = R.kitOf(s, 1)
	check(
		"by default the Classic with its Regen Shield, and the knife",
		kit ~= nil and same(kit, { "", "classic", "knife" }) and shield == "regen"
	)
	check("picked, by default, the first of each stage", same(R.picksOf(s, 1), { 1, 1, 1, 1 }))
	check(
		"a pick of a loadout there is counts, and not one there isn't",
		R.pick(s, 1, 1, 3)
			and not R.pick(s, 1, 1, 3)
			and not R.pick(s, 1, 1, 5)
			and not R.pick(s, 1, 5, 1)
			and not R.pick(s, 1, 0, 1)
			and not R.pick(s, 99, 1, 1)
	)
	R.pick(s, 1, 2, 2)
	R.pick(s, 1, 3, 4)
	R.pick(s, 1, 4, 2)
	check("each stage's pick kept", same(R.picksOf(s, 1), { 3, 2, 4, 2 }) and same(R.picksOf(s, 2), { 1, 1, 1, 1 }))
	kit, shield = R.kitOf(s, 1)
	check("the first stage: the Ghost, no shield", kit ~= nil and same(kit, { "", "ghost", "knife" }) and shield == "")
	s.stage = 2
	kit, shield = R.kitOf(s, 1)
	check(
		"the second: the Stinger in Heavy Armor, with the Ghost",
		kit ~= nil and same(kit, { "stinger", "ghost", "knife" }) and shield == "heavy"
	)
	kit, shield = R.kitOf(s, 2)
	check(
		"or the Sheriff, in the sidearm's place, in Light Armor",
		kit ~= nil and same(kit, { "", "sheriff", "knife" }) and shield == "light"
	)
	s.stage = 3
	kit, shield = R.kitOf(s, 1)
	check("the third: the Guardian in Light Armor", kit ~= nil and same(kit, { "guardian", "ghost", "knife" }) and shield == "light")
	s.stage = 4
	kit, shield = R.kitOf(s, 1)
	check("the fourth: the Vandal in Heavy Armor", kit ~= nil and same(kit, { "vandal", "ghost", "knife" }) and shield == "heavy")
	check("nobody's kit who isn't playing", R.kitOf(s, 99) == nil)
	R.leave(s, 1, 1)
	check("and someone's picks go with them", s.picks[1] == nil)
end

do
	local s = match(2)
	check("in the match, a pick out of the spawn room doesn't count", not R.pick(s, 1, 2, 3, false) and R.picksOf(s, 1)[2] == 1)
	check("in it, it does", R.pick(s, 1, 2, 3, true) and R.picksOf(s, 1)[2] == 3)
	R.died(s, 1, s.liveAt + 1, 2)
	check("and so does one while down", R.pick(s, 1, 3, 2) and R.picksOf(s, 1)[3] == 2)
	kills(s, 2, 1, T.killTarget.value, s.liveAt + 2)
	check("and once the match is over, anywhere", s.phase == "matchOver" and R.pick(s, 2, 4, 2))
end

do
	local s = lobby(2)
	R.armed(s, 1)
	check("in the pre-game, a new pick is handed over anywhere", R.rearms(s, 1, 1, false))
	R.step(s, T.preGame.value)
	local start = s.liveAt
	check("in the match, in the spawn room", R.rearms(s, 1, start + 1, true))
	check("but not out of it", not R.rearms(s, 1, start + 1, false))
	R.step(s, start + T.stageTime.value)
	local due = start + T.stageTime.value + T.swapDelay.value
	check("a new stage's loadout: not out of the room at first", not R.rearms(s, 1, due - 0.01, false))
	check("but at once in the room", R.rearms(s, 1, start + T.stageTime.value, true))
	check("and anywhere once the stage has been under way the swap's delay", R.rearms(s, 1, due, false))
	R.armed(s, 1)
	check("handed over, it's the stage's", s.kitStage[1] == 2 and not R.rearms(s, 1, due + 1, false))
	R.died(s, 1, due + 2, 2)
	check("and nothing for the dead", not R.rearms(s, 1, due + 2, true))
	kills(s, 1, 2, T.killTarget.value, due + 3)
	check("nor once the match is over", s.phase == "matchOver" and not R.rearms(s, 2, due + 4, true))
end

-- Protection and the spawn rooms' burn ----------------------------------------------------

do
	local s = match(2)
	local t = s.liveAt + 30
	R.died(s, 1, t, 2)
	R.step(s, t + T.respawnTime.value)
	local life = t + T.respawnTime.value + 0.3
	R.spawned(s, 1, life)
	check(
		"a new life can't be hurt for 15 s",
		R.safe(s, 1, life + T.protectTime.value - 0.01) and not R.safe(s, 1, life + T.protectTime.value)
	)
	check("until it fires or leaves the room", R.unprotect(s, 1) and not R.safe(s, 1, life + 1) and not R.unprotect(s, 1))

	check("the room doesn't burn its own for 15 s", not R.burns(s, 1, life + T.stayTime.value - 0.01, "own"))
	check("then burns them", R.burns(s, 1, life + T.stayTime.value, "own"))
	check(
		"every burn interval while they stay",
		not R.burns(s, 1, life + T.stayTime.value + T.burnInterval.value - 0.01, "own")
			and R.burns(s, 1, life + T.stayTime.value + T.burnInterval.value, "own")
	)
	check("not out of it", not R.burns(s, 1, life + 20, nil))
	check("and again at once on coming back", R.burns(s, 1, life + 20.1, "own"))
	check("the other side's room burns at once", R.burns(s, 2, life, "enemy") and not R.burns(s, 2, life + 0.1, "enemy"))

	local before = lobby(2)
	R.spawned(before, 1, 0)
	check("nothing burns before the match", not R.burns(before, 1, 30, "own") and not R.burns(before, 2, 30, "enemy"))
	R.died(s, 2, life + 21, 1)
	check("nor the dead, whose stay is over", not R.burns(s, 2, life + 22, "enemy") and s.spawnedAt[2] == nil)
end

-- Skipping, for testing ---------------------------------------------------------------------

do
	local s = lobby(2)
	R.skip(s, 5)
	R.step(s, 5)
	check("skipping ends the pre-game", s.phase == "live" and s.liveAt == 5)
	R.skip(s, 6)
	R.step(s, 6)
	check(
		"then moves the match on to the next stage's start",
		s.stage == 2 and s.stageAt == 6 and s.phaseEndsAt == 6 + T.timeLimit.value - T.stageTime.value
	)
	R.skip(s, 7)
	R.step(s, 7)
	R.skip(s, 8)
	R.step(s, 8)
	check("to the last", s.stage == 4 and s.phase == "live")
	R.skip(s, 9)
	R.step(s, 9)
	check("and in the last ends it as if the time were up", s.phase == "matchOver" and s.matchWinner == nil)
	R.skip(s, 10)
	R.step(s, 10)
	R.skip(s, 11)
	check("then the victory screen and the vote", s.phase == "vote" and #R.step(s, 11) == 2 and s.phase == "pregame")
end

return nil
