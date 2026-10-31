--!strict
-- Reyna (system 73): her kit and her numbers and where they come from, her
-- Soul Orbs (who earns one, which is in her reach, the wire), her Devour
-- (Q taking the orb in reach with a charge, and nothing without either, its
-- heal over its time, past full health up to the overheal's, which nothing
-- else that heals takes away, until its time's up) and her Dismiss (E taking it: no firing,
-- casting or planting through its time, a top speed of its own, the gun
-- drawn again as it ends, a death ending it, and the wire carrying it so a
-- replay comes back the same), and Basic Training with her kit.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local AgentSelect = require("../src/shared/Abilities/AgentSelect")
local SoulSim = require("../src/shared/Abilities/SoulSim")
local Health = require("../src/shared/Combat/Health")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Spike = require("../src/shared/Spike/Spike")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local TrainingConfig = require("../src/shared/Training/TrainingConfig")
local TrainingRules = require("../src/shared/Training/TrainingRules")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local RY = AbilityConfig.Reyna
local Q, E = AbilityConfig.Q, AbilityConfig.E
local FEET = vector.create(0, 0.02, 0)

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = 0, pitch = 0, viewTime = 0 }
end

-- An objective with the Soul Orb numbered `soul` in reach.
local function soulful(soul: number?): Spike.Context
	local o = table.clone(Spike.NONE)
	o.soul = soul
	return o
end

-- One tick with `buttons` held and `soul` in reach: its bullets and casts.
local function step(sim: PlayerSim.State, buttons: number, soul: number?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	local shots, _, _, _, casts = PlayerSim.step(sim, input(buttons), cfg, floor, DT, soulful(soul))
	return shots or {}, casts or {}
end

local function run(sim: PlayerSim.State, buttons: number, n: number): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	local shots, casts = {}, {}
	for _ = 1, n do
		local s, c = step(sim, buttons)
		table.move(s, 1, #s, #shots + 1, shots)
		table.move(c, 1, #c, #casts + 1, casts)
	end
	return shots, casts
end

local function ofKind(casts: { AbilitySim.Cast }, kind: string): { AbilitySim.Cast }
	local out = {}
	for _, cast in casts do
		if cast.kind == kind then
			table.insert(out, cast)
		end
	end
	return out
end

local function now(sim: PlayerSim.State): number
	return sim.movement.tick * DT
end

local function speed(sim: PlayerSim.State): number
	local v = sim.movement.velocity
	return math.sqrt(v.x * v.x + v.z * v.z)
end

-- Reyna settled on the floor, the Vandal drawn and her charges full.
local function newReyna(): PlayerSim.State
	local sim = PlayerSim.new(FEET, { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new("reyna")
	AbilitySim.fill(sim.abilities)
	run(sim, 0, ticks(1.5))
	return sim
end

H.section("Reyna tests")

-- Her kit and her numbers ---------------------------------------------------------------------

do
	local agent = AbilityConfig.Agents.reyna
	check(
		"Reyna: a Duelist, with Leer, Devour, Dismiss and Empress on C, Q, E and X",
		agent.role == "Duelist" and table.concat(agent.abilities, ",") == "leer,devour,dismiss,empress"
	)
	check(
		"the sixth agent on the wire",
		AbilityConfig.AgentIds[6] == "reyna" and AbilityConfig.AgentIndex.reyna == 6 and #AbilityConfig.AgentIds == 6
	)
	check("and in agent select", table.find(AgentSelect.pickable(), "reyna") ~= nil)
	check(
		"Devour and Dismiss can be played, Leer and Empress not yet",
		AbilitySim.playable("devour")
			and AbilitySim.playable("dismiss")
			and not AbilitySim.playable("leer")
			and not AbilitySim.playable("empress")
	)
	local D, M, L, X = AbilityConfig.Defs.devour, AbilityConfig.Defs.dismiss, AbilityConfig.Defs.leer, AbilityConfig.Defs.empress
	local costs = D.cost and M.cost and L.cost
	check(
		"Devour and Dismiss: 200 credits, 2 charges each (Patch 2.03)",
		costs ~= nil
			and (D.cost :: any).value == 200
			and (M.cost :: any).value == 200
			and (D.charges :: any).value == 2
			and (M.charges :: any).value == 2
			and (D.cost :: any).status == "confirmed"
			and (D.charges :: any).status == "confirmed"
	)
	check(
		"Leer: 250 credits, 2 charges; Empress: 7 points (Patch 12.02)",
		(L.cost :: any).value == 250 and (X.points :: any).value == 7 and (X.points :: any).status == "confirmed"
	)
	check(
		"Soul Orbs last 3 s (Patch 12.02), and her damage counts for one 3 s before a death (Patch 2.03)",
		RY.orbLife.value == 3 and RY.orbLife.status == "confirmed" and RY.damaged.value == 3 and RY.damaged.status == "confirmed"
	)
	check(
		"Devour heals 50 over 2 s (Patch 8.11), up to 150, for 10 s (Patch 12.02)",
		RY.heal.value == 50
			and RY.healTime.value == 2
			and RY.heal.status == "confirmed"
			and RY.overheal.value == 150
			and RY.overhealTime.value == 10
			and RY.overhealTime.status == "confirmed"
	)
	check(
		"Dismiss: 1.5 s at a top speed of 12 m/s (Patch 8.11)",
		RY.dismissTime.value == 1.5 and RY.dismissSpeed.value == 12 and RY.dismissSpeed.status == "confirmed"
	)
	check("her reach and the orb's height are ours", RY.reach.status == "estimate" and RY.height.status == "estimate")
	local kit = AbilitySim.new("reyna")
	check(
		"both bought by the charge",
		AbilitySim.canBuy(kit, "devour") and AbilitySim.canBuy(kit, "dismiss") and not AbilitySim.canBuy(kit, "leer")
	)
	check("no free charge each round", kit.charges[E] == 0)
end

-- Her Soul Orbs -------------------------------------------------------------------------------

do
	check("a kill earns her one", SoulSim.earns(true, nil, 10))
	check("so does a death 2.9 s or 3 s after she last hurt them", SoulSim.earns(false, 7.1, 10) and SoulSim.earns(false, 7, 10))
	check("but not 3.1 s after, nor without her ever hurting them", not SoulSim.earns(false, 6.9, 10) and not SoulSim.earns(false, nil, 10))

	local orb = SoulSim.orb(4, vector.create(1.23456, 0.02, -3.98765), 12.34567)
	check(
		"kept to the centimetre and its end to the millisecond",
		orb.at == vector.create(1.23, 0.02, -3.99) and orb.ends == 15.346,
		tostring(orb.ends)
	)
	local two = { orb, SoulSim.orb(5, vector.create(-2, 0, 7.5), 20) }
	local back = SoulSim.decode(SoulSim.encode(two))
	check(
		"the wire carries them exactly",
		#back == 2 and back[1].id == 4 and back[1].at == two[1].at and back[1].ends == two[1].ends and back[2].at == two[2].at,
		SoulSim.encode(two)
	)
	check("and reads nothing from nothing", #SoulSim.decode(nil) == 0 and #SoulSim.decode("") == 0 and #SoulSim.decode("x,y") == 0)

	local always = function(): boolean
		return true
	end
	local eye = vector.create(0, 1.6, 0)
	local near1 = SoulSim.orb(1, vector.create(0, 0, -5), 0)
	local near2 = SoulSim.orb(2, vector.create(0, 0, -8), 0)
	local far = SoulSim.orb(3, vector.create(0, 0, -16), 0)
	check("the nearest in reach", SoulSim.pick({ near2, near1, far }, eye, 1, always) == 1)
	check("none past its reach", SoulSim.pick({ far }, eye, 1, always) == nil)
	check("none once its time's up", SoulSim.pick({ near1 }, eye, 3, always) == nil and SoulSim.pick({ near1 }, eye, 2.99, always) == 1)
	local blocked = function(_: vector, at: vector): boolean
		return at.z ~= -5
	end
	check("one out of sight passed over for the next", SoulSim.pick({ near1, near2 }, eye, 1, blocked) == 2)
	local twin = SoulSim.orb(9, vector.create(0, 0, -5), 0)
	check("of two as near, the lower number", SoulSim.pick({ twin, near1 }, eye, 1, always) == 1)
	check("those that last", #SoulSim.lasting({ near1, SoulSim.orb(7, vector.create(0, 0, 0), 5) }, 4) == 1)

	local heal = SoulSim.heal(10)
	local first = SoulSim.take(heal, 11)
	local second, over = SoulSim.take(heal, 12)
	local after = SoulSim.take(heal, 13)
	check("Devour's heal: 25 a second, 50 in all, then nothing", first == 25 and second == 25 and over and after == 0)
	local steady = SoulSim.heal(0)
	local given = 0
	for i = 1, 30 do
		given += SoulSim.take(steady, i * 0.1)
	end
	check("given a few points at a time, it comes to 50", given == 50)
end

-- Overheal ------------------------------------------------------------------------------------

do
	local h = Health.new(100)
	check("past full health with an overheal", Health.overheal(h, 30, 150) and h.health == 130)
	Health.overheal(h, 40, 150)
	check("up to its most", h.health == 150)
	check("and no further", not Health.overheal(h, 10, 150) and h.health == 150)
	Health.apply(h, 20)
	check("a hit takes it off as health", h.health == 130)
	Health.mend(h, 50, 0)
	check("a mend doesn't take it away", h.health == 130)
	Health.heal(h)
	check("nor a health pack", h.health == 130)
	check("its time up, it goes", Health.trim(h) and h.health == 100)
	check("leaving full health as it is", not Health.trim(h) and h.health == 100)
	Health.apply(h, 30)
	check("and taking nothing from the hurt", not Health.trim(h) and h.health == 70)
	Health.reset(h)
	check("a new life starts at full health", h.health == 100)
	local hurt = Health.new(100)
	Health.apply(hurt, 60)
	Health.mend(hurt, 30, 0)
	check("a mend still heals up to full", hurt.health == 70)
	local dead = Health.new(100)
	Health.apply(dead, 200)
	check("and the dead get nothing", not Health.overheal(dead, 50, 150) and dead.health == 0)
end

-- Devour ---------------------------------------------------------------------------------------

do
	local sim = newReyna()
	local _, none = step(sim, B.AbilityQ)
	check("Q with no orb in reach: nothing", #none == 0 and sim.abilities.charges[Q] == 2)
	step(sim, 0)
	local _, casts = step(sim, B.AbilityQ, 7)
	local devour = ofKind(casts, "devour")[1]
	check("Q with one: Devour, taking it", devour ~= nil and devour.soul == 7 and devour.ability == "devour")
	check("its charge spent", sim.abilities.charges[Q] == 1)
	local shots = run(sim, B.Fire, 2)
	check("and the gun stays in hand, firing", #shots > 0)
	step(sim, 0)
	sim.abilities.charges[Q] = 0
	local _, empty = step(sim, B.AbilityQ, 8)
	check("with no charge, the orb's left", #empty == 0)

	local both = newReyna()
	local _, together = step(both, B.AbilityQ + B.AbilityE, 3)
	check(
		"Q and E at once take the one orb once: Devour",
		#ofKind(together, "devour") == 1 and #ofKind(together, "dismiss") == 0 and both.abilities.charges[E] == 2
	)
end

-- Dismiss --------------------------------------------------------------------------------------

do
	local sim = newReyna()
	local t0 = now(sim)
	local _, casts = step(sim, B.AbilityE, 2)
	local dismiss = ofKind(casts, "dismiss")[1]
	local kit = sim.abilities
	check("E with an orb in reach: Dismiss, taking it", dismiss ~= nil and dismiss.soul == 2 and kit.charges[E] == 1)
	check("for its time", near(kit.dismissUntil, t0 + DT + RY.dismissTime.value, 1e-6))
	check(
		"which the kit says",
		string.find(AbilitySim.summary(kit, now(sim)), "dismiss 1.5", 1, true) ~= nil,
		AbilitySim.summary(kit, now(sim))
	)
	check("and keeps it busy", AbilitySim.busy(kit, now(sim)))
	local shots = run(sim, B.Fire, ticks(0.5))
	check("nothing fires through it", #shots == 0)
	local _, again = step(sim, B.AbilityQ, 5)
	check("nor casts", #again == 0 and kit.charges[Q] == 2)
	step(sim, 0)
	local top = 0
	for _ = 1, ticks(0.7) do
		step(sim, B.Forward)
		top = math.max(top, speed(sim))
	end
	check(
		"and she runs faster than the run speed, up to 12 m/s",
		top > cfg.baseRunSpeed + 1 and top <= RY.dismissSpeed.value + 1e-6,
		tostring(top)
	)
	local over: AbilitySim.Cast? = nil
	local fast = 0
	for _ = 1, ticks(0.5) do
		local _, c = step(sim, B.Forward)
		over = over or ofKind(c, "solid")[1]
		if over and fast == 0 then
			fast = speed(sim)
		end
	end
	check("it ends as its time's up", over ~= nil and kit.dismissUntil == 0 and not AbilitySim.dismissing(kit, now(sim)))
	check("leaving no more than the run speed", fast <= cfg.baseRunSpeed + 1e-6, tostring(fast))
	local w = sim.weapons
	check("and the gun drawn again", w.equipEndTime > (over :: AbilitySim.Cast).time)
	run(sim, 0, ticks(1.2))
	check("which fires once it's drawn", #run(sim, B.Fire, 2) > 0)

	local dead = newReyna()
	step(dead, B.AbilityE, 4)
	AbilitySim.died(dead.abilities)
	check("a death ends it", dead.abilities.dismissUntil == 0 and PlayerSim.maxSpeed(dead, cfg) < RY.dismissSpeed.value)

	local planter = newReyna()
	step(planter, B.AbilityE, 6)
	check("nor can she plant or defuse in it", not PlayerSim.rooted(planter))
end

-- The wire -------------------------------------------------------------------------------------

do
	local sim = newReyna()
	step(sim, B.AbilityE, 1)
	run(sim, B.Forward, ticks(0.3))
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(3, sim))
	check("the ack carries her Dismiss", decoded.abilities.dismissUntil == sim.abilities.dismissUntil and sim.abilities.dismissUntil > 0)
	local copy = decoded :: PlayerSim.State
	local same, solids = true, 0
	for i = 1, ticks(1.6) do
		local buttons = if i % 40 < 20 then B.Forward else B.Left + B.Fire
		local s1, c1 = step(sim, buttons)
		local s2, c2 = step(copy, buttons)
		solids += #ofKind(c1, "solid")
		same = same and #c1 == #c2 and #s1 == #s2 and sim.movement.position == copy.movement.position
	end
	check("and a replay from it runs and ends as it does", same and solids == 1)
end

-- Basic Training with her kit -----------------------------------------------------------------

do
	local s = TrainingRules.new()
	TrainingRules.go(s, TrainingRules.indexOf("abilities") :: number)
	TrainingRules.skip(s, 1)
	check("an ability that can't be played yet counts as used", TrainingRules.progress(s) == "1 / 3" and not TrainingRules.used(s))
	s.hint = TrainingConfig.Notes.soul
	check(
		"with the hint on Soul Orbs after the count",
		TrainingRules.progress(s) == "1 / 3   " .. TrainingConfig.Notes.soul,
		TrainingRules.progress(s)
	)
	check(
		"named as the input in use has them",
		TrainingRules.text(TrainingConfig.Notes.soul, "keys") == "Q and E take a Soul Orb: down a target first."
	)
	TrainingRules.cast(s, 2, "devour")
	check("Devour and Dismiss used: done", TrainingRules.cast(s, 3, "dismiss"))
	local u = TrainingRules.new()
	TrainingRules.go(u, TrainingRules.indexOf("ultimate") :: number)
	TrainingRules.skip(u, 4)
	check("an ultimate that can't be played yet: done", TrainingRules.used(u))
end

return nil
