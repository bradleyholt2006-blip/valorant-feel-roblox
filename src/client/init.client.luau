--!strict
-- Client entry point.

local UserInputService = game:GetService("UserInputService")

local MovementController = require(script.MovementController)
local RemotePlayers = require(script.RemotePlayers)
local DebugHud = require(script.Debug.DebugHud)
local SpeedGraph = require(script.Debug.SpeedGraph)
local CounterStrafeLab = require(script.Debug.CounterStrafeLab)
local Recorder = require(script.Debug.Recorder)

MovementController.start()
RemotePlayers.start()

DebugHud.start(MovementController)
SpeedGraph.start(MovementController)
CounterStrafeLab.start(MovementController)
Recorder.start(MovementController)

-- Debug weapon select until the weapon system exists: movement speed and
-- deadzone come from the equipped weapon's profile.
local weaponKeys = {
	[Enum.KeyCode.One] = "rifle",
	[Enum.KeyCode.Two] = "sniper",
	[Enum.KeyCode.Three] = "knife",
}
UserInputService.InputBegan:Connect(function(input, processed)
	local weapon = weaponKeys[input.KeyCode]
	if weapon and not processed then
		MovementController.setWeapon(weapon)
	end
end)
