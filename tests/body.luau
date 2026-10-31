--!strict
-- Agents' bodies (system 63): the rotations, the kit's skeleton as the
-- importer gives it (and any rig with its bone names, at any scale), and
-- the pose: the head in the head box in every stance, aim and step, the
-- feet on the ground and kept still while down, standing as the body turns
-- on the spot until they step round after it, the limbs reaching what they
-- reach for and the hands on what they hold, the legs tucking in the air
-- and the knees bending as they land, the reload, the kick, the plant, the
-- defuse and the draw, and no pops from frame to frame.

local BodyConfig = require("../src/shared/Body/BodyConfig")
local BodyMotion = require("../src/shared/Body/BodyMotion")
local BodyPose = require("../src/shared/Body/BodyPose")
local BodyRig = require("../src/shared/Body/BodyRig")
local Quat = require("../src/shared/Body/Quat")
local Hitboxes = require("../src/shared/Combat/Hitboxes")
local H = require("./Harness")

local check = H.check
local near = H.near

local X = vector.create(1, 0, 0)
local Y = vector.create(0, 1, 0)
local Z = vector.create(0, 0, 1)
local AHEAD = vector.create(0, 0, -1)

local function close(a: vector, b: vector, tol: number): boolean
	return vector.magnitude(a - b) <= tol
end

local function mirror(v: vector): vector
	return vector.create(-v.x, v.y, v.z)
end

-- Rotations ---------------------------------------------------------------------------------------

H.section("Agent bodies: rotations (system 63)")

do
	check("a quarter turn about +Y takes ahead (-Z) to the left (-X)", close(Quat.rotate(Quat.aboutY(math.pi / 2), AHEAD), -X, 1e-5))
	local yaw = 0.7
	check(
		"turning by a yaw faces the aim's way, as Hitboxes and the aim have it",
		close(Quat.rotate(Quat.aboutY(yaw), AHEAD), vector.create(-math.sin(yaw), 0, -math.cos(yaw)), 1e-5)
	)
	check(
		"a pitch up about +X raises the aim",
		close(Quat.rotate(Quat.aboutX(0.5), AHEAD), vector.create(0, math.sin(0.5), -math.cos(0.5)), 1e-5)
	)
	local a, b = Quat.axisAngle(vector.normalize(vector.create(1, 2, 3)), 0.9), Quat.aboutX(-0.4)
	local p = vector.create(0.3, -0.2, 0.5)
	check(
		"turns compose as CFrames multiply (the right one first)",
		close(Quat.rotate(Quat.mul(a, b), p), Quat.rotate(a, Quat.rotate(b, p)), 1e-5)
	)
	check("a turn undone", close(Quat.rotate(Quat.conj(a), Quat.rotate(a, p)), p, 1e-5))
	local ok = true
	for _, t in { a, Quat.aboutX(3), Quat.aboutY(3), Quat.aboutZ(3), Quat.axisAngle(vector.normalize(vector.create(1, 1, 0)), 3.1) } do
		local back = Quat.fromAxes(Quat.rotate(t, X), Quat.rotate(t, Y), Quat.rotate(t, Z))
		ok = ok and Quat.angle(Quat.mul(back, Quat.conj(t))) < 1e-3
	end
	check("a turn found again from where it takes the three axes, however far it turns", ok)
	local half = Quat.scale(a, 0.5)
	check("half a turn twice over is the turn", Quat.angle(Quat.mul(Quat.mul(half, half), Quat.conj(a))) < 1e-4)
	check("a quarter of a turn turns a quarter as far", near(Quat.angle(Quat.scale(a, 0.25)), 0.9 * 0.25, 1e-4))
	local from, to = vector.normalize(vector.create(1, -2, 0.5)), vector.normalize(vector.create(-0.3, 0.4, -1))
	check("the shortest turn from one way to another", close(Quat.rotate(Quat.fromTo(from, to), from), to, 1e-5))
	check("...and to the opposite way", close(Quat.rotate(Quat.fromTo(Y, -Y), Y), -Y, 1e-5))
	local m = Quat.between(X, Y, Quat.rotate(a, X), Quat.rotate(a, Y) + Quat.rotate(a, X) * 0.2)
	check("the turn from one frame to another, its second axis squared up", Quat.angle(Quat.mul(m, Quat.conj(a))) < 1e-3)
	local twist = Quat.twist(Quat.mul(Quat.aboutY(0.8), Quat.aboutX(0.3)), Y)
	check("the twist of a turn about an axis", near(Quat.angle(twist), 0.8, 0.01) and close(vector.normalize(twist.v), Y, 1e-4))
	check(
		"a blend of two turns starts at the one and ends at the other",
		Quat.angle(Quat.mul(Quat.nlerp(a, b, 0), Quat.conj(a))) < 1e-4 and Quat.angle(Quat.mul(Quat.nlerp(a, b, 1), Quat.conj(b))) < 1e-4
	)
end

-- The skeleton -------------------------------------------------------------------------------------

H.section("Agent bodies: the kit's skeleton (system 63)")

local sk = BodyRig.DEFAULT

do
	check("the kit's 64 bones and the 15 leaf tips its FBX carries", #sk.bones == 79, tostring(#sk.bones))
	local ordered = true
	for i, b in sk.bones do
		if b.parent and b.parent >= i then
			ordered = false
		end
	end
	check("every bone comes after its parent, and the root is the pelvis", ordered and sk.bones[1].name == "spine01")
	local lowest = math.huge
	for _, b in sk.bones do
		lowest = math.min(lowest, b.rest.y)
	end
	check("drawn 1.75 m tall, to the top of the standing head box", near(sk.height, 1.75, 1e-6))
	check(
		"its soles on the ground (the lowest joints, the balls of the feet, just above)",
		lowest > 0 and lowest < 0.03,
		string.format("%.3f", lowest)
	)
	print(
		string.format(
			"  The kit at 1.75 m: hips %.3f m up, thigh %.3f, shin %.3f, upper arm %.3f, forearm %.3f, the head's middle %.3f m up",
			sk.leftLeg.hip.y,
			sk.leftLeg.upper,
			sk.leftLeg.lower,
			sk.left.upperLength,
			sk.left.foreLength,
			sk.headCentre.y
		)
	)
	check(
		"its legs and arms mirror each other",
		close(mirror(sk.leftLeg.hip), sk.rightLeg.hip, 1e-4)
			and close(mirror(sk.leftLeg.ankle), sk.rightLeg.ankle, 1e-4)
			and close(mirror(sk.left.shoulder), sk.right.shoulder, 1e-4)
			and close(mirror(sk.left.wrist), sk.right.wrist, 1e-4)
			and close(mirror(sk.left.palm), sk.right.palm, 1e-4)
	)
	check("each palm faces in toward the body, as the kit's arms hang", sk.left.palm.x > 0.3 and sk.right.palm.x < -0.3)
	local box = Hitboxes.build({ position = vector.zero, yaw = 0, crouchAlpha = 0 })[1]
	check(
		"standing at rest, the middle of its head is in the standing head box",
		math.abs(sk.headCentre.y - box.center.y) < box.half.y and math.abs(sk.headCentre.z) < box.half.z
	)

	-- As BodyView reads it: the importer's names, at the scale the body's
	-- drawn at (6.25 studs) and wherever it stands.
	local scale, offset = 6.25 / (BodyRig.KIT_TOP - BodyRig.KIT_BOTTOM), vector.create(3, 1, -2)
	local moved: { BodyRig.RigBone } = {}
	for _, b in BodyRig.kitBones() do
		table.insert(moved, { name = b.name, parent = b.parent, position = b.position * scale + offset })
	end
	local again = BodyRig.new(moved, BodyRig.KIT_BOTTOM * scale + offset.y, BodyRig.KIT_TOP * scale + offset.y)
	local same = again ~= nil and #again.bones == #sk.bones
	if again then
		for i, b in again.bones do
			same = same and b.name == sk.bones[i].name and close(b.rest, sk.bones[i].rest, 1e-4)
		end
	end
	check("read off a rig at any scale and wherever it stands, the same skeleton", same)
	check(
		"...knowing where its origin is in the rig and how big a rig's unit is",
		again ~= nil and close(again.origin, sk.origin * scale + offset, 1e-4) and near(again.scale, sk.scale / scale, 1e-6)
	)
	local missing: { BodyRig.RigBone } = {}
	for _, b in BodyRig.kitBones() do
		if b.name ~= "bn_shin01.L" then
			table.insert(missing, b)
		end
	end
	check(
		"a rig missing a bone the pose needs isn't posed (BodyView draws the boxes)",
		BodyRig.new(missing, BodyRig.KIT_BOTTOM, BodyRig.KIT_TOP) == nil
	)
end

-- Playing a body ----------------------------------------------------------------------------------

local DT = 1 / 60

type Play = {
	velocity: vector?, -- world, m/s
	turn: number?, -- radians a second
	crouch: number?,
	pitch: number?,
	hold: BodyMotion.Hold?,
	air: boolean?,
	foregrip: vector?,
	reloading: boolean?,
	reloadLength: number?,
	channel: number?,
	gliding: boolean?,
	fireRate: number?, -- shots a second
}

type Body = {
	state: BodyMotion.State,
	pose: BodyPose.Pose,
	position: vector,
	velocity: vector,
	yaw: number,
	pitch: number,
	crouch: number,
	sinceShot: number?,
}

local function newBody(): Body
	return {
		state = BodyMotion.new(),
		pose = BodyPose.new(sk),
		position = vector.zero,
		velocity = vector.zero,
		yaw = 0,
		pitch = 0,
		crouch = 0,
		sinceShot = nil,
	}
end

-- As the snapshots carry them: the speed changes no quicker than a
-- counter-strafe brakes (full speed to a stop in about 0.16 s,
-- MovementConfig), the aim swings up or down at a quick flick's speed at
-- most, and the crouch goes down or up over its transition.
local BRAKE = 34 -- m/s^2
local FLICK = 8 -- radians a second
local CROUCH_TIME = 0.12

local function toward(current: number, target: number, most: number): number
	return current + math.clamp(target - current, -most, most)
end

-- Plays a body for a while at a steady input, calling `each` every frame.
local function play(body: Body, input: Play, seconds: number, each: ((number) -> ())?)
	for frame = 1, math.floor(seconds / DT + 0.5) do
		local change = (input.velocity or vector.zero) - body.velocity
		local most = BRAKE * DT
		if vector.magnitude(change) > most then
			change = vector.normalize(change) * most
		end
		body.velocity += change
		body.position += body.velocity * DT
		body.yaw += (input.turn or 0) * DT
		body.pitch = toward(body.pitch, input.pitch or 0, FLICK * DT)
		body.crouch = toward(body.crouch, input.crouch or 0, DT / CROUCH_TIME)
		local rate = input.fireRate
		local since = body.sinceShot
		if since then
			since += DT
		end
		if rate and (since == nil or since >= 1 / rate - 1e-9) then
			since = 0
		end
		body.sinceShot = since
		BodyMotion.step(body.state, {
			position = body.position,
			yaw = body.yaw,
			pitch = body.pitch,
			crouch = body.crouch,
			grounded = not input.air,
			hold = input.hold or "rifle",
			foregrip = input.foregrip,
			reloading = input.reloading == true,
			reloadLength = input.reloadLength,
			channel = input.channel or 0,
			gliding = input.gliding == true,
			sinceShot = body.sinceShot,
		}, DT)
		BodyPose.solve(sk, body.state, body.pose)
		if each then
			each(frame)
		end
	end
end

local function joint(body: Body, name: string): vector
	return body.pose.joints[sk.index[name]]
end

-- Where a joint is in the world.
local function placed(body: Body, name: string): vector
	return body.position + Quat.rotate(Quat.aboutY(body.yaw), joint(body, name))
end

-- Where a hand holds: the middle of its grip, from its wrist and its turn.
local function holding(body: Body, arm: BodyRig.Arm): vector
	local turn = body.pose.world[arm.hand]
	local Hd = BodyConfig.Hold
	return body.pose.joints[arm.hand]
		+ Quat.rotate(turn, arm.along) * (Hd.gripAlong.value * arm.knuckles)
		+ Quat.rotate(turn, arm.palm) * Hd.gripPalm.value
end

local RIFLE = 5.4
local KNIFE = 6.75
local MOVES: { { name: string, velocity: vector, crouch: number?, hold: BodyMotion.Hold? } } = {
	{ name = "standing", velocity = vector.zero },
	{ name = "running ahead", velocity = vector.create(0, 0, -RIFLE) },
	{ name = "running back", velocity = vector.create(0, 0, RIFLE) },
	{ name = "running sideways", velocity = vector.create(RIFLE, 0, 0) },
	{ name = "running ahead and to the left", velocity = vector.create(-RIFLE, 0, -RIFLE) * 0.7071 },
	{ name = "walking", velocity = vector.create(0, 0, -RIFLE * 0.61) },
	{ name = "running with the knife", velocity = vector.create(0, 0, -KNIFE), hold = "knife" },
	{ name = "crouch-walking", velocity = vector.create(0, 0, -RIFLE * 0.35), crouch = 1 },
	{ name = "crouch-walking sideways", velocity = vector.create(-RIFLE * 0.35, 0, 0), crouch = 1 },
}

-- What's held ------------------------------------------------------------------------------------

H.section("Agent bodies: how each weapon's held (system 63)")

do
	local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
	local wrong = {}
	for _, id in WeaponConfig.Ids do
		local category = WeaponConfig.Defs[id].category
		local want = if category == "sidearm"
			then "pistol"
			elseif category == "melee" then "knife"
			elseif category == "spike" then "spike"
			elseif category == "ability" or category == "ultimate" then "item"
			else "rifle"
		if BodyMotion.holdOf(id) ~= want then
			table.insert(wrong, id)
		end
	end
	check(
		"sidearms in a pistol grip, the other guns at the shoulder, the knife, the spike, abilities' items",
		#wrong == 0,
		table.concat(wrong, ", ")
	)
	check("nothing in hand, nothing held", BodyMotion.holdOf(nil) == "none" and BodyMotion.holdOf("") == "none")
	check(
		"the Vandal at the shoulder and the Classic in a pistol grip",
		BodyMotion.holdOf("vandal") == "rifle" and BodyMotion.holdOf("classic") == "pistol"
	)
end

-- The head in its box ----------------------------------------------------------------------------

H.section("Agent bodies: the head stays in the head box (system 63)")

do
	local worst = { across = 0, up = 0 }
	local worstAt = { across = "", up = "" }
	local lowest, lowestAt = math.huge, ""
	local stretched, stretchedAt = 0, ""
	local finite = true
	for _, move in MOVES do
		for _, hold in { "rifle", "pistol", "none" } :: { BodyMotion.Hold } do
			for _, pitch in { -1, 0, 1 } do
				for _, crouch in (if move.crouch then { move.crouch } else { 0, 1 }) :: { number } do
					local body = newBody()
					local input: Play = { velocity = move.velocity, crouch = crouch, pitch = pitch, hold = move.hold or hold }
					local label = string.format("%s, %s, pitch %g, crouch %g", move.name, move.hold or hold, pitch, crouch)
					local box = Hitboxes.build({ position = vector.zero, yaw = 0, crouchAlpha = crouch })[1]
					play(body, input, 1.3, function(frame)
						if frame < 25 then
							return
						end
						local pose = body.pose
						local d = pose.headCentre - box.center
						local across = math.max(math.abs(d.x), math.abs(d.z))
						if across > worst.across then
							worst.across, worstAt.across = across, label
						end
						if math.abs(d.y) > worst.up then
							worst.up, worstAt.up = math.abs(d.y), label
						end
						for _, n in { "foot.L", "foot.R", "toe.L", "toe.R", "toe.L_end", "toe.R_end" } do
							local y = joint(body, n).y
							if y < lowest then
								lowest, lowestAt = y, label
							end
						end
						for limb, r in pose.stretch do
							if r > stretched then
								stretched, stretchedAt = r, label .. " (" .. limb .. ")"
							end
						end
						for _, j in pose.joints do
							finite = finite and j == j and math.abs(j.x) < 10 and math.abs(j.y) < 10 and math.abs(j.z) < 10
						end
					end)
				end
			end
		end
	end
	print(string.format("  The head's middle strays from the head box's at most %.3f m across (%s)", worst.across, worstAt.across))
	print(string.format("  ...and %.3f m up or down (%s)", worst.up, worstAt.up))
	print(string.format("  The lowest a foot's joint goes: %.3f m (%s)", lowest, lowestAt))
	print(string.format("  The furthest a limb reaches, of its length: %.3f (%s)", stretched, stretchedAt))
	check("the head's middle stays within 3 cm of the head box's, across", worst.across <= 0.03, string.format("%.3f", worst.across))
	check("...and up and down, running, crouching and aiming up or down", worst.up <= 0.03, string.format("%.3f", worst.up))
	check("the feet never go into the ground", lowest >= -0.005, string.format("%.3f", lowest))
	check("every foot and hand is reached (no limb stretched past its length)", stretched <= 1, string.format("%.3f", stretched))
	check("every joint is a number, near the body", finite)
end

-- Planted feet ------------------------------------------------------------------------------------

H.section("Agent bodies: a foot that's down stays put (system 63)")

do
	local function slide(velocity: vector, crouch: number): (number, number)
		local body = newBody()
		local last: vector? = nil
		local moved, time = 0, 0
		play(body, { velocity = velocity, crouch = crouch }, 3, function(frame)
			local s = body.state
			local ball = body.position + joint(body, "toe.L")
			local down = s.phase < s.stance and s.moving > 0.95
			if frame > 60 and down and last then
				moved += vector.magnitude(ball - last)
				time += DT
			end
			last = if down then ball else nil
		end)
		return if time > 0 then moved / time else 0, vector.magnitude(velocity)
	end
	local lines = {}
	local worst = 0
	for _, case in
		{
			{ "walking", vector.create(0, 0, -RIFLE * 0.61), 0 },
			{ "running", vector.create(0, 0, -RIFLE), 0 },
			{ "with the knife", vector.create(0, 0, -KNIFE), 0 },
			{ "backward", vector.create(0, 0, RIFLE), 0 },
			{ "sideways", vector.create(RIFLE, 0, 0), 0 },
			{ "crouched", vector.create(0, 0, -RIFLE * 0.35), 1 },
		} :: { { any } }
	do
		local speed, of = slide(case[2], case[3])
		table.insert(lines, string.format("%s %.0f%%", case[1], 100 * speed / of))
		if case[1] ~= "sideways" then
			worst = math.max(worst, speed / of)
		end
	end
	print("  A planted foot slides, as a share of the body's speed: " .. table.concat(lines, ", "))
	check("planted feet slide under 15% of the body's speed, ahead, back and crouched", worst <= 0.15, string.format("%.2f", worst))
end

-- Holding -----------------------------------------------------------------------------------------

H.section("Agent bodies: hands on what they hold (system 63)")

do
	local onIt = true
	local misses = {}
	for _, hold in { "rifle", "pistol", "knife", "spike", "item" } :: { BodyMotion.Hold } do
		for _, pitch in { -0.8, 0, 0.8 } do
			for _, crouch in { 0, 1 } do
				local body = newBody()
				play(body, { hold = hold, pitch = pitch, crouch = crouch }, 1)
				local pose = body.pose
				local want = pose.grip + Quat.rotate(pose.held, BodyPose.GRIPS[hold].point)
				local miss = vector.magnitude(holding(body, sk.right) - want)
				if miss > 0.01 then
					onIt = false
					table.insert(misses, string.format("%s pitch %g crouch %g: %.3f m", hold, pitch, crouch, miss))
				end
			end
		end
	end
	check("the right hand holds each kind of thing at its grip, aiming up or down and crouched", onIt, table.concat(misses, "; "))

	local body = newBody()
	play(body, { hold = "rifle" }, 1)
	local pose = body.pose
	local foregrip = pose.grip + Quat.rotate(pose.held, BodyConfig.Hold.foregrip.value)
	check("the left hand holds a rifle at its foregrip", close(holding(body, sk.left), foregrip, 0.01))

	-- The longest guns' foregrips, as far ahead as BodyView puts one.
	local furthest = vector.create(0, -0.05, -0.3)
	local reached = true
	for _, pitch in { -0.8, 0, 0.8 } do
		for _, crouch in { 0, 1 } do
			local long = newBody()
			play(long, { hold = "rifle", foregrip = furthest, pitch = pitch, crouch = crouch }, 1)
			local want = long.pose.grip + Quat.rotate(long.pose.held, furthest)
			reached = reached and close(holding(long, sk.left), want, 0.01)
		end
	end
	check("...and a long gun's 0.30 m ahead of the grip, aiming up or down and crouched", reached)
	check("the rifle points along the aim", close(Quat.rotate(pose.held, AHEAD), AHEAD, 1e-3))
	check("...and the head looks along it", close(Quat.rotate(pose.world[sk.head], AHEAD), AHEAD, 1e-3))
	play(body, { hold = "rifle", pitch = 0.6 }, 1)
	local aim = vector.create(0, math.sin(0.6), -math.cos(0.6))
	check(
		"aiming up, the rifle and the head point up with the aim",
		close(Quat.rotate(body.pose.held, AHEAD), aim, 1e-3) and close(Quat.rotate(body.pose.world[sk.head], AHEAD), aim, 1e-3)
	)

	-- Fingers close toward the palm, both hands.
	local closed = true
	for _, arm in { sk.left, sk.right } do
		local palm = Quat.rotate(body.pose.world[arm.hand], arm.palm)
		local s = if arm.side < 0 then ".L" else ".R"
		local tip = joint(body, "middle03" .. s .. "_end") - joint(body, "middle01" .. s)
		closed = closed and vector.dot(tip, palm) > 0.02
	end
	check("the fingers close toward the palm round the grip, on both hands", closed)

	-- With nothing held and standing still, each side mirrors the other.
	local still = newBody()
	play(still, { hold = "none" }, 1.5)
	local mirrored = true
	for _, n in { "hand", "forearm01", "shin01", "foot", "middle03", "thumb03" } do
		mirrored = mirrored and close(mirror(joint(still, n .. ".L")), joint(still, n .. ".R"), 0.01)
	end
	check("empty-handed and still, the left side mirrors the right (hands, fingers, knees, feet)", mirrored)
end

-- In the air, reloading, planting, drawing ------------------------------------------------------

H.section("Agent bodies: jumping, reloading, planting and drawing (system 63)")

do
	local body = newBody()
	play(body, {}, 1)
	local standL, standR = joint(body, "foot.L"), joint(body, "foot.R")
	play(body, { air = true }, 0.4)
	local airL, airR = joint(body, "foot.L"), joint(body, "foot.R")
	check(
		"in the air the legs tuck, the left higher",
		airL.y - standL.y > 0.12 and airR.y - standR.y > 0.06 and airL.y > airR.y,
		string.format("%.2f, %.2f", airL.y - standL.y, airR.y - standR.y)
	)
	play(body, { air = true, gliding = true }, 0.6)
	local glideL, glideR = joint(body, "foot.L"), joint(body, "foot.R")
	local hips = math.abs(joint(body, "thigh01.L").x - joint(body, "thigh01.R").x)
	check(
		"gliding the legs hang together, the feet closer than the hips",
		math.abs(glideL.x - glideR.x) < hips - 0.06,
		string.format("%.2f, the hips %.2f", math.abs(glideL.x - glideR.x), hips)
	)
	play(body, {}, 1)
	check("back on the ground the feet stand where they stood", close(joint(body, "foot.L"), standL, 0.02))

	-- Landing a long fall: the hips come down a moment, bending the knees,
	-- the head's middle still in its box.
	local fall = newBody()
	play(fall, {}, 1)
	local hipsUp = joint(fall, "spine01").y
	play(fall, { air = true }, BodyConfig.Gait.landLongest.value)
	local lowestHips, worstHead = math.huge, 0
	local headBox = Hitboxes.build({ position = vector.zero, yaw = 0, crouchAlpha = 0 })[1]
	play(fall, {}, 0.5, function()
		lowestHips = math.min(lowestHips, joint(fall, "spine01").y)
		worstHead = math.max(worstHead, math.abs(fall.pose.headCentre.y - headBox.center.y))
	end)
	check("landing a long fall, the hips dip, bending the knees", hipsUp - lowestHips > 0.04, string.format("%.3f m", hipsUp - lowestHips))
	check("...with the head's middle in its box meanwhile", worstHead < headBox.half.y, string.format("%.3f m", worstHead))

	-- Reloading: the left hand leaves the foregrip for the magazine, down
	-- and back up; after, it's on the foregrip again.
	local reload = newBody()
	play(reload, { hold = "rifle" }, 1)
	local before = joint(reload, "hand.L")
	local lowest = math.huge
	play(reload, { hold = "rifle", reloading = true }, BodyConfig.Hold.reloadCycle.value, function()
		lowest = math.min(lowest, joint(reload, "hand.L").y)
	end)
	play(reload, { hold = "rifle" }, 1)
	check("reloading, the left hand goes down to the magazine and out", before.y - lowest > 0.15, string.format("%.2f", before.y - lowest))
	check("...and after it's back on the foregrip", close(joint(reload, "hand.L"), before, 0.01))

	-- A Vandal's 2.5 s reload: the hand's trip takes all of it, smoothly,
	-- and it's back on the foregrip as it ends.
	local long = newBody()
	play(long, { hold = "rifle" }, 1)
	local grip = joint(long, "hand.L")
	local last = grip
	local jump, lowestAt, deepest = 0, 0, math.huge
	local function track(frame: number)
		local hand = joint(long, "hand.L")
		jump = math.max(jump, vector.magnitude(hand - last))
		last = hand
		if hand.y < deepest then
			deepest, lowestAt = hand.y, frame * DT
		end
	end
	play(long, { hold = "rifle", reloading = true, reloadLength = 2.5 }, 2.5, track)
	play(long, { hold = "rifle" }, 1, function()
		local hand = joint(long, "hand.L")
		jump = math.max(jump, vector.magnitude(hand - last))
		last = hand
	end)
	check(
		"a long gun's reload: the left hand's lowest about halfway through it, not before the second",
		lowestAt > 1 and lowestAt < 1.5,
		string.format("%.2f s", lowestAt)
	)
	check("...moving no more than 3 cm a frame, through it and after (no pop)", jump < 0.03, string.format("%.3f m", jump))
	check("...and on the foregrip again after", close(joint(long, "hand.L"), grip, 0.01))

	-- Firing: the gun kicks up and back with a shot, and settles.
	local fire = newBody()
	play(fire, { hold = "rifle" }, 1)
	local aim = Quat.rotate(fire.pose.held, AHEAD)
	local rest = fire.pose.grip
	play(fire, { hold = "rifle", fireRate = 1 }, DT)
	local kicked = Quat.rotate(fire.pose.held, AHEAD)
	local back = fire.pose.grip
	play(fire, { hold = "rifle" }, 0.5)
	check(
		"firing, the muzzle kicks up and the gun comes back",
		kicked.y - aim.y > 0.05 and back.z - rest.z > 0.01,
		string.format("%.3f up, %.3f m back", kicked.y - aim.y, back.z - rest.z)
	)
	check("...and settles again", close(Quat.rotate(fire.pose.held, AHEAD), aim, 1e-3) and close(fire.pose.grip, rest, 1e-3))

	-- Planting crouched: both hands down in front, the spike not drawn in hand.
	local plant = newBody()
	play(plant, { hold = "spike", channel = 1, crouch = 1 }, 1)
	local l, r = joint(plant, "hand.L"), joint(plant, "hand.R")
	check(
		"planting, both hands go down in front",
		l.y < 0.8 and r.y < 0.8 and l.z < -0.1 and r.z < -0.1,
		string.format("%.2f %.2f", l.y, l.z)
	)
	check("...and what's held isn't drawn", plant.pose.shown == false)

	-- Defusing crouched: both hands down on the spike on the ground.
	local defuse = newBody()
	play(defuse, { hold = "none", channel = 2, crouch = 1 }, 1)
	local dl, dr = joint(defuse, "hand.L"), joint(defuse, "hand.R")
	check(
		"defusing crouched, the hands go down on the spike, as far as the arms reach",
		dl.y < 0.52 and dr.y < 0.52 and defuse.pose.stretch.leftArm <= 1 and defuse.pose.stretch.rightArm <= 1,
		string.format("%.2f m up, the arms %.2f of their length", dl.y, defuse.pose.stretch.leftArm)
	)

	-- Drawing: the gun comes up from low.
	local draw = newBody()
	play(draw, { hold = "pistol" }, 1)
	play(draw, { hold = "rifle" }, DT)
	local first = Quat.rotate(draw.pose.held, AHEAD)
	play(draw, { hold = "rifle" }, BodyConfig.Hold.drawTime.value + 0.1)
	check(
		"a new gun starts pointing down and comes up to the aim",
		first.y < -0.5 and close(Quat.rotate(draw.pose.held, AHEAD), AHEAD, 1e-3),
		string.format("%.2f", first.y)
	)
end

-- Turning on the spot ------------------------------------------------------------------------------

H.section("Agent bodies: turning on the spot (system 63)")

do
	-- A small turn leaves the feet where they stand.
	local body = newBody()
	play(body, {}, 1)
	local standL, standR = placed(body, "foot.L"), placed(body, "foot.R")
	local restL, restR = joint(body, "foot.L"), joint(body, "foot.R")
	play(body, { turn = 1 }, 0.4)
	play(body, {}, 0.5)
	check(
		"turning on the spot a little, the feet stay where they stand",
		close(placed(body, "foot.L"), standL, 0.01) and close(placed(body, "foot.R"), standR, 0.01),
		string.format("%.3f, %.3f m", vector.magnitude(placed(body, "foot.L") - standL), vector.magnitude(placed(body, "foot.R") - standR))
	)
	check("...the hips turned part way toward them", body.state.hipYaw < -0.05, string.format("%.2f", body.state.hipYaw))

	-- A quarter turn: the feet step round after it, one lifting then the
	-- other, and come to stand square under the body again.
	local turned = newBody()
	play(turned, {}, 1)
	local liftL, liftR = 0, 0
	local order: { string } = {}
	play(turned, { turn = 2 }, math.pi / 4, function()
		local l, r = joint(turned, "foot.L").y - restL.y, joint(turned, "foot.R").y - restR.y
		liftL, liftR = math.max(liftL, l), math.max(liftR, r)
		if l > 0.02 and order[#order] ~= "left" then
			table.insert(order, "left")
		elseif r > 0.02 and order[#order] ~= "right" then
			table.insert(order, "right")
		end
	end)
	play(turned, {}, 1, function()
		local l, r = joint(turned, "foot.L").y - restL.y, joint(turned, "foot.R").y - restR.y
		liftL, liftR = math.max(liftL, l), math.max(liftR, r)
		if l > 0.02 and order[#order] ~= "left" then
			table.insert(order, "left")
		elseif r > 0.02 and order[#order] ~= "right" then
			table.insert(order, "right")
		end
	end)
	check(
		"turning a quarter to the left, the feet step round after it, the left first",
		liftL > 0.03 and liftR > 0.03 and order[1] == "left",
		string.format("lifts %.3f, %.3f; %s", liftL, liftR, table.concat(order, " then "))
	)
	check(
		"...and stand square under the body again",
		close(joint(turned, "foot.L"), restL, 0.02) and close(joint(turned, "foot.R"), restR, 0.02),
		string.format("%.3f, %.3f m", vector.magnitude(joint(turned, "foot.L") - restL), vector.magnitude(joint(turned, "foot.R") - restR))
	)

	-- A flick turns the feet with it past the most they twist, and they step
	-- after; walking off, they come round with the body.
	local flick = newBody()
	play(flick, {}, 1)
	play(flick, { turn = 12 }, 0.2)
	local most = 0
	for k = 1, 2 do
		most = math.max(most, math.abs(flick.state.feet[k]))
	end
	check(
		"a flick turns the feet as far as they twist, no further",
		most <= BodyConfig.Gait.turnMost.value + 1e-6,
		string.format("%.2f", most)
	)
	play(flick, { velocity = vector.create(0, 0, -RIFLE) }, 1)
	check(
		"...and running off, they come round with the body",
		math.abs(flick.state.feet[1]) < 0.05 and math.abs(flick.state.feet[2]) < 0.05,
		string.format("%.2f, %.2f", flick.state.feet[1], flick.state.feet[2])
	)
end

-- No pops -------------------------------------------------------------------------------------------

H.section("Agent bodies: nothing jumps from one frame to the next (system 63)")

do
	-- The legs' joints: a planted foot moves back under the body as fast as
	-- the body goes, so they're allowed that much more.
	local leg: { [number]: boolean } = {}
	for i, b in sk.bones do
		leg[i] = i == sk.leftLeg.thigh or i == sk.rightLeg.thigh or (b.parent ~= nil and leg[b.parent] == true)
	end
	local body = newBody()
	local last: { vector } = {}
	local worst, worstAt = 0, ""
	local stage = ""
	local function watch()
		local ground = vector.magnitude(body.velocity) * DT
		for i, j in body.pose.joints do
			local was = last[i]
			if was then
				local d = vector.magnitude(j - was) - (if leg[i] then ground else 0)
				if d > worst then
					worst, worstAt = d, stage .. " (" .. sk.bones[i].name .. ")"
				end
			end
			last[i] = j
		end
	end
	for _, step in
		{
			{ "standing", {} :: Play, 0.5 },
			{ "running ahead", { velocity = vector.create(0, 0, -RIFLE) } :: Play, 0.8 },
			{ "cutting right", { velocity = vector.create(RIFLE, 0, 0) } :: Play, 0.6 },
			{ "cutting left", { velocity = vector.create(-RIFLE, 0, 0) } :: Play, 0.6 },
			{ "backing off", { velocity = vector.create(0, 0, RIFLE) } :: Play, 0.6 },
			{ "sideways and back", { velocity = vector.create(RIFLE, 0, RIFLE * 0.2) } :: Play, 0.6 },
			{ "sideways and ahead", { velocity = vector.create(RIFLE, 0, -RIFLE * 0.2) } :: Play, 0.6 },
			{ "crouching", { crouch = 1 } :: Play, 0.6 },
			{ "turning on the spot", { turn = 4 } :: Play, 0.8 },
			{ "turning slowly", { turn = 1.5 } :: Play, 1.2 },
			{ "standing after the turn", {} :: Play, 0.6 },
			{ "jumping", { air = true, velocity = vector.create(0, 0, -RIFLE) } :: Play, 0.5 },
			{ "landing", { velocity = vector.create(0, 0, -RIFLE) } :: Play, 0.5 },
			{ "drawing a pistol", { hold = "pistol" } :: Play, 0.6 },
			{ "reloading", { hold = "pistol", reloading = true } :: Play, 1 },
			{ "reloading a long gun", { hold = "rifle", reloading = true, reloadLength = 2.5 } :: Play, 2.7 },
			{ "firing", { hold = "rifle", fireRate = 9.75 } :: Play, 0.6 },
			{ "defusing crouched", { hold = "none", channel = 2, crouch = 1 } :: Play, 1 },
			{ "looking up", { pitch = 1.2 } :: Play, 0.4 },
			{ "planting", { hold = "spike", channel = 1 } :: Play, 1 },
		} :: { { any } }
	do
		stage = step[1]
		play(body, step[2], step[3], watch)
	end
	print(
		string.format(
			"  The most any joint moves in a frame at 60 frames a second, past the ground's own move: %.3f m (%s)",
			worst,
			worstAt
		)
	)
	-- The quickest real moves (flicking the aim with a gun out while
	-- switching to the spike to plant, a foot swinging across in a
	-- counter-strafe) come to about 12 cm a frame; a pop, a limb jumping
	-- from one place to another, is more.
	check("no joint jumps 15 cm or more in a frame, whatever the body does next", worst < 0.15, string.format("%.3f", worst))
end

return nil
