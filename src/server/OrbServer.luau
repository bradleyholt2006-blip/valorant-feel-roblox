--!strict
-- The spike rounds' Ultimate Orbs on the server (system 49). UltimateOrbs
-- keeps which are up; this puts them on the map played, all up as each
-- round starts (Arena says when), and gives a point of the ultimate to
-- whoever's simulation takes one (SpikeSim's "collected"):
--   * each is a gold ball over a mark on the floor, as Team Deathmatch's
--     Ultimate Orbs are (PickupsServer), there while it's up
--   * which are up goes to clients as Workspace's attribute
--     (UltimateOrbs.UP), and into everyone's simulation with the spike's
--     context (SpikeServer.setOrbs), so it can be taken
--   * an orb two take on the same tick goes to whichever the server steps
--     first; the other's taking ends with nothing gained
-- Everything is in Workspace.VFUltimateOrbs, built for the map played and
-- gone once the spike rounds are over. None of it collides with anything,
-- stops a shot or is seen by a query.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local SpikeSim = require(Shared.Spike.SpikeSim)
local UltimateOrbs = require(Shared.Spike.UltimateOrbs)
local Units = require(Shared.Units)

local AbilityServer = require(script.Parent.AbilityServer)
local PlayerSimServer = require(script.Parent.PlayerSimServer)
local SpikeServer = require(script.Parent.SpikeServer)

local OrbServer = {}

OrbServer.MODEL = "VFUltimateOrbs"

-- An orb: how wide, and how high its middle is over the floor; and the
-- mark under it. Team Deathmatch's sizes and gold.
local ORB_WIDTH, ORB_HEIGHT = 0.5, 1.0
local MARK_WIDTH = 1.2
local GOLD = Color3.fromRGB(230, 200, 120)

type Orb = { ball: Part, light: PointLight }

local state: UltimateOrbs.State? = nil
local root: Model? = nil
local built: { Orb } = {}

local function newPart(name: string, size: vector, cframe: CFrame, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = Units.toStuds(size)
	p.CFrame = cframe
	p.Color = GOLD
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function folder(): Model
	local made = root
	if made and made.Parent then
		return made
	end
	local model = Instance.new("Model")
	model.Name = OrbServer.MODEL
	-- Every client has every orb, however far away it is.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = Workspace
	root = model
	return model
end

-- Every part gone.
local function clearAll()
	table.clear(built)
	local made = root
	if made then
		made:ClearAllChildren()
	end
end

-- The orbs of the map `layout`, in place of the last map's, none up.
local function build(layout: string): UltimateOrbs.State
	clearAll()
	local s = UltimateOrbs.new(layout)
	state = s
	local parent = folder()
	for i, at in s.places do
		local name = "UltimateOrb" .. i
		-- The mark: a disc lying flat on the floor.
		local mark = newPart(
			name .. "Mark",
			vector.create(0.02, MARK_WIDTH, MARK_WIDTH),
			CFrame.new(Units.toStuds(at + vector.create(0, 0.01, 0))) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.SmoothPlastic
		)
		mark.Shape = Enum.PartType.Cylinder
		mark.Transparency = 0.6
		mark.Parent = parent
		local centre = Units.toStuds(at + vector.create(0, ORB_HEIGHT, 0))
		local ball = newPart(name, vector.create(ORB_WIDTH, ORB_WIDTH, ORB_WIDTH), CFrame.new(centre), Enum.Material.Neon)
		ball.Shape = Enum.PartType.Ball
		ball.Transparency = 1
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 10
		light.Brightness = 1.5
		light.Enabled = false
		light.Parent = ball
		ball.Parent = parent
		built[i] = { ball = ball, light = light }
	end
	return s
end

-- Which are up, to clients, to everyone's simulation, and on the map.
local function publish()
	local s = state
	Workspace:SetAttribute(UltimateOrbs.UP, if s then UltimateOrbs.encode(s) else nil)
	SpikeServer.setOrbs(if s then UltimateOrbs.upOf(s) else nil)
	for i, orb in built do
		local up = s ~= nil and s.up[i] == true
		orb.ball.Transparency = if up then 0 else 1
		orb.light.Enabled = up
	end
end

-- As a round of the spike rounds starts on the map `layout`: its orbs,
-- every one up.
function OrbServer.roundStarted(layout: string)
	local s = state
	local orbs = if s and s.layout == layout then s else build(layout)
	UltimateOrbs.roundStarted(orbs)
	publish()
end

-- The spike rounds over: no orbs.
function OrbServer.stop()
	if state == nil then
		return
	end
	state = nil
	clearAll()
	publish()
end

-- An orb a player's simulation has taken: theirs, with its point, if it's
-- still up.
local function onAct(player: Player, act: SpikeSim.Act)
	local s, orb = state, act.orb
	if act.kind ~= "collected" or not s or not orb then
		return
	end
	if UltimateOrbs.take(s, orb) then
		AbilityServer.addPoints(player, AbilityConfig.Points.orb.value)
		publish()
	end
end

function OrbServer.start()
	table.insert(PlayerSimServer.spikeListeners, onAct)
end

return OrbServer
