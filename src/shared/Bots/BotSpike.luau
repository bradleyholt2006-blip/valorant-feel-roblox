--!strict
-- A bot's hands on the spike (system 61): what it presses each tick to
-- plant it or defuse it, from its job (BotTeam) and from what its
-- simulation and the spike's context say (SpikeSim, Spike), as a player
-- does it:
--   * planting: once it's at the spot planned and in the plant area, the
--     spike's drawn (its fourth slot) and Use held, standing still, until
--     it's down
--   * defusing: within reach of the planted spike and in sight of it, Use
--     held, standing still, until it's defused
--   * a fight comes first: it lets go to fight (a plant starts over; a
--     defuse keeps its half once past it), unless its job says there's no
--     time to fight first, or it's nearly done
--   * nothing's fired, reloaded, scoped or crouched for while the spike's
--     in hand or a plant or a defuse is under way: fire with the spike in
--     hand would plant it, and a crouch could take the spike out of sight
--
-- Plain state and maths, shared by the server (BotServer) and the tests.

local PlayerSim = require("../PlayerSim")
local Spike = require("../Spike/Spike")
local SpikeSim = require("../Spike/SpikeSim")
local BotTeam = require("./BotTeam")

local BotSpike = {}

-- A tick's hands: hold Use; the slot to have in hand, if the spike says
-- (the spike's, to plant); stand where it is; and leave the gun alone.
export type Hands = {
	use: boolean,
	slot: number?,
	still: boolean,
	quiet: boolean,
}

-- Seconds into a plant (of its 4) past which a fight doesn't stop it, and
-- of a defuse's 7 (estimates): nearly done, it's finished.
BotSpike.PLANT_ON = 3
BotSpike.DEFUSE_ON = 5.5

BotSpike.NONE = table.freeze({ use = false, slot = nil, still = false, quiet = false }) :: Hands

-- This tick's hands for a bot with simulation `sim` at simulation time `t`
-- (the tick's), its eye at `eye`, doing `job`, with the spike's context
-- `ctx` for it. `there`: it's at the spot its job sends it to;
-- `fighting`: it's fighting someone (BotBrain.fighting).
function BotSpike.hands(
	job: BotTeam.Order?,
	there: boolean,
	sim: PlayerSim.State,
	ctx: Spike.Context,
	t: number,
	eye: vector,
	fighting: boolean
): Hands
	local s, w, m = sim.spike, sim.weapons, sim.movement
	local inHand = SpikeSim.inHand(w)
	local busy = inHand or s.channel ~= SpikeSim.NONE
	local task = if job then job.task else nil
	local commit = job ~= nil and job.commit == true
	if task == "plant" and SpikeSim.carrying(w) then
		local planting = s.channel == SpikeSim.PLANTING
		local into = if planting then t - s.channelStart else 0
		if fighting and not commit and into < BotSpike.PLANT_ON then
			return { use = false, slot = nil, still = false, quiet = inHand }
		end
		local ready = there and m.grounded and ctx.canPlant and Spike.siteAt(ctx.zones, m.position) ~= nil
		if planting or ready then
			return { use = inHand, slot = Spike.SLOT, still = true, quiet = true }
		end
	elseif task == "defuse" then
		local planted = ctx.planted
		local defusing = s.channel == SpikeSim.DEFUSING
		local into = SpikeSim.defuseProgress(s, t)
		if fighting and not commit and into < BotSpike.DEFUSE_ON then
			return { use = false, slot = nil, still = false, quiet = busy }
		end
		local sees = ctx.sees
		local reach = planted ~= nil
			and m.grounded
			and not inHand
			and Spike.inDefuseRange(m.position, planted)
			and (sees == nil or sees(eye, planted))
		if ctx.canDefuse and (defusing or reach) then
			return { use = true, slot = nil, still = true, quiet = true }
		end
	end
	return { use = false, slot = nil, still = false, quiet = busy }
end

return BotSpike
