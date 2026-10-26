--!strict
-- The plan of the map being played, for Omen's From the Shadows (system
-- 43), whose map shows wherever he plays: the arena's map where a mode is
-- on (Minimap.planFor), and otherwise the course's. The course has no plan
-- of its own as the arena's maps and the spike maps do, so it's drawn from
-- its parts (Workspace's VFTestRange), as Minimap.planOf takes them. Each
-- part something collides with is seen from above as its footprint, turned
-- with it:
--   * a floor where its top is the ground and it's wide (the course's
--     floors)
--   * nothing where it hangs over the floor (the tunnel's roof) or is no
--     thicker than a marking
--   * a wall where it stands as tall as ArenaLayout's high crates, which
--     hide someone standing, and cover where it's lower, or tilted (a ramp,
--     drawn as all the floor it spans)
-- The markings on the floor collide with nothing, and aren't drawn. The
-- client draws it and the server checks the places asked for against it
-- (ShadowServer), each from the parts it has, built again as they change.

local Workspace = game:GetService("Workspace")

local ArenaConfig = require(script.Parent.Parent.Arena.ArenaConfig)
local ArenaLayout = require(script.Parent.Parent.Arena.ArenaLayout)
local Minimap = require(script.Parent.Minimap)
local Units = require(script.Parent.Parent.Units)

local PartsPlan = {}

-- The course's folder (TestRange).
PartsPlan.ROOT = "VFTestRange"

local S = Units.STUDS_PER_METRE
-- Metres, ours.
local GROUND = 0 -- the course's ground
local FLAT = 0.05 -- a top this near the ground is level with it
local THIN = 0.05 -- a part no thicker than this is a marking
local OVER = 1 -- a part whose bottom is this far over the ground hangs over it
local WIDE = 20 -- square metres: a floor's footprint is at least this
local UPRIGHT = 0.999 -- a part whose up is this near the vertical stands upright

local watched: Instance? = nil
local course: Minimap.Plan? = nil

-- How far a part reaches from its middle along each of the world's axes,
-- in studs, however it's turned.
local function reachOf(cf: CFrame, size: Vector3): Vector3
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local h = size / 2
	return Vector3.new(
		math.abs(r.X) * h.X + math.abs(u.X) * h.Y + math.abs(l.X) * h.Z,
		math.abs(r.Y) * h.X + math.abs(u.Y) * h.Y + math.abs(l.Y) * h.Z,
		math.abs(r.Z) * h.X + math.abs(u.Z) * h.Y + math.abs(l.Z) * h.Z
	)
end

-- A part as the plan draws it, or nil for nothing.
local function shapeOf(part: BasePart): Minimap.Shape?
	local cf = part.CFrame
	local reach = reachOf(cf, part.Size)
	local bottom, top = (cf.Position.Y - reach.Y) / S, (cf.Position.Y + reach.Y) / S
	if top - bottom <= THIN or bottom - GROUND >= OVER then
		return nil
	end
	local upright = math.abs(cf.UpVector.Y) >= UPRIGHT
	local centre = vector.create(cf.Position.X / S, 0, cf.Position.Z / S)
	local size, yaw
	if upright then
		local right = cf.RightVector
		size, yaw = vector.create(part.Size.X / S, 0, part.Size.Z / S), math.atan2(-right.Z, right.X)
	else
		size, yaw = vector.create(2 * reach.X / S, 0, 2 * reach.Z / S), 0
	end
	local kind: Minimap.Kind = "cover"
	if math.abs(top - GROUND) <= FLAT and size.x * size.z >= WIDE then
		kind = "floor"
	elseif upright and top - GROUND >= ArenaLayout.Heights.high.value then
		kind = "wall"
	end
	return { kind = kind, center = centre, size = size, yaw = yaw }
end

-- The course's plan, from the parts under `root`: nil with no floor.
local function build(root: Instance): Minimap.Plan?
	local shapes: { Minimap.Shape } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d.CanCollide then
			local shape = shapeOf(d)
			if shape then
				table.insert(shapes, shape)
			end
		end
	end
	return Minimap.planOf("course", shapes)
end

-- The course's plan, or nil without the course.
function PartsPlan.course(): Minimap.Plan?
	local root = Workspace:FindFirstChild(PartsPlan.ROOT)
	if not root then
		return nil
	end
	if root ~= watched then
		watched = root
		course = nil
		local function changed()
			course = nil
		end
		root.DescendantAdded:Connect(changed)
		root.DescendantRemoving:Connect(changed)
	end
	if not course then
		course = build(root)
	end
	return course
end

-- The plan of the map being played: the arena's map where a mode is on,
-- and otherwise the course's. Nil with neither.
function PartsPlan.inPlay(): Minimap.Plan?
	if Workspace:GetAttribute(ArenaConfig.ON) == true then
		local model = Workspace:FindFirstChild(ArenaConfig.MODEL)
		return if model then Minimap.planFor(Workspace:GetAttribute(ArenaConfig.MODE), model:GetAttribute("Map")) else nil
	end
	return PartsPlan.course()
end

return PartsPlan
