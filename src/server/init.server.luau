--!strict
-- Server entry point. Order inside each Heartbeat matters: dummies advance,
-- then player inputs run (their shots rewind targets through the snapshots
-- sent so far), then the frame's snapshot goes out and joins that history.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RobloxLevel = require(ReplicatedStorage:WaitForChild("Shared").Combat.RobloxLevel)

local TestRange = require(script.TestRange)
local Tuning = require(script.Tuning)
local PlayerSimServer = require(script.PlayerSimServer)
local CombatServer = require(script.CombatServer)
local Dummies = require(script.Dummies)
local Replication = require(script.Replication)

TestRange.buildIfMissing()
Tuning.start()
PlayerSimServer.start(CombatServer.onShot)
Dummies.start()
table.insert(Replication.listeners, CombatServer.record)

RunService.Heartbeat:Connect(function(dt)
	Dummies.step(dt)
	PlayerSimServer.step(dt)
	Replication.step()
end)

-- Checks wall penetration measures parts of known size (Output window).
task.spawn(function()
	local ok, report = RobloxLevel.selfTest()
	if ok then
		print("[VF] " .. report)
	else
		warn("[VF] " .. report)
	end
end)
