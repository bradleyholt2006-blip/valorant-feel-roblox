--!strict
-- Live parameter overrides. The server owns the resolved movement config and
-- pushes every change to all clients, so prediction and authority always run
-- the same numbers. Only Studio sessions and the place owner may tune.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local Remotes = require(Shared.Net.Remotes)

local Tuning = {}

local overrides: { [string]: number } = {}
local cfg = MovementConfig.resolve()

function Tuning.config(): MovementConfig.Values
	return cfg
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
	elseif (MovementConfig.Params :: any)[key] ~= nil and typeof(value) == "number" and value == value and math.abs(value) < 1e4 then
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
