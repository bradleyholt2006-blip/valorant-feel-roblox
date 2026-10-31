# System 76: bots shoot enemy utility

Bots now shoot an enemy's utility when they see it, as guides tell players to: a Recon Bolt stuck in
the level, an Owl Drone in flight and Reyna's Leer eye. Each is noticed and aimed at as an enemy is,
after the bot's reaction and a turn timed for the piece's size, and fired at as its range calls for
until it breaks, its bullets striking it as a player's do. An enemy always comes first: a bot shoots
utility only while it has noticed no enemy, nor lost sight of one a moment ago, and it turns from
the utility to an enemy as soon as it notices one. Leer's eye now also shows through the nearsight
it gives: a player it's nearsighting still sees it, drawn just inside the dark round their screen,
and can shoot it, as the guides have players do. Bots see it the same way. This system also corrects
the Studio checklist's text where Empress's run there found it wrong (section 5).

As before, everything comes from public sources: Riot's page on Sova and its patch notes 4.08
and 5.12, read for systems 44 and 47; guides by Dignitas, Mobalytics, EarlyGame and THESPIKE.GG;
and, for the eye's health, the guides read for system 74. No game files, memory or network traffic
were used, nothing was read from the live game, and no Riot asset or sound is used. Riot says that
enemies can destroy the bolt and the drone, gives the health of each, and says that allies' damage
does nothing to them. The guides say that players shoot each one on sight, that the quickest shoot
the eye at once, that the eye takes a few shots, and that shooting it takes a player's crosshair off
their enemies. Counter-Strike has nothing like this to shoot, so its bot is no guide here: when a
bot shoots utility, and how it weighs utility against an enemy, are ours. How fast each skill breaks
each piece is measured offline, our bots against our own utility (section 3). Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's page on Sova and its patch notes) |
| **Community** | Published by a guide, not by the maker (Dignitas, Mobalytics, EarlyGame, THESPIKE.GG, and system 74's guides for the eye) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Run offline in our own tests (`tests/botthings.luau`), our bots against our own utility |

## 1. Observable behaviour

- **The Recon Bolt, shot on sight** (Dignitas, Mobalytics). Dignitas: "A player with quick reaction
  times can look at a Recon Bolt on the ground and shoot it" "before Sova learns anything about
  their positioning". Mobalytics: "If they're fast enough, they can destroy it before it tags
  them.", and "Good players will wait it out and then press forward or shoot it to fake that they're
  coming and rotate away."
- **The Owl Drone, shot down** (EarlyGame, Dignitas, THESPIKE.GG). EarlyGame: "shoot down the drone
  on sight". Dignitas tells Sova players to "place your recon-gathering tools in places where
  they're not going to get immediately shot down", as "the enemy team can destroy your remote
  abilities before they have a chance to give you information". THESPIKE.GG: "Owl Drone can be
  pretty easy for enemies to destroy".
- **Leer's eye, shot while it nearsights** (Dignitas). "The strongest, and maybe only way to play
  against Leer is literally just to shoot it." "But, at the higher levels, you need to be shooting
  the eye as soon as it leaves her hand." "The eyeball takes a few shots to kill." It "completely
  obscures vision from the enemy team until it's killed.", and "all that enemy players are going to
  have to do upon seeing the eyeball spawn is simply kill it". Reyna players are told: "So place the
  eyeball either high up or down on the ground.", and to "place the flash in a position where the
  enemy has to take their crosshair far away in order to shoot it."
- **What it costs the shooter** (Dignitas). "she can make you shoot the eyeball and take your
  crosshair off."; "Once the Leer appears, you can have one player fire shots into the eyeball while
  the other aims".
- **What breaks each one** (Riot, from systems 44, 47 and 74). Riot: "Enemies can destroy this
  bolt." and "Enemies can destroy the Owl Drone." Patch 5.12: "Recon Bolt (E) Health
  increased 1 >>> 20", and "The following abilities are now immune to allied damage.", the bolt and
  the drone among them. Patch 4.08 gives the drone "Health reduced 125 >>> 100". The eye's 100
  health is from the guides (74-leer.md).

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "EQUIP a bow with recon bolt. FIRE to send the recon bolt forward, activating upon collision and" "Revealing the location of nearby enemies caught in the line of sight of the bolt." "Enemies can destroy this bolt." | [playvalorant.com, Sova](https://playvalorant.com/en-us/agents/sova/), read for system 44 |
| "Enemies can destroy the Owl Drone.", in Riot's text as THESPIKE.GG gives it | [THESPIKE.GG, Sova](https://www.thespike.gg/valorant/agents/sova), read for system 47 |
| Owl Drone "Health reduced 125 >>> 100" | [VALORANT Patch Notes 4.08](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-4-08/), 27 April 2022, read for system 47 |
| "Recon Bolt (E) Health increased 1 >>> 20"; "The following abilities are now immune to allied damage.", the Owl Drone and the Recon Bolt among them | [VALORANT Patch Notes 5.12](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-5-12/), 6 December 2022, read for systems 44 and 47 |

### From the community

| What | Source |
| --- | --- |
| "A player with quick reaction times can look at a Recon Bolt on the ground and shoot it"; "before Sova learns anything about their positioning"; "place your recon-gathering tools in places where they're not going to get immediately shot down"; "the enemy team can destroy your remote abilities before they have a chance to give you information" | Michael Kelly, [A Guide to Mastering Sova by Pro Player Psalm](https://dignitas.gg/articles/news/Unknown/14785/a-guide-to-mastering-sova-by-pro-player-psalm-valorant-agent-guide), Dignitas, 17 October 2020 |
| "The strongest, and maybe only way to play against Leer is literally just to shoot it."; "But, at the higher levels, you need to be shooting the eye as soon as it leaves her hand."; "The eyeball takes a few shots to kill."; "Only one weapon in the game, the Operator, is able to take it down in one swift shot."; "completely obscures vision from the enemy team until it's killed."; "all that enemy players are going to have to do upon seeing the eyeball spawn is simply kill it"; "she can make you shoot the eyeball and take your crosshair off."; "Once the Leer appears, you can have one player fire shots into the eyeball while the other aims"; "So place the eyeball either high up or down on the ground."; "place the flash in a position where the enemy has to take their crosshair far away in order to shoot it." | Michael Kelly, [A Guide to Mastering Reyna with Pro Player Psalm](https://dignitas.gg/articles/news/Unknown/14970/a-guide-to-mastering-reyna-with-pro-player-psalm-valorant-agent-guide), Dignitas, 11 February 2021 |
| "If they're fast enough, they can destroy it before it tags them."; "Good players will wait it out and then press forward or shoot it to fake that they're coming and rotate away." | [Mobalytics, Sova Valorant agent guide](https://mobalytics.gg/blog/sova-valorant-agent-guide/) |
| "shoot down the drone on sight" | [EarlyGame, Sova guide](https://earlygame.com/valorant/sova-agent-guide-abilities), 1 December 2021, read for system 47 |
| "Owl Drone can be pretty easy for enemies to destroy" | [THESPIKE.GG, Agents of VALORANT: Sova](https://www.thespike.gg/news/agents-of-valorant-sova/95), 14 May 2020, read for system 47 |

No source says how long players take to shoot each piece, which they shoot first, whether they shoot
utility with an enemy in view, or whether the eye can be seen through the nearsight it gives.
Dignitas comes close on the last: the eye obscures vision "until it's killed", and players kill it
once they see it, which can only be done if it still shows to those it's nearsighting. Ours are in
section 4: a bot notices each piece as it would an enemy in the same place, fights an enemy first,
and sees the eye through its nearsight as a player now does.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How soon players shoot each piece | Clips of ranked and pro matches: from a bolt sticking, a drone coming into view or an eye leaving her hand, to the first shot at it, and how often it's broken |
| What comes first | The same clips: what a player does with an enemy and a piece of utility both in view |
| The eye through its nearsight | A custom game with a friend: their Leer looked at from 10 and 20 m, and what's seen of the eye |
| Ours, offline | `tests/botthings.luau`: a bot with a Vandal at each skill, standing on a floor, and a piece of utility at eye height, somewhere within 25 degrees of its view; 12 runs each |

Ours, measured: how many of the 12 runs broke the piece before its time was up, and the median time
from it coming into view to it breaking.

| The piece (its health, the time it had left) | Easy | Normal | Hard | Expert |
| --- | --- | --- | --- | --- |
| Leer's eye, open, 12 m off (100, 2 s) | 1 of 12 | 11 of 12, 1.55 s | 12 of 12, 1.06 s | 12 of 12, 0.73 s |
| A Recon Bolt, 12 m off (20, 3.2 s) | 5 of 12 | 11 of 12, 1.77 s | 12 of 12, 0.88 s | 12 of 12, 0.61 s |
| An Owl Drone hovering, 12 m off (100, 4 s) | 9 of 12, 3.65 s | 12 of 12, 2.00 s | 12 of 12, 1.34 s | 12 of 12, 0.80 s |
| Leer's eye, 20 m off | 0 of 12 | 6 of 12, 1.90 s | 12 of 12, 1.34 s | 12 of 12, 0.81 s |
| A Recon Bolt, 20 m off | 2 of 12 | 6 of 12, 2.93 s | 11 of 12, 1.65 s | 12 of 12, 0.77 s |
| An Owl Drone, 20 m off | 2 of 12 | 10 of 12, 3.23 s | 12 of 12, 2.09 s | 12 of 12, 1.30 s |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| What's shot | An enemy's Recon Bolt once it's stuck, Owl Drone in flight and Leer's eye from the cast; never its own side's, nor its own | Confirmed (enemies destroy the bolt and the drone, allies can't: Riot's page, Patch 5.12); community (the eye) |
| Seen | As an enemy is: near its view, and with neither the level nor a smoke, a wall of fire or a wall of ice in the way of its middle; none at a flash's whitest; past a nearsight's range, only Leer's eye | Estimate |
| Noticed | After its reaction, as an enemy in the same place would be | Estimate (the guides' quickest players shoot it at once) |
| Its aim | Turned onto in the time Fitts's law gives for its size across: 0.2 m for the bolt's shaft, 0.25 m for the drone (its height) and 0.5 m for the eye; never at a head; wandering as on an enemy; and fired at as the range calls for (taps past 22 m, bursts down to 10 m, a spray inside it) until it breaks | Estimate |
| An enemy first | Only while no enemy is noticed, nor one it lost sight of a moment ago, whose last place it watches for 0.7 s first; given up as soon as an enemy's noticed; the nearest piece first | Estimate (shooting the eye takes a player's crosshair off their enemies: Dignitas) |
| Left be | With a knife in hand, and while it plants or defuses the spike | Estimate |
| Not an enemy | Utility isn't in what its side has seen, nor in how long it's been quiet, nor a place where an enemy was, to look into | Estimate |
| A fight | Shooting it counts as a fight for its casts and the spike: a cast under way is given up for it, none starts meanwhile, and it plants or defuses only once it's done | Estimate |
| The eye through its nearsight | A player's screen draws an eye that's past the dark of a nearsight, or a Shade's, just inside the dark, where it looks to be and as big as it looks, unless the level or a smoke hides it; its light stays where it is. Bots see it through a nearsight too | Community (shot while it nearsights: Dignitas); estimate (how it's drawn) |
| How fast | At 12 m, Hard and Expert break an open eye inside its 2 s every time, Normal nearly always and Easy seldom; section 3 has the rest | Measured (offline) |

## 5. Design

### What a bot sees

- **The pieces.** Each look, twenty times a second, the server lists the utility standing
  (`ReconServer.standing`, `DroneServer.flying`, `LeerServer.standing`): what names each one, whose
  it is and their side, where its middle is, and how fast it moves. A bolt's middle is its shaft's,
  a quarter of a metre out of the surface it's stuck in; a drone's is where this frame's snapshot
  shows it, flying as its owner's simulation flies it; an eye's is where it has flown to, at its
  pace while it flies (`LeerSim.velocity`).
- **In the bot's mind.** Each one's shown to its mind (`BotBrain`) as an enemy is, with its middle
  as both its head and its chest, its size across, and an id of its own (negative, below every
  entity's), kept as long as the piece stands.
- **Seen.** As for an enemy: within 75 degrees either side of where it looks, and with nothing in
  the way of its middle (`Sight.hidden`). A flash at its whitest hides every piece, and a nearsight
  hides those past its range, except Leer's eye, a ball of light that shows through it as it does on
  a player's screen. A bot with a knife in hand, or planting or defusing, sees none: it has nothing
  to shoot them with, or its hands are busy.

### What it does

- **Noticed.** After its skill's reaction, longer toward the edge of its view, as for an enemy.
- **An enemy first.** It shoots a piece only while it has noticed no enemy. One it lost sight of a
  moment ago still counts: it watches their last place for 0.7 s, as ever, before turning to the
  piece. It turns from a piece to an enemy as soon as it notices one, and with two pieces in sight
  it shoots the nearer.
- **Its aim.** As on an enemy, but the turn's target is the piece's size, so a bolt's turn is slower
  than an eye's in the same place, and its aim is on the piece's middle, never a head. It doesn't
  know its wander, so its rounds miss a small bolt more often than they miss a body. It fires as the
  range calls for, and keeps firing until the piece breaks, which drops it from the list. Its
  bullets go through `CombatServer` as anyone's do, so a piece breaks only to an enemy.
- **Not an enemy.** A piece seen isn't in what its side has seen, which the plans and the casts work
  from (`BotTeam` and `BotUtility`). It isn't counted in how long the bot's been quiet, as a Healing
  Orb waits for, and isn't a place where an enemy was, to look into after.
- **A knife.** A bot that draws its knife while it's shooting a piece stops, and goes on its way.

### The eye through its nearsight

- **Why.** A nearsight draws a shell of dark round the screen at its range (`ParanoiaView`). Until
  now that hid an eye further off, so a player it nearsighted couldn't see it to shoot, though the
  guides' answer to Leer is to shoot it. Now an eye past the dark is drawn just inside it, at 95% of
  its distance, where it looks to be and shrunk to look as big as it would, with its pupil turned to
  the camera (`LeerView`). It's drawn there only while neither the level nor a smoke hides it,
  through the spawns' barriers as anyone's sight goes. Its light stays where it is, out of view.
- **The shots.** What's drawn changes nothing on the wire or in the server: a shot at the eye where
  it's drawn goes on along the same line to the eye itself, in the level shots are traced through
  (`ClientShots.eyes`, `LeerSim.level`).
- **Bots.** A bot sees an eye through a nearsight in the same way, so a bot it's nearsighting can
  shoot it.

### Fixes from Empress's run in Studio

- **EM8's text.** Player 1's ultimate reads `X2/7` after their death there, not `X0/7`: EM7's kill
  and the death each give a point. And on the course, the points come back as soon as player 1 is
  back in play, not 1.5 s after: the points were spent long before, and they're held back only while
  the frenzy's on. Only the checklist changes.

### Not here yet

- **Looking away.** A player can look away from an eye instead of shooting it; a bot always shoots
  it, the guides' strongest answer.
- **Teamwork.** Dignitas has one player shoot the eye while another watches the angle; each bot here
  does its own.
- **Hearing.** Bots see a drone or a bolt; they don't hear the drone's rotors or the bolt's flight
  and turn to it.
- **Shooting blind.** A bot doesn't shoot at a piece it can't see now, as a player might at where
  they know it is.
- **Sage's walls.** Players shoot through a Barrier Orb's wall to get past it; bots don't shoot
  walls.
- **Ability damage.** Since Patch 5.12, damaging abilities break enemy utility; here only bullets
  and knives do, as before.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Bots/BotBrain.luau` | A target's and a known piece's `size`; `choose` fights an enemy first; the turn and the trigger timed for a piece's size, never at a head; `lastSeen` leaves pieces out |
| `src/server/BotServer.luau` | `things`: the utility standing, each with an id of its own; `look` looks for an enemy's at its middle as for an enemy, the eye through a nearsight, and none with a knife in hand or in a plant or a defuse; pieces left out of the sightings and the quiet; a knife leaves a piece be |
| `src/server/ReconServer.luau` | `standing`: the bolts standing, for the bots |
| `src/server/DroneServer.luau` | `flying`: the drones in flight, for the bots |
| `src/server/LeerServer.luau` | `standing`: the eyes standing, for the bots |
| `src/shared/Abilities/LeerSim.luau` | `velocity`: how fast an eye flies |
| `src/client/ParanoiaView.luau` | `reach`: how far you see while the dark's drawn |
| `src/client/LeerView.luau` | An eye past the dark drawn just inside it, unless the level or a smoke hides it |
| `tests/botthings.luau` | New: what bots fight, and how fast each skill breaks each piece |
| `docs/studio-checklist.md` | Section 80, and section 79's EM8 |

## 7. Debug tools

- **The pieces' health.** The caster's or owner's attributes show each piece's health as it's shot
  (`VFBoltHealth`, `VFDroneHealth`, `VFLeerHealth`), and a broken piece bursts on every screen.
- **The bots' skill.** Workspace's `VFBotSkill` sets the skill bots play at from their next life
  (section 64), to see each skill against utility.
- **The eye drawn.** Workspace's `VFLeer` holds each eye as an `Eye` ball: past the dark of a
  nearsight it sits about 7.1 m from the camera and shrinks, and it goes back to its place as the
  nearsight clears.

## 8. Refinement loop

1. Play section 80 in Studio at each skill: whether bots shoot each piece when a player would, and
   whether they're too quick or too slow at it.
2. Step through clips of ranked and pro matches to time players' first shots at each piece, as in
   section 3, and set a noticing time for utility apart from an enemy's if they differ.
3. Tune what comes first if bots throw fights by shooting utility, or leave it standing too long.
4. Check the eye drawn through a nearsight against clips of the reference: its size and how bright
   it is.

## Known gaps to check in Studio

- Bots shooting a bolt stuck on a wall and a drone in flight, the drone judged where the snapshots
  had it.
- An enemy fought first, and their last place watched before a piece of utility.
- A bot nearsighted by an eye still breaking it.
- The eye drawn through its nearsight where it looks to be, its pupil turned to the camera, and shot
  there.
- How quick bots are at it, and how the eye looks through the dark, as they feel.
