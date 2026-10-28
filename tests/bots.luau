--!strict
-- Bots (system 60): their ids, how many fill a match and which leave,
-- what they buy, what they see and how fast, how they turn and shoot, by
-- skill, in duels on a floor, and how they walk every map and go round it
-- together, on each map's own solids (TileWorld) with the movement a
-- player has. Each number checked is against what BotConfig says a skill
-- is like (docs/research/60-bots.md).

local ArenaLayout = require("../src/shared/Arena/ArenaLayout")
local BotBrain = require("../src/shared/Bots/BotBrain")
local BotBuy = require("../src/shared/Bots/BotBuy")
local BotConfig = require("../src/shared/Bots/BotConfig")
local BotFill = require("../src/shared/Bots/BotFill")
local BotMove = require("../src/shared/Bots/BotMove")
local BotNav = require("../src/shared/Bots/BotNav")
local BotSpots = require("../src/shared/Bots/BotSpots")
local BotTeam = require("../src/shared/Bots/BotTeam")
local Health = require("../src/shared/Combat/Health")
local ShotResolver = require("../src/shared/Combat/ShotResolver")
local Sight = require("../src/shared/Combat/Sight")
local SpikeMaps = require("../src/shared/Match/SpikeMaps")
local MovementConfig = require("../src/shared/Movement/MovementConfig")
local PlayerCodec = require("../src/shared/Net/PlayerCodec")
local PlayerSim = require("../src/shared/PlayerSim")
local Accuracy = require("../src/shared/Weapons/Accuracy")
local WeaponConfig = require("../src/shared/Weapons/WeaponConfig")
local WeaponSim = require("../src/shared/Weapons/WeaponSim")
local FakeWorld = require("./FakeWorld")
local H = require("./Harness")
local TileWorld = require("./TileWorld")

local check = H.check

local B = PlayerSim.Buttons
local P = BotConfig.Params
local DT = 1 / MovementConfig.TickRate.value
local cfg = MovementConfig.resolve()
local EYE = vector.create(0, 1.62, 0)
local SKILLS = BotConfig.SKILLS

-- Park-Miller dice, seeded: the same numbers each run. A small seed's
-- first few numbers are small too, so they're thrown away.
local function diceOf(seed: number): BotConfig.Dice
	local s = seed
	local function roll(): number
		s = s * 16807 % 2147483647
		return s / 2147483647
	end
	for _ = 1, 3 do
		roll()
	end
	return roll
end

local function median(xs: { number }): number
	if #xs == 0 then
		return math.huge
	end
	local sorted = table.clone(xs)
	table.sort(sorted)
	return sorted[(#sorted + 1) // 2]
end

local function lowest(xs: { number }): number
	local out = math.huge
	for _, x in xs do
		out = math.min(out, x)
	end
	return out
end

-- Whether each is more than the next.
local function falling(xs: { number }): boolean
	for k = 2, #xs do
		if not (xs[k - 1] > xs[k]) then
			return false
		end
	end
	return true
end

local function list(xs: { number }, unit: string): string
	local out = {}
	for _, x in xs do
		table.insert(out, string.format("%.2f%s", x, unit))
	end
	return table.concat(out, ", ")
end

-- Ids -----------------------------------------------------------------------------------

H.section("Bots: ids (system 60)")

do
	local n = 7
	local rule = PlayerCodec.botRuleId(n)
	local entity = PlayerCodec.entityIdForUser(rule)
	check("a bot's id in the rules is negative, below any Studio test player's", rule < -PlayerCodec.BOT_LIMIT)
	check("and its entity id is BOT_BASE + n, as entityIdForUser makes it", entity == PlayerCodec.BOT_BASE + n)
	check("which is a bot's", PlayerCodec.isBot(entity) and PlayerCodec.isBotRule(rule))
	check("and no dummy's or drone's", not PlayerCodec.isDummy(entity) and not PlayerCodec.isDrone(entity))
	local last = PlayerCodec.BOT_BASE + PlayerCodec.BOT_LIMIT
	check("bots' ids are below the drones'", last < PlayerCodec.DRONE_BASE and PlayerCodec.isBot(last))
	check(
		"a player's UserId, or a Studio test player's, is no bot's",
		not PlayerCodec.isBotRule(123456789) and not PlayerCodec.isBotRule(-1) and not PlayerCodec.isBotRule(-2)
	)
	check(
		"nor is a dummy's or a drone's entity",
		not PlayerCodec.isBot(PlayerCodec.DUMMY_BASE + 1) and not PlayerCodec.isBot(PlayerCodec.DRONE_BASE + 1)
	)
end

-- Filling a match ---------------------------------------------------------------------------

H.section("Bots: how many fill a match, and which leave (system 60)")

do
	local spike = BotConfig.Quotas.spike.value
	check("with nobody playing there are no bots", BotFill.wanted(spike, 0) == 0)
	check("one player in the spike rounds has nine bots with them", BotFill.wanted(spike, 1) == 9)
	check("a full match has none", BotFill.wanted(spike, 10) == 0 and BotFill.wanted(spike, 12) == 0)
	local join, leave = BotFill.plan(spike, 1, {}, "waiting")
	check("a player alone: nine join", join == 9 and #leave == 0)

	local function seat(id: number, side: number?, alive: boolean, order: number): BotFill.Seat
		return { id = id, side = side, alive = alive, order = order }
	end
	-- Skirmish (four) with two players and three bots: one too many.
	local three = { seat(-1, 1, true, 1), seat(-2, 2, true, 2), seat(-3, 2, true, 3) }
	join, leave = BotFill.plan(4, 2, three, "live")
	check("a bot alive mid-round stays though there's one too many", join == 0 and #leave == 0)
	join, leave = BotFill.plan(4, 2, three, "buy")
	check("in the buy phase the last to join on the side with the most bots leaves", join == 0 and #leave == 1 and leave[1] == -3)
	local down = { seat(-1, 1, true, 1), seat(-2, 2, false, 2), seat(-3, 2, true, 3) }
	_, leave = BotFill.plan(4, 2, down, "planted")
	check("mid-round, one that's down leaves", #leave == 1 and leave[1] == -2)
	local waiting = { seat(-1, 1, true, 1), seat(-2, 2, false, 2), seat(-3, nil, true, 3) }
	_, leave = BotFill.plan(4, 2, waiting, "live")
	check("one waiting for a place leaves first", #leave == 1 and leave[1] == -3)
	_, leave = BotFill.plan(4, 4, three, "roundOver")
	check("players enough for the quota: every bot leaves while nothing's at stake", #leave == 3)
	check(
		"waiting, buying, between rounds and after the match are calm",
		BotFill.calm("waiting") and BotFill.calm("buy") and BotFill.calm("roundOver") and BotFill.calm("matchOver")
	)
	check("a live round and a planted spike aren't", not BotFill.calm("live") and not BotFill.calm("planted"))
end

-- Buying ----------------------------------------------------------------------------------

H.section("Bots: what they buy (system 60)")

do
	local price = BotBuy.price
	local function spent(ids: { string }): number
		local total = 0
		for _, id in ids do
			total += price(id)
		end
		return total
	end
	local bare = { primary = "", sidearm = "classic", shield = "" }
	local sawGhost, sawLight, firstOk = false, false, true
	for seed = 1, 30 do
		local buys = BotBuy.choose(800, bare, true, diceOf(seed))
		local ghost = #buys == 1 and buys[1] == "ghost"
		local light = #buys == 1 and buys[1] == "light"
		sawGhost = sawGhost or ghost
		sawLight = sawLight or light
		firstOk = firstOk and (ghost or light)
	end
	check("a half's first round: a Light Armor, or now and then a Ghost", firstOk and sawLight and sawGhost)

	local full = BotBuy.choose(price("vandal") + price("heavy"), bare, false, diceOf(5))
	check(
		"a rifle's and Heavy Armor's worth buys both",
		#full == 2 and (full[1] == "vandal" or full[1] == "phantom") and full[2] == "heavy",
		table.concat(full, ", ")
	)
	local light = BotBuy.choose(price("vandal") + price("light"), bare, false, diceOf(5))
	check("a rifle's and Light Armor's: those", #light == 2 and light[2] == "light", table.concat(light, ", "))
	local smg = BotBuy.choose(price("spectre") + price("light") + 100, bare, false, diceOf(5))
	check("a Spectre's and Light Armor's: those", #smg == 2 and smg[1] == "spectre" and smg[2] == "light", table.concat(smg, ", "))
	check("less than that: it saves", #BotBuy.choose(price("spectre") + price("light") - 1, bare, false, diceOf(5)) == 0)
	local armed = { primary = "vandal", sidearm = "classic", shield = "" }
	local kept = BotBuy.choose(5000, armed, false, diceOf(5))
	check("a survivor keeps its rifle and buys Heavy Armor", #kept == 1 and kept[1] == "heavy", table.concat(kept, ", "))
	local cheap = BotBuy.choose(price("light") + 100, armed, false, diceOf(5))
	check("or Light Armor if that's all it can", #cheap == 1 and cheap[1] == "light", table.concat(cheap, ", "))
	check(
		"and nothing with Heavy Armor on",
		#BotBuy.choose(5000, { primary = "vandal", sidearm = "classic", shield = "heavy" }, false, diceOf(5)) == 0
	)

	-- Never more than it has, and never a second gun for a slot it fills.
	local within, noSecond = true, true
	local haves = {
		bare,
		armed,
		{ primary = "", sidearm = "", shield = "light" },
		{ primary = "spectre", sidearm = "ghost", shield = "light" },
	}
	for credits = 0, 9000, 100 do
		for k, has in haves do
			for _, first in { true, false } do
				local buys = BotBuy.choose(credits, has, first, diceOf(credits + k + 1))
				within = within and spent(buys) <= credits
				if has.primary ~= "" then
					for _, id in buys do
						local def = WeaponConfig.Defs[id]
						noSecond = noSecond and not (def and def.category ~= "sidearm")
					end
				end
			end
		end
	end
	check("never more than its credits, from 0 to 9000", within)
	check("never a primary when it has one", noSecond)
end

-- Seeing ----------------------------------------------------------------------------------

H.section("Bots: what they see, and how fast they notice it (system 60)")

-- Someone `distance` metres from the eye, `angle` radians round from the
-- middle of a view at yaw 0 (looking down -z), standing still.
local function someone(id: number, distance: number, angle: number, visible: boolean?): BotBrain.Target
	local feet = vector.create(-distance * math.sin(angle), 0, -distance * math.cos(angle))
	local points = Sight.points({ position = feet, yaw = 0, crouchAlpha = 0 })
	return { id = id, head = points[1], chest = points[2], velocity = vector.zero, visible = visible ~= false }
end

-- When a bot looking every lookEvery from `from` first notices `target`,
-- seconds after `from`, within `limit`; nil if it doesn't.
local function noticeTime(brain: BotBrain.Brain, target: BotBrain.Target, from: number, limit: number): number?
	local t = from
	while t <= from + limit + 1e-9 do
		BotBrain.look(brain, t, EYE, { target })
		local k = brain.known[target.id]
		if k and k.noticed then
			return t - from
		end
		t += P.lookEvery.value
	end
	return nil
end

local function noticeTimes(skill: string, angle: number, runs: number): { number }
	local out = {}
	for seed = 1, runs do
		local brain = BotBrain.new(BotConfig.Skills[skill], diceOf(seed * 13 + 1), 0)
		table.insert(out, noticeTime(brain, someone(1, 15, angle), 0, 3) or math.huge)
	end
	return out
end

do
	local half = math.rad(P.fov.value) / 2
	local normal = BotConfig.Skills.normal
	check("someone behind it is never noticed", noticeTime(BotBrain.new(normal, diceOf(3), 0), someone(1, 10, math.pi), 0, 3) == nil)
	check("nor someone in front behind a wall", noticeTime(BotBrain.new(normal, diceOf(3), 0), someone(1, 10, 0, false), 0, 3) == nil)
	check(
		"nor someone just outside its field of view",
		noticeTime(BotBrain.new(normal, diceOf(3), 0), someone(1, 10, half + math.rad(4)), 0, 3) == nil
	)
	check("but someone just inside it is", noticeTime(BotBrain.new(normal, diceOf(3), 0), someone(1, 10, half - math.rad(4)), 0, 3) ~= nil)

	local centre = noticeTimes("normal", 0, 31)
	local edge = noticeTimes("normal", math.rad(45), 31)
	print(
		string.format(
			"  Normal notices someone in the middle of its view in %.2f s (median), 45 degrees off in %.2f s",
			median(centre),
			median(edge)
		)
	)
	check("never at the first look", lowest(centre) > 0)
	check(
		"in the middle of its view, Normal notices in about a person's recognition reaction (0.38 s)",
		median(centre) >= 0.35 and median(centre) <= 0.5,
		string.format("%.2f s", median(centre))
	)
	check("toward the edge of its view it takes longer", median(edge) >= median(centre) * 1.25)
	local bySkill = {}
	for _, skill in SKILLS do
		table.insert(bySkill, median(noticeTimes(skill, 0, 21)))
	end
	print("  Easy, Normal, Hard and Expert notice in " .. list(bySkill, " s"))
	check("each skill notices sooner than the one below it", falling(bySkill))
	check("Expert no sooner than a person's simple reaction (0.22 s)", bySkill[4] >= 0.2)

	-- Lost sight of a moment, known again at once; for longer, noticed anew.
	local brain = BotBrain.new(normal, diceOf(9), 0)
	local seen = someone(1, 15, 0)
	local hidden = someone(1, 15, 0, false)
	local first = noticeTime(brain, seen, 0, 3) :: number
	local t = first
	while t < first + 0.4 do
		t += P.lookEvery.value
		BotBrain.look(brain, t, EYE, { hidden })
	end
	t += P.lookEvery.value
	check("someone it lost sight of a moment ago is known again at once", noticeTime(brain, seen, t, 0) == 0)
	while t < first + 0.4 + 1.5 do
		t += P.lookEvery.value
		BotBrain.look(brain, t, EYE, { hidden })
	end
	t += P.lookEvery.value
	local again = noticeTime(brain, seen, t, 3)
	check("after longer than its attack memory (0.7 s), noticed anew", again ~= nil and again > 0)
	local k = brain.known[1]
	while t < 30 do
		t += P.lookEvery.value
		BotBrain.look(brain, t, EYE, { hidden })
		k = brain.known[1]
	end
	check("and forgotten once unseen for its memory (10 s)", k == nil)
	local fresh = BotBrain.new(normal, diceOf(9), 0)
	local at = noticeTime(fresh, seen, 0, 3) :: number
	BotBrain.look(fresh, at + P.lookEvery.value, EYE, {})
	check("someone gone from the snapshots (dead) is forgotten at once", brain.known[1] == nil and fresh.known[1] == nil)
end

-- Turning ---------------------------------------------------------------------------------

H.section("Bots: turning onto a target, by Fitts's law (system 60)")

do
	local function meanTurn(skill: string, degrees: number, width: number): number
		local brain = BotBrain.new(BotConfig.Skills[skill], diceOf(77), 0)
		local total = 0
		for _ = 1, 200 do
			total += BotBrain.turnTime(brain, math.rad(degrees), width / 15)
		end
		return total / 200
	end
	local chest, head = 0.44, 0.24
	local turns = { meanTurn("normal", 10, chest), meanTurn("normal", 45, chest), meanTurn("normal", 120, chest) }
	print("  Normal turns 10, 45 and 120 degrees onto a chest 15 m off in " .. list(turns, " s"))
	check("a wider turn takes longer", turns[1] < turns[2] and turns[2] < turns[3])
	check("onto a head than a chest, longer", meanTurn("normal", 45, head) > turns[2])
	-- Boudaoud et al.'s players found and clicked targets 7 to 25 degrees
	-- off in 0.4 to 0.8 s, a reaction included: the turn, less a simple
	-- reaction (0.22 s), is about 0.2 to 0.6 s.
	local theirs = { meanTurn("normal", 7, chest), meanTurn("normal", 25, chest) }
	check(
		"Normal turns 7 to 25 degrees onto a chest 15 m off in what a player does",
		theirs[1] >= 0.15 and theirs[2] <= 0.6,
		list(theirs, " s")
	)
	local bySkill = {}
	for _, skill in SKILLS do
		table.insert(bySkill, meanTurn(skill, 45, chest))
	end
	check("each skill turns faster than the one below it", falling(bySkill), list(bySkill, " s"))
end

-- Duels -----------------------------------------------------------------------------------

H.section("Bots: duels with a Vandal, by skill (system 60)")

local floor = FakeWorld.new():addFloor()

-- How far up the gun's next round goes (BotServer's climbOf), at the
-- simulation's own time `t`.
local function climbOf(def: WeaponConfig.WeaponDef, w: WeaponSim.State, t: number): number
	local settled = t - w.lastShotTime > def.accuracy.recoveryTime.value
	return Accuracy.curve(def.recoil.pitch.points, if settled then 1 else w.sprayIndex + 1)
end

type Duel = {
	first: number?, -- seconds from the target coming into view to the first shot
	kill: number?, -- and to the kill
	fired: number,
	hits: number,
	moving: number, -- shots fired while moving faster than the deadzone
}

-- A bot with a Vandal on a floor, facing down -z, and someone in Heavy
-- Armor `distance` metres off, `angle` radians round, who comes into view
-- and stays: standing, or strafing across its view at a run, turning back
-- every 0.35 to 0.65 s. The bot stands, or walks forward until it fights,
-- as the server drives it (BotServer.drive). Four seconds at most.
local function duel(skill: string, seed: number, distance: number, angle: number, strafe: boolean, walking: boolean): Duel
	local sim = PlayerSim.new(vector.create(0, 0.02, 0), { "vandal", "classic", "knife", "" }, seed)
	for k = 1, 40 do
		PlayerSim.step(sim, { seq = k, buttons = 0, yaw = 0, pitch = 0, slot = 1, viewTime = 0 }, cfg, floor, DT)
	end
	local dice = diceOf(seed * 7 + 3)
	local brain = BotBrain.new(BotConfig.Skills[skill], dice, 0)
	local feet = vector.create(-distance * math.sin(angle), 0, -distance * math.cos(angle))
	local across = vector.create(math.cos(angle), 0, -math.sin(angle))
	local hp = Health.new(100, "heavy")
	local t0 = (sim.movement.tick + 1) * DT
	local nextLook = t0 + dice() * P.lookEvery.value
	local way, nextTurn = 1, t0 + 0.35 + 0.3 * dice()
	local out: Duel = { first = nil, kill = nil, fired = 0, hits = 0, moving = 0 }
	local seq = 40
	while out.kill == nil do
		local t = (sim.movement.tick + 1) * DT
		if t - t0 > 4 then
			break
		end
		seq += 1
		local velocity = vector.zero
		if strafe then
			if t >= nextTurn then
				way = -way
				nextTurn = t + 0.35 + 0.3 * dice()
			end
			velocity = across * (5.4 * way)
			feet += velocity * DT
		end
		local pose = { position = feet, yaw = 0, crouchAlpha = 0 }
		local points = Sight.points(pose)
		local eye = PlayerSim.eye(sim, cfg)
		if t >= nextLook then
			BotBrain.look(brain, t, eye, { { id = 1, head = points[1], chest = points[2], velocity = velocity, visible = true } })
			nextLook += P.lookEvery.value
		end
		local w = sim.weapons
		local def = WeaponSim.equippedDef(w)
		local mode = WeaponConfig.mode(def, w.scoped)
		local act = BotBrain.tick(brain, {
			now = t,
			eye = eye,
			accurate = PlayerSim.isAccurate(sim, cfg),
			weapon = def.id,
			category = def.category,
			semi = mode.fireMode == "semi",
			interval = mode.interval,
			recovery = def.accuracy.recoveryTime.value,
			ammo = w.ammo[w.equipped],
			magazine = def.magazine.value,
			reloading = WeaponSim.isReloading(w),
			climb = climbOf(def, w, t),
			sidearm = true,
			equipped = w.equipped,
		}, DT, nil, nil)
		local buttons = 0
		if act.stop then
			if act.dodge > 0 then
				buttons += B.Right
			elseif act.dodge < 0 then
				buttons += B.Left
			end
		elseif walking then
			buttons += B.Forward
		end
		if act.crouch then
			buttons += B.Crouch
		end
		if act.fire then
			buttons += B.Fire
		end
		if act.reload then
			buttons += B.Reload
		end
		local input = { seq = seq, buttons = buttons, yaw = act.yaw, pitch = act.pitch, slot = act.slot or w.equipped, viewTime = 0 }
		local shots = PlayerSim.step(sim, input, cfg, floor, DT)
		for _, shot in shots or {} do
			out.first = out.first or (t - t0)
			out.fired += 1
			if shot.moveState ~= "still" then
				out.moving += 1
			end
			local hit = ShotResolver.resolve(shot.origin, shot.direction, { { id = 1, pose = pose } }, math.huge, nil)
			if hit then
				out.hits += 1
				local result = Health.apply(hp, WeaponConfig.damageAt(WeaponConfig.get(shot.weapon), hit.region, hit.distance))
				if result.killed and out.kill == nil then
					out.kill = t - t0
				end
			end
		end
	end
	return out
end

type Tally = { first: { number }, kill: { number }, kills: number, fired: number, hits: number, moving: number }

local function duels(skill: string, runs: number, distance: number, angle: number, strafe: boolean, walking: boolean): Tally
	local out: Tally = { first = {}, kill = {}, kills = 0, fired = 0, hits = 0, moving = 0 }
	for run = 1, runs do
		local d = duel(skill, run * 101 + 17, distance, angle, strafe, walking)
		table.insert(out.first, d.first or math.huge)
		table.insert(out.kill, d.kill or math.huge)
		out.kills += if d.kill then 1 else 0
		out.fired += d.fired
		out.hits += d.hits
		out.moving += d.moving
	end
	return out
end

local function hitRate(t: Tally): number
	return t.hits / math.max(t.fired, 1)
end

do
	local RUNS = 15
	local still: { [string]: Tally } = {}
	local firsts, kills, rates = {}, {}, {}
	for _, skill in SKILLS do
		local t = duels(skill, RUNS, 15, 0, false, false)
		still[skill] = t
		table.insert(firsts, median(t.first))
		table.insert(kills, median(t.kill))
		table.insert(rates, hitRate(t))
		print(
			string.format(
				"  %-6s against someone still 15 m off: first shot %.2f s, kill %s, %d of %d won in 4 s, %.0f%% of shots hit",
				BotConfig.Skills[skill].name,
				median(t.first),
				if median(t.kill) < math.huge then string.format("%.2f s", median(t.kill)) else "none",
				t.kills,
				RUNS,
				100 * hitRate(t)
			)
		)
	end
	check("each skill fires sooner than the one below it", falling(firsts), list(firsts, " s"))
	check("and kills sooner", falling(kills), list(kills, " s"))
	check("and hits more of its shots", falling({ rates[4], rates[3], rates[2], rates[1] }), list(rates, ""))
	local normal = still.normal
	check(
		"Normal opens fire after a person's recognition reaction (0.38 s), never at once",
		lowest(normal.first) >= 0.4 and median(normal.first) >= 0.5,
		string.format("%.2f s at the soonest", lowest(normal.first))
	)
	check(
		"Normal takes over a second to win, so a player who's ready wins first",
		median(normal.kill) >= 1,
		string.format("%.2f s", median(normal.kill))
	)
	check("but wins most duels in four seconds", normal.kills >= RUNS * 0.8)
	check("Easy misses most of its shots", hitRate(still.easy) < 0.45, string.format("%.0f%%", 100 * hitRate(still.easy)))
	check("Expert is quick but human: never under a simple reaction", lowest(still.expert.first) >= 0.22)

	local walker = duels("normal", RUNS, 15, math.rad(10), false, true)
	check(
		"a bot walking when someone shows stops before it shoots",
		walker.fired > 0 and walker.moving == 0,
		string.format("%d of %d on the move", walker.moving, walker.fired)
	)
	local stood = 0
	for _, skill in SKILLS do
		stood += still[skill].moving
	end
	check("and every bot shoots standing still", stood == 0)

	local near = duels("normal", RUNS, 10, 0, false, false)
	local strafing = duels("normal", RUNS, 10, 0, true, false)
	print(
		string.format(
			"  Normal at 10 m hits %.0f%% of shots at someone still, %.0f%% at someone strafing",
			100 * hitRate(near),
			100 * hitRate(strafing)
		)
	)
	check("someone strafing is harder to hit", hitRate(strafing) < hitRate(near))
	check("but not impossible: Normal hits some", hitRate(strafing) >= 0.1)
end

-- Looking round ---------------------------------------------------------------------------

H.section("Bots: checking corners, and turning to a hit (system 60)")

-- A body standing at the eye with a full Vandal, at time `now`.
local function standing(now: number, ammo: number?, equipped: number?): BotBrain.Body
	return {
		now = now,
		eye = EYE,
		accurate = true,
		weapon = "vandal",
		category = "rifle",
		semi = false,
		interval = 0.1,
		recovery = 0.35,
		ammo = ammo or 25,
		magazine = 25,
		reloading = false,
		climb = 0,
		sidearm = true,
		equipped = equipped or 1,
	}
end

-- A point `distance` metres off at eye height, `angle` radians round.
local function pointAt(distance: number, angle: number): vector
	return EYE + vector.create(-distance * math.sin(angle), 0, -distance * math.cos(angle))
end

do
	local normal = BotConfig.Skills.normal
	local brain = BotBrain.new(normal, diceOf(4), 0)
	local ahead = pointAt(10, 0)
	local corner = math.rad(60)
	local glances = { corner = pointAt(10, corner) }
	local t = 0
	local function run(seconds: number, spots: { [string]: vector }?)
		local stop = t + seconds
		while t < stop do
			t += DT
			BotBrain.tick(brain, standing(t), DT, ahead, spots)
		end
	end
	run(0.45, glances)
	check(
		"a spot an enemy might be in, coming into sight, is glanced at",
		math.abs(BotBrain.wrap(brain.yaw - corner)) < math.rad(8),
		string.format("%.0f degrees", math.deg(brain.yaw))
	)
	run(P.glance.value + 0.5, glances)
	check(
		"and then it looks where it was told again",
		math.abs(brain.yaw) < math.rad(5),
		string.format("%.0f degrees", math.deg(brain.yaw))
	)
	run(5, glances)
	check("and not at that spot again for a while", math.abs(brain.yaw) < math.rad(5))

	BotBrain.hurt(brain, t, pointAt(8, math.pi))
	run(0.8, nil)
	check(
		"a hit from behind turns it round",
		math.abs(BotBrain.wrap(brain.yaw - math.pi)) < math.rad(10),
		string.format("%.0f degrees", math.deg(brain.yaw))
	)

	-- An enemy it lost sight of: it watches where they were, for a while.
	local watcher = BotBrain.new(normal, diceOf(6), 0)
	local side = math.rad(30)
	local foe, gone = someone(2, 12, side), someone(2, 12, side, false)
	local now = noticeTime(watcher, foe, 0, 3) :: number
	local nextLook = now
	local function follow(seconds: number, target: BotBrain.Target)
		local stop = now + seconds
		while now < stop do
			now += DT
			if now >= nextLook then
				BotBrain.look(watcher, now, EYE, { target })
				nextLook += P.lookEvery.value
			end
			BotBrain.tick(watcher, standing(now), DT, ahead, nil)
		end
	end
	follow(0.3, foe)
	follow(1.5, gone)
	check(
		"an enemy it lost sight of: once it's stopped fighting, it watches where they were",
		not BotBrain.fighting(watcher) and math.abs(BotBrain.wrap(watcher.yaw - side)) < math.rad(5),
		string.format("%.0f degrees", math.deg(watcher.yaw))
	)
	follow(2.5, gone)
	check(
		"and a few seconds on, looks where it was told again",
		math.abs(watcher.yaw) < math.rad(5),
		string.format("%.0f degrees", math.deg(watcher.yaw))
	)

	local calm = BotBrain.tick(BotBrain.new(normal, diceOf(4), 0), standing(1, 10), DT, nil, nil)
	check("with nobody about and its magazine under half, it reloads", calm.reload)
	local full = BotBrain.tick(BotBrain.new(normal, diceOf(4), 0), standing(1, 20), DT, nil, nil)
	check("but not with most of it left", not full.reload)

	-- Out of rounds in a fight 8 m off: Normal draws its sidearm; Easy reloads.
	local function emptyInAFight(skill: string): BotBrain.Act
		local b = BotBrain.new(BotConfig.Skills[skill], diceOf(4), 0)
		local target = someone(1, 8, 0)
		local at = noticeTime(b, target, 0, 3) :: number
		return BotBrain.tick(b, standing(at, 0), DT, nil, nil)
	end
	local drawn = emptyInAFight("normal")
	check("out of rounds in a fight up close, it draws its sidearm", drawn.slot == 2 and drawn.stop)
	local easy = emptyInAFight("easy")
	check("Easy reloads instead", easy.slot == nil and easy.reload)
end

-- Walking ---------------------------------------------------------------------------------

H.section("Bots: walking every map round its walls (system 60)")

-- A body walking a map as the server drives a bot: its simulation, the
-- way it's going, and its view, which looks the way it walks.
type Walker = { id: number, sim: PlayerSim.State, mover: BotMove.Mover, yaw: number, seq: number }

local function walkerAt(nav: BotNav.Nav, id: number, feet: vector, yaw: number): Walker
	return {
		id = id,
		sim = PlayerSim.new(feet + vector.create(0, 0.05, 0), { "vandal", "classic", "knife", "" }, id),
		mover = BotMove.new(nav, diceOf(id * 31 + 7)),
		yaw = yaw,
		seq = 0,
	}
end

-- One tick toward `goal` (a node, or nil to stay) at time `t`; walking
-- quietly if `quiet`. Whether it's there.
local function stride(w: Walker, world: any, t: number, goal: number?, quiet: boolean): boolean
	local step = BotMove.step(w.mover, t, w.sim.movement.position, goal)
	local buttons = 0
	local direction = step.direction
	if direction then
		local want = math.atan2(-direction.x, -direction.z)
		w.yaw += BotBrain.wrap(want - w.yaw) * math.min(DT / P.lookEase.value, 1)
		local forward, right = BotMove.keys(direction, w.yaw)
		if forward > 0 then
			buttons += B.Forward
		elseif forward < 0 then
			buttons += B.Back
		end
		if right > 0 then
			buttons += B.Right
		elseif right < 0 then
			buttons += B.Left
		end
		if quiet then
			buttons += B.Walk
		end
	end
	if step.jump then
		buttons += B.Jump
	end
	w.seq += 1
	PlayerSim.step(w.sim, { seq = w.seq, buttons = buttons, yaw = w.yaw, pitch = 0, slot = 1, viewTime = 0 }, cfg, world, DT)
	return step.arrived
end

type Walk = { arrived: boolean, seconds: number, run: number, stalls: number, replans: number }

-- A walk from `feet` to `goal`: whether it got there, in how long, how
-- long a run along the path takes, how often it stalled, and how often it
-- stayed stuck long enough to plan its way again (what the server tells of
-- in Studio).
local function walk(nav: BotNav.Nav, world: any, feet: vector, goal: number): Walk
	local w = walkerAt(nav, 1, feet, 0)
	local start = BotNav.nodeAt(nav, feet, 3)
	local route = if start then BotNav.path(nav, start, goal) else nil
	local length = 0
	for k = 2, (if route then #route else 0) do
		local r = route :: { number }
		length += vector.magnitude(BotNav.feet(nav, r[k]) - BotNav.feet(nav, r[k - 1]))
	end
	local out: Walk = { arrived = false, seconds = 0, run = length / PlayerSim.maxSpeed(w.sim, cfg), stalls = 0, replans = 0 }
	local stuck = false
	local t = 0
	while t < 40 and not out.arrived do
		t += DT
		out.arrived = stride(w, world, t, goal, false)
		if w.mover.stuckSince and not stuck then
			out.stalls += 1
		end
		stuck = w.mover.stuckSince ~= nil
	end
	out.seconds = t
	out.replans = w.mover.stuck
	return out
end

do
	for _, key in SpikeMaps.MAPS do
		local map = SpikeMaps.Maps[key]
		local plan = BotSpots.ofMap(map)
		local nav = plan.nav
		local x0, z0, x1, z1 = map.bounds()
		local world = TileWorld.new(nav.solids, x0, z0, x1, z1)
		local attackers, defenders = map.spots("attack"), map.spots("defend")
		-- The attackers' way to each site, and the defenders' to a spot
		-- holding the first.
		local ways = {}
		for _, site in plan.sites do
			table.insert(ways, walk(nav, world, attackers[1].feet, site.centre))
		end
		table.insert(ways, walk(nav, world, defenders[1].feet, plan.sites[1].holds[1].node))
		local arrived, stalls, replans, slowest = 0, 0, 0, 0
		for _, w in ways do
			arrived += if w.arrived then 1 else 0
			stalls += w.stalls
			replans += w.replans
			slowest = math.max(slowest, w.seconds / math.max(w.run, 0.5))
		end
		local walks = #ways
		local times = {}
		for _, w in ways do
			table.insert(times, w.seconds)
		end
		print(
			string.format(
				"  %s: walks of %s, the slowest %.2fx a run along its path, stuck %d times",
				key,
				list(times, " s"),
				slowest,
				stalls
			)
		)
		check(
			string.format("%s: from the attackers' spawn to each site and the defenders' to a hold, round walls and up stairs", key),
			arrived == walks and stalls <= 1 and replans == 0 and slowest <= 1.5,
			string.format("%d of %d arrived, %d stalls, %d replans, the slowest %.2fx a run", arrived, walks, stalls, replans, slowest)
		)
	end
	local w, l, _, rd = ArenaLayout.size()
	for _, name in ArenaLayout.MAPS do
		local nav = BotNav.ofParts("arena" .. name, ArenaLayout.parts(name), -w / 2 - 1, -l / 2 - rd - 1, w / 2 + 1, l / 2 + rd + 1)
		local world = TileWorld.new(nav.solids, -w / 2 - 1, -l / 2 - rd - 1, w / 2 + 1, l / 2 + rd + 1)
		local ok = true
		local detail = ""
		local times = {}
		local stalls = 0
		for side = 1, 2 do
			local from = ArenaLayout.spots(side)[1].feet
			local to = BotNav.nodeAt(nav, ArenaLayout.spots(3 - side)[1].feet, 3)
			local done = if to then walk(nav, world, from, to) else nil
			ok = ok and done ~= nil and done.arrived and done.stalls <= 1 and done.replans == 0
			if done then
				table.insert(times, done.seconds)
				stalls += done.stalls
				detail ..= string.format("%s in %.1f s; ", if done.arrived then "arrived" else "stuck", done.seconds)
			end
		end
		print(string.format("  the arena's map %s: walks of %s, stuck %d times", name, list(times, " s"), stalls))
		check(string.format("the arena's map %s: from each spawn room to the other", name), ok, detail)
	end
end

-- Together --------------------------------------------------------------------------------

H.section("Bots: going round a map together (system 60)")

do
	local map = SpikeMaps.Maps.outpost
	local plan = BotSpots.ofMap(map)
	local nav = plan.nav
	local x0, z0, x1, z1 = map.bounds()
	local world = TileWorld.new(nav.solids, x0, z0, x1, z1)

	local function siteOf(p: vector): string?
		local n = BotNav.nodeAt(nav, p, 3)
		if not n then
			return nil
		end
		for _, s in plan.sites do
			if s.field[n] <= BotSpots.AREA then
				return s.name
			end
		end
		return nil
	end
	local function members(walkers: { Walker }, bots: boolean): { BotTeam.Member }
		local out = {}
		for _, w in walkers do
			table.insert(out, { id = w.id, bot = bots, alive = true, feet = w.sim.movement.position })
		end
		return out
	end
	-- Each side's plan is gone over every P.think, from the first tick.
	local THINK = math.round(P.think.value / DT)
	local function thinks(tick: number): boolean
		return tick % THINK == 1
	end
	local function team(side: BotTeam.Side, spots: { any }, count: number, withPlan: boolean): (BotTeam.Team, { Walker })
		local t = BotTeam.new(nav, if withPlan then plan else nil, side, diceOf(7), nil)
		BotTeam.round(t, 0)
		local walkers = {}
		for k = 1, count do
			table.insert(walkers, walkerAt(nav, k, spots[k].feet, spots[k].yaw))
		end
		return t, walkers
	end

	-- Attackers gather, then go in together.
	do
		local t, bots = team("attack", map.spots("attack"), 5, true)
		local entered: { [number]: number } = {}
		local orders: { [number]: BotTeam.Order } = {}
		local now, tick = 0, 0
		while now < 15 do
			now += DT
			tick += 1
			if thinks(tick) then
				orders = BotTeam.think(t, now, true, members(bots, true), {})
			end
			for _, w in bots do
				local o = orders[w.id]
				stride(w, world, now, o and o.goal, o ~= nil and o.walk)
				if entered[w.id] == nil and siteOf(w.sim.movement.position) == t.site then
					entered[w.id] = now
				end
			end
		end
		local times = {}
		for _, at in entered do
			table.insert(times, at)
		end
		table.sort(times)
		print(string.format("  Attackers on Outpost entered %s at %s", tostring(t.site), list(times, " s")))
		check("five attackers all get onto the site they picked", #times == 5)
		check("together: the first and last in within 3 s", #times == 5 and times[5] - times[1] <= 3)
		local apart = true
		for a = 1, #bots do
			for b = a + 1, #bots do
				apart = apart and vector.magnitude(bots[a].sim.movement.position - bots[b].sim.movement.position) > 1
			end
		end
		check("never on the same spot as another", apart)
	end

	-- Defenders split, hold, and come over when attackers turn up.
	do
		local t, bots = team("defend", map.spots("defend"), 5, true)
		local orders: { [number]: BotTeam.Order } = {}
		local sightings: { BotTeam.Sighting } = {}
		local contact = plan.sites[1]
		local held, sites = 0, {}
		local now, tick = 0, 0
		while now < 27 do
			now += DT
			tick += 1
			if now >= 15 and #sightings == 0 then
				held = 0
				for _, w in bots do
					local o = orders[w.id]
					local job = t.jobs[w.id]
					if o and o.goal and vector.magnitude(BotNav.feet(nav, o.goal) - w.sim.movement.position) < 1 then
						held += 1
					end
					if job and job.site then
						sites[job.site] = (sites[job.site] or 0) + 1
					end
				end
				table.insert(sightings, { at = BotNav.feet(nav, contact.entrances[1].node), time = now })
			end
			if thinks(tick) then
				orders = BotTeam.think(t, now, true, members(bots, true), sightings)
			end
			for _, w in bots do
				local o = orders[w.id]
				stride(w, world, now, o and o.goal, o ~= nil and o.walk)
			end
		end
		local other = if contact == plan.sites[1] then plan.sites[2] else plan.sites[1]
		check(
			"five defenders split over both sites, and all are on their spots in 15 s",
			(sites[contact.name] or 0) >= 1 and (sites[other.name] or 0) >= 1 and held == 5,
			string.format("%d on their spots", held)
		)
		local there, stayed = 0, 0
		for _, w in bots do
			local site = siteOf(w.sim.movement.position)
			there += if site == contact.name then 1 else 0
			stayed += if site == other.name then 1 else 0
		end
		check(
			"attackers seen at one site: the others come over, all but one",
			there == 4 and stayed == 1,
			string.format("%d at %s, %d at %s", there, contact.name, stayed, other.name)
		)
	end

	-- A player on the side leads: the bots go with them to the site they're making for.
	do
		local spots = map.spots("attack")
		local t, bots = team("attack", spots, 4, true)
		local player = walkerAt(nav, 100, spots[5].feet, spots[5].yaw)
		local planned = t.site
		local goal = plan.sites[1]
		for _, s in plan.sites do
			if s.name ~= planned then
				goal = s
			end
		end
		local orders: { [number]: BotTeam.Order } = {}
		local now, tick = 0, 0
		while now < 22 do
			now += DT
			tick += 1
			if thinks(tick) then
				local all = members(bots, true)
				table.insert(all, { id = player.id, bot = false, alive = true, feet = player.sim.movement.position })
				orders = BotTeam.think(t, now, true, all, {})
			end
			for _, w in bots do
				local o = orders[w.id]
				stride(w, world, now, o and o.goal, o ~= nil and o.walk)
			end
			stride(player, world, now, goal.centre, false)
		end
		local with = 0
		for _, w in bots do
			with += if siteOf(w.sim.movement.position) == goal.name then 1 else 0
		end
		print(string.format("  A player making for the site the bots hadn't picked: %d of 4 there with them in 22 s", with))
		check(
			"a player heading for the other site takes the bots with them",
			with >= 3,
			string.format("%d of 4 at %s with the player; the plan was %s", with, goal.name, tostring(planned))
		)
	end

	-- In the modes that respawn, bots follow a player on their side round the map.
	do
		local spots = map.spots("attack")
		local t, bots = team("team", spots, 3, false)
		local player = walkerAt(nav, 100, spots[5].feet, spots[5].yaw)
		local goal = plan.sites[2].centre
		local orders: { [number]: BotTeam.Order } = {}
		local sum, samples, worst = 0, 0, 0
		local now, tick = 0, 0
		while now < 20 do
			now += DT
			tick += 1
			if thinks(tick) then
				local all = members(bots, true)
				table.insert(all, { id = player.id, bot = false, alive = true, feet = player.sim.movement.position })
				orders = BotTeam.think(t, now, true, all, {})
			end
			for _, w in bots do
				local o = orders[w.id]
				stride(w, world, now, o and o.goal, false)
			end
			stride(player, world, now, goal, false)
			if now > 4 and tick % 32 == 0 then
				for _, w in bots do
					local d = vector.magnitude(w.sim.movement.position - player.sim.movement.position)
					sum += d
					samples += 1
					worst = math.max(worst, d)
				end
			end
		end
		local ends = 0
		for _, w in bots do
			ends = math.max(ends, vector.magnitude(w.sim.movement.position - player.sim.movement.position))
		end
		print(string.format("  Bots following a player across Outpost: %.1f m from them on average, %.1f m at most", sum / samples, worst))
		check("bots keep with a player they follow", sum / samples <= 9 and worst <= 16)
		check("and gather round them where they stop", ends <= 8, string.format("%.1f m", ends))
	end
end

return nil
