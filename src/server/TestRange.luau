--!strict
-- Builds a measurement course (original geometry) when the place has no map.
-- Everything is laid out in metres so it matches the numbers in the docs:
--   * 20 m sprint lane with a stripe every metre and a post every 5 m
--   * steps of 0.20 / 0.35 / 0.50 m (the last should block; stepHeight 0.35)
--   * a 1.5 m crouch tunnel
--   * jump boxes of 0.50 / 0.70 / 0.85 / 1.00 m
--   * ramps at 30 / 45 / 50 degrees (maxGroundAngle is 46)
--   * an angled wall for wall-slide checks
--   * a target lane down -Z with stripes every 10 m to 50 m, a backstop, a
--     waist-high cover and practice dummy spawn points
--   * a wallbang lane: wood, concrete and metal walls 0.10 / 0.20 / 0.40 m
--     thick with a dummy behind each, and the 0.20 m concrete wall again
--     turned 45 degrees
--
-- Everything here is SmoothPlastic, which bullets can't go through, except
-- the wallbang walls (Combat/RobloxLevel maps materials to penetration).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Units = require(ReplicatedStorage:WaitForChild("Shared").Units)

local S = Units.STUDS_PER_METRE

local TestRange = {}

local function part(parent: Instance, name: string, sizeM: Vector3, centerM: Vector3, color: Color3, rotation: CFrame?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = sizeM * S
	p.CFrame = CFrame.new(centerM * S) * (rotation or CFrame.identity)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function sign(target: BasePart, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui
	gui.Parent = target
end

function TestRange.buildIfMissing()
	if Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("VFTestRange") then
		return
	end
	local root = Instance.new("Folder")
	root.Name = "VFTestRange"

	local grey = Color3.fromRGB(70, 72, 80)
	local light = Color3.fromRGB(200, 200, 205)
	local accent = Color3.fromRGB(240, 90, 90)

	part(root, "Floor", Vector3.new(80, 1, 80), Vector3.new(0, -0.5, 0), grey)

	-- Sprint lane along +X from x = 0.
	for m = 0, 20 do
		local stripe = part(root, "Lane" .. m, Vector3.new(0.05, 0.01, 2), Vector3.new(m, 0.005, -6), if m % 5 == 0 then accent else light)
		stripe.CanCollide = false
		if m % 5 == 0 then
			local post = part(root, "Post" .. m, Vector3.new(0.1, 2, 0.1), Vector3.new(m, 1, -7.2), accent)
			post.CanCollide = false
			local tag = part(root, "Tag" .. m, Vector3.new(0.8, 0.01, 0.4), Vector3.new(m, 0.006, -4.6), grey)
			tag.CanCollide = false
			sign(tag, m .. " m")
		end
	end

	-- Steps.
	for i, h in { 0.20, 0.35, 0.50 } do
		local step = part(root, string.format("Step_%.2fm", h), Vector3.new(2, h, 2), Vector3.new(-6 - (i - 1) * 3, h / 2, 6), light)
		sign(step, string.format("%.2f m", h))
	end

	-- Crouch tunnel: 1.5 m clearance, 4 m long.
	part(root, "TunnelRoof", Vector3.new(4, 0.3, 3), Vector3.new(8, 1.5 + 0.15, 8), light)
	part(root, "TunnelWallA", Vector3.new(4, 1.5, 0.3), Vector3.new(8, 0.75, 6.35), grey)
	part(root, "TunnelWallB", Vector3.new(4, 1.5, 0.3), Vector3.new(8, 0.75, 9.65), grey)

	-- Jump boxes.
	for i, h in { 0.50, 0.70, 0.85, 1.00 } do
		local box = part(root, string.format("Jump_%.2fm", h), Vector3.new(1.5, h, 1.5), Vector3.new(-6 - (i - 1) * 2.5, h / 2, -10), accent)
		sign(box, string.format("%.2f m", h))
	end

	-- Ramps (rotated about Z, rising toward -X).
	for i, deg in { 30, 45, 50 } do
		local length = 5
		local rise = math.sin(math.rad(deg)) * length / 2
		local ramp = part(
			root,
			"Ramp_" .. deg,
			Vector3.new(length, 0.2, 2),
			Vector3.new(18, rise, 6 + (i - 1) * 3),
			light,
			CFrame.Angles(0, 0, math.rad(deg))
		)
		sign(ramp, deg .. " deg")
	end

	-- Angled wall for slide tests.
	part(root, "SlideWall", Vector3.new(8, 3, 0.3), Vector3.new(14, 1.5, -14), grey, CFrame.Angles(0, math.rad(30), 0))

	-- Target lane straight ahead of the spawn (yaw 0 looks down -Z), with
	-- distance stripes, a backstop and practice dummy spawn points.
	part(root, "LaneFloor", Vector3.new(24, 1, 24), Vector3.new(2, -0.5, -50), grey)
	part(root, "Backstop", Vector3.new(24, 6, 0.5), Vector3.new(2, 3, -60), light)
	for _, m in { 10, 20, 30, 40, 50 } do
		local stripe = part(root, "Range" .. m, Vector3.new(12, 0.01, 0.05), Vector3.new(2, 0.005, -m), accent)
		stripe.CanCollide = false
		local tag = part(root, "RangeTag" .. m, Vector3.new(0.8, 0.01, 0.4), Vector3.new(-5, 0.006, -m), grey)
		tag.CanCollide = false
		sign(tag, m .. " m")
	end
	-- Waist-high cover with a dummy behind it: only its head is exposed.
	part(root, "Cover", Vector3.new(2, 1.2, 0.4), Vector3.new(8, 0.6, -21), light)

	local spawns = Instance.new("Folder")
	spawns.Name = "DummySpawns"
	spawns.Parent = root
	local dummySpots = {
		{ x = 0, z = -10, mode = "static" },
		{ x = 3, z = -15, mode = "strafe" },
		{ x = -2, z = -20, mode = "crouch" },
		{ x = 0, z = -30, mode = "static" },
		{ x = 3, z = -30, mode = "strafe" },
		{ x = 0, z = -50, mode = "static" },
		{ x = 8, z = -22, mode = "static" },
	}
	local function marker(x: number, z: number, mode: string)
		local index = #spawns:GetChildren() + 1
		local m = part(spawns, string.format("Dummy%02d", index), Vector3.new(0.5, 0.02, 0.5), Vector3.new(x, 0.01, z), accent)
		m.CanCollide = false
		m.CanQuery = false
		m.Transparency = 0.6
		m:SetAttribute("Mode", mode)
	end
	for _, spot in dummySpots do
		marker(spot.x, spot.z, spot.mode)
	end

	-- Wallbang lane, left of the spawn: walls 2.4 m tall with their faces on
	-- z = -20 and a dummy 1.5 m behind each, a line 10 m in front to shoot
	-- from and a backstop. F10 labels what each wall cost the bullet.
	local wallZ = -20
	local function wallTag(x: number, text: string)
		local tag = part(root, "WallbangTag", Vector3.new(1.3, 0.01, 0.4), Vector3.new(x, 0.006, wallZ + 1.2), grey)
		tag.CanCollide = false
		sign(tag, text)
	end
	local kinds = {
		{ name = "wood", material = Enum.Material.Wood, color = Color3.fromRGB(150, 105, 65) },
		{ name = "concrete", material = Enum.Material.Concrete, color = Color3.fromRGB(165, 165, 160) },
		{ name = "metal", material = Enum.Material.Metal, color = Color3.fromRGB(130, 136, 146) },
	}
	local x = -32
	for _, kind in kinds do
		for _, t in { 0.1, 0.2, 0.4 } do
			local wall = part(
				root,
				string.format("Wallbang_%s_%.2fm", kind.name, t),
				Vector3.new(1.4, 2.4, t),
				Vector3.new(x, 1.2, wallZ - t / 2),
				kind.color
			)
			wall.Material = kind.material
			wallTag(x, string.format("%s %.2f m", kind.name, t))
			marker(x, wallZ - 1.5, "static")
			x += 2
		end
	end
	-- The 0.20 m concrete wall turned 45 degrees: 0.28 m along a straight shot.
	local turned = part(
		root,
		"Wallbang_concrete_0.20m_45deg",
		Vector3.new(1.4, 2.4, 0.2),
		Vector3.new(-35.5, 1.2, wallZ - 0.5),
		kinds[2].color,
		CFrame.Angles(0, math.rad(45), 0)
	)
	turned.Material = Enum.Material.Concrete
	wallTag(-35.5, "concrete 0.20 m at 45")
	marker(-35.5, wallZ - 1.8, "static")
	part(root, "WallbangBackstop", Vector3.new(24, 3, 0.5), Vector3.new(-26, 1.5, wallZ - 4.25), light)
	local line = part(root, "WallbangLine", Vector3.new(22, 0.01, 0.05), Vector3.new(-26, 0.005, wallZ + 10), accent)
	line.CanCollide = false
	local lineTag = part(root, "WallbangLineTag", Vector3.new(1.2, 0.01, 0.4), Vector3.new(-37.5, 0.006, wallZ + 10), grey)
	lineTag.CanCollide = false
	sign(lineTag, "10 m")

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(1.5, 0.1, 1.5) * S
	spawn.CFrame = CFrame.new(Vector3.new(0, 0.05, 0) * S)
	spawn.Transparency = 0.5
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = root

	root.Parent = Workspace
end

return TestRange
