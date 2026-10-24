--!strict
-- Broadcasts a timestamped, numbered pose snapshot of every entity (players
-- and dummies) once per server frame, so clients can interpolate them.
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

local Entities = require(script.Parent.Entities)

-- Roblox servers step at 60 Hz, so this sends every frame; it only skips
-- frames if a server ever runs much faster than that.
local MIN_SPACING = 0.75 / NetConfig.SNAPSHOT_RATE

local Replication = {}

local lastSent = -math.huge
local seq = 0

-- Listeners get every snapshot as sent (server time + quantised poses).
Replication.listeners = {} :: { (number, { PlayerCodec.Pose }) -> () }

-- Sends the frame's snapshot, stamped with server time `now`.
function Replication.step(now: number)
	if now - lastSent < MIN_SPACING then
		return
	end
	lastSent = now
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
