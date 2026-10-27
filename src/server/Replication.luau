--!strict
-- Sends a timestamped, numbered pose snapshot of the entities (players and
-- dummies) once per server frame at 60 Hz (SendSchedule keeps a faster
-- server, like Studio's, to 60 a second), so clients can interpolate them.
-- Each player gets the poses their fog of war lets through (FogServer,
-- system 35): an enemy they can't see or hear isn't in theirs. Players with
-- the same set get the same packets, encoded once; everyone gets a packet
-- each frame, empty or not, so their clocks and counts run on.
--
-- Poses are quantised exactly as the wire does before anything sees them,
-- and listeners (lag compensation) get each snapshot with every pose in it,
-- so the server's history holds exactly what clients draw, and a shot at
-- someone a shooter can't see is still checked against where they were.
-- Players and dummies give their paced poses (MovePacer), so they move
-- evenly from one snapshot to the next, and so do Sova's Owl Drones (system
-- 47), which are no entity's (Replication.extras).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerCodec = require(Shared.Net.PlayerCodec)
local NetConfig = require(Shared.Net.NetConfig)
local Remotes = require(Shared.Net.Remotes)
local SendSchedule = require(Shared.Net.SendSchedule)

local Entities = require(script.Parent.Entities)
local FogServer = require(script.Parent.FogServer)

local Replication = {}

local schedule = SendSchedule.new()
local lastFrame: number? = nil
local seq = 0

-- Listeners get every snapshot as sent (server time + quantised poses).
Replication.listeners = {} :: { (number, { PlayerCodec.Pose }) -> () }
-- What else each snapshot carries, as poses: Sova's Owl Drones (system 47,
-- DroneServer).
Replication.extras = {} :: { () -> { PlayerCodec.Pose } }

-- A snapshot's packets: its poses a chunk at a time, at least one.
local function encode(now: number, poses: { PlayerCodec.Pose }): { buffer }
	local out = {}
	local chunk = PlayerCodec.MAX_POSES_PER_SNAPSHOT
	for first = 1, math.max(#poses, 1), chunk do
		local slice = table.move(poses, first, math.min(first + chunk - 1, #poses), 1, {})
		table.insert(out, PlayerCodec.encodeSnapshot(now, slice, seq))
	end
	return out
end

-- Sends the frame's snapshot, stamped with server time `now`.
function Replication.step(now: number)
	local dt = if lastFrame then now - lastFrame else 1 / NetConfig.SNAPSHOT_RATE
	lastFrame = now
	if not SendSchedule.step(schedule, dt, NetConfig.SNAPSHOT_RATE) then
		return
	end
	seq = (seq + 1) % 65536
	local poses = Entities.poses()
	for _, extra in Replication.extras do
		for _, pose in extra() do
			table.insert(poses, pose)
		end
	end
	local quantized = table.create(#poses)
	for i, pose in poses do
		quantized[i] = PlayerCodec.quantizePose(pose)
	end
	for _, listener in Replication.listeners do
		listener(now, quantized)
	end
	local remote = Remotes.get().Snapshot
	-- The packets made this frame, by the ids in them ("*" for all).
	local made: { [string]: { buffer } } = {}
	for _, player in Players:GetPlayers() do
		local sends = FogServer.sendsTo(player)
		local theirs = quantized
		local key = "*"
		if sends then
			theirs = {}
			local ids = {}
			for _, pose in quantized do
				if sends(pose.id) then
					table.insert(theirs, pose)
					table.insert(ids, pose.id)
				end
			end
			key = table.concat(ids, ",")
		end
		local packets = made[key]
		if not packets then
			packets = encode(now, theirs)
			made[key] = packets
		end
		for _, packet in packets do
			remote:FireClient(player, packet)
		end
	end
end

return Replication
