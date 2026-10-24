--!strict
-- Renders other players by interpolating server snapshots.
--
-- Remote characters are drawn INTERP_DELAY seconds in the past so there are
-- always two snapshots to blend between. That delay is a known, fixed number,
-- which is what server-side lag compensation will rewind by later. Riot
-- describes the same trade-off (7.8125 ms buffering at 128 Hz) in
-- "On Peeker's Advantage"; our snapshot rate is lower, so the delay is larger.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementCodec = require(Shared.Net.MovementCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local CharacterRig = require(Shared.CharacterRig)

local RemotePlayers = {}

RemotePlayers.INTERP_DELAY = 0.05 -- seconds; ~3 snapshots at 60 Hz
local MAX_BUFFER = 32

type Sample = { time: number, pose: MovementCodec.Pose }

local buffers: { [number]: { Sample } } = {}
local localSlot = Players.LocalPlayer.UserId % 2 ^ 32

-- Snapshots carry UserId mod 2^32 (Studio test players have negative ids).
local function playerForSlot(slot: number): Player?
	for _, player in Players:GetPlayers() do
		if player.UserId % 2 ^ 32 == slot then
			return player
		end
	end
	return nil
end

local function onSnapshot(payload: buffer)
	if typeof(payload) ~= "buffer" then
		return
	end
	local serverTime, poses = MovementCodec.decodeSnapshot(payload)
	for _, pose in poses do
		if pose.userId == localSlot then
			continue
		end
		local buf = buffers[pose.userId]
		if not buf then
			buf = {}
			buffers[pose.userId] = buf
		end
		local last = buf[#buf]
		if last and serverTime <= last.time then
			continue
		end
		table.insert(buf, { time = serverTime, pose = pose })
		if #buf > MAX_BUFFER then
			table.remove(buf, 1)
		end
	end
end

local function lerpAngle(a: number, b: number, t: number): number
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * t
end

-- Interpolated pose of a player at a given server time (also used by debug tools).
function RemotePlayers.sample(slot: number, serverTime: number): MovementCodec.Pose?
	local buf = buffers[slot]
	if not buf or #buf == 0 then
		return nil
	end
	if serverTime <= buf[1].time then
		return buf[1].pose
	end
	for i = #buf - 1, 1, -1 do
		local a, b = buf[i], buf[i + 1]
		if serverTime >= a.time then
			local t = math.clamp((serverTime - a.time) / math.max(b.time - a.time, 1e-6), 0, 1)
			return {
				userId = slot,
				position = a.pose.position + (b.pose.position - a.pose.position) * t,
				yaw = lerpAngle(a.pose.yaw, b.pose.yaw, t),
				pitch = a.pose.pitch + (b.pose.pitch - a.pose.pitch) * t,
				crouchAlpha = a.pose.crouchAlpha + (b.pose.crouchAlpha - a.pose.crouchAlpha) * t,
				grounded = b.pose.grounded,
			}
		end
	end
	-- Past the newest snapshot: hold it rather than extrapolate.
	return buf[#buf].pose
end

local function onRender()
	local renderTime = Workspace:GetServerTimeNow() - RemotePlayers.INTERP_DELAY
	for slot in buffers do
		local player = playerForSlot(slot)
		if not player then
			buffers[slot] = nil
			continue
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local pose = RemotePlayers.sample(slot, renderTime)
		if character and root and pose then
			local offset = CharacterRig.rootOffset(character, root)
			root.CFrame = CFrame.new(Units.toStuds(pose.position) + Vector3.new(0, offset, 0)) * CFrame.Angles(0, pose.yaw, 0)
		end
	end
end

function RemotePlayers.start()
	Remotes.get().MovementSnapshot.OnClientEvent:Connect(onSnapshot)
	RunService:BindToRenderStep("VFRemotePlayers", Enum.RenderPriority.Camera.Value + 2, onRender)
end

return RemotePlayers
