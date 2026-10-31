--!strict
-- Sage's Healing Orb on the server (system 36). Each try of it in a
-- player's simulation (a "heal" or "selfheal" cast) is judged here, from
-- what their screen showed as they tried (the input's viewTime): fire's on
-- the hurt ally the crosshair was over, posed as the screen showed them (as
-- far back as a shot's rewind goes, CombatServer.rewound) and in sight of
-- the eye, past the level, clouds and walls of fire and of ice
-- (HealSim.aimedAt); alt fire's on the healer, if they're hurt. A try that
-- heals spends the charge and puts the orb away between ticks, the gun
-- back in hand a moment after (AbilityConfig.HealingOrb), and the ack
-- takes it to its owner; one that heals nobody leaves it in hand.
--
-- A heal gives its health a few points at a time (FireServer.EVERY), as
-- HealSim runs it, through CombatServer.mend. It's over once its time has
-- run, or its target dies, comes back to a new life or leaves, and every
-- heal is over with a new round (HealServer.clear, from the arena).
--
-- As a heal starts, those who'd hear the healer's cast are told (the
-- Ability remote's "healing", with the healer and the target, the fog of
-- war's way, system 35), and every client as it's over ("healed"), so each
-- draws its glow. The healer's `VFLastHeal` attribute is the name of the
-- player it healed, which scripted checks read. Bots heal and are healed
-- as players are (system 65), each known by its stand-in
-- (PlayerSimServer.Actor).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local HealSim = require(Shared.Abilities.HealSim)
local FogOfWar = require(Shared.Combat.FogOfWar)
local Sight = require(Shared.Combat.Sight)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local FogServer = require(script.Parent.FogServer)
local CloudServer = require(script.Parent.CloudServer)
local BlazeServer = require(script.Parent.BlazeServer)
local BarrierServer = require(script.Parent.BarrierServer)
local FireServer = require(script.Parent.FireServer)

local HealServer = {}

HealServer.LAST_ATTRIBUTE = "VFLastHeal"

local HO = AbilityConfig.HealingOrb

-- A heal under way, and when it last gave its points.
type Running = { heal: HealSim.Heal, lot: number }

local heals: { Running } = {}

-- Every client told the heals on `target` are over (every heal, with no
-- target).
local function healed(target: number?)
	Remotes.get().Ability:FireAllClients({ kind = "healed", target = target })
end

-- The hurt ally a try along the crosshair heals, if any, posed as the
-- healer's screen showed them at `viewTime`.
local function aimedAt(healer: Entities.Entity, cast: AbilitySim.Cast, viewTime: number): Entities.Entity?
	local rewound, time = CombatServer.rewound(healer, viewTime, function(entity: Entities.Entity): boolean
		local h = entity.health
		return CombatServer.teammates(healer, entity) and HealSim.hurt(h.health, h.maxHealth)
	end)
	local allies: { HealSim.Body } = {}
	for _, t in rewound do
		table.insert(allies, { id = t.id, pose = { position = t.pose.position, yaw = t.pose.yaw, crouchAlpha = t.pose.crouchAlpha } })
	end
	local o: Sight.Occluders = {
		clouds = CloudServer.standing(time),
		walls = BlazeServer.standing(time),
		barriers = BarrierServer.standing(),
		time = time,
		blocked = FogServer.blocked,
	}
	local id = HealSim.aimedAt(cast.origin, cast.direction, allies, function(a: vector, b: vector): boolean
		return Sight.hidden(a, b, o)
	end)
	return if id then Entities.get(id) else nil
end

-- A heal of `healer`'s (`player`'s) on `target` starting, from `cast`.
local function start(player: PlayerSimServer.Actor, healer: Entities.Entity, target: Entities.Entity, cast: AbilitySim.Cast)
	local now = Workspace:GetServerTimeNow()
	local total = if target == healer then HO.selfHeal.value else HO.allyHeal.value
	table.insert(heals, { heal = HealSim.new(target.id, healer.id, total, now), lot = now })
	if target.kind ~= "dummy" then
		player:SetAttribute(HealServer.LAST_ATTRIBUTE, target.name)
	end
	local event = {
		entity = healer.id,
		target = target.id,
		ability = cast.ability,
		kind = "healing",
		at = now,
		position = Units.toStuds(cast.position),
		direction = Units.asVector3(cast.direction),
	}
	local remote = Remotes.get().Ability
	for _, other in Players:GetPlayers() do
		if FogServer.hears(other, cast.position, FogOfWar.Edges.cast, healer.id) then
			remote:FireClient(other, event)
		end
	end
end

-- A try of the orb in `player`'s simulation, with the viewTime of the
-- input it came in: judged, and if it heals, the heal under way.
local function try(player: PlayerSimServer.Actor, cast: AbilitySim.Cast, viewTime: number)
	local healer = PlayerSimServer.entityOf(player)
	local sim = PlayerSimServer.getSim(player)
	if not healer or not sim or not healer.health.alive or not PlayerSimServer.inPlay(player) then
		return
	end
	local kit = sim.abilities
	if kit.holding ~= cast.slot or kit.charges[cast.slot] <= 0 then
		return
	end
	local h = healer.health
	local target: Entities.Entity? = nil
	if cast.kind == "selfheal" then
		target = if HealSim.hurt(h.health, h.maxHealth) then healer else nil
	else
		target = aimedAt(healer, cast, viewTime)
	end
	if not target then
		return
	end
	AbilitySim.used(kit, cast.slot)
	WeaponSim.putAway(sim.weapons, cast.time, AbilityConfig.unequip(cast.ability))
	PlayerSimServer.markDirty(player)
	start(player, healer, target, cast)
end

local function onTick(player: PlayerSimServer.Actor, input: any, casts: { AbilitySim.Cast }?)
	if not casts then
		return
	end
	for _, cast in casts do
		if cast.kind == "heal" or cast.kind == "selfheal" then
			try(player, cast, input.viewTime)
		end
	end
end

-- Once a server frame, at server time `now`: each heal gives what it's
-- come to, and those over go.
function HealServer.step(now: number)
	local i = 1
	while i <= #heals do
		local r = heals[i]
		local heal = r.heal
		local target = Entities.get(heal.target)
		if not target or not target.health.alive then
			table.remove(heals, i)
			healed(heal.target)
			continue
		end
		HealSim.step(heal, now, target.health.lastHit)
		local done = HealSim.done(heal)
		if done or now - r.lot >= FireServer.EVERY then
			local owed = HealSim.take(heal)
			if owed > 0 then
				CombatServer.mend(target, owed, 0)
				r.lot = now
			end
		end
		if done then
			table.remove(heals, i)
			healed(heal.target)
		else
			i += 1
		end
	end
end

-- Every heal over (a new round), and every client told.
function HealServer.clear()
	table.clear(heals)
	healed(nil)
end

-- The heals on a player over (a death or a new life).
local function stopOn(player: PlayerSimServer.Actor)
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	for i = #heals, 1, -1 do
		if heals[i].heal.target == entity.id then
			table.remove(heals, i)
			healed(entity.id)
		end
	end
end

function HealServer.start()
	table.insert(PlayerSimServer.tickListeners, onTick)
	table.insert(PlayerSimServer.deathListeners, stopOn)
	table.insert(PlayerSimServer.spawnListeners, stopOn)
	table.insert(PlayerSimServer.botDeathListeners, stopOn)
	table.insert(PlayerSimServer.botSpawnListeners, stopOn)
end

return HealServer
