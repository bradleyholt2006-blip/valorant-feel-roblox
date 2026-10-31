--!strict
-- Bots' agents' abilities (system 66): where a bot is in its side's plan
-- (BotTeam.placeOf), what it casts at each moment and when it doesn't
-- (BotUtility.choose), and each cast played through its own simulation
-- by its hands (BotUtility.hands, PlayerSim) on each map's own solids
-- (TileWorld), then flown as the server flies it: smokes, clouds, mollies,
-- slows, walls, flashes, bolts and blasts landing where they were meant to
-- (docs/research/66-bots-abilities.md).

local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local BoltSim = require("../src/shared/Abilities/BoltSim")
local CloudSim = require("../src/shared/Abilities/CloudSim")
local FireballSim = require("../src/shared/Abilities/FireballSim")
local FlareSim = require("../src/shared/Abilities/FlareSim")
local ParanoiaSim = require("../src/shared/Abilities/ParanoiaSim")
local SlowSim = require("../src/shared/Abilities/SlowSim")
local BotConfig = require("../src/shared/Bots/BotConfig")
local BotNav = require("../src/shared/Bots/BotNav")
local BotSpots = require("../src/shared/Bots/BotSpots")
local BotTeam = require("../src/shared/Bots/BotTeam")
local BotUtility = require("../src/shared/Bots/BotUtility")
local FakeWorld = require("./FakeWorld")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local H = require("./Harness")
local TileWorld = require("./TileWorld")

local check = H.check

local U = BotConfig.Utility
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local EYE = vector.create(0, 1.62, 0)
local LOW = vector.create(0, 0.3, 0)
local EXPERT = BotConfig.Skills.expert
local NEVER: BotConfig.Skill = table.clone(BotConfig.Skills.expert)
NEVER.utility = { value = 0, status = "estimate", source = "test" }
local Q, E = AbilityConfig.Q, AbilityConfig.E

-- Park-Miller dice, seeded: the same numbers each run (as tests/bots).
local function diceOf(seed: number): BotConfig.Dice
	local s = seed
	local function roll(): number
		s = s * 16807 % 2147483647
		return s / 2147483647
	end
	for _ = 1, 3 do
		roll()
	end
	return roll
end

-- A map, ready to throw on: its plan and its solids as a world, in its own
-- frame.
type Ground = { plan: BotSpots.Plan, nav: BotNav.Nav, world: any }

local grounds: { [string]: Ground } = {}

local function groundOf(key: string): Ground
	local known = grounds[key]
	if known then
		return known
	end
	local map = SpikeMaps.Maps[key]
	local plan = BotSpots.ofMap(map)
	local x0, z0, x1, z1 = map.bounds()
	local g: Ground = { plan = plan, nav = plan.nav, world = TileWorld.new(plan.nav.solids, x0, z0, x1, z1) }
	grounds[key] = g
	return g
end

-- A bot standing at `feet` on `agent`, every charge and its ultimate full,
-- settled on the floor.
local function botAt(world: any, feet: vector, agent: string, seed: number): PlayerSim.State
	local sim = PlayerSim.new(feet + vector.create(0, 0.05, 0), { "vandal", "classic", "knife", "" }, seed)
	sim.abilities = AbilitySim.new(agent)
	AbilitySim.fill(sim.abilities, true)
	for k = 1, 16 do
		PlayerSim.step(sim, { seq = k, buttons = 0, yaw = 0, pitch = 0, slot = 1, viewTime = 0 }, cfg, world, DT)
	end
	return sim
end

local function momentOf(sim: PlayerSim.State, place: BotTeam.Place?): BotUtility.Moment
	return {
		now = 50,
		clock = (sim.movement.tick + 1) * DT,
		place = place,
		live = 20,
		feet = sim.movement.position,
		eye = PlayerSim.eye(sim, cfg),
		health = 100,
		fighting = false,
		quiet = 10,
		sightings = {},
		defuse = nil,
		allies = {},
		mates = {},
	}
end

-- Plays cast `c` through the bot's simulation, as the server drives a bot,
-- until its hands say it's over: the casts its simulation made, and the
-- most it moved meanwhile. A heal on itself is taken as the server takes
-- one that heals (HealServer).
local function play(sim: PlayerSim.State, c: BotUtility.Cast, world: any): ({ AbilitySim.Cast }, number)
	local yaw, pitch = 0, 0
	local out: { AbilitySim.Cast } = {}
	local start = sim.movement.position
	local moved = 0
	for k = 1, math.ceil((c.longest + 1) / DT) do
		local t = (sim.movement.tick + 1) * DT
		local h = BotUtility.hands(c, sim.abilities, sim.weapons, t, PlayerSim.eye(sim, cfg), yaw, pitch, DT)
		yaw, pitch = h.yaw, h.pitch
		local input = { seq = k, buttons = h.buttons, yaw = yaw, pitch = pitch, slot = h.slot or 1, viewTime = t }
		local _, _, _, _, casts = PlayerSim.step(sim, input, cfg, world, DT)
		for _, cast in casts or {} do
			table.insert(out, cast)
			if cast.kind == "selfheal" then
				AbilitySim.used(sim.abilities, cast.slot)
				WeaponSim.putAway(sim.weapons, cast.time, AbilityConfig.unequip(cast.ability))
			end
		end
		moved = math.max(moved, vector.magnitude(sim.movement.position - start))
		if h.done then
			break
		end
	end
	return out, moved
end

local function find(casts: { AbilitySim.Cast }, kind: string): AbilitySim.Cast?
	for _, cast in casts do
		if cast.kind == kind then
			return cast
		end
	end
	return nil
end

local function flat(a: vector, b: vector): number
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
end

-- An attacker's place going in through entrance `k` of `site`, at the
-- spots that hold it.
local function entryOf(g: Ground, site: BotSpots.Site, k: number, phase: string): BotTeam.Place
	local threats = {}
	for _, h in site.holds do
		if h.entrance == k then
			table.insert(threats, BotNav.feet(g.nav, h.node) + EYE)
		end
	end
	local e = site.entrances[k]
	return { role = "entry", phase = phase, there = true, way = e.aim, door = BotNav.feet(g.nav, e.node), threats = threats }
end

-- A defender's place holding entrance `k` of `site`, from its first hold:
-- the place, and the hold's feet.
local function holdOf(g: Ground, site: BotSpots.Site, k: number): (BotTeam.Place?, vector)
	local e = site.entrances[k]
	for _, h in site.holds do
		if h.entrance == k then
			local d = BotNav.feet(g.nav, e.node) - BotNav.feet(g.nav, e.outside)
			local level = vector.create(d.x, 0, d.z)
			local place: BotTeam.Place = {
				role = "hold",
				phase = "hold",
				there = true,
				way = e.aim,
				heading = if vector.magnitude(level) > 1e-3 then vector.normalize(level) else nil,
				door = BotNav.feet(g.nav, e.node),
				from = BotNav.feet(g.nav, e.stage) + EYE,
				threats = {},
			}
			return place, BotNav.feet(g.nav, h.node)
		end
	end
	return nil, vector.zero
end

local function sees(world: any, a: vector, b: vector): boolean
	return world:sweep(a, vector.create(0.01, 0.01, 0.01), b - a) == nil
end

H.section("Bots' abilities: where each bot is in its side's plan (system 66)")

do
	local g = groundOf("outpost")
	local plan = g.plan
	local attack = BotTeam.new(g.nav, plan, "attack", diceOf(11), {})
	local defend = BotTeam.new(g.nav, plan, "defend", diceOf(12), {})
	BotTeam.round(attack, 0)
	BotTeam.round(defend, 0)
	local function members(spawn: { number }, base: number): { BotTeam.Member }
		local out = {}
		for k = 1, 5 do
			local n = spawn[(k - 1) % #spawn + 1]
			table.insert(out, { id = base + k, bot = true, alive = true, feet = BotNav.feet(g.nav, n) })
		end
		return out
	end
	local function zeros(field: { number }): { number }
		local out = {}
		for n, d in field do
			if d == 0 then
				table.insert(out, n)
			end
		end
		return out
	end
	local attackers = members(zeros(plan.attack), 100)
	local defenders = members(zeros(plan.defend), 200)
	BotTeam.think(attack, 1, true, attackers, {}, nil)
	BotTeam.think(defend, 1, true, defenders, {}, nil)
	local entries, matched, holds, heldWays = 0, 0, 0, 0
	for _, m in attackers do
		local p = BotTeam.placeOf(attack, m.id, m.feet)
		local site = BotSpots.site(plan, attack.site :: string) :: BotSpots.Site
		if p and p.role == "entry" and p.phase == "gather" then
			entries += 1
			for k, e in site.entrances do
				local count = 0
				for _, h in site.holds do
					if h.entrance == k then
						count += 1
					end
				end
				if p.way and vector.magnitude(e.aim - p.way) < 1e-3 and #p.threats == count and count > 0 then
					matched += 1
				end
			end
		end
	end
	for _, m in defenders do
		local p = BotTeam.placeOf(defend, m.id, m.feet)
		if p and p.role == "hold" then
			holds += 1
			if p.way and p.from and p.heading and math.abs(vector.magnitude(p.heading) - 1) < 1e-3 then
				heldWays += 1
			end
		end
	end
	check(
		"attackers gathering go in through their way, at the spots that hold it",
		entries == 5 and matched == 5,
		string.format("%d of 5 entering, %d at their way's holds", entries, matched)
	)
	check(
		"defenders hold a way in, knowing where its attackers gather and the way it's crossed",
		holds == 5 and heldWays == 5,
		string.format("%d of 5 holding, %d knowing their way", holds, heldWays)
	)
	-- Once it's planted: the attackers guard it, the defenders retake.
	local site = plan.sites[1]
	local at = BotNav.feet(g.nav, site.plants[1])
	local spike: BotTeam.Spike = { state = "planted", at = at, site = site.name, detonateAt = 60, halfSaved = false }
	BotTeam.think(attack, 2, true, attackers, {}, spike)
	BotTeam.think(defend, 2, true, defenders, {}, spike)
	local guards, retakes = 0, 0
	for _, m in attackers do
		local p = BotTeam.placeOf(attack, m.id, m.feet)
		if p and p.role == "guard" and p.spike and vector.magnitude(p.spike - at) < 1e-3 then
			guards += 1
		end
	end
	for _, m in defenders do
		local p = BotTeam.placeOf(defend, m.id, m.feet)
		if p and p.role == "entry" and p.phase == "gather" and #p.threats > 0 and p.spike then
			retakes += 1
		end
	end
	check("attackers guard the planted spike", guards == 5, string.format("%d of 5", guards))
	check("defenders retake it, at the spots that watch it", retakes == 5, string.format("%d of 5", retakes))
	-- Then not planted, as on a round's first frames before the last round's
	-- spike has caught up: a holder in the retake's push would smoke its way
	-- forward from spawn.
	local carried: BotTeam.Spike = { state = "carried", at = nil, carrier = attackers[1].id, site = nil, detonateAt = 0, halfSaved = false }
	BotTeam.think(attack, 3, true, attackers, {}, carried)
	BotTeam.think(defend, 3, true, defenders, {}, carried)
	local stale = 0
	for _, m in attackers do
		local p = BotTeam.placeOf(attack, m.id, m.feet)
		if p and (p.role == "guard" or p.spike) then
			stale += 1
		end
	end
	for _, m in defenders do
		local p = BotTeam.placeOf(defend, m.id, m.feet)
		if not p or p.role ~= "hold" or p.spike then
			stale += 1
		end
	end
	check("with the spike not planted, nobody guards it or retakes it", stale == 0, string.format("%d still at it", stale))
	-- From the Studio checks: the carrier, come from the spawn with the
	-- spike after its side's taken the site, had no place on its way to
	-- plant, so a Sova carrying it never cast its Recon Bolt. Short of the
	-- site it goes in through its way as the push did; on it, it plants.
	attack.phase = "take"
	attack.tookAt = 3
	BotTeam.think(attack, 3.5, true, attackers, {}, carried)
	local carrier = attackers[1]
	local taken = BotSpots.site(plan, attack.site :: string) :: BotSpots.Site
	local onWay = BotTeam.placeOf(attack, carrier.id, carrier.feet)
	local onSite = BotTeam.placeOf(attack, carrier.id, BotNav.feet(g.nav, taken.plants[1]))
	check(
		"the spike's carrier on its way to plant, short of the site, goes in through its way as the push did",
		attack.jobs[carrier.id].task == "plant"
			and onWay ~= nil
			and onWay.role == "entry"
			and onWay.phase == "push"
			and onWay.way ~= nil
			and #onWay.threats > 0,
		if onWay then onWay.role .. " " .. onWay.phase else attack.jobs[carrier.id].task
	)
	check("...and on the site, it plants, with no place to cast from", onSite == nil)
	local moved = BotUtility.moved(
		{ role = "hold", phase = "hold", there = true, way = vector.one, from = vector.zero, threats = { vector.one } },
		vector.create(10, 0, 0)
	)
	check(
		"a place moves into the place's frame",
		moved.way == vector.create(11, 1, 1) and moved.from == vector.create(10, 0, 0) and moved.threats[1] == vector.create(11, 1, 1)
	)
	-- The modes that respawn have no plan to be in.
	local team = BotTeam.new(g.nav, nil, "team", diceOf(13), {})
	BotTeam.think(team, 1, true, { attackers[1] }, {}, nil)
	check("a side of the modes that respawn has no place in a plan", BotTeam.placeOf(team, attackers[1].id, attackers[1].feet) == nil)
end

H.section("Bots' abilities: what a bot casts, and when it doesn't (system 66)")

do
	check(
		"bots cast the abilities written for them, and buy those",
		BotUtility.uses("darkcover")
			and BotUtility.uses("curveball")
			and BotUtility.uses("huntersfury")
			and not BotUtility.uses("owldrone")
			and not BotUtility.uses("runitback")
			and not BotUtility.uses("tailwind")
	)
	local g = groundOf("outpost")
	local site = g.plan.sites[1]
	local feet = BotNav.feet(g.nav, site.entrances[1].stage)
	local place = entryOf(g, site, 1, "push")
	local sim = botAt(g.world, feet, "omen", 5)
	local kit = sim.abilities
	local m = momentOf(sim, place)
	local memo = BotUtility.memo()
	local first = BotUtility.choose(m, kit, memo, EXPERT, diceOf(1), g.world)
	check(
		"Omen going in smokes the spot most likely to hold his way in first",
		first ~= nil and first.ability == "darkcover" and first.key == "push:darkcover:1",
		if first then first.key else "nothing"
	)
	local second = BotUtility.choose(m, kit, memo, EXPERT, diceOf(1), g.world)
	check(
		"each moment's cast goes once a life: the next is the second spot's",
		second ~= nil and second.key == "push:darkcover:2",
		if second then second.key else "nothing"
	)
	local fighting = momentOf(sim, place)
	fighting.fighting = true
	local waiting = momentOf(sim, place)
	waiting.now = 10
	local early = BotUtility.memo()
	early.nextAt = 20
	check(
		"nothing's cast while it fights, or before its hands are free again",
		BotUtility.choose(fighting, kit, BotUtility.memo(), EXPERT, diceOf(1), g.world) == nil
			and BotUtility.choose(waiting, kit, early, EXPERT, diceOf(1), g.world) == nil
	)
	kit.holding = E
	check("nor with an ability in hand already", BotUtility.choose(m, kit, BotUtility.memo(), EXPERT, diceOf(1), g.world) == nil)
	kit.holding = 0
	local unlucky = BotUtility.memo()
	local none = BotUtility.choose(m, kit, unlucky, NEVER, diceOf(1), g.world)
	local after = BotUtility.choose(m, kit, unlucky, EXPERT, diceOf(1), g.world)
	check(
		"a moment its skill's roll misses is gone for the life, whatever it rolls after",
		none == nil and unlucky.rolled["push:darkcover:1"] == false and (after == nil or after.key ~= "push:darkcover:1"),
		if after then after.key else "nothing"
	)
	-- Past the think's deadline it tries no more throws: with the first
	-- spot out of reach, the second's is tried only by the next think.
	local farPlace = table.clone(place)
	farPlace.threats = { place.threats[1] + vector.create(200, 0, 0), place.threats[2] }
	local far = momentOf(sim, farPlace)
	local late = BotUtility.memo()
	local stopped = BotUtility.choose(far, kit, late, EXPERT, diceOf(1), g.world, os.clock() - 1)
	local resumed = BotUtility.choose(far, kit, late, EXPERT, diceOf(1), g.world)
	check(
		"past the think's deadline no more throws are tried, and the next think tries the rest",
		stopped == nil
			and late.retry["push:darkcover:1"] ~= nil
			and late.retry["push:darkcover:2"] == nil
			and resumed ~= nil
			and resumed.key == "push:darkcover:2",
		if resumed then resumed.key else "nothing"
	)
	-- Hurt and out of a fight, a bot on Sage heals itself, or the ally most hurt.
	local sage = botAt(g.world, feet, "sage", 6)
	local hurt = momentOf(sage, nil)
	hurt.health = 50
	local self = BotUtility.choose(hurt, sage.abilities, BotUtility.memo(), EXPERT, diceOf(2), g.world)
	local fresh = momentOf(sage, nil)
	fresh.health = 50
	fresh.quiet = 1
	local whole = momentOf(sage, nil)
	check(
		"a bot on Sage hurt with nobody about for a while heals itself",
		self ~= nil and self.ability == "healingorb" and self.alt,
		if self then self.key else "nothing"
	)
	check(
		"but not in a fight's lull, nor unhurt",
		BotUtility.choose(fresh, sage.abilities, BotUtility.memo(), EXPERT, diceOf(2), g.world) == nil
			and BotUtility.choose(whole, sage.abilities, BotUtility.memo(), EXPERT, diceOf(2), g.world) == nil
	)
	local open = FakeWorld.new():addFloor()
	local friend = momentOf(sage, nil)
	local chest = PlayerSim.eye(sage, cfg) + vector.create(3, -0.4, 0)
	friend.allies = { { id = 7, chest = chest + vector.create(0, 0, 40), health = 20 }, { id = 8, chest = chest, health = 40 } }
	local onAlly = BotUtility.choose(friend, sage.abilities, BotUtility.memo(), EXPERT, diceOf(2), open)
	check(
		"and heals a hurt ally in reach, not one out of it",
		onAlly ~= nil and not onAlly.alt and onAlly.target == chest,
		if onAlly and onAlly.target then tostring(onAlly.target) else "nothing"
	)
	-- Mollies and Shock Bolts keep off teammates.
	local phoenix = botAt(g.world, feet, "phoenix", 7)
	AbilitySim.used(phoenix.abilities, AbilitySim.slotOf(phoenix.abilities, "curveball") :: number)
	phoenix.abilities.charges[AbilitySim.slotOf(phoenix.abilities, "curveball") :: number] = 0
	local crowded = momentOf(phoenix, place)
	crowded.mates = { place.threats[1] }
	local molly = BotUtility.choose(crowded, phoenix.abilities, BotUtility.memo(), EXPERT, diceOf(3), g.world)
	check("a molly isn't thrown where a teammate stands", molly == nil or molly.ability ~= "hothands")
	-- Hunter's Fury: at enemies seen a moment ago, three at most, apart.
	local sova = botAt(g.world, feet, "sova", 8)
	local seen = momentOf(sova, nil)
	local eye = PlayerSim.eye(sova, cfg)
	seen.sightings = {
		{ at = eye + vector.create(20, 0, 0), time = 49.5 },
		{ at = eye + vector.create(21, 0, 0), time = 49.5 },
		{ at = eye + vector.create(0, 0, 30), time = 49 },
		{ at = eye + vector.create(-30, 0, 0), time = 49.2 },
		{ at = eye + vector.create(0, 0, -25), time = 49.9 },
		{ at = eye + vector.create(0, 0, -20), time = 40 },
	}
	local fury = BotUtility.choose(seen, sova.abilities, BotUtility.memo(), EXPERT, diceOf(4), g.world)
	check(
		"Hunter's Fury goes at enemies seen a moment ago: three at most, apart",
		fury ~= nil and fury.ability == "huntersfury" and #fury.targets == 3,
		if fury then string.format("%d targets", #fury.targets) else "nothing"
	)
end

H.section("Bots' abilities: each throw, tried and played, landing where it was meant to (system 66)")

do
	-- Over every map's sites and ways in: each agent's casts from where it
	-- would cast them, played through its simulation and flown as the
	-- server flies them.
	type Tally = { tried: number, found: number, landed: number, worst: number }
	local tallies: { [string]: Tally } = {}
	local order: { string } = {}
	local function tally(name: string, found: boolean, landed: boolean, miss: number?)
		local t = tallies[name]
		if not t then
			t = { tried = 0, found = 0, landed = 0, worst = 0 }
			tallies[name] = t
			table.insert(order, name)
		end
		t.tried += 1
		if found then
			t.found += 1
		end
		if landed then
			t.landed += 1
		end
		if miss then
			t.worst = math.max(t.worst, miss)
		end
	end
	local stoodStill = true
	local seed = 100
	for _, key in SpikeMaps.MAPS do
		local g = groundOf(key)
		local world = g.world
		for _, site in g.plan.sites do
			for k, e in site.entrances do
				seed += 1
				local stage = BotNav.feet(g.nav, e.stage)
				local push = entryOf(g, site, k, "push")
				local gather = entryOf(g, site, k, "gather")
				if #push.threats == 0 then
					continue
				end
				local spot = push.threats[1] - EYE
				-- Dark Cover on the first spot: its smoke on its floor.
				do
					local sim = botAt(world, stage, "omen", seed)
					local c = BotUtility.choose(momentOf(sim, push), sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
					local found = c ~= nil and c.ability == "darkcover"
					local smoke = if c and found then find(play(sim, c, world), "smoke") else nil
					local miss = if smoke and smoke.smoke and c and c.point then flat(smoke.smoke, c.point) else nil
					tally("Dark Cover on a spot holding the way in", found, miss ~= nil and miss <= U.smokeMiss.value, miss)
				end
				-- Paranoia through it.
				do
					local sim = botAt(world, stage, "omen", seed)
					sim.abilities.charges[E] = 0
					local c = BotUtility.choose(momentOf(sim, push), sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
					local found = c ~= nil and c.ability == "paranoia"
					local sent = if c and found then find(play(sim, c, world), "paranoia") else nil
					local orb = if sent then ParanoiaSim.send(0, 0, sent.origin, sent.direction) else nil
					tally("Paranoia through it", found, orb ~= nil and ParanoiaSim.inPath(orb, { push.threats[1] }))
				end
				-- Jett's cloud on it, or on the way in.
				do
					local sim = botAt(world, stage, "jett", seed)
					-- Its points spent, as Blade Storm comes first at the way in.
					sim.abilities.points = 0
					local c = BotUtility.choose(momentOf(sim, push), sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
					local found = c ~= nil and c.ability == "cloudburst"
					local throw = if c and found then find(play(sim, c, world), "throw") else nil
					local miss: number? = nil
					if throw and c and c.target then
						local p = CloudSim.throw(0, 0, throw.origin, throw.direction)
						local at: vector? = nil
						while not at do
							at = CloudSim.drift(p, DT, world)
						end
						miss = vector.magnitude((at :: vector) - c.target)
					end
					tally("Cloudburst on it or the way in", found, miss ~= nil and miss <= U.cloudMiss.value, miss)
				end
				-- Phoenix's Curveball round the corner: blinding those holding,
				-- seen by neither him nor anyone with him.
				do
					local sim = botAt(world, stage, "phoenix", seed)
					local c = BotUtility.choose(momentOf(sim, push), sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
					local found = c ~= nil and c.ability == "curveball"
					local flare = if c and found then find(play(sim, c, world), "flare") else nil
					local blinds = false
					if flare and flare.curve then
						local f = FlareSim.throw(0, 0, flare.origin, flare.direction, flare.curve)
						local path = FlareSim.fly(f, DT, world)
						local pop = path[#path]
						local score = 0
						for _, h in push.threats do
							if FlareSim.seen(pop, h, world) then
								score += FlareSim.strength(pop, h, vector.normalize((push.way :: vector) - h))
							end
						end
						blinds = not FlareSim.seen(pop, flare.origin, world) and score >= U.flashWorth.value * 0.8
					end
					tally("Curveball round the corner at those holding", found, blinds)
				end
				-- Hot Hands on the spot.
				do
					local sim = botAt(world, stage, "phoenix", seed)
					sim.abilities.charges[AbilitySim.slotOf(sim.abilities, "curveball") :: number] = 0
					local c = BotUtility.choose(momentOf(sim, push), sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
					local found = c ~= nil and c.ability == "hothands"
					local casts: { AbilitySim.Cast }, moved = {}, 0
					if c and found then
						casts, moved = play(sim, c, world)
					end
					stoodStill = stoodStill and moved < 0.6
					local ball = find(casts, "fireball")
					local miss: number? = nil
					if ball and c and c.point then
						local f = FireballSim.throw(0, 0, ball.origin, ball.direction, ball.lob == true)
						if FireballSim.fly(f, DT, world) then
							miss = vector.magnitude(f.position - c.point)
						end
					end
					tally("Hot Hands on it", found, miss ~= nil and miss <= U.throwMiss.value + 0.5, miss)
				end
				-- Sova gathered: the Recon Bolt where it reveals them; going in,
				-- a Shock Bolt on the spot.
				do
					local sim = botAt(world, stage, "sova", seed)
					local c = BotUtility.choose(momentOf(sim, gather), sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
					local found = c ~= nil and c.ability == "reconbolt"
					local bolt = if c and found then find(play(sim, c, world), "bolt") else nil
					local reveals = false
					if bolt then
						local b = BoltSim.shoot(0, 0, bolt.origin, bolt.direction, bolt.bars or 0, bolt.bounces or 0)
						if BoltSim.fly(b, DT, world) and b.normal then
							local from = b.position + b.normal * AbilityConfig.ReconBolt.lift.value
							for _, h in gather.threats do
								reveals = reveals
									or vector.magnitude(h - from) <= AbilityConfig.ReconBolt.radius.value and sees(world, from, h)
							end
						end
					end
					tally("Recon Bolt revealing those holding", found, reveals)
				end
				do
					local sim = botAt(world, stage, "sova", seed)
					-- Its Recon Bolt cast as its side gathered.
					local memo = BotUtility.memo()
					memo.done["gather:reconbolt"] = true
					local c = BotUtility.choose(momentOf(sim, push), sim.abilities, memo, EXPERT, diceOf(seed), world)
					local found = c ~= nil and c.ability == "shockbolt"
					local bolt = if c and found then find(play(sim, c, world), "bolt") else nil
					local miss: number? = nil
					if bolt and c and c.point then
						local b = BoltSim.shoot(0, 0, bolt.origin, bolt.direction, bolt.bars or 0, 0)
						if BoltSim.fly(b, DT, world) then
							miss = vector.magnitude(b.position - c.point)
						end
					end
					tally("Shock Bolt on it", found, miss ~= nil and miss <= U.throwMiss.value + 0.5, miss)
				end
				-- Holding it, with attackers seen there: Sage's slow, then her
				-- wall, on the way in.
				local hold, holdFeet = holdOf(g, site, k)
				if hold and hold.way then
					local way = hold.way :: vector
					local floor = way - EYE
					do
						local sim = botAt(world, holdFeet, "sage", seed)
						local m = momentOf(sim, hold)
						m.sightings = { { at = way, time = 49.5 } }
						local c = BotUtility.choose(m, sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
						local found = c ~= nil and c.ability == "sloworb"
						local slow = if c and found then find(play(sim, c, world), "slow") else nil
						local miss: number? = nil
						if slow and c and c.point then
							local f = SlowSim.throw(0, 0, slow.origin, slow.direction)
							if FireballSim.fly(f, DT, world) then
								miss = vector.magnitude(f.position - c.point)
							end
						end
						tally("Slow Orb on the way in, stalling", found, miss ~= nil and miss <= U.throwMiss.value + 0.5, miss)
					end
					do
						local sim = botAt(world, holdFeet, "sage", seed)
						sim.abilities.charges[Q] = 0
						local m = momentOf(sim, hold)
						m.sightings = { { at = way, time = 49.5 } }
						local c = BotUtility.choose(m, sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
						local found = c ~= nil and c.ability == "barrierorb"
						local raised = if c and found then find(play(sim, c, world), "barrier") else nil
						local miss = if raised and raised.wall and c and c.point then flat(raised.wall.centre, c.point) else nil
						tally("Barrier Orb across it, in range", found, miss ~= nil and miss <= U.wallMiss.value + 0.5, miss)
					end
				end
			end
		end
	end
	for _, name in order do
		local t = tallies[name]
		print(
			string.format(
				"  %s: found from %d of %d places, %d played and landing as tried (worst %.1f m off)",
				name,
				t.found,
				t.tried,
				t.landed,
				t.worst
			)
		)
	end
	local function landedAll(name: string, least: number): boolean
		local t = tallies[name]
		return t ~= nil and t.found >= least and t.landed == t.found
	end
	local function show(name: string): string
		local t = tallies[name]
		return if t then string.format("%d found of %d, %d landed", t.found, t.tried, t.landed) else "none"
	end
	local sixteen = tallies["Dark Cover on a spot holding the way in"].tried
	check(
		"Dark Cover goes through walls: a smoke for nearly every spot, each on its floor",
		landedAll("Dark Cover on a spot holding the way in", math.ceil(sixteen * 0.75)),
		show("Dark Cover on a spot holding the way in")
	)
	check(
		"Paranoia's orb goes through the spot it's sent at",
		landedAll("Paranoia through it", math.ceil(sixteen * 0.75)),
		show("Paranoia through it")
	)
	check(
		"Jett's clouds burst where they were tried to, from where there's a line",
		landedAll("Cloudburst on it or the way in", 1),
		show("Cloudburst on it or the way in")
	)
	check(
		"Phoenix's flashes, where one's found, blind those holding and neither him nor his side",
		landedAll("Curveball round the corner at those holding", 1),
		show("Curveball round the corner at those holding")
	)
	check("Hot Hands lands on the spot it's thrown at", landedAll("Hot Hands on it", 1), show("Hot Hands on it"))
	check("and a throw found from where it stands is thrown from there, standing still", stoodStill)
	check(
		"Recon Bolts stick where they reveal those they're for",
		landedAll("Recon Bolt revealing those holding", math.ceil(sixteen * 0.5)),
		show("Recon Bolt revealing those holding")
	)
	check("Shock Bolts stick by the spot they're shot at", landedAll("Shock Bolt on it", 1), show("Shock Bolt on it"))
	check("Sage's slows land on the way in", landedAll("Slow Orb on the way in, stalling", 1), show("Slow Orb on the way in, stalling"))
	check(
		"and a bot on Sage raises its walls across it, in range",
		landedAll("Barrier Orb across it, in range", 1),
		show("Barrier Orb across it, in range")
	)
end

H.section("Bots' abilities: hands for the casts that need no throw found (system 66)")

do
	-- In the open (a floor and nothing else).
	local world = FakeWorld.new():addFloor()
	local feet = vector.zero
	-- Hunter's Fury: each blast along the view at its target, in turn.
	local sova = botAt(world, feet, "sova", 21)
	local eye = PlayerSim.eye(sova, cfg)
	local m = momentOf(sova, nil)
	local a, b = eye + vector.create(25, 0, -10), eye + vector.create(-20, 1, -30)
	m.sightings = { { at = a, time = 49.5 }, { at = b, time = 49.5 } }
	local fury = BotUtility.choose(m, sova.abilities, BotUtility.memo(), EXPERT, diceOf(5), world)
	local blasts = {}
	if fury then
		for _, cast in play(sova, fury, world) do
			if cast.kind == "blast" then
				table.insert(blasts, cast)
			end
		end
	end
	local function off(cast: AbilitySim.Cast, target: vector): number
		return math.deg(math.acos(math.clamp(vector.dot(cast.direction, vector.normalize(target - cast.origin)), -1, 1)))
	end
	check(
		"Hunter's Fury: a blast at each enemy seen, each along the view at it",
		#blasts == 2 and off(blasts[1], a) < 1 and off(blasts[2], b) < 1,
		if #blasts == 2 then string.format("%.2f and %.2f degrees off", off(blasts[1], a), off(blasts[2], b)) else #blasts .. " blasts"
	)
	-- Blade Storm with an enemy near, in the modes that respawn.
	local jett = botAt(world, feet, "jett", 22)
	local near = momentOf(jett, nil)
	near.sightings = { { at = PlayerSim.eye(jett, cfg) + vector.create(6, 0, 0), time = 49.5 } }
	local storm = BotUtility.choose(near, jett.abilities, BotUtility.memo(), EXPERT, diceOf(6), world)
	local stormed = if storm then find(play(jett, storm, world), "storm") else nil
	check(
		"Blade Storm with an enemy near: its knives in hand",
		stormed ~= nil and jett.abilities.storm and jett.weapons.equipped == WeaponSim.ULT,
		if storm then storm.key else "nothing"
	)
	-- A bot on Sage heals itself, and its charge goes with it.
	local sage = botAt(world, feet, "sage", 23)
	local hurt = momentOf(sage, nil)
	hurt.health = 40
	local heal = BotUtility.choose(hurt, sage.abilities, BotUtility.memo(), EXPERT, diceOf(7), world)
	local healed = if heal then find(play(sage, heal, world), "selfheal") else nil
	check(
		"the Healing Orb on itself: tried, and out of hand once it heals",
		healed ~= nil and sage.abilities.holding == 0 and sage.abilities.charges[E] == 0
	)
	-- Guarding the spike with an enemy on it: a molly on the spike, kept off
	-- a teammate's side of it.
	local phoenix = botAt(world, feet, "phoenix", 24)
	phoenix.abilities.charges[AbilitySim.slotOf(phoenix.abilities, "curveball") :: number] = 0
	local spike = vector.create(10, 0, -6)
	local guard: BotTeam.Place = { role = "guard", phase = "guard", there = true, threats = {}, spike = spike }
	local g = momentOf(phoenix, guard)
	g.defuse = spike
	local molly = BotUtility.choose(g, phoenix.abilities, BotUtility.memo(), EXPERT, diceOf(8), world)
	local ball = if molly then find(play(phoenix, molly, world), "fireball") else nil
	local miss: number? = nil
	if ball then
		local f = FireballSim.throw(0, 0, ball.origin, ball.direction, ball.lob == true)
		if FireballSim.fly(f, DT, world) then
			miss = vector.magnitude(f.position - spike)
		end
	end
	check(
		"guarding the spike, an enemy heard defusing it gets a molly on it",
		miss ~= nil and miss <= U.throwMiss.value + 0.5,
		if miss then string.format("%.1f m off", miss) else "none"
	)
	-- The skill: out of many lives, an Easy bot casts at about its share of
	-- a moment's.
	local rolls, cast = 400, 0
	local dice = diceOf(9)
	local kit = AbilitySim.new("sage")
	AbilitySim.fill(kit, false)
	for _ = 1, rolls do
		if BotUtility.choose(hurt, kit, BotUtility.memo(), BotConfig.Skills.easy, dice, world) then
			cast += 1
		end
	end
	local share = cast / rolls
	check(
		"an Easy bot casts at about its share of the moments",
		math.abs(share - BotConfig.Skills.easy.utility.value) < 0.1,
		string.format("%.2f of moments, its share %.2f", share, BotConfig.Skills.easy.utility.value)
	)
end

H.section("Bots' abilities: a flash's thrower waits for its pop, and a late Recon Bolt (system 66)")

do
	-- From the Studio checks: a bot's own flash blinded it as it walked on
	-- before the pop, and an attacking Sova that hadn't got to where its
	-- side gathers as the push went never cast its Recon Bolt.
	local g = groundOf("outpost")
	local world = g.world
	local popTime = FlareSim.popTime(DT)
	local waited, still, quiet, own = nil :: number?, true, true, true
	local found = false
	local seed = 300
	for _, site in g.plan.sites do
		for k, e in site.entrances do
			seed += 1
			local push = entryOf(g, site, k, "push")
			if found or #push.threats == 0 then
				continue
			end
			local sim = botAt(world, BotNav.feet(g.nav, e.stage), "phoenix", seed)
			local c = BotUtility.choose(momentOf(sim, push), sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
			if not c or c.ability ~= "curveball" then
				continue
			end
			found = true
			local yaw, pitch = 0, 0
			local thrownAt: number? = nil
			local from = sim.movement.position
			for n = 1, math.ceil((c.longest + 1) / DT) do
				local t = (sim.movement.tick + 1) * DT
				local h = BotUtility.hands(c, sim.abilities, sim.weapons, t, PlayerSim.eye(sim, cfg), yaw, pitch, DT)
				yaw, pitch = h.yaw, h.pitch
				if thrownAt then
					still = still and h.still and vector.magnitude(sim.movement.position - from) < 0.6
					quiet = quiet and h.buttons == 0
					own = own and h.slot == nil
				end
				if h.done then
					waited = if thrownAt then t - thrownAt else nil
					break
				end
				local input = { seq = n, buttons = h.buttons, yaw = yaw, pitch = pitch, slot = h.slot or 1, viewTime = t }
				local _, _, _, _, casts = PlayerSim.step(sim, input, cfg, world, DT)
				if find(casts or {}, "flare") then
					thrownAt = t
				end
			end
		end
	end
	check(
		"a flash's thrower stands where it threw it until it's popped, pressing nothing, its gun coming back",
		found and waited ~= nil and waited >= popTime - 1e-6 and still and quiet and own,
		if waited then string.format("%.3f s after the throw, the pop at %.3f s", waited, popTime) else "no throw"
	)

	-- Sova, the push gone before it got to where its side gathers: the
	-- Recon Bolt on the way while the way in's still a way off, and not
	-- once it's near; nor while its side gathers and it isn't there yet.
	local late, near, early = false, true, true
	local tried = 0
	for _, site in g.plan.sites do
		for k, e in site.entrances do
			seed += 1
			local push = entryOf(g, site, k, "push")
			push.there = false
			local stage = BotNav.feet(g.nav, e.stage)
			local way = push.way :: vector
			if #push.threats == 0 or vector.magnitude(stage + EYE - way) < U.reconFar.value then
				continue
			end
			tried += 1
			local sim = botAt(world, stage, "sova", seed)
			local c = BotUtility.choose(momentOf(sim, push), sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
			late = late or (c ~= nil and c.key == "gather:reconbolt")
			local gather = entryOf(g, site, k, "gather")
			gather.there = false
			local before = BotUtility.choose(momentOf(sim, gather), sim.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
			early = early and (before == nil or before.key ~= "gather:reconbolt")
			local close = botAt(world, way - EYE, "sova", seed)
			local there = BotUtility.choose(momentOf(close, push), close.abilities, BotUtility.memo(), EXPERT, diceOf(seed), world)
			near = near and (there == nil or there.key ~= "gather:reconbolt")
		end
	end
	check(
		"the push gone before Sova got there, its Recon Bolt goes on the way, a way off the way in",
		late,
		string.format("%d ways in at least %.1f m off", tried, U.reconFar.value)
	)
	check("...not once it's at the way in", near)
	check("...nor while its side gathers and it isn't there yet", early)

	-- From the Studio checks: a Sova that fetched the spike, and so came
	-- from the spawn after the push went, never cast it: on its way in, the
	-- stretch with a throw can be a couple of metres. Walked in at a run
	-- from the spawn on every map, thinking as the server has bots think,
	-- it casts before it's at its way in wherever a think on the walk finds
	-- a throw: on every way in it'd cast on from where its side gathers but
	-- one, whose walk in never sees a spot for it.
	local think = BotConfig.Params.think.value
	local run = 5.4 -- m/s, with a rifle
	local walks, found, cast, missed = 0, 0, 0, {}
	for _, key in SpikeMaps.MAPS do
		local ground = groundOf(key)
		for _, site in ground.plan.sites do
			for k, e in site.entrances do
				local push = entryOf(ground, site, k, "push")
				push.there = false
				local way = push.way :: vector
				if #push.threats == 0 then
					continue
				end
				local gathered = botAt(ground.world, BotNav.feet(ground.nav, e.stage), "sova", seed)
				local there = BotUtility.choose(
					momentOf(gathered, entryOf(ground, site, k, "gather")),
					gathered.abilities,
					BotUtility.memo(),
					EXPERT,
					diceOf(seed),
					ground.world
				)
				if there == nil or there.key ~= "gather:reconbolt" then
					continue
				end
				-- Its way: down the attackers' field from the way in to the spawn,
				-- walked the other way.
				local path = { BotNav.feet(ground.nav, e.node) }
				local at = e.node
				for _ = 1, 400 do
					local nextNode = BotSpots.down(ground.nav, ground.plan.attack, at, 0.5)
					if nextNode == at or ground.plan.attack[nextNode] <= 0 then
						break
					end
					at = nextNode
					table.insert(path, 1, BotNav.feet(ground.nav, at))
				end
				local kit = AbilitySim.new("sova")
				AbilitySim.fill(kit, true)
				local memo = BotUtility.memo()
				local i, feet, now = 1, path[1], 50
				local done, any = false, false
				while i < #path and not done do
					local m = momentOf(botAt(ground.world, feet, "sova", seed), push)
					m.now = now
					if vector.magnitude(m.eye - way) < U.reconFar.value then
						break
					end
					local c = BotUtility.choose(m, kit, memo, EXPERT, diceOf(seed), ground.world)
					done = c ~= nil and c.key == "gather:reconbolt"
					-- Whether a throw's found here, as a fresh choice.
					local fresh = BotUtility.choose(m, kit, BotUtility.memo(), EXPERT, diceOf(seed), ground.world)
					any = any or done or (fresh ~= nil and fresh.key == "gather:reconbolt")
					-- On along its way, a think's walk.
					local left = run * think
					while left > 0 and i < #path do
						local to = path[i + 1] - feet
						local d = vector.magnitude(to)
						if d <= left then
							feet, i, left = path[i + 1], i + 1, left - d
						else
							feet, left = feet + to * (left / d), 0
						end
					end
					now += think
				end
				walks += 1
				found += if any then 1 else 0
				cast += if done then 1 else 0
				if not done then
					table.insert(missed, string.format("%s %s %d", key, site.name, k))
				end
			end
		end
	end
	check(
		"...and walked in from the spawn after the push went, it casts on the way in before it's there",
		walks > 0 and cast == found and found >= walks - 1,
		string.format(
			"%d of the %d ways in with a throw on the walk, of %d%s",
			cast,
			found,
			walks,
			if #missed > 0 then "; none on " .. table.concat(missed, ", ") else ""
		)
	)
end

return nil
