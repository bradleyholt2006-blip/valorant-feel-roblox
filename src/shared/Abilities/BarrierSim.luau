--!strict
-- Sage's Barrier Orb (system 38): where its wall goes, the wall, and what
-- it does to everything else.
--   * where it goes (BarrierSim.place): on the floor where the crosshair
--     meets it, no further than its range from the eye; past a wall, a
--     ceiling or nothing at all, on the floor below where the aim ends. It
--     faces the way the kit has it turned (AbilitySim): across the way she
--     looks, unless she's turned it
--   * its segments, in a row along it, each standing on the floor under
--     its middle if there's one not far over or under the targeter's, and
--     left out if not: the reference's 'Will only spawn a chunk of the
--     barrier if it is supported by the ground' (Patch 0.49). One that
--     would touch the planted spike breaks as it rises (BarrierSim.raise)
--   * none goes up in the buy phase (Patch 1.14: 'Barrier Orb can't be
--     cast in Buy Phase'): the walls the simulation's given say so
--     (Walls.closed), and the orb stays in hand
--   * from the time it's raised, each segment rises out of its floor to
--     its height over the deploy time, and stands until it breaks or the
--     wall's time is up, when they all go together
--   * standing, a segment is a box in the world everyone moves through
--     (BarrierSim.world): nobody walks through it, and anyone standing
--     where it rises is lifted on its top, as MovementSim keeps them clear
--     of whatever they're in. In the level that shots are traced through,
--     it's a surface no bullet goes through (BarrierSim.level), and it's in
--     the way of a sight (BarrierSim.hides)
--   * its health is each segment's own, which the server keeps: it
--     fortifies (BarrierSim.fortify) and decays (BarrierSim.decay) as the
--     wall's time goes
-- The server raises each wall where the caster's simulation placed it as
-- the cast's tick ran there, and tells every client of it and of each
-- segment that breaks (BarrierServer). Both ends judge where it stands at
-- the server time each input's screen showed, as the Slow Orb's fields are
-- (SlowSim.judged), so the owner's prediction meets it where the server's
-- simulation does.
--
-- No Roblox APIs here.

local AbilityConfig = require("./AbilityConfig")
local BoxMath = require("../Movement/BoxMath")
local MovementSim = require("../Movement/MovementSim")
local Penetration = require("../Combat/Penetration")

-- One of a wall's segments: its place in the row (1 to the most, along the
-- wall), the point on the floor under its middle, in metres, and the server
-- time it broke, if it has.
export type Segment = { index: number, base: vector, broken: number? }
-- Where a wall goes: the targeter's point on the floor, the yaw it faces
-- (radians, as a view's), and the segments with a floor under them.
export type Placement = { centre: vector, angle: number, segments: { Segment } }
-- A wall raised: whose (an entity id), which (the cast's tick), from when
-- (server time), and where.
export type Wall = { owner: number, id: number, start: number, centre: vector, angle: number, segments: { Segment } }
-- The walls in play, the server time they're judged at, and whether no
-- wall goes up then (the buy phase).
export type Walls = { walls: { Wall }, time: number, closed: boolean? }
-- A segment standing at some time, as a box, with its separating axes
-- (BoxMath.axes), and whose it is. A shot's surface on it has it as its
-- key.
export type Piece = { box: BoxMath.Box, axes: { vector }, wall: Wall, segment: Segment, barrier: boolean }

local BarrierSim = {}

local BO = AbilityConfig.BarrierOrb
local EPS = 1e-9
local UP = vector.create(0, 1, 0)
local DOWN = vector.create(0, -1, 0)
-- Half the size of the boxes that look for where it goes: about a
-- crosshair's line (ours).
local THIN = vector.create(0.05, 0.05, 0.05)
-- How far short of what the aim meets the floor below is looked for, so
-- it's on this side of a wall the aim meets (ours).
local BACK = 0.1
-- Half the planted spike, from the floor it stands on up, as SpikeView
-- draws it (ours: its size isn't published).
local SPIKE_HALF = vector.create(0.13, 0.2, 0.13)

-- A sweep misses a segment it starts within this of (metres), as Roblox's
-- Blockcast misses a part (the offline tests' world has the same).
BarrierSim.TOLERANCE = 0.001
-- What C again turns the targeter by: a quarter turn, as a recast does
-- (the VALORANT Wiki).
BarrierSim.QUARTER = math.pi / 2
-- What a segment's surface is called, for the shots' debug tools.
BarrierSim.SURFACE = "Barrier"
-- The player attribute each owner's last wall is kept in, for scripted
-- checks: each segment's health in the row, "x" for one broken or gone
-- and "-" for one left out ("600,600,-,412").
BarrierSim.HEALTH_ATTRIBUTE = "VFWall"

-- The yaw a wall faces, raised by someone facing `yaw` with the targeter
-- turned `turn` from across their view.
function BarrierSim.angle(yaw: number, turn: number): number
	return yaw + turn
end

-- The way along a wall facing `angle` (its length), and the way it faces
-- (through it), both level.
function BarrierSim.axes(angle: number): (vector, vector)
	local s, c = math.sin(angle), math.cos(angle)
	return vector.create(c, 0, -s), vector.create(-s, 0, -c)
end

-- A turn kept within half a turn either way.
function BarrierSim.wrap(turn: number): number
	return (turn + math.pi) % (2 * math.pi) - math.pi
end

-- The turn C again leaves (AbilitySim): a quarter from across the view,
-- and across the view from anywhere else (the VALORANT Wiki has a recast
-- after alt fire put the targeter back across the view or along it).
function BarrierSim.toggled(turn: number): number
	return if math.abs(BarrierSim.wrap(turn)) < 1e-6 then BarrierSim.QUARTER else 0
end

-- The floor under `from`, within `distance` below it: the point on it,
-- or nil if there's none or it's too steep.
local function floorBelow(world: MovementSim.World, from: vector, distance: number): vector?
	local fraction, normal = world:sweep(from, THIN, DOWN * distance)
	if not fraction or not normal or normal.y < BO.floor.value then
		return nil
	end
	return from + DOWN * (distance * fraction + THIN.y)
end

-- Where the wall of a cast from `eye` (metres) along `aim`, facing
-- `angle`, goes through `world`: the targeter's floor and the segments
-- with a floor under them. Nil if there's no floor for it, or for none of
-- its segments.
function BarrierSim.place(world: MovementSim.World, eye: vector, aim: vector, angle: number): Placement?
	local range = BO.range.value
	local dir = vector.normalize(aim)
	local fraction, normal = world:sweep(eye, THIN, dir * range)
	local reach = if fraction then range * fraction else range
	local centre: vector?
	if fraction and normal and normal.y >= BO.floor.value then
		-- The aim meets a floor: it goes where the crosshair's line meets
		-- the floor's face, rather than where the box that looked for it
		-- touched it, short of that.
		local face = vector.dot(normal, eye + dir * reach) - BoxMath.aabbReach(THIN, normal)
		local towards = vector.dot(normal, dir)
		local at = if towards < -EPS then (face - vector.dot(normal, eye)) / towards else reach
		centre = eye + dir * math.max(at, 0)
	else
		centre = floorBelow(world, eye + dir * math.max(reach - BACK, 0), BO.drop.value)
	end
	if not centre then
		return nil
	end
	local along = BarrierSim.axes(angle)
	local n = BO.segments.value
	-- Each segment looks for its floor from just over the most it climbs,
	-- so a crate as high as that is under the look rather than round it.
	local over = BO.climb.value + THIN.y + 0.01
	local segments: { Segment } = {}
	for i = 1, n do
		local middle = centre + along * ((i - (n + 1) / 2) * BO.length.value)
		local base = floorBelow(world, middle + UP * over, over + BO.fall.value)
		if base then
			table.insert(segments, { index = i, base = base })
		end
	end
	if #segments == 0 then
		return nil
	end
	return { centre = centre, angle = angle, segments = segments }
end

-- The wall `owner` raised with the cast on tick `id`, at server time
-- `start`, where `placed` says. With the spike planted at `spike` (the
-- floor under it, metres), a segment that would touch it breaks as it
-- rises (the VALORANT Wiki has one touching the planted spike break at
-- once).
function BarrierSim.raise(owner: number, id: number, start: number, placed: Placement, spike: vector?): Wall
	local segments: { Segment } = {}
	local wall: Wall = { owner = owner, id = id, start = start, centre = placed.centre, angle = placed.angle, segments = segments }
	for _, segment in placed.segments do
		local raised: Segment = { index = segment.index, base = segment.base }
		if spike and BarrierSim.touches(wall, raised, spike) then
			raised.broken = start
		end
		table.insert(segments, raised)
	end
	return wall
end

-- When a wall's time is up, when it fortifies, and when it starts to decay.
function BarrierSim.ends(wall: Wall): number
	return wall.start + BO.duration.value
end

function BarrierSim.fortifies(wall: Wall): number
	return wall.start + BO.fortify.value
end

function BarrierSim.decays(wall: Wall): number
	return wall.start + BO.decay.value
end

-- How far a wall has risen at `t`, 0 to 1 of its height.
function BarrierSim.risen(wall: Wall, t: number): number
	return math.clamp((t - wall.start) / BO.rise.value, 0, 1)
end

-- Whether a segment stands at `t`: raised, not broken, and its wall's time
-- not up.
function BarrierSim.standing(wall: Wall, segment: Segment, t: number): boolean
	local broken = segment.broken
	return t >= wall.start and t < BarrierSim.ends(wall) and (broken == nil or t < broken)
end

-- A segment's box at `t`: from its depth under its floor up to as far as
-- it has risen, as long as a segment and as thick, facing as its wall does.
function BarrierSim.box(wall: Wall, segment: Segment, t: number): BoxMath.Box
	local along, across = BarrierSim.axes(wall.angle)
	local bottom = segment.base.y - BO.sink.value
	local top = segment.base.y + BO.height.value * BarrierSim.risen(wall, t)
	return {
		center = vector.create(segment.base.x, (bottom + top) / 2, segment.base.z),
		half = vector.create(BO.length.value / 2, (top - bottom) / 2, BO.thickness.value / 2),
		axes = { along, UP, across },
	}
end

-- Whether a segment, risen all the way, would touch the spike planted on
-- the floor at `spike` (metres).
function BarrierSim.touches(wall: Wall, segment: Segment, spike: vector): boolean
	local box = BarrierSim.box(wall, segment, wall.start + BO.rise.value)
	return BoxMath.separation(spike + vector.create(0, SPIKE_HALF.y, 0), SPIKE_HALF, box) < 0
end

-- Every segment of `walls` standing at `t`.
function BarrierSim.pieces(walls: { Wall }, t: number): { Piece }
	local out: { Piece } = {}
	for _, wall in walls do
		for _, segment in wall.segments do
			if BarrierSim.standing(wall, segment, t) then
				local box = BarrierSim.box(wall, segment, t)
				table.insert(out, { box = box, axes = BoxMath.axes(box), wall = wall, segment = segment, barrier = true })
			end
		end
	end
	return out
end

-- The piece a shot's surface is on, if it's a segment's.
function BarrierSim.piece(key: any): Piece?
	if type(key) == "table" and key.barrier == true then
		return key :: Piece
	end
	return nil
end

-- The world with walls in it --------------------------------------------------

local Walled = {}
Walled.__index = Walled

-- `base` with the segments of `walls` standing at `t` in it, which is what
-- everyone moves through; `base` itself when none stand.
function BarrierSim.world(base: MovementSim.World, walls: { Wall }, t: number): MovementSim.World
	local pieces = BarrierSim.pieces(walls, t)
	if #pieces == 0 then
		return base
	end
	return (setmetatable({ base = base, pieces = pieces }, Walled) :: any) :: MovementSim.World
end

function Walled:sweep(center: vector, half: vector, delta: vector): (number?, vector?)
	local best, normal = self.base:sweep(center, half, delta)
	for _, piece in self.pieces do
		local t, n = BoxMath.sweep(center, half, delta, piece.box, piece.axes, BarrierSim.TOLERANCE)
		if t and (best == nil or t < best) then
			best, normal = t, n
		end
	end
	return best, normal
end

function Walled:overlaps(center: vector, half: vector): boolean
	if self.base:overlaps(center, half) then
		return true
	end
	for _, piece in self.pieces do
		if BoxMath.separation(center, half, piece.box, piece.axes) < 0 then
			return true
		end
	end
	return false
end

function Walled:nearest(center: vector, half: vector, margin: number): (number?, vector?)
	local best, away = self.base:nearest(center, half, margin)
	for _, piece in self.pieces do
		local gap, out = BoxMath.separation(center, half, piece.box, piece.axes)
		if gap <= margin and (best == nil or gap < best) then
			best, away = gap, out
		end
	end
	return best, away
end

-- The level with walls in it ---------------------------------------------------

local Shot = {}
Shot.__index = Shot

-- `base` with the segments of `walls` standing at `t` in it, which is what
-- shots are traced through: each a "solid" surface, so no bullet gets
-- through (Penetration), keyed by its piece. `base` itself when none
-- stand.
function BarrierSim.level(base: Penetration.Level, walls: { Wall }, t: number): Penetration.Level
	local pieces = BarrierSim.pieces(walls, t)
	if #pieces == 0 then
		return base
	end
	return (setmetatable({ base = base, pieces = pieces }, Shot) :: any) :: Penetration.Level
end

function Shot:cast(origin: vector, dir: vector, maxDistance: number, skip: { any }): Penetration.Surface?
	-- The level's own pieces go to it; it knows nothing of these.
	local rest: { any } = {}
	local passed: { [any]: boolean } = {}
	for _, key in skip do
		if BarrierSim.piece(key) then
			passed[key] = true
		else
			table.insert(rest, key)
		end
	end
	local best: Penetration.Surface? = self.base:cast(origin, dir, maxDistance, rest)
	for _, piece in self.pieces do
		if passed[piece] then
			continue
		end
		local distance, normal = BoxMath.ray(origin, dir, maxDistance, piece.box)
		if distance and normal and (best == nil or distance < best.distance) then
			best = { distance = distance, normal = normal, material = "solid", name = BarrierSim.SURFACE, key = piece }
		end
	end
	return best
end

function Shot:exit(origin: vector, dir: vector, surface: Penetration.Surface, depth: number): (number?, vector?)
	if BarrierSim.piece(surface.key) then
		return nil, nil
	end
	return self.base:exit(origin, dir, surface, depth)
end

-- Sight ------------------------------------------------------------------------

-- Whether a segment of `walls` standing at `t` is in the way from `a` to
-- `b`: the line between them goes through it, or either end is in it.
function BarrierSim.hides(walls: { Wall }, t: number, a: vector, b: vector): boolean
	local ab = b - a
	local length = vector.magnitude(ab)
	for _, wall in walls do
		for _, segment in wall.segments do
			if not BarrierSim.standing(wall, segment, t) then
				continue
			end
			local box = BarrierSim.box(wall, segment, t)
			if BoxMath.inside(a, box) or BoxMath.inside(b, box) then
				return true
			end
			if length > EPS and BoxMath.ray(a, ab / length, length, box) ~= nil then
				return true
			end
		end
	end
	return false
end

-- Health -----------------------------------------------------------------------

-- A segment's health once it's fortified, from `health` before: what
-- fortifying adds, so what it's lost stays lost (Patch 6.04: 'max health
-- minus the damage that was dealt during fortification').
function BarrierSim.fortify(health: number): number
	return health + BO.fortified.value - BO.health.value
end

-- A segment's health at `to`, from `health` at `from`: once its wall
-- decays it loses its share of what's left of the wall's time, so every
-- segment comes to nothing as the time's up, whatever it had, and none
-- goes before the rest (the VALORANT Wiki has each lose a share of the
-- health it has left, and all of them expire together).
function BarrierSim.decay(wall: Wall, health: number, from: number, to: number): number
	local ends = BarrierSim.ends(wall)
	local start = math.max(from, BarrierSim.decays(wall))
	if to <= start then
		return health
	elseif to >= ends then
		return 0
	end
	return health * (ends - to) / (ends - start)
end

-- A wall's segments as BarrierSim.HEALTH_ATTRIBUTE has them at `t`, from
-- each one's health (by its place in `wall.segments`).
function BarrierSim.summary(wall: Wall, health: { number }, t: number): string
	local parts = table.create(BO.segments.value, "-")
	for i, segment in wall.segments do
		parts[segment.index] = if BarrierSim.standing(wall, segment, t)
			then tostring(math.max(math.floor((health[i] or 0) + 0.5), 1))
			else "x"
	end
	return table.concat(parts, ",")
end

return BarrierSim
