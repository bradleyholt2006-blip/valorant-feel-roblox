--!strict
-- Client entry point.

local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local NetSim = require(script.NetSim)
local PlayerController = require(script.PlayerController)
local RemoteEntities = require(script.RemoteEntities)
local Visuals = require(script.Visuals)
local ClientShots = require(script.Combat.ClientShots)
local ClientMelee = require(script.Combat.ClientMelee)
local WeaponEffects = require(script.Combat.WeaponEffects)
local CombatHud = require(script.Combat.CombatHud)
local ArenaHud = require(script.ArenaHud)
local BuyMenu = require(script.BuyMenu)
local GameSounds = require(script.Audio.GameSounds)
local DefaultSounds = require(script.Audio.DefaultSounds)
local DebugHud = require(script.Debug.DebugHud)
local SpeedGraph = require(script.Debug.SpeedGraph)
local CounterStrafeLab = require(script.Debug.CounterStrafeLab)
local Recorder = require(script.Debug.Recorder)
local WeaponLab = require(script.Debug.WeaponLab)
local SprayLab = require(script.Debug.SprayLab)
local HitRegLab = require(script.Debug.HitRegLab)
local SoundLab = require(script.Debug.SoundLab)
local HitboxOverlay = require(script.Debug.HitboxOverlay)
local TestAim = require(script.Debug.TestAim)

-- Our HUD replaces Roblox's health bar, and number keys belong to weapons.
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Delivers messages held back by simulated latency (Hit Reg Lab) at the start of each frame.
NetSim.start()
RemoteEntities.start()
-- The look: lighting, colour, vignette, and outlines on RemoteEntities' models (V, N).
Visuals.start()
PlayerController.start()
ClientShots.start()
-- The knife's swings: the client's guess at once, the server's verdict after.
ClientMelee.start()
WeaponEffects.start()
CombatHud.start()
-- The arena's score and round banners, and P to turn it on or off.
ArenaHud.start()
-- B: every gun and shield, in the arena's buy phase and any time on the course.
BuyMenu.start()
-- Footsteps, landings, gunshots, reloads, draws and hit sounds, with
-- Roblox's own character sounds switched off.
DefaultSounds.start()
GameSounds.start()

DebugHud.start(PlayerController)
SpeedGraph.start(PlayerController)
CounterStrafeLab.start(PlayerController)
Recorder.start(PlayerController)
WeaponLab.start(PlayerController)
SprayLab.start(PlayerController)
HitRegLab.start(PlayerController)
SoundLab.start(PlayerController)
HitboxOverlay.start()
-- Studio only: aim set by attributes, for scripted playtests.
TestAim.start(PlayerController)

-- F2 pages through the labs: Weapon Lab, Spray Lab, Hit Reg Lab, Sound Lab, off.
local labs = { WeaponLab, SprayLab, HitRegLab, SoundLab }
local labPage = 0
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F2 then
		labPage = (labPage + 1) % (#labs + 1)
		for i, lab in labs do
			lab.setVisible(i == labPage)
		end
	end
end)

-- Debug weapon give (Studio / place owner only, and anyone in the arena's buy
-- phase), quicker than the buy menu for the guns tested most. The weapon goes
-- into its slot with full ammo and is drawn.
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
