--!strict
-- Damage and danger indicators (system 54), round the crosshair, as the
-- reference's:
--   * a hit you take from somewhere shows a red arc on the side it came
--     from ('New directional damage indicator visual', Patch 0.49; Iso's
--     shield gives 'a damage indicator towards the direction of the enemy
--     that broke the shield', Patch 8.11): a bullet's, a blade's and a
--     blast's from whoever made it, a burst's from where it burst. It goes
--     on pointing the way it came from as you turn, whole for a while and
--     then fading (Indicators.alpha), and a hit from much the same way
--     renews it (Indicators.add). A fire's burn shows none: you're standing
--     in what burns you, as the critical mark says
--   * a fire or a wall of fire that isn't yours shows a yellow mark on its
--     side when it's near you, pulsing ('Added a small animation to our
--     Yellow Directional Indicator', Patch 6.07), and once it reaches you a
--     red one under the crosshair, the critical ('the yellow and red UI that
--     appear when utility is around you or you are taking/about to take
--     damage', Patch 6.07; Indicators.fireThreat and wallThreat)
--   * a hit on the Owl Drone you're flying shows as one on you (Patch 12.02:
--     'new UI damage indicators that display for objects that take damage
--     while controlled by a player')
--   * at low health your health reads red, and with the magazine low its
--     count ('New low health and low ammo visuals', Patch 0.49;
--     Indicators.lowHealth and lowAmmo)
-- Nothing public says how they look or gives their numbers: those are ours
-- (Params).
--
-- No Roblox APIs here, so the offline tests run it.

local BlazeSim = require("../Abilities/BlazeSim")
local FireSim = require("../Abilities/FireSim")
local Health = require("./Health")

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

-- A hit taken: where it came from and where it struck (metres), and when
-- (seconds, on the clock it's drawn by).
export type Hurt = { from: vector, at: vector, time: number }

-- A red arc: where its latest hit came from, the way that was from where it
-- struck (a yaw, Indicators.yawOf), and when it came.
export type Mark = { from: vector, heading: number, time: number }

-- How near a fire or a wall of fire is: it reaches you (critical), or it's
-- around you (danger).
export type Level = "critical" | "danger"

-- A fire or a wall of fire near someone: how near, and the place on it that
-- shows the way to it (metres).
export type Threat = { level: Level, to: vector }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local Indicators = {}

local EPS = 1e-9

Indicators.Params = {
	hold = p(1, "estimate", "Seconds a red arc shows whole after its latest hit; not published"),
	fade = p(1, "estimate", "Seconds it then takes to fade away; not published"),
	merge = p(20, "estimate", "Degrees between the ways two hits came within which the second renews the first's arc (ours)"),
	most = p(8, "estimate", "Red arcs shown at once, the oldest giving way (ours)"),
	near = p(
		3,
		"estimate",
		"Metres a fire or a wall of fire comes within to show its yellow mark ('when utility is around you', Patch 6.07)"
	),
	pulse = p(0.8, "estimate", "Seconds of one beat of the yellow and the critical marks' pulse ('a small animation', Patch 6.07)"),
	lowHealth = p(30, "estimate", "Health in whole points at or under which it reads red ('New low health ... visuals', Patch 0.49)"),
	lowAmmo = p(
		0.25,
		"estimate",
		"Share of the magazine at or under which its count reads red, a round at the least ('low ammo visuals', Patch 0.49)"
	),
}

local P = Indicators.Params

-- An angle in (-180, 180].
local function wrap(degrees: number): number
	local w = degrees % 360
	return if w > 180 then w - 360 else w
end

-- The yaw that looks along `d` (degrees), as the camera's: 0 down -Z,
-- positive to the left. Nil if it's straight up or down.
function Indicators.yawOf(d: vector): number?
	if d.x * d.x + d.z * d.z < EPS then
		return nil
	end
	return math.deg(math.atan2(-d.x, -d.z))
end

-- Where on the ring the way `heading` (a yaw) shows for a view along
-- `viewYaw`: degrees clockwise from the top, 0 ahead, 90 to the right, -90
-- to the left and 180 behind.
function Indicators.bearing(viewYaw: number, heading: number): number
	return wrap(viewYaw - heading)
end

-- A hit taken, among the arcs shown (oldest first): it renews the arc whose
-- way is within `merge` of its own, which becomes the newest, or adds one,
-- the oldest giving way past `most`. Returns its arc, or nil for a hit that
-- came from straight above or below where it struck.
function Indicators.add(marks: { Mark }, hurt: Hurt): Mark?
	local heading = Indicators.yawOf(hurt.from - hurt.at)
	if not heading then
		return nil
	end
	for i, mark in marks do
		if math.abs(wrap(mark.heading - heading)) <= P.merge.value + EPS then
			mark.from, mark.heading, mark.time = hurt.from, heading, hurt.time
			table.remove(marks, i)
			table.insert(marks, mark)
			return mark
		end
	end
	local mark: Mark = { from = hurt.from, heading = heading, time = hurt.time }
	table.insert(marks, mark)
	while #marks > P.most.value do
		table.remove(marks, 1)
	end
	return mark
end

-- The way from `eye` to where `mark`'s latest hit came from, a yaw: as you
-- move, it goes on pointing at that place. The way it came if you're right
-- over or under it.
function Indicators.wayTo(mark: Mark, eye: vector): number
	return Indicators.yawOf(mark.from - eye) or mark.heading
end

-- How strong an arc shows `age` seconds after its latest hit: whole for
-- `hold`, then less in a straight line to nothing `fade` later.
function Indicators.alpha(age: number): number
	local hold, fade = P.hold.value, P.fade.value
	if age <= hold then
		return 1
	elseif age >= hold + fade then
		return 0
	end
	return 1 - (age - hold) / fade
end

-- The arcs gone by `now` taken away.
function Indicators.prune(marks: { Mark }, now: number)
	for i = #marks, 1, -1 do
		if now - marks[i].time >= P.hold.value + P.fade.value - EPS then
			table.remove(marks, i)
		end
	end
end

-- The yellow and the critical marks' strength at `t` seconds: from whole
-- down to 0.4 and back, once a beat.
function Indicators.pulse(t: number): number
	local phase = (t / P.pulse.value) % 1
	return 0.7 + 0.3 * math.cos(phase * 2 * math.pi)
end

-- Hot Hands' fire (FireSim) to someone whose feet are at `feet` at `t`,
-- `halfWidth` their half width: critical once it reaches them as the server
-- burns them (FireServer's FireSim.inside, by their half width), danger
-- within `near` more. The way to it is to its middle.
function Indicators.fireThreat(pool: FireSim.Pool, feet: vector, t: number, halfWidth: number): Threat?
	if FireSim.inside(pool, feet, t, halfWidth) then
		return { level = "critical", to = pool.centre }
	elseif FireSim.inside(pool, feet, t, halfWidth + P.near.value) then
		return { level = "danger", to = pool.centre }
	end
	return nil
end

-- Blaze's wall (BlazeSim) the same way: critical once it reaches them as
-- the server burns them, danger within `near` more. The way to it is to the
-- place on it nearest them.
function Indicators.wallThreat(wall: BlazeSim.Wall, feet: vector, t: number, halfWidth: number): Threat?
	local level: Level? = nil
	if BlazeSim.inside(wall, feet, t, halfWidth) then
		level = "critical"
	elseif BlazeSim.inside(wall, feet, t, halfWidth + P.near.value) then
		level = "danger"
	end
	if not level then
		return nil
	end
	return { level = level, to = BlazeSim.nearest(wall, feet, t) or wall.points[1] }
end

-- Whether `health` reads as low: in whole points as the HUD shows it
-- (Health.points), some left and at or under `lowHealth`.
function Indicators.lowHealth(health: number): boolean
	local points = Health.points(health)
	return points > 0 and points <= P.lowHealth.value
end

-- Whether a magazine of `size` rounds with `ammo` left reads as low: at or
-- under `lowAmmo` of it, and a round at the least, so the last always does.
function Indicators.lowAmmo(ammo: number, size: number): boolean
	if size <= 0 then
		return false
	end
	return ammo <= math.max(1, math.floor(size * P.lowAmmo.value + EPS))
end

-- Bearings as scripted checks read them: whole degrees, joined by commas
-- ("-90, 180").
function Indicators.text(bearings: { number }): string
	local out = {}
	for _, b in bearings do
		local whole = math.floor(b + 0.5)
		table.insert(out, tostring(if whole == -180 then 180 else whole))
	end
	return table.concat(out, ", ")
end

return Indicators
