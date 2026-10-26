--!strict
-- Phoenix's Run it Back (system 33): its numbers and where they come from,
-- its cast (X with its points full, marking where he stands and the way he
-- faces, the gun away for its activation and nothing else cast through
-- it, an ability in hand gone), its running out (his body gone where he
-- is, held, then rising at the mark as he stood there, his guns reloaded
-- and back in hand as he's free), the server sparing him a hit that would
-- have killed him (the same return, from his last tick), a Blade Storm
-- knife that did it brought back, a plant under way as his body goes, the
-- kit's points not filled while it's on, the hold in the movement, and the
-- wire carrying all of it so a replay comes back the same.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local MovementSim = require("../src/shared/Movement/MovementSim")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Spike = require("../src/shared/Spike/Spike")
local SpikeSim = require("../src/shared/Spike/SpikeSim")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local RB = AbilityConfig.RunItBack
local TDM = AbilityConfig.TeamDeathmatch
local ULT = WeaponSim.ULT
local E, X = AbilityConfig.E, AbilityConfig.X
local PHOENIX = "phoenix"
local FEET = vector.create(0, 0.02, 0)

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = 0, viewTime = 0 }
end

-- A player, the slot their client asks for, and the way they face.
type Player = { sim: PlayerSim.State, slot: number, yaw: number }

-- One tick; returns its bullets and its casts.
local function step(p: Player, buttons: number, ctx: Spike.Context?): ({ WeaponSim.Shot }, { AbilitySim.Cast }, SpikeSim.Act?)
	local shots, _, act, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot, p.yaw), cfg, floor, DT, ctx)
	return shots or {}, casts or {}, act
end

local function run(p: Player, buttons: number, n: number, ctx: Spike.Context?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	local shots, casts = {}, {}
	for _ = 1, n do
		local s, c = step(p, buttons, ctx)
		for _, shot in s do
			table.insert(shots, shot)
		end
		for _, cast in c do
			table.insert(casts, cast)
		end
	end
	return shots, casts
end

local function now(p: Player): number
	return p.sim.movement.tick * DT
end

-- Phoenix settled on the floor at `feet` (the middle unless given) with
-- `loadout` (the Vandal, the Classic and the knife unless given), the
-- Vandal drawn, every charge and his points full.
local function newPlayer(feet: vector?, loadout: { string }?): Player
	local sim = PlayerSim.new(feet or FEET, loadout or { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(PHOENIX)
	AbilitySim.fill(sim.abilities, true)
	local p = { sim = sim, slot = 1, yaw = 0 }
	run(p, 0, ticks(1.5))
	return p
end

-- The casts of kind `kind` among `casts`.
local function ofKind(casts: { AbilitySim.Cast }, kind: string): { AbilitySim.Cast }
	local out = {}
	for _, cast in casts do
		if cast.kind == kind then
			table.insert(out, cast)
		end
	end
	return out
end

-- Level distance between two points.
local function flat(a: vector, b: vector): number
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
end

-- Ticks until the first cast of kind `kind`, holding `buttons`, at most
-- `most`; nil if none came.
local function untilCast(p: Player, kind: string, most: number, buttons: number?): (number?, AbilitySim.Cast?)
	for n = 1, most do
		local _, casts = step(p, buttons or 0)
		local found = ofKind(casts, kind)[1]
		if found then
			return n, found
		end
	end
	return nil, nil
end

H.section("Run it Back tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param: any in RB do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Run it Back number says where it's from", labelled)
	local def = AbilityConfig.Defs.runitback
	check(
		"7 points (Patch 13.02: 'increased from 6 to 7'), Phoenix's X",
		def.points ~= nil
			and def.points.value == 7
			and def.points.status == "confirmed"
			and def.slot == X
			and def.kind == "ultimate"
			and table.find(AbilityConfig.Agents.phoenix.abilities, "runitback") ~= nil
	)
	check("70 in Team Deathmatch (the wiki)", TDM.ultimate.runitback.value == 70 and TDM.ultimate.runitback.status == "community")
	check(
		"10 s, its 1 s activation in it (the wiki)",
		RB.duration.value == 10 and RB.activation.value == 1 and RB.duration.status == "community" and RB.activation.status == "community"
	)
	check(
		"back in 2.4 s: 1 s gone and 1.4 s rising (the wiki)",
		near(RB.away.value + RB.rise.value, 2.4, 1e-12) and RB.away.status == "community" and RB.rise.status == "community"
	)
	check("the server's grace on top is ours", RB.grace.status == "estimate")
	check("it can be played", AbilitySim.playable("runitback"))
end

-- The cast -------------------------------------------------------------------------------------

do
	local p = newPlayer()
	p.sim.abilities.points = 6
	local _, none = step(p, B.Ultimate)
	check("short of its points, X does nothing", #none == 0 and not AbilitySim.runningBack(p.sim.abilities))
end

do
	local p = newPlayer(vector.create(3, 0.02, -2))
	p.yaw = 0.7
	local feet = p.sim.movement.position
	local _, casts = step(p, B.Ultimate)
	local cast = casts[1]
	local kit, w = p.sim.abilities, p.sim.weapons
	local t = now(p)
	check("X with its points full marks", #casts == 1 and cast.kind == "mark" and cast.ability == "runitback" and cast.slot == X)
	check(
		"where he stands, the way he faces",
		vector.magnitude(cast.position - feet) < 1e-6
			and vector.magnitude(kit.mark - feet) < 1e-6
			and kit.markYaw == 0.7
			and vector.magnitude(cast.direction - vector.create(-math.sin(0.7), 0, -math.cos(0.7))) < 1e-6
	)
	check("standing, on the floor", kit.markGrounded and not kit.markCrouched)
	check("its points spent", kit.points == 0)
	check("running 10 s from the cast", near(kit.backUntil - t, RB.duration.value, 1e-9) and AbilitySim.runningBack(kit))
	check("the kit says so", string.find(AbilitySim.summary(kit, t), "back", 1, true) ~= nil)
	check("the gun away for its 1 s activation", near(w.equipEndTime - t, RB.activation.value, 1e-9) and w.equipped == 1)
	local shots = run(p, B.Fire, 20)
	check("so it can't fire through it", #shots == 0)
	local _, early = run(p, B.AbilityE, 1)
	check("nor is anything else cast in it", #early == 0 and AbilitySim.marking(kit, now(p)) and kit.holding == 0)
	run(p, 0, ticks(RB.activation.value) - 21)
	check("its activation's over 1 s in", not AbilitySim.marking(kit, now(p)))
	local _, later = step(p, B.AbilityE)
	check("then other abilities cast", #later == 1 and later[1].kind == "equip" and kit.holding == E)
	local _, again = step(p, B.Ultimate)
	check("X again casts nothing", #ofKind(again, "mark") == 0)
	AbilitySim.fill(kit, true)
	check("and its points aren't filled while it runs", kit.points == 0 and AbilitySim.full(kit, true))
end

do
	local p = newPlayer()
	step(p, B.AbilityE)
	run(p, 0, ticks(WeaponConfig.Defs.flare.equipTime.value) + 1)
	local _, casts = step(p, B.Ultimate)
	local w, kit = p.sim.weapons, p.sim.abilities
	check(
		"cast with the flare in hand, the flare goes and the gun comes out",
		#ofKind(casts, "mark") == 1
			and kit.holding == 0
			and w.loadout[ULT] == ""
			and w.equipped == 1
			and kit.charges[E] == AbilitySim.maxCharges(kit, E)
	)
end

do
	local p = newPlayer()
	run(p, B.Crouch, ticks(0.6))
	local _, casts = step(p, B.Crouch + B.Ultimate)
	check("crouched, it marks him crouched", #casts == 1 and p.sim.abilities.markCrouched and p.sim.abilities.markGrounded)
end

-- Running out ---------------------------------------------------------------------------------

do
	local p = newPlayer(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	local w, kit = p.sim.weapons, p.sim.abilities
	w.ammo[1] -= 12
	w.ammo[2] -= 5
	local reserve1, reserve2 = w.reserve[1], w.reserve[2]
	step(p, B.Ultimate)
	local cast = now(p)
	local mark = kit.mark
	-- Away from the mark, and off the floor as it runs out.
	run(p, B.Forward, ticks(3))
	local moved = p.sim.movement.position
	check("it doesn't hold him where he cast it", flat(moved, mark) > 5)
	local n, fizzle = untilCast(p, "fizzle", ticks(RB.duration.value) + 5, B.Forward)
	check(
		"10 s after the cast it runs out",
		n ~= nil and near(now(p) - cast, RB.duration.value, 1e-9),
		string.format("%.4f s", now(p) - cast)
	)
	local gone = p.sim.movement.position
	check(
		"his body going where he is",
		fizzle ~= nil and fizzle.ability == "runitback" and vector.magnitude(fizzle.position - gone) < 0.05 and kit.returnAt == now(p)
	)
	check("over, and his return under way", not AbilitySim.runningBack(kit) and AbilitySim.away(kit, now(p)))
	check("the kit says he's away", string.find(AbilitySim.summary(kit, now(p)), "away", 1, true) ~= nil)
	local ammo = w.ammo[1]
	local shots = run(p, B.Forward + B.Fire + B.Jump, ticks(RB.away.value) - 1)
	check(
		"held where it went: no moves, no shots",
		#shots == 0 and vector.magnitude(p.sim.movement.position - gone) < 1e-9 and w.ammo[1] == ammo
	)
	local _, rise = step(p, B.Forward + B.Fire)
	local back = rise[1]
	check(
		"1 s on he rises at the mark",
		back ~= nil
			and back.kind == "rise"
			and vector.magnitude(back.position - mark) < 1e-9
			and near(now(p) - kit.returnAt, RB.away.value, 1e-9)
	)
	check(
		"put there, standing on the floor, and still",
		vector.magnitude(p.sim.movement.position - mark) < 1e-9
			and p.sim.movement.grounded
			and not p.sim.movement.crouched
			and vector.magnitude(p.sim.movement.velocity) == 0
	)
	check(
		"from the eye there, facing as he did",
		back ~= nil
			and vector.magnitude(back.origin - PlayerSim.eye(p.sim, cfg)) < 1e-6
			and vector.magnitude(back.direction - vector.create(0, 0, -1)) < 1e-6
	)
	local vandal, classic = WeaponConfig.Defs.vandal, WeaponConfig.Defs.classic
	check(
		"his guns reloaded from what they carry",
		w.ammo[1] == vandal.magazine.value
			and w.ammo[2] == classic.magazine.value
			and w.reserve[1] == reserve1 - 12
			and w.reserve[2] == reserve2 - 5
	)
	check(
		"the gun drawn again, ready as he's free (Patch 5.07)",
		w.equipped == 1 and near(w.equipEndTime, AbilitySim.risen(kit), 1e-9) and near(AbilitySim.risen(kit) - kit.returnAt, 2.4, 1e-9)
	)
	check("the kit says he's rising", string.find(AbilitySim.summary(kit, now(p)), "rise", 1, true) ~= nil)
	local risen = AbilitySim.risen(kit)
	local held = 0
	while AbilitySim.returning(kit, now(p) + DT) and held < ticks(3) do
		local s = step(p, B.Forward + B.Fire)
		held += #s
	end
	check(
		"held through his rise: no moves, no shots",
		held == 0 and vector.magnitude(p.sim.movement.position - mark) < 1e-9,
		string.format("%d shots", held)
	)
	local s = step(p, B.Forward + B.Fire)
	check(
		"free once it's over, 2.4 s after his body went",
		#s == 1 and now(p) >= risen - 1e-9 and now(p) - risen < DT and kit.returnAt == 0,
		string.format("%d shots", #s)
	)
	local words = AbilitySim.summary(kit, now(p))
	check(
		"the mark forgotten",
		kit.mark == vector.zero
			and not kit.markGrounded
			and string.find(words, "back", 1, true) == nil
			and string.find(words, "away", 1, true) == nil
			and string.find(words, "rise", 1, true) == nil,
		words
	)
	run(p, B.Forward, 10)
	check("and he moves", flat(p.sim.movement.position, mark) > 0.05)
	AbilitySim.fill(kit, true)
	check("its points can be filled again", kit.points == 7)
end

do
	local p = newPlayer()
	run(p, B.Crouch, ticks(0.6))
	step(p, B.Crouch + B.Ultimate)
	-- Stood up, and up in the air as it runs out.
	run(p, 0, ticks(RB.duration.value - 0.2))
	step(p, B.Jump)
	untilCast(p, "fizzle", ticks(1))
	check("off the floor as his body goes", not p.sim.movement.grounded)
	local _, back = untilCast(p, "rise", ticks(2))
	check(
		"he rises crouched, as he cast it",
		back ~= nil and p.sim.movement.crouched and p.sim.movement.crouchAlpha == 1 and p.sim.movement.grounded
	)
end

-- The server sparing him a hit ----------------------------------------------------------------

do
	local p = newPlayer()
	step(p, B.Ultimate)
	local mark = p.sim.abilities.mark
	run(p, B.Forward, ticks(2))
	local kit = p.sim.abilities
	local t = now(p)
	AbilitySim.fizzle(kit, t)
	check("a hit that would kill him ends it there", not AbilitySim.runningBack(kit) and kit.returnAt == t)
	local at = p.sim.movement.position
	local shots, casts = step(p, B.Forward + B.Fire)
	check("his body's gone from his next tick, with nothing more cast", #casts == 0 and #shots == 0 and p.sim.movement.position == at)
	local n, back = untilCast(p, "rise", ticks(2), B.Forward)
	check(
		"and 1 s after the hit he rises at the mark",
		n ~= nil and back ~= nil and vector.magnitude(p.sim.movement.position - mark) < 1e-9 and near(now(p) - t, RB.away.value, 1e-9)
	)
end

do
	-- A Blade Storm knife that did it: Jett's knives back, and no point.
	local jett = PlayerSim.new(FEET, { "vandal", "classic", "knife", "" })
	AbilitySim.fill(jett.abilities, true)
	local j: Player = { sim = jett, slot = 1, yaw = 0 }
	run(j, 0, ticks(1.5))
	step(j, B.Ultimate)
	run(j, 0, ticks(AbilityConfig.BladeStorm.windup.value) + 1)
	step(j, B.Fire)
	run(j, 0, 30)
	local points = jett.abilities.points
	PlayerSim.knivesBack(jett, "kunai", "hip")
	check(
		"a single knife that hit him brings all five back (Patch 1.02), with no point",
		jett.weapons.ammo[ULT] == 5 and jett.abilities.points == points
	)
	step(j, B.Fire)
	PlayerSim.knivesBack(jett, "kunai", "alt")
	check("the burst brings none back", jett.weapons.ammo[ULT] == 4)
end

-- A plant under way ---------------------------------------------------------------------------

do
	local site = Spike.CourseSites[1]
	local ctx: Spike.Context = { zones = Spike.CourseSites, canPlant = true, canDefuse = false, halfSaved = false }
	local p = newPlayer(vector.create(site.center.x, 0.02, site.center.z), { "vandal", "classic", "knife", "spike" })
	step(p, B.Ultimate)
	run(p, 0, ticks(1.2))
	p.slot = 4
	run(p, 0, ticks(1), ctx)
	-- Half a second short of its 4 s.
	run(p, B.Use, ticks(3.5), ctx)
	check("planting with it running", p.sim.spike.channel == SpikeSim.PLANTING and AbilitySim.runningBack(p.sim.abilities))
	AbilitySim.fizzle(p.sim.abilities, now(p))
	local planted = false
	while AbilitySim.returning(p.sim.abilities, now(p) + DT) do
		local _, _, act = step(p, B.Use, ctx)
		planted = planted or (act ~= nil and act.kind == "planted")
	end
	check("as his body goes the plant stops, and nothing's planted", not planted and p.sim.spike.channel == SpikeSim.NONE)
end

-- The hold --------------------------------------------------------------------------------------

do
	local m = MovementSim.newState(vector.create(0, 2, 0))
	m.velocity = vector.create(3, -4, 1)
	m.gliding = true
	MovementSim.step(m, input(B.Forward + B.Jump), cfg, cfg.baseRunSpeed, floor, DT, { hold = true })
	check(
		"held, a tick of movement stands still in the air: no fall, no glide",
		m.tick == 1 and m.position == vector.create(0, 2, 0) and m.velocity == vector.zero and not m.gliding
	)
end

-- A new life -----------------------------------------------------------------------------------

do
	local p = newPlayer()
	step(p, B.Ultimate)
	run(p, 0, ticks(RB.duration.value) + 10)
	local kit = p.sim.abilities
	AbilitySim.settle(kit)
	check(
		"a new life or round ends it and its return",
		not AbilitySim.runningBack(kit) and not AbilitySim.returning(kit, now(p)) and kit.mark == vector.zero
	)
end

-- The wire -------------------------------------------------------------------------------------

do
	local p = newPlayer(vector.create(1, 0.02, 4))
	p.yaw = -1.1
	run(p, B.Crouch, ticks(0.6))
	step(p, B.Crouch + B.Ultimate)
	run(p, B.Forward, ticks(2))
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	local a, b = p.sim.abilities, decoded.abilities
	check(
		"the ack carries it running: its time, its mark and how he stood there",
		b.backUntil == a.backUntil and b.returnAt == 0 and b.mark == a.mark and b.markYaw == a.markYaw and b.markCrouched and b.markGrounded
	)
	local copy: Player = { sim = decoded :: PlayerSim.State, slot = p.slot, yaw = p.yaw }
	local same, rises = true, 0
	for i = 1, ticks(RB.duration.value + 3) do
		local buttons = if i % 50 < 25 then B.Forward else B.Left + B.Fire
		local _, c1 = step(p, buttons)
		local _, c2 = step(copy, buttons)
		rises += #ofKind(c1, "rise")
		same = same
			and #c1 == #c2
			and p.sim.movement.position == copy.sim.movement.position
			and a.returnAt == copy.sim.abilities.returnAt
			and p.sim.weapons.equipEndTime == copy.sim.weapons.equipEndTime
	end
	check("and a replay from it runs out, returns and rises as it does", same and rises == 1 and not AbilitySim.returning(a, now(p)))

	local q = newPlayer()
	step(q, B.Ultimate)
	run(q, 0, ticks(RB.duration.value) + ticks(0.5))
	local _, away = PlayerCodec.decodeAck(PlayerCodec.encodeAck(10, q.sim))
	check("the ack carries his return", away.abilities.returnAt == q.sim.abilities.returnAt and away.abilities.backUntil == 0)
	local left: Player = { sim = away :: PlayerSim.State, slot = q.slot, yaw = q.yaw }
	local alike = true
	for _ = 1, ticks(3) do
		local _, c1 = step(q, B.Forward)
		local _, c2 = step(left, B.Forward)
		alike = alike and #c1 == #c2 and q.sim.movement.position == left.sim.movement.position
	end
	check("and a replay from it rises where it does", alike)
end

return nil
