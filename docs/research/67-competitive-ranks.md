# System 67: Competitive ranks and careers

Competitive now ranks its players as the reference does. After five placement matches a player is
placed in a tier from Iron 1 to Ascendant 3 with 50 RR (Rank Rating). Each match after that gains RR
for a win and loses it for a loss; 100 RR promotes, and a loss at 0 RR demotes. A hidden MMR
(matchmaking rating) moves with every match, and how far it stands over or under the rank sets how
much a win gains and a loss loses. Rank shields keep a rank's Tier 1 from a loss or two, and from
Immortal up RR goes on counting, through Immortal 2 and 3 to Radiant.

Every player also has a career: for each mode on the Play menu, their matches won, lost and drawn,
and their kills, deaths, assists, combat score and rounds. It's kept with the rank in a Roblox data
store from one session to the next. The Play menu's cards show each mode's record and Competitive's
the rank, and Competitive's victory screen shows what the match did to it.

What the ranks are, the bounds of what a match is worth and what moves it are published; how Riot's
MMR works and how much each thing moves the RR inside those bounds aren't, so those numbers are ours
and marked as estimates. No game file or source code was read, nothing was read from the live game,
and no Riot image is in the repository: ranks show as words.

## 1. Observable behaviour

- A new player plays placement matches before a rank shows, then has a rank and its RR, and each
  match after shows the RR it was worth.
- A promotion, a demotion and a shield used show at the end of the match.
- From Immortal up the RR goes on past 100, and the top of a region's leaderboard is Radiant.

## 2. Publicly documented details

| What | Source |
| --- | --- |
| "all players need to play 5 placement matches to be placed", "with Ascendant 3 being the highest initial placement" | Riot, [Rank Rating (RR) for Iron through Ascendant Ranks](https://support.riotgames.com/en-us/valorant/gameplay/rank-rating-rr-for-iron-through-ascendant-ranks), support article (dated 19 December 2025) |
| "After being placed, you'll start off with 50 RR in your determined rank, and will need 100 RR to promote"; "you'll start the next rank with a minimum 10 RR buffer" | The same |
| "To demote, you'll need to hit 0 RR and then lose again"; "The lowest you can start in the next tier down after being demoted is 70 RR" | The same |
| "Whenever you enter Tier 1 of a rank (i.e. Bronze 1, Silver 1, etc.) through either promotion or demotion", "2 Rank Shields"; "These shields protect you from demoting to a lower Rank (i.e. from Silver to Bronze)"; "Shields do not protect you from dropping between Rank Tiers (i.e. Silver II to Silver I)" | The same |
| "How much RR you gain or lose is affected by how close your rank is to your MMR"; "If your MMR is higher than your rank, you'll gain more RR on wins than you lose on losses"; "If your MMR is lower than your rank, you'll gain less RR on wins and lose more on losses" | The same |
| "How much you win by, extraordinary plays, and whether or not you're the underdog in a match can all have an effect"; "it'll be your performance under review, rather than that of your teammates" | The same |
| "Going AFK or queue dodging in Competitive games for a prolonged period of time will affect your RR" | The same |
| "On a win, you will gain between 10 and 50 RR"; "On a loss you will lose between 0 and 30 RR"; "Min 5 RR gain for Diamond+"; "Max drop of 50 RR on a loss for Diamond+"; "On a draw you will gain a max of 20 RR (performance-based)", "Only for Iron through Diamond" | Riot, [VALORANT Episode 2 Act I Competitive Changes](https://playvalorant.com/en-us/news/game-updates/valorant-episode-2-act-i-competitive-changes/) |
| Immortal 2, Immortal 3 and Radiant by "regional RR thresholds", North America's 90, 200 and 450; Radiant also "one of the top 500 players in your region"; RR earned "forever"; "Demote from Immortal 1 by reaching 0 RR and losing again"; RR "completely reliant on the outcome of the match" | Riot, [Rank Rating (RR) for Immortal and Radiant Ranks](https://support.riotgames.com/en-us/valorant/gameplay/rank-rating-rr-for-immortal-and-radiant-ranks), support article (dated 30 March 2026) |

The Episode 2 article had a demotion land on 80 RR at the least; the support article, newer,
says 70, which is what's used. Overtime's vote to draw is Patch 1.03's (system 13).

## 3. What can be measured, and how

The rules are plain functions, checked offline: `tests/rank.luau` has 75 checks, and the
suite's 3990 pass. In Studio (section 71 of the checklist) each player's attributes carry their rank
and totals, and in Studio alone the hidden MMR and a printed line for each result. `VFMatchDecide`
ends the round under way for the side it names, so a whole match plays in seconds. Studio can only
use the data store if the place lets it use API services (Game Settings, Security); otherwise the
career lasts the session and `VFCareerStatus` says why.

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| Placements | 5 matches, then the tier the MMR stands at, Ascendant 3 at most, with 50 RR | Confirmed | Support article |
| Shields on placing | None | Estimate | Ours: the article gives them for a promotion or a demotion |
| RR a tier | 100 | Confirmed | Support article |
| Promotion | What's over 100 carried, 10 RR at the least | Confirmed | Support article |
| A loss short of 0 RR | Stops at 0, in the tier | Confirmed | Support article |
| Demotion | A loss at 0 RR: 100 less the loss, 70 RR at the least | Confirmed | Support article |
| Shields | 2 on entering a rank's Tier 1, Bronze to Ascendant, by a promotion or a demotion; each takes a loss at 0 RR instead of the rank | Confirmed | Support article |
| A win | 10 to 50 RR; from Diamond, 5 to 50 | Confirmed | Episode 2 article |
| A loss | 0 to 30 RR; from Diamond, 0 to 50 | Confirmed | Episode 2 article |
| A draw | 0 to 20 RR on play alone, below Immortal; none from Immortal | Confirmed bounds | Episode 2 article, Iron through Diamond; Ascendant, added since, is counted with them |
| Immortal | RR past 100; Immortal 2 at 90, Immortal 3 at 200, Radiant at 450 | Confirmed | Immortal and Radiant article, North America's |
| What a match is worth inside the bounds | 20, plus 5 RR a tier of MMR over the rank, play up to 5 either way, the margin up to 5, the underdog up to 5 either way | Estimate | Ours: what counts is published, how much isn't |
| Play | Combat score a round against the match's average: 5 RR more at half as much again, 5 less at half of it | Estimate | Ours; none from Immortal, as the article has it |
| MMR | Elo's, a tier 100 from Iron 1 at 0; 400 for 10 to 1; K 40, 80 in placements; a new player at Silver 3 | Estimate | Ours |
| Bots' MMR | Easy 300, Normal 800, Hard 1300, Expert 1800 | Estimate | Ours |
| A win over the MMR | Can't take the rank more than a tier over it | Estimate | Ours, as bots fill matches here |
| Which matches count | Half its rounds or more played to their end; in a mode without rounds, everyone in it at its end | Estimate | Ours |
| Leaving Competitive under way | A loss as it stands, once a round's been played to its end | Estimate | Ours: the reference's penalty has no published size |

## 5. Design

### The hidden MMR

Each player's MMR is Elo's rating on the ranks' own scale: Iron 1 at 0 and 100 a tier, so Silver 3
is 800 and Ascendant 3 is 2000 to 2099. A match moves it by K times the result (1 for a win, 0 for a
loss, a half for a draw) less what was expected, and what's expected is Elo's chance for the side's
MMR against the other's, each the average of its players: 1 in 2 for sides level, 10 in 11 for a
side 400 up. K is 80 in placements, to find a new player's level sooner, and 40 after. A new player
starts at Silver 3, about the middle of the ranks. The MMR never goes to a client on a live server;
in Studio it's an attribute, for checks.

### Placements

The first five Competitive matches move the MMR and nothing else. After the fifth the player is
placed at the tier their MMR stands at, Ascendant 3 at most, with 50 RR. No shields come with it, as
the article has them come with a promotion or a demotion.

### What a match is worth

Once placed, a win is worth 20 RR, plus 5 for each tier the MMR stands over the rank, plus the
player's play, the margin and the underdog's share, held to 10 to 50 (5 to 50 from Diamond). A loss
is worth 20, less 5 for each tier the MMR stands over the rank, less their play, plus the margin,
less the underdog's share, held to 0 to 30 (0 to 50 from Diamond). The MMR is the one after the
match has moved it.

- **The MMR against the rank.** 5 RR a tier puts the published bounds where the MMR is a few tiers
  off: with the rest level, a win gains 10 two tiers under the rank and 50 six tiers over, and a
  loss loses 30 two tiers under and nothing four tiers over. So a player whose MMR is over their
  rank gains more than they lose, and one under it the other way, as the article says.
- **Play.** The player's combat score a round against the match's average, everyone's in it, bots
  and all: 5 RR more at half as much again as the average, 5 less at half of it, and no more either
  way. None from Immortal, where RR is "completely reliant on the outcome of the match".
- **The margin.** Up to 5 RR more either way, a whole match's rounds for all of it: a 13-0 win gains
  about 4 more than a 13-11, and a 0-13 loss loses about 4 more than an 11-13.
- **The underdog.** Up to 5 RR more for a win, and less for a loss, for a side given no chance; the
  favourite the other way.
- **A draw.** Below Immortal 0 to 20 on play alone, 10 for an average game; none from Immortal.

### Promotions, demotions and shields

100 RR promotes, carrying what's over, with 10 RR at the least. A loss bigger than the RR left stops
at 0, and a loss at 0 demotes, to 100 less the loss with 70 at the least. Entering a rank's Tier 1,
Bronze 1 to Ascendant 1, by a promotion or a demotion gives 2 shields; each takes a loss at 0 RR in
that tier instead of the rank, and a demotion out of the tier needs them gone. Iron 1 at 0 RR stays
there.

### Immortal and Radiant

Ascendant 3 promotes into Immortal 1, where RR goes on past 100. Immortal 2, Immortal 3 and Radiant
are shown at North America's thresholds, 90, 200 and 450 RR, and Immortal 1 at 0 RR demotes on a
loss as any tier does. There are no shields there, as the article has none.

### Bots

Bots fill Competitive matches here, so each counts at its skill's MMR in its side's average (Normal
at a new player's). The reference's bounds come from matched sides: there, a player over their level
loses more than they win. Here nothing matches the sides, and beating weaker bots over and over
would gain at least 10 RR a time forever. So a win can't take the rank more than a tier over the
MMR, and the MMR against bots slows as the chance of winning nears certain: 400 wins in a row over
Easy bots, alone on a side, end at Platinum 1 with an MMR of 1123.

### Which matches count

A match counts as it ends. In a mode of rounds it counts for each player who played half its rounds
or more to their end (Roster's `rounds`), so joining near the end isn't a match played; in the
others for everyone in it then. A draw is a Team Deathmatch ended level; in deathmatch the winner
won and everyone else lost. Leaving a Competitive match under way, once a round of it's been played
to its end, is a loss as the match stands: the reference says leaving costs RR without saying how
much, and ours is the loss alone, as rejoining after a dropped connection isn't in yet. A match
ended by turning the arena off counts for nobody.

### Keeping it

`CareerServer` keeps each player's career in the data store `VFCareer1`, a key each. A player's part
in a match is added at once to the career their screen shows, and then to the store's with
`UpdateAsync`, which adds it to whatever's there: written from two servers, as a player moves
between modes' servers, nothing's lost. Each result has an id, and the store keeps the last 16, so a
write retried after it went through counts once. Writes go at most every 6 s, the store's limit for
a key; one that fails is tried twice more before the session's career stops being kept. A read that
fails keeps the session's results out of the store, as what it holds is unknown. A player who leaves
is kept 10 s more for the arena's word on a match they left, and until what's theirs is written, and
the server closing writes everything still to write.

### On screen

Competitive's victory screen has a line under the time left: the rank, its RR and the RR the match
was worth (`GOLD 2 64 RR (+18)`), or a promotion or placement in green, a demotion in red, a shield
used, or the placements played (`PLACEMENT 3 OF 5`). Nothing shows when the match didn't count. Each
Play menu card has the player's record in its mode (`7W 4L 1.40 K/D`), and Competitive's has the
rank or the placements played.

### Not in yet

- Acts and episodes: a player is placed once and the rank never resets, where the reference has 5
  placement matches at the start of Act 1 and Act 4, and 1 at the others.
- Radiant's top 500 of a region: there's no leaderboard, and the thresholds are one region's.
- Overtime's vote to draw (system 13), so nothing ends drawn and a draw's RR is never given.
- Matching by rank: everyone on a server plays together, whatever their ranks.
- The rank on the scoreboard, and the ranks' icons.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Career/RankConfig.luau` | The tiers, the rules' numbers with their sources, bots' MMRs, the attributes |
| `src/shared/Career/RankRules.luau` | The MMR, placements, what a match is worth, promotions, demotions, shields and Immortal; the rank in words |
| `src/shared/Career/CareerRules.luau` | Each player's part in a match, which matches count, a leave, the totals, results by id, the store's format and the line for clients |
| `src/server/CareerServer.luau` | The data store, each player's attributes, results added at once and written |
| `src/server/Arena.luau` | A match won and a Competitive leave go to `CareerServer`; `VFMatchDecide` |
| `src/shared/Match/MatchRules.luau`, `src/shared/Match/MatchConfig.luau` | `decide` and `VFMatchDecide`, for checks |
| `src/client/Scoreboard.luau` | The rank on Competitive's victory screen |
| `src/client/PlayMenu.luau` | Each card's record, and Competitive's rank |
| `tests/rank.luau` | 75 checks |
| `docs/studio-checklist.md` | Section 71 |

## 7. Debug tools

- Each player's `VFRankTier` (0 while placing, else the tier's number in `RankConfig.Tiers`),
  `VFRankRR`, `VFRankGames`, `VFRankShields`, `VFRankLast` (the RR the last match was worth, if it
  counted), `VFRankNote` (`placed`, `promoted`, `demoted` or `shielded`), `VFCareer` (the totals)
  and `VFCareerStatus`; in Studio also `VFRankMmr`.
- In Studio each result prints a line: `[VF] career: <UserId> <mode> <result> <RR> <note>; <rank>,
  MMR <MMR>`.
- `VFMatchDecide`, set from the server to 1 or 2 in the spike rounds: the round under way goes to
  that side, its buy phase too.

## 8. Refinement loop

1. Play Competitive with friends and bots, and watch what each match is worth, on the victory screen
   and in Studio's printed lines.
2. Tune `RankConfig.Rules`' estimates (`base`, `gapRR`, `perfScale`, `marginMax`, `underdogMax`,
   `k`, `overMmr`) or the bots' MMRs, and re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Placements, a ranked match's RR, a promotion and a demotion or a shield, on the victory screen.
- Each mode's record and Competitive's rank on the Play menu.
- Leaving Competitive under way counted as a loss.
- The data store: a career kept from one session to the next, and written once.

Section 71 of the [Studio checklist](../studio-checklist.md) covers these.
