# System 14: The economy

In the reference's main mode, everything in the buy menu costs credits. Each side starts each half
with 800, enough for a pistol or a light shield. After that, every round pays both sides as the next
one starts: a win pays well, and a loss pays less, but more for each loss in a row. Kills and the
spike's plant pay as they happen, and nobody can hold more than a cap. Overtime starts everyone on
the same credits each round. Most of a team's decisions come from this: when to save, when to
force-buy, and when to buy a full kit. This system adds credits to the spike rounds (system 13), has
the buy menu charge them, and lets a round's survivors keep their shield, damaged as it was. Skirmish
and the course stay free: they have no economy in the reference either.

As before, everything comes from Riot's patch notes and from community wikis and guides. No game
files, memory, network traffic or protected assets were used, and nothing reads the game while it
runs. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source |

## 1. Observable behaviour

- The buy menu shows your credits. Anything you can't afford is greyed out.
- Each half starts everyone on 800, with the Classic and the knife and no shield. That's the pistol
  round.
- A round's result is paid as the next round's buy phase starts. The winners get 3000. The losers
  get 1900 for a first loss in a row, 2400 for a second, and 2900 for a third or more. A win resets
  the side's streak.
- Losing and surviving pays less. An attacker who lives through a lost round without the spike being
  planted gets 1000, not a loss. So does a defender who lives through the spike going off. This
  stops a side hiding and saving its guns for free.
- A kill pays its killer 200 at once. The plant pays every attacker 300, dead or alive.
- Nobody holds more than 9000.
- In overtime, every round starts everyone on 5000.
- Swiftplay pays a schedule of its own, and has no loss streak.
- Selling back something bought this buy phase refunds its price. A gun or shield bought over one you
  bought this buy phase refunds that one.
- Surviving keeps your guns and shield into the next round, the shield as damaged as it was. Dying
  loses them.

## 2. Publicly documented details

### From Riot

- **The half's credits.** Patch 1.0: "the 800 you receive on side swap rounds", while discussing
  "the credit cap". ([Patch 1.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-0/))
- **Survivors of a lost round.** Patch 1.11: "Attackers who lose but survive the entire round
  without planting the Spike receive a reduced number of credits (1,000)", and "Defenders who lose
  but survive the entire round after the Spike has detonated also receive reduced credits (1,000)".
  ([Patch 1.11](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-11/))
- **Overtime.** Patch 1.03, for Competitive's win-by-two overtime: "Each round will have a full
  reset, setting all players at 5000 credits and 4 points short of their ultimate".
  ([Patch 1.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-1-03/))
- **Skirmish has no economy.** Patch 12.03: "full weapon selection each round" (from
  [07-arena.md](07-arena.md)). That's why Skirmish stays free here.

Riot doesn't publish the win, loss, kill and plant amounts in the notes we found. They come from
the community, below, where every source agrees.

### From the community

| What | Value | Sources |
| --- | --- | --- |
| A round won | 3000 | [Mobalytics' economy guide](https://mobalytics.gg/blog/valorant/ultimate-economy-guide/): "a round win will always give $3000"; [ONE Esports](https://www.oneesports.gg/valorant/valorant-economy-guide-how-to-earn-credits-and-what-to-buy-with-them/) (June 2023); [Turbosmurfs](https://turbosmurfs.gg/article/valorant-economy-guide) |
| A round lost | 1900, then 2400, then 2900 for the third loss in a row and more | Mobalytics, ONE Esports, Turbosmurfs, [valohub](https://valohub.co/guides/valorant-economy-guide) |
| The streak's reset | A win resets it | Turbosmurfs: "it resets to 1,900 the moment you win a round"; valohub agrees |
| A kill | 200 | Mobalytics: "$200 is given for a kill" |
| The plant | 300 to every attacker | Mobalytics: "the entire attacking team will gain $300 for planting the spike" |
| The cap | 9000 | Mobalytics: "the credit cap of $9000" |
| Unrated's Endgame | 5000 | The Valorant Fandom wiki's Unrated page |
| Dying | Lose your guns and shield | [Hotspawn](https://www.hotspawn.com/valorant/guide/how-to-manage-the-valorant-economy): "If you die the previous round, you will lose any purchased weapons and armor" |
| Surviving | Keep them, the shield as damaged | Hotspawn: "Even if you survive, you may still have to repurchase armor if you took damage" |
| The Regen Shield's pool | Carries over between rounds and doesn't refill | Beebom, in [09-arsenal.md](09-arsenal.md): the pool "carries over but does not replenish between rounds" |
| A defuse | 300? | Only [wecoach](https://wecoach.gg/blog/article/a-detailed-guide-for-mastering-the-valorant-economy) says so. The other guides list the plant and not the defuse, so we pay nothing for it |

**Swiftplay.** The [VALORANT Wiki's Swiftplay page](https://wiki.playvalorant.com/en-us/Swiftplay)
says: "No credit bonuses for loss streaks", and "Credits earned based on round outcome have adjusted
values and are the same for both teams, with the exception of round 2". Its table, by round:

| Round | Credits |
| --- | --- |
| 1 | 800 |
| 2 | +2400, and a "+600 bonus if team won previous round" |
| 3 | +4250 |
| 4 | +4250 |
| Endgame | 5000 |

[Turbosmurfs](https://turbosmurfs.gg/article/valorant-economy-guide) gives the same figures. We read
the table as each half's rounds: Swiftplay swaps sides after round 4, and round 5 starts the second
half over on 800 like any half.

## 3. What can be measured, and how

All of this can be checked by watching public footage of a match with the buy menu or the
scoreboard in view, writing down each player's credits at the start of each buy phase, and adding up
what they did in the round before. Nothing needs to be read from the game.

| What | How |
| --- | --- |
| Win, loss and streak amounts | A side's credits from one buy phase to the next, with nothing bought |
| The survivor's 1000 | An attacker who hid through a lost round with no plant, and a defender who lived through a detonation |
| Kill and plant pay | The credits jump in the round, as the kill or the plant happens |
| Kills after the round's end | Whether a kill in the post-round phase pays. We don't pay it (estimate) |
| When "surviving" is judged | An attacker who lives through the clock running out and is then hunted down in the post-round phase: 1000 or a full loss? We pay a full loss (estimate) |
| Swiftplay's schedule | The same as above, in a Swiftplay match |

## 4. Confirmed vs estimated, as implemented

All of these are in `MatchConfig.Credits` and `MatchConfig.Swiftplay`, each with its status and
source.

| Rule | Ours | Status |
| --- | --- | --- |
| Each half's start, and the match's | 800 for everyone, and no streak | Confirmed (Patch 1.0, for the half) |
| A round won | +3000 | Community |
| A round lost | +1900, +2400, +2900 and on | Community |
| A loss survived | +1000 in place of the loss: an attacker alive with no plant, a defender alive after the spike went off | Confirmed (Patch 1.11) |
| When "alive" is judged | As the next round starts, so the blast's victims and anyone killed in the post-round phase lost their lives | Estimate |
| A kill | +200 to the killer, for an enemy, while the round is live or planted | Community; only in the round is an estimate |
| The plant | +300 to every attacker, alive or dead | Community |
| A defuse | Nothing | Estimate (one guide says 300) |
| The cap | 9000 | Community |
| Overtime | Everyone on 5000, every round | Confirmed (Patch 1.03) |
| Swiftplay | 800, then +2400 (+600 to the winners), +4250, +4250 a half, 5000 for the Endgame, and no streak | Community |
| Swiftplay's kills and plant | Paid as the standard match's | Estimate (the wiki only says the round's result pays differently) |
| Someone joining mid-match | 800, or 5000 in overtime | Estimate |
| A round started again after a wait | Pays nothing for the round cut short | Estimate |
| While waiting for an opponent | Purchases cost credits, as in a round | Estimate |
| What a purchase costs | Its price, less the price of what you bought for its slot this buy phase | Community (the reference's menu) |
| Selling back | Refunds the price, for what the slot began the buy phase with | Community (as system 9) |
| A survivor's shield | Kept into the next round as damaged as it was, with the Regen Shield's pool | Community (Hotspawn, Beebom) |
| A damaged shield bought again | A fresh one, at its full price, and it sells back for the damaged one | Community for the Regen Shield, estimate for the others (as 09-arsenal.md) |
| A gun sold back to an empty slot | The slot empties, and you're handed the next gun you have | Community (the reference's menu) |
| The debug keys 5 to 9 | Still give guns for free during the buy phase (Studio or the place owner) | Ours, for testing |

## 5. Design

### Credits as plain state

`MatchRules` from system 13 keeps the economy as well, so the offline tests can play it. Each member
has `credits`, each side a `streak` of rounds lost in a row, and the state remembers whether the spike
was planted this round (`spikePlanted`). Everything's paid in one of four places:

- `join` gives the newcomer the starting credits, or overtime's in overtime.
- `died(s, id, now, killer)` pays the killer 200 if they're on the other side and the round is
  live or planted.
- `planted` pays every attacker 300.
- `startRound` calls `payFor` before moving on to the next round. That function does one of two
  things. If the next round starts a half or is in overtime, it sets everyone's credits and clears
  the streaks. Otherwise it pays for the round just played, by the match's `economy`:
  - **standard:** the winners get a win. Each loser gets a loss for their side's streak, or 1000 if
    they survived on the losing terms. The winners' streak goes to 0 and the losers' goes up by one.
  - **swiftplay:** everyone gets the schedule's amount for that round of the half, plus the bonus to
    the winners in round 2.

`MatchRules.payout(format, round, streak)` gives what a round pays its winners and losers. It's a
pure function, so the buy menu uses it too, to show what's at stake. `MatchRules.spend` takes
credits for a purchase, or gives them back for a refund. It refuses to spend more than someone has.

Paying at the next round's start, not at the round's end, means "survived" is judged after the
spike's blast. The spike's server reports the detonation before the blast kills anyone near it, so
judging at the round's end would count the blast's victims as survivors.

### The buy menu's prices

`Shop.cost(s, item)` is the price less the refund of what was bought for its slot this buy phase.
Buying back what the slot began the phase with refunds what replaced it and charges nothing.
`Shop.refund` is what selling refunds. Both are shared, and so is how the client copies the state:

- The server publishes the bought list (`VFBought`, from system 9) and what each slot held before
  (`VFBoughtOver`).
- The client rebuilds the state from the two (`Shop.fromLists`) and prices every tile exactly as
  the server will. A test checks that the two agree on every item.

`ShopServer` charges through a hook, `ShopServer.pay(player, amount)`, which the arena sets. In the
spike rounds it calls `MatchRules.spend`. Anywhere else the hook is free. A purchase happens only if
it's paid for. A damaged shield bought again is a renewal (`Shop.renew`), recorded so it can be sold
back.

### Shields between rounds

`PlayerSimServer.keepShields` is on in the spike rounds. A new life that keeps the last one's kit
(a survivor's) keeps its shield's points and the Regen Shield's pool (`Health.keep` and
`Health.restore`). Before this, every new life got a fresh shield. Skirmish still does, as the
reference does.

The buy menu has to respect a damaged shield too. Otherwise buying Heavy Armor and selling it back
would hand you a fresh Light Armor for free. `ShopServer` keeps the shield as it was when the buy
phase first changed it, and puts it back as it was whenever the slot goes back to it.

### A gun sold back to nothing

System 9 couldn't empty a slot, so a gun bought into an empty slot couldn't be sold back. With credits
at stake, that would cost you its whole price. `PlayerSimServer.give` now takes "" for the primary or
sidearm slot. `WeaponSim.give` moves the hand to the next slot with something in it and draws it, so
the owner's prediction does the same once the ack arrives.

### Who's told what

| Attribute | Where | What |
| --- | --- | --- |
| `VFCredits` (`MatchConfig.CREDITS`) | Each player | Their credits, while the spike rounds are on |
| `Streak1`, `Streak2` | The arena's model | Each side's losses in a row, for the menu's stakes |
| `VFBoughtOver` (`Shop.BEFORE_ATTRIBUTE`) | Each player | What each slot bought into held before, in `VFBought`'s order |

The buy menu shows `<credits> CREDITS` and what the round pays: `WIN +3000   LOSE +1900`, or `THIS
ROUND PAYS +4250` when both sides get the same. The last round of a half shows neither, since the
next round starts over. Tiles you can't afford are dimmed, with their price in red. The hover panel
says what something costs when that isn't its price, and what selling it refunds. The arena HUD adds
your credits, in gold, to the buy phase's line.

### Not here yet

- **Dropping and picking up guns.** In the reference, a gun replaced in the buy menu or dropped by
  someone who dies lies on the ground for anyone to take. That's how teammates buy for each other
  and how a side takes the other's guns. Here, a replaced gun is gone. That needs drops, a later
  system.
- **Buying for a teammate**, which needs drops.
- **Ultimate points**, and the credits for agents' abilities. There are no agents yet.
- **A defuse bonus.** Most guides don't list one.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Match/MatchConfig.luau` | `Credits`, `Swiftplay`, each format's `economy`, `CREDITS` |
| `src/shared/Match/MatchRules.luau` | Each member's credits and each side's streak, `payout`, `payFor`, `credits`, `spend`, kill and plant pay |
| `src/shared/Weapons/Shop.luau` | `cost`, `refund`, `renew`, `beforeList`, `fromLists`, `BEFORE_ATTRIBUTE` |
| `src/shared/Combat/Health.luau` | `keep` and `restore`: a shield's points and pool, put back |
| `src/shared/Weapons/WeaponSim.luau` | `give` with "": the hand moves to the next slot |
| `src/server/ShopServer.luau` | The `pay` hook, the shield as it was, renewals, a gun sold back to nothing |
| `src/server/PlayerSimServer.luau` | `keepShields`, death listeners told the killer, `give` that empties a slot |
| `src/server/CombatServer.luau` | `setShield` with a kept shield |
| `src/server/Arena.luau` | `ShopServer.pay`, kills paid to the killer, `keepShields`, `VFCredits`, `Streak1`/`Streak2` |
| `src/client/BuyMenu.luau` | Credits, the round's stakes, dimmed tiles, costs and refunds |
| `src/client/ArenaHud.luau` | Credits in the buy phase's line |
| `tests/economy.luau` | 80 checks: pay, streaks, survivors, kills, the plant, the cap, halves, overtime, Swiftplay, spending, costs, kept shields |

## 7. Debug tools

- The buy menu (B) shows your credits and what the round pays, all the time in the spike rounds.
- `VFCredits` on each player, and `Streak1` and `Streak2` on the arena's model, can be read in the
  Properties window or from the command bar.
- `VFMatchSkip` (system 13) still ends any phase, so the payouts can be checked without playing the
  rounds out.
- The debug keys 5 to 9 still give guns for free, for trying a gun in the spike rounds without the
  credits.

## 8. Refinement loop

1. Watch a public match, with the buy menu or scoreboard in view. Note each player's credits at the
   start of each buy phase, and what happened in the round before.
2. Compare with ours, round by round, using the HUD and `VFCredits`.
3. If a number differs, change it in `MatchConfig.Credits` with its source and status, and the
   tests follow it.
4. The two open questions are worth watching for: whether a kill in the post-round phase pays, and
   whether someone hunted down after the clock runs out counts as surviving.

## Known gaps to check in Studio

- The buy menu's credits, stakes and dimmed tiles, and the hover panel's costs and refunds.
- Charging, refunds, buying back and selling back to nothing, all in a real buy phase.
- A shield carried damaged into the next round, the Regen Shield's pool with it, and renewing it.
- Kill pay with two players, and the plant's pay.
- The payouts over a few rounds, and the half's and Swiftplay's reset.

Section 18 of the [Studio checklist](../studio-checklist.md) covers these.
