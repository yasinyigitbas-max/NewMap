# Look pack, sky half: sky, haze, light, colour (18 Nov 2026)

Yasin: "we need a visible jump"; then "we are going for a gta 4 like look". This is one half of a cheap look pack for
the phone test app (`tools/city/rig/rig.tscn`); the other half (the buildings' shader) is a separate session.
Branch `claude/look-sky`. Nothing in the locked pieces, the bake or the city's shaders changed.

## What changed
| Part | What it does | Cost per pixel on the phone |
|---|---|---|
| Sky (`tools/city/look/sky.gdshader`, `sky_noise.png` 256 x 256) | a pale sky from a smoggy yellow-grey horizon to a soft blue top, soft drifting clouds, the sun's glow; at night a brown-orange glow over the city, a few stars, clouds lit orange from below | only on sky pixels, in the pass that already draws the sky: 2 reads of one small texture (3 at night) instead of the old sky's arithmetic. No `TIME` in the sky, so its light map is not redrawn every frame |
| Haze | the engine's plain distance fog, coloured like the sky's horizon, with the same sun glow, so the far city fades INTO the sky; denser and orange at night | one `exp` and one blend per pixel, no texture read. No height fog, no volumetric fog, `fog_aerial_perspective` 0 |
| Warm sun, cool shade | amber sun, grey-blue shade light; at night a weak blue moon and a dark brown-grey shade light | nothing (light colours only) |
| Tonemap + grade | Filmic curve, then a 16 x 16 x 16 colour table built at start (`look.gd grade_color`): colours held back (saturation 0.72), cool-green shadows, warm yellow highlights, a little warmer overall, a soft S-curve, blacks lifted to a smoggy grey | in the last pass, which runs anyway (it scales the 720p picture up and smooths edges): one read of a 12 KB table per screen pixel |
| Sun angle | 40 degrees high instead of 48 (longer shadows, more light on the walls) | nothing |
| Bloom (`--bloom=1`, OFF by default) | a soft glow round bright things, GTA 4 style | a blur chain at 1/4 to 1/16 of the picture plus one read per pixel: roughly a third of a frame's pixels again. My guess 1-2 ms on the Redmi, NOT measured |

Not used, on purpose (the phone is pixel-limited): SSAO, SSR, volumetric fog, depth of field; bloom only as a switch.

## How to switch it
Rig options (after `--` on the PC, or in `user://rig_args.txt` on the phone; no rebuild):
- `--look=1` (default) the look pack; `--look=0` the old plain sky and light, to compare on the same drive.
- `--bloom=1` adds bloom (off by default; measure it first).
- `--reflect=0` turns off sky reflections (default on, as before; saves a cube-map read a pixel; needed in the cloud).
- `--shots=FOLDER` takes pictures at the set views instead of driving, by day and at night, and quits:
  `<view>_<day|night>_<before|after|after_bloom>.jpg`, 1640 x 720. `--views=name:x,z:yaw[:pitch];...` and
  `--times=day|night` to change them. Views: centre (Amber Ave at 7th St), apartments, gritty edge, waterfront.

```bash
godot --path . --resolution 1640x720 -- --shots=OUT/look --look=1
```
```bash
godot --path . --resolution 1640x720 -- --shots=OUT/look --look=0
```
In the game the same node can be used as is: `look.gd` (`set_night(0..1)` for the time of day).

## The pictures
`map_dc/coronado/city_kit/review/look_18nov/sky/`: before / after pairs (`*_before.jpg`, `*_after.jpg`) and side by
side sheets (`pair_*.jpg`). Taken in the cloud, which is NOT what the phone shows:
- the cloud's software GPU draws the weathered buildings about 40 % too dark;
- it draws every tree near the camera BLACK when sun shadows or sky reflections are on, so the cloud pictures were
  taken with sun shadows off (`NOSHADOW=1`) and sky reflections off (`--reflect=0`), before and after alike. The
  phone has both (shadows to 50 m, as before). So there are no shadows in the pictures, and glass reflects no sky.
The PC session takes the real ones on the phone.

What the cloud pictures show:
- Draw calls are the same with and without the look (day 77 / 99 / 70 / 60, night 91 / 111 / 86 / 70 for centre,
  apartments, gritty, waterfront): the look adds no draws.
- By day: pale smoggy sky with clouds, the far end of every street fades into a yellow-grey haze, walls warm, shade
  grey; colours held back. By night: brown-orange glow low in the sky, orange windows and lamps, few stars.
- At night the road away from the lamps is darker than before in the centre (the grade's S-curve darkens the darks).
  If it is too dark on the phone: `NIGHT.ambient_energy` in `look.gd` (0.6 now) is the one number to raise.
- Bloom is hardly visible in the cloud pictures (the software GPU's bright range is not the phone's, and it is kept
  subtle on purpose). Judge it on the phone.

## What it should cost, and what could not be checked
- Expected: the sky costs about what the old sky did; the haze and the grade a few arithmetic steps and one small
  table read per pixel. Next to the rest of a frame that is small, but at 720p the phone sits right at the 60 fps
  step (median 16.5 ms against 16.7), so even a small cost can push frames over the step. That is the one real risk.
- NOT checked (needs the phone): frame times with `--look=1` against `--look=0` (run `--plan=zones` both ways, and
  once with `--bloom=1`); how the colours look on the Redmi's screen; whether the Mali GPU builds the new sky and the
  colour table without a hitch at start; dusk values between day and night (`set_night(0.5)`), never looked at.
- The lamp halos (`rt_glow.gdshader`) are drawn without fog on purpose, so far halos shine through the night smog.
  If that looks wrong, the building-shader session can fade them with distance: one line, not done here.

---------------------------------------------------------------------------------------------------------------------
# The look queue (18 Nov, evening; from the PC session for Yasin: "give them all the improvements lists and have them do them non stop")
Every job below is switchable, has pictures under `review/look_18nov/<job>/`, and touches neither the bake, the
streamer nor the city's shaders: where those would need a change it is written as a note in `docs/look_patches/`.
All pictures: cloud preview (no sun shadows, no sky reflection, buildings ~40 % too dark), 1640 x 720.

Found while doing it (PC session, please read): `docs/look_patches/streamer_now.md`: since the streamer rewrite,
`update_focus(p, true)` adds cells WITHOUT collision (the rig's own start uses it). One-line fix in the note.

## Job 1: times of day (`--look=NAME`)
`--look=morning | noon | day | golden | dusk | night | overcast` (`--look=1` is the day / night pair as before, `0` the
old look). A preset sets the sun's height and direction, every colour of sky, haze, light and clouds, and how far the
city's night is on (windows, lamp glow, real lamp lights: `dusk` 0.65, `night` 1). It overrides the drives' own night.
`--presets=a,b,c` with `--shots` takes every preset at each view in one run.
| Preset | What |
|---|---|
| morning | low sun from the east (16 deg), cool morning mist (densest haze), few clouds |
| noon | high white sun (64 deg), short shadows, flat bright smog |
| day | the look's day (40 deg), as in the first pictures |
| golden | late afternoon: low orange sun from the west (11 deg), long shadows, amber haze |
| dusk | sun just down (3 deg): pink-orange west, blue east, windows and lamps coming on |
| night | the look's night |
| overcast | a grey lid: weak sun, strong soft light from everywhere, thick haze, the sky all cloud |
Cost: nothing per pixel beyond the look itself (only numbers change); a preset change redraws the sky's reflection
map once (and the small sky map of job 5). Pictures: `review/look_18nov/times/<view>_<preset>.jpg`, `sheet_<view>.jpg`.

## Job 2: the upscaler (`--upscale=1 --sharp=0.2`)
How it works (docs/engine, patch `c_sgsr1_mobile_upscaler`, part of `all1` / `all3` / the phone's `coronado_all7`):
the viewport's `scaling_3d_mode = FSR` (FSR 1), which the stock Mobile renderer refuses (it falls back to bilinear
with the warning "FSR1 3D scaling is only available when using the Forward+ renderer"), runs Snapdragon Game Super
Resolution 1 in the patched engine: one raster pass at the SCREEN's size that scales the 720p picture up and sharpens
edges (edge-direction mode). `fsr_sharpness` 0 (sharpest) .. 2 (softest) maps to SGSR's edge sharpness 2.1 .. 1.1.
Rig: `--upscale=1` sets the mode, `--sharp=` the sharpness (default 0.2, the engine's default). On a stock engine the
option does nothing but print that warning once.
Cost: today the tonemap pass writes the screen directly (bilinear). With SGSR it writes the 720p picture (1640 x 720)
and SGSR then draws every screen pixel (2460 x 1080, 2.66 MP) with one texture read, plus four gathers on edge pixels
only. So: one extra full-screen pass at the screen's size. My guess 0.5-1 ms on the Mali-G610, not measured; it
competes with simply drawing 3D at more lines (e.g. `--scale=0.75`), which is the honest comparison.
WHAT TO TEST ON THE PHONE (PC session; the app is already built with `coronado_all7`, no rebuild):
1. The log's first lines: the engine line says `coronado_all7` and the rig's `start` line says `upscale=1`; logcat
   must NOT show "FSR1 3D scaling is only available" (if it does, the build lacks patch c).
2. `--plan=zones --upscale=0` and `--plan=zones --upscale=1` (twice each: two identical runs differ by ~7 frames over
   33 ms). Compare the medians and frames over 16.7 / 33 ms per zone.
3. If 2 costs little: `--plan=zones --upscale=1 --scale=0.6` (draws 650 lines instead of 720, upscaled): does it win
   back the cost and still look as sharp as plain 720p?
4. Pictures on the phone: `--shots=user://look_up --fullsize --look=day --upscale=0` and the same with `--upscale=1`,
   then with `--sharp=0.0` and `--sharp=0.6`; `adb pull` the app's `files/look_up` folder. Look at thin things:
   road lines far away, power wires, railings, window frames, tree edges.
Cloud pictures: see "Job 2 in the cloud" below (if the patched Linux engine built in time).

## Job 3: the lamps' glow (`--glow=1|0`, on with the look)
The bake draws every lamp as a halo at its head and a pool of light on the ground (`rt_glow.gdshader`, two
MultiMeshes a cell, only at night). The look now draws the same quads with its own shader
(`tools/city/look/glow.gdshader`, put on each cell's two glow nodes when the cell comes in, `look.gd attach_stream`).
- halo: a hot small core + a wide soft glow + a faint haze, instead of a flat white disc; street lamps shifted
  towards sodium orange (the cool lot lights stay white); pulled 0.4 m towards the camera so it no longer cuts into
  the lamp head and the wall behind it with a hard line.
- pool: lifted 0.18 m (kerbs and pavements no longer slice it with a straight edge), a light-like falloff that
  reaches 0 at the edge, 15 % smaller.
- both fade with distance like the night haze, so far lamps no longer shine as bright as near ones.
Cost: per pixel a few more arithmetic steps (three exp in the halo, one in the pool), no texture read, the same
additive blend; halo quads 1.8 x wider (3.2 x the area, but they are small), pool quads 0.85 x (0.72 x the area: the
pools are the big ones that overlap along every street, the centre's main glow cost, so the total should be a bit
LOWER than before). No extra draw. The new shader compiles the first time a cell with lamps comes in (a one-off hitch;
the game's warm-up should include it). The same change written for `rt_glow.gdshader` itself:
`docs/look_patches/glow.md`. Pictures: `review/look_18nov/glow/<view>_night_glow0.jpg` (old) against
`review/look_18nov/times/<view>_night.jpg` (new).

## Job 4: soft shadows beyond the sun shadow (`--blobs=1`, OFF by default)
Sun shadows end at 50 m, so every tree farther away stands on bright ground. `tools/city/look/blob_shadows.gd` finds
a loaded cell's trees in what the cell already holds (instanced plants: their positions; merged plants: the foot each
vertex carries in CUSTOM0) and adds one MultiMesh of soft blobs (`blob.gdshader`): a multiply blend that darkens the
ground, moved away from the sun by the crown's height and stretched for a low sun, fading in from 38 m (where the
real shadow fades out) and out with the haze; strength follows the time of day (none at night, faint when overcast).
Cost on screen: one draw per cell with trees (measured: +5 to +8 draws a view, 77 -> 84, 99 -> 107, 70 -> 78, 60 -> 65), only far blobs reach the pixel stage (nearer ones
are collapsed in the vertex shader), small quads, a few arithmetic steps, no texture read.
Why OFF: finding the trees reads every foliage mesh back from the GPU when the cell comes in (tens of ms a cell):
fine for pictures, a hitch on the phone, and it would spoil the streaming measurements. The bake should record the
trees instead (then it costs nothing at load): `docs/look_patches/blob_shadows.md`. Parked cars: the cell has their
stalls already; the note says how they would get a blob too. Pictures: `review/look_18nov/blobs/<view>_<noon|golden>_blobs.jpg`
against `times/<view>_<noon|golden>.jpg`.

## Job 5: sky reflections for glass, and wet ground (`--wet=0..1`)
- `ck_sky_map`: the look draws its own sky into a 128 x 64 panorama (`sky_map.gdshader`, the same maths as the sky:
  `sky_common.gdshaderinc`) whenever the time of day changes: 8,192 pixels once, never per frame.
- `tools/city/look/sky_reflect.gdshaderinc`: the snippet for the building session. `ck_sky_reflect()` gives the sky
  seen in a surface with a Fresnel term (for glass: `EMISSION += ck_sky_reflect(NORMAL, VIEW, INV_VIEW_MATRIX, 0.04,
  glass_mask)`); `ck_wet_ground()` makes ground darker, smoother and puts the sky in the puddles, scaled by `ck_wet`.
  Why a map of our own: the engine's sky reflection is one cube-map read in EVERY lit pixel (rough walls and asphalt
  included, where it is nearly invisible). With `--reflect=0` that read is gone everywhere and only glass (and wet
  ground, when it rains) reads the map: one read of a 32 KB texture on those pixels only.
- The building session's glass today reflects a two-colour gradient (`ck_look_sky_top` / `_horizon`); the look now
  sets those two to its own sky on every time-of-day change, when they exist (their branch). Swapping their gradient
  for `ck_sky_reflect()` would give clouds and the sun's glow in the glass for one texture read.
- `--wet=0.8` (DEMO): the cells' ground drawn by `demo_wet_ground.gdshader` = `rt_ground.gdshader` + two marked lines;
  puddles from the look's noise texture (one more read per ground pixel) + the sky map (one more). The ground covers
  most of the screen, so rain costs two reads a pixel on most of the screen: a mood for the game's rain, not for
  every day. The real change goes into `rt_ground.gdshader` (the building session's): the two `WET` lines.
  Pictures: `review/look_18nov/wet/pair_<view>_<overcast|dusk>.jpg` (dry above, wet below). In the cloud it reads
  gently (a sheen and puddle patches towards the far end, pavements catch the sky); no extra draw. Stronger: raise
  `--wet` or the 1.3 in `ck_wet_ground()`.
- Not done: a reflection of the city itself in the puddles (needs screen-space reflection: a full-screen pass, ruled
  out), rain drops, wet walls.

### Job 2 in the cloud (done: a Linux engine with patch c was built here)
`/e/godot` at 4.7.2-stable + `docs/engine/patches/c_sgsr1_mobile_upscaler.patch` only, `scons platform=linuxbsd
target=template_debug disable_path_overrides=no` (33 min on 4 cores; not kept: the cloud is wiped). The same rig, the
same views, screen 2460 x 1080 (the Redmi's), 3D drawn 720 lines high (rig default, scale 0.667), `--look=day`,
`--fullsize`: `--upscale=0` (today: bilinear) against `--upscale=1 --sharp=0.2`. The engine printed no "FSR1 ... only
available" warning, so SGSR ran.
Pictures: `review/look_18nov/upscale/<view>_day.jpg` and `<view>_day_sgsr.jpg` (full size), `crop_<view>.jpg` (two
areas zoomed 2 x, bilinear left, SGSR right). Sharpness (mean brightness step between neighbouring pixels in the
crop; `tools/city/look/upscale_sheet.py`), bilinear -> SGSR: centre 8.11 -> 10.52 and 2.11 -> 2.50, apartments 5.74
-> 7.11 and 8.48 -> 10.34, gritty 5.71 -> 7.22 and 5.79 -> 7.43, waterfront 4.49 -> 5.47 and 5.39 -> 6.56: 18-30 %
sharper everywhere; leaves, signals, wires and edges visibly crisper, no ringing seen at this sharpness. The JPEGs grow
14-17 % (more fine detail). Times in the cloud mean nothing for the phone: its cost is still to be measured there.

---------------------------------------------------------------------------------------------------------------------
# Queue 2 (18 Nov, night): the day, the sky, the sea, weather, life, cars, the phone runs
| Job | Switch | Pictures | What it adds per pixel |
|---|---|---|---|
| 1 running day | `--cycle=120 --clock=7` (shots: `--hours=...`) | `day/sheet_*.jpg` (12 hours, waterfront and centre) | nothing: numbers. Sky and sky map step every 0.5 s; one step 0.44 ms on the main thread (cloud); the engine's sky reflection map is redrawn over several frames (`Sky.PROCESS_MODE_INCREMENTAL`). The sky map's own redraw read 0 ms in the cloud (its timer does not see so small a pass): the phone line `RIG look running day: ...` tells |
| 2 sun, moon, stars | `--celestial=1` (0 = before) | `celestial/pair_*.jpg` | sky pixels only: a few sums; one texture read on the moon's own pixels |
| 3 the sea | `--sea=1` (0 = the green plane) | `sea/pair_*.jpg` | 3 reads per water pixel (2 ripples, the sky map), unshaded; one draw, ~33k triangles |
| 4 weather | `--weather=mist\|hazy\|storm\|rain` | `weather/sheet_*.jpg` | numbers only; rain: the wet ground (2 reads a ground pixel) |
| 5 life in the air | `--air=1` (off) | `air/pair_*.jpg` | one draw of small see-through quads, no texture |
| 6 car paint | `--cars=1` (demo), `--carenv=1\|0` | `cars/pair_*.jpg` | none extra: the game's car shader reads its panorama anyway; the look supplies it (128 x 128 once per time change) |
| 7 phone runs | | `docs/LOOK_PHONE_TESTS.md` | |

Notes:
- Running day: nothing steps at once. Lamp glow, windows and the real lamps follow `ck_night`, which is blended. The
  one thing that does switch: the streamer shows a cell's glow nodes when `ck_night` passes 0.02 (in the same frame
  for all loaded cells); they draw nothing at that moment (glow 0 below 0.15), but it is the first draw of their
  material. If the phone shows a hitch at dusk, show them earlier, a few cells a frame (streamer, not mine).
- The moon: a fixed direction (40 degrees up, south-west), the same direction the night's light had before, so the
  night preset did not change; the light swings from the sun to the moon with the blend.
- FOUND and fixed on the way: the sun's east and west were swapped (morning sun in the west). The first time-of-day
  pictures (`times/`) still show the old sides; the moods in them are right.
- The sea: from `coast.json` (its "sea" line is the island's outline) and the terrain's depths; it reaches 25 m onto
  the land so the waterline is where the water cuts the beach (the 0 m contour the shore foam follows): no seam to
  close, nothing to edit in `x_shore_foam`. Ponds left out (they lie at land height, outside the city's cells).
- Air: the smoke rises from the steel mill's chimney (found once offline at -704.7, 20.2, -1470), steam from a
  warehouse vent; gulls circle off the waterfront promenade; the plane crosses every 120 s for 60 s.
- Cars: the sky map's lower half is now the street (dimly lit asphalt), so car sides reflect a dark street, not haze.

# Queue 3 (18 Nov, night): what a real graphics card showed
The PC session's pictures on an NVIDIA card (sun shadows, sky reflections): night, dusk, overcast good; the DAY one
flat beige wash, no blue, no cloud shapes, jacaranda purple and brick red gone grey-green, murky; golden hour brown.
## Job 1: the numbers (`tools/city/look/measure.py`)
Cloud pictures (darker than a real card; compare them with each other): before = the old look, after = the look's day.
| picture | bright | contrast | sat % | sky sat % | black % | white % |
|---|---|---|---|---|---|---|
| sky/centre_day_before.jpg | 96 | 178 | 26 | 35 | 3.8 | 0.0 |
| sky/apartments_day_before.jpg | 101 | 177 | 26 | 45 | 0.6 | 0.0 |
| sky/gritty_day_before.jpg | 108 | 168 | 25 | 42 | 0.5 | 0.0 |
| sky/waterfront_day_before.jpg | 127 | 155 | 21 | 42 | 0.3 | 0.0 |
| sky/centre_day_after.jpg | 88 | 141 | 28 | 20 | 0.0 | 0.0 |
| sky/apartments_day_after.jpg | 92 | 174 | 32 | 31 | 0.0 | 0.0 |
| sky/gritty_day_after.jpg | 97 | 149 | 29 | 18 | 0.0 | 0.0 |
| sky/waterfront_day_after.jpg | 116 | 162 | 25 | 13 | 0.0 | 0.0 |
| times/centre_golden.jpg | 72 | 159 | 44 | 33 | 0.0 | 0.0 |
| times/centre_morning.jpg | 88 | 135 | 19 | 15 | 0.0 | 0.0 |
| times/centre_noon.jpg | 94 | 158 | 23 | 19 | 0.0 | 0.0 |
| times/centre_overcast.jpg | 86 | 162 | 19 | 19 | 0.0 | 0.0 |
| times/centre_dusk.jpg | 42 | 111 | 38 | 34 | 0.1 | 0.0 |
| times/centre_night.jpg | 29 | 106 | 43 | 40 | 1.5 | 0.0 |

By day the look is about 10 % darker, its contrast lower (mean 157 against 170) and the SKY's saturation halved
(13-31 % against 35-45 %): the beige wash in numbers. Golden is saturated (44 %) but dark: its trouble is the brown haze.
## Job 2: three days to choose from (`--look=day` default unchanged, `day_half`, `day_clear`)
Each preset can pick its own colour table now (`grade`: `gta`, `half`, `clear`; all three built at start, ~10 ms
each; the running day keeps `gta`, switching tables would be a visible step). `day_half`: half the haze (fog 0.00085),
half the held-back colour. `day_clear`: blue sky, haze only low at the horizon (fog 0.0007), colours kept (no
desaturation, a gentle S-curve). Pictures: `variants/sheet_<view>.jpg` = old look | day | day_half | day_clear.
## Job 3: clouds seen from the street
Two new sky values: `cloud_low` (where clouds melt into the haze; 0.2 before, 0.06-0.1 in the new days, so they reach
down between the buildings) and `cloud_soft` (edge width; 0.24 before, 0.16-0.2: crisper shapes). Same shader, same
two reads; the default day keeps its values.
## Job 4: golden and morning
Golden: haze thinner and lighter (fog 0.0019 -> 0.0011, haze colour pale gold instead of brown), the sun lower (9 deg)
and stronger (1.85, deep orange), the shade bluer (warm walls against cool shade), the "half" table. Morning: the same
idea, mist halved (0.0028 -> 0.0016). Pictures: `variants/<view>_golden.jpg`, `_morning.jpg` against `times/`.
## Job 5: the sun shadow's end (`--shadowtune=1`, 0 = before)
The 50 m stay. 2 splits instead of the engine's 4 (two shadow passes less), the first to 12.5 m, blended where they
meet; the shadow fades out from 30 to 50 m (`directional_shadow_fade_start` 0.6); softer for a low sun
(`shadow_blur` 1.8 at the horizon .. 1.0 above 45 deg), fainter when the sun is weak (`shadow_opacity` 0.3 + energy x 0.5:
overcast and storm throw faint shadows). Pictures with shadows on: `shadow/pair_*.jpg` (the cloud GPU draws the trees
near the camera black with shadows on: ignore them, look at the road).
## Decided (Yasin, 18 Nov): "i go for gta4 look"
The default day keeps the GTA 4 palette. `day_half` and `day_clear` stay as named presets, not the default. Inside the
palette: the day's clouds now reach lower and have crisper, darker-bottomed shapes so they read from the street
(`cloud_low` 0.1, `cloud_soft` 0.18), the sky colours unchanged; golden and morning use the GTA table again (their
lighter haze and warm sun stay). Pictures with sun shadows on (2 splits: the cloud draws them now):
`review/look_18nov/gta/<view>_<day|golden|morning>.jpg`. The bake now includes the tier work's far ground (ran fine
on the cloud's GPU, 83 s; no `--nofarground` needed).

### Queue 3 results (cloud)
| Day (4 views, mean) | bright | contrast | sat % | sky sat % |
|---|---|---|---|---|
| old look (`sky/*_day_before`) | 108 | 170 | 25 | 41 |
| `day` (default) | 99 | 157 | 29 | 21 |
| `day_half` | 95 | 167 | 29 | 30 |
| `day_clear` | 95 | 172 | 27 | 40 |
| `golden` (queue 3, sun at 9 deg) | 73 | 169 | 45 | 31 |
| `morning` (queue 3) | 95 | 182 | 24 | 17 |
- `day_clear` gets the sky's colour and the contrast of the old look back (sky 40 % against 41), keeping the haze
  towards the horizon; `day_half` sits between. Sheets: `variants/sheet_<view>.jpg` (old | day | day_half | day_clear).
- Golden at 9 degrees put most of the street in the shade and measured darker (73 against 83): raised to 12 degrees,
  shade light 0.6 -> 0.75 (the `variants/*_golden.jpg` pictures are re-rendered with it): bright 75, contrast 168,
  sat 44, sky 30. It still measures a little darker than queue 2's golden (83), but that one had the sun on the wrong
  side (in front of most views, a bright sky in the picture); now the sun is behind the east-facing views and lights
  the walls warm against blue shade, with blue sky between the clouds (`variants/pair_*_golden.jpg`).
- FOUND: with `--shadowtune=1` (2 splits) the cloud's software GPU draws the near trees properly WITH sun shadows on
  (`shadow/pair_apartments_golden.jpg`); with the engine's 4 splits they came out black. The "trees black with
  shadows" cloud flaw is tied to the 4-split mode. Cloud pictures can have shadows from now on.

### In the GTA palette, with sun shadows (cloud, 4 views)
| preset | bright | contrast | sat % | sky sat % |
|---|---|---|---|---|
| day (clouds readable from the street) | 89 | 169 | 25 | 20 |
| golden (GTA table, shade 0.92 warm-grey) | 71 | 171 | 26 | 25 |
| morning (GTA table) | 91 | 187 | 23 | 18 |
With real shadows the low golden sun leaves most streets in shade: the warm light falls on tree tops and the walls
that face west (`gta/sheet_*.jpg`); the shade was lifted (0.75 -> 0.92) so the street does not sink. Darker than the
day is right for a low sun; judge it on the phone.
