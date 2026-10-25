# System 9: The full arsenal and the buy menu

This covers every gun the reference sells and the knife, with each one's way of firing: semi and
automatic fire, bursts while aiming down sights, the Classic's three-bullet right click, shotgun
pellets, shell-by-shell reloads, the Odin's rising fire rate and every scope. It also covers the
three shields and the buy menu that sells all of it. The knife's attacks are
[system 10](10-knife.md); abilities, dropping and picking up weapons, and the standard mode's
economy are separate work.

As before, everything comes from Riot's patch notes and from community stat sites and wikis. The
main community source is the VALORANT Wiki at wiki.playvalorant.com, run by Weird Gloop and not
by Riot; its weapon pages give each gun's stats, spread table and movement penalties, and agree
with metabot.gg's stat pages wherever both give a number. No game files, memory, network traffic
or protected assets were used. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number. It must be measured and tuned before we trust it |

## 1. Observable behaviour

- Twenty guns in six groups, plus the knife. Sidearms: Classic, Shorty, Frenzy, Ghost, Bandit and
  Sheriff. SMGs: Stinger and Spectre. Shotguns: Bucky and Judge. Rifles: Bulldog, Guardian,
  Phantom, Vandal and Warden. Snipers: Marshal, Outlaw and Operator. Machine guns: Ares and Odin.
  You carry one primary (anything but a sidearm), one sidearm and the knife.
- Each gun has a price in credits. The Classic is free and everyone has one.
- Some guns fire once per click (the Shorty, Ghost, Bandit, Sheriff, Bucky, Guardian and the
  snipers), the rest while the trigger is held.
- Right click does something different on each gun:
  - most primaries and the heavier guns zoom in (aim down sights), shooting a little tighter and
    moving slower;
  - the Stinger and the Bulldog fire short bursts while zoomed;
  - the snipers and the Warden have scopes, and the Operator has two zoom levels;
  - the Classic fires three bullets at once, like a tiny shotgun;
  - the Bucky fires a canister that bursts into pellets a few metres out;
  - the Odin fires at its full rate straight away;
  - the knife has a heavier stab;
  - the other sidearms and the Judge have no right click.
- Shotguns fire a spread of pellets, each doing its own damage. The Bucky and the Marshal reload
  one round at a time, and the Outlaw takes longer to reload two rounds than one.
- The Odin fires faster the longer you hold the trigger. The Ares used to as well, but no longer.
- Three suppressed guns, the Ghost, Spectre and Phantom, are quieter and hide their tracers from
  enemies.
- The buy menu opens with B during the buy phase. It shows every gun and shield with its price.
  Clicking one buys it and puts it in your hands. Right-clicking something you bought this buy
  phase sells it back.
- Three shields: Light Armor (25), Heavy Armor (50) and the Regen Shield (25 that refills twice
  from a pool of 50). The Regen Shield takes every point of damage until it's gone; the other two
  take about two thirds and let a third through to health.
- In Skirmish, the arena's mode (system 7), nothing costs anything and everyone starts every
  round in Heavy Armor.

## 2. Publicly documented details

### From Riot

| Fact | Status | Source |
| --- | --- | --- |
| The Bandit: "a precision sidearm with 1-tap headshot power"; Sidearm, 600 credits, no attachments, 8 rounds, 24 in reserve, reload 1.5 s, equip 0.75 s, Medium wall penetration | Confirmed | [Patch 12.00](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-12-00/) |
| The Warden: "the latest automatic Rifle to join the Vandal and Phantom in the 2900 credits tier"; a scope at 2x; 18 rounds, 36 in reserve; "50 at all ranges", "200 headshot", "42 leg"; fire rate 6.5; reload 2.5; equip "Normal: 1.0, Fast: .6, Instant .2"; Medium wall penetration | Confirmed | [Patch 13.06](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-13-06/) (22 September 2026) |
| The Outlaw after its first shot: recovery 0.1 → 0.15, spread 0 → 2.25, recoil 0 → 4.0 | Confirmed | [Patch 13.01](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-13-01/) |
| "The speed of equipping your weapon after unequipping Double Tap is now instant" (Iso) | Confirmed | The same notes |
| Reserves: "Vandal Reserve ammo adjusted from 75 >>> 50", "Phantom Reserve ammo adjusted from 90 >>> 60", Shorty 10 → 6; Shorty price 150 → 300 and pellet damage 12 → 11 (no falloff), 8 → 6 (first falloff); Frenzy "Min spread increased from .45 >>> .65" | Confirmed | Patch 6.11, quoted by [PCGamesN](https://www.pcgamesn.com/valorant/patch-notes-6-11) |
| The Regen Shield: 650 credits, "Damage Absorption: 25 HP", "Regeneration Pool: 50 HP", "Absorbs 100% of incoming damage taken before damage to health occurs", "After a brief delay, the shield regenerates by draining any remaining points left in the Regeneration Pool" | Confirmed | [Patch 9.10](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-9-10) |
| Patch 9.10 also: Ghost 15 → 13 rounds, Frenzy 13 → 15; rifles walk 2 → 3 and run 5 → 6; machine guns walk 2.4 → 3 and run 6 → 6.5; Classic right click running 1.3 → 1.5 and jumping 2.1 → 2.25; Phantom's falloff moved to 20 m | Confirmed | The same notes |
| Skirmish's 2v2 queue: "Full weapon selection each round (no economy)" | Confirmed | [Patch 12.03](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-12-03) |

### From the community: the guns

From the VALORANT Wiki's weapon pages (Weird Gloop), each checked against metabot.gg's
page for the same gun. Speeds are the wiki's run speeds, with the knife's 6.75 m/s as 100%.
Damage is per bullet or per pellet, head / body / legs. The wiki rounds the fractional values
down (the Sheriff's head 159) and metabot rounds them to the nearest (160); both come from the
gun's multipliers, which the wiki lists (the Sheriff's head is 55 x 2.9 = 159.5), so we use the
products.

| Gun | Price | Fire | Rate (rps) | Rounds / reserve | Reload | Draw | Speed | Walls | Damage by range |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Classic | free | semi | 6.75 | 12 / 36 | 1.75 | 0.75 | 5.73 (85%) | Low | 0-30 m 78 / 26 / 22.1, then 66 / 22 / 18.7 |
| Shorty | 300 | semi, 15 pellets | 3.0 | 2 / 6 | 1.75 | 0.75 | 5.4 (80%) | Low | per pellet 0-7 m 22 / 11 / 9.35, 7-15 m 12 / 6 / 5.1, then 6 / 3 / 2.55 |
| Frenzy | 450 | auto | 10 | 15 / 45 | 1.5 | 1.0 | 5.73 (85%) | Low | 0-20 m 78 / 26 / 22.1, then 63 / 21 / 17.85 |
| Ghost | 500 | semi | 6.75 | 13 / 39 | 1.5 | 0.75 | 5.73 (85%) | Medium | 0-30 m 105 / 30 / 25.5, then 87.5 / 25 / 21.25 |
| Bandit | 600 | semi | 5.1 | 8 / 24 | 1.5 | 0.75 | 5.4 (80%) on the wiki, 85% on metabot | Medium | 0-10 m 152 / 39 / 33.15, 10-30 m 128.7 / 39 / 33.15, then 112.2 / 34 / 28.9 |
| Sheriff | 800 | semi | 4 | 6 / 24 | 2.25 | 1.0 | 5.4 (80%) | High | 0-30 m 159.5 / 55 / 46.75, then 145 / 50 / 42.5 |
| Stinger | 1100 | auto | 16 | 20 / 60 | 2.25 | 0.75 | 5.73 (85%) | Low | 0-15 m 67.5 / 27 / 22.95, then 57.5 / 23 / 19.55 |
| Spectre | 1600 | auto | 13.33 | 30 / 90 | 2.25 | 0.75 | 5.73 (85%) | Low | 0-15 m 78 / 26 / 22.1, 15-30 m 66 / 22 / 18.7, then 60 / 20 / 17 |
| Bucky | 850 | semi, 15 pellets | 1.1 | 5 / 10 | 2.5, 0.5 a shell | 1.0 | 5.06 (75%) | Low | per pellet 0-8 m 34 / 17 / 14.45, 8-12 m 26 / 13 / 11.05, then 18 / 9 / 7.65 |
| Judge | 1850 | auto, 12 pellets | 3.5 | 5 / 15 | 2.2 | 1.0 | 5.06 (75%) | Low | per pellet 0-10 m 34 / 17 / 14.45, 10-15 m 20 / 10 / 8.5, then 14 / 7 / 5.95 |
| Bulldog | 2050 | auto | 10 | 24 / 72 | 2.5 | 1.0 | 5.4 (80%) | Medium | 115.5 / 35 / 29.75 |
| Guardian | 2250 | semi | 5.25 | 12 / 36 | 2.5 | 1.0 | 5.4 (80%) | High | 195 / 65 / 48.75 |
| Phantom | 2900 | auto | 11 | 30 / 60 | 2.5 | 1.0 | 5.4 (80%) | Medium | 0-20 m 156 / 39 / 33.15, then 140 / 35 / 29.75 |
| Vandal | 2900 | auto | 9.75 | 25 / 50 | 2.5 | 1.0 | 5.4 (80%) | Medium | 160 / 40 / 34 |
| Warden | 2900 | auto | 6.5 | 18 / 36 | 2.5 | 1.0 | 80% (metabot) | Medium | 200 / 50 / 42 |
| Marshal | 950 | semi | 1.5 | 5 / 15 | 2.5, 0.5 a round | 1.25 | 5.4 (80%) | Medium | 202 / 101 / 85.85 |
| Outlaw | 2400 | semi | 2.75 | 2 / 10 | 2.3 for one round, 3.8 for two | 1.25 | 5.4 (80%) | High | 238 / 140 / 119 |
| Operator | 4700 | semi | 0.6 | 5 / 10 | 3.7 | 1.5 | 5.13 (76%) | High | 255 / 150 / 120 |
| Ares | 1600 | auto | 13 | 50 / 100 | 3.25 | 1.25 | 5.13 (76%) | High | 0-30 m 75 / 30 / 25.5, then 70 / 28 / 23.8 |
| Odin | 3200 | auto, rising | 12 rising to 15.6 | 100 / 200 | 5.0 | 1.25 | 5.13 (76%) | High | 0-30 m 95 / 38 / 32.3, then 77.5 / 31 / 26.35 |

Notes on the table:

- Reserves agree with Riot where Riot gave them (the Bandit, the Warden, Patch 6.11's Vandal,
  Phantom and Shorty).
- Every draw time also has a "Fast" and an "Instant" figure, as in the Warden's notes, 0.6 and
  0.2 of the normal for most guns. No public source says which situations use them; the only other
  "instant" in this year's notes is Iso's equip after an ability, so they look like draws after
  an ability. We have no abilities, so only the normal time applies.
- The Frenzy's normal draw is 1.0 s on both sites, though its fast and instant figures (0.45,
  0.15) match the 0.75 s sidearms.
- Fire rates the wiki gives as a share of the normal rate are in the zoom table below.

Spread and movement, from the same pages (degrees; the first shot is the cone at bullet 1, the
maximum the most it grows to over a spray; crouched multiplies both; moving adds a penalty):

| Gun | First shot | Max | Crouched | Moving: crouched / walk / run / air |
| --- | --- | --- | --- | --- |
| Classic | 0.4 | 1.8 | x0.75 | 0.5 / 1.1 / 2.3 / 7 |
| Classic right click | 1.9 | 5.78 | x0.9 | 0 / 0.6 / 1.5 / 2.25 |
| Shorty | 4 | 4 | 3.4 (x0.85) | 0.5 / 1 / 2 / 4 |
| Frenzy | 0.65 | 1.7 | x0.85 | 0.5 / 0.8 / 2 / 7 |
| Ghost | 0.3 | 1.65 | x0.75 | 0.5 / 1.1 / 2.3 / 7 |
| Bandit | 0.275 | 1.97 | x0.75 | 0.5 / 1.2 / 2.7 / 7 |
| Sheriff | 0.25 | 2.75 | x0.75 | 0.5 / 1.2 / 3 / 7 |
| Stinger | 0.65 | 1.5 | x0.85 | 0.15 / 1 / 2.5 / 10 |
| Spectre | 0.4 | 1.4 | x0.85 | 0.15 / 1 / 2.5 / 10 |
| Bucky | 3 | 3 | x0.85 | 0.5 / 1 / 2 / 4 |
| Judge | 2.5 | 4 | x0.85 | 0.5 / 1 / 2 / 4 |
| Bulldog | 0.3 | 1.25 | x0.85 | 0.8 / 3 / 6 / 10 |
| Guardian | 0.1 | 1.58 | x0.85 | 0.8 / 3 / 6 / 10 |
| Phantom | 0.2 | 0.9 | x0.85 | 0.8 / 3 / 6 / 10 |
| Vandal | 0.25 | 1.0 | x0.85 | 0.8 / 3 / 6 / 10 |
| Warden | 0.15 (metabot) | not found | not found | not found |
| Marshal | 1 (0 scoped) | 1 | x0.9 | 7.5 / 10 / 15 / 20 |
| Outlaw | 3.5 (0 scoped, 2.25 after the first shot) | 3.5 | x0.9 | 7.5 / 10 / 15 / 20 |
| Operator | 5 (0 scoped) | 5 | x0.9 | 7.5 / 10 / 15 / 15 |
| Ares | 1.0, tightening to 0.7 | 1.0 | x0.6 | 0.4 / 3 / 6.5 / 10 |
| Odin | 0.8 | 1.3 | x0.6 | 0.4 / 3 / 6.5 / 10 |

- The wiki lists the Shorty's and the Judge's crouch multiplier as x0.75, but their own spread
  tables (4 to 3.4, 2.5 to 2.12, 4 to 3.4) are x0.85, so we take x0.85.
- The Ares tightens as you fire: its 4.01 entry changes "spread from .8 to .7 after 10 bullets to
  1.0 to .7 after 13 bullets".
- The Stinger's total spread is "reached at 6 bullets instead of 7" (its 11.08 entry), and the
  Frenzy's spread "now reach[es] max in 5 bullets instead of 6" (Patch 6.11).
- Recovery and tap efficiency from the wiki's history: Bandit 0.45 → 0.4 s and 3 → 4 (13.00),
  Spectre tap efficiency 2 → 3 (11.08), the Bulldog's burst recovery 0.4 → 0.35 (4.0).
- Sideways recoil (11.08, PC): the Vandal's and the Phantom's switch time 0.37 → 0.6 s and chance
  6% → 10%; the protected bullets, which never drift, 4 → 6 (Vandal) and 6 → 8 (Phantom); the
  Spectre's switch time 0.18 → 0.28 s and protected bullets 4 → 5.

Zoom and right click:

| Gun | Right click | Zoom | Fire rate zoomed | Speed zoomed | First shot zoomed |
| --- | --- | --- | --- | --- | --- |
| Classic | three bullets at once, 2.22 a second | none | | | see the spread table |
| Stinger | aim, 4-round bursts at 18 rps, 2.118 bursts a second | 1.15x | 52% overall | 76% | 0.35 (max 2.74, crouched x0.75) |
| Spectre | aim | 1.15x | 90% (12) | 76% | 0.25 (max 1.25) |
| Bucky | a canister that bursts into 5 pellets 7.5 m out; a direct hit before then does 40 / 20 / 15 | none | | | |
| Bulldog | aim, 3-round bursts at 13.33 rps, 2.105 bursts a second | 1.25x | 63.16% overall | 76% | 0.1 (max 1.5, crouched x0.75) |
| Guardian | aim | 1.5x | 100% | 76% | 0 (max 1.48) |
| Phantom | aim | 1.25x | 90% (9.9) | 76% | 0.11 (max 0.91) |
| Vandal | aim | 1.25x | 90% (8.775) | 76% | 0.157 (max 1.02) |
| Warden | scope | 2x (Riot) | not found | not found | not found |
| Marshal | scope | 3.5x | 80% (1.2) | 90% | 0 |
| Outlaw | scope | 3.5x | 100% | 80% | 0, then 2.25 |
| Operator | scope | 2.5x, then 5x | 100% | 72% | 0 |
| Ares | aim | 1.15x | 100% | 76% | 0.9 (tightening to 0.55) |
| Odin | aim, full rate at once | 1.15x | 130% (15.6) | 76% | 0.79 (max 1.36) |
| Knife | a heavier stab | | | | |

The Shorty, Frenzy, Ghost, Bandit, Sheriff and Judge have no right click on the wiki. The Sheriff
is the one change for us: system 2 had guessed it zoomed 1.25x.

The knife (wiki): 50 front and 100 back with a click, 75 and 150 with the stab, within 0-8 m; a
three-swing combo; 6.75 m/s; a 0.6 s draw.

### From the community: shields and the menu

| Fact | Status | Source |
| --- | --- | --- |
| Light Armor 400 credits for 25, Heavy Armor 1000 for 50 | Community | [Sportskeeda's armor guide](https://sportskeeda.com/valorant/valorant-armor-guide-understanding-defense-purchase-system-works-riot-s-shooter), [Digital Trends](https://qa2.www.digitaltrends.com/gaming/how-does-regen-shield-work-valorant), [Dot Esports](https://dotesports.com/valorant/news/valorant-regen-shield-explained) |
| Light and Heavy Armor absorb 66% of incoming damage; the Regen Shield absorbs 100% | Community | Sportskeeda ("shields offer 66% of damage mitigation"), Dot Esports, [Beebom](https://beebom.com/valorant-regen-shield-explained/amp/) ("the other armors absorb 66% of incoming damage") |
| The Regen Shield's 25 refills from its pool "3 seconds after your active armor depletes", twice from a full pool, never above 125 with health; the pool "carries over but does not replenish between rounds", and buying it again refills it | Community | Beebom; [talkesport](https://www.talkesport.com/editorials/valorant-regen-shield/) ("if the player is out of combat for three seconds") |
| "Open the Buy menu during the Buy Phase of a round (Default key is B)"; hover over an item and "Right-Click your mouse to sell the weapon or item and receive your credits back"; "you can only refund a VALORANT weapon, ability, or shield in the same Buy Phase"; a weapon carried over from an earlier round can't be sold | Community | [esports.gg](https://esports.gg/guides/valorant/how-to-request-a-refund-in-valorant/) |
| The menu "lets players know how much each weapon costs and its stats" | Community | [esportnow.gg](https://esportnow.gg/valorant/news/how-to-use-every-valorant-weapon-full-guide-updates-2026) |
| The Classic's right click "shoots a burst of three bullets at the same time", each doing "as much damage as a bullet fired using the Classic's primary fire" | Community | [Inven Global](https://www.invenglobal.com/articles/11036/valorant-weapon-guide-the-classic) |
| The Odin: "12 rounds/sec, spinning up to 15.6 rounds/sec with sustained fire" | Community | [dodge.gg](https://www.dodge.gg/en-US/valorant/news/odin-weapon-guide-2026) |
| The Warden: the best first shot of any rifle, 0.15 degrees | Community | [Beebom](https://beebom.com/valorant-warden/), [metabot](https://metabot.gg/en/valorant/weapon/Warden/overview) |

**Not found publicly:** how long the Odin takes to reach 15.6, how much ammo the Classic's right
click uses, how the Bucky's pellets spread once its canister bursts, the Warden's spread,
movement penalties and zoomed speed and fire rate, every recoil pattern, recovery and tap
efficiency for most guns, the Regen Shield's refill rate, how fast a shell-by-shell reload puts
the first round in, the knife's timings and reach, and the buy menu's exact layout. Section 3 says
how to measure each.

## 3. What can be measured, and how

From your own copy of the game in The Range, played normally, with a video (Windows' Game Bar or
your graphics driver's recorder) and the bots. Never use any tool that reads the game's memory,
files or network traffic.

| Measurement | Method | Gives us |
| --- | --- | --- |
| The Odin's rise | Hold the trigger on a wall and count the shots in each tenth of a second of the video | `spinUp` |
| Bursts | Count the frames between the bullets of one Stinger and one Bulldog burst, and between bursts | `burst` |
| The Classic's right click | Right-click a full magazine away and count the clicks | `alt.ammo` |
| Pellets | Shoot a wall from 5 m with each shotgun and count the holes; measure the pattern's width | `pellets`, the shotguns' `firingError` |
| The Bucky's canister | Right-click a wall at 5 m and at 10 m: one hole, then a pattern | `alt` (the burst distance and spread) |
| Shell-by-shell reloads | Count frames from the reload starting to each shell going in, Bucky and Marshal | `reload.perRound`, `reload.first` |
| Spread and recoil | As in [03-spread-recoil](03-spread-recoil.md), for each gun | `accuracy`, `recoil` |
| Armour | With a friend, Light Armor on: one Classic body shot (26), then read your health and shield | Whether 66% is right (it should leave 91.2 health and 7.8 shield) |
| The Regen Shield | With a friend: have your 25 shot away, then time how long until it starts refilling and how long it takes | `Shields.regen` |
| Zoomed speed | Cross two markers zoomed with each gun | `ads.moveMultiplier` |

## 4. Confirmed vs estimated, as implemented

Every value lives in `src/shared/Weapons/WeaponConfig.luau` with its status and source. The guns
first:

| Parameter | Value | Status |
| --- | --- | --- |
| The 20 guns' prices, fire modes, rates, magazines, reserves, reloads, draws, run speeds, wall classes and damage | Section 2's table | Community; confirmed where Riot gave them (the Bandit, the Warden, Patch 6.11's reserves and Shorty) |
| The Bandit's run speed | 85% (5.74 m/s), metabot's; the wiki says 80% | Community, conflicting |
| The Warden's first shot | 0.15° | Community |
| The rest of the Warden's accuracy | Its maximum 1.0° at bullet 8, and zoomed from 0; crouch, movement, recovery and tap efficiency like the rifles'; zoomed, fire rate x1.0 and 76% speed | Estimate |
| Spread: first shot, maximum, crouch multiplier and movement errors | Section 2's spread table | Community |
| Spread between the first shot and the maximum | Our shape from [03-spread-recoil](03-spread-recoil.md), reaching the maximum at a bullet of ours for each gun | Estimate |
| Zoom levels, zoomed fire rates and speeds | Section 2's zoom table; the Operator's scoped 72% | Community; confirmed (the Operator) |
| Zoomed accuracy | Each gun's own zoomed curve, from the wiki's zoomed first shot and maximum | Community |
| Bursts | Stinger: 4 rounds at 18 a second, 2.118 bursts a second. Bulldog: 3 at 13.33, 2.105 a second. Burst recovery 0.4 and 0.35 s | Community |
| How a burst fires | One click fires the whole burst; holding fires burst after burst, the spray carrying on from one to the next | Community (the burst); estimate (the spray carrying on) |
| What stops a burst | Unzooming, switching, reloading or running out | Estimate |
| The Classic's right click | 3 bullets at once, 2.22 clicks a second, its own cone (1.9° to 5.78°) and movement errors | Community |
| Its ammo | A round a bullet: 3 a click, so 4 clicks a magazine; with fewer left, a bullet for each round left | Estimate |
| Pellets | Shorty 15, Bucky 15, Judge 12, each doing its own damage | Community |
| Where the pellets go | All in the shot's one cone, each at its own random point, with one recoil for the shot | Estimate (how they're spread inside the cone) |
| A shotgun hit | Every pellet that hits one target adds up into one hit, on the best region any of them hit | Estimate |
| Shell-by-shell reloads | Bucky and Marshal: 0.5 s a round, so 2.5 s from empty | Community |
| The first round of one | 0.5 s like the rest | Estimate |
| Firing during one | Stops it, keeping the rounds already in | Estimate |
| The Outlaw's reload | 2.3 s for one round, 3.8 s for two | Community |
| The Outlaw after its first shot | Recovery 0.15 s, spread 2.25°, recoil 4.0 | Confirmed |
| The Odin | 12 a second rising to 15.6 while held; zoomed, 15.6 at once | Community |
| How it rises | Evenly over 1.0 s, and back to 12 the moment you let go | Estimate |
| The Ares | 13 a second throughout: no spin-up since Patch 4.0 | Community |
| Recovery | Counted from when the gun can fire again ([03-spread-recoil](03-spread-recoil.md)) | Estimate (where it counts from) |
| Recovery times and tap efficiencies | Vandal, Phantom and Outlaw confirmed; the Bandit's, the Spectre's tap efficiency and both bursts' recovery from the wiki's history; every other gun's ours | Mixed |
| Recoil climb and sideways drift for the new guns | Ours, shaped for each kind of gun | Estimate |
| A sniper's view kick | Marshal 1.2°, Outlaw 1.5°, Operator 1.8°, settling in 0.35 s | Estimate |
| Suppressed guns | The Ghost, Spectre and Phantom: quieter, and their tracers show only to their own side | Community |
| How far a suppressed shot is heard | Silent at 70 m (system 8's curve) | Estimate |
| Sounds | The library's five gunshots, each gun taking the nearest at a pitch of its own; reloads in parts, a round-at-a-time reload for each round | Estimate |
| Looks | Stand-in shapes in nine kinds (pistol, suppressed pistol, sawn-off, SMG, shotgun, rifle, sniper, machine gun, knife) and a colour for each gun | Estimate (placeholders) |
| The knife | 6.75 m/s and a 0.6 s draw; its attacks are [system 10](10-knife.md) | Community |
| The Bucky's right click | Not built yet: it does nothing | |

The shields:

| Parameter | Value | Status |
| --- | --- | --- |
| Light Armor and Heavy Armor | 400 credits for 25 and 1000 for 50 | Community |
| How they take a hit | 66% of it while they last, and health the rest | Community |
| The Regen Shield | 650 credits for 25, taking every point of a hit while it lasts, refilling from a pool of 50 | Confirmed (Patch 9.10) |
| When it refills | 3 s after the last hit | Community (the 3 s); estimate (counting from the last hit, not from when it ran out) |
| How fast | 12.5 a second, so 25 in 2 s | Estimate |
| What ends a refill | A hit, the pool running out, or the shield being full | Estimate |
| What a new life wears | The shield worn in the last one, full, and the Regen Shield's pool full again | Estimate (with nothing to pay, a new life buys it back) |
| What everyone starts in | Heavy Armor, as Skirmish does, on the course too | Community |
| A new match in the arena | Everyone back on the starting kit: Vandal, Classic, knife and Heavy Armor | Estimate (the reference starts a match with the Classic and credits to spend) |

The buy menu:

| Parameter | Value | Status |
| --- | --- | --- |
| Opening it | B, while buying is open | Community |
| When buying is open | In the arena, the buy phase and while waiting for an opponent; on the course, any time | Community (the buy phase); ours (waiting, and the course, like the reference's practice range) |
| Buying | A click: a gun goes into its slot with full ammo and is drawn, a shield goes on full | Community |
| Buying the shield you wear | A fresh one, if it's damaged | Community for the Regen Shield ("buying it again refills it"); estimate for the others |
| Selling | A right click, on what was bought this buy phase, puts back what its slot held when the phase began | Community |
| A buy phase on the course | Each life | Estimate |
| Buying as the phase opens | Held for the new life the phase brings, and made as soon as it starts (Roblox takes about 0.32 s to load the character) | Ours (the reference respawns everyone at once) |
| Prices | Shown and not charged: Skirmish has no economy | Confirmed (Patch 12.03) |
| What it shows | The guns in four columns by group and the shields in a fifth, each with its price and a stand-in picture; a white edge on what you have and a teal one on what you can sell back; the numbers of the one under the cursor in a panel to the right | Estimate (the reference's layout isn't published) |
| While it's open | The mouse moves a cursor, its buttons are the menu's, and you can still move | Estimate |
| The HUD's health and shield | Rounded up, so 86.4 reads 87 and a player left with 0.4 reads 1; nothing left reads 0 | Estimate |

What the simulation produces (from `luau tests/run.luau`; a shotgun's shots to kill count every
pellet hitting):

| Gun | Fire rate, configured and simulated | A magazine empties in | Shots to kill 150 at 10 m, head / body | Body kill time |
| --- | --- | --- | --- | --- |
| Classic | 6.75, 6.74 | 1.63 s | 2 / 6 | 741 ms |
| Shorty | 3.00, 2.98 | 0.34 s | 1 / 2 | 333 ms |
| Frenzy | 10.00, 9.96 | 1.41 s | 2 / 6 | 500 ms |
| Ghost | 6.75, 6.74 | 1.78 s | 2 / 5 | 593 ms |
| Bandit | 5.10, 5.09 | 1.38 s | 1 / 4 | 588 ms |
| Sheriff | 4.00, 4.00 | 1.25 s | 1 / 3 | 500 ms |
| Stinger | 16.00, 16.00 | 1.19 s | 3 / 6 | 312 ms |
| Spectre | 13.33, 13.30 | 2.18 s | 2 / 6 | 375 ms |
| Bucky | 1.10, 1.10 | 3.64 s | 1 / 1 | |
| Judge | 3.50, 3.48 | 1.15 s | 1 / 1 | |
| Bulldog | 10.00, 9.98 | 2.30 s | 2 / 5 | 400 ms |
| Guardian | 5.25, 5.23 | 2.10 s | 1 / 3 | 381 ms |
| Phantom | 11.00, 10.98 | 2.64 s | 1 / 4 | 273 ms |
| Vandal | 9.75, 9.72 | 2.47 s | 1 / 4 | 308 ms |
| Warden | 6.50, 6.50 | 2.62 s | 1 / 3 | 308 ms |
| Marshal | 1.50, 1.50 | 2.67 s | 1 / 2 | 667 ms |
| Outlaw | 2.75, 2.72 | 0.37 s | 1 / 2 | 364 ms |
| Operator | 0.60, 0.60 | 6.67 s | 1 / 1 | |
| Ares | 13.00, 12.99 | 3.77 s | 2 / 5 | 308 ms |
| Odin | 12 rising to 15.6, 15.29 over a magazine | 6.48 s | 2 / 4 | 250 ms |

| Zoomed burst | Rounds 1/13.33 s apart | Bursts a second | Second burst held starts at |
| --- | --- | --- | --- |
| Bulldog | to the tick | 2.105 | bullet 4 |

Shots to kill at 10 m from full health, head / body, by shield (a shotgun's with every pellet
hitting). Light Armor and the Regen Shield
are both 25, and come out the same because, from full health, health and shield together always
drop by exactly the hit (the tests check every gun, shield, region and range: 960 cases). A
Classic body shot on Light Armor leaves 91.16 health and 7.84 shield, the check in section 3.

| Gun | No shield | Light Armor, Regen Shield | Heavy Armor |
| --- | --- | --- | --- |
| Classic | 2 / 4 | 2 / 5 | 2 / 6 |
| Shorty | 1 / 2 | 1 / 2 | 1 / 2 |
| Frenzy | 2 / 4 | 2 / 5 | 2 / 6 |
| Ghost | 1 / 4 | 2 / 5 | 2 / 5 |
| Bandit | 1 / 3 | 1 / 4 | 1 / 4 |
| Sheriff | 1 / 2 | 1 / 3 | 1 / 3 |
| Stinger | 2 / 4 | 2 / 5 | 3 / 6 |
| Spectre | 2 / 4 | 2 / 5 | 2 / 6 |
| Bucky, Judge | 1 / 1 | 1 / 1 | 1 / 1 |
| Bulldog | 1 / 3 | 2 / 4 | 2 / 5 |
| Guardian | 1 / 2 | 1 / 2 | 1 / 3 |
| Phantom, Vandal | 1 / 3 | 1 / 4 | 1 / 4 |
| Warden | 1 / 2 | 1 / 3 | 1 / 3 |
| Marshal | 1 / 1 | 1 / 2 | 1 / 2 |
| Outlaw | 1 / 1 | 1 / 1 | 1 / 2 |
| Operator | 1 / 1 | 1 / 1 | 1 / 1 |
| Ares | 2 / 4 | 2 / 5 | 2 / 5 |
| Odin | 2 / 3 | 2 / 4 | 2 / 4 |

With health already down, a fresh shield doesn't add its whole value: Heavy Armor bought at 10
health still lets 13.6 of a Vandal body shot through, which kills.

## 5. Design

```
 one trigger pull, inside WeaponSim.step (client prediction and server alike)

   buttons, zoom ──► mode: hip / zoom / alt ──► when it fires: rate, burst, spin-up, recovery
                                            └─► what a round is: rounds used, bullets in it
   each round ──► one cone, one recoil ──► bullets 1..n, each its own shot number ──► Shots {volley, pellet}
                                                                                      │
   server, CombatServer.onVolley:  each bullet traced through walls, tested on hitboxes
                                   Volley.totals ──► one hit for each target, its best region ──► Health
                                   ShotResult ──► the shooter: one verdict with every pellet
                                   ShotFx ──► everyone else: every pellet's end, tracers if they may see them
```

- **Three ways to fire.** A gun fires from the hip, zoomed (aiming down sights or scoped), or,
  for the Classic, with its right click. `WeaponConfig.mode` puts each together once from the
  definition: its cadence (rate, burst, spin-up), the rounds a trigger pull uses, the bullets in
  a round, and the accuracy and recoil it reads. The simulation, the HUD and the labs all ask
  it, so they never disagree about how a gun is firing.
- **A round is a volley.** A shotgun's round is one shot with many bullets. They share one cone
  and one recoil, and each gets its own shot number, so its own random point in the cone, the
  same on the client and the server. The server traces each through the walls and tests it
  against the hitboxes, then adds up every pellet that hit each target (`Volley.totals`) into one
  hit: one damage number, one hit marker, one hit sound, one tag slow, on the best region any of
  them hit. The shooter's verdict carries every pellet, so the client draws each tracer and hole.
- **Bursts are weapon state.** The first round of a burst sets when the next burst may start;
  the rest of the burst (`burstLeft`, `burstNext`) fires on its own cadence whether the trigger is
  still held or not. Its rounds count on through the spray with no recovery between them. The ack
  carries both, so a client corrected mid-burst picks it up exactly.
- **Spin-up is weapon state.** `spin` runs from 0 to 1 while the trigger is held and the gun can
  fire, and the rate is the gun's rate plus that share of the way to its top rate. Letting go,
  reloading or switching puts it back to 0. It's in the ack too.
- **Recovery counts from readiness.** See [03-spread-recoil](03-spread-recoil.md): without it the
  Outlaw's recovery could never matter, and a burst gun's burst recovery would be lost inside the
  time between bursts.
- **Reloads a round at a time.** For the Bucky and the Marshal each round is a step of its own:
  when one goes in, the next starts while the magazine isn't full and the reserve has some. A pull
  of the trigger with a round in stops the reload and fires. The Outlaw's reload takes its short
  time when one round is missing.
- **The Classic's right click** uses three rounds and fires a bullet for each, in its own cone.
- **Feedback once per round.** The muzzle flash, the view kick and the gunshot are per round,
  never per pellet, so a shotgun sounds and kicks once.
- **Suppressed tracers.** The server sends a suppressed gun's shots to the other side without
  tracers; they still get the sound, quieter, and the holes.
- **Snipers kick the view.** Their bullets don't climb, but each shot jumps the view up and lets
  it settle, which is what makes a bolt-action read as one.

```
 buying, on B

   BuyMenu ── Buy: "buy" or "sell", an id ──► ShopServer: is buying open? alive, and in the arena its rules say so
                                              Shop: what each slot held when the buy phase began
                                              ├─► a gun: into its slot, full ammo ──► the ack ──► drawn (drawWhenGiven)
                                              └─► a shield: on, full ──► a "shield" combat event ──► the HUD
                                              VFShield, VFBought ──► the menu's edges and the sell hint
```

- **A shield takes its share.** While it lasts, a shield takes its share of every hit
  (`absorb`: 66% for the armours, all of it for the Regen Shield) and health the rest; once it's
  gone, health takes everything. Only health running out kills. From full health, health and
  shield fall by exactly each hit, so the shots to kill are the ones their sum gives, and none of
  system 2's numbers move.
- **The Regen Shield refills on the server.** `Health.step` runs for every entity each server
  frame: 3 s after the last hit it refills at 12.5 a second from its pool. Clients hear about it
  through "shield" combat events, at most ten a second while it refills and one as it stops, so
  the HUD's number climbs smoothly without flooding the remote.
- **What you wear stays.** The kind of shield belongs to the player, not to a life: each new life
  puts it back on full, with a full pool. A new match in the arena puts everyone back on the
  starting kit.
- **Buying is plain state.** `Shop` keeps, for each slot bought into this buy phase, what it held
  when the phase began. Selling puts that back, and buying back what a slot began with leaves
  nothing to sell. `ShopServer` checks that buying is open and applies the result: a gun with full
  ammo, drawn if its slot is in hand, or a shield on full. Each life is a new buy phase.
- **A buy as the phase opens waits for its life.** The arena respawns everyone as a buy phase
  opens, but Roblox takes a moment to load each character (0.32 s in BRINK), and the menu is open
  from the phase's first moment. A request in between would be lost: refused for a dead player,
  or made on a living player's old life and then reset away with it. So the arena marks the
  respawn as expected (`PlayerSimServer.expectSpawn`), and until the new life starts `ShopServer`
  holds what comes in (`Shop.hold`, a few requests, for up to 5 s) and makes it as soon as the
  life begins.
- **The menu shows the server's word.** The guns you have come from the predicted loadout, which
  the server's acks correct; the shield worn and what can be sold come from two player
  attributes the server sets, `VFShield` and `VFBought`. A gun you buy is drawn only once an ack
  shows it in its slot (`PlayerController.drawWhenGiven`), so a refused purchase changes nothing.
  The debug keys 4 to 8 take the same path now, which stops them switching slots when the server
  says no.
- **The mouse belongs to the menu while it's open.** The camera stops reading it and shows the
  cursor, and its buttons are masked out of the simulation's input (`InputSampler.blockMouse`), so
  a click on a tile never fires. The keys still work, so you can walk about in spawn while
  choosing, and the menu closes itself when buying closes.

### Roblox differences that matter

- **ShotFx is unreliable.** It goes out on an unreliable remote, which drops anything over about
  900 bytes. A Bucky shot's 15 end points come to about 200 bytes, well inside it.
- **Every pellet is a trace.** A Judge held down is 42 traces a second through the walls on the
  server for one player. Roblox raycasts are cheap enough for that, and a trace stops after the
  most pieces it may count (system 5).
- **A cursor needs the mouse unlocked.** Under `MouseBehavior.LockCenter` there's no cursor and
  GUI buttons get no hover, so the camera hands the mouse back (`Default`) while the menu is open
  and locks it again when it closes.
- **The shield is pushed, not polled.** Like damage, the shield's value reaches clients only in
  combat events, so the Regen Shield's refill has to be sent as it happens; ten events a second
  for each refilling player is small next to the snapshots.

## 6. Implementation map

| File | Role |
| --- | --- |
| `src/shared/Weapons/WeaponConfig.luau` | The 21 weapons, each value with its status and source; `WeaponConfig.mode` and `altMode`; `Arsenal` (the buy menu's groups) and `Ids` (wire ids); `shotDamage` and `shotsToKill` |
| `src/shared/Weapons/WeaponSim.luau` | Modes, bursts, spin-up, a round at a time and the Outlaw's reload, the Classic's right click, pellets |
| `src/shared/Weapons/Accuracy.luau` | Recovery from readiness; a cone and a recoil from a mode's accuracy |
| `src/shared/Combat/Volley.luau` | A round's hits added up by target |
| `src/shared/Net/PlayerCodec.luau` | The ack's `burstLeft`, `burstNext` and `spin` |
| `src/server/CombatServer.luau` | `onVolley`: a round's bullets traced and resolved, one hit for each target, ShotResult and ShotFx |
| `src/client/Combat/ClientShots.luau` | The client's own trace of each pellet, matched to the server's verdict for the round |
| `src/client/Combat/CombatHud.luau` | One hit marker and number for a round; a reload bar for a round at a time |
| `src/client/Combat/WeaponEffects.luau` | Every gun's stand-in shape and colour; one flash and kick for a round, a tracer and hole for each pellet; others' suppressed shots without tracers |
| `src/shared/Audio/SoundConfig.luau`, `src/client/Audio/GameSounds.luau` | Every gun's gunshot, pitch and reload parts; a part for each round of a round-at-a-time reload |
| `src/client/Debug/WeaponLab.luau`, `SprayLab.luau` | The mode, bursts, spin-up and reload steps (below) |
| `src/client/Debug/TestAim.luau`, `src/client/InputSampler.luau` | `VFTestButtons` and `VFTestGive` for scripted playtests |
| `tests/arsenal.luau` | Offline tests: every gun's numbers, pellets, bursts, spin-up, reloads, the Classic's right click, acks resumed mid-burst, mid-spin and mid-reload |
| `src/shared/Combat/Health.luau` | Health and a shield: each hit split by the shield's share, the Regen Shield's refill, a new life |
| `src/shared/Weapons/Shop.luau` | The buy menu's rules: what's on sale and where it goes, buying, selling back what was bought this buy phase |
| `src/server/ShopServer.luau` | The Buy remote: whether buying is open, a purchase or a sale applied, the `VFShield` and `VFBought` attributes |
| `src/server/CombatServer.luau` | `step`: the Regen Shield's refill, sent as "shield" events; `setShield` |
| `src/server/PlayerSimServer.luau`, `src/server/Arena.luau` | `give`, `holding`; `resetKit`, which a new match uses for the starting kit |
| `src/client/BuyMenu.luau` | The menu: its tiles, the numbers panel, buying and selling |
| `src/client/Combat/WeaponLooks.luau` | Every gun's stand-in shape and colours, for the viewmodel and the menu's pictures |
| `src/client/Combat/CombatHud.luau` | The shield's name under its number, and the Regen Shield's pool |
| `src/client/PlayerController.luau` | `drawWhenGiven`: a gun is drawn once the server has put it in its slot |
| `src/client/CameraController.luau`, `src/client/InputSampler.luau` | `cursorFree` and `blockMouse` while the menu is open |
| `tests/shop.luau` | Offline tests: the shields' numbers, splits, refill and new lives, shots to kill through every shield, the menu's rules |

## 7. Debug tools

| Key or attribute | Tool |
| --- | --- |
| F2 (weapon lab) | Its first line adds the gun's group, price and pellets. A second line says how it fires zoomed (its zoom, and its bursts and their rate), with its right click, and while held (the spin-up, with how far it's risen now). The state line shows a burst still to come and a reload's current round; the fire rate line reads "expect 12 rising to 15.6" for the Odin; the reload line gives a round's time or the Outlaw's one-round time |
| F2 (spray lab) | Says which curve the shot read: hip, zoomed or the right click's |
| `VFTestGive` (Studio) | Set it on the local player to a weapon id (`odin`, `bucky` ...): it's given and drawn as 4 to 8 would, and the attribute clears itself |
| `VFTestButtons` (Studio) | PlayerSim button flags held on top of real input while it's set: 128 fire, 256 right click, 512 reload, 32 crouch. Holds the trigger without a mouse button |
| B | The buy menu, while buying is open |
| `VFTestBuy` (Studio) | Set it on the local player to an id (`odin`, `light` ...) to buy it, or to `-` and the id (`-odin`) to sell it back, as the menu's clicks would; it clears itself |
| `VFTestMenu` (Studio) | `true` opens the menu and `false` closes it, as B would; it clears itself |
| F3 (HUD) | The shield's name under its number, and the Regen Shield's pool left |

The Hit Reg Lab's network buffering moved from B to U to make room for the menu.

## 8. Refinement loop

1. Hold the Odin on a wall and count shots per tenth of a second: set `spinUp.time`, and whether
   the rate rises evenly.
2. Count frames within and between Stinger and Bulldog bursts; check the burst recovery by tapping
   bursts at a growing gap.
3. Right-click a full Classic magazine away and count the clicks: `alt.ammo`.
4. Shoot a wall with each shotgun at 5 m: count the holes and measure the pattern, then set the
   pellets' spread inside the cone.
5. Time each shell of a Bucky and a Marshal reload, the first especially, and whether a shot
   during one keeps the shells already in.
6. Spray each new gun at a wall with the spray lab and fit its climb and drift, as in
   [03-spread-recoil](03-spread-recoil.md).
7. Measure the Warden's spread, movement errors and zoomed speed.
8. With a friend, take one Classic body shot in Light Armor from full health: about 91 health and
   8 shield (91.16 and 7.84) means 66% is right. In Heavy Armor a Vandal body shot should leave
   about 86 and 24 (86.4 and 23.6).
9. Have your Regen Shield shot away, then time from the last hit to the refill starting, and to
   the shield being full: `Shields.regen.delay` and `rate`.
10. Re-run `luau tests/run.luau` and update the tables in section 4.

## Known gaps to check in Studio

Written and tested outside Studio (offline Luau tests plus `luau-lsp` type checking). Only a Studio
session can confirm:

- Every gun can be given (`VFTestGive`), draws in its own shape and colour, and fires as the
  weapon lab says: the Bulldog's and the Stinger's bursts zoomed, the Odin rising to 15.6, the
  Classic's three bullets.
- A shotgun shot at a dummy draws a tracer and a hole for each pellet, and shows one hit marker
  and one number: the total.
- A Bucky or a Marshal reloads a round at a time, with a sound for each, and a shot stops it.
- With two players, the other one sees a Bucky's 15 tracers, and none of a suppressed gun's when
  on the other side in the arena.
- Each gun's shot sounds like its own.
- B opens the menu only while buying is open, it fits the screen at any size, and while it's open
  the view stays still, a click never fires and the movement keys still work.
- Hovering a tile shows its numbers; a click buys and draws it; a right click sells back what was
  bought this buy phase, and nothing else.
- The HUD shows Light Armor's split and the Regen Shield refilling as the tests have them.
- A new match in the arena puts everyone back on the starting kit.
- A buy the moment a buy phase opens lands on the new life, and can be sold back.

### Checked in BRINK

Playtests in BRINK on main at ff93950, solo and then with two players, with purchases made
through `VFTestBuy` and the menu read from the player's GUI (measured):

- The menu (B1 to B6): 1200 by 608 px at full size in a 1398 by 672 view, the four columns and
  the shields as laid out, the mouse freed while it was open and the view still; a click on it
  didn't fire, and W still moved. The tiles, the hover panel's numbers (the Odin's, the Bucky's
  pellet table, the Regen Shield's rules), buying, selling back and the three shields' HUD lines
  all read as section 4 has them.
- Two players (B7 to B9). A Vandal body shot through Heavy Armor read `87 | +24`, and the fourth
  killed. A Classic body shot (26) through Light Armor read `92 | +8`. The Regen Shield took a
  whole Classic hit (`99`, no shield), started refilling 3.00 s after it and was full at 4.95 s,
  25 in about 2 s; it refilled once more, to `REGEN 0 LEFT`, and then not again. Turning the
  arena on put both players back on the starting kit, whatever they'd bought on the course, and
  so did a new match after 10-0.
- Others' shots (G8), 21 m apart: a Bucky shot showed the other player 15 tracers, 15 holes and
  15 sparks; a Ghost shot from the other side showed its hole and spark but no tracer, and was
  heard at about half the Bucky's volume.
- Two findings, both fixed since. A purchase in the first third of a second of a buy phase was
  lost: the new life starts 0.32 s after the phase does, and its reset wiped what was bought, so
  a buy 0.15 s in never landed (section 5: it's now held for the new life). And at death the
  HUD's health read `-0` (now `0`).

