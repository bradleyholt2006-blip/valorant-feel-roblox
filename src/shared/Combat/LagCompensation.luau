--!strict
-- Lag compensation: the server checks a shot against the targets as the
-- shooter saw them.
--
-- The server records every snapshot it sends (the quantised poses, stamped
-- with the send time). Each shot comes with the viewTime of the input that
-- fired it, the snapshot time the shooter's screen was showing (InterpClock).
-- The server rebuilds every target at that time from the same snapshots with
-- the same interpolation (PoseHistory), so for a shooter who received those
-- snapshots the boxes are identical to the ones they aimed at. Riot: "Hit
-- registration in VALORANT works by saving player positions and animation
-- state in a historical buffer. When the server receives a shot packet from
-- the client, it rewinds the player positions and animation state using the
-- historical buffer".
--
-- How far back the server goes is capped (NetConfig.maxRewind, 140 ms since
-- Patch 6.02). A shot that saw an older world is checked against the world at
-- the cap instead, so a very high ping shooter starts to miss moving targets
-- rather than hitting players who have already reached cover.
--
-- Pure (no Roblox APIs): the server wires it up, the offline tests drive it
-- through a simulated network.

local PlayerCodec = require("../Net/PlayerCodec")
local PoseHistory = require("../Net/PoseHistory")
local ShotResolver = require("./ShotResolver")

export type Rewind = {
	requested: number, -- the viewTime the shot came with
	time: number, -- the time targets are rebuilt at
	amount: number, -- seconds before now
	clamped: boolean, -- the cap (or a viewTime from the future) moved it
}

export type Target = {
	id: number,
	pose: PlayerCodec.Pose,
	from: number, -- snapshot times blended (PoseHistory.Lookup)
	to: number,
	held: boolean,
}

export type State = {
	histories: { [number]: PoseHistory.History },
	lastSeen: { [number]: number },
}

local LagCompensation = {}

local CAPACITY = 64 -- snapshots kept per entity, about a second at 60 Hz
local FORGET_AFTER = 1 -- seconds missing from snapshots before an entity's history goes

function LagCompensation.new(): State
	return { histories = {}, lastSeen = {} }
end

-- Records a snapshot as it is sent.
function LagCompensation.record(state: State, time: number, poses: { PlayerCodec.Pose })
	for _, pose in poses do
		local h = state.histories[pose.id]
		if not h then
			h = PoseHistory.new(CAPACITY)
			state.histories[pose.id] = h
		end
		PoseHistory.push(h, time, pose)
		state.lastSeen[pose.id] = time
	end
	for id, seen in state.lastSeen do
		if time - seen > FORGET_AFTER then
			state.histories[id] = nil
			state.lastSeen[id] = nil
		end
	end
end

-- The time a shot that came with `viewTime` is checked at, when the server
-- processes it at `now`: no earlier than the cap, and never in the future.
function LagCompensation.rewindTime(viewTime: number, now: number, maxRewind: number): Rewind
	local time = math.clamp(viewTime, now - maxRewind, now)
	return { requested = viewTime, time = time, amount = now - time, clamped = time ~= viewTime }
end

-- Every recorded entity that `include` accepts, posed at `time`.
function LagCompensation.targets(state: State, time: number, include: (id: number) -> boolean): { Target }
	local out: { Target } = {}
	for id, h in state.histories do
		if include(id) then
			local lookup = PoseHistory.sample(h, time)
			if lookup then
				table.insert(out, { id = id, pose = lookup.pose, from = lookup.from, to = lookup.to, held = lookup.held })
			end
		end
	end
	return out
end

-- The same targets in the form ShotResolver takes.
function LagCompensation.shotTargets(targets: { Target }): { ShotResolver.Target }
	local out: { ShotResolver.Target } = table.create(#targets)
	for i, t in targets do
		out[i] = { id = t.id, pose = { position = t.pose.position, yaw = t.pose.yaw, crouchAlpha = t.pose.crouchAlpha } }
	end
	return out
end

return LagCompensation
