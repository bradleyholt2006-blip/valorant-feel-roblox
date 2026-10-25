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
-- Settings travel as text, "key=value" lines, in the VFSettings attribute
-- and the data store; keys this doesn't know are ignored, so older servers
-- read newer settings.

local Crosshair = require("./Crosshair")

export type Settings = {
	sensitivity: number,
	scoped: number,
	dpi: number,
	crosshair: string, -- a crosshair code, tidied by Crosshair.normalize
}

local PlayerSettings = {}

PlayerSettings.YAW_DEGREES_PER_COUNT = 0.07
-- The attribute the server sets on the player, once, with what it loaded.
PlayerSettings.ATTRIBUTE = "VFSettings"
-- Where the server is with keeping them: "loading", "saved", "loaded",
-- "new" (nothing kept yet), or "off: <why>" when this place can't keep them.
PlayerSettings.STATUS_ATTRIBUTE = "VFSettingsStatus"
PlayerSettings.MAX_TEXT = 1200

PlayerSettings.DEFAULTS = table.freeze({
	sensitivity = 0.4, -- ours: a common setting at 800 DPI
	scoped = 1,
	dpi = 800,
	crosshair = Crosshair.DEFAULT,
})

PlayerSettings.LIMITS = table.freeze({
	sensitivity = { 0.001, 10 },
	scoped = { 0.01, 5 },
	dpi = { 0, 32000 },
})

function PlayerSettings.copy(s: Settings): Settings
	return { sensitivity = s.sensitivity, scoped = s.scoped, dpi = s.dpi, crosshair = s.crosshair }
end

local function clampNumber(value: any, limits: { number }, default: number): number
	local n = tonumber(value)
	if n == nil or n ~= n or n == math.huge or n == -math.huge then
		return default
	end
	return math.clamp(n, limits[1], limits[2])
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
	}
end

function PlayerSettings.toText(s: Settings): string
	return table.concat({
		"sensitivity=" .. Crosshair.number(s.sensitivity),
		"scoped=" .. Crosshair.number(s.scoped),
		"dpi=" .. tostring(s.dpi),
		"crosshair=" .. s.crosshair,
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
	return a.sensitivity == b.sensitivity and a.scoped == b.scoped and a.dpi == b.dpi and a.crosshair == b.crosshair
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
