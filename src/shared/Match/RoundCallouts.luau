--!strict
-- The round-end callouts (system 56): as a round of Skirmish or the spike
-- rounds is won in a way worth naming, the winners' banner names it in
-- place of ROUND WON, as the reference's does (its announcer says it too):
--   * ACE: one of the winners killed every enemy who started the round
--     ('When one player gets five or six kills in a single round', ONE
--     Esports; a sixth being of an enemy brought back)
--   * TEAM ACE: each of the winners killed an enemy ('When each player from
--     the winning team scores a kill against the opposing team', ONE
--     Esports), even one who died after ('Players may die after getting
--     their one kill and still receive the Team Ace title', win.gg); against
--     fewer enemies than winners, as many of them as there were enemies
--     ('four players in your team must kill the four enemy players', of an
--     enemy side one short, TheGlobalGaming)
--   * FLAWLESS: none of the winners died ('A round where no one from the
--     winning team died', ONE Esports), which the losers are shown as well
--     (FPS Aim Lab)
--   * CLUTCH: the winners were down to their last, against two or more
--     (FPS Aim Lab: a win from one against several)
--   * THRIFTY: the winners' loadouts were worth, on average, 2500 credits or
--     more less than the losers' ('at least an average of 2500 credits
--     less', GINX), in the spike rounds alone, where loadouts are bought
-- A round has one at most, the first of these that holds, in FPS Aim Lab's
-- order: an ace or a team ace, then a flawless, a clutch and thrifty. A
-- round won with none is ROUND WON, and the losers' ROUND LOST.
--
-- Ours: an ace needs two or more on the losing side, a flawless two or more
-- on the winning side, and a team ace two or more on each (Params.least),
-- or with one a side every round won by a kill would be all three; and a
-- loadout is worth its guns' and its shield's prices as the round goes live
-- (worth), its abilities left out.
--
-- Plain state the offline tests can play: the server keeps the round under
-- way (CalloutServer, told by Arena when it goes live and ends) and the
-- arena's model carries its callout to clients, whose banner (ArenaHud)
-- shows it. No Roblox APIs here.

local Shop = require("../Weapons/Shop")

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

export type Callout = "ace" | "teamAce" | "flawless" | "clutch" | "thrifty"

-- A round from when it goes live, by player.
export type Round = {
	sides: { [number]: number }, -- everyone who started it, on their side
	alive: { [number]: boolean },
	died: { [number]: boolean }, -- whoever's died in it, brought back or not
	kills: { [number]: { [number]: boolean } }, -- by killer: the enemies they've killed in it
	last: { [number]: boolean }, -- by side: whether it's been down to its last against `odds` or more
	worth: { [number]: number }?, -- what each one's loadout was worth as it went live; nil with nothing bought
}

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local RoundCallouts = {}

RoundCallouts.Params = {
	least = p(
		2,
		"estimate",
		"Players a side needs, at least: the losers for an ace, the winners for a flawless, and each side for a team ace; with one a side, every round won by a kill would be all three (ours)"
	),
	odds = p(
		2,
		"community",
		"Enemies alive, at least, as the winners are down to their last, for a clutch: one against several (FPS Aim Lab)"
	),
	thrifty = p(
		2500,
		"community",
		"Credits, at least, by which the winners' loadouts are worth less on average than the losers': 'at least an average of 2500 credits less' (GINX)"
	),
}

local P = RoundCallouts.Params

-- What the banner says for each.
RoundCallouts.TITLES = {
	ace = "ACE",
	teamAce = "TEAM ACE",
	flawless = "FLAWLESS",
	clutch = "CLUTCH",
	thrifty = "THRIFTY",
} :: { [string]: string }

local function aliveOn(r: Round, side: number): number
	local n = 0
	for id, on in r.sides do
		if on == side and r.alive[id] then
			n += 1
		end
	end
	return n
end

-- Notes a side that's down to its last against `odds` or more.
local function lastStand(r: Round)
	for side = 1, 2 do
		if aliveOn(r, side) == 1 and aliveOn(r, 3 - side) >= P.odds.value then
			r.last[side] = true
		end
	end
end

-- A round goes live with everyone in `sides` (by player, their side) alive,
-- and where loadouts are bought, what each one's is worth (`worth`).
function RoundCallouts.begin(sides: { [number]: number }, worth: { [number]: number }?): Round
	local r: Round = { sides = table.clone(sides), alive = {}, died = {}, kills = {}, last = {}, worth = worth }
	for id in sides do
		r.alive[id] = true
	end
	lastStand(r)
	return r
end

-- Someone's died, killed by `killer` if anyone: a kill of theirs if they're
-- an enemy who started the round.
function RoundCallouts.died(r: Round, id: number, killer: number?)
	local side = r.sides[id]
	if side == nil or not r.alive[id] then
		return
	end
	r.alive[id] = false
	r.died[id] = true
	local by = if killer then r.sides[killer] else nil
	if killer and by and by ~= side then
		local killed = r.kills[killer]
		if not killed then
			killed = {}
			r.kills[killer] = killed
		end
		killed[id] = true
	end
	lastStand(r)
end

-- Someone brought back by Sage's Resurrection (system 39).
function RoundCallouts.revived(r: Round, id: number)
	if r.sides[id] ~= nil and not r.alive[id] then
		r.alive[id] = true
		lastStand(r)
	end
end

-- Someone's left the game: out of the round, though they didn't die in it.
function RoundCallouts.left(r: Round, id: number)
	if r.sides[id] ~= nil and r.alive[id] then
		r.alive[id] = false
		lastStand(r)
	end
end

local function sideOf(r: Round, side: number): { number }
	local out = {}
	for id, on in r.sides do
		if on == side then
			table.insert(out, id)
		end
	end
	return out
end

local function average(r: Round, ids: { number }): number
	local worth = r.worth or {}
	local sum = 0
	for _, id in ids do
		sum += worth[id] or 0
	end
	return sum / math.max(#ids, 1)
end

-- The round's callout as `winner`'s side wins it: the first that holds, or
-- nil for none.
function RoundCallouts.decide(r: Round, winner: number): Callout?
	local winners, losers = sideOf(r, winner), sideOf(r, 3 - winner)
	local least = P.least.value
	if #losers >= least then
		for _, id in winners do
			local killed = r.kills[id] or {}
			local all = true
			for _, enemy in losers do
				all = all and killed[enemy] == true
			end
			if all then
				return "ace"
			end
		end
	end
	-- A team ace's killers: each of the winners, or against fewer, as many
	-- as there were enemies.
	local killers, lived = 0, true
	for _, id in winners do
		if next(r.kills[id] or {}) ~= nil then
			killers += 1
		end
		lived = lived and not r.died[id]
	end
	local needed = math.min(#winners, #losers)
	if needed >= least and killers >= needed then
		return "teamAce"
	elseif #winners >= least and lived then
		return "flawless"
	elseif r.last[winner] then
		return "clutch"
	elseif r.worth and #winners > 0 and #losers > 0 and average(r, losers) - average(r, winners) >= P.thrifty.value then
		return "thrifty"
	end
	return nil
end

-- What a side's banner says as the round ends with `callout` (nil for
-- none): to the winners the callout, or ROUND WON; to the losers ROUND
-- LOST, or the winners' flawless, which they're shown too.
function RoundCallouts.title(callout: string?, won: boolean): string
	local word = if callout then RoundCallouts.TITLES[callout] else nil
	if won then
		return word or "ROUND WON"
	end
	return if callout == "flawless" and word then word else "ROUND LOST"
end

-- What a loadout is worth: the price of each of its items (a gun or a
-- shield, Shop's; "" for an empty slot), and nothing for what isn't sold.
function RoundCallouts.worth(items: { string }): number
	local sum = 0
	for _, id in items do
		local item = Shop.item(id)
		sum += if item then item.price else 0
	end
	return sum
end

return RoundCallouts
