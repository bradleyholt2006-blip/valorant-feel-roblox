# System 6: The look

This covers how the game looks while you play: the lighting, colour grading and bloom, the
vignette, the red outline on enemies (blue on allies), and which things cast shadows. Character
models, animations, weapon bob and sway, ability effects and the maps themselves are separate
work. The maps get a short set of rules here (section 5), from what Riot says about building them.

As before, everything comes from Riot's articles and patch notes, community guides and the game's
own settings menu. No game files, memory, network traffic or protected assets were used, and none
were needed: Riot has written publicly about how the game is lit and why, and the rest can be
measured from screenshots of the game. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- The look is clean, bright and stylised, somewhere between realism and cel-shaded animation.
  Characters have strong, simple silhouettes.
- Shade is never very dark, interiors included. Surfaces sit close together in brightness, and
  areas of a map differ by colour (the "yellow container" kind of callout).
- There is little detail at head and body height. Props and decoration are mostly higher up.
- Enemies have a red rim along their silhouette, brightest on the upper body. Allies have a faint
  blue one. Enemies far away look brighter, and their rim looks bigger.
- The red can be changed to purple or one of two yellows, for colour blindness.
- Characters cast no shadows on the ground, yours included. Your own hands and weapon shade
  themselves.
- There are optional screen effects: a vignette that darkens the edges of the screen, bloom
  (mostly on weapons), distortion, a contrast boost ("Improve Clarity") and sharpening.
- Nothing in play is blurred or lost in haze.

## 2. Publicly documented details

From Riot:

| Fact | Status | Source |
| --- | --- | --- |
| "Characters need to always stand out from their environment" | Confirmed | [VALORANT Shaders and Gameplay Clarity](https://technology.riotgames.com/node/110) (Riot tech blog, Brandon "mochi" Wang) |
| "enemies have a red fresnel, and allies have a neutral, blue fresnel." The fresnel is a rim light at grazing angles that works as a silhouette. It favours edges that face up, so it's strongest on the upper body, like a light from above | Confirmed (the quote; the rest paraphrased) | The same article |
| "characters in the distance are brightened, and enemy fresnels are larger and more distinct" | Confirmed | The same article |
| "We have cast shadows only on objects in first person, like your own hands and weapon." Dynamic shadows were left out of the play space because players on low settings would lose information | Confirmed | The same article |
| "We also tune the maximum "darkness" or "brightness" for each area across the map" | Confirmed | The same article |
| Maps are lit offline with Unreal's Lightmass and stored in lightmaps. Characters and weapons are lit by one directional light with a stylised falloff Riot calls "Gradient Lambert", with artist-set highlight, mid-tone and shadow brightness | Confirmed (paraphrased) | The same article |
| A forward renderer, and "each frame must render in 6.9 milliseconds or less to hit a 144 FPS quality bar"; "there are no differences between low, medium, and high graphics quality settings that could change the competitive landscape" | Confirmed | The same article |
| "we make sure that our materials are similar in value and there isn't too much contrast or darkness" | Confirmed | [The Art of VALORANT Map Environments](https://playvalorant.com/en-us/news/dev/the-art-of-valorant-map-environments) (Riot, Lydia "PHRISK" Zanotti, Nov 2020) |
| "we make sure that they aren't too dark, especially in interior spaces" | Confirmed | The same article |
| Detail: "we try to keep the majority of it above player height" | Confirmed | The same article |
| Lights are used "to illuminate dark areas" and "to spotlight spaces where you would want the most visibility possible", such as a plant site or a corner players often check | Confirmed | The same article |
| "we try to use colors as a way to help distinguish certain areas and structures", "like the yellow shipping container on B-site" | Confirmed | The same article |
| The art "is always subordinate to gameplay clarity and making sure the Agents are always clearly visible when they should be" | Confirmed | The same article |
| "We're not trying to make the most beautiful game ever, we're trying to make an accessible game that everybody can play." The art director calls the style, between realism and cel-shaded animation, "illustrative visual design" | Confirmed (interview) | Moby Francke, [Inverse](https://inverse.com/gaming/valorant-art-style-interview-moby-francke) (Nov 2020) |
| "Fixed an issue where some players' outline/fresnel were displayed even when "Hide Outlines and Fresnel" setting was enabled": there is an outline or fresnel, and a setting that hides it (the notes don't say where) | Confirmed | [Patch 6.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-6-07) |

From the community:

| Fact | Status | Source |
| --- | --- | --- |
| Settings > General > Accessibility > Enemy Highlight Color: "Red (Default)", "Purple (Tritanopia)", "Yellow (Deuteranopia)", "Yellow (Protanopia)" | Community | [esports.gg](https://esports.gg/guides/valorant/how-to-change-enemy-color-in-valorant/) |
| Video settings: Vignette "just adds a darker/less saturated area around the edges of your screen"; Bloom "mainly affects weapon renders"; Cast Shadows "only affects the shadows that are cast on your own player model/view model"; Improve Clarity "seems to basically just affect your contrast/the dynamic range of the lighting"; Experimental Sharpening "sharpens the edges of textures for increased visibility". The guide recommends Vignette, Bloom, Distortion and Cast Shadows off, and Improve Clarity and sharpening on | Community | [ProSettings](https://prosettings.net/guides/valorant-options/) |
| Some pros use a yellow enemy highlight: "Yellow – Deuteranopia seems to be the most common" | Community | ProSettings |

**Not found publicly:** any colour value (the red's RGB), how wide the fresnel is, how the distance
boost grows, the vignette's strength and shape, how much bloom or contrast there is, the video
settings' defaults, or the exposure. Every number below is therefore an estimate, with the
measurements that would replace it in section 3.

## 3. What can be measured, and how

From your own copy of the game, played normally, with screenshots (Windows' Print Screen or your
graphics driver's overlay). A screenshot of what's on your screen is the measurement. Never use any
tool that reads the game's memory, files or network traffic. Any image editor's colour picker reads
the pixels.

| Measurement | Method | Gives us |
| --- | --- | --- |
| Vignette | In The Range, face a flat, evenly lit wall and take a screenshot with Vignette on, then off (Settings > Video > Graphics Quality), without moving. Pick the brightness at the centre, at the middle of each edge and in each corner, on and off | The darkening at the edges (strength), whether the corners are darker than the edges multiplied (if so, it's round, not two layers), and where it starts |
| Enemy colours | For each Enemy Highlight Color option, a screenshot of a bot 10 m away. Pick the brightest pixels of the rim | The four colours |
| Rim and distance | The same bot at 10, 20 and 40 m: the rim's width in pixels, and how red the body looks | Whether the rim keeps its width on screen (an outline, like ours) or shrinks with the model (a fresnel), and the tint near and far |
| Sun and shade | On a map, one material in sun and in shade, and the same material indoors. Pick each | The ratios our Brightness, OutdoorAmbient and Ambient should give |
| Bloom | A bright weapon skin's highlight with Bloom on and off | How far the glow spreads |
| Defaults | The Video settings on a fresh install | Which effects are on by default |

Our side is measured the same way in Studio: the same shots, with the look on and off (V), on
similar surfaces.

## 4. Confirmed vs estimated, as implemented

All values live in `src/shared/Visuals/VisualConfig.luau`, each with its status and source.

| Parameter | Value | Status |
| --- | --- | --- |
| Enemies outlined in red, allies in blue | A Highlight on every other player and dummy | Confirmed that it's red and blue; a Highlight is our stand-in for the fresnel |
| The outline shows only where the target can be seen | Highlight depth mode Occluded | Estimate (a fresnel is part of the character's shading, which can't show through walls) |
| Outline transparency, enemy / ally | 0.25 / 0.6 | Estimate |
| Tint over the target, 10 m to 50 m | Enemies 10% to 35%, allies 5% to 15%, straight between | Estimate (that far enemies stand out more is confirmed) |
| Enemy colour options and their order | Red (Default), Purple (Tritanopia), Yellow (Deuteranopia), Yellow (Protanopia) | Community |
| Their colours | 255,70,70; 200,80,255; 255,220,50; 235,235,100 | Estimate |
| Ally colour | 100,170,255 | Estimate (that it's blue is confirmed) |
| No character shadows | Your avatar and other players' hidden avatars cast none; the blocks never did | Confirmed |
| Your hands and weapon | No shadows | A Roblox difference (section 5): the reference's shade only themselves |
| Sun brightness | 2.5 (BRINK has 3) | Estimate |
| Ambient (shade the sky can't reach) / OutdoorAmbient | 100,100,105 / 115,115,120 (BRINK has 70,70,70 for both) | Estimate |
| EnvironmentDiffuseScale / EnvironmentSpecularScale | 0.5 / 0.5 | Estimate |
| ShadowSoftness | 0.25 (BRINK has 0.2) | Estimate |
| ExposureCompensation | 0 | Estimate |
| Haze | Atmosphere Density at most 0.2 (BRINK has 0.3) | Estimate |
| Colour grading: contrast / saturation / brightness | +0.05 / +0.1 / 0 | Estimate |
| Bloom: intensity / size / threshold | 0.35 / 16 / 1.5 (BRINK has 1 / 24 / 2) | Estimate |
| Depth of field | Off while the look is on | Estimate (nothing in play is out of focus) |
| Vignette | Clear out to 45% of the way to each edge, easing to 15% darker at the edges and 28% in the corners | Estimate (that the setting exists is community) |

What the numbers give (from `luau tests/run.luau`):

| Across the screen, middle to edge | 0 | 0.45 | 0.6 | 0.7 | 0.8 | 0.9 | 1 | Corner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Darkening | 0% | 0% | 2.7% | 6.5% | 10.5% | 13.7% | 15.0% | 27.8% |

| Distance | 5 m | 10 m | 20 m | 30 m | 40 m | 50 m |
| --- | --- | --- | --- | --- | --- | --- |
| Enemy tint | 10% | 10% | 16% | 22% | 29% | 35% |
| Ally tint | 5% | 5% | 8% | 10% | 12% | 15% |

## 5. Design

```
 Visuals.start()                                   client only: nothing replicates
   ├─ setOn(true)   save the place's values, then
   │                  Lighting ← the preset           (sun direction, sky and fog stay the place's)
   │                  Atmosphere.Density ≤ 0.2
   │                  the place's ColorCorrection, Bloom, DepthOfField → off
   │                  VFColour and VFBloom → Lighting, VFVignette on, outlines on
   ├─ ChildAdded on VFDummies / VFPlayers → one Highlight (VFOutline) per model
   └─ render step, Camera + 3 (after RemoteEntities places the models)
        each outlined model: ally or enemy → its colour; distance → its tint
 V → setOn(not on): off puts back exactly what was saved
 N → the next enemy colour
```

- **On this client only.** Everything is set by the client, so the server and the place file are
  untouched, and V compares with the place's own look. The preset changes only what it lists:
  the sun's direction, the sky, the Atmosphere's colours and any fog stay the map's.
- **A preset over the place's lighting.** The reference lights each map offline and caps each
  area's darkness and brightness. Roblox lights at runtime, so the nearest thing is a preset that
  keeps the shade up (Ambient where the sky can't reach, OutdoorAmbient and some sky light in
  outdoor shade) under a slightly softer sun, so values stay close together. A map can still light
  its own areas (see the rules below).
- **The outline is a Highlight.** Roblox has no per-model shaders, so no fresnel. A Highlight draws
  an outline round the whole model's silhouette and a tint over it. The outline stands in for the
  rim, and a tint that grows with distance stands in for "brightened" and "larger and more
  distinct". There is one per model, shown only where the model is visible. Roblox shows at most
  255 at once, far more than ten players and the dummies.
- **Allies and enemies by team.** Another player on the same Roblox team as you (neither of you
  neutral) is an ally. With no teams, every player is an enemy, like the dummies.
- **The vignette is two gradients.** Roblox has no vignette effect. Drawing one into an
  EditableImage needs a permission each published experience has to turn on, and radial
  UIGradients are still a Studio beta that can't be published. So two black layers cover the
  view, under the HUD, each with a transparency gradient: one across, one down. Each is clear out
  to the start, then eases (smoothstep) to the strength at the edge. Where both overlap, in the
  corners, the light left is the product of the two. A NumberSequence holds at most 20 keypoints,
  so each layer has 10 a side, which follows the curve to under 1% of its strength. Once upgraded
  gradients are live, one elliptical gradient would do.
- **No character shadows.** Riot casts shadows only from first-person objects. The blocks already
  cast none, and the Roblox avatars hidden under them (yours and other players') now cast none
  either. The reference's hands and weapon shade only themselves, but a Roblox part's shadow falls
  on everything, so our viewmodel would put a floating gun's shadow on the floor; it stays
  shadowless.
- **Colour grading and bloom of our own.** They replace the place's while the look is on. The
  place's are switched off, never deleted, and switched back on with V. Depth of field goes off.
- **Haze is capped**, so a far player isn't lost in it, and the place's density comes back with V.

### Roblox differences that matter

- **No shaders.** No fresnel, no Gradient Lambert falloff, no faked skin scattering. The outline
  is a fixed number of pixels wide, where a fresnel's rim shrinks with the model, so ours looks
  relatively thicker at range. That happens to fit "larger and more distinct".
- **Some lighting is Studio-only.** Lighting's `LightingStyle` and `PrioritizeLightingQuality`
  can't be set from a script, and `Technology` is deprecated in their favour
  ([Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting)). Studio starts
  every place on Soft, "a flatter look with softer lights and shadows"; Realistic is needed for
  local lights to cast "precise shadows and highlights"
  ([Roblox](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-indoor-environments)).
  Our guess is that Soft is nearer the reference's soft baked shading on the open course, and that
  Realistic will matter once a map uses lights to pick out key spaces. The preset works with
  either; Studio check V6 compares them.
- **The vignette can only darken.** The reference's is described as darker and less saturated at
  the edges. Ours can't desaturate.
- **No sharpening or distortion.** Roblox has neither post effect.

### Building maps that read like the reference's

Riot's rules from the map article, for BRINK and any map after it:

1. Keep materials close in value. No very dark surfaces, and no dark interiors.
2. Keep detail and clutter above head height (1.75 m here), with plain surfaces at body height,
   so a player is the only busy thing at that height.
3. Light dark corners, and the places players look at most (sites, common angles), with a
   PointLight or SpotLight. With LightingStyle on Realistic they cast shadows.
4. Give each area its own colour, so callouts are easy to say.
5. Keep story and decoration outside the space you play in.
6. Ours, not Riot's: keep large areas of the enemy colours (red, purple, yellow) out of the map,
   so an outline never blends into a wall.

## 6. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Visuals/VisualConfig.luau` | Every number of the look, with status and source |
| `src/shared/Visuals/VisualMath.luau` | The vignette's curve and gradient keypoints, the outline's tint by distance |
| `src/client/Visuals.luau` | The preset, our colour grading and bloom, the vignette, the outlines, V and N |
| `src/client/PlayerController.luau` | Your hidden avatar casts no shadow |
| `src/client/RemoteEntities.luau` | Other players' hidden avatars cast no shadow |
| `src/client/Debug/DebugHud.luau` | The `look` line |
| `src/client/init.client.luau` | Starts the look after RemoteEntities, whose folders it watches |
| `tests/visuals.luau` | Offline tests and the report above |

## 7. Debug tools

| Where | Tool |
| --- | --- |
| V | The look off and on again. Off puts back exactly what the place had, to compare |
| N | The next enemy colour: Red (Default), Purple (Tritanopia), Yellow (Deuteranopia), Yellow (Protanopia) |
| F3 HUD | `look    on (V)   enemy Red (Default) (N)` |
| Explorer, while playing | `Lighting.VFColour` and `Lighting.VFBloom`, `PlayerGui.VFVignette`, and a `VFOutline` Highlight in each dummy and player model, all on this client only |

## 8. Refinement loop

1. Take the reference screenshots in section 3.
2. Vignette: compare the edge and corner darkening with ours in the same kind of shot, and set
   `strength` and `start`. If the reference's corners are darker than ours for the same edges,
   its vignette is round; raise the strength a little until elliptical gradients are live.
3. Set the four enemy colours and the ally colour from the colour picks.
4. Outline: compare the rim's width and the body's tint at 10 and 40 m with our dummies at the same
   distances, and set the outline transparency and the tint curve.
5. Lighting: compare the sun-to-shade ratio on similar surfaces and adjust Brightness against
   OutdoorAmbient; check an interior against Ambient.
6. Re-run `luau tests/run.luau` and update the tables in section 4.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- Lighting set from the client shows on that client, and V puts the place's values back exactly.
- The vignette sits over the world and under the HUD, covers the whole screen, and doesn't take
  mouse clicks.
- Outlines follow only the visible part of a target, never through walls, the tint visibly grows
  with distance, and N changes the colour.
- Hidden avatars cast no shadows.
- How the preset looks with LightingStyle on Soft and on Realistic.

The [Studio test session](../studio-checklist.md) walks through these, with what to expect.
