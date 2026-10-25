# valorant-feel-roblox

Valorant-style tactical FPS mechanics rebuilt from scratch in Roblox (Luau), aiming for the same
feel, responsiveness and mechanical depth with original code and assets. Reference behaviour comes
only from public footage, patch notes, developer blogs and our own measurements.

Built one system at a time:

1. **First-person movement and counter-strafing**, with Counter-Strike's air strafing held to running
   speed - [research and design](docs/research/01-movement.md)
2. **Weapon firing**: fire modes, fire rate, ammo, reload, draw, ADS and scopes, damage, health and
   shields, hit slow, server-side hit resolution, practice dummies, and other players drawn as
   their hitboxes until there are agent models - [research and design](docs/research/02-weapon-firing.md)
3. **Spread and recoil**: firing error by bullet, recovery and tap efficiency, movement error by
   state, jump landing, aim-down-sights, recoil climb and sideways drift, seeded per-shot spread
   the server and client agree on - [research and design](docs/research/03-spread-recoil.md)
4. **Hit registration and lag compensation**: server rewind to what the shooter saw with Riot's
   140 ms cap, a render clock measured from snapshot arrivals, Network Buffering, players' and
   dummies' moves paced in the snapshots so others see them move evenly, client-predicted sparks
   and server hit confirms pinned to the body part, simulated latency, jitter and loss for testing
   in Studio - [research and design](docs/research/04-hit-registration.md)
5. **Wall penetration**: Low / Medium / High weapon classes against soft, medium, hard and solid
   materials, thickness along the ray, damage left after walls, bullets stopping inside walls,
   holes, dust and sparks, a wallbang lane - [research and design](docs/research/05-wall-penetration.md)
6. **The look**: a lighting preset that keeps shade from getting dark and values close together,
   colour grading and soft bloom, a subtle vignette, a red outline on enemies (blue on allies) that
   grows with distance, the reference's four enemy colours for colour blindness, and no character
   shadows - [research and design](docs/research/06-visuals.md)
7. **The arena**: a whitebox of Skirmish A, the reference's small-fight layout, measured from
   Riot's minimap, played by Skirmish's rules: two sides on Roblox teams, a buy phase held behind
   each spawn's barrier, rounds that end when a side is wiped out, first to 10, with a score bar
   and banners, and round restarts that respawn living players cleanly -
   [research and design](docs/research/07-arena.md)
8. **Sound**: running footsteps heard by others out to a flat 20 m edge, never walking or
   crouching ones; landings heard unless they come up onto something higher; gunshots from where
   they were fired, dulled by distance and muffled through walls; reloads played in parts as
   they go, draws and dry fire; hit, headshot and kill sounds; nothing from the other side in the
   buy phase. The sounds are Pro Sound Effects' recordings from the Creator Store's free library,
   and Roblox's own character sounds are off -
   [research and design](docs/research/08-sound.md)
9. **The arsenal**: all 20 guns and the knife, with every way they fire: semi and automatic, the
   Stinger's and the Bulldog's bursts zoomed, the Classic's three-bullet right click, shotgun
   pellets that land as one hit, shell-by-shell reloads, the Outlaw's double tap, the Odin's rising
   fire rate, every zoom and scope, and suppressed guns whose tracers only their own side sees;
   Light Armor, Heavy Armor and the Regen Shield, each taking its share of a hit; and a buy menu
   on B with every gun and shield, its numbers on hover, click to buy and right-click to sell back -
   [research and design](docs/research/09-arsenal.md)
10. **The knife**: a slash on the left button round a three-swing combo and a harder, slower stab
    on the right; double damage from behind, judged on a 180-degree arc, so a stab in the back
    kills through any shield; one target a swing, the one nearest the aim, never through a wall;
    lag compensated like a bullet, guessed on your screen at once with a cut where it strikes the
    level, and the library's knife recordings for its sounds -
    [research and design](docs/research/10-knife.md)
11. **Settings**: your Valorant sensitivity and scoped multiplier, turning the view exactly as far
    as the reference does for the same mouse movement, with cm/360 worked out from your mouse's
    DPI; crosshair codes pasted from the reference or a crosshair site and drawn pixel for pixel,
    with their own crosshairs for aiming down sights and the sniper scope's dot, lines that spread
    as you move and fire and top lines that fade in a spray; a settings menu on O, and both kept
    for your next session - [research and design](docs/research/11-settings.md)
12. **The spike**: carried in slot 4 and dropped with G, picked up by running over it; held 4
    plants it in a site in 4 seconds and defuses it in 7, rooted, with half a defuse kept; a
    defuse needs the defuser in range and in sight of it throughout; a 45-second countdown that
    beeps faster as it ends, with the reference's tells (red lights and a rising casing while
    defused, the white sphere at 7 seconds), and a blast that kills everyone within 35 m; all
    predicted on your screen and decided by the server. On the course, two sites behind the spawn
    where anyone can plant and defuse - [research and design](docs/research/12-spike.md)
13. **Rounds played for the spike**: the reference's standard match on Outpost, a small two-site
    map of our own for one to three a side. One side attacks with the spike, which lies in front
    of them each round and only they can carry; the other defends the sites, and only it can
    defuse. A buy phase behind the spawn barriers (45 s at each half, 30 s otherwise), 100 s to
    plant, a round won by a wipe, the clock, a defuse or the blast, halves of 12, first to 13 and
    sudden death at 12-12, or Competitive's win by two, or Swiftplay's first to 5; the Classic and
    the knife at each half and after a death; a top bar with the round's clock that gives way to
    the spike, and banners for match point, overtime, switching sides and how each round was won -
    [research and design](docs/research/13-rounds.md)
14. **The economy**: credits in the spike rounds, paid as the reference pays them. 800 at the start
    of each half; each round then pays 3000 for a win, or 1900, 2400 and 2900 for losses in a row,
    or 1000 for a loss survived without a plant (or, defending, after the blast); 200 a kill and 300
    to every attacker for the plant, as they happen; 9000 at most; everyone on 5000 in overtime,
    and Swiftplay's own schedule. The buy menu charges for each purchase, less the refund of what it
    replaces from the same buy phase, dims what you can't afford and shows what the round pays; a
    survivor keeps their shield, damaged, into the next round - [research and
    design](docs/research/14-economy.md)
15. **Guns on the ground**: G drops the gun in hand, a little ahead of you, and the next weapon
    comes out; in the spike rounds the dead drop their primary, or their sidearm without one.
    Anyone can pick one up, on either side: walking over it fills an empty slot, and F swaps the
    gun you're looking at for yours, which goes down in its place. Guns keep their rounds on the
    ground, the drop is predicted on your screen, and the ground is cleared as each round starts -
    [research and design](docs/research/15-ground-guns.md)
16. **The round at a glance**: a kill feed at the top right, a line a kill with the killer, the
    weapon, the headshot and wallbang marks and whoever died, each name in its side's colour and
    your own lines outlined in gold; a tile for each player beside the top bar, dimmed once they're
    dead; and in the spike rounds a scoreboard held on Tab, with everyone's kills, deaths, assists
    and average combat score (damage, kills worth more with more enemies alive, multikills), your
    side's credits and guns, and the other side's credits as the round started -
    [research and design](docs/research/16-scoreboard.md)
17. **The ability kit**: four abilities on C, Q, E and X, with an ability bar between health and
    ammo. Basic abilities are bought a charge at a time in the buy phase and kept through a death
    into the next round; the signature has a free charge every round; the ultimate fills with a
    point for each kill, death, plant and defuse. Everyone plays Jett for now, and two of hers
    work: Updraft throws you straight up about 4 m, and Tailwind readies a gust that, after a
    second's windup, dashes you about 7 m the way you're moving, and comes back with two kills.
    Casts are predicted on your screen and decided by the server, and others see and hear them
    where you're drawn. Her Blade Storm is in the kit but not playable yet -
    [research and design](docs/research/17-abilities.md)
18. **Cloudburst**, Jett's smoke: C throws it at once from your eye the way you look, and puts
    your gun away for a quarter of a second. It flies at 30 m/s, and holding C curves it towards
    your crosshair. It bursts where it hits the level, or in mid-air after 2 s, into a ball of
    smoke 3.35 m in radius that lasts 2.5 s and hides what's behind it, enemy outlines included;
    from inside it, the screen is smoke. The server flies each throw on its thrower's ticks, and
    your screen flies yours the same way, so your cloud forms at once where the server's will -
    [research and design](docs/research/18-cloudburst.md)

## Running it

1. Install [Rojo](https://rojo.space) 7.x and the Rojo Studio plugin.
2. `rojo serve` in this folder, connect from Studio, press Play.
3. With no `Map` in Workspace, a measurement course with a target lane and practice dummies is
   built automatically. Look straight ahead from the spawn to face the lane; the wallbang lane is
   to the left, and the spike's two sites are 26 m behind you, with the spike waiting 4 m
   behind. In a place made from the Baseplate template, delete its `Baseplate` and
   `SpawnLocation` first.
4. The arena is built beside the course, off to its right, and the spike rounds' map off to its
   left. P puts everyone in the server in the arena: you spawn in your side's room and wait there
   for an opponent, and anyone who joins plays for the other side. P again starts the spike
   rounds, P again their shorter Swiftplay format, and P again puts everyone back on the course.
5. For a first full check, follow the [Studio test session](docs/studio-checklist.md): every
   system's Studio checks in order, with what each lab should read.

Controls: WASD, Shift walk, Ctrl crouch, Space jump, mouse 1 fire, mouse 2 zoom / scope,
R reload, 1/2/3 primary / secondary / knife (mouse 1 slashes and mouse 2 stabs), 4 the spike
while you carry it (hold 4 to plant it in a site or to defuse it), G drops the gun or the spike
in hand, F picks up the gun on the ground you're looking at, B buy menu (on the course at any time; in the arena
during the buy phase and while waiting for an opponent), Tab held the scoreboard (the spike
rounds), C Cloudburst (held, it curves the throw), Q Updraft and E Tailwind (E readies the gust,
and E again within its window dashes; X, Blade Storm, isn't playable yet). The spike rounds
charge credits; the course and the arena are free. On the course a spent charge comes back 1.5 s
after it's done, and in the arena every life starts with every charge.
O settings: sensitivity, scoped multiplier, mouse DPI (only for the cm/360 it shows) and a
crosshair code (Enter takes a box's value; DEFAULT puts back the reference's own crosshair).
Look: V turns it off and on again (lighting, vignette and outlines), to compare with the place's
own lighting; N cycles the enemy outline colour.
Arena: P moves on through the arena, the spike rounds, Swiftplay and off (Studio or place owner
only). In either, the buy menu and the debug keys 5-9 (below) work for anyone during the buy
phase, and while waiting for an opponent; the debug keys stay free in the spike rounds. A new
match in the arena puts everyone back on its starting kit (Vandal, Classic, knife, Heavy Armor);
in the spike rounds, each half and each death leaves you the Classic and the knife, with no
shield, and 800 credits at each half.
Debug: F2 weapon lab, then spray lab, hit reg lab and sound lab on further presses, F3 HUD (with the next
shot's cone round the crosshair, how far the crosshair's lines have spread and the last jump
measured; G with the HUD on and the knife in hand shows the server ghost), F4 counter-strafe lab (Z zeroes its cm/360 counter, Backspace clears its stops), F6 record
CSV, F10 hitbox overlay, Backspace clear impact marks, counters and the spray plot, 5-9 give
Vandal / Phantom / Operator / Sheriff / Classic (Studio or place owner only). F7 and F8 are left
alone because Studio takes them for Start and Run.
In the hit reg lab: `[` / `]` simulated latency, J jitter, L packet loss, U Network Buffering,
K rewind cap 140 / 200 / 0 ms (0 is no lag compensation); its motion line measures how evenly the
player or dummy nearest the crosshair moves.
In the sound lab: `[` / `]` footstep radius (this client only), Y practice dummies' footsteps
(off by default), H the rings sounds draw on the floor, Backspace clears its log.
Scripted playtests (Studio only): a tool that can press keys but can't move the mouse aims by
setting attributes on the local player, `VFTestYaw` / `VFTestPitch`, `VFTestAimPoint` or
`VFTestAimEntity` with `VFTestAimRegion` ([TestAim](src/client/Debug/TestAim.luau)).
`VFTestButtons` holds input flags on top of the real ones (128 fire or slash, 256 right click or
stab, 512 reload, 1024 the spike's 4 held, 2048 G, and the ability keys: 4096 C, 8192 Q, 16384 E
and 32768 X), `VFTestGive` set to a weapon id gives that
weapon as 5-9 would (`spike` hands over the course's spike), `VFTestBuy` set
to an id buys it as the menu would (`-` and the id sells it back), `VFTestMenu` set to true or
false opens or closes the menu, `VFTestSlot` set to 1, 2, 3 or 4 draws that slot,
`VFTestSettingsMenu` set to true or false opens or closes the settings menu, `VFTestSetting`
set to `key=value` (`sensitivity=0.8`, `scoped=0.5`, `dpi=1600` or `crosshair=0;P;c;5`) enters
that setting as its box in the menu would, `VFTestTake` set to true presses F, and `VFTestBoard`
set to true or false holds the scoreboard open as Tab does or lets it go. Each of the last eight
clears itself.
`VFTestMute` on the local player silences the game's sound while the sound lab's meters still
read. From the server, Workspace's `VFArenaMode` (`skirmish` or `spike`), `VFMatchFormat`
(`standard`, `competitive` or `swiftplay`) and `VFArenaOn` choose what's played, and `VFMatchSkip`
set true ends the spike rounds' phase under way (a buy phase, a round or the wait for the next).
In the spike rounds each player's credits are their `VFCredits` attribute, and each side's losses
in a row `Streak1` and `Streak2` on the arena's model. Every gun on the ground is a part in
Workspace's `VFGroundGuns`, with its `Weapon`, `Ammo` and `Reserve` as attributes. Each player's
record is in their attributes too: `VFKills`, `VFDeaths`, `VFAssists`, `VFScore`, `VFRounds` and
`VFStartCredits` in the spike rounds, and `VFAlive` and `VFLoadout` in either. Each player's ability kit is
their `VFKit` attribute, as `C0/2 Q1/1 E1/1 X0/8` (charges and most, then the ultimate's points),
with what's under way after it, and `VFTestBuy` set to `updraft` buys a charge. Where a player's
last Cloudburst burst is their `VFLastCloud` attribute (metres), and `Workspace.VFClouds` holds
each throw in the air and each cloud as parts.

## Tests

The shared simulation (movement, weapons and every gun's way of firing, the knife's swings and
what they catch, the spike's plant, defuse and drop, spread and recoil, hitboxes, wire formats,
pose history, render clock, move pacing, lag compensation and wall penetration), the look's maths,
the arena's rules and map, the sound's rules (footsteps, landings, distance curves, walls in the
way, reload parts), the settings (crosshair codes and the pixels they draw, sensitivity and
cm/360), the spike's rules (sites, the defuse's reach, its beeps and its blast), the spike
rounds' rules and map, the economy (what each round pays, kills, the plant, the cap, what a
purchase costs and the shield a survivor keeps), guns on the ground (G's drop, what the dead
drop, walking over one and the one in view), the match's record (the combat score, kills,
deaths, assists and the average) and the ability kit (charges through rounds, halves, kills and
deaths, buying them, Updraft's height and Tailwind's dash, and the kit on the wire) and Cloudburst
(the throw, its flight, its curve and what stops it, and the cloud's life) are pure Luau and run
outside Roblox:

```
luau tests/run.luau
```

It prints metrics reports (start, stop and counter-strafe timings per weapon; air drift, air stops
and how far air strafing bends a jump; fire rate, magazine and time-to-kill per weapon; cone and
recoil by bullet, and tapping recovery, per weapon; client and server agreement on a strafing
target through a simulated network; how evenly other players and dummies are drawn, paced and
not; damage left through walls by class, material and thickness; the vignette across the screen
and the outline's tint by distance; the arena's size and how much of it each spawn can see; the
footstep curve, steps per second by weapon, and the filters for walls and distance; cm/360 at
the default sensitivity, unzoomed and scoped; how long each side takes to reach Outpost's sites)
and runs the test suites. CI also type-checks everything with `luau-lsp` and Roblox definitions.

## Rules for this project

- No game memory access, no anti-cheat circumvention, no extracted assets.
- Every gameplay number carries a status: confirmed, community, measured (ours, from a public
  source) or estimate, with its source.
- Gameplay is server-authoritative; clients predict.
