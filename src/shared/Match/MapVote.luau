--!strict
-- The vote for the next map (system 22), after a match's victory screen, as
-- plain state the offline tests can play, as Counter-Strike's end of match
-- has it:
--   * a few maps to pick from, chosen at random from those the mode plays
--     on, the one just played among them like any other
--   * everyone in the server has one vote, and can change it until the time
--     is up; someone who leaves takes their vote with them
--   * the map with the most votes is played next. A tie is settled at
--     random between the maps tied for the most, and with no votes at all
--     the next map is any of them, at random, as Counter-Strike picks the
--     next map at random when its vote is off
--
-- No Roblox APIs here: the modes say who votes and when the time is up, and
-- pass in what to roll the dice with.

export type Vote = {
	options: { string }, -- the maps to pick from, in the order they're shown
	picks: { [number]: number }, -- by voter: the option they picked
}

-- A whole number from 1 to n, at random (math.random's, unless a test has
-- its own).
export type Roll = (n: number) -> number

local MapVote = {}

-- Up to `count` of the pool's maps, chosen at random, shown in the pool's
-- order.
function MapVote.new(pool: { string }, count: number, roll: Roll): Vote
	local left = table.clone(pool)
	local chosen: { [string]: boolean } = {}
	for _ = 1, math.min(count, #pool) do
		chosen[table.remove(left, roll(#left)) :: string] = true
	end
	local options = {}
	for _, key in pool do
		if chosen[key] then
			table.insert(options, key)
		end
	end
	return { options = options, picks = {} }
end

-- Someone votes for an option, by its number in the list, or changes their
-- vote. Returns whether anything changed: not for an option that isn't
-- there, or the one they'd already picked.
function MapVote.cast(v: Vote, voter: number, option: number): boolean
	if option ~= math.floor(option) or option < 1 or option > #v.options or v.picks[voter] == option then
		return false
	end
	v.picks[voter] = option
	return true
end

-- Someone has left: their vote goes with them. Returns whether they had one.
function MapVote.drop(v: Vote, voter: number): boolean
	if v.picks[voter] == nil then
		return false
	end
	v.picks[voter] = nil
	return true
end

-- The votes for each option, in the list's order.
function MapVote.tally(v: Vote): { number }
	local out = table.create(#v.options, 0)
	for _, option in v.picks do
		out[option] += 1
	end
	return out
end

-- The map to play next: the most votes, and a tie (with no votes, all of
-- them) settled at random.
function MapVote.winner(v: Vote, roll: Roll): string
	local tally = MapVote.tally(v)
	local most = 0
	for _, n in tally do
		most = math.max(most, n)
	end
	local top = {}
	for i, n in tally do
		if n == most then
			table.insert(top, v.options[i])
		end
	end
	return top[roll(#top)]
end

return MapVote
