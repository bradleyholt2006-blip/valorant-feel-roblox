--!strict
-- Sage's Resurrection on the server (system 39).
--
-- Whoever's killed leaves a body: it lies on the floor under where they
-- fell, along the way they faced (ReviveSim), as an invisible part in
-- Workspace's VFBodies (ReviveSim.FOLDER) named by their entity id, which
-- every client draws (ReviveView). It's there until they're back, by a new
-- life or a return, or gone, and every body goes with a new round
-- (ReviveServer.clear, from the arena). With no floor under them there's
-- no body.
--
-- Each try of the orb in a player's simulation (a "revive" cast) is judged
-- here, from what their screen showed as they tried (the input's viewTime,
-- SlowSim.judged): fire's on the fallen the crosshair was over, of those
-- they can bring back, in sight of the eye past the level, clouds and
-- walls of fire and of ice (ReviveSim.aimedAt). In Skirmish and the spike
-- rounds those are the fallen of their own side, while the round's played
-- (canRevive, from the arena); elsewhere, with no sides, the practice
-- dummies, so it can be tried alone: one that's fallen stays down while
-- someone has the orb in hand. A try that brings someone back spends
-- the ultimate's points and puts the orb away between ticks, the gun back
-- in hand a moment after (AbilityConfig.Resurrection), and the ack takes
-- it to its owner; one that brings nobody back leaves it in hand.
--
-- A player's return starts at once: their new life is asked for where
-- they lie, out of play, rising with the body (PlayerSimServer.revive),
-- and a dummy's kept down. As they burst out, 2 s after the cast, they're
-- back in play with full health and their shield broken, the rules count
-- them alive again (reviveListeners, from the arena), any wall of ice
-- they're in breaks (Patch 3.0), and their body's gone; then they fall,
-- held, for 1.3 s (AbilitySim). A return carries on if the one who cast
-- it falls meanwhile (ours: no source says), and a new round ends it.
--
-- As it's cast, those who'd hear it are told (the Ability remote's
-- "reviving", from the body, the fog of war's way, system 35), and as
-- they burst out, those who'd hear that ("revived"), with every client's
-- kill feed (the Combat remote's "revived": Patch 3.0, 'The killfeed will
-- display certain ultimate abilities when players on either team are
-- killed in a second-life state or revived'). The caster's `VFLastRevive`
-- attribute is the name of the one they brought back, which scripted
-- checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local ReviveSim = require(Shared.Abilities.ReviveSim)
local SlowSim = require(Shared.Abilities.SlowSim)
local FogOfWar = require(Shared.Combat.FogOfWar)
local Sight = require(Shared.Combat.Sight)
local RobloxSpike = require(Shared.Spike.RobloxSpike)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local Tuning = require(script.Parent.Tuning)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local Dummies = require(script.Parent.Dummies)
local CombatServer = require(script.Parent.CombatServer)
local FogServer = require(script.Parent.FogServer)
local CloudServer = require(script.Parent.CloudServer)
local BlazeServer = require(script.Parent.BlazeServer)
local BarrierServer = require(script.Parent.BarrierServer)

local ReviveServer = {}

-- Whether the entity `by` can bring back the fallen `owner` now, when
-- something other than the course's rule decides (the arena): nil leaves
-- it to that rule, the practice dummies' and nobody else's.
ReviveServer.canRevive = nil :: ((by: Entities.Entity, owner: Entities.Entity) -> boolean?)?
-- Called as someone bursts out, back in play, with who cast their return.
ReviveServer.reviveListeners = {} :: { (Entities.Entity, Entities.Entity?) -> () }

local RES = AbilityConfig.Resurrection
local UP = vector.create(0, 1, 0)
-- How far below where they fell the floor is looked for (metres), as for a
-- gun dropped (GroundGunsServer).
local FLOOR_DEPTH = 50

-- Someone fallen: their body and its part, and a return under way: who
-- cast it (entity id), when (server time), and for a player whether their
-- new life has started.
type Fallen = { body: ReviveSim.Body, part: BasePart, by: number?, at: number?, started: boolean }

local fallen: { [number]: Fallen } = {}
local folder: Folder? = nil

-- The body of `entity`, just killed, where it fell: nil with no floor under
-- it, or nothing known of it.
local function lay(entity: Entities.Entity)
	local sim = entity.sim
	local where = folder
	if not sim or not where then
		return
	end
	local floor = RobloxSpike.ground(sim.movement.position, FLOOR_DEPTH)
	if not floor then
		return
	end
	local yaw = Dummies.yawOf(entity.id)
	local player = entity.player
	if player then
		local _, look = PlayerSimServer.view(player)
		yaw = if look then math.atan2(-look.x, -look.z) else 0
	end
	local old = fallen[entity.id]
	if old then
		old.part:Destroy()
	end
	local body: ReviveSim.Body = { id = entity.id, feet = floor, yaw = yaw or 0 }
	local part = Instance.new("Part")
	part.Name = tostring(entity.id)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.one * 0.2
	part.CFrame = CFrame.new(Units.toStuds(floor)) * CFrame.Angles(0, body.yaw, 0)
	part.Parent = where
	fallen[entity.id] = { body = body, part = part, by = nil, at = nil, started = false }
end

-- A body gone.
local function remove(id: number)
	local f = fallen[id]
	if f then
		fallen[id] = nil
		f.part:Destroy()
	end
end

-- Whether `by` can bring back `owner`: the arena's say, or on the course
-- only a practice dummy.
local function revivable(by: Entities.Entity, owner: Entities.Entity): boolean
	local rule = ReviveServer.canRevive
	local verdict = if rule then rule(by, owner) else nil
	if verdict ~= nil then
		return verdict
	end
	return owner.kind == "dummy"
end

-- Whether someone in play who could bring back `owner` has the orb in hand.
local function awaited(owner: Entities.Entity): boolean
	for _, player in Players:GetPlayers() do
		local sim = PlayerSimServer.getSim(player)
		local entity = PlayerSimServer.entityOf(player)
		if
			sim
			and entity
			and sim.weapons.loadout[WeaponSim.ULT] == "revive"
			and PlayerSimServer.inPlay(player)
			and revivable(entity, owner)
		then
			return true
		end
	end
	return false
end

-- The fallen a try of `reviver`'s along `cast` brings back, if any, as the
-- level, clouds and walls stood at `time`.
local function aimedAt(reviver: Entities.Entity, cast: AbilitySim.Cast, time: number): Fallen?
	local bodies: { ReviveSim.Body } = {}
	for id, f in fallen do
		local owner = Entities.get(id)
		if f.at == nil and owner and not owner.health.alive and revivable(reviver, owner) then
			table.insert(bodies, f.body)
		end
	end
	if #bodies == 0 then
		return nil
	end
	local o: Sight.Occluders = {
		clouds = CloudServer.standing(time),
		walls = BlazeServer.standing(time),
		barriers = BarrierServer.standing(),
		time = time,
		blocked = FogServer.blocked,
	}
	local id = ReviveSim.aimedAt(cast.origin, cast.direction, bodies, function(a: vector, b: vector): boolean
		return Sight.hidden(a, b, o)
	end)
	return if id then fallen[id] else nil
end

-- Tells `event` to those who'd hear it from `at`, as `source`'s.
local function tell(event: { [string]: any }, at: vector, source: number)
	local remote = Remotes.get().Ability
	for _, other in Players:GetPlayers() do
		if FogServer.hears(other, at, FogOfWar.Edges.cast, source) then
			remote:FireClient(other, event)
		end
	end
end

-- A try of the orb in `player`'s simulation, with the viewTime of the
-- input it came in: judged, and if it brings someone back, their return
-- under way.
local function try(player: Player, cast: AbilitySim.Cast, viewTime: number)
	local reviver = PlayerSimServer.entityOf(player)
	local sim = PlayerSimServer.getSim(player)
	if not reviver or not sim or not PlayerSimServer.inPlay(player) then
		return
	end
	local kit = sim.abilities
	if kit.holding ~= cast.slot or not AbilitySim.charged(kit) then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local f = aimedAt(reviver, cast, SlowSim.judged(viewTime, now))
	local owner = if f then Entities.get(f.body.id) else nil
	if not f or not owner then
		return
	end
	AbilitySim.used(kit, cast.slot)
	WeaponSim.putAway(sim.weapons, cast.time, AbilityConfig.unequip(cast.ability))
	PlayerSimServer.markDirty(player)
	f.by, f.at, f.started = reviver.id, now, false
	f.part:SetAttribute(ReviveSim.BY, reviver.id)
	f.part:SetAttribute(ReviveSim.AT, now)
	player:SetAttribute(ReviveSim.LAST_ATTRIBUTE, owner.name)
	local back = owner.player
	if back then
		PlayerSimServer.revive(back, f.body.feet, f.body.yaw, now)
	else
		Dummies.keepDown(owner.id)
	end
	tell({
		entity = reviver.id,
		target = owner.id,
		ability = cast.ability,
		kind = "reviving",
		at = now,
		position = Units.toStuds(f.body.feet),
		direction = Vector3.yAxis,
	}, f.body.feet, reviver.id)
end

-- `owner` bursting out of their body at `now`, back in play.
local function burst(owner: Entities.Entity, f: Fallen, now: number)
	remove(owner.id)
	local top = f.body.feet + UP * RES.height.value
	if owner.kind == "dummy" then
		Dummies.revive(owner.id, top, RES.fall.value)
	end
	CombatServer.back(owner, ReviveSim.UNSHIELDED)
	-- Out through any wall of ice they're in, from the floor to the top of
	-- their head as they burst out.
	local cfg = Tuning.config()
	local tall = RES.height.value + cfg.standHeight
	BarrierServer.breakIn(f.body.feet + UP * (tall / 2), vector.create(cfg.halfWidth, tall / 2, cfg.halfWidth), now)
	local by = if f.by then Entities.get(f.by) else nil
	for _, listener in ReviveServer.reviveListeners do
		listener(owner, by)
	end
	Remotes.get().Combat:FireAllClients({ kind = "revived", target = owner.id, attacker = f.by, weapon = "revive" })
	tell({
		entity = owner.id,
		ability = "resurrection",
		kind = "revived",
		at = now,
		position = Units.toStuds(top),
		direction = Vector3.yAxis,
	}, top, owner.id)
end

local function onTick(player: Player, input: any, casts: { AbilitySim.Cast }?)
	if not casts then
		return
	end
	for _, cast in casts do
		if cast.kind == "revive" then
			try(player, cast, input.viewTime)
		end
	end
end

-- Once a server frame, at server time `now`: those whose time has come
-- burst out, the bodies of those back, or gone, go, and a fallen dummy
-- waits while it's awaited.
function ReviveServer.step(now: number)
	for id, f in fallen do
		local owner = Entities.get(id)
		local at = f.at
		if not owner then
			remove(id)
		elseif not at then
			if owner.health.alive then
				remove(id)
			elseif owner.kind == "dummy" and awaited(owner) then
				Dummies.keepDown(id)
			elseif owner.kind == "dummy" then
				Dummies.release(id)
			end
		elseif now >= ReviveSim.burstAt(at) then
			local player = owner.player
			if not player or f.started then
				burst(owner, f, now)
			elseif now >= ReviveSim.burstAt(at) + PlayerSimServer.SPAWN_WAIT then
				-- Their new life never came: the return's given up, and the
				-- body lies on.
				PlayerSimServer.forgetRevive(player)
				f.by, f.at = nil, nil
				f.part:SetAttribute(ReviveSim.BY, nil)
				f.part:SetAttribute(ReviveSim.AT, nil)
			end
		end
	end
end

-- Every body gone, and every return under way with it (a new round): a
-- player's new life asked for and not started starts as any other, and a
-- dummy kept down comes back as it would have.
function ReviveServer.clear()
	for id, f in fallen do
		local owner = Entities.get(id)
		if f.at and owner then
			if owner.player then
				PlayerSimServer.forgetRevive(owner.player)
			else
				Dummies.release(id)
			end
		end
		remove(id)
	end
end

function ReviveServer.start()
	local where = Instance.new("Folder")
	where.Name = ReviveSim.FOLDER
	where.Parent = Workspace
	folder = where
	table.insert(CombatServer.killListeners, function(_, victim)
		lay(victim)
	end)
	-- Bots don't play the Resurrection yet (system 65).
	table.insert(PlayerSimServer.tickListeners, function(actor: PlayerSimServer.Actor, input: any, casts: { AbilitySim.Cast }?)
		if actor:IsA("Player") then
			onTick(actor, input, casts)
		end
	end)
	table.insert(PlayerSimServer.spawnListeners, function(player: Player)
		local entity = PlayerSimServer.entityOf(player)
		local f = if entity then fallen[entity.id] else nil
		if f and f.at then
			f.started = true
		end
	end)
end

return ReviveServer
