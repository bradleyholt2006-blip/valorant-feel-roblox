--!strict
-- Phoenix's Curveball on the client (system 30): flares in the air, and
-- their pops.
--   * Your own fly here at once, as you throw them (PlayerController's
--     castListeners), through FlareSim as the server flies them, and pop
--     where the server's will. When the server says where one goes (the
--     Ability remote's "flight"), it goes there instead if ours doesn't
--   * Others' come from the server ("flight"): where from, which way
--     round, where it stops and where it pops, flown here the same way as
--     the frame on your screen reaches the throw
--   * A flare is a ball of light, and its pop a flash of it with its sound
--     (GameSounds). The blind it gives is the server's, which BlindView
--     draws
-- In Workspace's VFFlares each flare in the air is a `Flare` ball, and each
-- pop a `Pop` one while it lasts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilitySim = require(Shared.Abilities.AbilitySim)
local FlareSim = require(Shared.Abilities.FlareSim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local SoundConfig = require(Shared.Audio.SoundConfig)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local GameSounds = require(script.Parent.Audio.GameSounds)

local FlareView = {}

local DT = 1 / MovementConfig.TickRate.value
local POP_TIME = FlareSim.popTime(DT)
local LIGHT = Color3.fromRGB(255, 196, 110)
local ORB = 0.25 -- metres across (ours)
local NEAR = 0.06 -- seconds your own is hidden for, so it doesn't fill the view leaving the eye
local MOVE = 0.25 -- metres: the server's pop this far from ours moves our flare
local FLASH = 0.3 -- seconds a pop's flash lasts (ours)
local STALE = 1 -- seconds: a pop the screen is this far past isn't shown
local KEEP = 5 -- seconds your popped flares are remembered, so the server's word on one doesn't throw it again

-- A flare in the air: its path (FlareSim.fly), and when it was thrown on
-- its clock, os.clock() for yours and the render clock for others'.
type Shown = { path: { vector }, start: number, own: boolean, entity: number, orb: Part }

local world = RobloxWorld.new()
local flares: { [string]: Shown } = {}
local popped: { [string]: number } = {} -- your flares popped, by key, at os.clock()
local folder: Folder? = nil

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFFlares"
	made.Parent = Workspace
	folder = made
	return made
end

local function ball(name: string, across: number, brightness: number, range: number): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = LIGHT
	p.Transparency = 1
	p.Size = Vector3.one * across * Units.STUDS_PER_METRE
	local light = Instance.new("PointLight")
	light.Color = LIGHT
	light.Brightness = brightness
	light.Range = range * Units.STUDS_PER_METRE
	light.Shadows = false
	light.Parent = p
	p.Parent = holder()
	return p
end

local function show(key: string, path: { vector }, start: number, own: boolean, entity: number)
	local had = flares[key]
	if had then
		had.orb:Destroy()
	end
	flares[key] = { path = path, start = start, own = own, entity = entity, orb = ball("Flare", ORB, 1.5, 3) }
end

-- A flare's pop at `at` (metres): its flash, swelling and fading, and its
-- sound, yours or another's.
local function pop(at: vector, own: boolean, entity: number)
	if own then
		GameSounds.playWorld(SoundConfig.Abilities.pop, at, "you")
	else
		GameSounds.playCast("pop", at, entity, true)
	end
	local p = ball("Pop", ORB, 8, 12)
	p.CFrame = CFrame.new(Units.toStuds(at))
	p.Transparency = 0
	local light = p:FindFirstChildOfClass("PointLight") :: PointLight
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - start) / FLASH
		if k >= 1 or p.Parent == nil then
			conn:Disconnect()
			p:Destroy()
			return
		end
		p.Size = Vector3.one * (ORB + 1.4 * math.sqrt(k)) * Units.STUDS_PER_METRE
		p.Transparency = k
		light.Brightness = 8 * (1 - k)
	end)
end

local function onOwnCast(cast: AbilitySim.Cast)
	if cast.kind ~= "flare" then
		return
	end
	local entity = PlayerController.entityId
	local flare = FlareSim.throw(entity, cast.tick, cast.origin, cast.direction, cast.curve or 1)
	show("own:" .. cast.tick, FlareSim.fly(flare, DT, world), os.clock(), true, entity)
end

local function onEvent(event: any)
	if typeof(event) ~= "table" or event.ability ~= "curveball" or event.kind ~= "flight" then
		return
	end
	if typeof(event.entity) ~= "number" or typeof(event.id) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	if typeof(event.position) ~= "Vector3" or typeof(event.direction) ~= "Vector3" or typeof(event.pop) ~= "Vector3" then
		return
	end
	local stop = if typeof(event.stop) == "number" then event.stop else nil
	local curve = if event.curve == -1 then -1 else 1
	local flare = FlareSim.throw(event.entity, event.id, Units.toMetres(event.position), Units.asVector(event.direction), curve)
	-- With no world, it stops where the server says it did.
	local path = FlareSim.fly(flare, DT, nil, stop)
	if event.entity ~= PlayerController.entityId then
		show(event.entity .. ":" .. event.id, path, event.at, false, event.entity)
		return
	end
	local key = "own:" .. event.id
	local mine = flares[key]
	if popped[key] or (mine and vector.magnitude(mine.path[#mine.path] - Units.toMetres(event.pop)) <= MOVE) then
		return
	end
	-- Ours doesn't go where the server's does, or wasn't thrown here: the
	-- server's goes, on your clock.
	local start = if mine then mine.start else os.clock() - (Workspace:GetServerTimeNow() - event.at)
	show(key, path, start, true, event.entity)
end

function FlareView.start()
	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()
		for key, f in flares do
			local age = (if f.own then clock else render) - f.start
			if age >= POP_TIME then
				f.orb:Destroy()
				flares[key] = nil
				if f.own then
					popped[key] = clock
				end
				if age - POP_TIME < STALE then
					pop(f.path[#f.path], f.own, f.entity)
				end
			elseif age < (if f.own then NEAR else 0) then
				f.orb.Transparency = 1
			else
				f.orb.Transparency = 0
				f.orb.CFrame = CFrame.new(Units.toStuds(FlareSim.at(f.path, age, DT)))
			end
		end
		for key, at in popped do
			if clock - at > KEEP then
				popped[key] = nil
			end
		end
	end)
end

return FlareView
