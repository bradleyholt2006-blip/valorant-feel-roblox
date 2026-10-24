--!strict
-- Server entry point. Order inside each Heartbeat matters: dummies advance,
-- then player inputs run (their shots rewind targets through the snapshots
-- sent so far), then the frame's snapshot goes out and joins that history.
-- All three work to the same server time, the one the snapshot carries.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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
	local now = Workspace:GetServerTimeNow()
	Dummies.step(now)
	PlayerSimServer.step(dt, now)
	Replication.step(now)
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
