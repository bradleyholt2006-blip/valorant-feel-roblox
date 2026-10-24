--!strict
-- Renders every other entity (players and practice dummies) by interpolating
-- server snapshots.
--
-- Entities are drawn at the render clock's time (InterpClock): a little
-- behind the newest snapshot, measured from how snapshots actually arrive,
-- so there are almost always two to blend between. Every input carries the
-- time of the frame on screen when it was sampled (viewTime), which is what
-- the server's lag compensation rewinds to, and the blending is PoseHistory,
-- the same code the server rewinds with. Riot describes the arrangement with
-- one 128 Hz frame of buffering (7.8125 ms) in "On Peeker's Advantage"; ours
-- has to cover a 60 Hz snapshot interval plus arrival jitter.
--
-- Dummies have no server-side parts: the client draws them straight from
-- their analytic hitboxes, so what you see is exactly what can be hit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerCodec = require(Shared.Net.PlayerCodec)
local PoseHistory = require(Shared.Net.PoseHistory)
local InterpClock = require(Shared.Net.InterpClock)
local NetConfig = require(Shared.Net.NetConfig)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local CharacterRig = require(Shared.CharacterRig)
local Hitboxes = require(Shared.Combat.Hitboxes)
local ShotResolver = require(Shared.Combat.ShotResolver)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)

local NetSim = require(script.Parent.NetSim)

local RemoteEntities = {}

local histories: { [number]: PoseHistory.History } = {}
local lastSeen: { [number]: number } = {}
local latestSnapshot = -math.huge
local localId = PlayerCodec.entityIdForUser(Players.LocalPlayer.UserId)

-- The render clock, and the time of the frame being drawn / on screen.
RemoteEntities.clock = InterpClock.new()
local frameTime: number? = nil

-- Index into NetConfig.Buffering (Minimum, Moderate, Maximum).
RemoteEntities.buffering = 1

-- Snapshot counts for the Hit Reg Lab. Lost and late come from the
-- snapshots' sequence numbers.
RemoteEntities.stats = { snapshots = 0, lost = 0, late = 0 }
local lastSeq: number? = nil

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

-- The snapshot time remote entities are drawn at this frame (before the
-- first snapshot, the server's time).
function RemoteEntities.renderTime(): number
	return frameTime or Workspace:GetServerTimeNow()
end

-- The time of the frame on screen. Inputs sample it before this frame's
-- entities move, so it is what the player was looking at.
function RemoteEntities.shownTime(): number
	return RemoteEntities.renderTime()
end

function RemoteEntities.setBuffering(index: number)
	RemoteEntities.buffering = index
	InterpClock.setExtra(RemoteEntities.clock, NetConfig.Buffering[index].extra)
end

-- Clears the snapshot and frame counters (Hit Reg Lab, Backspace).
function RemoteEntities.resetStats()
	local stats = RemoteEntities.stats
	stats.snapshots, stats.lost, stats.late = 0, 0, 0
	RemoteEntities.clock.frames = 0
	RemoteEntities.clock.starved = 0
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

local function countSequence(seq: number)
	local stats = RemoteEntities.stats
	local last = lastSeq
	if last == nil then
		stats.snapshots += 1
		lastSeq = seq
		return
	end
	local ahead = (seq - last) % 65536
	if ahead == 0 then
		return -- another packet of the same snapshot
	elseif ahead < 32768 then
		stats.snapshots += 1
		stats.lost += ahead - 1
		lastSeq = seq
	else
		stats.late += 1 -- older than one already received
	end
end

local function onSnapshot(payload: buffer)
	if typeof(payload) ~= "buffer" then
		return
	end
	local serverTime, poses, seq = PlayerCodec.decodeSnapshot(payload)
	countSequence(seq)
	InterpClock.onSnapshot(RemoteEntities.clock, serverTime, os.clock(), seq)
	latestSnapshot = math.max(latestSnapshot, serverTime)
	for _, pose in poses do
		if pose.id == localId then
			continue
		end
		lastSeen[pose.id] = math.max(lastSeen[pose.id] or -math.huge, serverTime)
		local h = histories[pose.id]
		if not h then
			h = PoseHistory.new()
			histories[pose.id] = h
		end
		PoseHistory.push(h, serverTime, pose)
	end
end

-- An entity's pose at a snapshot time, with which snapshots it came from.
function RemoteEntities.lookup(id: number, serverTime: number): PoseHistory.Lookup?
	local h = histories[id]
	return if h then PoseHistory.sample(h, serverTime) else nil
end

-- Interpolated pose of an entity at a snapshot time (nil if never seen).
function RemoteEntities.sample(id: number, serverTime: number): PlayerCodec.Pose?
	local lookup = RemoteEntities.lookup(id, serverTime)
	return if lookup then lookup.pose else nil
end

-- An entity is present if the newest snapshot included it.
function RemoteEntities.isPresent(id: number): boolean
	local seen = lastSeen[id]
	return seen ~= nil and seen >= latestSnapshot - 1e-6
end

-- Every present entity at a snapshot time, with its lookup.
function RemoteEntities.lookups(serverTime: number): { { id: number, lookup: PoseHistory.Lookup } }
	local out = {}
	for id in histories do
		if RemoteEntities.isPresent(id) then
			local lookup = RemoteEntities.lookup(id, serverTime)
			if lookup then
				table.insert(out, { id = id, lookup = lookup })
			end
		end
	end
	return out
end

-- Targets as they were drawn at a snapshot time, for client-side shot prediction.
function RemoteEntities.targets(serverTime: number): { ShotResolver.Target }
	local out: { ShotResolver.Target } = {}
	for _, entry in RemoteEntities.lookups(serverTime) do
		local pose = entry.lookup.pose
		table.insert(out, { id = entry.id, pose = { position = pose.position, yaw = pose.yaw, crouchAlpha = pose.crouchAlpha } })
	end
	return out
end

function RemoteEntities.ids(): { number }
	local out = {}
	for id in histories do
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
	frameTime = InterpClock.advance(RemoteEntities.clock, os.clock())
	local renderTime = RemoteEntities.renderTime()
	for id in histories do
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
			histories[id] = nil
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
	NetSim.on(remotes.Snapshot, onSnapshot)
	NetSim.on(remotes.Combat, function(event: any)
		if typeof(event) == "table" and (event.kind == "damage" or event.kind == "spawn") then
			RemoteEntities.health[event.target] = { health = event.health, shield = event.shield }
		end
	end)
	RunService:BindToRenderStep("VFRemoteEntities", Enum.RenderPriority.Camera.Value + 2, onRender)
end

return RemoteEntities
