--!strict
-- Visual feedback for firing: a stand-in weapon model, muzzle flash, tracers,
-- impact marks and other players' shots.
--
-- Everything is built from plain parts (original placeholder art), lives only
-- on this client, never collides and is invisible to raycasts.
--
-- The local player's tracers and impacts come from the client's own trace
-- (ClientShots), so they appear on the tick the shot fires. Impact marks on
-- level geometry stay up (newest MAX_MARKS) so a spray against the backstop
-- leaves its pattern for comparison with reference footage. Backspace clears
-- them.
--
-- Hits on characters follow Patch 1.07: a small client-predicted spark
-- appears at once where the shot met the target as drawn ("DOES NOT mean
-- your shot has registered on the server (similar to tracers)"), and the hit
-- confirm only comes with the server's verdict, spawned "at the location of
-- the hit on the character" and staying attached to it as the character
-- moves, turns or crouches.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)
local Hitboxes = require(Shared.Combat.Hitboxes)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerController = require(script.Parent.Parent.PlayerController)
local RemoteEntities = require(script.Parent.Parent.RemoteEntities)
local NetSim = require(script.Parent.Parent.NetSim)
local ClientShots = require(script.Parent.ClientShots)

local S = Units.STUDS_PER_METRE
local DT = 1 / MovementConfig.TickRate.value
local MAX_MARKS = 80

local WeaponEffects = {}

-- Viewmodel -----------------------------------------------------------------

type Piece = { size: vector, offset: vector, accent: boolean? } -- metres, relative to the grip
type Shape = { muzzle: vector, pieces: { Piece } }

local SHAPES: { [string]: Shape } = {
	rifle = {
		muzzle = vector.create(0, 0.03, -0.56),
		pieces = {
			{ size = vector.create(0.06, 0.09, 0.42), offset = vector.create(0, 0.02, -0.13) }, -- receiver
			{ size = vector.create(0.028, 0.028, 0.2), offset = vector.create(0, 0.03, -0.44) }, -- barrel
			{ size = vector.create(0.04, 0.14, 0.07), offset = vector.create(0, -0.09, -0.13), accent = true }, -- magazine
			{ size = vector.create(0.05, 0.08, 0.18), offset = vector.create(0, 0, 0.17) }, -- stock
			{ size = vector.create(0.035, 0.1, 0.04), offset = vector.create(0, -0.07, 0.03) }, -- grip
			{ size = vector.create(0.02, 0.03, 0.05), offset = vector.create(0, 0.08, -0.05), accent = true }, -- sight
		},
	},
	sniper = {
		muzzle = vector.create(0, 0.03, -0.78),
		pieces = {
			{ size = vector.create(0.065, 0.09, 0.5), offset = vector.create(0, 0.02, -0.15) },
			{ size = vector.create(0.03, 0.03, 0.36), offset = vector.create(0, 0.03, -0.58) },
			{ size = vector.create(0.05, 0.05, 0.26), offset = vector.create(0, 0.1, -0.12), accent = true }, -- scope
			{ size = vector.create(0.05, 0.09, 0.2), offset = vector.create(0, 0, 0.2) },
			{ size = vector.create(0.035, 0.1, 0.04), offset = vector.create(0, -0.07, 0.03) },
		},
	},
	pistol = {
		muzzle = vector.create(0, 0.03, -0.2),
		pieces = {
			{ size = vector.create(0.035, 0.05, 0.19), offset = vector.create(0, 0.03, -0.08) }, -- slide
			{ size = vector.create(0.032, 0.11, 0.05), offset = vector.create(0, -0.04, 0.0), accent = true }, -- grip
		},
	},
	knife = {
		muzzle = vector.create(0, 0, -0.25),
		pieces = {
			{ size = vector.create(0.012, 0.035, 0.2), offset = vector.create(0, 0, -0.15), accent = true }, -- blade
			{ size = vector.create(0.028, 0.03, 0.1), offset = vector.create(0, 0, 0) }, -- handle
		},
	},
}

local SHAPE_OF: { [string]: string } = {
	vandal = "rifle",
	phantom = "rifle",
	operator = "sniper",
	classic = "pistol",
	sheriff = "pistol",
	knife = "knife",
}

local ACCENT: { [string]: Color3 } = {
	vandal = Color3.fromRGB(200, 70, 60),
	phantom = Color3.fromRGB(60, 170, 170),
	operator = Color3.fromRGB(140, 90, 200),
	classic = Color3.fromRGB(150, 150, 160),
	sheriff = Color3.fromRGB(210, 170, 70),
	knife = Color3.fromRGB(190, 195, 205),
}
local BODY = Color3.fromRGB(38, 40, 46)

-- Where the grip sits relative to the eye (metres, camera space).
local HIP = vector.create(0.17, -0.17, -0.36)
local ADS = vector.create(0, -0.075, -0.3)
local ADS_BLEND_TIME = 0.12

local function effectPart(name: string, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	return p
end

type Viewmodel = { weapon: string, shape: Shape, parts: { { part: Part, offset: CFrame } }, model: Model }

local viewmodel: Viewmodel? = nil
local kick = 0
local adsBlend = 0
local flash: Part? = nil
local flashUntil = 0

local function buildViewmodel(weaponId: string): Viewmodel
	local shape = SHAPES[SHAPE_OF[weaponId] or "rifle"]
	local model = Instance.new("Model")
	model.Name = "VFViewmodel"
	local parts = {}
	for _, piece in shape.pieces do
		local p = effectPart("Piece", if piece.accent then ACCENT[weaponId] or BODY else BODY)
		p.Size = Units.toStuds(piece.size)
		p.Parent = model
		table.insert(parts, { part = p, offset = CFrame.new(Units.toStuds(piece.offset)) })
	end
	model.Parent = Workspace.CurrentCamera
	return { weapon = weaponId, shape = shape, parts = parts, model = model }
end

local function viewmodelFor(weaponId: string): Viewmodel
	local current = viewmodel
	if current and current.weapon == weaponId and current.model.Parent then
		return current
	end
	if current then
		current.model:Destroy()
	end
	local built = buildViewmodel(weaponId)
	viewmodel = built
	return built
end

-- Grip transform this frame, in camera space (studs).
local function holdCFrame(sim: PlayerSim.State, frameDt: number): (CFrame, boolean)
	local w = sim.weapons
	local def = PlayerSim.def(sim)
	local t = sim.movement.tick * DT
	local zoom = if w.scoped > 0 and def.ads then def.ads.zoom[w.scoped] else 1
	local hidden = zoom >= 2 -- a real scope replaces the view

	local target = if zoom > 1 then 1 else 0
	adsBlend += (target - adsBlend) * math.min(frameDt / ADS_BLEND_TIME * 3, 1)
	kick *= math.exp(-frameDt * 18)

	-- Drawing: comes up from below over the equip time.
	local equipLeft = math.clamp((w.equipEndTime - t) / math.max(def.equipTime.value, 1e-3), 0, 1)
	-- Reloading: dips and rolls for the middle of the reload.
	local reloadDip = 0
	if w.reloadEndTime > 0 then
		local progress = 1 - math.clamp((w.reloadEndTime - t) / math.max(def.reloadTime.value, 1e-3), 0, 1)
		reloadDip = math.sin(progress * math.pi)
	end

	local hold = HIP + (ADS - HIP) * adsBlend
	local offset = hold + vector.create(0, -0.22 * equipLeft - 0.08 * reloadDip, 0.03 * kick)
	local angles = CFrame.Angles(math.rad(5 * kick) - math.rad(50) * equipLeft - math.rad(15) * reloadDip, 0, math.rad(35) * reloadDip)
	return CFrame.new(Units.toStuds(offset)) * angles, hidden
end

local function updateViewmodel(frameDt: number)
	local sim = PlayerController.sim
	if not sim or not PlayerController.alive then
		local current = viewmodel
		if current then
			current.model.Parent = nil
		end
		return
	end
	local def = PlayerSim.def(sim)
	local vm = viewmodelFor(def.id)
	vm.model.Parent = Workspace.CurrentCamera
	local hold, hidden = holdCFrame(sim, frameDt)
	local grip = Workspace.CurrentCamera.CFrame * hold
	for _, entry in vm.parts do
		entry.part.CFrame = grip * entry.offset
		entry.part.LocalTransparencyModifier = if hidden then 1 else 0
	end
	local f = flash
	if f then
		f.CFrame = grip * CFrame.new(Units.toStuds(vm.shape.muzzle))
		f.Transparency = if os.clock() < flashUntil and not hidden then 0.1 else 1
		local light = f:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = os.clock() < flashUntil
		end
	end
end

-- World position of the muzzle right now (studs), for tracers.
function WeaponEffects.muzzlePosition(): Vector3
	local vm = viewmodel
	if vm and vm.model.Parent and #vm.parts > 0 then
		return (vm.parts[1].part.CFrame * vm.parts[1].offset:Inverse() * CFrame.new(Units.toStuds(vm.shape.muzzle))).Position
	end
	return Workspace.CurrentCamera.CFrame.Position
end

-- Short-lived effects ---------------------------------------------------------

type Fade = { part: BasePart, start: number, duration: number, from: number }
local fades: { Fade } = {}
local effectsFolder: Folder? = nil
local marksFolder: Folder? = nil
local marks: { BasePart } = {}

local function fade(part: BasePart, duration: number, from: number)
	part.Transparency = from
	part.Parent = effectsFolder
	table.insert(fades, { part = part, start = os.clock(), duration = duration, from = from })
end

local function tracer(from: Vector3, to: Vector3, color: Color3, width: number)
	local length = (to - from).Magnitude
	if length < 1e-3 then
		return
	end
	local p = effectPart("Tracer", color, Enum.Material.Neon)
	p.Size = Vector3.new(width * S, width * S, length)
	p.CFrame = CFrame.lookAt((from + to) / 2, to)
	fade(p, 0.07, 0.25)
end

local function mark(point: vector, normal: vector)
	local p = effectPart("Mark", Color3.fromRGB(20, 20, 24))
	p.Size = Vector3.new(0.04 * S, 0.04 * S, 0.004 * S)
	local at = Units.toStuds(point + normal * 0.003)
	p.CFrame = CFrame.lookAt(at, at + Units.asVector3(normal))
	p.Parent = marksFolder
	table.insert(marks, p)
	if #marks > MAX_MARKS then
		local oldest = table.remove(marks, 1)
		if oldest then
			oldest:Destroy()
		end
	end
end

local function spark(point: vector, color: Color3, size: number)
	local p = effectPart("Spark", color, Enum.Material.Neon)
	p.Size = Vector3.one * size * S
	p.CFrame = CFrame.new(Units.toStuds(point))
	fade(p, 0.15, 0)
end

function WeaponEffects.clearMarks()
	for _, m in marks do
		m:Destroy()
	end
	table.clear(marks)
end

-- Shots fire inside the controller's render step, before this frame's camera
-- is placed, so they are queued and drawn after the viewmodel has moved.
local queued: { ClientShots.Record } = {}

local function drawShot(record: ClientShots.Record)
	kick += 1
	flashUntil = os.clock() + 0.035
	local outcome = record.predicted
	local from = WeaponEffects.muzzlePosition()
	tracer(from, Units.toStuds(outcome.point), Color3.fromRGB(255, 220, 140), 0.012)
	if outcome.targetId then
		spark(outcome.point, Color3.fromRGB(255, 240, 200), 0.02) -- client-predicted, not a hit
	elseif outcome.normal then
		mark(outcome.point, outcome.normal)
	end
end

-- Server hit confirms, each pinned to a spot on a region's box.
local CONFIRM_TIME = 0.35
local CONFIRM_COLOR = Color3.fromRGB(200, 30, 40)
type Confirm = { id: number, region: Hitboxes.Region, fraction: vector, start: number, size: number, part: BasePart }
local confirms: { Confirm } = {}

local function onVerdict(record: ClientShots.Record)
	local verdict = record.verdict
	if not verdict or not verdict.targetId or not verdict.region then
		return
	end
	RemoteEntities.flashRegion(verdict.targetId, verdict.region)
	-- Where on the target, from the pose the server hit.
	local tested = verdict.tested[verdict.targetId]
	local hitPoint = verdict.hitPoint
	local region: Hitboxes.Region = verdict.region :: Hitboxes.Region
	local box = if tested then Hitboxes.region(tested.pose, region) else nil
	if not box or not hitPoint then
		return
	end
	local confirm: Confirm = {
		id = verdict.targetId,
		region = region,
		fraction = Hitboxes.boxFraction(box, hitPoint),
		start = os.clock(),
		size = if region == "head" then 0.07 else 0.08, -- Patch 1.07 scaled headshot effects down slightly
		part = effectPart("HitConfirm", CONFIRM_COLOR, Enum.Material.Neon),
	}
	table.insert(confirms, confirm)
end

local function updateConfirms()
	local now = os.clock()
	local renderTime = RemoteEntities.renderTime()
	for i = #confirms, 1, -1 do
		local c = confirms[i]
		local t = (now - c.start) / CONFIRM_TIME
		local pose = if RemoteEntities.isPresent(c.id) then RemoteEntities.sample(c.id, renderTime) else nil
		local box = if pose and t < 1 then Hitboxes.region({ position = pose.position, yaw = pose.yaw, crouchAlpha = pose.crouchAlpha }, c.region) else nil
		if not box then
			c.part:Destroy()
			table.remove(confirms, i)
			continue
		end
		c.part.Size = Vector3.one * c.size * (1 + t) * S
		c.part.CFrame = CFrame.new(Units.toStuds(Hitboxes.boxPoint(box, c.fraction)))
		c.part.Transparency = 0.1 + 0.9 * t
		c.part.Parent = effectsFolder
	end
end

local function onShotFx(fx: any)
	if typeof(fx) ~= "table" or typeof(fx.from) ~= "Vector3" or typeof(fx.to) ~= "Vector3" then
		return
	end
	tracer(fx.from, fx.to, Color3.fromRGB(150, 200, 255), 0.01)
	if not fx.hit then
		spark(Units.toMetres(fx.to), Color3.fromRGB(200, 200, 200), 0.03)
	end
end

function WeaponEffects.start()
	local folder = Instance.new("Folder")
	folder.Name = "VFEffects"
	folder.Parent = Workspace
	effectsFolder = folder
	local marksF = Instance.new("Folder")
	marksF.Name = "VFImpactMarks"
	marksF.Parent = Workspace
	marksFolder = marksF

	local f = effectPart("MuzzleFlash", Color3.fromRGB(255, 210, 120), Enum.Material.Neon)
	f.Size = Vector3.new(0.05, 0.05, 0.09) * S
	f.Transparency = 1
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 8
	light.Color = f.Color
	light.Enabled = false
	light.Parent = f
	f.Parent = Workspace.CurrentCamera
	flash = f

	table.insert(ClientShots.firedListeners, function(record)
		table.insert(queued, record)
	end)
	table.insert(ClientShots.verdictListeners, onVerdict)
	NetSim.on(Remotes.get().ShotFx, onShotFx)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Backspace then
			WeaponEffects.clearMarks()
		end
	end)

	-- After the camera (Camera + 1) and remote entities (Camera + 2).
	RunService:BindToRenderStep("VFWeaponEffects", Enum.RenderPriority.Camera.Value + 4, function(frameDt)
		updateViewmodel(frameDt)
		for _, record in queued do
			drawShot(record)
		end
		table.clear(queued)
		updateConfirms()
		local now = os.clock()
		for i = #fades, 1, -1 do
			local e = fades[i]
			local t = (now - e.start) / e.duration
			if t >= 1 then
				e.part:Destroy()
				table.remove(fades, i)
			else
				e.part.Transparency = e.from + (1 - e.from) * t
			end
		end
	end)
end

return WeaponEffects
