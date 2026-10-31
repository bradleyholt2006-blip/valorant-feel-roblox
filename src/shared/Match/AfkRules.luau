--!strict
-- AFK in a match (system 70): how long a player in the spike rounds' match
-- under way has gone without playing, and what's due. Only time alive in a
-- round counts (its buy phase too, and after the plant): dead, or between
-- rounds, there's nothing to play, so the clock stops but keeps what it
-- had; out of a match it starts over. Anything played starts it over: a
-- key or button pressed or let go (not one held on: a crouch toggled on is
-- held from tick to tick), a look that turns the view more than
-- MatchConfig.Afk.turn from where it was as the clock last started, a
-- weapon asked for, a buy or a ping. Past `warnAfter` seconds the player's
-- warned, and past `outAfter` more they're due out of the match.
--
-- Pure, so the offline tests run it; AfkServer plays it.

local MatchConfig = require("./MatchConfig")

local A = MatchConfig.Afk

local AfkRules = {}

-- Whether a player's time counts now ("count"), stops ("pause": dead, or
-- between rounds) or starts over ("off": not in a match under way, or AFK's
-- off).
export type State = "count" | "pause" | "off"

export type Clock = {
	idle: number, -- seconds counted since they last played
	warned: boolean,
	-- The aim and the weapon asked for as the clock last started, to tell
	-- a look or a weapon from more of the same, and the keys held last
	-- tick; nil until a life's first input, as a life starts on the
	-- server's aim.
	yaw: number?,
	pitch: number?,
	slot: number?,
	buttons: number?,
}

function AfkRules.new(): Clock
	return { idle = 0, warned = false, yaw = nil, pitch = nil, slot = nil, buttons = nil }
end

-- Something played: the clock starts over, and any warning's taken back.
function AfkRules.played(c: Clock)
	c.idle = 0
	c.warned = false
end

-- A life starts, on the server's aim: its first input sets where the aim
-- is, and doesn't count as a look.
function AfkRules.spawned(c: Clock)
	c.yaw, c.pitch, c.slot, c.buttons = nil, nil, nil, nil
end

-- The least angle between two yaws, radians.
local function apart(a: number, b: number): number
	local d = (a - b) % (2 * math.pi)
	return math.min(d, 2 * math.pi - d)
end

-- One tick's input, from a player alive: whether it played at anything (and
-- if so the clock's started over).
function AfkRules.input(c: Clock, buttons: number, yaw: number, pitch: number, slot: number): boolean
	local lastYaw, lastPitch, lastSlot, lastButtons = c.yaw, c.pitch, c.slot, c.buttons
	c.buttons = buttons
	if lastYaw == nil or lastPitch == nil or lastSlot == nil or lastButtons == nil then
		c.yaw, c.pitch, c.slot = yaw, pitch, slot
		return false
	end
	local turn = A.turn.value
	local looked = apart(yaw, lastYaw) > turn or math.abs(pitch - lastPitch) > turn
	if buttons == lastButtons and not looked and slot == lastSlot then
		return false
	end
	c.yaw, c.pitch, c.slot = yaw, pitch, slot
	AfkRules.played(c)
	return true
end

-- Moves the clock on `dt` seconds in `state`, warning after `warnAfter`
-- and out `outAfter` after that. Returns "out" once they're due out of the
-- match (and starts the clock over), else nil; `c.warned` says whether
-- they're warned.
function AfkRules.step(c: Clock, dt: number, state: State, warnAfter: number, outAfter: number): "out"?
	if state == "off" then
		AfkRules.played(c)
		return nil
	elseif state == "pause" then
		return nil
	end
	c.idle += dt
	if c.idle >= warnAfter + outAfter then
		AfkRules.played(c)
		return "out"
	end
	c.warned = c.idle >= warnAfter
	return nil
end

-- Seconds counted until they're due out, once warned.
function AfkRules.left(c: Clock, warnAfter: number, outAfter: number): number
	return math.max(warnAfter + outAfter - c.idle, 0)
end

return AfkRules
