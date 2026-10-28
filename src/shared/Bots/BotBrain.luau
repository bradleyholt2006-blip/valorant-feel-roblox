--!strict
-- A bot's eyes, aim and trigger finger (system 60): what it has noticed,
-- where it looks and when it fires. The Counter-Strike bot's way, from its
-- designer's slides (Booth, "The Official Counter-Strike Bot", GDC 2004):
--   * it sees only what's in its field of view and in sight, and notices
--     an enemy there only after its reaction time (BotConfig), longer
--     toward the edge of view. One it's just lost sight of it knows again
--     at once, for a moment (CS:GO's 0.7 s), and where it saw them it
--     remembers longer
--   * where it looks goes apart from where it walks ('Directing Attention
--     (Looking around)'): at its enemy while it fights; for a while after
--     losing sight of one, where they were ('Last known Enemy location');
--     else where it's told to, the way ahead or the angle it holds, with a
--     glance at each spot an enemy might be in as one comes into view, as
--     a player checks their corners
--   * its aim: 'Select point P on victim' (the chest, or now and then the
--     head), turn onto it in the time Fitts's law gives a person for a
--     turn that wide onto a target that size, landing a little off, and
--     then wander round it, 'Periodically generate new random Aim Offset
--     based on bot's "skill"', the wander settling as it focuses in. It
--     follows a target that moves as a person does, carrying their
--     movement on, but sees a change in it (a strafe the other way) only
--     its lag later; and it pulls the gun's climb down by its share
--   * it stands still to shoot: while it fights it lets go of its keys,
--     and fires only once it's slower than its gun's deadzone and its aim
--     is where it means it to be, after its skill's delay. It doesn't know
--     its wander, so a shot goes where the wander has it: that, not the
--     trigger, is what misses. At range it fires single taps, nearer in
--     bursts, close up a spray, each followed by the gun's recovery. Hard
--     and Expert step aside between bursts, and stop again to fire
--
-- Plain state and maths: the server tells it what it sees (BotServer),
-- and turns what it wants into the buttons and angles of its simulation's
-- input (PlayerSim).

local BotConfig = require("./BotConfig")

local BotBrain = {}

local P = BotConfig.Params
local HALF_FOV = math.rad(P.fov.value) / 2
-- How far up or down from the middle of the view an enemy is still in it
-- (a 16:9 screen's half height at the field of view across).
local HALF_TALL = math.atan(math.tan(HALF_FOV) * 9 / 16)
local HEAD_WIDTH = 0.24 -- metres across (Hitboxes)
local CHEST_WIDTH = 0.44
local MAX_PITCH = math.rad(85)
-- Seconds: the time constant the view eases onto the aim with in a fight,
-- and how far back what was seen of a target is kept, for the lag.
local FIGHT_EASE = 0.04
local TRAIL = 0.5

-- An enemy as the server shows the bot this look: where their head and
-- chest are and how fast they move (metres, the snapshots' pose), and
-- whether a line from the bot's eye reaches either.
export type Target = {
	id: number,
	head: vector,
	chest: vector,
	velocity: vector,
	visible: boolean,
}

-- An enemy as one look saw them: when, where their chest and head were,
-- and how they were moving.
export type Glimpse = { time: number, at: vector, head: vector, moving: vector }

-- What a bot knows of an enemy.
export type Known = {
	id: number,
	since: number?, -- when they came into view this time, while they're in it
	delay: number, -- how long after `since` they're noticed
	noticed: boolean, -- noticed, and in view
	seen: number, -- when last in view and noticed
	at: vector, -- where (their chest), and how they were moving
	moving: vector,
	head: vector,
	trail: { Glimpse }, -- the looks since they came into view, the last TRAIL seconds', oldest first
}

export type Brain = {
	skill: BotConfig.Skill,
	dice: BotConfig.Dice,
	known: { [number]: Known },
	target: number?, -- whom it's fighting
	since: number, -- when the fight began: noticed, for the attack delay and the focus
	head: boolean, -- this fight's point: the head, else the chest
	-- The view, radians, and where it's easing toward.
	yaw: number,
	pitch: number,
	-- The turn onto the target under way: from where, when it began, how
	-- long it takes, and how far off it lands.
	turnFrom: { yaw: number, pitch: number }?,
	turnAt: number,
	turnFor: number,
	landYaw: number,
	landPitch: number,
	-- The wander round the target: where it is, where it's going, and when
	-- it's next made anew.
	wanderYaw: number,
	wanderPitch: number,
	nextYaw: number,
	nextPitch: number,
	wanderAt: number,
	-- The trigger: rounds fired in this burst (an automatic's counted off
	-- its magazine, from what it held as the burst began), the pause after
	-- it, whether fire was held last tick, and when a semi-automatic was
	-- last pressed.
	rounds: number,
	burstFrom: number?,
	pauseUntil: number,
	held: boolean,
	pressedAt: number,
	-- Stepping aside between bursts (Hard and Expert): which way, until when.
	dodge: number,
	dodgeUntil: number,
	crouch: boolean, -- this fight's: crouched for a close spray
	-- The glance under way at a spot an enemy might be in, and the spots
	-- glanced at lately, by a key of the server's.
	glance: vector?,
	glanceUntil: number,
	glanced: { [string]: number },
	-- Where a hit came from that it didn't see, and when.
	hurtFrom: vector?,
	hurtAt: number,
}

-- What the bot is doing this tick, for its input.
export type Act = {
	yaw: number,
	pitch: number,
	fire: boolean,
	stop: boolean, -- let go of the movement keys: it's fighting
	dodge: number, -- -1 left, 1 right, 0 neither
	crouch: boolean,
	reload: boolean,
	slot: number?, -- a weapon slot it wants in hand, if it wants another
}

-- What the bot's body and gun are like this tick.
export type Body = {
	now: number,
	eye: vector,
	accurate: boolean, -- slow enough to shoot straight (PlayerSim.isAccurate)
	weapon: string,
	category: string,
	semi: boolean, -- fires once a press
	interval: number, -- seconds between rounds
	recovery: number, -- seconds the gun takes to settle after a burst
	ammo: number,
	magazine: number,
	reloading: boolean,
	climb: number, -- degrees the next round goes up by, the gun's recoil
	sidearm: boolean, -- it has a sidearm with rounds in it
	equipped: number, -- the slot in hand
}

local function wrap(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end
BotBrain.wrap = wrap

-- The view's yaw and pitch that look from `eye` at `p` (Accuracy.aim's).
function BotBrain.anglesTo(eye: vector, p: vector): (number, number)
	local d = p - eye
	local flat = math.sqrt(d.x * d.x + d.z * d.z)
	return math.atan2(-d.x, -d.z), math.atan2(d.y, flat)
end

local function gauss(dice: BotConfig.Dice): number
	-- Box-Muller.
	local u = math.max(dice(), 1e-9)
	return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * dice())
end
BotBrain.gauss = gauss

function BotBrain.new(skill: BotConfig.Skill, dice: BotConfig.Dice, yaw: number?): Brain
	return {
		skill = skill,
		dice = dice,
		known = {},
		target = nil,
		since = 0,
		head = false,
		yaw = yaw or 0,
		pitch = 0,
		turnFrom = nil,
		turnAt = 0,
		turnFor = 0,
		landYaw = 0,
		landPitch = 0,
		wanderYaw = 0,
		wanderPitch = 0,
		nextYaw = 0,
		nextPitch = 0,
		wanderAt = 0,
		rounds = 0,
		burstFrom = nil,
		pauseUntil = 0,
		held = false,
		pressedAt = -math.huge,
		dodge = 0,
		dodgeUntil = 0,
		crouch = false,
		glance = nil,
		glanceUntil = 0,
		glanced = {},
		hurtFrom = nil,
		hurtAt = -math.huge,
	}
end

-- A new life: nothing known, nothing fought, facing `yaw`.
function BotBrain.reset(b: Brain, yaw: number)
	table.clear(b.known)
	table.clear(b.glanced)
	b.target = nil
	b.turnFrom = nil
	b.yaw, b.pitch = yaw, 0
	b.rounds, b.burstFrom, b.pauseUntil, b.held = 0, nil, 0, false
	b.dodge, b.dodgeUntil = 0, 0
	b.crouch = false
	b.glance = nil
	b.hurtFrom = nil
end

-- How far from the middle of the view the point p is: across (yaw) and up
-- (pitch), radians.
local function offView(b: Brain, eye: vector, p: vector): (number, number)
	local yaw, pitch = BotBrain.anglesTo(eye, p)
	return wrap(yaw - b.yaw), pitch - b.pitch
end

-- How long after coming into view an enemy this far off the middle of it
-- is noticed: the skill's reaction, longer toward the edge, and varying.
local function noticeDelay(b: Brain, across: number, up: number): number
	local off = math.clamp(math.max(math.abs(across) / HALF_FOV, math.abs(up) / HALF_TALL), 0, 1)
	local base = b.skill.reaction.value * (1 + (P.edgeReaction.value - 1) * off)
	return math.max(base * (1 + P.reactionSpread.value * gauss(b.dice)), 0.08)
end
BotBrain.noticeDelay = noticeDelay

-- A look: the enemies there are, and which the bot's eye reaches. Each in
-- view is noticed once its delay's gone by; one lost sight of a moment ago
-- is known again at once.
function BotBrain.look(b: Brain, now: number, eye: vector, targets: { Target })
	local here: { [number]: boolean } = {}
	for _, t in targets do
		here[t.id] = true
		local k = b.known[t.id]
		local across, up = offView(b, eye, t.chest)
		local inView = t.visible and math.abs(across) <= HALF_FOV and math.abs(up) <= HALF_TALL
		if not inView then
			if k then
				k.since = nil
				k.noticed = false
			end
			continue
		end
		if not k then
			k = {
				id = t.id,
				since = nil,
				delay = 0,
				noticed = false,
				seen = -math.huge,
				at = t.chest,
				moving = t.velocity,
				head = t.head,
				trail = {},
			}
			b.known[t.id] = k
		end
		local known = k :: Known
		if known.since == nil then
			known.since = now
			known.delay = if now - known.seen <= P.attackMemory.value then 0 else noticeDelay(b, across, up)
			table.clear(known.trail)
		end
		if now - (known.since :: number) >= known.delay then
			known.noticed = true
			known.seen = now
			known.at, known.moving, known.head = t.chest, t.velocity, t.head
			local trail = known.trail
			table.insert(trail, { time = now, at = t.chest, head = t.head, moving = t.velocity })
			while #trail > 1 and now - trail[1].time > TRAIL do
				table.remove(trail, 1)
			end
		end
	end
	-- Forgotten: gone (dead, or out of the snapshots), or out of view and
	-- not seen for long (or never noticed at all).
	for id, k in b.known do
		if not here[id] or k.since == nil and now - k.seen > P.memory.value then
			b.known[id] = nil
		end
	end
end

-- A hit taken from `from` (metres), which the bot turns to if it isn't
-- already fighting someone in sight.
function BotBrain.hurt(b: Brain, now: number, from: vector)
	b.hurtFrom = from
	b.hurtAt = now
end

-- Whom to fight: the one it's fighting while they're in view and noticed,
-- else the nearest noticed.
local function choose(b: Brain, eye: vector): Known?
	local current = if b.target then b.known[b.target] else nil
	if current and current.noticed then
		return current
	end
	local best: Known? = nil
	local bestDistance = math.huge
	for _, k in b.known do
		if k.noticed then
			local d = vector.magnitude(k.at - eye)
			if d < bestDistance then
				best, bestDistance = k, d
			end
		end
	end
	return best
end

-- Minimum jerk: how far along a movement of a person's is, a share of its
-- time in (Flash and Hogan's profile).
local function minJerk(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * t * (10 - 15 * t + 6 * t * t)
end

-- How long the turn onto a target takes: Fitts's law for the angle `d`
-- onto a target `w` wide (radians), a little different each time.
function BotBrain.turnTime(b: Brain, d: number, w: number): number
	local id = math.log(d / math.max(w, 1e-4) + 1, 2)
	local s = b.skill
	return math.max((s.fittsA.value + s.fittsB.value * id) * (1 + 0.15 * gauss(b.dice)), 0.05)
end

-- Eases an angle toward `to`: by a time constant, no faster than `speed`
-- radians a second.
local function ease(from: number, to: number, dt: number, tau: number, speed: number): number
	local d = wrap(to - from)
	local step = d * math.min(dt / tau, 1)
	local most = speed * dt
	return from + math.clamp(step, -most, most)
end

-- Starts a fight with `k`: its point, its turn, its first wander.
local function engage(b: Brain, now: number, eye: vector, k: Known)
	local s = b.skill
	b.target = k.id
	b.since = now
	b.head = b.dice() < s.head.value
	local point = if b.head then k.head else k.at
	local distance = math.max(vector.magnitude(point - eye), 1)
	local yaw, pitch = BotBrain.anglesTo(eye, point)
	local d = math.sqrt(wrap(yaw - b.yaw) ^ 2 + (pitch - b.pitch) ^ 2)
	local w = (if b.head then HEAD_WIDTH else CHEST_WIDTH) / distance
	b.turnFrom = { yaw = b.yaw, pitch = b.pitch }
	b.turnAt = now
	b.turnFor = BotBrain.turnTime(b, d, w)
	local spread = math.rad(s.trackError.value * s.turnError.value)
	b.landYaw, b.landPitch = spread * gauss(b.dice), spread * gauss(b.dice) * 0.6
	b.wanderYaw, b.wanderPitch = b.landYaw, b.landPitch
	b.nextYaw, b.nextPitch = b.landYaw, b.landPitch
	b.wanderAt = now + b.turnFor
	b.rounds, b.burstFrom = 0, nil
	b.pauseUntil = 0
	b.crouch = false
end

-- How wide the wander is now, `t` seconds into the fight: wide after the
-- turn, settling to the skill's.
local function wanderWidth(b: Brain, t: number): number
	local s = b.skill
	local settled = math.max(t - b.turnFor, 0)
	return math.rad(s.trackError.value * (1 + (s.turnError.value - 1) * math.exp(-settled / s.focus.value)))
end

-- Where the bot aims at its target `ahead` seconds from now: the point on
-- them where it last saw them before its lag, carried on as they were
-- moving then, as yaw and pitch, and how far. A target that keeps on as
-- they were is followed; one that turns back is followed the old way
-- until the bot sees it, as a person's aim overshoots a strafe.
local function aimAt(b: Brain, eye: vector, k: Known, now: number, ahead: number): (number, number, number)
	local trail = k.trail
	local g: Glimpse? = trail[1]
	for _, glimpse in trail do
		if glimpse.time <= now - b.skill.lag.value then
			g = glimpse
		end
	end
	local point = if b.head then k.head else k.at
	if g then
		point = (if b.head then g.head else g.at) + g.moving * (now + ahead - g.time)
	end
	local yaw, pitch = BotBrain.anglesTo(eye, point)
	return yaw, pitch, vector.magnitude(point - eye)
end

-- The fight's trigger: whether to fire this tick, by the range and the gun.
local function trigger(b: Brain, body: Body, distance: number): boolean
	local now = body.now
	if now < b.pauseUntil then
		return false
	end
	local rounds = if distance > P.tapRange.value then 1 elseif distance > P.sprayRange.value then P.burst.value else P.spray.value
	-- A sniper or a shotgun fires each round on its own; so does a
	-- semi-automatic, each a press.
	if body.category == "sniper" or body.category == "shotgun" then
		rounds = 1
	end
	if body.semi then
		-- A press on a tick of its own, once the gun's ready for the next.
		if b.held or now - b.pressedAt < body.interval then
			return false
		end
		b.pressedAt = now
		b.rounds += 1
		if b.rounds >= rounds then
			b.rounds = 0
			b.pauseUntil = now + math.max(body.recovery, body.interval) * (if rounds == 1 then 1 else 0.5)
		end
		return true
	end
	-- An automatic is held, its rounds counted off the magazine.
	local from = math.max(b.burstFrom or body.ammo, body.ammo)
	b.burstFrom = from
	b.rounds = from - body.ammo
	if b.rounds >= rounds then
		-- The burst's done: let go, and wait for the gun to settle.
		b.rounds, b.burstFrom = 0, nil
		b.pauseUntil = now + body.recovery
		if b.skill.dodge then
			b.dodge = if b.dice() < 0.5 then -1 else 1
			b.dodgeUntil = now + math.min(body.recovery, 0.25)
		end
		return false
	end
	return true
end

-- One tick of the bot's mind: where it looks and whether it fires, from
-- what it knows and what it's told to look at when not fighting (`look`,
-- a point, or nil to keep looking where it is). `glances` are spots an
-- enemy might be in that are in sight now, by key.
function BotBrain.tick(b: Brain, body: Body, dt: number, look: vector?, glances: { [string]: vector }?): Act
	local now, eye = body.now, body.eye
	local s = b.skill
	local act: Act = { yaw = b.yaw, pitch = b.pitch, fire = false, stop = false, dodge = 0, crouch = false, reload = false, slot = nil }
	local k = choose(b, eye)
	if k and (b.target ~= k.id) then
		engage(b, now, eye, k)
	elseif not k and b.target then
		-- Lost sight: aim on where they were for a moment, then let go.
		local last = b.known[b.target]
		if not last or now - last.seen > P.attackMemory.value then
			b.target = nil
			b.turnFrom = nil
		end
	end
	local target = if b.target then b.known[b.target] else nil
	if target then
		local yaw, pitch, distance = aimAt(b, eye, target, now, 0)
		local t = now - b.since
		-- The wander, made anew every so often, eased into.
		if now >= b.wanderAt then
			local width = wanderWidth(b, t)
			b.nextYaw, b.nextPitch = width * gauss(b.dice), width * gauss(b.dice) * 0.6
			b.wanderAt = now + P.wanderEvery.value
		end
		b.wanderYaw += (b.nextYaw - b.wanderYaw) * math.min(dt / 0.1, 1)
		b.wanderPitch += (b.nextPitch - b.wanderPitch) * math.min(dt / 0.1, 1)
		-- Where it means to aim: the point, off by the wander it doesn't
		-- know of, with the gun's climb pulled down by the skill's share.
		local pull = math.rad(body.climb * s.recoil.value)
		local meanYaw = yaw + b.wanderYaw
		local meanPitch = pitch + b.wanderPitch - pull
		local from = b.turnFrom
		if from and t < b.turnFor then
			local along = minJerk(t / b.turnFor)
			b.yaw = from.yaw + wrap(yaw + b.landYaw - from.yaw) * along
			b.pitch = from.pitch + (pitch + b.landPitch - from.pitch) * along
		else
			-- Eased on, led by the ease's own time on a target that moves,
			-- so the view keeps up with them rather than trailing.
			b.turnFrom = nil
			local leadYaw, leadPitch = aimAt(b, eye, target, now, FIGHT_EASE)
			b.yaw = ease(b.yaw, leadYaw + b.wanderYaw, dt, FIGHT_EASE, math.rad(720))
			local wantPitch = leadPitch + b.wanderPitch - pull
			b.pitch = b.pitch + (wantPitch - b.pitch) * math.min(dt / FIGHT_EASE, 1)
		end
		act.stop = true
		-- Fire: the target in sight and noticed, the delay gone by, still,
		-- and the aim where it means it.
		local inSight = target.noticed and now - target.seen <= 0.1
		local width = (if b.head then HEAD_WIDTH else CHEST_WIDTH) / math.max(distance, 1)
		local off = math.sqrt(wrap(b.yaw - meanYaw) ^ 2 + (b.pitch - meanPitch) ^ 2)
		local onTarget = off <= width / 2 * P.tolerance.value
		-- A spray close up, crouched now and then.
		if distance <= P.sprayRange.value and t < 0.05 + dt and b.dice() < 0.25 and s.name ~= "Easy" then
			b.crouch = true
		end
		act.crouch = b.crouch
		if now < b.dodgeUntil then
			act.dodge = b.dodge
		end
		local ready = inSight
			and t >= s.attackDelay.value
			and body.accurate
			and now >= b.dodgeUntil
			and not body.reloading
			and body.ammo > 0
			and onTarget
		if ready then
			act.fire = trigger(b, body, distance)
		elseif not inSight then
			b.rounds, b.burstFrom = 0, nil
		end
		-- Out of rounds mid-fight: the sidearm, rather than a reload, if
		-- it's near (Booth's bot switches to its pistol); else reload.
		if body.ammo <= 0 and not body.reloading then
			if body.equipped == 1 and body.sidearm and distance < 20 and s.name ~= "Easy" then
				act.slot = 2
			else
				act.reload = true
			end
		end
	else
		-- Not fighting: a hit from someone unseen turns it that way; else it
		-- watches where an enemy it lost sight of was, for a while; else a
		-- glance at a spot an enemy might be in, newly in sight; else where
		-- it's told.
		local want: vector? = look
		local lost = BotBrain.lastSeen(b, now, P.investigate.value)
		if b.hurtFrom and now - b.hurtAt < 1.5 then
			want = b.hurtFrom
		elseif lost then
			want = lost
		elseif b.glance and now < b.glanceUntil then
			want = b.glance
		else
			b.glance = nil
			if glances then
				local best: vector? = nil
				local bestKey: string? = nil
				local bestOff = math.huge
				for key, spot in glances do
					local last = b.glanced[key]
					if last and now - last < 8 then
						continue
					end
					local d = vector.magnitude(spot - eye)
					if d > P.checkRange.value then
						continue
					end
					local across = offView(b, eye, spot)
					if math.abs(across) < bestOff then
						best, bestKey, bestOff = spot, key, math.abs(across)
					end
				end
				if best and bestKey then
					b.glance = best
					b.glanceUntil = now + P.glance.value
					b.glanced[bestKey] = now
					want = best
				end
			end
		end
		if want then
			local yaw, pitch = BotBrain.anglesTo(eye, want)
			local speed = math.rad(P.lookSpeed.value)
			b.yaw = ease(b.yaw, yaw, dt, P.lookEase.value, speed)
			b.pitch = ease(b.pitch, pitch, dt, P.lookEase.value, speed)
		end
		b.rounds, b.burstFrom = 0, nil
		b.crouch = false
		-- Reload when nothing's about and the magazine's run low.
		if not body.reloading and body.magazine > 0 and body.ammo < body.magazine * 0.5 then
			act.reload = true
		end
		-- Back to the primary once the fight's over.
		if body.equipped ~= 1 then
			act.slot = 1
		end
	end
	b.pitch = math.clamp(b.pitch, -MAX_PITCH, MAX_PITCH)
	b.yaw = wrap(b.yaw)
	b.held = act.fire
	act.yaw, act.pitch = b.yaw, b.pitch
	return act
end

-- Whether the bot is fighting someone it can see, or saw a moment ago.
function BotBrain.fighting(b: Brain): boolean
	return b.target ~= nil
end

-- Where it last saw an enemy it's not fighting now, the latest within
-- `within` seconds (its memory, if not given): a place to look into.
function BotBrain.lastSeen(b: Brain, now: number, within: number?): vector?
	local best: vector? = nil
	local bestAt = -math.huge
	for _, k in b.known do
		if not k.noticed and k.seen > bestAt and now - k.seen <= (within or P.memory.value) then
			best, bestAt = k.at, k.seen
		end
	end
	return best
end

return BotBrain
