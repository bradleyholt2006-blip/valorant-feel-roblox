--!strict
-- What a cast looks and sounds like (system 17). Ours, not the reference's
-- art: plain translucent parts, made here on the client.
--   * Updraft: a ring of air spreading from the feet, and streaks rising
--   * Tailwind readied: a ring of air around the waist through its windup
--   * Tailwind's dash: a streak along its way, and for the one dashing a
--     flash at the edges of the screen
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
local WAIST = 1 -- metres above the feet
local STALE = 1 -- seconds: a cast the screen is this far past isn't shown

type Due = { kind: string, at: number, position: vector, direction: vector, entity: number }

local folder: Folder? = nil
local due: { Due } = {}
local flashUntil = 0

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
-- across over `duration`, fading as it goes.
local function ring(at: vector, from: number, to: number, duration: number)
	-- A cylinder's axis is its X: turned up, it lies flat.
	local cframe = CFrame.new(Units.toStuds(at)) * CFrame.Angles(0, 0, math.pi / 2)
	local p = newPart(vector.create(0.04, from, from), cframe, 0.5, Enum.PartType.Cylinder)
	animate(p, duration, function(k)
		local d = from + (to - from) * k
		p.Size = Units.toStuds(vector.create(0.04, d, d))
		p.Transparency = 0.5 + 0.5 * k
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
	end)
end

return AbilityEffects
