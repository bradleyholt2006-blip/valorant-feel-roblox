--!strict
-- Sage's Slow Orb on the client (system 37): orbs in the air, and their
-- fields of ice.
--   * Your own fly here at once, as you throw them (PlayerController's
--     castListeners), through SlowSim as the server flies them, and burst
--     where the server's will. When the server says where one goes (the
--     Ability remote's "flight"), it goes there instead if ours doesn't
--   * Others' come from the server ("flight"): its keys, when it bursts, the
--     floor its field lies on and how far that reaches, drawn here as the
--     frame on your screen reaches the throw
--   * every field the server tells of, yours too, is kept on the server's
--     clock for your own prediction (PlayerController.fields), which slows
--     you in it as the server's simulation does
--   * an orb is a pale ball of light. Its burst is a flash with its sound
--     (GameSounds), and its field a floor of ice spreading as the server's
--     does, no further than its walls (FireSim.edge), shards of ice standing
--     up out of it as it reaches them, gone in a moment as it ends. While
--     you're slowed the edge of your screen frosts over, and a run or a
--     jump through a field, yours or another's, crunches (GameSounds.iced)
-- In Workspace's VFSlows each orb in the air is an `Orb` ball, and each
-- field an `Ice` model while it lasts. They all go when the server says
-- every fire's out (a new round, "out").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilitySim = require(Shared.Abilities.AbilitySim)
local FireballSim = require(Shared.Abilities.FireballSim)
local FireSim = require(Shared.Abilities.FireSim)
local SlowSim = require(Shared.Abilities.SlowSim)
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
local Ui = require(script.Parent.Debug.Ui)

local SlowView = {}

local DT = 1 / MovementConfig.TickRate.value
local ICE = Color3.fromRGB(165, 228, 242)
local GLOW = Color3.fromRGB(110, 210, 235)
local BALL = 0.25 -- metres across (ours)
local NEAR = 0.06 -- seconds your own is hidden for, so it doesn't fill the view leaving the eye
local MOVE = 0.25 -- metres: the server's field this far from ours moves our orb
local FLASH = 0.25 -- seconds a burst's flash lasts (ours)
local STALE = 1 -- seconds: a burst the screen is this far past isn't shown
local KEEP = 8 -- seconds your thrown orbs are remembered, so the server's word on one doesn't throw it again
-- Seconds a field the server told of is kept for your prediction after it
-- ends, so moves replayed after a correction still find it (ours: past
-- SlowSim.LAG).
local AFTER = 2
local FADE = 0.3 -- seconds a field fades over as it ends (ours: the wiki has it 'rapidly dissipates')
local LIFT = 0.03 -- metres its floor of ice sits over the floor
local CLEAR = 0.45 -- how clear its floor of ice is
local SHARDS = 12 -- shards of ice standing up out of a field (ours)
-- Seconds an orb that never bursts flies before it's given up on.
local LONGEST = FireballSim.longest(SlowSim.FLIGHT)

-- An orb thrown, and its field: its keys, when it bursts (nil for never)
-- and its field, from SlowSim, on the clock it was thrown on: os.clock()
-- for yours and the render clock for others'.
type Shown = {
	keys: { FireballSim.Key },
	land: number?,
	field: SlowSim.Field?,
	start: number,
	own: boolean,
	entity: number,
	ball: Part?,
	ice: Model?,
	wedges: { WedgePart },
	shards: { { part: Part, distance: number } },
}

local world = RobloxWorld.new()
local shown: { [string]: Shown } = {}
local done: { [string]: number } = {} -- your orbs burst and gone, by key, at os.clock()
-- The fields the server's told of, on its clock, by thrower and throw.
local fields: { SlowSim.Field } = {}
local known: { [string]: boolean } = {}
local folder: Folder? = nil

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFSlows"
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

local function ball(name: string, across: number, brightness: number, range: number): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	plain(p)
	p.Material = Enum.Material.Neon
	p.Color = ICE
	p.Transparency = 1
	p.Size = Vector3.one * across * Units.STUDS_PER_METRE
	local l = Instance.new("PointLight")
	l.Color = GLOW
	l.Brightness = brightness
	l.Range = range * Units.STUDS_PER_METRE
	l.Shadows = false
	l.Parent = p
	p.Parent = holder()
	return p
end

local function forget(s: Shown)
	if s.ball then
		s.ball:Destroy()
	end
	if s.ice then
		s.ice:Destroy()
	end
end

-- An orb's field from where it burst, on the clock it was thrown on.
local function fieldFor(entity: number, id: number, start: number, land: number?, centre: vector?, reaches: { number }?): SlowSim.Field?
	if not land or not centre or not reaches then
		return nil
	end
	return SlowSim.field(entity, id, centre, start + land, reaches)
end

local function show(
	key: string,
	keys: { FireballSim.Key },
	land: number?,
	field: SlowSim.Field?,
	start: number,
	own: boolean,
	entity: number
)
	local had = shown[key]
	if had then
		forget(had)
	end
	shown[key] = {
		keys = keys,
		land = land,
		field = field,
		start = start,
		own = own,
		entity = entity,
		ball = ball("Orb", BALL, 2, 5),
		ice = nil,
		wedges = {},
		shards = {},
	}
end

-- An orb's burst at `at` (metres): its flash, swelling and fading, and its
-- sound, yours or another's.
local function burst(at: vector, own: boolean, entity: number)
	if own then
		GameSounds.playWorld(SoundConfig.Abilities.ice, at, "you")
	else
		GameSounds.playCast("ice", at, entity, true)
	end
	local p = ball("Burst", BALL, 5, 8)
	p.CFrame = CFrame.new(Units.toStuds(at))
	p.Transparency = 0
	local glow = p:FindFirstChildOfClass("PointLight") :: PointLight
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - start) / FLASH
		if k >= 1 or p.Parent == nil then
			conn:Disconnect()
			p:Destroy()
			return
		end
		p.Size = Vector3.one * (BALL + 3 * math.sqrt(k)) * Units.STUDS_PER_METRE
		p.Transparency = 0.3 + 0.7 * k
		glow.Brightness = 5 * (1 - k)
	end)
end

local function wedge(parent: Instance): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = "Floor"
	plain(w)
	w.Material = Enum.Material.Ice
	w.Color = ICE
	w.Transparency = 1
	w.Parent = parent
	return w
end

-- A field's model: its floor of ice (two wedges a sector) and shards of ice
-- scattered over it, the same for everyone (its thrower and throw pick
-- where), each standing once the field's spread to it.
local function build(s: Shown, field: SlowSim.Field)
	local model = Instance.new("Model")
	model.Name = "Ice"
	for _ = 1, 2 * FireSim.SECTORS do
		table.insert(s.wedges, wedge(model))
	end
	local random = Random.new(field.owner % 2 ^ 31 + field.id)
	for _ = 1, SHARDS do
		local i = random:NextInteger(1, FireSim.SECTORS)
		local out = FireSim.direction(i) * (field.reaches[i] * random:NextNumber(0.1, 0.85))
		local tall = random:NextNumber(0.15, 0.4)
		local part = Instance.new("Part")
		part.Name = "Shard"
		plain(part)
		part.Material = Enum.Material.Ice
		part.Color = ICE
		part.Transparency = 1
		part.Size = Vector3.new(0.08, tall, 0.08) * Units.STUDS_PER_METRE
		local tilt = CFrame.Angles(random:NextNumber(-0.4, 0.4), random:NextNumber(0, 2 * math.pi), random:NextNumber(-0.4, 0.4))
		part.CFrame = CFrame.new(Units.toStuds(field.centre + out + vector.create(0, tall * 0.4, 0))) * tilt
		part.Parent = model
		table.insert(s.shards, { part = part, distance = vector.magnitude(out) })
	end
	model.Parent = holder()
	s.ice = model
end

-- A field's floor of ice as far as it has spread at `t` (its clock), the
-- shards it has reached standing, all of it fading over its last moment.
local function spread(s: Shown, field: SlowSim.Field, t: number)
	local edge = FireSim.edge(field, t)
	local lift = vector.create(0, LIFT, 0)
	local centre = Units.toStuds(field.centre + lift)
	local fade = math.clamp((FireSim.ends(field) - t) / FADE, 0, 1)
	local clear = 1 - (1 - CLEAR) * fade
	for i = 1, FireSim.SECTORS do
		local j = i % FireSim.SECTORS + 1
		FireView.triangle(centre, Units.toStuds(edge[i] + lift), Units.toStuds(edge[j] + lift), s.wedges[2 * i - 1], s.wedges[2 * i], clear)
	end
	local r = FireSim.radiusAt(field, t)
	for _, shard in s.shards do
		shard.part.Transparency = if r >= shard.distance then 1 - 0.8 * fade else 1
	end
end

local function onOwnCast(cast: AbilitySim.Cast)
	if cast.kind ~= "slow" then
		return
	end
	local entity = PlayerController.entityId
	local orb = SlowSim.throw(entity, cast.tick, cast.origin, cast.direction)
	local land = FireballSim.fly(orb, DT, world)
	local start = os.clock()
	local centre = if land then SlowSim.floorUnder(orb.position) else nil
	local reaches = if centre then SlowSim.reaches(centre, world) else nil
	show("own:" .. cast.tick, orb.keys, land, fieldFor(entity, cast.tick, start, land, centre, reaches), start, true, entity)
end

-- A field the server told of, kept for your prediction.
local function keep(entity: number, id: number, at: number, land: number?, centre: vector?, reaches: { number }?)
	local key = entity .. ":" .. id
	local field = fieldFor(entity, id, at, land, centre, reaches)
	if field and not known[key] then
		known[key] = true
		table.insert(fields, field)
	end
end

local function onEvent(event: any)
	if typeof(event) == "table" and event.kind == "out" then
		for key, s in shown do
			forget(s)
			shown[key] = nil
		end
		table.clear(fields)
		table.clear(known)
		return
	end
	if typeof(event) ~= "table" or event.ability ~= "sloworb" or event.kind ~= "flight" then
		return
	end
	if typeof(event.entity) ~= "number" or typeof(event.id) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	local keys = FireView.keysOf(event.keys)
	if not keys then
		return
	end
	local land = if typeof(event.land) == "number" then event.land else nil
	local centre = if typeof(event.point) == "Vector3" then Units.asVector(event.point) else nil
	local reaches = FireView.reachesOf(event.reaches)
	keep(event.entity, event.id, event.at, land, centre, reaches)
	if event.entity ~= PlayerController.entityId then
		show(
			event.entity .. ":" .. event.id,
			keys,
			land,
			fieldFor(event.entity, event.id, event.at, land, centre, reaches),
			event.at,
			false,
			event.entity
		)
		return
	end
	local key = "own:" .. event.id
	local mine = shown[key]
	if done[key] then
		return
	end
	local ours = if mine then mine.field else nil
	if mine and ((ours == nil and centre == nil) or (ours and centre and vector.magnitude(ours.centre - centre) <= MOVE)) then
		return
	end
	-- Ours doesn't go where the server's does, or wasn't thrown here: the
	-- server's goes, on your clock.
	local start = if mine then mine.start else os.clock() - (Workspace:GetServerTimeNow() - event.at)
	show(key, keys, land, fieldFor(event.entity, event.id, start, land, centre, reaches), start, true, event.entity)
end

-- One orb or field, a frame on: `age` seconds since its throw.
local function frame(s: Shown, age: number): boolean
	local land = s.land
	local field = s.field
	if not land or not field then
		-- It never bursts: in the air until it's given up on.
		if age >= LONGEST then
			return false
		end
	elseif age >= land then
		local b = s.ball
		if b then
			b:Destroy()
			s.ball = nil
			if age - land < STALE then
				burst(FireballSim.at(s.keys, land), s.own, s.entity)
			end
		end
		local t = s.start + age
		if not FireSim.burning(field, t) then
			return false
		end
		if not s.ice then
			build(s, field)
		end
		spread(s, field, t)
		return true
	end
	local b = s.ball
	if b then
		if age < (if s.own then NEAR else 0) then
			b.Transparency = 1
		else
			b.Transparency = 0
			b.CFrame = CFrame.new(Units.toStuds(FireballSim.at(s.keys, age)))
		end
	end
	return true
end

-- The fields lying, for the minimap: each one's centre, how far it has
-- spread, and its thrower.
function SlowView.standing(): { { centre: vector, radius: number, entity: number } }
	local render = RemoteEntities.renderTime()
	local clock = os.clock()
	local out = {}
	for _, s in shown do
		local field = s.field
		local t = if s.own then clock else render
		if field and FireSim.burning(field, t) then
			table.insert(out, { centre = field.centre, radius = FireSim.radiusAt(field, t), entity = s.entity })
		end
	end
	return out
end

-- Whether feet at `feet` (metres) stand in a field as your screen shows it
-- now.
function SlowView.iced(feet: vector): boolean
	return SlowSim.slowed(fields, feet, RemoteEntities.renderTime(), PlayerController.cfg.halfWidth)
end

function SlowView.start()
	-- Slowed, the edge of the screen frosts over: a stroke round a frame set
	-- in from its edges, drawn out over them, as the dash's flash is
	-- (AbilityEffects).
	local gui = Ui.screen("VFSlowFx", 14, Enum.ScreenInsets.None)
	local edge = Ui.frame(gui, {
		Size = UDim2.new(1, -40, 1, -40),
		Position = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = ICE
	stroke.Thickness = 40
	stroke.Transparency = 1
	stroke.Parent = edge

	PlayerController.fields = function(): { SlowSim.Field }
		return fields
	end
	GameSounds.iced = SlowView.iced
	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()
		for key, s in shown do
			local age = (if s.own then clock else render) - s.start
			if not frame(s, age) then
				forget(s)
				shown[key] = nil
				if s.own then
					done[key] = clock
				end
			end
		end
		for key, at in done do
			if clock - at > KEEP then
				done[key] = nil
			end
		end
		for i = #fields, 1, -1 do
			local field = fields[i]
			if render > FireSim.ends(field) + AFTER then
				table.remove(fields, i)
				known[field.owner .. ":" .. field.id] = nil
			end
		end
		local s = PlayerController.sim
		local slowed = PlayerController.alive and s ~= nil and s.movement.slowed
		stroke.Transparency = if slowed then 0.55 + 0.1 * math.sin(clock * 4) else 1
	end)
end

return SlowView
