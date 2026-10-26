--!strict
-- Sage's Healing Orb (system 36): who a try heals, and a heal under way.
--
-- A try with fire heals the ally the crosshair's over: of the hurt allies
-- the healer's screen showed, the first along the crosshair that it passes
-- within its width of (AbilityConfig.HealingOrb), anywhere from their feet
-- to the top of their head, within its reach, and in sight, any of the
-- three points of them Sight counts with nothing in the way. A try with alt
-- fire heals the healer, if they're hurt. Hurt is short of the most health
-- as the HUD shows it, in whole points.
--
-- A heal gives its health over its duration, at a steady rate, a point at
-- a time up to the most; each time its target's hurt it stops for its
-- pause, its clock with it, and goes on after with what's left. It's over
-- once its time has run, whether its target's at the most or not.
--
-- No Roblox APIs here: the server passes its level in as `hidden`, so the
-- offline tests run it on a fake one.

local AbilityConfig = require("./AbilityConfig")
local Health = require("../Combat/Health")
local Hitboxes = require("../Combat/Hitboxes")
local Sight = require("../Combat/Sight")

-- An ally a try can heal: their entity id and where they stood.
export type Body = { id: number, pose: Hitboxes.Pose }

-- A heal under way: on whom, by whom (entity ids), the health it gives in
-- all and a second while it runs, the seconds it has run, its pauses left
-- out, the whole points it has given, and when it was last stepped.
export type Heal = {
	target: number,
	healer: number,
	total: number,
	rate: number,
	ran: number,
	given: number,
	at: number,
}

local HealSim = {}

local HO = AbilityConfig.HealingOrb
local EPS = 1e-9
local UP = vector.create(0, 1, 0)

-- Whether `health` is short of `most`, in whole points.
function HealSim.hurt(health: number, most: number): boolean
	return Health.points(health) < most
end

-- How tall a body stands, feet to the top of the head, crouched as it is.
local function height(pose: Hitboxes.Pose): number
	local head = Hitboxes.build(pose)[1]
	return head.center.y + head.half.y - pose.position.y
end

-- The closest the segments from `p1` to `q1` and from `p2` to `q2` come:
-- how far along the first that is (0 to 1), and how far apart they are
-- there (Ericson, "Real-Time Collision Detection", 5.1.9).
local function closest(p1: vector, q1: vector, p2: vector, q2: vector): (number, number)
	local d1, d2, r = q1 - p1, q2 - p2, p1 - p2
	local a, e, f = vector.dot(d1, d1), vector.dot(d2, d2), vector.dot(d2, r)
	local s, t = 0, 0
	if a <= EPS and e <= EPS then
		s, t = 0, 0
	elseif a <= EPS then
		t = math.clamp(f / e, 0, 1)
	else
		local c = vector.dot(d1, r)
		if e <= EPS then
			s = math.clamp(-c / a, 0, 1)
		else
			local b = vector.dot(d1, d2)
			local denom = a * e - b * b
			s = if denom > EPS then math.clamp((b * f - c * e) / denom, 0, 1) else 0
			t = (b * s + f) / e
			if t < 0 then
				t = 0
				s = math.clamp(-c / a, 0, 1)
			elseif t > 1 then
				t = 1
				s = math.clamp((b - c) / a, 0, 1)
			end
		end
	end
	return s, vector.magnitude((p1 + d1 * s) - (p2 + d2 * t))
end

-- How far along the crosshair from `eye` (`aim` a unit vector) it's over
-- `pose`'s body, within the orb's width and reach; nil if it isn't.
function HealSim.along(eye: vector, aim: vector, pose: Hitboxes.Pose): number?
	local reach = HO.reach.value
	local s, apart = closest(eye, eye + aim * reach, pose.position, pose.position + UP * height(pose))
	return if apart <= HO.width.value + EPS then s * reach else nil
end

-- The ally a try from `eye` along `aim` (a unit vector) heals, of `allies`,
-- by entity id: the first along the crosshair it's over that `hidden`
-- (true when something's in the way between two points) doesn't hide from
-- the eye. Nil for nobody.
function HealSim.aimedAt(eye: vector, aim: vector, allies: { Body }, hidden: (vector, vector) -> boolean): number?
	local over: { { id: number, along: number, pose: Hitboxes.Pose } } = {}
	for _, ally in allies do
		local along = HealSim.along(eye, aim, ally.pose)
		if along then
			table.insert(over, { id = ally.id, along = along, pose = ally.pose })
		end
	end
	table.sort(over, function(a, b)
		return a.along < b.along
	end)
	for _, o in over do
		for _, point in Sight.points(o.pose) do
			if not hidden(eye, point) then
				return o.id
			end
		end
	end
	return nil
end

-- A heal of `total` health on `target` by `healer` (entity ids), starting
-- at `now`.
function HealSim.new(target: number, healer: number, total: number, now: number): Heal
	return { target = target, healer = healer, total = total, rate = total / HO.duration.value, ran = 0, given = 0, at = now }
end

-- A heal run on to `now`, its target last hurt at `hurtAt`: all the time
-- since it was last stepped, but what of it the pause from that hurt takes.
function HealSim.step(h: Heal, now: number, hurtAt: number)
	if now <= h.at then
		return
	end
	local paused = math.max(math.min(now, hurtAt + HO.pause.value) - math.max(h.at, hurtAt), 0)
	h.ran = math.min(h.ran + (now - h.at) - paused, HO.duration.value)
	h.at = now
	if h.ran >= HO.duration.value - EPS then
		h.ran = HO.duration.value
	end
end

-- The whole points a heal owes now, taken as given.
function HealSim.take(h: Heal): number
	local due = math.min(math.floor(h.rate * h.ran + 1e-6), h.total)
	local owed = math.max(due - h.given, 0)
	h.given += owed
	return owed
end

-- Whether a heal's time has run: once it's given what it owes, it's over.
function HealSim.done(h: Heal): boolean
	return h.ran >= HO.duration.value
end

return HealSim
