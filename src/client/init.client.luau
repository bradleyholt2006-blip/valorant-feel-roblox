--!strict
-- Client entry point.

local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local NetSim = require(script.NetSim)
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
local SprayLab = require(script.Debug.SprayLab)
local HitRegLab = require(script.Debug.HitRegLab)
local HitboxOverlay = require(script.Debug.HitboxOverlay)

-- Our HUD replaces Roblox's health bar, and number keys belong to weapons.
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Delivers messages held back by simulated latency (Hit Reg Lab) at the start of each frame.
NetSim.start()
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
SprayLab.start(PlayerController)
HitRegLab.start(PlayerController)
HitboxOverlay.start()

-- F2 pages through the labs: Weapon Lab, Spray Lab, Hit Reg Lab, off.
local labs = { WeaponLab, SprayLab, HitRegLab }
local labPage = 0
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F2 then
		labPage = (labPage + 1) % (#labs + 1)
		for i, lab in labs do
			lab.setVisible(i == labPage)
		end
	end
end)

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
