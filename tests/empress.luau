--!strict
-- Reyna's Empress (system 75): its numbers and where they come from, its
-- cast (the points spent, the gun away and nothing cast through its
-- activation), its frenzy (rounds 15% faster, draws and reloads 25% faster,
-- the spray climbing and settling as it would without it, Q taking no orb
-- and Dismiss spending no charge and hiding her), what ends it, the wire
-- carrying it so a replay comes back the same, and bots casting it and
-- the rest of her kit through it.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Spike = require("../src/shared/Spike/Spike")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local BotConfig = require("../src/shared/Bots/BotConfig")
local BotTeam = require("../src/shared/Bots/BotTeam")
local BotUtility = require("../src/shared/Bots/BotUtility")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local RY = AbilityConfig.Reyna
local Q, E, X = AbilityConfig.Q, AbilityConfig.E, AbilityConfig.X
local FEET = vector.create(0, 0.02, 0)
local VANDAL = WeaponConfig.get("vandal")
local CLASSIC = WeaponConfig.get("classic")

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

-- One tick with `buttons` held, `soul` in reach and `slot` asked for: its
-- bullets and casts.
local function step(sim: PlayerSim.State, buttons: number, soul: number?, slot: number?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	local shots, _, _, _, casts = PlayerSim.step(sim, input(buttons, slot), cfg, floor, DT, soulful(soul))
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

local function summary(sim: PlayerSim.State): string
	return AbilitySim.summary(sim.abilities, now(sim))
end

-- Reyna settled on the floor, the Vandal drawn, her charges and her
-- ultimate's points full.
local function newReyna(): PlayerSim.State
	local sim = PlayerSim.new(FEET, { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new("reyna")
	AbilitySim.fill(sim.abilities, true)
	run(sim, 0, ticks(1.5))
	return sim
end

-- Reyna in her frenzy: X, and its activation waited out.
local function inFrenzy(): PlayerSim.State
	local sim = newReyna()
	step(sim, B.Ultimate)
	run(sim, 0, ticks(RY.empressActivation.value) + 1)
	return sim
end

-- The first `n` rounds of a spray held from a ready gun, the trigger let go
-- after.
local function spray(sim: PlayerSim.State, n: number): { WeaponSim.Shot }
	local out = {}
	while #out < n do
		local s = step(sim, B.Fire)
		table.move(s, 1, #s, #out + 1, out)
	end
	run(sim, 0, ticks(1))
	return out
end

H.section("Empress tests")

-- Its numbers -----------------------------------------------------------------------------------

do
	check("Reyna's Empress can be played", AbilitySim.playable("empress"))
	check(
		"its activation 1 s (THESPIKE.GG, 'Cast time: 1 second')",
		RY.empressActivation.value == 1 and RY.empressActivation.status == "community"
	)
	check("its rounds 15% faster (Patch 1.09)", RY.empressFire.value == 1.15 and RY.empressFire.status == "confirmed")
	check(
		"its draws and reloads 25% faster (esports.net, THESPIKE.GG)",
		RY.empressHandling.value == 1.25 and RY.empressHandling.status == "community"
	)
end

-- Its cast --------------------------------------------------------------------------------------

do
	local sim = newReyna()
	local kit = sim.abilities
	check("her points full on the course", AbilitySim.charged(kit) and kit.points == 7)
	local t0 = now(sim)
	local _, casts = step(sim, B.Ultimate)
	local cast = ofKind(casts, "empress")[1]
	check("X with them full: Empress, its points spent", cast ~= nil and cast.slot == X and kit.points == 0)
	check("its frenzy its activation off", near(kit.empressAt, t0 + DT + RY.empressActivation.value, 1e-9))
	check(
		"which the kit says, under way and busy",
		AbilitySim.crowning(kit, now(sim))
			and string.find(summary(sim), "crown", 1, true) ~= nil
			and AbilitySim.ultimateOn(kit)
			and AbilitySim.busy(kit, now(sim)),
		summary(sim)
	)
	local _, leer = step(sim, B.AbilityC)
	check("nothing's cast through its activation", #leer == 0 and kit.holding == 0)
	local early, first = 0, nil :: WeaponSim.Shot?
	for _ = 1, ticks(RY.empressActivation.value) + 4 do
		local shots = step(sim, B.Fire)
		if shots[1] and shots[1].time < kit.empressAt - 1e-9 then
			early += 1
		end
		first = first or shots[1]
	end
	check("nor fired", early == 0)
	check("the gun fires as it's over", first ~= nil and near(first.time, kit.empressAt, DT + 1e-9))
	run(sim, 0, ticks(0.5))
	check(
		"and the frenzy's on, as the kit says, nothing else under way",
		AbilitySim.frenzied(kit, now(sim)) and string.find(summary(sim), "frenzy", 1, true) ~= nil and not AbilitySim.busy(kit, now(sim)),
		summary(sim)
	)
	local at = kit.empressAt
	local _, again = step(sim, B.Ultimate)
	check("X again does nothing", #again == 0 and kit.empressAt == at)
	local _, eye = step(sim, B.AbilityC)
	check("and through it the rest of her kit casts: Leer in hand", #ofKind(eye, "equip") == 1 and kit.holding == AbilityConfig.C)

	local short = newReyna()
	short.abilities.points = 6
	local _, none = step(short, B.Ultimate)
	check("X short of its points does nothing", #none == 0 and short.abilities.empressAt == 0)
end

-- Its frenzy ------------------------------------------------------------------------------------

do
	local plain, hasty = newReyna(), inFrenzy()
	local a, b = spray(plain, 11), spray(hasty, 11)
	local interval = WeaponConfig.mode(VANDAL, 0).interval
	local spanA, spanB = a[11].time - a[1].time, b[11].time - b[1].time
	check(
		"in the frenzy the Vandal's rounds come 15% faster",
		near(spanA, 10 * interval, DT) and near(spanB, 10 * interval / RY.empressFire.value, DT),
		string.format("%.4f s and %.4f s for ten", spanA, spanB)
	)
	local same = true
	for i = 1, 11 do
		same = same
			and a[i].bullet == b[i].bullet
			and near(a[i].recoilPitch, b[i].recoilPitch, 1e-9)
			and near(a[i].recoilYaw, b[i].recoilYaw, 1e-9)
	end
	check("its spray climbs as it would without it (Patch 9.05)", same)
end

do
	-- Tapped every quarter of a second, part of the spray recovers between.
	local function taps(sim: PlayerSim.State): { WeaponSim.Shot }
		local out = {}
		for _ = 1, 6 do
			local s = step(sim, B.Fire)
			table.insert(out, s[1])
			run(sim, 0, ticks(0.25) - 1)
		end
		return out
	end
	local a, b = taps(newReyna()), taps(inFrenzy())
	local same = #a == 6 and #b == 6
	for i = 1, math.min(#a, #b) do
		same = same and near(a[i].sprayIndex, b[i].sprayIndex, 1e-9)
	end
	check(
		"and settles as it would, from when it could have fired again at its own rate",
		same and a[3].sprayIndex > 0 and a[3].sprayIndex < 2,
		string.format("%.3f and %.3f", a[3].sprayIndex, b[3].sprayIndex)
	)
end

do
	local plain, hasty = newReyna(), inFrenzy()
	local t1 = now(plain) + DT
	step(plain, 0, nil, 2)
	local t2 = now(hasty) + DT
	step(hasty, 0, nil, 2)
	check(
		"a draw 25% faster: the Classic's",
		near(plain.weapons.equipEndTime - t1, CLASSIC.equipTime.value, 1e-9)
			and near(hasty.weapons.equipEndTime - t2, CLASSIC.equipTime.value / RY.empressHandling.value, 1e-9)
	)
end

do
	local plain, hasty = newReyna(), inFrenzy()
	spray(plain, 3)
	spray(hasty, 3)
	local t1 = now(plain) + DT
	step(plain, B.Reload)
	local t2 = now(hasty) + DT
	step(hasty, B.Reload)
	check(
		"a reload 25% faster: the Vandal's",
		near(plain.weapons.reloadEndTime - t1, VANDAL.reloadTime.value, 1e-9)
			and near(hasty.weapons.reloadEndTime - t2, VANDAL.reloadTime.value / RY.empressHandling.value, 1e-9)
	)
end

-- What ends it ----------------------------------------------------------------------------------

do
	local dead = inFrenzy()
	AbilitySim.died(dead.abilities)
	step(dead, 0)
	check("a death ends it", dead.abilities.empressAt == 0 and dead.weapons.rate == 1 and dead.weapons.handling == 1)
	local round = inFrenzy()
	AbilitySim.newRound(round.abilities)
	check("so does a new round", round.abilities.empressAt == 0 and not AbilitySim.ultimateOn(round.abilities))
	local course = inFrenzy()
	AbilitySim.fill(course.abilities, true)
	check("nothing else does: the course fills no points while it's on", course.abilities.points == 0)
	run(course, 0, ticks(30))
	check("and 30 s on it's on still", AbilitySim.frenzied(course.abilities, now(course)))
end

-- Devour and Dismiss in it ----------------------------------------------------------------------

do
	local sim = inFrenzy()
	local kit = sim.abilities
	local _, q = step(sim, B.AbilityQ, 4)
	check("in the frenzy Q takes no orb, as Devour's cast for her", #q == 0 and kit.charges[Q] == 2)
	step(sim, 0)
	kit.charges[E] = 0
	local _, e = step(sim, B.AbilityE, 4)
	local d = ofKind(e, "dismiss")[1]
	check(
		"E takes it with no charge left: Dismiss, hiding her",
		d ~= nil and d.soul == 4 and d.hidden == true and kit.charges[E] == 0 and AbilitySim.dismissing(kit, now(sim))
	)
	check("unseen by her enemies, bots too, while it runs", AbilitySim.unseen(kit, now(sim)))
	run(sim, 0, ticks(RY.dismissTime.value) + 2)
	check(
		"and the frenzy goes on after it, seen again",
		AbilitySim.frenzied(kit, now(sim)) and not AbilitySim.dismissing(kit, now(sim)) and not AbilitySim.unseen(kit, now(sim))
	)

	local plain = newReyna()
	local _, e2 = step(plain, B.AbilityE, 5)
	local d2 = ofKind(e2, "dismiss")[1]
	check(
		"out of it a Dismiss spends its charge and doesn't hide her",
		d2 ~= nil
			and d2.hidden == nil
			and plain.abilities.charges[E] == 1
			and AbilitySim.dismissing(plain.abilities, now(plain))
			and not AbilitySim.unseen(plain.abilities, now(plain))
	)
end

-- The wire --------------------------------------------------------------------------------------

do
	local sim = inFrenzy()
	run(sim, B.Fire, 5)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(3, sim))
	check(
		"the ack carries her Empress and its quickening",
		decoded.abilities.empressAt == sim.abilities.empressAt
			and decoded.weapons.rate == sim.weapons.rate
			and decoded.weapons.handling == sim.weapons.handling
			and sim.weapons.rate == RY.empressFire.value
			and sim.weapons.handling == RY.empressHandling.value
	)
	-- A second's spray, a reload (2 s at its quickened handling) and a spray
	-- from as it's done: off from both if the copy had lost her Empress.
	local copy = decoded :: PlayerSim.State
	local same, fired = true, 0
	for i = 1, ticks(4) do
		local buttons = if i <= ticks(1) then B.Fire elseif i <= ticks(1) + 4 then B.Reload elseif i >= ticks(3.1) then B.Fire else 0
		local s1 = step(sim, buttons)
		local s2 = step(copy, buttons)
		fired += #s1
		same = same and #s1 == #s2 and (s1[1] == nil or s1[1].time == s2[1].time)
	end
	check("and a replay from it fires as it does", same and fired > 10, tostring(fired))

	local mid = newReyna()
	step(mid, B.Ultimate)
	run(mid, 0, ticks(0.4))
	local _, during = PlayerCodec.decodeAck(PlayerCodec.encodeAck(4, mid))
	check(
		"in its activation too",
		during.abilities.empressAt == mid.abilities.empressAt and AbilitySim.crowning(during.abilities, now(mid))
	)
end

-- Bots ------------------------------------------------------------------------------------------

do
	local sim = newReyna()
	local function always(): number
		return 0
	end
	local function moment(place: BotTeam.Place?, sightings: { BotTeam.Sighting }): BotUtility.Moment
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
			sightings = sightings,
			defuse = nil,
			allies = {},
			mates = {},
		}
	end
	local seenNear = { { at = vector.create(0, 1.62, -8), time = 49.5 } } :: { BotTeam.Sighting }
	local c = BotUtility.choose(moment(nil, seenNear), sim.abilities, BotUtility.memo(), BotConfig.Skills.expert, always, floor)
	check(
		"a bot on her casts Empress with an enemy seen near, where it respawns",
		c ~= nil and c.ability == "empress" and c.key == "empress"
	)
	local cast: AbilitySim.Cast? = nil
	if c then
		for _ = 1, 10 do
			local t = (sim.movement.tick + 1) * DT
			local hands = BotUtility.hands(c, sim.abilities, sim.weapons, t, PlayerSim.eye(sim, cfg), 0, 0, DT)
			local _, casts = step(sim, hands.buttons)
			cast = cast or ofKind(casts, "empress")[1]
			if hands.done then
				break
			end
		end
	end
	check("its hands press X, casting it", cast ~= nil and AbilitySim.ultimateOn(sim.abilities))
	run(sim, 0, ticks(RY.empressActivation.value) + 2)
	local way = vector.create(0, 1.62, -20)
	local place: BotTeam.Place = {
		role = "hold",
		phase = "hold",
		there = true,
		way = way,
		heading = nil,
		door = nil,
		from = nil,
		threats = {},
		spike = nil,
	}
	local seen = { { at = way + vector.create(0, 0, -1), time = 49.5 } } :: { BotTeam.Sighting }
	local leer = BotUtility.choose(moment(place, seen), sim.abilities, BotUtility.memo(), BotConfig.Skills.expert, always, floor)
	check(
		"and through the frenzy, the rest: Leer at attackers just seen at the way in it holds",
		leer ~= nil and leer.ability == "leer" and leer.key == "stall:leer" and AbilitySim.frenzied(sim.abilities, now(sim))
	)
end

return nil
