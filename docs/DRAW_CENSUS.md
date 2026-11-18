# Drawing census on the phone (19 Nov 2026)

Yasin: "queue the drawing cost census". Where a frame's graphics (GPU) time goes on the Redmi (Mali-G610), one thing
changed at a time, so that the next performance work is chosen from numbers. Nothing was fixed and no default changed.

## How it was measured
- `tools/city/rig/rig.gd --plan=census`: the camera STANDS at a street-level viewpoint (centre 0,-600; apartments
  250,-600; gritty -600,-1000; waterfront 570,200; industrial -800,-1400; pilot 0,0; civic -200,-600), waits until the
  place is ready and nothing loads, then goes through states, each the baseline with ONE thing changed, measured for
  2 s after 0.5 s to settle. Per state: median and 95 % GPU ms, CPU draw ms, draws, triangles. Baseline first and last.
  Options: `--census=day|night|both --views=a,b --censussecs=2 --warmnight`. All states in one app run.
- New switches for it, none baked in, none on by default: `CK_CHEAP` (colour-only fragment: rt_bldg, rt_prop,
  rt_foliage) and `CK_OPAQUE` (plants without the cut-out), made at runtime by `city_stream.gd shader_variant()`.
- Runs (`review/phone/`): `census_day` (720p, before the look and the growth were merged), `census_full_day` (full
  screen, with the look), `census_x15_day` (1.5 x full screen, with the look: THE ONE TO READ), `census_x15_night`,
  `census_night_720`, `census_warmnight`, and `census_gate_stream` (the stream gate on the merged build: PASS).
- Also in this job: `city_stream.gd` `add_ms` / `ready_ms` now keep the last 4,096 numbers (a 25-minute soak grew them
  without end); the rig counts across the cut.

## READ THIS FIRST: why the 720p numbers do not show costs
The phone lowers its GPU clock whenever it can still make 60 fps. At 720p the measured GPU time stays near 13-14 ms
whatever is switched off: half the pixels (`scale_0.50`) saved 0.0-0.3 ms; 2.25 times the pixels cost 0.1-1.3 ms in most
places (table at the end). So "the GPU needs 13-14.5 ms of 16.7" at 720p does NOT mean the phone is near its limit; how
much room there really is was not measured. To see costs the GPU must be fully busy: the census was run again at
1.5 x the full screen (3690 x 1620, about 4.5 x the pixels of 720p), where no view makes 60 fps. Even there:
- the phone warmed from 32.7 to 36.4 C during the day run, and in four of seven views the baseline moved by 2-7 ms
  between the start and the end (centre 30.9 -> 33.1, industrial 30.2 -> 23.7, pilot 28.5 -> 30.2, civic 35.5 -> 37.2):
  their small differences are noise. Three views held (apartments 40.9 / 40.9, gritty 26.3 / 26.3, waterfront
  30.9 / 30.9): read those.
- Pixel costs at 1.5 x are about 4.5 times what they are at 720p; vertex and CPU costs are the same.
- One run each. Differences under about 0.5 ms are not meaningful.
- FOUND: switching the sky reflection off and on again left the GPU about 28 ms a frame slower (17 -> 45 ms at full
  screen, 10 -> 22 ms at 720p) until the next teleport. The state now runs last. Not explained; worth knowing for
  anything that changes the environment at runtime.

## Day, 1.5 x full screen, with the look (`census_x15_day`): GPU ms saved per frame against the baseline
Baseline rows: the GPU ms itself. `baseline_end` = the baseline again before the sky reflection state.
```
saving in ms of GPU per frame against the baseline (baseline rows: the GPU ms itself)
state                    centre  apartments      gritty  waterfront  industrial       pilot       civic
baseline                  30.93       40.92       26.28       30.87       30.22       28.45       35.45
hide_plants               +0.78      +10.89       +3.43       +0.57       -0.47       +5.73      +15.17
hide_props_near           +0.52       +2.56       +1.30       +0.37       -0.08       +1.42       +1.12
hide_props_mid            +0.01       +0.40       +0.21       -0.09       +0.34       +0.04       -1.82
hide_props_other          -0.01       +0.10       +0.04       -0.08       +0.07       -1.63       -0.70
hide_bldg_near            +0.16       +7.02       +3.29       +0.68       -0.13       -1.74       -1.12
hide_bldg_mid             +0.02       +0.20       +0.31       -0.01       +0.26       -2.10       -1.47
hide_ground               +0.01       +0.52       +0.65       -0.12       +0.09       -2.05       -1.23
hide_wear                 +0.36       +1.92       +1.86       -0.04       -0.25       -1.96       -0.93
hide_far                  +0.06       +0.50       +0.71       -0.09       -0.28       -2.11       -1.42
hide_far_ground           +0.00       +0.19       +0.17       +0.00       +0.05       -2.29       -1.84
hide_misc                 +0.02       +0.09       +0.07       -0.05       +0.16       -2.17       -0.79
shadows_off               +0.95       +4.91       +3.36       +0.62       +0.01       -2.12       -1.33
shadow_map_2048           +0.00       +2.36       +2.00       +0.72       -0.34       -2.04       -1.02
shadow_map_1024           +0.05       +3.09       +2.54       +0.53       -0.03       -2.18       -1.74
fxaa_off                  +0.66       +3.85       +3.64       +1.07       +0.38       -1.18       -0.52
scale_0.50                +1.99       +5.60       +5.58       +2.17       +5.16       -0.42       -0.03
scale_0.67                +1.91       +5.78       +4.20       +2.01      +20.62       -0.63      +20.89
scale_0.85                +1.31       +4.61       +3.86       +1.48      +18.30       -1.42      +17.38
scale_1.00                +1.29       +4.90       +4.28       +1.60      +16.61       -0.75      +13.47
cheap_bldg_mid            -1.48       +0.22       +0.15       +0.01       +6.65       -2.26       +0.41
cheap_bldg_all            -0.17       +3.83       +2.50       +0.27       +7.19       -2.21       +0.78
cheap_props_mid           -2.19       +0.16       +0.08       +0.00       +6.55       -2.28       +0.27
cheap_plants_mid          -2.05       +0.65       +0.19       -0.05       +7.05       -1.97       -1.54
plants_opaque             +0.65       +3.97       +2.76       +0.68       +7.57       -1.56       -1.18
look_parts_off            -1.86       +0.62       +0.42       -0.03       +6.71       -1.84       -0.46
look_contact_off          -2.14       +0.01       +0.04       -0.04       +6.55       -1.87       -1.91
look_windows_off          -2.00       +0.12       +0.05       -0.13       +6.49       -1.84       -1.64
look_glass_off            -1.89       +0.32       +0.22       +0.00       +6.59       -2.28       -1.90
look_detail_off           -2.05       +0.28       +0.17       -0.05       +6.69       -2.20       -1.86
look_signs_off            -2.10       +0.02       +0.08       -0.03       +6.58       -1.78       -1.96
look_propmaps_off         -2.10       +0.14       +0.04       -0.06       +6.55       -2.13       -1.60
look_between_off          -2.10       +0.04       +0.06       -0.01       +6.62       -2.33       -1.87
baseline_end              33.06       40.89       26.25       30.93       23.66       30.18       37.22
sky_reflection_off        +0.69       +5.07       +3.16       +0.53       +7.61       -2.22       -1.47
baseline_after_reflection       33.07       40.91       26.20       30.92       23.68       30.36       37.32
draws / tris(k) / cpu draw ms at baseline: centre 103/772/2.8, apartments 118/918/2.8, gritty 100/544/2.5, waterfront 112/761/2.6, industrial 96/530/2.5, pilot 79/538/2.4, civic 106/546/2.9
```

## Night (`census_x15_night`, 1.5 x; `census_night_720`, 720p)
| State | centre 1.5x | apartments 1.5x | gritty 1.5x | centre 720p | apartments 720p |
|---|---|---|---|---|---|
| baseline GPU ms | 36.8 | 40.7 | 25.2 | 12.3 | 14.8 |
| lights 0 (of 20) | +0.2 | +1.5 | +0.9 | +0.8 | +0.2 |
| lights 1 | -0.3 | +0.9 | +0.7 | +0.5 | +0.2 |
| window glow off (the bake's emission) | -0.1 | +1.4 | +0.8 | +0.2 | +0.2 |
| look windows off | +0.3 | +0.6 | +0.3 | +0.1 | +0.2 |
| look signs off | +0.1 | +0.3 | +0.2 | 0.0 | +0.1 |
| lamp halos and pools hidden | +0.1 | +0.1 | 0.0 | 0.0 | 0.0 |

THE FIRST NIGHT (the 40-49 ms half second found in the tier work). GPU ms of the first frames after day turns to night:
- 720p, first dusk of the session (centre): 11 32 33 15 12 ...; worst frame 41 ms. The SECOND dusk: 12 13 14 13 ...,
  worst frame 24 ms. At 1.5 x: 30 120 117 117 115 95 83 83 81 56 44 44, the second time 37-42.
- It happens once a session: what is built or loaded the first time the night is drawn (the look's night shaders,
  window and glow textures, the lights' shader versions), not the drawing itself.
- `--warmnight` (draw the night 20 frames behind the loading screen, then day again): first dusk 12 14 15 13 ...,
  worst frame 19 ms (`census_warmnight`). IT IS GONE.
- APPLIED (Yasin: "Yes, add it"): the rig draws the night once in its warm-up by default (`--nowarmnight` to compare);
  0.5 s more behind the loading screen. Phone, `warmnight_zones`: centre and gritty at night with no frame over 33 ms
  (before: 9 frames over 33, two of 52 ms in `tiers_off_zones`). The game should do the same in its own loading.
  The zones gate still FAILS, on something new: the teleport to the gritty edge at night took 3.6 s (limit 3 s) and a
  collision body waited 4.8 s. The first growth's pieces south of the gritty edge nearly doubled the collision there
  (123k -> 236k units in that drive), and the streamer makes 1,200 units a frame. Not a drawing matter; not changed.
  `warmnight_stream`: STREAM HEALTH PASS.

## What costs most, and what removing or cheapening it would give (apartments / gritty, 1.5 x)
1. **Trees and plants: 10.9 / 3.4 ms** (27 % / 13 %); in civic 15 ms, pilot 5.7 ms. The biggest single cost. Of it,
   **the cut-out leaves are 4.0 / 2.8 ms** (`plants_opaque`: the same plants drawn solid). Merging them further would
   not help (they are already merged per 64 m / per cell; that saves CPU, not GPU). What would: fewer and tighter
   cut-out cards, a solid inner crown, an earlier switch to the mid tier, fewer trees in the sun shadow
   (`docs/TREE_ARTIST_BRIEF.md`, for the new tree models).
2. **Near buildings: 7.0 / 3.3 ms.** Their full shader (normal map, ORM, grime, the look's parts) is 3.8 / 2.5 ms of it
   (`cheap_bldg_all`); the rest is their geometry and pixels.
3. **Sun shadows: 4.9 / 3.4 ms** (`shadows_off`). A smaller shadow map: 1024 saves 3.1 / 2.5, 2048 saves 2.4 / 2.0.
4. **Sky reflection: 5.1 / 3.2 ms** (one cube-map read a lit pixel; measured last, see above).
5. **FXAA: 3.9 / 3.6 ms** (a full-screen pass; at 1.5 x it is large, at 720p about a quarter of it).
6. **Near props: 2.6 / 1.3 ms.**
7. **Wear marks on the ground: 1.9 / 1.9 ms**, a lot for what they are (thin decals over the ground: overdraw).
8. Each under 1 ms: ground 0.5 / 0.7; far world 0.5 / 0.7; mid buildings 0.2 / 0.3; mid props 0.4 / 0.2; far ground
   0.2 / 0.2; everything else (misc) 0.1; other props 0.1.
9. **The mid tier made colour only (as SPEC says) saves almost nothing:** buildings 0.2 / 0.2, props 0.2 / 0.1, plants
   0.7 / 0.2. The baked mid buildings DO run the full rt_bldg (the bake makes 8 building materials, shared by near and
   mid, all with normal, ORM and window glow on), but the mid tier covers few pixels. Not worth a change.
10. **The look's building parts are cheap:** all of them together 0.6 / 0.4 ms; each alone under 0.3.
11. **The waterfront** costs 30.9 ms, yet no kind of city object takes more than 1.1 ms of it: the cost is in something
    without a census switch, most likely the look's sea or sky. Not measured (`--sea=0` would tell).
12. **Resolution:** at 1.5 x, drawing half the pixels saved only 5.6 ms of 41 in the apartments: much of the frame there
    did not scale with pixels (918k triangles, the shadow pass). A lead, not a result (heat, clock).
13. **At night:** the 20 lights 0.2-1.5 ms, window glow and the look's windows and signs 0.1-1.4 ms, halos nothing.
    The cost of night is the first dusk (above), not the night itself.
CPU: the draw itself took 2.4-2.9 ms of CPU at 1.5 x (1.1-2.8 at 720p); 79-128 draws a view.

## What could not be measured
- A depth pre-pass for the cut-outs: the Mobile renderer has none (Godot draws one only in Forward+).
- A RELEASE build: not made (Yasin: "dont make the release build yet"). All numbers are from the debug build.
- The look's whole sky, haze and grade against no look: the look cannot be switched off inside a run, and a
  `--look=0` census was not run. Its shader parts were measured (above).
- The look's sea, the sky shader itself, bloom (off by default), the cars and the air: no census state.
- Near plants against mid plants, and plants without shadows: not separated (Yasin chose to finish here).
- How far the phone is from its limit at 720p cannot be read from GPU time on this phone (clock). Frame time at the
  vsync step and heat over a long drive are the measures that count there.

## 720p for the record (`census_day`, before the look and the growth; GPU clock not at its top, see above)
```
saving in ms of GPU per frame against the baseline (baseline rows: the GPU ms itself)
state                    centre  apartments      gritty  waterfront  industrial       pilot       civic
baseline                  10.08       14.21       13.63       13.90       13.68       13.91       14.07
hide_plants               +2.17       +0.77       -0.10       +0.20       +0.53       +0.40       +1.03
hide_props_near           +1.89       +0.32       +0.06       +0.01       +0.37       -0.04       +0.09
hide_props_mid            +0.03       -0.03       -0.11       +0.10       +0.00       +0.10       +0.01
hide_props_other          -0.03       -0.04       -0.13       +0.11       +0.00       +0.12       +0.10
hide_bldg_near            +0.35       +0.25       -0.13       +0.05       +0.50       -0.08       +0.07
hide_bldg_mid             +0.14       +0.03       -0.11       +0.03       +0.14       +0.07       -0.04
hide_ground               +0.62       +0.01       -0.30       -0.08       +0.13       +0.03       +0.04
hide_wear                 +0.37       +0.08       -0.08       +0.05       +0.30       -0.01       +0.24
hide_far                  +0.19       -0.01       -0.09       +0.08       +0.17       +0.19       +0.01
hide_far_ground           -0.01       +0.02       -0.13       +0.08       +0.07       +0.18       +0.09
hide_misc                 -0.04       -0.02       -0.20       -0.02       +0.04       +0.10       +0.08
shadows_off               +1.17       +0.25       +0.58       -0.11       +0.49       +0.51       +0.17
shadow_map_2048           -0.10       +0.03       +0.10       +0.18       +0.18       +0.23       +0.11
shadow_map_1024           +0.14       +0.16       +0.26       -0.31       +0.48       +0.26       +0.24
fxaa_off                  -0.16       +0.44       -0.21       +0.04       -0.01       +0.11       +0.39
sky_reflection_off       -11.30       +0.10       +0.02       -0.02       +0.55       +0.09       +0.25
scale_0.50               -10.63       +0.31       +0.00       +0.08       +0.30       +0.13       +0.28
scale_0.85               -12.10       -2.80       -0.52       -0.45       -0.35       -0.24       -0.70
scale_1.00               -12.07       -5.26       -0.38       -1.26       -0.08       -0.35       -2.73
cheap_bldg_mid           -11.87       -0.01       -0.20       -0.01       +0.03       +0.20       +0.01
cheap_bldg_all           -11.60       +0.12       -0.12       -0.06       +0.09       +0.18       +0.26
cheap_props_mid          -12.03       -0.03       -0.10       +0.00       +0.07       +0.10       +0.19
cheap_plants_mid         -11.93       +0.01       -0.11       +0.20       +0.14       +0.11       +0.21
plants_opaque            -11.45       +0.26       -0.18       -0.08       +0.24       +0.11       +0.22
baseline_end              22.08       14.14       13.65       13.73       13.66       13.90       14.11
draws / tris(k) / cpu draw ms at baseline: centre 98/777/1.1, apartments 111/1027/2.3, gritty 94/504/2.7, waterfront 108/905/2.7, industrial 91/401/2.7, pilot 77/615/2.7, civic 99/563/2.8
```
