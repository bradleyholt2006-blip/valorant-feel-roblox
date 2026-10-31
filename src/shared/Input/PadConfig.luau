--!strict
-- A gamepad's numbers (system 68, PadRules). The reference's console
-- version publishes its layout and the names of its settings (its
-- Traditional preset, primagames.com; "Focus Horizontal Sensitivity",
-- "Walk While in Focus" and the rest, charlieintel.com) but none of these
-- numbers, so they're ours. Same status convention as MovementConfig:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki, guide or community measurement
--   "estimate"  - ours; to be tuned (docs/research/68-controller.md)
--
-- The look speed, Focus's share of it, inverting the look and walking in
-- Focus are the player's (PlayerSettings' padLook, padFocus, padInvert and
-- padWalk).
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local PadConfig = {}

PadConfig.Params = {
	-- The left stick moves once it's tilted past `moveDead` of its throw,
	-- and walks while it's tilted less than `walkTilt`.
	moveDead = p(0.25, "estimate", "Of the stick's throw: past a worn stick's drift"),
	walkTilt = p(0.6, "estimate", "Of the stick's throw: about half way over walks"),
	-- The right stick turns the view once it's tilted past `lookDead`, by
	-- its tilt past that (0 to 1 of the rest of its throw) to the power
	-- `lookCurve` of the look speed, so small tilts aim finely.
	lookDead = p(0.12, "estimate", "Of the stick's throw"),
	lookCurve = p(2, "estimate", "The console version's aim curves are named (Light and the rest) but not published"),
	-- Held over `rampFrom` of its throw past the dead zone for `rampDelay`
	-- seconds, the view turns sideways faster, up to `rampBoost` times over
	-- `rampTime` seconds more, so turning round doesn't take long; not in
	-- Focus or zoomed.
	rampFrom = p(0.95, "estimate", "Of the stick's throw past its dead zone"),
	rampDelay = p(0.2, "estimate", "Seconds"),
	rampTime = p(0.25, "estimate", "Seconds"),
	rampBoost = p(1.8, "estimate", "Times the look speed"),
	-- Pixels a second the cursor that has the mouse moves at full tilt: the
	-- big map's, From the Shadows' map's, and the ping wheel's pick (each a
	-- pixel for a count of the mouse).
	cursorSpeed = p(700, "estimate", "Pixels a second: across the big map in about a second"),
	-- A trigger pressed further than this of its travel is held: the console
	-- version's "Left/Right Trigger Deadzone" (0.01 in charlieintel.com's
	-- settings, as low as it goes for 'minimal delay').
	trigger = p(0.1, "estimate", "Of the trigger's travel"),
	-- Seconds between the two bumpers going down that make them the
	-- ultimate's chord (LB + RB) and not two abilities: each bumper's
	-- ability waits this long for the other.
	chord = p(0.08, "estimate", "Seconds: short enough that Updraft on LB still feels at once"),
	-- Seconds Y or Select is held before it's held, not tapped: the knife,
	-- the scoreboard.
	hold = p(0.25, "estimate", "Seconds, as long as Z is held for the ping wheel (Pings.Params.hold)"),
}

return PadConfig
