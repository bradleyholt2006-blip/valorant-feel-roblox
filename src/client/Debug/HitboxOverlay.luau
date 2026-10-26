--!strict
-- Hitbox overlay (toggle F10), drawn through walls.
--
--   * every other player's three hitboxes where this client draws them this
--     frame, outlined so they show through walls (players and practice
--     dummies are drawn as their hitboxes; dummies are left out here). On a
--     live server, not an enemy's: through a wall it would show where one
--     is that the fog of war has sent unseen (system 35)
--   * for each of your shots, for two seconds: the ray, the client's end
--     point (yellow) and the boxes of the targets near the ray exactly as the
--     client tested them (yellow)
--   * when the verdict comes back: the server's end point (blue) and the
--     boxes it tested after rewinding. Where the server tested the same pose
--     as the client, the client's boxes turn white; where it didn't, the
--     server's are drawn in blue next to them. A label gives the rewind, and
--     when the verdict differs from the client's guess the ray turns red and
--     the label says why (ClientShots.Cause).
--   * the walls each shot met: a thick segment through every piece the
--     bullet went into, coloured by material, labelled with its thickness
--     along the ray, the share of the bullet's budget it took and the damage
--     left after it. When the verdict arrives the labels turn white if the
--     server's walls match the client's, and red, with the server's list in
--     blue, if not.
--   * for each of your knife swings, for two seconds: where it could catch
--     (its aim out to reach - radius, its sides `radius` either way and its
--     end face on), the point where the client had it meet a target or the
--     level (yellow) and the boxes in reach as the client tested them; with
--     the verdict, the server's point (blue), its boxes as for shots, and a
--     label with the swing, the rewind, what it caught, how far off the aim,
--     the damage, whether from behind and how many the level hid. A red aim
--     line and label mean the client guessed otherwise.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Hitboxes = require(Shared.Combat.Hitboxes)
local Melee = require(Shared.Combat.Melee)
local Penetration = require(Shared.Combat.Penetration)
local Units = require(Shared.Units)

local RemoteEntities = require(script.Parent.Parent.RemoteEntities)
local ClientShots = require(script.Parent.Parent.Combat.ClientShots)
local ClientMelee = require(script.Parent.Parent.Combat.ClientMelee)

local S = Units.STUDS_PER_METRE
local SHOT_LIFETIME = 2

local LIVE_COLOR = Color3.fromRGB(90, 220, 120)
local CLIENT_COLOR = Color3.fromRGB(255, 220, 80)
local SERVER_COLOR = Color3.fromRGB(90, 160, 255)
local SAME_COLOR = Color3.fromRGB(240, 240, 240)
local DIFF_COLOR = Color3.fromRGB(240, 80, 80)

local MATERIAL_COLORS: { [string]: Color3 } = {
	soft = Color3.fromRGB(205, 150, 90),
	medium = Color3.fromRGB(175, 175, 180),
	hard = Color3.fromRGB(120, 175, 225),
	solid = Color3.fromRGB(230, 90, 90),
}

local HitboxOverlay = {}

local enabled = false
local folder: Folder? = nil
local live: { [number]: { [string]: BasePart } } = {}

type Drawn = {
	parts: { BasePart },
	ray: BasePart?,
	clientEnd: BasePart?,
	boxes: { [number]: { BasePart } }, -- the client's tested boxes, by target
	wallLabels: { TextLabel }, -- the client's walls
	expires: number,
}
-- By record: a shot's (ClientShots) or a swing's (ClientMelee).
local drawn: { [any]: Drawn } = {}

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

-- Boxes for one pose, added to a shot's parts.
local function drawBoxes(entry: Drawn, pose: Hitboxes.Pose, color: Color3): { BasePart }
	local parts = regionParts(color)
	RemoteEntities.placeBoxes(parts, pose)
	local list = {}
	for _, p in parts do
		table.insert(entry.parts, p)
		table.insert(list, p)
	end
	return list
end

local function line(from: vector, to: vector, color: Color3, width: number?): Part
	local p = newPart()
	p.Transparency = 0.2
	p.Material = Enum.Material.Neon
	p.Color = color
	local a, b = Units.toStuds(from), Units.toStuds(to)
	local w = (width or 0.008) * S
	p.Size = Vector3.new(w, w, math.max((b - a).Magnitude, 0.01))
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

local function label(anchor: BasePart, text: string, color: Color3, rise: number?, width: number?): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width or 240, 18)
	gui.StudsOffset = Vector3.new(0, (rise or 0.25) * S, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = anchor
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.RobotoMono
	l.TextSize = 14
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.3
	l.Text = text
	l.Parent = gui
	gui.Parent = anchor
	return l
end

-- A flat disc `radius` round at `center`, facing along `normal`.
local function disc(center: vector, normal: vector, radius: number, color: Color3): Part
	local p = newPart()
	p.Shape = Enum.PartType.Cylinder
	p.Transparency = 0.85
	p.Color = color
	p.Size = Vector3.new(0.005 * S, radius * 2 * S, radius * 2 * S)
	local c = Units.toStuds(center)
	-- A cylinder's axis is its X.
	p.CFrame = CFrame.lookAt(c, c + Units.asVector3(normal)) * CFrame.Angles(0, math.rad(90), 0)
	return p
end

local function wallText(name: string?, material: string, thickness: number, used: number, multiplier: number, exited: boolean): string
	local what = if name then string.format("%s (%s)", name, material) else material
	if not exited and thickness == 0 then
		return what .. " stops"
	end
	local after = if exited then string.format("x%.2f", multiplier) else "stops inside"
	return string.format("%s %.2f m  %.0f%%  %s", what, thickness, used * 100, after)
end

-- The pieces of level a shot went into, up to `upTo` metres.
local function drawWalls(entry: Drawn, origin: vector, dir: vector, walls: { Penetration.Wall }, upTo: number)
	for i, wall in walls do
		if wall.entry > upTo + 1e-3 then
			break
		end
		local depth = wall.exit or (wall.entry + wall.thickness)
		local color = MATERIAL_COLORS[wall.material] or SAME_COLOR
		local from, to = origin + dir * wall.entry, origin + dir * math.max(depth, wall.entry + 0.01)
		local segment = line(from, to, color, 0.03)
		table.insert(entry.parts, segment)
		local text = wallText(wall.name, wall.material, wall.thickness, wall.used, wall.multiplier, wall.exit ~= nil)
		table.insert(entry.wallLabels, label(segment, text, CLIENT_COLOR, 0.35 + (i - 1) % 3 * 0.12))
	end
end

local function sameWalls(mine: { Penetration.Wall }, upTo: number, server: { ClientShots.WallReport }): boolean
	local n = 0
	for _, wall in mine do
		if wall.entry > upTo + 1e-3 then
			break
		end
		n += 1
		local theirs = server[n]
		if
			not theirs
			or theirs.material ~= wall.material
			or math.abs(theirs.used - wall.used) > 1e-3
			or (theirs.exit == nil) ~= (wall.exit == nil)
		then
			return false
		end
	end
	return n == #server
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
	local entry: Drawn = { parts = {}, ray = nil, clientEnd = nil, boxes = {}, wallLabels = {}, expires = os.clock() + SHOT_LIFETIME }
	for id, tested in record.tested do
		entry.boxes[id] = drawBoxes(entry, tested.pose, CLIENT_COLOR)
	end
	local ray = line(shot.origin, record.predicted.point, CLIENT_COLOR)
	entry.ray = ray
	table.insert(entry.parts, ray)
	local clientEnd = dot(record.predicted.point, CLIENT_COLOR)
	entry.clientEnd = clientEnd
	table.insert(entry.parts, clientEnd)
	drawWalls(entry, shot.origin, shot.direction, record.predicted.penetration.walls, record.predicted.distance)
	drawn[record] = entry
end

local function onVerdict(record: ClientShots.Record)
	local entry = drawn[record]
	local verdict = record.verdict
	if not entry or not verdict then
		return
	end
	local serverEnd = dot(verdict.point, SERVER_COLOR)
	table.insert(entry.parts, serverEnd)
	for id, tested in verdict.tested do
		local mine = record.tested[id]
		local boxes = entry.boxes[id]
		if mine and boxes and ClientShots.samePose(mine.pose, tested.pose) then
			for _, p in boxes do
				setOutlineColor(p, SAME_COLOR)
			end
		else
			drawBoxes(entry, tested.pose, SERVER_COLOR)
		end
	end
	-- Walls: the client's labels turn white when the server met the same ones.
	local walls = record.predicted.penetration.walls
	if sameWalls(walls, record.predicted.distance, verdict.walls) then
		for _, l in entry.wallLabels do
			l.TextColor3 = SAME_COLOR
		end
	else
		for _, l in entry.wallLabels do
			l.TextColor3 = DIFF_COLOR
		end
		local origin, dir = record.shot.origin, record.shot.direction
		for i, wall in verdict.walls do
			local at = dot(origin + dir * wall.entry, SERVER_COLOR)
			table.insert(entry.parts, at)
			local text = wallText(wall.name, wall.material, wall.thickness, wall.used, wall.multiplier, wall.exit ~= nil)
			label(at, "server " .. text, SERVER_COLOR, -0.2 - (i - 1) % 3 * 0.12)
		end
	end

	local text = string.format("rewind %.0f ms%s", verdict.rewind * 1000, if verdict.clamped then " CAPPED" else "")
	if verdict.multiplier < 1 then
		text ..= string.format("  walls x%.2f", verdict.multiplier)
	end
	if not record.agree then
		text ..= "  " .. (record.cause or "?")
		local ray = entry.ray
		if ray then
			ray.Color = DIFF_COLOR
		end
	end
	-- Label the nearer end point: usually the target.
	local anchor = entry.clientEnd
	if not anchor or verdict.distance < record.predicted.distance then
		anchor = serverEnd
	end
	label(anchor :: BasePart, text, if record.agree then SAME_COLOR else DIFF_COLOR)
end

-- Square to the aim, across the view.
local function across(dir: vector): vector
	local right = vector.create(-dir.z, 0, dir.x)
	return if vector.magnitude(right) > 1e-3 then vector.normalize(right) else vector.create(1, 0, 0)
end

local function onSwing(record: ClientMelee.Record)
	if not enabled then
		return
	end
	local swing, attack = record.swing, record.attack
	local origin, dir = swing.origin, swing.direction
	local length, radius = Melee.length(attack), attack.radius.value
	local entry: Drawn = { parts = {}, ray = nil, clientEnd = nil, boxes = {}, wallLabels = {}, expires = os.clock() + SHOT_LIFETIME }
	for id, tested in record.tested do
		entry.boxes[id] = drawBoxes(entry, tested.pose, CLIENT_COLOR)
	end
	local axis = line(origin, origin + dir * length, CLIENT_COLOR)
	entry.ray = axis
	table.insert(entry.parts, axis)
	local side = across(dir) * radius
	for _, sign in { -1, 1 } do
		table.insert(entry.parts, line(origin + side * sign, origin + side * sign + dir * length, CLIENT_COLOR, 0.004))
	end
	table.insert(entry.parts, disc(origin + dir * length, dir, radius, CLIENT_COLOR))
	local hit, wall = record.predicted.hit, record.predicted.wall
	local at = if hit then hit.point elseif wall then origin + dir * wall.distance else origin + dir * attack.reach.value
	local clientEnd = dot(at, CLIENT_COLOR)
	entry.clientEnd = clientEnd
	table.insert(entry.parts, clientEnd)
	drawn[record] = entry
end

local function onSwingVerdict(record: ClientMelee.Record)
	local entry = drawn[record]
	local verdict = record.verdict
	if not entry or not verdict then
		return
	end
	local serverAt = verdict.point or verdict.wall
	local serverEnd: BasePart? = nil
	if serverAt then
		local p = dot(serverAt, SERVER_COLOR)
		table.insert(entry.parts, p)
		serverEnd = p
	end
	for id, tested in verdict.tested do
		local mine = record.tested[id]
		local boxes = entry.boxes[id]
		if mine and boxes and ClientShots.samePose(mine.pose, tested.pose) then
			for _, p in boxes do
				setOutlineColor(p, SAME_COLOR)
			end
		else
			drawBoxes(entry, tested.pose, SERVER_COLOR)
		end
	end
	local swing = record.swing
	local text = string.format(
		"%s  rewind %.0f ms%s",
		if swing.kind == "stab" then "stab" else string.format("slash %d", swing.combo),
		verdict.rewind * 1000,
		if verdict.clamped then " CAPPED" else ""
	)
	local target = verdict.targetId
	if target then
		text ..= string.format(
			"  %s %s %.2f m off  %.0f%s",
			RemoteEntities.nameOf(target),
			verdict.region or "?",
			verdict.offset or 0,
			verdict.damage,
			if verdict.back then " from behind" else ""
		)
	else
		text ..= if verdict.wall then "  struck the level" else "  caught no one"
	end
	if #verdict.hidden > 0 then
		text ..= string.format("  %d hidden", #verdict.hidden)
	end
	if not record.agree then
		local guess = record.predicted.hit
		text ..= "  client " .. (if guess then RemoteEntities.nameOf(guess.targetId) .. " " .. guess.region else "none")
		local ray = entry.ray
		if ray then
			ray.Color = DIFF_COLOR
		end
	end
	label((serverEnd or entry.clientEnd) :: BasePart, text, if record.agree then SAME_COLOR else DIFF_COLOR, nil, 420)
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
	local mySide = if RunService:IsStudio() then nil else Players.LocalPlayer:GetAttribute(ArenaConfig.SIDE)
	local enemies: { [number]: boolean } = {}
	if typeof(mySide) == "number" then
		for _, player in Players:GetPlayers() do
			local side = player:GetAttribute(ArenaConfig.SIDE)
			if typeof(side) == "number" and side ~= mySide then
				enemies[PlayerCodec.entityIdForUser(player.UserId)] = true
			end
		end
	end
	for _, id in RemoteEntities.ids() do
		if PlayerCodec.isDummy(id) or not RemoteEntities.isPresent(id) or enemies[id] then
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
	table.insert(ClientMelee.firedListeners, onSwing)
	table.insert(ClientMelee.verdictListeners, onSwingVerdict)
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
