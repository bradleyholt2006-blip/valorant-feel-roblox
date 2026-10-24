# System 2: Weapon firing

This covers the trigger and everything a shot needs short of where the bullet goes: fire modes,
fire rate, magazines, reloads, weapon switching, aim-down-sights and scopes, damage by body region
and range, health and shields, the slow you get when hit, and how the server decides what a shot
hit. Spread and recoil are system 3. Rewinding targets to what the shooter saw (lag compensation)
is system 4 (`docs/research/04-hit-registration.md`).

As with system 1, everything comes from public patch notes, Riot's engineering blogs, community
wikis and footage. No game files, memory or protected assets were used. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog) or shown directly in-game |
| **Community** | Published by a wiki or stat site (these mirror the in-game Arsenal screen), not by Riot |
| **Estimate** | Our own number. It must be measured and tuned before we trust it |

Weapons in this pass: Vandal and Phantom (rifles), Operator (sniper), Classic and Sheriff
(sidearms) and the knife. They cover every fire mode and both kinds of zoom.

## 1. Observable behaviour

- Bullets are hitscan: no travel time and no drop.
- Fire modes: automatic (Vandal, Phantom) fire while the trigger is held; semi-automatic (Classic,
  Sheriff) fire once per click; the Operator is bolt-action with a long cycle between shots.
- Each weapon has a magazine and reserve ammo. A reload refills the magazine at the end of the
  animation, an empty magazine reloads by itself, and switching weapons cancels a reload.
- Switching weapons has a draw time before the new weapon can fire.
- Right-click zooms: rifles go to 1.25x and fire a little slower; the Operator has a 2.5x and a 5x
  scope and moves slower while scoped.
- Damage depends on where the bullet lands (head, body, legs) and, for most weapons, how far the
  target is. Agents have 100 health plus shields (25 light, 50 heavy) that absorb damage first.
- Getting hit slows you down for a moment ("tagging").
- The server decides every hit. A player who has just been killed can't land shots afterwards.

## 2. Publicly documented details

How shots are handled (Riot):

| Fact | Status | Source |
| --- | --- | --- |
| The server is authoritative and never trusts the client's view; clients predict locally | Confirmed | [Peeking into VALORANT's Netcode](https://technology.riotgames.com/node/111) |
| Clients send the time they were viewing when they fired; the server rewinds to it to check the hit, with a cap on how far back | Confirmed | Same article |
| Once a lethal shot is processed the victim is dead and their later shots are rejected | Confirmed | Same article |
| Non-lethal hits briefly slow the victim | Confirmed (qualitative) | Same article |
| State changes are pushed as events (a hit event with its damage) rather than replicating health | Confirmed | [VALORANT's 128-Tick Servers](https://technology.riotgames.com/node/112) |
| Server-side hitboxes follow server-side animation, interpolated during a rewind | Confirmed | Same article |
| Movement, weapons and physics run on a fixed 128 Hz step on client and server | Confirmed | node/111 |

Weapon numbers:

| Fact | Value | Status | Source |
| --- | --- | --- | --- |
| Vandal | auto, 9.75 rps, 25 + 75, reload 2.5 s, draw 1.0 s, 160 / 40 / 34 at every range, 80% speed | Community | [metabot](https://metabot.gg/en/valorant/weapon/vandal/overview), [Liquipedia](https://liquipedia.net/valorant/Vandal) |
| Phantom | auto, 11 rps, 30 rounds, reload 2.5 s, draw 1.0 s, 80% speed | Community | [metabot](https://metabot.gg/en/valorant/weapon/phantom/overview) |
| Phantom body damage and falloff | "Now does 39 damage per bullet from 0-20m and 35 damage per bullet 20m+" | Confirmed | Patch 9.10, as quoted by [Sportskeeda](https://www.sportskeeda.com/valorant/new-valorant-regen-shield-weapon-changes-explained). Older guides ([Hotspawn](https://www.hotspawn.com/?p=91749), [Inven Global, 2020](https://www.invenglobal.com/valorant/articles/11131/valorant-weapon-guide-the-phantom)) give the pre-9.10 bands: 15 m, and 124 / 31 / 26 past 30 m |
| Phantom head and leg damage | 156 / 33 to 20 m, 140 / 30 past it | Community | metabot |
| Operator fire rate | 0.6 rps (was 0.75) | Confirmed | [Patch 1.09](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-09) |
| Operator leg damage | 120 (was 127) | Confirmed | Patch 1.09 |
| Operator scoped move speed | 72% (was 76%) | Confirmed | Patch 1.09 |
| Operator deadzone | 15% (was 30%) | Confirmed | Patch 1.09 |
| Operator | 5 rounds, reload 3.7 s, draw 1.5 s, 255 / 150 head / body, 76% speed | Community | [metabot](https://metabot.gg/en/valorant/weapon/operator/overview), [Liquipedia](https://liquipedia.net/valorant/Operator) |
| Classic | semi, 6.75 rps, 12 rounds, reload 1.75 s, draw 0.75 s, 78 / 26 / 22 to 30 m then 66 / 22 / 19, 85% speed | Community | [metabot](https://metabot.gg/en/valorant/weapon/classic/overview) |
| Sheriff | semi, 4 rps, 6 rounds, reload 2.25 s, draw 1.0 s, 160 / 55 / 47 to 30 m then 145 / 50 / 43, 80% speed | Community | [metabot](https://metabot.gg/en/valorant/weapon/sheriff/overview) |
| Deadzone (every other weapon) | accurate below 27.5% of max speed | Confirmed | [Patch 0.50](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-0-50/) raised it from 25% to 30%; [Patch 3.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/): "Weapon Deadzones changed from 30% >>> 27.5%" |
| Rifle ADS | 1.25x zoom, fire rate x0.9 (Phantom 11 to 9.9) | Community | [PC Gamer](https://pcgamer.com/valorant-guns-damage-recoil-guide), Inven Global |
| Vandal ADS fire rate | 8.32 rps | Community, conflicting | Liquipedia lists 8.32 next to 9.75 hip; PC Gamer lists 8.32 next to an older 9.25 hip |
| Operator zoom | 2.5x and 5x | Community | PC Gamer; the Fandom wiki confirms two zoom levels |
| Health and shields | 100 health, light 25, heavy 50 | Community | Wikis |
| Tagging | 72.5% slow "for a brief period" | Confirmed | [Patch 3.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/): "Bullet tagging changed from 75% slow >>> 72.5% slow"; duration from [Fandom, Weapons](https://valorant.fandom.com/wiki/Weapons) |

**Conflict worth settling with a measurement:** the Vandal's ADS fire rate (0.9 x 9.75 = 8.78, or
8.32). We use x0.9 for now. The Phantom's falloff boundary, which the guides disagreed on, is
settled by Patch 9.10: two bands split at 20 m.

**Not found publicly:** reserve ammo for the Phantom and sidearms, the knife's draw time, rifle
ADS movement speed, how long tagging lasts, whether a click during a draw or a cooldown is buffered,
and hitbox sizes. All of those are estimates below.

## 3. What can be measured, and how

All of these can be measured in The Range from your own footage. Record at 120 fps or more with a
key and mouse overlay, repeat each measurement at least 5 times, and enter the average and count
in `src/client/Debug/ReferenceData.luau` (fields `fireInterval`, `reloadTime`, `equipTime`).

| Measurement | Method | Gives us |
| --- | --- | --- |
| Fire interval | Spray a full magazine at a wall; count frames between the first and last muzzle flash and divide by shots - 1 | `fireRate` |
| ADS fire interval | The same while aiming down sights | `ads.fireRateMultiplier` |
| Reload time | Frames from the reload key to the ammo counter refilling | `reloadTime` |
| Draw time | Hold fire, press the switch key; frames until the first muzzle flash | `equipTime` |
| Click buffering | Click once during the draw (or a pistol's cooldown) and see whether it fires when ready | semi-auto behaviour |
| Falloff check | Phantom headshots on a bot with heavy shields a few steps either side of the Range's 20 m marker; a one-shot kill means the close band. Patch 9.10 gives the body split at 20 m, so this checks that the head values (community) split there too | Phantom head `damage` bands |
| Scoped speed | Time to cross two distance markers while scoped / ADS | `ads.moveMultiplier` |
| Tag duration | In a custom game, have a friend tag you while you hold a strafe key; frames from the hit to full speed again, against the HUD speed of a known weapon | `tagDuration`, `tagSpeedMultiplier` |
| Hitbox edges | Scoped Operator shots (no first-shot spread when scoped) at a still bot from a marked distance, stepping the crosshair off the head edge by a few pixels; with the zoomed FOV that gives an angle and so a size | `Hitboxes` sizes |

The weapon lab (F2, below) shows our value next to each reference measurement with the
difference, and the offline metrics report prints the same numbers.

## 4. Confirmed vs estimated, as implemented

All values live in `src/shared/Weapons/WeaponConfig.luau`, each with its status and source.

| Parameter | Value | Status |
| --- | --- | --- |
| Operator fire rate, leg damage, scoped speed, deadzone | 0.6 rps, 120, 72%, 15% | Confirmed |
| Deadzone, every other weapon | 27.5% | Confirmed |
| Fire rates, magazines, reloads, draw times, speeds, damage | table above | Community |
| Phantom falloff boundary and body damage | 20 m, 39 then 35 | Confirmed |
| Rifle ADS | 1.25x, fire rate x0.9 | Community |
| Rifle ADS move speed | 76% | Estimate |
| Sheriff ADS | 1.25x, fire rate x1.0, move 76% | Estimate |
| Operator scoped fire rate | x1.0 | Estimate |
| Reserve ammo | Vandal 75 (community); Phantom 60, Operator 10, Classic 36, Sheriff 24 | Estimate |
| Knife draw time | 0.75 s | Estimate |
| Tagging | 72.5% slow (confirmed) for 0.15 s (estimate) | Mixed |
| Health and shields | 100 + 50 heavy (25 light) | Community |
| Hitboxes (standing, width x height x depth) | head 0.24 x 0.26 x 0.24 m centred at 1.62 m, body 0.44 x 0.64 x 0.28 m, legs 0.34 x 0.85 x 0.26 m; crouched versions blend in with the crouch | Estimate |

What the simulation produces (from `luau tests/run.luau`):

| Weapon | Configured | Simulated | Ticks per shot | Body hits to kill 150 HP |
| --- | --- | --- | --- | --- |
| Vandal | 9.75 rps | 9.72 rps over a magazine | 13 or 14 (13.13 average) | 4 in 308 ms |
| Phantom | 11 rps | 10.98 rps | 11 or 12 (11.64 average) | 4 in 273 ms (close range) |
| Operator | 0.6 rps | 0.60 rps | 213 or 214 | 1 |
| Sheriff | 4 rps | 4.00 rps | 32 | 3 in 500 ms |
| Classic | 6.75 rps | 6.74 rps | 19 (18.96 average) | 6 in 741 ms |

Shots can only happen on 128 Hz ticks, so a fire rate that isn't a whole number of ticks alternates
between the two neighbouring tick counts. The remainder carries over, so the average stays exact
(the small shortfall above is the first-to-last span of one magazine rounding up to whole ticks).

## 5. Design

```
 client, 128 Hz                                              server, same inputs
 mouse 1 / mouse 2 / R / 1-3 ─► input {buttons, slot, aim, viewTime}  ── reliable ──►  queue ─► PlayerSim.step
                                     │                                                          │
                              PlayerSim.step (prediction)                                       ├─ MovementSim (speed = weapon x ADS x tag)
                               ├─ MovementSim                                                   └─ WeaponSim ─► Shot {tick, eye, aim}
                               └─ WeaponSim ─► Shot                                                              │
                                     │                                                           CombatServer.onShot
                         ClientShots: trace against the level and                                 ├─ level: Roblox raycast
                         the targets drawn at viewTime                                            ├─ targets: ShotResolver vs analytic hitboxes
                                     │                                                            │   (rewound to the shot's viewTime: system 4)
                         tracer, impact mark, muzzle flash (now)                                  ├─ damage by region and range ─► Health ─► tag slow
                                     │                                                            ├─ ShotResult ──► shooter: verdict
                         hit marker, damage number  ◄──────────── verdict ───────────────────────┤
                         kill feed, health          ◄──────────── Combat event (all) ─────────────┤
                         other players' tracers     ◄──────────── ShotFx (others) ────────────────┘
```

- **Weapons live in the input stream.** There is no "I fired" message. Each 128 Hz input carries
  the fire, alt-fire and reload buttons and the slot the player wants, and the server re-runs
  `PlayerSim` (movement plus `WeaponSim`) on exactly those inputs. Shots fall out of the simulation
  on both sides on the same tick, so fire rate, ammo, reload and draw times are enforced by the
  server with no extra checks, and the client's prediction of its own ammo and timers is exact.
- **One state, one reconciliation.** Ammo, timers, scope level and the tag slow are part of
  `PlayerSim.State`. The server's ack carries all of it, the client compares every field and
  rewinds and replays on any difference. The tests check that a decoded ack resumes bit for bit.
  Shots re-simulated during a replay don't replay their effects.
- **Analytic hitboxes.** A character is three yaw-oriented boxes (head, body, legs) built from a
  pose: feet position, yaw and crouch amount. The client and the server test the same boxes with
  the same code (`Hitboxes`, `ShotResolver`), and a recorded pose is all it takes to rebuild a
  target in the past, which is how system 4 rewinds them. The reference animates its server
  hitboxes; ours don't animate yet.
- **The server decides.** `CombatServer` traces the level with a Roblox raycast (characters
  excluded), then tests target hitboxes in front of the first wall, applies damage by region and
  range, shields first, tags the victim and pushes events: the verdict to the shooter, damage and
  kills to everyone, tracers to the others. A dead shooter's queued shots are rejected, like the
  reference.
- **Tagging** is applied by the server between ticks: the victim's speed is clamped at once and
  capped for the tag duration. The victim's client finds out from the next ack and reconciles.
- **The client guesses only for looks.** Tracers and impact marks use the client's own trace
  against what was on screen, so they appear instantly. Hit markers, damage numbers and the kill
  feed only come from the server. A damage number is the shot's damage after range and walls, not
  the health it took, so a Vandal headshot reads 160 on a 150 HP dummy.
- **Practice dummies are real players.** They run the same `PlayerSim` at 128 Hz with scripted
  inputs (static, strafing, crouching), replicate like players and are drawn by the client straight
  from their hitboxes, so what you see is exactly what can be hit.
- **Other players are drawn the same way for now.** The two-player test showed Roblox's default
  avatar standing 1.43 m tall inside hitboxes made for a 1.75 m agent, so its head was below the
  head box and a shot at it hit the body. Until there are agent models, each client draws other
  players as their three hitboxes (a yellow head on a red body and legs, with their name and
  health over it) and hides their Roblox avatar, including accessories and the name Roblox puts
  over it. Animating avatars waits for those models.

Roblox differences from the reference that matter here:

- Remote entities are drawn about 25-30 ms in the past (60 Hz snapshots) against the reference's
  7.8 ms. Since system 4 the server rewinds targets to what the shooter saw; the weapon lab counts
  how often its verdict and the client's guess agree.
- No animation on hitboxes. Wall penetration, using each weapon's penetration class, is system 5
  ([05-wall-penetration.md](05-wall-penetration.md)).
- Not in this system: the Classic's burst alt-fire, knife attacks, abilities, the buy phase.

## 6. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Weapons/WeaponConfig.luau` | Every weapon number with status and source; damage and shots-to-kill helpers |
| `src/shared/Weapons/WeaponSim.luau` | Deterministic weapon state machine: switch, draw, reload, scope, fire cadence |
| `src/shared/PlayerSim.luau` | Movement + weapons + tag slow as one deterministic step |
| `src/shared/Combat/Hitboxes.luau` | Head/body/legs boxes from a pose; ray vs oriented box |
| `src/shared/Combat/ShotResolver.luau` | Nearest target hit in front of the level |
| `src/shared/Combat/Health.luau` | Health and shields |
| `src/shared/Net/PlayerCodec.luau` | Inputs (19 bytes per tick), acks with the full state, snapshots (22 bytes per entity) |
| `src/server/PlayerSimServer.luau` | Authority: input queue, token bucket, acks, debug loadout |
| `src/server/CombatServer.luau` | Shot resolution against rewound targets (system 4), damage, tagging, events |
| `src/server/Entities.luau` | Registry of everything that can be shot |
| `src/server/Dummies.luau` | Practice dummies (static, strafe, crouch) |
| `src/server/Replication.luau` | Pose snapshots every server frame (60 Hz), recorded for the rewind |
| `src/server/TestRange.luau` | Adds a target lane with 10-50 m markers, cover and dummy spawns |
| `src/client/PlayerController.luau` | Prediction and reconciliation of the whole PlayerSim |
| `src/client/RemoteEntities.luau` | Snapshot interpolation for players and dummies; dummy drawing |
| `src/client/Combat/ClientShots.luau` | Client trace of each shot, matched with the server's verdict |
| `src/client/Combat/WeaponEffects.luau` | Stand-in weapon model, muzzle flash, tracers, impact marks |
| `src/client/Combat/CombatHud.luau` | Health, ammo, reload / draw bar, hit marker, damage numbers, kill feed, scope |
| `tests/weapons.luau`, `tests/combat.luau`, `tests/net.luau` | Offline tests and the weapon metrics report |

## 7. Debug tools

| Key | Tool |
| --- | --- |
| F2 | Weapon lab (first page; the second is the spray lab from system 3): weapon stats with their status, live timers, measured fire rate over the last burst, reload and draw-to-shot times against ReferenceData, a shot log of client guess vs server verdict with round trip and agreement rate, and a time-to-kill table |
| F10 | Hitbox overlay through walls: other players' hitboxes; per shot, the ray, the boxes the client tested, the client's end point (yellow) and the server's (blue), red when they disagree (system 4 adds the server's rewound boxes) |
| always | Impact marks stay on walls (newest 80), so a spray leaves its pattern (system 3 adds the spray lab and a cone ring on the crosshair) |
| Backspace | Clear impact marks and the shot log |
| 4-8 | Give Vandal / Phantom / Operator / Sheriff / Classic (Studio or place owner only) |
| 1 / 2 / 3 | Primary / secondary / knife |

The target lane is straight ahead of the spawn: static dummies at 10, 30 and 50 m, strafing ones
at 15 and 30 m, a crouching one at 20 m and one behind waist-high cover at 22 m.

## 8. Refinement loop

1. Measure fire interval, reload and draw time for each weapon (section 3) and enter them in
   ReferenceData; the lab shows the difference live.
2. Settle the Vandal's ADS fire rate and update WeaponConfig with the status changed and the clip
   as the source.
3. Measure tag duration and the hitbox edges; update `tagDuration` and `Hitboxes`.
4. Shoot the static dummies: the lab's agreement should be 100%. Since system 4 it should be about
   100% against the strafing dummies too, at any round trip under the rewind cap (the Hit Reg Lab
   adds latency to check).
5. Re-run `luau tests/run.luau` and update the table in section 4.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- Mouse buttons reach the game with the default PlayerModule's controls disabled, and right-click
  isn't taken by the camera scripts. The first Studio run found the PlayerModule in StarterPlayer,
  not PlayerScripts, in a place using Roblox's Input Action System player scripts
  (`Workspace.PlayerScriptsUseInputActionSystem`, every place's default from 2027). The client
  waited for it forever, so the client now looks in both places and starts without it.
- The viewmodel and muzzle flash sit right in front of a scriptable camera at 103 degrees.
- The `VFCharacters` collision group keeps character parts out of both the client's and the
  server's shot traces.
- Other players' avatars stay hidden, accessories that load late included, and only their blocks
  and label show.
- Humanoid death and auto-respawn with an anchored root and `BreakJointsOnDeath` off.

The [Studio test session](../studio-checklist.md) walks through these, with what to expect.
