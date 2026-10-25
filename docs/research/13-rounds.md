# System 13: Rounds played for the spike

The reference's main mode is played for the spike. One side attacks: it carries the spike to one of
two sites and plants it. The other side defends the sites and defuses the spike. A round ends when
a side is wiped out, the round's clock runs out before a plant, the spike is defused, or it goes
off. The sides swap after twelve rounds, and the first side to thirteen wins. This system builds
those rules, the match around them (halves, overtime, Swiftplay's shorter format), the spike played
by side, the starting kits, the round's HUD, and Outpost, a small two-site map of our own to play
it on. Credits and the economy are system 14; until then the buy menu costs nothing, as in
Skirmish.

As before, everything comes from Riot's patch notes and from community wikis and guides. No game
files, memory, network traffic or protected assets were used, and nothing reads the game while it
runs. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source |

The VALORANT Wiki at wiki.playvalorant.com is written by players, so what only it says is
Community here, as in [12-spike.md](12-spike.md).

## 1. Observable behaviour

- Two sides of up to five. One attacks and one defends, and they swap at the half.
- Each round starts with a buy phase. Both sides are held in their spawns behind barriers while
  they buy, and the spike lies on the ground in front of the attackers, for any of them to pick up.
- Then the round's clock runs. The attackers have until it runs out to plant the spike at a site.
  Once it's planted, the round's clock gives way to the spike's 45 seconds.
- The attackers win a round by killing every defender or by the spike going off. The defenders win
  by killing every attacker before a plant, by the clock running out before a plant, or by
  defusing the spike. Once the spike is planted, killing every attacker isn't enough: it has to be
  defused.
- After a round, a short post-round phase shows the result. Nothing changes it, and the next
  round starts.
- Dying loses what you bought. You start the next round with the Classic. Players who survive keep
  their guns.
- Twelve rounds a half. The first side to thirteen wins. Tied at 12-12, Unrated plays one more
  round and its winner takes the match. Competitive plays on, the sides swapping every round,
  until one side is two rounds ahead.
- Swiftplay is the same game, shorter: halves of four rounds, first to five, sudden death at 4-4.

## 2. Publicly documented details

### From Riot

- **Halves and the score to win.** Patch 1.11 added a custom-game option under which a match
  goes on "until both teams have played a full half of 12 rounds on each side", and with it "the
  game will no longer end when a team reaches 13 wins"
  ([Patch 1.11](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-1-11/)). So
  a normal match has halves of 12 and ends at 13 wins.
- **Overtime.** Patch 1.03 introduced Competitive's overtime: "teams will alternate playing rounds
  on attack and defense until a team claims victory by being up by 2 rounds". It added that
  "Unrated will still use the original Sudden Death format". Each overtime round also resets
  everyone's credits, and every two overtime rounds the teams can vote to draw
  ([Patch 1.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-03/)).
- **Credits.** Patch 1.0 set the credits for the first round of each half, and Patch 1.11 changed
  what survivors of some lost rounds earn
  ([Patch 1.0](https://playvalorant.com/news/game-updates/valorant-patch-notes-1-0/), Patch 1.11).
  Both are for system 14.
- **Retake.** Patch 13.00 (June 2026) added Retake, a separate mode: 3v3 on a single site with the
  spike already planted, first to five, the sides swapping every round, and no economy
  ([Patch 13.00](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-13-00)).
  It isn't built here.

### From the community

- **The match.** The VALORANT Wiki on Unrated: "The first to 13 rounds wins (best-of-25), with a
  final Endgame round played should the game reach a 12-12 scoreline." On Competitive: "the first
  team to get a 2-round lead on their opponent wins the game". On Swiftplay: "a 5v5 best-of-nine
  mode" ([Game Modes](https://wiki.playvalorant.com/en-us/Game_Modes)).
- **The phases.** The Valorant Fandom wiki on Unrated: the buy phase lasts 30 seconds, and the
  first buy phase of each half and the Endgame's last 45. A round lasts up to 100 seconds, and the
  post-round phase 7. The Endgame is played on the second half's sides
  ([Unrated](https://valorant.fandom.com/wiki/Unrated)). Wikipedia's article on the game quotes
  Game Informer's March 2020 preview on "the 100-second round timer"
  ([Valorant](https://en.wikipedia.org/wiki/Valorant)).
- **Swiftplay.** ONE Esports: "Halftime is after the fourth round, after which teams will switch
  sides", "the objective is to win five rounds", and ties go to "sudden death overtime"
  ([ONE Esports](https://www.oneesports.gg/valorant/shorter-unrated-games-swiftplay/)).
- **The spike at the start.** The VALORANT Wiki: "At the start of a round, the spike is dropped in
  front of the Attackers and can be run over to be collected", and it "can be collected only by
  other Attackers" ([Spike](https://wiki.playvalorant.com/en-us/Spike)). Fragster writes instead
  that it's handed to a random attacker
  ([Fragster](https://www.fragster.com/how-to-drop-spike-valorant-step-by-step-guide/)). We follow
  the wiki, which is the more specific of the two.
- **Losing your kit.** Hotspawn's economy guide: "If you die the previous round, you will lose any
  purchased weapons and armor, but you will keep purchased unused abilities", and "Even if you
  survive, you may still have to repurchase armor if you took damage". The Classic is "the basic
  Classic pistol that each player has access to every round"
  ([Hotspawn](https://www.hotspawn.com/valorant/guide/how-to-manage-the-valorant-economy)).

## 3. What can be measured, and how

- **The phase times.** Any public match video with the HUD in view shows the buy phase's countdown,
  the round's clock from 1:40, and the time from a round's last kill to the next buy phase.
- **Picking the spike up in the buy phase.** The same videos show whether attackers pick it up
  behind the barrier, before the round starts.
- **How far the sites are.** On the reference's maps, the time from the barriers dropping to the
  first attacker reaching a site, against the time a defender takes to get there from their
  spawn. Ours are worked out by the tests from Outpost's plan (section 5).

## 4. Confirmed vs estimated, as implemented

The rules are in `src/shared/Match/MatchRules.luau`, their numbers in
`src/shared/Match/MatchConfig.luau`, and the map in `src/shared/Match/MatchMap.luau`.

| Parameter | Value | Status |
| --- | --- | --- |
| Halves | 12 rounds, then the sides swap and the score stays | Confirmed (Patch 1.11) |
| To win | First to 13 | Confirmed (Patch 1.11) |
| Overtime, standard | At 12-12 one more round, on the second half's sides, and its winner takes the match | Confirmed (sudden death, Patch 1.03); community (the second half's sides) |
| Overtime, competitive | From 12-12, rounds on alternate sides until a side is two ahead; the first-half attackers attack first | Confirmed (Patch 1.03); estimate (who attacks first) |
| Swiftplay | Halves of 4, first to 5, sudden death at 4-4 | Community |
| Buy phase | 30 s; 45 s in the first round of each half and in every round past regulation | Community (30 and 45 s, Unrated); estimate (45 s for competitive's overtime rounds) |
| The round | 100 s to plant | Community |
| Planted | The spike's 45 s replace the round's clock | Community (system 12) |
| Post-round | 7 s, then everyone spawns for the next round, dead or alive | Community |
| Match over | 10 s showing the result, then a new match at 0-0 | Estimate |
| Winning a round | Every defender dead, or the spike going off: the attackers. Every attacker dead before a plant, the clock running out before a plant, or a defuse: the defenders | Community |
| The spike at a round's start | On the ground in front of the attackers, between their spawn spots and their door to mid; only attackers pick it up | Community (the VALORANT Wiki); estimate (the spot) |
| Planting | Only while the round's clock runs: not in the buy phase or after the round ends | Estimate (the barriers hold attackers in during the buy phase, and a round's result can't change) |
| Defusing | Only the defending side | Community |
| Finding it | Lying on the ground, its marker shows through walls only to the attackers; planted, to everyone | Estimate |
| Starting kit | The Classic and the knife, no shield: at the start of each half, and after any death | Community (Hotspawn) |
| Survivors | Keep their guns and shield into the next round, the shield refilled | Community (keeping them); estimate (the refill: see the gaps) |
| Sides | Each player joins the side with fewer players, side 1 when level; side 1 attacks first | Estimate |
| Nobody to play | With a side empty: waiting, the barriers down, buying open, anyone who dies back in 3 s, and the spike can be carried but not planted | Estimate (as the arena) |
| The map | Outpost, our own: section 5 | Estimate |
| Competitive's draw vote | Not built | |
| Credits | Not built: the buy menu is free | (system 14) |

## 5. Design

### Two modes, one host

The arena (system 7) already had what a match of rounds needs: sides on Roblox teams, so teammates
show as allies and can't shoot each other; spawning everyone for each round; barriers for the buy
phase; and the score sent to clients. `src/server/Arena.luau` now runs either mode: Skirmish on
Skirmish A by `ArenaRules`, or the spike rounds on Outpost by `MatchRules`. The state of play goes
out as attributes on the arena's model either way: `Mode`, `Phase`, `Round`, `Score1`, `Score2`,
`RoundWinner`, `MatchWinner`, `PhaseEndsAt` and `WinScore`, and for the spike rounds `Format`,
`Attackers` and `Reason`. The buy menu and the sounds read the phase from there as before.

What's on is Workspace's: `VFArenaOn`, `VFArenaMode` (`skirmish` or `spike`) and `VFMatchFormat`
(`standard`, `competitive` or `swiftplay`). P asks the server for the next of Skirmish, the spike
rounds, the spike rounds in Swiftplay's format, and off. A change of format starts a new match.

### The rules as plain state

`MatchRules` follows `ArenaRules`: plain state with no Roblox in it, which the offline tests play
through whole matches. The server tells it who joins, leaves and dies, when the spike is planted,
defused or goes off, and the time. It returns who to spawn and counts a version up on every change,
so the server knows when to tell clients. The phases are `waiting`, `buy`, `live`, `planted`,
`roundOver` and `matchOver`.

The spike tells the rounds it has gone off before its blast kills anyone. A round the blast decides
is the attackers' even if it kills the last attacker, and nothing that happens after a round's end
changes it.

### The spike by side

`SpikeServer` keeps running the one spike, with the rounds' say over it while they're played:
- Only the attacking side picks it up.
- Its carrier can plant it only while the round is live.
- Only the defending side can defuse it.
- A new spike lies in front of the attackers as each round starts, and none comes back between
  rounds.
- Lying on the ground, its marker shows through walls only to the attackers. Once it's planted,
  everyone sees it.

What a player may do with it goes to each player's simulation as before, now one context for the
carrier, one for those who may defuse it and one for everyone else. Clients predict the plant and
the defuse from Workspace's `VFSpikePlantOpen` and `VFSpikeDefusers` (the defending side, or 0 for
anyone) and their own side. On the course, anyone can still carry, plant and defuse it, at any
time.

### Kits

`PlayerSimServer.resetKit` now takes the kit to start the next life on: weapons by slot and a
shield. The spike rounds give the Classic and the knife with no shield at the start of each match
and each half, and to anyone who dies. Everything is free until system 14, so losing your kit only
means buying it again in the next buy phase. Once credits exist, that's what gives a death its
cost.

### Outpost

The reference's maps are built for five a side, and none is published at a scale we could build
from without measuring it ourselves from Riot's minimaps, as we did for Skirmish A. Outpost follows
their pattern at a size for one to three a side:
- The attackers' spawn is at one end and the defenders' at the other.
- Site A is on the attackers' left and B on their right. Each is reached by a main from the
  attackers' side, by a link from mid, and from the defenders' spawn, which is nearer both sites.
- It's mirrored left to right, so neither site is the easy one.

It's 66 m across and 68 m long, on a 1 m grid, with walls 5 m tall. Each site has a 12 by 10 m
plant area marked on its floor, with high and low cover. A pillar where the two links meet mid
keeps either site from seeing into the other.

The tests check the plan rather than trusting it:
- Every room can be reached, and every gap is wider than a player.
- No spot in either spawn can see into the other.
- Each spawn's three barriers hold its side in.
- No cover hides the eye but not the head.
- Running with the knife, defenders reach each site's plant area in 4.8 s and attackers in 7.5 s,
  so the defenders can get set first.

It's built at x -150 m, off the course's other side from the arena.

### The HUD

- **The top bar.** Your score in the ally colour and theirs in the enemy colour. Between them, the
  clock: the buy phase's, then the round's. Once the spike is planted it shows `SPIKE` in red, as
  the reference's bar shows the spike. Under the clock, the round and whether you attack or defend.
- **The buy phase.** A banner counts down, with what's at stake: `MATCH POINT`, `SUDDEN DEATH` or
  `OVERTIME`, and `LAST ROUND OF THE HALF`.
- **A round's end.** `ROUND WON` or `ROUND LOST`, how it was won, and `SWITCHING SIDES` before the
  half.
- **A match's end.** `VICTORY` or `DEFEAT` with the score.

The spike's own banners for a defuse and a blast are for the course. In the spike rounds, the
round's end says it.

### Roblox differences that matter

- Nobody respawns on their own while a mode is on (`CharacterAutoLoads` off). The rounds spawn
  everyone, so the dead watch until the next round.
- Teams are Roblox teams, which friendly fire and the outlines already go by. In the spike rounds
  they're named for their colours, Orange and Teal, because their spawns swap at the half.

## 6. Implementation map

| Piece | Where |
| --- | --- |
| The formats and the phases' times | `src/shared/Match/MatchConfig.luau` |
| Rounds, halves, overtime, who wins | `src/shared/Match/MatchRules.luau` |
| Outpost: rooms, cover, doors, spawns, sites, the spike's start | `src/shared/Match/MatchMap.luau` |
| The map's sites as the spike knows them | `src/shared/Spike/Spike.luau` (`Layouts`) |
| Running either mode, building the map, teams, spawns, kits | `src/server/Arena.luau` |
| The spike by side, its events | `src/server/SpikeServer.luau` |
| Starting kits | `src/server/PlayerSimServer.luau` (`resetKit`) |
| Planting and defusing by side, predicted | `src/client/ClientSpike.luau` |
| The HUD and P | `src/client/ArenaHud.luau` |
| The spike's banners on the course only | `src/client/SpikeHud.luau` |
| Its marker for the side that carries it | `src/client/SpikeView.luau` |
| The buy menu's line | `src/client/BuyMenu.luau` |
| Tests | `tests/match.luau` |

## 7. Debug tools

- **P** moves through Skirmish, the spike rounds, Swiftplay's format and off (Studio or the place
  owner). The Output window says which: `[VF] Arena on: the spike rounds, Standard`.
- **The attributes:** Workspace's `VFArenaOn`, `VFArenaMode` and `VFMatchFormat`, set from the
  server, choose what's played. The arena model's attributes are the match's whole state.
- **Skipping:** `VFMatchSkip` set true on Workspace from the server ends the phase being played
  and clears itself. That's a buy phase, a round (as its clock running out) or the wait for the
  next round, but not a planted spike's countdown. Scripted checks can get through a match without
  waiting out every buy phase and round.
- **The map:** the attackers' spawn has a red floor marked `ATTACKERS` and the defenders' a blue
  one marked `DEFENDERS`. The sites' plant areas are amber, marked `A` and `B`. Low cover is darker
  than high cover.

## 8. Refinement loop

1. Time the phases from match videos and set the community numbers as measured.
2. Check from videos whether attackers can pick up the spike behind the barrier.
3. Play Outpost with two and three a side, and move cover and doors where a side always wins.
4. Measure a real map (Ascent or Bind) from its minimap as Skirmish A was, if a full-size map is
   wanted.
5. Credits and buying (system 14), which give losing your kit its cost. That includes keeping a
   survivor's damaged shield, which the next round refills for now.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- Outpost builds at its origin with nothing overlapping it, and plays at the right scale: the
  doors, the cover's heights and the barriers.
- Each side spawns in its role's spawn facing out, and the spawns swap at the half.
- The spike lies in front of the attackers each round. Only attackers pick it up, plants work only
  while the round is live, and only defenders get the defuse prompt.
- Each way of ending a round shows its banner and scores. The sides swap at the half, the
  overtime round is labelled, and a match ends with `VICTORY` or `DEFEAT` and starts again.
- The Classic and the knife at each half and after a death, while survivors keep theirs.
- The round's clock agrees with the server, and gives way to `SPIKE` at the plant.

The [Studio test session](../studio-checklist.md), section 17, walks through these, with what to
expect.
