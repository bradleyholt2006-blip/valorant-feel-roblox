--!strict
-- Sage's Resurrection (system 39): its numbers and where they come from,
-- the orb in hand (X once the ultimate's points are full, its equip, fire's
-- tries, a click at a time, the orb staying in hand through them, the
-- points spent and the orb put away as the server finds one brings someone
-- back, X again and whatever else is drawn putting it away untried), the
-- bodies and who a try brings back (the crosshair over a fallen ally lying
-- on the floor, within its width and reach, the first along it in sight),
-- the return's times, the life it brings back held (rising with the body,
-- then falling to the floor, nothing pressed doing anything until control's
-- back), the rules counting them alive again, and the wire carrying it.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local ReviveSim = require("../src/shared/Abilities/ReviveSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local MatchRules = require("../src/shared/Match/MatchRules")
local ArenaRules = require("../src/shared/Arena/ArenaRules")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local RES = AbilityConfig.Resurrection
local ORB = WeaponConfig.Defs.revive
local ULT = WeaponSim.ULT
local X = AbilityConfig.X
local SAGE = "sage"

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

-- A player and the slot their client asks for.
type Player = { sim: PlayerSim.State, slot: number }

-- The slot the client asks for this tick, by PlayerController's rules (as
-- the Healing Orb tests have them).
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

-- One tick, the slot asked for as the client would; returns its bullets
-- and its casts.
local function step(p: Player, buttons: number, yaw: number?, pitch: number?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	p.slot = ask(p.sim, p.slot)
	local shots, _, _, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot, yaw, pitch), cfg, floor, DT)
	return shots or {}, casts or {}
end

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

local function now(p: Player): number
	return p.sim.movement.tick * DT
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

-- Sage settled on the floor with the Vandal drawn and her ultimate's points
-- full, as the course has them.
local function newPlayer(): Player
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(SAGE)
	AbilitySim.fill(sim.abilities, true)
	local p = { sim = sim, slot = 1 }
	run(p, 0, ticks(1.5))
	return p
end

-- X tapped, and the orb's equip waited out.
local function inHand(): Player
	local p = newPlayer()
	step(p, B.Ultimate)
	run(p, 0, ticks(ORB.equipTime.value) + 1)
	return p
end

local NOTHING = function(_a: vector, _b: vector): boolean
	return false
end

H.section("Resurrection tests")

-- Its numbers ----------------------------------------------------------------------------------

do
	check(
		"12 m of reach (Patch 11.04's '6m >>> 12m'), confirmed; its width ours",
		RES.reach.value == 12 and RES.reach.status == "confirmed" and RES.width.value == 0.5 and RES.width.status == "estimate"
	)
	check(
		"the wiki's times from the game files: a 0.8 s equip, a 1 s unequip, 2 s rising and 1.3 s falling",
		ORB.equipTime.value == 0.8
			and ORB.equipTime.status == "community"
			and RES.unequip.value == 1
			and AbilityConfig.unequip("resurrection") == 1
			and RES.rise.value == 2
			and RES.fall.value == 1.3
			and RES.rise.status == "community"
			and RES.fall.status == "community"
	)
	check("how high the body rises is ours", RES.height.value == 0.5 and RES.height.status == "estimate")
	local def = AbilityConfig.Defs.resurrection
	check(
		"the ultimate, 7 points (Patch 9.10), its orb a weapon of its own in the fifth slot",
		def.kind == "ultimate"
			and def.points ~= nil
			and def.points.value == 7
			and def.weapon == "revive"
			and ORB.slot == 5
			and ORB.category == "ability"
			and ORB.ability == "resurrection"
	)
	check("it can be played", AbilitySim.playable("resurrection"))
	check(
		"the orb is last on the wire",
		WeaponConfig.Ids[#WeaponConfig.Ids] == "revive" and WeaponConfig.IndexOf.revive == #WeaponConfig.Ids
	)
	check("a click a try, ten a second at most, and no bullet's damage", ORB.fireMode == "semi" and ORB.fireRate.value == 10)
end

-- In hand --------------------------------------------------------------------------------------

do
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(SAGE)
	AbilitySim.fill(sim.abilities)
	local p = { sim = sim, slot = 1 }
	run(p, 0, ticks(1))
	sim.abilities.points = 6
	local _, casts = step(p, B.Ultimate)
	check("with its points short, X does nothing", #casts == 0 and sim.abilities.holding == 0 and sim.weapons.equipped == 1)
end

do
	local p = newPlayer()
	local _, casts = step(p, B.Ultimate)
	local cast = casts[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check(
		"with them full, X puts the orb in hand",
		cast ~= nil and cast.kind == "equip" and cast.ability == "resurrection" and cast.slot == X
	)
	check("from the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "revive" and w.back == 1)
	check("its points still there", kit.points == 7 and kit.holding == X)
	check("the kit says it's in hand", string.find(AbilitySim.summary(kit, now(p)), "equip", 1, true) ~= nil)
	local waited: number? = nil
	for n = 1, ticks(2) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot)), cfg, floor, DT)
		if probed and #ofKind(probed, "revive") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"it can be tried once its 0.8 s equip is over",
		waited ~= nil and math.abs(waited - ticks(ORB.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
end

do
	local p = inHand()
	local yaw, pitch = -0.3, -0.4
	local shots, casts = step(p, B.Fire, yaw, pitch)
	local try = ofKind(casts, "revive")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("fire tries it on a body", try ~= nil and try.ability == "resurrection" and try.slot == X)
	check(
		"from the eye, along the crosshair",
		try ~= nil
			and vector.magnitude(try.origin - PlayerSim.eye(p.sim, cfg)) < 1e-6
			and vector.magnitude(try.direction - Accuracy.aim(yaw, pitch)) < 1e-6
	)
	check("as a cast, not a bullet", #shots == 0)
	check(
		"its points kept, and the orb still in hand",
		kit.points == 7 and kit.holding == X and w.equipped == ULT and w.loadout[ULT] == "revive"
	)
	check("ready for the next try", w.ammo[ULT] == 1)
	local _, held = run(p, B.Fire, ticks(1))
	check("held, it tries no more", #ofKind(held, "revive") == 0 and kit.holding == X)
	step(p, 0)
	local _, again = step(p, B.Fire)
	check("a click tries it again", #ofKind(again, "revive") == 1 and kit.points == 7)
	step(p, 0)
	local shots2, alt = step(p, B.AltFire)
	check("alt fire tries nothing", #alt == 0 and #shots2 == 0 and kit.holding == X)
end

do
	local p = inHand()
	local _, casts = step(p, B.Fire)
	local try = ofKind(casts, "revive")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	-- The server finds it brings someone back (ReviveServer), between ticks.
	AbilitySim.used(kit, try.slot)
	WeaponSim.putAway(w, try.time, AbilityConfig.unequip(try.ability))
	check("a try that brings someone back spends the points", kit.points == 0 and kit.holding == 0 and kit.charges[X] == 0)
	check("and the gun's back in hand 1 s after it", w.loadout[ULT] == "" and w.equipped == 1 and near(w.equipEndTime - try.time, 1, 1e-9))
	local _, more = run(p, B.Fire, ticks(1))
	check("nothing more is tried", #ofKind(more, "revive") == 0)
	local _, again = step(p, B.Ultimate)
	check("and with its points gone, X does nothing", #again == 0 and kit.holding == 0 and w.equipped == 1)
end

do
	local p = newPlayer()
	step(p, B.Ultimate)
	run(p, 0, 10)
	local _, casts = step(p, B.Ultimate)
	local w, kit = p.sim.weapons, p.sim.abilities
	check("X again puts it away untried", #casts == 0 and kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1)
	check("its points kept", kit.points == 7)
end

do
	local p = inHand()
	p.slot = 2
	step(p, 0)
	local w, kit = p.sim.weapons, p.sim.abilities
	check("drawing a gun puts it away", kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 2 and kit.points == 7)
end

do
	local p = inHand()
	local kit = p.sim.abilities
	-- Points taken back between ticks (the server's kit for a new mode).
	kit.points = 3
	step(p, 0)
	check("its points short again, it goes", kit.holding == 0 and p.sim.weapons.loadout[ULT] == "")
end

do
	local p = newPlayer()
	step(p, B.Ultimate)
	local _, casts = run(p, B.Fire, ticks(ORB.equipTime.value) + 2)
	check("fire held from X on doesn't try it: a try's a click once it's in hand", #ofKind(casts, "revive") == 0)
	step(p, 0)
	local _, clicked = step(p, B.Fire)
	check("and the click does", #ofKind(clicked, "revive") == 1)
end

-- The bodies, and who a try brings back --------------------------------------------------------

local function body(id: number, feet: vector, yaw: number?): ReviveSim.Body
	return { id = id, feet = feet, yaw = yaw or 0 }
end

do
	check("a body lies as long as they stood, 1.75 m", near(ReviveSim.LENGTH, 1.75, 1e-9))
	local blocks = ReviveSim.blocks(body(1, vector.create(0, 0, -6)))
	local head, chest, legs = blocks[1], blocks[2], blocks[3]
	check(
		"head, body and legs, laid along the way they faced, its middle where they fell",
		head.region == "head"
			and chest.region == "body"
			and legs.region == "legs"
			and head.center.z < chest.center.z
			and chest.center.z < legs.center.z
			and near(head.center.z, -6 - (1.62 - 0.875), 1e-5)
			and near(legs.center.z, -6 - (0.425 - 0.875), 1e-5)
	)
	check(
		"lying on the floor: each as high as it was deep, as long as it stood tall",
		near(chest.center.y, chest.half.y, 1e-6)
			and near(chest.half.y, 0.14, 1e-6)
			and near(chest.half.z, 0.32, 1e-6)
			and near(chest.half.x, 0.22, 1e-6)
	)
	local turned = ReviveSim.blocks(body(1, vector.create(0, 0, -6), math.pi / 2))
	check("facing another way, they lie along it", near(turned[1].center.x, -(1.62 - 0.875), 1e-5) and near(turned[1].center.z, -6, 1e-5))
end

do
	local eye = vector.create(0, 1.6, 0)
	local function at(x: number, y: number, z: number): vector
		return vector.normalize(vector.create(x, y, z) - eye)
	end
	local fallen = body(7, vector.create(0, 0, -6))
	check("the crosshair on a body on the floor brings them back", ReviveSim.aimedAt(eye, at(0, 0.14, -6), { fallen }, NOTHING) == 7)
	check(
		"anywhere along it, its head or its feet",
		ReviveSim.aimedAt(eye, at(0, 0.14, -6.85), { fallen }, NOTHING) == 7
			and ReviveSim.aimedAt(eye, at(0, 0.14, -5.15), { fallen }, NOTHING) == 7
	)
	check(
		"within its width of it it's still over them, past it not",
		ReviveSim.aimedAt(eye, at(0.4, 0.14, -6), { fallen }, NOTHING) == 7
			and ReviveSim.aimedAt(eye, at(0.7, 0.14, -6), { fallen }, NOTHING) == nil
	)
	check("looking level, over them, it isn't", ReviveSim.aimedAt(eye, vector.create(0, 0, -1), { fallen }, NOTHING) == nil)
	local across = body(8, vector.create(0, 0, -6), math.pi / 2)
	check(
		"lying across the view, as far along them as they're long",
		ReviveSim.aimedAt(eye, at(1, 0.14, -6), { across }, NOTHING) == 8
			and ReviveSim.aimedAt(eye, at(1.8, 0.14, -6), { across }, NOTHING) == nil
	)
	local inReach = body(9, vector.create(0, 0, -11))
	local outOfReach = body(9, vector.create(0, 0, -14))
	check(
		"within its 12 m, and not past it",
		ReviveSim.aimedAt(eye, at(0, 0.14, -11), { inReach }, NOTHING) == 9
			and ReviveSim.aimedAt(eye, at(0, 0.14, -14), { outOfReach }, NOTHING) == nil
	)
	local front = body(1, vector.create(0, 0, -4))
	local back = body(2, vector.create(0, 0, -6))
	local low = at(0, 0.14, -5)
	check("of two along the crosshair, the nearer", ReviveSim.aimedAt(eye, low, { back, front }, NOTHING) == 1)
	local hidesFront = function(_a: vector, b: vector): boolean
		return b.z > -4.9
	end
	check("the nearer hidden, the one behind", ReviveSim.aimedAt(eye, low, { back, front }, hidesFront) == 2)
	local hidesAll = function(_a: vector, _b: vector): boolean
		return true
	end
	check("nobody in sight, nobody", ReviveSim.aimedAt(eye, low, { back, front }, hidesAll) == nil)
	local headShows = function(_a: vector, b: vector): boolean
		return b.z > -6.5
	end
	check("one whose head shows past cover is in sight", ReviveSim.aimedAt(eye, at(0, 0.14, -6), { fallen }, headShows) == 7)
	check("and nobody fallen, nobody", ReviveSim.aimedAt(eye, at(0, 0.14, -6), {}, NOTHING) == nil)
end

-- The return -----------------------------------------------------------------------------------

do
	check(
		"cast at 10, they burst out at 12 and have control back at 13.3",
		ReviveSim.burstAt(10) == 12 and near(ReviveSim.backAt(10), 13.3, 1e-9)
	)
	check(
		"the body rises steadily to its height as they burst out, and no higher",
		ReviveSim.risen(10, 10) == 0
			and near(ReviveSim.risen(10, 11), 0.25, 1e-9)
			and near(ReviveSim.risen(10, 12), 0.5, 1e-9)
			and ReviveSim.risen(10, 15) == 0.5
	)
	check("their shield broken, the kind they wore kept", ReviveSim.UNSHIELDED.shield == 0 and ReviveSim.UNSHIELDED.pool == 0)
end

-- A life brought back held as the server starts it: rising 1.5 s more with
-- the body, then falling for the rest, 1.3 s.
local function revived(): Player
	local sim = PlayerSim.new(vector.create(0, 0.05, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(SAGE)
	sim.abilities.floatUntil = 1.5
	sim.abilities.heldUntil = 1.5 + RES.fall.value
	return { sim = sim, slot = 1 }
end

do
	local p = revived()
	local m, kit = p.sim.movement, p.sim.abilities
	check("the kit says it's held", string.find(AbilitySim.summary(kit, DT), "revived", 1, true) ~= nil)
	local shots, casts = run(p, bit32.bor(B.Forward, B.Fire, B.Jump, B.AbilityE), ticks(1))
	check(
		"rising with the body at its steady speed, 0.25 m a second, nothing pressed moving them",
		near(m.position.y, 0.05 + 0.25, 1e-6) and m.position.x == 0 and m.position.z == 0,
		string.format("%.4f", m.position.y)
	)
	check("nothing fires and nothing's cast", #shots == 0 and #casts == 0 and kit.charges[AbilityConfig.E] == 1)
	run(p, B.Forward, ticks(0.5) - 1)
	check("to the top as they burst out", near(m.position.y, 0.05 + 0.375, 0.25 * DT), string.format("%.4f", m.position.y))
	local fired = run(p, bit32.bor(B.Forward, B.Fire), ticks(0.8))
	check("then they fall to the floor", m.grounded and m.position.y < 0.05, string.format("%.4f", m.position.y))
	check("held there: still nothing pressed moves them or fires", #fired == 0 and m.position.x == 0 and m.position.z == 0)
	-- On to the last tick it's held.
	run(p, 0, math.ceil(kit.heldUntil / DT) - 1 - p.sim.movement.tick)
	check(
		"until control's back, 1.3 s after they burst out",
		AbilitySim.reviving(kit, now(p)) and not AbilitySim.reviving(kit, now(p) + DT)
	)
	check("and the kit says so", string.find(AbilitySim.summary(kit, now(p) + DT), "revived", 1, true) == nil)
	local back = run(p, B.Fire, 1)
	run(p, B.Forward, ticks(0.2))
	check("then the gun's ready, and they move", #back == 1 and m.position.z < -0.1, tostring(#back))
	local s = AbilitySim.new(SAGE)
	s.floatUntil, s.heldUntil = 2, 3
	AbilitySim.settle(s)
	check("a new life or round has nothing held", s.floatUntil == 0 and s.heldUntil == 0)
end

-- The rules ------------------------------------------------------------------------------------

do
	local s = MatchRules.new()
	for _, id in { 1, 2, 3, 4 } do
		MatchRules.join(s, id, 0)
	end
	check("in the buy phase, nobody's brought back", not MatchRules.canRevive(s, 1, 3))
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.died(s, 3, 50)
	check("in the round, a fallen ally can be", MatchRules.canRevive(s, 1, 3))
	check(
		"not an enemy, nor anyone standing",
		not MatchRules.canRevive(s, 2, 3) and not MatchRules.canRevive(s, 3, 1) and not MatchRules.canRevive(s, 1, 2)
	)
	check("brought back, they're alive again", MatchRules.revived(s, 3) and s.members[3].alive and not MatchRules.revived(s, 3))
	MatchRules.died(s, 3, 60)
	MatchRules.died(s, 1, 61)
	check("and both down after, the round's over", s.phase == "roundOver")
	check("nobody's brought back once it is", not MatchRules.canRevive(s, 1, 3) and not MatchRules.revived(s, 3))
end

do
	local s = MatchRules.new()
	for _, id in { 1, 2, 3, 4 } do
		MatchRules.join(s, id, 0)
	end
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.died(s, 3, 50)
	MatchRules.planted(s, 100)
	check("with the spike planted, still", MatchRules.canRevive(s, 1, 3) and MatchRules.revived(s, 3))
end

do
	local s = ArenaRules.new()
	for _, id in { 1, 2, 3, 4 } do
		ArenaRules.join(s, id, 0)
	end
	check("in Skirmish too: not in the buy phase", not ArenaRules.canRevive(s, 1, 3))
	ArenaRules.step(s, s.phaseEndsAt)
	ArenaRules.died(s, 3, 30)
	check(
		"but a fallen ally in the round, not an enemy",
		ArenaRules.canRevive(s, 1, 3) and not ArenaRules.canRevive(s, 2, 3) and not ArenaRules.canRevive(s, 4, 3)
	)
	check("alive again", ArenaRules.revived(s, 3) and s.members[3].alive)
end

-- The wire -------------------------------------------------------------------------------------

do
	local p = inHand()
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	check(
		"the ack carries the orb in hand, and the points",
		decoded.abilities.holding == X and decoded.abilities.points == 7 and decoded.weapons.loadout[ULT] == "revive"
	)
	local r = revived()
	local _, back = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, r.sim))
	check(
		"and a life brought back, when it's held until",
		back.abilities.floatUntil == r.sim.abilities.floatUntil and back.abilities.heldUntil == r.sim.abilities.heldUntil
	)
end

return nil
