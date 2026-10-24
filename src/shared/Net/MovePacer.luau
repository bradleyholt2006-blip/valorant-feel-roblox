--!strict
-- Paces an entity's simulation ticks onto a steady timeline for the
-- snapshots.
--
-- The server runs a player's moves when they arrive, a bunch at a time: a
-- client at 60 fps sends two or three 128 Hz moves a frame, and each 60 Hz
-- server frame runs whatever has come in since the last. Sending each frame's
-- newest pose made other players lurch, drawn at anything from 2.5 to 7.6 m/s
-- while running at a steady 5.4 in the offline tests (3 to 8 in Studio).
-- Practice dummies tick at 128 Hz inside 60 Hz frames, so they did the same
-- in a regular beat. Riot's server avoids it by running every client's moves
-- on its own steady tick: "When the server starts receiving data from a
-- client, it establishes a basis between that client's timeline and its own"
-- ("Peeking into VALORANT's Netcode"). Ours still runs moves the moment they
-- arrive, so no one's movement or shots wait for it, and paces only what the
-- snapshots show:
--
--   * After each tick, the entity's pose is kept at that tick's time on its
--     own timeline: a player's move number over the tick rate, or for a
--     dummy, the server time of its tick.
--   * Every server frame notes how far the newest tick is from the server's
--     time. On all but 1% of the last couple of seconds' frames the tick had
--     arrived by the low end of that, so the snapshot shows the entity at
--     server time plus that low end, less 2 ms: the ticks either side have
--     almost always run, and the pose is a blend of them.
--   * The time shown follows the server's clock and eases toward that
--     target, closing most of a gap in a tenth of a second and running at
--     most 10% fast or slow, so a change in timing slows or speeds the
--     entity a touch instead of making it jump. It never passes the newest
--     tick: when a move is late the entity waits for it, then catches up
--     the same gentle way, and it never goes back.
--
-- The cost is a few milliseconds more before everyone else sees a player
-- move (6 to 12 ms offline), and about 6 ms for a dummy. Clients and lag
-- compensation both use the snapshots, so hit registration still checks
-- exactly what the shooter saw.
--
-- Pure (no Roblox APIs): the server uses it, the offline tests drive it.

local NetConfig = require("./NetConfig")
local PlayerCodec = require("./PlayerCodec")
local PoseHistory = require("./PoseHistory")

export type Pacer = {
	history: PoseHistory.History, -- the pose after each tick, at the tick's time
	frames: { { at: number, offset: number } }, -- recent server frames: time, and the newest tick's time minus it
	time: number?, -- the tick time shown last frame, nil until the first
	lastAt: number, -- server time of the last frame
	stats: { frames: number, held: number, lag: number },
}

local MovePacer = {}

local CAPACITY = 128 -- ticks kept: a second of them
local SNAP = 0.25 -- seconds off target before the time shown jumps instead of easing

function MovePacer.new(): Pacer
	return {
		history = PoseHistory.new(CAPACITY),
		frames = {},
		time = nil,
		lastAt = 0,
		-- held: frames that showed the newest tick because the next hadn't
		-- run; lag: how far the time shown was behind the newest tick, last frame
		stats = { frames = 0, held = 0, lag = 0 },
	}
end

-- Forgets the ticks and the timing: the entity respawned or was moved.
function MovePacer.reset(p: Pacer)
	table.clear(p.history.samples)
	table.clear(p.frames)
	p.time = nil
end

-- Keeps the pose an entity has after a tick, at the tick's time.
function MovePacer.push(p: Pacer, time: number, pose: PlayerCodec.Pose)
	PoseHistory.push(p.history, time, pose)
end

-- Moves to server time `now`, once per server frame after its ticks have
-- run, and returns the pose to replicate (nil before the first tick).
function MovePacer.advance(p: Pacer, now: number): PlayerCodec.Pose?
	local newest = PoseHistory.newest(p.history)
	if not newest then
		return nil
	end
	local cfg = NetConfig.Pacing
	local frames = p.frames
	table.insert(frames, { at = now, offset = newest.time - now })
	local oldest = now - cfg.window.value
	while #frames > 1 and frames[1].at < oldest do
		table.remove(frames, 1)
	end
	local offsets = table.create(#frames)
	for i, f in frames do
		offsets[i] = f.offset
	end
	table.sort(offsets)
	local k = math.clamp(math.floor(#offsets * (1 - cfg.percentile.value)) + 1, 1, #offsets)
	local target = now + offsets[k] - cfg.margin.value

	local t = p.time
	local nextTime
	if t == nil then
		nextTime = target
	else
		local dt = math.max(now - p.lastAt, 0)
		local free = t + dt
		local err = target - free
		if math.abs(err) > SNAP then
			nextTime = target
		else
			-- Close the gap gradually: the target wobbles a little from frame to
			-- frame, and following each wobble at once shows as speed changes.
			local share = 1 - math.exp(-dt / cfg.settle.value)
			local step = dt * cfg.maxRate.value
			nextTime = free + math.clamp(err * share, -step, step)
		end
		nextTime = math.max(nextTime, t)
	end
	local stats = p.stats
	stats.frames += 1
	if nextTime > newest.time then
		nextTime = newest.time
		stats.held += 1
	end
	stats.lag = newest.time - nextTime
	p.time = nextTime
	p.lastAt = now
	return (PoseHistory.sample(p.history, nextTime) :: PoseHistory.Lookup).pose
end

return MovePacer
