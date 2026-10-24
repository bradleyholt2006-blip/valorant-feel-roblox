# Studio test session

Systems 1 to 5 have so far only run outside Roblox: the offline tests and the type checks pass, but
nothing has been played in Studio yet. This session is that first run. It goes through every
"Known gaps to check in Studio" item in the five research docs, in an order where each step only
relies on things earlier steps showed working.

It takes about an hour. Doing it in parts is fine; keep the order.

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
4. Press Play (F5). Sections 1 to 7 need one player; section 8 needs two.

| Key | What it does |
| --- | --- |
| F2 | Labs, one press each: Weapon Lab, Spray Lab, Hit Reg Lab, off |
| F3 | HUD panel (on at the start) |
| F4 | Counter-Strafe Lab |
| F6 | Record movement to a CSV in the Output window |
| G | Ghost box where the server has you (while the HUD is on) |
| Z | Zero the mouse counter (while the Counter-Strafe Lab is open) |
| F10 | Hitbox and wall overlay |
| Backspace | Clear impact marks, the shot log, the lab counters, the spray plot, and the Counter-Strafe Lab's stops while it's open |
| 1 / 2 / 3 | Vandal / Classic / knife (the starting loadout) |
| 4 to 8 | Give yourself a Vandal, Phantom, Operator, Sheriff or Classic |

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
  because our jump peaks at 0.83 m, and 1.00 m is out of reach.
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

## 4. Weapons

From [02-weapon-firing.md](research/02-weapon-firing.md). Press F2 once for the Weapon Lab.

- **W1 Fire rate.** Hold fire with the Vandal at the back wall: the lab reads
  `fire rate 9.72 rps ... expect 9.75  within 1 tick`, and the Phantom (5) reads 10.98. The Sheriff
  (7), the Classic (8) and the Operator (6) fire once per click, and a click during the cooldown
  doesn't count. So clicking as fast as you can should come out a little under 4.00, 6.75 and 0.60
  (the lab says `OFF`), but never over. **Send:** the fire rate line for each weapon.
- **W2 Reload and draw.** Fire a few shots and press R. The lab should read `reload 2500ms` for the
  Vandal and the Phantom, 2250 for the Sheriff, 1750 for the Classic and 3700 for the Operator.
  Switch weapons and hold fire straight away: `draw->shot` is at least the equip time, which is
  1000 ms for the Vandal, 750 for the Classic and 1500 for the Operator.
- **W3 Damage and kills.** Shoot the static dummy at 10 m with the Vandal. The numbers that float
  up read 160 for the head, 40 for the body and 34 for the legs, and the part you hit flashes
  white. One headshot or four body shots kill it: it disappears, the kill feed shows it, and it's
  back 2 s later.
- **W4 Agreement.** Against the static dummies, the shot log's `agree` stays at 100% and every row
  says `ok`.
- **W5 First shots after spawning.** Stop the game, press Play again, and shoot the 10 m dummy
  straight away: those first shots say `ok` too. The server's first message after you spawn sets
  your spray seed ([03-spread-recoil.md](research/03-spread-recoil.md)), and it has to arrive
  before your first shot.
- **W6 Your own body.** Look down at your feet and fire. The marks land on the floor, not in the
  air above it, which would mean your own body is getting in the way of your shots.
- **W7 Operator scope.** With the Operator (6), mouse 2 cycles through 2.5x, 5x and off. Scoped
  shots land exactly on the crosshair. Unscoped shots spread widely (5 degrees).

## 5. Spread and recoil

From [03-spread-recoil.md](research/03-spread-recoil.md). Press F2 twice for the Spray Lab.

- **R1 Spray pattern.** Stand on the 50 m stripe a few steps to the right of the dummy there,
  facing the back wall, which is 10 m away. Hold fire with the Vandal for a whole magazine without
  touching the mouse. On the wall, the first three marks are close together. Then they climb,
  reaching about 80 cm above where you aimed by bullet 9 and 1.1 m by bullet 16, with a side to
  side drift from bullet 9 on. The Spray Lab's dots should make the same shape as the marks
  (1 square is 1 degree, which is 17.5 cm at 10 m). **Send:** one screenshot with the wall and the
  plot both in view.
- **R2 Cone ring.** With the HUD on, fire single shots half a second apart. The ring around the
  crosshair is green, and each mark lands inside it.
- **R3 Moving error.** While you run, the ring turns red and grows, and shots spread wide. Walking,
  it's smaller. Crouched and still, it's smallest.
- **R4 Recovery.** After a spray, wait about 0.4 s. The Spray Lab's `next shot now` line reads
  `bullet 1.00`, and the next shot lands on the crosshair.
- **R5 Camera kick at 60 and 240 fps.** The view kicks up with each shot and settles back as the
  spray recovers. If the Roblox menu (Esc, Settings) has Maximum Frame Rate, spray once at 60 and
  once at 240 (the HUD shows `fps`). The kick should feel the same and the marks on the wall
  should make the same pattern.

## 6. Hit registration

From [04-hit-registration.md](research/04-hit-registration.md). Press F2 three times for the Hit
Reg Lab and F10 for the overlay. Backspace clears the lab's counters between steps.

- **H1 Snapshots.** With nothing simulated, `snapshots` reads about 60/s with `lost 0`, `held a pose
  on` is close to 0% of frames, and `render delay` is about 20 to 35 ms. **Send:** a screenshot.
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
  more times. Agreement is still about 100%. The odd `snapshot` difference is fine.
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
  Every shot is `capped`: the server goes back the full 140 ms, which still leaves about 65 ms
  between what you saw and what it tests. Agreement on moving targets is a bit under half for body
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

- **P1 Damage through walls.** Shoot each wall once at body height with the Classic (8), the Vandal
  (4) and the Operator (6, scoped). In the open at this range, a body shot does 26 with the
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

## 8. Two players

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
- **T2 Animation.** Does the other player's character play its walk animation, or slide along
  standing still? Either is fine for now; say which.
- **T3 Hitting a player.** Press F10 in window 1. Player 2 strafes left and right in the target
  lane, 10 to 20 m out, and player 1 shoots them. Shots register, with damage numbers and hit
  confirms, and the overlay's boxes turn white on them. No impact marks appear on their body, which
  would mean characters block shots.
- **T4 Death and respawn.** Kill player 2 with one Vandal headshot or four body shots. Their screen
  shows `ELIMINATED - respawning` and the kill feed shows the kill. About 3 s later they're back at
  the spawn with full health and shields, and they can move and shoot.
- **T5 Their holes.** Player 2 shoots the wallbang walls. Player 1 sees the same holes, puffs and
  sparks in the same places.
- **T6 Corrections.** When players only move, `max` on both HUDs doesn't grow. Being shot slows you
  down, and that slow comes from the server, so it can add a few millimetres.

## Results

```
S1 self-test line:
C3 counts: slider ___ gave ___ counts, slider ___ gave ___ counts (mouse DPI, if known: ___)
M2 counter: accurate ___ ms, stopped ___ ms; release: accurate ___ ms, stopped ___ ms
M9 corrections max: ___ mm (no latency), ___ mm (50 ms each way)
W1 fire rate: Vandal ___, Phantom ___, Sheriff ___, Classic ___, Operator ___
H1 snapshots ___/s, render delay ___ ms, held a pose on ___% of frames
H2 agreement ___%, rewind mean ___ ms
H5 agreement ___%, rewind mean ___ ms, hit confirm ___ ms, round trip ___ ms
H7 agreement on moving targets with the cap at 0: body ___%, head ___%
H8 agreement on moving targets past the cap: body ___%, head ___%
H9 strafer's biggest jump: ___ m/s, and with 40 ms and jitter: ___ m/s
T1 motion on the other player: speed ___ m/s, last second ___-___, biggest jump ___ m/s
T2 animation: walks / slides
Didn't look right (IDs and what you saw):
```

## Which check covers which known gap

| Research doc | Known gap | Checks |
| --- | --- | --- |
| 01 | The client's per-frame root CFrame wins over the replicated one without flicker | T1 |
| 01 | Collision with ramps, the angled wall and the jump boxes' faces | M5, M6, M7 |
| 01 | Whether `GetMouseDelta` needs Roblox's sensitivity divided out | C3 |
| 01 | Humanoid animation with an anchored root | T2 |
| 02 | Mouse buttons reach the game, and right-click isn't taken by the camera scripts | C1 |
| 02 | Viewmodel and muzzle flash in front of a scriptable camera at 103 degrees | C2 |
| 02 | The `VFCharacters` group keeps characters out of shot traces | W6, T3 |
| 02 | Death and respawn with an anchored root and `BreakJointsOnDeath` off | T4 |
| 03 | The camera kick at 60 and 240 fps, and the HUD ring on the impacts | R5, R2 |
| 03 | The first ack after spawning corrects the seed before the first shot | W5 |
| 03 | The Spray Lab's plot matches the marks on the wall | R1 |
| 04 | The render clock settles on Roblox's real snapshot timing | H1 |
| 04 | `viewTime` is read before remote entities move | H2, H3 |
| 04 | Hit confirms stay on the body part and go when the target dies | H4 |
| 04 | About 100% agreement against strafers, with white boxes in the overlay | H2, H3, H5 |
| 04 | Pacing keeps other players and dummies smooth with Roblox's real timing | H9, T1 |
| 05 | Rays that start inside a part don't hit it, and the back cast's normal faces out | S1 |
| 05 | The self-test's parts are found by raycasts one frame after they're added | S1 |
| 05 | Holes, dust and sparks on the right faces, other players' holes, white wall labels | P2, P4, T5 |
