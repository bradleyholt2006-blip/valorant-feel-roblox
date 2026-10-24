--!strict
-- Remote instances live in ReplicatedStorage.VFRemotes. The server creates
-- them; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER = "VFRemotes"

local definitions: { [string]: string } = {
	MovementInput = "RemoteEvent", -- client -> server, reliable ordered input batches
	MovementAck = "UnreliableRemoteEvent", -- server -> owner, authoritative state
	MovementSnapshot = "UnreliableRemoteEvent", -- server -> all, character poses
	MovementTuning = "RemoteEvent", -- both ways, live parameter overrides (Studio only)
}

export type Remotes = {
	MovementInput: RemoteEvent,
	MovementAck: UnreliableRemoteEvent,
	MovementSnapshot: UnreliableRemoteEvent,
	MovementTuning: RemoteEvent,
}

local cached: Remotes? = nil

local function get(): Remotes
	if cached then
		return cached
	end
	local folder: Instance
	if RunService:IsServer() then
		folder = ReplicatedStorage:FindFirstChild(FOLDER) or Instance.new("Folder")
		folder.Name = FOLDER
		for name, className in definitions do
			if not folder:FindFirstChild(name) then
				local remote = Instance.new(className)
				remote.Name = name
				remote.Parent = folder
			end
		end
		folder.Parent = ReplicatedStorage
	else
		folder = ReplicatedStorage:WaitForChild(FOLDER)
	end
	local out = {}
	for name in definitions do
		out[name] = folder:WaitForChild(name)
	end
	local remotes = (out :: any) :: Remotes
	cached = remotes
	return remotes
end

return { get = get }
