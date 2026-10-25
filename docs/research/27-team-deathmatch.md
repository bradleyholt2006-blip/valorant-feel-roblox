# System 27: Team Deathmatch

The goal asks for modes "like 2v2, comp, gun game, etc.", and the reference has a team mode beyond
the spike rounds: Team Deathmatch, five a side, the first side to 100 kills winning, or the side in
the lead after 9 minutes 30 seconds, split into four stages. There's no economy: each player picks
a loadout for each stage, a gun with the shield that goes with it, and each new stage upgrades it.
The dead are back in 1.5 s in their side's spawn room, protected for 15 s, and the room hurts
anyone who stays in it after that.

This system plays it on the spike rounds' three maps (system 25), each side in one of the map's two
spawn rooms, as a seventh mode on the Play menu (system 24), with the victory screen and the vote
for the next map between matches (systems 21 and 22). Drop-in is as before: whoever joins a match
under way spawns at once, on the side with fewer players.

As before, everything comes from public sources: Riot's "VALORANT Team Deathmatch 101" and the
patch notes that changed its loadouts (8.0 and 9.11), and, for what Riot doesn't give (each stage's
length, the pre-game, the loadouts' lists), the VALORANT Wiki's page on the mode. No game files,
memory or network traffic were used. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's article and patch notes) |
| **Community** | Published by a guide or wiki, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **The mode** (Team Deathmatch 101, June 2023). 5v5, with "four timed stages and no econ" over 9
  minutes 30 seconds. The first side to 100 kills wins; if the time runs out first, the side in the
  lead wins, and a tie is a draw. It has three maps of its own, Piazza, District and Kasbah.
- **Stages** (the wiki). A 20-second pre-game, then three stages of 75 s and a last of 345 s.
- **Loadouts.** Each player picks a loadout for each stage "at the start of the match or anytime
  you're in the Spawn Room", and each new stage upgrades it by itself. The shield comes with the
  loadout. The wiki has the lists: Stage 1 is sidearms alone (the Classic with the Regen Shield, or
  the Frenzy, the Ghost or the Bandit with none); Stage 2 the Sheriff or the Ares in Light Armor,
  or the Stinger in Heavy; Stage 3 the Spectre, the Ares or the Bulldog in Heavy, or the Guardian
  in Light; Stage 4 the Phantom or the Vandal in Heavy. After Stage 1 each player carries the
  stage's gun and the sidearm they picked for Stage 1. As a stage begins they're prompted to switch
  to its gun, and made to after a short time.
- **Respawns.** Every 1.5 s, into the side's spawn room, with a buff that protects from damage and
  abilities for 15 s (the wiki: while they stay in the room). After 15 s, staying in the room
  hurts.
- **Spawners and orbs.** Weapon spawners in fixed places hold guns that change with the stage, with
  limited ammo; G destroys one, as does running out, and the player is back on their loadout.
  Recovery Orbs restore health and shield over 6 s and come back every 30 s; Ultimate Orbs come up
  now and then. Kills and Ultimate Orbs charge the ultimate (the wiki: 3 points a kill and 10 an
  orb, with Jett's Blade Storm at 60).
- **Abilities.** Basic and signature abilities from the start, recharging over time once spent,
  each at its own rate (the wiki: Jett's Cloudburst every 29 s, Updraft and Tailwind every 44 s).
- **Patches.** 8.0 put Stage 2's Sheriff in Light Armor, not Heavy; 9.11 gave Stage 1's Classic the
  Regen Shield, not Light Armor.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Fight alongside your team to be the first to 100 kills in Team Deathmatch, the newest 5v5 VALORANT game mode." | [VALORANT Team Deathmatch 101](https://playvalorant.com/en-us/news/game-updates/valorant-team-deathmatch-101/), Riot, 15 June 2023 |
| "There are four timed stages and no econ."; "Match duration: 9m 30s, split into four stages" | The same |
| "You'll get to choose your loadout for each stage at the start of the match or anytime you're in the Spawn Room." | The same |
| "With each new stage, your loadout, and its lethality, will be automatically upgraded." | The same |
| "Plain and simple: the team that gets 100 kills first wins."; "What if a match ends before a team can get to 100 kills?" "The team in the lead will be the victor." | The same |
| "Score tied when the match ends?" "The match will end in a draw." | The same |
| "Respawn every 1.5 seconds."; "After dying, you'll respawn into the safety of your team's Spawn Room." | The same |
| "When you respawn, you gain a buff that protects you from damage and abilities for 15 seconds."; "After 15 seconds, you'll start to take damage from staying in spawn, so move quickly!" | The same |
| "Placed around the map are Weapon Spawners in fixed locations with weapons up for grabs."; "These weapons are stage-specific, and upgrade as the match progresses." | The same |
| "Weapons from the Weapon Spawner can be destroyed with (G) or whatever your drop weapon keybind is."; "Weapons taken from Weapon Spawners will have limited ammo and will also be destroyed when they run out." | The same |
| "Recovery Orbs grant a buff that restores Health and Shield over 6s."; "Respawn duration: 30s"; "The maximum Shield restored is determined by your selected loadout." | The same |
| "Ultimate Orbs spawn periodically in certain sections of each map."; "Got a kill? That will also increase your Ultimate percentage." | The same |
| "Abilities will recharge over time once depleted." | The same |
| "we've built three new custom maps just for Team Deathmatch" | The same |
| "Stage 2 - Sheriff Loadout"; "Heavy Shield >>> Light Shield" | [VALORANT Patch Notes 8.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-8-0/) |
| "When using the Classic in Stage 1 you will now have the Regen Shield instead of Light Armor" | [VALORANT Patch Notes 9.11](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-9-11/) |

### From the community

| What | Source |
| --- | --- |
| "Team Deathmatch has a 20-second pre-game phase and four main stages." | [VALORANT Wiki, Team Deathmatch](https://wiki.playvalorant.com/en-us/Team_Deathmatch) (Weird Gloop) |
| "the first three stages are 75 seconds (1m 15s) each, and Stage 4 is 345 seconds (5m 45s)." | The same |
| "Whilst inside the spawn room, both during pre-game and during the match, players can access their weapon loadout and modify which weapons they'll receive at each stage." | The same |
| "Stage 1 is a sidearm-only stage"; "players will carry both their primary weapon of choice for that stage as well as their sidearm of choice for Stage 1." | The same |
| "The amount of armor or shield a player has each stage depends on the gun they have chosen for that stage." | The same |
| "When a new stage begins, players will be prompted to switch to their next weapon", and "will be forced to equip it after a short duration." | The same |
| The loadouts: Stage 1 the Classic (Regen Shield), the Frenzy, the Ghost or the Bandit (no armor); Stage 2 the Sheriff (Light Armor), the Stinger (Heavy) or the Ares (Light); Stage 3 the Spectre, the Ares or the Bulldog (Heavy) or the Guardian (Light); Stage 4 the Phantom or the Vandal (Heavy) | The same |
| "Upon being killed, players will respawn 1.5 seconds later in their team's spawn room."; "Whilst remaining in the spawn room, they will be kept invulnerable for 15 seconds but after this they will start to take damage from staying in the room." | The same |
| "Players gain access to their ultimate by charging it up with points gained from kills (3 points) or collecting Ultimate Orbs (10 points)."; "Each Recovery Orb respawns every 30 seconds" | The same |
| Jett's charges recharge one at a time: Cloudburst in 29 s, Updraft and Tailwind in 44 s | The same |

Riot's buff protects "for 15 seconds"; the wiki has it last "whilst remaining in the spawn room",
so ours ends as you leave your room, and, as gun game's does, as you fire.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How much the spawn room's damage does, and how often | A public clip of a player staying in spawn past 15 s: the health and shield frame by frame |
| How long into a stage its gun is forced on | Public clips: the match's clock at a stage's start against the moment the gun in hand changes |
| Whether a stage's shield is handed over full | The same clips: the shield before and after the change |
| Whether the protection ends on leaving the room, or on firing | Public clips of a player hit just outside their spawn room within 15 s of a respawn |
| What stops an enemy entering a spawn room | Public clips of a spawn room's doorway: a wall that holds them, or damage |
| Whether our maps suit Team Deathmatch | Our own playtests: kills a minute with 2, 4 and 10 players, and how many lives end within 5 s of leaving the room |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Players | Two sides of up to five; anyone over waits in line (system 21) | Confirmed |
| Winning | The first side to 100 kills, or when the time's up the side with more; level, a draw | Confirmed |
| Length | 9 minutes 30 seconds in four stages: 75 s, 75 s, 75 s and 345 s | Confirmed (9:30, four stages); community (each stage's length) |
| The pre-game | 20 s in the spawn rooms behind the map's barriers, picking loadouts | Community (20 s); estimate (the barriers) |
| Under a player a side | It waits: lives come back after 1.5 s and nothing goes in the record, and the pre-game starts once each side has someone | Estimate |
| Loadouts | The wiki's lists, each gun with its shield; the first of each list is carried until another is picked | Community; confirmed (the Sheriff in Light Armor, Patch 8.0; the Classic with the Regen Shield, Patch 9.11) |
| What's carried | The stage's gun, the sidearm picked for the first stage unless the stage's gun is a sidearm (the Sheriff), and the knife | Community |
| Picking | B in the pre-game, in line, while down, between matches, or in your own spawn room: a column for each stage | Confirmed (at the start, or in the Spawn Room); estimate (in line, while down and between matches) |
| A new stage | Its loadout handed over at once in your spawn room, or anywhere 5 s into the stage, with a countdown on the HUD; a new primary is drawn | Confirmed (upgraded by itself); community (forced after a short time); estimate (the 5 s, and nothing taking it sooner but the room) |
| A pick in the room | The stage under way's handed over at once | Estimate |
| Shields | The loadout's: fresh with each life, and fresh when a loadout of another kind is handed over | Confirmed (by the loadout); estimate (fresh when handed over) |
| Respawns | 1.5 s after a death, in the side's spawn room, at one of the map's spawn places | Confirmed |
| Spawn protection | 15 s that can't be hurt, ending sooner as you leave your room or fire; drawn as a force field, as in gun game | Confirmed (15 s); community (ending on leaving the room); estimate (ending on firing, and the look) |
| The spawn room's damage | Your own room, from 15 s after your life or the match started, and the other side's at once: 15 every 0.5 s, through the shield as any damage, without the slow a hit brings | Confirmed (after 15 s); estimate (the damage, its rate, and the other side's room) |
| A death in a spawn room | `SPAWN ROOM` for its killer in the kill feed, and a death in the record, with no kill or assist for anyone | Estimate |
| Abilities | Every life starts with every charge, as in Skirmish; nothing recharges | Estimate (the reference's recharging isn't built) |
| The ultimate | As in Skirmish: a point a kill and a death, 8 for Blade Storm | Estimate (the reference's 60 points, 3 a kill and 10 an orb, aren't built) |
| Guns on the ground | None: G does nothing, and nothing drops on a death | Estimate (the spawners' guns, which G destroys, aren't built) |
| The scoreboard | Each side's players with their kills, deaths, assists and combat score, the whole match's under `SCORE` | Estimate |
| The end of a match | The victory screen for 10 s, `VICTORY`, `DEFEAT` or `DRAW`, then the vote for the next of the three maps for 15 s, then the next pre-game | Ours (systems 21, 22 and 25) |
| The maps | The spike rounds' three, a side in each spawn room | Estimate (the reference has three of its own) |
| Weapon spawners, Recovery Orbs, Ultimate Orbs | Not here | Confirmed, not built |

## 5. Design

### The rules

`TeamDeathmatchRules` is Team Deathmatch as plain state, as `GunGameRules` is gun game: the server
says who joins, leaves, hurts, dies, fires and stands where, and spawns whoever the rules return.
The sides, the line and the record are `Roster`'s, five a side, shared with the other modes.

```
             someone on each side
  waiting ─────────────────────► pregame: 20 s, behind the barriers
     ▲                                │
     │ a side empty                   ▼
     │                           live: 9:30, four stages
     │                                │ 100 kills, or the time's up
     │                                ▼
     └──────────────────────── matchOver: the victory screen, 10 s
                                      │
                                      ▼
                                vote: 15 s ──► pregame, on the map voted for
```

`stageAt` gives the stage a time into the match is in, and `step` moves `stage` on as the clock
passes each start. Each player's `picks` hold the loadout they've picked for each stage, by its
number in the stage's list, and `kitOf` turns the stage under way's into a kit by slot and a
shield. `kitStage` is the stage of the guns a player holds, so `rearms` can tell a new stage's
loadout, handed over anywhere once the stage has run `swapDelay`, from a pick changed for the stage
under way, handed over only in the spawn room or before the match. `canPick` says when a pick
counts: in line, outside a match under way, while down, or in your own room.

`roomAt` says whether feet are in a side's own spawn room or the other side's, from the rooms of the
map's plan (`MapPlan`): side 1 has the attackers' spawn and side 2 the defenders'. `burns` says
when a room burns someone: their own from `stayTime` after their life started (`spawned`) or the
match did, the other side's at once, then every `burnInterval` while they stay. `safe` is the
protection, which `unprotect` ends.

`died` scores a kill of an enemy for the killer's side, and a death with no killer (a burn) scores
for nobody; the record counts both. At 100 the match is over; when the time's up the side with more
kills wins, and a tie has no winner. `skip`, for testing, ends the pre-game, moves the match on to
the next stage's start, or ends it in the last.

### The server

`Arena` runs Team Deathmatch as its fifth mode, on Workspace's `VFArenaMode` `teamdeathmatch`,
which the Play menu reaches; P doesn't. Each life spawns at one of the map's spawn places for its
side's role, with its kit and shield (`PlayerSimServer.resetKit`). The map's barriers are up
through the pre-game, as in the spike rounds' buy phase.

Once a server frame, `spawnRooms` looks at where everyone alive stands: out of their own room their
protection's over; when the rules say, the kit is handed over (`arm`, which gives the new guns
first, so the hand goes to one as the old one's slot empties) with the shield if it's another
kind; and a burn is damage from nobody (`CombatServer.hurt`), with `spawnroom` for its weapon, so
the kill feed can name it. A life that's about to spawn again is left alone, so a player moved
across to the other side isn't burned in their old room. Firing ends protection, as in gun game,
and `CombatServer.protected` keeps the protected from being hurt.

A pick comes on the `LoadoutPick` remote, with the stage's number and the loadout's, and counts
where the rules say, with the server's own view of whether the player stands in their room.

The arena's model has `Mode` `teamdeathmatch`, `Map`, `Phase`, each side's kills as its score,
`WinScore` 100, `PhaseEndsAt`, `MatchWinner` (nothing for a draw), and `Stage` and `StageAt`, the
stage under way and when it started. Each player has `VFStagePicks` ("1,2,1,1"), `VFKitStage`,
`VFRoomSince` (when their stay in the room began, for the HUD's warning) and `VFProtected`. The
teams are named by colour, Orange and Teal, as in the spike rounds. Drops are off, and a drop that
comes anyway is handed straight back. Nothing is bought, and the debug keys 5 to 9 give nothing.

Gun game's assists were never counted: the record of who hurt a life was cleared before the death
was recorded. It's recorded first now, in both modes.

### The client

- **`ArenaHud`.** Each side's kills either side of the clock, the pre-game's and then the
  match's, with `STAGE 2 OF 4` under it, and under the bar `FIRST TO 100   NEXT STAGE IN 0:42`,
  with `B loadouts` while you're in your room or down. A new stage shows `STAGE 3` in gold for a
  moment with the loadout you picked for it (`SPECTRE   HEAVY ARMOR`), then `NEW LOADOUT IN 2`
  until it's handed over, and a new primary is drawn. In your room it shows your protection, or
  once that's over, when the room starts burning you; while it does, or in the other side's,
  `LEAVE THE SPAWN ROOM` or `ENEMY SPAWN ROOM` in red. The pre-game shows `MATCH STARTS IN 15`
  with the map's name.
- **`LoadoutMenu`.** New: B opens a column for each stage, with when it's under way
  (`1:15 - 2:30`) and its loadouts, each a gun and its shield. A click picks one, outlined in
  gold, and the stage under way is marked `NOW`. During a match it opens only in your own room or
  while you're down, and leaving the room closes it.
- **`Scoreboard`.** `TEAM DEATHMATCH   FIRST TO 100`, the two sides with the whole match's combat
  score under `SCORE`, and at the end `VICTORY`, `DEFEAT` or `DRAW`.
- **`KillFeed`.** A burn's death has `SPAWN ROOM` in red for its killer.
- **`PlayMenu`.** A seventh card, `TEAM DEATHMATCH`, `5v5`; a name that long shrinks to fit.
- **`BuyMenu`, `VoteScreen`, `Spectate`.** No buy menu, as B is the loadout menu; the spike rounds'
  maps' cards; and the dead come back in a moment.

### Not here yet

- **Weapon spawners, Recovery Orbs and Ultimate Orbs.** The next system.
- **Recharging abilities, and the ultimate's points.** Every life starts with every charge, and the
  ultimate fills as in Skirmish.
- **The prompt to switch.** The new stage's gun comes after 5 s, or at once in the room, with no
  key to take it sooner.
- **Maps of its own.** It's played on the spike rounds' maps, whose spawn rooms are a long way from
  the fight for a mode with respawns.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Arena/TeamDeathmatchConfig.luau` | New: the rules' numbers, with status and source, the stages' loadouts, and the player attributes |
| `src/shared/Arena/TeamDeathmatchRules.luau` | New: Team Deathmatch as plain state: sides, stages, picks and kits, protection and the spawn rooms' burn |
| `src/shared/Arena/GunGameRules.luau` | Assists recorded before the record of who hurt a life is cleared |
| `src/shared/Match/PlayConfig.luau`, `src/shared/Net/Remotes.luau` | Team Deathmatch on the Play menu; `LoadoutPick` |
| `src/server/Arena.luau` | Team Deathmatch as a mode: its kits, spawns, barriers, rooms, picks, protection and the record |
| `src/server/CombatServer.luau` | `hurt`, damage from nobody, and no slow for it |
| `src/server/AbilityServer.luau` | Every life with every charge in Team Deathmatch too |
| `src/client/LoadoutMenu.luau` | New: the loadout menu on B |
| `src/client/ArenaHud.luau`, `src/client/Scoreboard.luau`, `src/client/KillFeed.luau` | The kills, the stages and the rooms; `SCORE` and `DRAW`; `SPAWN ROOM` |
| `src/client/PlayMenu.luau`, `src/client/BuyMenu.luau`, `src/client/VoteScreen.luau`, `src/client/Spectate.luau` | The seventh card; no buy menu; the spike maps' cards; the line for the dead |
| `src/client/init.client.luau`, `src/client/Debug/TestAim.luau` | The menu started; `VFTestLoadouts` and `VFTestPick` |
| `tests/teamdeathmatch.luau` | New: 94 checks: the numbers, the rooms on every map, joining and the line, kills and the end, the time limit, stages, picks and kits, rearming, protection and the burn, and skipping |
| `tests/gungame.luau`, `tests/play.luau` | An assist in gun game; seven modes |

## 7. Debug tools

- Output says what's on: `[VF] Arena on: Team Deathmatch, on Outpost`.
- `workspace:SetAttribute("VFArenaMode", "teamdeathmatch")` and `VFArenaOn` true, from the server,
  start it, as PLAY TEAM DEATHMATCH does in Studio. `VFTestPlay` `teamdeathmatch` presses PLAY for
  it.
- `VFTestLoadouts` set to true or false on the local player opens or closes the loadout menu, and
  `VFTestPick` set to `2,3` picks the third loadout of the second stage, as a click would.
- `VFMatchSkip`, set true from the server, ends the pre-game, then each time moves the match on to
  the next stage's start, and in the last stage ends it as if its time were up.
- The arena's model has `Stage` and `StageAt`; each player has `VFStagePicks`, `VFKitStage`,
  `VFRoomSince` and `VFProtected`.

## 8. Refinement loop

1. From public clips (section 3), set `burnDamage`, `burnInterval` and `swapDelay`, and whether a
   stage's shield comes full.
2. Play with as many as can join. If the spawn rooms are too far from the fight on the spike maps,
   that's for maps of its own.
3. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- PLAY TEAM DEATHMATCH on the Play menu's seventh card, `5v5`, starts it on one of the three maps,
  each side in its own spawn room behind the barriers, with the pre-game's countdown.
- B opens the loadout menu; a click picks a loadout, and in the pre-game or the room it's in your
  hands at once, with its shield. Out of the room in a match, B does nothing.
- The top bar's kills, clock and stage, and a new stage's loadout handed over 5 s in, or at once in
  the room, with a new primary drawn.
- A respawn is a force field to others and can't be hurt until it fires or leaves the room.
- Staying in your room 15 s, or going into the other side's, burns, with the HUD's warning, and a
  death there reads `SPAWN ROOM` in the kill feed.
- A match's end: `VICTORY` and `DEFEAT`, or `DRAW` for a tie, then the vote of the spike rounds'
  maps, and the next pre-game on the winner.

Section 31 of the [Studio checklist](../studio-checklist.md) covers these.
