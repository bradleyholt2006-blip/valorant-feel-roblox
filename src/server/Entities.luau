--!strict
-- Registry of everything that can be shot: players, practice dummies and
-- bots (system 60). Combat asks it for target poses; replication asks it
-- for snapshot poses.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Health = require(Shared.Combat.Health)
local PlayerCodec = require(Shared.Net.PlayerCodec)

export type Kind = "player" | "dummy" | "bot"

export type Entity = {
	id: number,
	kind: Kind,
	name: string,
	player: Player?,
	health: Health.State,
	sim: any?, -- PlayerSim.State when spawned
	-- The pose snapshots show, in metres (a little behind the simulation,
	-- MovePacer), or nil while not spawned.
	pose: () -> PlayerCodec.Pose?,
	onKilled: (attacker: Entity?) -> (),
}

local Entities = {}

local byId: { [number]: Entity } = {}

function Entities.add(entity: Entity)
	byId[entity.id] = entity
end

function Entities.remove(id: number)
	byId[id] = nil
end

function Entities.get(id: number): Entity?
	return byId[id]
end

function Entities.all(): { [number]: Entity }
	return byId
end

-- An entity's id in the match's rules (MatchRules): a player's UserId, a
-- bot's (PlayerCodec.botRuleId); nil for anything else.
function Entities.ruleId(entity: Entity): number?
	local player = entity.player
	if player then
		return player.UserId
	end
	return if entity.kind == "bot" then PlayerCodec.botRuleId(entity.id - PlayerCodec.BOT_BASE) else nil
end

-- What a combat event tells clients about an entity's health and shield:
-- the shield's kind as `armor` and a Regen Shield's pool left as `pool`.
function Entities.vitals(entity: Entity): { [string]: any }
	local h = entity.health
	return { target = entity.id, health = h.health, shield = h.shield, armor = h.kind, pool = h.pool }
end

-- The poses this frame's snapshot shows of every living, spawned entity
-- (players, dummies and bots pace theirs, MovePacer).
function Entities.poses(): { PlayerCodec.Pose }
	local out = {}
	for _, entity in byId do
		local pose = entity.pose()
		if pose then
			table.insert(out, pose)
		end
	end
	return out
end

return Entities
