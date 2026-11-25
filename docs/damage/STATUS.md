# Damage option B: status (stage A stop, 25 Nov 2026)

Branch `damage/option-b` (from `main`). Contract: `WORLD_CONTRACT.md` (copied from the locomotion branch, with
Yasin's section 5, "damage follows real-world logic"). **Stage A is built and tested here. Stage B waits for Yasin's go**
and his look at `BEHAVIOUR.md` (the per-prop table with thresholds and reasons).

## What stage A does
| Item | What | Where |
|---|---|---|
| 1 | One C++ damage node, `CityDamage`, with the contract's `hit()`, `strike()`, `surface_at()`, signals `obstacle_changed`, `prop_broken`. `CityStream` makes it (child `Damage`, property `damage`). | `native/src/city_damage.*` |
| 2 | `surface_at`: all 19 surfaces. Cars (body / glass by height), people, room windows and doors, rooms' walls and floors, buildings by their kit (brick, stucco, stone, wood ...; pitched roofs stone, flat roofs concrete), props by the bake's per-shape names (new bake) or by shape (old bake: thin and tall = metal), the ground by the bake's new surface map, the sea. | same |
| 3 | Hit marks: 256 quads in **one MultiMesh, one draw (measured)**, the oldest 32 fading; multiplied onto the surface, so right by day and night; 16 marks on a sheet made here. Only on the static world (a car or a person keeps its own damage). | `assets/damage/marks.*`, `tools/damage/make_mark_sheet.py` |
| 4 | Particles (dust, chips, sparks, splinters, leaves, glass, drops, clods) by surface and kind: one more MultiMesh, one draw while any fly, 192 at most. Sounds by surface and kind from the sets the game has (a pool of 8 players). | same, `assets/damage/sprites.*` |
| 5 | Windows and doors through `hit()`: `CityRooms::hit_opening` (intact -> cracked -> broken, saved with the breakables). **A bullet leaves a hole in the pane: up to 8 holes**, the crack star comes at the 3rd shot, the 5th breaks it. Fixed on the way: the window shatter sound pointed at a file that does not exist (`audio/sfx/glass_shatter_`), now `audio/sfx/car/glass_shatter_`. | `native/src/city_rooms.*`, `tools/city/rooms/builtin/builtin_glass.gdshader` |
| 6 | Test gun: user arg `--testgun` (G key, middle mouse button, or a third finger on the phone) fires from the screen's centre; `--testgun=crowd` also calls the crowd's `gun_aimed` / `gunshot`. Cars report impacts: `CityCar::hit` calls `hit(..., CAR, car)`. The punch: one marked TEMP line in `city_crowd.cpp` at the punch's contact calls `strike()`. | `city_damage.cpp`, `city_car.cpp`, `city_crowd.cpp` |

## Checks run (here, in the cloud: Godot 4.7.2 Linux, the module built for Linux)
- `tests/damage/test_damage.gd` (a made-up street, no bake): **RESULT PASS, 0 failed**. Surfaces of brick and stucco
  walls, the ground, a pole, a bench, a tree, a car (body and glass), a person, the sea; bullets, a punch, a kick at
  nothing, a car into a pole and into a tree; the pool full at 256 with the oldest 32 fading; particles gone after 3 s.
  With the Mobile renderer (software Vulkan): **256 marks on screen = 1 draw call** (8 with, 7 without).
- `tests/damage/test_car_wall.gd` (the car test unchanged, plus the damage node): **RESULT PASS**: a car into a wall
  at 68 km/h marks the wall (a big chip), and the car test's own checks still pass.
- Cost here: **0.06 ms a shot** (ray, surface, mark, particles, sound); the particles' step 0.014 ms a frame. The first
  version cost 0.49 ms a shot, 90 % of it making a sound player each time: now a pool of 8.
- Pictures (Mobile renderer, software Vulkan): `shots/01_holes_brick_stucco.png` (holes, dust in the air, a bark scar,
  a scrape on a pole), `shots/02_full_pool.png` (256 holes, the oldest rows fading), `shots/03_pane_holes.png` (the
  glass shader with three bullet holes).

## What these checks cannot see (say it plainly)
- **The baked city is not in this repo** (`runtime/` is made on Yasin's PC). Nothing here ran on real buildings, real
  room windows or real ground. `tests/damage/test_damage_city.gd` does that on the PC: five shots into a real shop
  pane (holes 1, 2, cracked at 3, broken at 5, `obstacle_changed` once), the wall beside it, the ground in front.
- **The bake must run again** for two things: the per-prop surface names (meta `surf` on bodies) and the ground
  surface map (`far/ground_surface.bin`: asphalt vs pavement). Until then props read by shape (a tree trunk can read
  metal) and **all hard ground reads concrete** (the footsteps' map cannot tell road from pavement). The new map's
  loop over the top-down picture is GDScript: it may add a minute or two to a full bake (not measured).
- **The phone**: not run (the Redmi run comes last). Not known: the cost on the Redmi, how the marks look at 720p,
  whether ETC2 compression smears the small holes. The `#if CURRENT_RENDERER == RENDERER_MOBILE` doubling in
  `marks.gdshader` was checked on the PC's Mobile renderer (software Vulkan) only.
- **A pane's hole shape** follows the crack star's stretch (a pane twice as tall as wide in its UVs): on a wide pane
  the holes look flattened. Not measured on the real panes.
- **Sounds are stand-ins** (footstep landings, pole and bin hits, car bumps): no bullet sounds exist. List:
  `ASSETS_WANTED.md`.
- The punch's `strike()` runs only inside a fight (that is where the game's punch lands); a punch at a wall alone does
  not happen in the game yet. Kicks do not exist yet.
- The test gun's keys and the third finger were not pressed in a test (`shoot()` itself is tested).
- Marks stay where they are when a cell unloads (far away, out of sight); a mark on a door would swing off, so doors
  take none.

## Not in stage A (stage B, after Yasin's go)
Health and behaviours per prop kind (`BEHAVIOUR.md`), `CityBreakables` to all kinds, layers 3 / 4 / 7 (debris is still
on layer 1 today), hydrant water, trees shaking / snapping, `prop_broken`, saved prop state.

## Yasin: to do on the PC
```
bash native/build.sh windows
godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/damage/test_damage.gd
godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/damage/test_damage_city.gd
```
The city test needs the current bake; a new bake gives the surface names and the ground map.
