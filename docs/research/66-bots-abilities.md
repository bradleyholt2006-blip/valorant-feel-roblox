# System 66: bots' abilities

Each bot casts its agent's abilities, at the moments a player on that agent would, and the server
takes each cast as a player's. Attackers gathered short of a site look over it with the Recon Bolt
before they go in. On the push, Dark Cover goes on the two spots most likely to hold their way in, a
cloud on the first, and Paranoia, a Curveball round the corner, a Shock Bolt or Hot Hands at those
holding it. Defenders look for the attackers early with the Recon Bolt, and once attackers have
shown at their way in a moment ago they stall them there: a slow, a molly, a wall, a smoke or a
cloud on it, or Paranoia or a Shock Bolt at them. A bot guarding the planted spike answers a defuse
with Hunter's Fury, a molly or a Shock Bolt on the spike; out of a fight a bot on Sage heals itself
or a hurt teammate; and Hunter's Fury goes at enemies seen a moment ago.

Every throw is tried before it's thrown, flown through the level as the server will fly it, so a
bot throws only what lands where it means it to, and keeps its flashes and mollies off its own side.
Its hands then play the cast as a player's keys and mouse do. Each round, after its guns and shield,
it buys charges of the abilities it casts with what it has left.

Nothing is published about bots casting Valorant's abilities, so when a bot casts is ours, set
against what guides tell players about smokes, flashes, recon, walls and the post-plant, and against
the Counter-Strike bot's designer's notes on grenades and difficulty. No game file or source code
was read, nothing was read from the live game, and no Riot image, model or sound is in the
repository.

## 1. Observable behaviour

- On an execute, smokes go on chokepoints, flush with them so they don't spill into the open; on
  defense they stall a push, and a controller takes care not to block teammates off (Mobalytics).
- Sova's Recon Bolt is used to gather information on a site; a Sage's walls make a site harder to
  enter (thespike.gg).
- Flashes are for entering a site, and smokes on chokepoints or entry paths slow the other side
  (N4G).
- After a plant, teams stay back out of the site and stop a defuse with abilities thrown from cover,
  Sova's Shock Darts and Hunter's Fury among them (Dignitas).
- The Counter-Strike bot's designer notes that bots must throw grenades far ahead, and sets weapon
  proficiency from poor on Easy to complete on Hard (Booth).

## 2. Publicly documented details

| What | Source |
| --- | --- |
| "you should stick to smoking chokepoints during executes" | Mobalytics, [VALORANT Controller Guide (Tips, Tricks, and Responsibilities)](https://mobalytics.gg/blog/valorant/controller-guide-tips-tricks-responsibilities/) |
| "Place the smoke flush with the chokepoint. The smoke should not spill out into open space." | The same |
| "These smokes are good for stalling on defense to give times for rotates." | The same |
| "It is also important to note where your teammates are and avoid blocking them off by mistake." | The same |
| "be sure to save a smoke for an execute or at least time your execute when a smoke recharges." | The same |
| "Using his Sova dart, you can immediately gain information from a popular area like Mid or sites." | [An In-depth Guide on Using Utilities Perfectly in Valorant](https://thespike.gg/valorant/news/an-in-depth-guide-on-using-utilities-perfectly-in-valorant/2393), thespike.gg, 20 December 2022 |
| "Sages using their walls to make it harder for entry." | The same |
| "Make sure to time your smokes or ult with your teammates' movement." | The same |
| Flashes are "vital for site entry" | Maullick Gupta, [Mastering Utilities in Valorant: A Guide to Flashes and Smoke](https://n4g.com/articles/valorant-mastering-utilities-flashes-and-smokes-guide), N4G, 3 August 2023 |
| "Smoking choke points or enemy entry paths can hamper an opposing team's progression." | The same |
| "teams usually stay back and out of the site" | kaz0o_, [Analyzing the Post-Plant Meta in VALORANT](https://dignitas.gg/articles/analyzing-the-post-plant-meta-in-valorant), Dignitas, 22 November 2021 |
| "it is much safer since utilities can be thrown from behind cover." | The same |
| Sova's Shock Darts and Hunter's Fury "can both be used like the previous abilities to stop the defuse." | The same |
| "Have to throw grenades far ahead" | Michael Booth, [The Official Counter-Strike Bot](https://media.gdcvault.com/gdc04/slides/making_of_official.pdf), GDC 2004, slides: Combat: Weapon Proficiency |
| "Poor weapon proficiency" (Easy), "Mix of weapon proficiencies" (Normal), "Complete weapon proficiency" (Hard) | The same: Making it Fun: Difficulty levels |

What each ability does, how it's cast and what its numbers are, are the earlier systems', with their
sources (systems 17 to 19, 30, 31, 36 to 38, 40, 41 and 44 to 46); the sides' plans, the spots that
hold each way in and the bots' views and hands are systems 60 and 61's.

## 3. What can be measured, and how

When a bot casts and where its throws go is decided on the server, so it's checked in Studio
(section 70 of the checklist): each bot's stand-in names the last ability it cast and for what
(`VFBotCast`, Studio only), and its kit shows the charges it bought (`VFKit`).

Offline, each throw is tried and then played through a bot's simulation on every entrance of the
four maps' sites, 16 in all, from where the plan stands a bot for it (an attacker's spot short of
the way in, a defender's spot holding it). How many of the 16 a throw is found from, and the
furthest any lands from the spot it was meant for:

| Throw | Found from | Furthest off |
| --- | --- | --- |
| Dark Cover on a spot holding the way in | 16 | 0.1 m |
| Paranoia through those spots | 16 | 0 m |
| A Recon Bolt seeing those holding it | 15 | 0 m |
| A Slow Orb on the way in, stalling | 13 | 2.6 m |
| A Barrier Orb across it, in range | 10 | 0.8 m |
| Cloudburst on the spot, or on its sight of the way in | 8 | 4 m |
| Hot Hands on the spot | 8 | 2.8 m |
| A Shock Bolt by the spot | 6 | 3 m |
| A Curveball round the corner, blinding those holding and no teammate | 4 | 0 m |

A throw that isn't found from where a bot stands isn't thrown; it's tried again as the bot moves.
The offline suite, 3894 checks, passes.

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| What bots cast | Cloudburst, Blade Storm, Hot Hands, Curveball, the Healing, Slow and Barrier Orbs, Dark Cover, Paranoia, the Recon and Shock Bolts, and Hunter's Fury | Estimate | Ours: what goes at a spot, a person or a way in. Updraft, Tailwind, Blaze, Shrouded Step, From the Shadows, the Owl Drone, Resurrection and Run it Back wait |
| How often a moment gets its cast | Easy 0.4, Normal 0.7, Hard 0.9, Expert 1; each moment rolled once a life | Estimate | Ours, on Booth's "Poor weapon proficiency" to "Complete weapon proficiency" |
| The least time between one bot's casts | 1.2 s | Estimate | Ours |
| A throw not found, tried again | 1.5 s later | Estimate | Ours |
| The longest from the key to the throw | 3 s; Hunter's Fury 7 s | Estimate | Ours |
| A heal | Itself at 60 health or less, or the most hurt teammate within 15 m at 50 or less, once no enemy has hurt it or been in its sight for 3 s | Estimate | Ours |
| The Recon Bolt from a hold | 8 to 30 s into the round | Estimate | Ours: defenders look for the attackers early |
| A stall | Attackers seen within 14 m of its way in, in the last 2.5 s | Estimate | Ours, for "stalling on defense" (Mobalytics) |
| Smokes on the push | On the two spots most likely to hold the way in, within 3 m | Estimate | Ours, for "smoking chokepoints during executes" (Mobalytics) |
| A Curveball | Within 9 m of the way in; popping out of the thrower's sight, blinding those holding at least 0.6 of the longest blind between them, and no teammate more than 0.2 | Estimate | Ours: it pops about 6 m from where it's thrown (system 30) |
| Paranoia | Within 20 m of the way in | Estimate | Ours: inside its 25 m travel (system 41) |
| Blade Storm | On the push within 12 m of the way in, or in a stall; with no plan, an enemy seen within 12 m in the last 2.5 s | Estimate | Ours |
| Hunter's Fury | At enemies its side saw in the last 2 s, or at the spike an enemy's defusing; up to three blasts, at least 4 m apart | Estimate | Ours, for "stop the defuse" (Dignitas) |
| How far a throw may land from its spot | A smoke 3 m, a cloud 4 m, a molly, slow or Shock Bolt 3 m, a wall 3 m | Estimate | Ours |
| A molly or a Shock Bolt and its own side | Lands its radius and 1.5 m clear of teammates, and of itself | Estimate | Ours |
| Aimed | Within 1° | Estimate | Ours |
| The charges it buys | After its guns and shield, a charge at a time round E, Q and C; keeping back the price of a Vandal and Heavy Armor unless it's a half's first round or it has a primary | Estimate | Ours, as bots save for a full buy (system 60) |

## 5. Design

### Where it is in its side's plan

Each side's plan (`BotTeam`, systems 60 and 61) gives each bot a job, and what it casts goes by
where that job has it (`BotTeam.placeOf`):

- **Going in** (an entry): an attacker gathered short of its way into the site, or on the push
  through it, with the spots most likely to hold that way (the site's holds for it); or a defender
  on a retake, in through its way back, with where its side last saw those watching the spike.
- **Holding** (a hold): a defender at its way in, with where the attackers come from beyond it.
- **Guarding** (a guard): an attacker after the plant, with the spike.

Fetching the spike, planting it, defusing it and getting out of its blast take a bot's hands, so it
casts nothing then. In the modes that respawn there's no plan, and a bot casts only what needs none:
a heal, Hunter's Fury and Blade Storm.

### The moments

- **Gathered, before the push** (or a retake's): the Recon Bolt over its way in, at the spots that
  hold it.
- **On the push**: Dark Cover on the two spots most likely to hold its way in; a cloud on the first,
  or on its sight of the way in; Paranoia through them from 20 m; a Curveball round the corner at
  them from 9 m; a Shock Bolt or Hot Hands on the first; and Blade Storm once it's within 12 m.
- **Holding**: the Recon Bolt toward where the attackers come from, 8 to 30 s into the round; and
  with attackers seen at the way in a moment ago, a stall: a slow, a molly, a wall, a smoke or a
  cloud on the floor at the way in, Paranoia or a Shock Bolt at them, or Blade Storm.
- **Guarding the planted spike**, with an enemy defusing it: Hunter's Fury at the spike through
  whatever's between, or a molly or a Shock Bolt on it.
- **Anywhere**: a Healing Orb on itself or a hurt teammate in reach once no enemy has been about for
  3 s, and Hunter's Fury at enemies its side saw in the last 2 s.

A bot casts nothing while it fights, while it holds or steers an ability, and for 1.2 s after its
last cast. Each moment's cast is rolled once a life against its skill's share (`utility`), so a
Normal bot uses about seven in ten; a roll that misses is gone for that life, and so is a cast once
made, but for a heal, which goes on as long as it's needed.

### Tried before it's thrown

Each throw is flown through the level from the bot's eye, by the simulation the server flies it
with, before it's thrown, and one that lands where it's meant to is kept:

- **Dark Cover**: its mark sent out to the reach that puts the smoke on the spot's floor
  (`SmokeSim.place`).
- **Cloudburst**: thrown straight, bursting where it would.
- **Hot Hands and the Slow Orb**: lobbed, the arcs that reach the spot worked out, then a sweep of
  pitches and a finer one round the best, each flown (`FireballSim`, `SlowSim`); thrown if it lands
  near enough, its radius and 1.5 m clear of teammates and itself.
- **The Shock Bolt**: the low arc for each draw, three bars down to one, flown (`BoltSim`); shot
  if it lands by the spot, in sight of it, and clear of teammates and itself.
- **The Recon Bolt**: aimed over the spots it's for and flown, and loosed on the flight that, from
  where it sticks, sees the most of them within its radius.
- **The Curveball**: tried round both ways over a spread of angles (`FlareSim`), and thrown on the
  one that pops out of the thrower's sight, blinding those holding enough and no teammate much.
- **The Barrier Orb**: placed across the way in within its 15 m, turned to stand most across the way
  attackers come (`BarrierSim.place`).
- **Paranoia**: sent through the spots once they're within its travel.
- **Hunter's Fury**: up to three targets, at least 4 m apart, within its range.
- **The Healing Orb**: on a hurt teammate it sees, else on itself.

A throw found from where the bot stands is thrown from there, the bot standing still for it; a
smoke, a heal, a wall, Paranoia and Hunter's Fury go at a point, so they're aimed again each tick
and cast on the move. A throw that isn't found isn't thrown, and is tried again 1.5 s later from
wherever the bot has got to.

### Its hands

The cast is played by the bot's hands (`BotUtility.hands`), tick by tick, as a player's keys and
mouse: the ability's key, its equip waited out, its aim eased round as the bot's view eases
(`BotBrain`), and the throw once it's ready and aimed within 1°. A bolt's bounces are pressed and
its draw held to its bars, then let go; a smoke's mark is pushed or pulled out to its reach and sent
with the key again; a wall's targeter is turned with the key; each blast of Hunter's Fury waits for
the last one's windup, with the view turning as slowly as a player's does then (system 46).
Cloudburst is aimed before its key, as its throw goes on the press. A fight starting or 3 s going by
(7 s for Hunter's Fury) gives the cast up, and the ability's put away.

Every cast goes to the server as a player's would, through the bot's inputs, so the ability servers
fly, burst and hurt it as they do a player's (system 65).

### Buying charges

In each buy phase of the spike rounds, once a bot is alive with its agent locked in, its guns and
shield bought, it buys charges of the abilities it casts that cost credits, one at a time round its
E, Q and C, from its own credits (`Arena`). It keeps back what `BotBuy.toKeep` says: nothing on a
half's first round or with a primary, else the price of a Vandal and Heavy Armor, so a bot saving
for a full buy spends only what's past it.

### What it costs

The server gives the bots' choices 2 ms of each think (`BotServer`), every half second, the bots
taking turns from where the last think stopped; a bot whose throws run past it tries the rest in the
next think. A throw's flight is tried at a sixteenth of a second a step (the Curveball's at a
sixty-fourth, for its turn), for no more than 3 s, and a throw that isn't found waits 1.5 s before
it's tried again.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Bots/BotUtility.luau` | What a bot casts and when; every throw tried; its hands for the cast |
| `src/shared/Bots/BotTeam.luau` | `placeOf`: where each bot is in its side's plan, its way in and the spots that hold it |
| `src/shared/Bots/BotConfig.luau` | `Utility`, each skill's `utility`, and `CAST` |
| `src/shared/Bots/BotBuy.luau` | `toKeep`: what a bot keeps back from its charges |
| `src/server/BotServer.luau` | Each bot's moment, its casts within the budget, and its hands in its inputs |
| `src/server/Arena.luau` | Bots buying their charges in a buy phase |
| `tests/botutility.luau` | The places, the choices, every throw on every map, and the hands |
| `docs/studio-checklist.md` | Section 70 |

## 7. Debug tools

- In Studio, each bot's stand-in (ReplicatedStorage's `VFBots`) names the last ability it cast and
  for what, as `BotUtility` names them (`VFBotCast`: `darkcover push:darkcover:1`,
  `sloworb stall:sloworb`, `huntersfury defuse:huntersfury`, `healingorb heal`), next to its job
  (`VFBotTask`). Neither is set outside Studio, as they'd tell an enemy its plan.
- Its kit (`VFKit`) shows the charges it bought.

## 8. Refinement loop

1. Play the spike rounds with bots, and watch a side's push and a side's hold: whether the smokes
   and the flashes come with the push, whether a stall buys the defenders time, and whether a bot's
   throws ever land on its own side.
2. Tune `BotConfig.Utility` and each skill's `utility`, and re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Bots buying their charges, and casting them in a round: the moments, and how often.
- Their throws in the place's real geometry, on Roblox's collisions: smokes on the spots, flashes
  round the corner, mollies, slows and walls on the way in, and none on their own side.
- A heal, and Hunter's Fury, a molly or a Shock Bolt on a defuse.
- What the casts cost the server.

Section 70 of the [Studio checklist](../studio-checklist.md) covers these.
