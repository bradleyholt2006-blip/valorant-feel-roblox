--!strict
-- Sova's Shock Bolt on the client (system 45): its bolts in the air and
-- their bursts.
--   * your own bolts fly here at once, as you loose them (PlayerController's
--     castListeners), through BoltSim as the server flies them, and burst
--     where the server's will. When the server says where one goes (the
--     Ability remote's "flight"), it goes there instead if ours doesn't
--   * others' come from the server ("flight"), drawn as the frame on your
--     screen reaches the loose
--   * a bolt is a thin shaft of light along its way, whistling as it flies,
--     and where it lands it bursts: a ball of light flashing out to the
--     burst's outer radius and fading, with a crack
-- Its bow's draw shows under the crosshair as the Recon Bolt's does
-- (ReconView). In Workspace's VFShock each bolt in the air is a `Bolt` part
-- and each burst a `Burst` ball; the bolts go when the server says every
-- fire's out (a new round, "out"). VFShock's attributes count the bolts in
-- the air (`Bolts`) and the bursts shown (`Bursts`), which scripted checks
-- read.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local BoltSim = require(Shared.Abilities.BoltSim)
local FireballSim = require(Shared.Abilities.FireballSim)
local ShockSim = require(Shared.Abilities.ShockSim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local SoundConfig = require(Shared.Audio.SoundConfig)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local FireView = require(script.Parent.FireView)
local GameSounds = require(script.Parent.Audio.GameSounds)

local ShockView = {}

local SB = AbilityConfig.ShockBolt
local RC = AbilityConfig.ReconBolt
local DT = 1 / MovementConfig.TickRate.value
local LIGHT = Color3.fromRGB(235, 235, 120)
local GLOW = Color3.fromRGB(255, 240, 140)
local SHAFT = 0.7 -- metres long, drawn (ours)
local THICK = 0.05 -- metres across
local NEAR = 0.06 -- seconds your own is hidden for, so it doesn't fill the view leaving the eye
local MOVE = 0.25 -- metres: the server's bolt bursting this far from ours moves ours
local FLASH = 0.35 -- seconds a burst takes to flash out and fade (ours)
local STALE = 1 -- seconds: a burst the screen is this far past isn't shown
local KEEP = 8 -- seconds your loosed bolts are remembered, so the server's word on one doesn't loose it again

-- A bolt loosed: its keys, when it bursts (nil for never) and the way the
-- surface there faces, on the clock it was loosed on: os.clock() for yours
-- and the render clock for others'.
type Shown = {
	keys: { FireballSim.Key },
	land: number?,
	normal: vector?,
	start: number,
	own: boolean,
	entity: number,
	part: Part?,
	heard: boolean,
}

local world = RobloxWorld.new()
local shown: { [string]: Shown } = {}
local done: { [string]: number } = {} -- your bolts gone, by key, at os.clock()
local folder: Folder? = nil
local bursts = 0

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFShock"
	made.Parent = Workspace
	folder = made
	return made
end

local function plain(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

local function shaft(): Part
	local p = Instance.new("Part")
	p.Name = "Bolt"
	plain(p)
	p.Material = Enum.Material.Neon
	p.Color = LIGHT
	p.Transparency = 1
	p.Size = Vector3.new(THICK, THICK, SHAFT) * Units.STUDS_PER_METRE
	local l = Instance.new("PointLight")
	l.Color = GLOW
	l.Brightness = 1.5
	l.Range = 3 * Units.STUDS_PER_METRE
	l.Shadows = false
	l.Parent = p
	p.Parent = holder()
	return p
end

local function keyOf(entity: number, id: number): string
	return if entity == PlayerController.entityId then "own:" .. id else entity .. ":" .. id
end

local function forget(s: Shown)
	if s.part then
		s.part:Destroy()
	end
end

local function show(key: string, keys: { FireballSim.Key }, land: number?, normal: vector?, start: number, own: boolean, entity: number)
	local had = shown[key]
	if had then
		forget(had)
	end
	shown[key] = {
		keys = keys,
		land = land,
		normal = normal,
		start = start,
		own = own,
		entity = entity,
		part = shaft(),
		heard = if had then had.heard else false,
	}
end

-- A sound of the bolt's out in the world at `at`: yours, or its owner's.
local function play(kind: string, at: vector, own: boolean, entity: number, follow: (() -> vector?)?)
	local sound = SoundConfig.Abilities[kind]
	if not sound then
		return
	end
	if own then
		GameSounds.playWorld(sound, at, "you", { follow = follow })
	else
		GameSounds.playWorld(sound, at, RemoteEntities.nameOf(entity), { follow = follow })
	end
end

local function onOwnCast(cast: AbilitySim.Cast)
	if cast.kind ~= "bolt" or cast.ability ~= "shockbolt" then
		return
	end
	local entity = PlayerController.entityId
	local bolt = BoltSim.shoot(entity, cast.tick, cast.origin, cast.direction, cast.bars or 0, cast.bounces or 0)
	local land = BoltSim.fly(bolt, DT, world)
	show(keyOf(entity, cast.tick), bolt.keys, land, bolt.normal, os.clock(), true, entity)
end

local function onFlight(event: any)
	local keys = FireView.keysOf(event.keys)
	if not keys then
		return
	end
	local land = if typeof(event.land) == "number" then event.land else nil
	local point = if typeof(event.point) == "Vector3" then Units.asVector(event.point) else nil
	local normal = if typeof(event.normal) == "Vector3" then Units.asVector(event.normal) else nil
	if event.entity ~= PlayerController.entityId then
		show(event.entity .. ":" .. event.id, keys, land, normal, event.at, false, event.entity)
		return
	end
	local key = keyOf(event.entity, event.id)
	if done[key] then
		return
	end
	local mine = shown[key]
	local ours = if mine and mine.land then BoltSim.at(mine.keys, mine.land) else nil
	if mine and ((ours == nil and point == nil) or (ours and point and vector.magnitude(ours - point) <= MOVE)) then
		return
	end
	-- Ours doesn't go where the server's does, or wasn't loosed here: the
	-- server's goes, on your clock.
	local start = if mine then mine.start else os.clock() - (Workspace:GetServerTimeNow() - event.at)
	show(key, keys, land, normal, start, true, event.entity)
end

local function onEvent(event: any)
	if typeof(event) == "table" and event.kind == "out" then
		for key, s in shown do
			forget(s)
			shown[key] = nil
		end
		return
	end
	if typeof(event) ~= "table" or event.ability ~= "shockbolt" or event.kind ~= "flight" then
		return
	end
	if typeof(event.entity) ~= "number" or typeof(event.id) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	onFlight(event)
end

-- A burst at `at`: a ball of light flashing out to its outer radius and
-- fading as it goes.
local function flash(at: vector)
	local p = Instance.new("Part")
	p.Name = "Burst"
	p.Shape = Enum.PartType.Ball
	plain(p)
	p.Material = Enum.Material.Neon
	p.Color = LIGHT
	p.Size = Vector3.one * 0.1
	p.CFrame = CFrame.new(Units.toStuds(at))
	p.Parent = holder()
	local l = Instance.new("PointLight")
	l.Color = GLOW
	l.Brightness = 4
	l.Range = 2 * SB.outer.value * Units.STUDS_PER_METRE
	l.Shadows = false
	l.Parent = p
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - start) / FLASH
		if k >= 1 or p.Parent == nil then
			conn:Disconnect()
			p:Destroy()
			return
		end
		p.Size = Vector3.one * math.max(2 * SB.outer.value * math.sqrt(k), 0.1) * Units.STUDS_PER_METRE
		p.Transparency = 0.35 + 0.65 * k
		l.Brightness = 4 * (1 - k)
	end)
end

-- One bolt, a frame on: `age` seconds since its loose. False once it's
-- gone: burst, or given up on.
local function frame(s: Shown, age: number): boolean
	local land = s.land
	local normal = s.normal
	local part = s.part
	if age < 0 then
		-- Others' before the frame on your screen reaches the loose.
		if part then
			part.Transparency = 1
		end
		return true
	end
	if land and normal and age >= land then
		if age - land < STALE then
			local point = ShockSim.eye(BoltSim.at(s.keys, land), normal)
			flash(point)
			play("shockburst", point, s.own, s.entity)
			bursts += 1
		end
		return false
	end
	if not land and age >= RC.airTime.value then
		-- It never lands: given up on.
		return false
	end
	if not s.heard then
		s.heard = true
		if age < STALE then
			play("boltflight", BoltSim.at(s.keys, age), s.own, s.entity, function(): vector?
				local now = (if s.own then os.clock() else RemoteEntities.renderTime()) - s.start
				local ends = s.land
				return BoltSim.at(s.keys, if ends then math.min(now, ends) else now)
			end)
		end
	end
	if part then
		if s.own and age < NEAR then
			part.Transparency = 1
		else
			local at = BoltSim.at(s.keys, age)
			local key = s.keys[1]
			for i = 2, #s.keys do
				if s.keys[i].age > age then
					break
				end
				key = s.keys[i]
			end
			local v = FireballSim.velocityAt(key, age)
			part.Transparency = 0
			if vector.magnitude(v) > 1e-6 then
				part.CFrame = CFrame.lookAt(Units.toStuds(at), Units.toStuds(at + vector.normalize(v)))
			else
				part.CFrame = CFrame.new(Units.toStuds(at))
			end
		end
	end
	return true
end

function ShockView.start()
	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()
		local count = 0
		for key, b in shown do
			local age = (if b.own then clock else render) - b.start
			if frame(b, age) then
				count += 1
			else
				forget(b)
				shown[key] = nil
				if b.own then
					done[key] = clock
				end
			end
		end
		for key, at in done do
			if clock - at > KEEP then
				done[key] = nil
			end
		end
		local f = holder()
		f:SetAttribute("Bolts", count)
		f:SetAttribute("Bursts", bursts)
	end)
end

return ShockView
