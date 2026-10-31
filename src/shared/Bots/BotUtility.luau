--!strict
-- A bot's agent's abilities (system 66): when it casts one, at what, and
-- its hands for the cast, tick by tick, as a player's keys and mouse
-- would go.
--
-- When: at the moments a player on its agent would, from where it is in
-- its side's plan (BotTeam.placeOf), each moment's cast rolled once a life
-- against its skill's share (BotConfig's utility), and never while it
-- fights:
--   * gathered short of its way in, before the push (or a retake's): the
--     Recon Bolt over it, at the spots that hold it; and on the push, if
--     it went before the bot got there, while it's still a way off
--   * on the push: Dark Cover on the two spots most likely to hold its way
--     in, a cloud on the first, Paranoia through them, a Curveball round
--     the corner at them, Leer where they'd see it, a Shock Bolt or Hot
--     Hands on the first, and Blade Storm or Empress once it's at the way
--     in
--   * holding a way in: the Recon Bolt toward where the attackers gather,
--     early in the round; and with attackers seen at the way in a moment
--     ago, the stall: a slow, a molly, a wall, a smoke or a cloud on the
--     way in, Paranoia, Leer or a Shock Bolt at them, or Blade Storm or
--     Empress
--   * guarding the planted spike with an enemy heard defusing it: Hunter's
--     Fury through the walls at it, a molly or a Shock Bolt on it
--   * anywhere: a Healing Orb on itself or a hurt teammate in reach once
--     no enemy's been about for a while, and Hunter's Fury at enemies its
--     side saw a moment ago; and in the modes that respawn, Blade Storm or
--     Empress with an enemy seen near
-- Empress's frenzy lasts the life, and the others are cast through it.
--
-- How: every throw is tried before it's thrown, flown through the level as
-- the server will fly it (SmokeSim, FlareSim, FireballSim, SlowSim,
-- BoltSim, CloudSim, ParanoiaSim, BarrierSim, LeerSim), so a bot throws
-- only what lands where it means it to: a smoke on its floor, a molly on
-- the spot, a Recon Bolt where it sees those it's for, Leer's eye short of
-- them where they look, and a flash that blinds them and neither it nor a
-- teammate where they stand, the bot waiting where it threw it until it's
-- popped (bots on its side look away from it as it flies: BotServer).
-- Mollies and Shock Bolts keep off its teammates, and a Shock Bolt off
-- itself. Then its hands play it as a player's do: the ability's key, its
-- aim eased round as the bot's view eases (BotBrain), the throw's button
-- once it's ready and aimed (a draw held to its bars, a smoke's mark sent
-- out to its reach), and the key let go between presses. A throw found
-- from where it stands is thrown from there, standing still; a cast at a
-- point (a smoke, a heal, a wall, Paranoia, Leer, a blast of Hunter's
-- Fury) is aimed again each tick as it walks. One it gives up on, a fight
-- starting or its time running out, it puts away.
--
-- Plain state and maths in metres; the world is MovementSim's, as the
-- sims', so the offline tests throw through a map's own solids.

local AbilityConfig = require("../Abilities/AbilityConfig")
local AbilitySim = require("../Abilities/AbilitySim")
local BarrierSim = require("../Abilities/BarrierSim")
local BoltSim = require("../Abilities/BoltSim")
local FireballSim = require("../Abilities/FireballSim")
local FlareSim = require("../Abilities/FlareSim")
local LeerSim = require("../Abilities/LeerSim")
local ShockSim = require("../Abilities/ShockSim")
local SlowSim = require("../Abilities/SlowSim")
local SmokeSim = require("../Abilities/SmokeSim")
local MovementSim = require("../Movement/MovementSim")
local Accuracy = require("../Weapons/Accuracy")
local WeaponSim = require("../Weapons/WeaponSim")
local BotBrain = require("./BotBrain")
local BotConfig = require("./BotConfig")
local BotTeam = require("./BotTeam")

local BotUtility = {}

-- Someone on its side it might heal: their entity id, where their chest
-- is, and their health.
export type Ally = { id: number, chest: vector, health: number }

-- What a bot knows at a moment, for what it casts, in the place's frame:
-- the server's time and its simulation's own (which its kit is timed by);
-- where it is in its side's plan (BotTeam.Place, moved into the place's
-- frame; nil with no plan, as in the modes that respawn) and how long the
-- round has been live; its feet, eye and health; whether it's fighting,
-- and how long since an enemy was in its sight or hurt it; where its side
-- has seen enemies lately; where the spike is being defused by an enemy,
-- if it is; its teammates it might heal; and its teammates' eyes, which
-- its throws keep off.
export type Moment = {
	now: number,
	clock: number,
	place: BotTeam.Place?,
	live: number,
	feet: vector,
	eye: vector,
	health: number,
	fighting: boolean,
	quiet: number,
	sightings: { BotTeam.Sighting },
	defuse: vector?,
	allies: { Ally },
	mates: { vector },
}

-- What a bot has cast in this life, and when it may next: the moments it
-- has rolled for (true where it may cast), those it has cast for, when
-- each whose throw wasn't found is tried again, and the server's time it
-- may cast from.
export type Memo = {
	rolled: { [string]: boolean },
	done: { [string]: boolean },
	retry: { [string]: number },
	nextAt: number,
}

-- Where a cast is in its hands: its key pressed, its ability coming into
-- hand, its throw (or its draw, its mark or its try), Hunter's Fury's
-- blasts, a flare thrown and not yet popped, or the key let go after an
-- instant cast.
export type Step = "press" | "equip" | "send" | "fury" | "pop" | "after"

-- A cast, chosen for moment `key`: the ability and its slot; its aim, at
-- `target` aimed again each tick from the eye, else along `yaw` and
-- `pitch`, found from where it stands, which it stands at until it's
-- thrown; alt fire's throw (Curveball's round to the right, Hot Hands'
-- lob, the Healing Orb on itself); a bolt's bars and bounces; the
-- Barrier Orb's targeter's turn; Hunter's Fury's targets, in turn; the
-- point it's meant for (a floor it lands on, a spot it's at), for checks;
-- and the longest it may take. Then, under way: its step, when it and its step
-- started (the simulation's time, -1 before its first tick), the buttons
-- it sent last tick, the target Hunter's Fury's next blast goes at, and
-- whether a blast of it is charging.
export type Cast = {
	key: string,
	ability: string,
	slot: number,
	target: vector?,
	yaw: number,
	pitch: number,
	alt: boolean,
	bars: number,
	bounces: number,
	turn: number,
	targets: { vector },
	point: vector?,
	longest: number,
	step: Step,
	from: number,
	stepFrom: number,
	pressed: number,
	blast: number,
	charging: boolean,
}

-- A tick's hands for a cast: the buttons, the slot to ask for meanwhile
-- (the fifth, with the ability in hand: nil for the bot's own), the view,
-- whether it stands where it is, and whether the cast is over (anything
-- left in hand goes away as the bot's own slot is asked for again).
export type Hands = {
	buttons: number,
	slot: number?,
	yaw: number,
	pitch: number,
	still: boolean,
	done: boolean,
}

local U = BotConfig.Utility
local P = BotConfig.Params
local B = MovementSim.Buttons
local X = AbilityConfig.X
local DC = AbilityConfig.DarkCover
local CB = AbilityConfig.Cloudburst
local PA = AbilityConfig.Paranoia
local HH = AbilityConfig.HotHands
local SO = AbilityConfig.SlowOrb
local RC = AbilityConfig.ReconBolt
local SB = AbilityConfig.ShockBolt
local HF = AbilityConfig.HuntersFury
local BO = AbilityConfig.BarrierOrb
local LE = AbilityConfig.Leer
local EPS = 1e-9
local EYE = vector.create(0, 1.62, 0) -- standing (MovementConfig's standEyeHeight)
local UP = vector.create(0, 1, 0)
-- The box a sight line is swept with: thin, as a ray (FlareSim's).
local SIGHT = vector.create(0.01, 0.01, 0.01)
-- How long after its key an ability has to be in hand before the cast's
-- given up: it comes on the tick of the key, unless something stops it.
local GRACE = 0.1
-- Where a planted spike is aimed at: a little over the floor.
local LOW = vector.create(0, 0.3, 0)
-- Hunter's Fury: the most blasts it's cast for, and how far apart their
-- targets are at the least (metres).
local BLASTS = 3
local APART = 4
-- The most spots a Recon Bolt is tried for.
local SPOTS = 3

-- The abilities bots cast. Those left out move the body (Updraft,
-- Tailwind, Shrouded Step, From the Shadows), are steered or flown
-- (Blaze, the Owl Drone), need what the server doesn't yet do for a bot
-- (Run it Back), or want a body to raise (the Resurrection).
local USES: { [string]: boolean } = {
	cloudburst = true,
	bladestorm = true,
	curveball = true,
	hothands = true,
	healingorb = true,
	sloworb = true,
	barrierorb = true,
	darkcover = true,
	paranoia = true,
	leer = true,
	reconbolt = true,
	shockbolt = true,
	huntersfury = true,
	empress = true,
}

-- Casts at once on the key, nothing in hand.
local INSTANT: { [string]: boolean } = { cloudburst = true, bladestorm = true, empress = true }

-- Whether bots cast ability `id`, and so buy its charges.
function BotUtility.uses(id: string): boolean
	return USES[id] == true
end

-- A new life's memo: nothing rolled for or cast.
function BotUtility.memo(): Memo
	return { rolled = {}, done = {}, retry = {}, nextAt = -math.huge }
end

-- A place in the map's frame (BotTeam.placeOf's) moved by `by`: into the
-- place's.
function BotUtility.moved(p: BotTeam.Place, by: vector): BotTeam.Place
	local threats = {}
	for _, t in p.threats do
		table.insert(threats, t + by)
	end
	return {
		role = p.role,
		phase = p.phase,
		there = p.there,
		way = if p.way then p.way + by else nil,
		heading = p.heading,
		door = if p.door then p.door + by else nil,
		from = if p.from then p.from + by else nil,
		threats = threats,
		spike = if p.spike then p.spike + by else nil,
	}
end

-- Throws, tried ------------------------------------------------------------------------

local function flat(a: vector, b: vector): number
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
end

-- Whether nothing of the level is between two points.
local function clearBetween(world: any, a: vector, b: vector): boolean
	local delta = b - a
	if vector.magnitude(delta) < 1e-6 then
		return true
	end
	return world:sweep(a, SIGHT, delta) == nil
end

-- Whether any of `eyes` (teammates', or the thrower's) stands within
-- `radius` of a burst at `at`, a body's height up or down.
local function near(eyes: { vector }, at: vector, radius: number): boolean
	for _, e in eyes do
		local feet = e - EYE
		if flat(feet, at) <= radius and at.y > feet.y - 2 and at.y < e.y + 1 then
			return true
		end
	end
	return false
end

local function new(id: string, slot: number, key: string): Cast
	return {
		key = key,
		ability = id,
		slot = slot,
		target = nil,
		yaw = 0,
		pitch = 0,
		alt = false,
		bars = 0,
		bounces = 0,
		turn = 0,
		targets = {},
		point = nil,
		longest = U.longest.value,
		step = "press",
		from = -1,
		stepFrom = -1,
		pressed = 0,
		blast = 1,
		charging = false,
	}
end

-- A cast at a point, aimed again each tick.
local function at(id: string, slot: number, key: string, target: vector): Cast
	local c = new(id, slot, key)
	c.target = target
	c.point = target
	return c
end

-- The pitches that carry a throw `speed` fast, falling at `g`, `dx` along
-- the level and `dy` up: the low and the high, as nothing in the way and no
-- air time would have them; none if it can't reach.
local function arcs(speed: number, g: number, dx: number, dy: number): { number }
	if dx < 1e-3 then
		return { if dy >= 0 then math.rad(89) else -math.rad(89) }
	end
	local v2 = speed * speed
	local disc = v2 * v2 - g * (g * dx * dx + 2 * dy * v2)
	if disc < 0 then
		return {}
	end
	local r = math.sqrt(disc)
	return { math.atan((v2 - r) / (g * dx)), math.atan((v2 + r) / (g * dx)) }
end

-- Dark Cover on the floor at `floor`: its mark a metre over it, which the
-- smoke falls from, through any wall in the way.
local function smoke(m: Moment, world: any, slot: number, key: string, floor: vector): Cast?
	local target = floor + UP
	local reach = vector.magnitude(target - m.eye)
	if reach < DC.near.value or reach > DC.reach.value then
		return nil
	end
	local centre = SmokeSim.place(world, m.eye, (target - m.eye) / reach, reach)
	if not centre or flat(centre, floor) > U.smokeMiss.value or math.abs(centre.y - floor.y) > 2 then
		return nil
	end
	local c = at("darkcover", slot, key, target)
	c.point = floor
	-- And the time its mark takes to go out from where it starts.
	c.longest += math.max(reach - DC.start.value, 0) / DC.push.value
	return c
end

-- Paranoia through `point`, if its orb gets there.
local function paranoia(m: Moment, slot: number, key: string, point: vector): Cast?
	local d = vector.magnitude(point - m.eye)
	if d < 1 or d > PA.offset.value + PA.travel.value then
		return nil
	end
	return at("paranoia", slot, key, point)
end

-- Leer at those at `points`, each looking toward `watch`: cast at the
-- first whose eye would come to rest short of them, as far as the level
-- lets it fly, in their view, with nothing of the level between.
local function leer(m: Moment, world: any, slot: number, key: string, points: { vector }, watch: vector): Cast?
	for _, point in points do
		local d = vector.magnitude(point - m.eye)
		local look = watch - point
		if d <= LE.travel.value + 1 or vector.magnitude(look) < 1e-6 then
			continue
		end
		local aim = (point - m.eye) / d
		local rest = LeerSim.rest(LeerSim.cast(0, 0, 0, m.eye, aim, LeerSim.reach(world, m.eye, aim)))
		if LeerSim.looks(rest, point, vector.normalize(look)) and clearBetween(world, rest, point) then
			return at("leer", slot, key, point)
		end
	end
	return nil
end

-- Cloudburst at `point`, straight there, if it bursts near it: at it, or at
-- what's in the way just short of it.
local function cloud(m: Moment, world: any, slot: number, key: string, point: vector): Cast?
	local d = vector.magnitude(point - m.eye)
	if d < 2 then
		return nil
	end
	local aim = (point - m.eye) / d
	local most = CB.speed.value * CB.maxFlight.value
	local size = CB.size.value
	local fraction = world:sweep(m.eye, vector.create(size, size, size), aim * most)
	local burst = m.eye + aim * (most * (fraction or 1))
	if vector.magnitude(burst - point) > U.cloudMiss.value then
		return nil
	end
	return at("cloudburst", slot, key, point)
end

-- Where a throw of `id` (Hot Hands' fireball, lobbed with `lob`, or the
-- Slow Orb) from the eye along `aim` bursts, flown as the server flies it,
-- if it does in the time a throw's tried for.
local function burst(id: string, eye: vector, aim: vector, lob: boolean, world: any): vector?
	local ball = if id == "sloworb" then SlowSim.throw(0, 0, eye, aim) else FireballSim.throw(0, 0, eye, aim, lob)
	local dt = U.flightTick.value
	while not ball.landed and ball.age < U.flight.value - EPS do
		FireballSim.step(ball, dt, world)
	end
	return if ball.landed then ball.position else nil
end

-- A molly (Hot Hands) or the Slow Orb on the floor at `floor`, keeping its
-- teammates out of it (and with the Slow Orb, itself): the low arc and the
-- lob's drop tried first, then pitches over the range, then finer round
-- the nearest.
local function lob(m: Moment, world: any, slot: number, key: string, id: string, floor: vector): Cast?
	local radius = (if id == "sloworb" then SO.radius.value else HH.radius.value) + U.clear.value
	if near(m.mates, floor, radius) or (id == "sloworb" and near({ m.eye }, floor, radius)) then
		return nil
	end
	local yaw = BotBrain.anglesTo(m.eye, floor)
	local d = floor - m.eye
	local dx, dy = math.sqrt(d.x * d.x + d.z * d.z), d.y
	local bestMiss, bestPitch, bestLob = math.huge, 0, false
	local function try(pitch: number, lobbed: boolean): boolean
		pitch = math.clamp(pitch, -math.rad(89), math.rad(89))
		local p = burst(id, m.eye, Accuracy.aim(yaw, pitch), lobbed, world)
		if not p then
			return false
		end
		local miss = vector.magnitude(p - floor)
		if miss < bestMiss then
			bestMiss, bestPitch, bestLob = miss, pitch, lobbed
		end
		return miss <= U.throwMiss.value
	end
	local modes: { boolean } = if id == "hothands" then { false, true } else { false }
	for _, lobbed in modes do
		local speed = if id == "sloworb" then SO.speed.value elseif lobbed and HH.lobSpeed then HH.lobSpeed.value else HH.speed.value
		local g = if id == "sloworb" then SO.gravity.value * SO.worldGravity.value else HH.gravity.value * HH.worldGravity.value
		local guesses = arcs(speed, g, dx, dy)
		-- A fireball out of air time drops straight down: thrown to reach
		-- the spot as it runs out, it falls onto it.
		local air = if id == "hothands" then HH.airTime else nil
		if air and dx < speed * air.value then
			table.insert(guesses, math.acos(dx / (speed * air.value)))
		end
		for _, pitch in guesses do
			if try(pitch, lobbed) then
				break
			end
		end
		if bestMiss <= U.throwMiss.value then
			break
		end
	end
	if bestMiss > U.throwMiss.value then
		local pitch = math.rad(U.pitchFrom.value)
		while pitch <= math.rad(U.pitchTo.value) + EPS and bestMiss > U.throwMiss.value do
			for _, lobbed in modes do
				if try(pitch, lobbed) then
					break
				end
			end
			pitch += math.rad(U.pitchStep.value)
		end
	end
	if bestMiss > U.throwMiss.value and bestMiss < math.huge then
		local from, lobbed = bestPitch, bestLob
		for k = 1, 3 do
			if try(from + k * math.rad(U.fineStep.value), lobbed) or try(from - k * math.rad(U.fineStep.value), lobbed) then
				break
			end
		end
	end
	if bestMiss > U.throwMiss.value then
		return nil
	end
	local c = new(id, slot, key)
	c.yaw, c.pitch, c.alt = yaw, bestPitch, bestLob
	c.point = floor
	return c
end

-- Where a bolt drawn to `bars` from the eye along `aim`, with no bounce,
-- sticks, and the way the surface there faces, if it does in the time a
-- throw's tried for.
local function stick(eye: vector, aim: vector, bars: number, world: any): (vector?, vector?)
	local bolt = BoltSim.shoot(0, 0, eye, aim, bars, 0)
	local dt = U.flightTick.value
	while not bolt.landed and bolt.age < U.flight.value - EPS do
		BoltSim.step(bolt, dt, world)
	end
	if not bolt.landed then
		return nil, nil
	end
	return bolt.position, bolt.normal
end

-- A Shock Bolt at `point` (a spot's floor, or the spike): sticking near
-- enough, in sight of it, and far enough from its teammates and itself.
local function shock(m: Moment, world: any, slot: number, key: string, point: vector): Cast?
	local radius = SB.outer.value + U.clear.value
	if near(m.mates, point, radius) or vector.magnitude(m.eye - point) <= radius then
		return nil
	end
	local yaw = BotBrain.anglesTo(m.eye, point)
	local d = point - m.eye
	local dx, dy = math.sqrt(d.x * d.x + d.z * d.z), d.y
	-- Each draw's low arc: a high one flies too long.
	for bars = RC.bars.value, 1, -1 do
		local pitch = arcs(BoltSim.speed(bars), BoltSim.gravity(bars), dx, dy)[1]
		local stuck, normal = nil, nil
		if pitch then
			stuck, normal = stick(m.eye, Accuracy.aim(yaw, pitch), bars, world)
		end
		if
			pitch
			and stuck
			and normal
			and vector.magnitude(stuck - point) <= U.throwMiss.value
			and clearBetween(world, ShockSim.eye(stuck, normal), point)
			and not near(m.mates, stuck, radius)
			and vector.magnitude(m.eye - stuck) > radius
		then
			local c = new("shockbolt", slot, key)
			c.yaw, c.pitch, c.bars = yaw, pitch, bars
			c.point = point
			return c
		end
	end
	return nil
end

-- The Recon Bolt where its pulses reveal the most of `points`: drawn full
-- (fast and nearly straight) at their middle, a little over it, and over
-- each, and through each of `through` (the way in, from outside it), and
-- a little higher each time, so it sticks where it sees them.
local function recon(m: Moment, world: any, slot: number, key: string, points: { vector }, through: { vector }?): Cast?
	if #points == 0 then
		return nil
	end
	local middle = vector.zero
	for _, p in points do
		middle += p
	end
	middle /= #points
	local aims = { middle + UP, middle + UP * 4 }
	for _, p in points do
		table.insert(aims, p + UP * 1.5)
	end
	if through then
		for _, p in through do
			table.insert(aims, p)
		end
	end
	local bars = RC.bars.value
	local bestSeen, best = 0, nil :: Cast?
	for _, a in aims do
		local yaw, pitch = BotBrain.anglesTo(m.eye, a)
		for _, extra in { 0, 4, 10 } do
			local up = pitch + math.rad(extra)
			local stuck, normal = stick(m.eye, Accuracy.aim(yaw, up), bars, world)
			if stuck and normal then
				local eye = stuck + normal * RC.lift.value
				local seen = 0
				for _, p in points do
					if vector.magnitude(p - eye) <= RC.radius.value and clearBetween(world, eye, p) then
						seen += 1
					end
				end
				if seen > bestSeen then
					local c = new("reconbolt", slot, key)
					c.yaw, c.pitch, c.bars = yaw, up, bars
					bestSeen, best = seen, c
					if seen == #points then
						return c
					end
				end
			end
		end
	end
	return best
end

-- A Curveball at those holding the way in at `way`: thrown toward it, a
-- little either side, round to the left and to the right, and the pop that
-- blinds them most (each watching the way in), seen neither by the bot
-- nor by a teammate, if it blinds them enough.
local function flash(m: Moment, world: any, slot: number, key: string, way: vector, threats: { vector }): Cast?
	local baseYaw, pitch = BotBrain.anglesTo(m.eye, way)
	local bestScore, best = U.flashWorth.value - EPS, nil :: Cast?
	for _, offset in { 0, 20, -20, 40, -40, 60, -60 } do
		local yaw = baseYaw + math.rad(offset)
		for _, curve in { -1, 1 } do
			local f = FlareSim.throw(0, 0, m.eye, Accuracy.aim(yaw, pitch), curve)
			local path = FlareSim.fly(f, U.flareTick.value, world)
			local pop = path[#path]
			if FlareSim.seen(pop, m.eye, world) then
				continue
			end
			local blinds = false
			for _, e in m.mates do
				local to = pop - e
				local d = vector.magnitude(to)
				if d > 1e-6 and FlareSim.seen(pop, e, world) and FlareSim.strength(pop, e, to / d) > U.flashMate.value then
					blinds = true
					break
				end
			end
			if blinds then
				continue
			end
			local score = 0
			for _, h in threats do
				local look = way - h
				if vector.magnitude(look) > 1e-6 and FlareSim.seen(pop, h, world) then
					score += FlareSim.strength(pop, h, vector.normalize(look))
				end
			end
			if score > bestScore then
				local c = new("curveball", slot, key)
				c.yaw, c.pitch, c.alt = yaw, pitch, curve > 0
				bestScore, best = score, c
			end
		end
	end
	return best
end

-- The Barrier Orb's wall on the floor at `floor`, across the way in that
-- goes `heading`, if it's in range and stands there.
local function wall(m: Moment, world: any, slot: number, key: string, floor: vector, heading: vector?): Cast?
	local target = floor + UP * 0.1
	local d = vector.magnitude(target - m.eye)
	if d < 1 or d > BO.range.value then
		return nil
	end
	local yaw = BotBrain.anglesTo(m.eye, target)
	local turn = 0
	if heading then
		local along0 = BarrierSim.axes(BarrierSim.angle(yaw, 0))
		local along1 = BarrierSim.axes(BarrierSim.angle(yaw, BarrierSim.QUARTER))
		turn = if math.abs(vector.dot(along0, heading)) <= math.abs(vector.dot(along1, heading)) then 0 else BarrierSim.QUARTER
	end
	local placed = BarrierSim.place(world, m.eye, (target - m.eye) / d, BarrierSim.angle(yaw, turn))
	if not placed or flat(placed.centre, floor) > U.wallMiss.value then
		return nil
	end
	local c = at("barrierorb", slot, key, target)
	c.turn = turn
	c.point = floor
	return c
end

-- Hunter's Fury at `points`, up to three in its range at least APART apart,
-- through the walls.
local function fury(m: Moment, slot: number, key: string, points: { vector }): Cast?
	local targets: { vector } = {}
	for _, p in points do
		if vector.magnitude(p - m.eye) > HF.range.value then
			continue
		end
		local apart = true
		for _, q in targets do
			apart = apart and vector.magnitude(p - q) >= APART
		end
		if apart then
			table.insert(targets, p)
		end
		if #targets >= BLASTS then
			break
		end
	end
	if #targets == 0 then
		return nil
	end
	local c = at("huntersfury", slot, key, targets[1])
	c.targets = targets
	c.longest = U.furyLongest.value
	return c
end

-- The Healing Orb on an ally it sees, or on itself.
local function heal(m: Moment, world: any, slot: number, key: string, ally: Ally?): Cast?
	if ally then
		if not clearBetween(world, m.eye, ally.chest) then
			return nil
		end
		return at("healingorb", slot, key, ally.chest)
	end
	local c = new("healingorb", slot, key)
	c.alt = true
	return c
end

-- Choosing ------------------------------------------------------------------------------

-- The latest sighting of its side's within `within` of `point`, no older than
-- `since` seconds.
local function seenNear(m: Moment, point: vector, within: number, since: number): vector?
	local best: vector? = nil
	local bestAt = -math.huge
	for _, s in m.sightings do
		if m.now - s.time <= since and s.time > bestAt and vector.magnitude(s.at - point) <= within then
			best, bestAt = s.at, s.time
		end
	end
	return best
end

-- The hurt ally in reach it would heal first: the most hurt.
local function hurtAlly(m: Moment): Ally?
	local best: Ally? = nil
	for _, a in m.allies do
		if a.health > 0 and a.health <= U.allyFrom.value and vector.magnitude(a.chest - m.eye) <= U.allyReach.value then
			if best == nil or a.health < best.health then
				best = a
			end
		end
	end
	return best
end

local function firstOf(list: { vector }, most: number): { vector }
	local out = {}
	for k = 1, math.min(most, #list) do
		table.insert(out, list[k])
	end
	return out
end

type Option = { id: string, key: string, again: boolean, retry: number?, solve: (slot: number) -> Cast? }

-- What to cast now, and how: the first, by priority, of the casts the
-- moment calls for that its kit has a charge of (or the points), that it
-- rolls to make (once a life for each), and that a throw's found for (one
-- that isn't is tried again a while on, from wherever the bot's got to).
-- Nil for nothing. Past `deadline` (os.clock's), no more throws are tried
-- this time: those left are tried the next.
function BotUtility.choose(
	m: Moment,
	kit: AbilitySim.State,
	memo: Memo,
	skill: BotConfig.Skill,
	dice: BotConfig.Dice,
	world: any,
	deadline: number?
): Cast?
	if m.fighting or m.now < memo.nextAt or kit.holding ~= 0 or kit.steering ~= 0 then
		return nil
	end
	local ultimate = AbilitySim.ultimateOn(kit) and not AbilitySim.frenzied(kit, m.clock)
	if AbilitySim.busy(kit, m.clock) or ultimate or AbilitySim.charging(kit, m.clock) then
		return nil
	end
	local options: { Option } = {}
	local function add(id: string, key: string, solve: (slot: number) -> Cast?, again: boolean?, retry: number?)
		table.insert(options, { id = id, key = key, again = again == true, retry = retry, solve = solve })
	end
	local place = m.place
	local role = if place then place.role else "none"
	local threats = if place then place.threats else {}
	-- An enemy defusing the spike it guards: at the spike, through walls.
	local defuse = m.defuse
	if role == "guard" and defuse then
		add("huntersfury", "defuse:huntersfury", function(slot: number): Cast?
			return fury(m, slot, "defuse:huntersfury", { defuse + EYE * 0.4 })
		end)
		add("hothands", "defuse:hothands", function(slot: number): Cast?
			return lob(m, world, slot, "defuse:hothands", "hothands", defuse)
		end)
		add("shockbolt", "defuse:shockbolt", function(slot: number): Cast?
			return shock(m, world, slot, "defuse:shockbolt", defuse + LOW)
		end)
	end
	-- Hurt, with no enemy about for a while: a heal, on itself first.
	if m.quiet >= U.quiet.value then
		if m.health > 0 and m.health <= U.healFrom.value then
			add("healingorb", "heal", function(slot: number): Cast?
				return heal(m, world, slot, "heal", nil)
			end, true)
		end
		local ally = hurtAlly(m)
		if ally then
			add("healingorb", "heal", function(slot: number): Cast?
				return heal(m, world, slot, "heal", ally)
			end, true)
		end
	end
	-- Gathered short of its way in: the Recon Bolt over it, and through
	-- it. Not there yet as the push goes (it fetched the spike, say), it's
	-- cast on the way while the way in's still a way off, tried again soon,
	-- from where it sees the way in, as it walks on.
	local way = if place then place.way else nil
	if place and role == "entry" and #threats > 0 then
		local gathered = place.phase == "gather" and place.there
		local late = place.phase == "push" and way ~= nil and vector.magnitude(m.eye - way) >= U.reconFar.value
		if gathered or late then
			local through = if way then { way } else {}
			if way and place.door then
				table.insert(through, place.door + EYE)
			end
			add("reconbolt", "gather:reconbolt", function(slot: number): Cast?
				if not gathered and way and not clearBetween(world, m.eye, way) then
					return nil
				end
				return recon(m, world, slot, "gather:reconbolt", firstOf(threats, SPOTS), through)
			end, false, if gathered then nil else U.reconRetry.value)
		end
	end
	-- Going in through its way.
	if place and role == "entry" and place.phase == "push" and way and #threats > 0 then
		local d = vector.magnitude(m.eye - way)
		local first = threats[1]
		if d <= U.stormNear.value then
			add("bladestorm", "push:bladestorm", function(slot: number): Cast?
				return new("bladestorm", slot, "push:bladestorm")
			end)
			add("empress", "push:empress", function(slot: number): Cast?
				return new("empress", slot, "push:empress")
			end)
		end
		for k = 1, math.min(2, #threats) do
			local key = "push:darkcover:" .. k
			add("darkcover", key, function(slot: number): Cast?
				return smoke(m, world, slot, key, threats[k] - EYE)
			end)
		end
		-- A cloud on the spot, else on its sight of the way in: halfway, or at
		-- the door, else on the way in.
		local door = if place.door then place.door + EYE else way
		local sights = { first, (door + first) / 2, door, way }
		add("cloudburst", "push:cloudburst", function(slot: number): Cast?
			for _, point in sights do
				local c = cloud(m, world, slot, "push:cloudburst", point)
				if c then
					return c
				end
			end
			return nil
		end)
		if d <= U.paranoiaNear.value then
			add("paranoia", "push:paranoia", function(slot: number): Cast?
				return paranoia(m, slot, "push:paranoia", first)
			end)
		end
		if d <= U.flashNear.value then
			add("curveball", "push:curveball", function(slot: number): Cast?
				return flash(m, world, slot, "push:curveball", way, threats)
			end)
			add("leer", "push:leer", function(slot: number): Cast?
				return leer(m, world, slot, "push:leer", threats, way)
			end)
		end
		add("shockbolt", "push:shockbolt", function(slot: number): Cast?
			return shock(m, world, slot, "push:shockbolt", first - EYE + LOW)
		end)
		add("hothands", "push:hothands", function(slot: number): Cast?
			return lob(m, world, slot, "push:hothands", "hothands", first - EYE)
		end)
	end
	-- Holding its way in.
	if place and role == "hold" and way then
		local from = place.from
		if from and place.there and m.live >= U.reconFrom.value and m.live <= U.reconTo.value then
			add("reconbolt", "hold:reconbolt", function(slot: number): Cast?
				return recon(m, world, slot, "hold:reconbolt", { from, way })
			end)
		end
		local seen = seenNear(m, way, U.stallNear.value, U.stallRecent.value)
		if seen then
			-- On the floor where they come in: at the door, else out on the
			-- way in.
			local floors = { way - EYE }
			if place.door then
				table.insert(floors, 1, place.door)
			end
			local function first(solve: (floor: vector) -> Cast?): Cast?
				for _, floor in floors do
					local c = solve(floor)
					if c then
						return c
					end
				end
				return nil
			end
			add("sloworb", "stall:sloworb", function(slot: number): Cast?
				return first(function(floor: vector): Cast?
					return lob(m, world, slot, "stall:sloworb", "sloworb", floor)
				end)
			end)
			add("hothands", "stall:hothands", function(slot: number): Cast?
				return first(function(floor: vector): Cast?
					return lob(m, world, slot, "stall:hothands", "hothands", floor)
				end)
			end)
			add("barrierorb", "stall:barrierorb", function(slot: number): Cast?
				return first(function(floor: vector): Cast?
					return wall(m, world, slot, "stall:barrierorb", floor, place.heading)
				end)
			end)
			add("darkcover", "stall:darkcover", function(slot: number): Cast?
				return first(function(floor: vector): Cast?
					return smoke(m, world, slot, "stall:darkcover", floor)
				end)
			end)
			add("cloudburst", "stall:cloudburst", function(slot: number): Cast?
				return first(function(floor: vector): Cast?
					return cloud(m, world, slot, "stall:cloudburst", floor + EYE)
				end)
			end)
			add("paranoia", "stall:paranoia", function(slot: number): Cast?
				return paranoia(m, slot, "stall:paranoia", seen)
			end)
			add("leer", "stall:leer", function(slot: number): Cast?
				return leer(m, world, slot, "stall:leer", { seen }, m.eye)
			end)
			add("shockbolt", "stall:shockbolt", function(slot: number): Cast?
				return shock(m, world, slot, "stall:shockbolt", seen - EYE * 0.6)
			end)
			add("bladestorm", "stall:bladestorm", function(slot: number): Cast?
				return new("bladestorm", slot, "stall:bladestorm")
			end)
			add("empress", "stall:empress", function(slot: number): Cast?
				return new("empress", slot, "stall:empress")
			end)
		end
	end
	-- Anywhere: Hunter's Fury at enemies seen a moment ago; and with no plan
	-- (the modes that respawn), Blade Storm or Empress with one seen near.
	local recent: { vector } = {}
	for _, s in m.sightings do
		if m.now - s.time <= U.furyRecent.value then
			table.insert(recent, s.at)
		end
	end
	if #recent > 0 then
		add("huntersfury", "fury", function(slot: number): Cast?
			return fury(m, slot, "fury", recent)
		end)
	end
	if role == "none" and seenNear(m, m.eye, U.stormNear.value, U.stallRecent.value) then
		add("bladestorm", "storm", function(slot: number): Cast?
			return new("bladestorm", slot, "storm")
		end)
		add("empress", "empress", function(slot: number): Cast?
			return new("empress", slot, "empress")
		end)
	end
	for _, o in options do
		local slot = AbilitySim.slotOf(kit, o.id)
		local stocked = slot ~= nil and (if slot == X then AbilitySim.charged(kit) else kit.charges[slot] > 0)
		local retry = memo.retry[o.key]
		if not slot or not stocked or not USES[o.id] or memo.done[o.key] or (retry and m.now < retry) then
			continue
		end
		local rolled = memo.rolled[o.key]
		if rolled == nil then
			rolled = dice() < skill.utility.value
			memo.rolled[o.key] = rolled
		end
		if not rolled then
			continue
		end
		local c = o.solve(slot)
		if c then
			if not o.again then
				memo.done[o.key] = true
			end
			return c
		end
		memo.retry[o.key] = m.now + (o.retry or U.retry.value)
		if deadline and os.clock() > deadline then
			return nil
		end
	end
	return nil
end

-- Hands ---------------------------------------------------------------------------------

-- A view angle eased toward another, as BotBrain's idle view is.
local function ease(from: number, to: number, dt: number, speed: number): number
	local d = BotBrain.wrap(to - from)
	local step = d * math.min(dt / P.lookEase.value, 1)
	local most = speed * dt
	return from + math.clamp(step, -most, most)
end

-- This tick's hands for cast `c`, at simulation time `t` (the tick's),
-- with the kit and the weapons as the last tick left them, the eye where
-- it is and the view as it was (yaw and pitch, radians).
function BotUtility.hands(
	c: Cast,
	kit: AbilitySim.State,
	weapons: WeaponSim.State,
	t: number,
	eye: vector,
	yaw: number,
	pitch: number,
	dt: number
): Hands
	if c.from < 0 then
		c.from, c.stepFrom = t, t
	end
	local id = c.ability
	local key = AbilitySim.BUTTONS[c.slot]
	-- The aim: at its target from the eye, else as found. Blade Storm,
	-- Empress and a heal on itself need none; a blast of Hunter's Fury
	-- charging turns the view slowly, as it turns a player's (system 46).
	local aims = not INSTANT[id] or id == "cloudburst"
	if id == "healingorb" and c.alt then
		aims = false
	end
	local target = if id == "huntersfury" then c.targets[c.blast] or c.target else c.target
	local wantYaw, wantPitch = c.yaw, c.pitch
	if target then
		wantYaw, wantPitch = BotBrain.anglesTo(eye, target)
	end
	local aimed = true
	if aims then
		local speed = math.rad(P.lookSpeed.value) * (if AbilitySim.charging(kit, t) then HF.turn.value else 1)
		yaw = ease(yaw, wantYaw, dt, speed)
		pitch = ease(pitch, wantPitch, dt, speed)
		aimed = math.sqrt(BotBrain.wrap(yaw - wantYaw) ^ 2 + (pitch - wantPitch) ^ 2) <= math.rad(U.aimed.value)
		if aimed then
			yaw, pitch = wantYaw, wantPitch
		end
	end
	local buttons = 0
	local was = c.pressed
	local function edge(button: number)
		if not bit32.btest(was, button) then
			buttons += button
		end
	end
	local inHand = kit.holding == c.slot
	local ready = inHand and weapons.equipped == WeaponSim.ULT and t >= weapons.equipEndTime - EPS
	local step: Step = c.step
	local done = false
	if step == "press" then
		-- Its key, once let go of a tick (a press is an edge); Cloudburst's
		-- throw goes on the press, so it's aimed first.
		if not bit32.btest(was, key) and (id ~= "cloudburst" or aimed) then
			buttons += key
			step = if INSTANT[id] then "after" elseif id == "huntersfury" then "fury" else "equip"
		end
	elseif step == "equip" then
		if inHand then
			if id == "barrierorb" and math.abs(BarrierSim.wrap(kit.turn - c.turn)) > 1e-3 then
				-- Its key again turns the targeter.
				edge(key)
			elseif ready then
				step = "send"
			end
		elseif t - c.stepFrom > GRACE then
			done = true
		end
	elseif step == "send" then
		if not inHand then
			-- Thrown, sent, loosed or healed: out of hand. A flare's thrower
			-- waits where it is, its view where it threw, until it's popped:
			-- it was thrown where its pop can't be seen from there.
			if id == "curveball" then
				step = "pop"
			else
				done = true
			end
		elseif id == "darkcover" then
			-- Its mark out to its reach (fire further, alt fire nearer), then
			-- its key again sends it.
			local want = SmokeSim.clamp(if target then vector.magnitude(target - eye) else kit.reach)
			local gap = want - kit.reach
			local move = DC.push.value * dt
			if gap > move then
				buttons += B.Fire
			elseif gap < -move then
				buttons += B.AltFire
			elseif aimed then
				edge(key)
			end
		elseif AbilitySim.bowed(id) then
			-- Its bounces, a press of alt fire each; then fire held from once
			-- it's aimed until the draw's filled its bars, and let go.
			if kit.bounces ~= c.bounces then
				edge(B.AltFire)
			elseif kit.drawFrom == 0 then
				if aimed then
					buttons += B.Fire
				end
			elseif AbilitySim.bars(kit, t) < c.bars then
				buttons += B.Fire
			end
		elseif id == "healingorb" then
			-- Tried a press at a time, until one heals or it's tried long enough.
			if aimed then
				edge(if c.alt then B.AltFire else B.Fire)
			end
			if t - c.stepFrom > U.healTry.value then
				done = true
			end
		elseif aimed then
			buttons += if c.alt then B.AltFire else B.Fire
		end
	elseif step == "fury" then
		-- Its bow drawn, a blast at each target in turn: fire, once the bow
		-- can, aimed; the view kept on it through the windup.
		-- A blast goes on the tick its windup ends, along that tick's view, so
		-- the next target waits for the tick after.
		local bow = weapons.equipped == WeaponSim.ULT and weapons.loadout[WeaponSim.ULT] ~= ""
		if kit.chargeAt > 0 then
			c.charging = true
		elseif c.charging then
			c.charging = false
			c.blast += 1
		end
		if kit.furyUntil == 0 and t - c.stepFrom > GRACE then
			done = true
		elseif not c.charging and c.blast > #c.targets then
			done = true
		elseif bow and not c.charging and aimed and t >= weapons.equipEndTime - EPS and t >= weapons.nextFireTime - EPS then
			edge(B.Fire)
		end
	elseif step == "pop" then
		done = t - c.stepFrom >= FlareSim.popTime(dt)
	elseif step == "after" then
		done = true
	end
	if t - c.from > c.longest then
		done = true
	end
	if step ~= c.step then
		c.step = step
		c.stepFrom = t
	end
	c.pressed = buttons
	return {
		buttons = buttons,
		-- Its gun comes back as a flare it threw flies.
		slot = if INSTANT[id] or step == "pop" then nil else WeaponSim.ULT,
		yaw = yaw,
		pitch = pitch,
		still = c.target == nil and aims,
		done = done,
	}
end

return BotUtility
