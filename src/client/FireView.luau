--!strict
-- Phoenix's Hot Hands on the client (system 31): fireballs in the air, and
-- their fire.
--   * Your own fly here at once, as you throw them (PlayerController's
--     castListeners), through FireballSim as the server flies them, and
--     burst where the server's will. When the server says where one goes
--     (the Ability remote's "flight"), it goes there instead if ours doesn't
--   * Others' come from the server ("flight"): its keys, when it bursts, the
--     floor its fire burns on and how far that reaches, drawn here as the
--     frame on your screen reaches the throw
--   * A fireball is a ball of flame with its light. Its burst is a flash
--     with its sound (GameSounds), and its fire a floor of flame spreading
--     as the server's does, no further than its walls (FireSim.edge), with
--     flames on it, its glow and its crackle until it's out. The burn and
--     the heal are the server's, and an orange glow round the screen's edge
--     says you're burning, in this fire or in Blaze's wall (system 32,
--     BlazeView)
-- In Workspace's VFFires each fireball in the air is a `Fireball` ball, and
-- each fire a `Fire` model while it burns. They all go when the server says
-- every fire's out (a new round, "out").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilitySim = require(Shared.Abilities.AbilitySim)
local BlazeSim = require(Shared.Abilities.BlazeSim)
local FireballSim = require(Shared.Abilities.FireballSim)
local FireSim = require(Shared.Abilities.FireSim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local SoundConfig = require(Shared.Audio.SoundConfig)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local FireView = {}

local DT = 1 / MovementConfig.TickRate.value
local FLAME = Color3.fromRGB(255, 120, 40)
local CORE = Color3.fromRGB(255, 200, 90)
local BALL = 0.3 -- metres across (ours)
local NEAR = 0.06 -- seconds your own is hidden for, so it doesn't fill the view leaving the eye
local MOVE = 0.25 -- metres: the server's fire this far from ours moves our fireball
local FLASH = 0.25 -- seconds a burst's flash lasts (ours)
local STALE = 1 -- seconds: a burst the screen is this far past isn't shown
local KEEP = 8 -- seconds your thrown fireballs are remembered, so the server's word on one doesn't throw it again
local CRACKLE = 0.5 -- seconds from one of a fire's crackles to the next (ours)
local LIFT = 0.03 -- metres its floor of flame sits over the floor
local THICK = 0.05 -- studs: how thick its floor of flame is
local GLOW = 0.35 -- seconds the screen's edge glows after each burn you take

-- A fireball thrown, and its fire: its keys, when it bursts (nil for
-- never) and its fire, from FireballSim and FireSim, on the clock it was
-- thrown on: os.clock() for yours and the render clock for others'.
type Shown = {
	keys: { FireballSim.Key },
	land: number?,
	pool: FireSim.Pool?,
	start: number,
	own: boolean,
	entity: number,
	ball: Part?,
	fire: Model?,
	wedges: { WedgePart },
	flames: { { part: Part, fire: Fire, distance: number } },
	crackled: number,
}

local world = RobloxWorld.new()
local shown: { [string]: Shown } = {}
local done: { [string]: number } = {} -- your fireballs burst and burnt out, by key, at os.clock()
local folder: Folder? = nil
local glowUntil = 0

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFFires"
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

local function light(parent: Instance, brightness: number, range: number): PointLight
	local l = Instance.new("PointLight")
	l.Color = FLAME
	l.Brightness = brightness
	l.Range = range * Units.STUDS_PER_METRE
	l.Shadows = false
	l.Parent = parent
	return l
end

local function ball(name: string, across: number, brightness: number, range: number): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	plain(p)
	p.Material = Enum.Material.Neon
	p.Color = FLAME
	p.Transparency = 1
	p.Size = Vector3.one * across * Units.STUDS_PER_METRE
	light(p, brightness, range)
	p.Parent = holder()
	return p
end

local function forget(s: Shown)
	if s.ball then
		s.ball:Destroy()
	end
	if s.fire then
		s.fire:Destroy()
	end
end

-- A fire's pool from where its fireball burst, on the clock it was thrown
-- on.
local function poolFor(entity: number, id: number, start: number, land: number?, centre: vector?, reaches: { number }?): FireSim.Pool?
	if not land or not centre or not reaches then
		return nil
	end
	return FireSim.new(entity, id, centre, start + land, reaches)
end

local function show(key: string, keys: { FireballSim.Key }, land: number?, pool: FireSim.Pool?, start: number, own: boolean, entity: number)
	local had = shown[key]
	if had then
		forget(had)
	end
	shown[key] = {
		keys = keys,
		land = land,
		pool = pool,
		start = start,
		own = own,
		entity = entity,
		ball = ball("Fireball", BALL, 2, 6),
		fire = nil,
		wedges = {},
		flames = {},
		crackled = -math.huge,
	}
end

-- A fireball's burst at `at` (metres): its flash, swelling and fading, and
-- its sound, yours or another's.
local function burst(at: vector, own: boolean, entity: number)
	if own then
		GameSounds.playWorld(SoundConfig.Abilities.fire, at, "you")
	else
		GameSounds.playCast("fire", at, entity, true)
	end
	local p = ball("Burst", BALL, 6, 10)
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
		p.Size = Vector3.one * (BALL + 2.5 * math.sqrt(k)) * Units.STUDS_PER_METRE
		p.Transparency = 0.2 + 0.8 * k
		glow.Brightness = 6 * (1 - k)
	end)
end

-- Two wedges drawn as the triangle a, b, c (studs), or hidden if it has no
-- area (a fire just burst, or a wall right against it).
local function triangle(a: Vector3, b: Vector3, c: Vector3, w1: WedgePart, w2: WedgePart)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	-- The longest side as bc: the corner opposite it, a, splits the
	-- triangle into two right ones, a wedge each.
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal = ac:Cross(ab)
	if normal.Magnitude < 1e-4 or bc.Magnitude < 1e-4 then
		w1.Transparency, w2.Transparency = 1, 1
		return
	end
	local right = normal.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	w1.Size = Vector3.new(THICK, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)
	w2.Size = Vector3.new(THICK, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)
	w1.Transparency, w2.Transparency = 0.35, 0.35
end

local function wedge(parent: Instance): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = "Floor"
	plain(w)
	w.Material = Enum.Material.Neon
	w.Color = FLAME
	w.Transparency = 1
	w.Parent = parent
	return w
end

-- A fire's model: its floor of flame (two wedges a sector), its glow, and
-- flames at its centre and out each sixth of the way round, each lit once
-- the fire's spread to it.
local function build(s: Shown, pool: FireSim.Pool)
	local model = Instance.new("Model")
	model.Name = "Fire"
	local centre = Units.toStuds(pool.centre + vector.create(0, LIFT, 0))
	for _ = 1, 2 * FireSim.SECTORS do
		table.insert(s.wedges, wedge(model))
	end
	local core = Instance.new("Part")
	core.Name = "Glow"
	plain(core)
	core.Transparency = 1
	core.Size = Vector3.one * 0.2
	core.CFrame = CFrame.new(centre + Vector3.new(0, 1, 0))
	light(core, 2, 7)
	core.Parent = model
	local places = { 0 }
	for i = 1, FireSim.SECTORS, FireSim.SECTORS // 6 do
		table.insert(places, i)
	end
	for _, i in places do
		local out = if i == 0 then vector.zero else FireSim.direction(i) * (pool.reaches[i] * 0.6)
		local part = Instance.new("Part")
		part.Name = "Flame"
		plain(part)
		part.Transparency = 1
		part.Size = Vector3.one * 0.2
		part.CFrame = CFrame.new(Units.toStuds(pool.centre + out))
		local fire = Instance.new("Fire")
		fire.Color = FLAME
		fire.SecondaryColor = CORE
		fire.Size = 5
		fire.Heat = 8
		fire.Enabled = false
		fire.Parent = part
		part.Parent = model
		table.insert(s.flames, { part = part, fire = fire, distance = vector.magnitude(out) })
	end
	model.Parent = holder()
	s.fire = model
end

-- A fire's floor of flame as far as it has spread at `t` (its clock), and
-- the flames it has reached lit.
local function spread(s: Shown, pool: FireSim.Pool, t: number)
	local edge = FireSim.edge(pool, t)
	local centre = Units.toStuds(pool.centre + vector.create(0, LIFT, 0))
	local lift = vector.create(0, LIFT, 0)
	for i = 1, FireSim.SECTORS do
		local j = i % FireSim.SECTORS + 1
		triangle(centre, Units.toStuds(edge[i] + lift), Units.toStuds(edge[j] + lift), s.wedges[2 * i - 1], s.wedges[2 * i])
	end
	local r = FireSim.radiusAt(pool, t)
	for _, flame in s.flames do
		flame.fire.Enabled = r >= flame.distance
	end
end

local function onOwnCast(cast: AbilitySim.Cast)
	if cast.kind ~= "fireball" then
		return
	end
	local entity = PlayerController.entityId
	local fireball = FireballSim.throw(entity, cast.tick, cast.origin, cast.direction, cast.lob == true)
	local land = FireballSim.fly(fireball, DT, world)
	local start = os.clock()
	local centre = if land then FireSim.floorUnder(fireball.position) else nil
	local reaches = if centre then FireSim.reaches(centre, world) else nil
	show("own:" .. cast.tick, fireball.keys, land, poolFor(entity, cast.tick, start, land, centre, reaches), start, true, entity)
end

-- A flight's keys as the server sends them, or nil if they aren't.
local function keysOf(sent: any): { FireballSim.Key }?
	if typeof(sent) ~= "table" or #sent == 0 then
		return nil
	end
	local keys: { FireballSim.Key } = {}
	for _, k in sent do
		if typeof(k) ~= "table" or typeof(k.age) ~= "number" or typeof(k.gravity) ~= "number" then
			return nil
		end
		if typeof(k.position) ~= "Vector3" or typeof(k.velocity) ~= "Vector3" then
			return nil
		end
		table.insert(
			keys,
			{ age = k.age, position = Units.asVector(k.position), velocity = Units.asVector(k.velocity), gravity = k.gravity }
		)
	end
	return keys
end

local function reachesOf(sent: any): { number }?
	if typeof(sent) ~= "table" or #sent ~= FireSim.SECTORS then
		return nil
	end
	local out: { number } = {}
	for _, reach in sent do
		if typeof(reach) ~= "number" then
			return nil
		end
		table.insert(out, reach)
	end
	return out
end

local function onEvent(event: any)
	if typeof(event) == "table" and event.kind == "out" then
		for key, s in shown do
			forget(s)
			shown[key] = nil
		end
		return
	end
	if typeof(event) ~= "table" or event.ability ~= "hothands" or event.kind ~= "flight" then
		return
	end
	if typeof(event.entity) ~= "number" or typeof(event.id) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	local keys = keysOf(event.keys)
	if not keys then
		return
	end
	local land = if typeof(event.land) == "number" then event.land else nil
	local centre = if typeof(event.point) == "Vector3" then Units.asVector(event.point) else nil
	local reaches = reachesOf(event.reaches)
	if event.entity ~= PlayerController.entityId then
		show(
			event.entity .. ":" .. event.id,
			keys,
			land,
			poolFor(event.entity, event.id, event.at, land, centre, reaches),
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
	local ours = if mine then mine.pool else nil
	if mine and ((ours == nil and centre == nil) or (ours and centre and vector.magnitude(ours.centre - centre) <= MOVE)) then
		return
	end
	-- Ours doesn't go where the server's does, or wasn't thrown here: the
	-- server's goes, on your clock.
	local start = if mine then mine.start else os.clock() - (Workspace:GetServerTimeNow() - event.at)
	show(key, keys, land, poolFor(event.entity, event.id, start, land, centre, reaches), start, true, event.entity)
end

-- One fireball or fire, a frame on: `age` seconds since its throw.
local function frame(s: Shown, age: number, clock: number): boolean
	local land = s.land
	local pool = s.pool
	if not land or not pool then
		-- It never bursts: in the air until it's given up on.
		if age >= FireballSim.LONGEST then
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
		if not FireSim.burning(pool, t) then
			return false
		end
		if not s.fire then
			build(s, pool)
		end
		spread(s, pool, t)
		if clock - s.crackled >= CRACKLE then
			s.crackled = clock
			local at = pool.centre + vector.create(0, 0.5, 0)
			if s.own then
				GameSounds.playWorld(SoundConfig.Abilities.burning, at, "you")
			else
				GameSounds.playCast("burning", at, s.entity, true)
			end
		end
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

function FireView.start()
	-- The burning glow: a stroke round a frame set in from the screen's
	-- edges, drawn out over them, as the dash's flash is (AbilityEffects).
	local gui = Ui.screen("VFFireFx", 14, Enum.ScreenInsets.None)
	local edge = Ui.frame(gui, {
		Size = UDim2.new(1, -40, 1, -40),
		Position = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = FLAME
	stroke.Thickness = 40
	stroke.Transparency = 1
	stroke.Parent = edge

	table.insert(PlayerController.castListeners, onOwnCast)
	local remotes = Remotes.get()
	NetSim.on(remotes.Ability, onEvent)
	NetSim.on(remotes.Combat, function(event: any)
		if typeof(event) ~= "table" or event.kind ~= "damage" or event.target ~= PlayerController.entityId then
			return
		end
		if event.weapon == FireSim.WEAPON or event.weapon == BlazeSim.WEAPON then
			glowUntil = os.clock() + GLOW
		end
	end)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()
		for key, s in shown do
			local age = (if s.own then clock else render) - s.start
			if not frame(s, age, clock) then
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
		local left = glowUntil - clock
		stroke.Transparency = if left > 0 then 1 - 0.6 * left / GLOW else 1
	end)
end

return FireView
