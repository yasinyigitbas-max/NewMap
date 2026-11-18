# Every look switch, on one page (for Yasin, 18 Nov)

Two cloud sessions made the "visible jump": the sky, light and colour (branch `claude/look-sky`, `docs/LOOK_SKY.md`)
and the buildings' shader (branch `claude/look-buildings`, `docs/LOOK_BUILDINGS.md`). Neither is merged. Every change
can be turned on and off. Pictures are from the cloud, which draws buildings ~40 % too dark, no sun shadows and no
sky reflection: the phone pictures the PC session takes are the real ones.

"Safe by default?" = my advice for the phone, from what each change costs per pixel (the phone is limited by pixels).
None of it is measured on the phone yet.

| Switch (how) | What it does | Picture | Cost on the phone | Safe by default? |
|---|---|---|---|---|
| `--look=1` (rig; `0` = old look) | GTA 4-like sky with clouds, smoggy haze into the sky, warm sun / grey shade, colour grade; night with orange smog glow | `look_18nov/sky/pair_*.jpg` | sky: same as the old sky; haze: a little maths a pixel; grade: one read of a tiny table a pixel | YES |
| `--look=morning`, `noon`, `day`, `golden`, `dusk`, `night`, `overcast` (rig) | times of day of the same look | `look_18nov/times/sheet_*.jpg` | the same as `--look=1` | YES (the game picks one by its clock) |
| `--glow=1` (rig, on with the look; `0` = old) | lamp halos with a hot core and soft glow, warm sodium colour, light pools no longer cut by kerbs, far lamps fade into the haze | `look_18nov/glow/*_glow0.jpg` (old) vs `times/*_night.jpg` | a few more sums per glow pixel; the big pools are 28 % smaller, so likely a bit cheaper than before | YES (check the first-use hitch) |
| `--bloom=1` (rig, off) | soft glow round bright things | `look_18nov/sky/pair_*` (bottom row) | a blur chain + one read a pixel: guess 1-2 ms; the 720p runs sit right at the 60 fps step | NO: measure first |
| `--upscale=1 --sharp=0.2` (rig, off) | the phone's engine sharpens the 720p picture up to the screen (SGSR) instead of plain stretching | `look_18nov/upscale/crop_*.jpg` (cloud engine with the patch: 18-30 % sharper) | one extra pass over the whole screen (2460 x 1080): guess 0.5-1 ms | MAYBE: test on the phone (`LOOK_SKY.md` job 2 says how) |
| `--blobs=1` (rig, off) | soft tree shadows past the 50 m sun shadow | `look_18nov/blobs/` vs `times/` | cheap to draw (small far quads, +5 to +8 draws measured), but today it reads each cell's meshes when it loads: hitches | NO until the bake records the trees (`docs/look_patches/blob_shadows.md`) |
| `--wet=0.8` (rig, off) | rain mood: darker ground, sky in the puddles | `look_18nov/wet/` vs `times/` | two more reads on every ground pixel (most of the screen) | NO: only when it rains; and it needs the line in the ground shader |
| `--reflect=0` (rig; default 1) | no engine sky reflection at all (saves one read in every lit pixel) | (the cloud pictures are all taken this way) | saves pixels | MAYBE: with the buildings' glass on the sky map (`sky_reflect.gdshaderinc`) instead, yes |
| `--cycle=120 --clock=7` (rig, off) | a running day: the whole day in 120 s, sun east to west, the moon at night, every value blended (nothing jumps) | `look_18nov/day/sheet_*.jpg` | sky and its maps step every 0.5 s (0.44 ms main thread in the cloud); the engine's sky reflection redrawn over several frames | MAYBE: measure the day / night change (`LOOK_PHONE_TESTS.md` run 11) |
| `--celestial=1` (rig, on with the look; `0` = before) | sun disc with soft glare, a moon with its own light, stars that rise with the dusk | `look_18nov/celestial/pair_*.jpg` | sky pixels only: a few sums; one texture read on the moon's own pixels | YES |
| `--sea=1` (rig, on with the look; `0` = green plane) | the sea: colour by depth, ripples, the sky reflected, a sun glint; meets the shore foam | `look_18nov/sea/pair_*.jpg` | one draw (~33k triangles); 3 texture reads per water pixel, unshaded | YES, but measure the waterfront (run 5) |
| `--weather=mist\|hazy\|storm\|rain` (rig) | weather moods over any time of day; mist burns off in the running day | `look_18nov/weather/sheet_*.jpg` | numbers only; rain adds the wet ground | YES (rain: as `--wet`) |
| `--air=1` (rig, off) | gulls over the waterfront, a plane now and then, smoke from the steel mill | `look_18nov/air/pair_*.jpg` | one draw of small see-through quads | YES after one phone run (14) |
| `--cars=1` (rig, DEMO) / `--carenv=1` | the preview cars parked on the stalls; their paint and glass reflect the look's sky | `look_18nov/cars/pair_*.jpg` | the reflection: the game's car shader already reads its panorama; the look only supplies it (128 x 128, once per time change). The demo itself: one draw a car | env: YES; the demo cars: NO (pictures only) |
| `--look=day_half`, `--look=day_clear` (rig) | two other days, kept as NAMED PRESETS only: half the haze / a clear blue Coronado day | `look_18nov/variants/sheet_*.jpg` | the same as `--look=1` | SETTLED: Yasin, 18 Nov: "i go for gta4 look": the default `day` stays; these are not the default |
| `--shadowtune=1` (rig, on with the look; `0` = before) | the sun shadow's end fades out from 30 to 50 m instead of a line; 2 blended splits; softer for a low sun, fainter when the sun is weak | `look_18nov/shadow/pair_*.jpg` | 2 splits instead of the engine's 4: two shadow passes LESS; blending only where the splits meet | YES (check the near shadows' sharpness on the phone) |
| `ck_look_contact` (shader value, buildings) | buildings sit on the pavement: thin dark line at the wall's foot, the kit's own AO also dims sunlight | `look_18nov/buildings/*_contact.jpg` | ~5 sums per building pixel | YES |
| `ck_look_windows` (shader value, buildings) | night windows whole, each its own light (warm, white, a few cold / TV), no orange chequerboard | `look_18nov/buildings/*_windows.jpg` | ~20 sums per building pixel, at night only | YES |
| `ck_look_glass` (shader value, buildings) | glass reflects the sky by day, panes differ a little | `look_18nov/buildings/*_glass.jpg` | ~40 sums on glass pixels, by day | YES |
| `ck_sky_map` / `ck_wet` (shader values, from the look) | the small sky picture glass and wet ground can reflect; the rain amount | (used by the two lines above) | the map is drawn once per time-of-day change | YES (nothing uses them until a shader includes the snippet) |

How to switch on the phone without a rebuild: the rig options go into the args file the phone script writes
(`user://rig_args.txt`), e.g. `--plan=zones --look=golden --upscale=1`. The building switches are global shader
values, set from code (`RenderingServer.global_shader_parameter_set(&"ck_look_glass", 0.0)`) or in project.godot.

## The phone runs
All of them, in order, one change at a time: `docs/LOOK_PHONE_TESTS.md`. The short version below still holds.

## My suggestion for the next phone run (PC session)
1. `--plan=zones --look=0` against `--plan=zones --look=1` (and the buildings' switches on): the whole pack's cost.
2. The same with `--bloom=1`, and with `--upscale=1`: one each, each against the run before.
3. Pictures on the phone: `--shots=user://look --look=1`, `--presets=morning,noon,golden,dusk,night,overcast`.

## Waiting for a change somewhere else (written as notes, nothing applied)
- `docs/look_patches/streamer_now.md`: a streamer bug found on the way (cells loaded "all at once" get no collision).
- `docs/look_patches/glow.md`: the new lamp glow inside the bake's own shader.
- `docs/look_patches/blob_shadows.md`: the bake records the trees, so blob shadows cost nothing when a cell loads.
- `tools/city/look/sky_reflect.gdshaderinc`: two lines for the buildings' glass and the ground's rain.
