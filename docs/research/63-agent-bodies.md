# System 63: agent bodies

Other players and bots are drawn as an agent's body: a rigged model, for now the kit body
Superhero_Male_A, 1.75 m tall, its bones posed every frame from what the snapshots say each one is
doing. Its legs step at the speed it moves, a foot that's down staying where it's put; its hips turn
toward the way it moves while its chest faces its aim; it crouches, leans into a run, tucks its legs
in a jump, bends its knees landing and lets its legs hang gliding. It holds what's in its hand as
that kind of thing is held: a long gun at the shoulder with the left hand on the foregrip, a sidearm
out in front in both hands, the knife low in the right hand, the spike in both and an ability's item
up in the right. It reloads, plants and defuses, takes an orb, and switches what it holds, the new
thing coming up from low.

What can be hit doesn't change. The hitboxes stay the analytic boxes the server tests shots against,
and the body is posed round them: wherever the pose would put the head, the whole body moves so the
middle of its head sits in the middle of the head box, to within a centimetre and a half. The
reference ties its hitboxes to its animated characters, and Riot has worked on making the two agree;
here the boxes come first and the body follows them, so what's seen is what's hit without the server
knowing anything about animation.

The animation is procedural: no recorded clips, only a few shapes and two-bone reaches worked out
each frame, after David Rosen's approach (GDC 2014) and Rune Skovbo Johansen's thesis on
semi-procedural locomotion (2009), which matches a stride's length and rate to the speed so a
planted foot doesn't slide. It's plain Luau, so the offline tests run the pose the game draws.

Everything comes from public sources: Roblox's documentation, a GDC talk's page, a university
thesis, a report on Counter-Strike: Global Offensive's animation update and Riot's own posts. No
game file, model or animation was read or extracted, nothing was read from the live game, and no
Riot image, model or sound is in the repository. The body's model is a kit body imported into the
place; it isn't in the repository either.

## 1. Observable behaviour

- In the reference, other agents are whole characters: their legs step as they move, quicker running
  than walking, and stand still when they stop; crouched, they bend at the knees and hips; in the
  air their legs come up.
- The upper body faces where an agent aims and bends to aim up or down, and the head looks along the
  aim, whichever way the legs are going.
- Each kind of weapon has its hold: long guns at the shoulder in both hands, sidearms out in front
  in both hands, the knife in one. A switch shows the new weapon coming up, and a reload shows the
  magazine changed.
- Planting and defusing show the agent's hands at the spike.
- What's shot at follows the character, and the two have to agree: in 2020 Riot named hitbox clarity
  as something to improve, and fixed a hit-registration bug that came from crouches getting out of
  step between the client and the server.
- Counter-Strike: Global Offensive's animation update rebuilt its animation to blend movement under
  any aim or action, kept it in step on every client continually, and moved its hitboxes to capsules
  on the animated skeleton.

## 2. Publicly documented details

| What | Source |
| --- | --- |
| "use simple procedural techniques to achieve interactive and fluid animations using very few key frames" | David Rosen, [Animation Bootcamp: An Indie Approach to Procedural Animation](https://gdcvault.com/play/1020049/Animation-Bootcamp-An-Indie-Approach), GDC 2014 |
| "the speed is found by dividing the distance by the duration of the motion cycle" | Rune Skovbo Johansen, [Automated Semi-Procedural Animation for Character Locomotion](https://runevision.com/thesis/rune_skovbo_johansen_thesis.pdf), Aarhus University, 25 May 2009, section 4.4 |
| "to ensure that the feet step correctly on the ground" | The same |
| "It should transition naturally between standing, walking, and running." | The same, section 1.2.1 |
| "Re-built animation statemachine to support blending locomotion over any weapon aim or action poses" | Counter-Strike: Global Offensive's update notes, quoted by GosuGamers in [its report on the update](https://www.gosugamers.net/counterstrike/news/32616-cs-go-update-hitbox-and-animation-overhaul) |
| "Replaced shared hitboxes with new capsule-based set" | The same |
| "we found and fixed a hit registration bug caused by crouch synchronization in a previous patch." | Riot, [Ask VALORANT #4](https://playvalorant.com/en-us/news/dev/ask-valorant-4), 31 July 2020 |
| "They highlighted these opportunities for improving reliability in combat: increasing hitbox clarity" | gfinity, [its report of Riot's comments](https://www.gfinityesports.com/valorant/valorant-hit-box-issues-riot-movement-readability-update-pc/) of 24 September 2020 |
| "Bones are non-rendered objects that drive the movement of one or more parts."; its `Transform` is "Not Replicated" | Roblox, [Bone](https://create.roblox.com/docs/reference/engine/classes/Bone) |
| "Under the Armature section, disable Add Leaf Bones." | Roblox, [Export requirements](https://create.roblox.com/docs/art/modeling/export-requirements), for a rig exported from Blender |

Riot doesn't publish how its characters are animated or how their hitboxes follow them, and nothing
here comes from the reference's animation. Every number in `BodyConfig` is ours, below.

## 3. What can be measured, and how

The pose is plain Luau, so the offline tests (`tests/body.luau`, 49 checks) play bodies frame by
frame at 60 frames a second, the speed, the aim and the crouch changing only as quickly as the
snapshots can change them: a counter-strafe's braking, a quick flick, the crouch's transition. They
pose nine ways of moving (standing; running ahead, back, sideways and diagonally; walking; running
with the knife; crouch-walking ahead and sideways), each aiming level, up and down, with each kind
of hold, and measure:

| What | Measured | Checked against |
| --- | --- | --- |
| The middle of the head from the head box's, across | 0.008 m at most | 0.03 m |
| ...and up or down | 0.014 m at most, running diagonally and looking down | 0.03 m |
| The lowest a foot's joint goes | 0.004 m above the ground | 0.005 m below |
| The furthest a limb reaches, of its length | 0.985 | 1 |
| A planted foot's slide, of the body's speed | Walking 4%, running 3%, with the knife 3%, backward 2%, crouched 8%; sideways 22%, not checked | 15% |
| The most a joint moves in a frame, past the ground's own move | 0.123 m, a finger as the hands go down to plant | 0.15 m |
| The feet in a jump | The left 0.26 m up, the right 0.17 m | The left higher |
| The feet gliding | 0.12 m apart, the hips 0.23 m | Closer than the hips by 0.06 m |
| The left hand reloading | 0.23 m down from the foregrip, and back on it after | 0.15 m; 0.01 m |
| A new gun's barrel, its first frame | 0.78 of its way down | Over 0.5 down, then along the aim |

The kit's skeleton, read as the importer brings it in and drawn 1.75 m tall, has its hip joints at
0.980 m, thighs of 0.444 m and shins of 0.416 m, upper arms of 0.286 m and forearms of 0.268 m, and
the middle of its head at 1.633 m, 1.3 cm over the standing head box's middle. Drawn taller, the
head held in its box would bend the knees standing: with a rifle, they bend 24 degrees at 1.75 m, 38
at 1.78 m, 45 at 1.80 m and 50 at 1.82 m (15 at rest).

In the place, with the kit body in `VFBodies`, four bots of a side in the spike rounds' buy phase
and then running off as the round started: every head joint was inside its head block, 0.05 m under
the block's middle as the pose puts it; the ankles stood 0.13 m over the soles standing and came up
to 0.36 m in the stride; and the bodies took 0.43 ms of a frame on average, 0.52 ms at most, and
0.67 ms with five. The meshes kept the pose they were imported in until each copy's parts were
jointed to its root part (section 5).

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| The body drawn round the hitboxes, its head in the head box | The middle of the head within 0.03 m | Estimate | Ours; the reference's hitboxes follow its characters |
| How tall it's drawn | 1.75 m, the standing head box's top | Estimate | The head box; taller bends the knees standing (section 3) |
| The head's bob and sway with the step | 0.012 m, 0.008 m | Estimate | Small enough to stay in the box |
| Stride rate | 1.0 + 0.2 a second per m/s, at most 2.3, quicker crouched (x1.4) and sideways (x1.35), and up to 2.8 where a stride would be longer than the legs reach | Estimate | A stride's length times its rate is the speed (Johansen) |
| A foot's share of the stride on the ground | 0.62 - 0.065 per m/s, from 0.26 to 0.6 | Estimate | Walking keeps a foot down; running has both up |
| The longest sweep under the body | 0.65 m, 0.42 m sideways, 0.75 of that crouched, and 35% shorter a radian up or down | Estimate | The tests: the head stays in its box |
| A foot rising onto its ball before the hips drop | Up to 0.5 radians | Estimate | Ours |
| Stance | Feet 0.12 m either side, 0.17 m crouched; a long gun's left foot 0.07 m ahead, 0.14 m crouched | Estimate | Ours |
| The hips turning toward the way it moves | 0.45 of the angle, at most 0.5 radians | Estimate | Ours |
| The crouch's lean | 0.5 radians, 0.55 of it at the hips | Estimate | The head box crouched at 1.10 m |
| The chest's share of the aim | 0.3 looking up, 0.1 looking down | Estimate | Bending the back looking down would drop the head out of its box |
| A long gun's bladed stance | The chest turned 0.5 radians, its left shoulder forward; a sidearm's 0.12, the knife's 0.15 | Estimate | So the left hand reaches the foregrip |
| Where each kind of thing is held | `BodyConfig.Hold`, from the top of the chest along the aim | Estimate | Ours |
| A switch, a draw | The hands over 0.2 s; the new thing up from low over 0.35 s | Estimate | About the quickest equip |
| Reloading | The left hand to the magazine and back every 1.6 s | Estimate | Ours |
| A bone's `Transform` | Applied on top of its rest, not replicated | Confirmed | Roblox's `Bone` |
| A rig's leaf bones | Off when exporting from Blender; the kit's FBX has them, and they're harmless | Confirmed (Roblox) | Roblox's export requirements |

## 5. Design

### The rig

`BodyRig` reads a skeleton from any rig with the kit's bone names (a `bn_` before a name is
dropped): each bone's joint where it rests, in metres in the body's own space (its soles at the
origin, facing -Z, its right along +X), and what the pose needs measured from them: each leg's hip,
knee, ankle, ball of the foot and toe tip, and the knee's axis at rest; each arm's collarbone,
shoulder, elbow and wrist, the elbow's axis, which way the hand points and its palm faces, and its
fingers; the spine from the pelvis to the neck; the head's joint and middle. It's scaled so the body
stands 1.75 m from its soles to the top of its head. A rig missing a bone the pose needs isn't
posed, and the agent's drawn as blocks, as before. The kit's own skeleton, 64 bones and the 15 leaf
tips its FBX carries, is kept in `BodyRig` as imported, for the offline tests.

### What the body is doing

`BodyMotion` works out from each frame's interpolated pose (where the feet are, the yaw and pitch,
the crouch, whether on the ground, the weapon, a reload, a plant, a defuse or an orb, and a glide)
how the body moves in its own space, smoothed over 0.08 s; turning on the spot shuffles the feet as
stepping sideways would. The stride follows the speed: its rate rises with the speed, its share on
the ground falls, and the sweep under the body is the speed times the time a foot's down, so a
planted foot stays put. Where that sweep would be longer than the legs reach, the steps get quicker
instead, up to 2.8 strides a second, past which a foot slides a little. Strides are shorter looking
up or down, since the head drops as it tips. The hips turn toward the way the legs step; stepping
backward they turn the other way, with a margin either side of straight sideways so they don't flip
about. It notes leaving the ground and landing (a landing after a fall bends the knees a moment),
reloads, plants, defuses, orbs and glides, each eased in and out, and when what's held changed.

### The pose

`BodyPose` turns that into a turn for each bone, in order:

1. The hips turn toward the way the legs step, swing and roll with the stride and tip forward to the
   crouch and to running. The back bends to the lean, the chest turned to the stance the weapon's
   held in (bladed with a long gun) and taking its share of the aim; the neck and head look along
   the aim, the head tipped toward a long gun's stock.
2. The whole body moves so the middle of its head is in the middle of the head box, with a little
   bob and sway with the step and a dip landing.
3. Each foot goes where it stands (apart, a long gun's left foot ahead and the right turned out) or
   along its stride: down, it sweeps back under the hips; up, it swings forward, lifting, and its
   heel comes up as it goes behind the hips, the toes bending to stay on the ground. In the air the
   legs tuck, the left higher; gliding they hang together. A foot the leg can't reach rises onto its
   ball, and only if that's not enough do the hips come down.
4. Each leg reaches its foot, its knee toward where the foot points; each arm reaches its hand's
   place, its elbow down, after the collarbone gives a little toward it. The right hand holds the
   weapon's grip, the left a long gun's foregrip (where the gun's look puts it) or a sidearm's grip
   round the right; the knife's left hand is up in front of the chest, and a free hand hangs and
   swings with the stride. The fingers close round what's held, the right index resting on a gun's
   trigger.
5. Reloading, the left hand goes to the magazine, down out of the gun and back; planting or
   defusing, both hands go down to the spike; taking an orb, the right hand reaches out. Switching
   what's held, the stance and the hands go from the old hold to the new over 0.2 s, and the new
   thing comes up from low.

### Drawing it

`BodyView` draws a body for each other player and bot from the model in ReplicatedStorage's
`VFBodies` folder (the one named `Default`, or else the first), as Roblox's importer brings a rig
in: a model whose `PrimaryPart` is the part its bones hang off, standing on that part's origin and
facing -Z. Each body is a copy, without the importer's `AnimationController`, joints and initial
poses, scaled to 1.75 m, its parts anchored and kept out of collisions, shots and touches. Each
frame the model's parts move together to the entity's feet and yaw in one `BulkMoveTo`, and the
bones are posed by their `Transform`, which Roblox applies on top of where a bone rests: a bone's
turn from its parent's in the body's space, `q`, becomes `R^-1 * q * R`, where `R` is the bone's
axes at rest, and the root bone's also carries the pose's move (`R^-1 * move * q * R`). A bone that
has turned less than 0.004 radians since it was last written isn't written again, so curled fingers
cost nothing. Each copy's parts are jointed to its root part, which the bones hang off: Roblox skins
a mesh only by the bones in its own assembly, and the importer's joints don't join the root part to
the meshes. What's held is built from its look (`WeaponLooks`), an ability's item from its lit
pieces only, and placed at the right hand's grip; it's hidden while planting, defusing or taking an
orb.

A hit lights the body white, a Shade (system 43) draws it dark and see-through, and spawn protection
in gun game draws it as a force field. The agent's blocks stay on the hitboxes, unseen, for the
label over the head and anything that finds an entity by them, and the outline round another player
is round the model the body's in; without a body in `VFBodies` the blocks are drawn as before.
Practice dummies stay blocks, so what's seen of them is exactly what can be hit. The agent being
watched while spectating isn't drawn, as before.

Nothing new is sent: the body is posed from the snapshot's pose, which the client has already, and a
body is only drawn where the snapshots put an entity, so the fog of war (system 35) holds. The
server knows nothing of bodies.

### The tests

`tests/body.luau` has 49 checks: the rotations; the kit's skeleton (its 79 bones in order, its
height, its soles on the ground, its limbs mirrored, its head in the head box at rest, the same
skeleton read off a rig at any scale and wherever it stands, and a rig missing a bone not posed);
how each weapon is held; the head in its box, the feet out of the ground and every limb reached
across the ways of moving, aims, crouches and holds; planted feet; the hands on what they hold, the
gun and the head along the aim, the fingers closed and the two sides mirrored standing empty-handed;
the legs in a jump and a glide; the reload, the plant and the draw; and no joint jumping 15 cm in a
frame whatever the body does next.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Body/BodyConfig.luau` | New: the body's numbers, each with its status and source |
| `src/shared/Body/Quat.luau` | New: rotations |
| `src/shared/Body/BodyRig.luau` | New: the skeleton read off a rig, and the kit's |
| `src/shared/Body/BodyMotion.luau` | New: what the body's doing from frame to frame, and the stride |
| `src/shared/Body/BodyPose.luau` | New: the pose |
| `src/client/BodyView.luau` | New: a body copied from `VFBodies`, posed, moved and painted, with what it holds |
| `src/client/RemoteEntities.luau` | Players and bots drawn as bodies, their blocks unseen; what the bodies cost, in Studio |
| `src/client/Debug/HitboxOverlay.luau` | The note that the boxes are drawn round the body |
| `tests/body.luau`, `tests/run.luau` | New: the 49 checks |
| `docs/studio-checklist.md` | Section 67 |

## 7. Debug tools

- F10's hitbox overlay draws each other player's and bot's boxes round its body, through walls (on a
  live server, not an enemy's): the head should sit in the head box, standing and crouched.
- A model put in ReplicatedStorage's `VFBodies`, named `Default`, is the one drawn; with no
  `VFBodies`, or a model that can't be posed, the agents are blocks again.
- In Studio, Workspace's `VFBodyMs` on a client has the milliseconds the bodies take of each of its
  frames, on average over the last second.

## 8. Refinement loop

1. In Studio, watch another player and bots walk, run, strafe, crouch, jump, glide, aim, reload,
   switch, plant and defuse, beside F10's boxes.
2. Tune `BodyConfig`, and re-run `tests/body.luau`: the head in its box, the feet planted, the limbs
   reached and no pops.
3. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The `Transform` sums on the real rig: each bone where the pose puts it, the skinned mesh
  following, and `ScaleTo` scaling the skinned mesh and its bones together.
- The head in the head box with F10, standing, crouched, and aiming up and down.
- The steps, the stance, the holds, the reload, the switch, the plant, the defuse, an orb, a jump, a
  landing and a glide, as they look.
- A hit, a Shade and spawn protection; the outline round the body and not the unseen blocks; the
  label over the head.
- What nine bodies cost a client's frame (`VFBodyMs`).
- Planting or defusing standing, the hands go down only to about the waist: the head stays in the
  standing head box, so the body can't kneel. Crouched, they reach the spike.
- A foot slides about a fifth of the body's speed running sideways (section 3).

Section 67 of the [Studio checklist](../studio-checklist.md) covers these.
