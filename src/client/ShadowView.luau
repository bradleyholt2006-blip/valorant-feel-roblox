--!strict
-- Omen's From the Shadows on the client (system 43). Ours, not the
-- reference's art: plain parts, the GUI and a colour correction.
--   * Its map: with it in hand the big map's up (MinimapView) wherever you
--     play, the course's drawn from its parts (PartsPlan), and the mouse
--     moves a cursor across it, not the view, from where you stand (ours),
--     held on the map (Minimap.held). The cursor's a ring, violet where
--     fire would take you, as your simulation will find it
--     (ShadowSim.place), red where it wouldn't, and in the buy phase
--     everywhere. Fire sends its place with the input
--     (PlayerController.mapPoint). Once it's fired, where it's taking you
--     shows on the minimap until you've formed there
--   * Your windup: shadow closing in from the screen's edges, as Shrouded
--     Step's
--   * You as a Shade: the world all but grey ('Omen's vision is mostly
--     grayscale', the VALORANT Wiki), and dark all round you past how far
--     you see (ShadowSim.sight: nothing as you arrive, then more and more,
--     faster and faster; ParanoiaView draws it as a nearsight's dark),
--     until you've formed
--   * Others' windups swirl as Shrouded Step's does (StepView.swirl), and
--     others as Shades are drawn dark and see-through (RemoteEntities).
--     Where one goes from, a puff of shadow, for whoever sees them go, and
--     shadow drawn in round the Shade as it arrives, for whoever hears it
--     there (StepView.puff and form); sent back, a puff where the Shade
--     was and shadow drawn in where they're back; formed, shadow drawn in
--   * A Shade arriving and being sent back are heard here, each as far as
--     the server tells of it (ShadowServer), and so is yours sent back by an
--     enemy's hit, which your simulation couldn't foresee; AbilityEffects
--     plays the rest
--   * An enemy's From the Shadows covers your minimap and big map in dark
--     from as it's fired until it's over: its time, or sooner as you hear
--     it end or they die ('This activation will also cause the minimaps of
--     enemy agents to become obscured for the ability's duration', the
--     VALORANT Wiki)
-- For scripted checks, PlayerGui's VFShadow carries Map (whether its map's
-- up), Cursor (the cursor's place, metres), Placeable (whether fire would
-- take you there), Grey (whether you're a Shade's grey), Sight (how far you
-- see as one, metres, or -1) and Dark (how covered the minimap is, 0 to
-- 1); the windup's shadow is its `Edge`.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local BarrierSim = require(Shared.Abilities.BarrierSim)
local Minimap = require(Shared.Match.Minimap)
local MovementConfig = require(Shared.Movement.MovementConfig)
local PartsPlan = require(Shared.Match.PartsPlan)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local ShadowSim = require(Shared.Abilities.ShadowSim)
local Units = require(Shared.Units)
local WeaponSim = require(Shared.Weapons.WeaponSim)

local CameraController = require(script.Parent.CameraController)
local NetSim = require(script.Parent.NetSim)
local ParanoiaView = require(script.Parent.ParanoiaView)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local StepView = require(script.Parent.StepView)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local ShadowView = {}

-- The big map's view while From the Shadows' map is up, which the cursor
-- moves across: MinimapView sets it each frame it draws it. Nil without.
ShadowView.view = nil :: Minimap.View?

local FS = AbilityConfig.FromTheShadows
local DT = 1 / MovementConfig.TickRate.value
local SHADOW = Color3.fromRGB(26, 18, 40)
local EDGE = 140 -- pixels: how far the windup's shadow closes in at the last, as Shrouded Step's
local SPEED = 1 -- pixels the cursor moves across the map for each count of the mouse (ours)
local MOVED = 0.01 -- metres the cursor moves before where it would take you is found again
local AGAIN = 0.25 -- seconds before it's found again anyway, as walls rise and fall
local GREY = -0.85 -- a Shade's saturation (ours: 'mostly grayscale')
local LEAST = 0.2 -- metres: the least a Shade sees, so the dark's never on the eye (ours)
local STALE = 1 -- seconds: an event the screen is this far past isn't shown

-- Another's event for the frame on your screen to reach: what, whose,
-- when (server time), and the places you're told of (metres): where they
-- went from, or the Shade was, and where they've arrived, are back or
-- have formed.
type Due = { kind: string, entity: number, at: number, from: vector?, to: vector? }

local me = Players.LocalPlayer
local world = RobloxWorld.new()
local due: { Due } = {}
-- Each enemy's From the Shadows over your minimap, by their entity: from
-- and until when (server time).
local covering: { [number]: { at: number, ends: number } } = {}
local up = false
local cursorAt: vector? = nil
-- Where the cursor was when it was last found whether fire would take you
-- there, when (os.clock()), whether it was the buy phase then, and whether
-- it would.
local judgedAt: vector? = nil
local judgedWhen = -math.huge
local judgedClosed = false
local placeable = false
local darkNow = 0
local grey: ColorCorrectionEffect? = nil

-- Whether From the Shadows' map is in your hand.
local function inHand(): boolean
	local s = PlayerController.sim
	if not s or not PlayerController.alive then
		return false
	end
	local w = s.weapons
	return w.equipped == WeaponSim.ULT and w.loadout[WeaponSim.ULT] == "shadowmap" and s.abilities.holding ~= 0
end

-- The mouse moving the cursor `delta` counts across the map.
local function moveCursor(delta: Vector2)
	local view, at, plan = ShadowView.view, cursorAt, PartsPlan.inPlay()
	if not view or not at or not plan then
		return
	end
	local moved = Minimap.fromView(view, delta.X * SPEED, delta.Y * SPEED) - Minimap.fromView(view, 0, 0)
	cursorAt = Minimap.held(plan, at + moved)
end

local function mapPoint(): vector?
	return if up then cursorAt else nil
end

-- Finds whether fire would take you to `at` again, once the cursor's moved,
-- the buy phase has begun or ended, or a moment's gone by: never in the buy
-- phase, as your simulation has it.
local function judge(at: vector)
	local walls = PlayerController.barriers
	local judged = if walls then walls(RemoteEntities.shownTime()) else nil
	local closed = judged ~= nil and judged.closed == true
	local last, clock = judgedAt, os.clock()
	if last and vector.magnitude(at - last) < MOVED and clock - judgedWhen < AGAIN and closed == judgedClosed then
		return
	end
	judgedAt, judgedWhen, judgedClosed = at, clock, closed
	local through = if judged then BarrierSim.world(world, judged.walls, judged.time) else world
	placeable = not closed and ShadowSim.place(through, at, PlayerController.cfg) ~= nil
end

local function playerOf(id: number): Player?
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == id then
			return player
		end
	end
	return nil
end

-- Whether an entity's on another side than yours.
local function isEnemy(id: number): boolean
	local player = playerOf(id)
	local mine = me:GetAttribute(ArenaConfig.SIDE)
	local theirs = if player then player:GetAttribute(ArenaConfig.SIDE) else nil
	return typeof(mine) == "number" and typeof(theirs) == "number" and mine ~= theirs
end

local function metres(v: any): vector?
	return if typeof(v) == "Vector3" then Units.toMetres(v) else nil
end

local function onEvent(event: any)
	if typeof(event) ~= "table" then
		return
	end
	if event.kind == "out" then
		table.clear(due)
		table.clear(covering)
		return
	end
	if event.ability ~= "fromtheshadows" or typeof(event.entity) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	local entity: number, at: number = event.entity, event.at
	if entity == PlayerController.entityId then
		-- Yours comes from your kit, but for an enemy's hit sending you back.
		local back = metres(event.to)
		if event.kind == "home" and event.broken == true and back then
			GameSounds.playCast("home", back)
		end
		return
	end
	if event.kind == "shadows" then
		StepView.swirl(entity, at, FS.windup.value)
		if isEnemy(entity) then
			covering[entity] = { at = at, ends = at + FS.windup.value + FS.shade.value }
		end
		return
	end
	local cover = covering[entity]
	if cover and (event.kind == "home" or event.kind == "form") then
		cover.ends = math.min(cover.ends, at)
	end
	local from, to = metres(event.from), metres(event.to)
	if event.kind == "form" then
		from, to = nil, metres(event.position)
	end
	if from or to then
		table.insert(due, { kind = event.kind, entity = entity, at = at, from = from, to = to })
	end
end

-- Another's event as the frame on your screen reaches it.
local function show(d: Due)
	local from, to = d.from, d.to
	if d.kind == "shade" then
		if from then
			StepView.puff(from)
		end
		if to then
			StepView.form(to)
			GameSounds.playCast("shade", to, d.entity)
		end
	elseif d.kind == "home" then
		if from then
			StepView.puff(from)
			GameSounds.playCast("home", from, d.entity)
		end
		if to then
			StepView.form(to)
			GameSounds.playCast("form", to, d.entity)
		end
	elseif d.kind == "form" and to then
		StepView.form(to)
	end
end

-- Whether From the Shadows' map is up.
function ShadowView.mapUp(): boolean
	return up
end

-- Where its cursor is (metres), while its map's up.
function ShadowView.cursor(): vector?
	return if up then cursorAt else nil
end

-- Whether fire would take you where the cursor is.
function ShadowView.placeable(): boolean
	return placeable
end

-- Where it's taking you, once it's fired, until you've formed there.
function ShadowView.going(): vector?
	local s = PlayerController.sim
	local kit = if s and PlayerController.alive then s.abilities else nil
	return if kit and kit.shadowAt > 0 then kit.shadowTo else nil
end

-- How covered your minimap is by an enemy's From the Shadows, 0 or 1.
function ShadowView.dark(): number
	return darkNow
end

-- Puts the cursor on the map nearest `point` (metres), as the mouse could
-- (TestAim's VFTestMapPoint). Returns whether its map was up to take it.
function ShadowView.setCursor(point: vector): boolean
	local plan = PartsPlan.inPlay()
	if not up or not plan then
		return false
	end
	cursorAt = Minimap.held(plan, point)
	return true
end

function ShadowView.start()
	-- Your windup's shadow closing in from the screen's edges (a stroke
	-- round a frame set in from them as far, drawn outwards over them).
	local gui = Ui.screen("VFShadow", 3, Enum.ScreenInsets.None)
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

	PlayerController.mapPoint = mapPoint
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		local s = PlayerController.sim
		local kit = if s and PlayerController.alive then s.abilities else nil
		local t = if s then s.movement.tick * DT else 0

		-- The map: up with it in hand, its cursor from where you stand.
		local wasUp = up
		up = inHand()
		if up and s and (not wasUp or not cursorAt) then
			local plan = PartsPlan.inPlay()
			cursorAt = if plan then Minimap.held(plan, s.movement.position) else nil
			judgedAt = nil
		elseif not up then
			cursorAt = nil
		end
		-- The mouse is its cursor's while it's up; once it's not, it's
		-- nobody's, unless it's a ping's (PingView).
		if up then
			CameraController.mapCursor = moveCursor
		elseif CameraController.mapCursor == moveCursor then
			CameraController.mapCursor = nil
		end
		local at = cursorAt
		if up and at then
			judge(at)
		end

		-- Yours: the windup's shadow at the edges, and as a Shade, the
		-- grey and the dark past how far you see.
		local closing = if kit and AbilitySim.gathering(kit, t) then 1 - (kit.shadowAt - t) / FS.windup.value else 0
		local inset = EDGE * closing
		edge.Size = UDim2.new(1, -2 * inset, 1, -2 * inset)
		edge.Position = UDim2.fromOffset(inset, inset)
		stroke.Thickness = inset
		stroke.Transparency = if closing > 0 then 0.55 - 0.3 * closing else 1
		local shaded = kit ~= nil and AbilitySim.shaded(kit, t)
		local sight = if kit and shaded then ShadowSim.sight(1 - (AbilitySim.formsAt(kit) - t) / FS.shade.value) else nil
		ParanoiaView.cap = if sight then math.max(sight, LEAST) else nil
		local camera = Workspace.CurrentCamera
		local g = grey
		if shaded and camera and not (g and g.Parent == camera) then
			if g then
				g:Destroy()
			end
			local made = Instance.new("ColorCorrectionEffect")
			made.Name = "VFShade"
			made.Saturation = GREY
			made.Parent = camera
			grey = made
		elseif not shaded and g then
			g:Destroy()
			grey = nil
		end

		-- Others', as the frame on your screen reaches them.
		local render = RemoteEntities.renderTime()
		local i = 1
		while i <= #due do
			local d = due[i]
			if render < d.at then
				i += 1
				continue
			end
			table.remove(due, i)
			if render - d.at < STALE then
				show(d)
			end
		end
		darkNow = 0
		for entity, cover in covering do
			if render >= cover.ends or RemoteEntities.healthOf(entity).health <= 0 then
				covering[entity] = nil
			elseif render >= cover.at then
				darkNow = 1
			end
		end

		gui:SetAttribute("Map", up)
		gui:SetAttribute("Cursor", if up and at then Units.asVector3(at) else nil)
		gui:SetAttribute("Placeable", up and placeable)
		gui:SetAttribute("Grey", shaded)
		gui:SetAttribute("Sight", if sight then math.floor(math.max(sight, LEAST) * 100 + 0.5) / 100 else -1)
		gui:SetAttribute("Dark", darkNow)
	end)
end

return ShadowView
