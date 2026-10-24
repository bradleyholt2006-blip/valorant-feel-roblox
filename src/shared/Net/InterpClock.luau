--!strict
-- The clock remote entities are drawn by.
--
-- Every snapshot is stamped with the server time it was sent. The client
-- draws other entities at a time a little behind the newest snapshot it has,
-- so there are almost always two snapshots to blend between, and sends that
-- time with every input (viewTime) so lag compensation can rewind the server
-- to exactly that view. The reference buffers one 128 Hz frame (7.8125 ms);
-- our snapshots come at Roblox's 60 Hz and arrive with some jitter, so the
-- delay is measured instead of fixed:
--
--   * Each arrival gives an offset: snapshot time minus local arrival time.
--     The highest offset in the last couple of seconds belongs to the
--     snapshot that came quickest, so local time plus that offset is where
--     the stream is when nothing is late.
--   * Each snapshot is needed from the moment the one sent before it is
--     drawn. How far behind the stream that moment must be for it to have
--     arrived is its lateness plus one send interval. The delay is a high
--     percentile of those, plus a margin, plus the player's Network Buffering
--     setting. A lost snapshot doesn't raise the delay: like the reference at
--     its minimum buffering, the entity holds its pose for an interval
--     instead ("player pops" with packet loss, as Riot puts it).
--   * The render time eases toward (local time + offset - delay), running at
--     most 10% fast or slow, so changes in latency never make remote players
--     jump or move backwards.
--
-- The clock never reads the client's estimate of the server's time: it only
-- follows the snapshots, so what it says is what the screen shows.

local NetConfig = require("./NetConfig")

export type Arrival = { time: number, at: number, seq: number? } -- snapshot time, local arrival time, sequence number

export type Clock = {
	extra: number, -- Network Buffering setting, seconds
	arrivals: { Arrival }, -- in-order arrivals within the window, oldest first
	newest: number, -- newest snapshot time received
	offset: number, -- local time + offset = the stream's time when nothing is late
	delay: number, -- how far behind the stream entities are drawn
	time: number?, -- the render time, nil before the first snapshot
	lastLocal: number,
	frames: number,
	starved: number, -- frames drawn past the newest snapshot (poses held)
}

local InterpClock = {}

local DEFAULT_DELAY = 2 / NetConfig.SNAPSHOT_RATE -- until three snapshots have arrived
local SNAP_ERROR = 0.25 -- seconds off target before the clock jumps instead of easing

function InterpClock.new(extra: number?): Clock
	return {
		extra = extra or 0,
		arrivals = {},
		newest = -math.huge,
		offset = 0,
		delay = DEFAULT_DELAY + (extra or 0),
		time = nil,
		lastLocal = 0,
		frames = 0,
		starved = 0,
	}
end

local function measure(c: Clock)
	local arrivals = c.arrivals
	local offset = -math.huge
	for _, a in arrivals do
		offset = math.max(offset, a.time - a.at)
	end
	c.offset = offset
	if #arrivals < 3 then
		c.delay = DEFAULT_DELAY + c.extra
		return
	end
	local needs = table.create(#arrivals - 1)
	for i = 2, #arrivals do
		local a, b = arrivals[i - 1], arrivals[i]
		-- Snapshots lost in between don't count as a longer interval.
		local sent = if a.seq and b.seq then math.max((b.seq - a.seq) % 65536, 1) else 1
		table.insert(needs, (offset - (b.time - b.at)) + (b.time - a.time) / sent)
	end
	table.sort(needs)
	local k = math.clamp(math.ceil(#needs * NetConfig.Interp.percentile.value), 1, #needs)
	c.delay = needs[k] + NetConfig.Interp.margin.value + c.extra
end

-- Call for every snapshot packet with the local time it arrived and its
-- sequence number. Repeats (one snapshot split over several packets) and
-- late out-of-order packets don't count.
function InterpClock.onSnapshot(c: Clock, time: number, at: number, seq: number?)
	if time <= c.newest then
		return
	end
	c.newest = time
	local arrivals = c.arrivals
	table.insert(arrivals, { time = time, at = at, seq = seq })
	local oldest = at - NetConfig.Interp.window.value
	while #arrivals > 3 and arrivals[1].at < oldest do
		table.remove(arrivals, 1)
	end
	measure(c)
end

function InterpClock.setExtra(c: Clock, extra: number)
	c.extra = extra
	measure(c)
end

-- Moves the clock to local time `now` (once per frame) and returns the time
-- to draw remote entities at, or nil before the first snapshot.
function InterpClock.advance(c: Clock, now: number): number?
	if c.newest == -math.huge then
		return nil
	end
	local target = now + c.offset - c.delay
	local t = c.time
	local nextTime
	if t == nil then
		nextTime = target
	else
		local dt = math.max(now - c.lastLocal, 0)
		local free = t + dt
		local err = target - free
		if math.abs(err) > SNAP_ERROR then
			nextTime = target
		else
			local step = dt * NetConfig.Interp.maxRate.value
			nextTime = free + math.clamp(err, -step, step)
		end
	end
	c.time = nextTime
	c.lastLocal = now
	c.frames += 1
	if nextTime > c.newest then
		c.starved += 1
	end
	return nextTime
end

-- How far behind the newest snapshot the last frame was drawn (negative
-- when it ran past it).
function InterpClock.buffer(c: Clock): number
	local t = c.time
	return if t then c.newest - t else 0
end

return InterpClock
