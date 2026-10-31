--!strict
-- Health and a shield (systems 2 and 9). While the shield lasts it takes its
-- share of every hit (Light and Heavy Armor about two thirds, the Regen
-- Shield all of it) and health takes the rest; once it's gone, health takes
-- everything. A hit that doesn't kill takes exactly its damage off the two
-- together, and from full health the shield always runs out first, so the
-- shots it takes to kill are the ones their sum gives: only what the HUD
-- shows depends on the split. A Regen Shield also refills itself from a pool
-- of its own once it hasn't been hit for a while
-- (docs/research/09-arsenal.md). Health can go past its most only by an
-- overheal (Reyna's Devour, system 73), up to the most that gives, and
-- stays there until it's hit off or its time's up (Health.trim): nothing
-- else that heals takes it away.

local WeaponConfig = require("../Weapons/WeaponConfig")

export type State = {
	health: number,
	shield: number,
	maxHealth: number,
	kind: string, -- the shield worn: a WeaponConfig.Shields id, or "" for none
	maxShield: number,
	absorb: number, -- the share of each hit the shield takes while it lasts
	pool: number, -- a Regen Shield's points still to refill from
	lastHit: number, -- when it was last hit (a Regen Shield waits from then)
	alive: boolean,
}

export type DamageResult = {
	damage: number, -- total applied
	shieldDamage: number,
	healthDamage: number,
	killed: boolean,
}

local Health = {}

-- Below this, health is gone: a split hit works in fractions, and a kill
-- must not miss by a rounding error.
local EPS = 1e-6

-- Puts on a fresh shield of this kind ("" for none): full, with a full pool.
-- It stays the kind worn through Health.reset, for the next life.
function Health.setShield(s: State, kind: string)
	local def = WeaponConfig.Shields[kind]
	local regen = def and def.regen
	s.kind = if def then kind else ""
	s.maxShield = if def then def.points.value else 0
	s.shield = s.maxShield
	s.absorb = if def then def.absorb.value else 1
	s.pool = if regen then regen.pool.value else 0
end

function Health.new(maxHealth: number, kind: string?): State
	local s: State = {
		health = maxHealth,
		shield = 0,
		maxHealth = maxHealth,
		kind = "",
		maxShield = 0,
		absorb = 1,
		pool = 0,
		lastHit = -math.huge,
		alive = true,
	}
	Health.setShield(s, kind or "")
	return s
end

-- A hit of `amount` at time `now` (the time only matters to a Regen Shield).
function Health.apply(s: State, amount: number, now: number?): DamageResult
	if not s.alive or amount <= 0 then
		return { damage = 0, shieldDamage = 0, healthDamage = 0, killed = false }
	end
	if now then
		s.lastHit = now
	end
	local toShield = math.min(s.shield, amount * s.absorb)
	s.shield -= toShield
	if s.shield < EPS then
		s.shield = 0
	end
	local toHealth = math.min(s.health, amount - toShield)
	s.health -= toHealth
	local killed = s.health < EPS
	if killed then
		s.health = 0
		s.alive = false
	end
	return { damage = toShield + toHealth, shieldDamage = toShield, healthDamage = toHealth, killed = killed }
end

-- A Regen Shield's refill over the `dt` seconds up to `now`: `rate` points a
-- second from the pool once it hasn't been hit for its delay, until it's
-- full or the pool is empty. Returns whether the shield changed.
function Health.step(s: State, now: number, dt: number): boolean
	local def = WeaponConfig.Shields[s.kind]
	local regen = def and def.regen
	if not regen or not s.alive or s.shield >= s.maxShield or s.pool <= 0 or now - s.lastHit < regen.delay.value then
		return false
	end
	local add = math.min(regen.rate.value * dt, s.maxShield - s.shield, s.pool)
	if add <= 0 then
		return false
	end
	s.shield += add
	s.pool -= add
	if s.shield > s.maxShield - EPS then
		s.shield = s.maxShield
	end
	if s.pool < EPS then
		s.pool = 0
	end
	return true
end

-- A shield's points and its pool, to put back as they were: a survivor's,
-- into the next round, and a damaged one, for a fresh one sold back.
export type Kept = { shield: number, pool: number }

function Health.keep(s: State): Kept
	return { shield = s.shield, pool = s.pool }
end

-- Puts back what `kept` describes, on the shield of the same kind.
function Health.restore(s: State, kept: Kept)
	s.shield = math.min(kept.shield, s.maxShield)
	s.pool = math.min(kept.pool, s.pool)
end

-- A new life: full health and a fresh shield of the kind worn.
function Health.reset(s: State)
	s.health = s.maxHealth
	s.alive = true
	s.lastHit = -math.huge
	Health.setShield(s, s.kind)
end

-- A life under way made whole (deathmatch's health packs, system 26): full
-- health, an overheal kept, and a fresh shield of the kind worn. Nothing
-- for the dead.
function Health.heal(s: State)
	if not s.alive then
		return
	end
	s.health = math.max(s.health, s.maxHealth)
	Health.setShield(s, s.kind)
end

-- Some health and some shield back for a living one (Team Deathmatch's
-- Recovery Orbs, system 28), each up to its most, an overheal kept: the
-- shield of the kind worn, and a Regen Shield's pool left as it is.
-- Returns whether either changed.
function Health.mend(s: State, health: number, shield: number): boolean
	if not s.alive then
		return false
	end
	local h = math.max(math.min(s.health + math.max(health, 0), s.maxHealth), s.health)
	local sh = math.min(s.shield + math.max(shield, 0), s.maxShield)
	local changed = h ~= s.health or sh ~= s.shield
	s.health, s.shield = h, sh
	return changed
end

-- Some health back for a living one past its most, up to `most` (Reyna's
-- Devour, system 73): health already past that is kept. Returns whether it
-- changed.
function Health.overheal(s: State, health: number, most: number): boolean
	if not s.alive then
		return false
	end
	local h = math.max(math.min(s.health + math.max(health, 0), most), s.health)
	local changed = h ~= s.health
	s.health = h
	return changed
end

-- Health past its most back down to it (an overheal's time up). Returns
-- whether it changed.
function Health.trim(s: State): boolean
	if s.health <= s.maxHealth then
		return false
	end
	s.health = s.maxHealth
	return true
end

-- Whole points for display: a split hit leaves fractions, and anything left
-- counts as a point. Nothing left reads 0, never -0.
function Health.points(value: number): number
	local whole = math.ceil(value - 1e-9)
	return if whole > 0 then whole else 0
end

return Health
