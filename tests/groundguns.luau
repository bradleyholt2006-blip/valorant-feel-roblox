--!strict
-- Guns on the ground (system 15): what can lie there and what the dead drop,
-- putting guns down and taking them up, walking over one, the one in view,
-- G letting go of the gun in hand as PlayerSim steps it, and what a gun
-- picked up keeps.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local GroundGuns = require("../src/shared/Weapons/GroundGuns")
local Shop = require("../src/shared/Weapons/Shop")
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
local P = GroundGuns.Params
local ORIGIN = vector.create(0, 0.02, 10)

local function input(buttons: number, slot: number, yaw: number?)
	return { seq = 0, buttons = buttons, slot = slot, yaw = yaw or 0, pitch = 0, viewTime = 0 }
end

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

-- A player settled on the floor with `loadout`, holding its first weapon.
local function newPlayer(loadout: { string }): PlayerSim.State
	local s = PlayerSim.new(ORIGIN, loadout)
	for _ = 1, 40 do
		PlayerSim.step(s, input(0, s.weapons.equipped), cfg, floor, DT)
	end
	return s
end

-- Steps `n` ticks with the same buttons and slot; returns every gun let go
-- of and every spike act.
local function run(
	s: PlayerSim.State,
	buttons: number,
	n: number,
	slot: number,
	ctx: Spike.Context?
): ({ WeaponSim.Dropped }, { SpikeSim.Act })
	local dropped, acts = {}, {}
	for _ = 1, n do
		local _, _, act, gun = PlayerSim.step(s, input(buttons, slot), cfg, floor, DT, ctx)
		if gun then
			table.insert(dropped, gun)
		end
		if act then
			table.insert(acts, act)
		end
	end
	return dropped, acts
end

H.section("Guns on the ground")

-- The numbers -----------------------------------------------------------------------------

do
	local ok = true
	for name, param in P :: { [string]: GroundGuns.Param } do
		if not (param.status == "confirmed" or param.status == "community" or param.status == "estimate") or param.source == "" then
			ok = false
			print("    no status or source: " .. name)
		end
	end
	check("every number has a status and a source", ok)
end

-- What can lie there -----------------------------------------------------------------------

do
	check(
		"a primary goes in slot 1",
		GroundGuns.slotOf("vandal") == 1 and GroundGuns.slotOf("operator") == 1 and GroundGuns.slotOf("odin") == 1
	)
	check("a sidearm in slot 2", GroundGuns.slotOf("classic") == 2 and GroundGuns.slotOf("sheriff") == 2)
	check(
		"the knife, the spike, Blade Storm's knives, Curveball's flare, Hot Hands' fireball and Blaze's flame never lie there",
		GroundGuns.slotOf("knife") == nil
			and GroundGuns.slotOf("spike") == nil
			and GroundGuns.slotOf("kunai") == nil
			and GroundGuns.slotOf("flare") == nil
			and GroundGuns.slotOf("fireball") == nil
			and GroundGuns.slotOf("flamewall") == nil
	)
	check("nor does anything that isn't a weapon", GroundGuns.slotOf("") == nil and GroundGuns.slotOf("regen") == nil)
	local everyGun = true
	for id, def in WeaponConfig.Defs do
		local slot = GroundGuns.slotOf(id)
		local gun = not def.melee and not def.spike and not def.ultimate and not def.ability
		if (slot ~= nil) ~= gun or (slot ~= nil and slot ~= def.slot) then
			everyGun = false
			print("    " .. id)
		end
	end
	check("every gun can, in its own slot", everyGun)
end

do
	check("the dead drop their primary", GroundGuns.deathSlot({ "vandal", "classic", "knife", "spike" }) == 1)
	check("or their sidearm if they have no primary", GroundGuns.deathSlot({ "", "classic", "knife", "" }) == 2)
	check("and nothing with neither", GroundGuns.deathSlot({ "", "", "knife", "spike" }) == nil)
end

-- Putting them down and taking them up ------------------------------------------------

do
	local s = GroundGuns.new()
	local a = GroundGuns.add(s, "vandal", 20, 50, vector.create(0, 0, 0), 0, 1)
	local b = GroundGuns.add(s, "classic", 12, 36, vector.create(2, 0, 0), 0, 2)
	check("each gun put down gets an id of its own", a.id ~= b.id and s.guns[a.id] == a and s.guns[b.id] == b)
	check("and keeps its rounds", a.ammo == 20 and a.reserve == 50)
	local version = s.version
	check("taking one up hands it over", GroundGuns.remove(s, a.id) == a and s.guns[a.id] == nil and s.version > version)
	version = s.version
	check("a gun already gone can't be taken again", GroundGuns.remove(s, a.id) == nil and s.version == version)
	GroundGuns.clear(s)
	check("clearing the ground takes the rest", next(s.guns) == nil and s.version > version)
	version = s.version
	GroundGuns.clear(s)
	check("and clearing it bare changes nothing", s.version == version)
end

do
	local s = GroundGuns.new()
	local max = P.maxGuns.value
	for i = 1, max + 1 do
		GroundGuns.add(s, "classic", 12, 36, vector.create(i, 0, 0), 0, i)
	end
	local count = 0
	for _ in s.guns do
		count += 1
	end
	check("with too many on the ground, the oldest goes", count == max and s.guns[1] == nil and s.guns[max + 1] ~= nil)

	-- A weapon spawner's gun (Team Deathmatch, system 28) stays, the oldest
	-- or not.
	local spawned = GroundGuns.new()
	local first = GroundGuns.add(spawned, "stinger", 20, 60, vector.create(0, 0.1, 0), 0, 0, 1)
	for i = 1, max do
		GroundGuns.add(spawned, "classic", 12, 36, vector.create(i, 0, 0), 0, i)
	end
	check(
		"a weapon spawner's gun is marked with its spawner, and never the one to go",
		first.spawner == 1 and spawned.guns[first.id] ~= nil and spawned.guns[2] == nil
	)
end

-- Walking over one ----------------------------------------------------------------------

do
	local feet = vector.create(0, 0, 0)
	check("standing on it is walking over it", GroundGuns.walksOver(feet, vector.create(0.5, 0, 0.3)))
	check("but not beside it", not GroundGuns.walksOver(feet, vector.create(0.6, 0, 0.6)))
	check("nor a floor below", not GroundGuns.walksOver(feet, vector.create(0, -1.5, 0)))
	local s = GroundGuns.new()
	local far = GroundGuns.add(s, "vandal", 25, 50, vector.create(0.5, 0, 0), 0, 0)
	local close = GroundGuns.add(s, "phantom", 30, 60, vector.create(0.2, 0, 0), 0, 0)
	local any = function(_: GroundGuns.Gun): boolean
		return true
	end
	check("of two underfoot, the nearer is picked up", GroundGuns.walkedOver(s, feet, any) == close)
	local notPhantom = function(gun: GroundGuns.Gun): boolean
		return gun.weapon ~= "phantom"
	end
	check("unless it isn't wanted", GroundGuns.walkedOver(s, feet, notPhantom) == far)
	local twin = GroundGuns.add(s, "vandal", 25, 50, vector.create(-0.2, 0, 0), 0, 0)
	check("of two as near, the one down first", GroundGuns.walkedOver(s, feet, any) == close and twin.id > close.id)
end

-- The one in view -----------------------------------------------------------------------

do
	local eye = vector.create(0, 1.6, 0)
	local gun = vector.create(0, 0, -1.5) -- on the floor, 1.5 m ahead
	local at = gun + GroundGuns.CENTRE
	local look = vector.normalize(at - eye)
	local along = GroundGuns.alongView(eye, look, gun, P.reach.value, P.aimRadius.value)
	check("looking down at a gun at your feet finds it", along ~= nil and near(along :: number, vector.magnitude(at - eye), 1e-6))
	check("looking the other way doesn't", GroundGuns.alongView(eye, -look, gun, P.reach.value, P.aimRadius.value) == nil)
	local ahead = vector.create(0, 0, -1)
	check("nor looking straight ahead over it", GroundGuns.alongView(eye, ahead, gun, P.reach.value, P.aimRadius.value) == nil)
	local beyond = vector.create(0, 0, -5)
	local toBeyond = vector.normalize(beyond + GroundGuns.CENTRE - eye)
	check("one out of reach isn't in view", GroundGuns.alongView(eye, toBeyond, beyond, P.reach.value, P.aimRadius.value) == nil)

	local s = GroundGuns.new()
	local near1 = GroundGuns.add(s, "vandal", 25, 50, vector.create(0, 0, -1.2), 0, 0)
	GroundGuns.add(s, "phantom", 30, 60, vector.create(0, 0, -2.4), 0, 0)
	local down = vector.normalize(vector.create(0, 0.05, -1.8) - eye)
	check("of two along the view, the nearer", GroundGuns.aimedAt(s, eye, down) == near1)
	local wide = vector.normalize(vector.create(0.75, 0.05, -1.2) - eye)
	check("a near miss is no gun", GroundGuns.aimedAt(s, eye, wide) == nil)
	check("but the server's slack takes it", GroundGuns.aimedAt(s, eye, wide, 0.5) == near1)
end

-- G lets go of the gun in hand ------------------------------------------------------------

do
	local s = newPlayer({ "vandal", "classic", "knife", "" })
	-- A few rounds fired first, so it's not full.
	run(s, B.Fire, ticks(0.3), 1)
	run(s, 0, ticks(0.5), 1)
	local ammo, reserve = s.weapons.ammo[1], s.weapons.reserve[1]
	local dropped = run(s, B.Drop, ticks(1), 1)
	check("G lets go of the gun in hand, once however long it's held", #dropped == 1 and dropped[1].id == "vandal" and dropped[1].slot == 1)
	check(
		"with the rounds it had",
		ammo < WeaponConfig.get("vandal").magazine.value and dropped[1].ammo == ammo and dropped[1].reserve == reserve
	)
	local t = s.movement.tick * DT
	check("its slot is empty", s.weapons.loadout[1] == "" and s.weapons.ammo[1] == 0)
	check("and the sidearm comes out, drawn", s.weapons.equipped == 2 and s.weapons.equipEndTime > t - 1)
	run(s, 0, 1, 2)
	dropped = run(s, B.Drop, 1, 2)
	check("G pressed again lets go of the sidearm", #dropped == 1 and dropped[1].id == "classic" and s.weapons.equipped == 3)
	run(s, 0, 1, 3)
	dropped = run(s, B.Drop, 3, 3)
	check("but never the knife", #dropped == 0 and s.weapons.loadout[3] == "knife")
end

do
	local s = newPlayer({ "vandal", "classic", "knife", "" })
	run(s, 0, 1, 1)
	local dropped = run(s, B.Drop, 1, 1)
	local t = s.movement.tick * DT
	local equipTime = WeaponConfig.get("classic").equipTime.value
	check("the sidearm takes its draw time from the drop", #dropped == 1 and near(s.weapons.equipEndTime, t + equipTime, DT + 1e-9))
end

do
	local s = newPlayer({ "vandal", "classic", "knife", "spike" })
	run(s, 0, ticks(0.6), 4)
	local dropped, acts = run(s, B.Drop, 1, 4)
	check("with the spike in hand, G lets go of the spike, not a gun", #dropped == 0 and #acts == 1 and acts[1].kind == "dropped")
	check("and the Vandal comes back, still there", s.weapons.equipped == 1 and s.weapons.loadout[1] == "vandal")
end

do
	-- Rooted defusing, the weapon is put away: G does nothing.
	local site = Spike.CourseSites[1]
	local feet = vector.create(site.center.x, 0.02, site.center.z)
	local planted = feet - vector.create(0, 0.02, 1)
	local ctx: Spike.Context =
		{ zones = Spike.CourseSites, canPlant = false, canDefuse = true, planted = planted, halfSaved = false, sees = nil }
	local s = PlayerSim.new(feet, { "vandal", "classic", "knife", "" })
	for _ = 1, 40 do
		PlayerSim.step(s, input(0, 1), cfg, floor, DT, ctx)
	end
	run(s, B.Use, ticks(1), 1, ctx)
	local dropped = run(s, bit32.bor(B.Use, B.Drop), ticks(0.5), 1, ctx)
	check(
		"G while defusing lets go of nothing",
		#dropped == 0 and s.spike.channel == SpikeSim.DEFUSING and s.weapons.loadout[1] == "vandal"
	)
end

do
	local s = newPlayer({ "vandal", "classic", "knife", "" })
	run(s, B.Fire, ticks(0.3), 1)
	run(s, 0, ticks(0.3), 1)
	run(s, B.Reload, 1, 1)
	local ammo = s.weapons.ammo[1]
	check("(a reload under way)", WeaponSim.isReloading(s.weapons))
	local dropped = run(s, B.Drop, 1, 1)
	check(
		"a gun let go of mid-reload keeps only what was in it",
		#dropped == 1 and dropped[1].ammo == ammo and not WeaponSim.isReloading(s.weapons)
	)
end

-- Both sides agree ------------------------------------------------------------------------

do
	local a = newPlayer({ "vandal", "classic", "knife", "" })
	local b = newPlayer({ "vandal", "classic", "knife", "" })
	local droppedA = run(a, B.Drop, 3, 1)
	local droppedB = run(b, B.Drop, 3, 1)
	check(
		"two simulations from the same input let go on the same tick, with the same rounds",
		#droppedA == 1 and #droppedB == 1 and a.weapons.equipEndTime == b.weapons.equipEndTime and droppedA[1].ammo == droppedB[1].ammo
	)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(90, a))
	check(
		"the ack carries the empty slot and G held",
		decoded.weapons.loadout[1] == "" and decoded.weapons.equipped == 2 and decoded.spike.dropHeld == true
	)
end

-- Picking one up ----------------------------------------------------------------------

do
	local w = WeaponSim.newState({ "", "classic", "knife", "" })
	WeaponSim.give(w, 1, "vandal", 1, 7, 13)
	check("a gun picked up keeps its rounds", w.loadout[1] == "vandal" and w.ammo[1] == 7 and w.reserve[1] == 13)
	check("and isn't drawn unless its slot is in hand", w.equipped == 2)
	WeaponSim.give(w, 2, "sheriff", 1, 3, 0)
	check("one into the slot in hand is drawn", w.equipped == 2 and w.loadout[2] == "sheriff" and w.ammo[2] == 3 and w.equipEndTime > 1)
	WeaponSim.give(w, 1, "phantom", 1)
	check("and one given without rounds comes full", w.ammo[1] == WeaponConfig.get("phantom").magazine.value)
end

do
	-- Bought, then let go of: nothing to sell back.
	local s = Shop.new()
	local vandal = Shop.item("vandal") :: Shop.Item
	Shop.buy(s, vandal, "")
	check("(a Vandal bought refunds its price)", Shop.refund(s, vandal) == vandal.price)
	Shop.forget(s, vandal.slot)
	check("dropped, it can't be sold back", Shop.refund(s, vandal) == 0 and Shop.sell(s, vandal) == nil)
	check("and the menu shows nothing bought", #Shop.boughtList(s) == 0)
	check("so another costs its full price", Shop.cost(s, vandal) == vandal.price)
end

return nil
