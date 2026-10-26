# Studio test session

The offline tests and the type checks cover the shared simulation; this session covers what only
Studio can show. It goes through every "Known gaps to check in Studio" item in the thirty-four
research docs, in an order where each step only relies on things earlier steps showed working.

It takes about six hours. Doing it in parts is fine; keep the order.

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
   then two, then three for their last check, section 37 one and then two, and section 38 one,
   then two, then three.

| Key | What it does |
| --- | --- |
| F2 | Labs, one press each: Weapon Lab, Spray Lab, Hit Reg Lab, Sound Lab, off |
| F3 | HUD panel (on at the start in Studio, off on a live server) |
| F4 | Counter-Strafe Lab |
| F6 | Record movement to a CSV in the Output window |
| G | Drops the gun or the spike in hand (not in gun game or either deathmatch, but for a Team Deathmatch spawner's gun, which it destroys); with the knife in hand and the HUD on, the ghost box where the server has you |
| F | Picks up the gun on the ground you're looking at, swapping it for yours |
| Z | Zero the mouse counter (while the Counter-Strafe Lab is open) |
| [ / ] | Footstep radius down and up 2 m, this client only (while the Sound Lab is open) |
| Y | Practice dummies' footsteps on and off (while the Sound Lab is open; off at the start) |
| H | The Sound Lab's rings on the floor on and off |
| F10 | Hitbox and wall overlay |
| V | The look (lighting, vignette, outlines) off and on again, to compare with the place's own |
| N | The next enemy outline colour |
| P | The next of: the arena (Skirmish), gun game, the spike rounds, the spike rounds in Swiftplay's format, and off |
| Tab | Held: the scoreboard, in the arena and the spike rounds (at a match's end it shows by itself as the victory screen) |
| Left / right click | While you're down in the arena or the spike rounds: watch the next or the last of your living teammates |
| Click a map | During the vote for the next map, after a match in the arena or the spike rounds: votes for it, or moves your vote to it |
| C / Q / E | Cloudburst (held, it curves the throw), Updraft, and Tailwind: E readies the gust and E again dashes. As Phoenix, E readies Curveball's flare: the left button throws it curving left, the right curving right, and E again puts it away; Q readies Hot Hands' fireball: the left button throws it, the right lobs it, and Q again puts it away; and C readies Blaze's flame: the left button sends its wall, held it bends the wall towards the crosshair, and C again puts it away |
| X | Blade Storm, once its points are full: five knives, the left button throwing one and the right all that are left; with a gun drawn, X draws them again. As Phoenix, Run it Back: it marks where you stand, and dying, or its 10 s running out, brings you back there |
| Space | Jump; held in the air, Jett's glide (Drift) slows the fall until you land or let go |
| Backspace | Clear impact marks, the shot log, the lab counters, the spray plot, and the Counter-Strafe Lab's stops and the Sound Lab's log while they're open |
| 1 / 2 / 3 | Vandal / Classic / knife (the starting loadout); with the knife, the left button slashes and the right stabs |
| 4 | The spike, while you carry it; held, it plants in a site or defuses the planted spike |
| B | The buy menu: every gun and shield (on the course at any time; in the arena during the buy phase or while waiting; never in gun game; in deathmatch any time, guns alone; in Team Deathmatch the loadout menu instead, before the match or in your spawn room) |
| O | The settings menu: your sensitivity, crosshair and the minimap's settings |
| Caps Lock | Held: the big map, in a match (the minimap at the top left is only in a match) |
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
(C kept set after a throw curves it).
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

- **V1 On and off.** The `look` line reads `look    on (V)   enemy Red (Default) (N)`. Press V: it
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
- **V4 Colours.** N turns the outlines purple, then a deep yellow, then a paler yellow, then red
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
  right, and under them `Nothing's at stake here: an agent picked is yours at once, as often as
  you like.` There are two cards, JETT and PHOENIX, each over DUELIST; Jett's is outlined in
  gold with `YOURS` over the name. Under them is Jett's kit, headed `JETT   DUELIST`:
  C CLOUDBURST, Q UPDRAFT, E TAILWIND and
  X BLADE STORM, each with its line, and last `DRIFT   PASSIVE` with
  `Hold jump while you fall to glide.` On the right, `YOUR TEAM` reads
  `Nobody else on your side`. The button reads `PLAYING JETT`, dimmed, and `T to close` is at the
  bottom right. The mouse moves a cursor, a click fires nothing, and WASD still moves you. Your
  player's `VFAgent` reads `jett` and `VFAgentPick` `free`. T closes it, and the view turns with
  the mouse again. **Send:** a screenshot of the screen.
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
  10 s after the buy phase started, their row reads `JETT` and `LOCKED IN` in gold, and their
  `VFAgentPick` reads `locked`. **Send:** a screenshot of window 1's screen.
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
AS4 player 3's row read LOCKED IN ___ s after the buy phase started; their VFAgentPick: ___
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
| 06 | Outlines only on the visible part of a target, the tint grows with distance, N changes it | V3, V4, T7 |
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
