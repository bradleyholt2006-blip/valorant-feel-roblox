--!strict
-- Omen's From the Shadows (system 43): its numbers and where they come from,
-- its map in hand (X once the ultimate's points are full, its equip, X again
-- putting it away, fire with no place picked or nowhere to go leaving it in
-- hand, nowhere in the buy phase), the teleport (fire spending the points
-- and starting the windup, through which he's rooted and can't fire or cast
-- though he looks round, then a Shade held where it took him, then there for
-- good, his gun drawn again), sent back (X as a Shade, or the server's word
-- of an enemy's hit, but not X in the windup), where it takes him (the floor
-- under the place, onto a crate, never onto a wall or a block, beside a wall,
-- nowhere under a low roof or with no floor), how far he sees as a Shade,
-- a new life ending it, the map of the course, and the wire carrying it all
-- so a replay comes back the same and nobody's drawn sliding to the Shade.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local ShadowSim = require("../src/shared/Abilities/ShadowSim")
local BarrierSim = require("../src/shared/Abilities/BarrierSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Shop = require("../src/shared/Weapons/Shop")
local Spike = require("../src/shared/Spike/Spike")
local SpikeSim = require("../src/shared/Spike/SpikeSim")
local Minimap = require("../src/shared/Match/Minimap")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local FogOfWar = require("../src/shared/Combat/FogOfWar")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local PoseHistory = require("../src/shared/Net/PoseHistory")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local FS = AbilityConfig.FromTheShadows
local MAP = WeaponConfig.Defs.shadowmap
local ULT = WeaponSim.ULT
local X = AbilityConfig.X
local OMEN = "omen"
local FEET = vector.create(0, 0.02, 0)
local THERE = vector.create(3, 0, -30)
local VANDAL = WeaponConfig.Defs.vandal.equipTime.value

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?, point: vector?)
	return {
		seq = 0,
		buttons = buttons,
		slot = slot or 1,
		yaw = yaw or 0,
		pitch = pitch or 0,
		viewTime = 0,
		point = if point then PlayerCodec.quantizePoint(point) else nil,
	}
end

-- A player, the slot their client asks for, the way they look, the place
-- picked on the map, and the world.
type Player = { sim: PlayerSim.State, slot: number, yaw: number, pitch: number, point: vector?, world: any }

-- The slot the client asks for this tick, by PlayerController's rules.
local function ask(s: PlayerSim.State, slot: number): number
	local w = s.weapons
	if slot ~= ULT and w.loadout[slot] == "" then
		slot = w.equipped
	end
	if w.equipped == ULT and w.hold ~= 0 and slot == w.hold then
		slot = ULT
	end
	return slot
end

-- One tick with `buttons` held, the spike as `objective` allows and the
-- walls as `barriers` has them; returns its bullets, its casts and what
-- happened with the spike.
local function step(
	p: Player,
	buttons: number,
	objective: Spike.Context?,
	barriers: BarrierSim.Walls?
): ({ WeaponSim.Shot }, { AbilitySim.Cast }, SpikeSim.Act?)
	p.slot = ask(p.sim, p.slot)
	local shots, _, act, _, casts =
		PlayerSim.step(p.sim, input(buttons, p.slot, p.yaw, p.pitch, p.point), cfg, p.world, DT, objective, nil, barriers)
	return shots or {}, casts or {}, act
end

-- `n` ticks with `buttons` held: every bullet and cast.
local function run(p: Player, buttons: number, n: number): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	local shots, casts = {}, {}
	for _ = 1, n do
		local s, c = step(p, buttons)
		for _, shot in s do
			table.insert(shots, shot)
		end
		for _, cast in c do
			table.insert(casts, cast)
		end
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

local function now(p: Player): number
	return p.sim.movement.tick * DT
end

-- Omen settled at FEET in `world` (the floor without), the Vandal drawn, his
-- whole kit and, unless `empty`, his ultimate's points full.
local function newPlayer(world: any?, empty: boolean?): Player
	local sim = PlayerSim.new(FEET, { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(OMEN)
	AbilitySim.fill(sim.abilities, not empty)
	local p: Player = { sim = sim, slot = 1, yaw = 0, pitch = 0, point = nil, world = world or floor }
	run(p, 0, ticks(1.5))
	return p
end

-- X tapped, and its map's equip waited out.
local function inHand(world: any?): Player
	local p = newPlayer(world)
	step(p, B.Ultimate)
	run(p, 0, ticks(MAP.equipTime.value) + 1)
	return p
end

-- Fired with the cursor on `point` (THERE without): the teleport's cast, if
-- any.
local function fire(p: Player, point: vector?): AbilitySim.Cast?
	p.point = point or THERE
	local _, casts = step(p, B.Fire)
	return ofKind(casts, "shadows")[1]
end

-- Steps with `buttons` until a cast of `kind` (2 s at the most): the cast
-- and when, and whether every tick before it held him where he stood.
local function until_(p: Player, buttons: number, kind: string): (AbilitySim.Cast?, number, boolean)
	local at = p.sim.movement.position
	local stayed = true
	for _ = 1, ticks(3) do
		local _, c = step(p, buttons)
		local found = ofKind(c, kind)[1]
		if found then
			return found, now(p), stayed
		end
		stayed = stayed and vector.magnitude(p.sim.movement.position - at) < 1e-6
	end
	return nil, 0, stayed
end

H.section("From the Shadows tests")

-- Its numbers ---------------------------------------------------------------------------------

do
	local labelled = true
	for _, param: any in FS do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every From the Shadows number says where it's from", labelled)
	local def = AbilityConfig.Defs.fromtheshadows
	check(
		"Omen's X, an ultimate: 7 points (the wiki), its map in hand, played",
		def.slot == X
			and def.kind == "ultimate"
			and def.points ~= nil
			and def.points.value == 7
			and def.points.status == "community"
			and def.cost == nil
			and def.weapon == "shadowmap"
			and AbilitySim.playable("fromtheshadows")
	)
	check(
		"a 1.5 s windup, then 2.5 s as a Shade, and 0.5 s to put the map in hand (the wiki's game files)",
		FS.windup.value == 1.5
			and FS.windup.status == "community"
			and FS.shade.value == 2.5
			and FS.shade.status == "community"
			and MAP.equipTime.value == 0.5
	)
	check(
		"his arrival heard out to 22.5 m (Patch 0.49's 2250)",
		FS.heard.value == 22.5
			and FS.heard.status == "confirmed"
			and string.find(FS.heard.source, "2250", 1, true) ~= nil
			and near(FogOfWar.Edges.shade, 22.5, 1e-9)
	)
	check("the gun drawn again 4 s after it's fired, at the soonest", near(AbilityConfig.unequip("fromtheshadows"), 4, 1e-12))
	check(
		"its map, a weapon of the fifth slot that's never reloaded, with no alt fire",
		MAP.category == "ability"
			and MAP.slot == ULT
			and MAP.ability == "fromtheshadows"
			and MAP.magazine.value == 1
			and MAP.reserve.value == 0
			and MAP.alt == nil
			and MAP.name == "From the Shadows"
	)
	check("neither it nor its map is sold", Shop.item("fromtheshadows") == nil and Shop.item("shadowmap") == nil)
	check(
		"how high and how deep it looks for a floor, how far round, and how far he sees as a Shade, are ours",
		FS.top.status == "estimate" and FS.depth.status == "estimate" and FS.nudge.status == "estimate" and FS.sight.status == "estimate"
	)
	check(
		"the map over the high crates (2.0 m) and under the walls (5 m) and the arena's block (3.0 m)",
		FS.top.value > 2 and FS.top.value < 3
	)
	check(
		"its sounds: fired across the map, the Shade's arrival, forming and going back as far as Patch 0.49 has",
		SoundConfig.Abilities.shadows ~= nil
			and SoundConfig.CastCurves.shadows == "blast"
			and SoundConfig.CastCurves.shade == "shade"
			and SoundConfig.CastCurves.form == "shade"
			and SoundConfig.CastCurves.home == "shade"
			and SoundConfig.Weapons.shadowmap ~= nil
	)
end

-- The map in hand ------------------------------------------------------------------------------

do
	local p = newPlayer(nil, true)
	local _, casts = step(p, B.Ultimate)
	check("with its points short, X does nothing", #casts == 0 and p.sim.abilities.holding == 0)
end

do
	local p = newPlayer()
	local _, casts = step(p, B.Ultimate)
	local cast = casts[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("X puts its map in hand", cast ~= nil and cast.kind == "equip" and cast.ability == "fromtheshadows" and cast.slot == X)
	check("from the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "shadowmap" and w.back == 1)
	check("its points still there", kit.points == 7 and kit.holding == X and AbilitySim.charged(kit))
	p.point = THERE
	local waited: number? = nil
	for n = 1, ticks(1.5) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot), 0, 0, THERE), cfg, floor, DT)
		if probed and #ofKind(probed, "shadows") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"it can be fired once its 0.5 s equip is over",
		waited ~= nil and math.abs(waited - ticks(MAP.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	step(p, B.Ultimate)
	run(p, 0, ticks(1))
	check("X again puts it away, nothing spent", kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1 and kit.points == 7)
end

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	p.point = nil
	local _, casts = step(p, B.Fire)
	check(
		"fired with no place picked, nothing happens, and its map stays in hand",
		#casts == 0 and kit.holding == X and kit.points == 7 and w.loadout[ULT] == "shadowmap" and kit.shadowAt == 0
	)
	run(p, 0, ticks(0.2))
	local off = fire(p, vector.create(5000, 0, 0))
	check(
		"nor with the cursor where there's no floor",
		off == nil and kit.holding == X and kit.points == 7 and w.loadout[ULT] == "shadowmap" and w.ammo[ULT] == 1
	)
	run(p, 0, ticks(0.2))
	local closed: BarrierSim.Walls = { walls = {}, time = 0, closed = true }
	p.point = THERE
	local _, shut = step(p, B.Fire, nil, closed)
	check("nor in the buy phase", #shut == 0 and kit.holding == X and kit.points == 7)
	run(p, 0, ticks(0.2))
	check("so it can try again where there's somewhere", fire(p) ~= nil and kit.points == 0)
end

-- The teleport ----------------------------------------------------------------------------------

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	local from = p.sim.movement.position
	p.point = THERE
	local shots, casts = step(p, B.Fire)
	local fired = now(p)
	local cast = ofKind(casts, "shadows")[1]
	local to = if cast then cast.step else nil
	check("fire sends him", cast ~= nil and cast.ability == "fromtheshadows" and cast.slot == X)
	check("as a cast, not a bullet", #shots == 0)
	check(
		"to the floor under the place picked",
		to ~= nil and vector.magnitude(to - THERE) < 1e-4,
		if to then string.format("%.4f, %.4f, %.4f", to.x, to.y, to.z) else "none"
	)
	check("from where he stood", cast ~= nil and cast.position == from)
	check("its points spent, and its map gone", kit.points == 0 and kit.holding == 0 and w.loadout[ULT] == "")
	check(
		"the gun's put away until 4 s after at the soonest",
		near(w.equipEndTime - fired, 4, 1e-9),
		string.format("%.4f s", w.equipEndTime - fired)
	)
	check(
		"its windup's under way, which the kit says",
		AbilitySim.shadowing(kit, fired + DT)
			and AbilitySim.gathering(kit, fired + DT)
			and AbilitySim.busy(kit, fired + DT)
			and AbilitySim.ultimateOn(kit)
			and string.find(AbilitySim.summary(kit, fired + DT), "shadows", 1, true) ~= nil
	)
	local filled = AbilitySim.copy(kit)
	AbilitySim.fill(filled, true)
	check("and the course doesn't fill the points while it's under way", filled.points == 0)

	-- Through the windup: forward held, fire, every key and a turn.
	local still, nothing = true, true
	local shade: AbilitySim.Cast? = nil
	local shadeAt = 0
	local keys = { B.Forward + B.Fire, B.Forward + B.AbilityQ, B.Forward + B.AbilityE, B.Forward + B.Ultimate, B.Forward + B.Jump }
	local n = 0
	while not shade and n < ticks(3) do
		n += 1
		p.yaw += 0.01
		local s, c = step(p, keys[n % #keys + 1])
		shade = ofKind(c, "shade")[1]
		if shade then
			shadeAt = now(p)
			nothing = nothing and #s == 0 and #c == 1
		else
			nothing = nothing and #s == 0 and #c == 0
			still = still and vector.magnitude(p.sim.movement.position - from) < 1e-6
		end
	end
	check("through its windup he doesn't move, though he turns", still and p.yaw > 1)
	check("nor fire, nor cast anything, X included", nothing and kit.points == 0 and kit.shadowAt > 0)
	check(
		"and once its 1.5 s are up he's a Shade",
		shade ~= nil and shadeAt - fired >= FS.windup.value - 1e-9 and shadeAt - fired < FS.windup.value + DT,
		string.format("%.4f s", shadeAt - fired)
	)
	check("from where he was, to where it took him", shade ~= nil and shade.position == from and shade.step == to)
	check(
		"standing on that floor at once",
		to ~= nil and p.sim.movement.position == to and p.sim.movement.grounded and p.sim.movement.velocity == vector.zero
	)
	check(
		"a Shade, which the kit says",
		AbilitySim.shaded(kit, shadeAt)
			and not AbilitySim.gathering(kit, shadeAt)
			and string.find(AbilitySim.summary(kit, shadeAt), "shade", 1, true) ~= nil
	)

	-- A Shade: held where it took him, firing nothing.
	local formed, formedAt, stayed = until_(p, B.Forward + B.Jump + B.Fire, "form")
	check("as a Shade he's held there, nothing he presses moving him", stayed)
	check(
		"and 2.5 s later he's there for good",
		formed ~= nil and formedAt - shadeAt >= FS.shade.value - DT and formedAt - shadeAt <= FS.shade.value + DT,
		string.format("%.4f s", formedAt - shadeAt)
	)
	check(
		"the teleport over, and him free from that tick",
		formed ~= nil
			and to ~= nil
			and formed.position == to
			and not AbilitySim.shadowing(kit, formedAt)
			and kit.shadowAt == 0
			and not AbilitySim.ultimateOn(kit)
			and vector.magnitude(p.sim.movement.position - to) > 0
	)
	check(
		"his gun drawn again as he forms, a whole draw",
		w.equipped == 1 and near(w.equipEndTime - formedAt, VANDAL, 1e-9),
		string.format("%.4f s", w.equipEndTime - formedAt)
	)
	check("and the points don't come back", kit.points == 0)
end

-- Sent back ---------------------------------------------------------------------------------------

do
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	local from = p.sim.movement.position
	local cast = fire(p)
	local to = if cast then cast.step else nil
	-- X pressed in the windup does nothing, nor held into the Shade.
	run(p, 0, ticks(0.5))
	local _, early = step(p, B.Ultimate)
	local shade, _, _ = until_(p, B.Ultimate, "shade")
	check("X in the windup does nothing", #early == 0 and shade ~= nil and AbilitySim.shaded(kit, now(p)))
	local _, still = run(p, B.Ultimate, ticks(0.2))
	check("nor held on into his time as a Shade", #still == 0 and AbilitySim.shaded(kit, now(p)))
	step(p, 0)
	local _, casts = step(p, B.Ultimate)
	local home = ofKind(casts, "home")[1]
	local at = now(p)
	check("X again as a Shade sends him back", home ~= nil and home.ability == "fromtheshadows" and home.slot == X)
	check("from the Shade, to where he stood", home ~= nil and to ~= nil and home.position == from and home.step == to)
	check(
		"standing there at once, the teleport over",
		vector.magnitude(p.sim.movement.position - from) < 0.01 and kit.shadowAt == 0 and not AbilitySim.shadowing(kit, at)
	)
	check("his gun drawn again", w.equipped == 1 and near(w.equipEndTime - at, VANDAL, 1e-9))
	check("and its points spent all the same (Patch 1.0)", kit.points == 0)
	local _, after = run(p, B.Forward, ticks(0.5))
	check("free from then", #after == 0 and vector.magnitude(p.sim.movement.position - from) > 0.5)
end

do
	-- The server's word of an enemy's hit, between ticks.
	local p = inHand()
	local w, kit = p.sim.weapons, p.sim.abilities
	local from = p.sim.movement.position
	fire(p)
	run(p, 0, ticks(0.5))
	local look = Accuracy.aim(0, 0)
	check("in the windup there's no Shade to break", PlayerSim.home(p.sim, cfg, now(p), look) == nil and AbilitySim.gathering(kit, now(p)))
	until_(p, 0, "shade")
	run(p, 0, ticks(1))
	local t = now(p)
	local home = PlayerSim.home(p.sim, cfg, t, look)
	check(
		"a Shade an enemy hits is sent back where he stood",
		home ~= nil and home.kind == "home" and home.position == from and p.sim.movement.position == from
	)
	check("the teleport over, his gun drawn again", kit.shadowAt == 0 and w.equipped == 1 and near(w.equipEndTime - t, VANDAL, 1e-9))
	local _, after = run(p, B.Forward, ticks(0.5))
	check("and he's free from his next tick", #after == 0 and vector.magnitude(p.sim.movement.position - from) > 0.5)
	check("once he's formed there's none either", PlayerSim.home(p.sim, cfg, now(p), look) == nil)
end

do
	-- The spike planted a metre ahead: no defuse starts through it.
	local ctx: Spike.Context = {
		zones = Spike.CourseSites,
		canPlant = false,
		canDefuse = true,
		planted = vector.create(0, 0, -1),
		halfSaved = false,
	}
	local p = inHand()
	local probe = PlayerSim.copy(p.sim)
	PlayerSim.step(probe, input(B.Use, ask(p.sim, p.slot)), cfg, floor, DT, ctx)
	check("standing there, Use would start a defuse", probe.spike.channel == SpikeSim.DEFUSING)
	fire(p)
	local defusing = false
	for _ = 1, ticks(1) do
		step(p, B.Use, ctx)
		defusing = defusing or p.sim.spike.channel ~= SpikeSim.NONE
	end
	check("but through its windup none starts", not defusing and AbilitySim.gathering(p.sim.abilities, now(p)))
end

do
	-- Jumped and fired as he rises: through the windup he comes down where
	-- he is, and that's where a Shade's sent back to.
	local p = inHand()
	step(p, B.Jump)
	run(p, 0, 3)
	local before = p.sim.movement.position.y
	local cast = fire(p)
	run(p, 0, ticks(0.2))
	check("fired in the air, he rises and falls on through the windup", cast ~= nil and p.sim.movement.position.y ~= before)
	local shade = until_(p, 0, "shade")
	check(
		"and as a Shade he'd be sent back to the floor he came down on",
		shade ~= nil and near(shade.position.y, 0, 0.03) and near(p.sim.abilities.shadowFrom.y, 0, 0.03)
	)
end

-- Where it takes him ------------------------------------------------------------------------------

local GAP = cfg.halfWidth

do
	local to = ShadowSim.place(floor, vector.create(-12, 0, 40), cfg)
	check(
		"the floor under the place picked",
		to ~= nil and vector.magnitude(to - vector.create(-12, 0, 40)) < 1e-4,
		if to then string.format("%.4f, %.4f, %.4f", to.x, to.y, to.z) else "none"
	)
	local far = ShadowSim.place(floor, vector.create(600, 7, -600), cfg)
	check("however far away, and whatever height the place says", far ~= nil and near(far.y, 0, 1e-4) and near(far.x, 600, 1e-3))
	-- Crates 1.0 and 2.0 m tall, a block 3.0 m tall and a wall 5 m tall.
	local world = FakeWorld.new()
		:addFloor()
		:addBox(vector.create(-1, 0, -1), vector.create(1, 1, 1))
		:addBox(vector.create(9, 0, -1), vector.create(11, 2, 1))
		:addBox(vector.create(19, 0, -1), vector.create(21, 3, 1))
		:addBox(vector.create(29, 0, -6), vector.create(31, 5, 6))
	local low = ShadowSim.place(world, vector.create(0, 0, 0), cfg)
	local high = ShadowSim.place(world, vector.create(10, 0, 0), cfg)
	check(
		"onto a crate's top, the maps' high crates' too",
		low ~= nil and near(low.y, 1, 1e-4) and high ~= nil and near(high.y, 2, 1e-4),
		string.format("%s, %s", if low then tostring(low.y) else "none", if high then tostring(high.y) else "none")
	)
	check("never onto the block", ShadowSim.place(world, vector.create(20, 0, 0), cfg) == nil)
	check("nor onto a wall", ShadowSim.place(world, vector.create(30, 0, 0), cfg) == nil)
	local beside = ShadowSim.place(world, vector.create(29.1, 0, 0), cfg)
	check(
		"on a wall by its side, onto the floor beside it, clear of it",
		beside ~= nil and near(beside.y, 0, 1e-4) and beside.x <= 29 - GAP + 1e-6,
		if beside then string.format("%.3f m from it", 29 - beside.x) else "none"
	)
	local against = ShadowSim.place(world, vector.create(28.8, 0, 0), cfg)
	check(
		"against a wall, drawn off it until he fits",
		against ~= nil and against.x <= 29 - GAP + 1e-6 and against.x < 28.8,
		if against then string.format("%.3f m from it", 29 - against.x) else "none"
	)
	-- A slab 1.2 to 1.5 m over the floor is under where it looks from: its
	-- top is a floor, as a crate's is.
	local slab = FakeWorld.new():addFloor():addBox(vector.create(-6, 1.2, -6), vector.create(6, 1.5, 6))
	local onto = ShadowSim.place(slab, vector.zero, cfg)
	check("onto a slab's top, as a crate's", onto ~= nil and near(onto.y, 1.5, 1e-4), if onto then tostring(onto.y) else "none")
	-- A roof 1.2 m over the floor, up past where it looks from: too low to
	-- stand under, and too wide to find room round.
	local roof = FakeWorld.new():addFloor():addBox(vector.create(-6, 1.2, -6), vector.create(6, 4, 6))
	check("under a roof lower than he stands there's nowhere", ShadowSim.place(roof, vector.zero, cfg) == nil)
	local platform = FakeWorld.new():addBox(vector.create(-1, -1, -1), vector.create(1, 0, 1))
	check("nor with no floor", ShadowSim.place(platform, vector.create(5, 0, 5), cfg) == nil)
	local deep = FakeWorld.new():addBox(vector.create(-30, -30, -30), vector.create(30, -25, 30))
	check("nor where the floor's deeper than it looks", ShadowSim.place(deep, vector.zero, cfg) == nil)
end

do
	local s0, s1, s2, s3 = ShadowSim.sight(0), ShadowSim.sight(0.25), ShadowSim.sight(0.5), ShadowSim.sight(0.75)
	check("as a Shade he sees nothing at first", s0 == 0)
	check(
		"then further and further, faster towards the end (the wiki)",
		s1 ~= nil and s2 ~= nil and s3 ~= nil and s1 > 0 and s2 > s1 and s3 > s2 and s3 - s2 > s2 - s1
	)
	check("up to 10 m, ours", near(ShadowSim.sight(0.999) or 0, FS.sight.value, 0.05))
	check("and then as far as anyone", ShadowSim.sight(1) == nil)
end

-- A new life ----------------------------------------------------------------------------------

do
	local p = inHand()
	fire(p)
	local kit = p.sim.abilities
	run(p, 0, ticks(2))
	AbilitySim.settle(kit)
	check(
		"a new life or round ends it",
		kit.shadowAt == 0 and kit.shadowTo == vector.zero and kit.shadowFrom == vector.zero and not AbilitySim.shadowing(kit, now(p))
	)
end

-- The course's map --------------------------------------------------------------------------------

do
	local shapes: { Minimap.Shape } = {
		{ kind = "floor", center = vector.create(0, 0, 0), size = vector.create(80, 0, 80), yaw = 0 },
		{ kind = "floor", center = vector.create(2, 0, -50), size = vector.create(24, 0, 24), yaw = 0 },
		{ kind = "wall", center = vector.create(0, 0, 39), size = vector.create(80, 0, 2), yaw = 0 },
		{ kind = "cover", center = vector.create(10, 0, 0), size = vector.create(2, 0, 2), yaw = 0, high = true },
		{ kind = "floor", center = vector.create(60, 0, 0), size = vector.create(10, 0, 2), yaw = math.pi / 2 },
	}
	local plan = Minimap.planOf("course", shapes)
	check(
		"the course's map: its floors' extent, a turned one's as turned",
		plan ~= nil
			and plan.family == "course"
			and near(plan.x0, -40, 1e-9)
			and near(plan.x1, 61, 1e-9)
			and near(plan.z0, -62, 1e-9)
			and near(plan.z1, 40, 1e-9)
			and #plan.shapes == 5
	)
	if plan then
		local m = Minimap.Params.margin.value
		check(
			"a place on it, or in the margin round it, is on the map, and further out isn't",
			Minimap.holds(plan, vector.create(0, 50, 0))
				and Minimap.holds(plan, vector.create(-40 - m + 0.01, 0, 0))
				and not Minimap.holds(plan, vector.create(-40 - m - 0.01, 0, 0))
				and not Minimap.holds(plan, vector.create(0, 0, 40 + m + 0.01))
		)
		local held = Minimap.held(plan, vector.create(-100, 7, 100))
		check(
			"the cursor pushed off the map is held at its edge, on the floor",
			near(held.x, -40 - m, 1e-9) and near(held.z, 40 + m, 1e-9) and held.y == 0
		)
		local on = Minimap.held(plan, vector.create(5, 0, -5))
		check("and on it, it's where it is", near(on.x, 5, 1e-6) and near(on.z, -5, 1e-6))
	end
	check("with no floor, no map", Minimap.planOf("none", { shapes[3] }) == nil)
	-- The cursor: where on the screen it's moved to, back to the floor,
	-- however the map's turned.
	local view: Minimap.View = { centre = vector.create(3, 0, -4), turn = 0.7, scale = 6, half = 300 }
	local x, y = Minimap.toView(view, vector.create(10, 0, 12))
	local under = Minimap.fromView(view, x, y)
	check("the place under a point on a turned map is the place shown there", near(under.x, 10, 1e-4) and near(under.z, 12, 1e-4))
	local up = Minimap.fromView({ centre = vector.zero, turn = 0, scale = 2, half = 100 }, 0, -10)
	check("up an unturned map is -z, 2 pixels a metre", near(up.x, 0, 1e-9) and near(up.z, -5, 1e-9))
	local quarry = Minimap.planFor("spike", "quarry")
	check(
		"and a match's map holds its own floor but not the course",
		quarry ~= nil and Minimap.holds(quarry, Minimap.middle(quarry)) and not Minimap.holds(quarry, vector.zero)
	)
end

-- The wire -------------------------------------------------------------------------------------

do
	local inputs: { PlayerCodec.WireInput } = {
		{ seq = 1, buttons = B.Fire, slot = 5, yaw = 0.5, pitch = 0.1, viewTime = 12.5, point = vector.create(-312.37, 0, 41.06) },
		{ seq = 2, buttons = 0, slot = 1, yaw = 0, pitch = 0, viewTime = 12.6 },
		{ seq = 3, buttons = B.Fire, slot = 5, yaw = 0, pitch = 0, viewTime = 12.7, point = vector.create(0.001, 0, -0.5) },
	}
	local wire = PlayerCodec.encodeInputs(inputs, 1, 3)
	local decoded = PlayerCodec.decodeInputs(wire)
	check("a place on the map takes 8 bytes more", buffer.len(wire) == 19 * 3 + 8 * 2)
	check(
		"and gets to the server exactly, with its slot, and none where there's none",
		decoded ~= nil
			and #decoded == 3
			and decoded[1].point == inputs[1].point
			and decoded[1].slot == 5
			and decoded[2].point == nil
			and decoded[2].slot == 1
			and decoded[3].point == inputs[3].point
			and decoded[3].seq == 3
	)
	local function bad(point: vector): boolean
		return PlayerCodec.decodeInputs(
			PlayerCodec.encodeInputs({ { seq = 1, buttons = 0, slot = 5, yaw = 0, pitch = 0, viewTime = 0, point = point } }, 1, 1)
		) == nil
	end
	check(
		"a place that isn't a number, or is off past any map, is rejected",
		bad(vector.create(0 / 0, 0, 0)) and bad(vector.create(0, 0, math.huge)) and bad(vector.create(2e6, 0, 0))
	)
	local cut = buffer.create(19 + 4)
	buffer.copy(cut, 0, wire, 0, 23)
	check("and so is one cut short", PlayerCodec.decodeInputs(cut) == nil)
	check("the client keeps its place as the wire does", PlayerCodec.quantizePoint(vector.create(1.5, 9, -2)) == vector.create(1.5, 0, -2))
end

do
	local p = inHand()
	p.point = vector.create(-7.3, 0, -21.9)
	step(p, B.Fire)
	run(p, B.Forward, ticks(0.6))
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	local a, b = p.sim.abilities, decoded.abilities
	check(
		"the ack carries its windup and where it takes him",
		b.shadowAt == a.shadowAt and b.shadowTo == a.shadowTo and b.shadowFrom == a.shadowFrom and a.shadowAt > 0
	)
	local copy: Player = { sim = decoded :: PlayerSim.State, slot = p.slot, yaw = p.yaw, pitch = p.pitch, point = p.point, world = floor }
	local same, ends = true, 0
	for i = 1, ticks(4) do
		local buttons = if i % 40 < 20 then B.Forward else B.Left + B.Fire
		local _, c1 = step(p, buttons)
		local _, c2 = step(copy, buttons)
		ends += #ofKind(c1, "shade") + #ofKind(c1, "form")
		same = same
			and #c1 == #c2
			and p.sim.movement.position == copy.sim.movement.position
			and p.sim.weapons.equipEndTime == copy.sim.weapons.equipEndTime
	end
	check("and a replay from it becomes a Shade and forms as it does", same and ends == 2)

	local q = inHand()
	fire(q)
	until_(q, 0, "shade")
	run(q, 0, ticks(0.3))
	local _, shaded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(10, q.sim))
	check(
		"the ack carries him a Shade, and where he'd be sent back to",
		AbilitySim.shaded(shaded.abilities, now(q))
			and shaded.abilities.shadowFrom == q.sim.abilities.shadowFrom
			and shaded.movement.position == q.sim.movement.position
	)
	local left: Player = { sim = shaded :: PlayerSim.State, slot = q.slot, yaw = q.yaw, pitch = q.pitch, point = nil, world = floor }
	local alike = true
	for i = 1, ticks(1) do
		local buttons = if i == 20 then B.Ultimate else 0
		local _, c1 = step(q, buttons)
		local _, c2 = step(left, buttons)
		alike = alike and #c1 == #c2 and q.sim.movement.position == left.sim.movement.position
	end
	check("and a replay from it is sent back as it is", alike and q.sim.abilities.shadowAt == 0)
end

do
	local pose: PlayerCodec.Pose = {
		id = 7,
		position = vector.create(3, 0, -30),
		yaw = 0.4,
		pitch = 0,
		crouchAlpha = 0,
		grounded = true,
		alive = true,
		quiet = true,
		reloading = false,
		weapon = 0,
		channel = 0,
		gliding = false,
		shade = true,
	}
	local _, poses = PlayerCodec.decodeSnapshot(PlayerCodec.encodeSnapshot(1, { pose }))
	check(
		"a snapshot says who's a Shade",
		poses[1].shade == true and PlayerCodec.quantizePose(pose).shade == true and poses[1].gliding == false and poses[1].quiet == true
	)
	local before = table.clone(pose)
	before.position = vector.create(0, 0, 0)
	before.shade = false
	local h = PoseHistory.new()
	PoseHistory.push(h, 1, before)
	PoseHistory.push(h, 1 + 1 / 30, pose)
	local mid = PoseHistory.sample(h, 1 + 1 / 60)
	local last = PoseHistory.sample(h, 1 + 1 / 30)
	check(
		"and between the snapshots either side of becoming one, he's where he was, never on the way",
		mid ~= nil and mid.pose.position == before.position and last ~= nil and last.pose.position == pose.position
	)
	local walked = table.clone(before)
	walked.position = vector.create(0.1, 0, 0)
	local g = PoseHistory.new()
	PoseHistory.push(g, 1, before)
	PoseHistory.push(g, 1 + 1 / 30, walked)
	local between = PoseHistory.sample(g, 1 + 1 / 60)
	check(
		"while anyone else is blended as ever",
		between ~= nil and near(between.pose.position.x, 0.05, 1e-6) and between.pose.shade == false
	)
end

return nil
