# System 61: bots and the spike

Bots play for the spike now. In the spike rounds an attacking side of bots picks the spike up as the
round starts, carries it with its plan to the site it chose, and once through its way onto the site
the bot carrying it plants it at a place picked for it: in the plant area, beside cover and out of
sight of the defenders' ways back in, so whoever defuses it has to come out to it. Once it's planted
the attackers watch it, each from a spot beside cover that sees it, and each gets out of the blast
when there's only just time left to make it on foot. Defending bots retake the site: they gather at
its ways back in from their spawn, push in together, and the one nearest the spike defuses it while
the others stand round it, each watching one of the spots it's watched from. If the defuser couldn't
get there on foot and defuse it in time, they get out of the blast instead.

A bot plants and defuses as a player does, in its own simulation: in the plant area it draws the
spike and holds Use, standing still, and by the planted spike, in sight of it, it holds Use until
it's defused. The server takes a bot's plant or defuse as it takes a player's, with the same rules.
A bot lets go to fight unless it's nearly done or there's no time to, and never fires with the spike
in hand, which would plant it.

Players come first, as the Counter-Strike bot's designer put it: "By default, bots defer key
scenario objective to human Players". A spike on the ground is left to a player on the side for 5 s
of a live round before the nearest bot goes for it; a bot picks it up only when it means to, so it
never takes it from under a player going for it; a player carrying it decides where it's planted;
and a player defusing it is left to it, the bots standing round.

Everything comes from public sources: Michael Booth's slides on the Counter-Strike bot from GDC 2004
and the Valve Developer Community's list of CS:GO's console variables. Valve doesn't publish how its
bots choose where to plant, where to watch the bomb from or when to go for a defuse, so every number
here is ours, labelled an estimate and measured in the offline tests. No game file or source code
was read, nothing was read from the live game, and no Riot image, model or sound is in the
repository.

## 1. Observable behaviour

- A Counter-Strike bot says what it's doing with the bomb as a player would on the radio: that it's
  going to plant it, that the bomb's been dropped, that it's going to guard a bombsite.
- An attacking side takes the bomb or spike to the site it's going for, and one of them plants it
  once they're on the site, where the defenders coming back don't see it at once.
- Once it's planted, the attackers stop pushing and watch it from cover, and get away from it before
  it goes off.
- Defenders retake together, from the ways back onto the site, rather than one at a time. One
  defuses while the others cover them, and a defuse is let go of to fight unless there's no time to.
- With too little time to get there and defuse it, defenders get away from it instead, and live to
  keep their guns.
- Counter-Strike's bots leave the bomb to a human on their side, by default.

## 2. Publicly documented details

### The Counter-Strike bot and the bomb

| What | Source |
| --- | --- |
| "When a bot decides to hide, guard a location, or snipe, it picks a nearby Hiding Spot in the Navigation Mesh" | Michael Booth, [The Official Counter-Strike Bot](https://media.gdcvault.com/gdc04/slides/making_of_official.pdf), GDC 2004, slides: Combat: Hiding / Sniping |
| "I'm going to guard bombsite B"; "I'm going to plant the bomb"; "Status of scenario ("They dropped the bomb")" | The same: Talking to Teammates |
| "Scenario announcements ("The bomb has been planted")" | The same: Perceiving the Environment |
| "Scenario objectives" first of what a bot weighs, with a "Simplified Counter-Terrorist Bomb Example" whose diagram the slides' text doesn't carry | The same: Deciding What to Do |
| Morale goes up when a bot "Completes an objective"; "Morale is used when determining whether to "rush" or "camp"" | The same: Deciding What to Do: Morale |
| "Make the player feel smart, skilled, and in charge"; "By default, bots defer key scenario objective to human Players" | The same: Making it Fun: Respect the Player |

### CS:GO's bots on a server

| What | Source |
| --- | --- |
| `bot_defer_to_human_goals`, 0 by default: "If nonzero and there is a human on the team, the bots will not do the scenario tasks." | Valve Developer Community, [List of CS:GO Cvars](https://developer.valvesoftware.com/wiki/List_of_CS:GO_Cvars) |
| `bot_defer_to_human_items`, 1 by default: "If nonzero and there is a human on the team, the bots will not get scenario items." | The same |
| `bot_allow_rogues`, 1 by default: "If nonzero, bots may occasionally go 'rogue'. Rogue bots do not obey radio commands, nor pursue scenario goals." | The same |

### The spike's own rules

Bots play by the spike's rules as they are (system 12, [its research](12-spike.md)): a plant takes
4 s in a site's plant area, a defuse 7 s with its half kept at 3.5 s, it goes off 45 s after the
plant, and the blast reaches 35 m, all community numbers; the defuse's reach of 1.6 m and the 0.7 m
it's run over from are ours. The server checks a bot's plant and defuse as it checks a player's.

## 3. What can be measured, and how

Nobody publishes how well a side of bots plays for the bomb, so the bots are measured in the offline
tests (`tests/botspike.luau`) on each spike map's own solids, as system 60's walks are: five bots on
the movement a player has, each tick's buttons made from their jobs and hands as the server makes
them, the plant and the defuse stepped in each one's simulation, and the spike kept as the server
keeps it. These are the numbers the tests print. Five attackers from their spawn, with the spike
lying where the round puts it, from the round going live:

| Map | Picked up | Planted | Site, and the site planned |
| --- | --- | --- | --- |
| Outpost | 0.8 s | 16.6 s | A, A |
| Quarry | 0.8 s | 22.1 s | A, A |
| Foundry | 0.8 s | 27.3 s | A, A |
| Wharf | 1.1 s | 26.2 s | A, A |

Each plant went down in the plant area, at the place planned. On Outpost the round goes on to the
blast: 10 s after the plant all five stood guarding it where they saw it, and they left with 10.6,
10.6, 9.1, 9.1 and 8.6 s on it, from 1.3 to 9.9 m from it, each by its own way out. As it went off
the nearest was 37.9 m from it, out of its 35 m.

Five defenders from their spawn, the spike planted at each site's best place to plant as the test
starts, with 45 s on it; times from the plant:

| Site | Pushed in | Defused | The other four round the spike |
| --- | --- | --- | --- |
| Outpost A | 4.5 s | 14.9 s | 4 |
| Outpost B | 4.0 s | 15.3 s | 4 |
| Quarry A | 9.0 s | 20.2 s | 4 |
| Quarry B | 8.5 s | 20.2 s | 4 |
| Foundry A | 6.5 s | 18.3 s | 4 |
| Foundry B | 6.5 s | 18.5 s | 4 |
| Wharf A | 8.0 s | 20.0 s | 4 |
| Wharf B | 10.0 s | 21.8 s | 4 |

Each defused it with 23 to 30 s to spare. From the ways back into Outpost's A with only 9 s on it,
too little for the way and a defuse, all five got out of the blast instead, the nearest 38.0 m from
it as it went off. On Foundry's A with 17 s on it, a defender 18.7 m from the spike as the crow
flies but 81.4 m on foot got out of the blast, and one 15.3 m off and 16.2 m on foot went for the
defuse.

What it costs, in the command-line Luau the tests run in: each map's plan, worked out once, now
takes about 0.26, 0.39, 0.42 and 0.73 s on Outpost, Quarry, Foundry and Wharf, from 0.16, 0.33, 0.35
and 0.52 s in system 60, spread over frames as before. It now pauses after each way in and each
entrance's holding spots too, so the longest it runs without a pause is 15 to 40 ms, where it was 50
to 150 ms, apart from Wharf's first stretch, building its solids, about 100 ms as it was. Once the
spike's planted, each of the two fields below is worked out in 3 or 4 of a side's plan's goes,
within 2 s, taking up to 5 ms a go.

## 4. Confirmed vs estimated, as implemented

| What | Value | Status | Source |
| --- | --- | --- | --- |
| A spike on the ground left to a player on the side | 5 s of a live round | Estimate | Booth: bots defer to human players; `bot_defer_to_human_items` |
| Places to plant a site | 3, at least 2.5 m apart, 0.6 m inside the plant area's edge, up to 1.9 m over its floor | Estimate | Ours |
| A place to plant, scored | 3 less for each way back in that sees the spike there, 1.5 more a side of cover (two at most), 1 less for each 5 m from the area's middle | Estimate | Ours |
| Near enough the place to plant to start | 1 m, across | Estimate | Ours |
| Watch spots | 8, at least 3 m apart, on a 1 m grid, 5 to 20 m from the best place to plant, within 34 m of the site on foot | Estimate | Ours; Booth's bot guards from a Hiding Spot |
| A watch spot, scored | 1 less for each 3 m from 10 m, 1.5 more a side of cover (two at most), 1 more for each other place to plant it sees, 1.5 less for each way back in that sees it | Estimate | Ours |
| The spike looked at | 0.3 m over the floor; guarded a metre over it, where a defuser would be | Estimate | Ours |
| A plant finished under fire | Past 3 s of its 4 | Estimate | Ours |
| A defuse finished under fire | Past 5.5 s of its 7, or with no more than 2 s to spare | Estimate | Ours |
| The retake's push | 70% gathered, 12 s after the plant, or with no more than 14 s more than the defuse left, whichever's first | Estimate | Ours; 70% as system 60's attackers |
| A run, to judge the time | 5 m/s | Estimate | Under a rifle's 5.40 m/s, for the turns on the way |
| Out of the blast | 38 m from the spike | Estimate | Its 35 m (community) and 3 to spare |
| An attacker leaves, its way out at 5 m/s and this to spare | 1.5 s | Estimate | Ours |
| Nodes of a field worked out each time a side's plan is gone over | 2000 | Estimate | Ours: each field's done in 3 or 4 goes |
| A bot fetching it walks straight onto it from | 1.5 m, to 0.15 m | Estimate | Ours; it's picked up from 0.7 m |

## 5. Design

### Who carries it

`BotTeam` keeps the spike in each side's plan, as the server knows it. Lying on the ground, the
attacking bot nearest it goes for it: at once with no player on the side alive, else once it's lain
there 5 s of a live round, time for a player by it to pick it up, as the Counter-Strike bot doesn't
get scenario items with a human on its team. Dropped somewhere else, the wait starts over, and the
bot going for it keeps on until it has it. Its job is a node beside the spike and then the spike
itself, and the server walks it straight onto the spike for the last 1.5 m. The server lets a bot
pick the spike up only when that's its job, so one walking past never takes it from under a player.
A player carrying it plants it where they choose, and the bots go with them as system 60's go with a
player.

### Where it's planted

`BotSpots` works out each site's places to plant once a map, with the rest of its plan. They're
nodes of the plant area the attackers get to, kept 0.6 m inside its edge so that feet stopping a
little short of the spot are still in it, scored first by how few of the defenders' ways back in see
the spike there, then by the cover beside it and how near the middle it is: three, at least 2.5 m
apart. The ways back in are found as system 60 finds the attackers' ways in, from the defenders'
spawn, each with a staging spot 9 m short of it. Each round the attackers' plan picks one of the
three, at random. Every site of the four maps has three places to plant and one to three ways back
in.

### Planting

The bot carrying the spike goes with the plan, gathering and pushing with the rest. Once through its
way onto the site, or once the side's taking it, it makes for the place planned, looking back the
way the defenders come from their spawn, and once within 1 m of it, on the ground in the plant area,
it draws the spike and holds Use, standing still, until the spike's down.

### After the plant

The attackers guard it, as Booth's bot guards a location from a Hiding Spot. Each site has eight
watch spots, worked out once a map: nodes the attackers get to on a 1 m grid, 5 to 20 m from the
best place to plant and seeing the spike there, beside cover, scored by how near 10 m they are, the
cover beside them, how many of the other places to plant they see and how few of the ways back in
see them. Once it's down, those that see where it actually is are dealt out, each bot keeping the
one it has, and any bots left over stand round the spike. All of them watch a metre over it, where a
defuser would be.

### The retake

Once it's planted the defending bots retake it. Each takes one of the site's ways back in, as evenly
as they go, and gathers at its staging spot, walking the last 12 m quietly; any already on the site
stay there, watching the spike. They push in together once 70% are there, 12 s after the plant at
the latest, or once there's no more than 14 s more than a defuse takes left. Through their way in,
the one nearest the spike goes to it and defuses it, and the rest stand round it, each watching one
of the spots it's watched from. The defuser lets go to fight, unless it's more than 5.5 s in or
there's no more than 2 s to spare. A player defusing it is left to it, and the bots stand round.

### Out of the blast

Out of the blast is 38 m from the spike, its 35 m and 3 to spare. If the defuser couldn't get there
and defuse it in time, at 5 m/s on foot, or finish a defuse under way, every defending bot gets out
of the blast instead. Each attacker goes once what's left is no more than its way out at 5 m/s and
1.5 s to spare, from where it is or where it's going, whichever's further, so the one deepest in the
site goes first. Each goes the nearest way out on foot and stops once it's out.

The ways are fields of distances on foot over the map's nav (`BotNav`): to every node 38 m or more
from the spike, and to the node a defuser goes to by it. Each is worked out a little each time a
side's plan is gone over, 2000 nodes at a time, and is done within 2 s of the plant, long before the
first bot needs to go; until it is, a bot judges by what's done so far. Both are shared by both
sides.

### A bot's hands

`BotSpike` makes a tick's hands from the bot's job, its simulation and what the spike says it may
do: whether to hold Use, the spike's slot to have in hand, whether to stand still and whether to
leave the gun alone. Planting, it draws the spike in the plant area and holds Use; defusing, it
holds Use within reach of the spike and in sight of it. While the spike's in hand or a plant or a
defuse is under way, nothing's fired, reloaded, scoped or crouched for: fire with the spike in hand
would plant it, and a crouch could take the spike out of sight.

### The server

`SpikeServer` keeps one spike for players and bots, each by their id in the rules, a player's UserId
or a bot's. `BotServer` asks it what each bot may do each tick and steps the bot's simulation with
that, as `PlayerSimServer` does a player's, and tells it what the bot did: a plant, a defuse or a
defuse let go of. A bot dying drops the spike where it falls or keeps a defuse's half, as a player
does, and a bot gone with the spike leaves it where it was. The server gives no ultimate points for
a bot's plant or defuse, as bots have no ultimates.

The defending side's plan uses only a planted spike, which everyone sees on screen; never where a
dropped or carried one is, which a defender couldn't know.

### On screen

Workspace's `VFSpikeCarrier` carries the carrier's id in the rules, so a bot carrying the spike has
the minimap's carrier mark for its side as a player does, and the debug HUD (F3) names it.

### The tests

`tests/botspike.luau` has 31 checks: who goes for the spike and when, with and without a player on
the side; a bot's hands, planting and defusing, letting go to fight and not; a whole attack on each
map, fetched, carried and planted on the site planned, and on Outpost watched and left before the
blast; a retake of each site of each map, gathered, pushed and defused in time with the others round
the spike; too late for one, everyone out of the blast; and the time judged on foot.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Bots/BotSpike.luau` | New: a bot's hands on the spike, what it presses to plant or defuse it |
| `src/shared/Bots/BotSpots.luau` | Each site's places to plant, its ways back in and its watch spots; the plan's work paused after each way in and each entrance's holding spots |
| `src/shared/Bots/BotTeam.luau` | The spike in each side's plan: fetching it, planting it, guarding it, the retake and the defuse, and getting out of the blast |
| `src/shared/Bots/BotNav.luau` | Fields of distances on foot worked out a little at a time, to nodes as well as from them |
| `src/server/BotServer.luau` | The spike in a bot's tick: its hands, what it may do, and what it did told to `SpikeServer`; giving a bot the spike and taking it |
| `src/server/SpikeServer.luau` | Players and bots by their ids in the rules: picking it up, carrying, planting, defusing and dying with it |
| `src/shared/Spike/Spike.luau`, `src/client/ClientSpike.luau` | The carrier's id: a player's UserId or a bot's |
| `src/client/Debug/DebugHud.luau` | The bot carrying the spike, named |
| `tests/botspike.luau`, `tests/run.luau` | New: the 31 checks |
| `docs/studio-checklist.md` | Section 65 |

## 7. Debug tools

- In Studio, each bot's stand-in's `VFBotTask` has its new jobs too: `fetch`, `plant`, `guard`,
  `retake`, `defuse` and `clear` (out of the blast).
- Workspace's `VFSpikeCarrier` is a bot's id in the rules, below 0, while a bot carries the spike;
  the debug HUD's `spike` line says which (`carried by BOT Ash`).
- Workspace's `VFBotMs` has the milliseconds the bots take of each server frame, as in system 60.

## 8. Refinement loop

1. Play the spike rounds with bots on both sides, attacking and defending: whether they get the
   spike planted, where, and whether their post-plant and retakes look like people's.
2. Tune `BotTeam`'s spike numbers and `BotSpots`' places to plant and watch from, and re-run
   `tests/botspike.luau` for each map's times.
3. Re-run `luau tests/run.luau`.

## Known gaps to check in Studio

- Bots picking the spike up, carrying it and planting it in the place's real geometry, on Roblox's
  own collisions, and the plant going down in the plant area.
- A bot's plant and defuse going through the round as a player's do: what's shown and heard, and the
  round won.
- Players first: a spike dropped by a player left to them for 5 s, and a player carrying it or
  defusing it.
- Attackers watching the spike and leaving the blast in time; defenders retaking together and
  defusing, or leaving the blast when it's too late.
- A bot carrying the spike on the minimap for its side, and named in the debug HUD.
- What the bots cost the server around a plant.
- Not in this system: taking over a bot after dying, bots hearing the spike or a defuse, and
  abilities.

Section 65 of the [Studio checklist](../studio-checklist.md) covers these.
