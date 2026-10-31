--!strict
-- A gamepad, played as the reference's console version plays it (system
-- 68), on its default layout, the Traditional preset (primagames.com's
-- table of it; dexerto.com and esports.net put a few buttons elsewhere,
-- docs/research/68-controller.md):
--   * the left stick moves toward the nearest of the 8 directions the keys
--     give, and walks tilted only part of the way over (ours: the console
--     version leaves walking to "Walk While in Focus")
--   * the right stick turns the view, the further it's tilted the faster,
--     and faster still held all the way over for a moment (ours)
--   * RT fires. LT held is Focus, which turns the view slower ('When
--     pressing the trigger, the game quickly shifts how sensitive the
--     aiming joystick is', Kotaku), and with it RS is alt fire ("ADS" is
--     LT + RS): it aims down sights, or fires the Classic's burst. A
--     sniper's LT held is its scope ("Focus / Sniper Scope (Hold)"), and
--     RS with it its second zoom. With the knife, Blade Storm's knives, an
--     ability's weapon or an ability in hand, LT is alt fire itself, as
--     right click is
--   * A jumps, L3 crouches and crouches no more ("Crouch (Toggle)"), X
--     reloads, RS uses (F, "Activate / Use"), D-pad Down is the spike's
--     (4), D-pad Left drops (G) and D-pad Up pings (Z, held for the wheel)
--   * LB, RB and B are the abilities ("Ability 1", 2 and 3: Q, E and C),
--     and LB and RB together the ultimate (X): each bumper's ability waits
--     PadConfig's `chord` for the other
--   * Y switches between the primary and the sidearm, and held, draws the
--     knife ("Equip Secondary / Equip Melee (Hold)")
-- Gamepad reads the pad, and does what this says with it.
--
-- No Roblox APIs here.

local PadConfig = require("./PadConfig")
local PlayerSim = require("../PlayerSim")

local B = PlayerSim.Buttons
local P = PadConfig.Params

local PadRules = {}

-- The buttons, by the names a Pad has them under. LT and RT are the
-- triggers, held past PadConfig's `trigger` (Gamepad adds them).
PadRules.BUTTONS = table.freeze({ "a", "b", "x", "y", "lb", "rb", "lt", "rt", "l3", "r3", "up", "down", "left", "right", "select" })

-- A pad as it's held: each stick from -1 to 1 (right and up), each trigger
-- from 0 to 1, and the buttons held, by name.
export type Pad = {
	lx: number,
	ly: number,
	rx: number,
	ry: number,
	lt: number,
	rt: number,
	buttons: { [string]: boolean },
}

function PadRules.newPad(): Pad
	return { lx = 0, ly = 0, rx = 0, ry = 0, lt = 0, rt = 0, buttons = {} }
end

-- A pad from text, for scripted checks (TestAim's VFTestPad): the left
-- stick's x and y, the right's, the left trigger and the right, and then
-- the names of the buttons held, all apart by spaces ("0 1 0 0 0 1 a lb":
-- running ahead, firing, jumping, with LB held); nil for anything else.
function PadRules.parse(text: any): Pad?
	if type(text) ~= "string" then
		return nil
	end
	local words = {}
	for word in string.gmatch(text, "%S+") do
		table.insert(words, word)
	end
	local numbers = {}
	for i = 1, 6 do
		local n = tonumber(words[i])
		if n == nil or n ~= n then
			return nil
		end
		numbers[i] = n
	end
	local pad = PadRules.newPad()
	pad.lx, pad.ly = math.clamp(numbers[1], -1, 1), math.clamp(numbers[2], -1, 1)
	pad.rx, pad.ry = math.clamp(numbers[3], -1, 1), math.clamp(numbers[4], -1, 1)
	pad.lt, pad.rt = math.clamp(numbers[5], 0, 1), math.clamp(numbers[6], 0, 1)
	for i = 7, #words do
		local name = string.lower(words[i])
		if not table.find(PadRules.BUTTONS, name) then
			return nil
		end
		pad.buttons[name] = true
	end
	return pad
end

-- The keys each of the 8 directions holds, from ahead round to the right.
local DIRECTIONS = {
	B.Forward,
	bit32.bor(B.Forward, B.Right),
	B.Right,
	bit32.bor(B.Back, B.Right),
	B.Back,
	bit32.bor(B.Back, B.Left),
	B.Left,
	bit32.bor(B.Forward, B.Left),
}

-- The left stick at (x, y) as the movement keys it holds: none within
-- PadConfig's `moveDead` of its middle, else those of the nearest of the
-- 8 directions; and whether it walks, tilted less than `walkTilt`.
function PadRules.move(x: number, y: number): (number, boolean)
	local tilt = math.sqrt(x * x + y * y)
	if tilt < P.moveDead.value then
		return 0, false
	end
	-- 0 ahead, a quarter turn to the right.
	local angle = math.atan2(x, y)
	local sector = math.floor(angle / (math.pi / 4) + 0.5) % 8
	return DIRECTIONS[sector + 1], tilt < P.walkTilt.value
end

-- A stick at (x, y), as far as it's tilted past `dead` (0 to 1 of the
-- rest of its throw) to the power `power`, along the way it's tilted; and
-- how far past `dead` it is, before the power.
function PadRules.curve(x: number, y: number, dead: number, power: number): (number, number, number)
	local tilt = math.sqrt(x * x + y * y)
	if tilt <= dead then
		return 0, 0, 0
	end
	local past = math.min((tilt - dead) / (1 - dead), 1)
	local scale = past ^ power / tilt
	return x * scale, y * scale, past
end

-- The right stick's ramp: seconds it's been held all the way over.
export type Look = { full: number }

function PadRules.newLook(): Look
	return { full = 0 }
end

-- Degrees the view turns in `dt` seconds, to the right and up, for the
-- right stick at (x, y): `speed` degrees a second at full tilt (the
-- player's padLook), times `scale` (Focus's padFocus, else 1), and held
-- all the way over, sideways faster by the ramp while `ramp` (not in Focus
-- or zoomed). Inverted, up on the stick turns it down.
function PadRules.look(
	look: Look,
	x: number,
	y: number,
	dt: number,
	speed: number,
	scale: number,
	ramp: boolean,
	invert: boolean
): (number, number)
	local cx, cy, past = PadRules.curve(x, y, P.lookDead.value, P.lookCurve.value)
	if ramp and past >= P.rampFrom.value then
		look.full += dt
	else
		look.full = 0
	end
	local boost = 1 + (P.rampBoost.value - 1) * math.clamp((look.full - P.rampDelay.value) / P.rampTime.value, 0, 1)
	local rate = speed * scale * dt
	return cx * rate * boost, cy * rate * (if invert then -1 else 1)
end

-- A bumper: when it went down (nil while it's up), and while it's held,
-- what it is: waiting to see if the other comes ("wait"), its own ability
-- ("own"), half of the ultimate's chord ("chord"), or nothing until it's
-- let go, the chord over ("spent").
type Bumper = { at: number?, role: ("wait" | "own" | "chord" | "spent")? }
export type Bumpers = { lb: Bumper, rb: Bumper }

function PadRules.newBumpers(): Bumpers
	return { lb = { at = nil, role = nil }, rb = { at = nil, role = nil } }
end

local function bumper(b: Bumper, other: Bumper, down: boolean, now: number): boolean
	if down and b.at == nil then
		b.at = now
		if other.role == "wait" and now - (other.at :: number) < P.chord.value then
			b.role, other.role = "chord", "chord"
		else
			b.role = "wait"
		end
	elseif down and b.role == "wait" and now - (b.at :: number) >= P.chord.value then
		b.role = "own"
	elseif not down and b.at ~= nil then
		local tapped = b.role == "wait"
		if b.role == "chord" and other.role == "chord" then
			other.role = "spent"
		end
		b.at, b.role = nil, nil
		return tapped
	end
	return false
end

-- The bumpers held as `lb` and `rb` at `now` (seconds): the flags they
-- hold (AbilityQ and AbilityE, or together Ultimate), and those of a
-- bumper let go before its chord's wait was out, to press once.
function PadRules.bumpers(s: Bumpers, lb: boolean, rb: boolean, now: number): (number, number)
	local taps = 0
	if bumper(s.lb, s.rb, lb, now) then
		taps = bit32.bor(taps, B.AbilityQ)
	end
	if bumper(s.rb, s.lb, rb, now) then
		taps = bit32.bor(taps, B.AbilityE)
	end
	local held = 0
	if s.lb.role == "own" then
		held = bit32.bor(held, B.AbilityQ)
	end
	if s.rb.role == "own" then
		held = bit32.bor(held, B.AbilityE)
	end
	if s.lb.role == "chord" and s.rb.role == "chord" then
		held = bit32.bor(held, B.Ultimate)
	end
	return held, taps
end

-- A button that's one thing tapped and another held (Y, Select): when it
-- went down, whether it's been held long enough, and whether something
-- else has taken it until it's let go (Select with the D-pad).
export type Hold = { at: number?, held: boolean, taken: boolean }

function PadRules.newHold(): Hold
	return { at = nil, held = false, taken = false }
end

-- The button held as `down` at `now`: "tap" as it's let go before
-- PadConfig's `hold`, "hold" once as that comes while it's held, and nil
-- otherwise, and at all once it's been taken (h.taken).
function PadRules.hold(h: Hold, down: boolean, now: number): ("tap" | "hold")?
	if down then
		if h.at == nil then
			h.at, h.held, h.taken = now, false, false
		end
		if not h.held and not h.taken and now - (h.at :: number) >= P.hold.value then
			h.held = true
			return "hold"
		end
		return nil
	end
	local tapped = h.at ~= nil and not h.held and not h.taken
	h.at, h.held, h.taken = nil, false, false
	return if tapped then "tap" else nil
end

-- What LT does with what's in hand:
--   "hand"  alt fire, as right click: the knife, Blade Storm's knives, an
--           ability's weapon, or an ability in hand
--   "scope" a sniper's scope, held, and with RS its second zoom
--   "ads"   Focus, and with RS aiming down sights
--   "alt"   Focus, and with RS alt fire (the Classic's burst)
--   "focus" Focus
export type Role = "hand" | "scope" | "ads" | "alt" | "focus"

-- LT's role for a weapon of `category` (WeaponConfig's), with zoom levels
-- (`ads`) or an alt fire of its own (`alt`), and an ability in hand or not.
function PadRules.role(category: string, ads: boolean, alt: boolean, holding: boolean): Role
	if holding or category == "melee" or category == "ultimate" or category == "ability" then
		return "hand"
	elseif ads and category == "sniper" then
		return "scope"
	elseif ads then
		return "ads"
	elseif alt then
		return "alt"
	end
	return "focus"
end

-- LT and RS as they bear on the weapon in hand: its id, and whether RS has
-- asked for aiming down sights or a scope's second zoom, until LT's let go
-- or the weapon's another.
export type Aim = { weapon: string, deep: boolean, ads: boolean }

function PadRules.newAim(): Aim
	return { weapon = "", deep = false, ads = false }
end

-- What LT and RS do with `weapon` in hand, LT's role for it `role`, with
-- `levels` zoom levels: LT held as `lt`, RS as `rs`, and RS just pressed
-- or not. Returns the zoom level wanted (nil where LT leaves the zoom
-- alone), whether alt fire is held, whether it's Focus, and whether RS is
-- LT's (and so not "use").
function PadRules.aim(
	a: Aim,
	role: Role,
	weapon: string,
	levels: number,
	lt: boolean,
	rs: boolean,
	rsPressed: boolean
): (number?, boolean, boolean, boolean)
	if a.weapon ~= weapon or not lt then
		a.weapon, a.deep, a.ads = weapon, false, false
	end
	if role == "hand" then
		return nil, lt, false, false
	elseif role == "scope" then
		if lt and rsPressed and levels >= 2 then
			a.deep = not a.deep
		end
		local wanted = if not lt then 0 elseif a.deep then 2 else 1
		return math.min(wanted, levels), false, false, lt
	elseif role == "ads" then
		if lt and rsPressed then
			a.ads = not a.ads
		end
		return if a.ads then math.min(1, levels) else 0, false, lt and not a.ads, lt
	elseif role == "alt" then
		return nil, lt and rs, lt, lt
	end
	return nil, false, lt, false
end

-- What to press this tick to bring the zoom from `scoped` to `wanted`, with
-- `levels` levels: alt fire, each press going up one (WeaponSim), counted
-- as it comes, so presses are a tick apart (`pressedLast`, the last
-- tick's); and going down, the zoom let go (Buttons.Unzoom), which takes it
-- straight off first, so a scope let go never passes through its second
-- zoom, nor its second zoom through none on the way back to its first.
-- Returns whether to press alt fire, and whether to let the zoom go.
function PadRules.pulse(wanted: number, scoped: number, levels: number, pressedLast: boolean): (boolean, boolean)
	if levels <= 0 or wanted == scoped or wanted < 0 or wanted > levels then
		return false, false
	elseif wanted < scoped then
		return wanted > 0 and not pressedLast, true
	end
	return not pressedLast, false
end

-- The slot Y tapped draws, with `equipped` in hand: the sidearm from the
-- primary, else the primary while there's one, else the sidearm.
function PadRules.swap(equipped: number, loadout: { string }): number
	if equipped == 1 then
		return if loadout[2] ~= "" then 2 else 1
	end
	return if loadout[1] ~= "" then 1 else 2
end

return PadRules
