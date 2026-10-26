--!strict
-- Sage's Resurrection (system 39): where the fallen lie, who a try brings
-- back, and when.
--
-- Someone who's fallen lies on the floor under where they fell, along the
-- way they faced, its middle there: as long as they stood tall, and as wide
-- and as thick as they were, their head, body and legs laid down (Hitboxes'
-- boxes, blocks). A try with fire brings back the fallen ally the
-- crosshair's over: of those the reviver can bring back, the first along
-- the crosshair it passes within its width of (AbilityConfig.Resurrection),
-- anywhere along them, within its reach, and in sight, any of their three
-- blocks' middles with nothing in the way.
--
-- Their return, from the cast: their body rises its height over its rise,
-- out of harm's way, and they burst out at the top (burstAt) with full
-- health and no shield; then they fall to the floor, held and in harm's
-- way, until they've control back (backAt).
--
-- No Roblox APIs here: the server passes its level in as `hidden`, so the
-- offline tests run it on a fake one.

local AbilityConfig = require("./AbilityConfig")
local HealSim = require("./HealSim")
local Health = require("../Combat/Health")
local Hitboxes = require("../Combat/Hitboxes")

-- Someone fallen: their entity id, the floor under where they fell (feet,
-- metres) and the way they faced (yaw, radians).
export type Body = { id: number, feet: vector, yaw: number }

local ReviveSim = {}

-- Where the server puts the bodies for every client (an invisible part
-- each, named by its owner's entity id, its CFrame where they lie and the
-- way they face), and the attributes a return under way sets on one: who
-- cast it (entity id) and when (server time).
ReviveSim.FOLDER = "VFBodies"
ReviveSim.BY = "VFReviver"
ReviveSim.AT = "VFReviveAt"
-- The name of the one a player last brought back, which scripted checks
-- read.
ReviveSim.LAST_ATTRIBUTE = "VFLastRevive"

local RES = AbilityConfig.Resurrection
local EPS = 1e-9
local UP = vector.create(0, 1, 0)

-- How they stood, head, body and legs, at the origin.
local STOOD = Hitboxes.build({ position = vector.create(0, 0, 0), yaw = 0, crouchAlpha = 0 })

-- How long a body lies: as tall as they stood, feet to the top of the head.
ReviveSim.LENGTH = STOOD[1].center.y + STOOD[1].half.y

-- What of the shield they wear they're brought back with: none, 'full HP
-- (excluding shields)' (the VALORANT Wiki), the kind kept for the next
-- life's (Health.restore).
ReviveSim.UNSHIELDED = table.freeze({ shield = 0, pool = 0 }) :: Health.Kept

-- How high off the floor the line along a body runs: halfway up its
-- thickest block, the body's.
local LIE = STOOD[2].half.z

-- The way someone facing `yaw` looks along the ground.
local function facing(yaw: number): vector
	return vector.create(-math.sin(yaw), 0, -math.cos(yaw))
end

-- A body's blocks (head, body and legs), laid along the way they faced,
-- feet behind and head ahead: each as long along it as it stood tall, as
-- thick as it was deep, and lying on the floor.
function ReviveSim.blocks(body: Body): { Hitboxes.Box }
	local along = facing(body.yaw)
	local out = table.create(#STOOD)
	for _, box in STOOD do
		table.insert(out, {
			region = box.region,
			center = body.feet + along * (box.center.y - ReviveSim.LENGTH / 2) + UP * box.half.z,
			half = vector.create(box.half.x, box.half.z, box.half.y),
			yaw = body.yaw,
		})
	end
	return out
end

-- The ends of the line along a body, feet and head.
local function ends(body: Body): (vector, vector)
	local half = facing(body.yaw) * (ReviveSim.LENGTH / 2)
	local middle = body.feet + UP * LIE
	return middle - half, middle + half
end

-- How far along the crosshair from `eye` (`aim` a unit vector) it's over
-- `body`, within the Resurrection's width and reach; nil if it isn't.
function ReviveSim.along(eye: vector, aim: vector, body: Body): number?
	local reach = RES.reach.value
	local a, b = ends(body)
	local s, apart = HealSim.closest(eye, eye + aim * reach, a, b)
	return if apart <= RES.width.value + EPS then s * reach else nil
end

-- The points of a body that sight is judged by: its blocks' middles.
function ReviveSim.points(body: Body): { vector }
	local out = {}
	for _, box in ReviveSim.blocks(body) do
		table.insert(out, box.center)
	end
	return out
end

-- The body a try from `eye` along `aim` (a unit vector) brings back, of
-- `bodies`, by entity id: the first along the crosshair it's over that
-- `hidden` (true when something's in the way between two points) doesn't
-- hide from the eye. Nil for nobody.
function ReviveSim.aimedAt(eye: vector, aim: vector, bodies: { Body }, hidden: (vector, vector) -> boolean): number?
	local over: { { body: Body, along: number } } = {}
	for _, body in bodies do
		local along = ReviveSim.along(eye, aim, body)
		if along then
			table.insert(over, { body = body, along = along })
		end
	end
	table.sort(over, function(a, b)
		return a.along < b.along
	end)
	for _, o in over do
		for _, point in ReviveSim.points(o.body) do
			if not hidden(eye, point) then
				return o.body.id
			end
		end
	end
	return nil
end

-- When a return cast at `at` has them burst out.
function ReviveSim.burstAt(at: number): number
	return at + RES.rise.value
end

-- And when they've control back, fallen to the floor.
function ReviveSim.backAt(at: number): number
	return at + RES.rise.value + RES.fall.value
end

-- How high a body of a return cast at `at` has risen at `t`: steadily, from
-- the floor to its height over its rise, and no higher.
function ReviveSim.risen(at: number, t: number): number
	return RES.height.value * math.clamp((t - at) / RES.rise.value, 0, 1)
end

return ReviveSim
