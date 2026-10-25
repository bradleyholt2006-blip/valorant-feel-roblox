--!strict
-- The local player's settings (system 11): the sensitivity the camera turns
-- by and the crosshair code CrosshairView draws. The settings menu changes
-- them; each change applies at once and goes to the server to keep
-- (SettingsServer).
--
-- The server sets PlayerSettings.ATTRIBUTE once, with what it kept from last
-- time. Until then, and when nothing was kept, these are the defaults. A
-- change made before the kept settings arrive wins over them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerSettings = require(Shared.Settings.PlayerSettings)
local Crosshair = require(Shared.Settings.Crosshair)
local Remotes = require(Shared.Net.Remotes)

local CameraController = require(script.Parent.CameraController)

local ClientSettings = {}

ClientSettings.current = PlayerSettings.copy(PlayerSettings.DEFAULTS)
-- The crosshair code, read.
ClientSettings.code = (Crosshair.parse(Crosshair.DEFAULT) :: any) :: Crosshair.Code
-- Called with the settings after each change, kept ones included.
ClientSettings.listeners = {} :: { (PlayerSettings.Settings) -> () }

local me = Players.LocalPlayer
local changed = false -- the player has changed something this session
local sent = PlayerSettings.toText(ClientSettings.current) -- what the server has

local function apply(s: PlayerSettings.Settings)
	ClientSettings.current = s
	local code = Crosshair.parse(s.crosshair)
	ClientSettings.code = code or (Crosshair.parse(Crosshair.DEFAULT) :: any)
	CameraController.sensitivity = s.sensitivity
	CameraController.scopedMultiplier = s.scoped
	for _, listener in ClientSettings.listeners do
		listener(s)
	end
end

-- Changes the settings: held to their limits, applied, and sent to be kept.
function ClientSettings.set(s: PlayerSettings.Settings)
	local clean = PlayerSettings.sanitize(s)
	changed = true
	apply(clean)
	local text = PlayerSettings.toText(clean)
	if text ~= sent then
		sent = text
		Remotes.get().Settings:FireServer(text)
	end
end

-- Changes one setting, as the menu's boxes and TestAim's VFTestSetting do.
-- Returns false when the value isn't one.
function ClientSettings.setOne(key: string, value: string): boolean
	local s = PlayerSettings.copy(ClientSettings.current)
	if key == "crosshair" then
		local text = Crosshair.normalize(value)
		if not text then
			return false
		end
		s.crosshair = text
	elseif key == "sensitivity" or key == "scoped" or key == "dpi" then
		local n = tonumber(value)
		if n == nil or n ~= n then
			return false
		end
		if key == "sensitivity" then
			s.sensitivity = n
		elseif key == "scoped" then
			s.scoped = n
		else
			s.dpi = n
		end
	else
		return false
	end
	ClientSettings.set(s)
	return true
end

-- Where the server is with keeping them (PlayerSettings.STATUS_ATTRIBUTE).
function ClientSettings.status(): string
	local status = me:GetAttribute(PlayerSettings.STATUS_ATTRIBUTE)
	return if typeof(status) == "string" then status else "loading"
end

function ClientSettings.start()
	apply(ClientSettings.current)
	local function kept()
		local text = me:GetAttribute(PlayerSettings.ATTRIBUTE)
		if typeof(text) ~= "string" or changed then
			return
		end
		local s = PlayerSettings.fromText(text)
		sent = PlayerSettings.toText(s)
		apply(s)
	end
	me:GetAttributeChangedSignal(PlayerSettings.ATTRIBUTE):Connect(kept)
	kept()
end

return ClientSettings
