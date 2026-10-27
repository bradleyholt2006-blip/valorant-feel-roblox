--!strict
-- Sova's Shock Bolt (system 45): where its bolt bursts, and whom it hurts.
--   * loosed from his bow as the Recon Bolt is, it flies as the Recon Bolt
--     does (BoltSim: the same keys and the same bounces), and where the
--     Recon Bolt would stick, it bursts
--   * the burst looks from just off the surface it met (ShockSim.eye), and
--     hurts everyone it has a point of in sight within its outer radius,
--     with whatever hides them from a player's eye in the way (Sight), by
--     how far the nearest point of them it sees is: its most within its
--     inner radius, and less further out, in a straight line to its least
--     at the outer, in whole points (ShockSim.damageAt)
-- How much of it its owner and his side take is the server's (ShockServer).
--
-- No Roblox APIs here, so the offline tests burst it in a fake world.

local AbilityConfig = require("./AbilityConfig")

-- Someone a burst might hurt: their entity id, and the points of them that
-- count (Sight.points).
export type Target = { id: number, points: { vector } }
-- Someone a burst hurts: their entity id, how far the nearest point of them
-- it sees is (metres), and the damage it does them.
export type Hit = { id: number, distance: number, damage: number }

local ShockSim = {}

local SB = AbilityConfig.ShockBolt
local EPS = 1e-9

-- What its damage is credited to, for the kill feed and the match's
-- record: the bow's weapon.
ShockSim.WEAPON = "shockbow"
-- The player attributes that keep, for scripted checks, where the owner's
-- last bolt burst (metres) and whom it hurt, each name with the damage it
-- did them, in the order of their names ("" for nobody).
ShockSim.POINT_ATTRIBUTE = "VFLastShock"
ShockSim.HITS_ATTRIBUTE = "VFShockHits"

-- The damage a burst does `distance` metres away: its most within its
-- inner radius, then less in a straight line to its least at its outer,
-- and none past it, in whole points.
function ShockSim.damageAt(distance: number): number
	local inner, outer = SB.inner.value, SB.outer.value
	if distance > outer + EPS then
		return 0
	end
	if distance <= inner then
		return SB.damage.value
	end
	local k = (distance - inner) / (outer - inner)
	return math.floor(SB.damage.value + (SB.least.value - SB.damage.value) * k + 0.5)
end

-- Where a burst at `point`, on a surface facing `normal`, looks from.
function ShockSim.eye(point: vector, normal: vector): vector
	return point + normal * SB.lift.value
end

-- Whom a burst at `point` on a surface facing `normal` hurts, of `targets`,
-- with `hidden` saying whether anything's in the way between two points:
-- each one with a point it sees within its outer radius, by the nearest it
-- sees, in the order given.
function ShockSim.hits(point: vector, normal: vector, targets: { Target }, hidden: (vector, vector) -> boolean): { Hit }
	local eye = ShockSim.eye(point, normal)
	local outer = SB.outer.value
	local out: { Hit } = {}
	for _, target in targets do
		local best: number? = nil
		for _, p in target.points do
			local d = vector.magnitude(p - eye)
			if d <= outer + EPS and (best == nil or d < best) and not hidden(eye, p) then
				best = d
			end
		end
		if best then
			table.insert(out, { id = target.id, distance = best, damage = ShockSim.damageAt(best) })
		end
	end
	return out
end

return ShockSim
