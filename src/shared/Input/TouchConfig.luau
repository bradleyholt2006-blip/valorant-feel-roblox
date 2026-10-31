--!strict
-- A touch screen's layout and numbers (system 71, TouchRules). Guides to
-- the reference's mobile version name its settings (its sensitivities,
-- its gyroscope, its two- to four-finger setups) but give none of its
-- layout's places or sizes, so these are ours, laid out as mobile
-- shooters commonly are: the fire button big, where the right thumb rests,
-- the rest round it. Same status convention as MovementConfig:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki, guide or community measurement
--   "estimate"  - ours; to be tuned (docs/research/71-touch-controls.md)
--
-- Sizes and places are in units of 1% of the screen's short side, so the
-- layout is the same shape on every screen. How fast a drag turns the
-- view is the player's (PlayerSettings' touchLook).
--
-- No requires, so it runs in Studio and in the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

-- A round button: its name (what TouchControls does with it), what it
-- says, and its middle and radius in units.
export type Round = { name: string, label: string, dx: number, dy: number, r: number }
-- A button in the left column: its name and what it says.
export type Pill = { name: string, label: string }

local TouchConfig = {}

TouchConfig.Params = {
	-- A touch that starts on no button in the left `stickZone` of the
	-- screen's width moves, as a stick whose middle is where it started:
	-- `stickRadius` units across its throw, its knob `knob` units.
	stickZone = p(0.4, "estimate", "Of the screen's width, from its left edge"),
	stickRadius = p(12, "estimate", "Units: a short push of the thumb"),
	knob = p(5, "estimate", "Units"),
	-- Units kept between a button and the screen's edge, the HUD's band
	-- along the bottom, the minimap, or another button.
	margin = p(1.5, "estimate", "Units"),
	-- The left column's buttons: wide, high and apart, in units.
	pillW = p(13, "estimate", "Units"),
	pillH = p(6.5, "estimate", "Units"),
	pillGap = p(1.5, "estimate", "Units"),
}

-- The right thumb's buttons, each `dx` units in from the right edge of the
-- screen's safe area and `dy` units up from the floor: the bottom of the
-- safe area, or where the HUD's band along the bottom reaches under them,
-- the top of the band.
TouchConfig.Cluster = table.freeze({
	{ name = "fire", label = "FIRE", dx = 21, dy = 21, r = 9 },
	{ name = "jump", label = "JUMP", dx = 7, dy = 7, r = 5.5 },
	{ name = "crouch", label = "CROUCH", dx = 19, dy = 5.5, r = 5 },
	{ name = "reload", label = "RELOAD", dx = 6, dy = 22, r = 4.5 },
	{ name = "aim", label = "AIM", dx = 36, dy = 13.5, r = 5.5 },
	{ name = "c", label = "C", dx = 42, dy = 29, r = 4.5 },
	{ name = "q", label = "Q", dx = 31, dy = 33, r = 4.5 },
	{ name = "e", label = "E", dx = 19, dy = 36, r = 4.5 },
	{ name = "x", label = "X", dx = 7, dy = 35, r = 5 },
	{ name = "use", label = "USE", dx = 48, dy = 15, r = 4.5 },
	{ name = "spike", label = "SPIKE", dx = 30, dy = 4, r = 4 },
	{ name = "drop", label = "DROP", dx = 42, dy = 4, r = 4 },
	{ name = "swap", label = "SWAP", dx = 54, dy = 27, r = 4.5 },
	{ name = "ping", label = "PING", dx = 56, dy = 6, r = 4 },
} :: { Round })

-- The left column, top to bottom from under the minimap, and on into a
-- second column where it would reach the floor.
TouchConfig.Column = table.freeze({
	{ name = "buy", label = "BUY" },
	{ name = "map", label = "MAP" },
	{ name = "scores", label = "SCORES" },
	{ name = "agents", label = "AGENTS" },
	{ name = "play", label = "PLAY" },
	{ name = "settings", label = "SETTINGS" },
} :: { Pill })

-- A second fire button for the left thumb or finger, so the right can aim
-- while it fires: `dx` units in from the safe area's left edge and `dy`
-- down from its top.
TouchConfig.FireLeft = table.freeze({ name = "fire2", label = "FIRE", dx = 44, dy = 30, r = 7 } :: Round)
-- With a menu up, the one button shown, which shuts it: `dx` in from the
-- right edge and `dy` down from the top.
TouchConfig.Close = table.freeze({ name = "close", label = "CLOSE", dx = 8, dy = 8, r = 6 } :: Round)

-- The HUD's band along the bottom of the screen, which the buttons keep
-- clear of: the health and shields (CombatHud), the abilities
-- (AbilityHud) and the ammo (CombatHud), all within `half` pixels of the
-- middle of the screen, from `rise` pixels above its bottom.
TouchConfig.Hud = table.freeze({ half = 300, rise = 70 })

return TouchConfig
