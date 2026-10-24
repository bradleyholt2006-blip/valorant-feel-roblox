--!strict
-- Resolves shots on the server and applies damage.
--
-- A shot comes out of the shooter's PlayerSim on the tick it was fired, with
-- that tick's viewTime: the snapshot time the shooter's screen was showing.
-- The server rewinds every other living entity to that time (lag
-- compensation, capped at 140 ms like the reference since Patch 6.02),
-- traces the shot through the level (Penetration, over Roblox raycasts) and
-- against those entities' analytic hitboxes (ShotResolver), applies damage by
-- region, range and the walls it went through, slows the victim ("tagging")
-- and tells everyone what happened. In the push model Riot describes,
-- clients get hit events, not polled health.
--
-- The verdict sent back to the shooter also says what the server tested:
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

function CombatServer.onShot(shooter: Entities.Entity, shot: WeaponSim.Shot, viewTime: number)
	if not shooter.health.alive then
		return -- a dead player's queued shots are rejected, as in the reference
	end
	local def = WeaponConfig.get(shot.weapon)
	local rewind = LagCompensation.rewindTime(viewTime, Workspace:GetServerTimeNow(), Tuning.maxRewind())
	local rewound = LagCompensation.targets(history, rewind.time, function(id: number): boolean
		local entity = Entities.get(id)
		return id ~= shooter.id and entity ~= nil and entity.health.alive and entity.pose() ~= nil
	end)
	local trace = Penetration.trace(level, shot.origin, shot.direction, def.penetration, WeaponConfig.MaxRange)
	local blockedAt = trace.stop
	local hit = ShotResolver.resolve(shot.origin, shot.direction, LagCompensation.shotTargets(rewound), blockedAt, shooter.id)

	local tested = {}
	for _, t in rewound do
		if ShotResolver.nearRay(shot.origin, shot.direction, t.pose, blockedAt) then
			table.insert(tested, describeTarget(t))
		end
	end
	local endPoint = if hit then hit.point else shot.origin + shot.direction * blockedAt
	local endDistance = if hit then hit.distance else blockedAt
	local multiplier = Penetration.multiplierAt(trace, endDistance)
	local verdict: { [string]: any } = {
		shotNumber = shot.shotNumber,
		tick = shot.tick,
		weapon = shot.weapon,
		endPoint = Units.toStuds(endPoint),
		viewTime = viewTime,
		rewindTime = rewind.time,
		rewind = rewind.amount,
		clamped = rewind.clamped,
		origin = Units.asVector3(shot.origin),
		direction = Units.asVector3(shot.direction),
		blockedAt = blockedAt,
		multiplier = multiplier,
		walls = describeWalls(trace, endDistance),
		tested = tested,
	}
	if hit then
		local victim = Entities.get(hit.targetId)
		if victim and victim.health.alive then
			local amount = Penetration.damage(WeaponConfig.damageAt(def, hit.region, hit.distance), multiplier)
			local result = damage(shooter, victim, amount, hit.region)
			verdict.target = hit.targetId
			verdict.region = hit.region
			verdict.distance = hit.distance
			verdict.hitPoint = Units.asVector3(hit.point)
			-- What the shot did, not the health it took: a 160 headshot on a
			-- 150 HP target still reads 160, so damage values can be checked.
			verdict.damage = amount
			verdict.killed = result.killed
		end
	end

	local remotes = Remotes.get()
	if shooter.player then
		remotes.ShotResult:FireClient(shooter.player, verdict)
	end
	-- Other clients trace the walls again themselves to draw the holes.
	local fx = {
		shooter = shooter.id,
		weapon = shot.weapon,
		from = Units.toStuds(shot.origin),
		to = verdict.endPoint,
		hit = verdict.target ~= nil,
	}
	for _, entity in Entities.all() do
		if entity.player and entity ~= shooter then
			remotes.ShotFx:FireClient(entity.player, fx)
		end
	end
end

return CombatServer
