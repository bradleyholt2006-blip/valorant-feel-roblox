# Studio test session

The offline tests and the type checks cover the shared simulation; this session covers what only
Studio can show. It goes through every "Known gaps to check in Studio" item in the seven research
docs, in an order where each step only relies on things earlier steps showed working.

It takes a little over an hour. Doing it in parts is fine; keep the order.

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
4. Press Play (F5). Sections 1 to 8 need one player, section 9 needs two, and section 10 needs one
   and then two.

| Key | What it does |
| --- | --- |
| F2 | Labs, one press each: Weapon Lab, Spray Lab, Hit Reg Lab, off |
| F3 | HUD panel (on at the start) |
| F4 | Counter-Strafe Lab |
| F6 | Record movement to a CSV in the Output window |
| G | Ghost box where the server has you (while the HUD is on) |
| Z | Zero the mouse counter (while the Counter-Strafe Lab is open) |
| F10 | Hitbox and wall overlay |
| V | The look (lighting, vignette, outlines) off and on again, to compare with the place's own |
| N | The next enemy outline colour |
| P | The arena on and off |
| Backspace | Clear impact marks, the shot log, the lab counters, the spray plot, and the Counter-Strafe Lab's stops while it's open |
| 1 / 2 / 3 | Vandal / Classic / knife (the starting loadout) |
| 4 to 8 | Give yourself a Vandal, Phantom, Operator, Sheriff or Classic (in the arena: anyone, during the buy phase or while waiting) |

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
  air above it, which would mean your own body is getting in the way of your shots. No part of
  your Roblox avatar shows when you look down, straight after pressing Play as well as after a
  respawn.
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

- **A1 On.** Press P. The Output window shows `[VF] Arena on`, and you respawn in a small room with
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
  away, and 4 to 8 give you any weapon.
- **A4 Off and on.** Press P: the Output window shows `[VF] Arena off`, you're back at the course's
  spawn, the score bar and banner are gone, and the dummies still have red outlines. Press P again
  and you're back in the NORTH room, facing the hall. Then hold W and press P twice more, so each
  new life starts while you're running. Each time you start at the spawn and run on from there
  with no snap back, and the HUD's `max` correction stays at `0.0 mm`. The `corrections` count can
  go up by one at each spawn, as at any spawn.

Then two players: stop the game and start a Local Server with 2 players, as in section 9.

- **A5 Sides.** Press P in window 1. One player spawns in the NORTH room and the other in SOUTH,
  and both screens show `ROUND 1` and a banner counting down from `BUY PHASE 15`. In the server
  window's Explorer, Teams holds North and South, with one player on each.
- **A6 The buy phase.** During the countdown, each room has a see-through orange or teal barrier
  across its open side. You can't walk through it, and a shot at it stops on it. 4 to 8 change
  weapons. At 0 the barrier disappears, you can walk out, and 4 to 8 no longer change your weapons
  until the next buy phase.
- **A7 Seeing each other.** Each player sees the other with the red enemy outline, never through
  walls. Standing anywhere in your own room, you can't see into the other one.
- **A8 A round.** Player 1 kills player 2. Player 1's screen shows `ROUND WON` in blue and player
  2's shows `ROUND LOST` in red, and player 1's side scores 1. About 3 s later both respawn in their
  rooms for `ROUND 2`, with `BUY PHASE 3`. Player 1, who was still alive, starts the new round
  cleanly: no snap back, and if they weren't hit, `max` stays at `0.0 mm`. Each player still has
  the weapon they had.
- **A9 First to 10.** Play on until a side has 10 (one player can stand in the open while the other
  shoots). The winner's screen shows `VICTORY` and the loser's `DEFEAT`, each with the final score
  under it, and about 6 s later round 1 of a new match starts at 0-0 with the 15 s buy phase.
- **A10 Leaving.** Close player 2's window. Player 1's banner goes back to
  `WAITING FOR AN OPPONENT`, the barrier goes if it was up, and the score stays.
- **A11 Off again.** Press P in window 1. Player 1 is back on the course, on no team, and Teams is
  empty.
- **A12 Teammates (optional).** Stop the game, start a Local Server with 3 players and press P in
  window 1. Players 1 and 3 share the NORTH room, each on their own spot, and player 2 has SOUTH to
  themselves. Players 1 and 3 see each other with a faint blue outline, and their shots pass
  through each other without hurting. North loses a round only once both of its players are down.

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
