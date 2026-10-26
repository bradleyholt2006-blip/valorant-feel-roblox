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
local KillFeed = require(script.KillFeed)
local ArenaHud = require(script.ArenaHud)
local Scoreboard = require(script.Scoreboard)
local Spectate = require(script.Spectate)
local VoteScreen = require(script.VoteScreen)
local PlayMenu = require(script.PlayMenu)
local BuyMenu = require(script.BuyMenu)
local LoadoutMenu = require(script.LoadoutMenu)
local AgentMenu = require(script.AgentMenu)
local ClientSettings = require(script.ClientSettings)
local CrosshairView = require(script.CrosshairView)
local SettingsMenu = require(script.SettingsMenu)
local ClientSpike = require(script.ClientSpike)
local SpikeView = require(script.SpikeView)
local SpikeHud = require(script.SpikeHud)
local GroundGunsView = require(script.GroundGunsView)
local AbilityHud = require(script.AbilityHud)
local AbilityEffects = require(script.AbilityEffects)
local CloudView = require(script.CloudView)
local FlareView = require(script.FlareView)
local FireView = require(script.FireView)
local BlazeView = require(script.BlazeView)
local RunItBackView = require(script.RunItBackView)
local HealView = require(script.HealView)
local SlowView = require(script.SlowView)
local MinimapView = require(script.MinimapView)
local BlindView = require(script.BlindView)
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
-- The spike: what the server says of it, and what that lets you do, predicted.
ClientSpike.start()
PlayerController.objective = ClientSpike.context
table.insert(PlayerController.spikeListeners, ClientSpike.onAct)
PlayerController.start()
ClientShots.start()
-- The knife's swings: the client's guess at once, the server's verdict after.
ClientMelee.start()
WeaponEffects.start()
CombatHud.start()
-- Who killed whom, with what, at the top right.
KillFeed.start()
-- The arena's score and round banners, and P to turn it on or off.
ArenaHud.start()
-- Tab: everyone's kills, deaths, assists, combat score and credits, in the
-- arena and the spike rounds, and the victory screen as a match ends.
Scoreboard.start()
-- While you're down in rounds, a living teammate's view (left and right
-- click to switch).
Spectate.start()
-- After each match's victory screen, the vote for the next map: click one.
VoteScreen.start()
-- M: the Play menu (system 24), a card for each mode and PLAY, up as you
-- join a live server until you've pressed it.
PlayMenu.start()
-- B: every gun and shield, in the arena's buy phase and any time on the course.
BuyMenu.start()
-- B in Team Deathmatch: the loadout to carry in each of its stages.
LoadoutMenu.start()
-- T: agent select (system 29), up by itself as each match's window opens.
AgentMenu.start()
-- Your sensitivity and crosshair, kept between sessions; O for the menu.
ClientSettings.start()
CrosshairView.start(PlayerController)
SettingsMenu.start()
-- The spike in the world (its beeps and blast too) and on the HUD.
SpikeView.start()
SpikeHud.start()
-- Guns on the ground, and F to pick one up.
GroundGunsView.start()
-- Footsteps, landings, gunshots, reloads, draws and hit sounds, with
-- Roblox's own character sounds switched off.
DefaultSounds.start()
GameSounds.start()
-- The ability kit (system 17): C, Q, E and X on the bar at the bottom, and
-- each cast's look and sound; Cloudburst's throws and clouds (system 18),
-- Curveball's flares and blinds (system 30), Hot Hands' fireballs and fire
-- (system 31), Blaze's walls of fire (system 32), Run it Back's marks and
-- returns (system 33), the Healing Orb's heals (system 36) and the Slow
-- Orb's fields of ice (system 37).
AbilityHud.start()
AbilityEffects.start()
CloudView.start()
FlareView.start()
BlindView.start()
FireView.start()
BlazeView.start()
RunItBackView.start()
HealView.start()
SlowView.start()
-- The minimap at the top left (system 34), and the big map while Caps Lock
-- is held: the map, your side and the enemies it sees, the spike, what's
-- been thrown, and the sounds you make.
MinimapView.start()

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
-- They start at 5: 4 is the spike's.
local giveKeys: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.Five] = "vandal",
	[Enum.KeyCode.Six] = "phantom",
	[Enum.KeyCode.Seven] = "operator",
	[Enum.KeyCode.Eight] = "sheriff",
	[Enum.KeyCode.Nine] = "classic",
}
UserInputService.InputBegan:Connect(function(input, processed)
	local id = giveKeys[input.KeyCode]
	if id and not processed then
		PlayerController.requestWeapon(id)
	end
end)
