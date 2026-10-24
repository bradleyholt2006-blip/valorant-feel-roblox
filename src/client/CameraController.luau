--!strict
-- First-person mouse look with a scriptable camera.
--
-- Sensitivity uses the reference game's convention: degrees of yaw per mouse
-- count = YAW_DEGREES_PER_COUNT * sensitivity. 0.07 is the widely published
-- community figure (estimate until verified with the cm/360 test in the lab).

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CameraController = {}

CameraController.YAW_DEGREES_PER_COUNT = 0.07
CameraController.sensitivity = 0.4
CameraController.fieldOfView = 103 -- horizontal, reference game's fixed FOV (community)

CameraController.yaw = 0
CameraController.pitch = 0
-- Extra view rotation drawn on top of the aim (weapon recoil kick), radians.
CameraController.kickPitch = 0
CameraController.kickYaw = 0
-- Current zoom (1 = hip). Mouse sensitivity scales with 1 / zoom while
-- zoomed, so the crosshair moves across the scene at the same speed (estimate
-- of the reference's default scoped sensitivity).
CameraController.zoom = 1

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
	if UserInputService:GetFocusedTextBox() then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		return
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	-- GetMouseDelta includes Roblox's own sensitivity slider; divide it out so
	-- our sensitivity is the only scale applied.
	local delta = UserInputService:GetMouseDelta() / userSensitivity()
	CameraController.countsX += delta.X
	local radPerCount = math.rad(CameraController.YAW_DEGREES_PER_COUNT * CameraController.sensitivity) / CameraController.zoom
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

return CameraController
