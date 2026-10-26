--!strict
-- Omen's Shrouded Step on the client (system 42). Ours, not the
-- reference's art: plain parts and adornments.
--   * Its targeter: with it in hand, a ring on the floor where fire would
--     take you, as your simulation will find it (StepSim.place), and a
--     shadow of you standing there, both seen through walls (Riot's Patch
--     1.0 gave him an indicator of where he's targeting when his view of
--     it is blocked). With nowhere to step, a red ring where your aim ends
--     (StepSim.ends), and no shadow. Once it's fired the ring stays where
--     it takes you until you're there. Where it is shows on the minimap
--     too (StepView.aimed; Patch 1.0: 'Omen can now see his teleport
--     location on the map')
--   * Its windup ("step"): for others, shadow swirling up round him as he's
--     drawn, as the frame on your screen reaches it; for you, shadow
--     closing in from the screen's edges
--   * His going ("vanish", from the server to everyone): for others, a puff
--     of shadow where he was, and his shadow standing on the floor he's
--     going to, darkening, until he's there; for you, the screen dark until
--     you're there, and clearing as you are
--   * His arrival ("arrive"): for others, shadow drawn in round him as he
--     forms there, and his shadow gone
-- Each is heard as AbilityEffects hears every cast. In Workspace's VFStep
-- the targeter is a `StepMark` part with its `Ring` and `Ghost`
-- adornments, others' windups `Swirl` parts, their going a `Puff`, the
-- floor they're going to a `Shadow` model, its `Entity` attribute whose it
-- is, and their arrival a `Form`. They go when the server says every
-- fire's out (a new round, "out").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local BarrierSim = require(Shared.Abilities.BarrierSim)
local MovementConfig = require(Shared.Movement.MovementConfig)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local StepSim = require(Shared.Abilities.StepSim)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local WeaponSim = require(Shared.Weapons.WeaponSim)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local Ui = require(script.Parent.Debug.Ui)

local StepView = {}

local SS = AbilityConfig.ShroudedStep
local DT = 1 / MovementConfig.TickRate.value
local S = Units.STUDS_PER_METRE
local SHADOW = Color3.fromRGB(26, 18, 40)
local WISP = Color3.fromRGB(70, 44, 110)
local MARKED = Color3.fromRGB(160, 120, 240) -- the targeter, as Dark Cover's mark
local REFUSED = Color3.fromRGB(230, 70, 70) -- with nowhere to step
local RING = 0.45 -- metres: the targeter ring's radius (ours)
local RING_IN = 0.36 -- and inside it
local LIFT = 0.03 -- metres the ring sits over the floor
local GHOST_CLEAR = 0.8 -- how clear the shadow of you is
local SWIRL = 0.55 -- metres: how far out the windup's shadow swirls (ours)
local WISPS = 6 -- wisps in a swirl
local TALL = 1.9 -- metres: how tall a swirl, a shadow or a form is
local PUFF = 0.45 -- seconds his going's puff takes (ours)
local FORM = 0.35 -- seconds his forming takes (ours)
local EDGE = 140 -- pixels: how far the windup's shadow closes in at the last
local CLEAR = 0.25 -- seconds your screen takes to clear as you're there (ours)
local STALE = 1 -- seconds: a step the screen is this far past isn't shown

-- Another's step on its way: whose, when (server time) its windup
-- started, and once the frame on your screen reaches it, its swirl.
type Winding = { entity: number, at: number, wisps: { Part }? }
-- Another's going: whose, when (server time), where from and to (metres),
-- and once reached, the shadow where they're going.
type Going = { entity: number, at: number, from: vector, to: vector, shadow: Model? }
-- Another's arrival, for the frame on your screen to reach.
type Arrival = { entity: number, at: number, position: vector }

local world = RobloxWorld.new()
local folder: Folder? = nil
local marker: { part: Part, ring: CylinderHandleAdornment, ghost: CylinderHandleAdornment }? = nil
local winding: { Winding } = {}
local going: { Going } = {}
local arrivals: { Arrival } = {}
-- Where your targeter shows you'd go this frame, if anywhere.
local aimedAt: vector? = nil
-- When (os.clock()) you were last there.
local arrived = -math.huge

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFStep"
	made.Parent = Workspace
	folder = made
	return made
end

local function part(parent: Instance, name: string, shape: Enum.PartType, colour: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Shape = shape
	p.Material = Enum.Material.SmoothPlastic
	p.Color = colour
	p.Transparency = 1
	p.Size = Vector3.one * 0.2
	p.Parent = parent
	return p
end

-- Runs `update` with how far through `duration` it is (0 to 1) each frame,
-- then removes `instance`.
local function animate(instance: Instance, duration: number, update: (number) -> ())
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - start) / duration
		if k >= 1 or instance.Parent == nil then
			conn:Disconnect()
			instance:Destroy()
			return
		end
		update(k)
	end)
end

-- A cylinder standing `tall` (metres) over `feet`, `across` wide: a
-- cylinder's axis is its X, so it's turned up.
local function stand(p: BasePart, feet: vector, across: number, tall: number)
	p.Size = Vector3.new(tall * S, across * S, across * S)
	p.CFrame = CFrame.new(Units.toStuds(feet + vector.create(0, tall / 2, 0))) * CFrame.Angles(0, 0, math.pi / 2)
end

-- The targeter: a part with a ring flat on the floor and a shadow of him
-- standing, both drawn over everything.
local function makeMarker()
	local p = part(holder(), "StepMark", Enum.PartType.Block, MARKED)
	p.Size = Vector3.one * 0.05
	local cfg = PlayerController.cfg
	local ring = Instance.new("CylinderHandleAdornment")
	ring.Name = "Ring"
	ring.Adornee = p
	ring.AlwaysOnTop = true
	ring.ZIndex = 1
	ring.Radius = RING * S
	ring.InnerRadius = RING_IN * S
	ring.Height = 0.02 * S
	-- Its axis is its Z: turned to stand up, so it lies flat.
	ring.CFrame = CFrame.new(0, LIFT * S, 0) * CFrame.Angles(math.pi / 2, 0, 0)
	ring.Transparency = 0.15
	ring.Visible = false
	ring.Parent = p
	local ghost = Instance.new("CylinderHandleAdornment")
	ghost.Name = "Ghost"
	ghost.Adornee = p
	ghost.AlwaysOnTop = true
	ghost.ZIndex = 0
	ghost.Radius = cfg.halfWidth * S
	ghost.Height = cfg.standHeight * S
	ghost.CFrame = CFrame.new(0, cfg.standHeight / 2 * S, 0) * CFrame.Angles(math.pi / 2, 0, 0)
	ghost.Color3 = MARKED
	ghost.Transparency = GHOST_CLEAR
	ghost.Visible = false
	ghost.Parent = p
	local m = { part = p, ring = ring, ghost = ghost }
	marker = m
	return m
end

-- With it in hand, where fire would take you; fired, where it takes you
-- until you're there.
local function aimFrame(render: number)
	local had = marker
	local m = if had and had.part.Parent then had else makeMarker()
	local s = PlayerController.sim
	local w = if s then s.weapons else nil
	local kit = if s then s.abilities else nil
	local camera = Workspace.CurrentCamera
	aimedAt = nil
	local at: vector? = nil
	local placed = false
	if s and kit and PlayerController.alive and AbilitySim.stepping(kit, s.movement.tick * DT) then
		at, placed = kit.stepTo, true
	elseif
		s
		and w
		and kit
		and camera
		and PlayerController.alive
		and w.equipped == WeaponSim.ULT
		and w.loadout[WeaponSim.ULT] == "stepmark"
		and kit.holding ~= 0
	then
		local walls = PlayerController.barriers
		local judged = if walls then walls(render) else nil
		local through = if judged then BarrierSim.world(world, judged.walls, judged.time) else world
		local eye = Units.toMetres(camera.CFrame.Position)
		local aim = Units.asVector(camera.CFrame.LookVector)
		local to = StepSim.place(through, eye, aim, PlayerController.cfg)
		at, placed = to or StepSim.ends(through, eye, aim), to ~= nil
	end
	if not at then
		m.ring.Visible = false
		m.ghost.Visible = false
		return
	end
	if placed then
		aimedAt = at
	end
	m.part.CFrame = CFrame.new(Units.toStuds(at))
	m.ring.Color3 = if placed then MARKED else REFUSED
	m.ring.Visible = true
	m.ghost.Visible = placed
end

-- Another's windup, swirling round them where they're drawn at `render`:
-- false once it's over.
local function swirl(wd: Winding, render: number): boolean
	local k = (render - wd.at) / SS.windup.value
	local pose = if RemoteEntities.isPresent(wd.entity) then RemoteEntities.sample(wd.entity, render) else nil
	if k >= 1 or not pose or not pose.alive then
		if wd.wisps then
			for _, p in wd.wisps do
				p:Destroy()
			end
			wd.wisps = nil
		end
		return k < 1 and render - wd.at < STALE
	end
	local wisps: { Part } = wd.wisps or {}
	if not wd.wisps then
		for i = 1, WISPS do
			wisps[i] = part(holder(), "Swirl", Enum.PartType.Ball, if i % 2 == 0 then WISP else SHADOW)
		end
		wd.wisps = wisps
	end
	-- Rising and drawing in round him, turning faster as it goes.
	local turn = 2 * math.pi * (k + k * k)
	for i, p in wisps do
		local angle = turn + i / WISPS * 2 * math.pi
		local out = SWIRL * (1 - 0.4 * k)
		local high = TALL * ((i / WISPS) * 0.6 + 0.4 * k)
		local at = pose.position + vector.create(math.cos(angle) * out, high, math.sin(angle) * out)
		p.Size = Vector3.one * (0.18 + 0.22 * k) * S
		p.CFrame = CFrame.new(Units.toStuds(at))
		p.Transparency = 0.6 - 0.35 * k
	end
	return true
end

-- A puff of shadow where someone went from `feet` (metres): a dark ball
-- spreading from the chest as it fades.
local function puff(feet: vector)
	local ball = part(holder(), "Puff", Enum.PartType.Ball, SHADOW)
	local centre = feet + vector.create(0, TALL / 2, 0)
	ball.CFrame = CFrame.new(Units.toStuds(centre))
	animate(ball, PUFF, function(k)
		ball.Size = Vector3.one * (0.8 + 1.4 * math.sqrt(k)) * S
		ball.Transparency = 0.25 + 0.75 * k
	end)
end

-- `entity`'s shadow standing at `feet` (metres): a column of shadow with a
-- darker core.
local function newShadow(feet: vector, entity: number): Model
	local model = Instance.new("Model")
	model.Name = "Shadow"
	model:SetAttribute("Entity", entity)
	part(model, "Haze", Enum.PartType.Cylinder, WISP)
	part(model, "Core", Enum.PartType.Cylinder, SHADOW)
	model.Parent = holder()
	return model
end

-- A shadow `k` of the way to its arrival: denser as it comes.
local function shade(model: Model, feet: vector, k: number)
	local haze = model:FindFirstChild("Haze") :: Part?
	local core = model:FindFirstChild("Core") :: Part?
	if haze then
		stand(haze, feet, 0.9 - 0.2 * k, TALL)
		haze.Transparency = 0.85 - 0.25 * k
	end
	if core then
		stand(core, feet, 0.35 + 0.15 * k, TALL * (0.6 + 0.4 * k))
		core.Transparency = 0.7 - 0.4 * k
	end
end

-- Shadow drawn in round someone forming at `feet` (metres).
local function form(feet: vector)
	local p = part(holder(), "Form", Enum.PartType.Cylinder, SHADOW)
	animate(p, FORM, function(k)
		stand(p, feet, 1.2 * (1 - k) + 0.2, TALL)
		p.Transparency = 0.35 + 0.65 * k
	end)
end

local function forgetGoing(g: Going)
	if g.shadow then
		g.shadow:Destroy()
		g.shadow = nil
	end
end

local function clearAll()
	for _, wd in winding do
		local wisps = wd.wisps
		if wisps then
			for _, p in wisps do
				p:Destroy()
			end
		end
	end
	for _, g in going do
		forgetGoing(g)
	end
	table.clear(winding)
	table.clear(going)
	table.clear(arrivals)
end

local function onOwnCast(cast: AbilitySim.Cast)
	if cast.kind == "arrive" then
		arrived = os.clock()
	end
end

local function onEvent(event: any)
	if typeof(event) ~= "table" then
		return
	end
	if event.kind == "out" then
		clearAll()
		return
	end
	if event.ability ~= "shroudedstep" or typeof(event.entity) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	if event.entity == PlayerController.entityId or typeof(event.position) ~= "Vector3" then
		return -- yours is drawn from your kit
	end
	local feet = Units.toMetres(event.position)
	if event.kind == "step" then
		table.insert(winding, { entity = event.entity, at = event.at })
	elseif event.kind == "vanish" and typeof(event.to) == "Vector3" then
		table.insert(going, { entity = event.entity, at = event.at, from = feet, to = Units.toMetres(event.to) })
	elseif event.kind == "arrive" then
		table.insert(arrivals, { entity = event.entity, at = event.at, position = feet })
	end
end

-- Where your targeter shows you'd go this frame, or where it's taking you,
-- for the minimap: nil without.
function StepView.aimed(): vector?
	return aimedAt
end

function StepView.start()
	-- Your windup's shadow closing in from the screen's edges (a stroke
	-- round a frame set in from them as far, drawn outwards over them), and
	-- the screen dark while you're gone (under the HUD).
	local gui = Ui.screen("VFStep", 3, Enum.ScreenInsets.None)
	local edge = Ui.frame(gui, {
		Name = "Edge",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = SHADOW
	stroke.Thickness = 0
	stroke.Transparency = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = edge
	local screen = Ui.frame(gui, {
		Name = "Dark",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	})
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, SHADOW),
		ColorSequenceKeypoint.new(0.5, WISP),
		ColorSequenceKeypoint.new(1, SHADOW),
	})
	gradient.Rotation = 90
	gradient.Parent = screen

	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		aimFrame(render)

		-- Others' windups, goings and arrivals, as the frame on your screen
		-- reaches them.
		local i = 1
		while i <= #winding do
			local wd = winding[i]
			if render < wd.at or swirl(wd, render) then
				i += 1
			else
				table.remove(winding, i)
			end
		end
		i = 1
		while i <= #going do
			local g = going[i]
			local k = (render - g.at) / SS.away.value
			if render < g.at then
				i += 1
				continue
			end
			if k >= 1 or render - g.at >= STALE then
				forgetGoing(g)
				table.remove(going, i)
				continue
			end
			if not g.shadow then
				puff(g.from)
				g.shadow = newShadow(g.to, g.entity)
			end
			local shadow = g.shadow
			if shadow then
				shade(shadow, g.to, k)
			end
			i += 1
		end
		i = 1
		while i <= #arrivals do
			local a = arrivals[i]
			if render >= a.at then
				table.remove(arrivals, i)
				for j = #going, 1, -1 do
					if going[j].entity == a.entity then
						forgetGoing(going[j])
						table.remove(going, j)
					end
				end
				if render - a.at < STALE then
					form(a.position)
				end
			else
				i += 1
			end
		end

		-- Yours, from your kit: the windup's shadow at the edges, and the
		-- screen while you're gone and as you're there.
		local s = PlayerController.sim
		local kit = if s then s.abilities else nil
		local t = if s then s.movement.tick * DT else 0
		local closing = 0
		local clear = math.clamp((os.clock() - arrived) / CLEAR, 0, 1)
		if kit and AbilitySim.shrouding(kit, t) then
			closing = 1 - (kit.stepAt - t) / SS.windup.value
		elseif kit and AbilitySim.shrouded(kit, t) then
			clear = 0
		end
		local inset = EDGE * closing
		edge.Size = UDim2.new(1, -2 * inset, 1, -2 * inset)
		edge.Position = UDim2.fromOffset(inset, inset)
		stroke.Thickness = inset
		stroke.Transparency = if closing > 0 then 0.55 - 0.3 * closing else 1
		screen.Visible = clear < 1
		screen.BackgroundTransparency = clear
	end)
end

return StepView
