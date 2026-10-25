--!strict
-- Resolves shots on the server and applies damage.
--
-- A round comes out of the shooter's PlayerSim on the tick it was fired, with
-- that tick's viewTime: the snapshot time the shooter's screen was showing.
-- The server rewinds every other living entity to that time (lag
-- compensation, capped at 140 ms like the reference since Patch 6.02),
-- traces each of the round's bullets (a shotgun's pellets) through the level
-- (Penetration, over Roblox raycasts) and against those entities' analytic
-- hitboxes (ShotResolver), works out each bullet's damage by region, range
-- and the walls it went through, applies each target's total at once
-- (Volley), slows the victim ("tagging") and tells everyone what happened.
-- In the push model Riot describes, clients get hit events, not polled
-- health.
--
-- The verdict sent back to the shooter, one per round, also says what the
-- server tested:
-- how far it rewound, the rewound pose of every target near the ray and the
-- snapshots it came from, the shot's origin, where the level stopped it and
-- the walls on the way. That is what the debug tools use to draw the
-- server's boxes and walls next to the client's and to say why the two
-- disagree when they do.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Health = require(Shared.Combat.Health)
local ShotResolver = require(Shared.Combat.ShotResolver)
local Volley = require(Shared.Combat.Volley)
local LagCompensation = require(Shared.Combat.LagCompensation)
local Penetration = require(Shared.Combat.Penetration)
local RobloxLevel = require(Shared.Combat.RobloxLevel)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local Tuning = require(script.Parent.Tuning)
local PlayerSimServer = require(script.Parent.PlayerSimServer)

local DT = 1 / MovementConfig.TickRate.value

local CombatServer = {}

local level = RobloxLevel.new()
local history = LagCompensation.new()

-- Replication listener: every snapshot sent becomes rewind history.
function CombatServer.record(time: number, poses: { PlayerCodec.Pose })
	LagCompensation.record(history, time, poses)
end

local function damage(attacker: Entities.Entity, victim: Entities.Entity, amount: number, region: string)
	local result = Health.apply(victim.health, amount)
	local hp = WeaponConfig.Health
	if result.damage > 0 and victim.sim and not result.killed then
		PlayerSim.applyTag(victim.sim, Tuning.config(), hp.tagSpeedMultiplier.value, hp.tagDuration.value, DT)
		if victim.player then
			PlayerSimServer.markDirty(victim.player)
		end
	end
	Remotes.get().Combat:FireAllClients({
		kind = "damage",
		attacker = attacker.id,
		target = victim.id,
		region = region,
		damage = result.damage,
		health = victim.health.health,
		shield = victim.health.shield,
		killed = result.killed,
	})
	if result.killed then
		victim.onKilled(attacker)
	end
	return result
end

-- The walls a shot met before `distance`, for the shooter's debug tools.
local function describeWalls(trace: Penetration.Trace, distance: number): { { [string]: any } }
	local out = {}
	for _, wall in trace.walls do
		if wall.entry > distance + 1e-4 then
			break
		end
		table.insert(out, {
			material = wall.material,
			name = wall.name,
			entry = wall.entry,
			exit = wall.exit,
			thickness = wall.thickness,
			used = wall.used,
			multiplier = wall.multiplier,
			continues = wall.continues,
		})
	end
	return out
end

-- Players on the same team (the arena's sides) can't shoot each other: the
-- reference has no friendly fire for guns, and here the bullet passes
-- through them.
local function teammates(a: Entities.Entity, b: Entities.Entity): boolean
	local pa, pb = a.player, b.player
	return pa ~= nil and pb ~= nil and not pa.Neutral and not pb.Neutral and (pa.Team :: Team?) ~= nil and pa.Team == pb.Team
end

-- Positions go as metres in a Vector3 (the wire keeps float32 exactly), so
-- the client can compare them with its own bit for bit.
local function describeTarget(t: LagCompensation.Target): { [string]: any }
	return {
		id = t.id,
		position = Units.asVector3(t.pose.position),
		yaw = t.pose.yaw,
		crouch = t.pose.crouchAlpha,
		from = t.from,
		to = t.to,
		held = t.held,
	}
end

-- One round: its bullets, all fired on the same tick from the same eye.
function CombatServer.onVolley(shooter: Entities.Entity, shots: { WeaponSim.Shot }, viewTime: number)
	local first = shots[1]
	if not first or not shooter.health.alive then
		return -- a dead player's queued shots are rejected, as in the reference
	end
	local def = WeaponConfig.get(first.weapon)
	local rewind = LagCompensation.rewindTime(viewTime, Workspace:GetServerTimeNow(), Tuning.maxRewind())
	local rewound = LagCompensation.targets(history, rewind.time, function(id: number): boolean
		local entity = Entities.get(id)
		return id ~= shooter.id and entity ~= nil and entity.health.alive and entity.pose() ~= nil and not teammates(shooter, entity)
	end)
	local targets = LagCompensation.shotTargets(rewound)

	-- Each bullet: where it ended, what it hit and the damage it did. The
	-- targets tested are those near any bullet's ray.
	local tested, testedIds = {}, {}
	local pellets = table.create(#shots)
	local ends = table.create(#shots)
	local hits: { Volley.Hit } = {}
	for _, shot in shots do
		local trace = Penetration.trace(level, shot.origin, shot.direction, def.penetration, WeaponConfig.MaxRange)
		local blockedAt = trace.stop
		local hit = ShotResolver.resolve(shot.origin, shot.direction, targets, blockedAt, shooter.id)
		for _, t in rewound do
			if not testedIds[t.id] and ShotResolver.nearRay(shot.origin, shot.direction, t.pose, blockedAt) then
				testedIds[t.id] = true
				table.insert(tested, describeTarget(t))
			end
		end
		local endPoint = if hit then hit.point else shot.origin + shot.direction * blockedAt
		local endDistance = if hit then hit.distance else blockedAt
		local multiplier = Penetration.multiplierAt(trace, endDistance)
		local pellet: { [string]: any } = {
			shotNumber = shot.shotNumber,
			endPoint = Units.toStuds(endPoint),
			direction = Units.asVector3(shot.direction),
			blockedAt = blockedAt,
			multiplier = multiplier,
			walls = describeWalls(trace, endDistance),
		}
		if hit then
			local victim = Entities.get(hit.targetId)
			if victim and victim.health.alive then
				-- What the bullet did, not the health it took: a 160 headshot
				-- on a 150 HP target still reads 160, so damage values can be
				-- checked.
				local amount = Penetration.damage(WeaponConfig.damageAt(def, hit.region, hit.distance), multiplier)
				pellet.target = hit.targetId
				pellet.region = hit.region
				pellet.distance = hit.distance
				pellet.hitPoint = Units.asVector3(hit.point)
				pellet.damage = amount
				table.insert(hits, { target = hit.targetId, region = hit.region :: string, damage = amount })
			end
		end
		table.insert(pellets, pellet)
		table.insert(ends, pellet.endPoint)
	end

	-- Each target takes the round's damage as one hit.
	local results = {}
	for _, total in Volley.totals(hits) do
		local victim = Entities.get(total.target)
		if victim and victim.health.alive then
			local result = damage(shooter, victim, total.damage, total.region)
			table.insert(results, { target = total.target, region = total.region, damage = total.damage, pellets = total.pellets, killed = result.killed })
		end
	end

	local remotes = Remotes.get()
	if shooter.player then
		remotes.ShotResult:FireClient(shooter.player, {
			volley = first.volley,
			tick = first.tick,
			weapon = first.weapon,
			viewTime = viewTime,
			rewindTime = rewind.time,
			rewind = rewind.amount,
			clamped = rewind.clamped,
			origin = Units.asVector3(first.origin),
			tested = tested,
			pellets = pellets,
			hits = results,
		})
	end
	-- Other clients trace the walls again themselves to draw the holes. A
	-- suppressed gun's tracers show only to the shooter's own side.
	for _, entity in Entities.all() do
		if entity.player and entity ~= shooter then
			remotes.ShotFx:FireClient(entity.player, {
				shooter = shooter.id,
				weapon = first.weapon,
				from = Units.toStuds(first.origin),
				to = ends,
				hit = #results > 0,
				tracers = not def.suppressed or teammates(shooter, entity),
			})
		end
	end
end

return CombatServer
