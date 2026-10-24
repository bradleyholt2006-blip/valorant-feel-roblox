--!strict
-- Client entry point.

local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local PlayerController = require(script.PlayerController)
local RemoteEntities = require(script.RemoteEntities)
local ClientShots = require(script.Combat.ClientShots)
local WeaponEffects = require(script.Combat.WeaponEffects)
local CombatHud = require(script.Combat.CombatHud)
local DebugHud = require(script.Debug.DebugHud)
local SpeedGraph = require(script.Debug.SpeedGraph)
local CounterStrafeLab = require(script.Debug.CounterStrafeLab)
local Recorder = require(script.Debug.Recorder)
local WeaponLab = require(script.Debug.WeaponLab)
local HitboxOverlay = require(script.Debug.HitboxOverlay)

-- Our HUD replaces Roblox's health bar, and number keys belong to weapons.
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

RemoteEntities.start()
PlayerController.start()
ClientShots.start()
WeaponEffects.start()
CombatHud.start()

DebugHud.start(PlayerController)
SpeedGraph.start(PlayerController)
CounterStrafeLab.start(PlayerController)
Recorder.start(PlayerController)
WeaponLab.start(PlayerController)
HitboxOverlay.start()

-- Debug weapon give (Studio / place owner only) until there is a buy phase.
-- The weapon goes into its slot with full ammo and is drawn.
local giveKeys: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.Four] = "vandal",
	[Enum.KeyCode.Five] = "phantom",
	[Enum.KeyCode.Six] = "operator",
	[Enum.KeyCode.Seven] = "sheriff",
	[Enum.KeyCode.Eight] = "classic",
}
UserInputService.InputBegan:Connect(function(input, processed)
	local id = giveKeys[input.KeyCode]
	if id and not processed then
		PlayerController.requestWeapon(id)
	end
end)
