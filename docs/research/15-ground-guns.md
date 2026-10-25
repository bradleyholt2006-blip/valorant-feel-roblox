# System 15: Guns on the ground

In the reference, a gun can leave a player's hands and lie on the floor for anyone to take. G
drops the gun in hand. The dead drop theirs where they fall. Anyone, on either side, can pick a
gun up: walking over one fills an empty slot, and looking at one and pressing F swaps it for the
gun in its slot. A side that wins a fight takes the losers' rifles, a player with spare credits
buys a gun and drops it for a teammate, and a player saving picks up whatever's left. This system
adds all of that. G and the walk-over work everywhere: on the course, in Skirmish and in the spike
rounds. The dead drop their guns only in the spike rounds, where dying loses your kit anyway.

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

- G ("Drop Equipped Item") throws the gun in hand a little ahead of you. The next weapon comes
  out: the sidearm after a primary, the knife after a sidearm. The knife can't be dropped. With
  the spike in hand, G drops the spike (system 12), not a gun.
- Someone who dies drops their primary where they fall, or their sidearm if they have no primary.
  Nothing else they carried drops.
- A gun on the ground keeps the rounds it had, in the magazine and in reserve.
- Walking over a gun picks it up if its slot is empty. It goes into the slot without being drawn.
- Looking at a gun within reach shows it outlined, with a prompt. F picks it up and draws it. If
  its slot holds a gun, that gun is dropped in its place.
- Anyone can take any gun: a teammate's, an opponent's, their own.
- A gun picked up is yours from then on, and stays with you into the next round if you survive.
- The guns on the ground are gone when the next round starts.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| A gun bought for a teammate can be sold back | Patch 1.10 "added the ability to sell back guns bought for a teammate" (quoted by [GGRecon](https://www.ggrecon.com/articles/valorant-players-buy-back-feature-refund-team-guns), which reports that it's unreliable) |
| A dropped gun shows its skin | Patch 9.06: "you'll now be able to see if you're picking up a Reaver vandal or Forsaken vandal" ([patch notes](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-906/)) |

### From the community

| What | Value | Sources |
| --- | --- | --- |
| What the dead drop | "Agents automatically drop their Primary weapon (Or Secondary weapon if they do not have a Primary) when they die" | The [Valorant Fandom wiki's Weapons page](https://valorant.fandom.com/wiki/Weapons) |
| Who can pick guns up | "Weapons can also be picked up off the ground after being dropped by a player, both friendly and hostile, which will carry on with the player into the next round" | The same page |
| Picking up after the round | Guns can be picked up in the seconds after a round ends | [Upcomer](https://www.upcomer.com/this-simple-fix-would-make-weapon-looting-much-easier-in-valorant/) (closed beta, 2020) |
| One primary at a time | "You're only allowed to carry one primary weapon" | [Dexerto](https://www.dexerto.com/valorant/valorant-weapon-juggling-gives-clutch-chances-similar-to-csgo-1369375/) |
| Dropping and picking up again | Players juggle guns, "dropping and picking up their primary over again" | Dexerto |
| The keys | G drops, F ("Use Object") picks up | The reference's default key bindings |

Nothing public gives the distances: how far a dropped gun lands, how close you must be to walk
over one, or how far F reaches. Those are ours, and labelled as estimates.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| How far ahead a G drop lands | From a public video, frame a drop on a floor with a known grid (a range's floor) |
| How close walking over must be | Walk slowly past a gun in a public video and note where it goes |
| How far F reaches | The distance at which the prompt appears, against a gun of known length |
| Whether the dropper can pick a gun straight back up | A public video of the juggle |
| What a swap does with your gun | Where your gun lands when you take another with F |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| G drops the gun in hand | A primary or a sidearm, never the knife; the spike first if it's in hand | Community |
| The next weapon | The first slot with something in it, drawn with its draw time | Community (as system 14's sell back to nothing) |
| What the dead drop | Their primary, or their sidearm if they have no primary, where they fall | Community |
| The dead drop only in the spike rounds | Skirmish's and the course's kits work differently | Ours |
| Rounds kept | The magazine and the reserve, as they were. A reload under way is lost | Estimate (how the reference plays, with no written source found) |
| Who can pick up | Anyone alive, on either side | Community |
| Walking over | Within 0.7 m across and 1 m up or down of the feet, as the spike, into an empty slot, not drawn | Estimate |
| The dropper | Doesn't pick up a gun that landed at their feet until they step off it, as the spike | Estimate |
| How far G throws | 1.2 m ahead, stopped 0.2 m short of a wall, as the spike | Estimate |
| F's reach | 3 m from the eye, the view passing within 0.4 m of the gun's middle, with nothing solid in between | Estimate |
| F's slack | The server takes 0.5 m more of both, for the view moving on while the request travels | Estimate |
| F with the slot full | Your gun goes down where the one you took lay | Estimate |
| F draws the gun | Drawn once the server has put it in its slot | Estimate |
| F while planting or defusing | Does nothing | Estimate |
| The ground cleared | As each round starts, and when what's played changes | Estimate (Upcomer has guns picked up as a round ends, not after) |
| At most 40 on the ground | The oldest goes first (the course has no rounds to clear it) | Ours |
| A gun that leaves a slot | Takes what was bought into it this buy phase with it: it can't be sold back, even if you pick it up again | Ours. The reference lets a gun bought for a teammate be sold back (Patch 1.10) |

## 5. Design

### The drop is predicted

G is a button in the input stream (system 12 added it for the spike), so the drop runs inside
`PlayerSim.step` and the owner predicts it like a shot. `PlayerSim.step` notes whether G was
pressed this tick before `SpikeSim.step` reads it. If the spike didn't take the press and no plant
or defuse is under way, `WeaponSim.takeInHand` lets go of the gun in hand. It returns the gun and
its rounds as a `Dropped`, which comes out of `PlayerSim.step` as a fourth value. The gun leaves
your hand on the tick you press G, and the server's simulation lets go of it on the same tick, so
nothing has to be corrected. The ack carries the empty slot and the held G (a test checks both).

### The ground as plain state

`GroundGuns` keeps what's on the ground so the offline tests can play it. Each gun has an id, its
weapon, its rounds, where it rests and the way it points. The module answers the questions both
sides ask:

- `slotOf` and `deathSlot`: which slot a gun goes in, and what someone who dies drops.
- `walksOver` and `walkedOver`: whether someone's feet are over a gun, and the nearest one they'd
  take.
- `alongView` and `aimedAt`: the gun the view is on, the nearest along it of those it passes
  close to, within reach.

### The server

`GroundGunsServer` owns the guns. It hears of each G drop from `PlayerSimServer.dropListeners`, with
the feet and the facing, and lays the gun on the ground under where it's thrown (`RobloxSpike.reach`
and `ground`, as the spike). In the spike rounds (`dropOnDeath`, set by the arena) a death listener
lays the dead's gun at their feet and takes it from their loadout. Each frame, after the moves, it
hands any gun walked over to a player whose slot is empty.

F arrives as the `GroundGun` remote with the gun's id. The server checks the gun's still there, the
player is alive and not planting or defusing, and their own view as of their last move (eye and aim,
`PlayerSimServer.view`) passes close enough within reach, with the slack. Then it checks nothing
solid is between the eye and the gun. Then it swaps. `PlayerSimServer.give` takes the rounds a gun
keeps.

Every client sees the guns as invisible parts in `Workspace.VFGroundGuns`, one per gun, named by its
id, with `Weapon`, `Ammo` and `Reserve` attributes. The model streams to everyone whole
(`ModelStreamingMode` Persistent). The arena clears the ground at each round's buy phase, in Skirmish
and the spike rounds, and when it starts or stops.

### The client

`GroundGunsView` draws each gun lying on its side where it rests, in its stand-in look from
`WeaponLooks`. Every frame it asks `GroundGuns.aimedAt` for the gun the view is on, from the
predicted eye and the camera's aim, and checks it can be seen (`RobloxSpike.sees`, at the gun's
height). It outlines that gun (a `Highlight`) and shows `F  PICK UP VANDAL` for an empty slot or `F
SWAP FOR VANDAL` for a full one, under the crosshair. F fires the remote and asks
`PlayerController.drawWhenGiven` to draw the gun once the server's ack shows it in its slot, as a
purchase is drawn. Nothing shows while the buy or settings menu is open.

The F3 HUD's ghost box was on G. G now drops a gun, so the ghost toggles on G only with the knife in
hand.

### The buy menu

A gun that leaves its slot, dropped or swapped, takes that slot's purchase record with it
(`Shop.forget`, through `ShopServer.forget`). Without that, you could buy a Vandal, drop it for a
teammate and sell it back, and the side would have a free Vandal. The reference handles this by
letting the teammate sell it back instead (Patch 1.10). Ours is the simple safe rule, and the
difference is listed below.

### Not here yet

- **A gun replaced in the buy menu dropping.** System 14's doc says the reference drops the gun a
  purchase replaces. Here the buy menu still holds it so you can buy it back for nothing. Which is
  right needs checking in a public video.
- **Selling back a gun bought for a teammate** (Patch 1.10), with the refund going to the buyer.
- **Whose gun it is.** The reference shows the buyer's name on a gun bought for a teammate, and
  its skin (Patch 9.06). There are no skins here.
- **Sounds.** A gun lands and is picked up without a sound. The spike's drop has one (system 12).
- **Throwing.** A dropped gun lands at once where it falls. There's no arc and no bounce.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Weapons/GroundGuns.luau` | The ground as plain state, its numbers, walking over, the gun in view |
| `src/shared/Weapons/WeaponSim.luau` | `takeInHand`, `Dropped`, and `give` with the rounds a gun keeps |
| `src/shared/PlayerSim.luau` | G lets go of the gun in hand, and `step` returns it |
| `src/shared/Weapons/Shop.luau` | `forget`: a gun gone takes its purchase with it |
| `src/shared/Spike/RobloxSpike.luau` | `sees` at a height of the caller's |
| `src/shared/Net/Remotes.luau` | `GroundGun`: F, with the gun's id |
| `src/server/GroundGunsServer.luau` | The guns on the ground, the parts, G and death drops, walking over, F |
| `src/server/PlayerSimServer.luau` | `dropListeners`, `view`, and `give` with rounds |
| `src/server/ShopServer.luau` | `forget` |
| `src/server/Arena.luau` | The ground cleared each round and on a change, and `dropOnDeath` in the spike rounds |
| `src/client/GroundGunsView.luau` | The guns drawn, the outline, the prompt and F |
| `src/client/Debug/DebugHud.luau` | The ghost on G only with the knife in hand |
| `src/client/Debug/TestAim.luau` | `VFTestTake`: F, for scripted checks |
| `tests/groundguns.luau` | 51 checks: what can lie there, putting down and taking up, walking over, the gun in view, G as PlayerSim steps it, rounds kept, the purchase forgotten |

## 7. Debug tools

- `Workspace.VFGroundGuns` lists every gun on the ground, with its weapon and rounds as
  attributes, in the Explorer.
- `VFTestTake` (a boolean attribute on your player, Studio only) presses F for you, and clears
  itself. With `VFTestAimPoint` set to a gun's position it picks that gun up without the mouse.
- `VFTestButtons` set to 2048 holds G, as before.
- The debug keys 5 to 9 give guns to drop.

## 8. Refinement loop

1. Find a public video with a drop on a floor of known size: a range's grid, or a map whose tile
   sizes are known.
2. Measure how far the gun landed, how close the player was when a walk-over took it, and how far
   away the prompt appeared.
3. Change `GroundGuns.Params` with the source and status, and the tests follow.
4. Watch for what a purchase does to the gun it replaces.

## Known gaps to check in Studio

- G drops the gun in hand ahead of you and the next weapon comes out, with the knife and the spike
  as the tests have them.
- The gun is drawn lying on the floor, short of walls, and another player sees it land and go.
- Walking over a gun fills an empty slot without drawing it, and a full slot walks past it.
- F's outline and prompt, at 3 m and not through walls, and the swap.
- Rounds kept through a drop and a pickup.
- Death drops in the spike rounds, picked-up guns kept into the next round, and the ground cleared.
- Nothing to sell back after a drop.

Section 19 of the [Studio checklist](../studio-checklist.md) covers these.
