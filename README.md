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
    point for each kill, death, plant and defuse. Jett's kit came first: Updraft throws you
    straight up about 4 m, and Tailwind readies a gust that, after a second's windup, dashes you
    about 7 m the way you're moving, and comes back with two kills. Casts are predicted on your
    screen and decided by the server, and others see and hear them where you're drawn -
    [research and design](docs/research/17-abilities.md)
18. **Cloudburst**, Jett's smoke: C throws it at once from your eye the way you look, and puts
    your gun away for a quarter of a second. It flies at 30 m/s, and holding C curves it towards
    your crosshair. It bursts where it hits the level, or in mid-air after 2 s, into a ball of
    smoke 3.35 m in radius that lasts 2.5 s and hides what's behind it, enemy outlines included;
    from inside it, the screen is smoke. The server flies each throw on its thrower's ticks, and
    your screen flies yours the same way, so your cloud forms at once where the server's will -
    [research and design](docs/research/18-cloudburst.md)
19. **Blade Storm**, Jett's ultimate: X, once its 8 points are full, puts five throwing knives in
    your hand after a second's windup. Mouse 1 throws one, exactly where the crosshair is,
    standing, running or in the air, for 50 to the body and 150 to the head, and a kill with one
    brings all five back. Mouse 2 throws all that are left at once, in a spread, and its kills
    bring none back. Once they're all thrown, your gun comes back. A number key draws a gun and
    keeps the knives for later, X draws them again, and the other abilities work with them out.
    The knives are a weapon of their own in a fifth slot, so the server decides each throw as it
    does a shot, with lag compensation - [research and design](docs/research/19-blade-storm.md)
20. **Drift**, Jett's passive: with Space held while you fall, you glide, falling no faster than
    2 m/s, so a held jump comes down slowly and the top of Updraft keeps you in the air about 3 s.
    The rise, a dash and your speed along the ground are left alone, and you can shoot and cast as
    in any fall. Others hear a soft run of gusts and see rings of air left behind you as you sink -
    [research and design](docs/research/20-drift.md)
21. **Matches that never stop**: a live server plays from the moment it starts, Skirmish for now,
    so whoever joins drops into a match under way. They go on the side with fewer players: in a
    buy phase they spawn at once, and later they watch a teammate until the next round, switching
    with the mouse buttons. Past two a side (five in the spike rounds) they wait in line for a
    place, and the sides are evened out before each round. Skirmish keeps the same record as the
    spike rounds, and each match ends on a 10-second victory screen with everyone's kills, deaths,
    assists and combat score and the MVPs, before the next starts on the same server -
    [research and design](docs/research/21-drop-in.md)
22. **The map vote**: Skirmish B and C, built beside A from Riot's minimaps, so Skirmish has the
    reference's three maps, sharing one hall. A server's first match is on one of them at random,
    and after each victory screen everyone votes for the next for 15 s, clicking one of three map
    cards that each show the map's plan. The most votes wins, a tie or no votes at all is settled
    at random, and the next match starts on it - [research and design](docs/research/22-map-vote.md)
23. **Gun game**: Counter-Strike's Arms Race played in the arena with the reference's guns, on
    Skirmish's three maps and with the same vote between matches. Each player climbs a ladder of
    12 guns, one kill a level, from the Vandal or the Phantom to the knife, with a gun of each kind
    picked at random for each match. A kill on the knife's level wins the match for the killer's
    side, or after 10 minutes whoever is furthest up, and a knife kill also knocks the one killed
    down a level. The dead are back in 1.5 s and can't be hurt for 5 s or until they fire. Up to
    four a side, with no buying, no abilities and no guns on the ground -
    [research and design](docs/research/23-gun-game.md)
24. **The Play menu**: as Counter Blox's main screen, a live server opens on a menu of the modes,
    Skirmish (2v2), gun game (4v4) and the spike rounds as Unrated, Competitive and Swiftplay
    (5v5), each with how many play it. Each server plays one mode: a public server Skirmish, and
    PLAY for its mode drops you into its match under way. PLAY for another mode, or for this one
    once its match is full, teleports you to the fullest server playing it with a place free, or
    to a new one. Every server keeps a line in a memory store that every server reads, for where
    to send players and the menu's counts. M opens the menu again during a match. In Studio, which
    can't teleport, PLAY for another mode switches the server to it -
    [research and design](docs/research/24-play-menu.md)
25. **The spike rounds' maps**: Quarry and Foundry, two maps of our own for five a side beside
    Outpost, laid out as the reference's traditional maps are, with two sites and three lanes. A
    server's first spike match is on one of the three at random, and after each victory screen
    everyone votes for the next, as in Skirmish. The tests check every map the same way: every
    room reached, no sightline from one spawn into the other, barriers that hold each side in, and
    the defenders at each site first - [research and design](docs/research/25-spike-maps.md)
26. **Deathmatch**: the reference's FFA Deathmatch on the spike rounds' three maps, a sixth mode on
    the Play menu. Up to 14 play, each for themselves, and the first to 40 kills wins, or whoever
    has the most after 9 minutes. The dead are back in 1.5 s wherever no enemy sees them or is
    near, close to the fight and away from where they fell, facing open floor. Every death leaves
    a health pack for 10 s that heals in full and reloads, and every kill reloads the killer's
    gun. Every gun is free at any time, every life wears Heavy Armor, and there are no abilities,
    so no glide. The victory screen shows everyone in their places, then the vote for the next
    map - [research and design](docs/research/26-deathmatch.md)
27. **Team Deathmatch**: the reference's 5v5 Team Deathmatch on the spike rounds' three maps, a
    seventh mode on the Play menu. The first side to 100 kills wins, or the side with more after
    9 minutes 30 seconds, in four stages; a tie is a draw. B picks a loadout for each stage, a gun
    and its shield, before the match or in your spawn room, and each new stage hands its loadout
    over a moment in. The dead are back in 1.5 s in their side's spawn room, can't be hurt for 15 s
    or until they fire or leave it, and the room burns anyone who stays after that, as the other
    side's does at once. Then the victory screen, `DRAW` for a tie, and the vote for the next map -
    [research and design](docs/research/27-team-deathmatch.md)
28. **Team Deathmatch's pickups**: four weapon spawners on each map, each with a gun of the stage's
    at random and limited rounds, lent in place of your loadout's until it's spent or G destroys
    it; two Recovery Orbs, which mend health and shield over 6 s, leave a zone that mends allies
    who walk in, and come back after 30 s; and two Ultimate Orbs, up together every so often, worth
    10 points each. Abilities recharge over time, each at its own rate and kept through a death,
    and Blade Storm needs 60 points, 3 a kill. The tests hold every pickup out on the floor and
    about as quick a run from either side's spawn -
    [research and design](docs/research/28-tdm-pickups.md)
29. **Agent select**: each player plays their own agent in Skirmish, the spike rounds and Team
    Deathmatch. Once a match you have 10 s to pick one, from the match's start or from when you
    join it under way: T opens the agent select screen, with a card for each agent, the kit of the
    one selected, what your teammates have selected and LOCK IN, and when the time's up the agent
    selected is locked in for the rest of the match. On the course and while a mode waits for
    players, an agent picked is yours at once, as in the reference's Range. An agent locked in goes
    on your kit at once where nothing's lost by it (a buy phase, the pre-game, your own spawn room,
    or while you're down), or else with your next life, and in the spike rounds what you'd bought
    into the last agent's kit this buy phase is sold back. Jett and Phoenix (system 30) are the
    agents to pick from - [research and design](docs/research/29-agent-select.md)
30. **Curveball**, Phoenix's flash: Phoenix joins Jett in agent select with his whole kit on the
    bar, and Curveball, his signature, is the first of it played. E readies a flare in 0.8 s;
    mouse 1 throws it curving round to the left and mouse 2 to the right, and your gun is back
    0.48 s later. It flies straight for a moment, turns a quarter round, stops against a wall, and
    pops 0.6 s after the throw, blinding everyone who can see it, you and your side too: the
    screen goes white for up to 1.5 s, longest looking straight at it from close by and briefly
    turned away, then clears over a second. The server decides who's blinded and for how long,
    and others see a glow on a blinded player's face. It holds two charges at 250 credits, with
    one free every round and one back for two kills -
    [research and design](docs/research/30-curveball.md)
31. **Hot Hands**, Phoenix's fire: Q readies a fireball in 0.8 s; mouse 1 throws it and mouse 2
    lobs it underhand, and your gun is back 0.7 s later. It falls gently as it flies, comes back off
    walls and ceilings, and bursts on the first floor it meets, dropping straight down if it's
    still in the air 1.5 s after the throw. Its fire spreads over the floor to 9 m across, no
    further than the walls round it let it, and burns for 4 s: 60 a second to enemies standing in
    it, however they jump, and a third of that to allies, credited to the thrower for the kill.
    Phoenix heals in his own fire instead, which is his passive, Inner Fire: 50 health over 4 s
    from his first touch of each fire, going on if he leaves it. Since Patch 9.10 it's one charge
    at 200 credits, with none free - [research and design](docs/research/31-hot-hands.md)
32. **Blaze**, Phoenix's wall of fire: C readies a flame in 0.8 s; mouse 1 sends a line of fire out
    along the floor from your feet, 21 m in 0.75 s, up steps and boxes and through walls, and while
    it's held the line bends towards your crosshair, at up to 180 degrees a second; your gun is back
    0.5 s after you let go, or once its run's over. Where it ends, a wall of fire 4 m tall rises
    from your end and spreads to the far end in half a second, and stands for 8 s: nobody sees
    through it, enemies standing in it burn 30 a second and allies a third of that, and Phoenix
    heals in it instead, 50 over 8 s (Inner Fire). One charge at 150 credits, with none free -
    [research and design](docs/research/32-blaze.md)
33. **Run it Back**, Phoenix's ultimate: X, once its 7 points are full, marks where you stand, and
    for the next 10 s a hit that would kill you doesn't. Your body goes instead, and 1 s later you
    rise at the mark, held there 1.4 s more, facing the way you did as you cast it, with full
    health, the shield you had then and your guns reloaded. If nothing kills you, its 10 s running
    out brings you back the same way. While your body's gone nothing hurts you and shots go through,
    and a hit it spared counts for nobody - [research and design](docs/research/33-run-it-back.md)
34. **The minimap**, at the top left: the map from above, drawn from the level's own plan, with you,
    your side and the way each of you looks, the enemies your side sees, the spike, the clouds,
    walls of fire and fires that are out, and a white circle as far as the sounds you make are
    heard. The server works out who each side sees twenty times a second, through the level, the
    clouds and the walls of fire, and nobody blinded white sees anyone; an enemy it stops seeing
    leaves a faded mark where they were for 3 s. Caps Lock held opens the big map, with the
    places' names, and the settings menu has the reference's map settings -
    [research and design](docs/research/34-minimap.md)
35. **The fog of war**: each player's snapshots carry only the enemies they could see by the next
    look, hear, or their side spots, and for half a second after, so a client that read them
    couldn't see anyone through a wall. Twenty times a second the server looks from each player's
    eye, and where it's moving to by the time their screen shows it, to seven points of each
    enemy's body and where it's moving to, through the level but not the clouds or walls of fire.
    Running steps, jumps, reloads, the spike's plant and defuse and glides are heard as far as
    their sounds go; gunshots, swings and casts go only to those who'd hear them or have whoever
    made them, and a shot's verdict lists only the targets its shooter has. The dead have what
    their side in play has, and enemies' labels no longer show through walls -
    [research and design](docs/research/35-fog-of-war.md)
36. **Sage's Healing Orb**: Sage joins Jett and Phoenix in agent select, a Sentinel with her whole
    kit on the bar, and her Healing Orb is the first of it played. E puts the orb in hand, ready in
    0.5 s. With the crosshair over a hurt ally in sight, a click of mouse 1 heals them, and mouse 2
    heals you if you're hurt: 100 health over 5 s, 20 a second up to the most, no shield, stopping
    for a second each time they're hurt. The server decides whom a click heals, from what your
    screen showed as you clicked; a click that heals nobody leaves the orb in hand. A heal spends
    its one charge, free each round, and puts the gun back 0.7 s later; the charge comes back 45 s
    after, 22 s in Team Deathmatch. With the orb in hand, the ally it would heal is marked in green
    with a + over their head, and whoever's healed glows green -
    [research and design](docs/research/36-healing-orb.md)
37. **Sage's Slow Orb**: Q puts Sage's Slow Orb in hand, ready in 0.5 s, and mouse 1 throws it.
    It flies fast and far, off walls, and bursts where it lands into a field of ice 5.6 m round
    that lasts 7 s. Everyone in it, enemies, allies and Sage alike, is held to half their speed at
    once, on the ground and in the air (2.7 m/s with a rifle), jumps 30% lower and dashes half as
    far, and crunches running or jumping through it, though walking is silent. Your own game
    slows you just as the server does, both judging the field at the moment your screen showed,
    so going in and out of it doesn't snap you back. Two charges at 200 credits, and the gun's
    back 0.4 s after a throw -
    [research and design](docs/research/37-slow-orb.md)
38. **Sage's Barrier Orb**: C puts Sage's Barrier Orb in hand, ready in 0.8 s, with a targeter
    on the floor where the crosshair meets it, up to 15 m away, and mouse 1 raises its wall there:
    four segments of ice in a row, 10.4 m long and 2.5 m tall, rising out of the floor over 1.35 s
    and standing for 40 s. Nobody walks, shoots or sees through it, and whoever stands where it
    rises is lifted onto its top, by your own game just as by the server's. C again turns the
    targeter a quarter, and mouse 2 held keeps it facing the same way as you turn. Each segment
    forms at 400 health and fortifies to 600 after 2 s, less what it's lost; enemies' bullets and
    knives break it, one over the planted spike breaks at once, and in its last 5 s it wears away.
    One charge at 300 credits, none raised in the buy phase, and the gun's back 0.7 s after -
    [research and design](docs/research/38-barrier-orb.md)
39. **Sage's Resurrection**: with its 7 points full, X puts Sage's Resurrection in hand, ready in
    0.8 s, and mouse 1 with the crosshair over a fallen ally's body, up to 12 m away, brings them
    back where they lie. Everyone who's killed leaves a body on the floor, over a disc glowing in
    their side's colour, and the one your try would bring back is marked in green. Their body rises
    in a shell of crystal for 2 s, out of harm's way, and they burst out at its top with full health
    and no shield, breaking any wall of ice they're in, then fall to the floor for 1.3 s, held and
    in harm's way, before they've control back. The kill feed shows it. In Skirmish and the spike
    rounds it brings back allies; on the course, practice dummies, which stay down while it's in
    hand. The gun's back 1 s after the cast -
    [research and design](docs/research/39-resurrection.md)
40. **Omen's Dark Cover**: Omen joins Jett, Phoenix and Sage in agent select, a Controller with his
    whole kit on the bar, and his Dark Cover is the first of it played. E puts his shadow orb in
    hand, ready in 0.6 s, with a small violet mark along the crosshair where it meets the level,
    15 m out at most, and a faint ball on the floor under it where the smoke would be, both seen
    through walls. Mouse 1 held sends the mark further, up to 80 m, and mouse 2 held brings it
    closer, down to 2 m; with no floor under it the mark turns red. E again sends the orb there,
    unseen and through walls at 64 m/s, and it bursts into a dome of dark smoke 4.1 m round on the
    floor under the mark, growing over 1 s. A mark inside a wall is brought back out of it, and over
    a floor too steep to stand on the smoke falls through to one it can. Nobody's spotted through it
    on the minimap, nor healed or brought back through it, and from inside it the screen is dark. It
    stands 15 s, flickers with a low tone for its last 1.5 s and goes at once, and only Omen's side
    hears the orb sent. Two charges, one free each round and the second 150 credits; a spent one
    comes back 40 s after, but never one that wasn't bought (65 s in Team Deathmatch), and the gun's
    back 0.7 s after a send -
    [research and design](docs/research/40-dark-cover.md)
41. **Omen's Paranoia**: Q puts Omen's other shadow orb in hand, ready in 1.1 s, and mouse 1 sends
    it straight along the crosshair, a see-through ball of shadow 8.6 m across: it appears 4.5 m
    ahead and flies 25 m at 20 m/s, through walls and anyone in its way. Everyone it comes within
    4.3 m of, his own side and Omen too, is nearsighted for 2 s: past 7.5 m they see nothing but
    darkness, what they hear is muffled and quieter, their minimap is covered and tells them of
    nobody, and a flash popping further away doesn't blind them; then it clears over half a second.
    Whoever stands in its path as it's sent sees shadow at their screen's edges, and others see a
    wisp of shadow round a nearsighted player's head. One charge at 250 credits (in Team Deathmatch
    it comes back 73 s after it's spent), and the gun's back 0.7 s after a send -
    [research and design](docs/research/41-paranoia.md)
42. **Omen's Shrouded Step**: C puts Omen's step in hand, ready in 0.5 s, with a violet ring on the
    floor where it would take him and a faint shadow of him standing in it, both seen through walls,
    and the ring on the minimap too: along the crosshair, 15 m out at most, and where the aim meets
    a wall or nothing, on the floor below where it ends, clear of the wall. He must have room to
    stand there and be in sight there, and it never puts him more than 1 m over his eye; with
    nowhere to go the ring turns red. Mouse 1 starts a 0.7 s windup, through which he can't move,
    fire or cast, shadow closing in on his screen and swirling round him for others. Then he's gone,
    out of play, his screen dark, a puff of shadow where he was and a column of shadow where he's
    going, and half a second later he's there, heard within 12.5 m, his gun back 0.7 s after. Two
    charges at 100 credits, none free (in Team Deathmatch one comes back 33 s after it's spent) -
    [research and design](docs/research/42-shrouded-step.md)
43. **Omen's From the Shadows**: once its seven points are full, X puts Omen's map in hand, ready
    in 0.5 s: the big map of wherever he plays, the course's drawn from its parts, with a cursor on
    it that the mouse moves instead of the view, violet where he'd stand and red where he wouldn't.
    Mouse 1 starts a 1.5 s windup, heard by everyone, through which he's rooted, though he can look
    round; then he's a Shade there for 2.5 s, rooted again, his world nearly grey and dark past a
    few metres that grow as his time runs out, and others see him dark and see-through. Then he
    forms there, his gun drawn again. X while he's a Shade, or an enemy's hit on it, sends him back
    to where he cast it, unhurt, the points spent all the same. Its arrival is heard within 22.5 m,
    and an enemy's minimap goes dark until it's over -
    [research and design](docs/research/43-from-the-shadows.md)
44. **Sova's Recon Bolt**: Sova, an Initiator, is the fifth agent, and his Recon Bolt the first of
    his kit played. E puts his bow in hand, ready in 0.8 s. Mouse 1 held draws the bolt, a bar under
    the crosshair filling each third of a second, three at the most, and mouse 2 adds a bounce, two
    at the most and then none again; E lets a draw go. Mouse 1 let go looses it, at 18 m/s with no
    bar up to 41.25 m/s with three, falling less the further it's drawn: level from the eye, a tap
    sticks in the floor 18.6 m ahead and a full draw 60 m. It goes off whatever it meets while it
    has bounces left, as off a mirror, and sticks to the next thing it meets. 0.667 s later it
    pulses, and again 1.6 s after: each pulse reveals every enemy within 30 m that it has in sight,
    their silhouettes lit through walls for his side for 0.75 s, and on its minimap. An enemy's
    bullet or knife takes its 20 health, and his side's do nothing. One charge, free each round and
    back 50 s after it's loosed (48 s in Team Deathmatch), and the gun's back 0.7 s after a loose -
    [research and design](docs/research/44-recon-bolt.md)
45. **Sova's Shock Bolt**: Q puts Sova's bow in hand with a shock bolt, ready in 0.8 s, and it's
    drawn, given bounces and loosed as the Recon Bolt is, and flies the same way. With no bounces
    left, where it lands it bursts: everyone it has in sight within 5 m takes 75 within 1 m of it,
    less further out, down to 1 at 5 m, through their shield, its owner and his side as much as his
    enemies; the level and walls of ice shelter them. Two charges at 150 credits (in Team
    Deathmatch one comes back 26 s after it's spent), and the gun's back 0.7 s after a loose -
    [research and design](docs/research/45-shock-bolt.md)
46. **Sova's Hunter's Fury**: once its 8 points are full, X puts Sova's bow in hand with three
    energy blasts, drawn in 0.5 s, and its 6 s run from then. Mouse 1 charges a blast: through its
    1 s windup he's rooted where he stands, his view turning slowly, and then it goes from his eye
    along the crosshair, 66 m, through walls and everything else, and knocks him 1.5 m back. Every
    enemy within 2 m of its line, ahead of him, takes 80 however far away, through their shield,
    and is revealed to his side for 1 s, through walls and on its minimap. A blast at the most
    every 2.125 s; it's over once its time's up or anything else is drawn, a blast charging going
    with it, and it catches nobody while the spawns' barriers are up. His minimap shows where a
    blast would go; in Team Deathmatch it takes 70 points -
    [research and design](docs/research/46-hunters-fury.md)
47. **Sova's Owl Drone**: C puts Sova's drone in hand, ready in 0.9 s, and mouse 1 sends it out from
    his eye. His view is the drone's for its 7 s, or until C again, while his body stands where he
    left it, and his gun's back 0.7 s after. For its first 0.25 s it flies on as it was sent, and
    then the moving keys fly it along the ground at 5 m/s the way the view faces, and jump and
    crouch up and down at 3 m/s, never more than 3 m over the floor below it. Mouse 1 from it shoots
    a dart along the crosshair, 40 m at the most, one every 5 s: an enemy it strikes is pinged 1.6 s
    after and 1.2 s after that, each ping revealing them to his side for 0.6 s, through walls and on
    its minimap, and `[Target Hit]` shows for 2 s. Its 100 health is taken by enemies' bullets and
    knives, and enemies see and hear it only within 15 m or in their sight. One charge at 400
    credits (in Team Deathmatch back 51 s after it's spent); with it, all of Sova's kit is played -
    [research and design](docs/research/47-owl-drone.md)
48. **One of each agent on a side**: with five agents, everyone on a side of five can play one of
    their own, as in the reference, where each player on a team picks a different agent. An agent a
    teammate has locked in this match is taken: its card in agent select is dimmed and reads TAKEN,
    it can't be selected or locked in, and a selection it's taken from moves back to the agent you
    play, or else to the first that's free, so the time running out never locks in a taken one. The
    first to lock an agent in has it, and of windows closing at once on one agent the first player
    on the server keeps it; the other side can play it too. Someone moved across to even the sides
    has a window for their new side, and someone back in a match to find their agent taken has
    another - [research and design](docs/research/48-one-of-each.md)
49. **Ultimate Orbs in the spike rounds**: two on each map, one in each site's main, both up as each
    round starts. Hold F on the ground at one for 2 s to take it, rooted with the gun away as in a
    defuse, for a point of your ultimate; let go, or have someone else take it first, and you get
    nothing. Taken, it's gone until the next round. A gold bar shows the taking, a prompt asks for F
    within reach of one, enemies hear its whoosh as far as a plant, a chime marks it yours, and the
    minimap shows the orbs up as gold dots. F defuses the spike too -
    [research and design](docs/research/49-ultimate-orbs.md)
50. **The ultimate's points across a match**: in the spike rounds the half wipes everyone's ultimate
    points (Swiftplay starts each half on 2), each overtime round puts everyone 3 short of full
    whatever they had, and a death's point comes as the next round starts. Only a death at an
    enemy's hands earns one, not the spike's blast, a teammate's ability or your own -
    [research and design](docs/research/50-ultimate-points.md)
51. **Agents and ultimates at a glance**: the tiles either side of the top bar's score show each
    player's agent by the first two letters of its name, with your side's health under them and a
    gold diamond under anyone's whose ultimate is ready, an enemy's too. The scoreboard has each
    player's agent in a box before their name and their ultimate under ULT, how far along it is
    (`3/8`) or READY, for both sides - [research and design](docs/research/51-at-a-glance.md)
52. **Pings**: tap Z to ping what the crosshair's on for your side: an enemy in sight, the spike, a
    gun on the ground, or the place itself, which a smoke or a cloud stops at its edge. Hold Z for a
    wheel of four calls, Danger, Watching, Pushing and Need support, and move the mouse towards one,
    then let go to ping it, or right click to put it away. With the big map up (Caps Lock) the mouse
    moves a cursor across it, and a left click pings that place on the maps alone, dead or alive.
    Each ping is a marker with its word and how far away it is, faded under the crosshair and gone
    after 4 s, and a mark on the minimap and the big map, with a beep, or a ding for the map's; four
    come in quick succession, then one more each 1.5 s -
    [research and design](docs/research/52-pings.md)
53. **The combat report**: as you die, yours comes up on the right: who killed you and with what,
    then a row for everyone you fought, whoever killed you first, with KILLED or KILLED YOU, the
    damage you dealt them and took from them, and beside each a figure lit where the bullets and
    blades struck, head, body and legs, with how many. N hides it and shows it again, and mouse 3
    opens its details, each weapon's and ability's damage and hits. In the arena and the spike
    rounds it covers the round, and shows again through the next buy phase; anywhere else it covers
    a life, and goes as you come back. On the course N shows yours at any time. The enemy outline
    colour moved from N to I - [research and design](docs/research/53-combat-report.md)
54. **Damage and danger indicators**: a hit you take shows a red arc round the crosshair on the side
    it came from, whole for a second and then fading, and it goes on pointing at that place as you
    turn and move; a hit on the Owl Drone you fly shows the same way, and only the one hit sees it.
    A fire or a wall of fire that isn't yours shows a pulsing yellow chevron on its side once it's
    within 3 m of reaching you, and a red diamond under the crosshair once it does. The health reads
    red at 30 or under, and a gun's magazine count at a quarter of its magazine or under -
    [research and design](docs/research/54-damage-indicators.md)
55. **The kill banner**: each kill of an enemy brings up a banner low in the middle of the screen
    with the kill's number in it and a mark for each kill up to the fifth, gold from the fifth on, a
    little red X beside it for a headshot and the name of whoever was killed under it, with the kill
    sound, higher with each kill. In the arena and the spike rounds it counts the round's kills, and
    anywhere else a life's. Only the killer sees it, and an ability's kills have it too -
    [research and design](docs/research/55-kill-banner.md)
56. **Round-end callouts**: a round of the arena or the spike rounds won in a way worth naming has
    its name on the banner in place of ROUND WON: ACE when one of the winners killed every enemy,
    TEAM ACE when each of them killed one, FLAWLESS when none of them died, which the losers see
    too, CLUTCH when they were down to their last against two or more, and in the spike rounds
    THRIFTY when their loadouts were worth 2500 credits less on average. A round gets the first that
    holds, in that order; an ace needs two or more enemies, and a team ace or a flawless two or more
    winners - [research and design](docs/research/56-round-callouts.md)
57. **Buying for teammates**: in the spike rounds, a right click on a gun you don't have in the buy
    menu asks your team for it. A team panel left of the menu has a card for each of your side, with
    their credits, gun and shield, their plan (saving, buying or extra credits, from the panel's
    buttons) and the gun they're asking for, with BUY to buy it for them, and the ping's blip plays
    for a request. The buyer pays, and the gun's the teammate's as if they'd bought it; selling it
    back, or buying another gun over it, gives the buyer their credits back -
    [research and design](docs/research/57-team-buying.md)
58. **Wharf**: a fourth spike map, for five a side, and the first dressed one: a harbour, with a
    warehouse yard at A, a garden plaza in mid and a container yard at B under a gantry crane. Its
    cover is a kit of placeholder props (crates, crate stacks, containers, barrels, planters, hedges
    and trees). A Model named after a piece, in a Folder named `VFMapKit` in ServerStorage, is
    fitted over every piece of that name, while the piece's box still decides where anyone can go,
    see or shoot - [research and design](docs/research/58-wharf.md)
59. **Heights**: the spike maps can have rooms raised off the ground, decks over a room's floor,
    stairs and ramps from one floor to another, railings and windows, and Wharf is rebuilt with them
    to measurements of Counter-Strike's maps: a heaven over A's site with hell under it, a window
    room looking down mid, a platform across the back of B, a long lane to B, and a room by B with a
    door and a window to vault through. The offline tests walk it in three dimensions, timing each
    side's runs to each site and checking what its raised places see -
    [research and design](docs/research/59-wharf-heights.md)
60. **Bots**: a match fills up with bots while anyone plays it, up to ten in the spike rounds and
    Team Deathmatch, eight in gun game and deathmatch and four in Skirmish, and a player joining
    takes a bot's place. They play as people do, inside people's limits: they see only what's in
    front of them, notice an enemy after a person's reaction time, turn onto them as a hand does,
    stop to shoot, tap, burst or spray by range, and miss as people do. They check corners, watch
    where they lost sight of an enemy, go to a site together, hold every way in and come over when
    attackers show at the other, and follow a player on their side, finding their way round walls
    and up stairs and getting out of anywhere they stick. There are four skills; the default,
    Normal, loses to a player who checks their corners -
    [research and design](docs/research/60-bots.md)
61. **Bots and the spike**: bots play for the spike in the spike rounds. Attackers pick it up, carry
    it with their plan and plant it on the site they chose, out of sight of the defenders' ways back
    in, then watch it from cover, and each gets out of the blast in time. Defenders gather at the
    ways back in, push in together, and one defuses it while the rest cover them, or they all get
    out of the blast when it's too late. Players come first: the bots leave a spike on the ground to
    a player on their side for 5 s, a player carrying it plants it where they choose, and a player
    defusing it is left to it - [research and design](docs/research/61-bots-and-the-spike.md)
62. **Taking over a bot**: in Skirmish and the spike rounds, but not in Competitive, a player who's
    died can play on as a bot of their side for the rest of the round, as Counter-Strike lets the
    dead: watching it, F starts their new life in its body, where it stands and looking where it
    looked, with its guns and their rounds, its health and shield, and the spike if it carries it.
    The bot's out of the round with no death, and plays again from the next; what the player does in
    its body counts for them, and they keep its guns if they live -
    [research and design](docs/research/62-taking-over-bots.md)
63. **Agent bodies**: other players and bots are drawn as an agent's body, a rigged model in
    ReplicatedStorage's `VFBodies` (for now the kit body Superhero_Male_A), 1.75 m tall and posed
    every frame from their snapshots by procedural animation: its legs step with the speed and keep
    a planted foot still, its hips turn toward the way it moves while its chest faces its aim, it
    crouches, jumps, lands and glides, and it holds each kind of weapon as that kind is held,
    reloads, switches, plants and defuses. What can be hit doesn't change: the body is posed round
    the hitboxes, its head kept in the head box -
    [research and design](docs/research/63-agent-bodies.md)
64. **The 1v1**: Duel on the Play menu, Skirmish's rounds one a side, first to 10, on a map built
    by hand in the place, Workspace's `1v1Map` with spawn rooms `Spawn1` and `Spawn2`: the spawn
    spots, each room's door and its barrier, the bots' way round and the minimap are all read from
    its parts, so it can be rebuilt in Studio with no change in code. A bot plays whoever's alone,
    and there's no map vote - [research and design](docs/research/64-duel.md)
65. **Bots' agents**: each bot plays an agent, picked in the agent select window as a player picks,
    one nobody on its side has and never what a player has selected, and the top bar and the
    scoreboard show it with its ultimate. Its kit is a player's, kept from one life to the next, and
    every ability treats a bot as a player: a flash blinds it, Paranoia nearsights it, a Healing Orb
    heals an allied bot, and a Recon Bolt or Hunter's Fury leaves bots on its own side be -
    [research and design](docs/research/65-bots-agents.md)
66. **Bots' abilities**: each bot casts its agent's abilities when a player on that agent would.
    Attackers look over a site with the Recon Bolt before they push, then smoke the spots that hold
    their way in, flash round the corner at them, and burn or shock them out; defenders look for
    the attackers early, then slow, burn, wall or smoke a way in that attackers have just shown at.
    A bot guarding the planted spike answers a defuse with Hunter's Fury, a molly or a Shock Bolt,
    and a bot on Sage heals itself and hurt teammates once it's quiet. Every throw is flown through
    the level before it's thrown, so it lands where the bot means it to and keeps off its own side,
    and bots buy their charges with what's left after their guns -
    [research and design](docs/research/66-bots-abilities.md)

## Running it

1. Install [Rojo](https://rojo.space) 7.x and the Rojo Studio plugin.
2. `rojo serve` in this folder, connect from Studio, press Play.
3. With no `Map` in Workspace, a measurement course with a target lane and practice dummies is
   built automatically. Look straight ahead from the spawn to face the lane; the wallbang lane is
   to the left, and the spike's two sites are 26 m behind you, with the spike waiting 4 m
   behind. In a place made from the Baseplate template, delete its `Baseplate` and
   `SpawnLocation` first.
4. The arena is built beside the course, off to its right, and the spike rounds' four maps off
   to its left. A live server starts the arena by itself; in Studio you start on the course, and
   P puts everyone in the server in the arena: you spawn in your side's room and wait there for an
   opponent, and whoever joins goes on the side with fewer players. After each match everyone
   votes for the next of Skirmish's three maps. P again starts gun game in the same hall, P again
   the spike rounds, on four maps of their own with the same vote, P again their shorter
   Swiftplay format, and P again puts everyone back on the course. A live server opens on the
   Play menu, and only once you press PLAY are you in a match; in Studio M opens the menu, where
   PLAY for another mode switches the server to it, as P does. Both deathmatches are only on the
   menu. PLAY's teleports between servers only work once the place is published.
5. Other players and bots are drawn as an agent's body once ReplicatedStorage has a folder
   `VFBodies` with a rigged model in it (the one named `Default`, or else the first), as Studio's 3D
   importer brings in a rig with the kit's bone names: put the imported `Superhero_Male_A` there.
   Without one they're drawn as red blocks the hitboxes' size, as they are on a client that can't
   load all of the body's meshes: other players can't load a mesh Roblox's moderation has blocked,
   and the Output (F9 in a game) names any that didn't load. Exporting a rig from Blender, turn Add
   Leaf Bones off, as Roblox asks.
6. For a first full check, follow the [Studio test session](docs/studio-checklist.md): every
   system's Studio checks in order, with what each lab should read.

Controls: WASD, Shift walk, Ctrl crouch, Space jump, mouse 1 fire, mouse 2 zoom / scope,
R reload, 1/2/3 primary / secondary / knife (mouse 1 slashes and mouse 2 stabs), 4 the spike
while you carry it (hold 4 to plant it in a site or to defuse it), G drops the gun or the spike
in hand, F picks up the gun on the ground you're looking at (held, it takes an Ultimate Orb in
the spike rounds, or defuses the spike; while you're down, it takes over the bot of your side you're
watching), B buy menu (on the course at any time; in the arena during the buy phase and while
waiting for an opponent; in deathmatch any time, guns alone; in
Team Deathmatch B is the loadout menu, before the match or in your spawn room), Tab
held the scoreboard (the arena and the spike rounds), mouse 1 and 2, while you're down in either,
the next or the last teammate to watch,
a click on a map card, during the vote after a match, your vote for the next map,
M the Play menu (a click picks a mode's card, and PLAY plays it), Caps Lock held the big map
(mouse 1 pings the place under its cursor), Z a ping for your side on what your crosshair's on
(held, the ping wheel: move the mouse towards a call and let go to ping it, or mouse 2 to put it
away),
N the combat report, shown or hidden (mouse 3 opens its details while it's up),
T agent select (a click selects an agent's card, and LOCK IN locks it in),
C Cloudburst (held, it curves the throw), Q Updraft, E Tailwind (E readies the gust,
and E again within its window dashes) and X Blade Storm (mouse 1 throws a knife and mouse 2 all
that are left; with a gun drawn, X draws the knives again). Space held in the air glides (Jett's
Drift). As Phoenix, E readies Curveball's flare: mouse 1 throws it curving left, mouse 2 curving
right, and E again puts it away; Q readies Hot Hands' fireball: mouse 1 throws it, mouse 2 lobs it,
and Q again puts it away; C readies Blaze's flame: mouse 1 sends its wall, held it bends the wall
towards your crosshair, and C again puts it away; X marks where you stand for Run it Back. As
Sage, Q readies the Slow Orb: mouse 1 throws it, and Q again puts it away; E readies the Healing
Orb: mouse 1 heals the hurt ally in your crosshair, mouse 2 heals you, and E again puts it away.
The spike rounds charge credits; the course and the arena are free.
On the course a spent charge comes back 1.5 s after it's done, and the ultimate's points are full at
every life and fill again 1.5 s after Blade Storm ends or Run it Back brings you back; in the arena
every life starts with every charge, in Team Deathmatch spent charges come back over time, a spent
Healing Orb comes back 45 s after in the arena and the spike rounds, and gun game and deathmatch
have no abilities.
O settings: sensitivity, scoped multiplier, mouse DPI (only for the cm/360 it shows), a
crosshair code (Enter takes a box's value; DEFAULT puts back the reference's own crosshair) and
the minimap's: Rotate or Fixed, the same way round or by side, kept centred, its size and zoom,
the vision cones, and when the big map names its places.
Look: V turns it off and on again (lighting, vignette and outlines), to compare with the place's
own lighting; I cycles the enemy outline colour.
Arena: P moves on through the arena, gun game, the spike rounds, Swiftplay and off (Studio or
place owner only). In the arena and the spike rounds, the buy menu and the debug keys 5-9 (below)
work for anyone during the buy phase, and while waiting for an opponent; the debug keys stay free
in the spike rounds. A new match in the arena puts everyone back on its starting kit (Vandal,
Classic, knife, Heavy Armor); in the spike rounds, each half and each death leaves you the Classic
and the knife, with no shield, and 800 credits at each half. Gun game has neither the buy menu nor
the debug keys: each life starts on your level's gun, the knife and Heavy Armor, a kill puts the
next gun in your hands at once, and G does nothing, as its guns can't be dropped.
Debug: F2 weapon lab, then spray lab, hit reg lab and sound lab on further presses, F3 HUD (on at
the start in Studio, off on a live server; with the next shot's cone round the crosshair, how far
the crosshair's lines have spread and the last jump measured; G with the HUD on and the knife in
hand shows the server ghost), F4 counter-strafe lab (Z zeroes its cm/360 counter, Backspace clears
its stops), F6 record CSV, F10 hitbox overlay, Backspace clear impact marks, counters and the spray
plot, 5-9 give Vandal / Phantom / Operator / Sheriff / Classic (Studio or place owner only). F7 and
F8 are left alone because Studio takes them for Start and Run.
In the hit reg lab: `[` / `]` simulated latency, J jitter, L packet loss, U Network Buffering,
K rewind cap 140 / 200 / 0 ms (0 is no lag compensation); its motion line measures how evenly the
player or dummy nearest the crosshair moves.
In the sound lab: `[` / `]` footstep radius (this client only), Y practice dummies' footsteps
(off by default), H the rings sounds draw on the floor, Backspace clears its log.
Scripted playtests (Studio only): a tool that can press keys but can't move the mouse aims by
setting attributes on the local player, `VFTestYaw` / `VFTestPitch`, `VFTestAimPoint` or
`VFTestAimEntity` with `VFTestAimRegion` ([TestAim](src/client/Debug/TestAim.luau)). `VFTestButtons`
holds input flags on top of the real ones (128 fire or slash, 256 right click or stab, 512 reload,
1024 4 and 65536 F held, 2048 G, and the ability keys: 4096 C, 8192 Q, 16384 E and 32768 X),
`VFTestGive` set to a weapon id gives that weapon as 5-9 would (`spike` hands over the course's
spike), `VFTestBuy` set to an id buys it as the menu would (`-` and the id sells it back),
`VFTestMenu` set to true or false opens or closes the menu, `VFTestSlot` set to 1, 2, 3, 4 or 5
draws that slot (5 is Blade Storm's knives), `VFTestSettingsMenu` set to true or false opens or
closes the settings menu, `VFTestSetting` set to `key=value` (`sensitivity=0.8`, `scoped=0.5`,
`dpi=1600`, `crosshair=0;P;c;5` or `mapRotate=0`) enters that setting as its box or button in the
menu would, `VFTestMap` set to true or false opens or closes the big map as holding Caps Lock does,
`VFTestMapPoint` set to a place, in metres, puts From the Shadows' cursor, or the big map's to ping
with, on the map nearest it, `VFTestPing` set to `tap`, a call's id (`danger`, `watching`, `pushing`
or `help`), `wheel`, `shut` or `map` pings as Z tapped, Z let go on that call, Z held, mouse 2 on
the wheel or mouse 1 on the big map would, `VFTestReport` set to `toggle` or `details` shows or
hides the combat report as N would, or opens or shuts its details as mouse 3 would, `VFTestTake` set
to true presses F, `VFTestBoard` set to true or false holds the scoreboard open as Tab does or lets
it go, `VFTestVote` set to 1, 2 or 3 votes for that map card as a click would, `VFTestPlayMenu` set
to true or false opens or closes the Play menu, `VFTestPlay` set to a mode's key (`skirmish`,
`gungame`, `deathmatch`, `teamdeathmatch`, `standard`, `competitive` or `swiftplay`) presses PLAY
for it, `VFTestLoadouts` set to true or false opens or closes Team Deathmatch's loadout menu,
`VFTestPick` set to `2,3` picks the second stage's third loadout as a click would, `VFTestAgents`
set to true or false opens or closes agent select as T does, and `VFTestAgent` set to an agent's id
(`jett`) selects it as a click on its card would, or set to `lock` locks in. Each of the last
nineteen clears itself.
`VFTestMute` on the local player silences the game's sound while the sound lab's meters still read.
From the server, Workspace's `VFArenaMode` (`skirmish`, `gungame`, `spike`, `deathmatch` or
`teamdeathmatch`), `VFMatchFormat` (`standard`, `competitive` or `swiftplay`) and `VFArenaOn`
choose what's played, `VFMatchMap` (`outpost`, `quarry`, `foundry` or `wharf`) the spike rounds'
first map, and `VFMatchSkip` set true ends the phase under way (a buy phase, a round, the wait for
the next, a gun game match, the victory screen or the vote; a Skirmish round goes to side 1, and a
gun game match to whoever is furthest up). The arena's model says which map is played (`Map`: `A`,
`B` or `C` in the arena, and `outpost`, `quarry`, `foundry` or `wharf` in the spike rounds, whose
maps are models in Workspace's `VFSpikeMap`), and during the vote the maps to pick from and their
votes (`VoteMaps`, `Votes`), with each player's own vote as `VFMapVote`. In gun game it also has the
match's guns, a level each (`Ladder`, as `vandal,phantom,...`), and the UserId of whoever is
furthest up, or won (`Leader`), and each player's level is their `VFGunLevel` attribute, with
`VFProtected` true while their spawn protection lasts. In the spike rounds each player's credits are
their `VFCredits` attribute, and each side's losses in a row `Streak1` and `Streak2` on the arena's
model. Every gun on the ground is a part in Workspace's `VFGroundGuns`, with its `Weapon`, `Ammo`
and `Reserve` as attributes. Each player's record is in their attributes too: `VFKills`, `VFDeaths`,
`VFAssists`, `VFScore`, `VFRounds`, `VFAlive` and `VFLoadout` in either, and `VFStartCredits` in the
spike rounds. `VFInLine` is a player's place in line while both sides are full. Bots (system 60)
fill what's played up to its number of players unless Workspace's `VFBots` is false, at the skill
`VFBotSkill` names (`easy`, `normal`, `hard` or `expert`), each with a stand-in in
ReplicatedStorage's `VFBots`: a Configuration named after it (`BOT Ash`), with its `Entity` and `Id`
and the attributes the arena keeps on a player, among them its agent and its kit as a player's
(system 65), which the top bar and the scoreboard read, and in Studio its job in its side's plan as
`VFBotTask`. In Studio, Workspace's `VFBotMs` has the milliseconds the bots take of each server
frame, and the Output has a line each time a bot's been stuck. Other players and bots are drawn as
the body in ReplicatedStorage's `VFBodies` (system 63), and in Studio a client's Workspace
`VFBodyMs` has the milliseconds the bodies take of each of its frames. Each player's ability kit is
their `VFKit` attribute, as `C0/2 Q1/1 E1/1 X0/8` (charges and most, then the
ultimate's points), with what's under way after it (`storm` while Blade Storm lasts, `glide` while
you glide, `equip` while Curveball's flare, Hot Hands' fireball, Blaze's flame, the Healing Orb or
the Slow Orb is in hand, `bend` while a Blaze wall is bent, `back` while Run it Back runs, and
`away` and `rise` through its return), and `VFTestBuy` set to `updraft` buys a charge. Where a kit's
charges come back over time, when each of C, Q and E next has one is the player's `VFRecharge`
attribute (server time, 0 for none coming). A player's agent is their `VFAgent` attribute, what
they've selected while they can pick `VFAgentSelected`, where they stand `VFAgentPick` (`free`,
`open` or `locked`, unset where nobody picks), and while their window's open, when it closes (server
time) `VFAgentCloses`. A teammate's `locked` agent is taken from the rest of their side (system 48),
and `VFTestAgent` set to a taken agent is refused. Where a player's last Cloudburst burst is their
`VFLastCloud` attribute (metres), and `Workspace.VFClouds` holds each throw in the air and each
cloud as parts. Where a player's last Curveball popped is their `VFLastFlare` attribute (metres),
and their blind their `VFBlind` (when it began, when its white ends and when it's gone, in server
time); `Workspace.VFFlares` holds each flare in the air and each pop as parts. Where a player's last
Hot Hands burst is their `VFLastFire` attribute (the floor under it, in metres), and
`Workspace.VFFires` holds each fireball in the air, each burst and each fire as parts. The far end
of a player's last Blaze wall is their `VFLastWall` attribute (metres), and `Workspace.VFWalls`
holds each wall's run on its way and each wall as models. Where a player last cast Run it Back is
their `VFLastMark` attribute (metres), and `Workspace.VFRunItBack` holds each mark as a model, its
`Entity` attribute whose it is. Whom a player last healed with the Healing Orb is their `VFLastHeal`
attribute (a player's or bot's name). Where a player's last Slow Orb burst is their `VFLastSlow`
attribute (the floor under it, in metres), whether their last tick was slowed their `VFSlowed`, and
`Workspace.VFSlows` holds each orb in the air, each burst and each field of ice. Where a player's
last Dark Cover smoke went is their `VFLastSmoke` attribute (the floor under its mark, in metres),
and `Workspace.VFClouds` holds each smoke and, with its orb in hand, its mark. Whom a player's last
Paranoia orb touched is their `VFLastParanoia` attribute (their names, in the order it touched
them), and their nearsight their `VFNearsight` (when it began, when it stops being whole and when
it's gone, in server time); `Workspace.VFParanoia` holds each orb in flight, the dark round the
camera and each wisp. Where a player's last Shrouded Step takes them is their `VFLastStep` attribute
(the floor, in metres), and `Workspace.VFStep` holds its targeter, and others' windups, their going,
the floor they're going to and their arrival. Where a player's last From the Shadows takes them is
their `VFLastShadow` attribute (the floor, in metres), and PlayerGui's `VFShadow` carries whether
its map's up (`Map`), its cursor (`Cursor`, in metres), whether fire would take them there
(`Placeable`), their Shade's grey (`Grey`), how far they see as one (`Sight`, in metres) and how
dark an enemy's has made their minimap (`Dark`). Where a player's last Recon Bolt stuck is their
`VFLastBolt` attribute (metres), the names its last pulse revealed their `VFLastRecon`, in order,
and the health it has left their `VFBoltHealth`; PlayerGui's `VFRecon` carries whether the bow's in
hand (`Bow`), the bars it's drawn (`Bars`), its bounces (`Bounces`), the bolts drawn (`Bolts`) and
the silhouettes shown (`Revealed`), and `Workspace.VFRecon` holds each bolt, each pulse and each
silhouette. Where a player's last Shock Bolt burst is their `VFLastShock` attribute (metres), and
whom it hurt and how much their `VFShockHits` (each a name and its damage, joined by commas);
`Workspace.VFShock` holds each bolt in the air and each burst. Where a player's last blast of
Hunter's Fury went from is their `VFLastFury` attribute (metres), and whom it caught their
`VFFuryHits` (names joined by commas); PlayerGui's `VFFury` carries whether its bow's in hand
(`Bow`), the seconds it has left (`Left`), whether a blast charges (`Charging`), how fast the view
turns (`Turn`, a share of its usual) and the blasts drawn (`Blasts`), and `Workspace.VFFury` holds
each blast and each one charging. While a player flies the Owl Drone, the id the snapshots give it
is their `VFDroneId` attribute and the health it has left their `VFDroneHealth`; where their last
dart ended is their `VFLastDart` (metres), and whom it struck their `VFDartHit`. PlayerGui's
`VFDrone` carries whether they fly it (`Flying`), the seconds it has left (`Left`), the seconds
until a dart can go (`DartIn`), whether `[Target Hit]` shows (`TargetHit`), whether a dart's pings
are on them (`Tagged`) and the drones drawn (`Drones`), and `Workspace.VFDrone` holds each drone,
their body while they fly it, each dart's streak and each burst's pieces. Workspace's `VFOrbs` is
which of the spike rounds' Ultimate Orbs are up, by number (`1,2`), and `Workspace.VFUltimateOrbs`
holds each orb and its mark. The minimap's ScreenGui, `VFMinimap`, carries what it shows: the plan
drawn (`Plan`, as `spike:quarry`), the entity ids of the enemies on it (`Seen`), whether the spike
is (`Spike`), the Ultimate Orbs on it (`Orbs`, as `1,2`), how far it's turned (`Turn`, degrees),
whether the big map's open (`Big`) and how covered it is by a nearsight's dark (`Dark`, 0 to 1), or
by an enemy's From the Shadows. PlayerGui's `VFIndicators` carries the red arcs round the crosshair
(`Hurt`, each as where on the ring it is, in whole degrees clockwise from the top), where the latest
hit's is (`LastHurt`), the yellow chevrons (`Danger`) and whether the red diamond's up (`Critical`),
and `VFCombatHud` whether the health and the magazine's count read low (`LowHealth` and `LowAmmo`).
PlayerGui's `VFKillBanner` carries the latest banner's number (`Count`, 0 before one), the marks it
lit (`Marks`), whether it was a headshot (`Headshot`), whose kill it was (`Victim`), its kill
sound's playback speed (`Pitch`) and whether a banner's up (`Shown`). The arena's model,
`Workspace.VFArena`, carries the callout of the round just played until the next buy phase
(`Callout`: `ace`, `teamAce`, `flawless`, `clutch` or `thrifty`), and PlayerGui's `VFArenaBanner`
the banner's words (`Title`). Each player carries the gun they're asking their team for
(`VFRequest`), their plan (`VFPlan`: `save`, `buy` or `extra`) and who paid for each of `VFBought`'s
(`VFBoughtBy`: a teammate's UserId, or "" for themselves). Each piece of a dressed map's kit, its
box and its model, carries `VFKitPiece`, the piece's name.
Workspace's `VFFogOff` set true turns the fog of war off, so everyone's snapshots carry everyone,
and `VFFogLines` and `VFFogMs` are what its looks cost in the last second: the lines they cast and
the milliseconds of server time they took. Workspace's
`VFPlayMenu` is whether players start in the Play menu (always on a
live server; in Studio, tick it in the place before you press Play), and `VFModeCounts` how many
are in servers playing each mode (`skirmish=6,gungame=0,...`). A player's `VFPlaying` is true once
they've pressed PLAY on this server. The `Play` remote carries PLAY to the server, and what came of
it back.

## Tests

The shared simulation (movement, weapons and every gun's way of firing, the knife's swings and what
they catch, the spike's plant, defuse and drop, spread and recoil, hitboxes, wire formats, pose
history, render clock, move pacing, lag compensation and wall penetration), the look's maths, the
arena's rules and its three maps, the vote for the next map, gun game (its ladders of guns, levels,
knife kills, spawn protection, the time limit, and joining, leaving and evening the sides out in a
match), the Play menu's modes and its list of servers (what each server plays, which server PLAY
sends someone to, and the counts), the sound's rules (footsteps, landings,
distance curves, walls in the way, reload parts), the settings (crosshair codes and the pixels they
draw, sensitivity and cm/360), the spike's rules (sites, the defuse's reach, its beeps and its
blast), the spike rounds' rules and maps, the economy (what each round pays, kills, the plant, the
cap, what a purchase costs and the shield a survivor keeps), guns on the ground (G's drop, what the
dead drop, walking over one and the one in view), the match's record (the combat score, kills,
deaths, assists and the average), who plays on which side (dropping in, the line and evening the
sides out), the ability kit (charges through rounds, halves, kills and deaths, buying them,
Updraft's height and Tailwind's dash, and the kit on the wire), Cloudburst (the throw, its flight,
its curve and what stops it, and the cloud's life), Blade Storm (the cast, single throws and the
burst, the kills that bring the knives back, swapping, and what ends it), Drift (the glide from a
jump, a ledge and Updraft, a press in a fall, landing with jump held, and what it leaves alone),
agent select (where each player picks, the window, locking in, the time running out, a swap at
once or with the next life, and what's sold back), Curveball (Phoenix's kit, the flare in hand, its
throw and flight, the blind, and the kit on the wire), Hot Hands (the fireball in hand, its
flight off walls and ceilings to the floor, its fire and who stands in it, the burn, Inner Fire's
heal, and the wire), Blaze (the flame in hand, sending and bending the wall, its run up boxes,
through walls and down ledges, the wall and who stands in it, the burn, Inner Fire's heal, and the
wire), Run it Back (the cast and its activation, running out, the return and the rise, a hit it
spares, a plant under way, and the wire), the minimap (who sees whom through the level, clouds
and walls of fire, every map's plan, the views each setting gives, allies held on the edge, the
spike's and the names' rules, and the cones' rays), the fog of war (who's always sent, the lines
from an eye to a body, both carried ahead, corner peeks, what's heard, the hold and the looks it
skips), Sage's Healing Orb (her kit, the orb in hand and its tries, whom a try heals, the heal
and its pauses, and the wire), her Slow Orb (its charges, the orb in hand, its flight and its
field, the slow on the ground, in the air, on a jump and on a dash, judged as a screen showed it,
and the wire), her Barrier Orb (its charge, the orb in hand and its targeter's turns, where its wall
goes, the wall rising, standing and breaking, what it does to steps, shots and sight, its health,
and the wire), her Resurrection (its points, the orb in hand and its tries, where bodies lie and the
aim along them, the return's times and hold, who can be brought back, and the wire), Omen's Dark
Cover (his kit, the orb in hand and its mark, where its smoke goes, its flight, the smoke and its
warning, and the wire), his Paranoia (the orb in hand and its send, its flight, whom it touches
and who's warned, the nearsight, how far the nearsighted see and how the deafened hear), his
Shrouded Step (its charges, its mark in hand, the step, where it takes him, and the wire), his
From the Shadows (its map in hand, the teleport, being sent back, where it takes him, the course's
map, and the wire), Sova's Recon Bolt (the bow in hand, the draw, the bounces and the loose, its
flight, its pulses and whom they reveal, its shaft, and the wire), his Shock Bolt (the bow in hand,
the draw and the loose, its burst, how much it does at each distance and whom it reaches, and the
wire), his Hunter's Fury (its bow in hand, a blast's windup and the blast, the knockback, the
blasts' rate, how it ends, whom a blast catches, and the wire), his Owl Drone (its numbers, in hand,
sent out, its flight, its ceiling, walls, Sova held, its darts, how it ends, the level with drones
in it, its ids, and the wire), one of each agent on a side (what's taken, a selection moved off it,
the time running out, the other side, a key for each side, back in a match, fewer agents than
places, and halftime), the spike rounds' Ultimate Orbs (where they stand, which are up, whose feet
reach one, the taking, a defuse first, and the wire), the ultimate's points across a match (each
round's kind, a match's, a half's and an overtime round's start, and a death's point paid), each
player's agent and ultimate at a glance (the ultimate as everyone reads it, a kit charging, each
agent's letters, a health bar, and the top bar's tiles), pings (what a ping along the crosshair
marks: places, the sky and its reach, smokes, enemies in sight, guns and the spike; the wheel's
calls and its pick, the look, the limit, and how a ping shows), the combat report (a volley's
bullets by part, hits in the reports they touch by weapon and by part, bursts and burns, dummies,
what nobody did and yourself, kills and deaths, the rows' order, whole points, a report's stretch,
and the text checks read), the damage and danger indicators (a hit's way and where it shows on the
ring, arcs renewed and giving way, their fade, arcs pointing as you move, the pulse, fires and walls
near and reaching you, low health and low ammo, and the text checks read), the kill banner (which
kills count, each killer's count by the life and by the round, the headshot mark, the marks and the
top banner, how a banner comes up and fades, and the kill sound rising with the count), the
round-end callouts (what makes each, which one a round won with several gets, the sides too small
for them, deaths that don't count, a life brought back and someone leaving, what each side's banner
says, and a loadout's worth), buying for teammates (what can be asked for, asking and taking it
back, plans, when a request can be bought and by whom, and whose credits go where as a gun bought
for a teammate is sold back, replaced or dropped), the map kit (each piece's placeholder inside its
box, the looks, Wharf's zones, and its dressing out of reach), heights on the spike maps (raised
floors, decks, stairs, ramps, railings and windows as a map's plan builds them, and Wharf walked and
looked across in three dimensions: every floor reached and left, each side's runs to each site, what
its raised places and its window see, and how open its sites are) and bots (how many fill a match
and which leave, what they buy, what they see and how fast, their turns by Fitts's law, duels by
skill, checking corners, walking every map round its walls without getting stuck, and going round a
map together) and bots playing for the spike (who goes for it, a bot's hands planting and defusing
it, an attack on every map and a retake of every site, and getting out of the blast) and taking over
a bot (who may and when, what it changes in the round and its callouts, and the body's kit from the
server to the client) and agents' bodies (the kit's skeleton, the head in the head box, planted
feet, the hands on what they hold, a jump, a reload, a plant and a draw, and no pops) are pure Luau
and run outside Roblox:

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
the default sensitivity, unzoomed and scoped; how long each side takes to reach each spike map's
sites; how fast each skill of bot notices, turns, fires and kills, and how long bots take to walk
each map, to plant the spike on it and to retake each of its sites) and runs the test suites. CI
also type-checks everything with `luau-lsp` and Roblox definitions.

## Rules for this project

- No game memory access, no anti-cheat circumvention, no extracted assets.
- Every gameplay number carries a status: confirmed, community, measured (ours, from a public
  source) or estimate, with its source.
- Gameplay is server-authoritative; clients predict.
