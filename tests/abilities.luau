--!strict
-- The ability kit (system 17): Jett's numbers and where they come from, the
-- kit's charges through rounds, halves, kills and deaths, buying charges,
-- Updraft and Tailwind as PlayerSim steps them (and movement under them),
-- and the wire carrying the kit.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local MovementSim = require("../src/shared/Movement/MovementSim")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local Shop = require("../src/shared/Weapons/Shop")
local Spike = require("../src/shared/Spike/Spike")
local SpikeSim = require("../src/shared/Spike/SpikeSim")
local JumpAnalyzer = require("../src/shared/Movement/JumpAnalyzer")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local J = AbilityConfig.Jett
local C, Q, E, X = AbilityConfig.C, AbilityConfig.Q, AbilityConfig.E, AbilityConfig.X

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function horizontal(v: vector): number
	return math.sqrt(v.x * v.x + v.z * v.z)
end

local function input(buttons: number, yaw: number?, slot: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = 0, viewTime = 0 }
end

-- A player settled on the floor with the Vandal in hand and a full kit.
local function newPlayer(): PlayerSim.State
	local s = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	AbilitySim.fill(s.abilities)
	for _ = 1, 40 do
		PlayerSim.step(s, input(0), cfg, floor, DT)
	end
	return s
end

-- One tick; returns its bullets' count and its casts.
local function step(s: PlayerSim.State, buttons: number, yaw: number?, world: any?): (number, { AbilitySim.Cast })
	local shots, _, _, _, casts = PlayerSim.step(s, input(buttons, yaw), cfg, world or floor, DT)
	return if shots then #shots else 0, casts or {}
end

-- Steps `n` ticks holding `buttons`; returns the bullets fired and the casts.
local function run(s: PlayerSim.State, buttons: number, n: number, yaw: number?): (number, { AbilitySim.Cast })
	local bullets, all = 0, {}
	for _ = 1, n do
		local fired, casts = step(s, buttons, yaw)
		bullets += fired
		for _, cast in casts do
			table.insert(all, cast)
		end
	end
	return bullets, all
end

-- The time of the tick about to run.
local function nextTime(s: PlayerSim.State): number
	return (s.movement.tick + 1) * DT
end

-- Readies Tailwind with a tap of E and waits out the windup.
local function readied(s: PlayerSim.State): AbilitySim.Cast?
	local _, casts = step(s, B.AbilityE)
	run(s, 0, ticks(J.windup.value) + 1)
	return casts[1]
end

H.section("Ability tests")

-- The kit and its numbers ----------------------------------------------------

do
	local jett = AbilityConfig.Agents.jett
	check(
		"Jett's kit: Cloudburst on C, Updraft on Q, Tailwind on E, Blade Storm on X",
		jett.abilities[C] == "cloudburst"
			and jett.abilities[Q] == "updraft"
			and jett.abilities[E] == "tailwind"
			and jett.abilities[X] == "bladestorm"
	)
	check("the keys are the reference's defaults, in the bar's order", table.concat(AbilityConfig.KEYS, "") == "CQEX")
	local d = AbilityConfig.Defs
	check(
		"each ability sits in its own slot, of its kind",
		d.cloudburst.slot == C
			and d.updraft.slot == Q
			and d.tailwind.slot == E
			and d.bladestorm.slot == X
			and d.cloudburst.kind == "basic"
			and d.updraft.kind == "basic"
			and d.tailwind.kind == "signature"
			and d.bladestorm.kind == "ultimate"
	)
	check(
		"prices from Riot's patch notes: Cloudburst 200, Updraft 150 a charge",
		d.cloudburst.cost ~= nil
			and d.cloudburst.cost.value == 200
			and d.cloudburst.cost.status == "confirmed"
			and d.updraft.cost ~= nil
			and d.updraft.cost.value == 150
			and d.updraft.cost.status == "confirmed"
	)
	check(
		"Tailwind is free, a charge a round, and back after two kills",
		d.tailwind.cost == nil and d.tailwind.free == 1 and d.tailwind.recharge ~= nil
	)
	local recharge = d.tailwind.recharge
	check(
		"its two kills are Riot's",
		recharge ~= nil and recharge.kind == "kills" and recharge.kills.value == 2 and recharge.kills.status == "confirmed"
	)
	check(
		"Blade Storm needs 8 points (Patch 7.04)",
		d.bladestorm.points ~= nil and d.bladestorm.points.value == 8 and d.bladestorm.points.status == "confirmed"
	)
	check(
		"Tailwind's windup is 1 s and its window 7.5 s (Patch 7.04)",
		J.windup.value == 1 and J.window.value == 7.5 and J.windup.status == "confirmed"
	)
	local labelled = true
	local function label(param: any)
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	for _, def in d do
		for _, key in { "cost", "charges", "points" } do
			local param = (def :: any)[key]
			if param then
				label(param)
			end
		end
	end
	for _, param in J do
		label(param)
	end
	for _, param in AbilityConfig.Points do
		label(param)
	end
	check("every number says where it's from", labelled)
end

-- The kit through a match --------------------------------------------------------

do
	local k = AbilitySim.new()
	check(
		"a new kit: Tailwind's free charge and nothing else",
		k.charges[C] == 0 and k.charges[Q] == 0 and k.charges[E] == 1 and k.points == 0
	)
	check(
		"Updraft holds one, Cloudburst two",
		AbilitySim.maxCharges(k, Q) == 1 and AbilitySim.maxCharges(k, C) == 2 and AbilitySim.maxCharges(k, X) == 0
	)

	check("a charge of Updraft can be bought", AbilitySim.buy(k, "updraft") and k.charges[Q] == 1)
	check("but not a second: it holds one", not AbilitySim.canBuy(k, "updraft") and not AbilitySim.buy(k, "updraft") and k.charges[Q] == 1)
	check(
		"Cloudburst is sold a charge at a time, up to two",
		AbilitySim.buy(k, "cloudburst") and AbilitySim.buy(k, "cloudburst") and k.charges[C] == 2
	)
	check("but not a third", not AbilitySim.canBuy(k, "cloudburst") and not AbilitySim.buy(k, "cloudburst") and k.charges[C] == 2)
	check("and both sell back", AbilitySim.sell(k, "cloudburst") and AbilitySim.sell(k, "cloudburst") and k.charges[C] == 0)
	check(
		"Tailwind and Blade Storm aren't sold",
		not AbilitySim.buy(k, "tailwind") and not AbilitySim.buy(k, "bladestorm") and k.charges[E] == 1
	)
	check("nor is what isn't in the kit", not AbilitySim.buy(k, "vandal"))
	check("a charge sells back", AbilitySim.sell(k, "updraft") and k.charges[Q] == 0)
	check("and none is left to sell", not AbilitySim.sell(k, "updraft") and not AbilitySim.sell(k, "bladestorm"))

	AbilitySim.buy(k, "updraft")
	AbilitySim.newRound(k)
	check("an unused charge carries into the next round", k.charges[Q] == 1 and k.charges[E] == 1)
	k.charges[E] = 0
	AbilitySim.newRound(k)
	check("each round gives Tailwind its free charge back", k.charges[E] == 1)

	AbilitySim.killed(k)
	check("a kill is an ultimate point", k.points == 1)
	check("with Tailwind's charge there, kills don't count towards another", k.kills == 0 and k.charges[E] == 1)
	k.charges[E] = 0
	AbilitySim.killed(k)
	check("with it spent, a kill counts towards it", k.kills == 1 and k.charges[E] == 0 and k.points == 2)
	AbilitySim.killed(k)
	check("and a second brings it back", k.kills == 0 and k.charges[E] == 1 and k.regained == 1 and k.points == 3)

	AbilitySim.died(k)
	check("a death is a point, and charges are kept through it", k.points == 4 and k.charges[Q] == 1 and k.charges[E] == 1)
	for _ = 1, 10 do
		AbilitySim.killed(k)
	end
	check("points stop at what Blade Storm needs", k.points == 8)

	AbilitySim.newHalf(k)
	check("a new half takes what was bought, and gives Tailwind's charge", k.charges[Q] == 0 and k.charges[C] == 0 and k.charges[E] == 1)
	check("but keeps the points", k.points == 8)
	AbilitySim.reset(k)
	check("a new match keeps nothing", k.points == 0 and k.charges[Q] == 0 and k.charges[E] == 1)

	AbilitySim.fill(k)
	check(
		"the course and Skirmish fill every charge that can be played",
		k.charges[Q] == 1 and k.charges[E] == 1 and k.charges[C] == 2 and AbilitySim.full(k)
	)
	check("the kit in a few characters", AbilitySim.summary(k, 0) == "C2/2 Q1/1 E1/1 X0/8", AbilitySim.summary(k, 0))
end

do
	-- A signature that holds two, one free (none of Jett's: a stand-in): what
	-- kills bring back goes at the round's end; the free one stays.
	AbilityConfig.Defs.testGust = {
		id = "testGust",
		name = "Test Gust",
		slot = E,
		kind = "signature",
		charges = { value = 2, status = "estimate", source = "test" },
		free = 1,
		recharge = { kind = "kills", kills = { value = 2, status = "estimate", source = "test" } },
		description = "",
	}
	AbilityConfig.Agents.testAgent = { id = "testAgent", name = "Test", abilities = { "cloudburst", "updraft", "testGust", "bladestorm" } }
	local k = AbilitySim.new("testAgent")
	AbilitySim.killed(k)
	AbilitySim.killed(k)
	check("a signature short of its most comes back with kills", k.charges[E] == 2 and k.regained == 1)
	AbilitySim.newRound(k)
	check("and what kills brought back is taken back at the round's end", k.charges[E] == 1 and k.regained == 0)
	AbilityConfig.Defs.testGust = nil :: any
	AbilityConfig.Agents.testAgent = nil :: any
end

-- Movement under an ability ---------------------------------------------------------

do
	local function settled(): MovementSim.State
		local m = MovementSim.newState(vector.create(0, 0.02, 0))
		for _ = 1, 16 do
			MovementSim.step(m, input(0), cfg, cfg.baseRunSpeed, floor, DT)
		end
		return m
	end
	local m = settled()
	local before = m.position
	MovementSim.step(m, input(B.Back), cfg, cfg.baseRunSpeed, floor, DT, { dash = vector.create(10, 0, 0) })
	check(
		"a dash moves at its own velocity, whatever the keys",
		near(m.position.x - before.x, 10 * DT, 1e-9) and near(m.position.z, before.z, 1e-9) and m.grounded
	)
	m = settled()
	MovementSim.step(m, input(0), cfg, cfg.baseRunSpeed, floor, DT, { lift = 5 })
	check("a lift takes you off the ground at its speed, with no gravity", not m.grounded and near(m.velocity.y, 5, 1e-9))
	MovementSim.step(m, input(0), cfg, cfg.baseRunSpeed, floor, DT)
	check("and after it, gravity again", near(m.velocity.y, 5 - cfg.gravity * DT, 1e-9))
	m = settled()
	m.velocity = vector.create(12, 0, 0)
	MovementSim.step(m, input(B.Forward), cfg, cfg.baseRunSpeed, floor, DT, { cap = 6.75 })
	check("a cap holds the speed along the ground to it before the tick", horizontal(m.velocity) <= 6.75 + 1e-9)
end

-- Updraft -------------------------------------------------------------------------------

do
	local s = newPlayer()
	local start = s.movement.position.y
	-- The HUD's jump line (F3) measures it too.
	local analyzer = JumpAnalyzer.new()
	local function measure(): JumpAnalyzer.Jump?
		local m = s.movement
		return JumpAnalyzer.tick(analyzer, m.tick * DT, m.position, m.velocity, m.grounded, 0)
	end
	measure()
	local _, casts = step(s, B.AbilityQ)
	measure()
	check("Q casts Updraft", #casts == 1 and casts[1].ability == "updraft" and casts[1].kind == "lift")
	check("spending its charge", s.abilities.charges[Q] == 0)
	check("and lifts you off the ground at once", not s.movement.grounded and s.movement.position.y > start)
	local top, airborne, jump = start, 0, nil
	for _ = 1, ticks(4) do
		step(s, 0)
		jump = measure() or jump
		top = math.max(top, s.movement.position.y)
		if not s.movement.grounded then
			airborne += 1
		end
	end
	check("the feet top out at its apex", near(top - start, J.updraftApex.value, 0.01), string.format("%.3f m", top - start))
	check("and come back down", s.movement.grounded and near(s.movement.position.y, start, 0.01))
	check("up for as long as the speed says", AbilitySim.ticks(J.updraftTime.value, DT) == 77 and airborne > 77)
	check(
		"the HUD's jump line reads its rise, and about 1.68 s in the air",
		jump ~= nil and near(jump.rise, J.updraftApex.value, 0.01) and near(jump.airtime, 1.68, 0.02),
		if jump then string.format("rise %.3f m, %.3f s", jump.rise, jump.airtime) else "never landed"
	)
	local _, again = step(s, B.AbilityQ)
	check("Q with no charge does nothing", #again == 0 and s.movement.grounded)

	AbilitySim.fill(s.abilities)
	step(s, B.Jump)
	run(s, 0, ticks(0.15))
	local from = s.movement.position.y
	local _, mid = step(s, B.AbilityQ)
	check("it works in the air, lifting from there", #mid == 1 and s.movement.velocity.y > 0 and s.movement.position.y > from)

	AbilitySim.fill(s.abilities)
	run(s, 0, ticks(3))
	local _, held = run(s, B.AbilityQ, 20)
	check("holding Q casts it once", #held == 1)
end

-- Tailwind --------------------------------------------------------------------------------

do
	local s = newPlayer()
	local ready = readied(s)
	check("E readies Tailwind", ready ~= nil and ready.ability == "tailwind" and ready.kind == "ready")
	check("spending its charge", s.abilities.charges[E] == 0)
	check("and opens its window after the windup", AbilitySim.ready(s.abilities, nextTime(s)))

	local before = s.movement.position
	local _, casts = step(s, B.AbilityE)
	check("E again dashes", #casts == 1 and casts[1].kind == "dash")
	local dashTicks = 1
	while AbilitySim.dashing(s.abilities, nextTime(s)) and dashTicks < 200 do
		step(s, 0)
		dashTicks += 1
	end
	local moved = s.movement.position - before
	check("for its time", dashTicks == AbilitySim.ticks(J.dashTime.value, DT), tostring(dashTicks))
	check(
		"forward with no keys, its distance, level",
		near(moved.z, -J.dashDistance.value, 0.01) and near(moved.x, 0, 1e-6) and near(moved.y, 0, 0.01),
		string.format("%.3f, %.3f, %.3f", moved.x, moved.y, moved.z)
	)
	step(s, 0)
	check(
		"and as it ends you keep no more than the run speed",
		horizontal(s.movement.velocity) <= cfg.baseRunSpeed * J.dashExit.value + 1e-6
	)
	check("the window has closed", not AbilitySim.ready(s.abilities, nextTime(s)) and s.abilities.readyUntil == 0)
	local _, again = step(s, B.AbilityE)
	check("and E does nothing with the charge spent", #again == 0)
end

do
	-- Pressed during the windup, E doesn't dash; the window opens anyway.
	local s = newPlayer()
	step(s, B.AbilityE)
	run(s, 0, ticks(0.4))
	local _, early = step(s, B.AbilityE)
	check("E during the windup does nothing", #early == 0 and not AbilitySim.dashing(s.abilities, nextTime(s)))
	run(s, 0, ticks(J.windup.value))
	check("the window still opens", AbilitySim.ready(s.abilities, nextTime(s)))
	run(s, 0, ticks(J.window.value))
	check("and closes unused after its 7.5 s", not AbilitySim.ready(s.abilities, nextTime(s)) and s.abilities.readyUntil == 0)
	local _, late = step(s, B.AbilityE)
	check("taking the charge with it", #late == 0 and s.abilities.charges[E] == 0)
end

do
	local s = newPlayer()
	readied(s)
	local before = s.movement.position
	step(s, B.AbilityE + B.Right)
	run(s, B.Right, AbilitySim.ticks(J.dashTime.value, DT) - 1)
	local moved = s.movement.position - before
	check(
		"the dash goes the way the keys say",
		near(moved.x, J.dashDistance.value, 0.01) and near(moved.z, 0, 1e-6),
		string.format("%.3f, %.3f", moved.x, moved.z)
	)
end

do
	-- Nothing fires during it, and a held trigger fires after.
	local s = newPlayer()
	readied(s)
	local _, casts = step(s, B.AbilityE + B.Fire)
	local during = run(s, B.Fire, AbilitySim.ticks(J.dashTime.value, DT) - 1)
	check("nothing fires during a dash", #casts == 1 and during == 0)
	local after = run(s, B.Fire, ticks(0.3))
	check("and a held trigger fires once it's over", after > 0)
end

do
	-- A dash ends a lift, and flies level in the air.
	local s = newPlayer()
	readied(s)
	step(s, B.AbilityQ)
	run(s, 0, ticks(0.2))
	check("lifting", AbilitySim.lifting(s.abilities, nextTime(s)) and s.movement.velocity.y > 0)
	local y = s.movement.position.y
	local _, casts = step(s, B.AbilityE)
	check("a dash ends the lift", #casts == 1 and s.abilities.liftUntil == 0 and s.movement.velocity.y == 0)
	local level = true
	s.abilities.charges[Q] = 1
	local _, qs = run(s, B.AbilityQ, 10)
	for _ = 1, 20 do
		step(s, 0)
		if AbilitySim.dashing(s.abilities, s.movement.tick * DT) then
			level = level and near(s.movement.position.y, y, 1e-9)
		end
	end
	check("and flies level through the air", level and s.movement.position.y > 1)
	check("nothing casts during a dash", #qs == 0 and s.abilities.charges[Q] == 1)
end

do
	-- Nor does a plant start in one.
	local site = Spike.CourseSites[1]
	local s = PlayerSim.new(vector.create(site.center.x, 0.02, site.center.z), { "vandal", "classic", "knife", "spike" })
	AbilitySim.fill(s.abilities)
	local ctx: Spike.Context = { zones = Spike.CourseSites, canPlant = true, canDefuse = false, planted = nil, halfSaved = false }
	local function tick(buttons: number)
		PlayerSim.step(s, input(buttons, 0, 4), cfg, floor, DT, ctx)
	end
	for _ = 1, ticks(1.5) do
		tick(0)
	end
	tick(B.AbilityE)
	for _ = 1, ticks(J.windup.value) + 1 do
		tick(0)
	end
	tick(B.AbilityE)
	local planting = false
	for _ = 2, AbilitySim.ticks(J.dashTime.value, DT) do
		tick(B.Use)
		planting = planting or s.spike.channel ~= SpikeSim.NONE
	end
	check("a plant doesn't start in a dash", AbilitySim.dashing(s.abilities, s.movement.tick * DT) and not planting)

	-- Started on the same tick, the plant goes first and roots: no dash.
	s = PlayerSim.new(vector.create(site.center.x, 0.02, site.center.z), { "vandal", "classic", "knife", "spike" })
	AbilitySim.fill(s.abilities)
	for _ = 1, ticks(1.5) do
		tick(0)
	end
	tick(B.AbilityE)
	for _ = 1, ticks(J.windup.value) + 1 do
		tick(0)
	end
	local _, _, _, _, casts = PlayerSim.step(s, input(B.AbilityE + B.Use, 0, 4), cfg, floor, DT, ctx)
	check("pressed with the dash, the plant goes first", casts == nil and s.spike.channel == SpikeSim.PLANTING)
end

do
	-- A dash takes the zoom off.
	local s = PlayerSim.new(vector.create(0, 0.02, 0), { "operator", "classic", "knife", "" })
	AbilitySim.fill(s.abilities)
	run(s, 0, ticks(1.5))
	step(s, B.AltFire)
	run(s, 0, 2)
	check("zoomed in", s.weapons.scoped == 1)
	readied(s)
	step(s, B.AbilityE)
	check("a dash takes the zoom off", s.weapons.scoped == 0)
end

do
	-- Rooted by a plant or a defuse, nothing casts.
	local k = AbilitySim.new()
	AbilitySim.fill(k)
	local feet, eye = vector.create(0, 0, 0), vector.create(0, 1.62, 0)
	local motion, casts = AbilitySim.step(k, input(B.AbilityQ), 1, DT, 128, feet, eye, true, cfg)
	check("nothing casts while a plant or a defuse roots you", casts == nil and motion.lift == nil and k.charges[Q] == 1)
	local _, after = AbilitySim.step(k, input(B.AbilityQ), 1 + DT, DT, 129, feet, eye, false, cfg)
	check("and a key held through it doesn't cast as it ends", after == nil)
end

-- The wire --------------------------------------------------------------------------------

do
	local inputs = {
		{ seq = 1, buttons = B.Ultimate + B.AbilityC + B.Forward, slot = 1, yaw = 0, pitch = 0, viewTime = 0 },
		{ seq = 2, buttons = 65535, slot = 2, yaw = 0, pitch = 0, viewTime = 0 },
	}
	local decoded = PlayerCodec.decodeInputs(PlayerCodec.encodeInputs(inputs, 1, 2))
	check(
		"every button gets to the server, the abilities' too",
		decoded ~= nil and decoded[1].buttons == B.Ultimate + B.AbilityC + B.Forward and decoded[2].buttons == 65535
	)

	local function same(a: AbilitySim.State, b: AbilitySim.State): boolean
		for slot = 1, AbilityConfig.SLOTS do
			if a.charges[slot] ~= b.charges[slot] or a.owned[slot] ~= b.owned[slot] then
				return false
			end
		end
		return a.agent == b.agent
			and a.regained == b.regained
			and a.kills == b.kills
			and a.points == b.points
			and a.need == b.need
			and a.held == b.held
			and a.readyFrom == b.readyFrom
			and a.readyUntil == b.readyUntil
			and a.liftUntil == b.liftUntil
			and a.dashUntil == b.dashUntil
			and a.dashX == b.dashX
			and a.dashZ == b.dashZ
			and a.storm == b.storm
			and a.holding == b.holding
	end

	local s = newPlayer()
	AbilitySim.killed(s.abilities)
	AbilitySim.killed(s.abilities)
	readied(s)
	step(s, B.AbilityQ)
	run(s, B.AbilityQ, 5)
	local _, decoded2 = PlayerCodec.decodeAck(PlayerCodec.encodeAck(5, s))
	check(
		"the ack carries the kit exactly, a window and a lift under way",
		same(decoded2.abilities, s.abilities) and decoded2.abilities.held ~= 0
	)

	step(s, B.AbilityE + B.Left)
	run(s, B.Left, 10)
	local _, mid = PlayerCodec.decodeAck(PlayerCodec.encodeAck(6, s))
	check("and a dash under way", same(mid.abilities, s.abilities) and AbilitySim.dashing(mid.abilities, nextTime(s)))
	local a, b = s, mid :: PlayerSim.State
	AbilitySim.fill(a.abilities)
	AbilitySim.fill(b.abilities)
	local identical = true
	for i = 1, 200 do
		local buttons = if i % 50 == 1 then B.AbilityQ else B.Forward
		step(a, buttons, i * 0.01)
		step(b, buttons, i * 0.01)
		identical = identical and a.movement.position == b.movement.position and a.movement.velocity == b.movement.velocity
	end
	check(
		"and a replay from it moves bit for bit, through another lift",
		identical and same(a.abilities, b.abilities) and a.abilities.charges[Q] == 0
	)
end

-- The shop ------------------------------------------------------------------------------------

do
	local updraft = Shop.item("updraft")
	check(
		"Updraft is on sale a charge at a time, on its key",
		updraft ~= nil and updraft.kind == "ability" and updraft.price == 150 and updraft.slot == "Q"
	)
	check("Tailwind and Blade Storm aren't on sale", Shop.item("tailwind") == nil and Shop.item("bladestorm") == nil)
	local cloudburst = Shop.item("cloudburst")
	local shop = Shop.new()
	if updraft and cloudburst then
		check("a charge costs its price", Shop.cost(shop, updraft) == 150 and Shop.cost(shop, cloudburst) == 200)
		check(
			"and there's nothing to sell back before one's bought",
			Shop.refund(shop, updraft) == 0 and not Shop.sellCharge(shop, updraft)
		)
		Shop.buyCharge(shop, cloudburst)
		Shop.buyCharge(shop, updraft)
		Shop.buyCharge(shop, cloudburst)
		check("one bought sells back for its price", Shop.refund(shop, updraft) == 150 and Shop.refund(shop, cloudburst) == 200)
		local list = table.concat(Shop.chargeList(shop), ",")
		check("the charges bought, C's first, for the buy menu", list == "cloudburst,cloudburst,updraft", list)
		local back = Shop.chargesFrom(list)
		check("and read back", back.cloudburst == 2 and back.updraft == 1)
		check("selling one back", Shop.sellCharge(shop, cloudburst) and shop.charges.cloudburst == 1)
		Shop.reset(shop)
		check("a new buy phase forgets them", Shop.refund(shop, cloudburst) == 0 and #Shop.chargeList(shop) == 0)
	end
	check("an empty list reads as none", next(Shop.chargesFrom("")) == nil and next(Shop.chargesFrom(nil)) == nil)
end

-- Team Deathmatch's kit (system 28) ---------------------------------------------------

do
	local TDM = AbilityConfig.TeamDeathmatch
	check(
		"Team Deathmatch's ultimate points: 3 a kill, 10 an Ultimate Orb, none a death; Blade Storm 60",
		TDM.kill.value == 3
			and TDM.orb.value == 10
			and TDM.death.value == 0
			and TDM.ultimate.bladestorm.value == 60
			and TDM.kill.status == "community"
			and TDM.death.status == "estimate"
	)
	check(
		"and Jett's cooldowns, the wiki's: Cloudburst 29 s, Updraft and Tailwind 44",
		TDM.cooldowns.cloudburst.value == 29
			and TDM.cooldowns.updraft.value == 44
			and TDM.cooldowns.tailwind.value == 44
			and TDM.headStart.value == 0.5
			and TDM.signatureStart.value == 1
	)
	local k = AbilitySim.new()
	k.need = TDM.ultimate.bladestorm.value
	check("a mode's own cost is what the ultimate needs", AbilitySim.pointsNeeded(k) == 60)
	AbilitySim.killed(k, TDM.kill.value)
	AbilitySim.died(k, TDM.death.value)
	check("its points for a kill and a death", k.points == 3)
	for _ = 1, 30 do
		AbilitySim.killed(k, TDM.kill.value)
	end
	check("up to the cost, and no further", k.points == 60 and AbilitySim.charged(k))
	check("the kit in a few characters says so", AbilitySim.summary(k, 0) == "C0/2 Q0/1 E1/1 X60/60", AbilitySim.summary(k, 0))
	local p = newPlayer()
	p.abilities.need = 60
	p.abilities.points = 59
	local _, back = PlayerCodec.decodeAck(PlayerCodec.encodeAck(11, p))
	check("the ack carries it", back.abilities.need == 60 and back.abilities.points == 59 and not AbilitySim.charged(back.abilities))
	local none = AbilitySim.new(AbilityConfig.NO_AGENT)
	none.need = 60
	check("but a kit with no ultimate needs nothing", AbilitySim.pointsNeeded(none) == 0)
end

return nil
