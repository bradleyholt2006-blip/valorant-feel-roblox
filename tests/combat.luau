--!strict
-- Hitboxes, shot resolution, damage and health (system 2).

local Hitboxes = require("../src/shared/Combat/Hitboxes")
local ShotResolver = require("../src/shared/Combat/ShotResolver")
local Health = require("../src/shared/Combat/Health")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local H = require("./Harness")

local check, near = H.check, H.near

local FORWARD = vector.create(0, 0, -1)

local function pose(x: number, z: number, yaw: number?, crouch: number?): Hitboxes.Pose
	return { position = vector.create(x, 0, z), yaw = yaw or 0, crouchAlpha = crouch or 0 }
end

-- A ray fired down -Z from (x, y, 0) at a target standing at z = -10.
local function shoot(x: number, y: number, target: Hitboxes.Pose): Hitboxes.Hit?
	return Hitboxes.raycast(vector.create(x, y, 0), FORWARD, Hitboxes.build(target), 100)
end

H.section("Combat tests")

do
	local t = pose(0, -10)
	local head = shoot(0, 1.62, t)
	check("eye-height ray hits the head", head ~= nil and head.region == "head")
	-- vector components are 32-bit floats, hence the tolerance.
	check("hit distance is to the front face", head ~= nil and near(head.distance, 10 - 0.12, 1e-5), if head then tostring(head.distance) else "miss")
	local body = shoot(0, 1.17, t)
	check("chest-height ray hits the body", body ~= nil and body.region == "body")
	local legs = shoot(0, 0.5, t)
	check("knee-height ray hits the legs", legs ~= nil and legs.region == "legs")
	check("ray over the head misses", shoot(0, 1.80, t) == nil)
	check("ray just inside the body's side hits", (shoot(0.21, 1.17, t) or {} :: any).region == "body")
	check("ray just outside the body's side misses", shoot(0.23, 1.17, t) == nil)
	local corner = shoot(0.11, 1.74, t)
	check("grazing the head's corner still hits it", corner ~= nil and corner.region == "head")
end

do
	-- Turned 90 degrees: the body is 0.28 m deep, so it is narrower side-on.
	local t = pose(0, -10, math.pi / 2)
	check("side-on target is narrower", shoot(0.2, 1.17, t) == nil and (shoot(0.13, 1.17, t) or {} :: any).region == "body")
end

do
	local t = pose(0, -10, 0, 1)
	check("crouched target ducks under a standing head-height ray", shoot(0, 1.62, t) == nil)
	check("crouched head sits at 1.10 m", (shoot(0, 1.10, t) or {} :: any).region == "head")
	local half = pose(0, -10, 0, 0.5)
	local boxes = Hitboxes.build(half)
	check("half-crouched head is between the two heights", near(boxes[1].center.y, (1.62 + 1.10) / 2, 1e-5))
end

do
	local origin = vector.create(0, 1.17, 0)
	local near1 = { id = 1, pose = pose(0, -10) }
	local far2 = { id = 2, pose = pose(0, -20) }
	local hit = ShotResolver.resolve(origin, FORWARD, { far2, near1 }, 250, nil)
	check("the nearest target in line takes the shot", hit ~= nil and hit.targetId == 1)
	check("a wall in front stops the shot", ShotResolver.resolve(origin, FORWARD, { near1, far2 }, 5, nil) == nil)
	local ignored = ShotResolver.resolve(origin, FORWARD, { near1, far2 }, 250, 1)
	check("the shooter's own id is ignored", ignored ~= nil and ignored.targetId == 2)
	check("a wall between two targets protects the far one", (ShotResolver.resolve(origin, FORWARD, { near1, far2 }, 15, 1)) == nil)
	local miss = ShotResolver.resolve(origin, vector.create(0, 0, 1), { near1, far2 }, 250, nil)
	check("targets behind the shooter are never hit", miss == nil)
end

do
	local vandal = WeaponConfig.get("vandal")
	local phantom = WeaponConfig.get("phantom")
	local classic = WeaponConfig.get("classic")
	check("Vandal does 160/40/34 at any range", WeaponConfig.damageAt(vandal, "head", 5) == 160 and WeaponConfig.damageAt(vandal, "body", 49) == 40 and WeaponConfig.damageAt(vandal, "legs", 200) == 34)
	check("Phantom body 39 up to 20 m, 35 beyond", WeaponConfig.damageAt(phantom, "body", 20) == 39 and WeaponConfig.damageAt(phantom, "body", 20.01) == 35 and WeaponConfig.damageAt(phantom, "body", 80) == 35)
	check("Classic head 78 close, 66 past 30 m", WeaponConfig.damageAt(classic, "head", 10) == 78 and WeaponConfig.damageAt(classic, "head", 31) == 66)
	check("Vandal kills 150 HP in 1 head / 4 body / 5 leg shots",
		WeaponConfig.shotsToKill(vandal, "head", 10, 150) == 1 and WeaponConfig.shotsToKill(vandal, "body", 10, 150) == 4 and WeaponConfig.shotsToKill(vandal, "legs", 10, 150) == 5)
	check("Phantom can't one-tap 150 HP past its falloff", WeaponConfig.shotsToKill(phantom, "head", 10, 150) == 1 and WeaponConfig.shotsToKill(phantom, "head", 25, 150) == 2)
	check("Operator body shot kills 150 HP", WeaponConfig.shotsToKill(WeaponConfig.get("operator"), "body", 30, 150) == 1)
end

do
	local hp = Health.new(100, 50)
	local r1 = Health.apply(hp, 40)
	check("shields absorb damage first", r1.shieldDamage == 40 and hp.health == 100 and hp.shield == 10)
	local r2 = Health.apply(hp, 40)
	check("damage spills from shield into health", r2.shieldDamage == 10 and r2.healthDamage == 30 and hp.health == 70)
	Health.apply(hp, 40)
	local r4 = Health.apply(hp, 40)
	check("fourth Vandal body shot kills 150 HP", r4.killed and not hp.alive and r4.damage == 30)
	local r5 = Health.apply(hp, 40)
	check("no damage after death", r5.damage == 0 and not r5.killed)
	Health.reset(hp)
	check("reset restores health and shields", hp.alive and hp.health == 100 and hp.shield == 50)
	local one = Health.apply(hp, 160)
	check("Vandal headshot kills through heavy shields", one.killed and one.damage == 150)
end

return nil
