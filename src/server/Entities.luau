--!strict
-- Registry of everything that can be shot: players and practice dummies.
-- Combat asks it for target poses; replication asks it for snapshot poses.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Health = require(Shared.Combat.Health)
local PlayerCodec = require(Shared.Net.PlayerCodec)

export type Kind = "player" | "dummy"

export type Entity = {
	id: number,
	kind: Kind,
	name: string,
	player: Player?,
	health: Health.State,
	sim: any?, -- PlayerSim.State when spawned
	-- Current pose in metres, or nil while not spawned.
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

-- Current poses of every living, spawned entity.
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
