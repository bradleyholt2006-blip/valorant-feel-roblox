--!strict
-- Detects "stops" in a stream of movement ticks and measures them, so our
-- numbers can be compared with frame-counted footage of the reference game.
--
-- A stop starts on the tick the player stops asking to move in their current
-- direction (key released, or opposite key pressed) while moving faster than
-- the accuracy threshold. It is timed from the end of the tick before, when
-- the key changed, so a stop that crossed the threshold within its first tick
-- took one tick, the way footage times it from the key. It is measured until
-- speed is ~zero or the player asks to move again. The reference times are
-- for stops from a full run, so a stop that began slower is logged but left
-- out of the averages.
--
-- Pure module: used by the in-game Counter-Strafe Lab and by the offline tests.

export type StopMethod = "release" | "counter" | "mixed"

export type StopResult = {
	method: StopMethod,
	startSpeed: number, -- m/s when the key changed (the end of the tick before)
	fromFullSpeed: boolean, -- began at the full speed given to tick (always true when none was)
	timeToAccurate: number?, -- s until speed <= threshold (nil if never)
	timeToZero: number?, -- s until speed <= zeroSpeed
	distance: number, -- m travelled after the stop began
	threshold: number, -- m/s accuracy threshold used
}

type Active = {
	startTime: number,
	startSpeed: number,
	fromFullSpeed: boolean,
	startDir: vector,
	method: StopMethod,
	timeToAccurate: number?,
	distance: number,
	threshold: number,
	lastPos: vector,
}

local ZERO_SPEED = 0.05

local StopAnalyzer = {}
StopAnalyzer.__index = StopAnalyzer

export type Analyzer = typeof(setmetatable(
	{} :: {
		active: Active?,
		lastWish: vector,
		lastTime: number?,
		lastSpeed: number?,
		history: { StopResult },
		maxHistory: number,
		onStop: ((StopResult) -> ())?,
	},
	StopAnalyzer
))

function StopAnalyzer.new(maxHistory: number?): Analyzer
	return setmetatable({
		active = nil,
		lastWish = vector.create(0, 0, 0),
		lastTime = nil,
		lastSpeed = nil,
		history = {},
		maxHistory = maxHistory or 50,
		onStop = nil,
	}, StopAnalyzer)
end

local function finish(self: Analyzer, timeToZero: number?)
	local a = self.active
	if not a then
		return
	end
	self.active = nil
	local result: StopResult = {
		method = a.method,
		startSpeed = a.startSpeed,
		fromFullSpeed = a.fromFullSpeed,
		timeToAccurate = a.timeToAccurate,
		timeToZero = timeToZero,
		distance = a.distance,
		threshold = a.threshold,
	}
	table.insert(self.history, result)
	if #self.history > self.maxHistory then
		table.remove(self.history, 1)
	end
	if self.onStop then
		self.onStop(result)
	end
end

-- Call once per simulation tick.
--   wishDir: normalised wish direction from MovementSim.wishDirection (or zero)
--   velocity: horizontal velocity in m/s
--   threshold: accuracy threshold speed (maxSpeed * accurateFraction)
--   fullSpeed: the speed a stop must begin at to count as from a full run
function StopAnalyzer.tick(self: Analyzer, time: number, position: vector, velocity: vector, wishDir: vector, threshold: number, fullSpeed: number?)
	local speed = vector.magnitude(vector.create(velocity.x, 0, velocity.z))
	local a = self.active

	if a then
		a.distance += vector.magnitude(vector.create(position.x - a.lastPos.x, 0, position.z - a.lastPos.z))
		a.lastPos = position
		local elapsed = time - a.startTime
		-- Pressing the opposite key mid-stop turns a release into a mixed stop.
		if vector.dot(wishDir, a.startDir) < -0.5 and a.method == "release" then
			a.method = "mixed"
		end
		if a.timeToAccurate == nil and speed <= threshold then
			a.timeToAccurate = elapsed
		end
		if speed <= ZERO_SPEED or vector.dot(velocity, a.startDir) <= 0 then
			-- Stopped, or a held counter-strafe has flipped us the other way.
			finish(self, elapsed)
		elseif vector.dot(wishDir, a.startDir) > 0.5 then
			-- Player started moving the same way again: abandon the measurement.
			self.active = nil
		end
	else
		local moving = speed > threshold
		local velDir = if speed > 1e-4 then vector.create(velocity.x, 0, velocity.z) / speed else vector.create(0, 0, 0)
		local stillPushing = vector.dot(wishDir, velDir) > 0.5
		local wasPushing = vector.dot(self.lastWish, velDir) > 0.5
		if moving and wasPushing and not stillPushing then
			self.active = {
				startTime = self.lastTime or time,
				startSpeed = self.lastSpeed or speed,
				fromFullSpeed = (self.lastSpeed or speed) >= (fullSpeed or 0),
				startDir = velDir,
				method = if vector.dot(wishDir, velDir) < -0.5 then "counter" else "release",
				timeToAccurate = nil,
				distance = 0,
				threshold = threshold,
				lastPos = position,
			}
		end
	end
	self.lastWish = wishDir
	self.lastTime = time
	self.lastSpeed = speed
end

-- Forgets every logged stop, and the one in progress.
function StopAnalyzer.clear(self: Analyzer)
	table.clear(self.history)
	self.active = nil
end

-- Mean of a numeric field over the stops from full speed, filtered by method.
function StopAnalyzer.average(self: Analyzer, method: StopMethod, field: "timeToAccurate" | "timeToZero" | "distance"): (number?, number)
	local sum, n = 0, 0
	for _, r in self.history do
		local v = (r :: any)[field]
		if r.method == method and r.fromFullSpeed and v ~= nil then
			sum += v
			n += 1
		end
	end
	if n == 0 then
		return nil, 0
	end
	return sum / n, n
end

return StopAnalyzer
