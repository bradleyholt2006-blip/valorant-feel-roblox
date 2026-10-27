--!strict
-- Sova's Owl Drone on the client (system 47): your flight's time and the
-- dart's cooldown, the drones you have, their darts, whom they strike and
-- their pings, and a drone shot down.
--   * flying it, your view's the drone's (PlayerController), its edges
--     tinted, and under the crosshair a bar for the time it has left,
--     emptying as it runs, and under it a second, filling through the
--     dart's cooldown, full once the next can go. Your body stands where you
--     left it, drawn as everyone else's is (RemoteEntities.placeBoxes)
--   * every other drone you have (the snapshots, RemoteEntities.drones) is
--     a small dark body, its box, with its lens to the front and a rotor to
--     either side in your side's colour or the enemies', facing the way it
--     looks, humming as it flies (as far as the ability curve carries).
--     Yours isn't drawn while you fly it, as the view's inside it, but you
--     hear its hum
--   * a dart is a thin streak from the drone to where it ended, with its
--     sound: yours at once, from your tick, to where your screen had the
--     level and everyone; others' as the frame on your screen reaches them
--     (the Ability remote's "dart"). One of yours that struck someone shows
--     '[Target Hit]' for its hitText (Patch 4.08: '[Target Hit]
--     confirmation text now remains on screen for 2s, previously 1s'),
--     with the strike's sound; whoever it struck hears the strike and sees
--     TAGGED until its last ping's reveal is over (ours)
--   * each of its pings ("dartping") shows your side whom it revealed, for
--     the reveal's time (ReconView.reveal), with its sound where they
--     stood; whoever it struck hears it too
--   * a drone shot down ("dronedown") bursts into shards where it was
--     struck, with its sound
-- The drones are in the level your shots are traced through
-- (ClientShots.drones), as the server's are in its own. In Workspace's
-- VFDrone each drone is a `Drone_<id>` model, your body while you fly a
-- `Body` model, each dart a `Dart` part and each burst's pieces `Shard`
-- parts; the darts and shards go when the server says every fire's out (a
-- new round, "out"). The `VFDrone` gui's attributes say whether you fly it
-- (`Flying`), the seconds it has left (`Left`), the seconds until a dart
-- can go (`DartIn`), whether '[Target Hit]' shows (`TargetHit`), whether
-- you're tagged (`Tagged`) and the drones drawn (`Drones`), which scripted
-- checks read.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared.Abilities.AbilityConfig)
local AbilitySim = require(Shared.Abilities.AbilitySim)
local DroneSim = require(Shared.Abilities.DroneSim)
local ArenaConfig = require(Shared.Arena.ArenaConfig)
local Hitboxes = require(Shared.Combat.Hitboxes)
local Penetration = require(Shared.Combat.Penetration)
local ShotResolver = require(Shared.Combat.ShotResolver)
local MovementConfig = require(Shared.Movement.MovementConfig)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Remotes = require(Shared.Net.Remotes)
local SoundConfig = require(Shared.Audio.SoundConfig)
local VisualConfig = require(Shared.Visuals.VisualConfig)
local Units = require(Shared.Units)

local NetSim = require(script.Parent.NetSim)
local PlayerController = require(script.Parent.PlayerController)
local RemoteEntities = require(script.Parent.RemoteEntities)
local ReconView = require(script.Parent.ReconView)
local Visuals = require(script.Parent.Visuals)
local ClientShots = require(script.Parent.Combat.ClientShots)
local GameSounds = require(script.Parent.Audio.GameSounds)
local Ui = require(script.Parent.Debug.Ui)

local DroneView = {}

local DR = AbilityConfig.OwlDrone
local DT = 1 / MovementConfig.TickRate.value
local S = Units.STUDS_PER_METRE
local LIGHT = Color3.fromRGB(95, 175, 255)
local DIM = Color3.fromRGB(70, 72, 80)
local SHELL = Color3.fromRGB(38, 40, 46)
local CHEST = vector.create(0, 1.3, 0) -- metres above the feet a ping's heard from
local BELOW_EYE = vector.create(0, -0.08, 0) -- from the drone's middle to where your darts are drawn from, metres (ours)
local HUM_EVERY = 0.4 -- seconds from one of a drone's hums to the next (ours)
local SPIN = 40 -- radians a second its rotors turn, drawn (ours)
local STREAK = 0.25 -- seconds a dart's streak takes to fade (ours)
local STREAK_WIDTH = 0.02 -- metres across
local SHARDS = 8 -- pieces a drone bursts into (ours)
local SHARD_TIME = 0.6 -- seconds they fly and fade (ours)
local STALE = 1 -- seconds: an event the screen is this far past isn't shown
local BAR_W, BAR_H, BAR_GAP = 80, 4, 4 -- pixels
local BELOW = 30 -- pixels under the crosshair
local EDGE = 24 -- pixels: how far the tint reaches in from the screen's edges while you fly

-- A dart, a ping or a drone shot down that the server told of, until the
-- frame on your screen reaches it: whose, where it went from and to (a
-- ping's where they stood, a burst's where it was struck), whom it struck,
-- and for a ping, whom it revealed to your side, with where the server
-- said they stood.
type Due = {
	kind: string,
	at: number,
	entity: number,
	origin: vector,
	to: vector,
	struck: number?,
	ids: { number },
	poses: { [number]: Hitboxes.Pose },
}

-- A drone drawn: its model, its parts, and when it last hummed (os.clock()).
type Drawn = { model: Model, body: Part, lens: Part, rotors: { Part }, hummed: number }

-- A streak or a shard drawn: from where, how it flies (nil for one that
-- stays), and when it started (os.clock()) and for how long.
type Fading = { part: Part, from: vector, velocity: vector?, start: number, time: number }

local folder: Folder? = nil
local due: { Due } = {}
local drawn: { [number]: Drawn } = {}
local fading: { Fading } = {}
-- Your drones' ids, from your `VFDroneId`, until the snapshots have them no
-- more: never drawn, nor in your shots' level.
local mine: { [number]: boolean } = {}
local body: Model? = nil
local bodyParts: { [string]: BasePart } = {}
local hitUntil = 0 -- os.clock()
local taggedUntil = 0 -- os.clock()
local ownHummed = 0 -- os.clock()

local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "VFDrone"
	made.Parent = Workspace
	folder = made
	return made
end

local function plain(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

local function colour(c: VisualConfig.Colour): Color3
	return Color3.fromRGB(c.rgb[1], c.rgb[2], c.rgb[3])
end

-- Whether `entity` is you or on your side.
local function friendly(entity: number): boolean
	if entity == PlayerController.entityId then
		return true
	end
	local side = Players.LocalPlayer:GetAttribute(ArenaConfig.SIDE)
	if side == nil then
		return false
	end
	for _, player in Players:GetPlayers() do
		if PlayerCodec.entityIdForUser(player.UserId) == entity then
			return player:GetAttribute(ArenaConfig.SIDE) == side
		end
	end
	return false
end

-- Something of `entity`'s: your side's colour, or the enemies'.
local function tint(entity: number?): Color3
	if entity and friendly(entity) then
		return colour(VisualConfig.allyColour)
	end
	local option = VisualConfig.EnemyColours[Visuals.enemyColour] or VisualConfig.EnemyColours[1]
	return colour(option.colour)
end

-- Whose drone `id` is, by their entity id, while the server has it flying.
local function ownerOf(id: number): number?
	for _, player in Players:GetPlayers() do
		if player:GetAttribute(DroneSim.ID_ATTRIBUTE) == id then
			return PlayerCodec.entityIdForUser(player.UserId)
		end
	end
	return nil
end

-- A sound of the drone's out in the world at `at`: yours, or `entity`'s.
local function play(kind: string, at: vector, own: boolean, entity: number, follow: (() -> vector?)?)
	local sound = SoundConfig.Abilities[kind]
	if not sound then
		return
	end
	GameSounds.playWorld(sound, at, if own then "you" else RemoteEntities.nameOf(entity), { follow = follow })
end

local function newDrone(id: number): Drawn
	local model = Instance.new("Model")
	model.Name = "Drone_" .. id
	local b = Instance.new("Part")
	b.Name = "Body"
	plain(b)
	b.Material = Enum.Material.SmoothPlastic
	b.Color = SHELL
	b.Size = Units.toStuds(DroneSim.half() * 2)
	b.Parent = model
	local lens = Instance.new("Part")
	lens.Name = "Lens"
	plain(lens)
	lens.Material = Enum.Material.Neon
	lens.Size = Units.toStuds(vector.create(0.1, 0.08, 0.02))
	lens.Parent = model
	local rotors: { Part } = {}
	for _ = 1, 2 do
		local r = Instance.new("Part")
		r.Name = "Rotor"
		plain(r)
		r.Material = Enum.Material.Neon
		r.Transparency = 0.35
		r.Size = Units.toStuds(vector.create(0.22, 0.01, 0.22))
		r.Parent = model
		table.insert(rotors, r)
	end
	model.Parent = holder()
	return { model = model, body = b, lens = lens, rotors = rotors, hummed = 0 }
end

-- A drone where `pose` has it, in `light`: its body square to the world, as
-- its box is (DroneSim.box), and its lens and rotors turned the way it
-- looks.
local function place(d: Drawn, pose: PlayerCodec.Pose, light: Color3, clock: number)
	local half = DroneSim.half()
	d.body.CFrame = CFrame.new(Units.toStuds(pose.position))
	local turned = CFrame.new(Units.toStuds(pose.position)) * CFrame.Angles(0, pose.yaw, 0)
	d.lens.CFrame = turned * CFrame.new(0, 0, -(half.z * 0.95 + 0.01) * S)
	d.lens.Color = light
	for i, r in d.rotors do
		local side = if i == 1 then 1 else -1
		local at = turned * CFrame.new(side * (half.x + 0.1) * S, half.y * 0.6 * S, 0)
		r.CFrame = at * CFrame.Angles(0, clock * SPIN * side, 0)
		r.Color = light
	end
end

-- Your body as it stands while you fly: a part for each of its boxes, in
-- your side's colour.
local function newBody(): Model
	local model = Instance.new("Model")
	model.Name = "Body"
	table.clear(bodyParts)
	for _, region in { "head", "body", "legs" } do
		local p = Instance.new("Part")
		p.Name = region
		plain(p)
		p.Material = Enum.Material.SmoothPlastic
		p.Color = colour(VisualConfig.allyColour)
		p.Parent = model
		bodyParts[region] = p
	end
	return model
end

-- A dart's streak from `from` to `to`, fading.
local function streak(from: vector, to: vector, light: Color3)
	local length = vector.magnitude(to - from)
	if length < 1e-3 then
		return
	end
	local p = Instance.new("Part")
	p.Name = "Dart"
	plain(p)
	p.Material = Enum.Material.Neon
	p.Color = light
	p.Size = Units.toStuds(vector.create(STREAK_WIDTH, STREAK_WIDTH, length))
	local mid = (from + to) / 2
	p.CFrame = CFrame.lookAt(Units.toStuds(mid), Units.toStuds(to))
	p.Parent = holder()
	table.insert(fading, { part = p, from = mid, velocity = nil, start = os.clock(), time = STREAK })
end

-- A drone shot down at `at`: its pieces flying out and falling, fading.
local function burst(at: vector, light: Color3)
	for i = 1, SHARDS do
		local p = Instance.new("Part")
		p.Name = "Shard"
		plain(p)
		p.Material = Enum.Material.SmoothPlastic
		p.Color = if i % 2 == 0 then light else SHELL
		p.Size = Units.toStuds(vector.create(0.06, 0.04, 0.06))
		p.CFrame = CFrame.new(Units.toStuds(at))
		p.Parent = holder()
		local angle = i / SHARDS * 2 * math.pi
		local velocity = vector.create(math.cos(angle) * 2, 1.5 + (i % 3) * 0.5, math.sin(angle) * 2)
		table.insert(fading, { part = p, from = at, velocity = velocity, start = os.clock(), time = SHARD_TIME })
	end
end

-- Your dart, as it goes in your tick: its streak, to where your screen had
-- the level and everyone, and its sound.
local function onOwnCast(cast: AbilitySim.Cast, input: PlayerCodec.WireInput)
	if cast.ability ~= "owldrone" or cast.kind ~= "dart" then
		return
	end
	local level = ClientShots.levelAt(input.viewTime)
	local trace = Penetration.trace(level, cast.origin, cast.direction, "none", DR.dartRange.value)
	local targets = RemoteEntities.targets(input.viewTime)
	local hit = ShotResolver.resolve(cast.origin, cast.direction, targets, trace.stop, PlayerController.entityId)
	local to = if hit then hit.point else cast.origin + cast.direction * trace.stop
	streak(cast.origin + BELOW_EYE, to, tint(PlayerController.entityId))
	play("dartshot", cast.origin, true, PlayerController.entityId)
end

-- Whom a ping revealed to your side, with where the server said they stood.
local function revealed(event: any): ({ number }, { [number]: Hitboxes.Pose })
	local ids: { number } = {}
	local poses: { [number]: Hitboxes.Pose } = {}
	if typeof(event.ids) ~= "table" or typeof(event.poses) ~= "table" then
		return ids, poses
	end
	for _, sent in event.poses do
		local pose = ReconView.poseOf(sent)
		if pose and typeof(sent.id) == "number" then
			poses[sent.id] = pose
		end
	end
	for _, id in event.ids do
		if typeof(id) == "number" and poses[id] then
			table.insert(ids, id)
		end
	end
	return ids, poses
end

local function onEvent(event: any)
	if typeof(event) == "table" and event.kind == "out" then
		for _, f in fading do
			f.part:Destroy()
		end
		table.clear(fading)
		table.clear(due)
		return
	end
	if typeof(event) ~= "table" or event.ability ~= "owldrone" then
		return
	end
	if typeof(event.entity) ~= "number" or typeof(event.at) ~= "number" then
		return
	end
	local yours = event.entity == PlayerController.entityId
	local struck = if typeof(event.struck) == "number" then event.struck else nil
	if event.kind == "dart" then
		if typeof(event.origin) ~= "Vector3" or typeof(event.to) ~= "Vector3" then
			return
		end
		-- Yours went in your tick: what it struck shows at once.
		if yours then
			if event.hit == true then
				hitUntil = os.clock() + DR.hitText.value
				GameSounds.playCast("darthit", vector.zero)
			end
			return
		end
		table.insert(due, {
			kind = "dart",
			at = event.at,
			entity = event.entity,
			origin = Units.asVector(event.origin),
			to = Units.asVector(event.to),
			struck = struck,
			ids = {},
			poses = {},
		})
	elseif event.kind == "dartping" then
		local ids, poses = revealed(event)
		local target = if typeof(event.target) == "number" then event.target else nil
		local first = ids[1]
		local at = if first then poses[first].position + CHEST else vector.zero
		table.insert(due, {
			kind = "dartping",
			at = event.at,
			entity = event.entity,
			origin = at,
			to = at,
			struck = target,
			ids = ids,
			poses = poses,
		})
	elseif event.kind == "dronedown" then
		if typeof(event.point) ~= "Vector3" then
			return
		end
		local point = Units.asVector(event.point)
		table.insert(due, {
			kind = "dronedown",
			at = event.at,
			entity = event.entity,
			origin = point,
			to = point,
			struck = nil,
			ids = {},
			poses = {},
		})
	end
end

-- A dart, a ping or a drone shot down, as the frame on your screen reaches
-- it.
local function happen(d: Due)
	local own = d.entity == PlayerController.entityId
	local you = PlayerController.entityId
	if d.kind == "dart" then
		streak(d.origin, d.to, tint(d.entity))
		play("dartshot", d.origin, false, d.entity)
		if d.struck == you then
			taggedUntil = os.clock() + DR.firstPing.value + (DR.pings.value - 1) * DR.pingEvery.value + DR.reveal.value
			GameSounds.playCast("darthit", vector.zero)
		end
	elseif d.kind == "dartping" then
		for _, id in d.ids do
			ReconView.reveal(id, d.poses[id], d.at + DR.reveal.value)
		end
		if #d.ids > 0 then
			play("dartping", d.origin, own, d.entity)
		elseif d.struck == you then
			GameSounds.playCast("dartping", vector.zero)
		end
	elseif d.kind == "dronedown" then
		burst(d.origin, tint(d.entity))
		play("dronebreak", d.origin, own, d.entity)
	end
end

function DroneView.start()
	-- While you fly: its edges tinted, and under the crosshair its time
	-- left and the dart's cooldown; '[Target Hit]' under them, and TAGGED
	-- up top while a dart's pings are on you.
	local gui = Ui.screen("VFDrone", 16, Enum.ScreenInsets.None)
	local edge = Ui.frame(gui, {
		Name = "Edge",
		Size = UDim2.new(1, -2 * EDGE, 1, -2 * EDGE),
		Position = UDim2.fromOffset(EDGE, EDGE),
		BackgroundTransparency = 1,
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = LIGHT
	stroke.Thickness = EDGE * 2
	stroke.Transparency = 1
	stroke.Parent = edge
	local panel = Ui.frame(gui, {
		Name = "Flight",
		Size = UDim2.fromOffset(BAR_W, 2 * BAR_H + BAR_GAP),
		Position = UDim2.new(0.5, -BAR_W / 2, 0.5, BELOW),
		BackgroundTransparency = 1,
		Visible = false,
	})
	local time = Ui.frame(panel, { Name = "Time", Size = UDim2.fromOffset(BAR_W, BAR_H), BackgroundColor3 = DIM })
	local timeFill = Ui.frame(time, { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = LIGHT, BackgroundTransparency = 0 })
	local dart = Ui.frame(panel, {
		Name = "Dart",
		Size = UDim2.fromOffset(BAR_W, BAR_H),
		Position = UDim2.fromOffset(0, BAR_H + BAR_GAP),
		BackgroundColor3 = DIM,
	})
	local dartFill = Ui.frame(dart, { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = LIGHT, BackgroundTransparency = 0 })
	local hitText = Ui.label(gui, {
		Name = "TargetHit",
		Size = UDim2.fromOffset(200, 20),
		Position = UDim2.new(0.5, -100, 0.5, BELOW + 2 * BAR_H + BAR_GAP + 8),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = LIGHT,
		TextStrokeTransparency = 0.5,
		Text = "[Target Hit]",
		Visible = false,
	})
	local tagged = Ui.label(gui, {
		Name = "Tagged",
		Size = UDim2.fromOffset(200, 24),
		Position = UDim2.new(0.5, -100, 0, 90),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = tint(nil),
		TextStrokeTransparency = 0.5,
		Text = "TAGGED",
		Visible = false,
	})

	ClientShots.drones = function(level: Penetration.Level, at: number): Penetration.Level
		local posed: { DroneSim.Posed } = {}
		for _, pose in RemoteEntities.drones(at) do
			if not mine[pose.id] then
				table.insert(posed, { id = pose.id, position = pose.position })
			end
		end
		return DroneSim.level(level, posed)
	end
	table.insert(PlayerController.castListeners, onOwnCast)
	NetSim.on(Remotes.get().Ability, onEvent)
	RunService.RenderStepped:Connect(function()
		local render = RemoteEntities.renderTime()
		local clock = os.clock()
		local s = PlayerController.sim
		local kit = if s then s.abilities else nil
		local t = if s then s.movement.tick * DT else 0
		local flying = PlayerController.alive and kit ~= nil and AbilitySim.droning(kit)

		-- Your flight: its time left and the dart's cooldown, the edges
		-- tinted, its hum, and your body where you left it.
		local left = if flying and kit then math.max(AbilitySim.droneEnds(kit) - t, 0) else 0
		local dartIn = if flying and kit then math.max(kit.dartAt - t, 0) else 0
		local piloting = flying and kit ~= nil and AbilitySim.piloting(kit, t)
		panel.Visible = flying
		timeFill.Size = UDim2.fromScale(math.clamp(left / DR.duration.value, 0, 1), 1)
		dartFill.Size = UDim2.fromScale(if piloting then 1 - math.clamp(dartIn / DR.dartCooldown.value, 0, 1) else 0, 1)
		dartFill.BackgroundColor3 = if piloting and dartIn <= 0 then LIGHT else LIGHT:Lerp(DIM, 0.6)
		stroke.Transparency = if flying then 0.82 else 1
		if flying and kit and clock - ownHummed >= HUM_EVERY then
			ownHummed = clock
			play("dronehum", kit.dronePos, true, PlayerController.entityId)
		end
		if flying and s and kit then
			local b = body or newBody()
			body = b
			b.Parent = holder()
			local stood = { position = s.movement.position, yaw = kit.bodyYaw, crouchAlpha = s.movement.crouchAlpha }
			RemoteEntities.placeBoxes(bodyParts, stood)
		elseif body then
			body.Parent = nil
		end

		-- Everyone else's drones, where the snapshots have them.
		local ownId = Players.LocalPlayer:GetAttribute(DroneSim.ID_ATTRIBUTE)
		if typeof(ownId) == "number" then
			mine[ownId] = true
		end
		local seen: { [number]: boolean } = {}
		for _, pose in RemoteEntities.drones(render) do
			seen[pose.id] = true
			if mine[pose.id] then
				continue
			end
			local d = drawn[pose.id] or newDrone(pose.id)
			drawn[pose.id] = d
			local owner = ownerOf(pose.id)
			place(d, pose, tint(owner), clock)
			if clock - d.hummed >= HUM_EVERY then
				d.hummed = clock
				local id = pose.id
				play("dronehum", pose.position, false, owner or id, function(): vector?
					local now = RemoteEntities.drone(id, RemoteEntities.renderTime())
					return if now then now.position else nil
				end)
			end
		end
		local count = 0
		for id, d in drawn do
			if seen[id] and not mine[id] then
				count += 1
			else
				d.model:Destroy()
				drawn[id] = nil
			end
		end
		for id in mine do
			if not seen[id] and id ~= ownId then
				mine[id] = nil
			end
		end

		-- Darts, pings and bursts, as the frame on your screen reaches them.
		local i = 1
		while i <= #due do
			local d = due[i]
			if render < d.at then
				i += 1
				continue
			end
			table.remove(due, i)
			if render - d.at < STALE then
				happen(d)
			end
		end
		for j = #fading, 1, -1 do
			local f = fading[j]
			local age = clock - f.start
			local k = age / f.time
			if k >= 1 or f.part.Parent == nil then
				f.part:Destroy()
				table.remove(fading, j)
				continue
			end
			local v = f.velocity
			if v then
				f.part.CFrame = CFrame.new(Units.toStuds(f.from + v * age + vector.create(0, -4.9 * age * age, 0)))
			end
			f.part.Transparency = k
		end

		hitText.Visible = clock < hitUntil
		tagged.Visible = clock < taggedUntil
		tagged.TextColor3 = tint(nil)
		gui:SetAttribute("Flying", flying)
		gui:SetAttribute("Left", math.floor(left * 10 + 0.5) / 10)
		gui:SetAttribute("DartIn", math.floor(dartIn * 10 + 0.5) / 10)
		gui:SetAttribute("TargetHit", clock < hitUntil)
		gui:SetAttribute("Tagged", clock < taggedUntil)
		gui:SetAttribute("Drones", count)
	end)
end

return DroneView
