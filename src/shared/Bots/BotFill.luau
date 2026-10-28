--!strict
-- How many bots a match has, and which one leaves (system 60): the
-- Counter-Strike server's bot quota in its fill mode, 'The server is filled
-- with bots until there are at least bot_quota players on the server
-- (humans + bots)' (bot_quota_mode, the Valve Developer Community), each
-- mode's quota BotConfig's. Bots play only while a player does: with nobody
-- in what's played, there are none, and the match waits for a player as it
-- always has.
--
-- A player joining takes a bot's place: while there are more than the
-- quota, bots leave, one waiting for a place or one that's down at any
-- time, and otherwise only while nothing's at stake (waiting for the
-- match, a buy phase, Team Deathmatch's pre-game, between rounds and
-- after the match), so nobody vanishes mid-fight. In the modes that
-- respawn, one leaves the next time it's down. The one to leave is on the
-- side with the most bots, so a player waiting in line for a place gets
-- it on the side with fewer players; of those, the last to join.
--
-- No Roblox APIs here: the arena says who's playing.

local BotFill = {}

-- A bot in the match: its id in the rules, its side (nil while it waits
-- for a place), whether it's alive, and when it joined (a count).
export type Seat = { id: number, side: number?, alive: boolean, order: number }

-- The phases in which nothing's at stake.
local CALM: { [string]: boolean } = {
	waiting = true,
	buy = true,
	pregame = true,
	roundOver = true,
	matchOver = true,
	vote = true,
}

-- How many bots fill a match that `players` players are in (on a side or
-- in line), up to `quota` in all.
function BotFill.wanted(quota: number, players: number): number
	if players <= 0 then
		return 0
	end
	return math.max(quota - players, 0)
end

-- Whether nothing's at stake in `phase`, so anyone can leave.
function BotFill.calm(phase: string?): boolean
	return phase == nil or CALM[phase] == true
end

-- What changes: how many bots join, and which leave, by their ids, with
-- `bots` in the match and `players` players, in `phase`.
function BotFill.plan(quota: number, players: number, bots: { Seat }, phase: string?): (number, { number })
	local want = BotFill.wanted(quota, players)
	if #bots < want then
		return want - #bots, {}
	end
	local extra = #bots - want
	if extra == 0 then
		return 0, {}
	end
	local calm = BotFill.calm(phase)
	-- Bots by side, to leave from the side with the most.
	local count: { [number]: number } = {}
	for _, b in bots do
		local side = b.side or 0
		count[side] = (count[side] or 0) + 1
	end
	local left: { [number]: boolean } = {}
	local out: { number } = {}
	for _ = 1, extra do
		local best: Seat? = nil
		for _, b in bots do
			if left[b.id] or not (calm or not b.alive or b.side == nil) then
				continue
			end
			if best == nil then
				best = b
				continue
			end
			local current = best :: Seat
			local mine, theirs = count[b.side or 0], count[current.side or 0]
			-- One waiting for a place first, then one down, then the side
			-- with the most bots, then the last to join.
			local key = if b.side == nil then 3 elseif not b.alive then 2 else 1
			local bestKey = if current.side == nil then 3 elseif not current.alive then 2 else 1
			if key ~= bestKey then
				if key > bestKey then
					best = b
				end
			elseif mine ~= theirs then
				if mine > theirs then
					best = b
				end
			elseif b.order > current.order then
				best = b
			end
		end
		local chosen = best
		if not chosen then
			break
		end
		left[chosen.id] = true
		count[chosen.side or 0] -= 1
		table.insert(out, chosen.id)
	end
	return 0, out
end

return BotFill
