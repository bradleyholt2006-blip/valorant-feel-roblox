# System 4: Hit registration and lag compensation

This covers how the server decides what a shot hit when the shooter, the target and the server
are each looking at a slightly different moment: how other players are drawn (interpolation and
the render clock), what time each shot carries, how the server rewinds targets to what the shooter
saw and how far it is willing to go (the rewind cap), how hits are shown (a client-predicted spark
at once, the server's confirm a round trip later), and the tools that check the client and the
server agree. How a shot is traced and damaged is system 2; where the bullet goes is system 3. Wall
penetration is a possible later system.

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
- Once a lethal shot is processed, the victim's later shots don't count, even if they fired on
  their own screen at about the same moment.

## 2. Publicly documented details

How it works (Riot):

| Fact | Status | Source |
| --- | --- | --- |
| "Hit registration in VALORANT works by saving player positions and animation state in a historical buffer. When the server receives a shot packet from the client, it rewinds the player positions and animation state using the historical buffer" | Confirmed | [VALORANT's 128-Tick Servers](https://technology.riotgames.com/node/112) |
| Server hitboxes follow server-side animation, which runs every 4th frame: "In the event of a rewind we could lerp between the saved animations" | Confirmed | Same article |
| Clients "send up exactly what time in the simulation they were looking at when firing a shot"; "In reasonable networking conditions, this allows for near-perfect hit registration" | Confirmed | [Peeking into VALORANT's Netcode](https://technology.riotgames.com/node/111) |
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
| Rewind cap | 140 ms (200 ms and off one key away in the Hit Reg Lab) | Confirmed (Patch 6.02) |
| The server rewinds to the time on the shooter's screen | yes | Confirmed |
| A dead player's later shots are rejected | yes | Confirmed |
| Spark at once, server confirm on the body part and moving with it | yes | Confirmed (Patch 1.07) |
| Hit confirm size and lifetime | 7 cm head, 8 cm body, 0.35 s | Estimate (smaller for heads is confirmed) |
| Network Buffering | +0, +15.6, +31.25 ms over our minimum | Confirmed steps (Riot: 1, 3 and 5 frames) |
| Snapshot rate | 60 Hz, every server frame | Roblox's frame rate (the reference: 128 Hz) |
| Render delay | measured: the 98th percentile of how late snapshots arrive, plus one send interval, plus 2 ms | Estimate (the reference: a fixed 7.8125 ms) |
| Render clock correction | at most 10% faster or slower; jumps only when more than 0.25 s off | Estimate |
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
| The same, no lag compensation | 30.1% | 30.1% | 0 | 0 | 0% |
| The same, 3% of snapshots lost | 100% | 99.7% | 124 / 133 ms | 0 | 1.6% |
| 75 ms each way (past the cap) | 52.9% | 52.9% | 140 / 140 ms | all | 0% |
| 40 ms each way, the old fixed 50 ms delay | 99.7% | 95.2% | 106 / 115 ms | 0 | 44.9% |

The render clock on its own: 40 ms each way gives a delay of 24.2 ms and no starved frames; with
0-8 ms of jitter, 30.3 ms and none; a jump from 40 to 100 ms settles within 2 s without the
entities ever moving backwards.

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
  everyone. The clock eases toward its target at up to 10% faster or slower than real time and
  never runs backwards, so a change in latency never makes anyone jitter.
- **Rewind and the cap.** The server rebuilds every other living entity at `viewTime` clamped to
  between 140 ms ago and now (a time from the future is checked at now). A shooter whose view is
  older than the cap is checked against the world at the cap, so they start to miss moving targets
  instead of hitting players who have already reached cover. The shooter and dead or unspawned
  entities are left out.
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
- **No hitbox animation.** The reference animates server hitboxes (every 4th frame, lerped on a
  rewind). Ours are boxes rebuilt from position, yaw and crouch, which makes the rewind exact but
  means a running or crouching character's limbs don't move their boxes.
- **No penetration.** Shots stop at the first level geometry; each weapon's penetration class is
  recorded for a later system.
- **Ping in Studio is close to zero.** Hence the simulated network. Real packet loss on Roblox's
  reliable channel shows up as extra delay (resends), which `NetSim` doesn't model.

## 6. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Net/NetConfig.luau` | The cap, render clock and buffering numbers, and the reference values the lab compares with, each with status and source |
| `src/shared/Net/PoseHistory.luau` | Pose history and the one interpolation rule both sides use |
| `src/shared/Net/InterpClock.luau` | The render clock: delay measured from snapshot arrivals, eased, never backwards |
| `src/shared/Combat/LagCompensation.luau` | Server history, rewind time with the cap, rewound targets |
| `src/shared/Combat/ShotResolver.luau` | Skips targets whose bounding sphere is off the ray (`nearRay`) |
| `src/shared/Combat/Hitboxes.luau` | `region`, `boxFraction` and `boxPoint` for confirms pinned to a box |
| `src/shared/Net/PlayerCodec.luau` | Snapshots carry a sequence number |
| `src/server/Replication.luau` | A snapshot every server frame, quantised before anything sees it |
| `src/server/CombatServer.luau` | Rewinds, resolves and sends the detailed verdict |
| `src/server/PlayerSimServer.luau` | One input per player per round, so shots resolve in tick order |
| `src/server/Tuning.luau` | `maxRewind` is tunable live (Studio or the place owner) |
| `src/client/NetSim.luau` | Simulated latency, jitter and loss for this client's gameplay messages |
| `src/client/RemoteEntities.luau` | Histories, the render clock, snapshot counts, Network Buffering |
| `src/client/PlayerController.luau` | `viewTime` from the frame on screen; round trip from input to ack |
| `src/client/Combat/ClientShots.luau` | The client's trace, the verdict, what each side tested and why they differ |
| `src/client/Combat/WeaponEffects.luau` | Predicted spark at once; confirm pinned to the box hit |
| `src/client/Debug/HitRegLab.luau` | The Hit Reg Lab (below) |
| `src/client/Debug/HitboxOverlay.luau` | Client and server boxes per shot |
| `tests/hitreg.luau` | Offline tests and the simulated network |

## 7. Debug tools

| Key | Tool |
| --- | --- |
| F2 (third press) | Hit Reg Lab: the rewind cap against Riot's 140 / 200 ms; the round trip from input to ack against Riot's "20-30 ms over network RTT"; snapshots per second, lost and late, the render delay and how often a frame held a pose, Network Buffering against the reference's 7.8 / 23.4 / 39.1 ms; rewind last, mean and max, shots capped, and the round trip at which shots start to hit the cap; client and server agreement on all shots and on moving targets, with the reasons when they differ; shot to hit confirm against one round trip; peeker's advantage by Riot's formula against 40-70 ms |
| `[` / `]` (lab open) | Simulated latency down / up 10 ms each way (0-150 ms) |
| J / L / B / K (lab open) | Jitter 0, 5, 15 ms; loss 0, 2, 5%; Network Buffering Minimum, Moderate, Maximum; rewind cap 140 ms, 200 ms, off (Studio or place owner) |
| F10 | Hitbox overlay: per shot, the client's boxes and end point in yellow; when the verdict comes, the server's end point in blue, the client's boxes turn white where the server tested the same pose, the server's are drawn in blue where it didn't, and a label gives the rewind (CAPPED when the cap moved it) and the reason for any difference; the ray turns red |
| F2 (first press) | The weapon lab's shot log now shows each shot's rewind (`!` when capped) and the reason for a DIFF |
| F3 | The HUD shows the round trip, and the simulated latency in red when it's on |
| Backspace | Clear the counters, the shot log and impact marks |

## 8. Refinement loop

1. In Studio with the lab open, shoot the strafing dummies at 0, 40, 80 and 120 ms of simulated
   round trip (`]` adds 10 ms each way), with J and L at their middle settings too. Agreement
   should stay at about 100% until the cap; every DIFF names its reason in the shot log.
2. Turn the cap off (K twice) and repeat at 80 ms: agreement on the strafers should fall to
   around a third, which shows what the rewind is doing.
3. With two players in Studio (Test tab, Clients and Servers, 2 players) and F10 on, shoot one
   strafing past cover and check the white boxes sit where the target was drawn.
4. Measure the reference's hit confirm delay and behind-cover window (section 3); compare with the
   lab's confirm delay and rewind at the same round trip.
5. If shooters around 100-125 ms of round trip should still land moving shots, as they do in the
   reference, try `NetConfig.maxRewind` at 0.17 and judge being hit behind cover against it.
6. Re-run `luau tests/run.luau` and update the tables in section 4.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- The render clock settles on Roblox's real snapshot timing (the lab's "held a pose" should stay
  near 0% with no simulated loss), and Roblox doesn't bunch several snapshots into one frame
  often enough to need a bigger delay.
- `viewTime` is read before the remote entities move each frame (render priorities
  Camera + 1 for the player, Camera + 2 for remote entities, First for NetSim).
- Hit confirms stay on the body part as the target moves, and go when it dies (it leaves the
  snapshots).
- Agreement is about 100% against the strafing dummies with no simulated latency, and the
  overlay's white boxes match the dummies.
