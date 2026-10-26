--!strict
-- Sage's Healing Orb on the client (system 36).
--   * With the orb in hand, the hurt ally under your crosshair, as your
--     screen shows them, is marked: a green box round each of their blocks,
--     and a + over their head, as the reference's widget over the ally it
--     targets (Patch 12.05). The same test as the server's (HealSim), on
--     what you see: the level and clouds in the way, but not walls of fire
--   * A heal the server starts (the Ability remote's "healing") sounds its
--     chime from the healer, and whoever it heals glows green until it's
--     over ("healed"): their blocks, or for you the edge of your screen.
--     Your own heals show at once, as the server has them, and others' as
--     the frame on your screen reaches them
-- The orb in hand is a weapon, which WeaponEffects draws.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HealSim = require(Shared.Abilities.HealSim)
local Minimap = require(Shared.Match.Minimap)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local Sight = require(Shared.Combat.Sight)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)
local WeaponSim = require(Shared.Weapons.WeaponSim)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local CloudView = require(script.Parent.CloudView)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local HealView = {}

local GREEN = Color3.fromRGB(110, 235, 150)
local REGIONS = { "head", "body", "legs" }
local PAD = 0.06 -- metres each box is drawn out past the block it's round
local MOST = 20 -- seconds a glow lasts at the most, should its end be lost
local STALE = 1 -- seconds: a heal the screen is this far past isn't heard
-- How many barriers one line of sight goes through at the most.
local PASSES = 4

-- A heal waiting for the frame on your screen to reach it.
type Due = { at: number, healer: number, target: number, position: vector }
-- A model's boxes: the marked ally's, or a glow's.
type Boxes = { model: Model, boxes: { [string]: BoxHandleAdornment } }

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = RobloxWorld.CHARACTER_GROUP
params.RespectCanCollide = true

local due: { Due } = {}
-- Who's glowing, by entity id, and until when (os.clock()) at the most.
local glowing: { [number]: number } = {}
local glows: { [number]: Boxes } = {}
local marked: Boxes? = nil
local widget: BillboardGui? = nil

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

-- Whether another player is on your team.
local function ally(player: Player): boolean
	local me = Players.LocalPlayer
	return player ~= me and not player.Neutral and not me.Neutral and me.Team ~= nil and player.Team == me.Team
end

-- Green boxes round `model`'s blocks, `transparency` clear.
local function box(model: Model, transparency: number): Boxes
	local out: Boxes = { model = model, boxes = {} }
	for _, region in REGIONS do
		local part = model:FindFirstChild(region)
		if part and part:IsA("BasePart") then
			local b = Instance.new("BoxHandleAdornment")
			b.Name = "VFHeal"
			b.Adornee = part
			b.AlwaysOnTop = false
			b.ZIndex = 1
			b.Color3 = GREEN
			b.Transparency = transparency
			b.Size = part.Size + Vector3.one * (2 * PAD * Units.STUDS_PER_METRE)
			b.Parent = part
			out.boxes[region] = b
		end
	end
	return out
end

-- Boxes kept the size of their blocks, which crouching changes.
local function fit(b: Boxes)
	for region, adornment in b.boxes do
		local part = b.model:FindFirstChild(region)
		if part and part:IsA("BasePart") then
			adornment.Size = part.Size + Vector3.one * (2 * PAD * Units.STUDS_PER_METRE)
		end
	end
end

local function unbox(b: Boxes?)
	if b then
		for _, adornment in b.boxes do
			adornment:Destroy()
		end
	end
end

-- The + over a marked ally's head.
local function plus(model: Model): BillboardGui?
	local head = model:FindFirstChild("head")
	if not head or not head:IsA("BasePart") then
		return nil
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "VFHealMark"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(36, 36)
	gui.StudsOffset = Vector3.new(0, 0.55 * Units.STUDS_PER_METRE, 0)
	gui.Adornee = head
	gui.Parent = head
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
	return gui
end

-- The hurt ally your crosshair's over, as your screen shows them, while
-- the orb's in hand.
local function aimedAt(): number?
	local s = PlayerController.sim
	if not s or s.weapons.equipped ~= WeaponSim.ULT or s.weapons.loadout[WeaponSim.ULT] ~= "healorb" or s.abilities.holding == 0 then
		return nil
	end
	local render = RemoteEntities.renderTime()
	local most = WeaponConfig.Health.maxHealth.value
	local allies: { HealSim.Body } = {}
	for _, player in Players:GetPlayers() do
		local id = PlayerCodec.entityIdForUser(player.UserId)
		if not ally(player) or not RemoteEntities.isPresent(id) or not HealSim.hurt(RemoteEntities.healthOf(id).health, most) then
			continue
		end
		local pose = RemoteEntities.sample(id, render)
		if pose and pose.alive then
			table.insert(allies, { id = id, pose = { position = pose.position, yaw = pose.yaw, crouchAlpha = pose.crouchAlpha } })
		end
	end
	if #allies == 0 then
		return nil
	end
	local camera = Workspace.CurrentCamera.CFrame
	local clouds = CloudView.standing(render)
	return HealSim.aimedAt(
		Units.toMetres(camera.Position),
		Units.asVector(camera.LookVector),
		allies,
		function(a: vector, b: vector): boolean
			for _, cloud in clouds do
				if Sight.cloudHides(cloud, a, b) then
					return true
				end
			end
			return blocked(a, b)
		end
	)
end

-- A heal started: its chime from the healer, and its target's glow.
local function start(d: Due, late: boolean)
	local own = d.healer == PlayerController.entityId
	if not late then
		GameSounds.playCast("healing", d.position, if own then nil else d.healer)
	end
	glowing[d.target] = os.clock() + MOST
end

local function onEvent(event: any)
	if typeof(event) ~= "table" then
		return
	end
	if event.kind == "healed" then
		if typeof(event.target) == "number" then
			glowing[event.target] = nil
		else
			table.clear(glowing)
			table.clear(due)
		end
		return
	end
	if event.kind ~= "healing" or typeof(event.entity) ~= "number" or typeof(event.target) ~= "number" then
		return
	end
	if typeof(event.at) ~= "number" or typeof(event.position) ~= "Vector3" then
		return
	end
	local d: Due = { at = event.at, healer = event.entity, target = event.target, position = Units.toMetres(event.position) }
	if d.healer == PlayerController.entityId then
		start(d, false)
	else
		table.insert(due, d)
	end
end

function HealView.start()
	-- Your own heal: a stroke round a frame set in from the screen's edges,
	-- drawn out over them, as the dash's flash is (AbilityEffects).
	local gui = Ui.screen("VFHealFx", 14, Enum.ScreenInsets.None)
	local edge = Ui.frame(gui, {
		Size = UDim2.new(1, -40, 1, -40),
		Position = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = GREEN
	stroke.Thickness = 40
	stroke.Transparency = 1
	stroke.Parent = edge

	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()
		local i = 1
		while i <= #due do
			local d = due[i]
			if render >= d.at then
				table.remove(due, i)
				start(d, render - d.at > STALE)
			else
				i += 1
			end
		end

		-- The glows: yours at the screen's edge, pulsing, and others' round
		-- their blocks while they're drawn.
		local me = PlayerController.entityId
		local mine = false
		for id, untilAt in glowing do
			if clock >= untilAt then
				glowing[id] = nil
			elseif id == me then
				mine = true
			end
		end
		stroke.Transparency = if mine then 0.7 + 0.1 * math.sin(clock * 6) else 1
		for id, b in glows do
			if not glowing[id] or RemoteEntities.modelOf(id) ~= b.model then
				unbox(b)
				glows[id] = nil
			end
		end
		for id in glowing do
			local model = if id ~= me then RemoteEntities.modelOf(id) else nil
			if model and not glows[id] then
				glows[id] = box(model, 0.65)
			end
			local b = glows[id]
			if b then
				fit(b)
				for _, adornment in b.boxes do
					adornment.Transparency = 0.65 + 0.1 * math.sin(clock * 6)
				end
			end
		end

		-- The ally the orb would heal.
		local target = aimedAt()
		local model = if target then RemoteEntities.modelOf(target) else nil
		local m = marked
		if m and m.model ~= model then
			unbox(m)
			marked = nil
			local w = widget
			if w then
				w:Destroy()
				widget = nil
			end
		end
		if model and not marked then
			marked = box(model, 0.45)
			widget = plus(model)
		end
		local now = marked
		if now then
			fit(now)
		end
	end)
end

return HealView
