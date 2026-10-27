--!strict
-- The spike rounds' Ultimate Orbs (system 49): their numbers, where each
-- map's stand, which are up as the rounds go, whose feet are close enough
-- to take one, and the taking as PlayerSim steps it: F held on the ground
-- at one, rooted with the weapon away, for 2 s; over with nothing the
-- moment F's let go or the orb's gone; a defuse in reach first; and F
-- carried on the wire.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local Spike = require("../src/shared/Spike/Spike")
local SpikeSim = require("../src/shared/Spike/SpikeSim")
local UltimateOrbs = require("../src/shared/Spike/UltimateOrbs")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local TeamDeathmatchConfig = require("../src/shared/Arena/TeamDeathmatchConfig")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local FogOfWar = require("../src/shared/Combat/FogOfWar")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local P = UltimateOrbs.Params
local J = AbilityConfig.Jett
local VANDAL_DRAW = WeaponConfig.get("vandal").equipTime.value

-- Where a player stands, and an orb's mark a metre from them, on the floor.
local FEET = vector.create(0, 0.02, 0)
local ORB = vector.create(0, 0, -1)

local function input(buttons: number, slot: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = 0, pitch = 0, viewTime = 0 }
end

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

-- What a player may do in a round of the spike rounds: take the orbs up,
-- `orbs`, and defuse the spike planted at `planted`, if any.
local function rounds(orbs: { [number]: vector }?, planted: vector?): Spike.Context
	return {
		zones = Spike.CourseSites,
		canPlant = false,
		canDefuse = planted ~= nil,
		planted = planted,
		halfSaved = false,
		sees = nil,
		orbs = orbs,
	}
end

-- A player settled on the floor at `feet` with the Vandal, the Classic, the
-- knife and (if `carrying`) the spike, the Vandal drawn and ready.
local function newPlayer(feet: vector?, carrying: boolean?): PlayerSim.State
	local s = PlayerSim.new(feet or FEET, { "vandal", "classic", "knife", if carrying then "spike" else "" })
	for _ = 1, ticks(1.5) do
		PlayerSim.step(s, input(0), cfg, floor, DT)
	end
	return s
end

-- Steps `n` ticks with the same buttons; returns every act, the bullets
-- fired and how many casts there were.
local function run(s: PlayerSim.State, buttons: number, n: number, ctx: Spike.Context?, slot: number?): ({ SpikeSim.Act }, number, number)
	local acts, bullets, cast = {}, 0, 0
	for _ = 1, n do
		local shots, _, act, _, casts = PlayerSim.step(s, input(buttons, slot), cfg, floor, DT, ctx)
		bullets += if shots then #shots else 0
		cast += if casts then #casts else 0
		if act then
			table.insert(acts, act)
		end
	end
	return acts, bullets, cast
end

-- The time of the tick just run.
local function now(s: PlayerSim.State): number
	return s.movement.tick * DT
end

-- Readies Jett's Tailwind with a tap of E and waits out the windup.
local function readied(s: PlayerSim.State, ctx: Spike.Context?)
	AbilitySim.fill(s.abilities)
	run(s, B.AbilityE, 1, ctx)
	run(s, 0, ticks(J.windup.value) + 1, ctx)
end

-- How another player looks on the wire, at `feet`, with the spike's channel
-- `channel`.
local function pose(feet: vector, channel: number): PlayerCodec.Pose
	return {
		id = PlayerCodec.DUMMY_BASE + 1,
		position = feet,
		yaw = 0,
		pitch = 0,
		crouchAlpha = 0,
		grounded = true,
		alive = true,
		quiet = true,
		reloading = false,
		weapon = 0,
		channel = channel,
		gliding = false,
	}
end

H.section("Ultimate Orbs (system 49)")

-- The numbers ---------------------------------------------------------------------------

do
	local ok = true
	for _, param in P do
		ok = ok
			and type(param.value) == "number"
			and param.source ~= ""
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
	end
	check("every orb number carries a status and a source", ok)
	check("two a map, as the patch notes have it (confirmed)", P.perMap.value == 2 and P.perMap.status == "confirmed")
	check(
		"taken in 2 s, from 1.5 m across the floor and 1.2 m up or down (estimates)",
		P.collectTime.value == 2
			and P.reach.value == 1.5
			and P.height.value == 1.2
			and P.collectTime.status == "estimate"
			and P.reach.status == "estimate"
			and P.height.status == "estimate"
	)
	check("each worth a point of the ultimate", AbilityConfig.Points.orb.value == 1)
	check("which are up is Workspace's VFOrbs", UltimateOrbs.UP == "VFOrbs")
end

-- Where --------------------------------------------------------------------------------

do
	local counted, placed = true, true
	for _, key in SpikeMaps.MAPS do
		local map = SpikeMaps.Maps[key]
		local plan = TeamDeathmatchConfig.Pickups[key]
		local places = UltimateOrbs.placesOf(key)
		counted = counted and #places == P.perMap.value
		for i, at in places do
			placed = placed and plan ~= nil and at == map.origin + plan.ultimate[i]
		end
	end
	check("each spike map has its two", counted)
	check("where Team Deathmatch has its Ultimate Orbs, on the map's floor", placed)
	check("the course has none", #UltimateOrbs.placesOf("course") == 0 and next(UltimateOrbs.decode("course", "1,2")) == nil)
	check("nor has a map that isn't one", #UltimateOrbs.placesOf("nowhere") == 0)
	check("each map's worked out once", UltimateOrbs.placesOf("quarry") == UltimateOrbs.placesOf("quarry"))
end

-- Which are up ----------------------------------------------------------------------------

do
	local s = UltimateOrbs.new("outpost")
	check(
		"a map's orbs are down till a round starts",
		#s.places == 2 and not s.up[1] and not s.up[2] and UltimateOrbs.encode(s) == "" and next(UltimateOrbs.upOf(s)) == nil
	)
	UltimateOrbs.roundStarted(s)
	check("a round puts both up", s.up[1] and s.up[2] and UltimateOrbs.encode(s) == "1,2")
	local up = UltimateOrbs.upOf(s)
	check("each where it stands", up[1] == s.places[1] and up[2] == s.places[2])
	check("taking one takes it", UltimateOrbs.take(s, 2) and not s.up[2] and UltimateOrbs.encode(s) == "1")
	check("once: taking it again gets nothing", not UltimateOrbs.take(s, 2))
	check("nor does taking one there isn't", not UltimateOrbs.take(s, 3) and not UltimateOrbs.take(s, 0))
	up = UltimateOrbs.upOf(s)
	check("and it's up no longer", up[1] == s.places[1] and up[2] == nil)
	UltimateOrbs.roundStarted(s)
	check("the next round puts it back up", s.up[1] and s.up[2] and UltimateOrbs.encode(s) == "1,2")
end

do
	local outpost = UltimateOrbs.placesOf("outpost")
	local both = UltimateOrbs.decode("outpost", "1,2")
	check("VFOrbs '1,2' is both, each where it stands", both[1] == outpost[1] and both[2] == outpost[2])
	local second = UltimateOrbs.decode("outpost", "2")
	check("'2' is the second alone", second[1] == nil and second[2] == outpost[2])
	check(
		"'' is none, and so is no attribute",
		next(UltimateOrbs.decode("outpost", "")) == nil and next(UltimateOrbs.decode("outpost", nil)) == nil
	)
	check(
		"a number that's no orb is left out, and anything that isn't text",
		next(UltimateOrbs.decode("outpost", "3,0")) == nil and next(UltimateOrbs.decode("outpost", 12)) == nil
	)
	local s = UltimateOrbs.new("foundry")
	UltimateOrbs.roundStarted(s)
	UltimateOrbs.take(s, 1)
	local read = UltimateOrbs.decode("foundry", UltimateOrbs.encode(s))
	local up = UltimateOrbs.upOf(s)
	check("a client reads the server's text as the server has it", read[1] == nil and up[1] == nil and read[2] ~= nil and read[2] == up[2])
end

-- Close enough ---------------------------------------------------------------------------

do
	local at = vector.create(0, 0, 0)
	check(
		"feet 1.5 m from an orb's mark can take it, 1.6 m can't",
		UltimateOrbs.reaches(vector.create(1.5, 0, 0), at) and not UltimateOrbs.reaches(vector.create(1.6, 0, 0), at)
	)
	check(
		"the same in any direction across the floor",
		UltimateOrbs.reaches(vector.create(1, 0, -1), at) and not UltimateOrbs.reaches(vector.create(1.1, 0, 1.1), at)
	)
	check(
		"1.1 m above or below it can, 1.3 m can't",
		UltimateOrbs.reaches(vector.create(0, 1.1, 0), at)
			and UltimateOrbs.reaches(vector.create(0, -1.1, 0), at)
			and not UltimateOrbs.reaches(vector.create(0, 1.3, 0), at)
	)
	local orbs = { [1] = vector.create(-1, 0, 0), [2] = vector.create(0.5, 0, 0) }
	check("of two in reach, the nearer", UltimateOrbs.inReach(orbs, at) == 2)
	check(
		"of two as near, the lower number, whichever comes first",
		UltimateOrbs.inReach({ [1] = vector.create(1, 0, 0), [2] = vector.create(-1, 0, 0) }, at) == 1
			and UltimateOrbs.inReach({ [2] = vector.create(1, 0, 0), [1] = vector.create(-1, 0, 0) }, at) == 1
	)
	check("none in reach, none", UltimateOrbs.inReach(orbs, vector.create(5, 0, 0)) == nil and UltimateOrbs.inReach({}, at) == nil)
end

-- The taking -------------------------------------------------------------------------------

do
	local s = newPlayer()
	local before = s.movement.position
	local ctx = rounds({ [1] = ORB })
	local acts = run(s, B.Interact, 1, ctx)
	check("F held at an orb starts its taking", s.spike.channel == SpikeSim.COLLECTING and s.spike.orb == 1 and #acts == 0)
	check("which roots the taker, as a defuse does", PlayerSim.rooted(s))
	local start = s.spike.channelStart
	local bullets
	acts, bullets = run(s, bit32.bor(B.Interact, B.Fire, B.Forward, B.Right, B.Jump), ticks(1), ctx)
	local moved = vector.magnitude(s.movement.position - before)
	check("holding W, D and space through it moves them 0 m", moved < 1e-9 and s.movement.grounded, string.format("%.4f m", moved))
	check("the gun's away: fire held shoots nothing", bullets == 0 and #acts == 0)
	check("halfway through, the bar reads 50%", near(SpikeSim.fraction(s.spike, now(s)), 0.5, 1e-9))
	acts = run(s, B.Interact, ticks(1), ctx)
	check(
		"2 s after it starts, it's taken",
		#acts == 1 and acts[1].kind == "collected" and acts[1].time - start == P.collectTime.value,
		if #acts > 0 then tostring(acts[1].time - start) else "none"
	)
	local act = acts[1]
	if act then
		check("saying which orb, and where it stood", act.orb == 1 and act.position == ORB)
		check("the Vandal comes back, drawn", s.weapons.equipped == 1 and near(s.weapons.equipEndTime - act.time, VANDAL_DRAW, 1e-9))
	end
	check("and the taker can move again", s.spike.channel == SpikeSim.NONE and s.spike.orb == 0 and not PlayerSim.rooted(s))
	-- Until the server's word that it's gone gets back, the client has it up
	-- still: F held on mustn't start it again.
	acts = run(s, B.Interact, ticks(0.5), ctx)
	check("F held on after it's taken starts nothing", #acts == 0 and s.spike.channel == SpikeSim.NONE and s.spike.holdOver)
	run(s, 0, 1, ctx)
	check("letting go ends the wait", not s.spike.holdOver)
	run(s, B.Interact, 1, ctx)
	check("and holding F again starts again", s.spike.channel == SpikeSim.COLLECTING)
end

do
	local s = newPlayer()
	local ctx = rounds({ [1] = ORB })
	run(s, B.Interact, ticks(1.9), ctx)
	local acts = run(s, 0, 1, ctx)
	check("let go of at 1.9 s, nothing's taken and it's over", #acts == 0 and s.spike.channel == SpikeSim.NONE and not PlayerSim.rooted(s))
	check("the Vandal's drawn again", near(s.weapons.equipEndTime - now(s), VANDAL_DRAW, 1e-9))
	run(s, B.Interact, 1, ctx)
	local start = s.spike.channelStart
	acts = run(s, B.Interact, ticks(2), ctx)
	check("and the next try takes the whole 2 s again", #acts == 1 and acts[1].kind == "collected" and acts[1].time - start == 2)
end

do
	local s = newPlayer()
	run(s, B.Interact, ticks(1), rounds({ [1] = ORB }))
	-- Someone else has taken it: it's up no longer.
	local acts = run(s, B.Interact, 1, rounds({}))
	check("taken by someone else partway, the taking's over with nothing", #acts == 0 and s.spike.channel == SpikeSim.NONE)
	check("and the Vandal's drawn again", near(s.weapons.equipEndTime - now(s), VANDAL_DRAW, 1e-9))
	acts = run(s, B.Interact, ticks(2.5), rounds(nil))
	check("with none up, F held does nothing", #acts == 0 and s.spike.channel == SpikeSim.NONE)
end

do
	local s = newPlayer()
	local acts = run(s, B.Use, ticks(2.5), rounds({ [1] = ORB }))
	check("4 doesn't take one (F does)", #acts == 0 and s.spike.channel == SpikeSim.NONE)
	local far = newPlayer(vector.create(0, 0.02, 0.6))
	acts = run(far, B.Interact, ticks(2.5), rounds({ [1] = ORB }))
	check("1.6 m from it, F does nothing", #acts == 0 and far.spike.channel == SpikeSim.NONE)
	local up = newPlayer()
	run(up, B.Jump, 2, rounds({ [1] = ORB }))
	acts = run(up, B.Interact, 3, rounds({ [1] = ORB }))
	check("in the air it can't start", not up.movement.grounded and up.spike.channel == SpikeSim.NONE and #acts == 0)
end

do
	-- An orb and the planted spike both in reach: a defender's F defuses.
	local SPIKE_AT = vector.create(1, 0, 0)
	local s = newPlayer()
	run(s, B.Interact, 1, rounds({ [1] = ORB }, SPIKE_AT))
	check("F with the planted spike in reach defuses it, an orb in reach or not", s.spike.channel == SpikeSim.DEFUSING)
	local d = newPlayer()
	run(d, B.Interact, 1, rounds(nil, SPIKE_AT))
	local start = d.spike.channelStart
	local acts = run(d, B.Interact, ticks(7), rounds(nil, SPIKE_AT))
	check("all 7 s of it, as 4 does", #acts == 1 and acts[1].kind == "defused" and acts[1].time - start == 7)
	-- An attacker there may not defuse it: theirs is the orb.
	local ctx = rounds({ [1] = ORB }, SPIKE_AT)
	ctx.canDefuse = false
	local a = newPlayer()
	run(a, B.Interact, 1, ctx)
	check("one who may not defuse it takes the orb", a.spike.channel == SpikeSim.COLLECTING)
end

do
	-- F with the spike in hand in a site.
	local site = Spike.CourseSites[1]
	local s = newPlayer(vector.create(site.center.x, 0.02, site.center.z), true)
	local ctx = rounds(nil)
	ctx.canPlant = true
	run(s, 0, ticks(0.6), ctx, 4)
	local acts = run(s, B.Interact, ticks(5), ctx, 4)
	check(
		"F with the spike in hand in a site doesn't plant it",
		#acts == 0 and s.spike.channel == SpikeSim.NONE and SpikeSim.inHand(s.weapons)
	)
	acts = run(s, B.Use, ticks(4) + 1, ctx, 4)
	check("4 still does", #acts == 1 and acts[1].kind == "planted")
	-- And at an orb, the spike in hand: it's put away and back after.
	local c = newPlayer(FEET, true)
	run(c, 0, ticks(0.6), rounds({ [1] = ORB }), 4)
	acts = run(c, B.Interact, ticks(2) + 1, rounds({ [1] = ORB }), 4)
	check(
		"with the spike in hand, F takes an orb all the same, and the spike's drawn again after",
		#acts == 1 and acts[1].kind == "collected" and SpikeSim.inHand(c.weapons) and c.weapons.equipEndTime > now(c)
	)
end

do
	-- The abilities while taking one.
	local s = newPlayer()
	local ctx = rounds({ [1] = ORB })
	AbilitySim.fill(s.abilities)
	run(s, B.Interact, 1, ctx)
	local charges = s.abilities.charges[AbilityConfig.Q]
	local _, _, cast = run(s, bit32.bor(B.Interact, B.AbilityQ), ticks(1), ctx)
	check(
		"nothing's cast while taking one: Q held does nothing",
		cast == 0 and s.abilities.charges[AbilityConfig.Q] == charges and s.spike.channel == SpikeSim.COLLECTING
	)

	-- Tailwind readied, then E pressed with F: the taking goes first.
	local t = newPlayer()
	readied(t, ctx)
	local _, _, _, _, casts = PlayerSim.step(t, input(bit32.bor(B.AbilityE, B.Interact)), cfg, floor, DT, ctx)
	check("pressed with a dash, the taking goes first and roots: no dash", casts == nil and t.spike.channel == SpikeSim.COLLECTING)

	-- In a dash, an orb at the feet wherever it's got to.
	local d = newPlayer()
	readied(d)
	run(d, B.AbilityE, 1)
	local taking, grounded = false, true
	for _ = 2, AbilitySim.ticks(J.dashTime.value, DT) do
		run(d, B.Interact, 1, rounds({ [1] = d.movement.position }))
		taking = taking or d.spike.channel ~= SpikeSim.NONE
		grounded = grounded and d.movement.grounded
	end
	check("F held through a dash takes nothing", AbilitySim.dashing(d.abilities, now(d)) and grounded and not taking)
end

do
	-- What G and a reload do to it.
	local s = newPlayer()
	local ctx = rounds({ [2] = ORB })
	run(s, B.Fire, 3, ctx)
	run(s, 0, ticks(0.5), ctx)
	run(s, B.Reload, 1, ctx)
	local reloading = s.weapons.reloadEndTime > 0
	run(s, B.Interact, 1, ctx)
	check("taking one stops a reload, as a defuse does", reloading and s.weapons.reloadEndTime == 0)
	run(s, bit32.bor(B.Interact, B.Drop), ticks(0.5), ctx)
	check(
		"G held while taking one drops nothing",
		s.spike.channel == SpikeSim.COLLECTING and s.spike.dropHeld and s.weapons.loadout[1] == "vandal"
	)
end

-- The wire -------------------------------------------------------------------------------------

do
	local inputs = {
		{ seq = 1, buttons = B.Interact + B.Forward, slot = 1, yaw = 0, pitch = 0, viewTime = 0 },
		{ seq = 2, buttons = 131071, slot = 3, yaw = 0, pitch = 0, viewTime = 0 },
		{ seq = 3, buttons = B.Interact, slot = 5, yaw = 0, pitch = 0, viewTime = 0, point = vector.create(12, 0, -30) },
		{ seq = 4, buttons = 65535, slot = 2, yaw = 0, pitch = 0, viewTime = 0 },
	}
	local decoded = PlayerCodec.decodeInputs(PlayerCodec.encodeInputs(inputs, 1, 4))
	check(
		"F gets to the server, and the slot it was sent with",
		decoded ~= nil and decoded[1].buttons == B.Interact + B.Forward and decoded[1].slot == 1
	)
	check("all seventeen buttons at once", decoded ~= nil and decoded[2].buttons == 131071 and decoded[2].slot == 3)
	check(
		"and with a place on the map",
		decoded ~= nil and decoded[3].buttons == B.Interact and decoded[3].slot == 5 and decoded[3].point == vector.create(12, 0, -30)
	)
	check("and the sixteen before it, without F", decoded ~= nil and decoded[4].buttons == 65535 and decoded[4].slot == 2)
end

do
	local s = newPlayer()
	local ctx = rounds({ [2] = ORB })
	run(s, B.Interact, ticks(0.5), ctx)
	run(s, bit32.bor(B.Interact, B.Drop), ticks(0.5), ctx)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(49, s))
	local ss, ds = s.spike, decoded.spike
	check(
		"the ack carries a taking under way exactly, which orb too",
		ds.channel == SpikeSim.COLLECTING
			and ds.orb == 2
			and ds.channelStart == ss.channelStart
			and ds.channelEnd == ss.channelEnd
			and ds.dropHeld
			and not ds.holdOver
			and not ds.halfStart
	)
	-- The rest of it replayed from the ack lands as the original does.
	local replay = PlayerSim.copy(decoded)
	local original = run(s, B.Interact, ticks(1.5), ctx)
	local again = run(replay, B.Interact, ticks(1.5), ctx)
	check(
		"and a replay from it takes it on the same tick",
		#original == 1 and #again == 1 and original[1].tick == again[1].tick and again[1].orb == 2
	)
	local _, after = PlayerCodec.decodeAck(PlayerCodec.encodeAck(50, s))
	check(
		"and once it's over, no orb and the wait for F",
		after.spike.orb == 0 and after.spike.channel == SpikeSim.NONE and after.spike.holdOver
	)
end

do
	local _, poses = PlayerCodec.decodeSnapshot(PlayerCodec.encodeSnapshot(1, { pose(vector.create(1, 0, 2), SpikeSim.COLLECTING) }))
	check(
		"others see who's taking one: channel 3 in the snapshot, the flags beside it as they were",
		poses[1].channel == SpikeSim.COLLECTING and poses[1].quiet and poses[1].grounded and not poses[1].gliding and not poses[1].reloading
	)
	-- Heard as far as a plant or a defuse: the ear 0.62 m over the chest the
	-- sounds come from.
	local ear = vector.create(0, 1.62, 0)
	local function taker(distance: number): FogOfWar.Target
		return { id = 2, side = 2, pose = pose(vector.create(0, 0, -distance), SpikeSim.COLLECTING), velocity = vector.zero }
	end
	local reach = math.sqrt((FogOfWar.Edges.device + FogOfWar.Params.hearing.value) ^ 2 - 0.62 ^ 2)
	check(
		string.format("an enemy taking one is heard as far as a plant or a defuse, %.1f m", reach),
		FogOfWar.hears(ear, taker(reach - 0.01)) and not FogOfWar.hears(ear, taker(reach + 0.01))
	)
end

-- The rest -----------------------------------------------------------------------------------

do
	local k = SpikeSim.new()
	local none = not SpikeSim.stowed(k)
	k.channel = SpikeSim.PLANTING
	local planting = not SpikeSim.stowed(k)
	k.channel = SpikeSim.DEFUSING
	local defusing = SpikeSim.stowed(k)
	k.channel = SpikeSim.COLLECTING
	check(
		"the weapon's away defusing and taking an orb, not planting (the spike's in hand)",
		none and planting and defusing and SpikeSim.stowed(k) and k.orb == 0
	)
	local S = SoundConfig.Sounds
	check(
		"its sounds: a whoosh as F starts on one, a chime as it's taken",
		S[SoundConfig.Orbs.grab] ~= nil and S[SoundConfig.Orbs.taken] ~= nil
	)
end

return nil
