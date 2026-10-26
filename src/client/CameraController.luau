--!strict
-- First-person mouse look with a scriptable camera.
--
-- Sensitivity uses the reference game's convention: degrees of yaw per mouse
-- count = YAW_DEGREES_PER_COUNT * sensitivity. 0.07 is the widely published
-- community figure (estimate until verified with the cm/360 test in the lab).
-- The player sets the sensitivity and the scoped multiplier in the settings
-- menu (ClientSettings); PlayerSettings.degreesPerCount has the sums.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local PlayerSettings = require(ReplicatedStorage:WaitForChild("Shared").Settings.PlayerSettings)

local CameraController = {}

CameraController.YAW_DEGREES_PER_COUNT = PlayerSettings.YAW_DEGREES_PER_COUNT
CameraController.sensitivity = PlayerSettings.DEFAULTS.sensitivity
-- The reference's "scoped sensitivity multiplier": how fast the view turns
-- zoomed, on top of dividing by the zoom.
CameraController.scopedMultiplier = PlayerSettings.DEFAULTS.scoped
CameraController.fieldOfView = 103 -- horizontal, reference game's fixed FOV (community)

CameraController.yaw = 0
CameraController.pitch = 0
-- Extra view rotation drawn on top of the aim (weapon recoil kick), radians.
CameraController.kickPitch = 0
CameraController.kickYaw = 0
-- Current zoom (1 = hip). Mouse sensitivity scales with 1 / zoom while
-- zoomed, so at a scoped multiplier of 1 the crosshair moves across the
-- scene at the same speed (estimate of the reference's default scoped
-- sensitivity).
CameraController.zoom = 1
-- While set (the buy menu or the settings menu is open), the mouse moves a
-- cursor instead of the view.
CameraController.cursorFree = false
-- While set (Omen's From the Shadows' map is up, system 43, ShadowView),
-- the mouse moves its cursor across the map instead of the view: called
-- with each frame's movement, in counts, as the view would turn by.
CameraController.mapCursor = nil :: ((Vector2) -> ())?

local MAX_PITCH = math.rad(89)

local function userSensitivity(): number
	local ok, settings = pcall(function()
		return UserSettings():GetService("UserGameSettings")
	end)
	if ok and settings then
		return math.max(settings.MouseSensitivity, 1e-3)
	end
	return 1
end

-- Roblox's Camera.FieldOfView is vertical; convert from horizontal for the
-- current aspect ratio so the view matches regardless of window shape.
local function verticalFov(horizontalDeg: number, viewport: Vector2): number
	local aspect = viewport.X / math.max(viewport.Y, 1)
	return math.deg(2 * math.atan(math.tan(math.rad(horizontalDeg) / 2) / aspect))
end

function CameraController.start()
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseIconEnabled = false
end

-- Accumulated counts since the last call, for the cm/360 test.
CameraController.countsX = 0

function CameraController.updateLook()
	if UserInputService:GetFocusedTextBox() or CameraController.cursorFree then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		return
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	-- GetMouseDelta includes Roblox's own sensitivity slider; divide it out so
	-- our sensitivity is the only scale applied.
	local delta = UserInputService:GetMouseDelta() / userSensitivity()
	local mapCursor = CameraController.mapCursor
	if mapCursor then
		mapCursor(delta)
		return
	end
	CameraController.countsX += delta.X
	local radPerCount = math.rad(PlayerSettings.degreesPerCount(CameraController.sensitivity, CameraController.scopedMultiplier, CameraController.zoom))
	CameraController.yaw -= delta.X * radPerCount
	CameraController.pitch = math.clamp(CameraController.pitch - delta.Y * radPerCount, -MAX_PITCH, MAX_PITCH)
end

-- Horizontal FOV after zoom: zoom divides tan(fov / 2).
function CameraController.zoomedFov(zoom: number): number
	return math.deg(2 * math.atan(math.tan(math.rad(CameraController.fieldOfView) / 2) / zoom))
end

function CameraController.render(eyeStuds: Vector3, zoom: number?)
	local camera = Workspace.CurrentCamera
	CameraController.zoom = zoom or 1
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = verticalFov(CameraController.zoomedFov(CameraController.zoom), camera.ViewportSize)
	local yaw = CameraController.yaw + CameraController.kickYaw
	local pitch = math.clamp(CameraController.pitch + CameraController.kickPitch, -MAX_PITCH, MAX_PITCH)
	camera.CFrame = CFrame.new(eyeStuds) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
end

-- Looks out of someone else's eyes (Spectate): from `eyeStuds`, at their
-- yaw and pitch, unzoomed. Your own aim is left as it is.
function CameraController.lookFrom(eyeStuds: Vector3, yaw: number, pitch: number)
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = verticalFov(CameraController.fieldOfView, camera.ViewportSize)
	local clamped = math.clamp(pitch, -MAX_PITCH, MAX_PITCH)
	camera.CFrame = CFrame.new(eyeStuds) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(clamped, 0, 0)
end

return CameraController
