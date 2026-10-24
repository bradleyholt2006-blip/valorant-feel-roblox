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
- In the air you keep your speed, and you can steer: holding A or D while turning the mouse the
  same way bends your path (air strafing), and players chain jumps this way (bunny hopping). Unlike
  in Counter-Strike, neither makes you faster than running. Shots are inaccurate in the air and for
  a short time after landing.
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
| Bunny hopping is meant to be there, for "a slight benefit" | Before closed-beta patch 0.47 it got players through Sage's Slow Orb at speed, because the orb didn't slow you in the air: "Players were able to circumvent too much of Sage's Slow Orb by bunny hopping through the zone." The fix: "Slow Orb now also slows the air speed of players in the zone", "while still allowing for bunny hopping and walking to provide a slight benefit to traversing the zone" | Confirmed | Patch 0.47 (2020), as quoted by [GameSpot](https://www.gamespot.com/articles/valorant-patch-nerfs-razes-grenades-adjusts-sages-/1100-6476323/) and [GameRiv](https://gameriv.com/riot-nerfed-bunny-hopping-in-valorant-with-their-latest-patch-0-47/) |
| Air strafing keeps your speed while it turns you | Holding A or D and turning the mouse, "acceleration is added perfectly such that the velocity direction is the same as the camera direction", and "the velocity vector retains its magnitude while changing direction at the whim of the user". Against Source, where "if you turn your mouse too fast, your velocity's direction will stop turning and the magnitude will decrease" | Community | [Unreal forum, "How does VALORANT handle air strafing?"](https://forums.unrealengine.com/t/how-does-valorant-handle-air-strafing/586555) (2022) |
| How you air strafe | "You use the 'A' and 'D' keys combined with mouse movement and change direction mid-air" | Community | [WeCoach movement guide](https://wecoach.gg/blog/article/valorant-movement-guide-tips-to-improve-movement-in-valorant) |
| Strafing and bunny hopping don't beat running | "Valorant has capped strafe speed to be equal distance traveled with running speed" (same thread, 2025); hopping "doesn't help gain significant momentum" ([Sportskeeda](https://www.sportskeeda.com/valorant/how-use-bunny-hop-valorant)); "Denn anders als im Uralt-Counter-Strike könnt ihr durch das Hopping nicht schneller werden" (unlike the ancient Counter-Strike, hopping won't make you faster; [Mein-MMO](https://mein-mmo.de/en/valorant-bunny-hopping-made-easy-the-experts-tactic,492774), from a Reddit guide); "A failed bunny hop movement can even slow you down" ([Sportskeeda](https://www.sportskeeda.com/esports/how-to-bhop-or-bunny-hop-in-valorant)). In the 2020 beta a Discord source claimed "a maximum of 10% movement speed increase", unverified ([Upcomer](https://upcomer.com/valorants-mechanics-gunplay-classic-cs-csgo/), April 2020) | Community | As listed |
| Mouse yaw | 0.07° per count × sensitivity | Community | Widely published sensitivity converters; verify with cm/360 |
| Field of view | 103° horizontal, fixed | Community | Widely published |
| Roblox stud | 28 cm | Confirmed (Roblox) | [Roblox units](https://create.roblox.com/docs/physics/units) |

The moving-error numbers belong to the weapon system and are recorded here only because they are
the reason the deadzone matters. They are used by spread (system 3, `docs/research/03-spread-recoil.md`).

**Not found publicly:** walk speed (the 61% walk-accuracy point above is a hint), crouch speed,
acceleration from a standstill, jump height, gravity, any number for air control, collision size,
eye height, step height, max slope. All of those are estimates below. Deceleration is pinned down
by Riot's stop timings.

For comparison, how the two engines the air model draws on work, from their own code and docs:

| Engine | What it does in the air | Source |
| --- | --- | --- |
| Quake, and Source after it (Counter-Strike) | Input adds `accel × wishspeed × frametime` along the wish direction, but only up to where the velocity's share along it reaches 30: "wishspd = min(wishspd, 30);", "addspeed = wishspd - currentspeed", "accelspeed = min(accelspeed, addspeed);". Strafing across the velocity adds up to 30 sideways each frame, which turns it and speeds it up | [QuakeWorld wiki, QW physics air](https://quakeworld.nu/wiki/QW_physics_air) |
| Counter-Strike: Global Offensive and CS2 | `sv_airaccelerate` "Default is 12" | [Total CS](https://totalcsgo.com/commands/svairaccelerate) |
| Source's units | "Maps, architecture, and some prop models use a scale of roughly 1 foot ≈ 16 units", so 30 units/s is about 0.57 m/s | [Valve Developer Community, Dimensions](https://developer.valvesoftware.com/wiki/Dimensions_(Half-Life_2_and_Counter-Strike:_Source)) |
| Unreal Engine 4 (character movement) | `AirControl`: "When falling, amount of lateral movement control available to the character. 0 = no control, 1 = full control at max speed of MaxWalkSpeed." `MaxWalkSpeed`: "Also determines maximum lateral speed when falling." `BrakingDecelerationFalling`: "Lateral deceleration when falling and not applying acceleration." | [AirControl](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Engine/GameFramework/UCharacterMovementComponent/AirControl?application_version=4.27), [CharacterMovementComponent](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/CharacterMovementComponent?application_version=4.27) |

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
| Standing drift | Jump in place and hold D for the whole jump: how far to the side you land, against a floor line or a crate | `airWishSpeedCap` (ours: 0.37 m) |
| Air stop | Run, jump and hold S from take-off: how soon you stop in the air, and where you land | `airAcceleration` (ours: stopped 86 ms after take-off, landing about where you jumped) |
| Air strafe | Run, let go of W as you jump, hold D and turn the mouse right steadily. In first person a path that follows the crosshair looks like moving straight ahead while the view turns; one that lags slides sideways across the view | `airAcceleration` (ours keeps up with the mouse to about 680°/s) |
| Steering with W | Run and jump with W still held, and turn the mouse 90° in the air: does the path follow? | which model is right: Counter-Strike's (ours) doesn't steer with W until you look more than about 85° away from where you're going; Unreal's does |
| Hop speed | Time ten strafe hops along a known distance against running the same distance | `airSpeedLimit` (ours: never faster than running) |

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

In the air (Counter-Strike's model, section 5), a held key adds up to A·w each second along
itself, A being `airAcceleration` and w the wish speed, until the velocity's share along the key
reaches the cap c, `airWishSpeedCap`:

- From a standstill that takes two ticks, so a standing jump drifts at c the whole way:
  0.57 m/s for 0.66 s is 0.37 m. The standing drift measures c directly.
- Against the velocity, the key brakes at A·w, 64.8 m/s² for a rifle: 5.40 m/s stops in 83 ms
  (86 ms in whole ticks). The air stop measures A.
- Across it, each tick turns the velocity by up to atan(A·w·dt / speed), 5.35° at 128 Hz, which
  is 685° a second. Turning the mouse any slower, the velocity follows it, asin(c / speed) = 6°
  to the strafe side of the crosshair.

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
| Air acceleration / wish cap | 12 /s, 0.57 m/s (Counter-Strike's) | Estimate |
| Air speed limit | the wish speed: running, or walking with Shift held | Community (players report no gain) |
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
| Standing jump holding D | lands 0.37 m to the side | not measured |
| Running jump, letting go | 3.59 m, lands at 5.40 m/s | not measured |
| Running jump holding S | stopped in the air after 86 ms | not measured |
| Running jump holding D, mouse right at 180°/s | path bends 124° (the crosshair turns 118°), lands at 5.40 m/s | speed kept (players' reports) |
| The same at 720°/s | path bends 474°, lands at 4.95 m/s: faster than it can follow | not measured |
| Running jump holding W, mouse right at 90°/s | path doesn't bend | not measured |
| Ten strafe hops, mouse at 180°/s | never above 5.40 m/s (10.04 without the limit, as in Counter-Strike) | never above running (players' reports) |

Times are ticks of the new input until the speed is below the line, as footage times it from the
key, so ours move in steps of 7.8 ms. Letting go stops a tick before a counter-strafe because
braking snaps to zero under 10 cm/s (as Unreal does), while a counter-strafe ends when the velocity
reverses.

System 1 used a Source-style model at first, which made counter-strafing about three times as fast
as letting go (39 against 133 ms to accuracy). Riot's timings showed the reference doesn't work
that way, and the Source model's friction floor also let a slowed runner sag below the hit-slow
cap and into the deadzone. Both are gone with the model in section 5.

The first air model barely let you strafe. It used the capped wish speed (0.8 m/s) in the
acceleration as well as in the cap, so a key could change your speed by only 1.2 m/s each second:
a strafed jump bent the path by 9 degrees at most, and a standing jump drifted 0.27 m. Quake and
Source use the full wish speed there, as ours now does.

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
  the braking rate, and a held key holds any wish speed exactly.
- **Counter-Strike's air strafing, held to running speed.** In the air the input works as in
  Quake and Source: it adds up to `airAcceleration` × the wish speed per second along the wish
  direction, but only until the velocity's share along it reaches `airWishSpeedCap`. Pushing the
  way you're already going adds nothing, pushing against it brakes hard, and pushing across it
  adds a little sideways every tick, which turns the velocity: hold A or D and turn the mouse the
  same way, and the path follows the crosshair. Then input can't take the speed along the ground
  past `airSpeedLimit` × the wish speed, or past what it already was if that's faster, so strafing
  turns you without speeding you up. Counter-Strike has no such limit, which is where its
  bunny-hop speed comes from. Letting go keeps your velocity: nothing brakes you in the air.
  Crouching doesn't weaken air control, as in both engines; walking does.

  Why this and not Unreal's own air control: what players describe, a velocity that follows the
  camera and keeps its size however fast you turn, is what Counter-Strike's formula does under a
  speed limit. Ours stays 6 degrees to the strafe side of the crosshair at full speed for any
  mouse speed up to about 680 degrees a second. Unreal's `AirControl` can turn a velocity by at
  most AirControl × `maxAcceleration` ÷ speed, about 220 degrees a second for a rifle even at its
  full setting of 1, and loses speed beyond that, the very thing the description says Source
  does. Full air control would also carry a standing jump 2.9 m sideways. That makes
  Counter-Strike's formula our best estimate; the measurements in section 3, the W test above all,
  tell the two apart.
- **Custom kinematic controller.** Roblox Humanoid physics is replaced. The root part is anchored and
  positioned by the sim; collision is a collide-and-slide on an axis-aligned box using
  `Workspace:Blockcast`, with stair stepping and ground snapping (see Collision below).
- **Server authority.** The server owns position. A token bucket limits each player to 128 ticks per
  real second (no speed hacks), the queue is capped at about 190 ms (no banking time), inputs are
  validated on decode, and tuning changes are accepted only in Studio or from the place owner.
  Inputs arrive as fast as the bucket refills, so a backlog bigger than its 125 ms bank would never
  shrink by itself. The first Studio run showed one: after the server froze while a probe ran, it
  stayed about 100 ms behind the player for the rest of the session, and every shot rewound at the
  cap. A backlog that stands for 0.25 s now drains at one extra input a frame, from an allowance
  that refills at only 1 tick a second, so a client can't use it to run faster than real time.
- **Reconciliation.** The client stores its predicted state per input. When an ack disagrees by more
  than 2 mm or 1 cm/s, it rewinds to the server state, replays unacknowledged inputs, and blends the
  visual error out over about 100 ms so the camera doesn't snap.
- **Remote players** are interpolated from timestamped snapshots on a render clock that measures
  how late snapshots arrive. The server runs each player's moves as they arrive, two or three to a
  packet, so the snapshots show each move at its own time on a steady timeline instead of the
  newest one each frame (`MovePacer`), and others see them move evenly. Every input carries the
  time of the frame on screen, which is what the server rewinds targets to for hit registration
  (system 4, `docs/research/04-hit-registration.md`).

Roblox differences from the reference that matter:

- The server's Heartbeat runs at 60 Hz, so the server sub-steps the 128 Hz simulation. Inputs are
  still simulated at 128 Hz on both sides; only the network batching differs.
- Snapshots go out at 60 Hz, not 128 Hz, so other players are drawn about 25-30 ms in the past
  (measured; system 4) rather than 7.8 ms.
- Player-vs-player collision is off for now (characters ignore each other).
- Other players are drawn as blocks on their hitboxes for now, with their Roblox avatars hidden
  (system 2), so how a Humanoid animates with an anchored root waits for agent models.

### Collision

The first Studio run found the player's box inside parts in three places: sliding down the face of
a jump box after a missed jump (M5), at the foot of the 30 and 45 degree ramps (M6), and partway
along the angled wall (M7). Probes in a playtest showed why.

| Finding | Value | Status |
| --- | --- | --- |
| Blockcast ignores a part the cast starts this close to, or touching, or inside | 0.0003 studs (0.08 mm) or less | Measured (ours, Studio) |
| Blockcast reports the part from | 0.001 studs (0.28 mm) | Measured (ours, Studio) |
| Same for rotated parts and every approach angle tried (90, 30, 5 and 1 degrees) | yes | Measured (ours, Studio) |
| Hits come back short of the true contact, along the normal | 0.00007 to 0.00026 studs | Measured (ours, Studio) |
| Rotation of rotated parts as the client sees them, against the server | rounded by about 0.002 degrees | Measured (ours, Studio) |
| Positions and sizes as the client sees them | exact | Measured (ours, Studio) |

The old code backed every move off 5 mm along its direction of travel. Sliding along a surface at
a shallow angle, that left a little less gap to the surface each tick, until the gap fell inside
Blockcast's blind spot. The next cast then ignored the part and the box moved into it. At the foot
of a ramp a second fault added to it: the first tick on the slope gave the player upward speed,
which skipped the ground check, so the player went airborne and sank into the slab.

What the collision does now (`MovementSim.luau`):

- It keeps a 5 mm gap to every surface, measured straight out from the surface rather than along
  the motion, so a glancing slide can't wear it down. That is 18 times the 0.28 mm at which
  Blockcast is known to see a part.
- Every sweep looks 0.25 m past the end of its move, so a surface just beyond the end of a move
  still counts.
- Before it moves, every tick measures the exact gap to the nearby block parts and pushes the box
  back out to the 5 mm skin if it has come closer than half of that. Roblox's overlap queries only
  know a part's bounding box, which for a rotated part is much bigger than the part, so
  `BoxMath.luau` does the separating-axis test itself.
- Walking up or down a ramp keeps the horizontal speed, and the velocity stays horizontal while on
  the ground (Unreal's default walking; an estimate for the reference). On the ground, a slope
  steeper than the 46 degree maximum blocks like a vertical wall, so sliding along it can't climb it.
- The ground check runs on every grounded tick except the tick of a jump, so walking onto a slope
  can't launch the player.
- The ack carries the ground normal, so a correction on a ramp replays exactly.

The client's 0.002 degree rounding moves a walk over the whole course by at most 0.15 mm and
0.29 mm/s offline, inside the 2 mm and 1 cm/s correction tolerances. The offline tests
(`tests/FakeWorld.luau`) copy the blind spot with a 1 mm tolerance, model rotated parts, and walk
the course's ramps, angled wall and jump boxes.

## 6. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Movement/MovementConfig.luau` | Every parameter with status and source |
| `src/shared/Movement/MovementSim.luau` | Deterministic movement step (braking, acceleration, air strafing, jump, crouch, collision) |
| `src/shared/Movement/StopAnalyzer.luau` | Detects and measures stops; shared by the lab and the tests |
| `src/shared/Movement/JumpAnalyzer.luau` | Measures each time in the air: airtime, distance, how far to the side, how far the path bent, speeds; shared by the HUD and the tests |
| `src/shared/Movement/RobloxWorld.luau` | Blockcast / overlap world adapter |
| `src/shared/Movement/BoxMath.luau` | Exact gap or overlap between the player's box and a rotated block |
| `src/shared/PlayerSim.luau` | Movement and weapons stepped together (since system 2) |
| `src/shared/Net/PlayerCodec.luau` | Buffer encoding of inputs, acks and snapshots |
| `src/server/PlayerSimServer.luau` | Authority, validation, acks |
| `src/shared/Net/InputQueue.luau` | Each player's input queue: the real-time budget, the cap and the backlog drain |
| `src/server/Tuning.luau` | Live tuning overrides, pushed to every client |
| `src/server/Replication.luau` | Snapshots of every entity |
| `src/server/TestRange.luau` | Measurement course built when the place has no `Map` |
| `src/client/PlayerController.luau` | Prediction, reconciliation, rendering of the local player |
| `src/client/RemoteEntities.luau` | Snapshot interpolation for other players and dummies |
| `tests/movement.luau` | Offline movement tests and the metrics report (`luau tests/run.luau` runs all suites) |

## 7. Debug tools

| Key | Tool |
| --- | --- |
| F3 | HUD: speed (m/s and studs/s), % of max, ACCURATE / MOVING ERROR, flags, the last jump, tick, ping, pending inputs, corrections. The jump lines give its airtime, the distance it covered and how far to the side of where you faced as you left the ground, how far the path bent on the way (air strafing), and the speed along the ground leaving and landing, with the top speed between |
| always | Movement-error crosshair (same idea as the reference's option) and a W A S D / Shift / Ctrl / Space key overlay |
| always | Speed graph: 2.5 s of speed, coloured by accuracy, with the deadzone line |
| F4 | Counter-Strafe Lab: per-stop timing, slide, "overhold" coaching, averages vs ReferenceData (Riot's stop times for the rifles) over the stops that began at full speed (others are dimmed and marked `part speed`), live tuning box, cm/360 check; Backspace clears its stops |
| F6 | Recorder: per-tick CSV printed to Output for spreadsheet comparison |
| G (HUD on) | Ghost: box at the last authoritative server position (not F7: Studio takes it for Start) |
| Z (lab open) | Zero the cm/360 counter (not F8: Studio takes it for Run) |
| 1 / 2 / 3 | Primary / secondary / knife (weapon speed comes from the equipped weapon) |
| 4 / 6 | Give a Vandal / Operator to compare rifle and sniper movement (see system 2) |

Live tuning: in the lab box, type `groundFriction 3` and Enter. The server applies it and pushes it
to every client so prediction stays in sync. `reset` clears overrides. `airSpeedLimit 100` takes
the speed limit off the air, so strafe hops build speed as they do in Counter-Strike.

## 8. Refinement loop

1. Riot's stop times are in ReferenceData for the rifles. Measure the start time (standing to full
   speed, and how long the movement-error crosshair stays closed after pressing a key) and the
   stop times at today's 27.5% deadzone, and enter them.
2. If the start doesn't match, give the model a separate start acceleration; otherwise re-fit
   friction and acceleration with the formulas above, try them live in the lab, then commit them
   to MovementConfig with status changed to `community` (our own measurement) and the clip as source.
3. Repeat for walk/crouch speed, jump airtime and apex.
4. Do the air measurements: the standing drift sets `airWishSpeedCap`, the air stop
   `airAcceleration`. Compare an air strafe and a W turn with the HUD's jump lines. If W steers in
   the reference, its air control is Unreal's rather than Counter-Strike's, and the model changes.
5. Re-run `luau tests/run.luau` and update the table in section 4.
6. Play with two clients in Studio (Test > Clients and Servers) with incoming replication lag set to
   100 ms; corrections should stay at 0 while walking around.

## Known gaps to check in Studio

This was written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking with
Roblox definitions). Things only a Studio session can confirm:

- That the client's per-frame root CFrame wins over the replicated server CFrame without flicker.
- That M5 to M7 pass with the collision fix (see Collision above). Only block parts are measured
  exactly: wedges, cylinders and meshes still go by their bounding box, so the player may stop short
  of a rotated one, and the pushout before each move can't see them. The course only uses blocks.
- Whether `GetMouseDelta` needs the extra division by Roblox's sensitivity setting (cm/360 check).
- Air strafing with a real mouse at Roblox frame rates: the path should follow the crosshair and
  land at full speed (M11).
- The first Studio run showed a 76 mm correction on spawning. The client and the server each read
  the spawn point off their own copy of the new character, at different moments, so the two
  simulations started apart. The server now stores its spawn point on the character (the
  `VFSpawnFeet` attribute) and the client starts from that, so a spawn only hands over the new
  spray seed and the HUD's `max` stays at 0.0 mm.

The [Studio test session](../studio-checklist.md) walks through these, with what to expect.
