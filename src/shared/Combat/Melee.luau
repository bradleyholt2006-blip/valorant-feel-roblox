--!strict
-- Knife hits (system 10): what a swing catches, and how hard it hits.
--
-- A swing catches what's in front of the eye: anything within `radius` of
-- the aim, out to `reach` straight ahead. That is a capsule along the aim,
-- from the eye to `reach - radius`, `radius` round. The reference's knife
-- hits with volumes like this ("Right click hitboxes are now 1.5x larger",
-- Patch 4.01), and it hits one target: "Targets closer to the center of
-- your knife attacks will get hit first, so you still have precision if you
-- need it". So of the targets the capsule touches, the one nearest the aim
-- takes the swing, unless the level hides it, when the next nearest does. A
-- target is hidden when the level is between the eye and every one of its
-- boxes the capsule touches, at the point it touches each: a head showing
-- over waist-high cover can still be struck.
--
-- A target struck from behind takes double ("double damage when striking
-- the target's back", the wiki): from anywhere behind the line through its
-- shoulders, a 180-degree arc (community). The head takes no more than the
-- body: a knife to the head counts as a headshot, for the same damage
-- (community).
--
-- When a swing catches no one, the level straight ahead within reach is
-- what the blade strikes, for the mark and the sound ("Knifing walls now
-- has instant feedback when slicing up walls", Patch 4.01).
--
-- Pure, like ShotResolver: the caller gives the targets as they were
-- (rewound on the server, as drawn on the client) and the level, so both
-- sides decide a swing with the same code.

local Hitboxes = require("./Hitboxes")
local Penetration = require("./Penetration")
local WeaponConfig = require("../Weapons/WeaponConfig")

export type Target = { id: number, pose: Hitboxes.Pose }

-- Where a swing touches a target: the point of its boxes nearest the aim.
export type Contact = {
	targetId: number,
	region: Hitboxes.Region,
	point: vector, -- metres
	offset: number, -- metres from the aim
	distance: number, -- metres along the aim from the eye
}

export type Result = {
	hit: Contact?,
	back: boolean, -- the hit came from behind
	damage: number, -- what the hit does; 0 with no hit
	contacts: { Contact }, -- every target in reach at its box nearest the aim, nearest the aim first
	hidden: { number }, -- the ones the level hid, in the same order
	wall: Penetration.Surface?, -- what the blade struck when it hit no one
}

local Melee = {}

-- A target is hidden only by level geometry this much nearer than the point
-- it was caught at, so a box touching a wall is still in view.
local SKIN = 0.01
-- Steps of the search for a box's nearest approach: each keeps 0.618 of the
-- stretch, so 60 leave about 2e-13 of it.
local SEARCH_STEPS = 60
local GOLDEN = (math.sqrt(5) - 1) / 2

local PRIORITY: { [Hitboxes.Region]: number } = { head = 3, body = 2, legs = 1 }
local CENTER_OFFSET = vector.create(0, 0.9, 0)

-- The capsule's line: how far along the aim it runs.
function Melee.length(attack: WeaponConfig.SwingDef): number
	return math.max(attack.reach.value - attack.radius.value, 0)
end

-- Broad phase: whether a target could be in reach at all. The debug tools
-- report the targets this lets through.
function Melee.nearby(origin: vector, attack: WeaponConfig.SwingDef, pose: Hitboxes.Pose): boolean
	return vector.magnitude(pose.position + CENTER_OFFSET - origin) <= attack.reach.value + Hitboxes.BOUND_RADIUS
end

local function clampToBox(p: vector, half: vector): vector
	return vector.create(math.clamp(p.x, -half.x, half.x), math.clamp(p.y, -half.y, half.y), math.clamp(p.z, -half.z, half.z))
end

-- The nearest approach of the segment from `origin` along `dir` (unit) for
-- `length` metres to a box: how far apart they are there, how far along the
-- segment, and the box's point there. A segment that goes into the box
-- meets it where it goes in.
function Melee.approach(origin: vector, dir: vector, length: number, box: Hitboxes.Box): (number, number, vector)
	local entry = Hitboxes.rayBox(origin, dir, box, length)
	if entry then
		return 0, entry, origin + dir * entry
	end
	local o = Hitboxes.toLocal(origin - box.center, box.yaw)
	local d = Hitboxes.toLocal(dir, box.yaw)
	local half = box.half
	local function gap(t: number): number
		local p = o + d * t
		return vector.magnitude(p - clampToBox(p, half))
	end
	-- The gap is convex along the segment, so a golden-section search finds
	-- its least.
	local lo, hi = 0, length
	local a, b = hi - (hi - lo) * GOLDEN, lo + (hi - lo) * GOLDEN
	local ga, gb = gap(a), gap(b)
	for _ = 1, SEARCH_STEPS do
		if ga <= gb then
			hi, b, gb = b, a, ga
			a = hi - (hi - lo) * GOLDEN
			ga = gap(a)
		else
			lo, a, ga = a, b, gb
			b = lo + (hi - lo) * GOLDEN
			gb = gap(b)
		end
	end
	local t = (lo + hi) / 2
	local p = o + d * t
	local q = clampToBox(p, half)
	return vector.magnitude(p - q), t, box.center + Hitboxes.toWorld(q, box.yaw)
end

-- Whether `from` is behind a target posed as `pose`: on the far side of the
-- line through its shoulders, square to the way it faces.
function Melee.isBehind(from: vector, pose: Hitboxes.Pose): boolean
	local to = from - pose.position
	return -math.sin(pose.yaw) * to.x - math.cos(pose.yaw) * to.z < 0
end

-- Which of two contacts the swing takes first: the one nearer the aim, then
-- the nearer one (both 0 off the aim when it goes into both), then the head
-- before the body before the legs.
local function before(a: Contact, b: Contact): boolean
	if a.offset ~= b.offset then
		return a.offset < b.offset
	end
	if a.distance ~= b.distance then
		return a.distance < b.distance
	end
	if a.region ~= b.region then
		return PRIORITY[a.region] > PRIORITY[b.region]
	end
	return a.targetId < b.targetId
end

-- Where the swing touches each of a target's boxes it reaches, nearest the
-- aim first.
function Melee.contacts(origin: vector, dir: vector, attack: WeaponConfig.SwingDef, target: Target): { Contact }
	local length, radius = Melee.length(attack), attack.radius.value
	local out: { Contact } = {}
	for _, box in Hitboxes.build(target.pose) do
		local offset, distance, point = Melee.approach(origin, dir, length, box)
		if offset <= radius then
			table.insert(out, { targetId = target.id, region = box.region, point = point, offset = offset, distance = distance })
		end
	end
	table.sort(out, before)
	return out
end

-- Where the swing touches one target first, if it does.
function Melee.contact(origin: vector, dir: vector, attack: WeaponConfig.SwingDef, target: Target): Contact?
	return Melee.contacts(origin, dir, attack, target)[1]
end

-- Whether the level leaves `point` in view of `origin`.
local function inView(level: Penetration.Level, origin: vector, point: vector): boolean
	local to = point - origin
	local distance = vector.magnitude(to)
	return distance <= SKIN or level:cast(origin, to / distance, distance - SKIN, {}) == nil
end

-- What a swing from `origin` along `dir` (unit) does with `attack` to
-- `targets`, through `level`. `ignoreId` is the one swinging.
function Melee.resolve(level: Penetration.Level, origin: vector, dir: vector, attack: WeaponConfig.SwingDef, targets: { Target }, ignoreId: number?): Result
	local poses: { [number]: Hitboxes.Pose } = {}
	local reached: { { Contact } } = {} -- each target's contacts, nearest the aim first
	for _, target in targets do
		if target.id == ignoreId or not Melee.nearby(origin, attack, target.pose) then
			continue
		end
		local list = Melee.contacts(origin, dir, attack, target)
		if #list > 0 then
			poses[target.id] = target.pose
			table.insert(reached, list)
		end
	end
	table.sort(reached, function(a: { Contact }, b: { Contact }): boolean
		return before(a[1], b[1])
	end)
	local contacts: { Contact } = table.create(#reached)
	for i, list in reached do
		contacts[i] = list[1]
	end

	local hit: Contact? = nil
	local hidden: { number } = {}
	for _, list in reached do
		for _, contact in list do
			if inView(level, origin, contact.point) then
				hit = contact
				break
			end
		end
		if hit then
			break
		end
		table.insert(hidden, list[1].targetId)
	end

	if hit then
		local back = Melee.isBehind(origin, poses[hit.targetId])
		return {
			hit = hit,
			back = back,
			damage = if back then attack.back.value else attack.front.value,
			contacts = contacts,
			hidden = hidden,
			wall = nil,
		}
	end
	return {
		hit = nil,
		back = false,
		damage = 0,
		contacts = contacts,
		hidden = hidden,
		wall = level:cast(origin, dir, attack.reach.value, {}),
	}
end

return Melee
