--!strict
-- A touch screen, played as mobile shooters commonly play (system 71), on
-- TouchConfig's layout:
--   * a touch that starts on no button in the left of the screen moves, as
--     a stick whose middle is where it started: toward the nearest of the
--     8 directions the keys give, walking pushed only part of the way, as a
--     gamepad's left stick does (PadRules.move)
--   * a touch that starts on no button anywhere else turns the view as
--     it's dragged, the way the mouse does, PlayerSettings' touchLook
--     degrees for a drag the length of the screen's short side; so does
--     the fire button's touch, so a burst can follow what it's fired at
--   * the buttons do what their keys do: FIRE, AIM (right click), JUMP,
--     CROUCH (on, and off again), RELOAD, the abilities C, Q, E and X, USE
--     (F), SPIKE (4: drawn, and held to plant), DROP (G), SWAP (tapped,
--     the primary or the sidearm; held, the knife), PING (Z, held for the
--     wheel), a second FIRE for the left thumb, and down the left, BUY,
--     MAP, SCORES, AGENTS, PLAY and SETTINGS; with a menu up, CLOSE
-- TouchControls reads the touches and does what this says with them.
--
-- No Roblox APIs here.

local PadRules = require("./PadRules")
local PlayerSim = require("../PlayerSim")
local TouchConfig = require("./TouchConfig")

local B = PlayerSim.Buttons
local P = TouchConfig.Params

local TouchRules = {}

-- A button laid out: what it's called and says, its middle and its size in
-- pixels, and whether it's round (else a rounded box).
export type Spot = { name: string, label: string, x: number, y: number, w: number, h: number, round: boolean }
-- The HUD's band along the bottom: from `left` to `right`, below `top`.
export type Band = { left: number, right: number, top: number }
-- A touch screen held as given, for scripted checks (TestAim's
-- VFTestTouch): the stick's tilt (right and up, -1 to 1), the look drag's
-- speed (right and up, in screen short sides a second), and the buttons
-- held, by name.
export type Test = { x: number, y: number, lx: number, ly: number, buttons: { [string]: boolean } }

-- Every button's name.
local names = {}
for _, b in TouchConfig.Cluster do
	table.insert(names, b.name)
end
for _, pill in TouchConfig.Column do
	table.insert(names, pill.name)
end
table.insert(names, TouchConfig.FireLeft.name)
table.insert(names, TouchConfig.Close.name)
TouchRules.NAMES = table.freeze(names)

-- What each button holds down while it's held, as its key does: USE is F,
-- SPIKE is 4.
TouchRules.HOLDS = table.freeze({
	fire = B.Fire,
	fire2 = B.Fire,
	aim = B.AltFire,
	jump = B.Jump,
	reload = B.Reload,
	c = B.AbilityC,
	q = B.AbilityQ,
	e = B.AbilityE,
	x = B.Ultimate,
	use = B.Interact,
	spike = B.Use,
	drop = B.Drop,
} :: { [string]: number })
-- The buttons that do something else while you're dead: watch the next
-- player or the last, or take over the bot watched (TouchControls).
local WATCHING = { fire = true, fire2 = true, aim = true, use = true }

local function round(b: TouchConfig.Round, x: number, y: number, unit: number): Spot
	local across = 2 * b.r * unit
	return { name = b.name, label = b.label, x = x, y = y, w = across, h = across, round = true }
end

-- The HUD's band along the bottom (TouchConfig.Hud), in the safe area's
-- pixels: on a screen `fullW` by `fullH` pixels whose safe area's top left
-- corner is (`offX`, `offY`) on it.
function TouchRules.band(fullW: number, fullH: number, offX: number, offY: number): Band
	local hud = TouchConfig.Hud
	return { left = fullW / 2 - hud.half - offX, right = fullW / 2 + hud.half - offX, top = fullH - hud.rise - offY }
end

-- Every button laid out in a safe area `w` by `h` pixels, `unit` pixels a
-- unit (1% of the screen's short side): the right thumb's on the floor,
-- lifted over the HUD's `band` where it reaches under them; the second
-- fire button; the left column from under the minimap, whose bottom is
-- `top` pixels down (0 with none), into a second column where it would
-- reach the band or the bottom; and CLOSE.
function TouchRules.layout(w: number, h: number, unit: number, top: number, band: Band?): { Spot }
	local margin = P.margin.value * unit
	local spots: { Spot } = {}
	local extent = 0
	for _, b in TouchConfig.Cluster do
		extent = math.max(extent, b.dx + b.r)
	end
	local floor = h - margin
	if band and band.right > w - extent * unit - margin then
		floor = math.min(floor, band.top - margin)
	end
	for _, b in TouchConfig.Cluster do
		table.insert(spots, round(b, w - b.dx * unit, floor - b.dy * unit, unit))
	end
	local f = TouchConfig.FireLeft
	table.insert(spots, round(f, f.dx * unit, f.dy * unit, unit))

	local pillW, pillH, gap = P.pillW.value * unit, P.pillH.value * unit, P.pillGap.value * unit
	local first = top + margin
	local bottom = h - margin
	if band and band.left < margin + 2 * pillW + gap + margin then
		bottom = math.min(bottom, band.top - margin)
	end
	local x, y = margin, first
	for _, pill in TouchConfig.Column do
		if y + pillH > bottom and y > first then
			x += pillW + gap
			y = first
		end
		table.insert(
			spots,
			{ name = pill.name, label = pill.label, x = x + pillW / 2, y = y + pillH / 2, w = pillW, h = pillH, round = false }
		)
		y += pillH + gap
	end

	local c = TouchConfig.Close
	table.insert(spots, round(c, w - c.dx * unit, c.dy * unit, unit))
	return spots
end

-- Whether (x, y) is on `spot`.
function TouchRules.on(spot: Spot, x: number, y: number): boolean
	local dx, dy = x - spot.x, y - spot.y
	if spot.round then
		return dx * dx + dy * dy <= (spot.w / 2) ^ 2
	end
	return math.abs(dx) <= spot.w / 2 and math.abs(dy) <= spot.h / 2
end

-- The button among `spots` that (x, y) is on, if any, of those `shown`
-- says are (all, without it).
function TouchRules.hit(spots: { Spot }, x: number, y: number, shown: ((string) -> boolean)?): Spot?
	for _, spot in spots do
		if (shown == nil or shown(spot.name)) and TouchRules.on(spot, x, y) then
			return spot
		end
	end
	return nil
end

-- What a touch on no button at `x` across a safe area `w` wide does: moves
-- in the left of the screen, else looks.
function TouchRules.zone(w: number, x: number): "stick" | "look"
	return if x < P.stickZone.value * w then "stick" else "look"
end

-- The stick's tilt, right and up, 0 to 1 at most, for a touch (`dx`, `dy`)
-- pixels from its middle, right and down, with a throw of `radius` pixels.
function TouchRules.stick(dx: number, dy: number, radius: number): (number, number)
	local x, y = dx / radius, -dy / radius
	local tilt = math.sqrt(x * x + y * y)
	if tilt > 1 then
		x, y = x / tilt, y / tilt
	end
	return x, y
end

-- The mouse's counts, right and down, a drag of (`dx`, `dy`) pixels turns
-- the view by: `degrees` (the player's touchLook) for a drag of `short`
-- pixels, the screen's short side, at `perCount` degrees a count unzoomed
-- (PlayerSettings.degreesPerCount), so zoomed it turns slower as the mouse
-- does.
function TouchRules.look(dx: number, dy: number, short: number, degrees: number, perCount: number): (number, number)
	local scale = degrees / (short * perCount)
	return dx * scale, dy * scale
end

-- PlayerSim's flags for the buttons `held`, the stick at (`x`, `y`) and
-- crouched or not: the stick's movement keys and walk, the crouch, and
-- what each button held holds, but for those that watch while you're
-- dead.
function TouchRules.flags(held: { [string]: boolean }, x: number, y: number, crouched: boolean, alive: boolean): number
	local flags, walk = PadRules.move(x, y)
	if walk then
		flags = bit32.bor(flags, B.Walk)
	end
	if crouched then
		flags = bit32.bor(flags, B.Crouch)
	end
	for name, flag in TouchRules.HOLDS do
		if held[name] and (alive or not WATCHING[name]) then
			flags = bit32.bor(flags, flag)
		end
	end
	return flags
end

-- A touch screen from text, for scripted checks (TestAim's VFTestTouch):
-- the stick's x and y, the look drag's speed right and up, and then the
-- names of the buttons held, all apart by spaces ("0 1 0.2 0 fire jump":
-- running ahead, turning right a fifth of the screen's height a second,
-- firing and jumping); nil for anything else.
function TouchRules.parse(text: any): Test?
	if type(text) ~= "string" then
		return nil
	end
	local words = {}
	for word in string.gmatch(text, "%S+") do
		table.insert(words, word)
	end
	local numbers = {}
	for i = 1, 4 do
		local n = tonumber(words[i])
		if n == nil or n ~= n or n == math.huge or n == -math.huge then
			return nil
		end
		numbers[i] = n
	end
	local test: Test = {
		x = math.clamp(numbers[1], -1, 1),
		y = math.clamp(numbers[2], -1, 1),
		lx = numbers[3],
		ly = numbers[4],
		buttons = {},
	}
	for i = 5, #words do
		local name = string.lower(words[i])
		if not table.find(TouchRules.NAMES, name) then
			return nil
		end
		test.buttons[name] = true
	end
	return test
end

return TouchRules
