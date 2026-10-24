# System 5: Wall penetration

This covers shooting through walls ("wallbangs"): which weapons get through which surfaces, how
thickness and angle matter, how much damage is left on the other side, where a bullet stops when
it can't get through, and what the player sees on the wall. Where the bullet goes is system 3;
what it hits on a character and when is systems 2 and 4.

As before, everything comes from Riot's patch notes, developer posts, community tests and
footage. No game files, memory, network traffic or protected assets were used. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- Many walls, crates and doors can be shot through. Players spray known spots ("wallbangs") to
  hit or deny enemies they can't see.
- How well a gun shoots through walls is a per-weapon class: Low (pistols like the Classic, light
  shotguns and SMGs), Medium (most rifles, the Vandal and Phantom among them) or High (Sheriff,
  Operator, Odin, Ares).
- The surface matters: wood and glass stop almost nothing, stone and brick stop Low weapons, metal
  stops everything but High ones. Thick walls stop more than thin ones, and a wall shot at an
  angle stops more than the same wall shot square on.
- A hit through a wall does less damage than the same hit in the open.
- A bullet that goes through leaves a hole with a puff of white dust; one that doesn't makes an
  orange spark.
- A bullet can stop partway into a wall. A character whose body clips into the wall in that
  stretch can still be hit, at full damage, even through a wall that "can't" be penetrated.
- Some walls have a different material on each side, and some surfaces have been changed by
  patches, so the same spot can behave differently from one patch to the next.

## 2. Publicly documented details

From Riot:

| Fact | Status | Source |
| --- | --- | --- |
| Guardian: "Penetration power increased from Medium >>> Heavy"; "despite its semi-automatic, heavy-hitting firing style—it matched other rifles in terms of penetrating power" | Confirmed | [Patch 1.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-03/) (Jul 2020) |
| Bandit (new pistol): "Wall Penetration: Medium" | Confirmed | [Patch 12.00](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-12-00/) (Jan 2026) |
| Surfaces have materials that decide penetration, tuned per map: "Some of Corrode's wall materials have made certain positions too effective at denying space through penetration alone"; "We're adjusting the wall materials in key areas"; "Adjusted wall material on a key surface" (A and B sites) | Confirmed | Patch 12.00 |
| Haven, mid window: "Added a breakable element to prevent early round start kills through wall penetration"; bug fixes for "unintended wall penetration" on Haven and Bind | Confirmed | Patch 12.00 |
| A skin dealing less wallbang damage than the default Sheriff "is definitely a bug": wallbang damage is meant to be the same for every skin | Confirmed (developer post) | Nickwu, r/VALORANT 2020, via [devtrackers.gg](https://devtrackers.gg/valorant/p/95d1cf68-interesting-bug-sheriff-s-level-4-reaver-skin-deals-less-damage-through-wall-compared-to-other-skins-or-default-sheriff) |

From the community:

| Fact | Status | Source |
| --- | --- | --- |
| Classes per weapon: Low: Classic, Shorty, Frenzy, Stinger, Bucky. Medium: Ghost, Spectre, Judge, Bulldog, Phantom, Vandal, Marshal (and the Guardian before 1.03). High: Sheriff, Operator, Ares, Odin | Community | [Shacknews](https://shacknews.com/article/117432/weapons-and-stats-valorant) (Apr 2020), [Codashop](https://news.codashop.com/ph/?p=15954) (Oct 2020; it still lists the Guardian as Medium after 1.03), [Liquipedia Vandal](https://liquipedia.net/valorant/Vandal) |
| Material tiers from tests: "Glass and wooden barriers need a low amount of bullet penetration", "stone or brick is medium", metal "needs a high amount"; "wall material, the angle of the shot, wall thickness, and gun type" all change the result | Community (player tests) | quarkez's tests, reported by [Dexerto](https://www.dexerto.com/valorant/valorant-wall-bang-analysis-reveals-why-damage-is-so-inconsistent-1380296/) (Jun 2020) |
| Wood "does little to withstand fire"; stone stops Low weapons "but not medium-penetration rounds"; metal stops everything except High; penetrating shots do less damage | Community | [TheGamer](https://www.thegamer.com/valorant-shoot-through-walls/) |
| "An orange spark" means the bullet ricocheted and leaves no hole; "a puff of white smoke plus a cratered bullet hole" means it is going through | Community | TheGamer |
| Bullets don't stop at the entry face: higher-penetration weapons go part way and stop inside. "Character model clips through the object/wall, and if shot at, you will take full damage"; an air gap between the model and the wall avoids it | Community (player test) | quarkez, via [Sportskeeda](https://www.sportskeeda.com/valorant/valorant-wall-penetration-inconsistencies-ruining-competitive-integrity-game) |
| The bullet "disappears inside the wall without exiting", and "while it is still in the wall, it deals full damage" | Community | [Mein-MMO](https://mein-mmo.de/en/wallbangs-in-valorant-are-even-stronger-than-you-thought,537635) (Aug 2020) |
| Some walls have different materials on each side; the same shot can do different damage; impact effects don't always show that a bullet got through | Community (player test) | Sportskeeda, Dexerto |
| Two players got identical wallbang damage from the same spots with the Vandal and Odin (the test that found the skin bug) | Community (player test) | The same devtrackers.gg thread |

**Not found publicly:** any damage number through a wall, how damage loss depends on class,
material, thickness or angle, whether entering a wall costs anything by itself, how far each
class gets into each material, how several walls combine, and whether there is any randomness
(one test says the same shot can do different damage; the skin report says two players got
identical damage from the same spots). Everything numeric below is therefore an estimate, with
the measurements that would replace it in section 3.

## 3. What can be measured, and how

In a custom game with a friend on the other team, no shields, and the friend reading out their
health after each hit: damage is 100 minus what they read. Body shots at a fixed distance keep the
open-air damage known (a Vandal does 40 to the body at any range). Never use any tool on the live
game to read health or positions; the friend's own screen is the measurement.

| Measurement | Method | Gives us |
| --- | --- | --- |
| Pass or stop | For each class (Classic, Vandal, Sheriff or Operator) and each kind of surface (wood, glass, stone or brick, metal), one shot at the friend standing behind it: does their health drop? | Which limits are zero (the class-material table) |
| Damage left | Five body shots through the same wall from the same spot, and five in the open: the ratio | One point of the damage curve, and whether it varies shot to shot |
| Angle | The same wall square on and from about 45 degrees (and 60 if possible), same distance | How damage falls with thickness along the ray, without knowing the thickness: at 45 degrees the bullet goes through 1.41 times as much wall, at 60 degrees 2 times |
| Two walls | A spot where a shot crosses two thin walls, against one of them | How walls combine |
| Stops inside | The friend hugs a wall a Medium weapon can't get through; shoot where their body clips in | Whether the bullet reaches into walls, and how deep (move the friend back until it stops) |
| What it looks like | Record the wall up close for each material, through and not through | The hole, dust and spark cues |

Thickness can only be judged by eye (a wall's edge next to something of known size), which is why
the angle test matters: it changes the thickness along the ray by a known factor.

Our own game is measured in the wallbang lane (section 7), whose walls have known materials and
thicknesses, with the Weapon Lab and the F10 overlay giving every wall's cost.

## 4. Confirmed vs estimated, as implemented

All values live in `src/shared/Weapons/WeaponConfig.luau` (`WeaponConfig.Penetration` and each
weapon's `penetration`), each with its status and source.

| Parameter | Value | Status |
| --- | --- | --- |
| Penetration is a per-weapon class | yes | Confirmed (Patch 1.03, 12.00) |
| Our weapons' classes | Classic Low, Vandal and Phantom Medium, Sheriff and Operator High, knife none | Community |
| Surfaces have materials that decide it | yes | Confirmed (Patch 12.00) |
| Which class gets through which material | Low: soft. Medium: soft, medium. High: soft, medium, hard | Community |
| Thickest wall per class, square on (soft / medium / hard) | Low 0.25 / 0 / 0 m, Medium 0.50 / 0.25 / 0 m, High 1.00 / 0.50 / 0.20 m | Estimate |
| Entering a wall from open air costs | 10% of the bullet's budget | Estimate |
| Damage past the walls | x (1 - 0.75 x budget spent): a bullet that barely gets through keeps a quarter | Estimate |
| Thickness counts along the ray | yes (a 45 degree shot goes through 1.41x the wall) | Community that angle and thickness matter; along the ray is ours |
| Bullets stop inside walls; a target in that stretch takes full damage | yes | Community |
| Holes and dust when going through, a spark when not | yes | Community |
| No randomness | the same shot does the same damage | Estimate (the reports disagree) |

What the rules give for one wall hit square on (from `luau tests/run.luau`):

| Class | Material | 0.05 m | 0.10 m | 0.20 m | 0.40 m | 0.80 m |
| --- | --- | --- | --- | --- | --- | --- |
| Low | soft | x0.79 | x0.66 | x0.39 | stops | stops |
| Medium | soft | x0.86 | x0.79 | x0.66 | x0.38 | stops |
| Medium | medium | x0.79 | x0.66 | x0.39 | stops | stops |
| High | soft | x0.89 | x0.86 | x0.79 | x0.65 | x0.38 |
| High | medium | x0.86 | x0.79 | x0.66 | x0.38 | stops |
| High | hard | x0.76 | x0.59 | x0.25 | stops | stops |

Low gets through no medium or hard wall, and Medium no hard one. High's x0.25 through 0.20 m of
hard is exactly at its limit: only a shot within about a degree of square on gets through, and
anything steeper stops. (A level may report an exit up to 0.05 mm past the bullet's reach,
`Penetration.EXIT_TOLERANCE`, so that rounding doesn't decide a wall at the limit.) Body / head
damage through one wall:

| Weapon | Open | 0.10 m wood | 0.20 m concrete | 0.10 m metal |
| --- | --- | --- | --- | --- |
| Classic | 26 / 78 | 17 / 51 | stops | stops |
| Sheriff | 55 / 160 | 47 / 137 | 36 / 105 | 32 / 94 |
| Vandal | 40 / 160 | 32 / 126 | 15 / 62 | stops |
| Phantom | 39 / 156 | 31 / 123 | 15 / 60 | stops |
| Operator | 150 / 255 | 129 / 219 | 98 / 167 | 88 / 150 |

## 5. Design

```
 shot (origin, direction, weapon class)
   └─ Penetration.trace(level, ...)                     shared, pure: client, server and tests
        loop: level:cast  → nearest surface not yet gone through (material, distance, normal)
              limit = limits[class][material]; 0 → the bullet stops at the face
              pay the entry cost (unless the piece touches the last one: the same wall)
              reach = budget left / cost per metre
              level:exit(depth = reach) → exit distance, or nil → the bullet stops inside
              pay thickness x cost per metre; multiplier = 1 - loss x budget spent
        → Trace { walls, stop, stopped }
   ├─ ShotResolver.resolve(..., blockedAt = trace.stop)  hitboxes, as before
   └─ damage = round(damageAt(region, range) x multiplierAt(trace, hit distance)), at least 1
```

- **A budget per bullet.** Every bullet starts with 1. A wall costs the entry cost plus its
  thickness along the ray over the class's limit for that material (scaled so that a single wall
  exactly at the limit, hit square on, takes everything). That one rule gives the observed
  behaviour: thicker and more angled walls cost more, harder materials cost more, a second wall
  costs more on top of the first, and a bullet that can't pay stops inside, as deep as its budget
  reaches.
- **Damage follows the budget spent.** Hits past the walls take `1 - damageLoss x spent`. A wall
  a weapon gets through easily costs it little; a wall that takes nearly everything leaves a
  quarter. One curve per class, set by two numbers, fitted from the measurements in section 3:
  damage left against the thickness along the ray should be a straight line whose start is
  `1 - loss x entryCost` and whose slope is set by the limit.
- **Hits inside a wall keep the damage from before it.** The reference's "hidden wallbang", where
  a bullet that never comes out still does full damage to a body clipped into the wall. Our
  hitboxes always sit inside the movement collision box (the widest corner is 0.28 m from the
  centre against a 0.34 m half-width), so a character can't clip into a wall here and the case
  only matters in tests, but the rule is the reference's.
- **One wall can be several pieces.** Builders overlap parts. A piece that starts within 1 cm of
  the last exit continues the same wall: no second entry cost, and an overlap is paid once. A
  piece inside one already gone through adds nothing, and a solid piece inside a wall (rebar in
  concrete) stops the bullet at its face.
- **The level behind an interface.** `Level` has two calls: the nearest surface along the ray
  leaving out pieces already gone through, and the exit of a piece within a depth.
  `RobloxLevel` does both with raycasts; the tests use boxes. Each cast starts from the shooter,
  so a piece that starts inside another is still found. At most 16 pieces are traced, then the
  next stops the bullet.
- **Same trace on both sides.** The client predicts the walls with the same code and the same
  level, so the holes and the predicted spark appear on the tick the shot fires, and the server's
  verdict carries its walls and multiplier for the debug tools to compare. Other players' shots
  are traced again on each client to draw their holes (the server sends the weapon with the
  tracer).

### Roblox differences that matter

- **Materials from Roblox materials.** The reference's maps have authored materials per surface.
  Here a part's Roblox material decides: Wood, WoodPlanks, Glass, Fabric, Cardboard, Carpet,
  Leather and Plaster are soft; Concrete, Brick, Cobblestone, Granite, Marble, Slate, Pavement,
  Limestone, Sandstone, Basalt, Rock, Asphalt, tiles, shingles, Pebble and Salt are medium; Metal,
  DiamondPlate, CorrodedMetal and Foil are hard. Everything else, Plastic and SmoothPlastic
  included, is solid, so the test range (all SmoothPlastic apart from the wallbang walls) and any
  map built before this system still stop every bullet. A `VFPenetration` attribute ("soft",
  "medium", "hard", "solid") on a part or any ancestor overrides it, the way Riot sets the
  material of single surfaces on its maps. Terrain is always solid.
- **Exits by casting back.** Roblox rays don't report where they leave a part, so the exit is
  found by casting back toward the shooter, against that part alone, from as deep as the bullet
  can reach. A ray that starts inside a part doesn't hit it, so no hit means the part is thicker
  than the bullet can go. The cast starts 1 mm deeper than that, so it finds a back face exactly
  at the reach, and a back face it finds in that last millimetre doesn't count. That is exact for
  blocks, wedges and cylinders; a ray that leaves a concave union or mesh and enters it again
  counts only one stretch, so penetrable walls should be built from parts. A self-test at server start measures parts of known size and prints the
  result in the Output window.
- **No ricochets, no wall damage.** Bullets that stop just stop; walls don't break.

## 6. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Weapons/WeaponConfig.luau` | `PenetrationClass`, each weapon's class, `WeaponConfig.Penetration` (limits, entry cost, damage loss) with status and source |
| `src/shared/Combat/Penetration.luau` | The trace through walls, the multiplier at a distance, damage rounding, the one-wall table |
| `src/shared/Combat/RobloxLevel.luau` | `Penetration.Level` over Roblox raycasts, the material mapping and attribute, the self-test |
| `src/server/CombatServer.luau` | Traces every shot through the level, applies the multiplier, sends the walls in the verdict and the weapon with the tracer |
| `src/server/init.server.luau` | Runs the self-test at start |
| `src/server/TestRange.luau` | The wallbang lane |
| `src/client/Combat/ClientShots.luau` | The client's trace through the same level; the verdict's walls; `world` now also covers a different multiplier |
| `src/client/Combat/WeaponEffects.luau` | Holes and dust through walls, sparks when stopped; other players' holes |
| `src/client/Debug/HitboxOverlay.luau` | Wall segments and labels per shot, compared with the server's |
| `src/client/Debug/WeaponLab.luau` | The weapon's class and limits, the lane table, the last shot's walls, reference wallbangs |
| `src/client/Debug/ReferenceData.luau` | `wallbangs` slots for measurements of the reference |
| `tests/penetration.luau`, `tests/FakeLevel.luau` | Offline tests and the report above |

## 7. Debug tools

| Where | Tool |
| --- | --- |
| Wallbang lane | Left of the spawn: wood, concrete and metal walls 0.10, 0.20 and 0.40 m thick, 2.4 m tall, with a practice dummy 1.5 m behind each and a sign on the floor; the 0.20 m concrete wall again turned 45 degrees (0.28 m along a straight shot, which the Vandal no longer gets through but the Operator does); a line 10 m out to shoot from and a backstop |
| F2 (first press) | Weapon Lab: the equipped weapon's class (with status) and the thickest wall of each material it gets through; the damage left after each lane wall; the last shot's walls with thickness, budget share and the client's and server's multipliers and damage; any reference wallbang measurements next to what we predict for the same wall. The shot log has a `walls` column with the multiplier |
| F10 | Hitbox overlay: every piece of wall a shot went into as a thick segment (wood brown, stone grey, metal blue, solid red) labelled with its Roblox material, our material, thickness along the ray, budget share and the damage left after it (or "stops"/"stops inside"); the labels turn white when the server's walls match the client's, red when not, with the server's walls in blue. The verdict label adds `walls x0.66` |
| On the wall | A hole and a puff of dust where a bullet goes through (and where it comes out); an orange spark where it stops |
| Output window | `[VF] penetration self-test passed: ...` at server start, or what failed |

## 8. Refinement loop

1. In Studio, check the self-test line in the Output window, then shoot each lane wall with the
   Classic, Vandal and Operator. The F10 labels should show the thickness on the sign, the Weapon
   Lab's table should match the dummies' damage numbers, and every label should turn white.
2. Make the class-material table from the reference's pass-or-stop tests (section 3) and set any
   limit that should be zero, or not, in `WeaponConfig.Penetration.limits`.
3. For each class, plot damage left against thickness along the ray from the angle tests
   (1, 1.41 and 2 times the wall). Our rule makes that a straight line, starting at
   `1 - damageLoss x entryCost` and ending at `1 - damageLoss` where the bullet stops getting
   through. So `damageLoss` is one minus the line's value at that point, `entryCost` is one minus
   the start, over `damageLoss`, and the angle where it stops getting through gives the limit as
   a multiple of the wall's thickness. If the points curve, the cost isn't linear in thickness
   and the model needs another term.
4. Enter each reference measurement in `ReferenceData.wallbangs` with our best guess at the
   wall's thickness; the Weapon Lab shows ours next to it. Tune until they agree.
5. Re-run `luau tests/run.luau` and update the tables in section 4.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- Roblox rays that start inside a part don't hit it, the back cast's normal faces out of the
  exit face, and metal exactly at High's limit lets a bullet through square on but not 2.25
  degrees off (the self-test checks all three).
- The self-test's parts are found by raycasts one frame after they are added.
- Holes, dust and sparks are visible and sit on the right faces, other players' holes appear in
  the same places, and every F10 wall label turns white against the server.

The [Studio test session](../studio-checklist.md) walks through these, with what to expect.
