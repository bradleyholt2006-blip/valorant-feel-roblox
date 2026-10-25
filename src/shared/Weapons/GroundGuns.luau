--!strict
-- Guns on the ground (system 15), as plain state the offline tests can play.
-- G drops the gun in hand (PlayerSim), and in the spike rounds the dead drop
-- theirs: 'Agents automatically drop their Primary weapon (Or Secondary
-- weapon if they do not have a Primary) when they die' (the Valorant Fandom
-- wiki). Anyone can pick one up, either side: by walking over it, when its
-- slot is empty, or with F while looking at it, swapping it for the gun in
-- that slot, which drops in its place. A gun keeps its rounds on the ground,
-- and the ground is cleared as each round starts.
--
-- Same status convention as MovementConfig (docs/research/15-ground-guns.md).
-- No Roblox APIs here: the server says where a gun comes to rest.

local WeaponConfig = require("./WeaponConfig")

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

export type Gun = {
	id: number,
	weapon: string, -- a WeaponConfig id
	ammo: number, -- rounds in the magazine
	reserve: number,
	position: vector, -- metres: where it rests on the ground
	yaw: number, -- the way its muzzle points
	at: number, -- server time it was dropped
}

export type State = {
	guns: { [number]: Gun },
	nextId: number,
	version: number, -- goes up on every change
}

local GroundGuns = {}

GroundGuns.Params = {
	-- Walking over a gun, as the spike is run over.
	pickupRange = p(0.7, "estimate", "Horizontal distance from the feet that counts as walking over a gun, as the spike's"),
	pickupHeight = p(1.0, "estimate", "How far above or below the feet it can be and still be walked over, as the spike's"),
	-- F: the gun the view passes closest to, within reach of the eye.
	reach = p(3, "estimate", "How far from the eye F reaches a gun; not published"),
	aimRadius = p(0.4, "estimate", "How close to a gun's middle the view must pass for F to take it; not published"),
	-- Let go of with G, thrown a little ahead, as the spike is.
	dropForward = p(1.2, "estimate", "How far ahead of the feet a dropped gun lands on flat ground, as the spike"),
	maxGuns = p(40, "estimate", "Guns on the ground at once, the oldest taken away first (ours: the course has no rounds to clear it)"),
}

-- A gun's middle, above where it rests: what the view looks at.
GroundGuns.CENTRE = vector.create(0, 0.05, 0)

-- The model the server keeps the guns in, one part each named by its id,
-- with these attributes; and the remote that asks to pick one up.
GroundGuns.MODEL = "VFGroundGuns"
GroundGuns.WEAPON = "Weapon"
GroundGuns.AMMO = "Ammo"
GroundGuns.RESERVE = "Reserve"

function GroundGuns.new(): State
	return { guns = {}, nextId = 1, version = 0 }
end

-- The slot a gun goes in, for one that can be on the ground: a primary (1)
-- or a sidearm (2), never the knife or the spike.
function GroundGuns.slotOf(weapon: string): number?
	local def = WeaponConfig.Defs[weapon]
	if not def or def.melee or def.spike or (def.slot ~= 1 and def.slot ~= 2) then
		return nil
	end
	return def.slot
end

-- What someone who dies drops, by slot: their primary, or their sidearm if
-- they have no primary; nothing with neither.
function GroundGuns.deathSlot(loadout: { string }): number?
	for _, slot in { 1, 2 } do
		local id = loadout[slot]
		if id and id ~= "" and GroundGuns.slotOf(id) == slot then
			return slot
		end
	end
	return nil
end

-- Puts a gun on the ground. With too many there, the oldest goes.
function GroundGuns.add(s: State, weapon: string, ammo: number, reserve: number, position: vector, yaw: number, at: number): Gun
	local gun = { id = s.nextId, weapon = weapon, ammo = ammo, reserve = reserve, position = position, yaw = yaw, at = at }
	s.nextId += 1
	s.guns[gun.id] = gun
	local count, oldest = 0, nil :: number?
	for id in s.guns do
		count += 1
		if oldest == nil or id < oldest then
			oldest = id
		end
	end
	if count > GroundGuns.Params.maxGuns.value and oldest then
		s.guns[oldest] = nil
	end
	s.version += 1
	return gun
end

-- Takes a gun off the ground, if it's still there.
function GroundGuns.remove(s: State, id: number): Gun?
	local gun = s.guns[id]
	if gun then
		s.guns[id] = nil
		s.version += 1
	end
	return gun
end

function GroundGuns.clear(s: State)
	if next(s.guns) ~= nil then
		table.clear(s.guns)
		s.version += 1
	end
end

-- Whether someone standing at `feet` is over a gun resting at `position`.
function GroundGuns.walksOver(feet: vector, position: vector): boolean
	local d = position - feet
	local P = GroundGuns.Params
	return math.abs(d.y) <= P.pickupHeight.value and d.x * d.x + d.z * d.z <= P.pickupRange.value ^ 2
end

-- The nearest gun someone standing at `feet` walks over that `wants` takes,
-- if any.
function GroundGuns.walkedOver(s: State, feet: vector, wants: (Gun) -> boolean): Gun?
	local best: Gun? = nil
	local bestDistance = math.huge
	for _, gun in s.guns do
		if GroundGuns.walksOver(feet, gun.position) and wants(gun) then
			local d = gun.position - feet
			local distance = d.x * d.x + d.z * d.z
			if distance < bestDistance or (distance == bestDistance and best ~= nil and gun.id < best.id) then
				best, bestDistance = gun, distance
			end
		end
	end
	return best
end

-- How far along the view, from `eye` along the unit vector `look`, a gun
-- resting at `position` is, if the view passes within `radius` of its middle
-- and it's no further than `reach`; nil if not.
function GroundGuns.alongView(eye: vector, look: vector, position: vector, reach: number, radius: number): number?
	local offset = position + GroundGuns.CENTRE - eye
	local along = vector.dot(offset, look)
	if along < 0 then
		return nil
	end
	local miss = vector.magnitude(offset - look * along)
	if miss > radius or vector.magnitude(offset) > reach then
		return nil
	end
	return along
end

-- The gun the view from `eye` along `look` is on: the nearest along it of
-- those it passes close enough to, within reach. `slack` widens both, for
-- the server's check of a client's choice.
function GroundGuns.aimedAt(s: State, eye: vector, look: vector, slack: number?): Gun?
	local P = GroundGuns.Params
	local extra = slack or 0
	local best: Gun? = nil
	local bestAlong = math.huge
	for _, gun in s.guns do
		local along = GroundGuns.alongView(eye, look, gun.position, P.reach.value + extra, P.aimRadius.value + extra)
		if along and (along < bestAlong or (along == bestAlong and best ~= nil and gun.id < best.id)) then
			best, bestAlong = gun, along
		end
	end
	return best
end

return GroundGuns
