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
