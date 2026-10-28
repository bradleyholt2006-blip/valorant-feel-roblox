# System 60: bots

A match no longer waits for players. While anyone plays a mode, the server fills it with bots,
players it plays itself, up to a number of players for the mode: ten in the spike rounds and Team
Deathmatch, eight in gun game and deathmatch, four in Skirmish. A player joining takes a bot's
place, so one player alone starts a match. A bot is simulated as a player is, on the same movement
and guns at 128 ticks a second, its shots resolved as a player's are, and it's drawn, heard, named
and counted as a player is: on the scoreboard, in the kill feed, on the minimap and in the top bar,
with BOT before its name.

It plays as a person does, inside a person's limits. It sees only what's in its field of view and
not behind a wall, a smoke or a wall of fire, and notices an enemy only after a person's reaction
time, longer toward the edge of its view. It turns onto them in the time a person's hand takes,
lands a little off, lets go of its movement keys and fires only once it's slow enough to be
accurate: single taps at range, short bursts nearer, a spray close up. It misses as a person does,
because its aim wanders round the target, more for an easier bot. It holds the angle it's given,
glances at each place an enemy might be as one comes into view, and watches where it lost sight of
one. A side's bots go to a site together, hold every way into the sites and come over when attackers
turn up at the other, and go where a player on their side goes. There are four skills. The default,
Normal, is good enough to punish a player who walks into its angle and slow enough that one who
checks their corners wins.

Everything comes from public sources: the slides of the Counter-Strike bot's designer from GDC 2004
and from his talk on Left 4 Dead's AI, the Valve Developer Community's pages on bot quotas and on
CS:GO's bot behaviour trees, and published research on people: reaction times, Fitts's law for the
mouse, a study of aiming in first-person games and the minimum-jerk model of arm movements. Valve
doesn't publish its bots' numbers, and no game file was read for them: not Counter-Strike's bot
profiles, not its source code. Every number here is ours, set against what people do, and labelled
an estimate. Nothing was read from the live game, and no Riot image, model or sound is in the
repository.

## 1. Observable behaviour

- A server with too few players fills up with bots, and a player joining takes one's place.
- A bot sees only what's in front of it, and takes a moment to react, longer to something at the
  edge of its view. A harder bot reacts faster and aims better; an easier one waits longer before it
  opens fire.
- It looks around as it moves, apart from where it walks: at places an enemy might be, where it last
  saw one, toward a noise.
- It aims at a point on its target with an offset that changes every so often, smaller for a better
  bot.
- It fires a rifle in bursts at range, and draws its pistol rather than reload in a fight.
- It notices it's stuck by its speed, and gets out with a wiggle and a jump.
- It follows a player it's told to, finding its way again as they move, and covers them where they
  stop.

## 2. Publicly documented details

### The Counter-Strike bot

| What | Source |
| --- | --- |
| "Behave in a believably human manner" | Michael Booth, [The Official Counter-Strike Bot](https://media.gdcvault.com/gdc04/slides/making_of_official.pdf), GDC 2004, slides: The Design Goals of the Official Counter-strike Bot |
| "Player perception of a 'fair fight'"; "Creates behavior variation among bots" | The same: The Importance of Being Human |
| "Players will rationalize most behaviors"; "Blatantly mindless behavior breaks the illusion" | The same: Performance is Key |
| Easy: "Poor reaction times", "Terrible aim", "Substantial additional delay before opening fire on victim". Normal: "Medium reaction times", "Medium aim", "Minor additional attack delay". Hard: "Good reaction times", "Good aim", "No additional attack delay". Expert: "Very good (but still human) reaction times", "Excellent aim" | The same: Making it Fun: Difficulty levels |
| "Viewing is Independent of Movement"; "Allows visual searching while moving"; "Allows firing at enemies while retreating"; "Bots can only 'see' what is in their field of view" | The same: Controlling the View |
| "Directing Attention (Looking around)": "Currently selected Victim", "Hiding Spots", "Last known Enemy location", "Approach Points", "Towards Enemy noises" | The same: Perceiving the Environment |
| "Select point P on victim"; "Add Aim Offset, resulting in P'"; "Periodically generate new random Aim Offset based on bot's 'skill'"; "Add View Drift, resulting in P''" | The same: Combat: How to Aim |
| "Burst firing with a Rifle when victim is far away"; "Switching to a pistol instead of reloading primary weapon"; "Switching to a pistol if using a sniper rifle and victim is very close"; "Aiming for the head, unless using certain sniper rifles, shotguns, or the knife" | The same: Combat: Weapon Proficiency |
| "Navigation Areas represent 2D 'walkable' areas"; "Paths can pass through the area anywhere" | The same |
| "Increased cost for crossing Jump and/or Crouch areas and Ladders"; "Small and/or irregular obstacles"; "Watch average velocity over a short window of time"; "Random 'wiggle'"; "Add random jump after a short duration" | The same: Moving Around in the Environment |
| "Automatically finds Hiding Spots and Approach Points"; "All Hiding Spots provide good cover" | The same: Simple to Use: Automated Map Learning; Combat: Hiding / Sniping |
| "Periodic re-path if leader is moving"; "If leader is hiding, take up covering position nearby" | The same: Combat: Following a Leader |
| "By default, bots defer key scenario objective to human Players" | The same: Making it Fun: Respect the Player |

### Bots on a server, and CS:GO's

| What | Source |
| --- | --- |
| fill: "The server is filled with bots until there are at least bot_quota players on the server (humans + bots)." "Human players joining cause an existing bot to be kicked, human players leaving might cause a bot to be added." | Valve Developer Community, [Bot quota mode](https://developer.valvesoftware.com/wiki/Bot_quota_mode) |
| The Deathmatch behaviour tree's memories expire: "ShortTermAttackMemory" at time = 0.7, "LongTermMemory" at time = 10, "ShortTermInvestigateMemory" at time = 3. The page doesn't say what each holds | Valve Developer Community, [Bot Behavior Trees](https://developer.valvesoftware.com/wiki/Mp_bot_ai_bt) |
| action_aim: "Rotates bot towards input point. Uses aim penalties set in the bot config." The bot config's reaction_time: "Delay before reaction on event." | The same |

### Moving as a person moves

| What | Source |
| --- | --- |
| "Following path directly looks robotic"; "Move towards 'look ahead' point farther down path"; "Use local obstacle avoidance"; "Resultant motion is fluid" | Michael Booth, [The AI Systems of Left 4 Dead](https://cdn.fastly.steamstatic.com/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf), slides |
| "unconstrained point-to-point motions are approximately straight with bell-shaped tangential velocity profiles"; "the objective function is the square of the magnitude of jerk" | Tamar Flash and Neville Hogan, ["The coordination of arm movements: an experimentally confirmed mathematical model"](https://pmc.ncbi.nlm.nih.gov/articles/PMC6565116), The Journal of Neuroscience, 1985 |

### People's limits

| What | Source |
| --- | --- |
| "simple reaction times averaged 0.220sec: recognition reaction times averaged 0.384sec" (Laming, 1968, in Kosinski's review) | [BioNumbers 110799](https://bionumbers.hms.harvard.edu/bionumber.aspx?id=110799) |
| Fitts's law for the mouse, pointing: MT = -107 + 223 ID, in ms, with ID = log2(A/W + 1) | I. Scott MacKenzie, Abigail Sellen and William Buxton, ["A Comparison of Input Devices in Elemental Pointing and Dragging Tasks"](https://www.yorku.ca/mack/CHI91.html), CHI 1991 |
| At "a 103° rendered field of view", targets of "diameters of: 0.57°, 1.15°, 2.29°, 4.59°, and 9.15°" whose distance from the view's middle "randomly varied between 7-25° horizontally and 0-2.8° vertically", "a range of ID of 0.83-5.50", with "the average task completion time (typically 0.4 - 0.8 s)" | Ben Boudaoud, Josef Spjut and Joohwan Kim, ["Mouse Sensitivity Effects in First-Person Targeting Tasks"](https://arxiv.org/pdf/2203.12050.pdf), [IEEE Conference on Games 2022](https://research.nvidia.com/publication/2022-08_mouse-sensitivity-first-person-targeting-tasks.md) |

## 3. What can be measured, and how

Neither the reference nor Counter-Strike publishes how well its bots play, so the bots are measured
against people, in the offline tests (`tests/bots.luau`), on the shared code the server runs. A duel
puts a bot with a Vandal on a floor, and someone in Heavy Armor 15 m in front of it, who comes into
view and stays there. The bot is driven as the server drives it, and its shots are resolved against
the target's hitboxes, fifteen times a skill with different dice, for four seconds at most. These
are the numbers the tests print:

| Skill | Notices someone in the middle of its view | First shot | Kill | Duels won in 4 s | Shots that hit |
| --- | --- | --- | --- | --- | --- |
| Easy | 0.60 s | 0.88 s | 2.79 s | 13 of 15 | 29% |
| Normal | 0.45 s | 0.57 s | 1.77 s | 15 of 15 | 43% |
| Hard | 0.35 s | 0.39 s | 0.52 s | 15 of 15 | 58% |
| Expert | 0.30 s | 0.30 s | 0.30 s | 15 of 15 | 83% |

Times are medians from the target coming into view. Normal notices someone 45 degrees off in 0.65 s,
and turns 10, 45 and 120 degrees onto a chest 15 m off in 0.36, 0.56 and 0.70 s. At 10 m it hits 56%
of its shots at someone standing and 37% at someone strafing at a run, turning back every 0.35 to
0.65 s.

Set against people: an average person's recognition reaction is 0.384 s, and Boudaoud, Spjut and
Kim's players took 0.4 to 0.8 s to find and click a target 7 to 25 degrees off, a reaction included.
Normal's first shot at someone in the middle of its view, 0.57 s, is about a person's reaction and a
click, and it takes 1.8 s to win the duel, so a player who's ready on the angle, or who sees it
first, wins. Expert's first shot, 0.30 s, is a simple reaction's 0.22 s and a little: the fastest a
person is, as Booth's Expert is "Very good (but still human)".

The walks run the movement a player has on each map's own solids, from the attackers' spawn to each
site's middle and from the defenders' to a spot holding the first site, as the server walks a bot.
Each arrived without once getting stuck, in no more time than a run along its path takes:

| Map | To A from the attackers' spawn | To B from the attackers' spawn | To a hold at A from the defenders' spawn |
| --- | --- | --- | --- |
| Outpost | 11.2 s | 10.1 s | 8.6 s |
| Quarry | 14.9 s | 14.1 s | 11.4 s |
| Foundry | 14.9 s | 14.0 s | 9.9 s |
| Wharf | 19.0 s | 17.7 s | 10.2 s |

On the arena's three maps a bot walks from either spawn room to the other in 5.7 to 6.6 s. On map B
it's stuck a moment each way against the crate standing at an angle, and steps aside past it: the
nav, as the tests' world, takes a turned box as the box round it, so its way round the corner is
tight, where in Roblox the crate's own corner is further off. Going round Outpost together, five
attackers got onto the site they'd picked between 9.8 and 10.1 s into the round, and none stood on
another's spot. Five defenders were on their spots in 15 s, covering both sites; when attackers were
seen at one, 12 s later four were there and one had stayed on the other. Four attackers went with a
player who made for the site they hadn't picked, and three bots following a player across the map
kept 6.8 m from them on average and 11.2 m at most.

## 4. Confirmed vs estimated, as implemented

The skills (`BotConfig.Skills`). Each is an estimate: Booth's slides say what each is like, not its
numbers.

| What | Easy | Normal | Hard | Expert | Against |
| --- | --- | --- | --- | --- | --- |
| Reaction, to someone in the middle of its view | 0.55 s | 0.4 s | 0.3 s | 0.24 s | A recognition reaction, 0.384 s, for Normal; a simple one, 0.220 s, for Expert (Laming) |
| Added delay before the first shot | 0.25 s | 0.1 s | 0 | 0 | Booth: substantial, minor, none, none |
| Fitts's law: intercept a, slope b | 0.12 s, 0.18 s a bit | 0.08 s, 0.1 s a bit | 0.06 s, 0.08 s a bit | 0.05 s, 0.065 s a bit | Normal's turns as Boudaoud et al.'s 0.4 to 0.8 s less a simple reaction; Easy's nearer the office mouse's 0.223 s a bit (MacKenzie et al.) |
| Aim's wander once settled (standard deviation) | 1.3° | 0.8° | 0.5° | 0.3° | Booth's aim offset: ours, Easy's about a chest's width at 20 m |
| Wander just after the turn | 3 times | 2.5 times | 2 times | 1.8 times | Ours |
| Time it takes to settle (time constant) | 0.6 s | 0.45 s | 0.3 s | 0.2 s | Ours |
| Reaction to a target's change of way | 0.25 s | 0.2 s | 0.15 s | 0.12 s | Ours: about a reaction |
| Share of the gun's climb pulled down | 0 | 0.3 | 0.6 | 0.85 | Ours |
| Chance of aiming at the head, each fight | 0 | 0.3 | 0.7 | 0.9 | Ours; Booth's bot aims for the head |
| Steps aside between bursts | No | No | Yes | Yes | Ours |

| What | Value | Status | Source |
| --- | --- | --- | --- |
| Field of view, across | 103° | Community | The game's fixed field of view (CameraController); Boudaoud et al.'s too |
| Reaction toward the edge of view | 1.6 times, in proportion between | Estimate | Ours |
| How much each reaction varies | 15% (standard deviation) | Estimate | Ours |
| Known again at once after losing sight | 0.7 s | Confirmed | CS:GO's ShortTermAttackMemory |
| Forgotten after | 10 s | Confirmed | CS:GO's LongTermMemory |
| Watching where one was lost | 3 s | Confirmed | CS:GO's ShortTermInvestigateMemory |
| Looks for enemies | Every 0.05 s | Estimate | As the fog of war's looks |
| Wander made anew | Every 0.3 s | Estimate | Ours |
| Taps past, bursts down to, sprays inside | 22 m, 10 m | Estimate | Booth: bursts at range |
| A burst, a spray at the longest | 3 rounds, 8 | Estimate | Ours |
| The view off its aim, the shot still taken | 1.2 times the target's half width | Estimate | Ours |
| Turning when not fighting | 360° a second at most, eased over 0.12 s | Estimate | Ours |
| A glance at a spot an enemy might be | 0.6 s, at spots up to 35 m, checked every 0.25 s, none again for 8 s | Estimate | Ours |
| Each side's plan gone over | Every 0.5 s | Estimate | Ours |
| Quota: spike rounds, Team Deathmatch | 10 | Estimate | Their five a side |
| Quota: gun game | 8 | Estimate | Its four a side |
| Quota: Skirmish | 4 | Estimate | Its two a side |
| Quota: deathmatch | 8 | Estimate | Fewer than its 14, for the server's sake |

The way round a map and a side's plan are estimates too, each of ours and set by what the tests
walk: a column every 0.5 m; a jump up to 0.75 m, costing 4 m more than walking; stuck under 0.8 m/s
over 0.25 s for 0.5 s; a site's area 14 m on foot from its plant area's middle; attackers gathering
9 m short of their way in and pushing once 70% are there or by 32 s, give or take 8; defenders'
spots 6 to 26 m from the way in they hold, 13 m best; the others coming over 3 s after attackers are
seen at a site; and a bot following a player standing 3 to 7 m round them.

## 5. Design

### Filling a match

`BotFill` follows the Counter-Strike server's fill mode. While anyone plays what's played, on a side
or in line for one, bots fill it up to the mode's quota; with nobody, there are none, and the match
waits for a player as it always has. While there are more than the quota, a bot waiting for a place
or one that's down leaves at once; one alive leaves only while nothing's at stake (waiting for the
match, a buy phase, Team Deathmatch's pre-game, between rounds and after the match), so nobody
vanishes mid-fight. The one to leave is on the side with the most bots, the last of them to join, so
a player waiting in line gets a place on the side with fewer players.

Each bot goes through the match's rules as a player does, by an id of its own: its entity id less
2^32, a negative number below any Studio test player's UserId (`PlayerCodec.botRuleId`). So a bot
filling the second side starts the match, and it's on a side, spawns, dies, buys, earns, scores and
is counted as a player is. The server list and the Play menu count only players. In the spike rounds
a bot buys as it spawns in a buy phase, from its own credits (`BotBuy`): a Light Armor or now and
then a Ghost in a half's first round, a rifle and Heavy Armor with 3,900 credits, a rifle and Light
Armor or a Spectre and Light Armor with less, and otherwise it saves; a survivor keeps its gun and
buys a shield. Its gun drops where it dies, as a player's does.

### What a bot sees, and when it notices

Twenty times a second each bot looks at every enemy alive, at the snapshots' pose. One near its view
that neither the level nor a smoke or a wall of fire hides from its eye (`Sight`, as the minimap's
spotting has it) is in sight, and in view if they're inside its field of view, 103 degrees across
and a 16:9 screen's height. One in view is noticed after the skill's reaction time, longer toward
the edge, up to 1.6 times at the edge, and varying by 15% each time, as a person's reactions do. One
it lost sight of within 0.7 s is known again at once; where they were, it watches for 3 s; anyone
unseen for 10 s, or gone from the snapshots, is forgotten.

### Aim and trigger

Noticing someone starts a fight with them, the nearest noticed. The bot picks its point on them, the
head at the skill's chance and otherwise the chest, and turns onto it in the time Fitts's law gives
its skill for a turn that wide onto a target that size, varying by 15%, along a minimum-jerk path,
the shape of a person's quick arm movement. It lands off by the wander just after a turn, which
settles to the skill's own over its focus time. The wander, an offset round the point made anew
every 0.3 s and eased into, is Booth's aim offset: the bot doesn't know it, so a shot goes where it
puts it, and that, not the trigger, is what misses.

A target that moves is followed as a person follows one. The bot keeps what each look saw over the
last half second, and aims where it saw them its reaction to a change of way ago, carried on at the
speed they had then: someone who keeps going is followed exactly, and someone who strafes back the
other way is followed the old way until the bot sees it, so its aim overshoots each strafe. Its view
eases onto the aim, led by its own easing time, so it keeps up rather than trailing; the skill's
share of the gun's climb is pulled down.

It stands still to shoot: while it fights it lets go of its movement keys, and fires only once it's
slower than its gun's deadzone, the skill's added delay has gone by, the target's in sight and its
view is where it means to aim. Past 22 m it taps single rounds, down to 10 m it fires bursts of 3,
and closer it sprays up to 8, each followed by the gun's recovery before the next, the rounds of an
automatic counted off its magazine. A sniper rifle or a shotgun fires a round at a time, a
semi-automatic a press at a time. Hard and Expert step aside between bursts, and stop again to fire;
all but Easy now and then crouch for a spray close up. Out of rounds with someone within 20 m, all
but Easy draw the sidearm rather than reload, as Booth's bot does; with nobody about, a magazine
under half is reloaded. A knife in hand runs at whoever it fights and slashes once they're in reach,
and a sniper rifle is scoped for a fight further than 8 m.

### Looking round

Where a bot looks goes apart from where it walks. Not fighting, it turns toward a hit from someone
it didn't see, for 1.5 s; else it watches where an enemy it lost sight of was; else it glances, for
0.6 s, at the spot an enemy might be in that's newly in its sight and nearest its view's middle (a
site's ways in and the spots that hold them, up to 35 m off), each spot not again for 8 s; else it
looks where its job says: 6 m along its way as it walks, and at the way in it holds once it's there.
That's how it checks its corners.

### Walking

`BotNav` stands in for the Counter-Strike bot's navigation mesh. It's worked out from the plan the
server builds each map from, as a grid of columns 0.5 m apart, each with a node for every height a
player's box can stand at there: a door's 1.5 m always has a column whose middle lands in it. Each
node joins the nodes beside it the box can get to on foot: walking (level, or up or down a step or a
slope), jumping up to 0.75 m, or dropping. A path is A*'s over it, a jump up costing 4 m more than
the walk, so a path takes a ramp or stairs a few metres on rather than jump up beside them, as a
player does; a path keeps off a ledge's edge where it can. A map's nav is built the first time it's
played on, a few milliseconds a frame.

`BotMove` follows a path as Left 4 Dead's bots follow theirs: it steers at the furthest node ahead
it can walk straight to, up to 4 m on, rather than going from node to node, and jumps as a jump's
edge comes near. It notices it's stuck by its speed over the last quarter second, slower than
0.8 m/s for half a second while it means to move, and steps aside at random for 0.35 s with a jump,
as the Counter-Strike bot wiggles and jumps; stuck for 1.2 s, it finds its way again, keeping 1.2 m
off the spot it stuck at for 10 s. It finds its way again every 4 s anyway, and when it's 2.5 m off
its path. The movement keys are the ones nearest the way it's going for the way it's looking. In
Studio, the Output has a line each time a bot's stuck long enough to find its way again, with where,
so a spot bots walk into shows up in play.

### Together

`BotSpots` works out each spike map's sites once, from its nav, as the Counter-Strike bot's map is
analysed for its hiding spots and approach points: each site's area, within 14 m on foot of its
plant area's middle; its ways in, where the attackers' shortest ways from their spawn cross into
that area, up to four different ones; where they gather, 9 m short of each; and up to four spots to
hold each way in from, 6 to 26 m from it, 13 m best, beside cover and seeing it at head height.

`BotTeam` gives each side a plan each round, and each bot a job in it: a node to walk to, a point to
look at once there, and whether to walk quietly. Attackers pick a site and a way in, or two in a
third of rounds, gather spread out short of each way in, walking the last 12 m quietly, and push in
together once 70% are there, by 32 s give or take 8, or once they've been seen near where they
gather. Through their way in they take the site, each to a spot on it watching the way the defenders
come back, and 20 s after that with nobody seen they go looking. Defenders split over the sites,
each to a spot holding one of its ways in, and a site's spots cover all of them; when attackers are
seen at one site, those at the other come over 3 s later, all but one, who stays.

A player on the side leads: once they've come 12 m from the spawn and are 10 m nearer another site
than the one planned, the attackers go there with them. In the modes that respawn, bots follow a
player on their side, standing 3 to 7 m round them and moving up once they've gone 4 m, as the
Counter-Strike bot follows a leader; with nobody to follow, a side goes where its enemies were last
seen, together, else from place to place over the map, the named rooms but the spawn rooms. Bots of
a side never stand on the same spot: those making for the same place are spread round it, 1.6 m
apart.

### The server

`BotServer` plays each bot with the shared modules' minds. Each server frame it starts the lives
asked for, takes each bot's look when it's due (spread over each bot's first interval), works out
four times a second which spots an enemy might be in are in each bot's sight, goes over each side's
plan twice a second, and runs every 128 Hz tick due: each bot's eyes and trigger and its walk made
the buttons and angles of its simulation's input. Its shots go to `CombatServer` as a player's do,
and the snapshots show it a tick behind through a `MovePacer`, as they show everyone. Each bot has a
stand-in for clients in ReplicatedStorage's `VFBots`: a Configuration named after the bot
(`BOT Ash`), with its entity id and its id in the rules, and whatever the arena keeps on a player
for clients. In Studio, and only there, as it would tell an enemy's plan, the stand-in also carries
the bot's job in its side's plan. The fog of war and the minimap see bots and let them be seen as
players are.

### On screen

Clients ask `Who` who an entity is: a player, or a bot by its stand-in. So a bot is named over its
head and in the kill feed and the combat report, outlined as a teammate or an enemy, listed on the
scoreboard, shown on the top bar's tiles with the first two letters of its name past `BOT `, drawn
on the minimap, and followed when a player watches their side after dying.

### The tests

`tests/bots.luau` has 82 checks: the ids; how many fill a match and which bot leaves; what bots buy,
never over their credits; what they see and how fast, against people's reactions; turns by Fitts's
law, against Boudaoud et al.'s players; the duels by skill, each skill quicker and surer than the
one below it, Normal beatable, and every shot fired standing still; checking corners, watching where
an enemy was lost, turning to a hit, reloading and drawing the sidearm; walking every spike map and
the arena's on their own solids (`tests/TileWorld.luau`), never stuck long enough to find the way
again; and going round Outpost together.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Bots/BotConfig.luau` | New: the skills, the numbers of seeing, aiming and firing, the quotas and the names |
| `src/shared/Bots/BotFill.luau` | New: how many bots a match has, and which leaves |
| `src/shared/Bots/BotBuy.luau` | New: what a bot buys |
| `src/shared/Bots/BotBrain.luau` | New: what a bot notices, where it looks, its aim and its trigger |
| `src/shared/Bots/BotNav.luau` | New: where a bot can go on a map, and what it can see from where |
| `src/shared/Bots/BotMove.luau` | New: following a path, and getting unstuck |
| `src/shared/Bots/BotSpots.luau` | New: each spike map's sites, their ways in and the spots that hold them |
| `src/shared/Bots/BotTeam.luau` | New: each side's plan, and each bot's job in it |
| `src/server/BotServer.luau` | New: the bots on the server: lives, looks, plans, ticks and stand-ins |
| `src/server/Arena.luau` | Bots filled into each mode and played by its rules by their ids; their kits, buys, spawns, deaths and records |
| `src/server/Entities.luau`, `src/server/CombatServer.luau`, `src/server/PlayerSimServer.luau`, `src/server/AbilityServer.luau`, `src/server/CalloutServer.luau` | A killer or victim that's a bot, by its id in the rules, and its side |
| `src/server/GroundGunsServer.luau`, `src/server/FogServer.luau`, `src/server/MinimapServer.luau`, `src/server/init.server.luau` | A bot's gun dropped where it dies; bots seen, and seeing, in the fog of war and on the minimap; bots started and stepped |
| `src/shared/Net/PlayerCodec.luau` | Bots' entity ids and ids in the rules |
| `src/client/Who.luau` | New: who an entity is, a player or a bot |
| `src/client/RemoteEntities.luau`, `src/client/Visuals.luau`, `src/client/KillFeed.luau`, `src/client/KillBannerView.luau`, `src/client/ReportView.luau`, `src/client/Scoreboard.luau`, `src/client/ArenaHud.luau`, `src/client/MinimapView.luau`, `src/client/Spectate.luau`, `src/client/ParanoiaView.luau`, `src/client/BlindView.luau`, `src/client/Combat/ClientMelee.luau`, `src/client/Audio/GameSounds.luau` | A bot named, coloured, counted and followed as a player is |
| `tests/TileWorld.luau`, `tests/bots.luau`, `tests/run.luau` | New: a map's solids as a world to walk in, and the 82 checks |
| `docs/studio-checklist.md` | Section 64 |

## 7. Debug tools

- Workspace's `VFBots` set false keeps bots out: those in a match leave as soon as nothing's at
  stake, and none join.
- Workspace's `VFBotSkill` (`easy`, `normal`, `hard` or `expert`) sets how well bots play, from each
  one's next life.
- Each bot's stand-in in ReplicatedStorage's `VFBots` carries `Entity` and `Id`, and the attributes
  the arena keeps on a player: `VFArenaSide`, `VFAlive`, `VFKills`, `VFDeaths`, `VFLoadout`,
  `VFCredits` and the rest. In Studio it also carries `VFBotTask`, its job in its side's plan:
  `gather`, `push`, `take`, `hunt`, `hold`, `rotate`, `follow`, `roam` or `wait`.
- In Studio, the Output says `[VF] BOT Ash stuck at (x, y, z), going another way` each time a bot's
  been stuck for 1.2 s, with where in metres in the map's own frame.
- In Studio, Workspace's `VFBotMs` has the milliseconds the bots take of each server frame, on
  average over the last second.

## 8. Refinement loop

1. Play against Normal bots in Skirmish and the spike rounds: whether a new player wins their share
   of duels, whether the bots feel like people, and how Easy, Hard and Expert compare.
2. Tune `BotConfig`'s skills, and re-run the tests' duels to see each skill's times and hits.
3. Watch bots walk each map in Studio for anywhere they stick or stop; add a walk to the tests for
   each.
4. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Bots filling each mode, the match starting with one player, and a player joining taking a bot's
  place.
- The bots on screen: names, outlines, the scoreboard, the top bar, the minimap and the kill feed.
- What they buy in the spike rounds, and their guns dropping where they die.
- How they fight in the place's real geometry: noticing, stopping to shoot, bursts, and whether
  Normal is beatable.
- Going round the spike maps together and following a player, without walking into walls, on
  Roblox's own collisions.
- What nine bots cost the server.
- Not in this system: the spike (bots don't carry, plant or defuse it, so a side of bots alone loses
  its attack on time), abilities and agents, hearing footsteps and gunfire, and taking over a bot
  after dying.

Section 64 of the [Studio checklist](../studio-checklist.md) covers these.
