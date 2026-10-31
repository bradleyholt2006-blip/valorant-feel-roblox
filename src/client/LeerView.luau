--!strict
-- Reyna's Leer on the client (system 74): her eyes in flight and open, and
-- their breaking.
--   * your own fly here at once, as you cast them (PlayerController's
--     castListeners), through LeerSim as the server flies them, as far as
--     the level here lets them; the server's word on one changes nothing,
--     as nothing changes its path
--   * others' come from the server (the Ability remote's "flight"), flown
--     here the same way as the frame on your screen reaches the cast
--   * an eye is a ball of violet light, a dark pupil on it turned to the
--     camera, as it watches whoever looks at it: small and dim as it flies,
--     growing to its size and brightening as it opens, which sounds, and
--     fading as its time runs out
--   * one the server says broke ("break") bursts in a flash of its light,
--     with its sound, as the frame on your screen reaches it; one whose
--     caster's started a new life ("gone") just goes
-- The nearsight it gives is drawn by ParanoiaView, from the attribute it's
-- kept on. An eye past the dark drawn round your screen, a nearsight's or
-- a Shade's, shows through it (system 76), as a ball of light: it's drawn
-- just inside the dark, where and as big as it looks, unless the level or
-- a smoke hides it, so it can be shot, as the guides have players do with
-- an eye that's nearsighting them. The eyes standing are in the level your
-- shots are traced through (ClientShots.eyes), as the server's are in its
-- own. In Workspace's VFLeer each eye is an `Eye` ball with its `Pupil`
-- ball, and each burst a `Break` ball; they all go when the server says
-- every fire's out (a new round, "out"). VFLeer's `Eyes` attribute says
-- how many are drawn, which scripted checks read.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local LeerSim = require(Shared.Abilities.LeerSim)
local Penetration = require(Shared.Combat.Penetration)
local Sight = require(Shared.Combat.Sight)
local Minimap = require(Shared.Match.Minimap)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Remotes = require(Shared.Net.Remotes)
local SoundConfig = require(Shared.Audio.SoundConfig)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local CloudView = require(script.Parent.CloudView)
local ParanoiaView = require(script.Parent.ParanoiaView)
local ClientShots = require(script.Parent.Combat.ClientShots)
local GameSounds = require(script.Parent.Audio.GameSounds)

local LeerView = {}

local LE = AbilityConfig.Leer
local world = RobloxWorld.new()
local GLOW = Color3.fromRGB(196, 72, 236)
local PUPIL = Color3.fromRGB(40, 6, 52)
local OPEN_SEE = 0.2 -- how see-through the eye is, open (ours)
local CAST_SEE = 0.7 -- and as it flies
local SMALL = 0.35 -- its size as it's cast, of its size open (ours)
local PUPIL_SIZE = 0.4 -- the pupil's size, of the eye's
local PUPIL_OUT = 0.4 -- how far out its middle is from the eye's, of the eye's size
local LIGHT_RANGE = 4 -- metres its light reaches, open (ours)
local FADE = 0.3 -- seconds it fades over as its time runs out (ours)
local BURST = 0.25 -- seconds a break's flash lasts
local NEAR = 0.06 -- seconds your own is hidden for, so it doesn't fill the view leaving the eye
local STALE = 1 -- seconds: an opening or a break the screen is this far past isn't heard
local KEEP = 5 -- seconds your casts are remembered, so the server's word on one doesn't cast it again
-- Seconds an eye the server told of is kept for your shots after it's
-- gone, as the server keeps its own (ours: past SlowSim.LAG).
local AFTER = 2
-- How far in from the dark round your screen an eye past it is drawn, of
-- the dark's distance: inside its slabs, which are no more than 3% further
-- out.
local INSIDE = 0.95
-- Barriers a line from the camera goes through, at most (as HealView's).
local PASSES = 4

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = RobloxWorld.CHARACTER_GROUP
params.RespectCanCollide = true

-- An eye drawn: when it was cast on its clock, os.clock() for yours and
-- the render clock for others', when it broke or went on that clock, if
-- it has, and whether to burst then, and whether its opening's been
-- heard.
type Shown = {
	eye: LeerSim.Eye,
	start: number,
	own: boolean,
	ended: number?,
	burst: boolean,
	heard: boolean,
	ball: Part,
	pupil: Part,
	light: PointLight,
}

local shown: { [string]: Shown } = {}
local sent: { [string]: number } = {} -- your casts, by key, at os.clock()
-- The eyes the server's told of, on its clock, by caster and cast.
local standing: { LeerSim.Eye } = {}
local known: { [string]: LeerSim.Eye } = {}
local folder: Folder? = nil

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFLeer"
	made.Parent = Workspace
	folder = made
	return made
end

local function ball(name: string, colour: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = colour
	p.Transparency = 1
	p.Size = Vector3.one * LE.size.value * Units.STUDS_PER_METRE
	p.Parent = parent
	return p
end

local function keyOf(entity: number, id: number): string
	return if entity == PlayerController.entityId then "own:" .. id else entity .. ":" .. id
end

local function drop(key: string)
	local s = shown[key]
	if s then
		s.ball:Destroy()
		shown[key] = nil
	end
end

local function show(key: string, eye: LeerSim.Eye, start: number, own: boolean)
	drop(key)
	local shell = ball("Eye", GLOW, holder())
	local light = Instance.new("PointLight")
	light.Color = GLOW
	light.Brightness = 0
	light.Range = LIGHT_RANGE * Units.STUDS_PER_METRE
	light.Shadows = false
	light.Parent = shell
	shown[key] = {
		eye = eye,
		start = start,
		own = own,
		ended = nil,
		burst = false,
		heard = false,
		ball = shell,
		pupil = ball("Pupil", PUPIL, shell),
		light = light,
	}
end

-- A sound of the eye's out in the world at `at`: yours, or its caster's.
local function play(kind: string, at: vector, s: Shown)
	local sound = SoundConfig.Abilities[kind]
	if not sound then
		return
	end
	GameSounds.playWorld(sound, at, if s.own then "you" else RemoteEntities.nameOf(s.eye.owner))
end

-- An eye breaking at `at`: a flash of its light, gone in a moment.
local function burst(at: vector)
	local p = ball("Break", GLOW, holder())
	p.Size = Vector3.one * LE.size.value * 1.5 * Units.STUDS_PER_METRE
	p.CFrame = CFrame.new(Units.toStuds(at))
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - start) / BURST
		if k >= 1 or p.Parent == nil then
			conn:Disconnect()
			p:Destroy()
			return
		end
		p.Transparency = k
	end)
end

local function onOwnCast(cast: AbilitySim.Cast)
	if cast.kind ~= "leer" then
		return
	end
	local key = "own:" .. cast.tick
	sent[key] = os.clock()
	local travel = LeerSim.reach(world, cast.origin, cast.direction)
	show(key, LeerSim.cast(PlayerController.entityId, cast.tick, 0, cast.origin, cast.direction, travel), os.clock(), true)
end

-- Where the server's time `at` falls on the clock an eye's drawn on.
local function onClock(s: Shown, at: number): number
	return if s.own then os.clock() - (Workspace:GetServerTimeNow() - at) else at
end

local function onEvent(event: any)
	if typeof(event) == "table" and event.kind == "out" then
		for key in shown do
			drop(key)
		end
		table.clear(standing)
		table.clear(known)
		return
	end
	if typeof(event) ~= "table" or event.ability ~= "leer" then
		return
	end
	if typeof(event.entity) ~= "number" or typeof(event.id) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	local name = event.entity .. ":" .. event.id
	if event.kind == "break" or event.kind == "gone" then
		local eye = known[name]
		if eye then
			eye.broken = event.at
		end
		local s = shown[keyOf(event.entity, event.id)]
		if s and not s.ended then
			s.ended = onClock(s, event.at)
			s.burst = event.kind == "break"
		end
		return
	end
	if event.kind ~= "flight" or typeof(event.position) ~= "Vector3" or typeof(event.direction) ~= "Vector3" then
		return
	end
	local origin, way = Units.toMetres(event.position), Units.asVector(event.direction)
	local travel = if typeof(event.travel) == "number" then event.travel else nil
	if not known[name] then
		local eye = LeerSim.cast(event.entity, event.id, event.at, origin, way, travel)
		known[name] = eye
		table.insert(standing, eye)
	end
	local eye = LeerSim.cast(event.entity, event.id, 0, origin, way, travel)
	if event.entity ~= PlayerController.entityId then
		show(name, eye, event.at, false)
		return
	end
	-- Yours: cast here already, or the server's goes, on your clock.
	local key = "own:" .. event.id
	if sent[key] then
		return
	end
	sent[key] = os.clock()
	show(key, eye, os.clock() - (Workspace:GetServerTimeNow() - event.at), true)
end

-- Whether the level or a smoke standing at `render` (the render clock) is
-- in the way from `a` to `b` (metres), through the spawns' barriers, as for
-- the server's sight (FogServer).
local function hidden(a: vector, b: vector, render: number): boolean
	for _, cloud in CloudView.standing(render) do
		if Sight.cloudHides(cloud, a, b) then
			return true
		end
	end
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

-- Where to draw an eye whose middle is at `at`, seen from the camera at
-- `view`, and its size there, as a share of its own: just inside the dark
-- round your screen if it's past it and nothing hides it, else where it is.
local function seenAt(at: vector, view: vector?, render: number): (vector, number)
	local reach = ParanoiaView.reach
	if not view or reach == math.huge then
		return at, 1
	end
	local d = vector.magnitude(at - view)
	local inside = reach * INSIDE
	if d <= inside or hidden(view, at, render) then
		return at, 1
	end
	local share = inside / d
	return view + (at - view) * share, share
end

-- One eye, a frame on: `now` on its clock, `render` on the render clock.
-- False once it's gone.
local function frame(s: Shown, now: number, render: number, view: vector?): boolean
	local age = now - s.start
	local ended = s.ended
	if ended and now >= ended then
		if s.burst then
			local at = LeerSim.at(s.eye, ended - s.start)
			burst(at)
			if now - ended < STALE then
				play("leerbreak", at, s)
			end
		end
		return false
	end
	local windup = LE.windup.value
	local life = windup + LE.duration.value
	if age >= life then
		return false
	end
	if age < 0 or (s.own and age < NEAR) then
		-- Others' before the frame on your screen reaches the cast.
		s.ball.Transparency = 1
		s.pupil.Transparency = 1
		s.light.Brightness = 0
		return true
	end
	local open = math.clamp(age / windup, 0, 1)
	if open >= 1 and not s.heard then
		s.heard = true
		if age - windup < STALE then
			play("leeropen", LeerSim.rest(s.eye), s)
		end
	end
	local fade = math.clamp((life - age) / FADE, 0, 1)
	local at, share = seenAt(LeerSim.at(s.eye, age), view, render)
	local size = LE.size.value * (SMALL + (1 - SMALL) * open) * share
	local see = CAST_SEE + (OPEN_SEE - CAST_SEE) * open
	s.ball.Size = Vector3.one * size * Units.STUDS_PER_METRE
	s.ball.CFrame = CFrame.new(Units.toStuds(at))
	s.ball.Transparency = 1 - (1 - see) * fade
	-- Its light where it is, but not drawn in close.
	s.light.Brightness = if share < 1 then 0 else 2 * open * fade
	-- The pupil, on the side the camera's on.
	local toward = if view and vector.magnitude(view - at) > 1e-6 then vector.normalize(view - at) else -s.eye.way
	s.pupil.Size = Vector3.one * size * PUPIL_SIZE * Units.STUDS_PER_METRE
	s.pupil.CFrame = CFrame.new(Units.toStuds(at + toward * size * PUPIL_OUT))
	s.pupil.Transparency = 1 - fade
	return true
end

function LeerView.start()
	ClientShots.eyes = function(level: Penetration.Level, time: number): Penetration.Level
		return LeerSim.level(level, standing, time)
	end
	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()
		local camera = Workspace.CurrentCamera
		local view = if camera then Units.toMetres(camera.CFrame.Position) else nil
		local count = 0
		for key, s in shown do
			if frame(s, if s.own then clock else render, render, view) then
				count += 1
			else
				drop(key)
			end
		end
		for key, at in sent do
			if clock - at > KEEP then
				sent[key] = nil
			end
		end
		for i = #standing, 1, -1 do
			local eye = standing[i]
			if render > LeerSim.ends(eye) + AFTER then
				table.remove(standing, i)
				known[eye.owner .. ":" .. eye.id] = nil
			end
		end
		local f = holder()
		if f:GetAttribute("Eyes") ~= count then
			f:SetAttribute("Eyes", count)
		end
	end)
end

return LeerView
