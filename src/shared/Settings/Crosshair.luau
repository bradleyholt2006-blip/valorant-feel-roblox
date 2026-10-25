--!strict
-- Crosshair codes (system 11): read the code the reference's settings export,
-- write it back, and work out what it draws.
--
-- The reference exports a crosshair as "auto-generated codes" (Patch 4.05)
-- and Riot documents the importing and exporting but not the code. What's
-- known of it is the community's: fields joined by semicolons, a profile
-- number first, then pairs of a key and its value, in sections that start
-- with a capital letter: P the primary crosshair, A the one for aiming down
-- sights and S the sniper scope's centre dot (the three tabs Patch 5.04
-- names). Pairs before the first section are general settings. Only the
-- settings that differ from the defaults are written, so "0;P;h;0;d;1;0b;0;1b;0"
-- is the default crosshair with the outlines off, the centre dot on, and no
-- inner or outer lines.
--
-- docs/research/11-settings.md has the key table, where each key comes from
-- and how sure it is. Keys this doesn't know are kept as they are, so a code
-- goes back out with everything it came in with.
--
-- Pure, so the tests read the community's example codes and the server can
-- check a code before keeping it.

export type Field = { key: string, value: string }
export type Section = { name: string, fields: { Field } }
export type Code = {
	version: string, -- the leading profile number
	sections: { Section }, -- the general settings (name "") first
	warnings: { string }, -- what was dropped or changed, in words
}

export type Rgb = { r: number, g: number, b: number } -- 0-255

export type Lines = {
	show: boolean,
	thickness: number,
	length: number, -- horizontal lines
	vertical: number, -- vertical lines
	offset: number,
	opacity: number,
	movementError: boolean,
	firingError: boolean,
	movementScale: number,
	firingScale: number,
}

export type Profile = {
	color: Rgb,
	colorName: string,
	outlines: boolean,
	outlineThickness: number,
	outlineOpacity: number,
	dot: boolean,
	dotThickness: number,
	dotOpacity: number,
	fade: boolean, -- fade the top lines with firing error
	inner: Lines,
	outer: Lines,
}

export type SniperDot = { show: boolean, color: Rgb, colorName: string, thickness: number, opacity: number }

-- One drawn piece, in whole pixels from the centre of the screen (x right,
-- y down): pixel 0 is the one just right of and below the centre. A hidden
-- piece has w and h 0.
export type Rect = { x: number, y: number, w: number, h: number, alpha: number, outline: number, outlineAlpha: number }

local Crosshair = {}

Crosshair.MAX_LENGTH = 1000
Crosshair.MAX_FIELDS = 300
-- The default crosshair: nothing differs.
Crosshair.DEFAULT = "0;P"

-- The eight colours, in the menu's order ("White, Green, Yellow-Green,
-- Green-Yellow, Yellow, Cyan, Pink, Red", community); 8 is the hex colour
-- of Patch 5.04. The RGB values are ours: no source gives them.
Crosshair.COLORS = {
	[0] = { name = "white", rgb = { r = 255, g = 255, b = 255 } },
	[1] = { name = "green", rgb = { r = 0, g = 255, b = 0 } },
	[2] = { name = "yellow-green", rgb = { r = 127, g = 255, b = 0 } },
	[3] = { name = "green-yellow", rgb = { r = 223, g = 255, b = 0 } },
	[4] = { name = "yellow", rgb = { r = 255, g = 255, b = 0 } },
	[5] = { name = "cyan", rgb = { r = 0, g = 255, b = 255 } },
	[6] = { name = "pink", rgb = { r = 255, g = 0, b = 255 } },
	[7] = { name = "red", rgb = { r = 255, g = 0, b = 0 } },
}
Crosshair.CUSTOM = 8

-- How far the top lines have faded (with "fade crosshair with firing error"
-- on) once the firing error is this many degrees: fully. Ours: the community
-- says only that the top line "disappears when continuously firing with an
-- automatic weapon".
Crosshair.FADE_DEGREES = 0.5
-- The sniper scope's centre dot is this many pixels across for each unit of
-- its thickness. Ours: its thickness goes in fractions (0.335, 2.742 in
-- published settings), so it isn't whole pixels.
Crosshair.SNIPER_DOT_PIXELS = 2

-- The keys --------------------------------------------------------------------

type KeyDef = { kind: "bool" | "number" | "int" | "hex", default: number?, min: number?, max: number? }

local function bool(default: number): KeyDef
	return { kind = "bool", default = default }
end
local function num(default: number, min: number, max: number): KeyDef
	return { kind = "number", default = default, min = min, max = max }
end

local PROFILE_KEYS: { [string]: KeyDef } = {
	c = { kind = "int", default = 0, min = 0, max = 8 }, -- colour
	u = { kind = "hex" }, -- the hex colour, with colour 8
	h = bool(1), -- outlines
	t = num(1, 1, 6), -- outline thickness
	o = num(0.5, 0, 1), -- outline opacity
	d = bool(0), -- centre dot
	z = num(2, 0, 6), -- centre dot thickness
	a = num(1, 0, 1), -- centre dot opacity
	f = bool(1), -- fade crosshair with firing error
	s = bool(1), -- show the spectated player's crosshair
	m = bool(0), -- override the firing error offset with the crosshair offset
}
-- Inner lines are 0, outer lines 1.
type LineDefaults = {
	show: number,
	thickness: number,
	length: number,
	offset: number,
	opacity: number,
	movement: number,
	firing: number,
	maxLength: number,
	maxOffset: number,
}
local LINE_DEFAULTS: { [string]: LineDefaults } = {
	["0"] = { show = 1, thickness = 2, length = 6, offset = 3, opacity = 0.8, movement = 0, firing = 1, maxLength = 20, maxOffset = 20 },
	["1"] = { show = 1, thickness = 2, length = 2, offset = 10, opacity = 0.35, movement = 1, firing = 1, maxLength = 10, maxOffset = 40 },
}
for prefix, d in LINE_DEFAULTS do
	PROFILE_KEYS[prefix .. "b"] = bool(d.show) -- show
	PROFILE_KEYS[prefix .. "t"] = num(d.thickness, 0, 10)
	PROFILE_KEYS[prefix .. "l"] = num(d.length, 0, d.maxLength) -- length (horizontal)
	PROFILE_KEYS[prefix .. "v"] = num(d.length, 0, d.maxLength) -- vertical length
	PROFILE_KEYS[prefix .. "g"] = bool(0) -- vertical length set apart from the horizontal
	PROFILE_KEYS[prefix .. "o"] = num(d.offset, 0, d.maxOffset)
	PROFILE_KEYS[prefix .. "a"] = num(d.opacity, 0, 1)
	PROFILE_KEYS[prefix .. "m"] = bool(d.movement) -- movement error
	PROFILE_KEYS[prefix .. "f"] = bool(d.firing) -- firing error
	PROFILE_KEYS[prefix .. "s"] = num(1, 0, 3) -- movement error multiplier
	PROFILE_KEYS[prefix .. "e"] = num(1, 0, 3) -- firing error multiplier
end

local SNIPER_KEYS: { [string]: KeyDef } = {
	d = bool(1), -- show the centre dot
	c = { kind = "int", default = 7, min = 0, max = 8 },
	u = { kind = "hex" },
	s = num(1, 0, 6), -- thickness
	o = num(0.75, 0, 1), -- opacity
}

local GENERAL_KEYS: { [string]: KeyDef } = {
	s = bool(0), -- "Use Advanced Options" (Patch 3.03): the A and S sections count
}

local KEYS_BY_SECTION: { [string]: { [string]: KeyDef } } = {
	[""] = GENERAL_KEYS,
	P = PROFILE_KEYS,
	A = PROFILE_KEYS,
	S = SNIPER_KEYS,
}

-- Reading -----------------------------------------------------------------------

local function trim(s: string): string
	return (string.gsub(s, "^%s+", ""):gsub("%s+$", ""))
end

-- Up to three decimals, without trailing zeros: 0.35, 1, 2.742.
function Crosshair.number(v: number): string
	local text = string.format("%.3f", v)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return if text == "-0" then "0" else text
end

-- The value a known key keeps, or nil and why it was dropped.
local function normalize(def: KeyDef, key: string, value: string, warnings: { string }): string?
	if def.kind == "hex" then
		local hex = string.match(value, "^#?(%x+)$")
		if not hex or (#hex ~= 6 and #hex ~= 8) then
			table.insert(warnings, string.format("%s %s isn't a hex colour, so it was left out", key, value))
			return nil
		end
		return string.upper(if #hex == 6 then hex .. "FF" else hex)
	end
	local n = tonumber(value)
	if n == nil or n ~= n or n == math.huge or n == -math.huge then
		table.insert(warnings, string.format("%s %s isn't a number, so it was left out", key, value))
		return nil
	end
	if def.kind == "bool" then
		return if n ~= 0 then "1" else "0"
	end
	if def.kind == "int" then
		n = math.floor(n)
	end
	local min, max = def.min, def.max
	if min and max and (n < min or n > max) then
		local kept = math.clamp(n, min, max)
		table.insert(
			warnings,
			string.format(
				"%s %s is outside %s-%s, so it's %s",
				key,
				value,
				Crosshair.number(min),
				Crosshair.number(max),
				Crosshair.number(kept)
			)
		)
		n = kept
	end
	return Crosshair.number(n)
end

local function sectionNamed(code: Code, name: string): Section?
	for _, section in code.sections do
		if section.name == name then
			return section
		end
	end
	return nil
end

local function set(section: Section, key: string, value: string)
	for _, field in section.fields do
		if field.key == key then
			field.value = value
			return
		end
	end
	table.insert(section.fields, { key = key, value = value })
end

-- Reads a code. Returns nil and the reason when it isn't one; otherwise the
-- code, with any field it couldn't use left out and said so in `warnings`.
function Crosshair.parse(text: string): (Code?, string?)
	if type(text) ~= "string" then
		return nil, "that isn't text"
	end
	text = trim(text)
	if text == "" then
		return nil, "the code is empty"
	end
	if #text > Crosshair.MAX_LENGTH then
		return nil, string.format("the code is longer than %d characters", Crosshair.MAX_LENGTH)
	end
	local fields = string.split(text, ";")
	-- A trailing semicolon leaves an empty last field.
	if fields[#fields] == "" then
		table.remove(fields)
	end
	if #fields > Crosshair.MAX_FIELDS then
		return nil, string.format("the code has more than %d fields", Crosshair.MAX_FIELDS)
	end
	local version = trim(fields[1])
	if not string.match(version, "^%d+$") then
		return nil, "a crosshair code starts with a number (0;P;...)"
	end
	local warnings: { string } = {}
	local general: Section = { name = "", fields = {} }
	local code: Code = { version = version, sections = { general }, warnings = warnings }
	local section = general
	local i = 2
	while i <= #fields do
		local field = trim(fields[i])
		if string.match(field, "^%u$") then
			local existing = sectionNamed(code, field)
			if existing then
				section = existing
			else
				section = { name = field, fields = {} }
				table.insert(code.sections, section)
			end
			i += 1
			continue
		end
		local raw = fields[i + 1]
		if raw == nil then
			table.insert(warnings, string.format("%s has no value, so it was left out", field))
			break
		end
		local value = trim(raw)
		i += 2
		if not string.match(field, "^%w+$") or #field > 8 then
			table.insert(warnings, string.format("%q isn't a key, so it and its value were left out", field))
			continue
		end
		if not string.match(value, "^[%w%.%-#]+$") or #value > 16 then
			table.insert(warnings, string.format("%s %q isn't a value, so it was left out", field, value))
			continue
		end
		local keys = KEYS_BY_SECTION[section.name]
		local def = keys and keys[field]
		local kept = if def then normalize(def, field, value, warnings) else value
		if kept then
			set(section, field, kept)
		end
	end
	return code, nil
end

-- The code as text again: what it came in with, tidied.
function Crosshair.format(code: Code): string
	local parts = { code.version }
	for _, section in code.sections do
		if section.name ~= "" then
			table.insert(parts, section.name)
		end
		for _, field in section.fields do
			table.insert(parts, field.key)
			table.insert(parts, field.value)
		end
	end
	return table.concat(parts, ";")
end

-- A code tidied, or nil and the reason when it isn't one.
function Crosshair.normalize(text: string): (string?, string?, { string }?)
	local code, err = Crosshair.parse(text)
	if not code then
		return nil, err, nil
	end
	return Crosshair.format(code), nil, code.warnings
end

function Crosshair.hasSection(code: Code, name: string): boolean
	return sectionNamed(code, name) ~= nil
end

-- What a section says for a key, or the key's default.
local function valueOf(section: Section?, keys: { [string]: KeyDef }, key: string): number
	if section then
		for _, field in section.fields do
			if field.key == key then
				local n = tonumber(field.value)
				if n then
					return n
				end
			end
		end
	end
	return keys[key].default or 0
end

local function hexOf(section: Section?, key: string): string?
	if section then
		for _, field in section.fields do
			if field.key == key then
				return field.value
			end
		end
	end
	return nil
end

local function colorFor(index: number, hex: string?): (Rgb, string)
	if index == Crosshair.CUSTOM then
		local h = hex or "FFFFFFFF"
		return {
			r = tonumber(string.sub(h, 1, 2), 16) or 255,
			g = tonumber(string.sub(h, 3, 4), 16) or 255,
			b = tonumber(string.sub(h, 5, 6), 16) or 255,
		},
			"#" .. string.sub(h, 1, 6)
	end
	local entry = Crosshair.COLORS[index] or Crosshair.COLORS[0]
	return { r = entry.rgb.r, g = entry.rgb.g, b = entry.rgb.b }, entry.name
end

-- Whether the general settings turn on "Use Advanced Options".
function Crosshair.advanced(code: Code): boolean
	return valueOf(sectionNamed(code, ""), GENERAL_KEYS, "s") ~= 0
end

-- The crosshair a section ("P" or "A") draws, defaults filled in.
function Crosshair.profile(code: Code, name: string): Profile
	local section = sectionNamed(code, name)
	local function v(key: string): number
		return valueOf(section, PROFILE_KEYS, key)
	end
	local function lines(prefix: string): Lines
		local length = v(prefix .. "l")
		return {
			show = v(prefix .. "b") ~= 0,
			thickness = v(prefix .. "t"),
			length = length,
			-- Patch 5.04's chain: until it's undone, the vertical lines are as
			-- long as the horizontal ones.
			vertical = if v(prefix .. "g") ~= 0 then v(prefix .. "v") else length,
			offset = v(prefix .. "o"),
			opacity = v(prefix .. "a"),
			movementError = v(prefix .. "m") ~= 0,
			firingError = v(prefix .. "f") ~= 0,
			movementScale = v(prefix .. "s"),
			firingScale = v(prefix .. "e"),
		}
	end
	local color, colorName = colorFor(v("c"), hexOf(section, "u"))
	return {
		color = color,
		colorName = colorName,
		outlines = v("h") ~= 0,
		outlineThickness = v("t"),
		outlineOpacity = v("o"),
		dot = v("d") ~= 0,
		dotThickness = v("z"),
		dotOpacity = v("a"),
		fade = v("f") ~= 0,
		inner = lines("0"),
		outer = lines("1"),
	}
end

-- The crosshair for aiming down sights: the A section when "Use Advanced
-- Options" is on and the code has one, otherwise the primary.
function Crosshair.adsProfile(code: Code): Profile
	if Crosshair.advanced(code) and Crosshair.hasSection(code, "A") then
		return Crosshair.profile(code, "A")
	end
	return Crosshair.profile(code, "P")
end

-- The sniper scope's centre dot.
function Crosshair.sniperDot(code: Code): SniperDot
	local section = if Crosshair.advanced(code) then sectionNamed(code, "S") else nil
	local function v(key: string): number
		return valueOf(section, SNIPER_KEYS, key)
	end
	local color, colorName = colorFor(v("c"), hexOf(section, "u"))
	return { show = v("d") ~= 0, color = color, colorName = colorName, thickness = v("s"), opacity = v("o") }
end

-- Drawing --------------------------------------------------------------------------

-- Whole pixels for a size: anything shown is at least one.
local function pixels(v: number): number
	if v <= 0 then
		return 0
	end
	return math.max(math.floor(v + 0.5), 1)
end

-- How far the top lines have faded for this much firing error, 0 to 1.
function Crosshair.fadeFor(firingDegrees: number): number
	return math.clamp(firingDegrees / Crosshair.FADE_DEGREES, 0, 1)
end

local HIDDEN: Rect = { x = 0, y = 0, w = 0, h = 0, alpha = 0, outline = 0, outlineAlpha = 0 }

Crosshair.PIECES = { "dot", "innerRight", "innerLeft", "innerUp", "innerDown", "outerRight", "outerLeft", "outerUp", "outerDown" }

-- The pieces of a profile, in PIECES order, with the lines that show
-- movement error moved out by `movementPixels` and those that show firing
-- error by `firingPixels` (each times its multiplier). `fade` (0 to 1) is how
-- far the top lines have faded, when the profile fades them.
function Crosshair.shape(p: Profile, movementPixels: number, firingPixels: number, fade: number): { Rect }
	local outline = if p.outlines then pixels(p.outlineThickness) else 0
	local out: { Rect } = {}

	local size = pixels(p.dotThickness)
	if p.dot and size > 0 then
		local at = -math.floor(size / 2)
		table.insert(out, { x = at, y = at, w = size, h = size, alpha = p.dotOpacity, outline = outline, outlineAlpha = p.outlineOpacity })
	else
		table.insert(out, HIDDEN)
	end

	local topAlpha = if p.fade then 1 - math.clamp(fade, 0, 1) else 1
	for _, l in { p.inner, p.outer } do
		local thick = pixels(l.thickness)
		local long, tall = pixels(l.length), pixels(l.vertical)
		local offset = l.offset
		if l.movementError then
			offset += movementPixels * l.movementScale
		end
		if l.firingError then
			offset += firingPixels * l.firingScale
		end
		local gap = math.floor(offset + 0.5)
		local half = math.floor(thick / 2)
		local shown = l.show and thick > 0
		local function piece(x: number, y: number, w: number, h: number, alpha: number): Rect
			if not shown or w == 0 or h == 0 then
				return HIDDEN
			end
			return { x = x, y = y, w = w, h = h, alpha = l.opacity * alpha, outline = outline, outlineAlpha = p.outlineOpacity * alpha }
		end
		-- An even thickness is centred on the line between the middle two
		-- pixels and an odd one on the middle pixel; either way there are as
		-- many pixels of gap on each side.
		local near = if thick % 2 == 1 then gap + 1 else gap
		table.insert(out, piece(near, -half, long, thick, 1))
		table.insert(out, piece(-gap - long, -half, long, thick, 1))
		table.insert(out, piece(-half, -gap - tall, thick, tall, topAlpha))
		table.insert(out, piece(-half, near, thick, tall, 1))
	end
	return out
end

local function describeLines(name: string, l: Lines): string
	if not l.show or l.thickness <= 0 or (l.length <= 0 and l.vertical <= 0) then
		return "no " .. name .. " lines"
	end
	local length = if l.vertical ~= l.length
		then string.format("%s/%s", Crosshair.number(l.length), Crosshair.number(l.vertical))
		else Crosshair.number(l.length)
	local errors = {}
	if l.movementError then
		table.insert(errors, "moving")
	end
	if l.firingError then
		table.insert(errors, "firing")
	end
	return string.format(
		"%s lines %s long, %s thick, %s out%s",
		name,
		length,
		Crosshair.number(l.thickness),
		Crosshair.number(l.offset),
		if #errors > 0 then ", spread " .. table.concat(errors, " and ") else ""
	)
end

-- In words, for the settings menu.
function Crosshair.describe(p: Profile): string
	local parts = { p.colorName }
	table.insert(
		parts,
		if p.outlines
			then string.format("outlines %s at %s", Crosshair.number(p.outlineThickness), Crosshair.number(p.outlineOpacity))
			else "no outlines"
	)
	table.insert(parts, if p.dot then string.format("dot %s", Crosshair.number(p.dotThickness)) else "no dot")
	table.insert(parts, describeLines("inner", p.inner))
	table.insert(parts, describeLines("outer", p.outer))
	return table.concat(parts, "; ")
end

return Crosshair
