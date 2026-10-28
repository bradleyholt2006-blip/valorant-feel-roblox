# System 55: The kill banner and multi-kill counter

In the reference, each kill brings up a banner for the player who made it: Patch 1.02 has
"multi-kill streak banners", and the banner "reflects the number of kills" (Sportskeeda). Since
Patch 6.05 a headshot no longer adds text under it; the kill logo has "a little red X" instead
(EsportsDriven). A kill sound plays with it, higher with each kill in skins' versions. Skins have
their own banners, the same size for every kill: Patch 10.09 fixed some that appeared "smaller than
normal after the first kill". Until now ours had none of it. A kill showed in the kill feed, and a
gun's or a knife's kill played the kill sound, higher with each kill of a life. This system adds the
banner. The server counts each player's kills of enemies, by the round in Skirmish and the spike
rounds and by the life elsewhere, and tells the killer alone of each, with its number, who was
killed and whether it was a headshot. A banner then comes up low in the middle of the screen. It has
a diamond with the kill's number in it and a mark lit for each kill up to the fifth, gold from the
fifth on, with a red X beside it for a headshot and the name of whoever was killed under it. It
comes up a little bigger and settles, shows whole for 1.5 s and fades over 0.5 s. The kill sound now
plays with it, an ability's kills too, rising with the banner's count, so it starts over each round
in the rounds.

As before, everything comes from public sources: Riot's patch notes (1.02, 3.07, 3.12 and 10.09)
and, for what Riot doesn't give, the press (The Loadout, EsportsDriven, Dot Esports, Sportskeeda,
Wired Consumer and GamesKeys). No game files, memory or network traffic were used, and nothing was
read from the live game. Riot gives that the banners count multi-kills, that skins have their own,
that they carry a wide player card and that every kill's is the same size; the press gives the logo,
the red X and why the headshot text went, how skins' banners and sounds rise with each kill, and
what an ace is. Nothing in this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide or the press, not by the maker |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source we could read says where on the screen the banner is, how long it shows, how it comes and
goes, or whose player card it carries. Ours, in section 4: low in the middle, its middle 240 px up
from the bottom; coming up at 1.3 times its size and settling over 0.15 s; whole for 1.5 s and
fading over 0.5 s; and the name of whoever was killed in place of a card. The reference's banners
are Riot's art (a skull, or an X, and each skin's own), so ours is drawn from plain frames.

## 1. Observable behaviour

- **A banner for each kill** (Riot and the community). Patch 1.02: "Optimized multi-kill streak
  banners." Sportskeeda, of skins' banners: "Interestingly, upon each kill, the octane goes higher
  as the banner reflects the number of kills."
- **Up to an ace, and past it** (the community). Sportskeeda: an ace "requires a single player to
  eliminate every Agent on the enemy team"; of one skin, "the penta-kill is one of the best Ace
  sounds in the game"; of another, "The Ace and Overkill sound effects are very similar but also
  beautifully crafted nonetheless." Five kills by one player in a round of five against five are the
  enemy side's every Agent, so the fifth kill's banner and sound are an ace's; a kill past it, after
  Sage's Resurrection brings someone back, is past the ace (our reading).
- **The same size every kill** (Riot). Patch 10.09: "Fixed a bug where Kill Banners for certain
  skins (Oni, Evori Dreamwings, EX.O, Prelude to Chaos, Mystbloom, and more) were appearing smaller
  than normal after the first kill."
- **A player card on it** (Riot). Patch 3.12: "After community feedback, we are bringing back the
  Wide Player cards that are shown during the Loading Screens and in the kill banners."
- **The headshot mark** (the community). The Loadout: Riot "removed the text denoting when a
  headshot's secured from the game's kill banners", in Patch 6.05, leaving "the red 'X' on the kill
  banner itself, and of course the kill feed". Riot's Preeti Khanolkar, quoted there: the text was
  "clutter in a space where visual clarity is key". EsportsDriven: the text was "under the kill
  banner which you get in case your kill was a headshot", and a headshot shows "by looking at the
  kill feed or the kill logo which will have a little red X". Dot Esports dates it "mid-way through
  March 2023": "the headshot text just felt extra without adding more value".
- **The kill sound rising** (the community). Sportskeeda, of skins' kill sounds: Reaver's sounds
  "are marked by a haunting bell that progressively increases in pitch with each kill", and Prelude
  to Chaos's guitar riffs "slowly rise with each kill".
- **Skins' own** (Riot). Patch 1.02: "It's fixed now, so go ahead and upgrade that baby and enjoy
  your custom effects, finisher, kill banner, and variants!"
- **The kill logo** (the community). Wired Consumer: "Instead of the usual skull logo, the game will
  now show you an X logo in the same pop-up as before whenever you kill an enemy in the game."
  GamesKeys, of the "Show Mature Content" setting: "You have to turn this option off.", and then
  "your kill icon will be changed in your next match."
- **Practice bots** (Riot). Patch 1.02: "Jett: Killing practice bots now properly refreshes Blade
  Storm".

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Optimized multi-kill streak banners."; "It's fixed now, so go ahead and upgrade that baby and enjoy your custom effects, finisher, kill banner, and variants!"; "Jett: Killing practice bots now properly refreshes Blade Storm" | [VALORANT Patch Notes 1.02](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-02/), 23 June 2020 |
| "Fixed a bug where Team Ace could be awarded in scenarios where it wasn't earned by the team (we still respect teamwork!)." | [VALORANT Patch Notes 3.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-07/), 5 October 2021 |
| "After community feedback, we are bringing back the Wide Player cards that are shown during the Loading Screens and in the kill banners." | [VALORANT Patch Notes 3.12](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-12/), 7 December 2021 |
| "Fixed a bug where Kill Banners for certain skins (Oni, Evori Dreamwings, EX.O, Prelude to Chaos, Mystbloom, and more) were appearing smaller than normal after the first kill." | [VALORANT Patch Notes 10.09](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-10-09/), 13 May 2025 |

### From the community

| What | Source |
| --- | --- |
| Riot "removed the text denoting when a headshot's secured from the game's kill banners"; "the red 'X' on the kill banner itself, and of course the kill feed"; "clutter in a space where visual clarity is key" | [The Loadout, on the headshot text](https://www.theloadout.com/valorant/headshot-text-removed), Aaron Down, 21 March 2023 |
| "under the kill banner which you get in case your kill was a headshot"; "by looking at the kill feed or the kill logo which will have a little red X" | [EsportsDriven, on the headshot text](https://esportsdriven.com/valorant/news/683/riots-controversial-secret-change), Wei, 22 March 2023 |
| "mid-way through March 2023"; "the headshot text just felt extra without adding more value" | [Dot Esports, on why the headshot text went](https://dotesports.com/valorant/news/why-was-the-valorant-headshot-banner-removed), Harrison Thomas |
| "Interestingly, upon each kill, the octane goes higher as the banner reflects the number of kills."; an ace "requires a single player to eliminate every Agent on the enemy team"; "the penta-kill is one of the best Ace sounds in the game"; "The Ace and Overkill sound effects are very similar but also beautifully crafted nonetheless." | [Sportskeeda, on skins' ace effects](https://www.sportskeeda.com/valorant/top-5-valorant-skin-collections-best-ace-effects) |
| "Instead of the usual skull logo, the game will now show you an X logo in the same pop-up as before whenever you kill an enemy in the game." | [Wired Consumer, on the kill icon](https://www.wiredconsumer.com/how-to/change-valorant-kill-icon/), 11 March 2023 |
| "You have to turn this option off."; "your kill icon will be changed in your next match." | [GamesKeys, on the kill icon](https://gameskeys.net/how-to-change-the-kill-icon-in-valorant/), 23 January 2024 |
| "The sounds are marked by a haunting bell that progressively increases in pitch with each kill."; "slowly rise with each kill" | [Sportskeeda, on skins' kill sounds](https://www.sportskeeda.com/valorant/5-valorant-skins-best-kill-sounds) |

## 3. What can be measured, and how

| What | How |
| --- | --- |
| Where the banner is, its size, and how far it is from the ability bar | Public clips of a round's kills, at a known resolution |
| How long it shows, and how it comes and goes | Public clips of single kills, frame by frame |
| What changes on it from one kill to the next, and at the fifth and past it | Public clips of aces, and of a sixth kill after Sage's Resurrection |
| Whether its count goes by the life in Deathmatch and Team Deathmatch | Public clips of a Deathmatch life with more than five kills, and of a death in it |
| How much the kill sound rises from each kill to the next | Public clips of the default kill sound over several kills, pitch-tracked |
| Whether the dead see a banner for a kill their utility makes | Public clips of a kill by a fire after its thrower died |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| A banner for each kill | Each kill of an enemy brings up a banner for the player who made it, with its number: which of their kills it is | Confirmed (Patch 1.02: "multi-kill streak banners"); community (the banner "reflects the number of kills", Sportskeeda) |
| Which kills | A kill of an enemy, an ability's too; not a teammate, not yourself, and not a death nobody caused (the spike's blast, a spawn room's burn). A practice dummy's counts | Estimate; a practice bot's kill counts for Jett's Blade Storm (Patch 1.02) |
| Its count | Over the round in Skirmish and the spike rounds, through a life Sage's Resurrection starts; over the life elsewhere, and while a match waits for an opponent. It starts over as a round starts, or a mode | Community (the fifth kill's is a five-player side's ace, which is a round's, Sportskeeda); estimate (by the life elsewhere) |
| Up to the ace, and past it | A mark lit for each kill up to the fifth; from the fifth on all of them, the diamond, its number and the marks gold | Community (the ace's and past it, an "Overkill", have their own sounds, Sportskeeda); estimate (the marks and the gold) |
| Its look | A diamond with the kill's number, the marks under it, and under them the name of whoever was killed in the enemy colour | Estimate; the reference's is Riot's art, a logo (a skull, or an X, Wired Consumer) with a wide player card (Patch 3.12) |
| A headshot | A little red X off the diamond's top right edge, for a kill whose hit struck the head, as the kill feed's `HS` | Community ("the kill logo which will have a little red X", EsportsDriven); no headshot text since Patch 6.05 (The Loadout) |
| Its size | The same for every kill | Confirmed (Patch 10.09: banners "smaller than normal after the first kill" were a bug) |
| Where | Low in the middle, its middle 240 px up from the bottom, clear of the ability bar | Estimate |
| How it comes and goes | Up at 1.3 times its size, settling over 0.15 s; whole for 1.5 s after its kill, then fading over 0.5 s; the next kill's takes its place at once | Estimate |
| Who's told | The killer alone, by the server, as the kill lands | Estimate (ours: it's their HUD's) |
| The kill sound | With each banner, the library's bell, played 0.06 faster for each kill after the first up to the fifth, and no faster past it (system 8's `KillPitchStep`) | Community (skins' kill sounds rise with each kill, Sportskeeda); estimate (the step, and the default's rising) |

## 5. Design

### The rules

- **`KillBanner`** (new) has the rules, with no Roblox APIs: `counts` says whether a kill counts;
  `killed` counts it for its killer and gives its banner (its number, who was killed, and whether it
  was a headshot); `open` starts a life's count and `clear` everyone's; `count` reads one; `marks`
  and `top` say how many marks a banner lights and whether it's the top one; and `alpha` and `scale`
  say how solid and how big a banner draws as it ages.

### The server

- **`CombatServer`** tells its kill listeners the part the killing hit struck (`"body"` for a burst
  or a burn), as the kill feed has it.
- **`BannerServer`** (new) counts each player's kills from the kill listeners and sends each kill's
  banner to its killer alone with the `Banner` remote. It starts a player's count over at each spawn
  unless the count goes by the round.
- **`Arena`** starts everyone's count over as a round starts and as a mode starts or stops, and says
  when counts go by the round (`BannerServer.byRound`, as the combat report's).
- **`Remotes`** has `Banner`.

### The client

- **`KillBannerView`** (new) draws the banner from the `Banner` remote (`VFKillBanner`) and plays
  the kill sound with it.
- **`GameSounds`** plays the kill sound for the banner (`playKill`), at its count's pitch, and no
  longer counts kills of its own: before, a gun's or a knife's kill played it, rising over the life.

### Not here yet

- **Round awards.** The reference ends a round naming an ace, and a Team Ace (Patch 3.07 fixed one
  "awarded in scenarios where it wasn't earned by the team"). Ours has the ace's banner alone, and
  nothing at a round's end.
- **Riot's look.** The reference's banners are Riot's art, its logo (a skull, or an X) and each
  skin's own, with a wide player card; none is copied. Plain frames stand in, and the name for the
  card.
- **Skins.** Skins' banners and kill sounds are their own; ours has one of each.
- **Spectating.** Spectate's view of a teammate shows none of their banners.
- **Where it is, and how long.** No source we could read gives them; they're ours, to set from
  clips.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Combat/KillBanner.luau` | New: the rules: which kills count, each killer's count and starting it over, a banner's number, headshot, marks and top, and how it comes up and fades |
| `src/server/BannerServer.luau` | New: everyone's count, and each kill's banner to its killer with the `Banner` remote |
| `src/server/CombatServer.luau` | The part the killing hit struck, to the kill listeners |
| `src/server/Arena.luau` | Counts started over with each round and mode, and by the round in the rounds |
| `src/server/init.server.luau` | `BannerServer` started |
| `src/shared/Net/Remotes.luau` | `Banner` |
| `src/client/KillBannerView.luau` | New: the banner, its kill sound, and `VFKillBanner` |
| `src/client/Audio/GameSounds.luau` | The kill sound played for the banner (`playKill`), no longer from a gun's or a knife's kill |
| `src/shared/Audio/SoundConfig.luau`, `src/shared/Audio/SoundMath.luau` | The kill sound's pitch, by the banner's count |
| `src/client/init.client.luau` | `KillBannerView` started |
| `tests/killbanner.luau`, `tests/run.luau` | New: 27 checks: which kills count, each killer's count, starting it over by the life and by the round, the headshot mark, marks and the top banner, how a banner comes up and fades, and the kill sound rising with the count up to the ace's |
| `tests/sound.luau` | The kill sound's check, for each kill counted rather than each of a life |

## 7. Debug tools

- PlayerGui's `VFKillBanner` carries `Count` (the latest banner's number, 0 before one), `Marks`
  (the marks it lit), `Headshot`, `Victim` (whose kill it was), `Pitch` (its kill sound's playback
  speed) and `Shown` (whether a banner's up).
- The Sound Lab's log lists each `kill` sound as it plays.

## 8. Refinement loop

1. From public clips of a round's kills, set where the banner is, its size, how long it shows, and
   how it comes and goes.
2. From public clips of aces and of a sixth kill, set what changes at the fifth and past it.
3. From public clips of a Deathmatch life, check whether its count goes by the life.
4. From public clips of the default kill sound over several kills, set `KillPitchStep`.
5. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- A kill of a dummy on the course: the banner low in the middle with 1 in it and a mark lit, the
  dummy's name under it, and the kill sound; whole for 1.5 s, then fading.
- More kills in a life: each banner's number one more, the kill sound higher each time up to the
  fifth, and gold from the fifth.
- A headshot kill: the little red X; none for a body shot.
- A new life on the course: the count from 1 again.
- An ability's kill: a banner and the kill sound, as a gun's.
- In Skirmish: the count over the round, and from 1 again in the next.
- Only the killer seeing it.

Section 59 of the [Studio checklist](../studio-checklist.md) covers these.