--!strict
-- Hit registration and interpolation numbers. Same status convention as
-- MovementConfig:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki or community measurement
--   "estimate"  - ours; to be measured and tuned (docs/research/04-hit-registration.md)
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local NetConfig = {}

-- Lag compensation -------------------------------------------------------------

-- How far back the server will rewind targets to check a shot. A shot that
-- saw an older world is checked against the world this long ago instead.
NetConfig.maxRewind = p(0.140, "confirmed", "Patch 6.02 (Feb 2023): 'Adjusted max server rewind limit down to 140 ms from 200 ms'")

-- Interpolation ----------------------------------------------------------------

-- Snapshots go out once per server frame. Roblox servers step at 60 Hz, so
-- that is our rate; the reference sends at its 128 Hz tick.
NetConfig.SNAPSHOT_RATE = 60

-- The render clock (InterpClock) draws remote entities a little behind the
-- newest snapshot: far enough that the next snapshot has almost always
-- arrived, measured from recent arrivals.
NetConfig.Interp = {
	window = p(2, "estimate", "Seconds of snapshot arrivals the delay is measured over"),
	percentile = p(
		0.98,
		"estimate",
		"Share of recent snapshots that must have arrived in time; the rest show as a held pose (Riot accepts 'player pops' from packet loss at its minimum buffering)"
	),
	margin = p(0.002, "estimate", "Seconds added on top of the measured delay"),
	settle = p(0.1, "estimate", "Seconds the render clock takes to close 63% of a gap to its target (it eases exponentially)"),
	maxRate = p(0.1, "estimate", "How much faster or slower than real time the render clock may run while it adjusts (10%)"),
}

-- The reference's Network Buffering setting: 1, 3 or 5 frames of 128 Hz
-- interpolation delay. Ours adds the same extra time on top of our minimum.
export type Buffering = { name: string, extra: number, reference: number }
NetConfig.Buffering = {
	{ name = "Minimum", extra = 0, reference = 0.0078125 },
	{ name = "Moderate", extra = 0.015625, reference = 0.0234375 },
	{ name = "Maximum", extra = 0.03125, reference = 0.0390625 },
} :: { Buffering }
NetConfig.bufferingSource = "RiotStealthyJesus, r/VALORANT (2020): 'Minimum' is 1 frame of delay (7.8125ms), 'Moderate' 3 frames (23.4375ms), 'Maximum' 5 frames (39.0625ms)"

-- Pacing -------------------------------------------------------------------------

-- The server shows each player's and dummy's ticks on a steady timeline in
-- the snapshots (MovePacer), a little behind the newest tick: far enough
-- that the next tick has almost always run, measured per entity.
NetConfig.Pacing = {
	window = p(2, "estimate", "Seconds of server frames the delay is measured over"),
	percentile = p(0.99, "estimate", "Share of recent server frames that must already have run the tick shown"),
	margin = p(0.002, "estimate", "Seconds added on top of the measured delay"),
	settle = p(0.1, "estimate", "Seconds the time shown takes to close 63% of a gap to its target (it eases exponentially)"),
	maxRate = p(0.1, "estimate", "How much faster or slower than real time the time shown may run while it adjusts (10%)"),
}
NetConfig.pacingSource = "Peeking into VALORANT's Netcode (Riot): the server 'establishes a basis between that client's timeline and its own' and adjusts it 'to maintain a healthy queue of upcoming moves to execute', targeting 'an average of half a frame of movement data on servers'"

-- Reference values the Hit Reg Lab compares against -------------------------------

NetConfig.Reference = {
	maxRewindAtLaunch = p(0.200, "confirmed", "Patch 6.02: the max rewind 'was set to 200 ms' before it"),
	interpDelay = p(0.0078125, "confirmed", "On Peeker's Advantage & Ranked (May 2020): 'NETWORK INTERP DELAY = 7.8125ms'"),
	serverFrame = p(0.0078125, "confirmed", "On Peeker's Advantage & Ranked: 'SERVER FRAMERATE = 7.8125ms (1/128th of a second, 128-tick servers)'"),
	peekersAdvantageLow = p(0.040, "confirmed", "On Peeker's Advantage & Ranked: 'an average of 40-70ms'"),
	peekersAdvantageHigh = p(0.070, "confirmed", "On Peeker's Advantage & Ranked: 'an average of 40-70ms'"),
	processingOverRtt = p(
		0.025,
		"confirmed",
		"Gameplay Consistency Update 2 (May 2022): 'Network RTT + Processing Delays' 'should be roughly 20-30ms higher than your Network RTT'"
	),
}

return NetConfig
