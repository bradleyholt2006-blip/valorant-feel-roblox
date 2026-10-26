--!strict
-- The ability kit (system 17), stepped inside PlayerSim from the same input
-- as movement and weapons, so the client predicts it and the server runs
-- exactly the same ticks.
--
-- C, Q and E each hold charges, and X the ultimate's points. Pressing an
-- ability's key casts it when it has a charge, and what the cast does is the
-- ability's own. Jett's:
--   * Updraft (Q) lifts her straight up at once, at a steady speed for its
--     time, and then she falls as from a jump. It works in the air too
--   * Tailwind (E) spends its charge to ready a gust: after the windup a
--     window opens, and E within it dashes her the way she's moving (forward
--     if she isn't), straight and level for the dash's time, whatever was
--     under way. A dash ends a lift, and nothing fires during it. As it ends
--     she keeps no more than her run speed
--   * Cloudburst (C, system 18) throws a cloud from her eye the way she's
--     looking, and puts her gun away for a moment. CloudSim flies it: this
--     only says it was thrown
--   * Blade Storm (X, system 19) spends the ultimate's points once they're
--     full, and while it lasts X draws its knives again. The knives are a
--     weapon of their own (WeaponSim's fifth slot), which PlayerSim puts in
--     hand: this says when, and it's over once they're gone
-- And her passive, Drift (system 20): with jump held, a fall is held to a
-- glide, which MovementSim does. It takes no charge, and nothing but a dash
-- or a lift under way stops it.
-- Phoenix's Curveball (E, system 30) puts its flare in hand, if it has a
-- charge: a weapon of its own in WeaponSim's fifth slot, which PlayerSim
-- puts there. Fire or alt fire throws it once it's in hand, which spends
-- the charge (thrown), and E again, or drawing anything else, puts it away
-- unthrown. FlareSim flies it. His Hot Hands (Q, system 31) puts its
-- fireball in hand the same way, in place of the flare if that's there:
-- fire throws it and alt fire lobs it, FireballSim flies it and FireSim
-- burns where it bursts. His Blaze (C, system 32) puts its flame in hand
-- the same way, and fire sends its wall out (thrown): the flame stays in
-- hand while fire's held, bending the wall, until PlayerSim lets it go
-- (steering), and BlazeSim runs it and stands the wall where it ends. And
-- his passive, Inner Fire, has their fire heal him (FireSim too). His Run
-- it Back (X, system 33) spends the ultimate's points once they're full and
-- marks where he stands and the way he faces; its activation puts his gun
-- away (PlayerSim) and nothing else casts meanwhile. As its time runs out,
-- or the server spares him a hit that would have killed him while it runs
-- (fizzle), his body's gone, and once it's been gone its time he's back at
-- the mark (PlayerSim) and rises there. Through all of his return he's
-- held: nothing he presses does anything.
-- Sage's Healing Orb (E, system 36) puts its orb in hand the same way, but
-- it isn't thrown: fire tries it on the ally under the crosshair and alt
-- fire on herself, a try at a time, and it stays in hand, its charge with
-- it, until the server finds a try heals someone (HealServer), spends the
-- charge and puts it away (used). Her Slow Orb (Q, system 37) puts its orb
-- in hand as Hot Hands does its fireball: fire throws it (there's no lob),
-- SlowSim flies it, and its field slows whoever's in it (PlayerSim).
--
-- The server changes the kit between ticks, as it does a loadout: charges
-- bought and sold, the signature's free charge each round, ultimate points
-- for kills, deaths, plants and defuses, and a signature charge back for
-- kills; and in Team Deathmatch (system 28) charges back over time, and
-- what the ultimate needs. The ack carries the kit, so the owner's
-- prediction agrees.
--
-- No Roblox APIs here.

local AbilityConfig = require("./AbilityConfig")
local MovementSim = require("../Movement/MovementSim")
local Accuracy = require("../Weapons/Accuracy")

export type State = {
	agent: string, -- an AbilityConfig.Agents id, or AbilityConfig.NO_AGENT for no abilities
	charges: { number }, -- by slot: C, Q and E (X's is always 0)
	-- Signature charges that came back by recharge this round, which the next
	-- round takes back (the VALORANT Wiki: they "will not be kept").
	regained: number,
	kills: number, -- kills towards the signature's next charge
	points: number, -- ultimate points
	-- What the ultimate needs in the mode played, 0 for its own (Team
	-- Deathmatch's costs more, system 28).
	need: number,
	held: number, -- the kit's keys held last tick, as input buttons
	-- A readied ability's window (Tailwind's): when it opens and closes, 0
	-- for none.
	readyFrom: number,
	readyUntil: number,
	-- A lift under way (Updraft): when it ends, 0 for none.
	liftUntil: number,
	-- A dash under way (Tailwind): when it ends, 0 for none, and its
	-- velocity, level.
	dashUntil: number,
	dashX: number,
	dashZ: number,
	-- The ultimate under way (Blade Storm): its knives are carried.
	-- PlayerSim ends it when they're gone.
	storm: boolean,
	-- The slot whose ability is in hand (Curveball's flare, system 30, Hot
	-- Hands' fireball, system 31, the Healing Orb, system 36, or the Slow
	-- Orb, system 37), 0 for none.
	-- PlayerSim puts it away when the hand goes elsewhere.
	holding: number,
	-- The slot whose wall is being bent (Blaze, system 32), 0 for none, and
	-- when its run's over, the longest it's bent for: its flame stays in
	-- hand until then, or until fire's let go (PlayerSim).
	steering: number,
	steerUntil: number,
	-- Run it Back (system 33): when it runs out, 0 when it isn't running;
	-- where it was cast (the feet), the way he faced, and whether he stood
	-- on the ground and crouched; and when his return started (his body
	-- gone), 0 for none.
	backUntil: number,
	mark: vector,
	markYaw: number,
	markGrounded: boolean,
	markCrouched: boolean,
	returnAt: number,
}

-- A cast, for the server to tell others of (its sound and look): "lift",
-- "ready", "dash", "throw", "storm" (Blade Storm cast), "draw" (its knives
-- drawn again), "equip" (an ability put in hand), "flare" (Curveball's
-- thrown), "fireball" (Hot Hands' thrown), "flame" (Blaze's sent out),
-- "mark" (Run it Back cast), "fizzle" (his body gone as it runs out),
-- "rise" (back at its mark), "heal" (the Healing Orb tried on an ally),
-- "selfheal" (tried on herself) or "slow" (the Slow Orb thrown), where the
-- player's feet and eye were, and
-- the way it goes (the dash's way, up for a lift, the way they faced for a
-- readied gust and for Run it Back's, the way they looked for the rest). A
-- flare's says which way round it curves, and a fireball's whether it was
-- lobbed.
export type Cast = {
	slot: number,
	ability: string,
	kind: string,
	tick: number,
	time: number,
	position: vector,
	origin: vector,
	direction: vector,
	curve: number?, -- a flare's: -1 round to the left, 1 to the right
	lob: boolean?, -- a fireball's: thrown underhand, by alt fire
}

local AbilitySim = {}

local C, E, X = AbilityConfig.C, AbilityConfig.E, AbilityConfig.X
local J = AbilityConfig.Jett
local RB = AbilityConfig.RunItBack
local B = MovementSim.Buttons
local EPS = 1e-9
local UP = vector.create(0, 1, 0)
local ZERO = vector.create(0, 0, 0)

-- The input button for each slot's key, and all of them.
AbilitySim.BUTTONS = { B.AbilityC, B.AbilityQ, B.AbilityE, B.Ultimate }
local ALL = bit32.bor(B.AbilityC, B.AbilityQ, B.AbilityE, B.Ultimate)

-- Abilities whose casts are written, and passives that work; the rest
-- can't be bought or cast yet.
local PLAYABLE: { [string]: boolean } = {
	cloudburst = true,
	updraft = true,
	tailwind = true,
	bladestorm = true,
	drift = true,
	curveball = true,
	hothands = true,
	blaze = true,
	runitback = true,
	innerfire = true,
	healingorb = true,
	sloworb = true,
}

function AbilitySim.playable(id: string): boolean
	return PLAYABLE[id] == true
end

-- Whether an ability is one its key puts in hand, to be thrown or tried
-- from there (Curveball's flare, Hot Hands' fireball, Blaze's flame, the
-- Healing Orb, the Slow Orb): a weapon of its own, outside the ultimate.
local function held(def: AbilityConfig.AbilityDef?): boolean
	return def ~= nil and def.weapon ~= nil and def.kind ~= "ultimate" and PLAYABLE[def.id] == true
end

-- A new kit for `agent` (by default AbilityConfig.DEFAULT_AGENT): the
-- signature's free charges and nothing else.
function AbilitySim.new(agent: string?): State
	local s: State = {
		agent = agent or AbilityConfig.DEFAULT_AGENT,
		charges = { 0, 0, 0, 0 },
		regained = 0,
		kills = 0,
		points = 0,
		need = 0,
		held = 0,
		readyFrom = 0,
		readyUntil = 0,
		liftUntil = 0,
		dashUntil = 0,
		dashX = 0,
		dashZ = 0,
		storm = false,
		holding = 0,
		steering = 0,
		steerUntil = 0,
		backUntil = 0,
		mark = ZERO,
		markYaw = 0,
		markGrounded = false,
		markCrouched = false,
		returnAt = 0,
	}
	AbilitySim.newHalf(s)
	return s
end

function AbilitySim.copy(s: State): State
	local out = table.clone(s)
	out.charges = table.clone(s.charges)
	return out
end

function AbilitySim.def(s: State, slot: number): AbilityConfig.AbilityDef?
	return AbilityConfig.abilityOf(s.agent, slot)
end

-- Whether the kit's agent has `passive` (Jett's "drift").
function AbilitySim.hasPassive(s: State, passive: string): boolean
	local agent = AbilityConfig.Agents[s.agent]
	return agent ~= nil and agent.passive == passive
end

-- The slot the kit holds an ability in, if it holds it.
function AbilitySim.slotOf(s: State, id: string): number?
	for slot = C, X do
		local def = AbilitySim.def(s, slot)
		if def and def.id == id then
			return slot
		end
	end
	return nil
end

-- The most charges a slot holds (0 for X and an empty slot).
function AbilitySim.maxCharges(s: State, slot: number): number
	local def = AbilitySim.def(s, slot)
	return if def and def.charges then def.charges.value else 0
end

-- The points the ultimate needs (0 with none): the mode's, if it has its
-- own, or the ultimate's.
function AbilitySim.pointsNeeded(s: State): number
	local def = AbilitySim.def(s, X)
	if not def or not def.points then
		return 0
	end
	return if s.need > 0 then s.need else def.points.value
end

-- Ends whatever's under way: a readied window, a lift, a dash, the
-- ultimate (Blade Storm, or Run it Back and the return it brings), an
-- ability in hand, a wall being bent. Nothing carries into a new life or a
-- new round.
function AbilitySim.settle(s: State)
	s.readyFrom, s.readyUntil = 0, 0
	s.liftUntil = 0
	s.dashUntil, s.dashX, s.dashZ = 0, 0, 0
	s.storm = false
	s.holding = 0
	s.steering, s.steerUntil = 0, 0
	s.backUntil, s.returnAt = 0, 0
	s.mark, s.markYaw, s.markGrounded, s.markCrouched = ZERO, 0, false, false
end

-- A new match: nothing but the signature's free charges, and no points.
function AbilitySim.reset(s: State)
	s.points = 0
	AbilitySim.newHalf(s)
end

-- No abilities at all: no charges, no points, and nothing under way (gun
-- game, system 23).
function AbilitySim.empty(s: State)
	for slot = C, X do
		s.charges[slot] = 0
	end
	s.regained = 0
	s.kills = 0
	s.points = 0
	AbilitySim.settle(s)
end

-- Each round: charges that came back by recharge go, and the signature has
-- at least its free charges. Unused charges carry over.
function AbilitySim.newRound(s: State)
	local def = AbilitySim.def(s, E)
	local free = if def and def.free then def.free else 0
	s.charges[E] = math.max(s.charges[E] - s.regained, free)
	s.regained = 0
	s.kills = 0
	AbilitySim.settle(s)
end

-- A new half: nothing bought is kept, and the signature has its free
-- charges. The ultimate's points are kept.
function AbilitySim.newHalf(s: State)
	for slot = C, X do
		s.charges[slot] = 0
	end
	s.regained = 0
	AbilitySim.newRound(s)
end

-- Whether the ultimate's points are full, and it can be cast.
function AbilitySim.charged(s: State): boolean
	local needed = AbilitySim.pointsNeeded(s)
	return needed > 0 and s.points >= needed
end

-- Whether the ultimate is one that can be played.
local function ultimatePlayable(s: State): boolean
	local def = AbilitySim.def(s, X)
	return def ~= nil and AbilitySim.playable(def.id)
end

-- Whether the ultimate's under way: Blade Storm's knives carried, or Run
-- it Back running or bringing him back.
function AbilitySim.ultimateOn(s: State): boolean
	return s.storm or s.backUntil > 0 or s.returnAt > 0
end

-- Every charge the kit can hold, for the course and Skirmish, where nothing
-- is bought; with `ultimate`, the ultimate's points too (the course), unless
-- it's under way.
function AbilitySim.fill(s: State, ultimate: boolean?)
	for slot = C, E do
		local def = AbilitySim.def(s, slot)
		s.charges[slot] = if def and AbilitySim.playable(def.id) then AbilitySim.maxCharges(s, slot) else 0
	end
	s.regained = 0
	s.kills = 0
	if ultimate and ultimatePlayable(s) and not AbilitySim.ultimateOn(s) then
		s.points = AbilitySim.pointsNeeded(s)
	end
end

-- Whether the kit is full: every playable charge there, and with
-- `ultimate` the ultimate's points, unless it's under way.
function AbilitySim.full(s: State, ultimate: boolean?): boolean
	for slot = C, E do
		local def = AbilitySim.def(s, slot)
		if def and AbilitySim.playable(def.id) and s.charges[slot] < AbilitySim.maxCharges(s, slot) then
			return false
		end
	end
	return not ultimate or not ultimatePlayable(s) or AbilitySim.ultimateOn(s) or AbilitySim.charged(s)
end

-- Whether anything's under way at `t`: a readied window, a lift or a dash.
function AbilitySim.busy(s: State, t: number): boolean
	return t < s.readyUntil - EPS or t < s.liftUntil - EPS or t < s.dashUntil - EPS
end

-- Ultimate points, up to what the ultimate needs.
function AbilitySim.addPoints(s: State, amount: number)
	s.points = math.clamp(s.points + amount, 0, AbilitySim.pointsNeeded(s))
end

-- A kill: its point, or `points` where the mode has its own, and the
-- signature a step closer to a charge back when it recharges with kills and
-- isn't full.
function AbilitySim.killed(s: State, points: number?)
	AbilitySim.addPoints(s, points or AbilityConfig.Points.kill.value)
	local def = AbilitySim.def(s, E)
	local recharge = if def then def.recharge else nil
	if not recharge or recharge.kind ~= "kills" or s.charges[E] >= AbilitySim.maxCharges(s, E) then
		return
	end
	s.kills += 1
	if s.kills >= recharge.kills.value then
		s.kills = 0
		s.charges[E] += 1
		s.regained += 1
	end
end

-- A death: its point, or `points` where the mode has its own, and whatever
-- was under way ends. Charges are kept.
function AbilitySim.died(s: State, points: number?)
	AbilitySim.addPoints(s, points or AbilityConfig.Points.death.value)
	AbilitySim.settle(s)
end

-- Whether a charge of the ability `id` can be bought into the kit: one it
-- holds, sold by the charge, playable, and short of its most.
function AbilitySim.canBuy(s: State, id: string): boolean
	local slot = AbilitySim.slotOf(s, id)
	local def = if slot then AbilitySim.def(s, slot) else nil
	return slot ~= nil and def ~= nil and def.cost ~= nil and AbilitySim.playable(id) and s.charges[slot] < AbilitySim.maxCharges(s, slot)
end

-- A charge of the ability `id` bought; false if it can't take one.
function AbilitySim.buy(s: State, id: string): boolean
	local slot = AbilitySim.slotOf(s, id)
	if not slot or not AbilitySim.canBuy(s, id) then
		return false
	end
	s.charges[slot] += 1
	return true
end

-- A charge of the ability `id` sold back; false if there's none.
function AbilitySim.sell(s: State, id: string): boolean
	local slot = AbilitySim.slotOf(s, id)
	if not slot or slot == X or s.charges[slot] <= 0 then
		return false
	end
	s.charges[slot] -= 1
	return true
end

-- The kit in a few characters, for the server to tell clients (scripted
-- checks read it): each slot's charges and most, the ultimate's points and
-- what they need, and what's under way at `t`, as "C0/2 Q1/1 E0/1 X3/8
-- ready", or "X0/8 storm" in Blade Storm, "back" while Run it Back runs,
-- "away" while his body's gone and "rise" as he rises at its mark, "equip"
-- with an ability in hand (Curveball's flare, Hot Hands' fireball, Blaze's
-- flame, the Healing Orb), "bend" while a wall is being bent (Blaze), and
-- "glide" while `gliding` (the movement's, for Drift).
function AbilitySim.summary(s: State, t: number, gliding: boolean?): string
	local parts = {}
	for slot = C, E do
		table.insert(parts, string.format("%s%d/%d", AbilityConfig.KEYS[slot], s.charges[slot], AbilitySim.maxCharges(s, slot)))
	end
	table.insert(parts, string.format("X%d/%d", s.points, AbilitySim.pointsNeeded(s)))
	if s.storm then
		table.insert(parts, "storm")
	end
	if s.backUntil > 0 then
		table.insert(parts, "back")
	elseif AbilitySim.away(s, t) then
		table.insert(parts, "away")
	elseif AbilitySim.returning(s, t) then
		table.insert(parts, "rise")
	end
	if s.holding ~= 0 then
		table.insert(parts, "equip")
	end
	if s.steering ~= 0 then
		table.insert(parts, "bend")
	end
	if AbilitySim.dashing(s, t) then
		table.insert(parts, "dash")
	elseif AbilitySim.lifting(s, t) then
		table.insert(parts, "lift")
	end
	if AbilitySim.ready(s, t) then
		table.insert(parts, "ready")
	elseif t < s.readyUntil - EPS then
		table.insert(parts, "windup")
	end
	if gliding then
		table.insert(parts, "glide")
	end
	return table.concat(parts, " ")
end

function AbilitySim.dashing(s: State, t: number): boolean
	return t < s.dashUntil - EPS
end

function AbilitySim.lifting(s: State, t: number): boolean
	return t < s.liftUntil - EPS
end

-- Whether a readied window is open at `t`.
function AbilitySim.ready(s: State, t: number): boolean
	return s.readyUntil > 0 and t >= s.readyFrom - EPS and t < s.readyUntil - EPS
end

-- Whether Run it Back's running (system 33): cast, not run out, and no hit
-- that would have killed him spared yet.
function AbilitySim.runningBack(s: State): boolean
	return s.backUntil > 0
end

-- Whether its activation's under way at `t`: the gun away, and nothing else
-- cast.
function AbilitySim.marking(s: State, t: number): boolean
	return s.backUntil > 0 and t < s.backUntil - RB.duration.value + RB.activation.value - EPS
end

-- Whether his body's gone at `t`, his return under way.
function AbilitySim.away(s: State, t: number): boolean
	return s.returnAt > 0 and t < s.returnAt + RB.away.value - EPS
end

-- When his return ends, risen at the mark (0 with none under way).
function AbilitySim.risen(s: State): number
	return if s.returnAt > 0 then s.returnAt + RB.away.value + RB.rise.value else 0
end

-- Whether his return's under way at `t`: his body gone, or rising at the
-- mark. He's held through all of it.
function AbilitySim.returning(s: State, t: number): boolean
	return s.returnAt > 0 and t < AbilitySim.risen(s) - EPS
end

-- His body gone at `t`, a tick's time (system 33): Run it Back's over and
-- his return starts, as it runs out or as the server spares him a hit that
-- would have killed him. An ability in hand goes, and a wall being bent
-- runs straight on.
function AbilitySim.fizzle(s: State, t: number)
	s.backUntil = 0
	s.returnAt = t
	s.holding = 0
	s.steering, s.steerUntil = 0, 0
end

-- The way someone facing `yaw` looks along the ground.
local function facing(yaw: number): vector
	return vector.create(-math.sin(yaw), 0, -math.cos(yaw))
end

-- Run it Back's tick at `t` (system 33), before anything else in it: as
-- its time runs out his body's gone ("fizzle", from `feet` and `eye`), and
-- once it's been gone its time he's back at the mark ("rise", which
-- PlayerSim puts him at); his return's over once he's risen. Returns
-- whether he's held this tick, his return under way, and what started, if
-- anything.
function AbilitySim.comeBack(s: State, t: number, dt: number, tick: number, feet: vector, eye: vector): (boolean, Cast?)
	local cast: Cast? = nil
	if s.backUntil > 0 and t >= s.backUntil - EPS then
		AbilitySim.fizzle(s, t)
		cast = {
			slot = X,
			ability = "runitback",
			kind = "fizzle",
			tick = tick,
			time = t,
			position = feet,
			origin = eye,
			direction = facing(s.markYaw),
		}
	end
	if s.returnAt == 0 then
		return false, nil
	end
	if t >= AbilitySim.risen(s) - EPS then
		s.returnAt = 0
		s.mark, s.markYaw, s.markGrounded, s.markCrouched = ZERO, 0, false, false
		return false, nil
	end
	local back = s.returnAt + RB.away.value
	if t >= back - EPS and t - dt < back - EPS then
		cast = {
			slot = X,
			ability = "runitback",
			kind = "rise",
			tick = tick,
			time = t,
			position = s.mark,
			origin = s.mark + (eye - feet),
			direction = facing(s.markYaw),
		}
	end
	return true, cast
end

-- The weapon the kit has in WeaponSim's fifth slot now, "" for none:
-- Blade Storm's knives while it lasts, the ability in hand's, or the flame
-- of a wall being bent (Blaze).
function AbilitySim.carried(s: State): string
	local slot = if s.storm then X elseif s.holding ~= 0 then s.holding elseif s.steering ~= 0 then s.steering else 0
	local def = if slot ~= 0 then AbilitySim.def(s, slot) else nil
	return if def and def.weapon then def.weapon else ""
end

-- The ability in hand thrown (WeaponSim fires it as PlayerSim has it): its
-- charge spent, and its cast, from `origin` (the eye) the way `aim` points.
-- `alt` says alt fire threw it: Curveball's flare goes round to the right
-- then, and to the left otherwise, and Hot Hands' fireball is lobbed. The
-- Slow Orb has no alt fire.
-- Blaze's wall is sent out from `feet`, and is bent from then until its
-- run's over, if fire's held that long. The Healing Orb is only tried, on
-- the ally the crosshair's over or with `alt` on herself: it stays in hand
-- with its charge until the server finds the try heals (used). Nil with
-- nothing in hand to throw.
function AbilitySim.thrown(s: State, tick: number, t: number, feet: vector, origin: vector, aim: vector, alt: boolean): Cast?
	local slot = s.holding
	local def = if slot ~= 0 then AbilitySim.def(s, slot) else nil
	if def and def.id == "healingorb" and s.charges[slot] > 0 then
		local try: Cast = {
			slot = slot,
			ability = def.id,
			kind = if alt then "selfheal" else "heal",
			tick = tick,
			time = t,
			position = feet,
			origin = origin,
			direction = aim,
		}
		return try
	end
	s.holding = 0
	if not def or s.charges[slot] <= 0 then
		return nil
	end
	s.charges[slot] -= 1
	local cast: Cast = {
		slot = slot,
		ability = def.id,
		kind = "flare",
		tick = tick,
		time = t,
		position = feet,
		origin = origin,
		direction = aim,
	}
	if def.id == "hothands" then
		cast.kind = "fireball"
		cast.lob = alt
	elseif def.id == "sloworb" then
		cast.kind = "slow"
	elseif def.id == "blaze" then
		cast.kind = "flame"
		s.steering = slot
		s.steerUntil = t + AbilityConfig.Blaze.flight.value
	else
		cast.curve = if alt then 1 else -1
	end
	return cast
end

-- The ability in `slot` used, between ticks, as the server finds a try of
-- it heals (the Healing Orb, system 36): its charge spent and, if it's in
-- hand, out of it. The ack takes it to its owner.
function AbilitySim.used(s: State, slot: number)
	s.charges[slot] = math.max(s.charges[slot] - 1, 0)
	if s.holding == slot then
		s.holding = 0
	end
end

-- The ticks something lasting `duration` from a tick runs for, that tick
-- included.
function AbilitySim.ticks(duration: number, dt: number): number
	return math.max(math.ceil(duration / dt - 1e-6), 1)
end

-- The dash's speed: its distance over the ticks it runs.
function AbilitySim.dashSpeed(dt: number): number
	return J.dashDistance.value / (AbilitySim.ticks(J.dashTime.value, dt) * dt)
end

-- Updraft's lift speed: steady for its ticks, then a fall as from a jump,
-- so the feet top out at its apex. With u the speed, n the ticks and g
-- gravity, the rise is u*n*dt for the lift and u^2/2g less half a tick's
-- for the fall, a tick at a time: u*(n - 1/2)*dt + u^2/2g.
function AbilitySim.liftSpeed(gravity: number, dt: number): number
	local T = (AbilitySim.ticks(J.updraftTime.value, dt) - 0.5) * dt
	local H = J.updraftApex.value
	return gravity * (math.sqrt(T * T + 2 * H / gravity) - T)
end

-- The way a dash goes: the keys' direction, or forward with none.
local function dashDirection(buttons: number, yaw: number): vector
	local dir = MovementSim.wishDirection(buttons, yaw)
	if vector.magnitude(dir) < 1e-6 then
		dir = vector.create(-math.sin(yaw), 0, -math.cos(yaw))
	end
	return vector.normalize(dir)
end

-- One tick at time `t`, before movement: casts what's been pressed, from
-- `feet` and `eye` where the last tick left them. `rooted` says a plant or
-- a defuse holds the player, and nothing casts then; nor does anything
-- during a dash or Run it Back's activation. Returns what this tick does to
-- movement, and the casts that started, if any.
function AbilitySim.step(
	s: State,
	input: any,
	t: number,
	dt: number,
	tick: number,
	feet: vector,
	eye: vector,
	rooted: boolean,
	cfg: any
): (MovementSim.Motion, { Cast }?)
	local buttons: number = input.buttons
	local keys = bit32.band(buttons, ALL)
	local pressed = bit32.band(keys, bit32.bnot(s.held))
	s.held = keys
	if s.readyUntil > 0 and t >= s.readyUntil - EPS then
		s.readyFrom, s.readyUntil = 0, 0
	end
	-- An ability in hand with no charge left to throw goes (one sold back).
	if s.holding ~= 0 and s.charges[s.holding] <= 0 then
		s.holding = 0
	end

	local motion: MovementSim.Motion = {}
	-- A dash that has just ended leaves no more than the run speed.
	if s.dashUntil > 0 and not AbilitySim.dashing(s, t) then
		s.dashUntil, s.dashX, s.dashZ = 0, 0, 0
		motion.cap = J.dashExit.value * cfg.baseRunSpeed
	end

	local casts: { Cast }? = nil
	local function started(cast: Cast)
		local list = casts or {}
		table.insert(list, cast)
		casts = list
	end
	if pressed ~= 0 and not rooted and not AbilitySim.dashing(s, t) and not AbilitySim.marking(s, t) then
		for slot = C, X do
			if bit32.band(pressed, AbilitySim.BUTTONS[slot]) == 0 then
				continue
			end
			local def = AbilitySim.def(s, slot)
			local id = if def then def.id else ""
			if id == "cloudburst" and s.charges[slot] > 0 then
				s.charges[slot] -= 1
				local aim = Accuracy.aim(input.yaw, input.pitch)
				started({
					slot = slot,
					ability = id,
					kind = "throw",
					tick = tick,
					time = t,
					position = feet,
					origin = eye,
					direction = aim,
				})
			elseif id == "updraft" and s.charges[slot] > 0 then
				s.charges[slot] -= 1
				s.liftUntil = t + J.updraftTime.value
				started({ slot = slot, ability = id, kind = "lift", tick = tick, time = t, position = feet, origin = eye, direction = UP })
			elseif id == "tailwind" and AbilitySim.ready(s, t) then
				local dir = dashDirection(buttons, input.yaw)
				local velocity = dir * AbilitySim.dashSpeed(dt)
				s.dashUntil = t + J.dashTime.value
				s.dashX, s.dashZ = velocity.x, velocity.z
				s.readyFrom, s.readyUntil = 0, 0
				s.liftUntil = 0
				started({ slot = slot, ability = id, kind = "dash", tick = tick, time = t, position = feet, origin = eye, direction = dir })
				-- Nothing else casts in the dash.
				break
			elseif id == "tailwind" and s.readyUntil == 0 and s.charges[slot] > 0 then
				s.charges[slot] -= 1
				s.readyFrom = t + J.windup.value
				s.readyUntil = s.readyFrom + J.window.value
				started({
					slot = slot,
					ability = id,
					kind = "ready",
					tick = tick,
					time = t,
					position = feet,
					origin = eye,
					direction = facing(input.yaw),
				})
			elseif id == "bladestorm" and s.storm then
				-- The knives drawn again, if they aren't in hand (PlayerSim).
				local aim = Accuracy.aim(input.yaw, input.pitch)
				started({ slot = slot, ability = id, kind = "draw", tick = tick, time = t, position = feet, origin = eye, direction = aim })
			elseif id == "bladestorm" and AbilitySim.charged(s) then
				s.points = 0
				s.storm = true
				local aim = Accuracy.aim(input.yaw, input.pitch)
				started({
					slot = slot,
					ability = id,
					kind = "storm",
					tick = tick,
					time = t,
					position = feet,
					origin = eye,
					direction = aim,
				})
			elseif id == "runitback" and AbilitySim.charged(s) and not AbilitySim.ultimateOn(s) then
				-- Marked at once, where he stands and the way he faces, in place
				-- of an ability in hand, and of a wall being bent, which runs
				-- straight on. PlayerSim puts the gun away for the activation.
				s.points = 0
				s.backUntil = t + RB.duration.value
				s.mark = feet
				s.markYaw = input.yaw
				s.holding = 0
				s.steering, s.steerUntil = 0, 0
				started({
					slot = slot,
					ability = id,
					kind = "mark",
					tick = tick,
					time = t,
					position = feet,
					origin = eye,
					direction = facing(input.yaw),
				})
			elseif held(def) and s.holding == slot then
				-- Its key again: what's in hand goes away unthrown (PlayerSim).
				s.holding = 0
			elseif held(def) and not s.storm and s.charges[slot] > 0 then
				-- In hand (PlayerSim), in place of any other ability there, and
				-- of a wall being bent, which runs straight on; its charge goes
				-- as it's thrown.
				s.holding = slot
				s.steering, s.steerUntil = 0, 0
				local aim = Accuracy.aim(input.yaw, input.pitch)
				started({
					slot = slot,
					ability = id,
					kind = "equip",
					tick = tick,
					time = t,
					position = feet,
					origin = eye,
					direction = aim,
				})
			end
		end
	end

	if AbilitySim.dashing(s, t) then
		motion.dash = vector.create(s.dashX, 0, s.dashZ)
	elseif AbilitySim.lifting(s, t) then
		motion.lift = AbilitySim.liftSpeed(cfg.gravity, dt)
	elseif MovementSim.has(buttons, B.Jump) and AbilitySim.hasPassive(s, "drift") then
		-- Drift: once she's falling, the fall is held to a glide.
		motion.glide = { speed = AbilityConfig.Drift.fallSpeed.value, brake = AbilityConfig.Drift.brake.value }
	end
	return motion, casts
end

return AbilitySim
