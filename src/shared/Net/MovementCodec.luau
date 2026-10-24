--!strict
-- Binary packing for movement traffic. Buffers keep remote payloads small and
-- let us send 128 Hz input without hitting remote throughput limits.
--
--   Input (client -> server, reliable):   10 bytes per tick
--   Ack   (server -> owner, unreliable):  full authoritative state at a seq
--   Snapshot (server -> all, unreliable): pose of every character at a server time

local MovementConfig = require(script.Parent.Parent.Movement.MovementConfig)

local MovementCodec = {}

-- Stable weapon <-> byte mapping.
local weaponIds: { string } = {}
for id in MovementConfig.Weapons do
	table.insert(weaponIds, id)
end
table.sort(weaponIds)
local weaponIndex: { [string]: number } = {}
for i, id in weaponIds do
	weaponIndex[id] = i
end
MovementCodec.weaponIds = weaponIds

local TAU = 2 * math.pi
local INPUT_SIZE = 10

local function packAngle(yaw: number): number
	return math.floor(((yaw % TAU) / TAU) * 65536 + 0.5) % 65536
end

local function unpackAngle(v: number): number
	return v / 65536 * TAU
end

-- Yaw is quantised to 1/65536 of a turn. The client quantises its own copy the
-- same way before simulating so client and server see identical inputs.
MovementCodec.quantizeYaw = function(yaw: number): number
	return unpackAngle(packAngle(yaw))
end

MovementCodec.quantizePitch = function(pitch: number): number
	return math.clamp(math.floor(pitch * 10000 + 0.5), -32767, 32767) / 10000
end

export type WireInput = {
	seq: number,
	buttons: number,
	yaw: number,
	pitch: number,
	weapon: string,
}

function MovementCodec.encodeInputs(inputs: { WireInput }, first: number, last: number): buffer
	local b = buffer.create((last - first + 1) * INPUT_SIZE)
	local o = 0
	for i = first, last do
		local input = inputs[i]
		buffer.writeu32(b, o, input.seq)
		buffer.writeu8(b, o + 4, input.buttons)
		buffer.writeu8(b, o + 5, weaponIndex[input.weapon] or 1)
		buffer.writeu16(b, o + 6, packAngle(input.yaw))
		buffer.writei16(b, o + 8, math.clamp(math.floor(input.pitch * 10000 + 0.5), -32767, 32767))
		o += INPUT_SIZE
	end
	return b
end

-- Returns nil for malformed payloads (wrong type or size) so the server can drop them.
function MovementCodec.decodeInputs(b: any): { WireInput }?
	if typeof(b) ~= "buffer" then
		return nil
	end
	local len = buffer.len(b)
	if len == 0 or len % INPUT_SIZE ~= 0 or len > INPUT_SIZE * 256 then
		return nil
	end
	local out = table.create(len // INPUT_SIZE)
	for o = 0, len - 1, INPUT_SIZE do
		local weapon = weaponIds[buffer.readu8(b, o + 5)]
		if weapon == nil then
			return nil
		end
		table.insert(out, {
			seq = buffer.readu32(b, o),
			buttons = bit32.band(buffer.readu8(b, o + 4), 127),
			weapon = weapon,
			yaw = unpackAngle(buffer.readu16(b, o + 6)),
			pitch = buffer.readi16(b, o + 8) / 10000,
		})
	end
	return out
end

-- Ack: everything MovementSim needs to resume from this state.
local ACK_SIZE = 4 + 4 + 8 * 6 + 1 + 8 + 4 + 4 + 1

function MovementCodec.encodeAck(seq: number, s: any): buffer
	local b = buffer.create(ACK_SIZE)
	buffer.writeu32(b, 0, seq)
	buffer.writeu32(b, 4, s.tick)
	buffer.writef64(b, 8, s.position.x)
	buffer.writef64(b, 16, s.position.y)
	buffer.writef64(b, 24, s.position.z)
	buffer.writef64(b, 32, s.velocity.x)
	buffer.writef64(b, 40, s.velocity.y)
	buffer.writef64(b, 48, s.velocity.z)
	local flags = (if s.grounded then 1 else 0) + (if s.crouched then 2 else 0) + (if s.jumpLatched then 4 else 0)
	buffer.writeu8(b, 56, flags)
	buffer.writef64(b, 57, s.crouchAlpha)
	buffer.writei32(b, 65, math.clamp(s.tick - s.lastJumpTick, 0, 2 ^ 31 - 1))
	buffer.writei32(b, 69, math.clamp(s.tick - s.lastLandTick, 0, 2 ^ 31 - 1))
	buffer.writeu8(b, 73, weaponIndex[s.weapon] or 1)
	return b
end

function MovementCodec.decodeAck(b: buffer): (number, any)
	local tick = buffer.readu32(b, 4)
	local flags = buffer.readu8(b, 56)
	return buffer.readu32(b, 0),
		{
			tick = tick,
			position = vector.create(buffer.readf64(b, 8), buffer.readf64(b, 16), buffer.readf64(b, 24)),
			velocity = vector.create(buffer.readf64(b, 32), buffer.readf64(b, 40), buffer.readf64(b, 48)),
			grounded = bit32.band(flags, 1) ~= 0,
			crouched = bit32.band(flags, 2) ~= 0,
			jumpLatched = bit32.band(flags, 4) ~= 0,
			groundNormal = vector.create(0, 1, 0),
			crouchAlpha = buffer.readf64(b, 57),
			lastJumpTick = tick - buffer.readi32(b, 65),
			lastLandTick = tick - buffer.readi32(b, 69),
			weapon = weaponIds[buffer.readu8(b, 73)] or MovementConfig.DefaultWeapon,
		}
end

-- Snapshot: [f64 serverTime][u8 count] then per character:
-- [u32 userId-slot][f32 x][f32 y][f32 z][u16 yaw][i16 pitch][u8 crouch][u8 flags]
local SNAP_HEADER = 9
local SNAP_ENTRY = 4 + 12 + 2 + 2 + 1 + 1

export type Pose = {
	userId: number,
	position: vector, -- metres, feet
	yaw: number,
	pitch: number,
	crouchAlpha: number,
	grounded: boolean,
}

function MovementCodec.encodeSnapshot(serverTime: number, poses: { Pose }): buffer
	local b = buffer.create(SNAP_HEADER + SNAP_ENTRY * #poses)
	buffer.writef64(b, 0, serverTime)
	buffer.writeu8(b, 8, #poses)
	local o = SNAP_HEADER
	for _, pose in poses do
		buffer.writeu32(b, o, pose.userId % 2 ^ 32)
		buffer.writef32(b, o + 4, pose.position.x)
		buffer.writef32(b, o + 8, pose.position.y)
		buffer.writef32(b, o + 12, pose.position.z)
		buffer.writeu16(b, o + 16, packAngle(pose.yaw))
		buffer.writei16(b, o + 18, math.clamp(math.floor(pose.pitch * 10000 + 0.5), -32767, 32767))
		buffer.writeu8(b, o + 20, math.floor(math.clamp(pose.crouchAlpha, 0, 1) * 255 + 0.5))
		buffer.writeu8(b, o + 21, if pose.grounded then 1 else 0)
		o += SNAP_ENTRY
	end
	return b
end

function MovementCodec.decodeSnapshot(b: buffer): (number, { Pose })
	local count = buffer.readu8(b, 8)
	local poses = table.create(count)
	local o = SNAP_HEADER
	for _ = 1, count do
		table.insert(poses, {
			userId = buffer.readu32(b, o),
			position = vector.create(buffer.readf32(b, o + 4), buffer.readf32(b, o + 8), buffer.readf32(b, o + 12)),
			yaw = unpackAngle(buffer.readu16(b, o + 16)),
			pitch = buffer.readi16(b, o + 18) / 10000,
			crouchAlpha = buffer.readu8(b, o + 20) / 255,
			grounded = buffer.readu8(b, o + 21) ~= 0,
		})
		o += SNAP_ENTRY
	end
	return buffer.readf64(b, 0), poses
end

-- Max characters per snapshot packet (unreliable remotes cap payloads near 900 bytes).
MovementCodec.MAX_POSES_PER_SNAPSHOT = (900 - SNAP_HEADER - 16) // SNAP_ENTRY

return MovementCodec
