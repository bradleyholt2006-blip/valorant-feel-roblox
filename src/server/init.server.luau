--!strict
-- Server entry point. Order inside each Heartbeat matters: dummies advance,
-- then player inputs (and their shots) run against those positions, then the
-- frame's poses are broadcast.

local RunService = game:GetService("RunService")

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

RunService.Heartbeat:Connect(function(dt)
	Dummies.step(dt)
	PlayerSimServer.step(dt)
	Replication.step(dt)
end)
