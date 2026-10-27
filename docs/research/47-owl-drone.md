# System 47: Sova's Owl Drone

Sova's Owl Drone is his C, a basic ability, and the last of his kit played. C puts the drone in
hand, ready 0.9 s later, and fire sends it out from his eye: his view is the drone's for its 7 s, or
until C again, while his body stands where he left it. For its first 0.25 s it flies on as it was
sent, and then the keys fly it, along the ground at 5 m/s the way the view faces, and up with jump
or down with crouch at 3 m/s, never more than 3 m over the floor below it. Fire from it shoots a
dart along the crosshair, one every 5 s at the most: an enemy it strikes is pinged twice, 1.6 s
after it and 1.2 s after that, each ping revealing them to his side for 0.6 s. Enemies can shoot it
down: it has 100 health, and as it breaks or its time's up his view's back at his eye, and his gun's
back in hand 0.7 s later. This system adds the Owl Drone as Sova's C, its flight in his own
simulation, its darts and their pings, its health, who's sent it through the fog of war, and what
everyone sees and hears of it. Every ability of Sova's is played now.

As before, everything comes from public sources: five of Riot's patch notes and, for what Riot
doesn't give, the VALORANT Wiki's pages on Sova and on Team Deathmatch (read for system 44), the
guides of seventeen sites (THESPIKE.GG's two, Boosting Ground's, esports.net's, Mobalytics' two,
valoranttracker.org's, esportsdriven.com's, EarlyGame's, Hotspawn's, Aim Lab's, Dexerto's,
Codashop's, dodge.gg's, op.gg's, Rankforge's, Gfinity's, Upcomer's and Dot Esports'), a library's
review, and the press's reports of Patch 4.08, of Patch 9.00 and of two bugs. Riot's page for Sova
doesn't describe the Owl Drone, and the wiki's own page on it couldn't be read: its site refused
every fetch, so whatever it gives of its speed, its height or its dart isn't here. bo3.gg's, Red
Bull's, AFK Gaming's and Dexerto's wiki pages on Sova gave no text we could read. No game files,
memory or network traffic were used, and nothing was read from the live game. Here the wiki's
numbers are labelled community, and so is Riot's text for the ability, which we could read only as
THESPIKE.GG, Mobalytics, Aim Lab and Dexerto quote it. Riot gives its cost, its 7 s, its 100 health,
its two pings and their times, its keys for flying up and down, the '[Target Hit]' text and its 2 s,
its green crosshair, its immunity to allied damage and how drones show on the minimap; the wiki
gives its one charge, its dart's 5 s, its 0.6 s reveals, enemies destroying it and its cooldown in
Team Deathmatch; the guides give its equip, deploy and unequip, jump and crouch flying it, its
greatest height depending on the ground below it, Sova still while it flies and its rotors' noise.
Its speed, its climb and how quickly it gets to them, its greatest height, its size, its dart's
reach, how far it's heard, its look and its sounds are ours. Nothing in this system is measured.
Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by the game's maker (Riot's patch notes) |
| **Community** | Published by a guide, a wiki or the press, not by the maker (the VALORANT Wiki, run by Weird Gloop) |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |

No source we could read gives how fast it flies or climbs, how quickly it gets to those speeds, how
high over the floor it can go, how big it is, how far a dart reaches or how fast it flies, how far
its rotors are heard, whether players stop it, what else damages it, or what a dart does while the
spawns' barriers are up. Ours are in section 4: 5 m/s, under a run's 6.75 m/s, as Dot Esports has it
feel "very slow"; 3 m/s; a quarter of a second from a stop; 3 m; 0.4 m across and 0.25 m high; 40 m,
at once along the crosshair; 15 m; through players; bullets and knives alone; and nobody struck, as
for Hunter's Fury's blasts.

## 1. Observable behaviour

- **In hand** (Riot's text, Boosting Ground and op.gg). Riot's text, as THESPIKE.GG gives it: "EQUIP
  an owl drone. FIRE to deploy and take control of movement of the drone." Boosting Ground: "Equip
  time is 0.9 seconds, deploy time is 0.25 seconds, and unequip time is 0.7 seconds." op.gg: "EQUIP
  a destructible Owl Drone. FIRE to take control."
- **Flying it** (Patch 2.05, Aim Lab, Boosting Ground, Dot Esports, dodge.gg and EarlyGame).
  Patch 2.05: "Added unique keybinds to the option menu for flying up and down when using Owl
  Drone", and "Sova Drone and Astra ascend/descend binds now properly respect changed jump/crouch
  keybinds". Aim Lab: "Use your jump key bind to raise the drone's elevation, and your crouch key
  bind to lower the elevation." Boosting Ground: "While piloting, he can fly it around the map to
  scout." In our words: it has the drone's greatest height depend on the ground below it. Dot
  Esports: it "feels very slow and is clunky to control at first", and it "doesn't have a
  sensitivity cap". dodge.gg: "fly it through doorways, around corners, and into site to spot
  enemies." EarlyGame: "fly the drone below head level".
- **His body** (valoranttracker.org, dodge.gg and esportsdriven.com). valoranttracker.org: "As long
  as you use this ability, the Sova will remain in the same place." dodge.gg: "Piloting the drone
  means Sova is stationary and defenseless". esportsdriven.com: "if damage is done to the agent, the
  drone's casts will stop."
- **Its time** (Patch 4.08, the wiki and the guides). Patch 4.08: "Duration reduced 10s >>> 7s", as
  "A reduced Drone duration means Sova has to incur more risk in his positioning to clear deeper
  angles". In our words: the wiki gives 7 s. THESPIKE.GG: "Duration: 7 seconds". Boosting Ground:
  "Its flight duration is 7 seconds". Twinfinite, before the patch: "Its flight time is two seconds
  less, from 10 to 8 seconds."
- **A dart** (Riot's text, the wiki and the guides). Riot's text: "While in control of the drone,
  FIRE to shoot a marking dart." "This dart will Reveal the location of any player struck by the
  dart." In our words: the wiki gives its cooldown as 5 s. Boosting Ground: "The dart itself has a
  5-second cooldown after firing." THESPIKE.GG: "Dart cooldown: 5 seconds". Hotspawn: "with the
  ability to second cast the dart if the drone survives the five-second recharge."
  valoranttracker.org: "Dart Cooldown | 5 seconds (Refreshes On-Hit, Can Stack)". Mobalytics: "You
  can fire it multiple times but it has a long cooldown". Patch 4.08: "Fixed a bug with Owl Drone,
  where the Dart Cooldown UI element would not properly update after tagging an opponent."
- **Its pings** (Patch 4.08, the wiki and the guides). Patch 4.08: "Number of reveal pings reduced
  3 >>> 2"; "Initial delay before first ping reveals increased 1.2s >>> 1.6s*"; "*Delay between the
  first and second ping remains 1.2s". THESPIKE.GG: "Reveals: 1st ping 1.6 seconds after dart
  impact, second 1.2 seconds after the first ping". In our words: the wiki has each a real-time
  reveal of 0.6 s, as Boosting Ground does. esports.net: "Reveal Duration: 0.8s twice". Mobalytics:
  "reveal duration 0.8s twice. First after 1.6s then 1.2s". Boosting Ground: "if this dart hits an
  enemy player, it reveals their location through walls with intermittent pings." esports.net: "If
  you successfully mark an enemy with the dart, their location will be revealed to you and your
  team."
- **[Target Hit]** (Patch 4.08). "Removed delay on [Target Hit] confirmation text"; "[Target Hit]
  confirmation text now remains on the player HUD when transitioning out of Owl Drone."; "[Target
  Hit] confirmation text now remains on screen for 2s, previously 1s"; "Adjusted audio on drone dart
  hits for both Sova, and the player hit, to make confirmations more noticeable".
- **Its crosshair** (Patch 4.08). "Changed crosshair color to green to better stand out against the
  white HUD".
- **Its health** (Patch 4.08, Riot's text, Codashop, Patch 5.12 and esports.net). Patch 4.08:
  "Health reduced 125 >>> 100". Riot's text: "Enemies can destroy the Owl Drone." Codashop: "It
  takes a few shots for it to go down". Patch 5.12: "The following abilities are now immune to
  allied damage.", the Owl Drone among them, and "Abilities that output damage will now universally
  damage enemy objects that can be damaged." esports.net, of Patch 9.00 on console: "Sova's Owl
  Drone's HP is now 100, up from 60."
- **Its sound** (valoranttracker.org). "Makes noise because of engine rotors."
- **Its cost** (Patch 3.0, the wiki and the guides). Patch 3.0: "Cost increased 300 >>> 400". ONE
  Esports, after Patch 4.08: "It still costs 400 credits." Boosting Ground: "Sova can purchase one
  per round." In our words: the wiki's page on Team Deathmatch has its charge back 51 s after it's
  used there.
- **The minimap** (Patch 11.07). "we have adjusted some of how controllable utility and drones are
  shown on the minimap." "Their icons now have a directional arrow to indicate where they are
  facing," "ally and enemy color coding", the Owl Drone among them.
- **Its world** (Dexerto and GGRecon). Dexerto, of a bug in Patch 1.11: "Sova can be seen jumping on
  top of his Owl Drone and flying around the map causing sheer chaos." GGRecon, of another: a player
  "shared eight, YES EIGHT, different locations where Sova's drone could escape the usual confines"
  of the maps, and a developer answered "We'll look at fixing these for the next patch coming up."

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| "Added unique keybinds to the option menu for flying up and down when using Owl Drone"; "Sova Drone and Astra ascend/descend binds now properly respect changed jump/crouch keybinds"; "Fixed a rare bug that could leave players unable to move or process inputs until they died" "when entering or returning from Astra's astral form, Sova's drone, Skye's scout, or Cypher's Spy Camera." | [VALORANT Patch Notes 2.05](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-2-05/), 16 March 2021 |
| Owl Drone (C) "Cost increased 300 >>> 400" | [VALORANT Patch Notes 3.0](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-3-0/), 22 June 2021 |
| "We wanted to focus on addressing the amount of space that the Owl Drone practically guaranteed," "and introduce additional counter play opportunities for opponents."; "A reduced Drone duration means Sova has to incur more risk in his positioning to clear deeper angles,"; Owl Drone "Duration reduced 10s >>> 7s"; "Health reduced 125 >>> 100"; "Number of reveal pings reduced 3 >>> 2"; "Initial delay before first ping reveals increased 1.2s >>> 1.6s*"; "*Delay between the first and second ping remains 1.2s"; "Changed crosshair color to green to better stand out against the white HUD"; "Removed delay on [Target Hit] confirmation text"; "[Target Hit] confirmation text now remains on the player HUD when transitioning out of Owl Drone."; "[Target Hit] confirmation text now remains on screen for 2s, previously 1s"; "Adjusted audio on drone dart hits for both Sova, and the player hit, to make confirmations more noticeable"; "Fixed a bug with Owl Drone, where the Dart Cooldown UI element would not properly update after tagging an opponent." | [VALORANT Patch Notes 4.08](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-4-08/), 27 April 2022 |
| "The following abilities are now immune to allied damage.", the Owl Drone among them; "Abilities that output damage will now universally damage enemy objects that can be damaged." | [VALORANT Patch Notes 5.12](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-5-12/), 6 December 2022 |
| "we have adjusted some of how controllable utility and drones are shown on the minimap."; "Their icons now have a directional arrow to indicate where they are facing," "ally and enemy color coding, and added a seeking-state for drones that lock-on to players."; the Owl Drone among them | [VALORANT Patch Notes 11.07](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-11-07/) |
| In our words: his page describes his Shock Bolt and his Recon Bolt, but not the Owl Drone | [playvalorant.com, Sova](https://playvalorant.com/en-us/agents/sova/) |

### From the community

| What | Source |
| --- | --- |
| In our words: Owl Drone (C), 400 credits, one use, 7 s, a dart cooldown of 5 s, 100 health and real-time reveals of 0.6 s; "Enemies can destroy the Owl Drone." | [VALORANT Wiki, Sova](https://wiki.playvalorant.com/en-us/Sova) (Weird Gloop), read for system 44 |
| In our words: the Owl Drone's charge back 51 s after it's used in Team Deathmatch | [VALORANT Wiki, Team Deathmatch](https://wiki.playvalorant.com/en-us/Team_Deathmatch) |
| Riot's text, as it gives it: "EQUIP an owl drone. FIRE to deploy and take control of movement of the drone." "While in control of the drone, FIRE to shoot a marking dart." "This dart will Reveal the location of any player struck by the dart." "Enemies can destroy the Owl Drone."; and "Ability type: Basic"; "Duration: 7 seconds"; "Dart cooldown: 5 seconds"; "Health: 100HP"; "Reveals: 1st ping 1.6 seconds after dart impact, second 1.2 seconds after the first ping"; "Cost: 400 creds"; "Max charges: 1"; "you can counter this if you get a teammate to follow the drone a few paces behind." | [THESPIKE.GG, Sova](https://www.thespike.gg/valorant/agents/sova) |
| Riot's text and the same numbers; "Owl Drone can be pretty easy for enemies to destroy" | [THESPIKE.GG, Agents of VALORANT: Sova](https://www.thespike.gg/news/agents-of-valorant-sova/95), 14 May 2020 |
| "Sova equips and deploys a controllable Owl Drone."; "The Owl Drone costs 400 Credits."; "Sova can purchase one per round."; "Its flight duration is 7 seconds"; "it has 100 HP"; "Equip time is 0.9 seconds, deploy time is 0.25 seconds, and unequip time is 0.7 seconds."; "Pressing fire while piloting shoots a marking dart."; "The dart itself has a 5-second cooldown after firing."; "if this dart hits an enemy player, it reveals their location through walls with intermittent pings."; "While piloting, he can fly it around the map to scout."; "Enemies can shoot and destroy the drone." In our words: two pings, each revealing for 0.6 s, and its greatest height depending on the ground below it | [Boosting Ground, Sova overview](https://boosting-ground.com/Valorant/guides/agent-guides/sova-overview) (2023) |
| "Sova equips an Owl Drone, allowing you to take full control of the drone and scout the areas around you."; "While using the drone, you're able to shoot a marking dart."; "If you successfully mark an enemy with the dart, their location will be revealed to you and your team."; "Cost: 400"; "Duration: 7s"; "Health: 100 HP"; "Dart cooldown: 5s"; "Reveal Duration: 0.8s twice" | [esports.net, Sova guide](https://www.esports.net/wiki/guides/valorant-sova-guide) (2025) |
| Riot's text, and "7s"; "100 HP"; "5s"; "reveal duration 0.8s twice. First after 1.6s then 1.2s" | [Mobalytics, Sova overview](https://mobalytics.gg/valorant/agent/sova/overview) |
| "Owl Drone (C – 300 credits)"; "Equip and fire an owl drone that you take POV control of."; "While flying the owl, you can fire a dart which temporarily reveals its target's location."; "You can fire it multiple times but it has a long cooldown" "so you'll need to fire early and have the drone survive long enough." | [Mobalytics, Sova guide](https://mobalytics.gg/blog/sova-valorant-agent-guide/) |
| "300 • 1 Use"; "EXECUTE the launch of the flying drone."; "LEFT CLICK to release the drone and start observing."; "LEFT CLICK during the Owl Drone mode, to shoot by a dart into the opponent to highlight him."; "HP \| 120"; "Duration \| 10 seconds"; "Dart Cooldown \| 5 seconds (Refreshes On-Hit, Can Stack)"; "Makes noise because of engine rotors."; "Dart pings 3 times, revealing for 0.8 seconds every 1.2 seconds."; "As long as you use this ability, the Sova will remain in the same place." | [valoranttracker.org, Sova](https://valoranttracker.org/agents/sova) |
| "an Intel ability, which Sova must equip before casting."; "if damage is done to the agent, the drone's casts will stop." In our words: 400 credits, one use, 10 s, 120 health, a dart cooldown of 5 s, and three pings 1.2 s apart, each revealing for 0.6 s; Sova still while he flies it | [esportsdriven.com, Sova guide](https://esportsdriven.com/valorant/guides/71/sova-valorant-guide) (2022) |
| "a 10 second flight time"; "fly the drone below head level"; "1 Tracking dart round with a 5 second cool down."; "0.6 seconds reveal per tick, with 1 tick every 1.2 seconds at a total of 3 ticks."; "shoot down the drone on sight"; "300$"; "1 Charge" | [EarlyGame, Sova guide](https://earlygame.com/valorant/sova-agent-guide-abilities), 1 December 2021 |
| "Sova can buy an Owl Drone for 300 credits and spend it to scout around corners safely."; "The drone last 10 seconds, has a small health pool and can fire a tagging dart," "with the ability to second cast the dart if the drone survives the five-second recharge."; "What the tagging dart does is reveal the opponent's movement for several seconds."; "This drone can act as the first bullet sponge for an ally" | [Hotspawn, Sova guide](https://www.hotspawn.com/valorant/guides/how-to-play-sova), 13 May 2020 |
| "Equip an owl drone. Fire to deploy and take control of the movement of the drone."; "Use your jump key bind to raise the drone's elevation, and your crouch key bind to lower the elevation."; "While in control of the drone, Fire to shoot a marking dart."; "This dart will reveal the location of any player struck by the dart." | [Aim Lab, Sova](https://aimlabs.com/articles/?p=2336), 4 August 2023 |
| "Ability 1 — Owl Drone (400 Creds)."; Riot's text; it "has a great cost-to-effect ratio", but "it's relatively easy for the enemy to destroy." | [Dexerto, how to play Sova](https://www.dexerto.com/valorant/how-to-play-as-sova-valorants-initiator-agent-with-a-thirst-for-intel-1347924/), 11 January 2022 |
| "Owl Drone (C) lets Sova summon an owl drone and scout ahead."; "With the drone, Sova can fire a marking dart that reveals the enemies' location."; "Remember that your Owl Drone costs 400 credits and lasts only 7 seconds."; "It takes a few shots for it to go down, so you and your teammates can use this as a distraction before picking off your enemies." | [Codashop, Sova guide](https://news.codashop.com/my/?p=21597), 16 February 2023 |
| "Owl Drone (C) — 400 credits, 1 charge"; "Deploy the drone and pilot it remotely — fly it through doorways, around corners, and into site to spot enemies."; "Fire the drone's marking dart to tag an enemy, revealing their location through walls" "with periodic pulses for several seconds."; "Piloting the drone means Sova is stationary and defenseless" | [dodge.gg, Sova guide 2026](https://www.dodge.gg/en-US/valorant/news/sova-guide-2026), 21 March 2026 |
| "EQUIP a destructible Owl Drone. FIRE to take control. FIRE again to shoot a dart that repeatedly reveals enemies." In our words: 400 credits | [op.gg, Sova](https://op.gg/valorant/agents/Sova) |
| "Owl Drone scouts ahead and can tag enemies."; among the common mistakes, "Flying the Owl Drone without teammate support." | [Rankforge, Sova guide](https://rankforge.gg/blog/sova-guide-valorant), 9 July 2026 |
| "After triggering this ability, Sova will release a flying drone that he will use to shoot a dart at his enemies."; "If an opponent is hit, its location will be revealed to Sova and his teammates." | [Gfinity, Sova guide](https://www.gfinityesports.com/article/valorant-sova-agent-guide-abilities-tips-and-tricks), 29 April 2024 |
| "Sova's second basic ability, Owl Drone, allows you to send a drone into the air to scan the area ahead of you."; "This ability does not do damage and is solely to gain information." | [Upcomer, Sova guide](https://upcomer.com/valorant-guide-how-to-play-sova-the-initiator), 8 April 2020 |
| It "doesn't have a sensitivity cap", and it "feels very slow and is clunky to control at first."; its use is to find enemies and "throw them a dart that will keep revealing them until they take it out." | [Dot Esports, Sova's drone](https://dotesports.com/valorant/news/sovas-drone-has-a-secret-feature-almost-no-valorant-player-knows), 30 May 2023 |
| "This enables Sova to equip and launch a drone, which he is able to control."; "Once the drone is within sight of an opposing player, Sova can shoot a tracking dart from the drone,"; it "will reveal the location of the tracked player until he or she removes the tracker."; "But, enemy players can shoot and destroy the drone, so be careful to stay hidden." | [Santa Clarita Public Library, Valorant character reviews: Sova](https://teens.santaclaritalibrary.com/2021/05/31/valorant-character-reviews-sova/), 31 May 2021 |
| "Owl Drone duration has been reduced to seven seconds"; "drone health is down to 100 from 125"; "tagged enemies are only pinged twice, instead of three times."; "The initial delay before the first ping has been increased from 1.2 to 1.6 seconds"; "It still costs 400 credits."; and a post it quotes from before the patch: "Drone lasts only 8s and now scans only two times" | [ONE Esports, Patch 4.08](https://www.oneesports.gg/valorant/sova-nerf-patch-4-08-shock-dart-drone/), 26 April 2022 |
| Before Patch 4.08: "Its flight time is two seconds less, from 10 to 8 seconds."; "Further, it only tags enemies for two pings as opposed to the three previously." | [Twinfinite, Sova's nerf](https://twinfinite.net/guides/valorant-sova-nerf-explained/) |
| "Sova Buff (Console)": "Sova's Owl Drone's HP is now 100, up from 60." | [esports.net, Patch 9.00](https://www.esports.net/news/valorant/valorant-patch-9-00-notes/), 25 June 2024 |
| A bug of Patch 1.11: "Sova can be seen jumping on top of his Owl Drone and flying around the map causing sheer chaos." | [Dexerto, Patch 1.11's drone bug](https://www.dexerto.com/valorant/bug-valorant-patch-1-11-lets-sova-ride-drone-1447257/), 5 November 2020 |
| Normally the drone "should be able to travel a short distance"; a player "shared eight, YES EIGHT, different locations where Sova's drone could escape the usual confines" of the maps; a developer: "We'll look at fixing these for the next patch coming up." | [GGRecon, Sova's drone glitch](https://www.ggrecon.com/articles/sova-drone-glitch-valorant) |

Where the sources disagree, Riot's notes and the wiki are taken: the 300 credits of Mobalytics',
valoranttracker.org's, EarlyGame's and Hotspawn's guides are the cost before Patch 3.0, and their
10 s, three pings and 120 or 125 health are from before Patch 4.08. Twinfinite's 8 s and the post
ONE Esports quotes came before the patch, whose notes give 7 s. THESPIKE.GG's page of May 2020 has
the numbers after both patches, which nothing we could read explains. Each ping's reveal is the
wiki's 0.6 s, which Boosting Ground gives too, not esports.net's and Mobalytics' 0.8 s. The 100
health is PC's: esports.net's report of Patch 9.00 has console's raised to it from 60.
esportsdriven.com has damage to Sova end its flight, and valoranttracker.org its dart's cooldown
"Refreshes On-Hit, Can Stack", which nothing else we could read says. Dot Esports and the library's
review have a dart reveal until it's taken out, which Riot's two pings don't.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| Its speed along the ground and up or down, and how quickly it gets to them | Clips stepped through of the drone flown a set distance from a stop, along the ground and up |
| Its greatest height | The drone flown up as far as it goes over flat ground, over a box and over a drop |
| Its size | Through how narrow a gap it flies, and where shots at its edges stop striking it |
| A dart's reach and speed | A dart at a player further away each time, and clips stepped through from the click to the strike |
| Its equip, deploy and unequip | Clips stepped through from C to the drone ready, from the click to the keys flying it, and from its end to the gun back |
| Each ping's reveal | Clips stepped through from a ping to the silhouette going |
| How far it's heard | A second player further from it each time, until its rotors go quiet |
| What damages it | Each weapon's shots at it, counted until it breaks, and each damaging ability at it |
| Players | The drone flown into a player, and a player jumping onto it |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| His kit | The Owl Drone is played now, the last of his kit: it's lit on his card, the bar and in the buy menu, and nothing of his reads NOT YET | Confirmed (C: Patch 3.0) |
| Its cost and charge | One. In the spike rounds it's bought for 400, and nothing brings it back that round once it's spent; on the course and in Skirmish it's there every life, and on the course it comes back 1.5 s after it's spent; in Team Deathmatch, 51 s after | Confirmed (400: Patch 3.0); community (one: the wiki; 51 s: the wiki's page on Team Deathmatch) |
| In hand | C puts the drone in the fifth slot, ready 0.9 s later; C again puts it away, nothing spent. With it in hand you run at the knife's speed | Community (0.9 s: Boosting Ground); estimate (the speed) |
| Sent out | Fire, once it's ready, spends the charge and sends the drone out from his eye, level, the way he faces, at 5 m/s; his view is the drone's from then until its flight's over. For its deploy, 0.25 s, it flies on as it was sent, and then the keys fly it | Community (fire to deploy: Riot's text; 0.25 s: Boosting Ground); estimate (the eye, level, the speed) |
| Flying it | The moving keys fly it along the ground the way the view faces, at 5 m/s, as they'd move him, walk or not; jump flies it up and crouch down, at 3 m/s. It gets to what the keys ask at 20 m/s each second, and with none held it comes to a stop: sent out with no keys, it stops 1.8 m in front of his eye. The mouse turns its view as it would his | Confirmed (up and down: Patch 2.05); community (jump and crouch: Aim Lab); estimate (the speeds, how quickly) |
| Its height | Its middle goes no higher than 3 m over the floor below it: a climb stops there, and over a drop it sinks back at 3 m/s, as it does with no floor within 20 m under it | Community (its height by the ground below it: Boosting Ground); estimate (3 m, 20 m) |
| Its box | 0.4 m across and 0.25 m high, square to the world. It flies through the world as a player moves, stopped by walls, floors and ceilings and sliding along them, with no gravity; it flies through players and dummies | Estimate (ours) |
| His body | Held where he left it, facing the way he faced: nothing pressed moves him, fires or casts; he stays crouched if he was, falls and slides on as he was, and a plant or defuse under way stops as if let go of. Nothing is picked up from the ground. The gun's away from the launch until 0.7 s after the flight's over | Community (still: valoranttracker.org and dodge.gg; 0.7 s: Boosting Ground); estimate (the rest) |
| A dart | Fire, once the keys fly it, no sooner than 5 s after the last, shoots a dart from its middle along the crosshair, at once, as far as 40 m, through nothing: it strikes the first enemy in play or dummy its line meets, where his screen showed them, as a bullet does; on the course anyone but him. It does no damage | Community (fire: Riot's text; 5 s: the wiki, Boosting Ground and THESPIKE.GG; no damage: Upcomer); estimate (40 m, at once, as his screen showed them) |
| The buy phase | While the spawns' barriers are up, a buy phase or Team Deathmatch's pre-game, a dart strikes nobody | Estimate (ours, as for Hunter's Fury's blasts) |
| Its pings | Whoever a dart strikes is pinged twice, 1.6 s after it struck and 1.2 s after that, each revealing them to his side for 0.6 s as a Recon Bolt's pulse does: their silhouette through walls where the server had them, and on the minimap; on the course, to him alone. They ping on once the drone's gone, but not once they're dead or out of play | Confirmed (two, 1.6 s, 1.2 s: Patch 4.08); community (0.6 s: the wiki and Boosting Ground; to his side: esports.net and Gfinity); estimate (as the Recon Bolt's) |
| [Target Hit] | One of his darts that strikes someone shows `[Target Hit]` under his crosshair for 2 s, as soon as the server says so and on past the flight's end, with the strike's sound; whoever it struck hears the strike and reads TAGGED until their last ping's reveal is over | Confirmed (Patch 4.08); estimate (TAGGED) |
| Its crosshair | Green while he flies it, its lines still | Confirmed (green: Patch 4.08); estimate (still) |
| Its health | 100. An enemy's bullet or knife that strikes it takes its damage off it, a bullet's to the body at its range; at none it breaks, its flight over. His side's do nothing; on the course anyone's does. It stops every bullet | Confirmed (100: Patch 4.08; allies: Patch 5.12); community (enemies: Riot's text); estimate (the damage, the bullets stopped) |
| What ends it | Its 7 s up, C again, broken, his death or a new round: his view's back at his eye, the way he faced as he sent it, and the gun's back in hand 0.7 s later | Confirmed (7 s: Patch 4.08); community (0.7 s: Boosting Ground); estimate (C again) |
| Who has it | Everyone's snapshots carry it as no entity's, under its own id, its middle paced as a player's is, facing the way he looks. His side has it, and on the course everyone; an enemy in play has it while it's within 15 m of their eye or in their sight, and for the fog of war's 0.5 s after, and one who's down has what their side in play has | Estimate (ours; 15 m for valoranttracker.org's rotors' noise) |
| His view | His screen, his fog of war, his minimap's spotting and the flashes that blind him look from the drone while it flies | Estimate (ours) |
| Its look | In hand, a squat dark body with a light blue lens to the front and an arm out either side, each with its rotor; flying, a small dark box with its lens to the front and a spinning rotor either side, in your side's colour or the enemies', facing the way he looks; his body, standing where he left it, in his side's colour on his screen; flying it, the screen's edges tinted light blue and two bars under the crosshair, its time left and the dart's cooldown; a dart, a thin streak of light from it to where it went; broken, eight pieces flying out and falling | Estimate (ours) |
| Its sounds | In hand, the rifle's draw raised past the bow's; sent out, a thick whoosh sped up; flying, the transporter's swell sped right up and quiet, every 0.4 s, as its rotors' hum, heard as far as the ability curve carries; a dart, a thin swish sped up; striking, a knife's strike on a rod sped up; each ping, a bell, higher than a recon bolt's pulse; broken, the spike blast's crack sped right up | Community (its rotors heard: valoranttracker.org); estimate (ours, from free Roblox sounds) |

## 5. Design

### The rules

- **`AbilityConfig`** makes the Owl Drone played (its weapon and its line on his card), and adds
  `OwlDrone` (its deploy, time and unequip, its health, its speed, climb and acceleration, its
  ceiling and how far down a floor's looked for, its box, the dart's cooldown and range, its pings
  and their reveal, how long `[Target Hit]` shows and how far it's heard), each with its status and
  source.
- **`WeaponConfig`** adds `owl`, the drone in hand, 38th of the weapons' wire ids, drawn in 0.9 s.
- **`DroneSim`** is new: how it flies (`step`: the keys, its acceleration and its ceiling over the
  floor below), its box, and the level shots are traced through with drones in it (`level`).
  **`MovementSim`** adds `fly`, a box moved through the world with no gravity, sliding along what
  stops it.
- **`AbilitySim`** sends it out (a `drone` cast, which `launch` starts), flies it (`droneThrough`,
  its darts as `dart` casts) and ends it (`land`, a `land` cast); `droning`, `piloting`, `droneEnds`
  and `landing` say how it's going. **`PlayerSim`** launches it from his eye, holds him while it
  flies, gives its fire to the darts, keeps the gun away until its unequip after, and `downed` ends
  it as the server breaks it.
- **`PlayerCodec`** carries the kit's seven drone fields in the ack, and the drones' ids
  (`DRONE_BASE` and `isDrone`); **`PlayerController`** checks the fields against the server's;
  **`SoundConfig`** adds its sounds.

### The server

- **`DroneServer`** is new. After each of his ticks it puts his drone in the snapshots
  (**`Replication`**'s new `extras`), paced as a player's pose is, and in the rewind history; judges
  each dart as his tick sends it, where his screen showed everyone (**`CombatServer`**'s `rewound`),
  tags whom it struck and pings them (**`ReconServer`**'s `reveal`), and tells him, them and
  whoever'd hear it; stands the drones in the level shots and swings are traced through
  (**`CombatServer`**'s `levelAt`, with its new `levelFor` and `posed`), takes their health as
  they're struck (`struck`), and breaks them; decides whom the snapshots send each drone to
  (**`FogServer`**'s new `others`); and sets `VFDroneId`, `VFDroneHealth`, `VFLastDart` and
  `VFDartHit`.
- **`PlayerSimServer`**'s `view` is the drone's while it flies, so the fog of war, the minimap's
  spotting and the flashes look from it, and his pose holds his body still; **`FogServer`** looks
  from it; **`GroundGunsServer`** gives nothing while it flies; **`AbilityServer`** leaves the darts
  and the landing to `DroneServer`; **`Arena`** ends every flight and ping at a new round;
  **`init.server`** starts it.

### The client

- **`DroneView`** is new: the flight's bars under the crosshair and the tinted edges, his body where
  he left it, every drone you have and its hum, darts and their streaks (yours at once, from your
  tick), `[Target Hit]` and TAGGED, the pings' reveals (**`ReconView`**'s `reveal`) and sounds, and
  a drone's burst.
- **`PlayerController`** puts the camera in the drone, between its ticks, and back at his eye as it
  ends; **`RemoteEntities`** keeps drones' poses from the snapshots (`drone` and `drones`);
  **`ClientShots`** puts them in the level your shots are traced through (`drones`);
  **`CrosshairView`** turns the crosshair green; **`CombatHud`** hides its draw bar while it flies;
  **`WeaponEffects`** hides the gun and sparks where a shot strikes a drone; **`Spectate`** looks
  out of the drone of whoever you watch; **`AbilityHud`** lights C with its seconds left;
  **`WeaponLooks`** gives the drone in hand its shape; **`BuyMenu`** gives its flight and darts;
  **`TestAim`** aims from it; **`init.client`** starts the view.

### Not here yet

- **Players.** It flies through players and dummies, where Dexerto's bug of Patch 1.11 had players
  standing on it.
- **Abilities.** Only bullets and knives take its health: no ability does, where Patch 5.12 has
  "Abilities that output damage" "universally damage enemy objects that can be damaged."
- **Damage to Sova.** Being hurt doesn't end its flight, where esportsdriven.com has damage to him
  stop it.
- **The minimap.** Drones aren't on it, where Patch 11.07 shows them with "a directional arrow to
  indicate where they are facing" in their side's colour. His side's minimap does spot whom the
  drone sees, as it spots whom he sees.
- **Its own page's numbers.** Its speed, its climb, its height, its size and its dart's reach are
  ours, as the wiki's page on the Owl Drone couldn't be read.
- **The dart's flight.** It strikes at once along the crosshair; nothing we could read gives its
  speed. valoranttracker.org's "Refreshes On-Hit, Can Stack" isn't here: one dart every 5 s.
- **His body for spectators.** Watching him while he flies, you look out of the drone, and his body
  isn't drawn for you.
- **Inputs on their way.** For about a round trip after the server breaks it, his body turns the way
  the drone looked, as the inputs on their way from his client still fly it.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | The Owl Drone played; `OwlDrone`'s numbers, each with its status and source |
| `src/shared/Weapons/WeaponConfig.luau` | `owl`, the drone in hand, and its wire id |
| `src/shared/Abilities/DroneSim.luau` | New: its flight, its box, and the level with drones in it |
| `src/shared/Movement/MovementSim.luau` | `fly`: a box through the world with no gravity |
| `src/shared/Abilities/AbilitySim.luau`, `src/shared/PlayerSim.luau` | Sent out, flown, its darts and its end; his body held and the gun away; `downed` |
| `src/shared/Net/PlayerCodec.luau`, `src/client/PlayerController.luau` | The kit's drone fields on the wire, and checked against the server's; the drones' ids; the camera in the drone |
| `src/shared/Audio/SoundConfig.luau` | Its sounds |
| `src/server/DroneServer.luau` | New: its snapshots, its darts and pings, its health, and who has it; `VFDroneId`, `VFDroneHealth`, `VFLastDart` and `VFDartHit` |
| `src/server/CombatServer.luau`, `src/server/Replication.luau`, `src/server/FogServer.luau`, `src/server/PlayerSimServer.luau`, `src/server/GroundGunsServer.luau`, `src/server/AbilityServer.luau`, `src/server/Arena.luau`, `src/server/init.server.luau` | `levelFor` and `posed`; `extras`; `others`, and the drone's eye; `view` and his body's pose; nothing picked up while it flies; the darts left to `DroneServer`; flights ended at a new round; `DroneServer` started |
| `src/client/DroneView.luau` | New: its bars and tint, his body, the drones, darts, `[Target Hit]`, TAGGED, pings and bursts |
| `src/client/RemoteEntities.luau`, `src/client/Combat/ClientShots.luau`, `src/client/Combat/WeaponEffects.luau`, `src/client/Combat/WeaponLooks.luau`, `src/client/Combat/CombatHud.luau`, `src/client/CrosshairView.luau`, `src/client/AbilityHud.luau`, `src/client/BuyMenu.luau`, `src/client/Spectate.luau`, `src/client/Debug/TestAim.luau`, `src/client/init.client.luau` | `drone` and `drones`; drones in your shots' level; the gun hidden and sparks off drones; its shape in hand; no draw bar while it flies; the green crosshair; C's square; its flight and darts in the buy menu; the drone's view for spectators; aim from it; the view started |
| `tests/owldrone.luau` | New: its numbers, in hand, sent out, its flight, its ceiling, walls, Sova held, its darts, how it ends, the level with drones in it, its ids, and the wire |
| `tests/arsenal.luau`, `tests/reconbolt.luau` | The weapons' ids and sounds; the Owl Drone played in Sova's kit |

## 7. Debug tools

- While a player flies the drone, `VFDroneId` is the id the snapshots give it (from 4294836225, one
  more for each drone the server sends out) and `VFDroneHealth` the health it has left. `VFLastDart`
  is where their last dart ended, in metres, set as it goes, and `VFDartHit` whom it struck, a name
  (`Dummy 1 (static)`), or nothing.
- `VFKit` reads `C1/1 Q2/2 E1/1 X8/8` on the course, ends in `equip` while the drone's in hand, and
  in `drone 6.2` while it flies, the seconds it has left.
- PlayerGui's `VFDrone` carries `Flying` (whether you fly it), `Left` (the seconds it has left),
  `DartIn` (the seconds until a dart can go), `TargetHit` (whether `[Target Hit]` shows), `Tagged`
  (whether a dart's pings are on you) and `Drones` (the drones drawn). `Workspace.VFDrone` holds
  each drone you have as a `Drone_` model and its id, your body while you fly as `Body`, each dart's
  streak as a `Dart` part and each burst's pieces as `Shard` parts.
- Whom a ping reveals shows as the Recon Bolt's pulses do: `VFRecon`'s `Revealed`, and `Reveal_` and
  the entity's id in `Workspace.VFRecon`.
- `VFTestButtons` 4096 presses C and 128 the left button, so it can be sent out and fired without a
  key or a mouse button, and 1, 64 and 32 hold W, jump and crouch to fly it; `VFTestYaw` and
  `VFTestPitch` turn its view, and `VFTestAimPoint` and `VFTestAimEntity` aim from its middle.

## 8. Refinement loop

1. Fly the drone a set distance along the ground and up, stepping through clips of the reference's,
   and change `speed`, `climb` and `accel` until it gets there as soon.
2. Fly it up as far as it goes over flat ground and over a box, and change `ceiling`.
3. Fly it through narrowing gaps and shoot at its edges, and change `width` and `height`.
4. Step through clips of C, the launch, a dart and the end, and change the owl's `equipTime`,
   `deploy`, `dartCooldown` and `unequip`.
5. Fire darts at a player further away each time, and change `dartRange`; walk away from a drone
   until its hum goes quiet, and change `heard`.
6. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- The Owl Drone lit on Sova's card and the bar, `C1/1` on the course, and the drone in hand 0.9 s
  after C, with C again putting it away.
- Sent out: the view leaving his eye and stopping 1.8 m on, the tinted edges and the green
  crosshair, the bars, its hum, his body standing where he left it, and as its 7 s are up, the view
  back and the gun back 0.7 s later.
- Flying it: the keys along the ground at 5 m/s the way the view faces, up and down at 3 m/s, no
  higher than 3 m over the floor, down to it, and stopped by walls and over them; his body still.
- Its darts: one every 5 s; a dummy struck, `[Target Hit]` for 2 s, and pinged 1.6 s and 2.8 s
  after, revealed for 0.6 s each; none past 40 m or through a wall.
- Its end: C again, and as its time's up.
- With other players: seen and heard, and shot down by three Vandal hits; its darts tagging another
  player, revealed to its owner alone on the course; in Skirmish, its charge each round, hidden from
  enemies who can't see it or hear it, his side's shots doing nothing, and its darts revealing
  enemies to his side through walls and on the minimap; and bought for 400 in the spike rounds.

Section 51 of the [Studio checklist](../studio-checklist.md) covers these.
