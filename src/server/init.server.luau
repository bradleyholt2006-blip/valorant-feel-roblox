--!strict
-- Server entry point. Order inside each Heartbeat matters: dummies advance,
-- and bots play (system 60), then player inputs run (their shots and knife
-- swings, and the bots', rewind targets through the snapshots sent so far),
-- then the frame's snapshot goes out and joins that history.
-- All three work to the same server time, the one the snapshot carries.
-- The spike moves on after the moves that planted, defused or picked it up,
-- so its blast is in the frame's snapshot; the guns on the ground after the
-- moves that walked over them.
-- Ability kits refill on the course after the moves that cast from them, a
-- Phoenix whose body's been gone too long in Run it Back is back in play, and
-- so is an Omen gone too long in his Shrouded Step, thrown clouds whose thrower
-- is dead fly on, flares pop, blinding whoever the moves left looking at them,
-- walls of fire whose caster is dead run on, fires burn whoever the moves left
-- standing in them, the Healing Orb's heals give what they've come to, after
-- the fires' burns that pause them, the Slow Orb's fields say whom the moves
-- left slowed, Paranoia's orbs touch whoever the moves left in their way,
-- the Recon Bolt's pulses reveal whoever the moves left in their sight,
-- Shock Bolts burst on whoever the moves left near them, and the Owl
-- Drones the moves flew are paced and looked at and their darts' pings
-- reveal whom they struck, before the minimap's spotting goes by what they
-- see and what they reveal, and by whom Hunter's Fury's blasts revealed as
-- the moves sent them.
-- Regen Shields refill after the shots, and the minimap's spotting looks
-- after them, so nobody they killed is seen; the fog of war's looks come
-- after that, with what each side spots, and each player's snapshot goes
-- by them. The arena's rounds move on last, so a round that ends in this
-- frame's shots respawns its players after the frame's snapshot, and agent
-- select after them, as the rounds have it, and the AFK clocks after the
-- rounds, by the phase they leave. The combat reports that changed in the
-- frame go out at its end.

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
local BotServer = require(script.BotServer)
local Replication = require(script.Replication)
local ShopServer = require(script.ShopServer)
local SettingsServer = require(script.SettingsServer)
local CareerServer = require(script.CareerServer)
local SpikeServer = require(script.SpikeServer)
local GroundGunsServer = require(script.GroundGunsServer)
local AbilityServer = require(script.AbilityServer)
local AgentServer = require(script.AgentServer)
local AfkServer = require(script.AfkServer)
local CloudServer = require(script.CloudServer)
local FlareServer = require(script.FlareServer)
local FireServer = require(script.FireServer)
local HealServer = require(script.HealServer)
local SlowServer = require(script.SlowServer)
local BarrierServer = require(script.BarrierServer)
local ReviveServer = require(script.ReviveServer)
local ParanoiaServer = require(script.ParanoiaServer)
local ReconServer = require(script.ReconServer)
local ShockServer = require(script.ShockServer)
local FuryServer = require(script.FuryServer)
local DroneServer = require(script.DroneServer)
local BlazeServer = require(script.BlazeServer)
local RunItBackServer = require(script.RunItBackServer)
local StepServer = require(script.StepServer)
local ShadowServer = require(script.ShadowServer)
local MinimapServer = require(script.MinimapServer)
local FogServer = require(script.FogServer)
local PickupsServer = require(script.PickupsServer)
local OrbServer = require(script.OrbServer)
local PingServer = require(script.PingServer)
local ReportServer = require(script.ReportServer)
local BannerServer = require(script.BannerServer)
local CalloutServer = require(script.CalloutServer)
local ModeServers = require(script.ModeServers)
local TrainingServer = require(script.TrainingServer)
local MapDresser = require(script.MapDresser)

TestRange.buildIfMissing()
Arena.buildIfMissing()
MapDresser.watch()
Tuning.start()
PlayerSimServer.start(CombatServer.onVolley, CombatServer.onSwing)
ShopServer.start()
AbilityServer.start()
AgentServer.start()
AfkServer.start()
CloudServer.start()
FlareServer.start()
FireServer.start()
HealServer.start()
SlowServer.start()
BarrierServer.start()
-- After the Barrier Orb's, whose walls stand in the level shots are traced
-- through before the Recon Bolt's shafts.
ReconServer.start()
ShockServer.start()
FuryServer.start()
DroneServer.start()
ReviveServer.start()
ParanoiaServer.start()
BlazeServer.start()
RunItBackServer.start()
StepServer.start()
ShadowServer.start()
MinimapServer.start()
FogServer.start()
GroundGunsServer.start()
PickupsServer.start()
OrbServer.start()
PingServer.start()
ReportServer.start()
BannerServer.start()
CalloutServer.start()
SettingsServer.start()
CareerServer.start()
Dummies.start()
BotServer.start()
TrainingServer.start()
-- Before the arena starts, so whoever joins starts in the Play menu where
-- they should (system 24).
ModeServers.start()
Arena.start()
SpikeServer.start()
table.insert(Replication.listeners, CombatServer.record)

RunService.Heartbeat:Connect(function(dt)
	local now = Workspace:GetServerTimeNow()
	Dummies.step(now)
	BotServer.step(now)
	PlayerSimServer.step(dt, now)
	SpikeServer.step(now)
	AbilityServer.step(now)
	RunItBackServer.step(now)
	StepServer.step(now)
	CloudServer.step(now)
	FlareServer.step(now)
	BlazeServer.step(now)
	FireServer.step(now, dt)
	HealServer.step(now)
	SlowServer.step(now)
	BarrierServer.step(now)
	ReviveServer.step(now)
	ParanoiaServer.step(now)
	ReconServer.step(now)
	ShockServer.step(now)
	DroneServer.step(now)
	GroundGunsServer.step()
	CombatServer.step(now, dt)
	MinimapServer.step(now)
	FogServer.step(now)
	Replication.step(now)
	Arena.step(now)
	AfkServer.step(now, dt)
	AgentServer.step(now)
	ReportServer.step(now)
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
