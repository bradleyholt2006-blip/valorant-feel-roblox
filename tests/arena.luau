--!strict
-- The arena (system 7): Skirmish's rounds, and the whitebox of Skirmish A
-- they're played on: inside its walls, the same from either end, room to
-- move everywhere, no sightline from one spawn to the other, barriers that
-- hold each side in, and every number labelled.

local ArenaConfig = require("../src/shared/Arena/ArenaConfig")
local ArenaLayout = require("../src/shared/Arena/ArenaLayout")
local ArenaRules = require("../src/shared/Arena/ArenaRules")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerSim = require("../src/shared/PlayerSim")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")

local check = H.check

local R = ArenaConfig.Rules
local cfg = MovementConfig.resolve()
local DT = 1 / MovementConfig.TickRate.value
local B = PlayerSim.Buttons

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

H.section("Arena tests")

-- Rounds ----------------------------------------------------------------------

do
	local s = ArenaRules.new()
	local t = 100
	check("alone, you spawn on side 1 and wait for an opponent", same(ArenaRules.join(s, 11, t), { 11 }) and s.phase == "waiting" and ArenaRules.sideOf(s, 11) == 1)
	check("while waiting you can pick a gun any time, and the barriers are down", ArenaRules.canPick(s, 11) and not ArenaRules.barriersUp(s))
	local spawned = ArenaRules.join(s, 22, t)
	check("an opponent joins side 2 and starts round 1: both spawn", same(spawned, { 11, 22 }) and ArenaRules.sideOf(s, 22) == 2 and s.phase == "buy" and s.round == 1)
	check("round 1's buy phase is the long one, behind the barriers", s.phaseEndsAt == t + R.firstBuyTime.value and ArenaRules.barriersUp(s) and ArenaRules.canPick(s, 22))
	check("the buy phase lasts its time", #ArenaRules.step(s, t + R.firstBuyTime.value - 0.01) == 0 and s.phase == "buy")
	ArenaRules.step(s, t + R.firstBuyTime.value)
	check("then the round is live: barriers down, no more picking", s.phase == "live" and not ArenaRules.barriersUp(s) and not ArenaRules.canPick(s, 11))
	t += R.firstBuyTime.value + 7
	ArenaRules.died(s, 22, t)
	check("a kill ends the round, and the killer's side scores", s.phase == "roundOver" and s.roundWinner == 1 and s.score[1] == 1 and s.score[2] == 0)
	ArenaRules.died(s, 11, t + 1)
	check("deaths after the round's end change nothing", s.score[1] == 1 and s.score[2] == 0 and s.roundWinner == 1)
	check("the next round waits for its time", #ArenaRules.step(s, t + R.roundOverTime.value - 0.01) == 0)
	spawned = ArenaRules.step(s, t + R.roundOverTime.value)
	check(
		"then everyone spawns, dead or alive, for round 2 and its short buy phase",
		same(spawned, { 11, 22 }) and s.phase == "buy" and s.round == 2 and s.phaseEndsAt == t + R.roundOverTime.value + R.buyTime.value
	)

	-- Side 2 wins the rest.
	for _ = 1, R.winScore.value do
		t = s.phaseEndsAt
		ArenaRules.step(s, t)
		ArenaRules.died(s, 11, t + 5)
		if s.phase == "matchOver" then
			break
		end
		ArenaRules.step(s, s.phaseEndsAt)
	end
	check(
		"the first side to the win score takes the match",
		s.phase == "matchOver" and s.matchWinner == 2 and s.score[2] == R.winScore.value and s.score[1] == 1,
		string.format("%s %d-%d", s.phase, s.score[1], s.score[2])
	)
	spawned = ArenaRules.step(s, s.phaseEndsAt)
	check(
		"then a new match starts at 0-0, with round 1's long buy phase",
		same(spawned, { 11, 22 }) and s.score[1] == 0 and s.score[2] == 0 and s.round == 1 and s.matchWinner == nil and s.phase == "buy"
	)
end

do
	local s = ArenaRules.new()
	local t = 0
	for _, id in { 1, 2, 3, 4 } do
		ArenaRules.join(s, id, t)
	end
	local sides = { ArenaRules.sideOf(s, 1), ArenaRules.sideOf(s, 2), ArenaRules.sideOf(s, 3), ArenaRules.sideOf(s, 4) }
	local spots = { ArenaRules.spotOf(s, 1), ArenaRules.spotOf(s, 2), ArenaRules.spotOf(s, 3), ArenaRules.spotOf(s, 4) }
	check("2v2: players alternate sides as they join, each in their own spot", same(sides :: any, { 1, 2, 1, 2 }) and same(spots :: any, { 1, 1, 2, 2 }))
	ArenaRules.step(s, s.phaseEndsAt)
	ArenaRules.died(s, 1, 30)
	check("one of two down doesn't end the round", s.phase == "live")
	ArenaRules.died(s, 3, 31)
	check("the second does", s.phase == "roundOver" and s.roundWinner == 2)

	ArenaRules.step(s, s.phaseEndsAt)
	ArenaRules.step(s, s.phaseEndsAt)
	ArenaRules.died(s, 2, 50)
	ArenaRules.leave(s, 4, 51)
	check("leaving while your teammate is down loses the round", s.phase == "roundOver" and s.roundWinner == 1 and s.score[1] == 1)
end

do
	local s = ArenaRules.new()
	ArenaRules.join(s, 1, 0)
	ArenaRules.join(s, 2, 0)
	ArenaRules.step(s, s.phaseEndsAt)
	ArenaRules.died(s, 2, 20)
	ArenaRules.step(s, s.phaseEndsAt)
	ArenaRules.step(s, s.phaseEndsAt)
	ArenaRules.died(s, 1, 40)
	ArenaRules.leave(s, 2, 41)
	check("your opponent leaving goes back to waiting and keeps the score", s.phase == "waiting" and s.score[1] == 1 and s.score[2] == 1)
	check("you come back after the respawn time", #ArenaRules.step(s, 41 + R.respawnTime.value - 0.01) == 0 and same(ArenaRules.step(s, 41 + R.respawnTime.value), { 1 }))
	ArenaRules.died(s, 1, 60)
	check("and again if you die while waiting", same(ArenaRules.step(s, 60 + R.respawnTime.value), { 1 }))
	local spawned = ArenaRules.join(s, 3, 70)
	check("a new opponent starts the next round, with its short buy phase", same(spawned, { 1, 3 }) and s.round == 3 and s.phaseEndsAt == 70 + R.buyTime.value)

	local m = ArenaRules.new()
	ArenaRules.join(m, 1, 0)
	ArenaRules.join(m, 2, 0)
	for i = 1, R.winScore.value do
		ArenaRules.step(m, m.phaseEndsAt)
		ArenaRules.died(m, 2, i * 100)
		if m.phase == "roundOver" then
			ArenaRules.step(m, m.phaseEndsAt)
		end
	end
	local won = m.phase == "matchOver"
	ArenaRules.leave(m, 2, 2000)
	check("leaving a finished match starts the next one at 0-0", won and m.phase == "waiting" and m.score[1] == 0 and m.round == 0)

	local v = ArenaRules.new()
	local before = v.version
	ArenaRules.join(v, 1, 0)
	local afterJoin = v.version
	ArenaRules.step(v, 1)
	check("the version moves on every change and only then", afterJoin > before and v.version == afterJoin)
end

-- The map -----------------------------------------------------------------------

local parts = ArenaLayout.parts()
local W, L, RW, RD = ArenaLayout.size()
local HALF = cfg.halfWidth
local EYE = cfg.standEyeHeight

-- How far apart a part's footprint and an upright square of half-width h at
-- (x, z) are (negative when they overlap): the widest gap along the four axes
-- that can separate them.
local function gap(part: ArenaLayout.Part, x: number, z: number, h: number): number
	local dx, dz = x - part.center.x, z - part.center.z
	local c, s = math.cos(part.yaw), math.sin(part.yaw)
	local hx, hz = part.size.x / 2, part.size.z / 2
	-- The part's own axes in (x, z): its x is (c, -s) and its z (s, c).
	local px, pz = dx * c - dz * s, dx * s + dz * c
	local ac, as = math.abs(c), math.abs(s)
	return math.max(
		math.abs(dx) - (h + hx * ac + hz * as),
		math.abs(dz) - (h + hx * as + hz * ac),
		math.abs(px) - (hx + h * (ac + as)),
		math.abs(pz) - (hz + h * (ac + as))
	)
end

-- Whether the line from a to b on the floor crosses a part's footprint.
local function crosses(part: ArenaLayout.Part, a: vector, b: vector): boolean
	local c, s = math.cos(part.yaw), math.sin(part.yaw)
	local function into(v: vector): (number, number)
		local dx, dz = v.x - part.center.x, v.z - part.center.z
		return dx * c - dz * s, dx * s + dz * c
	end
	local ax, az = into(a)
	local bx, bz = into(b)
	local t0, t1 = 0, 1
	for _, axis in { { ax, bx, part.size.x / 2 }, { az, bz, part.size.z / 2 } } do
		local p0, d, h = axis[1], axis[2] - axis[1], axis[3]
		if math.abs(d) < 1e-12 then
			if math.abs(p0) > h then
				return false
			end
		else
			local ta, tb = (-h - p0) / d, (h - p0) / d
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

local function solid(part: ArenaLayout.Part, barriers: boolean): boolean
	return part.kind == "wall" or part.kind == "cover" or (barriers and part.kind == "barrier")
end

local function corners(part: ArenaLayout.Part): { vector }
	local c, s = math.cos(part.yaw), math.sin(part.yaw)
	local out = {}
	for _, k in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		local lx, lz = k[1] * part.size.x / 2, k[2] * part.size.z / 2
		table.insert(out, vector.create(part.center.x + lx * c + lz * s, 0, part.center.z - lx * s + lz * c))
	end
	return out
end

do
	local hall = ArenaLayout.hall()
	local inside = true
	for _, part in parts do
		if part.kind == "cover" then
			for _, corner in corners(part) do
				inside = inside
					and corner.x >= hall.min.x - 1e-6
					and corner.x <= hall.max.x + 1e-6
					and corner.z >= hall.min.z - 1e-6
					and corner.z <= hall.max.z + 1e-6
			end
		end
	end
	check("every piece of cover is inside the hall", inside)

	-- Each part has a partner turned half way round the centre: the same
	-- kind and size, facing the same way (a box turned half way round looks
	-- the same).
	local unmatched = 0
	for _, part in parts do
		local turned = ArenaLayout.turned(part.center)
		local found = false
		for _, other in parts do
			local dyaw = (other.yaw - part.yaw) % math.pi
			if
				other.kind == part.kind
				and vector.magnitude(other.center - turned) < 1e-6
				and vector.magnitude(other.size - part.size) < 1e-9
				and (dyaw < 1e-9 or math.pi - dyaw < 1e-9)
			then
				found = true
				break
			end
		end
		if not found then
			unmatched += 1
		end
	end
	check("the map is the same seen from either spawn (each part has its partner turned round the centre)", unmatched == 0, unmatched .. " without")

	local pieces = 0
	for _, part in parts do
		if part.kind == "cover" then
			pieces += 1
		end
	end
	-- 1 centre block, 2 side crates, 4 double crates of 2, 4 wall crates.
	check("all of Skirmish A's cover is there: 15 blocks and crates", pieces == 15, tostring(pieces))

	-- Along each wall from every corner of the hall: the cut ends where the plan says.
	local cut = ArenaLayout.Plan.chamfer.value * W
	local function inCorner(x: number, z: number): boolean
		for _, part in parts do
			if part.name == "Corner" and gap(part, x, z, 0) < 0 then
				return true
			end
		end
		return false
	end
	local cutRight = true
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local cx, cz = sx * W / 2, sz * L / 2
			for _, along in { { -sx, 0 }, { 0, -sz } } do
				local function at(d: number): boolean
					-- d along the wall, 1 cm off it
					local off = { -sx * (1 - math.abs(along[1])), -sz * (1 - math.abs(along[2])) }
					return inCorner(cx + along[1] * d + off[1] * 0.01, cz + along[2] * d + off[2] * 0.01)
				end
				cutRight = cutRight and at(cut - 0.03) and not at(cut + 0.03)
			end
		end
	end
	check(string.format("the hall's corners are cut at 45 degrees, %.2f m along each wall", cut), cutRight)
end

-- Free floor for a player's box, on a grid over the hall and the rooms:
-- true where the box fits with `margin` to spare.
local CELL = 0.2
local function onPlan(x: number, z: number): boolean
	for _, rect in { ArenaLayout.hall(), ArenaLayout.room(1), ArenaLayout.room(2) } do
		if x >= rect.min.x and x <= rect.max.x and z >= rect.min.z and z <= rect.max.z then
			return true
		end
	end
	return false
end
local function freeGrid(barriers: boolean, margin: number): ({ { boolean } }, number, number, (x: number, z: number) -> (number, number))
	local x0, z0 = -W / 2 - 1, -L / 2 - RD - 1
	local nx, nz = math.ceil((W + 2) / CELL), math.ceil((L + 2 * RD + 2) / CELL)
	local blockers = {}
	for _, part in parts do
		if solid(part, barriers) then
			table.insert(blockers, part)
		end
	end
	local grid = {}
	for i = 1, nx do
		local column = {}
		for j = 1, nz do
			local x, z = x0 + (i - 0.5) * CELL, z0 + (j - 0.5) * CELL
			local free = onPlan(x, z)
			for _, part in if free then blockers else {} do
				if gap(part, x, z, HALF) < margin then
					free = false
					break
				end
			end
			column[j] = free
		end
		grid[i] = column
	end
	local function cellOf(x: number, z: number): (number, number)
		return math.floor((x - x0) / CELL) + 1, math.floor((z - z0) / CELL) + 1
	end
	return grid, nx, nz, cellOf
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

local MARGIN = 0.1 -- every way through is at least the player's width and 0.2 m more
do
	local grid, nx, nz, cellOf = freeGrid(false, MARGIN)
	local label, count = regions(grid, nx, nz)
	local spotsFree = true
	local spotRegion: number? = nil
	for side = 1, 2 do
		for _, spot in ArenaLayout.spots(side) do
			for _, part in parts do
				if solid(part, true) and gap(part, spot.feet.x, spot.feet.z, HALF) < MARGIN then
					spotsFree = false
				end
			end
			local i, j = cellOf(spot.feet.x, spot.feet.z)
			spotRegion = spotRegion or label[i][j]
			spotsFree = spotsFree and label[i][j] == spotRegion
		end
	end
	check("every spawn spot is clear, even with the barriers up", spotsFree)
	check(
		"with the barriers down the floor is all one space: no pocket you can't get to, every gap wider than a player",
		count == 1,
		count .. " regions"
	)

	local up, ux, uz, upCell = freeGrid(true, MARGIN)
	local upLabel = regions(up, ux, uz)
	local function regionAt(x: number, z: number): number
		local i, j = upCell(x, z)
		return upLabel[i][j]
	end
	local one, two = ArenaLayout.spots(1)[1].feet, ArenaLayout.spots(2)[1].feet
	local hallPoint = vector.create(0, 0, -L / 4)
	check(
		"with the barriers up each side is held in its room",
		regionAt(one.x, one.z) ~= regionAt(hallPoint.x, hallPoint.z) and regionAt(two.x, two.z) ~= regionAt(hallPoint.x, hallPoint.z)
	)
end

do
	-- Every eye, standing anywhere in one room, against every eye in the
	-- other: something taller than the eye is in the way.
	local function eyes(side: number): { vector }
		local room = ArenaLayout.room(side)
		local out = {}
		local x = room.min.x + HALF
		while x <= room.max.x - HALF + 1e-9 do
			local z = room.min.z + HALF
			while z <= room.max.z - HALF + 1e-9 do
				table.insert(out, vector.create(x, 0, z))
				z += 0.5
			end
			x += 0.5
		end
		return out
	end
	local function blockedAt(height: number, a: vector, b: vector): boolean
		for _, part in parts do
			if solid(part, false) and part.center.y + part.size.y / 2 > height and part.center.y - part.size.y / 2 < height and crosses(part, a, b) then
				return true
			end
		end
		return false
	end
	local from, to = eyes(1), eyes(2)
	local open, jumpOpen = 0, 0
	for _, a in from do
		for _, b in to do
			if not blockedAt(EYE, a, b) then
				open += 1
			end
			if not blockedAt(EYE + cfg.jumpApexHeight, a, b) then
				jumpOpen += 1
			end
		end
	end
	check(
		"standing anywhere in your spawn, you can't see into the other one",
		open == 0 and #from > 50,
		string.format("%d of %d lines open", open, #from * #to)
	)
	H.section("Arena report")
	print(
		string.format(
			"spawn to spawn at the top of a jump (estimates): %d of %d lines open (%.0f%%)",
			jumpOpen,
			#from * #to,
			jumpOpen / (#from * #to) * 100
		)
	)
	H.section("Arena tests")
end

do
	-- The real movement against the arena's parts: run at the barrier, then
	-- with it down, out into the hall.
	local function world(barriers: boolean): any
		local w = FakeWorld.new():addFloor()
		for _, part in parts do
			if solid(part, barriers) then
				w:addPart(part.center, part.size, 0, part.yaw, 0)
			end
		end
		return w
	end
	local spot = ArenaLayout.spots(1)[1]
	local function run(barriers: boolean, seconds: number): vector
		local sim = PlayerSim.new(spot.feet + vector.create(0, 0.05, 0))
		local w = world(barriers)
		for i = 1, math.floor(seconds / DT) do
			PlayerSim.step(sim, { seq = i, buttons = B.Forward, slot = 1, yaw = spot.yaw, pitch = 0, viewTime = 0 }, cfg, w, DT)
		end
		return sim.movement.position
	end
	local held = run(true, 3)
	local mouth = ArenaLayout.room(1).max.z
	check("running at the barrier for 3 s, you stay in your room", held.z < mouth and held.y > -0.01, string.format("z %.2f, mouth %.2f", held.z, mouth))
	local free = run(false, 3)
	check("with it down you run out into the hall", free.z > mouth + 5, string.format("z %.2f", free.z))
	check("and you can't jump out: the walls are far above a jump", ArenaLayout.Plan.wallHeight.value > cfg.jumpApexHeight + cfg.standHeight)
end

do
	-- Cover either shows your head with your eye above it, or hides your head.
	local headTop, headBottom = 1.75, 1.49 -- Hitboxes: the standing head
	local ok = true
	for name, height in (ArenaLayout.Heights :: any) :: { [string]: ArenaLayout.Param } do
		local v = height.value
		ok = ok and (v < headBottom and v < EYE - 0.1 and v >= cfg.crouchHeight or v > headTop + 0.1)
		if not ok then
			print("    cover height in the wrong band: " .. name)
		end
	end
	check("no cover hides your eye but not your head", ok)
end

do
	local okLabels = true
	local statuses = { confirmed = true, community = true, estimate = true, measured = true }
	local function param(name: string, v: any)
		if type(v) ~= "table" or type(v.value) ~= "number" or not statuses[v.status] or type(v.source) ~= "string" or v.source == "" then
			okLabels = false
			print("    missing or unlabelled: " .. name)
		end
	end
	for key, v in (ArenaConfig.Rules :: any) :: { [string]: any } do
		param("Rules." .. key, v)
	end
	for key, v in (ArenaLayout.Plan :: any) :: { [string]: any } do
		param("Plan." .. key, v)
	end
	for key, v in (ArenaLayout.Heights :: any) :: { [string]: any } do
		param("Heights." .. key, v)
	end
	okLabels = okLabels and ArenaLayout.piecesStatus == "measured" and ArenaLayout.piecesSource ~= ""
	check("every number has a status and a source", okLabels)
end

H.section("Arena report")
do
	local spot1, spot2 = ArenaLayout.spots(1)[1].feet, ArenaLayout.spots(2)[1].feet
	print(string.format("hall %.1f x %.1f m (scale an estimate), spawn rooms %.1f x %.1f m", W, L, RW, RD))
	print(string.format("spawn to spawn %.1f m; hall corner to corner %.1f m", vector.magnitude(spot2 - spot1), math.sqrt(W * W + L * L)))
	print(
		string.format(
			"rules: first to %d, buy phase %d s then %d s (community), next round %d s after the last kill (estimate)",
			R.winScore.value,
			R.firstBuyTime.value,
			R.buyTime.value,
			R.roundOverTime.value
		)
	)
end

return nil
