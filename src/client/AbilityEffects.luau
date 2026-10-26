--!strict
-- What a cast looks and sounds like (system 17). Ours, not the reference's
-- art: plain translucent parts, made here on the client.
--   * Updraft: a ring of air spreading from the feet, and streaks rising
--   * Tailwind readied: a ring of air around the waist through its windup
--   * Tailwind's dash: a streak along its way, and for the one dashing a
--     flash at the edges of the screen
--   * Cloudburst: only heard here, as it's thrown and as it bursts;
--     CloudView draws it in the air and the cloud (system 18)
--   * Curveball: only its throw heard here; FlareView draws the flare in
--     the air and its pop, and BlindView the blind (system 30)
--   * Hot Hands: only its throw heard here; FireView draws the fireball in
--     the air, its burst and its fire (system 31)
--   * Blaze: only heard here, as it's sent out and, for others, as its
--     wall rises; BlazeView draws it on its way and its wall (system 32)
--   * Run it Back: only heard here, as it's cast, as his body goes and as
--     he rises at the mark; RunItBackView draws its mark, his body going
--     and his rising (system 33)
--   * the Healing Orb: neither here; HealView marks the ally it would heal,
--     and sounds and draws each heal (system 36)
--   * the Slow Orb: only its throw heard here; SlowView draws the orb in
--     the air, its burst and its field of ice (system 37)
--   * the Barrier Orb: only its wall rising heard here, yours as you raise
--     it and others' as it rises; BarrierView draws its targeter and the
--     wall, and sounds it fortifying and breaking (system 38)
--   * the Resurrection: neither here; ReviveView draws the bodies, marks
--     the one it would bring back, and draws and sounds each return
--     (system 39)
--   * Dark Cover: only heard here, as its orb's sent (by the sender's side
--     alone) and as others' smokes form; CloudView draws its mark and the
--     smokes, and sounds yours forming and each one's warning (system 40)
--   * Paranoia: only heard here, as its orb's sent; ParanoiaView draws the
--     orb in flight, warns those in its path and draws the nearsights it
--     gives (system 41)
--   * Shrouded Step: only heard here, as it's fired and as he arrives;
--     StepView draws its targeter, his windup, his going, the shadow where
--     he's going and his arrival (system 42)
--   * From the Shadows: only heard here, yours as you cast it, become a
--     Shade, form or are sent back, and others' as it's fired and as they
--     form; ShadowView draws its map, the windup, the Shade and its
--     arrival, forming and being sent back, and sounds others' Shades
--     arriving and being sent back, and yours sent back by a hit (system 43)
--   * Blade Storm's cast: for others, five blades circling the one who cast
--     it through its windup (system 19). The knives themselves are a
--     weapon, which WeaponEffects draws
--   * Drift's glide: for others, faint rings of air left at the waist as
--     they sink, so the air seems to rush up past them (system 20). It comes
--     in their pose, so it's drawn as they are
-- Your own casts show the tick you press them (PlayerController's
-- castListeners); others' come from the server (the Ability remote) and
-- wait for the frame on your screen to reach them, so they line up with
-- where the caster is drawn. Each plays its sound through GameSounds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local AbilityEffects = {}

local AIR = Color3.fromRGB(205, 240, 255)
local BLADE = Color3.fromRGB(150, 230, 255)
local WAIST = 1 -- metres above the feet
local CHEST = 1.3
local STALE = 1 -- seconds: a cast the screen is this far past isn't shown
local GLIDE_EVERY = 0.2 -- seconds between a glide's rings

type Due = { kind: string, at: number, position: vector, direction: vector, entity: number }

local folder: Folder? = nil
local due: { Due } = {}
local flashUntil = 0
local glidedAt: { [number]: number } = {} -- each glider's last ring, os.clock()

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFAbilityFx"
	made.Parent = Workspace
	folder = made
	return made
end

local function newPart(size: vector, cframe: CFrame, transparency: number, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = AIR
	p.Transparency = transparency
	p.Shape = shape or Enum.PartType.Block
	p.Size = Units.toStuds(size)
	p.CFrame = cframe
	p.Parent = holder()
	return p
end

-- Runs `update` with how far through `duration` it is (0 to 1) each frame,
-- then removes `part`.
local function animate(part: BasePart, duration: number, update: (number) -> ())
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - start) / duration
		if k >= 1 or part.Parent == nil then
			conn:Disconnect()
			part:Destroy()
			return
		end
		update(k)
	end)
end

-- A flat ring of air at `at` (metres), spreading from `from` to `to` metres
-- across over `duration`, fading as it goes from `transparency` (0.5 unless
-- given).
local function ring(at: vector, from: number, to: number, duration: number, transparency: number?)
	local clear = transparency or 0.5
	-- A cylinder's axis is its X: turned up, it lies flat.
	local cframe = CFrame.new(Units.toStuds(at)) * CFrame.Angles(0, 0, math.pi / 2)
	local p = newPart(vector.create(0.04, from, from), cframe, clear, Enum.PartType.Cylinder)
	animate(p, duration, function(k)
		local d = from + (to - from) * k
		p.Size = Units.toStuds(vector.create(0.04, d, d))
		p.Transparency = clear + (1 - clear) * k
	end)
end

local function lift(feet: vector)
	ring(feet + vector.create(0, 0.05, 0), 0.8, 3, 0.45)
	for i = 1, 6 do
		local angle = i / 6 * 2 * math.pi
		local from = feet + vector.create(math.cos(angle) * 0.6, 0.2, math.sin(angle) * 0.6)
		local p = newPart(vector.create(0.04, 0.9, 0.04), CFrame.new(Units.toStuds(from)), 0.4)
		animate(p, 0.4, function(k)
			p.CFrame = CFrame.new(Units.toStuds(from + vector.create(0, 3.5 * k, 0)))
			p.Transparency = 0.4 + 0.6 * k
		end)
	end
end

local function ready(feet: vector)
	ring(feet + vector.create(0, WAIST, 0), 1.6, 1.2, AbilityConfig.Jett.windup.value)
end

local function dash(feet: vector, direction: vector)
	local length = AbilityConfig.Jett.dashDistance.value
	local from = feet + vector.create(0, WAIST, 0)
	local middle = from + direction * (length / 2)
	local cframe = CFrame.lookAt(Units.toStuds(middle), Units.toStuds(middle + direction))
	local p = newPart(vector.create(0.12, 0.12, length), cframe, 0.45)
	animate(p, 0.35, function(k)
		p.Transparency = 0.45 + 0.55 * k
	end)
end

-- Five blades circling the chest, each along its way round, once round
-- over the windup and fading as they go.
local function storm(feet: vector)
	local centre = feet + vector.create(0, CHEST, 0)
	local windup = AbilityConfig.BladeStorm.windup.value
	for i = 1, 5 do
		local p = newPart(vector.create(0.02, 0.04, 0.25), CFrame.new(Units.toStuds(centre)), 0.3)
		p.Color = BLADE
		local start = i / 5 * 2 * math.pi
		animate(p, windup, function(k)
			local angle = start + k * 2 * math.pi
			local at = centre + vector.create(math.cos(angle) * 0.7, 0, math.sin(angle) * 0.7)
			local ahead = vector.create(-math.sin(angle), 0, math.cos(angle))
			p.CFrame = CFrame.lookAt(Units.toStuds(at), Units.toStuds(at + ahead))
			p.Transparency = 0.3 + 0.7 * k * k
		end)
	end
end

-- A ring of a glide, at the waist of someone sinking through it.
local function glide(feet: vector)
	ring(feet + vector.create(0, WAIST, 0), 0.9, 1.4, 0.35, 0.8)
end

-- What a cast shows, at `feet` (metres); `own` for the local player's.
local function show(kind: string, feet: vector, direction: vector, own: boolean)
	if kind == "lift" then
		lift(feet)
	elseif kind == "ready" then
		ready(feet)
	elseif kind == "dash" then
		if own then
			flashUntil = os.clock() + 0.25
		else
			dash(feet, direction)
		end
	elseif kind == "storm" and not own then
		storm(feet)
	end
end

local function onOwnCast(cast: AbilitySim.Cast)
	show(cast.kind, cast.position, cast.direction, true)
	GameSounds.playCast(cast.kind, cast.position)
end

local function onCast(event: any)
	if typeof(event) ~= "table" or typeof(event.entity) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	if typeof(event.kind) ~= "string" or typeof(event.position) ~= "Vector3" or typeof(event.direction) ~= "Vector3" then
		return
	end
	if event.entity == PlayerController.entityId then
		return -- predicted already
	end
	if event.kind == "flight" then
		return -- a throw on its way: CloudView's, FlareView's, FireView's, BlazeView's, SlowView's or ParanoiaView's
	elseif event.kind == "healing" then
		return -- a heal: HealView's
	elseif event.kind == "reviving" or event.kind == "revived" then
		return -- a return: ReviveView's
	elseif event.kind == "vanish" then
		return -- a step's going: StepView's
	elseif event.kind == "shade" or event.kind == "home" then
		return -- a Shade's: ShadowView's
	end
	table.insert(due, {
		kind = event.kind,
		at = event.at,
		position = Units.toMetres(event.position),
		direction = Units.asVector(event.direction),
		entity = event.entity,
	})
end

function AbilityEffects.start()
	-- The dash's flash: a stroke around a frame set in from the screen's
	-- edges, drawn outwards over them.
	local gui = Ui.screen("VFAbilityFx", 14, Enum.ScreenInsets.None)
	local edge = Ui.frame(gui, {
		Size = UDim2.new(1, -40, 1, -40),
		Position = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = AIR
	stroke.Thickness = 40
	stroke.Transparency = 1
	stroke.Parent = edge

	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onCast)
	RunService.RenderStepped:Connect(function()
		local now = RemoteEntities.renderTime()
		local i = 1
		while i <= #due do
			local d = due[i]
			if now >= d.at then
				table.remove(due, i)
				if now - d.at < STALE then
					show(d.kind, d.position, d.direction, false)
					GameSounds.playCast(d.kind, d.position, d.entity)
				end
			else
				i += 1
			end
		end
		local left = flashUntil - os.clock()
		stroke.Transparency = if left > 0 then 1 - 0.5 * left / 0.25 else 1

		-- Others gliding, where they're drawn.
		local clock = os.clock()
		local gliding: { [number]: boolean } = {}
		for _, id in RemoteEntities.ids() do
			local pose = if RemoteEntities.isPresent(id) then RemoteEntities.sample(id, now) else nil
			if pose and pose.alive and pose.gliding then
				gliding[id] = true
				local last = glidedAt[id]
				if last == nil or clock - last >= GLIDE_EVERY then
					glidedAt[id] = clock
					glide(pose.position)
				end
			end
		end
		for id in glidedAt do
			if not gliding[id] then
				glidedAt[id] = nil
			end
		end
	end)
end

return AbilityEffects
