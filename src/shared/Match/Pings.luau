--!strict
-- Pings (system 52): a mark for your side, made without a word ('The
-- in-game ping system was created with the simple goal of allowing players
-- to communicate with one another without using their mic', Patch 9.11).
--   * Z tapped pings what the crosshair's on ('Tapping a designated Ping
--     Key will ping whatever you're looking at', Riot Support): an enemy in
--     sight ('With your sight centred on the enemy, just quickly tap your
--     ping hotkey', Gfinity), the spike or a gun on the ground ('Spikes,
--     weapons', Riot Support), and anything else the place it's on ('even a
--     particularly striking wall')
--   * Z held opens the wheel ('Tap for a quick marker; hold the key to open
--     the ping wheel', DostGame), its four as The Global Gaming lists them:
--     Danger, Watching, Pushing and Need support. The mouse picks one by
--     moving towards it, and letting Z go pings it on the place the
--     crosshair's on
--   * with the big map up, a left click pings a place on it, which shows
--     on the minimap and the big map and nowhere in the world ('Pings made
--     on your map will no longer appear in the world and only display on
--     the minimap', Patch 9.11), dead or alive (The Global Gaming: 'pinging
--     even though you're dead')
--   * a cloud or a smoke stops a ping along the crosshair where it meets it
--     ('Smokes will block your in-world pings from traveling through them
--     and instead land on the smoke', Patch 9.11)
--   * a few pings in quick succession, then one more each little while
--     (Patch 0.47: 'Fixed a bug where players could spam pings'), all of
--     them counted alike (Patch 0.49: 'direct bound pings were used to reach
--     usage limit'), the wheel greyed out while there are none left (Patch
--     1.0: 'the ping wheel on the megamap would not grey out when ping
--     limited')
-- How many, how long a ping shows, how long Z is held for the wheel and the
-- rest of the numbers aren't published: they're ours (Params).
--
-- No Roblox APIs here: the server passes in how far the crosshair goes
-- before the level, and what's in the way of sight, so the offline tests
-- run it on a fake one.

local HealSim = require("../Abilities/HealSim")
local Hitboxes = require("../Combat/Hitboxes")
local Sight = require("../Combat/Sight")
local WeaponConfig = require("../Weapons/WeaponConfig")

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

-- What a ping marks: a place, an enemy, the spike, a gun, or a place on the
-- map.
export type Kind = "place" | "enemy" | "spike" | "gun" | "map"

-- A ping as the server judged it: what it marks, the wheel's option it was
-- made with, where (metres), the enemy's entity or the gun's id, and the
-- gun.
export type Ping = {
	kind: Kind,
	option: string?,
	position: vector,
	target: number?,
	weapon: string?,
}

-- An enemy as the pinger's screen showed them, and something on the ground
-- that can be pinged, by its middle: the spike, or a gun with its id.
export type Body = { id: number, pose: Hitboxes.Pose }
export type Item = { kind: "spike" | "gun", id: number?, weapon: string?, middle: vector }
export type Cloud = { centre: vector, radius: number }

-- What a ping along the crosshair is judged on: the eye and the way it
-- looks (a unit vector), how far it goes before the level (nil for nothing
-- within reach), the clouds and smokes standing, the enemies, what's on the
-- ground, `hidden` (true when something is in the way of sight from one
-- point to another), and the wheel's option, if one was picked.
export type Look = {
	eye: vector,
	look: vector,
	level: number?,
	clouds: { Cloud },
	enemies: { Body },
	items: { Item },
	hidden: (vector, vector) -> boolean,
	option: string?,
}

-- A player's pings left (fractions of one count towards the next), as of
-- `at`.
export type Budget = { left: number, at: number }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local Pings = {}

local EPS = 1e-9
local UP = vector.create(0, 1, 0)

Pings.Params = {
	hold = p(
		0.25,
		"estimate",
		"Seconds Z is held before the wheel opens: 'Tap for a quick marker; hold the key to open the ping wheel' (DostGame)"
	),
	duration = p(4, "estimate", "Seconds a ping shows, in the world and on the map; not published"),
	fadeOut = p(0.5, "estimate", "Seconds at the end of a ping's time in which it fades away (ours)"),
	budget = p(4, "estimate", "Pings in quick succession before the limit (Patch 0.47's spam fix; Dot Esports: 'a limit'); not published"),
	refill = p(1.5, "estimate", "Seconds for each ping back once some are spent; not published"),
	reach = p(200, "estimate", "Metres a ping along the crosshair goes at the most: further than any map's longest sightline (ours)"),
	body = p(0.4, "estimate", "Metres the crosshair may pass from an enemy's body and ping them, as the Healing Orb's width (ours)"),
	item = p(0.4, "estimate", "Metres the crosshair may pass from the spike's or a gun's middle and ping it, as F's at a gun (GroundGuns)"),
	aimSlack = p(
		10,
		"estimate",
		"Degrees the look a ping comes with may be from the server's last of the player's, as the mouse moves on (ours)"
	),
	fadeNear = p(
		48,
		"estimate",
		"Pixels from the crosshair a marker fades within ('Ping elements now fade when under player aim', Patch 0.49)"
	),
	faded = p(0.7, "estimate", "How see-through a marker is under the crosshair (ours)"),
	wheelPick = p(30, "estimate", "Pixels the mouse moves from the wheel's middle towards an option to pick it (ours)"),
}

-- The wheel's options, clockwise from the top, as The Global Gaming lists
-- them ('Danger incoming', 'Watching area', 'I am pushing the area' and
-- 'Need support'; Riot Support has 'Need Support').
Pings.OPTIONS = { "danger", "watching", "pushing", "help" } :: { string }

-- What each kind and option says on its marker and in the wheel (ours,
-- but for Need support's): a gun's says its name.
Pings.Words = {
	place = "HERE",
	enemy = "ENEMY",
	spike = "SPIKE",
	danger = "DANGER",
	watching = "WATCHING",
	pushing = "PUSHING",
	help = "NEED SUPPORT",
} :: { [string]: string }

-- Whether `kind` is a ping's kind, and `option` one of the wheel's.
function Pings.isKind(kind: any): boolean
	return kind == "place" or kind == "enemy" or kind == "spike" or kind == "gun" or kind == "map"
end

function Pings.isOption(option: any): boolean
	return type(option) == "string" and table.find(Pings.OPTIONS, option) ~= nil
end

-- The limit -------------------------------------------------------------------

-- A budget with every ping in it, at `now`.
function Pings.newBudget(now: number): Budget
	return { left = Pings.Params.budget.value, at = now }
end

-- The pings a budget has at `now`: what it had, and one more for each
-- `refill` since, up to `budget`.
function Pings.left(b: Budget, now: number): number
	local P = Pings.Params
	return math.min(P.budget.value, b.left + math.max(now - b.at, 0) / P.refill.value)
end

-- Spends one of a budget's pings at `now`, if it has one. Returns whether
-- it did.
function Pings.spend(b: Budget, now: number): boolean
	local left = Pings.left(b, now)
	if left < 1 - EPS then
		return false
	end
	b.left = left - 1
	b.at = math.max(now, b.at)
	return true
end

-- Along the crosshair --------------------------------------------------------------

-- How far along a ray from `eye` (`look` a unit vector) it meets the edge
-- of a cloud: where it goes in, or from inside it, where it comes out (a
-- ping can't go through the edge either way). Nil if it never does.
function Pings.cloudAt(eye: vector, look: vector, cloud: Cloud): number?
	local r = cloud.radius
	if r <= 0 then
		return nil
	end
	local to = cloud.centre - eye
	local along = vector.dot(to, look)
	local miss2 = vector.dot(to, to) - along * along
	if miss2 > r * r then
		return nil
	end
	local half = math.sqrt(r * r - miss2)
	if along + half < 0 then
		return nil
	end
	return if along - half >= 0 then along - half else along + half
end

-- How tall a body stands, feet to the top of the head, crouched as it is.
local function height(pose: Hitboxes.Pose): number
	local head = Hitboxes.build(pose)[1]
	return head.center.y + head.half.y - pose.position.y
end

-- How far along the crosshair it passes within `body` of a pose, anywhere
-- from its feet to the top of its head, no further than `most`; nil if it
-- doesn't.
local function alongBody(eye: vector, look: vector, pose: Hitboxes.Pose, most: number): number?
	local s, apart = HealSim.closest(eye, eye + look * most, pose.position, pose.position + UP * height(pose))
	return if apart <= Pings.Params.body.value + EPS then s * most else nil
end

-- How far along the crosshair it passes within `radius` of `point`, no
-- further than `most`; nil if it doesn't.
local function alongPoint(eye: vector, look: vector, point: vector, radius: number, most: number): number?
	local offset = point - eye
	local along = vector.dot(offset, look)
	if along < 0 or along > most then
		return nil
	end
	return if vector.magnitude(offset - look * along) <= radius + EPS then along else nil
end

-- Whether any of the points of a body that count (Sight.points) is in sight
-- of the eye.
local function seen(l: Look, pose: Hitboxes.Pose): boolean
	for _, point in Sight.points(pose) do
		if not l.hidden(l.eye, point) then
			return true
		end
	end
	return false
end

-- What a ping along the crosshair marks. It goes as far as the level or
-- the first cloud's edge lets it (`reach` at the most). Without the wheel's
-- option, it marks the first along it of an enemy in sight whose body it
-- passes close to, and the spike or a gun in sight whose middle it does,
-- as far as it goes and a little past (`body` and `item`, which a body or
-- a thing lying against what stops it needs). Otherwise, and with the
-- wheel's option, it marks the place where it stops. Nil when nothing stops
-- it (the sky).
function Pings.resolve(l: Look): Ping?
	local P = Pings.Params
	local stop = math.min(l.level or P.reach.value, P.reach.value)
	local landed = l.level ~= nil and l.level <= P.reach.value
	for _, cloud in l.clouds do
		local at = Pings.cloudAt(l.eye, l.look, cloud)
		if at and at < stop then
			stop, landed = at, true
		end
	end
	if not l.option then
		local best: Ping? = nil
		local nearest = math.huge
		for _, enemy in l.enemies do
			local along = alongBody(l.eye, l.look, enemy.pose, stop + P.body.value)
			if along and along < nearest and seen(l, enemy.pose) then
				best, nearest = { kind = "enemy", position = l.eye + l.look * along, target = enemy.id }, along
			end
		end
		for _, item in l.items do
			local along = alongPoint(l.eye, l.look, item.middle, P.item.value, stop + P.item.value)
			if along and along < nearest and not l.hidden(l.eye, item.middle) then
				best, nearest = { kind = item.kind, position = item.middle, target = item.id, weapon = item.weapon }, along
			end
		end
		if best then
			return best
		end
	end
	if not landed then
		return nil
	end
	return { kind = "place", option = l.option, position = l.eye + l.look * stop }
end

-- The look a ping's judged along: the one it came with, within `aimSlack`
-- of the server's last of the player's (`own`), or else that.
function Pings.aimFrom(own: vector, claimed: vector): vector
	local slack = math.cos(math.rad(Pings.Params.aimSlack.value))
	local length = vector.magnitude(claimed)
	if not (length > EPS) then
		return own
	end
	local unit = claimed / length
	return if vector.dot(unit, own) >= slack then unit else own
end

-- The wheel ----------------------------------------------------------------------

-- The option the mouse `x`, `y` pixels right and down from the wheel's
-- middle picks: the one it's moved towards, once it's `wheelPick` out; nil
-- nearer the middle.
function Pings.pick(x: number, y: number): string?
	if not (x * x + y * y >= Pings.Params.wheelPick.value ^ 2) then
		return nil
	end
	local n = #Pings.OPTIONS
	local turn = math.atan2(x, -y) -- clockwise from the top
	return Pings.OPTIONS[math.floor(turn / (2 * math.pi / n) + 0.5) % n + 1]
end

-- How it shows ------------------------------------------------------------------

-- What a ping's marker says: its option's word, a gun's name, or its
-- kind's word ("" for the map's, which has none).
function Pings.word(ping: Ping): string
	local option = ping.option
	if option then
		return Pings.Words[option] or ""
	end
	if ping.kind == "gun" then
		local def = if ping.weapon then WeaponConfig.Defs[ping.weapon] else nil
		return if def then string.upper(def.name) else "GUN"
	end
	return Pings.Words[ping.kind] or ""
end

-- A ping as scripted checks list it: its option, or else its kind.
function Pings.tag(ping: Ping): string
	return ping.option or ping.kind
end

-- How see-through a ping's marker is, `age` seconds after it came, `off`
-- pixels from the crosshair: fading away in the last of its time
-- (`fadeOut`), and faded while it's under the crosshair (`fadeNear`).
-- 1 once its time's up.
function Pings.transparency(age: number, off: number): number
	local P = Pings.Params
	local left = P.duration.value - age
	if left <= 0 then
		return 1
	end
	local shown = math.min(left / P.fadeOut.value, 1)
	if off <= P.fadeNear.value then
		shown *= 1 - P.faded.value
	end
	return 1 - shown
end

return Pings
