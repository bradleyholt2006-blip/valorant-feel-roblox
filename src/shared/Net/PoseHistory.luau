--!strict
-- Timestamped pose history for one entity, and the one interpolation rule
-- remote entities are drawn with.
--
-- The client keeps one per entity from the snapshots it receives; the server
-- keeps the same from the snapshots it sends (LagCompensation). Both sample
-- with this code, so a rewind rebuilds exactly the pose the shooter's screen
-- showed, as long as the shooter received the same snapshots.

local PlayerCodec = require("./PlayerCodec")

export type Sample = { time: number, pose: PlayerCodec.Pose }

export type History = {
	samples: { Sample }, -- oldest first, strictly increasing times
	capacity: number,
}

-- A pose at a time. `from` and `to` are the times of the snapshots blended
-- (equal when one snapshot is used as it is); `held` means the time was past
-- the newest snapshot, so the newest pose is held rather than guessed.
export type Lookup = {
	pose: PlayerCodec.Pose,
	from: number,
	to: number,
	held: boolean,
}

local PoseHistory = {}

-- A gap longer than this means the entity was gone (dead, or out of the
-- snapshots) and came back. Its old poses are dropped, so it never slides
-- from where it died to where it respawned.
PoseHistory.MAX_GAP = 0.25

function PoseHistory.new(capacity: number?): History
	return { samples = {}, capacity = capacity or 64 }
end

-- Adds a snapshot pose. Ignored (returns false) unless it is newer than the
-- newest one, as when unreliable packets arrive out of order.
function PoseHistory.push(h: History, time: number, pose: PlayerCodec.Pose): boolean
	local samples = h.samples
	local last = samples[#samples]
	if last then
		if time <= last.time then
			return false
		end
		if time - last.time > PoseHistory.MAX_GAP then
			table.clear(samples)
		end
	end
	table.insert(samples, { time = time, pose = pose })
	if #samples > h.capacity then
		table.remove(samples, 1)
	end
	return true
end

function PoseHistory.newest(h: History): Sample?
	return h.samples[#h.samples]
end

local function lerpAngle(a: number, b: number, t: number): number
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * t
end

local function blend(a: PlayerCodec.Pose, b: PlayerCodec.Pose, t: number): PlayerCodec.Pose
	return {
		id = b.id,
		position = a.position + (b.position - a.position) * t,
		yaw = lerpAngle(a.yaw, b.yaw, t),
		pitch = a.pitch + (b.pitch - a.pitch) * t,
		crouchAlpha = a.crouchAlpha + (b.crouchAlpha - a.crouchAlpha) * t,
		grounded = b.grounded,
		alive = b.alive,
		quiet = b.quiet,
		reloading = b.reloading,
		weapon = b.weapon,
		channel = b.channel,
		gliding = b.gliding,
	}
end

-- The pose at `time`: blended between the snapshots either side, the oldest
-- one before the history starts, the newest one held after it ends.
function PoseHistory.sample(h: History, time: number): Lookup?
	local samples = h.samples
	local n = #samples
	if n == 0 then
		return nil
	end
	local first = samples[1]
	if time <= first.time then
		return { pose = first.pose, from = first.time, to = first.time, held = false }
	end
	local last = samples[n]
	if time >= last.time then
		return { pose = last.pose, from = last.time, to = last.time, held = time > last.time }
	end
	for i = n - 1, 1, -1 do
		local a = samples[i]
		if time >= a.time then
			local b = samples[i + 1]
			return { pose = blend(a.pose, b.pose, (time - a.time) / (b.time - a.time)), from = a.time, to = b.time, held = false }
		end
	end
	return nil
end

return PoseHistory
