# System 4: Hit registration and lag compensation

This covers how the server decides what a shot hit when the shooter, the target and the server
are each looking at a slightly different moment: how other players are drawn (interpolation, the
render clock, and the server pacing their moves so they move evenly), what time each shot carries,
how the server rewinds targets to what the shooter
saw and how far it is willing to go (the rewind cap), how hits are shown (a client-predicted spark
at once, the server's confirm a round trip later), and the tools that check the client and the
server agree. How a shot is traced and damaged is system 2; where the bullet goes is system 3;
how it goes through walls is system 5.

As before, everything comes from Riot's engineering blogs, patch notes, developer posts and
footage. No game files, memory, network traffic or protected assets were used. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site or guide, not by Riot |
| **Estimate** | Our own number. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- You aim at where the enemy is on your screen, not ahead of them. A shot that was on a strafing
  target on your screen counts, at any normal ping.
- Feedback comes in two steps: the tracer and a small spark at once, then the hit confirm (blood
  or sparks) about one round trip later, stuck to the body part that was hit and moving with the
  character. Headshot effects are a little smaller than body ones.
- You can be hit just after reaching cover, more often by players with high ping. Since Patch 6.02
  the window is shorter, and players with very high ping miss moving targets they appeared to hit.
- Peeking: the player who swings round a corner sees the holder before the holder sees them
  (peeker's advantage), 40-70 ms on average.
- The Network Buffering setting (Minimum, Moderate, Maximum) smooths other players' movement on a
  bad connection at the cost of seeing them a little later.
- On a connection that drops packets, other players "pop": they freeze for a moment, then jump.
- Otherwise other players move smoothly on your screen: someone running at a steady speed doesn't
  speed up and slow down from frame to frame, even when their own connection is uneven.
- Once a lethal shot is processed, the victim's later shots don't count, even if they fired on
  their own screen at about the same moment.

## 2. Publicly documented details

How it works (Riot):

| Fact | Status | Source |
| --- | --- | --- |
| "Hit registration in VALORANT works by saving player positions and animation state in a historical buffer. When the server receives a shot packet from the client, it rewinds the player positions and animation state using the historical buffer" | Confirmed | [VALORANT's 128-Tick Servers](https://technology.riotgames.com/node/112) |
| Server hitboxes follow server-side animation, which runs every 4th frame: "In the event of a rewind we could lerp between the saved animations" | Confirmed | Same article |
| Clients "send up exactly what time in the simulation they were looking at when firing a shot"; "In reasonable networking conditions, this allows for near-perfect hit registration" | Confirmed | [Peeking into VALORANT's Netcode](https://technology.riotgames.com/node/111) |
| "When the server starts receiving data from a client, it establishes a basis between that client's timeline and its own"; "As each update arrives from a client, the server slots it into the corresponding slot in its queue", and it "sets up its basis (and adjusts as needed) to maintain a healthy queue of upcoming moves to execute" | Confirmed | Same article |
| When a move hasn't arrived in time, "the server will predict what the client would have done", usually that "they continued to hold down whatever keys were being held in the last received update" | Confirmed | Same article |
| "targeting one buffered frame of movement data for clients and an average of half a frame of movement data on servers"; "clients and servers always update movement, physics, and other related systems with a fixed timestep: exactly 128 times per second" | Confirmed | Same article |
| Running the simulation on whatever data is newest means guessing, and the wrong guesses make characters pop or slide to catch up: "This sort of artifact goes directly against our design goal of smooth movement, and would make it difficult for players to track a moving target." Corrections are "only seen by the player who encountered the underlying network issues"; "The other nine players continue to see smooth movement." | Confirmed | Same article |
| The rewind is capped: "Without limits, a player with 500ms latency could kill you a half second after you'd moved behind cover" | Confirmed | Same article |
| "When the server processes a lethal shot, it marks the victim as dead, rejecting any future shots from that victim" | Confirmed | Same article |
| "Adjusted max server rewind limit down to 140 ms from 200 ms." The 200 ms "was set ... based on what we deemed as acceptable networking conditions"; against high ping it "should feel less like you're getting shot after moving behind cover", and high-ping players "may start to experience hit registration inaccuracy" | Confirmed | [Patch 6.02](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-6-02/) (Feb 2023) |
| "shot results are entirely server authoritative"; "the client waits until it hears back from the server on the result before displaying a hit-confirm", so hit effects trail the tracer by "your connection's round trip time (i.e. 40 ms to the server = 80 ms delay between tracer and hit VFX)" | Confirmed | [The State of Hit Registration](https://playvalorant.com/en-us/news/dev/the-state-of-hit-registration/) (Aug 2020) |
| "Server hit VFX confirms will now spawn at the location of the hit on the character and stay attached to that position"; "An additional client-predicted small spark VFX now spawns immediately at the game space location of a hit", which "DOES NOT mean your shot has registered on the server"; headshot VFX "scaled down slightly" | Confirmed | [Patch 1.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-07/) (Sep 2020) |
| "NETWORK INTERP DELAY = 7.8125ms"; "SERVER FRAMERATE = 7.8125ms (1/128th of a second, 128-tick servers)" | Confirmed | [On Peeker's Advantage & Ranked](https://playvalorant.com/en-us/news/game-updates/04-on-peeker-s-advantage-ranked) (May 2020) |
| Peeker's advantage is "<ENEMY'S CLIENT FRAMERATE> + <ENEMY'S 1-WAY NETWORK LAG> + <SERVER FRAMERATE>" + "<YOUR 1-WAY NETWORK LAG> + <NETWORK INTERP DELAY>", "an average of 40-70ms" | Confirmed | Same article |
| The interpolation delay "causes a 7.8125ms desync between movement data and damage data": "the player's move position is always shown 7.8125ms behind from where they actually fired" | Confirmed | Same article |
| Network Buffering: "'Minimum' is 1 frame of delay (7.8125ms)", "'Moderate' is 3 frames of delay (23.4375ms)", "'Maximum' is 5 frames of delay (39.0625ms)"; packet loss of "1-3%" is "not uncommon", and without the delay it would show as "player pops" | Confirmed (developer post) | RiotStealthyJesus on r/VALORANT (2020), via [devtrackers.gg](https://devtrackers.gg/valorant/p/e1133afd-peekers-advantage-strafe-shooting) |
| The "Network RTT + Processing Delays" graph "should be roughly 20-30ms higher than your Network RTT" | Confirmed | [Gameplay Consistency Update 2](https://playvalorant.com/en-us/news/game-updates/valorant-gameplay-consistency-update-2/) (May 2022) |
| Riot audited "Can your client and the server ever disagree on how shots are processed?" and on "the target's animation pose": "everything's looking good on the correctness front" | Confirmed | [Gameplay Consistency Update](https://playvalorant.com/en-us/news/game-updates/valorant-gameplay-consistency-update/) (Apr 2022) |
| Worked example: peekers get about 141 ms more to react before Riot Direct and 128-tick servers; about 71 ms at 144 FPS with 35 ms ping | Confirmed | Peeking into VALORANT's Netcode |

**Not found publicly:** how many frames of history the server keeps (only that the cap limits the
rewind), whether the interpolation buffer adapts to jitter beyond the Network Buffering setting,
what the server does with a shot time newer than its own, and the hit confirm's exact size and
lifetime. Those are estimates below.

## 3. What can be measured, and how

Never use network shaping or lag-switch tools on the live game: Riot names lag switching as a
source of unfair peeker's advantage, so it can look like cheating and put the account at risk.
Higher ping comes from a distant server region in a custom game instead, with the game's own
network graphs (Network RTT, Network RTT + Processing Delays, packet loss) on screen. Record at
240 fps if you can: one frame is then 4.2 ms.

| Measurement | Method | Gives us |
| --- | --- | --- |
| Hit confirm delay | In the Range, shoot a bot; frames from the spark to the attached hit confirm, next to the Network RTT graph. Repeat on a distant region | Confirms that the confirm trails by one round trip plus processing, as ours does |
| Behind-cover window | A friend strafes into cover in a custom game, you fire as they reach it, both record. With a shared sound (the shot) to line the clips up, count frames between the friend reaching cover on their screen and the hit landing | How far back the server rewound for that ping |
| The cap | The same from more and more distant regions. The window stops growing at the cap, and past it your hits on a moving target start missing | `maxRewind` (Riot says 140 ms; this checks it) |
| Buffering | The same peek with the holder on Minimum, then Maximum; on the peeker's clip the holder should react about 31 ms (7-8 frames at 240 fps) later | The Network Buffering steps |
| Pops | Only on a connection that really drops packets (the packet loss graph shows it): count how often other players freeze then jump at Minimum and at Moderate | How the reference trades loss for delay |

Our own game can be measured with any ping: the Hit Reg Lab (section 7) adds latency, jitter and
loss to this client only, and Studio's Incoming Replication Lag setting works too.

## 4. Confirmed vs estimated, as implemented

All values live in `src/shared/Net/NetConfig.luau`, each with its status and source.

| Parameter | Value | Status |
| --- | --- | --- |
| Rewind cap | 140 ms (200 ms, and 0 for no lag compensation, one key away in the Hit Reg Lab) | Confirmed (Patch 6.02) |
| The server rewinds to the time on the shooter's screen | yes | Confirmed |
| A dead player's later shots are rejected | yes | Confirmed |
| Spark at once, server confirm on the body part and moving with it | yes | Confirmed (Patch 1.07) |
| Hit confirm size and lifetime | 7 cm head, 8 cm body, 0.35 s | Estimate (smaller for heads is confirmed) |
| Network Buffering | +0, +15.6, +31.25 ms over our minimum | Confirmed steps (Riot: 1, 3 and 5 frames) |
| Snapshot rate | 60 Hz: every server frame at Roblox's 60 Hz, and 60 a second from a server that steps faster (Studio's, at about 217 Hz) | Roblox's frame rate (the reference: 128 Hz) |
| Render delay | measured: the 98th percentile of how late snapshots arrive, plus one send interval, plus 2 ms; snapshots handled at one moment count once, and the first half second's don't count | Estimate (the reference: a fixed 7.8125 ms) |
| Render clock correction | eases (63% of a gap in 0.1 s), at most 10% faster or slower; jumps only when more than 0.25 s off | Estimate |
| Players and dummies in the snapshots | paced: each tick shown at its own time, as far behind the server's time as the newest tick was on all but 1% of the last 2 s of frames, plus 2 ms; eased like the render clock; never past the newest tick | Estimate (the reference runs queued moves on its own 128 Hz tick, half a frame behind on average) |
| History | 64 snapshots per entity (about a second) | Estimate (needs only to cover the cap) |
| Hitboxes | rebuilt from position, yaw and crouch; not animated | Simplification (the reference animates them) |

What the simulation produces (from `luau tests/run.luau`). A strafing practice dummy 15 m away
changes direction every 0.6 s; the shooter fires every 0.17-0.23 s, half the shots anywhere on the
target and half near its edges, over 60 s. The server runs 60 Hz frames, the client 144 fps.
"Agree" means the client's guess and the server's verdict name the same target and region (or
both miss); "as seen" means the server tested the pose that was actually on screen.

| Network | Agree | As seen | Rewind mean / max | Capped | Frames that held a pose |
| --- | --- | --- | --- | --- | --- |
| None (Studio) | 100% | 100% | 40 / 48 ms | 0 | 0% |
| 40 ms each way, 0-3 ms jitter | 100% | 100% | 124 / 133 ms | 0 | 0% |
| The same, no lag compensation | 30.1% | 30.1% | 0 | all | 0% |
| The same, 3% of snapshots lost | 100% | 99.7% | 124 / 133 ms | 0 | 1.6% |
| 75 ms each way (past the cap) | 52.6% | 52.6% | 140 / 140 ms | all | 0% |
| 40 ms each way, the old fixed 50 ms delay | 100% | 95.2% | 106 / 115 ms | 0 | 44.9% |

Aimed at the middle of the body or the head instead, as a player tracking the strafer does (and
the Studio checklist's H6 to H8), agreement on shots at the moving strafer:

| Network | Body | Head | Rewind mean | Capped |
| --- | --- | --- | --- | --- |
| 40 ms each way, 0-5 ms jitter, 2% of snapshots lost (H6) | 100% | 100% | 127 ms | 0 |
| The same, no lag compensation (H7) | 26.1% | 21.7% | 0 | all |
| None (Studio), no lag compensation | 100% | 82.5% | 0 | all |
| 80 ms each way, 0-5 ms jitter, 2% lost (H8, past the cap) | 43.9% | 23.0% | 140 ms (207 asked for) | all |

Without the full rewind, whether a shot agrees depends on where in the strafe it lands. The dummy
spends most of each 0.6 s strafe slowing down and speeding up, and near a turn it has hardly
moved, so those shots still agree; at full speed it has left the ray. Shots fired on an even beat
near 0.6 s or 1.2 s land at the same point of the strafe every time: 20 body shots at H7's latency
then agree anywhere from 0% to 100%, depending on when the first one goes, which is why the
checklist asks for uneven gaps. With no latency, the server's newest pose is only 25-30 ms newer
than the one drawn, and in that time the strafer moves less than the body's half width (0.22 m),
so body shots agree without lag compensation; only the head (0.12 m) shows the difference.

The render clock on its own: 40 ms each way gives a delay of 24.2 ms and no starved frames; with
0-8 ms of jitter, 30.3 ms and none; a jump from 40 to 100 ms settles within 2 s without the
entities ever moving backwards.

How evenly others move (`tests/pacing.luau`). A player runs left and right 15 m in front of a
still observer, 2 s each way at rifle speed (5.40 m/s), through the real path: their client's
frames, one packet of 128 Hz moves a frame, the server's input queue and simulation at 60 Hz. A
dummy strafes the same way on the server's clock. Each goes into the snapshots twice, as the newest
pose every server frame (what the server sent before pacing) and paced, and the observer draws
both with the render clock at the same frame rate as the player. Speeds are while running at full
speed; a jump is how far a frame's velocity is off the line through the frames either side
(`MotionMeter`, the Hit Reg Lab's motion line), over every frame, turns included; delay is the
mean time from the player being somewhere to being drawn there.

| Network, frame rate | Snapshots show | Drawn speed (5th-95th) | Frames within 1% of 5.40 | Biggest jump | Delay |
| --- | --- | --- | --- | --- | --- |
| Studio, 60 fps | newest pose | 5.06-7.29 m/s | 13.1% | 2.32 m/s | 54.5 ms |
| | paced | 5.40-5.40 m/s | 100% | 0.23 m/s | 60.3 ms |
| Studio, 144 fps | newest pose | 2.53-7.59 m/s | 3.7% | 2.32 m/s | 36.3 ms |
| | paced | 5.40-5.40 m/s | 99.4% | 0.36 m/s | 43.0 ms |
| Studio, 60 fps, frames up to 20% long, server frames up to 2 ms late | newest pose | 1.79-7.25 m/s | 2.9% | 6.24 m/s | 53.4 ms |
| | paced | 5.37-5.43 m/s | 98.4% | 0.41 m/s | 65.6 ms |
| 40 ms each way, 0-5 ms jitter, 144 fps | newest pose | 2.53-7.59 m/s | 1.1% | 2.37 m/s | 118.7 ms |
| | paced | 5.39-5.42 m/s | 98.3% | 0.31 m/s | 128.0 ms |

Paced, the server had to hold a player on their newest move (the next hadn't run) on 0.3-0.4% of
frames, and shots at the paced player agreed with the server 100% of the time in every case. The
dummy gives the same picture: from the newest pose 4.84-7.59 m/s with jumps up to 1.5-3.9 m/s;
paced 5.39-5.42 m/s, 98.2% of frames or more within 1%, jumps at most 0.35 m/s, 5.5-6.5 ms later.
On a steady run the paced jumps stay under 0.04 m/s, except where a late move made the server hold
the player (0.41 m/s with uneven frames). The rest come from the turns, where slowing down
and speeding up again reach 0.36 m/s, so the lab calls a jump under 0.5 smooth.

## 5. Design

```
 server, each Heartbeat (60 Hz)                                         client
                                                                        snapshot ──► PoseHistory per entity (decoded poses)
 Replication: quantise every pose ─► snapshot {time, seq, poses} ─────►           InterpClock: render time from arrivals
              └──► LagCompensation.record (the same quantised poses)                draw every entity at the render time
                                                                                    │
 PlayerSimServer: one input per player per round, in tick order  ◄── input {..., viewTime = time of the frame on screen}
   └─ a shot falls out of a tick with that input's viewTime
        CombatServer.onShot
          ├─ rewindTime: viewTime clamped to [now - 140 ms, now]
          ├─ LagCompensation.targets: PoseHistory.sample at that time (the client's blend)
          ├─ level raycast, ShotResolver against the rewound boxes
          ├─ damage, tag, events
          └─ verdict {rewind, capped, origin, direction, tested poses, hit point} ──► ClientShots: match the guess, say why if different
                                                                                     WeaponEffects: confirm pinned to the box hit
```

- **One history, one blend.** Both sides keep a `PoseHistory` per entity. The server records the
  snapshot it sends, quantised exactly as the wire quantises it, and the client pushes what it
  decodes, so they hold the same numbers. `PoseHistory.sample` blends the two snapshots around a
  time the same way on both: position and crouch linearly, yaw the short way round, flags from
  the later one. Past the newest snapshot it holds the newest pose (no extrapolation), and after
  a gap of more than 0.25 s it starts over, so a player never slides from where they died to where
  they respawned. A test runs snapshots through the encoder and decoder and checks the server's
  rebuilt pose equals the client's bit for bit.
- **The shot time is the frame on screen.** Every input carries `viewTime`, the render time of the
  frame the player was looking at when the input was sampled (it is read before this frame's
  entities move). It is a time on the snapshot timeline, which is the server's clock, so the
  server needs no conversion and no clock sync.
- **A render clock measured from arrivals.** Riot buffers a fixed 7.8125 ms because its snapshots
  come every 7.8125 ms on a well-controlled network. Ours come every 16.7 ms over whatever the
  player's connection does, and a fixed delay that is too short makes entities stop at the newest
  snapshot and then jump (45% of frames at 40 ms each way with the old 50 ms delay). `InterpClock`
  measures instead: the earliest-arriving snapshot of the last 2 s says where the stream is; each
  snapshot's lateness against it plus one send interval says how far behind it had to be drawn;
  the delay is the 98th percentile of those plus 2 ms plus the Network Buffering setting. Lost
  snapshots don't count as long intervals (sequence numbers say how many were sent), so loss
  shows as a short pose hold, like the reference's "player pops", not as a bigger delay for
  everyone. The clock eases toward its target, closing 63% of a gap in 0.1 s and running at most
  10% faster or slower than real time, and never runs backwards, so neither a change in latency
  nor the small change each arrival makes to the target shows as jitter.
- **Bursts of snapshots count once.** A client that stalls (a long frame, loading) handles every
  snapshot that came in meanwhile at once, and draws nothing until it has, so those snapshots
  were never late for a frame; counted one by one they made a 0.3 s stall raise the delay to
  280 ms for the next 2 s. So snapshots handled within 1 ms of each other count as one moment,
  at the worst of them, and the percentile is over moments. Joining is the big case: Roblox holds
  a remote's events until its first listener connects, so a client that has just joined gets
  seconds of old snapshots at once. That held the delay at 660 ms in the offline test, and in
  Studio every shot in the first 3 s after joining was rewound to the cap. The first half
  second's arrivals don't count at all, and until there are some to measure the delay is two
  send intervals.
- **Paced snapshots.** The server runs a player's moves the moment they arrive, and they arrive in
  bunches: a client at 60 fps sends two or three 128 Hz moves a packet, and each 60 Hz server
  frame runs whatever has come in since the last. Sending each frame's newest pose made other
  players lurch, drawn at anything from 2.5 to 7.6 m/s while running at a steady 5.40, and the
  dummies, two or three 128 Hz ticks a frame, did the same in a regular beat. Riot's server runs
  each client's moves from a queue on its own 128 Hz tick, so everyone else gets them at an even
  pace. Ours keeps running moves at once, so nobody's movement or shots wait, and paces only what
  the snapshots show (`MovePacer`). Each tick's pose is kept at its own time: a player's move
  number over 128, or the server time of a dummy's tick. Every frame the server notes how far the
  newest tick is from its own time; the snapshot shows the entity at server time plus the low end
  of that over the last 2 s (on all but 1% of those frames the tick had run by then), less 2 ms.
  The time shown eases toward that target the same way the render clock does, never passes the
  newest tick (a late move makes the entity wait, then catch up gently) and never goes back. It
  costs 6-12 ms before others see a player move and about 6 ms for a dummy. Lag compensation
  records the same paced snapshots, so hit registration still checks exactly what the shooter
  saw.
- **Rewind and the cap.** The server rebuilds every other living entity at `viewTime` clamped to
  between 140 ms ago and now (a time from the future is checked at now). A shooter whose view is
  older than the cap is checked against the world at the cap, so they start to miss moving targets
  instead of hitting players who have already reached cover. The shooter and dead or unspawned
  entities are left out. Time an input spends queued on the server adds to its shot's rewind, so the
  server drains a backlog that stands (see Server authority in `01-movement.md`).
- **Shots in order.** The server used to run each player's whole input queue in turn, so a player
  late in the list could fire after a player who had already killed them. It now takes one input
  from each player per round, so shots are resolved in about tick order and a lethal shot is
  processed before the victim's later shots, which are then rejected as Riot's are.
- **The verdict says what the server tested.** Besides the hit, it carries how far the server went
  back, whether the cap moved the time, the shot's origin and direction as the server simulated
  them, the distance to the level, and the pose and source snapshots of every rewound target near
  the ray (positions as float32 metres, which the wire keeps exactly). The client compares that
  with its own trace and names the first reason for any difference: `capped` (the cap moved the
  time), `shooter` (the server's shot started or pointed elsewhere: a movement correction),
  `gone` (a target one side tested wasn't there on the other), `snapshot` (the pose came from
  different snapshots: one was lost, late or held), `pose` (same snapshots, different pose: a
  bug), `world` (the level stopped the shot at another distance), `edge` (none of these: a
  rounding hair, also worth a report).
- **Hit feedback, as Patch 1.07 has it.** The client's own trace draws the tracer and a small
  spark at once; it is never a hit marker. When the verdict comes, the hit point is turned into
  coordinates within the box that was hit (`Hitboxes.boxFraction`) and the confirm is drawn at
  those coordinates on the target's current box each frame, so it moves, turns and crouches with
  the character. Hit markers and damage numbers still come only from the verdict.
- **Simulated network for our own game.** `NetSim` sits between the client's gameplay remotes and
  the code that uses them. It can add latency each way, jitter and loss: unreliable messages
  (snapshots, acks, tracers) can arrive out of order or be dropped, reliable ones (inputs,
  verdicts, combat events) only arrive later, in order. To the server it looks like a player with
  a worse connection, so the cap applies to it like anyone else.

### Roblox differences that matter

- **Studio's server runs fast.** In Studio the server steps at about 217 Hz, not 60, and the old
  rule of a minimum spacing between snapshots let 72 a second through. Now a server stepping
  faster than 60 Hz earns a share of a send each frame and sends on the frame nearest a whole one
  (`SendSchedule`), so Studio sends 60 a second like a live server, and a 60 Hz server still sends
  on every frame, however unevenly its frames come.
- **60 Hz frames.** The server's frame and the snapshot rate are 60 Hz against the reference's
  128 Hz, so our render delay is about 24-30 ms against 7.8 ms, and a rewind is 20-30 ms longer
  than the reference's at the same ping (40 ms at zero ping, 124 ms at 80 ms of round trip).
  With the same 140 ms cap our shooters reach it at about 100 ms of round trip, where the
  reference's reach it at roughly 115-125 ms (our estimate from its published buffering). Raising
  our cap to about 170 ms would cover the same pings, at the price of victims being hit up to
  30 ms longer after reaching cover. We keep the confirmed 140 ms; it is one tuning value
  (`maxRewind`) if playtests say otherwise.
- **Peeker's advantage** follows: by Riot's formula ours is about one frame + the round trip + the
  render delay, so roughly 25-30 ms more than the reference at the same ping. Only faster server
  frames would close that, which Roblox doesn't offer.
- **No fixed tick for running moves.** Roblox gives the server a 60 Hz Heartbeat, not a 128 Hz
  loop, and a client's moves come two or three to a packet. The reference queues each client's
  moves and runs one per 128 Hz tick, half a frame behind on average; ours runs them when they
  arrive and paces the snapshots, which costs 6-12 ms of delay for players and about 6 ms for
  dummies where the reference's queue costs about half of a 7.8 ms frame.
- **No hitbox animation, and blocks for bodies.** The reference animates server hitboxes (every
  4th frame, lerped on a rewind). Ours are boxes rebuilt from position, yaw and crouch, which makes
  the rewind exact but means a running or crouching character's limbs don't move their boxes.
  Until there are agent models, other players are drawn as those boxes, like the dummies, with
  their Roblox avatars hidden, so what you see of anyone is exactly what can be hit.
- **No penetration (until system 5).** Shots stopped at the first level geometry here; system 5
  traces them through walls, and the verdict now carries the walls too.
- **Ping in Studio is close to zero.** Hence the simulated network. Real packet loss on Roblox's
  reliable channel shows up as extra delay (resends), which `NetSim` doesn't model.

## 6. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Net/NetConfig.luau` | The cap, render clock, pacing and buffering numbers, and the reference values the lab compares with, each with status and source |
| `src/shared/Net/PoseHistory.luau` | Pose history and the one interpolation rule both sides use |
| `src/shared/Net/InterpClock.luau` | The render clock: delay measured from snapshot arrivals, a burst counted once, eased, never backwards |
| `src/shared/Net/SendSchedule.luau` | Which server frames send a snapshot: every one at 60 Hz, 60 a second from a faster server |
| `src/shared/Net/MovePacer.luau` | Each player's and dummy's ticks put on a steady timeline for the snapshots |
| `src/shared/Net/MotionMeter.luau` | How evenly something moves on screen: speed and the biggest jump, for the lab and the tests |
| `src/shared/Combat/LagCompensation.luau` | Server history, rewind time with the cap, rewound targets |
| `src/shared/Combat/ShotResolver.luau` | Skips targets whose bounding sphere is off the ray (`nearRay`) |
| `src/shared/Combat/Hitboxes.luau` | `region`, `boxFraction` and `boxPoint` for confirms pinned to a box |
| `src/shared/Net/PlayerCodec.luau` | Snapshots carry a sequence number |
| `src/server/Replication.luau` | A snapshot of the paced poses on each frame `SendSchedule` picks, quantised before anything sees it |
| `src/server/CombatServer.luau` | Rewinds, resolves and sends the detailed verdict |
| `src/server/PlayerSimServer.luau` | One input per player per round, so shots resolve in tick order; paces each player's moves |
| `src/server/Dummies.luau` | Ticks the dummies on the server's clock and paces them |
| `src/server/init.server.luau` | Dummies, players and the snapshot all work to the frame's server time |
| `src/server/Tuning.luau` | `maxRewind` is tunable live (Studio or the place owner) |
| `src/client/NetSim.luau` | Simulated latency, jitter and loss for this client's gameplay messages |
| `src/client/RemoteEntities.luau` | Histories, the render clock, snapshot counts, Network Buffering, a `MotionMeter` per entity; draws dummies and other players as their hitboxes and hides other players' avatars |
| `src/client/PlayerController.luau` | `viewTime` from the frame on screen; round trip from input to ack |
| `src/client/Combat/ClientShots.luau` | The client's trace, the verdict, what each side tested and why they differ |
| `src/client/Combat/WeaponEffects.luau` | Predicted spark at once; confirm pinned to the box hit |
| `src/client/Debug/HitRegLab.luau` | The Hit Reg Lab (below) |
| `src/client/Debug/HitboxOverlay.luau` | Client and server boxes per shot |
| `tests/hitreg.luau` | Offline tests and the simulated network |
| `tests/pacing.luau` | `MovePacer` and `MotionMeter`, and a simulated network that measures how evenly a player and a dummy are drawn |

## 7. Debug tools

| Key | Tool |
| --- | --- |
| F2 (third press) | Hit Reg Lab: the rewind cap against Riot's 140 / 200 ms; the round trip from input to ack against Riot's "20-30 ms over network RTT"; snapshots per second, lost and late, the render delay and how often a frame held a pose, Network Buffering against the reference's 7.8 / 23.4 / 39.1 ms; the motion of the player or dummy nearest the crosshair (within 10 degrees): its speed, slowest and fastest over the last second, and the biggest jump, green under 0.5 m/s, against Riot's "The other nine players continue to see smooth movement"; rewind last, mean and max, shots capped, and the round trip at which shots start to hit the cap; client and server agreement on all shots and on moving targets, with the reasons when they differ; shot to hit confirm against one round trip; peeker's advantage by Riot's formula against 40-70 ms |
| `[` / `]` (lab open) | Simulated latency down / up 10 ms each way (0-150 ms) |
| J / L / U / K (lab open) | Jitter 0, 5, 15 ms; loss 0, 2, 5%; Network Buffering Minimum, Moderate, Maximum (U, which was B until the buy menu took it); rewind cap 140 ms, 200 ms, 0 for no lag compensation (Studio or place owner) |
| F10 | Hitbox overlay: per shot, the client's boxes and end point in yellow; when the verdict comes, the server's end point in blue, the client's boxes turn white where the server tested the same pose, the server's are drawn in blue where it didn't, and a label gives the rewind (CAPPED when the cap moved it) and the reason for any difference; the ray turns red |
| F2 (first press) | The weapon lab's shot log now shows each shot's rewind (`!` when capped) and the reason for a DIFF |
| F3 | The HUD shows the round trip, and the simulated latency in red when it's on |
| Backspace | Clear the counters, the shot log and impact marks |

## 8. Refinement loop

1. In Studio with the lab open, shoot the strafing dummies at 0, 40, 80 and 120 ms of simulated
   round trip (`]` adds 10 ms each way), with J and L at their middle settings too. Agreement
   should stay at about 100% until the cap; every DIFF names its reason in the shot log.
2. Set the cap to 0 (K twice) and repeat at 80 ms, with uneven gaps between shots: agreement on
   the moving strafer should fall to about a quarter for body shots and a fifth for head shots,
   which shows what the rewind is doing. At Studio's own ping it hardly falls for body shots
   (section 4).
3. With two players in Studio (Test tab, Clients and Servers, 2 players) and F10 on, shoot one
   strafing past cover and check the white boxes sit where the target was drawn.
4. In the same test, one player runs along the sprint lane while the other aims at them with the
   lab open: the motion line should read 5.40 m/s, 5.40-5.40 over the last second, and a biggest
   jump under 0.5 (the newest pose gave 1-2.5 m/s). Aimed at a strafing dummy, the jump should
   stay under 0.5 too.
5. Measure the reference's hit confirm delay and behind-cover window (section 3); compare with the
   lab's confirm delay and rewind at the same round trip.
6. If shooters around 100-125 ms of round trip should still land moving shots, as they do in the
   reference, try `NetConfig.maxRewind` at 0.17 and judge being hit behind cover against it.
7. Re-run `luau tests/run.luau` and update the tables in section 4.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- The render clock settles on Roblox's real snapshot timing (the lab's "held a pose" should stay
  near 0% with no simulated loss), and Roblox doesn't bunch several snapshots into one frame
  often enough to need a bigger delay.
- Shots in the first seconds after joining are rewound as little as later ones, and Studio's
  snapshots come at 60 a second.
- `viewTime` is read before the remote entities move each frame (render priorities
  Camera + 1 for the player, Camera + 2 for remote entities, First for NetSim).
- Hit confirms stay on the body part as the target moves, and go when it dies (it leaves the
  snapshots).
- Agreement is about 100% against the strafing dummies with no simulated latency, and the
  overlay's white boxes match the dummies.
- With Roblox's real frame and packet timing, pacing keeps others smooth: the motion line reads a
  biggest jump under 0.5 m/s on another player running steadily (5.40-5.40) and on the strafing
  dummies.

The [Studio test session](../studio-checklist.md) walks through these, with what to expect.
