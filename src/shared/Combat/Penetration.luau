--!strict
-- Wall penetration: traces a shot through the level and says how much of its
-- damage is left at any point along it. Pure, like ShotResolver: the level
-- sits behind a two-method interface (Level), so client prediction, the
-- server and the offline tests trace shots through walls with the same code.
--
-- The rules (numbers in WeaponConfig.Penetration, sources in
-- docs/research/05-wall-penetration.md):
--   * each weapon has a class and each surface a material; a class gets
--     through a material up to a limit thickness, and not at all when the
--     limit is 0 (solid surfaces stop every bullet)
--   * thickness is measured along the ray, so a wall shot at an angle is
--     thicker than the same wall shot square on
--   * a bullet that can't pay for a wall stops inside it, as deep as its
--     budget reaches. A target in that stretch can still be hit and takes the
--     damage from before the wall, like the reference when a character clips
--     into a wall ("while it is still in the wall, it deals full damage")
--   * past the walls, damage is multiplied by 1 - damageLoss * budget spent
--   * pieces that touch or overlap are one wall: only the first pays the
--     entry cost and an overlap is paid for once

local WeaponConfig = require("../Weapons/WeaponConfig")

export type Material = "soft" | "medium" | "hard" | "solid"

-- A surface the ray enters.
export type Surface = {
	distance: number, -- metres from the origin
	normal: vector,
	material: Material,
	name: string?, -- what the level calls the surface's material, for display
	key: any, -- the level's handle on that piece of geometry
}

export type Level = {
	-- The nearest surface along the ray within maxDistance, leaving out the
	-- pieces in `skip` and any piece the origin is inside.
	cast: (self: Level, origin: vector, dir: vector, maxDistance: number, skip: { any }) -> Surface?,
	-- Where the ray leaves the piece it entered at `surface`, if that is at
	-- most `depth` metres past the entry: distance from the origin and the
	-- exit face's outward normal.
	exit: (self: Level, origin: vector, dir: vector, surface: Surface, depth: number) -> (number?, vector?),
}

export type Wall = {
	material: Material,
	name: string?,
	entry: number, -- metres from the origin
	exit: number?, -- nil: the bullet stopped in this wall
	normal: vector, -- entry face
	exitNormal: vector?,
	thickness: number, -- metres of this piece the bullet went through (to the exit, or to where it stopped)
	used: number, -- share of the bullet's budget this piece took
	multiplier: number, -- damage multiplier past this piece
	continues: boolean, -- touches or overlaps the piece before it: the same wall
	key: any,
}

export type Trace = {
	walls: { Wall },
	stop: number, -- metres: where the bullet stopped, or the range
	stopped: boolean, -- a wall stopped it (false: it went the full range)
}

local Penetration = {}

-- A piece that starts this close past the last exit continues the same wall.
Penetration.CONTACT = 0.01

local function limitFor(class: WeaponConfig.PenetrationClass, material: Material): number
	local limits = WeaponConfig.Penetration.limits
	local row = limits[class] or limits.none
	return row[material] or 0
end

-- The thickest wall of a material a class gets through on its own, square on (metres).
function Penetration.limit(class: WeaponConfig.PenetrationClass, material: Material): number
	return limitFor(class, material)
end

function Penetration.trace(level: Level, origin: vector, dir: vector, class: WeaponConfig.PenetrationClass, maxRange: number): Trace
	local cfg = WeaponConfig.Penetration
	local entryCost = cfg.entryCost.value
	local damageLoss = cfg.damageLoss.value
	local walls: { Wall } = {}
	local skip: { any } = {}
	local budget = 1
	local multiplier = 1
	local reached = -math.huge -- furthest exit so far

	for piece = 1, cfg.maxPieces + 1 do
		local surface = level:cast(origin, dir, maxRange, skip)
		if not surface then
			break
		end
		table.insert(skip, surface.key)
		local continues = surface.distance <= reached + Penetration.CONTACT
		local cost = if continues then 0 else entryCost
		-- Past maxPieces, whatever comes next stops the bullet.
		local limit = if piece > cfg.maxPieces then 0 else limitFor(class, surface.material)

		if limit <= 0 or budget - cost <= 0 then
			table.insert(walls, {
				material = surface.material,
				name = surface.name,
				entry = surface.distance,
				exit = nil,
				normal = surface.normal,
				exitNormal = nil,
				thickness = 0,
				used = 0,
				multiplier = multiplier,
				continues = continues,
				key = surface.key,
			})
			return { walls = walls, stop = surface.distance, stopped = true }
		end

		budget -= cost
		local perMetre = (1 - entryCost) / limit
		-- An overlap with the piece before is already paid for.
		local start = math.max(surface.distance, reached)
		local reach = budget / perMetre
		local exit, exitNormal = level:exit(origin, dir, surface, start + reach - surface.distance)

		if exit == nil then
			table.insert(walls, {
				material = surface.material,
				name = surface.name,
				entry = surface.distance,
				exit = nil,
				normal = surface.normal,
				exitNormal = nil,
				thickness = reach,
				used = cost + budget,
				multiplier = 1 - damageLoss,
				continues = continues,
				key = surface.key,
			})
			return { walls = walls, stop = start + reach, stopped = true }
		end

		if exit <= reached then
			continue -- inside a piece already gone through
		end
		local thickness = math.max(exit - start, 0)
		local used = thickness * perMetre
		budget = math.max(budget - used, 0)
		multiplier = 1 - damageLoss * (1 - budget)
		reached = exit
		table.insert(walls, {
			material = surface.material,
			name = surface.name,
			entry = surface.distance,
			exit = exit,
			normal = surface.normal,
			exitNormal = exitNormal,
			thickness = thickness,
			used = cost + used,
			multiplier = multiplier,
			continues = continues,
			key = surface.key,
		})
	end
	return { walls = walls, stop = maxRange, stopped = false }
end

-- Damage multiplier for a hit `distance` metres along the shot: from the
-- walls fully gone through before it. A hit inside a wall keeps the
-- multiplier from before that wall.
function Penetration.multiplierAt(trace: Trace, distance: number): number
	local m = 1
	for _, wall in trace.walls do
		local exit = wall.exit
		if exit == nil or exit > distance then
			break
		end
		m = wall.multiplier
	end
	return m
end

-- Walls (not pieces) fully gone through before `distance`.
function Penetration.wallsBefore(trace: Trace, distance: number): number
	local n = 0
	for _, wall in trace.walls do
		local exit = wall.exit
		if exit == nil or exit > distance then
			break
		end
		if not wall.continues then
			n += 1
		end
	end
	return n
end

-- Damage left after one wall `thickness` metres deep, from open air, hit
-- `angle` degrees off square on; nil if the bullet stops in it. The same
-- rules as trace, for tables and debug readouts.
function Penetration.oneWall(class: WeaponConfig.PenetrationClass, material: Material, thickness: number, angle: number?): number?
	local limit = limitFor(class, material)
	local along = thickness / math.cos(math.rad(angle or 0))
	if limit <= 0 or along > limit then
		return nil
	end
	local cfg = WeaponConfig.Penetration
	local entryCost = cfg.entryCost.value
	return 1 - cfg.damageLoss.value * (entryCost + (1 - entryCost) * along / limit)
end

-- Damage after walls, rounded; a hit that gets through always does at least 1.
function Penetration.damage(base: number, multiplier: number): number
	if multiplier >= 1 or base <= 0 then
		return base
	end
	return math.max(1, math.floor(base * multiplier + 0.5))
end

return Penetration
