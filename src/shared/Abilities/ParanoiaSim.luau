--!strict
-- Omen's Paranoia (system 41): the orb's flight, whom it touches, and the
-- nearsight it gives them.
--
-- Sent, the orb appears its offset ahead of the eye along the crosshair
-- (Patch 4.04: 'Added forward spawn offset, so players adjacent to Omen
-- are not hit'), and flies straight on that way at its speed until it has
-- flown its travel, and goes. Nothing stops it or turns it: the level,
-- clouds and bodies alike (Riot's agent page: 'This projectile can pass
-- straight through walls'), so its path is known from the send. It
-- touches anyone who comes within its radius of its middle on the way,
-- judged at the middles of their head, body and legs (Sight.points),
-- allies and Omen too; and those standing in its path as it's sent are
-- warned (Patch 1.0: 'Enemies will receive a warning when the projectile
-- is fired').
--
-- A touch nearsights: whole for its duration, then clearing over its fade,
-- a second touch running it on (ParanoiaSim.nearsight). While it's whole,
-- they see no further than its vision, which the minimap's sight and a
-- flash's pop go by, and they're deafened (the VALORANT Wiki's Paranoia
-- page: 'briefly Nearsighting and Deafening all players it touches';
-- community). Each is kept as a player attribute in server time
-- (ParanoiaSim.ATTRIBUTE and DEAF_ATTRIBUTE): Reyna's Leer (system 74,
-- LeerSim) nearsights without deafening, so the two can end apart.
--
-- No Roblox APIs here, so the offline tests fly it.

local AbilityConfig = require("./AbilityConfig")

-- An orb sent: its thrower's entity id, the tick it was sent on (which
-- names it on both ends), where its middle appears (metres) and the way it
-- goes (a unit vector).
export type Orb = { owner: number, id: number, start: vector, way: vector }

-- A nearsight, in server time: since when, until when it's whole, and
-- until when any of it is left.
export type Nearsight = { from: number, full: number, gone: number }

local ParanoiaSim = {}

local PA = AbilityConfig.Paranoia
local EPS = 1e-9

-- The player attribute each nearsight is kept in: its from, full and gone,
-- in server time ("812.500,814.500,815.000"), unset with none.
ParanoiaSim.ATTRIBUTE = "VFNearsight"
-- And the one their deafening is kept in, the same way: Paranoia's alone.
ParanoiaSim.DEAF_ATTRIBUTE = "VFDeafened"

-- An orb sent from `eye` the way `aim` points.
function ParanoiaSim.send(owner: number, id: number, eye: vector, aim: vector): Orb
	local way = vector.normalize(aim)
	return { owner = owner, id = id, start = eye + way * PA.offset.value, way = way }
end

-- How long an orb flies, from where it appears to the end of its travel
-- (seconds).
function ParanoiaSim.flight(): number
	return PA.travel.value / PA.speed.value
end

-- Where an orb's middle is `age` seconds after it was sent: its start until
-- then, and the end of its travel from then on.
function ParanoiaSim.at(orb: Orb, age: number): vector
	return orb.start + orb.way * (math.clamp(age, 0, ParanoiaSim.flight()) * PA.speed.value)
end

-- How far `point` is from the line from `a` to `b`, as far as it goes.
function ParanoiaSim.distance(point: vector, a: vector, b: vector): number
	local ab = b - a
	local length2 = vector.dot(ab, ab)
	local u = if length2 > EPS then math.clamp(vector.dot(point - a, ab) / length2, 0, 1) else 0
	return vector.magnitude(point - (a + ab * u))
end

-- Whether an orb whose middle went from `a` to `b` touched a body with
-- these points: any of them within its radius of its middle on the way.
function ParanoiaSim.touches(a: vector, b: vector, points: { vector }): boolean
	for _, point in points do
		if ParanoiaSim.distance(point, a, b) <= PA.radius.value + EPS then
			return true
		end
	end
	return false
end

-- Whether a body with these points stands in an orb's path: where it
-- would touch them all the way from its start to the end of its travel.
function ParanoiaSim.inPath(orb: Orb, points: { vector }): boolean
	return ParanoiaSim.touches(orb.start, ParanoiaSim.at(orb, math.huge), points)
end

-- A nearsight given at `now`, over `old` if any of that is left: whole for
-- its duration, then clearing over its fade, or for `whole` seconds and
-- over `fade` where they're given (Leer's, system 74). The later end wins.
function ParanoiaSim.nearsight(old: Nearsight?, now: number, whole: number?, fade: number?): Nearsight
	local full = now + (whole or PA.duration.value)
	local gone = full + (fade or PA.fade.value)
	if old and old.gone > now then
		local from = if old.full > now then old.from else now
		return { from = from, full = math.max(old.full, full), gone = math.max(old.gone, gone) }
	end
	return { from = now, full = full, gone = gone }
end

-- How dark a nearsight leaves all past its vision at `t` (server time), 0
-- to 1: all of it while it's whole, then less and less until it's gone.
function ParanoiaSim.darkAt(n: Nearsight, t: number): number
	if t < n.from or t >= n.gone then
		return 0
	elseif t < n.full then
		return 1
	end
	return 1 - (t - n.full) / math.max(n.gone - n.full, EPS)
end

-- Whether a nearsight is whole at `t`: they see no further than its
-- vision (and, Paranoia's, are deafened).
function ParanoiaSim.whole(n: Nearsight?, t: number): boolean
	return n ~= nil and t >= n.from and t < n.full
end

-- How far someone with a nearsight sees at `t` (metres): its vision while
-- it's whole, and as far as anyone does (nil) otherwise.
function ParanoiaSim.range(n: Nearsight?, t: number): number?
	return if ParanoiaSim.whole(n, t) then PA.vision.value else nil
end

-- A nearsight as its attribute keeps it, and back.
function ParanoiaSim.encode(n: Nearsight): string
	return string.format("%.3f,%.3f,%.3f", n.from, n.full, n.gone)
end

function ParanoiaSim.decode(text: any): Nearsight?
	if type(text) ~= "string" then
		return nil
	end
	local a, b, c = string.match(text, "^([^,]+),([^,]+),([^,]+)$")
	local from, full, gone = tonumber(a), tonumber(b), tonumber(c)
	if not from or not full or not gone then
		return nil
	end
	return { from = from, full = full, gone = gone }
end

return ParanoiaSim
