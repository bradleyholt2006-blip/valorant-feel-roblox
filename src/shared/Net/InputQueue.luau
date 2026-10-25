--!strict
-- The server's queue of one player's inputs, and the budget that decides when
-- each may run.
--
-- Tokens refill at the tick rate, so a client can't simulate faster than real
-- time, and up to MAX_BURST of them bank while the queue is empty, so the
-- inputs in a late packet still run as soon as it arrives. Inputs arrive at
-- the rate tokens do, though, so a backlog bigger than the bank (a server
-- stall, or a burst of packets later than 125 ms) would never shrink: the
-- player would stay that many ticks behind, and every later shot would rewind
-- that much further. So when the queue has ended every frame above
-- DRAIN_TARGET for DRAIN_DELAY, one more input a frame runs on a catch-up
-- allowance. It refills at only CATCH_UP_RATE, so no client can use it to run
-- faster than real time for long.

local MovementConfig = require("../Movement/MovementConfig")

local TICK_RATE = MovementConfig.TickRate.value

local InputQueue = {}

InputQueue.MAX_BURST = 16 -- ticks a client may bank while its queue is empty (125 ms)
InputQueue.MAX_QUEUE = 24 -- inputs; beyond this the oldest are dropped (~190 ms)
InputQueue.DRAIN_TARGET = 1 -- inputs a frame may end with without counting as a backlog
InputQueue.DRAIN_DELAY = 0.25 -- seconds a backlog must stand before it is drained
InputQueue.CATCH_UP_MAX = 24 -- extra ticks a drain can run before the allowance is spent
InputQueue.CATCH_UP_RATE = 1 -- extra ticks a second the allowance refills (0.8% of real time)
-- Seqs from the last input a life ran to the first of the next life. The
-- client keeps sending for the old life until the new character reaches it,
-- seconds at most, far fewer than this, so when the server starts a life
-- while the player is alive (a round restart), the old life's inputs still
-- on their way all fall below the new start and are dropped.
InputQueue.LIFE_GAP = 2 ^ 16

export type Queue<T> = {
	inputs: { T },
	tokens: number,
	catchUp: number,
	standing: number, -- seconds the queue has ended every frame above DRAIN_TARGET
	extraTaken: boolean, -- this frame's catch-up input has run
}

function InputQueue.new<T>(): Queue<T>
	return { inputs = {}, tokens = 0, catchUp = InputQueue.CATCH_UP_MAX, standing = 0, extraTaken = false }
end

-- Queues an input. Returns the oldest one if that made the queue too long and
-- it was dropped.
function InputQueue.push<T>(q: Queue<T>, input: T): T?
	table.insert(q.inputs, input)
	if #q.inputs > InputQueue.MAX_QUEUE then
		return table.remove(q.inputs, 1)
	end
	return nil
end

-- Starts a server frame dt seconds after the last.
function InputQueue.refill<T>(q: Queue<T>, dt: number)
	q.tokens = math.min(q.tokens + dt * TICK_RATE, InputQueue.MAX_BURST)
	q.catchUp = math.min(q.catchUp + dt * InputQueue.CATCH_UP_RATE, InputQueue.CATCH_UP_MAX)
	q.extraTaken = false
end

-- The next input to run this frame, or nil if there is none or the budget
-- doesn't allow another.
function InputQueue.take<T>(q: Queue<T>): T?
	if #q.inputs == 0 then
		return nil
	end
	if q.tokens >= 1 then
		q.tokens -= 1
	elseif q.standing >= InputQueue.DRAIN_DELAY and not q.extraTaken and q.catchUp >= 1 then
		q.catchUp -= 1
		q.extraTaken = true
	else
		return nil
	end
	return table.remove(q.inputs, 1)
end

-- Ends a server frame of dt seconds, after its inputs have run.
function InputQueue.endFrame<T>(q: Queue<T>, dt: number)
	if #q.inputs > InputQueue.DRAIN_TARGET then
		q.standing += dt
	else
		q.standing = 0
	end
end

-- Forgets the waiting inputs (the player died).
function InputQueue.clear<T>(q: Queue<T>)
	table.clear(q.inputs)
	q.standing = 0
end

return InputQueue
