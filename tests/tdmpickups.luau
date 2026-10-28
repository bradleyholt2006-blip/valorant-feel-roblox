--!strict
-- Team Deathmatch's pickups (system 28). Weapon spawners hold a gun of the
-- stage's, lent in place of the loadout's until it's spent or dropped, or
-- the next stage's loadout comes; a spawner taken has another gun after a
-- wait, and each stage restocks them all. Recovery Orbs mend health and
-- shield over 6 s and leave a zone that mends the taker's allies once each,
-- back after 30 s. The Ultimate Orbs come up together, a while in and then
-- every so often. And each map has them out on its floor, each as quick a
-- run from one side's spawn as from the other's.

local TeamDeathmatchConfig = require("../src/shared/Arena/TeamDeathmatchConfig")
local TeamDeathmatchRules = require("../src/shared/Arena/TeamDeathmatchRules")
local MapVote = require("../src/shared/Match/MapVote")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local H = require("./Harness")
local Levels = require("./Levels")

local check = H.check

local T = TeamDeathmatchConfig.Rules
local GUNS = TeamDeathmatchConfig.SpawnerGuns
local PICKUPS = TeamDeathmatchConfig.Pickups
local R = TeamDeathmatchRules

local function dice(...: number): MapVote.Roll
	local rolls = { ... }
	local i = 0
	return function(n: number): number
		i += 1
		local r = rolls[i] or 1
		assert(r >= 1 and r <= n, "a roll off the dice")
		return r
	end
end

-- Players 1 to n joined at time 0 (odd ids on side 1, even on side 2), on
-- Outpost, with the match under way from the end of the pre-game, at
-- `T.preGame`; the dice roll `rolls` after the first map's.
local function match(n: number, ...: number): TeamDeathmatchRules.State
	local s = R.new(nil, dice(1, ...))
	for id = 1, n do
		R.join(s, id, 0)
	end
	R.step(s, T.preGame.value)
	return s
end

local LIVE = T.preGame.value
local OUTPOST = PICKUPS.outpost

H.section("Team Deathmatch's pickups (system 28)")

-- The numbers ------------------------------------------------------------------------------

do
	local guns, ammo = true, true
	for _, list in GUNS do
		for _, entry in list do
			local def = WeaponConfig.Defs[entry.gun]
			guns = guns and def ~= nil and (def.slot == 1 or def.slot == 2) and not def.ultimate
			ammo = ammo and def ~= nil and entry.ammo == def.magazine.value and entry.reserve >= 0 and entry.reserve <= def.reserve.value
		end
	end
	check("every spawner gun is a gun of ours, a primary or a sidearm", guns)
	check("each with its own magazine and no more than its own reserve", ammo)
	check("four stages of spawner guns, as of loadouts", #GUNS == #TeamDeathmatchConfig.Stages)
	check(
		"the wiki's guns: the Shorty, Sheriff and Stinger first, and last the Judge, Operator and Odin",
		GUNS[1][1].gun == "shorty"
			and GUNS[1][2].gun == "sheriff"
			and GUNS[1][3].gun == "stinger"
			and #GUNS[4] == 3
			and GUNS[4][2].gun == "operator"
			and GUNS[4][2].reserve == 3
			and GUNS[4][3].gun == "odin"
			and GUNS[4][3].reserve == 0
	)
	check(
		"Recovery Orbs mend over 6 s and come back after 30, Riot's",
		T.recoveryTime.value == 6
			and T.recoveryTime.status == "confirmed"
			and T.recoveryWait.value == 30
			and T.recoveryWait.status == "confirmed"
	)
	local labelled = TeamDeathmatchConfig.SpawnerGunsStatus == "community" and TeamDeathmatchConfig.PickupsStatus == "estimate"
	check("the spawners' guns are the wiki's, and where the pickups stand ours", labelled)
end

-- Where they stand -------------------------------------------------------------------------

-- Shortest runs on a map, from a point to every half-metre cell of its floor
-- a player fits in (eight ways, never across a corner), in metres.
local CELL = 0.5
local HALF = MovementConfig.resolve().halfWidth

local function gap(part: any, x: number, z: number, h: number): number
	return math.max(math.abs(x - part.center.x) - part.size.x / 2 - h, math.abs(z - part.center.z) - part.size.z / 2 - h)
end

local function solids(map: any): { any }
	local out = {}
	for _, part in map.parts() do
		local kind = part.kind
		if kind == "wall" or kind == "cover" or kind == "deck" or kind == "flight" or kind == "rail" then
			table.insert(out, part)
		end
	end
	return out
end

local function runs(map: any): (number, number) -> (number, number) -> number
	local parts = solids(map)
	local x0, z0, x1, z1 = map.bounds()
	local nx, nz = math.ceil((x1 - x0) / CELL), math.ceil((z1 - z0) / CELL)
	local free: { { boolean } } = {}
	for i = 1, nx do
		local column = {}
		for j = 1, nz do
			local x, z = x0 + (i - 0.5) * CELL, z0 + (j - 0.5) * CELL
			local ok = map.onFloor(x, z)
			for _, part in parts do
				if not ok then
					break
				end
				ok = gap(part, x, z, HALF) >= 0.1
			end
			column[j] = ok
		end
		free[i] = column
	end
	local function cellOf(x: number, z: number): (number, number)
		return math.floor((x - x0) / CELL) + 1, math.floor((z - z0) / CELL) + 1
	end
	return function(fromX: number, fromZ: number)
		-- Dijkstra over the grid, with a binary heap of { distance, i, j }.
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
				local up = k // 2
				if heap[up][1] <= heap[k][1] then
					break
				end
				heap[up], heap[k] = heap[k], heap[up]
				k = up
			end
		end
		local function pop(): { number }
			local top = heap[1]
			local last = table.remove(heap) :: { number }
			if #heap > 0 then
				heap[1] = last
				local k = 1
				while true do
					local l, r, small = 2 * k, 2 * k + 1, k
					if l <= #heap and heap[l][1] < heap[small][1] then
						small = l
					end
					if r <= #heap and heap[r][1] < heap[small][1] then
						small = r
					end
					if small == k then
						break
					end
					heap[small], heap[k] = heap[k], heap[small]
					k = small
				end
			end
			return top
		end
		local si, sj = cellOf(fromX, fromZ)
		dist[si][sj] = 0
		push(0, si, sj)
		while #heap > 0 do
			local top = pop()
			local d, i, j = top[1], top[2], top[3]
			if d > dist[i][j] then
				continue
			end
			for di = -1, 1 do
				for dj = -1, 1 do
					local a, b = i + di, j + dj
					if (di == 0 and dj == 0) or a < 1 or a > nx or b < 1 or b > nz or not free[a][b] then
						continue
					end
					if di ~= 0 and dj ~= 0 and not (free[a][j] and free[i][b]) then
						continue
					end
					local nd = d + (if di ~= 0 and dj ~= 0 then math.sqrt(2) * CELL else CELL)
					if nd < dist[a][b] then
						dist[a][b] = nd
						push(nd, a, b)
					end
				end
			end
		end
		return function(x: number, z: number): number
			local i, j = cellOf(x, z)
			return if dist[i] and dist[i][j] then dist[i][j] else math.huge
		end
	end
end

-- Whether a pickup at (x, z) is clear by a metre all round: the ground
-- floor under it, and no wall, cover or height (system 59) within a metre.
local function clear(map: any, parts: { any }, x: number, z: number): boolean
	for _, d in { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } } do
		if map.floorAt(x + d[1], z + d[2]) ~= 0 then
			return false
		end
	end
	for _, part in parts do
		if gap(part, x, z, 1) < 0 then
			return false
		end
	end
	return true
end

-- The furthest any pickup is from as quick a run from one side's spawn as
-- from the other's, and the most a map's set of them leans to one side, in
-- metres: about a second and a half of running, and one.
local EACH = 11
local ALL = 7
local speed = MovementConfig.resolve().baseRunSpeed

do
	local onFloor, inRooms, apart, even, overall, leans = true, true, true, true, true, true
	local worst = { each = 0, all = 0 }
	for _, key in SpikeMaps.MAPS do
		local map = SpikeMaps.Maps[key]
		local plan = PICKUPS[key]
		check(
			string.format("%s has its pickups: four spawners, two of each orb", map.NAME),
			plan ~= nil and #plan.spawners == 4 and #plan.recovery == 2 and #plan.ultimate == 2
		)
		if not plan then
			continue
		end
		local parts = solids(map)
		local all: { vector } = {}
		for _, list in { plan.spawners, plan.recovery, plan.ultimate } do
			for _, at in list do
				table.insert(all, at)
			end
		end
		-- Out of the spawn rooms and their doors.
		local closed = { "AttackerSpawn", "DefenderSpawn" }
		for _, role in { "attack", "defend" } do
			for _, door in map.Doors[role] do
				table.insert(closed, door)
			end
		end
		for _, at in all do
			onFloor = onFloor and at.y == 0 and clear(map, parts, at.x, at.z)
			for _, name in closed do
				local r = map.room(name)
				if r and at.x >= r.x0 - 1 and at.x <= r.x1 + 1 and at.z >= r.z0 - 1 and at.z <= r.z1 + 1 then
					inRooms = false
				end
			end
		end
		for a = 1, #all do
			for b = a + 1, #all do
				apart = apart and vector.magnitude(all[a] - all[b]) >= 5
			end
		end
		-- As quick a run from either side's spawn, on a map with heights up
		-- and down them (system 59).
		local fromAttack: (number, number) -> number, fromDefend: (number, number) -> number
		if map.raised then
			local level, run = Levels.ofMap(map), Levels.runsOf(map)
			local function along(list: { number }): (number, number) -> number
				return function(x: number, z: number): number
					local id = Levels.nodeAt(level, x, z, 0)
					return if id then list[id] else math.huge
				end
			end
			fromAttack, fromDefend = along(run.attack), along(run.defend)
		else
			local walk = runs(map)
			local attack, defend = map.spots("attack")[1].feet, map.spots("defend")[1].feet
			fromAttack, fromDefend = walk(attack.x, attack.z), walk(defend.x, defend.z)
		end
		local sum = 0
		local lines = {}
		for _, at in all do
			local a, d = fromAttack(at.x, at.z), fromDefend(at.x, at.z)
			local lean = a - d
			even = even and a < math.huge and d < math.huge and math.abs(lean) <= EACH
			worst.each = math.max(worst.each, math.abs(lean))
			sum += lean
			table.insert(lines, string.format("%+.1f", lean))
		end
		overall = overall and math.abs(sum) <= ALL
		-- The Ultimate Orbs, which the spike rounds have too (system 49).
		for _, at in plan.ultimate do
			leans = leans and fromAttack(at.x, at.z) < fromDefend(at.x, at.z)
		end
		worst.all = math.max(worst.all, math.abs(sum))
		print(
			string.format(
				"  %s: runs from the attackers' spawn less the defenders', m: %s (all %+.1f)",
				map.NAME,
				table.concat(lines, " "),
				sum
			)
		)
	end
	check("every pickup out on the floor, a metre clear of walls and cover", onFloor)
	check("none in a spawn room or its doors, nor a metre from one", inRooms)
	check("each at least 5 m from the next", apart)
	check(
		string.format("each no more than %d m further a run from one side's spawn than the other's (%.1f s)", EACH, EACH / speed),
		even,
		string.format("%.1f m at worst", worst.each)
	)
	check(
		string.format("and each map's set evened out between the sides, within %d m", ALL),
		overall,
		string.format("%.1f m at worst", worst.all)
	)
	check("each map's Ultimate Orbs a shorter run from the attackers' spawn than the defenders' (system 49)", leans)
end

-- Weapon spawners --------------------------------------------------------------------------

do
	local s = R.new(nil, dice())
	R.join(s, 1, 0)
	R.join(s, 2, 0)
	local empty = true
	for i in OUTPOST.spawners do
		empty = empty and R.spawnerGun(s, i) == nil
	end
	check("no guns on the spawners in the pre-game", s.phase == "pregame" and #s.spawners == 4 and empty)
	check("so none to take", not R.take(s, 1, 1, 1))
end

do
	-- The dice: the map, then a gun for each spawner as the match starts.
	local s = match(2, 3, 1, 2, 3)
	check(
		"each spawner has a gun of the first stage's as the match starts, at random",
		R.spawnerGun(s, 1) == GUNS[1][3]
			and R.spawnerGun(s, 2) == GUNS[1][1]
			and R.spawnerGun(s, 3) == GUNS[1][2]
			and R.spawnerGun(s, 4) == GUNS[1][3]
	)
	local kit = R.kitOf(s, 1) :: { string }
	check("the first stage's kit has no primary", kit[1] == "" and kit[2] == "classic")
	check("someone takes the Stinger", R.take(s, 1, 1, LIVE + 1))
	check("and the spawner stands empty", R.spawnerGun(s, 1) == nil and not R.take(s, 2, 1, LIVE + 1))
	kit = R.kitOf(s, 1) :: { string }
	check("the Stinger is theirs, lent in the primary slot", R.lentOf(s, 1, 1) == "stinger" and kit[1] == "stinger" and kit[2] == "classic")
	check("the kit lends it", R.lends(s, 1, 1) and not R.lends(s, 1, 2) and not R.lends(s, 2, 1))
	check("so their spawn room doesn't take it back", R.rearms(s, 1, LIVE + 2, true) and (R.kitOf(s, 1) :: { string })[1] == "stinger")
	check("nor anyone else's kit", (R.kitOf(s, 2) :: { string })[1] == "")
	check("the Shorty, a sidearm, in place of the Classic", R.take(s, 1, 2, LIVE + 2) and (R.kitOf(s, 1) :: { string })[2] == "shorty")
	check("with the Stinger kept", (R.kitOf(s, 1) :: { string })[1] == "stinger")

	R.step(s, LIVE + 1 + T.spawnerWait.value - 0.1)
	check("the spawner's empty until its wait is over", R.spawnerGun(s, 1) == nil)
	R.step(s, LIVE + 1 + T.spawnerWait.value)
	check("then it has another of the stage's", R.spawnerGun(s, 1) == GUNS[1][1])
end

do
	local s = match(2, 3, 3, 3, 3)
	R.take(s, 1, 1, LIVE + 1)
	check("the gun lent stays out of the room", not R.rearms(s, 1, LIVE + 2, false))
	R.returned(s, 1, 1)
	check("once it's gone, out of the room too", R.rearms(s, 1, LIVE + 3, false) and R.lentOf(s, 1, 1) == nil)
	check("the loadout's guns", (R.kitOf(s, 1) :: { string })[1] == "")
	R.armed(s, 1)
	check("and that's that", not R.rearms(s, 1, LIVE + 4, false))
	R.returned(s, 1, 1)
	check("nothing owed for a gun not lent", not R.rearms(s, 1, LIVE + 5, false))
end

do
	local s = match(2, 3, 3, 3, 3)
	R.take(s, 1, 1, LIVE + 1)
	local had = R.lentOf(s, 1, 1) == "stinger"
	R.died(s, 1, LIVE + 2, 2)
	check("a death takes the gun lent with it", had and R.lentOf(s, 1, 1) == nil)
	R.step(s, LIVE + 2 + T.respawnTime.value)
	check("and the next life is on the loadout", (R.kitOf(s, 1) :: { string })[1] == "")
	R.died(s, 2, LIVE + 4, 1)
	check("nobody dead takes a gun", not R.take(s, 2, 2, LIVE + 4) and R.spawnerGun(s, 2) ~= nil)
end

do
	local s = match(2, 3, 3, 3, 3)
	R.take(s, 1, 1, LIVE + 1)
	-- The Ares for the second stage, picked in the room.
	R.pick(s, 1, 2, 3, true)
	local stage2 = LIVE + T.stageTime.value
	R.step(s, stage2)
	local restocked = true
	for i in OUTPOST.spawners do
		local gun = R.spawnerGun(s, i)
		restocked = restocked and gun ~= nil and table.find(GUNS[2], gun) ~= nil
	end
	check("a new stage puts one of its guns on every spawner, the empty one too", restocked)
	local kit = R.kitOf(s, 1) :: { string }
	check("and its loadout in place of the gun lent in the last", kit[1] == "ares" and kit[2] == "classic")
	check("which is in hand till then, but not the kit's", R.lentOf(s, 1, 1) == "stinger" and not R.lends(s, 1, 1))
	check("handed over as the stage's is", not R.rearms(s, 1, stage2 + 1, false) and R.rearms(s, 1, stage2 + T.swapDelay.value, false))
	-- Before it's handed over, someone takes a gun of the new stage's.
	R.take(s, 2, 3, stage2 + 1)
	R.armed(s, 1)
	R.armed(s, 2)
	check(
		"which the handover leaves them",
		R.lentOf(s, 2, 1) == GUNS[2][1].gun and R.lends(s, 2, 1) and (R.kitOf(s, 2) :: { string })[1] == GUNS[2][1].gun
	)
	check("while the last stage's is gone", R.lentOf(s, 1, 1) == nil)
end

do
	local s = match(2)
	R.take(s, 1, 1, LIVE + 1)
	for _ = 1, 4 do
		R.skip(s, LIVE + 2)
		R.step(s, LIVE + 2)
	end
	local empty = true
	for i in OUTPOST.spawners do
		empty = empty and R.spawnerGun(s, i) == nil
	end
	check("the match over, the spawners are empty", s.phase == "matchOver" and empty)
	local again = R.new(nil, dice())
	R.join(again, 1, 0)
	R.join(again, 2, 0)
	R.step(again, LIVE)
	R.take(again, 1, 1, LIVE + 1)
	R.leave(again, 2, LIVE + 2)
	check(
		"with a side empty, the pickups go, and the guns lent with them",
		again.phase == "waiting" and R.lentOf(again, 1, 2) == nil and R.spawnerGun(again, 2) == nil
	)
	check("the loadout's back at once", R.rearms(again, 1, LIVE + 3, false))
end

-- Recovery Orbs ----------------------------------------------------------------------------

do
	local s = match(6)
	local at = OUTPOST.recovery[1]
	check("Recovery Orbs are up as the match starts", s.recovery[1].up and s.recovery[2].up)
	check("nothing a step away", R.pickUp(s, 1, at + vector.create(T.orbRange.value + 0.1, 0, 0), LIVE + 1) == nil)
	check("running over one takes it", R.pickUp(s, 1, at + vector.create(0.5, 0, 0), LIVE + 1) == "recovery")
	check("and it's down", not s.recovery[1].up and R.pickUp(s, 2, at, LIVE + 1) ~= "recovery")
	local total = R.mended(s, 1, LIVE + 2.5)
	check("its buff mends, evenly", H.near(total, 1.5 / T.recoveryTime.value, 1e-9))
	total += R.mended(s, 1, LIVE + 4)
	total += R.mended(s, 1, LIVE + 10)
	check("all the share in its 6 s, and no more", H.near(total, T.recoveryShare.value, 1e-9) and R.mended(s, 1, LIVE + 11) == 0)
	check("and then it's over", s.mending[1] == nil)

	-- The zone: players 3 and 5 are on side 1 with player 1, the even ones on
	-- side 2.
	local inZone = at + vector.create(T.zoneRadius.value - 0.2, 0, 0)
	R.pickUp(s, 3, inZone, LIVE + 2)
	check("an ally walking into its zone is mended too", s.mending[3] ~= nil)
	R.mended(s, 3, LIVE + 3)
	R.pickUp(s, 3, inZone, LIVE + 3)
	check("once", s.mending[3].ends == LIVE + 2 + T.recoveryTime.value)
	R.pickUp(s, 2, inZone, LIVE + 2)
	check("but not an enemy", s.mending[2] == nil)
	R.step(s, LIVE + 1 + T.zoneTime.value)
	R.pickUp(s, 5, inZone, LIVE + 1 + T.zoneTime.value)
	check("and the zone ends", #s.zones == 0 and s.mending[5] == nil)

	R.step(s, LIVE + 1 + T.recoveryWait.value - 0.1)
	check("the orb's down until its wait is over", not s.recovery[1].up)
	R.step(s, LIVE + 1 + T.recoveryWait.value)
	check("then up again", s.recovery[1].up)
	R.pickUp(s, 2, at, LIVE + 40)
	R.died(s, 2, LIVE + 41, 1)
	check("a death ends the buff", s.mending[2] == nil and R.mended(s, 2, LIVE + 42) == 0)
	check("nor do the dead take orbs", R.pickUp(s, 2, OUTPOST.recovery[2], LIVE + 42) == nil and s.recovery[2].up)
end

-- Ultimate Orbs ----------------------------------------------------------------------------

do
	local s = match(2)
	local at = OUTPOST.ultimate[1]
	check("no Ultimate Orbs as the match starts", not s.ultimate[1].up and not s.ultimate[2].up and R.pickUp(s, 1, at, LIVE) == nil)
	R.step(s, LIVE + T.ultimateFirst.value)
	check("they come up together a while in", s.ultimate[1].up and s.ultimate[2].up)
	check("and running over one takes it", R.pickUp(s, 1, at, LIVE + 31) == "ultimate" and not s.ultimate[1].up)
	R.step(s, LIVE + T.ultimateFirst.value + T.ultimateEvery.value - 0.1)
	check("down until they come up again", not s.ultimate[1].up and s.ultimate[2].up)
	R.step(s, LIVE + T.ultimateFirst.value + T.ultimateEvery.value)
	check("all together", s.ultimate[1].up and s.ultimate[2].up)
	check("nothing outside a match", R.pickUp(R.new(nil, dice()), 1, at, 0) == nil)
end

-- Abilities starting over ------------------------------------------------------------------

do
	local s = R.new(nil, dice())
	R.join(s, 1, 0)
	check("someone's first life starts their abilities over", R.startsOver(s, 1))
	check("once", not R.startsOver(s, 1))
	R.join(s, 2, 1)
	check("and a match starting, everyone's", s.phase == "pregame" and R.startsOver(s, 1) and R.startsOver(s, 2))
	R.step(s, 1 + LIVE)
	R.died(s, 1, LIVE + 2, 2)
	R.step(s, LIVE + 2 + T.respawnTime.value)
	check("but not a life after a death", s.phase == "live" and s.members[1].alive and not R.startsOver(s, 1))
end

return nil
