--!strict
-- Rounds played for the spike (system 13): the standard match's rounds,
-- halves, overtime and formats, and the maps they're played on, Outpost,
-- Quarry and Foundry (system 25) and Wharf (system 58): each one every room
-- reachable, no sightline from one spawn into the other, barriers that hold
-- each side in, the defenders nearer the sites, Outpost mirrored left to
-- right, and every number labelled.

local MapPlan = require("../src/shared/Match/MapPlan")
local MatchConfig = require("../src/shared/Match/MatchConfig")
local MatchMap = require("../src/shared/Match/MatchMap")
local MatchRules = require("../src/shared/Match/MatchRules")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local Spike = require("../src/shared/Spike/Spike")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check = H.check

local R = MatchConfig.Rules
local cfg = MovementConfig.resolve()
local DT = 1 / MovementConfig.TickRate.value
local B = PlayerSim.Buttons
local STANDARD = MatchConfig.Formats.standard

local function same(a: { number }, b: { number }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

-- A 1v1 match, player 1 on side 1 and player 2 on side 2, at round 1's
-- buy phase.
local function oneVsOne(format: string?): MatchRules.State
	local s = MatchRules.new(format)
	MatchRules.join(s, 1, 0)
	MatchRules.join(s, 2, 0)
	return s
end

-- When the round under way started, as win() last saw it.
local roundStart = 0

-- Plays the round under way to its end, won by `winner`'s side killing the
-- other side's player, and starts the next.
local function win(s: MatchRules.State, winner: number)
	if s.phase == "buy" then
		MatchRules.step(s, s.phaseEndsAt)
	end
	MatchRules.died(s, if winner == 1 then 2 else 1, s.phaseEndsAt - 50)
	if s.phase == "roundOver" then
		roundStart = s.phaseEndsAt
		MatchRules.step(s, roundStart)
	end
end

H.section("Match tests")

-- Rounds ----------------------------------------------------------------------

do
	local s = MatchRules.new()
	local t = 100
	check("alone, you spawn on side 1 and wait for an opponent", same(MatchRules.join(s, 11, t), { 11 }) and s.phase == "waiting")
	local spawned = MatchRules.join(s, 22, t)
	check("an opponent starts round 1: both spawn", same(spawned, { 11, 22 }) and s.phase == "buy" and s.round == 1)
	check(
		"side 1 attacks the first half, and round 1's buy phase is the long one, behind the barriers",
		s.attackers == 1 and MatchRules.attacking(s, 11) and not MatchRules.attacking(s, 22) and s.phaseEndsAt == t + R.firstBuyTime.value and MatchRules.barriersUp(s)
	)
	check("nobody can plant in the buy phase, and everyone can buy", not MatchRules.canPlant(s) and MatchRules.canPick(s, 11) and MatchRules.canPick(s, 22))
	t += R.firstBuyTime.value
	MatchRules.step(s, t)
	check(
		"then the round is live, with its clock: barriers down, no buying, planting open",
		s.phase == "live" and s.phaseEndsAt == t + R.roundTime.value and not MatchRules.barriersUp(s) and not MatchRules.canPick(s, 11) and MatchRules.canPlant(s)
	)
	MatchRules.step(s, t + R.roundTime.value - 0.01)
	check("the clock runs its whole time", s.phase == "live")
	MatchRules.step(s, t + R.roundTime.value)
	check("run out with no plant, the defenders win", s.phase == "roundOver" and s.roundWinner == 2 and s.reason == "time" and s.score[2] == 1)
	MatchRules.planted(s, t + 200)
	MatchRules.died(s, 22, t + R.roundTime.value + 1)
	check("nothing changes the result after the round's end: a plant, a kill", s.phase == "roundOver" and s.score[1] == 0 and s.score[2] == 1)
	t += R.roundTime.value
	check("the next round waits for the post-round phase", #MatchRules.step(s, t + R.postRoundTime.value - 0.01) == 0)
	spawned = MatchRules.step(s, t + R.postRoundTime.value)
	check(
		"then everyone spawns, dead or alive, for round 2 and its short buy phase",
		same(spawned, { 11, 22 }) and s.round == 2 and s.phase == "buy" and s.phaseEndsAt == t + R.postRoundTime.value + R.buyTime.value
	)
end

do
	local s = oneVsOne()
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.died(s, 2, 60)
	check("killing every defender wins the round for the attackers", s.roundWinner == 1 and s.reason == "eliminated")

	s = oneVsOne()
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.died(s, 1, 60)
	check("killing every attacker before a plant wins it for the defenders", s.roundWinner == 2 and s.reason == "eliminated")

	s = oneVsOne()
	MatchRules.step(s, s.phaseEndsAt)
	local detonateAt = 80 + Spike.Params.detonateTime.value
	MatchRules.planted(s, detonateAt)
	check("planted, the spike's countdown replaces the round's clock", s.phase == "planted" and s.phaseEndsAt == detonateAt and not MatchRules.canPlant(s))
	MatchRules.died(s, 1, 85)
	check("killing every attacker after the plant isn't enough", s.phase == "planted" and s.roundWinner == nil)
	MatchRules.defused(s, 100)
	check("a defuse is", s.phase == "roundOver" and s.roundWinner == 2 and s.reason == "defused")

	s = oneVsOne()
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.planted(s, detonateAt)
	MatchRules.step(s, detonateAt - 0.01)
	check("the spike's 45 s run their course", s.phase == "planted")
	MatchRules.step(s, detonateAt)
	check("then it goes off and the attackers win", s.roundWinner == 1 and s.reason == "detonated")
	MatchRules.defused(s, detonateAt + 0.01)
	check("a defuse too late changes nothing", s.roundWinner == 1 and s.score[1] == 1 and s.score[2] == 0)

	s = oneVsOne()
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.planted(s, detonateAt)
	MatchRules.detonated(s, detonateAt - 0.2)
	check("the spike going off, as the server reports it, wins it for the attackers", s.roundWinner == 1 and s.reason == "detonated")

	s = oneVsOne()
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.planted(s, detonateAt)
	MatchRules.died(s, 2, 90)
	check("killing every defender after the plant wins it for the attackers at once", s.roundWinner == 1 and s.reason == "eliminated")
	MatchRules.defused(s, 91)
	check("and nothing undoes that", s.roundWinner == 1 and s.score[1] == 1)
end

do
	local s = MatchRules.new()
	local t = 0
	for _, id in { 1, 2, 3, 4 } do
		MatchRules.join(s, id, t)
	end
	check(
		"2v2: players alternate sides as they join, each in their own spot",
		same({ MatchRules.sideOf(s, 1) or 0, MatchRules.sideOf(s, 2) or 0, MatchRules.sideOf(s, 3) or 0, MatchRules.sideOf(s, 4) or 0 }, { 1, 2, 1, 2 })
			and same({ MatchRules.spotOf(s, 1) or 0, MatchRules.spotOf(s, 2) or 0, MatchRules.spotOf(s, 3) or 0, MatchRules.spotOf(s, 4) or 0 }, { 1, 1, 2, 2 })
	)
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.died(s, 2, 50)
	check("one defender of two down doesn't end the round", s.phase == "live")
	MatchRules.planted(s, 100)
	MatchRules.leave(s, 4, 60)
	check("the other leaving after the plant ends it: no defenders left", s.roundWinner == 1 and s.reason == "eliminated")
end

do
	-- The halves, in the standard format.
	local s = oneVsOne()
	roundStart = 0
	local half = STANDARD.halfRounds.value
	local attackers, buys, halves, swaps = {}, {}, {}, {}
	for round = 1, 2 * half do
		attackers[round] = s.attackers
		buys[round] = s.phaseEndsAt - roundStart
		if s.round ~= round or s.phase ~= "buy" then
			break
		end
		if MatchRules.startsHalf(s) then
			table.insert(halves, round)
		end
		if MatchRules.lastOfHalf(s) then
			table.insert(swaps, round)
		end
		-- Alternate the winners, to come to 12-12.
		win(s, if round % 2 == 1 then 1 else 2)
	end
	local sidesOk, buysOk = true, true
	for round = 1, 2 * half do
		sidesOk = sidesOk and attackers[round] == (if round <= half then 1 else 2)
		local long = round == 1 or round == half + 1
		buysOk = buysOk and buys[round] == (if long then R.firstBuyTime.value else R.buyTime.value)
	end
	check("side 1 attacks rounds 1-12, side 2 rounds 13-24", sidesOk)
	check("rounds 1 and 13 start the halves, with the long buy phase; the rest have the short one", buysOk and same(halves, { 1, half + 1 }))
	check("the sides swap after round 12", same(swaps, { half }))
	check("12-12 after regulation: a 25th round, sudden death", s.score[1] == half and s.score[2] == half and s.round == 2 * half + 1 and s.phase == "buy")
	check("on the second half's sides, with the long buy phase", s.attackers == 2 and s.phaseEndsAt - roundStart == R.firstBuyTime.value)
	local point = MatchRules.matchPoint(s)
	check("both sides are on match point", point[1] and point[2])
	win(s, 2)
	check("its winner takes the match, 13-12", s.phase == "matchOver" and s.matchWinner == 2 and s.score[2] == 13 and s.score[1] == 12)
	MatchRules.step(s, s.phaseEndsAt) -- to the vote for the next map (system 25)
	local spawned = MatchRules.step(s, s.phaseEndsAt)
	check(
		"then a new match starts at 0-0, side 1 attacking round 1",
		#spawned == 2 and s.score[1] == 0 and s.score[2] == 0 and s.round == 1 and s.attackers == 1 and s.match == 2 and s.matchWinner == nil
	)
end

do
	local s = oneVsOne()
	for _ = 1, 13 do
		win(s, 1)
	end
	check("13 rounds in a row wins it 13-0", s.phase == "matchOver" and s.matchWinner == 1 and s.score[1] == 13 and s.round == 13)
	check("the 13th was on the second half's sides", s.attackers == 2)
end

do
	-- Competitive's overtime: win by two, the sides taking turns.
	local s = oneVsOne("competitive")
	for round = 1, 24 do
		win(s, if round % 2 == 1 then 1 else 2)
	end
	local seen = { s.attackers }
	win(s, 1)
	check("competitive at 13-12 in overtime: not over, a two-round lead is needed", s.phase == "buy" and s.score[1] == 13 and s.score[2] == 12)
	table.insert(seen, s.attackers)
	win(s, 2)
	table.insert(seen, s.attackers)
	win(s, 1)
	table.insert(seen, s.attackers)
	check("overtime rounds alternate who attacks, side 1 first", same(seen, { 1, 2, 1, 2 }), table.concat(seen :: any, ","))
	win(s, 1)
	check("15-13: a two-round lead wins it", s.phase == "matchOver" and s.matchWinner == 1 and s.score[1] == 15 and s.score[2] == 13)
end

do
	-- Swiftplay: halves of 4, first to 5, sudden death at 4-4.
	local s = oneVsOne("swiftplay")
	check("Swiftplay is its own format", s.format.name == "Swiftplay" and s.format.halfRounds.value == 4)
	local attackers = {}
	for round = 1, 8 do
		attackers[round] = s.attackers
		win(s, if round % 2 == 1 then 1 else 2)
	end
	check("side 1 attacks rounds 1-4 and side 2 rounds 5-8", same(attackers, { 1, 1, 1, 1, 2, 2, 2, 2 }))
	check("4-4: round 9, sudden death", s.round == 9 and s.score[1] == 4 and s.score[2] == 4 and s.attackers == 2)
	win(s, 1)
	check("its winner takes the match 5-4", s.phase == "matchOver" and s.matchWinner == 1)
	local fast = oneVsOne("swiftplay")
	for _ = 1, 5 do
		win(fast, 2)
	end
	check("five rounds in a row wins it 5-0", fast.phase == "matchOver" and fast.score[2] == 5)
	check("an unknown format is played as standard", MatchRules.new("nonsense").format.name == "Standard")
end

do
	local s = oneVsOne()
	win(s, 1)
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.leave(s, 2, 500)
	check("your opponent leaving goes back to waiting and keeps the score", s.phase == "waiting" and s.score[1] == 1)
	local spawned = MatchRules.join(s, 3, 600)
	check("a new opponent starts the next round, on the score as it was", same(spawned, { 1, 3 }) and s.round == 3 and s.score[1] == 1)

	local v = MatchRules.new()
	local before = v.version
	MatchRules.join(v, 1, 0)
	local afterJoin = v.version
	MatchRules.step(v, 1)
	check("the version moves on every change and only then", afterJoin > before and v.version == afterJoin)

	local mp = oneVsOne()
	for _ = 1, 12 do
		win(mp, 1)
	end
	local point = MatchRules.matchPoint(mp)
	check("12-0: one side on match point", point[1] and not point[2])
end

do
	-- What the HUD works out from the score and the round.
	local COMPETITIVE = MatchConfig.Formats.competitive
	local SWIFT = MatchConfig.Formats.swiftplay
	check(
		"the winner on a score: 13 takes it; 12-12 and 13-12 don't in competitive, 14-12 does",
		MatchRules.winner(STANDARD, 13, 7) == 1
			and MatchRules.winner(STANDARD, 12, 12) == nil
			and MatchRules.winner(STANDARD, 12, 13) == 2
			and MatchRules.winner(COMPETITIVE, 13, 12) == nil
			and MatchRules.winner(COMPETITIVE, 14, 12) == 1
			and MatchRules.winner(COMPETITIVE, 15, 16) == nil
	)
	local p1, p2 = MatchRules.matchPointOf(STANDARD, 12, 11), MatchRules.matchPointOf(COMPETITIVE, 12, 12)
	local p3 = MatchRules.matchPointOf(COMPETITIVE, 13, 12)
	check(
		"match point: 12-11 for the side on 12; never at 12-12 in competitive; 13-12 for the side ahead",
		p1[1] and not p1[2] and not p2[1] and not p2[2] and p3[1] and not p3[2]
	)
	local swaps = {}
	for round = 1, 30 do
		if MatchRules.swapsAfter(STANDARD, round) then
			table.insert(swaps, round)
		end
	end
	local swapsOt = {}
	for round = 1, 28 do
		if MatchRules.swapsAfter(COMPETITIVE, round) then
			table.insert(swapsOt, round)
		end
	end
	check("the sides swap after round 12 only, in standard (sudden death stays put)", same(swaps, { 12 }), table.concat(swaps :: any, ","))
	check(
		"and after 12 and every overtime round from 24 in competitive",
		same(swapsOt, { 12, 24, 25, 26, 27, 28 }),
		table.concat(swapsOt :: any, ",")
	)
	check("and after round 4 in Swiftplay", MatchRules.swapsAfter(SWIFT, 4) and not MatchRules.swapsAfter(SWIFT, 3) and not MatchRules.swapsAfter(SWIFT, 8))
	check(
		"each match knows its format's key, standard for an unknown one",
		MatchRules.new("swiftplay").formatKey == "swiftplay" and MatchRules.new("nonsense").formatKey == "standard" and MatchRules.new().formatKey == "standard"
	)

	-- Skipping a phase, for scripted checks.
	local s = oneVsOne()
	MatchRules.skip(s, 5)
	MatchRules.step(s, 5)
	check("a skip ends the buy phase now", s.phase == "live" and s.phaseEndsAt == 5 + R.roundTime.value)
	MatchRules.skip(s, 6)
	MatchRules.step(s, 6)
	check("and a round on its clock, to the defenders", s.phase == "roundOver" and s.roundWinner == 2 and s.reason == "time")
	MatchRules.skip(s, 7)
	MatchRules.step(s, 7)
	check("and the wait for the next round", s.phase == "buy" and s.round == 2)
	MatchRules.step(s, s.phaseEndsAt)
	MatchRules.planted(s, 100)
	MatchRules.skip(s, 50)
	MatchRules.step(s, 50)
	check("but not a planted spike's countdown", s.phase == "planted" and s.phaseEndsAt == 100)
	local waiting = MatchRules.new()
	MatchRules.join(waiting, 1, 0)
	local before = waiting.version
	MatchRules.skip(waiting, 1)
	check("nor waiting for an opponent", waiting.phase == "waiting" and waiting.version == before)
end

-- The maps (system 25) -------------------------------------------------------------

do
	-- Each by its own key, all different, and the spike knowing each one's
	-- sites.
	local listed = #SpikeMaps.MAPS == 4
	local names: { [string]: boolean } = {}
	for _, key in SpikeMaps.MAPS do
		local map = SpikeMaps.Maps[key]
		listed = listed and map ~= nil and map.LAYOUT == key and not names[map.NAME] and Spike.Layouts[key] ~= nil
		if map then
			names[map.NAME] = true
		end
	end
	local count = 0
	for _ in SpikeMaps.Maps do
		count += 1
	end
	check("four maps for the spike rounds, each by its own key, and the spike knows each one's sites", listed and count == #SpikeMaps.MAPS)
	check("Outpost is the first", SpikeMaps.MAPS[1] == "outpost" and SpikeMaps.Maps.outpost == MatchMap)

	-- Where they stand in the place: apart, and well off the course's left
	-- (its floor ends at x -40 m).
	local spans = {}
	for _, key in SpikeMaps.MAPS do
		local map = SpikeMaps.Maps[key]
		local x0, _, x1 = map.bounds()
		table.insert(spans, { map.origin.x + x0, map.origin.x + x1 })
	end
	local apart = true
	for i, a in spans do
		apart = apart and a[2] < -60
		for j, b in spans do
			if i ~= j then
				apart = apart and (a[2] + 10 <= b[1] or b[2] + 10 <= a[1])
			end
		end
	end
	check("each is built in a place of its own, 10 m or more from the next, and 20 m or more from the course", apart)
end

do
	-- Cover either shows your head with your eye above it, or hides your head.
	local headTop, headBottom = 1.75, 1.49 -- Hitboxes: the standing head
	local ok = true
	for name, height in (MapPlan.Heights :: any) :: { [string]: MapPlan.Param } do
		local v = height.value
		ok = ok and (v < headBottom and v < cfg.standEyeHeight - 0.1 and v >= cfg.crouchHeight or v > headTop + 0.1)
		if not ok then
			print("    cover height in the wrong band: " .. name)
		end
	end
	check("no cover hides your eye but not your head", ok)
	check("and nobody can jump out: the walls are far above a jump", MapPlan.Plan.wallHeight.value > cfg.jumpApexHeight + cfg.standHeight)
end

do
	local okLabels = true
	local statuses = { confirmed = true, community = true, estimate = true }
	local function param(name: string, v: any)
		if type(v) ~= "table" or type(v.value) ~= "number" or not statuses[v.status] or type(v.source) ~= "string" or v.source == "" then
			okLabels = false
			print("    missing or unlabelled: " .. name)
		end
	end
	for key, v in (MatchConfig.Rules :: any) :: { [string]: any } do
		param("Rules." .. key, v)
	end
	for name, format in MatchConfig.Formats do
		param(name .. ".halfRounds", format.halfRounds)
		param(name .. ".winScore", format.winScore)
		okLabels = okLabels and format.overtimeSource ~= ""
	end
	for key, v in (MapPlan.Plan :: any) :: { [string]: any } do
		param("Plan." .. key, v)
	end
	for key, v in (MapPlan.Heights :: any) :: { [string]: any } do
		param("Heights." .. key, v)
	end
	okLabels = okLabels and MatchConfig.startingKitSource ~= ""
	check("every number has a status and a source", okLabels)
end

local HALF = cfg.halfWidth
local EYE = cfg.standEyeHeight
local CELL = 0.25
local MARGIN = 0.1 -- every way through is at least the player's width and 0.2 m more

local function solid(part: MapPlan.Part, barriers: boolean): boolean
	return part.kind == "wall" or part.kind == "cover" or (barriers and part.kind == "barrier")
end

-- How far apart an upright part's footprint and a square of half-width h at
-- (x, z) are (negative when they overlap). Every part here is square to the
-- axes.
local function gap(part: MapPlan.Part, x: number, z: number, h: number): number
	return math.max(math.abs(x - part.center.x) - part.size.x / 2 - h, math.abs(z - part.center.z) - part.size.z / 2 - h)
end

-- Whether the segment from a to b on the floor crosses a part's footprint.
local function crosses(part: MapPlan.Part, a: vector, b: vector): boolean
	local t0, t1 = 0, 1
	for _, axis in { { a.x, b.x, part.center.x, part.size.x / 2 }, { a.z, b.z, part.center.z, part.size.z / 2 } } do
		local p0, d, c, h = axis[1], axis[2] - axis[1], axis[3], axis[4]
		if math.abs(d) < 1e-12 then
			if math.abs(p0 - c) > h then
				return false
			end
		else
			local ta, tb = (c - h - p0) / d, (c + h - p0) / d
			if ta > tb then
				ta, tb = tb, ta
			end
			t0, t1 = math.max(t0, ta), math.min(t1, tb)
			if t0 > t1 then
				return false
			end
		end
	end
	return true
end

-- Labels each free cell with the region it's in; returns the labels and how
-- many regions there are.
local function regions(grid: { { boolean } }, nx: number, nz: number): ({ { number } }, number)
	local label: { { number } } = {}
	for i = 1, nx do
		label[i] = {}
	end
	local count = 0
	for i = 1, nx do
		for j = 1, nz do
			if grid[i][j] and not label[i][j] then
				count += 1
				local stack = { { i, j } }
				label[i][j] = count
				while #stack > 0 do
					local c = table.remove(stack) :: { number }
					for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
						local a, b = c[1] + d[1], c[2] + d[2]
						if a >= 1 and a <= nx and b >= 1 and b <= nz and grid[a][b] and not label[a][b] then
							label[a][b] = count
							table.insert(stack, { a, b })
						end
					end
				end
			end
		end
	end
	return label, count
end

-- Shortest walk on the free grid from a point to every cell (8 ways, in
-- metres), by Dijkstra with a binary heap.
local function walk(grid: { { boolean } }, nx: number, nz: number, fromI: number, fromJ: number): { { number } }
	local dist: { { number } } = {}
	for i = 1, nx do
		local column = {}
		for j = 1, nz do
			column[j] = math.huge
		end
		dist[i] = column
	end
	local heap: { { number } } = {}
	local function push(d: number, i: number, j: number)
		table.insert(heap, { d, i, j })
		local k = #heap
		while k > 1 do
			local parent = k // 2
			if heap[parent][1] <= heap[k][1] then
				break
			end
			heap[parent], heap[k] = heap[k], heap[parent]
			k = parent
		end
	end
	local function pop(): { number }
		local top = heap[1]
		local last = table.remove(heap) :: { number }
		if #heap > 0 then
			heap[1] = last
			local k = 1
			while true do
				local l, r = 2 * k, 2 * k + 1
				local m = k
				if l <= #heap and heap[l][1] < heap[m][1] then
					m = l
				end
				if r <= #heap and heap[r][1] < heap[m][1] then
					m = r
				end
				if m == k then
					break
				end
				heap[m], heap[k] = heap[k], heap[m]
				k = m
			end
		end
		return top
	end
	dist[fromI][fromJ] = 0
	push(0, fromI, fromJ)
	local diag = math.sqrt(2) * CELL
	while #heap > 0 do
		local top = pop()
		local d, i, j = top[1], top[2], top[3]
		if d <= dist[i][j] then
			for di = -1, 1 do
				for dj = -1, 1 do
					local a, b = i + di, j + dj
					if (di ~= 0 or dj ~= 0) and a >= 1 and a <= nx and b >= 1 and b <= nz and grid[a][b] then
						-- No cutting a corner past a blocked cell.
						if di ~= 0 and dj ~= 0 and not (grid[i + di][j] and grid[i][j + dj]) then
							continue
						end
						local nd = d + (if di ~= 0 and dj ~= 0 then diag else CELL)
						if nd < dist[a][b] then
							dist[a][b] = nd
							push(nd, a, b)
						end
					end
				end
			end
		end
	end
	return dist
end

-- Every check of one map, on the parts the server builds it from. Returns
-- how long each side takes to walk to each site's plant area, by site:
-- { attackers, defenders }.
local function checkMap(map: MapPlan.Map): { [string]: { number } }
	H.section(map.NAME .. " tests")
	local parts = map.parts()

	local onGrid = true
	for _, room in map.rooms() do
		for _, v in { room.x0, room.z0, room.x1, room.z1 } do
			onGrid = onGrid and v == math.floor(v)
		end
		onGrid = onGrid and room.x1 > room.x0 and room.z1 > room.z0
	end
	check("every room is a rectangle on the 1 m grid", onGrid)

	-- A map made mirrored has each part's mirror image across x = 0: the
	-- same kind and size.
	local mirrored = false
	for _, room in map.Rooms do
		mirrored = mirrored or room.mirror ~= nil
	end
	if mirrored then
		local unmatched = 0
		for _, part in parts do
			local mirror = vector.create(-part.center.x, part.center.y, part.center.z)
			local found = false
			for _, other in parts do
				if other.kind == part.kind and vector.magnitude(other.center - mirror) < 1e-6 and vector.magnitude(other.size - part.size) < 1e-9 then
					found = true
					break
				end
			end
			if not found then
				unmatched += 1
			end
		end
		check("the map is mirrored left to right: A's side is B's", unmatched == 0, unmatched .. " without")
	end

	local coverOk = true
	for _, part in parts do
		if part.kind == "cover" then
			for _, corner in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
				local x = part.center.x + corner[1] * (part.size.x / 2 - 0.01)
				local z = part.center.z + corner[2] * (part.size.z / 2 - 0.01)
				coverOk = coverOk and map.onFloor(x, z)
			end
		end
	end
	check("every piece of cover stands on the floor, clear of the walls", coverOk)

	-- Free floor for a player's box, on a grid over the map: true where the
	-- box fits with `margin` to spare.
	local BX0, BZ0, BX1, BZ1 = map.bounds()
	local nx, nz = math.ceil((BX1 - BX0) / CELL), math.ceil((BZ1 - BZ0) / CELL)
	local function cellOf(x: number, z: number): (number, number)
		return math.floor((x - BX0) / CELL) + 1, math.floor((z - BZ0) / CELL) + 1
	end
	local function freeGrid(barriers: boolean, margin: number): { { boolean } }
		local grid = {}
		for i = 1, nx do
			local column = {}
			for j = 1, nz do
				column[j] = map.onFloor(BX0 + (i - 0.5) * CELL, BZ0 + (j - 0.5) * CELL)
			end
			grid[i] = column
		end
		-- Each part blocks the cells near enough it, and only those.
		local reach = HALF + margin
		for _, part in parts do
			if solid(part, barriers) then
				local i0, j0 = cellOf(part.center.x - part.size.x / 2 - reach, part.center.z - part.size.z / 2 - reach)
				local i1, j1 = cellOf(part.center.x + part.size.x / 2 + reach, part.center.z + part.size.z / 2 + reach)
				for i = math.max(i0, 1), math.min(i1, nx) do
					local column = grid[i]
					for j = math.max(j0, 1), math.min(j1, nz) do
						if column[j] and gap(part, BX0 + (i - 0.5) * CELL, BZ0 + (j - 0.5) * CELL, HALF) < margin then
							column[j] = false
						end
					end
				end
			end
		end
		return grid
	end

	local grid = freeGrid(false, MARGIN)
	local label, count = regions(grid, nx, nz)
	check("with the barriers down the floor is all one space: every room reachable, every gap wider than a player", count == 1, count .. " regions")
	local roomsReached = true
	for _, room in map.rooms() do
		-- Somewhere in each room a player fits, and it's the one space.
		local found = false
		local i0, j0 = cellOf(room.x0 + 0.01, room.z0 + 0.01)
		local i1, j1 = cellOf(room.x1 - 0.01, room.z1 - 0.01)
		for i = i0, i1 do
			for j = j0, j1 do
				if grid[i][j] and label[i][j] == 1 then
					found = true
				end
			end
		end
		roomsReached = roomsReached and found
		if not found then
			print("    nowhere to stand in " .. room.name)
		end
	end
	check("and there's room to stand in every room", roomsReached)

	local spotsFree = #map.spots("attack") >= R.sideSize.value and #map.spots("defend") >= R.sideSize.value
	for _, role in { "attack", "defend" } :: { MapPlan.Role } do
		for _, spot in map.spots(role) do
			for _, part in parts do
				if solid(part, true) and gap(part, spot.feet.x, spot.feet.z, HALF) < MARGIN then
					spotsFree = false
				end
			end
			local i, j = cellOf(spot.feet.x, spot.feet.z)
			spotsFree = spotsFree and label[i][j] == 1
		end
	end
	check("a spawn spot for each of five a side, each clear, even with the barriers up", spotsFree)

	local start = map.spikeStart
	local inSpawn = map.room("AttackerSpawn") :: MapPlan.Room
	local clear = true
	for _, part in parts do
		if solid(part, true) and gap(part, start.x, start.z, 0.3) < 0 then
			clear = false
		end
	end
	check(
		"the spike starts in front of the attackers, inside their spawn and clear of everything",
		clear and start.x > inSpawn.x0 and start.x < inSpawn.x1 and start.z > inSpawn.z0 and start.z < inSpawn.z1 and start.z < map.spots("attack")[1].feet.z
	)

	local up = freeGrid(true, MARGIN)
	local upLabel = regions(up, nx, nz)
	local function regionAt(x: number, z: number): number?
		local i, j = cellOf(x, z)
		return upLabel[i][j]
	end
	local attack, defend = map.spots("attack")[1].feet, map.spots("defend")[1].feet
	-- Just outside the attackers' door to mid.
	local midDoor = map.room("AttackerDoorMid") :: MapPlan.Room
	local midPoint = regionAt((midDoor.x0 + midDoor.x1) / 2, midDoor.z0 - 1)
	check(
		"with the barriers up each side is held in its spawn",
		midPoint ~= nil
			and regionAt(attack.x, attack.z) ~= nil
			and regionAt(attack.x, attack.z) ~= midPoint
			and regionAt(defend.x, defend.z) ~= midPoint
			and regionAt(attack.x, attack.z) ~= regionAt(defend.x, defend.z)
	)

	-- The zones: inside their sites' rooms, on the floor, in the place's
	-- metres for the spike.
	local zones = map.zones()
	local zonesOk = #zones == 2 and zones[1].site == "A" and zones[2].site == "B"
	for _, zone in zones do
		local room = map.room(zone.site .. "Site") :: MapPlan.Room
		local c = zone.center - map.origin
		zonesOk = zonesOk
			and c.x - zone.half.x >= room.x0
			and c.x + zone.half.x <= room.x1
			and c.z - zone.half.z >= room.z0
			and c.z + zone.half.z <= room.z1
			and zone.center.y - zone.half.y <= 0
			and zone.center.y + zone.half.y >= 1
	end
	check("each site's plant area is inside its site, from the floor up", zonesOk)
	local layout = Spike.Layouts[map.LAYOUT]
	local same2 = layout ~= nil and #layout == 2
	if layout then
		for i, zone in zones do
			same2 = same2 and vector.magnitude(layout[i].center - zone.center) < 1e-9 and vector.magnitude(layout[i].half - zone.half) < 1e-9
		end
	end
	check("and the spike knows them as the map's layout", same2)

	-- How long each side takes to walk to each site's plant area, running
	-- with the knife out, from their first spawn spot.
	local speed = MovementConfig.Params.baseRunSpeed.value
	local function timeTo(dist: { { number } }, zone: MapPlan.Zone): number
		local best = math.huge
		local c = zone.center - map.origin
		local x0, x1 = c.x - zone.half.x, c.x + zone.half.x
		local z0, z1 = c.z - zone.half.z, c.z + zone.half.z
		for i = 1, nx do
			for j = 1, nz do
				local x, z = BX0 + (i - 0.5) * CELL, BZ0 + (j - 0.5) * CELL
				if x >= x0 and x <= x1 and z >= z0 and z <= z1 and dist[i][j] < best then
					best = dist[i][j]
				end
			end
		end
		return best / speed
	end
	local ai, aj = cellOf(attack.x, attack.z)
	local di, dj = cellOf(defend.x, defend.z)
	local fromAttack, fromDefend = walk(grid, nx, nz, ai, aj), walk(grid, nx, nz, di, dj)
	local times = {}
	local nearer = true
	for _, zone in zones do
		local a, d = timeTo(fromAttack, zone), timeTo(fromDefend, zone)
		times[zone.site] = { a, d }
		nearer = nearer and d < a
	end
	check("the defenders reach each site before the attackers can", nearer)

	-- Every eye in one spawn against every eye in the other: something
	-- taller than the eye is in the way.
	local function eyes(name: string): { vector }
		local room = map.room(name) :: MapPlan.Room
		local out = {}
		local x = room.x0 + HALF
		while x <= room.x1 - HALF + 1e-9 do
			local z = room.z0 + HALF
			while z <= room.z1 - HALF + 1e-9 do
				table.insert(out, vector.create(x, 0, z))
				z += 1
			end
			x += 1
		end
		return out
	end
	local tall = {}
	for _, part in parts do
		if solid(part, false) and part.center.y + part.size.y / 2 > EYE then
			table.insert(tall, part)
		end
	end
	local function blocked(a: vector, b: vector): boolean
		for _, part in tall do
			if crosses(part, a, b) then
				return true
			end
		end
		return false
	end
	local from, to = eyes("AttackerSpawn"), eyes("DefenderSpawn")
	local open = 0
	for _, a in from do
		for _, b in to do
			if not blocked(a, b) then
				open += 1
			end
		end
	end
	check("standing anywhere in either spawn, you can't see into the other", open == 0 and #from > 50, string.format("%d of %d lines open", open, #from * #to))

	-- The real movement against the map's parts: run at a barrier, then with
	-- it down, out through the door.
	local function world(barriers: boolean): any
		local w = FakeWorld.new():addFloor()
		for _, part in parts do
			if solid(part, barriers) then
				w:addPart(part.center, part.size, 0, part.yaw, 0)
			end
		end
		return w
	end
	local spot = map.spots("attack")[1]
	local function run(barriers: boolean, seconds: number): vector
		local sim = PlayerSim.new(spot.feet + vector.create(0, 0.05, 0))
		local w = world(barriers)
		for i = 1, math.floor(seconds / DT) do
			PlayerSim.step(sim, { seq = i, buttons = B.Forward, slot = 1, yaw = spot.yaw, pitch = 0, viewTime = 0 }, cfg, w, DT)
		end
		return sim.movement.position
	end
	local held = run(true, 3)
	check("running at the barrier for 3 s, the attackers stay in their spawn", held.z > midDoor.z0 + 0.5, string.format("z %.2f", held.z))
	local free = run(false, 3)
	check("with it down they run out to mid", free.z < midDoor.z0 - 5, string.format("z %.2f", free.z))
	return times
end

local times = {}
for _, key in SpikeMaps.MAPS do
	times[key] = checkMap(SpikeMaps.Maps[key])
end
H.section("Spike maps report")
local speed = MovementConfig.Params.baseRunSpeed.value
for _, key in SpikeMaps.MAPS do
	for _, site in { "A", "B" } do
		local t = times[key][site]
		print(
			string.format(
				"%s, to site %s's plant area, running with the knife (%.2f m/s): attackers %.1f s, defenders %.1f s",
				SpikeMaps.Maps[key].NAME,
				site,
				speed,
				t[1],
				t[2]
			)
		)
	end
end

return nil
