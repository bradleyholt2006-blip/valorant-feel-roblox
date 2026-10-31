--!strict
-- AFK in a match (system 70): a player's clock counts their time alive in a
-- round without playing, stops while they're dead or between rounds, and
-- starts over out of a match or as they play at anything: a key pressed or
-- let go, a look past MatchConfig.Afk.turn, a weapon asked for. Warned
-- after warnAfter, they're due out after outAfter more (AfkRules).

local AfkRules = require("../src/shared/Match/AfkRules")
local MatchConfig = require("../src/shared/Match/MatchConfig")
local MovementSim = require("../src/shared/Movement/MovementSim")
local H = require("./Harness")

local check = H.check

local A = MatchConfig.Afk
local B = MovementSim.Buttons
local WARN, OUT = A.warnAfter.value, A.outAfter.value
local TURN = A.turn.value

H.section("AFK tests")

-- Moves the clock on in steps of `dt` for `seconds`, in `state`: whether it
-- came due out on the way.
local function run(c: AfkRules.Clock, seconds: number, state: AfkRules.State, dt: number?): boolean
	local step = dt or 0.25
	local out = false
	for _ = 1, math.floor(seconds / step + 0.5) do
		out = AfkRules.step(c, step, state, WARN, OUT) == "out" or out
	end
	return out
end

-- The clock ------------------------------------------------------------------------------------

do
	local c = AfkRules.new()
	local out = run(c, WARN - 1, "count")
	check("a minute and more alive in a round without playing: not yet warned", not out and not c.warned)
	run(c, 1, "count")
	check("...warned once it's been warnAfter", c.warned and math.abs(AfkRules.left(c, WARN, OUT) - OUT) < 1e-6)
	out = run(c, OUT - 1, "count")
	check("...and not out a second short of outAfter more", not out and c.warned)
	out = run(c, 1, "count")
	check("...then due out, the clock started over", out and c.idle == 0 and not c.warned)
end

do
	local c = AfkRules.new()
	run(c, WARN - 10, "count")
	local idle = c.idle
	run(c, 60, "pause")
	check("dead or between rounds the clock stops, keeping what it had", c.idle == idle)
	run(c, 10, "count")
	check("...and goes on from there once it counts again", c.warned)
	run(c, 1, "off")
	check("out of a match it starts over", c.idle == 0 and not c.warned)
	run(c, WARN + OUT + 60, "off")
	check("...and never comes due there", c.idle == 0)
end

do
	local c = AfkRules.new()
	run(c, WARN + 5, "count")
	AfkRules.played(c)
	check("a buy or a ping starts the clock over and takes the warning back", c.idle == 0 and not c.warned)
end

-- What counts as playing -----------------------------------------------------------------------

do
	local c = AfkRules.new()
	run(c, 30, "count")
	check("a life's first input sets where the aim is, and isn't playing", not AfkRules.input(c, 0, 1.0, 0.1, 1) and c.idle == 30)
	check("nothing pressed, the aim as it was: not playing", not AfkRules.input(c, 0, 1.0, 0.1, 1))
	check("a key pressed is playing, and starts the clock over", AfkRules.input(c, B.Forward, 1.0, 0.1, 1) and c.idle == 0)
	run(c, 10, "count")
	check("...held on, it's not, from the tick after", not AfkRules.input(c, B.Forward, 1.0, 0.1, 1) and c.idle == 10)
	check("...and let go, it is", AfkRules.input(c, 0, 1.0, 0.1, 1))
	AfkRules.input(c, B.Crouch, 1.0, 0.1, 1)
	run(c, 10, "count")
	for _ = 1, 100 do
		AfkRules.input(c, B.Crouch, 1.0, 0.1, 1)
	end
	check("a crouch toggled on, held from tick to tick, isn't playing", c.idle == 10)
	AfkRules.input(c, 0, 1.0, 0.1, 1)
	check("a weapon asked for is", AfkRules.input(c, 0, 1.0, 0.1, 2))
end

do
	local c = AfkRules.new()
	AfkRules.input(c, 0, 0, 0, 1)
	run(c, 5, "count")
	check("a look under a tenth of a degree isn't playing", not AfkRules.input(c, 0, TURN * 0.5, 0, 1) and c.idle == 5)
	check("...but a slow turn adds up to one", AfkRules.input(c, 0, TURN * 1.5, 0, 1) and c.idle == 0)
	run(c, 5, "count")
	check("a look up or down past it is playing", AfkRules.input(c, 0, TURN * 1.5, TURN * 1.2, 1))
	local w = AfkRules.new()
	AfkRules.input(w, 0, math.pi - TURN * 0.2, 0, 1)
	run(w, 5, "count")
	check("a hair's turn across the yaw's wrap isn't a whole turn", not AfkRules.input(w, 0, -math.pi + TURN * 0.2, 0, 1))
end

do
	local c = AfkRules.new()
	AfkRules.input(c, B.Forward, 1.0, 0, 1)
	run(c, 20, "count")
	AfkRules.spawned(c)
	check("a new life on the server's aim, keys held over: not playing", not AfkRules.input(c, B.Forward, -2.0, 0.3, 2) and c.idle == 20)
	check("...and what's played after counts as before", AfkRules.input(c, 0, -2.0, 0.3, 2) and c.idle == 0)
end

return nil
