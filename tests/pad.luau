--!strict
-- A gamepad (system 68): the sticks as keys and turns, the bumpers' chord
-- for the ultimate, taps and holds, what LT and RS do with each weapon,
-- the scope held as LT is by alt fire pressed a tick at a time on the
-- weapons' own zoom, Y's swap, and the text scripted checks give a pad.

local FakeWorld = require("./FakeWorld")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PadConfig = require("../src/shared/Input/PadConfig")
local PadRules = require("../src/shared/Input/PadRules")
local PlayerSim = require("../src/shared/PlayerSim")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local H = require("./Harness")

local check, near = H.check, H.near

local B = PlayerSim.Buttons
local P = PadConfig.Params
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local floor = FakeWorld.new():addFloor()

H.section("Controller tests")

-- The text scripted checks give ---------------------------------------------------

do
	local pad = PadRules.parse("0 1  0 0 0 1 a LB")
	check(
		"a pad from text: the sticks, the triggers and the buttons held",
		pad ~= nil and pad.ly == 1 and pad.lx == 0 and pad.rt == 1 and pad.buttons.a == true and pad.buttons.lb == true
	)
	local wild = PadRules.parse("3 -2 0 0 -1 9")
	check("held to the sticks' and the triggers' travel", wild ~= nil and wild.lx == 1 and wild.ly == -1 and wild.lt == 0 and wild.rt == 1)
	check("too few numbers isn't a pad", PadRules.parse("0 1 0 0 0") == nil)
	check("nor is a button it doesn't know", PadRules.parse("0 0 0 0 0 0 a start") == nil)
	check("nor anything but text", PadRules.parse(12) == nil and PadRules.parse(nil) == nil)
end

-- The left stick ---------------------------------------------------------------------

do
	local function keys(x: number, y: number): number
		return (PadRules.move(x, y))
	end
	check("in the middle, no keys", keys(0, 0) == 0)
	check("within the dead zone, no keys", keys(P.moveDead.value * 0.9, 0) == 0)
	check("all the way up runs ahead", keys(0, 1) == B.Forward and not select(2, PadRules.move(0, 1)))
	check("half way up walks ahead", keys(0, 0.45) == B.Forward and select(2, PadRules.move(0, 0.45)) == true)
	local round = {
		{ 0, 1, B.Forward },
		{ 0.7, 0.7, bit32.bor(B.Forward, B.Right) },
		{ 1, 0, B.Right },
		{ 0.7, -0.7, bit32.bor(B.Back, B.Right) },
		{ 0, -1, B.Back },
		{ -0.7, -0.7, bit32.bor(B.Back, B.Left) },
		{ -1, 0, B.Left },
		{ -0.7, 0.7, bit32.bor(B.Forward, B.Left) },
	}
	local all = true
	for _, way in round do
		all = all and keys(way[1], way[2]) == way[3]
	end
	check("each of the 8 directions holds its keys", all)
	local function at(degrees: number): number
		local r = math.rad(degrees)
		return keys(math.sin(r), math.cos(r))
	end
	check(
		"each direction is the nearest: 20 degrees off ahead is ahead, 25 is ahead and right",
		at(20) == B.Forward and at(25) == bit32.bor(B.Forward, B.Right) and at(-20) == B.Forward
	)
	check("and just short of straight back either side is back", at(179) == B.Back and at(-179) == B.Back)
end

-- The right stick ---------------------------------------------------------------------

do
	local x, y, past = PadRules.curve(0.1, 0, 0.12, 2)
	check("within its dead zone it turns nothing", x == 0 and y == 0 and past == 0)
	x, y, past = PadRules.curve(0, 1, 0.12, 2)
	check("all the way over, all of it", near(y, 1, 1e-9) and x == 0 and near(past, 1, 1e-9))
	x, y, past = PadRules.curve(0.56, 0, 0.12, 2)
	check("half way past the dead zone, a quarter of it", near(past, 0.5, 1e-9) and near(x, 0.25, 1e-9), tostring(x))
	x, y = PadRules.curve(0.6, 0.8, 0, 1)
	check("along the way it's tilted", near(x, 0.6, 1e-9) and near(y, 0.8, 1e-9))

	-- A second of the stick held as given, in frames of 1/60 s.
	local function second(sx: number, sy: number, scale: number, ramp: boolean, invert: boolean): (number, number)
		local look = PadRules.newLook()
		local yaw, pitch = 0, 0
		for _ = 1, 60 do
			local dy, dp = PadRules.look(look, sx, sy, 1 / 60, 200, scale, ramp, invert)
			yaw += dy
			pitch += dp
		end
		return yaw, pitch
	end
	local yaw = second(1, 0, 1, false, false)
	check("all the way right, the look speed a second", near(yaw, 200, 1e-6), tostring(yaw))
	local focused = second(1, 0, 0.5, false, false)
	check("in Focus, its share of it", near(focused, 100, 1e-6))
	local _, up = second(0, 1, 1, false, false)
	local _, inverted = second(0, 1, 1, false, true)
	check("up looks up, and inverted, down", near(up, 200, 1e-6) and near(inverted, -200, 1e-6))
	local ramped = second(1, 0, 1, true, false)
	local full = 1 - P.rampDelay.value - P.rampTime.value
	check(
		"held all the way over, sideways it speeds up to the ramp's boost",
		near(ramped, 200 * (P.rampDelay.value + P.rampBoost.value * full + (1 + P.rampBoost.value) / 2 * P.rampTime.value), 4),
		tostring(ramped)
	)
	local _, upRamped = second(0, 1, 1, true, false)
	check("but not up and down", near(upRamped, 200, 1e-6))
	local slow = second(0.8, 0, 1, true, false)
	check("nor short of all the way over", slow < 200 * 0.8)
end

-- The bumpers ---------------------------------------------------------------------------

do
	local window = P.chord.value
	local s = PadRules.newBumpers()
	local held = PadRules.bumpers(s, true, false, 0)
	check("LB down: its ability waits for RB", held == 0)
	held = PadRules.bumpers(s, true, false, window + 0.01)
	check("then holds Q", held == B.AbilityQ)
	held = PadRules.bumpers(s, false, false, 1)
	check("and lets it go", held == 0)

	s = PadRules.newBumpers()
	PadRules.bumpers(s, true, false, 0)
	local taps
	held, taps = PadRules.bumpers(s, false, false, window / 2)
	check("LB tapped quicker than the wait still presses Q", held == 0 and taps == B.AbilityQ)

	s = PadRules.newBumpers()
	held = PadRules.bumpers(s, true, true, 0)
	check("both at once: the ultimate", held == B.Ultimate)
	s = PadRules.newBumpers()
	PadRules.bumpers(s, true, false, 0)
	held = PadRules.bumpers(s, true, true, window / 2)
	check("RB within the wait: the ultimate, and neither ability", held == B.Ultimate)
	held = PadRules.bumpers(s, true, true, 0.5)
	check("for as long as both are held", held == B.Ultimate)
	held, taps = PadRules.bumpers(s, false, true, 0.6)
	check("one let go ends it, and the other does nothing", held == 0 and taps == 0)
	held = PadRules.bumpers(s, false, true, 1)
	check("however long it's held", held == 0)
	PadRules.bumpers(s, false, false, 1.1)
	held = PadRules.bumpers(s, false, true, 1.2)
	held = PadRules.bumpers(s, false, true, 1.2 + window + 0.01)
	check("until it's let go: then it's E again", held == B.AbilityE)

	s = PadRules.newBumpers()
	PadRules.bumpers(s, false, true, 0)
	held = PadRules.bumpers(s, true, true, window + 0.02)
	check("RB, then LB after the wait: E, and LB's own wait", held == B.AbilityE)
	held = PadRules.bumpers(s, true, true, 2 * window + 0.05)
	check("then both abilities", held == bit32.bor(B.AbilityQ, B.AbilityE))
end

-- Taps and holds ---------------------------------------------------------------------------

do
	local h = PadRules.newHold()
	check("down: nothing yet", PadRules.hold(h, true, 0) == nil)
	check("let go before the hold: a tap", PadRules.hold(h, false, P.hold.value / 2) == "tap")
	PadRules.hold(h, true, 1)
	check("held to the hold: a hold, once", PadRules.hold(h, true, 1 + P.hold.value) == "hold")
	check("then nothing while it's held", PadRules.hold(h, true, 2) == nil)
	check("nor as it's let go", PadRules.hold(h, false, 3) == nil)
	PadRules.hold(h, true, 4)
	h.taken = true
	check("taken: no hold", PadRules.hold(h, true, 5) == nil)
	check("and no tap", PadRules.hold(h, false, 5.1) == nil)
	PadRules.hold(h, true, 6)
	check("and the next press is its own again", PadRules.hold(h, false, 6.1) == "tap")
end

-- What LT does with each weapon ------------------------------------------------------------

do
	local function roleOf(id: string, holding: boolean?): PadRules.Role
		local def = WeaponConfig.get(id)
		return PadRules.role(def.category, def.ads ~= nil, WeaponConfig.altMode(def) ~= nil, holding == true)
	end
	check("the Vandal: Focus, and aiming down sights with RS", roleOf("vandal") == "ads")
	check("the Operator and the Marshal: their scopes", roleOf("operator") == "scope" and roleOf("marshal") == "scope")
	check("the Classic: Focus, and its burst with RS", roleOf("classic") == "alt")
	check("the Shorty: Focus alone", roleOf("shorty") == "focus")
	check("the knife: alt fire", roleOf("knife") == "hand")
	check("Blade Storm's knives: alt fire", roleOf("kunai") == "hand")
	check("anything with an ability in hand: alt fire", roleOf("vandal", true) == "hand")

	local a = PadRules.newAim()
	local wanted, alt, focus, taken = PadRules.aim(a, "scope", "operator", 2, true, false, false)
	check("a scope: LT held wants its first zoom", wanted == 1 and not alt and not focus and taken)
	wanted = PadRules.aim(a, "scope", "operator", 2, true, true, true)
	check("RS with it, the second", wanted == 2)
	wanted = PadRules.aim(a, "scope", "operator", 2, true, true, true)
	check("RS again, the first", wanted == 1)
	PadRules.aim(a, "scope", "operator", 2, true, true, true)
	wanted, _, _, taken = PadRules.aim(a, "scope", "operator", 2, false, false, false)
	check("LT let go: no zoom, and RS is use again", wanted == 0 and not taken)
	wanted = PadRules.aim(a, "scope", "operator", 2, true, false, false)
	check("and LT again: the first, not the second", wanted == 1)
	wanted = PadRules.aim(a, "scope", "marshal", 1, true, true, true)
	check("a scope with one zoom: RS changes nothing", wanted == 1)

	a = PadRules.newAim()
	wanted, alt, focus, taken = PadRules.aim(a, "ads", "vandal", 1, true, false, false)
	check("a rifle: LT held is Focus, its sights left alone", wanted == 0 and focus and not alt and taken)
	wanted, _, focus = PadRules.aim(a, "ads", "vandal", 1, true, true, true)
	check("RS with it aims down sights, out of Focus", wanted == 1 and not focus)
	wanted, _, focus = PadRules.aim(a, "ads", "vandal", 1, true, true, false)
	check("and stays, RS held or not", wanted == 1 and not focus)
	wanted, _, focus = PadRules.aim(a, "ads", "vandal", 1, true, true, true)
	check("RS again: back to Focus", wanted == 0 and focus)
	PadRules.aim(a, "ads", "vandal", 1, true, true, true)
	wanted = PadRules.aim(a, "ads", "phantom", 1, true, false, false)
	check("another weapon starts unaimed", wanted == 0)
	PadRules.aim(a, "ads", "phantom", 1, true, true, true)
	wanted, _, focus, taken = PadRules.aim(a, "ads", "phantom", 1, false, false, false)
	check("LT let go: neither", wanted == 0 and not focus and not taken)

	a = PadRules.newAim()
	wanted, alt, focus, taken = PadRules.aim(a, "alt", "classic", 0, true, true, true)
	check("the Classic: RS with LT is its alt fire, in Focus", wanted == nil and alt and focus and taken)
	wanted, alt, focus, taken = PadRules.aim(a, "alt", "classic", 0, false, true, true)
	check("RS alone isn't", not alt and not focus and not taken)
	wanted, alt, focus, taken = PadRules.aim(a, "hand", "knife", 0, true, true, true)
	check("the knife: LT is alt fire, and RS is still use", wanted == nil and alt and not focus and not taken)
	wanted, alt, focus, taken = PadRules.aim(a, "focus", "shorty", 0, true, true, true)
	check("Focus alone leaves RS to use", wanted == nil and not alt and focus and not taken)
end

-- The zoom, by alt fire pressed a tick at a time ---------------------------------------

do
	local function input(buttons: number, slot: number)
		return { seq = 0, buttons = buttons, slot = slot, yaw = 0, pitch = 0, viewTime = 0 }
	end
	-- A player holding `id` in its slot, drawn.
	local function holding(id: string): PlayerSim.State
		local def = WeaponConfig.get(id)
		local loadout = { if def.slot == 1 then id else "vandal", if def.slot == 2 then id else "classic", "knife" }
		local s = PlayerSim.new(vector.create(0, 0.02, 0), loadout, 1)
		s.weapons.equipped = def.slot
		for _ = 1, math.ceil(def.equipTime.value / DT) + 4 do
			PlayerSim.step(s, input(0, def.slot), cfg, floor, DT)
		end
		return s
	end
	-- Ticks pressing alt fire as PadRules.pulse says, until the zoom is
	-- `wanted`: the presses it took (nil past 20 ticks), and whether each
	-- came a tick after the last let go.
	local function bring(s: PlayerSim.State, wanted: number): (number?, boolean)
		local def = PlayerSim.def(s)
		local levels = if def.ads then #def.ads.zoom else 0
		local pressed = false
		local presses, apart = 0, true
		for _ = 1, 20 do
			if s.weapons.scoped == wanted and not pressed then
				return presses, apart
			end
			local was = pressed
			pressed = PadRules.pulse(wanted, s.weapons.scoped, levels, pressed)
			if pressed then
				presses += 1
				apart = apart and not was
			end
			PlayerSim.step(s, input(if pressed then B.AltFire else 0, s.weapons.equipped), cfg, floor, DT)
		end
		return nil, apart
	end
	local op = holding("operator")
	local presses = bring(op, 1)
	check("the Operator scoped with one press", presses == 1 and op.weapons.scoped == 1)
	local apart
	presses, apart = bring(op, 0)
	check("and back out with two, a tick apart (its second zoom on the way)", presses == 2 and apart and op.weapons.scoped == 0)
	bring(op, 1)
	presses = bring(op, 2)
	check("from its first zoom to its second, one", presses == 1 and op.weapons.scoped == 2)
	presses = bring(op, 0)
	check("and out of its second, one", presses == 1 and op.weapons.scoped == 0)
	local vandal = holding("vandal")
	presses = bring(vandal, 1)
	local back = bring(vandal, 0)
	check("a rifle's sights: one press in and one out", presses == 1 and back == 1 and vandal.weapons.scoped == 0)
	check("nothing pressed with no zoom to have", not PadRules.pulse(1, 0, 0, false))
	check("nor for a level the weapon hasn't", not PadRules.pulse(3, 0, 2, false))
end

-- Y's swap ------------------------------------------------------------------------------------

do
	local full = { "vandal", "classic", "knife", "", "" }
	local light = { "", "classic", "knife", "", "" }
	check("from the primary, the sidearm", PadRules.swap(1, full) == 2)
	check("from the sidearm, the primary", PadRules.swap(2, full) == 1)
	check("from the knife or the spike, the primary", PadRules.swap(3, full) == 1 and PadRules.swap(4, full) == 1)
	check("with no primary, the sidearm", PadRules.swap(3, light) == 2 and PadRules.swap(2, light) == 2)
	check("with no sidearm, the primary stays", PadRules.swap(1, { "vandal", "", "knife", "", "" }) == 1)
end

return nil
