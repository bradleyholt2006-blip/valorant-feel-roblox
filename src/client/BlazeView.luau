--!strict
-- Phoenix's Blaze on the client (system 32): walls of fire on their way,
-- and standing.
--   * Your own run here at once, on your predicted ticks
--     (PlayerController.tickListeners), through BlazeSim as the server runs
--     them, bent while your wall's being bent, and rise where the server's
--     will. When the server says where one rose (the Ability remote's
--     "wall"), it stands there instead if ours doesn't
--   * Others' come from the server: where each one's head is every few of
--     its ticks ("flight"), drawn as the frame on your screen reaches them,
--     then its wall ("wall")
--   * On its way it's a flame running over the floor, a line of fire on
--     the floor behind it. Its wall rises from the caster's end and spreads
--     along it to the far end, as the server's does: a sheet of flame
--     nothing shows through, the outlines (Highlights) included, with
--     flames along it, its glow and its crackle, and it falls once it's
--     over. From inside it the screen is flame. The burn and the heal are
--     the server's, and the glow round the screen's edge as you burn is
--     FireView's
-- In Workspace's VFWalls each run on its way is a `Run` model, and each
-- wall a `Wall` model while it stands: its `From` and `To` attributes are
-- its ends (metres), and `Moved` is set on one of yours that the server's
-- word moved. Everything goes when the server says every fire's out (a new
-- round, "out").
-- Nothing here is in anyone's way: shots, moves and throws go through a
-- wall of fire, as its parts can't be hit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local BlazeSim = require(Shared.Abilities.BlazeSim)
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

local BlazeView = {}

local BZ = AbilityConfig.Blaze
local DT = 1 / MovementConfig.TickRate.value
local S = Units.STUDS_PER_METRE
local FLAME = Color3.fromRGB(255, 120, 40)
local SHEET = Color3.fromRGB(255, 90, 20)
local CORE = Color3.fromRGB(255, 200, 90)
local UP = vector.create(0, 1, 0)
local RISE = 0.25 -- seconds a stretch of wall takes to rise once the fire reaches it (ours)
local FALL = 0.3 -- seconds it takes to fall once it's over (ours)
local LINE = 0.4 -- metres across its line of fire on the floor (ours)
local LIFT = 0.03 -- metres that line sits over the floor
local HEAD = 0.35 -- metres across the flame running at its head (ours)
local MOVE = 0.25 -- metres: the server's far end this far from ours moves our wall
local STALE = 1 -- seconds a run is drawn past the last word on it
local LIVE = 0.1 -- seconds without a predicted tick before your runs go on by themselves
local CRACKLE = 0.5 -- seconds from one of its crackles to the next (ours)
local FLAMES = 2 -- segments from one of its flames to the next
local LIGHTS = 4 -- segments from one of its lights to the next

type Frame = { at: number, position: vector }
-- A run on its way: its line of fire and its head.
type Trail = { model: Model, lines: { Part }, head: Part }
-- A wall standing: on the clock it's drawn on (os.clock() for yours, the
-- render clock for others').
type Shown = {
	wall: BlazeSim.Wall,
	own: boolean,
	entity: number,
	model: Model,
	sheets: { Part },
	flames: { Fire },
	risen: boolean,
	crackled: number,
}

local world = RobloxWorld.new()
local own: { BlazeSim.Run } = {}
local ownTrails: { [number]: Trail } = {}
local flights: { [string]: { frames: { Frame }, trail: Trail?, done: boolean } } = {}
local walls: { [string]: Shown } = {}
local lastLive = 0
local loose = 0 -- seconds your runs haven't run since your ticks stopped
local folder: Folder? = nil

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFWalls"
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

local function part(parent: Instance, name: string, colour: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	plain(p)
	p.Material = Enum.Material.Neon
	p.Color = colour
	p.Transparency = 1
	p.Size = Vector3.one * 0.05
	p.Parent = parent
	return p
end

local function light(parent: Instance, brightness: number, range: number)
	local l = Instance.new("PointLight")
	l.Color = FLAME
	l.Brightness = brightness
	l.Range = range * S
	l.Shadows = false
	l.Parent = parent
end

local function flame(parent: Instance, size: number): Fire
	local f = Instance.new("Fire")
	f.Color = FLAME
	f.SecondaryColor = CORE
	f.Size = size
	f.Heat = 12
	f.Enabled = false
	f.Parent = parent
	return f
end

-- A run's line of fire and its head, made as it's first drawn.
local function trail(): Trail
	local model = Instance.new("Model")
	model.Name = "Run"
	local head = part(model, "Head", FLAME)
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.one * HEAD * S
	flame(head, 4).Enabled = true
	light(head, 2, 6)
	model.Parent = holder()
	return { model = model, lines = {}, head = head }
end

-- A line of fire on the floor from `a` to `b` (metres) in `p`, or hidden if
-- it has no length.
local function lineAlong(p: Part, a: vector, b: vector)
	local d = b - a
	local length = vector.magnitude(d)
	if length < 1e-3 then
		p.Transparency = 1
		return
	end
	local lift = vector.create(0, LIFT, 0)
	local from, to = Units.toStuds(a + lift), Units.toStuds(b + lift)
	p.Size = Vector3.new(LINE * S, 0.05, length * S)
	p.CFrame = CFrame.lookAt((from + to) / 2, to)
	p.Transparency = 0.25
end

-- A run's line of fire through `points` to its head at `head` (metres).
local function drawTrail(t: Trail, points: { vector }, head: vector)
	local at = 0
	for i = 2, #points + 1 do
		local a = points[i - 1]
		local b = points[i] or head
		at += 1
		local line = t.lines[at]
		if not line then
			line = part(t.model, "Line", FLAME)
			t.lines[at] = line
		end
		lineAlong(line, a, b)
	end
	for i = at + 1, #t.lines do
		t.lines[i].Transparency = 1
	end
	t.head.CFrame = CFrame.new(Units.toStuds(head + vector.create(0, HEAD / 2, 0)))
	t.head.Transparency = 0.1
end

-- A wall named `key` standing on `wall`'s path, on the clock it's drawn on.
local function show(key: string, wall: BlazeSim.Wall, isOwn: boolean, entity: number): Shown
	local had = walls[key]
	if had then
		had.model:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Wall"
	model:SetAttribute("From", Units.asVector3(wall.points[1]))
	model:SetAttribute("To", Units.asVector3(wall.points[#wall.points]))
	local sheets: { Part } = {}
	local flames: { Fire } = {}
	for i = 2, #wall.points do
		local sheet = part(model, "Sheet", SHEET)
		table.insert(sheets, sheet)
		if (i - 2) % FLAMES == 0 then
			table.insert(flames, flame(sheet, 8))
		end
		if (i - 2) % LIGHTS == 0 then
			light(sheet, 1.5, 8)
		end
	end
	model.Parent = holder()
	local shown: Shown = {
		wall = wall,
		own = isOwn,
		entity = entity,
		model = model,
		sheets = sheets,
		flames = flames,
		risen = false,
		crackled = -math.huge,
	}
	walls[key] = shown
	return shown
end

local function forgetWall(key: string)
	local s = walls[key]
	if s then
		s.model:Destroy()
		walls[key] = nil
	end
end

-- The wall at `t`, `h` of its height at most each stretch: each stretch
-- from where the fire has reached, risen once it's there, an upright sheet
-- over its floor, high enough over both its ends; and its flames lit where
-- it stands. Hidden where the fire hasn't reached.
local function drawWall(s: Shown, t: number, h: number)
	local wall = s.wall
	local reach = BlazeSim.reachAt(wall, t)
	local thick = BZ.thickness.value
	for i = 2, #wall.points do
		local sheet = s.sheets[i - 1]
		local from = wall.along[i - 1]
		local span = wall.along[i] - from
		local rise = math.clamp((t - BlazeSim.reachedAt(wall, from)) / RISE, 0, 1)
		local tall = h * (1 - (1 - rise) * (1 - rise))
		if reach <= from + 1e-6 or tall < 1e-3 or span < 1e-6 then
			sheet.Transparency = 1
		else
			local a = wall.points[i - 1]
			local b = a + (wall.points[i] - a) * math.min((reach - from) / span, 1)
			local low = math.min(a.y, b.y)
			local high = math.max(a.y, b.y) + tall
			local way = vector.create(b.x - a.x, 0, b.z - a.z)
			local length = vector.magnitude(way)
			local mid = vector.create((a.x + b.x) / 2, (low + high) / 2, (a.z + b.z) / 2)
			-- Each a little longer than its stretch, so the bends don't gap.
			sheet.Size = Vector3.new(thick * S, (high - low) * S, (length + thick / 2) * S)
			sheet.CFrame = CFrame.lookAt(Units.toStuds(mid), Units.toStuds(mid + way / math.max(length, 1e-6)), Units.toStuds(UP))
			sheet.Transparency = 0
		end
		local f = sheet:FindFirstChildOfClass("Fire")
		if f then
			f.Enabled = sheet.Transparency < 1 and h >= BZ.height.value - 1e-6
		end
		local l = sheet:FindFirstChildOfClass("PointLight")
		if l then
			l.Enabled = sheet.Transparency < 1
		end
	end
end

-- One wall a frame on, at `t` on its clock: false once it has fallen.
local function frameWall(s: Shown, t: number, clock: number, eye: vector?): (boolean, boolean)
	local wall = s.wall
	local ends = BlazeSim.ends(wall)
	if t >= ends + FALL then
		return false, false
	end
	if t < wall.start then
		for _, sheet in s.sheets do
			sheet.Transparency = 1
		end
		return true, false
	end
	if not s.risen then
		s.risen = true
		if s.own and t - wall.start < STALE then
			GameSounds.playWorld(SoundConfig.Abilities.wall, wall.points[1], "you")
		end
	end
	local h = BZ.height.value
	if t >= ends then
		h *= 1 - (t - ends) / FALL
	end
	drawWall(s, t, h)
	local inside = false
	if eye and t < ends then
		inside = BlazeSim.inside(wall, eye, t, 0)
		if clock - s.crackled >= CRACKLE then
			local near = BlazeSim.nearest(wall, eye, t)
			if near then
				s.crackled = clock
				local at = near + vector.create(0, 1, 0)
				if s.own then
					GameSounds.playWorld(SoundConfig.Abilities.burning, at, "you")
				else
					GameSounds.playCast("burning", at, s.entity, true)
				end
			end
		end
	end
	return true, inside
end

local function forgetTrail(t: Trail?)
	if t then
		t.model:Destroy()
	end
end

-- One of your runs over: its wall, at once, if it ran anywhere.
local function riseOwn(r: BlazeSim.Run)
	forgetTrail(ownTrails[r.id])
	ownTrails[r.id] = nil
	local wall = BlazeSim.wall(r.owner, r.id, r.points, os.clock())
	if wall then
		show("own:" .. r.id, wall, true, r.owner)
	end
end

-- Each of your predicted ticks: your runs go on with its input, bent while
-- your wall's being bent, and its walls sent out join them.
local function onTick(info: any)
	lastLive = os.clock()
	loose = 0
	if #own == 0 and not info.casts then
		return
	end
	local bent = info.sim.abilities.steering ~= 0
	for _, r in BlazeSim.tick(own, PlayerController.entityId, info.input, info.casts, bent, DT, world) do
		riseOwn(r)
	end
end

-- The server's word on where one of your walls rose (`points`, metres, at
-- server time `at`).
local function onOwnWall(id: number, points: { vector }, at: number)
	local key = "own:" .. id
	local mine = walls[key]
	local far = points[#points]
	if mine then
		local ours = mine.wall.points
		if #ours == #points and vector.magnitude(ours[#ours] - far) <= MOVE then
			return
		end
	end
	-- Ours doesn't stand where the server's does, or didn't rise here: the
	-- server's stands, on your clock.
	for i, r in own do
		if r.id == id then
			table.remove(own, i)
			break
		end
	end
	forgetTrail(ownTrails[id])
	ownTrails[id] = nil
	local start = if mine then mine.wall.start else os.clock() - (Workspace:GetServerTimeNow() - at)
	local wall = BlazeSim.wall(PlayerController.entityId, id, points, start)
	if wall then
		local shown = show(key, wall, true, PlayerController.entityId)
		shown.model:SetAttribute("Moved", true)
		shown.risen = mine ~= nil
	end
end

local function pointsOf(sent: any): { vector }?
	if typeof(sent) ~= "table" or #sent < 2 then
		return nil
	end
	local out: { vector } = {}
	for _, point in sent do
		if typeof(point) ~= "Vector3" then
			return nil
		end
		table.insert(out, Units.asVector(point))
	end
	return out
end

-- Everything gone: every fire's out (a new round).
local function clearAll()
	for key in walls do
		forgetWall(key)
	end
	for id, t in ownTrails do
		forgetTrail(t)
		ownTrails[id] = nil
	end
	table.clear(own)
	for key, f in flights do
		forgetTrail(f.trail)
		flights[key] = nil
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
	if event.ability ~= "blaze" or typeof(event.entity) ~= "number" or typeof(event.id) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	local key = event.entity .. ":" .. event.id
	if event.kind == "flight" and typeof(event.point) == "Vector3" then
		if event.entity ~= PlayerController.entityId then
			local f = flights[key]
			if not f then
				f = { frames = {}, trail = nil, done = false }
				flights[key] = f
			end
			table.insert(f.frames, { at = event.at, position = Units.asVector(event.point) })
		end
	elseif event.kind == "wall" then
		local points = pointsOf(event.points)
		if not points then
			return
		end
		if event.entity == PlayerController.entityId then
			onOwnWall(event.id, points, event.at)
			return
		end
		local wall = BlazeSim.wall(event.entity, event.id, points, event.at)
		if wall then
			show(key, wall, false, event.entity)
		end
		local f = flights[key]
		if f then
			f.done = true
		end
	end
end

-- Where a run's head is at `now` from what the server said, and the points
-- of its path it has passed, if it's been sent out by then.
local function placeAt(frames: { Frame }, now: number): (vector?, { vector })
	local passed: { vector } = {}
	local first = frames[1]
	if not first or now < first.at then
		return nil, passed
	end
	for i, a in frames do
		if a.at > now then
			local before = frames[i - 1]
			local k = (now - before.at) / math.max(a.at - before.at, 1e-6)
			return before.position + (a.position - before.position) * k, passed
		end
		table.insert(passed, a.position)
	end
	return frames[#frames].position, passed
end

local function stepOwnLoose(frameDt: number)
	if #own == 0 or os.clock() - lastLive < LIVE then
		return
	end
	-- Your ticks have stopped (you died): your runs go straight on.
	loose = math.min(loose + frameDt, 0.25)
	while loose >= DT do
		loose -= DT
		local i = 1
		while i <= #own do
			local r = own[i]
			if BlazeSim.drift(r, DT, world) then
				table.remove(own, i)
				riseOwn(r)
			else
				i += 1
			end
		end
	end
end

-- The walls standing, for the minimap (system 34): each one's path as far
-- as the fire has spread, and its caster.
function BlazeView.standing(): { { points: { vector }, entity: number } }
	local render = RemoteEntities.renderTime()
	local clock = os.clock()
	local out = {}
	for _, s in walls do
		local t = if s.own then clock else render
		if BlazeSim.standing(s.wall, t) then
			table.insert(out, { points = BlazeSim.spreadPath(s.wall, t), entity = s.entity })
		end
	end
	return out
end

function BlazeView.start()
	-- From inside a wall, the screen is flame (under the HUD).
	local gui = Ui.screen("VFBlaze", 1, Enum.ScreenInsets.None)
	local screen = Ui.frame(gui, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = SHEET,
		BackgroundTransparency = 0.12,
		Visible = false,
	})

	table.insert(PlayerController.tickListeners, onTick)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function(frameDt)
		local render = RemoteEntities.renderTime()
		local clock = os.clock()
		stepOwnLoose(frameDt)

		local running: { [number]: boolean } = {}
		for _, r in own do
			running[r.id] = true
			local t = ownTrails[r.id]
			if not t then
				t = trail()
				ownTrails[r.id] = t
			end
			drawTrail(t, r.points, r.position)
		end
		for id, t in ownTrails do
			if not running[id] then
				forgetTrail(t)
				ownTrails[id] = nil
			end
		end

		for key, f in flights do
			local last = f.frames[#f.frames]
			local wall = walls[key]
			if (f.done and (not wall or render >= wall.wall.start)) or (not f.done and render - last.at > STALE) then
				forgetTrail(f.trail)
				flights[key] = nil
			else
				local head, passed = placeAt(f.frames, render)
				if head then
					local t = f.trail or trail()
					f.trail = t
					drawTrail(t, passed, head)
				end
			end
		end

		local camera = Workspace.CurrentCamera
		local eye = if camera then Units.toMetres(camera.CFrame.Position) else nil
		local inside = false
		for key, s in walls do
			local stands, within = frameWall(s, if s.own then clock else render, clock, eye)
			if not stands then
				forgetWall(key)
			elseif within then
				inside = true
			end
		end
		screen.Visible = inside
	end)
end

return BlazeView
