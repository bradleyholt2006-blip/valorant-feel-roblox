--!strict
-- Bots shooting an enemy's utility (system 76): a Recon Bolt, an Owl Drone
-- or Leer's eye noticed and fought as an enemy is, but only while no enemy
-- is; and broken, by skill, on a floor with the movement and the gun a
-- player has, each shot traced through the level with the utility in it
-- as the server traces it (docs/research/76-bots-shoot-utility.md).

local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local BoltSim = require("../src/shared/Abilities/BoltSim")
local DroneSim = require("../src/shared/Abilities/DroneSim")
local LeerSim = require("../src/shared/Abilities/LeerSim")
local BotBrain = require("../src/shared/Bots/BotBrain")
local BotConfig = require("../src/shared/Bots/BotConfig")
local Penetration = require("../src/shared/Combat/Penetration")
local Sight = require("../src/shared/Combat/Sight")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local FakeLevel = require("./FakeLevel")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check = H.check

local B = PlayerSim.Buttons
local P = BotConfig.Params
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local EYE = vector.create(0, 1.62, 0)
local SKILLS = BotConfig.SKILLS
local LE = AbilityConfig.Leer
local RC = AbilityConfig.ReconBolt
local DR = AbilityConfig.OwlDrone
local SIZES = {
	eye = LE.size.value,
	bolt = RC.width.value,
	drone = math.min(DR.width.value, DR.height.value),
}

-- Park-Miller dice, seeded, as the bots' tests have them.
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

-- A point `distance` metres off at eye height, `angle` radians round from
-- the middle of a view at yaw 0 (looking down -z).
local function pointAt(distance: number, angle: number): vector
	return EYE + vector.create(-distance * math.sin(angle), 0, -distance * math.cos(angle))
end

-- A piece of an enemy's utility there, `size` across, as the server shows
-- it a bot (BotServer.look): its middle its head and chest.
local function thing(id: number, at: vector, size: number, visible: boolean?): BotBrain.Target
	return { id = id, head = at, chest = at, velocity = vector.zero, visible = visible ~= false, size = size }
end

-- Someone `distance` metres off, `angle` round, standing still.
local function someone(id: number, distance: number, angle: number, visible: boolean?): BotBrain.Target
	local feet = vector.create(-distance * math.sin(angle), 0, -distance * math.cos(angle))
	local points = Sight.points({ position = feet, yaw = 0, crouchAlpha = 0 })
	return { id = id, head = points[1], chest = points[2], velocity = vector.zero, visible = visible ~= false }
end

-- A body standing at the eye with a full Vandal, at time `now`.
local function standing(now: number): BotBrain.Body
	return {
		now = now,
		eye = EYE,
		accurate = true,
		weapon = "vandal",
		category = "rifle",
		semi = false,
		interval = 0.1,
		recovery = 0.35,
		ammo = 25,
		magazine = 25,
		reloading = false,
		climb = 0,
		sidearm = true,
		equipped = 1,
	}
end

-- A bot's looks every lookEvery and ticks every tick from `from` for
-- `seconds`, at what `seen(t)` shows it then. What it fired at first and
-- when, and whom it's fighting at the end.
type Watch = { fired: number?, firedAt: number?, firedOff: number, target: number? }

local function watch(brain: BotBrain.Brain, from: number, seconds: number, seen: (number) -> { BotBrain.Target }): Watch
	local out: Watch = { fired = nil, firedAt = nil, firedOff = math.huge, target = nil }
	local t = from
	local nextLook = from
	while t < from + seconds do
		t += DT
		if t >= nextLook then
			BotBrain.look(brain, t, EYE, seen(t))
			nextLook += P.lookEvery.value
		end
		local act = BotBrain.tick(brain, standing(t), DT, nil, nil)
		if act.fire and out.fired == nil then
			out.fired = brain.target
			out.firedAt = t
			local k = if brain.target then brain.known[brain.target] else nil
			if k then
				local yaw, pitch = BotBrain.anglesTo(EYE, k.at)
				out.firedOff = math.sqrt(BotBrain.wrap(act.yaw - yaw) ^ 2 + (act.pitch - pitch) ^ 2)
			end
		end
	end
	out.target = brain.target
	return out
end

-- What it fights --------------------------------------------------------------------------

H.section("Bots shooting utility: what they fight (system 76)")

do
	-- An enemy's Leer eye 12 m off, 20 degrees round: noticed as an enemy
	-- is, then turned onto and shot at.
	local brain = BotBrain.new(BotConfig.Skills.normal, diceOf(5), 0)
	local at = pointAt(12, math.rad(20))
	local eye = thing(-1, at, SIZES.eye)
	local w = watch(brain, 0, 2, function()
		return { eye }
	end)
	local k = brain.known[-1]
	check("an enemy's Leer eye in view is noticed", k ~= nil and k.noticed and k.size == SIZES.eye)
	check(
		"and fought: it stands still, turns onto it and fires at it",
		w.fired == -1 and BotBrain.fighting(brain),
		string.format("first round at %.2f s", w.firedAt or math.huge)
	)
	check(
		"its first round no later than a person's would come: the reaction, the turn and its aim",
		(w.firedAt or math.huge) < 1.2,
		string.format("%.2f s", w.firedAt or math.huge)
	)
	local s = BotConfig.Skills.normal
	check(
		"with its view on it, off by no more than its wander just after the turn (three times its spread)",
		w.firedOff < math.rad(3 * s.trackError.value * s.turnError.value),
		string.format("%.2f degrees off its middle", math.deg(w.firedOff))
	)
	check("a piece of utility's never shot at the head", brain.head == false)
	check("nor is it somewhere an enemy was, to look into", BotBrain.lastSeen(brain, 2) == nil)

	-- Gone (broken): forgotten at once, and the fight with it over.
	watch(brain, 2, DT * 2, function()
		return {}
	end)
	check("broken, it's forgotten at once, and the fight's over", brain.known[-1] == nil and not BotBrain.fighting(brain))
end

do
	-- The turn onto a piece of utility takes the time Fitts's law gives for
	-- its size: longer onto a bolt than onto an eye in the same place.
	local function turnOnto(size: number): number
		local brain = BotBrain.new(BotConfig.Skills.normal, diceOf(3), 0)
		watch(brain, 0, 1, function()
			return { thing(-1, pointAt(12, math.rad(30)), size) }
		end)
		return brain.turnFor
	end
	local onBolt, onEye = turnOnto(SIZES.bolt), turnOnto(SIZES.eye)
	check(
		"the turn onto a piece of utility is timed for its size: a bolt's longer than an eye's",
		onBolt > onEye,
		string.format("%.3f s and %.3f s", onBolt, onEye)
	)

	-- A bolt and an enemy coming into view together: the enemy's fought,
	-- whichever's noticed first.
	local fought = 0
	for seed = 1, 6 do
		local brain = BotBrain.new(BotConfig.Skills.normal, diceOf(seed * 17 + 9), 0)
		local bolt = thing(-2, pointAt(6, math.rad(-10)), SIZES.bolt)
		local foe = someone(7, 15, math.rad(10))
		local w = watch(brain, 0, 1.5, function()
			return { bolt, foe }
		end)
		fought += if w.fired == 7 and w.target == 7 then 1 else 0
	end
	check(
		"an enemy and a bolt in view: the enemy's fought, though the bolt's nearer, every time",
		fought == 6,
		string.format("%d of 6", fought)
	)

	-- Shooting a drone when an enemy comes into view: the enemy, once noticed.
	local shooter = BotBrain.new(BotConfig.Skills.normal, diceOf(11), 0)
	local drone = thing(-3, pointAt(8, 0), SIZES.drone)
	watch(shooter, 0, 1.5, function()
		return { drone }
	end)
	check("shooting a drone", shooter.target == -3)
	local switched: number? = nil
	local t = 1.5
	local nextLook = t
	while t < 3.5 and switched == nil do
		t += DT
		if t >= nextLook then
			BotBrain.look(shooter, t, EYE, { drone, someone(8, 15, math.rad(25)) })
			nextLook += P.lookEvery.value
		end
		BotBrain.tick(shooter, standing(t), DT, nil, nil)
		if shooter.target == 8 then
			switched = t - 1.5
		end
	end
	local k = shooter.known[8]
	check(
		"an enemy coming into view takes over from it as soon as they're noticed",
		switched ~= nil and k ~= nil and k.noticed and math.abs((k.since :: number) + k.delay - (1.5 + switched)) <= P.lookEvery.value + DT,
		string.format("%.2f s on", switched or math.huge)
	)

	-- That enemy out of sight: its last place is watched a moment, as
	-- ever, before it goes back to the drone.
	local back: number? = nil
	local lost = t
	nextLook = t
	while t < lost + 2 and back == nil do
		t += DT
		if t >= nextLook then
			BotBrain.look(shooter, t, EYE, { drone, someone(8, 15, math.rad(25), false) })
			nextLook += P.lookEvery.value
		end
		BotBrain.tick(shooter, standing(t), DT, nil, nil)
		if shooter.target == -3 then
			back = t - lost
		end
	end
	check(
		"an enemy it's lost sight of keeps its aim off the drone for the moment it watches where they were",
		back ~= nil and back >= P.attackMemory.value - P.lookEvery.value,
		string.format("back on the drone %.2f s on", back or math.huge)
	)
end

-- Breaking it -------------------------------------------------------------------------------

H.section("Bots shooting utility: breaking it, by skill (system 76)")

local floor = FakeWorld.new():addFloor()
local base = FakeLevel.new()

local function climbOf(def: WeaponConfig.WeaponDef, w: WeaponSim.State, t: number): number
	local settled = t - w.lastShotTime > def.accuracy.recoveryTime.value
	return Accuracy.curve(def.recoil.pitch.points, if settled then 1 else w.sprayIndex + 1)
end

type Kind = "eye" | "bolt" | "drone"

-- A bot with a Vandal on a floor, facing down -z, and an enemy's piece of
-- utility `distance` metres off, `angle` round, at eye height, in view
-- from the start: Leer's eye open (its 2 s left), a Recon Bolt stuck in a
-- wall turned to it, or an Owl Drone hovering. Each round's traced
-- through the level with it in, as CombatServer traces it, and what
-- strikes it takes its damage off its health. Seconds until it's broken,
-- nil if it isn't in 4 s or its time runs out first; and the rounds fired.
local function breaks(skill: string, seed: number, kind: Kind, distance: number, angle: number): (number?, number)
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" }, seed)
	for k = 1, 40 do
		PlayerSim.step(sim, { seq = k, buttons = 0, yaw = 0, pitch = 0, slot = 1, viewTime = 0 }, cfg, floor, DT)
	end
	local dice = diceOf(seed * 7 + 3)
	local brain = BotBrain.new(BotConfig.Skills[skill], dice, 0)
	local t0 = (sim.movement.tick + 1) * DT
	local at = PlayerSim.eye(sim, cfg) + vector.create(-distance * math.sin(angle), 0, -distance * math.cos(angle))
	local health, ends
	local level: (number) -> Penetration.Level
	local function struck(key: any): boolean
		return false
	end
	if kind == "eye" then
		local e = LeerSim.cast(9, 1, t0 - LE.windup.value, at, vector.create(0, 0, -1), 0)
		health, ends = LE.health.value, LeerSim.ends(e)
		level = function(t: number): Penetration.Level
			return LeerSim.level(base, { e }, t)
		end
		struck = function(key: any): boolean
			return LeerSim.piece(key) ~= nil
		end
	elseif kind == "bolt" then
		local toward = vector.normalize(vector.create(-at.x, 0, -at.z))
		local s = BoltSim.stuck(9, 1, at - toward * (RC.length.value / 2), toward, t0 - RC.windup.value)
		health, ends = RC.health.value, BoltSim.ends(s)
		level = function(t: number): Penetration.Level
			return BoltSim.level(base, { s }, t)
		end
		struck = function(key: any): boolean
			return BoltSim.piece(key) ~= nil
		end
	else
		health, ends = DR.health.value, t0 + DR.duration.value
		level = function(): Penetration.Level
			return DroneSim.level(base, { { id = 1, position = at } }, nil)
		end
		struck = function(key: any): boolean
			return DroneSim.piece(key) ~= nil
		end
	end
	local target = thing(-1, at, SIZES[kind])
	local nextLook = t0 + dice() * P.lookEvery.value
	local fired = 0
	local seq = 40
	while true do
		local t = (sim.movement.tick + 1) * DT
		if t - t0 > 4 or t >= ends then
			return nil, fired
		end
		seq += 1
		local eye = PlayerSim.eye(sim, cfg)
		if t >= nextLook then
			BotBrain.look(brain, t, eye, { target })
			nextLook += P.lookEvery.value
		end
		local w = sim.weapons
		local def = WeaponSim.equippedDef(w)
		local mode = WeaponConfig.mode(def, w.scoped)
		local act = BotBrain.tick(brain, {
			now = t,
			eye = eye,
			accurate = PlayerSim.isAccurate(sim, cfg),
			weapon = def.id,
			category = def.category,
			semi = mode.fireMode == "semi",
			interval = mode.interval,
			recovery = def.accuracy.recoveryTime.value,
			ammo = w.ammo[w.equipped],
			magazine = def.magazine.value,
			reloading = WeaponSim.isReloading(w),
			climb = climbOf(def, w, t),
			sidearm = true,
			equipped = w.equipped,
		}, DT, nil, nil)
		local buttons = 0
		if act.dodge > 0 then
			buttons += B.Right
		elseif act.dodge < 0 then
			buttons += B.Left
		end
		if act.crouch then
			buttons += B.Crouch
		end
		if act.fire then
			buttons += B.Fire
		end
		if act.reload then
			buttons += B.Reload
		end
		local input = { seq = seq, buttons = buttons, yaw = act.yaw, pitch = act.pitch, slot = act.slot or w.equipped, viewTime = 0 }
		local shots = PlayerSim.step(sim, input, cfg, floor, DT)
		for _, shot in shots or {} do
			fired += 1
			local shotDef = WeaponConfig.get(shot.weapon)
			local trace = Penetration.trace(level(t), shot.origin, shot.direction, shotDef.penetration, WeaponConfig.MaxRange)
			local last = trace.walls[#trace.walls]
			if trace.stopped and last and last.exit == nil and struck(last.key) then
				local multiplier = Penetration.multiplierAt(trace, trace.stop)
				health -= Penetration.damage(WeaponConfig.damageAt(shotDef, "body", trace.stop), multiplier)
				if health <= 0 then
					return t - t0, fired
				end
			end
		end
	end
end

type Tally = { times: { number }, broken: number, runs: number, fired: number }

local function tally(skill: string, kind: Kind, distance: number, runs: number): Tally
	local out: Tally = { times = {}, broken = 0, runs = runs, fired = 0 }
	for run = 1, runs do
		local angle = math.rad(-25 + 50 * ((run * 7) % runs) / runs)
		local time, fired = breaks(skill, run * 131 + 29, kind, distance, angle)
		table.insert(out.times, time or math.huge)
		out.broken += if time then 1 else 0
		out.fired += fired
	end
	return out
end

local function median(xs: { number }): number
	local sorted = table.clone(xs)
	table.sort(sorted)
	return sorted[(#sorted + 1) // 2]
end

local RUNS = 12
local tallies: { [string]: { [string]: Tally } } = {}
for _, kind: Kind in { "eye", "bolt", "drone" } do
	tallies[kind] = {}
	for _, skill in SKILLS do
		tallies[kind][skill] = tally(skill, kind, 12, RUNS)
	end
end

-- How many of the runs broke it in time, and the median time, by skill.
local function summary(kind: Kind): string
	local rows = {}
	for _, skill in SKILLS do
		local t = tallies[kind][skill]
		table.insert(rows, string.format("%s %d/%d in %.2f s", skill, t.broken, t.runs, median(t.times)))
	end
	return table.concat(rows, ", ")
end

-- Whether the median time falls from Normal to Hard to Expert, with Easy's
-- no less than Normal's.
local function quicker(kind: Kind): boolean
	local t = tallies[kind]
	local easy, normal, hard, expert = median(t.easy.times), median(t.normal.times), median(t.hard.times), median(t.expert.times)
	return easy >= normal and normal > hard and hard > expert
end

local eye = tallies.eye
check(
	"an open Leer eye 12 m off: Hard and Expert break it before its 2 s are up every time",
	eye.hard.broken == RUNS and eye.expert.broken == RUNS,
	summary("eye")
)
check(
	"Normal nearly always, and Easy seldom, as players at the higher levels shoot it at once",
	eye.normal.broken >= RUNS - 2 and eye.easy.broken <= RUNS / 3
)
check("each skill quicker than the one below", quicker("eye"))
local bolt = tallies.bolt
check(
	"a Recon Bolt 12 m off, which a round breaks: Normal and up break it before its time's up nearly every time",
	bolt.normal.broken >= RUNS - 2 and bolt.hard.broken == RUNS and bolt.expert.broken == RUNS,
	summary("bolt")
)
check("each skill quicker than the one below", quicker("bolt"))
local drone = tallies.drone
check(
	"an Owl Drone hovering 12 m off: Normal and up break it inside 4 s every time",
	drone.normal.broken == RUNS and drone.hard.broken == RUNS and drone.expert.broken == RUNS,
	summary("drone")
)
check("each skill quicker than the one below", quicker("drone"))

return nil
