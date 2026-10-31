--!strict
-- Omen's Shrouded Step on the server (system 42). Where it takes him, its
-- windup, his going and his arrival run in his simulation (StepSim,
-- AbilitySim, PlayerSim), as his client predicts them, and clients hear of
-- it being fired and of his arrival (the Ability remote's "step" and
-- "arrive", from AbilityServer: those who'd hear them or have him in their
-- snapshots, the fog of war, system 35; his arrival only as far as its own
-- curve goes). This does what only the server can:
--   * as it's fired, where it takes him is his `VFLastStep` attribute
--     (metres), which scripted checks read
--   * as he goes, his body's out of play until he's there: nothing hurts
--     or heals him, shots go through him, the snapshots leave him out,
--     nothing blinds him and he picks nothing up (PlayerSimServer.inPlay).
--     A blind or a nearsight he already had runs on (ours: nothing says
--     it goes)
--   * every client hears of his going ("vanish", with where he's going), as
--     they do of Run it Back's mark: anyone who can see it sees him go, and
--     the floor he's going to shows his shadow until he's there
--   * as he's there he's back in play as he went: the same health and
--     shield
--   * a body that's been gone longer than its time and the grace, on the
--     server's clock, is back in play where it is: his moves have stopped
--     coming, and moves held back mustn't keep him out of play

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerSimServer = require(script.Parent.PlayerSimServer)
local CombatServer = require(script.Parent.CombatServer)

local StepServer = {}

StepServer.LAST_STEP_ATTRIBUTE = "VFLastStep"

local SS = AbilityConfig.ShroudedStep

-- When each player went (server time), while they're out of play.
local goneAt: { [Player]: number } = {}

-- Back in play as they went.
local function back(player: Player)
	goneAt[player] = nil
	local entity = PlayerSimServer.entityOf(player)
	if entity and PlayerSimServer.isAlive(player) then
		CombatServer.reappear(entity)
	end
end

-- Gone at `now` from where `cast` says, to the floor it marked: out of
-- play, and every client told.
local function vanish(player: Player, cast: AbilitySim.Cast, to: vector, now: number)
	local entity = PlayerSimServer.entityOf(player)
	if not entity then
		return
	end
	CombatServer.withdraw(entity)
	goneAt[player] = now
	Remotes.get().Ability:FireAllClients({
		entity = entity.id,
		ability = cast.ability,
		kind = "vanish",
		at = now,
		position = Units.toStuds(cast.position),
		direction = Units.asVector3(cast.direction),
		to = Units.toStuds(to),
	})
end

local function onCast(player: Player, cast: AbilitySim.Cast)
	local to = cast.step
	if cast.kind == "step" and to then
		player:SetAttribute(StepServer.LAST_STEP_ATTRIBUTE, Units.asVector3(to))
	elseif cast.kind == "vanish" and to then
		vanish(player, cast, to, Workspace:GetServerTimeNow())
	elseif cast.kind == "arrive" then
		back(player)
	end
end

local function forget(player: Player)
	goneAt[player] = nil
end

-- Once a server frame, at server time `now`, after the moves: bodies gone
-- too long back in play.
function StepServer.step(now: number)
	for player, at in goneAt do
		if now - at >= SS.away.value + SS.grace.value then
			back(player)
		end
	end
end

function StepServer.start()
	-- Bots don't play Shrouded Step yet (system 65).
	table.insert(PlayerSimServer.castListeners, function(actor: PlayerSimServer.Actor, cast: AbilitySim.Cast)
		if actor:IsA("Player") then
			onCast(actor, cast)
		end
	end)
	table.insert(PlayerSimServer.deathListeners, forget)
	table.insert(PlayerSimServer.spawnListeners, forget)
	Players.PlayerRemoving:Connect(forget)
end

return StepServer
