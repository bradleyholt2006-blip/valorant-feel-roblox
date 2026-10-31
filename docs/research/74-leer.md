# System 74: Reyna's Leer

Reyna's Leer (C) can now be played, the last of her abilities but Empress, which system 75 adds. C
readies the eye, and fire casts it: it flies 10 m along the crosshair over 0.4 s, on through walls
and ceilings, and hangs where it gets to, though a floor in its way stops it short. Then for 2 s any
enemy who looks at it is nearsighted, seeing no further than Paranoia leaves them, while they look
and a moment after, unless they break it first: it has 100 health. This system adds the eye in hand
and its flight, who looks at it and what they see, the eye in the level shots are traced through and
its breaking, how it looks and sounds, how bots cast it, and Basic Training with it. It also fixes
what Reyna's first run in Studio found (section 5).

As before, everything comes from public sources: Riot's patch notes 5.07 and 5.12, Liquipedia's
pages on Reyna and on Patch 5.12, guides by PC Gamer, esports.net, SteelSeries, Boosting Ground and
valoranttracker.org, Sportskeeda's article on Patch 5.07, thespike.gg's page on her, and Dot
Esports' report of a player's test of the eye's health. No game files, memory or network traffic
were used, nothing was read from the live game, and no Riot asset or sound is used. Riot gives the
windup, how long it nearsights, when the gun's back in hand, that it nearsights at any range, and
that damage from abilities hurts it. The guides give how far it goes, that it goes through walls,
its health and that it spares her side. How fast it flies, how big it is, how far off where they
look still counts as looking at it, and how the nearsight comes and goes are ours. Nothing in this
system is measured yet. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (Liquipedia, PC Gamer, esports.net, SteelSeries, Boosting Ground, valoranttracker.org, Sportskeeda, thespike.gg, Dot Esports) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **The eye** (Liquipedia, esports.net, PC Gamer). "Equip an ethereal, destructible eye. Activate to
  cast the eye a short distance forward." and "The eye will nearsight all enemies who look at it."
  esports.net: "Throws an eye that floats in the air." PC Gamer: "Casting Leer throws a ghostly eye
  in the air that inflicts near sight on any enemy within its line-of-sight."
- **Through walls, 10 m** (valoranttracker.org, SteelSeries, Boosting Ground). valoranttracker.org:
  "Once deployed, it will travel a fixed distance of ten meters away unless thrown on the ground."
  and "Able to pass through walls." SteelSeries: "It can travel through walls (like Omen) for a
  short distance." Boosting Ground: "Crucially, Leer passes through walls and geometry, allowing
  Reyna to deploy it from relative safety."
- **Its times** (Patch 5.07, Boosting Ground, valoranttracker.org). Patch 5.07: "Wind-up of
  nearsight effect decreased .6s >>> .4s", "Nearsight unequip delay decreased: .7 >>> .5" and
  "Duration decreased 2.6s >>> 2.0s", as "individual casts of the eye remain in the world for too
  long when the eye isn't destroyed." Boosting Ground: "The Nearsight effect lasts for 2 seconds
  after a brief wind-up period of 0.4 seconds." valoranttracker.org: "The eye will stay in position
  for approximately two seconds before vanishing."
- **At any range** (Patch 5.07, Sportskeeda, SteelSeries). "Range Restriction on Leer removed", to
  make it "a powerful angle-breaking tool against Operators on maps with longer sightlines."
  Sportskeeda: "Now with infinite range on the Leer, she can blind enemies across all ranges".
  SteelSeries: "Reyna's Leer possesses an unlimited range, enabling you to blind adversaries within
  your field of vision."
- **What they see** (esports.net, PC Gamer, Boosting Ground). "Enemies that look towards the eye
  will be nearsighted, gaining vision only a short distance ahead of them." PC Gamer: "Enemies under
  Leer's effects can only see a few meters around them." Boosting Ground has their vision limited
  "reportedly to around 7 meters."
- **Enemies alone** (Boosting Ground, PC Gamer, valoranttracker.org, thespike.gg). "Leer does not
  affect Reyna or her teammates."; "Allies are completely unaffected by Leer"; "Doesn't Nearsight
  teammates."; and in Spanish, "su destello no afecta a los compañeros de equipo" (its flash doesn't
  affect teammates).
- **Breaking it** (Boosting Ground, PC Gamer, valoranttracker.org, esports.net, Dot Esports,
  Patch 5.12). Boosting Ground: "The eye itself is destructible and possesses 100 Health Points
  (HP)." and "Enemies can shoot and destroy the eye to end the Nearsight effect prematurely." PC
  Gamer: "it can also be destroyed by dealing 100 damage to the eye." valoranttracker.org lists its
  health as 100, and esports.net has "The eye can be destroyed by enemies." Dot Esports reports a
  player's test: "Three bullets at 97.5 damage wasn't enough," and "the player believes it lands
  between 97.5 and 100 health." Since Patch 5.12 fire and Hunter's Fury damage it too ("Hot hands
  now damages:" and "Hunters Fury now damages:" both list "Reyna Leer"), as "Abilities that output
  damage will now universally damage enemy objects that can be damaged."
- **The charges** (Liquipedia). 250 credits (200 until Patch 3.0), two charges.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Wind-up of nearsight effect decreased .6s >>> .4s"; "Range Restriction on Leer removed"; "Nearsight unequip delay decreased: .7 >>> .5"; "Duration decreased 2.6s >>> 2.0s"; "Reyna's flash underperforms as a selfish entry-tool, especially at higher skill levels."; "Also, it should sharpen Leer as a powerful angle-breaking tool against Operators on maps with longer sightlines."; "We've also felt like individual casts of the eye remain in the world for too long when the eye isn't destroyed." | [VALORANT Patch Notes 5.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-5-07/), 4 October 2022 |
| "Abilities that output damage will now universally damage enemy objects that can be damaged."; "Hot hands now damages:" and "Hunters Fury now damages:", each listing "Reyna Leer"; "Damage-over-time area abilities (like Brimstone's Incindiary and Viper's Snakebite) now damage enemy utility" | [VALORANT Patch Notes 5.12](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-5-12/), 6 December 2022 |

Of the other notes searched for system 73 (2.03, 8.11, 11.11, 12.02 and 13.01), none changes Leer.

### From the community

| What | Source |
| --- | --- |
| "Equip an ethereal, destructible eye. Activate to cast the eye a short distance forward." "The eye will nearsight all enemies who look at it."; 250 credits, Max Charges 2 (200 to 250 in 3.0); 5.07's changes, as Riot's | [Liquipedia, Reyna](https://liquipedia.net/valorant/Reyna) |
| Under Damage Interaction Updates, "Reyna Leer" in the lists for Brimstone's Incendiary, Phoenix's Hot Hands and Blaze, Killjoy's Nanoswarm, Sova's Hunters Fury and Viper's Snakebite | [Liquipedia, Patch 5.12](https://liquipedia.net/valorant/Patch_5.12) |
| "Casting Leer throws a ghostly eye in the air that inflicts near sight on any enemy within its line-of-sight."; "Enemies under Leer's effects can only see a few meters around them."; "The spell automatically dissipates after a few seconds, but it can also be destroyed by dealing 100 damage to the eye."; "Allies are completely unaffected by Leer" | [PC Gamer, Valorant Reyna abilities guide](https://www.pcgamer.com/valorant-reyna-abilities-skills/) |
| "Throws an eye that floats in the air."; "Enemies that look towards the eye will be nearsighted, gaining vision only a short distance ahead of them."; "The eye can be destroyed by enemies." | [esports.net, Valorant Reyna Guide](https://www.esports.net/news/valorant-reyna-guide-how-to-play-reyna-like-a-pro/) |
| "Reyna's Leer possesses an unlimited range, enabling you to blind adversaries within your field of vision."; "It can travel through walls (like Omen) for a short distance."; "Leer lasts for 3 seconds." | [SteelSeries, Valorant Reyna tips and tricks](https://steelseries.com/blog/valorant-reyna-tips-and-tricks-279) |
| "The eye itself is destructible and possesses 100 Health Points (HP)."; "The Nearsight effect lasts for 2 seconds after a brief wind-up period of 0.4 seconds."; "Activating the ability casts the eye forward a short, fixed distance."; vision "reportedly to around 7 meters"; "Leer does not affect Reyna or her teammates."; "Crucially, Leer passes through walls and geometry, allowing Reyna to deploy it from relative safety."; "Enemies can shoot and destroy the eye to end the Nearsight effect prematurely." | [Boosting Ground, Valorant Reyna Guide](https://boosting-ground.com/Valorant/guides/agent-guides/reyna-guide) |
| "Leer Health" 100; "Once deployed, it will travel a fixed distance of ten meters away unless thrown on the ground."; "The eye will stay in position for approximately two seconds before vanishing."; "Doesn't Nearsight teammates."; "Able to pass through walls."; "200 • 2 Uses" | [valoranttracker.org, Reyna](https://valoranttracker.org/agents/reyna) |
| "Now with infinite range on the Leer, she can blind enemies across all ranges" | [Sportskeeda, All Reyna changes in Valorant Episode 5 Act 2](https://www.sportskeeda.com/valorant/all-reyna-changes-valorant-episode-5-act-2-will-dictate-place-meta) |
| "su destello no afecta a los compañeros de equipo" (its flash doesn't affect teammates); "los rivales más habilidosos pueden eliminar rápidamente el orbe flotante" (the most skilled opponents can quickly destroy the floating orb) | [thespike.gg, Reyna (in Spanish)](https://www.thespike.gg/es/valorant/agentes/reyna) |
| "After a lot of testing, the savvy fan believes that it takes approximately 100 damage to destroy the evil eye."; "Three bullets at 97.5 damage wasn't enough."; "While the exact amount is unclear, the player believes it lands between 97.5 and 100 health." | [Dot Esports, VALORANT player theorizes that Reyna's Leer has about 100 health](https://dotesports.com/valorant/news/valorant-player-theorizes-that-reynas-leer-has-about-100-health) |

The guides disagree in places: SteelSeries has it last 3 s and valoranttracker.org gives 200
credits, from before Patches 5.07 and 3.0, so we follow Riot and Liquipedia. No source says how fast
the eye flies or whether it takes its whole windup to fly, how big it is, how far off where they
look still counts as looking at it, how the nearsight comes on and goes as they look and look away,
what hides the eye from them, what "unless thrown on the ground" makes of where it stops, or Team
Deathmatch's cooldown for it. Ours are in section 4: the eye flies its 10 m evenly over its 0.4 s
windup and stops on a floor in its way, and anyone with it within 50 degrees of where they look,
with nothing between, is nearsighted while they look and 0.2 s after, seeing as far as Paranoia
leaves them.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How far it flies, and how fast | Clips of a cast along a wall's tiles, stepped frame by frame from the cast to where it stops |
| Where a floor stops it | A custom game: cast it at the floor at a few angles, near and far, and into a wall's foot |
| How far off where they look still counts | A custom game: a friend turns away from an open eye a few degrees at a time, saying when the nearsight goes |
| How the nearsight comes and goes | Clips from an enemy's view as they look at an eye and away, stepped frame by frame |
| How big it is to shots | A custom game: shots just past its edge from a few distances |
| Its health | A custom game with Spike Rush's damage orb, as Dot Esports' player did, or the Classic's body shots |
| Team Deathmatch's cooldown | A Team Deathmatch match, timing a charge's return from its cast |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Leer in hand | C puts the eye in hand (the fifth slot), ready 0.8 s after; fire casts it, alt fire does nothing, and C again puts it away. The gun's back 0.5 s after the cast. 250 credits a charge, two charges | Confirmed (0.5 s, Patch 5.07); community (250, two, Liquipedia); estimate (0.8 s, as Curveball's flare) |
| Its charges elsewhere | On the course they fill as every ability's do; in Team Deathmatch each comes back 44 s after it's spent | Estimate (44 s, as Curveball's) |
| Its flight | From her eye along the crosshair, at the pace that takes 10 m over its 0.4 s windup (25 m/s), on through walls and ceilings; it hangs where it gets to | Confirmed (0.4 s, Patch 5.07); community (10 m, through walls, valoranttracker.org, SteelSeries and Boosting Ground); estimate (its pace, ceilings) |
| A floor in its way | The first surface facing up, no steeper than can be walked (46 degrees), that it meets from above stops it, and it rests on that, its size clear of it; so does a floor it reaches inside a wall's foot | Community ("unless thrown on the ground", valoranttracker.org); estimate (what counts as a floor) |
| Open | From its windup's end for 2 s, and then it goes | Confirmed (2 s, Patch 5.07; from the windup's end, Boosting Ground) |
| Who it nearsights | Each server frame while it's open, every enemy of hers in play with its middle within 50 degrees of where they look, at any distance, with nothing between: the level, the spawns' barriers, clouds, walls of fire and walls of ice. Players on another side, and bots; on the course, with no sides, everyone but her. Never her side | Confirmed (any range, Patch 5.07); community (enemies who look at it, Liquipedia; never her side, Boosting Ground, PC Gamer and valoranttracker.org); estimate (50 degrees, what hides it) |
| The nearsight | Whole while they look and 0.2 s after: they see no further than Paranoia's 7.5 m; then it clears over 0.5 s. It's Paranoia's own, run on by each look, so the minimap, a flash's pop and bots go by it as by Paranoia's, and it goes as Paranoia's does with a death or a new life. It doesn't deafen | Community ("a short distance ahead", esports.net; "around 7 meters", Boosting Ground); estimate (0.2 s, 0.5 s, no deafening) |
| Breaking it | A box 0.5 m across in the level shots and knives are traced through, which no bullet passes. Her enemies' bullets and knives take their damage off its 100 health, a bullet's to the body at its range, and at none it breaks and nearsights no more. Her side's do nothing; on the course anyone's do, hers too | Community (100, Boosting Ground, PC Gamer and valoranttracker.org; broken by enemies, esports.net); estimate (0.5 m; anyone's on the course) |
| Gone | With a new round, and as she starts a new life; it goes on through her death | Estimate |
| Its look | A violet ball with a dark pupil turned to whoever watches it, small and dim as it flies, growing to 0.5 m and brightening as it opens, fading over its last 0.3 s; broken, it bursts in a flash | Estimate |
| Its sounds | In hand a quick whoosh, cast a slowed swish, opening a low toll, broken a sharp crack, heard as a cast is | Estimate (ours, from free Roblox sounds) |
| Bots | A bot playing her casts it on the push at those holding its way in, and holding a way in at an attacker seen there a moment ago, where its eye would come to rest short of them, in their view, with nothing between | Estimate |
| Basic Training | On the abilities step it counts as any ability does | Estimate |

## 5. Design

### The rules

- **`AbilityConfig`** adds Leer's `weapon` (`leereye`), its Team Deathmatch cooldown, and `Leer`:
  when the gun's back, the windup, its time open, its travel, health and size, the cone, and the
  nearsight's linger and fade, each with its status and source; `unequip` covers it. Leer is
  playable (`AbilitySim`), its fire casting `leer`.
- **`WeaponConfig`** adds `leereye`, the eye in hand, 39th on the wire.
- **`LeerSim`** (new) is the eye with no Roblox APIs: its cast (`cast`), how far it flies through
  the level (`reach`, with the world as `MovementSim`'s, so the tests fly it through a fake one),
  where it is (`at`, `rest`), when it opens and goes (`opens`, `ends`, `standing`, `open`), who
  looks at it (`looks`), the nearsight a look gives (`nearsight`), and the level with eyes in it
  (`level`, `piece`), over the Recon Bolt's.
- **`ParanoiaSim`** keeps the deafening on an attribute of its own (`DEAF_ATTRIBUTE`), and
  `nearsight` takes a whole time and a fade, so Leer's runs on Paranoia's.

### The server

- **`LeerServer`** (new) flies each cast as far as `reach` lets it, tells every client (`flight`),
  nearsights whoever looks at an open eye each frame through `ParanoiaServer.nearsee`, puts the eyes
  in `CombatServer.levelAt` and takes the damage they're struck for (`CombatServer.struck`), tells
  every client of one that breaks (`break`) and of a caster's that go with her new life (`gone`),
  and clears them with a new round (`Arena`). Each caster's `VFLastLeer`, `VFLeerHealth` and
  `VFLastLeered` say where her last eye came to rest, the health it has left and whom it
  nearsighted.
- **`ParanoiaServer`** adds `nearsightOf` and `nearsee`, and keeps the deafening apart, on
  `VFDeafened`.

### The client

- **`LeerView`** (new) draws your own eyes as you cast them, as far as the level here lets them fly,
  and others' from `flight`, puts them in the level your shots are traced through
  (`ClientShots.eyes`), and plays their opening and breaking. Workspace's `VFLeer` holds the balls
  and says how many (`Eyes`).
- **`ParanoiaView`** draws Leer's nearsight as Paranoia's, and deafens from `VFDeafened` alone.
  **`WeaponLooks`** draws the eye in hand, **`BuyMenu`** gives its rows, and **`SoundConfig`** its
  sounds.

### Bots

- **`BotUtility`** casts it on the push (`push:leer`) and holding a way in (`stall:leer`), each
  flown through the level first, so it rests where they'd see it.

### Fixes from Reyna's first run in Studio

Her checks in section 77 passed, and found these, fixed here:

- **Dismiss's edge.** The purple round the screen's edge never showed: its stroke was drawn round a
  frame the size of the screen, off it. It's now round a frame set in by half its width, as
  Paranoia's warning is (`SoulView`).
- **Her gun in Dismiss.** Others still saw it in her hands. Poses now put it away through Dismiss,
  as for the Owl Drone (`PlayerSimServer`, `BotServer`).
- **Her gun's draw.** It was heard as Dismiss began, putting the gun away; now it's heard as Dismiss
  ends and she draws it again (`GameSounds`).
- **The prompt.** It sat under the crosshair, where the reload bar is and, on a short screen, a
  kill's banner; it's now over it (`SoulView`).
- **Basic Training's ring** (system 72). The ring round a step's targets was drawn 1.6 m across
  whatever the step's radius; it's now as wide as where a target downed counts, its edge picked out,
  so the rifle step's takes in both targets (`TrainingView`).

### Not here yet

- **Fire and Hunter's Fury.** Since Patch 5.12 damage from abilities breaks it; here only bullets
  and knives do, as for the Recon Bolt and the Owl Drone.
- **Empress.** Played since system 75 (75-empress.md).
- **Bots against it.** Bots don't look away from an eye or shoot it; they're nearsighted by it as by
  Paranoia.
- **Late joiners** don't see an eye already standing.
- **Voices.** The reference's Reyna calls out; there are no voices here.
- **The look, the sounds, the cone, the pace and the floor** are ours until clips are stepped
  through.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | Leer's weapon, its Team Deathmatch cooldown, and `Leer`'s numbers, each with its status and source |
| `src/shared/Abilities/LeerSim.luau` | New: the eye's flight and reach, when it's open, who looks at it, the nearsight, and the level with eyes in it |
| `src/shared/Abilities/ParanoiaSim.luau` | `DEAF_ATTRIBUTE`, and `nearsight`'s whole time and fade |
| `src/shared/Abilities/AbilitySim.luau` | Leer playable, its fire casting `leer` |
| `src/shared/Weapons/WeaponConfig.luau` | `leereye`, 39th on the wire |
| `src/shared/Bots/BotUtility.luau` | `push:leer` and `stall:leer` |
| `src/shared/Audio/SoundConfig.luau` | Its sounds |
| `src/server/LeerServer.luau` | New: eyes flown, nearsighting, struck, broken and gone |
| `src/server/ParanoiaServer.luau` | `nearsightOf`, `nearsee`, and the deafening apart |
| `src/server/PlayerSimServer.luau`, `src/server/BotServer.luau` | The gun put away through Dismiss |
| `src/server/Arena.luau`, `src/server/init.server.luau` | Eyes cleared each round; LeerServer started and stepped |
| `src/client/LeerView.luau` | New: the eyes drawn, in your shots' level, and heard |
| `src/client/ParanoiaView.luau` | Leer's nearsight drawn, and the deafening from its own attribute |
| `src/client/Combat/ClientShots.luau` | `eyes`, the level with eyes in it |
| `src/client/Combat/WeaponLooks.luau`, `src/client/BuyMenu.luau` | The eye in hand, and its rows |
| `src/client/SoulView.luau`, `src/client/Audio/GameSounds.luau`, `src/client/TrainingView.luau` | Dismiss's edge and the prompt; the draw through Dismiss; the training ring |
| `src/client/init.client.luau` | LeerView started |
| `tests/leer.luau` | New: its numbers, in hand, its flight and where it stops, who looks, the nearsight, the level |
| `tests/botutility.luau`, `tests/soulharvest.luau`, `tests/arsenal.luau` | Bots casting it; it played and bought; the eye on the wire |

## 7. Debug tools

- Your `VFLastLeer`: where your last eye came to rest (metres); `VFLeerHealth`: the health it has
  left; `VFLastLeered`: once it's gone, the names of those it nearsighted, in order ("" for nobody).
- Anyone's `VFNearsight`: their nearsight, Paranoia's or Leer's, as `from,full,gone` in server time;
  `VFDeafened`: Paranoia's deafening, the same way.
- Workspace's `VFLeer` holds each eye (`Eye`, with its `Pupil`) and each burst (`Break`); its `Eyes`
  says how many eyes are drawn.
- `VFKit` has Leer's charges under `C`.

## 8. Refinement loop

1. Play her on the course and against bots: whether the eye's easy to place, whether 50 degrees is
   the right cone and the nearsight's linger right, and whether it's too easy or too hard to shoot.
2. Tune `AbilityConfig.Leer` and `LeerView`, and re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Leer on her card, and the eye in hand.
- The eye flying 10 m through walls, and stopping on the floor.
- Someone looking at it nearsighted until they look away, and not deafened.
- Her side never nearsighted, and unable to break it.
- Bullets breaking it at 100.
- Bots casting it.
- The fixes: Dismiss's edge, her gun in Dismiss, the draw, the prompt, and the training ring.
- The cone, the linger and the eye's health, as they feel.

Section 78 of the [Studio checklist](../studio-checklist.md) covers these.
