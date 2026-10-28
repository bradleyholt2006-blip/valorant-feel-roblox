--!strict
-- The kill banner (system 55), as the reference's: each kill brings up a
-- banner for whoever made it, marked with which kill of theirs it is
-- ('Optimized multi-kill streak banners', Patch 1.02; 'the banner reflects
-- the number of kills', Sportskeeda), with a little red X on it for a
-- headshot (Patch 6.05 took the headshot text off it, leaving 'the kill
-- logo which will have a little red X', EsportsDriven), and with the kill
-- sound, higher with each kill (SoundMath.killPitch). Every kill's banner is
-- the size of the first (Patch 10.09 fixed some 'appearing smaller than
-- normal after the first kill').
--
-- The count runs over a stretch of play, as the combat report's: in
-- Skirmish and the spike rounds a round, from its start (KillBanner.clear)
-- to the next's, through a life Sage's Resurrection starts; elsewhere a
-- life, from a spawn (KillBanner.open) to the next. Only a kill of an enemy
-- counts (KillBanner.counts): not a teammate's, nor your own, nor a death
-- nobody caused. A practice dummy's does. Its marks count up to a
-- five-player side's ace, and a kill past that lights them all (Params).
--
-- Plain state the offline tests can play: the server keeps everyone's count
-- (BannerServer) and sends each kill's banner to whoever made it, alone,
-- which the client draws (KillBannerView). No Roblox APIs here.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

-- Each player's kills of the stretch, by entity id.
export type Log = { [number]: number }

-- A kill's banner, as its killer is told of it: which kill of the stretch it
-- is, who was killed, and whether it was a headshot.
export type Banner = { count: number, target: number, head: boolean }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local KillBanner = {}

KillBanner.Params = {
	marks = p(
		5,
		"community",
		"Kills a banner's marks count up to: a five-player side's ace, a kill past it an 'Overkill' (Sportskeeda, of skins' kill sounds)"
	),
	hold = p(1.5, "estimate", "Seconds a banner shows whole after its kill; not published"),
	fade = p(0.5, "estimate", "Seconds it then takes to fade away; not published"),
	pop = p(1.3, "estimate", "How much bigger than its size a banner comes up (ours)"),
	settle = p(0.15, "estimate", "Seconds it takes to settle to its size (ours)"),
}

local P = KillBanner.Params

function KillBanner.newLog(): Log
	return {}
end

-- A life starts for `id`, out of the rounds: no kills in it yet.
function KillBanner.open(log: Log, id: number)
	log[id] = nil
end

-- A round starts, or a mode: nobody's killed anyone in it.
function KillBanner.clear(log: Log)
	table.clear(log)
end

-- Whether a kill counts: made by somebody (`killer`; nil for the spike's
-- blast or a spawn room's burn) of somebody else, who isn't on their side
-- (`allies`).
function KillBanner.counts(killer: number?, victim: number, allies: boolean): boolean
	return killer ~= nil and killer ~= victim and not allies
end

-- A kill, as CombatServer tells of it, with the part the hit that made it
-- struck: counted for `killer` if it counts, with its banner; nil if not.
function KillBanner.killed(log: Log, killer: number?, victim: number, allies: boolean, region: string): Banner?
	if killer == nil or not KillBanner.counts(killer, victim, allies) then
		return nil
	end
	local count = (log[killer] or 0) + 1
	log[killer] = count
	return { count = count, target = victim, head = region == "head" }
end

-- How many of `id`'s kills of the stretch there are so far.
function KillBanner.count(log: Log, id: number): number
	return log[id] or 0
end

-- How many of its marks a banner lights: one for each kill of the stretch
-- so far, up to all of them.
function KillBanner.marks(count: number): number
	return math.clamp(count, 0, P.marks.value)
end

-- Whether a banner is the top one: an ace's, or past it.
function KillBanner.top(count: number): boolean
	return count >= P.marks.value
end

-- How solid a banner is `age` seconds after its kill: whole for hold, then
-- fading in a straight line over fade.
function KillBanner.alpha(age: number): number
	local hold, fade = P.hold.value, P.fade.value
	if age <= hold then
		return 1
	end
	return math.max(0, 1 - (age - hold) / fade)
end

-- How big a banner draws `age` seconds after its kill, as a share of its
-- size: pop as it comes up, easing down to its size over settle.
function KillBanner.scale(age: number): number
	local left = 1 - math.clamp(age / P.settle.value, 0, 1)
	return 1 + (P.pop.value - 1) * left * left
end

return KillBanner
