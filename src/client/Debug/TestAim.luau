--!strict
-- Studio-only scripted aim, for playtests driven by a tool such as the Roblox
-- Studio MCP. Such a tool can press keys and mouse buttons, but under
-- MouseBehavior.LockCenter its mouse moves never reach GetMouseDelta, so the
-- view can't turn. It sets these LocalPlayer attributes instead:
--
--   VFTestYaw, VFTestPitch  degrees to hold the view at (yaw 0 looks down -Z,
--                           the target lane, and positive yaw turns left;
--                           positive pitch looks up)
--   VFTestAimPoint          Vector3 in metres: look at that world point
--   VFTestAimEntity         entity id: track that entity as it is drawn on
--                           screen (dummy n is PlayerCodec.DUMMY_BASE + n,
--                           drawn as Workspace.VFDummies.Dummy_n; a player
--                           is their UserId mod 2^32, drawn as
--                           Workspace.VFPlayers.<their name>)
--   VFTestAimRegion         "head", "body" (the default) or "legs"
--
-- VFTestAimEntity wins over VFTestAimPoint, which wins over the angles.
-- Clearing them gives the mouse back. More drive the weapons and the buy
-- menu without a mouse button:
--
--   VFTestButtons  PlayerSim button flags held on top of the real input
--                  while set (Fire 128, AltFire 256, Reload 512, Crouch 32,
--                  Use 1024 for the spike's 4 held, Drop 2048 for G, and
--                  the abilities' C 4096, Q 8192, E 16384 and X 32768;
--                  MovementSim.Buttons has the rest)
--   VFTestGive     a weapon id: asks for it as the debug give does, then
--                  clears itself ("spike" hands over the course's spike)
--   VFTestBuy      an item id ("odin", "regen"): buys it as a click in the
--                  buy menu would, or with a "-" in front sells it back;
--                  then clears itself
--   VFTestMenu     true opens the buy menu (if buying is open), false
--                  closes it; then clears itself
--   VFTestSlot     1 to 5: draws that slot as its number key does (3 is
--                  the knife, 4 the spike while it's carried), or as X
--                  does for 5, Blade Storm's knives; then clears itself
--   VFTestTake     true: takes the gun on the ground in view as F does
--                  (system 15), then clears itself
--   VFTestBoard    true holds the scoreboard open as Tab does (system 16),
--                  false lets it go; then clears itself
--   VFTestSettingsMenu  true opens the settings menu, false closes it; then
--                  clears itself
--   VFTestSetting  "key=value": enters a setting as its box in the settings
--                  menu does ("sensitivity=0.35", "scoped=0.8", "dpi=1600",
--                  "crosshair=0;P;c;5;h;0"), then clears itself
--   VFTestVote     1 to 3: votes for that map in the vote for the next map,
--                  as a click on its card does (system 22), then clears
--                  itself
--   VFTestPlayMenu true opens the Play menu as M does (system 24), false
--                  closes it if it may close; then clears itself
--   VFTestPlay     a mode's key ("skirmish", "gungame", "deathmatch",
--                  "standard", "competitive" or "swiftplay"): presses PLAY
--                  for it as the Play menu's button does, then clears
--                  itself
--
-- Outside Studio this does nothing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Hitboxes = require(Shared.Combat.Hitboxes)
local PlayerSim = require(Shared.PlayerSim)
local Units = require(Shared.Units)

local CameraController = require(script.Parent.Parent.CameraController)
local BuyMenu = require(script.Parent.Parent.BuyMenu)
local GroundGunsView = require(script.Parent.Parent.GroundGunsView)
local Scoreboard = require(script.Parent.Parent.Scoreboard)
local SettingsMenu = require(script.Parent.Parent.SettingsMenu)
local VoteScreen = require(script.Parent.Parent.VoteScreen)
local InputSampler = require(script.Parent.Parent.InputSampler)
local PlayMenu = require(script.Parent.Parent.PlayMenu)
local RemoteEntities = require(script.Parent.Parent.RemoteEntities)

local TestAim = {}

local MAX_PITCH = math.rad(89)

-- The yaw and pitch that look from `eye` at `point`, in Accuracy.aim's convention.
local function lookAt(eye: vector, point: vector): (number, number)
	local d = point - eye
	return math.atan2(-d.x, -d.z), math.atan2(d.y, math.sqrt(d.x * d.x + d.z * d.z))
end

-- Where the attributes say to look, or nil when they're clear.
local function target(eye: vector): vector?
	local player = Players.LocalPlayer
	local id = player:GetAttribute("VFTestAimEntity")
	if typeof(id) == "number" then
		-- The pose on screen: inputs sample this same time as their viewTime
		-- before this frame's entities move.
		local pose = RemoteEntities.sample(id, RemoteEntities.shownTime())
		if not pose then
			return nil
		end
		local region = player:GetAttribute("VFTestAimRegion")
		local name: Hitboxes.Region = if region == "head" or region == "legs" then region else "body"
		local box = Hitboxes.region({ position = pose.position, yaw = pose.yaw, crouchAlpha = pose.crouchAlpha }, name)
		return if box then box.center else nil
	end
	local point = player:GetAttribute("VFTestAimPoint")
	if typeof(point) == "Vector3" then
		return Units.asVector(point)
	end
	return nil
end

function TestAim.start(controller: any)
	if not RunService:IsStudio() then
		return
	end
	-- Just before the player's own render step, which samples the aim.
	RunService:BindToRenderStep("VFTestAim", Enum.RenderPriority.Camera.Value, function()
		local player = Players.LocalPlayer
		local buttons = player:GetAttribute("VFTestButtons")
		InputSampler.extraButtons = if typeof(buttons) == "number" then bit32.band(buttons, 65535) else 0
		local give = player:GetAttribute("VFTestGive")
		if typeof(give) == "string" and give ~= "" then
			player:SetAttribute("VFTestGive", nil)
			controller.requestWeapon(give)
		end
		local buy = player:GetAttribute("VFTestBuy")
		if typeof(buy) == "string" and buy ~= "" then
			player:SetAttribute("VFTestBuy", nil)
			if string.sub(buy, 1, 1) == "-" then
				BuyMenu.request("sell", string.sub(buy, 2))
			else
				BuyMenu.request("buy", buy)
			end
		end
		local menu = player:GetAttribute("VFTestMenu")
		if typeof(menu) == "boolean" then
			player:SetAttribute("VFTestMenu", nil)
			BuyMenu.setOpen(menu)
		end
		local settingsMenu = player:GetAttribute("VFTestSettingsMenu")
		if typeof(settingsMenu) == "boolean" then
			player:SetAttribute("VFTestSettingsMenu", nil)
			SettingsMenu.setOpen(settingsMenu)
		end
		local setting = player:GetAttribute("VFTestSetting")
		if typeof(setting) == "string" and setting ~= "" then
			player:SetAttribute("VFTestSetting", nil)
			local key, value = string.match(setting, "^(%w+)=(.*)$")
			if key and value then
				SettingsMenu.enter(key, value)
			end
		end
		local slot = player:GetAttribute("VFTestSlot")
		if typeof(slot) == "number" then
			player:SetAttribute("VFTestSlot", nil)
			controller.selectSlot(slot)
		end
		if player:GetAttribute("VFTestTake") == true then
			player:SetAttribute("VFTestTake", nil)
			GroundGunsView.take()
		end
		local board = player:GetAttribute("VFTestBoard")
		if typeof(board) == "boolean" then
			player:SetAttribute("VFTestBoard", nil)
			Scoreboard.held = board
		end
		local vote = player:GetAttribute("VFTestVote")
		if typeof(vote) == "number" then
			player:SetAttribute("VFTestVote", nil)
			VoteScreen.vote(vote)
		end
		local playMenu = player:GetAttribute("VFTestPlayMenu")
		if typeof(playMenu) == "boolean" then
			player:SetAttribute("VFTestPlayMenu", nil)
			PlayMenu.setOpen(playMenu)
		end
		local play = player:GetAttribute("VFTestPlay")
		if typeof(play) == "string" and play ~= "" then
			player:SetAttribute("VFTestPlay", nil)
			PlayMenu.play(play)
		end
		local sim: PlayerSim.State? = controller.sim
		if not sim then
			return
		end
		local eye = PlayerSim.eye(sim, controller.cfg)
		local point = target(eye)
		if point then
			local yaw, pitch = lookAt(eye, point)
			CameraController.yaw = yaw
			CameraController.pitch = math.clamp(pitch, -MAX_PITCH, MAX_PITCH)
			return
		end
		local yaw = player:GetAttribute("VFTestYaw")
		local pitch = player:GetAttribute("VFTestPitch")
		if typeof(yaw) == "number" then
			CameraController.yaw = math.rad(yaw)
		end
		if typeof(pitch) == "number" then
			CameraController.pitch = math.clamp(math.rad(pitch), -MAX_PITCH, MAX_PITCH)
		end
	end)
end

return TestAim
