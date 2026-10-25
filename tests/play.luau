--!strict
-- The Play menu (system 24): a server for each mode, and the list of
-- servers PLAY picks from. The menu's modes are what the arena plays; a
-- player is sent to the fullest server of their mode with a place for them,
-- never the one they're on, nor one that's gone quiet or can't be reached.

local ArenaConfig = require("../src/shared/Arena/ArenaConfig")
local DeathmatchConfig = require("../src/shared/Arena/DeathmatchConfig")
local GunGameConfig = require("../src/shared/Arena/GunGameConfig")
local MatchConfig = require("../src/shared/Match/MatchConfig")
local PlayConfig = require("../src/shared/Match/PlayConfig")
local ServerList = require("../src/shared/Match/ServerList")
local H = require("./Harness")

local check = H.check

local R = PlayConfig.Rules

H.section("Play menu tests")

-- The modes ----------------------------------------------------------------------

do
	local keys: { [string]: boolean } = {}
	local unique = true
	for _, mode in PlayConfig.Modes do
		unique = unique and not keys[mode.key] and PlayConfig.ByKey[mode.key] == mode
		keys[mode.key] = true
	end
	check("six modes, each by a key of its own", #PlayConfig.Modes == 6 and unique)

	local arenas = true
	for _, mode in PlayConfig.Modes do
		if mode.arena == "spike" then
			arenas = arenas and mode.format ~= nil and MatchConfig.Formats[mode.format] ~= nil and mode.key == mode.format
		else
			arenas = arenas and (mode.arena == "skirmish" or mode.arena == "gungame" or mode.arena == "deathmatch") and mode.format == nil
		end
	end
	check("each is a mode the arena plays, and the spike rounds' by their formats' keys", arenas)

	local formats = true
	for key in MatchConfig.Formats do
		local mode = PlayConfig.ByKey[key]
		formats = formats and mode ~= nil and mode.arena == "spike"
	end
	check("every format of the spike rounds is on the menu", formats)

	local sizes = PlayConfig.ByKey.skirmish.players == 2 * ArenaConfig.Rules.sideSize.value
		and PlayConfig.ByKey.gungame.players == 2 * GunGameConfig.Rules.sideSize.value
		and PlayConfig.ByKey.standard.players == 2 * MatchConfig.Rules.sideSize.value
		and PlayConfig.ByKey.competitive.players == 2 * MatchConfig.Rules.sideSize.value
		and PlayConfig.ByKey.swiftplay.players == 2 * MatchConfig.Rules.sideSize.value
	check("a match holds two sides of its mode's side size: 2v2, 4v4 and 5v5", sizes)
	local dm = PlayConfig.ByKey.deathmatch
	local ffa = dm ~= nil and dm.players == DeathmatchConfig.Rules.players.value and dm.freeForAll == true
	for _, mode in PlayConfig.Modes do
		ffa = ffa and (mode.freeForAll == true) == (mode == dm)
	end
	check("and Deathmatch everyone for themselves, 14 of them, the one free for all", ffa)

	local default = PlayConfig.ByKey[PlayConfig.DEFAULT]
	check("a public server plays Skirmish, as the arena has from system 21", default ~= nil and default.arena == "skirmish")

	local blurbs = string.find(PlayConfig.ByKey.skirmish.blurb, tostring(ArenaConfig.Rules.winScore.value), 1, true) ~= nil
		and string.find(PlayConfig.ByKey.gungame.blurb, tostring(#GunGameConfig.Tiers), 1, true) ~= nil
		and string.find(PlayConfig.ByKey.standard.blurb, tostring(MatchConfig.Formats.standard.winScore.value), 1, true) ~= nil
		and string.find(PlayConfig.ByKey.swiftplay.blurb, tostring(MatchConfig.Formats.swiftplay.winScore.value), 1, true) ~= nil
		and string.find(PlayConfig.ByKey.deathmatch.blurb, tostring(DeathmatchConfig.Rules.killTarget.value), 1, true) ~= nil
		and string.find(PlayConfig.ByKey.deathmatch.blurb, tostring(DeathmatchConfig.Rules.timeLimit.value // 60), 1, true) ~= nil
	check("each blurb has its mode's own numbers", blurbs)
end

do
	local keyOf = PlayConfig.keyOf
	check("the arena off is no mode, the course", keyOf(false, "skirmish", "standard") == nil and keyOf(nil, "gungame", nil) == nil)
	check(
		"Skirmish, gun game and Deathmatch by the arena's mode",
		keyOf(true, "skirmish", "competitive") == "skirmish"
			and keyOf(true, "gungame", nil) == "gungame"
			and keyOf(true, "deathmatch", "standard") == "deathmatch"
	)
	check(
		"the spike rounds by their format",
		keyOf(true, "spike", "standard") == "standard"
			and keyOf(true, "spike", "competitive") == "competitive"
			and keyOf(true, "spike", "swiftplay") == "swiftplay"
	)
	check(
		"an unknown format is the default one, and an unknown mode Skirmish, as the arena plays them",
		keyOf(true, "spike", "nonsense") == MatchConfig.DEFAULT_FORMAT
			and keyOf(true, "spike", nil) == MatchConfig.DEFAULT_FORMAT
			and keyOf(true, 7, nil) == "skirmish"
	)
end

do
	check(
		"a line is distrusted before it's gone, and a server's own updates keep it trusted",
		R.soonest.value < R.refresh.value and R.refresh.value < R.stale.value and R.stale.value < R.expiry.value
	)
	local labelled = true
	for _, param in R do
		labelled = labelled
			and param.value > 0
			and (param.status == "confirmed" or param.status == "community" or param.status == "estimate")
	end
	check("every rule is labelled, and more than zero", labelled)
end

-- Lines ----------------------------------------------------------------------

local function line(key: string, mode: string, players: number, playing: number, at: number?): ServerList.Line
	local public = string.sub(key, 1, 2) == "p:"
	return {
		key = key,
		mode = mode,
		players = players,
		playing = playing,
		cap = PlayConfig.ByKey[mode].players,
		max = 12,
		job = if public then string.sub(key, 3) else nil,
		code = if public then nil else "code-" .. key,
		at = at or 1000,
	}
end

do
	check("keys say which kind of server", ServerList.publicKey("abc") == "p:abc" and ServerList.reservedKey("xyz") == "r:xyz")
	local a = line("r:xyz", "gungame", 3, 2)
	local b = ServerList.decode(a.key, ServerList.encode(a))
	check(
		"a line comes back from the store as it went in",
		b ~= nil
			and b.key == a.key
			and b.mode == a.mode
			and b.players == 3
			and b.playing == 2
			and b.cap == a.cap
			and b.max == 12
			and b.job == nil
			and b.code == a.code
			and b.at == a.at
	)
	local value = ServerList.encode(line("p:job", "skirmish", 2, 2))
	check(
		"one with no key, or that isn't a table, is nothing",
		ServerList.decode(nil, value) == nil and ServerList.decode("p:job", "text") == nil
	)
	local broken = true
	for _, field in { "mode", "players", "playing", "cap", "max", "at" } do
		local copy = table.clone(value)
		copy[field] = nil
		broken = broken and ServerList.decode("p:job", copy) == nil
	end
	check("one missing anything it needs is nothing", broken)
	local bad = true
	for _, wrong in { { players = -1 }, { playing = 0 / 0 }, { at = "now" }, { mode = "" }, { max = true } } do
		local copy = table.clone(value)
		for k, v in wrong do
			copy[k] = v
		end
		bad = bad and ServerList.decode("p:job", copy) == nil
	end
	check("one with a count below zero, not a number, or an empty mode is nothing", bad)
	local odd = table.clone(value)
	odd.players, odd.job = 2.7, 42
	local fixed = ServerList.decode("p:job", odd)
	check("counts are whole, and a job that isn't text is none", fixed ~= nil and fixed.players == 2 and fixed.job == nil)
	local l = line("p:job", "skirmish", 1, 1, 100)
	check(
		"a line is trusted until it's stale, and not after",
		ServerList.fresh(l, 100 + R.stale.value, R.stale.value) and not ServerList.fresh(l, 101 + R.stale.value, R.stale.value)
	)
end

-- Where PLAY sends someone ----------------------------------------------------------------------

do
	local S = R.stale.value
	local choose = ServerList.choose
	local lines = {
		line("p:one", "skirmish", 3, 3),
		line("r:two", "skirmish", 2, 2),
		line("r:three", "gungame", 5, 5),
	}
	local to = choose(lines, "skirmish", 1, nil, 1000, S)
	check("to the fullest match of the mode picked", to ~= nil and to.key == "p:one")
	to = choose(lines, "skirmish", 1, "p:one", 1000, S)
	check("never the server they're on", to ~= nil and to.key == "r:two")
	to = choose(lines, "gungame", 1, nil, 1000, S)
	check("only a server playing that mode", to ~= nil and to.key == "r:three")
	check("none playing it is none, for a new server", choose(lines, "competitive", 1, nil, 1000, S) == nil)

	local full = { line("p:full", "skirmish", 4, 4), line("r:room", "skirmish", 1, 1) }
	to = choose(full, "skirmish", 1, nil, 1000, S)
	check("not a full match, however full", to ~= nil and to.key == "r:room")
	local crowded = line("p:crowded", "skirmish", 12, 1)
	check("not a full server, however much room its match has", choose({ crowded }, "skirmish", 1, nil, 1000, S) == nil)
	local onePlace = { line("r:one", "skirmish", 3, 3) }
	check(
		"a place for each of a group, or none for them",
		choose(onePlace, "skirmish", 1, nil, 1000, S) ~= nil and choose(onePlace, "skirmish", 2, nil, 1000, S) == nil
	)

	local stale = { line("p:old", "skirmish", 3, 3, 1000 - S - 1), line("r:new", "skirmish", 1, 1) }
	to = choose(stale, "skirmish", 1, nil, 1000, S)
	check("not a server that's gone quiet", to ~= nil and to.key == "r:new")

	local noJob = line("p:nojob", "skirmish", 3, 3)
	noJob.job = nil
	local noCode = line("r:nocode", "skirmish", 3, 3)
	noCode.code = nil
	check("not a server with no way there", choose({ noJob, noCode }, "skirmish", 1, nil, 1000, S) == nil)

	local busier = { line("r:a", "skirmish", 2, 2), line("p:b", "skirmish", 6, 2) }
	to = choose(busier, "skirmish", 1, nil, 1000, S)
	check("level matches: the fuller server", to ~= nil and to.key == "p:b")
	local level = { line("r:b", "skirmish", 2, 2), line("r:a", "skirmish", 2, 2) }
	local first = choose(level, "skirmish", 1, nil, 1000, S)
	local reversed = choose({ level[2], level[1] }, "skirmish", 1, nil, 1000, S)
	check(
		"level in every way: the first by key, in any order",
		first ~= nil and first.key == "r:a" and reversed ~= nil and reversed.key == "r:a"
	)
end

-- The menu's counts ----------------------------------------------------------------------

do
	local S = R.stale.value
	local lines = {
		line("p:one", "skirmish", 6, 4),
		line("r:two", "skirmish", 3, 3),
		line("r:three", "gungame", 5, 5),
		line("r:old", "standard", 9, 9, 1000 - S - 1),
	}
	local counts = ServerList.counts(lines, 1000, S)
	check(
		"everyone in each mode's servers, the menu too, and nobody in a server gone quiet",
		counts.skirmish == 9 and counts.gungame == 5 and counts.standard == nil
	)
	local order = {}
	for _, mode in PlayConfig.Modes do
		table.insert(order, mode.key)
	end
	local text = ServerList.formatCounts(counts, order)
	check(
		"as Workspace has them, in the menu's order",
		text == "skirmish=9,gungame=5,deathmatch=0,standard=0,competitive=0,swiftplay=0",
		text
	)
	local back = ServerList.parseCounts(text)
	check("and back", back.skirmish == 9 and back.gungame == 5 and back.standard == 0 and back.swiftplay == 0)
	local junk = ServerList.parseCounts("skirmish=x,=3,gungame=2")
	check(
		"nothing from nothing, and only the parts that make sense",
		next(ServerList.parseCounts(nil)) == nil and junk.gungame == 2 and junk.skirmish == nil
	)
end

return nil
