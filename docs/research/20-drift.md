# System 20: Drift

Drift is Jett's passive. In the reference, holding jump while she falls lets her glide: she comes
down slowly instead of dropping, so she can float off a ledge or down from the top of Updraft and
stay in the air for longer. It takes no charge and has no limit, and she can still shoot and use
her abilities while it lasts. Others hear it.

This system adds it to system 17's kit, the last of Jett's four abilities and her passive to be
playable. It's the kit's first passive: it has no slot or key of its own, only the jump key. The
glide is part of the movement step, so it's predicted on your screen and decided by the server on
the same ticks, as Updraft and Tailwind are.

As before, everything comes from Riot's patch notes and from community wikis and guides. No game
files, memory, network traffic or protected assets were used, and nothing reads the game while it
runs. The glide's look is ours, and its sound is a recording from the Creator Store's free
library, as system 17's are. Status labels:

| Label | Meaning |
| --- | --- |
| **Confirmed** | Stated by Riot (patch notes, dev blog, a developer's public post) |
| **Community** | Published by a wiki, stat site, guide or a player's test, not by Riot |
| **Estimate** | Our own number or reading. It must be measured and tuned before we trust it |
| **Measured** | Ours, measured from a public source |

## 1. Observable behaviour

- **Hold jump in a fall.** With jump held while she's falling, her fall slows to a glide. Let go
  and she falls as before.
- **From anything.** A jump held on the way down, a step off a ledge, the top of Updraft.
- **Only falling.** It slows the way down, not the way up.
- **Free, with no limit.** It works until she lands, as often as she likes.
- **Weapons and abilities.** She can shoot and cast while she glides. Guns are no more accurate
  than in any fall, and Blade Storm's knives are as exact as ever.
- **Fall damage.** A glide brings her down from a height without the damage of the fall.
- **Not while suppressed or detained.**
- **Sound.** The glide has a sound of its own, which others hear.

## 2. Publicly documented details

### From Riot

| What | Source |
| --- | --- |
| Suppression and detain | Patch 9.10, under Jett's Drift (Passive): "Balance-impacting bug fix: Jett can no longer float while suppressed or detained." ([patch notes](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-9-10/)) |
| Others hear it | Patch 12.04: "Fixed a bug where Drift's passive gliding SFX was audible from the other side of Astra's Cosmic Divide." ([patch notes](https://playvalorant.com/en-gb/news/game-updates/valorant-patch-notes-12-04/)) A wall that blocks sound blocks it, so it's heard out in the world |
| Its cost to run | Patch 12.09: "Fixed a bug where using Jett's Drift caused performance drops" ([patch notes](https://playvalorant.com/en-us/news/game-updates/valorant-patch-notes-12-09/)) |

### From the community

| What | Value | Sources |
| --- | --- | --- |
| The ability | "Holding the jump button while falling allows you to glide through the air." Its key is the jump key, Space on PC | [The VALORANT Wiki's Jett page](https://wiki.playvalorant.com/en-us/Jett); the [Fandom wiki's Mobility page](https://valorant.fandom.com/wiki/Mobility) |
| When | "Whenever she is airborne, she can hold her jump key to reduce her fall speed", and "glide down to ground instead" | [The VALORANT Wiki's Passive Effects page](https://wiki.playvalorant.com/en-us/Passive_Effects) |
| Weapons and abilities | "Jett can still use her weapons and other abilities while using Drift." | The same page |
| Fall damage | She can "safely fall from large distances without taking fall damage upon landing". Updraft lands safely "even if she does not slow her descent using Drift", as long as she lands no lower than where she started | The same page; [the VALORANT Wiki's Updraft page](https://wiki.playvalorant.com/en-us/Updraft) |
| Free | "Unlike the previous Agents, Jett's passive isn't fueled by any form of energy. It's just there, and it works until she hits the ground." Gliding, she "can now cover longer distances" | [Sportskeeda](https://www.sportskeeda.com/valorant/all-passive-abilities-valorant-ranked) |
| Aim in the air | "Once in the air, unless you're using your ultimate, your aim is not going to be accurate" | [Switchblade Gaming's Jett guide](https://www.switchbladegaming.com/valorant/jett-guide/) |
| Knives and Updraft | "Jett's knife throws are reported as fully accurate while moving, jumping, or gliding." At the top of Updraft, holding jump slows the way down, "extending airborne time past the base 0.6 seconds" | [esports.net's Jett guide](https://www.esports.net/wiki/guides/valorant-jett-guide/) |
| Its history | v1.0: "Fixed a bug with Jett's lower body popping out of place during her glide" | The VALORANT Wiki's Jett page |

Nothing public gives how fast she falls while gliding, how quickly a fast fall slows to the glide
when jump is pressed, or whether gliding changes her air control. Those are ours, and labelled as
estimates.

## 3. What can be measured, and how

| What | How |
| --- | --- |
| The glide's speed | A public clip of a glide from the top of Updraft, or from a ledge of known height, to the floor: its time against the height. Ours takes 3.0 s from Updraft's top and 0.81 s for a held jump |
| The brake | Frame-count a clip of jump pressed in a long fall: the frames from the press to the slow fall. Ours takes 12 ticks (0.09 s) from 7.5 m/s |
| Air control | A glide with A or D held, against a standing jump's 0.37 m to the side |
| How far it's heard | The minimap's sound circle around a gliding Jett in a public video, against the map's scale |

## 4. Confirmed vs estimated, as implemented

| Rule | Ours | Status |
| --- | --- | --- |
| The glide | With jump held in a fall, she falls no faster than 2 m/s; a faster fall slows to it at 60 m/s each second | Community (held in a fall); estimate (2 m/s, 60 m/s²) |
| When | Any fall with jump held: a jump's way down, a step off a ledge, after Updraft or Tailwind. Never rising, and not during a dash or a lift, which fly as they did | Community (in the air, falling); estimate (the dash and the lift) |
| What's left alone | Her speed along the ground and her air control are a fall's. A held jump rises as any jump does | Estimate |
| Landing | Held into a landing, jump doesn't jump again: it has to be let go of and pressed again, which goes for any jump pressed in the air | Estimate (Unreal's and Source's rule) |
| Weapons and abilities | Everything works in a glide. A gun's cone is the air's; Blade Storm's knives land on the crosshair | Community |
| Free | No charge and no limit | Community |
| The sound | A stand-in, Updraft's gust slowed and quiet, every 0.3 s while it lasts; yours on the Self bus, others' on them out to 30 m, and not from the other side in the buy phase | Confirmed (others hear it, Patch 12.04); estimate (the rest) |
| The look | For others, faint rings of air left at the waist as they sink | Ours |

## 5. Design

### The glide

`AbilitySim.step` asks for it. When jump is held, the kit's agent has Drift
(`AbilitySim.hasPassive`) and no dash or lift is under way, the tick's `Motion` carries a `glide`:
Drift's fall speed and brake. `MovementSim` uses it where it applies gravity:

- A fall that would pass the glide's speed this tick stops at it.
- One that's already faster slows at the brake until it gets there.
- Rising, gravity is as ever, so a held jump tops out where any jump does.

Nothing else in the step changes: the ground, air strafing, crouching and collision are as they
were. The movement state keeps whether the last tick glided (`gliding`), for the sound, the look
and the HUD; nothing steps from it. A dash and a lift set the fall themselves, so they aren't
touched, and with jump still held the glide takes up again when they end.

### Jump held in the air

Holding jump in the air now latches it (`jumpLatched`), as a jump from the ground already did.
Without that, a press in the air to glide, held into the landing, would jump on the tick she
landed. Now any jump pressed in the air has to be let go of and pressed again on the ground. That's
Unreal's default, where a press is spent on the tick it's made whether it jumps or not, and
Source's, where a held jump doesn't pogo ([01-movement.md](01-movement.md)).

### The wire

- The ack's movement flags carry `gliding` (8) beside grounded, crouched and the latch, so a
  correction replays a glide exactly.
- Each snapshot pose carries `gliding` (64), for others' sound and look. Between two snapshots,
  `PoseHistory` takes the newer one's, as it does the other flags.
- The server's `VFKit` reads `glide` while it has you gliding, for scripted checks.

### Sound

The reference's glide has a sound of its own, which others hear (Patch 12.04). No wind that runs
on turned up in the library yet, so ours is a stand-in, `glide`: Updraft's gust at half speed and
at 0.35 of the volume, played every 0.3 s while the glide lasts so the gusts run together.

- Yours is on the Self bus, from your predicted ticks, at 0.6 of anyone else's, so it doesn't
  cover their steps.
- Others' is out in the world on their chest as they're drawn, on the ability curve to its 30 m
  edge, and not from the other side in the buy phase.
- As the glide ends, the last gust rings out.

### The look

For others, `AbilityEffects` leaves a faint ring of air at the waist every 0.2 s while they glide.
Each spreads a little and fades over 0.35 s where it was left, so as they sink the air seems to
rush up past them. Your own glide shows nothing: you're in first person.

### Not here yet

- **Suppression and detain.** Nothing suppresses or detains yet, so nothing stops a glide (v9.10).
- **Fall damage.** There's no fall damage, so a glide saves nothing yet.
- **A wind that runs on.** The glide's sound is a stand-in, until a sound search finds one.
- **Air control in a glide.** Ours is a fall's. Whether the reference's changes is unmeasured.
- **Her glide in others' view.** Others are drawn as their hitboxes, so there's no gliding pose.

## 6. Implementation map

| File | What |
| --- | --- |
| `src/shared/Abilities/AbilityConfig.luau` | `Drift.fallSpeed` and `Drift.brake`; an agent's `passive`, and Jett's `drift` |
| `src/shared/Abilities/AbilitySim.luau` | The glide asked for with jump held; `hasPassive`; `glide` in the summary |
| `src/shared/Movement/MovementSim.luau` | `Motion.glide`, a fall held to it, and `gliding`; jump held in the air latched |
| `src/shared/Net/PlayerCodec.luau` | `gliding` in the ack's movement flags and in each snapshot pose |
| `src/shared/Net/PoseHistory.luau` | The newer pose's `gliding` between snapshots |
| `src/server/PlayerSimServer.luau` | Each pose's `gliding` |
| `src/server/Dummies.luau` | Dummies don't glide |
| `src/server/AbilityServer.luau` | `glide` in `VFKit` |
| `src/shared/Audio/SoundConfig.luau` | The `glide` sound, and `Drift`: how often and how loud |
| `src/client/Audio/GameSounds.luau` | Your glide's gusts, and others' |
| `src/client/AbilityEffects.luau` | Others' rings |
| `src/client/Debug/DebugHud.luau` | `glide` on the `state` line |
| `tests/drift.luau` | 49 checks: the numbers and their labels, a held jump, a press in the air, the speed along the ground, a ledge, a press in a fast fall and letting go, landing with it held, Updraft's lift and its top, Q and jump together, a dash in a glide, a gun's cone and the knives, an agent without it, and the wire |

## 7. Debug tools

- The HUD (F3): `state` reads `air glide` and `vert` reads `-2.00 m/s` while you glide, and the
  jump line's airtime covers the glide.
- Each player's `VFKit` reads `glide` at the end while the server has them gliding, as
  `C2/2 Q1/1 E1/1 X8/8 glide`.
- `VFTestButtons` 64 holds jump; 8256 is Q and jump together, so Updraft casts as it's set and the
  glide follows.
- The Sound Lab logs `glide` about three times a second while you, or anyone, glides.

## 8. Refinement loop

1. Time a glide from the top of Updraft in a public clip, and set `Drift.fallSpeed` so ours takes
   as long. Check a held jump the same way.
2. Frame-count a press in a long fall, and set `Drift.brake`.
3. Compare a glide with A or D held against a fall's air control.
4. Search the Creator Store's library for a wind that runs on, a loop or a long take, to replace
   the stand-in.

## Known gaps to check in Studio

- Holding Space through a jump, the way down is slow: `vert` reads `-2.00` and `state` reads
  `glide`, and the jump line about 0.81 s.
- Held from the top of Updraft, about 3 s in the air.
- Pressed in a fall, the fall slows at once; let go, it speeds up again.
- Held into a landing, it doesn't jump again until it's pressed again.
- A dash in a glide flies level, and the glide takes up again after it.
- A gun's cone is the air's in a glide, and Blade Storm's knives land on the crosshair.
- Your glide is heard as a soft run of gusts.
- Another player sees and hears a glide where you are on their screen.

Section 24 of the [Studio checklist](../studio-checklist.md) covers these.
