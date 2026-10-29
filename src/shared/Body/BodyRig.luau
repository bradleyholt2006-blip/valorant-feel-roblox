--!strict
-- The skeleton an agent's body is posed on (system 63): each bone's joint
-- where the rig rests, in metres in the body's own space (its soles at the
-- origin, +Y up, facing -Z, its right along +X), each bone's parent, and
-- what the pose needs measured from them (the legs, the arms, the hands,
-- the head).
--
-- BodyView reads the bones from the body in the game, so any rig with the
-- kit's bone names poses (a "bn_" in front of a name is dropped). The
-- kit's own skeleton (Superhero_Male_A: the 64 bones its Blender file
-- deforms with, and the tips Blender's FBX export adds, its leaf bones) is
-- kept here too, as imported, for the offline tests.

local BodyConfig = require("./BodyConfig")

export type Bone = {
	name: string,
	parent: number?, -- comes before it; nil for a root
	rest: vector, -- joint, metres
}

-- A bone as read from a rig: its joint in the rig's units, along the
-- body's axes.
export type RigBone = {
	name: string,
	parent: string?,
	position: vector,
}

export type Leg = {
	thigh: number,
	thighTwist: number?,
	shin: number,
	shinTwist: number?,
	foot: number,
	toe: number,
	hip: vector,
	knee: vector,
	ankle: vector,
	ball: vector, -- where the toes bend
	tip: vector, -- the end of the toes
	upper: number, -- hip to knee, metres
	lower: number, -- knee to ankle
	hinge: vector, -- the knee's axis at rest
}

export type Arm = {
	side: number, -- -1 left, 1 right
	clavicle: number,
	upper: number,
	upperTwist: number?,
	forearm: number,
	forearmTwist: number?,
	hand: number,
	collar: vector, -- the clavicle's joint
	shoulder: vector,
	elbow: vector,
	wrist: vector,
	upperLength: number,
	foreLength: number,
	hinge: vector, -- the elbow's axis at rest
	along: vector, -- the hand at rest: wrist toward the knuckles
	palm: vector, -- out of the palm
	knuckles: number, -- wrist to knuckles, metres
	fingers: { { number } }, -- index, middle, ring, pinky: knuckle first
	thumb: { number },
}

export type Skeleton = {
	bones: { Bone },
	index: { [string]: number },
	height: number,
	origin: vector, -- where the body's origin (its soles, between the ankles) is in the rig, the rig's units
	scale: number, -- metres to the rig's unit
	spine: { number }, -- spine01 (the root: the pelvis) up to spine06 (the neck)
	head: number,
	pelvis: vector,
	chest: vector, -- spine05's joint
	headJoint: vector,
	headCentre: vector,
	left: Arm,
	right: Arm,
	leftLeg: Leg,
	rightLeg: Leg,
}

local BodyRig = {}

-- The kit's bones as imported: Roblox's axes (the body faces -Z, its left
-- on -X), studs at the importer's scale of one to the Blender unit, its
-- origin between the feet. Left and middle bones; the right side mirrors
-- the left. Tips ("_end") are the leaf bones Blender's FBX export adds,
-- at the ends of the last bones (the toes' and the chin's are measured).
local KIT: { { any } } = {
	{ "spine01", "", 0, 5.327, 0.26 },
	{ "spine02", "spine01", 0, 6.076, 0.085 },
	{ "spine03", "spine02", 0, 6.806, 0.107 },
	{ "spine04", "spine03", 0, 7.528, 0.192 },
	{ "spine05", "spine04", 0, 8.332, 0.166 },
	{ "spine06", "spine05", 0, 8.686, 0.1 },
	{ "head", "spine06", 0, 9.009, 0.034 },
	{ "jaw", "head", 0, 8.93, -0.129 },
	{ "jaw_end", "jaw", 0, 8.634, -0.582 },
	{ "shoulder.L", "spine04", -0.117, 8.22, -0.018 },
	{ "upperarm01.L", "shoulder.L", -0.822, 8.278, 0.297 },
	{ "upperarm02.L", "upperarm01.L", -1.456, 7.765, 0.318 },
	{ "forearm01.L", "upperarm02.L", -2.091, 7.252, 0.34 },
	{ "forearm02.L", "forearm01.L", -2.715, 6.896, 0.073 },
	{ "hand.L", "forearm02.L", -3.339, 6.54, -0.193 },
	{ "index01.L", "hand.L", -3.685, 6.238, -0.591 },
	{ "index02.L", "index01.L", -3.784, 6.047, -0.698 },
	{ "index03.L", "index02.L", -3.857, 5.897, -0.779 },
	{ "index03.L_end", "index03.L", -3.925, 5.737, -0.859 },
	{ "middle01.L", "hand.L", -3.776, 6.25, -0.488 },
	{ "middle02.L", "middle01.L", -3.888, 5.99, -0.582 },
	{ "middle03.L", "middle02.L", -3.941, 5.819, -0.631 },
	{ "middle03.L_end", "middle03.L", -3.983, 5.642, -0.674 },
	{ "ring01.L", "hand.L", -3.772, 6.232, -0.343 },
	{ "ring02.L", "ring01.L", -3.895, 5.959, -0.413 },
	{ "ring03.L", "ring02.L", -3.946, 5.792, -0.445 },
	{ "ring03.L_end", "ring03.L", -3.977, 5.609, -0.47 },
	{ "pinky01.L", "hand.L", -3.746, 6.187, -0.201 },
	{ "pinky02.L", "pinky01.L", -3.86, 5.983, -0.216 },
	{ "pinky03.L", "pinky02.L", -3.899, 5.855, -0.224 },
	{ "pinky03.L_end", "pinky03.L", -3.947, 5.726, -0.233 },
	{ "thumb01.L", "hand.L", -3.376, 6.412, -0.383 },
	{ "thumb02.L", "thumb01.L", -3.356, 6.307, -0.54 },
	{ "thumb03.L", "thumb02.L", -3.382, 6.137, -0.676 },
	{ "thumb03.L_end", "thumb03.L", -3.418, 5.955, -0.78 },
	{ "pelvis.L", "spine01", 0, 5.327, 0.26 },
	{ "pelvis.L_end", "pelvis.L", -0.67, 5.932, -0.153 },
	{ "thigh01.L", "spine01", -0.649, 5.567, -0.044 },
	{ "thigh02.L", "thigh01.L", -0.649, 4.307, -0.18 },
	{ "shin01.L", "thigh02.L", -0.649, 3.047, -0.316 },
	{ "shin02.L", "shin01.L", -0.649, 1.875, -0.128 },
	{ "foot.L", "shin02.L", -0.649, 0.703, 0.059 },
	{ "toe.L", "foot.L", -0.649, 0.083, -0.742 },
	{ "toe.L_end", "toe.L", -0.649, 0.083, -1.093 },
}
-- The kit body's mesh from its soles to the top of its head, same units.
local KIT_BOTTOM = -0.0275
local KIT_TOP = 9.9675

-- A rig's bone name as the pose knows it.
function BodyRig.boneName(rigName: string): string
	return if string.sub(rigName, 1, 3) == "bn_" then string.sub(rigName, 4) else rigName
end

local function unit(v: vector, fallback: vector): vector
	local m = vector.magnitude(v)
	return if m > 1e-6 then v / m else fallback
end

-- The part of v at right angles to a unit axis.
local function across(v: vector, axis: vector): vector
	return v - axis * vector.dot(v, axis)
end

-- The axis a two-bone limb bends about at rest: (bend x reach), where bend
-- is the way its middle joint stands out from the line from its root to
-- its end (or `bend` if it's straight).
local function hingeOf(root: vector, middle: vector, tip: vector, bend: vector): vector
	local reach = unit(tip - root, vector.create(0, -1, 0))
	local out = unit(across(middle - root, reach), unit(across(bend, reach), bend))
	return unit(vector.cross(out, reach), vector.create(1, 0, 0))
end

-- Builds a skeleton from a rig's bones (its joints in the rig's units,
-- along the body's axes) and its mesh's lowest and highest points on the
-- same up axis; it's scaled so the mesh stands `height` metres. Nil if a
-- bone the pose needs is missing.
function BodyRig.new(rig: { RigBone }, bottom: number, top: number, height: number?): Skeleton?
	local tall = height or BodyConfig.Body.height.value
	if top - bottom < 1e-6 then
		return nil
	end
	local scale = tall / (top - bottom)
	local byName: { [string]: RigBone } = {}
	local children: { [string]: { RigBone } } = {}
	local roots: { RigBone } = {}
	for _, b in rig do
		byName[BodyRig.boneName(b.name)] = b
	end
	for _, b in rig do
		local parent = if b.parent then BodyRig.boneName(b.parent) else nil
		if parent and byName[parent] then
			children[parent] = children[parent] or {}
			table.insert(children[parent], b)
		else
			table.insert(roots, b)
		end
	end
	local footL, footR = byName["foot.L"], byName["foot.R"]
	if not footL or not footR then
		return nil
	end
	local mid = (footL.position + footR.position) * 0.5
	local origin = vector.create(mid.x, bottom, mid.z)
	local bones: { Bone } = {}
	local index: { [string]: number } = {}
	local function add(b: RigBone, parent: number?)
		local name = BodyRig.boneName(b.name)
		if index[name] then
			return
		end
		table.insert(bones, { name = name, parent = parent, rest = (b.position - origin) * scale })
		local i = #bones
		index[name] = i
		local kids = children[name]
		if kids then
			for _, c in kids do
				add(c, i)
			end
		end
	end
	for _, b in roots do
		add(b, nil)
	end

	local function at(name: string): vector
		return bones[index[name]].rest
	end
	local needs = { "spine01", "spine02", "spine03", "spine04", "spine05", "spine06", "head" }
	for _, side in { "L", "R" } do
		for _, n in { "shoulder", "upperarm01", "forearm01", "hand", "thigh01", "shin01", "foot", "toe" } do
			table.insert(needs, n .. "." .. side)
		end
	end
	for _, n in needs do
		if not index[n] then
			return nil
		end
	end

	local function leg(side: string): Leg
		local s = "." .. side
		local hip, knee, ankle, ball = at("thigh01" .. s), at("shin01" .. s), at("foot" .. s), at("toe" .. s)
		local tipIndex = index["toe" .. s .. "_end"]
		return {
			thigh = index["thigh01" .. s],
			thighTwist = index["thigh02" .. s],
			shin = index["shin01" .. s],
			shinTwist = index["shin02" .. s],
			foot = index["foot" .. s],
			toe = index["toe" .. s],
			hip = hip,
			knee = knee,
			ankle = ankle,
			ball = ball,
			tip = if tipIndex then bones[tipIndex].rest else ball + vector.create(0, 0, -0.06),
			upper = vector.magnitude(knee - hip),
			lower = vector.magnitude(ankle - knee),
			hinge = hingeOf(hip, knee, ankle, vector.create(0, 0, -1)),
		}
	end

	local function arm(side: string, sign: number): Arm
		local s = "." .. side
		local shoulder, elbow, wrist = at("upperarm01" .. s), at("forearm01" .. s), at("hand" .. s)
		local fingers: { { number } } = {}
		for _, f in { "index", "middle", "ring", "pinky" } do
			local chain = {}
			for k = 1, 3 do
				local i = index[f .. "0" .. k .. s]
				if i then
					table.insert(chain, i)
				end
			end
			table.insert(fingers, chain)
		end
		local thumb = {}
		for k = 1, 3 do
			local i = index["thumb0" .. k .. s]
			if i then
				table.insert(thumb, i)
			end
		end
		-- The hand's axes: toward the middle knuckle, and out of the palm,
		-- which for a left hand is (pinky to index) x (wrist to knuckles)
		-- turned round, and for a right hand that as it is.
		local forearmWay = unit(wrist - elbow, vector.create(sign, 0, 0))
		local knuckle = index["middle01" .. s]
		local along = if knuckle then unit(bones[knuckle].rest - wrist, forearmWay) else forearmWay
		local indexKnuckle, pinkyKnuckle = index["index01" .. s], index["pinky01" .. s]
		local width = if indexKnuckle and pinkyKnuckle then bones[indexKnuckle].rest - bones[pinkyKnuckle].rest else vector.create(0, 0, -1)
		local palm = unit(vector.cross(unit(across(width, along), vector.create(0, 0, -1)), along) * sign, vector.create(-sign, 0, 0))
		return {
			side = sign,
			clavicle = index["shoulder" .. s],
			upper = index["upperarm01" .. s],
			upperTwist = index["upperarm02" .. s],
			forearm = index["forearm01" .. s],
			forearmTwist = index["forearm02" .. s],
			hand = index["hand" .. s],
			collar = at("shoulder" .. s),
			shoulder = shoulder,
			elbow = elbow,
			wrist = wrist,
			upperLength = vector.magnitude(elbow - shoulder),
			foreLength = vector.magnitude(wrist - elbow),
			hinge = hingeOf(shoulder, elbow, wrist, vector.create(0, 0, 1)),
			along = along,
			palm = palm,
			knuckles = if knuckle then vector.magnitude(bones[knuckle].rest - wrist) else 0.1,
			fingers = fingers,
			thumb = thumb,
		}
	end

	local headJoint = at("head")
	local chin = if index["jaw_end"] then at("jaw_end").y else headJoint.y - 0.065
	local skeleton: Skeleton = {
		bones = bones,
		index = index,
		height = tall,
		origin = origin,
		scale = scale,
		spine = {
			index["spine01"],
			index["spine02"],
			index["spine03"],
			index["spine04"],
			index["spine05"],
			index["spine06"],
		},
		head = index["head"],
		pelvis = at("spine01"),
		chest = at("spine05"),
		headJoint = headJoint,
		headCentre = vector.create(headJoint.x, (chin + tall) * 0.5, headJoint.z - BodyConfig.Body.headForward.value),
		left = arm("L", -1),
		right = arm("R", 1),
		leftLeg = leg("L"),
		rightLeg = leg("R"),
	}
	return skeleton
end

-- The kit's skeleton as a rig would give it.
function BodyRig.kitBones(): { RigBone }
	local out: { RigBone } = {}
	local function add(name: string, parent: string, x: number, y: number, z: number)
		table.insert(
			out,
			{ name = "bn_" .. name, parent = if parent == "" then "RootPart" else "bn_" .. parent, position = vector.create(x, y, z) }
		)
	end
	for _, row in KIT do
		add(row[1], row[2], row[3], row[4], row[5])
	end
	for _, row in KIT do
		local name: string = row[1]
		if string.find(name, ".L", 1, true) then
			local parent: string = row[2]
			add((string.gsub(name, "%.L", ".R")), (string.gsub(parent, "%.L", ".R")), -row[3], row[4], row[5])
		end
	end
	return out
end

BodyRig.KIT_BOTTOM = KIT_BOTTOM
BodyRig.KIT_TOP = KIT_TOP

-- The kit's skeleton, built as BodyView builds one from the rig.
BodyRig.DEFAULT = BodyRig.new(BodyRig.kitBones(), KIT_BOTTOM, KIT_TOP) :: Skeleton

return BodyRig
