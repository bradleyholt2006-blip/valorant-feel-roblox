# System 64: the 1v1

A mode of one against one: Skirmish's rounds with one a side, played on a map built by hand in the
place rather than in code. Bradley built the map in Studio, as Workspace's `1v1Map`, and asked for a
1v1 mode on it. It's on the Play menu as Duel, and P moves from Skirmish to it.

## 1. Rules

The rounds are Skirmish's (system 7, `ArenaRules`), with the side size and the win score their own
(`ArenaConfig.Duel`):

| What | Value | Status |
| --- | --- | --- |
| Players a side | 1 | estimate: ours, for a 1v1; the reference's Skirmish layouts are played 1v1 as well as 2v2 |
| Rounds to win | 10 | confirmed: Skirmish's "First to 10 wins" (Patch 11.07b) |

Everything else is Skirmish's: one life a round, a 15 s buy phase first and 3 s ones after, held in
the spawn room behind a barrier, no round timer, every gun free each round, every ability charge in
every life, and the victory screen after the last round. Anyone over two waits in line, and takes the
place of whoever leaves. With the map the only one, there's no vote: the next match starts after the
victory screen. A bot (system 60) plays whoever's alone (`BotConfig.Quotas.duel`, 2), and gives its
place to a player who joins. Nobody takes over a bot (system 62) and nobody's revived (system 39):
there's nobody on your side.

## 2. The map

`DuelMap` reads everything from the parts as they stand, so the map can be moved, rebuilt or
redressed with no change in code. What it needs:

- Workspace's `1v1Map`, a folder or a model.
- In it, a model named `Spawn1` and one named `Spawn2`: each side's spawn room. Side 1 spawns in
  `Spawn1`.
- In each, a part named `Floor` (or failing that, the room's widest part is taken as its floor).

What it works out:

- **Spawn spots.** The middle of each room's floor, facing the room's door.
- **Doors.** Along the floor's edge nearest the other room, the wall standing within 3 studs of the
  edge (the plane across it that's most solid), and in it each gap at least 2 studs wide that's open
  from 1 to 6 studs off the floor. The door is as tall as the gap is open over its middle, up to 30
  studs. The barrier, a ForceField part named `Barrier` in its side's colour, fills it for each buy
  phase. On Bradley's map each room has one door, 10.5 x 11.75 studs.
- **The bots' map.** Every part something collides with, as the arena's parts are (`BotNav.ofParts`):
  floor where its top is the floor's height and it's over 4 m², wall where it's 2.5 m taller than
  the floor and 3 m long, cover otherwise, and nothing where it's 2 m or more overhead (a door's
  lintel). The bots' places to go are a grid of nine over the widest floor.
- **The minimap.** Drawn from the parts as the course's is for From the Shadows (`PartsPlan`), its
  ground the floor's height, the barriers left out.

As the mode starts, the server makes the map a model that's always on every client
(`ModelStreamingMode.Persistent`), as the arena's are, so a streaming place never drops a wall a
client's movement needs. Without the map, or without both rooms, Skirmish is played instead, with a
warning in the output.

## 3. What's ours

Everything here is ours: the side size, how the doors and spots are found, and how the parts are
sorted for the bots. The win score is Skirmish's. No Riot image, model or sound is in the
repository, and the map is Bradley's own, in the place.
