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
-- Walls follow the reference's two cues: a bullet that goes through leaves a
-- hole with "a puff of white smoke" (and a hole where it comes out), one
-- that doesn't makes an orange spark (TheGamer's wallbang guide). A bullet
-- that stops inside a wall counts as not going through. Other players' shots
-- are traced through the level again here to draw their holes.
--
-- Hits on characters follow Patch 1.07: a small client-predicted spark
-- appears at once where the shot met the target as drawn ("DOES NOT mean
-- your shot has registered on the server (similar to tracers)"), and the hit
-- confirm only comes with the server's verdict, spawned "at the location of
-- the hit on the character" and staying attached to it as the character
-- moves, turns or crouches.
--
-- The knife (system 10) swings across the view, each slash of its combo its
-- own way, and stabs forward. Where the client's guess has it strike the
-- level it leaves a cut at once (Patch 4.01: "Knifing walls now has instant
-- feedback when slicing up walls"), and others' swings leave theirs; its hit
-- confirm comes with the server's verdict, as a bullet's does.
--
-- The spike (system 12) is held low and tipped toward the ground while it's
-- planted, and a defuse puts the weapon away until it ends.
--
-- Blade Storm's knives (system 19) have no flash and no kick: the hand
-- snaps forward as each goes, and each leaves a pale streak where it flew,
-- wider and longer lasting than a bullet's tracer. Others' do too.
--
-- A wall of Sage's (system 38) stops every bullet and blade, and leaves no
-- mark, as it goes in a while: what strikes it chips ice off it instead.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerSim = require(Shared.PlayerSim)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local SpikeSim = require(Shared.Spike.SpikeSim)
local Hitboxes = require(Shared.Combat.Hitboxes)
local Penetration = require(Shared.Combat.Penetration)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local BarrierSim = require(Shared.Abilities.BarrierSim)
local DroneSim = require(Shared.Abilities.DroneSim)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local PlayerController = require(script.Parent.Parent.PlayerController)
local RemoteEntities = require(script.Parent.Parent.RemoteEntities)
local NetSim = require(script.Parent.Parent.NetSim)
local ClientShots = require(script.Parent.ClientShots)
local ClientMelee = require(script.Parent.ClientMelee)
local WeaponLooks = require(script.Parent.WeaponLooks)

local S = Units.STUDS_PER_METRE
local DT = 1 / MovementConfig.TickRate.value
local MAX_MARKS = 80

local WeaponEffects = {}

-- Viewmodel -----------------------------------------------------------------

type Shape = WeaponLooks.Shape

-- Where the grip sits relative to the eye (metres, camera space).
local HIP = vector.create(0.17, -0.17, -0.36)
local ADS = vector.create(0, -0.075, -0.3)
local ADS_BLEND_TIME = 0.12

-- The knife's swing (stand-in animation): out fast over STRIKE_TIME, since
-- the swing is decided on the tick it starts, then back to rest by
-- SWING_TIME.
local STRIKE_TIME = 0.1
local SWING_TIME = 0.35

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
local flick = 0 -- 0 to 1: the hand snapping forward as a knife is thrown
local adsBlend = 0
local plantBlend = 0 -- 0 to 1: the spike held low, going down, while planting
local flash: Part? = nil
local flashUntil = 0

local function buildViewmodel(weaponId: string): Viewmodel
	local shape = WeaponLooks.shape(weaponId)
	local model = Instance.new("Model")
	model.Name = "VFViewmodel"
	local parts = {}
	for _, piece in shape.pieces do
		local p = effectPart("Piece", WeaponLooks.colour(weaponId, piece))
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

-- Where a knife swing has the grip `since` seconds in (camera space,
-- metres), and its turn. The slashes of the combo go right to left (1), left
-- to right (2) and down from the top right (3); a stab (0) thrusts forward.
local function swingPose(combo: number, since: number): (vector, CFrame)
	if since < 0 or since >= SWING_TIME then
		return vector.zero, CFrame.identity
	end
	local strike = math.clamp(since / STRIKE_TIME, 0, 1)
	local back = math.clamp((since - STRIKE_TIME) / (SWING_TIME - STRIKE_TIME), 0, 1)
	local hold = 1 - back * back * (3 - 2 * back) -- 1 through the strike, easing to 0
	if combo == 0 then
		local out = math.sin(strike * math.pi / 2) * hold
		return vector.create(-0.06, 0.04, -0.2) * out, CFrame.Angles(math.rad(-8) * out, math.rad(10) * out, 0)
	end
	local from = if combo == 2 then -1 else 1 -- +1: from the right
	local ease = strike * strike * (3 - 2 * strike)
	local side = from * (1 - 2 * ease)
	local drop = if combo == 3 then 1 else 0
	local amount = math.min(strike * 4, 1) * hold
	local offset = vector.create(-0.15 + 0.2 * side, 0.03 + 0.1 * drop * side, -0.05) * amount
	-- The blade turned across the view, leading the way it goes.
	return offset, CFrame.Angles(0, math.rad(75) * from * amount, (math.rad(25) * side + math.rad(30) * drop) * amount)
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
	flick *= math.exp(-frameDt * 12)

	-- Drawing: comes up from below over the equip time.
	local equipLeft = math.clamp((w.equipEndTime - t) / math.max(def.equipTime.value, 1e-3), 0, 1)
	-- Reloading: dips and rolls for the middle of the reload, or of each
	-- round for a gun that loads a round at a time.
	local reloadDip = 0
	if w.reloadEndTime > 0 then
		local slot = w.equipped
		local step = WeaponSim.reloadStep(def, w.ammo[slot], w.reserve[slot])
		local progress = 1 - math.clamp((w.reloadEndTime - t) / math.max(step, 1e-3), 0, 1)
		reloadDip = if def.reloadPerRound then 0.6 + 0.4 * math.sin(progress * math.pi) else math.sin(progress * math.pi)
	end

	local swingOffset, swingTurn = vector.zero, CFrame.identity
	if def.melee then
		swingOffset, swingTurn = swingPose(w.combo, t - w.lastShotTime)
	end
	-- Planting: the spike held out low and tipped toward the ground.
	local planting = if sim.spike.channel == SpikeSim.PLANTING then 1 else 0
	plantBlend += (planting - plantBlend) * math.min(frameDt * 8, 1)

	local hold = HIP + (ADS - HIP) * adsBlend
	local offset = hold
		+ vector.create(
			0,
			-0.22 * equipLeft - 0.08 * reloadDip - 0.12 * plantBlend + 0.03 * flick,
			0.03 * kick - 0.06 * plantBlend - 0.1 * flick
		)
		+ swingOffset
	local angles = CFrame.Angles(
		math.rad(5 * kick) - math.rad(50) * equipLeft - math.rad(15) * reloadDip - math.rad(30) * plantBlend - math.rad(15) * flick,
		0,
		math.rad(35) * reloadDip
	)
	return CFrame.new(Units.toStuds(offset)) * angles * swingTurn, hidden
end

local function updateViewmodel(frameDt: number)
	local sim = PlayerController.sim
	-- Defusing or taking an Ultimate Orb (system 49), the weapon is put
	-- away, and flying the Owl Drone (system 47) the view's the drone's.
	if not sim or not PlayerController.alive or SpikeSim.stowed(sim.spike) or AbilitySim.droning(sim.abilities) then
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

-- A shot's line from `from` to `to` (studs), `width` metres across, gone
-- after `duration` seconds (a bullet's by default).
local function tracer(from: Vector3, to: Vector3, color: Color3, width: number, duration: number?)
	local length = (to - from).Magnitude
	if length < 1e-3 then
		return
	end
	local p = effectPart("Tracer", color, Enum.Material.Neon)
	p.Size = Vector3.new(width * S, width * S, length)
	p.CFrame = CFrame.lookAt((from + to) / 2, to)
	fade(p, duration or 0.07, 0.25)
end

-- A thrown knife's streak (system 19).
local STREAK_COLOR = Color3.fromRGB(190, 240, 255)
local STREAK_WIDTH = 0.018
local STREAK_TIME = 0.15

local MARK_COLOR = Color3.fromRGB(20, 20, 24)

-- Keeps a mark up, and the newest MAX_MARKS of them.
local function keep(p: BasePart)
	p.Parent = marksFolder
	table.insert(marks, p)
	if #marks > MAX_MARKS then
		local oldest = table.remove(marks, 1)
		if oldest then
			oldest:Destroy()
		end
	end
end

local function mark(point: vector, normal: vector)
	local p = effectPart("Mark", MARK_COLOR)
	p.Size = Vector3.new(0.04 * S, 0.04 * S, 0.004 * S)
	local at = Units.toStuds(point + normal * 0.003)
	p.CFrame = CFrame.lookAt(at, at + Units.asVector3(normal))
	keep(p)
end

local function cross(a: vector, b: vector): vector
	return vector.create(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

-- How long a knife's cut is: a slash's line, or a stab's short gash.
local SLASH_CUT = 0.22
local STAB_CUT = 0.05

-- The way a knife swing along `direction` crosses a surface facing `normal`:
-- across the view, or down from the top right for the combo's third slash,
-- laid flat on the surface.
local function sweepAcross(direction: vector, combo: number, normal: vector): vector
	local right = cross(direction, vector.create(0, 1, 0))
	right = if vector.magnitude(right) > 1e-3 then vector.normalize(right) else vector.create(1, 0, 0)
	local up = cross(right, direction)
	local sweep = if combo == 3 then right + up * 0.6 else right
	local flat = sweep - normal * vector.dot(sweep, normal)
	if vector.magnitude(flat) < 1e-3 then
		flat = up - normal * vector.dot(up, normal)
	end
	return if vector.magnitude(flat) > 1e-6 then vector.normalize(flat) else vector.create(1, 0, 0)
end

-- A knife's cut in the level, `length` metres along `along` (in the surface).
local function cut(point: vector, normal: vector, along: vector, length: number)
	local p = effectPart("Cut", MARK_COLOR)
	p.Size = Vector3.new(length * S, 0.008 * S, 0.003 * S)
	p.CFrame = CFrame.fromMatrix(Units.toStuds(point + normal * 0.003), Units.asVector3(along), Units.asVector3(cross(normal, along)))
	keep(p)
end

local function spark(point: vector, color: Color3, size: number)
	local p = effectPart("Spark", color, Enum.Material.Neon)
	p.Size = Vector3.one * size * S
	p.CFrame = CFrame.new(Units.toStuds(point))
	fade(p, 0.15, 0)
end

local PUFF_COLOR = Color3.fromRGB(235, 235, 228)
local RICOCHET_COLOR = Color3.fromRGB(255, 150, 60)
local ICE_COLOR = Color3.fromRGB(200, 240, 255)

local function puff(point: vector, normal: vector, size: number)
	local p = effectPart("Puff", PUFF_COLOR)
	p.Size = Vector3.one * size * S
	p.CFrame = CFrame.new(Units.toStuds(point + normal * size * 0.6))
	fade(p, 0.3, 0.2)
end

-- Whether a mark can show on what a shot met: not on an unseen part, such
-- as the box a kit piece's look stands in (MapKit), which is bigger than a
-- round barrel or a crate stack's narrower top, so a mark on it would hang
-- in the air.
local function marked(key: any): boolean
	return not (typeof(key) == "Instance" and key:IsA("BasePart") and key.Transparency >= 1)
end

-- Holes and sparks along a shot, for the walls it met up to `upTo` metres.
-- Pieces that touch are one wall: one entry, and one exit if the bullet came
-- out of the last of them.
local function drawWalls(origin: vector, dir: vector, walls: { Penetration.Wall }, upTo: number)
	local i = 1
	while i <= #walls do
		local first = walls[i]
		if first.entry > upTo + 1e-3 then
			return
		end
		local last = first
		while walls[i + 1] and walls[i + 1].continues do
			i += 1
			last = walls[i]
		end
		i += 1
		local at = origin + dir * first.entry
		if BarrierSim.piece(first.key) then
			spark(at + first.normal * 0.01, ICE_COLOR, 0.04)
			return
		end
		-- An Owl Drone (system 47) flies on: no mark stays on it.
		if DroneSim.piece(first.key) then
			spark(at + first.normal * 0.01, RICOCHET_COLOR, 0.025)
			return
		end
		if marked(first.key) then
			mark(at, first.normal)
		end
		local exit, exitNormal = last.exit, last.exitNormal
		if exit and exitNormal then
			puff(at, first.normal, 0.06)
			if exit <= upTo + 1e-3 then
				local out = origin + dir * exit
				if marked(last.key) then
					mark(out, exitNormal)
				end
				puff(out, exitNormal, 0.04)
			end
		else
			spark(at + first.normal * 0.01, RICOCHET_COLOR, 0.025)
		end
	end
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
	local outcome = record.predicted
	local from = WeaponEffects.muzzlePosition()
	if WeaponConfig.get(record.shot.weapon).ultimate then
		flick = 1
		tracer(from, Units.toStuds(outcome.point), STREAK_COLOR, STREAK_WIDTH, STREAK_TIME)
	else
		if record.shot.pellet == 1 then
			kick += 1 -- one kick and flash a round, however many pellets
			flashUntil = os.clock() + 0.035
		end
		tracer(from, Units.toStuds(outcome.point), Color3.fromRGB(255, 220, 140), 0.012)
	end
	drawWalls(record.shot.origin, record.shot.direction, outcome.penetration.walls, outcome.distance)
	if outcome.targetId then
		spark(outcome.point, Color3.fromRGB(255, 240, 200), 0.02) -- client-predicted, not a hit
	end
end

-- The local player's knife swing, as the client guessed it: a spark where
-- it met a target (not a hit), or a cut where the blade struck the level.
local function drawSwing(record: ClientMelee.Record)
	local swing, predicted = record.swing, record.predicted
	local hit, wall = predicted.hit, predicted.wall
	if hit then
		spark(hit.point, Color3.fromRGB(255, 240, 200), 0.02)
	elseif wall then
		local point = swing.origin + swing.direction * wall.distance
		if BarrierSim.piece(wall.key) then
			spark(point + wall.normal * 0.01, ICE_COLOR, 0.04)
			return
		end
		if DroneSim.piece(wall.key) then
			spark(point + wall.normal * 0.01, RICOCHET_COLOR, 0.02)
			return
		end
		cut(point, wall.normal, sweepAcross(swing.direction, swing.combo, wall.normal), if swing.kind == "stab" then STAB_CUT else SLASH_CUT)
		spark(point + wall.normal * 0.01, RICOCHET_COLOR, 0.02)
	end
end

-- Server hit confirms, each pinned to a spot on a region's box.
local CONFIRM_TIME = 0.35
local CONFIRM_COLOR = Color3.fromRGB(200, 30, 40)
type Confirm = { id: number, region: Hitboxes.Region, fraction: vector, start: number, size: number, part: BasePart }
local confirms: { Confirm } = {}

-- A hit confirm at `hitPoint` on a target's region, placed on the pose the
-- server hit (`tested`), so it stays on that spot as the target moves.
local function confirm(targetId: number, regionName: string, tested: ClientShots.Tested?, hitPoint: vector?)
	RemoteEntities.flashRegion(targetId, regionName)
	local region: Hitboxes.Region = regionName :: Hitboxes.Region
	local box = if tested then Hitboxes.region(tested.pose, region) else nil
	if not box or not hitPoint then
		return
	end
	local c: Confirm = {
		id = targetId,
		region = region,
		fraction = Hitboxes.boxFraction(box, hitPoint),
		start = os.clock(),
		size = if region == "head" then 0.07 else 0.08, -- Patch 1.07 scaled headshot effects down slightly
		part = effectPart("HitConfirm", CONFIRM_COLOR, Enum.Material.Neon),
	}
	table.insert(confirms, c)
end

local function onVerdict(record: ClientShots.Record)
	local verdict = record.verdict
	if verdict and verdict.targetId and verdict.region then
		confirm(verdict.targetId, verdict.region, verdict.tested[verdict.targetId], verdict.hitPoint)
	end
end

local function onSwingVerdict(record: ClientMelee.Record)
	local verdict = record.verdict
	if verdict and verdict.targetId and verdict.region then
		confirm(verdict.targetId, verdict.region, verdict.tested[verdict.targetId], verdict.point)
	end
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

-- Someone else's round: a tracer for each bullet (unless their gun is
-- suppressed and they're on the other side), the holes it made, and their
-- body's gun kicking.
local function onShotFx(fx: any)
	if typeof(fx) ~= "table" or typeof(fx.from) ~= "Vector3" or typeof(fx.to) ~= "table" then
		return
	end
	if typeof(fx.shooter) == "number" then
		RemoteEntities.fired(fx.shooter)
	end
	local def = WeaponConfig.get(if typeof(fx.weapon) == "string" then fx.weapon else "knife")
	local class: WeaponConfig.PenetrationClass = def.penetration
	local from = Units.toMetres(fx.from)
	for _, to in fx.to do
		if typeof(to) ~= "Vector3" then
			continue
		end
		if def.ultimate then
			tracer(fx.from, to, STREAK_COLOR, STREAK_WIDTH, STREAK_TIME)
		elseif fx.tracers ~= false then
			tracer(fx.from, to, Color3.fromRGB(150, 200, 255), 0.01)
		end
		local toMetres = Units.toMetres(to)
		local length = vector.magnitude(toMetres - from)
		if length >= 1e-3 then
			local dir = (toMetres - from) / length
			local trace = Penetration.trace(ClientShots.levelAt(RemoteEntities.renderTime()), from, dir, class, length + 0.01)
			drawWalls(from, dir, trace.walls, length)
		end
	end
end

-- Someone else's knife swing: the cut where the server has it strike the
-- level.
local function onSwingFx(fx: any)
	if typeof(fx) ~= "table" or typeof(fx.wall) ~= "Vector3" or typeof(fx.normal) ~= "Vector3" or typeof(fx.direction) ~= "Vector3" then
		return
	end
	local point, normal = Units.toMetres(fx.wall), Units.asVector(fx.normal)
	if fx.ice == true then
		spark(point + normal * 0.01, ICE_COLOR, 0.04)
		return
	end
	if fx.drone == true then
		spark(point + normal * 0.01, RICOCHET_COLOR, 0.02)
		return
	end
	local combo = if typeof(fx.combo) == "number" then fx.combo else 1
	cut(point, normal, sweepAcross(Units.asVector(fx.direction), combo, normal), if fx.kind == "stab" then STAB_CUT else SLASH_CUT)
	spark(point + normal * 0.01, RICOCHET_COLOR, 0.02)
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
	table.insert(ClientMelee.firedListeners, drawSwing)
	table.insert(ClientMelee.verdictListeners, onSwingVerdict)
	NetSim.on(Remotes.get().SwingFx, onSwingFx)

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
