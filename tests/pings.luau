--!strict
-- Pings (system 52): what a ping along the crosshair marks (Pings.resolve):
-- the place it stops on, the level or a smoke's edge, an enemy in sight, the
-- spike or a gun, or with the wheel's option the place; the look it's
-- judged along (Pings.aimFrom); the limit (Pings.spend); the wheel's pick;
-- and what a marker says and how faded it is.

local Pings = require("../src/shared/Match/Pings")
local H = require("./Harness")

local check = H.check
local near = H.near
local P = Pings.Params

H.section("Pings (system 52)")

local function v(x: number, y: number, z: number): vector
	return vector.create(x, y, z)
end

local function str(p: vector): string
	return string.format("(%.2f, %.2f, %.2f)", p.x, p.y, p.z)
end

local function nearly(a: vector, b: vector): boolean
	return vector.magnitude(a - b) < 1e-6
end

local EYE = v(0, 1.6, 0)
local AHEAD = v(0, 0, -1)

local function open(_: vector, _: vector): boolean
	return false
end

-- A wall across the way at z = `z`: in the way of anything past it.
local function wallAt(z: number): (vector, vector) -> boolean
	return function(a: vector, b: vector): boolean
		return (a.z - z) * (b.z - z) < 0
	end
end

local function look(over: { [string]: any }): Pings.Look
	local l: Pings.Look = { eye = EYE, look = AHEAD, level = nil, clouds = {}, enemies = {}, items = {}, hidden = open, option = nil }
	for k, value in over do
		(l :: any)[k] = value
	end
	return l
end

local function body(id: number, x: number, z: number, crouch: number?): Pings.Body
	return { id = id, pose = { position = v(x, 0, z), yaw = 0, crouchAlpha = crouch or 0 } }
end

-- Its numbers -------------------------------------------------------------------

do
	local statuses = { confirmed = true, community = true, estimate = true }
	local bad = {}
	for name, param in P do
		if not statuses[param.status] or #param.source == 0 or param.value <= 0 then
			table.insert(bad, name)
		end
	end
	table.sort(bad)
	check("every number has a status and a source", #bad == 0, table.concat(bad, ", "))
	check("a tap is quicker than holding Z for the wheel", P.hold.value > 0.1 and P.hold.value < 0.5)
	check("a ping fades within its time", P.fadeOut.value < P.duration.value)
	check("four options on the wheel, clockwise from the top", table.concat(Pings.OPTIONS, " ") == "danger watching pushing help")
end

-- The place it stops on -----------------------------------------------------------

do
	local ping = Pings.resolve(look({ level = 10 }))
	check("a wall 10 m ahead: a place on it", ping ~= nil and ping.kind == "place" and nearly(ping.position, v(0, 1.6, -10)))
	check("with no option", ping ~= nil and ping.option == nil)
	check("nothing within reach (the sky): nothing pinged", Pings.resolve(look({})) == nil)
	check("nor past it", Pings.resolve(look({ level = P.reach.value + 1 })) == nil)
	ping = Pings.resolve(look({ level = P.reach.value }))
	check("a wall at the edge of its reach is pinged", ping ~= nil and ping.kind == "place")
end

-- Smokes ------------------------------------------------------------------------

do
	local smoke = { centre = v(0, 1.6, -6), radius = 2 }
	check("a ray goes into a smoke at its edge", near(Pings.cloudAt(EYE, AHEAD, smoke) or -1, 4, 1e-9))
	check("and out of it from inside", near(Pings.cloudAt(v(0, 1.6, -5), AHEAD, smoke) or -1, 3, 1e-9))
	check("a smoke behind the eye is no stop", Pings.cloudAt(v(0, 1.6, -9), AHEAD, smoke) == nil)
	check("nor one beside the way", Pings.cloudAt(EYE, AHEAD, { centre = v(3, 1.6, -6), radius = 2 }) == nil)
	check("nor one of no size", Pings.cloudAt(EYE, AHEAD, { centre = v(0, 1.6, -6), radius = 0 }) == nil)

	local ping = Pings.resolve(look({ level = 10, clouds = { smoke } }))
	check(
		"a smoke before a wall: the ping lands on the smoke (Patch 9.11)",
		ping ~= nil and ping.kind == "place" and nearly(ping.position, v(0, 1.6, -4)),
		if ping then str(ping.position) else "nil"
	)
	ping = Pings.resolve(look({ clouds = { smoke } }))
	check("even with nothing behind it", ping ~= nil and nearly(ping.position, v(0, 1.6, -4)))
	ping = Pings.resolve(look({ level = 3, clouds = { smoke } }))
	check("a wall before the smoke: on the wall", ping ~= nil and nearly(ping.position, v(0, 1.6, -3)))
	ping = Pings.resolve(look({ level = 10, clouds = { { centre = EYE, radius = 2.5 } } }))
	check("from inside one: where the ray comes out of it", ping ~= nil and nearly(ping.position, v(0, 1.6, -2.5)))
	ping = Pings.resolve(look({ level = 20, clouds = { smoke }, enemies = { body(7, 0, -8) } }))
	check(
		"an enemy behind a smoke isn't pinged: the smoke is",
		ping ~= nil and ping.kind == "place" and nearly(ping.position, v(0, 1.6, -4))
	)
end

-- Enemies -----------------------------------------------------------------------------

do
	local ping = Pings.resolve(look({ enemies = { body(7, 0, -8) } }))
	check(
		"an enemy in sight, the crosshair on them: ENEMY",
		ping ~= nil and ping.kind == "enemy" and ping.target == 7 and nearly(ping.position, v(0, 1.6, -8)),
		if ping then ping.kind .. " " .. str(ping.position) else "nil"
	)
	ping = Pings.resolve(look({ level = 20, enemies = { body(7, 0.3, -8) } }))
	check("the crosshair a little beside them still pings them", ping ~= nil and ping.kind == "enemy")
	ping = Pings.resolve(look({ level = 20, enemies = { body(7, 0.6, -8) } }))
	check("further beside them, the wall behind", ping ~= nil and ping.kind == "place" and nearly(ping.position, v(0, 1.6, -20)))
	ping = Pings.resolve(look({ level = 5, enemies = { body(7, 0, -8) } }))
	check("an enemy behind a wall: the wall", ping ~= nil and ping.kind == "place" and nearly(ping.position, v(0, 1.6, -5)))
	ping = Pings.resolve(look({ level = 8, enemies = { body(7, 0, -7.8) } }))
	check("one against the wall the crosshair's on: them", ping ~= nil and ping.kind == "enemy")
	ping = Pings.resolve(look({ level = 8, enemies = { body(7, 0, -8.3) }, hidden = wallAt(-8) }))
	check("one just past it, out of sight: the wall", ping ~= nil and ping.kind == "place")
	ping = Pings.resolve(look({
		level = 20,
		enemies = { body(7, 0, -8) },
		hidden = function(_: vector, _: vector): boolean
			return true
		end,
	}))
	check(
		"one hidden from the eye (a wall of fire): the place behind",
		ping ~= nil and ping.kind == "place" and nearly(ping.position, v(0, 1.6, -20))
	)
	ping = Pings.resolve(look({ level = 20, enemies = { body(8, 0, -12), body(7, 0, -8) } }))
	check("of two, the nearer", ping ~= nil and ping.target == 7)
	-- Over a crouched head.
	ping = Pings.resolve(look({ eye = v(0, 1.75, 0), level = 20, enemies = { body(7, 0, -8, 1) } }))
	check("over a crouched enemy's head: not them", ping ~= nil and ping.kind == "place")
	ping = Pings.resolve(look({ eye = v(0, 1.75, 0), level = 20, enemies = { body(7, 0, -8) } }))
	check("but on one standing there, them", ping ~= nil and ping.kind == "enemy")
end

-- The spike and guns ----------------------------------------------------------------

do
	-- Looking down at the floor 0.2 m short of a gun 5 m away.
	local down = vector.normalize(v(0, -1.6, -4.8))
	local floor = vector.magnitude(v(0, -1.6, -4.8))
	local gun: Pings.Item = { kind = "gun", id = 3, weapon = "vandal", middle = v(0, 0.05, -5) }
	local ping = Pings.resolve(look({ look = down, level = floor, items = { gun } }))
	check(
		"a gun on the ground, the crosshair just short of it: the gun",
		ping ~= nil and ping.kind == "gun" and ping.target == 3 and ping.weapon == "vandal" and nearly(ping.position, gun.middle),
		if ping then ping.kind else "nil"
	)
	check("its marker says its name", ping ~= nil and Pings.word(ping) == "VANDAL")
	local wide = vector.normalize(v(0, -1.6, -4.8) + v(1, 0, 0))
	ping = Pings.resolve(look({ look = wide, level = 5, items = { gun } }))
	check("the crosshair well beside it: the floor", ping ~= nil and ping.kind == "place")
	ping = Pings.resolve(look({ look = down, level = floor, items = { gun }, hidden = wallAt(-2) }))
	check("one out of sight isn't pinged", ping ~= nil and ping.kind == "place")

	local spike: Pings.Item = { kind = "spike", middle = v(0, 0.15, -5) }
	ping = Pings.resolve(look({ look = down, level = floor, items = { spike } }))
	check("the spike on the ground: SPIKE", ping ~= nil and ping.kind == "spike" and Pings.word(ping) == "SPIKE")
	ping = Pings.resolve(look({ look = down, level = floor, items = { gun }, enemies = { body(7, 0, -3) } }))
	check("an enemy before a gun: the enemy", ping ~= nil and ping.kind == "enemy")
	ping = Pings.resolve(look({ look = down, level = floor, items = { gun }, enemies = { body(7, 0, -9) } }))
	check("a gun before an enemy: the gun", ping ~= nil and ping.kind == "gun")
end

-- The wheel's options ---------------------------------------------------------------

do
	local ping = Pings.resolve(look({ level = 10, option = "danger" }))
	check(
		"an option pings the place, with it",
		ping ~= nil and ping.kind == "place" and ping.option == "danger" and nearly(ping.position, v(0, 1.6, -10))
	)
	ping = Pings.resolve(look({ level = 20, option = "watching", enemies = { body(7, 0, -8) } }))
	check("even with the crosshair on an enemy", ping ~= nil and ping.kind == "place" and ping.option == "watching")
	ping = Pings.resolve(look({ level = 10, clouds = { { centre = v(0, 1.6, -6), radius = 2 } }, option = "help" }))
	check("and on a smoke's edge", ping ~= nil and nearly(ping.position, v(0, 1.6, -4)) and Pings.word(ping) == "NEED SUPPORT")
	check("and nothing into the sky", Pings.resolve(look({ option = "pushing" })) == nil)
	check("its options", Pings.isOption("danger") and Pings.isOption("help") and not Pings.isOption("here") and not Pings.isOption(3))
	check("its kinds", Pings.isKind("place") and Pings.isKind("map") and not Pings.isKind("danger") and not Pings.isKind(nil))
end

-- The look it's judged along --------------------------------------------------------

do
	local own = AHEAD
	local turned = vector.normalize(v(math.sin(math.rad(6)), 0, -math.cos(math.rad(6))))
	check("a look a little on from the server's last is taken", nearly(Pings.aimFrom(own, turned), turned))
	local far = vector.normalize(v(math.sin(math.rad(20)), 0, -math.cos(math.rad(20))))
	check("one further off isn't: the server's is", nearly(Pings.aimFrom(own, far), own))
	check("nor one of nothing", nearly(Pings.aimFrom(own, v(0, 0, 0)), own))
	check("nor one that isn't a number", nearly(Pings.aimFrom(own, v(0 / 0, 0, 0)), own))
	check("a long one is made a unit's length", nearly(Pings.aimFrom(own, v(0, 0, -5)), own))
end

-- The limit ------------------------------------------------------------------------

do
	local b = Pings.newBudget(100)
	local spent = 0
	for _ = 1, 6 do
		if Pings.spend(b, 100) then
			spent += 1
		end
	end
	check("four at once, then no more", spent == 4, tostring(spent))
	check("none left", near(Pings.left(b, 100), 0, 1e-9))
	check("half of one back after 0.75 s, not enough", not Pings.spend(b, 100.75))
	check("one back after 1.5 s", Pings.spend(b, 101.5) and not Pings.spend(b, 101.5))
	check("all four back after a while, and no more", near(Pings.left(b, 200), 4, 1e-9))
	local c = Pings.newBudget(50)
	Pings.spend(c, 50)
	check("a clock going back gives none back", near(Pings.left(c, 40), 3, 1e-9))
end

-- The wheel's pick -------------------------------------------------------------------

do
	check("the mouse barely moved: nothing", Pings.pick(0, 0) == nil and Pings.pick(10, -20) == nil)
	check("up: Danger", Pings.pick(0, -40) == "danger")
	check("right: Watching", Pings.pick(40, 0) == "watching")
	check("down: Pushing", Pings.pick(0, 40) == "pushing")
	check("left: Need support", Pings.pick(-40, 0) == "help")
	local function at(degrees: number): string?
		local r = math.rad(degrees)
		return Pings.pick(50 * math.sin(r), -50 * math.cos(r))
	end
	check("up and a little right: Danger", at(40) == "danger")
	check("right and a little up: Watching", at(50) == "watching")
	check("down and a little left: Pushing", at(220) == "pushing")
	check("up and a little left: Danger", at(-40) == "danger")
	check("left and a little up: Need support", at(-50) == "help")
	check("not a number: nothing", Pings.pick(0 / 0, 0) == nil)
end

-- What a marker says, and how it fades ---------------------------------------------

do
	local here: Pings.Ping = { kind = "place", position = v(0, 0, 0) }
	check("a place says HERE", Pings.word(here) == "HERE" and Pings.tag(here) == "place")
	local seen: Pings.Ping = { kind = "enemy", position = v(0, 0, 0), target = 7 }
	check("an enemy says ENEMY", Pings.word(seen) == "ENEMY" and Pings.tag(seen) == "enemy")
	local warned: Pings.Ping = { kind = "place", option = "danger", position = v(0, 0, 0) }
	check("an option says its word", Pings.word(warned) == "DANGER" and Pings.tag(warned) == "danger")
	local unknown: Pings.Ping = { kind = "gun", weapon = "nope", position = v(0, 0, 0) }
	check("a gun of no known kind says GUN", Pings.word(unknown) == "GUN")
	local mapped: Pings.Ping = { kind = "map", position = v(0, 0, 0) }
	check("the map's says nothing, as it's never in the world", Pings.word(mapped) == "" and Pings.tag(mapped) == "map")

	local far = 500
	check("a fresh one is solid", Pings.transparency(0, far) == 0)
	check("under the crosshair it fades (Patch 0.49)", near(Pings.transparency(0, 10), P.faded.value, 1e-9))
	check("at the edge of the crosshair's reach too", near(Pings.transparency(1, P.fadeNear.value), P.faded.value, 1e-9))
	check("further out it doesn't", Pings.transparency(1, P.fadeNear.value + 1) == 0)
	local half = P.duration.value - P.fadeOut.value / 2
	check("half way through its fade, half gone", near(Pings.transparency(half, far), 0.5, 1e-9))
	check("and under the crosshair then, more", near(Pings.transparency(half, 0), 1 - 0.5 * (1 - P.faded.value), 1e-9))
	check("gone once its time's up", Pings.transparency(P.duration.value, far) == 1 and Pings.transparency(P.duration.value + 3, 0) == 1)
end

return nil
