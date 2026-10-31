--!strict
-- A player's settings (system 11): the mouse sensitivity and the crosshair
-- they bring from the reference, kept between sessions by SettingsServer.
--
-- Sensitivity is the reference's own number. The view turns
-- YAW_DEGREES_PER_COUNT * sensitivity degrees for each count the mouse
-- reports, the same yaw "0.07 degrees per mouse count" the community's
-- converters use, so the same number and mouse DPI give the same distance
-- across the mouse pad for a full turn (cm/360). Zoomed, the view turns
-- `scoped` (the reference's "scoped sensitivity multiplier", 1 by default)
-- times as far for each count, divided by the zoom: at 1 the scene slides
-- under the crosshair as fast as it does unzoomed.
--
-- The DPI is the mouse's, which the game can't read; it's only there to
-- turn the sensitivity into cm/360 for the menu.
--
-- The minimap's settings (system 34) are the reference's (Settings, General,
-- Map; thespike.gg and setup.gg, community): Rotate or Fixed, a Fixed map's
-- orientation Based on Side or Always the Same, Keep Player Centered, the
-- Minimap Size and Zoom, Minimap Vision Cones, and Show Map Region Names on
-- the big map: Always, Only in Buy Phase or Never (the UI Settings FAQ).
--
-- A gamepad's (system 68, PadRules): how fast the right stick turns the
-- view, in degrees a second at full tilt; Focus's share of that; inverting
-- it; and walking while in Focus. The reference's console version has
-- these as "Base", "Focus" and the other sensitivities, and "Walk While in
-- Focus" (charlieintel.com, community), on scales it doesn't publish: the
-- numbers here are ours.
--
-- Settings travel as text, "key=value" lines, in the VFSettings attribute
-- and the data store; keys this doesn't know are ignored, so older servers
-- read newer settings, and settings kept before a key was known take its
-- default.

local Crosshair = require("./Crosshair")

export type Settings = {
	sensitivity: number,
	scoped: number,
	dpi: number,
	crosshair: string, -- a crosshair code, tidied by Crosshair.normalize
	-- The minimap (system 34).
	mapRotate: boolean, -- Rotate (true) or Fixed
	mapBySide: boolean, -- a Fixed map's orientation: Based on Side (true) or Always the Same
	mapCentred: boolean, -- Keep Player Centered
	mapSize: number,
	mapZoom: number,
	mapCones: boolean, -- Minimap Vision Cones
	mapNames: string, -- Show Map Region Names: "always", "buy" (Only in Buy Phase) or "never"
	-- A gamepad (system 68).
	padLook: number, -- degrees a second the view turns at full tilt
	padFocus: number, -- Focus's share of that
	padInvert: boolean, -- up on the stick looks down
	padWalk: boolean, -- Walk While in Focus
	-- A touch screen (system 71).
	touchLook: number, -- degrees a drag the length of the screen's short side turns the view
}

local PlayerSettings = {}

PlayerSettings.YAW_DEGREES_PER_COUNT = 0.07
-- The attribute the server sets on the player, once, with what it loaded.
PlayerSettings.ATTRIBUTE = "VFSettings"
-- Where the server is with keeping them: "loading", "saved", "loaded",
-- "new" (nothing kept yet), or "off: <why>" when this place can't keep them.
PlayerSettings.STATUS_ATTRIBUTE = "VFSettingsStatus"
PlayerSettings.MAX_TEXT = 1200

-- The minimap's are ours, from what guides set (thespike.gg, setup.gg,
-- 1v9.gg): none publishes the reference's own.
PlayerSettings.DEFAULTS = table.freeze({
	sensitivity = 0.4, -- ours: a common setting at 800 DPI
	scoped = 1,
	dpi = 800,
	crosshair = Crosshair.DEFAULT,
	mapRotate = true,
	mapBySide = true,
	mapCentred = false,
	mapSize = 1,
	mapZoom = 0.9,
	mapCones = true,
	mapNames = "always",
	padLook = 220, -- ours: about a second and a half for a turn at full tilt, before the ramp
	padFocus = 0.5,
	padInvert = false,
	padWalk = false, -- charlieintel.com's: 'Turn off Walk While in Focus lets you move quicker'
	touchLook = 120, -- ours: a drag right across a phone held sideways turns 210 to 260 degrees
})

PlayerSettings.LIMITS = table.freeze({
	sensitivity = { 0.001, 10 },
	scoped = { 0.01, 5 },
	dpi = { 0, 32000 },
	mapSize = { 0.8, 1.2 },
	mapZoom = { 0.6, 1.4 },
	padLook = { 30, 720 },
	padFocus = { 0.1, 1 },
	touchLook = { 30, 400 },
})

-- Show Map Region Names' choices, in the menu's order.
PlayerSettings.MAP_NAMES = table.freeze({ "always", "buy", "never" })

function PlayerSettings.copy(s: Settings): Settings
	return table.clone(s)
end

local function clampNumber(value: any, limits: { number }, default: number): number
	local n = tonumber(value)
	if n == nil or n ~= n or n == math.huge or n == -math.huge then
		return default
	end
	return math.clamp(n, limits[1], limits[2])
end

-- A switch from anything: true or false, or as text "1", "on", "true",
-- "0", "off", "false"; nil for anything else.
function PlayerSettings.switchOf(value: any): boolean?
	if type(value) == "boolean" then
		return value
	elseif value == "1" or value == "on" or value == "true" then
		return true
	elseif value == "0" or value == "off" or value == "false" then
		return false
	end
	return nil
end

local function switch(value: any, default: boolean): boolean
	local on = PlayerSettings.switchOf(value)
	if on == nil then
		return default
	end
	return on
end

-- Settings from anything: missing or broken values take the default, numbers
-- are held to LIMITS and the crosshair is tidied (a broken one is the
-- default).
function PlayerSettings.sanitize(raw: any): Settings
	local t = if type(raw) == "table" then raw else {}
	local L = PlayerSettings.LIMITS
	local D = PlayerSettings.DEFAULTS
	local crosshair = D.crosshair
	if type(t.crosshair) == "string" then
		crosshair = Crosshair.normalize(t.crosshair) or D.crosshair
	end
	return {
		sensitivity = clampNumber(t.sensitivity, L.sensitivity, D.sensitivity),
		scoped = clampNumber(t.scoped, L.scoped, D.scoped),
		dpi = math.floor(clampNumber(t.dpi, L.dpi, D.dpi) + 0.5),
		crosshair = crosshair,
		mapRotate = switch(t.mapRotate, D.mapRotate),
		mapBySide = switch(t.mapBySide, D.mapBySide),
		mapCentred = switch(t.mapCentred, D.mapCentred),
		mapSize = clampNumber(t.mapSize, L.mapSize, D.mapSize),
		mapZoom = clampNumber(t.mapZoom, L.mapZoom, D.mapZoom),
		mapCones = switch(t.mapCones, D.mapCones),
		mapNames = if table.find(PlayerSettings.MAP_NAMES, t.mapNames) then t.mapNames else D.mapNames,
		padLook = clampNumber(t.padLook, L.padLook, D.padLook),
		padFocus = clampNumber(t.padFocus, L.padFocus, D.padFocus),
		padInvert = switch(t.padInvert, D.padInvert),
		padWalk = switch(t.padWalk, D.padWalk),
		touchLook = clampNumber(t.touchLook, L.touchLook, D.touchLook),
	}
end

local function bit(on: boolean): string
	return if on then "1" else "0"
end

function PlayerSettings.toText(s: Settings): string
	return table.concat({
		"sensitivity=" .. Crosshair.number(s.sensitivity),
		"scoped=" .. Crosshair.number(s.scoped),
		"dpi=" .. tostring(s.dpi),
		"crosshair=" .. s.crosshair,
		"mapRotate=" .. bit(s.mapRotate),
		"mapBySide=" .. bit(s.mapBySide),
		"mapCentred=" .. bit(s.mapCentred),
		"mapSize=" .. Crosshair.number(s.mapSize),
		"mapZoom=" .. Crosshair.number(s.mapZoom),
		"mapCones=" .. bit(s.mapCones),
		"mapNames=" .. s.mapNames,
		"padLook=" .. Crosshair.number(s.padLook),
		"padFocus=" .. Crosshair.number(s.padFocus),
		"padInvert=" .. bit(s.padInvert),
		"padWalk=" .. bit(s.padWalk),
		"touchLook=" .. Crosshair.number(s.touchLook),
	}, "\n")
end

function PlayerSettings.fromText(text: any): Settings
	local raw: { [string]: string } = {}
	if type(text) == "string" and #text <= PlayerSettings.MAX_TEXT then
		for line in string.gmatch(text, "[^\n]+") do
			local key, value = string.match(line, "^(%w+)=(.*)$")
			if key and value then
				raw[key] = value
			end
		end
	end
	return PlayerSettings.sanitize(raw)
end

function PlayerSettings.equal(a: Settings, b: Settings): boolean
	for key in PlayerSettings.DEFAULTS do
		if (a :: any)[key] ~= (b :: any)[key] then
			return false
		end
	end
	return true
end

-- Sensitivity ------------------------------------------------------------------

-- Degrees the view turns for one mouse count at this zoom (1 unzoomed),
-- with this sensitivity and scoped multiplier.
function PlayerSettings.degreesPerCount(sensitivity: number, scoped: number, zoom: number): number
	local degrees = PlayerSettings.YAW_DEGREES_PER_COUNT * sensitivity
	if zoom > 1 then
		degrees *= scoped / zoom
	end
	return degrees
end

-- Counts for a full turn.
function PlayerSettings.countsPer360(degreesPerCount: number): number
	return 360 / degreesPerCount
end

-- Centimetres of mouse movement for a full turn, or nil without the DPI.
function PlayerSettings.cmPer360(degreesPerCount: number, dpi: number): number?
	if dpi <= 0 or degreesPerCount <= 0 then
		return nil
	end
	return PlayerSettings.countsPer360(degreesPerCount) / dpi * 2.54
end

-- Sensitivity times DPI, the number players compare across mice.
function PlayerSettings.edpi(s: Settings): number
	return s.sensitivity * s.dpi
end

return PlayerSettings
