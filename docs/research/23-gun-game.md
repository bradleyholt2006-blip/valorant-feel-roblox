# System 23: Gun game

The goal names gun game among the modes a server should offer, as Counter Blox's do. The gun game
Counter Blox's players know is Counter-Strike's: a mod first, then Arms Race in Counter-Strike:
Global Offensive and Counter-Strike 2. Each player climbs a ladder of guns of their own, a kill
moving them on to the next, and the first to make a kill with the knife at the top wins. The
reference had its own take for a while, Escalation, with a ladder of 12 levels shared by each
team.

This system plays Arms Race's rules with the reference's guns, in the arena's hall (system 7), on
Skirmish's three maps and with the same victory screen and vote between matches (systems 21 and
22). Escalation gives most of the numbers: 12 levels, the Vandal or the Phantom first, 5 seconds
untouchable after a respawn and a 10 minute limit. Team Deathmatch gives the respawn time. A Play
menu to pick a mode is system 24.

As before, everything comes from public sources: Riot's articles on Escalation and Team
Deathmatch, Wikipedia's article on gun game, the Counter-Strike Wiki and the Valve Developer
Community's page on Arms Race. Counter Blox's own gun game isn't documented anywhere we found: the
wiki pages and articles about the game say nothing of its modes' rules. No game files, memory or
network traffic were used. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's articles on its modes) |
| **Community** | Published by a wiki, an encyclopedia or a server-settings reference, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **Gun game.** A kill moves the killer's gun up a tier, and the top tier is a knife. A kill with
  the knife wins.
- **Arms Race.** Six a side, one long round with continuous respawns, no buying and no money, and
  guns that can't be dropped. The guns come in a fixed order of kinds, with a gun of each kind
  picked at random. Two kills move a player on, and a knife kill knocks the one killed down a
  level. Each side's leader glows when they fire, and killing the other side's leader moves you on
  at once. A respawn is protected for a moment, until the player moves.
- **Escalation.** Five a side and 12 levels, a weapon or an ability each. The team needs 7 points
  to clear a level: a kill on the current level is worth 1 and one on an earlier level 0.5. Each
  player needs at least one kill with each weapon to move on themselves, even when the team is
  further up. The first team to finish level 12, or the furthest along after 10 minutes, wins.
  There are no agent abilities, respawns are fast and untouchable for 5 seconds, and each death
  drops a health pack that lasts 10 seconds.
- **Team Deathmatch.** The reference's respawn mode: back every 1.5 seconds in the side's spawn
  room, protected there for 15 seconds.
- **Counter Blox.** The goal lists gun game among its modes. Its rules aren't published.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "5v5 game mode"; "12 Escalation levels (each level has a specific weapon or ability)"; "First team to 12, or furthest along in 10 minutes, wins" | [New VALORANT mode: Escalation](https://playvalorant.com/en-us/news/game-updates/new-valorant-mode-escalation) |
| "Team together must earn 7 points on a level to advance to the next level"; "A kill on the current level earns 1 point"; "A kill on a previous level earns .5 points" | The same |
| "You'll have to earn at least 1 kill on a weapon to unlock the next weapon level"; "Then you'll progress to the level 2 weapon, not directly to level 4" | The same |
| "Level 1: Always either Raze's Showstopper or Vandal/Phantom"; "Level 2: Always Vandal or Phantom."; "Levels 3–11: Assorted weapons and abilities"; "Level 12: Possible Shorty, Classic, Knife, Shock Dart...or even the Snowball Launcher" | The same |
| "No Agent-specific abilities based on your character select choice"; "Fast respawns (invulnerable for first 5 seconds)"; "Every death drops a health pack that expires after 10 seconds"; "Games run for about 7–9 minutes" | The same |
| "Respawn every 1.5 seconds"; "you'll respawn into the safety of your team's Spawn Room"; "you gain a buff that protects you from damage and abilities for 15 seconds" | [VALORANT Team Deathmatch 101](https://playvalorant.com/en-us/news/game-updates/valorant-team-deathmatch-101/) |

### From the community: gun game and Arms Race

| What | Source |
| --- | --- |
| "Defeating an enemy causes the player's gun to increase in tier"; "Reaching the highest tier causes the player's gun to be replaced with a combat knife"; "scoring a kill with the knife causes that player to win, and the entire game to restart"; "first introduced as a Counter-Strike mod" | [Wikipedia, Gun Game](https://en.wikipedia.org/wiki/Gun_Game) |
| 6 a side; "There is no time limit"; no buy menu and no money; guns can't be dropped and vanish when their owner dies | [Counter-Strike Wiki, Arms Race](https://counterstrike.fandom.com/wiki/Arms_Race) |
| The order since the update of 21 September 2021: an auto-sniper, a sniper rifle, 3 to 4 rifles, a machine gun, 3 SMGs, a heavy pistol, 3 pistols, 2 shotguns, then the Gold Knife. Since 11 November 2014 the gun of each tier is random, and the order of tiers fixed | The same |
| 2 kills a weapon, knife kills not counting; "The first player to get a kill with the Gold Knife wins the game for themselves and their team" | The same |
| Killed by a knife, or by suicide, a player respawns a tier lower; otherwise on the same weapon. Respawns are immediate, with a short spawn protection that ends quickly once the player moves | The same |
| Each side's player furthest ahead is its leader, who glows when firing; killing the other side's leader levels the killer up at once, unless they lead too | The same |
| "The game is a single extended round with instant respawn"; the killed player "loses a progression unless they are on the first weapon"; `mp_ggprogressive_random_weapon_kills_needed` 2 by default, the Golden Knife needing one | [Valve Developer Community, Arms Race](https://developer.valvesoftware.com/wiki/CS:GO_Game_Modes/Arms_Race) |

Nothing public says how long Arms Race's protection lasts, what level someone joining a match under
way starts on, or how Counter Blox's gun game plays. Everything not in these tables is ours, and
labelled.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How long Arms Race's protection lasts, and what ends it | A public clip of an Arms Race match, frame by frame from a respawn to the protection's end, with and without the player moving |
| What a player joining under way starts on | Join a public Arms Race match under way, or find a clip that does |
| Counter Blox's ladder and kills a level | A public clip of Counter Blox's gun game, counting the guns and the kills between them |
| How long our matches run | Our own playtests, 2 and 4 a side: from the start to the winning kill. Escalation's run 7 to 9 minutes |
| Whether the hall suits four a side | The same playtests: where fights start, and how often a respawn is shot at once |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Sides | Two, up to 4 a side; anyone over waits in line (system 21) | Estimate (Arms Race is 6 a side and Escalation 5; the hall was made for two a side) |
| The ladder | 12 levels: the Vandal and the Phantom in either order; the Bulldog, Guardian or Warden; the Marshal, Outlaw or Operator; the Ares or Odin; the Stinger or Spectre; the Sheriff; the Ghost or Bandit; the Classic or Frenzy; the Bucky or Judge; the Shorty; the knife. One gun of each tier at random for each match, never the same gun twice | Confirmed (12 levels; level 2 always the Vandal or Phantom; the knife among level 12's); community (the order of kinds after the rifles, and a random gun of each); estimate (the snipers after the rifles, which Arms Race puts first) |
| Kills a level | 1, the knife's included | Estimate (gun game's own rule; Arms Race takes 2, and Escalation at least 1 each) |
| A knife kill | Moves the killer on as any kill does, and knocks the one killed down a level, unless they're on the first | Community (Arms Race) |
| Winning | The first kill on the last level, the knife's, wins the match for the killer and their side. After 10 minutes, whoever's furthest up wins: the highest level, then the first there | Community (the knife); confirmed (10 minutes, furthest along); estimate (the tie) |
| Respawns | 1.5 s after a death, in the side's room, on the gun of their level with the knife and Heavy Armor | Confirmed (1.5 s, the spawn room); estimate (the armor, the arena's starting shield) |
| Spawn protection | 5 s, in which shots and swings go through, as through a teammate. Firing, swinging or scoping ends it | Confirmed (5 s); estimate (what ends it, as moving ends Arms Race's) |
| Moving on | The next gun is in the killer's hands at once, drawn, and the last one's gone | Community (a kill "causes the player's gun to increase in tier") |
| Buying, abilities, guns on the ground | None: the buy menu and the debug keys 5-9 are closed, every kit is empty, and G does nothing | Community (Arms Race's no buying and no drops); confirmed (no agent abilities); estimate (none of the shared ones either) |
| Joining | On the side with fewer, spawning at once, on level 1 | Estimate |
| Leaving | The first in line takes the place. If that leaves the sides two apart, the last to join the bigger moves across and spawns on the other, on their level. A side emptying gives the match up: everyone waits on level 1 for an opponent, and a new ladder starts when one joins | Estimate |
| The end of a match | The victory screen for 10 s, ranked by level, then the vote for the next map for 15 s, then a new match with a new ladder | Ours (systems 21 and 22) |
| The record | Kills, deaths and assists, as in Skirmish; the scoreboard ranks by level, not the combat score | Ours |

## 5. Design

### The rules

`GunGameRules` is gun game as plain state, as `ArenaRules` is Skirmish: the server says who joins,
leaves, spawns, fires and dies, with what and when, and spawns whoever the rules return. Who plays
on which side is `Roster`'s, shared with Skirmish and the spike rounds, and the vote is `MapVote`'s.

```
             someone on each side
  waiting ─────────────────────────► live: 10 minutes, everyone on level 1
     ▲                                 │
     │ a side empty                    │ a kill on the knife's level, or the time's up
     │ (live, or during the vote)      ▼
     └────────────────────────── matchOver: the victory screen, 10 s
                                       │
                                       ▼
                                 vote: 15 s ──► live, on the map voted for, with a new ladder
```

Each player has a level, the kills they've made on it and when they got there, and while it lasts
the time their spawn protection ends. `died` takes the weapon of the kill, so a knife kill can
knock the one killed down. `leader` is whoever's furthest up, for the time limit's winner and the
top of the scoreboard. With no rounds to even the sides out between, `leave` evens them out at
once, and whoever moves across spawns in their new room.

The ladder is rolled at the start of each match: one gun from each of `GunGameConfig.Tiers`, with
the Vandal and the Phantom in both of the first two tiers, so a match always opens on them, in
either order. `kitOf` is what a level carries by slot: its gun in its own slot and the knife.

### Spawn protection

`CombatServer.protected` says whether an entity can't be hurt now, and the server's target filter
leaves those out as it leaves out teammates, so shots and swings go through them. The protection
starts as each life does (`PlayerSimServer.spawnListeners`) and ends after 5 s, or on the first
input with fire or the right button held (`tickListeners`). Your own HUD says while it's on, and
everyone else sees you as a force field.

### Moving on mid-life

A kill moves the killer on at once: `Arena`'s `arm` gives them the new gun, then empties the slot
of the last if it was the other slot, so the hand goes to the new gun. The
client draws it as it arrives (`PlayerController.drawWhenGiven`), from the knife too, so a kill
with the knife on the way up still leaves you holding the next gun.

### The server

`Arena` runs gun game as its third mode, on Workspace's `VFArenaMode` `gungame`, which P reaches
after Skirmish. Each life starts on its level's kit (`PlayerSimServer.resetKit`), and the server
publishes the match's ladder and who leads on the arena's model (`Ladder`, `Leader`), each side's
highest level as its score (`Score1`, `Score2`, with `WinScore` the ladder's length), and each
player's level and protection (`VFGunLevel`, `VFProtected`). While it's on, `AbilityServer.off`
empties every kit, and the loadout rule refuses every purchase and debug gun. G does nothing, as
the client doesn't send it (`InputSampler.blockButtons`), and should a drop come anyway,
`GroundGunsServer.drops` is off and the server hands the gun straight back. Each room has four
spawn spots now, the arena's two and two more 1.2 m behind them (`ArenaLayout.Plan.rowSpacing`).

### The client

- **`ArenaHud`.** Each side's highest level either side of the match's clock, `LEVEL 3 OF 12`
  under it, and under the bar the gun you're on in gold and the next (`NEXT  ODIN`, or
  `A KILL WINS` on the knife). Moving on shows `LEVEL 4` and the new gun's name in the middle for
  1.5 s, and a knife kill on you `KNIFED` and the level you're down to. While your protection lasts,
  `SPAWN PROTECTION   until you fire`.
- **`Scoreboard`.** `GUN GAME` at the top, each player's level where the combat score goes and the
  gun of it where the loadout goes, for both sides, as nobody's gun is a secret. The rows go by
  level, the leader first on a tie, so the victory screen's MATCH MVP is the winner.
- **`BuyMenu`.** Closed throughout.
- **`Spectate`.** The dead come back in a moment, as its line says.
- **`RemoteEntities`.** Draws a protected player as a force field.

### Not here yet

- **Escalation's health packs.** Each death drops one that lasts 10 s.
- **Arms Race's leaders.** The leader's glow when they fire, and a level at once for killing the
  other side's.
- **Escalation's team levels.** 7 points a level for the team, with each player's own level
  behind it.
- **A late joiner's start.** Someone joining a long match starts on level 1, far behind. Nothing
  public says what Arms Race does.
- **Abilities as levels.** Escalation's ladder has some, such as the Showstopper.
- **Evening out Skirmish and the spike rounds when a side empties.** Gun game moves a player
  across at once. In Skirmish and the spike rounds, a side left empty with two or more on the
  other waits for someone to join.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Arena/GunGameConfig.luau` | New: the tiers of guns and the rules' numbers, with status and source, and the players' attributes |
| `src/shared/Arena/GunGameRules.luau` | New: gun game as plain state |
| `src/shared/Arena/ArenaLayout.luau` | Two more spawn spots in each room (`rowSpacing`, 1.2 m) |
| `src/shared/Arena/ArenaConfig.luau` | `gungame` among `VFArenaMode`'s modes |
| `src/server/Arena.luau` | Gun game as a mode: its kits, its levels mid-life, protection, the arena model's `Ladder` and `Leader`, and `VFMatchSkip` |
| `src/server/CombatServer.luau` | `protected`: shots and swings go through whoever it names |
| `src/server/AbilityServer.luau`, `src/shared/Abilities/AbilitySim.luau` | `off`, and `AbilitySim.empty` |
| `src/server/GroundGunsServer.luau`, `src/client/InputSampler.luau` | `drops`: whether G puts the gun on the ground; `blockButtons`: flags never sent, G's in gun game |
| `src/client/ArenaHud.luau` | The levels, the guns, the flashes, and P's new stop |
| `src/client/Scoreboard.luau` | Rows by level, with each player's gun |
| `src/client/BuyMenu.luau`, `src/client/Spectate.luau`, `src/client/RemoteEntities.luau` | Closed in gun game; its line for the dead; the force field |
| `tests/gungame.luau` | New: 48 checks: the ladder, levels, knife kills, protection, the win and the time limit, the vote, and joining, leaving and evening the sides out |

## 7. Debug tools

- Output says what's on: `[VF] Arena on: gun game, Skirmish B`.
- `workspace:SetAttribute("VFArenaMode", "gungame")` and `VFArenaOn` true, from the server, start
  it, as P does.
- The arena's model has `Mode` `gungame`, `Ladder` (`vandal,phantom,guardian,...`), `Leader` (a
  UserId), `Score1` and `Score2` (each side's highest level), `WinScore` 12 and `PhaseEndsAt` (the
  time limit's end). Each player has `VFGunLevel` and, while it lasts, `VFProtected`.
- `VFMatchSkip`, set true from the server, ends a match as if its time were up, so whoever's
  furthest up wins, then the victory screen and the vote.

## 8. Refinement loop

1. Time Arms Race's spawn protection in a public clip, and what ends it, and set `protectTime`.
2. Play 2 and 4 a side and time the matches. If they run well past Escalation's 7 to 9 minutes,
   take a tier out of `GunGameConfig.Tiers`; if they're over fast, make `killsPerLevel` 2, as
   Arms Race's.
3. If a public clip shows Counter Blox's gun game, compare its ladder and kills a level with ours.
4. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- P reaches gun game after Skirmish, and everyone spawns on level 1's gun with the knife: the top
  bar shows the levels and the clock, and under it the gun and the next.
- A kill puts the next gun in the killer's hands at once, with `LEVEL 2` and its name in the middle.
- A knife kill knocks the one killed down a level, with `KNIFED` on their screen.
- A respawn is a force field to others and can't be hurt, until it fires.
- A match's end: the victory screen goes by level, with MATCH MVP on the winner, then the vote,
  and the next match starts on the map voted for, with a new ladder.
- No buy menu, no abilities, and G does nothing.

Section 27 of the [Studio checklist](../studio-checklist.md) covers these.
