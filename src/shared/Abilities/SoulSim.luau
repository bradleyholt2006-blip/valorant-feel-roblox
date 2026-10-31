--!strict
-- Reyna's Soul Orbs (system 73): which of hers is in her reach, who earns
-- one, how they go over the wire, and Devour's heal.
--
-- An enemy she kills leaves her one where they fell, and so does one who
-- dies within AbilityConfig.Reyna's `damaged` of her last hurting them,
-- whoever killed them; it lasts its `orbLife`. One is in her reach while it
-- lasts, its middle within the reach of her eye with nothing solid between
-- (`sees`, the caller's: RobloxSpike's over the level in Roblox, a fake in
-- the offline tests); of those, the nearest, and of two as near, the lower
-- number. Where it fell is kept to the centimetre and when it goes to the
-- millisecond, so the wire carries it exactly and her client picks as the
-- server does.
--
-- Her orbs go to her as a player attribute (SoulSim.ATTRIBUTE): each as its
-- number, where it fell (metres) and when it goes (server time), as
-- "7,1.25,0.02,-3.5,812.345", apart by ";", "" for none.
--
-- Devour's heal gives its health over its time at a steady rate, in whole
-- points (CombatServer.overheal, past her most up to the overheal's, for
-- its `overhealTime`: SoulServer).
--
-- No Roblox APIs here.

local AbilityConfig = require("./AbilityConfig")

local RY = AbilityConfig.Reyna

-- A Soul Orb: its number, where it fell (the feet of the one who fell,
-- metres) and when it goes (server time).
export type Orb = { id: number, at: vector, ends: number }
-- Devour's heal: when it started, and the whole points it has given.
export type Heal = { from: number, given: number }

local SoulSim = {}

-- The player attribute each Reyna's orbs go to her in.
SoulSim.ATTRIBUTE = "VFSouls"

local EPS = 1e-9

local function round(x: number, step: number): number
	return math.round(x / step) * step
end

-- An orb numbered `id`, fallen at `at` at `now`, lasting its time.
function SoulSim.orb(id: number, at: vector, now: number): Orb
	return {
		id = id,
		at = vector.create(round(at.x, 0.01), round(at.y, 0.01), round(at.z, 0.01)),
		ends = round(now + RY.orbLife.value, 0.001),
	}
end

-- Where an orb floats: its height over where they fell.
function SoulSim.middle(orb: Orb): vector
	return orb.at + vector.create(0, RY.height.value, 0)
end

-- Whether a death at `now` earns a Reyna an orb: she killed them, or she
-- last hurt them at `hurtAt` (nil for never), within its time before.
function SoulSim.earns(killer: boolean, hurtAt: number?, now: number): boolean
	return killer or (hurtAt ~= nil and now - hurtAt <= RY.damaged.value + EPS)
end

-- The orb in reach of `eye` at `now`, by its number, if any: of those that
-- last and are near enough, the nearest `sees` has nothing between, called
-- with the eye, where it fell and its height.
function SoulSim.pick(orbs: { Orb }, eye: vector, now: number, sees: (vector, vector, number) -> boolean): number?
	local near: { { orb: Orb, distance: number } } = {}
	for _, orb in orbs do
		local distance = vector.magnitude(SoulSim.middle(orb) - eye)
		if now < orb.ends and distance <= RY.reach.value then
			table.insert(near, { orb = orb, distance = distance })
		end
	end
	table.sort(near, function(a, b)
		if a.distance ~= b.distance then
			return a.distance < b.distance
		end
		return a.orb.id < b.orb.id
	end)
	for _, n in near do
		if sees(eye, n.orb.at, RY.height.value) then
			return n.orb.id
		end
	end
	return nil
end

-- The orbs that last at `now`.
function SoulSim.lasting(orbs: { Orb }, now: number): { Orb }
	local out = {}
	for _, orb in orbs do
		if now < orb.ends then
			table.insert(out, orb)
		end
	end
	return out
end

function SoulSim.encode(orbs: { Orb }): string
	local parts = table.create(#orbs)
	for _, orb in orbs do
		table.insert(parts, string.format("%d,%.2f,%.2f,%.2f,%.3f", orb.id, orb.at.x, orb.at.y, orb.at.z, orb.ends))
	end
	return table.concat(parts, ";")
end

-- The orbs an attribute carries; none for anything it can't read.
function SoulSim.decode(text: any): { Orb }
	local out = {}
	if type(text) ~= "string" then
		return out
	end
	for entry in string.gmatch(text, "[^;]+") do
		local a, b, c, d, e = string.match(entry, "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")
		local id, x, y, z, ends = tonumber(a), tonumber(b), tonumber(c), tonumber(d), tonumber(e)
		if id and x and y and z and ends then
			table.insert(out, { id = id, at = vector.create(x, y, z), ends = ends })
		end
	end
	return out
end

-- Devour's heal, started at `now`.
function SoulSim.heal(now: number): Heal
	return { from = now, given = 0 }
end

-- Whether a heal's time has run at `now`.
function SoulSim.over(h: Heal, now: number): boolean
	return now - h.from >= RY.healTime.value - EPS
end

-- The whole points a heal owes at `now`, taken as given, and whether it's
-- over: all it gives once its time has run.
function SoulSim.take(h: Heal, now: number): (number, boolean)
	local time = RY.healTime.value
	local over = SoulSim.over(h, now)
	local ran = math.clamp(now - h.from, 0, time)
	local total = RY.heal.value
	local due = if over then total else math.min(math.floor(total * ran / time + 1e-6), total)
	local owed = math.max(due - h.given, 0)
	h.given += owed
	return owed, over
end

return SoulSim
