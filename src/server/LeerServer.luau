--!strict
-- Reyna's Leer on the server (system 74). Each eye cast (a "leer" cast)
-- flies here through LeerSim on the server's clock, from when it's told
-- of, as far as the level lets it (LeerSim.reach: a floor in its way stops
-- it), and nothing changes its path after the cast. Every client is told
-- of the cast (the Ability remote's "flight"): where from, which way, how
-- far and when, in server time, so each draws it the same way.
--
-- Open (LeerSim.open), each server frame it nearsights every enemy of its
-- caster's who looks at it (LeerSim.looks), judged from where the server
-- last had their eye and their view (PlayerSimServer.view): players on
-- another side than hers and bots, and on the course, with no sides,
-- everyone but her. Allies never are (Boosting Ground's guide: 'Leer does
-- not affect Reyna or her teammates'). In the way: the level, but not the
-- spawns' barriers (FogServer.blocked), the clouds standing
-- (CloudServer), the walls of fire (BlazeServer) and the walls of ice
-- (BarrierServer), as for anyone's eye (Sight). Their nearsight runs on
-- through ParanoiaServer (ParanoiaServer.nearsee), on the attribute
-- Paranoia's is kept on, so the minimap, a flash's pop and bots go by it
-- as they do by Paranoia's, and it goes as Paranoia's does, with a death
-- or a new life; but it doesn't deafen. An eye goes on through its
-- caster's death.
--
-- In the world, its eye stands in the level shots and swings are traced
-- through, as the attacker's screen showed it (CombatServer.levelAt): a
-- bullet or a knife of her enemies' that strikes it takes its damage off
-- the eye's health, and at none it breaks ("break") and nearsights no
-- more; her side's do nothing, as the guides have enemies alone break it
-- (esports.net: 'The eye can be destroyed by enemies'). On the course,
-- with no sides, anyone's does, hers too, so it can be tried alone. An
-- eye is kept for shots that come in late until SlowSim.LAG after its
-- time's up. They all go with a new round (Arena), which every client
-- hears of from FireServer.clear's "out", and a caster's go as she starts
-- a new life, which every client hears of ("gone"). Each caster's last
-- eye is their `VFLastLeer` attribute
-- (where it came to rest, metres), the health it has left their
-- `VFLeerHealth`, and once it's gone, the names of those it nearsighted
-- their `VFLastLeered` (in order, "" for nobody), which scripted checks
-- read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local LeerSim = require(Shared.Abilities.LeerSim)
local SlowSim = require(Shared.Abilities.SlowSim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local Penetration = require(Shared.Combat.Penetration)
local Sight = require(Shared.Combat.Sight)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local Entities = require(script.Parent.Entities)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)
local CloudServer = require(script.Parent.CloudServer)
local BlazeServer = require(script.Parent.BlazeServer)
local BarrierServer = require(script.Parent.BarrierServer)
local FogServer = require(script.Parent.FogServer)
local ParanoiaServer = require(script.Parent.ParanoiaServer)

local LeerServer = {}

local LE = AbilityConfig.Leer
local world = RobloxWorld.new()

type Actor = PlayerSimServer.Actor

-- An eye cast: whose, and their side (nil on the course), its health,
-- whether its caster's been told where it came to rest, and whom it's
-- nearsighted, their names in order.
type Kept = {
	player: Actor,
	side: number?,
	eye: LeerSim.Eye,
	health: number,
	told: boolean,
	leered: { [Actor]: boolean },
	names: { string },
}

local kept: { Kept } = {}
local keptOf: { [LeerSim.Eye]: Kept } = {}
-- The eyes kept, for the shots.
local eyes: { LeerSim.Eye } = {}

local function forget(i: number)
	local k = kept[i]
	table.remove(kept, i)
	keptOf[k.eye] = nil
	local at = table.find(eyes, k.eye)
	if at then
		table.remove(eyes, at)
	end
end

local function onCast(player: Actor, cast: AbilitySim.Cast)
	if cast.kind ~= "leer" then
		return
	end
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local travel = LeerSim.reach(world, cast.origin, cast.direction)
	local eye = LeerSim.cast(entity.id, cast.tick, now, cast.origin, cast.direction, travel)
	Remotes.get().Ability:FireAllClients({
		entity = entity.id,
		ability = cast.ability,
		kind = "flight",
		id = cast.tick,
		at = now,
		position = Units.toStuds(cast.origin),
		direction = Units.asVector3(eye.way),
		travel = eye.travel, -- metres
	})
	local side = player:GetAttribute(ArenaConfig.SIDE)
	local k: Kept = {
		player = player,
		side = if typeof(side) == "number" then side else nil,
		eye = eye,
		health = LE.health.value,
		told = false,
		leered = {},
		names = {},
	}
	table.insert(kept, k)
	keptOf[eye] = k
	table.insert(eyes, eye)
end

-- Whether `actor` is an enemy of `k`'s caster, to be nearsighted: on
-- another side, and with no sides, anyone but her.
local function enemy(k: Kept, actor: Actor): boolean
	if actor == k.player then
		return false
	end
	return k.side == nil or actor:GetAttribute(ArenaConfig.SIDE) ~= k.side
end

-- An open eye's frame, at server time `now`: each enemy in play who looks
-- at it, with nothing between, nearsighted.
local function look(k: Kept, now: number, o: Sight.Occluders)
	local at = LeerSim.rest(k.eye)
	for _, actor in PlayerSimServer.actors() do
		if not enemy(k, actor) or not PlayerSimServer.inPlay(actor) then
			continue
		end
		local from, view = PlayerSimServer.view(actor)
		if not from or not view or not LeerSim.looks(at, from, view) or Sight.hidden(from, at, o) then
			continue
		end
		local n = LeerSim.nearsight(ParanoiaServer.nearsightOf(actor), now)
		if n then
			ParanoiaServer.nearsee(actor, n)
		end
		if not k.leered[actor] then
			k.leered[actor] = true
			table.insert(k.names, actor.Name)
		end
	end
end

-- Whether `attacker`'s bullets and knives break an eye of `owner`'s (an
-- entity id): her enemies' do, and with no sides (the course) anyone's,
-- hers too. One whose caster's gone breaks to anyone.
local function breaks(attacker: Entities.Entity, owner: number): boolean
	local entity = Entities.get(owner)
	return entity == nil or not CombatServer.teammates(attacker, entity)
end

-- A bullet or a knife of `attacker`'s that struck an eye (`key`, its
-- piece), for `amount`: the eye takes it, and at nothing breaks.
local function struck(attacker: Entities.Entity, key: any, amount: number)
	local piece = LeerSim.piece(key)
	if not piece or amount <= 0 then
		return
	end
	local e = piece.eye
	local k = keptOf[e]
	local now = Workspace:GetServerTimeNow()
	if not k or e.broken ~= nil or now >= LeerSim.ends(e) or not breaks(attacker, e.owner) then
		return
	end
	k.health = math.max(k.health - amount, 0)
	if k.player.Parent then
		k.player:SetAttribute(LeerSim.HEALTH_ATTRIBUTE, k.health)
	end
	if k.health <= 0 then
		e.broken = now
		Remotes.get().Ability:FireAllClients({
			entity = e.owner,
			ability = "leer",
			kind = "break",
			id = e.id,
			at = now,
			point = Units.asVector3(LeerSim.at(e, now - e.at)),
		})
	end
end

-- Once a server frame, at server time `now`: the eyes that have come to
-- rest told of, the open ones nearsighting whoever looks at them, and
-- those long gone forgotten, their caster told whom they nearsighted.
function LeerServer.step(now: number)
	local o: Sight.Occluders? = nil
	local function occluders(): Sight.Occluders
		local made: Sight.Occluders = o
			or {
				clouds = CloudServer.standing(now),
				walls = BlazeServer.standing(now),
				barriers = BarrierServer.standing(),
				time = now,
				blocked = FogServer.blocked,
			}
		o = made
		return made
	end
	for i = #kept, 1, -1 do
		local k = kept[i]
		local e = k.eye
		if not k.told and now >= LeerSim.opens(e) then
			k.told = true
			if k.player.Parent then
				k.player:SetAttribute(LeerSim.LAST_ATTRIBUTE, Units.asVector3(LeerSim.rest(e)))
				k.player:SetAttribute(LeerSim.HEALTH_ATTRIBUTE, k.health)
				k.player:SetAttribute(LeerSim.LEERED_ATTRIBUTE, "")
			end
		end
		if LeerSim.open(e, now) then
			look(k, now, occluders())
		end
		if now >= LeerSim.ends(e) + SlowSim.LAG then
			if k.player.Parent then
				k.player:SetAttribute(LeerSim.LEERED_ATTRIBUTE, table.concat(k.names, ","))
			end
			forget(i)
		end
	end
end

-- Every eye gone (a new round). FireServer.clear tells every client.
function LeerServer.clear()
	table.clear(kept)
	table.clear(keptOf)
	table.clear(eyes)
end

function LeerServer.start()
	table.insert(PlayerSimServer.castListeners, onCast)
	local function newLife(player: Actor)
		local now = Workspace:GetServerTimeNow()
		for i = #kept, 1, -1 do
			local k = kept[i]
			if k.player ~= player then
				continue
			end
			if LeerSim.standing(k.eye, now) then
				Remotes.get().Ability:FireAllClients({ entity = k.eye.owner, ability = "leer", kind = "gone", id = k.eye.id, at = now })
			end
			forget(i)
		end
	end
	table.insert(PlayerSimServer.spawnListeners, newLife)
	table.insert(PlayerSimServer.botSpawnListeners, newLife)
	Players.PlayerRemoving:Connect(newLife)
	local levelBefore = CombatServer.levelAt
	CombatServer.levelAt = function(base: Penetration.Level, viewTime: number): Penetration.Level
		local level = if levelBefore then levelBefore(base, viewTime) else base
		return LeerSim.level(level, eyes, SlowSim.judged(viewTime, Workspace:GetServerTimeNow()))
	end
	local struckBefore = CombatServer.struck
	CombatServer.struck = function(attacker: Entities.Entity, key: any, amount: number)
		if LeerSim.piece(key) then
			struck(attacker, key, amount)
		elseif struckBefore then
			struckBefore(attacker, key, amount)
		end
	end
end

return LeerServer
