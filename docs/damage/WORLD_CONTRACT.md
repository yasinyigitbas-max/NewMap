# World contract: damage and traversal (25 Nov 2026)

Yasin chose **damage option B** (hit marks on every surface first, then props that react and break). It is built in the
game by its own session, while two traversal labs (procedural and layered) are built in isolation. This contract is
the only thing they share, so whichever lab wins **drops in without rewriting either side**. Keep to it. Change it only
with Yasin's word, and write the change here.

## 1. Collision layers (Godot layer numbers; the value in brackets is the bit)
The game already uses 1, 2, 5 and 6. Those meanings stay.

| Layer | Bit | What | Who is on it |
|---|---|---|---|
| 1 | 1 | **static world** | buildings, ground, roads, pavements, merged props, tree trunks, walls of rooms |
| 2 | 2 | **player on foot** | the player's capsule |
| 3 | 4 | **standing breakables** | every prop that can be knocked over or broken, while it stands (moved off layer 1) |
| 4 | 8 | **breakable openings** | window panes and door leaves while intact or cracked; off once broken (the opening is free) |
| 5 | 16 | **cars** | traffic and the player's car (unchanged) |
| 6 | 32 | **people** | the crowd's capsules (unchanged) |
| 7 | 64 | **debris** | fallen props, broken pieces, shards: never something to stand on, climb or vault |
| 8 | 128 | (reserved for the damage system's own queries if it needs one) | |

- **Traversal and locomotion probes** (ground, step, vault, climb, ledge, cover rays and shape casts) use mask
  **1 | 4 | 8**. Never 64. An intact window or door is a wall; a broken one is an opening.
- **The player's capsule** collides with 1 | 4 | 8 | 16 | 32. **Not 64**: he walks through small debris. The damage
  system may push light debris away from him.
- **Debris** collides with 1 | 4 | 16 (the world, standing props, cars). It doesn't collide with the player, people or
  other debris unless the damage system decides so for a big piece.
- **Bullets** (hit tests) use 1 | 4 | 8 | 16 | 32 | 64.

## 2. Surfaces
Every hit reports a **surface type**, one of: `concrete, brick, stucco, asphalt, stone, wood, metal, glass, plastic,
fabric, bark, foliage, grass, dirt, sand, water, flesh, car_body, car_glass`. The damage system owns the lookup
(material, collider meta or a per-cell table: its choice) and exposes it as `surface_at(hit)`. Traversal may use the
same lookup for footstep sounds and grip; it never builds its own table.

## 3. The damage interface (C++, a node in the game, one per world)
```
// every source of harm calls one of these; nothing else talks to props, windows or doors directly
Dictionary hit(Vector3 at, Vector3 normal, Vector3 dir, float amount, int kind, Object *source);
    // kind: BULLET, PUNCH, KICK, BLUNT, CAR, FALL (later: EXPLOSION)
    // returns { surface, target_id, state: "marked" | "damaged" | "broken" | "knocked" }
Dictionary strike(Vector3 from, Vector3 to, float radius, float amount, int kind, Object *source);
    // a melee sweep: the locomotion system calls it on the contact frame of a punch or kick, with the fist's or
    // foot's path in that frame; it finds the first thing touched and calls hit()
String surface_at(const Dictionary &ray_hit);
signal obstacle_changed(AABB box);
    // a prop fell, a window or door broke, debris settled: anything a traversal system cached inside this box is stale
signal prop_broken(String target_id, Vector3 at, int kind);
```
- **Cars report their own impacts** through `hit(..., CAR, car)`; the locomotion system reports falls through
  `hit(..., FALL, player)` if a landing should mark the ground.
- **The traversal system** must probe the world live, never keep a probe result across frames without listening to
  `obstacle_changed`. It holds no reference to props.
- The damage system never moves, animates or freezes the player or people. It only reports (signals) and changes the
  world.

## 4. What the labs do now
- Use these layers and masks in their own test projects, so their probes already behave as they will in the game.
- Put at least one **breakable prop stand-in** (a bin on layer 3 that turns into layer-7 debris when "hit"), one
  **window** and one **door** (layer 4) on the course, and test that traversal refuses debris, treats an intact window
  as a wall and walks or climbs through a broken one.
- On the contact frame of punches and kicks (if the lab has them), call a stub `strike(...)` with this signature.

## 5. What the damage session doesn't touch
The player, people, animation and traversal code (`city_player*`, `city_ped*`, `mo_*`, `hand_grip*`, `foot_*` and the
like). To test melee before a lab system arrives, it may add **one marked, temporary line** at the existing punch's
contact that calls `strike()`, and nothing more.
