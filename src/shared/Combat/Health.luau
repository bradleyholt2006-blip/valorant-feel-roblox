--!strict
-- Health + shields. Shields take damage first, then health (the reference's
-- armour behaves as extra hit points; see docs/research/02-weapon-firing.md).

export type State = {
	health: number,
	shield: number,
	maxHealth: number,
	maxShield: number,
	alive: boolean,
}

export type DamageResult = {
	damage: number, -- total applied
	shieldDamage: number,
	healthDamage: number,
	killed: boolean,
}

local Health = {}

function Health.new(maxHealth: number, shield: number): State
	return { health = maxHealth, shield = shield, maxHealth = maxHealth, maxShield = shield, alive = true }
end

function Health.apply(s: State, amount: number): DamageResult
	if not s.alive or amount <= 0 then
		return { damage = 0, shieldDamage = 0, healthDamage = 0, killed = false }
	end
	local toShield = math.min(s.shield, amount)
	s.shield -= toShield
	local toHealth = math.min(s.health, amount - toShield)
	s.health -= toHealth
	local killed = s.health <= 0
	if killed then
		s.alive = false
	end
	return { damage = toShield + toHealth, shieldDamage = toShield, healthDamage = toHealth, killed = killed }
end

function Health.reset(s: State)
	s.health = s.maxHealth
	s.shield = s.maxShield
	s.alive = true
end

return Health
