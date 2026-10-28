--!strict
-- Damage and danger indicators (system 54): the way a hit came from as a
-- yaw and where it shows on the ring as you turn, arcs renewed by hits from
-- much the same way and the oldest giving way, how they fade, the pulse,
-- when a fire or a wall of fire reads as near you and when it reaches you,
-- low health and low ammo, and the text scripted checks read.

local BlazeSim = require("../src/shared/Abilities/BlazeSim")
local FireSim = require("../src/shared/Abilities/FireSim")
local Indicators = require("../src/shared/Combat/Indicators")
local H = require("./Harness")

local check = H.check
local near = H.near

H.section("Damage and danger indicators (system 54)")

local P = Indicators.Params
local AT = vector.zero
local HALF = 0.34

-- A place 10 m from `AT` the way `yaw` looks.
local function fromYaw(yaw: number): vector
	local r = math.rad(yaw)
	return AT + vector.create(-math.sin(r), 0, -math.cos(r)) * 10
end

local function hurt(from: vector, time: number): Indicators.Hurt
	return { from = from, at = AT, time = time }
end

do
	local yawOf = Indicators.yawOf
	local ahead, left, right = yawOf(vector.create(0, 0, -1)), yawOf(vector.create(-1, 0, 0)), yawOf(vector.create(1, 0, 0))
	local behind = yawOf(vector.create(0, 0, 1))
	check(
		"a way's yaw is the camera's: 0 down -Z, 90 to the left, -90 to the right, 180 behind",
		ahead == 0 and left == 90 and right == -90 and behind ~= nil and near(math.abs(behind), 180, 1e-9)
	)
	check("a way straight up or down has none", yawOf(vector.create(0, 5, 0)) == nil and yawOf(vector.create(0, -1, 0)) == nil)
	check("its height doesn't count", yawOf(vector.create(-1, 3, 0)) == 90)
	check("and a way round fromYaw comes back", near(yawOf(fromYaw(37) - AT) or 0, 37, 1e-4))
end

do
	-- Shot from the left while looking down -Z.
	local heading = Indicators.yawOf(fromYaw(90) - AT) or 0
	check("a hit from the left shows on the left of the ring", near(Indicators.bearing(0, heading), -90, 1e-4))
	check("turned left to face it, at the top", near(Indicators.bearing(90, heading), 0, 1e-4))
	check("turned right, behind", near(Indicators.bearing(-90, heading), 180, 1e-4))
	check("from the right, on the right", near(Indicators.bearing(0, -90), 90, 1e-9))
	check("bearings stay in (-180, 180]", near(Indicators.bearing(170, -170), -20, 1e-9) and near(Indicators.bearing(-170, 170), 20, 1e-9))
end

do
	local marks: { Indicators.Mark } = {}
	local first = Indicators.add(marks, hurt(fromYaw(90), 0))
	check("a hit adds an arc the way it came", first ~= nil and #marks == 1 and near(first.heading, 90, 1e-4))

	local again = Indicators.add(marks, hurt(fromYaw(80), 0.5))
	check(
		"one from much the same way renews it, pointing the newer way",
		again == first and #marks == 1 and marks[1].time == 0.5 and near(marks[1].heading, 80, 1e-4)
	)
	check(
		"a hit from straight above adds none",
		Indicators.add(marks, { from = vector.create(0, 10, 0), at = AT, time = 1 }) == nil and #marks == 1
	)

	Indicators.add(marks, hurt(fromYaw(-90), 0.6))
	check("one from another way adds another", #marks == 2 and near(marks[2].heading, -90, 1e-4))
	Indicators.add(marks, hurt(fromYaw(85), 0.7))
	check("a renewed arc becomes the newest", #marks == 2 and near(marks[1].heading, -90, 1e-4) and near(marks[2].heading, 85, 1e-4))
end

do
	local merge = P.merge.value
	local marks: { Indicators.Mark } = {}
	Indicators.add(marks, hurt(fromYaw(0), 0))
	Indicators.add(marks, hurt(fromYaw(merge - 0.1), 0.1))
	check("hits within merge of each other renew one arc", #marks == 1)
	Indicators.add(marks, hurt(fromYaw(2 * merge), 0.2))
	check("further apart, two", #marks == 2)

	local round: { Indicators.Mark } = {}
	Indicators.add(round, hurt(fromYaw(175), 0))
	Indicators.add(round, hurt(fromYaw(-175), 0.1))
	check("ways either side of behind are close", #round == 1)
end

do
	local most = P.most.value
	local marks: { Indicators.Mark } = {}
	for i = 1, most + 2 do
		Indicators.add(marks, hurt(fromYaw(i * 30), i))
	end
	check(
		"past most arcs the oldest give way",
		#marks == most and marks[1].time == 3 and marks[most].time == most + 2,
		string.format("%d arcs", #marks)
	)
end

do
	local hold, fade = P.hold.value, P.fade.value
	check("an arc shows whole for hold", Indicators.alpha(0) == 1 and Indicators.alpha(hold) == 1)
	check("then fades in a straight line", near(Indicators.alpha(hold + fade / 2), 0.5, 1e-9))
	check("and is gone after fade", Indicators.alpha(hold + fade) == 0 and Indicators.alpha(hold + fade + 5) == 0)

	local marks: { Indicators.Mark } = {}
	Indicators.add(marks, hurt(fromYaw(90), 0))
	Indicators.add(marks, hurt(fromYaw(-90), 1.5))
	Indicators.prune(marks, hold + fade)
	check("pruning takes away the arcs gone", #marks == 1 and marks[1].time == 1.5)
	Indicators.prune(marks, 1.5 + hold + fade)
	check("and the last once it's gone", #marks == 0)
end

do
	local mark: Indicators.Mark = { from = vector.create(-10, 0, 0), heading = 90, time = 0 }
	check("an arc points at where its hit came from", near(Indicators.wayTo(mark, AT), 90, 1e-9))
	check("from where you've moved to", near(Indicators.wayTo(mark, vector.create(-10, 0, 10)), 0, 1e-9))
	check("its first way right under it", Indicators.wayTo(mark, vector.create(-10, -4, 0)) == 90)
end

do
	local low, high = math.huge, -math.huge
	for i = 0, 200 do
		local v = Indicators.pulse(i * 0.01)
		low, high = math.min(low, v), math.max(high, v)
	end
	check("the pulse runs from whole down to 0.4 and back", near(low, 0.4, 1e-3) and near(high, 1, 1e-9))
	check(
		"once a beat",
		near(Indicators.pulse(0), 1, 1e-9)
			and near(Indicators.pulse(P.pulse.value / 2), 0.4, 1e-9)
			and near(Indicators.pulse(P.pulse.value), 1, 1e-9)
	)
end

do
	local centre = vector.create(0, 0, 0)
	local pool = FireSim.new(1, 1, centre, 0, FireSim.reaches(centre))
	local reach = pool.shape.radius.value + HALF
	local function at(x: number, y: number?): vector
		return vector.create(x, y or 0, 0)
	end
	local inFire = Indicators.fireThreat(pool, at(2), 1, HALF)
	check("standing in Hot Hands' fire is critical", inFire ~= nil and inFire.level == "critical" and inFire.to == centre)
	local edge = Indicators.fireThreat(pool, at(reach - 0.01), 1, HALF)
	check("as far as it burns someone", edge ~= nil and edge.level == "critical")
	local byIt = Indicators.fireThreat(pool, at(reach + 0.01), 1, HALF)
	check("just past that, danger", byIt ~= nil and byIt.level == "danger" and byIt.to == centre)
	local farther = Indicators.fireThreat(pool, at(reach + P.near.value - 0.01), 1, HALF)
	check("as far as near more, danger", farther ~= nil and farther.level == "danger")
	check("past that, nothing", Indicators.fireThreat(pool, at(reach + P.near.value + 0.01), 1, HALF) == nil)
	check("nothing jumping over it", Indicators.fireThreat(pool, at(2, pool.shape.height.value + 0.1), 1, HALF) == nil)
	check(
		"nothing before it bursts or once it's out",
		Indicators.fireThreat(pool, at(2), -0.1, HALF) == nil and Indicators.fireThreat(pool, at(2), FireSim.ends(pool), HALF) == nil
	)
	local spreading = Indicators.fireThreat(pool, at(2), 0.1, HALF)
	check("as it spreads, near it's danger", spreading ~= nil and spreading.level == "danger")
end

do
	local a, b = vector.create(0, 0, 0), vector.create(0, 0, -10)
	local wall = BlazeSim.wall(1, 1, { a, b }, 0)
	assert(wall, "wall")
	local reach = 0.5 + HALF
	local function at(x: number, z: number): vector
		return vector.create(x, 0, z)
	end
	local inWall = Indicators.wallThreat(wall, at(0.5, -5), 1, HALF)
	check("standing in Blaze is critical", inWall ~= nil and inWall.level == "critical" and inWall.to == at(0, -5))
	local byIt = Indicators.wallThreat(wall, at(reach + 1, -5), 1, HALF)
	check("beside it, danger, the way to the place on it nearest", byIt ~= nil and byIt.level == "danger" and byIt.to == at(0, -5))
	local past = Indicators.wallThreat(wall, at(0, -12), 1, HALF)
	check("past its far end, the way to its end", past ~= nil and past.level == "danger" and past.to == b)
	check("farther, nothing", Indicators.wallThreat(wall, at(reach + 3.1, -5), 1, HALF) == nil)
	check(
		"nothing before it rises or once it falls",
		Indicators.wallThreat(wall, at(0.5, -5), -0.1, HALF) == nil
			and Indicators.wallThreat(wall, at(0.5, -5), BlazeSim.ends(wall), HALF) == nil
	)
	local early = Indicators.wallThreat(wall, at(0.5, -9), 0.1, HALF)
	check("where it hasn't spread to yet, nothing", early == nil)
	local later = Indicators.wallThreat(wall, at(0.5, -9), 1, HALF)
	check("then critical once it's there", later ~= nil and later.level == "critical")
end

do
	local lowHealth = Indicators.lowHealth
	check("health at 30 reads low and at 31 doesn't", lowHealth(30) and not lowHealth(31))
	check("in whole points as the HUD shows them", lowHealth(29.2) and not lowHealth(30.5) and lowHealth(0.3))
	check("nothing left isn't low: you're dead", not lowHealth(0))

	local lowAmmo = Indicators.lowAmmo
	check("a Vandal's magazine reads low at 6 and not 7", lowAmmo(6, 25) and not lowAmmo(7, 25))
	check("a Classic's at 3 and not 4", lowAmmo(3, 12) and not lowAmmo(4, 12))
	check("an Operator's at its last round", lowAmmo(1, 5) and not lowAmmo(2, 5))
	check("a magazine of one, at its last", lowAmmo(1, 1))
	check("empty is low", lowAmmo(0, 25))
	check("no magazine, never", not lowAmmo(0, 0))
end

check(
	"bearings read in whole degrees",
	Indicators.text({ -90, 180, -179.6, 0.4, -0.6 }) == "-90, 180, 180, 0, -1",
	Indicators.text({ -90, 180, -179.6, 0.4, -0.6 })
)
check("none, an empty text", Indicators.text({}) == "")

return nil
