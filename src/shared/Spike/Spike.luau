--!strict
-- The spike (system 12): what the reference's rounds are played for. The
-- attackers carry it to a site and plant it; once planted it detonates 45
-- seconds later unless a defender defuses it, and the blast kills everyone
-- near it (docs/research/12-spike.md).
--
-- The numbers, with the same status convention as MovementConfig:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki, guide or community measurement
--   "estimate"  - ours; to be tuned
-- The VALORANT Wiki (wiki.playvalorant.com) is written by players: Riot pays
-- for it but doesn't write it, so what only it says is "community".
--
-- And the rules that don't depend on Roblox: where it can be planted, who's
-- close enough to defuse it, who the blast reaches and how fast it beeps.
-- PlayerSim steps the plant and the defuse themselves (SpikeSim).
--
-- Its only require is the spike rounds' maps, for their sites (plain
-- data), so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

-- Part of a site's plant area: an upright box in metres, turned `yaw` about
-- the vertical. Feet inside one of a site's boxes can plant.
export type Zone = { site: string, center: vector, half: vector, yaw: number }

-- What a player's simulation needs to know of the spike this tick, from the
-- server's state of it (the client's copy is replicated): where it can be
-- planted, whether this player may plant or defuse, and where the planted
-- spike is while it can still be defused.
export type Context = {
	zones: { Zone },
	canPlant: boolean,
	canDefuse: boolean,
	planted: vector?, -- metres, on the ground
	-- A defuse has passed the half: the next one takes the second half only.
	halfSaved: boolean,
	-- Whether the eye can see the spike (a defuse needs it); nil sees always.
	sees: ((eye: vector, spike: vector) -> boolean)?,
	-- The Ultimate Orbs up, by number, where each stands (system 49,
	-- UltimateOrbs); nil for none.
	orbs: { [number]: vector }?,
	-- The Soul Orb of Reyna's in her reach, by its number (system 73,
	-- SoulSim.pick), which her Devour and Dismiss would take; nil for none.
	soul: number?,
}

local SpikeMaps = require("../Match/SpikeMaps")

local Spike = {}

local WIKI = "VALORANT Wiki (wiki.playvalorant.com), Spike"
local GUIDES = "; the same in Red Bull's, Mobalytics' and Sportskeeda's guides"

Spike.Params = {
	plantTime = p(4, "community", WIKI .. ": 'Planting takes 4 seconds'" .. GUIDES),
	defuseTime = p(7, "community", WIKI .. ": a defuse takes 7 seconds" .. GUIDES),
	defuseHalf = p(3.5, "community", WIKI .. ": once 3.5 seconds of defuse progress is reached it is saved" .. GUIDES),
	detonateTime = p(45, "community", WIKI .. ": the countdown is 45 seconds" .. GUIDES),
	-- The blast: 'A black sphere expands rapidly from the Spike and instantly
	-- kills any player it touches' (the VALORANT Wiki), out to 'roughly the
	-- player's audio range'.
	blastRadius = p(35, "community", "note.com (yuyujan11_valo, 2023), measured with in-game pings: 35 m"),
	blastGrowTime = p(0.5, "estimate", "How long the sphere takes to reach its edge; the wiki says it 'expands rapidly'"),
	-- How close a defender must be: inside the circle drawn round the planted
	-- spike ('The defuse range circle indicator that shows after planting the
	-- Spike', Patch 2.05). Its size isn't published.
	defuseRange = p(1.6, "estimate", "The defuse circle's radius, horizontally from the spike; not published"),
	defuseHeight = p(1.2, "estimate", "How far above or below the spike the defuser's feet may be"),
	-- Picking it up: 'collected by running over it' (the VALORANT Wiki), with
	-- no line of sight needed 'when overlapped by a player' (Patch 0.49).
	pickupRange = p(0.7, "estimate", "Horizontal distance from the feet that counts as running over it"),
	pickupHeight = p(1.0, "estimate", "How far above or below the feet it can be and still be run over"),
	-- Where a plant puts it: in front of the planter, as long as that's still
	-- inside the site ('The spike will now stay within the outlined site area
	-- no matter where you are facing', Patch 11.10).
	plantAhead = p(0.35, "estimate", "How far in front of the planter's feet it goes down; not published"),
	-- Thrown forward from the eye when dropped with G, landing where it falls.
	dropForward = p(1.2, "estimate", "How far ahead of the feet a dropped spike lands, on flat ground"),
	-- A new spike on the course, where the old one started, after it's gone.
	courseRespawn = p(5, "estimate", "Seconds after a detonation or defuse before the course's spike is back"),
}

-- How fast it beeps: once a second at first, then faster as it nears the
-- end, the last five seconds eight times a second.
Spike.Beeps = {
	{ from = 0, perSecond = 1 },
	{ from = 25, perSecond = 2 },
	{ from = 35, perSecond = 4 },
	{ from = 40, perSecond = 8 },
}
Spike.BeepSource = "Mobalytics and TRN Checkpoint: 'The first 25 seconds = one beep per second, 25-35 seconds = two"
	.. " beeps per second, 35-40 seconds = four beeps per second, 40 to explosion = eight beeps per second' (community);"
	.. " note.com (yuyujan11_valo) has it speed up at 20, 10 and 5 seconds left, and the VALORANT Wiki double-beeps"
	.. " at 20 and triple-beeps at 10: the same moments, 25, 35 and 40 seconds after the plant"

-- Workspace attributes the server keeps the spike's state in, for every
-- client: what it's doing, where, and when.
Spike.STATE = "VFSpike" -- "none", "carried", "dropped", "planted", "defused" or "detonated"
-- The carrier's id in the rules while carried (a player's UserId, or a
-- bot's, system 61), else 0.
Spike.CARRIER = "VFSpikeCarrier"
-- Metres, as a Vector3, while dropped or planted (and after, where it was):
-- metres so the client's copy of a planted spike is exactly the server's.
Spike.POSITION = "VFSpikePosition"
Spike.PLANTED_AT = "VFSpikePlantedAt" -- server time it was planted
Spike.HALF = "VFSpikeHalf" -- a defuse has passed the half
Spike.SITE = "VFSpikeSite" -- the site it was planted at
Spike.ENDED_AT = "VFSpikeEndedAt" -- server time it was defused or detonated
Spike.LAYOUT = "VFSpikeLayout" -- which sites there are: a key of Spike.Layouts
-- Who may do what with it: in the spike rounds (system 13) its carrier may
-- plant it only while a round is live, and only the defending side (a value
-- of ArenaConfig.SIDE) may defuse it; on the course, any time and anyone (0).
Spike.PLANT_OPEN = "VFSpikePlantOpen"
Spike.DEFUSERS = "VFSpikeDefusers"

-- The weapon id and the slot it's carried in ("Equip Spike" is 4).
Spike.ID = "spike"
Spike.SLOT = 4

-- The course's two sites (system 12's test area, 26 m behind the spawn):
-- plant areas 6 m square and 2 m tall, 10 m apart, side by side (our
-- sizes: each of the reference's maps marks out its own).
Spike.CourseSites = {
	{ site = "A", center = vector.create(-8, 1, 26), half = vector.create(3, 1, 3), yaw = 0 },
	{ site = "B", center = vector.create(8, 1, 26), half = vector.create(3, 1, 3), yaw = 0 },
} :: { Zone }
-- Where the course's spike waits to be picked up.
Spike.CourseStart = vector.create(0, 0, 4)

-- The sites of each place there's a spike, by the name Spike.LAYOUT gives:
-- the course's, and each of the spike rounds' maps' (system 25).
Spike.Layouts = {
	course = Spike.CourseSites,
} :: { [string]: { Zone } }
for _, key in SpikeMaps.MAPS do
	local map = SpikeMaps.Maps[key]
	Spike.Layouts[map.LAYOUT] = map.zones()
end

-- Rotates v about +Y by -yaw (world -> box local space), as Hitboxes does.
local function toLocal(v: vector, yaw: number): vector
	local c, s = math.cos(yaw), math.sin(yaw)
	return vector.create(v.x * c - v.z * s, v.y, v.x * s + v.z * c)
end

function Spike.inZone(zone: Zone, point: vector): boolean
	local d = toLocal(point - zone.center, zone.yaw)
	local h = zone.half
	return math.abs(d.x) <= h.x and math.abs(d.y) <= h.y and math.abs(d.z) <= h.z
end

-- The site whose plant area `point` is in, if any.
function Spike.siteAt(zones: { Zone }, point: vector): string?
	for _, zone in zones do
		if Spike.inZone(zone, point) then
			return zone.site
		end
	end
	return nil
end

-- Whether feet at `feet` are close enough to the spike at `spike` to defuse
-- it (the eye's sight of it is checked apart).
function Spike.inDefuseRange(feet: vector, spike: vector): boolean
	local d = feet - spike
	return math.abs(d.y) <= Spike.Params.defuseHeight.value and d.x * d.x + d.z * d.z <= Spike.Params.defuseRange.value ^ 2
end

-- Whether feet at `feet` run over a spike lying at `spike`.
function Spike.runsOver(feet: vector, spike: vector): boolean
	local d = feet - spike
	return math.abs(d.y) <= Spike.Params.pickupHeight.value and d.x * d.x + d.z * d.z <= Spike.Params.pickupRange.value ^ 2
end

-- Seconds a defuse takes from here: the whole of it, or the second half
-- once the first is saved.
function Spike.defuseTime(halfSaved: boolean): number
	local full = Spike.Params.defuseTime.value
	return if halfSaved then full - Spike.Params.defuseHalf.value else full
end

-- How far a defuse has got, `elapsed` seconds into it: seconds of the whole
-- 7, counting a saved first half.
function Spike.defuseProgress(halfSaved: boolean, elapsed: number): number
	return elapsed + (if halfSaved then Spike.Params.defuseHalf.value else 0)
end

-- Beeps a second `since` seconds after the plant.
function Spike.beepRate(since: number): number
	local rate = Spike.Beeps[1].perSecond
	for _, step in Spike.Beeps do
		if since >= step.from then
			rate = step.perSecond
		end
	end
	return rate
end

-- The times of every beep, in seconds after the plant: the first at the
-- plant, then each at the rate of the stretch it starts in.
function Spike.beepTimes(): { number }
	local times = {}
	local t = 0
	local last = Spike.Params.detonateTime.value
	while t < last - 1e-9 do
		table.insert(times, t)
		t += 1 / Spike.beepRate(t + 1e-9)
		-- Land on each stretch's start, so the rate changes on time.
		for _, step in Spike.Beeps do
			if step.from > times[#times] + 1e-9 and t > step.from + 1e-9 then
				t = step.from
				break
			end
		end
	end
	return times
end

-- When the blast reaches `distance` metres from the spike, in seconds after
-- the detonation, or nil when it's out of the blast.
function Spike.blastReaches(distance: number): number?
	local radius = Spike.Params.blastRadius.value
	if distance > radius then
		return nil
	end
	return distance / radius * Spike.Params.blastGrowTime.value
end

-- A context in which nothing can be done with the spike.
Spike.NONE = table.freeze({ zones = {}, canPlant = false, canDefuse = false, planted = nil, halfSaved = false, sees = nil }) :: Context

return Spike
