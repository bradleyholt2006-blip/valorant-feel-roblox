# System 28: Team Deathmatch's pickups

System 27 built the reference's Team Deathmatch without what lies around its maps and without its
own way with abilities. This system adds both, on the spike rounds' three maps: weapon spawners
holding a gun of the stage's, lent in place of the loadout's; Recovery Orbs that mend health and
shield, and leave a zone for allies; Ultimate Orbs that come up together now and then; abilities
that recharge over time; and the ultimate's own costs and points.

As before, everything comes from public sources: Riot's "VALORANT Team Deathmatch 101" and the patch
note that fixed a spawner's Outlaw (8.01), and, for what Riot doesn't give (the spawners' guns and
rounds, the orbs' points and zone, the abilities' times and the ultimate's costs), the VALORANT
Wiki's page on the mode. No game files, memory or network traffic were used. Nothing in this system
is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's article and patch notes) |
| **Community** | Published by a guide or wiki, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **Weapon spawners** (Team Deathmatch 101). In fixed places on each map, with guns that are the
  stage's and upgrade as the match goes on, and can be different each match. A gun taken from one
  has limited ammo and is destroyed when it runs out, or with G; either way its taker is back on
  their loadout's gun.
- **The spawners' guns** (the wiki). Each stage has its own: the Shorty, the Sheriff and the
  Stinger in the first; the Bucky, the Spectre, the Bulldog and the Marshal in the second; the
  Judge, the Phantom, the Vandal and the Outlaw in the third; the Judge, the Operator and the Odin
  in the last. Most have a full magazine but less in reserve than usual; the Odin has its 100 and
  nothing more. A gun dropped "can no longer be picked back up".
- **Recovery Orbs** (Riot). A buff that restores health and shield over 6 s, the shield as much as
  the loadout's; each orb is back 30 s after it's taken. The wiki: not the Regen Shield's pool;
  players "run over" orbs, and an orb leaves "a zone that allies can enter to also receive its
  effects".
- **Ultimate Orbs** (Riot). Up "periodically in certain sections of each map". The wiki: all up
  together, each worth 10 points to whoever takes it.
- **The ultimate** (the wiki). Points from kills, 3 each, and Ultimate Orbs, 10 each; each agent's
  ultimate costs its own number in this mode, Jett's Blade Storm 60.
- **Abilities** (Riot: "Abilities will recharge over time once depleted"). The wiki: basic and
  signature abilities from the start; most agents start the match with their signature's charge
  and their basic abilities half way to their first; each ability brings a spent charge back in its
  own time, Jett's Cloudburst in 29 s and her Updraft and Tailwind in 44 s.
- **Patches.** 8.01 fixed a spawner's Outlaw having no reserve. The wiki's spawner table has the
  Judge's magazine at 7, as it was until, by the wiki's own page for the Judge, Patch 7.09
  "Reduced max mag size from 7 >>> 5": the table looks older than the gun.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Placed around the map are Weapon Spawners in fixed locations with weapons up for grabs."; "Be sure you and your team are the first to reach them." | [VALORANT Team Deathmatch 101](https://playvalorant.com/en-us/news/game-updates/valorant-team-deathmatch-101/), Riot, 15 June 2023 |
| "Weapons from the Weapon Spawner can potentially be different each match."; "These weapons are stage-specific, and upgrade as the match progresses." | The same |
| "Weapons from the Weapon Spawner can be destroyed with (G) or whatever your drop weapon keybind is."; "Once destroyed, you will return to your loadout weapon." | The same |
| "Weapons taken from Weapon Spawners will have limited ammo and will also be destroyed when they run out." | The same |
| "Recovery Orbs grant a buff that restores Health and Shield over 6s."; "Recovery Orbs are available in certain sections of each map."; "Respawn duration: 30s" | The same |
| "The maximum Shield restored is determined by your selected loadout." | The same |
| "Ultimate Orbs spawn periodically in certain sections of each map."; "Got a kill? That will also increase your Ultimate percentage." | The same |
| "Abilities will recharge over time once depleted." | The same |
| "Fixed a bug where, if the Outlaw was picked up from a weapon spawner, it had no reserve ammunition." | [VALORANT Patch Notes 8.01](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-8-01/) |

### From the community

| What | Source |
| --- | --- |
| "Guns can also be picked up from weapon spawners located around the map."; "The guns available at these spawners change depending on the current stage." | [VALORANT Wiki, Team Deathmatch](https://wiki.playvalorant.com/en-us/Team_Deathmatch) (Weird Gloop) |
| "Players can return to their chosen loadout by dropping the gun (which in this case can no longer be picked back up)"; "or by depleting all bullets from the gun they picked up." | The same |
| "most of these guns have standard ammo (with the exception of Odin), but lesser reserves than usual" | The same |
| The spawners' guns, rounds in the magazine over the reserve: Stage 1 the Shorty 2/6, the Sheriff 6/12, the Stinger 20/60; Stage 2 the Bucky 5/5, the Spectre 30/60, the Bulldog 24/24, the Marshal 5/5; Stage 3 the Judge 7/7, the Phantom 30/20, the Vandal 25/25, the Outlaw 2/6; Stage 4 the Judge 7/7, the Operator 5/3, the Odin 100/0 | The same |
| A Recovery Orb "Grants a 6-second buff that restores Health and Armor or Shield"; "(not including the regeneration pool from Regen Shield) depending on the player's loadout."; "Each Recovery Orb respawns every 30 seconds" | The same |
| An Ultimate Orb "Grants 10 points towards the player's ultimate charge"; "All Ultimate Orbs spawn onto the map together periodically" | The same |
| Orbs leave "a zone that allies can enter to also receive its effects"; players "run over" them; "Each map contains several orbs" | The same |
| "Players gain access to their ultimate by charging it up with points gained from kills (3 points)"; "or collecting Ultimate Orbs (10 points)." | The same |
| The ultimates' costs in the mode, from 50 to 90 points: Jett's Blade Storm 60 | The same |
| "Players have immediate access to their basic and signature abilities"; "After casting abilities, they will recharge over time, with recharge rates varying depending on the type of ability." | The same |
| "Most agents start the match with one full charge of their signature ability"; "(plus 50% progress on the next charge if their signature has more than one charge available)"; "and 50% progress towards the first charge of their basic abilities." | The same |
| The cooldowns, per charge: Jett's Cloudburst 29 s, Updraft 44 s and Tailwind 44 s | The same |
| The Judge: "Reduced max mag size from 7 >>> 5" (v7.09), and its reserve from 21 to 15 | [VALORANT Wiki, Judge](https://wiki.playvalorant.com/en-us/Judge) (Weird Gloop) |

Neither source says how long a spawner stands empty, how many spawners and orbs a map has, how big
the zone is or how long it lasts, how often the Ultimate Orbs come up, whether a spent charge comes
back one at a time, or whether a kit's charges outlast a death. Ours are in section 4.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How long a spawner stands empty once its gun is taken | A public clip that watches one spawner: the match's clock at the take and when a gun shows again |
| Whether a spawner's gun is walked over or taken with a key | Public clips of a player taking one |
| How much a Recovery Orb mends, and how evenly | A clip of a hurt player taking one: the health and shield each second of the 6 s |
| The zone: how far it reaches, how long it lasts, and whether an ally gets it more than once | Clips of an ally walking in after a take: where they stood and when |
| When the Ultimate Orbs first come up, and how often after | Clips: the match's clock each time they show |
| Whether two spent charges come back together or one after the other | A clip of Jett throwing both clouds, and when each pip comes back |
| Whether a kit's charges outlast a death, and whether kills still bring Tailwind back | Clips of a Jett dying with charges spent, and of one with two kills and Tailwind spent |
| Whether our spawners and orbs suit the maps | Our own playtests: how often each is taken, by which side, and the fights round them |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Weapon spawners | Four a map, each a grey pad with a ring round it, lit while it holds a gun, the gun lying on it | Confirmed (in fixed places); estimate (four, where, the look) |
| Their guns | Each one of its stage's at random, with the wiki's rounds; the Judge 5 in the magazine and 7 in reserve | Community; confirmed (the Outlaw's reserve, Patch 8.01); estimate (at random, each spawner its own; the Judge's 5) |
| When they have one | Every spawner a gun as the match goes live and again as each stage starts; a spawner taken has another 30 s later; none in the pre-game or after a match | Confirmed (the stage's); estimate (the 30 s, and the stage's start) |
| Taking one | As a gun on the ground (system 15): walked over into an empty slot, or F in place of the gun in its slot, whose loadout gun isn't put down | Estimate |
| A lent gun | In its slot for the stage it was taken in, the loadout's gun out of it. Spent, or destroyed with G, and the loadout's gun is back at once, wherever you are; a death takes it; the next stage's loadout takes its place as that stage's gun is handed over, a fresh gun even where it's the same | Confirmed (G, running out, back on the loadout); community (can't be picked up again); estimate (the rest) |
| Recovery Orbs | Two a map, a green ball over a mark, up as the match goes live; taken by running over it (within 1 m); back 30 s after | Confirmed (30 s); community (run over); estimate (two, where, 1 m, the look) |
| Their buff | 6 s mending health and shield, the loadout's, evenly, all of each in the 6 s, never over the most; a Regen Shield's pool left as it is | Confirmed (6 s, health and shield, the loadout's); community (not the pool); estimate (how much, evenly) |
| Their zone | 3 m round where the orb was, for 6 s: each of the taker's side who walks in has the buff, once | Community (a zone for allies); estimate (3 m, 6 s, once each) |
| Ultimate Orbs | Two a map, a gold ball over a mark; all up 30 s into the match and every 60 s after; 10 points to whoever runs over one | Community (10 points, all together); estimate (two, where, 30 s and 60 s) |
| The ultimate | 3 points a kill, 10 an orb, none for a death; Blade Storm needs 60 | Community; estimate (none for a death) |
| Abilities at the start | As each match's pre-game starts, and with each player's first life in a match: Tailwind's charge, and Cloudburst and Updraft empty, half way to their first | Community |
| Their recharge | A spent charge comes back in the ability's time, Cloudburst 29 s, Updraft and Tailwind 44 s, one at a time, from when it's spent, dead or alive; charges are kept from one life to the next | Community (the times); estimate (one at a time, dead or alive, kept) |
| Kills and Tailwind | Two kills still bring a Tailwind charge back, as in the spike rounds | Estimate |
| The ability bar | A slot waiting on a charge counts down the seconds to it; X's ten pips each a tenth of 60 | Ours |

## 5. Design

### Where they stand

Each map has four spawners, two Recovery Orbs and two Ultimate Orbs, in the map's own metres on
its floor (`TeamDeathmatchConfig.Pickups`). The reference's maps are made for the mode, with the
spawners where the fights are; ours are the spike rounds', so they go where the two sides' runs to
a fight meet: each main's end by its site, the middle of mid, and the sites' fronts.

| Map | Weapon spawners | Recovery Orbs | Ultimate Orbs |
| --- | --- | --- | --- |
| Outpost | A choke and B choke; either side of the block in the middle of mid | A site's and B site's fronts, by the chokes | A main and B main, near their ends |
| Quarry | The north end of A main; either side of the courtyard's south; B choke | The courtyard's west and east | The north end of A main; B main's lower end |
| Foundry | A long, by its corner; either side of the hall in mid; B choke | A short, by the site; B link | A long; B main, by its choke |

The offline tests hold every one to where it can stand and to where it's fair. Each is on the
floor, a metre clear of walls and cover, out of the spawn rooms and their doors by a metre, and 5 m
or more from any other. Each side's run to it is found through the map's floor on a half-metre
grid, as wide as a player: neither side's is more than 11 m longer than the other's (about 1.6 s at
a run), and over a map's eight the two sides' runs differ by no more than 7 m. As printed, the
attackers' run less the defenders', spawners, then Recovery Orbs, then Ultimate Orbs, in metres:

| Map | Each | All |
| --- | --- | --- |
| Outpost | -0.2 -0.2 +0.0 +0.0 +9.5 +9.1 -10.2 -10.2 | -2.3 |
| Quarry | +2.5 -1.2 -0.9 +2.0 +7.0 +7.6 -6.4 -10.0 | +0.6 |
| Foundry | +3.4 +0.3 +0.3 +1.5 -0.0 +3.0 -8.6 -6.5 | -6.7 |

The spike maps lean to the defenders, whose spawn is nearer both sites, so the Recovery Orbs, by
the sites, are the defenders' sooner, and the Ultimate Orbs, back up the mains, the attackers'.

### The rules

`TeamDeathmatchRules` keeps the pickups with the rest of the mode, by their numbers in the map's
lists. A match going live puts a gun of the first stage's on every spawner (`restock`) and every
Recovery Orb up, and sets the Ultimate Orbs' time; `step` restocks as each stage starts and runs
the pickups' clock (`pickupsStep`): spawners and Recovery Orbs back once their wait is over, the
Ultimate Orbs all up at their time, and zones ending. Outside a match, or on a new map, everything
is empty or down (`clearPickups`).

`pickUp` says what someone alive at their feet runs over: a zone of their side they haven't had,
which starts the buff on them; a Recovery Orb, which starts it, goes down for its wait, and leaves
a zone; or an Ultimate Orb, which goes down until they all come up again. `mended` is how much of
the buff someone has had since last asked, as a share of their most health and shield.

`take` lends a spawner's gun: `lent` holds each player's lent guns by slot with the stage they were
taken in, and `kitOf` puts them in the kit in place of the loadout's for that stage alone (`lends`).
`returned` says a lent gun is gone, spent or destroyed; the loadout's gun is then owed (`owed`),
and `rearms` hands it over at once, wherever they are. A death, a new match and a wait clear them.
`startsOver` says whose abilities start over with the life they're spawning into: everyone's as a
match starts, and each player's with their first life in one.

### The server

- **`PickupsServer`** (new) builds the map played's pads, rings and orbs in `Workspace.VFPickups`
  and keeps them as the rules have them. Each spawner's gun is a gun on the ground
  (`GroundGunsServer.place`), on its pad and marked with its spawner, so it's taken as one: walked
  over into an empty slot, or F in place of the gun in its slot. Once a server frame it asks the
  rules what everyone alive runs over, gives an Ultimate Orb's points
  (`AbilityServer.addPoints`), and mends everyone under a buff four times a second
  (`CombatServer.mend`, which tells clients). Nothing it builds collides, stops a shot or is seen
  by a query.
- **`GroundGunsServer`.** A spawner's gun taken with F leaves the gun it replaces off the ground,
  and `spawnerTaken` tells `PickupsServer`, which has the rules lend it.
- **`Arena`.** Once a server frame, a lent gun no longer in its slot, or with nothing left in the
  magazine or the reserve, is returned, and the loadout's gun handed over; a lent gun the kit no
  longer lends is replaced afresh, even by the same gun, so a Vandal lent in the third stage isn't
  the fourth's. G with a lent gun in hand destroys it. Each player's lent guns go to clients as
  `VFLent`, by slot (`stinger,`).
- **`AbilityServer`.** With `AbilityServer.rules` (`AbilityConfig.TeamDeathmatch`), `fresh` starts
  a kit over: no points, the signature's charge, and every charge short of its most half way back.
  `step` brings a spent charge back in its ability's time, one at a time, alive or dead, and puts
  when each slot's next is due in `VFRecharge` (`0.00,812.50,0.00`, server time, 0 for none
  coming). A life carries its kit over from the last; a kill is worth the mode's 3 points and a
  death none; `need`, on the kit and on the wire, is what the ultimate needs, 60 for Blade Storm.

### The client

- **`GroundGunsView`.** A spawner's gun is drawn as any gun on the ground, with its prompt.
- **`ArenaHud`.** G works with a lent gun in hand, and the line under the bar adds
  `G back to your loadout`.
- **`AbilityHud`.** A slot waiting on a charge counts down the whole seconds to it, dimmed, where
  its note would be; and an ultimate needing more than ten points has ten pips, each a tenth.

### Not here yet

- **Other agents.** Only Jett plays, so only her times and cost are in.
- **Sound and the buff's look.** Nothing sounds as a pickup is taken or comes up, and the buff
  shows only as health and shield going up.
- **The minimap.** There's none to show where the pickups are.
- **The numbers no source gives.** The spawners' wait, the orbs' places and counts, the zone, the
  Ultimate Orbs' times and how much the buff mends are ours, for public clips to set (section 3).

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Arena/TeamDeathmatchConfig.luau` | The spawners' guns, where each map's pickups stand, the pickups' numbers, with status and source, and `VFLent` |
| `src/shared/Arena/TeamDeathmatchRules.luau` | The pickups as plain state: spawners, lent guns, orbs, zones and the buff, and whose abilities start over |
| `src/shared/Abilities/AbilityConfig.luau` | `TeamDeathmatch`, the mode's kit: points, costs, cooldowns and the start; `VFRecharge` |
| `src/shared/Abilities/AbilitySim.luau`, `src/shared/PlayerSim.luau`, `src/shared/Net/PlayerCodec.luau`, `src/client/PlayerController.luau` | `need` on the kit and on the wire; a kill's and a death's points the mode's |
| `src/shared/Combat/Health.luau`, `src/server/CombatServer.luau` | `mend`: health and shield back up to their most |
| `src/shared/Weapons/GroundGuns.luau`, `src/server/GroundGunsServer.luau` | A gun marked with its spawner, never cleared for room; `place`, `has`, `remove` and `spawnerTaken` |
| `src/server/PickupsServer.luau` | New: the pads, rings, orbs and zones, what's run over, and the buff's mending |
| `src/server/AbilityServer.luau` | The mode's kit: `fresh`, the recharge, `VFRecharge`, `addPoints` |
| `src/server/Arena.luau`, `src/server/init.server.luau` | Lent guns returned and the loadout's handed over afresh, G's destroying, `VFLent`; the pickups started and stopped |
| `src/client/ArenaHud.luau`, `src/client/AbilityHud.luau` | G with a lent gun; the countdown and ten pips |
| `tests/tdmpickups.luau` | New: 70 checks: the numbers, where every map's pickups stand and how fair, the spawners and lent guns, Recovery Orbs, the zone and the buff, Ultimate Orbs, and the abilities starting over |
| `tests/abilities.luau`, `tests/groundguns.luau` | The mode's kit, its summary and its `need` on the wire; a spawner's gun never cleared for room |

## 7. Debug tools

- `Workspace.VFPickups` has the map's `SpawnerPad` and `SpawnerRing`, `RecoveryOrb` and
  `UltimateOrb` parts, each numbered, with each orb's `Mark`, and a `RecoveryZone` while one lasts.
- A spawner's gun is a part in `Workspace.VFGroundGuns` with a `Spawner` attribute, its number.
- Each player has `VFLent` (`stinger,`: a primary, then a sidearm) while a spawner's gun is lent
  them, and `VFRecharge` in Team Deathmatch.
- `VFMatchSkip`, set true from the server, moves the match on to the next stage's start, which
  puts new guns on the spawners.

## 8. Refinement loop

1. From public clips (section 3), set `spawnerWait`, `zoneRadius`, `zoneTime`, `ultimateFirst`,
   `ultimateEvery` and `recoveryShare`, and whether charges come back one at a time.
2. Play with as many as can join, and watch which side takes each pickup first. If one side has
   them all, move them (`TeamDeathmatchConfig.Pickups`); the tests print each one's lean.
3. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The pads, rings and orbs on each map, out on the floor, none in a wall or a spawn room.
- A spawner's gun walked over into an empty slot, or taken with F in place of the gun in its slot,
  without the old gun going down; the ring dims, and 30 s later another gun lies on it.
- G with a lent gun in hand destroys it, and the loadout's gun is back; so does spending it.
- A Recovery Orb taken mends over 6 s, and an ally who walks into its zone is mended too.
- The Ultimate Orbs up 30 s into the match, 10 points each on the ability bar's X.
- The abilities as a match starts, their countdowns, and their charges kept through a death.
- A new stage's guns on every spawner, and its loadout in place of a gun lent in the last.

Section 32 of the [Studio checklist](../studio-checklist.md) covers these.
