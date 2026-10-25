# valorant-feel-roblox

Valorant-style tactical FPS mechanics rebuilt from scratch in Roblox (Luau), aiming for the same
feel, responsiveness and mechanical depth with original code and assets. Reference behaviour comes
only from public footage, patch notes, developer blogs and our own measurements.

Built one system at a time:

1. **First-person movement and counter-strafing**, with Counter-Strike's air strafing held to running
   speed - [research and design](docs/research/01-movement.md)
2. **Weapon firing**: fire modes, fire rate, ammo, reload, draw, ADS and scopes, damage, health and
   shields, hit slow, server-side hit resolution, practice dummies, and other players drawn as
   their hitboxes until there are agent models - [research and design](docs/research/02-weapon-firing.md)
3. **Spread and recoil**: firing error by bullet, recovery and tap efficiency, movement error by
   state, jump landing, aim-down-sights, recoil climb and sideways drift, seeded per-shot spread
   the server and client agree on - [research and design](docs/research/03-spread-recoil.md)
4. **Hit registration and lag compensation**: server rewind to what the shooter saw with Riot's
   140 ms cap, a render clock measured from snapshot arrivals, Network Buffering, players' and
   dummies' moves paced in the snapshots so others see them move evenly, client-predicted sparks
   and server hit confirms pinned to the body part, simulated latency, jitter and loss for testing
   in Studio - [research and design](docs/research/04-hit-registration.md)
5. **Wall penetration**: Low / Medium / High weapon classes against soft, medium, hard and solid
   materials, thickness along the ray, damage left after walls, bullets stopping inside walls,
   holes, dust and sparks, a wallbang lane - [research and design](docs/research/05-wall-penetration.md)
6. **The look**: a lighting preset that keeps shade from getting dark and values close together,
   colour grading and soft bloom, a subtle vignette, a red outline on enemies (blue on allies) that
   grows with distance, the reference's four enemy colours for colour blindness, and no character
   shadows - [research and design](docs/research/06-visuals.md)
7. **The arena**: a whitebox of Skirmish A, the reference's small-fight layout, measured from
   Riot's minimap, played by Skirmish's rules: two sides on Roblox teams, a buy phase held behind
   each spawn's barrier, rounds that end when a side is wiped out, first to 10, with a score bar
   and banners, and round restarts that respawn living players cleanly -
   [research and design](docs/research/07-arena.md)

## Running it

1. Install [Rojo](https://rojo.space) 7.x and the Rojo Studio plugin.
2. `rojo serve` in this folder, connect from Studio, press Play.
3. With no `Map` in Workspace, a measurement course with a target lane and practice dummies is
   built automatically. Look straight ahead from the spawn to face the lane; the wallbang lane is
   to the left. In a place made from the Baseplate template, delete its `Baseplate` and
   `SpawnLocation` first.
4. The arena is built beside the course, off to its right. P turns it on for everyone in the
   server: you spawn in your side's room and wait there for an opponent, and anyone who joins
   plays for the other side. P again puts everyone back on the course.
5. For a first full check, follow the [Studio test session](docs/studio-checklist.md): every
   system's Studio checks in order, with what each lab should read.

Controls: WASD, Shift walk, Ctrl/C crouch, Space jump, mouse 1 fire, mouse 2 zoom / scope,
R reload, 1/2/3 primary / secondary / knife.
Look: V turns it off and on again (lighting, vignette and outlines), to compare with the place's
own lighting; N cycles the enemy outline colour.
Arena: P turns it on and off (Studio or place owner only). In the arena, the debug keys 4-8
(below) give anyone a weapon during the buy phase, and while waiting for an opponent.
Debug: F2 weapon lab, then spray lab and hit reg lab on further presses, F3 HUD (with the next
shot's cone on the crosshair and the last jump measured; G with the HUD on shows the server
ghost), F4 counter-strafe lab (Z zeroes its cm/360 counter, Backspace clears its stops), F6 record
CSV, F10 hitbox overlay, Backspace clear impact marks, counters and the spray plot, 4-8 give
Vandal / Phantom / Operator / Sheriff / Classic (Studio or place owner only). F7 and F8 are left
alone because Studio takes them for Start and Run.
In the hit reg lab: `[` / `]` simulated latency, J jitter, L packet loss, B Network Buffering,
K rewind cap 140 / 200 / 0 ms (0 is no lag compensation); its motion line measures how evenly the
player or dummy nearest the crosshair moves.
Scripted playtests (Studio only): a tool that can press keys but can't move the mouse aims by
setting attributes on the local player, `VFTestYaw` / `VFTestPitch`, `VFTestAimPoint` or
`VFTestAimEntity` with `VFTestAimRegion` ([TestAim](src/client/Debug/TestAim.luau)).

## Tests

The shared simulation (movement, weapons, spread and recoil, hitboxes, wire formats, pose
history, render clock, move pacing, lag compensation and wall penetration), the look's maths,
and the arena's rules and map are pure Luau and run outside Roblox:

```
luau tests/run.luau
```

It prints metrics reports (start, stop and counter-strafe timings per weapon; air drift, air stops
and how far air strafing bends a jump; fire rate, magazine and time-to-kill per weapon; cone and
recoil by bullet, and tapping recovery, per weapon; client and server agreement on a strafing
target through a simulated network; how evenly other players and dummies are drawn, paced and
not; damage left through walls by class, material and thickness; the vignette across the screen
and the outline's tint by distance; the arena's size and how much of it each spawn can see) and
runs the test suites. CI also type-checks everything with `luau-lsp` and Roblox definitions.

## Rules for this project

- No game memory access, no anti-cheat circumvention, no extracted assets.
- Every gameplay number carries a status: confirmed, community, measured (ours, from a public
  source) or estimate, with its source.
- Gameplay is server-authoritative; clients predict.
