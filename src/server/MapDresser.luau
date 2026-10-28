--!strict
-- A dressed spike map's look (system 58), over the parts Arena builds every
-- spike map from (MapPlan): each zone's floor and the walls in their looks
-- (MapKit.Themes), each piece of cover as the piece of the kit it is, and
-- the dressing in its style (MapKit.Styles).
--
-- A piece's box stays where Arena puts it, unseen: it's all there is to
-- the piece for moving, seeing and shooting. Over it goes a model named
-- after the piece from ServerStorage's VFMapKit folder, if there is one,
-- fitted to the box, or else the kit's placeholder. Either is for show:
-- nothing in it collides, is hit or is touched. A model put in the folder,
-- or taken out of it, while the server runs shows at once on every piece
-- of its name (MapDresser.watch).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MapKit = require(Shared.Match.MapKit)
local MapPlan = require(Shared.Match.MapPlan)
local RobloxLevel = require(Shared.Combat.RobloxLevel)
local Units = require(Shared.Units)

local MapDresser = {}

-- A piece of cover dressed: its model, and what it was built from.
type Dressed = { model: Model, piece: string, name: string, look: number, frame: CFrame, size: vector, folder: Instance }
local dressed: { Dressed } = {}

-- The folder of a map's model its kit's models go in.
local KIT = "Kit"
-- A sign's text, in pixels per stud.
local SIGN_PIXELS = 20

local function colour(c: MapKit.Colour): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function material(name: string): Enum.Material
	local ok, value = pcall(function(): any
		return (Enum.Material :: any)[name]
	end)
	return if ok and value then value else Enum.Material.SmoothPlastic
end

-- A part in a look: its colour and material, and how bullets go through it
-- whatever its material (RobloxLevel).
local function apply(p: BasePart, look: MapKit.Look)
	p.Color = colour(look.colour)
	p.Material = material(look.material)
	p:SetAttribute(RobloxLevel.ATTRIBUTE, look.penetration)
end

-- A part only to look at.
local function forShow(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end

local function faceOf(face: string?): Enum.NormalId
	if face == "+x" then
		return Enum.NormalId.Right
	elseif face == "-x" then
		return Enum.NormalId.Left
	elseif face == "+z" then
		return Enum.NormalId.Back
	elseif face == "-z" then
		return Enum.NormalId.Front
	end
	return Enum.NormalId.Top
end

-- The frame of a piece's box, in the place: the middle of its base, its x
-- along the box's longer side. And the box's size in that frame.
local function frameOf(spec: MapPlan.Part, origin: vector): (CFrame, vector)
	local base = origin + spec.center - vector.create(0, spec.size.y / 2, 0)
	local along = spec.size.x >= spec.size.z
	local size = if along then spec.size else vector.create(spec.size.z, spec.size.y, spec.size.x)
	local turn = spec.yaw + (if along then 0 else math.pi / 2)
	return CFrame.new(Units.toStuds(base)) * CFrame.Angles(0, turn, 0), size
end

-- The kit's placeholder for a piece: its bits, in the frame of its box.
local function placeholder(piece: string, look: number, frame: CFrame, size: vector): Model
	local model = Instance.new("Model")
	for _, bit in MapKit.bits(piece, size, look) do
		local p = Instance.new("Part")
		p.Name = bit.name
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		local cf = frame * CFrame.new(Units.toStuds(bit.offset))
		if bit.shape == "cylinder" then
			-- A cylinder's axis is its x: stood up.
			p.Shape = Enum.PartType.Cylinder
			p.Size = Units.toStuds(vector.create(bit.size.y, bit.size.x, bit.size.z))
			cf *= CFrame.Angles(0, 0, math.pi / 2)
		elseif bit.shape == "ball" then
			p.Shape = Enum.PartType.Ball
			p.Size = Units.toStuds(bit.size)
		else
			p.Size = Units.toStuds(bit.size)
		end
		p.CFrame = cf
		p.Color = colour(bit.colour)
		p.Material = material(bit.material)
		forShow(p)
		p.Parent = model
	end
	return model
end

-- A model of the kit folder's, fitted to a piece's box: as big as fits in
-- it, the long side of the model's own box (its x) along the box's, and the
-- middle of its base on the box's.
local function fitted(template: Model, frame: CFrame, size: vector): Model
	local model = template:Clone()
	local _, extents = model:GetBoundingBox()
	local box = Units.toStuds(size)
	local scale = math.min(box.X / extents.X, box.Y / extents.Y, box.Z / extents.Z)
	if scale > 0 and scale < math.huge then
		model:ScaleTo(model:GetScale() * scale)
	end
	local cf, grown = model:GetBoundingBox()
	local base = cf * CFrame.new(0, -grown.Y / 2, 0)
	model:PivotTo(frame * base:ToObjectSpace(model:GetPivot()))
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			forShow(d)
		end
	end
	return model
end

-- The kit folder's model for a piece, if it has one with parts in it.
local function templateOf(piece: string): Model?
	local kit = ServerStorage:FindFirstChild(MapKit.FOLDER)
	local template = if kit then kit:FindFirstChild(piece) else nil
	if template and template:IsA("Model") and template:FindFirstChildWhichIsA("BasePart", true) then
		return template
	end
	return nil
end

-- A dressed piece's model: the kit folder's, fitted, or the placeholder.
local function build(d: Dressed): Model
	local template = templateOf(d.piece)
	local model = if template then fitted(template, d.frame, d.size) else placeholder(d.piece, d.look, d.frame, d.size)
	model.Name = d.name
	model:SetAttribute(MapKit.ATTRIBUTE, d.piece)
	model.Parent = d.folder
	return model
end

-- Builds every dressed piece of `piece`'s name again (of every name, for
-- nil), as the kit folder has it now.
local function redress(piece: string?)
	for _, d in dressed do
		if piece == nil or d.piece == piece then
			local old = d.model
			d.model = build(d)
			old:Destroy()
		end
	end
end

-- The piece of cover `p` as the kit's piece it is: the box unseen, and the
-- piece's model over it, in the map model's Kit folder.
local function dressPiece(p: BasePart, spec: MapPlan.Part, piece: string, root: Instance, origin: vector)
	local info = MapKit.Pieces[piece]
	p.Transparency = 1
	p.CastShadow = false
	p:SetAttribute(MapKit.ATTRIBUTE, piece)
	if info then
		p:SetAttribute(RobloxLevel.ATTRIBUTE, info.penetration)
	end
	local folder: Instance? = root:FindFirstChild(KIT)
	if not folder then
		local made = Instance.new("Folder")
		made.Name = KIT
		made.Parent = root
		folder = made
	end
	local frame, size = frameOf(spec, origin)
	local d: Dressed = {
		model = Instance.new("Model"),
		piece = piece,
		name = spec.name,
		look = MapKit.lookOf(piece, spec.name, spec.look),
		frame = frame,
		size = size,
		folder = folder :: Instance,
	}
	d.model = build(d)
	table.insert(dressed, d)
end

-- A sign's text, on the face it shows.
local function signText(p: BasePart, text: string, face: string?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = faceOf(face)
	gui.PixelsPerStud = SIGN_PIXELS
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(245, 240, 228)
	label.Text = text
	label.Parent = gui
	gui.Parent = p
end

-- Dresses one of a map's parts, `p`, built from `spec` at `origin`, if it's
-- a dressed map's: returns whether it was, so it needs nothing more.
function MapDresser.dress(p: BasePart, spec: MapPlan.Part, root: Instance, origin: vector): boolean
	local zone = spec.zone
	local piece = spec.piece
	if zone then
		apply(p, MapKit.Themes[zone] or MapKit.Themes.plain)
		return true
	elseif spec.kind == "cover" and piece then
		dressPiece(p, spec, piece, root, origin)
		return true
	elseif spec.kind == "dressing" then
		local style = MapKit.Styles[spec.style or ""] or MapKit.Styles.building
		apply(p, style)
		if not style.solid then
			forShow(p)
			p.CastShadow = false
		end
		local text = spec.text
		if text then
			signText(p, text, spec.face)
		end
		if spec.style == "light" then
			local light = Instance.new("SurfaceLight")
			light.Face = Enum.NormalId.Bottom
			light.Range = 22
			light.Brightness = 1.4
			light.Angle = 120
			light.Color = colour(style.colour)
			light.Parent = p
		end
		return true
	end
	return false
end

-- Keeps every dressed piece as the kit folder has it while the server runs:
-- a model put in it, taken out or the folder itself added or removed shows
-- at once. A model is best put in whole, as a copy, since one built up in
-- the folder part by part is fitted as it was when it went in.
function MapDresser.watch()
	local function hook(folder: Instance)
		folder.ChildAdded:Connect(function(child: Instance)
			redress(child.Name)
		end)
		folder.ChildRemoved:Connect(function(child: Instance)
			redress(child.Name)
		end)
	end
	local folder = ServerStorage:FindFirstChild(MapKit.FOLDER)
	if folder then
		hook(folder)
	end
	ServerStorage.ChildAdded:Connect(function(child: Instance)
		if child.Name == MapKit.FOLDER then
			hook(child)
			redress(nil)
		end
	end)
	ServerStorage.ChildRemoved:Connect(function(child: Instance)
		if child.Name == MapKit.FOLDER then
			redress(nil)
		end
	end)
end

return MapDresser
