--!strict
-- Settings (system 11): crosshair codes, what they draw, and sensitivity.

local Crosshair = require("../src/shared/Settings/Crosshair")
local PlayerSettings = require("../src/shared/Settings/PlayerSettings")
local H = require("./Harness")

local check, near = H.check, H.near

H.section("Settings tests")

local function parsed(text: string): Crosshair.Code
	local code, err = Crosshair.parse(text)
	assert(code, err)
	return code
end

local function same(a: Crosshair.Rgb, r: number, g: number, b: number): boolean
	return a.r == r and a.g == g and a.b == b
end

local function hidden(rect: Crosshair.Rect): boolean
	return rect.w == 0 or rect.h == 0
end

-- Pieces by name.
local function pieces(rects: { Crosshair.Rect }): { [string]: Crosshair.Rect }
	local out = {}
	for i, name in Crosshair.PIECES do
		out[name] = rects[i]
	end
	return out
end

-- The default crosshair ------------------------------------------------------------

do
	local p = Crosshair.profile(parsed(Crosshair.DEFAULT), "P")
	check("the default is white with outlines (1 thick, 0.5 opacity) and no centre dot", same(p.color, 255, 255, 255) and p.outlines and p.outlineThickness == 1 and p.outlineOpacity == 0.5 and not p.dot)
	check(
		"default inner lines: 0.8 opacity, 6 long, 2 thick, 3 out (exputer's 0.8/6/2/3), firing error on, movement error off",
		p.inner.show and p.inner.opacity == 0.8 and p.inner.length == 6 and p.inner.vertical == 6 and p.inner.thickness == 2 and p.inner.offset == 3 and p.inner.firingError and not p.inner.movementError
	)
	check(
		"default outer lines: 0.35 opacity, 2 long, 2 thick, 10 out (0.35/2/2/10), both errors on",
		p.outer.show and p.outer.opacity == 0.35 and p.outer.length == 2 and p.outer.thickness == 2 and p.outer.offset == 10 and p.outer.firingError and p.outer.movementError
	)
	check("the default fades with firing error, multipliers 1", p.fade and p.inner.movementScale == 1 and p.inner.firingScale == 1 and p.outer.movementScale == 1 and p.outer.firingScale == 1)
	check("the default's description", Crosshair.describe(p) == "white; outlines 1 at 0.5; no dot; inner lines 6 long, 2 thick, 3 out, spread firing; outer lines 2 long, 2 thick, 10 out, spread moving and firing")
end

-- The community's example codes -----------------------------------------------------

do
	-- senslab: "a cyan crosshair with no outlines, inner lines 4 long at
	-- offset 2 at full opacity, no firing error, and outer lines off".
	local text = "0;P;c;5;h;0;0l;4;0o;2;0a;1;0f;0;1b;0"
	local code = parsed(text)
	local p = Crosshair.profile(code, "P")
	check("senslab's example: cyan, no outlines", same(p.color, 0, 255, 255) and p.colorName == "cyan" and not p.outlines)
	check("senslab's example: inner lines 4 long both ways, 2 out, opacity 1, no firing error", p.inner.length == 4 and p.inner.vertical == 4 and p.inner.offset == 2 and p.inner.opacity == 1 and not p.inner.firingError)
	check("senslab's example: no outer lines", not p.outer.show)
	check("senslab's example goes back out as it came in", Crosshair.format(code) == text and #code.warnings == 0)

	local s = pieces(Crosshair.shape(p, 0, 0, 0))
	check("its inner lines: 4 x 2 from 2 px out, on all four sides", s.innerRight.x == 2 and s.innerRight.w == 4 and s.innerRight.h == 2 and s.innerLeft.x == -6 and s.innerUp.y == -6 and s.innerUp.h == 4 and s.innerDown.y == 2)
	check("its outer lines and dot aren't drawn", hidden(s.outerRight) and hidden(s.outerLeft) and hidden(s.outerUp) and hidden(s.outerDown) and hidden(s.dot))
	check("no outlines on it", s.innerRight.outline == 0)
end

do
	-- dotesports' basic dot: white, outlines off, centre dot on at opacity 1
	-- and thickness 2, no inner or outer lines.
	local text = "0;P;h;0;d;1;0b;0;1b;0"
	local p = Crosshair.profile(parsed(text), "P")
	check("dotesports' basic dot: white, no outlines, a dot of opacity 1 and thickness 2", same(p.color, 255, 255, 255) and not p.outlines and p.dot and p.dotOpacity == 1 and p.dotThickness == 2)
	local s = pieces(Crosshair.shape(p, 0, 0, 0))
	check("it draws a 2 x 2 dot on the centre and nothing else", s.dot.x == -1 and s.dot.y == -1 and s.dot.w == 2 and s.dot.h == 2 and s.dot.alpha == 1 and hidden(s.innerRight) and hidden(s.outerUp))
end

do
	-- THESPIKE's square and round dots, given with their colour only.
	local square = parsed("0;P;o;1;d;1;z;4;0b;0;1b;0")
	local p = Crosshair.profile(square, "P")
	local s = pieces(Crosshair.shape(p, 0, 0, 0))
	check("THESPIKE's square dot: white, a 4 px dot outlined at opacity 1, no lines", p.colorName == "white" and s.dot.w == 4 and s.dot.x == -2 and s.dot.outline == 1 and s.dot.outlineAlpha == 1 and hidden(s.innerRight) and hidden(s.outerRight))
	local text = "0;s;1;P;h;0;d;1;z;3;f;0;0t;3;0l;1;0o;1;0a;1;0f;0;1t;0;1l;0;1o;0;1a;0;1f;0"
	local round = parsed(text)
	local r = pieces(Crosshair.shape(Crosshair.profile(round, "P"), 0, 0, 0))
	check(
		"THESPIKE's round dot: a 3 px dot with a 1 x 3 inner line against each side, rounding it, and no outer lines",
		r.dot.w == 3 and r.dot.x == -1 and r.innerRight.x == 2 and r.innerLeft.x == -2 and r.innerUp.y == -2 and r.innerDown.y == 2 and r.innerRight.w == 1 and r.innerRight.h == 3 and r.innerRight.y == -1 and hidden(r.outerRight)
	)
	check("THESPIKE's round dot goes back out as it came in", Crosshair.format(round) == text and Crosshair.advanced(round))
end

do
	-- dotesports' cyan round dot with inner and outer lines.
	local text = "0;P;c;5;h;0;d;1;0l;1;0v;1;0o;1;0a;0.6;0f;0;1t;4;1l;1;1v;1;1o;1;1a;0.1;1m;0;1f;0"
	local code = parsed(text)
	local p = Crosshair.profile(code, "P")
	check("the round dot: cyan, a dot, inner 1 long 1 out at 0.6", p.colorName == "cyan" and p.dot and p.inner.length == 1 and p.inner.vertical == 1 and p.inner.offset == 1 and p.inner.opacity == 0.6)
	check("the round dot: outer 1 long, 4 thick, 1 out at 0.1, no errors", p.outer.length == 1 and p.outer.thickness == 4 and p.outer.offset == 1 and p.outer.opacity == 0.1 and not p.outer.movementError and not p.outer.firingError)
	check("the round dot goes back out as it came in", Crosshair.format(code) == text)
end

do
	-- JUNiOR's code from the sciencejiho spec, with advanced options, a
	-- separate vertical length and a sniper dot.
	local text = "0;s;1;P;c;5;o;1;f;0;m;1;0l;2;0v;2;0g;1;0o;0;0a;1;0f;0;1b;0;S;c;5;s;0.7;o;1"
	local code = parsed(text)
	local p = Crosshair.profile(code, "P")
	check("JUNiOR's: advanced options on", Crosshair.advanced(code))
	check("JUNiOR's: cyan, outlines at opacity 1, no fade, inner 2 by 2 at 0", p.colorName == "cyan" and p.outlines and p.outlineOpacity == 1 and not p.fade and p.inner.length == 2 and p.inner.vertical == 2 and p.inner.offset == 0)
	local dot = Crosshair.sniperDot(code)
	check("JUNiOR's sniper dot: cyan, 0.7 thick, opacity 1", dot.show and dot.colorName == "cyan" and dot.thickness == 0.7 and dot.opacity == 1)
	check("JUNiOR's goes back out as it came in", Crosshair.format(code) == text and #code.warnings == 0)
	local s = pieces(Crosshair.shape(p, 0, 0, 0))
	check("offset 0: the inner lines meet in the middle", s.innerRight.x == 0 and s.innerLeft.x == -2 and s.innerUp.y == -2 and s.innerDown.y == 0)
end

-- Vertical lines on their own (Patch 5.04's chain) --------------------------------

do
	local chained = Crosshair.profile(parsed("0;P;0l;4;0v;9"), "P")
	check("chained, the vertical lines follow the horizontal length", chained.inner.length == 4 and chained.inner.vertical == 4)
	local apart = Crosshair.profile(parsed("0;P;0l;4;0v;9;0g;1"), "P")
	check("unchained (0g 1), they take 0v", apart.inner.length == 4 and apart.inner.vertical == 9)
	local s = pieces(Crosshair.shape(apart, 0, 0, 0))
	check("and are drawn that long", s.innerUp.h == 9 and s.innerDown.h == 9 and s.innerRight.w == 4)
end

-- Errors spread the lines -------------------------------------------------------

do
	local p = Crosshair.profile(parsed(Crosshair.DEFAULT), "P")
	local still = pieces(Crosshair.shape(p, 0, 0, 0))
	check("the default's pieces at rest: inner from 3 px, outer from 10 px", still.innerRight.x == 3 and still.innerRight.w == 6 and still.innerLeft.x == -9 and still.outerRight.x == 10 and still.outerLeft.x == -12 and still.outerUp.y == -12)
	check("each 2 px thick across the centre", still.innerRight.y == -1 and still.innerRight.h == 2 and still.innerUp.x == -1 and still.innerUp.w == 2)
	check("outlined 1 px at 0.5", still.innerRight.outline == 1 and still.innerRight.outlineAlpha == 0.5 and still.outerDown.outline == 1)

	local moving = pieces(Crosshair.shape(p, 5, 0, 0))
	check("moving 5 px: only the outer lines (movement error) move out", moving.innerRight.x == 3 and moving.outerRight.x == 15 and moving.outerLeft.x == -17 and moving.outerDown.y == 15)
	local firing = pieces(Crosshair.shape(p, 0, 4, 0))
	check("firing 4 px: both move out (firing error)", firing.innerRight.x == 7 and firing.outerRight.x == 14 and firing.innerUp.y == -13)
	local both = pieces(Crosshair.shape(p, 5, 4, 0))
	check("both: the outer lines add them", both.outerRight.x == 19 and both.innerRight.x == 7)

	local faded = pieces(Crosshair.shape(p, 0, 4, 1))
	check("fully faded: the top lines and their outlines go, the others stay", faded.innerUp.alpha == 0 and faded.innerUp.outlineAlpha == 0 and faded.outerUp.alpha == 0 and faded.innerDown.alpha == 0.8 and faded.innerRight.alpha == 0.8)
	local half = pieces(Crosshair.shape(p, 0, 0, 0.5))
	check("half faded: the top lines at half", near(half.innerUp.alpha, 0.4, 1e-9) and near(half.outerUp.alpha, 0.175, 1e-9))
	local noFade = pieces(Crosshair.shape(Crosshair.profile(parsed("0;P;f;0"), "P"), 0, 0, 1))
	check("with fading off, the top lines stay", noFade.innerUp.alpha == 0.8)
	check("fade: none at 0 degrees, half at 0.25, all at 0.5 and past it", Crosshair.fadeFor(0) == 0 and near(Crosshair.fadeFor(0.25), 0.5, 1e-9) and Crosshair.fadeFor(0.5) == 1 and Crosshair.fadeFor(3) == 1)

	local doubled = pieces(Crosshair.shape(Crosshair.profile(parsed("0;P;1s;2;0e;0.5"), "P"), 5, 4, 0))
	check("multipliers: outer movement x2, inner firing x0.5", doubled.outerRight.x == 10 + 10 + 4 and doubled.innerRight.x == 3 + 2)
	local rounded = pieces(Crosshair.shape(p, 0.6, 0.4, 0))
	check("spread rounds to whole pixels", rounded.outerRight.x == 11 and rounded.innerRight.x == 3)
end

-- Sizes in whole pixels ------------------------------------------------------------

do
	local p = Crosshair.profile(parsed("0;P;d;1;z;0.5;0t;1;0l;2.6;1b;0"), "P")
	local s = pieces(Crosshair.shape(p, 0, 0, 0))
	check("half a pixel of dot still shows as one", s.dot.w == 1 and s.dot.h == 1)
	check("2.6 long rounds to 3; 1 thick sits on the middle pixel", s.innerRight.w == 3 and s.innerRight.h == 1 and s.innerRight.y == 0 and s.innerUp.x == 0 and s.innerUp.w == 1)
	check("1 thick: 3 pixels of gap each side of the middle one, at offset 3", s.innerRight.x == 4 and s.innerLeft.x + s.innerLeft.w == -3 and s.innerDown.y == 4 and s.innerUp.y + s.innerUp.h == -3)
	local even = pieces(Crosshair.shape(Crosshair.profile(parsed(Crosshair.DEFAULT), "P"), 0, 0, 0))
	check("2 thick: 3 pixels of gap each side of the middle line", even.innerRight.x == 3 and even.innerLeft.x + even.innerLeft.w == -3 and even.innerUp.x == -1)
	local zero = pieces(Crosshair.shape(Crosshair.profile(parsed("0;P;0t;0;1l;0"), "P"), 0, 0, 0))
	check("0 thick or 0 long isn't drawn, outline and all", hidden(zero.innerRight) and hidden(zero.outerUp) and zero.innerRight.outline == 0)
	local outlineOnly = pieces(Crosshair.shape(Crosshair.profile(parsed("0;P;0a;0;t;2"), "P"), 0, 0, 0))
	check("opacity 0 with outlines leaves the outline", outlineOnly.innerRight.alpha == 0 and outlineOnly.innerRight.outline == 2 and outlineOnly.innerRight.w == 6)
end

-- Colours ----------------------------------------------------------------------------

do
	local names = {}
	for i = 0, 7 do
		table.insert(names, Crosshair.profile(parsed("0;P;c;" .. i), "P").colorName)
	end
	check("the eight colours in the menu's order", table.concat(names, ",") == "white,green,yellow-green,green-yellow,yellow,cyan,pink,red")
	local code = parsed("0;P;c;8;u;00ff7f")
	local p = Crosshair.profile(code, "P")
	check("a hex colour (Patch 5.04's custom)", same(p.color, 0, 255, 127) and p.colorName == "#00FF7F")
	check("written back in capitals with its alpha", Crosshair.format(code) == "0;P;c;8;u;00FF7FFF")
	local bad = parsed("0;P;c;8;u;nothex")
	check("a hex colour that isn't one is left out, and the custom colour is white", #bad.warnings == 1 and Crosshair.format(bad) == "0;P;c;8" and same(Crosshair.profile(bad, "P").color, 255, 255, 255))
end

-- What a code can't say -----------------------------------------------------------

do
	check("empty isn't a code", Crosshair.parse("") == nil and Crosshair.parse("   ") == nil)
	local _, why = Crosshair.parse("P;c;5")
	check("a code starts with a number", Crosshair.parse("P;c;5") == nil and why ~= nil and string.find(why, "starts with a number", 1, true) ~= nil)
	check("too long isn't a code", Crosshair.parse("0;P" .. string.rep(";c;1", 400)) == nil)

	local clamped = parsed("0;P;0o;50;1a;-1;c;9.7")
	check("past a slider's ends: held to them, and said", Crosshair.format(clamped) == "0;P;0o;20;1a;0;c;8" and #clamped.warnings == 3)
	local dropped = parsed("0;P;c;x;h;0;z")
	check("a value that isn't a number, or a key with no value, is left out and said", Crosshair.format(dropped) == "0;P;h;0" and #dropped.warnings == 2)
	local tidy = parsed(" 0 ; P ; c ; 5 ; 0a ; 1.000 ; h ; 2 ;")
	check("spaces, trailing zeros, a trailing semicolon and a 2 for on are tidied", Crosshair.format(tidy) == "0;P;c;5;0a;1;h;1")
	local again = parsed("0;P;c;1;c;5")
	check("a key given twice keeps the last value in the first place", Crosshair.format(again) == "0;P;c;5")
end

do
	local text = "0;s;1;x9;3;P;c;1;zz;7;A;c;2;0l;3;S;q;1"
	local code = parsed(text)
	check("keys and sections this doesn't know are kept, in order", Crosshair.format(code) == text and #code.warnings == 0)
	local merged = parsed("0;P;c;1;A;c;2;P;h;0")
	check("a section named twice is one section", Crosshair.format(merged) == "0;P;c;1;h;0;A;c;2")
	check("normalize gives the tidied text", Crosshair.normalize("0;P;c;5;0a;1.0") == "0;P;c;5;0a;1" and Crosshair.normalize("nope") == nil)
end

-- Aiming down sights and the sniper scope ------------------------------------------

do
	check("ADS uses the A section with advanced options on", Crosshair.adsProfile(parsed("0;s;1;P;c;1;A;c;5")).colorName == "cyan")
	check("without advanced options it's the primary", Crosshair.adsProfile(parsed("0;P;c;1;A;c;5")).colorName == "green")
	check("advanced options with no A section: the primary", Crosshair.adsProfile(parsed("0;s;1;P;c;1")).colorName == "green")
	local default = Crosshair.sniperDot(parsed(Crosshair.DEFAULT))
	check("the sniper dot by default: shown, red, 1 thick, 0.75", default.show and default.colorName == "red" and default.thickness == 1 and default.opacity == 0.75)
	check("the S section counts only with advanced options", not Crosshair.sniperDot(parsed("0;s;1;P;S;d;0")).show and Crosshair.sniperDot(parsed("0;P;S;d;0")).show)
end

-- Settings -------------------------------------------------------------------------

do
	local d = PlayerSettings.sanitize(nil)
	check("defaults: 0.4, scoped 1, 800 DPI, the default crosshair", d.sensitivity == 0.4 and d.scoped == 1 and d.dpi == 800 and d.crosshair == Crosshair.DEFAULT)

	local s = PlayerSettings.copy(PlayerSettings.DEFAULTS)
	s.sensitivity, s.scoped, s.dpi, s.crosshair = 0.314, 0.85, 1600, "0;P;c;5;h;0;0l;4;0o;2;0a;1;0f;0;1b;0"
	local text = PlayerSettings.toText(s)
	check("as text: key=value lines", text == "sensitivity=0.314\nscoped=0.85\ndpi=1600\ncrosshair=0;P;c;5;h;0;0l;4;0o;2;0a;1;0f;0;1b;0\nmapRotate=1\nmapBySide=1\nmapCentred=0\nmapSize=1\nmapZoom=0.9\nmapCones=1\nmapNames=always\npadLook=220\npadFocus=0.5\npadInvert=0\npadWalk=0")
	check("and back", PlayerSettings.equal(PlayerSettings.fromText(text), s))

	local wild = PlayerSettings.sanitize({ sensitivity = -1, scoped = 0 / 0, dpi = 1e9, crosshair = "garbage" })
	check("out of range held, NaN and broken crosshairs take the default", wild.sensitivity == 0.001 and wild.scoped == 1 and wild.dpi == 32000 and wild.crosshair == Crosshair.DEFAULT)
	local tidied = PlayerSettings.sanitize({ sensitivity = "0.5", dpi = 799.6, crosshair = "0;P;c;5;0a;1.000" })
	check("numbers as text read, DPI whole, the crosshair tidied", tidied.sensitivity == 0.5 and tidied.dpi == 800 and tidied.crosshair == "0;P;c;5;0a;1")
	local extra = PlayerSettings.fromText("sensitivity=0.6\nfov=110\nnonsense\ncrosshair=0;P;d;1")
	check("keys it doesn't know are ignored", extra.sensitivity == 0.6 and extra.scoped == 1 and extra.crosshair == "0;P;d;1")
	check("text that's too long is all defaults", PlayerSettings.equal(PlayerSettings.fromText(string.rep("x", 2000)), PlayerSettings.DEFAULTS))
	local pad = PlayerSettings.fromText("padLook=5000\npadFocus=0\npadInvert=on\npadWalk=1")
	check(
		"a gamepad's (system 68): the look speed and Focus's share held to their bounds, the switches read",
		pad.padLook == 720 and pad.padFocus == 0.1 and pad.padInvert and pad.padWalk
	)
	local plain = PlayerSettings.sanitize(nil)
	check(
		"and by default 220 degrees a second, half in Focus, not inverted",
		plain.padLook == 220 and plain.padFocus == 0.5 and not plain.padInvert
	)
end

do
	local s = PlayerSettings.sanitize({ sensitivity = 0.4, scoped = 1, dpi = 800 })
	local hip = PlayerSettings.degreesPerCount(s.sensitivity, s.scoped, 1)
	check("0.4 turns 0.028 degrees a count (0.07 x 0.4)", near(hip, 0.028, 1e-12))
	local cm = PlayerSettings.cmPer360(hip, 800)
	check("0.4 at 800 DPI: 12857 counts, 40.8 cm a turn", near(PlayerSettings.countsPer360(hip), 12857.14, 0.01) and cm ~= nil and near(cm, 40.82, 0.01))
	local community = PlayerSettings.cmPer360(PlayerSettings.degreesPerCount(1.5, 1, 1), 800)
	check("1.5 at 800 DPI: 10.9 cm (csdb.gg's figure)", community ~= nil and near(community, 10.9, 0.05))
	check("no DPI, no cm/360", PlayerSettings.cmPer360(hip, 0) == nil)
	check("eDPI 320", PlayerSettings.edpi(s) == 320)
	check("zoomed at multiplier 1: divided by the zoom", near(PlayerSettings.degreesPerCount(0.4, 1, 2.5), 0.028 / 2.5, 1e-12) and near(PlayerSettings.degreesPerCount(0.4, 1, 1.25), 0.028 / 1.25, 1e-12))
	check("multiplier 0.5 halves it zoomed, not unzoomed", near(PlayerSettings.degreesPerCount(0.4, 0.5, 5), 0.028 * 0.5 / 5, 1e-12) and near(PlayerSettings.degreesPerCount(0.4, 0.5, 1), 0.028, 1e-12))
	print(string.format("  0.4 at 800 DPI: %.1f cm/360 hip, %.1f cm scoped 2.5x, %.1f cm at 5x", cm or 0, PlayerSettings.cmPer360(PlayerSettings.degreesPerCount(0.4, 1, 2.5), 800) or 0, PlayerSettings.cmPer360(PlayerSettings.degreesPerCount(0.4, 1, 5), 800) or 0))
end

return nil
