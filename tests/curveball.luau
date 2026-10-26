--!strict
-- Phoenix's Curveball (system 30): Phoenix and his kit, Curveball's numbers
-- and where they come from, its charges through rounds and kills, the
-- flare in hand (E, its equip, fire and alt fire throwing it round to the
-- left and the right, the gun back after, and what puts it away
-- unthrown), its flight (straight, a quarter turn to the side, stopped by
-- the level, popping at its windup), the blind its pop gives (by how the
-- eye faces it and how far off it is, white and then clearing, and two
-- blinds together), and the wire carrying the flare in hand.

local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local AbilityConfig = require("../src/shared/Abilities/AbilityConfig")
local AbilitySim = require("../src/shared/Abilities/AbilitySim")
local AgentSelect = require("../src/shared/Abilities/AgentSelect")
local FlareSim = require("../src/shared/Abilities/FlareSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
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
local CV = AbilityConfig.Curveball
local FLARE = WeaponConfig.Defs.flare
local ULT = WeaponSim.ULT
local C, Q, E, X = AbilityConfig.C, AbilityConfig.Q, AbilityConfig.E, AbilityConfig.X
local PHOENIX = "phoenix"

local function ticks(seconds: number): number
	return math.floor(seconds / DT + 0.5)
end

local function input(buttons: number, slot: number?, yaw: number?, pitch: number?)
	return { seq = 0, buttons = buttons, slot = slot or 1, yaw = yaw or 0, pitch = pitch or 0, viewTime = 0 }
end

-- A player, and the slot their client asks for.
type Player = { sim: PlayerSim.State, slot: number }

-- The slot the client asks for this tick, by PlayerController's rules (as
-- the Blade Storm tests have them).
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
local function step(
	p: Player,
	buttons: number,
	yaw: number?,
	pitch: number?,
	objective: Spike.Context?
): ({ WeaponSim.Shot }, { AbilitySim.Cast })
	p.slot = ask(p.sim, p.slot)
	local shots, _, _, _, casts = PlayerSim.step(p.sim, input(buttons, p.slot, yaw, pitch), cfg, floor, DT, objective)
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

-- A number key, as PlayerController.selectSlot takes it.
local function press(p: Player, slot: number)
	if p.sim.weapons.loadout[slot] ~= "" then
		p.slot = slot
	end
end

local function now(p: Player): number
	return p.sim.movement.tick * DT
end

-- Phoenix settled on the floor at `feet` with the Vandal drawn and every
-- charge.
local function newPlayer(feet: vector?): Player
	local sim = PlayerSim.new(feet or vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" })
	sim.abilities = AbilitySim.new(PHOENIX)
	AbilitySim.fill(sim.abilities)
	local p = { sim = sim, slot = 1 }
	run(p, 0, ticks(1.5))
	return p
end

-- E tapped, and the flare's equip waited out.
local function inHand(feet: vector?): Player
	local p = newPlayer(feet)
	step(p, B.AbilityE)
	run(p, 0, ticks(FLARE.equipTime.value) + 1)
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

H.section("Curveball tests")

-- Phoenix --------------------------------------------------------------------------------------

do
	local agent = AbilityConfig.Agents[PHOENIX]
	check(
		"Phoenix's kit: Blaze on C, Hot Hands on Q, Curveball on E, Run it Back on X (since Patch 9.10)",
		agent ~= nil
			and agent.abilities[C] == "blaze"
			and agent.abilities[Q] == "hothands"
			and agent.abilities[E] == "curveball"
			and agent.abilities[X] == "runitback"
	)
	check("a Duelist, as Riot's agent page has him, with Inner Fire", agent.role == "Duelist" and agent.passive == "innerfire")
	local d = AbilityConfig.Defs
	check(
		"each in its own slot, of its kind",
		d.blaze.slot == C
			and d.hothands.slot == Q
			and d.curveball.slot == E
			and d.runitback.slot == X
			and d.blaze.kind == "basic"
			and d.hothands.kind == "basic"
			and d.curveball.kind == "signature"
			and d.runitback.kind == "ultimate"
	)
	check(
		"Run it Back needs 7 points (Patch 13.02), Hot Hands costs 200 (Patch 9.10), Blaze 150",
		d.runitback.points ~= nil
			and d.runitback.points.value == 7
			and d.runitback.points.status == "confirmed"
			and d.hothands.cost ~= nil
			and d.hothands.cost.value == 200
			and d.blaze.cost ~= nil
			and d.blaze.cost.value == 150
	)
	check(
		"all of his can be played: Curveball, Hot Hands (system 31), Blaze (system 32) and Run it Back (system 33), and Inner Fire works",
		AbilitySim.playable("curveball")
			and AbilitySim.playable("hothands")
			and AbilitySim.playable("blaze")
			and AbilitySim.playable("innerfire")
			and AbilitySim.playable("runitback")
			and AbilitySim.playable("drift")
	)
	local pickable = AgentSelect.pickable()
	check("so he can be picked, after Jett", pickable[1] == "jett" and pickable[2] == PHOENIX and #pickable == 2)
	check(
		"and he's second on the wire",
		AbilityConfig.AgentIds[2] == PHOENIX and AbilityConfig.AgentIndex[PHOENIX] == 2 and AbilityConfig.Passives.innerfire ~= nil
	)
	local TDM = AbilityConfig.TeamDeathmatch
	check(
		"Team Deathmatch's numbers for him, the wiki's: Curveball back in 44 s, Run it Back 70 points",
		TDM.cooldowns.curveball.value == 44 and TDM.ultimate.runitback.value == 70
	)
end

-- Curveball's numbers ---------------------------------------------------------------------------

do
	local labelled = true
	local function label(param: any)
		labelled = labelled
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
			and #param.source > 0
	end
	for _, param in CV do
		label(param)
	end
	local def = AbilityConfig.Defs.curveball
	for _, param in { def.cost, def.charges, AbilityConfig.Defs.blaze.cost, AbilityConfig.Defs.hothands.charges } do
		label(param)
	end
	check("every Curveball number says where it's from", labelled)
	check(
		"250 a charge (Patch 3.0), two of them, one free each round (Patch 9.10)",
		def.cost ~= nil
			and def.cost.value == 250
			and def.cost.status == "confirmed"
			and def.charges ~= nil
			and def.charges.value == 2
			and def.free == 1
	)
	local recharge = def.recharge
	check(
		"and one back for two kills (Patch 9.10)",
		recharge ~= nil and recharge.kind == "kills" and recharge.kills.value == 2 and recharge.kills.status == "confirmed"
	)
	check("a 0.6 s windup to the pop (Patch 11.00)", CV.windup.value == 0.6 and CV.windup.status == "confirmed")
	check("a blind of 1.5 s at most (Patch 5.01), clearing over a second (the wiki)", CV.maxBlind.value == 1.5 and CV.fade.value == 1)
	check(
		"0.8 s to put it in hand and 0.48 s to have the gun back (the wiki)",
		FLARE.equipTime.value == 0.8 and CV.unequip.value == 0.48 and FLARE.equipTime.status == "community"
	)
	check(
		"the flare, a weapon of the fifth slot that's never reloaded, and Curveball's",
		FLARE.category == "ability"
			and FLARE.slot == ULT
			and FLARE.ability == "curveball"
			and def.weapon == "flare"
			and FLARE.magazine.value == 1
			and FLARE.reserve.value == 0
	)
	local item = Shop.item("curveball")
	check(
		"Curveball's charges are sold on E, the flare never",
		item ~= nil and item.price == 250 and item.slot == "E" and Shop.item("flare") == nil
	)
end

-- The kit through a match ---------------------------------------------------------------------

do
	local k = AbilitySim.new(PHOENIX)
	check("a new kit: Curveball's free charge and nothing else", k.charges[C] == 0 and k.charges[Q] == 0 and k.charges[E] == 1)
	check("a second can be bought", AbilitySim.canBuy(k, "curveball") and AbilitySim.buy(k, "curveball") and k.charges[E] == 2)
	check("but not a third", not AbilitySim.buy(k, "curveball") and k.charges[E] == 2)
	check("and Blaze's one, once", AbilitySim.buy(k, "blaze") and not AbilitySim.buy(k, "blaze") and k.charges[C] == 1)
	AbilitySim.newRound(k)
	check("both carry into the next round", k.charges[E] == 2)
	k.charges[E] = 0
	AbilitySim.newRound(k)
	check("and each round gives the free one back", k.charges[E] == 1)
	AbilitySim.killed(k)
	AbilitySim.killed(k)
	check("two kills bring one back", k.charges[E] == 2 and k.regained == 1)
	AbilitySim.newRound(k)
	check("which goes at the round's end", k.charges[E] == 1)
	AbilitySim.fill(k)
	check("the course fills it to two", k.charges[E] == 2 and AbilitySim.full(k))
end

-- In hand --------------------------------------------------------------------------------------

do
	local p = newPlayer()
	local before = p.sim.abilities.charges[E]
	local _, casts = step(p, B.AbilityE)
	local cast = casts[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("E puts the flare in hand", cast ~= nil and cast.kind == "equip" and cast.ability == "curveball")
	check("from the fifth slot, the gun it came from remembered", w.equipped == ULT and w.loadout[ULT] == "flare" and w.back == 1)
	check("with nothing spent yet", kit.charges[E] == before and kit.holding == E)
	check("the kit says so", string.find(AbilitySim.summary(kit, now(p)), "equip", 1, true) ~= nil)
	check("it runs as fast as the knife", near(PlayerSim.maxSpeed(p.sim, cfg), 6.75, 1e-9))
	-- How long until a press throws it, tried on a copy each tick.
	local waited: number? = nil
	for n = 1, ticks(2) do
		local probe = PlayerSim.copy(p.sim)
		local _, _, _, _, probed = PlayerSim.step(probe, input(B.Fire, ask(p.sim, p.slot)), cfg, floor, DT)
		if probed and #ofKind(probed, "flare") > 0 then
			waited = n
			break
		end
		step(p, 0)
	end
	check(
		"it can be thrown once its 0.8 s equip is over",
		waited ~= nil and math.abs(waited - ticks(FLARE.equipTime.value)) <= 1,
		string.format("%s ticks", tostring(waited))
	)
	check("the client asks for it, so it stays", p.slot == ULT)
end

do
	local p = inHand()
	local yaw, pitch = 0.4, 0.1
	local shots, casts = step(p, B.Fire, yaw, pitch)
	local thrown = ofKind(casts, "flare")[1]
	local w, kit = p.sim.weapons, p.sim.abilities
	check("fire throws it", thrown ~= nil and thrown.ability == "curveball" and thrown.slot == E)
	check("round to the left", thrown ~= nil and thrown.curve == -1)
	check(
		"from the eye, along the crosshair",
		thrown ~= nil
			and vector.magnitude(thrown.origin - PlayerSim.eye(p.sim, cfg)) < 1e-6
			and vector.magnitude(thrown.direction - Accuracy.aim(yaw, pitch)) < 1e-6
	)
	check("as a throw, not a bullet", #shots == 0)
	check("its charge spent", kit.charges[E] == 1 and kit.holding == 0)
	check("the flare gone, and the gun back in hand", w.loadout[ULT] == "" and w.equipped == 1)
	check("ready 0.48 s after", near(w.equipEndTime - now(p), CV.unequip.value, 1e-9), string.format("%.4f s", w.equipEndTime - now(p)))
	local more = run(p, B.Fire, ticks(CV.unequip.value) + 2)
	check("and firing after that", #more > 0 and more[1].weapon == "vandal")
end

do
	local p = inHand()
	local _, casts = step(p, B.AltFire)
	local thrown = ofKind(casts, "flare")[1]
	check("alt fire throws it round to the right", thrown ~= nil and thrown.curve == 1)
	check("and doesn't zoom the gun", p.sim.weapons.scoped == 0)
end

do
	local p = newPlayer()
	step(p, B.AbilityE)
	local _, casts = run(p, B.Fire, ticks(FLARE.equipTime.value) + 2)
	local thrown = ofKind(casts, "flare")
	check("fire held from the start throws it as soon as it's in hand", #thrown == 1)
	local again = ofKind(select(2, run(p, B.Fire, ticks(1))), "flare")
	check("once: another throw is another E", #again == 0 and p.sim.weapons.loadout[ULT] == "")
end

do
	local p = newPlayer()
	step(p, B.AbilityE)
	run(p, 0, 10)
	local _, casts = step(p, B.AbilityE)
	local w, kit = p.sim.weapons, p.sim.abilities
	check("E again puts it away unthrown", #casts == 0 and kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 1)
	check("its charge kept", kit.charges[E] == 2)
	check(
		"and the gun drawn again, its own draw",
		near(w.equipEndTime - now(p), WeaponConfig.Defs.vandal.equipTime.value, 1e-9),
		string.format("%.4f s", w.equipEndTime - now(p))
	)
	run(p, 0, 2)
	local _, back = step(p, B.AbilityE)
	check("and E puts it in hand again", #back == 1 and back[1].kind == "equip" and p.sim.weapons.equipped == ULT)
end

do
	local p = inHand()
	press(p, 2)
	step(p, 0)
	local w, kit = p.sim.weapons, p.sim.abilities
	check("drawing a gun puts it away unthrown", kit.holding == 0 and w.loadout[ULT] == "" and w.equipped == 2 and kit.charges[E] == 2)
	local _, casts = run(p, B.Fire, 3)
	check("and fire is the gun's again", #ofKind(casts, "flare") == 0)
	press(p, 1)
	step(p, B.AbilityE)
	run(p, 0, 3)
	press(p, 3)
	step(p, 0)
	check("so does the knife", p.sim.abilities.holding == 0 and p.sim.weapons.equipped == 3 and p.sim.weapons.loadout[ULT] == "")
end

do
	local p = newPlayer()
	p.sim.abilities.charges[E] = 0
	local _, casts = step(p, B.AbilityE)
	check("with no charge, E does nothing", #casts == 0 and p.sim.weapons.equipped == 1 and p.sim.abilities.holding == 0)
end

do
	local p = inHand()
	AbilitySim.died(p.sim.abilities)
	step(p, 0)
	check("a death puts it away", p.sim.abilities.holding == 0 and p.sim.weapons.loadout[ULT] == "" and p.sim.weapons.equipped == 1)
	local q = inHand()
	AbilitySim.sell(q.sim.abilities, "curveball")
	AbilitySim.sell(q.sim.abilities, "curveball")
	step(q, 0)
	check("and so does selling its last charge back", q.sim.abilities.holding == 0 and q.sim.weapons.loadout[ULT] == "")
end

do
	local site = Spike.CourseSites[1]
	local feet = vector.create(site.center.x, 0.02, site.center.z)
	local planted = feet - vector.create(0, 0.02, 1)
	local context: Spike.Context = {
		zones = Spike.CourseSites,
		canPlant = true,
		canDefuse = true,
		planted = planted,
		halfSaved = false,
		sees = nil,
	}
	local p = inHand(feet)
	step(p, B.Use, nil, nil, context)
	check(
		"and so does a defuse",
		p.sim.spike.channel == SpikeSim.DEFUSING and p.sim.abilities.holding == 0 and p.sim.weapons.loadout[ULT] == ""
	)
end

do
	local p = newPlayer()
	local thrown = 0
	for _ = 1, 3 do
		step(p, B.AbilityE)
		run(p, 0, ticks(FLARE.equipTime.value) + 1)
		local _, casts = step(p, B.Fire)
		thrown += #ofKind(casts, "flare")
		run(p, 0, ticks(1))
	end
	check("two charges, two throws, and no third", thrown == 2 and p.sim.abilities.charges[E] == 0)
end

-- Its flight ------------------------------------------------------------------------------------

local AHEAD = vector.create(0, 0, -1)
local EYE = vector.create(0, 1.6, 0)

do
	local f = FlareSim.throw(1, 1, EYE, AHEAD, -1)
	for _ = 1, ticks(CV.straight.value) - 1 do
		FlareSim.step(f, DT, floor)
	end
	check("straight ahead at first", math.abs(f.position.x) < 1e-6 and f.position.z < 0)
	local path = FlareSim.fly(f, DT, floor)
	local pop = path[#path]
	check("then round to the left", pop.x < -1, string.format("x %.2f", pop.x))
	check("a quarter turn, and no further", near(vector.dot(vector.normalize(f.velocity), vector.create(-1, 0, 0)), 1, 1e-6))
	check("at its speed all the way", near(vector.magnitude(f.velocity), CV.speed.value, 1e-4))
	check("with no drop", near(pop.y, EYE.y, 1e-5))
	local whole = FlareSim.fly(FlareSim.throw(1, 3, EYE, AHEAD, -1), DT, floor)
	check(
		"popping its windup after the throw",
		#whole - 1 == math.ceil(CV.windup.value / DT - 1e-6) and near(f.age, FlareSim.popTime(DT), 1e-9)
	)
	print(string.format("    a level throw pops %.2f m ahead and %.2f m to the side (ours)", -pop.z, -pop.x))
	local right = FlareSim.fly(FlareSim.throw(1, 2, EYE, AHEAD, 1), DT, floor)
	local mirror = right[#right]
	check("and round to the right just as far", near(mirror.x, -pop.x, 1e-4) and near(mirror.z, pop.z, 1e-4))
	local up = FlareSim.fly(FlareSim.throw(1, 3, EYE, vector.normalize(vector.create(0, 1, -1)), -1), DT, floor)
	check("thrown up, it climbs all the way", up[#up].y > EYE.y + 2 and up[#up].y > up[#up - 1].y)
end

do
	-- A wall 2 m ahead, its face at z = -2.
	local world = FakeWorld.new():addFloor():addBox(vector.create(-5, 0, -3), vector.create(5, 4, -2))
	local f = FlareSim.throw(1, 4, EYE, AHEAD, -1)
	local path = FlareSim.fly(f, DT, world)
	local pop = path[#path]
	check("the level stops it", f.stopped ~= nil and near(pop.z, -2 + CV.size.value, 1e-3), string.format("z %.3f", pop.z))
	check("and it pops there, on time", f.age >= CV.windup.value - 1e-9 and vector.magnitude(pop - path[#path - 1]) < 1e-9)
	local told = FlareSim.throw(1, 4, EYE, AHEAD, -1)
	local again = FlareSim.fly(told, DT, nil, f.stopped)
	check("the path alone, stopped where the server says, ends at the same place", vector.magnitude(again[#again] - pop) < 1e-4)
	check(
		"and is drawn between its ticks, held at the pop after",
		vector.magnitude(FlareSim.at(path, 1.5 * DT, DT) - (path[2] + path[3]) * 0.5) < 1e-5
			and vector.magnitude(FlareSim.at(path, 5, DT) - pop) < 1e-9
			and vector.magnitude(FlareSim.at(path, 0, DT) - EYE) < 1e-9
	)
end

-- The blind -------------------------------------------------------------------------------------

do
	local look = AHEAD
	local function at(angle: number, distance: number): vector
		local r = math.rad(angle)
		return EYE + vector.create(-math.sin(r), 0, -math.cos(r)) * distance
	end
	check("looking at it from near, all of the longest blind", FlareSim.strength(at(0, 5), EYE, look) == 1)
	check("and within the view's sides", FlareSim.strength(at(CV.fullAngle.value, 5), EYE, look) == 1)
	local edge = FlareSim.strength(at(CV.edgeAngle.value, 5), EYE, look)
	local between = FlareSim.strength(at((CV.fullAngle.value + CV.edgeAngle.value) / 2, 5), EYE, look)
	check("less off the screen, a brief share", near(edge, CV.away.value, 1e-9) and edge < 0.3)
	check("in between, in between", between < 1 and between > edge)
	check("with its back to it, that brief share still", near(FlareSim.strength(at(180, 5), EYE, look), CV.away.value, 1e-9))
	local farther = FlareSim.strength(at(0, (CV.near.value + CV.far.value) / 2), EYE, look)
	check("further off, less", farther < 1 and farther > 0)
	check("and very far off, none", FlareSim.strength(at(0, CV.far.value + 1), EYE, look) == 0)
	check("too little to tell is none", FlareSim.strength(at(180, CV.far.value - 1), EYE, look) == 0)
	local world = FakeWorld.new():addFloor():addBox(vector.create(-5, 0, -3), vector.create(5, 4, -2))
	check("a wall in between hides it", not FlareSim.seen(at(0, 5), EYE, world))
	check("nothing between, it's seen", FlareSim.seen(at(0, 1.5), EYE, world) and FlareSim.seen(at(180, 5), EYE, world))
end

do
	local b = FlareSim.blind(nil, 100, 1)
	check("a full blind: white for 1.5 s, gone a second after", b.from == 100 and near(b.full, 101.5, 1e-9) and near(b.gone, 102.5, 1e-9))
	check(
		"the screen white, then clearing evenly",
		FlareSim.whiteAt(b, 100) == 1
			and FlareSim.whiteAt(b, 101.4) == 1
			and near(FlareSim.whiteAt(b, 102), 0.5, 1e-9)
			and FlareSim.whiteAt(b, 102.5) == 0
	)
	local brief = FlareSim.blind(nil, 100, CV.away.value)
	check(
		"a brief one, briefly",
		near(brief.full - 100, CV.away.value * CV.maxBlind.value, 1e-9)
			and near(brief.gone - brief.full, CV.away.value * CV.fade.value, 1e-9)
	)
	local weaker = FlareSim.blind(b, 100.5, 0.2)
	check("a weaker one on top leaves it as it was", weaker.from == 100 and weaker.full == b.full and weaker.gone == b.gone)
	local stronger = FlareSim.blind(b, 101, 1)
	check(
		"a stronger one on top makes it longer",
		stronger.from == 101 and near(stronger.full, 102.5, 1e-9) and near(stronger.gone, 103.5, 1e-9)
	)
	local after = FlareSim.blind(b, 110, 0.5)
	check("and one long after is a blind of its own", after.from == 110 and near(after.full, 110.75, 1e-9))
	local text = FlareSim.encode({ from = 1761400000.25, full = 1761400001.75, gone = 1761400002.75 })
	local back = FlareSim.decode(text)
	check(
		"its attribute comes back to it, at server time's size",
		back ~= nil and back.from == 1761400000.25 and back.gone == 1761400002.75,
		text
	)
	check("and anything else is none", FlareSim.decode("white") == nil and FlareSim.decode(nil) == nil and FlareSim.decode(3) == nil)
end

-- The wire -------------------------------------------------------------------------------------

do
	local p = newPlayer()
	step(p, B.AbilityE)
	run(p, 0, 20)
	local _, decoded = PlayerCodec.decodeAck(PlayerCodec.encodeAck(9, p.sim))
	local a, b = p.sim.weapons, decoded.weapons
	check(
		"the ack carries the flare in hand",
		decoded.abilities.holding == E
			and decoded.abilities.agent == PHOENIX
			and b.loadout[ULT] == "flare"
			and b.equipped == ULT
			and b.back == a.back
	)
	local copy = decoded :: PlayerSim.State
	local left: Player = { sim = copy, slot = p.slot }
	local same = true
	local throws = 0
	for i = 1, 200 do
		local buttons = if i == 90 then B.AltFire elseif i == 140 then B.AbilityE elseif i >= 150 and i < 160 then B.Fire else 0
		local _, c1 = step(p, buttons)
		local _, c2 = step(left, buttons)
		local f1, f2 = ofKind(c1, "flare"), ofKind(c2, "flare")
		throws += #f1
		same = same and #f1 == #f2 and (f1[1] == nil or f1[1].curve == f2[1].curve) and p.sim.weapons.equipped == copy.weapons.equipped
	end
	check(
		"and a replay from it throws as it does, to the same end",
		same and throws == 1 and copy.abilities.charges[E] == 1,
		tostring(throws)
	)
end

return nil
