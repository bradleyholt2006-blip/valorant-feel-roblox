--!strict
-- Measures each time in the air (a jump, or a step off a ledge) from a
-- stream of movement ticks, so air control can be compared with footage of
-- the reference game: how long it lasted, where it landed (along where you
-- faced when you left the ground, and to the side of that), how high the
-- feet rose, the speed along the ground leaving and landing, the fastest in
-- between, and how far the path turned on the way (air strafing bends it).
--
-- Pure module: used by the HUD (F3) and by the offline tests.

export type Jump = {
	airtime: number, -- s from the last tick on the ground to the first one back on it
	distance: number, -- m along the ground from take-off to landing
	forward: number, -- m of that along where you faced at take-off
	side: number, -- m of it to the right of that (negative: left)
	rise: number, -- m the feet rose above take-off at their highest (0 off a ledge)
	takeoffSpeed: number, -- m/s along the ground on the first tick in the air
	landingSpeed: number, -- m/s along the ground on landing
	peakSpeed: number, -- m/s, the fastest along the ground in between
	bend: number, -- degrees the path turned in the air, right positive
}

type Flight = {
	time: number,
	position: vector,
	top: number, -- the feet's highest so far
	yaw: number,
	takeoffSpeed: number,
	peakSpeed: number,
	bend: number,
	lastDir: vector?,
}

export type Analyzer = {
	flight: Flight?,
	last: { time: number, position: vector, yaw: number, grounded: boolean }?,
	history: { Jump },
	maxHistory: number,
}

-- Slower than this along the ground, the path has no direction to turn.
local MOVING = 0.1 -- m/s
-- A tick that swings the path further than this went through a stop (the
-- opposite key braked it and pushed it back), which isn't a turn.
local REVERSAL = 90 -- degrees

local JumpAnalyzer = {}

function JumpAnalyzer.new(maxHistory: number?): Analyzer
	return { flight = nil, last = nil, history = {}, maxHistory = maxHistory or 20 }
end

-- Forgets everything, the last tick included: after a respawn the next
-- tick is somewhere else, and isn't a take-off.
function JumpAnalyzer.clear(a: Analyzer)
	a.flight = nil
	a.last = nil
	table.clear(a.history)
end

local function ground(v: vector): vector
	return vector.create(v.x, 0, v.z)
end

-- Feeds one tick: the time at its end, where the player is, its velocity,
-- whether it's on the ground and the yaw it was steered with (Roblox: 0
-- looks down -Z, turning right lowers it). Returns the jump it finished, if
-- it landed on this tick.
function JumpAnalyzer.tick(a: Analyzer, time: number, position: vector, velocity: vector, grounded: boolean, yaw: number): Jump?
	local last = a.last
	a.last = { time = time, position = position, yaw = yaw, grounded = grounded }
	local h = ground(velocity)
	local speed = vector.magnitude(h)
	local flight = a.flight
	if flight == nil then
		if grounded or last == nil or not last.grounded then
			return nil
		end
		-- Left the ground on this tick: measured from where the last tick on it ended.
		a.flight = {
			time = last.time,
			position = last.position,
			top = math.max(last.position.y, position.y),
			yaw = last.yaw,
			takeoffSpeed = speed,
			peakSpeed = speed,
			bend = 0,
			lastDir = if speed > MOVING then h / speed else nil,
		}
		return nil
	end

	flight.peakSpeed = math.max(flight.peakSpeed, speed)
	flight.top = math.max(flight.top, position.y)
	if speed > MOVING then
		local dir = h / speed
		local prev = flight.lastDir
		if prev then
			local turn = math.deg(math.atan2(prev.x * dir.z - prev.z * dir.x, vector.dot(prev, dir)))
			if math.abs(turn) < REVERSAL then
				flight.bend += turn
			end
		end
		flight.lastDir = dir
	end
	if not grounded then
		return nil
	end

	a.flight = nil
	local moved = ground(position - flight.position)
	local s, c = math.sin(flight.yaw), math.cos(flight.yaw)
	local jump: Jump = {
		airtime = time - flight.time,
		distance = vector.magnitude(moved),
		forward = vector.dot(moved, vector.create(-s, 0, -c)),
		side = vector.dot(moved, vector.create(c, 0, -s)),
		rise = flight.top - flight.position.y,
		takeoffSpeed = flight.takeoffSpeed,
		landingSpeed = speed,
		peakSpeed = flight.peakSpeed,
		bend = flight.bend,
	}
	table.insert(a.history, jump)
	if #a.history > a.maxHistory then
		table.remove(a.history, 1)
	end
	return jump
end

return JumpAnalyzer
