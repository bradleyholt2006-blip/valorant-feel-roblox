--!strict
-- Sage's Resurrection on the client (system 39).
--   * The fallen lie where the server has their bodies (ReviveSim.FOLDER):
--     their head, body and legs laid down in their colours, darkened, over
--     a disc glowing on the floor, in the ally colour for your side's and
--     the enemy colour for anyone else's, as the reference's discs (Player
--     Assist's guide has them blue for allies and red for enemies)
--   * With the orb in hand, the body under your crosshair that it would
--     bring back is marked: a green box round each block, and a + over it.
--     The same test as the server's (ReviveSim), on what you see: of your
--     side's fallen in Skirmish and the spike rounds, or on the course the
--     dummies', the level and clouds in the way, but not walls of fire
--   * A return under way: the body rises in a shell of crystal, its height
--     over its rise, as the frame on your screen reaches it, and bursts in
--     chips of crystal as they're back. Those who'd hear it hear its chime
--     as it starts and its crack as it bursts (the Ability remote's
--     "reviving" and "revived"). Yours isn't drawn round you: you rise with
--     it
-- The orb in hand is a weapon, which WeaponEffects draws.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReviveSim = require(Shared.Abilities.ReviveSim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local Minimap = require(Shared.Match.Minimap)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Sight = require(Shared.Combat.Sight)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local WeaponSim = require(Shared.Weapons.WeaponSim)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local CloudView = require(script.Parent.CloudView)
local Visuals = require(script.Parent.Visuals)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local ReviveView = {}

local GREEN = Color3.fromRGB(110, 235, 150)
local CRYSTAL = Color3.fromRGB(90, 230, 210)
-- RemoteEntities' colours for each block, darkened: the fallen lie dimmer
-- than the living stand.
local DUMMY_COLOURS: { [string]: Color3 } = {
	head = Color3.fromRGB(240, 200, 80),
	body = Color3.fromRGB(80, 140, 230),
	legs = Color3.fromRGB(50, 90, 170),
}
local PLAYER_COLOURS: { [string]: Color3 } = {
	head = Color3.fromRGB(240, 200, 80),
	body = Color3.fromRGB(215, 80, 65),
	legs = Color3.fromRGB(145, 45, 40),
}
local DARKEN = 0.55
local DISC = 1.6 -- metres across (ours)
local PAD = 0.06 -- metres each box is drawn out past the block it's round
local SHELL_PAD = 0.15 -- metres the crystal stands out from the body
local CHIPS = 10
local STALE = 1 -- seconds: a sound the screen is this far past isn't heard
-- How many barriers one line of sight goes through at the most.
local PASSES = 4

-- A body drawn: its blocks (by region), its disc and its shell, and its
-- return under way, if any: when it was cast (server time).
type Drawn = {
	body: ReviveSim.Body,
	model: Model,
	blocks: { [string]: Part },
	disc: Part,
	shell: Part,
	at: number?,
}
-- A sound waiting for the frame on your screen to reach it.
type Due = { kind: string, at: number, position: vector, entity: number? }

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = RobloxWorld.CHARACTER_GROUP
params.RespectCanCollide = true

local holder: Folder? = nil
-- By the server's body part; and the bodies gone from the server whose
-- return the screen hasn't reached the end of, still rising.
local drawn: { [BasePart]: Drawn } = {}
local rising: { Drawn } = {}
local due: { Due } = {}
local marked: { boxes: { BoxHandleAdornment }, widget: BillboardGui?, model: Model }? = nil

local function folder(): Folder
	local f = holder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFBodyViews"
	made.Parent = Workspace
	holder = made
	return made
end

local function newPart(parent: Instance, colour: Color3, material: Enum.Material, transparency: number): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Color = colour
	p.Material = material
	p.Transparency = transparency
	p.Parent = parent
	return p
end

local function playerOf(id: number): Player?
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == id then
			return player
		end
	end
	return nil
end

-- Whether the fallen `id` is you or on your side, as the kill feed colours
-- them.
local function ours(id: number): boolean
	local player = playerOf(id)
	local me = Players.LocalPlayer
	local mine = me:GetAttribute(ArenaConfig.SIDE)
	return player ~= nil and (player == me or (mine ~= nil and player:GetAttribute(ArenaConfig.SIDE) == mine))
end

-- Whether the orb in your hand would bring back the fallen `id`: your
-- side's in Skirmish and the spike rounds, the dummies on the course.
local function revivable(id: number): boolean
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return PlayerCodec.isDummy(id)
	end
	local mode = Workspace:GetAttribute(ArenaConfig.MODE)
	return (mode == "skirmish" or mode == "spike") and id ~= PlayerController.entityId and ours(id)
end

local function colour3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

-- The body the server's part says lies there.
local function bodyOf(part: BasePart): ReviveSim.Body?
	local id = tonumber(part.Name)
	if not id then
		return nil
	end
	local look = part.CFrame.LookVector
	return { id = id, feet = Units.toMetres(part.Position), yaw = math.atan2(-look.X, -look.Z) }
end

-- A body's blocks, disc and shell, `rise` metres up.
local function place(d: Drawn, rise: number)
	local up = vector.create(0, rise, 0)
	local rotation = CFrame.Angles(0, d.body.yaw, 0)
	for _, box in ReviveSim.blocks(d.body) do
		local p = d.blocks[box.region]
		if p then
			p.Size = Units.toStuds(box.half * 2)
			p.CFrame = CFrame.new(Units.toStuds(box.center + up)) * rotation
		end
	end
	local thick = 0.3 + 2 * SHELL_PAD
	d.shell.Size = Units.toStuds(vector.create(0.5 + 2 * SHELL_PAD, thick, ReviveSim.LENGTH + 2 * SHELL_PAD))
	d.shell.CFrame = CFrame.new(Units.toStuds(d.body.feet + up + vector.create(0, thick / 2, 0))) * rotation
	-- A cylinder's axis is its X: turned up, it lies flat.
	d.disc.Size = Units.toStuds(vector.create(0.03, DISC, DISC))
	d.disc.CFrame = CFrame.new(Units.toStuds(d.body.feet + vector.create(0, 0.02, 0))) * CFrame.Angles(0, 0, math.pi / 2)
end

-- A body as the screen has it at `render`: risen as far as its return
-- has it, in its shell once that's started, and not round you if it's
-- yours rising.
local function show(d: Drawn, render: number)
	local at = d.at
	local own = at ~= nil and d.body.id == PlayerController.entityId
	d.model.Parent = if own then nil else folder()
	place(d, if at then ReviveSim.risen(at, render) else 0)
	d.shell.Transparency = if at and render >= at then 0.45 else 1
end

local function draw(body: ReviveSim.Body): Drawn
	local model = Instance.new("Model")
	model.Name = "VFBody" .. body.id
	local colours: { [string]: Color3 } = if PlayerCodec.isDummy(body.id) then DUMMY_COLOURS else PLAYER_COLOURS
	local blocks: { [string]: Part } = {}
	for region, c in colours do
		local p = newPart(model, c:Lerp(Color3.new(0, 0, 0), 1 - DARKEN), Enum.Material.SmoothPlastic, 0)
		p.Name = region
		p.CastShadow = true
		blocks[region] = p
	end
	local side = if ours(body.id) then colour3(VisualConfig.allyColour) else colour3(VisualConfig.EnemyColours[Visuals.enemyColour].colour)
	local disc = newPart(model, side, Enum.Material.Neon, 0.6)
	disc.Shape = Enum.PartType.Cylinder
	local shell = newPart(model, CRYSTAL, Enum.Material.Glass, 1)
	model.Parent = folder()
	local d: Drawn = { body = body, model = model, blocks = blocks, disc = disc, shell = shell, at = nil }
	place(d, 0)
	return d
end

-- Chips of crystal flying out from `at` (metres) and fading.
local function chips(at: vector)
	local start = os.clock()
	local parts: { { part: Part, way: vector } } = {}
	for i = 1, CHIPS do
		local angle = i / CHIPS * 2 * math.pi
		local way = vector.normalize(vector.create(math.cos(angle), 0.4 + (i % 3) * 0.3, math.sin(angle)))
		local p = newPart(folder(), CRYSTAL, Enum.Material.Glass, 0.3)
		p.Size = Units.toStuds(vector.create(0.1, 0.1, 0.1))
		p.CFrame = CFrame.new(Units.toStuds(at))
		table.insert(parts, { part = p, way = way })
	end
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - start) / 0.5
		for _, c in parts do
			if k >= 1 then
				c.part:Destroy()
			else
				c.part.CFrame = CFrame.new(Units.toStuds(at + c.way * (1.2 * k))) * CFrame.Angles(k * 4, k * 3, 0)
				c.part.Transparency = 0.3 + 0.7 * k
			end
		end
		if k >= 1 then
			conn:Disconnect()
		end
	end)
end

-- Whether the level is in the way from `a` to `b` (metres), through the
-- spawns' barriers as the server's sight goes (FogServer).
local function blocked(a: vector, b: vector): boolean
	local from = Units.toStuds(a)
	local along = Units.toStuds(b) - from
	for _ = 1, PASSES do
		local hit = Workspace:Raycast(from, along, params)
		if not hit then
			return false
		end
		if hit.Instance.Name ~= Minimap.BARRIER then
			return true
		end
		params:AddToFilter(hit.Instance)
	end
	return true
end

-- The body your crosshair's over that the orb in your hand would bring
-- back, as your screen shows it.
local function aimedAt(render: number): Drawn?
	local s = PlayerController.sim
	if not s or s.weapons.equipped ~= WeaponSim.ULT or s.weapons.loadout[WeaponSim.ULT] ~= "revive" or s.abilities.holding == 0 then
		return nil
	end
	local bodies: { ReviveSim.Body } = {}
	local byId: { [number]: Drawn } = {}
	for _, d in drawn do
		if d.at == nil and revivable(d.body.id) then
			table.insert(bodies, d.body)
			byId[d.body.id] = d
		end
	end
	if #bodies == 0 then
		return nil
	end
	local camera = Workspace.CurrentCamera.CFrame
	local clouds = CloudView.standing(render)
	local id = ReviveSim.aimedAt(
		Units.toMetres(camera.Position),
		Units.asVector(camera.LookVector),
		bodies,
		function(a: vector, b: vector): boolean
			for _, cloud in clouds do
				if Sight.cloudHides(cloud, a, b) then
					return true
				end
			end
			return blocked(a, b)
		end
	)
	return if id then byId[id] else nil
end

local function unmark()
	local m = marked
	if m then
		for _, b in m.boxes do
			b:Destroy()
		end
		local w = m.widget
		if w then
			w:Destroy()
		end
		marked = nil
	end
end

-- Green boxes round a body's blocks, and a + over it.
local function mark(d: Drawn)
	local boxes = {}
	for _, p in d.blocks do
		local b = Instance.new("BoxHandleAdornment")
		b.Name = "VFRevive"
		b.Adornee = p
		b.AlwaysOnTop = false
		b.ZIndex = 1
		b.Color3 = GREEN
		b.Transparency = 0.45
		b.Size = p.Size + Vector3.one * (2 * PAD * Units.STUDS_PER_METRE)
		b.Parent = p
		table.insert(boxes, b)
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "VFReviveMark"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(36, 36)
	gui.StudsOffset = Vector3.new(0, 0.6 * Units.STUDS_PER_METRE, 0)
	gui.Adornee = d.blocks.body
	gui.Parent = d.model
	Ui.label(gui, {
		Text = "+",
		Font = Enum.Font.GothamBold,
		TextSize = 34,
		TextColor3 = GREEN,
		TextStrokeTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.fromScale(1, 1),
	})
	marked = { boxes = boxes, widget = gui, model = d.model }
end

local function onEvent(event: any)
	if typeof(event) ~= "table" or (event.kind ~= "reviving" and event.kind ~= "revived") then
		return
	end
	if typeof(event.at) ~= "number" or typeof(event.position) ~= "Vector3" or typeof(event.entity) ~= "number" then
		return
	end
	local own = event.entity == PlayerController.entityId
	local d: Due = {
		kind = event.kind,
		at = event.at,
		position = Units.toMetres(event.position),
		entity = if own then nil else event.entity,
	}
	table.insert(due, d)
end

-- Each frame, at `render` (the server time your screen shows).
local function step(render: number)
	local seen: { [BasePart]: boolean } = {}
	local bodies = Workspace:FindFirstChild(ReviveSim.FOLDER)
	if bodies then
		for _, part in bodies:GetChildren() do
			if not part:IsA("BasePart") then
				continue
			end
			seen[part] = true
			local d = drawn[part]
			if not d then
				local body = bodyOf(part)
				if not body then
					continue
				end
				d = draw(body)
				drawn[part] = d
			end
			local at = part:GetAttribute(ReviveSim.AT)
			d.at = if typeof(at) == "number" then at else nil
		end
	end
	-- A body gone from the server rises on until the screen reaches its
	-- burst, if its return's under way; otherwise it's gone at once.
	for part, d in drawn do
		if not seen[part] then
			drawn[part] = nil
			if d.at and render < ReviveSim.burstAt(d.at) then
				table.insert(rising, d)
			else
				d.model:Destroy()
			end
		end
	end
	for _, d in drawn do
		show(d, render)
	end
	local i = 1
	while i <= #rising do
		local d = rising[i]
		local at = d.at
		if not at or render >= ReviveSim.burstAt(at) then
			table.remove(rising, i)
			d.model:Destroy()
		else
			show(d, render)
			i += 1
		end
	end

	-- The sounds, and the burst's chips, as the screen reaches them.
	i = 1
	while i <= #due do
		local d = due[i]
		if render >= d.at then
			table.remove(due, i)
			if render - d.at < STALE then
				GameSounds.playCast(d.kind, d.position + vector.create(0, 0.3, 0), d.entity, true)
				if d.kind == "revived" then
					chips(d.position + vector.create(0, 0.9, 0))
				end
			end
		else
			i += 1
		end
	end

	-- The body the orb would bring back.
	local target = aimedAt(render)
	local m = marked
	if m and (target == nil or m.model ~= target.model) then
		unmark()
	end
	if target and not marked then
		mark(target)
	end
end

function ReviveView.start()
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		step(RemoteEntities.renderTime())
	end)
end

return ReviveView
