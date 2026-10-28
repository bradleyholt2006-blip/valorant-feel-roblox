--!strict
-- The bullets of one round together: a volley. One bullet for most guns, a
-- shotgun's pellets, the Classic's right-click three. Each bullet is traced
-- and does its own damage, but a target takes a volley's damage as one hit:
-- one damage event and hit slow on the server, one hit marker, damage
-- number and hit sound for the shooter, so a shotgun blast reads as one
-- shot. Each total also counts its bullets by the part each struck, for the
-- combat report (system 53). Pure, so the offline tests check it.

export type Hit = { target: number, region: string, damage: number }
-- How many bullets struck each part.
export type Parts = { head: number, body: number, legs: number }
export type Total = { target: number, region: string, damage: number, pellets: number, parts: Parts }

local Volley = {}

local RANK: { [string]: number } = { head = 3, body = 2, legs = 1 }

-- Adds up the bullets that hit by target, in the order each target was first
-- hit. The region that counts is the best one hit: head, then body, then legs.
function Volley.totals(hits: { Hit }): { Total }
	local out: { Total } = {}
	local byTarget: { [number]: Total } = {}
	for _, hit in hits do
		local total: Total = byTarget[hit.target]
			or { target = hit.target, region = hit.region, damage = 0, pellets = 0, parts = { head = 0, body = 0, legs = 0 } }
		if byTarget[hit.target] == nil then
			byTarget[hit.target] = total
			table.insert(out, total)
		end
		total.damage += hit.damage
		total.pellets += 1
		local parts = total.parts
		if hit.region == "head" then
			parts.head += 1
		elseif hit.region == "body" then
			parts.body += 1
		elseif hit.region == "legs" then
			parts.legs += 1
		end
		if (RANK[hit.region] or 0) > (RANK[total.region] or 0) then
			total.region = hit.region
		end
	end
	return out
end

return Volley
