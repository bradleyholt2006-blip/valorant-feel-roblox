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
8. **Sound**: running footsteps heard by others out to a flat 20 m edge, never walking or
   crouching ones; landings heard unless they come up onto something higher; gunshots from where
   they were fired, dulled by distance and muffled through walls; reloads played in parts as
   they go, draws and dry fire; hit, headshot and kill sounds; nothing from the other side in the
   buy phase. The sounds are Pro Sound Effects' recordings from the Creator Store's free library,
   and Roblox's own character sounds are off -
   [research and design](docs/research/08-sound.md)
9. **The arsenal**: all 20 guns and the knife, with every way they fire: semi and automatic, the
   Stinger's and the Bulldog's bursts zoomed, the Classic's three-bullet right click, shotgun
   pellets that land as one hit, shell-by-shell reloads, the Outlaw's double tap, the Odin's rising
   fire rate, every zoom and scope, and suppressed guns whose tracers only their own side sees;
   Light Armor, Heavy Armor and the Regen Shield, each taking its share of a hit; and a buy menu
   on B with every gun and shield, its numbers on hover, click to buy and right-click to sell back -
   [research and design](docs/research/09-arsenal.md)

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
R reload, 1/2/3 primary / secondary / knife, B buy menu (on the course at any time; in the arena
during the buy phase and while waiting for an opponent). Nothing costs anything yet.
Look: V turns it off and on again (lighting, vignette and outlines), to compare with the place's
own lighting; N cycles the enemy outline colour.
Arena: P turns it on and off (Studio or place owner only). In the arena, the buy menu and the
debug keys 4-8 (below) work for anyone during the buy phase, and while waiting for an opponent;
a new match puts everyone back on the starting kit (Vandal, Classic, knife, Heavy Armor).
Debug: F2 weapon lab, then spray lab, hit reg lab and sound lab on further presses, F3 HUD (with the next
shot's cone on the crosshair and the last jump measured; G with the HUD on shows the server
ghost), F4 counter-strafe lab (Z zeroes its cm/360 counter, Backspace clears its stops), F6 record
CSV, F10 hitbox overlay, Backspace clear impact marks, counters and the spray plot, 4-8 give
Vandal / Phantom / Operator / Sheriff / Classic (Studio or place owner only). F7 and F8 are left
alone because Studio takes them for Start and Run.
In the hit reg lab: `[` / `]` simulated latency, J jitter, L packet loss, U Network Buffering,
K rewind cap 140 / 200 / 0 ms (0 is no lag compensation); its motion line measures how evenly the
player or dummy nearest the crosshair moves.
In the sound lab: `[` / `]` footstep radius (this client only), Y practice dummies' footsteps
(off by default), H the rings sounds draw on the floor, Backspace clears its log.
Scripted playtests (Studio only): a tool that can press keys but can't move the mouse aims by
setting attributes on the local player, `VFTestYaw` / `VFTestPitch`, `VFTestAimPoint` or
`VFTestAimEntity` with `VFTestAimRegion` ([TestAim](src/client/Debug/TestAim.luau)).
`VFTestButtons` holds input flags on top of the real ones (128 fire, 256 right click, 512 reload),
`VFTestGive` set to a weapon id gives that weapon as 4-8 would, `VFTestBuy` set to an id buys
it as the menu would (`-` and the id sells it back), and `VFTestMenu` set to true or false opens
or closes the menu. Each of the last three clears itself.
`VFTestMute` on the local player silences the game's sound while the sound lab's meters still
read.

## Tests

The shared simulation (movement, weapons and every gun's way of firing, spread and recoil,
hitboxes, wire formats, pose history, render clock, move pacing, lag compensation and wall
penetration), the look's maths, the arena's rules and map, and the sound's rules (footsteps,
landings, distance curves, walls in the way, reload parts) are pure Luau and run outside Roblox:

```
luau tests/run.luau
```

It prints metrics reports (start, stop and counter-strafe timings per weapon; air drift, air stops
and how far air strafing bends a jump; fire rate, magazine and time-to-kill per weapon; cone and
recoil by bullet, and tapping recovery, per weapon; client and server agreement on a strafing
target through a simulated network; how evenly other players and dummies are drawn, paced and
not; damage left through walls by class, material and thickness; the vignette across the screen
and the outline's tint by distance; the arena's size and how much of it each spawn can see; the
footstep curve, steps per second by weapon, and the filters for walls and distance) and runs the
test suites. CI also type-checks everything with `luau-lsp` and Roblox definitions.

## Rules for this project

- No game memory access, no anti-cheat circumvention, no extracted assets.
- Every gameplay number carries a status: confirmed, community, measured (ours, from a public
  source) or estimate, with its source.
- Gameplay is server-authoritative; clients predict.
