--!strict
-- Sova's Recon Bolt on the client (system 44): its bow's draw, its bolts in
-- the air and stuck, their pulses, and the enemies they reveal.
--   * your bow in hand shows its draw under the crosshair, a bar for each
--     third of a second it's been drawn, three at most, and under them its
--     bounces, a pip lit for each added; the draw starting creaks. The
--     Shock Bolt's bow (system 45) shows its draw the same way; ShockView
--     draws its bolts
--   * your own bolts fly here at once, as you loose them (PlayerController's
--     castListeners), through BoltSim as the server flies them, and stick
--     where the server's will. When the server says where one goes (the
--     Ability remote's "flight"), it goes there instead if ours doesn't
--   * others' come from the server ("flight"), drawn as the frame on your
--     screen reaches the loose
--   * a bolt is a thin shaft of light along its way, whistling as it flies.
--     Stuck, it stands out of the surface, brightening through its windup,
--     until it's gone or the server says it broke ("break")
--   * each pulse the server tells of ("pulse") is a shell of light sweeping
--     out to its radius from where the bolt looks from, with its sound, as
--     the frame on your screen reaches it; and to its owner's side, whom it
--     revealed: each one's silhouette, their body's boxes lit in the enemy
--     colour through walls (a Highlight), where the snapshots have them or
--     else where the server said they stood, for the reveal's time
-- The shafts stuck are in the level your shots are traced through
-- (ClientShots.bolts), as the server's are in its own. In Workspace's
-- VFRecon each bolt is a `Bolt` part, each pulse a `Pulse` ball and each
-- silhouette a `Reveal_<id>` model; they all go when the server says every
-- fire's out (a new round, "out"). The `VFRecon` gui's attributes say
-- whether the bow's in hand (`Bow`), the bars it's drawn (`Bars`), its
-- bounces (`Bounces`), the bolts drawn (`Bolts`) and the silhouettes shown
-- (`Revealed`), which scripted checks read.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local BoltSim = require(Shared.Abilities.BoltSim)
local FireballSim = require(Shared.Abilities.FireballSim)
local Hitboxes = require(Shared.Combat.Hitboxes)
local Penetration = require(Shared.Combat.Penetration)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local SoundConfig = require(Shared.Audio.SoundConfig)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local FireView = require(script.Parent.FireView)
local Visuals = require(script.Parent.Visuals)
local ClientShots = require(script.Parent.Combat.ClientShots)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local ReconView = {}

local RC = AbilityConfig.ReconBolt
local DT = 1 / MovementConfig.TickRate.value
local LIGHT = Color3.fromRGB(110, 200, 255)
local GLOW = Color3.fromRGB(70, 160, 255)
local DIM = Color3.fromRGB(70, 72, 80)
local SHAFT = 0.7 -- metres long, drawn (ours)
local THICK = 0.05 -- metres across
local NEAR = 0.06 -- seconds your own is hidden for, so it doesn't fill the view leaving the eye
local MOVE = 0.25 -- metres: the server's bolt stuck this far from ours moves ours
local SWEEP = 0.45 -- seconds a pulse takes to sweep out to its radius (ours)
local STALE = 1 -- seconds: a pulse or a break the screen is this far past isn't shown
local KEEP = 8 -- seconds your loosed bolts are remembered, so the server's word on one doesn't loose it again
-- Seconds a bolt the server told of is kept for your shots after it's
-- gone, as the server keeps its own (ours: past SlowSim.LAG).
local AFTER = 2
local BAR_W, BAR_H, BAR_GAP = 18, 4, 3 -- pixels
local PIP = 6
local BELOW = 30 -- pixels under the crosshair

-- A bolt loosed: its keys, when it stuck (nil for never) and the way the
-- surface there faces, on the clock it was loosed on: os.clock() for
-- yours and the render clock for others'.
type Shown = {
	keys: { FireballSim.Key },
	land: number?,
	normal: vector?,
	start: number,
	own: boolean,
	entity: number,
	id: number,
	part: Part?,
	heard: boolean,
	stuckHeard: boolean,
}

-- A pulse or a break the server told of, until the frame on your screen
-- reaches it.
type Due = {
	kind: string,
	at: number,
	point: vector,
	entity: number,
	id: number,
	ids: { number },
	poses: { [number]: Hitboxes.Pose },
}

-- A silhouette shown: until when (the render clock), where the server
-- said they stood, and its model.
type Reveal = { untilAt: number, pose: Hitboxes.Pose, model: Model, parts: { [string]: BasePart } }

local world = RobloxWorld.new()
local shown: { [string]: Shown } = {}
local done: { [string]: number } = {} -- your bolts gone, by key, at os.clock()
-- The bolts the server's told of, stuck, on its clock, by owner and loose.
local stuckBolts: { BoltSim.Stuck } = {}
local known: { [string]: BoltSim.Stuck } = {}
local due: { Due } = {}
local reveals: { [number]: Reveal } = {}
local folder: Folder? = nil
local drawing = false

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFRecon"
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
	l.Brightness = 1
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

local function show(
	key: string,
	keys: { FireballSim.Key },
	land: number?,
	normal: vector?,
	start: number,
	own: boolean,
	entity: number,
	id: number
)
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
		id = id,
		part = shaft(),
		heard = if had then had.heard else false,
		stuckHeard = if had then had.stuckHeard else false,
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
	if cast.kind ~= "bolt" or cast.ability ~= "reconbolt" then
		return
	end
	local entity = PlayerController.entityId
	local bolt = BoltSim.shoot(entity, cast.tick, cast.origin, cast.direction, cast.bars or 0, cast.bounces or 0)
	local land = BoltSim.fly(bolt, DT, world)
	show(keyOf(entity, cast.tick), bolt.keys, land, bolt.normal, os.clock(), true, entity, cast.tick)
end

local function poseOf(sent: any): Hitboxes.Pose?
	if typeof(sent) ~= "table" or typeof(sent.position) ~= "Vector3" or typeof(sent.yaw) ~= "number" then
		return nil
	end
	return {
		position = Units.asVector(sent.position),
		yaw = sent.yaw,
		crouchAlpha = if typeof(sent.crouch) == "number" then sent.crouch else 0,
	}
end

local function onFlight(event: any)
	local keys = FireView.keysOf(event.keys)
	if not keys then
		return
	end
	local land = if typeof(event.land) == "number" then event.land else nil
	local point = if typeof(event.point) == "Vector3" then Units.asVector(event.point) else nil
	local normal = if typeof(event.normal) == "Vector3" then Units.asVector(event.normal) else nil
	local name = event.entity .. ":" .. event.id
	if land and point and normal and not known[name] then
		local stuck = BoltSim.stuck(event.entity, event.id, point, normal, event.at + land)
		known[name] = stuck
		table.insert(stuckBolts, stuck)
	end
	if event.entity ~= PlayerController.entityId then
		show(name, keys, land, normal, event.at, false, event.entity, event.id)
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
	show(key, keys, land, normal, start, true, event.entity, event.id)
end

local function onEvent(event: any)
	if typeof(event) == "table" and event.kind == "out" then
		for key, s in shown do
			forget(s)
			shown[key] = nil
		end
		table.clear(stuckBolts)
		table.clear(known)
		table.clear(due)
		for id, r in reveals do
			r.model:Destroy()
			reveals[id] = nil
		end
		return
	end
	if typeof(event) ~= "table" or event.ability ~= "reconbolt" then
		return
	end
	if typeof(event.entity) ~= "number" or typeof(event.id) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	if event.kind == "flight" then
		onFlight(event)
		return
	end
	if (event.kind ~= "pulse" and event.kind ~= "break") or typeof(event.point) ~= "Vector3" then
		return
	end
	if event.kind == "break" then
		local stuck = known[event.entity .. ":" .. event.id]
		if stuck then
			stuck.broken = event.at
		end
	end
	local ids: { number } = {}
	local poses: { [number]: Hitboxes.Pose } = {}
	if typeof(event.ids) == "table" and typeof(event.poses) == "table" then
		for _, sent in event.poses do
			local pose = poseOf(sent)
			if pose and typeof(sent.id) == "number" then
				poses[sent.id] = pose
			end
		end
		for _, id in event.ids do
			if typeof(id) == "number" and poses[id] then
				table.insert(ids, id)
			end
		end
	end
	local d: Due = {
		kind = event.kind,
		at = event.at,
		point = Units.asVector(event.point),
		entity = event.entity,
		id = event.id,
		ids = ids,
		poses = poses,
	}
	table.insert(due, d)
end

-- A pulse's shell of light, sweeping out to its radius from `from` and
-- fading as it goes.
local function sweep(from: vector)
	local p = Instance.new("Part")
	p.Name = "Pulse"
	p.Shape = Enum.PartType.Ball
	plain(p)
	p.Material = Enum.Material.ForceField
	p.Color = LIGHT
	p.Size = Vector3.one * 0.1
	p.CFrame = CFrame.new(Units.toStuds(from))
	p.Parent = holder()
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - start) / SWEEP
		if k >= 1 or p.Parent == nil then
			conn:Disconnect()
			p:Destroy()
			return
		end
		p.Size = Vector3.one * math.max(2 * RC.radius.value * math.sqrt(k), 0.1) * Units.STUDS_PER_METRE
		p.Transparency = 0.2 + 0.8 * k
	end)
end

-- A bolt breaking at `at`: a flash of light, gone in a moment.
local function shatter(at: vector)
	local p = Instance.new("Part")
	p.Name = "Break"
	p.Shape = Enum.PartType.Ball
	plain(p)
	p.Material = Enum.Material.Neon
	p.Color = LIGHT
	p.Size = Vector3.one * 0.3 * Units.STUDS_PER_METRE
	p.CFrame = CFrame.new(Units.toStuds(at))
	p.Parent = holder()
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - start) / 0.2
		if k >= 1 or p.Parent == nil then
			conn:Disconnect()
			p:Destroy()
			return
		end
		p.Transparency = k
	end)
end

local function enemyColour(): Color3
	local option = VisualConfig.EnemyColours[Visuals.enemyColour] or VisualConfig.EnemyColours[1]
	local rgb = option.colour.rgb
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- A silhouette's model: a part for each of the body's boxes, lit through
-- walls by a Highlight in the enemy colour.
local function silhouette(id: number): (Model, { [string]: BasePart })
	local model = Instance.new("Model")
	model.Name = "Reveal_" .. id
	model:SetAttribute("Entity", id)
	local parts: { [string]: BasePart } = {}
	for _, region in { "head", "body", "legs" } do
		local p = Instance.new("Part")
		p.Name = region
		plain(p)
		p.Material = Enum.Material.SmoothPlastic
		-- All but clear, as a Highlight draws nothing on a part that is.
		p.Transparency = 0.98
		p.Parent = model
		parts[region] = p
	end
	local h = Instance.new("Highlight")
	h.Name = "VFReveal"
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.FillColor = enemyColour()
	h.FillTransparency = 0.45
	h.OutlineColor = enemyColour()
	h.OutlineTransparency = 0
	h.Adornee = model
	h.Parent = model
	model.Parent = holder()
	return model, parts
end

-- A pulse or a break, as the frame on your screen reaches it.
local function happen(d: Due)
	local own = d.entity == PlayerController.entityId
	if d.kind == "break" then
		local key = keyOf(d.entity, d.id)
		local s = shown[key]
		if s then
			forget(s)
			shown[key] = nil
		end
		if own then
			done[key] = os.clock()
		end
		shatter(d.point)
		play("boltbreak", d.point, own, d.entity)
		return
	end
	sweep(d.point)
	play("pulse", d.point, own, d.entity)
	for _, id in d.ids do
		local r = reveals[id]
		if not r then
			local model, parts = silhouette(id)
			r = { untilAt = 0, pose = d.poses[id], model = model, parts = parts }
			reveals[id] = r
		end
		r.untilAt = math.max(r.untilAt, d.at + RC.reveal.value)
		r.pose = d.poses[id]
	end
end

-- One bolt, a frame on: `age` seconds since its loose. False once it's
-- gone.
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
	if not land or not normal then
		-- It never sticks: in the air until it's given up on.
		if age >= RC.airTime.value then
			return false
		end
	elseif age >= land then
		local over = land + RC.windup.value + RC.duration.value
		if age >= over then
			return false
		end
		local point = BoltSim.at(s.keys, land)
		if not s.stuckHeard then
			s.stuckHeard = true
			if age - land < STALE then
				play("boltstick", point, s.own, s.entity)
			end
		end
		if part then
			part.Transparency = 0
			local mid = point + normal * (SHAFT / 2 - 0.15)
			part.CFrame = CFrame.lookAt(Units.toStuds(mid), Units.toStuds(mid + normal))
			local wound = math.clamp((age - land) / RC.windup.value, 0, 1)
			local glow = part:FindFirstChildOfClass("PointLight")
			if glow then
				glow.Brightness = 1 + 3 * wound
			end
		end
		return true
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

-- Whether your bow's in hand, with either bolt, and the kit's time.
local function bowInHand(): (boolean, number)
	local s = PlayerController.sim
	if not s or not PlayerController.alive then
		return false, 0
	end
	local kit = s.abilities
	local def = if kit.holding ~= 0 then AbilitySim.def(kit, kit.holding) else nil
	local w = s.weapons
	return def ~= nil and AbilitySim.bowed(def.id) and w.equipped == WeaponSim.ULT and w.loadout[WeaponSim.ULT] ~= "", s.movement.tick * DT
end

function ReconView.start()
	-- The bow's draw under the crosshair: three bars, and two pips under
	-- them for its bounces.
	local gui = Ui.screen("VFRecon", 16, Enum.ScreenInsets.None)
	local width = 3 * BAR_W + 2 * BAR_GAP
	local panel = Ui.frame(gui, {
		Name = "Bow",
		Size = UDim2.fromOffset(width, BAR_H + PIP + 6),
		Position = UDim2.new(0.5, -width / 2, 0.5, BELOW),
		BackgroundTransparency = 1,
		Visible = false,
	})
	local bars: { Frame } = {}
	for i = 1, RC.bars.value do
		table.insert(
			bars,
			Ui.frame(panel, {
				Name = "Bar" .. i,
				Size = UDim2.fromOffset(BAR_W, BAR_H),
				Position = UDim2.fromOffset((i - 1) * (BAR_W + BAR_GAP), 0),
				BackgroundColor3 = DIM,
			})
		)
	end
	local pips: { Frame } = {}
	for i = 1, RC.bounces.value do
		local x = width / 2 + (i - 1.5) * (PIP + 6) - PIP / 2
		table.insert(
			pips,
			Ui.frame(panel, {
				Name = "Bounce" .. i,
				Size = UDim2.fromOffset(PIP, PIP),
				Position = UDim2.fromOffset(x, BAR_H + 5),
				Rotation = 45,
				BackgroundColor3 = DIM,
			})
		)
	end

	ClientShots.bolts = function(level: Penetration.Level, time: number): Penetration.Level
		return BoltSim.level(level, stuckBolts, time)
	end
	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()

		-- Your bow: its bars and bounces, and the creak as a draw starts.
		local inHand, t = bowInHand()
		local s = PlayerController.sim
		local kit = if s then s.abilities else nil
		local drawn = if inHand and kit then AbilitySim.bars(kit, t) else 0
		local bounces = if inHand and kit then kit.bounces else 0
		local nowDrawing = inHand and kit ~= nil and kit.drawFrom > 0
		if nowDrawing and not drawing and s then
			GameSounds.playCast("nock", s.movement.position)
		end
		drawing = nowDrawing
		panel.Visible = inHand
		for i, bar in bars do
			bar.BackgroundColor3 = if nowDrawing and i <= drawn then LIGHT else DIM
		end
		for i, pip in pips do
			pip.BackgroundColor3 = if i <= bounces then LIGHT else DIM
		end

		-- The bolts.
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
		for i = #stuckBolts, 1, -1 do
			local stuck = stuckBolts[i]
			if render > BoltSim.ends(stuck) + AFTER then
				table.remove(stuckBolts, i)
				known[stuck.owner .. ":" .. stuck.id] = nil
			end
		end

		-- Pulses and breaks, as the frame on your screen reaches them.
		local i = 1
		while i <= #due do
			local d = due[i]
			if render < d.at then
				i += 1
				continue
			end
			table.remove(due, i)
			if render - d.at < STALE then
				happen(d)
			end
		end

		-- The silhouettes: where the snapshots have them, or else where the
		-- server said they stood.
		local revealed = 0
		for id, r in reveals do
			if render >= r.untilAt then
				r.model:Destroy()
				reveals[id] = nil
				continue
			end
			local pose: Hitboxes.Pose = r.pose
			local seen = if RemoteEntities.isPresent(id) then RemoteEntities.sample(id, render) else nil
			if seen then
				pose = { position = seen.position, yaw = seen.yaw, crouchAlpha = seen.crouchAlpha }
			end
			RemoteEntities.placeBoxes(r.parts, pose)
			revealed += 1
		end

		gui:SetAttribute("Bow", inHand)
		gui:SetAttribute("Bars", drawn)
		gui:SetAttribute("Bounces", bounces)
		gui:SetAttribute("Bolts", count)
		gui:SetAttribute("Revealed", revealed)
	end)
end

return ReconView
