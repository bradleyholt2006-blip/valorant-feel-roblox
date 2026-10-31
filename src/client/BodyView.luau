--!strict
-- Draws another agent's body (system 63): a copy of a rigged model from
-- ReplicatedStorage.VFBodies, its bones posed every frame by BodyPose from
-- what the snapshots say the agent is doing, and what it holds in its
-- hands (WeaponLooks' stand-in look). RemoteEntities keeps its blocks on
-- the hitboxes, unseen, for the label over the head and anything that
-- finds an entity by them; the body's head is kept in the head block.
--
-- A rig is used as Studio's importer brings it in: a model whose
-- PrimaryPart is the part its bones hang off, standing on that part's
-- origin facing -Z (its left on -X), the bones named as the kit's
-- (BodyRig). It's scaled to the agents' height. One missing a bone the pose
-- needs isn't used, and the blocks are drawn as before; nor is one until
-- its meshes have loaded on this client, or ever if one of them can't (a
-- mesh Roblox's moderation has blocked doesn't load for other players, and
-- a body without its mesh is all but unseen).
--
-- Each bone is turned by its Transform, which Roblox applies on top of
-- where the bone rests (its CFrame): a bone's turn from rest in the body's
-- space (BodyPose) is turned into its own axes, and the root bone is moved
-- as the pose moves it. Bones the pose doesn't turn keep their parent's
-- turn, as at rest, and aren't written. A body off the screen isn't posed:
-- it only moves with its entity, what it holds hidden, until it's back.

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BodyConfig = require(Shared.Body.BodyConfig)
local BodyMotion = require(Shared.Body.BodyMotion)
local BodyPose = require(Shared.Body.BodyPose)
local BodyRig = require(Shared.Body.BodyRig)
local Quat = require(Shared.Body.Quat)
local PlayerCodec = require(Shared.Net.PlayerCodec)
local Units = require(Shared.Units)
local WeaponConfig = require(Shared.Weapons.WeaponConfig)

local WeaponLooks = require(script.Parent.Combat.WeaponLooks)

local BodyView = {}

-- Where the bodies are kept, and the one drawn for every agent until each
-- has its own (else the first there).
BodyView.FOLDER = "VFBodies"
BodyView.DEFAULT = "Default"
-- Workspace's attribute on a client, in Studio, for checks: the
-- milliseconds the bodies take of each frame (RemoteEntities).
BodyView.COST = "VFBodyMs"

local FLASH_COLOUR = Color3.new(1, 1, 1)
local SHADE_COLOUR = Color3.fromRGB(40, 26, 64)
local SHADE_CLEAR = 0.35

-- A bone turned less than this since it was last written isn't written
-- again (radians; a millimetre at a forearm's length).
local SAME_TURN = 0.004

-- A long gun's left hand goes under it this far toward the muzzle, as far
-- as the arm reaches (the tests check it to 0.30 m).
local FOREGRIP_SHARE = 0.43
local FOREGRIP_NEAREST, FOREGRIP_FURTHEST = -0.18, -0.3

type Held = { id: string, parts: { BasePart }, offsets: { CFrame } }

export type Body = {
	model: Model,
	skeleton: BodyRig.Skeleton,
	state: BodyMotion.State,
	pose: BodyPose.Pose,
	parts: { BasePart }, -- every part, moved together
	offsets: { CFrame }, -- each from the root part
	moved: { CFrame }, -- working: where each goes this frame
	plain: { { colour: Color3, material: Enum.Material, transparency: number } },
	bones: { [number]: Bone }, -- by the skeleton's index
	rest: { [number]: CFrame }, -- each bone's axes at rest, from the root part's
	restInverse: { [number]: CFrame },
	written: { [number]: Quat.Quat }, -- each bone's turn as last written (none: as at rest)
	origin: CFrame, -- the root part from the body's origin
	held: Held?,
	look: string,
	last: number?,
	source: Model, -- the rig it was copied from
}

local template: Model? = nil
local broken: { [Model]: boolean } = {}
-- Each rig's meshes: on their way (false) or loaded (true) on this client.
local fetched: { [Model]: boolean } = {}

-- Loads a rig's meshes, and marks it broken if any of them doesn't load:
-- drawn without one, a body would be missing that part of it, or all of it.
-- The Output says which didn't (F9 in a game).
local function fetch(model: Model)
	local names: { [string]: string } = {} -- each mesh's part, by the mesh's asset number
	local parts: { MeshPart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("MeshPart") then
			local id = string.match(d.MeshId, "%d+$")
			if id then
				names[id] = d.Name
				table.insert(parts, d)
			end
		end
	end
	local failed: { string } = {}
	local ok, problem = pcall(function()
		ContentProvider:PreloadAsync(parts, function(content: string, status: Enum.AssetFetchStatus)
			local id = string.match(content, "%d+$")
			if id and names[id] and status ~= Enum.AssetFetchStatus.Success then
				table.insert(failed, `{names[id]} ({content}, {status.Name})`)
			end
		end)
	end)
	if not ok then
		table.insert(failed, tostring(problem))
	end
	if #failed > 0 then
		broken[model] = true
		warn(`[VF] Agents are drawn as blocks: the body {model.Name}'s meshes didn't all load, {table.concat(failed, "; ")}`)
	else
		fetched[model] = true
	end
end

-- The body to draw agents with, if there's one in ReplicatedStorage and its
-- meshes have loaded. One taken out of ReplicatedStorage is gone, though
-- its folder's still about.
function BodyView.template(): Model?
	local found = template
	if found and found:IsDescendantOf(ReplicatedStorage) and not broken[found] then
		return found
	end
	template = nil
	local folder = ReplicatedStorage:FindFirstChild(BodyView.FOLDER)
	if not folder then
		return nil
	end
	local named = folder:FindFirstChild(BodyView.DEFAULT)
	local model = if named and named:IsA("Model") then named else folder:FindFirstChildWhichIsA("Model")
	if not model or broken[model] then
		return nil
	end
	if fetched[model] == nil then
		fetched[model] = false
		task.spawn(fetch, model)
	end
	if fetched[model] then
		template = model
		return model
	end
	return nil
end

-- How far up and down a part reaches, in the root part's space.
local function span(root: BasePart, part: BasePart): (number, number)
	local cf = root.CFrame:ToObjectSpace(part.CFrame)
	local _, y, _, _, _, _, r10, r11, r12 = cf:GetComponents()
	local size = part.Size
	local half = 0.5 * (math.abs(r10) * size.X + math.abs(r11) * size.Y + math.abs(r12) * size.Z)
	return y - half, y + half
end

-- The body's mesh: its biggest part.
local function meshOf(model: Model, root: BasePart): BasePart?
	local best: BasePart? = nil
	local most = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= root then
			local size = d.Size
			local volume = size.X * size.Y * size.Z
			if volume > most then
				best, most = d, volume
			end
		end
	end
	return best
end

-- A body copied from a rig, scaled to the agents' height and ready to
-- pose; nil if it can't be posed.
function BodyView.new(source: Model): Body?
	local model = source:Clone()
	-- The importer's animation pieces and joints aren't used: the pose
	-- turns the bones, and every part moves with the root part.
	for _, d in model:GetDescendants() do
		if
			d:IsA("Humanoid")
			or d:IsA("AnimationController")
			or d:IsA("JointInstance")
			or d:IsA("WeldConstraint")
			or (d:IsA("Folder") and d.Name == "InitialPoses")
		then
			d:Destroy()
		end
	end
	local function fail(): Body?
		model:Destroy()
		broken[source] = true
		return nil
	end
	local primary = model.PrimaryPart
	local mesh = if primary then meshOf(model, primary) else nil
	if not primary or not mesh then
		return fail()
	end
	local root: BasePart = primary
	local bottom, top = span(root, mesh)
	if top - bottom < 1e-3 then
		return fail()
	end
	local tall = Units.STUDS_PER_METRE * BodyConfig.Body.height.value
	model:ScaleTo(model:GetScale() * tall / (top - bottom))
	bottom, top = span(root, mesh)

	local rootFrame = root.CFrame
	local rig: { BodyRig.RigBone } = {}
	local byName: { [string]: Bone } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Bone") then
			local parent = d.Parent
			table.insert(rig, {
				name = d.Name,
				parent = if parent and parent:IsA("Bone") then parent.Name else nil,
				position = Units.asVector(rootFrame:PointToObjectSpace(d.WorldPosition)),
			})
			byName[BodyRig.boneName(d.Name)] = d
		end
	end
	local skeleton = BodyRig.new(rig, bottom, top)
	if not skeleton then
		return fail()
	end

	local bones: { [number]: Bone } = {}
	local rest: { [number]: CFrame } = {}
	local restInverse: { [number]: CFrame } = {}
	for i, b in skeleton.bones do
		local bone = byName[b.name]
		if bone then
			local axes = rootFrame:ToObjectSpace(bone.WorldCFrame).Rotation
			bones[i], rest[i], restInverse[i] = bone, axes, axes:Inverse()
		end
	end
	local parts: { BasePart } = {}
	local offsets: { CFrame } = {}
	local plain = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			table.insert(parts, d)
			table.insert(offsets, rootFrame:ToObjectSpace(d.CFrame))
			table.insert(plain, { colour = d.Color, material = d.Material, transparency = d.Transparency })
		end
	end
	-- Roblox skins a mesh only by the bones in its own assembly, and the
	-- bones hang off the root part, which the importer's joints (gone
	-- above) don't join to the meshes: every part's jointed to it, where
	-- it rests, or the meshes stay in the pose they were imported in.
	for i, part in parts do
		if part ~= root then
			local joint = Instance.new("Motor6D")
			joint.Name = "VFSkin"
			joint.Part0 = root
			joint.Part1 = part
			joint.C0 = offsets[i]
			joint.Parent = part
		end
	end
	return {
		model = model,
		skeleton = skeleton,
		state = BodyMotion.new(),
		pose = BodyPose.new(skeleton),
		parts = parts,
		offsets = offsets,
		moved = table.create(#parts, CFrame.identity),
		plain = plain,
		bones = bones,
		rest = rest,
		restInverse = restInverse,
		written = {},
		origin = CFrame.new(-Units.asVector3(skeleton.origin)),
		held = nil,
		look = "",
		last = nil,
		source = source,
	}
end

-- Where a long gun's left hand goes, from its look.
local function foregripOf(id: string): vector
	local muzzle = WeaponLooks.shape(id).muzzle
	return vector.create(0, -0.05, math.clamp(muzzle.z * FOREGRIP_SHARE, FOREGRIP_FURTHEST, FOREGRIP_NEAREST))
end

-- What's held, built from its look: an ability's item is only its lit
-- pieces (the rest of its look is the hand holding it, in first person).
local function heldFor(body: Body, id: string): Held
	local old = body.held
	if old then
		for _, part in old.parts do
			part:Destroy()
		end
	end
	local def = WeaponConfig.Defs[id]
	local item = def ~= nil and (def.category == "ability" or def.category == "ultimate")
	local held: Held = { id = id, parts = {}, offsets = {} }
	for _, piece in WeaponLooks.shape(id).pieces do
		if item and not piece.accent then
			continue
		end
		local part = Instance.new("Part")
		part.Name = "Held"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = if item then Enum.Material.Neon else Enum.Material.SmoothPlastic
		part.Color = WeaponLooks.colour(id, piece)
		part.Size = Units.toStuds(piece.size)
		part.Parent = body.model
		table.insert(held.parts, part)
		table.insert(held.offsets, CFrame.new(Units.toStuds(piece.offset)))
	end
	body.held = held
	return held
end

local function frameOf(q: Quat.Quat): CFrame
	local v = q.v
	return CFrame.new(0, 0, 0, v.x, v.y, v.z, q.w)
end

-- Poses a body for this frame from an entity's interpolated pose, and
-- moves it there. `now` is os.clock(); `sinceShot` the seconds since the
-- entity last fired, if it has; `unseen`, off the screen: moved, not posed.
function BodyView.update(body: Body, pose: PlayerCodec.Pose, now: number, sinceShot: number?, unseen: boolean?)
	local dt = if body.last then now - body.last else 0
	body.last = now
	local weapon = if pose.weapon > 0 then WeaponConfig.Ids[pose.weapon] else nil
	local def = if weapon then WeaponConfig.Defs[weapon] else nil
	local hold: BodyMotion.Hold = BodyMotion.holdOf(weapon)
	BodyMotion.step(body.state, {
		position = pose.position,
		yaw = pose.yaw,
		pitch = pose.pitch,
		crouch = pose.crouchAlpha,
		grounded = pose.grounded,
		hold = hold,
		foregrip = if hold == "rifle" and weapon then foregripOf(weapon) else nil,
		reloading = pose.reloading,
		reloadLength = if def and def.reloadTime then def.reloadTime.value else nil,
		channel = pose.channel,
		gliding = pose.gliding,
		sinceShot = sinceShot,
	}, dt)

	-- The body's origin on the entity's feet, facing its way; every part
	-- where it rests from the root part.
	local place = CFrame.new(Units.toStuds(pose.position)) * CFrame.Angles(0, pose.yaw, 0)
	local root = place * body.origin
	local moved, offsets = body.moved, body.offsets
	for i in body.parts do
		moved[i] = root * offsets[i]
	end
	Workspace:BulkMoveTo(body.parts, moved, Enum.BulkMoveMode.FireCFrameChanged)
	if unseen then
		local held = body.held
		if held then
			for _, part in held.parts do
				if part.Transparency ~= 1 then
					part.Transparency = 1
				end
			end
		end
		return
	end
	local skeleton, posed = body.skeleton, body.pose
	BodyPose.solve(skeleton, body.state, posed)

	-- The bones: the root moved and turned, and each bone the pose turns
	-- that's turned since it was last written (a hand's fingers, curled
	-- round what it holds, mostly aren't).
	local set, turns, written = posed.set, posed.turns, body.written
	for i, bone in body.bones do
		local b = skeleton.bones[i]
		local turn = turns[i]
		if b.parent == nil then
			bone.Transform = body.restInverse[i] * CFrame.new(Units.toStuds(posed.root)) * frameOf(turn) * body.rest[i]
		elseif set[i] then
			local was = written[i]
			if not was or Quat.angle(Quat.mul(Quat.conj(was), turn)) > SAME_TURN then
				bone.Transform = body.restInverse[i] * frameOf(turn) * body.rest[i]
				written[i] = turn
			end
		elseif written[i] then
			bone.Transform = CFrame.identity
			written[i] = nil
		end
	end

	-- What's held, in the right hand.
	local shown = posed.shown and weapon ~= nil
	local held = body.held
	if shown and weapon and (not held or held.id ~= weapon) then
		held = heldFor(body, weapon)
	end
	if held then
		local grip = place * CFrame.new(Units.toStuds(posed.grip)) * frameOf(posed.held)
		for k, part in held.parts do
			if shown then
				part.CFrame = grip * held.offsets[k]
			end
			local clear = if shown then 0 else 1
			if part.Transparency ~= clear then
				part.Transparency = clear
			end
		end
	end
end

-- Draws a body lit up (hit), as a Shade (system 43), as a force field
-- (spawn protection in gun game, system 23), or as it is.
function BodyView.paint(body: Body, flash: boolean, shade: boolean, field: boolean)
	local key = (if flash then "f" else "") .. (if shade then "s" else "") .. (if field then "p" else "")
	if key == body.look then
		return
	end
	body.look = key
	for i, part in body.parts do
		local plain = body.plain[i]
		if plain.transparency >= 1 then
			continue -- the root part, unseen
		end
		part.Color = if flash then FLASH_COLOUR elseif shade then SHADE_COLOUR else plain.colour
		part.Material = if field then Enum.Material.ForceField else plain.material
		part.Transparency = if shade then math.max(plain.transparency, SHADE_CLEAR) else plain.transparency
	end
end

function BodyView.destroy(body: Body)
	body.model:Destroy()
end

return BodyView
