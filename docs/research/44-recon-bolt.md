# System 44: Sova's Recon Bolt

Sova's Recon Bolt is his signature, and the first of his kit played. E puts his bow in hand, ready
in 0.8 s. Fire held draws the bolt back, a bar under the crosshair filling each third of a second,
three at the most, and alt fire adds a bounce, two at the most and then none again. Fire let go
looses it, faster and flatter the more bars were filled. It goes off whatever it meets while it has
bounces left and sticks to the next thing it meets; there it winds up and pulses twice, 1.6 s apart,
and each pulse reveals every enemy within 30 m that it has in sight, their silhouettes seen by his
side through walls for a moment, and on their minimap. Enemies can shoot it to pieces. This system
adds Sova as the fifth agent, his bow, its draw and its bounces, the bolt's flight, sticking, pulses
and reveals, its shaft that bullets and knives break, and what everyone sees and hears of it. His
other three abilities aren't played yet.

As before, everything comes from public sources: Riot's page for Sova and six of its patch notes
and, for what Riot doesn't give, the VALORANT Wiki's pages on the Recon Bolt, on Sova, on
projectiles, on status effects and on Team Deathmatch, four guides (Boosting Ground's,
esports.net's, THESPIKE.GG's and Mobalytics') and Red Bull's page on status effects. No game files,
memory or network traffic were used, and nothing was read from the live game. Here the wiki's
numbers are labelled community, though it says some of them come from the game files. Riot gives his
role, the bow, held fire extending its range and alt fire's two bounces, enemies in the bolt's sight
revealed and able to destroy it, its two pulses, its health, its immunity to allies' damage, its
cooldown and that its sound tells of its path, where it lands and how far it reveals; the wiki gives
the draw's bars and their times, letting a draw go, bouncing off any surface and sticking with none
left, the windup, the pulses' interval, their radius, the reveal's time, a real-time silhouette
through terrain, the equip and unequip times, its one use and the speeds and gravities of its four
trajectories; the guides give alt fire cycling the bounces, its duration and its not seeing through
walls. The units of those speeds and gravities, how a bounce goes, where a pulse looks from and what
of an enemy it must see, the shaft that's shot, how it looks and how it sounds are ours. Nothing in
this system is measured. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes and agent page) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source gives the units of the projectile classes' speeds or the gravity they're a share of, what
a bounce keeps of the bolt's speed, how big the bolt is, whether players stop it, how long it flies
meeting nothing, where a pulse looks from, which parts of an enemy it must see, what of a stuck bolt
bullets strike, what a revealed player sees or hears, or how far any of it is heard. Ours are in
section 4: centimetres a second and a share of 9.8 m/s/s, as Hot Hands' and the Slow Orb's; a bounce
as off a mirror, its speed kept; a box 0.1 m across that players don't stop, given up on after 10 s;
a pulse looking from 0.1 m off the surface the bolt's in, and seeing an enemy if it sees the middle
of their head, their body or their legs, as anyone's eye does; a shaft 0.5 m long and 0.2 m across
standing out of the surface; nothing for the revealed but the pulse's sound; and all of it heard out
to 30 m, as the other abilities are.

## 1. Observable behaviour

- **In hand** (Riot's page for Sova and the wiki). Riot: "EQUIP a bow with recon bolt. FIRE to send
  the recon bolt forward, activating upon collision and" "Revealing the location of nearby enemies
  caught in the line of sight of the bolt." The wiki: "Sova must equip before casting, nocking a
  recon arrow into his bow". In our words: it's ready 0.8 s after E and his gun's back 0.7 s after
  it's loosed (from the game files, the wiki says), and it's free, one use.
- **The draw** (Riot's page, the wiki and Boosting Ground). Riot: "HOLD FIRE to extend the range of
  the projectile." The wiki has it fly on "one of four different projectile trajectories.", bars
  under the crosshair showing the draw: "The arrow increases its projectile class for every bar
  filled", "Immediately cast as a Class 2 Projectile", "0.333 seconds/1st bar filled for Class 3
  Projectile", "0.667 seconds/2nd bar filled for Class 4 Projectile" and "1.000 second/3rd bar
  filled for Class 5 Projectile" (its own estimates). Casting it again while it's drawn lets the
  draw go, to "allow him to safely release his Fire key without firing the arrow." Boosting Ground:
  "effectively four distinct power levels corresponding to the segments on the charge bar." and
  "Higher charges result in faster, flatter trajectories."
- **Its flight** (the wiki's page on projectiles). "The trajectory of a projectile is dependent on
  its speed and the scale at which it is affected by gravity." Class 2 has a speed of 1800 and a
  gravity of 0.3, class 3 2900 and 0.45, class 4 4125 and 0.3 and class 5 4125 and 0.15, with no
  units given, and the Recon Bolt is in each, at 0, 1 and 2 bars and fully drawn; for the first two
  it notes a "+0.3 m offset". "Projectile classes are not official VALORANT terminology" and "are
  based on the interpretation of data from the game files by VALORANT Wiki editors".
- **Its bounces** (Riot's page, the wiki and Boosting Ground). Riot: "ALT FIRE to add up to two
  bounces to this arrow." The wiki: "Sova can control the number of times this arrow can bounce off
  of terrain using Alt Fire.", two at most, and "Upon contact with any surface the arrow will bounce
  against it depending on how many bounces have been added to it." Boosting Ground: alt fire "cycles
  through adding zero, one, or two bounces to the arrow."
- **Stuck** (the wiki). "If no more bounces are available to be used on a collision, the arrow will
  attach to the surface," "wind up briefly, then periodically emits sonar pulses over a few
  seconds." In our words: its windup is 0.667 s (the wiki's own estimate), it pulses twice, once
  every 1.6 s, out to 30 m (from the game files, it says), and the wiki's page for Sova has it last
  3.2 s, as THESPIKE.GG does ("Duration: 3.2 seconds"). Patch 7.04: "Total number of scans reduced
  3>>>2".
- **Its reveals** (Riot's page, the wiki, THESPIKE.GG, Boosting Ground and Red Bull). Riot:
  "Revealing the location of nearby enemies caught in the line of sight of the bolt." The wiki: "If
  these pulses hit any enemy agents that are also in the arrow's line of sight," "the enemy will be
  briefly revealed with a real-time silhouette.", each reveal lasting "0.75 seconds". Its page on
  status effects: "An agent with a Reveal debuff has their silhouette revealed to enemy agents
  through terrain.", a real-time one being "a real-time silhouette that continuously shows the
  affected agent's position for the duration of the reveal". THESPIKE.GG: "it won't spot enemies
  through walls, so it'll need a clear sightline to detect their presence." Boosting Ground: "the
  scan does not penetrate walls or solid objects." Red Bull: "If an Agent is Revealed their
  silhouette will be shown through all terrain letting everyone know where that Agent currently is."
- **Destroyed** (Riot's page, Patch 5.12 and the wiki). Riot: "Enemies can destroy this bolt."
  Patch 5.12: "Recon Bolt (E) Health increased 1 >>> 20", having "increased the health of 1hp
  destructibles so that they aren't instantly vaporized.", and "The following abilities are now
  immune to allied damage.", the Recon Bolt among them. The wiki: "Enemies can deal damage to the
  recon bolt and destroy it." In our words: Patch 5.12 also has Brimstone's Incendiary, Phoenix's
  Hot Hands and Blaze, Killjoy's Nanoswarm and Viper's Snakebite damage it.
- **What's heard** (Patch 11.00). "Increased volume of Recon Bolt’s projectile loop and improved how
  the arrow’s sound travels through the air" "to make it easier to track"; "Audio priority and
  attenuation adjusted so that you can more reliably hear the arrow when multiple audio cues are
  present"; "Audio tech updated to make it easier understand the trajectory of the arrow, point of
  impact, and reveal radius".
- **Its cooldown** (Patches 3.0, 11.08 and 13.00, and the wiki). Patch 3.0: "Cooldown time increased
  35 >>> 40". Patch 11.08: "Cooldown increased from 40s → 60s". Patch 13.00: "The signature ability
  cooldown of Sova, Fade, Skye, Breach, KAY/0 have been reduced from 60s to 50s." The wiki's page on
  Team Deathmatch has it come back after 48 s there.
- **Its limits** (the wiki's history and esports.net). v1.07: "No longer reveals Killjoy's Turrets".
  v1.01: "The Area-of-Effect indicators now only show up on the enemy’s minimap". v5.0: "Fixed a bug
  where revealed agents would sometimes briefly appear in an incorrect location on the minimap". In
  our words: v0.50 made its collision smaller so it doesn't stick on corners, and v1.01 reveals only
  the part of an enemy behind a wall that it sees. esports.net, with older numbers: "If you’re lucky
  or precise enough, your Recon Bolt can also attach itself onto an enemy.", and then "the enemy
  can’t destroy the bolt by themselves and will reveal their location and surroundings wherever they
  go".

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| Role "Initiator"; "Born from the eternal winter of Russia's tundra, Sova tracks, finds, and eliminates enemies" "with ruthless efficiency and precision."; "EQUIP a bow with recon bolt. FIRE to send the recon bolt forward, activating upon collision and" "Revealing the location of nearby enemies caught in the line of sight of the bolt." "Enemies can destroy this bolt. HOLD FIRE to extend the range of the projectile." "ALT FIRE to add up to two bounces to this arrow." | [playvalorant.com, Sova](https://playvalorant.com/en-us/agents/sova/) |
| Recon Bolt (E) "Cooldown time increased 35 >>> 40"; Shock Dart (Q) "Cost increased 100 >>> 150"; Owl Drone (C) "Cost increased 300 >>> 400"; Hunter's Fury (X) "Ultimate points required increased 7 >>> 8"; "Our goal here is to create a healthier pace of abilities throughout a round." | [VALORANT Patch Notes 3.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/), 22 June 2021 |
| "Recon Bolt (E) Health increased 1 >>> 20"; "increased the health of 1hp destructibles so that they aren't instantly vaporized."; "The following abilities are now immune to allied damage.", the Owl Drone and the Recon Bolt among them; "We want to ensure that abilities are interacting in a consistent manner across the board." In our words: the Incendiary, Hot Hands, Blaze, the Nanoswarm and the Snakebite now damage it | [VALORANT Patch Notes 5.12](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-5-12/), 6 December 2022 |
| Recon Bolt (E) "Total number of scans reduced 3>>>2" | [VALORANT Patch Notes 7.04](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-7-04/), 29 August 2023 |
| "Increased volume of Recon Bolt’s projectile loop and improved how the arrow’s sound travels through the air" "to make it easier to track"; "Audio priority and attenuation adjusted so that you can more reliably hear the arrow when multiple audio cues are present"; "Audio tech updated to make it easier understand the trajectory of the arrow, point of impact, and reveal radius" | [VALORANT Patch Notes 11.00](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-00/), 24 June 2025 |
| Recon Bolt "Cooldown increased from 40s → 60s"; "With this update, we're adjusting how often they can use their signature abilities within a round." "These abilities should remain impactful, but now demand more coordination and deliberate timing to unlock their full value." | [VALORANT Patch Notes 11.08](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-08/), 14 October 2025 |
| "We're reducing Signature Ability cooldowns for Initiators! (Sova, Fade, Skye, Breach, and KAY/O)"; "The signature ability cooldown of Sova, Fade, Skye, Breach, KAY/0 have been reduced from 60s to 50s."; "These changes aim to strike a balance between the old cooldowns and the changes from Patch 11.08 late last year." | [VALORANT Patch Notes 13.00](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-13-00/), 23 June 2026 |

### From the community

| What | Source |
| --- | --- |
| "EQUIP a bow with a recon bolt."; "Sova must equip before casting, nocking a recon arrow into his bow"; "one of four different projectile trajectories."; "The arrow increases its projectile class for every bar filled"; "Immediately cast as a Class 2 Projectile"; "0.333 seconds/1st bar filled for Class 3 Projectile"; "0.667 seconds/2nd bar filled for Class 4 Projectile"; "1.000 second/3rd bar filled for Class 5 Projectile"; "allow him to safely release his Fire key without firing the arrow."; "Sova can control the number of times this arrow can bounce off of terrain using Alt Fire."; "Upon contact with any surface the arrow will bounce against it depending on how many bounces have been added to it."; "If no more bounces are available to be used on a collision, the arrow will attach to the surface," "wind up briefly, then periodically emits sonar pulses over a few seconds."; "If these pulses hit any enemy agents that are also in the arrow's line of sight," "the enemy will be briefly revealed with a real-time silhouette."; "Enemies can deal damage to the recon bolt and destroy it."; "0.75 seconds"; "1 every 1.6 seconds". In our words: free and one use; a cooldown of 50 s; an equip of 0.8 s and an unequip of 0.7 s (from the game files, it says); a windup of 0.667 s (its own estimate); two pulses 1.6 s apart and a radius of 30 m (from the game files, it says); 20 health; immune to allies' damage; its numbers good for PC alone | [VALORANT Wiki, Recon Bolt](https://wiki.playvalorant.com/en-us/Recon_Bolt) (Weird Gloop) |
| History: v13.00 "Cooldown reduced from 60s to 50s"; v11.08 "Cooldown increased from 40s → 60s"; v7.04 "Total number of scans reduced 3 >>> 2"; v5.12 "Health increased 1 HP >>> 20 HP" and "Now immune to all allied damage"; v5.0 "Fixed a bug where revealed agents would sometimes briefly appear in an incorrect location on the minimap"; v3.0 "Cooldown time increased 35 >>> 40"; v1.07 "No longer reveals Killjoy's Turrets"; v1.01 "The Area-of-Effect indicators now only show up on the enemy’s minimap". In our words: v0.50 a smaller collision so it doesn't stick on corners, and the places it went through the map fixed; v1.01 only the part of an enemy behind a wall that it sees revealed; v1.03 more places it clipped walls fixed; v3.01 no longer looking deployed to enemies while it flies; v4.05 no longer destroyed by an Orbital Strike well off it; v6.07 its look; v11.00 its sounds; v12.00 its lightning no longer gone for the rest of a game after a switch to the knife fully drawn | The same |
| "an archer who became an agent for the VALORANT Protocol"; "Revealing the location of nearby enemies caught in the line of sight of the bolt". In our words: an Initiator with no passive: Owl Drone (C, 400 credits, one use), Shock Bolt (Q, 150, two), Recon Bolt (E, free, one, 3.2 s, a cooldown of 50 s, 20 health and reveals of 0.75 s) and Hunter's Fury (X, 8 points) | [VALORANT Wiki, Sova](https://wiki.playvalorant.com/en-us/Sova) |
| "The trajectory of a projectile is dependent on its speed and the scale at which it is affected by gravity."; "with higher classifications signifying a longer trajectory"; "Projectile classes are not official VALORANT terminology"; "are based on the interpretation of data from the game files by VALORANT Wiki editors". Class 2: speed 1800, gravity 0.3, the Recon Bolt with no bar; class 3: 2900, 0.45, one bar; class 4: 4125, 0.3, two bars; class 5: 4125, 0.15, fully drawn; for no bar and one, "+0.3 m offset" | [VALORANT Wiki, Projectile](https://wiki.playvalorant.com/en-us/Projectile) |
| "An agent with a Reveal debuff has their silhouette revealed to enemy agents through terrain."; "a real-time silhouette that continuously shows the affected agent's position for the duration of the reveal". In our words: the Recon Bolt's is a real-time reveal | [VALORANT Wiki, Status Effect](https://wiki.playvalorant.com/en-us/Status_Effect) |
| In our words: the Recon Bolt back 48 s after it's used, in Team Deathmatch | [VALORANT Wiki, Team Deathmatch](https://wiki.playvalorant.com/en-us/Team_Deathmatch) |
| Alt fire "cycles through adding zero, one, or two bounces to the arrow."; "effectively four distinct power levels corresponding to the segments on the charge bar."; "Higher charges result in faster, flatter trajectories."; two pulses "with a 1-second interval between scans", lasting "a total of 5 seconds before disappearing."; "the scan does not penetrate walls or solid objects."; "The bolt has 20 Health (HP)."; "Enemies can destroy the bolt."; "immune to damage from allied sources."; "the Recon Bolt is free." | [Boosting Ground, Sova overview](https://boosting-ground.com/Valorant/guides/agent-guides/sova-overview) (2023) |
| "Duration: 5.6s"; "Pulses: 3, every 1.8s"; "Reveal duration: 1s"; "Cooldown: 40s"; "If you’re lucky or precise enough, your Recon Bolt can also attach itself onto an enemy."; "the enemy can’t destroy the bolt by themselves and will reveal their location and surroundings wherever they go" | [esports.net, Sova guide](https://www.esports.net/wiki/guides/valorant-sova-guide) |
| "Duration: 3.2 seconds"; "it won't spot enemies through walls, so it'll need a clear sightline to detect their presence."; "Savvy enemies are likely to wait until it wears off before pushing forward." | [THESPIKE.GG, Sova](https://thespike.gg/valorant/agents/sova) |
| "If the arrow has line of sight of an enemy, it will reveal their location with an outline."; "E – free, 35 second cooldown." | [Mobalytics, Sova guide](https://mobalytics.gg/blog/sova-valorant-agent-guide/) |
| "If an Agent is Revealed their silhouette will be shown through all terrain letting everyone know where that Agent currently is." | [Red Bull, status effects](https://www.redbull.com/ca-en/status-effects-valorant) |

Where the sources disagree, the newest and the wiki are taken: Boosting Ground's pulses a second
apart, 5 s in all, and esports.net's three pulses 1.8 s apart over 5.6 s, reveals of 1 s and a
cooldown of 40 s are older than Patches 7.04 and 11.08 or disagree with the wiki, and Mobalytics'
35 s is older than Patch 3.0.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| Its flight at each bar | Clips of bolts loosed level at a flat floor from a known height, at each bar, noting where each lands and when |
| A bounce | Bolts bounced off a wall and a floor at known angles, noting where each goes next and when it lands |
| The windup, the pulses and its end | Clips stepped through from its sticking to each pulse and to its going |
| What a pulse sees | A second player standing round cover near a stuck bolt, a little further out each time, noting when they're revealed |
| What the revealed see and hear | A second player's view and sound as they're revealed |
| How far it's heard | A second player further from the bow, the bolt in the air and the bolt stuck each time, until each isn't heard |
| What of it is shot | Shots at a stuck bolt from known places, noting which break it |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| His kit | Sova is a fifth agent, an Initiator: Owl Drone (C, 400, one charge), Shock Bolt (Q, 150, two), the Recon Bolt (E, free, one) and Hunter's Fury (X, 8 points). The Recon Bolt alone is played: the rest read NOT YET on his card, on the bar and in the buy menu, and can't be bought | Confirmed (Initiator: Riot's page and Patch 13.00; the costs and points: Patch 3.0); community (the charges, free: the wiki) |
| Its charge | One, free each round; outside Team Deathmatch it comes back 50 s after it's loosed, and in it 48 s; on the course 1.5 s after | Confirmed (50 s: Patch 13.00); community (one, free and 48 s: the wiki) |
| In hand | E puts the bow in the fifth slot, ready 0.8 s later; E again or a number key puts it away, nothing spent. With it in hand you run at the knife's speed | Community (0.8 s: the wiki); estimate (the speed) |
| The draw | Once it's ready, fire held draws the bolt, a bar filling each third of a second, three at the most, shown as three bars under the crosshair | Confirmed (held fire: Riot's page); community (the bars and their times: the wiki) |
| Its bounces | Alt fire adds a bounce, two at the most, and once more takes them off again, shown as two diamonds under the bars. None as it comes into hand | Confirmed (two: Riot's page); community (cycling: Boosting Ground); estimate (none as it comes into hand) |
| Letting a draw go | E while it's drawn lets the draw go, the bow still in hand, and nothing's drawn again until fire's let go | Community (the wiki) |
| The loose | Fire let go with the bolt drawn looses it from the eye along the crosshair, with the bars filled and the bounces added; the charge is spent and the gun's back 0.7 s later. A tap looses it with no bar | Confirmed (fire: Riot's page); community (no bar at once, 0.7 s: the wiki); estimate (from the eye: the wiki's 0.3 m offset isn't applied) |
| Its flight | 18, 29, 41.25 and 41.25 m/s with no bar to three, falling at 0.3, 0.45, 0.3 and 0.15 of 9.8 m/s/s: loosed level from the eye of someone standing, no bar sticks in the floor 18.6 m ahead after 1.03 s, one bar 24.5 m ahead, two bars 42.6 m and three 60.3 m after 1.46 s. A box 0.1 m across that players and dummies don't stop, given up on after 10 s meeting nothing | Community (the classes: the wiki's page on projectiles); estimate (their units, 9.8, its size, players, 10 s) |
| A bounce | Off any surface it meets while it has bounces left, as off a mirror, its speed kept, a bounce spent | Community (any surface: the wiki); estimate (the mirror, the speed) |
| Sticking | To the next surface it meets with none left, standing out of it the way that surface faces | Community (the wiki) |
| Its pulses | Its first 0.667 s after it sticks, its second 1.6 s later, and it's gone 3.2 s after the first; it pulses on through its owner's death | Confirmed (two: Patch 7.04); community (0.667 s, 1.6 s: the wiki; 3.2 s: the wiki's page for Sova, read as from the first pulse); estimate (through a death) |
| Whom a pulse reveals | Each enemy with the middle of their head, their body or their legs within 30 m of a point 0.1 m off the surface it's in, with nothing hiding them from that point: the level, a cloud, a wall of fire or a wall of ice, as for anyone's eye, but not the spawns' barriers. On the course, with no sides, everyone but its owner | Confirmed (enemies in its sight: Riot's page); community (30 m: the wiki; no walls: THESPIKE.GG and Boosting Ground); estimate (the points, 0.1 m) |
| A reveal | From each pulse for 0.75 s, each one it revealed is on the minimap of its owner's side, so the fog of war sends them to that side, and that side's clients draw them, their body's boxes lit in the enemy colour through walls, moving as they move. Each client of the side is told whom it revealed and where they stood | Community (0.75 s, a real-time silhouette: the wiki; through terrain: its page on status effects); estimate (the minimap, the look) |
| Destroyed | Stuck, its shaft stands 0.5 m out of the surface, 0.2 m across, in the level bullets and knives are traced through, judged as the attacker's screen showed it: each that strikes it stops there, and an enemy's takes its damage off the bolt's 20 health, at none breaking it, so it pulses no more. Its owner's side's take nothing; on the course anyone's do, its owner's too | Confirmed (20, enemies, allies immune: Patch 5.12); estimate (the shaft, the course) |
| What others see and hear | Everyone sees the bolt fly and stick, a thin shaft of light, brightening through its windup, and each pulse as a shell of light sweeping out to 30 m. Its loose, its flight, its sticking, its pulses and its breaking are heard out to 30 m, as other abilities are; its string drawn back only by the one drawing it | Confirmed (heard: Patch 11.00); estimate (the rest) |
| What ends it | Its time, its breaking or a new round | Estimate |
| Its look | In hand, a short dark bow held upright, its string between its tips and a bolt of light blue beside the grip; the draw's bars and the bounces' diamonds under the crosshair | Estimate (ours) |
| Its sounds | A light rattle as the bow comes into hand, a slow scrape as its string's drawn back, a thin swish as it's loosed, a quick, quiet whoosh following it, a quick metallic strike as it sticks, a bell's ping each pulse and a sharp crack as it breaks | Estimate (ours, from free Roblox sounds) |

## 5. Design

### The rules

- **`AbilityConfig`** adds Sova, fifth of the agents' ids, his kit and his cooldowns in Team
  Deathmatch, makes the Recon Bolt played (its charge, its cooldown, its weapon and its line on his
  card), and adds `ReconBolt` (the unequip, the bars, the speeds and gravities, the bounces, the
  size, the air time, the windup, the pulses, their interval and radius, the reveal, the duration,
  where a pulse looks from, its health and its shaft), each with its status and source. `unequip`
  gives the gun back 0.7 s after the loose.
- **`WeaponConfig`** adds `bow`, the bow in hand, 35th of the weapons' wire ids, firing nothing.
- **`AbilitySim`** plays it: E puts the bow in hand with nothing drawn and no bounces, and `bow`,
  each tick after the weapons' step, draws it with fire held, adds bounces with alt fire and looses
  it as fire's let go, a `bolt` cast with its bars and bounces; E while it's drawn lets the draw go
  (`letDown`); `bars` says how far it's drawn, and `summary` adds `draw` and `bounce` to `VFKit`.
- **`BoltSim`** is new: the bolt's flight, bounces and sticking (`shoot`, `step`, `fly`, `at`), a
  bolt stuck and its pulses (`stuck`, `pulseAt`, `ends`, `standing`, `eye`), whom a pulse reveals
  (`reveals`) and its shaft in the level shots are traced through (`box`, `level`, `piece`).
  **`FireballSim`** shares its sweep (`sweep`) with it.
- **`PlayerSim`** calls `bow` after the weapons' step, and **`PlayerCodec`** carries the bounces,
  the let-down, alt fire held and the draw's start in the ack.
- **`SoundConfig`** adds its sounds.

### The server

- **`ReconServer`** is new. It flies each bolt loosed at once, as nothing changes its path, and
  tells every client its path, how long after the loose it sticks and where (`flight`); gives its
  pulses on the server's clock and judges whom each reveals, telling its owner's side whom and where
  (`pulse`), and everyone else of the pulse alone; puts its shaft in the level shots are traced
  through (`CombatServer.levelAt`), takes an enemy's bullets and knives off its health
  (`CombatServer.struck`) and tells every client when it breaks (`break`); sets `VFLastBolt`,
  `VFLastRecon` and `VFBoltHealth`; and forgets every bolt with a new round (`clear`, from
  **`Arena`**).
- **`MinimapServer`** adds whom the pulses reveal to each side (`ReconServer.revealed`) to whom that
  side sees, so the fog of war sends them; **`init.server`** starts and steps it.

### The client

- **`ReconView`** is new: the bow's bars and bounces under the crosshair, and the scrape as a draw
  starts; your own bolts flown at once as you loose them, through `BoltSim`, and others' from the
  server; each bolt in the air and stuck, its pulses and its breaking as the frame on your screen
  reaches them, with their sounds; and the silhouettes the pulses reveal to your side.
- **`ClientShots`** traces your shots through the shafts too (`bolts`), as the server does;
  **`PlayerController`** checks the ack's new fields; **`AbilityHud`** lights E with `EQUIP` while
  the bow comes into hand; **`AbilityEffects`** sounds the loose; **`WeaponLooks`** gives the bow
  its look; **`init.client`** starts the view.

### Not here yet

- **His other abilities.** The Owl Drone, the Shock Bolt and Hunter's Fury read NOT YET.
- **Stuck to a player.** It flies through players and dummies, where esports.net has it stick to an
  enemy and reveal them wherever they go.
- **Other damage.** Only bullets and knives take its health: no fire or other ability does, though
  Patch 5.12 has the Incendiary, Hot Hands, Blaze, the Nanoswarm and the Snakebite damage it.
- **An enemy's minimap.** Enemies near it don't see where it reaches on their minimap (v1.01).
- **What the revealed see or hear.** Nothing tells someone they're revealed but the pulse's sound;
  no source says what they get.
- **Part of a body** (v1.01). A revealed body is drawn whole, not only the part the pulse sees.
- **A loop in flight** (Patch 11.00). Its flight is one whoosh following it, not a loop.
- **Shot in flight.** Only a stuck bolt's shaft can be shot.
- **The 0.3 m offset** (the wiki's page on projectiles). It leaves from the eye.
- **Walls and clouds in flight.** Its flight meets the level alone, so it flies through Sage's walls
  of ice, Phoenix's walls of fire and the clouds; a pulse doesn't see through them.
- **The buy phase.** It can be loosed in the buy phase, as the other throws here can.
- **The scrape heard by others.** Only the one drawing hears the string drawn back.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | Sova and his kit, the Recon Bolt played; `ReconBolt`'s numbers, each with its status and source; `unequip` |
| `src/shared/Weapons/WeaponConfig.luau` | `bow`, the bow in hand, and its wire id |
| `src/shared/Abilities/BoltSim.luau` | New: its flight, bounces and sticking, its pulses, whom a pulse reveals, and its shaft in the level |
| `src/shared/Abilities/AbilitySim.luau`, `src/shared/Abilities/FireballSim.luau` | The bow in hand, its draw, bounces, let-down and loose, and `bars`; the sweep shared |
| `src/shared/PlayerSim.luau`, `src/shared/Net/PlayerCodec.luau` | The bow each tick; the ack carrying the draw and the bounces |
| `src/shared/Audio/SoundConfig.luau` | Its sounds |
| `src/server/ReconServer.luau` | New: each bolt flown, its pulses and whom they reveal, its shaft shot and broken, `VFLastBolt`, `VFLastRecon` and `VFBoltHealth` |
| `src/server/MinimapServer.luau`, `src/server/Arena.luau`, `src/server/init.server.luau` | Reveals on the minimap; every bolt gone with a new round; `ReconServer` started and stepped |
| `src/client/ReconView.luau` | New: the bars and bounces, the bolts, their pulses and breaking, and the silhouettes |
| `src/client/Combat/ClientShots.luau`, `src/client/PlayerController.luau`, `src/client/AbilityHud.luau`, `src/client/AbilityEffects.luau`, `src/client/Combat/WeaponLooks.luau`, `src/client/init.client.luau` | Shots traced through the shafts; the ack checked; E on the bar; the loose's sound; the bow's look; the view started |
| `tests/reconbolt.luau` | New: its numbers, the bow in hand, the draw and the loose, the bounces, letting a draw go, a new life, its flight, its pulses, its reveals, its shaft, and the wire |
| `tests/arsenal.luau` | The weapons' ids |

## 7. Debug tools

- A player's `VFLastBolt` is where their last bolt stuck, in metres, set as it sticks; `VFLastRecon`
  the names its last pulse revealed, in order, or nothing; and `VFBoltHealth` the health it has
  left.
- `VFKit` reads `C0/1 Q0/2 E1/1 X0/8` on the course, and ends in `equip` while the bow's in hand,
  with `draw` and the bars while it's drawn and `bounce` and the bounces once any are added.
- PlayerGui's `VFRecon` carries `Bow` (whether the bow's in hand), `Bars` (the bars drawn),
  `Bounces` (the bounces added), `Bolts` (the bolts drawn, in the air or stuck) and `Revealed` (the
  silhouettes shown); its `Bow` frame is the bars and diamonds.
- `Workspace.VFRecon` holds each bolt as a `Bolt` part, each pulse as a `Pulse` ball and each
  silhouette as a `Reveal_<id>` model, its `Entity` attribute whose it is.
- `VFTestButtons` 16384 presses E, 128 the left button and 256 the right, so it can be drawn, given
  bounces, let go and loosed without a key or a mouse button; `VFTestYaw`, `VFTestPitch` and
  `VFTestAimPoint` aim.

## 8. Refinement loop

1. Loose bolts level at a flat floor from a known height at each bar, and change `speed`, `gravity`
   and `worldGravity` until each lands where the reference's does, and then the offset.
2. Bounce bolts off a wall and a floor, and change `bounce`.
3. Step through the windup, the pulses and the end, and change `windup`, `interval` and `duration`.
4. Stand round cover near a stuck bolt, and change `lift`, `radius` and the points a pulse must see.
5. Shoot stuck bolts, and change `length` and `width`.
6. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The Recon Bolt lit on Sova's card and the bar, the rest of his kit NOT YET there and in the buy
  menu, `E1/1` on the course, and the bow in hand 0.8 s after E.
- The draw: the bars a third of a second apart, the bounces added and taken off by alt fire, E
  letting the draw go, and E again putting the bow away.
- The loose: the gun back 0.7 s after; the bolt's flight, sticking where `BoltSim` has it, a tap
  18.6 m down the lane, and further with more bars.
- Bounces off the floor and the backstop.
- The pulses: the windup, two 1.6 s apart, the shell of light, the pings, and gone 3.2 s after the
  first.
- The reveals: the silhouettes through walls, `VFLastRecon`, nobody past 30 m, and nobody a wall
  hides, even right behind it.
- Shot to pieces: a shot at its shaft breaking it, and no more pulses.
- With other players: seen and heard; on the course, revealing everyone but its owner, to its owner
  alone; in Skirmish, revealing enemies alone to its owner's side, through walls and on the minimap;
  allies' shots doing nothing and an enemy's breaking it; and its charge back 50 s after it's
  loosed.

Section 48 of the [Studio checklist](../studio-checklist.md) covers these.
