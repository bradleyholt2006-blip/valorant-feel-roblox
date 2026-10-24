--!strict
-- Hitbox overlay (toggle F10), drawn through walls.
--
--   * every other player's three hitboxes where this client draws them this
--     frame (practice dummies are already drawn as their hitboxes)
--   * for each of your shots, for two seconds: the ray, the boxes of targets
--     near it as they were at the shot's viewTime (exactly what the client
--     tested), the client's end point (yellow) and the server's (blue). The
--     ray turns red when the server's verdict differs from the client's.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Hitboxes = require(Shared.Combat.Hitboxes)
local Units = require(Shared.Units)

local RemoteEntities = require(script.Parent.Parent.RemoteEntities)
local ClientShots = require(script.Parent.Parent.Combat.ClientShots)

local S = Units.STUDS_PER_METRE
local SHOT_LIFETIME = 2
local NEAR_RAY = 1.5 -- metres from the ray to a target's centre

local LIVE_COLOR = Color3.fromRGB(90, 220, 120)
local CLIENT_COLOR = Color3.fromRGB(255, 220, 80)
local SERVER_COLOR = Color3.fromRGB(90, 160, 255)
local DIFF_COLOR = Color3.fromRGB(240, 80, 80)

local HitboxOverlay = {}

local enabled = false
local folder: Folder? = nil
local live: { [number]: { [string]: BasePart } } = {}

type Drawn = { parts: { BasePart }, ray: BasePart?, expires: number }
local drawn: { [ClientShots.Record]: Drawn } = {}

local function newPart(): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Parent = folder
	return p
end

local function outline(color: Color3): Part
	local p = newPart()
	local box = Instance.new("SelectionBox")
	box.Adornee = p
	box.Color3 = color
	box.LineThickness = 0.015
	box.SurfaceColor3 = color
	box.SurfaceTransparency = 0.85
	box.Parent = p
	return p
end

local function setOutlineColor(p: BasePart, color: Color3)
	local box = p:FindFirstChildOfClass("SelectionBox")
	if box then
		box.Color3 = color
		box.SurfaceColor3 = color
	end
end

local function regionParts(color: Color3): { [string]: BasePart }
	return { head = outline(color), body = outline(color), legs = outline(color) }
end

local function line(from: vector, to: vector, color: Color3): Part
	local p = newPart()
	p.Transparency = 0.2
	p.Material = Enum.Material.Neon
	p.Color = color
	local a, b = Units.toStuds(from), Units.toStuds(to)
	p.Size = Vector3.new(0.008 * S, 0.008 * S, math.max((b - a).Magnitude, 0.01))
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
	return p
end

local function dot(at: vector, color: Color3): Part
	local p = newPart()
	p.Shape = Enum.PartType.Ball
	p.Transparency = 0
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.one * 0.05 * S
	p.CFrame = CFrame.new(Units.toStuds(at))
	return p
end

local function clearLive()
	for _, parts in live do
		for _, p in parts do
			p:Destroy()
		end
	end
	table.clear(live)
end

local function onFired(record: ClientShots.Record)
	if not enabled then
		return
	end
	local shot = record.shot
	local entry: Drawn = { parts = {}, ray = nil, expires = os.clock() + SHOT_LIFETIME }
	for _, target in RemoteEntities.targets(record.input.viewTime) do
		local toCenter = target.pose.position + vector.create(0, 0.9, 0) - shot.origin
		local along = math.max(vector.dot(toCenter, shot.direction), 0)
		if vector.magnitude(toCenter - shot.direction * along) <= NEAR_RAY then
			local parts = regionParts(CLIENT_COLOR)
			RemoteEntities.placeBoxes(parts, target.pose)
			for _, p in parts do
				table.insert(entry.parts, p)
			end
		end
	end
	local ray = line(shot.origin, record.predicted.point, CLIENT_COLOR)
	entry.ray = ray
	table.insert(entry.parts, ray)
	table.insert(entry.parts, dot(record.predicted.point, CLIENT_COLOR))
	drawn[record] = entry
end

local function onVerdict(record: ClientShots.Record)
	local entry = drawn[record]
	local verdict = record.verdict
	if not entry or not verdict then
		return
	end
	table.insert(entry.parts, dot(verdict.point, SERVER_COLOR))
	if not record.agree then
		local ray = entry.ray
		if ray then
			ray.Color = DIFF_COLOR
		end
		for _, p in entry.parts do
			setOutlineColor(p, DIFF_COLOR)
		end
	end
end

local function render()
	local now = os.clock()
	for record, entry in drawn do
		if now >= entry.expires or not enabled then
			for _, p in entry.parts do
				p:Destroy()
			end
			drawn[record] = nil
		end
	end
	if not enabled then
		return
	end
	local renderTime = RemoteEntities.renderTime()
	local seen: { [number]: boolean } = {}
	for _, id in RemoteEntities.ids() do
		if id >= PlayerCodec.DUMMY_BASE or not RemoteEntities.isPresent(id) then
			continue
		end
		local pose = RemoteEntities.sample(id, renderTime)
		if pose then
			seen[id] = true
			local parts = live[id] or regionParts(LIVE_COLOR)
			live[id] = parts
			RemoteEntities.placeBoxes(parts, pose :: Hitboxes.Pose)
		end
	end
	for id, parts in live do
		if not seen[id] then
			for _, p in parts do
				p:Destroy()
			end
			live[id] = nil
		end
	end
end

function HitboxOverlay.start()
	local f = Instance.new("Folder")
	f.Name = "VFHitboxOverlay"
	f.Parent = Workspace
	folder = f
	table.insert(ClientShots.firedListeners, onFired)
	table.insert(ClientShots.verdictListeners, onVerdict)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.F10 then
			enabled = not enabled
			if not enabled then
				clearLive()
			end
		end
	end)
	RunService:BindToRenderStep("VFHitboxOverlay", Enum.RenderPriority.Camera.Value + 3, render)
end

return HitboxOverlay
