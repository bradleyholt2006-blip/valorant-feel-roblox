# System 35: The fog of war

Until now every client was sent every other player's pose sixty times a second, wherever they were,
so a client that read its snapshots could see everyone through every wall: the wallhack Riot's fog
of war is built against. This system keeps from each player the enemies they can't see or hear.
Twenty times a second the server looks from each player's eye to each enemy, through the level, and
an enemy is in that player's snapshots while a look finds a line to their body, or hears them, or
their side spots them on the minimap, and for half a second after. Both are carried ahead along
their velocities, so an enemy is sent just before they come round the corner, whoever's moving.
Whatever else says where someone is goes the same way: a gunshot, a knife's swing or an ability's
cast is told only to those who'd hear it or have whoever made it, and a shot's verdict lists only
the targets its shooter has.

As before, everything comes from public sources: Riot's tech blog on the fog of war, Riot's audio
director in Ask VALORANT #6 and a Riot developer's reply on Reddit as GINX copies it; then GINX and
mein-mmo.de on what's sent and what enemies hear. No game files, memory or network traffic were
used, and nothing was read from the live game. Riot says how its system works and what went wrong on
the way, but gives no numbers: how far ahead it looks, how long an enemy stays sent and how often it
checks are ours. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes, support pages, tech blog or a developer's post) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **Nothing behind walls** (Riot). "Cheaters use wallhacks to see opponents through walls." The
  reference's answer is that "the game server withholds information about the positions of enemies
  until a client needs to display it", so a player holding an angle stays hidden: "we wouldn't send
  their location to enemy players, keeping them hidden until they decided to peek the angle". An
  actor that stops being relevant to a player is marked "invisible and intangible" on their client
  "and eventually" despawned; once it's relevant again it's spawned "(if necessary)", made visible
  with its collision back, and the client is caught up "on any updates they had missed".
- **No pop-in** (Riot, and a streamer GINX quotes). One ray to an actor's centre gave "a massive pop
  in effect as an enemy peeked a corner", "a new extreme form of peeker's advantage". Expanding "the
  actor's bounding box by the actor's velocity multiplied by a "look ahead" time", "bigger than the
  expected ping time", fixed it: "sending the information to a player just before the enemy came
  around the corner." The streamer: it "doesn't even render player locations until just before line
  of sight happens."
- **Optimistic** (Riot). The checks should remove only what they're "positive" won't be needed.
  Raycasts were "fundamentally too pessimistic", and in playtests "actors would pop in or remain
  invisible indefinitely"; so the reference moved to a Potentially Visible Set, which works out
  ahead of time which parts of the map see which, "visible" "As long as any part of a voxel can see
  any part of the other voxel".
- **Heard** (a Riot developer's post as GINX copies it, and Riot). "There's an audio component to
  the Fog of War system where if you can hear an enemy" "that can trigger the location being sent to
  you." "Footsteps are a special case though and are handled through a different system" "to try and
  make them as accurate and secure as possible." The blog: "I had to tie in the audio system".
- **What's heard** (Ask VALORANT #6 and mein-mmo.de). "The footstep radius is set up to give players
  who hear enemy footsteps time to use an ability and re-equip a weapon" "before they are in
  danger", with "an attenuation curve that is somewhat flat". In mein-mmo.de's account running is
  heard and walking with Shift isn't, a reload is "gut hörbar", a jump is loud on your own level or
  down but not up onto a box, a weapon switch is silent, and a plant, a defuse or a gun dropped is
  loud.
- **Cost** (Riot). "it'd be really hard to justify thousands of raycasts every tick when we're
  committed to 128 tick servers"; at first "Frame times were doubled", then "the system started
  assuming that relevant actors stay relevant for a small amount of time", and "Today, the Fog of
  War system takes up less than 2% of server frame time (down from 50% in our first prototype)."

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "the game server withholds information about the positions of enemies until a client needs to display it"; "network relevancy that can be used to limit network updates and even despawn non-relevant actors"; "Agents, weapons, and abilities are all examples of network actors." | Riot's tech blog, [Demolishing Wallhacks with VALORANT's Fog of War](https://technology.riotgames.com/node/108) |
| A check "Every time the server wanted to send a network update (usually once each tick)". Failed: "we'd mark the actor as not relevant and stop sending network updates", and "the server sent a message to that player to mark the not relevant actor as invisible and intangible" "and eventually despawn them". Passed: "send the usual updates and catch them up on any updates they had missed" | The same |
| The first prototype "cast a single ray from the player's camera location towards the center of an actor", which failed when "a door, ledge, or corner obscured the midpoint of the actor": "a massive pop in effect as an enemy peeked a corner". Then ten rays, "one for each corner of the actor's bounding box, one to the actor's camera location, and one to the center"; but "it'd be really hard to justify thousands of raycasts every tick when we're committed to 128 tick servers." | The same |
| "expanding the actor's bounding box by the actor's velocity multiplied by a "look ahead" time" "which was bigger than the expected ping time"; "This prevented pop-in effects by sending the information to a player just before the enemy came around the corner." | The same |
| The checks were "still fundamentally too pessimistic"; "During playtests, actors would pop in or remain invisible indefinitely."; "Both need optimistic results"; "Potentially Visible Sets (PVS)", which "pre-computes which parts of a scene (our map) can see which other parts": "As long as any part of a voxel can see any part of the other voxel, the table returns "visible"." | The same |
| "Frame times were doubled"; "the system started assuming that relevant actors stay relevant for a small amount of time"; "less than 2% of server frame time (down from 50% in our first prototype)"; "I had to tie in the audio system" | The same |
| A Riot developer on Reddit: "There's an audio component to the Fog of War system where if you can hear an enemy" "that can trigger the location being sent to you."; "Footsteps are a special case though and are handled through a different system" "to try and make them as accurate and secure as possible." | [GINX's copy](https://www.ginx.tv/en/valorant-anti-cheat-protection-sports-fog-of-war-system-to-combat-wallhacks), 1 April 2020 |
| "The footstep radius is set up to give players who hear enemy footsteps time to use an ability and re-equip a weapon" "before they are in danger."; "We optimize for making sure footsteps are heard, as opposed to optimizing for portraying distance."; "an attenuation curve that is somewhat flat" | Riot's audio director in [Ask VALORANT #6](https://playvalorant.com/en-us/news/game-updates/ask-valorant-6/), 27 August 2020 |

### From the community

| What | Source |
| --- | --- |
| A streamer: "[The system] doesn't even render player locations until just before line of sight happens." | [GINX](https://www.ginx.tv/en/valorant-anti-cheat-protection-sports-fog-of-war-system-to-combat-wallhacks) |
| Running is heard ("Denn wer rennt, wird gehört. Punkt."), walking with Shift and switching weapons aren't; a reload is "gut hörbar"; a jump is loud only on your own level or down; planting or defusing the spike, and dropping a gun, are loud; an ultimate's line is heard across the map, other abilities' lines aren't | [mein-mmo.de](https://mein-mmo.de/en/valorant-what-can-the-opposing-team-hear-and-what-cant-they,495584), 20 April 2020 |

No source says how far ahead the reference looks, how long a relevant actor stays relevant, how
often it checks now it uses its sets, or how big a cell is; whether a smoke hides anyone from it (a
set worked out ahead of time can't know where a smoke is, so we read it as not); how teammates, the
dead, spectators or the minimap are handled; or what the "different system" for footsteps does. Ours
are in section 4. Riot says it tied the audio in; which sounds count and how far they reach are
ours, from this game's own sound ranges (system 8).

## 3. What can be measured, and how

| What | How |
| --- | --- |
| Whether the reference ever pops an enemy in | Clips of peeks at a known ping, both players' views, stepped frame by frame from the first frame the peeker could be seen |
| How early ours sends an enemy before they're in sight | The tests' corner peeks (`tests/fogofwar.luau`), and Studio with 100 ms added each way (FW3) |
| What ours costs | `VFFogLines` and `VFFogMs` with two, three and more players, still and moving, behind cover and in the open |
| How short the hold and the recheck can be | How often anyone pops in, in Studio and in playtests, as they're shortened |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| What's kept back | An enemy left out of a player's snapshots isn't drawn, heard or hit by their client's guess at a shot, and their name, health and minimap dot go with them | Confirmed (positions withheld; the actor invisible and intangible) |
| Always sent | Yourself, your side, practice dummies and anyone on no side; a player on no side (on the course, or waiting in line, who may watch anyone) has everyone | Estimate (Riot's blog speaks of enemies only) |
| Seen | A line from the viewer's eye to any of seven points of the enemy's body (the top of the head, the middles of the body and the legs, and 0.26 m to either side of the head's top and the body's middle, across the line) that only the level cuts: not a cloud, a wall of fire, a body or the spawns' barriers, and not the view's edge | Confirmed (rays to a body's box, camera and middle, then sets worked out from the map alone, optimistic); estimate (the points) |
| Carried ahead | The body, and where its velocity takes it in 0.1 s (to the next look and 0.05 s more); the eye, and where the viewer's velocity takes it in how far their screen is behind the server (0.25 s at the most) and that 0.1 s, stood up if they're crouched | Confirmed (velocity times a look-ahead bigger than the ping); estimate (the values, and the eye's part) |
| How often | Each player looks 20 times a second, the players' looks spread over the frames between. An enemy already sent is looked at again every 0.25 s, first along the line that saw them last; one hidden, once either has moved 0.05 m or changed velocity by 0.05 m/s, or after 1 s | Confirmed (a check with each update); estimate (the values) |
| Held | 0.5 s after the last look that saw, heard or had them spotted | Confirmed (relevant actors stay relevant a while); estimate (0.5 s) |
| Heard | Within where the sound goes silent, plus 2 m: their steps as they run along the ground (0.5 m/s and up, not walking), or while they're in the air (a landing to come), 20 m; a reload, 15 m; a plant or a defuse, 60 m; a glide, 30 m. Steps go through the same check as the rest | Confirmed (an audio component; footsteps a system of their own); community (running and reloads heard, walking not, mein-mmo.de); estimate (the ranges, this game's own, system 8; the 2 m; steps here) |
| Spotted | Whoever your side spots on the minimap (system 34) | Estimate |
| Down | A player who's down has what their side in play has, so whoever they watch is drawn as that teammate has them | Estimate |
| Deathmatch's pulse | Everyone, for 0.3 s as you come back to life; the pulse marks each as they arrive | Community (the pulse, the VALORANT Wiki); estimate (0.3 s) |
| Events | A gunshot goes to those within 200 m of it (a suppressed gun's, 70 m), a knife's swing 12 m and an ability's cast 30 m, each plus 2 m, or who have whoever made it; Run it Back's mark and rising go to everyone | Estimate (the ranges, this game's own) |
| Verdicts | A shot or a swing is checked against everyone, sent or not, but its verdict lists only the targets near it its shooter has, and any it hit | Estimate |
| Labels | An enemy's name and health show only where nothing's in the way; a teammate's show through walls | Estimate |
| Roots | A character's root stays where its life began, not where they are | Estimate (a Roblox matter) |

## 5. Design

### The rules

- **`FogOfWar`** (new) is who's in whose snapshots, with no Roblox APIs: `always` (who's always
  sent), `points` (a body's seven), `eyes` and `bodies` (each carried ahead), `sees` (the lines, the
  last one that saw tried first), `hears` (the sounds), `look` (one player's look at everyone, with
  the hold, the recheck and the looks it skips), `shows` and `anyShows` (whether a player, or any of
  a side, has someone) and `forget`. `Edges` and `weaponEdge` are where each sound goes silent, from
  `SoundConfig`'s curves. The level comes in as `blocked`, so the tests run it on a fake one.

### The server

- **`FogServer`** (new) takes the looks that are due each frame: from where the server has each
  player's eye (`PlayerSimServer.view`), with their velocity and how far behind the server their
  screen is (`PlayerSimServer.behind`), at every entity where the snapshots have it (`Entities`).
  The level is a raycast that passes the barriers, as the minimap's is. `sendsTo` is what a player's
  snapshots carry, `shows` whether someone's in them and `hears` whether an event goes to them.
  Deathmatch's reveal comes from `PlayerSimServer`'s spawn listeners, and what the looks cost goes
  on Workspace once a second.
- **`Replication`** sends each player their own snapshot: the frame's poses that `sendsTo` lets
  through, encoded once for each set of them. Its listeners (lag compensation) still get every pose,
  so a shot is checked against everyone.
- **`CombatServer`** lists in a verdict only the targets near it the shooter has, and the one it
  hit, and sends `ShotFx` and `SwingFx` by `hears`.
- **`AbilityServer`** and **`RunItBackServer`** send each cast by `hears`, but Run it Back's mark
  and rising to everyone, since the mark's drawn for all.
- **`MinimapServer`** hands what each side spots to the fog.
- **`PlayerSimServer`** keeps how far behind each player's screen is, and puts a character's root
  where its life starts and leaves it there: moved with them, it would tell every client where they
  are. **`Arena`**'s health packs are models that stream to everyone, as the root they'd stream
  around no longer moves.
- **`init.server`** steps the fog after the minimap's look and before the snapshot.

### The client

- **`RemoteEntities`**: an enemy's label no longer shows through walls. As before, an entity not in
  the newest snapshot isn't drawn and the client's guess at a shot passes it.
- **`MinimapView`**: deathmatch's pulse marks each player as they arrive in the moment after you're
  back, since until then they weren't sent.
- **`HitboxOverlay`** (F3): on a live server, an enemy's boxes aren't drawn through walls.

### Not here yet

- **Utility.** The flights of Cloudburst, Curveball, Hot Hands and Blaze, and the clouds, walls and
  fires they leave, still go to every client, each flight from where it was thrown; the minimap
  shows every cloud and wall (system 34), and the `VFLast…` attributes say where each player's last
  landed. Their casts go only to those who'd hear them, and Blade Storm's knives are shots, so they
  go as shots do. The reference counts abilities among the actors its fog hides.
- **Where each life starts.** A life's start goes to everyone: the character's `VFSpawnFeet`
  attribute and its root, put there.
- **The spike.** Workspace's spike attributes say who carries it and where it lies dropped, to
  everyone; the minimap shows them only as its rules say (system 34).
- **Footsteps.** The reference handles them in a system of their own; here they're one more sound
  that sends an enemy.
- **Clouds and walls of fire** hide nobody from the fog, as a map's sets can't, so an enemy in a
  cloud is sent to whoever has a line to them; on screen the cloud hides them.
- **Pessimism.** Raycasts can miss a body seen through a gap between the seven points; the points,
  the look ahead and the hold keep that rare, but it's measured only by playing.
- **Spectators.** A spectator of the whole match (a coach, an observer) isn't here; a player on no
  side has everyone.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Combat/FogOfWar.luau` | New: who's in whose snapshots, and the numbers with their status and source |
| `src/server/FogServer.luau` | New: the looks each frame, what each player's snapshots carry, who hears an event, and the cost |
| `src/server/Replication.luau` | Each player's own snapshot |
| `src/server/CombatServer.luau` | The verdicts' targets, and `ShotFx` and `SwingFx` by who hears them |
| `src/server/AbilityServer.luau`, `src/server/RunItBackServer.luau` | Casts by who hears them |
| `src/server/MinimapServer.luau` | Each side's spotting handed on |
| `src/server/PlayerSimServer.luau` | `behind`, and the root left where a life starts |
| `src/server/Arena.luau` | Health packs that stream to everyone |
| `src/server/init.server.luau` | `FogServer` started, and stepped before the snapshot |
| `src/client/RemoteEntities.luau` | Enemies' labels not through walls |
| `src/client/MinimapView.luau` | Deathmatch's pulse as each arrives |
| `src/client/Debug/HitboxOverlay.luau` | Enemies' boxes not through walls on a live server |
| `tests/fogofwar.luau` | New: who's always sent, the points, the eyes and bodies carried ahead, the lines, the corner peeks, hearing, the hold, the recheck, the looks skipped, the dead and forgetting |

## 7. Debug tools

- Workspace's `VFFogOff`, set true on the server, turns the fog off: everyone's snapshots carry
  everyone, to compare.
- Workspace's `VFFogLines` and `VFFogMs`, set by the server once a second, are what its looks cost
  in the last second: the lines they cast, and the milliseconds of server time they took (10 is 1%
  of it).
- A client's `Workspace.VFPlayers` holds a model for each player in its snapshots, named as the
  player is, so in a Local Server the client's Explorer shows who's been sent.

## 8. Refinement loop

1. Step through clips of peeks at known pings, and shorten `ahead`, `hold` and `recheck` as far as
   nothing pops in.
2. Read `VFFogLines` and `VFFogMs` with full servers, and set `every`, `still` and `stale`.
3. Compare who's heard against the white circle (system 34) as sounds are tuned (system 8), and
   settle `hearing`.
4. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- On the course, everyone sent to everyone.
- An enemy behind cover not sent, and one stepping out drawn from their first frame, at no ping and
  at 100 ms each way.
- An enemy heard running, reloading or jumping behind cover sent, and not walking; out of earshot on
  a spike map not sent, though their shots are heard.
- A knife swung behind cover heard only near it.
- Teammates always sent, and an enemy a teammate spots sent too.
- The dead seeing what their side does, watching a teammate.
- Enemies' labels not through walls, teammates' through them.
- Deathmatch's pulse showing everyone as you're back.
- `VFFogOff` sending everyone; the cost in `VFFogLines` and `VFFogMs`.
- A character's root staying where they spawned on the server, nothing else changed.

Section 39 of the [Studio checklist](../studio-checklist.md) covers these.
