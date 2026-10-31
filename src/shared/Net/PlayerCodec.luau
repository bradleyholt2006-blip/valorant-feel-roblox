--!strict
-- Binary packing for player simulation traffic.
--
--   Input    (client -> server, reliable):   19 bytes per 128 Hz tick, 27
--                                            with a place on the map
--   Ack      (server -> owner, unreliable):  full PlayerSim state at a seq
--   Snapshot (server -> all, unreliable):    pose of every entity at a server time
--
-- Pure buffer code (no Roblox APIs), so the offline tests round-trip it.

local WeaponConfig = require("../Weapons/WeaponConfig")
local AbilityConfig = require("../Abilities/AbilityConfig")

local PlayerCodec = {}

local TAU = 2 * math.pi
-- A player's weapon slots: the three weapons, the spike and an ultimate's
-- weapon (WeaponSim.SLOTS).
local SLOTS = 5

local function packAngle(a: number): number
	return math.floor(((a % TAU) / TAU) * 65536 + 0.5) % 65536
end

local function unpackAngle(v: number): number
	return v / 65536 * TAU
end

local function packPitch(p: number): number
	return math.clamp(math.floor(p * 10000 + 0.5), -32767, 32767)
end

-- The client quantises its own copies exactly like the wire does, so both
-- sides simulate bit-identical inputs.
function PlayerCodec.quantizeYaw(yaw: number): number
	return unpackAngle(packAngle(yaw))
end

function PlayerCodec.quantizePitch(pitch: number): number
	return packPitch(pitch) / 10000
end

-- Cursor helpers ----------------------------------------------------------

type Cursor = { b: buffer, o: number }

local function w8(c: Cursor, v: number)
	buffer.writeu8(c.b, c.o, v)
	c.o += 1
end
local function w16(c: Cursor, v: number)
	buffer.writeu16(c.b, c.o, v)
	c.o += 2
end
local function wi16(c: Cursor, v: number)
	buffer.writei16(c.b, c.o, v)
	c.o += 2
end
local function w32(c: Cursor, v: number)
	buffer.writeu32(c.b, c.o, v)
	c.o += 4
end
local function wf32(c: Cursor, v: number)
	buffer.writef32(c.b, c.o, v)
	c.o += 4
end
local function wf64(c: Cursor, v: number)
	buffer.writef64(c.b, c.o, v)
	c.o += 8
end
local function r8(c: Cursor): number
	local v = buffer.readu8(c.b, c.o)
	c.o += 1
	return v
end
local function r16(c: Cursor): number
	local v = buffer.readu16(c.b, c.o)
	c.o += 2
	return v
end
local function ri16(c: Cursor): number
	local v = buffer.readi16(c.b, c.o)
	c.o += 2
	return v
end
local function r32(c: Cursor): number
	local v = buffer.readu32(c.b, c.o)
	c.o += 4
	return v
end
local function rf32(c: Cursor): number
	local v = buffer.readf32(c.b, c.o)
	c.o += 4
	return v
end
local function rf64(c: Cursor): number
	local v = buffer.readf64(c.b, c.o)
	c.o += 8
	return v
end

-- Inputs --------------------------------------------------------------------

export type WireInput = {
	seq: number,
	buttons: number,
	slot: number,
	yaw: number,
	pitch: number,
	viewTime: number,
	-- The place picked on the map while From the Shadows' map is in hand
	-- (system 43): metres across the floor, its y 0. Nil without.
	point: vector?,
}

local INPUT_SIZE = 19
-- A place on the map takes the slot byte's top bit and two floats after.
local POINT_FLAG = 128
local POINT_SIZE = 8
-- The seventeenth button (F's, system 49) takes the slot byte's next bit,
-- and the eighteenth (the pad's zoom let go, system 68) the one after.
local HIGH_BUTTON = 65536
local HIGH_FLAG = 64
local HIGHER_BUTTON = 131072
local HIGHER_FLAG = 32
-- Further from the place's middle than any map goes, metres.
local POINT_MOST = 1e6
local MAX_INPUTS_PER_PACKET = 256
PlayerCodec.MAX_INPUTS_PER_PACKET = MAX_INPUTS_PER_PACKET

-- A place on the map as the wire carries it, so the client simulates what
-- the server will: across the floor, single precision (a vector's
-- components are), with no height.
function PlayerCodec.quantizePoint(point: vector): vector
	return vector.create(point.x, 0, point.z)
end

function PlayerCodec.encodeInputs(inputs: { WireInput }, first: number, last: number): buffer
	local size = 0
	for i = first, last do
		size += INPUT_SIZE + (if inputs[i].point then POINT_SIZE else 0)
	end
	local c: Cursor = { b = buffer.create(size), o = 0 }
	for i = first, last do
		local input = inputs[i]
		local point = input.point
		local high = bit32.band(input.buttons, HIGH_BUTTON) ~= 0
		local higher = bit32.band(input.buttons, HIGHER_BUTTON) ~= 0
		w32(c, input.seq)
		w16(c, bit32.band(input.buttons, HIGH_BUTTON - 1))
		w8(c, input.slot + (if point then POINT_FLAG else 0) + (if high then HIGH_FLAG else 0) + (if higher then HIGHER_FLAG else 0))
		w16(c, packAngle(input.yaw))
		wi16(c, packPitch(input.pitch))
		wf64(c, input.viewTime)
		if point then
			wf32(c, point.x)
			wf32(c, point.z)
		end
	end
	return c.b
end

-- Returns nil for malformed payloads so the server can drop them.
function PlayerCodec.decodeInputs(b: any): { WireInput }?
	if typeof(b) ~= "buffer" then
		return nil
	end
	local len = buffer.len(b)
	if len == 0 or len > (INPUT_SIZE + POINT_SIZE) * MAX_INPUTS_PER_PACKET then
		return nil
	end
	local c: Cursor = { b = b, o = 0 }
	local out = table.create(len // INPUT_SIZE)
	while c.o < len do
		if c.o + INPUT_SIZE > len or #out >= MAX_INPUTS_PER_PACKET then
			return nil
		end
		local seq = r32(c)
		local buttons = r16(c)
		local slotByte = r8(c)
		local yaw = unpackAngle(r16(c))
		local pitch = ri16(c) / 10000
		local viewTime = rf64(c)
		local slot = bit32.band(slotByte, HIGHER_FLAG - 1)
		if bit32.band(slotByte, HIGH_FLAG) ~= 0 then
			buttons += HIGH_BUTTON
		end
		if bit32.band(slotByte, HIGHER_FLAG) ~= 0 then
			buttons += HIGHER_BUTTON
		end
		if slot < 1 or slot > SLOTS or viewTime ~= viewTime then
			return nil
		end
		local point: vector? = nil
		if bit32.band(slotByte, POINT_FLAG) ~= 0 then
			if c.o + POINT_SIZE > len then
				return nil
			end
			local x = rf32(c)
			local z = rf32(c)
			if not (math.abs(x) < POINT_MOST and math.abs(z) < POINT_MOST) then
				return nil
			end
			point = vector.create(x, 0, z)
		end
		table.insert(out, { seq = seq, buttons = buttons, slot = slot, yaw = yaw, pitch = pitch, viewTime = viewTime, point = point })
	end
	return out
end

-- Ack: everything PlayerSim needs to resume from this state ------------------

local ACK_SIZE = 4 -- seq
	+ 4 + 8 * 3 + 8 * 3 + 4 * 3 + 1 + 8 + 4 + 4 -- movement
	+ SLOTS + SLOTS + 2 * SLOTS + 1 + 8 * 3 + 1 + 1 + 8 + 8 + 4 + 4 + 8 + 1 + 1 + 8 + 8 + 1 + 2 + 2 -- weapons
	+ 1 + 8 + 8 + 1 + 1 -- the spike's plant or defuse, or an Ultimate Orb taken
	+ 1 + 3 + 3 + 10 + 8 * 29 + 4 * 18 -- the ability kit
	+ 4 + 8 -- tag

local function ago(tick: number, past: number): number
	return math.clamp(tick - past, 0, 2 ^ 31 - 1)
end

function PlayerCodec.encodeAck(seq: number, s: any): buffer
	local c: Cursor = { b = buffer.create(ACK_SIZE), o = 0 }
	local m, w = s.movement, s.weapons
	w32(c, seq)

	w32(c, m.tick)
	wf64(c, m.position.x)
	wf64(c, m.position.y)
	wf64(c, m.position.z)
	wf64(c, m.velocity.x)
	wf64(c, m.velocity.y)
	wf64(c, m.velocity.z)
	-- Exact: a vector's components are single precision.
	wf32(c, m.groundNormal.x)
	wf32(c, m.groundNormal.y)
	wf32(c, m.groundNormal.z)
	w8(
		c,
		(if m.grounded then 1 else 0)
			+ (if m.crouched then 2 else 0)
			+ (if m.jumpLatched then 4 else 0)
			+ (if m.gliding then 8 else 0)
			+ (if m.slowed then 16 else 0)
	)
	wf64(c, m.crouchAlpha)
	w32(c, ago(m.tick, m.lastJumpTick))
	w32(c, ago(m.tick, m.lastLandTick))

	for slot = 1, SLOTS do
		w8(c, WeaponConfig.IndexOf[w.loadout[slot]] or 0)
	end
	for slot = 1, SLOTS do
		w8(c, math.clamp(w.ammo[slot], 0, 255))
	end
	for slot = 1, SLOTS do
		w16(c, math.clamp(w.reserve[slot], 0, 65535))
	end
	w8(c, w.equipped)
	wf64(c, w.equipEndTime)
	wf64(c, w.nextFireTime)
	wf64(c, w.reloadEndTime)
	w8(c, w.scoped)
	w8(c, (if w.fireHeld then 1 else 0) + (if w.altHeld then 2 else 0))
	wf64(c, w.lastShotTime)
	wf64(c, w.sprayIndex)
	w32(c, w.shotCounter % 2 ^ 32)
	w32(c, w.seed)
	wf64(c, w.recoilYaw)
	w8(c, w.swayDir + 1)
	w8(c, math.clamp(w.burstLeft, 0, 255))
	wf64(c, w.burstNext)
	wf64(c, w.spin)
	w8(c, w.combo)
	w8(c, w.back)
	w8(c, w.hold)
	-- A buff's quickening (system 75), in hundredths: the frenzy's are whole
	-- hundredths, so they come back exactly.
	w8(c, math.clamp(math.round(w.rate * 100), 0, 255))
	w8(c, math.clamp(math.round(w.handling * 100), 0, 255))

	local k = s.spike
	w8(c, k.channel)
	wf64(c, k.channelStart)
	wf64(c, k.channelEnd)
	-- The Ultimate Orb being taken (system 49) in the flags' top bits.
	w8(c, (if k.halfStart then 1 else 0) + (if k.dropHeld then 2 else 0) + (if k.holdOver then 4 else 0) + 8 * math.clamp(k.orb, 0, 31))
	w8(c, k.lastSlot)

	local a = s.abilities
	w8(c, AbilityConfig.AgentIndex[a.agent] or 0)
	for slot = 1, 3 do
		w8(c, math.clamp(a.charges[slot], 0, 255))
	end
	for slot = 1, 3 do
		w8(c, math.clamp(a.owned[slot], 0, 255))
	end
	w8(c, math.clamp(a.regained, 0, 255))
	w8(c, math.clamp(a.kills, 0, 255))
	w8(c, math.clamp(a.points, 0, 255))
	w8(c, math.clamp(a.need, 0, 255))
	-- The kit's keys, a bit a slot (their buttons are the input's top four).
	w8(c, bit32.rshift(a.held, 12))
	w8(c, if a.storm then 1 else 0)
	w8(c, a.holding)
	w8(c, a.steering)
	w8(
		c,
		(if a.markGrounded then 1 else 0)
			+ (if a.markCrouched then 2 else 0)
			+ (if a.turning then 4 else 0)
			+ (if a.letDown then 8 else 0)
			+ (if a.altDown then 16 else 0)
	)
	w8(c, math.clamp(a.bounces, 0, 255))
	wf64(c, a.readyFrom)
	wf64(c, a.readyUntil)
	wf64(c, a.liftUntil)
	wf64(c, a.dashUntil)
	wf64(c, a.dashX)
	wf64(c, a.dashZ)
	wf64(c, a.steerUntil)
	wf64(c, a.backUntil)
	wf64(c, a.returnAt)
	wf64(c, a.markYaw)
	wf64(c, a.turn)
	wf64(c, a.fixed)
	wf64(c, a.floatUntil)
	wf64(c, a.heldUntil)
	wf64(c, a.reach)
	wf64(c, a.stepAt)
	wf64(c, a.shadowAt)
	wf64(c, a.drawFrom)
	wf64(c, a.furyUntil)
	wf64(c, a.chargeAt)
	wf64(c, a.kickFrom)
	wf64(c, a.kickYaw)
	wf64(c, a.droneFrom)
	wf64(c, a.landAt)
	wf64(c, a.dartAt)
	wf64(c, a.bodyYaw)
	wf64(c, a.bodyPitch)
	wf64(c, a.dismissUntil)
	wf64(c, a.empressAt)
	-- Exact: a vector's components are single precision.
	for _, v in { a.mark, a.stepTo, a.shadowFrom, a.shadowTo, a.dronePos, a.droneVel } do
		wf32(c, v.x)
		wf32(c, v.y)
		wf32(c, v.z)
	end

	w32(c, math.clamp(s.tagUntilTick, 0, 2 ^ 32 - 1))
	wf64(c, s.tagMultiplier)
	return c.b
end

function PlayerCodec.decodeAck(b: buffer): (number, any)
	local c: Cursor = { b = b, o = 0 }
	local seq = r32(c)

	local tick = r32(c)
	local px = rf64(c)
	local py = rf64(c)
	local pz = rf64(c)
	local vx = rf64(c)
	local vy = rf64(c)
	local vz = rf64(c)
	local position = vector.create(px, py, pz)
	local velocity = vector.create(vx, vy, vz)
	local nx = rf32(c)
	local ny = rf32(c)
	local nz = rf32(c)
	local flags = r8(c)
	local crouchAlpha = rf64(c)
	local jumpAgo = r32(c)
	local landAgo = r32(c)
	local movement = {
		tick = tick,
		position = position,
		velocity = velocity,
		grounded = bit32.band(flags, 1) ~= 0,
		crouched = bit32.band(flags, 2) ~= 0,
		jumpLatched = bit32.band(flags, 4) ~= 0,
		gliding = bit32.band(flags, 8) ~= 0,
		slowed = bit32.band(flags, 16) ~= 0,
		groundNormal = vector.create(nx, ny, nz),
		crouchAlpha = crouchAlpha,
		lastJumpTick = tick - jumpAgo,
		lastLandTick = tick - landAgo,
	}

	local loadout, ammo, reserve = {}, {}, {}
	for slot = 1, SLOTS do
		loadout[slot] = WeaponConfig.Ids[r8(c)] or ""
	end
	for slot = 1, SLOTS do
		ammo[slot] = r8(c)
	end
	for slot = 1, SLOTS do
		reserve[slot] = r16(c)
	end
	local equipped = r8(c)
	local equipEndTime = rf64(c)
	local nextFireTime = rf64(c)
	local reloadEndTime = rf64(c)
	local scoped = r8(c)
	local wflags = r8(c)
	local lastShotTime = rf64(c)
	local sprayIndex = rf64(c)
	local shotCounter = r32(c)
	local seed = r32(c)
	local recoilYaw = rf64(c)
	local swayDir = r8(c) - 1
	local burstLeft = r8(c)
	local burstNext = rf64(c)
	local spin = rf64(c)
	local combo = r8(c)
	local back = r8(c)
	local hold = r8(c)
	local rate = r8(c) / 100
	local handling = r8(c) / 100
	local weapons = {
		loadout = loadout,
		ammo = ammo,
		reserve = reserve,
		equipped = equipped,
		equipEndTime = equipEndTime,
		nextFireTime = nextFireTime,
		reloadEndTime = reloadEndTime,
		scoped = scoped,
		fireHeld = bit32.band(wflags, 1) ~= 0,
		altHeld = bit32.band(wflags, 2) ~= 0,
		lastShotTime = lastShotTime,
		sprayIndex = sprayIndex,
		shotCounter = shotCounter,
		seed = seed,
		recoilYaw = recoilYaw,
		swayDir = swayDir,
		burstLeft = burstLeft,
		burstNext = burstNext,
		spin = spin,
		combo = combo,
		back = back,
		hold = hold,
		rate = rate,
		handling = handling,
	}

	local channel = r8(c)
	local channelStart = rf64(c)
	local channelEnd = rf64(c)
	local kflags = r8(c)
	local lastSlot = r8(c)
	local spike = {
		channel = channel,
		channelStart = channelStart,
		channelEnd = channelEnd,
		halfStart = bit32.band(kflags, 1) ~= 0,
		dropHeld = bit32.band(kflags, 2) ~= 0,
		holdOver = bit32.band(kflags, 4) ~= 0,
		lastSlot = lastSlot,
		orb = bit32.rshift(kflags, 3),
	}

	local agentIndex = r8(c)
	local agent = if agentIndex == 0 then AbilityConfig.NO_AGENT else AbilityConfig.AgentIds[agentIndex] or AbilityConfig.DEFAULT_AGENT
	local charges = { r8(c), r8(c), r8(c), 0 }
	local owned = { r8(c), r8(c), r8(c), 0 }
	local regained = r8(c)
	local kills = r8(c)
	local points = r8(c)
	local need = r8(c)
	local held = bit32.lshift(r8(c), 12)
	local storm = r8(c) ~= 0
	local holding = r8(c)
	local steering = r8(c)
	local markFlags = r8(c)
	local bounces = r8(c)
	local readyFrom = rf64(c)
	local readyUntil = rf64(c)
	local liftUntil = rf64(c)
	local dashUntil = rf64(c)
	local dashX = rf64(c)
	local dashZ = rf64(c)
	local steerUntil = rf64(c)
	local backUntil = rf64(c)
	local returnAt = rf64(c)
	local markYaw = rf64(c)
	local turn = rf64(c)
	local fixed = rf64(c)
	local floatUntil = rf64(c)
	local heldUntil = rf64(c)
	local reach = rf64(c)
	local stepAt = rf64(c)
	local shadowAt = rf64(c)
	local drawFrom = rf64(c)
	local furyUntil = rf64(c)
	local chargeAt = rf64(c)
	local kickFrom = rf64(c)
	local kickYaw = rf64(c)
	local droneFrom = rf64(c)
	local landAt = rf64(c)
	local dartAt = rf64(c)
	local bodyYaw = rf64(c)
	local bodyPitch = rf64(c)
	local dismissUntil = rf64(c)
	local empressAt = rf64(c)
	local function point(): vector
		local x = rf32(c)
		local y = rf32(c)
		local z = rf32(c)
		return vector.create(x, y, z)
	end
	local mark = point()
	local stepTo = point()
	local shadowFrom = point()
	local shadowTo = point()
	local dronePos = point()
	local droneVel = point()
	local abilities = {
		agent = agent,
		charges = charges,
		owned = owned,
		regained = regained,
		kills = kills,
		points = points,
		need = need,
		held = held,
		readyFrom = readyFrom,
		readyUntil = readyUntil,
		liftUntil = liftUntil,
		dashUntil = dashUntil,
		dashX = dashX,
		dashZ = dashZ,
		storm = storm,
		holding = holding,
		steering = steering,
		steerUntil = steerUntil,
		backUntil = backUntil,
		mark = mark,
		markYaw = markYaw,
		markGrounded = bit32.band(markFlags, 1) ~= 0,
		markCrouched = bit32.band(markFlags, 2) ~= 0,
		returnAt = returnAt,
		turn = turn,
		turning = bit32.band(markFlags, 4) ~= 0,
		fixed = fixed,
		floatUntil = floatUntil,
		heldUntil = heldUntil,
		reach = reach,
		stepAt = stepAt,
		stepTo = stepTo,
		shadowAt = shadowAt,
		shadowFrom = shadowFrom,
		shadowTo = shadowTo,
		drawFrom = drawFrom,
		letDown = bit32.band(markFlags, 8) ~= 0,
		altDown = bit32.band(markFlags, 16) ~= 0,
		bounces = bounces,
		furyUntil = furyUntil,
		chargeAt = chargeAt,
		kickFrom = kickFrom,
		kickYaw = kickYaw,
		droneFrom = droneFrom,
		landAt = landAt,
		dronePos = dronePos,
		droneVel = droneVel,
		dartAt = dartAt,
		bodyYaw = bodyYaw,
		bodyPitch = bodyPitch,
		dismissUntil = dismissUntil,
		empressAt = empressAt,
	}

	local tagUntilTick = r32(c)
	local tagMultiplier = rf64(c)
	return seq, {
		movement = movement,
		weapons = weapons,
		spike = spike,
		abilities = abilities,
		tagUntilTick = tagUntilTick,
		tagMultiplier = tagMultiplier,
	}
end

-- Snapshots -----------------------------------------------------------------

export type Pose = {
	id: number,
	position: vector, -- metres, feet (a drone's middle, system 47)
	yaw: number,
	pitch: number,
	crouchAlpha: number,
	grounded: boolean,
	alive: boolean,
	-- For the sound others hear (system 8): walking or crouching, so their
	-- steps make no sound; reloading; and the weapon in hand, by its
	-- WeaponConfig index (0 for none).
	quiet: boolean,
	reloading: boolean,
	weapon: number,
	-- Planting (1) or defusing (2) the spike, taking an Ultimate Orb (3,
	-- system 49), or none (0), for the sounds and the look (system 12).
	channel: number,
	-- Gliding (Jett's Drift, system 20), for the sound and the look.
	gliding: boolean,
	-- A Shade (Omen's From the Shadows, system 43), for the look, and so
	-- nobody's drawn sliding to where it took him.
	shade: boolean?,
}

local SNAP_HEADER = 8 + 2 + 1 -- server time, sequence number, pose count
local SNAP_ENTRY = 4 + 12 + 2 + 2 + 1 + 1 + 1
PlayerCodec.SNAPSHOT_HEADER = SNAP_HEADER
PlayerCodec.SNAPSHOT_ENTRY = SNAP_ENTRY

-- Entity ids: players use UserId mod 2^32; dummies use DUMMY_BASE + n, for n
-- up to DUMMY_LIMIT. The range is bounded because Studio's local test
-- players have UserIds -1, -2, ..., which land at the very top of it. Sova's
-- Owl Drones (system 47) use DRONE_BASE + n the same way, below the
-- dummies': in the snapshots, but no player's or dummy's. Bots (system 60)
-- use BOT_BASE + n, below the drones'; in the rules a bot goes by its
-- entity id less 2^32 (botRuleId), a negative number below any Studio test
-- player's UserId, which entityIdForUser turns back into its entity id as
-- it does a player's UserId.
PlayerCodec.DUMMY_BASE = 4294901760 -- 0xFFFF0000
PlayerCodec.DUMMY_LIMIT = 4096
PlayerCodec.DRONE_BASE = 4294836224 -- 0xFFFE0000
PlayerCodec.DRONE_LIMIT = 4096
PlayerCodec.BOT_BASE = 4294770688 -- 0xFFFD0000
PlayerCodec.BOT_LIMIT = 4096

function PlayerCodec.entityIdForUser(userId: number): number
	return userId % 2 ^ 32
end

function PlayerCodec.isDummy(id: number): boolean
	return id > PlayerCodec.DUMMY_BASE and id <= PlayerCodec.DUMMY_BASE + PlayerCodec.DUMMY_LIMIT
end

function PlayerCodec.isDrone(id: number): boolean
	return id > PlayerCodec.DRONE_BASE and id <= PlayerCodec.DRONE_BASE + PlayerCodec.DRONE_LIMIT
end

-- Whether an entity id is a bot's.
function PlayerCodec.isBot(id: number): boolean
	return id > PlayerCodec.BOT_BASE and id <= PlayerCodec.BOT_BASE + PlayerCodec.BOT_LIMIT
end

-- Bot `n`'s id in the rules (1 up to BOT_LIMIT).
function PlayerCodec.botRuleId(n: number): number
	return PlayerCodec.BOT_BASE + n - 2 ^ 32
end

-- Whether an id in the rules is a bot's.
function PlayerCodec.isBotRule(id: number): boolean
	return id < 0 and PlayerCodec.isBot(PlayerCodec.entityIdForUser(id))
end

-- Applies the same float32 rounding a pose gets on the wire, so the server's
-- rewind history holds exactly what clients interpolate.
function PlayerCodec.quantizePose(pose: Pose): Pose
	local b = buffer.create(12)
	buffer.writef32(b, 0, pose.position.x)
	buffer.writef32(b, 4, pose.position.y)
	buffer.writef32(b, 8, pose.position.z)
	return {
		id = pose.id,
		position = vector.create(buffer.readf32(b, 0), buffer.readf32(b, 4), buffer.readf32(b, 8)),
		yaw = unpackAngle(packAngle(pose.yaw)),
		pitch = packPitch(pose.pitch) / 10000,
		crouchAlpha = math.floor(math.clamp(pose.crouchAlpha, 0, 1) * 255 + 0.5) / 255,
		grounded = pose.grounded,
		alive = pose.alive,
		quiet = pose.quiet,
		reloading = pose.reloading,
		weapon = pose.weapon,
		channel = pose.channel,
		gliding = pose.gliding,
		shade = pose.shade,
	}
end

-- `seq` counts snapshots (mod 65536) so clients can measure loss; every
-- packet of a snapshot split over several carries the same one.
function PlayerCodec.encodeSnapshot(serverTime: number, poses: { Pose }, seq: number?): buffer
	local c: Cursor = { b = buffer.create(SNAP_HEADER + SNAP_ENTRY * #poses), o = 0 }
	wf64(c, serverTime)
	w16(c, (seq or 0) % 65536)
	w8(c, #poses)
	for _, pose in poses do
		w32(c, pose.id)
		wf32(c, pose.position.x)
		wf32(c, pose.position.y)
		wf32(c, pose.position.z)
		w16(c, packAngle(pose.yaw))
		wi16(c, packPitch(pose.pitch))
		w8(c, math.floor(math.clamp(pose.crouchAlpha, 0, 1) * 255 + 0.5))
		w8(
			c,
			(if pose.grounded then 1 else 0)
				+ (if pose.alive then 2 else 0)
				+ (if pose.quiet then 4 else 0)
				+ (if pose.reloading then 8 else 0)
				+ 16 * math.clamp(pose.channel, 0, 3)
				+ (if pose.gliding then 64 else 0)
				+ (if pose.shade then 128 else 0)
		)
		w8(c, pose.weapon)
	end
	return c.b
end

-- Returns the server time, the poses and the sequence number.
function PlayerCodec.decodeSnapshot(b: buffer): (number, { Pose }, number)
	local c: Cursor = { b = b, o = 0 }
	local serverTime = rf64(c)
	local seq = r16(c)
	local count = r8(c)
	local poses = table.create(count)
	for _ = 1, count do
		local id = r32(c)
		local x = rf32(c)
		local y = rf32(c)
		local z = rf32(c)
		local position = vector.create(x, y, z)
		local yaw = unpackAngle(r16(c))
		local pitch = ri16(c) / 10000
		local crouchAlpha = r8(c) / 255
		local flags = r8(c)
		local weapon = r8(c)
		table.insert(poses, {
			id = id,
			position = position,
			yaw = yaw,
			pitch = pitch,
			crouchAlpha = crouchAlpha,
			grounded = bit32.band(flags, 1) ~= 0,
			alive = bit32.band(flags, 2) ~= 0,
			quiet = bit32.band(flags, 4) ~= 0,
			reloading = bit32.band(flags, 8) ~= 0,
			weapon = weapon,
			channel = bit32.extract(flags, 4, 2),
			gliding = bit32.band(flags, 64) ~= 0,
			shade = bit32.band(flags, 128) ~= 0,
		})
	end
	return serverTime, poses, seq
end

-- Unreliable remotes cap payloads near 900 bytes.
PlayerCodec.MAX_POSES_PER_SNAPSHOT = (900 - SNAP_HEADER - 16) // SNAP_ENTRY

return PlayerCodec
