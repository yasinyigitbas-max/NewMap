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
| `--upscale=1 --sharp=0.2` (rig, off) | the phone's engine sharpens the 720p picture up to the screen (SGSR) instead of plain stretching | `look_18nov/upscale/` (if the cloud engine built) | one extra pass over the whole screen (2460 x 1080): guess 0.5-1 ms | MAYBE: test on the phone (`LOOK_SKY.md` job 2 says how) |
| `--blobs=1` (rig, off) | soft tree shadows past the 50 m sun shadow | `look_18nov/blobs/` vs `times/` | cheap to draw (small far quads, +10-14 draws), but today it reads each cell's meshes when it loads: hitches | NO until the bake records the trees (`docs/look_patches/blob_shadows.md`) |
| `--wet=0.8` (rig, off) | rain mood: darker ground, sky in the puddles | `look_18nov/wet/` vs `times/` | two more reads on every ground pixel (most of the screen) | NO: only when it rains; and it needs the line in the ground shader |
| `--reflect=0` (rig; default 1) | no engine sky reflection at all (saves one read in every lit pixel) | (the cloud pictures are all taken this way) | saves pixels | MAYBE: with the buildings' glass on the sky map (`sky_reflect.gdshaderinc`) instead, yes |
| `ck_look_contact` (shader value, buildings) | buildings sit on the pavement: thin dark line at the wall's foot, the kit's own AO also dims sunlight | `look_18nov/buildings/*_contact.jpg` | ~5 sums per building pixel | YES |
| `ck_look_windows` (shader value, buildings) | night windows whole, each its own light (warm, white, a few cold / TV), no orange chequerboard | `look_18nov/buildings/*_windows.jpg` | ~20 sums per building pixel, at night only | YES |
| `ck_look_glass` (shader value, buildings) | glass reflects the sky by day, panes differ a little | `look_18nov/buildings/*_glass.jpg` | ~40 sums on glass pixels, by day | YES |
| `ck_sky_map` / `ck_wet` (shader values, from the look) | the small sky picture glass and wet ground can reflect; the rain amount | (used by the two lines above) | the map is drawn once per time-of-day change | YES (nothing uses them until a shader includes the snippet) |

How to switch on the phone without a rebuild: the rig options go into the args file the phone script writes
(`user://rig_args.txt`), e.g. `--plan=zones --look=golden --upscale=1`. The building switches are global shader
values, set from code (`RenderingServer.global_shader_parameter_set(&"ck_look_glass", 0.0)`) or in project.godot.

## My suggestion for the next phone run (PC session)
1. `--plan=zones --look=0` against `--plan=zones --look=1` (and the buildings' switches on): the whole pack's cost.
2. The same with `--bloom=1`, and with `--upscale=1`: one each, each against the run before.
3. Pictures on the phone: `--shots=user://look --look=1`, `--presets=morning,noon,golden,dusk,night,overcast`.

## Waiting for a change somewhere else (written as notes, nothing applied)
- `docs/look_patches/streamer_now.md`: a streamer bug found on the way (cells loaded "all at once" get no collision).
- `docs/look_patches/glow.md`: the new lamp glow inside the bake's own shader.
- `docs/look_patches/blob_shadows.md`: the bake records the trees, so blob shadows cost nothing when a cell loads.
- `tools/city/look/sky_reflect.gdshaderinc`: two lines for the buildings' glass and the ground's rain.
