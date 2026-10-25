--!strict
-- Deathmatch (system 26): everyone for themselves on the spike rounds'
-- maps, up to 14 at once. The first to 40 kills wins, or after 9 minutes
-- whoever has the most. The dead are back in 1.5 s, wherever no living
-- enemy sees them and none is near, close to the action and away from where
-- they fell. Every death leaves a health pack for 10 s, which heals in full
-- and reloads, as every kill reloads the killer's gun. Every gun is free,
-- every life has Heavy Armor, and there are no abilities, Jett's glide
-- included. Then the victory screen and the vote for the next map.

local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local ArenaConfig = require("../src/shared/Arena/ArenaConfig")
local DeathmatchConfig = require("../src/shared/Arena/DeathmatchConfig")
local DeathmatchRules = require("../src/shared/Arena/DeathmatchRules")
local DeathmatchSpawns = require("../src/shared/Arena/DeathmatchSpawns")
local Health = require("../src/shared/Combat/Health")
local MapPlan = require("../src/shared/Match/MapPlan")
local MapVote = require("../src/shared/Match/MapVote")
local Roster = require("../src/shared/Match/Roster")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local PlayerSim = require("../src/shared/PlayerSim")
local Shop = require("../src/shared/Weapons/Shop")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check = H.check

local A = ArenaConfig.Rules
local D = DeathmatchConfig.Rules
local cfg = MovementConfig.resolve()

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

-- Dice from a seed, the same every run (Park and Miller's generator), for
-- the trials below.
local function seeded(seed: number): MapVote.Roll
	local state = seed % 2147483646 + 1
	return function(n: number): number
		state = state * 16807 % 2147483647
		return state % n + 1
	end
end

local function sorted(ids: { number }): string
	local copy = table.clone(ids)
	table.sort(copy)
	return table.concat(copy, ",")
end

-- A match under way between players 1 to n, joined at time 0.
local function match(n: number): DeathmatchRules.State
	local s = DeathmatchRules.new(nil, dice())
	for id = 1, n do
		DeathmatchRules.join(s, id, 0)
	end
	return s
end

-- `killer` kills `id` `times` times, each coming straight back.
local function kills(s: DeathmatchRules.State, killer: number, id: number, times: number, now: number)
	for _ = 1, times do
		DeathmatchRules.died(s, id, now, killer)
		s.members[id].alive = true
		s.members[id].respawnAt = nil
	end
end

H.section("Deathmatch tests")

-- The rules' numbers ------------------------------------------------------------------

do
	local labelled = true
	for _, param in D do
		labelled = labelled
			and param.value > 0
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every number is more than zero, with a status and a source", labelled)
	check(
		"14 players, first to 40 kills or the most in 9 minutes, back in 1.5 s: Riot's",
		D.players.value == 14
			and D.killTarget.value == 40
			and D.timeLimit.value == 9 * 60
			and D.respawnTime.value == 1.5
			and D.players.status == "confirmed"
			and D.killTarget.status == "confirmed"
			and D.timeLimit.status == "confirmed"
			and D.respawnTime.status == "confirmed"
	)
	check(
		"a health pack lasts 10 s, and a kill gives the Ares and the Odin 30 back: Riot's",
		D.packTime.value == 10 and D.heavyReload.value == 30
	)
	check(
		"a new life is kept farther from enemies than it looks for the action within",
		D.safeDistance.value < D.actionDistance.value and D.spotClearance.value > cfg.halfWidth
	)
	check("every life wears Heavy Armor", WeaponConfig.Shields[DeathmatchConfig.SHIELD] ~= nil and DeathmatchConfig.SHIELD == "heavy")
end

-- Joining, and the line ----------------------------------------------------------------

do
	local s = DeathmatchRules.new(nil, dice(2))
	check("the first match is on one of the spike rounds' maps, at random", s.map == SpikeMaps.MAPS[2] and #s.maps == 3)
	local first = DeathmatchRules.join(s, 10, 0)
	check("alone, someone waits for an opponent, and spawns at once", s.phase == "waiting" and sorted(first) == "10")
	local both = DeathmatchRules.join(s, 20, 5)
	check(
		"a second starts the match: both spawn, and the clock runs 9 minutes",
		s.phase == "live" and sorted(both) == "10,20" and s.phaseEndsAt == 5 + D.timeLimit.value
	)
	check(
		"each is a side of their own",
		DeathmatchRules.sideOf(s, 10) ~= nil and DeathmatchRules.sideOf(s, 10) ~= DeathmatchRules.sideOf(s, 20)
	)
	check("a third mid-match spawns at once", sorted(DeathmatchRules.join(s, 30, 6)) == "30" and s.members[30].alive)
	check("joining twice changes nothing", #DeathmatchRules.join(s, 30, 7) == 0 and DeathmatchRules.count(s) == 3)

	local full = match(D.players.value)
	local over = DeathmatchRules.join(full, 99, 1)
	check(
		"once 14 play, the next waits in line, first in it, without a life",
		#over == 0 and Roster.placeInLine(full, 99) == 1 and full.members[99] == nil and DeathmatchRules.count(full) == 14
	)
	local sides: { [number]: boolean } = {}
	local unique = true
	for _, m in full.members do
		unique = unique and not sides[m.side]
		sides[m.side] = true
	end
	check("and the 14 are 14 sides", unique)
	local came = DeathmatchRules.leave(full, 3, 2)
	check(
		"a place left goes to whoever's first in line, who spawns at once",
		sorted(came) == "99" and full.members[99] ~= nil and full.members[99].alive and #full.queue == 0
	)
end

-- Kills, assists and coming back ---------------------------------------------------------

do
	local s = match(3)
	DeathmatchRules.damaged(s, 3, 2, 40)
	DeathmatchRules.died(s, 2, 10, 1, vector.create(4, 0, 6))
	local m1, m2, m3 = s.members[1], s.members[2], s.members[3]
	check("a kill of anyone else counts, and the death", m1.kills == 1 and m2.deaths == 1 and m1.deaths == 0)
	check("whoever else hurt them has an assist", m3.assists == 1 and m1.assists == 0)
	check("damage to anyone scores", m3.score == 40)
	check("the dead come back after 1.5 s", #DeathmatchRules.step(s, 11.49) == 0 and sorted(DeathmatchRules.step(s, 11.5)) == "2")
	DeathmatchRules.died(s, 3, 12, 3)
	DeathmatchRules.died(s, 1, 12, nil)
	check(
		"dying by your own hand, or the world's, is a death and no kill",
		m3.deaths == 1 and m3.kills == 0 and m1.deaths == 1 and m1.kills == 1
	)
	DeathmatchRules.damaged(s, 2, 2, 30)
	check("nor does hurting yourself score", m2.score == 0)
end

do
	-- The first to 40.
	local s = match(3)
	kills(s, 1, 2, D.killTarget.value - 1, 20)
	check("39 kills isn't the match", s.phase == "live" and s.members[1].kills == 39)
	DeathmatchRules.died(s, 3, 30, 2)
	DeathmatchRules.died(s, 2, 31, 1)
	check(
		"the 40th wins it: the victory screen, for its 10 s",
		s.phase == "matchOver" and s.winner == 1 and s.phaseEndsAt == 31 + A.matchOverTime.value
	)
	check("the dead stay down, and the floor is cleared", s.members[2].respawnAt == nil and s.members[3].respawnAt == nil and #s.packs == 0)
	DeathmatchRules.died(s, 1, 32, 2)
	check("nothing after the end goes in the record", s.members[2].kills == 1 and s.members[1].deaths == 0)
end

do
	-- The time limit: the most kills, and on a tie the first to that many.
	local s = match(4)
	kills(s, 2, 1, 3, 100)
	kills(s, 3, 1, 3, 50)
	kills(s, 4, 1, 1, 10)
	check(
		"places by kills, the first to as many ahead",
		DeathmatchRules.placeOf(s, 3) == 1
			and DeathmatchRules.placeOf(s, 2) == 2
			and DeathmatchRules.placeOf(s, 4) == 3
			and DeathmatchRules.placeOf(s, 1) == 4
	)
	check("nobody else has a place", DeathmatchRules.placeOf(s, 99) == nil and DeathmatchRules.leader(s) == 3)
	DeathmatchRules.step(s, D.timeLimit.value - 0.01)
	check("the match runs to its time", s.phase == "live")
	DeathmatchRules.step(s, D.timeLimit.value)
	check("then whoever leads wins", s.phase == "matchOver" and s.winner == 3)
end

-- Health packs ---------------------------------------------------------------------------

do
	local s = match(3)
	local spot = vector.create(10, 0, -4)
	DeathmatchRules.died(s, 2, 10, 1, spot)
	local pack = s.packs[1]
	check(
		"a death leaves a pack where it fell, for 10 s",
		pack ~= nil and pack.position == spot and pack.expiresAt == 10 + D.packTime.value
	)
	check("not for someone a metre and a half away", DeathmatchRules.pickUp(s, 3, spot + vector.create(1.5, 0, 0), 11) == nil)
	check("nor the dead", DeathmatchRules.pickUp(s, 2, spot, 11) == nil)
	local taken = DeathmatchRules.pickUp(s, 3, spot + vector.create(0.6, 0.3, 0.6), 11)
	check("whoever alive walks over it takes it, and it's gone", taken == pack and #s.packs == 0)
	check("once", DeathmatchRules.pickUp(s, 1, spot, 11) == nil)

	DeathmatchRules.died(s, 3, 12, 1, spot)
	DeathmatchRules.step(s, 12 + D.packTime.value - 0.01)
	check("an untaken pack lasts its 10 s", #s.packs == 1)
	DeathmatchRules.step(s, 12 + D.packTime.value)
	check("and then goes", #s.packs == 0)

	local alone = match(1)
	DeathmatchRules.died(alone, 1, 5, nil, spot)
	check("waiting for an opponent, a death leaves none", #alone.packs == 0 and alone.members[1].respawnAt == 5 + D.respawnTime.value)
	check("each pack has an id of its own", s.packCount == 2)
end

-- The vote and the next match ------------------------------------------------------------

do
	local s = DeathmatchRules.new(nil, dice(1))
	for id = 1, 3 do
		DeathmatchRules.join(s, id, 0)
	end
	check("the first match on Outpost, as the dice have it", s.map == "outpost")
	kills(s, 1, 2, D.killTarget.value, 10)
	DeathmatchRules.step(s, 10 + A.matchOverTime.value)
	local vote = s.vote
	check(
		"after the victory screen, a vote for 15 s between all three maps",
		s.phase == "vote" and vote ~= nil and #vote.options == 3 and s.phaseEndsAt == 10 + A.matchOverTime.value + A.voteTime.value
	)
	check("anyone playing votes", DeathmatchRules.vote(s, 2, 3) and DeathmatchRules.vote(s, 3, 3))
	check("someone not in the server doesn't", not DeathmatchRules.vote(s, 42, 1))
	local back = DeathmatchRules.step(s, s.phaseEndsAt)
	check(
		"then a new match on the map with the votes, everyone spawning, the record cleared",
		s.phase == "live"
			and s.match == 2
			and vote ~= nil
			and s.map == vote.options[3]
			and sorted(back) == "1,2,3"
			and s.members[1].kills == 0
	)
	check("and the clock starts again", s.phaseEndsAt == 10 + A.matchOverTime.value + A.voteTime.value + D.timeLimit.value)
end

do
	local s = match(2)
	DeathmatchRules.died(s, 2, 3, 1, vector.zero)
	DeathmatchRules.leave(s, 2, 4)
	check("one left: back to waiting, the match given up and the floor cleared", s.phase == "waiting" and s.match == 2 and #s.packs == 0)
	check("and the record with it", s.members[1].kills == 0)
	check("the one left plays on", s.members[1].alive)
	local again = DeathmatchRules.join(s, 5, 6)
	check("a new opponent starts the match over", s.phase == "live" and sorted(again) == "1,5")
	DeathmatchRules.skip(s, 7)
	DeathmatchRules.step(s, 7)
	check("a skip ends it as its time would", s.phase == "matchOver")
end

-- Buying, and reloads ---------------------------------------------------------------------

do
	local s = match(2)
	check("buying is open to the living, any time in a match", DeathmatchRules.canPick(s, 1))
	DeathmatchRules.died(s, 1, 1, 2)
	check("not to the dead", not DeathmatchRules.canPick(s, 1))
	check("nor to anyone not playing", not DeathmatchRules.canPick(s, 3))
	kills(s, 2, 1, D.killTarget.value, 2)
	check("nor once the match is over", not DeathmatchRules.canPick(s, 2))

	local guns, others = true, true
	for _, group in WeaponConfig.Arsenal do
		for _, id in group.ids do
			local item = Shop.item(id)
			guns = guns and item ~= nil and DeathmatchConfig.FOR_SALE[item.kind] == true
		end
	end
	for _, id in WeaponConfig.ShieldIds do
		local item = Shop.item(id)
		others = others and item ~= nil and not DeathmatchConfig.FOR_SALE[item.kind]
	end
	local ability = Shop.item("updraft")
	others = others and ability ~= nil and not DeathmatchConfig.FOR_SALE[ability.kind]
	check("every gun is for sale, and no shield nor ability", guns and others)

	check(
		"a kill fills any gun's magazine, but the Ares and the Odin get 30",
		DeathmatchRules.reloadFor("vandal") == nil
			and DeathmatchRules.reloadFor("ares") == 30
			and DeathmatchRules.reloadFor("odin") == 30
			and DeathmatchRules.reloadFor(nil) == nil
	)
end

do
	local w = WeaponSim.newState({ "vandal", "classic", "knife", "" })
	w.ammo[1] = 5
	WeaponSim.reloadNow(w, 1)
	check("a reload at once fills the magazine from the reserve", w.ammo[1] == 25 and w.reserve[1] == 30)
	w.ammo[1], w.reserve[1] = 10, 3
	WeaponSim.reloadNow(w, 1)
	check("as far as the reserve goes", w.ammo[1] == 13 and w.reserve[1] == 0)
	w.ammo[1], w.reserve[1] = 0, 0
	w.reloadEndTime = 4
	WeaponSim.reloadNow(w, 1)
	check("with nothing left, nothing goes in, and a reload under way is over", w.ammo[1] == 0 and w.reloadEndTime == 0)

	local odin = WeaponSim.newState({ "odin", "classic", "knife", "" })
	odin.ammo[1] = 10
	WeaponSim.reloadNow(odin, 1, DeathmatchRules.reloadFor("odin"))
	check("the Odin takes 30 at the most", odin.ammo[1] == 40 and odin.reserve[1] == 170)
	odin.ammo[1] = 90
	WeaponSim.reloadNow(odin, 1, 30)
	check("and only what fits", odin.ammo[1] == 100 and odin.reserve[1] == 160)

	local knife = WeaponSim.newState({ "", "", "knife", "" })
	WeaponSim.reloadNow(knife, 3)
	WeaponSim.reloadNow(knife, 1)
	check("the knife and an empty slot take nothing", knife.ammo[3] == 0 and knife.ammo[1] == 0 and knife.loadout[1] == "")
end

do
	local h = Health.new(WeaponConfig.Health.maxHealth.value, DeathmatchConfig.SHIELD)
	Health.apply(h, 120, 0)
	Health.heal(h)
	check(
		"a pack heals in full, with a fresh shield of the kind worn",
		h.health == h.maxHealth and h.shield == h.maxShield and h.kind == "heavy"
	)
	Health.apply(h, 1e4, 1)
	Health.heal(h)
	check("but not the dead", not h.alive and h.health == 0)
end

-- No abilities ----------------------------------------------------------------------------

do
	local kit = AbilitySim.new()
	kit.agent = AbilityConfig.NO_AGENT
	AbilitySim.empty(kit)
	local none = true
	for slot = AbilityConfig.C, AbilityConfig.X do
		none = none and AbilitySim.def(kit, slot) == nil and AbilitySim.maxCharges(kit, slot) == 0
	end
	check("a kit of no agent's has no abilities to cast or buy", none and not AbilitySim.canBuy(kit, "updraft"))
	check("and no Drift", not AbilitySim.hasPassive(kit, "drift"))

	local B = PlayerSim.Buttons
	local DT = 1 / MovementConfig.TickRate.value
	local ledge = FakeWorld.new():addFloor():addBox(vector.create(-20, 0, 0), vector.create(20, 6, 40))
	local s = PlayerSim.new(vector.create(0, 6.02, 1), { "vandal", "classic", "knife", "" })
	s.abilities = kit
	local fastest, glided = 0, 0
	for _ = 1, 1000 do
		PlayerSim.step(s, { seq = 0, buttons = B.Jump + B.Forward, slot = 1, yaw = 0, pitch = 0, viewTime = 0 }, cfg, ledge, DT)
		fastest = math.min(fastest, s.movement.velocity.y)
		if s.movement.gliding then
			glided += 1
		end
		if s.movement.grounded and s.movement.position.y < 1 then
			break
		end
	end
	check("so a fall with jump held doesn't glide: Jett can't glide, as Riot says", glided == 0 and fastest < -4)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(2, s))
	check("and the ack says it's no agent's, not Jett's", decoded.abilities.agent == AbilityConfig.NO_AGENT)
	local jett = PlayerSim.new(vector.zero)
	local _, back = PlayerCodec.decodeAck(PlayerCodec.encodeAck(3, jett))
	check("as it still says Jett's for Jett's", back.abilities.agent == AbilityConfig.DEFAULT_AGENT)
end

-- Where a life starts ---------------------------------------------------------------------

local EYE = cfg.standEyeHeight

-- Whether the segment from a to b along the floor crosses a part's footprint.
local function crosses(part: MapPlan.Part, a: vector, b: vector): boolean
	local t0, t1 = 0, 1
	for _, axis in { { a.x, b.x, part.center.x, part.size.x / 2 }, { a.z, b.z, part.center.z, part.size.z / 2 } } do
		local p0, d, c, h = axis[1], axis[2] - axis[1], axis[3], axis[4]
		if math.abs(d) < 1e-12 then
			if math.abs(p0 - c) > h then
				return false
			end
		else
			local ta, tb = (c - h - p0) / d, (c + h - p0) / d
			if ta > tb then
				ta, tb = tb, ta
			end
			t0, t1 = math.max(t0, ta), math.min(t1, tb)
			if t0 > t1 then
				return false
			end
		end
	end
	return true
end

-- What sees what on a map, eye to eye: anything taller than an eye, walls
-- and tall cover, is in the way; low cover isn't.
local function seesOn(map: MapPlan.Map): DeathmatchSpawns.Sees
	local tall = {}
	for _, part in map.parts() do
		if (part.kind == "wall" or part.kind == "cover") and part.center.y + part.size.y / 2 > EYE then
			table.insert(tall, part)
		end
	end
	return function(a: vector, b: vector): boolean
		for _, part in tall do
			if crosses(part, a, b) then
				return false
			end
		end
		return true
	end
end

local function apart(a: vector, b: vector): number
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
end

for _, key in SpikeMaps.MAPS do
	local map = SpikeMaps.Maps[key]
	local spots = DeathmatchSpawns.spots(map)
	local clear, view = D.spotClearance.value, D.openView.value
	local onFloor, offCover, opens = true, true, true
	for _, spot in spots do
		local f = spot.feet
		for _, d in
			{
				vector.create(-clear, 0, -clear),
				vector.create(clear, 0, clear),
				vector.create(-clear, 0, clear),
				vector.create(clear, 0, -clear),
			}
		do
			onFloor = onFloor and map.onFloor(f.x + d.x, f.z + d.z)
		end
		for _, c in map.cover() do
			offCover = offCover and (math.abs(f.x - c.x) >= c.sx / 2 + clear or math.abs(f.z - c.z) >= c.sz / 2 + clear)
		end
		opens = opens and #spot.open == 8
		for _, open in spot.open do
			opens = opens and open >= 0 and open <= view
		end
	end
	print(string.format("  %s: %d places a life can start", map.NAME, #spots))
	check(map.NAME .. ": a place every 3 m or so across its floor", #spots >= 100)
	check(map.NAME .. ": each with floor all round it", onFloor)
	check(map.NAME .. ": and clear of cover", offCover)
	check(map.NAME .. ": with the open floor ahead each of eight ways, up to 6 m", opens)

	local sees = seesOn(map)
	-- Alone: anywhere, but away from where they fell.
	local died = spots[1].feet
	local away = true
	local roll = seeded(1)
	for _ = 1, 50 do
		local c = DeathmatchSpawns.choose(spots, {}, died, sees, roll)
		away = away and apart(c.feet, died) >= D.deathDistance.value
	end
	check(map.NAME .. ": alone, a life starts 20 m or more from where it fell", away)

	-- Trials with others alive at random places: whenever a place nobody
	-- sees and nobody's near exists, the life starts at one.
	local function trial(others: number, seed: number): (number, number, number, number)
		local roll = seeded(seed)
		local safeWhenCould, could, unseen, total = 0, 0, 0, 0
		for _ = 1, 40 do
			local enemies = {}
			for _ = 1, others do
				table.insert(enemies, spots[roll(#spots)].feet)
			end
			local fell = spots[roll(#spots)].feet
			local function isSeen(at: vector): boolean
				for _, e in enemies do
					if sees(e, at) then
						return true
					end
				end
				return false
			end
			local function nearest(at: vector): number
				local n = math.huge
				for _, e in enemies do
					n = math.min(n, apart(at, e))
				end
				return n
			end
			local exists = false
			for _, spot in spots do
				if nearest(spot.feet) >= D.safeDistance.value and not isSeen(spot.feet) then
					exists = true
					break
				end
			end
			local c = DeathmatchSpawns.choose(spots, enemies, fell, sees, roll)
			total += 1
			if not isSeen(c.feet) then
				unseen += 1
			end
			if exists then
				could += 1
				if not isSeen(c.feet) and nearest(c.feet) >= D.safeDistance.value then
					safeWhenCould += 1
				end
			end
		end
		return safeWhenCould, could, unseen, total
	end
	for _, others in { 5, 13 } do
		local ok, could, unseen, total = trial(others, others * 7 + #key)
		print(
			string.format(
				"  %s, %d others alive at random: a safe place nobody sees in %d of %d trials; the life started unseen in %d",
				map.NAME,
				others,
				could,
				total,
				unseen
			)
		)
		check(
			string.format("%s, %d others alive: the life starts safe and unseen whenever it can", map.NAME, others),
			ok == could and could > 0
		)
	end

	-- Facing: the open way nearest the nearest enemy.
	local spot: DeathmatchSpawns.Spot? = nil
	for _, s in spots do
		if s.open[1] >= view and s.open[3] >= view and s.open[5] >= view and s.open[7] >= view then
			spot = s
			break
		end
	end
	if spot then
		local here = spot.feet
		local east = here + vector.create(40, 0, 0)
		local c = DeathmatchSpawns.choose({ spot }, { east }, nil, function()
			return false
		end, seeded(2))
		check(map.NAME .. ": a life faces the open way toward the nearest enemy", math.abs(c.yaw - 3 * math.pi / 2) < 1e-9, tostring(c.yaw))
	end
end

do
	check("yaw 0 faces -z, and pi/2 faces -x", DeathmatchSpawns.yawToward(vector.zero, vector.create(0, 0, -5)) == 0)
	check("as a spawn spot's does", math.abs(DeathmatchSpawns.yawToward(vector.zero, vector.create(-5, 0, 0)) - math.pi / 2) < 1e-9)
	-- A wall in the way on one side: the open way nearest the enemy.
	local spot: DeathmatchSpawns.Spot = { feet = vector.zero, open = { 0, 0, 6, 6, 6, 6, 6, 0 } }
	local c = DeathmatchSpawns.choose({ spot }, { vector.create(0, 0, -40) }, nil, function()
		return false
	end, dice())
	check(
		"with the enemy behind a wall, the nearest way that's open",
		math.abs(c.yaw - math.pi / 2) < 1e-9 or math.abs(c.yaw - 3 * math.pi / 2) < 1e-9
	)
	local boxed: DeathmatchSpawns.Spot = { feet = vector.zero, open = { 1, 2, 3, 2, 1, 0.5, 0.5, 0.5 } }
	local d = DeathmatchSpawns.choose({ boxed }, { vector.create(0, 0, -40) }, nil, function()
		return false
	end, dice())
	check("and with no way open 6 m, the most open", math.abs(d.yaw - math.pi / 2) < 1e-9)

	-- Every place seen: the farthest from everyone that nobody sees, or the
	-- farthest.
	local spots = {
		{ feet = vector.create(0, 0, 0), open = { 6, 6, 6, 6, 6, 6, 6, 6 } },
		{ feet = vector.create(5, 0, 0), open = { 6, 6, 6, 6, 6, 6, 6, 6 } },
		{ feet = vector.create(8, 0, 0), open = { 6, 6, 6, 6, 6, 6, 6, 6 } },
	}
	local enemy = vector.create(-2, 0, 0)
	local hidden = DeathmatchSpawns.choose(spots, { enemy }, nil, function(_, b)
		return b.x ~= 5
	end, dice())
	check("too near everywhere: the farthest place nobody sees", hidden.feet == spots[2].feet)
	local open = DeathmatchSpawns.choose(spots, { enemy }, nil, function()
		return true
	end, dice())
	check("and seen everywhere, the farthest", open.feet == spots[3].feet)
	check("no places at all is the middle of the map", DeathmatchSpawns.choose({}, {}, nil, function()
		return false
	end, dice()).feet == vector.zero)
end

return nil
