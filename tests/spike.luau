--!strict
-- The spike (system 12): its numbers, where it can be planted and defused,
-- its beeps and blast, and the plant, the defuse and the drop as PlayerSim
-- steps them.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
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
local P = Spike.Params
local A_SITE = Spike.CourseSites[1]
local A_FEET = vector.create(A_SITE.center.x, 0.02, A_SITE.center.z)
local OUTSIDE = vector.create(0, 0.02, 10)

local function input(buttons: number, slot: number, yaw: number?)
	return { seq = 0, buttons = buttons, slot = slot, yaw = yaw or 0, pitch = 0, viewTime = 0 }
end

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

-- What a player on the course may do: plant (if carrying) and defuse the
-- spike planted at `planted`, if any.
local function course(planted: vector?, halfSaved: boolean?, sees: ((vector, vector) -> boolean)?): Spike.Context
	return {
		zones = Spike.CourseSites,
		canPlant = true,
		canDefuse = planted ~= nil,
		planted = planted,
		halfSaved = halfSaved == true,
		sees = sees,
	}
end

-- A player settled on the floor at `feet` with the Vandal, the Classic, the
-- knife and (if `carrying`) the spike, holding the Vandal.
local function newPlayer(feet: vector, carrying: boolean): PlayerSim.State
	local s = PlayerSim.new(feet, { "vandal", "classic", "knife", if carrying then "spike" else "" })
	for _ = 1, 40 do
		PlayerSim.step(s, input(0, 1), cfg, floor, DT)
	end
	return s
end

-- Steps `n` ticks with the same buttons and slot; returns every act.
local function run(s: PlayerSim.State, buttons: number, n: number, slot: number, ctx: Spike.Context?): ({ SpikeSim.Act }, number)
	local acts, bullets = {}, 0
	for _ = 1, n do
		local shots, _, act = PlayerSim.step(s, input(buttons, slot), cfg, floor, DT, ctx)
		bullets += if shots then #shots else 0
		if act then
			table.insert(acts, act)
		end
	end
	return acts, bullets
end

-- A player at site A with the spike drawn and ready to plant.
local function readyToPlant(): PlayerSim.State
	local s = newPlayer(A_FEET, true)
	run(s, 0, ticks(0.6), 4, course())
	return s
end

H.section("Spike tests")

-- The numbers ----------------------------------------------------------------------

do
	local ok = true
	for _, param in P do
		ok = ok and type(param.value) == "number" and param.source ~= "" and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
	end
	check("every spike number carries a status and a source", ok)
	check(
		"plant 4 s, defuse 7 s, half saved at 3.5 s, 45 s to go off (community)",
		P.plantTime.value == 4
			and P.defuseTime.value == 7
			and P.defuseHalf.value == 3.5
			and P.detonateTime.value == 45
			and P.plantTime.status == "community"
			and P.defuseTime.status == "community"
			and P.defuseHalf.status == "community"
			and P.detonateTime.status == "community"
	)
	check("the blast reaches 35 m (community)", P.blastRadius.value == 35 and P.blastRadius.status == "community")
	local def = WeaponConfig.get("spike")
	check("the spike is carried in slot 4 and fires nothing", def.id == "spike" and def.slot == Spike.SLOT and def.fireMode == "none" and def.spike == true)
	check("the spike isn't on sale", Shop.item("spike") == nil)
	check("its wire id is stable, after the guns", WeaponConfig.IndexOf.spike == 22)
end

-- Where -----------------------------------------------------------------------------

do
	local zones = Spike.CourseSites
	check("the middle of A is in A", Spike.siteAt(zones, A_FEET) == "A")
	check("the middle of B is in B", Spike.siteAt(zones, vector.create(8, 0.02, 26)) == "B")
	check("between the sites is in neither", Spike.siteAt(zones, vector.create(0, 0.02, 26)) == nil)
	check("2.9 m from A's middle is in, 3.1 m is out", Spike.siteAt(zones, A_FEET + vector.create(2.9, 0, 0)) == "A" and Spike.siteAt(zones, A_FEET + vector.create(3.1, 0, 0)) == nil)
	check("3 m above the floor is out", Spike.siteAt(zones, A_FEET + vector.create(0, 3, 0)) == nil)
	local turned: Spike.Zone = { site = "T", center = vector.create(0, 1, 0), half = vector.create(3, 1, 0.5), yaw = math.rad(90) }
	check("a zone turned 90 degrees runs along the other axis", Spike.inZone(turned, vector.create(0, 0.5, 2.5)) and not Spike.inZone(turned, vector.create(2.5, 0.5, 0)))

	local spike = vector.create(0, 0, 0)
	check("a defuser 1.5 m away is in range, 1.7 m isn't", Spike.inDefuseRange(vector.create(1.5, 0, 0), spike) and not Spike.inDefuseRange(vector.create(1.7, 0, 0), spike))
	check("a defuser 1.3 m above it isn't", not Spike.inDefuseRange(vector.create(0, 1.3, 0), spike))
	check("feet over it run it over, 0.8 m away don't", Spike.runsOver(vector.create(0.3, 0.02, 0), spike) and not Spike.runsOver(vector.create(0.8, 0.02, 0), spike))
end

-- Beeps and the blast -------------------------------------------------------------------

do
	check("it beeps once a second at first", Spike.beepRate(0) == 1 and Spike.beepRate(24.9) == 1)
	check("twice a second from 25 s, four times from 35 s, eight from 40 s", Spike.beepRate(25) == 2 and Spike.beepRate(35) == 4 and Spike.beepRate(40) == 8)
	local times = Spike.beepTimes()
	local rising, onTime = true, { [25] = false, [35] = false, [40] = false }
	for i, t in times do
		rising = rising and (i == 1 or t > times[i - 1])
		for from in onTime do
			onTime[from] = onTime[from] or near(t, from, 1e-6)
		end
	end
	check("105 beeps, the first at the plant, all before 45 s", #times == 105 and times[1] == 0 and times[#times] < 45, tostring(#times))
	check("each faster stretch starts with a beep on time", rising and onTime[25] and onTime[35] and onTime[40])
	check("the last comes 1/8 s before the end", near(times[#times], 45 - 1 / 8, 1e-6), string.format("%.4f", times[#times]))
	check("the blast is at its edge 0.5 s after it goes off", near(Spike.blastReaches(35) or -1, 0.5, 1e-9) and near(Spike.blastReaches(17.5) or -1, 0.25, 1e-9))
	check("it doesn't reach 35.1 m", Spike.blastReaches(35.1) == nil)
	check("a whole defuse is 7 s, one from the half 3.5 s", Spike.defuseTime(false) == 7 and Spike.defuseTime(true) == 3.5)
end

-- The plant ---------------------------------------------------------------------------

do
	local s = readyToPlant()
	check("4 draws the spike", s.weapons.equipped == Spike.SLOT and SpikeSim.inHand(s.weapons))
	local before = s.movement.position
	local acts = run(s, B.Use, 1, 4, course())
	check("holding 4 in a site starts a plant", s.spike.channel == SpikeSim.PLANTING and #acts == 0)
	local start = s.spike.channelStart
	-- Rooted: running and jumping go nowhere.
	acts = run(s, bit32.bor(B.Use, B.Forward, B.Right), ticks(2), 4, course())
	local moved = vector.magnitude(s.movement.position - before)
	check("planting roots: holding W and D for 2 s moves 0 m", moved < 1e-9, string.format("%.4f m", moved))
	check("halfway through, the bar reads 50%", near(SpikeSim.fraction(s.spike, s.movement.tick * DT), 0.5, 1e-9))
	run(s, bit32.bor(B.Use, B.Jump), ticks(0.5), 4, course())
	check("and so does jumping", vector.magnitude(s.movement.position - before) < 1e-9 and s.movement.grounded)
	acts = run(s, B.Use, ticks(2), 4, course())
	check("4 s after it starts, it's planted", #acts == 1 and acts[1].kind == "planted" and acts[1].time - start == 4, if #acts > 0 then tostring(acts[1].time - start) else "none")
	local act = acts[1]
	if act then
		check("at site A, a little in front of the planter", act.site == "A" and near(vector.magnitude(act.position - before), P.plantAhead.value, 1e-6))
		check("the spike leaves the slot and the Vandal comes back, drawn", s.weapons.loadout[4] == "" and s.weapons.equipped == 1 and near(s.weapons.equipEndTime - act.time, WeaponConfig.get("vandal").equipTime.value, 1e-9))
	end
	check("and the player can move again", s.spike.channel == SpikeSim.NONE and not PlayerSim.rooted(s))
end

do
	local s = readyToPlant()
	local acts = run(s, B.Fire, ticks(4) + 1, 4, course())
	check("holding fire plants too", #acts == 1 and acts[1].kind == "planted")
end

do
	local s = readyToPlant()
	local acts = run(s, B.Use, ticks(3.9), 4, course())
	acts = run(s, 0, 1, 4, course())
	check("let go of at 3.9 s, nothing's planted and it stops", #acts == 0 and s.spike.channel == SpikeSim.NONE and SpikeSim.inHand(s.weapons))
	run(s, B.Use, 1, 4, course())
	local start = s.spike.channelStart
	acts = run(s, B.Use, ticks(4), 4, course())
	check("and the next try takes the whole 4 s again", #acts == 1 and acts[1].time - start == 4)
end

do
	local s = newPlayer(OUTSIDE, true)
	run(s, 0, ticks(0.6), 4, course())
	local acts = run(s, B.Use, ticks(5), 4, course())
	check("outside the sites, holding 4 does nothing", #acts == 0 and s.spike.channel == SpikeSim.NONE)
	local _, bullets = run(s, B.Fire, ticks(2), 4, course())
	check("and the spike in hand never fires", bullets == 0)
end

do
	local s = readyToPlant()
	local ctx = course()
	ctx.canPlant = false
	local acts = run(s, B.Use, ticks(5), 4, ctx)
	check("where the rules say no (canPlant), nothing", #acts == 0 and s.spike.channel == SpikeSim.NONE)
end

do
	local s = newPlayer(A_FEET, true)
	-- 4 pressed and held at once: the plant waits for the draw.
	local acts = run(s, B.Use, ticks(0.3), 4, course())
	check("the plant waits for the spike's draw", #acts == 0 and s.spike.channel == SpikeSim.NONE)
	run(s, B.Use, ticks(0.25), 4, course())
	check("and starts once it's drawn", s.spike.channel == SpikeSim.PLANTING)
end

do
	local s = readyToPlant()
	run(s, B.Jump, 2, 4, course())
	local acts = run(s, B.Use, 3, 4, course())
	check("in the air it can't start", not s.movement.grounded and s.spike.channel == SpikeSim.NONE and #acts == 0)
end

do
	local s = readyToPlant()
	run(s, B.Use, ticks(1), 4, course())
	SpikeSim.take(s.spike, s.weapons, s.movement.tick * DT)
	check("taken away mid-plant: the plant stops and the Vandal is drawn", s.spike.channel == SpikeSim.NONE and s.weapons.loadout[4] == "" and s.weapons.equipped == 1)
end

do
	-- 4 still held as the plant completes: the planter doesn't go straight
	-- on to defuse it (on the course anyone may).
	local s = readyToPlant()
	local acts = run(s, B.Use, ticks(4.1), 4, course())
	local planted = acts[1]
	check("planted, with 4 still held", planted ~= nil and planted.kind == "planted" and s.spike.holdOver)
	if planted then
		acts = run(s, B.Use, ticks(1), 1, course(planted.position))
		check("holding on doesn't start a defuse of it", #acts == 0 and s.spike.channel == SpikeSim.NONE)
		run(s, 0, 1, 1, course(planted.position))
		check("letting go ends the wait", not s.spike.holdOver)
		run(s, B.Use, 1, 1, course(planted.position))
		check("and holding 4 again defuses it", s.spike.channel == SpikeSim.DEFUSING)
	end
end

-- The drop ------------------------------------------------------------------------------

do
	local s = newPlayer(OUTSIDE, true)
	run(s, 0, ticks(0.6), 4, course())
	local acts = run(s, B.Drop, ticks(1), 4, course())
	check("G drops the spike from the hand, once however long it's held", #acts == 1 and acts[1].kind == "dropped" and s.weapons.loadout[4] == "")
	check("and the Vandal comes back", s.weapons.equipped == 1)
	local t = newPlayer(OUTSIDE, true)
	acts = run(t, B.Drop, 3, 1, course())
	check("with the spike not in hand, G does nothing", #acts == 0 and t.weapons.loadout[4] == "spike")
end

-- The defuse -----------------------------------------------------------------------------

local SPIKE_AT = A_FEET - vector.create(0, 0.02, 1)

do
	local s = newPlayer(A_FEET, false)
	local before = s.movement.position
	local acts = run(s, B.Use, 1, 1, course(SPIKE_AT))
	check("holding 4 by the planted spike starts a defuse", s.spike.channel == SpikeSim.DEFUSING and #acts == 0)
	local start = s.spike.channelStart
	local _, bullets
	acts, bullets = run(s, bit32.bor(B.Use, B.Fire, B.Forward), ticks(3), 1, course(SPIKE_AT))
	check("defusing, the weapon is put away: holding fire shoots nothing", bullets == 0)
	check("and the defuser stays put", vector.magnitude(s.movement.position - before) < 1e-9)
	acts = run(s, B.Use, ticks(4), 1, course(SPIKE_AT))
	check("7 s after it starts, it's defused", #acts == 1 and acts[1].kind == "defused" and acts[1].time - start == 7, if #acts > 0 then tostring(acts[1].time - start) else "none")
	local act = acts[1]
	if act then
		check("the Vandal is drawn again", near(s.weapons.equipEndTime - act.time, WeaponConfig.get("vandal").equipTime.value, 1e-9))
	end
	-- Until the client hears it's defused, it still has it planted: 4 held
	-- on mustn't start another.
	acts = run(s, B.Use, ticks(0.5), 1, course(SPIKE_AT))
	check("4 held on after a defuse starts no other", #acts == 0 and s.spike.channel == SpikeSim.NONE)
end

do
	local s = newPlayer(A_FEET, false)
	run(s, B.Use, ticks(4), 1, course(SPIKE_AT))
	local acts = run(s, 0, 1, 1, course(SPIKE_AT))
	local stopped = acts[1]
	check("let go of at 4 s, it says how far it got", stopped ~= nil and stopped.kind == "stopped" and near(stopped.progress, 4, 1e-9), if stopped then tostring(stopped.progress) else "none")
	-- The server saves the half from that: the next defuse starts from it.
	run(s, B.Use, 1, 1, course(SPIKE_AT, true))
	local start = s.spike.channelStart
	check("the next defuse starts from the half", s.spike.halfStart and near(SpikeSim.fraction(s.spike, s.movement.tick * DT), 0.5, 1e-9))
	acts = run(s, B.Use, ticks(3.5), 1, course(SPIKE_AT, true))
	check("and takes 3.5 s", #acts == 1 and acts[1].kind == "defused" and acts[1].time - start == 3.5)
end

do
	local s = newPlayer(A_FEET, false)
	run(s, B.Use, ticks(3), 1, course(SPIKE_AT))
	local acts = run(s, 0, 1, 1, course(SPIKE_AT))
	check("let go of at 3 s, short of the half", acts[1] ~= nil and acts[1].progress < P.defuseHalf.value)
end

do
	local s = newPlayer(A_FEET, false)
	local acts = run(s, B.Use, ticks(1), 1, course(SPIKE_AT, false, function()
		return false
	end))
	check("without sight of it, no defuse", #acts == 0 and s.spike.channel == SpikeSim.NONE)
	local far = newPlayer(A_FEET + vector.create(3, 0, 0), false)
	acts = run(far, B.Use, ticks(1), 1, course(SPIKE_AT))
	check("out of range, no defuse", #acts == 0 and far.spike.channel == SpikeSim.NONE)
end

do
	-- Sight lost partway: crouched behind cover, say (Patch 6.10).
	local s = newPlayer(A_FEET, false)
	local seen = true
	local ctx = course(SPIKE_AT, false, function()
		return seen
	end)
	run(s, B.Use, ticks(2), 1, ctx)
	seen = false
	local acts = run(s, B.Use, 1, 1, ctx)
	check("losing sight of it stops a defuse", #acts == 1 and acts[1].kind == "stopped" and s.spike.channel == SpikeSim.NONE)
	acts = run(s, B.Use, ticks(1), 1, ctx)
	check("and holding on doesn't start another", #acts == 0 and s.spike.channel == SpikeSim.NONE)
	seen = true
	run(s, B.Use, 1, 1, ctx)
	check("in sight again, it starts over", s.spike.channel == SpikeSim.DEFUSING)
end

do
	-- Out of range partway: pulled away (Patch 2.07), here by moving the spike.
	local s = newPlayer(A_FEET, false)
	run(s, B.Use, ticks(1), 1, course(SPIKE_AT))
	local acts = run(s, B.Use, 1, 1, course(SPIKE_AT - vector.create(0, 0, 2)))
	check("out of range of it, a defuse stops", #acts == 1 and acts[1].kind == "stopped" and s.spike.channel == SpikeSim.NONE)
end

do
	local s = newPlayer(A_FEET, false)
	run(s, B.Use, ticks(2), 1, course(SPIKE_AT))
	-- It goes off (or is defused by someone else): no planted spike any more.
	local acts = run(s, B.Use, 1, 1, course(nil))
	check("a defuse stops when there's no spike to defuse", #acts == 1 and acts[1].kind == "stopped" and s.spike.channel == SpikeSim.NONE)
end

-- Both sides agree -----------------------------------------------------------------------

do
	local a, b = readyToPlant(), readyToPlant()
	local actsA = run(a, B.Use, ticks(4.5), 4, course())
	local actsB = run(b, B.Use, ticks(4.5), 4, course())
	check(
		"two simulations from the same input plant on the same tick, at the same point",
		#actsA == 1 and #actsB == 1 and actsA[1].tick == actsB[1].tick and actsA[1].position == actsB[1].position
	)

	local s = readyToPlant()
	run(s, B.Use, ticks(0.5), 4, course())
	-- G pressed mid-plant: not a drop, but the ack must carry it as held.
	run(s, bit32.bor(B.Use, B.Drop), ticks(0.5), 4, course())
	check("G pressed while planting doesn't drop it", s.spike.channel == SpikeSim.PLANTING and s.weapons.loadout[4] == "spike" and s.spike.dropHeld)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(90, s))
	local ss, ds = s.spike, decoded.spike
	check(
		"the ack carries the plant under way exactly",
		ds.channel == ss.channel
			and ds.channelStart == ss.channelStart
			and ds.channelEnd == ss.channelEnd
			and ds.halfStart == ss.halfStart
			and ds.lastSlot == ss.lastSlot
			and ds.dropHeld == ss.dropHeld
			and ds.holdOver == ss.holdOver
			and decoded.weapons.loadout[4] == "spike"
	)
	-- The rest of the plant replayed from the ack lands as the original did.
	local replay = PlayerSim.copy(decoded)
	local original = run(s, B.Use, ticks(3.5), 4, course())
	local again = run(replay, B.Use, ticks(3.5), 4, course())
	check("and a replay from it plants on the same tick", #original == 1 and #again == 1 and original[1].tick == again[1].tick)
end

do
	local s = newPlayer(A_FEET, false)
	run(s, B.Use, ticks(4), 1, course(SPIKE_AT))
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(91, s))
	check("and a defuse under way, its weapon put away", decoded.spike.channel == SpikeSim.DEFUSING and decoded.spike.channelEnd == s.spike.channelEnd)
	local w = WeaponSim.newState({ "vandal", "classic", "knife", "spike" })
	check("a fourth slot in every loadout", #w.loadout == WeaponSim.SLOTS and w.loadout[4] == "spike" and w.equipped == 1)
end

return nil
