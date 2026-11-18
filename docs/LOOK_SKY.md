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
