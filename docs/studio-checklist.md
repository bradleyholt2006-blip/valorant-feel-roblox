# Studio test session

The offline tests and the type checks cover the shared simulation; this session covers what only
Studio can show. It goes through every "Known gaps to check in Studio" item in the fifty-nine
research docs, in an order where each step only relies on things earlier steps showed working.

It takes about seven hours. Doing it in parts is fine; keep the order.

The expected values are what our code should produce (worked out from `luau tests/run.luau` and the
code itself), not the reference game's numbers, which are in the research docs. A result that
differs is what this session is for: note it and carry on, unless the step says to stop.

## What to send back

Fill in the results block at the end of this page and reply with it, plus:

- the IDs of any checks that didn't look right, with a line on what you saw
- the screenshots marked **Send**
- any red error text from the Output window, copied as text, first error first

## Before you start

1. Make a new place from the Baseplate template and delete `Baseplate` and `SpawnLocation` from
   Workspace, so only our course is there. The baseplate's top is at the same height as our floor,
   and the template's spawn pad would sit in the middle of the course as a 0.28 m step.
2. Install Rojo 7.x and its Studio plugin, run `rojo serve` in this repository and connect from
   the plugin.
3. Open the Output window (View tab, Output).
4. Press Play (F5). Sections 1 to 8 need one player, section 9 needs two, and sections 10 to 14
   need one and then two. Section 11 needs headphones. Section 15 needs one, sections 16 to 24
   one and then two, section 25 three and then one, sections 26 to 31 two, section 32 two or
   three, section 33 one and then three, section 34 one and then two, sections 35 and 36 one,
   then two, then three for their last check, section 37 one and then two, section 38 one, then
   two, then three, section 39 two and then three, section 40 one, then two, then three, sections 41
   and 42 one, then two, then two in the spike rounds, section 43 one and then three,
   sections 44 to 51 one and then three, section 52 three, section 53 two, section 54 two and then
   three, section 55 three, section 56 one and then three, section 57 one and then two, section 58
   one and then two, section 59 one and then two, section 60 two and then three, section 61 three,
   section 62 one and then two, section 63 one and then two, and section 64 one, then two, then
   one.

| Key | What it does |
| --- | --- |
| F2 | Labs, one press each: Weapon Lab, Spray Lab, Hit Reg Lab, Sound Lab, off |
| F3 | HUD panel (on at the start in Studio, off on a live server) |
| F4 | Counter-Strafe Lab |
| F6 | Record movement to a CSV in the Output window |
| G | Drops the gun or the spike in hand (not in gun game or either deathmatch, but for a Team Deathmatch spawner's gun, which it destroys); with the knife in hand and the HUD on, the ghost box where the server has you |
| F | Picks up the gun on the ground you're looking at, swapping it for yours |
| Z | A ping for your side on what the crosshair's on; held, the ping wheel (section 56). While the Counter-Strafe Lab is open, it zeroes the mouse counter too |
| [ / ] | Footstep radius down and up 2 m, this client only (while the Sound Lab is open) |
| Y | Practice dummies' footsteps on and off (while the Sound Lab is open; off at the start) |
| H | The Sound Lab's rings on the floor on and off |
| F10 | Hitbox and wall overlay |
| V | The look (lighting, vignette, outlines) off and on again, to compare with the place's own |
| N | Shows or hides the combat report (section 57); on the course, yours so far at any time |
| I | The next enemy outline colour (it was N before the combat report) |
| P | The next of: the arena (Skirmish), the 1v1 (section 68), gun game, the spike rounds, the spike rounds in Swiftplay's format, and off |
| Tab | Held: the scoreboard, in the arena and the spike rounds (at a match's end it shows by itself as the victory screen) |
| Left / right click | While you're down in the arena or the spike rounds: watch the next or the last of your living teammates |
| Mouse 3 | Opens or shuts the combat report's details, while it's up |
| Click a map | During the vote for the next map, after a match in the arena or the spike rounds: votes for it, or moves your vote to it |
| C / Q / E | Cloudburst (held, it curves the throw), Updraft, and Tailwind: E readies the gust and E again dashes. As Phoenix, E readies Curveball's flare: the left button throws it curving left, the right curving right, and E again puts it away; Q readies Hot Hands' fireball: the left button throws it, the right lobs it, and Q again puts it away; and C readies Blaze's flame: the left button sends its wall, held it bends the wall towards the crosshair, and C again puts it away |
| X | Blade Storm, once its points are full: five knives, the left button throwing one and the right all that are left; with a gun drawn, X draws them again. As Phoenix, Run it Back: it marks where you stand, and dying, or its 10 s running out, brings you back there |
| Space | Jump; held in the air, Jett's glide (Drift) slows the fall until you land or let go |
| Backspace | Clear impact marks, the shot log, the lab counters, the spray plot, and the Counter-Strafe Lab's stops and the Sound Lab's log while they're open |
| 1 / 2 / 3 | Vandal / Classic / knife (the starting loadout); with the knife, the left button slashes and the right stabs |
| 4 | The spike, while you carry it; held, it plants in a site or defuses the planted spike |
| B | The buy menu: every gun and shield (on the course at any time; in the arena during the buy phase or while waiting; never in gun game; in deathmatch any time, guns alone; in Team Deathmatch the loadout menu instead, before the match or in your spawn room) |
| O | The settings menu: your sensitivity, crosshair and the minimap's settings |
| Caps Lock | Held: the big map, in a match (the minimap at the top left is only in a match); the left button pings the place under its cursor |
| T | Agent select: a card for each agent, its kit, your side's picks and LOCK IN (on the course and while waiting any time, and in a match, where it counts down your window; not in gun game, either deathmatch or between matches) |
| 5 to 9 | Give yourself a Vandal, Phantom, Operator, Sheriff or Classic (in the arena: anyone, during the buy phase or while waiting; never in gun game or Team Deathmatch; in deathmatch any time) |
| U | Network Buffering, in the Hit Reg Lab (it was B before the buy menu) |
| A controller | The console version's layout (section 72): the left stick moves, walking tilted a little, and the right looks; RT fires; LT held is Focus or a sniper's scope, and LT with RS aims down sights; A jumps, X reloads, L3 crouches until it's pressed again, and RS is F; LB, RB and B are Q, E and C, and both bumpers X; Y swaps guns, and held draws the knife; D-pad Up is Z, Left G, Down 4 and Right B; Select tapped is the big map, held the scoreboard, and with D-pad Up, Left, Right or Down M, T, O or N; in a menu, Roblox's gamepad cursor, and B shuts it; while you're down, RT and LT switch whom you watch, and RS takes over |

Every gun is in the buy menu. A gun can also come from an attribute, which is how scripted checks
do it: with the game running, select your player under Players in the Explorer, add a string
attribute `VFTestGive` and set it to the gun's id (`classic`, `shorty`, `frenzy`, `ghost`,
`bandit`, `sheriff`, `stinger`, `spectre`, `bucky`, `judge`, `bulldog`, `guardian`, `phantom`,
`vandal`, `warden`, `marshal`, `outlaw`, `operator`, `ares` or `odin`). You get it as 5 to 9 would
give it, and the attribute clears itself, ready for the next one. `VFTestBuy` does the same as a
click in the buy menu, for a gun or a shield (`light`, `regen`, `heavy`), and sells it back with
a `-` in front (`-odin`); `VFTestMenu` set to true or false opens or closes the menu; and a number
attribute `VFTestSlot` set to 1, 2, 3 or 4 draws that slot as its key would. `VFTestGive` set to
`spike` hands you the course's spike. A number attribute `VFTestButtons` holds buttons down while
it's set, without the mouse or keys: 128 is the left button (fire, or the knife's slash), 256 the
right (zoom, or the stab), 1024 is 4 held (the spike's plant and defuse), 2048 is G, 32 crouches
and 1 is W; add them to hold several. The ability keys are 4096 for C, 8192 Q, 16384 E and 32768
X; an ability casts as its key goes down, so set the attribute and clear it again for each cast
(C kept set after a throw curves it). 65536 holds F (an Ultimate Orb's taking, or a defuse).
A boolean attribute `VFTestTake` set to true presses F for you, and clears itself, and
`VFTestBoard` set to true or false holds the scoreboard open as Tab does or lets it go.
`VFTestSettingsMenu` set to true or false opens or closes the settings menu, and a string
attribute `VFTestSetting` enters a setting as its box or button in the menu would:
`sensitivity=0.8`, `scoped=0.5`, `dpi=1600`, `crosshair=` and a code, or a map setting, as
`mapRotate=0`. `VFTestMap` set to true or false opens or closes the big map as holding Caps Lock
does. A number attribute `VFTestVote` set to 1, 2 or 3 votes for that card in the vote for the next
map, as a click on it would. In Team
Deathmatch, `VFTestLoadouts` set to true or false opens or closes the loadout menu, and a string
attribute `VFTestPick` set to `2,3` picks the second stage's third loadout, as a click on it would.
`VFTestAgents` set to true or false opens or closes agent select as T does, and a string attribute
`VFTestAgent` set to `jett` selects her card as a click would, or set to `lock` locks in.

Where things are, from the spawn, looking down the target lane:

- **Straight ahead:** the target lane, with a stripe every 10 m to 50 m and a back wall at 60 m.
  Static dummies stand at 10, 30 and 50 m, strafing ones at 15 and 30 m, a crouching one at 20 m,
  and one behind a low wall at 22 m on the right.
- **Just ahead, running to the right:** the 20 m sprint lane, with a stripe every metre and a post
  every 5 m.
- **Ahead on the right:** the angled slide wall.
- **Ahead on the left:** four red jump boxes, 0.50, 0.70, 0.85 and 1.00 m tall.
- **Far left:** the wallbang lane, ten walls 20 m ahead with a red line 10 m in front of them to
  shoot from.
- **Behind on the left:** three steps, 0.20, 0.35 and 0.50 m tall.
- **Behind on the right:** the crouch tunnel, and further right three ramps at 30, 45 and 50
  degrees.
- **4 m behind:** a grey tile marked `SPIKE`, where the spike waits.
- **26 m behind:** the spike's two sites, amber squares 6 m across marked A (behind on the left,
  with a low wall across it) and B (behind on the right), 10 m apart, with dummy 18 between them.

Dummies are box figures: a yellow head, a blue body and dark blue legs. Each has 150 HP (100 health
and 50 shields) and comes back 2 s after it dies.

## 1. Start-up

- **S1 Self-test.** Within a second of pressing Play, the Output window shows
  `[VF] penetration self-test passed: wood measured 0.200 m, concrete stopped 0.250 m in, plastic stops, metal at the limit only square on`.
  A `FAILED` line says which of our assumptions about Roblox raycasts didn't hold; copy it.
- **S2 No errors.** There is no red text in the Output window. If there is any, copy all of it and
  send it before going on, because most later checks need the scripts running.
- **S3 The course.** You spawn at the start of the target lane, facing down it, and the course
  matches the list above.

## 2. Camera and mouse

- **C1 Look and zoom.** Mouse look is smooth and the view is wide (103 degrees across). Mouse 1
  fires. Mouse 2 with the Vandal zooms in a little (1.25x) and back out, and doesn't turn the
  camera or do anything else.
- **C2 Viewmodel.** The dark block gun sits low on the right, moves to the middle while you zoom,
  and the muzzle flash shows at its tip. The camera doesn't cut off any part of it.
- **C3 Mouse counts.** Press F4, then Z to zero the counter. Move the mouse 10 cm to the right
  along a ruler, slowly and steadily, and read the counts on the `cm/360 check` line. Open the
  Roblox menu (Esc), go to Settings and change Camera Sensitivity, say from 1 to 2 (note both
  values). Close the menu, press Z and move the same 10 cm again. The counts should be the same
  both times, within a few percent: our code divides Roblox's own sensitivity out of the mouse
  movement, and this shows whether that's right. If you know your mouse's DPI, the counts should
  also be about DPI x 3.94 (3150 at 800 DPI). **Send:** both counts and both slider values.

## 3. Movement

From [01-movement.md](research/01-movement.md). Keep the HUD on.

- **M1 Speeds.** Run along the sprint lane. The HUD's `speed` tops out at 5.40 m/s with the Vandal,
  5.74 with the Classic (2) and 6.75 with the knife (3). With the Vandal, walking (Shift) gives
  3.29 m/s and crouching (Ctrl) 1.89 m/s.
- **M2 Stops.** Press F4 for the Counter-Strafe Lab, and Backspace to clear any stops already in
  it. With the Vandal, strafe along the sprint lane at full speed with A or D and stop: ten times
  by tapping the opposite key, ten times by letting go. The averages should come out at about:
  - `counter x10  accurate 102ms` and `stopped 164ms (ref 160ms, ...)`
  - `release x10  accurate 102ms` and `stopped 156ms (ref 170ms, ...)`
  - a slide of about 31 cm for both.

  The `overhold` column says `clean` when you let go of the opposite key in time. **Send:** a
  screenshot of the lab.
- **M3 Steps.** You walk up the 0.20 m and 0.35 m steps without jumping. The 0.50 m step stops you,
  and you have to jump onto it.
- **M4 Crouch tunnel.** You can't walk into it standing. Crouched you can, and if you let go of
  crouch inside, you stay crouched until you come out.
- **M5 Jump boxes.** You can jump onto the 0.50 m and 0.70 m boxes. You just miss the 0.85 m one,
  because our jump peaks at 0.83 m, and 1.00 m is out of reach. Jump pressed against a box or
  with a walk-up: from a standstill further out you fall short, because in the air you only
  reach 0.57 m/s, about 0.37 m in a jump (from 0.39 m out at rest, 0.02 m short in Studio).
- **M6 Ramps.** You walk up and down the 30 and 45 degree ramps with no bouncing or sticking. The
  50 degree ramp is too steep to walk up. The ramps are rotated parts. The offline tests now
  model them, but Roblox's own collision queries are what count here.
- **M7 Slide wall.** Run into the angled wall at a shallow angle: you slide along it smoothly,
  without sticking or shaking.
- **M8 Ghost.** G shows a box where the server has you. Standing still, it sits on you. At a run
  it trails a little behind you (by your speed times the round trip) and catches up when you stop.
  G again hides it.
- **M9 Corrections.** The HUD's `corrections` count goes up when you spawn or give yourself a
  weapon, because the server knows about those first. Moving should never add to `max`, which
  should stay at `0.0 mm`. Check it after a few minutes of running, jumping, crouching, the ramps
  and the slide wall. Then open the Hit Reg Lab (F2 three times), press `]` five times to add 50
  ms each way, and move around for another minute: `max` should still read `0.0 mm`. Press `[`
  five times to take the latency off again.
- **M10 Recorder.** Press F6, strafe and stop a few times, then F6 again. The Output window shows
  `[Recorder] N ticks. CSV follows:`, the rows, then `[Recorder] end of CSV`. There's no need to
  send it.
- **M11 Air control.** With the Vandal, watch the HUD's three `jump` lines, which describe your
  last jump: its airtime, distance and how far to the side of where you faced as you left the
  ground; how far the path bent on the way; and the speed along the ground leaving and landing,
  with the top speed between. Tap Space for each jump: held on the way down, it glides (Drift,
  section 24), and the lines read longer.
  1. Stand still, jump and hold D until you land: `jump 0.66 s  0.37 m  0.37 m right`,
     `path bent 0°`, `speed 0.00 > 0.57 m/s, top 0.57`.
  2. Run down the sprint lane, jump and let go of everything: `3.59 m  0.00 m`, `path bent 0°`,
     `speed 5.40 > 5.40`. A side or bend that rounds to nothing has no direction after it.
  3. Run, jump and hold S: you stop in the air and land within 0.3 m of where you jumped, reading
     `speed 5.40 > 0.57`.
  4. Run, let go of W as you jump, hold D and turn the mouse smoothly right, about a quarter turn
     during the jump. The view keeps moving straight ahead while it turns, and the HUD reads a
     bend of the angle you turned plus about 6 degrees (`path bent 96° right` for exactly a
     quarter turn), landing about 2.5 m to the right at `speed 5.40 > 5.40`. Try it to the left
     with A.
  5. The same quarter turn with W held instead of D: the path barely bends (about 6 degrees).
  6. Strafe-hop down the sprint lane: jump holding D with the mouse turning right, jump again the
     moment you land holding A with the mouse turning left, and so on. You can keep it going, and
     `top` never goes past 5.40. Each press has to come once you're down: one just before you land
     doesn't jump.

## 4. Weapons

From [02-weapon-firing.md](research/02-weapon-firing.md). Press F2 once for the Weapon Lab.

- **W1 Fire rate.** Hold fire with the Vandal at the back wall: the lab reads
  `fire rate 9.72 rps ... expect 9.75  within 1 tick`, and the Phantom (6) reads 10.98. The Sheriff
  (8), the Classic (9) and the Operator (7) fire once per click, and a click during the cooldown
  doesn't count. So clicking as fast as you can should come out a little under 4.00, 6.75 and 0.60
  (the lab says `OFF`), but never over. **Send:** the fire rate line for each weapon.
- **W2 Reload and draw.** Fire a few shots and press R. The lab should read `reload 2500ms` for the
  Vandal and the Phantom, 2250 for the Sheriff, 1750 for the Classic and 3700 for the Operator.
  Switch weapons with its number key and fire as soon as you can: hold fire for an automatic,
  and click again after the draw for a semi (a press during the draw isn't kept). `draw->shot`
  is at least the equip time, which is 1000 ms for the Vandal, 750 for the Classic and 1500 for
  the Operator. After a `VFTestGive` it can read about 40 ms short: the lab sees that draw only
  when the server's ack arrives.
- **W3 Damage and kills.** Shoot the static dummy at 10 m with the Vandal. The numbers that float
  up read 160 for the head, 40 for the body and 34 for the legs, and the part you hit flashes
  white. One headshot or four body shots kill it: it disappears, the kill feed shows it, and it's
  back 2 s later.
- **W4 Agreement.** Against the static dummies, the shot log's `agree` stays at 100% and every row
  says `ok`.
- **W5 First shots after spawning.** Stop the game, press Play again, and shoot the 10 m dummy
  straight away: those first shots say `ok` too. The server's first message after you spawn sets
  your spray seed ([03-spread-recoil.md](research/03-spread-recoil.md)), and it has to arrive
  before your first shot. Their rewind column reads about 40-55 ms like later shots, never
  `140ms!`, which used to happen for the first 3 s after joining. The Hit Reg Lab's render delay
  reads about 33 ms for the first 3 s, then the measured value, never hundreds of milliseconds.
  Other players and dummies may hold their poses for a moment now and then in those first
  seconds, while the snapshots come in clumps.
- **W6 Your own body.** Look down at your feet and fire. The marks land on the floor, not in the
  air above it, which would mean your own body is getting in the way of your shots. No part of
  your Roblox avatar shows when you look down, straight after pressing Play as well as after a
  respawn.
- **W7 Operator scope.** With the Operator (7), mouse 2 cycles through 2.5x, 5x and off. Scoped
  shots land exactly on the crosshair. Unscoped shots spread widely (5 degrees).

## 5. Spread and recoil

From [03-spread-recoil.md](research/03-spread-recoil.md). Press F2 twice for the Spray Lab.

- **R1 Spray pattern.** Stand on the 50 m stripe a few steps to the right of the dummy there,
  facing the back wall, which is 10 m away. Hold fire with the Vandal for a whole magazine without
  touching the mouse. On the wall, the first three marks are close together. Then they climb,
  reaching about 80 cm above where you aimed by bullet 9 and 1.1 m by bullet 16, with a side to
  side drift from bullet 7 on. The Spray Lab's dots should make the same shape as the marks
  (1 square is 1 degree, which is 17.5 cm at 10 m). **Send:** one screenshot with the wall and the
  plot both in view.
- **R2 Cone ring.** With the HUD on, fire single shots half a second apart. The ring around the
  crosshair is green, and each mark lands inside it.
- **R3 Moving error.** While you run, the ring turns red and grows, and shots spread wide. Walking,
  it's smaller. Crouched and still, it's smallest.
- **R4 Recovery.** After a spray, wait about half a second (the Vandal's 0.375 s counts from when
  it could fire again). The Spray Lab's `next shot now` line reads `bullet 1.00`, and the next
  shot lands on the crosshair.
- **R5 Camera kick at 60 and 240 fps.** The view kicks up with each shot and settles back as the
  spray recovers. If the Roblox menu (Esc, Settings) has Maximum Frame Rate, spray once at 60 and
  once at 240 (the HUD shows `fps`). The kick should feel the same and the marks on the wall
  should make the same pattern.

## 6. Hit registration

From [04-hit-registration.md](research/04-hit-registration.md). Press F2 three times for the Hit
Reg Lab and F10 for the overlay. Backspace clears the lab's counters between steps.

- **H1 Snapshots.** With nothing simulated, `snapshots` reads about 60/s with `lost 0` (it read
  69-72 in Studio before the server kept to 60), `held a pose on` is close to 0% of frames, and
  `render delay` is about 20 to 35 ms. **Send:** a screenshot.
- **H2 Strafers.** Shoot the strafing dummy at 15 m 20 times, body and head. `agreement` is 100% on
  all shots and on moving targets, `rewind` has a mean of about 40 ms (30 to 60 is fine), and
  `capped` is 0.
- **H3 Overlay.** With F10 on, each shot draws the boxes the client tested in yellow. When the
  server's answer comes back, they turn white, meaning the server tested the same pose. There
  should be no blue boxes and no red rays.
- **H4 Hit confirms.** A small dark red dot appears on the part you hit a moment after the shot.
  That's the server's confirm. It rides along with the strafing dummy for about a third of a
  second, and goes when the dummy dies.
- **H5 Latency.** Press Backspace, then `]` four times (40 ms each way), and shoot the strafer 20
  more times. Agreement stays at about 100%, the rewind mean is about 120 to 135 ms, `capped` is
  0, and the `hit confirm` mean is close to the round trip shown in the network section.
- **H6 Jitter and loss.** Press J once (0 to 5 ms of jitter) and L once (2% loss) and shoot 20
  more times. Agreement is still about 100%. The odd `snapshot` difference is fine. The jitter
  takes the round trip to about 110 ms, and with the render delay that's about 140 ms, so most
  shots now reach the cap: in BRINK 16 of 20 read `capped` and the overlay drew a blue box beside
  the yellow one on 17. The cap leaves out a few milliseconds of strafe, a few centimetres, so
  agreement holds.
- **H7 No lag compensation.** Leave the latency, jitter and loss on. Press K twice: the lab's
  rewind cap reads `0 ms (no lag compensation)`, so the server tests the strafer where it is now
  instead of where you saw it. Press Backspace and shoot the strafer 20 times at the body, then
  Backspace and 20 times at the head. Leave uneven gaps between shots, anything from a third of a
  second to a second: an even beat can fall into step with the dummy's 0.6 s strafe and land every
  shot at the same point of it. Every shot reads `capped`, because a cap of 0 moves all of them to
  the present. Agreement on moving targets falls to about a quarter for body shots and a fifth for
  head shots. With 20 shots, anything from 1 to 8 agreeing is within chance. Press K once more to
  put the cap back at 140 ms.
- **H8 Past the cap.** Press `]` four more times (80 ms each way). Then, as in H7, press Backspace
  and shoot 20 times at the body, then Backspace and 20 times at the head, with uneven gaps.
  Every shot is `capped`: the server goes back the full 140 ms, which still leaves the rest of
  the round trip and the render delay between what you saw and what it tests (in BRINK, 190 ms
  and 33 ms: about 83 ms). Agreement on moving targets is a bit under half for body
  shots (4 to 12 of 20 is within chance) and about a fifth for head shots (1 to 7). Then press `[`
  eight times, J twice and L twice to switch everything off. The HUD's red `sim` text goes away.
- **H9 Smooth movement.** Aim at the strafing dummy at 15 m and keep it within 10 degrees of the
  crosshair. The lab's `motion` line reads `Dummy_N, nearest your crosshair`. Its `speed` swings
  between 0 and 5.40 m/s as it strafes, but `biggest jump` stays green, under 0.5 m/s: no frame
  moves it much more or less than the frames either side. Before the server paced the dummies,
  this read 1 to 2.5. Press `]` four times and J once, and check it again; then press `[` four
  times and J twice to switch them off.

## 7. Wall penetration

From [05-wall-penetration.md](research/05-wall-penetration.md). Stand on the red line 10 m in
front of the wallbang walls, with F10 on and the Weapon Lab open (F2 once). From the left there's
the 0.20 m concrete wall turned 45 degrees, then wood, concrete and metal walls, each 0.10, 0.20
and 0.40 m thick. The signs on the floor say which is which. A dummy stands 1.5 m behind the middle
of each wall. Aim at the middle of a wall at chest height: after the first shot, the overlay shows
the dummy's boxes through the wall.

- **P1 Damage through walls.** Shoot each wall once at body height with the Classic (9), the Vandal
  (5) and the Operator (7, scoped). In the open at this range, a body shot does 26 with the
  Classic, 40 with the Vandal and 150 with the Operator. Through the walls, the floating numbers
  should be:

  | Wall | Classic | Vandal | Operator |
  | --- | --- | --- | --- |
  | wood 0.10 m | 17 | 32 | 129 |
  | wood 0.20 m | 10 | 26 | 118 |
  | wood 0.40 m | stops | 15 | 98 |
  | concrete 0.10 m | stops | 26 | 118 |
  | concrete 0.20 m | stops | 15 | 98 |
  | concrete 0.40 m | stops | stops | 58 |
  | metal 0.10 m | stops | stops | 88 |
  | metal 0.20 m | stops | stops | stops |
  | metal 0.40 m | stops | stops | stops |
  | concrete 0.20 m at 45 degrees | stops | stops | 81 or 82 |

  Three Operator cells sit on an edge, where the shot's slight downward angle decides them. A shot
  from eye height to the dummy's chest comes down about 2 degrees, which makes each wall a fraction
  of a millimetre thicker along the ray. Square on and dead level, 0.20 m wood and 0.10 m concrete
  would do exactly 118.5 and round to 119. 0.20 m metal is exactly the Operator's limit, so only a
  shot within about a degree of square on gets through it (38), and the 2 degree drop to the chest
  stops it. The turned wall moves by about 1 for each half degree off 45.

  The damage adds up, so a dummy can die partway through; give it 2 s to come back before the next
  shot. **Send:** any numbers that differ.
- **P2 Labels.** Each wall a shot went into gets a thick line and a label. It shows the Roblox
  material, our class, the thickness along the shot, the share of the bullet's budget it used and
  the damage left after it, for example `Wood (soft) 0.10 m  28%  x0.79` for the Vandal. The
  thickness matches the floor sign (0.28 m for the turned wall), and the label turns white a moment
  later when the server agrees. **Send:** a screenshot of any label that turns red.
- **P3 Weapon Lab.** The penetration section's `last shot` line lists the same walls and multiplier
  as the label. Its `server` value shows the same multiplier and the damage the dummy took.
- **P4 Holes, dust and sparks.** Where a bullet goes through, there's a hole and a white puff on
  the front, and another hole and puff on the back (walk round to look). Where it doesn't, there's
  a hole and an orange spark on the front only.
- **P5 Stopping inside.** When the Vandal shoots the 0.40 m concrete wall, the label says
  `stops inside` and there's no exit hole. When the Classic shoots any concrete wall, the label says
  `stops`, at the face.
- **P6 Plastic.** Shoot the light grey backstop behind the walls, or any other part of the course.
  Every bullet stops at its face.

## 8. The look

From [06-visuals.md](research/06-visuals.md). Keep the HUD on, and F10 off: its boxes show
through walls, the outlines don't. The HUD's `look` line says whether the look is on and which
enemy colour it uses.

- **V1 On and off.** The `look` line reads `look    on (V)   enemy Red (Default) (I)`. Press V: it
  reads `off`, the shade gets darker, bright parts glow more, the screen's edges are no longer
  darker and the dummies lose their outlines. In BRINK, the Explorer now shows Lighting back at
  the place's own values: Ambient and OutdoorAmbient 70, 70, 70, ShadowSoftness 0.2, the
  Atmosphere's Density 0.3 and the place's Bloom enabled, with no `VFColour` or `VFBloom` under
  Lighting (another place shows its own values). Press V again, and toggle it a few more times:
  nothing drifts. **Send:** a screenshot of the same view with the look on and off.
- **V2 Vignette.** With the look on, face the light grey backstop behind the wallbang walls. The
  screen's edges are a little darker than the middle, and the corners darker still. The HUD, the
  crosshair and the labs aren't darkened, and Mouse 1 still fires and Mouse 2 still zooms, so the
  vignette doesn't take clicks.
- **V3 Outlines.** Every dummy has a thin red outline and a faint red tint. The static dummy at
  50 m is clearly redder than the one at 10 m. The dummy behind the low wall at 22 m is outlined
  only above the wall. From the red line in front of the wallbang walls, the dummies behind them
  show no outline through the walls. **Send:** a screenshot down the target lane.
- **V4 Colours.** I turns the outlines purple, then a deep yellow, then a paler yellow, then red
  again, and the `look` line names each: `Purple (Tritanopia)`, `Yellow (Deuteranopia)`,
  `Yellow (Protanopia)`, `Red (Default)`.
- **V5 No shadows.** Stand in the sun with it behind you, so your shadow would fall ahead of you,
  and look down: your avatar casts no shadow. The dummies cast none either. With the look off (V)
  there's still none: that doesn't depend on the look.
- **V6 Lighting style.** Stop the game. Select Lighting in the Explorer and find `LightingStyle`
  in the Properties window: Studio starts places on Soft. Try Realistic, press Play and compare
  with V, then keep whichever you prefer. Scripts can't change it, so it stays your choice for the
  place. **Send:** which you kept.

## 9. Two players

Stop the game. In the Test tab, under Clients and Servers, pick Local Server with 2 players and
press Start. Studio opens a server window and two player windows. Keys go to whichever window you
clicked last.

- **T1 Smooth movement.** In each window, the other player moves smoothly as they run, stop and
  jump, with no flicker or jumping back and forth. To measure it, open the Hit Reg Lab in window 1
  (F2 three times) and keep player 2 within 10 degrees of the crosshair while they run along the
  sprint lane, holding D for at least 2 s. While they're still running, the lab's `motion` line
  names them and reads `speed 5.40 m/s`, `last second 5.40-5.40` and a green `biggest jump` under
  0.5 m/s. Before the server paced players' moves, a steady run read anywhere from about 2.5 to
  7.6 m/s, with jumps of 1 to 2.5. Then swap windows and measure player 1 the same way.
- **T2 Blocks.** Each window draws the other player like a dummy but in red: a yellow head on a red
  body and dark red legs, with their name and health over the head. Their Roblox avatar doesn't show
  at all, so there's no hair or hat poking out of the blocks and no Roblox name tag inside them.
  Press F10: the green outlines sit exactly on the blocks. With a body in ReplicatedStorage's
  `VFBodies` (section 67), the other player is drawn as it instead, the outlines round it.
- **T3 Hitting a player.** Press F10 in window 1. Player 2 strafes left and right in the target
  lane, 10 to 20 m out, and player 1 shoots them. Shots register, with damage numbers and hit
  confirms, the block that was hit flashes white (with a body, the whole body), and the overlay's
  boxes turn white on them. No impact marks appear on their body, which would mean characters block
  shots.
- **T4 Death and respawn.** Kill player 2 with one Vandal headshot or four body shots. Their screen
  shows `ELIMINATED - respawning` and the kill feed shows the kill. About 3 s later they're back at
  the spawn with full health and shields, and they can move and shoot.
- **T5 Their holes.** Player 2 shoots the wallbang walls. Player 1 sees the same holes, puffs and
  sparks in the same places.
- **T6 Corrections.** When players only move, `max` on both HUDs doesn't grow. Being shot slows you
  down, and that slow comes from the server, so it can add a few millimetres.
- **T7 Their outline.** In each window, the other player has the same red outline and tint as the
  dummies, and none shows through walls. Teammates, outlined in blue, come in section 10 (A12).

## 10. The arena

From [07-arena.md](research/07-arena.md). Stop the game and press Play (F5), for one player to
start with. The arena is built off to the course's right, about 90 m from its spawn, so you only
see it once you're in it. Keep the HUD on.

- **A1 On.** Press P. The Output window shows `[VF] Arena on: Skirmish`, and you respawn in a small room with
  a brown floor marked NORTH, looking out through its open side into a walled hall with a tall
  grey block in the middle. The score bar at the top of the screen shows `0` in blue on the left
  and `0` in red on the right, with `ARENA` and `FIRST TO 10` between them, and a banner reads
  `WAITING FOR AN OPPONENT`.
- **A2 The map.** Walk out into the hall and round it. It should match the plan in
  [07-arena.md](research/07-arena.md) (section 5): a 3 m block in the middle with a chest-high
  crate either side, two pairs of 2 m double crates angled across each half, two chest-high crates
  against each long wall, and a second room at the far end with a teal floor marked SOUTH. The
  floor's grid lines are 2 m apart, so the hall is 9.5 squares across and 12.5 long. Nothing else
  in the place pokes into the arena, and you can't jump out of it. **Send:** a screenshot from your
  room's opening, and whether the hall feels too big, about right or too small for a 1v1.
- **A3 Waiting.** While you're alone there's no barrier: you can walk out of your room straight
  away, B opens the buy menu, and 5 to 9 give you any weapon.
- **A4 Off and on.** Press P five times, through the 1v1, gun game and the spike rounds
  (sections 68, 27 and 17): the Output window shows `[VF] Arena on: 1v1, on Workspace's 1v1Map` (a
  warning instead in a place without one), then `[VF] Arena on: gun game, Skirmish A` (or `B` or
  `C`), then `[VF] Arena on: the spike rounds, Standard, on Outpost` (or `Quarry` or `Foundry`),
  then the same with `Swiftplay`, then `[VF] Arena off`, and you're back at the course's spawn, the
  score bar and banner are gone, and the dummies still have red outlines. Press P again and you're
  back in the NORTH room, facing the hall. Then hold W and press P five times more, so each new life
  starts while you're running. Each time you start at a spawn and run on from there with no snap
  back, and the HUD's `max` correction stays at `0.0 mm`. The `corrections` count can go up by one
  at each spawn, as at any spawn.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **A5 Sides.** Press P in window 1. One player spawns in the NORTH room and the other in SOUTH,
  and both screens show `ROUND 1` and a banner counting down from `BUY PHASE 15`. In the server
  window's Explorer, Teams holds North and South, with one player on each.
- **A6 The buy phase.** During the countdown, each room has a see-through orange or teal barrier
  across its open side. You can't walk through it, and a shot at it stops on it. B opens the buy
  menu and 5 to 9 change weapons. At 0 the barrier disappears, you can walk out, the menu closes
  if it was open, and until the next buy phase B does nothing and 5 to 9 change nothing, not even
  the weapon in your hands.
- **A7 Seeing each other.** Each player sees the other with the red enemy outline, never through
  walls. Standing anywhere in your own room, you can't see into the other one.
- **A8 A round.** Player 1 kills player 2. Player 1's screen shows `ROUND WON` in blue and player
  2's shows `ROUND LOST` in red, and player 1's side scores 1. About 3 s later both respawn in their
  rooms for `ROUND 2`, with `BUY PHASE 3`. Player 1, who was still alive, starts the new round
  cleanly: no snap back, and if they weren't hit, `max` stays at `0.0 mm`. Each player still has
  the weapon they had.
- **A9 First to 10.** Play on until a side has 10 (one player can stand in the open while the other
  shoots). The winner's screen shows `VICTORY` and the loser's `DEFEAT`, each with the final score
  under it, and about 6 s later round 1 of a new match starts at 0-0 with the 15 s buy phase. Both
  players are back on the starting kit: a Vandal, a Classic and Heavy Armor, whatever they bought
  before.
- **A10 Leaving.** Close player 2's window. Player 1's banner goes back to
  `WAITING FOR AN OPPONENT`, the barrier goes if it was up, and the score stays.
- **A11 Off again.** Press P five times in window 1, through the 1v1, gun game and the spike rounds.
  Player 1 is back on the course, on no team, and Teams is empty.
- **A12 Teammates (optional).** Stop the game, start a Local Server with 3 players and press P in
  window 1. Players 1 and 3 share the NORTH room, each on their own spot, and player 2 has SOUTH to
  themselves. Players 1 and 3 see each other with a faint blue outline, and their shots pass
  through each other without hurting. North loses a round only once both of its players are down.

## 11. Sound

From [08-sound.md](research/08-sound.md). Put headphones on, stop the game and press Play (F5) for
one player, on the course. Open the Sound Lab (F2 four times). Its `last sounds` list shows each
sound as it plays: whose it was, how far away, what was in the way, and why it wasn't heard when
it wasn't.

- **N1 Loading.** Within 10 s of spawning, the lab's output section reads
  `voices playing 0, loaded N of N`, with nothing still loading. **Send:** the line, if anything is
  still loading after 10 s, and any audio errors in the Output window.
- **N2 Your steps.** Run (W). You hear your own steps quietly, about three a second, and the lab's
  `your steps` line reads `heard within 20 m` in red, with a white ring of that size on the floor
  at each step. Hold Shift: the steps stop and the line reads `silent (walking or crouching)`.
  Crouching is silent too, and so is standing still.
- **N3 Jumps and landings.** Jump on the spot: a soft rustle as you leave the ground and a thud as
  you land. Jump up onto the 0.50 m red jump box: that landing is the softer one, which nobody else
  hears. Step off it onto the floor: the heard thud again. Spawning is silent: press P six times
  (the arena, the 1v1, gun game, the spike rounds twice, then off) and you appear each time without
  a sound. Nothing else plays with any of these: Roblox's own character sounds are off.
- **N4 Shots.** Fire each weapon (5 to 9 give the Vandal, Phantom, Operator, Sheriff and Classic).
  Each has its own sound. The Phantom's is the quietest and dullest, and the Operator's the
  biggest. Hold fire with the Vandal: each shot is distinct and none is cut into a click. With the
  Sound Lab open (F2 four times), the Self meter's held peak for one shot reads about 0.50 for the
  Vandal, the Operator and the Sheriff, 0.43 for the Classic and 0.35 for the Phantom: every
  recording is evened out as it plays now, mono and stereo alike (08-sound section 6), so the
  Sheriff is no longer the loudest nor the Operator and the Classic too quiet.
  **Send:** any shot that sounds too loud or too quiet next to the others, and any sound at all
  that doesn't sound like what it's for (the [table of sounds](research/08-sound.md) says what
  each one is).
- **N5 Reloads and draws.** Fire a few shots and press R. The reload plays in parts as it goes, a
  magazine out, a magazine in and a bolt or slide, the last one about as the ammo refills; the
  Sheriff's opens and closes its cylinder, and the Operator works its bolt. Press R again and
  switch weapons halfway through: the reload stops at once. Every switch plays a draw sound, and
  the knife's is a blade. Giving yourself a gun for the other slot (8 while holding a rifle)
  plays its draw once.
- **N6 Dry fire.** An empty magazine reloads itself while there's ammo in reserve, so take a fresh
  Vandal (5) and hold fire until it stops reloading (100 rounds, about 18 s). Then click: one dry
  click per click. Press 5 again for a full one.
- **N7 Hits.** Shoot a dummy in the body: a thud. In the head: a sharper, higher hit. Kill one: the
  kill sound as well. Kill several in one life: each kill sound is a little higher than the last,
  up to the fifth, and after you die it starts low again.
- **N8 Dummies' steps.** Press Y. The strafing dummy 15 m ahead starts making running steps, heard
  from where it is, with a blue ring at each one. The one at 30 m isn't heard: its steps show as
  `not heard: out of range`, with grey rings. Walk back from the 15 m one until the lab shows its
  steps at more than 20 m: they stop being heard there. Up to then they follow the footstep curve:
  as loud as close up to 2 m, 0.8 of that at 10 m and about half at 19 m (in BRINK 0.59-0.61 at
  15-16 m and 0.45-0.51 at 18.5 m). Press Y again to turn them off.

Then two players: stop the game and start a Local Server with 2 players, as in section 9. Turn the
arena on (P in window 1), keep the Sound Lab open in window 1, and play through a buy phase.

- **N9 Buy phase.** While the barriers are up, window 1 hears nothing player 2 does: their steps,
  shots and reloads show as `not heard: buy phase`. Once the barriers go, they're heard.
- **N10 Direction and walls.** Player 2 runs round player 1 in the hall. Player 1 hears each step
  from the side it's on, and nothing while player 2 walks (Shift) or crouches. Player 2 runs behind
  the middle block: their steps sound duller, and the lab shows `walls` with a lower cutoff. Player
  1's own steps, while both run, don't cover player 2's.
- **N11 Their shots and reloads.** Player 2 fires from the far end of the hall: player 1 hears it
  from there. Player 2 reloads within 15 m: player 1 hears the parts from where player 2 stands.
  Further away, nothing.
- **N12 Voice chat.** With voice chat on, no sound is heard twice.
- **N13 Muting for tests.** In the server window, select player 1 under Players and add a boolean
  attribute `VFTestMute`, ticked. Player 1 hears nothing, the lab shows `MUTED (VFTestMute)`, and
  the meters still move when player 1 fires. Untick it and the sound comes back.

## 12. The arsenal

From [09-arsenal.md](research/09-arsenal.md). One player, on the course, with the Weapon Lab open
(F2 once). Give yourself each gun with `VFTestGive` (above).

- **G1 Every gun.** Give yourself each of the 20 in turn. Each appears in your hands in its own
  shape and colour: pistols, the Ghost with a suppressor, the Shorty sawn-off, SMGs, shotguns
  with a pump, rifles, snipers with a scope, the Ares and the Odin with a box under them. Each
  has a draw sound and a gunshot of its own. The Weapon Lab's first line names the gun, its group
  and its price. **Send:** any gun that doesn't come, or that looks or sounds like another.
- **G2 Shotguns.** With the Bucky, shoot the static dummy at 10 m: a tracer for each of the 15
  pellets and a hole for each that misses, but one hit marker and one number for the pellets that
  hit, 13 each in the body. From 5 m, one shot at the middle of its body kills it: 9 of the 15
  pellets at 17 are enough. The Judge
  fires while you hold the trigger, 3.5 shots a second; the Shorty once a click.
- **G3 Bursts.** With the Bulldog, zoom (mouse 2) and click once: three rounds come out quickly.
  Hold fire: bursts of three, about two a second, the lab's state line showing `burst, 2 to
  come` as each starts. Unzoomed it's an automatic, 10 a second. The Stinger zoomed fires bursts
  of four.
- **G4 The Odin.** Hold fire at the back wall. The lab's second line shows it rising to 100%
  within a second, and its fire rate line reads about 15 rps against `expect 12.00 rising to
  15.60`. Let go and fire again: it starts at 12 again. Zoomed, it fires at 15.6 from the first
  shot.
- **G5 The Classic's right click.** With the Classic, right-click: three bullets at once, spread
  wider than a left click. Four right clicks empty the magazine, and it reloads itself.
- **G6 A round at a time.** Fire two shots with the Bucky and press R: a shell sound about every
  half second, the ammo counting 3, 4, 5, and the lab's state line reading `reloading ... (this
  round)`. Fire four and press R, then click after the second shell: it fires, and the reload
  stops with those shells in. The Marshal does the same. The Outlaw: one shot then R takes
  2300 ms on the lab's reload line, two shots then R 3800 ms.
- **G7 Scopes.** The Marshal and the Outlaw zoom 3.5x, the Warden 2x and the Guardian 1.5x; the
  Sheriff doesn't zoom at all now. Each sniper shot kicks the view up, and it settles back.

Then two players, as in section 9, with the arena on (P in window 1).

- **G8 Others' shots.** Player 2 fires a Bucky past player 1: player 1 sees 15 tracers. Player 2
  takes the Spectre or the Ghost: player 1, on the other side, sees the holes but no tracers and
  hears a quieter shot. **Send:** a screenshot of player 1's screen just after a Bucky shot.

## 13. Shields and the buy menu

From [09-arsenal.md](research/09-arsenal.md). One player on the course with the HUD on (F3), then
two.

- **B1 Opening it.** Press B. The menu fills the middle of the screen, with `BUY` and
  `THE COURSE: EVERYTHING'S FREE` along its top, four columns of guns (Sidearms; SMGs and
  Shotguns; Rifles; Snipers and Machine guns), the three shields in a fifth, and a panel on the
  right. The mouse moves a cursor and the view stays still; a click on the menu doesn't fire; WASD
  still moves you. B again closes it, and the mouse turns the view again. In a small window the
  whole menu shrinks to fit. **Send:** a screenshot with the menu open.
- **B2 The tiles.** Each has its name, its price in gold (the Classic's `FREE`), and a small side-on
  picture in the gun's colours. The Vandal, the Classic and Heavy Armor have a white edge: the
  Vandal's tile says `IN HAND` and the other two `OWNED`.
- **B3 Its numbers.** Point at the Odin: the panel reads `ODIN` and 3200, `Machine gun,
  automatic`, `Fire rate 12 rising to 15.6 a second`, `Zoomed 1.15x, 15.6 a second`, then its run
  speed, draw, reload, `Magazine 100, 200 in reserve`, `Walls High`, and its damage by range. The
  Bucky's table is headed `A pellet (of 15)`, and the Regen Shield says it takes every point of a
  hit and refills from a pool of 50, 3 s after you were last hit.
- **B4 Buying.** Click the Phantom: you're holding it, 30 / 60, and its tile has a teal edge and
  `IN HAND`, with `Bought this buy phase: right-click to sell it back` in the panel when you point
  at it. Click the Sheriff: it goes in your sidearm slot and is drawn.
- **B5 Selling back.** Press 1 to draw the Phantom, then right-click it: you're holding a Vandal
  again with a full magazine, and the Phantom's edge goes. Right-clicking the Vandal does nothing,
  since you didn't buy it.
- **B6 Shields.** Buy Light Armor: the HUD's shield reads `+25` with `LIGHT ARMOR` under it. The
  Regen Shield: `+25` and `REGEN  50 LEFT`. Heavy Armor: `+50` and `HEAVY ARMOR`.

Then two players, as in section 9, on the course.

- **B7 Armour.** Both start in Heavy Armor. Player 2 hits player 1 once in the body with the
  Vandal: player 1's HUD reads `87` and `+24` (86.4 and 23.6, rounded up), and the fourth body
  shot kills. Player 1 comes back in Heavy Armor at full health and buys Light Armor. Player 2
  hits them once in the body with the Classic, from under 30 m: `92` and `+8` (91.16 and 7.84).
- **B8 The Regen Shield.** Player 2 kills player 1, who comes back in Light Armor at full health.
  In their menu Light Armor's edge is white, not teal: a new life is a new buy phase, so it can't
  be sold back. They buy the Regen Shield. One Classic body shot: `99` and no shield, since the
  shield took 25 of the 26. About 3 s later it climbs back to `+25` over about 2 s and reads
  `REGEN  25 LEFT`. After another hit it refills once more, to `REGEN  0 LEFT`, and after the one
  after that it stays empty and its name goes. **Send:** how long after the hit the refill
  started, and how long it took.
- **B9 The arena.** Press P in window 1. Each player is on the starting kit, whatever they bought
  on the course. The menu reads `SKIRMISH: EVERYTHING'S FREE` with the buy phase's countdown, and
  closes itself when the countdown ends (A6 has the rest).
- **B10 Buying as the phase opens.** Play a round in which player 2 dies. As the next buy phase
  opens, player 1, who was still alive, presses B and clicks the Odin straight away: they come
  back in their room holding it, with its teal edge, and a right click sells it back. Player 2
  buys the Bucky in the same first moment (with `VFTestBuy`, since the menu opens only once
  they're back): they come back holding it. When player 1 died in B7, their health read `0`,
  not `-0`.

## 14. The knife

From [10-knife.md](research/10-knife.md). One player on the course, with the Weapon Lab open
(F2 once). Dummy_1 is the static dummy at 10 m, facing the spawn; its label over its head reads
its health and shield, `100 + 50` (Heavy Armor). A check that needs no mouse can draw the knife
with `VFTestSlot` 3, swing with `VFTestButtons` 128 or 256, and aim with `VFTestAimEntity` (the
dummy's id is 4294901761) and `VFTestAimRegion`.

- **K1 Swings.** Press 3. The Weapon Lab names the knife and reads `slash 2.00 a second, 2.0 m
  out, 0.8 m wide, 50 / 100 from behind   stab 0.80 a second, 1.8 m out, 0.6 m wide, 75 / 150
  from behind   combo starts over`. Hold the left button at open air: the `swings` line counts
  `slash 1`, `slash 2`, `slash 3`, `slash 1`, ..., each `500.0ms after the one before`, and the
  knife sweeps across the view right to left, then left to right, then down from the top right.
  Each slash has a sharp swish. Let go for a second and slash: it's `slash 1` again. Hold the
  right button: a `stab` every `1250.0ms`, a thrust forward with a heavier whoosh, and the combo
  starts over. Holding both slashes.
- **K2 From in front.** Walk up to Dummy_1 and slash its body from about a metre: a hit marker,
  the number `50`, a red hit confirm on its body and the blade going in (a wet stab), and its label
  reads `83 + 17`. The second makes it `50 + 0` and the third kills it, held: 1.0 s. When it's back,
  stab: `75`, its label `75 + 1` (74.5 and 0.5, rounded up), and the second stab kills it. Slash
  its head: `50` still, with the headshot sound, and a kill on the head has `HS` in the kill
  feed. The kill feed reads `<your name>   Knife   Dummy 1`, as for guns.
- **K3 From behind.** Walk past Dummy_1 and turn round to face its back. One stab kills it: `150`,
  and the Hit Reg Lab (F2 three times) reads `Dummy_1 body from behind, 150` on its `last` line.
  Two slashes do too (`100`, then `50 + 0`, then the kill). From its side, a step behind the line
  through its shoulders a stab still does 150; a step in front of it, 75.
- **K4 Reach.** Face Dummy_1 straight on, looking level, and back away a step at a time,
  slashing. On the Hit Reg Lab's `last` line, the last slash that lands reads under `0.40 m off
  the aim, 1.60 m out`: the swing's line runs 1.6 m and catches 0.4 m round it, 2.0 m in all. Do
  the same with the stab: under `0.30 m off the aim, 1.50 m out`, 1.8 m in all. **Send:** the
  last slash's and the last stab's line.
- **K5 Walls.** Slash a wall from close: a thin dark cut appears on its face at once where the aim
  meets it, with an orange spark and the blade striking metal (a click and a short ring). The
  first two slashes' cuts lie level, the third's slants up to the right, and a stab's is a short
  nick. From more than 2 m away nothing is struck. Backspace clears the cuts. (The cuts are parts
  named `Cut` in `Workspace.VFImpactMarks`.)
- **K6 Cover.** Stand against the low wall at 22 m on the right, with the dummy behind it facing
  you. Standing, slash level: you hit its head over the wall for `50`. Crouch (Ctrl) and slash:
  the blade strikes the wall instead, with a cut and the strike sound, and no damage. The Hit Reg
  Lab's `last` line reads `struck the level   1 hidden by the level`.
- **K7 The overlay.** Press F10 and slash Dummy_1's body from about a metre: a line from your eye
  along the aim, two lines 0.4 m either side and a disc at its end, a yellow dot where your client
  had it strike and the dummy's boxes as your client tested them; a moment later a blue dot where
  the server had it, its boxes white where they match yours, and a label such as `slash 1  rewind
  40 ms  Dummy_1 body 0.00 m off  50`, in white (red when your client guessed otherwise).
  **Send:** a screenshot with a slash's label showing.
- **K8 The swap.** Stab, then press 1 and 3 again straight away, and hold the right button: the
  next stab comes as soon as the knife is drawn, about 0.6 s after you pressed 3, and the Weapon
  Lab reads well under `1250.0ms after the one before`.

Then two players, as in section 9, on the course.

- **K9 Each other.** Both draw the knife. Player 2 slashes player 1 from in front: player 1's HUD
  reads `83` and `+17`. Player 2 walks round behind player 1 and stabs once: player 1 dies, and
  both kill feeds read `Player2   Knife   Player1`. Player 1 hears player 2's swings and the blade
  going in from where player 2 is. Player 2 slashes the wall beside player 1: player 1 sees the
  cut and the spark there and hears the strike. Teammates take no swing, as they take no bullet
  (A12), but that needs three players.

## 15. Settings

From [11-settings.md](research/11-settings.md). One player on the course, with the HUD on (F3).
Your settings may have been kept from an earlier session: if the menu's boxes don't read 0.4, 1
and 800 at the start, set them to those first, and press DEFAULT for the crosshair. The pixel
numbers below scale with the width of the view: they're given for 1920 pixels across, and the
HUD's `xhair` line has the real ones.

- **X1 The menu.** Press O. A panel titled SETTINGS opens over the game, the cursor shows, the view
  holds still and the crosshair in the middle of the view goes; W still moves you, a click on the
  panel doesn't fire, and B doesn't open the buy menu over it. The boxes read 0.4, 1 and 800,
  and under them `0.0280 degrees a count   12857 counts a turn   40.8 cm/360   eDPI 320` and
  `Zoomed: Vandal 51.0 cm, Guardian 61.2 cm, Operator 102.1 / 204.1 cm`. The code box reads `0;P`
  with `white; outlines 1 at 0.5; no dot; inner lines 6 long, 2 thick, 3 out, spread firing;
  outer lines 2 long, 2 thick, 10 out, spread moving and firing` under it, and the three previews
  show that crosshair on dark, grey and light. The bottom line says whether your settings can be
  kept (X9). O closes the menu. **Send:** the bottom line.
- **X2 Sensitivity.** Type 0.8 in the sensitivity box and press Enter: `0.0560 degrees a count
  6429 counts a turn   20.4 cm/360   eDPI 640`. Close the menu: the same mouse movement turns the
  view twice as far as before. In the Counter-Strafe Lab (F4) the `cm/360 check` line expects
  6429 counts a turn. Type `abc`: the box goes back to 0.8. Type 50: it reads 10, the most. Set
  the multiplier to 0.5: zoomed with the Vandal, the view turns half as far as at 1 (the Zoomed
  line reads `Vandal 102.1 cm` at 0.4). Put back 0.4 and 1, or your own settings.
- **X3 A code.** Paste `0;P;c;5;h;0;0l;4;0o;2;0a;1;0f;0;1b;0` into the code box and press Enter:
  `Using it.` and `cyan; no outlines; no dot; inner lines 4 long, 2 thick, 2 out; no outer lines`.
  The previews and, with the menu closed, the crosshair show a small cyan cross with no outline:
  four lines 4 by 2, with a 4-pixel gap between opposite ones. Under
  `PlayerGui.VFPlayerCrosshair.Centre`, `innerRight` is at (2, -1) and 4 by 2, coloured 0, 255,
  255 with transparency 0, and the `Outline` frames are hidden. The box holds the code: Ctrl+A and
  Ctrl+C copy it out. **Send:** a screenshot of the crosshair over a wall.
- **X4 Codes that aren't quite.** Enter `hello`: `Not a crosshair code: a crosshair code starts
  with a number (0;P;...).`, and the crosshair stays as it was. Enter `0;P;0o;50`: `Using it, but:
  0o 50 is outside 0-20, so it's 20.`, and the box reads `0;P;0o;20`. DEFAULT puts back `0;P` and
  the white crosshair, with a thin dark outline round each line.
- **X5 Movement error.** With the default crosshair and the Vandal, standing still, the `xhair`
  line reads `P  move +0 px  fire +0 px` and the outer lines sit 10 px from the middle. Run: the
  outer lines jump out, by about 80 px (4.2% of the view's width), and the inner lines stay. Walk
  (Shift): about 40 px. Crouch-walk: about 11. Jump on the spot: about 135 in the air, then about
  94 for a quarter of a second after landing (the landing penalty), then back. Stop: they snap
  back as the HUD reads `ACCURATE`. With the knife (3) nothing moves. **Send:** the view's width and the run, walk and air numbers.
- **X6 Firing error.** Hold fire with the Vandal at a wall for the whole magazine: both sets of
  lines move out as the spray builds, to about 10 px by the last bullet, and the top two lines
  fade, half gone by the fifth bullet and gone by the ninth. Let go: the lines come back in as the
  spray recovers, in under half a second, and the top lines come back. **Send:** the `fire` number
  at the last bullet.
- **X7 Aiming down sights.** Enter `0;s;1;P;c;1;A;c;5`: the crosshair is green, and the menu reads
  `Aiming down sights: its own crosshair, cyan.` Zoom with the Vandal (mouse 2): it turns cyan
  and the `xhair` line reads `A`. Enter `0;P;c;1;A;c;5` (no `s;1`): the menu reads `the same
  crosshair`, and zoomed it stays green and reads `P`.
- **X8 The scope.** With the Operator (7), scope in: the crosshair goes and a small red dot, 2 px
  and a little see-through, sits on the scope's cross; the `xhair` line reads `S`. Enter JUNiOR's
  code `0;s;1;P;c;5;o;1;f;0;m;1;0l;2;0v;2;0g;1;0o;0;0a;1;0f;0;1b;0;S;c;5;s;0.7;o;1`: scoped, the
  dot is cyan, 1 px and solid. Unscoped, a small cyan plus, four 2 by 2 lines meeting in the
  middle, with one solid black outline round the whole plus and none across its middle.
- **X9 Kept.** The menu's bottom line says what became of your settings. Where the place can use
  data stores, a change reads `Kept for next time.`; stop, press Play again and open the menu: `Your
  settings from last time.`, with the same sensitivity and crosshair, and that crosshair was drawn
  from the start. Where it can't (in Studio, unless the place's Game Settings, Security, allow
  API access): `Not kept between sessions here: Studio can't use data stores in this place (the
  switch is in Game Settings, Security)`, and everything else still works. Don't change the
  switch for this check. **Send:** the bottom line after a change.

## 16. The spike

From [12-spike.md](research/12-spike.md). One player on the course with the HUD on (F3), then two.
Turn round from the spawn to face the sites (`VFTestYaw` 180): A is on your right, with its low
wall, and B on your left. The HUD's `spike` line and Workspace's attributes (`VFSpike`,
`VFSpikeCarrier`, `VFSpikePosition` in metres, `VFSpikePlantedAt`, `VFSpikeHalf`, `VFSpikeSite`,
`VFSpikeEndedAt`, `VFSpikeLayout`) say where the spike is and what it's doing. There's one spike:
each check leaves it planted, gone off or defused, and a new one is back on its tile 5 s after it
goes off or is defused. Without keys, `VFTestGive` `spike` hands it to you, `VFTestSlot` 4 draws
it and `VFTestButtons` holds 4 (1024), G (2048) or crouch (32).

- **D1 Waiting.** On Play, the spike lies on its tile 4 m behind the spawn: a dark squat case with
  a dim blue band, with `SPIKE` in red over it, seen through walls. The HUD reads `spike   on the
  ground at 0.0 4.0 m`, and `VFSpike` is `dropped`, `VFSpikeLayout` `course`, `VFSpikePosition`
  (0, 0, 4) and `VFSpikeCarrier` 0. With the arena on (P) it reads `none here`. Press P five more
  times, through the 1v1, gun game and the spike rounds to off, and the spike is back on its tile.
- **D2 Picking it up.** Walk back over the tile: a metal latch as you reach it, the spike leaves
  the floor, `SPIKE  [4]` shows in red at the bottom right and the HUD reads `spike   carried by
  you`. `VFSpike` is `carried`, `VFSpikeCarrier` your UserId and `VFSpikePosition` gone. Press 4:
  the spike comes up in hand in about half a second, a dark case with a red band. 1 puts the Vandal
  back, and 4 draws it again.
- **D3 Not here.** With the spike in hand, outside the sites, hold 4: nothing starts and no
  prompt shows. Jump and hold 4 in the air over a site: nothing starts until you land, when the
  plant starts.
- **D4 Planting.** Walk into site A's front half (between the spawn and its wall) holding the
  Vandal: `HOLD 4 TO PLANT` in red under the crosshair. Hold 4: the spike is drawn, then a red bar
  fills under the prompt, labelled `PLANTING`, with a run of arming beeps, and the spike in hand
  tips toward the ground. W and Space do nothing, but the view still turns and Ctrl still
  crouches. Let go at about 2 s: the bar goes, the beeps stop, nothing is planted, and the spike is
  still in hand. Hold 4 for the whole 4 s: `SPIKE PLANTED` in red across the screen, the spike on
  the floor a little in front of you, the Vandal drawn again, and `HOLD 4 TO DEFUSE` in cyan; keep
  holding and no defuse starts, until you let go and hold 4 again (then let go: D5 needs the spike
  to count down). The HUD reads `spike   planted at A  44.9 s left`, counting down, `SPIKE  A`
  flashes red at the top of the screen as it beeps, once a second, and a faint white circle 3.2 m
  across lies round it. `VFSpike` is `planted`, `VFSpikeSite` `A`, and `VFSpikePosition` is 0.35
  m from where your feet were, the way you faced. **Send:** the HUD's spike line and the
  position, with where you stood.
- **D5 The countdown.** Watch and listen from beside it: one beep and flash a second until `20.0
  s left`, then two a second, four from `10.0 s left` and eight from `5.0 s left`. At `7.0 s left`
  a white sphere about 8 m across closes in round the spike over a second, to about 2.4 m, and
  stays. Walk back to the spawn before it goes off. **Send:** the seconds left at each change.
- **D6 The blast.** At the spawn, 27 m from A, when the HUD reaches `0.0 s left`: `SPIKE
  DETONATED` in red, a deep explosion, and a black sphere grows from the spike to 35 m in half a
  second, then fades over a second and a half. It reaches you: you die, the view goes dark as it
  passes, and the kill feed reads `SPIKE   <your name>`, the spike in red for the killer. Dummy 18,
  between the sites, dies too (`SPIKE   Dummy 18`). Dummy 1, 10 m down the target lane at (0, 0, -10),
  dies only if it's within 35 m of `VFSpikePosition`: about 34 to 36 m, depending on where in A it
  went down. Dummy 4, at 30 m (56 m away), lives. `VFSpike` is `detonated`, and 5 s later the
  spike is back on its tile (`dropped`). **Send:** Dummy 1's distance and whether it died.
- **D7 Defusing.** Take the spike to site B and plant it. Let go, then hold 4 again by it: the
  Vandal goes, a cyan bar fills from the left labelled `DEFUSING`, with a white mark at its middle,
  the spike's band turns red and its cap rises, and steady fast beeps play. Fire does nothing. Let
  go at about 5 s: the bar goes, the HUD adds `half saved`, the cap sits halfway, `VFSpikeHalf` is
  true and the prompt reads `HOLD 4 TO DEFUSE  (half saved)`. Hold again: the bar starts at its
  middle, labelled `DEFUSING  from the half`, the beeps a little higher, and 3.5 s later `SPIKE
  DEFUSED` in cyan, a falling tone, the beeping stops and the Vandal comes back. `VFSpike` is
  `defused`. **Send:** the time a whole defuse and one from the half took, if you timed them.
- **D8 Out of sight.** Take the spike to site A's low wall. Stand with your back to the wall on
  its far side (away from the spawn), facing away from it, and plant: the spike goes down about
  0.7 m behind the wall. Walk round to the near side, stand against the wall facing the spike,
  standing up, and hold 4: the defuse starts, over the wall. Crouch while holding 4: as you go
  down, the defuse stops (the bar goes, the beeping stops, the band goes back to blue). Stand up still
  holding 4: a new defuse starts, from the beginning unless the first got past the half. Then let
  it finish, or let it go off away from it.
- **D9 Dropping.** Pick it up, draw it (4) and press G in the open: a metal thud, and the spike
  lands about 1.2 m in front of your feet. Walk onto it and you have it again. Face the low wall
  from half a metre away and press G: it lands at your feet, just short of the wall, never in it
  or through it, and you don't pick it straight back up standing there: step away and back onto
  it, and you do. Press G with the Vandal out: nothing. Hold 4 in a site and press G while
  planting: nothing is dropped.

Then two players, as in section 9, on the course.

- **D10 Together.** Player 1 picks up the spike: player 2's HUD reads `carried by Player1`.
  Player 1 plants at A: player 2 hears the arming beeps from where player 1 is, sees `SPIKE
  PLANTED` and the planted spike with its circle, and hears the beeps from the spike. Player 2
  defuses it: player 1 hears the defuse's beeping from there, and sees the spike's band turn red
  and its cap rise. Then player 1 picks up the next spike and player 2 kills them: the spike drops
  where player 1 died, with a thud, and player 2 can pick it up. Plant it once more and let it go
  off with both standing at the spawn: both die.

## 17. The spike rounds

From [13-rounds.md](research/13-rounds.md). One player, then two, with the HUD on (F3). The spike
rounds' three maps, Outpost, Quarry and Foundry, are built off the course's left, 150 to 450 m from
its spawn, so you only see them once you're in one. A server's first match is on one of them at
random, and each match after it on the one the vote picks (section 29). P moves on through Skirmish,
gun game, the spike rounds, the spike rounds in Swiftplay's format, and off. Without keys, set
Workspace's attributes from the server: `VFArenaMode` `spike`, `VFMatchFormat` `standard` or
`swiftplay`, then `VFArenaOn` true (false for off). `VFMatchSkip` set true on Workspace from the
server ends the phase being played and clears itself: a buy phase, a round (as its clock running
out, so the defenders win it) or the wait for the next round, but never a planted spike's countdown.
Skip whatever a check doesn't need to wait out.

- **E1 On.** Press P four times. The Output window shows `[VF] Arena on: Skirmish A` (or `B` or
  `C`), then the 1v1's line, then gun game's, then `[VF] Arena on: the spike rounds, Standard, on
  Outpost` (or `Quarry` or `Foundry`). You respawn in a room with a red floor marked ATTACKERS,
  facing its door into mid, with the spike on the floor about 4 m in front of you: `VFSpikeLayout`
  is the map's key (`outpost`, `quarry` or `foundry`) and `VFSpikePosition` (-150, 0, 29),
  (-300, 0, 30) or (-450, 0, 34). The top bar shows `0` and `0` with `SPIKE ROUNDS` and `STANDARD`
  between them, and the banner reads `WAITING FOR AN OPPONENT`, with `Standard, first to 13. Anyone
  who joins plays for the other side   B buy menu` under it. Teams holds Orange and Teal, and you're
  on Orange. You have the Classic (2) and the knife (3), and no shield.
- **E2 The map.** Walk round it. On each of the three, the spawn's door on the left leads to site
  A, the one ahead into mid, and the one on the right to site B. Each site has an amber plant area
  marked A or B with crates round it, the dark ones low enough to shoot over standing and the light
  ones high enough to hide you. The defenders' spawn is at the far end, with a blue floor marked
  DEFENDERS, a door to mid and a hall to each site. The walls are 5 m tall: you can't jump out or
  see over them, and from anywhere in either spawn you can't see into the other. Nothing else in
  the place pokes into it. On Outpost, a lobby leads to each site's main, a long corridor, and a
  link joins each site to mid, past a pillar; Quarry and Foundry are drawn in
  [25-spike-maps.md](research/25-spike-maps.md), and section 29 visits the other two. **Send:** a
  screenshot from each site, the map's name, and whether it feels too big, about right or too
  small for 1v1 and for 2v2.
- **E3 Waiting.** Alone, there are no barriers, B opens the buy menu, and 5 to 9 give weapons.
  Walk over the spike: you pick it up (`VFSpike` `carried`). In site A's plant area no `HOLD 4 TO
  PLANT` shows and holding 4 plants nothing: `VFSpikePlantOpen` is false while you wait, and
  `VFSpikeDefusers` is 2.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **E4 Round 1.** Press P four times in window 1. Player 1 spawns in ATTACKERS and player 2 in
  DEFENDERS, facing their door to mid. Both screens show the round's clock counting down from
  `0:45`, `ROUND 1   ATTACK` under it for player 1 and `ROUND 1   DEFEND` for player 2, and a banner
  counting down from `BUY PHASE 45`. Its line reads the map's name, your credits, and then `Attack:
  plant the spike at A or B   B buy menu` for player 1, as `QUARRY   800 CREDITS   Attack: ...`,
  and `Defend A and B   B buy menu` for player 2. Each spawn's three doors have see-through
  barriers, red for the attackers' and blue for the defenders', and you can't walk through them.
  Both have the Classic and the knife, and no shield, and the spike lies in front of player 1.
- **E5 The buy phase.** B opens the menu, which reads `800 CREDITS     WIN +3000   LOSE +1900` (the
  economy, section 18). Each player presses 5 for a Vandal, which the debug keys give for free, and
  buys Light Armor. Player 1 walks over the spike and picks it up.
  At `0:00` the barriers go, the menu closes, and the clock shows `1:40` and counts down.
- **E6 Plant and defuse.** Player 1 takes the spike to site A and plants it. On both screens the
  clock gives way to `SPIKE` in red, and `SPIKE PLANTED` shows. Standing by it, player 1 gets no
  defuse prompt, and holding 4 does nothing. Player 2 comes and defuses it. Player 2's screen shows
  `ROUND WON` in blue with `Spike defused` under it, player 1's `ROUND LOST` in red with the same
  line, with no `SPIKE DEFUSED` over either, and player 2's side scores 1.
- **E7 The next round.** About 7 s later both respawn for `ROUND 2`, in the same spawns, with a
  buy phase from `BUY PHASE 30` and a new spike in front of player 1. Both still have the Vandal
  and Light Armor.
- **E8 A death costs the kit.** In round 2 player 1 kills player 2: `ROUND WON` with `Enemies
  eliminated` for player 1, and `ROUND LOST` with `Your side was eliminated` for player 2. In
  round 3 player 2 has only the Classic and the knife, with no shield, and player 1 still has the
  Vandal and Light Armor.
- **E9 Planted, then wiped out.** In round 3 player 1 plants, and player 2 kills player 1. The
  round goes on, with `SPIKE` in the bar. Player 2 leaves the spike alone: it goes off, player 1's
  screen shows `ROUND WON` with `Spike detonated`, and the blast kills player 2 if they're within
  35 m of it.
- **E10 Only attackers carry it.** In round 4, player 1 drops the spike in mid (G). Player 1 sees
  its `SPIKE` marker through walls and player 2 doesn't. Player 2 walks over it: nothing (`VFSpike`
  stays `dropped`). Nobody plants: skip the round (or wait out
  its 100 s). `ROUND WON` with `Time ran out before a plant` for player 2.
- **E11 The half.** Press P in window 1: `[VF] Arena on: the spike rounds, Swiftplay, on` one of the
  three maps, and a new match at 0-0 on it, with both players back on the Classic and the knife.
  Skip through the buy phases and rounds: the defenders win each one on time. Round 4's buy phase
  adds `LAST ROUND OF THE HALF`, and its end adds `SWITCHING SIDES`. Round 5 has player 2 in
  ATTACKERS with the spike in front of them and player 1 in DEFENDERS, both on the Classic and the
  knife again, with a buy phase from 45, and the bar reads `DEFEND` for player 1 and `ATTACK` for
  player 2. From round 5, player 2's side is on 4, and both players' buy phases add `MATCH POINT`.
- **E12 Sudden death.** Keep skipping, so player 1's side wins rounds 5 to 8 on time: 4-4. Round
  9's buy phase reads `SUDDEN DEATH`, from 45, on the second half's sides. Skip it too: player 1
  wins it 5-4 and their screen shows `VICTORY` and player 2's `DEFEAT`, each with the score, and
  `MAP VOTE IN 10` under it. About 10 s later the vote for the next map comes up (section 29 covers
  it): let it run out. 15 s later round 1 of a new match starts at 0-0, on the map with the most
  votes or, with none, any of the three, with player 1 attacking again and both on the Classic and
  the knife.
- **E13 Off.** Press P in window 1: `[VF] Arena off`. Both players are back on the course, on no
  team, Teams is empty, and the course's spike is back on its tile (`VFSpikeLayout` `course`).

## 18. The economy

From [14-economy.md](research/14-economy.md). One player, then two, with the HUD on (F3). Each
player's credits are their `VFCredits` attribute (Players, the player, Properties), and each side's
losses in a row are `Streak1` and `Streak2` on Workspace's `VFArena`. The expected numbers assume you
buy only what a check says. `VFMatchSkip` (section 17) ends a buy phase or a round, as there.

- **Q1 The pistol round's credits.** One player, on the course: B reads `THE COURSE: EVERYTHING'S
  FREE`. Press P four times for the spike rounds. B now reads `800 CREDITS`. Every gun and shield
  that costs more than 800 is dimmed with its price in red: everything from the Bucky (850) up, and
  Heavy Armor (1000). The sidearms, Light Armor (400) and the Regen Shield (650) aren't.
- **Q2 Buying and refunds.** Buy Light Armor: `400 CREDITS`. Now the Regen Shield isn't dimmed,
  since the Light Armor goes back for it: hover it, and the panel reads `250, with what you bought
  for its slot sold back`. Heavy Armor is dimmed. Buy the Regen Shield: `150 CREDITS`. Right-click
  it: `800 CREDITS` and no shield. Buy a Sheriff: `0 CREDITS` and the Sheriff in hand. Every gun for
  the primary slot and every shield is dimmed, and the other sidearms aren't, since the Sheriff goes
  back for any of them. Right-click the Sheriff: `800 CREDITS` and the Classic back.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **Q3 Round 1.** Press P four times in window 1. Both players' buy phase line starts with the
  map's name and then `800 CREDITS` in gold, and both have `VFCredits` 800. Player 1's menu reads
  `800 CREDITS     WIN +3000   LOSE +1900`.
- **Q4 A kill pays at once.** Skip the buy phase. Player 1 kills player 2 with the Classic: player
  1's `VFCredits` goes to 1000 as player 2 dies. Player 2's stays 800.
- **Q5 The next round pays.** In round 2's buy phase player 1 has 4000 (800, the kill's 200 and the
  win's 3000) and player 2 has 2700 (800 and a first loss's 1900). `Streak2` is 1 and `Streak1` 0.
  Player 2's menu reads `WIN +3000   LOSE +2400`, and player 1's `WIN +3000   LOSE +1900`.
- **Q6 Sold back to nothing.** Player 1 buys a Vandal: `1100 CREDITS`, the Vandal in hand. Right-click
  it: `4000 CREDITS`, the primary slot empty and the Classic drawn. Buy a Spectre: `2400 CREDITS`.
  Hover the Vandal: `1300, with what you bought for its slot sold back`. Buy it: `1100 CREDITS`, the
  Vandal in hand and no Spectre. Buy Light Armor: `700 CREDITS`.
- **Q7 A shield kept damaged.** Skip the buy phase. Player 2 shoots player 1 once in the body with
  the Classic, and doesn't kill them. Player 1's HUD shows Light Armor down to about 8. Nobody
  plants: skip the round. Player 2's side wins on time.
- **Q8 A loss survived.** In round 3's buy phase, player 1 has 1700: 700 and the survivor's 1000,
  not a loss's 1900, as they lived through the round without a plant. Player 2 has 5700 (2700 and the
  win's 3000). Player 1 still has the Vandal, and Light Armor at the same 8 or so, not a fresh 25.
  Buy Light Armor: a fresh 25 for `1300 CREDITS`. Right-click it: `1700 CREDITS`, and the shield is
  back to its damaged 8.
- **Q9 The plant pays every attacker.** Skip the buy phase. Player 1 plants at A: player 1's
  `VFCredits` goes up 300 as the plant lands. Player 2 stays more than 35 m from the spike, and it
  goes off.
- **Q10 Surviving the blast.** In round 4's buy phase, player 2 has 6700: 5700 and the survivor's
  1000, as they lived through the detonation. Player 1 has 5000 (1700, the plant's 300 and the
  win's 3000).
- **Q11 Swiftplay.** Press P in window 1 for Swiftplay: a new match, both on 800 with the Classic and
  the knife. Skip every phase, so the defenders win each round on time:

  | Round | Player 1 | Player 2 |
  | --- | --- | --- |
  | 2 | 3200 | 3800 |
  | 3 | 7450 | 8050 |
  | 4 | 9000 | 9000 |
  | 5 | 800 | 800 |
  | 6 | 3800 | 3200 |
  | 9 | 5000 | 5000 |

  Round 2 pays both 2400, and player 2's side the bonus of 600 for winning round 1. The attackers
  get no survivor's credits in Swiftplay. Rounds 3 and 4 pay 4250 each, and nobody holds more than
  9000. Round 5 starts the half over, and round 9, the Endgame, everyone on 5000. Round 3's menu
  reads `THIS ROUND PAYS +4250`.
- **Q12 Off.** Press P in window 1: `[VF] Arena off`. Neither player has
  `VFCredits`, and B reads `THE COURSE: EVERYTHING'S FREE` again, with nothing dimmed.

## 19. Guns on the ground

From [15-ground-guns.md](research/15-ground-guns.md). One player on the course, then two, with the
HUD on (F3). Every gun on the ground is a part in Workspace's `VFGroundGuns`, named by its number,
with its `Weapon`, `Ammo` and `Reserve` as attributes (Properties, Attributes). Without keys, G is
`VFTestButtons` 2048, and F is `VFTestTake` true with `VFTestAimPoint` set to the gun's position.

- **L1 G drops it.** On the course, draw the Vandal (1) and look straight ahead down the target
  lane. Press G. The Vandal leaves your hands and the Classic comes out. A Vandal, in its stand-in
  look, lies on its side on the floor about 1.2 m in front of your feet, its muzzle pointing down
  the lane. `VFGroundGuns` holds a part `1` with `Weapon` `vandal`, `Ammo` 25 and `Reserve` 50.
- **L2 Walking over it.** Walk forward over the Vandal. It's gone from the floor and from
  `VFGroundGuns`, and the Classic stays in your hands. Press 1: the Vandal comes out, with 25
  rounds.
- **L3 The rounds go with it.** Fire 5 rounds (20 left) and press G. The part shows `Ammo` 20.
  Walk over it and press 1: 20 in the magazine, not 25.
- **L4 The prompt.** Press G again, so the Vandal is on the floor, then press 6 for a Phantom.
  Look down at the Vandal: it's outlined in white, and under the crosshair the prompt reads `F
  SWAP FOR VANDAL`. Look away: the outline and the prompt go. **Send** a screenshot with the
  prompt showing.
- **L5 The swap.** Look back at the Vandal and press F. The Vandal comes out in your hands, and a
  Phantom lies where the Vandal was. Turn a quarter to the right and press G: the Vandal lands
  there. Look at the Phantom: `F  PICK UP PHANTOM`, as your primary slot is empty. Press F: the
  Phantom is drawn.
- **L6 Reach.** Walk backwards from the Vandal, looking at it. The prompt goes when you're about
  2.5 m away along the floor (3 m from your eye). Walk back: it comes back. Note the distance.
- **L7 Not through walls.** Stand at the tallest red jump box (1.00 m) and drop a gun so it lands
  about a metre from the box. Walk round to the box's other side and crouch against it, so the
  box is between your eye and the gun. Look where the gun is: no outline and no prompt. Stand up
  and step back until you can see it: they come back.
- **L8 Short of a wall.** Face a wall from about half a metre away and press G. The gun lands on
  the floor just short of the wall, not in it or through it.
- **L9 The knife and the spike.** Press 5 for a Vandal. Draw the knife (3) and press G: nothing
  drops, and the ghost box shows (the HUD is on). Press G again to hide it. Hand yourself the spike
  (`VFTestGive` `spike`) and draw it (4). Press G: the spike drops, not a gun, and the Vandal comes
  back.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **L10 The other player sees it.** On the course, player 1 drops the Vandal with G. In window 2
  it lands where player 1 threw it. Player 2 walks up to it, looks at it and presses F: window 1
  sees it go, and player 2's Vandal lands in its place.
- **L11 The dead drop theirs.** Press P four times in window 1 for the spike rounds. In round 1's
  buy phase, player 1 presses 5 for a Vandal. Skip the buy phase. Player 2 kills player 1 with the
  Classic. A Vandal lies where player 1 fell, with `Ammo` 25, and no Classic beside it.
- **L12 Kept into the next round.** Before round 2 starts (the round's end lasts a few seconds),
  player 2 walks over the Vandal and picks it up, as their primary slot is empty. In round 2's buy phase player 2 still has it, and player 1 is back on the Classic
  and the knife.
- **L13 Nothing to sell back.** Still in round 2's buy phase, player 1 buys a Spectre: `1100
  CREDITS`. Press G: the Spectre is on the floor. Open the menu: still `1100 CREDITS`, and
  right-clicking the Spectre sells nothing. Walk over it to take it back: still nothing to sell
  back, and still `1100 CREDITS`.
- **L14 The sidearm, without a primary.** Skip the buy phase. Player 1 drops the Spectre with G and
  steps back from it. Player 2 kills player 1. A Classic lies where player 1 fell, as they had no
  primary.
- **L15 The ground cleared.** At round 3's buy phase the floor is bare: `VFGroundGuns` is empty.
- **L16 Off.** Drop a gun, then press P in window 1 until `[VF] Arena off`: `VFGroundGuns` is
  empty again.

## 20. The round at a glance

From [16-scoreboard.md](research/16-scoreboard.md). One player on the course, then two in the spike
rounds. Without keys, Tab is `VFTestBoard` true on your player (false lets it go). Each player's
record is in their attributes (select them under Players, then Properties, Attributes): `VFKills`,
`VFDeaths`, `VFAssists`, `VFScore`, `VFRounds`, `VFCredits` and `VFStartCredits` in the spike
rounds, and `VFAlive` and `VFLoadout` in either the arena or the spike rounds.

- **J1 The kill feed.** On the course, kill Dummy 1, the static dummy 10 m down the target lane,
  with Vandal body shots. At the top right a line reads `<your name>   Vandal   Dummy 1`, your
  name in blue and the dummy's in red, outlined in gold as you're in it. It goes after about 6 s.
  **Send:** a screenshot with the line showing, and how long it stayed.
- **J2 Headshots.** When it's back, kill it with one headshot: the line reads `<your name>
  Vandal   HS   Dummy 1`, with `HS` in yellow.
- **J3 Through a wall.** At the wallbang lane, kill the dummy behind the 0.10 m wood wall with
  Vandal shots through the wall: its line has `WALL` in grey before the dummy's name. The kills in
  the open, in J1 and J2, had none.
- **J4 Six at most.** Kill dummies as fast as you can, the static ones and the strafers. The
  newest line is always at the top, and no more than six show at once.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **J5 Skirmish.** Press P once in window 1. Beside the top bar, window 1 shows a tile with the
  first two letters of player 1's name on its left, in blue, and one for player 2 on its right, in
  red; window 2 the other way round. Tab opens Roblox's own player list, not ours.
- **J6 The tiles in the spike rounds.** Press P three times more, through the 1v1 and gun game to
  the spike rounds: the tiles stay. Skip round 1's buy phase (`VFMatchSkip`). Player 1 kills
  player 2 with the Classic, and player 2 doesn't shoot back. Player 2's tile dims on both screens.
  Both kill feeds read `Player1   Classic   Player2`, outlined in gold on both, as both are in it:
  in window 1 player 1's name is blue, and in window 2 it's red.
- **J7 The scoreboard.** In window 1, hold Tab. Roblox's player list doesn't open. Ours has `1`
  and `0` either side of `STANDARD   ROUND 1` across its top, then player 1's row, their name in
  gold on a gold-tinted row: `1 0 0`, ACS `170` (100 damage and 70 for the kill, over one round),
  `1000` credits and `CLASSIC`. Below it player 2's row, their name dimmed: `0 1 0`, ACS `0`,
  `800`, and no loadout. In window 2, player 2's row is first, with no loadout as their Classic
  dropped where they fell, and player 1's shows `800` credits, what they had as the round started,
  and no loadout. Let go of Tab: it's gone. **Send:** a screenshot of each.
- **J8 The other side's credits.** In round 2's buy phase, window 1's board shows `4000` for player
  1 and `2700` for player 2. Player 2 buys a Spectre: window 2's board shows `1100` and `SPECTRE`
  on player 2's row, and window 1's still shows `2700` for player 2, with no loadout. Player 1
  buys Light Armor: window 1's board shows `3600` and `CLASSIC  LIGHT` on player 1's row.
- **J9 The average.** Skip the buy phase. Player 2 kills player 1, who doesn't shoot back. Both
  players' `VFRounds` is 2: player 1's ACS reads `85` (170 over 2), and player 2's is their
  `VFScore` over 2, to the nearest point.
- **J10 Off.** Press P in window 1 until `[VF] Arena off`. The tiles go, Tab opens Roblox's player
  list again, and neither player has `VFKills` or the other record attributes any more.

With three players (optional): start a Local Server with 3 players, and press P four times in
window 1 (the spike rounds). Two of them share a side (Teams shows who).

- **J11 Assists.** Skip the buy phase. One of the pair shoots the player on their own once, then
  the other kills them: the first one's row shows `0 0 1`, and the killer's `1 0 0`.

## 21. The ability kit

From [17-abilities.md](research/17-abilities.md). One player on the course with the HUD on (F3),
then two in Skirmish and the spike rounds. Each player's kit is their `VFKit` attribute (select
them under Players, then Properties, Attributes): each slot's charges and the most it holds, then
the ultimate's points and what it needs, as `C0/2 Q1/1 E1/1 X0/8`, with `lift` or `dash`, and
`windup` or `ready`, after it while one's under way. Without keys, `VFTestButtons` presses Q
(8192) or E (16384): set it, then clear it.

- **U1 The bar.** At the bottom of the screen, between your health and your ammo, four squares:
  `C` CLOUDBURST, `Q` UPDRAFT, `E` TAILWIND and `X` BLADE STORM. C's square has two pips, Q's one
  and E's one, all lit; X's has eight, gold, since the course fills the ultimate's points (system
  19), and reads `8/8` at its top right, in gold. Each name fits inside its square with no word
  split across lines: BLADE STORM on two lines, CLOUDBURST on one, smaller. The HUD's key overlay
  (W A S D, F3) sits just above the bar, clear of it. `VFKit` reads `C2/2 Q1/1 E1/1 X8/8`.
  **Send:** a screenshot of the bar.
- **U2 Updraft.** Stand still on open floor and press Q. You're thrown straight up at once, with
  a low gust, a ring of air spreading at your feet and six streaks rising. Q's square is outlined
  for the lift's 0.6 s, and its pip goes dark; `VFKit` reads `Q0/1`, with `lift` for those 0.6 s.
  You top out about 0.95 s after the press and land about 1.7 s after it: the HUD's jump line
  reads about `1.67 s` and `rise 4.00 m`. The pip lights again about 2.1 s after the press, 1.5 s
  after the lift ended. **Send:** how high it looked next to the red 1.00 m jump box (we expect
  about four of them stacked), and the jump line.
- **U3 In the air.** Jump, and press Q at the top of the jump: you're lifted again from there.
  The jump line's rise reads more than 4 m, up to about 4.8 m if Q came right at the top.
- **U4 Tailwind's gust.** Stand still facing down the target lane and press E: a thin swish, and
  a ring of air round your waist that narrows as it fades. E's square reads `WINDUP` and its pip
  goes dark, and `VFKit` reads `E0/1` with `windup`. After 1 s the square is outlined and counts
  down from `7.5`, and `VFKit` reads `ready`.
- **U5 The dash.** Stand at the start of the sprint lane, facing along it. Ready a gust as in U4,
  and once the countdown shows, press E with no other keys held. You dash along the lane with a
  whoosh, the edges of the screen flash, and you stop about 7.5 m along it: 7 m in the dash's
  0.45 s, then a short slide. The outline and the countdown go. Once the pip's back, ready
  another and dash holding D: you go to the right, across the lane. Then run along the lane
  holding W with the Vandal and dash: the HUD's speed reads no more than `6.75` as you come out
  of it, the run speed with the knife, and is back to the Vandal's `5.40` a moment later.
  **Send:** where you stopped, in metres along the lane.
- **U6 The window closes.** Press E and then nothing else: the countdown runs to nothing 8.5 s
  after the press and the outline goes. Pressing E then does nothing, until the pip lights again
  1.5 s later.
- **U7 Nothing fires in a dash.** With the Vandal, ready a gust, hold the left button, and press E
  while it's firing: the Vandal stops for the dash, about half a second, and fires again after it.
  Zoom in with the right button and dash: the zoom comes off. Ready another, dash and press 2
  during the dash: the Classic comes out as the dash ends, not during it.
- **U8 A dash ends a lift.** Ready a gust, press Q, and while you're still rising press E: the rise
  stops at once, you dash level through the air, and then you fall.
- **U9 The sounds.** Open the Sound Lab (F2 four times). Updraft logs `gust` as `yours`, and no
  `jump`; a gust readied logs `windup`, and the dash `dash`. Dash from standing still: the log
  shows the `dash` and no more than one `step` after it. Running the same 7 m logs four or five:
  the first about 0.6 m after setting off, then one every 1.8 m, so a fifth if you come to rest
  past 7.8 m, as you do letting go at 7.5 m.
- **U10 Planting.** Set `VFTestGive` to `spike`, walk into site B and hold 4: the plant starts.
  Press Q while it's going: nothing happens, and `VFKit` still reads `Q1/1`. Let go of 4. Ready a
  gust, and once the countdown shows set `VFTestButtons` to 17408 (4 and E together): the plant
  starts and you don't dash. Clear it: the plant stops, and E's countdown is still running.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **U11 Others' casts.** Press P once in window 1 (Skirmish). After the buy phase, bring the two
  players about 10 m apart in view of each other. In window 2, cast Updraft, ready a gust and dash
  past player 1. Window 1 sees the ring and the streaks at player 2's feet as they go up, the ring
  at their waist, and a pale streak about 7 m long at their waist along the way they dashed, each
  where player 2 is drawn at the moment. Window 1's Sound Lab logs `gust`, `windup` and `dash`
  from player 2 at about how far away they were. Window 2 sees the edges of its screen flash in
  the dash, and no streak. In Skirmish a spent charge doesn't come back until the next round:
  player 2's Q pip stays dark.
- **U12 The spike rounds' kit.** Press P three times more in window 1 (the 1v1, gun game, then the
  spike rounds). In round 1's buy phase both `VFKit`s read `C0/2 Q0/1 E1/1 X0/8`: Cloudburst and
  Updraft have to be bought, and Tailwind's charge is free. In window 1, B opens the menu: under the
  shields, an `Abilities` group has Cloudburst (`C`, 200) and Updraft (`Q`, 150). Pointing at
  Updraft shows `Ability, on Q` and rows for `Charges` (`up to 1`), `A charge` (`150 credits`) and
  `Lift` (`4 m, in 0.6 s`). Click it: the credits go from 800 to 650, its pip lights and it shows
  `FULL`, the bar's Q pip lights, and `VFKit` reads `Q1/1`. Right-click it: back to 800 and `Q0/1`.
  Click it again to keep it. (Y12 buys Cloudburst.) **Send:** a screenshot of the menu with Updraft
  bought.
- **U13 Kept through a death.** Skip the buy phase. Player 2 kills player 1, who hasn't used
  Updraft. Player 2's `VFKit` reads `X1/8`, for the kill, and player 1's `X1/8` too, for the death.
  In round 2's buy phase, player 1's still reads `Q1/1`, and their bar shows the pip lit.
- **U14 Tailwind every round.** After round 2's buy phase, player 1 readies a gust and dashes:
  `E0/1`. Skip the round. In round 3's buy phase it reads `E1/1` again. If a round has a plant or a
  defuse (as in E6), whoever made it gets a point too.
- **U15 Off.** Press P in window 1 until `[VF] Arena off`. Within 2 s on the course both kits read
  `C2/2 Q1/1 E1/1 X8/8` again: full, the ultimate's points too.

## 22. Cloudburst

From [18-cloudburst.md](research/18-cloudburst.md). One player on the course with the HUD on (F3),
then two in Skirmish and the spike rounds. After each burst your `VFLastCloud` attribute (select
your player under Players, then Properties, Attributes) is where the server says it burst, in
metres. `Workspace.VFClouds` holds a small glowing `Throw` ball for each throw in the air, and a
`Cloud` ball and its `CloudEdge` for each cloud; the `Cloud` ball's `Centre` attribute is where
your screen has it, in metres, and `Moved` is set if the server's word moved it. Without keys,
`VFTestButtons` 4096 presses C: set it and clear it again for a throw, or keep it set to curve
one. `VFTestYaw` and `VFTestPitch` aim, in degrees, and positive pitch looks up. On the course a
spent charge comes back 1.5 s after the throw.

- **Y1 The bar.** C's square is lit, with both its pips. `VFKit` reads `C2/2 Q1/1 E1/1 X8/8`.
- **Y2 Down the lane.** Stand at the spawn facing down the target lane (`VFTestYaw` 0,
  `VFTestPitch` 0) with the Vandal, and press C. A quick, thin swish, and the Vandal dips and is
  back up within a quarter of a second. A small pale blue ball flies straight down the lane at eye
  height, through the dummies at 10, 30 and 50 m, and bursts against the backstop about 2 s later.
  A ball of pale grey-blue smoke grows there for about half a second, stays, and thins away about
  2.5 s after the burst. `VFLastCloud` reads about `(0, 1.62, -59.65)`, and the `Cloud` ball's
  `Centre` the same, with no `Moved`: your screen's cloud formed where the server's did. C's first
  pip goes dark, `VFKit` reads `C1/2`, and the pip lights again 1.5 s after the throw. **Send:** a
  screenshot of the cloud at the backstop.
- **Y3 The gun put away.** Hold the left button with the Vandal (`VFTestButtons` 128) and, while
  it's firing, press C (`VFTestButtons` 4224, then back to 128): the Vandal stops for a quarter of
  a second, two or three of its shots, and fires on. Fire a few rounds, start a reload (R, or
  `VFTestButtons` 512) and press C in it: the reload stops, and the magazine stays as it was.
  Zoom in with the right button and press C: the zoom comes off.
- **Y4 Into the sky.** Look up (`VFTestPitch` 30) and throw: the ball climbs, and bursts in mid-air
  2 s later, 60 m along its way. The cloud hangs there. `VFLastCloud` reads about
  `(0, 31.62, -51.96)`.
- **Y5 The floor, and what it hides.** Look a little down (`VFTestPitch` -10) and throw: it bursts
  on the floor about 8.6 m ahead with a slow, thick whoosh, and the cloud covers Dummy 1 at 10 m.
  `VFLastCloud` reads about `(0, 0.10, -8.62)`. While the cloud is thick, nothing of Dummy 1 shows
  through it, not even its red outline, and nor do the dummies at 30 and 50 m behind it. Their
  outlines come back as it thins, in its last moments. **Send:** a screenshot with the cloud over
  Dummy 1.
- **Y6 From inside.** Look down at your feet (`VFTestPitch` -60) and throw: it bursts on the floor
  just under 1 m ahead, `VFLastCloud` about `(0, 0.10, -0.88)`, and within about a fifth of a
  second the screen turns to pale grey-blue smoke, with the HUD on top of it. It clears as the
  cloud goes, about 2.5 s later. Throw another the same way and walk backwards (S): the screen
  clears about 2 m back, as your eye leaves the cloud.
- **Y7 The curve.** Face down the lane (`VFTestPitch` 0), set `VFTestButtons` to 4096 and keep it
  set, then a tenth of a second after the throw set `VFTestPitch` to 30, and clear `VFTestButtons`
  1.5 s later. The ball turns up within an eighth of a second, climbs, and bursts in mid-air 2 s
  after the throw: `VFLastCloud` about `(0, 29, -53)`, lower and further than Y4's, from about
  `(0, 30, -52.5)` to `(0, 27, -53.3)` as the pitch came sooner or later. Then the same, but clear
  `VFTestButtons` straight after the throw, before the pitch changes: it doesn't curve, and bursts
  at the backstop as in Y2, `(0, 1.62, -59.65)`.
- **Y8 In a dash, and planting.** Ready a gust (E) and, once the countdown shows, dash (E) and
  press C during the dash: nothing is thrown, and `VFKit` still reads `C2/2`. Set `VFTestGive` to
  `spike`, walk into site B and hold 4: while the plant goes, C throws nothing.
- **Y9 The sounds.** Open the Sound Lab (F2 four times) and throw at the floor as in Y5: it logs
  `smokeThrow` as `yours`, then `smokeBurst` from `you` about 8.8 m away, from your head. Throw
  down the lane as in Y2: its `smokeBurst` is out of range, 60 m away and past its 30 m edge.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **Y10 Others' throws.** Press P once in window 1 (Skirmish). After the buy phase, bring the two
  players about 15 m apart in view of each other. In window 2, throw at the floor halfway between
  them. Window 1 sees the small ball leave player 2's eye, where player 2 is drawn at the moment,
  and the cloud form where it burst: its `Cloud` ball's `Centre` in window 1 matches player 2's
  `VFLastCloud`. While the cloud is between them, neither window sees the other player, outline
  included. Window 1's Sound Lab logs `smokeThrow` and `smokeBurst` from player 2.
- **Y11 After the thrower dies.** In window 2, look up (`VFTestPitch` 30) and throw, and in
  window 1 kill player 2 at once, within the 2 s it flies. The ball flies on, straight, and
  bursts in mid-air 2 s after the throw, 60 m along its way, in both windows.
- **Y12 The spike rounds.** Press P three times more in window 1 (the 1v1, gun game, then the spike
  rounds). In round 1's buy phase B opens the menu. Pointing at Cloudburst shows `Ability, on C` and
  rows for `Charges` (`up to 2`), `A charge` (`200 credits`), `Cloud` (`6.7 m across, for 2.5 s`)
  and `Flight` (`30 m/s, at most 2 s`). Click it twice: the credits go from 800 to 600 to 400, both
  its pips light and it shows `FULL`, and `VFKit` reads `C2/2`. Right-click it once: 600, and
  `C1/2`.

## 23. Blade Storm

From [19-blade-storm.md](research/19-blade-storm.md). One player on the course with the HUD on (F3),
then two players on the course: stay on it, as it's where the ultimate fills. On the course every
life starts with the ultimate's 8 points full, and they fill again 1.5 s after Blade Storm ends, so
it can be cast again and again. While it lasts, your `VFKit` reads `storm` after the points. Without
keys, `VFTestButtons` 32768 presses X, 128 throws one and 256 throws all that are left: set it, then
clear it, for each. `VFTestAimEntity` aims at a dummy (Dummy 1, 10 m down the target lane, is
4294901761) and `VFTestAimRegion` at its `head`, `body` or `legs`; clear `VFTestAimEntity` and set
`VFTestPitch` to -20 to throw at the floor a few metres ahead.

- **Z1 The bar.** X's square has eight gold pips and reads `8/8` in gold, and `VFKit` reads
  `C2/2 Q1/1 E1/1 X8/8`, as in U1.
- **Z2 The cast.** Stand at the spawn with the Vandal, facing down the target lane, and press X. You
  hear a slow metal scrape, the cast. The Vandal goes, and about half a second later three pale blue
  blades, fanned out, come up into view. The bar under the crosshair, labelled `drawing`, fills over
  about 1 s. The ammo box reads `5`, with `Blade Storm   [X]` under it. X's square is outlined in
  teal, its pips dark, and its note reads `x5`. `VFKit` reads `C2/2 Q1/1 E1/1 X0/8 storm`. A click
  before the bar is full throws nothing. **Send:** a screenshot with the knives up and the bar.
- **Z3 One at a time.** Throw one at Dummy 1's body. You hear a quick, thin swish, the blades snap
  forward, and a pale streak runs from your hand to the dummy. The number `50` shows, and you hear
  the blade going in. Its label reads `83 + 17`, and the ammo `4`. The second makes it `50 + 0` and
  the third kills it. The ammo goes straight back to `5`, and X's note to `x5`. The kill feed reads
  `<your name>   Blade Storm   Dummy 1`, and `VFKit` reads `X1/8 storm`, a point for the kill. Click
  as fast as you can: no more than six go a second. Hold the button down: one goes. **Send:** how
  many knives it took, and whether all five came back.
- **Z4 Head and legs.** When Dummy 1 is back (2 s), one to its head kills it: `150`, the headshot
  sound, `HS` in the kill feed, and all five back. Then its legs: `43` each, its label `86 + 22`
  after the first, and the fourth kills it.
- **Z5 Exact on the move.** Aim at the middle of Dummy 1's body with the mouse, and throw while
  strafing left and right (A and D), while running at it (W), at the top of a jump, and just as you
  land. Each lands on the body, where the crosshair is. The HUD's `cone` line reads `0.00 deg` the
  whole time, and its ring stays a green dot, even while the speed line reads `MOVING ERROR`. Then
  run along the sprint lane with the knives out: the speed reads `6.75`, as with the knife (3).
- **Z6 Walls.** Stand on the red line at the wallbang lane and throw at the middle of the 0.10 m
  wood wall, at chest height. A dark mark shows on its face, with an orange spark. There's no hole
  out the back, and no number on the dummy behind it. The Vandal goes through that wall (P1).
- **Z7 Running out.** Throw all five, one at a time, at the floor. A sixth of a second after the
  fifth, the knives go, X's outline goes and its note reads `0/8`. The Vandal comes back up over its
  1 s draw, as `Vandal   [1]`. `VFKit` reads `X0/8`, without `storm`, and about 1.5 s later `X8/8`,
  with the pips gold again.
- **Z8 All at once.** With `X8/8` back, cast again and wait for the bar. From the spawn, aim at
  Dummy 1's body and right-click. Five streaks go out at once, each within about 0.35 m of the
  crosshair (2 degrees at 10 m), with one number for all that hit, and the ammo reads `0`. About
  half a second later the knives go and the Vandal comes back. If Dummy 1 died, the kill feed has
  its line, but no knives come back. Then cast again, throw two singly at the floor, and
  right-click: three streaks, and the ammo goes from `3` to `0`. **Send:** how many of the five
  landed, and the number.
- **Z9 Guns and X again.** Cast, and throw one at the floor (`x4`). Press 2: the Classic comes out
  over its 0.75 s draw, with `12 / 36` and `Classic   [2]`. X's square stays outlined with `x4`, and
  `VFKit` still reads `storm`. The Classic fires as ever. Press X: the knives come back up, the bar
  fills over half a second, and the ammo reads `4` again. Press 1 for the Vandal, then X: the same.
  Press 2, then X, and throw the last four at the floor: the hand goes back to the Classic, the gun
  they were last drawn from.
- **Z10 With the rest of the kit.** With the knives out, press C. The knives dip and are back within
  a quarter of a second, a ball flies down the lane, and `VFKit` reads `C1/2` with `storm`. Press Q:
  you're lifted, and a throw at the top at Dummy 1's body lands where the crosshair is. Ready a gust
  (E), and once the countdown shows, dash (E) and click quickly during the dash: nothing is thrown,
  and the ammo stays. A click after the dash throws.
- **Z11 The sounds.** Open the Sound Lab (F2 four times). The cast logs `storm` and `knife`, the
  knives drawn, both as `yours`; each throw logs `kunai`, and a body hit on a dummy `kunaiHit`, the
  blade going in. A head hit logs `headshot` and a kill `kill`, as with guns. When the knives run
  out, the only sound is your gun's draw as it comes back: no reload.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and stay
on the course.

- **Z12 Others' cast and streaks.** Bring the two players about 10 m apart, in view of each other.
  In window 2, cast Blade Storm. Window 1 sees five pale blue blades circle player 2 at chest height
  for about a second, where player 2 is drawn at the moment, and its Sound Lab logs `storm` from
  player 2. Player 2 throws at player 1's body. Window 1 sees each pale streak leave player 2's eye
  and hears `kunai` from them. After the first, player 1's HUD reads `83` and `+17`, as from the
  knife (K9). The third kills player 1. Both kill feeds read `Player2   Blade Storm   Player1`, and
  window 2's ammo is back to `5`.
- **Z13 A death ends it.** In window 1, cast Blade Storm and throw one (`x4`). In window 2, kill
  player 1 with the Vandal. About 3 s later player 1 is back with the Vandal in hand and no knives:
  the ammo box has no `[X]`, X's square isn't outlined, and `VFKit` reads `C2/2 Q1/1 E1/1 X8/8`,
  with no `storm`.

## 24. Drift

From [20-drift.md](research/20-drift.md). One player on the course with the HUD on (F3), then two
players on the course. Space held in the air glides: while it does, the HUD's `vert` line reads
the fall's speed and its `state` line reads `glide`, and your `VFKit` ends in `glide`, from the
server. Without keys, `VFTestButtons` 64 holds Space, and 8256 holds Q and Space together, so
Updraft casts as it's set and the glide follows: set it, and clear it once you've landed. On the
course Updraft's charge comes back 1.5 s after its lift ends.

- **I1 A held jump.** Stand still on open floor, press Space and keep it held. You rise as from
  any jump, then come down slowly: on the way down `vert` reads `-2.00 m/s` and `state` reads
  `air glide`, and you hear a soft run of gusts. The jump line reads about `0.81 s`, against
  `0.66 s` for a tap (M11). `VFKit` ends in `glide` on the way down, and not once you've landed.
  **Send:** the jump line, held and tapped.
- **I2 Landing with it held.** Keep Space held once you're down, for a couple of seconds: you don't
  jump again. Let go and press it: you jump.
- **I3 From the top of Updraft.** Press Q, then press and hold Space on the way up. The lift is as
  in U2, `rise 4.00 m`, and from the top you glide down at `-2.00`: the jump line reads about
  `3.00 s`, against U2's `1.67 s`. Do it again and let go of Space halfway down: `vert` falls away
  faster at once and `glide` goes. **Send:** the jump line.
- **I4 Pressed in a fall.** Press Q and let go of everything. On the way down from the top, once
  `vert` is below `-5`, press and hold Space: `vert` comes up to `-2.00` within about a tenth of a
  second, and stays there until you land.
- **I5 A dash in a glide.** Ready a gust (E) and wait for the countdown, press Q, and hold Space.
  Once `vert` reads `-2.00`, press E: you dash level through the air, with `vert` at `0.00` and no
  `glide`, then glide on down at `-2.00` after it.
- **I6 Aim.** With the Vandal (1), glide from the top of Updraft and watch the HUD's `cone` line:
  it ends in `air`, as in any fall, and its ring is as wide as in a jump. Then cast Blade Storm (X),
  wait for the knives, press Q, glide, and throw one at Dummy 1's body: it lands where the
  crosshair is.
- **I7 The sound.** Open the Sound Lab (F2 four times). A glide logs `glide` as `yours` about three
  times a second, and nothing more once you land or let go.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and stay
on the course.

- **I8 Others' glide.** Bring the two players about 10 m apart, in view of each other. In window 2,
  press Q and hold Space. Window 1 sees faint rings of air left at player 2's waist as they sink,
  each fading where it was left, at player 2 as they're drawn at the moment. Its Sound Lab logs
  `glide` from player 2 about three times a second, at about how far away they are. Both stop when
  player 2 lands or lets go of Space. Player 2's `VFKit` ends in `glide` while it lasts.
- **I9 Not across the buy phase.** Press P once in window 1 (Skirmish). In the buy phase, player 2
  jumps on their side holding Space: window 1's Sound Lab shows player 2's `glide` as
  `not heard: buy phase`, as in N9.

## 25. Matches that never stop

From [21-drop-in.md](research/21-drop-in.md). A quick play of what changed, with three players. In
Studio the game still starts on the course, and P starts Skirmish as before. A live server starts
Skirmish by itself (F6). Waiting in line needs five players in Skirmish, so the tests cover it.

Start a Local Server with 3 players, as in section 9, and press P once in window 1 (Skirmish).

- **F1 Three players.** Players 1 and 3 are on one side and player 2 on the other: in windows 1
  and 3 the top bar has two tiles on your left and one on your right. Everyone spawns for round
  1's 15 s buy phase. The HUD panel (F3) is on from the start, as before.
- **F2 Watching a teammate.** Once the round is live, player 2 shoots player 1. Window 1 shows
  `ELIMINATED` where you fell for 2 s. Then the view moves to player 3's eyes, with
  `SPECTATING PLAYER3` near the bottom and `You play from the next round` under it. Player 3's
  blocks aren't drawn, and the view turns as player 3 turns in window 3. A click changes nothing,
  with only one teammate up. Then player 2 kills player 3: window 1's view holds where it was until
  the next round puts you back in your spawn. **Send:** a screenshot of window 1 watching.
- **F3 Tab.** Hold Tab in window 3: both sides, each player's K, D, A and ACS, with player 2's
  kills and players 1 and 3's deaths on it, and no CREDITS column.
- **F4 The victory screen.** Play the match out: players 1 and 3 kill player 2 in each round until
  their side has 10. As the last kill lands, the scoreboard shows by itself in every window:
  `VICTORY` in windows 1 and 3, `DEFEAT` in window 2, everyone's record, `MATCH MVP` in gold on the
  best ACS of the match, `TEAM MVP` on player 2, and `MAP VOTE IN 10` counting down under it (the
  vote is section 26's). Nobody's name is dimmed. **Send:** a screenshot.
- **F5 The next match.** At 0 the vote for the next map comes up; let it run out. Then everyone
  spawns for a new match at 0-0 with round 1's 15 s buy phase, and Tab shows every record back
  at 0.
- **F6 A live server.** Only once the place is published: join it, and you're in Skirmish's
  waiting phase at once (`WAITING FOR AN OPPONENT`), with the HUD panel off until F3.

## 26. The map vote

From [22-map-vote.md](research/22-map-vote.md). A quick play of what changed, with two players.
To reach a match's end quickly, `workspace:SetAttribute("VFMatchSkip", true)` in the server's
command bar ends the phase under way, and in a Skirmish round gives the round to side 1.

Start a Local Server with 2 players, as in section 9, and press P once in window 1 (Skirmish).

- **O1 The first map.** The Output says `[VF] Arena on: Skirmish A`, `B` or `C`, and round 1's buy
  phase names it under the countdown (`SKIRMISH B   B buy menu`). The cover is that map's plan:
  A's is in [07-arena.md](research/07-arena.md), and B's and C's in
  [22-map-vote.md](research/22-map-vote.md).
- **O2 To the victory screen.** In the server's command bar run this, which skips until the match
  is won. Side 1 wins 10-0, and the victory screen shows with `MAP VOTE IN 10` under it.

  ```lua
  for _ = 1, 60 do
  	workspace:SetAttribute("VFMatchSkip", true)
  	task.wait(0.3)
  	if workspace.VFArena:GetAttribute("Phase") == "matchOver" then break end
  end
  ```

- **O3 The vote.** At 0 the victory screen gives way to `VOTE FOR THE NEXT MAP` in both windows:
  three cards, SKIRMISH A, B and C, each with its plan from above and `NO VOTES`, `JUST PLAYED` on
  the one just played, and 15 counting down at the top right. The mouse moves a cursor, and a
  click on a card doesn't fire your gun. **Send:** a screenshot.
- **O4 Voting.** In window 1, click a card other than the one just played: it's outlined in gold,
  and reads `1 VOTE` in gold in both windows. Click another card: the outline and the vote move to
  it. In window 2, click that same card: `2 VOTES`.
- **O5 The next match.** At 0 everyone spawns for a new match at 0-0 on the card with the votes:
  the buy phase names it, the cover is that map's with nothing of the last map's left, and the
  mouse turns the view again.

## 27. Gun game

From [23-gun-game.md](research/23-gun-game.md). A quick play of what changed, with two players.
`workspace:SetAttribute("VFMatchSkip", true)` in the server's command bar ends a gun game match as
if its time were up, so whoever's furthest up wins.

Start a Local Server with 2 players, as in section 9, and press P three times in window 1 (Skirmish,
the 1v1, then gun game).

- **GG1 The start.** The Output says `[VF] Arena on: gun game, Skirmish A`, `B` or `C`, and both
  players spawn in their rooms with no barriers up. The top bar has `10:00` counting down between
  each side's level, 1 and 1, with `LEVEL 1 OF 12` under it, and under the bar the gun you hold in
  gold and the next: `VANDAL   NEXT  PHANTOM`, or the other way round. You hold that gun, with
  the knife on 3 and nothing on 2. B opens no buy menu, the keys 5 to 9 give nothing, C, Q, E and
  X cast nothing, and G does nothing.
- **GG2 A kill.** Each player fires once, into the floor. Player 2 goes to the opening of player
  1's room and kills player 1. In window 2, `LEVEL 2` and the gun's name show in the middle for a
  moment, the gun in hand changes to it at once, the line under the bar moves on to it and the next,
  and your side's number on the top bar reads 2. Hold Tab in window 1: `GUN GAME` at the top, a
  LEVEL column with 2 for player 2 and 1 for you, and a GUN column with each player's gun, player
  2's too.
- **GG3 Spawn protection.** Player 1 comes back 1.5 s later in their room, on level 1's gun, with
  `SPAWN PROTECTION   until you fire` in the middle of window 1. Player 2, still at the opening,
  shoots player 1 at once: in window 2 player 1 is drawn as a force field, and the label over them
  stays at `100 + 50`. Then player 1 fires once: the line goes, player 1 looks solid again in
  window 2, and player 2's next shot hurts. **Send:** a screenshot of window 2 with player 1 as a
  force field.
- **GG4 A knife kill.** Player 1 kills player 2 (player 1 to level 2). Player 2 comes back, and
  with player 1 standing still, presses 3 and stabs player 1 in the back with the right button.
  Window 1 shows `KNIFED` and `Down to level 1` in the middle, and window 2 `LEVEL 3` with the gun
  of it, which is drawn in place of the knife.
- **GG5 The end.** Run `VFMatchSkip` once in the server's command bar. Player 2, on level 3, wins:
  `VICTORY` in window 2 and `DEFEAT` in window 1, the LEVEL column with 3 and 1, `MATCH MVP` in
  gold on player 2, `TEAM MVP` on player 1, and `MAP VOTE IN 10` under it. **Send:** a screenshot.
- **GG6 The next match.** At 0 the vote comes up, as in O3; vote or let it run out. Then both
  players spawn for a new match on the map with the votes, on level 1, at `10:00`. In the Explorer,
  `Workspace.VFArena`'s `Ladder` lists the new match's guns, most likely not the last match's.

## 28. The Play menu

From [24-play-menu.md](research/24-play-menu.md). A quick play of what changed, with two players.
Studio can't teleport, so there PLAY for another mode switches the server to it, as P does; the
teleports between servers need the place published (PM6).

Start a Local Server with 2 players, as in section 9. Both start on the course, as before.

- **PM1 The menu.** Press M in window 1: `PLAY` at the top, `This server is on the course.` under
  it with Studio's note, and six cards: SKIRMISH `2v2`, GUN GAME `4v4`, DEATHMATCH `FFA`,
  UNRATED `5v5`, COMPETITIVE `5v5` and SWIFTPLAY `5v5`, each with how it's won and `NOBODY YET`,
  and none with `THIS SERVER`. The SKIRMISH card is outlined in gold, the button under the cards
  reads `PLAY SKIRMISH`, `M  close` is at the top right, and the mouse moves a cursor. **Send:** a
  screenshot.
- **PM2 Picking.** Click the GUN GAME card: the outline moves to it, and the button reads
  `PLAY GUN GAME`. Press M: the menu closes, and the mouse turns the view again.
- **PM3 PLAY another mode.** Press M, click GUN GAME, then PLAY GUN GAME. The menu closes, the
  Output says `[VF] Arena on: gun game, Skirmish A`, `B` or `C`, and both players spawn in gun
  game, as in GG1.
- **PM4 This server's mode.** Press M in window 2: the GUN GAME card has `THIS SERVER` and the
  outline, and within a second reads `2 PLAYING` in gold, with `NOBODY YET` on the others. Click
  PLAY GUN GAME: the menu closes, and nothing else changes.
- **PM5 Over the victory screen and the vote.** Run `VFMatchSkip` once in the server's command
  bar, as in GG5, and the victory screen shows. Press M in window 1: the victory screen goes while
  the menu is open, and comes back as M closes it. At the vote, the cards go and come back the
  same way. Without keys, `VFTestPlayMenu` set to true and then false on the local player does
  what M does.
- **PM6 A live server.** Only once the place is published, with its Max Players at least 10: join
  it. The Play menu is up from the start, with `THIS SERVER` on SKIRMISH and no `M  close`, and M
  doesn't close it. PLAY SKIRMISH drops you into its match. Then M, GUN GAME and PLAY GUN GAME:
  `TELEPORTING TO GUN GAME...` under the button, then Roblox's teleport, and on the new server
  you're straight in gun game with no menu. A second player doing the same lands on the same
  server.

## 29. The spike rounds' maps

From [25-spike-maps.md](research/25-spike-maps.md). A quick play of what changed, with two players.
`workspace:SetAttribute("VFMatchSkip", true)` in the server's command bar ends the phase under way,
and a skipped round goes to the defenders, as its clock running out.

Start a Local Server with 2 players, as in section 9, and press P five times in window 1 (Skirmish,
the 1v1, gun game, the spike rounds, then the spike rounds in Swiftplay's format).

- **SM1 The first map.** The Output's last line says `[VF] Arena on: the spike rounds, Swiftplay,
  on Outpost`, `Quarry` or `Foundry`, and round 1's buy phase names that map first on its line, as
  `QUARRY   800 CREDITS   Attack: plant the spike at A or B   B buy menu`. Player 1 spawns behind
  red barriers in the map's ATTACKERS, with the spike in front of them, and player 2 behind blue
  ones in its DEFENDERS. In the Explorer, `Workspace.VFSpikeMap` holds three models: Outpost,
  Quarry and Foundry.
- **SM2 To the vote.** In the server's command bar run this, which skips through the match, the
  defenders winning every round so it ends 5-4 after sudden death, and then the victory screen:

  ```lua
  for _ = 1, 60 do
  	workspace:SetAttribute("VFMatchSkip", true)
  	task.wait(0.3)
  	if workspace.VFArena:GetAttribute("Phase") == "vote" then break end
  end
  ```

- **SM3 The vote.** Both windows show `VOTE FOR THE NEXT MAP`: three cards, OUTPOST, QUARRY and
  FOUNDRY, each with its plan from above, the defenders' blue spawn at the top, the attackers' red
  one at the bottom and A on the left, the amber plant areas and the cover. Each reads `NO VOTES`,
  the map just played has `JUST PLAYED`, and 15 counts down at the top right. **Send:** a
  screenshot.
- **SM4 Voting.** In both windows, click QUARRY, or FOUNDRY if Quarry was just played: it's
  outlined in gold, and reads `2 VOTES` in both windows.
- **SM5 The second map.** At 0 both players spawn for round 1 of a new match at 0-0 on that map,
  which the buy phase names: player 1 behind its red barriers with the spike in front of them, and
  player 2 behind its blue ones. Skip the buy phase. Player 1 picks up the spike, takes it into
  site B's plant area and plants it: `SPIKE` shows in the bar, so the spike's sites are this
  map's. In the rounds after, skipping the buy phases, walk round the map: its lanes and sites are
  as drawn in [25-spike-maps.md](research/25-spike-maps.md), the walls are 5 m tall, and nowhere
  in either spawn sees into the other. **Send:** a screenshot from each site, and whether the map
  feels too big, about right or too small for 2v2.
- **SM6 The third map.** Run SM2's loop again. At the vote, both players vote for the map not
  played yet, and at 0 the next match is on it. As in SM5: its barriers, the spike in front of
  player 1, a plant, at site A this time, and a walk round it. **Send:** as in SM5.

## 30. Deathmatch

From [26-deathmatch.md](research/26-deathmatch.md). A quick play of what changed, with two players.
`workspace:SetAttribute("VFMatchSkip", true)` in the server's command bar ends a deathmatch as if
its time were up, so whoever leads wins.

Start a Local Server with 2 players, as in section 9. Both start on the course.

- **DM1 The start.** Press M in window 1 and click the DEATHMATCH card, `FFA`, then PLAY
  DEATHMATCH. The Output says `[VF] Arena on: deathmatch, on Outpost`, `Quarry` or `Foundry`, and
  both players spawn at once somewhere on that map, neither in sight of the other, each facing
  open floor. The top bar has your kills in blue on the left, `9:00` counting down, and the other
  player's in red on the right, with `FIRST TO 40` under it, and under the bar `1ST OF 2` or
  `2ND OF 2` and `B buy menu`, with no tiles beside it. You hold the Vandal, with the Classic on
  2 and the knife on 3, and the label over the other player reads `100 + 50`. There's no ability
  bar, C, Q, E and X cast nothing, Space held in a fall doesn't slow it, and G does nothing.
- **DM2 The buy menu.** B in window 1: `DEATHMATCH: EVERY GUN'S FREE` at the top, every gun as
  usual, and the shields and the abilities dimmed with `NOT SOLD`, but for Heavy Shield, `OWNED`.
  Hover a dimmed one: `Deathmatch sells guns alone: every life wears Heavy Armor`, or for an
  ability `No abilities in deathmatch`. Click Light Shield: nothing changes. Click the Phantom: it's
  in your hands at once. Click the Vandal to have it back, and close the menu with B.
- **DM3 A kill.** Player 1 fires about 15 rounds into the floor, notes the magazine and the
  reserve, and kills player 2. The moment player 2 falls, player 1's magazine reads 25 again, and
  the reserve is down by as many rounds as that took. The top bar reads 1 on the left in window 1,
  and 1 on the right in window 2. Hold Tab in window 1: `DEATHMATCH   FIRST TO 40` at the top, one
  table, player 1 first with `1st` in the PLACE column and 1 kill, player 2 second with 1 death,
  and your own gun in your row alone.
- **DM4 A health pack.** Player 2 shoots player 1 once in the body, and player 1 kills player 2.
  Where player 2 fell, a green cross glows on the floor, and `Workspace.VFHealthPacks` holds it.
  Player 1 fires a few rounds into the floor, then walks over the cross within its 10 s: the
  label over player 1 in window 2 reads `100 + 50` again, the cross goes, and player 1's magazine
  is full. Meanwhile player 2 is back 1.5 s after falling, with `You come back in a moment` in
  window 2 until then, away from where they fell and out of player 1's sight. Let player 1 kill
  player 2 again and leave that cross: it goes by itself after 10 s.
- **DM5 Respawns.** Player 1 kills player 2 five more times, each from a different place. Each
  time player 2 is back after 1.5 s, out of player 1's sight, facing open floor rather than a
  wall, and never where they just fell.
- **DM6 The end.** Run `VFMatchSkip` once in the server's command bar. Player 1, with the most
  kills, wins: `VICTORY` in window 1 and `2ND PLACE` in window 2, over one table of both players in
  their places, `MATCH MVP` in gold on player 1, and `MAP VOTE IN 10` under it. **Send:** a
  screenshot of window 2.
- **DM7 The next match.** At 0 the vote shows OUTPOST, QUARRY and FOUNDRY's cards, as in SM3;
  vote or let it run out. Both players spawn for a new match on the map with the votes, at `9:00`
  with no kills, each back on the Vandal and the Classic.

## 31. Team Deathmatch

From [27-team-deathmatch.md](research/27-team-deathmatch.md). A quick play of what changed, with two
players. `workspace:SetAttribute("VFMatchSkip", true)` in the server's command bar ends the
pre-game, then each time moves the match on to the next stage's start, and in the last stage ends
it as if its time were up.

Start a Local Server with 2 players, as in section 9. Both start on the course.

- **TD1 The start.** Press M in window 1: seven cards, with TEAM DEATHMATCH `5v5` after
  DEATHMATCH, its name inside the card, and under it
  `Two sides, a new loadout each stage: the first to 100 kills wins`. Click it, then PLAY TEAM
  DEATHMATCH. The Output says `[VF] Arena on: Team Deathmatch, on Outpost`, `Quarry` or
  `Foundry`, and each player spawns in one of that map's two spawn rooms, held in by its
  barriers. In the middle `MATCH STARTS IN 20` counts down, with the map's name and
  `Pick a loadout for each stage: B` under it. The top bar has `0:20` counting down between the
  sides' kills, 0 and 0, with `FIRST TO 100` under it and a tile beside it for each player. You
  hold the Classic, on 2, with nothing on 1 and the knife on 3, and the HUD's shield reads `+25`
  and `REGEN  50 LEFT`. The keys 5 to 9 give nothing, and G does nothing.
- **TD2 The loadout menu.** B in window 1: `LOADOUTS` at the top, `B to close` at the top right,
  and four columns, `STAGE 1` `0:00 - 1:15`, `STAGE 2` `1:15 - 2:30`, `STAGE 3` `2:30 - 3:45` and
  `STAGE 4` `3:45 - 9:30`, each with its loadouts, a gun over its shield: CLASSIC over REGEN
  SHIELD, then FRENZY, GHOST and BANDIT over NO SHIELD; SHERIFF (LIGHT ARMOR), STINGER (HEAVY
  ARMOR) and ARES (LIGHT ARMOR); SPECTRE, ARES and BULLDOG (HEAVY ARMOR) and GUARDIAN (LIGHT
  ARMOR); PHANTOM and VANDAL (HEAVY ARMOR). The first of each is outlined in gold, and the mouse
  moves a cursor. Click GHOST: the outline moves to it, the Ghost is in your hands at once in the
  Classic's place, and the HUD shows no shield. In stage 2's column click STINGER, in stage 3's
  SPECTRE. O opens the settings menu over it; close it with O, and the menu is still up, the
  mouse still moves its cursor, and a click still fires nothing. Close the menu with B.
  **Send:** a screenshot of the menu.
- **TD3 The match.** Wait out the countdown, or run `VFMatchSkip` once. The barriers go, the
  top bar's clock reads `9:30` counting down with `STAGE 1 OF 4` under it, and under the bar
  `FIRST TO 100   NEXT STAGE IN 1:15   B loadouts`. In the middle,
  `SPAWN PROTECTION   until you fire or leave the spawn room`. In window 1, press B in your room:
  the menu opens, with `NOW` in gold by STAGE 1. Walk out of the room with it open: it closes as
  you leave, the protection line goes, `B loadouts` goes from under the bar, and B out there does
  nothing.
- **TD4 The spawn room's burn.** Meanwhile player 2 stays in their room, and once the match is
  under way fires once into the floor: the protection line gives way to
  `The spawn room burns you in 10: move out`, or however many seconds are left, counting down. At
  0, 15 s into the match, `LEAVE THE SPAWN ROOM` shows in red, and the health and shield drop by
  15 every half second until player 2 falls, about 4 s later. Both kill feeds read `SPAWN ROOM` in
  red, then player 2's name, and the top bar stays at 0 and 0. Player 2 comes back 1.5 s later in
  their room, with the protection line again.
- **TD5 Spawn protection and a kill.** Player 1 goes to the doorway of player 2's room, without
  stepping in. If player 2 is a force field, player 2 fires once; then player 1 kills player 2:
  the top bar reads 1 on the left in window 1, and 1 on the right in window 2. Player 2 comes back
  1.5 s later, and player 1 shoots them at once: in window 1 player 2 is drawn as a force field,
  and the label over them stays at `100 + 25`. Player 2 fires once: they look solid again, and
  player 1's next shot hurts. Then player 1 steps into the room and straight back out: inside,
  `ENEMY SPAWN ROOM` shows in red at once, and player 1 takes 15 every half second.
- **TD6 A new stage.** Run `VFMatchSkip` once. The top bar reads `8:15` and `STAGE 2 OF 4`. In
  window 1, out of the room, `STAGE 2` shows in gold with `STINGER   HEAVY ARMOR` under it for a
  moment, then `NEW LOADOUT IN 2` and `1`, then the Stinger is drawn on 1, with the Ghost kept on
  2, and the HUD's shield reads `+50` and `HEAVY ARMOR`. In window 2, in the room, the Sheriff is
  there at once, on 2 in the Classic's place, with `+25` and `LIGHT ARMOR`. Player 2 presses B
  and clicks stage 2's ARES: the Ares is drawn on 1 at once, the Classic is back on 2, and the
  shield still reads `LIGHT ARMOR`. Player 2 leaves the room before it burns them.
- **TD7 The end.** Run `VFMatchSkip` once more: stage 3, and 5 s in player 1's Spectre is drawn by
  itself. Once more, stage 4, and the Phantom; once more ends the match. Player 1's side, with
  more kills, wins: `VICTORY` in window 1 and `DEFEAT` in window 2, with the kills either side,
  the SCORE column, `MATCH MVP` in gold on player 1 and `MAP VOTE IN 10` under it. **Send:** a
  screenshot of window 2.
- **TD8 The next match, and a draw.** At 0 the vote shows OUTPOST, QUARRY and FOUNDRY's cards, as
  in SM3; vote or let it run out. Both players spawn in their rooms on the map with the votes,
  with `MATCH STARTS IN 20`, 0 and 0, and player 1 on the Ghost again. Run `VFMatchSkip` five
  times with no kills: the match starts, runs through its stages and ends level, and both windows
  read `DRAW` in white. **Send:** a screenshot of window 1.

## 32. Team Deathmatch's pickups

From [28-tdm-pickups.md](research/28-tdm-pickups.md). A quick play of what changed, with two
players, or three for the zone in TP4. Section 5 of the research doc has where each map's pickups
stand. On Outpost the spawners are at A choke, at B choke and either side of the block in the
middle of mid, the Recovery Orbs at the sites' fronts by the chokes, and the Ultimate Orbs near the
ends of A main and B main. `VFMatchSkip`, as in section 31, ends the pre-game and then moves the
match on a stage at a time.

Start a Local Server with 2 players, as in section 9, and start Team Deathmatch from the Play menu
as in TD1.

- **TP1 The pre-game.** While `MATCH STARTS IN` counts down, the Explorer's Workspace has
  `VFPickups`, with `SpawnerPad1` to `SpawnerPad4`, a `SpawnerRing` for each, `RecoveryOrb1` and
  `RecoveryOrb2`, `UltimateOrb1` and `UltimateOrb2`, and a `Mark` for each orb. The rings are dim
  grey, nothing lies on the pads, and the orbs are see-through. On the ability bar E's pip is lit
  and C's and Q's are dark, C counting down in its top right corner from about 15 and Q from about
  22, dimmed; X reads `0/60` with ten pips. As C's count reaches 0 its first pip lights, and it
  counts from 29 to the second. In window 1, press B and pick STINGER for stage 2.
- **TP2 A spawner's gun.** Run `VFMatchSkip` once. Every ring lights white with a gun on its pad,
  a Shorty, a Sheriff or a Stinger, and both green orbs glow over their marks; the gold ones stay
  see-through. Player 1 runs out to a pad. A Stinger is taken by walking over it, into slot 1,
  which the first stage leaves empty. A Shorty or a Sheriff isn't, as slot 2 has your sidearm:
  look at it and the prompt reads `F  SWAP FOR SHORTY` or `F  SWAP FOR SHERIFF`; press F and it's
  in your hands in the sidearm's place, and the sidearm isn't left on the pad. Either way the ring
  dims, the line under the bar adds `G back to your loadout`, and player 1's `VFLent` reads
  `stinger,`, `,shorty` or `,sheriff`. **Send:** a screenshot of a lit pad with its gun.
- **TP3 G, and running out.** With the lent gun in hand, press G: it's gone, with nothing on the
  ground, `G back to your loadout` goes with it, you hold your loadout's guns as before, and
  `VFLent` is unset. Thirty seconds after the take the ring lights again, with another gun of the
  stage's on the pad. Take a Shorty or a Sheriff, the quickest to empty, and fire it until it's
  empty, magazine and reserve: as its last round goes, your sidearm is back in its place.
- **TP4 A Recovery Orb.** Player 2 shoots player 1 two or three times and player 1 shoots player 2
  once, neither killing the other. Player 1 runs over a green orb: it goes out, a green glow 6 m
  across lies on the floor where it was, and player 1's health and shield climb back evenly to
  their most over 6 s (with the Classic, 100 and 25). Player 2 walks into the glow while it lasts:
  nothing mends them, as it's the other side's. The glow goes 6 s after the take, and the orb is
  back 30 s after it. With a third player on player 1's side (a Local Server with 3 players), hurt
  them too and have them walk into the glow within its 6 s: they're mended the same way, once.
- **TP5 Ultimate Orbs.** Thirty seconds after the match went live, both gold orbs light up
  together. Player 1 runs over one: it goes out, and the ability bar's X reads `10/60` with one pip
  lit. Player 1 kills player 2: `13/60`, two pips lit, and player 2's X stays at `0/60`. The other
  gold orb stays up until it's taken, and 60 s after they first came up both are up again.
- **TP6 Abilities through a death.** Player 1 throws a cloud with C: a pip goes dark, and C counts
  down from 29; at 0 the pip lights again. Player 1 throws another, lifts with Q (counting from
  44), and dies, to player 2 or to their room's burn. The next life has the same pips lit, and
  the counts carry on where they were. **Send:** a screenshot of the ability bar just after the
  respawn.
- **TP7 A new stage.** Player 1 takes a Stinger from a pad, waiting for one if none has it, and
  fires 10 rounds out of their room. Run `VFMatchSkip`: stage 2. Every pad has one of stage 2's
  guns at once, a Bucky, a Spectre, a Bulldog or a Marshal, the empty ones too. Player 1's Stinger
  stays in their hands, with `G back to your loadout`, until `NEW LOADOUT IN` runs out; then it's
  stage 2's own Stinger, full, 20 in the magazine and 60 in reserve, and `VFLent` is unset.
- **TP8 The end, and the next match.** Run `VFMatchSkip` until the match ends: every ring dims
  with nothing on its pad, the orbs go out, and `VFLent` is unset on both players. After the vote,
  in the next pre-game on the map voted for, its pads are dim and empty, and both kits start over:
  E's pip lit, C and Q dark and counting down from about 15 and 22, and X at `0/60`.

## 33. Agent select

From [29-agent-select.md](research/29-agent-select.md). A quick play of what changed, with one
player and then three. Jett and Phoenix (system 30) are the agents, so the screen comes up by
itself as a window opens, and T opens it too. Your player's `VFAgentPick` attribute says where you
stand: `free`, `open` or `locked`, or unset where nobody picks. A window lasts 10 s.
`workspace:SetAttribute("VFMatchSkip", true)` in the server's command bar ends a gun game match,
as in section 27. A player who joins a match under way has a window of their own too, which the
offline tests cover.

Press Play (F5), with one player.

- **AS1 The course.** Press T: `AGENT SELECT` at the top left, `PICK ANY TIME` in gold at the top
  right, and under them `Nothing's at stake here: an agent picked is yours at once, as often as you
  like.` There are five cards: JETT and PHOENIX over DUELIST, SAGE over SENTINEL, OMEN over
  CONTROLLER and SOVA over INITIATOR. Jett's is outlined in gold with `YOURS` over the name. Under
  them is Jett's kit, headed `JETT   DUELIST`: C CLOUDBURST, Q UPDRAFT, E TAILWIND and X BLADE
  STORM, each with its line, and last `DRIFT   PASSIVE` with `Hold jump while you fall to glide.` On
  the right, `YOUR TEAM` reads `Nobody else on your side`. The button reads `PLAYING JETT`, dimmed,
  and `T to close` is at the bottom right. The mouse moves a cursor, a click fires nothing, and WASD
  still moves you. Your player's `VFAgent` reads `jett` and `VFAgentPick` `free`. T closes it, and
  the view turns with the mouse again. **Send:** a screenshot of the screen.
- **AS2 The other menus.** With B's buy menu open, T does nothing; the same with O's settings
  menu. Close them, and press T: B now does nothing. With the screen up, O opens the settings
  menu over it; close it with O, and the screen is still up, the mouse still moves its cursor, and
  a click still fires nothing. M opens the Play menu, and the screen goes; T does nothing until
  you close the menu with M.
  Press P (Skirmish): you wait for an opponent, and T shows `PICK ANY TIME` and `PLAYING JETT`,
  as on the course. Stop the game.
- **AS3 A window.** Start a Local Server with 3 players, as in section 9, and press P once in
  window 1 (Skirmish): players 1 and 3 share a side, as in F1. As round 1's buy phase starts,
  the screen comes up by itself in window 1: `LOCK IN WITHIN 10` in gold at the top right,
  counting down, and under the title `Click an agent and LOCK IN; when time's up, the one
  selected is locked in for the match.` The button reads `LOCK IN`, lit. Under `YOUR TEAM`,
  `PLAYER3` with `JETT` dimmed and `SELECTING`. `VFAgentPick` reads `open`, and `VFAgentCloses`
  has a number, the server time it closes. Click LOCK IN: the screen goes, and `VFAgentPick` reads
  `locked`.
- **AS4 Locked in, and the time running out.** Press T in window 1 again: `LOCKED IN` at the top
  right, `Locked in until the match is over; you pick again as the next one starts.` under the
  title, the card tagged `LOCKED IN`, and the button `LOCKED IN`, dimmed. Player 3 never clicks:
  with Jett locked in by player 1, their row reads `PHOENIX`, dimmed, and `SELECTING`, their
  selection moved off Jett (section 52); 10 s after the buy phase started it reads `PHOENIX` and
  `LOCKED IN` in gold, their `VFAgentPick` reads `locked`, and PHOENIX's card reads `TAKEN`.
  **Send:** a screenshot of window 1's screen.
- **AS5 Nobody picks in gun game.** Press P twice in window 1 (the 1v1, then gun game). T does
  nothing, and `VFAgentPick` is unset. Space held in the air still glides, as Jett's Drift does. Run
  `VFMatchSkip` once: on the victory screen and in the vote after it, T does nothing either.
- **AS6 The spike rounds.** Press P in window 1 again (the spike rounds). As round 1's buy phase
  starts, the screen comes up by itself in window 2: `LOCK IN WITHIN 10` again, a new window for
  the new match. Don't click: at 0 the screen goes by itself, and `VFAgentPick` reads `locked`.
  In window 1, B opens the buy menu, with Cloudburst (`C`, 200) and Updraft (`Q`, 150) under the
  shields, as in U12. Click Updraft: the credits go from 800 to 650; right-click it: back to 800.
- **AS7 Deathmatch.** Press M in window 1, click the DEATHMATCH card and PLAY DEATHMATCH. In
  deathmatch, T does nothing, and `VFAgentPick` is unset.

## 34. Curveball

From [30-curveball.md](research/30-curveball.md). One player on the course, then two in Skirmish
and the spike rounds. Play as Phoenix first: press T, click PHOENIX's card and PICK PHOENIX (or set
`VFTestAgents` to true, `VFTestAgent` to `phoenix`, then `VFTestAgent` to `lock`). Without keys or
a mouse button, `VFTestButtons` 16384 presses E, 128 the left button and 256 the right: set it and
clear it again each time. `VFTestYaw` and `VFTestPitch` aim, in degrees: positive yaw turns left,
and positive pitch looks up. After each pop your `VFLastFlare` attribute is where the server says
it popped, in metres. While any of a blind is left, your `VFBlind` says when it began, when its
white ends and when it's gone, in server time, and it's unset once your screen is clear.
`Workspace.VFFlares` holds a small glowing `Flare` ball for each flare in the air. On the course a
spent charge comes back 1.5 s after it's done. The numbers below are for throws from the spawn,
facing down the target lane (`VFTestYaw` 0, `VFTestPitch` 0), with the Vandal in hand.

- **CB1 Phoenix.** In agent select, PHOENIX's card reads DUELIST. Its kit: C BLAZE (system 32),
  Q HOT HANDS (system 31), E CURVEBALL and X RUN IT BACK (system 33), lit, each with its line; and
  last `INNER FIRE   PASSIVE`, lit, with `His own fire heals him, where it would burn anyone else.`
  Click PICK PHOENIX: the button reads `PLAYING PHOENIX`, and `VFAgent` reads `phoenix`. Close it
  with T. The ability bar has BLAZE and HOT HANDS each with its pip lit, CURVEBALL with both its
  pips lit and RUN IT BACK with its seven lit gold, and `VFKit` reads `C1/1 Q1/1 E2/2 X7/7`.
  **Send:** a screenshot of Phoenix's card.
- **CB2 In hand.** Press E: a quick, quiet whoosh, the Vandal goes, and a small orange orb comes up
  in your hand. E's square lights, with `EQUIP` under it for 0.8 s; the HUD reads
  `Curveball   [E]`, with no ammo; both of E's pips stay lit; and `VFKit` ends in `equip`. You
  still run at the knife's speed, 6.75 m/s on the HUD panel (F3).
- **CB3 Round to the left.** With the flare drawn, press the left button: a thin swish, and a ball
  of orange light leaves your eye, goes straight for a moment, curves round to the left across
  your view and, 0.6 s after the throw, pops in a bright flash with a sharp crack, about 6 m away
  on your left. Your screen goes warm white, a whiter disc in the middle shrinking, for about
  1.4 s, then clears evenly over about 0.9 s: the pop was about 54 degrees off your view, a
  little past the 50 that blind the longest. The Vandal is back in hand half a second after the
  throw. `VFLastFlare` reads about `(-4.74, 1.62, -3.46)`; `VFBlind`'s first two numbers are about
  1.38 apart and its last two about 0.92. E's first pip goes dark (`E1/2`) and lights again 1.5 s
  later. **Send:** a screenshot of the white, with its disc.
- **CB4 Round to the right.** E, then the right button: there's no zoom, and the flare curves round
  to the right instead. `VFLastFlare` reads about `(4.74, 1.62, -3.46)`, and the blind is as in
  CB3.
- **CB5 Turned towards it, and away.** E, the left button, and within half a second of the throw
  set `VFTestYaw` to 54, looking straight at where it pops: all of the blind, white for 1.5 s and
  clearing over 1 s (`VFBlind`'s numbers 1.5 and 1 apart). Then the same, but set `VFTestYaw` to
  -126, your back to it: only a flash of white, about a fifth of a second, gone at once (0.225 and
  0.15 apart).
- **CB6 At your feet.** Look down at your feet (`VFTestPitch` -60) and throw with the left button:
  the ball hits the floor just ahead and waits there, glowing, until it pops 0.6 s after the
  throw. `VFLastFlare` reads about `(-0.04, 0.10, -0.87)`, and the blind is all of it.
- **CB7 Put away.** E, then E again before throwing: the orb goes, the Vandal comes back with its
  own draw, about a second, nothing is thrown, and `VFKit` reads `E2/2` with no `equip`. E, then
  1: the same. Hold the left button (`VFTestButtons` 128) and press E (16512, then back to 128):
  the Vandal stops, and the flare comes up and is thrown the moment it's ready, once, with the
  Vandal firing again 0.48 s later. Throw both charges, and press E again within a second: nothing
  comes up.
- **CB8 The sounds.** Open the Sound Lab (F2 four times) and throw as in CB3: it logs `flareEquip`
  as `yours` as the flare comes up, `flareThrow` as `yours` at the throw, and `flarePop` from
  `you` about 5.9 m away.

Then two players: stop the game and start a Local Server with 2 players, as in section 9. Press P
once in window 1 (Skirmish), and as round 1's buy phase starts, pick PHOENIX and LOCK IN in
window 1.

- **CB9 Others' flares, and their blind.** After the buy phase, bring the two players about 10 m
  apart, facing each other. In window 1, throw with the left button. Window 2 hears the swish from
  player 1, sees the ball of light leave player 1's eye where they're drawn and curve round to
  their left, and hears the crack from where it pops 0.6 s later; window 2's screen goes white for
  1.5 s and clears over 1 s, and its `VFBlind` is set. Window 1's screen goes white too, as in
  CB3: Phoenix's flash blinds him as well.
- **CB10 Round a corner.** In window 1, stand by a wall's corner with player 2 out of sight round
  it, about 5 m along the other side of the wall and facing the corner. Throw it round the corner,
  curving the way the corner goes: window 2 sees it come round and pop, and is blinded; window 1,
  with the wall between it and the pop, isn't, and its `VFBlind` stays unset.
- **CB11 The glow.** Out in the open, as in CB9, throw at player 2 from window 1 and at once turn
  your back on the pop (with the mouse, or `VFTestYaw` 180 degrees from where you face): a flicker
  of white. A second after the throw, turn back: a pale orange glow is in front of player 2's
  face while their screen is white, moves behind their head about 1.5 s after the pop, and fades
  out a second later. **Send:** a screenshot of the glow in front of player 2's face.
- **CB12 The spike rounds.** Press P three times more in window 1 (the 1v1, gun game, then the spike
  rounds), and as round 1's buy phase starts, pick PHOENIX and LOCK IN in window 1. B: under the
  shields, Blaze (`C`, 150) and Hot Hands (`Q`, 200), lit (sections 36 and 35 have more of them),
  and Curveball (`E`, 250) with one of its two pips lit, the round's free charge, and every tile
  inside the menu. Pointing at Curveball shows `Ability, on E`, its line, and rows for `Charges`
  (`up to 2`), `A charge` (`250 credits`), `Pop` (`0.6 s after the throw`), `Blind`
  (`up to 1.5 s, then 1 s clearing`) and `A charge back` (`every 2 kills`). Click it: the credits go
  from 800 to 550, both its pips light and it shows `FULL`, and `VFKit` reads `E2/2`; right-click
  it: back to 800. **Send:** a screenshot of the menu.

## 35. Hot Hands

From [31-hot-hands.md](research/31-hot-hands.md). One player on the course, then two on the course
and in the spike rounds, and three for the last check, which can be skipped. Play as Phoenix, as in
section 34. Without keys or a mouse button, `VFTestButtons` 8192 presses Q, 16384 E, 128 the left
button and 256 the right: set it and clear it again each time. `VFTestYaw` and `VFTestPitch` aim, in
degrees: positive yaw turns left, and positive pitch looks up. As each fireball bursts, your
`VFLastFire` attribute is the floor under it, where the server has it, in metres.
`Workspace.VFFires` holds a glowing `Fireball` ball for each fireball in the air, a `Burst` while
one flashes, and a `Fire` model for each fire while it burns. On the course a spent charge comes
back 1.5 s after it's spent. Dummy 3 is the crouching dummy on the 20 m stripe, 2 m to the left, and
Dummy 7 the one behind the low wall at 21 m on the right. The numbers below are for throws from the
spawn, facing down the target lane (`VFTestYaw` 0, `VFTestPitch` 0), with the Vandal in hand.

- **HH1 His kit.** In agent select (T), PHOENIX's card has Q HOT HANDS lit, with `Q readies a
  fireball. Fire throws it, alt fire lobs it; it bursts into fire that burns enemies and heals
  you.`, and `INNER FIRE   PASSIVE` lit, with no `NOT YET` (C BLAZE is section 36's, and X RUN IT
  BACK section 37's). On the ability bar HOT HANDS is lit with its one pip, and `VFKit` reads
  `C1/1 Q1/1 E2/2 X7/7`.
- **HH2 In hand.** Press Q: a soft whoosh, the Vandal goes, and a ball of fire with a flame on top
  comes up in your hand. Q's square lights, with `EQUIP` under it for 0.8 s; the HUD reads
  `Hot Hands   [Q]`, with no ammo; Q's pip stays lit; and `VFKit` ends in `equip`. You run at the
  knife's speed, 6.75 m/s on the HUD panel (F3).
- **HH3 Thrown.** With it drawn, press the left button: a low swish, and a glowing orange ball
  leaves your eye, falling gently, and a second after the throw bursts with a flash and a deep thump
  on the floor a little short of the 20 m stripe. Orange fire spreads over the floor from it to 9 m
  across in 0.75 s, with flames rising on it, its glow and a crackle, and 4 s after the burst it's
  gone at once. `VFLastFire` reads about `(0.00, 0.00, -18.30)`. The Vandal is back in hand 0.7 s
  after the throw, and Q's pip goes dark (`Q0/1`) and lights again 1.5 s later. 0.4 s after the
  burst the fire reaches Dummy 3: its label counts down from `100 + 50`, 60 a second in all, and it
  dies about 2.5 s later, the kill feed reading `<your name>   Hot Hands   Dummy 3`. Dummy 2,
  strafing at 15 m, is at the fire's edge and burns only while it's in it. **Send:** a screenshot of
  the fire at its full size.
- **HH4 Lobbed.** Q, then the right button: an underhand lob, slower, bursting about 6.4 m ahead a
  second after the throw. `VFLastFire` reads about `(0.00, 0.00, -6.41)`, and the fire stops about
  2 m short of you.
- **HH5 Thrown up.** Set `VFTestPitch` to 30, then Q and the left button: it climbs, and 1.5 s after
  the throw, about 12 m up and 23 m out, it stops going forward and drops straight down, bursting
  3 s after the throw. `VFLastFire` reads about `(0.00, 0.00, -23.38)`. Again with the right button:
  it stops about 3 m up and 8 m out, falls, and bursts 2.2 s after the throw, at about
  `(0.00, 0.00, -8.18)`. Set `VFTestPitch` back to 0.
- **HH6 At your feet.** Set `VFTestPitch` to -60 and throw with the left button: it bursts at once
  just in front of you, at about `(0.00, 0.00, -0.87)`, and you stand in its fire for its 4 s. Your
  health stays at 100 and your shield at 50, your screen's edge doesn't glow, and nothing goes in
  the kill feed. Set `VFTestPitch` back to 0.
- **HH7 Against the low wall.** Set `VFTestYaw` to -21 and `VFTestPitch` to 3, and throw with the
  left button: the fireball flies at the low wall, comes back off its face, and bursts about 2.3 m
  in front of it, 1.5 s after the throw, at about `(8.78, 0.00, -18.52)`. Its fire stops at the
  wall's face and doesn't go behind it, and Dummy 7, behind the wall 3.6 m from the burst, well
  inside the fire's 4.5 m, doesn't burn. Set both back to 0. **Send:** a screenshot of the fire
  against the wall.
- **HH8 Put away.** Q, then Q again before throwing: the ball goes and the Vandal comes back with
  its own draw, nothing is thrown, and `VFKit` reads `Q1/1` with no `equip`. Q, then 1: the same. Q,
  then E: the flare comes up in its place, with `EQUIP` under E; then Q: the fireball again, in
  place of the flare. Nothing's spent, `Q1/1` and `E2/2`; press 1 to put it away.
- **HH9 The sounds.** Open the Sound Lab (F2 four times) and throw as in HH3: it logs
  `fireballEquip` as `yours` as the fireball comes up, `fireballThrow` as `yours` at the throw,
  `fireBurst` from `you` about 18.4 m away, and `fireCrackle` from `you` every half second while the
  fire burns.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and pick
PHOENIX in window 1 (T). Everyone on the course is everyone else's enemy.

- **HH10 Others' fireballs, and the burn.** In window 2, walk about 6 m down the target lane from
  the spawn and stand still. In window 1, at the spawn with the view level, lob it: Q, then the
  right button. Window 2 hears the swish from player 1, sees the ball come from them and burst at
  player 2's feet with a thump, and the fire spread round them. Window 2's screen's edge glows
  orange, and its health and shield fall together, 60 a second in all. Jump in it: the burn and the
  glow go on, as no jump clears it. Stand still, and player 2 dies about 2.5 s after the burst; both
  kill feeds read `Player1   Hot Hands   Player2`. Once player 2 is back, do it again and walk out
  of the fire: the burn and the glow stop as they leave it. Then player 2 stands in the middle of
  the 0.35 m step, the middle of the three behind the spawn on the left. In window 1, at the spawn,
  set `VFTestYaw` to 120 and `VFTestPitch` to -10 and throw with the left button: it bursts about
  3.6 m short of the step's middle, at about `(-6.26, 0.00, 3.62)`, and its fire burns player 2 on
  the step, too low to stop it. The fire is drawn flat at the burst's height, so it runs out of
  sight under the step (one of the known gaps). Set both back to 0. **Send:** a screenshot of
  window 2's glowing edge.
- **HH11 Inner Fire.** In window 2, shoot player 1 three times in the body with the Vandal:
  window 1's HUD reads 30 health and no shield. In window 1, throw at your feet (`VFTestPitch` -60,
  the left button) and stay in the fire: your health climbs about 12 a second, from 30 to 80 over
  the 4 s after the burst, and stops there, 50 in all. Player 2 shoots once more (40 health); throw
  at your feet again, and step out of the fire a second after the burst: the heal goes on to 90 all
  the same. Once more (50 health), staying in the fire: the heal stops at 100, and the shield stays
  empty. Set `VFTestPitch` back to 0.
- **HH12 The spike rounds.** Press P four times in window 1 (Skirmish, the 1v1, gun game, then the
  spike rounds), and as round 1's buy phase starts, pick PHOENIX and LOCK IN in window 1. B: between
  Blaze (`C`, 150) and Curveball, Hot Hands (`Q`, 200) is lit, with its one pip dark, as no charge
  of it comes free. Pointing at it shows `Ability, on Q`, its line, and rows for `Charges` (`up
  to 1`), `A charge` (`200 credits`), `Fire` (`9 m across, for 4 s`), `Burn` (`60 a second`) and
  `Heals you` (`50 over 4 s, Inner Fire`). Click it: the credits go from 800 to 600, its pip lights
  and it shows `FULL`, and `VFKit` reads `Q1/1`; right-click it: back to 800 and `Q0/1`. **Send:** a
  screenshot of the menu.
- **HH13 Allies.** This one needs three players, and can be skipped. Stop the game, start a Local
  Server with 3 players, and press P four times in window 1 for the spike rounds. In round 1's buy
  phase, pick PHOENIX and LOCK IN in window 1, and buy Hot Hands. Tab shows who's on player 1's
  side. After the buy phase, that teammate stands about 6 m in front of player 1, and player 1 lobs
  at their feet as in HH10: their health falls about 20 a second, a third as fast as player 2's did
  in HH10, and their screen's edge glows the same.

## 36. Blaze

From [32-blaze.md](research/32-blaze.md). One player on the course, then two on the course and in
the spike rounds, and three for the last check, which can be skipped. Play as Phoenix, as in
section 34. Without keys or a mouse button, `VFTestButtons` 4096 presses C, 8192 Q and 128 the left
button: set it and clear it again each time. A click, the left button pressed and let go at once, is
this in the server's command bar:

```lua
local p = game.Players:GetPlayers()[1]
p:SetAttribute("VFTestButtons", 128)
task.wait(0.2)
p:SetAttribute("VFTestButtons", 0)
```

`VFTestYaw` and `VFTestPitch` aim, in degrees: positive yaw turns left, and positive pitch looks up.
As each wall rises, your `VFLastWall` attribute is its far end, where the server has it, in metres.
`Workspace.VFWalls` holds a `Run` model for each line of fire on its way and a `Wall` model for each
wall while it stands. On the course a spent charge comes back 1.5 s after it's spent. Dummy 1 is the
static one on the 10 m stripe, and Dummy 3 the crouching one on the 20 m stripe, 2 m to the left.
The numbers below are for walls sent from the spawn, facing down the target lane (`VFTestYaw` 0,
`VFTestPitch` 0), with the Vandal in hand.

- **BZ1 His kit.** In agent select (T), PHOENIX's card has C BLAZE lit, with `C readies a wall of
  fire. Fire sends it along the floor, held fire bends it; it blocks sight, burns enemies and heals
  you.` (X RUN IT BACK is section 37's.) On the ability bar BLAZE is lit with its one pip, and
  `VFKit` reads `C1/1 Q1/1 E2/2 X7/7`.
- **BZ2 In hand.** Press C: a deep whoosh, the Vandal goes, and a tongue of orange fire comes up
  over your open hand. C's square lights, with `EQUIP` under it for 0.8 s; the HUD reads
  `Blaze   [C]`, with no ammo; C's pip stays lit; and `VFKit` ends in `equip`. You run at the
  knife's speed, 6.75 m/s on the HUD panel (F3).
- **BZ3 Sent.** With it drawn, click the left button: a heavy whoosh, and a flame runs from your
  feet along the floor straight down the lane, a line of fire behind it, past Dummy 1 to just past
  the 20 m stripe in 0.75 s. There, with a crack and a roar, a wall of orange fire rises from your
  feet and spreads along the line to its far end in half a second, 4 m tall, with flames and a glow
  along it, and 8 s after it rose it falls. `VFLastWall` reads about `(0.00, 0.00, -21.00)`. The
  flame leaves your hand as you let go of the button, and the Vandal is back 0.5 s later. C's pip
  goes dark (`C0/1`) and lights again 1.5 s after the send. The wall rose where you stand: your
  screen is orange flame, and you don't burn. A quarter of a second after it rose the fire reaches
  Dummy 1: its label counts down from `100 + 50`, 30 a second in all, and it dies 5 s later, the
  kill feed reading `<your name>   Blaze   Dummy 1`. Dummies 2 and 3, a few metres to the side,
  don't burn. Stay where you are, on the spawn, until the end of BZ8.
- **BZ4 Bent.** Set `VFTestYaw` to 0, press C and wait a second, then run this in the server's
  command bar, which holds the left button for a second and turns you a quarter turn to the left a
  tenth of a second in:

  ```lua
  local p = game.Players:GetPlayers()[1]
  p:SetAttribute("VFTestButtons", 128)
  task.wait(0.1)
  p:SetAttribute("VFTestYaw", 90)
  task.wait(0.9)
  p:SetAttribute("VFTestButtons", 0)
  ```

  The flame runs ahead, bends round to the left, a quarter turn in half a second, and runs on that
  way, and the wall stands on its curve. `VFLastWall` reads about `(-13, 0.00, -12)`, give or take a
  metre or two: the sooner the turn, the further left. While it bends C's square stays lit and
  `VFKit` ends in `bend`; the flame stays in hand until the run's over, 0.75 s after the send, and
  the Vandal is back 0.5 s after that, with nothing fired. Set `VFTestYaw` back to 0. **Send:** a
  screenshot of the bent wall.
- **BZ5 Up a box, and through one.** Set `VFTestYaw` to 47.7 and send it (C, then a click): the line
  runs up onto the 0.85 m jump box, across it and down its far side, and the wall's top steps up
  over the box. `VFLastWall` reads about `(-15.53, 0.00, -14.13)`. Then set `VFTestYaw` to 53.5 and
  send it again: the line runs into the 1.00 m box's side at floor level and out of its far side,
  and the wall rises through the box. `VFLastWall` reads about `(-16.88, 0.00, -12.49)`.
- **BZ6 Up a ramp.** Set `VFTestYaw` to -108.4 and send it: the line runs out to your right and a
  little behind you, and up the 30 degree ramp, ending on it 2.5 m up, and the wall's top follows it
  up. `VFLastWall` reads about `(19.93, 2.48, 6.63)`. Set `VFTestYaw` back to 0.
- **BZ7 Put away.** C, then C again before sending it: the flame goes and the Vandal comes back with
  its own draw, nothing's sent, and `VFKit` reads `C1/1` with no `equip`. C, then 1: the same. C,
  then Q: the fireball comes up in its place, with `EQUIP` under Q; then C: the flame again, in
  place of the fireball. Nothing's spent (`C1/1`, `Q1/1`). With the flame in hand, press the right
  button: nothing's sent, and there's no zoom. Press 1 to put it away.
- **BZ8 The sounds.** Open the Sound Lab (F2 four times) and send it as in BZ3, staying where you
  are: it logs `wallEquip` as `yours` as the flame comes up, `wallSend` as `yours` as it's sent,
  `wallRise` from `you` about 1.6 m away as the wall rises at your feet, and `fireCrackle` from
  `you` about 0.6 m away every half second while it stands. Then press D for a moment to step out of
  the wall: the screen clears, and Dummy 3, crouching beyond the wall on its left, can't be seen
  through it, not even its outline, though its health label shows over it (one of the known gaps).
  **Send:** a screenshot of the wall from beside it.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and pick
PHOENIX in window 1 (T). Everyone on the course is everyone else's enemy.

- **BZ9 Others' walls, and the burn.** In window 2, walk 15 m down the target lane, halfway between
  the 10 and 20 m stripes in the middle of the lane, and stand still. In window 1, at the spawn,
  send it (C, then a click). Window 2 hears the heavy whoosh from player 1, sees the flame run from
  player 1's feet along the floor to them and past, and the wall rise from player 1's feet with a
  crack and spread towards them. As it reaches them, about a third of a second after it rose,
  window 2's screen turns to flame, its edge glows orange, and its health and shield fall together,
  30 a second in all. Jump in it: the burn goes on, as no jump clears it. Stand still, and player 2
  dies 5 s after the fire reached them; both kill feeds read `Player1   Blaze   Player2`. Once
  player 2 is back, do it again and walk out of it sideways: the burn, the glow and the flame stop
  as they leave it. **Send:** a screenshot of window 2 inside the wall.
- **BZ10 Out of sight.** Player 2 stands on the 10 m stripe 3 m right of Dummy 1. In window 1, at
  the spawn, send it, then walk 3 m to the left (A). In window 2, look at player 1: the wall stands
  between you, and nothing of player 1 shows through it, their outline included; only their health
  label shows over it (one of the known gaps). In window 1, look at player 2: the same.
- **BZ11 Inner Fire.** In window 2, shoot player 1 three times in the body with the Vandal:
  window 1's HUD reads 30 health and no shield. In window 1, send it from where you stand, and stay
  in it as it rises: your health climbs about 6 a second, from 30 to 80 over the 8 s it stands, and
  stops there, 50 in all. Player 2 shoots once more (40 health); send another, and step out of it a
  second after it rises: the heal goes on to 90 all the same.
- **BZ12 The spike rounds.** Press P four times in window 1 (Skirmish, the 1v1, gun game, then the
  spike rounds), and as round 1's buy phase starts, pick PHOENIX and LOCK IN in window 1. B: Blaze
  (`C`, 150) is lit, with its one pip dark, as no charge of it comes free. Pointing at it shows
  `Ability, on C`, its line, and rows for `Charges` (`up to 1`), `A charge` (`150 credits`), `Wall`
  (`up to 21 m, for 8 s`), `Burn` (`30 a second`) and `Heals you` (`50 over 8 s, Inner Fire`). Click
  it: the credits go from 800 to 650, its pip lights and it shows `FULL`, and `VFKit` reads `C1/1`;
  right-click it: back to 800 and `C0/1`. **Send:** a screenshot of the menu.
- **BZ13 Allies.** This one needs three players, and can be skipped. Stop the game, start a Local
  Server with 3 players, and press P four times in window 1 for the spike rounds. In round 1's buy
  phase, pick PHOENIX and LOCK IN in window 1, and buy Blaze. Tab shows who's on player 1's side.
  After the buy phase, that teammate stands about 10 m in front of player 1, and player 1 sends it
  at them as in BZ9: their health falls about 10 a second, a third as fast as player 2's did in BZ9,
  and their screen's edge glows the same.

## 37. Run it Back

From [33-run-it-back.md](research/33-run-it-back.md). One player on the course, then two. Play as
Phoenix, as in section 34. Without keys or a mouse button, `VFTestButtons` 32768 presses X, 16384 E,
1 W and 128 the left button: set it and clear it again each time, or keep 1 set to walk. As it's
cast, your `VFLastMark` attribute is where, your feet, in metres. `Workspace.VFRunItBack` holds a
`Mark` model for each mark while it's drawn, its `Entity` attribute whose it is. On the course its
points fill again 1.5 s after you're back. Start each check at the spawn, facing down the target
lane (`VFTestYaw` 0, `VFTestPitch` 0), with the Vandal in hand.

- **RB1 His kit.** In agent select (T), PHOENIX's card has X RUN IT BACK lit, with `Marks where you
  stand. Die before it's over, or let it run out, and you're back at the mark with full health.`,
  and nothing on it reads `NOT YET`. On the ability bar RUN IT BACK has its seven pips lit gold,
  with `7/7` under it, and `VFKit` reads `C1/1 Q1/1 E2/2 X7/7`.
- **RB2 The cast.** Fire 10 rounds down the lane (`15 / 50` on the HUD). Set `VFTestYaw` to 30 and
  press X: a low, slow whoosh, the Vandal dips and is back up a second later, and a small flame
  burns on the floor at your feet in a round orange glow. X's square lights, its pips go dark, and
  under it the seconds left count down from `10.0`. `VFKit` reads `C1/1 Q1/1 E2/2 X0/7 back`,
  `VFLastMark` about `(0.00, 0.00, 0.00)`, and `Workspace.VFRunItBack` holds one `Mark`. Through
  that first second the left button fires nothing and E does nothing; after it, E brings the flare
  up as ever, and E again puts it away. X again does nothing. Then set `VFTestYaw` to 0, walk down
  the lane past the 10 m stripe (W, about 2 s), and turn round (`VFTestYaw` 180): the flame burns on
  at the spawn. **Send:** a screenshot of the mark.
- **RB3 Running out.** Wait where you are. 10 s after the cast, with a heavy whoosh, your screen
  turns to orange flame, and W, Space and the left button do nothing; X's note reads `BACK`, and
  `VFKit` ends in `away`. Clear `VFTestYaw` (playing yourself, turn away with the mouse instead). A
  second later, with a deep crack, you're back at the spawn, facing 30 degrees left of the lane as
  you did when you cast it, level, and the mark's flame is gone; `VFKit` ends in `rise`. The flame
  on your screen clears over 1.4 s, and through it you still can't move or fire. Then you can, the
  Vandal in hand, and the HUD reads `25 / 40`: reloaded from its reserve. 1.5 s later X's pips fill
  again, gold (`X7/7`).
- **RB4 The spike's blast.** Buy Light Armor in place of your Heavy Armor (B, or `VFTestBuy`
  `light`): the HUD's shield reads `+25`, with `LIGHT ARMOR` under it. Pick up the spike, plant it
  in site A as in D4, and walk back to the spawn. When the HUD's spike line (F3) reads about
  `6.0 s left`, press X. As it goes off and the blast reaches you, you don't die: there's no
  `ELIMINATED` and no line of yours in the kill feed, your health reads `0`, and your screen turns
  to flame at once, `VFKit` ending in `away`. A second later you're back where you cast it, with
  `100` and `+25` (`LIGHT ARMOR`): full health and the shield you had as you cast it. **Send:** the
  HUD's health after.
- **RB5 A plant under way.** Wait for X's pips to fill. Pick up the spike, walk into site A's front
  half, and press X. When X's note reads about `3.0`, hold 4 to plant (`VFTestButtons` 1024). As it
  runs out your body goes, and the plant's bar goes with it; let go of 4 then. Nothing's planted
  (`VFSpike` stays `carried`), and you rise at the mark with the spike still yours.
- **RB6 The sounds.** Open the Sound Lab (F2 four times), wait for X's pips to fill, and press X,
  standing still: it logs `markLit` as `yours` as it's cast, `fizzle` as `yours` as it runs out 10 s
  later, and `markRise` as `yours` a second after that.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and pick
PHOENIX in window 1 (T). Everyone on the course is everyone else's enemy.

- **RB7 Seen by another.** In window 2, stand on the 10 m stripe facing the spawn (`VFTestYaw` 180).
  In window 1, at the spawn, press X, then walk 5 m to the left (A). Window 2 hears the low whoosh
  from player 1 and sees the small flame burn where they cast it. In window 2, shoot player 1 dead
  with the Vandal: a headshot (`VFTestAimEntity` 4294967295, player 1's id, and `VFTestAimRegion`
  `head`, then a click). Neither kill feed has a line. In window 2, player 1's blocks go in a burst
  of flame and embers, with a heavy whoosh; in window 1, the screen turns to flame at once with the
  same whoosh, and X reads `BACK`. Click again in window 2 within the second: nothing's hit. A
  second later, with a deep crack, a column of flame stands at the mark, player 1 inside it,
  thinning away over 1.4 s, and player 1's label reads `100 + 50` again. Shoot player 1 in it: the
  hit counts, and the headshot kills them, `Player2   Vandal   Player1` in both kill feeds, and
  player 1 respawns as ever. **Send:** a screenshot of the column from window 2.
- **RB8 Its sounds from another.** Open the Sound Lab in window 2, and in window 1 press X again
  (once its pips have filled) and stand still: window 2 logs `markLit` from player 1, `fizzle` from
  player 1 10 s later, and `markRise` from player 1 a second after that.

## 38. The minimap

From [34-minimap.md](research/34-minimap.md). One player in Skirmish, then two, then three, through
Skirmish, the spike rounds and deathmatch. The minimap is only in a match: the course has none. It's
the `VFMinimap` ScreenGui in your player's PlayerGui, and its attributes say what it shows: `Plan`
(the map drawn, as `arena:A`), `Seen` (the entity ids of the enemies on it), `Spike` (whether the
spike's on it), `Turn` (how far the map's turned, in degrees) and `Big` (whether the big map's
open). Under its `Box`, `Icons` holds each icon by name: `Self`, `Ally_<id>`, `Enemy_<id>`,
`Seen_<id>` (where one was last seen), `Pulse_<id>`, `Dead_<id>`, `Spike` and `Ring`. In a Local
Server, player 1's id is 4294967295, player 2's 4294967294 and player 3's 4294967293. Without Caps
Lock, `VFTestMap` set to true opens the big map and false closes it; without the menu,
`VFTestSetting` enters a map setting, as `mapRotate=0`.

Press Play (F5), with one player.

- **MP1 None on the course.** At the start there's nothing at the top left but the F3 panel, and
  `VFMinimap` has no `Plan`.
- **MP2 The arena.** Press P (Skirmish): you wait for an opponent, and the barriers are down. At the
  top left, 12 px in from the corner, is a dark square about a quarter of the window's height
  across, with the hall on it from above: its floor grey, its walls pale, the cover lighter where
  it's tall, your spawn's floor tinted blue and the other's red. The F3 panel now sits under it.
  `Plan` reads `arena:A`, as the arena's `Map` does. Your arrow, pale yellow with a dark edge,
  points straight up, with a faint white cone spreading up from it, stopped by the walls. Turn
  (`VFTestYaw` 90, then 180): the map turns round the box's middle and your arrow keeps pointing up;
  `Turn` reads about 90, then about 180, and nothing of the map shows outside the box as it turns.
  Walk round the hall: your arrow moves over the map as you do. **Send:** a screenshot of the
  minimap.
- **MP3 Fixed.** Press O: under MAP, Rotate has ROTATE lit, and Fixed orientation BY SIDE. Click
  FIXED: the map stops turning, your spawn at the bottom of the box (`Turn` 180 on side 1, 0 on side
  2), and as you turn your arrow turns instead. Click SAME WAY: `Turn` reads 0, side 1's room at the
  top. Click BY SIDE, then ROTATE again.
- **MP4 Centred, size, zoom and cones.** Click Keep me centred ON: your arrow sits in the box's
  middle and the map moves under it as you walk; OFF again. In Minimap size, type `1.2` and press
  Enter: the box is a fifth bigger, and the F3 panel moves down with it. Type `5`: it reads `1.2`.
  Type `0.8`: smaller. Put back `1`. In Minimap zoom, type `1.4`: the map's bigger in the box, and
  you're kept in its middle though Keep me centred is off; `0.6`: the whole hall small in the middle
  of the box. Put back `0.9`. Vision cones OFF: your cone goes; ON again. Close the menu.
- **MP5 The big map.** Hold Caps Lock (or set `VFTestMap` to true): a big square over the middle of
  the screen, about 0.82 of the window's height across, the whole hall on it the same way round as a
  fixed minimap, your spawn at the bottom, with your arrow and cone; `Big` reads true. The arena's
  places have no names. Let go (or set `VFTestMap` to false): it's gone, and `Big` reads false. Open
  O and click in the crosshair code box: Caps Lock there opens nothing. Close the menu.
- **MP6 The white circle.** Run a few steps (W, or `VFTestButtons` 1): a white ring round your
  arrow, as far as your steps are heard, 20 m round you, so wider than the hall, fading as you stop.
  Walk (Shift and W): none. Fire a few rounds into the floor: none for the shots. Press R: a smaller
  one for the reload, 15 m round you. Press Q (Updraft): one 30 m round you as it lifts you. Open
  the Sound Lab (F2 four times), press `[` five times (the footstep radius, down from 20 m to 10 m),
  and run: the ring's half as wide. Press `]` five times and close the lab.
- **MP7 A cloud in the cone.** Face down the hall, towards the other room, and throw Cloudburst
  along it (C). Where it bursts, a pale disc edged in blue, and your cone stops at its edge; as the
  cloud goes, the disc does too, and the cone reaches the far wall again.

Then two players: stop the game, start a Local Server with 2 players, as in section 9, and press P
in window 1 (Skirmish). Player 1 and player 2 are on opposite sides. As round 1's buy phase starts,
agent select comes up in both windows: in window 2 click PHOENIX and LOCK IN, and in window 1 lock
in JETT. The buy phase holds you in your rooms; the checks start as round 1 does.

- **MP8 Seen.** In window 1, look at player 2 (`VFTestAimEntity` 4294967294) with nothing between
  you: a red dot on window 1's minimap where player 2 is, moving as they move, and `Seen` reads
  `4294967294`. Turn window 1 away from them (clear `VFTestAimEntity` and set `VFTestYaw` the other
  way): at once the dot fades, with a `?` on it, where player 2 was last seen, and stays there as
  player 2 moves, gone after 3 s (`Seen_4294967294`); `Seen` is empty. Window 2's minimap shows
  player 1 only while player 2 looks at them. **Send:** a screenshot of the `?`.
- **MP9 In the way.** Player 2 crouches behind tall cover, or goes round a corner, where player 1
  can't see them, and window 1 looks their way: no dot. Player 2 stands in the open, and window 1
  throws Cloudburst so it bursts between them: while it stands there's no dot, though window 1 looks
  at player 2, and window 1's cone stops at the cloud; as it goes, the dot's back. Then player 2
  sends Blaze (C, then the left button) across between them: while the wall stands, no dot again,
  window 1's cone stops at it, and the wall's on both minimaps, edged red in window 1 and blue in
  window 2. In the next buy phase, window 1 looks out of the room through its barrier: the cone
  carries on through it into the hall.
- **MP10 Blinded.** Window 1 looks at player 2, and player 2 throws Curveball (E, then the left
  button) so it pops in front of player 1: as window 1's screen turns white, player 2's dot goes
  from window 1's minimap and their `?` shows; once the white has cleared to under half, the dot's
  back.
- **MP11 A kill.** Player 1 kills player 2 in sight: the dot goes, and there's no `?` where they
  fell.

Then three players: stop the game, start a Local Server with 3 players and press P in window 1
(Skirmish). Players 1 and 3 share a side, as in F1.

- **MP12 An ally.** In round 1, window 1's minimap has player 3's arrow in blue, pointing the way
  they look, with a faint blue cone of their own. In window 1's settings, set Minimap zoom to `1.4`,
  and send player 3 to the far end of the hall: their arrow sits on the minimap's edge, the way to
  them, and comes off it as they come back. Put the zoom back to `0.9`. Player 3 looks at player 2
  while player 1 looks away: player 2's dot is on window 1's minimap too. Then player 2 kills
  player 1: a red X where player 1 fell, on window 1's minimap and window 3's (`Dead_4294967295`),
  there until the next round; and as window 1 watches player 3 (as in F2), its minimap is
  player 3's, their arrow and cone as `Self`.
- **MP13 The spike.** Press P three times in window 1 (the 1v1, gun game, then the spike rounds). In
  window 1, attacking, the map's drawn with its two sites lettered A and B in their amber plant
  areas, and the spike's orange diamond in front of you (`Spike` true); as you turn, the letters
  stay upright. Window 2, defending, has no diamond (`Spike` false). Player 1 picks up the spike: in
  windows 1 and 3 a small orange mark sits on player 1's arrow, and the diamond's gone; window 2
  shows nothing of it. Player 1 drops it (G) where player 2 can't see it: window 2's `Spike` stays
  false. Player 2 looks at it: the diamond shows in window 2 (`Spike` true), and goes as they look
  away. Player 1 plants it at A: everyone's minimap has the diamond on A. Hold Caps Lock in
  window 2: the big map, the defenders' spawn at the bottom, with the places' names on it, as `A
  Lobby`. Set Region names to IN BUY PHASE: the names show on the big map only through the next buy
  phase; NEVER: none; ALWAYS again.
- **MP14 Deathmatch's pulse.** Press M in window 1, click the DEATHMATCH card and PLAY DEATHMATCH.
  Everyone's on a side of their own: no blue arrows on anyone's minimap, and neither spawn floor
  tinted. Player 2 kills player 1: as player 1 comes back 1.5 s later, players 2 and 3 show on
  window 1's minimap as faint red dots where they were (`Pulse_4294967294` and `Pulse_4294967293`),
  fading out over 3 s.

## 39. The fog of war

From [35-fog-of-war.md](research/35-fog-of-war.md). Two players in a Local Server, then three,
through the course, Skirmish, the spike rounds and deathmatch. What a client's been sent of the
others is in its own Explorer, in each player's window: `Workspace.VFPlayers` holds a model for each
player in its snapshots, named as the player is (`Player1`, `Player2`, `Player3`), so an enemy it
hasn't been sent has none there. The server window's Workspace has `VFFogLines` and `VFFogMs`, what
the fog's looks cost in the last second (the lines they cast, and the milliseconds of server time
they took), and `VFFogOff`, which set true turns the fog off.

Start a Local Server with 2 players, as in section 9.

- **FW1 The course.** Before anyone presses P, both players are on the course, on no side. Player 2
  walks behind the course's walls, out of player 1's sight: `Player2` stays in window 1's
  `VFPlayers` all the while, as `Player1` does in window 2's, and on the server `VFFogLines` reads
  0.
- **FW2 Behind cover.** Press P in window 1 (Skirmish): players 1 and 2 are on opposite sides. As
  round 1's buy phase starts, agent select comes up in both windows: lock in JETT in both. Once the
  round starts, player 2 goes behind tall cover, or round a corner, where player 1 can't see any
  part of them, and both stand still: half a second later `Player2` is gone from window 1's
  `VFPlayers`, and nothing of player 2 shows in window 1, not even their label. On the server,
  `VFFogLines` reads under 30 while both stand still. Player 2 walks out (Shift held, and A or D)
  into player 1's sight: `Player2` is back in `VFPlayers` before any of them shows, and they're
  drawn whole from their first frame in view, never popping in. `VFFogLines` reads more while
  player 2 walks behind the cover than while they stand. **Send:** `VFFogLines` and `VFFogMs` with
  both still out of sight, and with player 2 walking behind the cover.
- **FW3 A peek with a ping.** Open the Hit Reg Lab in window 1 (F2 three times) and press `]` ten
  times: 100 ms each way. Player 2 stands still behind the corner, and player 1 runs (W) out past
  it: player 2 shows as player 1 comes round, where they stand, from the first frame, with no
  pop-in. Then player 1 holds still, looking at the corner, and player 2 runs out past it: the same.
  Press `[` ten times to take the latency off, and close the lab.
- **FW4 Heard.** Player 2 goes back behind the cover, and player 1 stands where they can't see them,
  a few metres away. Player 2 runs back and forth behind it (A and D): `Player2` is in window 1's
  `VFPlayers` while they run, and window 1 hears their steps from behind the cover, but no label of
  theirs shows through it. Player 2 walks instead (Shift held): `Player2` goes half a second after
  their last running step, and window 1 hears nothing. Player 2 fires a few rounds into the floor:
  window 1 hears the shots, and `Player2` stays out. Player 2 stands still and reloads (R): in for
  the reload and half a second after. Player 2 jumps on the spot: in while they're in the air.
- **FW5 A knife's swing.** Player 2 stays behind the cover, draws the knife (3) and slashes the air
  (the left button): window 1, a few metres away, hears it. Player 2 goes to the back of their spawn
  room and player 1 to the back of theirs, and player 2 slashes again: window 1 hears nothing.
- **FW6 Roots.** In the server window's Explorer, open `Workspace.Player1` and select its
  `HumanoidRootPart`: as player 1 walks round the hall its position stays where they spawned, though
  in window 1 everything goes on as before (the view, the sounds, dropping your gun with G and
  picking it back up with F).
- **FW7 Off.** In the server window, set Workspace's `VFFogOff` to true: window 1's `VFPlayers` has
  `Player2` wherever they go, and `VFFogLines` reads 0. Set it false: once player 2 is out of
  player 1's sight again and still, `Player2` is gone half a second later.

Then three players: stop the game, start a Local Server with 3 players and press P in window 1
(Skirmish). Players 1 and 3 share a side, as in F1.

- **FW8 Teammates.** Player 3 goes behind cover, out of player 1's sight: `Player3` stays in
  window 1's `VFPlayers`, and their label shows through the cover.
- **FW9 Spotted.** Player 2 stands still behind cover from player 1 but in the open in front of
  player 3, and player 3 looks at them: `Player2` is in window 1's `VFPlayers`, and their red dot's
  on window 1's minimap, moving as they move. Player 3 looks away: half a second later `Player2` is
  gone from window 1's `VFPlayers`.
- **FW10 Down.** Player 2 kills player 1, and window 1 watches player 3 (as in F2): window 1's
  `VFPlayers` has `Player2` while player 3 sees, hears or spots them, as window 3's does, and not
  while player 3 doesn't.
- **FW11 Out of earshot.** Press P three times in window 1 (the 1v1, gun game, then the spike
  rounds). Once round 1 starts, player 2 runs about in their spawn, and player 1 stays in theirs: no
  `Player2` in window 1's `VFPlayers`, and no steps heard. Player 2 fires a few rounds into the
  floor: window 1 hears them, and `Player2` stays out.
- **FW12 Deathmatch's pulse.** Press M in window 1, click the DEATHMATCH card and PLAY DEATHMATCH.
  Player 2 kills player 1: as player 1 comes back, players 2 and 3 pulse on window 1's minimap where
  they are (`Pulse_4294967294` and `Pulse_4294967293`), behind walls or not; `Player2` and `Player3`
  are in window 1's `VFPlayers` for a moment, then only whoever player 1 sees or hears.

## 40. Sage's Healing Orb

From [36-healing-orb.md](research/36-healing-orb.md). One player on the course, then two on the
course, then three in Skirmish, the spike rounds and Team Deathmatch. Play as Sage: press T, click
SAGE's card and PICK SAGE (or set `VFTestAgents` to true, `VFTestAgent` to `sage`, then
`VFTestAgent` to `lock`). Without keys or a mouse button, `VFTestButtons` 16384 presses E, 128 the
left button and 256 the right: set it and clear it again each time. `VFTestAimEntity` set to a
player's entity id, with `VFTestAimRegion` set to `body`, holds your crosshair on the middle of
their body, and clearing it lets go: the ids are 4294967295 for player 1, 4294967294 for player 2
and 4294967293 for player 3. Your `VFLastHeal` attribute is the name of the player you last
healed. On the course a spent charge comes back 1.5 s after it's spent. Start each check with the
Vandal in hand.

- **HO1 Her kit.** In agent select, the cards are JETT, PHOENIX, SAGE, OMEN and SOVA, and SAGE's
  reads SENTINEL. Click it: her kit, X RESURRECTION, C BARRIER ORB and Q SLOW ORB lit (sections 43,
  42 and 41), and E HEALING ORB lit, with `E readies a healing orb. Fire heals the hurt ally in your
  crosshair, alt fire heals you, 100 health over 5 s.`; nothing under them, as she has no passive.
  Click PICK SAGE: the button reads `PLAYING SAGE`, and `VFAgent` reads `sage`. Close it with T. On
  the ability bar RESURRECTION has its seven pips lit gold, BARRIER ORB has its pip lit, SLOW ORB
  its two and HEALING ORB its one, and `VFKit` reads `C1/1 Q2/2 E1/1 X7/7`. **Send:** a screenshot
  of Sage's card.
- **HO2 In hand.** Press E: a quick whoosh, the Vandal goes, and a small green ball comes up over
  your hand. E's square lights, with `EQUIP` under it for 0.5 s; the HUD reads `Healing Orb   [E]`,
  with no ammo; E's pip stays lit; and `VFKit` ends in `equip`. You run at the knife's speed,
  6.75 m/s on the HUD panel (F3).
- **HO3 Nobody to heal.** With the orb up, click the left button: nothing happens and nothing's
  heard, the orb stays in hand, E's pip stays lit, and `VFKit` still ends in `equip`. The right
  button: the same, as you're not hurt. Look at Dummy 1, the static dummy 10 m down the target lane,
  and click: the same, as it's on nobody's side.
- **HO4 Put away.** E again: the orb goes and the Vandal comes back with its own draw, and `VFKit`
  reads `C1/1 Q2/2 E1/1 X7/7`, nothing spent. E, then 1: the same.
- **HO5 The sounds.** Open the Sound Lab (F2 four times) and press E: it logs `orbEquip` as `yours`
  as the orb comes up, and clicks with it log nothing. Press 1, and F2 to close the lab.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and pick
SAGE in window 1 (T). Everyone on the course is everyone else's enemy, so there the orb heals nobody
but its holder. Player 2 stands about 5 m from player 1, where each sees the other.

- **HO6 Healing yourself.** In window 2, shoot player 1 three times in the body with the Vandal
  (`VFTestAimEntity` 4294967295, then three clicks): window 1's HUD reads 30 health and no shield.
  In window 1, open the Sound Lab, press E and, once `EQUIP` has gone, the right button: a soft
  bell, logged as `healChime`, `yours`; the orb goes, and the Vandal's back in hand 0.7 s after the
  click. Your screen's edge glows green, pulsing, and your health climbs about 20 a second, from 30
  to 100 in 3.5 s, and stops there; the shield stays empty. The glow goes 5 s after the bell.
  `VFLastHeal` reads `Player1`. E's pip goes dark, with `45` under it, and lights again 1.5 s later,
  as the course fills it. In window 2, the bell is heard from player 1, and player 1's blocks glow
  green, pulsing, for the same 5 s. **Send:** a screenshot of window 1's green edge.
- **HO7 A hit pauses it.** In window 2, shoot player 1 twice in the body with the Vandal: 20 health.
  Draw the Classic in window 2 (2). In window 1, heal yourself again (E, then the right button), and
  about a second after the bell, as window 1 reads about 40, shoot player 1 once in the body with
  the Classic: 26 off. Window 1's health holds for a second after the hit, then climbs again about
  20 a second, and stops at 94: all 100 given, the hit's 26 off. The green edge stays through the
  pause, and goes about 6 s after the bell.
- **HO8 Not an enemy.** In window 1, shoot player 2 twice in the body with the Vandal
  (`VFTestAimEntity` 4294967294): window 2 reads 70 health and no shield. Wait for E's pip to light,
  press E and keep the crosshair on player 2: no green box and no + on them. Click: nothing happens,
  the orb stays in hand, and window 2 still reads 70. Clear `VFTestAimEntity` in both windows.

Then three players: stop the game, start a Local Server with 3 players and press P in window 1
(Skirmish). Players 1 and 3 share a side, as in F1. As round 1's buy phase starts, agent select
comes up by itself: pick SAGE and LOCK IN in window 1, and LOCK IN in windows 2 and 3.

- **HO9 The mark.** Once the round is live, player 3 walks about 5 m out in front of player 1 and
  stands in the open. In window 1, press E and aim at player 3 (`VFTestAimEntity` 4294967293): no
  mark, as player 3 isn't hurt, and a click does nothing. Player 2 comes out to where they can see
  player 3 and shoots them three times in the body with the Vandal: window 3 reads 30 health and no
  shield, and window 1 at once draws a green box round each of player 3's head, body and legs, and a
  green + over their head. Clear `VFTestAimEntity` in window 1 and turn away from player 3: the
  mark goes. Aim at player 3 again: it's back. **Send:** a screenshot of the mark.
- **HO10 Not behind cover.** Player 3 steps behind cover taller than they are, out of player 1's
  sight, with window 1 still aimed at them: no mark through it. Click: nothing, and the orb stays in
  hand.
- **HO11 Healing an ally.** Player 3 steps back out into player 1's sight, and the mark's back.
  Click the left button in window 1: a soft bell from player 1 in windows 1 and 3, the orb goes, and
  the Vandal's back 0.7 s after the click. Player 3's health climbs about 20 a second, from 30 to
  100 in 3.5 s, and stops there, with no shield. Window 3's screen edge glows green for 5 s, and in
  window 1 player 3's blocks glow green, pulsing, for those 5 s. `VFLastHeal` reads `Player3`. Under
  E on window 1's bar, `45` counts down, and while the round's on, E's pip lights again as it
  reaches 0. **Send:** window 3's health a second after the bell.
- **HO12 The spike rounds.** Press P three times in window 1 (the 1v1, gun game, then the spike
  rounds), and as round 1's buy phase starts, pick SAGE and LOCK IN in window 1. E's pip is lit, its
  charge free, and `VFKit` reads `C0/1 Q0/2 E1/1 X0/7`. B: under the shields, Barrier Orb (`C`, 300)
  and Slow Orb (`Q`, 200) are both for sale (sections 42 and 41).
- **HO13 Team Deathmatch.** Press M in window 1, click the TEAM DEATHMATCH card and PLAY TEAM
  DEATHMATCH. As the match starts, agent select comes up by itself: pick SAGE and LOCK IN in
  window 1. Run `VFMatchSkip` once to end the pre-game. Someone on the other side (Tab) shoots
  player 1 twice in the body with the Classic, and player 1 heals themselves as in HO6: E's pip goes
  dark with `22` under it, not 45, counting down, and lights again at 0.

## 41. Sage's Slow Orb

From [37-slow-orb.md](research/37-slow-orb.md). One player on the course, then two on the course,
then two in the spike rounds. Play as Sage, as in section 40. Without keys or a mouse button,
`VFTestButtons` 8192 presses Q, 16384 E, 128 the left button and 256 the right: set it and clear it
again each time. `VFTestYaw` and `VFTestPitch` aim, in degrees: positive yaw turns left, and
positive pitch looks up. As each orb bursts, your `VFLastSlow` attribute is the floor under it,
where the server has it, in metres, and your `VFSlowed` attribute says whether your last move was
slowed. `Workspace.VFSlows` holds a pale `Orb` ball for each orb in the air, a `Burst` while one
flashes, and an `Ice` model for each field while it lasts. On the course a spent charge comes back
1.5 s after it's spent. The numbers below are for throws from the spawn, facing down the target lane
(`VFTestYaw` 0, `VFTestPitch` 0), with the Vandal in hand, and the speeds, the `state` line and the
jump line are the HUD panel's (F3).

- **SO1 Her kit.** In agent select (T), SAGE's card has Q SLOW ORB lit, with `Q readies a slowing
  orb. Fire throws it; it bursts into a field of ice that slows everyone in it, you too.` and no
  `NOT YET`; X RESURRECTION is lit too (section 43). On the ability bar SLOW ORB is lit with both
  its pips, and `VFKit` reads `C1/1 Q2/2 E1/1 X7/7`.
- **SO2 In hand.** Press Q: a light gust, the Vandal goes, and a pale ball with two shards of ice
  comes up over your hand. Q's square lights, with `EQUIP` under it for 0.5 s; the HUD reads
  `Slow Orb   [Q]`, with no ammo; both of Q's pips stay lit; and `VFKit` ends in `equip`. You run at
  the knife's speed, 6.75 m/s.
- **SO3 Thrown.** With it up, press the left button: a quick swish, and a pale glowing ball leaves
  your eye, falling a little, and 0.83 s after the throw bursts with a flash and a crack of ice on
  the floor about 4 m past the 20 m stripe. Ice spreads over the floor from it to 11.2 m across in
  0.3 s, with shards standing up out of it, and 7 s after the burst it fades and is gone.
  `VFLastSlow` reads about `(0.00, 0.00, -24.12)`. The Vandal is back in hand 0.4 s after the throw,
  and one of Q's pips goes dark (`Q1/2`) and lights again 1.5 s later. On the minimap a round in
  your colour lies on the lane while the ice does. **Send:** a screenshot of the field at its full
  size.
- **SO4 Slowed.** Set `VFTestPitch` to -60 and throw: it bursts at once just in front of you, at
  about `(0.00, 0.00, -0.88)`, and the ice spreads round you. Run back and forth in it (W, then S):
  the speed holds at 2.70 m/s, half the Vandal's 5.40, from the first step; the `state` line reads
  `SLOWED`; the edge of your screen frosts over, pulsing faintly; `VFSlowed` is true; and every step
  crunches. Hold Shift and walk: 1.65 m/s, with no crunch and no step heard. Jump standing still: a
  crunch, and the jump line reads about `0.55 s` and `rise 0.58 m`, where out of the ice it reads
  `0.66 s` and `rise 0.83 m`. Run out of the ice: as you leave it the speed climbs back to 5.40 m/s,
  `SLOWED` and the frost go, and `VFSlowed` is false. Set `VFTestPitch` back to 0. **Send:** a
  screenshot with the frosted edge.
- **SO5 Running in, and jumping in.** Throw level, and at once run (W) after it down the lane: about
  18 m out, as you reach the ice's edge, the speed drops from 5.40 to 2.70 m/s at once, with the
  frost and `SLOWED`. Once the charge is back, throw again and run after it, jumping just before the
  edge: as you come over the ice in the air the speed drops to 2.70 m/s, before you land, and the
  landing crunches.
- **SO6 Against the cover.** Set `VFTestYaw` to -21 and throw level: the orb flies at the waist-high
  cover at 21 m on the right, comes back off its face, and bursts about 1.8 m in front of it, 0.89 s
  after the throw, at about `(8.57, 0.00, -19.05)`. Its ice stops at the cover's face and doesn't go
  behind it. Set `VFTestYaw` back to 0.
- **SO7 Thrown high.** Set `VFTestPitch` to 85 and throw: the orb climbs almost straight up, out of
  sight, and about 13 s after the throw comes back down and bursts between the 30 and 40 m stripes,
  at about `(0.00, 0.00, -33.25)`. Set `VFTestPitch` back to 0.
- **SO8 A dummy.** Open the Sound Lab (F2 four times) and press Y, so the dummies' steps are heard.
  Set `VFTestYaw` to -11 and `VFTestPitch` to -3.5, and throw: it bursts at about
  `(2.88, 0.00, -14.83)`, where Dummy 2 strafes at 15 m. For the 7 s of its ice Dummy 2's strafe is
  about half as wide, and its steps crunch; then it's back to its full width. Press Y again, set
  both back to 0, and press F2 to close the lab.
- **SO9 Put away.** Q, then Q again before throwing: the orb goes and the Vandal comes back with its
  own draw, nothing is thrown, and `VFKit` reads `Q2/2` with no `equip`. Q, then 1: the same. Q,
  then the right button: nothing. Q, then E: the Healing Orb comes up in its place, with `EQUIP`
  under E; then Q: the Slow Orb again, in place of the Healing Orb. Nothing's spent, `Q2/2` and
  `E1/1`; press 1 to put it away.
- **SO10 The sounds.** Open the Sound Lab (F2 four times) and throw as in SO3: it logs `slowEquip`
  as `yours` as the orb comes up, `slowThrow` as `yours` at the throw, and `slowBurst` from `you`
  about 24 m away. Throw at your feet as in SO4 and run: it logs `iceCrunch` as `yours` with each
  step. Press F2 to close the lab.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and pick
SAGE in window 1 (T). Player 2 stays Jett. Everyone on the course is everyone else's enemy.

- **SO11 Others' orbs, and the slow.** In window 2, walk about 6 m down the target lane from the
  spawn and stand still, facing down the lane. In window 1, at the spawn, set `VFTestPitch` to -13
  and throw: it bursts at about `(0.00, 0.00, -6.15)`, at player 2's feet. Window 2 hears the swish
  from player 1, sees the orb come from them and burst with a crack, and the ice spread round them.
  Player 2 runs about in it: 2.70 m/s, `SLOWED`, the frost on window 2's edge, player 2's `VFSlowed`
  true, and each step crunching in both windows, from player 2. Walking (Shift), window 1 hears
  nothing from them. Out of the ice, player 2 runs at 5.40 m/s again.
- **SO12 A step.** Player 2 stands in the middle of the 0.35 m step, the middle of the three behind
  the spawn on the left. In window 1, at the spawn, set `VFTestYaw` to 120 and `VFTestPitch` to -10
  and throw: it bursts about 3.1 m short of the step's middle, at about `(-6.70, 0.00, 3.87)`, and
  player 2, running about on the step, is slowed: the step's too low to stop the ice. The ice is
  drawn flat at the burst's height, so it runs out of sight under the step (one of the known gaps).
  Set both back to 0.
- **SO13 A dash.** Player 2 stands where they stood in SO11, facing down the lane, and player 1
  throws again as in SO11. In window 2, press E to ready Tailwind, wait for its gust, and press E
  again with no keys held: the dash goes about 3.5 m down the lane, half its 7 m, and the `pos`
  line's last number goes from about -6 to about -9.5. Once the ice is gone and the charge is back,
  the same dash goes about 7 m. Set `VFTestPitch` back to 0 in window 1.
- **SO14 With a ping.** Open the Hit Reg Lab in window 2 (F2 three times), press `]` ten times
  (100 ms each way), and note the HUD's `max` correction. Player 1 throws at player 2's feet as in
  SO11, and player 2 runs in and out of the ice a few times and jumps in it: the slow starts and
  stops at the ice's edge with no snap back, and `max` doesn't grow. Press `[` ten times to take the
  latency off.

Then the spike rounds: press P four times in window 1 (Skirmish, the 1v1, gun game, then the spike
rounds), and as round 1's buy phase starts, pick SAGE and LOCK IN in window 1, and LOCK IN in
window 2.

- **SO15 Bought.** `VFKit` reads `C0/1 Q0/2 E1/1 X0/7`, both of Q's pips dark. B: under the shields
  Slow Orb (`Q`, 200) is lit, and Barrier Orb (`C`, 300) beside it (section 42). Click Slow Orb
  twice: 400 credits go, Q's pips light, and `VFKit` reads `Q2/2`; a third click buys nothing. Once
  the round's live, throw one at your feet (`VFTestPitch` -60): you're slowed as in SO4, and one of
  Q's pips goes dark and stays dark, as nothing refills it here. Set `VFTestPitch` back to 0.

## 42. Sage's Barrier Orb

From [38-barrier-orb.md](research/38-barrier-orb.md). One player on the course, then two on the
course, then two in the spike rounds. Play as Sage, as in section 40. Without keys or a mouse
button, `VFTestButtons` 4096 presses C, 128 the left button and 256 the right: set it and clear it
again each time (hold 256 where a check says to hold the right button). `VFTestYaw` and
`VFTestPitch` aim, in degrees: positive yaw turns left, and positive pitch looks up. Your `VFWall`
attribute is your last wall's blocks' health, from left to right as you raised it: a number for each
standing, `x` for one broken or gone, and `-` for one left out. `VFKit` ends in `turn` while the
targeter's turned from across your view. `Workspace.VFBarriers` holds a `Barrier` model for each
wall while it stands, with a `Segment` part for each block, the `Targeter` model of `Ghost` parts,
and the `Chip`s of a block breaking. On the course a spent charge comes back 1.5 s after it's spent.
The numbers below are for walls raised from the spawn, with the Vandal in hand, and the `pos` line
is the HUD panel's (F3).

- **BO1 Her kit.** In agent select (T), SAGE's card has C BARRIER ORB lit, with `C readies a barrier
  orb. Fire raises a wall of ice where it shows; C again or held alt fire turns it.` and no `NOT
  YET`; X RESURRECTION is lit too (section 43). On the ability bar BARRIER ORB is lit with its pip,
  and `VFKit` reads `C1/1 Q2/2 E1/1 X7/7`.
- **BO2 In hand.** Open the Sound Lab (F2 four times), and keep it open to BO8. Facing down the
  target lane (`VFTestYaw` 0, `VFTestPitch` 0), press C: a gust, logged as `barrierEquip`, `yours`;
  the Vandal goes, and a pale ball with a slab of ice behind it comes up over your hand. C's square
  lights, with `EQUIP` under it for 0.8 s; the HUD reads `Barrier Orb   [C]`, with no ammo; C's pip
  stays lit; and `VFKit` ends in `equip`. Across the lane, about 15 m out, four faint shimmering
  blocks stand side by side on the floor, 10.4 m from end to end and 2.5 m tall: the targeter. You
  run at the knife's speed, 6.75 m/s.
- **BO3 Aimed.** Set `VFTestPitch` to -15: the targeter comes in to about 6 m ahead, still across
  the lane. At -30 it's about 2.8 m ahead. At 40, looking up into the sky, it's on the floor about
  11.4 m ahead, under where the aim's 15 m run ends. Set `VFTestPitch` to -15 again.
- **BO4 Raised.** Set `VFTestYaw` to 5 and press the left button: a deep crack, logged as
  `barrierRise`, `yours`, and four blocks of pale blue ice rise out of the floor over 1.35 s, about
  6 m ahead, where the targeter was: 10.4 m long, 2.5 m tall and 1.5 m thick, across your view, so
  turned 5° from straight across the lane. They're solid: nothing behind them shows through.
  `VFWall` reads `400,400,400,400`. 2 s after the crack each block flashes white and turns paler,
  with a quieter, higher crack (`barrierFortify`, from `you`, about 6 m away), and `VFWall` reads
  `600,600,600,600`. The Vandal's back in hand 0.7 s after the crack, and C's pip goes dark (`C0/1`)
  and lights again 1.5 s later. BO5 to BO8 use this wall, which stands for 40 s. **Send:** a
  screenshot of the wall.
- **BO5 Solid.** Set `VFTestYaw` and `VFTestPitch` to 0: the wall fills the view, and Dummy 1, 10 m
  down the lane, is hidden behind it. Walk into it (W): you stop at its face, sliding a little to
  the right along it as it's turned, at about `pos` `1.29 0.00 -5.07`. Jump into it: you don't get
  over. Walk back about 5 m (S).
- **BO6 Shot.** Fire at the wall in bursts of three: each bullet stops at it with a small pale
  spark, none reaches Dummy 1, and each takes 40 off the block it hits, the third (`VFWall`
  `600,600,560,600` after the first). After 15 hits `VFWall` reads `600,600,x,600`: that block
  bursts into chips of ice that fall and fade, with a sharp crack (`barrierBreak`, from `you`, about
  6 m away), and through the gap Dummy 1 shows. Walk through the gap: you pass.
- **BO7 A knife.** Draw the knife (3), walk up to the block left of the gap and swing at it with the
  left button: a pale spark where the blade meets it, and its number in `VFWall` drops by 50. Swing
  with the right button: 75 more. Draw the Vandal again (1).
- **BO8 Its end.** About 35 s after the wall rose, the blocks cloud over grey, and the numbers in
  `VFWall` start to fall, every block's together: 2.5 s later each is half what it was at 35 s. At
  40 s what's left bursts into chips with one sharp crack (`barrierBreak`), `VFWall` reads
  `x,x,x,x`, and the `Barrier` model's gone. Press F2 to close the Sound Lab.
- **BO9 Turned.** Set `VFTestPitch` to -15 and press C: the targeter's across the lane. Press C
  again: it turns a quarter, running down the lane from about 1 m to 11 m ahead, the orb stays in
  hand, and `VFKit` ends in `equip turn`. Press C a third time: across again, and `turn` goes. Hold
  the right button and turn to `VFTestYaw` 45, then 90: the targeter stays across the lane, so from
  where you look it turns until it runs along your view, and the view doesn't zoom. Let go of the
  right button and set `VFTestYaw` back to 0: the targeter now runs down the lane, as it's kept the
  turn you left it at, and `VFKit` ends in `turn`. Press 1: the Vandal's back and nothing's spent;
  press C: the targeter comes up still turned down the lane. Press C: across again.
- **BO10 Down the lane.** Press C again, so the targeter runs down the lane, and at once the left
  button: the wall goes up with no wait after the turn, down the middle of the lane from about 1 m
  to 11 m ahead. Dummy 1, at 10 m, stands where its far block rises: it's lifted with it onto its
  top, 2.5 m up, and stays there. Set `VFTestPitch` back to 0.
- **BO11 Lifted.** Face right (`VFTestYaw` -90), walk a few metres onto open floor and stand still.
  Set `VFTestPitch` to -80 and raise a wall: it rises under your feet and lifts you with it,
  smoothly and with no snap back, the `pos` line's middle number climbing to about 2.51 over 1.35 s,
  and you stand on its top. Walk back off it (S): you drop to the floor. Set `VFTestPitch` back to
  0.
- **BO12 The edge.** Face left (`VFTestYaw` 90) and walk along the course to its left edge, past the
  wallbang lane, stopping 2 to 3 m short of it. Press C: with the crosshair level, out over the
  edge, there's no targeter, and the left button raises nothing: the orb stays in hand and C's pip
  stays lit. Face down the course (`VFTestYaw` 0) with `VFTestPitch` -15: the targeter shows three
  blocks, the left one, which would stand over the edge, missing. Raise it: three rise, and `VFWall`
  reads `-,400,400,400`.
- **BO13 The spike.** Set `VFTestGive` to `spike`, walk into site A just inside its front edge, and
  plant (hold 4 for 4 s, as in D4). Step back about 3 m toward the spawn, press C and put the
  crosshair on the spike: the targeter's middle sits on it. Raise it: as it rises, the block over
  the spike (both middle ones, if it's right between them) bursts into chips at once with a sharp
  crack, `VFWall` has an `x` for it, and the rest rise. Then defuse the spike (hold 4 by it, as in
  D7) before it goes off.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and pick
SAGE in window 1 (T). Player 2 stays Jett. Everyone on the course is everyone else's enemy.

- **BO14 Others' walls.** In window 2, walk about 10 m down the target lane, 2 m to the left of
  Dummy 1, and turn to face the spawn. In window 1, at the spawn, raise a wall as in BO4
  (`VFTestYaw` 5, `VFTestPitch` -15). Window 2 sees it rise between them and player 1, with a deep
  crack from the wall, and player 1 is hidden behind it. Player 2 walks toward the spawn: they stop
  at its far face. Player 2 shoots the block in front of them: each hit a pale spark, and its number
  in window 1's `VFWall` drops by 40. Once it's fortified, 15 hits break it: it bursts in both
  windows, the crack heard in both, and player 2 walks through the gap.
- **BO15 Lifted, from window 2.** Player 2 stands still on the lane about 3 m out from the spawn
  (`pos` about `0.00 0.00 -3.00`). In window 1, at the spawn, set `VFTestYaw` to 0 and `VFTestPitch`
  to -28, and raise a wall: it rises under player 2, who goes up with it in both windows, smoothly
  and with no snap back, onto its top 2.5 m up (window 2's `pos` middle number about 2.51). Player 2
  walks off it. Set `VFTestPitch` back to 0 in window 1.
- **BO16 With a ping.** Once the walls are gone (40 s after each rose), open the Hit Reg Lab in
  window 2 (F2 three times), press `]` ten times (100 ms each way), and note the HUD's `max`
  correction. Do BO15 again; then player 2 walks off the wall, into its face and along it, and jumps
  at it: no snap back, and `max` doesn't grow. Press `[` ten times to take the latency off.

Then the spike rounds: press P four times in window 1 (Skirmish, the 1v1, gun game, then the spike
rounds), and as round 1's buy phase starts, pick SAGE and LOCK IN in window 1, and LOCK IN in
window 2.

- **BO17 Bought.** `VFKit` reads `C0/1 Q0/2 E1/1 X0/7`, C's pip dark. B: under the shields Barrier
  Orb (`C`, 300) is lit, beside the Slow Orb. Click it: 300 credits go, C's pip lights, and `VFKit`
  reads `C1/1`; a second click buys nothing. Close the menu (B) and press C: the targeter's red, and
  the left button raises nothing, the orb staying in hand with C's pip lit. Press 1. Once the
  round's live, press C: the targeter's pale blue. Raise it in the open: it rises as on the course,
  and on the minimap a pale blue bar lies along each block, edged in your colour, with your cone
  stopping at it.
- **BO18 Who breaks it.** Shoot your own wall: sparks, and `VFWall` doesn't change. Player 2, on the
  other side, shoots it: each hit takes 40 off, and at nothing a block breaks, as on the course.

## 43. Sage's Resurrection

From [39-resurrection.md](research/39-resurrection.md). One player on the course, then three in
Skirmish. Play as Sage, as in section 40. Without keys or a mouse button, `VFTestButtons` 32768
presses X, 4096 C and 128 the left button: set it and clear it again each time. `VFTestYaw` and
`VFTestPitch` aim, in degrees: positive yaw turns left, and positive pitch looks up.
`Workspace.VFBodies` holds an invisible part for each body, named by its owner's entity id (Dummy
1's is `4294901761`), with `VFReviver` and `VFReviveAt` while a return's under way, and
`Workspace.VFBodyViews` holds the drawn ones, a `VFBody` model each with the id after it. Your
`VFLastRevive` attribute is the name of the one you last brought back. On the course the ultimate's
points are full every life and fill again 1.5 s after they're spent. Start at the spawn facing down
the target lane (`VFTestYaw` 0, `VFTestPitch` 0), with the Vandal in hand.

- **RE1 Her kit.** In agent select (T), SAGE's card has X RESURRECTION lit, with `X readies it. Fire
  on a fallen ally's body brings them back where they lie, with full health and no shield.` and no
  `NOT YET`: nothing on her card is dimmed now. On the ability bar RESURRECTION has its seven pips
  lit gold, and `VFKit` reads `C1/1 Q2/2 E1/1 X7/7`.
- **RE2 In hand.** Open the Sound Lab (F2 four times), and keep it open to RE6. Press X: a gust,
  logged as `reviveEquip`, `yours`; the Vandal goes, and a small teal ball with three shards of
  crystal comes up over an open hand. X's square lights, with `EQUIP` under it for 0.8 s; the HUD
  reads `Resurrection   [X]`, with no ammo; and `VFKit` ends in `equip`. With nobody fallen, press
  the left button: nothing happens, the orb stays in hand, and `VFKit` still reads `X7/7`. Press 1:
  the Vandal's back, and nothing's spent.
- **RE3 A body.** Set `VFTestPitch` to -3 and fire single shots at Dummy 1, the static dummy 10 m
  down the lane: the fourth fells it. Where it stood its body lies on the floor, darkened, along the
  lane with its head toward you, 1.75 m long, over a disc 1.6 m across glowing red, as it's on
  nobody's side; `Workspace.VFBodies` has a part `4294901761`. 2 s after it fell, Dummy 1 stands
  where it stood again, and its body and disc are gone.
- **RE4 Kept down.** Fell it again and press X within 2 s: it stays down, its body there, as long as
  the orb's in hand. Press 1: it's back at once. Fell it again, press X within 2 s once more, and
  keep the orb in hand to RE6.
- **RE5 The mark.** With `VFTestPitch` 0 nothing's marked. Set it to -8: a green box round each of
  the body's three blocks, and a green + over it. At -20 the mark's gone. Set it to -8 again.
- **RE6 Brought back.** Press the left button: a deep chime, logged as `reviveChime`, and the body
  rises in a shell of pale crystal, 0.5 m over 2 s; the body's part has `VFReviver` and
  `VFReviveAt`, and your `VFLastRevive` reads `Dummy 1 (static)`. The orb goes at once and the
  Vandal's back 1 s later; X's pips go dark (`X0/7`) and light again 1.5 s after the chime. 2 s
  after the chime, a sharp crack, logged as `reviveBurst`: the shell bursts in chips of crystal that
  fall and fade, the body and its disc are gone, and Dummy 1 stands where it stood, dropping the 0.5
  m to the floor. The kill feed reads your name, `Resurrection` in teal, then `Dummy 1`, as it names
  dummies. Press F2 to close the Sound Lab. **Send:** a screenshot of the shell as it rises.
- **RE7 No shield.** Set `VFTestPitch` to -3 and fire single shots at Dummy 1: the third fells it,
  where the fourth did in RE3, as it came back with no shield. 2 s later it stands again, its shield
  back.
- **RE8 Into a wall.** Fell it again, press X within 2 s, and bring it back as in RE6 (`VFTestPitch`
  -8). At once press C, then C again as soon as the targeter shows, so it runs down the lane
  (section 42, BO9), set `VFTestPitch` to -15, and raise the wall before the burst: it rises down
  the middle of the lane, round the shell. As Dummy 1 bursts out, the block it's in breaks in chips
  of ice with a sharp crack, your `VFWall` has an `x` for it, and Dummy 1 drops to the floor, not
  onto the wall. Set `VFTestPitch` back to 0.

Then three players: stop the game, start a Local Server with 3 players and press P in window 1
(Skirmish). Players 1 and 3 share a side, as in F1. As round 1's buy phase starts, agent select
comes up by itself: pick SAGE and LOCK IN in window 1, and LOCK IN in windows 2 and 3. In Studio,
setting `VFTestGive` to `ultimate` fills the ultimate's points.

- **RE9 An ally.** Once the round is live, set `VFTestGive` to `ultimate` in window 1:
  RESURRECTION's seven pips light, and `VFKit` reads `X7/7`. Player 3 walks about 5 m out in front
  of player 1 and stands in the open, and player 2 comes out to where they can see player 3 and
  shoots them down. Windows 1 and 3 see player 3's body over a blue disc, and window 2 sees it over
  a red one. In window 1, press X and put the crosshair on the body: it's marked, as in RE5.
- **RE10 Back.** Click in window 1: the chime, in all three windows. Window 3's view rises with the
  body, 0.5 m over 2 s, and its keys do nothing; window 2 sees the body rise in its shell, and their
  shots at it do nothing. At the burst, window 3 reads 100 health and no shield, its view drops to
  the floor, and for 1.3 s W, jumps and clicks do nothing and `VFKit` ends in `revived`; then player
  3 moves and shoots again. Shots from player 2 as player 3 falls take health off. Every window's
  kill feed reads `Player1`, `Resurrection` in teal, then `Player3`. As the next round starts, every
  body's gone from all three windows. **Send:** a screenshot of window 2 as the shell rises.

## 44. Omen's Dark Cover

From [40-dark-cover.md](research/40-dark-cover.md). One player on the course, then three in Skirmish
and the spike rounds. Play as Omen: press T, click OMEN's card and PICK OMEN (or set `VFTestAgents`
to true, `VFTestAgent` to `omen`, then `VFTestAgent` to `lock`). Without keys or a mouse button,
`VFTestButtons` 16384 presses E, 128 the left button and 256 the right: set it and clear it again
each time, and leave 128 or 256 set for as long as the button's held. `VFTestYaw` and `VFTestPitch`
aim, in degrees: positive yaw turns left, and positive pitch looks up. The F3 panel's `pos` line is
where you stand, in metres. Your `VFLastSmoke` attribute is the floor your last smoke went on, in
metres, and `Workspace.VFClouds` holds each smoke, a `Smoke` ball, and with the orb in hand its
mark, `SmokeMark`. On the course a spent charge comes back 1.5 s after it's spent. Start at the
spawn facing down the target lane (`VFTestYaw` 0, `VFTestPitch` 0), with the Vandal in hand.

- **DC1 His kit.** In agent select, the cards are JETT, PHOENIX, SAGE, OMEN and SOVA, and OMEN's
  reads CONTROLLER. Click it: his kit, with X FROM THE SHADOWS lit (section 47), C SHROUDED STEP lit
  (section 46), Q PARANOIA lit (section 45), and E DARK COVER lit, with `E readies a shadow orb.
  Hold fire to send its mark further, alt fire to bring it closer, and E again to smoke there.`;
  nothing under them, as he has no passive. Click PICK OMEN: the button reads `PLAYING OMEN`, and
  `VFAgent` reads `omen`. Close it with T. On the ability bar FROM THE SHADOWS has its seven pips
  lit gold, SHROUDED STEP and DARK COVER have their two pips lit and PARANOIA its one, and `VFKit`
  reads `C2/2 Q1/1 E2/2 X7/7`. **Send:** a screenshot of Omen's card.
- **DC2 In hand.** Open the Sound Lab (F2 four times), and keep it open to DC6. Press E: a low
  whoosh, logged as `darkEquip`, `yours`; the Vandal goes, and a violet ball with two wisps comes up
  over an open hand. E's square lights, with `EQUIP` under it for 0.6 s; the HUD reads
  `Dark Cover   [E]`, with no ammo; and `VFKit` ends in `equip mark 15.0`. Half way between the 10 m
  and 20 m stripes, at eye height, is the mark, a small violet ball, and round it a faint violet
  ball 8.2 m across, its middle on the floor under the mark: both show over anything in front of
  them, Dummy 1 too. Click the left button: nothing's fired or heard, and the mark's number goes up
  a little. Press 1: the Vandal's back, the mark's gone, and `VFKit` reads `C2/2 Q1/1 E2/2 X7/7`,
  nothing spent.
- **DC3 The mark.** Press E. Set `VFTestButtons` to 128 for about 2 s, then clear it: the mark
  slides away down the lane, its number climbing about 15 a second, to about 45, with the faint ball
  under it past the 40 m stripe. Set it to 256 until the mark stops: it comes back to `mark 2.0` and
  no nearer, the faint ball round your feet. Set it to 384, both held: the mark stays. Clear it.
- **DC4 Nowhere for it.** Hold the left button until the mark reads 64 or more: as it passes the
  backstop, the faint ball goes behind it, shown over it, and past 62, where the lane's floor ends,
  the mark turns red and the faint ball goes. Press E: nothing's sent or heard, the orb stays in
  hand, and `VFKit` still reads `E2/2`. Hold the right button until the mark reads about 61: violet
  again, its faint ball on the floor behind the backstop.
- **DC5 Behind a wall.** Press E: a slow, deep swish, logged as `darkSend`, `yours`; the orb goes
  and the Vandal's back 0.7 s later, and E has one pip lit (`VFKit` `E1/2`), both again 1.5 s later.
  `VFLastSmoke` reads about `0, 0, -61`, and `Workspace.VFClouds` has a `Smoke`, out of sight behind
  the backstop. About 1 s after the swish the Sound Lab logs `darkForm` out of range, 61 m away, and
  15 s after that the `Smoke` is gone.
- **DC6 The smoke.** Press E, hold the left button until the mark reads about 20, its faint ball
  over the 20 m stripe, and press E. About a third of a second after the swish, a deep whoosh,
  logged as `darkForm`, and a dome of dark violet smoke grows on the floor over the stripe, quickly
  at first, whole in about 1 s and 8.2 m across, hiding what's behind it, Dummy 4 at 30 m too.
  13.5 s after the whoosh, a low bell, logged as `darkWarn`, and it flickers lighter, never thinner,
  until it's gone at once at 15 s. Press F2 to close the Sound Lab. **Send:** a screenshot of the
  whole dome.
- **DC7 Inside it.** Press E, hold the right button until the mark reads about 6, and press E. Walk
  into the smoke: as your eye goes in, the screen goes dark violet, all but the HUD, and as you walk
  out it clears.
- **DC8 Too steep to stand on.** Walk over to the ramps, signed `30 deg`, `45 deg` and `50 deg`, to
  the right of the spawn and behind it. Stand in front of the 50 deg ramp facing up it (`pos` about
  `10.00 0.00 12.00`, `VFTestYaw` -90, `VFTestPitch` 0) and press E: the mark's on the ramp where
  the crosshair meets it, and the faint ball's middle on the floor under the ramp, through it. Press
  E again: the smoke forms there, and `VFLastSmoke`'s middle number reads 0. Do the same in front of
  the 45 deg ramp (`pos` about `10.00 0.00 9.00`): the smoke forms on its slope, the middle number
  about 1.3.

Then three players: stop the game, start a Local Server with 3 players and press P in window 1
(Skirmish). Players 1 and 3 share a side, as in F1. As round 1's buy phase starts, agent select
comes up by itself: pick OMEN and LOCK IN in window 1, and LOCK IN in windows 2 and 3. Open the
Sound Lab in windows 1, 2 and 3.

- **DC9 Who hears it.** Once the round is live, players 2 and 3 stand beside player 1, and player 1
  sends a smoke about 10 m ahead. Windows 1 and 3 log `darkSend`; window 2 doesn't, though player 2
  stands right there. All three see the smoke form and log `darkForm`, and 13.5 s later `darkWarn`.
- **DC10 Spotted.** Player 3 stands beside player 1. Player 1 sends another smoke about 10 m ahead,
  and player 2 walks round behind it, in line with player 1: on window 1's minimap player 2 fades to
  where they were last seen, and its `Seen` loses `4294967294`. Player 2 steps out to the side:
  they're back on the minimap. As the next round starts, any smoke standing is gone from all three
  windows.

Then the spike rounds: press P three times more in window 1 (the 1v1, gun game, then the spike
rounds), and as round 1's buy phase starts, pick OMEN and LOCK IN in window 1, and LOCK IN in
windows 2 and 3.

- **DC11 Bought.** `VFKit` reads `C0/2 Q0/1 E1/2 X0/7`, one of E's pips lit. B: under the shields
  Dark Cover (`E`, 150), Paranoia (`Q`, 250) and Shrouded Step (`C`, 100) are all lit. Click Dark
  Cover: 150 credits go, E's second pip lights, and `VFKit` reads `E2/2`; it then reads `FULL`,
  and a second click buys nothing. Close the menu (B). Once the round's live, send one: `E1/2`, and
  E counts down from 40 under it, then reads `E2/2` again.

## 45. Omen's Paranoia

From [41-paranoia.md](research/41-paranoia.md). One player on the course, then three in Skirmish and
the spike rounds. Play as Omen, as in section 44. Without keys or a mouse button, `VFTestButtons`
8192 presses Q, 128 the left button and 256 the right: set it and clear it again each time.
`VFTestYaw` and `VFTestPitch` aim, in degrees: positive yaw turns left, and positive pitch looks up.
The F3 panel's `pos` line is where you stand, in metres. Your `VFLastParanoia` attribute is whom
your last orb touched, set once it's flown, and your `VFNearsight` is your nearsight while any of
it's left; `Workspace.VFParanoia` holds each orb in flight, an `Orb` ball, and the dark round the
camera, `Dark`, a model of `Slab` parts. On the course a spent charge comes back 1.5 s after it's
spent. Start at the spawn facing down the target lane (`VFTestYaw` 0, `VFTestPitch` 0), with the
Vandal in hand.

- **PA1 His kit.** In agent select (T), OMEN's card has Q PARANOIA lit now, with `Q readies a shadow
  orb. Fire sends it forward through walls, nearsighting and deafening everyone it touches.`, and
  nothing dimmed: C SHROUDED STEP and X FROM THE SHADOWS are lit too (sections 46 and 47). Close it
  with T. On the ability bar PARANOIA has its pip lit, and `VFKit` reads `C2/2 Q1/1 E2/2 X7/7`.
- **PA2 In hand.** Open the Sound Lab (F2 four times), and keep it open to PA5. Press Q: a thick,
  low whoosh, logged as `paranoiaEquip`, `yours`; the Vandal goes, and a dark violet ball with a
  flat band through it comes up over an open hand. Q's square lights, with `EQUIP` under it for
  1.1 s; the HUD reads `Paranoia   [Q]`, with no ammo; and `VFKit` ends in `equip`. Click the right
  button: nothing's sent or heard. Press Q again: the Vandal's back, and `VFKit` still reads `Q1/1`,
  nothing spent.
- **PA3 Down the lane.** Set `VFTestYaw` to 5, a little to the left, so it passes wide of the
  strafing dummies. Press Q and, once it's ready, click the left button: a heavy, slow whoosh,
  logged as `paranoiaSend`, `yours`. A see-through ball of shadow 8.6 m across, with a darker core,
  appears about 4.5 m ahead and flies down the lane through Dummies 1, 3 and 4, and 1.25 s later,
  its middle just short of the 30 m stripe, it's gone. The Vandal's back 0.7 s after the send, and
  Q's pip goes dark (`VFKit` `Q0/1`) and lights again 1.5 s later. Once the orb's gone,
  `VFLastParanoia` reads `Dummy 1 (static),Dummy 3 (crouch),Dummy 4 (static)`, and your own screen
  has stayed clear. Set `VFTestYaw` back to 0. **Send:** a screenshot of the orb in flight.
- **PA4 Through walls.** Walk to the wallbang lane, left of the spawn, and stand on its line in
  front of the `concrete 0.10 m` wall, facing the walls (`pos` about `-26.00 0.00 -10.00`,
  `VFTestYaw` 0). Send another: it flies straight through the walls, and `VFLastParanoia` reads
  `Dummy 11 (static)` first, the dummy behind that wall, then Dummies 10 and 12 in either order,
  then Dummies 9 and 13: the five behind the walls within 4.3 m of its path. Walk back to the spawn
  and face down the lane.
- **PA5 Nearsighted.** Set `VFTestPitch` to -89, looking straight down, send one, and set
  `VFTestPitch` straight back to 0: it appeared 4.5 m under your eye, inside the floor, near enough
  to your legs to touch you. At once a slowed tone, logged as `nearsight`, and the screen past about
  7.5 m is dark: Dummy 1, the 10 m stripe, the far wall and the sky are gone in it, and the floor
  round you still shows. Set `VFTestYaw` to 180 and back to 0: it's as dark behind you.
  `Workspace.VFParanoia.Dark` has 120 `Slab` parts, at Transparency 0. The minimap is off on the
  course, so it's PA6 that sees it covered. `VFNearsight` is set, and in SoundService
  `VFSound.world.worldMuffle` and `VFSound.self.selfMuffle` have Bypass off and Frequency 400, and
  the `world` and `self` faders Volume 0.35. 1.25 s after the send, `VFLastParanoia` reads your
  name. 2 s after the tone the dark draws back and thins away, and half a second later it's gone:
  the slabs at Transparency 1, `VFNearsight` unset, both muffles bypassed again, and the faders at
  full Volume again. Press F2 to close the Sound Lab. **Send:** a screenshot while it's dark.

Then three players: stop the game, start a Local Server with 3 players and press P in window 1
(Skirmish). Players 1 and 3 share a side, as in F1. As round 1's buy phase starts, agent select
comes up by itself: pick OMEN and LOCK IN in window 1, pick PHOENIX and LOCK IN in window 3, and
LOCK IN in window 2. Open the Sound Lab in window 2. In Skirmish each life starts with every charge.

- **PA6 Warned and nearsighted.** Once the round is live, players 1 and 3 stand side by side, 2 m
  apart, and player 2 about 20 m in front of them in the open, facing them: window 2's `VFMinimap`
  `Seen` has both of them. In window 1 press Q and, once it's ready, send it straight at player 2:
  window 2 logs `paranoiaSend`, about 20 m away. As the orb shows, the edges of window 2's screen go
  dark for a moment, and windows 1 and 3 don't. About half a second after the send, window 2 hears
  the tone, logged as `nearsight`, and its screen goes dark past about 7.5 m, players 1 and 3 gone
  in it; its minimap's covered (`Dark` 1), its `Seen` is empty, its `VFNearsight` is set, and its
  muffles are on, as in PA5. Windows 1 and 3 see a wisp of shadow round player 2's head, a `Wisp` in
  `Workspace.VFParanoia` with player 2's name as its `Player`. About 2.5 s after the tone it's all
  gone: window 2 is clear, its `Seen` has both again, and the wisp's gone. Player 1's
  `VFLastParanoia` reads `Player2`. Player 1 shoots player 2 down to end the round. **Send:** a
  screenshot of window 1 with the wisp.
- **PA7 A far flash.** In the next round, players 1, 2 and 3 stand as in PA6, and in window 3 press
  E to ready Curveball. Player 1 sends the orb at player 2 again, and as window 2 goes dark,
  player 3 throws the flare with the left button: it pops a few metres ahead of player 3, off to
  their left, well over 7.5 m from player 2 and in their view, and window 2 doesn't go white; its
  `VFBlind` stays unset. Windows 1 and 3 may go white, as it blinds whoever sees it. Once window 2's
  dark has gone, player 3 readies and throws the second flare the same way: now window 2 goes white,
  and its `VFBlind` is set.

Then the spike rounds: press P three times more in window 1 (the 1v1, gun game, then the spike
rounds), and as round 1's buy phase starts, pick OMEN and LOCK IN in window 1, and LOCK IN in
windows 2 and 3.

- **PA8 Bought.** `VFKit` reads `C0/2 Q0/1 E1/2 X0/7`, Q's pip dark. B: under the shields Paranoia
  (`Q`, 250), Dark Cover (`E`, 150) and Shrouded Step (`C`, 100) are all lit. Click Paranoia: 250
  credits go, Q's pip lights, and `VFKit` reads `Q1/1`; it then reads `FULL`, and a second click
  buys nothing. Close the menu (B). Once the round's live, send one: `Q0/1`, and nothing brings it
  back that round. E stays `E1/2`, its second pip dark and no count under it, and 40 s into the
  round it's still `E1/2`: a smoke that wasn't bought never comes. Send a smoke: `E0/2`, and E
  counts down from 40 under it, then reads `E1/2` again and stays there.

## 46. Omen's Shrouded Step

From [42-shrouded-step.md](research/42-shrouded-step.md). One player on the course, then three
there and in the spike rounds. Play as Omen, as in section 44. Without keys or a mouse button,
`VFTestButtons` 4096 presses C, 128 the left button, 1 W and 64 Space: set it and clear it again
each time. `VFTestYaw` and `VFTestPitch` aim, in degrees: positive yaw turns left, and positive
pitch looks up. The F3 panel's `pos` line is where you stand, in metres. Your `VFLastStep` attribute
is where your last step takes you, set as it's fired: the floor, in metres. `Workspace.VFStep` holds
the targeter, a `StepMark` part with its `Ring` and `Ghost`, and others' steps: their windups as
`Swirl` balls, their going as a `Puff`, the floor they're going to as a `Shadow` model, its `Entity`
attribute whose it is, and their arrival as a `Form`. PlayerGui's `VFStep` is your own screen
through it: its `Edge` frame through the windup, and `Dark` while you're gone. On the course a spent
charge comes back 1.5 s after you're there. Start at the spawn facing down the target lane
(`VFTestYaw` 0, `VFTestPitch` 0), with the Vandal in hand.

- **SS1 His kit.** In agent select (T), OMEN's card has C SHROUDED STEP lit now, with `C readies a
  short teleport, its mark on the floor. Fire steps you through the shadows to it.`, and X FROM THE
  SHADOWS lit too (section 47). Close it with T. On the ability bar SHROUDED STEP has its two pips
  lit, and `VFKit` reads `C2/2 Q1/1 E2/2 X7/7`.
- **SS2 In hand.** Open the Sound Lab (F2 four times), and keep it open to SS4. Press C: a thick,
  low whoosh, logged as `stepEquip`, `yours`; the Vandal goes, and three wisps of shadow curl up off
  an open hand. C's square lights, with `EQUIP` under it for 0.5 s; the HUD reads
  `Shrouded Step   [C]`, with no ammo; and `VFKit` ends in `equip`. Just short of half way from the
  10 m stripe to the 20 m one, about 14.9 m ahead, is a violet ring on the floor with a faint violet
  shadow of you standing in it, both shown over anything in front of them, Dummy 1 too. Set
  `VFTestPitch` to 20, into the sky: the ring comes back a little, to about 14 m, on the floor under
  where your aim ends. Set it back to 0. Press C again: the Vandal's back, the ring's gone, and
  `VFKit` still reads `C2/2`, nothing spent. **Send:** a screenshot of the ring and the shadow of
  you.
- **SS3 The step.** Set `VFTestPitch` to -18 and press C: once it's ready the ring's about 5 m
  ahead, half way to the 10 m stripe. Click the left button: a slow, deep tone, logged as `stepGo`,
  `yours`; the open hand goes, and shadow closes in from the screen's edges for 0.7 s. C's square
  stays lit with `STEP` under it, and C has one pip lit (`VFKit` `C1/2 Q1/1 E2/2 X7/7 step`). Then
  the screen goes dark (`VFKit` ends in `shroud`), and half a second later it clears as you're
  there: a quicker tone, logged as `stepArrive`, `yours`, and `pos` reads about `0.00 0.00 -4.99`.
  `VFLastStep` reads about `0, 0, -4.99`. The Vandal comes up as you're there, with its draw
  (`drawRifle`, `yours`), ready 0.7 s later, and C's second pip lights again 1.5 s after you're
  there. Walk back to the spawn.
- **SS4 Held.** Press C, and once it's ready click the left button and at once set `VFTestButtons`
  to 65 (W and Space), and keep it: through the windup and while you're gone you neither move nor
  jump, `pos` changing only as you're put 5 m ahead, and once you're there you jump and walk on down
  the lane. Clear it, press F2 to close the Sound Lab, and walk back to the spawn.
- **SS5 Nowhere.** Walk to the crouch tunnel, behind the spawn on the right, and stand 3 m in front
  of its mouth facing into it (`pos` about `3.00 0.00 8.00`, `VFTestYaw` -90). Press C and set
  `VFTestPitch` to -18: the ring's red, on the floor under the tunnel's roof, which is lower than
  you stand, and there's no shadow of you. Click the left button: nothing's fired or heard, the open
  hand stays, and `VFKit` still reads `C2/2`. Set `VFTestPitch` to -30: the ring's violet again just
  outside the tunnel's mouth, drawn back from under its roof, with the shadow of you in it. Click
  the left button: you're put there, `pos` about `5.61 0.00 8.00`.
- **SS6 Onto a box.** Walk to the red 1.00 m jump box, the furthest left of the four, and stand 5 m
  in front of it facing it (`pos` about `-13.50 0.00 -5.00`, `VFTestYaw` 0). Press C and set
  `VFTestPitch` to -7: the ring's on the box's top, with the shadow of you standing on it. Click the
  left button: you're put on top, `pos` about `-13.50 1.00 -10.05`. Walk off it.
- **SS7 A wall.** Walk to the wallbang lane and stand on its line in front of the `concrete 0.10 m`
  wall, facing the walls (`pos` about `-26.00 0.00 -10.00`, `VFTestYaw` 0, `VFTestPitch` 0). Press
  C: the ring's on the floor just this side of the wall, never behind it. Click the left button:
  `pos` about `-26.00 0.00 -19.51`, the wall right in front of you. Press C and set `VFTestPitch` to
  75, the aim up over the wall into the sky: the floor below where it ends is behind the wall, out
  of your sight, so the ring's red, and the left button does nothing. Press C to put it away, set
  `VFTestPitch` back to 0, and walk back to the spawn.

Then three players: stop the game and start a Local Server with 3 players, as in section 9. In
window 1 play as Omen, as before, and open the Sound Lab in windows 2 and 3.

- **SS8 Seen and heard.** Player 1 stands 4 m left of the spawn facing down the target lane (`pos`
  about `-4.00 0.00 0.00`, `VFTestYaw` 0), player 3 about 2 m to their right, and player 2 down the
  lane, half way from the 20 m stripe to the 30 m one, in line with player 1 and facing them. In
  window 1 press C, set `VFTestPitch` to -9, the ring about 10 m ahead, and click the left button:
  windows 2 and 3 log `stepGo`, and in both, shadow swirls up round player 1 (`Swirl` balls in
  `Workspace.VFStep`). 0.7 s later player 1's gone from both: a puff of shadow where they stood
  (`Puff`), and a column of shadow on the floor where they're going, darkening (a `Shadow` model).
  Half a second later player 1 stands there, shadow drawn in round them (`Form`), and the column's
  gone. Window 3, about 10 m away, logs `stepArrive`; window 2, about 15 m away, logs it as
  `not heard: out of range`, or not at all. **Send:** a screenshot of window 2 with the column of
  shadow.
- **SS9 Out of play.** Player 1 walks back to where they stood, and player 2 draws the Vandal. Once
  C's pips are both lit again, player 1 steps about 10 m ahead as before, and as the column of
  shadow shows in window 2, player 2 aims at it and holds the left button for about a third of a
  second: nothing hits player 1 before they're there, and the health over their head doesn't change.
  Once they're there, player 2's shots hit them again.

Then the spike rounds: press P four times in window 1, and as round 1's buy phase starts, pick OMEN
and LOCK IN in window 1, and LOCK IN in windows 2 and 3.

- **SS10 Bought.** `VFKit` reads `C0/2 Q0/1 E1/2 X0/7`, C's pips dark. B: under the shields Shrouded
  Step (`C`, 100), Paranoia (`Q`, 250) and Dark Cover (`E`, 150) are all lit. Click Shrouded Step:
  100 credits go, and C's first pip lights (`VFKit` `C1/2`). Click it again: another 100, both pips
  lit (`C2/2`); it then reads `FULL`, and a third click buys nothing. Close the menu (B). Press C:
  the ring shows on the minimap too, a violet disc where it would take you (`VFMinimap`'s `Icons`
  has `Step`). Still in the buy phase, walk up to the barrier in the door you face until it stops
  you, then step back 2.0 m (`pos` changing by 2.00), facing it. Set `VFTestPitch` to -10: the
  ring's on the floor this side of the barrier, never past it. Set `VFTestPitch` to 70 and then 75,
  the aim up over the barrier: the ring's red both times, and the left button does nothing. Set it
  to 0 and press C to put it away: still `C2/2`. Once the round's live and the barrier's gone, press
  C, set `VFTestPitch` to -18 and click the left button: you're put about 5 m ahead, through the
  door, and `VFKit` reads `C1/2`, which nothing brings back that round.

## 47. Omen's From the Shadows

From [43-from-the-shadows.md](research/43-from-the-shadows.md). One player on the course, then three
there and in Skirmish. Play as Omen, as in section 44. Without keys or a mouse button,
`VFTestButtons` 32768 presses X, 128 the left button and 1 W: set it and clear it again each time.
`VFTestYaw` and `VFTestPitch` aim, in degrees: positive yaw turns left, and positive pitch looks up.
A Vector3 attribute `VFTestMapPoint`, in metres, puts the map's cursor on the map nearest that place
once the map's up, then clears itself. The F3 panel's `pos` line is where you stand, in metres. Your
`VFLastShadow` attribute is where your last From the Shadows takes you, set as it's fired: the
floor, in metres. PlayerGui's `VFShadow` carries `Map` (whether its map's up), `Cursor` (the
cursor's place, in metres), `Placeable` (whether fire would take you there), `Grey` (whether you're
a Shade's grey), `Sight` (how far you see as one, in metres, or -1) and `Dark` (how dark an enemy's
has made your minimap, 0 to 1). The big map's ScreenGui, `VFMegamap`, has the cursor as `Shadow`
among its `Box`'s `Icons`. On the course the ultimate's points are full every life and fill again
1.5 s after you've formed. Start at the spawn facing down the target lane (`VFTestYaw` 0,
`VFTestPitch` 0), with the Vandal in hand.

- **FS1 His kit.** In agent select (T), OMEN's card has X FROM THE SHADOWS lit now, with `X brings
  up the map. Fire on a place in it sends you there as a Shade, which an enemy's shot or X again
  sends back before you form.`, and nothing on it dimmed. Close it with T. On the ability bar FROM
  THE SHADOWS has its seven pips lit gold, with `7/7` under it, and `VFKit` reads
  `C2/2 Q1/1 E2/2 X7/7`.
- **FS2 Its map.** Open the Sound Lab (F2 four times), and keep it open to FS6. Press X: a thick,
  low whoosh, logged as `shadowEquip`, `yours`; the Vandal goes, and a dark slate with a violet mark
  on it comes up over an open hand. X's square lights, with `EQUIP` under it for 0.5 s and then
  `MAP`; the HUD reads `From the Shadows   [X]`, with no ammo; and `VFKit` ends in `equip`. The big
  map comes up in the middle of the screen, the course drawn on it from its parts: its floors, its
  walls, and the boxes, steps, ramps and low walls; there's still no minimap at the top left
  (`VFMinimap`'s `Plan` reads `course`, and `Big` true). On you is a violet ring with a dot in it,
  the cursor (`Shadow`); `VFShadow`'s `Map` reads true, `Cursor` about `0, 0, 0` and `Placeable`
  true. Move the mouse: the cursor moves across the map, and the view doesn't turn. Press X again:
  the map's gone, the Vandal's back, and `VFKit` still reads `X7/7`, nothing spent. **Send:** a
  screenshot of the map.
- **FS3 Off the map.** Press X. Set `VFTestMapPoint` to `100, 0, 0`, far off to your right: the
  cursor stops at the map's edge, 2 m past the floor's (`Cursor` `42, 0, 0`), and it's red
  (`Placeable` false). Set it to `40, 0, -60`, off both floors, right of the target lane's end: red
  again. Click the left button: nothing's fired or heard, the map stays up, and `VFKit` still reads
  `C2/2 Q1/1 E2/2 X7/7 equip`.
- **FS4 The teleport.** Set `VFTestMapPoint` to `0, 0, -25`, half way from the 20 m stripe to the
  30 m one: the ring's violet there (`Cursor` `0, 0, -25`, `Placeable` true). Click the left button:
  a heavy whoosh slowed right down, logged as `shadowGo`, `yours`, and no draw; the map and the
  slate go, and shadow closes in from the screen's edges for 1.5 s, X's square lit with the seconds
  left under it, `1.5` down to `0.0`. X's pips are dark, `VFKit` reads
  `C2/2 Q1/1 E2/2 X0/7 shadows`, and `VFLastShadow` reads `0, 0, -25`. Then a deep, slow tone,
  logged as `shadowArrive`, `yours`: the edges clear, and you're a Shade 25 m down the lane, `pos`
  about `0.00 0.00 -25.00`. The world's nearly grey (`Grey` true, and a `VFShade`
  ColorCorrectionEffect under the camera), and dark close round you, the dark drawing back slowly
  and then faster: `Sight` reads `0.2` at first, about `2.5` half way, and nearly `10` at the last.
  X reads `SHADE`, and `VFKit` ends in `shade`. 2.5 s after you arrived, a quicker tone, logged as
  `shadowForm`, `yours`: the grey and the dark are gone (`Grey` false, `Sight` -1), and the Vandal
  comes up with its draw, logged as `drawRifle`, `yours`, ready 1 s later. X's pips light again
  1.5 s after you formed. **Send:** a screenshot as a Shade, half way through.
- **FS5 Held.** Once X's pips are lit again, press X, set `VFTestMapPoint` to `0, 0, 0`, the spawn,
  click the left button, and at once set `VFTestButtons` to 65 (W and Space) and keep it. Through
  the windup and as a Shade you neither move nor jump, `pos` changing only as you're put at the
  spawn; set `VFTestYaw` to 90 and back to 0 meanwhile, and the view turns. Once you've formed you
  jump and walk on down the lane. Clear it, and walk back to the spawn.
- **FS6 Sent back.** Once X's pips are lit again, press X, set `VFTestMapPoint` to `0, 0, -25` and
  click the left button. In the windup press X: nothing changes, and 1.5 s after the click you're a
  Shade 25 m down the lane, as in FS4. Then press X again: a thin, slowed swish, logged as
  `shadowBreak`, `yours`; at once you're back at the spawn, `pos` about `0.00 0.00 0.00`, the grey
  and the dark gone (`Grey` false), and the Vandal comes up with its draw (`drawRifle`, `yours`),
  ready 1 s later. `VFKit` reads `X0/7`, the points spent all the same, and X's pips light again
  1.5 s later. Press F2 to close the Sound Lab.
- **FS7 Where it takes you.** Once X's pips are lit again, press X, set `VFTestMapPoint` to
  `-13.5, 0, -10`, the top of the red 1.00 m jump box, and click the left button: as a Shade you
  stand on the box, `pos` about `-13.50 1.00 -10.00`. Once they're lit again, the same with
  `8, 0, 8`, over the crouch tunnel: you're put on its roof, `pos` about `8.00 1.80 8.00`. Then
  `-26, 0, -24.25`, on the backstop behind the wallbang lane's walls, 3 m tall: the ring's violet,
  and you're put just in front of it, `pos` about `-26.00 0.00 -23.55`.

Then three players: stop the game and start a Local Server with 3 players, as in section 9. In
window 1 play as Omen, as before, and open the Sound Lab in windows 2 and 3.

- **FS8 Seen and heard.** Player 1 stands 4 m left of the spawn facing down the target lane (`pos`
  about `-4.00 0.00 0.00`, `VFTestYaw` 0), player 3 about 2 m to their right, facing the same way,
  and player 2 down the lane at `pos` about `-4.00 0.00 -15.00`, facing down it too. In window 1
  press X, set `VFTestMapPoint` to `-4, 0, -25`, and click the left button: windows 2 and 3 log
  `shadowGo`, and in window 3 shadow swirls up round player 1 (`Swirl` balls in `Workspace.VFStep`)
  for 1.5 s. Then player 1's gone from where they stood in a puff of shadow (`Puff`), and in both
  windows they stand 10 m ahead of player 2, a Shade, dark and see-through, shadow drawn in round
  them (`Form`). Window 2 logs `shadowArrive`; window 3, about 25 m away, logs it as
  `not heard: out of range`, or not at all. 2.5 s later player 1 forms there, drawn as before, with
  shadow drawn in round them again: window 2 logs `shadowForm`, and window 3 logs it as out of
  range, or not at all. **Send:** a screenshot of window 2 with player 1 as a Shade.
- **FS9 Broken.** Player 1 walks back to where they stood (`pos` about `-4.00 0.00 0.00`), and
  player 2 draws the Vandal and turns to face them (`VFTestYaw` 180, `VFTestPitch` -5). Once X's
  pips are lit again, player 1 sends themself to `-4, 0, -10`, 5 m in front of player 2. As soon as
  player 1's a Shade there, player 2 fires one shot at it: at once player 1's back where they stood,
  `pos` about `-4.00 0.00 0.00`, the grey gone in window 1 and the Vandal coming up. Window 1 logs
  `shadowBreak`, `yours`, and windows 2 and 3 log `shadowBreak` and `shadowForm`, with a puff of
  shadow where the Shade was and shadow drawn in where player 1's back. The health over player 1's
  head doesn't change in windows 2 and 3, nor does window 1's own, and window 1's `VFKit` reads
  `X0/7`.

Then Skirmish: press P in window 1. Players 1 and 3 share a side, as in F1. As round 1's buy phase
starts, agent select comes up by itself: pick OMEN and LOCK IN in window 1, and LOCK IN in windows 2
and 3. In Studio, setting `VFTestGive` to `ultimate` fills the ultimate's points.

- **FS10 The buy phase.** In the buy phase set `VFTestGive` to `ultimate` in window 1: X's seven
  pips light, and `VFKit` reads `X7/7`. Press X: the big map comes up with the cursor on you
  (`VFMinimap`'s `Big` reads true), and the ring's red (`Placeable` false). Click the left button:
  nothing's fired or heard, and `VFKit` still reads `X7/7`. Press X to put it away.
- **FS11 Their minimaps.** In window 1 press X a moment before the round goes live, and keep the map
  up: as it goes live the ring turns from red to violet at once (`Placeable` true). Then click the
  left button with the cursor where it starts, on you: windows 2 and 3 log `shadowGo`. From then
  until player 1 has formed, 4 s later, window 2's minimap at the top left is covered in dark, and
  its big map too while Caps Lock is held (`VFMinimap`'s `Dark` reads 1); window 3's isn't (`Dark`
  0). In window 1 a violet disc on the minimap shows where you're going, on you, until you've formed
  (`VFMinimap`'s `Icons` has `Shade`). Set `VFTestGive` to `ultimate` in window 1 again, fire again
  where you stand, and press X as soon as you're a Shade: window 2's minimap clears as player 1's
  sent back, before the 4 s are up. **Send:** a screenshot of window 2's dark minimap.

## 48. Sova's Recon Bolt

From [44-recon-bolt.md](research/44-recon-bolt.md). One player on the course, then three there and
in Skirmish. Play as Sova: press T, click SOVA's card and PICK SOVA (or set `VFTestAgents` to true,
`VFTestAgent` to `sova`, then `VFTestAgent` to `lock`). Without keys or a mouse button,
`VFTestButtons` 16384 presses E, 128 the left button and 256 the right: set it and clear it again
each time, and leave 128 set for as long as the left button's held. `VFTestYaw` and `VFTestPitch`
aim, in degrees: positive yaw turns left, and positive pitch looks up; a Vector3 `VFTestAimPoint`,
in metres, aims at that place instead until it's cleared. The F3 panel's `pos` line is where you
stand, in metres. Your `VFLastBolt` attribute is where your last bolt stuck, in metres,
`VFLastRecon` the names its last pulse revealed, in order, and `VFBoltHealth` the health it has
left. PlayerGui's `VFRecon` carries `Bow` (whether the bow's in hand), `Bars` (the bars drawn),
`Bounces` (the bounces added), `Bolts` (the bolts drawn, in the air or stuck) and `Revealed` (the
silhouettes shown), and `Workspace.VFRecon` holds each bolt (`Bolt`), each pulse (`Pulse`) and each
silhouette (`Reveal_` and the entity's id: Dummy 1's is 4294901761, and Dummy 6's 4294901766). On
the course a spent charge comes back 1.5 s after it's spent. Start each check at the spawn facing
down the target lane (`VFTestYaw` 0, `VFTestPitch` 0), with the Vandal in hand.

- **RC1 His kit.** In agent select (T), the cards are JETT, PHOENIX, SAGE, OMEN and SOVA, and SOVA's
  reads INITIATOR. Click it: his kit, headed `SOVA   INITIATOR`, with Q SHOCK BOLT lit (section 49),
  X HUNTER'S FURY lit (section 50), and E RECON BOLT lit, with `E readies the bow. Hold fire to draw
  it further and alt fire to add bounces; it sticks where it lands and pulses, revealing enemies it
  sees.`, and C OWL DRONE lit (section 51); nothing under them, as he has no passive. Click PICK
  SOVA: the button reads `PLAYING SOVA`, and `VFAgent` reads `sova`. Close it with T. On the ability
  bar RECON BOLT has its one pip lit, SHOCK BOLT its two, OWL DRONE its one and HUNTER'S FURY its
  eight, gold, and `VFKit` reads `C1/1 Q2/2 E1/1 X8/8`. **Send:** a screenshot of Sova's card.
- **RC2 In hand.** Open the Sound Lab (F2 four times), and keep it open to RC8. Press E: a quick,
  light rattle, logged as `boltEquip`, `yours`; the Vandal goes, and a short dark bow comes up, held
  upright, with a bolt of light blue beside its grip. E's square lights, with `EQUIP` under it for
  0.8 s; the HUD reads `Recon Bolt   [E]`, with no ammo; and `VFKit` ends in `equip`. Under the
  crosshair are three dark bars with two dark diamonds under them (`VFRecon`'s `Bow` true, `Bars` 0
  and `Bounces` 0). Press E again: the bow and the bars go, the Vandal's back, and `VFKit` reads
  `C1/1 Q2/2 E1/1 X8/8`, nothing spent.
- **RC3 The draw.** Press E, and once `EQUIP`'s gone set `VFTestButtons` to 128 and keep it: a slow,
  low scrape, logged as `boltNock`, `yours`, and the bars light blue one by one, a third of a second
  apart, and stay at three (`Bars` 3); `VFKit` ends in `equip draw 3`. Set it to 384 and back to
  128: the first diamond lights (`Bounces` 1), and `VFKit` ends in `draw 3 bounce 1`. Again: both,
  and `bounce 2`. Again: neither, `Bounces` 0, and no `bounce` in `VFKit`. Set it to 16512 (E and
  the left button) and back to 128: the bars go dark (`Bars` 0), `draw` goes from `VFKit` and the
  bow stays in hand, its bars dark while the button's held. Clear it: nothing's loosed or heard, and
  `VFKit` reads `C1/1 Q2/2 E1/1 X8/8 equip`. Press E to put the bow away.
- **RC4 The loose.** Press E, and once `EQUIP`'s gone set `VFTestButtons` to 128 and clear it at
  once: a thin swish, logged as `boltLoose`, `yours`, and a quick, quiet whoosh, `boltFlight`; a
  thin shaft of light flies down the lane, dropping as it goes, and about 1 s later sticks in the
  floor just short of the 20 m stripe, standing up out of it, with a quick metallic strike,
  `boltStick`. `VFLastBolt` reads about `0, 0.05, -18.6`, and `VFBoltHealth` 20. The bow goes and
  the Vandal's back 0.7 s after the swish; E's pip goes dark, the seconds to its cooldown under it,
  and lights again 1.5 s later. The shaft brightens, and 0.67 s after it stuck a bell's ping, logged
  as `reconPulse`, `yours`: a shell of light sweeps out from it to 60 m across, and the dummies it
  sees light up red where they stand, over anything in the way, for 0.75 s (`Reveal_4294901761` and
  others in `Workspace.VFRecon`, counted by `Revealed`). 1.6 s later a second ping and sweep, and
  1.6 s after that the shaft's gone (`Bolts` 0). `VFLastRecon` has Dummy 1 to Dummy 5 and Dummy 7,
  and some of the wallbang lane's dummies, seen from the side past the ends of their walls, but not
  Dummy 6, 31 m away. **Send:** a screenshot as the first pulse sweeps out.
- **RC5 Drawn further.** Set `VFTestPitch` to 1. Press E, and once `EQUIP`'s gone hold the left
  button until `Bars` reads 1, then let it go: the bolt flies faster and sticks in the floor 2 m
  short of Dummy 4, `VFLastBolt` about `0, 0.05, -28.0`. Once E's lit again, the same until `Bars`
  reads 2: faster still, it sticks in the lane's floor about 4 m past Dummy 6, `0, 0.05, -53.9`,
  1.3 s after the loose, and `VFLastRecon` reads `Dummy 4 (static),Dummy 5 (strafe),Dummy 6
  (static)`, no more. Then until `Bars` reads 3: flatter, it sticks in the backstop about 1.1 m up,
  `0, 1.12, -59.7`, about 1.45 s after the loose, and `VFLastRecon` has Dummy 6 and Dummy 4, 29.6 m
  away, just inside its 30 m, and Dummy 5 at times as it strafes in and out of reach.
- **RC6 Bounces.** Set `VFTestPitch` to 0. Press E, and once `EQUIP`'s gone set `VFTestButtons` to
  256 and clear it (`Bounces` 1), then tap the left button as in RC4: the bolt goes off the floor
  short of the 20 m stripe, rises back to about head height, and sticks in the lane's floor about
  4 m short of the backstop, `VFLastBolt` about `0, 0.05, -55.9`, about 3.1 s after the loose;
  `VFLastRecon` reads `Dummy 4 (static),Dummy 5 (strafe),Dummy 6 (static)`. Once E's lit again, the
  same with two bounces (256 twice, cleared between): it goes off the floor there too and sticks in
  the backstop's foot, `0, 0.64, -59.7`, about 3.3 s after the loose. Once it's lit again, set
  `VFTestPitch` to 1, press E, give it one bounce and hold the left button until `Bars` reads 3: it
  goes off the backstop about 1.1 m up and comes back down the lane, sticking in the floor between
  the 30 m and 40 m stripes, `0, 0.05, -35.6`, about 2 s after the loose.
- **RC7 Walls in the way.** Walk to the wallbang lane's 10 m line, in front of the concrete 0.10 m
  wall (`pos` about `-26.00 0.00 -10.00`, `VFTestYaw` 0, `VFTestPitch` 0), and loose a tap: it
  sticks in the wall's face about 1.2 m up, `VFLastBolt` about `-26, 1.17, -19.95`. At its pulses
  `VFLastRecon` has Dummy 1 and Dummy 3, 28 m and 24 m away in the open, but not Dummy 2, strafing
  more than 30 m away, nor any of the dummies behind the walls, not even Dummy 11, 1.6 m behind the
  wall the bolt's in.
- **RC8 Shot to pieces.** Back at the spawn, loose a tap as in RC4. As soon as the first ping's
  heard, set `VFTestAimPoint` to `0, 0.3, -18.6`, the shaft's middle, and fire one shot (128, then
  clear it): a sharp crack, logged as `boltBreak`, `yours`, a flash where the shaft stood, and it's
  gone (`Bolts` 0); `VFBoltHealth` reads 0, and there's no second ping. Clear `VFTestAimPoint`, and
  press F2 to close the Sound Lab.

Then three players: stop the game and start a Local Server with 3 players, as in section 9. In
window 1 play as Sova, as before, and open the Sound Lab in windows 2 and 3. Player 1's id is
4294967295, player 2's 4294967294 and player 3's 4294967293.

- **RC9 Seen and heard.** Player 1 stands at the spawn facing down the target lane (`VFTestYaw` 0,
  `VFTestPitch` 0), player 3 beside them, 2 m to their left (`pos` about `-2.00 0.00 0.00`), and
  player 2 down the lane, 4 m right of its middle half way from the 20 m stripe to the 30 m one
  (`pos` about `4.00 0.00 -25.00`). In window 1 press E and tap the left button: windows 2 and 3 log
  `boltLoose` and `boltFlight`, see the shaft of light fly and stick short of the 20 m stripe, and
  log `boltStick`; then both log `reconPulse` twice and see the shell of light sweep out, but nobody
  lights up red in either (`Revealed` 0). In window 1 players 2 and 3 light up red at each pulse
  with the dummies (`Reveal_4294967294` and `Reveal_4294967293`), and `VFLastRecon` ends in
  `Player2,Player3`. **Send:** a screenshot of window 1 at a pulse.
- **RC10 Broken by another.** Once E's lit again in window 1, loose another tap the same way. In
  window 2 set `VFTestAimPoint` to `0, 0.3, -18.6` and, as soon as the bolt's stuck, fire one shot
  with the Vandal: a sharp crack in all three windows, logged as `boltBreak`, a flash where the
  shaft stood, and it's gone from all three; window 1's `VFBoltHealth` reads 0, and nobody logs
  another `reconPulse` from it. Clear `VFTestAimPoint`.

Then Skirmish: press P in window 1. Players 1 and 3 share a side, as in F1. As round 1's buy phase
starts, agent select comes up by itself: pick SOVA and LOCK IN in window 1, and LOCK IN in windows 2
and 3.

- **RC11 Free each round.** In the buy phase, window 1's `VFKit` reads `C1/1 Q2/2 E1/1 X0/8`. B:
  under the shields are Owl Drone (`C`, 400), its pip lit and reading `FULL` (section 51), and Shock
  Bolt (`Q`, 150), its two pips lit and reading `FULL` (section 49), and no Recon Bolt; clicking
  them buys nothing. Close the menu (B).
- **RC12 Revealed to his side.** Once the round's live, player 2 goes round a corner or behind cover
  within 25 m of players 1 and 3, out of their sight. Player 1 looses a bolt that sticks where
  player 2's in its sight, on a floor or a wall near them, with bounces if they help, and player 3
  steps into its sight too. At each pulse, in windows 1 and 3, player 2 lights up red through the
  walls for 0.75 s, moving as they move (`Reveal_4294967294`), and for as long a red dot shows them
  on window 1's minimap, then a `?` where they were (`VFMinimap`'s `Seen` reads `4294967294` while
  it lasts); window 2 sees the bolt and its sweeps and logs `reconPulse`, but nobody lights up red
  in it (`Revealed` 0). `VFLastRecon` reads `Player2` alone, though player 3 stands in the bolt's
  sight. Window 1's E pip is dark, the seconds under it counting down from 50, and it lights again
  50 s after the loose. **Send:** a screenshot of window 1 at a pulse, with its minimap.
- **RC13 Allies' shots, and an enemy's.** Once E's lit again, player 1 looses a bolt onto the floor
  in the open where players 2 and 3 can both see it. As soon as it's stuck, player 3 aims at its
  shaft (`VFTestAimPoint` 0.25 m over player 1's `VFLastBolt`) and fires three shots: window 1's
  `VFBoltHealth` stays 20, and it pulses on. Player 2 does the same with one shot: a sharp crack in
  all three windows, logged as `boltBreak`, the shaft gone, `VFBoltHealth` 0, and no pulse after.

## 49. Sova's Shock Bolt

From [45-shock-bolt.md](research/45-shock-bolt.md). One player on the course, then three there, in
Skirmish and in the spike rounds. Play as Sova, as in section 48. Without keys or a mouse button,
`VFTestButtons` 8192 presses Q, 128 the left button and 256 the right: set it and clear it again
each time, and leave 128 set for as long as the left button's held. `VFTestYaw` and `VFTestPitch`
aim, in degrees: positive yaw turns left, and positive pitch looks up; a Vector3 `VFTestAimPoint`,
in metres, aims at that place instead until it's cleared. The F3 panel's `pos` line is where you
stand, in metres. Your `VFLastShock` attribute is where your last bolt burst, in metres, and
`VFShockHits` whom it hurt and how much: each a name and its damage, in order of their names and
joined by commas, or nothing. PlayerGui's `VFRecon` shows the bow's draw as in section 48 (`Bow`,
`Bars` and `Bounces`), and `Workspace.VFShock` holds each bolt in the air (`Bolt`) and each burst
while it flashes (`Burst`); its `Bolts` attribute counts the bolts in the air, and `Bursts` the
bursts shown. You and the dummies wear Heavy Armor, their labels reading `100 + 50`, and a dummy
comes back 2 s after it dies. On the course a spent charge comes back 1.5 s after it's spent. Start
each check at the spawn facing down the target lane (`VFTestYaw` 0, `VFTestPitch` 0), with the
Vandal in hand.

- **SB1 His kit.** In agent select (T), click SOVA's card: Q SHOCK BOLT is lit now, with `Q readies
  the bow with a shock bolt. Hold fire to draw it further and alt fire to add bounces; it bursts
  where it lands, hurting those near it.` (C OWL DRONE is section 51's, and X HUNTER'S FURY
  section 50's). Click PICK SOVA and close it with T. On the ability bar SHOCK BOLT has its two pips
  lit, and `VFKit` reads `C1/1 Q2/2 E1/1 X8/8`. Press B: under the shields Shock Bolt (`Q`, 150) has
  its two pips lit and reads `FULL`. Hover it: `Ability, on Q`, the line on his card, and its rows,
  `Charges` up to 2, `A charge` 150 credits and `Burst` `75 within 1 m, 1 at 5 m`. Close the menu
  (B). **Send:** a screenshot of the hover.
- **SB2 In hand.** Open the Sound Lab (F2 four times), and keep it open to SB8. Press Q: a quick,
  light rattle, logged as `boltEquip`, `yours`; the Vandal goes, and the Recon Bolt's bow comes up,
  with a bolt of pale yellow beside its grip. Q's square lights, with `EQUIP` under it for 0.8 s;
  the HUD reads `Shock Bolt   [Q]`, with no ammo; and `VFKit` ends in `equip`. Under the crosshair
  are three dark bars with two dark diamonds under them (`VFRecon`'s `Bow` true). Once `EQUIP`'s
  gone, set `VFTestButtons` to 128 and keep it: a slow, low scrape, `boltNock`, and the bars light
  blue a third of a second apart, three at the most; `VFKit` ends in `equip draw 3`. Set it to 384
  and back to 128: the first diamond lights, and `VFKit` ends in `draw 3 bounce 1`. Set it to 8320
  (Q and the left button) and back to 128: the bars go dark and `draw` goes from `VFKit`, the bow
  still in hand. Clear it: nothing's loosed or heard. Press Q again: the bow and the bars go, the
  Vandal's back, and `VFKit` reads `C1/1 Q2/2 E1/1 X8/8`, nothing spent.
- **SB3 The burst.** Press Q, and once `EQUIP`'s gone set `VFTestButtons` to 128 and clear it at
  once: a thin swish, logged as `boltLoose`, `yours`, and a quick, quiet whoosh, `boltFlight`; a
  thin shaft of pale yellow light flies down the lane, dropping as it goes (`Workspace.VFShock`'s
  `Bolts` 1), and about 1 s later, where it meets the floor just short of the 20 m stripe, it
  bursts: a ball of light flashes out 10 m across and fades in about a third of a second, with a
  crack, louder and deeper than a recon bolt's breaking, logged as `shockBurst`, `yours` (`Bolts` 0,
  `Bursts` 1). `VFLastShock` reads about `0, 0.05, -18.6`, and `VFShockHits` has
  `Dummy 3 (crouch) 48`, crouched 2.4 m from it, whose label reads `84 + 19` (83.68 and 18.32,
  rounded up), and nobody else: Dummy 2, strafing 4 m to 6 m right of the lane's middle, stays out
  of its reach. The bow goes and the Vandal's back 0.7 s after the swish; one of Q's pips goes dark,
  and lights again 1.5 s later. **Send:** a screenshot as it bursts.
- **SB4 At a dummy's feet.** Walk 4 m down the lane (`pos` about `0.00 0.00 -4.00`, and no closer,
  or the burst reaches you too), set `VFTestAimPoint` to `0, 0.1, -10`, Dummy 1's feet, and loose a
  tap: it bursts just short of them about a third of a second later, `VFLastShock` about
  `0, 0.05, -9.6`, and `VFShockHits` reads `Dummy 1 (static) 75`; its label reads `75 + 1` (74.5 and
  0.5, rounded up), and your HUD still reads `100` and `+50`. Press Q and loose your second the same
  way: Dummy 1 dies, and the kill feed reads `<your name>   Shock Bolt   Dummy 1`. Clear
  `VFTestAimPoint`.
- **SB5 Further out, less.** Back at the spawn, set `VFTestPitch` to 1. Press Q, hold the left
  button until `Bars` reads 1, and let it go: it bursts on the floor 2 m short of Dummy 4 about 1 s
  after the loose, `VFLastShock` about `0, 0.05, -28.0`, and `VFShockHits` has Dummy 4 for about 57,
  its label about `81 + 13`, and Dummy 5 at times, for less, as it strafes. Once Q's pips are lit
  again, the same until `Bars` reads 2: it bursts on the lane's floor about 4 m past Dummy 6,
  `0, 0.05, -53.9`, 1.3 s after the loose, and `VFShockHits` reads `Dummy 6 (static)` and about 21.
  Then until `Bars` reads 3: it bursts on the backstop about 1.1 m up, `0, 1.12, -59.7`, nearly 10 m
  from Dummy 6, and `VFShockHits` is empty. Set `VFTestPitch` back to 0.
- **SB6 Your own.** Set `VFTestPitch` to -90 and loose a tap: it bursts at your feet at once,
  `VFLastShock` about `0, 0.05, 0`, and `VFShockHits` reads `<your name> 75`: your HUD reads `75`
  and `+1` (74.5 and 0.5, rounded up). Set `VFTestPitch` back to 0.
- **SB7 A bounce.** Press Q, set `VFTestButtons` to 256 and clear it (`Bounces` 1), then loose a
  tap: the bolt goes off the floor short of the 20 m stripe without bursting, rises back to about
  head height, and bursts on the lane's floor about 4 m short of the backstop, `VFLastShock` about
  `0, 0.05, -55.9`, about 3.1 s after the loose; `VFShockHits` is empty, Dummy 6 being 5.9 m from
  it.
- **SB8 Walls in the way.** Walk to the wallbang lane's 10 m line, in front of the concrete 0.10 m
  wall (`pos` about `-26.00 0.00 -10.00`, `VFTestYaw` 0, `VFTestPitch` 0), and loose a tap: it
  bursts on the wall's face about 1.2 m up, `VFLastShock` about `-26, 1.17, -19.95`, and
  `VFShockHits` is empty: Dummy 11, 1.6 m behind the wall, and the dummies beside it are unhurt,
  their labels still `100 + 50`. Press F2 to close the Sound Lab.

Then three players: stop the game and start a Local Server with 3 players, as in section 9. In
window 1 play as Sova, as before, and open the Sound Lab in windows 2 and 3.

- **SB9 Seen, heard and hurt.** Player 1 stands at the spawn facing down the target lane
  (`VFTestYaw` 0, `VFTestPitch` 0), player 3 beside them, 2 m to their left (`pos` about
  `-2.00 0.00 0.00`), and player 2 where a tap lands, just short of the 20 m stripe (`pos` about
  `0.00 0.00 -18.60`). In window 1 press Q and loose a tap: windows 2 and 3 log `boltLoose` and
  `boltFlight`, see the shaft of light fly through player 2 and burst at their feet, and log
  `shockBurst`. Window 2's HUD reads `75` and `+1`, and window 3's still `100` and `+50`; window 1's
  `VFShockHits` ends in `Player2 75`. **Send:** a screenshot of window 2 as it bursts.

Then Skirmish: press P in window 1. Players 1 and 3 share a side, as in F1. As round 1's buy phase
starts, agent select comes up by itself: pick SOVA and LOCK IN in window 1, and LOCK IN in windows 2
and 3.

- **SB10 Friend and foe.** In the buy phase, window 1's `VFKit` reads `C1/1 Q2/2 E1/1 X0/8`. Once
  the round's live, players 2 and 3 stand side by side in the open, a metre apart and across
  player 1's line of sight, and player 1, at least 6 m from them, sets `VFTestAimPoint` on the floor
  between them, 0.1 m up, and looses a Shock Bolt: windows 2 and 3 both read `75` and `+1`, and
  window 1's `VFShockHits` reads `Player2 75,Player3 75`, his side hurt as his enemies are;
  window 1's `VFKit` then reads `Q1/2`, and the spent pip stays dark for the rest of the round.
  Clear `VFTestAimPoint`.

Then the spike rounds: press P three times more in window 1 (the 1v1, gun game, then the spike
rounds), and as round 1's buy phase starts, pick SOVA and LOCK IN in window 1, and LOCK IN in
windows 2 and 3.

- **SB11 Bought.** `VFKit` reads `C0/1 Q0/2 E1/1 X0/8`, both of Q's pips dark. B: under the shields
  Shock Bolt (`Q`, 150) is lit, its pips dark. Click it: 150 credits go, one of Q's pips lights, and
  `VFKit` reads `Q1/2`; click again: `Q2/2`, and the tile reads `FULL`, and a third click buys
  nothing. Close the menu (B). Once the round's live, loose one: `Q1/2`, and the spent pip stays
  dark for the rest of the round.

## 50. Sova's Hunter's Fury

From [46-hunters-fury.md](research/46-hunters-fury.md). One player on the course, then three there
and in Skirmish. Play as Sova, as in section 48. Without keys or a mouse button, `VFTestButtons`
32768 presses X, 128 the left button, 8192 Q, 1 W and 64 jump: set it and clear it again each time,
and leave a button set for as long as it's held. `VFTestYaw` and `VFTestPitch` aim, in degrees:
positive yaw turns left, and positive pitch looks up; a Vector3 `VFTestAimPoint`, in metres, aims at
that place instead until it's cleared, and `VFTestSlot` set to 1 draws the Vandal as 1 does. The F3
panel's `pos` line is where you stand, in metres. Your `VFLastFury` attribute is where your last
blast went from, in metres, and `VFFuryHits` whom it caught, their names in order and joined by
commas, or nothing. PlayerGui's `VFFury` carries `Bow` (whether its bow's in hand), `Left` (the
seconds it has left), `Charging` (whether a blast charges), `Turn` (how fast the mouse turns the
view, as a share of its usual) and `Blasts` (the blasts drawn), and `Workspace.VFFury` holds each
blast while it fades (`Blast`) and each blast of someone else's while it charges (`Charge`). Whom a
blast reveals lights up as a Recon Bolt's pulse does (section 48: `VFRecon`'s `Revealed`, and
`Reveal_` and the entity's id in `Workspace.VFRecon`). You and the dummies wear Heavy Armor, their
labels reading `100 + 50`, and a dummy comes back 2 s after it dies; Dummy 18 stands 30 m behind the
spawn. On the course the ultimate's 8 points are full every life, and full again 1.5 s after
Hunter's Fury is over. Start each check at the spawn facing down the target lane (`VFTestYaw` 0,
`VFTestPitch` 0), with the Vandal in hand.

- **HF1 His kit.** In agent select (T), click SOVA's card: X HUNTER'S FURY is lit now, with `X
  readies the bow with three energy blasts for 6 s. Fire charges one, then sends it in a long line
  through walls, hurting and revealing enemies in it.`, and C OWL DRONE is lit too (section 51).
  Click PICK SOVA and close it with T. On the ability bar X's square has eight gold pips and reads
  `8/8` in gold, and `VFKit` reads `C1/1 Q2/2 E1/1 X8/8`. **Send:** a screenshot of Sova's card.
- **HF2 In hand.** Open the Sound Lab (F2 four times), and keep it open to HF8. Press X: a low
  chime, a bell slowed right down, logged as `furyCast`, `yours`, and a quick, light rattle,
  `boltEquip`; the Vandal goes, and the Recon Bolt's bow comes up with a bolt of bright cyan beside
  its grip, the bar labelled `drawing` filling over half a second. X's square is outlined in teal,
  its pips dark, with `EQUIP` under it for 0.5 s and then the seconds left, counting down from
  `6.0`; the ammo box reads `3`, with `Hunter's Fury   [X]` under it; and `VFKit` reads
  `C1/1 Q2/2 E1/1 X0/8 fury`. Under the crosshair are two bars (`VFFury`'s `Bow` true): the upper
  one full, dim until the bow's drawn and then bright, emptying as the seconds run down (`Left`),
  and a dark one under it. On the minimap a cyan band runs from you the way you face, out past the
  lane's end (`Fury`, in `VFMinimap`'s `Utility`), and turns as you turn. Fire nothing: as X's note
  reaches 0 the bow, the bars and the band go, and the Vandal comes back up over its 1 s draw;
  `VFKit` reads `X0/8`, and about 1.5 s later `X8/8`, the pips gold again. **Send:** a screenshot
  with the bow up and the minimap.
- **HF3 A blast.** Press X, and once X's note shows its seconds set `VFTestButtons` to 128 and clear
  it at once: no shot, but a swelling hum, logged as `furyCharge`, `yours`; the lower bar fills over
  1 s (`Charging` true, `Turn` 0.15), and `VFKit` ends in `fury charge`. As it fills, a deep boom,
  logged as `furyBlast`, `yours`: a band of cyan light 4 m across, with a bright line down its
  middle, runs from just under your eye straight down the lane and on through the backstop, and
  fades in about half a second (`Blast` in `Workspace.VFFury`, `Blasts` 1), and you slide 1.5 m back
  (`pos` about `0.00 0.00 1.50`; `Turn` 1 again). The ammo box reads `2`. `VFLastFury` reads
  `0, 1.62, 0`, and `VFFuryHits` reads `Dummy 1 (static),Dummy 3 (crouch),Dummy 4 (static),Dummy 6
  (static)`: each one's label reads `70 + 0`, and each lights up red through anything in the way for
  1 s (`Revealed` 4). Dummy 2 and Dummy 5, strafing 4 m to 6 m right of the line, Dummy 7 behind its
  cover and Dummy 18 behind you are untouched, their labels still `100 + 50`. **Send:** a screenshot
  as the band goes.
- **HF4 Two to kill.** Once X's note has dropped 2.2 since your first click, fire again as in HF3:
  after the hum and the windup, the band and the boom go again from 1.5 m further back (`VFLastFury`
  `0, 1.62, 1.5`), and the four dummies die; the kill feed reads
  `<your name>   Hunter's Fury   Dummy 1`, and the same for Dummy 3, Dummy 4 and Dummy 6. You slide
  back to `pos` about `0.00 0.00 3.00`, the ammo box reads `1`, and `VFKit` reads `X4/8 fury`, a
  point for each kill. Fire no more: as X's note reaches 0 the bow goes and the Vandal comes back,
  `VFKit` reads `X4/8`, and about 1.5 s later `X8/8`.
- **HF5 Rooted.** Walk back to the spawn. Press X, and once X's note shows its seconds set
  `VFTestButtons` to 128, and as `Charging` reads true set it to 129 (W and the left button) and
  keep it: through the windup `pos` doesn't change. As the blast goes you slide back 1.5 m, and then
  you walk forward down the lane. Clear it, and at once click again (128, then clear it), less than
  2.125 s after your first click: nothing happens (`Charging` stays false, and nothing's heard).
  Once X's note has dropped 2.2 since your first click, click again: the hum, and a blast 1 s later.
  Leave the last blast unfired.
- **HF6 Cut short.** Back at the spawn, once `X8/8`'s back, press X and fire as in HF3, and as
  `Charging` reads true clear `VFTestButtons` and set `VFTestSlot` to 1: the bow and the bars go at
  once, the Vandal comes up, and no blast comes (no `furyBlast`, `Blasts` 0); `VFKit` reads `X0/8`,
  without `fury`. Once `X8/8`'s back, the same, but press Q (8192, then clear it) as it charges: the
  Shock Bolt's bow comes up in its place (`VFKit` ends in `equip`), and no blast comes; press Q to
  put it away. Once `X8/8`'s back, press X, wait until X's note reads 0.6, and fire: the lower bar
  fills a little over half way, and as the note reaches 0 the bow goes with no blast.
- **HF7 Through walls.** Walk to the wallbang lane's 10 m line, in front of the concrete 0.10 m wall
  (`pos` within 0.2 m of `-26.00 0.00 -10.00`, `VFTestYaw` 0, `VFTestPitch` 0), press X, and fire
  once it's drawn: the band runs through the wall and the backstop behind it, and `VFFuryHits` reads
  `Dummy 10 (static),Dummy 11 (static),Dummy 12 (static)`: Dummy 11, 1.5 m behind the wall in front
  of you, and the two 2 m either side of it, behind theirs, each `70 + 0`; Dummy 9 and Dummy 13, 4 m
  either side, are untouched.
- **HF8 Its reach.** Walk back to the target lane, 17 m behind the spawn (`pos` about
  `0.00 0.00 17.00`, `VFTestYaw` 0), press X, and fire once it's drawn: `VFFuryHits` reads `Dummy 1
  (static),Dummy 3 (crouch),Dummy 4 (static)`, 27 m to 47 m away; Dummy 6, 67 m away, is past its
  66 m, and its label doesn't change. Press F2 to close the Sound Lab.

Then three players: stop the game and start a Local Server with 3 players, as in section 9. In
window 1 play as Sova, as before, and open the Sound Lab in windows 2 and 3.

- **HF9 Seen, heard and caught.** Player 1 stands at the spawn facing down the target lane
  (`VFTestYaw` 0, `VFTestPitch` 0), player 2 down it at `pos` about `0.00 0.00 -25.00`, and player 3
  3 m to player 1's left (`pos` about `-3.00 0.00 0.00`). In window 1 press X: windows 2 and 3 log
  `furyCast`. Once X's note shows its seconds, fire: windows 2 and 3 log `furyCharge`, and in
  window 3 a ball of light grows in front of player 1 for 1 s (`Charge` in `Workspace.VFFury`). Then
  all three log `furyBlast`, and windows 2 and 3 show the band from player 1 down the lane, in the
  enemy colour; window 2's screen flashes white for a moment, and its HUD reads `70` and `+0`, while
  window 3's still reads `100` and `+50`. Window 1's `VFFuryHits` reads `Dummy 1 (static),Dummy 3
  (crouch),Dummy 4 (static),Dummy 6 (static),Player2`, and in window 1 player 2 lights up red
  through anything in the way for 1 s (`Reveal_4294967294`), but not in window 3 (`Revealed` 0):
  with no sides on the course, whom it reveals is its owner's alone. **Send:** a screenshot of
  window 3 as the band goes.

Then Skirmish: press P in window 1. Players 1 and 3 share a side, as in F1. As round 1's buy phase
starts, agent select comes up by itself: pick SOVA and LOCK IN in window 1, and LOCK IN in windows 2
and 3. In Studio, setting `VFTestGive` to `ultimate` fills the ultimate's points.

- **HF10 The buy phase.** In round 1's buy phase set `VFTestGive` to `ultimate` in window 1: X's
  eight pips light, and `VFKit` reads `X8/8`. Set window 1's `VFTestAimPoint` to window 2's `pos`,
  1 m up, press X, and fire once it's drawn: windows 1 and 3 log `furyBlast`, and window 2 logs it
  as `not heard: buy phase`; the band runs through the barriers toward player 2, but `VFFuryHits` is
  empty, window 2's health doesn't change, and nobody lights up red. Clear `VFTestAimPoint`.
- **HF11 Friend and foe.** Once the round's live, player 2 goes behind cover, out of sight of
  players 1 and 3, and player 3 stands in the open between them, on the line from player 1 to
  player 2 and at least 5 m from each. Set `VFTestGive` to `ultimate` in window 1 again, set its
  `VFTestAimPoint` to window 2's `pos`, 1 m up, press X, and fire once it's drawn: window 2 takes
  80, its health and shield together, and its screen flashes white, and window 3 takes nothing,
  though the band runs through player 3; window 1's `VFFuryHits` reads `Player2`. For 1 s player 2
  lights up red through the cover in windows 1 and 3 (`Reveal_4294967294`), and a red dot shows them
  on both their minimaps, then a `?` where they were (`VFMinimap`'s `Seen` reads `4294967294` while
  it lasts); nobody lights up in window 2. Clear `VFTestAimPoint`. **Send:** a screenshot of
  window 3 as player 2 lights up, with its minimap.

## 51. Sova's Owl Drone

From [47-owl-drone.md](research/47-owl-drone.md). One player on the course, then three there, in
Skirmish and in the spike rounds. Play as Sova, as in section 48. Without keys or a mouse button,
`VFTestButtons` 4096 presses C, 128 the left button, 1 W, 64 jump and 32 crouch: set it and clear it
again each time, and leave a button set for as long as it's held. `VFTestYaw` and `VFTestPitch` aim,
in degrees: positive yaw turns left, and positive pitch looks up; while you fly the drone they turn
its view. A Vector3 `VFTestAimPoint`, in metres, aims at that place, and `VFTestAimEntity` at that
entity's body (Dummy 1's id is 4294901761, and Dummy 11's 4294901771), until it's cleared; while you
fly they aim from the drone's middle, where its darts go from. The F3 panel's `pos` line is where
you stand, in metres. While you fly it, your `VFDroneId` attribute is the id the snapshots give it
and `VFDroneHealth` the health it has left; `VFLastDart` is where your last dart ended, in metres,
and `VFDartHit` whom it struck, a name, or nothing. PlayerGui's `VFDrone` carries `Flying` (whether
you fly it), `Left` (the seconds it has left), `DartIn` (the seconds until a dart can go),
`TargetHit` (whether `[Target Hit]` shows), `Tagged` (whether a dart's pings are on you) and
`Drones` (the drones drawn), and `Workspace.VFDrone` holds every drone you have but your own
(`Drone_` and its id), your body while you fly (`Body`), each dart's streak (`Dart`) and each
burst's pieces (`Shard`). Whom a ping reveals lights up as a Recon Bolt's pulse does (section 48:
`VFRecon`'s `Revealed`, and `Reveal_` and the entity's id in `Workspace.VFRecon`). On the course a
spent charge comes back 1.5 s after it's spent. Start each check at the spawn facing down the target
lane (`VFTestYaw` 0, `VFTestPitch` 0), with the Vandal in hand.

- **OD1 His kit.** In agent select (T), click SOVA's card: C OWL DRONE is lit now, with `C readies a
  drone, and fire sends it out for you to fly for 7 s, or until C again. Fire from it shoots darts
  that reveal whoever they strike.`, and nothing on it reads `NOT YET`. Click PICK SOVA and close it
  with T. On the ability bar OWL DRONE has its one pip lit, and `VFKit` reads `C1/1 Q2/2 E1/1 X8/8`.
  Press B: under the shields Owl Drone (`C`, 400) has its pip lit and reads `FULL`. Hover it:
  `Ability, on C`, the line on his card, and its rows, `Charges` up to 1, `A charge` 400 credits,
  `Flight` `7 s, 100 health` and `A dart` `every 5 s, 2 pings`. Close the menu (B). **Send:** a
  screenshot of the hover.
- **OD2 In hand.** Open the Sound Lab (F2 four times), and keep it open to OD9. Press C: a quick
  mechanical clatter, logged as `droneEquip`, `yours`; the Vandal goes, and the drone comes up over
  your open hand: a squat dark body with a light blue lens at its front and an arm out to either
  side, each with a light blue rotor. C's square lights, with `EQUIP` under it for 0.9 s; the HUD
  reads `Owl Drone   [C]`, with no ammo; and `VFKit` ends in `equip`. Press C again: the drone goes,
  the Vandal's back, and `VFKit` reads `C1/1 Q2/2 E1/1 X8/8`, nothing spent.
- **OD3 Sent out.** Press C, and once `EQUIP`'s gone set `VFTestButtons` to 128 and clear it at
  once: a thick, quick whoosh, logged as `droneLaunch`, `yours`; the drone in hand goes, and the
  view leaves your eye and glides about 1.8 m down the lane, stopping half a second after the click.
  Round the screen's edges is a light blue tint, the crosshair's green, and under it are two light
  blue bars (`VFDrone`'s `Flying` true): the upper one full, emptying as the seconds run down
  (`Left`, from 7), and the lower one empty for a quarter of a second, then full (`DartIn` 0). A
  quiet, high whir is logged as `droneHum`, `you`, every 0.4 s. `VFDroneId` reads 4294836225, the
  first drone sent out since the game started, and `VFDroneHealth` 100; `pos` still reads
  `0.00 0.00 0.00`. C's square is lit with the seconds left under it, from `7.0` down, and `VFKit`
  reads `C0/1 Q2/2 E1/1 X8/8 drone` and the same seconds; 1.5 s after the click C's pip lights
  again, `C1/1`. Set `VFTestYaw` to 180: the view turns round, and there's your body standing at the
  spawn, facing you, in your side's blue (`Body` in `Workspace.VFDrone`). Set it back to 0. As C's
  note reaches 0 the view's back at your eye, facing down the lane, and the tint, the bars and the
  whir are gone (`Flying` false, and no `VFDroneId`); the Vandal comes up, ready 0.7 s later.
  **Send:** a screenshot while it flies.
- **OD4 Along the ground.** Press C, and once `EQUIP`'s gone set `VFTestButtons` to 129 (W and the
  left button), then at once to 1, and keep it: the drone flies straight down the lane at 5 m/s, a
  metre every fifth of a second, through Dummy 1 without stopping, and reaches the 20 m stripe as
  `Left` reads 3.0. Just then set `VFTestPitch` to -89, and `VFTestButtons` to 129 and back to 1: a
  thin, quick swish, logged as `droneDart`, `you`, and a thin blue streak from just under the view
  down to the floor; `VFLastDart` reads about `0, 0, -20`, and `VFDartHit` is empty. Set
  `VFTestPitch` back to 0. It flies on through Dummy 4, and as its time's up, nearly 35 m down the
  lane, the view's back at your eye at the spawn; `pos` read `0.00 0.00 0.00` all along.
- **OD5 Up and down.** Send it out (C, then 128 once `EQUIP`'s gone), and once it's stopped set
  `VFTestButtons` to 64 (jump) and keep it: the view rises at 3 m/s and, about half a second later,
  stops 3 m over the floor. Clear it, set `VFTestPitch` to 89 and fire a dart (128, then clear it):
  `VFLastDart` reads about `0, 42.99, -2.51`, its 40 m straight up from 3 m. Set `VFTestPitch` back
  to 0 and press C to end it. Once C's lit again, send it out again, and once it's stopped set
  `VFTestButtons` to 32 (crouch) and keep it: the view sinks at 3 m/s until it's just over the
  floor, and stays there. Clear it, set `VFTestPitch` to 89 and fire a dart: `VFLastDart` reads
  about `0, 40.12, -2.51`, 40 m up from 0.12 m. Set `VFTestPitch` back to 0 and press C to end it.
- **OD6 A dart.** Send it out, and once it's stopped set `VFTestAimEntity` to 4294901761, Dummy 1,
  and fire a dart (128, then clear it): `droneDart`, `you`, and a thin blue streak from just under
  the view to Dummy 1's middle. At once `[Target Hit]` shows in light blue under the bars, with a
  sharp metallic bite, logged as `dartHit`, `yours`, and goes 2 s later (`TargetHit`). `VFLastDart`
  reads about `0, 1.18, -9.86` and `VFDartHit` `Dummy 1 (static)`, and Dummy 1's label still reads
  `100 + 50`: a dart does no damage. The lower bar empties and fills again over 5 s, dim until it's
  full (`DartIn` counting down from 5); fire again at once, and nothing's fired or heard. 1.6 s
  after the dart a high bell, logged as `dartPing`, `you`, about 8 m away, and Dummy 1 lights up red
  for 0.6 s (`Reveal_4294901761`, `Revealed` 1); 1.2 s after that, again; then no more. Clear
  `VFTestAimEntity`, and press C to end it. **Send:** a screenshot with `[Target Hit]` showing.
- **OD7 Out of reach, and walls.** Once C's lit again, send it out, and once it's stopped set
  `VFTestYaw` to 10 and fire a dart: the streak runs 40 m down the lane, passing left of Dummy 3,
  and ends in the air, `VFLastDart` about `-6.95, 1.62, -41.21`, and `VFDartHit` is empty. Set
  `VFTestYaw` back to 0 and press C to end it. Walk to the wallbang lane's 10 m line, in front of
  the concrete 0.10 m wall (`pos` within 0.2 m of `-26.00 0.00 -10.00`, `VFTestYaw` 0), and send it
  out: it stops 1.8 m on. Set `VFTestAimEntity` to 4294901771, Dummy 11, 1.5 m behind the wall, and
  fire a dart: the streak ends on the wall's face, `VFLastDart` about `-26, 1.24, -20`, `VFDartHit`
  is empty, and nobody lights up. Clear `VFTestAimEntity`, and press C to end it.
- **OD8 Walls.** Still on the 10 m line, once C's lit again send it out and set `VFTestButtons` to 1
  (W) and keep it: the drone flies to the wall and stops against it about 2 s after the launch, the
  wall filling the view. Set it to 65 (W and jump) and keep it: the drone rises over the wall's top,
  on over the dummies behind it, and stops against the backstop behind them, 3 m over the floor,
  less than 2 s later. Clear it, set `VFTestPitch` to -89 and fire a dart: `VFLastDart` reads about
  `-26, 0, -23.85`, the floor between Dummy 11 and the backstop. Set `VFTestPitch` back to 0 and
  press C to end it.
- **OD9 Cut short.** Walk back to the spawn. Once C's lit again, send it out, set `VFTestAimEntity`
  to 4294901761, fire a dart, and at once press C (4096, then clear it): the view's back at your eye
  straight away, the tint and the bars gone and `VFKit` without `drone`, and the Vandal comes up,
  ready 0.7 s later. `[Target Hit]` stays up for its 2 s, and Dummy 1 still lights up 1.6 s and
  2.8 s after the dart. Clear `VFTestAimEntity`, and press F2 to close the Sound Lab.

Then three players: stop the game and start a Local Server with 3 players, as in section 9. In
window 1 play as Sova, as before, and open the Sound Lab in windows 2 and 3. Player 1's id is
4294967295, player 2's 4294967294 and player 3's 4294967293.

- **OD10 Seen and heard.** Player 1 stands at the spawn facing down the target lane (`VFTestYaw` 0,
  `VFTestPitch` 0), player 2 down it to the left, 12 m on (`pos` about `-4.00 0.00 -12.00`), and
  player 3 4 m to player 1's right (`pos` about `4.00 0.00 0.00`). In window 1 press C and send the
  drone out: windows 2 and 3 log `droneLaunch`, `Player1`, and see the drone come out of player 1's
  head and stop 1.8 m in front of them, a small dark box, its lens at its front and a spinning rotor
  to either side in the enemy colour (`Drone_4294836225` in `Workspace.VFDrone`, and `VFDrone`'s
  `Drones` 1), its whir logged every 0.4 s as `droneHum`, `Player1`; player 1 stands still at the
  spawn. Window 1's `Drones` reads 0: your own isn't drawn. In window 1 hold W (1) for a second:
  windows 2 and 3 see the drone fly smoothly down the lane and stop. Press C in window 1 to end it:
  it's gone from windows 2 and 3 (`Drones` 0). **Send:** a screenshot of window 3 with the drone in
  view.
- **OD11 Tagged.** Once C's lit again in window 1, send it out, and once it's stopped set
  `VFTestAimEntity` to 4294967294, player 2, and fire a dart: windows 2 and 3 log `droneDart`,
  `Player1`, and see a thin streak in the enemy colour run from the drone to player 2. Window 1
  shows `[Target Hit]`, and its `VFDartHit` reads `Player2`. Window 2 hears a sharp metallic bite,
  `dartHit`, `yours`, and `TAGGED` shows at the top of its screen in the enemy colour for 3.4 s
  (`VFDrone`'s `Tagged` true), with a high bell, `dartPing`, `yours`, 1.6 s after the dart and again
  1.2 s later. At each, in window 1 player 2 lights up red for 0.6 s (`Reveal_4294967294`), but not
  in window 3 (`Revealed` 0): on the course, whom a dart reveals is its owner's alone. Clear
  `VFTestAimEntity`, and press C to end it. **Send:** a screenshot of window 2 with `TAGGED`
  showing.
- **OD12 Shot down.** Once C's lit again in window 1, send it out, and leave it where it stops. In
  window 2 set `VFTestAimPoint` to `0, 1.62, -1.82`, the drone's middle, and fire three single shots
  with the Vandal, half a second apart: each strikes the drone with a spark, and window 1's
  `VFDroneHealth` reads 60, then 20; at the third, 0: a sharp, high crack in all three windows,
  logged as `droneBreak`, and the drone bursts into eight pieces that fly out and fall (`Shard` in
  `Workspace.VFDrone`). Window 1's view is back at player 1's eye at once, the Vandal up 0.7 s
  later, and player 1 is unhurt. Clear `VFTestAimPoint`.

Then Skirmish: press P in window 1. Players 1 and 3 share a side, as in F1. As round 1's buy phase
starts, agent select comes up by itself: pick SOVA and LOCK IN in window 1, and LOCK IN in windows 2
and 3.

- **OD13 Every round.** In round 1's buy phase window 1's `VFKit` reads `C1/1 Q2/2 E1/1 X0/8`. B:
  under the shields Owl Drone (`C`, 400) and Shock Bolt (`Q`, 150) have their pips lit and read
  `FULL`, and there's no Recon Bolt; clicking them buys nothing. Close the menu (B).
- **OD14 Hidden, then seen.** Once the round's live, player 2 stays at their side's spawn, out of
  sight of players 1 and 3 and more than 15 m from them, and player 3 stands beside player 1. In
  window 1 send the drone out the way player 2 is: window 3 draws it in your side's blue (`Drones`
  1) and logs its whir, `droneHum`, `Player1`; window 2 neither draws it (`Drones` 0) nor hears it.
  Fly it toward player 2 (W, and `VFTestYaw` to turn): once it's within 15 m of player 2, or they
  could see it, window 2 draws it in the enemy colour (`Drones` 1) and logs its whir. As soon as
  player 2's in its sight, set window 1's `VFTestAimEntity` to 4294967294 and fire a dart, and
  player 2 then steps behind cover: window 2 reads `TAGGED`; 1.6 s after the dart and 1.2 s after
  that, player 2 lights up red through the cover in windows 1 and 3 for 0.6 s (`Reveal_4294967294`),
  and a red dot shows them on both their minimaps, then a `?` where they were (`VFMinimap`'s `Seen`
  reads `4294967294` while it lasts); nobody lights up in window 2. Window 1's C pip stays dark for
  the rest of the round (`C0/1`). Clear `VFTestAimEntity`. To end the round, player 1 kills
  player 2. **Send:** a screenshot of window 3 as player 2 lights up, with its minimap.
- **OD15 Friend and foe.** In round 2's buy phase window 1's `VFKit` reads `C1/1` again, its pip
  lit. Once the round's live, player 1 stands in the open facing `VFTestYaw` 0, player 3 beside
  them, 3 m to their right, and player 2 where they can see player 1; in windows 2 and 3 set
  `VFTestAimPoint` to player 1's `pos` plus `0, 1.62, -1.82`, where the drone will stop. Window 1
  sends the drone out with no keys. Window 3 fires three single shots, half a second apart: they
  stop at the drone, and window 1's `VFDroneHealth` stays 100. Then window 2 does the same: 60, 20,
  then 0, and the drone bursts in all three windows, logged as `droneBreak`. Clear `VFTestAimPoint`
  in both.

Then the spike rounds: press P three times more in window 1 (the 1v1, gun game, then the spike
rounds), and as round 1's buy phase starts, pick SOVA and LOCK IN in window 1, and LOCK IN in
windows 2 and 3.

- **OD16 Bought.** `VFKit` reads `C0/1 Q0/2 E1/1 X0/8`, C's pip dark. B: under the shields Owl Drone
  (`C`, 400) is lit, its pip dark. Click it: 400 credits go, C's pip lights, `VFKit` reads `C1/1`,
  and the tile reads `FULL`; another click buys nothing. Close the menu (B). Once the round's live,
  send it out: `C0/1`, and the pip stays dark for the rest of the round.

## 52. One of each agent on a side

From [48-one-of-each.md](research/48-one-of-each.md). Three players, in Skirmish and then in the
spike rounds; players 1 and 3 share a side in both, as in F1. Everyone plays Jett as the server
starts, and agent select comes up by itself as each match's window opens, as in section 33: your
player's `VFAgent` is the agent you play, `VFAgentSelected` what you've selected and `VFAgentPick`
where you stand. A window lasts 10 s. Without a mouse, `VFTestAgents` set to true opens agent
select, and `VFTestAgent` set to an agent's id selects it as a click on its card would, or set to
`lock` locks in. Someone moved across to even the sides, and someone back in a match to find their
agent taken, are the offline tests'.

Start a Local Server with 3 players, as in section 9, and press P once in window 1 (Skirmish).

- **OE1 Nothing's taken yet.** As round 1's buy phase starts, agent select comes up by itself in all
  three windows, every card lit and none reading `TAKEN`. Click SOVA in window 1 and then in
  window 3: in both, SOVA's card is outlined in gold, and both players' `VFAgentSelected` read
  `sova`. Window 1's `YOUR TEAM` reads `PLAYER3` with `SOVA`, dimmed, and `SELECTING`.
- **OE2 Taken.** Click LOCK IN in window 1: window 1's screen goes, and player 1's `VFAgent` reads
  `sova`. At once in window 3, SOVA's card dims and reads `TAKEN` in grey, the gold outline goes
  back to JETT's card, tagged `YOURS`, and `VFAgentSelected` reads `jett`; under `YOUR TEAM`,
  `PLAYER1` reads `SOVA` and `LOCKED IN` in gold. Put the cursor on SOVA's card: it doesn't light,
  and under the button is `SOVA is taken: a teammate has locked it in`. Click it: nothing changes,
  and `VFAgentSelected` still reads `jett`. **Send:** a screenshot of window 3's screen with the
  cursor on SOVA.
- **OE3 The other side.** In window 2 no card reads `TAKEN`: click SOVA and LOCK IN. Window 2's
  screen goes, and player 2's `VFAgent` reads `sova`, as player 1's does.
- **OE4 The time running out.** Leave window 3 alone: 10 s after the buy phase started its screen
  goes by itself, and player 3's `VFAgent` reads `jett` and `VFAgentPick` `locked`. T in window 1
  shows `PLAYER3` with `JETT` and `LOCKED IN`, and JETT's card reads `TAKEN`.

Then the spike rounds: press P three times more in window 1 (the 1v1, gun game, then the spike
rounds).

- **OE5 At once.** As round 1's buy phase starts, agent select comes up by itself in all three
  windows: window 1's on SOVA, window 3's on JETT, and no card reads `TAKEN`. Click OMEN in
  windows 1 and 3, and lock in neither. 10 s after the buy phase started both screens go by
  themselves: player 1, first on the server, plays Omen (`VFAgent` reads `omen`), and player 3 is
  back on Jett (`jett`), their selection moved off Omen as player 1's window locked it in.
  Window 1's `VFKit` reads `C0/2 Q0/1 E1/2 X0/7`, as in DC11.

## 53. Ultimate Orbs

From [49-ultimate-orbs.md](research/49-ultimate-orbs.md). Two players in the spike rounds, with the
HUD on (F3) and the Sound Lab open (F2 four times) in both windows. Workspace's `VFOrbs` is which
orbs are up, by number (`1,2`), and `Workspace.VFUltimateOrbs` holds each orb (`UltimateOrb1`,
`UltimateOrb2`) and the disc under it (`UltimateOrb1Mark`, `UltimateOrb2Mark`). In metres, Outpost's
orbs are at (-177.5, 0, 10) and (-122.5, 0, 10), Quarry's at (-343, 0, -3) and (-263, 0, -5), and
Foundry's at (-493, 0, 1) and (-415, 0, -3): orb 1 on the A side and orb 2 on the B side. A player's
`VFKit` ends with the ultimate's points and what it needs, as `X0/8` for Jett. Without keys,
`VFTestButtons` 65536 holds F (add 1 for W, 64 for Space and 128 for the left button), and
`VFMatchSkip` skips a buy phase or what's left of a round (section 17).

Start a Local Server with 2 players, as in section 9, and press P four times in window 1 (the spike
rounds). As round 1's buy phase starts, agent select comes up by itself: let its 10 s run out in
both windows, so both play Jett. Each round's checks fit in its 100 s; if one runs out first, do
that round's checks again in the next.

- **UO1 Up.** `VFOrbs` reads `1,2`, and `Workspace.VFUltimateOrbs` holds its four parts. In both
  windows the minimap has a small gold dot for each, orb 1 down A main and orb 2 down B main (on
  Foundry, A long and B main), and `VFMinimap`'s `Orbs` reads `1,2`. Player 1 walks over the spike
  in front of them and has it.
- **UO2 The prompt.** Skip the buy phase. Player 1 walks to orb 1, and player 2 comes and stands
  about 5 m from it, facing it. The orb is a glowing gold ball about 0.5 m across, 1 m over a faint
  gold disc 1.2 m across on the floor, with a soft gold light round it. Within about 1.5 m of the
  disc's middle, `HOLD F FOR THE ULTIMATE ORB` shows in gold under player 1's crosshair; 2 m away
  it's gone. **Send:** a screenshot of the orb from a few metres away, and the map's name.
- **UO3 Let go.** Player 1 holds F and the left button at orb 1 (`VFTestButtons` 65664) for about a
  second, then lets go (clears it). While they're held: a whoosh, which window 1's Sound Lab logs as
  `orbGrab`, `yours`, and window 2's as `orbGrab` from player 1 about 5 m away; the gun goes from
  player 1's hands in both windows; a gold bar fills under the crosshair labelled
  `TAKING THE ULTIMATE ORB`; the HUD's spike line adds `taking an orb` and how far along it is; and
  nothing fires: the Classic's count stays at 12. As they're let go the bar goes at once, with no
  chime, the gun comes back over its draw, `VFOrbs` still reads `1,2`, and `VFKit` still ends
  `X0/8`.
- **UO4 Taken.** Player 1 holds F, W and Space (`VFTestButtons` 65601): the bar starts from empty,
  with another whoosh logged in both windows, and they neither move nor jump, though `VFTestYaw`
  still turns the view. 2 s later a chime, which window 1's Sound Lab logs as `orbTaken`, `yours`,
  and window 2's doesn't log at all; the bar goes, the gun comes back over its draw, and orb 1's
  ball and light go while its disc stays. `VFOrbs` reads `2`, orb 1's dot goes from both minimaps
  (`Orbs` reads `2`), and a moment later player 1's `VFKit` ends `X1/8`, one pip lit on the ability
  bar's X. From then W and Space move them again: clear `VFTestButtons`. **Send:** how long the bar
  took, if you timed it.
- **UO5 Gone.** Player 2 stands on orb 1's disc and holds F (`VFTestButtons` 65536 in window 2): no
  prompt, no bar, no whoosh, and the Classic stays in their hands. Clear it, and skip what's left of
  round 1: the defenders win it.
- **UO6 The next round.** As round 2's buy phase starts, `VFOrbs` reads `1,2` again, both dots are
  back on the minimaps, and `UltimateOrb1`'s Transparency is 0 again. Player 1's `VFKit` still ends
  `X1/8`.
- **UO7 F defuses.** Skip the buy phase. Player 1 picks up the spike in front of them, takes it to
  site A and plants it (section 17). Player 2 holds F by it (`VFTestButtons` 65536): the Classic
  goes, the cyan `DEFUSING` bar fills, and 7 s later player 2's screen shows `ROUND WON` with
  `Spike defused`. Clear `VFTestButtons`.
- **UO8 Full.** Skip round 3's buy phase. Set `VFTestGive` to `ultimate` in window 2: player 2's
  `VFKit` ends `X8/8`. Player 2 walks to orb 2 and holds F for 2 s: the chime, `VFOrbs` reads `1`,
  and `VFKit` still ends `X8/8`.
- **UO9 Over.** Press P in window 1: the spike rounds in Swiftplay's format, a new match on one of
  the three maps, and as its round 1 starts `VFOrbs` reads `1,2`, the orbs on that map's places.
  Press P again, for off: `VFOrbs` is gone and `Workspace.VFUltimateOrbs` is empty.

## 54. The ultimate's points across a match

From [50-ultimate-points.md](research/50-ultimate-points.md). Two players in the spike rounds, in
Swiftplay's format and then the standard one, then three. A player's `VFKit` ends with the
ultimate's points and what it needs, as `X2/8` for Sova and `X2/7` for Sage, and the ability bar's X
has a pip for each point it needs, lit for each it has, in gold once it's full. `VFTestGive` set to
`ultimate` fills the points, and `VFTestAgent` set to an agent's id selects it, or set to `lock`
locks in (section 52). `VFMatchSkip` skips a buy phase, what's left of a round, which the defenders
win, or the wait after it (section 17), but never a planted spike's countdown. In Swiftplay the
sides swap after round 4, and a 4-4 score goes to a sudden death in round 9; in the standard format,
after round 12, and 12-12 to round 25. Sova's Shock Bolt goes as in section 49: `VFTestButtons` 8192
presses Q and 128 the left button, `VFTestPitch` -90 looks at your feet, and a Vector3
`VFTestAimPoint`, in metres, aims at that place until it's cleared. `VFTestBuy` set to `shockbolt`
buys a charge of it, as a click in the buy menu would.

Start a Local Server with 2 players, as in section 9, and press P five times in window 1 (Skirmish,
the 1v1, gun game, the spike rounds, then the spike rounds in Swiftplay's format). Player 1 attacks
the first half, with the spike in front of them, and player 2 defends.

- **UP1 Swiftplay's two.** As round 1's buy phase starts, agent select comes up by itself in both
  windows. Click SOVA and LOCK IN in window 1, and SAGE and LOCK IN in window 2 (or set
  `VFTestAgent` to the agent's id and then to `lock`). Player 1's `VFKit` ends `X2/8`, two of the
  X's eight pips lit, and player 2's `X2/7`: each kit started over for its agent, still with the two
  points the match started on.
- **UP2 A death's point waits.** Skip the buy phase. Player 2 kills player 1 with the Classic: at
  once player 2's `VFKit` ends `X3/7`, while player 1's stays at `X2/8`, and player 2's side wins
  the round. As round 2's buy phase starts, player 1's ends `X3/8`, and player 2's is still `X3/7`.
- **UP3 Not the spike's.** Skip the buy phase. Player 1 picks up the spike in front of them, takes
  it to site A and plants it (section 17): their `VFKit` ends `X4/8` at once. Player 1 stays beside
  it, and player 2 leaves it alone. 45 s later it goes off: player 1's screen shows `ROUND WON` with
  `Spike detonated`, and the blast kills player 1. As round 3's buy phase starts, player 1's `VFKit`
  still ends `X4/8`, and player 2's `X3/7`.
- **UP4 Not your own.** In round 3's buy phase player 1 buys two Shock Bolts: `VFKit` reads `Q2/2`.
  Skip the buy phase. Player 1 sets `VFTestPitch` to -90 and looses a Shock Bolt at their feet, as
  in SB6: their HUD reads `25`. Once the gun's back, the second: it kills them, and the round goes
  to player 2's side. Player 1's `VFKit` still ends `X4/8`, and as round 4's buy phase starts it
  still does; player 2's ends `X3/7`.
- **UP5 The half.** Round 4's buy phase line adds `LAST ROUND OF THE HALF`. Set `VFTestGive` to
  `ultimate` in window 1: player 1's `VFKit` ends `X8/8`, every pip lit in gold. Skip the buy phase,
  and player 2 kills player 1, who neither shoots back nor uses the ultimate: player 2's `VFKit`
  ends `X4/7`. As round 5's buy phase starts, with the sides swapped, player 1's ends `X2/8`, the
  full ultimate and the death's point both gone, and player 2's `X2/7`.
- **UP6 Sudden death.** Skip rounds 5, 6 and 7, the buy phase and then the round each time:
  player 1's side defends now and wins each, to 4-3. In round 8's buy phase set `VFTestGive` to
  `ultimate` in window 1 (`X8/8`). Skip the buy phase, and player 2 kills player 1, who doesn't
  shoot back: player 2's `VFKit` ends `X3/7`, and it's 4-4. Round 9's buy phase line adds
  `SUDDEN DEATH`, and player 1's `VFKit` ends `X5/8`, three short of full and down from 8, and
  player 2's `X4/7`, up from 3.
- **UP7 The standard format.** Press P in window 1 for off, then four more times (Skirmish, the 1v1,
  gun game, the spike rounds), and let round 1's agent select run out in both windows: player 1's
  `VFKit` ends `X0/8`. Set `VFTestGive` to `ultimate` in window 1 (`X8/8`), then in the server's
  command bar run this, which skips to round 13's buy phase, the defenders winning every round.
  There player 1's `VFKit` ends `X0/8`.

  ```lua
  for _ = 1, 80 do
  	if workspace.VFArena:GetAttribute("Round") == 13 then break end
  	workspace:SetAttribute("VFMatchSkip", true)
  	task.wait(0.3)
  end
  ```

- **UP8 Its sudden death.** Run it again with 25 in place of 13. At 12-12 round 25's buy phase line
  adds `SUDDEN DEATH`, and player 1's `VFKit` ends `X5/8`.

Then three players: stop the game and start a Local Server with 3 players, as in section 9, and
press P four times in window 1 (the spike rounds). Players 1 and 3 share a side, as in section 52,
and attack first. As round 1's buy phase starts, agent select comes up by itself: click SOVA and
LOCK IN in window 1, and let the other windows' 10 s run out.

- **UP9 A teammate's.** In the buy phase player 1 buys two Shock Bolts (`Q2/2`). Skip the buy phase.
  Player 3 stands still about 8 m in front of player 1, who sets `VFTestAimPoint` to player 3's feet
  (their `pos` in window 3's F3 panel) and looses both Shock Bolts at them, one after the other, as
  in SB4: the first leaves player 3 on `25`, and the second kills them. Player 1's `VFKit` still
  ends `X0/8`, with no kill's point, and player 3's `X0/8`. Clear `VFTestAimPoint`, and skip what's
  left of round 1: as round 2's buy phase starts, player 3's `VFKit` still ends `X0/8`.

## 55. Agents and ultimates at a glance

From [51-at-a-glance.md](research/51-at-a-glance.md). Three players in the spike rounds, then in gun
game. Each tile beside the top bar's score has its player's agent by the first two letters of its
name (`JE` Jett, `PH` Phoenix, `SA` Sage, `OM` Omen, `SO` Sova), or in gun game the first two
letters of the player's name. Under your side's tiles is a white bar as full as each one's health,
and under anyone's a gold diamond while their ultimate's ready. PlayerGui's `VFArenaHud` carries
`Yours` and `Theirs`, the tiles in the order of the players' names: each tile's letters, then its
health where it's shown, `dead` and `ready` (`SO 100 ready, JE 74`). The scoreboard has a box with
each player's agent before their name, and under `ULT` their ultimate's points and what it needs
(`3/8`), or `READY` in gold. While it's open, PlayerGui's `VFScoreboard` carries `Ult`, its rows in
order (`SO Player1 READY, JE Player3 0/8`). `VFTestBoard` set to true holds the scoreboard open as
Tab does, and false lets it go. `VFTestGive` set to `ultimate` fills the points, and `VFTestAgent`
set to an agent's id selects it, or set to `lock` locks in (section 52). `VFMatchSkip` set true on
Workspace skips a buy phase, or what's left of a round, which the defenders win (section 17).

Start a Local Server with 3 players, as in section 9, and press P four times in window 1 (Skirmish,
the 1v1, gun game, then the spike rounds). Players 1 and 3 share a side, as in section 52, and
attack first, and player 2 defends. As round 1's buy phase starts, agent select comes up by itself:
click SOVA and LOCK IN in window 1, and SAGE and LOCK IN in window 2 (or set `VFTestAgent` to the
agent's id and then to `lock`), and let window 3's 10 s run out, on Jett.

- **GA1 The top bar.** Once agent select has gone in every window, window 1's top bar has `SO` and
  `JE` left of the score, in your side's colour, each with a full white bar under it, and `SA` right
  of it, in the other side's colour, with no bar. Window 1's `VFArenaHud`: `Yours` reads
  `SO 100, JE 100` and `Theirs` `SA`. Window 2's: `Yours` reads `SA 100` and `Theirs` `SO, JE`.
- **GA2 The scoreboard.** Set `VFTestBoard` to true in window 1 (or hold Tab). Each row starts with
  a box in its side's colour with the agent's letters: `SO` for Player1 and `JE` for Player3 in your
  side's table, and `SA` for Player2 in the other. Under `ULT`, Player1 and Player3 have `0/8` and
  Player2 `0/7`. `VFScoreboard`'s `Ult` reads `SO Player1 0/8, JE Player3 0/8, SA Player2 0/7`. Set
  `VFTestBoard` to false: `Ult` is gone.
- **GA3 Ready.** Set `VFTestGive` to `ultimate` in window 1: a gold diamond comes up under `SO`, and
  window 1's `Yours` reads `SO 100 ready, JE 100`. In window 2 a gold diamond is under `SO` too, and
  `Theirs` reads `SO ready, JE`. Set `VFTestBoard` to true in window 2: Player1's `ULT` reads
  `READY` in gold, and `Ult` reads `SA Player2 0/7, SO Player1 READY, JE Player3 0/8`. Set
  `VFTestBoard` to false.
- **GA4 Health.** Skip the buy phase. Player 2 shoots player 3 once in the body with the Classic,
  from within 30 m: in window 1 `JE`'s bar drops to about three quarters, and `Yours` reads
  `SO 100 ready, JE 74` (78 for a leg, 22 for the head); in window 2 `Theirs` still reads
  `SO ready, JE`, with no bars. Player 2 then kills player 3: in window 1 `JE`'s tile dims and its
  bar empties, `Yours` reading `SO 100 ready, JE 0 dead`, and in window 2 `Theirs` reads
  `SO ready, JE dead`. Set `VFTestBoard` to true in window 2: Player3's row and box are dimmed, and
  `Ult` reads `SA Player2 1/7, SO Player1 READY, JE Player3 0/8`, Player2's `1/7` the kill's point.
  Set `VFTestBoard` to false.
- **GA5 The victory screen.** In the server's command bar run this, which skips to the end of the
  match, the defenders winning every round from here. As it ends, the scoreboard comes up by itself
  in every window with `MAP VOTE IN 10` under it: each row still has its agent's box, but there's no
  `ULT` column, nor its title, and `VFScoreboard` has no `Ult`.

  ```lua
  for _ = 1, 150 do
  	if workspace.VFArena:GetAttribute("Phase") == "matchOver" then break end
  	workspace:SetAttribute("VFMatchSkip", true)
  	task.wait(0.3)
  end
  ```

- **GA6 Gun game.** Press P five times in window 1 (the spike rounds in Swiftplay's format, off,
  Skirmish, the 1v1, then gun game). Every tile beside the score reads `PL`, the first two letters
  of the players' names, and none has a diamond, though your side's still have their health bars:
  `Yours` lists a `PL 100` for each player on your side, and `Theirs` a `PL` for each on the other.
  Set `VFTestBoard` to true: no row has a box before its name, there's no `ULT` column, and
  `VFScoreboard` has no `Ult`. Set `VFTestBoard` to false.

## 56. Pings

From [52-pings.md](research/52-pings.md). One player on the course, then three in Skirmish.
PlayerGui's `VFPings` carries `Shown`, the markers on the screen in the order they came, each as its
word and how far away it is in whole metres (`HERE 3m, ENEMY 10m`); `Left`, the pings you have left,
whole; `Wheel`, empty while the wheel's shut, `open` while it's up, or the call picked; and
`Cursor`, where the big map's cursor is while it's up to ping on, in metres. The wheel is the
`VFPingWheel` ScreenGui. `VFMinimap` carries `Pings`, the pings on the minimap by what they mark
(`place`, `enemy`, `spike`, `gun`, a call's id, or `map` for one made on the map), and their icons
are `Ping_` and a number. Without Z or the mouse, a string attribute `VFTestPing` set to `tap` pings
as tapping Z does; to `danger`, `watching`, `pushing` or `help` as letting Z go with that call
picked does; to `wheel` opens the wheel as holding Z does; to `shut` puts it away as the right
button does; and to `map` pings as the left button does on the big map, where its cursor is. It
clears itself; set from the server's command bar, clear it there too before setting it again.
`VFTestMap` holds the big map up as Caps Lock does, and `VFTestMapPoint`, a Vector3 in metres, puts
its cursor nearest that place (section 47). `VFTestYaw` and `VFTestPitch` aim, in degrees: positive
yaw turns left, and positive pitch looks up. `VFTestAimEntity` aims at an entity, and wins over them
until it's cleared. A ping shows for 4 s, fading over its last half second, and you have four, each
back 1.5 s after it's spent.

Press Play (F5), with one player, as Jett (her card in agent select, T, if you've picked another).
Open the Sound Lab (F2 four times), and keep it open to PI7. Start at the spawn facing down the
target lane (`VFTestYaw` 0), with the Vandal in hand. Dummy 1, the static dummy on the 10 m stripe,
is 4294901761.

- **PI1 A place.** Look down at the floor (`VFTestPitch` -30) and tap Z (or set `VFTestPing` to
  `tap`): a short, high beep, logged as `ping`, `yours`, and on the floor about 3 m ahead, under the
  crosshair, a small pale yellow diamond with a dark edge, `HERE` over it in pale yellow and `3m`
  under it in white, all of it faint, about 70% see-through. `Shown` reads `HERE 3m`, and `Left` 3,
  back to 4 1.5 s later. Look up a little (`VFTestPitch` -20): the marker's under the crosshair no
  longer, and it's solid. 3.5 s after the beep it starts to fade, and by 4 s it's gone, `Shown`
  empty. **Send:** a screenshot of the marker, solid.
- **PI2 The sky, and Dummy 1.** Look up (`VFTestPitch` 30) and tap Z: nothing's marked or heard, but
  `Left` drops by one all the same. Aim at Dummy 1 (`VFTestAimEntity` 4294901761) and tap Z: a beep,
  and a red diamond on Dummy 1's body, `ENEMY` over it in red and `10m` under it; `Shown` reads
  `ENEMY 10m`. Clear `VFTestAimEntity`.
- **PI3 A gun.** Set `VFTestPitch` to 0 and press G (or `VFTestButtons` 2048, then clear it): the
  Vandal lands on the floor about 1.2 m ahead. Look down at it (`VFTestPitch` -50) and tap Z: a
  beep, and a pale yellow diamond on the gun, `VANDAL` over it and `2m` under it; `Shown` reads
  `VANDAL 2m`. Pick it up again (F, or `VFTestTake` true).
- **PI4 The spike.** Turn round to face its tile, 4 m behind the spawn (`VFTestYaw` 180,
  `VFTestPitch` -20), and tap Z: an orange diamond on the spike, `SPIKE` over it in orange and `4m`
  under it; `Shown` reads `SPIKE 4m`.
- **PI5 The wheel.** Turn back down the lane (`VFTestYaw` 0, `VFTestPitch` -30). Hold Z (or set
  `VFTestPing` to `wheel`): a quarter of a second after it goes down, four dark panels come up round
  the middle of the screen, `DANGER` above, `WATCHING` on the right, `PUSHING` below and
  `NEED SUPPORT` on the left, with a white dot in the middle; `Wheel` reads `open`. With the mouse:
  the view doesn't turn, and the dot moves instead, a little way at the most; moved right,
  `WATCHING` lights pale yellow with dark letters, and `Wheel` reads `watching`; the left button
  fires nothing. Click the right button (or set `VFTestPing` to `shut`): the wheel's gone, nothing's
  pinged or heard, and `Wheel` is empty. Hold Z again, move the mouse up and let go (or set
  `VFTestPing` to `danger`): a beep, and on the floor 3 m ahead a pale yellow marker reading
  `DANGER`; `Shown` reads `DANGER 3m`. With the mouse, hold Z, don't move it, and let go: nothing's
  pinged.
- **PI6 The limit.** Once `Left` reads 4, run this in the server's command bar, which taps Z five
  times in under a second and then holds it for the wheel:

  ```lua
  local p = game.Players:GetPlayers()[1]
  for _, what in { "tap", "tap", "tap", "tap", "tap", "wheel" } do
  	p:SetAttribute("VFTestPing", nil)
  	task.wait(0.05)
  	p:SetAttribute("VFTestPing", what)
  	task.wait(0.1)
  end
  ```

  Four beeps, not five, and four markers on the floor 3 m ahead, one on another: `Shown` reads
  `HERE 3m, HERE 3m, HERE 3m, HERE 3m`, and `Left` 0. The wheel comes up greyed, its words and its
  dot grey, and moving the mouse lights nothing, `Wheel` reading `open`. Within 1.5 s `Left` reads 1
  and the wheel's words are white again; `Left` is back to 4 within about 6 s. Set `VFTestPing` to
  `shut`, in the command bar.

- **PI7 A cloud in the way.** Run this in the server's command bar, which throws Cloudburst on the
  floor in front of Dummy 1 (as in Y5) and, a second later, with the cloud whole, pings Dummy 1
  through it:

  ```lua
  local p = game.Players:GetPlayers()[1]
  p:SetAttribute("VFTestPitch", -10)
  task.wait(0.2)
  p:SetAttribute("VFTestButtons", 4096)
  task.wait(0.2)
  p:SetAttribute("VFTestButtons", 0)
  task.wait(1)
  p:SetAttribute("VFTestAimEntity", 4294901761)
  task.wait(0.2)
  p:SetAttribute("VFTestPing", nil)
  task.wait(0.05)
  p:SetAttribute("VFTestPing", "tap")
  ```

  The cloud bursts on the floor about 8.6 m ahead, over Dummy 1, and the ping lands on its near
  edge, not on Dummy 1: a pale yellow `HERE` marker 5 or 6 m away, on the cloud's face, `Shown`
  reading `HERE 5m` or `HERE 6m`. Once the cloud's gone, tap Z again: `ENEMY 10m`. Clear
  `VFTestAimEntity` and `VFTestPing`, and close the Sound Lab.

Then three players: stop the game, start a Local Server with 3 players, as in section 9, and press P
in window 1 (Skirmish). Players 1 and 3 share a side, as in F1. As round 1's buy phase starts, agent
select comes up by itself: LOCK IN in every window. Open the Sound Lab in all three windows. In a
Local Server, player 1's id is 4294967295, player 2's 4294967294 and player 3's 4294967293.

- **PI8 Your side's.** In the buy phase, player 1 looks down at the floor in front of them
  (`VFTestPitch` -30) and taps Z. Windows 1 and 3 log `ping`, and window 2 doesn't. Window 1's
  marker is pale yellow, `Shown` reading `HERE 3m`. On window 1's minimap and on window 3's, a small
  diamond where it is, pale yellow in window 1's and blue in window 3's, and their `VFMinimap`s'
  `Pings` read `place`; window 2's minimap has none, and its `Pings` is empty. Player 3 turns to
  look at it: a blue diamond, `HERE` over it in blue.
- **PI9 The big map takes over.** In window 1, hold Z (or set `VFTestPing` to `wheel`) and, with the
  wheel up, hold Caps Lock (or set `VFTestMap` to true): the wheel goes, nothing pinged and `Wheel`
  empty, as the big map comes up, and on it a white ring with a dot in it, the cursor, in the middle
  of the hall: `Cursor` reads `100, 0, 0`. Tap Z (or set `VFTestPing` to `tap`): nothing's pinged,
  and no wheel comes up. With the mouse: the cursor moves across the map, the view doesn't turn, and
  pushed off the map the cursor stops at its edge. Set `VFTestMapPoint` to `150, 0, 0`: the cursor's
  held at the map's edge, `Cursor` reading `111.5, 0, 0`. Set it to `100, 0, 10`: `Cursor` reads
  `100, 0, 10`.
- **PI10 A ping on the map.** Click the left button (or set `VFTestPing` to `map`): windows 1 and 3
  hear a bright, high ding, logged as `mapPing`, and on their maps, the minimap and window 1's big
  map, a disc ringed in white at the cursor's place, pale yellow in window 1 and blue in window 3;
  window 2 hears and shows nothing. Nothing's in the world: neither window's `Shown` lists it.
  `Pings` reads `map` in windows 1 and 3 and is empty in window 2. With the mouse, the Vandal
  doesn't fire. 4 s after the ding, it's gone. Let go of Caps Lock (or set `VFTestMap` to false):
  the cursor's gone, and `Cursor` too. **Send:** a screenshot of window 3's minimap with the ping.
- **PI11 An enemy.** Skip the buy phase if it's still on (`VFMatchSkip`, in the server's command
  bar). Once round 1's live, window 1 aims at player 2 (`VFTestAimEntity` 4294967294), with nothing
  between them, and taps Z: a beep in windows 1 and 3, and none in window 2. In window 1, a red
  diamond on player 2, `ENEMY` over it in red and how far away they are under it (`Shown` `ENEMY`
  and the metres), and on windows 1's and 3's minimaps a red diamond where they were, `Pings`
  reading `enemy`; window 2's has none. Player 2 walks on: the marker stays where they were. Clear
  `VFTestAimEntity`.
- **PI12 While dead.** Player 2 kills player 1, and window 1 watches player 3. In window 1, tap Z
  (or set `VFTestPing` to `tap`): nothing's pinged, and `Left` doesn't change. Hold Caps Lock (or
  set `VFTestMap` to true): the big map, with the cursor in the hall's middle. Click the left button
  (or set `VFTestPing` to `map`): a ping on the maps in windows 1 and 3, as in PI10, and window 1
  still watches player 3; the click doesn't switch whom you watch.

## 57. The combat report

From [53-combat-report.md](research/53-combat-report.md). One player on the course, then two on the
course and in Skirmish. PlayerGui's `VFCombatReport` carries what the report holds: `Shown` and
`Details`, whether the report and its details are up; `Final`, whether it's a round's last, and
`Round`, its round's number, in the rounds; `Killer`, who killed you and with what
(`Player2, Vandal`), empty if nobody did; `Rows`, its rows in the order they show, each as
`Dummy 1: dealt 40 (1 body), taken 0`, with `, killed` for one you killed and `, killed you` for
whoever killed you, and `; ` between them; and `Totals` (`dealt 40, taken 0`). With no report to
show, only `Shown` and `Details` are there, both false. Without N or mouse 3, a string attribute
`VFTestReport` set to `toggle` shows or hides the report as N does, and to `details` opens or shuts
its details as mouse 3 does. It clears itself; set from the server's command bar, clear it there too
before setting it again. `VFTestAimEntity` aims at an entity and `VFTestAimRegion` at its `head`,
`body` or `legs`, and `VFTestButtons` 128 holds the left button. The shots below are fired from the
server's command bar 0.8 s apart, so each is a first shot. Damage reads in whole points: what each
hit took of health and shield together.

Press Play (F5), with one player, and keep the HUD on (F3). Start at the spawn facing down the
target lane (`VFTestYaw` 0), with the Vandal in hand. Dummy 1, the static dummy on the 10 m stripe,
is 4294901761; like you, it has 100 health and 50 of Heavy Armor.

- **CR1 Nothing yet.** `VFCombatReport`'s `Shown` is false. Press N (or set `VFTestReport` to
  `toggle`): on the right, under the kill feed, a dark panel headed `COMBAT REPORT`, reading
  `NOTHING DEALT OR TAKEN`, and at its foot `DEALT 0   TAKEN 0`, with `N hide   M3 details` on the
  right. `Shown` is true, `Final` false, `Killer` and `Rows` empty, there's no `Round`, and `Totals`
  reads `dealt 0, taken 0`. Press N again: it's gone, and `Shown` is false.
- **CR2 Three in the body.** Run this in the server's command bar, which fires three Vandal shots at
  Dummy 1's body:

  ```lua
  local p = game.Players:GetPlayers()[1]
  p:SetAttribute("VFTestAimRegion", "body")
  p:SetAttribute("VFTestAimEntity", 4294901761)
  for _ = 1, 3 do
  	task.wait(0.6)
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  end
  ```

  No report comes up: nobody's died. Press N: the report, with one row: a red `DU` badge, `Dummy 1`
  in red, and under DEALT `120`, beside a little figure of a head, a body and legs, its body lit
  white with `3` beside it and its head and legs dim with `0`; under TAKEN `0`, its figure all dim.
  `Rows` reads `Dummy 1: dealt 120 (3 body), taken 0`, `Totals` `dealt 120, taken 0`, and the foot
  `DEALT 120   TAKEN 0`. Press N to hide it.

- **CR3 Then the head.** Run this, which fires one at Dummy 1's head:

  ```lua
  local p = game.Players:GetPlayers()[1]
  p:SetAttribute("VFTestAimRegion", "head")
  task.wait(0.6)
  p:SetAttribute("VFTestButtons", 128)
  task.wait(0.2)
  p:SetAttribute("VFTestButtons", 0)
  task.wait(0.2)
  p:SetAttribute("VFTestAimEntity", nil)
  p:SetAttribute("VFTestAimRegion", nil)
  ```

  Dummy 1 dies, the kill feed reading `<your name>   Vandal   Dummy 1`. Press N: under `Dummy 1` its
  row reads `KILLED` in gold, DEALT reads `150`, and the figure's head is lit with `1` and its body
  with `3`. `Rows` reads `Dummy 1: dealt 150 (1 head, 3 body), taken 0, killed`, and `Totals`
  `dealt 150, taken 0`: the head shot took the 30 that were left, not its 160.

- **CR4 The details.** With the report up, press mouse 3 (or set `VFTestReport` to `details`): a
  second panel to the report's left, `WEAPON / ABILITY`, `DAMAGE` and `HITS` along its top, then
  `TO Dummy 1`, then `Vandal` with `150` and `4`. `Details` is true. Mouse 3 again: it shuts, and
  `Details` is false. Press mouse 3 once more, then N: both go. **Send:** a screenshot of the report
  and its details.
- **CR5 The enemy outline colour.** Press I: the dummies' outlines turn purple, and the HUD's `look`
  line reads `look    on (V)   enemy Purple (Tritanopia) (I)`. Press N: the report comes up, its
  `DU` badge and `Dummy 1` purple too, and the outlines stay purple. Press N to hide it, and I three
  times, back to red.

Then two players on the course: stop the game, start a Local Server with 2 players, as in section 9,
and stay on the course, where everyone is everyone else's enemy. In a Local Server, player 1's id is
4294967295 and player 2's 4294967294. Both start with the Vandal in hand. In window 2, walk 5 m to
the left of the spawn (A), so the two of you see each other with nothing between, and window 1 sees
Dummy 1.

- **CR6 Shot dead.** Run this in the server's command bar, which has player 1 fire once at Dummy 1's
  body:

  ```lua
  local p = game.Players.Player1
  p:SetAttribute("VFTestAimRegion", "body")
  p:SetAttribute("VFTestAimEntity", 4294901761)
  task.wait(0.6)
  p:SetAttribute("VFTestButtons", 128)
  task.wait(0.2)
  p:SetAttribute("VFTestButtons", 0)
  task.wait(0.2)
  p:SetAttribute("VFTestAimEntity", nil)
  ```

  Then this, which has player 1 fire once at player 2's body, and then player 2 three times at
  player 1's body and once at their head:

  ```lua
  local p1, p2 = game.Players.Player1, game.Players.Player2
  local function shoot(p, id, region)
  	p:SetAttribute("VFTestAimRegion", region)
  	p:SetAttribute("VFTestAimEntity", id)
  	task.wait(0.6)
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  end
  shoot(p1, 4294967294, "body")
  p1:SetAttribute("VFTestAimEntity", nil)
  for _ = 1, 3 do
  	shoot(p2, 4294967295, "body")
  end
  shoot(p2, 4294967295, "head")
  p2:SetAttribute("VFTestAimEntity", nil)
  ```

  Player 1 dies with the fourth of player 2's shots, both kill feeds reading
  `Player2   Vandal   Player1`. At once, without N, window 1's report comes up on the right: under
  its title, `KILLED BY`, a red `JE` badge (player 2's Jett) and `Player2   Vandal` in red. Then
  player 2's row first, `KILLED YOU` in red under its name, DEALT `40` with the body lit `1`, and
  TAKEN `150` with the head lit `1` and the body `3`; then Dummy 1's, DEALT `40` with the body lit
  `1`, TAKEN `0`. The foot reads `DEALT 80   TAKEN 150`. `Killer` reads `Player2, Vandal`; `Rows`
  `Player2: dealt 40 (1 body), taken 150 (1 head, 3 body), killed you` and
  `Dummy 1: dealt 40 (1 body), taken 0`, `; ` between them, Dummy 1 second though it was hit first;
  and `Totals` `dealt 80, taken 150`. Window 2 shows no report. **Send:** a screenshot of window 1's
  report.

- **CR7 While you're down.** In window 1, press mouse 3: the details read `TO Player2` with `Vandal`
  `40` `1`, `FROM Player2` with `Vandal` `150` `4`, and `TO Dummy 1` with `Vandal` `40` `1`. Press
  N: the report and its details go, and `Shown` is false; N again, and the report's back, without
  its details. As player 1 comes back to life, it goes by itself: `Shown` false and no `Rows`. Press
  N: a new life's report, `NOTHING DEALT OR TAKEN`, with `Killer` and `Rows` empty. Press N to hide
  it.
- **CR8 Only whom you fought.** In window 2, press N: player 2's report, with one row, `Player1`,
  `KILLED` in gold under it, DEALT `150` (head `1`, body `3`) and TAKEN `40` (body `1`), and none
  for Dummy 1, which player 2 never hit. `Rows` reads
  `Player1: dealt 150 (1 head, 3 body), taken 40 (1 body), killed`, and `Killer` is empty. Press N
  to hide it.

Then Skirmish: press P once in window 1. As round 1's buy phase starts, agent select comes up by
itself: LOCK IN in both windows. Skip the buy phase (`VFMatchSkip`, in the server's command bar).
Once round 1's live, bring the two players about 10 m apart in view of each other, with nothing
between them.

- **CR9 A round's.** Run CR6's second script again. As player 1 dies, window 1's report comes up as
  in CR6, but with no row for Dummy 1, and `ROUND 1` in grey at the right of its title: `Rows` reads
  `Player2: dealt 40 (1 body), taken 150 (1 head, 3 body), killed you`, `Round` is 1 and `Final`
  false. Window 2 shows none. The round goes to player 2's side, and as it ends, window 1's `Final`
  turns true, the report still up; window 2's still shows none, its `Shown` false.
- **CR10 Through the buy phase.** As round 2's buy phase starts, with both players back in their
  rooms, the report shows in both windows by itself: window 1's as it was, and window 2's with
  `Player1` and `KILLED` in gold, `Rows` reading
  `Player1: dealt 150 (1 head, 3 body), taken 40 (1 body), killed`; both with `ROUND 1`, `Round` 1
  and `Final` true. In either window N hides it and N shows it again. Skip the buy phase: as round 2
  goes live, both go, `Shown` false and no `Rows`, and N shows nothing. **Send:** a screenshot of
  window 2's report in the buy phase.

## 58. Damage and danger indicators

From [54-damage-indicators.md](research/54-damage-indicators.md). One player on the course, then
two. PlayerGui's `VFIndicators` carries what's round the crosshair: `Hurt`, the red arcs, each as
where on the ring it is in whole degrees clockwise from the top (`0` ahead, `90` to the right, `-90`
to the left and `180` behind), oldest first and joined by `, `, empty with none; `LastHurt`, where
the latest hit's arc is, or would be once it's gone, empty before a hit in this life; `Danger`, the
yellow chevrons, the same way; and `Critical`, whether the red diamond's up. `VFCombatHud`'s
`LowHealth` and `LowAmmo` say whether the health and the magazine's count read red. `VFTestYaw`
turns the view (positive yaw turns left) and `VFTestPitch` tilts it (negative looks down); a Vector3
`VFTestAimPoint`, in metres, aims at that place and `VFTestAimEntity` at an entity, until they're
cleared; and `VFTestButtons` holds buttons while it's set: 128 the left button, 512 reload, 4096 C
and 8192 Q. Set them in the server's command bar, and clear `VFTestButtons` again each time. To see
the indicators change as it happens, run this watch in a window's own command bar (in Play, with the
command bar on the client): for 20 s it prints each change, with the seconds since it started.

```lua
local g = game.Players.LocalPlayer.PlayerGui
local start, last = os.clock(), nil
task.spawn(function()
	while os.clock() - start < 20 do
		local i = g.VFIndicators
		local now = string.format(
			"hurt '%s', last '%s', danger '%s', critical %s, low health %s",
			tostring(i:GetAttribute("Hurt")),
			tostring(i:GetAttribute("LastHurt")),
			tostring(i:GetAttribute("Danger")),
			tostring(i:GetAttribute("Critical")),
			tostring(g.VFCombatHud:GetAttribute("LowHealth"))
		)
		if now ~= last then
			print(string.format("%.1f s: %s", os.clock() - start, now))
			last = now
		end
		task.wait(0.05)
	end
end)
```

Press Play (F5), with one player, and keep the HUD on (F3). Start at the spawn facing down the
target lane (`VFTestYaw` 0), with the Vandal in hand, 100 health and 50 of Heavy Armor.

- **DI1 Nothing yet.** `Hurt`, `LastHurt` and `Danger` are empty and `Critical` false, and nothing's
  round the crosshair. The HUD's health reads `100` and the Vandal's magazine `25`, both white, and
  `LowHealth` and `LowAmmo` are false.
- **DI2 Low ammo.** Run this, which draws the Classic and fires eight shots into the sky:

  ```lua
  local p = game.Players:GetPlayers()[1]
  p:SetAttribute("VFTestPitch", 60)
  p:SetAttribute("VFTestGive", "classic")
  task.wait(1.5)
  for _ = 1, 8 do
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  	task.wait(0.3)
  end
  ```

  The magazine's count reads `4`, still white, and `LowAmmo` is false. One more shot (128, then
  clear it): `3`, in red, the reserve beside it still grey, and `LowAmmo` true. Reload (512, then
  clear it): once it's done the count reads `12`, white again, and `LowAmmo` is false. Set
  `VFTestPitch` back to 0 and draw the Vandal (1).

- **DI3 Your own burst.** Play as Sova: in agent select (T), click SOVA's card, PICK SOVA, and close
  it with T. Then run this, which looses a Shock Bolt at the floor 2 m to your left:

  ```lua
  local p = game.Players:GetPlayers()[1]
  p:SetAttribute("VFTestAimPoint", Vector3.new(-2, 0.1, 0))
  p:SetAttribute("VFTestButtons", 8192)
  task.wait(0.2)
  p:SetAttribute("VFTestButtons", 0)
  task.wait(1)
  p:SetAttribute("VFTestButtons", 128)
  task.wait(0.1)
  p:SetAttribute("VFTestButtons", 0)
  task.wait(0.5)
  p:SetAttribute("VFTestAimPoint", nil)
  ```

  It bursts there at once (`VFLastShock` about `-2, 0.05, 0`), and your health and shield go down. A
  red arc, thickest in its middle, shows on the left of a ring round the crosshair: `Hurt` and
  `LastHurt` read `-90`. It's whole for a second and fades over the next, and then `Hurt` is empty,
  but `LastHurt` still reads `-90`. **Send:** a screenshot as it shows.

- **DI4 As you turn and move.** Set `VFTestYaw` to 90, facing where it burst: `LastHurt` reads `0`.
  At -90, with it behind you: `180`. Back at 0: `-90`. Then walk 4 m down the lane (`pos` about
  `0.00 0.00 -4.00`): `LastHurt` reads about `-153`, still pointing at where it burst, now behind
  you on the left. Walk back to the spawn.

Then two players: stop the game, start a Local Server with 2 players, as in section 9, and stay on
the course, where everyone is everyone else's enemy. In a Local Server, player 1's id is 4294967295
and player 2's 4294967294, and each window has its own command bar for the watch. Pick SOVA in
window 1 and PHOENIX in window 2 (T). Both start with the Vandal in hand. Player 1 stands at the
spawn facing down the target lane (`VFTestYaw` 0), and player 2 walks 5 m to the left of it (`pos`
about `-5.00 0.00 0.00`), so the two see each other with nothing between. Start the watch in
window 1 before each check.

- **DI5 From the left.** Start the watch in window 2 as well, then run this in the server's command
  bar, which has player 2 fire once at player 1's body:

  ```lua
  local p2 = game.Players.Player2
  p2:SetAttribute("VFTestAimRegion", "body")
  p2:SetAttribute("VFTestAimEntity", 4294967295)
  task.wait(0.6)
  p2:SetAttribute("VFTestButtons", 128)
  task.wait(0.2)
  p2:SetAttribute("VFTestButtons", 0)
  task.wait(0.2)
  p2:SetAttribute("VFTestAimEntity", nil)
  ```

  Window 1's HUD reads `87` and `+24`, and a red arc shows on the left of its ring: its watch prints
  `hurt '-90'` and `last '-90'`, then `hurt ''` 2 s later, `last` still `'-90'`. Window 2's watch
  prints nothing after its first line: the one who fired sees none. **Send:** a screenshot of
  window 1 as the arc shows.

- **DI6 Again, then low health.** Run this, which has player 2 fire twice more at player 1's body,
  0.8 s apart:

  ```lua
  local p2 = game.Players.Player2
  p2:SetAttribute("VFTestAimRegion", "body")
  p2:SetAttribute("VFTestAimEntity", 4294967295)
  for _ = 1, 2 do
  	task.wait(0.6)
  	p2:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p2:SetAttribute("VFTestButtons", 0)
  end
  task.wait(0.2)
  p2:SetAttribute("VFTestAimEntity", nil)
  ```

  Window 1's watch prints `hurt '-90'` at the first and nothing new at the second, one arc renewed,
  not two, then `hurt ''` 2 s after the second. At the first the HUD's health reads `70`, white; at
  the second `30`, in red, and the watch prints `low health true`. Start the watch again and run
  DI5's script with `"head"` in place of `"body"`: player 1 dies, both kill feeds reading
  `Player2   Vandal   Player1`, and the watch prints `last ''` and `low health false` with no new
  arc: a hit that kills shows none. Once player 1's back, `LastHurt` is empty and the health reads
  `100`, white.

- **DI7 The drone.** Run this, which has player 1 send the Owl Drone out and player 2 fire once at
  its middle once it's stopped, 1.8 m in front of player 1:

  ```lua
  local p1, p2 = game.Players.Player1, game.Players.Player2
  p1:SetAttribute("VFTestButtons", 4096)
  task.wait(0.2)
  p1:SetAttribute("VFTestButtons", 0)
  task.wait(1)
  p1:SetAttribute("VFTestButtons", 128)
  task.wait(0.2)
  p1:SetAttribute("VFTestButtons", 0)
  task.wait(1)
  p2:SetAttribute("VFTestAimPoint", Vector3.new(0, 1.62, -1.82))
  task.wait(0.6)
  p2:SetAttribute("VFTestButtons", 128)
  task.wait(0.2)
  p2:SetAttribute("VFTestButtons", 0)
  task.wait(0.2)
  p2:SetAttribute("VFTestAimPoint", nil)
  ```

  Window 1's `VFDroneHealth` reads 60, player 1 is unhurt, and an arc shows on window 1's ring,
  pointing from the drone at player 2, behind it on the left: the watch prints `hurt` and `last`
  about `'-110'`. Press C in window 1 to end the flight (4096, then clear it): back at player 1's
  eye, the watch prints `last '-90'`, the way to player 2 from there.

- **DI8 Near a fire.** Run this, which has player 2 turn away and throw Hot Hands at their feet,
  about 5.9 m from player 1, and player 1 turn towards it 1.5 s later and back:

  ```lua
  local p1, p2 = game.Players.Player1, game.Players.Player2
  p2:SetAttribute("VFTestYaw", 90)
  p2:SetAttribute("VFTestPitch", -60)
  p2:SetAttribute("VFTestButtons", 8192)
  task.wait(0.2)
  p2:SetAttribute("VFTestButtons", 0)
  task.wait(1)
  p2:SetAttribute("VFTestButtons", 128)
  task.wait(0.2)
  p2:SetAttribute("VFTestButtons", 0)
  task.wait(1.5)
  p1:SetAttribute("VFTestYaw", 90)
  task.wait(1)
  p1:SetAttribute("VFTestYaw", 0)
  ```

  In window 1, as the fire spreads, a yellow chevron, pointing out, pulses past the ring on the
  left: the watch prints `danger '-90'`, then `danger '0'` as player 1 turns towards it, `'-90'`
  again as they turn back, and `danger ''` as it goes out, 4 s after it burst. `critical` stays
  false, and player 1's HUD stays at `100` and `+50`. **Send:** a screenshot of window 1 with the
  chevron showing.

- **DI9 In a fire.** Once Q's lit again in window 2, run this, which has player 2 face player 1 and
  throw at their feet, about 4.1 m from player 1:

  ```lua
  local p2 = game.Players.Player2
  p2:SetAttribute("VFTestYaw", -90)
  p2:SetAttribute("VFTestPitch", -60)
  p2:SetAttribute("VFTestButtons", 8192)
  task.wait(0.2)
  p2:SetAttribute("VFTestButtons", 0)
  task.wait(1)
  p2:SetAttribute("VFTestButtons", 128)
  task.wait(0.2)
  p2:SetAttribute("VFTestButtons", 0)
  task.wait(0.5)
  p2:SetAttribute("VFTestYaw", nil)
  p2:SetAttribute("VFTestPitch", nil)
  ```

  Window 1's watch prints `danger '-90'`, and about half a second after the burst, as the fire
  reaches player 1, `critical true` with `danger ''`: a red diamond with a `!` pulses under the
  crosshair, and the screen's edge glows orange. No arc shows, a burn having nowhere it came from to
  point at: `hurt` stays `''`. Player 1's health and shield fall together, 60 a second; 2 s after
  the fire reached them the health reads `30`, in red (`low health true`), and half a second later
  player 1 dies, the kill feed reading `Player2   Hot Hands   Player1`, and it all goes
  (`critical false`, `low health false`).

- **DI10 A wall of fire.** Once player 1's back at the spawn facing down the lane, run this, which
  has player 2 send Blaze along the floor from their feet towards a place 3 m in front of player 1,
  passing about 2.6 m from them:

  ```lua
  local p2 = game.Players.Player2
  p2:SetAttribute("VFTestAimPoint", Vector3.new(0, 0.1, -3))
  p2:SetAttribute("VFTestButtons", 4096)
  task.wait(0.2)
  p2:SetAttribute("VFTestButtons", 0)
  task.wait(1)
  p2:SetAttribute("VFTestButtons", 128)
  task.wait(0.2)
  p2:SetAttribute("VFTestButtons", 0)
  task.wait(0.5)
  p2:SetAttribute("VFTestAimPoint", nil)
  ```

  In window 1, once the wall's risen, a yellow chevron pulses past the ring a little left of the
  top: the watch prints `danger` about `'-31'`, the way to the place on the wall nearest player 1,
  for the 8 s it stands, then `danger ''`. `critical` stays false, and player 1 doesn't burn.

## 59. The kill banner

From [55-kill-banner.md](research/55-kill-banner.md). One player on the course, then two on the
course and in Skirmish. PlayerGui's `VFKillBanner` carries the latest banner: `Count`, its number,
which of your kills it is (0 before one); `Marks`, the marks it lit; `Headshot`; `Victim`, whose
kill it was; `Pitch`, its kill sound's playback speed; and `Shown`, whether a banner's up.
`VFTestAimEntity` aims at an entity and `VFTestAimRegion` at its `head`, `body` or `legs`, until
they're cleared, and `VFTestButtons` holds buttons while it's set: 128 the left button, 256 the
right and 8192 Q. Set them in the server's command bar, and clear `VFTestButtons` again each time.
To see the banner change as it happens, run this watch in a window's own command bar (in Play, with
the command bar on the client): for 30 s it prints each change, with the seconds since it started.

```lua
local g = game.Players.LocalPlayer.PlayerGui
local start, last = os.clock(), nil
task.spawn(function()
	while os.clock() - start < 30 do
		local b = g.VFKillBanner
		local now = string.format(
			"count %s, marks %s, headshot %s, victim '%s', pitch %.2f, shown %s",
			tostring(b:GetAttribute("Count")),
			tostring(b:GetAttribute("Marks")),
			tostring(b:GetAttribute("Headshot")),
			tostring(b:GetAttribute("Victim")),
			b:GetAttribute("Pitch") or 0,
			tostring(b:GetAttribute("Shown"))
		)
		if now ~= last then
			print(string.format("%.1f s: %s", os.clock() - start, now))
			last = now
		end
		task.wait(0.05)
	end
end)
```

Press Play (F5), with one player, and keep the HUD on (F3). Play as Phoenix: press T, click
PHOENIX's card and PICK PHOENIX, and close it with T (or set `VFTestAgents` to true, `VFTestAgent`
to `phoenix`, then `VFTestAgent` to `lock`). Start at the spawn facing down the target lane
(`VFTestYaw` 0), with the Vandal in hand. Dummy 1, the static dummy on the 10 m stripe, is
4294901761; like you, it has 100 health and 50 of Heavy Armor, and it's back 2 s after it dies.
Start the watch before each check.

- **KB1 Nothing yet.** `Count` is 0 and `Shown` false, with no `Marks`, `Headshot`, `Victim` or
  `Pitch`: the watch's first line reads
  `count 0, marks nil, headshot nil, victim 'nil', pitch 0.00, shown false`. Nothing shows between
  the crosshair and the ability bar.
- **KB2 A headshot kill.** Run this in the server's command bar, which fires one shot at Dummy 1's
  head:

  ```lua
  local p = game.Players:GetPlayers()[1]
  p:SetAttribute("VFTestAimRegion", "head")
  p:SetAttribute("VFTestAimEntity", 4294901761)
  task.wait(0.6)
  p:SetAttribute("VFTestButtons", 128)
  task.wait(0.2)
  p:SetAttribute("VFTestButtons", 0)
  task.wait(0.2)
  p:SetAttribute("VFTestAimEntity", nil)
  ```

  Dummy 1 dies, the kill feed reading `<your name>   Vandal   HS   Dummy 1`, and the kill sound
  plays, a bell. At once a banner comes up low in the middle of the screen, well above the ability
  bar: a dark diamond outlined in white with a white `1` in it, a little red X off its top right
  edge, a row of five short bars under it with the first lit white and the rest faint, and `Dummy 1`
  in red under them. It comes up a little bigger and settles at once, shows whole for 1.5 s and
  fades over the next half second. The watch prints
  `count 1, marks 1, headshot true, victim 'Dummy 1', pitch 1.00`, with `shown true`, then
  `shown false` 2 s after the kill. **Send:** a screenshot as the banner shows.

- **KB3 A kill in the body.** Once Dummy 1's back, run this, which fires four shots at its body,
  0.8 s apart:

  ```lua
  local p = game.Players:GetPlayers()[1]
  p:SetAttribute("VFTestAimRegion", "body")
  p:SetAttribute("VFTestAimEntity", 4294901761)
  for _ = 1, 4 do
  	task.wait(0.6)
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  end
  task.wait(0.2)
  p:SetAttribute("VFTestAimEntity", nil)
  ```

  The fourth kills it, the kill feed reading `<your name>   Vandal   Dummy 1`, with no `HS`. The
  banner comes up again, the same size as before: `2` in the diamond, two bars lit, and no red X.
  The watch prints `count 2, marks 2, headshot false, victim 'Dummy 1', pitch 1.06`: the bell a
  little higher.

- **KB4 Up to five, and past it.** Run this, which kills Dummy 1 with a shot to the head four more
  times, each once it's back:

  ```lua
  local p = game.Players:GetPlayers()[1]
  p:SetAttribute("VFTestAimRegion", "head")
  p:SetAttribute("VFTestAimEntity", 4294901761)
  for _ = 1, 4 do
  	task.wait(3)
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  end
  task.wait(0.2)
  p:SetAttribute("VFTestAimEntity", nil)
  ```

  Four banners, 3.2 s apart, each with its red X. The watch prints
  `count 3, marks 3, headshot true, victim 'Dummy 1', pitch 1.12`, then `count 4, marks 4` with
  `pitch 1.18`, then `count 5, marks 5` with `pitch 1.24`, then `count 6, marks 5` with `pitch 1.24`
  again, each with `shown true` and then `shown false`. The third and fourth are white like the
  first two; the fifth is gold, its outline, its `5` and all five bars; and the sixth is gold too,
  with `6` in the diamond and the same five bars lit. **Send:** a screenshot of the sixth.

- **KB5 An ability's kill.** Once Dummy 1's back, run this, which has you draw Hot Hands (Q) and lob
  it (the right button), to burst about 6.4 m ahead:

  ```lua
  local p = game.Players:GetPlayers()[1]
  p:SetAttribute("VFTestButtons", 8192)
  task.wait(0.2)
  p:SetAttribute("VFTestButtons", 0)
  task.wait(1)
  p:SetAttribute("VFTestButtons", 256)
  task.wait(0.2)
  p:SetAttribute("VFTestButtons", 0)
  ```

  The fire spreads over Dummy 1, 3.6 m beyond the burst, and burns it, 60 a second in all; about 3 s
  after the burst it dies, the kill feed reading `<your name>   Hot Hands   Dummy 1`. With it comes
  the banner, gold, `7` in the diamond, all five bars lit and no red X: the watch prints
  `count 7, marks 5, headshot false, victim 'Dummy 1', pitch 1.24`. The fire stops about 2 m short
  of you, and nothing else dies.

Then two players on the course: stop the game, start a Local Server with 2 players, as in section 9,
and stay on the course, where everyone is everyone else's enemy. In a Local Server, player 1's id is
4294967295 and player 2's 4294967294, and each window has its own command bar for the watch. Both
start with the Vandal in hand. Player 1 stands at the spawn facing down the target lane (`VFTestYaw`
0), and player 2 walks 5 m to the left of it (`pos` about `-5.00 0.00 0.00`), so the two see each
other with nothing between, and window 1 sees Dummy 1.

- **KB6 Only the killer, and a new life.** Start the watch in both windows, then run this in the
  server's command bar, which has player 1 kill Dummy 1 with a shot to the head, player 2 kill
  player 1 the same way, and player 1, once back, kill Dummy 1 again:

  ```lua
  local p1, p2 = game.Players.Player1, game.Players.Player2
  local function shoot(p, id)
  	p:SetAttribute("VFTestAimRegion", "head")
  	p:SetAttribute("VFTestAimEntity", id)
  	task.wait(0.6)
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  	task.wait(0.2)
  	p:SetAttribute("VFTestAimEntity", nil)
  end
  shoot(p1, 4294901761)
  task.wait(1)
  shoot(p2, 4294967295)
  task.wait(5)
  shoot(p1, 4294901761)
  ```

  Window 1's watch prints `count 1, marks 1, headshot true, victim 'Dummy 1', pitch 1.00` with
  `shown true`. As player 2 kills player 1, both kill feeds reading
  `Player2   Vandal   HS   Player1`, window 2's watch prints
  `count 1, marks 1, headshot true, victim 'Player1', pitch 1.00` with `shown true`, its banner
  showing `Player1` in red, and window 1's nothing but its `shown false` as its own banner goes.
  Player 1 is back 3 s later and kills Dummy 1 again: window 1's watch prints its first line again,
  `count 1` with `shown true`, a new life's first kill and not a second; and window 2's nothing but
  `shown false`.

Then Skirmish: press P once in window 1. As round 1's buy phase starts, agent select comes up by
itself: LOCK IN in both windows. Skip the buy phase (`VFMatchSkip`, in the server's command bar).
Once round 1's live, bring the two players about 10 m apart in view of each other, with nothing
between them. Both have the Vandal in hand and 100 health with 50 of Heavy Armor.

- **KB7 By the round.** Start the watch in both windows, then run this, which has player 2 kill
  player 1 with a shot to the head:

  ```lua
  local p2 = game.Players.Player2
  p2:SetAttribute("VFTestAimRegion", "head")
  p2:SetAttribute("VFTestAimEntity", 4294967295)
  task.wait(0.6)
  p2:SetAttribute("VFTestButtons", 128)
  task.wait(0.2)
  p2:SetAttribute("VFTestButtons", 0)
  task.wait(0.2)
  p2:SetAttribute("VFTestAimEntity", nil)
  ```

  Window 2's watch prints `count 1, marks 1, headshot true, victim 'Player1', pitch 1.00`, and
  window 1's nothing after its first line. The round goes to player 2's side. Skip round 2's buy
  phase, bring the two in view of each other again, start both watches again and run it again:
  window 2's watch prints `count 1` again, round 2's first kill and not a second, and window 1's
  nothing after its first line, `count 0`.

## 60. Round-end callouts

From [56-round-callouts.md](research/56-round-callouts.md). Two players in Skirmish and then in the
spike rounds, and three in Skirmish. The arena's model, `Workspace.VFArena`, carries the callout of
the round just played as `Callout`, from its end to the next buy phase: `ace`, `teamAce`,
`flawless`, `clutch` or `thrifty`, and nil for none. PlayerGui's `VFArenaBanner` carries the
banner's words as `Title`. To see both change as they happen, run this watch in a window's own
command bar (in Play, with the command bar on the client): for 60 s it prints each change, with the
seconds since it started.

```lua
local g = game.Players.LocalPlayer.PlayerGui
local arena = workspace:WaitForChild("VFArena")
local start, last = os.clock(), nil
task.spawn(function()
	while os.clock() - start < 60 do
		local now = string.format(
			"title '%s', callout %s",
			tostring(g.VFArenaBanner:GetAttribute("Title")),
			tostring(arena:GetAttribute("Callout"))
		)
		if now ~= last then
			print(string.format("%.1f s: %s", os.clock() - start, now))
			last = now
		end
		task.wait(0.05)
	end
end)
```

Stop the game and start a Local Server with 2 players, as in section 9. In a Local Server,
player 1's id is 4294967295 and player 2's 4294967294, and each window has its own command bar for
the watch. Press P once in window 1 for Skirmish. As round 1's buy phase starts, agent select comes
up by itself: LOCK IN in both windows. Skip the buy phase (`VFMatchSkip`, in the server's command
bar). Once round 1's live, bring the two players about 10 m apart in view of each other, with
nothing between them. Both have the Vandal in hand and 100 health with 50 of Heavy Armor, so one
shot to the head kills. `VFTestAimEntity`, `VFTestAimRegion` and `VFTestButtons` are as in
section 59: each code block below defines `shoot`, which aims one player at another's head and fires
once.

- **CO1 One against one.** Start the watch in both windows, then run this, which has player 1 kill
  player 2:

  ```lua
  local p1 = game.Players.Player1
  local function shoot(p, id)
  	p:SetAttribute("VFTestAimRegion", "head")
  	p:SetAttribute("VFTestAimEntity", id)
  	task.wait(0.6)
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  	task.wait(0.2)
  	p:SetAttribute("VFTestAimEntity", nil)
  end
  shoot(p1, 4294967294)
  ```

  Window 1's banner reads `ROUND WON` in blue and window 2's `ROUND LOST` in red, as before:
  window 1's watch prints `title 'ROUND WON', callout nil` and window 2's
  `title 'ROUND LOST', callout nil`. With one a side, a round won by a kill has no callout. About
  3 s later both print `title 'BUY PHASE  3', callout nil` as round 2's buy phase starts.

Then the spike rounds: press P three times more in window 1 (the 1v1, gun game, then the spike
rounds), and LOCK IN in both windows as round 1's buy phase starts. Player 1 attacks and player 2
defends, each with the Classic and the knife and no shield.

- **CO2 Thrifty.** Start the watch in both windows. In round 1's buy phase, run this, which gives
  player 1 a Vandal (the debug give, free, as the 5 key's), then skips the buy phase and, once the
  round's live, the round:

  ```lua
  game.Players.Player1:SetAttribute("VFTestGive", "vandal")
  task.wait(1)
  workspace:SetAttribute("VFMatchSkip", true)
  task.wait(2)
  workspace:SetAttribute("VFMatchSkip", true)
  ```

  Nobody plants, and the round goes to player 2's side on time. Window 2's banner reads `THRIFTY` in
  blue with `Time ran out before a plant` under it, and its watch prints
  `title 'THRIFTY', callout thrifty`. Window 1's reads `ROUND LOST` in red with the same line under
  it, and its watch prints `title 'ROUND LOST', callout thrifty`. Player 1's loadout was worth 2900
  credits and player 2's nothing. **Send:** a screenshot of window 2's banner.

- **CO3 Even loadouts.** Start both watches again. In round 2's buy phase, run this, which gives
  player 2 a Vandal too (player 1 still has theirs) and skips as in CO2:

  ```lua
  game.Players.Player2:SetAttribute("VFTestGive", "vandal")
  task.wait(1)
  workspace:SetAttribute("VFMatchSkip", true)
  task.wait(2)
  workspace:SetAttribute("VFMatchSkip", true)
  ```

  The round goes to player 2's side on time again. Window 2's watch prints
  `title 'ROUND WON', callout nil` and window 1's `title 'ROUND LOST', callout nil`: the two
  loadouts were worth the same.

Then three players: stop the game, start a Local Server with 3 players, and press P once in window 1
for Skirmish. Players 1 and 3 are on one side and player 2 on the other, as in section 25, and
player 3's id is 4294967293. LOCK IN in all three windows as round 1's buy phase starts, and skip
it. Once each round's live, bring the three about 10 m apart in view of one another, with nothing
between them, and start the watch in all three windows.

- **CO4 An ace.** In round 1, run this, which has player 2 kill player 1 and then player 3:

  ```lua
  local p2 = game.Players.Player2
  local function shoot(p, id)
  	p:SetAttribute("VFTestAimRegion", "head")
  	p:SetAttribute("VFTestAimEntity", id)
  	task.wait(0.6)
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  	task.wait(0.2)
  	p:SetAttribute("VFTestAimEntity", nil)
  end
  shoot(p2, 4294967295)
  task.wait(1)
  shoot(p2, 4294967293)
  ```

  Window 2's banner reads `ACE` in blue, and its watch prints `title 'ACE', callout ace`. Windows 1
  and 3 read `ROUND LOST` in red, and their watches print `title 'ROUND LOST', callout ace`.
  **Send:** a screenshot of window 2's banner.

- **CO5 A flawless, on both sides.** In round 2, run this, which has player 1 kill player 2:

  ```lua
  local p1 = game.Players.Player1
  local function shoot(p, id)
  	p:SetAttribute("VFTestAimRegion", "head")
  	p:SetAttribute("VFTestAimEntity", id)
  	task.wait(0.6)
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  	task.wait(0.2)
  	p:SetAttribute("VFTestAimEntity", nil)
  end
  shoot(p1, 4294967294)
  ```

  Windows 1 and 3 read `FLAWLESS` in blue, and window 2 `FLAWLESS` in red: all three watches print
  `title 'FLAWLESS', callout flawless`. Nobody on the winning side died, and the losers see it too.

- **CO6 Nothing from one against one.** In round 3, run this, which has player 2 kill player 1 and
  then player 3 kill player 2:

  ```lua
  local p2, p3 = game.Players.Player2, game.Players.Player3
  local function shoot(p, id)
  	p:SetAttribute("VFTestAimRegion", "head")
  	p:SetAttribute("VFTestAimEntity", id)
  	task.wait(0.6)
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  	task.wait(0.2)
  	p:SetAttribute("VFTestAimEntity", nil)
  end
  shoot(p2, 4294967295)
  task.wait(1)
  shoot(p3, 4294967294)
  ```

  Windows 1 and 3 read `ROUND WON` in blue, their watches printing `title 'ROUND WON', callout nil`,
  and window 2 `ROUND LOST` in red, `title 'ROUND LOST', callout nil`. Player 3 won it from one
  against one, player 1 died, and player 1 killed nobody: no clutch, flawless or team ace.

- **CO7 A clutch.** In round 4, player 2 starts alone against two. Run this, which takes player 3
  out of the game (a kick) and then has player 2 kill player 1:

  ```lua
  local p2 = game.Players.Player2
  local function shoot(p, id)
  	p:SetAttribute("VFTestAimRegion", "head")
  	p:SetAttribute("VFTestAimEntity", id)
  	task.wait(0.6)
  	p:SetAttribute("VFTestButtons", 128)
  	task.wait(0.2)
  	p:SetAttribute("VFTestButtons", 0)
  	task.wait(0.2)
  	p:SetAttribute("VFTestAimEntity", nil)
  end
  game.Players.Player3:Kick("CO7")
  task.wait(1)
  shoot(p2, 4294967295)
  ```

  Window 3 shows that it was kicked; close it. Window 2's banner reads `CLUTCH` in blue, and its
  watch prints `title 'CLUTCH', callout clutch`. Window 1's reads `ROUND LOST` in red,
  `title 'ROUND LOST', callout clutch`. Player 2 started the round one against two and won it, and
  didn't kill player 3, so it's no ace.

## 61. Buying for teammates

From [57-team-buying.md](research/57-team-buying.md). Three players in the spike rounds. Each player
carries their credits as `VFCredits`, the gun they're asking their team for as `VFRequest`, their
plan as `VFPlan`, what they've bought this buy phase as `VFBought`, who paid for each as
`VFBoughtBy` (a teammate's id, or nothing for themselves) and their guns as `VFLoadout`. To see them
change as they happen, run this watch in the server's command bar: for 120 s it prints all three
players each time any of it changes, with the seconds since it started.

```lua
local start, last = os.clock(), nil
task.spawn(function()
	while os.clock() - start < 120 do
		local lines = {}
		for _, p in game.Players:GetPlayers() do
			table.insert(lines, string.format(
				"%s: %s credits, wants %s, plan %s, bought '%s' by '%s', guns '%s'",
				p.Name,
				tostring(p:GetAttribute("VFCredits")),
				tostring(p:GetAttribute("VFRequest")),
				tostring(p:GetAttribute("VFPlan")),
				tostring(p:GetAttribute("VFBought")),
				tostring(p:GetAttribute("VFBoughtBy")),
				tostring(p:GetAttribute("VFLoadout"))
			))
		end
		table.sort(lines)
		local now = table.concat(lines, "\n")
		if now ~= last then
			print(string.format("%.1f s:\n%s", os.clock() - start, now))
			last = now
		end
		task.wait(0.05)
	end
end)
```

Stop the game and start a Local Server with 3 players, as in section 9. Player 1's id is 4294967295,
player 2's 4294967294 and player 3's 4294967293. Press P four times in window 1 (Skirmish, the 1v1,
gun game, then the spike rounds), and LOCK IN in all three windows as round 1's buy phase starts.
Players 1 and 3 attack and player 2 defends, as in section 25, each with the Classic and the knife,
no shield and 800 credits. Without a mouse, `VFTestTeam` on a player right-clicks a gun in the buy
menu (`ask sheriff`), presses BUY on a teammate's card (`buy 4294967293`) or presses a plan's button
(`plan extra`); `VFTestBuy` and `VFTestMenu` are as before. The code blocks below set them from the
server's command bar, each through `send`, which clears the attribute first so the same value can be
sent twice, and print each step's ID as it starts, a few seconds apart, so the watch's lines fall
under it. Run round 1's block as soon as the three have locked in: round 1's buy phase lasts 45 s.

Start the watch, then run this, which opens the buy menu in all three windows and goes through TB1
to TB6:

```lua
local p1, p2, p3 = game.Players.Player1, game.Players.Player2, game.Players.Player3
local function send(p, key, value)
	p:SetAttribute(key, nil)
	task.wait(0.2)
	p:SetAttribute(key, value)
	task.wait(1)
end
send(p1, "VFTestMenu", true)
send(p2, "VFTestMenu", true)
send(p3, "VFTestMenu", true)
print("TB1")
task.wait(4)
print("TB2")
send(p3, "VFTestTeam", "ask sheriff")
task.wait(4)
print("TB3")
send(p1, "VFTestTeam", "buy 4294967293")
task.wait(3)
print("TB4")
send(p3, "VFTestBuy", "-sheriff")
task.wait(2)
print("TB5")
send(p3, "VFTestTeam", "ask ghost")
send(p2, "VFTestTeam", "buy 4294967293")
task.wait(2)
print("TB6")
send(p3, "VFTestTeam", "ask ghost")
send(p1, "VFTestTeam", "plan extra")
task.wait(4)
send(p1, "VFTestTeam", "plan extra")
```

- **TB1 The team panel.** Left of each buy menu is a panel headed `TEAM`, with `SAVING`, `BUYING`
  and `EXTRA` buttons under `YOUR PLAN` and a card for each of the window's side under `YOUR SIDE`.
  Window 1's has `Player1` first, in gold, then `Player3`, each with `800` in gold and `CLASSIC`
  under the name; window 3's has `Player3` first, then `Player1`; window 2's has `Player2` alone.
  Nobody's card is on the other side's panel. The help line at the bottom of each menu ends
  `or to ask your team for a gun   B to close`. **Send:** a screenshot of window 1's menu.

- **TB2 Asking.** Player 3 asks for a Sheriff. The watch prints
  `Player3: 800 credits, wants sheriff`. Window 1 plays the ping's blip, and player 3's card there
  reads `WANTS SHERIFF  800` in blue, with a gold `BUY`. In window 3 the Sheriff's tile is outlined
  in blue and tagged `REQUESTED`, and player 3's own card reads `YOU WANT SHERIFF` with `CANCEL`.
  Window 2 plays nothing, and its card doesn't change.

- **TB3 Buying it for them.** Player 1 presses BUY on player 3's card. The watch prints
  `Player1: 0 credits` and
  `Player3: 800 credits, wants nil, plan nil, bought 'sheriff' by '4294967295', guns ',sheriff'`:
  player 1 paid, player 3 didn't, and the Sheriff is player 3's, bought by player 1. Window 3 has
  the Sheriff in hand, and its card no longer shows a request.

- **TB4 Selling it back.** Player 3 sells the Sheriff back. The watch prints `Player1: 800 credits`
  and `Player3: 800 credits, wants nil, plan nil, bought '' by '', guns ',classic'`: the refund went
  to player 1, who bought it.

- **TB5 Not the other side.** Player 3 asks for a Ghost, and player 2, on the other side, tries to
  buy it for them. The watch prints `Player3: 800 credits, wants ghost`, and then nothing more:
  player 2 keeps `800 credits`, and player 3 still wants the Ghost.

- **TB6 Taking it back, and a plan.** Player 3 asks for the Ghost again, which takes the request
  back, and player 1 picks EXTRA. The watch prints `Player3: 800 credits, wants nil` and then
  `Player1: 800 credits, wants nil, plan extra`. For 4 s window 1's `EXTRA` button is gold and
  player 1's card in window 3 reads `EXTRA CREDITS` under the gun. Then player 1 picks EXTRA again,
  and the watch prints `plan nil` for them.

Skip the rest of the round: `VFMatchSkip` twice in the server's command bar, a few seconds apart.
Nobody plants, and the round goes to player 2's side on time. In round 2's buy phase (30 s),
players 1 and 3 have 1800 credits each (800, and 1000 for a loss lived through without a plant, as
in Q8) and player 2 3800. Start the watch again, then run this:

```lua
local p1, p2, p3 = game.Players.Player1, game.Players.Player2, game.Players.Player3
local function send(p, key, value)
	p:SetAttribute(key, nil)
	task.wait(0.2)
	p:SetAttribute(key, value)
	task.wait(1)
end
send(p1, "VFTestMenu", true)
send(p3, "VFTestMenu", true)
send(p3, "VFTestTeam", "ask spectre")
send(p1, "VFTestTeam", "buy 4294967293")
task.wait(2)
send(p3, "VFTestBuy", "stinger")
task.wait(2)
send(p3, "VFTestTeam", "ask operator")
task.wait(4)
send(p1, "VFTestTeam", "buy 4294967293")
```

- **TB7 Another gun over it, and too dear.** Player 1 buys player 3 a Spectre: the watch prints
  `Player1: 200 credits`, and for player 3 `1800 credits, wants nil, plan nil` and
  `bought 'spectre' by '4294967295', guns 'spectre,classic'`. Player 3 then buys a Stinger over it:
  `Player1: 1800 credits`, the Spectre's 1600 back, and for player 3 `850 credits` and
  `bought 'stinger' by '', guns 'stinger,classic'`, the Stinger's full 950 paid. Player 3 then asks
  for an Operator: for 4 s player 3's card in window 1 reads `WANTS OPERATOR  4700` with a red
  `SHORT`. Player 1's BUY then changes nothing: the watch prints nothing more, player 1 keeping
  1800.

## 62. Wharf

From [58-wharf.md](research/58-wharf.md), on Wharf as system 59 rebuilt it
([59-wharf-heights.md](research/59-wharf-heights.md)); section 63 checks its heights. Wharf, the
fourth spike map, is the first one dressed: each zone's floor in its own look, roofs over six rooms
with a light under each, lintels over the spawns' doors and the sites' chokes, buildings, a tower
and a crane past its walls, a sign at each site, and its cover as pieces of a kit (crates, crate
stacks, containers, barrels, planters, a hedge and a tree). Each piece is still a box, as on the
other maps, but an unseen one: what shows over it is only for show, the kit's placeholder or a model
from ServerStorage's `VFMapKit` folder. Workspace's `VFMatchMap`, set from the server's command bar,
starts the spike rounds on the map it names rather than one at random. The scripts below place
things in metres from Wharf's corner of the place, `-600, 0, 0`, at 0.28 m a stud.

Start a Local Server with 1 player, as in section 9.

- **WF1 On Wharf.** In the server's command bar, run this:

  ```lua
  workspace:SetAttribute("VFMatchMap", "wharf")
  workspace:SetAttribute("VFArenaMode", "spike")
  workspace:SetAttribute("VFMatchFormat", "standard")
  workspace:SetAttribute("VFArenaOn", true)
  task.wait(2)
  print("pieces", #workspace.VFSpikeMap.Wharf.Kit:GetChildren())
  print("spike", workspace:GetAttribute("VFSpikeLayout"), workspace:GetAttribute("VFSpikePosition"))
  ```

  The Output shows `[VF] Arena on: the spike rounds, Standard, on Wharf`, then `pieces 57` and
  `spike wharf -600, 0, 46.5`: the Kit folder has a model for each of the 57 pieces of cover, and
  the spike's sites and start are Wharf's. Round 1's buy phase names `WHARF` first on its line, and
  player 1 is on the red floor marked ATTACKERS, behind red barriers, with the spike in front of
  them. In the Explorer, `Workspace.VFSpikeMap` holds four models: Outpost, Quarry, Foundry and
  Wharf.

- **WF2 Its look.** Run this in the server's command bar. It moves the server window's view to six
  places in turn, 8 s at each, and prints each one's name as it gets there (if the view doesn't
  move, fly the server window's camera to each instead):

  ```lua
  local views = {
  	{ "from above", 0, 90, 85, 0, 0, 0 },
  	{ "mid, from the attackers' door", 0, 1.62, 41, 6, 1.62, 26 },
  	{ "A main", -33.5, 1.62, 47, -35.5, 1.62, 18 },
  	{ "A, from A short", -27, 1.62, -12.5, -45, 2, -22 },
  	{ "B, from hookah's door", 27.5, 1.62, -18.5, 45, 1.62, -20 },
  	{ "mid, from the defenders' side", 10.5, 1.62, -36.5, 10.5, 1.62, -5 },
  }
  local function at(x, y, z)
  	return Vector3.new(-600 + x, y, z) / 0.28
  end
  for _, v in views do
  	print(v[1])
  	workspace.CurrentCamera.CFrame = CFrame.lookAt(at(v[2], v[3], v[4]), at(v[5], v[6], v[7]))
  	task.wait(8)
  end
  ```

  - From above: the whole map, the attackers' spawn at the bottom and the defenders' at the top, A
    on the left and B on the right. Each zone's floor has its own look: dark asphalt on the
    attackers' side, blue-grey slate on the defenders', pale paving in mid, warm concrete at A and
    cool grey concrete at B. Six rooms are under flat metal roofs: A main, the link from mid to A,
    heaven at the back of A, the window room at the top of mid, the market and hookah, and heaven's
    deck, a grey metal plate, stands out from its roof over the back of A. The walls are cream, and
    on them, between the lanes, stand the warehouse, the sheds, the customs house, the terminal and
    the offices, with the tower between top mid and B and the yellow crane straddling B.
  - Mid, from the attackers' door: mid bottom, a container on the left, and the street turning right
    ahead past a crate stack, so nothing further up mid is in sight.
  - A main: the hall's wooden floor under its roof, lit by the light along the roof's middle, a
    crate close on the left, barrels on the right and a crate stack further along on the left, and
    the sheds over the wall at the far end, where the hall turns west.
  - A, from A short: A's concrete and its plant area, the container on the default ahead, crates and
    a crate stack about the site, barrels close on the right, and across the back of the site on the
    right heaven's deck with its railing, its roof over it, and the A sign on the back wall.
  - B, from hookah's door: B's concrete and its plant area, the crate stack on the default with a
    crate beside it, another crate stack beyond, the container by the end of B long on the right,
    the platform across the back on the left with a crate on it and the B sign on the wall over it,
    and ahead, past the wall, one of the crane's legs, its beam overhead.
  - Mid, from the defenders' side: top mid's way south to the courtyard, a crate at its left side,
    and in the courtyard ahead the tree, a crate beyond it.

  Nothing floats, sinks into the floor, pokes through a wall or flickers where two surfaces meet.
  **Send:** the six screenshots, and whether it looks like a place: too plain, about right or too
  busy.

- **WF3 The kit's pieces.** Run this in the server's command bar. It counts the Kit folder's models
  by piece, and the parts in them a step or a shot could meet, then casts five rays at a standing
  player's eye height (1.62 m), a crouching one's (1.1 m) or 2.4 m: over and at mid bottom's crate,
  at A main's crate stack, at A's container and through the courtyard tree's trunk:

  ```lua
  local by, solid = {}, 0
  for _, m in workspace.VFSpikeMap.Wharf.Kit:GetChildren() do
  	local piece = m:GetAttribute("VFKitPiece")
  	by[piece] = (by[piece] or 0) + 1
  	for _, p in m:GetDescendants() do
  		if p:IsA("BasePart") and (p.CanCollide or p.CanQuery or p.CanTouch) then
  			solid += 1
  		end
  	end
  end
  for piece, n in by do
  	print(piece, n)
  end
  print("in the way:", solid)
  local function at(x, y, z)
  	return Vector3.new(-600 + x, y, z) / 0.28
  end
  local function ray(name, x0, y, z0, x1, z1)
  	local from = at(x0, y, z0)
  	local hit = workspace:Raycast(from, at(x1, y, z1) - from)
  	local what = "nothing"
  	if hit then
  		what = hit.Instance.Name .. " " .. tostring(hit.Instance:GetAttribute("VFPenetration"))
  	end
  	print(name, what)
  end
  ray("standing, crate:", 5, 1.62, 40.4, 9.9, 40.4)
  ray("crouched, crate:", 5, 1.1, 40.4, 9.9, 40.4)
  ray("standing, stack:", -36.7, 1.62, 30, -36.7, 21)
  ray("2.4 m, container:", -39, 2.4, -9, -39, -21)
  ray("the trunk:", 5, 2.2, -7, 11, -7)
  ```

  The Output lists `Crate 22`, `CrateStack 12`, `Container 8`, `Barrels 11`, `Planter 2`, `Hedge 1`
  and `Tree 1`, in any order, then `in the way: 0`, then `standing, crate: nothing`,
  `crouched, crate: MidBottomCrate soft`, `standing, stack: AMainStack soft`,
  `2.4 m, container: ADefault hard` and `the trunk: nothing`: a standing player sees and shoots over
  a low piece, a high or tall one hides them, and only the boxes stop anything. In the Explorer,
  `Workspace.VFSpikeMap.Wharf.MidBottomCrate` has Transparency 1, CanCollide on and `VFKitPiece`
  `Crate`. In the server window's view, every piece's placeholder sits on the floor in its box.

- **WF4 A model of your own.** ServerStorage has no `VFMapKit` folder until one is made (if BRINK
  has one already, note what's in it and skip this check). Run this in the server's command bar. It
  makes the folder with a model named `Crate`, a single magenta block, and puts it in ServerStorage
  whole, then counts the crates showing it, looks at mid bottom's crate for 8 s, and takes the
  folder out again:

  ```lua
  local kit = Instance.new("Folder")
  kit.Name = "VFMapKit"
  local crate = Instance.new("Model")
  crate.Name = "Crate"
  local part = Instance.new("Part")
  part.Size = Vector3.new(4, 2, 2)
  part.Color = Color3.fromRGB(255, 0, 255)
  part.Anchored = true
  part.Parent = crate
  crate.Parent = kit
  kit.Parent = game.ServerStorage
  task.wait(1)
  local wharf = workspace.VFSpikeMap.Wharf
  local function swapped()
  	local n = 0
  	for _, m in wharf.Kit:GetChildren() do
  		if m:FindFirstChild("Part") then
  			n += 1
  		end
  	end
  	return n
  end
  print("swapped:", swapped(), "box solid:", wharf.MidBottomCrate.CanCollide)
  local eye, spot = Vector3.new(-596, 4, 36) / 0.28, Vector3.new(-591.6, 0.6, 40.4) / 0.28
  workspace.CurrentCamera.CFrame = CFrame.lookAt(eye, spot)
  task.wait(8)
  kit:Destroy()
  task.wait(1)
  print("swapped:", swapped())
  ```

  The Output shows `swapped: 22 box solid: true`, and in the view mid bottom's crate is a magenta
  block as long as the crate, standing on the floor where it was, with the unseen box still there to
  stop players and shots. Then `swapped: 0`, and the crate is back as it was.

- **WF5 Two players.** Stop the game, start a Local Server with 2 players, as in section 9, and run
  WF1's first four lines in the server's command bar. Player 1 attacks and player 2 defends. In the
  buy phase, each player walks into each of their spawn's three doors: each stops at a barrier
  across the middle of the door, under its lintel. From anywhere in either spawn, nothing of the
  other one is in sight. Skip the buy phase (`VFMatchSkip`). Player 1 picks up the spike and runs
  with the knife out of the spawn's door toward A, across A lobby, down A main, round its bends and
  through its door onto A, and plants it in A's plant area: `SPIKE` shows in the bar. Player 2 runs
  with the knife out of their spawn's door toward A, along the A hall and through A's back.
  [59-wharf-heights.md](research/59-wharf-heights.md) has the attackers reaching A's plant area in
  14.3 s and the defenders in 7.8 s. Then walk the rest: B's ways, through B lobby, its doors and B
  long, and through mid, the market and hookah; and mid's, through mid bottom, the lane, the
  courtyard and top mid. **Send:** each player's time to A, anything in the way or too tight, and
  whether the map feels too big, about right or too small for five a side.

## 63. Wharf's heights

From [59-wharf-heights.md](research/59-wharf-heights.md). System 59 gave the spike maps heights and
rebuilt Wharf with them: heaven at the back of A, a roofed room 3.2 m up with a railed deck over the
site and hell under the deck; a window room 3 m up looking down mid; a platform 1.6 m up across the
back of B; and hookah, a room off the market with a door and a window onto B. Each stair and ramp is
a WedgePart turned to rise toward its head, and a flight of stairs hides its wedge under steps that
are only for show. The scripts place things as section 62's do.

Start a Local Server with 1 player, as in section 9.

- **WH1 The heights, built.** In the server's command bar, run this. It counts the steps and the
  railings, measures the decks, and for each wedge reads the height of its top 1 m in from its foot
  and 1 m in from its head:

  ```lua
  workspace:SetAttribute("VFMatchMap", "wharf")
  workspace:SetAttribute("VFArenaMode", "spike")
  workspace:SetAttribute("VFMatchFormat", "standard")
  workspace:SetAttribute("VFArenaOn", true)
  task.wait(2)
  local wharf = workspace.VFSpikeMap.Wharf
  local steps, rails = 0, 0
  for _, p in wharf:GetChildren() do
  	if string.find(p.Name, "Step$") then
  		steps += 1
  	elseif string.find(p.Name, "Rail$") then
  		rails += 1
  	end
  end
  local deck, drop = wharf.HeavenDeck.Size.Y * 0.28, wharf.HeavenDrop.Size.Y * 0.28
  local thick = string.format("%.1f m and %.1f m thick", deck, drop)
  print(string.format("steps %d, rails %d, decks %s", steps, rails, thick))
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Include
  for _, p in wharf:GetChildren() do
  	if p:IsA("WedgePart") then
  		params.FilterDescendantsInstances = { p }
  		-- 1 m in from either end, along the way it rises
  		local along = -p.CFrame.LookVector * (p.Size.Z / 2 - 1 / 0.28)
  		local function top(sign)
  			local from = p.Position + along * sign + Vector3.new(0, 40, 0)
  			local hit = workspace:Raycast(from, Vector3.new(0, -80, 0), params)
  			return if hit then hit.Position.Y * 0.28 else -1
  		end
  		print(p.Name, p.Transparency, string.format("foot %.1f m, head %.1f m", top(-1), top(1)))
  	end
  end
  ```

  The Output shows `steps 47, rails 2, decks 0.3 m and 0.3 m thick`, then, in any order,
  `HeavenStairs 1 foot 0.4 m, head 2.8 m`, `SiteStairs 1 foot 0.4 m, head 2.8 m`,
  `WindowStairs 1 foot 0.4 m, head 2.6 m`, `BRamp 0 foot 0.3 m, head 1.3 m` and
  `BElbowRamp 0 foot 0.3 m, head 1.3 m`: each wedge rises toward its head, the stairs' three unseen
  under their steps and the ramps' two seen. A wedge whose foot reads higher than its head is turned
  the wrong way: note which, and stop here, as the walks below need them the right way.

- **WH2 The heights, seen.** Run this in the server's command bar, as WF2's views:

  ```lua
  local views = {
  	{ "A, from A main's door", -47.5, 1.62, -6.5, -44, 3.5, -28 },
  	{ "heaven's deck", -50.5, 4.82, -28, -36, 3.5, -27 },
  	{ "mid, from the end of the lane", 0.5, 1.62, 1.5, 0, 4.9, -12.5 },
  	{ "mid, from the window", 0, 4.62, -13.4, 0.5, 1.62, 12 },
  	{ "hookah, from B's site", 35, 1.62, -11, 27.5, 1.6, -15 },
  	{ "B's platform, from the top of the defenders' ramp", 43, 3.22, -33.5, 40, 1, -14 },
  }
  local function at(x, y, z)
  	return Vector3.new(-600 + x, y, z) / 0.28
  end
  for _, v in views do
  	print(v[1])
  	workspace.CurrentCamera.CFrame = CFrame.lookAt(at(v[2], v[3], v[4]), at(v[5], v[6], v[7]))
  	task.wait(8)
  end
  ```

  - A, from A main's door: a crate stack close on the right, and ahead, across the back of the site,
    heaven's deck 3.2 m up with its railing along the front, the stairs up to it along the site's
    west wall on the left, heaven's roof over the room behind the deck, the A sign on the wall over
    the deck, and under the deck, hell, open to the site.
  - Heaven's deck: the deck's metal floor ahead, its railing along the right-hand side stopping
    short of the far end, the gap there open to the site below, and a railing across the far end;
    the site below to the right, and the customs house over the wall ahead.
  - Mid, from the end of the lane: the courtyard ahead, open down the middle, and over its far side
    the window room's frame, 4 m wide and 3 m up, with the room's roof over it; barrels on the left
    by the way to A, and the tree on the right.
  - Mid, from the window: over the frame's sill, 1 m up, the far half of the courtyard below, the
    strip right under the window out of sight, and the lane running away from it toward the
    attackers' side, a planter on its left and a crate stack on its right, nothing across it; the
    tree off to the left, none of its leaves over the lane, and the warehouse over the wall to the
    right.
  - Hookah, from B's site: hookah's front, its window 3 m wide with its sill 0.75 m up and its top
    2.7 m, and to its right the door under its lintel, with barrels by it; a crate close on the
    left, and the crane's leg over hookah's roof.
  - B's platform, from the top of the defenders' ramp: the platform's floor ahead, a crate on it to
    the left, and its front open, with no railing, over the site below: the crate stack on the
    default, another crate stack, the container by the end of B long to the left and B long running
    away beyond it.

  Nothing floats, sinks into the floor, pokes through a wall or flickers where two surfaces meet,
  and each flight's steps sit on its slope, none hanging over it or sunk into it. **Send:** the six
  screenshots.

- **WH3 Walking them.** Stop the game, start a Local Server with 2 players, as in section 9, and run
  WH1's first four lines in the server's command bar. Player 1 attacks and player 2 defends. Skip
  each buy phase (`VFMatchSkip`); if a round ends before the walks do, carry on in the next. Walk
  with the knife out, running up and down every stair and ramp on the way:
  - Player 1: down A main onto A's site, and up the stairs along the site's west wall onto heaven's
    deck. Run into the railing along the deck's front: it holds. Walk east along the deck, past the
    railing's end, and off its front: a drop into the site. From the site, jump at the deck's edge:
    there's no way back up but the stairs. Then through A short, the link, the courtyard and the
    market into hookah, and jump through its window onto B, and back: one jump each way.
  - Player 2: out of the spawn's A door, along the A hall to A's back, up heaven's stairs into its
    room and out onto the deck, and back down. Out of the spawn's middle door, up the window room's
    stairs, and at the frame jump: it's too high to climb through. Then out of the spawn's B door,
    along the B hall and up the ramp at its end onto B's platform, off its front onto the site, up
    the ramp from the site back onto it, and from the site jump at the platform's front: there's no
    way up but the ramps.

  Every stair and ramp rises toward its head, and running up or down it there's no stop, stumble or
  hop. **Send:** anything that stopped or tripped either player, and any flight that looked or felt
  wrong.

- **WH4 Seen from below.** In the next round (skip its buy phase), player 2 goes up to heaven's deck
  and stands at the railing, then crouches, while player 1 stands in A's plant area, where they can
  see the deck, and looks up at it: standing, player 2's head shows over the railing, and crouching,
  they're hidden. Then the same at the window: player 2 stands at the frame, then crouches, and
  player 1 stands where the lane opens into the courtyard: standing, player 2's head shows in the
  frame, and crouching, they're out of sight. Standing at the frame, player 2 sees down the whole
  lane, with nothing across it. **Send:** player 1's screenshots, standing and crouching at each,
  and player 2's down the lane.

- **WH5 The runs, and how it plays.** At the start of a round's live phase, both with the knife out,
  player 1 runs from the spawn down A main to A's plant area and player 2 along the A hall and
  through A's back to it; [59-wharf-heights.md](research/59-wharf-heights.md) has them at 14.3 s and
  7.8 s. In another round, player 1 runs the quickest way to B, up mid's lane, across the courtyard,
  along the market and through hookah's window, and player 2 along the B hall and through B's back:
  13.2 s and 7.9 s. **Send:** each time, whether heaven, the window and the platform each look worth
  taking for what they cost, and whether A or B looks the easier to take.

## 64. Bots

From [60-bots.md](research/60-bots.md). System 60 fills what's played with bots, players the server
plays itself: up to ten in the spike rounds and Team Deathmatch, eight in gun game and deathmatch
and four in Skirmish, a player joining taking a bot's place. A bot is drawn, named and counted as a
player is, with `BOT ` before its name. Each has a stand-in in ReplicatedStorage's `VFBots`, a
Configuration named after it with `Entity`, `Id` and the attributes the arena keeps on a player
(`VFArenaSide`, `VFAlive`, `VFKills`, `VFStartCredits`, `VFCredits`, `VFLoadout` and the rest), and
in Studio `VFBotTask`, its job in its side's plan (`gather`, `push`, `take`, `hunt`, `hold`,
`rotate`, `follow`, `roam` or `wait`). Workspace's `VFBots` set false keeps bots out, and
`VFBotSkill` (`easy`, `normal`, `hard` or `expert`) sets how well they play, from each one's next
life. In Studio the Output says `[VF] BOT Ash stuck at (x, y, z), going another way` each time a
bot's been stuck for 1.2 s, with where in metres in the map's own frame, and Workspace's `VFBotMs`
has the milliseconds the bots take of each server frame. Bots don't use abilities; they play for the
spike from system 61 (section 65).

Start a Local Server with 1 player, as in section 9.

- **BT1 Filling each mode.** In the server's command bar, run this. It plays each mode in turn and,
  3 s in, counts the bots and those named and numbered as bots, counts who's on each side, and reads
  the phase:

  ```lua
  workspace:SetAttribute("VFMatchMap", "outpost")
  for _, mode in { "skirmish", "gungame", "deathmatch", "teamdeathmatch", "spike" } do
  	workspace:SetAttribute("VFArenaMode", mode)
  	workspace:SetAttribute("VFArenaOn", true)
  	task.wait(3)
  	local folder = game.ReplicatedStorage:FindFirstChild("VFBots")
  	local everyone = if folder then folder:GetChildren() else {}
  	local bots, named = #everyone, 0
  	for _, bot in everyone do
  		if string.sub(bot.Name, 1, 4) == "BOT " and bot:GetAttribute("Id") < 0 then
  			named += 1
  		end
  	end
  	for _, player in game.Players:GetPlayers() do
  		table.insert(everyone, player)
  	end
  	local count = {}
  	for _, who in everyone do
  		local side = who:GetAttribute("VFArenaSide")
  		if side then
  			count[side] = (count[side] or 0) + 1
  		end
  	end
  	local sides = {}
  	for side = 1, 20 do
  		if count[side] then
  			table.insert(sides, count[side])
  		end
  	end
  	local phase = workspace.VFArena:GetAttribute("Phase")
  	local line = "%s: %d bots, %d named; on each side %s; %s"
  	print(string.format(line, mode, bots, named, table.concat(sides, ", "), tostring(phase)))
  end
  ```

  After each mode's `[VF] Arena on:` line, the Output shows, in turn:

  - `skirmish: 3 bots, 3 named; on each side 2, 2; buy`
  - `gungame: 7 bots, 7 named; on each side 4, 4; live`
  - `deathmatch: 7 bots, 7 named; on each side 1, 1, 1, 1, 1, 1, 1, 1; live`
  - `teamdeathmatch: 9 bots, 9 named; on each side 5, 5; pregame`
  - `spike: 9 bots, 9 named; on each side 5, 5; buy`

  One player starts each match, where alone they'd be `waiting`. Where agent select comes up, lock
  in any agent. **Send:** the five lines.

- **BT2 A player's place.** Stop the game, start a Local Server with 2 players, and run BT1's script
  again: each mode has one bot fewer (`skirmish: 2 bots`, through `spike: 8 bots`), and the same on
  each side. Then close window 2, so player 2 leaves, and run
  `print(#game.ReplicatedStorage.VFBots:GetChildren())` in the server's command bar: `9`, a bot
  having taken their place. Only once the place is published: one player plays Skirmish against
  three bots, and a second joins and presses PLAY SKIRMISH: they wait in line until the round's
  over, or until a bot's down, and then take a bot's place. **Send:** the Output's lines, and how
  the join went if it was tried.

- **BT3 On screen.** In a buy phase of the spike rounds, after player 2's gone (skip to one with
  `VFMatchSkip` if need be), run this in window 1's command bar. It holds the scoreboard open, and
  lists the top bar's tiles, the scoreboard's rows and who's drawn:

  ```lua
  local me = game.Players.LocalPlayer
  me:SetAttribute("VFTestBoard", true)
  task.wait(1)
  local gui = me.PlayerGui
  print("yours:", gui.VFArenaHud:GetAttribute("Yours"))
  print("theirs:", gui.VFArenaHud:GetAttribute("Theirs"))
  print("board:", gui.VFScoreboard:GetAttribute("Ult"))
  local drawn = {}
  for _, model in workspace.VFPlayers:GetChildren() do
  	table.insert(drawn, model.Name)
  end
  table.sort(drawn)
  print("drawn:", table.concat(drawn, ", "))
  me:SetAttribute("VFTestBoard", false)
  ```

  `yours:` lists five tiles, each with `100`: your agent's letters, and four bots', the first two
  letters of each name past `BOT ` (`AS` for `BOT Ash`). `theirs:` lists the other side's five bots'
  letters, with no health. `board:` has a row for each of the ten: yours with your agent's letters
  and your ultimate (`JE Player1 0/8`), and a bot's with its letters and its name and no ultimate
  (`AS BOT Ash`). `drawn:` names your side's four bots, and none of the other side's, out of sight
  in their spawn. Take screenshots of the top bar; the scoreboard (hold Tab), each bot with its
  credits, and on your side its gun and shield; a bot of yours up close, with its name and health
  over its head (`BOT Ash`, then `100 + 25` in Light Armor) and its outline in your side's colour;
  and the minimap, with your side's bots on it. **Send:** the Output's lines and the screenshots.

- **BT4 What they buy.** A few seconds into a buy phase, run this in the server's command bar:

  ```lua
  for _, bot in game.ReplicatedStorage.VFBots:GetChildren() do
  	local start, left = bot:GetAttribute("VFStartCredits"), bot:GetAttribute("VFCredits")
  	print(bot.Name, bot:GetAttribute("VFArenaSide"), start, left, bot:GetAttribute("VFLoadout"))
  end
  ```

  Nobody's spent more than they had. In a half's first round, from 800 credits, each has bought a
  Light Armor (`400` left, `,classic`) or now and then a Ghost (`300` left, `,ghost`). Skip to the
  next buy phase (`VFMatchSkip` twice, for the buy phase and then the round) and run it again, and
  once more after that: a bot with a rifle's and armour's worth has a rifle (`vandal` or `phantom`
  first in `VFLoadout`), one with less a Spectre, one with less still nothing new, and one without a
  shield buys one if it can. **Send:** the Output's lines.

- **BT5 Going round together.** In a buy phase of the spike rounds on Outpost (BT1's `VFMatchMap`),
  stay in your spawn and run this in the server's command bar. It skips the buy phase, then every
  2 s for a minute lists the jobs of each side's bots alive:

  ```lua
  workspace:SetAttribute("VFMatchSkip", true)
  for k = 1, 30 do
  	task.wait(2)
  	local jobs = { {}, {} }
  	for _, bot in game.ReplicatedStorage.VFBots:GetChildren() do
  		local side = bot:GetAttribute("VFArenaSide")
  		if bot:GetAttribute("VFAlive") ~= false and jobs[side] then
  			table.insert(jobs[side], tostring(bot:GetAttribute("VFBotTask")))
  		end
  	end
  	local attackers = workspace.VFArena:GetAttribute("Attackers")
  	local a, d = jobs[attackers], jobs[3 - attackers]
  	table.sort(a)
  	table.sort(d)
  	local phase = workspace.VFArena:GetAttribute("Phase")
  	print(k * 2, phase, "attack: " .. table.concat(a, " "), "defend: " .. table.concat(d, " "))
  end
  ```

  The attacking side's bots read `gather`, then `push` together, then `take` once on the site (and
  `hunt` 20 s on with nobody seen). The defending side's read `hold`, and once attackers are seen at
  a site all but one of those at the other read `rotate`. From system 61 they play for the spike too
  (section 65): an attacker reads `fetch` and then `plant`, and once it's planted the attackers read
  `guard` and the defenders `retake` and `defuse`, and either side `clear` as they get out of its
  blast. While it runs, hold Caps Lock for the big map: your side's bots go together, attacking to
  the same site or defending to each way into the sites, through doors and up stairs, never stopped
  against a wall or in a doorway, and spread out rather than in a line or a heap. As they fight, the
  kill feed names them, and each one that dies drops its gun where it falls, a part in Workspace's
  `VFGroundGuns`. The Output has no `stuck at` line, or very few. Then for each of `quarry`,
  `foundry` and `wharf`, set `VFMatchMap` to it, `VFArenaOn` to false and then true, and once round
  1's buy phase starts run the script again. **Send:** the Output's lines for each map, every
  `stuck at` line among them, and screenshots of the big map as the attackers push and as the
  defenders hold.

- **BT6 Following a player.** Set `VFArenaMode` to `teamdeathmatch`. Once its pre-game's over, run
  this in window 1's command bar, which every second for half a minute prints how far each of your
  side's bots is from you, in metres:

  ```lua
  local me = game.Players.LocalPlayer
  for k = 1, 30 do
  	task.wait(1)
  	local eye = workspace.CurrentCamera.CFrame.Position
  	local out = {}
  	for _, model in workspace.VFPlayers:GetChildren() do
  		local standIn = game.ReplicatedStorage.VFBots:FindFirstChild(model.Name)
  		if standIn and standIn:GetAttribute("VFArenaSide") == me:GetAttribute("VFArenaSide") then
  			table.insert(out, string.format("%.0f", (model.body.Position - eye).Magnitude * 0.28))
  		end
  	end
  	print(k, table.concat(out, " "))
  end
  ```

  Meanwhile walk out of your spawn room and across the map, through doors and up stairs, stopping
  now and then. Your side's four bots come with you a few metres off, and where you stop gather
  round you, 3 to 7 m off, and none is left behind against a wall: most distances are under 10 m,
  and none stays over 20 m. **Send:** the Output's lines, and anything a bot did that looked wrong.

- **BT7 How they fight.** Play Skirmish against the bots for a few rounds at each skill, setting
  Workspace's `VFBotSkill` to `easy`, `normal`, `hard` and then `expert` in the server's command
  bar; each takes hold from a bot's next life. A bot takes a moment to notice you, longer at the
  edge of its view; stops dead before it shoots; taps at range, fires short bursts nearer and sprays
  up close; and misses some, Easy the most. Hold an angle and let one walk into it: on Normal you
  win most of those, and lose most where you walk into theirs. Die, and the view follows your side's
  bots as it would teammates. Then play a few rounds of the spike rounds. **Send:** for each skill,
  the rounds won and lost, whether they felt like people (too good, about right or too easy), and
  anything that looked robotic.

- **BT8 Off, and what they cost.** In a live round of the spike rounds on Wharf, with nine bots, run
  `print(workspace:GetAttribute("VFBotMs"))` in the server's command bar a few times: the
  milliseconds the bots take of each server frame, well under the frame's 16.7. Then set `VFBots` to
  false: as the round ends the bots leave and none join,
  `print(#game.ReplicatedStorage.VFBots:GetChildren())` prints `0`, and the match waits for players
  (`waiting`). Set it back to true: nine join, and the match goes on. **Send:** the numbers.

## 65. Bots and the spike

From [61-bots-and-the-spike.md](research/61-bots-and-the-spike.md). System 61 has bots play for the
spike in the spike rounds. An attacking side's bots pick it up, carry it with their plan and plant
it on the site they chose; once it's planted they guard it, each from a spot that sees it, and get
out of the blast in time. Defending bots gather at the site's ways back in, push in together, and
one defuses it while the rest stand round it, or they all get out of the blast when it's too late. A
spike on the ground is left to a player on the side for 5 s of a live round first, a player carrying
it plants it where they choose, and a player defusing it is left to it. In Studio a bot's
`VFBotTask` has the new jobs: `fetch`, `plant`, `guard`, `retake`, `defuse` and `clear` (out of the
blast). While a bot carries the spike, Workspace's `VFSpikeCarrier` is its id in the rules, below 0,
and the debug HUD's `spike` line names it.

Start a Local Server with 1 player, as in section 9, and set the spike rounds going on Outpost from
the server's command bar, as in BT1: `VFMatchMap` `outpost`, `VFArenaMode` `spike`, then `VFArenaOn`
true. You attack in the first half. Don't fight in these checks unless one says to: stay back and
watch the bots.

- **BS1 Left to you, then fetched.** As round 1's buy phase starts, stay in your spawn and leave the
  spike where it lies. Run this in the server's command bar. It skips the buy phase, then every 2 s
  for 2 minutes prints the phase, where the spike is and who has it, and the jobs of each side's
  bots alive:

  ```lua
  local function nameOf(id)
  	for _, bot in game.ReplicatedStorage.VFBots:GetChildren() do
  		if bot:GetAttribute("Id") == id then
  			return bot.Name
  		end
  	end
  	local player = game.Players:GetPlayerByUserId(id)
  	return if player then player.Name else tostring(id)
  end
  workspace:SetAttribute("VFMatchSkip", true)
  for k = 1, 60 do
  	task.wait(2)
  	local jobs = { {}, {} }
  	for _, bot in game.ReplicatedStorage.VFBots:GetChildren() do
  		local side = bot:GetAttribute("VFArenaSide")
  		if bot:GetAttribute("VFAlive") ~= false and jobs[side] then
  			table.insert(jobs[side], tostring(bot:GetAttribute("VFBotTask")))
  		end
  	end
  	local attackers = workspace.VFArena:GetAttribute("Attackers")
  	local a, d = jobs[attackers], jobs[3 - attackers]
  	table.sort(a)
  	table.sort(d)
  	local spike = workspace:GetAttribute("VFSpike")
  	local carrier = workspace:GetAttribute("VFSpikeCarrier")
  	if carrier ~= 0 then
  		spike = spike .. " by " .. nameOf(carrier)
  	elseif spike == "planted" then
  		spike = spike .. " at " .. workspace:GetAttribute("VFSpikeSite")
  	end
  	local phase = workspace.VFArena:GetAttribute("Phase")
  	print(k * 2, phase, spike, "attack: " .. table.concat(a, " "), "defend: " .. table.concat(d, " "))
  end
  ```

  For the round's first few seconds the spike reads `dropped` and no attacker reads `fetch`; about
  5 s in one does, and walks onto it: `carried by BOT ...`. The carrier goes with the others
  (`gather`, `push`) and reads `plant` once through their way onto the site, and the spike reads
  `planted at A` (or `B`), unless the defenders stop them. Once it's planted the attackers alive
  read `guard`, the defenders `retake` and then one `defuse`. Either it's defused, or with about
  10 s left the attackers alive read `clear` and leave the site, and none of them dies as it goes
  off (`detonated`). Follow the carrier to watch where it plants and where the others stand.
  **Send:** the Output's lines, and how the plant and the guarding looked.

- **BS2 Your spike.** In round 2 (run BS1's script again as its buy phase starts), pick the spike
  up, go with your side's bots to their site, and in its plant area press G to drop the spike. It
  reads `dropped`, and about 5 s later a bot reads `fetch`, picks it up and plants it as the side
  takes the site. In round 3 carry it and plant it yourself (hold 4 in the plant area): your side's
  bots read `guard`, each where it sees the spike, and with about 10 s left `clear`, and leave;
  leave too. **Send:** the Output's lines for both rounds.

- **BS3 On screen.** While a bot of your side carries the spike, in BS1 or BS2, press F3: the debug
  HUD's `spike` line reads `carried by BOT ...`, with that bot's name. Hold Caps Lock for the big
  map: the carrier's mark is on that bot, as on a teammate carrying it. When it plants:
  `SPIKE PLANTED` across the screen, the beeping, and the clock giving way to `SPIKE`, as for a
  player's plant. **Send:** screenshots of the HUD's line and the big map with the mark.

- **BS4 Defending with bots.** Set `VFArenaOn` false, `VFMatchFormat` `swiftplay` and `VFArenaOn`
  true, and skip the first half's four rounds before anyone plants (`VFMatchSkip` twice a round, for
  its buy phase and then the round), so you defend from round 5. Run BS1's script as round 5's buy
  phase starts, and stay in your spawn. The attacking bots read `fetch` as the round starts, with no
  player on their side to leave the spike to, and plant it. Your side's bots read `retake`: they
  gather at the ways back into that site and go in together, one reads `defuse` and the others stand
  round the spike, and the round's yours with `Spike defused`, unless the attackers stop them. If a
  retake comes too late, they read `clear` and leave the site instead. In round 6, once it's
  planted, go to it and hold 4 to defuse it yourself: while you're at it, no bot of yours reads
  `defuse`. **Send:** the Output's lines for both rounds.

- **BS5 What it costs.** Set `VFMatchMap` to `wharf`, `VFArenaOn` to false and then true. In a live
  round, as a plant goes down and the retake starts, run `print(workspace:GetAttribute("VFBotMs"))`
  in the server's command bar a few times: well under the frame's 16.7. **Send:** the numbers.

## 66. Taking over a bot

From [62-taking-over-bots.md](research/62-taking-over-bots.md). System 62 lets a player who's down
take over a living bot of their side for the rest of the round, as Counter-Strike's casual modes let
the dead: in Skirmish, and in the spike rounds in the standard format and Swiftplay's, while a
round's played, but not in Competitive's format, nor in the modes that respawn. Watching a bot on
your side, the line under its name reads `F  take control`. F (or `VFTestTake` true) asks, the line
reads `Taking control`, and as your new character loads you play on in the bot's body: where it
stood, looking where it looked, with its guns and their rounds, the one in hand drawn, its health
and shield, and the spike if it carried it. The bot's out of the round with no death, and plays
again from the next on the starting kit. Your new character carries the body's kit as text in
`VFSpawnKit` (each slot's gun, rounds and reserve, then after a semicolon the slot in hand) and its
pitch in `VFSpawnPitch`.

Start a Local Server with 1 player, as in section 9. This script, for the server's command bar,
prints each bot and then you: side, whether alive, kills, deaths, guns and credits, and last your
character's `VFSpawnKit` (nil for a life that wasn't a takeover):

```lua
local function show(who)
	local line = { who.Name }
	for _, key in { "VFArenaSide", "VFAlive", "VFKills", "VFDeaths", "VFLoadout", "VFCredits" } do
		table.insert(line, tostring(who:GetAttribute(key)))
	end
	print(table.concat(line, "  "))
end
for _, bot in game.ReplicatedStorage.VFBots:GetChildren() do
	show(bot)
end
local me = game.Players:GetPlayers()[1]
show(me)
print(me.Character and me.Character:GetAttribute("VFSpawnKit"))
```

- **BC1 In Skirmish.** Run this in the server's command bar:

  ```lua
  workspace:SetAttribute("VFArenaMode", "skirmish")
  workspace:SetAttribute("VFArenaOn", true)
  ```

  You and a bot are on one side, two bots on the other. Once round 1 is live, walk out at the other
  side's bots without shooting and let them kill you. After `ELIMINATED`, you're watching your
  side's bot, and the line under `SPECTATING  BOT ...` reads `F  take control`, not
  `You play from the next round`. Run the script: that bot reads `true`, and you `false`. Press F:
  the line reads `Taking control`, and in about a second you're playing again where the bot stood,
  the view going on from where it looked with no jump, its gun in your hand, and its health and
  shield on the HUD, and the server's Output has `[VF] takeover: -1 for <the bot's id> asked`, then
  `[VF] takeover: -1 into <the bot's id>'s body` (any other `[VF] takeover:` line says why not).
  Run the script again: the bot reads `false` with its kills and deaths as they were, you `true`
  with your own, and the last line is the body's kit, as `vandal:18:50,classic:12:36,knife:0:0,;1`,
  where the gun in hand's rounds and reserve are those in the ammo box. The kill feed has nothing
  for the bot, and on the top bar its tile is greyed and yours lit. Play the round out: in round 2
  the bot's back. Where Skirmish's one bot on your side is always down before you are, the spike
  rounds (Competitive as in section 71) have four. **Send:** the script's lines before and after,
  the `[VF] takeover:` lines, and how the view and the HUD went.

- **BC2 The spike.** In the server's command bar, set `VFArenaOn` to false, then `VFMatchMap` to
  `outpost`, `VFArenaMode` to `spike` and `VFArenaOn` to true, as in section 65: you attack first.
  In round 1's buy phase leave the spike where it lies and set `VFMatchSkip` to true; about 5 s into
  the round one of your side's bots picks it up, and the debug HUD's `spike` line (F3) reads
  `carried by BOT ...`. Go ahead of the bots, let the defenders kill you, then left- or right-click
  until you watch the bot carrying it (if it falls first, try again next round). Press F: once
  you're playing, the HUD's line reads `carried by` and your name, 4 draws the spike, and on the big
  map (Caps Lock) the carrier's mark is on you. Run
  `print(workspace:GetAttribute("VFSpikeCarrier"), game.Players:GetPlayers()[1].UserId)` in the
  server's command bar: the same number twice. Plant it in a site (hold 4 in its plant area):
  `SPIKE PLANTED`, as for any plant. In a later round, leave the spike to the bots and stay back;
  once one's planted it (the HUD's line reads `planted at A` or `B`), get killed, watch a bot of
  yours guarding it and press F: the line reads `F  take control` with the spike down too, and
  you're in its body. **Send:** the two numbers, and whether both takeovers and your plant went
  through.

- **BC3 Afterwards.** Go on with BC2's match. In a round, take over a bot of yours as before and run
  the script. Kill an enemy in the body and run it again: your kills went up by one, and the bot's
  didn't. Live to the round's end, and run it as the next buy phase starts: your `VFLoadout` is the
  body's guns, kept as a survivor keeps theirs, and the bot's is what it bought as it spawned, from
  the starting kit (`,classic`) and its own credits, which went down by what it spent. In a round
  where you take over a bot and die in it, the next buy phase finds you on `,classic`, as after any
  death. **Send:** the script's lines.

- **BC4 Where it isn't.** Set `VFArenaOn` to false, `VFMatchFormat` to `competitive` and `VFArenaOn`
  to true. Once a round's live, get killed and watch a bot of yours: the line reads
  `You play from the next round`, with no `F  take control`, and F does nothing. Do the same with
  `VFMatchFormat` set to `swiftplay`: the line's back, and F takes the bot over. In either, once a
  round's decided, the line's back to `You play from the next round` until the next. Then set
  `VFArenaOn` to false, `VFArenaMode` to `teamdeathmatch` and `VFArenaOn` to true, and get killed:
  while you watch a bot of yours, the line reads `You come back in a moment`, with no
  `F  take control`. **Send:** what the line read in each.

- **BC5 Two at once (optional).** This needs three players. Stop the game, start a Local Server with
  3 players, and start the spike rounds from the server's command bar as in BC2, after
  `VFMatchFormat` `standard`. Tab shows who's on player 1's side: player 3 should be, with three
  bots; if not, use whichever two players share a side, and their names below. Once the round's
  live, get players 1 and 3 killed (player 2 shoots them, or they walk into the other side's bots),
  and in windows 1 and 3 left- or right-click until both watch the same bot. Then run this in the
  server's command bar, which presses F for both at once:

  ```lua
  for _, name in { "Player1", "Player3" } do
  	game.Players[name]:SetAttribute("VFTestTake", true)
  end
  ```

  One of them plays on in the bot's body. The other's line reads `Taking control` for a moment, then
  their view moves on, and they stay down for the round: their `VFAlive` stays false, nothing of
  theirs stands anywhere, and their side has as many alive as before the takeover. **Send:** which
  of them got it, and what the other saw.

## 67. Agent bodies

From [63-agent-bodies.md](research/63-agent-bodies.md). System 63 draws other players and bots as an
agent's body: a copy of the rigged model in ReplicatedStorage's `VFBodies` folder (the one named
`Default`, or else the first), 1.75 m tall, its bones posed every frame from what the snapshots say
each one is doing, its head kept in the head box, and what it holds in its right hand. Their blocks
stay on the hitboxes, unseen; with no body in `VFBodies` they're drawn as blocks, as before.
Practice dummies are always blocks. In Studio, Workspace's `VFBodyMs`, read in a player's command
bar, is the milliseconds the bodies take of each of that player's frames, on average over the last
second.

Put the body in place first, with the game stopped: in the Explorer, insert a Folder into
ReplicatedStorage, name it `VFBodies`, and move the imported rig, `Superhero_Male_A`, into it from
Workspace. Then start a Local Server with 2 players, as in section 9. Player 2 plays on the course 5
to 10 m in front of player 1, and window 1 watches.

- **AB1 Standing.** In window 1, player 2 is the body, not blocks: about as tall as the blocks were,
  with no red block showing, no Roblox avatar, and their name and health over the head. In window 2,
  buy a Vandal (B) and stand still: it's at the shoulder in both hands, the left hand under the
  barrel and the left foot ahead, the body breathing. Press F10 in window 1: the green outlines are
  round the body, its head inside the head box. In window 2, look straight up and straight down,
  then hold Ctrl and do it again: the body crouches, the gun and the head follow the aim, and the
  head stays inside its box. Run `print(workspace:GetAttribute("VFBodyMs"))` in window 1's command
  bar. **Send:** whether the head ever left its box, how the stance looked, and the number.

- **AB2 Moving.** In window 2, run ahead, back, left, right and diagonally, then walk (Shift) and
  crouch-walk the same ways, stopping in between. In window 1: the legs step with the speed,
  quicker running, and a foot that's down stays where it's put, sliding a little only running
  sideways; the hips turn toward the way player 2 moves while the chest and the gun keep facing the
  aim; and the feet come to stand where they stop. Standing still in window 2, turn a little with
  the mouse, then slowly a quarter turn: on the little turn the feet stay put and the hips turn a
  touch with it; on the quarter turn the feet step round after it, lifting a little, the one on the
  side it turns to first, until they stand square again. Jump on the spot, then jump up onto the
  red 0.70 m jump box and step off it: the legs tuck, the left higher, and as they land the knees
  bend a moment and the head dips a little. Pick Jett (T, or set `VFTestAgents` to true,
  `VFTestAgent` to `jett`, then `VFTestAgent` to `lock`) and hold Space in the air: the legs hang
  together, the toes pointed. **Send:** anything that looked wrong, and which way player 2 was
  moving.

- **AB3 Holding.** In window 2, draw the Vandal (1), the Classic (2) and the knife (3) in turn,
  waiting a moment after each, then fire a few rounds from each gun and reload it (R). In window 1:
  the Classic is out in front in both hands; the knife is low in the right hand, the left up in
  front of the chest; at each switch the hands go from the old hold to the new without a snap, and
  the new weapon comes up from pointing down; each shot kicks the gun up and back a little, and it
  settles again; reloading, the left hand goes down to the magazine, pulls it out, puts it back and
  returns to the barrel, taking the whole reload, with no jump at its start or end. Pick Sage (T)
  and press Q: player 2 holds the Slow Orb's glowing piece up in the right hand. **Send:** anything
  that looked wrong.

- **AB4 The spike.** In window 2, pick up the spike (it waits 4 m behind the spawn), draw it (4) and
  hold 4 in a site's plant area until it's planted, standing; then hold F by it to defuse it,
  crouched. In window 1: planting, both hands go down in front, to about the waist's height standing
  (the head stays in the standing head box), and the spike in hand isn't drawn meanwhile; defusing
  crouched, nothing's in the hands and they go down onto the spike's raised cap, at its near rim,
  working a little, the head in the crouched head box. **Send:** anything that looked wrong.

- **AB5 Hits, a Shade and a force field.** In window 1, shoot player 2 a few times, with Dummy 1 not
  between you (down the lane it takes the shots first): the whole body flashes white with each hit.
  In window 2, pick Omen (T) and send him 25 m down the target lane
  with From the Shadows, as in FS4: while he's a Shade there, window 1 sees the body dark and
  see-through, then whole again as he forms. In window 1, press P three times (Skirmish, the 1v1,
  then gun game) and kill player 2: as they come back, the body's drawn as a force field until
  their spawn protection ends. **Send:** anything that looked wrong.

- **AB6 Bots.** Stop the game and start a Local Server with 1 player. In the server's command bar,
  set `VFMatchMap` to `outpost`, `VFArenaMode` to `spike` and `VFArenaOn` to true, as in section 65.
  In the buy phase your side's four bots are bodies, standing with their Classics; once the round's
  live they run off together, their legs keeping up. A bot that plants or defuses in view is drawn
  as in AB4, its gun put away. Run this in the player's command bar: it prints, every second for
  30 s, how many bodies are drawn and what they cost:

  ```lua
  for _ = 1, 30 do
  	local bodies = 0
  	for _, entity in workspace.VFPlayers:GetChildren() do
  		if entity:FindFirstChildWhichIsA("Model") then
  			bodies += 1
  		end
  	end
  	print(bodies, workspace:GetAttribute("VFBodyMs"))
  	task.wait(1)
  end
  ```

  Looking away from the bodies, the cost drops: a body off the screen isn't posed. Then get killed
  and watch a bot of yours: the one you watch isn't drawn, and the others are. **Send:** the
  highest pair of numbers, the cost looking away, and the F3 panel's `fps` with the bodies in view
  and looking away from them.

- **AB7 Without a body (optional).** With AB6's game still running, run this in the server's
  command bar: `game.ReplicatedStorage.VFBodies.Parent = game.ServerStorage`. Within a second the
  bots are drawn as red blocks, as before. Then run
  `game.ServerStorage.VFBodies.Parent = game.ReplicatedStorage`: within a couple of seconds they're
  bodies again, and stay bodies. The place isn't changed, as the game's copy of it goes when the
  game stops. **Send:** whether the blocks came, and then the bodies again.

## 68. The 1v1

From [64-duel.md](research/64-duel.md). System 64 plays Skirmish's rounds one a side, first to 10,
on the map built in the place, Workspace's `1v1Map`, with its spawn rooms `Spawn1` and `Spawn2`.

- **DU1 Alone, against a bot.** Start a solo Play. Press P twice (Skirmish, then the 1v1). The
  output says `[VF] Arena on: 1v1, on Workspace's 1v1Map`. You're in `Spawn1`'s room facing its door,
  which has an orange barrier for the 15 s buy phase; the top bar says ROUND 1, FIRST TO 10; the
  minimap draws the map. As the round goes live the barrier goes, and a bot comes from the other room
  through its door (teal barrier). Whoever dies loses the round; 3 s later both are back in their
  rooms for a 3 s buy phase. **Send:** anything that looked wrong.

- **DU2 Two players.** Start a Local Server with 2 players. In window 1 press P twice. There's no bot:
  one of you is in each room. Win a round each. **Send:** the score after two rounds, and whether
  either of you got through a barrier in a buy phase.

## 69. Bots' agents

From [65-bots-agents.md](research/65-bots-agents.md). System 65 has each bot play an agent: it picks
one in the agent select window after every player, one nobody on its side has locked in or selected,
and its kit is a player's, kept from one life to the next. Every ability treats a bot as a player: a
flash blinds it and Paranoia nearsights it, and while it's blinded or nearsighted it doesn't see
you; a Healing Orb heals an allied bot; a Recon Bolt and Hunter's Fury leave bots on the caster's
side be. Their casting is system 66's (section 70).

Start a Local Server with 1 player, as in section 9. This script, for the server's command bar,
prints each bot: side, agent, what it's selected, where its pick stands, its kit, its ultimate, and
a blind or a nearsight on it (nil for none):

```lua
for _, bot in game.ReplicatedStorage.VFBots:GetChildren() do
	local line = { bot.Name }
	for _, key in { "VFArenaSide", "VFAgent", "VFAgentSelected", "VFAgentPick", "VFKit", "VFUlt", "VFBlind", "VFNearsight" } do
		table.insert(line, tostring(bot:GetAttribute(key)))
	end
	print(table.concat(line, "  "))
end
```

- **BK1 Picks.** In the server's command bar, set `VFMatchMap` to `outpost`, `VFArenaMode` to
  `spike` and `VFArenaOn` to true, as in section 65. Within the first 10 s of round 1's buy phase,
  run the script: every bot reads `open`, with an agent selected, and no two on a side have selected
  the same. Note one your side's bots selected, open agent select (T) if it isn't up, and in the
  player's command bar set `VFTestAgent` to that agent's id (`omen`), then to `lock`, and run the
  script again: that bot has selected another. Once the window's closed, run it again: every bot
  reads `locked`, its agent what it selected, and each side's agents are all different, yours among
  them. Hold Tab: each bot's row has its agent's letters, and so do the top bar's tiles. **Send:**
  the script's lines before and after the window closed, and what the scoreboard showed.

- **BK2 The kit.** Go on with BK1's match. Every bot's `VFKit` starts `E1`, its signature's free
  charge (the agent's), and its `X` points with the round's. Set `VFMatchSkip` to true to end the
  buy phase and let the round play out, then run the script as the next buy phase starts, and again
  after round 2: a bot that got a kill has more points than one that didn't, and `VFUlt` matches
  `VFKit`'s `X`. **Send:** the script's lines after each round.

- **BK3 Blinded and nearsighted.** Set `VFArenaOn` to false, `VFArenaMode` to `skirmish` and
  `VFArenaOn` to true: you and a bot of yours against two bots. Pick Phoenix (T). Once the round's
  live, wait behind cover for the other side's bots; as they come into sight, 10 m away or more,
  throw the Curveball (E, then click) so it pops in front of them, and step out at once, standing
  still in front of them: for about a second neither shoots. Run the script straight after: their
  `VFBlind` isn't nil. In another round pick Omen, send Paranoia (Q, then click) through them as
  they come, and walk at them: they don't shoot until you're close. **Send:** whether they shot
  while blinded, the `VFBlind` lines, and about how close you were when the nearsighted bots shot.

- **BK4 Allies.** Go on in Skirmish. Pick Sage, let your bot get hurt in a fight, then look at it
  and press E and click: in the player's command bar,
  `print(game.Players:GetPlayers()[1]:GetAttribute("VFLastHeal"))` prints its name, `BOT` and all.
  Pick Sova, and loose a Recon Bolt (E, hold and let go of the left button) where your bot and the
  other side's are both in its sight: `VFLastRecon` on you has only the other side's names. Once X's
  full, cast Hunter's Fury (X, then click) through your bot at the other side's: `VFFuryHits` has
  only theirs. **Send:** the three printed lines.

## 70. Bots' abilities

From [66-bots-abilities.md](research/66-bots-abilities.md). System 66 has each bot cast its agent's
abilities when a player on that agent would: attackers look over a site with the Recon Bolt before
they push, then smoke, flash, burn or shock the spots that hold their way in; defenders look for the
attackers early, and stall a way in that attackers have just shown at; a bot guarding the planted
spike answers a defuse; and a bot on Sage heals itself and hurt teammates once it's quiet. Every
throw is flown through the level first, so it lands where the bot means it to and keeps off its own
side. In each buy phase of the spike rounds, after its guns and shield, a bot buys charges of the
abilities it casts. In Studio each bot's `VFBotCast` names the last ability it cast and for what,
as `darkcover push:darkcover:1`: the ability, then the moment (`gather`, `push`, `hold`, `stall`,
`defuse`, `heal`, `fury` or `storm`).

Start a Local Server with 1 player, as in section 9, and set the spike rounds going on Outpost from
the server's command bar, as in BT1: `VFMatchMap` `outpost`, `VFArenaMode` `spike`, then
`VFArenaOn` true. You attack in the first half. Stay back and watch the bots unless a check says
otherwise. This script, for the server's command bar, prints each cast as a bot starts it, for 4
minutes: the seconds since it was run, the bot, its side (`A` attacking, `D` defending), its agent,
its job and the cast. A cast made again straight after (a second heal) doesn't print again.

```lua
local started = os.clock()
local connections = {}
local function watch(bot)
	table.insert(connections, bot:GetAttributeChangedSignal("VFBotCast"):Connect(function()
		local attackers = workspace.VFArena:GetAttribute("Attackers")
		local side = if bot:GetAttribute("VFArenaSide") == attackers then "A" else "D"
		local when = string.format("%5.1f", os.clock() - started)
		print(when, bot.Name, side, bot:GetAttribute("VFAgent"), bot:GetAttribute("VFBotTask"), bot:GetAttribute("VFBotCast"))
	end))
end
for _, bot in game.ReplicatedStorage.VFBots:GetChildren() do
	watch(bot)
end
table.insert(connections, game.ReplicatedStorage.VFBots.ChildAdded:Connect(watch))
task.delay(240, function()
	for _, connection in connections do
		connection:Disconnect()
	end
	print("done")
end)
```

- **BU1 Charges.** 5 s into round 1's buy phase, while agent select is open, run section 69's
  script: no bot has a charge past its free one yet, as its kit changes when its agent is locked
  in. Run it again once agent select has closed (every bot's `VFAgentPick` reads `locked`): each
  bot's `VFKit` has charges past its free one where its agent has an ability it casts that it could
  pay for (Jett's `C`, Phoenix's `Q` or a second `E`, Sage's `C` or `Q`, Omen's `Q` or a second
  `E`, Sova's `Q`). Set `VFMatchSkip` to true, let round 1 play out, and run it again 5 s into
  round 2's buy phase: a bot that bought a primary has spent what was left on charges, and one
  saving for a full buy has bought none. **Send:** the script's lines in each buy phase.

- **BU2 The push.** Run the cast script as round 3's buy phase ends, and stay in your spawn while
  the attacking bots go. A Sova among them, carrying the spike or not, prints `gather:reconbolt` as
  they gather short of the site, or on its way in as the push goes if it wasn't there yet, and the
  rest print `push:` casts as they go in (`push:darkcover:1`, `push:cloudburst`, `push:curveball`,
  `push:hothands` and so on); the defenders print `hold:reconbolt` 8 to 30 s into the round. Then
  follow the attackers at a distance as they go in: Dark Cover and a cloud land on the spots inside
  their way in, not in the open short of it, and a Curveball pops round the corner, not in front of
  them. The bot that throws it stands where it threw it until it's popped, and the bots with it turn
  their backs on it. Run section 69's script straight after a flash: no attacker's `VFBlind` has
  anything more than a trace (white for 0.25 s at the most). Then set `VFArenaOn` to false and back
  to true, and run the cast script as the new round 1 goes live: no defender prints a `push:` cast
  before the spike's planted, and the attackers gather before they push, as at the first start.
  **Send:** the cast script's lines, and what the smokes and flashes looked like.

- **BU3 A stall.** In a later round, go ahead of the attacking bots to a way into a site, step out
  where its defenders see you for a second, and step back out of sight. Within a few seconds a slow,
  a molly, a wall, a smoke or a cloud lands at that way in (whichever the defenders there have), and
  the cast script prints a defender's `stall:` cast. **Send:** what came, and how long after you
  showed.

- **BU4 The defuse.** Let rounds play out with the spike planted, staying back: as a defending bot
  starts its defuse, a guarding attacker with one prints `defuse:huntersfury`, `defuse:hothands` or
  `defuse:shockbolt`, and the defuser is hurt or stops. The defenders print `push:` casts as they
  retake. **Send:** the guards' lines and what happened to the defuser.

- **BU5 A heal.** Set `VFArenaOn` to false, `VFArenaMode` to `skirmish` and `VFArenaOn` to true,
  and again until a bot of the other side is on Sage (section 69's script). Run the cast script,
  hurt that bot to about half its health without killing it, and get out of its sight: within about
  5 s the script prints `healingorb heal` for it, and in the server's command bar, with its name as
  the script printed it,
  `print(game.ReplicatedStorage.VFBots["<its name>"]:GetAttribute("VFLastHeal"))` prints its own
  name, `BOT` and all. **Send:** the lines.

- **BU6 What they cost.** Set `VFMatchMap` to `wharf`, `VFArenaMode` to `spike`, `VFArenaOn` to
  false and then true. In a live round with nine bots, as the attackers push, run
  `print(workspace:GetAttribute("VFBotMs"))` a few times: well under the frame's 16.7, and near
  BT8's. The Output has no errors or warnings from the bots. **Send:** the numbers, and whether any
  bot's throw hit its own side in any of these checks.

## 71. Ranks and careers

From [67-competitive-ranks.md](research/67-competitive-ranks.md). System 67 ranks Competitive's
players as the reference does: five placement matches, then RR won and lost each match, promotions,
demotions and rank shields, by a hidden MMR. Every mode keeps each player's record, saved with the
rank in a data store. Each player's `VFRankTier` (0 while placing; 9 is Silver 3 and 10 Gold 1),
`VFRankRR`, `VFRankGames`, `VFRankShields`, `VFRankLast` and `VFRankNote` say their rank and what
the last match did to it, and in Studio `VFRankMmr` their MMR; each result prints a `[VF] career:`
line in the server's Output. Studio can't use the data store unless the place lets it use API
services, and a Local Server's test players never do, so in these checks a career lasts the session,
each test starts from placements, and `VFCareerStatus` says why (`off: a test player`); only RK6
needs the store.

Start a Local Server with 2 players, as in section 9. In the server's command bar set Competitive
going on Outpost: `VFMatchMap` `outpost`, `VFMatchFormat` `competitive`, `VFArenaMode` `spike`, then
`VFArenaOn` true. Each player's side is their `VFArenaSide`. Run this script in the server's command
bar first, then each check's lines on their own: `play(n)` plays the match under way (or the next,
from a victory screen) to its end in a few seconds, side 1 winning 13 to `n` (`VFMatchDecide` gives
each round to a side), and `rounds(side, n)` gives the next `n` rounds to a side.

```lua
local arena = workspace.VFArena
local function step(side)
	local phase = arena:GetAttribute("Phase")
	if phase == "buy" or phase == "live" then
		workspace:SetAttribute("VFMatchDecide", side)
		return true
	elseif phase == "roundOver" or phase == "vote" then
		workspace:SetAttribute("VFMatchSkip", true)
	end
	return false
end
function play(n)
	task.spawn(function()
		while arena:GetAttribute("Phase") == "matchOver" do
			workspace:SetAttribute("VFMatchSkip", true)
			task.wait(0.3)
		end
		while arena:GetAttribute("Phase") ~= "matchOver" do
			step(if (arena:GetAttribute("Score2") or 0) < n then 2 else 1)
			task.wait(0.3)
		end
		print("over", arena:GetAttribute("Score1"), arena:GetAttribute("Score2"))
	end)
end
function rounds(side, n)
	task.spawn(function()
		while n > 0 do
			if step(side) then
				n -= 1
			end
			task.wait(0.3)
		end
		print("done", arena:GetAttribute("Score1"), arena:GetAttribute("Score2"))
	end)
end
```

- **RK1 Placements.** Run `play(5)` and wait for the victory screen, five times. After each, the
  Output has a `[VF] career:` line for each player, `competitive won` for side 1's and
  `competitive lost` for side 2's, and each player's victory screen has `PLACEMENT 1 OF 5` under the
  time left, then 2, and so on, as the screen comes and without changing after. After the fifth it
  reads `PLACED` with a tier and `50 RR`, in green, and `VFRankTier` is from 1 to 21: side 1's
  player higher than side 2's. **Send:** the Output's lines, and the tier each was placed in.

- **RK2 What a match is worth.** Run `play(11)`: side 1's player's victory screen has their tier,
  their RR and the RR it was worth, `(+10)` to `(+50)`, or reads `PROMOTED`, and side 2's a loss
  of 30 at most, `(-30)`. Then run `play(0)`: side 1's player gains more than for the 13-11, and
  side 2's loses more. **Send:** the four lines.

- **RK3 Promotions, demotions and shields.** Run `play(5)` until side 1's player reads `PROMOTED`
  (their `VFRankRR` 10 or more) and side 2's has gone down to 0 RR and then reads `DEMOTED`
  (`VFRankRR` 70 or more), or `A SHIELD KEPT THE RANK` if they're in a Tier 1 (a tier whose number
  is 4, 7, 10, 13, 16 or 19) entered by a promotion or a demotion. **Send:** those lines and the
  matches it took.

- **RK4 The Play menu.** Press M as each player: Competitive's card has their tier and RR in gold,
  and every other card's line is empty. Close it, and in the server's command bar set
  `VFMatchFormat` to `swiftplay`, `VFArenaOn` to false and back to true, and run `play(2)`: the
  Output's `[VF] career:` lines, `swiftplay won` and `swiftplay lost`, come as the victory screen
  does. Press M again: Swiftplay's card reads `1W 0L` and a K/D for side 1's player, and `0W 1L` for
  side 2's; Competitive's still has the rank. **Send:** what the cards say.

- **RK5 Leaving.** Set `VFMatchFormat` to `competitive`, `VFArenaOn` to false and back to true, and
  run `rounds(1, 3)`. Then close side 2's player's window: as they go, the Output has a `[VF]
  career:` line for them, `competitive lost` and the RR it cost. Run `play(5)`: the line for the
  match's end is side 1's player's alone. **Send:** both lines.

- **RK6 Kept (optional, with the place's data stores on).** This needs a live server, or the place's
  Studio access to API services (Game Settings, Security), which is the place owner's call, and your
  own account: press Play (F5), as a Local Server's test players keep nothing. With the Test tab's
  Client and Server button on Server, set Competitive going as above, run the script and play a
  match to its end with `play(5)`. Wait for `VFCareerStatus` to read `saved`, stop, and press Play
  again: `VFCareerStatus` reads `loaded`, and the rank, `VFRankGames` and the Play menu's lines are
  as they were. **Send:** the attributes before and after.

## 72. A controller

From [68-controller.md](research/68-controller.md). System 68 plays the game with a gamepad, on the
console version's layout: the left stick moves, walking when it's tilted only a little, and the
right turns the view; RT fires; LT held is Focus, the view turning slower, or a sniper's scope, and
LT with RS aims down sights; A jumps, X reloads, L3 crouches until it's pressed again, and RS is F;
LB, RB and B cast Q, E and C, and LB and RB together the ultimate; Y swaps guns, and held draws the
knife. D-pad Up pings (held, the wheel), Left drops, Down is 4 and Right is B. Select tapped opens
or shuts the big map, held shows the scoreboard, and with D-pad Up, Left, Right or Down opens or
shuts the Play menu, agent select, the settings or the combat report. In a menu the pad drives
Roblox's gamepad cursor, and B shuts the menu.

No controller is needed but for PD8: a string attribute `VFTestPad` on the local player stands in
for one, held as it says until it's changed or cleared: the left stick's x and y (up is positive y),
the right's, LT and RT from 0 to 1, then the buttons held, by the names `a`, `b`, `x`, `y`, `lb`,
`rb`, `l3`, `r3`, `up`, `down`, `left`, `right` and `select`, all apart by spaces. The local
player's `VFPad` says what the pad is doing each frame, as the client sees it: `off` while it isn't
in use, else its `flags` added up (1 W, 2 S, 4 A, 8 D, 16 walking, 32 crouching, 64 jump, 128
fire, 256 the right button, 512 reload, 1024 the spike's 4, 2048 G, 4096 C, 8192 Q, 16384 E, 32768 X
and 65536 F), the `zoom` LT wants (`-` where it leaves the zoom be), the zoom the client predicts
(`scoped`, 0 for none), `focus` 1 in Focus, the `turn` this frame in the mouse's counts (right and
down positive), and `cursor`: `on` while Roblox's gamepad cursor is up, `pick` with a menu's button
picked for the D-pad, else `off`.

Press Play (F5), with one player, as Jett (her card in agent select, T, if you've picked another).
Start at the spawn facing down the target lane with the Vandal in hand, and clear `VFTestYaw` and
`VFTestPitch` if they're set. Set `VFTestMute` on the local player if the sound's not wanted. Run
this once in the command bar with it on the client, then each check's lines on their own there:
`pad(s, t)` holds the pad as `s` says for `t` seconds (0.3 if left out) and prints `s`, then `VFPad`
and `VFKit`, leaving the pad held; `let()` lets everything go; `turn(s, t)` holds `s` for `t`
seconds, lets go, and prints how far the view turned, in degrees to the right and up;
`set(name, value)` sets one of the local player's attributes; and `gui(name, key)` prints an
attribute of one of PlayerGui's screens. `pad(nil, 0.1)` clears `VFTestPad` and gives the mouse and
keys back.

```lua
local me = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
function pad(s, t)
	me:SetAttribute("VFTestPad", s)
	task.wait(t or 0.3)
	print(s, "->", me:GetAttribute("VFPad"), me:GetAttribute("VFKit"))
end
function let()
	pad("0 0 0 0 0 0", 0.2)
end
local function heading()
	local look = cam.CFrame.LookVector
	return math.deg(math.atan2(look.X, -look.Z)), math.deg(math.asin(look.Y))
end
function turn(s, t)
	me:SetAttribute("VFTestPad", s)
	local yaw, pitch = heading()
	local right, up, start = 0, 0, os.clock()
	while os.clock() - start < t do
		task.wait()
		local y, p = heading()
		right += (y - yaw + 540) % 360 - 180
		up += p - pitch
		yaw, pitch = y, p
	end
	me:SetAttribute("VFTestPad", "0 0 0 0 0 0")
	print(string.format("%s: %.0f degrees right, %.0f up in %.1f s", s, right, up, t))
end
function set(name, value)
	me:SetAttribute(name, value)
end
function gui(name, key)
	print(name, key, me.PlayerGui[name]:GetAttribute(key))
end
```

- **PD1 Moving.** `pad("0 1 0 0 0 0", 1)`: you run ahead down the lane, the HUD's speed at 5.40, and
  the line reads `flags=1 zoom=0 scoped=0 focus=0 turn=0.0,0.0 cursor=off`. `let()`: you stop,
  `flags=0`. `pad("0 0.45 0 0 0 0", 1)`: you walk ahead, at 3.29, `flags=17`.
  `pad("-0.7 -0.7 0 0 0 0", 1)`: back and to the left at once, `flags=6`. `let()`, then
  `pad(nil, 0.1)`: the line reads `off`, and the mouse and keys move you again. The Output has no
  `[VF] Roblox's default controls are still on` line since Play. **Send:** the lines.

- **PD2 Looking.** Run `set("VFTestPitch", 0)` and then, on its own, `set("VFTestPitch", nil)`, so
  the view's level. `turn("0 0 0.5 0 0 0", 1)`: about 40 degrees right and 0 up.
  `turn("0 0 1 0 0 0", 0.2)`: about 40 too, in a fifth of the time, as the stick's curve has full
  tilt turning five times as fast as half. `turn("0 0 1 0 0 0", 1)`: about 330, as held all the way
  over for 0.2 s the turn speeds up to 1.8 times as fast over the next 0.25 s.
  `turn("0 0 0 1 0 0", 0.2)`: about 40 up, 0 right. `set("VFTestSetting", "padInvert=1")` and the
  same again: about 40 down (`-40 up`); then `set("VFTestSetting", "padInvert=0")`.
  `set("VFTestSetting", "padLook=110")`: `turn("0 0 0.5 0 0 0", 1)` reads about 20; then
  `set("VFTestSetting", "padLook=220")`, and level the view again as at the start. **Send:** the six
  lines.

- **PD3 Focus and the sights.** With the Vandal in hand, `pad("0 0 0 0 0 1")`: the Vandal fires, the
  line reading `flags=128`; `let()`. `pad("0 0 0 0 1 0")`: no zoom, and the line reads
  `zoom=0 scoped=0 focus=1`. Holding LT, `turn("0 0 0.5 0 1 0", 1)`: about 20 degrees, half
  PD2's 40. `pad("0 0 0 0 1 0 r3")` and `pad("0 0 0 0 1 0")`: the sights come up, the view zooming
  in a little, and the line reads `zoom=1 scoped=1 focus=0`. The same two again: the sights go,
  `zoom=0 scoped=0 focus=1`. The two once more, then `turn("0 0 0.5 0 1 0", 1)`: about 32
  degrees, 0.8 of the 40, as the mouse turns 0.8 as far in the Vandal's sights. LT's let go as it
  ends: `let()` prints `zoom=0 scoped=0 focus=0`, the sights down. **Send:** the lines.

- **PD4 A sniper's zooms.** `set("VFTestGive", "operator")`, and once the Operator's in hand:
  `pad("0 0 0 0 1 0", 0.5)`: the scope comes up, `zoom=1 scoped=1`. `pad("0 0 0 0 1 0 r3")` and
  `pad("0 0 0 0 1 0")`: the second zoom, `zoom=2 scoped=2`. The same again: back to the first,
  `zoom=1 scoped=1`, with `scoped` never 0 on the way. `let()`: the scope's down at once,
  `zoom=0 scoped=0`. `pad("0 0 0 0 1 0", 0.5)` and `let()`: in to the first zoom and straight out,
  `scoped` going from 1 to 0 with no frame of 2 between, as LT let go lets the zoom go.
  `set("VFTestGive", "vandal")` puts the Vandal back. **Send:** the lines, and the zoom frame by
  frame on the way out of the first and back from the second.

- **PD5 Jett's abilities.** Watch the bar at the bottom and `VFKit` at the end of each line.
  `pad("0 0 0 0 0 0 lb")` and `let()`: Updraft throws you up, a moment after LB goes down, `Q0/1`
  (U2). `pad("0 0 0 0 0 0 rb")` and `let()`: Tailwind's gust readies, `E0/1` with `windup`; once it
  reads `ready`, the same again dashes (U4, U5). Once `Q1/1`'s back, `pad("0 0 0 0 0 0 lb", 0.03)`
  and `let()`: a tap shorter than the bumpers' wait for each other casts Updraft as it's let go.
  `pad("0 0 0 0 0 0 lb rb")` and `let()`: Blade Storm, the knives drawn and `X0/8 storm`, with
  neither Updraft nor a gust. After a second, `pad("0 0 0 0 0 1", 0.1)` and `let()` throws one
  knife, and `pad("0 0 0 0 1 0", 0.1)` and `let()` the rest. `pad("0 0 0 0 0 0 b")` and `let()`:
  Cloudburst thrown ahead, curving a little as B's held, `C1/2`. **Send:** the lines.

- **PD6 Guns and the spike.** `pad("0 0 0 0 0 0 y", 0.1)` and `let()`: the Classic comes up; the
  same again, the Vandal. `pad("0 0 0 0 0 0 y", 0.5)` and `let()`: the knife, a quarter of a second
  after Y goes down; a tap of Y brings the Vandal back. `pad("0 0 0 0 0 0 l3", 0.1)` and `let()`:
  you crouch, and the line stays `flags=32` with nothing held; the same again stands you up,
  `flags=0`. `pad("0 0 0 0 0 0 a", 0.1)` and `let()`: a jump. `pad("0 0 0 0 0 1", 0.5)` and `let()`
  fires a few rounds, then `pad("0 0 0 0 0 0 x", 0.1)` and `let()` reloads them.
  `pad("0 0 0 0 0 0 left", 0.1)` and `let()`: the Vandal drops ahead and the Classic comes up.
  `set("VFTestPitch", -53)`: looking down at the Vandal, 1.2 m ahead, the prompt under the crosshair
  reads `RS  PICK UP VANDAL`, and after `pad(nil, 0.1)` `F  PICK UP VANDAL`.
  `pad("0 0 0 0 0 0 r3", 0.1)` and `let()` picks it up, and the Vandal's drawn.
  `set("VFTestPitch", nil)`.
  `set("VFTestGive", "spike")`, then `pad("0 0 0 0 0 0 down", 0.5)`: the spike comes up in hand and
  the line reads `flags=1024`, with nothing started outside a site; `let()`.
  `pad("0 0 0 0 0 0 left", 0.1)` and `let()`: the spike drops, and
  `print(workspace:GetAttribute("VFSpike"))` reads `dropped`. **Send:** the lines.

- **PD7 Pings, menus and the big map.** `set("VFTestPitch", -30)`. `pad("0 0 0 0 0 0 up", 0.1)` and
  `let()`: a ping on the floor ahead, `gui("VFPings", "Shown")` printing `HERE 3m`.
  `pad("0 0 0 0 0 0 up", 0.5)`: the wheel's up, `gui("VFPings", "Wheel")` printing `open`;
  `pad("0 0 0 1 0 0 up")`: `DANGER` lights, and `gui("VFPings", "Wheel")` prints `danger` (the
  line's `turn` is then the wheel's pick moving, not the view); `let()`:
  a `DANGER` marker on the floor ahead. `set("VFTestPitch", nil)`. `pad("0 0 0 0 0 0 right", 0.1)`
  and `let()`: the buy menu, and the line reads `flags=0` and `cursor=on`, with Roblox's gamepad
  cursor in the middle of the screen, or `cursor=pick` with a button picked, or `cursor=off`.
  `pad("0 0 0 0 0 0 b", 0.1)` and `let()`: the menu's shut, and no Cloudburst thrown (`VFKit`'s C as
  it was). `pad("0 0 0 0 0 0 select right", 0.1)` and `let()`: the settings menu, with the
  CONTROLLER section at the bottom: `Look speed` 220, `Focus speed` 0.5, `Invert look` and
  `Walk in Focus` OFF, and the layout under them; B shuts it, and the big map and the scoreboard
  haven't come up. The same with `select up` in place of `select right`: the Play menu, and B shuts
  it; with `select left`, agent select, and B shuts it; and with `select down`, the combat report,
  which `select down` again hides. Then `set("VFTestPlay", "skirmish")`: you're in Skirmish, a bot
  with you and two against you. `pad("0 0 0 0 0 0 select", 0.1)` and `let()`: the big map,
  `gui("VFMinimap", "Big")` printing `true`; `pad("0 0 0 0 0 1", 0.1)` and `let()`: a ping on the
  map where its cursor is, `gui("VFMinimap", "Pings")` having `map`, and no shot fired; Select
  tapped again shuts it. `pad("0 0 0 0 0 0 select", 1)`: the scoreboard, from a quarter of a second
  in; `let()` and it goes, with no big map. Once round 1 is live, walk at the other side's bots
  (`pad("0 1 0 0 0 0", 3)`, and steer with the right stick) and let them kill you: watching your
  side's bot, the line under its name reads `RS  take control`, and `pad("0 0 0 0 0 0 r3", 0.1)` and
  `let()` takes it over, as F does (BC1): the server's Output has `[VF] takeover:` lines, `asked`
  and then `into` the bot's body, or else why not. **Send:** the lines, the `[VF] takeover:` lines,
  which `cursor` the buy menu had, and anything that didn't open or shut.

- **PD8 A real controller (optional).** With a controller plugged in or paired, play on the course
  and in Skirmish. The view's turn and Focus as they feel, and `padLook` and `padFocus` as you'd
  have them; whether the prompts read `RS` and `HOLD D-PAD DOWN` while you use the pad and `F` and 4
  while you use the mouse and keys; whether Roblox's cursor comes up in the buy menu, moves with the
  left stick, buys with A and doesn't jump as the menu shuts, and B shuts it; and nothing from
  Roblox's own controls, nor its camera, nor its button picking on Select. **Send:** what felt off,
  and the cursor.

## 73. Rejoining a match

From [69-rejoining.md](research/69-rejoining.md). System 69 holds the place of a player who leaves
the spike rounds' match under way until the match ends: their record, side, credits (paid each round
as their side is) and agent wait for them, and a bot fills in meanwhile. Coming back, the Play
menu's PLAY reads RECONNECT, which puts them back on their side, the bot on their side giving way as
soon as it's down or nothing's at stake. In Competitive the loss for leaving waits for the match's
end: back in time for half its rounds, they get the match's result. A Local Server's players can't
come back once gone, so here Workspace's `VFTestAway`, set from the server to a player's UserId,
takes them out of the match as if they'd left. Each place held prints `[VF] place held:` in the
server's Output, and each let go `[VF] place let go:`.

Start a Local Server with 2 players, as in section 9, and set Competitive going on Outpost as in
section 71, with its script run in the server's command bar. Run this there too: `away(name)` takes
a player out, `show(name)` prints what the arena keeps on them, and `bots()` each bot's side and
agent.

```lua
function away(name)
	workspace:SetAttribute("VFTestAway", game.Players[name].UserId)
end
function show(name)
	local p = game.Players[name]
	print(name, "side", p:GetAttribute("VFArenaSide"), "line", p:GetAttribute("VFInLine"), "rejoin", p:GetAttribute("VFRejoin"),
		"credits", p:GetAttribute("VFCredits"), "agent", p:GetAttribute("VFAgent"))
end
function bots()
	for _, bot in game.ReplicatedStorage.VFBots:GetChildren() do
		print(bot.Name, bot:GetAttribute("VFArenaSide"), bot:GetAttribute("VFAgent"))
	end
end
```

- **RJ1 A place held.** Run `rounds(1, 2)`. In the next buy phase run `show("Player1")` and
  `bots()`, then `away("Player1")`: the Output has `[VF] place held: -1 in competitive`, player 1's
  character goes, and window 1's Play menu opens. Run `show("Player1")` again: no side,
  and `rejoin competitive`. Within a second, `bots()` lists a new bot on player 1's side, playing
  another agent than theirs while one's free; with five agents a side, as now, none is, and it plays
  theirs. **Send:** the lines.

- **RJ2 Back in a buy phase.** Run `rounds(2, 1)`, so player 1's away for a round, and wait for the
  next buy phase. In window 1 press M: Competitive's card is picked, the button reads RECONNECT, and
  the line under it `YOUR COMPETITIVE MATCH IS STILL ON: RECONNECT TO GET BACK IN`. Press RECONNECT:
  the menu shuts and player 1 spawns at once in their side's spawn, and the Output has
  `[VF] place let go: -1, back`. `show("Player1")` prints their side and agent as in RJ1, and their
  credits as then plus the round's pay; their abilities on the HUD are their agent's. `bots()` lists
  the bot that filled in gone. **Send:** the lines, and the credits before and after.

- **RJ3 Back during a round.** In a buy phase run `away("Player1")`, then
  `workspace:SetAttribute("VFMatchSkip", true)` so the round goes live, and press RECONNECT in
  window 1: the menu shuts and player 1 is first in line (`show` prints `line 1`), watching, their
  place still held. Run `rounds(1, 1)`: as the round ends the bot on their side leaves, the Output
  has `[VF] place let go: -1, back`, and player 1 spawns on their side for the next round. **Send:**
  the lines.

- **RJ4 The match's end, away.** In a buy phase run `away("Player1")`, then `play(5)`: the Output's
  `[VF] career:` line for `-1` reads `competitive lost`, and as the next match starts (after the
  victory screen and the vote) `[VF] place let go: -1, its match ended`. **Send:** the lines.

- **RJ5 The match's end, back in time.** Player 1 isn't in the new match: press PLAY in window 1 to
  join it, and run `show("Player1")` for their side, `s` below (PLAY can put them on either). Then
  run `rounds(s, 3)`, then in a buy phase `away("Player1")`, then `rounds(s, 1)`; in the next buy
  phase press RECONNECT in window 1, and run `rounds(s, 9)`, which wins the match for their side:
  the `[VF] career:` line for `-1` reads `competitive won`, not a leaver's loss. **Send:** the
  lines.

- **RJ6 Another server (optional, on a live server).** This needs the place published and played on
  Roblox, which is the place owner's call. Play Competitive from the Play menu, and a few rounds in,
  close Roblox. Join the game again: the menu has Competitive picked and RECONNECT, and pressing it
  puts you back in the match, on its server, with your record and credits. **Send:** whether
  RECONNECT came, and where it put you.

## 74. AFK

From [70-afk.md](research/70-afk.md). System 70 warns a player who stops playing in the spike
rounds' match under way: alive in a round, 90 seconds without playing at anything (a key pressed or
let go, a look, a weapon asked for, a buy or a ping) brings a red line across the top of the screen
counting down from 30, and if they still don't play they're taken out of the match, their place held
as for anyone who leaves (section 73): a bot stands in, and their Play menu opens on RECONNECT with
a line saying why. Dead or between rounds the time stops. AFK's off in Studio unless Workspace's
`VFTestAfk`, set from the server, has the seconds to warn after, and with it AFK counts with nobody
else playing too. The server's Output prints `[VF] AFK: <UserId> warned` and
`[VF] AFK: <UserId> taken out of the match`.

Start a Local Server with 1 player, and set Competitive going on Outpost as in section 71, with its
script run in the server's command bar, and section 73's too. In window 1's command bar run
section 72's script, for `pad`, `let` and `set`. Then in the server's command bar run
`workspace:SetAttribute("VFTestAfk", 15)` and `workspace:SetAttribute("VFPlayMenu", true)` (the
server then has players pick in the Play menu first, so it opens by itself as they're taken out; a
place may have it off, and the test's copy goes as the test ends), and this, which prints what the
server has of player 1's AFK:

```lua
function afk()
	local p = game.Players.Player1
	local at = p:GetAttribute("VFAfkAt")
	local left = if at then string.format("out in %.1f", at - workspace:GetServerTimeNow()) else "not warned"
	print("afk", left, "out", p:GetAttribute("VFAfkOut"))
end
```

- **AF1 Warned.** In a buy phase, leave window 1 alone: about 15 s on, the Output has
  `[VF] AFK: -1 warned`, window 1 has `INACTIVE: PLAY, OR YOU'RE TAKEN OUT OF THE MATCH IN 30` in
  red across the top, counting down, and `afk()` prints `out in` about 30. **Send:** the lines, and
  the seconds from the buy phase's start to the warning.

- **AF2 Playing takes it back.** While warned, run `pad("0 1 0 0 0 0", 0.2)` and `let()` in
  window 1: the line goes at once, and `afk()` prints `not warned`. Wait for the warning again, then
  `set("VFTestPitch", -10)`: the line goes again; `set("VFTestPitch", nil)`. In the next buy phase,
  once warned, `set("VFTestBuy", "ghost")`: the line goes. Then `pad("0 0 0 0 0 0 l3", 0.1)` and
  `let()` to crouch, and leave it: the warning comes 15 s on though the crouch is held, and the same
  again stands you up and takes it back. **Send:** the lines.

- **AF3 Dead or between rounds.** While warned, run `workspace:SetAttribute("VFMatchDecide", 2)`: as
  the round ends the line goes, and `afk()` prints `not warned` until the next buy phase, when the
  line's back counting on from about where it stopped, with no second `[VF] AFK: -1 warned` in the
  Output. **Send:** the seconds the line read as the round ended and as it came back.

- **AF4 Taken out.** Leave window 1 alone until the count runs out: the Output has
  `[VF] AFK: -1 taken out of the match` and `[VF] place held: -1 in competitive`, player 1's
  character goes, window 1's Play menu opens with Competitive's card picked, the button reading
  RECONNECT and the line under it `TAKEN OUT FOR BEING INACTIVE: RECONNECT TO GET BACK IN`, and
  `afk()` prints `out true`. With nobody else in the match it waits for players and its bots go, so
  `bots()` lists none (with two players, a bot stands in for player 1 as in RJ1). Run
  `set("VFTestPlay", "competitive")` in window 1, as RECONNECT: the menu shuts, the Output has
  `[VF] place let go: -1, back`, and `afk()` prints `out nil`. **Send:** the lines.

- **AF5 Off in Studio.** Run `workspace:SetAttribute("VFTestAfk", nil)` and leave window 1 alone
  through a whole round: no warning, and no `[VF] AFK:` line. **Send:** whether a warning came.

## 75. Touch controls

From [71-touch-controls.md](research/71-touch-controls.md). System 71 plays the game on a phone or a
tablet: a thumb on the left of the screen moves, as a stick that starts where it lands, walking
pushed only part of the way; a drag anywhere else turns the view, and so does FIRE's touch as it
moves. Round the right thumb are FIRE, AIM (right click), JUMP, CROUCH (on and off), RELOAD, C, Q, E
and X, USE (F), SPIKE (4, shown while the spike's carried), DROP (G), SWAP (tapped, the other gun;
held, the knife) and PING (Z); a second FIRE sits for the left thumb, and down the left are BUY,
MAP, SCORES, AGENTS, PLAY and SETTINGS. With a menu up only CLOSE shows. Dead, FIRE and AIM switch
who's watched and USE takes over the bot watched.

No touch screen is needed but for TC8: a string attribute `VFTestTouch` on the local player stands
in for one, held as it says until it's changed or cleared: the stick's x and y (up is positive y),
the look drag's speed right and up in screen heights a second, then the buttons held, by the names
`fire`, `fire2`, `aim`, `jump`, `crouch`, `reload`, `c`, `q`, `e`, `x`, `use`, `spike`, `drop`,
`swap`, `ping`, `buy`, `map`, `scores`, `agents`, `play`, `settings` and `close`, all apart by
spaces. The local player's `VFTouch` says what the touch screen is doing each frame: `off` while it
isn't in use, else its `flags` added up (as section 72's `VFPad`: 1 W, 2 S, 4 A, 8 D, 16 walking, 32
crouching, 64 jump, 128 fire, 256 the right button, 512 reload, 1024 the spike's 4, 2048 G, 4096
C, 8192 Q, 16384 E, 32768 X and 65536 F), the zoom the client predicts (`scoped`, 0 for none), the
`turn` this frame in the mouse's counts (right and down positive), `crouch` and `menu` 1 while
crouched and with a menu up, and the safe area's `size` in pixels.

Press Play (F5), with one player, as Jett. Start at the spawn facing down the target lane with the
Vandal in hand, and clear `VFTestYaw` and `VFTestPitch` if they're set. Set `VFTestMute` if the
sound's not wanted. Run this once in the command bar with it on the client, then each check's lines
on their own there: `touch(s, t)` holds the touch screen as `s` says for `t` seconds (0.3 if left
out) and prints `s`, then `VFTouch` and `VFKit`, leaving it held; `lift()` lets everything go;
`drag(s, t)` holds `s` for `t` seconds, lets go, and prints how far the view turned, in degrees to
the right and up; `set(name, value)` sets one of the local player's attributes; `gui(name, key)`
prints an attribute of one of PlayerGui's screens; and `buttons()` prints how many buttons show,
then each one's name, middle and width in pixels. `touch(nil, 0.1)` clears `VFTestTouch` and gives
the mouse and keys back.

```lua
me = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
function touch(s, t)
	me:SetAttribute("VFTestTouch", s)
	task.wait(t or 0.3)
	print(s, "->", me:GetAttribute("VFTouch"), me:GetAttribute("VFKit"))
end
function lift()
	touch("0 0 0 0", 0.2)
end
local function heading()
	local look = cam.CFrame.LookVector
	return math.deg(math.atan2(look.X, -look.Z)), math.deg(math.asin(look.Y))
end
function drag(s, t)
	me:SetAttribute("VFTestTouch", s)
	local yaw, pitch = heading()
	local right, up, start = 0, 0, os.clock()
	while os.clock() - start < t do
		task.wait()
		local y, p = heading()
		right += (y - yaw + 540) % 360 - 180
		up += p - pitch
		yaw, pitch = y, p
	end
	me:SetAttribute("VFTestTouch", "0 0 0 0")
	print(string.format("%s: %.0f degrees right, %.0f up in %.1f s", s, right, up, t))
end
function set(name, value)
	me:SetAttribute(name, value)
end
function gui(name, key)
	print(name, key, me.PlayerGui[name]:GetAttribute(key))
end
function buttons()
	local shown = {}
	for _, f in me.PlayerGui.VFTouch.Safe:GetChildren() do
		if f:IsA("Frame") and f.Visible and f.Name ~= "Stick" and f.Name ~= "Knob" then
			local c = f.AbsolutePosition + f.AbsoluteSize / 2
			table.insert(shown, string.format("%s %d,%d %d", f.Name, c.X, c.Y, f.AbsoluteSize.X))
		end
	end
	table.sort(shown)
	print(#shown, table.concat(shown, "; "))
end
```

- **TC1 Shown while it's in use.** Before anything,
  `print(me.PlayerGui.VFTouch.Enabled, me:GetAttribute("VFTouch"))`: `false off`.
  `touch("0 0 0 0")`: the line reads `flags=0 scoped=0 turn=0.0,0.0 crouch=0 menu=0 size=...` with
  the game window's size less Roblox's top bar, and the buttons show: `buttons()` prints 20, none of
  them `spike` or `close`. Look at the game window: the round buttons in a cluster at the bottom
  right, standing above the health, abilities and ammo along the bottom where they reach under them,
  none overlapping another, the second FIRE right of the minimap, and the column down the left under
  the minimap. `touch(nil, 0.1)`: `off`, the buttons gone, and the mouse and keys playing as before.
  **Send:** the lines, `buttons()`'s, and anything overlapping or off the screen.

- **TC2 Moving.** `touch("0 1 0 0", 1)`: you run ahead down the lane, the HUD's speed at 5.40,
  `flags=1`. `lift()`: you stop, `flags=0`. `touch("0 0.45 0 0", 1)`: you walk, at 3.29, `flags=17`.
  `touch("-0.7 -0.7 0 0", 1)`: back and to the left at once, `flags=6`. `lift()`. **Send:** the
  lines and speeds.

- **TC3 Looking.** `drag("0 0 0.5 0", 1)`: about 60 degrees right. `drag("0 0 0 0.25", 1)`: about 30
  up. `drag("0 0 -0.5 -0.25", 1)`: back. `set("VFTestSetting", "touchLook=240")`, and
  `drag("0 0 0.5 0", 1)`: about 120 right. `set("VFTestSetting", "touchLook=120")`.
  `touch("0 0 0 0 aim", 0.1)` and `lift()`: the Vandal's sights, `scoped=1`; `drag("0 0 0.5 0", 1)`
  turns about 48 right (60 over its 1.25 zoom); `touch("0 0 0 0 aim", 0.1)` and `lift()`:
  `scoped=0`. Hold `touch("0 0 0.5 0 fire", 1)`, then `lift()`: it fires and turns at once.
  **Send:** the turns.

- **TC4 The buttons.** `touch("0 0 0 0 fire", 0.5)` and `lift()`: a few rounds fired.
  `touch("0 0 0 0 reload", 0.1)` and `lift()`: a reload. `touch("0 0 0 0 jump", 0.1)` and `lift()`:
  a jump. `touch("0 0 0 0 crouch", 0.1)` and `lift()`: you crouch, and the line stays
  `flags=32 ... crouch=1` with nothing held, the button's ring gold; the same again stands you up.
  `touch("0 0 0 0 swap", 0.1)` and `lift()`: the Classic; the same, the Vandal.
  `touch("0 0 0 0 swap", 0.5)` and `lift()`: the knife; a tap, the Vandal back. `touch("0 0 0 0 q")`
  and `lift()`: Updraft, `Q0/1`. `touch("0 0 0 0 e")` and `lift()`: Tailwind's gust readies, `E0/1`
  with `windup`; once it reads `ready`, the same again dashes. `touch("0 0 0 0 c")` and `lift()`:
  Cloudburst, `C1/2`. `set("VFTestGive", "ultimate")`, then `touch("0 0 0 0 x")` and `lift()`: Blade
  Storm, `X0/8 storm`; `touch("0 0 0 0 fire", 0.1)` and `lift()` throws a knife.
  `touch("0 0 0 0 drop", 0.1)` and `lift()` with a gun in hand: it drops ahead.
  `set("VFTestPitch", -53)`: the prompt under the crosshair reads `USE  PICK UP ...`;
  `touch("0 0 0 0 use", 0.1)` and `lift()` picks it up. `set("VFTestPitch", nil)`.
  `set("VFTestGive", "spike")`: `buttons()` prints 21, with `spike`; `touch("0 0 0 0 spike", 0.5)`:
  the spike in hand, `flags=1024`; `lift()`, then `touch("0 0 0 0 drop", 0.1)` and `lift()`:
  dropped, and `spike` gone from `buttons()`. `set("VFTestPitch", -30)`,
  `touch("0 0 0 0 ping", 0.1)` and `lift()`: a ping ahead, `gui("VFPings", "Shown")` printing
  `HERE 3m`; `set("VFTestPitch", nil)`. **Send:** the lines, and anything that didn't happen.

- **TC5 The column and menus.** `touch("0 0 0 0 settings", 0.1)` and `lift()`: the settings menu,
  with `Touch look` 120 under CONTROLLER AND TOUCH, the line reading `menu=1`, and only CLOSE shown
  (`buttons()` prints 1, `close`). `touch("0 0 0 0 close", 0.1)` and `lift()`: shut, and 20 again.
  The same with `play`, then `agents`: each opens, and CLOSE shuts it. The map and the scoreboard
  are a match's, so `set("VFTestPlay", "skirmish")` for the rest. In a buy phase,
  `touch("0 0 0 0 buy", 0.1)` and `lift()`: the buy menu, `menu=1`; CLOSE shuts it.
  `touch("0 0 0 0 map", 0.1)` and `lift()`: the big map, `gui("VFMinimap", "Big")` printing `true`,
  MAP's ring gold; again, shut. `touch("0 0 0 0 scores", 0.1)` and `lift()`: the scoreboard stays
  up; again, gone. **Send:** the lines, and anything that didn't open or shut.

- **TC6 Dead.** In the spike rounds (as BC1 in section 66, or Competitive as in section 71), walk
  out at the other side and let them kill you. Watching your side's bot, the line under its name
  reads `USE  take control`, and while two or more of your side are alive, so there's someone to
  switch to, `FIRE / AIM  switch`; `touch("0 0 0 0 fire", 0.1)` and `lift()` watches the next, `aim`
  the last. Back on a bot you may take over, `touch("0 0 0 0 use", 0.1)` and `lift()`: you're in its
  body, and the server's Output has the `[VF] takeover:` lines. **Send:** the lines.

- **TC7 Planting.** In the spike rounds attacking with the spike, or on the course with
  `set("VFTestGive", "spike")`, stand on a site (the course's A is 8 m left of the spawn and 26 m
  behind it): with `VFTestTouch` set the prompt reads `HOLD SPIKE TO PLANT`, and
  `touch("0 0 0 0 spike", 4.5)` plants it; `touch(nil, 0.1)` and the prompt reads `HOLD 4 TO PLANT`
  again. **Send:** the prompts and the plant.

- **TC8 A phone (Bradley).** Play on a phone or a tablet, or in Studio's device emulator (the Test
  tab's Device). Roblox's own stick and jump button are gone; the stick moves where the thumb lands
  and walks with a light push; drags turn the view and FIRE's touch aims as it fires; every button's
  in reach and big enough; CLOSE shuts each menu; and the HUD's prompts name the buttons. **Send:**
  what felt off, the sizes, and `Touch look` as you'd have it.

## 76. Basic Training

From [72-basic-training.md](research/72-basic-training.md). System 72 is a tutorial on the course, a
step at a time, on a server of its own: the Play menu's first card, reading SOLO. A panel at the top
of the screen says what the step under way asks, naming the buttons for the input in use, and a gold
marker shows where: a column of light at a spot or the spike to fetch, a ring on the floor round the
targets, as wide as where one downed counts. It starts on the Classic and the knife with no shield.
Its steps, by the keys the local player's `VFTrainingStep` has for them: `move` to the sprint
lane's 20 m post; `crouch` into the low tunnel; `jump` onto the 0.50 m box; `walk` 6 m; `shoot` the
target 10 m down the range; `still`, the crouching target at 20 m downed standing still; `head`, the
target behind the cover downed by a headshot; `reload`; `rifle`, a target at 30 m downed aiming down
the sights of the Vandal it hands over; `shield`, one bought; `abilities`, C, Q and E used once
each; `ultimate`; `plant`; `defuse`; and `done`. `VFTrainingProgress` says how far through the step
you are, and `VFTrainingNote` why something didn't count; PlayerGui's `VFTraining` has the panel's
`Text`, its lines apart by ` | `, and the `Note` shown. `VFTestTraining` set to a step's key moves
you to it. Workspace's `VFTrainingOn` is true while it's played.

Press Play (F5), with one player, as Jett. Set `VFTestMute` if the sound's not wanted. Run this once
in the command bar with it on the client, then each check's lines there: `set(name, value)` sets one
of the local player's attributes; `step()` prints the step, its progress and its note; `panel()`
prints the panel's text and note; `walkTo(x, z, buttons, t)` holds `buttons` (1, W, if left out; 17
walks, 33 crouches) facing the spot at `x` and `z` in metres until you're within 0.4 m of it, the
step moves on or `t` seconds pass (8 if left out), then lets go and prints `step()`;
`hold(buttons, t)` holds `buttons` for `t` seconds, then lets go and prints `step()`; `hop(run)`
walks ahead for `run` seconds and jumps; and `shoot(x, z, region, moving, n)` aims at the `region`
(`head` if left out) of the dummy nearest that spot and fires up to `n` times (8 if left out),
holding `moving` too (nothing if left out, and for 0.4 s first, so you're moving as the first shot
goes off), until the step moves on, then prints `step()`. `VFTestButtons`' flags are section 75's: 1
W, 4 A, 16 walking, 32 crouching, 64 jump, 128 fire, 256 the right button, 512 reload, 1024 the
spike's 4, 4096 C, 8192 Q, 16384 E and 32768 X.

```lua
me = game.Players.LocalPlayer
local S = require(game.ReplicatedStorage.Shared.Units).STUDS_PER_METRE
local BASE = require(game.ReplicatedStorage.Shared.Net.PlayerCodec).DUMMY_BASE
function set(name, value)
	me:SetAttribute(name, value)
end
function step()
	print(me:GetAttribute("VFTrainingStep"), me:GetAttribute("VFTrainingProgress"), me:GetAttribute("VFTrainingNote"))
end
function panel()
	local gui = me.PlayerGui.VFTraining
	print(gui:GetAttribute("Text"), "/", gui:GetAttribute("Note"))
end
local function feet()
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
	return root and root.Position / S
end
function walkTo(x, z, buttons, t)
	local was = me:GetAttribute("VFTrainingStep")
	me:SetAttribute("VFTestAimPoint", Vector3.new(x, 1.5, z))
	me:SetAttribute("VFTestButtons", buttons or 1)
	local start = os.clock()
	while os.clock() - start < (t or 8) do
		task.wait()
		local p = feet()
		if (p and Vector2.new(p.X - x, p.Z - z).Magnitude < 0.4) or me:GetAttribute("VFTrainingStep") ~= was then
			break
		end
	end
	me:SetAttribute("VFTestButtons", nil)
	me:SetAttribute("VFTestAimPoint", nil)
	task.wait(0.5)
	step()
end
function hold(buttons, t)
	me:SetAttribute("VFTestButtons", buttons)
	task.wait(t)
	me:SetAttribute("VFTestButtons", nil)
	task.wait(0.5)
	step()
end
function hop(run)
	me:SetAttribute("VFTestButtons", 17)
	task.wait(run)
	me:SetAttribute("VFTestButtons", 81)
	task.wait(0.4)
	me:SetAttribute("VFTestButtons", nil)
	task.wait(0.8)
	step()
end
local function dummyAt(x, z)
	local best, id = math.huge, nil
	for _, m in workspace.VFDummies:GetChildren() do
		local n = tonumber(string.match(m.Name, "^Dummy_(%d+)$"))
		local p = if n then m:GetPivot().Position / S else nil
		local d = if p then Vector2.new(p.X - x, p.Z - z).Magnitude else math.huge
		if d < best then
			best, id = d, BASE + n
		end
	end
	return id
end
function shoot(x, z, region, moving, n)
	local was = me:GetAttribute("VFTrainingStep")
	me:SetAttribute("VFTestAimEntity", dummyAt(x, z))
	me:SetAttribute("VFTestAimRegion", region or "head")
	if moving then
		me:SetAttribute("VFTestButtons", moving)
		task.wait(0.4)
	end
	for _ = 1, n or 8 do
		me:SetAttribute("VFTestButtons", (moving or 0) + 128)
		task.wait(0.1)
		me:SetAttribute("VFTestButtons", moving or 0)
		task.wait(0.4)
		if me:GetAttribute("VFTrainingStep") ~= was then
			break
		end
	end
	me:SetAttribute("VFTestButtons", nil)
	me:SetAttribute("VFTestAimEntity", nil)
	task.wait(0.3)
	step()
end
```

- **TR1 Starting.** `set("VFTestPlay", "training")`: the server's Output has
  `[VF] Arena off: Basic Training` and `[VF] training: <your UserId> at move` (and a line like it as
  each later step starts), and you're back at the spawn with the Classic in hand and no shield. The
  panel at the top reads `BASIC TRAINING  1 / 14`, `MOVE` and
  `Move with W A S D to the marker at the end of the lane.`, and a gold column of light stands at
  the sprint lane's 20 m post, ahead and to your right. `step()` prints `move`, and
  `print(workspace:GetAttribute("VFTrainingOn"), workspace:GetAttribute("VFArenaOn"))` prints
  `true false`. `set("VFTestPlayMenu", true)`: the Play menu's first card is Basic Training, reading
  SOLO, and its line at the top reads `This server plays BASIC TRAINING.`;
  `set("VFTestPlayMenu", false)`. **Send:** the lines, and how the panel and the column look.

- **TR2 Moving, crouching, jumping.** `walkTo(20, -6)`: you run to the post and it moves on to
  `crouch`, the panel at `2 / 14` and the column at the low tunnel. `walkTo(12, 8)` stands you at
  the tunnel's mouth, still `crouch`; `walkTo(8, 8, 33)` crouches you into it: `jump`, the column on
  the lowest box. `walkTo(5, 8, 33)` takes you out at the far end, and `walkTo(-6, -7.6, 17)` to the
  box. `set("VFTestYaw", 0)` faces it, and `hop(0.15)` jumps onto it: `walk`. Short of it or over
  it, walk back in front of it and try again with a longer or shorter run. **Send:** the lines, and
  anything that moved on before you were there.

- **TR3 Walking.** `set("VFTestYaw", 180)` and `hold(1, 0.6)`: running doesn't count,
  `walk 0 / 6 m`. `hold(17, 1)`: about `3 / 6 m`, counting on the panel's bottom line.
  `hold(17, 1.5)`: `shoot`, and a gold ring 4 m across round the target 10 m down the range.
  **Send:** the lines.

- **TR4 Shooting.** `walkTo(0, 0)` back to the spawn, then `shoot(0, -10, "body")`: the target
  falls, and `still`, the ring round the crouching target at 20 m. `shoot(-2, -20, "head", 4, 6)`
  strafes left for 0.4 s and fires as you go on strafing: once it falls, `step()` still prints
  `still`, with the note `You were moving as that shot went off: stop, then fire.`, red on the
  panel's bottom line for 5 s (if it doesn't fall, again). `walkTo(0, 0)`, then `shoot(-2, -20)`:
  `head`, and the ring round the target behind the cover. `shoot(8, -22)`: `reload`. **Send:** the
  lines.

- **TR5 Reloading and a rifle.** `hold(512, 0.1)` (with a full magazine, `hold(128, 0.1)` first to
  fire one), then two seconds later `step()`: `rifle`, the Vandal in your hand with `25` in its
  magazine, and the ring, 7 m across, round both targets at 30 m (in BRINK the strafing one
  wandered 0.9 m to 2.9 m right of its spot). `shoot(1.5, -30, "head", 0, 3)` from the hip: once one
  falls, `step()` still prints `rifle`, with the note `Aim down sights first ({aim}).` and the
  panel's `Aim down sights first (RIGHT CLICK).` `hold(256, 0.1)` aims down the sights, and
  `shoot(1.5, -30)`: `shield`. **Send:** the lines.

- **TR6 Buying and abilities.** `set("VFTestBuy", "light")`: a Light Shield on the health bar, and
  `abilities 0 / 3`. `hold(4096, 0.1)`: Cloudburst, `1 / 3`; `hold(8192, 0.1)`: Updraft, `2 / 3`;
  `hold(16384, 0.1)`, and a second later `step()`: Tailwind readies, and `ultimate`.
  `hold(32768, 0.1)`: Blade Storm, and `plant`, the column at the spike behind the spawn. **Send:**
  the lines.

- **TR7 The spike.** `walkTo(0, 4)` picks the spike up. Go onto site A, marked on the floor 8 m left
  of the spawn and 26 m behind it (`walkTo(-8, 26)`, round its low wall if it's in the way), until
  the prompt under the crosshair reads `HOLD 4 TO PLANT`. `set("VFTestSlot", 4)`, then
  `hold(1024, 4.5)`: planted, and `defuse`, the panel down a little, clear of the spike's light.
  `hold(1024, 7.5)` by the spike: defused, and `done`. The panel reads `BASIC TRAINING COMPLETE`,
  `DONE` and
  `That's the basics. Open the Play menu (M) for a match: Skirmish to warm up, then Unrated.`, with
  no marker. **Send:** the lines.

- **TR8 Gone off.** `set("VFTestTraining", "plant")`: `plant` again. Five seconds after the defuse a
  new spike lies behind the spawn: plant it as in TR7, then walk away and let it go off (45 s):
  `step()` prints `plant` with the note `It went off: plant it again.`, red on the panel for 5 s.
  **Send:** the lines.

- **TR9 The buttons' names.** `set("VFTestTraining", "crouch")`, then
  `set("VFTestPad", "0 0 0 0 0 0")` and `panel()`:
  `Crouch (click L3) and get into the low tunnel by the marker.` `set("VFTestPad", nil)`,
  `set("VFTestTouch", "0 0 0 0")` and `panel()`: `Crouch (tap CROUCH) ...`.
  `set("VFTestTouch", nil)` and `panel()`: `Crouch (hold CTRL) ...`.
  `set("VFTestTraining", "rifle")`: the step's back, the Vandal still in its slot from TR5 (a step
  hands its gun, and draws it, only when it isn't there, as on a new life). **Send:** the lines.

- **TR10 Leaving.** `set("VFTestPlay", "skirmish")`: the server's Output has `[VF] Arena on: ...`,
  the panel and the marker are gone, `step()` prints `nil nil nil`, and `VFTrainingOn` reads
  `false`. `set("VFTestPlay", "training")` again: back at `move`, `1 / 14`, on the Classic and the
  knife. Then `require(game.ReplicatedStorage.Shared.Net.Remotes).get().Arena:FireServer("off")`, as
  P asks for the arena off: the plain course, no panel, `VFTrainingOn` `false`. **Send:** the lines.

- **TR11 A server of its own (Bradley, once the place is published).** PLAY for Basic Training on a
  live server sends you to a new server, straight into it, at MOVE; a second player picking it at
  the same time lands on a server of their own; and PLAY for Skirmish from there sends you to a
  Skirmish server. **Send:** where each PLAY took you.

- **TR12 The feel (Bradley).** Play it through with the keys, a controller and a phone: where a
  step's text or marker leaves you unsure, and where a step is too easy or too hard. **Send:** what
  to change.

## 77. Reyna's Devour and Dismiss

From [73-reyna-soul-orbs.md](research/73-reyna-soul-orbs.md). System 73 adds Reyna, a Duelist and
the sixth agent, with her Devour (Q) and Dismiss (E) to play; Leer (C) is played since system 74
(section 78), and Empress (X) since system 75 (section 79). An enemy she kills, or who dies within 3
s of her last hurting them, whoever killed them, leaves her a Soul Orb where they fell, for 3 s: a
purple ball 1 m up that only she sees. Dummies on the course leave them too. With one within 15 m of
her eye and in sight, Q takes it and heals her 50 over 2 s, past 100 up to 150, and what's past 100
goes 10 s after the heal's last point. E takes it instead, and for 1.5 s nothing hurts her and she
runs at up to 12 m/s, but she can't fire, cast, plant or defuse, and her gun comes back as it ends.
Your `VFSouls` attribute lists your orbs, each as its number, where it fell (metres) and when it
goes, apart by `;`. PlayerGui's `VFSouls` carries `Orbs` (how many), `Reach` (the number of the one
in reach, -1 for none) and `Prompt` (the keys over the crosshair, empty for none); `VFCombatHud`'s
`Health` is the health the HUD shows; and Workspace's `VFSouls` holds the balls (`VFSoulOrb`). In
Studio the server's Output has a `[VF] soul:` line as each orb's earned (saying whether by her kill
or her damage, and how long before), each is taken and each overheal goes.

Press Play (F5), with one player, and pick Reyna: press T, click REYNA's card and PICK REYNA (or set
`VFTestAgents` to true, `VFTestAgent` to `reyna`, then `VFTestAgent` to `lock`). Set `VFTestMute` if
the sound's not wanted. Run this once in the command bar with it on the client, then each check's
lines there: `souls()` prints your orbs, `Orbs`, `Reach` and `Prompt`, then `VFKit` and the health;
`press(buttons)` holds `buttons` for 0.1 s (128 fire, 8192 Q, 16384 E); `down(id, n)` aims at that
dummy's head and fires up to `n` times (8 if left out) until you've an orb more, then prints
`souls()`; `speed()` prints how fast you're going across the ground; and `dismiss()` runs ahead
for 0.5 s, presses E as you go on, fires 0.35 s later, and prints your speed before and in it and
`VFKit` in it and 1.5 s after it. Dummy 1, 10 m down the target lane, is 4294901761, and Dummy 6, 50
m down it, 4294901766. On the course a spent charge comes back 1.5 s after it's spent. Start each
check 1.2 m left of the spawn (`pos` on the F3 panel about `-1.20 0.00 0.00`), facing down the lane
(`set("VFTestYaw", 0)`), with the Vandal in hand: from the spawn itself, the sprint lane's first
post, 7 m out, hides Dummy 1's orb.

```lua
me = game.Players.LocalPlayer
local S = require(game.ReplicatedStorage.Shared.Units).STUDS_PER_METRE
function set(name, value)
	me:SetAttribute(name, value)
end
function souls()
	local g = me.PlayerGui.VFSouls
	local reach = g:GetAttribute("Reach")
	print(me:GetAttribute("VFSouls"), g:GetAttribute("Orbs"), reach, g:GetAttribute("Prompt"))
	print(me:GetAttribute("VFKit"), me.PlayerGui.VFCombatHud:GetAttribute("Health"))
end
function press(buttons)
	me:SetAttribute("VFTestButtons", buttons)
	task.wait(0.1)
	me:SetAttribute("VFTestButtons", nil)
end
function down(id, n)
	local had = me:GetAttribute("VFSouls")
	me:SetAttribute("VFTestAimEntity", id)
	me:SetAttribute("VFTestAimRegion", "head")
	for _ = 1, n or 8 do
		task.wait(0.3)
		press(128)
		task.wait(0.2)
		if me:GetAttribute("VFSouls") ~= had then
			break
		end
	end
	me:SetAttribute("VFTestAimEntity", nil)
	souls()
end
function speed()
	local root = me.Character.HumanoidRootPart
	local a = root.Position
	task.wait(0.25)
	local b = root.Position
	print(string.format("%.1f m/s", Vector2.new(b.X - a.X, b.Z - a.Z).Magnitude / S / 0.25))
end
function dismiss()
	me:SetAttribute("VFTestButtons", 1)
	task.wait(0.5)
	speed()
	me:SetAttribute("VFTestButtons", 16385)
	task.wait(0.1)
	me:SetAttribute("VFTestButtons", 1)
	task.wait(0.35)
	speed()
	me:SetAttribute("VFTestButtons", 129)
	task.wait(0.1)
	me:SetAttribute("VFTestButtons", 1)
	print(me:GetAttribute("VFKit"))
	task.wait(0.8)
	me:SetAttribute("VFTestButtons", nil)
	task.wait(1.5)
	print(me:GetAttribute("VFKit"))
end
```

- **RY1 Her kit.** In agent select (T), the cards are JETT, PHOENIX, SAGE, OMEN, SOVA and REYNA, and
  REYNA's reads DUELIST. Click it: her kit, headed `REYNA   DUELIST`, with Q DEVOUR lit,
  `With a Soul Orb in reach, Q takes it and heals you 50 over 2 s, past full health up to 150 for 10 s.`,
  and E DISMISS lit,
  `With a Soul Orb in reach, E takes it: for 1.5 s nothing hurts you and you run faster, but you can't fire or cast.`;
  C LEER and X EMPRESS are lit too (sections 78 and 79). Click PICK REYNA: the button reads
  `PLAYING REYNA`, and `VFAgent` reads `reyna`. Close it with T. `souls()` prints `nil 0 -1` and an
  empty prompt, then `C2/2 Q2/2 E2/2 X7/7 100`. **Send:** the lines, and how her card looks.

- **RY2 A Soul Orb.** `down(4294901761)`: Dummy 1 falls, the server's Output has
  `[VF] soul: <your name> earns 1 at 0.00, 0.00, -10.00 (her kill)` (or near those numbers), and a
  purple ball floats 1 m over where it fell, pulsing, a little bigger than one out of reach. Over
  the crosshair, in purple, `Q DEVOUR    E DISMISS`. `souls()` prints `1,0.00,0.00,-10.00,` and a
  time, `1`, `1` and `Q DEVOUR    E DISMISS`. The ball fades over its last half second and is gone 3
  s after the dummy fell: `souls()` then prints `nil 0 -1` and an empty prompt, and Workspace's
  `VFSouls` is empty. Dummy 1 is back 2 s after it fell. **Send:** the lines, and how the ball
  looks.

- **RY3 Out of reach.** `down(4294901766)`: Dummy 6 falls 50 m away, and its ball floats there,
  smaller and dimmer, with no prompt: `souls()` prints `1` orb and `-1` for `Reach`. `press(8192)`,
  then `press(16384)`: nothing, no `devour` or `dismiss` line in the Output, and `VFKit` still
  starts `C2/2 Q2/2 E2/2`. Once the ball's gone, the same with no orb at all. **Send:** the lines.

- **RY4 Devour.** Open the Sound Lab (F2 four times). `down(4294901761)`, then at once
  `press(8192)`: the Output has `[VF] soul: <your name> devour takes` the orb's number and
  `(there)`; the ball and the prompt go, and a soft bell's logged as `healChime`, `yours`. The
  Vandal stays in hand, and Q's pip goes dark and lights again 1.5 s later. Your health climbs 25 a
  second: `for _ = 1, 3 do souls() task.wait(1) end` straight after prints about 100, 125 and 150 as
  the health, and the HUD shows the same. `press(128)` fires the Vandal as ever. About 12 s after
  the bell, the Output has `[VF] soul: <your name> overheal over` and the health's 100 again.
  **Send:** the lines, and how long after the bell the overheal went.

- **RY5 Dismiss.** `set("VFTestYaw", 10)`, turning you a little left so you run past Dummy 1's spot.
  `down(4294901761)`, then `dismiss()`: the Output has `[VF] soul: <your name> dismiss takes` the
  orb's number and `(there)`, a fizzle's logged as `fizzle`, `yours`, the Vandal goes with no draw
  heard, and the screen darkens, purple round its edge, while E's square counts down. `dismiss()`
  prints about 5.4 m/s before it, about 12 m/s in it, and `VFKit` with `dismiss` and about `0.7`
  after it; the shot it fires in it does nothing, with no shot heard or logged. 1.5 s after the
  press the darkening goes and the Vandal comes back with its draw, and `dismiss()`'s last line
  starts `C2/2 Q2/2 E2/2`, E's charge back. **Send:** the lines, and how the screen looks in it.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and pick
REYNA in window 1. Everyone on the course is everyone else's enemy. Player 2 stands about 5 m to one
side of player 1, where each sees the other, and window 1 runs this section's script.

- **RY6 Nothing hurts her.** In window 2, run this: it aims at player 1, waits for player 1's
  Dismiss, and fires for a second.

  ```lua
  me = game.Players.LocalPlayer
  local p1 = game.Players.Player1
  me:SetAttribute("VFTestAimEntity", 4294967295)
  me:SetAttribute("VFTestAimRegion", "body")
  repeat task.wait() until string.find(p1:GetAttribute("VFKit") or "", "dismiss", 1, true)
  me:SetAttribute("VFTestButtons", 128)
  task.wait(1)
  me:SetAttribute("VFTestButtons", nil)
  me:SetAttribute("VFTestAimEntity", nil)
  ```

  In window 1, `down(4294901761)`, then `press(16384)`: window 2's Vandal fires about ten shots at
  player 1, with no hit marker or damage number, and window 1's `souls()` afterwards still
  reads 100. In window 2, player 1 turns dark and see-through as the fizzle's heard, the gun gone
  from their hands, for 1.5 s, then looks as ever, the gun back. Then run window 2's lines again
  without the `repeat` line: player 1 drops, so the shots land outside a Dismiss. **Send:**
  window 1's health after the first burst, what window 2 saw of player 1, and what the second burst
  did.

- **RY7 Basic Training with her kit.** Stop the game, press Play (F5) with one player, pick Reyna,
  and run section 76's script and this section's. `set("VFTestPlay", "training")`, then
  `set("VFTestTraining", "abilities")`: `step()` prints `abilities` and
  `0 / 3   {q} and {e} take a Soul Orb: down a target first.`, and `panel()` has
  `0 / 3   Q and E take a Soul Orb: down a target first.` `hold(4096, 0.1)`, then a second later
  `hold(128, 0.1)`: Leer's eye flies, and `1 / 3`, the hint still there. Once the eye's gone, 2.4 s
  after it flew (it opens in front of Dummy 1's head, and would take the first shots), with the
  Classic, `down(4294901761)` (two headshots) and `press(8192)`: `2 / 3`, the hint still there. Once
  Dummy 1's back, `down(4294901761)` and `press(16384)`: `ultimate`. `hold(32768, 0.1)`: Empress's
  swell, and `plant`. **Send:** the lines.

- **RY8 Bots playing her.** Stop the game and start a Local Server with 1 player. In the server's
  command bar, set `VFArenaMode` to `teamdeathmatch` and `VFArenaOn` to true: Team Deathmatch plays
  whichever map its vote picks, as `VFMatchMap` names only the spike rounds' first. Once the
  pre-game's over, run section 69's script: the bots with `VFAgent` `reyna` play her. Each side
  leaves one agent out, so there's usually one on each; if there's none, set `VFArenaOn` to false
  and true again. Let it play for 3 minutes. The server's Output has `[VF] soul:` lines for those
  bots: `earns` after their kills (`her kill`) and after enemies they'd hurt died to their side
  (`hurt ... s before`, never more than 3 s), now and then `devour takes ... (there)`, and never
  `dismiss` from a bot. **Send:** the soul lines, and those bots' kills (Tab).

- **RY9 The feel (Bradley).** Play her on the course and against bots, with the keys and a
  controller: whether the ball's easy to see and to take (its 15 m reach), whether Devour's heal and
  Dismiss's speed feel right, and whether the screen's darkening in Dismiss is too much. **Send:**
  what to change.

## 78. Reyna's Leer

From [74-leer.md](research/74-leer.md). System 74 has Reyna's Leer (C) played: C readies the eye,
ready 0.8 s later, and fire casts it. It flies 10 m along the crosshair over 0.4 s, on through walls
and ceilings, and hangs there, though a floor in its way stops it and it rests on that. From then
for 2 s any enemy who has it within 50 degrees of where they look, at any distance, with nothing
between, is nearsighted as by Paranoia, seeing no further than 7.5 m, while they look and 0.2 s
after, then clearing over 0.5 s; it doesn't deafen. Her side never are, and on the course, with no
sides, everyone but her is her enemy. It has 100 health: her enemies' bullets and knives take their
damage off it, a bullet's to the body at its range, and at none it bursts; her side's do nothing,
and on the course anyone's do, hers too. The gun's back 0.5 s after the cast. Your `VFLastLeer` is
where your last eye came to rest (metres), set as it opens, `VFLeerHealth` the health it has left,
and `VFLastLeered`, once it's gone, the names of those it nearsighted (empty for nobody). Anyone's
`VFNearsight` is their nearsight while any of it's left, Paranoia's or Leer's, and `VFDeafened`
Paranoia's deafening. Workspace's `VFLeer` holds each eye, an `Eye` ball with its `Pupil`, and each
burst, a `Break` ball, and its `Eyes` says how many eyes are drawn.

Press Play (F5), with one player, and pick Reyna as in section 77. Set `VFTestMute` if the sound's
not wanted. Run this once in the command bar with it on the client, then each check's lines there:
`press(buttons)` holds `buttons` for 0.1 s (4096 C, 128 fire, 256 the right button); `eye()` prints
`Eyes`, your `VFLastLeer` and `VFLeerHealth`, then your `VFLastLeered`, `VFNearsight` and `VFKit`;
`leer()` presses C, waits out its equip, fires, and 0.6 s later prints `eye()`; and `shoot(n)` aims
at where your last eye came to rest and fires `n` single shots, printing `VFLeerHealth` after each.
`VFTestYaw` and `VFTestPitch` aim, in degrees: positive yaw turns left, and positive pitch looks up.
The F3 panel's `pos` line is where you stand, in metres. On the course a spent charge comes back 1.5
s after it's spent. Start each check at the spawn facing down the lane (`VFTestYaw` 0,
`VFTestPitch` 0), with the Vandal in hand.

```lua
me = game.Players.LocalPlayer
function set(name, value)
	me:SetAttribute(name, value)
end
function press(buttons)
	me:SetAttribute("VFTestButtons", buttons)
	task.wait(0.1)
	me:SetAttribute("VFTestButtons", nil)
end
function eye()
	local folder = workspace:FindFirstChild("VFLeer")
	print(folder and folder:GetAttribute("Eyes"), me:GetAttribute("VFLastLeer"), me:GetAttribute("VFLeerHealth"))
	print(me:GetAttribute("VFLastLeered"), me:GetAttribute("VFNearsight"), me:GetAttribute("VFKit"))
end
function leer()
	press(4096)
	task.wait(1)
	press(128)
	task.wait(0.6)
	eye()
end
function shoot(n)
	set("VFTestAimPoint", me:GetAttribute("VFLastLeer"))
	for _ = 1, n do
		task.wait(0.1)
		press(128)
		task.wait(0.15)
		print(me:GetAttribute("VFLeerHealth"))
	end
	set("VFTestAimPoint", nil)
end
```

- **LR1 Her kit.** In agent select (T), REYNA's card has C LEER lit now, with
  `C readies an eye. Fire casts it 10 m ahead, through walls: for 2 s any enemy who looks at it is nearsighted, unless they shoot it.`,
  and X EMPRESS is lit too (section 79). Close it with T. `eye()` prints `0 nil nil`, then `nil nil`
  and a `VFKit` that starts `C2/2 Q2/2 E2/2`. **Send:** the lines.
- **LR2 In hand.** Open the Sound Lab (F2 four times), and keep it open to LR5. `press(4096)`: a
  quick whoosh, logged as `leerEquip`, `yours`; the Vandal goes, and an open hand comes up holding a
  violet eye, its dark pupil turned to you (on its far side, unseen, until system 75). C's square
  lights, with `EQUIP` under it for 0.8 s; the HUD reads `Leer   [C]`, with no ammo; and `VFKit`
  ends in `equip`. `press(256)`: nothing's cast or heard. `press(4096)` again: the Vandal's back,
  and `VFKit` still reads `C2/2`, nothing spent. **Send:** a screenshot of it in hand.
- **LR3 Down the lane.** `set("VFTestYaw", 10)`, turning you a little left so it stops clear of
  Dummy 1, then `leer()`: a slowed swish, logged as `leerCast`, `yours`, and a small, dim violet
  ball flies out from your view, growing and brightening, and stops about 10 m away as a low toll's
  logged as `leerOpen`, its dark pupil turned to you. `eye()` prints `1`, about `-1.74, 1.62, -9.85`
  and `100`, then an empty `VFLastLeered`, `nil` (her own eye doesn't nearsight her, though she's
  looking at it) and a `VFKit` with `C1/2`. The Vandal's back 0.5 s after the cast. 2.4 s after the
  cast the eye fades away: `eye()` then prints `0`, and `VFLastLeered` still empty, as dummies don't
  look. Set `VFTestYaw` back to 0. **Send:** the lines, and a screenshot of the eye open.
- **LR4 Through a wall, and onto the floor.** Walk to the wallbang lane, left of the spawn, and
  stand 3 m in front of its line, facing the `concrete 0.10 m` wall (`pos` about
  `-26.00 0.00 -13.00`, `VFTestYaw` 0). `leer()`: the eye flies on through the wall and past the
  dummy behind it, and stops short of the backstop, `VFLastLeer` about `-26.00, 1.62, -23.00`. Walk
  back to the spawn, set `VFTestPitch` to -30, looking down, and `leer()`: it flies down and stops
  on the floor about 2.4 m ahead, resting on it, `VFLastLeer` about `0.00, 0.25, -2.37`, not under
  the floor. Set `VFTestPitch` to -89, straight down, and `leer()`: it rests on the floor at your
  feet, about `0.00, 0.25, 0.00`. Set `VFTestPitch` back to 0. **Send:** the lines.
- **LR5 Shooting it.** `set("VFTestYaw", 10)`, `leer()`, then at once `shoot(3)`: it prints `60`,
  `20` and `0`, 40 a Vandal bullet, and on the third the eye bursts in a violet flash with a sharp
  crack at the eye, logged as `leerBreak` with your name and how far off it is; `eye()` then prints
  `0` eyes and `0` health. On the course her own shots break it, so it can be tried alone. Set
  `VFTestYaw` back to 0, and press F2 to close the Sound Lab. **Send:** the lines.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and pick
REYNA in window 1. Everyone on the course is everyone else's enemy. Run this section's script in
window 1, and open the Sound Lab in window 2. Player 2 walks 15 m down the target lane (`pos` about
`0.00 0.00 -15.00`) and turns to face player 1 at the spawn (`VFTestYaw` 180).

- **LR6 Nearsighted, and looking away.** In window 2, run this: it waits for an eye, prints its
  nearsight, deafening and world muffle, turns its back on the eye for a second, then turns back to
  it.

```lua
me = game.Players.LocalPlayer
repeat task.wait() until (workspace.VFLeer:GetAttribute("Eyes") or 0) > 0
task.wait(0.7)
print("looking", me:GetAttribute("VFNearsight"), me:GetAttribute("VFDeafened"),
game.SoundService.VFSound.world.worldMuffle.Bypass)
me:SetAttribute("VFTestYaw", 0)
task.wait(1)
print("away", me:GetAttribute("VFNearsight"))
me:SetAttribute("VFTestYaw", 180)
task.wait(0.3)
print("back", me:GetAttribute("VFNearsight"))
```

In window 1, `set("VFTestYaw", 10)` and `leer()`. As the eye opens about 5 m in front of player 2,
window 2 hears a slowed tone, logged as `nearsight`, and its screen goes dark past about 7.5 m:
player 1, 15 m off, is gone in it, while the eye still shows. Its script prints `looking`, a
nearsight, `nil` and `true`: no deafening, nothing muffled. Turned away, it clears within about 0.7
s: `away nil`. Turned back while the eye's still open, it's dark again: `back` and a nearsight.
Window 1's own `VFNearsight` stays `nil`, and a second after the eye's gone (late shots still count
till then), window 1's `eye()` has `Player2` as its `VFLastLeered`. **Send:** both windows' lines,
and a screenshot of window 2 while it's dark.
- **LR7 Shot by an enemy.** In window 2, run this: it waits for an eye, then fires three single
  shots into it.

```lua
me = game.Players.LocalPlayer
local p1 = game.Players.Player1
repeat task.wait() until (workspace.VFLeer:GetAttribute("Eyes") or 0) > 0
task.wait(0.6)
me:SetAttribute("VFTestAimPoint", p1:GetAttribute("VFLastLeer"))
for _ = 1, 3 do
me:SetAttribute("VFTestButtons", 128)
task.wait(0.1)
me:SetAttribute("VFTestButtons", nil)
task.wait(0.2)
print(p1:GetAttribute("VFLeerHealth"))
end
me:SetAttribute("VFTestAimPoint", nil)
```

In window 1, `leer()` (`VFTestYaw` still 10). Window 2 prints `60`, `20` and `0`, and on the third
shot the eye bursts on both screens, a crack logged as `leerBreak` in window 2's Sound Lab, and
window 2's dark clears within about 0.7 s, though the eye's 2 s weren't up. **Send:** window 2's
lines.

Then three players: stop the game, start a Local Server with 3 players and press P in window 1
(Skirmish). Players 1 and 3 share a side, as in F1. As round 1's buy phase starts, agent select
comes up by itself: pick REYNA and LOCK IN in window 1, and LOCK IN in windows 2 and 3. Run this
section's script in window 1. In Skirmish each life starts with every charge.

- **LR8 Her side.** Once the round is live, players 2 and 3 stand side by side, 2 m apart, about 15
  m in front of player 1 in the open, both facing player 1. Run LR7's script in window 3. In
  window 1, face the gap between them and `leer()`: the eye opens about 5 m short of them, and
  window 2 goes dark past 7.5 m, its `VFNearsight` set, while window 3 stays clear, its
  `VFNearsight` `nil`; player 3's shots go into the eye and do nothing, `100` three times, and it
  stands its full time. A second after it's gone, window 1's `VFLastLeered` reads `Player2`. Then
  run the script in window 2, and `leer()` in window 1 again, her second charge: it falls by each
  hit's damage and bursts at `0`. **Send:** the lines.

Then the bots: stop the game, start a Local Server with 1 player, and set the spike rounds going on
Outpost as in section 70 (`VFMatchMap` `outpost`, `VFArenaMode` `spike`, then `VFArenaOn` true), and
run section 70's script in the server's command bar.

- **LR9 Bots casting it.** Let it play for 4 minutes, staying back to watch. Each side leaves one
  agent out, so there's usually a bot on Reyna on each side. The script prints a Reyna bot's
  `leer push:leer` now and then as its side attacks or retakes, and, less often, `leer stall:leer`
  holding a way in with attackers just seen there (a cast the same as that bot's last doesn't print
  again); the eyes fly and open where those it's for would see them, and Workspace's `VFLeer` `Eyes`
  counts them on your screen as they show. With one opened in your view by a bot on the other side,
  your screen goes dark past 7.5 m as in LR6. That bot's `VFLastLeered`, in
  `ReplicatedStorage.VFBots`, names whom its last eye nearsighted. **Send:** the script's leer
  lines, and any `VFLastLeered` that names someone.
- **LR10 The feel (Bradley).** Play her with Leer on the course and against bots: whether the eye's
  easy to place, whether its cone (looked at from 50 degrees off) and how long the nearsight lingers
  feel right, and whether it's too easy or too hard to shoot. **Send:** what to change.

## 79. Reyna's Empress

From [75-empress.md](research/75-empress.md). System 75 has Reyna's Empress (X) played: with its 7
points, X spends them, and 1 s later her frenzy starts, her gun away meanwhile and nothing cast or
fired. It lasts until she dies or the round ends. Through it her guns fire 15% faster and draw and
reload 25% faster, each spray climbing and settling as it would without it; each Soul Orb she earns
heals her at once as Devour does (50 over 2 s), the orb kept and no charge spent, and Q does
nothing; what a heal finished in it takes her past 100 stays; and Dismiss spends no charge and hides
her from her enemies, players and bots, while her side sees her dark and see-through as ever. On the
course, with no sides, nobody else sees her in it. Everyone sees her with a faint violet glow
through the frenzy, and her own screen's edges glow violet. Anyone's `VFEmpress` is true while
they're in the frenzy, and `VFKit` reads `crown` through the activation and `frenzy` after;
`VFCombatHud`'s `Ammo` is the magazine it shows (-1 with none). In Studio the server's Output has
`[VF] soul: <name> empress devour, <n> kept` as each orb she earns in the frenzy heals her, and
`[VF] soul: <name> overheal kept (empress)` as such a heal finishes past 100.

Press Play (F5), with one player, and pick Reyna as in section 77. Set `VFTestMute` if the sound's
not wanted. Run section 77's script once in the command bar with it on the client, then this one,
then each check's lines there: `kit()` prints `VFKit`, `VFEmpress`, the health and the prompt over
the crosshair; `empress()` presses X and prints `kit()` at once, 0.5 s on and 1.2 s on; `spray(t)`
holds fire for `t` seconds and prints how many rounds went; `reload()` presses R and prints how long
the magazine takes to fill; and `draw(slot)` draws that slot with fire held and prints how long it
is till its first round, for an automatic gun. On the course the ultimate's points fill 1.5 s after
they're spent, as a spent charge comes back, but not while the frenzy's on, which only a death ends
there. Start each check 1.2 m left of the spawn facing down the lane, as in section 77, with the
Vandal in hand.

```lua
me = game.Players.LocalPlayer
hud = me.PlayerGui.VFCombatHud
function kit()
	local prompt = me.PlayerGui.VFSouls:GetAttribute("Prompt")
	print(me:GetAttribute("VFKit"), me:GetAttribute("VFEmpress"), hud:GetAttribute("Health"), prompt)
end
function empress()
	press(32768)
	kit()
	task.wait(0.5)
	kit()
	task.wait(0.7)
	kit()
end
function spray(t)
	local from = hud:GetAttribute("Ammo")
	set("VFTestButtons", 128)
	task.wait(t)
	set("VFTestButtons", nil)
	task.wait(0.1)
	print(from - hud:GetAttribute("Ammo"), "rounds")
end
function reload()
	local t0 = os.clock()
	press(512)
	repeat task.wait() until hud:GetAttribute("Ammo") == 25
	print(string.format("%.2f s", os.clock() - t0))
end
function draw(slot)
	local before = hud:GetAttribute("Ammo")
	local t0 = os.clock()
	set("VFTestSlot", slot)
	repeat task.wait() until hud:GetAttribute("Ammo") ~= before
	local from = hud:GetAttribute("Ammo")
	set("VFTestButtons", 128)
	repeat task.wait() until hud:GetAttribute("Ammo") ~= from
	set("VFTestButtons", nil)
	set("VFTestSlot", nil)
	print(string.format("%.2f s", os.clock() - t0))
end
```

- **EM1 Her kit.** In agent select (T), REYNA's card has X EMPRESS lit now, with
  `X sends you into a frenzy until you die or the round ends: you fire, draw and reload faster, kills heal you, and Dismiss hides you.`,
  and nothing on it reads `NOT YET`. Close it with T. `kit()` prints `C2/2 Q2/2 E2/2 X7/7`, `nil`,
  `100` and an empty prompt: the course fills Empress's points now, and X's square on the ability
  bar has its seven pips lit gold. **Send:** the lines, and how her card looks.
- **EM2 The gun as ever.** Before the cast: `spray(2)` prints about `20 rounds`, and then `reload()`
  about `2.50 s`. `set("VFTestSlot", 2)`, and once the Classic's up, `set("VFTestSlot", nil)` and
  `draw(1)`: about `1.00 s`, the Vandal's draw, with a round fired at its end. **Send:** the lines.
- **EM3 The cast.** Open the Sound Lab (F2 four times), and keep it open to EM6. `empress()`: a
  slow, swelling hum, logged as `empressCast`, `yours`; the Vandal goes; X's square lights, its note
  `WINDUP`, dim; and the screen's edges begin to glow a faint violet. It prints
  `C2/2 Q2/2 E2/2 X0/7 crown`, `nil` and `100`, the same 0.5 s on, and 1.2 s on
  `C2/2 Q2/2 E2/2 X0/7 frenzy` and `true`. As the activation ends, 1 s after the press, the Vandal's
  back with its draw heard, X's square stays lit, its note `FRENZY`, Q's note reads `AUTO` and E's
  `FREE`, and the edges' glow holds. `press(32768)` again: nothing, and `kit()` the same.
  `press(4096)`: Leer in hand, the eye's dark pupil turned to you now (section 78's fix);
  `press(4096)` again puts it away. **Send:** the lines, a screenshot of the screen in the frenzy,
  and one of the eye in hand.
- **EM4 Faster.** `reload()`: about `2.00 s` (EM2's draw left 24 rounds). `spray(2)`: about
  `23 rounds`, against EM2's 20, the crosshair's kick no bigger. `reload()` again: about `2.00 s`.
  `set("VFTestSlot", 2)`, and once the Classic's up, `set("VFTestSlot", nil)` and `draw(1)`: about
  `0.80 s`. `kit()` still reads `frenzy`. **Send:** the lines.
- **EM5 Devour, cast for you.** `down(4294901761)`: Dummy 1 falls, and the server's Output has
  `[VF] soul: <your name> earns <n> at 0.00, 0.01, -10.00 (her kill)`, then straight after
  `[VF] soul: <your name> empress devour, <n> kept`; a soft bell's logged as `healChime`, `yours`,
  with nothing pressed. The ball stays, and the prompt over the crosshair reads `E DISMISS` alone.
  `for _ = 1, 3 do kit() task.wait(1) end` at once prints about 100, 125 and 150 as the health.
  `press(8192)` while the ball's there: nothing, no `devour takes` line, and the ball stays its 3 s.
  About 2 s after the bell the Output has `[VF] soul: <your name> overheal kept (empress)`, and no
  `overheal over` follows: 15 s on, `kit()` still reads `150`. **Send:** the lines.
- **EM6 Dismiss, free.** `down(4294901761)` again, then at once `press(16384)`: the Output has
  `[VF] soul: <your name> dismiss takes <n> (there)`, a fizzle's logged, and the Vandal goes and the
  screen darkens as in section 77. `kit()` straight after reads `E2/2` still, with `dismiss` and
  `frenzy`. 1.5 s on the Vandal's back. Press F2 to close the Sound Lab. **Send:** the lines.

Then two players: stop the game and start a Local Server with 2 players, as in section 9, and pick
REYNA in window 1. Everyone on the course is everyone else's enemy. Run section 77's script and this
section's in window 1. Player 2 stands about 5 m to one side of player 1, where each sees the other.

- **EM7 Glowing, then gone.** In window 1, `empress()`. In window 2, player 1 glows faintly violet
  from 1 s after the press, a glow walls hide, and
  `print(game.Players.Player1:GetAttribute("VFEmpress"))` prints `true`. In window 1,
  `down(4294901761)`, then at once `press(16384)`: in window 2 player 1 isn't there at all through
  the Dismiss, no body, no gun and no name over them, for 1.5 s, then back, glowing still. **Send:**
  what window 2 saw of player 1 in the frenzy and in the Dismiss, and a screenshot of each.
- **EM8 A death ends it.** In window 2, run this: it aims at player 1's head and fires for a second.

```lua
me = game.Players.LocalPlayer
me:SetAttribute("VFTestAimEntity", 4294967295)
me:SetAttribute("VFTestAimRegion", "head")
me:SetAttribute("VFTestButtons", 128)
task.wait(1)
me:SetAttribute("VFTestButtons", nil)
me:SetAttribute("VFTestAimEntity", nil)
```

Player 1 drops, the glow gone: window 1's `kit()` reads `X0/7` with no `frenzy`, and `nil`, and
window 2's `VFEmpress` for player 1 is `nil`. Once player 1's back on the course, 1.5 s later
window 1's `kit()` reads `X7/7` again. **Send:** the lines.

Then three players: stop the game, start a Local Server with 3 players and press P in window 1
(Skirmish). Players 1 and 3 share a side, as in F1, and a bot plays on player 2's. As round 1's buy
phase starts, agent select comes up by itself: pick REYNA and LOCK IN in window 1, and LOCK IN in
windows 2 and 3. Run section 77's script and this section's in window 1.

- **EM9 Her side, and a new round.** In the buy phase, `set("VFTestGive", "ultimate")` in window 1:
  `kit()` reads `X7/7`. Once the round's live, players 2 and 3 stand where each sees player 1, and
  window 1 runs `empress()`: both see player 1 glow. Player 1 downs the bot on player 2's side: the
  server's Output has `earns` and `empress devour` lines for it. At once `press(16384)` in window 1:
  through the Dismiss window 3 sees player 1 dark and see-through, as in section 77, and window 2
  doesn't see them at all. Then player 1 downs player 2: as round 2 starts, window 1's `kit()` reads
  `X0/7` with no `frenzy`, and `nil`, the glow gone. **Send:** the lines, and what windows 2 and 3
  saw of the Dismiss.

Then the bots: stop the game and start a Local Server with 1 player. In the server's command bar,
set `VFArenaMode` to `teamdeathmatch` and `VFArenaOn` to true, and once the pre-game's over, run
section 69's script and section 70's there.

- **EM10 Bots playing her.** Let it play for 4 minutes, staying back to watch. Each side leaves one
  agent out, so there's usually a bot on Reyna on each side; once one has its points, it casts
  Empress with an enemy seen near, and section 70's script prints its `empress empress`. Through its
  frenzy it glows violet, its `VFEmpress` in `ReplicatedStorage.VFBots` true, and the server's
  Output has `[VF] soul: BOT <name> empress devour, <n> kept` after its kills, with no
  `devour takes` from it until it dies. In the spike rounds it casts `push:empress` going in, and
  `stall:empress` holding a way in. **Send:** the script's empress lines, and that bot's soul lines.
- **EM11 The feel (Bradley).** Play her with Empress on the course and against bots: whether the
  activation's too long, whether the faster gun shows in a fight, whether the glow and the edges are
  too much or too little, and whether an unseen Dismiss is too strong. **Send:** what to change.

## Results

```
S1 self-test line:
C3 counts: slider ___ gave ___ counts, slider ___ gave ___ counts (mouse DPI, if known: ___)
M2 counter: accurate ___ ms, stopped ___ ms; release: accurate ___ ms, stopped ___ ms
M9 corrections max: ___ mm (no latency), ___ mm (50 ms each way)
M11 air: standing D ___ m right; let go ___ m, speed ___ > ___; S lands ___ m from take-off; D quarter turn: bent ___°, speed ___ > ___; W quarter turn: bent ___°; hops top ___ m/s
W1 fire rate: Vandal ___, Phantom ___, Sheriff ___, Classic ___, Operator ___
H1 snapshots ___/s, render delay ___ ms, held a pose on ___% of frames
H2 agreement ___%, rewind mean ___ ms
H5 agreement ___%, rewind mean ___ ms, hit confirm ___ ms, round trip ___ ms
H7 agreement on moving targets with the cap at 0: body ___%, head ___%
H8 agreement on moving targets past the cap: body ___%, head ___%
H9 strafer's biggest jump: ___ m/s, and with 40 ms and jitter: ___ m/s
T1 motion on the other player: speed ___ m/s, last second ___-___, biggest jump ___ m/s
T2 blocks: the other player shows as blocks only / something of the avatar still shows (what)
V1 look off puts the place's lighting back: yes / no (what differed)
V6 LightingStyle kept: Soft / Realistic
A2 arena: builds clean / something overlaps it (what); the hall feels too big / about right / too small
A4 P while running: max ___ mm
A8 round restart, on the player who was alive: max ___ mm
A9 first to 10: VICTORY / DEFEAT, then a new match at 0-0: yes / no (what happened)
N1 sounds loaded ___ of ___ (still loading after 10 s: ___)
N4 too loud: ___; too quiet: ___
N8 the 15 m strafer stops being heard at ___ m
N10 steps behind the middle block sound duller: yes / no
G1 guns missing or looking or sounding like another: ___
G2 Bucky at 10 m, the number: ___
G4 Odin held, fire rate: ___ rps
B7 Light Armor after a Classic body shot: health ___, shield ___
B8 Regen Shield: refill started ___ s after the hit, took ___ s
B10 buys as the phase opens: kept / lost (which)
K1 swings: a slash every ___ ms, a stab every ___ ms; the combo goes 1, 2, 3, 1: yes / no
K4 the last hits: slash ___ m off the aim, ___ m out; stab ___ m off the aim, ___ m out
K8 stab, 1, 3, stab: ___ ms between the stabs
X1 bottom line: ___
X5 view ___ px wide: run +___ px, walk +___, crouch-walk +___, air +___
X6 spray: fire +___ px at the last bullet; the top lines gone by bullet ___
X9 after a change: ___; after playing again: ___
D4 spike line after the plant: ___; position ___, feet were at ___
D5 faster at ___, ___ and ___ s left; the white sphere at ___ s left
D6 died at the spawn: yes / no; Dummy 18: died / lived; Dummy 1 ___ m away: died / lived
D7 a whole defuse ___ s; from the half ___ s
D8 crouching stopped the defuse: yes / no
D9 dropped ___ m ahead; against the wall it landed ___ m short of it
E2 the map ___: builds clean / something overlaps it (what); for 1v1 too big / about right / too small; for 2v2 too big / about right / too small
E6 the defuse round's banners: ___
E8 player 2's kit in round 3: ___
E11 round 5's spawns: ___; SWITCHING SIDES shown: yes / no
E12 the match ended ___ - ___, then the vote and a new match: yes / no
Q5 round 2's credits: player 1 ___, player 2 ___
Q8 round 3's credits: player 1 ___, player 2 ___; player 1's shield ___
Q10 round 4's credits: player 1 ___, player 2 ___
Q11 Swiftplay's credits, rounds 2, 3, 4, 5, 6 and 9: player 1 ___, player 2 ___
L1 the Vandal landed ___ m ahead
L6 the prompt went at ___ m along the floor
J1 a kill feed line stayed ___ s
J9 player 2's ACS ___, from VFScore ___
U1 the names: all fit, none split / cut off or split (which); the key overlay clear of the bar: yes / no
U2 Updraft: rise ___ m, ___ s in the air; about ___ jump boxes (1.00 m) high; the pip back ___ s after the press
U3 Updraft at the jump's top: rise ___ m
U5 the dash stopped ___ m along the sprint lane; holding D it went right: yes / no
U11 the other player's casts lined up with where they were drawn: yes / no (what)
Y2 down the lane: VFLastCloud ___; the Cloud's Centre ___; Moved: yes / no
Y4 into the sky: VFLastCloud ___
Y5 on the floor: VFLastCloud ___; Dummy 1's outline hidden while it was thick: yes / no
Y6 the screen turned to smoke: yes / no; it cleared ___ m back
Y7 held: VFLastCloud ___; let go: VFLastCloud ___
Y10 the cloud in the same place in both windows: yes / no (what)
Z2 the windup: the bar took about ___ s; a click before it was full threw: yes / no
Z3 body knives to kill Dummy 1: ___; all five came back: yes / no
Z4 leg knives to kill: ___
Z5 a throw on the move missed the crosshair: yes / no (which)
Z8 the burst at 10 m: ___ of 5 landed, the number ___
Z12 the other player's blades and streaks lined up with where they were drawn: yes / no (what)
I1 the jump line held ___ s, tapped ___ s
I3 from the top of Updraft: the jump line ___ s
I8 the other player's rings lined up with where they were drawn: yes / no (what)
F2 the view moved to player 3 after ___ s; their blocks hidden: yes / no
F4 MATCH MVP on ___, TEAM MVP on ___; the countdown started at ___
O1 the first map: ___
O4 the outline and the count moved with each click: yes / no (what)
O5 the next match on: ___; anything of the last map's cover left: yes / no (what)
GG1 the first two guns: ___ then ___; anything that did work of B, 5 to 9, C, Q, E, X and G: ___
GG3 player 1 a force field: yes / no; their label stayed at 100 + 50: yes / no
GG4 in player 2's hands after the knife kill: ___
GG5 MATCH MVP on ___, TEAM MVP on ___
PM1 anything on the cards that read differently: ___
PM4 the GUN GAME card's count: ___
PM6 (live) PLAY GUN GAME took ___ s to land; the second player on the same server: yes / no
SM1 the first map: ___; VFSpikeMap holds Outpost, Quarry and Foundry: yes / no
SM3 anything on the cards that read differently: ___
SM5 the second map: ___; the plant at B: yes / no; for 2v2 too big / about right / too small
SM6 the third map: ___; the plant at A: yes / no; for 2v2 too big / about right / too small
DM1 the map: ___; anything that did work of C, Q, E, X, the glide and G: ___
DM2 anything sold that shouldn't be, or not sold that should: ___
DM3 before the kill: magazine ___, reserve ___; after: magazine ___, reserve ___
DM4 the pack healed to 100 + 50: yes / no; the magazine full: yes / no; the cross left alone went after ___ s
DM5 respawns in player 1's sight: ___ of 5; facing a wall: ___ of 5
DM6 window 2's title: ___; MATCH MVP on ___
TD1 the map: ___; the TEAM DEATHMATCH card's name fit: yes / no; anything that did work of 5 to 9 and G: ___
TD2 anything in the menu that read differently: ___; the Ghost in hand at once: yes / no; after O closed, the cursor stayed the menu's: yes / no
TD3 the menu closed as you left the room: yes / no; B did nothing out there: yes / no
TD4 the burn began ___ s into the match; player 2 fell ___ s after; the kill feed read: ___
TD5 player 2 a force field: yes / no; their label stayed at 100 + 25: yes / no; ENEMY SPAWN ROOM at once: yes / no
TD6 the Stinger in hand ___ s into the stage, drawn by itself: yes / no; player 2's Sheriff at once: yes / no
TD7 window 2's title: ___; MATCH MVP on ___
TD8 the next map: ___; the drawn match's title: ___
TP1 anything missing from VFPickups: ___; C's count started at ___, Q's at ___
TP2 the first pad's gun: ___, taken by walking over / with F; the sidearm left on the pad: yes / no
TP3 anything left on the ground by G: yes / no; the pad's next gun ___ s after the take; spent, the sidearm back: yes / no
TP4 before the orb: health ___, shield ___; 6 s after: health ___, shield ___; player 2 mended: yes / no; the ally mended: yes / no / not tried; the orb back ___ s after
TP5 the gold orbs up ___ s into the match; X after the orb ___, after the kill ___
TP6 C's pip back ___ s after the throw; the counts carried over the death: yes / no
TP7 the stage-2 guns on the pads: ___; the Stinger after the handover: magazine ___, reserve ___
TP8 the next pre-game's counts: C ___, Q ___; X ___
AS1 anything on the screen that read differently: ___; a click fired a shot: yes / no
AS2 T over the buy menu or the settings menu: did nothing / opened (which); after O closed, the cursor stayed the screen's: yes / no
AS3 the count started at ___; PLAYER3 under YOUR TEAM with SELECTING: yes / no
AS4 player 3's row read LOCKED IN ___ s after the buy phase started, on ___; their VFAgentPick: ___
AS5 T did anything in gun game, on its victory screen or in the vote: yes / no (what); the glide: yes / no
AS6 window 2's screen went by itself at 0: yes / no; Updraft bought and sold back: 800 > ___ > ___
AS7 T did anything in deathmatch: yes / no (what)
CB1 anything on Phoenix's card or the bar that read differently: ___
CB3 VFLastFlare: ___; white about ___ s, clearing over ___ s; the Vandal back ___ s after the throw
CB4 VFLastFlare: ___
CB5 facing it: white ___ s, clearing ___ s; your back to it: white ___ s
CB6 VFLastFlare: ___
CB7 E again put it away with nothing spent: yes / no; held fire threw it once: yes / no
CB8 the Sound Lab's three lines: ___
CB9 window 2 saw it and was blinded: yes / no; window 1 too: yes / no
CB10 round the corner, window 2 blinded: yes / no; window 1 blinded: yes / no
CB11 the glow in front of the face, then behind the head: yes / no
CB12 every tile inside the menu: yes / no; Curveball bought and sold back: 800 > ___ > ___
HH1 anything on Phoenix's card or the bar that read differently: ___
HH3 VFLastFire: ___; the fire out ___ s after the burst; the Vandal back ___ s after the throw; Dummy 3: died / lived
HH4 VFLastFire: ___
HH5 thrown up, VFLastFire: ___; lobbed: ___
HH6 VFLastFire: ___; health and shield after its 4 s: ___ + ___
HH7 VFLastFire: ___; the fire went behind the low wall: yes / no; Dummy 7 burned: yes / no
HH8 Q again put it away with nothing spent: yes / no; E and Q swapped them in hand: yes / no
HH9 the Sound Lab's four lines: ___
HH10 player 2 died ___ s after the burst; a jump got them out: yes / no; burned on the step: yes / no
HH11 healed from 30 to ___; after stepping out, to ___; from 50, stopped at ___
HH12 every tile inside the menu: yes / no; Hot Hands bought and sold back: 800 > ___ > ___
HH13 the teammate lost ___ a second (or not tried)
BZ1 anything on Phoenix's card or the bar that read differently: ___
BZ3 VFLastWall: ___; Dummy 1 died ___ s after the wall rose
BZ4 VFLastWall: ___; the Vandal fired: yes / no
BZ5 VFLastWall over the 0.85 m box: ___; through the 1.00 m box: ___
BZ6 VFLastWall up the ramp: ___
BZ7 C again and 1 put it away with nothing spent: yes / no; Q and C swapped them in hand: yes / no
BZ8 the Sound Lab's four lines: ___; Dummy 3 hidden by the wall: yes / no
BZ9 player 2 died ___ s after the fire reached them; a jump got them out: yes / no
BZ10 player 1 seen through the wall: yes / no (what showed)
BZ11 healed from 30 to ___; after stepping out, to ___
BZ12 every tile inside the menu: yes / no; Blaze bought and sold back: 800 > ___ > ___
BZ13 the teammate lost ___ a second (or not tried)
RB1 anything on Phoenix's card or the bar that read differently: ___
RB2 VFLastMark: ___; the Vandal fired or E worked in the first second: yes / no
RB3 seconds from the cast to the flame: ___; back facing 30 degrees left: yes / no; ammo after: ___
RB4 died or a line of yours in the kill feed: yes / no; health and shield after: ___
RB5 VFSpike after the plant was cut off: ___
RB6 the Sound Lab's three lines: ___
RB7 the burst seen: yes / no; the second click hit: yes / no; the kill in the column counted: ___
RB8 window 2's three lines: ___
MP2 the map drawn as the hall is: yes / no (what differs); any of it outside the box as it turned: yes / no
MP3 FIXED and BY SIDE, Turn: ___; SAME WAY, Turn: ___
MP4 size 5 read back as ___; zoom 1.4 kept you in the middle: yes / no
MP5 the big map ___ px across; Caps Lock in the code box opened it: yes / no
MP6 a ring for: running ___, walking ___, firing ___, reloading ___, Updraft ___
MP7 the cone stopped at the cloud: yes / no
MP8 the `?` gone after ___ s
MP9 a dot behind cover: yes / no; behind the cloud: yes / no
MP10 the dot gone while white: yes / no; back after ___ s
MP11 a `?` where player 2 fell: yes / no
MP12 player 3 held on the edge: yes / no; player 2 shown by player 3's sight: yes / no; the X: yes / no
MP13 the defenders' Spike: before ___, looking at it ___, looking away ___, planted ___
MP14 the pulse lasted ___ s
FW2 VFFogLines both still: ___, player 2 walking behind the cover: ___; VFFogMs: ___ and ___
FW3 anything popped in at 100 ms: yes / no (who, and which way)
FW4 Player2 in while running: yes / no; out while walking: yes / no; a label through the cover: yes / no
FW5 the slash heard from the back of the spawn room: yes / no
FW6 the server's root stayed where player 1 spawned: yes / no; anything in window 1 that stopped working: ___
FW9 Player2 in window 1's VFPlayers while player 3 looked at them: yes / no
FW10 window 1's VFPlayers matched window 3's: yes / no
FW11 Player2 in window 1's VFPlayers across the map: yes / no; the shots heard: yes / no
FW12 the pulse showed everyone behind walls: yes / no
HO1 anything on Sage's card or the bar that read differently: ___
HO2 EQUIP for about ___ s; speed with the orb: ___ m/s
HO3 a click with nobody to heal did anything: yes / no (what)
HO6 health after the heal: ___; the green edge lasted ___ s; VFLastHeal: ___
HO7 health after the heal with the Classic's hit: ___
HO8 player 2 marked or healed: yes / no
HO9 the mark with player 3 at full health: yes / no; once hurt: yes / no
HO10 marked or healed behind cover: yes / no
HO11 player 3's health after: ___; VFLastHeal: ___; the countdown from: ___
HO12 the Barrier Orb and the Slow Orb for sale: yes / no
HO13 the countdown in Team Deathmatch from: ___
SO1 anything on Sage's card or the bar that read differently: ___
SO2 EQUIP for about ___ s; speed with the orb: ___ m/s
SO3 VFLastSlow: ___; the ice lasted about ___ s
SO4 speed in the ice: ___ m/s running, ___ m/s walking; the jump line: ___ s, rise ___ m
SO5 slowed in the air before landing: yes / no
SO6 VFLastSlow: ___; ice behind the cover: yes / no
SO7 VFLastSlow: ___, about ___ s after the throw
SO8 Dummy 2's strafe half as wide: yes / no; its steps crunched: yes / no
SO10 anything the Sound Lab logged differently: ___
SO11 player 2's speed in the ice: ___ m/s; their crunches heard in window 1: yes / no
SO12 player 2 slowed on the step: yes / no
SO13 the dash in the ice: ___ m; out of it: ___ m
SO14 max correction before: ___ mm, after: ___ mm
SO15 Q after buying two: ___; a third bought: yes / no
BO1 anything on Sage's card or the bar that read differently: ___
BO2 EQUIP for about ___ s; the targeter about ___ m out
BO3 the targeter at pitch -15: ___ m; at -30: ___ m; at 40: ___ m
BO4 VFWall as it rose: ___; 2 s later: ___
BO5 pos where you stopped: ___; over it with a jump: yes / no
BO6 hits to break the block: ___; a bullet through it before it broke: yes / no
BO7 its number after a swing: ___; after a heavy one: ___
BO8 VFWall 2.5 s into its decay: ___; gone at about ___ s; anything the Sound Lab logged differently: ___
BO9 anything the targeter did differently: ___
BO10 Dummy 1 lifted onto it: yes / no
BO11 the pos line's height on top: ___; any snap back: yes / no
BO12 a targeter out over the edge: yes / no; VFWall: ___
BO13 VFWall over the spike: ___
BO14 player 1 seen through it: yes / no; hits to break a block: ___
BO15 player 2's height on top: ___; any snap back: yes / no
BO16 max correction before: ___ mm, after: ___ mm
BO17 red in the buy phase: yes / no; C after buying: ___; a second bought: yes / no
BO18 your own bullets took health off it: yes / no
RE1 anything on Sage's card or the bar that read differently: ___
RE2 EQUIP for about ___ s; anything the Sound Lab logged differently: ___
RE3 shots to fell Dummy 1: ___; its body along the lane, head toward you: yes / no
RE4 kept down with the orb in hand: yes / no
RE5 marked at pitch 0: yes / no; at -8: yes / no; at -20: yes / no
RE6 the shell rose about ___ m over ___ s; the burst ___ s after the chime; X's pips back after ___ s; the kill feed read: ___
RE7 shots to fell it after: ___
RE8 the wall up before the burst: yes / no; VFWall after it: ___
RE9 the discs' colours in windows 1, 2 and 3: ___
RE10 window 3's health after the burst: ___; held for about ___ s; player 2's hits in the fall took health: yes / no
DC1 anything on Omen's card or the bar that read differently: ___
DC2 EQUIP for about ___ s; the mark about ___ m out; anything the Sound Lab logged differently: ___
DC3 the mark after about 2 s of the left button: ___; at its nearest: ___
DC4 red past about ___ m; anything sent: yes / no
DC5 VFLastSmoke: ___; E's pip back after ___ s
DC6 the dome formed about ___ s after the swish and was whole ___ s later; the bell at ___ s; gone at ___ s
DC7 the screen dark inside it: yes / no
DC8 VFLastSmoke's middle number at the 50 deg ramp: ___; at the 45 deg ramp: ___
DC9 the windows that logged darkSend: ___; darkForm: ___
DC10 player 2 dropped from window 1's minimap behind it: yes / no; every smoke gone with the next round: yes / no
DC11 E's pips as the round began: ___; bought for ___; E back after ___ s
PA1 anything on Omen's card or the bar that read differently: ___
PA2 EQUIP for about ___ s; anything the Sound Lab logged differently: ___
PA3 VFLastParanoia: ___; the orb gone after about ___ s; Q's pip back after ___ s
PA4 VFLastParanoia: ___
PA5 dark past about ___ m, ahead and behind; the muffles' Frequency ___ and the faders' Volume ___; all clear after about ___ s
PA6 window 2 warned: yes / no; windows 1 and 3 warned: yes / no; window 2 dark about ___ s after the send; its Seen while dark: ___; the wisp in windows 1 and 3: yes / no
PA7 window 2's VFBlind after the first flare: ___; after the second: ___
PA8 Q's pip as the round began: ___; bought for ___; E 40 s into the round: ___; E once the smoke came back, and 40 s after: ___
SS1 anything on Omen's card or the bar that read differently: ___
SS2 EQUIP for about ___ s; the ring about ___ m out, and ___ m at pitch 20; anything the Sound Lab logged differently: ___
SS3 pos after the step: ___; VFLastStep: ___; dark for about ___ s; drawRifle heard as you arrived: yes / no; the Vandal back after ___ s; C's pip back after ___ s
SS4 moved or jumped before you were there: yes / no; walked on after: yes / no
SS5 the ring at pitch -18: ___; pos after the step at pitch -30: ___
SS6 pos after the step onto the box: ___
SS7 pos after the step at the wall: ___; the ring at pitch 75: ___
SS8 the windows that logged stepGo: ___; stepArrive in window 3: ___; in window 2: ___; the swirl, puff, column and form in windows 2 and 3: yes / no
SS9 the health over player 1's head after the shots at the column: ___; hit once there: yes / no
SS10 C's pips as the round began: ___; bought for ___ each; the minimap's Step: yes / no; the ring past the barrier in the buy phase: yes / no; red over it: yes / no; C after the step once live: ___
FS1 anything on Omen's card or the bar that read differently: ___
FS2 EQUIP for about ___ s, then: ___; the Plan: ___; Cursor: ___; the cursor moved with the mouse: yes / no; anything the Sound Lab logged differently: ___
FS3 Cursor pushed off the map: ___; red there and at the corner: yes / no; anything fired: yes / no
FS4 VFLastShadow: ___; pos as a Shade: ___; the windup about ___ s; Sight at first ___, half way ___, at the last ___; drawRifle heard at the click: yes / no, and as you formed: yes / no; the Vandal ready after ___ s; X's pips back after ___ s
FS5 moved or jumped before you formed: yes / no; the view turned: yes / no; walked on after: yes / no
FS6 X in the windup did anything: yes / no; pos after X as a Shade: ___; drawRifle heard as you were sent back: yes / no; VFKit after: ___
FS7 pos on the box: ___; on the tunnel's roof: ___; by the backstop: ___
FS8 the windows that logged shadowGo: ___; shadowArrive in window 2: ___; in window 3: ___; the swirl, puff, Shade and form: yes / no
FS9 player 1's pos after the shot: ___; their health after: ___; what each window logged: ___
FS10 the big map up: yes / no; the cursor red in the buy phase: yes / no; anything fired: yes / no
FS11 Placeable as the round went live: ___, after about ___ s; window 2's Dark while it ran: ___, for about ___ s; window 3's: ___; the minimap's Shade in window 1: yes / no; window 2's cleared as player 1 was sent back: yes / no
RC1 anything on Sova's card or the bar that read differently: ___
RC2 EQUIP for about ___ s; the bars and diamonds under the crosshair: yes / no; anything the Sound Lab logged differently: ___
RC3 the bars about ___ s apart; the bounces 1, 2, 0: yes / no; anything loosed after E let the draw go: yes / no
RC4 VFLastBolt: ___; stuck about ___ s after the loose; the Vandal back after ___ s; E's pip back after ___ s; pings ___ s and ___ s after it stuck, gone after ___ s; VFLastRecon: ___
RC5 VFLastBolt with 1 bar: ___; with 2: ___, VFLastRecon: ___; with 3: ___, VFLastRecon: ___
RC6 VFLastBolt with one bounce: ___, VFLastRecon: ___; with two: ___; off the backstop: ___
RC7 VFLastBolt: ___; VFLastRecon at each pulse: ___
RC8 VFBoltHealth after the shot: ___; a second ping: yes / no
RC9 what windows 2 and 3 logged: ___; anyone red in windows 2 or 3: yes / no; VFLastRecon: ___
RC10 VFBoltHealth after window 2's shot: ___; the windows that logged boltBreak: ___
RC11 VFKit as the round began: ___; Owl Drone and Shock Bolt FULL: yes / no; a Recon Bolt tile: yes / no
RC12 VFLastRecon: ___; player 2 red in window 1: yes / no, window 3: yes / no, window 2: yes / no; Seen while it lasted: ___; E back after ___ s
RC13 VFBoltHealth after player 3's shots: ___; after player 2's: ___; pulsed after player 2's: yes / no
SB1 anything on Sova's card, the bar or the hover that read differently: ___
SB2 EQUIP for about ___ s; the bolt's colour in hand: ___; anything the Sound Lab logged differently: ___
SB3 VFLastShock: ___; burst about ___ s after the loose; VFShockHits: ___; Dummy 3's label: ___; the Vandal back after ___ s; Q's pip back after ___ s
SB4 VFLastShock: ___; VFShockHits: ___; Dummy 1's label: ___; your HUD: ___; the kill feed after the second: ___
SB5 VFLastShock and VFShockHits with 1 bar: ___; with 2: ___; with 3: ___
SB6 VFShockHits: ___; your HUD after: ___
SB7 VFLastShock: ___; burst where it first met the floor: yes / no
SB8 VFLastShock: ___; VFShockHits: ___
SB9 what windows 2 and 3 logged: ___; window 2's HUD: ___; window 3's: ___; VFShockHits: ___
SB10 VFKit as the round began: ___; windows 2 and 3 after the burst: ___; VFShockHits: ___
SB11 VFKit as the round began: ___; bought for ___ each; a third bought: yes / no; Q after the loose: ___
HF1 anything on Sova's card or the bar that read differently: ___
HF2 EQUIP for about ___ s; the seconds from: ___; the ammo box: ___; the minimap's band: yes / no; the bow gone at 0: yes / no; X8/8 back after ___ s; anything the Sound Lab logged differently: ___
HF3 the windup about ___ s; Turn while it charged: ___; VFLastFury: ___; VFFuryHits: ___; the labels after: ___; pos after: ___; Revealed: ___
HF4 VFLastFury: ___; the kill feed: ___; pos after: ___; VFKit after: ___; the bow gone at 0: yes / no
HF5 pos through the windup: ___; anything from the early click: yes / no; the third blast after ___ s
HF6 a blast after 1: yes / no; after Q: yes / no; with 0.6 s left: yes / no; how full the lower bar got: ___
HF7 VFFuryHits: ___; the labels after: ___
HF8 VFFuryHits: ___; Dummy 6's label: ___
HF9 what windows 2 and 3 logged: ___; the charge's ball in window 3: yes / no; window 2's HUD: ___; window 3's: ___; VFFuryHits: ___; player 2 red in window 1: yes / no, window 3: yes / no
HF10 VFKit after VFTestGive: ___; what each window logged: ___; VFFuryHits: ___; window 2's health after: ___
HF11 what window 2 took: ___; window 3's: ___; VFFuryHits: ___; player 2 red in window 1: yes / no, window 3: yes / no, window 2: yes / no; Seen while it lasted: ___
OD1 anything on Sova's card, the bar or the buy menu's hover that read differently: ___
OD2 EQUIP for about ___ s; anything the Sound Lab logged differently: ___; VFKit after C again: ___
OD3 the view stopped about ___ m on; VFDroneId: ___; C's pip back after ___ s; your body at the spawn: yes / no; the view back after ___ s, the Vandal ready ___ s after that
OD4 VFLastDart: ___; pos while it flew: ___; how far down the lane it got: ___
OD5 VFLastDart from the top: ___; from the floor: ___
OD6 VFLastDart: ___; VFDartHit: ___; [Target Hit] for about ___ s; a second dart at once: yes / no; the pings ___ s and ___ s after the dart
OD7 VFLastDart at yaw 10: ___; at Dummy 11: ___; VFDartHit at Dummy 11: ___
OD8 stopped at the wall after ___ s; at the backstop after ___ s; VFLastDart: ___
OD9 the view back at once: yes / no; [Target Hit] stayed: yes / no; Dummy 1 still pinged: yes / no
OD10 what windows 2 and 3 logged: ___; the drone seen in both: yes / no; Drones in window 1: ___
OD11 VFDartHit: ___; TAGGED in window 2 for about ___ s; player 2 red in window 1: yes / no, window 3: yes / no
OD12 VFDroneHealth after each shot: ___; the burst in every window: yes / no
OD13 VFKit as the round began: ___; Owl Drone and Shock Bolt FULL: yes / no; a Recon Bolt tile: yes / no
OD14 Drones in window 2 before it came near: ___, after: ___; in window 3: ___; player 2 red in window 1: yes / no, window 3: yes / no, window 2: yes / no; Seen while it lasted: ___
OD15 VFKit in round 2's buy phase: ___; VFDroneHealth after player 3's shots: ___; after player 2's: ___
OD16 VFKit as the round began: ___; bought for ___; a second bought: yes / no; C after the launch: ___
OE1 a card read TAKEN before anyone locked in: yes / no; SOVA outlined in both windows: yes / no; PLAYER3 on SOVA, SELECTING, in window 1: yes / no
OE2 window 3's SOVA card read TAKEN: yes / no; VFAgentSelected after the lock: ___, after a click on SOVA: ___; under the button: ___
OE3 player 2's VFAgent: ___
OE4 player 3's VFAgent: ___, VFAgentPick: ___; JETT TAKEN in window 1: yes / no
OE5 player 1's VFAgent: ___, player 3's: ___; window 1's VFKit: ___
UO1 VFOrbs: ___; Orbs in both windows: ___
UO2 the map: ___; the orb's look: ___; the prompt came up about ___ m from the disc's middle
UO3 shots fired while held: ___; logged in window 1: ___, in window 2: ___; player 1's gun in window 2 while F was held: shown / none; VFOrbs after letting go: ___; VFKit: ___
UO4 the bar took about ___ s; moved while held: yes / no; logged in window 1: ___, in window 2: ___; VFOrbs after: ___; Orbs: ___; VFKit after: ___
UO5 a prompt, bar or whoosh for player 2 at orb 1's disc: yes / no
UO6 VFOrbs in round 2: ___; VFKit: ___
UO7 the defuse with F: started / didn't; the result: ___
UO8 VFKit after VFTestGive: ___; VFOrbs after: ___; VFKit after: ___
UO9 VFOrbs in Swiftplay's round 1: ___; after off: ___
UP1 player 1's VFKit: ___; player 2's, on Sage: ___
UP2 right after the kill, player 2's VFKit: ___, player 1's: ___; in round 2's buy phase, player 1's: ___
UP3 player 1's VFKit after the plant: ___; the blast killed player 1: yes / no; in round 3's buy phase, player 1's: ___, player 2's: ___
UP4 player 1's health after the first bolt: ___; killed by the second: yes / no; VFKit in round 4's buy phase: ___
UP5 player 2's VFKit after the kill: ___; in round 5's buy phase, player 1's: ___, player 2's: ___
UP6 the score before round 9: ___; round 9's line: ___; VFKit then, player 1's: ___, player 2's: ___
UP7 player 1's VFKit in round 1: ___; in round 13: ___
UP8 the score before round 25: ___; round 25's line: ___; player 1's VFKit: ___
UP9 player 3's health after the first bolt: ___; player 1's VFKit after the kill: ___; player 3's in round 2's buy phase: ___
GA1 window 1's Yours: ___, Theirs: ___; window 2's Yours: ___, Theirs: ___
GA2 the boxes' letters and colours: ___; ULT: ___; Ult: ___
GA3 window 1's Yours: ___; window 2's Theirs: ___; Player1's ULT there: ___, in gold: yes / no; Ult: ___
GA4 window 1's Yours after the shot: ___, after the kill: ___; window 2's Theirs: ___; Ult: ___
GA5 on the victory screen, the agents' boxes: shown / gone; ULT: shown / gone; Ult: ___
GA6 gun game's tiles: ___; Yours: ___, Theirs: ___; the boxes and ULT: shown / gone
PI1 Shown: ___; Left: ___, then ___; faint under the crosshair: yes / no; solid off it: yes / no; gone after ___ s
PI2 the sky's ping: marked / nothing, Left: ___ to ___; Dummy 1's Shown: ___, in red: yes / no
PI3 Shown: ___
PI4 Shown: ___, in orange: yes / no
PI5 the wheel's calls: ___; Wheel moved right: ___; shut: nothing pinged yes / no; Shown: ___
PI6 beeps: ___; Shown: ___; Left: ___; the wheel greyed: yes / no; Left back to 1 after ___ s
PI7 with the cloud, Shown: ___; after it, Shown: ___
PI8 windows that logged ping: ___; Pings in windows 1, 2 and 3: ___, ___, ___; window 3's colour: ___
PI9 the wheel as the big map came up: gone / stayed; Cursor: ___, then ___, then ___; Z: pinged / nothing
PI10 windows that logged mapPing: ___; Pings in windows 1, 2 and 3: ___, ___, ___; in the world: shown / not
PI11 window 1's Shown: ___; Pings in windows 1, 2 and 3: ___, ___, ___; window 2 heard it: yes / no
PI12 Z while dead: nothing / pinged; the map ping in windows: ___; the click switched whom you watch: yes / no
CR1 Shown before N: ___; after N: Shown ___, Rows ___, Totals ___; after N again: Shown ___
CR2 Rows: ___; Totals: ___; the figure's body: lit / dim, ___
CR3 Rows: ___; KILLED in gold: yes / no
CR4 the details' lines: ___; Details: ___, then ___
CR5 look line: ___; N changed the colour: yes / no; the row purple: yes / no
CR6 up without N: yes / no; Killer: ___; Rows: ___; Totals: ___; window 2 showed one: yes / no
CR7 the details' lines: ___; gone on coming back: yes / no; the new life's Rows: ___
CR8 window 2's Rows: ___; Killer: ___
CR9 window 1's Rows: ___; Round: ___; Final ___, then ___; window 2 showed one: yes / no
CR10 in the buy phase, Final and Round: ___, ___; window 2's Rows: ___; N hid and showed it: yes / no; gone as the round went live: yes / no
DI1 Hurt ___, LastHurt ___, Danger ___, Critical ___; the health and the magazine white: yes / no
DI2 after eight: ___, white / red, LowAmmo ___; after nine: ___, white / red, LowAmmo ___; reloaded: ___, white / red
DI3 VFLastShock: ___; an arc on the left: yes / no; Hurt ___, then ___; LastHurt ___
DI4 LastHurt at yaw 90: ___; at -90: ___; at 0: ___; 4 m down the lane: ___
DI5 window 1's watch: ___; window 2's watch printed more: yes / no
DI6 the watch: ___; the health: ___, then ___, red: yes / no; as player 1 died: ___; LastHurt once back: ___
DI7 VFDroneHealth: ___; the watch while flying: ___; after C: ___
DI8 the watch: ___; player 1's health and shield: ___
DI9 the watch: ___; an arc: yes / no; the diamond: yes / no; the kill feed: ___
DI10 the watch: ___; player 1 burned: yes / no
KB1 Count ___, Shown ___; anything between the crosshair and the ability bar: yes / no
KB2 the kill feed: ___; the watch: ___; the diamond's number ___, bars lit ___, a red X: yes / no, the name ___; gone after about ___ s
KB3 the kill feed: ___; the watch: ___; a red X: yes / no; the same size: yes / no
KB4 the watch: ___; gold from the fifth: yes / no; the sixth's number and bars lit: ___
KB5 the kill feed: ___; the watch: ___; anything else died: yes / no
KB6 window 1's watch: ___; window 2's watch: ___
KB7 window 2's watch in round 1: ___; in round 2: ___; window 1's watch printed more: yes / no
CO1 window 1's watch: ___; window 2's watch: ___; then: ___
CO2 window 2's watch: ___; window 1's watch: ___; window 2's banner and the line under it: ___
CO3 window 2's watch: ___; window 1's watch: ___
CO4 window 2's watch: ___; windows 1 and 3: ___
CO5 windows 1 and 3: ___; window 2: ___; window 2's banner colour: ___
CO6 windows 1 and 3: ___; window 2: ___
CO7 window 2's watch: ___; window 1's watch: ___
TB1 window 1's cards: ___; window 3's: ___; window 2's: ___; the help line's end: ___
TB2 the watch: ___; window 1's blip: yes / no; player 3's card in window 1: ___; window 3's Sheriff tile: ___; window 2 played anything: yes / no
TB3 the watch: ___; the Sheriff in player 3's hands: yes / no
TB4 the watch: ___
TB5 the watch: ___
TB6 the watch: ___; window 1's EXTRA button: ___; player 1's card in window 3: ___
TB7 the watch after the Spectre: ___; after the Stinger: ___; player 3's card in window 1: ___; after the last BUY: ___
WF1 the Output: ___; the buy phase's line: ___; player 1 behind the barriers with the spike: yes / no
WF2 the six views: ___; anything floating, sunk, poking through or flickering: ___; too plain, about right or too busy: ___
WF3 the counts: ___; in the way: ___; the five rays: ___; MidBottomCrate's Transparency, CanCollide and VFKitPiece: ___
WF4 the first line: ___; the magenta crate: ___; the second line: ___; the crate after: ___
WF5 held at every door: yes / no; the other spawn in sight: yes / no; the plant at A: yes / no; player 1's time: ___ s, player 2's: ___ s; in the way or too tight: ___; too big, about right or too small: ___
WH1 the Output: ___
WH2 the six views: ___; anything floating, sunk, poking through or flickering: ___; the steps on their slopes: ___
WH3 player 1, the stairs, the railing, the drop and back up: ___; hookah's window: ___; player 2, heaven's stairs, the window's stairs and frame, the ramps and the platform: ___; anything that stopped or tripped: ___
WH4 heaven's railing, standing / crouched: ___ / ___; the window's frame, standing / crouched: ___ / ___; the lane from the frame: ___
WH5 A: player 1 ___ s, player 2 ___ s; B: player 1 ___ s, player 2 ___ s; heaven, the window and the platform worth taking: ___; A or B easier to take: ___
BT1 the five lines: ___
BT2 the five lines with 2 players: ___; after window 2 closed: ___; a player joining on the published place: ___
BT3 yours: ___; theirs: ___; board: ___; drawn: ___; anything wrong in the screenshots: ___
BT4 the first round: ___; the next two: ___; anyone spending more than they had: yes / no
BT5 Outpost: ___; Quarry: ___; Foundry: ___; Wharf: ___; the stuck at lines: ___; together, spread out and never against a wall: yes / no
BT6 the distances: ___; anyone left behind or walking into a wall: ___
BT7 rounds won / lost: Easy ___ / ___, Normal ___ / ___, Hard ___ / ___, Expert ___ / ___; too good, about right or too easy: ___; robotic: ___
BT8 VFBotMs: ___; with VFBots false: ___; back on: ___
BS1 the Output's lines: ___; the plant and the guarding: ___
BS2 dropped for a bot: ___; planted yourself: ___
BS3 the HUD's line: ___; the mark on the bot: yes / no; SPIKE PLANTED for a bot's plant: yes / no
BS4 the bots' retake: ___; with you defusing: ___
BS5 VFBotMs around a plant on Wharf: ___
BC1 the script before: ___; after: ___; the view and the HUD: ___; the takeover lines: ___
BC2 the two numbers: ___ ___; the carrier's takeover, your plant, the takeover with it planted: ___
BC3 kills: ___; your VFLoadout next round: ___; the bot's and its credits: ___; after dying in a body: ___
BC4 Competitive: ___; Swiftplay: ___; once a round's decided: ___; Team Deathmatch: ___
BC5 who got it: ___; what the other saw: ___
AB1 the head in its box: ___; the stance: ___; VFBodyMs: ___
AB2 what looked wrong, and moving which way: ___
AB3 what looked wrong: ___
AB4 the plant: ___; the defuse: ___
AB5 the hits: ___; the Shade: ___; the force field: ___
AB6 the most bodies and VFBodyMs: ___ ___; VFBodyMs looking away: ___; fps with them in view: ___, looking away: ___
AB7 blocks without a body: yes / no; the bodies again: yes / no
BK1 before the window closed: ___; after: ___; the scoreboard and the top bar: ___
BK2 after round 1: ___; after round 2: ___
BK3 shot while blinded: yes / no; VFBlind: ___; the nearsighted bots shot from about ___ m
BK4 VFLastHeal: ___; VFLastRecon: ___; VFFuryHits: ___
BU1 round 1's VFKit lines before the lock: ___; after it: ___; round 2's: ___
BU2 the casts: ___; a Sova's recon, carrying the spike or late: ___; the smokes and flashes: ___; after starting over: ___
BU3 what came, and how long after: ___
BU4 the guards' casts: ___; the defuser: ___
BU5 the heal's lines: ___
BU6 VFBotMs on a push: ___; a throw on its own side: yes / no
RK1 the lines after each match: ___; the screen's line steady: yes / no; placed: side 1's player ___, side 2's ___
RK2 the 13-11: ___ ___; the 13-0: ___ ___
RK3 the promotion: ___; the demotion or shield: ___; matches it took: ___
RK4 Swiftplay's lines with its victory screen: yes / no; Competitive's card: ___; Swiftplay's: side 1's ___, side 2's ___
RK5 the leaver's line: ___; the match's end: ___
RK6 before: ___; after: ___
PD1 the lines: ___; the warning: none / ___
PD2 half 1 s: ___; full 0.2 s: ___; full 1 s: ___; up: ___; inverted: ___; padLook 110: ___
PD3 Focus: ___, ___ degrees; the sights: ___, ___ degrees; let go: ___
PD4 the lines: ___; the second zoom on the way out: yes / no; back from the second: ___
PD5 Updraft: ___; the gust and dash: ___; the tap: ___; Blade Storm: ___; Cloudburst: ___
PD6 Y: ___; the knife: ___; crouching: ___; the prompts: ___ ___; the spike: ___
PD7 pings: ___; the buy menu's cursor: on / pick / off; menus: ___; map, scores: ___
PD7 takeover: ___; the takeover lines: ___
PD8 what felt off: ___; the cursor: ___
RJ1 held: ___; the bot on their side: ___, its agent: ___
RJ2 the button and line: ___; back: ___; credits before ___, after ___; the bot gone: yes / no
RJ3 in line: ___; back as the round ended: ___
RJ4 the career line: ___; let go: ___
RJ5 the career line: ___
RJ6 RECONNECT came: yes / no; where it put you: ___
AF1 warned: ___; the line: ___; seconds to the warning: ___
AF2 a move: ___; a look: ___; a buy: ___; the crouch held: ___
AF3 as the round ended: ___; as it came back: ___
AF4 taken out: ___; the menu and line: ___; the bot: ___; back: ___
AF5 a warning: yes / no
TC1 the lines: ___; buttons(): ___; anything overlapping or off the screen: ___
TC2 the lines: ___; speeds: run ___, walk ___
TC3 right ___, up ___, touchLook 240 ___, zoomed ___; firing and turning at once: yes / no
TC4 the lines: ___; anything that didn't happen: ___
TC5 the lines: ___; anything that didn't open or shut: ___
TC6 the lines: ___; the takeover lines: ___
TC7 the prompts: ___ / ___; planted: yes / no
TC8 what felt off: ___; the sizes: ___; Touch look: ___
TR1 the lines: ___; the panel and the column: ___
TR2 the lines: ___; anything that moved on before you were there: ___
TR3 the lines: ___
TR4 the lines: ___
TR5 the lines: ___
TR6 the lines: ___
TR7 the lines: ___
TR8 the lines: ___
TR9 the lines: ___
TR10 the lines: ___
TR11 where each PLAY took you: ___
TR12 what to change: ___
RY1 the lines: ___; her card: ___
RY2 the lines: ___; the ball: ___
RY3 the lines: ___
RY4 the lines: ___; the overheal went ___ s after the bell
RY5 the lines: ___; the screen in it: ___
RY6 window 1's health after the first burst: ___; what window 2 saw: ___; the second burst: ___
RY7 the lines: ___
RY8 the soul lines: ___; the Reyna bots' kills: ___
RY9 what to change: ___
LR1 the lines: ___
LR2 a screenshot of it in hand: ___
LR3 the lines: ___; a screenshot of the eye open: ___
LR4 the lines: ___
LR5 the lines: ___
LR6 window 1's lines: ___; window 2's lines: ___; a screenshot of window 2 dark: ___
LR7 window 2's lines: ___
LR8 the lines: ___
LR9 the leer lines: ___; a VFLastLeered naming someone: ___
LR10 what to change: ___
EM1 the lines: ___; her card: ___
EM2 the lines: ___
EM3 the lines: ___; a screenshot of the frenzy: ___; one of the eye in hand: ___
EM4 the lines: ___
EM5 the lines: ___
EM6 the lines: ___
EM7 what window 2 saw in the frenzy: ___; in the Dismiss: ___
EM8 the lines: ___
EM9 the lines: ___; what window 2 saw of the Dismiss: ___; window 3: ___
EM10 the empress lines: ___; the soul lines: ___
EM11 what to change: ___
Didn't look right (IDs and what you saw):
```

## Which check covers which known gap

| Research doc | Known gap | Checks |
| --- | --- | --- |
| 01 | The client's per-frame root CFrame wins over the replicated one without flicker | T1 |
| 01 | Collision with ramps, the angled wall and the jump boxes' faces | M5, M6, M7 |
| 01 | Whether `GetMouseDelta` needs Roblox's sensitivity divided out | C3 |
| 01 | Air strafing with a real mouse at Roblox frame rates | M11 |
| 02 | Mouse buttons reach the game, and right-click isn't taken by the camera scripts | C1 |
| 02 | Viewmodel and muzzle flash in front of a scriptable camera at 103 degrees | C2 |
| 02 | The `VFCharacters` group keeps characters out of shot traces | W6, T3 |
| 02 | Other players' avatars stay hidden and only their blocks show | T2 |
| 02 | Death and respawn with an anchored root and `BreakJointsOnDeath` off | T4 |
| 03 | The camera kick at 60 and 240 fps, and the HUD ring on the impacts | R5, R2 |
| 03 | The first ack after spawning corrects the seed before the first shot | W5 |
| 03 | The Spray Lab's plot matches the marks on the wall | R1 |
| 04 | The render clock settles on Roblox's real snapshot timing | H1 |
| 04 | `viewTime` is read before remote entities move | H2, H3 |
| 04 | Hit confirms stay on the body part and go when the target dies | H4 |
| 04 | About 100% agreement against strafers, with white boxes in the overlay | H2, H3, H5 |
| 04 | Pacing keeps other players and dummies smooth with Roblox's real timing | H9, T1 |
| 04 | Shots right after joining are rewound as little as later ones, and Studio sends 60 snapshots a second | W5, H1 |
| 05 | Rays that start inside a part don't hit it, and the back cast's normal faces out | S1 |
| 05 | The self-test's parts are found by raycasts one frame after they're added | S1 |
| 05 | Holes, dust and sparks on the right faces, other players' holes, white wall labels | P2, P4, T5 |
| 06 | Lighting set from the client shows there, and V puts the place's values back exactly | V1 |
| 06 | The vignette sits over the world and under the HUD, covers the screen and takes no clicks | V2 |
| 06 | Outlines only on the visible part of a target, the tint grows with distance, I changes it | V3, V4, T7 |
| 06 | Hidden avatars cast no shadows | V5 |
| 06 | The preset with LightingStyle on Soft and on Realistic | V6 |
| 07 | The arena builds beside the course, with nothing in the place overlapping it, on every client | A1, A2 |
| 07 | Spawns in your side's room facing the hall, and a clean new life when a round restarts while you're alive | A1, A4, A8 |
| 07 | The barriers hold players and bullets in the buy phase and are gone when it ends | A6 |
| 07 | Teammates in blue and opponents in red, and bullets pass through teammates | A7, A12 |
| 07 | The top bar and the banner follow the rounds on both screens | A5, A8, A9, A10 |
| 07 | P turns it on and off, and off puts everyone back on the course | A4, A11 |
| 07 | Whether 19 m feels right | A2 |
| 08 | Every sound loads and plays, from the right place, at a sensible volume next to the others, and sounds like what it stands for | N1, N4, N5, N7 |
| 08 | Others' steps sound where they're drawn and stop at 20 m; walking, crouching and a crate landing are silent | N3, N8, N10 |
| 08 | Walls muffle, and the filter doesn't click when a sound starts | N10 |
| 08 | Nothing is heard twice with voice chat on | N12 |
| 08 | Your own steps don't cover anyone else's | N10 |
| 08 | The buy phase is silent from the other side | N9 |
| 09 | Every gun can be given, draws in its own shape and colour, and fires as the weapon lab says | G1, G3, G4, G5, G7 |
| 09 | A shotgun draws a tracer and a hole for each pellet and shows one hit marker and one number | G2 |
| 09 | A Bucky or a Marshal reloads a round at a time, with a sound for each, and a shot stops it | G6 |
| 09 | The other player sees a Bucky's 15 tracers, and none of a suppressed gun's from the other side | G8 |
| 09 | Each gun's shot sounds like its own | G1 |
| 09 | B opens the menu only while buying is open, it fits the screen, and while it's open the view stays still, a click never fires and the keys still move you | B1, A6, B9 |
| 09 | Hover shows the numbers, a click buys and draws, a right click sells back only this buy phase's purchases | B3, B4, B5 |
| 09 | The HUD shows Light Armor's split and the Regen Shield refilling as the tests have them | B6, B7, B8 |
| 09 | A new match in the arena puts everyone back on the starting kit | A9, B9 |
| 09 | A buy the moment a buy phase opens lands on the new life and can be sold back | B10 |
| 10 | The slash and the stab come at their rates, round the combo, and the swap cuts a stab short | K1, K8 |
| 10 | Each does its damage from in front and from behind, through the shields, and kills as the tests have it | K2, K3, K9 |
| 10 | A swing never reaches through a wall, a barrier or a teammate, but reaches a head over cover | K6, K9 |
| 10 | The cut appears at once on a wall, on the right face, and others see their opponent's cuts | K5, K9 |
| 10 | The sweep reads as a swing in each direction, and the sounds are heard where they should be, none of them louder than a gunshot | K1, K5, K9 |
| 10 | The overlay's reach matches where hits stop landing | K4, K7 |
| 11 | The menu opens on O, its boxes take typing without moving the player, and the cursor and the view behave as with the buy menu | X1, X2 |
| 11 | The crosshair is drawn crisply on the middle of the view, with its outline ring snug round each piece | X3, X4, X8 |
| 11 | It moves out with the errors and back | X5, X6 |
| 11 | The scope shows only the sniper dot, and aiming down sights uses the `A` crosshair when it should | X7, X8 |
| 11 | The settings are kept when the place can use data stores, and the menu says why not when it can't | X9 |
| 11 | The sensitivity turns the view by the expected amount | X2, C3 |
| 12 | The spike can be found, picked up by running over it, drawn with 4 and dropped with G, and lands on the ground short of walls | D1, D2, D9 |
| 12 | Holding 4 plants it in a site and defuses it, with the bar and the prompts, rooted, without the view or the bar jumping from a correction | D3, D4, D7 |
| 12 | The beeps keep time, faster at 25, 35 and 40 seconds, and come from the spike | D5 |
| 12 | A defuse stops when its defuser crouches out of sight of the spike | D8 |
| 12 | The blast kills everyone within 35 m, through walls, and no one further | D6, D10 |
| 12 | Another player sees the spike, its tells and the blast, and hears the plant and the defuse from where they are | D10 |
| 12 | The sounds are at sensible levels next to the others | D4, D5, D6, D7, N4 |
| 13 | Outpost builds at its origin with nothing overlapping it, and plays at the right scale | E1, E2 |
| 13 | Each side spawns in its role's spawn facing out, and the spawns swap at the half | E1, E4, E11 |
| 13 | The spike lies in front of the attackers each round, only attackers pick it up, plants work only while the round is live, and only defenders get the defuse prompt | E3, E5, E6, E7, E10 |
| 13 | Each way of ending a round shows its banner and scores, the half and the overtime round are labelled, and a match ends and starts again | E6, E8, E9, E10, E11, E12 |
| 13 | The Classic and the knife at each half and after a death, while survivors keep theirs | E4, E7, E8, E11, E12 |
| 13 | The round's clock agrees with the server, and gives way to `SPIKE` at the plant | E4, E5, E6 |
| 14 | The buy menu's credits, stakes and dimmed tiles, and the hover panel's costs and refunds | Q1, Q2, Q5, Q6, Q11 |
| 14 | Charging, refunds, buying back and selling back to nothing, all in a real buy phase | Q2, Q6, Q8 |
| 14 | A shield carried damaged into the next round, the Regen Shield's pool with it, and renewing it | Q7, Q8 |
| 14 | Kill pay with two players, and the plant's pay | Q4, Q9 |
| 14 | The payouts over a few rounds, and the half's and Swiftplay's reset | Q5, Q8, Q10, Q11 |
| 15 | G drops the gun in hand ahead of you and the next weapon comes out, with the knife and the spike as the tests have them | L1, L9 |
| 15 | The gun is drawn lying on the floor, short of walls, and another player sees it land and go | L1, L8, L10 |
| 15 | Walking over a gun fills an empty slot without drawing it, and a full slot walks past it | L2, L5, L12 |
| 15 | F's outline and prompt, at 3 m and not through walls, and the swap | L4, L5, L6, L7 |
| 15 | Rounds kept through a drop and a pickup | L3, L11 |
| 15 | Death drops in the spike rounds, picked-up guns kept into the next round, and the ground cleared | L11, L12, L14, L15, L16 |
| 15 | Nothing to sell back after a drop | L13 |
| 16 | The kill feed's lines, their colours, the headshot and wall marks, and the gold outline | J1, J2, J3, J4, J6 |
| 16 | The players' tiles beside the top bar, dimmed when they die | J5, J6 |
| 16 | Tab holds the scoreboard in the spike rounds, in place of Roblox's player list | J5, J7, J10 |
| 16 | The record and the ACS as the tests have them, on every client | J7, J9, J11 |
| 16 | Your side's credits and loadouts, and the other side's credits only as the round started | J7, J8 |
| 17 | The bar shows the kit as the tests have it, and lights and counts down as casts go | U1, U2, U4, U12 |
| 17 | Updraft throws you about 4 m up from the ground and from the air, and you land as from a jump | U2, U3 |
| 17 | Tailwind's windup, its window and its dash, the way you're moving or forward, about 7 m, and no faster than a run after it | U4, U5, U6 |
| 17 | Nothing fires during a dash, the zoom comes off, and a dash ends a lift | U7, U8 |
| 17 | Nothing casts while planting, and a plant doesn't start in a dash | U10 |
| 17 | Another player sees and hears each cast where you are on their screen | U9, U11 |
| 17 | The spike rounds' kit: charges bought and sold back, kept through a death, and the ultimate's points | U12, U13, U14, U15 |
| 18 | C throws it at once from the eye, the way you look, and the gun comes back a quarter of a second later | Y2, Y3 |
| 18 | It flies straight at 30 m/s, through the dummies, and bursts on a wall, on the floor, or in mid-air 60 m out | Y2, Y4, Y5 |
| 18 | Holding C curves it towards the crosshair, and letting go straightens it | Y7 |
| 18 | The cloud grows, stays and thins as the tests have it, and hides what's behind it, the outlines included, until it thins | Y2, Y5 |
| 18 | From inside it the screen is smoke | Y6 |
| 18 | Nothing is thrown in a dash or while planting | Y8 |
| 18 | The throw and the burst are heard, the burst out to 30 m | Y9 |
| 18 | Your cloud forms where the server says, on your screen at once | Y2, Y4, Y5, Y7 |
| 18 | Another player sees the throw fly and the cloud form where it burst, and hears both, even once the thrower is dead | Y10, Y11 |
| 18 | Cloudburst is on sale in the spike rounds, two charges at 200 | Y12 |
| 19 | With its points full, X casts it: the knives come up over about a second, and the HUD shows 5 | Z1, Z2 |
| 19 | A click throws one, straight to the crosshair standing, running or in the air | Z3, Z5, Z10 |
| 19 | Three to the body or one to the head kills a dummy, and the kill brings all five back | Z3, Z4 |
| 19 | Alt fire throws all that are left, spread round the crosshair, and its kills bring none back | Z8 |
| 19 | A knife stops at the first wall it meets | Z6 |
| 19 | They're gone a sixth of a second after the last, or half a second after a burst, and the gun comes back | Z7, Z8 |
| 19 | A number key draws a gun with the knives kept, and X draws them again in half a second | Z9 |
| 19 | Cloudburst, Updraft and Tailwind work with the knives out | Z10 |
| 19 | On the course the points fill again once it's over | Z7, Z8 |
| 19 | The cast, the throws and a body hit are heard | Z2, Z3, Z11 |
| 19 | Another player sees your cast and your knives' streaks, and hears both | Z12 |
| 19 | A death ends it | Z13 |
| 20 | Holding Space through a jump, the way down is slow: `vert` reads `-2.00` and `state` reads `glide`, and the jump line about 0.81 s | I1 |
| 20 | Held from the top of Updraft, about 3 s in the air | I3 |
| 20 | Pressed in a fall, the fall slows at once; let go, it speeds up again | I3, I4 |
| 20 | Held into a landing, it doesn't jump again until it's pressed again | I2 |
| 20 | A dash in a glide flies level, and the glide takes up again after it | I5 |
| 20 | A gun's cone is the air's in a glide, and Blade Storm's knives land on the crosshair | I6 |
| 20 | Your glide is heard as a soft run of gusts | I1, I7 |
| 20 | Another player sees and hears a glide where you are on their screen | I8, I9 |
| 21 | A published server starts Skirmish by itself | F6 |
| 21 | A third player joins the side with fewer players, and spawns at once in a buy phase | F1 |
| 21 | Down with a teammate alive: 2 s where you fell, then their view from their eyes, with their name and when you play; their blocks aren't drawn, and clicks switch between teammates | F2 |
| 21 | Tab shows the scoreboard in Skirmish, with no credits | F3 |
| 21 | At the end of a match, the victory screen shows by itself: the result, everyone's record, MATCH MVP and TEAM MVP, and the countdown to the next match | F4, F5 |
| 21 | The HUD panel (F3) shows from the start in Studio | F1 |
| 22 | Each map's cover builds where it should, with nothing left over from the last | O1, O5 |
| 22 | The vote shows by itself after the victory screen: three cards, a click votes and outlines the card, and the counts and the time change for everyone | O2, O3, O4 |
| 22 | The next match starts on the winner, with the map's name in the buy phase | O1, O5 |
| 23 | P reaches gun game after Skirmish and the 1v1, and everyone spawns on level 1's gun with the knife: the top bar shows the levels and the clock, and under it the gun and the next | GG1 |
| 23 | A kill puts the next gun in the killer's hands at once, with `LEVEL 2` and its name in the middle | GG2 |
| 23 | A knife kill knocks the one killed down a level, with `KNIFED` on their screen | GG4 |
| 23 | A respawn is a force field to others and can't be hurt, until it fires | GG3 |
| 23 | A match's end: the victory screen goes by level, with MATCH MVP on the winner, then the vote, and the next match starts on the map voted for, with a new ladder | GG5, GG6 |
| 23 | No buy menu, no abilities, and G does nothing | GG1 |
| 24 | M opens the menu over the course or a match: five cards, `THIS SERVER` on the one the server plays, and counts that follow who's in the server | PM1, PM4 |
| 24 | PLAY for another mode switches the server to it, and the menu closes | PM3 |
| 24 | PLAY for the mode the server plays closes the menu, and nothing else changes | PM4 |
| 24 | The vote and the victory screen hide while the menu is open | PM5 |
| 24 | On a live server only: the menu is up as you join, PLAY for Skirmish drops you into the match, and PLAY for another mode teleports you to a server playing it | PM6 |
| 25 | All three maps build at their origins with nothing overlapping them, and play at the right scale for five a side | E2, SM1, SM5, SM6 |
| 25 | A server's first match is on one of them at random, named in round 1's buy phase: everyone spawns in its spawns, behind its barriers, with the spike in front of the attackers | E1, E4, SM1 |
| 25 | After a match, the vote shows the three spike maps' cards with their plans, and the next match is on the winner: the spawns, the barriers and the spike's sites all the new map's | E12, SM2, SM3, SM4, SM5, SM6 |
| 26 | PLAY DEATHMATCH on the Play menu's sixth card, `FFA`, starts deathmatch on one of the three maps, with everyone spawning at once, nobody in sight of another | DM1 |
| 26 | The top bar's kills, clock and `FIRST TO 40`, and under it your place | DM1, DM3 |
| 26 | Heavy Armor every life, no ability bar, no glide, and G does nothing | DM1 |
| 26 | B any time you're alive: every gun free, the rest `NOT SOLD` | DM2 |
| 26 | A kill fills the killer's magazine at once, and a death leaves a green cross for 10 s that heals and reloads whoever walks over it | DM3, DM4 |
| 26 | A life comes back 1.5 s after a death, away from where it fell, facing open floor | DM4, DM5 |
| 26 | A match's end: the victory screen of everyone in their places, `VICTORY` and `2ND PLACE`, MATCH MVP on the winner, then the vote of the spike rounds' maps, and the next match on the winner | DM6, DM7 |
| 27 | PLAY TEAM DEATHMATCH on the Play menu's seventh card, `5v5`, starts it on one of the three maps, each side in its own spawn room behind the barriers, with the pre-game's countdown | TD1 |
| 27 | B opens the loadout menu; a click picks a loadout, and in the pre-game or the room it's in your hands at once, with its shield. Out of the room in a match, B does nothing. The settings menu opens over it and gives the cursor back to it | TD2, TD3, TD6 |
| 27 | The top bar's kills, clock and stage, and a new stage's loadout handed over 5 s in, or at once in the room, with a new primary drawn | TD3, TD6, TD7 |
| 27 | A respawn is a force field to others and can't be hurt until it fires or leaves the room | TD3, TD5 |
| 27 | Staying in your room 15 s, or going into the other side's, burns, with the HUD's warning, and a death there reads `SPAWN ROOM` in the kill feed | TD4, TD5 |
| 27 | A match's end: `VICTORY` and `DEFEAT`, or `DRAW` for a tie, then the vote of the spike rounds' maps, and the next pre-game on the winner | TD7, TD8 |
| 28 | The pads, rings and orbs on each map, out on the floor, none in a wall or a spawn room | TP1, TP2, TP8 |
| 28 | A spawner's gun walked over into an empty slot, or taken with F in place of the gun in its slot, without the old gun going down; the ring dims, and 30 s later another gun lies on it | TP2, TP3 |
| 28 | G with a lent gun in hand destroys it, and the loadout's gun is back; so does spending it | TP3 |
| 28 | A Recovery Orb taken mends over 6 s, and an ally who walks into its zone is mended too | TP4 |
| 28 | The Ultimate Orbs up 30 s into the match, 10 points each on the ability bar's X | TP5 |
| 28 | The abilities as a match starts, their countdowns, and their charges kept through a death | TP1, TP6, TP8 |
| 28 | A new stage's guns on every spawner, and its loadout in place of a gun lent in the last | TP7 |
| 29 | T on the course: Jett's card with her role, her kit and Drift, `PICK ANY TIME` and `PLAYING JETT`, with a cursor, and you can still move | AS1 |
| 29 | It doesn't open over the buy menu, the settings menu or the Play menu, and the settings menu opens over it and gives the cursor back to it | AS2 |
| 29 | In a match, the window: `LOCK IN WITHIN` counting down from 10 as the match starts; LOCK IN, or the time running out, locks in what's selected, and the screen goes | AS3, AS4, AS6 |
| 29 | After the window, `LOCKED IN` until the match is over, and a new window as the next one starts | AS4, AS6 |
| 29 | The buy menu's abilities, Jett's as before | AS6 |
| 29 | Nobody picks in gun game or deathmatch, on the victory screen or in the vote: T does nothing | AS5, AS7 |
| 29 | Teammates' picks: `SELECTING` while their window's open, and `LOCKED IN` after | AS3, AS4 |
| 30 | Phoenix's card in agent select, his kit on the bar with only E lit, and his kit in the buy menu, Curveball the only one for sale | CB1, CB12 |
| 30 | E draws the flare in 0.8 s, `EQUIP` on the bar; the left button throws it curving left, the right button right, and the gun is back 0.48 s later; E again or a number key puts it away | CB2, CB3, CB4, CB7 |
| 30 | The flare's flight: straight, then round a quarter turn, popping 0.6 s after the throw, about 3.5 m ahead and 4.7 m to the side on the course; stopped where it meets the floor or a wall | CB3, CB4, CB6 |
| 30 | The blind: white and clearing, longer looking at it and shorter turned away, none behind a wall; the shrinking core | CB3, CB5, CB10 |
| 30 | A second player: the throw and the pop heard, the flare seen in the air, the blind on whoever sees it, and the glow on a blinded player's face, then behind their head | CB9, CB10, CB11 |
| 31 | Hot Hands and Inner Fire lit on Phoenix's card, the bar and the buy menu, Hot Hands for sale at 200 | HH1, HH12, CB1, CB12 |
| 31 | Q draws the fireball in 0.8 s, `EQUIP` on the bar; the left button throws it and the right lobs it, and the gun is back 0.7 s later; Q again, or a number key, puts it away, and E swaps it for the flare | HH2, HH3, HH4, HH8 |
| 31 | The flight: a level throw bursting about 18 m ahead on the course, a lob about 6.4 m; one into a wall coming back off it; one thrown up dropping straight down once its 1.5 s are up | HH3, HH4, HH5, HH7 |
| 31 | The fire: spreading to 9 m across over 0.75 s, stopped by a crate but not by a kerb, out after 4 s; a dummy standing in it burns and dies, `Hot Hands` in the kill feed | HH3, HH7, HH10 |
| 31 | Inner Fire: Phoenix hurt, then standing in his own fire, heals 50 over 4 s and takes no damage | HH6, HH11 |
| 31 | A second player: the throw heard and seen, the fire burning them as an enemy, a third as fast on Phoenix's side, and the orange glow at their screen's edge | HH10, HH13 |
| 32 | Blaze lit on Phoenix's card, the bar and the buy menu, for sale at 150 | BZ1, BZ12, CB1, CB12 |
| 32 | C draws the flame in 0.8 s, `EQUIP` on the bar; the left button sends the wall and, held, bends it, and the gun is back 0.5 s after it's let go or the run's over; C again, or a number key, puts it away, and Q or E swaps it for theirs | BZ2, BZ3, BZ4, BZ7 |
| 32 | The run: 21 m down the lane in 0.75 s; bent round to the left; up onto the 0.85 m jump box and through the 1.00 m one; up the 30 degree ramp | BZ3, BZ4, BZ5, BZ6 |
| 32 | The wall: rising from your feet and spreading to the far end in half a second, 4 m tall, gone 8 s later; nothing seen through it, and the screen flame from inside it; a dummy standing in it burns and dies, `Blaze` in the kill feed | BZ3, BZ9, BZ10 |
| 32 | Inner Fire: Phoenix hurt, then standing in his own wall, heals 50 over 8 s and takes no damage | BZ3, BZ11 |
| 32 | A second player: the send heard, the run and the wall seen, the wall burning them as an enemy, a third as fast on Phoenix's side, and the orange glow at their screen's edge | BZ9, BZ10, BZ13 |
| 33 | Run it Back lit on Phoenix's card and the bar, with no `NOT YET` | RB1, CB1 |
| 33 | X with its points full: the mark's flame at your feet, the gun away for 1 s, nothing else cast in it, and X counting down from 10 on the bar | RB2 |
| 33 | Run out: the screen flame at once, held, then back at the mark facing the way you cast it, held 1.4 s more as the flame clears, your guns full and the gun in hand as you can move; X `BACK` on the bar through it | RB3, RB5 |
| 33 | The spike blast in it: no death, no kill feed, and back at the mark with full health and the shield you had | RB4 |
| 33 | A second player: the mark's flame seen, the burst as the body goes, the column at the mark, the sounds heard; shots through where the body was; a kill in the rise is a kill | RB7, RB8 |
| 34 | The minimap at the top left in the arena and the spike rounds, gone on the course; the map drawn as it's built, your spawn tinted, the F3 panel under it | MP1, MP2, MP13 |
| 34 | Rotate turning the map as you turn, the words upright, the art cut to the box; Fixed, Based on Side, Keep Player Centered, Size and Zoom from the settings menu | MP2, MP3, MP4 |
| 34 | The big map on Caps Lock held, with the places' names by the setting | MP5, MP13 |
| 34 | Your cone cut by the level, a cloud and a wall of fire, and the barriers seen through | MP2, MP7, MP9 |
| 34 | The white circle as you run, reload and use an ability, and none as you walk or fire | MP6 |
| 34 | A second player: shown while you see them, gone behind a wall, a cloud or a wall of fire, and not while you're blinded; the last-seen mark; the spike's rules; deathmatch's pulse | MP8, MP9, MP10, MP11, MP13, MP14 |
| 34 | A third: an ally's arrow and cone, held on the edge, and the X where they fall | MP12 |
| 35 | On the course, everyone sent to everyone | FW1 |
| 35 | An enemy behind cover not sent, and one stepping out drawn from their first frame, at no ping and at 100 ms each way | FW2, FW3 |
| 35 | An enemy heard running, reloading or jumping behind cover sent, and not walking; out of earshot on a spike map not sent, though their shots are heard | FW4, FW11 |
| 35 | A knife swung behind cover heard only near it | FW5 |
| 35 | Teammates always sent, and an enemy a teammate spots sent too | FW8, FW9 |
| 35 | The dead seeing what their side does, watching a teammate | FW10 |
| 35 | Enemies' labels not through walls, teammates' through them | FW4, FW8 |
| 35 | Deathmatch's pulse showing everyone as you're back | FW12 |
| 35 | `VFFogOff` sending everyone; the cost in `VFFogLines` and `VFFogMs` | FW2, FW7 |
| 35 | A character's root staying where they spawned on the server, nothing else changed | FW6 |
| 36 | Sage's card in agent select, the Healing Orb alone lit, and her kit on the bar and in the buy menu | HO1, HO12 |
| 36 | E puts the orb in hand in 0.5 s, `EQUIP` on the bar; a try with nobody to heal leaves it there; E again or a number key puts it away | HO2, HO3, HO4 |
| 36 | Alt fire with Sage hurt: the chime, the orb away, the gun back 0.7 s later, 20 health a second for 5 s up to the most, no shield, and the green edge | HO5, HO6 |
| 36 | A hit while healed pausing the heal, which still gives 100 in all | HO7 |
| 36 | An enemy not healed, nor marked | HO8 |
| 36 | A third player: the hurt ally marked under the crosshair, not behind cover or on full health; a heal on them, their glow and their green edge; `VFLastHeal`; the 45 s countdown | HO9, HO10, HO11 |
| 36 | Team Deathmatch's 22 s | HO13 |
| 37 | The Slow Orb lit on Sage's card and the bar, its two pips, and for sale at 200 in the spike rounds, two and no more | SO1, SO15 |
| 37 | Q puts the orb in hand in 0.5 s, `EQUIP` on the bar; the left button throws it, a pip goes dark and the gun is back 0.4 s later; the right button does nothing; Q again, or a number key, puts it away, and E swaps it for the Healing Orb | SO2, SO3, SO9, SO10 |
| 37 | The flight: a level throw bursting about 24 m ahead on the course; one into a wall coming back off it; one thrown high coming down | SO3, SO6, SO7 |
| 37 | The field: spreading to about 11 m across, stopped by a wall but not by a step, gone after 7 s, and on the minimap | SO3, SO6, SO12 |
| 37 | Running into it: 2.7 m/s with the Vandal at once, the frosted edge, `SLOWED`, `VFSlowed` and a crunch with each step; walking silent; a jump lower; back to 5.4 m/s out of it, and no correction going in or out | SO4, SO5, SO14 |
| 37 | A strafing dummy slowed in it, its steps crunching | SO8 |
| 37 | A second player slowed in your field, crunching where you see them, on a step too; Jett's dash half as far in it; no correction at 100 ms each way | SO11, SO12, SO13, SO14 |
| 38 | The Barrier Orb lit on Sage's card and the bar, with its pip, and for sale at 300 in the spike rounds, one and no more | BO1, BO17 |
| 38 | C puts the orb in hand in 0.8 s, `EQUIP` on the bar, with its targeter on the floor ahead; the left button raises the wall, the pip goes dark and the gun is back 0.7 s later; a number key puts it away | BO2, BO4, BO9 |
| 38 | The targeter: across the view, turned a quarter by C and back, held by alt fire as you turn, kept, red in the buy phase, and nowhere off the edge of the course | BO3, BO9, BO12, BO17 |
| 38 | The wall: rising out of the floor in 1.35 s, 10.4 m long and 2.5 m tall, solid, fortifying at 2 s with a flash and a crack, clouding over from 35 s and gone at 40 s; `VFWall` as it goes; on the minimap | BO4, BO5, BO8, BO17 |
| 38 | In the way: walking and jumping into it, shots stopped at it, a dummy behind it, a segment shot down and the gap it leaves, being lifted onto it, and a segment over the planted spike breaking | BO5, BO6, BO7, BO10, BO11, BO13 |
| 38 | A second player stopped by your wall, lifted onto it and breaking it, with no correction at 100 ms each way; and in the spike rounds, your own bullets not breaking it | BO14, BO15, BO16, BO18 |
| 39 | The Resurrection lit on Sage's card and the bar, `X7/7` on the course, and in hand 0.8 s after X | RE1, RE2 |
| 39 | A body where a dummy falls, kept down while the orb's in hand, and the mark on it only with the crosshair over it | RE3, RE4, RE5 |
| 39 | The return: the chime, the body rising 0.5 m in its shell over 2 s, the crack and the chips, the dummy back where it lay and falling to the floor, the kill feed's line, the points spent and refilled, and the gun back 1 s after | RE6 |
| 39 | Brought back with no shield: fewer shots to fell it again | RE7 |
| 39 | A wall of ice where it comes back breaking | RE8 |
| 39 | An ally in Skirmish: the discs' colours, rising with the body out of harm's way, held as they fall and in harm's way then, and every body gone with a new round | RE9, RE10 |
| 40 | Omen lit in agent select, a Controller, with Dark Cover lit and the rest NOT YET, and `E2/2` on the course | DC1 |
| 40 | In hand 0.6 s after E, the mark 15 m out, moved by held fire and alt fire within 2 to 80 m, seen through walls, and red with nowhere for it | DC2, DC3, DC4 |
| 40 | The smoke: sent with E, the gun back 0.7 s after, forming where the mark showed, growing over 1 s, standing 15 s, flickering for its last 1.5 s and gone, and dark from inside | DC5, DC6, DC7 |
| 40 | A mark behind a wall, and over a ramp too steep to stand on | DC4, DC5, DC8 |
| 40 | With other players: their spotting stopped at it, the send heard by the sender's side alone, every smoke gone with a new round, and the second charge bought at 150, never brought back by the cooldown unbought | DC9, DC10, DC11, PA8 |
| 41 | Paranoia lit on Omen's card and the bar, `Q1/1` on the course, and in hand 1.1 s after Q | PA1, PA2 |
| 41 | Sent with fire: appearing ahead, flying 25 m down the lane in 1.25 s and gone, the gun back 0.7 s after, and whom it touched in `VFLastParanoia` | PA3 |
| 41 | Through walls: the dummies behind the wallbang lane's walls touched | PA4 |
| 41 | The nearsight on your own screen: dark past 7.5 m whichever way you look, the sky too, a shell of shadow round the camera seen from inside, the tone, the muffling and the minimap covered, all clearing after 2 s | PA5, PA6 |
| 41 | With other players: the warning in its path, an enemy nearsighted and deafened, their minimap telling them of nobody, the wisp, a far flash not blinding them, and the charge bought for 250 | PA6, PA7, PA8 |
| 42 | Shrouded Step lit on Omen's card and the bar, `C2/2` on the course, and in hand 0.5 s after C, with the ring where it would take you shown through anything | SS1, SS2 |
| 42 | The step: the windup, then gone, then there 5 m down the lane, the gun back 0.7 s after, and `VFLastStep` | SS3 |
| 42 | Held through the windup: moving and jumping do nothing, and you walk on once you're there | SS4 |
| 42 | Nowhere under the crouch tunnel's roof, the ring red; onto the 1.00 m jump box; in front of a wall, never through it or over it | SS5, SS6, SS7 |
| 42 | With other players: the swirl, the puff, the shadow where you're going and your arrival, heard within 12.5 m; nothing hitting you while you're gone; the minimap's ring; and in the spike rounds, both charges bought at 100 and no step past the spawn's barrier, through it or over it | SS8, SS9, SS10 |
| 43 | From the Shadows lit on Omen's card and the bar, `X7/7` on the course, and its map up 0.5 s after X, the course's drawn from its parts, with the cursor on you | FS1, FS2 |
| 43 | The cursor held on the map, red off the floor, and fire there doing nothing | FS3 |
| 43 | The teleport: the windup, then a Shade 25 m down the lane, grey, the dark drawing back, then formed, the gun back 1 s after, and `VFLastShadow` | FS4 |
| 43 | Held through it, the view still turning | FS5 |
| 43 | X as a Shade sending you back, and doing nothing in the windup | FS6 |
| 43 | Onto the 1.00 m jump box and the crouch tunnel's roof, and beside a wall the cursor's on | FS7 |
| 43 | With other players: the swirl, the puff, the Shade dark and see-through, its arrival heard within 22.5 m; an enemy's shot sending it back unhurt; an enemy's minimap dark while it runs, and cleared as it's sent back; and the cursor red in the buy phase | FS8, FS9, FS10, FS11 |
| 44 | The Recon Bolt lit on Sova's card and the bar, the rest of his kit NOT YET there and in the buy menu, `E1/1` on the course, and the bow in hand 0.8 s after E | RC1, RC2, RC11 |
| 44 | The draw: the bars a third of a second apart, the bounces added and taken off by alt fire, E letting the draw go, and E again putting the bow away | RC2, RC3 |
| 44 | The loose: the gun back 0.7 s after; the bolt's flight, sticking where `BoltSim` has it, a tap 18.6 m down the lane, and further with more bars | RC4, RC5 |
| 44 | Bounces off the floor and the backstop | RC6 |
| 44 | The pulses: the windup, two 1.6 s apart, the shell of light, the pings, and gone 3.2 s after the first | RC4 |
| 44 | The reveals: the silhouettes through walls, `VFLastRecon`, nobody past 30 m, and nobody a wall hides, even right behind it | RC4, RC5, RC6, RC7 |
| 44 | Shot to pieces: a shot at its shaft breaking it, and no more pulses | RC8, RC10 |
| 44 | With other players: seen and heard; on the course, revealing everyone but its owner, to its owner alone; in Skirmish, revealing enemies alone to its owner's side, through walls and on the minimap; allies' shots doing nothing and an enemy's breaking it; and its charge back 50 s after it's loosed | RC9, RC10, RC12, RC13 |
| 45 | The Shock Bolt lit on Sova's card and the bar, `Q2/2` on the course, its `Burst` row in the buy menu, and the bow in hand 0.8 s after Q, drawn, given bounces and let go as the Recon Bolt's, and Q again putting it away | SB1, SB2 |
| 45 | The loose: the gun back 0.7 s after; the bolt bursting where `BoltSim` has it land, a tap 18.6 m down the lane, with its flash and its crack, and with a bounce only where it lands | SB3, SB5, SB7 |
| 45 | Its damage: 75 within 1 m, less further out and none past 5 m, through a dummy's Heavy Armor; two at a dummy's feet killing it, the kill feed naming the Shock Bolt | SB3, SB4, SB5 |
| 45 | Its owner hurt by his own burst | SB6 |
| 45 | Nobody hurt behind the wall it bursts on, even right behind it | SB8 |
| 45 | With other players: seen and heard; hurting anyone near it, an ally as much as an enemy; both charges there each round in Skirmish; and bought at 150 a charge in the spike rounds, two at most, nothing bringing a spent one back | SB9, SB10, SB11 |
| 46 | Hunter's Fury lit on Sova's card and the bar, `X8/8` on the course, and its bow in hand 0.5 s after X, with three blasts and its 6 s running from then | HF1, HF2 |
| 46 | A blast: its windup, rooted and the view slowed, then the band of light 66 m down the lane through the backstop, its crack, and the knockback | HF3, HF5 |
| 46 | Whom it catches: the four dummies on its line, 80 each through their Heavy Armor, none beside it more than 2 m off its line, and none behind; two blasts killing them, the kill feed naming Hunter's Fury; and through walls | HF3, HF4, HF7, HF8 |
| 46 | Its end: as its time's up, a blast charging going with it, and as anything else is drawn | HF2, HF4, HF6 |
| 46 | With other players: seen and heard; on the course, catching everyone but its owner, revealed to its owner alone; in Skirmish, its allies spared, its enemies revealed to its side through walls and on the minimap; and nobody caught while the barriers are up | HF9, HF10, HF11 |
| 47 | The Owl Drone lit on Sova's card and the bar, `C1/1` on the course, its rows in the buy menu, and the drone in hand 0.9 s after C, with C again putting it away | OD1, OD2 |
| 47 | Sent out: the view leaving his eye and stopping 1.8 m on, the tinted edges, the green crosshair, the bars and its hum, his body standing where he left it, and as its 7 s are up, the view back and the gun back 0.7 s later | OD3 |
| 47 | Flying it: along the ground at 5 m/s the way the view faces, through the dummies, up and down at 3 m/s, no higher than 3 m over the floor and down to it, stopped by a wall and over it; his body still | OD4, OD5, OD8 |
| 47 | Its darts: one every 5 s; a dummy struck, `[Target Hit]` for 2 s, and its pings 1.6 s and 2.8 s after, revealing it for 0.6 s each; none past 40 m or through a wall | OD6, OD7 |
| 47 | Its end: C again, its pings going on after, and as its time's up | OD3, OD9 |
| 47 | With other players: seen and heard; another player tagged, revealed to its owner alone on the course; shot down by an enemy's three hits; in Skirmish, its charge each round, hidden from enemies until they could see it or it's within 15 m, his side's shots doing nothing, and its darts revealing enemies to his side through walls and on the minimap; and bought for 400 in the spike rounds | OD10, OD11, OD12, OD13, OD14, OD15, OD16 |
| 48 | Before anyone locks in, teammates both selecting one agent; once one locks it in, `TAKEN` on its card for the other, dimmed and doing nothing when clicked, the line under the button with the cursor on it, and their selection back on the agent they play | OE1, OE2 |
| 48 | The other side locking in the same agent | OE3 |
| 48 | The time running out on what a selection moved to | OE4 |
| 48 | In the spike rounds, teammates' windows closing at once on one agent: the first player on the server keeps it, and the other goes back to the agent they play | OE5 |
| 48 | System 29's time running out, with player 1 on Jett: player 3 now ends on Phoenix | AS4 |
| 49 | Each map's two orbs up as round 1 starts, their look, and the gold dots on the minimap | UO1, UO2, UO9 |
| 49 | The prompt at one, and the taking: the bar, rooted with the gun away, the whoosh, 2 s, the chime, its point on the ability bar and in `VFKit`, and the orb gone for both players | UO2, UO3, UO4, UO5 |
| 49 | Letting go partway: nothing kept, the gun back, and the next try from empty | UO3, UO4 |
| 49 | Another player hearing the whoosh, and seeing no gun in the taker's hands | UO3, UO4 |
| 49 | Both orbs back up the next round | UO6 |
| 49 | F defusing the planted spike | UO7 |
| 49 | A full ultimate taking one: the orb gone, the points still full | UO8 |
| 49 | None after the spike rounds | UO9 |
| 50 | Swiftplay's 2 points at the start, kept through an agent picked in the first buy phase | UP1 |
| 50 | A death's point paid as the next round starts, and a kill's at once | UP2 |
| 50 | No point for a death to the spike's blast, to one's own Shock Bolt or to a teammate's, nor for the teammate | UP3, UP4, UP9 |
| 50 | The half wiping a full ultimate, and a death in its last round earning nothing across it | UP5 |
| 50 | A sudden death's start 3 short of full, whatever was had | UP6, UP8 |
| 50 | The standard format: none at the start, none after the half, and 3 short in its sudden death | UP7, UP8 |
| 51 | Each player's agent on the top bar, yours and theirs, by its first two letters | GA1 |
| 51 | Your side's health under its tiles, emptied by damage and death; none under the other side's | GA1, GA4 |
| 51 | A gold diamond under anyone's tile while their ultimate's ready, an enemy's too | GA3, GA4 |
| 51 | The scoreboard's agents and ULT, both sides', live, with `READY` in gold once full | GA2, GA3, GA4 |
| 51 | The victory screen keeping the agents, without the ULT | GA5 |
| 51 | Gun game: names' letters on the top bar, and no agents or ULT on the scoreboard | GA6 |
| 52 | Z tapped at the floor, the sky, an enemy, a gun and the spike: a marker for each but the sky's, with its word and how far away it is, and a beep | PI1, PI2, PI3, PI4 |
| 52 | Z held: the wheel, its pick, and a call pinged where the crosshair is; right click putting it away | PI5 |
| 52 | The limit: four in quick succession, then the wheel greyed, and one more back after 1.5 s | PI6 |
| 52 | A marker faded under the crosshair, and gone after 4 s | PI1 |
| 52 | A cloud stopping a ping at its edge, and an enemy behind one not pinged | PI7 |
| 52 | Pings seen by the pinger's side alone, in the world and on both maps | PI8, PI10, PI11 |
| 52 | The big map's cursor and a left click: a ping on the maps and not in the world, with its ding | PI9, PI10 |
| 52 | While dead: map pings, and no Z | PI12 |
| 53 | On the course, N with nothing done: an empty report; then Dummy 1's body shots and a head shot, with the figure lit and KILLED | CR1, CR2, CR3 |
| 53 | Mouse 3: the details, the Vandal with 150 and 4 hits | CR4, CR7 |
| 53 | Shot dead by another player: the report up at once, who killed you, their row first with KILLED YOU, and what each of you dealt; N hiding and showing it; gone as you come back | CR6, CR7 |
| 53 | In Skirmish, the round's report back through the next buy phase, N still hiding and showing it, and gone as the round goes live | CR9, CR10 |
| 53 | Each player's report holding only whom they fought | CR8, CR9 |
| 53 | I for the enemy outline colour, and N no longer changing it | CR5 |
| 54 | A hit from one side: a red arc on that side of the ring, whole for a second and fading over the next | DI3, DI5 |
| 54 | The arc going on pointing at where the hit came from as you turn and move | DI4, DI7 |
| 54 | Hits from much the same way renewing one arc; none for a hit that kills, and none left as you die | DI6 |
| 54 | Only the one hit seeing it | DI5 |
| 54 | A hit on the Owl Drone you fly: an arc on your ring, from the drone | DI7 |
| 54 | A fire or a wall of fire near you: the yellow chevron on its side, pulsing; once it reaches you, the red diamond, and no arc for its burn | DI8, DI9, DI10 |
| 54 | Low health and a low magazine reading red | DI2, DI6, DI9 |
| 55 | A kill of a dummy on the course: the banner low in the middle with 1 in it and a mark lit, the dummy's name under it, and the kill sound; whole for 1.5 s, then fading | KB2 |
| 55 | More kills in a life: each banner's number one more, the kill sound higher each time up to the fifth, and gold from the fifth | KB3, KB4 |
| 55 | A headshot kill: the little red X; none for a body shot | KB2, KB3 |
| 55 | A new life on the course: the count from 1 again | KB6 |
| 55 | An ability's kill: a banner and the kill sound, as a gun's | KB5 |
| 55 | In Skirmish: the count over the round, and from 1 again in the next | KB7 |
| 55 | Only the killer seeing it | KB6, KB7 |
| 56 | One against one in Skirmish: ROUND WON and ROUND LOST, with no callout | CO1 |
| 56 | In the spike rounds, a Vandal against the Classic, the Classic's side winning on time: THRIFTY for the winners and ROUND LOST for the losers; the same loadouts on each side: ROUND WON | CO2, CO3 |
| 56 | One against two in Skirmish: the one killing both, ACE; the two winning with nobody dead, FLAWLESS on all three screens; one against one at the end, nothing | CO4, CO5, CO6 |
| 56 | The one alone against two winning after one of them leaves: CLUTCH | CO7 |
| 56 | The callout gone as the next buy phase starts | CO1 |
| 57 | In the spike rounds, the team panel left of the buy menu: a card for each of your side, you first, with their credits and gun, and nobody from the other side | TB1 |
| 57 | A teammate asking for a gun: the ping's blip, and their card showing the gun with BUY; their own tile for it reading REQUESTED | TB2 |
| 57 | BUY: the buyer pays its price, and the gun's in the asker's hands, bought by the buyer | TB3 |
| 57 | Selling it back: the buyer's credits back | TB4 |
| 57 | The other side can't buy it | TB5 |
| 57 | Asking again takes it back; a plan on the card, gone when picked again | TB6 |
| 57 | Buying another gun over one bought for you: the buyer's credits back; a request for more than the buyer has: SHORT, and nothing bought | TB7 |
| 58 | Wharf is built off the course's left, past Foundry, and the spike rounds start on it with `VFMatchMap` set to `wharf` | WF1 |
| 58 | Its look: the zones' floors, the walls, the roofs and their lights, the lintels, the buildings, the tower, the crane and the signs | WF2 |
| 58 | The kit's placeholders: each piece's look, over its box, and nothing of it in the way of a shot or a step | WF2, WF3 |
| 58 | The cover: low pieces shot over standing, high and tall ones hiding a standing player | WF3 |
| 58 | A model in ServerStorage's VFMapKit folder fitted over every piece of its name | WF4 |
| 58 | Each side's way to each site, the barriers, and no sight of one spawn from the other | WF5 |
| 58 | How it feels at five a side: too big, about right or too small | WF5 |
| 59 | The wedges: each stair and ramp rising toward its head, walked up and down at a run without a stop or a hop | WH1, WH3 |
| 59 | The look of the heights: heaven, its deck and railing and hell under it, the window room and its frame, B's platform, hookah's window, the steps over the stairs | WH2 |
| 59 | Heaven's railing holding, its gap to drop through, and no climbing back onto the deck or the platform | WH3 |
| 59 | Jumping through hookah's window | WH3 |
| 59 | From the window and heaven, standing shows a head over the frame or the railing, and crouching hides it | WH4 |
| 59 | Each side's run to each site, and how the map feels at five a side | WF5, WH5 |
| 60 | Bots filling each mode, the match starting with one player, and a player joining taking a bot's place | BT1, BT2 |
| 60 | The bots on screen: names, outlines, the scoreboard, the top bar, the minimap and the kill feed | BT3, BT5 |
| 60 | What they buy in the spike rounds, and their guns dropping where they die | BT4, BT5 |
| 60 | How they fight in the place's real geometry: noticing, stopping to shoot, bursts, and whether Normal is beatable | BT7 |
| 60 | Going round the spike maps together and following a player, without walking into walls, on Roblox's own collisions | BT5, BT6 |
| 60 | What nine bots cost the server | BT8 |
| 61 | Bots picking the spike up, carrying it and planting it in the place's real geometry, on Roblox's own collisions, and the plant going down in the plant area | BS1, BS2 |
| 61 | A bot's plant and defuse going through the round as a player's do: what's shown and heard, and the round won | BS3, BS4 |
| 61 | Players first: a spike dropped by a player left to them for 5 s, and a player carrying it or defusing it | BS1, BS2, BS4 |
| 61 | Attackers watching the spike and leaving the blast in time; defenders retaking together and defusing, or leaving the blast when it's too late | BS1, BS2, BS4 |
| 61 | A bot carrying the spike on the minimap for its side, and named in the debug HUD | BS3 |
| 61 | What the bots cost the server around a plant | BS5 |
| 62 | The line under a watched bot's name, F, and the new life in its body: where it stood, looking the same way, its gun in hand with its rounds, its health and shield, and the HUD showing them | BC1 |
| 62 | The bot taken out of play with no death: gone, greyed on the top bar, its record as it was, and back the next round | BC1, BC3 |
| 62 | The spike a bot carried, the player's and planted by them; a takeover with the spike planted | BC2 |
| 62 | The record afterwards: kills in the body the player's, the body's guns kept if they live, and the bot on the starting kit | BC3 |
| 62 | Not in Competitive, nor once a round's decided, nor in the modes that respawn; in Swiftplay and Skirmish | BC1, BC4 |
| 62 | A takeover asked for as the bot's gone: no life, and watching goes on | BC5 |
| 63 | The `Transform` sums on the real rig: each bone where the pose puts it, the skinned mesh following, and the body scaled to 1.75 m | AB1, AB2 |
| 63 | The head in the head box, standing, crouched, and aiming up and down | AB1 |
| 63 | The steps, the stance, turning on the spot, a jump, a landing and a glide, as they look | AB2 |
| 63 | The holds, a switch, a shot's kick, a reload, an ability's item, the plant and the defuse, as they look | AB3, AB4 |
| 63 | A hit, a Shade and spawn protection on the body; the outline round it, not round the unseen blocks; the label over the head | AB1, AB5 |
| 63 | Bots drawn as bodies, planting and defusing too, the one watched not drawn, and what nine bodies cost a client's frame, in view and looking away | AB6 |
| 63 | Blocks again without a body, and the body again once it's back | AB7 |
| 65 | Bots picking in the agent select window, one of each agent on a side, never what a player selected | BK1 |
| 65 | Bots' agents and ultimates on the top bar and the scoreboard | BK1, BK2 |
| 65 | A bot's kit: its signature's free charge, and points for kills and deaths | BK2 |
| 65 | A flash blinding a bot and Paranoia nearsighting it in the place's real geometry, and what it sees meanwhile | BK3 |
| 65 | A Healing Orb healing an allied bot; a Recon Bolt and Hunter's Fury leaving allied bots be | BK4 |
| 66 | Bots buying their charges in a buy phase, after their guns and once their agents are locked in, and saving for a full buy | BU1 |
| 66 | Bots casting in a round: the moments, and how often; nothing carried over when the spike rounds start over | BU2, BU3, BU4 |
| 66 | Their throws in the place's real geometry, on Roblox's collisions: smokes on the spots, flashes round the corner, mollies, slows and walls on the way in, and none on their own side | BU2, BU3, BU6 |
| 66 | A heal; Hunter's Fury, a molly or a Shock Bolt on a defuse | BU4, BU5 |
| 66 | What the casts cost the server | BU6 |
| 67 | Placements, what a match is worth, a promotion and a demotion or a shield, on the victory screen | RK1, RK2, RK3 |
| 67 | Each mode's record and Competitive's rank on the Play menu | RK4 |
| 67 | Leaving Competitive under way counted as a loss | RK5 |
| 67 | The data store: a career kept from one session to the next | RK6 |
| 68 | Moving, walking, looking, the ramp and inverting | PD1, PD2 |
| 68 | Focus, a rifle's sights and a sniper's two zooms held as LT is | PD3, PD4 |
| 68 | The abilities, the ultimate's chord, Y's swap and the knife, crouching, reloading, a gun picked up and the spike | PD5, PD6 |
| 68 | Pings, the buy menu and B shutting it, Select's big map, scores and menus, and taking over a bot | PD7 |
| 68 | Roblox's gamepad cursor, the prompts and the feel with a real controller; no warning about Roblox's default controls | PD1, PD7, PD8 |
| 69 | A place held: the bot filling it on the player's side, the spike they carried dropped, and the line printed | RJ1 |
| 69 | Back by RECONNECT or PLAY, with their record, credits and agent, at once in a buy phase or down until the next round, and the bot on their side giving way | RJ2, RJ3 |
| 69 | A match's end with a player away, and with one back in time: the career lines | RJ4, RJ5 |
| 69 | Closing the game during a match on a live server and coming back, by RECONNECT | RJ6 |
| 70 | Standing still alive in a round: the warning at the time set, counting down, and gone at a key, a look or a buy | AF1, AF2 |
| 70 | Dead, or between rounds: the time stopping and going on | AF3 |
| 70 | Taken out: the Output's line, the place held and the bot on their side, the menu opening with RECONNECT and the line saying why, and back by RECONNECT | AF4 |
| 70 | No warning with nobody else playing, without `VFTestAfk` | AF5 |
| 71 | The buttons shown as a touch screen's in use, where the layout says, and none with the mouse | TC1 |
| 71 | The stick moving and walking, the look drag turning, and FIRE's touch turning too | TC2, TC3 |
| 71 | Each button doing what its key does, CROUCH on and off, SWAP tapped and held, and the column's menus | TC4, TC5, TC7 |
| 71 | With a menu up, only CLOSE, which shuts it | TC5 |
| 71 | Dead: FIRE and AIM switching, and USE taking over the bot watched | TC6 |
| 71 | On a phone: the feel, the sizes, and Roblox's own touch controls gone | TC8 |
| 72 | PLAY for Basic Training: the course, the kit, the panel and the marker | TR1 |
| 72 | Each step moving on once it's done, and not before; the notes | TR2, TR3, TR4, TR5, TR6, TR7 |
| 72 | The spike gone off before the defuse, back to planting | TR8 |
| 72 | The buttons named for a gamepad and a touch screen | TR9 |
| 72 | Leaving it for another mode, with nothing of it left | TR10 |
| 72 | On a live server: a new server for each player who picks it | TR11 |
| 72 | The rifle step's ring over both 30 m targets, wherever the strafing one has got to | TR5 |
| 73 | Her card, the bar and the kit (Leer since system 74, Empress since system 75) | RY1 |
| 73 | An orb for her kill where it fell, drawn only for her, brighter in reach, gone after 3 s | RY2, RY3 |
| 73 | Devour taking the orb in reach, 50 over 2 s up to 150, and the overheal gone 10 s after | RY4 |
| 73 | Dismiss taking it: 12 m/s, no firing, the screen darkened, the gun back as it ends | RY5 |
| 73 | Nothing hurting her through it, and others seeing her dark and see-through | RY6 |
| 73 | Basic Training with her kit: Leer (system 74) and Empress (system 75) cast, the hint on Soul Orbs | RY7 |
| 73 | Bots playing her: orbs for their side's kills on enemies they hurt, Devour when hurt, no Dismiss | RY8 |
| 73 | Her reach, the heal, the speed and the darkening, as they feel | RY9 |
| 74 | Leer on her card, and the eye in hand | LR1, LR2 |
| 74 | The eye flying 10 m through walls, and stopping on the floor | LR3, LR4 |
| 74 | Someone looking at it nearsighted until they look away, and not deafened | LR6 |
| 74 | Her side never nearsighted, and unable to break it | LR8 |
| 74 | Bullets breaking it at 100 | LR5, LR7 |
| 74 | Bots casting it | LR9 |
| 74 | The fixes: Dismiss's edge, her gun in Dismiss, the draw, the prompt, and the training ring | RY2, RY5, RY6, TR3, TR4, TR5 |
| 74 | The cone, the linger and the eye's health, as they feel | LR10 |
| 75 | Empress on her card, and its points full on the course | EM1 |
| 75 | The cast: the activation with the gun away, then the frenzy | EM3 |
| 75 | Rounds 15% faster, and draws and reloads 25% faster | EM2, EM4 |
| 75 | An orb in the frenzy healing her at once, the orb kept, and the overheal staying | EM5, EM9 |
| 75 | Dismiss in it free, and unseen by her enemies, but seen by her side | EM6, EM7, EM9 |
| 75 | Her death and a new round ending it | EM8, EM9 |
| 75 | The glow, the edges, the HUD and the sound | EM3, EM7 |
| 75 | Bots casting it | EM10 |
| 75 | The fixes: the eye in hand's pupil, and the bars keeping up with the quicker hands | EM3, EM4 |
| 75 | The activation, the glow and an unseen Dismiss, as they feel | EM11 |
