--!strict
-- The plant and the defuse (system 12), stepped inside PlayerSim from the
-- same input as movement and weapons, so the client predicts them and the
-- server runs exactly the same ticks.
--
-- Holding Use (4) or fire with the spike in hand, on the ground inside a
-- site's plant area, plants it in plantTime. Holding Use within range of the
-- planted spike, with sight of it, defuses it: defuseTime, or what's left
-- after a saved half. Either roots the player where they are (they can still
-- turn and crouch) and ends the moment the button is let go: a plant starts
-- over, a defuse keeps its half once past it. A defuse also ends the moment
-- its defuser is out of range or loses sight of the spike (Patches 2.07 and
-- 6.10), crouching behind cover, say. G drops the spike from the hand. A
-- defuse puts the weapon away, and the weapon comes back with its draw time
-- when it ends, as it does after a plant or a drop.
--
-- What the server must act on comes out as an Act: the spike planted,
-- defused, dropped, or a defuse let go of (for its saved half).

local Spike = require("./Spike")
local MovementSim = require("../Movement/MovementSim")
local WeaponSim = require("../Weapons/WeaponSim")

export type State = {
	channel: number, -- 0 nothing, 1 planting, 2 defusing
	channelStart: number, -- simulation time it started
	channelEnd: number, -- when it completes
	halfStart: boolean, -- this defuse started from a saved half
	lastSlot: number, -- the weapon to go back to when the spike leaves the hand
	dropHeld: boolean,
	-- A plant or a defuse has just completed with its button still held:
	-- nothing more starts until it's let go (on the course a planter would
	-- otherwise go straight on to defuse their own spike).
	holdOver: boolean,
}

export type ActKind = "planted" | "defused" | "stopped" | "dropped"
export type Act = {
	kind: ActKind,
	tick: number,
	time: number,
	position: vector, -- metres: where it was planted or dropped, or the defuser's feet
	yaw: number,
	site: string?, -- planted: the site
	progress: number, -- stopped: seconds of the 7 the defuse reached
}

local SpikeSim = {}

SpikeSim.NONE = 0
SpikeSim.PLANTING = 1
SpikeSim.DEFUSING = 2

local B = MovementSim.Buttons
local EPS = 1e-9
-- What a rooted player's movement keeps of their buttons.
local ROOTED_MASK = bit32.bnot(bit32.bor(B.Forward, B.Back, B.Left, B.Right, B.Jump))

function SpikeSim.new(): State
	return { channel = 0, channelStart = 0, channelEnd = 0, halfStart = false, lastSlot = 1, dropHeld = false, holdOver = false }
end

function SpikeSim.copy(s: State): State
	return table.clone(s)
end

local function has(buttons: number, flag: number): boolean
	return bit32.band(buttons, flag) ~= 0
end

-- Whether a player's weapons have the spike in hand.
function SpikeSim.inHand(w: WeaponSim.State): boolean
	return w.equipped == Spike.SLOT and w.loadout[Spike.SLOT] == Spike.ID
end

function SpikeSim.carrying(w: WeaponSim.State): boolean
	return w.loadout[Spike.SLOT] == Spike.ID
end

-- The buttons movement sees: none of the moving ones while rooted.
function SpikeSim.movementButtons(s: State, buttons: number): number
	return if s.channel ~= SpikeSim.NONE then bit32.band(buttons, ROOTED_MASK) else buttons
end

-- How far the plant or defuse under way has got, 0 to 1, at time `t`.
function SpikeSim.fraction(s: State, t: number): number
	if s.channel == SpikeSim.NONE then
		return 0
	end
	if s.channel == SpikeSim.DEFUSING then
		local full = Spike.Params.defuseTime.value
		return math.clamp(Spike.defuseProgress(s.halfStart, t - s.channelStart) / full, 0, 1)
	end
	return math.clamp((t - s.channelStart) / (s.channelEnd - s.channelStart), 0, 1)
end

-- Seconds of the 7 the defuse under way has reached at time `t`, counting a
-- saved half (0 when not defusing).
function SpikeSim.defuseProgress(s: State, t: number): number
	if s.channel ~= SpikeSim.DEFUSING then
		return 0
	end
	return Spike.defuseProgress(s.halfStart, t - s.channelStart)
end

-- Takes the spike out of the hand (planted or dropped): the weapon it
-- replaced is drawn again.
local function release(s: State, w: WeaponSim.State, t: number)
	WeaponSim.give(w, Spike.SLOT, "")
	local back = s.lastSlot
	if back < 1 or back >= Spike.SLOT or w.loadout[back] == "" then
		back = 1
		for slot = 1, Spike.SLOT - 1 do
			if w.loadout[slot] ~= "" then
				back = slot
				break
			end
		end
	end
	w.equipped = back
	WeaponSim.redraw(w, t)
end

local function stop(s: State)
	s.channel = SpikeSim.NONE
	s.halfStart = false
end

-- Takes the spike from a player, by the server's doing (it's handed to
-- someone else, or the arena starts): a plant under way stops, and the
-- weapon it replaced is drawn if it was in hand.
function SpikeSim.take(s: State, w: WeaponSim.State, t: number)
	if not SpikeSim.carrying(w) then
		return
	end
	if s.channel == SpikeSim.PLANTING then
		stop(s)
	end
	if SpikeSim.inHand(w) then
		release(s, w, t)
	else
		WeaponSim.give(w, Spike.SLOT, "")
	end
end

-- Roots the player where they stand.
local function root(m: MovementSim.State)
	local v = m.velocity
	m.velocity = vector.create(0, v.y, 0)
end

-- Whether a defuser with their feet at `feet` and their eye at `eye` can
-- defuse the spike at `spike`: close enough, and seeing it.
local function canReach(ctx: Spike.Context, feet: vector, eye: vector, spike: vector): boolean
	if not Spike.inDefuseRange(feet, spike) then
		return false
	end
	local sees = ctx.sees
	return sees == nil or sees(eye, spike)
end

-- Where the spike goes down: a little in front of the planter, if that's
-- still inside the site, otherwise at their feet.
local function plantPoint(zones: { Spike.Zone }, feet: vector, yaw: number): vector
	local ahead = feet + vector.create(-math.sin(yaw), 0, -math.cos(yaw)) * Spike.Params.plantAhead.value
	return if Spike.siteAt(zones, ahead) then ahead else feet
end

-- One tick, before movement: starts, carries on, ends or completes the plant
-- or the defuse, and drops the spike on G. `eye` is the eye before this
-- tick's movement. Returns what the server must act on, if anything.
function SpikeSim.step(
	s: State,
	m: MovementSim.State,
	w: WeaponSim.State,
	input: any,
	t: number,
	tick: number,
	eye: vector,
	ctx: Spike.Context
): Act?
	local buttons: number = input.buttons
	local use = has(buttons, B.Use)
	local fire = has(buttons, B.Fire)
	local drop = has(buttons, B.Drop)
	local dropPressed = drop and not s.dropHeld
	s.dropHeld = drop
	if s.holdOver and not (use or fire) then
		s.holdOver = false
	end
	if w.equipped ~= Spike.SLOT then
		s.lastSlot = w.equipped
	end
	local feet = m.position

	local function act(kind: ActKind, position: vector, site: string?, progress: number): Act
		return { kind = kind, tick = tick, time = t, position = position, yaw = input.yaw, site = site, progress = progress }
	end

	if s.channel == SpikeSim.PLANTING then
		if not ((use or fire) and SpikeSim.inHand(w) and m.grounded and ctx.canPlant) then
			stop(s)
		elseif t >= s.channelEnd - EPS then
			stop(s)
			s.holdOver = true
			local at = plantPoint(ctx.zones, feet, input.yaw)
			release(s, w, t)
			return act("planted", at, Spike.siteAt(ctx.zones, at) or Spike.siteAt(ctx.zones, feet), 0)
		else
			return nil
		end
	elseif s.channel == SpikeSim.DEFUSING then
		local planted = ctx.planted
		local progress = Spike.defuseProgress(s.halfStart, t - s.channelStart)
		if not (use and planted and ctx.canDefuse and canReach(ctx, feet, eye, planted)) then
			stop(s)
			WeaponSim.redraw(w, t)
			return act("stopped", feet, nil, progress)
		elseif t >= s.channelEnd - EPS then
			stop(s)
			s.holdOver = true
			WeaponSim.redraw(w, t)
			return act("defused", planted, nil, Spike.Params.defuseTime.value)
		else
			return nil
		end
	end

	-- Nothing under way: G drops the spike from the hand, and holding Use
	-- (or fire, with the spike in hand) starts a plant or a defuse.
	if dropPressed and SpikeSim.inHand(w) then
		release(s, w, t)
		return act("dropped", feet, nil, 0)
	end
	if not m.grounded or s.holdOver then
		return nil
	end
	if (use or fire) and SpikeSim.inHand(w) and ctx.canPlant and t >= w.equipEndTime - EPS and Spike.siteAt(ctx.zones, feet) then
		s.channel = SpikeSim.PLANTING
		s.channelStart = t
		s.channelEnd = t + Spike.Params.plantTime.value
		root(m)
		return nil
	end
	local planted = ctx.planted
	if use and planted and ctx.canDefuse and not SpikeSim.inHand(w) and canReach(ctx, feet, eye, planted) then
		s.channel = SpikeSim.DEFUSING
		s.channelStart = t
		s.halfStart = ctx.halfSaved
		s.channelEnd = t + Spike.defuseTime(ctx.halfSaved)
		root(m)
		WeaponSim.holster(w)
	end
	return nil
end

return SpikeSim
