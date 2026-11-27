# Damage: what I need from Yasin (25 Nov 2026)

Made here already: the mark sheet (`assets/damage/marks.png`, 16 marks: bullet holes in concrete, brick, stucco, stone,
wood, metal, asphalt and plastic; a bark scar, a ground divot, punch and kick scuffs, a car scrape, tyre rubber, a big
chip) and the particle sheet (`assets/damage/sprites.png`: dust, chip, spark, splinter, leaf, glass shard, drop, clod),
both drawn by `tools/damage/make_mark_sheet.py`. Replace them with better ones any time: same layout (4 x 4 tiles,
white = no mark on marks.png).

The sounds below do not exist in the game yet. Until they come, the damage system uses the nearest sound it has
(footstep landings, pole and bin hits, the car's bumps and scrapes, door glass): it works, but a bullet sounds like a
thump. **Wanted, 3-4 takes of each, short (0.1-0.6 s), mono .ogg:**

| Sound | For | Folder / name I will look for |
|---|---|---|
| bullet into concrete / brick / stucco | holes in walls | `audio/sfx/damage/bullet_masonry_0..3.ogg` |
| bullet into metal, with ricochet | poles, cars, signs | `audio/sfx/damage/bullet_metal_0..3.ogg` |
| bullet into wood | benches, fences, doors, trees | `audio/sfx/damage/bullet_wood_0..3.ogg` |
| bullet into glass (a crack, not a shatter) | windows, car glass | `audio/sfx/damage/bullet_glass_0..3.ogg` |
| bullet into dirt / grass / sand | the ground | `audio/sfx/damage/bullet_dirt_0..3.ogg` |
| bullet into water (a splash) | the sea | `audio/sfx/damage/bullet_water_0..3.ogg` |
| bullet into a person | people (no gore needed) | `audio/sfx/damage/bullet_flesh_0..3.ogg` |
| bullet passing by (a whiz) | near misses | `audio/sfx/damage/whiz_0..3.ogg` |
| a gunshot (pistol) | the test gun now, guns later | `audio/sfx/damage/gunshot_pistol_0..3.ogg` |
| punch / kick on metal (a dull clang) | hydrants, poles, bins | `audio/sfx/damage/hit_metal_0..3.ogg` |
| punch / kick on wood | doors, fences | `audio/sfx/damage/hit_wood_0..3.ogg` |
| a tree shaking (leaves rustle) | a car against a big tree | `audio/sfx/damage/tree_shake_0..2.ogg` |
| a tree or a slat snapping (wood crack) | small trees, benches, fences | `audio/sfx/damage/wood_snap_0..2.ogg` |
| water spraying, a loop | a broken hydrant | `audio/sfx/damage/hydrant_spray_loop_0.ogg` |

**Models for stage B (not needed for stage A):** a hydrant stump (the flange left in the ground), a bent lamp post, a
snapped sign post, a bench with its slats gone, a shattered shelter panel frame, a fallen small tree. Low poly, same
texture atlas as the props they belong to. If there are none, stage B tips the whole prop over instead (as the 9 kinds
that cars knock today).
