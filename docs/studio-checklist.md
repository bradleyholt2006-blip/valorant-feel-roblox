# Studio test session

The offline tests and the type checks cover the shared simulation; this session covers what only
Studio can show. It goes through every "Known gaps to check in Studio" item in the sixteen research
docs, in an order where each step only relies on things earlier steps showed working.

It takes about three and a half hours. Doing it in parts is fine; keep the order.

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
   need one and then two. Section 11 needs headphones. Section 15 needs one, and sections 16 to
   20 one and then two.

| Key | What it does |
| --- | --- |
| F2 | Labs, one press each: Weapon Lab, Spray Lab, Hit Reg Lab, Sound Lab, off |
| F3 | HUD panel (on at the start) |
| F4 | Counter-Strafe Lab |
| F6 | Record movement to a CSV in the Output window |
| G | Drops the gun or the spike in hand; with the knife in hand and the HUD on, the ghost box where the server has you |
| F | Picks up the gun on the ground you're looking at, swapping it for yours |
| Z | Zero the mouse counter (while the Counter-Strafe Lab is open) |
| [ / ] | Footstep radius down and up 2 m, this client only (while the Sound Lab is open) |
| Y | Practice dummies' footsteps on and off (while the Sound Lab is open; off at the start) |
| H | The Sound Lab's rings on the floor on and off |
| F10 | Hitbox and wall overlay |
| V | The look (lighting, vignette, outlines) off and on again, to compare with the place's own |
| N | The next enemy outline colour |
| P | The next of: the arena (Skirmish), the spike rounds, the spike rounds in Swiftplay's format, and off |
| Tab | Held: the scoreboard, in the spike rounds |
| Backspace | Clear impact marks, the shot log, the lab counters, the spray plot, and the Counter-Strafe Lab's stops and the Sound Lab's log while they're open |
| 1 / 2 / 3 | Vandal / Classic / knife (the starting loadout); with the knife, the left button slashes and the right stabs |
| 4 | The spike, while you carry it; held, it plants in a site or defuses the planted spike |
| B | The buy menu: every gun and shield (on the course at any time; in the arena during the buy phase or while waiting) |
| O | The settings menu: your sensitivity and crosshair |
| 5 to 9 | Give yourself a Vandal, Phantom, Operator, Sheriff or Classic (in the arena: anyone, during the buy phase or while waiting) |
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
and 1 is W; add them to hold several. A boolean attribute `VFTestTake` set to true presses F
for you, and clears itself, and `VFTestBoard` set to true or false holds the scoreboard open as Tab
does or lets it go. `VFTestSettingsMenu` set to
true or false opens or closes the settings menu, and a string attribute `VFTestSetting` enters a
setting as its box in the menu would: `sensitivity=0.8`, `scoped=0.5`, `dpi=1600` or
`crosshair=` and a code.

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
  with the top speed between.
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
     `top` never goes past 5.40.

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
- **A4 Off and on.** Press P three times, through the spike rounds (section 17): the Output window
  shows `[VF] Arena on: the spike rounds, Standard`, then `[VF] Arena on: the spike rounds,
  Swiftplay`, then `[VF] Arena off`, and you're back at the course's spawn, the score bar and
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
- **A11 Off again.** Press P three times in window 1, through the spike rounds. Player 1 is back
  on the course, on no team, and Teams is empty.
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
  hears. Step off it onto the floor: the heard thud again. Spawning is silent: press P twice (the
  arena on, then off) and you appear without a sound. Nothing else plays with any of these:
  Roblox's own character sounds are off.
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
  (0, 0, 4) and `VFSpikeCarrier` 0. With the arena on (P) it reads `none here`. Press P three more
  times, through the spike rounds to off, and the spike is back on its tile.
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

From [13-rounds.md](research/13-rounds.md). One player, then two, with the HUD on (F3). Outpost,
the spike rounds' map, is built off the course's left, about 150 m from its spawn, so you only see
it once you're in it. P moves on through Skirmish, the spike rounds, the spike rounds in
Swiftplay's format, and off. Without keys, set Workspace's attributes from the server:
`VFArenaMode` `spike`, `VFMatchFormat` `standard` or `swiftplay`, then `VFArenaOn` true (false
for off). `VFMatchSkip` set true on Workspace from the server ends the phase being played and
clears itself: a buy phase, a round (as its clock running out, so the defenders win it) or the
wait for the next round, but never a planted spike's countdown. Skip whatever a check doesn't
need to wait out.

- **E1 On.** Press P twice. The Output window shows `[VF] Arena on: Skirmish`, then `[VF] Arena
  on: the spike rounds, Standard`. You respawn in a room with a red floor marked ATTACKERS, facing
  its door into mid, with the spike on the floor 4 m in front of you: `VFSpikeLayout` is
  `outpost` and `VFSpikePosition` (-150, 0, 29). The top bar shows `0` and `0` with `SPIKE ROUNDS`
  and `STANDARD` between them, and the banner reads `WAITING FOR AN OPPONENT`, with `Standard,
  first to 13` under it. Teams holds Orange and Teal, and you're on Orange. You have the Classic
  (2) and the knife (3), and no shield.
- **E2 The map.** Walk round it. From the spawn, a door on the left leads through a lobby and A
  main, a long corridor, to site A; the door ahead leads into mid; the door on the right to B the
  same way. Each site has an amber plant area marked A or B with crates round it, the dark ones
  low enough to shoot over standing and the light ones high enough to hide you. A link joins each
  site to mid, past a pillar. The defenders' spawn is at the far end, with a blue floor marked
  DEFENDERS, a door to mid and a back hall to each site. The walls are 5 m tall: you can't jump
  out or see over them, and from anywhere in either spawn you can't see into the other. Nothing
  else in the place pokes into it. **Send:** a screenshot from each site, and whether the map
  feels too big, about right or too small for 1v1 and for 2v2.
- **E3 Waiting.** Alone, there are no barriers, B opens the buy menu, and 5 to 9 give weapons.
  Walk over the spike: you pick it up (`VFSpike` `carried`). In site A's plant area no `HOLD 4 TO
  PLANT` shows and holding 4 plants nothing: `VFSpikePlantOpen` is false while you wait, and
  `VFSpikeDefusers` is 2.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **E4 Round 1.** Press P twice in window 1. Player 1 spawns in ATTACKERS and player 2 in
  DEFENDERS, facing their door to mid. Both screens show the round's clock counting down from
  `0:45`, `ROUND 1   ATTACK` under it for player 1 and `ROUND 1   DEFEND` for player 2, and a
  banner counting down from `BUY PHASE 45`, its line reading `Attack: plant the spike at A or B
  B buy menu` for player 1 and `Defend A and B   B buy menu` for player 2. Each spawn's three doors
  have see-through barriers, red for the attackers' and blue for the defenders', and you can't
  walk through them. Both players have the Classic and the knife, and no shield, and the spike lies
  in front of player 1.
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
- **E11 The half.** Press P in window 1: `[VF] Arena on: the spike rounds, Swiftplay`, and a new
  match at 0-0, with both players back on the Classic and the knife. Skip through the buy phases
  and rounds: the defenders win each one on time. Round 4's buy phase adds `LAST ROUND OF THE
  HALF`, and its end adds `SWITCHING SIDES`. Round 5 has player 2 in ATTACKERS with the spike in
  front of them and player 1 in DEFENDERS, both on the Classic and the knife again, with a buy
  phase from 45, and the bar reads `DEFEND` for player 1 and `ATTACK` for player 2. From round 5,
  player 2's side is on 4, and its buy phases add `MATCH POINT`.
- **E12 Sudden death.** Keep skipping, so player 1's side wins rounds 5 to 8 on time: 4-4. Round
  9's buy phase reads `SUDDEN DEATH`, from 45, on the second half's sides. Skip it too: player 1
  wins it 5-4 and their screen shows `VICTORY` and player 2's `DEFEAT`, each with the score. About
  10 s later round 1 of a new match starts at 0-0, with player 1 attacking again and both on the
  Classic and the knife.
- **E13 Off.** Press P in window 1: `[VF] Arena off`. Both players are back on the course, on no
  team, Teams is empty, and the course's spike is back on its tile (`VFSpikeLayout` `course`).

## 18. The economy

From [14-economy.md](research/14-economy.md). One player, then two, with the HUD on (F3). Each
player's credits are their `VFCredits` attribute (Players, the player, Properties), and each side's
losses in a row are `Streak1` and `Streak2` on Workspace's `VFArena`. The expected numbers assume you
buy only what a check says. `VFMatchSkip` (section 17) ends a buy phase or a round, as there.

- **Q1 The pistol round's credits.** One player, on the course: B reads `THE COURSE: EVERYTHING'S
  FREE`. Press P twice for the spike rounds. B now reads `800 CREDITS`. Every gun and shield that
  costs more than 800 is dimmed with its price in red: everything from the Bucky (850) up, and Heavy
  Armor (1000). The sidearms, Light Armor (400) and the Regen Shield (650) aren't.
- **Q2 Buying and refunds.** Buy Light Armor: `400 CREDITS`. Now the Regen Shield isn't dimmed,
  since the Light Armor goes back for it: hover it, and the panel reads `250, with what you bought
  for its slot sold back`. Heavy Armor is dimmed. Buy the Regen Shield: `150 CREDITS`. Right-click
  it: `800 CREDITS` and no shield. Buy a Sheriff: `0 CREDITS` and the Sheriff in hand. Every gun for
  the primary slot and every shield is dimmed, and the other sidearms aren't, since the Sheriff goes
  back for any of them. Right-click the Sheriff: `800 CREDITS` and the Classic back.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **Q3 Round 1.** Press P twice in window 1. Both players' buy phase line starts with `800
  CREDITS` in gold, and both have `VFCredits` 800. Player 1's menu reads `800 CREDITS     WIN +3000
  LOSE +1900`.
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
- **L11 The dead drop theirs.** Press P twice in window 1 for the spike rounds. In round 1's buy
  phase, player 1 presses 5 for a Vandal. Skip the buy phase. Player 2 kills player 1 with the
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
- **J6 The tiles in the spike rounds.** Press P again: the tiles stay. Skip round 1's buy phase
  (`VFMatchSkip`). Player 1 kills player 2 with the Classic, and player 2 doesn't shoot back.
  Player 2's tile dims on both screens. Both kill feeds read `Player1   Classic   Player2`,
  outlined in gold on both, as both are in it: in window 1 player 1's name is blue, and in window
  2 it's red.
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

With three players (optional): start a Local Server with 3 players, and press P twice in window 1.
Two of them share a side (Teams shows who).

- **J11 Assists.** Skip the buy phase. One of the pair shoots the player on their own once, then
  the other kills them: the first one's row shows `0 0 1`, and the killer's `1 0 0`.

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
E2 Outpost: builds clean / something overlaps it (what); for 1v1 too big / about right / too small; for 2v2 too big / about right / too small
E6 the defuse round's banners: ___
E8 player 2's kit in round 3: ___
E11 round 5's spawns: ___; SWITCHING SIDES shown: yes / no
E12 the match ended ___ - ___, then a new match: yes / no
Q5 round 2's credits: player 1 ___, player 2 ___
Q8 round 3's credits: player 1 ___, player 2 ___; player 1's shield ___
Q10 round 4's credits: player 1 ___, player 2 ___
Q11 Swiftplay's credits, rounds 2, 3, 4, 5, 6 and 9: player 1 ___, player 2 ___
L1 the Vandal landed ___ m ahead
L6 the prompt went at ___ m along the floor
J1 a kill feed line stayed ___ s
J9 player 2's ACS ___, from VFScore ___
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
