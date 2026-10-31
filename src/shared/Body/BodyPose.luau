--!strict
-- Poses an agent's body (system 63) from what it's doing (BodyMotion): a
-- turn for every bone, worked out each frame from a few shapes and two-
-- bone reaches rather than recorded animation (Rosen, GDC 2014: "use
-- simple procedural techniques to achieve interactive and fluid animations
-- using very few key frames").
--
-- In order: the hips turn toward the way the legs step and swing with the
-- stride; the back bends to the crouch, the lean and the aim, the chest
-- turned to the stance a gun is held in; the head looks along the aim.
-- Then the whole body moves so the middle of its head sits in the middle of
-- the head box (Hitboxes), the box shots are tested against: a head drawn
-- outside it would be shot at and missed. The hips come down if a foot on
-- the ground couldn't be reached. Each leg then reaches its foot (down,
-- swinging, tucked in the air) and each arm its hand's place on what it
-- holds, which sits off the top of the chest along the aim.

local BodyConfig = require("./BodyConfig")
local BodyMotion = require("./BodyMotion")
local BodyRig = require("./BodyRig")
local Quat = require("./Quat")
local Hitboxes = require("../Combat/Hitboxes")

type Quat = Quat.Quat
type Skeleton = BodyRig.Skeleton
type State = BodyMotion.State

export type Pose = {
	world: { Quat }, -- each bone's turn from where it rests, body space
	turns: { Quat }, -- each bone's turn from its parent's: what the rig's bone takes
	joints: { vector }, -- each bone's joint, body space, metres
	root: vector, -- how far the root bone (the pelvis) has moved from rest
	grip: vector, -- the held thing's grip, body space
	held: Quat, -- the held thing's turn (its barrel along -Z unturned)
	shown: boolean, -- whether the held thing is drawn
	headCentre: vector, -- the middle of the head as posed
	headTarget: vector, -- the middle of the head box
	stretch: { [string]: number }, -- how far each limb reached over its length
	set: { [number]: Quat }, -- working: the bones turned this frame
}

-- Where a hand takes hold of what's held: a point on it and the hand's
-- axes there (toward the knuckles, out of the palm), its own space.
export type Grasp = { point: vector, along: vector, palm: vector }

local BodyPose = {}

local X = vector.create(1, 0, 0)
local Y = vector.create(0, 1, 0)
local FORWARD = vector.create(0, 0, -1)

local function unit(v: vector, fallback: vector): vector
	local m = vector.magnitude(v)
	return if m > 1e-6 then v / m else fallback
end

local function across(v: vector, axis: vector): vector
	return v - axis * vector.dot(v, axis)
end

local function smooth(t: number): number
	local x = math.clamp(t, 0, 1)
	return x * x * (3 - 2 * x)
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function mix(a: vector, b: vector, t: number): vector
	return a + (b - a) * t
end

local function grasp(point: vector, along: vector, palm: vector): Grasp
	return { point = point, along = vector.normalize(along), palm = vector.normalize(palm) }
end

-- The right hand round a pistol grip (raked back a little): fingers round
-- the front, palm to the left. The left hand on a long gun's foregrip,
-- palm up; on a pistol, wrapped round the right.
local GUN_RIGHT = grasp(vector.create(0, -0.06, 0.02), vector.create(0, -0.31, -0.95), vector.create(-1, 0, 0))
local RIFLE_LEFT = grasp(vector.zero, vector.create(0.55, 0.25, -0.8), vector.create(0.2, 1, 0))
local PISTOL_RIGHT = grasp(vector.create(0, -0.045, 0.005), vector.create(0, -0.31, -0.95), vector.create(-1, 0, 0))
local PISTOL_LEFT = grasp(vector.create(-0.035, -0.06, 0.01), vector.create(0.35, -0.3, -0.9), vector.create(1, 0.2, 0))
local KNIFE_RIGHT = grasp(vector.zero, vector.create(0, -1, 0), vector.create(-1, 0, 0))
local SPIKE_RIGHT = grasp(vector.create(0.1, 0, -0.14), vector.create(0, -0.3, -0.95), vector.create(-1, 0, 0))
local SPIKE_LEFT = grasp(vector.create(-0.1, 0, -0.14), vector.create(0, -0.3, -0.95), vector.create(1, 0, 0))
local ITEM_RIGHT = grasp(vector.create(0, -0.02, 0.02), vector.create(0, 0.25, -1), vector.create(0, 1, 0))
local HOLDS: { [string]: { Grasp? } } = {
	pistol = { PISTOL_LEFT, PISTOL_RIGHT },
	knife = { nil, KNIFE_RIGHT },
	spike = { SPIKE_LEFT, SPIKE_RIGHT },
	item = { nil, ITEM_RIGHT },
}
-- A free hand: up in front of the chest beside a knife (its point from the
-- chest), hanging, pressing down on the spike, reaching out for an orb.
local KNIFE_GUARD = grasp(vector.create(-0.12, -0.22, -0.2), vector.create(0.3, 0.3, -1), vector.create(1, 0, 0))
local HANGING = grasp(vector.zero, vector.create(0, -1, 0.1), vector.create(-1, 0, 0))
local PRESSING = grasp(vector.zero, vector.create(0, -0.5, -0.9), vector.create(0, -1, 0))
local REACHING = grasp(vector.zero, vector.create(0, 0, -1), vector.create(0, -1, 0))
-- Reloading, the left hand's trip: the magazine, and down out of the gun.
local RIFLE_MAG = vector.create(0, -0.13, -0.13)
local PISTOL_MAG = vector.create(0, -0.11, 0.01)
local MAG_HAND = grasp(vector.zero, vector.create(0.3, 0, -1), Y)

-- Where the right hand takes hold of each kind of thing held (the tests
-- check the hand lands there).
BodyPose.GRIPS = table.freeze({
	rifle = GUN_RIGHT,
	pistol = PISTOL_RIGHT,
	knife = KNIFE_RIGHT,
	spike = SPIKE_RIGHT,
	item = ITEM_RIGHT,
} :: { [string]: Grasp })

local function headBoxMiddle(crouch: number): number
	for _, box in Hitboxes.build({ position = vector.zero, yaw = 0, crouchAlpha = crouch }) do
		if box.region == "head" then
			return box.center.y
		end
	end
	return 1.62
end

function BodyPose.new(sk: Skeleton): Pose
	local n = #sk.bones
	local pose: Pose = {
		world = table.create(n, Quat.IDENTITY),
		turns = table.create(n, Quat.IDENTITY),
		joints = table.create(n, vector.zero),
		root = vector.zero,
		grip = vector.zero,
		held = Quat.IDENTITY,
		shown = false,
		headCentre = sk.headCentre,
		headTarget = sk.headCentre,
		stretch = {},
		set = {},
	}
	for i, b in sk.bones do
		pose.joints[i] = b.rest
	end
	return pose
end

-- Every bone's joint and turn from the bones turned this frame and the
-- root's move; a bone not turned keeps its parent's turn.
local function forward(sk: Skeleton, out: Pose)
	local world, turns, joints, set, bones = out.world, out.turns, out.joints, out.set, sk.bones
	for i, b in bones do
		local p = b.parent
		if p then
			local parentTurn = world[p]
			local turn = set[i] or parentTurn
			world[i] = turn
			turns[i] = Quat.mul(Quat.conj(parentTurn), turn)
			joints[i] = joints[p] + Quat.rotate(parentTurn, b.rest - bones[p].rest)
		else
			local turn = set[i] or Quat.IDENTITY
			world[i] = turn
			turns[i] = turn
			joints[i] = b.rest + out.root
		end
	end
end

-- Reaches a two-bone limb from `root` toward `target`, its middle joint
-- out toward `pole`: the middle and end joints, each bone's turn from rest,
-- and how far it had to reach over its length (over 1 falls short).
local function reach(
	root: vector,
	target: vector,
	upper: number,
	lower: number,
	pole: vector,
	restRoot: vector,
	restMiddle: vector,
	restEnd: vector,
	restHinge: vector
): (vector, vector, Quat, Quat, number)
	local to = target - root
	local distance = vector.magnitude(to)
	local way = unit(to, vector.create(0, -1, 0))
	local d = math.clamp(distance, math.abs(upper - lower) + 0.04 * (upper + lower), (upper + lower) * 0.9995)
	local a = (upper * upper - lower * lower + d * d) / (2 * d)
	local h = math.sqrt(math.max(upper * upper - a * a, 0))
	local bendWay = unit(across(pole, way), unit(across(FORWARD, way), X))
	local middle = root + way * a + bendWay * h
	local tip = root + way * d
	local hinge = unit(vector.cross(bendWay, way), restHinge)
	local restUpper = unit(restMiddle - restRoot, way)
	local restLower = unit(restEnd - restMiddle, way)
	local upperTurn = Quat.between(restUpper, restHinge, unit(middle - root, way), hinge)
	local lowerTurn = Quat.between(restLower, restHinge, unit(tip - middle, way), hinge)
	return middle, tip, upperTurn, lowerTurn, distance / (upper + lower)
end

-- Where a foot goes this frame: the ball of the foot, which way the foot
-- faces, how far its heel is up and how far its toes bend back (to stay
-- flat as the heel comes up).
local function footFor(leg: BodyRig.Leg, sign: number, s: State, gun: number, under: vector): (vector, Quat, number, number)
	local G = BodyConfig.Gait
	local c = s.crouch
	local m = s.moving
	local phase = (s.phase + (if sign < 0 then 0 else 0.5)) % 1

	-- Where it stands still: apart, the left ahead holding a gun (`gun` is
	-- how much it holds one), under the hips as they turn; standing, turned
	-- as the foot stands (BodyMotion: it stays put as the body turns on the
	-- spot, and steps round after it, lifting).
	local k = if sign < 0 then 1 else 2
	local width = G.width.value + (G.crouchWidth.value - G.width.value) * c + G.sideWidth.value * math.abs(s.direction.x) * m
	local stagger = lerp(G.crouchStagger.value * 0.5 * c, lerp(G.stagger.value, G.crouchStagger.value, c), gun) * (1 - 0.7 * m)
	local own = lerp(s.feet[k], s.hipYaw, m)
	local spot = Quat.rotate(Quat.aboutY(own), vector.create(sign * width, 0, sign * stagger)) + under
	local hips = Quat.aboutY(s.hipYaw)
	local yaw = own - sign * G.turnOut.value + (if sign > 0 then -G.bladeTurn.value * gun * (1 - m) * (1 - 0.5 * c) else 0)
	local facing = Quat.aboutY(lerp(yaw, s.hipYaw, s.glide))
	local toBall = leg.ball - leg.ankle
	local still = spot + Quat.rotate(facing, vector.create(toBall.x, 0, toBall.z)) + vector.create(0, leg.ball.y, 0)

	-- Stepping: down, it sweeps back from ahead of the hip at the body's
	-- speed; up, it swings forward again, lifting.
	-- Of the sweep, the share on the side it's stepping toward: less ahead,
	-- an even split sideways, more behind stepping back.
	local share = lerp(lerp(G.sweepFront.value, 0.5, math.abs(s.direction.x)), G.sweepBack.value, math.max(s.direction.z, 0))
	local front = s.sweep * share
	local along, lift, flat = 0, 0, 1
	if phase < s.stance then
		along = front - s.sweep * phase / s.stance
	else
		local t = (phase - s.stance) / (1 - s.stance)
		local e = t * t * t * (t * (t * 6 - 15) + 10)
		along = front - s.sweep + s.sweep * e
		lift = s.lift * math.sin(math.pi * t)
		flat = 1 - e
	end
	local ball = still + s.direction * (along * m) + vector.create(0, lift * m + s.footLift[k] * (1 - m), 0)
	-- The heel comes up as the foot goes behind the hips.
	local behind = ball.z - still.z
	local heel = G.heelLift.value * smooth(behind / G.heelReach.value) * m
	local toes = heel * flat

	-- In the air the legs tuck up, the left higher; gliding they hang
	-- together, toes pointed.
	local air = s.air
	if air > 0 then
		local tuck = G.tuck.value * (if sign < 0 then 1 else 0.6) * (1 - s.glide)
		local hang = vector.create(sign * lerp(width, 0.06, s.glide), tuck + 0.03 * s.glide, 0.06)
		ball = mix(ball, still - spot + Quat.rotate(hips, hang), air)
		heel = lerp(heel, 0.35 + 0.4 * s.glide, air)
		toes = lerp(toes, 0, air)
	end
	return ball, facing, heel, toes
end

-- A foot's ankle and turn with its ball where it is and its heel up so far.
local function ankleOf(leg: BodyRig.Leg, ball: vector, facing: Quat, heel: number): (vector, Quat)
	local turn = Quat.mul(facing, Quat.aboutX(-heel))
	return ball + Quat.rotate(turn, leg.ankle - leg.ball), turn
end

-- How far the toes bend back to keep them out of the ground, at least.
local function toesFor(leg: BodyRig.Leg, ball: vector, heel: number, toes: number): number
	local room = math.clamp((ball.y - 0.004) / math.max(vector.magnitude(leg.tip - leg.ball), 0.01), 0, 1)
	return math.max(toes, heel - math.asin(room))
end

-- The hand's turn from rest to the axes it's to have.
local function handTurn(arm: BodyRig.Arm, along: vector, palm: vector): Quat
	return Quat.between(arm.along, arm.palm, along, palm)
end

-- Where the wrist goes for a hand to take hold at a point, its axes as
-- given (the palm squared up to the fingers' way).
local function wristFor(arm: BodyRig.Arm, point: vector, along: vector, palm: vector): vector
	local H = BodyConfig.Hold
	local square = unit(across(palm, along), palm)
	return point - along * (H.gripAlong.value * arm.knuckles) - square * H.gripPalm.value
end

-- What's held and the hands for a kind of hold: the held thing's grip and
-- turn, and each hand's wrist, turn and whether it holds anything (left,
-- right).
type Hands = { grip: vector, held: Quat, wrists: { vector }, turns: { Quat }, gripping: { boolean } }

local function handsFor(sk: Skeleton, s: State, out: Pose, hold: BodyMotion.Hold, low: number): Hands
	local H = BodyConfig.Hold
	local m = s.moving * (1 - s.air)
	local cycle = s.phase * 2 * math.pi
	local ahead = -s.direction.z
	local tip = H.reloadDip.value * s.reload + 0.9 * low
	-- A gun kicks up and back with each shot.
	local kick = if hold == "rifle" or hold == "pistol" then s.kick else 0
	local held = Quat.mul(Quat.aboutX(s.pitch - tip + H.kick.value * kick), Quat.aboutZ(H.reloadTilt.value * s.reload))
	if hold == "knife" then
		held = Quat.mul(held, Quat.aboutX(0.6))
	end
	local place: BodyConfig.Point? = if hold == "none" then nil else (H :: any)[hold]
	local chest = out.joints[sk.spine[5]]
	local grip = chest
		+ Quat.rotate(Quat.aboutX(s.pitch * H.follow.value), if place then place.value else vector.zero)
		+ vector.create(0, -0.1 * low - 0.04 * s.reload + 0.008 * math.cos(2 * cycle) * m, 0)
		+ Quat.rotate(held, vector.create(0, 0, H.kickBack.value * kick))
	local grasps: { Grasp? } = if hold == "rifle"
		then { grasp(s.foregrip or H.foregrip.value, RIFLE_LEFT.along, RIFLE_LEFT.palm), GUN_RIGHT }
		else HOLDS[hold] or {}
	local hands: Hands = { grip = grip, held = held, wrists = {}, turns = {}, gripping = {} }
	for k, arm in { sk.left, sk.right } do
		local sign = arm.side
		local g = grasps[k]
		local wrist, along, palm
		if g then
			along, palm = Quat.rotate(held, g.along), Quat.rotate(held, g.palm)
			wrist = wristFor(arm, grip + Quat.rotate(held, g.point), along, palm)
		elseif hold == "knife" then
			-- The free hand up in front of the chest.
			along, palm = KNIFE_GUARD.along, KNIFE_GUARD.palm
			wrist = chest + KNIFE_GUARD.point
		else
			-- Hanging, swinging against the leg on its side.
			local swing = H.armSwing.value * math.cos(cycle) * m * ahead * -sign
			along, palm = HANGING.along, vector.create(-sign, 0, 0)
			wrist = out.joints[arm.upper] + vector.create(sign * 0.07, -(arm.upperLength + arm.foreLength) * 0.93, 0.03 + swing)
		end
		local turn = handTurn(arm, along, palm)
		-- Reloading, the left hand goes to the magazine, takes it down out of
		-- the gun, brings the next up into it and goes back, once over the
		-- gun's reload.
		if g and k == 1 and (hold == "rifle" or hold == "pistol") and s.reload > 0.01 then
			local u = s.reloadShare
			local mag = if hold == "rifle" then RIFLE_MAG else PISTOL_MAG
			local pulled = mag + vector.create(0, -0.25, 0.05)
			local spot = if u < 0.2
				then mag
				elseif u < 0.45 then mix(mag, pulled, smooth((u - 0.2) / 0.25))
				elseif u < 0.7 then mix(pulled, mag, smooth((u - 0.45) / 0.25))
				else mag
			local weight = s.reload * (if u < 0.2 then smooth(u / 0.2) elseif u > 0.85 then smooth((1 - u) / 0.15) else 1)
			local magAlong, magPalm = Quat.rotate(held, MAG_HAND.along), Quat.rotate(held, MAG_HAND.palm)
			wrist = mix(wrist, wristFor(arm, grip + Quat.rotate(held, spot), magAlong, magPalm), weight)
			turn = Quat.nlerp(turn, handTurn(arm, magAlong, magPalm), weight)
		end
		hands.wrists[k], hands.turns[k], hands.gripping[k] = wrist, turn, g ~= nil or hold == "knife"
	end
	return hands
end

-- Curls a hand's fingers by `grip` at each knuckle (the index finger by
-- `index`), and brings the thumb across.
local function curl(arm: BodyRig.Arm, set: { [number]: Quat }, grip: number, index: number)
	local hand = set[arm.hand]
	local hinge = unit(vector.cross(arm.along, arm.palm), Y)
	for f, chain in arm.fingers do
		local step = Quat.axisAngle(hinge, if f == 1 then index else grip)
		local turn = hand
		for _, i in chain do
			turn = Quat.mul(turn, step)
			set[i] = turn
		end
	end
	local turn = Quat.mul(hand, Quat.axisAngle(arm.along, -arm.side * 0.4 * grip))
	for k, i in arm.thumb do
		if k > 1 then
			turn = Quat.mul(turn, Quat.axisAngle(hinge, 0.4 * grip))
		end
		set[i] = turn
	end
end

-- Poses the body for this frame into `out`.
function BodyPose.solve(sk: Skeleton, s: State, out: Pose)
	local B, G, S, H = BodyConfig.Body, BodyConfig.Gait, BodyConfig.Spine, BodyConfig.Hold
	local set = out.set
	table.clear(set)
	table.clear(out.stretch)
	out.root = vector.zero

	local c = s.crouch
	local ground = 1 - s.air
	local m = s.moving * ground
	local cycle = s.phase * 2 * math.pi
	local hold: BodyMotion.Hold = s.hold
	-- Planting or taking an orb, eased in and out (no lurch as it starts).
	local plant, orb = smooth(s.plant), smooth(s.orb)
	local busy = math.max(plant, orb)
	local ahead = -s.direction.z -- 1 stepping forward, -1 back
	-- Switching what's held, the stance goes from the old hold's to the
	-- new over a moment, as the hands do.
	local switching = if s.previous ~= hold then 1 - smooth(s.draw / H.switchTime.value) else 0
	local function stance(of: (BodyMotion.Hold) -> number): number
		return lerp(of(hold), of(s.previous), switching)
	end

	-- The hips: turned toward the way the legs step, swinging with the
	-- stride (the left hip forward with the left foot), tipped forward to
	-- the crouch and to running, rolling with each step.
	local lean = S.crouchLean.value * c + math.clamp(-s.velocity.z * S.runLean.value, -0.06, S.runLeanMax.value) * ground
	local sideLean = math.clamp(s.velocity.x * S.sideLean.value, -0.1, 0.1) * ground
	local swing = -G.hipSwing.value * math.cos(cycle) * m * ahead
	local roll = G.hipRoll.value * math.sin(cycle) * m
	local pelvis =
		Quat.mul(Quat.aboutY(s.hipYaw + swing), Quat.mul(Quat.aboutX(-lean * S.pelvisShare.value), Quat.aboutZ(roll - sideLean * 0.5)))

	-- The back: the lower spine bends from the hips to the lean, turning to
	-- the stance a gun is held in; the upper spine takes the chest's share
	-- of the aim (bending higher up moves the head less).
	local blade = stance(function(h)
		return if h == "rifle" then S.blade.value elseif h == "pistol" then S.pistolBlade.value elseif h == "knife" then -0.15 else 0
	end) * (1 - busy)
	local breath = S.breathe.value * math.sin(s.time * 2 * math.pi * S.breatheRate.value)
	local torso = Quat.mul(Quat.aboutX(-lean), Quat.mul(Quat.aboutY(blade), Quat.aboutZ(-sideLean)))
	local chest = Quat.mul(Quat.aboutX(s.pitch * (if s.pitch > 0 then S.aimChest.value else S.aimChestDown.value) + breath), torso)
	local spine = sk.spine
	set[spine[1]] = pelvis
	set[spine[2]] = Quat.mul(pelvis, Quat.scale(Quat.mul(Quat.conj(pelvis), torso), 0.5))
	set[spine[3]] = torso
	set[spine[4]] = Quat.mul(torso, Quat.scale(Quat.mul(Quat.conj(torso), chest), 0.5))
	set[spine[5]] = chest
	-- The neck and head look along the aim, the head tipped to a long gun's
	-- stock.
	local cheek = stance(function(h)
		return if h == "rifle" then S.cheek.value else 0
	end) * (1 - busy)
	local look = Quat.mul(Quat.aboutX(s.pitch), Quat.aboutZ(cheek))
	set[spine[6]] = Quat.mul(chest, Quat.scale(Quat.mul(Quat.conj(chest), look), S.aimNeck.value))
	set[sk.head] = look

	-- Move the body so the head is in its box (a little bob and sway with
	-- the steps, and a dip landing).
	forward(sk, out)
	local headNow = out.joints[sk.head] + Quat.rotate(out.world[sk.head], sk.headCentre - sk.headJoint)
	local target = vector.create(
		B.sway.value * math.sin(cycle) * m,
		headBoxMiddle(c) + B.bob.value * math.cos(2 * cycle) * m - B.landDip.value * s.land,
		0
	)
	local root = target - headNow

	-- The feet, under the hips part way. A foot the leg can't reach from
	-- where the hips are rises onto its ball (as far as `tiptoe`), and
	-- if that's not enough the hips come down.
	local legs = { sk.leftLeg, sk.rightLeg }
	local balls: { vector } = {}
	local facings: { Quat } = {}
	local heels: { number } = {}
	local toes: { number } = {}
	local under = vector.create(root.x, 0, root.z) * lerp(G.underHips.value, G.underHipsMoving.value, m)
	local gun = stance(function(h)
		return if h == "rifle" or h == "pistol" then 1 else 0
	end)
	for k, leg in legs do
		balls[k], facings[k], heels[k], toes[k] = footFor(leg, if k == 1 then -1 else 1, s, gun, under)
	end
	if s.air < 0.5 then
		local drop = 0
		for k, leg in legs do
			local hip = out.joints[leg.thigh] + root
			local length = (leg.upper + leg.lower) * 0.985
			local function short(heel: number): number
				local to = ankleOf(leg, balls[k], facings[k], heel) - hip
				local level = to.x * to.x + to.z * to.z
				if level >= length * length then
					return 0 -- too far out to help by coming down
				end
				return to.y + math.sqrt(length * length - level)
			end
			-- short(heel) < 0 is how far the hip is above the highest it reaches.
			local most = math.max(heels[k], G.tiptoe.value)
			if short(heels[k]) < 0 and heels[k] < most then
				local lo, hi = heels[k], most
				if short(hi) >= 0 then
					for _ = 1, 10 do
						local mid = (lo + hi) * 0.5
						if short(mid) >= 0 then
							hi = mid
						else
							lo = mid
						end
					end
				end
				heels[k] = hi
			end
			drop = math.max(drop, -short(heels[k]))
		end
		if drop > 0 then
			root -= vector.create(0, drop, 0)
		end
	end
	out.root = root
	forward(sk, out)

	for k, leg in legs do
		local sign = if k == 1 then -1 else 1
		local ankle, foot = ankleOf(leg, balls[k], facings[k], heels[k])
		local facing = Quat.rotate(facings[k], FORWARD)
		local pole = vector.create(facing.x, 0, facing.z) + vector.create(sign * (0.12 + 0.15 * c), 0, 0)
		local _, _, thigh, shin, stretch =
			reach(out.joints[leg.thigh], ankle, leg.upper, leg.lower, pole, leg.hip, leg.knee, leg.ankle, leg.hinge)
		set[leg.thigh] = thigh
		set[leg.shin] = shin
		set[leg.foot] = foot
		set[leg.toe] = Quat.mul(foot, Quat.aboutX(toesFor(leg, balls[k], heels[k], toes[k])))
		out.stretch[if k == 1 then "leftLeg" else "rightLeg"] = stretch
	end

	-- What's held, and the hands on it. Switching what's held, the hands
	-- go from the old hold to the new over a moment, and the new thing
	-- comes up from low; put away for a defuse or an orb, they go from
	-- what was held straight to the work, not by the sides on the way.
	local low = 1 - smooth(s.draw / H.drawTime.value)
	local stowed = hold == "none" and s.previous ~= "none" and busy > 0.001
	local hands = if stowed then handsFor(sk, s, out, s.previous, 0) else handsFor(sk, s, out, hold, low)
	out.grip, out.held = hands.grip, hands.held
	out.shown = hold ~= "none" and busy < 0.5
	local before = if switching > 0 and not stowed then handsFor(sk, s, out, s.previous, 0) else nil
	local chestJoint = out.joints[spine[5]]
	for k, arm in { sk.left, sk.right } do
		local sign = arm.side
		local wrist, turn = hands.wrists[k], hands.turns[k]
		local function poleFor(gripping: boolean): vector
			local E = if not gripping then H.relaxedElbow.value elseif sign < 0 then H.leftElbow.value else H.rightElbow.value
			return if gripping then E else vector.create(sign * E.x, E.y, E.z)
		end
		local pole = poleFor(hands.gripping[k])
		local closed = if hands.gripping[k] then H.curl.value else H.relaxedCurl.value
		if before then
			wrist = mix(wrist, before.wrists[k], switching)
			turn = Quat.nlerp(turn, before.turns[k], switching)
			pole = mix(pole, poleFor(before.gripping[k]), switching)
			closed = lerp(closed, if before.gripping[k] then H.curl.value else H.relaxedCurl.value, switching)
		end
		-- Planting or defusing, both hands go down to the spike; taking an
		-- orb, the right reaches out.
		if plant > 0.001 then
			local pump = if s.channel == 2 then 0.025 * math.sin(s.time * 2 * math.pi * 3) else 0
			local press = mix(H.press.value, H.pressCrouched.value, c)
			local spot = vector.create(sign * press.x, press.y + pump, press.z)
			local along, palm = PRESSING.along, PRESSING.palm
			wrist = mix(wrist, wristFor(arm, spot, along, palm), plant)
			turn = Quat.nlerp(turn, handTurn(arm, along, palm), plant)
			closed = lerp(closed, H.relaxedCurl.value, plant)
		end
		if orb > 0.001 and sign > 0 then
			local spot = chestJoint + vector.create(0.12, -0.08, -0.5)
			local along, palm = REACHING.along, REACHING.palm
			wrist = mix(wrist, wristFor(arm, spot, along, palm), orb)
			turn = Quat.nlerp(turn, handTurn(arm, along, palm), orb)
		end

		-- The collarbone gives a little toward the hand, then the arm reaches.
		local collar = out.joints[arm.clavicle]
		local from = unit(out.joints[arm.upper] - collar, X)
		local shrug = Quat.scale(Quat.fromTo(from, unit(wrist - collar, from)), 0.12)
		local angle = Quat.angle(shrug)
		if angle > 0.25 then
			shrug = Quat.scale(shrug, 0.25 / angle)
		end
		local clavicle = Quat.mul(shrug, out.world[arm.clavicle])
		set[arm.clavicle] = clavicle
		local shoulder = collar + Quat.rotate(clavicle, arm.shoulder - arm.collar)
		local _, _, upper, fore, stretch =
			reach(shoulder, wrist, arm.upperLength, arm.foreLength, pole, arm.shoulder, arm.elbow, arm.wrist, arm.hinge)
		set[arm.upper] = upper
		set[arm.forearm] = fore
		set[arm.hand] = turn
		-- The forearm's twist bone takes half the twist to the hand.
		if arm.forearmTwist then
			local twist = Quat.twist(Quat.mul(Quat.conj(fore), turn), unit(arm.wrist - arm.elbow, X))
			set[arm.forearmTwist] = Quat.mul(fore, Quat.scale(twist, 0.5))
		end
		out.stretch[if k == 1 then "leftArm" else "rightArm"] = stretch

		-- The right index finger rests on a gun's trigger.
		local trigger = if k == 2 then gun * (1 - busy) else 0
		curl(arm, set, closed, lerp(closed, H.triggerCurl.value, trigger))
	end

	forward(sk, out)
	out.headCentre = out.joints[sk.head] + Quat.rotate(out.world[sk.head], sk.headCentre - sk.headJoint)
	out.headTarget = target
end

return BodyPose
