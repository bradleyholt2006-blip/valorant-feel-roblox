--!strict
-- The local player's settings (system 11): the sensitivity the camera turns
-- by, the crosshair code CrosshairView draws, how the minimap shows the
-- map (MinimapView, system 34) and how a gamepad turns the view (Gamepad,
-- system 68). The settings menu changes them; each change applies at once
-- and goes to the server to keep (SettingsServer).
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

-- Changes one setting, as the menu's boxes and buttons and TestAim's
-- VFTestSetting do: a number, a switch ("1" or "0", "on" or "off") or one
-- of Show Map Region Names' choices for the minimap's (system 34), and the
-- gamepad's (system 68). Returns false when the value isn't one.
function ClientSettings.setOne(key: string, value: string): boolean
	local s = PlayerSettings.copy(ClientSettings.current)
	if key == "crosshair" then
		local text = Crosshair.normalize(value)
		if not text then
			return false
		end
		s.crosshair = text
	elseif
		key == "sensitivity"
		or key == "scoped"
		or key == "dpi"
		or key == "mapSize"
		or key == "mapZoom"
		or key == "padLook"
		or key == "padFocus"
	then
		local n = tonumber(value)
		if n == nil or n ~= n then
			return false
		end
		(s :: any)[key] = n
	elseif
		key == "mapRotate"
		or key == "mapBySide"
		or key == "mapCentred"
		or key == "mapCones"
		or key == "padInvert"
		or key == "padWalk"
	then
		local on = PlayerSettings.switchOf(value)
		if on == nil then
			return false
		end
		(s :: any)[key] = on
	elseif key == "mapNames" then
		if not table.find(PlayerSettings.MAP_NAMES, value) then
			return false
		end
		s.mapNames = value
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
