--!strict
-- Sage's Barrier Orb on the client (system 38): its targeter, and its walls
-- of ice.
--   * with the orb in hand, its targeter shows where fire would raise the
--     wall, as your simulation will place it (BarrierSim.place): a ghost of
--     each segment on its floor, turned as your kit has it, red in the buy
--     phase, when none goes up, and nothing where there's nowhere for it.
--     Once you've raised it, the ghost stays where it went until the
--     server's wall rises there
--   * every wall the server tells of (the Ability remote's "barrier"),
--     yours too, is kept on the server's clock for your own prediction
--     (PlayerController.barriers), which stops you at it and lifts you onto
--     it as the server's simulation does, for the shots' level
--     (ClientShots.barriers) and for the minimap (BarrierView.standing)
--   * and drawn as the frame on your screen reaches it: each segment a
--     block of ice rising out of its floor, glowing as it fortifies and
--     clouding over as it decays, and breaking into chips of ice with its
--     sound (GameSounds) as the server says ("break") or as its time's up,
--     when they all go together. Its rising is heard from AbilityEffects
-- In Workspace's VFBarriers each wall is a `Barrier` model while it stands,
-- each segment a `Segment` in it, and the targeter a `Targeter` model. They
-- all go when the server says every fire's out (a new round, "out").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local BarrierSim = require(Shared.Abilities.BarrierSim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local BoxMath = require(Shared.Movement.BoxMath)
local RobloxWorld = require(Shared.Movement.RobloxWorld)
local WeaponSim = require(Shared.Weapons.WeaponSim)
local Remotes = require(Shared.Net.Remotes)
local SoundConfig = require(Shared.Audio.SoundConfig)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local CameraController = require(script.Parent.CameraController)
local GameSounds = require(script.Parent.Audio.GameSounds)
local ClientShots = require(script.Parent.Combat.ClientShots)

local BarrierView = {}

local BO = AbilityConfig.BarrierOrb
local S = Units.STUDS_PER_METRE
local ICE = Color3.fromRGB(170, 225, 245)
local HARD = Color3.fromRGB(215, 245, 255) -- fortified
local GLOW = Color3.fromRGB(240, 252, 255) -- as it fortifies
local GHOST = Color3.fromRGB(150, 220, 255)
local REFUSED = Color3.fromRGB(235, 80, 70)
local CLOUDED = Color3.fromRGB(190, 200, 210) -- as its time runs out
-- A segment's ice is solid: nothing's seen through it (the VALORANT Wiki),
-- though the fog of war still sends whoever's behind it.
local GHOST_CLEAR = 0.75 -- how clear the targeter is
local CHIP_CLEAR = 0.2 -- and a chip of ice
local FLASH = 0.3 -- seconds a fortifying segment glows for (ours)
local CHIPS = 8 -- chips of ice a breaking segment scatters (ours)
local CHIP_TIME = 0.8 -- seconds they fly for
local GRAVITY = 9.81 -- metres a second squared, on the chips
local STALE = 1 -- seconds: a fortifying or a break the screen is this far past isn't heard
local WAIT = 1.5 -- seconds your ghost waits for the server's wall
-- Seconds a wall is kept for your prediction after its time's up, so moves
-- replayed after a correction still find it (ours: past SlowSim.LAG).
local AFTER = 2
local MIDDLE = vector.create(0, BO.height.value / 2, 0) -- where a segment's sounds come from, over its floor

-- A wall the server told of, as drawn: whose, its model and a part for
-- each segment (by its place in the row), the segments drawn gone, and
-- whether its fortifying has been heard.
type Shown = {
	wall: BarrierSim.Wall,
	model: Model?,
	parts: { [number]: Part },
	gone: { [number]: boolean },
	fortified: boolean,
}
type Chip = { part: Part, from: vector, velocity: vector, start: number }

local world = RobloxWorld.new()
local shown: { [string]: Shown } = {}
-- The walls the server's told of, on its clock, for the simulation and the
-- shots.
local walls: { BarrierSim.Wall } = {}
local chips: { Chip } = {}
local folder: Folder? = nil
local targeter: Model? = nil
local ghosts: { Part } = {}
-- Your last wall raised: where it went, its cast's tick and when (os.clock()).
local raised: { placed: BarrierSim.Placement, id: number, at: number }? = nil
local random = Random.new()

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFBarriers"
	made.Parent = Workspace
	folder = made
	return made
end

local function plain(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end

local function block(name: string, parent: Instance, colour: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	plain(p)
	p.Material = material
	p.Color = colour
	p.Transparency = 1
	p.Parent = parent
	return p
end

-- A part fitted to `box` (metres). Its axes are the box's along and up;
-- the third follows from them, which a box doesn't mind.
local function fit(part: BasePart, box: BoxMath.Box)
	part.Size = Units.toStuds(box.half * 2)
	part.CFrame = CFrame.fromMatrix(Units.toStuds(box.center), Units.asVector3(box.axes[1]), Units.asVector3(box.axes[2]))
end

-- Whether no wall goes up now: the arena's buy phase.
local function closed(): boolean
	if Workspace:GetAttribute(ArenaConfig.ON) ~= true then
		return false
	end
	local arena = Workspace:FindFirstChild(ArenaConfig.MODEL)
	return arena ~= nil and arena:GetAttribute("Phase") == "buy"
end

-- A sound of a wall's: yours from you, others' from them.
local function play(kind: string, at: vector, owner: number)
	if owner == PlayerController.entityId then
		GameSounds.playWorld(SoundConfig.Abilities[kind], at, "you")
	else
		GameSounds.playCast(kind, at, owner, true)
	end
end

-- A segment breaking at `box`: chips of ice thrown out of it, falling.
local function shatter(box: BoxMath.Box)
	local clock = os.clock()
	for _ = 1, CHIPS do
		local size = random:NextNumber(0.12, 0.3)
		local part = block("Chip", holder(), ICE, Enum.Material.Ice)
		part.Size = Vector3.one * size * S
		part.Transparency = CHIP_CLEAR
		local a, b, c = random:NextNumber(-1, 1), random:NextNumber(-1, 1), random:NextNumber(-1, 1)
		local h = box.half
		local from = box.center + box.axes[1] * (a * h.x) + box.axes[2] * (b * h.y) + box.axes[3] * (c * h.z)
		local out = box.axes[3] * (if c < 0 then -1 else 1) * random:NextNumber(1, 3)
		local velocity = out + box.axes[1] * random:NextNumber(-1.5, 1.5) + vector.create(0, random:NextNumber(1.5, 4), 0)
		table.insert(chips, { part = part, from = from, velocity = velocity, start = clock })
	end
end

local function forget(key: string)
	local s = shown[key]
	shown[key] = nil
	if s and s.model then
		s.model:Destroy()
	end
end

-- A wall from the server's word of it, or nil if it's malformed.
local function wallOf(event: any): BarrierSim.Wall?
	if typeof(event.centre) ~= "Vector3" or typeof(event.angle) ~= "number" or typeof(event.segments) ~= "table" then
		return nil
	end
	local segments: { BarrierSim.Segment } = {}
	for _, s in event.segments do
		if typeof(s) ~= "table" or typeof(s.index) ~= "number" or typeof(s.base) ~= "Vector3" then
			return nil
		end
		table.insert(segments, {
			index = s.index,
			base = Units.asVector(s.base),
			broken = if typeof(s.broken) == "number" then s.broken else nil,
		})
	end
	return {
		owner = event.entity,
		id = event.id,
		start = event.at,
		centre = Units.asVector(event.centre),
		angle = event.angle,
		segments = segments,
	}
end

local function clearAll()
	for key in shown do
		forget(key)
	end
	table.clear(walls)
	raised = nil
end

local function onEvent(event: any)
	if typeof(event) ~= "table" then
		return
	end
	if event.kind == "out" then
		clearAll()
		return
	end
	if
		event.ability ~= "barrierorb"
		or typeof(event.entity) ~= "number"
		or typeof(event.id) ~= "number"
		or typeof(event.at) ~= "number"
	then
		return
	end
	local key = event.entity .. ":" .. event.id
	if event.kind == "barrier" then
		if shown[key] then
			return
		end
		local wall = wallOf(event)
		if not wall then
			return
		end
		table.insert(walls, wall)
		shown[key] = { wall = wall, model = nil, parts = {}, gone = {}, fortified = false }
	elseif event.kind == "break" and typeof(event.index) == "number" then
		local s = shown[key]
		if not s then
			return
		end
		for _, segment in s.wall.segments do
			if segment.index == event.index then
				segment.broken = event.at
			end
		end
	end
end

local function onOwnCast(cast: AbilitySim.Cast)
	local placed = cast.wall
	if cast.kind == "barrier" and placed then
		raised = { placed = placed, id = cast.tick, at = os.clock() }
	end
end

local function build(s: Shown)
	local model = Instance.new("Model")
	model.Name = "Barrier"
	for _, segment in s.wall.segments do
		s.parts[segment.index] = block("Segment", model, ICE, Enum.Material.Ice)
	end
	model.Parent = holder()
	s.model = model
end

-- One wall a frame on, at `t` on the server's clock: false once it's all
-- gone.
local function frame(s: Shown, t: number): boolean
	local wall = s.wall
	local ends = BarrierSim.ends(wall)
	if t >= ends then
		-- Its time's up: what's left of it goes together, with one sound.
		local any = false
		for _, segment in wall.segments do
			if not s.gone[segment.index] then
				s.gone[segment.index] = true
				if t - ends < STALE then
					shatter(BarrierSim.box(wall, segment, ends - 1e-6))
					any = true
				end
			end
		end
		if any then
			play("shatter", wall.centre + MIDDLE, wall.owner)
		end
		return false
	end
	if t < wall.start then
		return true
	end
	if not s.model then
		build(s)
	end
	local fortifies = BarrierSim.fortifies(wall)
	if not s.fortified and t >= fortifies then
		s.fortified = true
		if t - fortifies < STALE then
			play("fortify", wall.centre + MIDDLE, wall.owner)
		end
	end
	local glow = if t >= fortifies then math.clamp(1 - (t - fortifies) / FLASH, 0, 1) else 0
	local decays = BarrierSim.decays(wall)
	local clouded = math.clamp((t - decays) / (ends - decays), 0, 1)
	for _, segment in wall.segments do
		local part = s.parts[segment.index]
		if not part then
			continue
		end
		if BarrierSim.standing(wall, segment, t) then
			fit(part, BarrierSim.box(wall, segment, t))
			local colour = if t >= fortifies then HARD:Lerp(GLOW, glow) else ICE
			part.Color = colour:Lerp(CLOUDED, clouded)
			part.Material = if glow > 0 then Enum.Material.Neon else Enum.Material.Ice
			part.Transparency = 0
		elseif not s.gone[segment.index] then
			-- Broken (by the server's word, or touching the planted spike as
			-- it rose).
			s.gone[segment.index] = true
			part.Transparency = 1
			local broken = segment.broken or t
			if t - broken < STALE then
				local box = BarrierSim.box(wall, segment, broken)
				shatter(box)
				play("shatter", box.center, wall.owner)
			end
		end
	end
	return true
end

-- The targeter's ghost of `placed`, `colour`.
local function ghost(placed: BarrierSim.Placement?, colour: Color3)
	local model = targeter
	if not model or not model.Parent then
		local made = Instance.new("Model")
		made.Name = "Targeter"
		made.Parent = holder()
		model = made
		targeter = made
		table.clear(ghosts)
		for i = 1, BO.segments.value do
			ghosts[i] = block("Ghost", made, GHOST, Enum.Material.ForceField)
		end
	end
	for _, part in ghosts do
		part.Transparency = 1
	end
	if not placed then
		return
	end
	-- Risen all the way.
	local wall = BarrierSim.raise(0, 0, 0, placed)
	for _, segment in wall.segments do
		local part = ghosts[segment.index]
		if part then
			fit(part, BarrierSim.box(wall, segment, BO.rise.value))
			part.Color = colour
			part.Transparency = GHOST_CLEAR
		end
	end
end

-- With the orb in hand, where fire would raise its wall; after, where it
-- went until the server's rises there.
local function aimFrame(render: number)
	local s = PlayerController.sim
	local w = if s then s.weapons else nil
	local kit = if s then s.abilities else nil
	if
		s
		and w
		and kit
		and PlayerController.alive
		and w.equipped == WeaponSim.ULT
		and w.loadout[WeaponSim.ULT] == "wallorb"
		and kit.holding ~= 0
	then
		local camera = Workspace.CurrentCamera.CFrame
		local angle = if kit.turning then kit.fixed else BarrierSim.angle(CameraController.yaw, kit.turn)
		local placed = BarrierSim.place(
			BarrierSim.world(world, walls, render),
			Units.toMetres(camera.Position),
			Units.asVector(camera.LookVector),
			angle
		)
		ghost(placed, if closed() then REFUSED else GHOST)
		return
	end
	local r = raised
	if r then
		local rose = shown[PlayerController.entityId .. ":" .. r.id]
		if os.clock() - r.at > WAIT or (rose and render >= rose.wall.start) then
			raised = nil
		else
			ghost(r.placed, GHOST)
			return
		end
	end
	ghost(nil, GHOST)
end

-- The segments standing as your screen shows them now, for the minimap:
-- each one's ends, along the middle of its floor, and whose it is.
function BarrierView.standing(): { { points: { vector }, entity: number } }
	local render = RemoteEntities.renderTime()
	local out = {}
	for _, s in shown do
		local wall = s.wall
		local along = BarrierSim.axes(wall.angle) * (BO.length.value / 2)
		for _, segment in wall.segments do
			if BarrierSim.standing(wall, segment, render) then
				table.insert(out, { points = { segment.base - along, segment.base + along }, entity = wall.owner })
			end
		end
	end
	return out
end

function BarrierView.start()
	PlayerController.barriers = function(time: number): BarrierSim.Walls
		return { walls = walls, time = time, closed = closed() }
	end
	ClientShots.barriers = function(): { BarrierSim.Wall }
		return walls
	end
	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()
		for key, s in shown do
			if not frame(s, render) then
				forget(key)
			end
		end
		for i = #walls, 1, -1 do
			if render > BarrierSim.ends(walls[i]) + AFTER then
				table.remove(walls, i)
			end
		end
		aimFrame(render)
		for i = #chips, 1, -1 do
			local c = chips[i]
			local age = clock - c.start
			if age >= CHIP_TIME or c.part.Parent == nil then
				c.part:Destroy()
				table.remove(chips, i)
				continue
			end
			local at = c.from + c.velocity * age + vector.create(0, -GRAVITY / 2 * age * age, 0)
			c.part.CFrame = CFrame.new(Units.toStuds(at)) * CFrame.Angles(age * 7, age * 5, 0)
			c.part.Transparency = CHIP_CLEAR + (1 - CHIP_CLEAR) * age / CHIP_TIME
		end
	end)
end

return BarrierView
