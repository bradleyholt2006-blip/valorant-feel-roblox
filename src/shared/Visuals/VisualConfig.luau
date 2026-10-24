--!strict
-- The look (system 6): the lighting preset, colour grading and bloom, the
-- vignette and the friend-or-foe outline. Same status convention as
-- MovementConfig:
--   "confirmed" - stated by Riot (patch notes, dev blog, a developer's post)
--   "community" - published by a wiki, guide or community measurement
--   "estimate"  - ours; to be measured and tuned (docs/research/06-visuals.md)
--
-- Riot's own numbers aren't public: what it has said is what the look aims
-- for, so nearly every value here is an estimate, with the aim it serves in
-- its source.
--
-- Colours are 0-255 RGB, so this has no requires and runs in Studio and in
-- the offline tests.

export type Status = "confirmed" | "community" | "estimate"
export type Param = { value: number, status: Status, source: string }
export type Colour = { rgb: { number }, status: Status, source: string }
export type EnemyColour = { name: string, colour: Colour }

local function p(value: number, status: Status, source: string): Param
	return { value = value, status = status, source = source }
end

local function rgb(r: number, g: number, b: number, status: Status, source: string): Colour
	return { rgb = { r, g, b }, status = status, source = source }
end

local VisualConfig = {}

-- Lighting ------------------------------------------------------------------------

-- Set on this client's Lighting while the look is on, over the place's own
-- values, which come back when it's off. The sun's direction (ClockTime,
-- GeographicLatitude) and the sky stay the place's own: Riot lights each map
-- for itself.
VisualConfig.Lighting = {
	brightness = p(
		2.5,
		"estimate",
		"Sun a little softer than BRINK's 3, so sunlit and shaded faces sit closer in value. The Art of VALORANT Map Environments (Riot): 'we make sure that our materials are similar in value and there isn't too much contrast or darkness'"
	),
	ambient = rgb(
		100,
		100,
		105,
		"estimate",
		"Light in places the sky can't reach. The Art of VALORANT Map Environments: 'we make sure that they aren't too dark, especially in interior spaces'; VALORANT Shaders and Gameplay Clarity (Riot): 'We also tune the maximum \"darkness\" or \"brightness\" for each area across the map'"
	),
	outdoorAmbient = rgb(115, 115, 120, "estimate", "Light in outdoor shade, a touch cool like a sky-lit shadow; the same quotes as ambient"),
	environmentDiffuse = p(0.5, "estimate", "Share of the sky's colour in the shade; Roblox advises lowering Ambient and OutdoorAmbient as this goes up"),
	environmentSpecular = p(0.5, "estimate", "Sky reflections on smooth surfaces, half strength"),
	shadowSoftness = p(0.25, "estimate", "Softer sun-shadow edges, nearer the reference's baked lightmaps (Lightmass, per VALORANT Shaders and Gameplay Clarity)"),
	exposure = p(0, "estimate", "No exposure bias, so the look is the same in every place"),
	maxHaze = p(
		0.2,
		"estimate",
		"The Atmosphere's Density is kept at or below this, so players far away don't fade into haze. VALORANT Shaders and Gameplay Clarity: 'Characters need to always stand out from their environment'"
	),
}

-- Colour and bloom ------------------------------------------------------------------

-- A ColorCorrectionEffect and a BloomEffect of our own replace the place's
-- while the look is on (its depth of field goes off too: nothing in play is
-- out of focus in the reference).
VisualConfig.Colour = {
	contrast = p(
		0.05,
		"estimate",
		"A slight lift, so the softer lighting doesn't look flat. The reference's Improve Clarity setting 'seems to basically just affect your contrast/the dynamic range of the lighting' (ProSettings)"
	),
	saturation = p(0.1, "estimate", "Slightly richer colour, for the stylised, bright look; Riot's art director calls it 'illustrative visual design' (Inverse, 2020)"),
	brightness = p(0, "estimate", "No change: the lighting sets the brightness"),
}
VisualConfig.Bloom = {
	intensity = p(0.35, "estimate", "Faint: the reference's bloom 'mainly affects weapon renders' (ProSettings)"),
	size = p(16, "estimate", "Glow radius"),
	threshold = p(1.5, "estimate", "Only the brightest highlights glow"),
}

-- Vignette --------------------------------------------------------------------------

-- Two black layers over the 3D view and under the HUD, one darkening the
-- sides and one the top and bottom, so the eye settles on the middle.
VisualConfig.Vignette = {
	strength = p(0.15, "estimate", "How dark each edge gets (black at 15%); in the corners both layers overlap, about 28%"),
	start = p(0.45, "estimate", "Where the darkening begins, as a fraction of the way from the centre to each edge"),
}
VisualConfig.vignetteSource =
	"The reference has a Vignette setting (Settings > Video). ProSettings: 'Vignette in games just adds a darker/less saturated area around the edges of your screen'"

-- Friend-or-foe outline -----------------------------------------------------------------

-- Every other player and dummy gets a Highlight: an outline and a tint in
-- its side's colour. The tint grows with distance, so far targets stand out
-- more. VALORANT Shaders and Gameplay Clarity: 'enemies have a red fresnel,
-- and allies have a neutral, blue fresnel', and 'characters in the distance
-- are brightened, and enemy fresnels are larger and more distinct'.
VisualConfig.Outline = {
	outline = p(0.25, "estimate", "Enemy outline transparency (0 solid, 1 hidden)"),
	fillNear = p(0.9, "estimate", "Enemy tint transparency up close: a light tint"),
	fillFar = p(0.65, "estimate", "Enemy tint transparency far away: the distance boost (confirmed); the amount is ours"),
	nearDistance = p(10, "estimate", "Metres up to which the tint stays at its lightest"),
	farDistance = p(50, "estimate", "Metres from which the tint is at its strongest"),
	allyOutline = p(0.6, "estimate", "Ally outline transparency: allies' fresnel is 'neutral', so fainter than enemies'"),
	allyFillNear = p(0.95, "estimate", "Ally tint transparency up close"),
	allyFillFar = p(0.85, "estimate", "Ally tint transparency far away"),
}

-- The reference's Enemy Highlight Color options, in its order (Settings >
-- General > Accessibility). N cycles them.
VisualConfig.EnemyColours = {
	{ name = "Red (Default)", colour = rgb(255, 70, 70, "estimate", "Option name and order from esports.gg (community); the shade is ours") },
	{ name = "Purple (Tritanopia)", colour = rgb(200, 80, 255, "estimate", "Option name from esports.gg (community); the shade is ours") },
	{ name = "Yellow (Deuteranopia)", colour = rgb(255, 220, 50, "estimate", "Option name from esports.gg (community); the shade is ours") },
	{ name = "Yellow (Protanopia)", colour = rgb(235, 235, 100, "estimate", "Option name from esports.gg (community); the shade is ours") },
} :: { EnemyColour }
VisualConfig.enemyColoursStatus = "community" :: Status

VisualConfig.allyColour = rgb(100, 170, 255, "estimate", "Allies get 'a neutral, blue fresnel' (VALORANT Shaders and Gameplay Clarity, confirmed); the shade is ours")

return VisualConfig
