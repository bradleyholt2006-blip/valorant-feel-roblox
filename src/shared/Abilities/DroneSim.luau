--!strict
-- Sova's Owl Drone (system 47): how it flies, and the box shots strike.
--   * sent out, it flies on for its deploy as it was sent: level, from his
--     eye the way he faced, at its speed (AbilitySim.launch)
--   * then the keys fly it: along the ground the way the view faces, as
--     they'd move him, at its speed, and up with jump and down with crouch
--     at its climb (Patch 2.05's keys for 'flying up and down'; Aim Lab's
--     Sova guide: 'Use your jump key bind to raise the drone's elevation,
--     and your crouch key bind to lower the elevation.'). It gets to what
--     the keys ask at its accel, coming to a stop with none held
--   * its middle goes no higher over the floor below it than its ceiling
--     (Boosting Ground's Sova guide has its greatest height depend on the
--     ground beneath it): a rise stops there, and over a drop it sinks back
--     at its climb, as it does with no floor within its depth
--   * its box flies through the same world as the players (MovementSim.fly),
--     deflected off walls and sliding along floors, with no gravity
--   * shots and swings are traced through its box (DroneSim.level), and
--     those that strike it take its health (DroneServer)
-- The owner's PlayerSim flies it, so the client predicts it and the server
-- runs exactly the same ticks.
--
-- No Roblox APIs here: the world is MovementSim's, so the offline tests fly
-- it through a fake one.

local AbilityConfig = require("./AbilityConfig")
local MovementSim = require("../Movement/MovementSim")
local BoxMath = require("../Movement/BoxMath")
local Penetration = require("../Combat/Penetration")

-- A drone where shots are traced: its entity id and its middle (metres).
export type Posed = { id: number, position: vector }

-- A drone's box in a level, keyed by itself.
export type Piece = { box: BoxMath.Box, id: number, drone: boolean }

local DroneSim = {}

local DR = AbilityConfig.OwlDrone
local B = MovementSim.Buttons
local UP = vector.create(0, 1, 0)
local AXES = { vector.create(1, 0, 0), UP, vector.create(0, 0, 1) }

-- What the level calls a drone's surface.
DroneSim.SURFACE = "Owl Drone"

-- Attributes on a player, for scripted checks: the id the snapshots give
-- the drone they fly, while they fly it, and the health it has left; where
-- their last dart ended (metres), and whom it struck, a name or nothing.
DroneSim.ID_ATTRIBUTE = "VFDroneId"
DroneSim.HEALTH_ATTRIBUTE = "VFDroneHealth"
DroneSim.DART_ATTRIBUTE = "VFLastDart"
DroneSim.HIT_ATTRIBUTE = "VFDartHit"

-- Half its box.
function DroneSim.half(): vector
	return vector.create(DR.width.value / 2, DR.height.value / 2, DR.width.value / 2)
end

-- Its box with its middle at `position`, square to the world.
function DroneSim.box(position: vector): BoxMath.Box
	return { center = position, half = DroneSim.half(), axes = AXES }
end

-- How far its middle at `position` is over the floor below it: past its
-- depth, as far as that and more.
function DroneSim.over(world: MovementSim.World, position: vector): number
	local half = DroneSim.half()
	local fraction = world:sweep(position, half, UP * -DR.depth.value)
	if fraction == nil then
		return math.huge
	end
	return DR.depth.value * fraction + half.y
end

-- One tick of its flight, its middle at `position` and moving at
-- `velocity`: with `control`, the keys in `buttons` fly it, the way `yaw`
-- faces, and without, it flies on as it was going. Returns where it is
-- and how it's moving after the tick.
function DroneSim.step(
	position: vector,
	velocity: vector,
	buttons: number,
	yaw: number,
	control: boolean,
	dt: number,
	world: MovementSim.World,
	cfg: any
): (vector, vector)
	local wish = velocity
	if control then
		local rise = (if MovementSim.has(buttons, B.Jump) then 1 else 0) - (if MovementSim.has(buttons, B.Crouch) then 1 else 0)
		wish = MovementSim.wishDirection(buttons, yaw) * DR.speed.value + UP * (rise * DR.climb.value)
	end
	local change = wish - velocity
	local most = DR.accel.value * dt
	local size = vector.magnitude(change)
	if size > most then
		change *= most / size
	end
	velocity += change
	-- Its ceiling: a rise stops there, and above it, it sinks back.
	local room = DR.ceiling.value - DroneSim.over(world, position)
	if velocity.y * dt > room then
		velocity = vector.create(velocity.x, math.max(room / dt, -DR.climb.value), velocity.z)
	end
	return MovementSim.fly(world, position, velocity, DroneSim.half(), dt, cfg)
end

-- The piece a shot's surface is on, if it's a drone's.
function DroneSim.piece(key: any): Piece?
	if type(key) == "table" and key.drone == true then
		return key :: Piece
	end
	return nil
end

-- The level with drones in it ------------------------------------------------

local Shot = {}
Shot.__index = Shot

-- `base` with the boxes of `drones` in it, but `skip`'s (a drone's own
-- darts start in it), which shots and swings are traced through: each a
-- "solid" surface, so no bullet gets through one, keyed by its piece.
-- `base` itself with none.
function DroneSim.level(base: Penetration.Level, drones: { Posed }, skip: number?): Penetration.Level
	local pieces: { Piece } = {}
	for _, d in drones do
		if d.id ~= skip then
			table.insert(pieces, { box = DroneSim.box(d.position), id = d.id, drone = true })
		end
	end
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
		if DroneSim.piece(key) then
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
			best = { distance = distance, normal = normal, material = "solid", name = DroneSim.SURFACE, key = piece }
		end
	end
	return best
end

function Shot:exit(origin: vector, dir: vector, surface: Penetration.Surface, depth: number): (number?, vector?)
	if DroneSim.piece(surface.key) then
		return nil, nil
	end
	return self.base:exit(origin, dir, surface, depth)
end

return DroneSim
