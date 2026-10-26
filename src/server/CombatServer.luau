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
-- disagree when they do. Of the targets near the ray it lists only those
-- the shooter has in their snapshots, and any it hit (the fog of war,
-- system 35): a miss past someone they can't see says nothing of where
-- they are, and their client couldn't have tested them either. Others
-- hear the shot as far as it carries, or see it if they have the shooter.
--
-- A knife swing comes out of the simulation the same way, on the tick it
-- starts, and is checked against the same rewound targets (Melee): of those
-- in reach, the one nearest the aim that the level doesn't hide takes it,
-- for the swing's damage from in front or from behind. Its verdict goes back
-- to the one swinging with what the server tested, and the others hear it.
--
-- The spike's blast kills outright, with nobody to credit (kill), Team
-- Deathmatch's spawn rooms burn whoever they shouldn't have in them (hurt),
-- and Hot Hands' fire whoever stands in it, credited to its thrower (burn,
-- system 31).
--
-- Each damage event says whether the bullets went through a wall first, for
-- the kill feed (system 16), and every hit that took something is told to
-- damageListeners, for the match's record. Every kill is told to
-- killListeners, for the ability kit's points (system 17), with what made it
-- (a single Blade Storm knife brings them all back, system 19).
--
-- A hit that would kill someone can spare them instead (Phoenix's Run it
-- Back, system 33, CombatServer.spares): they've taken it and are out of
-- play, with no health, but nobody's killed them. Out of play, nothing
-- hurts or heals them, shots go through, and the snapshots leave them out,
-- until they're back in it (CombatServer.back).
--
-- Sage's walls of ice stand in the level that shots and swings are traced
-- through, as the attacker's screen showed them (CombatServer.levelAt,
-- system 38), and stop every bullet. A bullet or a knife that strikes one
-- takes its damage off it (CombatServer.struck): a bullet's to the body at
-- its range, less what the walls before took, and a knife's from in front.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FogOfWar = require(Shared.Combat.FogOfWar)
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Health = require(Shared.Combat.Health)
local ShotResolver = require(Shared.Combat.ShotResolver)
local Volley = require(Shared.Combat.Volley)
local LagCompensation = require(Shared.Combat.LagCompensation)
local Penetration = require(Shared.Combat.Penetration)
local Melee = require(Shared.Combat.Melee)
local RobloxLevel = require(Shared.Combat.RobloxLevel)
local BarrierSim = require(Shared.Abilities.BarrierSim)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local Tuning = require(script.Parent.Tuning)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local FogServer = require(script.Parent.FogServer)

local DT = 1 / MovementConfig.TickRate.value

local CombatServer = {}

-- Called with every hit that took health or shield: who did it (nil for the
-- spike's blast and a spawn room's burn), to whom, and how much, before a
-- kill's death listeners.
CombatServer.damageListeners = {} :: { (Entities.Entity?, Entities.Entity, number) -> () }
-- Called with every kill, players' and dummies' alike: who did it (nil for
-- the spike's blast and a spawn room's burn), who died, the weapon and the
-- mode it fired in (a WeaponSim.Shot's; nil for a swing, the blast or a
-- burn), before the death listeners.
CombatServer.killListeners = {} :: { (Entities.Entity?, Entities.Entity, string, string?) -> () }
-- Whether an entity can't be hurt now (gun game's spawn protection, system
-- 23): shots and swings go through it, as through a teammate.
CombatServer.protected = nil :: ((Entities.Entity) -> boolean)?
-- Whether a hit that would kill an entity spares it (Phoenix's Run it Back,
-- system 33), called with it, who hit it, and the weapon and mode as for
-- killListeners: it's taken the hit and is out of play, but there's no kill
-- and no death.
CombatServer.spares = nil :: ((Entities.Entity, Entities.Entity?, string, string?) -> boolean)?
-- The level shots and swings are traced through, as the attacker's screen
-- showed it at `viewTime`: with Sage's walls standing then in it
-- (BarrierServer, system 38). The level alone without.
CombatServer.levelAt = nil :: ((Penetration.Level, number) -> Penetration.Level)?
-- Called with what struck a surface that stopped it, the surface's key and
-- the damage it would have done there: a wall of Sage's takes it
-- (BarrierServer); the level's own surfaces don't.
CombatServer.struck = nil :: ((Entities.Entity, any, number) -> ())?

local level = RobloxLevel.new()
local history = LagCompensation.new()

-- Replication listener: every snapshot sent becomes rewind history.
function CombatServer.record(time: number, poses: { PlayerCodec.Pose })
	LagCompensation.record(history, time, poses)
end

-- `attacker` is nil for damage nobody caused (the spike's blast, a spawn
-- room's burn);
-- `wallbang`, that the bullets went through a wall on the way; `mode`, the
-- way the weapon fired, for a shot; `untagged`, that it doesn't slow (a
-- fire's burn).
local function damage(
	attacker: Entities.Entity?,
	victim: Entities.Entity,
	amount: number,
	region: string,
	weapon: string,
	wallbang: boolean?,
	mode: string?,
	untagged: boolean?
)
	local result = Health.apply(victim.health, amount, Workspace:GetServerTimeNow())
	local spares = CombatServer.spares
	local spared = result.killed and spares ~= nil and spares(victim, attacker, weapon, mode)
	if spared then
		result.killed = false
	end
	if result.damage > 0 then
		for _, listener in CombatServer.damageListeners do
			listener(attacker, victim, result.damage)
		end
	end
	-- A hit from nobody (a spawn room's burn) doesn't slow, nor does fire,
	-- nor one that spared its victim.
	local hp = WeaponConfig.Health
	if result.damage > 0 and attacker and victim.sim and not result.killed and not untagged and not spared then
		PlayerSim.applyTag(victim.sim, Tuning.config(), hp.tagSpeedMultiplier.value, hp.tagDuration.value, DT)
		if victim.player then
			PlayerSimServer.markDirty(victim.player)
		end
	end
	local event = Entities.vitals(victim)
	event.kind = "damage"
	event.attacker = if attacker then attacker.id else nil
	event.region = region
	event.weapon = weapon
	event.damage = result.damage
	event.killed = result.killed
	event.wallbang = wallbang == true
	Remotes.get().Combat:FireAllClients(event)
	if result.killed then
		for _, listener in CombatServer.killListeners do
			listener(attacker, victim, weapon, mode)
		end
		victim.onKilled(attacker)
	end
	return result
end

-- More than anyone has: health and the heaviest shield together.
local LETHAL = 1e4

-- Kills an entity outright, shield and all, with nobody to credit, as
-- `weapon` (the spike's blast). Clients hear of it as a kill with no
-- attacker.
function CombatServer.kill(victim: Entities.Entity, weapon: string)
	if victim.health.alive then
		damage(nil, victim, LETHAL, "body", weapon)
	end
end

-- Hurts an entity by `amount`, through its shield as any hit, with nobody
-- to credit, as `weapon` (Team Deathmatch's spawn rooms, system 27). Clients
-- hear of it as damage with no attacker, and a kill if it was the last.
function CombatServer.hurt(victim: Entities.Entity, amount: number, weapon: string)
	if victim.health.alive then
		damage(nil, victim, amount, "body", weapon)
	end
end

-- Burns an entity by `amount`, through its shield as any hit, as `weapon`
-- (Hot Hands' fire, system 31), credited to `attacker` for the kill feed
-- and the kit's points. Fire doesn't slow: the reference's tagging is its
-- bullets' ("Bullet tagging", Patch 3.0).
function CombatServer.burn(attacker: Entities.Entity?, victim: Entities.Entity, amount: number, weapon: string)
	if victim.health.alive then
		damage(attacker, victim, amount, "body", weapon, nil, nil, true)
	end
end

-- Regen Shields refilling: told to clients as they go, a few times a second.
local REGEN_EVENT_INTERVAL = 0.1
local regenSent: { [number]: number? } = {}

-- Once a server frame, `dt` seconds after the last.
function CombatServer.step(now: number, dt: number)
	for id, entity in Entities.all() do
		local h = entity.health
		if Health.step(h, now, dt) then
			local done = h.shield >= h.maxShield or h.pool <= 0
			if done or now - (regenSent[id] or -math.huge) >= REGEN_EVENT_INTERVAL then
				regenSent[id] = if done then nil else now
				local event = Entities.vitals(entity)
				event.kind = "shield"
				Remotes.get().Combat:FireAllClients(event)
			end
		end
	end
end

-- Puts a fresh shield of this kind on an entity ("" for none), or one as
-- `kept` describes, and tells clients (the buy menu).
function CombatServer.setShield(entity: Entities.Entity, kind: string, kept: Health.Kept?)
	Health.setShield(entity.health, kind)
	if kept then
		Health.restore(entity.health, kept)
	end
	local event = Entities.vitals(entity)
	event.kind = "shield"
	Remotes.get().Combat:FireAllClients(event)
end

-- Full health and a fresh shield of the kind worn for a living entity
-- (deathmatch's health packs, system 26), and tells clients.
function CombatServer.heal(entity: Entities.Entity)
	if not entity.health.alive then
		return
	end
	Health.heal(entity.health)
	local event = Entities.vitals(entity)
	event.kind = "shield"
	Remotes.get().Combat:FireAllClients(event)
end

-- Some health and shield back for a living entity, each up to its most
-- (Team Deathmatch's Recovery Orbs, system 28, and the Healing Orb's heals,
-- system 36), and tells clients if it changed.
function CombatServer.mend(entity: Entities.Entity, health: number, shield: number)
	if not Health.mend(entity.health, health, shield) then
		return
	end
	local event = Entities.vitals(entity)
	event.kind = "shield"
	Remotes.get().Combat:FireAllClients(event)
end

-- Takes a living entity out of play as it is, with no hit (Phoenix's Run it
-- Back running out, system 33): nothing hurts or heals it, and shots go
-- through it, until it's back.
function CombatServer.withdraw(entity: Entities.Entity)
	entity.health.alive = false
end

-- An entity out of play back in it (Run it Back's return): full health, and
-- the shield of the kind worn as `kept` describes, or a fresh one without;
-- and tells clients.
function CombatServer.back(entity: Entities.Entity, kept: Health.Kept?)
	Health.reset(entity.health)
	if kept then
		Health.restore(entity.health, kept)
	end
	local event = Entities.vitals(entity)
	event.kind = "shield"
	Remotes.get().Combat:FireAllClients(event)
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
-- through them. Fire burns them less (FireServer).
local function teammates(a: Entities.Entity, b: Entities.Entity): boolean
	local pa, pb = a.player, b.player
	return pa ~= nil and pb ~= nil and not pa.Neutral and not pb.Neutral and (pa.Team :: Team?) ~= nil and pa.Team == pb.Team
end
CombatServer.teammates = teammates

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

-- Whether a target near a shot or a swing goes in its verdict: one the
-- attacker has in their snapshots (the fog of war), or the one it hit.
local function listed(attacker: Entities.Entity, id: number, hitId: number?): boolean
	return id == hitId or attacker.player == nil or FogServer.shows(attacker.player, id)
end

-- Every living entity `attacker` can hurt, posed as the attacker's screen
-- showed them at `viewTime` (as far back as the cap allows).
local function rewindFor(attacker: Entities.Entity, viewTime: number): (LagCompensation.Rewind, { LagCompensation.Target })
	local rewind = LagCompensation.rewindTime(viewTime, Workspace:GetServerTimeNow(), Tuning.maxRewind())
	local rewound = LagCompensation.targets(history, rewind.time, function(id: number): boolean
		local entity = Entities.get(id)
		local protected = CombatServer.protected
		return id ~= attacker.id
			and entity ~= nil
			and entity.health.alive
			and entity.pose() ~= nil
			and not teammates(attacker, entity)
			and not (protected and protected(entity))
	end)
	return rewind, rewound
end

-- Every living entity `include` accepts, other than `viewer`, posed as the
-- viewer's screen showed them at `viewTime` (as far back as the cap
-- allows), and the time they're posed at: Sage's Healing Orb looks there
-- for the ally its holder had the crosshair over (system 36).
function CombatServer.rewound(
	viewer: Entities.Entity,
	viewTime: number,
	include: (Entities.Entity) -> boolean
): ({ LagCompensation.Target }, number)
	local rewind = LagCompensation.rewindTime(viewTime, Workspace:GetServerTimeNow(), Tuning.maxRewind())
	local rewound = LagCompensation.targets(history, rewind.time, function(id: number): boolean
		local entity = Entities.get(id)
		return id ~= viewer.id and entity ~= nil and entity.health.alive and entity.pose() ~= nil and include(entity)
	end)
	return rewound, rewind.time
end

-- The level as an attacker's screen showed it at `viewTime`.
local function levelFor(viewTime: number): Penetration.Level
	local at = CombatServer.levelAt
	return if at then at(level, viewTime) else level
end

-- One round: its bullets, all fired on the same tick from the same eye.
function CombatServer.onVolley(shooter: Entities.Entity, shots: { WeaponSim.Shot }, viewTime: number)
	local first = shots[1]
	if not first or not shooter.health.alive then
		return -- a dead player's queued shots are rejected, as in the reference
	end
	local def = WeaponConfig.get(first.weapon)
	local rewind, rewound = rewindFor(shooter, viewTime)
	local shotLevel = levelFor(viewTime)
	local targets = LagCompensation.shotTargets(rewound)

	-- Each bullet: where it ended, what it hit and the damage it did. The
	-- targets tested are those near any bullet's ray.
	local tested, testedIds = {}, {}
	local pellets = table.create(#shots)
	local ends = table.create(#shots)
	local hits: { Volley.Hit } = {}
	local throughWall: { [number]: boolean } = {} -- targets a bullet reached through a wall
	for _, shot in shots do
		local trace = Penetration.trace(shotLevel, shot.origin, shot.direction, def.penetration, WeaponConfig.MaxRange)
		local blockedAt = trace.stop
		local hit = ShotResolver.resolve(shot.origin, shot.direction, targets, blockedAt, shooter.id)
		for _, t in rewound do
			if
				not testedIds[t.id]
				and ShotResolver.nearRay(shot.origin, shot.direction, t.pose, blockedAt)
				and listed(shooter, t.id, if hit then hit.targetId else nil)
			then
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
				if #pellet.walls > 0 then
					throughWall[hit.targetId] = true
				end
			end
		else
			-- What stopped it takes what it would have done there.
			local last = trace.walls[#trace.walls]
			local struck = CombatServer.struck
			if struck and trace.stopped and last and last.exit == nil then
				struck(shooter, last.key, Penetration.damage(WeaponConfig.damageAt(def, "body", blockedAt), multiplier))
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
			local result = damage(shooter, victim, total.damage, total.region, first.weapon, throughWall[total.target], first.mode)
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
	-- Other clients trace the walls again themselves to draw the holes:
	-- those who'd hear it or have the shooter (the fog of war). A suppressed
	-- gun's tracers show only to the shooter's own side.
	local reach = FogOfWar.weaponEdge(first.weapon)
	for _, entity in Entities.all() do
		if entity.player and entity ~= shooter and FogServer.hears(entity.player, first.origin, reach, shooter.id) then
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

-- One knife swing, from the eye along the aim on the tick it started.
function CombatServer.onSwing(attacker: Entities.Entity, swing: WeaponSim.Swing, viewTime: number)
	local melee = WeaponConfig.get(swing.weapon).melee
	if not melee or not attacker.health.alive then
		return -- a dead player's queued swings are rejected, like their shots
	end
	local attack = if swing.kind == "stab" then melee.stab else melee.slash
	local rewind, rewound = rewindFor(attacker, viewTime)
	local result =
		Melee.resolve(levelFor(viewTime), swing.origin, swing.direction, attack, LagCompensation.shotTargets(rewound), attacker.id)
	local tested = {}
	local hitId = if result.hit then result.hit.targetId else nil
	for _, t in rewound do
		if Melee.nearby(swing.origin, attack, t.pose) and listed(attacker, t.id, hitId) then
			table.insert(tested, describeTarget(t))
		end
	end

	local verdict: { [string]: any } = {
		tick = swing.tick,
		weapon = swing.weapon,
		kind = swing.kind,
		combo = swing.combo,
		viewTime = viewTime,
		rewindTime = rewind.time,
		rewind = rewind.amount,
		clamped = rewind.clamped,
		origin = Units.asVector3(swing.origin),
		direction = Units.asVector3(swing.direction),
		tested = tested,
		hidden = result.hidden,
	}
	local hit, wall = result.hit, result.wall
	local wallPoint = if wall then swing.origin + swing.direction * wall.distance else nil
	local victim = if hit then Entities.get(hit.targetId) else nil
	if hit and victim and victim.health.alive then
		-- What the swing did, not the health it took, as for a bullet.
		local outcome = damage(attacker, victim, result.damage, hit.region, swing.weapon)
		verdict.target = hit.targetId
		verdict.region = hit.region
		verdict.point = Units.asVector3(hit.point)
		verdict.offset = hit.offset
		verdict.distance = hit.distance
		verdict.back = result.back
		verdict.damage = result.damage
		verdict.killed = outcome.killed
	elseif wall and wallPoint then
		verdict.wall = Units.asVector3(wallPoint)
		verdict.normal = Units.asVector3(wall.normal)
		verdict.material = wall.material
		local struck = CombatServer.struck
		if struck then
			struck(attacker, wall.key, attack.front.value)
		end
	end

	local remotes = Remotes.get()
	if attacker.player then
		remotes.SwingResult:FireClient(attacker.player, verdict)
	end
	-- The others hear it, and see the blade's mark where it struck the level:
	-- those near enough, or who have the one swinging (the fog of war).
	local fx = {
		attacker = attacker.id,
		weapon = swing.weapon,
		kind = swing.kind,
		combo = swing.combo,
		from = Units.toStuds(swing.origin),
		direction = Units.asVector3(swing.direction),
		hit = verdict.target ~= nil,
		wall = if verdict.wall and wallPoint then Units.toStuds(wallPoint) else nil,
		normal = verdict.normal,
		-- A wall of Sage's, which takes no cut.
		ice = if verdict.wall and wall and BarrierSim.piece(wall.key) then true else nil,
	}
	local reach = FogOfWar.weaponEdge(swing.weapon)
	for _, entity in Entities.all() do
		if entity.player and entity ~= attacker and FogServer.hears(entity.player, swing.origin, reach, attacker.id) then
			remotes.SwingFx:FireClient(entity.player, fx)
		end
	end
end

return CombatServer
