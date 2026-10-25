--!strict
-- Which server frames send a snapshot (Replication), so that clients get
-- NetConfig.SNAPSHOT_RATE a second whatever rate the server steps at.
--
-- A Roblox server steps at 60 Hz, and then every frame sends, however
-- unevenly the frames come. Studio's server steps three or four times as
-- fast (217 Hz, measured), where a minimum spacing between sends still let
-- through 72 a second. So a server stepping faster than the rate earns a
-- share of a send each frame and sends on the frame nearest to a whole one.
-- The share left over after a send is kept to half a frame either way, so a
-- run of short or long frames can't build up into a burst or a gap.

local SendSchedule = {}

-- A frame at least this share of a send interval long always sends.
local FULL_FRAME = 0.75

export type Schedule = { credit: number }

function SendSchedule.new(): Schedule
	return { credit = 1 }
end

-- A server frame `dt` seconds after the last: whether it sends.
function SendSchedule.step(s: Schedule, dt: number, rate: number): boolean
	local share = dt * rate
	s.credit += share
	if share < FULL_FRAME and s.credit < 1 - share / 2 then
		return false
	end
	s.credit = math.clamp(s.credit - 1, -share / 2, share / 2)
	return true
end

return SendSchedule
