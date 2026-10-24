# System 1: First-person movement and counter-strafing

This note covers what the reference game (Valorant) does, what is publicly documented, what we
guessed, how to measure what we guessed, and how our implementation is built. All of it comes from
public patch notes, developer blogs, wikis and footage. No game files, memory or protected assets
were used, and none should be.

Status labels used throughout:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog) or shown directly in-game |
| **Community** | Published by a wiki or community measurement, not by Riot |
| **Estimate** | Our own number. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- Speed is set by the equipped weapon. The knife is fastest; heavy weapons and scoped snipers are slower.
- Walking (Shift) and crouch-walking are much slower than running and much more accurate.
- Acceleration is quick but not instant. Stopping is quicker than starting.
- Shots are only accurate while the player is (nearly) still. There is a speed threshold, the
  "deadzone", under which the weapon counts as stationary.
- Counter-strafing (tapping the opposite key) barely helps, unlike in Counter-Strike: Riot's own
  timings put it within a few milliseconds of other ways of stopping, and Riot says letting go of
  the keys is as fast. Holding the opposite key too long starts moving you the other way.
- Holding A and D together cancels out to no movement.
- Jumping gives limited air control. Shots are inaccurate in the air and for a short time after landing.
- The game ships a crosshair option, "Movement error", that visibly widens the crosshair when you
  are moving too fast to be accurate. That is our best in-game measuring tool (Settings > Crosshair).

## 2. Publicly documented details

| Fact | Value | Status | Source |
| --- | --- | --- | --- |
| Server tick rate | 128 Hz (7.8125 ms) | Confirmed | Riot tech blog, [VALORANT's 128-Tick Servers](https://technology.riotgames.com/node/112) |
| Network interpolation buffer | 7.8125 ms by default | Confirmed | [On Peeker's Advantage & Ranked](https://playvalorant.com/en-us/news/game-updates/04-on-peeker-s-advantage-ranked) |
| Peeker's advantage | about 40-70 ms total | Confirmed | Same article |
| Knife run speed | 6.75 m/s | Community | [Fandom wiki, Melee](https://valorant.fandom.com/wiki/Melee) |
| Rifle (Vandal) run speed | 5.40 m/s | Community | [Liquipedia, Vandal](https://liquipedia.net/valorant/Vandal) |
| Operator run speed | 5.13 m/s | Community | [Liquipedia, Operator](https://liquipedia.net/valorant/Operator) |
| Operator scoped speed | 72% of normal (was 76%) | Confirmed | [Patch 1.09](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-09) |
| Accuracy deadzone, Operator | inaccurate above 15% of max speed (was 30%) | Confirmed | Patch 1.09 |
| Accuracy deadzone, every other weapon | accurate below 27.5% of max speed | Confirmed | [Patch 0.50](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-0-50/): "Deadzone accuracy speed threshold increased: 25% >> 30%"; [Patch 3.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/): "Weapon Deadzones changed from 30% >>> 27.5%" |
| Jump-land inaccuracy | binary, 0.225 s, value 7.0 | Confirmed | Patch 1.09 |
| Rifle moving error | run 3.75 → 5.0, walk 0.8 → 1.1, crouch-walk 0.3 → 0.8 | Confirmed | [Patch 2.02](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-2-02/) |
| Rifle moving error (later) | walk 1.3 → 2.0 (3.0); walk 2 → 3, run 5 → 6 (9.10) | Confirmed | Patch 3.0; Patch 9.10 as quoted by [esports.gg](https://esports.gg/news/valorant/valorant-9-10-patch/) and [Sportskeeda](https://www.sportskeeda.com/valorant/new-valorant-regen-shield-weapon-changes-explained) |
| Counter-strafe accuracy timing | Riot was reviewing "how quickly players become accurate after full movement" | Confirmed (qualitative) | On Peeker's Advantage |
| Stop timings, Phantom from a full run (2020 beta) | counter-strafing: 61% speed at 0.055 s, 25% at 0.104 s, stopped at 0.160 s. Walk bound to fire, no counter-strafe: 0.065 / 0.110 / 0.170 s. Walk bound to fire with a counter-strafe: 0.060 / 0.107 / 0.166 s. Riot: "approximate because of inconsistent frame rates and human input" | Confirmed | Riot_Classick on r/VALORANT, ["Walking/Running Accuracy too high?"](https://www.reddit.com/r/VALORANT/comments/g7ql8r/) (tests by the designer Excal), via [devtrackers.gg](https://devtrackers.gg/valorant/p/f29d0021-walking-running-accuracy-too-high) |
| Letting go vs the walk key | "stopping by letting off of movement inputs or counter-strafing is faster than using walk" | Confirmed | Same post |
| Walk accuracy during a stop (2020 beta) | reached at 61% speed ("Run -> Walk (61%)"); Patch 0.50 then removed walk accuracy from stops | Confirmed | Same post; Patch 0.50 |
| Engine | Unreal Engine 4 | Confirmed | Riot tech blog, [VALORANT's 128-Tick Servers](https://technology.riotgames.com/node/112), which describes optimising Unreal's replication |
| Mouse yaw | 0.07° per count × sensitivity | Community | Widely published sensitivity converters; verify with cm/360 |
| Field of view | 103° horizontal, fixed | Community | Widely published |
| Roblox stud | 28 cm | Confirmed (Roblox) | [Roblox units](https://create.roblox.com/docs/physics/units) |

The moving-error numbers belong to the weapon system and are recorded here only because they are
the reason the deadzone matters. They are used by spread (system 3, `docs/research/03-spread-recoil.md`).

**Not found publicly:** walk speed (the 61% walk-accuracy point above is a hint), crouch speed,
acceleration from a standstill, jump height, gravity, collision size, eye height, step height, max
slope. All of those are estimates below. Deceleration is pinned down by Riot's stop timings.

## 3. What can be measured, and how

Everything here can be measured from your own gameplay footage in The Range, with no tools that
touch the game. Record at 120 fps or more with a key overlay (OBS input overlay) so you can count
frames between a key event and its effect. Enable the "Movement error" crosshair option. Each
measurement should be repeated at least 5 times; enter the average and the count in
`src/client/Debug/ReferenceData.luau`.

| Measurement | Method | Gives us |
| --- | --- | --- |
| Run / walk / crouch speed | Frames to cross a known distance at full speed (run up first) | `maxSpeed`, `walkMultiplier`, `crouchMultiplier` |
| Start time | Frames from key down until the crosshair stops widening | `maxAcceleration` (and whether it differs from the stop) |
| Release stop | Frames from key up until the movement-error crosshair snaps closed | `groundFriction`, `brakingDeceleration` |
| Counter-strafe stop | Frames from opposite-key down until the crosshair closes | checks acceleration + friction together |
| Slide distance | Release on a floor line, measure overshoot against a known-size object | cross-check for friction |
| Jump airtime | Frames from take-off to landing on flat ground | `gravity` with apex height: g = 8h / t² |
| Jump apex | Highest crate you can land on without crouch-jumping | `jumpApexHeight` |
| Step height | Smallest ledge you have to jump onto | `stepHeight` |
| Crouch / eye height | Compare camera height to objects of known height | eye heights |
| cm/360 | Mouse distance for one full turn at a known sensitivity | verifies 0.07°/count |

How a measurement maps to a parameter (our model is Unreal-style ground movement, section 5):

- Letting go brakes: v' = −(2·f·v + a), where f is `groundFriction` (doubled by
  `brakingFrictionFactor`) and a is `brakingDeceleration`. Counter-strafing decelerates through
  the input at 2·f·v + `maxAcceleration`, the same rate, because a = `maxAcceleration`.
- So the time from v0 to a threshold vt is `ln((v0 + c) / (vt + c)) / (2f)` with c = a / 2f.
  With v0 = 5.4, f = 2.75, a = 20.48 that is 0.107 s to 25% speed and 0.163 s to a stop. The
  simulation steps this at 128 Hz and crosses the two lines at 104 and 160 ms (interpolating
  between ticks), which is what Riot measured.
- Starting from a standstill there is no friction: speed rises linearly at `maxAcceleration`, so
  the time to full speed is v0 / a (0.26 s for a rifle).

Riot's two stop times fix f and a. The start time is then a prediction, and the measurement that
tests the model: if the reference reaches full speed much sooner than 0.26 s, it accelerates
harder than it decelerates on a counter-strafe, and the model needs a separate start
acceleration. The rest are direct reads.

## 4. Confirmed vs estimated, as implemented

All values live in `src/shared/Movement/MovementConfig.luau`, each with its status and source.
Since system 2, each weapon's speed is `baseRunSpeed` (the knife's 6.75 m/s) times the weapon's
`moveMultiplier` in `src/shared/Weapons/WeaponConfig.luau`, and the deadzone is
`deadzoneFraction` unless the weapon overrides it (the Operator's 15%).

| Parameter | Value | Status |
| --- | --- | --- |
| Tick rate | 128 Hz | Confirmed |
| Knife / rifle / Operator speed | 6.75 / 5.40 / 5.13 m/s | Community |
| Operator deadzone | 15% | Confirmed |
| Deadzone, every other weapon | 27.5% | Confirmed |
| Jump-land penalty time | 0.225 s | Confirmed |
| Walk / crouch multiplier | 0.61 (from Riot's 61% walk-accuracy point) / 0.35 | Estimate |
| Max acceleration = braking deceleration | 20.48 m/s² (2048 cm/s², Unreal's default) | Estimate, fitted |
| Ground friction | 2.75 /s, doubled when braking (Unreal's default factor of 2) | Estimate, fitted to Riot's stop timings |
| Air acceleration / wish cap | 1.5 /s, 0.8 m/s | Estimate |
| Gravity / jump apex | 15 m/s², 0.85 m | Estimate |
| Step height / max slope | 0.35 m / 46° | Estimate |
| Collision box | 0.68 × 1.80 m (crouch 1.25 m) | Estimate |
| Eye height | 1.62 m (crouch 1.10 m) | Estimate |

What these estimates currently produce (from `luau tests/run.luau`):

| Rifle (5.40 m/s, 27.5% deadzone) | Ours | Reference |
| --- | --- | --- |
| Standing → 95% speed | 258 ms | not measured |
| Standing → inaccurate | 78 ms | not measured |
| Counter-strafe → 25% speed | 109 ms | 104 ms (Riot) |
| Counter-strafe → stopped | 164 ms, 0.31 m slide | 160 ms (Riot) |
| Letting go → 25% speed | 109 ms | 110 ms with walk bound to fire (Riot) |
| Letting go → stopped | 156 ms, 0.31 m slide | 170 ms with walk bound to fire (Riot) |
| Letting go or counter-strafe → accurate (27.5%) | 102 ms | not measured |
| Jump apex / airtime | 0.83 m / 664 ms | not measured |

Times are ticks of the new input until the speed is below the line, as footage times it from the
key, so ours move in steps of 7.8 ms. Letting go stops a tick before a counter-strafe because
braking snaps to zero under 10 cm/s (as Unreal does), while a counter-strafe ends when the velocity
reverses.

System 1 used a Source-style model at first, which made counter-strafing about three times as fast
as letting go (39 against 133 ms to accuracy). Riot's timings showed the reference doesn't work
that way, and the Source model's friction floor also let a slowed runner sag below the hit-slow
cap and into the deadzone. Both are gone with the model in section 5.

## 5. Design

```
            client (128 Hz fixed tick)                         server (128 Hz, sub-stepped in Heartbeat)
 keys + mouse ─► InputSampler ─► input{seq,buttons,slot,yaw,pitch,viewTime}
                      │                      │  reliable RemoteEvent, 19 bytes/tick
                      ▼                      └──────────────────────────────►  queue ─► token bucket ─► MovementSim.step
               PlayerSim.step (prediction)                                                      │
                      │                       ack{seq, full state} (unreliable, 60 Hz)          │
                      ◄─────────────────────────────────────────────────────────────────────────┤
           reconcile: compare, rewind, replay                                                    │
                                                snapshot{server time, all poses} (unreliable)   │
 other clients: RemoteEntities interpolate ◄────────────────────────────────────────────────────┘
               on a render clock about 25 ms behind (system 4)
```

- **One simulation, two places.** `MovementSim` is a pure function of (state, input, config, world).
  The client runs it for instant response; the server runs the same code on the same inputs and its
  result wins. It never touches Roblox services, so it also runs in the offline test suite.
- **Metres inside, studs outside.** The sim works in SI units so every number compares directly with
  the reference. `Units` and `RobloxWorld` convert at the boundary.
- **Unreal-style ground model.** With no input, or when moving faster than the wish speed (just
  pressed walk or crouch, or drew a slower weapon), the player brakes: friction in proportion to
  speed, doubled, plus a constant deceleration, never through zero. With input, friction only
  turns the velocity toward the input (none while already moving that way) and the input
  accelerates at `maxAcceleration` up to the wish speed. A counter-strafe therefore decelerates at
  the braking rate, and a held key holds any wish speed exactly. Air control is unchanged
  (Source-style, capped wish speed).
- **Custom kinematic controller.** Roblox Humanoid physics is replaced. The root part is anchored and
  positioned by the sim; collision is a collide-and-slide on an axis-aligned box using
  `Workspace:Blockcast`, with stair stepping and ground snapping.
- **Server authority.** The server owns position. A token bucket limits each player to 128 ticks per
  real second (no speed hacks), the queue is capped at about 190 ms (no banking time), inputs are
  validated on decode, and tuning changes are accepted only in Studio or from the place owner.
- **Reconciliation.** The client stores its predicted state per input. When an ack disagrees by more
  than 2 mm or 1 cm/s, it rewinds to the server state, replays unacknowledged inputs, and blends the
  visual error out over about 100 ms so the camera doesn't snap.
- **Remote players** are interpolated from timestamped snapshots on a render clock that measures
  how late snapshots arrive. Every input carries the time of the frame on screen, which is what the
  server rewinds targets to for hit registration (system 4, `docs/research/04-hit-registration.md`).

Roblox differences from the reference that matter:

- The server's Heartbeat runs at 60 Hz, so the server sub-steps the 128 Hz simulation. Inputs are
  still simulated at 128 Hz on both sides; only the network batching differs.
- Snapshots go out at 60 Hz, not 128 Hz, so other players are drawn about 25-30 ms in the past
  (measured; system 4) rather than 7.8 ms.
- Player-vs-player collision is off for now (characters ignore each other).

## 6. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Movement/MovementConfig.luau` | Every parameter with status and source |
| `src/shared/Movement/MovementSim.luau` | Deterministic movement step (braking, acceleration, jump, crouch, collision) |
| `src/shared/Movement/StopAnalyzer.luau` | Detects and measures stops; shared by the lab and the tests |
| `src/shared/Movement/RobloxWorld.luau` | Blockcast / overlap world adapter |
| `src/shared/PlayerSim.luau` | Movement and weapons stepped together (since system 2) |
| `src/shared/Net/PlayerCodec.luau` | Buffer encoding of inputs, acks and snapshots |
| `src/server/PlayerSimServer.luau` | Authority, validation, acks |
| `src/server/Tuning.luau` | Live tuning overrides, pushed to every client |
| `src/server/Replication.luau` | Snapshots of every entity |
| `src/server/TestRange.luau` | Measurement course built when the place has no `Map` |
| `src/client/PlayerController.luau` | Prediction, reconciliation, rendering of the local player |
| `src/client/RemoteEntities.luau` | Snapshot interpolation for other players and dummies |
| `tests/movement.luau` | Offline movement tests and the metrics report (`luau tests/run.luau` runs all suites) |

## 7. Debug tools

| Key | Tool |
| --- | --- |
| F3 | HUD: speed (m/s and studs/s), % of max, ACCURATE / MOVING ERROR, flags, tick, ping, pending inputs, corrections |
| always | Movement-error crosshair (same idea as the reference's option) and a W A S D / Shift / Ctrl / Space key overlay |
| always | Speed graph: 2.5 s of speed, coloured by accuracy, with the deadzone line |
| F4 | Counter-Strafe Lab: per-stop timing, slide, "overhold" coaching, averages vs ReferenceData (Riot's stop times for the rifles), live tuning box, cm/360 check |
| F6 | Recorder: per-tick CSV printed to Output for spreadsheet comparison |
| F7 | Ghost: box at the last authoritative server position |
| F8 | Zero the cm/360 counter |
| 1 / 2 / 3 | Primary / secondary / knife (weapon speed comes from the equipped weapon) |
| 4 / 6 | Give a Vandal / Operator to compare rifle and sniper movement (see system 2) |

Live tuning: in the lab box, type `groundFriction 3` and Enter. The server applies it and pushes it
to every client so prediction stays in sync. `reset` clears overrides.

## 8. Refinement loop

1. Riot's stop times are in ReferenceData for the rifles. Measure the start time (standing to full
   speed, and how long the movement-error crosshair stays closed after pressing a key) and the
   stop times at today's 27.5% deadzone, and enter them.
2. If the start doesn't match, give the model a separate start acceleration; otherwise re-fit
   friction and acceleration with the formulas above, try them live in the lab, then commit them
   to MovementConfig with status changed to `community` (our own measurement) and the clip as source.
3. Repeat for walk/crouch speed, jump airtime and apex.
4. Re-run `luau tests/run.luau` and update the table in section 4.
5. Play with two clients in Studio (Test > Clients and Servers) with incoming replication lag set to
   100 ms; corrections should stay at 0 while walking around.

## Known gaps to check in Studio

This was written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking with
Roblox definitions). Things only a Studio session can confirm:

- That the client's per-frame root CFrame wins over the replicated server CFrame without flicker.
- Blockcast precision on rotated parts and ramps (offline tests use axis-aligned boxes only).
- Whether `GetMouseDelta` needs the extra division by Roblox's sensitivity setting (cm/360 check).
- Humanoid animation behaviour with an anchored root.
- The first Studio run showed a 76 mm correction on spawning. The client and the server each read
  the spawn point off their own copy of the new character, at different moments, so the two
  simulations started apart. The server now stores its spawn point on the character (the
  `VFSpawnFeet` attribute) and the client starts from that, so a spawn only hands over the new
  spray seed and the HUD's `max` stays at 0.0 mm.

The [Studio test session](../studio-checklist.md) walks through these, with what to expect.
