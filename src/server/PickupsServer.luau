--!strict
-- Team Deathmatch's pickups on the server (system 28). TeamDeathmatchRules
-- keeps them; this puts them on the map played and has them taken:
--   * each weapon spawner is a pad on the floor, its ring lit while it has a
--     gun, and the gun lies on it as a gun on the ground
--     (GroundGunsServer.place), taken the ground guns' ways: walked over
--     into an empty slot, or with F in place of the gun in its slot. The
--     rules lend it there (TeamDeathmatchRules.take), and Arena hands the
--     loadout's gun back once it's spent or dropped
--   * each Recovery Orb and Ultimate Orb is a glowing ball over a mark on
--     the floor, up or not as the rules have it, taken by whoever alive runs
--     over it first. A Recovery Orb's buff mends its taker a few times a
--     second (CombatServer.mend), and the zone it leaves glows on the floor
--     while it lasts, mending the taker's allies who walk in; an Ultimate
--     Orb's points go to its taker (AbilityServer.addPoints)
-- Everything is in Workspace.VFPickups, built for the map played and gone
-- once Team Deathmatch is over. None of it collides with anything, stops a
-- shot or is seen by a query.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local TeamDeathmatchConfig = require(Shared.Arena.TeamDeathmatchConfig)
local TeamDeathmatchRules = require(Shared.Arena.TeamDeathmatchRules)
local SpikeMaps = require(Shared.Match.SpikeMaps)
local GroundGuns = require(Shared.Weapons.GroundGuns)
local Units = require(Shared.Units)

local AbilityServer = require(script.Parent.AbilityServer)
local CombatServer = require(script.Parent.CombatServer)
local GroundGunsServer = require(script.Parent.GroundGunsServer)
local PlayerSimServer = require(script.Parent.PlayerSimServer)

local PickupsServer = {}

PickupsServer.MODEL = "VFPickups"

local T = TeamDeathmatchConfig.Rules
-- How often a Recovery Orb's buff mends, at most (ours): a few times a
-- second, each told to clients.
local MEND_EVERY = 0.25
-- A spawner's pad: how wide and how tall, its gun on top; and its ring.
local PAD_WIDTH, PAD_HEIGHT = 1.4, 0.1
local RING_WIDTH = 1.7
-- An orb: how wide, and how high its middle is over the floor; and the
-- mark under it.
local ORB_WIDTH, ORB_HEIGHT = 0.5, 1.0
local MARK_WIDTH = 1.2

local PAD_GREY = Color3.fromRGB(60, 62, 70)
local RING_LIT = Color3.fromRGB(235, 235, 240)
local RING_DIM = Color3.fromRGB(85, 88, 98)
local RECOVERY_GREEN = Color3.fromRGB(80, 230, 150)
local ULTIMATE_GOLD = Color3.fromRGB(230, 200, 120)

type Orb = { ball: Part, light: PointLight, up: boolean }

local current: TeamDeathmatchRules.State? = nil
local root: Model? = nil
local builtFor: string? = nil
local rings: { Part } = {}
local recovery: { Orb } = {}
local ultimate: { Orb } = {}
local zones: { [TeamDeathmatchRules.Zone]: Part } = {}
-- Each spawner's gun on the ground, as last put there: its id and weapon.
local placed: { [number]: { id: number, weapon: string } } = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function newPart(name: string, size: vector, cframe: CFrame, colour: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = Units.toStuds(size)
	p.CFrame = cframe
	p.Color = colour
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- A disc lying flat on the floor at `at` (metres), `height` thick.
local function disc(name: string, at: vector, width: number, height: number, colour: Color3, material: Enum.Material): Part
	local cframe = CFrame.new(Units.toStuds(at + vector.create(0, height / 2, 0))) * CFrame.Angles(0, 0, math.rad(90))
	local p = newPart(name, vector.create(height, width, width), cframe, colour, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function folder(): Model
	local made = root
	if made and made.Parent then
		return made
	end
	local model = Instance.new("Model")
	model.Name = PickupsServer.MODEL
	-- Every client has every pickup, however far away it is.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = Workspace
	root = model
	return model
end

-- An orb over its mark at `at` (metres, on the floor), down to start with.
local function newOrb(name: string, at: vector, colour: Color3, parent: Instance): Orb
	local mark = disc(name .. "Mark", at, MARK_WIDTH, 0.02, colour, Enum.Material.SmoothPlastic)
	mark.Transparency = 0.6
	mark.Parent = parent
	local centre = Units.toStuds(at + vector.create(0, ORB_HEIGHT, 0))
	local ball = newPart(name, vector.create(ORB_WIDTH, ORB_WIDTH, ORB_WIDTH), CFrame.new(centre), colour, Enum.Material.Neon)
	ball.Shape = Enum.PartType.Ball
	ball.Transparency = 1
	local light = Instance.new("PointLight")
	light.Color = colour
	light.Range = 10
	light.Brightness = 1.5
	light.Enabled = false
	light.Parent = ball
	ball.Parent = parent
	return { ball = ball, light = light, up = false }
end

-- The guns on the spawners off the ground, and every part gone.
local function clearAll()
	for _, gun in placed do
		GroundGunsServer.remove(gun.id)
	end
	table.clear(placed)
	table.clear(rings)
	table.clear(recovery)
	table.clear(ultimate)
	table.clear(zones)
	builtFor = nil
	local made = root
	if made then
		made:ClearAllChildren()
	end
end

-- The pads and orbs of the map `key`, in place of the last map's.
local function build(key: string)
	clearAll()
	builtFor = key
	local plan = TeamDeathmatchConfig.Pickups[key]
	local map = SpikeMaps.Maps[key]
	if not plan or not map then
		return
	end
	local parent = folder()
	for i, at in plan.spawners do
		local feet = map.origin + at
		disc("SpawnerPad" .. i, feet, PAD_WIDTH, PAD_HEIGHT, PAD_GREY, Enum.Material.SmoothPlastic).Parent = parent
		local ring = disc("SpawnerRing" .. i, feet, RING_WIDTH, PAD_HEIGHT / 2, RING_DIM, Enum.Material.Neon)
		ring.Parent = parent
		rings[i] = ring
	end
	for i, at in plan.recovery do
		recovery[i] = newOrb("RecoveryOrb" .. i, map.origin + at, RECOVERY_GREEN, parent)
	end
	for i, at in plan.ultimate do
		ultimate[i] = newOrb("UltimateOrb" .. i, map.origin + at, ULTIMATE_GOLD, parent)
	end
end

local function show(orb: Orb, up: boolean)
	if orb.up ~= up then
		orb.up = up
		orb.ball.Transparency = if up then 0 else 1
		orb.light.Enabled = up
	end
end

-- The parts as the rules have the pickups now, and each spawner's gun on
-- the ground: put there as it has one, and taken away for another (a new
-- stage's) or none.
local function sync(t: TeamDeathmatchRules.State)
	if builtFor ~= t.map then
		build(t.map)
	end
	local plan = TeamDeathmatchRules.pickupsOf(t)
	local map = SpikeMaps.Maps[t.map]
	if not plan or not map then
		return
	end
	for i, at in plan.spawners do
		local gun = TeamDeathmatchRules.spawnerGun(t, i)
		local have = placed[i]
		local stale = have ~= nil and (not gun or gun.gun ~= have.weapon or not GroundGunsServer.has(have.id))
		if have and stale then
			GroundGunsServer.remove(have.id)
			placed[i] = nil
		end
		if gun and (not have or stale) then
			local top = map.origin + at + vector.create(0, PAD_HEIGHT, 0)
			placed[i] = { id = GroundGunsServer.place(gun.gun, gun.ammo, gun.reserve, top, 0, i), weapon = gun.gun }
		end
		local ring = rings[i]
		if ring then
			ring.Color = if gun then RING_LIT else RING_DIM
		end
	end
	for i, orb in recovery do
		show(orb, t.recovery[i] ~= nil and t.recovery[i].up)
	end
	for i, orb in ultimate do
		show(orb, t.ultimate[i] ~= nil and t.ultimate[i].up)
	end
	-- Each zone glows on the floor while it lasts.
	local lasting: { [TeamDeathmatchRules.Zone]: boolean } = {}
	for _, zone in t.zones do
		lasting[zone] = true
		if not zones[zone] then
			local glow =
				disc("RecoveryZone", map.origin + zone.position, T.zoneRadius.value * 2, 0.03, RECOVERY_GREEN, Enum.Material.ForceField)
			glow.Transparency = 0.3
			glow.Parent = folder()
			zones[zone] = glow
		end
	end
	for zone, glow in zones do
		if not lasting[zone] then
			glow:Destroy()
			zones[zone] = nil
		end
	end
end

-- Whoever alive and in play runs over an orb takes it: a Recovery Orb's
-- buff starts on them (the rules), and an Ultimate Orb's points are theirs.
local function pickUps(t: TeamDeathmatchRules.State, time: number, origin: vector)
	for id, member in t.members do
		local player = if member.alive then Players:GetPlayerByUserId(id) else nil
		local sim = if player and PlayerSimServer.inPlay(player) then PlayerSimServer.getSim(player) else nil
		if player and sim and TeamDeathmatchRules.pickUp(t, id, sim.movement.position - origin, time) == "ultimate" then
			AbilityServer.addPoints(player, AbilityConfig.TeamDeathmatch.orb.value)
		end
	end
end

-- Everyone under a Recovery Orb's buff mended by what's come of it since
-- they last were, a few times a second and as it ends: a share of their
-- most health and shield.
local function mend(t: TeamDeathmatchRules.State, time: number)
	local due: { number } = {}
	for id, buff in t.mending do
		if time - buff.from >= MEND_EVERY or time >= buff.ends then
			table.insert(due, id)
		end
	end
	for _, id in due do
		local share = TeamDeathmatchRules.mended(t, id, time)
		local player = Players:GetPlayerByUserId(id)
		local entity = if player then PlayerSimServer.entityOf(player) else nil
		if entity and share > 0 then
			local h = entity.health
			CombatServer.mend(entity, h.maxHealth * share, h.maxShield * share)
		end
	end
end

-- Once a server frame while Team Deathmatch is played (Arena), after its
-- rules have moved on.
function PickupsServer.step(t: TeamDeathmatchRules.State, time: number)
	current = t
	local map = SpikeMaps.Maps[t.map]
	if map then
		pickUps(t, time, map.origin)
	end
	mend(t, time)
	sync(t)
end

-- Team Deathmatch is over: no pickups, and nothing on the spawners.
function PickupsServer.stop()
	current = nil
	clearAll()
end

function PickupsServer.start()
	-- A spawner's gun taken: lent its taker in its slot, and the spawner
	-- empty for its wait.
	GroundGunsServer.spawnerTaken = function(player: Player, gun: GroundGuns.Gun)
		local t = current
		local index = gun.spawner
		if t and index then
			TeamDeathmatchRules.take(t, player.UserId, index, now())
		end
	end
end

return PickupsServer
