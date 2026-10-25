--!strict
-- Remote instances live in ReplicatedStorage.VFRemotes. The server creates
-- them; clients wait for them.
--
-- High-rate traffic (inputs, acks, snapshots) is packed into buffers by
-- PlayerCodec. Low-rate events (shot and swing results, damage, loadout) use
-- tables.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER = "VFRemotes"

local definitions: { [string]: string } = {
	PlayerInput = "RemoteEvent", -- client -> server, reliable ordered input batches
	PlayerAck = "UnreliableRemoteEvent", -- server -> owner, authoritative PlayerSim state
	Snapshot = "UnreliableRemoteEvent", -- server -> all, entity poses
	Tuning = "RemoteEvent", -- both ways, live parameter overrides (Studio / owner only)
	ShotResult = "RemoteEvent", -- server -> shooter, the verdict for each of their shots
	ShotFx = "UnreliableRemoteEvent", -- server -> others, tracers for someone else's shot
	SwingResult = "RemoteEvent", -- server -> attacker, the verdict for each of their knife swings
	SwingFx = "UnreliableRemoteEvent", -- server -> others, someone else's knife swing
	Combat = "RemoteEvent", -- server -> all, damage / death / respawn events
	Loadout = "RemoteEvent", -- client -> server, debug weapon give (Studio / owner only; anyone in the arena's buy phase)
	Buy = "RemoteEvent", -- client -> server, buy or sell an item from the buy menu
	Arena = "RemoteEvent", -- client -> server, turn the arena on or off (Studio / owner only)
	Settings = "RemoteEvent", -- client -> server, the player's settings to keep (sensitivity, crosshair)
	GroundGun = "RemoteEvent", -- client -> server, F: pick up the gun on the ground in view (system 15)
	Ability = "RemoteEvent", -- server -> all, an ability cast, for its sound and look (system 17)
	Vote = "RemoteEvent", -- client -> server, the player's vote for the next map (system 22)
	Play = "RemoteEvent", -- both ways: PLAY for a mode, and how it went (system 24)
	LoadoutPick = "RemoteEvent", -- client -> server, a loadout picked for a stage of Team Deathmatch (system 27)
	AgentPick = "RemoteEvent", -- client -> server, an agent selected or locked in (system 29)
}

export type Remotes = {
	PlayerInput: RemoteEvent,
	PlayerAck: UnreliableRemoteEvent,
	Snapshot: UnreliableRemoteEvent,
	Tuning: RemoteEvent,
	ShotResult: RemoteEvent,
	ShotFx: UnreliableRemoteEvent,
	SwingResult: RemoteEvent,
	SwingFx: UnreliableRemoteEvent,
	Combat: RemoteEvent,
	Loadout: RemoteEvent,
	Buy: RemoteEvent,
	Arena: RemoteEvent,
	Settings: RemoteEvent,
	GroundGun: RemoteEvent,
	Ability: RemoteEvent,
	Vote: RemoteEvent,
	Play: RemoteEvent,
	LoadoutPick: RemoteEvent,
	AgentPick: RemoteEvent,
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
