--!strict
-- Server entry point. Order inside each Heartbeat matters: dummies advance,
-- then player inputs run (their shots and knife swings rewind targets through
-- the snapshots sent so far), then the frame's snapshot goes out and joins
-- that history.
-- All three work to the same server time, the one the snapshot carries.
-- The spike moves on after the moves that planted, defused or picked it up,
-- so its blast is in the frame's snapshot; the guns on the ground after the
-- moves that walked over them.
-- Ability kits refill on the course after the moves that cast from them, and
-- thrown clouds whose thrower is dead fly on.
-- Regen Shields refill after the shots. The arena's rounds move on last, so
-- a round that ends in this frame's shots respawns its players after the
-- frame's snapshot, and agent select after them, as the rounds have it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RobloxLevel = require(ReplicatedStorage:WaitForChild("Shared").Combat.RobloxLevel)

local TestRange = require(script.TestRange)
local Arena = require(script.Arena)
local Tuning = require(script.Tuning)
local PlayerSimServer = require(script.PlayerSimServer)
local CombatServer = require(script.CombatServer)
local Dummies = require(script.Dummies)
local Replication = require(script.Replication)
local ShopServer = require(script.ShopServer)
local SettingsServer = require(script.SettingsServer)
local SpikeServer = require(script.SpikeServer)
local GroundGunsServer = require(script.GroundGunsServer)
local AbilityServer = require(script.AbilityServer)
local AgentServer = require(script.AgentServer)
local CloudServer = require(script.CloudServer)
local PickupsServer = require(script.PickupsServer)
local ModeServers = require(script.ModeServers)

TestRange.buildIfMissing()
Arena.buildIfMissing()
Tuning.start()
PlayerSimServer.start(CombatServer.onVolley, CombatServer.onSwing)
ShopServer.start()
AbilityServer.start()
AgentServer.start()
CloudServer.start()
GroundGunsServer.start()
PickupsServer.start()
SettingsServer.start()
Dummies.start()
-- Before the arena starts, so whoever joins starts in the Play menu where
-- they should (system 24).
ModeServers.start()
Arena.start()
SpikeServer.start()
table.insert(Replication.listeners, CombatServer.record)

RunService.Heartbeat:Connect(function(dt)
	local now = Workspace:GetServerTimeNow()
	Dummies.step(now)
	PlayerSimServer.step(dt, now)
	SpikeServer.step(now)
	AbilityServer.step(now)
	CloudServer.step(now)
	GroundGunsServer.step()
	CombatServer.step(now, dt)
	Replication.step(now)
	Arena.step(now)
	AgentServer.step(now)
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
