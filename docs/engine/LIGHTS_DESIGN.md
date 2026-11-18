# Lights in the Mobile renderer: design note (step d)

**Update, same day:** Yasin asked for the light grid as a test build. A first version exists as patch e
(`patches/e_mobile_light_grid.patch`, build `e2_light_grid`): 24 x 12 screen tiles and 64 depth slices (one
mask per slice rather than the min / max pairs described below), 32 omni + 32 spot lights, switched by the project setting `rendering/lights_and_shadows/mobile_light_grid`.
The per-mesh pairing and its pipeline variants are still there (the grid ignores them when on). What it was
checked against is in `tests/light_grid/README.md`. The text below is the design as written before the build.

12 Nov 2026. Read against Godot `4.7.2-stable` (`ed1daf0b`). Phone numbers are the game's own
(`PERF_LIGHTING_12NOV.md`); nothing here was measured on a phone by this session.

## Recommendation in one paragraph
Do not port Godot's clustered renderer and do not build a deferred renderer. If the game needs more than the
Mobile renderer gives today, the design that fits a phone is a **CPU-built tile + depth-bin light mask** read per
pixel (the scheme Unity URP calls Forward+ and Filament calls froxels, both built for phones): the 8-per-mesh limit
goes, a light is only visited where it reaches, and the light count stops multiplying pipelines. But first measure
what today's engine really charges for a light on the phone (see "Before any engine work"): the engine already
skips the expensive part outside a light's range, so the gain may be smaller than the game's notes assume.

## What 4.7.2 does today (verified in the source)
- `forward_mobile/render_forward_mobile.h`: `MAX_RDL_CULL = 8`. Each geometry instance carries
  `omni_lights[2]`, `spot_lights[2]`: 8 light ids of 8 bits each, packed in two `uint32`.
- `renderer_scene_cull.cpp` (about lines 3060-3145) pairs lights to instances on the CPU by AABB overlap and calls
  `pair_light_instance(light, type, index)`; when a mesh is touched by more than 8 it replaces one.
- `shaders/forward_mobile/scene_forward_mobile.glsl` (about 2168-2232): the fragment shader loops
  `sc_omni_lights(8)` / `sc_spot_lights(8)` times and calls `light_process_omni` / `light_process_spot` for each id.
- `shaders/scene_forward_lights_inc.glsl` `light_process_omni` (line 466): reads the light, computes the distance
  and attenuation (a `length` and a `pow`), guards the shadow lookup with `omni_attenuation > HALF_FLT_MIN`, and
  calls `light_compute`. Inside `light_compute` (line 199) the BRDF is wrapped in
  `if (is_directional || attenuation > HALF_FLT_MIN)`. So for a pixel outside the light's range the engine pays the
  light fetch and the attenuation maths, **not** the BRDF. A lamp that touches one corner of a merged 100 m mesh
  therefore costs every pixel of that mesh a little, and the pixels in range the full amount. (The game's
  `PERF_LIGHTING_12NOV.md` says the light "is evaluated in every pixel"; per the source that is true only for the
  attenuation part.)
- `render_forward_mobile.cpp` 2478-2480: the per-instance light counts go into the pipeline specialization
  (`shader_count_for`), so each new count combination is another pipeline to compile (a hitch, and with re-spirv a
  parse, see patch b2).
- Godot's own clustered path (`cluster_builder_rd.cpp`) builds its clusters by **rasterizing light volumes into a
  render target and then running a compute pass** (`draw_list_begin` at 474, `compute_list_*` at 522-550). That is
  two extra GPU passes and compute storage every frame; it is what makes Forward+ heavy on the phone and it is not
  usable from the Mobile renderer's no-compute path.

## Options compared
| Option | Per-pixel cost | Extra passes / memory | Engine work | Fit for tile GPUs | Verdict |
|---|---|---|---|---|---|
| A. Keep today's per-mesh lists (the BRDF early-out already exists) | out of range: light fetch + attenuation per paired light | none | none | perfect | **measure first**; enough if <= 8 lights per mesh is acceptable |
| B. CPU tile + depth-bin masks (URP Forward+ / Filament froxels) | 2 small fetches, then only lights that reach the pixel | one small buffer upload per frame | medium: ~1500-2500 lines, 6-8 files | good: still one forward pass, no G-buffer | **the one to build if A is not enough** |
| C. Port Godot's clustered builder to Mobile | similar to B | +1 raster pass +1 compute pass, cluster texture | large, drags compute into Mobile | poor: extra passes cost bandwidth | no |
| D. Deferred (G-buffer, light volumes) | cheapest per light when lights are many | G-buffer 3-4 targets | very large: every material path, transparency, MSAA, decals | only acceptable if the G-buffer stays in tile memory (subpass inputs through every scene shader); not checked how far 4.7.2 supports that | no |
| E. Baked / fake only (today: `vlit`, light pools, coronas) | zero | none | none | perfect | keep for static lamps on ground and facades |

Why not deferred, plainly: on a tile GPU a G-buffer that leaves the tile memory costs more bandwidth than the whole
frame does today; keeping it in tile memory needs input attachments through every scene shader. The game's cost is
one sun plus a handful of local lights, the case where forward wins.

## Before any engine work: one phone measurement (PC session, game code only)
Put one unshadowed omni light so that its range touches a big merged mesh (ground or a facade block) but lights
only a small patch on screen, and lap GPU ms with the light on and off. Repeat with 4 and 8 such lights.
- If the cost follows the lit patch (small): today's engine is already close to the best case for up to 8 lights
  per mesh. Then the only reasons for engine work are the 8-per-mesh limit and pipeline variants.
- If the cost follows the mesh's screen area (large): the attenuation part matters on the Mali and option B pays.

A shader change of any kind in `scene_forward_mobile` has a side cost: those shaders' baked cache from the
official editor is skipped and they compile on the phone at first run (long first load, then cached in `user://`).
The clean fix is to export with an editor built from the same patched source (one more build target, a Windows
editor, a few hours to set up).

## Option B in detail: tile + depth-bin light masks, CPU-built
**Data, per view, built on the CPU each frame** (in `RenderForwardMobile::_setup_lights` or beside
`light_storage->update_light_buffers`):
- Visible omni + spot lights sorted by view depth, capped at 32 (one `uint32` mask) or 64 (two words).
- **Z bins**: 1024 slices of view depth; each holds `(min_light_index, max_light_index)` as two `uint16`.
- **Tiles**: screen cut in 16 x 9 (or 32 x 18) tiles; each holds a `uint32` bitmask of lights whose screen
  bounds touch it (sphere / cone bounds projected on the CPU).
- Upload: one uniform buffer of about 1024 x 4 + 576 x 4 = 6.4 KB per view.

**Fragment shader**: tile = `gl_FragCoord.xy / tile_size`, mask = `tiles[tile]`; z bin from view depth gives
`[min, max]`; `mask &= bits(min..max)`; `while (mask != 0) { i = findLSB(mask); mask &= mask - 1; light(i); }`.
Lights of one kind are stored contiguously so omni and spot loops stay separate.

**Files**
- `servers/rendering/renderer_rd/forward_mobile/render_forward_mobile.{h,cpp}`: build bins and tiles, upload, bind
  in the render pass uniform set; drop light ids from `InstanceData` and the light counts from
  `pipeline_specialization` (fewer pipelines).
- `servers/rendering/renderer_rd/storage_rd/light_storage.{h,cpp}`: view-depth sort, screen bounds per light
  (`update_light_buffers` already walks them).
- `servers/rendering/renderer_rd/shaders/forward_mobile/scene_forward_mobile.glsl` and `_inc.glsl`: the new loop,
  the uniform block; vertex-lit path keeps a simple per-instance list or uses the same masks.
- `servers/rendering/renderer_scene_cull.cpp`: light-to-instance pairing can stay for shadow caster work but no
  longer feeds the shader for omni / spot (keep it for reflection probes and decals, which stay per mesh).
- `scene_shader_forward_mobile.{h,cpp}`: remove the `omni_lights` / `spot_lights` specialization constants.
- Light `cull_mask` / layers: one extra `uint` compare per light in the loop (the data already has `mask`).

**Expected cost (an estimate, not measured)**: a fixed two small fetches on every lit pixel and a few tens of
microseconds of CPU for 32 lights; each light is then visited only in the tiles and depth range it reaches. What
it saves against today is the per-paired-light fetch and attenuation on every pixel of big meshes, and the
8-per-mesh cap; how many milliseconds that is on the Redmi is exactly what the measurement above tells.

**Risks**
- Depth discontinuities inside a tile: a tile keeps lights for all depths; the z bin trims most. Worst case is a
  few wasted lights per pixel, never wrong lighting.
- Dynamic loops: a `findLSB` bit loop is what URP and Filament ship on phones, so I expect it to be fine on the
  Mali-G610, but this session has not measured it. A two-light prototype on the phone settles it early.
- Shadowed local lights stay expensive regardless (atlas passes + lookups). Keep the game's rule: no shadowed omni.
- Transparent and vertex-lit materials must use the same data or lighting pops between paths.
- Multiview (XR) needs per-view tiles; the game does not use it, keep the old path under multiview.
- It changes every scene shader variant: full shader cache rebuild, and a regression risk for the ubershader path.
  Test both specialized and ubershader pipelines.
- Upstream drift: this touches files Godot changes every release; carrying it to 4.8 is real work.

## What it means for the game
With option B, a merged ground or facade mesh can be touched by any number of lamps and each pixel visits only
the ones that reach it. Baked `vlit` stays the cheapest for static lamps at distance; real lights take over near the
player (headlights, room lamps, the nearest street lamps), chosen by distance in game code.

## Order of work and effort
1. The phone measurement above: game code only, one evening of laps.
2. If B is wanted: an editor build from the patched source first (so shader-changing patches keep their baked
   cache), then B itself: about 3-5 working days for a first version, plus picture comparison against the current
   renderer on Linux for every light type, then phone laps.
