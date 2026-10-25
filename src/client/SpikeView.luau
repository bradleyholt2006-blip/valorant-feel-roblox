--!strict
-- The spike in the world (system 12), on this client: its model where it
-- lies or is planted, with a marker over it so it can be found; once
-- planted, its light flashing with each beep, faster as the end nears, and
-- the circle a defuser must stand in; and its blast, a dark sphere growing
-- from it out to 35 m that darkens the view of anyone it passes. Its beeps,
-- its defuse, its blast and its drop are heard from where it is
-- (GameSounds.playWorld).
--
-- The VALORANT Wiki's tells: its lights are light blue, and red while
-- someone defuses it, when its casing rises to the top; a defuse let go of
-- past the half leaves the casing halfway. With 7 seconds left, too few
-- for a whole defuse, a white sphere closes in round it and stays.
--
-- Everything is built here from plain parts (original stand-in art), lives
-- only on this client, never collides and is invisible to raycasts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Spike = require(Shared.Spike.Spike)
local SpikeSim = require(Shared.Spike.SpikeSim)
local SoundConfig = require(Shared.Audio.SoundConfig)
local Units = require(Shared.Units)

local ClientSpike = require(script.Parent.ClientSpike)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local GameSounds = require(script.Parent.Audio.GameSounds)

local SpikeView = {}

-- Whether the planted spike's light is up this frame (a beep), for the HUD.
SpikeView.lit = false

local P = Spike.Params
local BODY = Color3.fromRGB(38, 40, 46)
-- Its lights, bright on a beep and dim between: light blue, and red while
-- it's being defused.
local BLUE, DIM_BLUE = Color3.fromRGB(110, 200, 255), Color3.fromRGB(30, 60, 80)
local RED, DIM_RED = Color3.fromRGB(235, 70, 60), Color3.fromRGB(80, 32, 30)
local CASING_RISE = 0.12 -- metres the casing rises for a defuse (estimate)
local LAST_SECONDS = 7 -- with this long left the white sphere closes in (the VALORANT Wiki)
local CLOSE_TIME = 1 -- seconds it takes to close in (estimate)
local FLASH_TIME = 0.08 -- seconds the light stays up after a beep (estimate)
local BLAST_FADE = 1.5 -- seconds the sphere takes to fade once grown (estimate)
local DARK_TIME = 1.0 -- seconds the view takes to clear once the blast has passed (estimate)
local LATE = 0.25 -- seconds: a beep heard of later than this is skipped, not played late
local SOUND_LATE = 1 -- seconds: a defuse or blast heard of later than this plays nothing
local CENTRE = vector.create(0, 0.15, 0) -- the spike's middle, above where it rests

-- Where the beeps have got to: which plant, and the next beep to play.
local beeps = Spike.beepTimes()
local beepsFor: number? = nil
local nextBeep = 1
local flashUntil = 0
-- The state last drawn, to act on changes: the defuse's and the blast's sounds.
local lastState = "none"
local lastEnded = 0
local darkFrom: number? = nil -- os.clock() the blast passed the camera
local darkenedFor: number? = nil -- the blast that did it (its server time)

local function part(parent: Instance, name: string, size: vector, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = Units.toStuds(size)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function SpikeView.start()
	local folder = Instance.new("Folder")
	folder.Name = "VFSpike"

	-- The spike: a squat case with a band of light round it and a cap.
	local model = Instance.new("Model")
	model.Name = "Spike"
	local body = part(model, "Case", vector.create(0.24, 0.3, 0.24), BODY)
	local band = part(model, "Band", vector.create(0.26, 0.05, 0.26), DIM_BLUE, Enum.Material.Neon)
	local cap = part(model, "Cap", vector.create(0.14, 0.05, 0.14), BODY)
	local light = Instance.new("PointLight")
	light.Color = BLUE
	light.Range = 10
	light.Brightness = 3
	light.Enabled = false
	light.Parent = band
	-- A marker over it, through walls, so it can be found.
	local marker = Instance.new("BillboardGui")
	marker.Name = "Marker"
	marker.AlwaysOnTop = true
	marker.Size = UDim2.fromOffset(90, 22)
	marker.StudsOffsetWorldSpace = Vector3.new(0, 1.2 * Units.STUDS_PER_METRE, 0)
	marker.LightInfluence = 0
	marker.Adornee = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextStrokeTransparency = 0.4
	label.TextColor3 = RED
	label.Text = "SPIKE"
	label.Parent = marker
	marker.Parent = body

	-- The circle a defuser must stand in, flat on the ground.
	local radius = P.defuseRange.value
	local ring = part(folder, "DefuseCircle", vector.create(0.02, radius * 2, radius * 2), Color3.new(1, 1, 1), Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	ring.Transparency = 0.85

	-- The last seconds' white sphere, and the blast.
	local last = part(folder, "LastSeconds", vector.create(1, 1, 1), Color3.new(1, 1, 1))
	last.Shape = Enum.PartType.Ball
	last.Transparency = 0.8
	local sphere = part(folder, "Blast", vector.create(1, 1, 1), Color3.fromRGB(12, 12, 18))
	sphere.Shape = Enum.PartType.Ball
	local dark = Instance.new("ColorCorrectionEffect")
	dark.Name = "VFSpikeBlast"
	dark.Enabled = false

	folder.Parent = Workspace

	-- `rise`: how far up the casing is, 0 to 1.
	local function place(at: vector, rise: number)
		local base = Units.toStuds(at)
		local function put(p: BasePart, height: number)
			p.CFrame = CFrame.new(base + Vector3.new(0, height * Units.STUDS_PER_METRE, 0))
		end
		put(body, 0.15)
		put(band, 0.2)
		put(cap, 0.325 + CASING_RISE * rise)
	end

	-- Whether anyone is defusing it: you, or anyone drawn defusing.
	local function defusing(): boolean
		local sim = PlayerController.sim
		if sim and PlayerController.alive and sim.spike.channel == SpikeSim.DEFUSING then
			return true
		end
		local t = RemoteEntities.renderTime()
		for _, id in RemoteEntities.ids() do
			local pose = if RemoteEntities.isPresent(id) then RemoteEntities.sample(id, t) else nil
			if pose and pose.alive and pose.channel == SpikeSim.DEFUSING then
				return true
			end
		end
		return false
	end

	RunService.RenderStepped:Connect(function()
		local view = ClientSpike.view()
		local now = Workspace:GetServerTimeNow()
		local at = view.position
		local state = view.state
		local shown = at ~= nil and (state == "dropped" or state == "planted" or state == "defused")
		local beingDefused = state == "planted" and defusing()
		model.Parent = if shown then folder else nil
		if at and shown then
			place(at, if beingDefused then 1 elseif state == "planted" and view.halfSaved then 0.5 else 0)
		end
		marker.Enabled = state == "dropped" or state == "planted"
		label.Text = if state == "planted" then "SPIKE PLANTED" else "SPIKE"
		ring.Parent = if at and state == "planted" then folder else nil
		if at and state == "planted" then
			ring.CFrame = CFrame.new(Units.toStuds(at + vector.create(0, 0.01, 0))) * CFrame.Angles(0, 0, math.rad(90))
		end

		-- The beeps, from the plant to the end, each with a flash.
		if state == "planted" and at then
			local since = now - view.plantedAt
			if beepsFor ~= view.plantedAt then
				beepsFor = view.plantedAt
				nextBeep = 1
			end
			while nextBeep <= #beeps and beeps[nextBeep] <= since do
				if since - beeps[nextBeep] <= LATE then
					GameSounds.playWorld(SoundConfig.Spike.beep, at + CENTRE, "spike")
					flashUntil = os.clock() + FLASH_TIME
				end
				nextBeep += 1
			end
		end
		local lit = state == "planted" and os.clock() < flashUntil
		band.Color = if beingDefused then (if lit then RED else DIM_RED) else (if lit then BLUE else DIM_BLUE)
		light.Color = if beingDefused then RED else BLUE
		light.Enabled = lit
		SpikeView.lit = lit

		-- Too late for a whole defuse: the white sphere closes in and stays.
		local closing = false
		if state == "planted" and at then
			local into = now - view.plantedAt - (P.detonateTime.value - LAST_SECONDS)
			if into >= 0 then
				closing = true
				local k = math.clamp(into / CLOSE_TIME, 0, 1)
				local r = 4 - 2.8 * k * k * (3 - 2 * k)
				last.Size = Units.toStuds(vector.create(1, 1, 1) * (r * 2))
				last.CFrame = CFrame.new(Units.toStuds(at + CENTRE))
			end
		end
		last.Parent = if closing then folder else nil

		-- Let go of (dropped, or its carrier killed): a thud where it lands.
		if state == "dropped" and lastState == "carried" and at then
			GameSounds.playWorld(SoundConfig.Spike.drop, at + CENTRE, "spike")
		end

		-- What it ended in, heard once, as it happens.
		if (state ~= lastState or view.endedAt ~= lastEnded) and at and now - view.endedAt < SOUND_LATE then
			if state == "defused" then
				GameSounds.playWorld(SoundConfig.Spike.defused, at + CENTRE, "spike")
			elseif state == "detonated" then
				GameSounds.playWorld(SoundConfig.Spike.blast, at + CENTRE, "spike")
			end
		end
		lastState, lastEnded = state, view.endedAt

		-- The blast grows to its edge, then fades; anyone it passes sees dark.
		local blasting = false
		if state == "detonated" and at then
			local since = now - view.endedAt
			local grow = P.blastGrowTime.value
			if since >= 0 and since < grow + BLAST_FADE then
				blasting = true
				local r = P.blastRadius.value * math.clamp(since / grow, 0, 1)
				sphere.Size = Units.toStuds(vector.create(1, 1, 1) * math.max(r * 2, 0.1))
				sphere.CFrame = CFrame.new(Units.toStuds(at))
				sphere.Transparency = 0.35 + 0.65 * math.clamp((since - grow) / BLAST_FADE, 0, 1)
				local camera = Workspace.CurrentCamera
				local eye = Units.toMetres(camera.CFrame.Position)
				if darkenedFor ~= view.endedAt and vector.magnitude(eye - at) <= r then
					darkenedFor = view.endedAt
					darkFrom = os.clock()
				end
			end
		end
		sphere.Parent = if blasting then folder else nil
		local from = darkFrom
		if from then
			local k = 1 - (os.clock() - from) / DARK_TIME
			if k <= 0 then
				darkFrom = nil
				dark.Enabled = false
			else
				dark.Parent = Workspace.CurrentCamera
				dark.Enabled = true
				dark.Brightness = -0.5 * k
				dark.Saturation = -0.6 * k
			end
		end
	end)
end

return SpikeView
