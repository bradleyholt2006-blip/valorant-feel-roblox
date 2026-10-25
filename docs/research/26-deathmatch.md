# System 26: Deathmatch

The goal asks for a choice of modes as Counter Blox has them, and Counter Blox's main screen offers
"Bomb Defusal, Hostage Rescue or Deathmatch" (Hotspawn's guide). The reference has its own: FFA
Deathmatch, everyone for themselves, up to 14 at once, the first to 40 kills or the most in 9
minutes winning. The dead come back in a moment anywhere on the map, every death leaves a health
pack, every gun is free, every life wears Heavy Armor and there are no abilities.

This system plays it on the spike rounds' three maps (system 25), as a sixth mode on the Play menu
(system 24), with the victory screen of everyone in their places and the vote for the next map
between matches (systems 21 and 22). Drop-in is as before: whoever joins a match under way spawns
at once.

As before, everything comes from public sources: Riot Support's page on FFA Deathmatch and the
patch notes that made and changed it (1.05, 1.10 and 4.03). Counter Blox's own deathmatch isn't
documented anywhere we found. No game files, memory or network traffic were used. Nothing in this
system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's support page and patch notes) |
| **Community** | Published by a guide or wiki, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- **FFA Deathmatch now** (the support page, October 2024). Up to 14 players, each for themselves.
  The first to 40 kills wins, or whoever has the most after 9 minutes. Respawns are at "ideal
  locations that are free of enemies but close to the action", and enemies are revealed each time
  you respawn. Every death drops a health pack that lasts 10 seconds and heals in full, health and
  armor. Each kill reloads your gun at once. Money is infinite and guns can be swapped at will.
  There are no abilities, so Jett can't glide.
- **As it began** (Patch 1.05). Ten players, first to 30 kills in 6 minutes, a random agent you
  own and no abilities. Any gun can be bought, Heavy Armor comes with every life, and kills drop
  health kits that heal in full and reload. All enemies show on the minimap now and then.
- **Patch 1.10.** 14 players, first to 40 in 9 minutes, and on every kill a full reload of the gun
  in hand, 30 rounds for the Ares and the Odin. Safer spawns, and the minimap reveal only as you
  respawn.
- **Patch 4.03.** Respawns in 1.5 s, not 3, farther from where you fell, and placed so you're more
  likely to face the other player in an encounter. "Dangerous" spawns removed or moved.
- **Counter Blox.** Deathmatch is one of its modes, picked from its main screen. Its rules aren't
  published.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "You can hop into an FFA Deathmatch queued with up to 14 players." | [VALORANT Game Mode - FFA Deathmatch](https://support.riotgames.com/en-us/valorant/gameplay/valorant-game-mode-ffa-deathmatch), Riot Support, 31 October 2024 |
| "Win by being the first to 40 kills or by having the most kills in 9 minutes."; and, earlier on the page, "Shorter match length (I would say a max of 6 minutes, but probably less)." | The same |
| "You'll respawn at ideal locations that are free of enemies but close to the action." | The same |
| "Every death drops a health pack that will last 10 seconds and heal for full health and full armor." | The same |
| "No abilities (yes, that means Jett can't glide, you cheeky Duelist, you)." | The same |
| "Infinite money!"; "The ability to swap weapons at will."; "Not only that, but each kill reloads your gun immediately." | The same |
| "Every time you respawn, enemies will be revealed." | The same |
| "10-player free-for-all"; "First to 30 kills with a time limit of 6 minutes"; "No abilities"; "You'll load in as a random Agent that you own" | [VALORANT Patch Notes 1.05](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-05/) |
| "Buy whatever weapons you want; heavy armor is given to you automatically" | The same |
| "Killing enemies drops health kits: picking one up fully restores your health/armor AND automatically reloads your weapon."; "All enemies are periodically revealed on the minimap" | The same |
| "Increased player count 10 >>> 14 players"; "Increased match length, first to 40 kills (was 30), time limit upped to 9 minutes (was 6)" | [VALORANT Patch Notes 1.10](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-1-10/) |
| "On every kill, players get an automatic, immediate full reload of their active weapon"; "(Ares & Odin get 30 bullets back)" | The same |
| "Updated spawning algorithm to encourage safer spawns"; "Removed periodic location pulse, and you'll now only receive a pulse right when you respawn" | The same |
| "Respawn Time Reduced: 3s >>> 1.5s" | [VALORANT Patch Notes 4.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-4-03/) |
| "Spawning logic will now favor respawn locations farther away from where you are defeated"; spawn placement "to increase the likelihood that you will be facing each other players" in an encounter; "dangerous" spawn locations removed or relocated | The same |

The support page's "a max of 6 minutes" is Patch 1.05's limit, left in from before 1.10; its own
win condition and Patch 1.10 both say 9 minutes, so 9 it is.

### From the community

| What | Source |
| --- | --- |
| Counter Blox's main screen has "the game modes": "Bomb Defusal, Hostage Rescue or Deathmatch" | [Hotspawn, how to play Counter Blox](https://www.hotspawn.com/counter-strike/news/roblox-csgo-how-to-play-counter-blox) |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How close you must walk to a health pack to take it | A public clip, frame by frame, of a player walking over one, against the floor's tiles |
| Where respawns land | Public clips of whole matches: for each respawn, how far the nearest enemy is and whether one is in view |
| Which way a respawn faces | The same clips: the first frame of each life against where the nearest enemy is |
| Whether a kill's reload drains the reserve | A public clip: the HUD's reserve before and after a kill on a part-empty magazine |
| How long our matches run, and whether our maps suit 14 | Our own playtests: from the start to 40 kills, and how often a life is shot within a second of starting |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| Players | Up to 14, each for themselves; anyone over waits in line (system 21) | Confirmed |
| Winning | The first to 40 kills, or after 9 minutes whoever has the most; on a tie, whoever got to that many first | Confirmed (40, 9 minutes); estimate (the tie) |
| Respawns | 1.5 s after a death | Confirmed |
| Where a life starts | A place no living enemy sees and none is within 10 m of, preferring one with an enemy within 30 m that's 20 m or more from where you fell (section 5) | Confirmed (free of enemies, close to the action, away from where you fell); estimate (every distance) |
| Which way it faces | Open floor ahead, as near the way to the nearest enemy as it goes | Confirmed (facing the other player); estimate (how) |
| Health packs | Every death in a match leaves one where the player fell, for 10 s. Whoever alive first walks within 1 m of it takes it: full health, a fresh Heavy Armor, and the gun in hand reloaded | Confirmed (10 s, full health and armor; the reload, Patch 1.05's); estimate (the 1 m, and the reload today) |
| A kill's reload | The killer's gun in hand at once has a full magazine, from its reserve; an Ares or an Odin 30 rounds | Confirmed (full, and the 30); estimate (from the reserve) |
| Shields | Heavy Armor on every life | Confirmed (Patch 1.05) |
| Buying | Every gun, free, at any time while alive; the shields and the abilities aren't sold | Confirmed ("Infinite money!", swapping at will); estimate (only while alive) |
| Abilities | None: a kit of no agent's, so no Drift either | Confirmed |
| Each match's first life | The starting kit (the Vandal, the Classic and the knife) with Heavy Armor; each later life the guns of the last, full | Estimate |
| Guns on the ground | None: G does nothing, and nothing drops on a death | Estimate (nothing public says either way) |
| Spawn protection | None | Estimate (nothing public mentions one) |
| Assists | Damage to someone another player then kills | Estimate (FFA's record isn't documented) |
| Under two players | It waits: lives come back after 1.5 s and nothing goes in the record, and a match starts once there's a second | Estimate |
| The end of a match | The victory screen for 10 s with everyone in their places, then the vote for the next of the three maps for 15 s | Ours (systems 21, 22 and 25) |
| The reveal as you respawn | Not here: there's no minimap | Confirmed, not built |
| The agent | Not here: nobody picks one | Confirmed (a random owned agent, Patch 1.05), not built |

## 5. Design

### The rules

`DeathmatchRules` is deathmatch as plain state, as `GunGameRules` is gun game: the server says who
joins, leaves, hurts, dies where and stands where, and spawns whoever the rules return. The record
is `Roster`'s, shared with the other modes. Each player is a side of their own, numbered by when
they joined, so `Roster` counts a kill of anyone else, and everything on the client that treats
the same side as an ally sees nobody else as one. There are no Roblox teams, so the shot filters,
the outlines and the knife's checks see everyone as an enemy.

```
             a second player
  waiting ─────────────────────► live: 9 minutes
     ▲                             │
     │ under two                   │ 40 kills, or the time's up
     │                             ▼
     └───────────────────── matchOver: the victory screen, 10 s
                                   │
                                   ▼
                             vote: 15 s ──► live, on the map voted for
```

`died` takes where the player fell, for their health pack, and the killer, whose kill is the
time they `reached` their count, so a tie at the time limit goes to whoever got there first.
`leader` and `placeOf` order everyone by kills, then by that time, then by when they joined.
`pickUp` hands a pack to whoever alive stands within its range, and `step` takes away the packs
whose time is up, brings the dead back once their 1.5 s are over, and moves the match on.

### Where a life starts

`DeathmatchSpawns.spots` lays a grid across each map's floor, a place every 3 m, keeping those
0.8 m clear of walls and cover, and notes for each how far the floor runs open ahead of it each of
eight ways, up to 6 m. `choose` sorts the places into four tiers, each with no living enemy within
10 m:

1. an enemy within 30 m, and 20 m or more from where the player fell;
2. 20 m or more from where they fell;
3. an enemy within 30 m;
4. the rest.

It takes the first tier with a place no living enemy can see, picking at random within it and
asking whether anyone sees each pick only as it's picked, so a respawn costs a few raycasts. With
nowhere safe and unseen, it takes the place farthest from every enemy that nobody sees, and with
everywhere seen, the farthest. The life faces the way with the most open floor, the full 6 m if
any has it, and among those the nearest the way to the nearest enemy (the map's middle when nobody
else is alive). On the server, seeing is a raycast from eye to eye against the map's own parts.

The tests run every map with 5 and 13 others alive at random places: in 40 trials of each, there
was always a safe place nobody saw, and the life started there. Outpost has 164 places, Quarry
274 and Foundry 308.

### Health packs and reloads

The server mirrors the rules' packs as green crosses a little above the floor, lit, that nothing
hits or collides with (`VFHealthPacks`), and checks the players' feet against them every step.
A pack taken heals through `CombatServer.heal`, which tells every client the new health and
shield in a shield event, and reloads the gun in hand. A kill reloads the killer's.
`PlayerSimServer.reloadInHand` moves rounds from the reserve into the magazine
(`WeaponSim.reloadNow`), 30 at most for the machine guns, and the next ack carries the magazine
to the client, whose prediction takes it up.

### No abilities

`AbilityConfig.NO_AGENT` is a kit of no agent's: no abilities, and no passive, so no Drift. It goes
over the wire as agent 0, so the client's prediction of a fall agrees with the server's, and
`AbilityServer.agent` puts it on every kit while deathmatch is played.

### The server

`Arena` runs deathmatch as its fourth mode, on Workspace's `VFArenaMode` `deathmatch`, which the
Play menu reaches; P doesn't. The arena's model has `Mode` `deathmatch`, `Map`, `Leader` (the
UserId of whoever leads, or won), `WinScore` 40 and `PhaseEndsAt`, and `MatchWinner` the winner's
side. Each player has `VFPlace`, their place in the match. The shop sells only what
`DeathmatchConfig.FOR_SALE` names (`ShopServer.sells`), and the loadout rule lets anyone alive buy,
but not on the victory screen or during the vote.
Drops are off, as in gun game, and a drop that comes anyway is handed straight back.

### The client

- **`ArenaHud`.** Your kills against the most anyone else has, either side of the match's clock,
  `FIRST TO 40` under it, and under the bar your place among everyone playing (`2ND OF 6`) and
  who leads, if not you. No tiles, as there are no sides.
- **`Scoreboard`.** One table of everyone in their places, up to 14, each with their kills,
  deaths, assists and place, and your own gun alone. The victory screen says `VICTORY` to whoever
  won and the rest their place (`3RD PLACE`), with MATCH MVP on the winner.
- **`BuyMenu`.** Open any time you're alive, `DEATHMATCH: EVERY GUN'S FREE`, with the shields and
  the abilities dimmed and `NOT SOLD`.
- **`AbilityHud`.** No bar, for a kit of no agent's.
- **`VoteScreen`.** The spike rounds' maps' cards.
- **`PlayMenu`.** The card says `FFA`.
- **`Spectate`.** The dead come back in a moment, as its line says.

### Not here yet

- **The reveal as you respawn.** There's no minimap to show it on.
- **Picking an agent.** Everyone plays a kit of no agent's, which only changes the look the day
  agents look different.
- **Measured spawns.** The distances are ours until a public clip says otherwise (section 3).
- **Packs off the floor.** A pack lies on the map's floor where the player fell, even for a death
  on top of cover or in the air.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Arena/DeathmatchConfig.luau` | New: the rules' numbers, with status and source, what's sold, the shield, and the place attribute |
| `src/shared/Arena/DeathmatchRules.luau` | New: deathmatch as plain state |
| `src/shared/Arena/DeathmatchSpawns.luau` | New: the places a life can start on each map, and which one it does, facing which way |
| `src/shared/Abilities/AbilityConfig.luau`, `src/shared/Net/PlayerCodec.luau` | `NO_AGENT`, sent as agent 0 |
| `src/shared/Weapons/WeaponSim.luau`, `src/shared/Combat/Health.luau` | `reloadNow`, and `heal` |
| `src/shared/Match/PlayConfig.luau` | Deathmatch on the Play menu, `freeForAll` |
| `src/server/Arena.luau` | Deathmatch as a mode: its kits, spawns, packs, reloads, the shop's rule and the record |
| `src/server/AbilityServer.luau`, `src/server/ShopServer.luau` | `agent`, and `sells` |
| `src/server/PlayerSimServer.luau`, `src/server/CombatServer.luau` | `reloadInHand`, and `heal` |
| `src/client/ArenaHud.luau`, `src/client/Scoreboard.luau` | The kills and the places, and the one table |
| `src/client/BuyMenu.luau`, `src/client/AbilityHud.luau` | Guns alone, any time; no bar |
| `src/client/VoteScreen.luau`, `src/client/PlayMenu.luau`, `src/client/Spectate.luau` | The spike maps' cards, `FFA`, and the line for the dead |
| `src/client/Debug/Ui.luau` | `ordinal`, for places |
| `tests/deathmatch.luau` | New: 98 checks: the numbers, joining and the line, kills, assists and respawns, the win and the time limit, packs, the vote, buying, reloads, no abilities or glide, and the spawns on every map |

## 7. Debug tools

- Output says what's on: `[VF] Arena on: deathmatch, on Quarry`.
- `workspace:SetAttribute("VFArenaMode", "deathmatch")` and `VFArenaOn` true, from the server,
  start it, as PLAY DEATHMATCH does in Studio. `VFTestPlay` `deathmatch` presses PLAY for it.
- The arena's model has `Mode` `deathmatch`, `Leader` (a UserId), `WinScore` 40 and
  `PhaseEndsAt`; each player has `VFPlace`. `Workspace.VFHealthPacks` holds the packs lying.
- `VFMatchSkip`, set true from the server, ends a match as if its time were up, so whoever leads
  wins, then the victory screen and the vote.

## 8. Refinement loop

1. From public clips (section 3), set `packRange`, and check `safeDistance`, `actionDistance` and
   `deathDistance` against where respawns land.
2. Play with as many as can join and time the matches. If 40 kills take far longer than 9 minutes
   with a few players, that's the reference's own; with many, a map may be too big for it.
3. If a clip shows a kill's reload leaving the reserve full, give `reloadNow` rounds of its own.
4. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- PLAY DEATHMATCH on the Play menu's sixth card, `FFA`, starts deathmatch on one of the three maps,
  with everyone spawning at once, nobody in sight of another.
- The top bar's kills, clock and `FIRST TO 40`, and under it your place.
- Heavy Armor every life, no ability bar, no glide, and G does nothing.
- B any time you're alive: every gun free, the rest `NOT SOLD`.
- A kill fills the killer's magazine at once, and a death leaves a green cross for 10 s that heals
  and reloads whoever walks over it.
- A life comes back 1.5 s after a death, away from where it fell, facing open floor.
- A match's end: the victory screen of everyone in their places, `VICTORY` and `2ND PLACE`, MATCH
  MVP on the winner, then the vote of the spike rounds' maps, and the next match on the winner.

Section 30 of the [Studio checklist](../studio-checklist.md) covers these.
