--!strict
-- The fog of war (system 35): which entities each player's snapshots carry.
-- The reference's server "withholds information about the positions of
-- enemies until a client needs to display it" and stops sending updates of
-- an actor a player can't see (Riot, "Demolishing Wallhacks with VALORANT's
-- Fog of War"). Here an enemy is in a player's snapshots while a look finds
-- the player could see them by the next look, hears them now, or their side
-- spots them (the minimap's, system 34), and for a moment after: the
-- reference assumes "relevant actors stay relevant for a small amount of
-- time". Everyone else is always in: yourself, your side, practice dummies
-- and anyone on no side; and a player on no side (on the course, or
-- waiting in line to watch anyone) has everyone.
--
-- Seeing: a line from the viewer's eye to any of seven points of the
-- target's body that the level leaves open. The body is where it is and
-- where its velocity takes it by the next look, as Riot expanded "the
-- actor's bounding box by the actor's velocity multiplied by a 'look
-- ahead' time"; the eye is where it is and where the viewer's velocity
-- takes it by the time their screen shows this moment (how far behind it
-- is, measured from their inputs, plus the next look), stood up if they're
-- crouched. So a target is sent "just before the enemy came around the
-- corner", whoever's moving. Only the level is in the way: the reference's
-- works out what the map lets each part of it see, so clouds and walls of
-- fire hide nobody from it, and nor does the view's edge; on screen,
-- they're drawn behind them.
--
-- Hearing: a sound of theirs the viewer's near enough to hear. "If you can
-- hear an enemy that can trigger the location being sent to you" (a Riot
-- developer, via GINX). Their steps as they run along the ground, a landing
-- to come while they're in the air, a reload, the spike's plant or defuse
-- and a glide, each out to where its sound goes silent (SoundConfig).
--
-- No Roblox APIs: the server passes its level in as `blocked`, so the
-- offline tests run it on a fake one.

local SoundConfig = require("../Audio/SoundConfig")
local SoundMath = require("../Audio/SoundMath")
local PlayerCodec = require("../Net/PlayerCodec")
local Hitboxes = require("./Hitboxes")

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

-- Someone looking, in metres: their entity id and side (nil for none),
-- their eye, their velocity (metres a second), their eye stood up if
-- they're crouched, and how many seconds their screen is behind the server
-- (the server's time less the time their latest input saw).
export type Viewer = {
	id: number,
	side: number?,
	eye: vector,
	velocity: vector,
	standEye: vector?,
	behind: number,
}
-- Someone who can be seen or heard: their entity id and side, the pose the
-- snapshots show and their velocity.
export type Target = {
	id: number,
	side: number?,
	pose: PlayerCodec.Pose,
	velocity: vector,
}
export type Who = { id: number, side: number? }
-- True when something of the level is between two points.
export type Blocked = (from: vector, to: vector) -> boolean

-- Where both were when a look last found a target hidden, and when.
type Still = { eye: vector, velocity: vector, feet: vector, moving: vector, crouch: number, at: number }
-- A viewer and a target: in the snapshots until `untilTime`; when the lines
-- were last cast; the line that saw last; and where both were when they
-- found nothing.
export type Pair = { untilTime: number, checkedAt: number, line: number?, hidden: Still? }
export type State = { pairs: { [number]: { [number]: Pair } } }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local FogOfWar = {}

FogOfWar.Params = {
	every = p(
		0.05,
		"estimate",
		"Seconds from one of a player's looks to the next: 20 a second, a look every third snapshot (the reference looks with every network update, 'usually once each tick')"
	),
	hold = p(
		0.5,
		"estimate",
		"Seconds an enemy stays in a player's snapshots after the last look that found them (the reference assumes 'relevant actors stay relevant for a small amount of time'; no value given)"
	),
	recheck = p(
		0.25,
		"estimate",
		"Seconds between looks for an enemy already in a player's snapshots: half the hold, so one still in sight stays in"
	),
	ahead = p(
		0.05,
		"estimate",
		"Seconds past the next look that velocities carry the eye and the body looked at (Riot's look ahead was 'bigger than the expected ping time'; here each viewer's own delay is added to their eye)"
	),
	behindMost = p(
		0.25,
		"estimate",
		"Seconds at most a viewer's screen counts as behind, so a lagging player's eye isn't carried off along a line"
	),
	width = p(
		0.26,
		"estimate",
		"Metres from a body's middle to the edges looked at: the corner of its widest box (Hitboxes: the body's 0.22 by 0.14)"
	),
	hearing = p(
		2,
		"estimate",
		"Metres past a sound's silent edge a viewer still counts as hearing it, for what either moves before the next look"
	),
	moving = p(0.5, "estimate", "Metres a second along the ground that count as stepping (a run's steps are a stride apart, SoundConfig)"),
	still = p(
		0.05,
		"estimate",
		"Metres either may move, and metres a second either's velocity may change, before a look that found an enemy hidden is made again"
	),
	stale = p(
		1,
		"estimate",
		"Seconds at most a look that found an enemy hidden stands for while neither moves, in case the level has changed"
	),
	reveal = p(
		0.3,
		"estimate",
		"Seconds everyone is in a deathmatch player's snapshots as they come back to life, for the minimap's pulse of 'the location of all enemy players' (the VALORANT Wiki; community)"
	),
}

local P = FogOfWar.Params
local UP = vector.create(0, 1, 0)
local CHEST = vector.create(0, 1, 0) -- where a body's sounds are heard from, over its feet
local HEAD_TOP = 0.8 -- the head's points, this far from its middle to its top
local MIN_MOVE = 0.05 -- metres a velocity has to carry something to look from or at there too

-- Where each sound a body makes goes silent, metres (SoundConfig's curves):
-- steps and landings, a reload, a plant or a defuse, a glide, an ability's
-- cast, and Omen arriving by Shrouded Step (system 42).
local function edge(points: { { number } }): number
	return SoundMath.radius(points) or points[#points][1]
end
local C = SoundConfig.Curves
FogOfWar.Edges = {
	steps = edge(C.footstep.points),
	reload = edge(C.reload.points),
	device = edge(C.device.points),
	glide = edge(C.ability.points),
	cast = edge(C.ability.points),
	arrive = edge(C.arrival.points),
}

-- How far a weapon's shots or swings are heard, metres: where its sounds'
-- curve goes silent (SoundConfig.Weapons), a gunshot's for one it doesn't
-- know.
function FogOfWar.weaponEdge(weapon: string): number
	local sounds = SoundConfig.Weapons[weapon]
	local curve = if sounds then (C :: any)[sounds.curve] else nil
	return edge((curve or C.gunshot).points)
end

function FogOfWar.new(): State
	return { pairs = {} }
end

-- Whether `target` is always in `viewer`'s snapshots: themselves, their
-- side, and anyone on no side (dummies, the course), or for a viewer on no
-- side, anyone.
function FogOfWar.always(viewer: Who, target: Who): boolean
	return target.id == viewer.id or viewer.side == nil or target.side == nil or viewer.side == target.side
end

-- The points of a body standing at `feet` (crouched by `crouch`) looked at
-- from `eye`: near the top of its head, the middle of its body and of its
-- legs, and the head's and the body's points out at its edges as the eye
-- sees them, level and square to the line from it.
function FogOfWar.points(eye: vector, feet: vector, crouch: number): { vector }
	local boxes = Hitboxes.build({ position = feet, yaw = 0, crouchAlpha = crouch })
	local head, body, legs = boxes[1], boxes[2], boxes[3]
	local top = head.center + UP * (head.half.y * HEAD_TOP)
	local d = feet - eye
	local across = vector.create(-d.z, 0, d.x)
	local length = vector.magnitude(across)
	-- Straight above or below: any way level will do.
	across = if length > 1e-6 then across * (P.width.value / length) else vector.create(P.width.value, 0, 0)
	return { top, body.center, legs.center, top + across, top - across, body.center + across, body.center - across }
end

-- Where a viewer is looked from: their eye, and where their velocity
-- carries it (stood up if they're crouched) by the time their screen shows
-- this moment and the next look comes.
function FogOfWar.eyes(viewer: Viewer): { vector }
	local t = math.clamp(viewer.behind, 0, P.behindMost.value) + P.every.value + P.ahead.value
	local ahead = (viewer.standEye or viewer.eye) + viewer.velocity * t
	if vector.magnitude(ahead - viewer.eye) < MIN_MOVE then
		return { viewer.eye }
	end
	return { viewer.eye, ahead }
end

-- Where a target's body is looked at: where it is, and where its velocity
-- carries it by the next look.
function FogOfWar.bodies(target: Target): { vector }
	local feet = target.pose.position
	local ahead = feet + target.velocity * (P.every.value + P.ahead.value)
	if vector.magnitude(ahead - feet) < MIN_MOVE then
		return { feet }
	end
	return { feet, ahead }
end

-- Whether `viewer` could see `target` by the next look: the number of the
-- first line found that the level leaves open, from either eye to any point
-- of either body (numbered eye by eye, body by body, point by point), or
-- nil; and how many lines were cast. `first`, the line that saw last time,
-- is tried first.
function FogOfWar.sees(viewer: Viewer, target: Target, blocked: Blocked, first: number?): (number?, number)
	local from: { vector } = {}
	local to: { vector } = {}
	for _, eye in FogOfWar.eyes(viewer) do
		for _, feet in FogOfWar.bodies(target) do
			for _, point in FogOfWar.points(eye, feet, target.pose.crouchAlpha) do
				table.insert(from, eye)
				table.insert(to, point)
			end
		end
	end
	local cast = 0
	if first and from[first] then
		cast += 1
		if not blocked(from[first], to[first]) then
			return first, cast
		end
	end
	for i = 1, #from do
		if i ~= first then
			cast += 1
			if not blocked(from[i], to[i]) then
				return i, cast
			end
		end
	end
	return nil, cast
end

-- Whether a sound of `target`'s is heard at `ear`: their steps as they run
-- along the ground, a landing to come while they're in the air, a reload, a
-- plant or a defuse, or a glide.
function FogOfWar.hears(ear: vector, target: Target): boolean
	local pose = target.pose
	if not pose.alive then
		return false
	end
	local d = vector.magnitude(pose.position + CHEST - ear) - P.hearing.value
	local v = target.velocity
	local E = FogOfWar.Edges
	local stepping = pose.grounded and not pose.quiet and math.sqrt(v.x * v.x + v.z * v.z) >= P.moving.value
	return ((stepping or not pose.grounded) and d <= E.steps)
		or (pose.reloading and d <= E.reload)
		or (pose.channel ~= 0 and d <= E.device)
		or (pose.gliding and d <= E.glide)
end

local function moved(a: vector, b: vector): boolean
	return vector.magnitude(a - b) >= P.still.value
end

-- Whether both are as they were when a look not long ago found the target
-- hidden, so it would find the same.
local function unchanged(h: Still, now: number, viewer: Viewer, target: Target): boolean
	return now - h.at < P.stale.value
		and not moved(h.eye, viewer.eye)
		and not moved(h.velocity, viewer.velocity)
		and not moved(h.feet, target.pose.position)
		and not moved(h.moving, target.velocity)
		and math.abs(h.crouch - target.pose.crouchAlpha) < P.still.value
end

-- One look of `viewer`'s at `targets`, at `now`: every enemy they could see
-- by the next look, hear, or that `also` names (their side's spotting),
-- stays in their snapshots for the hold from now. Lines are cast only for
-- an enemy not heard or named: one in already, every `recheck`; one that
-- isn't, every look, unless neither has moved since a look found it hidden
-- (and that look isn't stale).
-- Returns how many lines were cast.
function FogOfWar.look(
	state: State,
	now: number,
	viewer: Viewer,
	targets: { Target },
	blocked: Blocked,
	also: { [number]: boolean }?
): number
	local mine = state.pairs[viewer.id]
	if not mine then
		mine = {}
		state.pairs[viewer.id] = mine
	end
	local cast = 0
	for _, target in targets do
		if FogOfWar.always(viewer, target) then
			continue
		end
		local pair = mine[target.id]
		if not pair then
			pair = { untilTime = -math.huge, checkedAt = -math.huge, line = nil, hidden = nil }
			mine[target.id] = pair
		end
		if (also ~= nil and also[target.id] == true) or FogOfWar.hears(viewer.eye, target) then
			pair.untilTime = now + P.hold.value
			continue
		end
		local shown = pair.untilTime > now
		if shown and now - pair.checkedAt < P.recheck.value then
			continue
		end
		local hidden = pair.hidden
		if not shown and hidden and unchanged(hidden, now, viewer, target) then
			continue
		end
		local line, n = FogOfWar.sees(viewer, target, blocked, pair.line)
		cast += n
		pair.checkedAt = now
		if line then
			pair.untilTime = now + P.hold.value
			pair.line = line
			pair.hidden = nil
		else
			pair.hidden = {
				eye = viewer.eye,
				velocity = viewer.velocity,
				feet = target.pose.position,
				moving = target.velocity,
				crouch = target.pose.crouchAlpha,
				at = now,
			}
		end
	end
	return cast
end

-- Whether `target` is in `viewer`'s snapshots at `now`.
function FogOfWar.shows(state: State, now: number, viewer: Who, target: Who): boolean
	if FogOfWar.always(viewer, target) then
		return true
	end
	local mine = state.pairs[viewer.id]
	local pair = if mine then mine[target.id] else nil
	return pair ~= nil and pair.untilTime > now
end

-- Whether `target` is in any of `viewers`' snapshots at `now`: what a
-- player who's down gets, from those on their side still in play.
function FogOfWar.anyShows(state: State, now: number, viewers: { Who }, target: Who): boolean
	for _, viewer in viewers do
		if FogOfWar.shows(state, now, viewer, target) then
			return true
		end
	end
	return false
end

-- Forgets an entity, as a viewer and as a target (they left).
function FogOfWar.forget(state: State, id: number)
	state.pairs[id] = nil
	for _, mine in state.pairs do
		mine[id] = nil
	end
end

return FogOfWar
