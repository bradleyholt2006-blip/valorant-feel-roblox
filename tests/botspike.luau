--!strict
-- Bots and the spike (system 61): who goes for it and when, how a bot's
-- hands plant it and defuse it, and whole rounds of it on each map's own
-- solids (TileWorld) with the movement a player has, the plant and the
-- defuse stepped in each bot's simulation (SpikeSim) and the spike kept
-- as the server keeps it (SpikeServer): fetched, carried, planted,
-- watched, retaken, defused, or left to go off with everyone out of its
-- blast (docs/research/61-bots-and-the-spike.md).

local BotBrain = require("../src/shared/Bots/BotBrain")
local BotConfig = require("../src/shared/Bots/BotConfig")
local BotMove = require("../src/shared/Bots/BotMove")
local BotNav = require("../src/shared/Bots/BotNav")
local BotSpike = require("../src/shared/Bots/BotSpike")
local BotSpots = require("../src/shared/Bots/BotSpots")
local BotTeam = require("../src/shared/Bots/BotTeam")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local Spike = require("../src/shared/Spike/Spike")
local SpikeSim = require("../src/shared/Spike/SpikeSim")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local H = require("./Harness")
local TileWorld = require("./TileWorld")

local check = H.check

local B = PlayerSim.Buttons
local P = BotConfig.Params
local SP = Spike.Params
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
-- Each side's plan is gone over every P.think, from the first tick.
local THINK = math.round(P.think.value / DT)
-- Where an eye looks at the spike: a little over the ground (RobloxSpike's).
local CENTRE = vector.create(0, 0.15, 0)
local BODY = 1.8 -- metres, a player's height (SpikeServer's, for the blast)

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

local function list(xs: { number }, unit: string): string
	local out = {}
	for _, x in xs do
		table.insert(out, string.format("%.1f%s", x, unit))
	end
	return table.concat(out, ", ")
end

-- A map, ready to play on: its plan, its solids as a world, and its plant
-- areas in its own frame.
type Ground = { map: any, plan: BotSpots.Plan, nav: BotNav.Nav, world: any, zones: { Spike.Zone } }

local grounds: { [string]: Ground } = {}

local function groundOf(key: string): Ground
	local known = grounds[key]
	if known then
		return known
	end
	local map = SpikeMaps.Maps[key]
	local plan = BotSpots.ofMap(map)
	local x0, z0, x1, z1 = map.bounds()
	local zones: { Spike.Zone } = {}
	for _, z in map.zones() do
		table.insert(zones, { site = z.site, center = z.center - map.origin, half = z.half, yaw = z.yaw })
	end
	local g: Ground = { map = map, plan = plan, nav = plan.nav, world = TileWorld.new(plan.nav.solids, x0, z0, x1, z1), zones = zones }
	grounds[key] = g
	return g
end

-- A bot's body, as the server drives one: its simulation, its walk and its
-- view, which looks the way it walks.
type Walker = { id: number, sim: PlayerSim.State, mover: BotMove.Mover, yaw: number, seq: number }

local function walkerAt(nav: BotNav.Nav, id: number, feet: vector, yaw: number): Walker
	return {
		id = id,
		sim = PlayerSim.new(feet + vector.create(0, 0.05, 0), { "vandal", "classic", "knife", "" }, id),
		mover = BotMove.new(nav, diceOf(id * 31 + 7)),
		yaw = yaw,
		seq = 0,
	}
end

-- The spike as the server keeps it (SpikeServer): what it's doing, where,
-- who carries it (a walker's id), and when it goes off.
type Referee = {
	state: "dropped" | "carried" | "planted" | "defused" | "detonated",
	at: vector?,
	carrier: number?,
	site: string?,
	plantedAt: number?,
	detonateAt: number,
	halfSaved: boolean,
	defusedAt: number?,
	defuser: number?,
}

local function lying(at: vector): Referee
	return { state = "dropped", at = at, detonateAt = math.huge, halfSaved = false }
end

-- The spike as a side's plan knows it.
local function viewOf(r: Referee): BotTeam.Spike?
	local state = r.state
	if state == "dropped" or state == "carried" or state == "planted" then
		return { state = state, at = r.at, carrier = r.carrier, site = r.site, detonateAt = r.detonateAt, halfSaved = r.halfSaved }
	end
	return nil
end

-- What a walker may do with the spike this tick: plant it if it carries
-- it; defuse it if it defends and it's planted.
local function contextOf(g: Ground, r: Referee, w: Walker, defender: boolean): Spike.Context
	local planted = if r.state == "planted" then r.at else nil
	return {
		zones = g.zones,
		canPlant = r.state == "carried" and r.carrier == w.id,
		canDefuse = defender and planted ~= nil,
		planted = planted,
		halfSaved = r.halfSaved,
		sees = function(eye: vector, spike: vector): boolean
			return BotNav.sees(g.nav, eye, spike + CENTRE)
		end,
	}
end

-- One tick of a walker at time `t` as the server drives a bot
-- (BotServer.drive): its hands (BotSpike), right onto the point its job
-- says once near, else its walk. What its simulation did with the spike.
local function tick(g: Ground, w: Walker, t: number, o: BotTeam.Order?, ctx: Spike.Context): SpikeSim.Act?
	local sim = w.sim
	local feet = sim.movement.position
	local there = true
	if o and o.goal then
		local spot = BotNav.feet(g.nav, o.goal)
		there = vector.magnitude(vector.create(spot.x - feet.x, 0, spot.z - feet.z)) <= 1 and math.abs(spot.y - feet.y) < 1
	end
	local hands = BotSpike.hands(o, there, sim, ctx, (sim.movement.tick + 1) * DT, PlayerSim.eye(sim, cfg), false)
	local buttons = 0
	local direction: vector? = nil
	local onto = if o then o.onto else nil
	local toward = if onto then vector.create(onto.x - feet.x, 0, onto.z - feet.z) else nil
	if hands.still then
		BotMove.hold(w.mover)
	elseif onto and toward and vector.magnitude(toward) <= 1.5 and math.abs(onto.y - feet.y) < 1 then
		if vector.magnitude(toward) > 0.15 then
			direction = vector.normalize(toward)
		end
		BotMove.hold(w.mover)
	else
		local step = BotMove.step(w.mover, t, feet, if o then o.goal else nil)
		direction = step.direction
		if step.jump then
			buttons += B.Jump
		end
		if direction and o and o.walk then
			buttons += B.Walk
		end
	end
	if direction then
		local want = math.atan2(-direction.x, -direction.z)
		w.yaw += BotBrain.wrap(want - w.yaw) * math.min(DT / P.lookEase.value, 1)
		local forward, right = BotMove.keys(direction, w.yaw)
		if forward > 0 then
			buttons += B.Forward
		elseif forward < 0 then
			buttons += B.Back
		end
		if right > 0 then
			buttons += B.Right
		elseif right < 0 then
			buttons += B.Left
		end
	end
	if hands.use then
		buttons += B.Use
	end
	w.seq += 1
	local input = { seq = w.seq, buttons = buttons, yaw = w.yaw, pitch = 0, slot = hands.slot or 1, viewTime = 0 }
	local _, _, act = PlayerSim.step(sim, input, cfg, g.world, DT, ctx)
	return act
end

-- What the server makes of what a walker's simulation did, at time `t`:
-- a plant, a defuse, or a defuse let go of past its half.
local function hear(r: Referee, w: Walker, act: SpikeSim.Act?, t: number)
	if not act then
		return
	end
	if act.kind == "planted" and r.state == "carried" and r.carrier == w.id then
		r.state = "planted"
		r.at = act.position
		r.site = act.site
		r.carrier = nil
		r.plantedAt = t
		r.detonateAt = t + SP.detonateTime.value
	elseif act.kind == "defused" and r.state == "planted" and t < r.detonateAt then
		r.state = "defused"
		r.defusedAt = t
		r.defuser = w.id
	elseif act.kind == "stopped" and r.state == "planted" and act.progress >= SP.defuseHalf.value - 1e-9 then
		r.halfSaved = true
	end
end

-- Running over it picks it up, for a walker sent to fetch it.
local function pickUp(r: Referee, w: Walker, o: BotTeam.Order?)
	local at = r.at
	if r.state == "dropped" and at and o and o.task == "fetch" and Spike.runsOver(w.sim.movement.position, at) then
		r.state = "carried"
		r.carrier = w.id
		r.at = nil
		WeaponSim.give(w.sim.weapons, Spike.SLOT, Spike.ID)
	end
end

local function members(walkers: { Walker }): { BotTeam.Member }
	local out = {}
	for _, w in walkers do
		local s = w.sim.spike
		local defusing = if s.channel == SpikeSim.DEFUSING then SpikeSim.defuseProgress(s, w.sim.movement.tick * DT) else nil
		table.insert(out, { id = w.id, bot = true, alive = true, feet = w.sim.movement.position, defusing = defusing })
	end
	return out
end

-- How near the blast comes to someone standing at `feet`: from the spike
-- to the nearest point between their feet and the top of their head.
local function fromBlast(feet: vector, spike: vector): number
	local nearest = vector.create(feet.x, math.clamp(spike.y, feet.y, feet.y + BODY), feet.z)
	return vector.magnitude(nearest - spike)
end

-- Who goes for it -----------------------------------------------------------------------

H.section("Bots and the spike: who goes for it (system 61)")

do
	local g = groundOf("outpost")
	local spots = g.map.spots("attack")
	local start = g.map.spikeStart
	local function fetchers(orders: { [number]: BotTeam.Order }): { number }
		local out = {}
		for id, o in orders do
			if o.task == "fetch" then
				table.insert(out, id)
			end
		end
		return out
	end
	local function team(withPlayer: boolean): (BotTeam.Team, { BotTeam.Member })
		local t = BotTeam.new(g.nav, g.plan, "attack", diceOf(5), nil)
		BotTeam.round(t, 0)
		local all = {}
		for k = 1, 4 do
			table.insert(all, { id = k, bot = true, alive = true, feet = spots[k].feet })
		end
		if withPlayer then
			table.insert(all, { id = 100, bot = false, alive = true, feet = spots[5].feet })
		end
		return t, all
	end
	local spike: BotTeam.Spike = { state = "dropped", at = start, detonateAt = math.huge, halfSaved = false }

	local t, all = team(false)
	local orders = BotTeam.think(t, 0.5, true, all, {}, spike)
	local who = fetchers(orders)
	local nearest, best = 0, math.huge
	for _, m in all do
		local d = vector.magnitude(m.feet - start)
		if d < best then
			nearest, best = m.id, d
		end
	end
	check("no player on the side: the bot nearest the spike goes for it as the round starts", #who == 1 and who[1] == nearest)
	check("and steps right onto it", #who == 1 and orders[who[1]].onto == start)

	local tp, withPlayer = team(true)
	local early = fetchers(BotTeam.think(tp, 0.5, true, withPlayer, {}, spike))
	local before = fetchers(BotTeam.think(tp, 0.5 + BotTeam.DEFER - 0.5, true, withPlayer, {}, spike))
	local after = fetchers(BotTeam.think(tp, 0.5 + BotTeam.DEFER + 0.1, true, withPlayer, {}, spike))
	check(
		string.format("a player on the side: the bots leave it to them for %d s, then one goes for it", BotTeam.DEFER),
		#early == 0 and #before == 0 and #after == 1,
		string.format("%d, %d, then %d going for it", #early, #before, #after)
	)
	-- Dropped again somewhere else, the wait starts over.
	local moved: BotTeam.Spike = { state = "dropped", at = start + vector.create(0, 0, -20), detonateAt = math.huge, halfSaved = false }
	local again = fetchers(BotTeam.think(tp, 20, true, withPlayer, {}, moved))
	local later = fetchers(BotTeam.think(tp, 20 + BotTeam.DEFER + 0.1, true, withPlayer, {}, moved))
	check("dropped somewhere else, it's left to the player again first", #again == 0 and #later == 1)
	local carried: BotTeam.Spike = { state = "carried", carrier = 100, detonateAt = math.huge, halfSaved = false }
	check("carried by the player, no bot goes for it", #fetchers(BotTeam.think(tp, 40, true, withPlayer, {}, carried)) == 0)
end

-- A bot's hands --------------------------------------------------------------------------

H.section("Bots and the spike: a bot's hands (system 61)")

do
	local g = groundOf("outpost")
	local zone = g.zones[1]
	local feet = zone.center - vector.create(0, zone.half.y, 0)
	local ctx: Spike.Context = { zones = g.zones, canPlant = true, canDefuse = false, planted = nil, halfSaved = false, sees = nil }
	local plant: BotTeam.Order = { task = "plant", goal = nil, look = nil, walk = false }
	local function carrier(): PlayerSim.State
		local sim = PlayerSim.new(feet, { "vandal", "classic", "knife", Spike.ID }, 1)
		sim.movement.grounded = true
		return sim
	end
	local sim = carrier()
	local h = BotSpike.hands(plant, true, sim, ctx, 1, PlayerSim.eye(sim, cfg), false)
	check("in the plant area with the spike: draws it and stands still", h.slot == Spike.SLOT and h.still and h.quiet and not h.use)
	sim.weapons.equipped = Spike.SLOT
	h = BotSpike.hands(plant, true, sim, ctx, 1, PlayerSim.eye(sim, cfg), false)
	check("in hand: holds Use, and never fire, which would plant it too", h.use and h.quiet)
	local away = BotSpike.hands(plant, false, sim, ctx, 1, PlayerSim.eye(sim, cfg), false)
	check("short of the spot planned: no plant yet", not away.use and not away.still)
	h = BotSpike.hands(plant, true, sim, ctx, 1, PlayerSim.eye(sim, cfg), true)
	check("a fight first: lets go, the gun back in hand", not h.use and h.slot == nil and not h.still)
	sim.spike.channel = SpikeSim.PLANTING
	sim.spike.channelStart = 0
	sim.spike.channelEnd = SP.plantTime.value
	h = BotSpike.hands(plant, true, sim, ctx, BotSpike.PLANT_ON + 0.2, PlayerSim.eye(sim, cfg), true)
	check(string.format("but a plant more than %g s in is finished under fire", BotSpike.PLANT_ON), h.use and h.still)

	local spike = feet + vector.create(0.5, 0, 0)
	local dctx: Spike.Context = { zones = g.zones, canPlant = false, canDefuse = true, planted = spike, halfSaved = false, sees = nil }
	local defuse: BotTeam.Order = { task = "defuse", goal = nil, look = nil, walk = false }
	local committed: BotTeam.Order = { task = "defuse", goal = nil, look = nil, walk = false, commit = true }
	local d = PlayerSim.new(feet, nil, 2)
	d.movement.grounded = true
	h = BotSpike.hands(defuse, true, d, dctx, 1, PlayerSim.eye(d, cfg), false)
	check("by the planted spike, in sight of it: holds Use", h.use and h.still and h.quiet)
	local hidden = table.clone(dctx)
	hidden.sees = function(): boolean
		return false
	end
	h = BotSpike.hands(defuse, true, d, hidden, 1, PlayerSim.eye(d, cfg), false)
	check("out of sight of it: doesn't", not h.use)
	h = BotSpike.hands(defuse, true, d, dctx, 1, PlayerSim.eye(d, cfg), true)
	check("a fight first: lets go", not h.use and not h.still)
	h = BotSpike.hands(committed, true, d, dctx, 1, PlayerSim.eye(d, cfg), true)
	check("unless there's no time to fight first", h.use and h.still)
	d.spike.channel = SpikeSim.DEFUSING
	d.spike.channelStart = 0
	h = BotSpike.hands(defuse, true, d, dctx, BotSpike.DEFUSE_ON + 0.2, PlayerSim.eye(d, cfg), true)
	check(string.format("or it's more than %g s of the 7 in", BotSpike.DEFUSE_ON), h.use)
end

-- Rounds ----------------------------------------------------------------------------------

-- The attackers' round on a map, from the spike lying at the start: five
-- bots and no defenders. When it was picked up and planted, where and at
-- which site, and the planted site's plan; and, run on to the blast if
-- `blast`, how many of them stood watching it 10 s after the plant, how
-- much was left on it as each left for out of the blast and how far from
-- it each was then, and how far the blast came to the nearest at the end.
type Attack = {
	fetchedAt: number?,
	plantedAt: number?,
	site: string?,
	planned: string?,
	at: vector?,
	inZone: boolean,
	watching: number,
	leftWith: { number },
	leftFrom: { number },
	nearest: number,
}

local function attackRound(key: string, blast: boolean): Attack
	local g = groundOf(key)
	local spots = g.map.spots("attack")
	local team = BotTeam.new(g.nav, g.plan, "attack", diceOf(11), nil)
	BotTeam.round(team, 0)
	local walkers = {}
	for k = 1, 5 do
		table.insert(walkers, walkerAt(g.nav, k, spots[k].feet, spots[k].yaw))
	end
	local start = g.map.spikeStart
	local r = lying(vector.create(start.x, g.map.floorAt(start.x, start.z) or 0, start.z))
	local out: Attack = { inZone = false, watching = 0, leftWith = {}, leftFrom = {}, nearest = 0, planned = team.site }
	local orders: { [number]: BotTeam.Order } = {}
	local now, ticks = 0, 0
	local limit = 70
	while now < limit do
		now += DT
		ticks += 1
		if ticks % THINK == 1 then
			local before = orders
			orders = BotTeam.think(team, now, true, members(walkers), {}, viewOf(r))
			local plantedAt, at = r.plantedAt, r.at
			for _, w in walkers do
				local o, b = orders[w.id], before[w.id]
				if plantedAt and at and o and o.task == "clear" and not (b and b.task == "clear") then
					table.insert(out.leftWith, plantedAt + SP.detonateTime.value - now)
					table.insert(out.leftFrom, vector.magnitude(w.sim.movement.position - at))
				end
			end
		end
		for _, w in walkers do
			local o = orders[w.id]
			hear(r, w, tick(g, w, now, o, contextOf(g, r, w, false)), now)
			pickUp(r, w, o)
		end
		if r.state == "carried" and out.fetchedAt == nil then
			out.fetchedAt = now
		end
		local plantedAt = r.plantedAt
		if plantedAt and out.plantedAt == nil then
			out.plantedAt = plantedAt
			out.site, out.at = r.site, r.at
			out.inZone = r.at ~= nil and Spike.siteAt(g.zones, r.at :: vector) == r.site
			if not blast then
				break
			end
			limit = now + SP.detonateTime.value
		end
		local at = r.at
		if plantedAt and at and out.watching == 0 and now >= plantedAt + 10 then
			for _, w in walkers do
				local o = orders[w.id]
				local eye = PlayerSim.eye(w.sim, cfg)
				if o and o.task == "guard" and BotNav.sees(g.nav, eye, at + CENTRE) then
					out.watching += 1
				end
			end
		end
	end
	local at = r.at
	if blast and at then
		out.nearest = math.huge
		for _, w in walkers do
			out.nearest = math.min(out.nearest, fromBlast(w.sim.movement.position, at))
		end
	end
	return out
end

H.section("Bots and the spike: fetching it, planting it and watching it (system 61)")

do
	for _, key in SpikeMaps.MAPS do
		local blast = key == "outpost"
		local a = attackRound(key, blast)
		print(
			string.format(
				"  %s: picked up at %s, planted at %s on %s (planned %s)%s",
				key,
				if a.fetchedAt then string.format("%.1f s", a.fetchedAt) else "never",
				if a.plantedAt then string.format("%.1f s", a.plantedAt) else "never",
				tostring(a.site),
				tostring(a.planned),
				if blast
					then string.format("; %d of 5 watching it 10 s on, the blast %.1f m from the nearest", a.watching, a.nearest)
					else ""
			)
		)
		check(
			string.format("%s: a bot picks the spike up as the round starts, and it's planted on the site planned", key),
			a.fetchedAt ~= nil and a.fetchedAt < 4 and a.plantedAt ~= nil and a.site == a.planned and a.inZone
		)
		if blast then
			print(string.format("    leaving it with %s on it, from %s off", list(a.leftWith, " s"), list(a.leftFrom, " m")))
			check("all five watch it from where they see it, 10 s after the plant", a.watching == 5, string.format("%d", a.watching))
			check(
				"and get out of the blast before it goes off",
				a.nearest > SP.blastRadius.value,
				string.format("%.1f m from the nearest", a.nearest)
			)
		end
	end
end

-- The defenders' retake on a map: five defenders from their spawn, the
-- spike planted at the start at the best place to plant a site, with
-- `left` seconds on it (45 for a plant this moment), or from the stages of
-- the site's ways back in if `near`. When it was defused, if it was, and
-- how far the blast came to the nearest if it wasn't; when they pushed;
-- and how many stood round the spike as it was defused.
type Retake = { defusedAt: number?, pushedAt: number?, round: number, nearest: number, cleared: number }

local function retakeRound(key: string, siteIndex: number, left: number, near: boolean): Retake
	local g = groundOf(key)
	local site = g.plan.sites[siteIndex]
	local at = BotNav.feet(g.nav, site.plants[1])
	local team = BotTeam.new(g.nav, g.plan, "defend", diceOf(13), nil)
	BotTeam.round(team, 0)
	local walkers = {}
	local spots = g.map.spots("defend")
	for k = 1, 5 do
		local feet = spots[k].feet
		if near then
			local way = site.retakes[(k - 1) % #site.retakes + 1]
			feet = BotNav.feet(g.nav, way.stage)
		end
		table.insert(walkers, walkerAt(g.nav, k, feet + vector.create((k - 3) * 0.6, 0, 0), spots[k].yaw))
	end
	local r: Referee = { state = "planted", at = at, site = site.name, plantedAt = 0, detonateAt = left, halfSaved = false }
	local out: Retake = { round = 0, nearest = math.huge, cleared = 0 }
	local orders: { [number]: BotTeam.Order } = {}
	local now, ticks = 0, 0
	while now < left + 0.5 and r.state == "planted" do
		now += DT
		ticks += 1
		if ticks % THINK == 1 then
			orders = BotTeam.think(team, now, true, members(walkers), {}, viewOf(r))
			if team.retake == "push" and out.pushedAt == nil then
				out.pushedAt = now
			end
		end
		for _, w in walkers do
			hear(r, w, tick(g, w, now, orders[w.id], contextOf(g, r, w, true)), now)
		end
	end
	out.defusedAt = r.defusedAt
	for _, w in walkers do
		local d = fromBlast(w.sim.movement.position, at)
		out.nearest = math.min(out.nearest, d)
		if w.id ~= r.defuser and vector.magnitude(w.sim.movement.position - at) <= BotTeam.SPREAD + 1.5 then
			out.round += 1
		end
		local o = orders[w.id]
		if o and o.task == "clear" then
			out.cleared += 1
		end
	end
	return out
end

H.section("Bots and the spike: retaking a site and defusing it (system 61)")

do
	for _, key in SpikeMaps.MAPS do
		for index = 1, 2 do
			local g = groundOf(key)
			local name = g.plan.sites[index].name
			local rt = retakeRound(key, index, SP.detonateTime.value, false)
			print(
				string.format(
					"  %s %s: pushed in at %s, defused at %s, %d of the other 4 round the spike",
					key,
					name,
					if rt.pushedAt then string.format("%.1f s", rt.pushedAt) else "never",
					if rt.defusedAt then string.format("%.1f s", rt.defusedAt) else "never",
					rt.round
				)
			)
			check(
				string.format("%s %s: five defenders gather, push in together and defuse it in time", key, name),
				rt.pushedAt ~= nil
					and rt.defusedAt ~= nil
					and rt.defusedAt < SP.detonateTime.value
					and rt.defusedAt >= rt.pushedAt + SP.defuseTime.value
					and rt.round >= 3,
				string.format("%d round it", rt.round)
			)
		end
	end
	-- Too late to make it: out of the blast instead.
	local late = retakeRound("outpost", 1, 9, true)
	print(
		string.format(
			"  9 s left, from the ways back in: %d of 5 out of the blast's way, %.1f m from the nearest",
			late.cleared,
			late.nearest
		)
	)
	check(
		"with no time to get there and defuse it, the defenders get out of the blast",
		late.defusedAt == nil and late.cleared == 5 and late.nearest > SP.blastRadius.value,
		string.format("%.1f m from the nearest", late.nearest)
	)
end

do
	-- Time enough judged by the way there on foot, not as the crow flies:
	-- a defender near the spike but a long way round from it, and one as
	-- near both ways.
	local g = groundOf("foundry")
	local site = g.plan.sites[1]
	local at = BotNav.feet(g.nav, site.plants[1])
	local by = BotSpots.reachableNear(g.nav, g.plan.defend, at, 2) :: number
	local onFoot = BotNav.distances(g.nav, { by }, true)
	local far, near = 0, 0
	local most, least = 0, math.huge
	for n = 1, #g.nav.xs do
		local crow = vector.magnitude(BotNav.feet(g.nav, n) - at)
		local walk = onFoot[n]
		if walk < math.huge and g.plan.defend[n] < math.huge and crow < 20 then
			if walk - crow > most then
				far, most = n, walk - crow
			end
			if crow > 15 and walk - crow < least then
				near, least = n, walk - crow
			end
		end
	end
	local LEFT = 17
	local function judged(n: number): string
		local team = BotTeam.new(g.nav, g.plan, "defend", diceOf(17), nil)
		BotTeam.round(team, 0)
		local spike: BotTeam.Spike = { state = "planted", at = at, site = site.name, detonateAt = 1 + LEFT, halfSaved = false }
		local m: BotTeam.Member = { id = 1, bot = true, alive = true, feet = BotNav.feet(g.nav, n) }
		local orders: { [number]: BotTeam.Order } = {}
		for _ = 1, 8 do
			orders = BotTeam.think(team, 1, true, { m }, {}, spike)
		end
		local o = orders[1]
		return if o then o.task else "none"
	end
	local farTask, nearTask = judged(far), judged(near)
	local function off(n: number): string
		return string.format("%.1f m off, %.1f m on foot", vector.magnitude(BotNav.feet(g.nav, n) - at), onFoot[n])
	end
	print(string.format("  foundry A, %d s left: from %s, %s; from %s, %s", LEFT, off(far), farTask, off(near), nearTask))
	check(
		"time enough is judged by the way there on foot: a long way round, out of the blast; as near on foot, the retake",
		farTask == "clear" and nearTask ~= "clear",
		string.format("%s, %s", farTask, nearTask)
	)
end

return nil
