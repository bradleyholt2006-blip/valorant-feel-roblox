--!strict
-- Resolves shots on the server and applies damage.
--
-- A shot comes out of the shooter's PlayerSim on the tick it was fired. The
-- server traces it against level geometry (Roblox raycast) and against every
-- target's analytic hitboxes (ShotResolver), applies damage by region and
-- range, slows the victim ("tagging"), and tells everyone what happened. In
-- the push model Riot describes, clients get hit events, not polled health.
--
-- This version tests targets where they are on the server right now. Lag
-- compensation (rewinding targets to what the shooter saw) is system 4; the
-- viewTime the client sent with the shot is already passed through for it.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Health = require(Shared.Combat.Health)
local ShotResolver = require(Shared.Combat.ShotResolver)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local Tuning = require(script.Parent.Tuning)
local PlayerSimServer = require(script.Parent.PlayerSimServer)

local DT = 1 / MovementConfig.TickRate.value

local CombatServer = {}

local worldParams = RaycastParams.new()
worldParams.FilterType = Enum.RaycastFilterType.Exclude
worldParams.CollisionGroup = RobloxWorld.CHARACTER_GROUP
worldParams.RespectCanCollide = true

-- Hook for lag compensation (system 4): returns the targets as the shooter saw them.
local targetProvider: (shooter: Entities.Entity, viewTime: number) -> { ShotResolver.Target } = function(shooter)
	local targets: { ShotResolver.Target } = {}
	for _, pose in Entities.poses() do
		if pose.id ~= shooter.id then
			table.insert(targets, { id = pose.id, pose = { position = pose.position, yaw = pose.yaw, crouchAlpha = pose.crouchAlpha } })
		end
	end
	return targets
end

function CombatServer.setTargetProvider(provider: (Entities.Entity, number) -> { ShotResolver.Target })
	targetProvider = provider
end

-- Distance (metres) to the first piece of level geometry along the shot.
local function worldDistance(origin: vector, dir: vector): number
	local maxRange = WeaponConfig.MaxRange
	local result = Workspace:Raycast(Units.toStuds(origin), Units.toStuds(dir * maxRange), worldParams)
	if result then
		return result.Distance * Units.METRES_PER_STUD
	end
	return maxRange
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

function CombatServer.onShot(shooter: Entities.Entity, shot: WeaponSim.Shot, viewTime: number)
	if not shooter.health.alive then
		return -- a dead player's queued shots are rejected, as in the reference
	end
	local def = WeaponConfig.get(shot.weapon)
	local blockedAt = worldDistance(shot.origin, shot.direction)
	local hit = ShotResolver.resolve(shot.origin, shot.direction, targetProvider(shooter, viewTime), blockedAt, shooter.id)

	local endPoint = if hit then hit.point else shot.origin + shot.direction * blockedAt
	local verdict: { [string]: any } = {
		shotNumber = shot.shotNumber,
		tick = shot.tick,
		weapon = shot.weapon,
		endPoint = Units.toStuds(endPoint),
		viewTime = viewTime,
	}
	if hit then
		local victim = Entities.get(hit.targetId)
		if victim and victim.health.alive then
			local amount = WeaponConfig.damageAt(def, hit.region, hit.distance)
			local result = damage(shooter, victim, amount, hit.region)
			verdict.target = hit.targetId
			verdict.region = hit.region
			verdict.distance = hit.distance
			verdict.damage = result.damage
			verdict.killed = result.killed
		end
	end

	local remotes = Remotes.get()
	if shooter.player then
		remotes.ShotResult:FireClient(shooter.player, verdict)
	end
	local fx = { shooter = shooter.id, from = Units.toStuds(shot.origin), to = verdict.endPoint, hit = verdict.target ~= nil }
	for _, entity in Entities.all() do
		if entity.player and entity ~= shooter then
			remotes.ShotFx:FireClient(entity.player, fx)
		end
	end
end

return CombatServer
