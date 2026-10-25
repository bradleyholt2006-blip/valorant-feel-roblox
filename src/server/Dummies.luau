--!strict
-- Practice dummies, like the reference's shooting-range bots. They are real
-- simulated players (same PlayerSim, same 128 Hz ticks), driven by a script
-- instead of a client, so they move, accelerate and stop exactly like a
-- player would. That makes them honest targets for hit-registration tests.
--
-- Spawn points are Parts in a "DummySpawns" folder (TestRange builds some)
-- with a Mode attribute: "static", "strafe" or "crouch".
--
-- They tick at 128 Hz on the server's clock, two or three ticks a 60 Hz
-- frame, so the snapshots show them through a MovePacer, about a tick
-- behind, and they move as evenly as the simulation does.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local PlayerSim = require(Shared.PlayerSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local Health = require(Shared.Combat.Health)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local MovePacer = require(Shared.Net.MovePacer)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local StepTracker = require(Shared.Audio.StepTracker)

local Entities = require(script.Parent.Entities)
local Tuning = require(script.Parent.Tuning)

local TICK_RATE = MovementConfig.TickRate.value
local DT = 1 / TICK_RATE
local RESPAWN_TIME = 2
local MAX_CATCH_UP = 0.25 -- seconds of ticks a frame will run after a stall; older ones are skipped
local STRAFE_TICKS = math.floor(0.6 * TICK_RATE) -- direction change every 0.6 s (estimate of the range bots)

local B = PlayerSim.Buttons

type Dummy = {
	entity: Entities.Entity,
	mode: string,
	spawnFeet: vector,
	yaw: number,
	sim: PlayerSim.State,
	alive: boolean,
	respawnAt: number,
	ticks: number,
	pacer: MovePacer.Pacer, -- the pose after each tick, at the tick's server time
	shown: PlayerCodec.Pose?, -- what this frame's snapshot shows
}

local Dummies = {}

local dummies: { Dummy } = {}
local world = RobloxWorld.new()
local lastTick: number? = nil -- server time of the last tick
local clock = 0 -- server time of the last frame

local function buttonsFor(d: Dummy): number
	if d.mode == "strafe" then
		return if (d.ticks // STRAFE_TICKS) % 2 == 0 then B.Left else B.Right
	elseif d.mode == "crouch" then
		return B.Crouch
	end
	return 0
end

-- The dummy's pose as the simulation has it now.
local function currentPose(d: Dummy): PlayerCodec.Pose
	local m, w = d.sim.movement, d.sim.weapons
	return {
		id = d.entity.id,
		position = m.position,
		yaw = d.yaw,
		pitch = 0,
		crouchAlpha = m.crouchAlpha,
		grounded = m.grounded,
		alive = true,
		quiet = StepTracker.isQuiet(buttonsFor(d), m.crouched),
		reloading = WeaponSim.isReloading(w),
		weapon = WeaponConfig.IndexOf[w.loadout[w.equipped]] or 0,
	}
end

local function spawnDummy(d: Dummy)
	d.sim = PlayerSim.new(d.spawnFeet, { "vandal", "", "" }, d.entity.id)
	d.entity.sim = d.sim
	d.alive = true
	d.ticks = 0
	MovePacer.reset(d.pacer)
	d.shown = nil
	Health.reset(d.entity.health)
	Remotes.get().Combat:FireAllClients({ kind = "spawn", target = d.entity.id, health = d.entity.health.health, shield = d.entity.health.shield })
end

local function addDummy(index: number, feet: vector, mode: string)
	local hp = WeaponConfig.Health
	local d: Dummy
	local entity: Entities.Entity = {
		id = PlayerCodec.DUMMY_BASE + index,
		kind = "dummy",
		name = string.format("Dummy %d (%s)", index, mode),
		player = nil,
		health = Health.new(hp.maxHealth.value, hp.heavyShield.value),
		sim = nil,
		pose = function(): PlayerCodec.Pose?
			if not d.alive then
				return nil
			end
			-- Until its first tick, where it spawned.
			return d.shown or currentPose(d)
		end,
		onKilled = function()
			d.alive = false
			d.respawnAt = clock + RESPAWN_TIME
		end,
	}
	d = {
		entity = entity,
		mode = mode,
		spawnFeet = feet,
		yaw = math.pi, -- face +Z, toward the spawn
		sim = PlayerSim.new(feet),
		alive = true,
		respawnAt = 0,
		ticks = 0,
		pacer = MovePacer.new(),
		shown = nil,
	}
	table.insert(dummies, d)
	Entities.add(entity)
	spawnDummy(d)
end

local function findSpawns(): { BasePart }
	local out = {}
	for _, root in { Workspace:FindFirstChild("Map"), Workspace:FindFirstChild("VFTestRange") } do
		local folder = root and root:FindFirstChild("DummySpawns")
		if folder then
			for _, child in folder:GetChildren() do
				if child:IsA("BasePart") then
					table.insert(out, child)
				end
			end
		end
	end
	table.sort(out, function(a, b)
		return a.Name < b.Name
	end)
	return out
end

function Dummies.start()
	for i, part in findSpawns() do
		local feet = Units.toMetres(part.Position - Vector3.new(0, part.Size.Y / 2, 0)) + vector.create(0, 0.02, 0)
		addDummy(i, feet, (part:GetAttribute("Mode") :: string?) or "static")
	end
end

-- One server frame, ending at server time `now` (the time this frame's
-- snapshot carries): runs every tick due by then.
function Dummies.step(now: number)
	clock = now
	local last = lastTick or now
	if now - last > MAX_CATCH_UP then
		last = now - MAX_CATCH_UP
	end
	local cfg = Tuning.config()
	while last + DT <= now do
		last += DT
		for _, d in dummies do
			if not d.alive then
				if last >= d.respawnAt then
					spawnDummy(d)
				end
				continue
			end
			d.ticks += 1
			local input = { seq = d.ticks, buttons = buttonsFor(d), yaw = d.yaw, pitch = 0, slot = 1, viewTime = 0 }
			PlayerSim.step(d.sim, input, cfg, world, DT)
			MovePacer.push(d.pacer, last, currentPose(d))
		end
	end
	lastTick = last
	for _, d in dummies do
		d.shown = if d.alive then MovePacer.advance(d.pacer, now) else nil
	end
end

return Dummies
