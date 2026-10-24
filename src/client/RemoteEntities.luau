--!strict
-- Renders every other entity (players and practice dummies) by interpolating
-- server snapshots.
--
-- Remote entities are drawn INTERP_DELAY seconds in the past so there are
-- always two snapshots to blend between. That delay is a known, fixed number:
-- every input carries the server time the client was looking at
-- (renderTime), which is what server-side lag compensation rewinds to.
-- Riot describes the same trade-off (7.8125 ms buffering at 128 Hz) in
-- "On Peeker's Advantage"; our snapshot rate is 60 Hz, so the delay is larger.
--
-- Dummies have no server-side parts: the client draws them straight from
-- their analytic hitboxes, so what you see is exactly what can be hit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local CharacterRig = require(Shared.CharacterRig)
local Hitboxes = require(Shared.Combat.Hitboxes)
local ShotResolver = require(Shared.Combat.ShotResolver)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)

local RemoteEntities = {}

RemoteEntities.INTERP_DELAY = 0.05 -- seconds; three snapshots at 60 Hz
local MAX_BUFFER = 64

type Sample = { time: number, pose: PlayerCodec.Pose }

local buffers: { [number]: { Sample } } = {}
local lastSeen: { [number]: number } = {}
local latestSnapshot = 0
local localId = PlayerCodec.entityIdForUser(Players.LocalPlayer.UserId)

-- Last known health per entity, from combat events.
RemoteEntities.health = {} :: { [number]: { health: number, shield: number } }

-- Health for display: entities we have no event for yet are at full spawn health.
function RemoteEntities.healthOf(id: number): { health: number, shield: number }
	return RemoteEntities.health[id] or { health = WeaponConfig.Health.maxHealth.value, shield = WeaponConfig.Health.heavyShield.value }
end

local REGION_COLORS: { [string]: Color3 } = {
	head = Color3.fromRGB(240, 200, 80),
	body = Color3.fromRGB(80, 140, 230),
	legs = Color3.fromRGB(50, 90, 170),
}

local FLASH_COLOR = Color3.new(1, 1, 1)
local FLASH_TIME = 0.08

type Visual = { model: Model, parts: { [string]: BasePart }, label: TextLabel, flashUntil: { [string]: number } }
local visuals: { [number]: Visual } = {}
local visualFolder: Folder? = nil

function RemoteEntities.renderTime(): number
	return Workspace:GetServerTimeNow() - RemoteEntities.INTERP_DELAY
end

local function playerFor(id: number): Player?
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == id then
			return player
		end
	end
	return nil
end

local function isDummy(id: number): boolean
	return id >= PlayerCodec.DUMMY_BASE
end

local function onSnapshot(payload: buffer)
	if typeof(payload) ~= "buffer" then
		return
	end
	local serverTime, poses = PlayerCodec.decodeSnapshot(payload)
	latestSnapshot = math.max(latestSnapshot, serverTime)
	for _, pose in poses do
		if pose.id == localId then
			continue
		end
		lastSeen[pose.id] = serverTime
		local buf = buffers[pose.id]
		if not buf then
			buf = {}
			buffers[pose.id] = buf
		end
		local last = buf[#buf]
		if last and serverTime <= last.time then
			continue
		end
		table.insert(buf, { time = serverTime, pose = pose })
		if #buf > MAX_BUFFER then
			table.remove(buf, 1)
		end
	end
end

local function lerpAngle(a: number, b: number, t: number): number
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * t
end

-- Interpolated pose of an entity at a server time (nil if never seen).
function RemoteEntities.sample(id: number, serverTime: number): PlayerCodec.Pose?
	local buf = buffers[id]
	if not buf or #buf == 0 then
		return nil
	end
	if serverTime <= buf[1].time then
		return buf[1].pose
	end
	for i = #buf - 1, 1, -1 do
		local a, b = buf[i], buf[i + 1]
		if serverTime >= a.time then
			local t = math.clamp((serverTime - a.time) / math.max(b.time - a.time, 1e-6), 0, 1)
			return {
				id = id,
				position = a.pose.position + (b.pose.position - a.pose.position) * t,
				yaw = lerpAngle(a.pose.yaw, b.pose.yaw, t),
				pitch = a.pose.pitch + (b.pose.pitch - a.pose.pitch) * t,
				crouchAlpha = a.pose.crouchAlpha + (b.pose.crouchAlpha - a.pose.crouchAlpha) * t,
				grounded = b.pose.grounded,
				alive = b.pose.alive,
			}
		end
	end
	-- Past the newest snapshot: hold it rather than extrapolate.
	return buf[#buf].pose
end

-- An entity is present if the newest snapshot included it.
function RemoteEntities.isPresent(id: number): boolean
	local seen = lastSeen[id]
	return seen ~= nil and seen >= latestSnapshot - 1e-6
end

-- Targets as they were drawn at a server time, for client-side shot prediction.
function RemoteEntities.targets(serverTime: number): { ShotResolver.Target }
	local out: { ShotResolver.Target } = {}
	for id in buffers do
		if RemoteEntities.isPresent(id) then
			local pose = RemoteEntities.sample(id, serverTime)
			if pose then
				table.insert(out, { id = id, pose = { position = pose.position, yaw = pose.yaw, crouchAlpha = pose.crouchAlpha } })
			end
		end
	end
	return out
end

function RemoteEntities.ids(): { number }
	local out = {}
	for id in buffers do
		table.insert(out, id)
	end
	return out
end

local function makeVisual(id: number): Visual
	local folder = visualFolder :: Folder
	local model = Instance.new("Model")
	model.Name = string.format("Dummy_%d", id - PlayerCodec.DUMMY_BASE)
	local parts: { [string]: BasePart } = {}
	for region, color in REGION_COLORS do
		local p = Instance.new("Part")
		p.Name = region
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color
		p.Parent = model
		parts[region] = p
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(90, 20)
	billboard.StudsOffset = Vector3.new(0, 1.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = parts.head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.RobotoMono
	label.TextSize = 14
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = ""
	label.Parent = billboard
	billboard.Parent = model
	model.Parent = folder
	return { model = model, parts = parts, label = label, flashUntil = {} }
end

-- Lights up the region of a dummy the server says was hit.
function RemoteEntities.flashRegion(id: number, region: string)
	local visual = visuals[id]
	if visual then
		visual.flashUntil[region] = os.clock() + FLASH_TIME
	end
end

-- Positions a set of region parts exactly on an entity's hitboxes.
function RemoteEntities.placeBoxes(parts: { [string]: BasePart }, pose: Hitboxes.Pose)
	for _, box in Hitboxes.build(pose) do
		local p = parts[box.region]
		if p then
			p.Size = Units.toStuds(box.half * 2)
			p.CFrame = CFrame.new(Units.toStuds(box.center)) * CFrame.Angles(0, box.yaw, 0)
		end
	end
end

local function onRender()
	local renderTime = RemoteEntities.renderTime()
	for id in buffers do
		local present = RemoteEntities.isPresent(id)
		local pose = if present then RemoteEntities.sample(id, renderTime) else nil
		if isDummy(id) then
			local visual = visuals[id] or makeVisual(id)
			visuals[id] = visual
			visual.model.Parent = if pose then visualFolder else nil
			if pose then
				RemoteEntities.placeBoxes(visual.parts, pose)
				local now = os.clock()
				for region, part in visual.parts do
					part.Color = if (visual.flashUntil[region] or 0) > now then FLASH_COLOR else REGION_COLORS[region]
				end
				local hp = RemoteEntities.healthOf(id)
				visual.label.Text = string.format("%d + %d", hp.health, hp.shield)
			end
			continue
		end
		local player = playerFor(id)
		if not player then
			buffers[id] = nil
			continue
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if character and root and pose then
			local offset = CharacterRig.rootOffset(character, root)
			root.CFrame = CFrame.new(Units.toStuds(pose.position) + Vector3.new(0, offset, 0)) * CFrame.Angles(0, pose.yaw, 0)
		end
	end
end

function RemoteEntities.start()
	local folder = Instance.new("Folder")
	folder.Name = "VFDummies"
	folder.Parent = Workspace
	visualFolder = folder
	local remotes = Remotes.get()
	remotes.Snapshot.OnClientEvent:Connect(onSnapshot)
	remotes.Combat.OnClientEvent:Connect(function(event)
		if event.kind == "damage" or event.kind == "spawn" then
			RemoteEntities.health[event.target] = { health = event.health, shield = event.shield }
		end
	end)
	RunService:BindToRenderStep("VFRemoteEntities", Enum.RenderPriority.Camera.Value + 2, onRender)
end

return RemoteEntities
