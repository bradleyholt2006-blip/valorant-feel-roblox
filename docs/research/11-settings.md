# System 11: Settings: your sensitivity and crosshair

A player who comes from the reference brings two things that make it feel like their game: their
mouse sensitivity and their crosshair. This system takes both as the reference writes them. Type
the sensitivity and the scoped sensitivity multiplier from its settings, paste the crosshair code
it exports, and the view turns as far for the same hand movement and the same crosshair sits in
the middle of the screen, spreading as it does there. The settings are kept from one session to
the next. Video settings, key binds and the rest of the menu are separate work.

As before, everything comes from Riot's patch notes and from community guides, converters and
open-source decoders. No game files, memory, network traffic or protected assets were used, and
nothing reads the game while it runs. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide, converter or a player's test, not by Riot |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source |

## 1. Observable behaviour

- Sensitivity is one number. The same number and mouse DPI give the same distance across the mouse
  pad for a full turn (cm/360) for everyone. The field of view is fixed, 103 degrees across.
- Zoomed (a rifle's sights, a sniper's scope) the view turns more slowly, by an amount set by one
  more number, the scoped sensitivity multiplier, 1 by default.
- The crosshair has a colour (eight to pick from, or any hex colour), outlines (thickness and
  opacity), a centre dot (thickness and opacity), inner lines and outer lines (each with opacity,
  length, thickness and offset, and the horizontal and vertical lengths apart if you like).
- Lines can show movement error and firing error: they spread when you move or fire, so the
  crosshair shows how accurate the next shot is. By default the inner lines spread with firing and
  the outer lines with both. "Fade crosshair with firing error" fades the top line while you spray.
- "Use Advanced Options" gives aiming down sights its own crosshair and lets you style the sniper
  scope's centre dot.
- A crosshair is exported as a line of text, the crosshair code, and imported by pasting one.

## 2. Publicly documented details

### From Riot

| Fact | Status | Source |
| --- | --- | --- |
| "Turn on "Use Advanced Options" to additionally customize your ADS crosshair and sniper scope center dot!" | Confirmed | [Patch 3.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-03) |
| "Added the ability to save and switch between multiple crosshair profiles"; "Added a setting to set a minimum firing error across all weapons"; "Added a setting to use the primary crosshair with shotguns" | Confirmed | The same notes |
| "Added the ability to import and export different crosshair settings via auto-generated codes." Export: the arrow pointing up next to Crosshair Profile, and "The player's auto-generated code will be copied to their clipboard"; import: the arrow pointing down, "Input or paste the code in the provided field and click the 'Import' button" | Confirmed (quoted by the press) | Patch 4.05, quoted by [Sportskeeda](https://www.sportskeeda.com/valorant/valorant-patch-4-05-official-notes-crosshair-profile-export-import-codes-brimstone-nerfs) |
| "Added the ability to select a custom crosshair color" for "Primary, Aim Down Sights, or Sniper Scope", as a "Hex Code (6-digit RGB)"; "If a non-Hex code is entered, crosshair will revert to the previous color." | Confirmed | [Patch 5.04](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-5-04/) |
| "Added the ability to independently tune horizontal and vertical crosshair lines": "Disabling the middle "chain" icon enables independent tuning. Left slider is for horizontal line and the right slider is for the vertical line." | Confirmed | The same notes |
| "Increased the number of crosshair profiles available from 10 to 15"; "/crosshair copy" or "/cc" copies a spectated player's crosshair | Confirmed | The same notes |

Riot documents the importing and exporting but not the code itself.

### From the community

| Fact | Status | Source |
| --- | --- | --- |
| "Valorant uses a fixed yaw value of 0.07 degrees per mouse count"; the scoped multiplier is 1.0 by default and "applies uniformly to all sniper rifles"; the field of view is fixed at 103 | Community | [recharge.com](https://www.recharge.com/blog/en-gb/valorant-sensitivity-converter-cs2-apex-ow2-fortnite) |
| "Multiply your Valorant sensitivity by 3.1818 to get the identical feel in CS2", from "0.07 ÷ 0.022"; 10.9 cm a turn at 800 DPI for a Valorant 1.5 (CS2 4.773) | Community | [csdb.gg](https://csdb.gg/sensitivity-converter/valorant-to-cs2/) |
| The profile is stored "as one line of text"; `0;P;c;5;h;0;0l;4;0o;2;0a;1;0f;0;1b;0` is a cyan crosshair with no outlines, inner lines 4 long at offset 2 at full opacity, no firing error and the outer lines off; the viewer uses "the community key table that two independent open-source decoders agree on" | Community | [senslab](https://senslab.pro/crosshair/valorant) |
| The keys that scale with resolution: `t` outline thickness, `z` centre dot size, `0t`/`1t` line thickness, `0l`/`1l` horizontal length, `0v`/`1v` vertical length, `0o`/`1o` offset; codes split on `;` | Community | [sciencejiho/valorant-crosshair](https://github.com/sciencejiho/valorant-crosshair) (MIT) |
| JUNiOR's code, `0;s;1;P;c;5;o;1;f;0;m;1;0l;2;0v;2;0g;1;0o;0;0a;1;0f;0;1b;0;S;c;5;s;0.7;o;1` | Community | The same repository's [spec](https://github.com/sciencejiho/valorant-crosshair/blob/main/valorant_crosshair_lab_SPEC.md) |
| "Basic dot" `0;P;h;0;d;1;0b;0;1b;0`: white, outlines off, centre dot on at opacity 1 and thickness 2, no inner or outer lines; and a cyan round dot with inner and outer lines, `0;P;c;5;h;0;d;1;0l;1;0v;1;0o;1;0a;0.6;0f;0;1t;4;1l;1;1v;1;1o;1;1a;0.1;1m;0;1f;0` | Community | [Dot Esports](https://dotesports.com/valorant/news/how-to-get-the-dot-crosshair-in-valorant) |
| A square dot `0;P;o;1;d;1;z;4;0b;0;1b;0` and a round dot `0;s;1;P;h;0;d;1;z;3;f;0;0t;3;0l;1;0o;1;0a;1;0f;0;1t;0;1l;0;1o;0;1a;0;1f;0`, both white | Community | [THESPIKE](https://www.thespike.gg/valorant/crosshairs/codes/dot-crosshair-valorant-settings-codes) |
| "The Default Crosshair": white, outlines on, centre dot off, inner lines 0.8/6/2/3, outer lines 0.35/2/2/10, fade, firing error and movement on | Community | [eXputer](https://exputer.com/guides/settings/valorant-crosshair/) |
| A generator starting from outline thickness 1, centre dot thickness 2, inner length 6, outer offset 10 | Community | [valorantcrosshairdb](https://www.valorantcrosshairdb.com/crosshair-generator/) |
| Ranges: outline thickness 1 to 6 and opacity 0 to 1; centre dot thickness 1 to 6; inner length 0 to 20, thickness 0 to 10, offset 0 to 20; outer length 0 to 10, thickness 0 to 10, offset 0 to 40 | Community | [A crosshair generator's notes](https://hackmd.io/@crosshairgenerator/Bk0OBcZzo) |
| The colours, in order: "White," "Green," "Yellow-Green," "Green-Yellow," "Yellow," "Cyan," "Pink," and "Red", and a custom hex colour since Patch 5.04 | Community | [Upcomer](https://upcomer.com/how-to-change-your-crosshair-color-in-valorant), [ONE Esports](https://www.oneesports.gg/valorant/valorant-patch-5-04-crosshair-settings) |
| Fade crosshair with firing error "will make the top line of the crosshair disappear when continuously firing with an automatic weapon"; "the outer lines will expand while the inner ones will stay in their original position" when you strafe | Community | [Sportskeeda's guide](https://www.sportskeeda.com/esports/valorant-a-complete-guide-mastering-crosshair-settings) |
| Movement and firing error "makes the crosshair spread when you move or fire"; "With them off, the crosshair always shows at a fixed size" | Community | [dor.gg](https://clip.dor.gg/en/blog/valorant-crosshair-guide) |
| Crosshair sizes are in pixels, so "on higher res it translates to a smaller crosshair" | Community | [A VLR.gg thread](https://www.vlr.gg/post/2498136) |
| The sniper scope's settings are Center Dot, its colour, opacity and thickness; published ones include red at 0.75 and thickness 1, and thicknesses such as 0.335 and 2.742 | Community | [Pro Game Guides](https://progameguides.com/valorant/best-sniper-crosshair-settings-in-valorant/) |

Nobody publishes the key table in full, the colours' RGB values, how far the lines move for a
given error, the fade's curve, how big the sniper scope's dot is, or the sliders' steps.

## 3. What can be measured, and how

From your own copy of the game, in The Range, played normally, with screenshots and a video
(Windows' Game Bar or your graphics driver's recorder). Never use any tool that reads the game's
memory, files or network traffic.

| Measurement | Method | Gives us |
| --- | --- | --- |
| The yaw | Mark the mouse's place on the pad, turn a full circle back to a landmark, measure the distance; at 0.4 and 800 DPI it should be 40.8 cm | `YAW_DEGREES_PER_COUNT` |
| Scoped speed | The same with the Operator scoped at multiplier 1 | Whether zoomed turning divides by the zoom (102.1 cm at 2.5x) |
| The key table | Export a code, change one setting, export again, and compare | Each key's meaning and default |
| The default crosshair | Export the default profile; a screenshot at 1920 x 1080 | `Crosshair.DEFAULT`, the pixel sizes |
| Movement error | With movement error on and the multiplier at 1, run with the Vandal and take a screenshot; measure how far the lines moved | Whether the lines move by the error's size on screen |
| Firing error | The same during a spray | The same for firing error |
| The fade | Spray with the fade on and step through the video | `FADE_DEGREES` |
| The sniper dot | A scoped screenshot at thickness 1, 2 and 3 | `SNIPER_DOT_PIXELS` |

## 4. Confirmed vs estimated, as implemented

The settings and their limits are in `src/shared/Settings/PlayerSettings.luau`; the key table,
its defaults and ranges, and the drawing rules are in `src/shared/Settings/Crosshair.luau`.

| Parameter | Value | Status |
| --- | --- | --- |
| Yaw | 0.07 degrees a count, times the sensitivity | Community |
| Zoomed | Times the scoped multiplier, divided by the zoom, for any zoom (a rifle's sights and the scopes alike) | Community (the multiplier and its default of 1); estimate (dividing by the zoom, and that it covers rifles' sights) |
| Our defaults | Sensitivity 0.4, multiplier 1, 800 DPI | Estimate (0.4 is a common setting at 800 DPI, not the reference's default) |
| Limits | Sensitivity 0.001 to 10, multiplier 0.01 to 5, DPI 0 to 32000 | Estimate |
| The code | A profile number, then key and value pairs; `P`, `A` and `S` start the primary, aiming down sights and sniper scope sections; pairs before the first are general; only what differs from the default is written | Community |
| Keys seen with their settings | `c` colour, `h` outlines, `t` outline thickness, `o` outline opacity, `d` centre dot, `z` its thickness, `a` its opacity; `0b`/`1b` show the lines, `0t`/`1t` thickness, `0l`/`1l` length, `0v`/`1v` vertical length, `0o`/`1o` offset, `0a`/`1a` opacity, `0f`/`1f` firing error, `1m` the outer lines' movement error | Community (the example codes and their settings, the scalable keys) |
| Keys we read from the codes | `0g`/`1g` the vertical length apart (Patch 5.04's chain: in senslab's code the vertical lines are as long as `0l` with no `0v`, and JUNiOR's gives `0v` with `0g;1`); `0m` the inner lines' movement error, like `1m`; the general `s` "Use Advanced Options" (it comes with the codes that have an `S` section); `S`'s `c` colour, `s` thickness, `o` opacity | Estimate (our reading of the example codes) |
| Keys from the menu, not seen with their settings | `u` the hex colour, `f` the fade, `s` show the spectated player's crosshair, `m` override the firing error offset with the crosshair offset (kept, not drawn), `0s`/`1s` and `0e`/`1e` the movement and firing error multipliers, `S`'s `d` show the dot | Estimate |
| Defaults | White; outlines 1 thick at 0.5; no dot (2 thick, opacity 1 when on); inner lines 0.8, 6 long, 2 thick, 3 out, firing error; outer lines 0.35, 2 long, 2 thick, 10 out, movement and firing error; fade on; multipliers 1 | Community (the line values, the colour, outline thickness 1, dot thickness 2; which errors are on: `0f;0`, `1m;0` and `1f;0` appear in codes that turn them off, and strafing spreads only the outer lines); estimate (outline opacity 0.5) |
| Sniper dot defaults | Shown, red, thickness 1, opacity 0.75 | Estimate (from published settings that left them alone) |
| Ranges | As the generator's notes (above); multipliers 0 to 3; a value outside is held to the end, and the menu says so | Community (the slider ranges); estimate (the multipliers, and holding the value) |
| Numbers | Up to three decimals, trailing zeros dropped | Estimate |
| Keys we don't know | Kept as they are and written back, so a code goes out with everything it came in with | (ours) |
| Colours | White FFFFFF, green 00FF00, yellow-green 7FFF00, green-yellow DFFF00, yellow FFFF00, cyan 00FFFF, pink FF00FF, red FF0000; `c` 8 is the hex colour `u` | Community (the names and order); estimate (the RGB values) |
| Sizes | In screen pixels, whole ones: a size under one pixel shows as one | Community (pixels); estimate (the rounding) |
| Where lines sit | The offset is the gap from the middle to the line's inner end; an even thickness is centred on the line between the middle two pixels and an odd one on the middle pixel, with as much gap each side | Estimate |
| Outlines | A ring round each piece, under all the pieces | Estimate |
| Movement error | Lines that show it move out by the next shot's movement error plus the landing penalty, at its size on screen, times the multiplier | Estimate |
| Firing error | Lines that show it move out by what the spray has added to the first shot's firing error, at its size on screen, times the multiplier | Estimate |
| The fade | The top lines fade as firing error builds, gone at 0.5 degrees | Community (the top line); estimate (the curve) |
| Aiming down sights | The `A` crosshair when Use Advanced Options is on and the code has one, otherwise the primary | Confirmed (that it exists); estimate (when it applies) |
| Scoped | The scope (zoom 2 and over) takes the crosshair's place; the sniper dot draws 2 pixels across per unit of thickness, round | Confirmed (the dot is the scope's setting); estimate (its size and shape) |
| Shotguns | The primary crosshair, as with the reference's "use the primary crosshair with shotguns" | Estimate (what the reference draws for shotguns otherwise isn't described) |
| The knife | No spread, so its crosshair doesn't move | Estimate |

## 5. Design

### Sensitivity

`CameraController` turns the view by `PlayerSettings.degreesPerCount(sensitivity, scoped, zoom)`
for each count of mouse movement: 0.07 times the sensitivity, and zoomed, times the multiplier
over the zoom. Over the zoom means that at a multiplier of 1 the scene slides under the crosshair
as fast as it does unzoomed, so a flick across the screen takes the same hand movement. Roblox's
own camera sensitivity slider is divided out of the mouse movement first (C3 checks that this is
right), so ours is the only scale. The DPI is only for the menu's cm/360: the game can't read it.

### The code

`Crosshair.parse` splits on semicolons, takes a number first and then pairs, with a single capital
letter starting a section. Each known key's value is checked: a number for a number, 0 or 1 for a
switch, six or eight hex digits for the colour; one outside its slider is held to the end. Whatever
can't be used is dropped and said in `warnings`, which the menu shows. Keys it doesn't know are
kept as they came. `Crosshair.format` writes the code back, tidied (`1.000` becomes `1`), so the
menu's box holds what's in use and can be copied straight back into the reference.

`Crosshair.profile` fills in the defaults for a section and gives the drawing what it needs, and
`Crosshair.shape` turns it into nine rectangles in whole pixels (the dot and four of each kind of
line), with the lines moved out by the errors given and the top ones faded. It's pure, so the
tests check each example code's pieces against what its page says it draws.

### Drawing

`CrosshairView` draws the pieces as frames in their own screen layer, centred on the view, with
each outline as a ring of four frames under all the pieces, so lines that meet in the middle show
one outline round the lot and a faint line isn't darkened by its own outline. Each frame it works
out the zoom from the weapon in hand: unzoomed it draws the primary crosshair, zoomed in a little
the one for aiming down sights, and scoped only the sniper dot, over `CombatHud`'s scope. The
errors are the next shot's, from the same `Accuracy` sums the shot will use: the movement part of
its cone and the landing penalty, and what the spray has added since the first shot, each turned
into pixels at the current field of view. So the lines close as the spray recovers, and close at
once when you stop, exactly when the next shot is accurate again. It hides while a menu has the
cursor and while you're dead, and the debug HUD's old movement-error arms are gone in its favour.

### The menu

O opens it: three boxes for the sensitivity, the multiplier and the DPI, with the degrees a count,
counts a turn, cm/360 and eDPI under them and the cm/360 zoomed; the crosshair code box, which
holds the code in use, with what it draws in words and what the import changed; the crosshair on
three backgrounds; and what the code does when aiming down sights and scoped. A change applies as
the box is left. While it's open the mouse moves a cursor, as in the buy menu, and the buy menu
can't open over it.

### Keeping them

`ClientSettings` applies each change at once and sends it to `SettingsServer` as text,
`key=value` lines. The server checks it again (`PlayerSettings.fromText`: every number to its
limits, the code tidied or the default) and writes it to a data store keyed by the player, at most
once every 6 seconds, the store's limit for one key, and when they leave or the server closes. On
joining it puts what was kept in the player's `VFSettings` attribute, once; a change made before
it arrives wins. `VFSettingsStatus` says how it went, and the menu shows it.

### Roblox differences that matter

- Roblox gives scripts no clipboard, so the code box is selected and copied by hand (Ctrl+C), and
  pasting is Ctrl+V into the box.
- Esc opens Roblox's own menu, so the settings are on O.
- Roblox's own camera sensitivity slider scales mouse movement; we divide it out, which C3 checks.
- Data stores need the place to allow API access in Studio (Game Settings, Security). Without it
  the settings last the session and the menu says why they aren't kept. We don't change that
  setting.
- The view is drawn in Roblox's GUI pixels. On a screen the system scales up, those may not be the
  screen's own pixels.

## 6. Implementation map

| Piece | Where |
| --- | --- |
| Settings, their limits, the text form, the sensitivity sums | `src/shared/Settings/PlayerSettings.luau` |
| The crosshair code, its keys, profiles and pieces | `src/shared/Settings/Crosshair.luau` |
| The camera's turn rate | `src/client/CameraController.luau` |
| The local settings, applied and sent | `src/client/ClientSettings.luau` |
| The crosshair on screen | `src/client/CrosshairView.luau` |
| The menu | `src/client/SettingsMenu.luau` |
| Keeping them | `src/server/SettingsServer.luau`, the `Settings` remote in `src/shared/Net/Remotes.luau` |
| Tests | `tests/settings.luau` |

## 7. Debug tools

- **HUD (F3):** an `xhair` line: which crosshair is drawn (`P`, `A`, `S` for the sniper dot, or
  `hidden`) and how far movement and firing error have moved its lines, in pixels. The cone ring
  still shows the next shot's true cone round it.
- **Counter-Strafe Lab (F4):** its `cm/360 check` line expects the counts a turn for the current
  sensitivity.
- **`VFTestSettingsMenu` and `VFTestSetting`:** open or close the menu, and enter a setting as its
  box would (`sensitivity=0.35`, `crosshair=0;P;c;5;h;0`), from attributes, for scripted checks.

## 8. Refinement loop

1. Run C3 and the cm/360 check against a ruler, at your own sensitivity and DPI, and against the
   same turn in the reference.
2. Export a code from the reference with one setting changed at a time and confirm each key in
   section 4 that's still an estimate, and the defaults (export the default profile).
3. Screenshot the reference's crosshair at 1920 x 1080, standing, running and spraying, and set
   where lines sit, how far the errors move them, `FADE_DEGREES` and `SNIPER_DOT_PIXELS`.
4. Check the colours against a screenshot of each.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- The menu opens on O over the game, its boxes take typing without moving the player, and the
  cursor and the view behave as with the buy menu.
- The crosshair is drawn crisply on the middle of the view, its outline ring sits snugly round
  each piece, and it moves out with the errors and back.
- The scope shows only the sniper dot, and aiming down sights uses the `A` crosshair when it should.
- The settings are kept when the place can use data stores, and the menu says why not when it
  can't.
- The sensitivity turns the view by the expected amount for a given mouse movement (C3, and
  section 15).

The [Studio test session](../studio-checklist.md), section 15, walks through these, with what to
expect.
