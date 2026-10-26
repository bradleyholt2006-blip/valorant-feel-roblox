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
-- Until there are agent models, other players are drawn the same way, in
-- red, and their Roblox avatar is hidden on this client: it is shorter than
-- the hitboxes (a default avatar stands 1.43 m against the boxes' 1.75 m),
-- so a shot at its head would hit the body.
--
-- Over each is a label, their name and health, which shows through walls
-- but for an enemy's (another side's): through a wall it would say where an
-- enemy is that the fog of war (system 35) has sent unseen, one heard
-- behind it or about to come round its corner.
--
-- An entity that isn't in the newest snapshot (the fog of war has left it
-- out, or it's gone) isn't drawn, and the client's guess at a shot or a
-- swing doesn't hit it; as it's back, its history starts over if it was
-- away long enough (PoseHistory.MAX_GAP), so it never slides from where it
-- went to where it's back.
--
-- Where each entity is drawn every frame also goes into a MotionMeter, for
-- the Hit Reg Lab's motion line.
--
-- A player whose spawn protection is on in gun game (system 23) is drawn as
-- a force field, since shots go through them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerCodec = require(Shared.Net.PlayerCodec)
local PoseHistory = require(Shared.Net.PoseHistory)
local InterpClock = require(Shared.Net.InterpClock)
local MotionMeter = require(Shared.Net.MotionMeter)
local NetConfig = require(Shared.Net.NetConfig)
local Remotes = require(Shared.Net.Remotes)
local Units = require(Shared.Units)
local CharacterRig = require(Shared.CharacterRig)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local GunGameConfig = require(Shared.Arena.GunGameConfig)
local Hitboxes = require(Shared.Combat.Hitboxes)
local Health = require(Shared.Combat.Health)
local ShotResolver = require(Shared.Combat.ShotResolver)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)

local NetSim = require(script.Parent.NetSim)

local RemoteEntities = {}

local MOTION_WINDOW = 1 -- seconds of drawn frames each entity's motion is measured over

local histories: { [number]: PoseHistory.History } = {}
local meters: { [number]: MotionMeter.Meter } = {}
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

-- What combat events say of an entity's health: its shield's kind as
-- `armor` (a WeaponConfig.Shields id, or "") and a Regen Shield's pool left.
export type Vitals = { health: number, shield: number, armor: string, pool: number }

-- Last known health per entity, from combat events.
RemoteEntities.health = {} :: { [number]: Vitals }

-- The entity whose eyes the camera looks out of (Spectate), whose blocks
-- are left out so they don't fill the view.
RemoteEntities.viewing = nil :: number?

-- Health for display: entities we have no event for yet are at full spawn
-- health, in the shield everyone starts in.
function RemoteEntities.healthOf(id: number): Vitals
	local known = RemoteEntities.health[id]
	if known then
		return known
	end
	local kind = WeaponConfig.DefaultShield
	return { health = WeaponConfig.Health.maxHealth.value, shield = WeaponConfig.Shields[kind].points.value, armor = kind, pool = 0 }
end

-- Whole points for display: a split hit leaves fractions, and anything left
-- counts as a point (Health.points).
function RemoteEntities.points(value: number): number
	return Health.points(value)
end

local DUMMY_COLORS: { [string]: Color3 } = {
	head = Color3.fromRGB(240, 200, 80),
	body = Color3.fromRGB(80, 140, 230),
	legs = Color3.fromRGB(50, 90, 170),
}
local PLAYER_COLORS: { [string]: Color3 } = {
	head = Color3.fromRGB(240, 200, 80),
	body = Color3.fromRGB(215, 80, 65),
	legs = Color3.fromRGB(145, 45, 40),
}

local FLASH_COLOR = Color3.new(1, 1, 1)
local FLASH_TIME = 0.08

type Visual = {
	model: Model,
	parts: { [string]: BasePart },
	colors: { [string]: Color3 },
	billboard: BillboardGui,
	label: TextLabel,
	flashUntil: { [string]: number },
}
local visuals: { [number]: Visual } = {}
local dummyFolder: Folder? = nil
local playerFolder: Folder? = nil

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
	return PlayerCodec.isDummy(id)
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

-- What an entity is called: its dummy model's name or its player's.
function RemoteEntities.nameOf(id: number): string
	if isDummy(id) then
		return string.format("Dummy_%d", id - PlayerCodec.DUMMY_BASE)
	end
	local player = playerFor(id)
	return if player then player.Name else tostring(id)
end

-- How evenly an entity has moved on screen over the last second, or nil
-- until it has been drawn for a few frames.
function RemoteEntities.motion(id: number): MotionMeter.Reading?
	local meter = meters[id]
	return if meter then MotionMeter.read(meter) else nil
end

local function folderFor(id: number): Folder
	return (if isDummy(id) then dummyFolder else playerFolder) :: Folder
end

local function makeVisual(id: number): Visual
	local colors: { [string]: Color3 } = if isDummy(id) then DUMMY_COLORS else PLAYER_COLORS
	local model = Instance.new("Model")
	model.Name = RemoteEntities.nameOf(id)
	local parts: { [string]: BasePart } = {}
	for region, color in colors do
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
	billboard.Size = UDim2.fromOffset(if isDummy(id) then 90 else 200, 20)
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
	model.Parent = folderFor(id)
	return { model = model, parts = parts, colors = colors, billboard = billboard, label = label, flashUntil = {} }
end

-- Hides another player's Roblox avatar on this client, with its shadow,
-- anything added to it later (accessories load after the character) and the
-- name Roblox shows over it: their blocks and label stand in for all of it.
local function hideAvatar(character: Model)
	local function hide(d: Instance)
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
			d.CastShadow = false
		elseif d:IsA("Decal") then
			d.LocalTransparencyModifier = 1
		elseif d:IsA("Humanoid") then
			d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	for _, d in character:GetDescendants() do
		hide(d)
	end
	character.DescendantAdded:Connect(hide)
end

-- Every character another player gets is hidden from the moment it appears.
local function watchPlayer(player: Player)
	if player == Players.LocalPlayer then
		return
	end
	player.CharacterAdded:Connect(hideAvatar)
	if player.Character then
		hideAvatar(player.Character)
	end
end

-- Lights up the region of a dummy or player the server says was hit.
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
	local now = os.clock()
	frameTime = InterpClock.advance(RemoteEntities.clock, now)
	local renderTime = RemoteEntities.renderTime()
	local mySide = Players.LocalPlayer:GetAttribute(ArenaConfig.SIDE)
	for id in histories do
		local present = RemoteEntities.isPresent(id)
		local pose = if present then RemoteEntities.sample(id, renderTime) else nil
		local meter = meters[id]
		if pose then
			if not meter then
				meter = MotionMeter.new(MOTION_WINDOW)
				meters[id] = meter
			end
			MotionMeter.push(meter, now, pose.position)
		elseif meter then
			MotionMeter.clear(meter)
		end
		local player = if isDummy(id) then nil else playerFor(id)
		if not isDummy(id) and not player then
			-- They left.
			histories[id] = nil
			meters[id] = nil
			local gone = visuals[id]
			if gone then
				gone.model:Destroy()
				visuals[id] = nil
			end
			continue
		end
		local visual = visuals[id] or makeVisual(id)
		visuals[id] = visual
		visual.model.Parent = if pose and id ~= RemoteEntities.viewing then folderFor(id) else nil
		if pose then
			RemoteEntities.placeBoxes(visual.parts, pose)
			local protected = player ~= nil and player:GetAttribute(GunGameConfig.PROTECTED) == true
			local material = if protected then Enum.Material.ForceField else Enum.Material.SmoothPlastic
			for region, part in visual.parts do
				part.Color = if (visual.flashUntil[region] or 0) > now then FLASH_COLOR else visual.colors[region]
				if part.Material ~= material then
					part.Material = material
				end
			end
			local hp = RemoteEntities.healthOf(id)
			local health = string.format("%d + %d", RemoteEntities.points(hp.health), RemoteEntities.points(hp.shield))
			visual.label.Text = if player then player.DisplayName .. "  " .. health else health
			local theirSide = if player then player:GetAttribute(ArenaConfig.SIDE) else nil
			local enemy = typeof(mySide) == "number" and typeof(theirSide) == "number" and theirSide ~= mySide
			if visual.billboard.AlwaysOnTop == enemy then
				visual.billboard.AlwaysOnTop = not enemy
			end
		end
		-- Keep the hidden character where the blocks are, for anything that
		-- reads its position.
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if character and root and pose then
			local offset = CharacterRig.rootOffset(character, root)
			root.CFrame = CFrame.new(Units.toStuds(pose.position) + Vector3.new(0, offset, 0)) * CFrame.Angles(0, pose.yaw, 0)
		end
	end
end

function RemoteEntities.start()
	local dummies = Instance.new("Folder")
	dummies.Name = "VFDummies"
	dummies.Parent = Workspace
	dummyFolder = dummies
	local players = Instance.new("Folder")
	players.Name = "VFPlayers"
	players.Parent = Workspace
	playerFolder = players
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	local remotes = Remotes.get()
	NetSim.on(remotes.Snapshot, onSnapshot)
	NetSim.on(remotes.Combat, function(event: any)
		if typeof(event) == "table" and (event.kind == "damage" or event.kind == "spawn" or event.kind == "shield") then
			RemoteEntities.health[event.target] = {
				health = tonumber(event.health) or 0,
				shield = tonumber(event.shield) or 0,
				armor = if typeof(event.armor) == "string" then event.armor else "",
				pool = tonumber(event.pool) or 0,
			}
		end
	end)
	RunService:BindToRenderStep("VFRemoteEntities", Enum.RenderPriority.Camera.Value + 2, onRender)
end

return RemoteEntities
