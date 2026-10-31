# System 72: Basic Training

A new player's first mode on the Play menu: a tutorial, a step at a time, on the course, on a server
of its own. A panel at the top of the screen says what the step under way asks, naming the buttons
as the input in use has them (the keys, a gamepad's or a touch screen's), and how far through it the
player is; a gold marker shows where: a column of light at a spot to reach or the spike to fetch, a
ring under a target. Fourteen steps lead to the last: move to the end of the sprint lane; crouch
into the low tunnel; jump onto the lowest box; walk 6 m; shoot a target down; down another standing
still as the shot goes off; down the one behind the cover with a headshot; reload; aim down a
Vandal's sights and down a target 30 m away; buy a shield; use C, Q and E once each; use the
ultimate; plant the spike; and defuse it. A target downed the wrong way leaves a note on why it
didn't count, and the spike gone off before it's defused is back to planting. It starts on the spike
rounds' kit, the Classic and the knife with no shield, so the steps hand over what they teach.

The reference's first tutorial taught moving, jumping and crouching, a pistol and standing still to
shoot, a rifle and aiming down sights, walking silently, the buy menu, abilities, and planting the
spike and defending, in that order (a walkthrough). Its Basic Training since patch 8.10 is a
playable mode in three parts, basic gun use, the attackers' basics and the defenders' (a guide), and
an Event of missions and milestones in place of the Welcome Contract (Riot). The steps here keep
that order on the course's own lanes, so where each is, how far and what it says are ours. No game
file or source code was read, nothing was read from the live game, and no Riot asset is used.

## 1. Observable behaviour

- The original tutorial, in order: moving with W, A, S and D; jumping with the space bar and
  crouching with Control; a pistol picked up off the floor and a bot shot down; standing still to
  shoot; two more bots for a rifle, and a flying drone shot down with it; aiming down sights with
  the right mouse button; walking silently with Shift; the armory, opened with B; an aim test, then
  the agents' abilities; planting the spike, and defending.
- It could be played again in the practice range.
- Basic Training, since patch 8.10, is reached through Play, then Practice, in three parts: basic
  gun use (picking up guns, shooting, reloading, standing still to shoot), the attackers' basics
  (buying guns and shields, abilities, walking unheard, planting the spike and seeing it go off) and
  the defenders' (stopping the plant, or the spike).
- The Basic Training Event replaced the Welcome Contract: missions and milestones with rewards,
  shown as other Events are.

## 2. Publicly documented details

| What | Source |
| --- | --- |
| "We are releasing an update to our Welcome Contract for new players!"; "The new structure includes clearer missions and milestones to help you navigate the New Player Experience"; "If you have previously completed the Welcome Contract, you will not see the Basic Training Event" | Riot, [VALORANT Patch Notes 8.10](https://playvalorant.com/en-US/news/game-updates/valorant-patch-notes-8-10) |
| "players learn to jump with the spacebar and crouch with the Control key"; "The game instructs players to stand still while shooting or risk a major drop in accuracy"; "They can use the right mouse button to aim down their gun's sights"; "players learn to walk silently using the Shift key"; "the armory, accessed with the B key, which allows players to buy weapons and abilities"; "Completing the aim test leads to an explanation of Agents' abilities"; "a Spike planting tutorial and some defending" | DBLTAP, [Valorant Tutorial: How to Complete the Tutorial](https://www.dbltap.com/posts/valorant-tutorial-how-to-complete-the-tutorial-01e9v4n8enjy) |
| "Players can re-do the tutorial by heading into the practice range whenever they care to" | The same |
| A "playable tutorial mode", through Play then Practice, in three parts; "Movement Error is a VALORANT mechanic that significantly diminishes your shooting accuracy"; the attackers' goal: "enter any available Radianite sites, plant the Spike, and see that it successfully detonates" | Codashop, [Victory in Sight: Win Your First Match with VALORANT's New Basic Training](https://news.codashop.com/sg/?p=19303) |

Neither guide gives a step's place, distance or wording, so those are ours.

## 3. What can be measured, and how

The steps and what finishes each are plain functions, checked offline: `tests/training.luau` has 55
checks (the steps' order and places against the course's lanes, targets and spike; reaching a spot,
walking, a kill and its notes, a reload, the casts, the spike and its going off, the buttons' names,
the attributes and the Play menu's card), and the suite's 4236 pass. In Studio, PLAY for Basic
Training (or `VFTestPlay`) starts it, the player's `VFTestTraining` moves them to a step, and the
player's attributes and PlayerGui's `VFTraining` say where they are (section 76 of the checklist).

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| A mode of its own, for new players | First on the Play menu, played alone on a server of its own | Community | Codashop: a "playable tutorial mode" |
| The order | Moving, crouching, jumping, walking, shooting, standing still, the head, reloading, aiming down sights, buying, abilities, the spike | Community | DBLTAP's order, with Codashop's gun use (reloading) and attackers' basics (shields) |
| Standing still to shoot | A kill counts in STAND STILL only if its shot was fired accurate (`PlayerSim.isAccurate`, the movement error's own test) | Community | DBLTAP, Codashop |
| Aiming down sights with a rifle | A Vandal handed over, and a kill counts only aimed down its sights | Community | DBLTAP |
| Walking silently | 6 m walked with walk held | Community; the metres an estimate | DBLTAP; ours |
| The buy menu | A shield bought, free as the course has it | Community | DBLTAP, Codashop |
| Abilities | C, Q and E used once each, readying one aside, then the ultimate, charged as the course has it | Community | DBLTAP |
| The spike | Planted on either of the course's sites, then defused; gone off first, it's back to planting | Community | DBLTAP; Codashop's attackers' and defenders' basics |
| A headshot | The target behind the cover, only its head showing | Estimate | Ours |
| Where each step is, its radius, and what it says | `TrainingConfig.Steps` | Estimate | Ours, on the course's lanes |
| Counting a walk | 0.5 m/s at the least, 0.1 m at most a tick | Estimate | Ours |
| A note | Shown 5 s | Estimate | Ours |
| A pistol off the floor, bots that shoot back, the drone, the defenders' part, the guides (Brimstone, Sage), the rewards | None | Estimate | Ours: not in yet |

## 5. Design

### On the Play menu

Basic Training is the Play menu's first card, reading SOLO. PLAY for it always sends the player to a
new server reserved for it (ModeServers), never one already playing it, and that server plays the
course with the arena off and Workspace's `VFTrainingOn` true (`TrainingConfig.ON`, which
`PlayConfig.keyOf` reads as the mode). Everything else about the course stays as it is: its spike,
which anyone may plant and defuse, its dummies, its refills, its free buy menu and its agent select.
In Studio, PLAY for it switches the server as for any other mode, and whatever P asks for ends it.

### The steps

| Step | What finishes it | Where (x, z) |
| --- | --- | --- |
| MOVE | Feet within 1.2 m of the sprint lane's 20 m post | (20, -6) |
| CROUCH | Crouched, within 1 m of the tunnel's middle | (8, 8) |
| JUMP | Standing on the 0.50 m box | (-6, -10) |
| WALK | 6 m walked | Anywhere |
| SHOOT | The target 10 m down the range downed | (0, -10) |
| STAND STILL | The crouching target downed by a shot fired standing still | (-2, -20) |
| HEADSHOT | The target behind the cover downed by a headshot | (8, -22) |
| RELOAD | The magazine of the gun in hand filling again | Anywhere |
| AIM DOWN SIGHTS | A target 30 m away downed aimed down the Vandal's sights | (1.5, -30), 3 m either side |
| BUY | A shield worn | Anywhere |
| ABILITIES | C, Q and E used once each | Anywhere |
| ULTIMATE | X used | Anywhere |
| PLANT | The spike planted, by the player | Fetched from behind the spawn, (0, 4); either site |
| DEFUSE | The spike defused, by the player | The planted spike |
| DONE | Nothing: the last | |

Places are the course's, in metres across the floor, the spawn at the origin facing down -Z.

### What counts

TrainingServer feeds TrainingRules what the server sees for each player in it: each tick's feet,
ground and crouch (for a spot), walk held and movement (for a walk) and the magazine of the gun in
hand (for a reload); a shield worn; each ability cast, those that only ready one (put in hand, drawn
again, an ending) aside; each kill of a dummy, with whether its shot was fired accurate, hit the
head and was aimed down sights; and the spike planted or defused by the player, or gone off. A
target downed by the step's spot but not as it asks leaves a note: moving as the shot went off, not
the head, or not aimed down sights. The spike gone off while it's to be defused is back to planting,
with a note. A step that gives a weapon (the Vandal) puts it in its slot as it starts and in each
life during it. The step under way, how far through it the player is (the metres walked, the
abilities used) and the note go on the player as attributes.

### On the client

TrainingView draws a panel at the top of the screen while the player has a step: BASIC TRAINING and
the step's number, its title, what it says with the buttons named for the input in use
(`TrainingRules.text`: the keys, a gamepad's or the touch screen's), and at the bottom how far
through it they are, or for 5 s a note in red. It moves down under the spike's light while the
spike's planted. A gold marker shows where: a column of light at a spot or the spike to fetch, a
ring on the floor under a target. A gun the step hands over mid-life is drawn.

### Not in yet

- A pistol picked up off the floor, bots that move and shoot back, the drone, and the defenders'
  part with a side to play against.
- The guides' voices, and rewards.
- Starting over from the first step on the same server: it takes PLAY for another mode, then Basic
  Training again.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Training/TrainingConfig.luau` | The steps, the buttons' names, the notes, the attributes and the numbers |
| `src/shared/Training/TrainingRules.luau` | Where a player is, what finishes each step, the notes, and the text with the buttons named |
| `src/server/TrainingServer.luau` | Each player's way through, fed by the ticks, casts, kills and the spike; the kit, the weapon handed over, and the Training remote |
| `src/client/TrainingView.luau` | The panel, the marker, and a gun handed over drawn |
| `src/server/Arena.luau` | The course with Basic Training while `VFTrainingOn` is set and the arena's off; `Arena.has` and `playing` |
| `src/shared/Match/PlayConfig.luau` | Basic Training's card, first, for one; `keyOf` |
| `src/server/ModeServers.luau` | A new server each time; the mode set and read |
| `src/client/PlayMenu.luau` | SOLO on its card; the mode read |
| `src/client/Debug/TestAim.luau` | `VFTestTraining` |
| `src/shared/Net/Remotes.luau` | The Training remote |
| `tests/training.luau`, `tests/play.luau` | 55 checks, and the Play menu's |
| `docs/studio-checklist.md` | Section 76 |

## 7. Debug tools

- `VFTestPlay` "training" on the player, in Studio: presses PLAY for Basic Training, which switches
  the server to it.
- `VFTestTraining` on the player, in Studio: a step's key ("plant") moves the player to that step,
  then clears itself.
- The player's `VFTrainingStep`, `VFTrainingProgress` and `VFTrainingNote`: the step's key, how far
  through it they are ("2 / 3", "4 / 6 m"), and the note as a template with the buttons' names in
  braces.
- PlayerGui's `VFTraining` carries `Step`, `Text` (the panel's lines, apart by " | ") and `Note`
  (the note shown).
- The server's Output: `[VF] Arena off: Basic Training` as it starts, and
  `[VF] training: <UserId> at <step>` at each step.

## 8. Refinement loop

1. Play it through with the keys, a gamepad and a phone: where a step's text or marker leaves a new
   player unsure, and where a step is too easy or too hard to finish.
2. Tune `TrainingConfig` and re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- PLAY for Basic Training: the course, the kit, the panel and the marker.
- Each step moving on once it's done, and not before; the notes.
- The spike gone off before the defuse, back to planting.
- The buttons named for a gamepad and a touch screen.
- Leaving it for another mode, with nothing of it left.
- On a live server: a new server for each player who picks it.

Section 76 of the [Studio checklist](../studio-checklist.md) covers these.
