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
-- SlowSim flies it, and its field slows whoever's in it (PlayerSim). Her
-- Barrier Orb (C, system 38) puts its orb in hand the same way, with a
-- targeter where its wall would go (BarrierSim): C again turns the
-- targeter a quarter rather than putting it away, alt fire held keeps it
-- facing the way it did as she turns, and the turn's kept for the next
-- time it's in hand, until a new life or round. Fire raises the wall
-- where the targeter shows it, if it shows it anywhere (PlayerSim). Her
-- Resurrection (X, system 39) puts its orb in hand as the Healing Orb's
-- once the ultimate's points are full, and X again puts it away: fire
-- tries it on the fallen ally whose body is under the crosshair, and it
-- stays in hand until the server finds a try brings someone back
-- (ReviveServer), spends the points and puts it away (used). A life it
-- brings back starts held (revived): rising with the body, out of harm's
-- way, until they burst out, then falling to the floor, until they've
-- control back. Nothing they press does anything meanwhile.
--
-- Omen's Dark Cover (E, system 40) puts its orb in hand the same way, with
-- a mark along the crosshair (SmokeSim) its reach away, which the kit
-- keeps: PlayerSim starts it where the crosshair meets the level as it
-- comes into hand, then held fire sends it further and held alt fire
-- brings it closer (Patch 1.0). Fire throws nothing; E again sends the orb
-- (a "smoke" cast), and PlayerSim spends its charge and puts it away if
-- there's a floor under the mark for its smoke, or leaves it in hand. His
-- Paranoia (Q, system 41) puts its orb in hand as the Slow Orb's: fire
-- sends it (there's no alt fire), and ParanoiaSim flies it. His Shrouded
-- Step (C, system 42) is put in hand the same way, with a mark where it
-- would take him (StepSim), and fire there spends its charge and starts
-- its windup (a "step" cast), with nowhere leaving it in hand. Through the
-- windup he can't move or fire, nor cast anything, though he falls and
-- slides on as he was; as it ends he's gone ("vanish"), held on the floor
-- it marked (PlayerSim), and once he's been gone its time he's there
-- ("arrive"), free from that tick. His From the Shadows (X, system 43) puts
-- its map in hand as the Resurrection's orb is, once the ultimate's points
-- are full, and X again puts it away: fire with its cursor on a place he'd
-- stand (ShadowSim) spends the points and starts its windup (a "shadows"
-- cast), with nowhere leaving it in hand. Through the windup he's held as
-- through Shrouded Step's; as it ends he's a Shade ("shade") on the floor
-- it marked (PlayerSim), held there until its time's up and he's there for
-- good ("form"), free from that tick. X while he's a Shade, or the
-- server's word that an enemy hit it (PlayerSim.home), sends him back
-- where he cast it ("home"), free from then.
--
-- Sova's Recon Bolt (E, system 44) puts his bow in hand the same way, and
-- it fires nothing: once it's ready, fire held draws its bolt, a bar
-- filling each third of a second, alt fire adds a bounce, two at the most
-- and then none again, and fire let go looses it (bow, a "bolt" cast with
-- its bars and bounces), spending its charge and putting it away. E while
-- it's drawn lets the draw go, the bow staying in hand, and nothing's
-- drawn again until fire's let go. BoltSim flies it. His Shock Bolt (Q,
-- system 45) puts the same bow in hand with a shock bolt, drawn, given
-- bounces and loosed the same way (a "bolt" cast too), and it bursts where
-- it lands (ShockSim). His Hunter's Fury (X, system 46) spends the
-- ultimate's points once they're full and puts its bow in hand for its
-- time, from once it's drawn (a "fury" cast, which PlayerSim arms). Fire,
-- once it's drawn, starts a blast's windup (charge, which PlayerSim does),
-- through which he's rooted; as it ends the blast goes from his eye along
-- the crosshair (a "blast" cast, which FurySim judges), and a knockback
-- pushes him level from the way he faces, its speed falling to nothing
-- over its time. It's over (calm) once its time's up, its bow's gone or
-- anything else is drawn, a blast charging with it, and an ability put in
-- hand ends it too. His Owl Drone (C, system 47) is put in hand the same
-- way, and fire, once it's ready, spends its charge and sends the drone
-- out (a "drone" cast, which PlayerSim launches) from his eye. While it
-- flies he's held where he is, nothing pressed moving him, and the input
-- flies the drone (droneThrough, DroneSim), its view the drone's: for its
-- deploy it flies on as it was sent, and then the keys fly it, and fire,
-- no sooner than its dart's cooldown, shoots a dart from it along the
-- crosshair (a "dart" cast, which the server judges). Its flight's over
-- ("land") once its time's up or C's pressed again, or as the server
-- breaks it between ticks (PlayerSim.downed), and the gun's back in hand
-- its unequip after.
--
-- Reyna's Devour (Q, system 73) and Dismiss (E) each take the Soul Orb in
-- her reach (the step's `soul`, SoulSim.pick), with a charge: the charge
-- goes and the orb with it (a "devour" or "dismiss" cast, with the orb's
-- number), one orb a tick. Devour's heal is the server's (SoulServer).
-- Dismiss starts at once, in place of an ability in hand: through its time
-- she can't fire, cast, plant or defuse, and runs faster (PlayerSim), and
-- as it ends ("solid") she keeps no more than the run speed, her gun
-- drawn again.
--
-- The server changes the kit between ticks, as it does a loadout: charges
-- bought and sold, the signature's free charge each round, ultimate points
-- for kills, deaths, plants and defuses, and a signature charge back for
-- kills; and in Team Deathmatch (system 28) charges back over time, and
-- what the ultimate needs. In the spike rounds each round's start sets the
-- points too (system 50, roundPoints): a half's starts them over, an
-- overtime round's a few short of full, and any other's pays the deaths
-- of the last. The ack carries the kit, so the owner's prediction agrees.
--
-- No Roblox APIs here.

local AbilityConfig = require("./AbilityConfig")
local SmokeSim = require("./SmokeSim")
local BarrierSim = require("./BarrierSim")
local DroneSim = require("./DroneSim")
local MovementSim = require("../Movement/MovementSim")
local Accuracy = require("../Weapons/Accuracy")

export type State = {
	agent: string, -- an AbilityConfig.Agents id, or AbilityConfig.NO_AGENT for no abilities
	charges: { number }, -- by slot: C, Q and E (X's is always 0)
	-- By slot, as charges: how many it's had this round, free and bought,
	-- which a cooldown brings spent ones back up to (AbilityServer): not
	-- one that was never bought (Patch 3.0: 'Omen now must buy his second
	-- smoke').
	owned: { number },
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
	-- The Barrier Orb's targeter (system 38): how far it's turned from
	-- across her view (radians); whether alt fire's turning it, and the yaw
	-- it's held facing meanwhile.
	turn: number,
	turning: boolean,
	fixed: number,
	-- A life the Resurrection brought back (system 39): until when it rises
	-- with the body, and until when it's held, 0 for none. The server sets
	-- them as the life starts.
	floatUntil: number,
	heldUntil: number,
	-- Dark Cover's mark (system 40): how far along the crosshair it is
	-- (metres), while its orb's in hand.
	reach: number,
	-- Shrouded Step (system 42): when its windup ends and he's gone, 0 with
	-- none under way, and the floor it takes him to (the feet).
	stepAt: number,
	stepTo: vector,
	-- From the Shadows (system 43): when its windup ends and he's a Shade, 0
	-- with none under way; the floor it takes him to (the feet), and where
	-- he stood as he became a Shade, which he's sent back to.
	shadowAt: number,
	shadowFrom: vector,
	shadowTo: vector,
	-- Sova's bow in hand (the Recon Bolt's, system 44, or the Shock Bolt's,
	-- system 45): when its draw started, 0 with none; whether a draw was
	-- let go with fire still held, so nothing is drawn until it's let go;
	-- whether alt fire was held last tick; and the bounces it adds.
	drawFrom: number,
	letDown: boolean,
	altDown: boolean,
	bounces: number,
	-- Hunter's Fury (system 46): when its time's up, 0 when it isn't under
	-- way; when the blast charging goes, 0 with none charging; and a blast's
	-- knockback: when it started, 0 with none, and the way he faced as the
	-- blast went, which it pushes him back from.
	furyUntil: number,
	chargeAt: number,
	kickFrom: number,
	kickYaw: number,
	-- The Owl Drone (system 47): when it was sent out, 0 when it isn't
	-- flying; when its last flight ended, 0 for none; its middle and how
	-- it's moving (metres, metres a second); when its next dart can go; and
	-- the way he faced and looked as he sent it, which his body keeps
	-- while it flies and he looks again as it ends.
	droneFrom: number,
	landAt: number,
	dronePos: vector,
	droneVel: vector,
	dartAt: number,
	bodyYaw: number,
	bodyPitch: number,
	-- Reyna's Dismiss (system 73): when it ends, 0 when it isn't under way.
	dismissUntil: number,
}

-- A cast, for the server to tell others of (its sound and look): "lift",
-- "ready", "dash", "throw", "storm" (Blade Storm cast), "draw" (its knives
-- drawn again), "equip" (an ability put in hand), "flare" (Curveball's
-- thrown), "fireball" (Hot Hands' thrown), "flame" (Blaze's sent out),
-- "mark" (Run it Back cast), "fizzle" (his body gone as it runs out),
-- "rise" (back at its mark), "heal" (the Healing Orb tried on an ally),
-- "selfheal" (tried on herself), "slow" (the Slow Orb thrown),
-- "barrier" (the Barrier Orb's wall raised), "revive" (the Resurrection
-- tried on a body), "smoke" (Dark Cover's orb sent), "paranoia"
-- (Paranoia's orb sent), "step" (Shrouded Step fired), "vanish" (gone as
-- its windup ends), "arrive" (there), "shadows" (From the Shadows fired),
-- "shade" (a Shade as its windup ends), "form" (there for good), "home"
-- (sent back), "bolt" (a bolt of Sova's loosed), "fury" (Hunter's Fury
-- cast), "charge" (a blast's windup started), "blast" (a blast gone as
-- its windup ends), "drone" (the Owl Drone sent out), "dart" (a dart shot
-- from it), "land" (its flight over), "devour" or "dismiss" (a Soul Orb
-- taken by Reyna's Devour or Dismiss) or "solid" (Dismiss over), where the player's feet and eye
-- were (for "home", where they are back, and for a dart and a landing,
-- the drone's middle in place of the eye), and the way it goes (the
-- dash's way, up for a lift, the way they faced for a readied gust, for
-- Run it Back's and for a landing, the way they looked for the rest). A
-- flare's says which
-- way round it curves, a fireball's whether it was lobbed, a wall's where
-- it goes, a smoke's how far its mark was and where it goes, a step's, his
-- going's, a teleport's and a Shade's, where it takes him (a "home", where
-- the Shade was), and a bolt's the bars its draw filled and the bounces it
-- was given, and a Soul Orb's taking which orb it took.
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
	wall: BarrierSim.Placement?, -- a wall's: where it goes
	reach: number?, -- a smoke's: how far along the crosshair its mark was
	smoke: vector?, -- and the middle of the floor it goes on (PlayerSim)
	step: vector?, -- a step's, his going's, a teleport's and a Shade's: the floor it takes him to
	bars: number?, -- a bolt's: the bars its draw filled, 0 to 3
	bounces: number?, -- and the bounces it was given, 0 to 2
	soul: number?, -- a Soul Orb's taking: the orb it took, by its number
}

local AbilitySim = {}

local C, E, X = AbilityConfig.C, AbilityConfig.E, AbilityConfig.X
local J = AbilityConfig.Jett
local RB = AbilityConfig.RunItBack
local SS = AbilityConfig.ShroudedStep
local FS = AbilityConfig.FromTheShadows
local RC = AbilityConfig.ReconBolt
local HF = AbilityConfig.HuntersFury
local DR = AbilityConfig.OwlDrone
local RY = AbilityConfig.Reyna
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
	barrierorb = true,
	resurrection = true,
	darkcover = true,
	paranoia = true,
	shroudedstep = true,
	fromtheshadows = true,
	reconbolt = true,
	shockbolt = true,
	huntersfury = true,
	owldrone = true,
	devour = true,
	dismiss = true,
}

function AbilitySim.playable(id: string): boolean
	return PLAYABLE[id] == true
end

-- Whether an ability is a bolt loosed from Sova's bow: the Recon Bolt
-- (system 44) or the Shock Bolt (system 45).
function AbilitySim.bowed(id: string): boolean
	return id == "reconbolt" or id == "shockbolt"
end

-- Whether an ability is one its key puts in hand, to be thrown or tried
-- from there (Curveball's flare, Hot Hands' fireball, Blaze's flame, the
-- Healing Orb, the Slow Orb, the Barrier Orb, Sova's bow): a
-- weapon of its own, outside the ultimate, but for the Resurrection's orb
-- (system 39) and From the Shadows' map (system 43).
local function held(def: AbilityConfig.AbilityDef?): boolean
	return def ~= nil
		and def.weapon ~= nil
		and (def.kind ~= "ultimate" or def.id == "resurrection" or def.id == "fromtheshadows")
		and PLAYABLE[def.id] == true
end

-- A new kit for `agent` (by default AbilityConfig.DEFAULT_AGENT): the
-- signature's free charges and nothing else.
function AbilitySim.new(agent: string?): State
	local s: State = {
		agent = agent or AbilityConfig.DEFAULT_AGENT,
		charges = { 0, 0, 0, 0 },
		owned = { 0, 0, 0, 0 },
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
		turn = 0,
		turning = false,
		fixed = 0,
		floatUntil = 0,
		heldUntil = 0,
		reach = 0,
		stepAt = 0,
		stepTo = ZERO,
		shadowAt = 0,
		shadowFrom = ZERO,
		shadowTo = ZERO,
		drawFrom = 0,
		letDown = false,
		altDown = false,
		bounces = 0,
		furyUntil = 0,
		chargeAt = 0,
		kickFrom = 0,
		kickYaw = 0,
		droneFrom = 0,
		landAt = 0,
		dronePos = ZERO,
		droneVel = ZERO,
		dartAt = 0,
		bodyYaw = 0,
		bodyPitch = 0,
		dismissUntil = 0,
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

-- How many charges a cooldown brings `slot` back up to: as many as the kit's
-- had this round, never more than its most, so never one that wasn't
-- bought (Patch 3.0: 'Omen now must buy his second smoke').
function AbilitySim.rechargeTo(s: State, slot: number): number
	return math.min(AbilitySim.maxCharges(s, slot), s.owned[slot])
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
-- ultimate (Blade Storm, Run it Back and the return it brings, From the
-- Shadows, or Hunter's Fury and a blast's knockback), an ability in hand,
-- a wall being bent, a return from the Resurrection, a step (Shrouded
-- Step), a bolt drawn and its bounces (the Recon Bolt), the Owl Drone's
-- flight and what's left of it, Reyna's Dismiss; and the Barrier
-- Orb's targeter is across the view again
-- (the VALORANT Wiki has it across the view when it's first equipped in a
-- round). Nothing carries into a new life or a new round.
function AbilitySim.settle(s: State)
	s.readyFrom, s.readyUntil = 0, 0
	s.liftUntil = 0
	s.dashUntil, s.dashX, s.dashZ = 0, 0, 0
	s.storm = false
	s.holding = 0
	s.steering, s.steerUntil = 0, 0
	s.backUntil, s.returnAt = 0, 0
	s.mark, s.markYaw, s.markGrounded, s.markCrouched = ZERO, 0, false, false
	s.turn, s.turning, s.fixed = 0, false, 0
	s.floatUntil, s.heldUntil = 0, 0
	s.reach = 0
	s.stepAt, s.stepTo = 0, ZERO
	s.shadowAt, s.shadowFrom, s.shadowTo = 0, ZERO, ZERO
	s.drawFrom, s.letDown, s.bounces = 0, false, 0
	s.furyUntil, s.chargeAt = 0, 0
	s.kickFrom, s.kickYaw = 0, 0
	s.droneFrom, s.landAt, s.dartAt = 0, 0, 0
	s.dronePos, s.droneVel = ZERO, ZERO
	s.bodyYaw, s.bodyPitch = 0, 0
	s.dismissUntil = 0
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
		s.owned[slot] = 0
	end
	s.regained = 0
	s.kills = 0
	s.points = 0
	AbilitySim.settle(s)
end

-- Each round: charges that came back by recharge go, and the signature has
-- at least its free charges. Unused charges carry over, and they're what
-- the kit has had this round.
function AbilitySim.newRound(s: State)
	local def = AbilitySim.def(s, E)
	local free = if def and def.free then def.free else 0
	s.charges[E] = math.max(s.charges[E] - s.regained, free)
	for slot = C, E do
		s.owned[slot] = s.charges[slot]
	end
	s.regained = 0
	s.kills = 0
	AbilitySim.settle(s)
end

-- A new half: nothing bought is kept, and the signature has its free
-- charges. The ultimate's points are roundPoints' (system 50).
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

-- Whether the ability in `slot` has what it takes to be in hand: a charge,
-- or for the ultimate (the Resurrection's orb, system 39) its points full.
local function stocked(s: State, slot: number): boolean
	return if slot == X then AbilitySim.charged(s) else s.charges[slot] > 0
end

-- Whether the ultimate is one that can be played.
local function ultimatePlayable(s: State): boolean
	local def = AbilitySim.def(s, X)
	return def ~= nil and AbilitySim.playable(def.id)
end

-- Whether the ultimate's under way: Blade Storm's knives carried, Run it
-- Back running or bringing him back, From the Shadows taking him, or
-- Hunter's Fury's bow in hand.
function AbilitySim.ultimateOn(s: State): boolean
	return s.storm or s.backUntil > 0 or s.returnAt > 0 or s.shadowAt > 0 or s.furyUntil > 0
end

-- Every charge the kit can hold, for the course and Skirmish, where nothing
-- is bought; with `ultimate`, the ultimate's points too (the course), unless
-- it's under way.
function AbilitySim.fill(s: State, ultimate: boolean?)
	for slot = C, E do
		local def = AbilitySim.def(s, slot)
		s.charges[slot] = if def and AbilitySim.playable(def.id) then AbilitySim.maxCharges(s, slot) else 0
		s.owned[slot] = s.charges[slot]
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

-- Whether anything's under way at `t`: a readied window, a lift, a dash, a
-- step, a teleport, a drone's flight or Reyna's Dismiss.
function AbilitySim.busy(s: State, t: number): boolean
	return t < s.readyUntil - EPS
		or t < s.liftUntil - EPS
		or t < s.dashUntil - EPS
		or AbilitySim.stepping(s, t)
		or AbilitySim.shadowing(s, t)
		or AbilitySim.droning(s)
		or AbilitySim.dismissing(s, t)
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

-- A death: its point, or `points` where the mode has its own (none in the
-- spike rounds, where roundPoints pays it, nor for a death no enemy caused,
-- system 50), and whatever was under way ends. Charges are kept.
function AbilitySim.died(s: State, points: number?)
	AbilitySim.addPoints(s, points or AbilityConfig.Points.death.value)
	AbilitySim.settle(s)
end

-- How a round of the spike rounds starts (system 50): "match" for a match's
-- first, "half" for the second half's first, "overtime" for one past
-- regulation and "round" for any other.
export type RoundKind = "match" | "half" | "overtime" | "round"

-- The ultimate's points as a round of the spike rounds starts, after the
-- kit's own start (reset, newHalf or newRound). A match's or a half's first
-- starts them over: at none, or in Swiftplay at Points.swiftplay, or
-- Points.swiftplayNine for an ultimate of 9 points. An overtime round puts
-- everyone Points.overtimeShort short of what the ultimate needs, whatever
-- they had. Any other pays `owed`, the points for deaths in the last round.
function AbilitySim.roundPoints(s: State, kind: RoundKind, owed: number, swiftplay: boolean)
	local P = AbilityConfig.Points
	local needed = AbilitySim.pointsNeeded(s)
	if kind == "match" or kind == "half" then
		local start = if not swiftplay then 0 elseif needed >= 9 then P.swiftplayNine.value else P.swiftplay.value
		s.points = math.min(start, needed)
	elseif kind == "overtime" then
		s.points = math.max(needed - P.overtimeShort.value, 0)
	else
		AbilitySim.addPoints(s, owed)
	end
end

-- Whether a charge of the ability `id` can be bought into the kit: one it
-- holds, sold by the charge, playable, and short of its most.
function AbilitySim.canBuy(s: State, id: string): boolean
	local slot = AbilitySim.slotOf(s, id)
	local def = if slot then AbilitySim.def(s, slot) else nil
	return slot ~= nil and def ~= nil and def.cost ~= nil and AbilitySim.playable(id) and s.charges[slot] < AbilitySim.maxCharges(s, slot)
end

-- A charge of the ability `id` bought; false if it can't take one. One
-- bought in place of one spent and coming back is the same charge.
function AbilitySim.buy(s: State, id: string): boolean
	local slot = AbilitySim.slotOf(s, id)
	if not slot or not AbilitySim.canBuy(s, id) then
		return false
	end
	s.charges[slot] += 1
	s.owned[slot] = math.max(s.owned[slot], s.charges[slot])
	return true
end

-- A charge of the ability `id` sold back; false if there's none.
function AbilitySim.sell(s: State, id: string): boolean
	local slot = AbilitySim.slotOf(s, id)
	if not slot or slot == X or s.charges[slot] <= 0 then
		return false
	end
	s.charges[slot] -= 1
	s.owned[slot] = math.max(s.owned[slot] - 1, s.charges[slot])
	return true
end

-- The kit in a few characters, for the server to tell clients (scripted
-- checks read it): each slot's charges and most, the ultimate's points and
-- what they need, and what's under way at `t`, as "C0/2 Q1/1 E0/1 X3/8
-- ready", or "X0/8 storm" in Blade Storm, "back" while Run it Back runs,
-- "away" while his body's gone and "rise" as he rises at its mark, "step"
-- through Shrouded Step's windup and "shroud" while he's gone, "shadows"
-- through From the Shadows' windup and "shade" while he's a Shade, "fury"
-- while Hunter's Fury's bow is in hand and "charge" while a blast charges,
-- "drone 6.2" while the Owl Drone flies, the seconds it has left, "equip"
-- with an ability in hand (Curveball's flare, Hot Hands' fireball, Blaze's
-- flame, the Healing Orb, the Slow Orb, the Barrier Orb, the Resurrection's
-- orb, Dark Cover's orb, Paranoia's orb, Shrouded Step's mark, From the
-- Shadows' map, Sova's bow, his Owl Drone), "mark 15.0" with Dark Cover's
-- orb in hand, how far its mark is (metres), "draw 2" while a bolt of
-- Sova's is drawn, the bars it's filled, and "bounce 1" with bounces added
-- to it, "bend" while a wall is being bent (Blaze), "turn" while the
-- Barrier Orb's targeter is turned from across the view, "revived" while a
-- life the Resurrection brought back is held, "dismiss 1.2" while Reyna's
-- Dismiss runs, the seconds it has left, and "glide" while `gliding` (the
-- movement's, for Drift).
function AbilitySim.summary(s: State, t: number, gliding: boolean?): string
	local parts = {}
	for slot = C, E do
		table.insert(parts, string.format("%s%d/%d", AbilityConfig.KEYS[slot], s.charges[slot], AbilitySim.maxCharges(s, slot)))
	end
	table.insert(parts, string.format("X%d/%d", s.points, AbilitySim.pointsNeeded(s)))
	if s.storm then
		table.insert(parts, "storm")
	end
	if s.furyUntil > 0 then
		table.insert(parts, "fury")
	end
	if AbilitySim.charging(s, t) then
		table.insert(parts, "charge")
	end
	if AbilitySim.droning(s) then
		table.insert(parts, string.format("drone %.1f", math.max(AbilitySim.droneEnds(s) - t, 0)))
	end
	if s.backUntil > 0 then
		table.insert(parts, "back")
	elseif AbilitySim.away(s, t) then
		table.insert(parts, "away")
	elseif AbilitySim.returning(s, t) then
		table.insert(parts, "rise")
	end
	if AbilitySim.shrouding(s, t) then
		table.insert(parts, "step")
	elseif AbilitySim.shrouded(s, t) then
		table.insert(parts, "shroud")
	end
	if AbilitySim.gathering(s, t) then
		table.insert(parts, "shadows")
	elseif AbilitySim.shaded(s, t) then
		table.insert(parts, "shade")
	end
	if s.holding ~= 0 then
		table.insert(parts, "equip")
		local def = AbilitySim.def(s, s.holding)
		if def and def.id == "darkcover" then
			table.insert(parts, string.format("mark %.1f", s.reach))
		end
		if def and AbilitySim.bowed(def.id) then
			if s.drawFrom > 0 then
				table.insert(parts, string.format("draw %d", AbilitySim.bars(s, t)))
			end
			if s.bounces > 0 then
				table.insert(parts, string.format("bounce %d", s.bounces))
			end
		end
	end
	if s.steering ~= 0 then
		table.insert(parts, "bend")
	end
	if math.abs(s.turn) > 1e-6 then
		table.insert(parts, "turn")
	end
	if AbilitySim.reviving(s, t) then
		table.insert(parts, "revived")
	end
	if AbilitySim.dashing(s, t) then
		table.insert(parts, "dash")
	elseif AbilitySim.lifting(s, t) then
		table.insert(parts, "lift")
	end
	if AbilitySim.dismissing(s, t) then
		table.insert(parts, string.format("dismiss %.1f", math.max(s.dismissUntil - t, 0)))
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

-- Whether Reyna's Dismiss is under way at `t` (system 73).
function AbilitySim.dismissing(s: State, t: number): boolean
	return t < s.dismissUntil - EPS
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

-- Whether a life the Resurrection brought back is held at `t` (system 39):
-- rising with the body, or falling once they've burst out.
function AbilitySim.reviving(s: State, t: number): boolean
	return t < s.heldUntil - EPS
end

-- Whether it's still rising with the body at `t`, out of harm's way.
function AbilitySim.floating(s: State, t: number): boolean
	return t < s.floatUntil - EPS
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

-- Whether Shrouded Step's under way at `t` (system 42): its windup, or his
-- time gone.
function AbilitySim.stepping(s: State, t: number): boolean
	return s.stepAt > 0 and t < s.stepAt + SS.away.value - EPS
end

-- Whether its windup's under way at `t`: he can't move or fire.
function AbilitySim.shrouding(s: State, t: number): boolean
	return s.stepAt > 0 and t < s.stepAt - EPS
end

-- Whether he's gone at `t`, out of play until he's there.
function AbilitySim.shrouded(s: State, t: number): boolean
	return AbilitySim.stepping(s, t) and not AbilitySim.shrouding(s, t)
end

-- When he's there (0 with no step under way).
function AbilitySim.arrives(s: State): number
	return if s.stepAt > 0 then s.stepAt + SS.away.value else 0
end

-- Shrouded Step fired at `t` (system 42): its windup starts, and it takes
-- him to `to` (the floor, metres).
function AbilitySim.shroud(s: State, t: number, to: vector)
	s.stepAt = t + SS.windup.value
	s.stepTo = to
end

-- Shrouded Step's tick at `t` (system 42), before anything else in it but
-- a return: as its windup ends he's gone from `feet` and `eye` ("vanish"),
-- to the floor it marked, which PlayerSim puts him on; and once he's been
-- gone its time he's there ("arrive"), the step over and him free from
-- that tick. `look` is the way he looks. Returns whether he's held this
-- tick, and what started, if anything.
function AbilitySim.stepThrough(s: State, t: number, dt: number, tick: number, feet: vector, eye: vector, look: vector): (boolean, Cast?)
	if s.stepAt == 0 then
		return false, nil
	end
	local slot = AbilitySim.slotOf(s, "shroudedstep") or C
	if t >= AbilitySim.arrives(s) - EPS then
		s.stepAt, s.stepTo = 0, ZERO
		return false,
			{
				slot = slot,
				ability = "shroudedstep",
				kind = "arrive",
				tick = tick,
				time = t,
				position = feet,
				origin = eye,
				direction = look,
			}
	end
	local cast: Cast? = nil
	if t >= s.stepAt - EPS and t - dt < s.stepAt - EPS then
		cast = {
			slot = slot,
			ability = "shroudedstep",
			kind = "vanish",
			tick = tick,
			time = t,
			position = feet,
			origin = eye,
			direction = look,
			step = s.stepTo,
		}
	end
	return true, cast
end

-- Whether From the Shadows is under way at `t` (system 43): its windup, or
-- his time as a Shade.
function AbilitySim.shadowing(s: State, t: number): boolean
	return s.shadowAt > 0 and t < s.shadowAt + FS.shade.value - EPS
end

-- Whether its windup's under way at `t`: he's rooted where he cast it.
function AbilitySim.gathering(s: State, t: number): boolean
	return s.shadowAt > 0 and t < s.shadowAt - EPS
end

-- Whether he's a Shade at `t`: rooted where it takes him, and sent back by
-- X or an enemy's hit.
function AbilitySim.shaded(s: State, t: number): boolean
	return AbilitySim.shadowing(s, t) and not AbilitySim.gathering(s, t)
end

-- When he's there for good (0 with none under way).
function AbilitySim.formsAt(s: State): number
	return if s.shadowAt > 0 then s.shadowAt + FS.shade.value else 0
end

-- From the Shadows fired at `t` (system 43): its windup starts, and it
-- takes him to `to` (the floor, metres).
function AbilitySim.shadow(s: State, t: number, to: vector)
	s.shadowAt = t + FS.windup.value
	s.shadowFrom = ZERO
	s.shadowTo = to
end

-- A Shade at `t` sent back where he cast it, from `feet` and `eye` (the
-- Shade's) as he looks along `look`: From the Shadows over, its points
-- spent all the same (Patch 1.0), and its "home" cast, which PlayerSim
-- puts him back with. Nil unless he's a Shade.
function AbilitySim.home(s: State, t: number, tick: number, feet: vector, eye: vector, look: vector): Cast?
	if not AbilitySim.shaded(s, t) then
		return nil
	end
	local home = s.shadowFrom
	s.shadowAt, s.shadowFrom, s.shadowTo = 0, ZERO, ZERO
	return {
		slot = AbilitySim.slotOf(s, "fromtheshadows") or X,
		ability = "fromtheshadows",
		kind = "home",
		tick = tick,
		time = t,
		position = home,
		origin = home + (eye - feet),
		direction = look,
		step = feet,
	}
end

-- From the Shadows' tick at `t` (system 43), before anything else in it but
-- a return: as its windup ends he's a Shade ("shade", from `feet` and
-- `eye`, where he's sent back to) on the floor it marked, which PlayerSim
-- puts him on; X pressed (in `buttons`) while he's a Shade sends him back
-- (home); and once he's been a Shade its time he's there for good
-- ("form"), the teleport over and him free from that tick. `look` is the
-- way he looks. Returns whether he's held this tick, and what started, if
-- anything.
function AbilitySim.shadowThrough(
	s: State,
	t: number,
	dt: number,
	tick: number,
	feet: vector,
	eye: vector,
	look: vector,
	buttons: number
): (boolean, Cast?)
	if s.shadowAt == 0 then
		return false, nil
	end
	-- The kit's keys are watched through it, so X pressed counts, and a key
	-- held as it ends doesn't cast.
	local keys = bit32.band(buttons, ALL)
	local pressed = bit32.band(keys, bit32.bnot(s.held))
	s.held = keys
	local slot = AbilitySim.slotOf(s, "fromtheshadows") or X
	if t >= AbilitySim.formsAt(s) - EPS then
		s.shadowAt, s.shadowFrom, s.shadowTo = 0, ZERO, ZERO
		return false,
			{
				slot = slot,
				ability = "fromtheshadows",
				kind = "form",
				tick = tick,
				time = t,
				position = feet,
				origin = eye,
				direction = look,
			}
	end
	if t >= s.shadowAt - EPS and t - dt < s.shadowAt - EPS then
		s.shadowFrom = feet
		return true,
			{
				slot = slot,
				ability = "fromtheshadows",
				kind = "shade",
				tick = tick,
				time = t,
				position = feet,
				origin = eye,
				direction = look,
				step = s.shadowTo,
			}
	end
	if bit32.band(pressed, AbilitySim.BUTTONS[slot]) ~= 0 then
		local back = AbilitySim.home(s, t, tick, feet, eye, look)
		if back then
			return true, back
		end
	end
	return true, nil
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
-- Blade Storm's knives or Hunter's Fury's bow while it lasts, the ability
-- in hand's, or the flame of a wall being bent (Blaze).
function AbilitySim.carried(s: State): string
	local slot = if s.storm or s.furyUntil > 0 then X elseif s.holding ~= 0 then s.holding elseif s.steering ~= 0 then s.steering else 0
	local def = if slot ~= 0 then AbilitySim.def(s, slot) else nil
	return if def and def.weapon then def.weapon else ""
end

-- The ability in hand thrown (WeaponSim fires it as PlayerSim has it): its
-- charge spent, and its cast, from `origin` (the eye) the way `aim` points.
-- `alt` says alt fire threw it: Curveball's flare goes round to the right
-- then, and to the left otherwise, and Hot Hands' fireball is lobbed. The
-- Slow Orb has no alt fire, nor has Paranoia's orb (system 41), nor the
-- Barrier Orb, whose wall goes where PlayerSim has placed it, nor Shrouded
-- Step (system 42), whose step PlayerSim starts where it's found, nor From
-- the Shadows (system 43), whose teleport spends the ultimate's points and
-- PlayerSim starts where the map's place takes him.
-- Blaze's wall is sent out from `feet`, and is bent from then until its
-- run's over, if fire's held that long. The Healing Orb is only tried, on
-- the ally the crosshair's over or with `alt` on herself: it stays in hand
-- with its charge until the server finds the try heals (used). So is the
-- Resurrection's orb, on the body the crosshair's over, with its points
-- (system 39). Nil with nothing in hand to throw.
function AbilitySim.thrown(s: State, tick: number, t: number, feet: vector, origin: vector, aim: vector, alt: boolean): Cast?
	local slot = s.holding
	local def = if slot ~= 0 then AbilitySim.def(s, slot) else nil
	local tried = def ~= nil and (def.id == "healingorb" or def.id == "resurrection")
	if def and tried and stocked(s, slot) then
		local try: Cast = {
			slot = slot,
			ability = def.id,
			kind = if def.id == "resurrection" then "revive" elseif alt then "selfheal" else "heal",
			tick = tick,
			time = t,
			position = feet,
			origin = origin,
			direction = aim,
		}
		return try
	end
	s.holding = 0
	if def and def.id == "fromtheshadows" then
		if not AbilitySim.charged(s) then
			return nil
		end
		s.points = 0
		local teleport: Cast = {
			slot = slot,
			ability = def.id,
			kind = "shadows",
			tick = tick,
			time = t,
			position = feet,
			origin = origin,
			direction = aim,
		}
		return teleport
	end
	if not def or tried or s.charges[slot] <= 0 then
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
	elseif def.id == "paranoia" then
		cast.kind = "paranoia"
	elseif def.id == "barrierorb" then
		cast.kind = "barrier"
	elseif def.id == "shroudedstep" then
		cast.kind = "step"
	elseif def.id == "owldrone" then
		cast.kind = "drone"
	elseif def.id == "blaze" then
		cast.kind = "flame"
		s.steering = slot
		s.steerUntil = t + AbilityConfig.Blaze.flight.value
	else
		cast.curve = if alt then 1 else -1
	end
	return cast
end

-- Sova's bow in hand (systems 44 and 45), a tick: `ready` once it's drawn,
-- after the weapons' step. Alt fire pressed adds a bounce, and past the most
-- takes them all off again. Fire held, once the bow's ready, draws the
-- bolt from this tick, unless a draw was let go with it held (step), and
-- then nothing's drawn until it's let go. Fire let go with the bolt drawn
-- looses it: its charge spent, out of hand, and its cast, from `eye` the
-- way `aim` points, with the bars its draw filled and the bounces added.
-- Nil otherwise.
function AbilitySim.bow(s: State, t: number, buttons: number, ready: boolean, tick: number, feet: vector, eye: vector, aim: vector): Cast?
	local alt = MovementSim.has(buttons, B.AltFire)
	if alt and not s.altDown then
		s.bounces = (s.bounces + 1) % (RC.bounces.value + 1)
	end
	s.altDown = alt
	if MovementSim.has(buttons, B.Fire) then
		if s.drawFrom == 0 and ready and not s.letDown then
			s.drawFrom = t
		end
		return nil
	end
	s.letDown = false
	local slot = s.holding
	if s.drawFrom == 0 or slot == 0 or not stocked(s, slot) then
		s.drawFrom = 0
		return nil
	end
	local bars = AbilitySim.bars(s, t)
	local def = AbilitySim.def(s, slot)
	s.drawFrom = 0
	s.charges[slot] -= 1
	s.holding = 0
	local cast: Cast = {
		slot = slot,
		ability = if def then def.id else "reconbolt",
		kind = "bolt",
		tick = tick,
		time = t,
		position = feet,
		origin = eye,
		direction = aim,
		bars = bars,
		bounces = s.bounces,
	}
	s.bounces = 0
	return cast
end

-- The bars a bolt's draw has filled at `t`: one each third of a second,
-- three at the most, and none with nothing drawn.
function AbilitySim.bars(s: State, t: number): number
	if s.drawFrom == 0 then
		return 0
	end
	return math.clamp(math.floor((t - s.drawFrom) / RC.bar.value + 1e-6), 0, RC.bars.value)
end

-- Whether a blast of Hunter's Fury's is charging at `t` (system 46): he's
-- rooted where he is until it goes.
function AbilitySim.charging(s: State, t: number): boolean
	return s.chargeAt > 0 and t < s.chargeAt - EPS
end

-- A blast's windup started at `t` (system 46), as fire with its bow ready
-- starts one (PlayerSim): it goes its windup on. Returns its "charge"
-- cast, from his feet and eye, along `aim`.
function AbilitySim.charge(s: State, t: number, tick: number, feet: vector, eye: vector, aim: vector): Cast
	s.chargeAt = t + HF.windup.value
	return {
		slot = AbilitySim.slotOf(s, "huntersfury") or X,
		ability = "huntersfury",
		kind = "charge",
		tick = tick,
		time = t,
		position = feet,
		origin = eye,
		direction = aim,
	}
end

-- Hunter's Fury over (system 46): its time up, its bow gone, or anything
-- else drawn. A blast charging goes with it; a knockback under way runs on.
function AbilitySim.calm(s: State)
	s.furyUntil, s.chargeAt = 0, 0
end

-- Whether a blast's knockback is pushing him at `t` (system 46).
function AbilitySim.kicked(s: State, t: number): boolean
	return s.kickFrom > 0 and t < s.kickFrom + HF.kickTime.value - EPS
end

-- A blast's knockback, its velocity for the tick at `t` (system 46):
-- level, back from the way he faced as the blast went, its speed falling
-- in a straight line to nothing over its ticks, so that it covers its
-- distance over them.
function AbilitySim.kickVelocity(s: State, t: number, dt: number): vector
	local n = AbilitySim.ticks(HF.kickTime.value, dt)
	local k = math.floor((t - s.kickFrom) / dt + 0.5)
	local top = 2 * HF.kick.value / (n * dt)
	local speed = math.max(top * (1 - (k + 0.5) / n), 0)
	return facing(s.kickYaw) * -speed
end

-- Whether the Owl Drone flies (system 47): sent out, its flight not over.
function AbilitySim.droning(s: State): boolean
	return s.droneFrom > 0
end

-- Whether the keys fly it at `t`: its deploy's over.
function AbilitySim.piloting(s: State, t: number): boolean
	return s.droneFrom > 0 and t >= s.droneFrom + DR.deploy.value - EPS
end

-- When its time's up (0 when it isn't flying).
function AbilitySim.droneEnds(s: State): number
	return if s.droneFrom > 0 then s.droneFrom + DR.duration.value else 0
end

-- Whether its flight's just over at `t`, the gun on its way back.
function AbilitySim.landing(s: State, t: number): boolean
	return s.landAt > 0 and t < s.landAt + DR.unequip.value - EPS
end

-- The Owl Drone sent out at `t` (system 47), its middle at `eye`, flying
-- the way `yaw` faces at its speed, level; his body keeps facing along
-- `yaw` and looking along `pitch` while it flies. Its first dart can go
-- once its deploy's over.
function AbilitySim.launch(s: State, t: number, eye: vector, yaw: number, pitch: number)
	s.droneFrom = t
	s.landAt = 0
	s.dronePos = eye
	s.droneVel = facing(yaw) * DR.speed.value
	s.dartAt = t + DR.deploy.value
	s.bodyYaw, s.bodyPitch = yaw, pitch
end

-- Its flight over at `t`, from `feet` (his): its time up, C pressed again,
-- or, between ticks, broken (PlayerSim.downed). Returns its "land" cast,
-- from where the drone was, the way he faces; nil if it isn't flying.
function AbilitySim.land(s: State, t: number, tick: number, feet: vector): Cast?
	if s.droneFrom == 0 then
		return nil
	end
	local from = s.dronePos
	s.droneFrom = 0
	s.landAt = t
	s.droneVel = ZERO
	s.dartAt = 0
	return {
		slot = AbilitySim.slotOf(s, "owldrone") or C,
		ability = "owldrone",
		kind = "land",
		tick = tick,
		time = t,
		position = feet,
		origin = from,
		direction = facing(s.bodyYaw),
	}
end

-- The Owl Drone's tick at `t` (system 47), before anything else in it but
-- a return, Shrouded Step and From the Shadows: while it flies the kit's
-- keys are watched, so C pressed counts and a key held as it ends doesn't
-- cast, and C pressed again, or its time up, ends its flight (land, from
-- `feet`). Otherwise the input flies it (DroneSim, through `world`), and
-- `fired` (fire pressed this tick), once the keys fly it and its cooldown's
-- over, shoots a dart from its middle along the crosshair ("dart"). Returns
-- whether he's held this tick, and what started, if anything.
function AbilitySim.droneThrough(
	s: State,
	input: any,
	t: number,
	dt: number,
	tick: number,
	feet: vector,
	world: MovementSim.World,
	cfg: any,
	fired: boolean
): (boolean, Cast?)
	if s.droneFrom == 0 then
		return false, nil
	end
	local keys = bit32.band(input.buttons, ALL)
	local pressed = bit32.band(keys, bit32.bnot(s.held))
	s.held = keys
	local slot = AbilitySim.slotOf(s, "owldrone") or C
	if t >= AbilitySim.droneEnds(s) - EPS or bit32.band(pressed, AbilitySim.BUTTONS[slot]) ~= 0 then
		return false, AbilitySim.land(s, t, tick, feet)
	end
	s.dronePos, s.droneVel = DroneSim.step(s.dronePos, s.droneVel, input.buttons, input.yaw, AbilitySim.piloting(s, t), dt, world, cfg)
	if fired and AbilitySim.piloting(s, t) and t >= s.dartAt - EPS then
		s.dartAt = t + DR.dartCooldown.value
		return true,
			{
				slot = slot,
				ability = "owldrone",
				kind = "dart",
				tick = tick,
				time = t,
				position = feet,
				origin = s.dronePos,
				direction = Accuracy.aim(input.yaw, input.pitch),
			}
	end
	return true, nil
end

-- The ability in `slot` used, between ticks, as the server finds a try of
-- it heals (the Healing Orb, system 36) or brings someone back (the
-- Resurrection, system 39): its charge spent, or the ultimate's points,
-- and, if it's in hand, out of it. The ack takes it to its owner.
function AbilitySim.used(s: State, slot: number)
	if slot == X then
		s.points = 0
	else
		s.charges[slot] = math.max(s.charges[slot] - 1, 0)
	end
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
-- during a dash, Run it Back's activation or Dismiss. `soul` is the Soul
-- Orb in Reyna's reach, if any (system 73). Returns what this tick does to
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
	cfg: any,
	soul: number?
): (MovementSim.Motion, { Cast }?)
	local buttons: number = input.buttons
	local keys = bit32.band(buttons, ALL)
	local pressed = bit32.band(keys, bit32.bnot(s.held))
	s.held = keys
	if s.readyUntil > 0 and t >= s.readyUntil - EPS then
		s.readyFrom, s.readyUntil = 0, 0
	end
	-- An ability in hand with no charge left to throw goes (one sold back),
	-- and the Resurrection's orb with its points short (system 39).
	if s.holding ~= 0 and not stocked(s, s.holding) then
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
	-- Dismiss over (system 73): she keeps no more than the run speed, as from
	-- a dash, and PlayerSim draws her gun again.
	if s.dismissUntil > 0 and not AbilitySim.dismissing(s, t) then
		s.dismissUntil = 0
		motion.cap = cfg.baseRunSpeed
		started({
			slot = AbilitySim.slotOf(s, "dismiss") or E,
			ability = "dismiss",
			kind = "solid",
			tick = tick,
			time = t,
			position = feet,
			origin = eye,
			direction = facing(input.yaw),
		})
	end
	-- A blast of Hunter's Fury's whose windup is over goes (system 46), from
	-- the eye along the crosshair, and its knockback starts; one that's run
	-- its time is over.
	if s.kickFrom > 0 and not AbilitySim.kicked(s, t) then
		s.kickFrom, s.kickYaw = 0, 0
	end
	if s.chargeAt > 0 and t >= s.chargeAt - EPS then
		s.chargeAt = 0
		s.kickFrom = t
		s.kickYaw = input.yaw
		started({
			slot = AbilitySim.slotOf(s, "huntersfury") or X,
			ability = "huntersfury",
			kind = "blast",
			tick = tick,
			time = t,
			position = feet,
			origin = eye,
			direction = Accuracy.aim(input.yaw, input.pitch),
		})
	end
	local free = not rooted and not AbilitySim.dashing(s, t) and not AbilitySim.marking(s, t) and not AbilitySim.dismissing(s, t)
	if pressed ~= 0 and free then
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
			elseif id == "huntersfury" and AbilitySim.charged(s) and not AbilitySim.ultimateOn(s) then
				-- Its bow in hand (PlayerSim), in place of an ability in hand
				-- and of a wall being bent, which runs straight on: the points
				-- spent, and its time running from once the bow's drawn.
				s.points = 0
				s.furyUntil = t + HF.equip.value + HF.duration.value
				s.holding = 0
				s.steering, s.steerUntil = 0, 0
				s.drawFrom, s.letDown, s.bounces = 0, false, 0
				local aim = Accuracy.aim(input.yaw, input.pitch)
				started({
					slot = slot,
					ability = id,
					kind = "fury",
					tick = tick,
					time = t,
					position = feet,
					origin = eye,
					direction = aim,
				})
			elseif (id == "devour" or id == "dismiss") and s.charges[slot] > 0 and soul ~= nil then
				-- The Soul Orb in reach taken (system 73), one a tick, and its
				-- charge spent; Dismiss's time starts, in place of an ability
				-- in hand, and nothing else casts in it.
				s.charges[slot] -= 1
				local aim = Accuracy.aim(input.yaw, input.pitch)
				started({
					slot = slot,
					ability = id,
					kind = id,
					tick = tick,
					time = t,
					position = feet,
					origin = eye,
					direction = aim,
					soul = soul,
				})
				soul = nil
				if id == "dismiss" then
					s.dismissUntil = t + RY.dismissTime.value
					s.holding = 0
					s.steering, s.steerUntil = 0, 0
					break
				end
			elseif held(def) and s.holding == slot and id == "barrierorb" then
				-- The Barrier Orb's key again turns its targeter (BarrierSim's
				-- quarter, or back across the view), and it stays in hand: a
				-- turn doesn't hold up the wall (until Patch 6.11, as the
				-- VALORANT Wiki's history has it, 'when Sage rotated her
				-- Barrier Orb 90 degrees, she was blocked from placing the
				-- wall for .8 seconds').
				s.turn = BarrierSim.toggled(s.turn)
				s.fixed = input.yaw + s.turn
			elseif held(def) and s.holding == slot and id == "darkcover" then
				-- Dark Cover's key again sends its orb to its mark ('throw
				-- smoke with the ABILITY KEY', Patch 1.0), if PlayerSim finds
				-- a floor there.
				local aim = Accuracy.aim(input.yaw, input.pitch)
				started({
					slot = slot,
					ability = id,
					kind = "smoke",
					tick = tick,
					time = t,
					position = feet,
					origin = eye,
					direction = aim,
					reach = s.reach,
				})
			elseif held(def) and s.holding == slot and AbilitySim.bowed(id) and s.drawFrom > 0 then
				-- A bolt's key again while it's drawn lets the draw go, the bow
				-- staying in hand, and fire let go then looses nothing (the
				-- VALORANT Wiki, of the Recon Bolt: recasting while charging
				-- resets it, to 'allow him to safely release his Fire key
				-- without firing the arrow').
				s.drawFrom = 0
				s.letDown = true
			elseif held(def) and s.holding == slot then
				-- Its key again: what's in hand goes away unthrown (PlayerSim).
				s.holding = 0
			elseif held(def) and not s.storm and stocked(s, slot) then
				-- In hand (PlayerSim), in place of any other ability there, and
				-- of a wall being bent, which runs straight on, and Hunter's
				-- Fury's over (system 46: Patch 3.0's 'equipping a weapon,
				-- ability, or Spike' cancels it); its charge goes as it's
				-- thrown (the Resurrection's points, as it brings someone back).
				s.holding = slot
				s.steering, s.steerUntil = 0, 0
				AbilitySim.calm(s)
				-- Nothing drawn or added yet (Sova's bow), and alt fire held as
				-- it comes isn't a press.
				s.drawFrom, s.letDown, s.bounces = 0, false, 0
				s.altDown = MovementSim.has(buttons, B.AltFire)
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

	-- The Barrier Orb in hand (system 38): with alt fire held its targeter
	-- keeps facing the way it did as alt fire went down, however she turns
	-- ('ALT FIRE rotates the targeter'), and the turn she's left it at is
	-- kept as it's let go.
	local inHand = AbilitySim.def(s, s.holding)
	if inHand and inHand.id == "barrierorb" and MovementSim.has(buttons, B.AltFire) then
		if not s.turning then
			s.turning = true
			s.fixed = input.yaw + s.turn
		end
		s.turn = BarrierSim.wrap(s.fixed - input.yaw)
	else
		s.turning = false
	end

	-- Dark Cover in hand (system 40): held fire sends its mark further and
	-- held alt fire brings it closer.
	if inHand and inHand.id == "darkcover" then
		local further = MovementSim.has(buttons, B.Fire)
		if further ~= MovementSim.has(buttons, B.AltFire) then
			s.reach = SmokeSim.moved(s.reach, further, dt)
		end
	end

	if AbilitySim.dashing(s, t) then
		motion.dash = vector.create(s.dashX, 0, s.dashZ)
	elseif AbilitySim.kicked(s, t) then
		-- A blast's knockback (system 46) moves him as a dash would.
		motion.dash = AbilitySim.kickVelocity(s, t, dt)
	elseif AbilitySim.lifting(s, t) then
		motion.lift = AbilitySim.liftSpeed(cfg.gravity, dt)
	elseif MovementSim.has(buttons, B.Jump) and AbilitySim.hasPassive(s, "drift") then
		-- Drift: once she's falling, the fall is held to a glide.
		motion.glide = { speed = AbilityConfig.Drift.fallSpeed.value, brake = AbilityConfig.Drift.brake.value }
	end
	return motion, casts
end

return AbilitySim
