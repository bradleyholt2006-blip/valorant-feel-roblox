--!strict
-- Jett's Blade Storm (system 19): its numbers and where they come from, the
-- cast once the ultimate's points are full, the knives as WeaponSim's fifth
-- slot (the windup, one at a time and exact, all that are left at once,
-- gone once they're thrown and the gun back in hand), guns and X again to
-- swap, a kill with a single knife bringing them all back, what ends them,
-- the course's refills, the client's slot as PlayerController asks for it,
-- and the wire carrying all of it.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local Shop = require("../src/shared/Weapons/Shop")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()
local BS = AbilityConfig.BladeStorm
local KUNAI = WeaponConfig.Defs.kunai
local ULT = WeaponSim.ULT
local X = AbilityConfig.X

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

-- A player, and the slot their client asks for.
type Player = { sim: PlayerSim.State, slot: number }

-- The slot the client asks for this tick, by PlayerController's rules: a
-- slot that's emptied isn't asked for, but for the ultimate's, and knives
-- that came into hand by themselves are asked for from then on.
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

-- One tick, the slot asked for as the client would; returns its bullets and
-- its casts.
local function step(p: Player, buttons: number, yaw: number?, pitch: number?): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	p.slot = ask(p.sim, p.slot)
	local shots, _, _, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot, yaw, pitch), cfg, floor, DT)
	return shots or {}, casts or {}
end

local function run(p: Player, buttons: number, n: number)
	for _ = 1, n do
		step(p, buttons)
	end
end

-- A number key, as PlayerController.selectSlot takes it.
local function press(p: Player, slot: number)
	if p.sim.weapons.loadout[slot] ~= "" then
		p.slot = slot
	end
end

-- A player settled on the floor with `gun` drawn, a full kit and the
-- ultimate's points full.
local function newPlayer(gun: string?): Player
	local p = { sim = PlayerSim.new(vector.create(0, 0.02, 0), { gun or "vandal", "classic", "knife", "" }), slot = 1 }
	AbilitySim.fill(p.sim.abilities, true)
	run(p, 0, ticks(1.5))
	return p
end

-- Blade Storm cast, and its windup over.
local function armed(gun: string?): Player
	local p = newPlayer(gun)
	step(p, B.Ultimate)
	run(p, 0, ticks(BS.windup.value) + 1)
	return p
end

-- The ticks from now until a fresh press of `buttons` would first throw
-- (tried on a copy), stepping on with nothing held meanwhile.
local function untilReady(p: Player, buttons: number, limit: number): number?
	for n = 1, limit do
		local probe = PlayerSim.copy(p.sim)
		local shots = PlayerSim.step(probe, input(buttons, ask(p.sim, p.slot)), cfg, floor, DT)
		if shots then
			return n
		end
		step(p, 0)
	end
	return nil
end

-- Throws a knife now, with a fresh press, and lets go.
local function throw(p: Player, buttons: number?): { WeaponSim.Shot }
	local shots = step(p, buttons or B.Fire)
	step(p, 0)
	return shots
end

-- Ticks until the knives are gone, if they go within `limit`.
local function untilGone(p: Player, limit: number): number?
	for n = 1, limit do
		step(p, 0)
		if p.sim.weapons.loadout[ULT] == "" then
			return n
		end
	end
	return nil
end

H.section("Blade Storm tests")

-- Its numbers --------------------------------------------------------------------------------

do
	local labelled = true
	for _, param in BS do
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	check("every Blade Storm number says where it's from", labelled)
	local def = AbilityConfig.Defs.bladestorm
	check(
		"Jett's ultimate on X: 8 points, and the knives its weapon",
		def.slot == X and def.kind == "ultimate" and def.points ~= nil and def.points.value == 8 and def.weapon == "kunai"
	)
	check("and it can be played now", AbilitySim.playable("bladestorm"))
	check(
		"five knives, a weapon of the fifth slot that's never reloaded",
		KUNAI.category == "ultimate"
			and KUNAI.slot == ULT
			and KUNAI.ultimate == true
			and KUNAI.magazine.value == 5
			and KUNAI.reserve.value == 0
	)
	check("never on sale", Shop.item("kunai") == nil)
	local d = WeaponConfig.damageAt
	check(
		"50 a knife to the body, 150 to the head and 42.5 to the legs, near or far",
		d(KUNAI, "body", 1) == 50 and d(KUNAI, "head", 60) == 150 and d(KUNAI, "legs", 30) == 42.5 and d(KUNAI, "body", 100) == 50
	)
	check("a 1.02 s windup, then 0.5 s to draw them again", BS.windup.value == 1.02 and KUNAI.equipTime.value == 0.5)
	local alt = KUNAI.alt
	check(
		"six a second one at a time, and 0.45 s after a burst (Patch 1.09)",
		KUNAI.fireRate.value == 6 and alt ~= nil and near(1 / alt.fireRate.value, 0.45, 1e-12) and alt.fireRate.status == "confirmed"
	)
	check("the burst is every knife that's left", alt ~= nil and alt.pellets.value == 5 and alt.ammo.value == 5)
	local kill = WeaponConfig.shotsToKill
	check("one to the head kills anyone (the wiki's table)", kill(KUNAI, "head", 10, 150) == 1)
	check(
		"two to the body on 100, three on 125 or 150",
		kill(KUNAI, "body", 10, 100) == 2 and kill(KUNAI, "body", 10, 125) == 3 and kill(KUNAI, "body", 10, 150) == 3
	)
	check("three to the legs on 125, four on 150", kill(KUNAI, "legs", 10, 125) == 3 and kill(KUNAI, "legs", 10, 150) == 4)
end

-- The cast -----------------------------------------------------------------------------------

do
	local p = newPlayer()
	p.sim.abilities.points = 7
	local _, none = step(p, B.Ultimate)
	check("with 7 of its 8 points, X does nothing", #none == 0 and p.sim.weapons.equipped == 1 and not p.sim.abilities.storm)
	step(p, 0)
	p.sim.abilities.points = 8
	local _, casts = step(p, B.Ultimate)
	local cast = casts[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check(
		"with all 8, X casts it and spends them",
		cast ~= nil and cast.kind == "storm" and cast.ability == "bladestorm" and kit.points == 0 and kit.storm
	)
	check("all five knives in hand, from the fifth slot", w.equipped == ULT and w.loadout[ULT] == "kunai" and w.ammo[ULT] == 5)
	check("the gun they came from remembered", w.back == 1)
	check("the kit says so", string.find(AbilitySim.summary(kit, p.sim.movement.tick * DT), "storm", 1, true) ~= nil)
	check("the knives run as fast as the knife", near(PlayerSim.maxSpeed(p.sim, cfg), 6.75, 1e-9))
	local held = 0
	for _ = 1, 3 do
		local _, more = step(p, B.Ultimate)
		held += #more
	end
	check("held, X casts it once", held == 0)
	check("nothing's thrown in the windup, nor all at once", untilReady(p, B.AltFire, 100) == nil)
end

do
	local p = newPlayer()
	step(p, B.Ultimate)
	local n = untilReady(p, B.Fire, 200)
	check("the first knife can go 1.02 s after the cast: 131 ticks on", n == 131, tostring(n))
	check("this client asks for them from the tick after the cast", p.slot == ULT and p.sim.weapons.hold == 0)
end

-- One at a time --------------------------------------------------------------------------------

do
	local p = armed()
	local yaw, pitch = math.rad(40), math.rad(-12)
	local shots = step(p, B.Fire, yaw, pitch)
	local aim = Accuracy.aim(yaw, pitch)
	check(
		"fire throws one knife, exactly where you aim",
		#shots == 1 and shots[1].weapon == "kunai" and shots[1].mode == "hip" and vector.magnitude(shots[1].direction - aim) < 1e-5
	)
	check("four left", p.sim.weapons.ammo[ULT] == 4)
	local more = 0
	for _ = 1, 100 do
		more += #step(p, B.Fire, yaw, pitch)
	end
	check("held, fire throws once (a click a knife)", more == 0 and p.sim.weapons.ammo[ULT] == 4)

	-- Running and in the air, as exact.
	local q = armed()
	run(q, B.Forward, 40)
	local runShots = step(q, B.Forward + B.Fire, yaw, pitch)
	step(q, B.Forward)
	check("running, as exact", q.sim.movement.grounded and #runShots == 1 and vector.magnitude(runShots[1].direction - aim) < 1e-5)
	step(q, B.Forward + B.Jump)
	run(q, B.Forward, 20)
	local airShots = step(q, B.Forward + B.Fire, yaw, pitch)
	check("in the air, as exact", not q.sim.movement.grounded and #airShots == 1 and vector.magnitude(airShots[1].direction - aim) < 1e-5)
end

do
	-- Clicked as fast as can be: six a second at most.
	local p = armed()
	local times = {}
	for i = 1, ticks(1) do
		local shots = step(p, if i % 2 == 1 then B.Fire else 0)
		if #shots > 0 then
			table.insert(times, shots[1].time)
		end
	end
	local fastest = math.huge
	for i = 2, #times do
		fastest = math.min(fastest, times[i] - times[i - 1])
	end
	-- Each on a tick, on time on average: a gap can be a tick short.
	local mean = if #times > 1 then (times[#times] - times[1]) / (#times - 1) else 0
	check(
		"clicked as fast as can be, no faster than six a second",
		#times == 5 and mean >= 1 / 6 - 1e-9 and fastest > 1 / 6 - DT - 1e-9,
		string.format("%d, %.4f s apart on average, %.4f s at least", #times, mean, fastest)
	)
end

do
	-- The last one thrown: gone 0.167 s after it, and the gun back in hand.
	local p = armed()
	for _ = 1, 4 do
		throw(p)
		run(p, 0, 30)
	end
	local last = throw(p)
	check("the fifth is the last", #last == 1 and p.sim.weapons.ammo[ULT] == 0 and p.sim.weapons.equipped == ULT)
	local n = untilGone(p, 100)
	local w = p.sim.weapons
	check("gone a sixth of a second after (the wiki's 0.167 s): 22 ticks", n ~= nil and n + 1 == 22, tostring(n and n + 1))
	check("and the Vandal drawn again", w.equipped == 1 and w.equipEndTime > p.sim.movement.tick * DT)
	check("Blade Storm is over", not p.sim.abilities.storm and string.find(AbilitySim.summary(p.sim.abilities, 0), "storm", 1, true) == nil)
	local _, again = step(p, B.Ultimate)
	check("and X does nothing, with no points", #again == 0 and w.loadout[ULT] == "")
	check("this client still asks for the fifth slot, which draws nothing", p.slot == ULT and w.equipped == 1)
	press(p, 2)
	step(p, 0)
	check("and a number key works as ever", w.equipped == 2)
end

-- All at once -----------------------------------------------------------------------------------

do
	local p = armed()
	local yaw = math.rad(-30)
	local shots = step(p, B.AltFire, yaw)
	step(p, 0)
	local aim = Accuracy.aim(yaw, 0)
	local spread, inCone = false, true
	for _, shot in shots do
		spread = spread or shot.offset > 1e-3
		inCone = inCone and shot.offset <= shot.cone.radius + 1e-6 and vector.dot(shot.direction, aim) > math.cos(math.rad(3))
	end
	check(
		"alt fire throws all five at once",
		#shots == 5 and shots[1].mode == "alt" and shots[1].pellets == 5 and p.sim.weapons.ammo[ULT] == 0
	)
	check("spread round the aim, inside their cone", spread and inCone and near(shots[1].cone.radius, 2, 1e-9))
	local n = untilGone(p, 100)
	check("gone 0.45 s after (Patch 1.09's time between bursts): 58 ticks", n ~= nil and n + 1 == 58, tostring(n and n + 1))

	local q = armed()
	throw(q)
	run(q, 0, 30)
	throw(q)
	run(q, 0, 30)
	local rest = step(q, B.AltFire)
	check("after two single throws, the burst is the three left", #rest == 3 and rest[1].pellets == 3 and q.sim.weapons.ammo[ULT] == 0)
end

-- A kill brings them back -------------------------------------------------------------------------

do
	local p = armed()
	throw(p)
	run(p, 0, 30)
	throw(p)
	run(p, 0, 30)
	local points = p.sim.abilities.points
	PlayerSim.killedWith(p.sim, "kunai", "hip")
	check("a kill with a single knife brings all five back", p.sim.weapons.ammo[ULT] == 5)
	check("and is a point, as any kill", p.sim.abilities.points == points + 1)
	throw(p)
	PlayerSim.killedWith(p.sim, "kunai", "alt")
	check("a kill with the burst brings none back (Patch 3.06)", p.sim.weapons.ammo[ULT] == 4)
	PlayerSim.killedWith(p.sim, "vandal", "hip")
	check("nor a kill with a gun", p.sim.weapons.ammo[ULT] == 4)

	-- The last one kills.
	local q = armed()
	for _ = 1, 4 do
		throw(q)
		run(q, 0, 30)
	end
	step(q, B.Fire)
	PlayerSim.killedWith(q.sim, "kunai", "hip")
	run(q, 0, 60)
	check(
		"the last one killing brings them back before they go",
		q.sim.weapons.ammo[ULT] == 5 and q.sim.weapons.equipped == ULT and q.sim.abilities.storm
	)

	-- Carried but not in hand.
	local r = armed()
	throw(r)
	press(r, 1)
	run(r, 0, 3)
	PlayerSim.killedWith(r.sim, "kunai", "hip")
	check("carried with a gun in hand, a knife's kill still brings them back", r.sim.weapons.ammo[ULT] == 5 and r.sim.weapons.equipped == 1)

	local gone = newPlayer()
	PlayerSim.killedWith(gone.sim, "kunai", "hip")
	check("with none carried, nothing comes", gone.sim.weapons.loadout[ULT] == "")
end

do
	-- A kill with the last knife, heard late: this client puts them away
	-- before the server's refill reaches it, but goes on asking for them,
	-- so the server, which brought them back, keeps them in hand.
	local server = armed()
	for _ = 1, 4 do
		throw(server)
		run(server, 0, 30)
	end
	local client: Player = { sim = PlayerSim.copy(server.sim), slot = server.slot }
	step(server, B.Fire)
	step(client, B.Fire)
	PlayerSim.killedWith(server.sim, "kunai", "hip")
	local sent = {}
	for _ = 1, 40 do
		client.slot = ask(client.sim, client.slot)
		local i = input(0, client.slot)
		PlayerSim.step(client.sim, i, cfg, floor, DT)
		table.insert(sent, i)
	end
	check("this client puts them away, as far as it knows", client.sim.weapons.loadout[ULT] == "" and client.sim.weapons.equipped == 1)
	check("but goes on asking for them", client.slot == ULT)
	for _, i in sent do
		PlayerSim.step(server.sim, i, cfg, floor, DT)
	end
	check("so the server keeps them in hand", server.sim.weapons.equipped == ULT and server.sim.weapons.ammo[ULT] == 5)
end

-- Guns and X again ----------------------------------------------------------------------------------

do
	-- The input's slot catches up a tick late: until it does, the slot it
	-- was asking for doesn't take the knives out of hand.
	local p = newPlayer()
	PlayerSim.step(p.sim, input(B.Ultimate, 1), cfg, floor, DT)
	for _ = 1, 50 do
		PlayerSim.step(p.sim, input(0, 1), cfg, floor, DT)
	end
	local w = p.sim.weapons
	check("a stale slot doesn't put them away", w.equipped == ULT and w.hold == 1)
	PlayerSim.step(p.sim, input(0, 2), cfg, floor, DT)
	check("another slot does: the Classic drawn", w.equipped == 2 and w.hold == 0)
	check("and the knives still carried, all five", w.loadout[ULT] == "kunai" and w.ammo[ULT] == 5 and p.sim.abilities.storm)
	PlayerSim.step(p.sim, input(0, 1), cfg, floor, DT)
	check("the Vandal too", w.equipped == 1)
end

do
	local p = armed()
	throw(p)
	press(p, 2)
	run(p, 0, 3)
	local w = p.sim.weapons
	check("a number key draws a gun, the knives kept", w.equipped == 2 and w.loadout[ULT] == "kunai" and w.ammo[ULT] == 4)
	local fired = 0
	for i = 1, 150 do
		fired += #step(p, if i % 2 == 1 then B.Fire else 0)
	end
	check("which fires as ever", fired > 0 and w.ammo[ULT] == 4)
	local _, casts = step(p, B.Ultimate)
	check("X draws the knives again", #casts == 1 and casts[1].kind == "draw" and w.equipped == ULT and w.ammo[ULT] == 4)
	check("back to the Classic when they're gone", w.back == 2)
	local n = untilReady(p, B.Fire, 100)
	check("ready 0.5 s after (the wiki's re-equip): 64 ticks", n == 64, tostring(n))
	check("and asked for from the tick after", p.slot == ULT)
	local before = w.equipEndTime
	local _, inHand = step(p, B.Ultimate)
	step(p, 0)
	check("X with them in hand changes nothing", #inHand == 1 and w.equipEndTime == before and w.equipped == ULT)
end

do
	-- Switched away with none left: gone at once.
	local p = armed()
	for _ = 1, 4 do
		throw(p)
		run(p, 0, 30)
	end
	step(p, B.Fire)
	press(p, 1)
	step(p, 0)
	step(p, 0)
	check(
		"switched away with none left, they're gone",
		p.sim.weapons.loadout[ULT] == "" and p.sim.weapons.equipped == 1 and not p.sim.abilities.storm
	)
end

-- With the rest of the kit ----------------------------------------------------------------------------

do
	-- Cloudburst puts them away for a moment, as it does a gun.
	local p = armed()
	step(p, B.AbilityC)
	local w = p.sim.weapons
	check("a Cloudburst throw puts the knives away for a moment", w.equipped == ULT and w.equipEndTime > p.sim.movement.tick * DT)
	local n = untilReady(p, B.Fire, 100)
	check("and they're back after its 0.25 s", n == ticks(AbilityConfig.Cloudburst.stow.value), tostring(n))

	-- Tailwind: nothing's thrown in the dash, and they're there after it.
	local q = armed()
	step(q, B.AbilityE)
	run(q, 0, ticks(AbilityConfig.Jett.windup.value) + 1)
	local _, dash = step(q, B.AbilityE + B.Left)
	local during = 0
	for i = 1, ticks(AbilityConfig.Jett.dashTime.value) - 2 do
		during += #step(q, if i % 2 == 1 then B.Fire else 0)
	end
	check("nothing's thrown in a dash", #dash == 1 and dash[1].kind == "dash" and during == 0)
	run(q, 0, 10)
	check("and the knives are there after it", #throw(q) == 1 and q.sim.weapons.ammo[ULT] == 4)

	-- Updraft: thrown from the top of it, as exact.
	local r = armed()
	step(r, B.AbilityQ)
	run(r, 0, 30)
	local yaw, pitch = math.rad(10), math.rad(-40)
	local shots = step(r, B.Fire, yaw, pitch)
	check(
		"thrown from up an Updraft, as exact",
		not r.sim.movement.grounded and #shots == 1 and vector.magnitude(shots[1].direction - Accuracy.aim(yaw, pitch)) < 1e-5
	)
end

-- What ends it --------------------------------------------------------------------------------------

do
	local p = armed()
	throw(p)
	AbilitySim.died(p.sim.abilities)
	step(p, 0)
	check(
		"a death ends it, and the knives go",
		not p.sim.abilities.storm and p.sim.weapons.loadout[ULT] == "" and p.sim.weapons.equipped == 1
	)

	local q = armed()
	AbilitySim.newRound(q.sim.abilities)
	step(q, 0)
	check("so does a new round", q.sim.weapons.loadout[ULT] == "" and q.sim.weapons.equipped == 1)

	local fresh = PlayerSim.new(vector.create(0, 0, 0), { "vandal", "classic", "knife", "", "kunai" })
	check("and no life starts with them", fresh.weapons.loadout[ULT] == "" and fresh.weapons.ammo[ULT] == 0)
end

-- The course ----------------------------------------------------------------------------------------

do
	local k = AbilitySim.new()
	AbilitySim.fill(k)
	check("filling the charges leaves the points", k.points == 0 and AbilitySim.full(k) and not AbilitySim.full(k, true))
	AbilitySim.fill(k, true)
	check("the course fills the ultimate's too", k.points == 8 and AbilitySim.full(k, true) and AbilitySim.charged(k))

	local p = armed()
	local kit = p.sim.abilities
	kit.charges[AbilityConfig.Q] = 0
	check(
		"in Blade Storm, a spent charge is still short on the course",
		AbilitySim.full(kit, true) == false and not AbilitySim.busy(kit, 0)
	)
	AbilitySim.fill(kit, true)
	check(
		"which come back, and the points wait for it to end",
		kit.charges[AbilityConfig.Q] == 1 and kit.points == 0 and AbilitySim.full(kit, true)
	)
end

-- The wire --------------------------------------------------------------------------------------------

do
	local p = armed()
	throw(p)
	press(p, 2)
	run(p, 0, 3)
	step(p, B.Ultimate)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	local a, b = p.sim.weapons, decoded.weapons
	check(
		"the ack carries the knives, where the hand goes back and the slot held",
		b.loadout[ULT] == "kunai" and b.ammo[ULT] == 4 and b.equipped == ULT and b.back == a.back and b.hold == a.hold and a.hold ~= 0
	)
	check("and the kit in Blade Storm", decoded.abilities.storm == true)
	local copy = decoded :: PlayerSim.State
	local same = true
	local left: Player = { sim = copy, slot = p.slot }
	for i = 1, 200 do
		local buttons = if i == 70 then B.Fire elseif i == 101 then B.AltFire else 0
		local s1 = step(p, buttons)
		local s2 = step(left, buttons)
		same = same and #s1 == #s2 and p.sim.weapons.ammo[ULT] == copy.weapons.ammo[ULT] and p.sim.weapons.equipped == copy.weapons.equipped
	end
	check(
		"and a replay from it throws knife for knife, to the same end",
		same and copy.weapons.loadout[ULT] == "" and not copy.abilities.storm
	)
end

return nil
