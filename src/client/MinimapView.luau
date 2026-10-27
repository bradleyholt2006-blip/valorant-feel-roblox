--!strict
-- The minimap (system 34), at the top left, and the big map over the middle
-- of the screen while Caps Lock is held (the reference's "Open Map (Hold)",
-- by default Caps Lock; M is the Play menu here, system 24). Both draw the
-- map played from its plan (Minimap.planFor) as the settings have it
-- (ClientSettings: Rotate or Fixed, Based on Side, Keep Player Centered,
-- Minimap Size and Zoom, Vision Cones and Show Map Region Names), and on it:
--   * you, an arrow the way you look, with a thicker edge (Patch 0.50 gave
--     your own icon colour and "a slightly thicker border"); while you
--     spectate, whoever you look out of (Spectate)
--   * your side, arrows in the allies' colour, held on the minimap's edge
--     while off it (Patch 5.08), and a red X where one died until they're
--     back or the round's over (techweez; community)
--   * the enemies your side sees, as the server says (MinimapServer, the
--     Sight remote), and where one was last seen a faded mark for a while
--     (Patch 5.08's "Recently Seen Enemy" icons, which stay where they were);
--     in deathmatch everyone, for a moment, as you come back to life (the
--     VALORANT Wiki's Deathmatch page: a pulse on respawning; community),
--     each where they are as the fog of war sends them for it (system 35)
--   * the spike planted, and dropped while it's shown to you
--     (Minimap.spikeShown); carried, a mark on its carrier for their side
--   * vision cones, yours and your side's, each ray as far as it goes from
--     the eye before the level, a cloud or a wall of fire or of ice stops
--     it (Patch 6.07 fixed cones flickering at walls of fire)
--   * clouds, walls of fire, fires, fields of ice (the Slow Orb's, system
--     37) and walls of ice (the Barrier Orb's, system 38, a bar along each
--     segment standing), edged in their owner's colour
--   * where your Shrouded Step would take you, or is taking you (system 42,
--     StepView.aimed; Patch 1.0: 'Omen can now see his teleport location on
--     the map')
--   * with From the Shadows' map in hand (system 43, ShadowView), the big
--     map, the course's too, drawn from its parts (PartsPlan), though it
--     has no minimap, and on it the cursor, a ring, violet where fire would
--     take you and red where it wouldn't; once it's fired, where it's
--     taking you, until you've formed there
--   * with Hunter's Fury's bow in hand (system 46, FuryView.aimed), where a
--     blast would go, a band as wide as it reaches, as far as its range
--     ('a range indicator on your minimap to help you guide your aim',
--     Mobalytics' Sova page)
--   * the sites' letters, and on the big map the places' names
--   * a white circle round you as you make a sound, as far as it's heard
--     (the minimap's sound circle: "Anyone outside of this white circle
--     can't hear you", ONE Esports; community), for a sound made where you
--     are whose edge is near enough to show (Minimap.Params.ringMost)
-- Nothing of an enemy is drawn that the server hasn't said your side sees.
-- While you're nearsighted by Omen's Paranoia (system 41), or whoever you
-- look out of is, all of it's covered in dark (ParanoiaView.dark), as the
-- reference's minimap 'will become obscured' (the VALORANT Wiki's Status
-- Effect page; community), and so it is while an enemy's From the Shadows
-- runs (system 43, ShadowView.dark).
--
-- For scripted checks, the minimap's ScreenGui (VFMinimap) carries what it
-- shows as attributes: Plan (the plan's key), Seen (the entity ids of the
-- enemies shown, "3,7"), Spike (whether the spike is), Turn (degrees the
-- map's turned), Big (whether the big map's open) and Dark (how covered it
-- is, 0 to 1). Its icons are named Self, Ally_<id>, Enemy_<id>, Seen_<id>,
-- Pulse_<id>, Dead_<id>, Spike, Step, Shadow (From the Shadows' cursor),
-- Shade (where it's taking you), Fury (where a blast would go) and Ring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local Minimap = require(Shared.Match.Minimap)
local PartsPlan = require(Shared.Match.PartsPlan)
local FogOfWar = require(Shared.Combat.FogOfWar)
local Sight = require(Shared.Combat.Sight)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local SoundMath = require(Shared.Audio.SoundMath)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local Units = require(Shared.Units)

local Ui = require(script.Parent.Debug.Ui)
local ClientSettings = require(script.Parent.ClientSettings)
local ClientSpike = require(script.Parent.ClientSpike)
local CloudView = require(script.Parent.CloudView)
local BlazeView = require(script.Parent.BlazeView)
local FireView = require(script.Parent.FireView)
local SlowView = require(script.Parent.SlowView)
local BarrierView = require(script.Parent.BarrierView)
local GameSounds = require(script.Parent.Audio.GameSounds)
local SoundEngine = require(script.Parent.Audio.SoundEngine)
local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local Spectate = require(script.Parent.Spectate)
local Visuals = require(script.Parent.Visuals)
local ParanoiaView = require(script.Parent.ParanoiaView)
local StepView = require(script.Parent.StepView)
local ShadowView = require(script.Parent.ShadowView)
local FuryView = require(script.Parent.FuryView)

local MinimapView = {}

local P = Minimap.Params
local HF = AbilityConfig.HuntersFury
local S = Units.STUDS_PER_METRE
local MARGIN = 12 -- pixels from the screen's corner to the minimap
local EDGE = 3 -- pixels an ally held on the minimap's edge sits in from it
local PASSES = 4 -- barriers a cone's ray goes through at the most
local CONE_FAINT = 0.8 -- the cones' transparency, painted solid together

local BACK = Color3.fromRGB(12, 14, 20)
local FLOOR = Color3.fromRGB(78, 86, 100)
local WALL = Color3.fromRGB(205, 212, 225)
local COVER_LOW = Color3.fromRGB(122, 132, 148)
local COVER_HIGH = Color3.fromRGB(168, 178, 194)
local SITE = Color3.fromRGB(112, 100, 74)
local SPAWN = Color3.fromRGB(66, 74, 86)
local DARK = Color3.fromRGB(10, 10, 14)
local SELF = Color3.fromRGB(255, 236, 140)
local SPIKE = Color3.fromRGB(255, 150, 40)
local SMOKE = Color3.fromRGB(196, 214, 228)
local FIRE = Color3.fromRGB(255, 128, 40)
local ICE = Color3.fromRGB(110, 205, 235)
local TEXT = Color3.fromRGB(235, 238, 244)
local DEAD = Color3.fromRGB(235, 72, 72)
local SHADOW = Color3.fromRGB(18, 12, 28) -- Paranoia's dark over it all (system 41)
local STEP = Color3.fromRGB(160, 120, 240) -- where your Shrouded Step takes you (system 42)
local REFUSED = Color3.fromRGB(230, 70, 70) -- From the Shadows' cursor where it wouldn't (system 43)
local FURY = Color3.fromRGB(80, 235, 255) -- where a blast of your Hunter's Fury would go (system 46)

type Keyed = { parent: Instance, items: { [string]: GuiObject }, touched: { [string]: boolean } }

-- The minimap or the big map.
type Layer = {
	gui: ScreenGui,
	box: Frame,
	pivot: Frame,
	map: Frame,
	shapes: Frame,
	utility: Keyed,
	conePivot: Frame,
	coneMap: Frame,
	cones: Keyed,
	icons: Keyed,
	cover: Frame, -- the dark over it all while you're nearsighted
	big: boolean,
	built: string, -- the plan, scale and names its shapes are drawn for
	spawns: { { frame: Frame, shape: Minimap.Shape } },
	upright: { GuiObject }, -- the words on it, kept upright as it turns
}

type Icon = {
	name: string,
	kind: string, -- "self", "ally", "enemy", "seen", "pulse", "dead", "spike", "step" or "cursor"
	position: vector,
	yaw: number?,
	fade: number, -- 0 solid, 1 gone
	carrier: boolean,
	edge: boolean, -- held on the minimap's edge while off it
	refused: boolean?, -- From the Shadows' cursor: where fire wouldn't take you
}

type Round = { centre: vector, radius: number, colour: Color3 }

type Cone = { name: string, colour: Color3, eye: vector, yaw: number }

-- What both maps show this frame.
type Scene = {
	me: Minimap.Me?,
	icons: { Icon },
	clouds: { Round },
	fires: { Round },
	slows: { Round },
	walls: { { points: { vector }, colour: Color3, fill: Color3 } },
	cones: { Cone },
	ring: { radius: number, fade: number }?,
	fury: { from: vector, to: vector }?, -- where a blast of yours would go (system 46)
	home: Minimap.Shape?,
	turn: number, -- the turn that puts your spawn at the bottom
}

type Marker = { position: vector, at: number }

local me = Players.LocalPlayer
local mini: Layer? = nil
local mega: Layer? = nil
local held = false -- Caps Lock
local testBig = false -- TestAim's VFTestMap
local shownBottom = 0

-- What the server last said your side sees.
local seen: { [number]: boolean } = {}
local spikeSeen = false
-- Where enemies were last seen, deathmatch's pulse, and where allies died.
local recent: { [number]: Marker } = {}
local pulses: { [number]: Marker } = {}
local dead: { [number]: vector } = {}
-- Until when (os.clock()) everyone else reaching the snapshots pulses, as
-- you're back in deathmatch, and who has.
local pulseUntil = 0
local pulsed: { [number]: boolean } = {}
-- Entities killed and not back yet.
local down: { [number]: boolean } = {}
local ring: { radius: number, at: number }? = nil
-- Each cone's rays' reach in metres, as last cast, and when.
local reaches: { [string]: { number } } = {}
local castAt = 0
local lastRound: any = nil
local lastPlan = ""

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = RobloxWorld.CHARACTER_GROUP
params.RespectCanCollide = true

local function color3(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

local function allyColour(): Color3
	return color3(VisualConfig.allyColour)
end

local function enemyColour(): Color3
	return color3(VisualConfig.EnemyColours[Visuals.enemyColour].colour)
end

-- Keyed sets of GUI objects: made the first time a frame asks for one by
-- name, and gone the first frame none does.
local function keyed(parent: Instance): Keyed
	return { parent = parent, items = {}, touched = {} }
end

local function get(k: Keyed, name: string, make: () -> GuiObject): GuiObject
	k.touched[name] = true
	local item = k.items[name]
	if item then
		return item
	end
	local made = make()
	made.Name = name
	made.Parent = k.parent
	k.items[name] = made
	return made
end

local function sweep(k: Keyed)
	for name, item in k.items do
		if not k.touched[name] then
			item:Destroy()
			k.items[name] = nil
		end
	end
	table.clear(k.touched)
end

local function blank(parent: Instance?, name: string, z: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Size = UDim2.fromOffset(0, 0)
	f.ZIndex = z
	f.Parent = parent
	return f
end

local function plainFrame(colour: Color3, z: number): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = colour
	f.ZIndex = z
	return f
end

local function stroke(parent: Instance, colour: Color3, thickness: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = colour
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function disc(colour: Color3, z: number): Frame
	local f = plainFrame(colour, z)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = f
	return f
end

local function text(parent: Instance, words: string, size: number, z: number, bold: boolean): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Size = UDim2.fromOffset(0, 0)
	l.AutomaticSize = Enum.AutomaticSize.XY
	l.Font = if bold then Enum.Font.GothamBold else Enum.Font.GothamMedium
	l.TextSize = size
	l.TextColor3 = TEXT
	l.TextStrokeColor3 = DARK
	l.TextStrokeTransparency = 0.35
	l.Text = words
	l.ZIndex = z
	l.Parent = parent
	return l
end

-- An arrow: a disc with a point on its top, turned the way it looks, and a
-- spike's mark on it for its carrier.
local function newArrow(colour: Color3, edge: number, z: number): GuiObject
	local holder = blank(nil, "Arrow", z)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	local nose = plainFrame(colour, z)
	nose.Name = "Nose"
	nose.Position = UDim2.fromScale(0.5, 0.14)
	nose.Size = UDim2.fromScale(0.56, 0.56)
	nose.Rotation = 45
	nose.Parent = holder
	local body = disc(colour, z + 1)
	body.Name = "Body"
	body.Position = UDim2.fromScale(0.5, 0.5)
	body.Size = UDim2.fromScale(1, 1)
	stroke(body, DARK, edge)
	body.Parent = holder
	local mark = plainFrame(SPIKE, z + 2)
	mark.Name = "Spike"
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Size = UDim2.fromScale(0.42, 0.42)
	mark.Rotation = 45
	mark.Visible = false
	stroke(mark, DARK, 1)
	mark.Parent = holder
	return holder
end

local function newIcon(kind: string): GuiObject
	if kind == "self" then
		return newArrow(SELF, 2, 7)
	elseif kind == "ally" then
		return newArrow(allyColour(), 1, 6)
	elseif kind == "enemy" or kind == "seen" or kind == "pulse" then
		local d = disc(enemyColour(), if kind == "enemy" then 5 else 3)
		stroke(d, DARK, 1)
		if kind == "seen" then
			text(d, "?", 10, 4, true).Position = UDim2.fromScale(0.5, 0.5)
		end
		return d
	elseif kind == "dead" then
		local holder = blank(nil, "Dead", 2)
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		local x = text(holder, "X", 12, 2, true)
		x.Position = UDim2.fromScale(0.5, 0.5)
		x.TextColor3 = DEAD
		return holder
	elseif kind == "spike" then
		local d = plainFrame(SPIKE, 4)
		d.Rotation = 45
		stroke(d, DARK, 2)
		return d
	elseif kind == "step" then
		local d = disc(STEP, 4)
		d.BackgroundTransparency = 0.55
		stroke(d, STEP, 1.5)
		return d
	elseif kind == "cursor" then
		-- From the Shadows' cursor: a ring with a dot in it.
		local r = disc(STEP, 8)
		r.BackgroundTransparency = 1
		stroke(r, STEP, 2.5)
		local dot = disc(STEP, 8)
		dot.Name = "Dot"
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.Size = UDim2.fromScale(0.22, 0.22)
		dot.Parent = r
		return r
	end
	-- "ring": the sound circle round you.
	local r = disc(Color3.new(1, 1, 1), 1)
	r.BackgroundTransparency = 1
	stroke(r, Color3.new(1, 1, 1), 1.5)
	return r
end

local function newLayer(name: string, order: number, big: boolean): Layer
	local gui = Ui.screen(name, order, if big then Enum.ScreenInsets.None else nil)
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	local box = Instance.new("Frame")
	box.Name = "Box"
	box.BorderSizePixel = 0
	box.BackgroundColor3 = BACK
	box.BackgroundTransparency = if big then 0.12 else 0.3
	box.ClipsDescendants = true
	if big then
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.fromScale(0.5, 0.5)
	else
		box.Position = UDim2.fromOffset(MARGIN, MARGIN)
	end
	stroke(box, DARK, 1)
	box.Parent = gui
	-- The map turns about the box's middle: a point with no size there,
	-- and the map on it, moved so the view's centre is there. It's drawn in
	-- a group of its own, which cuts it to the box however it's turned
	-- (ClipsDescendants doesn't, turned).
	local art = Instance.new("CanvasGroup")
	art.Name = "Art"
	art.BackgroundTransparency = 1
	art.Size = UDim2.fromScale(1, 1)
	art.ZIndex = 1
	art.Parent = box
	local pivot = blank(art, "Pivot", 1)
	pivot.Position = UDim2.fromScale(0.5, 0.5)
	local map = blank(pivot, "Map", 1)
	local shapes = blank(map, "Shapes", 1)
	local utility = blank(map, "Utility", 2)
	-- The cones, painted solid and shown faint, so where they overlap is no
	-- brighter.
	local group = Instance.new("CanvasGroup")
	group.Name = "Cones"
	group.BackgroundTransparency = 1
	group.Size = UDim2.fromScale(1, 1)
	group.GroupTransparency = CONE_FAINT
	group.ZIndex = 2
	group.Parent = box
	local conePivot = blank(group, "Pivot", 1)
	conePivot.Position = UDim2.fromScale(0.5, 0.5)
	local coneMap = blank(conePivot, "Map", 1)
	-- The icons don't turn: they're placed by Minimap.toView.
	local icons = blank(box, "Icons", 3)
	icons.Size = UDim2.fromScale(1, 1)
	local cover = Instance.new("Frame")
	cover.Name = "Cover"
	cover.BorderSizePixel = 0
	cover.BackgroundColor3 = SHADOW
	cover.BackgroundTransparency = 1
	cover.Size = UDim2.fromScale(1, 1)
	cover.ZIndex = 4
	cover.Parent = box
	return {
		gui = gui,
		box = box,
		pivot = pivot,
		map = map,
		shapes = shapes,
		utility = keyed(utility),
		conePivot = conePivot,
		coneMap = coneMap,
		cones = keyed(coneMap),
		icons = keyed(icons),
		cover = cover,
		big = big,
		built = "",
		spawns = {},
		upright = {},
	}
end

-- The map's own shapes and words, drawn again when the plan, the scale or
-- whether the names show changes. Each place is put where it is from the
-- plan's middle, `scale` pixels a metre; a part turned by yaw on the floor
-- turns the other way on the screen, as the GUI turns clockwise.
local function build(layer: Layer, plan: Minimap.Plan, box: number, scale: number, names: boolean)
	local key = string.format("%s|%d|%.5f|%s", plan.key, box, scale, tostring(names))
	if layer.built == key then
		return
	end
	layer.built = key
	layer.shapes:ClearAllChildren()
	table.clear(layer.spawns)
	table.clear(layer.upright)
	local mid = Minimap.middle(plan)
	for _, shape in plan.shapes do
		local colour, z = FLOOR, 1
		if shape.kind == "wall" then
			colour, z = WALL, 4
		elseif shape.kind == "cover" then
			colour, z = if shape.high then COVER_HIGH else COVER_LOW, 3
		elseif shape.kind == "site" then
			colour, z = SITE, 2
		elseif shape.kind == "spawn" then
			colour, z = SPAWN, 2
		end
		local f = plainFrame(colour, z)
		f.Name = shape.kind
		f.Position = UDim2.fromOffset((shape.center.x - mid.x) * scale, (shape.center.z - mid.z) * scale)
		f.Size = UDim2.fromOffset(math.max(shape.size.x * scale, 1), math.max(shape.size.z * scale, 1))
		f.Rotation = -math.deg(shape.yaw)
		f.Parent = layer.shapes
		if shape.kind == "spawn" then
			table.insert(layer.spawns, { frame = f, shape = shape })
		end
	end
	for _, label in plan.labels do
		if label.kind == "region" and not (layer.big and names) then
			continue
		end
		local size = if label.kind == "site" then math.max(12, box * (if layer.big then 0.04 else 0.07)) else math.max(10, box * 0.017)
		local l = text(layer.shapes, label.text, math.floor(size), 5, label.kind == "site")
		l.Name = "Label"
		l.Position = UDim2.fromOffset((label.at.x - mid.x) * scale, (label.at.z - mid.z) * scale)
		if label.kind == "region" then
			l.TextTransparency = 0.2
		end
		table.insert(layer.upright, l)
	end
end

-- The level in the way of a ray along `dir` from `from`: how far it goes,
-- `most` at the most, through the spawns' barriers as the server's sight
-- goes (MinimapServer).
local function levelReach(from: vector, dir: vector, most: number): number
	local origin = Units.toStuds(from)
	local along = Units.toStuds(dir * most)
	for _ = 1, PASSES do
		local hit = Workspace:Raycast(origin, along, params)
		if not hit then
			return most
		end
		if hit.Instance.Name ~= Minimap.BARRIER then
			return hit.Distance / S
		end
		params:AddToFilter(hit.Instance)
	end
	return most
end

-- Each cone's rays cast again: the level, the clouds and the walls of fire.
local function cast(scene: Scene)
	local fov = math.rad(Sight.Params.fov.value)
	local most = P.coneLength.value
	local clouds = {}
	for _, c in scene.clouds do
		table.insert(clouds, { centre = c.centre, radius = c.radius })
	end
	local walls = {}
	for _, w in scene.walls do
		table.insert(walls, w.points)
	end
	table.clear(reaches)
	for _, cone in scene.cones do
		local out = {}
		for i, yaw in Minimap.coneYaws(cone.yaw, fov, P.coneRays.value) do
			local dir = vector.create(-math.sin(yaw), 0, -math.cos(yaw))
			local far = levelReach(cone.eye, dir, most)
			out[i] = Minimap.reach(cone.eye, dir, far, clouds, walls)
		end
		reaches[cone.name] = out
	end
end

-- An entity's pose as it's drawn now, if it's here and alive.
local function posed(id: number, render: number): PlayerCodec.Pose?
	if not RemoteEntities.isPresent(id) then
		return nil
	end
	local pose = RemoteEntities.sample(id, render)
	return if pose and pose.alive then pose else nil
end

local function playerOf(id: number): Player?
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == id then
			return player
		end
	end
	return nil
end

-- The colour a thing someone threw is edged in: yours and your side's in
-- the allies' colour, the rest in the enemies'.
local function ownerColour(entity: number, side: number): Color3
	if entity == PlayerController.entityId then
		return allyColour()
	end
	local owner = playerOf(entity)
	return if owner and owner:GetAttribute(ArenaConfig.SIDE) == side then allyColour() else enemyColour()
end

-- Where your feet are as drawn, or nil before your first life.
local function myFeet(): vector?
	local sim = PlayerController.sim
	return if sim then sim.movement.position else nil
end

local function eyeOf(pose: PlayerCodec.Pose): vector
	local cfg = PlayerController.cfg
	local eye = cfg.standEyeHeight + (cfg.crouchEyeHeight - cfg.standEyeHeight) * pose.crouchAlpha
	return pose.position + vector.create(0, eye, 0)
end

local function forgetMarks()
	table.clear(recent)
	table.clear(pulses)
	table.clear(dead)
	table.clear(down)
	table.clear(pulsed)
	pulseUntil = 0
end

-- What both maps show this frame, for a player on `side`.
local function sceneOf(plan: Minimap.Plan, mode: any, side: number, attackers: any): Scene
	local now = os.clock()
	local render = RemoteEntities.renderTime()
	local icons: { Icon } = {}
	local cones: { Cone } = {}
	local spike = ClientSpike.view()
	local ours = ClientSpike.ours()
	local carrierShown = spike.state == "carried" and Minimap.spikeShown("carried", ours, false)
	local ally = allyColour()

	-- You, or whoever you look out of.
	local camera = Workspace.CurrentCamera
	local watching = Spectate.watching
	local viewing = RemoteEntities.viewing
	local you: Minimap.Me? = nil
	if camera and (PlayerController.alive or viewing ~= nil) then
		local cf = camera.CFrame
		you = { position = Units.toMetres(cf.Position), yaw = Minimap.yawOf(Units.asVector(cf.LookVector)) }
	end
	if you then
		local user = if watching and viewing ~= nil then watching.UserId else me.UserId
		table.insert(icons, {
			name = "Self",
			kind = "self",
			position = you.position,
			yaw = you.yaw,
			fade = 0,
			carrier = carrierShown and spike.carrier == user,
			edge = true,
		})
		table.insert(cones, { name = "Self", colour = Color3.new(1, 1, 1), eye = you.position, yaw = you.yaw })
	end

	-- Your side.
	for _, player in Players:GetPlayers() do
		if player == me or player:GetAttribute(ArenaConfig.SIDE) ~= side then
			continue
		end
		local id = PlayerCodec.entityIdForUser(player.UserId)
		local pose = if id ~= viewing then posed(id, render) else nil
		if pose then
			local name = "Ally_" .. id
			table.insert(icons, {
				name = name,
				kind = "ally",
				position = pose.position,
				yaw = pose.yaw,
				fade = 0,
				carrier = carrierShown and spike.carrier == player.UserId,
				edge = true,
			})
			table.insert(cones, { name = name, colour = ally, eye = eyeOf(pose), yaw = pose.yaw })
		end
	end
	for id, at in dead do
		table.insert(icons, { name = "Dead_" .. id, kind = "dead", position = at, fade = 0, carrier = false, edge = false })
	end

	-- The enemies your side sees, and where they were.
	for id in seen do
		local pose = posed(id, render)
		if pose then
			table.insert(
				icons,
				{ name = "Enemy_" .. id, kind = "enemy", position = pose.position, fade = 0, carrier = false, edge = false }
			)
		end
	end
	for id, mark in recent do
		local fade = (now - mark.at) / P.lastSeen.value
		if fade >= 1 then
			recent[id] = nil
		else
			table.insert(
				icons,
				{ name = "Seen_" .. id, kind = "seen", position = mark.position, fade = fade, carrier = false, edge = false }
			)
		end
	end
	-- Deathmatch's pulse: everyone else, as they reach your snapshots in
	-- the moment after you're back (the fog of war sends them for it).
	if now < pulseUntil then
		for _, player in Players:GetPlayers() do
			local other = PlayerCodec.entityIdForUser(player.UserId)
			local pose = if player ~= me and not pulsed[other] then posed(other, render) else nil
			if pose then
				pulses[other] = { position = pose.position, at = now }
				pulsed[other] = true
			end
		end
	end
	for id, mark in pulses do
		local fade = (now - mark.at) / P.pulse.value
		if fade >= 1 then
			pulses[id] = nil
		else
			table.insert(
				icons,
				{ name = "Pulse_" .. id, kind = "pulse", position = mark.position, fade = fade, carrier = false, edge = false }
			)
		end
	end

	-- The spike, where it lies.
	local at = spike.position
	if at and spike.state ~= "carried" and Minimap.spikeShown(spike.state, ours, spikeSeen) then
		table.insert(icons, { name = "Spike", kind = "spike", position = at, fade = 0, carrier = false, edge = false })
	end
	-- Where your Shrouded Step would take you, or is taking you (system 42).
	local step = StepView.aimed()
	if step then
		table.insert(icons, { name = "Step", kind = "step", position = step, fade = 0, carrier = false, edge = false })
	end
	-- From the Shadows' cursor while its map's up, and where it's taking
	-- you once it's fired (system 43).
	local cursor = ShadowView.cursor()
	if cursor then
		table.insert(icons, {
			name = "Shadow",
			kind = "cursor",
			position = cursor,
			fade = 0,
			carrier = false,
			edge = false,
			refused = not ShadowView.placeable(),
		})
	end
	local going = ShadowView.going()
	if going then
		table.insert(icons, { name = "Shade", kind = "step", position = going, fade = 0, carrier = false, edge = false })
	end

	-- What's been thrown.
	local clouds: { Round } = {}
	for _, c in CloudView.standing(render) do
		table.insert(clouds, { centre = c.centre, radius = c.radius, colour = ownerColour(c.entity, side) })
	end
	local fires: { Round } = {}
	for _, f in FireView.burning() do
		table.insert(fires, { centre = f.centre, radius = f.radius, colour = ownerColour(f.entity, side) })
	end
	local slows: { Round } = {}
	for _, f in SlowView.standing() do
		table.insert(slows, { centre = f.centre, radius = f.radius, colour = ownerColour(f.entity, side) })
	end
	local walls = {}
	for _, w in BlazeView.standing() do
		table.insert(walls, { points = w.points, colour = ownerColour(w.entity, side), fill = FIRE })
	end
	for _, w in BarrierView.standing() do
		table.insert(walls, { points = w.points, colour = ownerColour(w.entity, side), fill = ICE })
	end

	-- Where a blast of your Hunter's Fury would go (system 46).
	local aimed = FuryView.aimed()
	local fury = if aimed then { from = aimed.origin, to = aimed.origin + aimed.direction * HF.range.value } else nil

	local r = ring
	local fade = if r then (now - r.at) / P.ring.value else 1
	local home = Minimap.homeOf(plan, mode, side, attackers)
	return {
		me = you,
		icons = icons,
		clouds = clouds,
		fires = fires,
		slows = slows,
		walls = walls,
		cones = if ClientSettings.current.mapCones then cones else {},
		ring = if r and fade < 1 and you then { radius = r.radius, fade = fade } else nil,
		fury = fury,
		home = home,
		turn = Minimap.homeTurn(plan, home),
	}
end

-- A round drawn on the turning map: a cloud, a fire or a field of ice.
local function drawRound(layer: Layer, name: string, round: Round, mid: vector, scale: number, colour: Color3, transparency: number)
	local f = get(layer.utility, name, function()
		local d = disc(colour, 1)
		stroke(d, round.colour, 1.5)
		return d
	end)
	f.Position = UDim2.fromOffset((round.centre.x - mid.x) * scale, (round.centre.z - mid.z) * scale)
	f.Size = UDim2.fromOffset(2 * round.radius * scale, 2 * round.radius * scale)
	f.BackgroundTransparency = transparency
	local edge = f:FindFirstChildOfClass("UIStroke")
	if edge then
		edge.Color = round.colour
	end
end

local function draw(layer: Layer, plan: Minimap.Plan, view: Minimap.View, scene: Scene)
	local turn = math.deg(view.turn)
	local mid = Minimap.middle(plan)
	local scale = view.scale
	layer.pivot.Rotation = turn
	layer.conePivot.Rotation = turn
	local offset = UDim2.fromOffset((mid.x - view.centre.x) * scale, (mid.z - view.centre.z) * scale)
	layer.map.Position = offset
	layer.coneMap.Position = offset
	for _, label in layer.upright do
		label.Rotation = -turn
	end
	local ally, enemy = allyColour(), enemyColour()
	for _, s in layer.spawns do
		local colour = SPAWN
		if scene.home then
			colour = (if s.shape == scene.home then ally else enemy):Lerp(SPAWN, 0.65)
		end
		s.frame.BackgroundColor3 = colour
	end

	-- What's been thrown, on the map as it turns.
	for i, c in scene.clouds do
		drawRound(layer, "Cloud_" .. i, c, mid, scale, SMOKE, 0.1)
	end
	for i, f in scene.fires do
		drawRound(layer, "Fire_" .. i, f, mid, scale, FIRE, 0.25)
	end
	for i, f in scene.slows do
		drawRound(layer, "Slow_" .. i, f, mid, scale, ICE, 0.35)
	end
	local thick = math.max(2, scale * 0.6)
	for i, w in scene.walls do
		for j = 2, #w.points do
			local a, b = w.points[j - 1], w.points[j]
			local dx, dz = (b.x - a.x) * scale, (b.z - a.z) * scale
			local length = math.sqrt(dx * dx + dz * dz)
			local f = get(layer.utility, "Wall_" .. i .. "_" .. j, function()
				local bar = plainFrame(FIRE, 2)
				stroke(bar, w.colour, 1)
				return bar
			end)
			f.Position = UDim2.fromOffset(((a.x + b.x) / 2 - mid.x) * scale, ((a.z + b.z) / 2 - mid.z) * scale)
			f.Size = UDim2.fromOffset(thick, length + thick / 2)
			f.Rotation = math.deg(math.atan2(dx, -dz))
			f.BackgroundColor3 = w.fill
			local edge = f:FindFirstChildOfClass("UIStroke")
			if edge then
				edge.Color = w.colour
			end
		end
	end
	-- Where a blast of your Hunter's Fury would go (system 46): a band as
	-- wide as it reaches either side, from your eye as far as its range.
	local fury = scene.fury
	if fury then
		local dx, dz = (fury.to.x - fury.from.x) * scale, (fury.to.z - fury.from.z) * scale
		local length = math.sqrt(dx * dx + dz * dz)
		local f = get(layer.utility, "Fury", function()
			local band = plainFrame(FURY, 2)
			band.BackgroundTransparency = 0.6
			return band
		end)
		f.Position = UDim2.fromOffset(((fury.from.x + fury.to.x) / 2 - mid.x) * scale, ((fury.from.z + fury.to.z) / 2 - mid.z) * scale)
		f.Size = UDim2.fromOffset(math.max(2 * HF.radius.value * scale, 2), length)
		f.Rotation = math.deg(math.atan2(dx, -dz))
	end
	sweep(layer.utility)

	-- The cones, from where each eye is now, as far as their rays last went.
	local fov = math.rad(Sight.Params.fov.value)
	local rays = P.coneRays.value
	for _, cone in scene.cones do
		local far = reaches[cone.name]
		if not far then
			continue
		end
		local px = {}
		for i, d in far do
			px[i] = d * scale
		end
		local x, y = (cone.eye.x - mid.x) * scale, (cone.eye.z - mid.z) * scale
		for i, rect in Minimap.coneRects(x, y, Minimap.coneYaws(cone.yaw, fov, rays), px, fov / rays) do
			local f = get(layer.cones, cone.name .. "_" .. i, function()
				return plainFrame(cone.colour, 1)
			end)
			f.BackgroundColor3 = cone.colour
			f.Position = UDim2.fromOffset(rect.x, rect.y)
			f.Size = UDim2.fromOffset(rect.w, rect.h)
			f.Rotation = rect.rotation
		end
	end
	sweep(layer.cones)

	-- The icons, upright, where each falls in the view.
	local half = view.half
	local size = math.max(9, math.floor(view.half * 2 * (if layer.big then 0.024 else 0.045) + 0.5))
	for _, icon in scene.icons do
		local x, y = Minimap.toView(view, icon.position)
		if icon.edge then
			x, y = Minimap.toEdge(view, x, y, EDGE + size / 2)
		end
		local kind = icon.kind
		local f = get(layer.icons, icon.name, function()
			return newIcon(kind)
		end)
		f.Position = UDim2.fromOffset(half + x, half + y)
		local across = if kind == "spike"
			then size * 1.1
			elseif kind == "self" then size * 1.15
			elseif kind == "cursor" then size * 1.8
			else size
		f.Size = UDim2.fromOffset(across, across)
		if icon.yaw then
			f.Rotation = math.deg(Minimap.facing(view, icon.yaw))
		end
		if kind == "self" or kind == "ally" then
			local mark = f:FindFirstChild("Spike") :: GuiObject?
			if mark then
				mark.Visible = icon.carrier
			end
		elseif kind == "cursor" then
			local colour = if icon.refused then REFUSED else STEP
			local edge = f:FindFirstChildOfClass("UIStroke")
			if edge then
				edge.Color = colour
			end
			local dot = f:FindFirstChild("Dot") :: GuiObject?
			if dot then
				dot.BackgroundColor3 = colour
			end
		elseif kind == "enemy" or kind == "seen" or kind == "pulse" then
			f.BackgroundColor3 = enemy
			if kind ~= "enemy" then
				f.BackgroundTransparency = 0.45 + 0.55 * icon.fade
				local edge = f:FindFirstChildOfClass("UIStroke")
				if edge then
					edge.Transparency = icon.fade
				end
				local mark = f:FindFirstChildOfClass("TextLabel")
				if mark then
					mark.TextTransparency = icon.fade
					mark.TextStrokeTransparency = 0.35 + 0.65 * icon.fade
				end
			end
		end
	end
	local r = scene.ring
	local you = scene.me
	if r and you then
		local f = get(layer.icons, "Ring", function()
			return newIcon("ring")
		end)
		local x, y = Minimap.toView(view, you.position)
		local across = 2 * r.radius * scale
		f.Position = UDim2.fromOffset(half + x, half + y)
		f.Size = UDim2.fromOffset(across, across)
		local edge = f:FindFirstChildOfClass("UIStroke")
		if edge then
			edge.Transparency = 0.15 + 0.85 * r.fade
		end
	end
	sweep(layer.icons)
end

-- The arena's model, if it's built.
local function arena(): Instance?
	return Workspace:FindFirstChild(ArenaConfig.MODEL)
end

local function hide()
	shownBottom = 0
	for _, layer in { mini, mega } do
		if layer and layer.gui.Enabled then
			layer.gui.Enabled = false
		end
	end
end

local function step()
	local mLayer, bLayer = mini, mega
	if not mLayer or not bLayer then
		return
	end
	local model = arena()
	local mode = Workspace:GetAttribute(ArenaConfig.MODE)
	local side = me:GetAttribute(ArenaConfig.SIDE)
	local plan = if model and Workspace:GetAttribute(ArenaConfig.ON) == true then Minimap.planFor(mode, model:GetAttribute("Map")) else nil
	local played = model ~= nil and plan ~= nil and typeof(side) == "number"
	-- Off the arena's maps there's no minimap, but From the Shadows' map
	-- shows the course's (system 43), with nobody on your side.
	local shadows = ShadowView.mapUp()
	if not played then
		plan = if shadows then PartsPlan.inPlay() else nil
		side = 0
	end
	ShadowView.view = nil
	if not plan then
		hide()
		mLayer.gui:SetAttribute("Plan", nil)
		return
	end
	-- A new map or round: the marks of the last go.
	local round = if model then model:GetAttribute("Round") else nil
	if plan.key ~= lastPlan or round ~= lastRound then
		lastPlan = plan.key
		lastRound = round
		forgetMarks()
	end
	local s = ClientSettings.current
	local camera = Workspace.CurrentCamera
	local screen = if camera then camera.ViewportSize.Y else 720
	local scene = sceneOf(plan, mode, side, if model then model:GetAttribute("Attackers") else nil)
	local now = os.clock()
	if now - castAt >= P.coneEvery.value then
		castAt = now
		cast(scene)
	end

	local turn = 0
	if played then
		local box = math.floor(screen * P.size.value * s.mapSize + 0.5)
		mLayer.box.Size = UDim2.fromOffset(box, box)
		shownBottom = MARGIN + box
		local view = Minimap.miniView(plan, s, scene.me, box, scene.turn)
		build(mLayer, plan, box, view.scale, false)
		draw(mLayer, plan, view, scene)
		turn = view.turn
	else
		shownBottom = 0
	end
	mLayer.gui.Enabled = played

	local big = held or testBig or shadows
	if big then
		local bigBox = math.floor(screen * P.bigSize.value + 0.5)
		bLayer.box.Size = UDim2.fromOffset(bigBox, bigBox)
		local bigView = Minimap.bigView(plan, s, bigBox, scene.turn)
		build(bLayer, plan, bigBox, bigView.scale, Minimap.namesShown(s.mapNames, if model then model:GetAttribute("Phase") else nil))
		draw(bLayer, plan, bigView, scene)
		if shadows then
			ShadowView.view = bigView
		end
	end
	bLayer.gui.Enabled = big
	local covered = math.max(ParanoiaView.dark, ShadowView.dark())
	mLayer.cover.BackgroundTransparency = 1 - covered
	bLayer.cover.BackgroundTransparency = 1 - covered

	-- For scripted checks.
	local shown = {}
	for id in seen do
		if posed(id, RemoteEntities.renderTime()) then
			table.insert(shown, id)
		end
	end
	table.sort(shown)
	local gui = mLayer.gui
	gui:SetAttribute("Plan", plan.key)
	gui:SetAttribute("Seen", table.concat(shown, ","))
	gui:SetAttribute("Spike", if mLayer.icons.items.Spike then true else false)
	gui:SetAttribute("Turn", math.floor(math.deg(turn) * 10 + 0.5) / 10)
	gui:SetAttribute("Big", big)
	gui:SetAttribute("Dark", math.floor(covered * 100 + 0.5) / 100)
end

-- The server's word on who your side sees: those it no longer sees are
-- marked where they were last drawn, unless they've died.
local function onSight(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.ids) ~= "table" then
		return
	end
	local now = os.clock()
	local render = RemoteEntities.renderTime()
	local fresh: { [number]: boolean } = {}
	for _, id in payload.ids do
		if typeof(id) == "number" then
			fresh[id] = true
			recent[id] = nil
		end
	end
	for id in seen do
		if not fresh[id] and not down[id] then
			local pose = posed(id, render)
			if pose then
				recent[id] = { position = pose.position, at = now }
			end
		end
	end
	seen = fresh
	spikeSeen = payload.spike == true
end

-- Deaths and lives: an X where you or an ally fell, gone as they're back;
-- and in deathmatch, as you're back, everyone, where they are.
local function onCombat(event: any)
	if typeof(event) ~= "table" or typeof(event.target) ~= "number" then
		return
	end
	local id: number = event.target
	local side = me:GetAttribute(ArenaConfig.SIDE)
	if event.kind == "damage" and event.killed == true then
		down[id] = true
		recent[id] = nil
		local at: vector? = nil
		if id == PlayerController.entityId then
			at = myFeet()
		else
			local player = playerOf(id)
			if player and typeof(side) == "number" and player:GetAttribute(ArenaConfig.SIDE) == side then
				local pose = RemoteEntities.sample(id, RemoteEntities.renderTime())
				at = if pose then pose.position else nil
			end
		end
		if at then
			dead[id] = at
		end
	elseif event.kind == "spawn" then
		down[id] = nil
		dead[id] = nil
		recent[id] = nil
		if id == PlayerController.entityId and Workspace:GetAttribute(ArenaConfig.MODE) == "deathmatch" then
			pulseUntil = os.clock() + FogOfWar.Params.reveal.value
			table.clear(pulsed)
		end
	end
end

-- Each sound you make where you are, heard no further than the edge the
-- circle shows: the circle, as far as it's heard. A smaller one while a
-- bigger one's fresh doesn't shrink it.
local function onSound(entry: GameSounds.Entry)
	if entry.who ~= "you" or not entry.loud or entry.position ~= nil or entry.note ~= nil then
		return
	end
	local curve = SoundEngine.curveOf(entry.sound)
	local radius = if curve then SoundMath.radius(curve) else nil
	if not radius or radius > P.ringMost.value then
		return
	end
	local now = os.clock()
	local r = ring
	if not r or radius >= r.radius or now - r.at > P.ring.value / 2 then
		ring = { radius = radius, at = now }
	end
end

-- How far down the screen the minimap reaches, in the HUD's pixels, or 0
-- while it's hidden: the debug panel goes under it (DebugHud).
function MinimapView.bottom(): number
	return shownBottom
end

-- Opens the big map as holding Caps Lock does, or closes it (TestAim's
-- VFTestMap).
function MinimapView.setBig(open: boolean)
	testBig = open
end

function MinimapView.start()
	mini = newLayer("VFMinimap", 14, false)
	mega = newLayer("VFMegamap", 18, true)
	local remotes = Remotes.get()
	NetSim.on(remotes.Sight, onSight)
	NetSim.on(remotes.Combat, onCombat)
	table.insert(GameSounds.entryListeners, onSound)
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.CapsLock and not processed then
			held = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.CapsLock then
			held = false
		end
	end)
	RunService.RenderStepped:Connect(step)
end

return MinimapView
