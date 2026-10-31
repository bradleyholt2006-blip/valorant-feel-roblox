--!strict
-- A touch screen (system 71): the layout on phones' and tablets' screens,
-- clear of each other, of the screen's edges and of the HUD; what a touch
-- hits; the stick, the look drag and the buttons as PlayerSim's flags; and
-- the text scripted checks give a touch screen.

local PadConfig = require("../src/shared/Input/PadConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local TouchConfig = require("../src/shared/Input/TouchConfig")
local TouchRules = require("../src/shared/Input/TouchRules")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local P = TouchConfig.Params
local EPS = 1e-6

H.section("Touch tests")

-- Screens, in points, held sideways: each one's whole size, and the safe
-- area's insets from its left, top, right and bottom, which Roblox's top
-- bar (36 or 58 points, by version) and a notch or a home bar take
-- (estimates of the devices').
type Screen = { name: string, w: number, h: number, left: number, top: number, right: number, bottom: number }
local SCREENS: { Screen } = {
	{ name = "iPhone SE", w = 667, h = 375, left = 0, top = 58, right = 0, bottom = 0 },
	{ name = "iPhone SE, the old top bar", w = 667, h = 375, left = 0, top = 36, right = 0, bottom = 0 },
	{ name = "iPhone 14", w = 844, h = 390, left = 47, top = 58, right = 47, bottom = 21 },
	{ name = "iPhone 14 Pro Max", w = 932, h = 430, left = 59, top = 58, right = 59, bottom = 21 },
	{ name = "a small Android phone", w = 800, h = 360, left = 0, top = 58, right = 0, bottom = 0 },
	{ name = "an Android phone", w = 915, h = 412, left = 0, top = 58, right = 0, bottom = 0 },
	{ name = "an iPad", w = 1180, h = 820, left = 0, top = 58, right = 0, bottom = 20 },
	{ name = "an older iPad", w = 1024, h = 768, left = 0, top = 58, right = 0, bottom = 0 },
	{ name = "a touch laptop", w = 1366, h = 768, left = 0, top = 58, right = 0, bottom = 0 },
}

type Box = { left: number, top: number, right: number, bottom: number }

local function boxOf(s: TouchRules.Spot): Box
	return { left = s.x - s.w / 2, top = s.y - s.h / 2, right = s.x + s.w / 2, bottom = s.y + s.h / 2 }
end

-- How far apart two spots are, edge to edge: round ones by their circles,
-- a box by its box (negative where they overlap).
local function apart(a: TouchRules.Spot, b: TouchRules.Spot): number
	if a.round and b.round then
		return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) - a.w / 2 - b.w / 2
	end
	local circle, box = a, boxOf(b)
	if not a.round then
		circle, box = b, boxOf(a)
		if not b.round then
			local other = boxOf(b)
			return math.max(box.left - other.right, other.left - box.right, box.top - other.bottom, other.top - box.bottom)
		end
	end
	local nx = math.clamp(circle.x, box.left, box.right)
	local ny = math.clamp(circle.y, box.top, box.bottom)
	local d = math.sqrt((circle.x - nx) ^ 2 + (circle.y - ny) ^ 2)
	if d == 0 then
		return -math.min(circle.x - box.left, box.right - circle.x, circle.y - box.top, box.bottom - circle.y) - circle.w / 2
	end
	return d - circle.w / 2
end

-- How far a spot is from a box, edge to edge (negative where they overlap).
local function clear(s: TouchRules.Spot, box: Box): number
	local fake: TouchRules.Spot = {
		name = "",
		label = "",
		x = (box.left + box.right) / 2,
		y = (box.top + box.bottom) / 2,
		w = box.right - box.left,
		h = box.bottom - box.top,
		round = false,
	}
	return apart(s, fake)
end

local function find(spots: { TouchRules.Spot }, name: string): TouchRules.Spot
	for _, s in spots do
		if s.name == name then
			return s
		end
	end
	error("no button " .. name)
end

-- The layout ----------------------------------------------------------------------------------

do
	local gaps, hud, under, top = math.huge, math.huge, math.huge, math.huge
	local worst = ""
	local columns = 0
	local everyOne = true
	for _, screen in SCREENS do
		local w, h = screen.w - screen.left - screen.right, screen.h - screen.top - screen.bottom
		local unit = math.min(screen.w, screen.h) / 100
		-- The minimap at its biggest (Minimap Size 1.2), as MinimapView
		-- draws it, 12 points in from the safe area's corner.
		local box = math.floor(screen.h * 0.25 * 1.2 + 0.5)
		local minimap = { left = 12, top = 12, right = 12 + box, bottom = 12 + box }
		local band = TouchRules.band(screen.w, screen.h, screen.left, screen.top)
		local bandBox = { left = band.left, top = band.top, right = band.right, bottom = screen.h - 16 - screen.top }
		-- ArenaHud's bar and the players' tiles across the top.
		local tiles = { left = w / 2 - 290, top = 8, right = w / 2 + 290, bottom = 73 }
		local spots = TouchRules.layout(w, h, unit, minimap.bottom, band)
		everyOne = everyOne and #spots == #TouchRules.NAMES
		local edges = math.huge
		for i, a in spots do
			local b = boxOf(a)
			edges = math.min(edges, b.left / unit, b.top / unit, (w - b.right) / unit, (h - b.bottom) / unit)
			if a.name == "close" then
				-- Shown only with a menu up, the rest hidden.
				continue
			end
			for j = i + 1, #spots do
				local other = spots[j]
				local gap = apart(a, other) / unit
				if other.name ~= "close" and gap < gaps then
					gaps, worst = gap, string.format("%s: %s and %s", screen.name, a.name, other.name)
				end
			end
			hud = math.min(hud, clear(a, bandBox) / unit, clear(a, tiles) / unit)
			if a.name == "fire2" then
				under = math.min(under, clear(a, minimap) / unit)
			end
			if not a.round then
				top = math.min(top, (b.top - minimap.bottom) / unit)
				columns = math.max(columns, math.floor(b.left / (P.pillW.value * unit)) + 1)
			end
		end
		check(string.format("%s: every button's a margin in from the safe area's edges", screen.name), edges >= P.margin.value - EPS)
	end
	check("every button's laid out", everyOne)
	check(string.format("no two buttons closer than the margin on any screen (closest: %s)", worst), gaps >= P.margin.value - EPS)
	check("clear of the HUD's band along the bottom and the bar across the top", hud >= P.margin.value - EPS)
	check("the left thumb's fire clear of the biggest minimap", under >= P.margin.value - EPS)
	check("the left column under the minimap", top >= P.margin.value - EPS)
	check("...in two columns at most", columns <= 2)
end

do
	-- An iPad has room under the band's ends: the right thumb's buttons only
	-- lift as far as the band where it reaches under them.
	local unit = 8.2
	local band = TouchRules.band(1180, 820, 0, 58)
	local lifted = TouchRules.layout(1180, 742, unit, 270, band)
	local free = TouchRules.layout(1180, 742, unit, 270, nil)
	local jump = TouchConfig.Cluster[2]
	local function above(spots: { TouchRules.Spot }): number
		return find(spots, "jump").y + jump.dy * unit
	end
	check(
		"the right thumb's buttons stand on the band where it reaches under them, else on the bottom",
		jump.name == "jump"
			and near(above(free), 742 - P.margin.value * unit, 1e-6)
			and near(above(lifted), band.top - P.margin.value * unit, 1e-6)
	)
	local wide = TouchRules.band(3000, 820, 0, 58)
	check(
		"...and a band that doesn't reach under them leaves them be",
		near(find(TouchRules.layout(3000, 742, unit, 270, wide), "fire").y, find(free, "fire").y, 1e-6)
	)
end

do
	-- The column runs on into a second where it would reach the band.
	local spots = TouchRules.layout(667, 317, 3.75, 125, TouchRules.band(667, 375, 0, 58))
	local buy, agents = find(spots, "buy"), find(spots, "agents")
	check("a short screen's column runs on into a second, from the top", agents.x > buy.x and agents.y == buy.y)
	local tall = TouchRules.layout(1180, 742, 8.2, 0, nil)
	check("...and a tall one's is one column", find(tall, "settings").x == find(tall, "buy").x)
end

-- What a touch hits ---------------------------------------------------------------------------

do
	local spots = TouchRules.layout(844 - 94, 390 - 79, 3.9, 129, TouchRules.band(844, 390, 47, 58))
	local all = true
	for _, s in spots do
		local hit = TouchRules.hit(spots, s.x, s.y)
		all = all and hit ~= nil and hit.name == s.name
	end
	check("a touch on a button's middle is on that button", all)
	local fire = find(spots, "fire")
	check("...and on its edge too", (TouchRules.hit(spots, fire.x + fire.w / 2 - 0.01, fire.y) :: TouchRules.Spot).name == "fire")
	check("a round button's corner isn't it", TouchRules.hit(spots, fire.x + fire.w * 0.45, fire.y - fire.h * 0.45) == nil)
	check("the middle of the screen is no button", TouchRules.hit(spots, 375, 150) == nil)
	check("a button hidden isn't hit", TouchRules.hit(spots, fire.x, fire.y, function(name)
		return name ~= "fire"
	end) == nil)
	check("no button in the left of the screen moves", TouchRules.zone(750, 299) == "stick")
	check("...and anywhere else, looks", TouchRules.zone(750, 301) == "look")
end

-- The stick and the look drag -----------------------------------------------------------------

do
	local x, y = TouchRules.stick(0, -60, 60)
	check("pushed up its whole throw, the stick's straight ahead", near(x, 0, EPS) and near(y, 1, EPS))
	x, y = TouchRules.stick(300, 0, 60)
	check("...pushed past it, it's held to its throw", near(x, 1, EPS) and near(y, 0, EPS))
	x, y = TouchRules.stick(-30, 30, 60)
	check("...and half way down to the left, half way", near(x, -0.5, EPS) and near(y, -0.5, EPS))
	local cx, cy = TouchRules.look(390, 0, 390, 120, 0.028)
	check("a drag the screen's short side turns touchLook's degrees", near(cx * 0.028, 120, 1e-6) and cy == 0)
	cx, cy = TouchRules.look(-39, 78, 390, 120, 0.028)
	check("...to the left and down as dragged", near(cx * 0.028, -12, 1e-6) and near(cy * 0.028, 24, 1e-6))
end

-- The buttons as flags ------------------------------------------------------------------------

do
	local none = {}
	check("nothing held: no flags", TouchRules.flags(none, 0, 0, false, true) == 0)
	check(
		"the stick ahead, FIRE and JUMP: ahead, firing and jumping",
		TouchRules.flags({ fire = true, jump = true }, 0, 1, false, true) == bit32.bor(B.Forward, B.Fire, B.Jump)
	)
	local walkTilt = PadConfig.Params.walkTilt.value
	check("pushed only part of the way, it walks", TouchRules.flags(none, 0, walkTilt * 0.8, false, true) == bit32.bor(B.Forward, B.Walk))
	check("crouched", TouchRules.flags(none, 0, 0, true, true) == B.Crouch)
	check(
		"the left thumb's FIRE fires too, and AIM is right click",
		TouchRules.flags({ fire2 = true, aim = true }, 0, 0, false, true) == bit32.bor(B.Fire, B.AltFire)
	)
	check(
		"the abilities, and RELOAD",
		TouchRules.flags({ c = true, q = true, e = true, x = true, reload = true }, 0, 0, false, true)
			== bit32.bor(B.AbilityC, B.AbilityQ, B.AbilityE, B.Ultimate, B.Reload)
	)
	check(
		"USE is F, SPIKE is 4, DROP is G",
		TouchRules.flags({ use = true, spike = true, drop = true }, 0, 0, false, true) == bit32.bor(B.Interact, B.Use, B.Drop)
	)
	check(
		"dead, FIRE, AIM and USE are for watching, not flags",
		TouchRules.flags({ fire = true, fire2 = true, aim = true, use = true, jump = true }, 0, 0, false, false) == B.Jump
	)
end

-- The text scripted checks give ---------------------------------------------------------------

do
	local test = TouchRules.parse("0 1  0.2 -0.1 FIRE jump")
	check(
		"a touch screen from text: the stick, the look drag and the buttons held",
		test ~= nil and test.x == 0 and test.y == 1 and test.lx == 0.2 and test.ly == -0.1 and test.buttons.fire and test.buttons.jump
	)
	local wild = TouchRules.parse("3 -2 5 0")
	check("the stick held to its throw, the look drag as given", wild ~= nil and wild.x == 1 and wild.y == -1 and wild.lx == 5)
	check("too few numbers isn't one", TouchRules.parse("0 1 0") == nil)
	check("nor is a button it doesn't know", TouchRules.parse("0 0 0 0 fire start") == nil)
	check("nor anything but text", TouchRules.parse(12) == nil and TouchRules.parse(nil) == nil)
end

return nil
