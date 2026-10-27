--!strict
-- Sova's Hunter's Fury (system 46): whom a blast catches. As its windup
-- ends (AbilitySim) a blast goes from his eye along the crosshair, through
-- the level and everything in it ('The arrows can be shot through walls',
-- EarlyGame's Sova guide), as far as its range, and catches everyone whose
-- body comes within its radius of that line:
--   * from his eye on, and none behind him (Patch 13.09: 'Fixed an issue
--     where Sova's Hunter's Fury could affect players positioned behind
--     him'), nor past its range: a tube, flat at both ends
--   * a body is its upright line, from the feet to the top of the head
--     (Hitboxes), as wide either side of it as the body's box
-- What it does to them is the server's (FuryServer).
--
-- No Roblox APIs here, so the offline tests run it.

local AbilityConfig = require("./AbilityConfig")
local Hitboxes = require("../Combat/Hitboxes")

-- Someone a blast might catch: their entity id, where their feet are, how
-- high the top of their head is above them, and how wide they are either
-- side of their upright line (metres).
export type Target = { id: number, feet: vector, top: number, width: number }
-- Someone a blast catches: their entity id, and how far along it the
-- nearest of them to its line is (metres).
export type Hit = { id: number, along: number }

local FurySim = {}

local HF = AbilityConfig.HuntersFury
local EPS = 1e-9
local UP = vector.create(0, 1, 0)

-- What its damage is credited to, for the kill feed and the match's
-- record: the bow's weapon.
FurySim.WEAPON = "furybow"
-- The player attributes that keep, for scripted checks, where the owner's
-- last blast went from (metres) and whom it caught, in the order of their
-- names ("" for nobody).
FurySim.POINT_ATTRIBUTE = "VFLastFury"
FurySim.HITS_ATTRIBUTE = "VFFuryHits"

-- How wide a body is either side of its upright line: its body box's half
-- width (Hitboxes).
FurySim.WIDTH = 0.22

-- Someone at `pose` (the snapshots'), as a blast sees them.
function FurySim.target(id: number, pose: Hitboxes.Pose): Target
	local top = 0
	for _, box in Hitboxes.build(pose) do
		top = math.max(top, box.center.y + box.half.y - pose.position.y)
	end
	return { id = id, feet = pose.position, top = top, width = FurySim.WIDTH }
end

-- Whether a blast from `origin` along `direction` (a unit vector) catches
-- `target`: some point of their upright line ahead of it and within its
-- range along it, within its radius and their width of it. If it does,
-- how far along it the nearest such point is.
function FurySim.reach(origin: vector, direction: vector, target: Target): number?
	local range, most = HF.range.value, HF.radius.value + target.width
	local rel = target.feet - origin
	-- How far along the blast the point `u` up from the feet is: s + k u.
	local s, k = vector.dot(rel, direction), vector.dot(UP, direction)
	local lo, hi = 0, target.top
	if math.abs(k) < EPS then
		if s < -EPS or s > range + EPS then
			return nil
		end
	else
		local a, b = -s / k, (range - s) / k
		lo, hi = math.max(lo, math.min(a, b)), math.min(hi, math.max(a, b))
		if lo > hi + EPS then
			return nil
		end
	end
	-- Off the blast's line, that point is `off + side u` away: the nearest
	-- of them between lo and hi.
	local off = rel - direction * s
	local side = UP - direction * k
	local square = vector.dot(side, side)
	local u = if square < EPS then lo else math.min(math.max(-vector.dot(off, side) / square, lo), math.max(hi, lo))
	local gap = off + side * u
	if vector.dot(gap, gap) > most * most + EPS then
		return nil
	end
	return math.clamp(s + k * u, 0, range)
end

-- Whom a blast from `origin` along `direction` catches, of `targets`, the
-- nearest along it first.
function FurySim.caught(origin: vector, direction: vector, targets: { Target }): { Hit }
	local out: { Hit } = {}
	for _, target in targets do
		local along = FurySim.reach(origin, direction, target)
		if along then
			table.insert(out, { id = target.id, along = along })
		end
	end
	table.sort(out, function(a: Hit, b: Hit): boolean
		if a.along ~= b.along then
			return a.along < b.along
		end
		return a.id < b.id
	end)
	return out
end

return FurySim
