--!strict
-- Switches off Roblox's default character sounds: the RbxCharacterSounds
-- script Roblox adds to every player's PlayerScripts, which plays its own
-- sounds for every character. They would play under ours (system 8): in
-- BRINK its falling sound played on every jump, as the simulation lifts the
-- anchored root, and it plays a death sound whenever a Humanoid dies, as
-- ours do on each death.
--
-- The old way, a same-named script in StarterPlayerScripts, no longer stops
-- Roblox adding it: in BRINK, Play replaced ours with the default (measured).
-- So the script is switched off as it appears, and the sounds it already
-- made on any character's root go.

local Players = game:GetService("Players")

local DefaultSounds = {}

local SCRIPT = "RbxCharacterSounds"
-- The sounds it puts on each character's HumanoidRootPart (seen in BRINK).
local SOUNDS = {
	Climbing = true,
	Died = true,
	FreeFalling = true,
	GettingUp = true,
	Jumping = true,
	Landing = true,
	Running = true,
	Splash = true,
	Swimming = true,
}

local function switchOff(child: Instance)
	if child.Name == SCRIPT and child:IsA("LocalScript") then
		child.Enabled = false
	end
end

local function remove(d: Instance)
	local parent = d.Parent
	if d:IsA("Sound") and SOUNDS[d.Name] and parent and parent.Name == "HumanoidRootPart" then
		-- Deferred: destroying it while it's being added makes Roblox warn.
		task.defer(function()
			(d :: Sound):Stop()
			d:Destroy()
		end)
	end
end

local function onCharacter(character: Model)
	for _, d in character:GetDescendants() do
		remove(d)
	end
	character.DescendantAdded:Connect(remove)
end

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

function DefaultSounds.start()
	local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
	playerScripts.ChildAdded:Connect(switchOff)
	for _, child in playerScripts:GetChildren() do
		switchOff(child)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return DefaultSounds
