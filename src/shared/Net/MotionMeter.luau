--!strict
-- Measures how evenly something moves on screen, from where it was drawn on
-- each frame: its speed along the ground, and how far any one frame's
-- movement is off the line through the frames either side of it (a jump).
-- Speeding up, slowing down and turning change the velocity a little each
-- frame and hardly count; a frame that moves farther or less than its
-- neighbours, from an uneven pace or a held pose, does.
--
-- Pure (no Roblox APIs): RemoteEntities feeds it every frame for the Hit Reg
-- Lab's motion line, and the offline tests measure with it too.

export type Sample = { at: number, position: vector } -- frame time (s) and where it was drawn (m)

export type Meter = {
	window: number, -- seconds of frames kept
	samples: { Sample },
}

export type Reading = {
	speed: number, -- along the ground on the newest frame, m/s
	low: number, -- the slowest and fastest frame in the window, m/s
	high: number,
	jump: number, -- the most any frame's velocity was off the line through its neighbours, m/s
	frames: number,
}

local MotionMeter = {}

-- Jumps under this look smooth, m/s (measured, ours, in tests/pacing.luau):
-- paced, a run's turns reach 0.36 and a late move 0.41; drawn from the
-- newest pose each server frame, a steady run jumps by 1 to 2.3.
MotionMeter.SMOOTH = 0.5

local TELEPORT = 1 -- metres in one frame: a respawn or a teleport, so the record starts over

function MotionMeter.new(window: number): Meter
	return { window = window, samples = {} }
end

function MotionMeter.clear(m: Meter)
	table.clear(m.samples)
end

-- Records where it was drawn on the frame at time `at`.
function MotionMeter.push(m: Meter, at: number, position: vector)
	local samples = m.samples
	local last = samples[#samples]
	if last and at <= last.at then
		return
	end
	if last and vector.magnitude(position - last.position) > TELEPORT then
		table.clear(samples)
	end
	table.insert(samples, { at = at, position = position })
	local oldest = at - m.window
	while #samples > 1 and samples[1].at < oldest do
		table.remove(samples, 1)
	end
end

-- Each frame's velocity, from the samples either side of it, and the time
-- in the middle of it.
local function velocities(samples: { Sample }): ({ vector }, { number })
	local v, mid = {}, {}
	for i = 2, #samples do
		local a, b = samples[i - 1], samples[i]
		table.insert(v, (b.position - a.position) / (b.at - a.at))
		table.insert(mid, (a.at + b.at) / 2)
	end
	return v, mid
end

local function ground(v: vector): number
	return math.sqrt(v.x * v.x + v.z * v.z)
end

-- How far each frame's velocity is off the line through the frames either
-- side of it, m/s, for every frame but the first and last.
function MotionMeter.jumps(samples: { Sample }): { number }
	local v, mid = velocities(samples)
	local out = {}
	for i = 2, #v - 1 do
		local share = (mid[i] - mid[i - 1]) / (mid[i + 1] - mid[i - 1])
		table.insert(out, vector.magnitude(v[i] - (v[i - 1] + (v[i + 1] - v[i - 1]) * share)))
	end
	return out
end

-- The window's numbers, or nil until it has a few frames.
function MotionMeter.read(m: Meter): Reading?
	local samples = m.samples
	if #samples < 4 then
		return nil
	end
	local v = velocities(samples)
	local low, high = math.huge, 0
	for _, vel in v do
		local s = ground(vel)
		low = math.min(low, s)
		high = math.max(high, s)
	end
	local jump = 0
	for _, j in MotionMeter.jumps(samples) do
		jump = math.max(jump, j)
	end
	return { speed = ground(v[#v]), low = low, high = high, jump = jump, frames = #v }
end

return MotionMeter
