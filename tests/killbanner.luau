--!strict
-- The kill banner (system 55): which kills count, each killer's count over a
-- stretch of play and starting it over, the headshot mark, how many marks a
-- banner lights and when it's the top one, how it comes up and fades, and
-- the kill sound rising with the count.

local KillBanner = require("../src/shared/Combat/KillBanner")
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local SoundMath = require("../src/shared/Audio/SoundMath")
local H = require("./Harness")

local check = H.check
local near = H.near

H.section("Kill banner (system 55)")

local P = KillBanner.Params
local ME, YOU, THEM = 1, 2, 3

-- A kill that counts, by `ME` of an enemy: its banner.
local function kill(log: KillBanner.Log, victim: number, region: string): KillBanner.Banner
	local banner = KillBanner.killed(log, ME, victim, false, region)
	assert(banner, "a kill of an enemy has a banner")
	return banner
end

do
	local counts = KillBanner.counts
	check("a kill of an enemy counts", counts(ME, YOU, false))
	check("a death nobody caused doesn't", not counts(nil, YOU, false))
	check("nor killing yourself", not counts(ME, ME, false))
	check("nor a teammate", not counts(ME, YOU, true))
end

do
	local log = KillBanner.newLog()
	local first = KillBanner.killed(log, ME, YOU, false, "body")
	check("a first kill is banner 1, of whoever was killed", first ~= nil and first.count == 1 and first.target == YOU and not first.head)
	local second = KillBanner.killed(log, ME, THEM, false, "head")
	check("the next is 2, a headshot marked", second ~= nil and second.count == 2 and second.head)
	check("legs aren't a headshot", not kill(log, 4, "legs").head)
	check("a burst or a burn is no headshot", not kill(log, 5, "body").head)
	check("each kill counts up", KillBanner.count(log, ME) == 4)

	local theirs = KillBanner.killed(log, YOU, ME, false, "body")
	check("someone else's count is their own", theirs ~= nil and theirs.count == 1 and KillBanner.count(log, ME) == 4)

	check(
		"a kill that doesn't count has no banner and leaves the count",
		KillBanner.killed(log, ME, 6, true, "head") == nil
			and KillBanner.killed(log, ME, ME, false, "body") == nil
			and KillBanner.killed(log, nil, ME, false, "body") == nil
			and KillBanner.count(log, ME) == 4
	)
	check("the same one killed again counts again", kill(log, YOU, "body").count == 5)

	KillBanner.open(log, ME)
	check("a new life starts its count over", KillBanner.count(log, ME) == 0 and KillBanner.count(log, YOU) == 1)
	check("from 1", kill(log, YOU, "body").count == 1)

	KillBanner.clear(log)
	check("a new round starts everyone's over", KillBanner.count(log, ME) == 0 and KillBanner.count(log, YOU) == 0)
end

do
	local most = P.marks.value
	check("a banner lights a mark for each kill", KillBanner.marks(1) == 1 and KillBanner.marks(3) == 3)
	check("up to all of them, the ace's", KillBanner.marks(most) == most)
	check("and a kill past it lights them all", KillBanner.marks(most + 1) == most and KillBanner.marks(most + 4) == most)
	check("the top banner is the ace's and past it", not KillBanner.top(most - 1) and KillBanner.top(most) and KillBanner.top(most + 2))
end

do
	local hold, fade = P.hold.value, P.fade.value
	check("a banner shows whole for hold", KillBanner.alpha(0) == 1 and KillBanner.alpha(hold) == 1)
	check("then fades in a straight line", near(KillBanner.alpha(hold + fade / 2), 0.5, 1e-9))
	check("and is gone after fade", KillBanner.alpha(hold + fade) == 0 and KillBanner.alpha(hold + fade + 3) == 0)

	local settle = P.settle.value
	check("it comes up bigger", near(KillBanner.scale(0), P.pop.value, 1e-9) and P.pop.value > 1)
	check(
		"and settles to its size",
		KillBanner.scale(settle / 2) < P.pop.value
			and KillBanner.scale(settle / 2) > 1
			and KillBanner.scale(settle) == 1
			and KillBanner.scale(settle + 1) == 1
	)
end

do
	local step = SoundConfig.KillPitchStep.value
	check(
		"the kill sound rises with each kill counted",
		SoundMath.killPitch(1) == 1 and near(SoundMath.killPitch(2), 1 + step, 1e-9) and near(SoundMath.killPitch(5), 1 + 4 * step, 1e-9)
	)
	check("past the ace's it stays at the ace's", SoundMath.killPitch(P.marks.value + 1) == SoundMath.killPitch(P.marks.value))
end

do
	local ok = true
	for _, param in P do
		ok = ok and (param.status == "confirmed" or param.status == "community" or param.status == "estimate") and #param.source > 0
	end
	check("every number carries a status and a source", ok)
end

return nil
