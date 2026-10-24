--!strict
-- Detects "stops" in a stream of movement ticks and measures them, so our
-- numbers can be compared with frame-counted footage of the reference game.
--
-- A stop starts on the tick the player stops asking to move in their current
-- direction (key released, or opposite key pressed) while moving faster than
-- the accuracy threshold. It is measured until speed is ~zero or the player
-- asks to move again.
--
-- Pure module: used by the in-game Counter-Strafe Lab and by the offline tests.

export type StopMethod = "release" | "counter" | "mixed"

export type StopResult = {
	method: StopMethod,
	startSpeed: number, -- m/s when the stop began
	timeToAccurate: number?, -- s until speed <= threshold (nil if never)
	timeToZero: number?, -- s until speed <= zeroSpeed
	distance: number, -- m travelled after the stop began
	threshold: number, -- m/s accuracy threshold used
}

type Active = {
	startTime: number,
	startSpeed: number,
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
function StopAnalyzer.tick(self: Analyzer, time: number, position: vector, velocity: vector, wishDir: vector, threshold: number)
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
				startTime = time,
				startSpeed = speed,
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
end

-- Mean of a numeric field over the history, filtered by method.
function StopAnalyzer.average(self: Analyzer, method: StopMethod, field: "timeToAccurate" | "timeToZero" | "distance"): (number?, number)
	local sum, n = 0, 0
	for _, r in self.history do
		local v = (r :: any)[field]
		if r.method == method and v ~= nil then
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
