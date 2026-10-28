# Studio test session

The offline tests and the type checks cover the shared simulation; this session covers what only
Studio can show. It goes through every "Known gaps to check in Studio" item in the fifty-three
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
   three, section 55 three, section 56 one and then three, and section 57 one and then two.

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
| P | The next of: the arena (Skirmish), gun game, the spike rounds, the spike rounds in Swiftplay's format, and off |
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
- **T2 Blocks.** Each window draws the other player like a dummy but in red: a yellow head on a
  red body and dark red legs, with their name and health over the head. Their Roblox avatar
  doesn't show at all, so there's no hair or hat poking out of the blocks and no Roblox name tag
  inside them. Press F10: the green outlines sit exactly on the blocks.
- **T3 Hitting a player.** Press F10 in window 1. Player 2 strafes left and right in the target
  lane, 10 to 20 m out, and player 1 shoots them. Shots register, with damage numbers and hit
  confirms, the block that was hit flashes white, and the overlay's boxes turn white on them. No impact marks appear on their body, which
  would mean characters block shots.
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
- **A4 Off and on.** Press P four times, through gun game and the spike rounds (sections 27 and
  17): the Output window shows `[VF] Arena on: gun game, Skirmish A` (or `B` or `C`), then `[VF]
  Arena on: the spike rounds, Standard, on Outpost` (or `Quarry` or `Foundry`), then the same with
  `Swiftplay`, then `[VF] Arena off`, and you're back at the course's spawn, the score bar and
  banner are gone, and the dummies still have red outlines. Press P again and you're back in the
  NORTH room, facing the hall. Then hold W and press P four times more, so each new life starts
  while you're running. Each time you start at a spawn and run on from there with no snap back,
  and the HUD's `max` correction stays at `0.0 mm`. The `corrections` count can go up by one at
  each spawn, as at any spawn.

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
- **A11 Off again.** Press P four times in window 1, through gun game and the spike rounds.
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
  hears. Step off it onto the floor: the heard thud again. Spawning is silent: press P five times
  (the arena, gun game, the spike rounds twice, then off) and you appear each time without a sound.
  Nothing else plays with any of these: Roblox's own character sounds are off.
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
  (0, 0, 4) and `VFSpikeCarrier` 0. With the arena on (P) it reads `none here`. Press P four more
  times, through gun game and the spike rounds to off, and the spike is back on its tile.
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

- **E1 On.** Press P three times. The Output window shows `[VF] Arena on: Skirmish A` (or `B` or
  `C`), then gun game's line, then `[VF] Arena on: the spike rounds, Standard, on Outpost` (or
  `Quarry` or `Foundry`). You respawn in a room with a red floor marked ATTACKERS, facing its door
  into mid, with the spike on the floor about 4 m in front of you: `VFSpikeLayout` is the map's key
  (`outpost`, `quarry` or `foundry`) and `VFSpikePosition` (-150, 0, 29), (-300, 0, 30) or (-450, 0,
  34). The top bar shows `0` and `0` with `SPIKE ROUNDS` and `STANDARD` between them, and the banner
  reads `WAITING FOR AN OPPONENT`, with `Standard, first to 13. Anyone who joins plays for the other
  side   B buy menu` under it. Teams holds Orange and Teal, and you're on Orange. You have the
  Classic (2) and the knife (3), and no shield.
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

- **E4 Round 1.** Press P three times in window 1. Player 1 spawns in ATTACKERS and player 2 in
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
  FREE`. Press P three times for the spike rounds. B now reads `800 CREDITS`. Every gun and shield
  that costs more than 800 is dimmed with its price in red: everything from the Bucky (850) up, and
  Heavy Armor (1000). The sidearms, Light Armor (400) and the Regen Shield (650) aren't.
- **Q2 Buying and refunds.** Buy Light Armor: `400 CREDITS`. Now the Regen Shield isn't dimmed,
  since the Light Armor goes back for it: hover it, and the panel reads `250, with what you bought
  for its slot sold back`. Heavy Armor is dimmed. Buy the Regen Shield: `150 CREDITS`. Right-click
  it: `800 CREDITS` and no shield. Buy a Sheriff: `0 CREDITS` and the Sheriff in hand. Every gun for
  the primary slot and every shield is dimmed, and the other sidearms aren't, since the Sheriff goes
  back for any of them. Right-click the Sheriff: `800 CREDITS` and the Classic back.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **Q3 Round 1.** Press P three times in window 1. Both players' buy phase line starts with the
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
- **L11 The dead drop theirs.** Press P three times in window 1 for the spike rounds. In round 1's
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
- **J6 The tiles in the spike rounds.** Press P twice more, through gun game to the spike rounds:
  the tiles stay. Skip round 1's buy phase (`VFMatchSkip`). Player 1 kills player 2 with the
  Classic, and player 2 doesn't shoot back. Player 2's tile dims on both screens. Both kill feeds
  read `Player1   Classic   Player2`, outlined in gold on both, as both are in it: in window 1
  player 1's name is blue, and in window 2 it's red.
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

With three players (optional): start a Local Server with 3 players, and press P three times in
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
- **U12 The spike rounds' kit.** Press P twice more in window 1 (gun game, then the spike rounds).
  In round 1's buy phase both `VFKit`s read `C0/2 Q0/1 E1/1 X0/8`: Cloudburst and Updraft have to be
  bought, and Tailwind's charge is free. In window 1, B opens the menu: under the shields, an
  `Abilities` group has Cloudburst (`C`, 200) and Updraft (`Q`, 150). Pointing at Updraft shows
  `Ability, on Q` and rows for `Charges` (`up to 1`), `A charge` (`150 credits`) and `Lift` (`4 m,
  in 0.6 s`). Click it: the credits go from 800 to 650, its pip lights and it shows `FULL`, the
  bar's Q pip lights, and `VFKit` reads `Q1/1`. Right-click it: back to 800 and `Q0/1`. Click it
  again to keep it. (Y12 buys Cloudburst.) **Send:** a screenshot of the menu with Updraft bought.
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
- **Y12 The spike rounds.** Press P twice more in window 1 (gun game, then the spike rounds). In
  round 1's buy phase B opens the menu. Pointing at Cloudburst shows `Ability, on C` and rows for
  `Charges` (`up to 2`), `A charge` (`200 credits`), `Cloud` (`6.7 m across, for 2.5 s`) and
  `Flight` (`30 m/s, at most 2 s`). Click it twice: the credits go from 800 to 600 to 400, both its
  pips light and it shows `FULL`, and `VFKit` reads `C2/2`. Right-click it once: 600, and `C1/2`.

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

Start a Local Server with 2 players, as in section 9, and press P twice in window 1 (Skirmish,
then gun game).

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

Start a Local Server with 2 players, as in section 9, and press P four times in window 1 (Skirmish,
gun game, the spike rounds, then the spike rounds in Swiftplay's format).

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
- **AS5 Nobody picks in gun game.** Press P in window 1 (gun game). T does nothing, and
  `VFAgentPick` is unset. Space held in the air still glides, as Jett's Drift does. Run
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
- **CB12 The spike rounds.** Press P twice more in window 1 (gun game, then the spike rounds), and
  as round 1's buy phase starts, pick PHOENIX and LOCK IN in window 1. B: under the shields, Blaze
  (`C`, 150) and Hot Hands (`Q`, 200), lit (sections 36 and 35 have more of them), and Curveball
  (`E`, 250) with one of its two pips lit, the round's free charge, and every tile inside the menu.
  Pointing at Curveball shows `Ability, on E`, its line, and rows for `Charges` (`up to 2`),
  `A charge` (`250 credits`), `Pop` (`0.6 s after the throw`), `Blind`
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
- **HH12 The spike rounds.** Press P three times in window 1 (Skirmish, gun game, then the spike
  rounds), and as round 1's buy phase starts, pick PHOENIX and LOCK IN in window 1. B: between Blaze
  (`C`, 150) and Curveball, Hot Hands (`Q`, 200) is lit, with its one pip dark, as no charge of it
  comes free. Pointing at it shows `Ability, on Q`, its line, and rows for `Charges` (`up to 1`),
  `A charge` (`200 credits`), `Fire` (`9 m across, for 4 s`), `Burn` (`60 a second`) and `Heals you`
  (`50 over 4 s, Inner Fire`). Click it: the credits go from 800 to 600, its pip lights and it shows
  `FULL`, and `VFKit` reads `Q1/1`; right-click it: back to 800 and `Q0/1`. **Send:** a screenshot
  of the menu.
- **HH13 Allies.** This one needs three players, and can be skipped. Stop the game, start a Local
  Server with 3 players, and press P three times in window 1 for the spike rounds. In round 1's buy
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
- **BZ12 The spike rounds.** Press P three times in window 1 (Skirmish, gun game, then the spike
  rounds), and as round 1's buy phase starts, pick PHOENIX and LOCK IN in window 1. B: Blaze (`C`,
  150) is lit, with its one pip dark, as no charge of it comes free. Pointing at it shows
  `Ability, on C`, its line, and rows for `Charges` (`up to 1`), `A charge` (`150 credits`), `Wall`
  (`up to 21 m, for 8 s`), `Burn` (`30 a second`) and `Heals you` (`50 over 8 s, Inner Fire`). Click
  it: the credits go from 800 to 650, its pip lights and it shows `FULL`, and `VFKit` reads `C1/1`;
  right-click it: back to 800 and `C0/1`. **Send:** a screenshot of the menu.
- **BZ13 Allies.** This one needs three players, and can be skipped. Stop the game, start a Local
  Server with 3 players, and press P three times in window 1 for the spike rounds. In round 1's buy
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
- **MP13 The spike.** Press P twice in window 1 (gun game, then the spike rounds). In window 1,
  attacking, the map's drawn with its two sites lettered A and B in their amber plant areas, and the
  spike's orange diamond in front of you (`Spike` true); as you turn, the letters stay upright.
  Window 2, defending, has no diamond (`Spike` false). Player 1 picks up the spike: in windows 1 and
  3 a small orange mark sits on player 1's arrow, and the diamond's gone; window 2 shows nothing of
  it. Player 1 drops it (G) where player 2 can't see it: window 2's `Spike` stays false. Player 2
  looks at it: the diamond shows in window 2 (`Spike` true), and goes as they look away. Player 1
  plants it at A: everyone's minimap has the diamond on A. Hold Caps Lock in window 2: the big map,
  the defenders' spawn at the bottom, with the places' names on it, as `A Lobby`. Set Region names
  to IN BUY PHASE: the names show on the big map only through the next buy phase; NEVER: none;
  ALWAYS again.
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
- **FW11 Out of earshot.** Press P twice in window 1 (gun game, then the spike rounds). Once round 1
  starts, player 2 runs about in their spawn, and player 1 stays in theirs: no `Player2` in
  window 1's `VFPlayers`, and no steps heard. Player 2 fires a few rounds into the floor: window 1
  hears them, and `Player2` stays out.
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
- **HO12 The spike rounds.** Press P twice in window 1 (gun game, then the spike rounds), and as
  round 1's buy phase starts, pick SAGE and LOCK IN in window 1. E's pip is lit, its charge free,
  and `VFKit` reads `C0/1 Q0/2 E1/1 X0/7`. B: under the shields, Barrier Orb (`C`, 300) and Slow Orb
  (`Q`, 200) are both for sale (sections 42 and 41).
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

Then the spike rounds: press P three times in window 1 (Skirmish, gun game, then the spike rounds),
and as round 1's buy phase starts, pick SAGE and LOCK IN in window 1, and LOCK IN in window 2.

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

Then the spike rounds: press P three times in window 1 (Skirmish, gun game, then the spike rounds),
and as round 1's buy phase starts, pick SAGE and LOCK IN in window 1, and LOCK IN in window 2.

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

Then the spike rounds: press P twice more in window 1 (gun game, then the spike rounds), and as
round 1's buy phase starts, pick OMEN and LOCK IN in window 1, and LOCK IN in windows 2 and 3.

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

Then the spike rounds: press P twice more in window 1 (gun game, then the spike rounds), and as
round 1's buy phase starts, pick OMEN and LOCK IN in window 1, and LOCK IN in windows 2 and 3.

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

Then the spike rounds: press P three times in window 1, and as round 1's buy phase starts, pick OMEN
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

Then the spike rounds: press P twice more in window 1 (gun game, then the spike rounds), and as
round 1's buy phase starts, pick SOVA and LOCK IN in window 1, and LOCK IN in windows 2 and 3.

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

Then the spike rounds: press P twice more in window 1 (gun game, then the spike rounds), and as
round 1's buy phase starts, pick SOVA and LOCK IN in window 1, and LOCK IN in windows 2 and 3.

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

Then the spike rounds: press P twice more in window 1 (gun game, then the spike rounds).

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

Start a Local Server with 2 players, as in section 9, and press P three times in window 1 (the spike
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

Start a Local Server with 2 players, as in section 9, and press P four times in window 1 (Skirmish,
gun game, the spike rounds, then the spike rounds in Swiftplay's format). Player 1 attacks the first
half, with the spike in front of them, and player 2 defends.

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
- **UP7 The standard format.** Press P in window 1 for off, then three more times (Skirmish, gun
  game, the spike rounds), and let round 1's agent select run out in both windows: player 1's
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
press P three times in window 1 (the spike rounds). Players 1 and 3 share a side, as in section 52,
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

Start a Local Server with 3 players, as in section 9, and press P three times in window 1 (Skirmish,
gun game, then the spike rounds). Players 1 and 3 share a side, as in section 52, and attack first,
and player 2 defends. As round 1's buy phase starts, agent select comes up by itself: click SOVA and
LOCK IN in window 1, and SAGE and LOCK IN in window 2 (or set `VFTestAgent` to the agent's id and
then to `lock`), and let window 3's 10 s run out, on Jett.

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

- **GA6 Gun game.** Press P four times in window 1 (the spike rounds in Swiftplay's format, off,
  Skirmish, then gun game). Every tile beside the score reads `PL`, the first two letters of the
  players' names, and none has a diamond, though your side's still have their health bars: `Yours`
  lists a `PL 100` for each player on your side, and `Theirs` a `PL` for each on the other. Set
  `VFTestBoard` to true: no row has a box before its name, there's no `ULT` column, and
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
| 23 | P reaches gun game after Skirmish, and everyone spawns on level 1's gun with the knife: the top bar shows the levels and the clock, and under it the gun and the next | GG1 |
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
