--!strict
-- Live parameter overrides. The server owns the resolved movement config and
-- pushes every change to all clients, so prediction and authority always run
-- the same numbers. Only Studio sessions and the place owner may tune.
--
-- Besides movement parameters, the lag compensation cap (maxRewind, seconds)
-- can be tuned; only the server uses it, clients show it in the Hit Reg Lab.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local NetConfig = require(Shared.Net.NetConfig)
local Remotes = require(Shared.Net.Remotes)

local Tuning = {}

local overrides: { [string]: number } = {}
local cfg = MovementConfig.resolve()

function Tuning.config(): MovementConfig.Values
	return cfg
end

function Tuning.maxRewind(): number
	return overrides.maxRewind or NetConfig.maxRewind.value
end

local function accepts(key: string, value: number): boolean
	if key == "maxRewind" then
		return value >= 0 and value <= 1
	end
	return (MovementConfig.Params :: any)[key] ~= nil and math.abs(value) < 1e4
end

function Tuning.canTune(player: Player): boolean
	return RunService:IsStudio() or (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId)
end

local function onTuning(player: Player, key: any, value: any)
	if not Tuning.canTune(player) or typeof(key) ~= "string" then
		return
	end
	if key == "__reset" then
		table.clear(overrides)
	elseif typeof(value) == "number" and value == value and accepts(key, value) then
		overrides[key] = value
	else
		return
	end
	cfg = MovementConfig.resolve(overrides)
	Remotes.get().Tuning:FireAllClients(overrides)
	print(string.format("[Tuning] %s set %s = %s", player.Name, key, tostring(value)))
end

function Tuning.start()
	local remotes = Remotes.get()
	remotes.Tuning.OnServerEvent:Connect(onTuning)
	Players.PlayerAdded:Connect(function(player)
		remotes.Tuning:FireClient(player, overrides)
	end)
	for _, player in Players:GetPlayers() do
		remotes.Tuning:FireClient(player, overrides)
	end
end

return Tuning
