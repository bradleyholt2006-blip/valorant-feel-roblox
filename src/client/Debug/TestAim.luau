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
-- Clearing them gives the mouse back. Outside Studio this does nothing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Hitboxes = require(Shared.Combat.Hitboxes)
local PlayerSim = require(Shared.PlayerSim)
local Units = require(Shared.Units)

local CameraController = require(script.Parent.Parent.CameraController)
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
		local player = Players.LocalPlayer
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
