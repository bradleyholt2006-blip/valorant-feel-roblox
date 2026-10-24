--!strict
-- Broadcasts timestamped pose snapshots of every entity (players and dummies)
-- so clients can interpolate them at a fixed delay.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)

local Entities = require(script.Parent.Entities)

local SNAPSHOT_RATE = 60

local Replication = {}

local accumulator = 0

-- Listeners get every snapshot as sent (server time + quantised poses).
Replication.listeners = {} :: { (number, { PlayerCodec.Pose }) -> () }

function Replication.step(dt: number)
	accumulator += dt
	if accumulator < 1 / SNAPSHOT_RATE then
		return
	end
	accumulator = 0
	local now = Workspace:GetServerTimeNow()
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
		remote:FireAllClients(PlayerCodec.encodeSnapshot(now, slice))
	end
end

return Replication
