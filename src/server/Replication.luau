--!strict
-- Broadcasts a timestamped, numbered pose snapshot of every entity (players
-- and dummies) once per server frame at 60 Hz (SendSchedule keeps a faster
-- server, like Studio's, to 60 a second), so clients can interpolate them.
--
-- Poses are quantised exactly as the wire does before anything sees them,
-- and listeners (lag compensation) get each snapshot as sent, so the
-- server's history holds exactly what clients draw. Players and dummies give
-- their paced poses (MovePacer), so they move evenly from one snapshot to
-- the next.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerCodec = require(Shared.Net.PlayerCodec)
local NetConfig = require(Shared.Net.NetConfig)
local Remotes = require(Shared.Net.Remotes)
local SendSchedule = require(Shared.Net.SendSchedule)

local Entities = require(script.Parent.Entities)

local Replication = {}

local schedule = SendSchedule.new()
local lastFrame: number? = nil
local seq = 0

-- Listeners get every snapshot as sent (server time + quantised poses).
Replication.listeners = {} :: { (number, { PlayerCodec.Pose }) -> () }

-- Sends the frame's snapshot, stamped with server time `now`.
function Replication.step(now: number)
	local dt = if lastFrame then now - lastFrame else 1 / NetConfig.SNAPSHOT_RATE
	lastFrame = now
	if not SendSchedule.step(schedule, dt, NetConfig.SNAPSHOT_RATE) then
		return
	end
	seq = (seq + 1) % 65536
	local poses = Entities.poses()
	local quantized = table.create(#poses)
	for i, pose in poses do
		quantized[i] = PlayerCodec.quantizePose(pose)
	end
	for _, listener in Replication.listeners do
		listener(now, quantized)
	end
	local remote = Remotes.get().Snapshot
	local chunk = PlayerCodec.MAX_POSES_PER_SNAPSHOT
	for first = 1, math.max(#quantized, 1), chunk do
		local slice = table.move(quantized, first, math.min(first + chunk - 1, #quantized), 1, {})
		remote:FireAllClients(PlayerCodec.encodeSnapshot(now, slice, seq))
	end
end

return Replication
