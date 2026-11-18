# Look pack: the phone runs, in order (for the PC session, 18 Nov)

The day look is decided (Yasin: "i go for gta4 look"): the runs below use the default day; no day-variant runs.

Every switch of the look pack (branch `claude/look-sky`, `docs/LOOK_SKY.md`, `docs/LOOK_OVERVIEW.md`) measured on the
Redmi one change at a time, each against the run before. The cloud cannot measure a phone: these runs are the only
numbers that count. All runs use `tools/city/rig/phone_rig.sh` as for the streaming runs.

## 0. Before the first run
- The look's files (sky, sea, glow, air shaders, `sky_noise.png`, `sea_map.png`) are new: the app on the phone does
  not have them. `run` only changes options; the FIRST run must be `all` (bake + export + install) from a checkout
  that has `claude/look-sky`. Merging is Yasin's call; without a merge, check the branch out in a second worktree:
  `git worktree add ../NewMap_look origin/claude/look-sky`, and run the script from there (it bakes there, ~2.5 min).
  Note: the script commits its results to the branch checked out (`PUSH=0` to keep them local).
- The engine: `coronado_all7` as for the streaming runs (has the upscaler patch c and the light grid).
- Expect `Shader cache miss` lines on the first run of a new shader (sky, sea, glow, air, car env): note them, they
  should not come back on the repeat.

## 1. The runs
`--plan=zones` (9 zones by day at 60 km/h, 7th St at 210 km/h, centre and gritty at night) for everything, so the
numbers sit beside `zones_720` / `zones_final` in `review/phone/`.

| # | Command | Changes against the run before | Compare |
|---|---|---|---|
| 1 | `phone_rig.sh all look0 --plan=zones --look=0` | the new build, OLD look (baseline) | against `zones_final`: must be the same (the build itself changed nothing) |
| 2 | `phone_rig.sh run look_base --plan=zones --look=1 --glow=0 --sea=0 --celestial=0` | sky + haze + light + grade (the first pack) | every zone's median and frames over 16.7 / 33 ms; the waterfront and the night zones most |
| 3 | `phone_rig.sh run look_glow --plan=zones --look=1 --sea=0 --celestial=0` | + the lamps' glow | the two NIGHT zones (centre: many overlapping pools) |
| 4 | `phone_rig.sh run look_sky2 --plan=zones --look=1 --sea=0` | + sun glare, moon, stars | night zones (the moon disc), little else expected |
| 5 | `phone_rig.sh run look_full --plan=zones --look=1` | + the sea = THE DEFAULT LOOK | the waterfront zone (water over most of the picture), 7th St |
| 6 | `phone_rig.sh run look_full2 --plan=zones --look=1` | nothing: a repeat | how much two identical runs differ (last time ~7 frames over 33 ms) |
| 7 | `phone_rig.sh run look_reflect0 --plan=zones --reflect=0` | no engine sky reflection anywhere | should be CHEAPER than 5 (one cube-map read a pixel less); look at the glass on the phone screen |
| 8 | `phone_rig.sh run look_bloom --plan=zones --bloom=1` | + bloom (against 5) | the guess was 1-2 ms: medians, and whether zones fall off the 60 fps step |
| 9 | `phone_rig.sh run look_up --plan=zones --upscale=1 --sharp=0.2` | SGSR upscaler (against 5) | cost of one extra screen-size pass; the log must NOT say "FSR1 3D scaling is only available" |
| 10 | `phone_rig.sh run look_up60 --plan=zones --upscale=1 --scale=0.6` | 650 lines + SGSR instead of 720 + bilinear | does it win the cost back and look as sharp? (pictures, step 2 below) |
| 11 | `phone_rig.sh run look_day --plan=zones --cycle=120 --clock=17.5` | the running day (against 5): 120 s a day, the run passes dusk and night | frames at the day / night change (the old jump cost one 53 ms frame); the line `RIG look running day: sky_map redraw worst gpu_ms=... one step on the main thread worst ... ms` |
| 12 | `phone_rig.sh run look_rain --plan=zones --weather=rain` | rain: wet ground (2 more reads a ground pixel) | every zone (the ground is most of the screen) |
| 13 | `phone_rig.sh run look_storm --plan=zones --weather=storm` | a mood without wet ground | should equal 5 (numbers only) |
| 14 | `phone_rig.sh run look_air --plan=zones --air=1` | gulls, a plane, smoke (one draw, against 5) | waterfront and industrial zones; draws +1 |
| 16 | `phone_rig.sh run look_shadow0 --plan=zones --shadowtune=0` | the sun shadow as before (4 splits, hard end; against 5) | 5 should be the cheaper one (2 shadow passes less); on the screen: is the shadow's end still a line in 5? |
| 15 | `phone_rig.sh run look_blobs --plan=zones --blobs=1` | blob shadows: EXPECTED TO HITCH (meshes read at load) | the streaming health check will likely FAIL: this run only says how bad, the fix is the bake note `docs/look_patches/blob_shadows.md` |

After each run: `python tools/city/rig/health.py` prints PASS / FAIL (the streaming budget); a look change should
not turn a PASS into a FAIL. Copy the `RIG drive` lines of each run into one table in `docs/LOOK_SKY.md`.

## 2. Pictures on the phone (the real look: the cloud draws buildings too dark, no shadows, no sky reflection)
Each `--shots` run takes pictures at fixed views and quits; the files land in the app's own folder. Copy them back:
`adb exec-out run-as com.yasin.citykit.rig tar -c -C files look > look.tar` (then unpack into
`map_dc/coronado/city_kit/review/look_18nov/phone/`).

| Command | What |
|---|---|
| `phone_rig.sh run shots_before --shots=user://look --look=0` | the old look: centre, apartments, gritty, waterfront by day and night |
| `phone_rig.sh run shots_after --shots=user://look --look=1` | the same with the look |
| `phone_rig.sh run shots_times --shots=user://look --presets=morning,noon,golden,dusk,night,overcast` | the six times of day |
| `phone_rig.sh run shots_shadow --shots=user://look --presets=day,golden "--views=centre:-6,-560:0:4;apartments:215,-600:90:5"` and the same with `--shadowtune=0` | the shadow's end, before / after |
| `phone_rig.sh run shots_sea --shots=user://look --presets=day,golden,night "--views=shore:600,200:95:1;waterfront:535,200:75:2;bridge:898,-1098:135:2"` | the sea |
| `phone_rig.sh run shots_weather --shots=user://look --weather=rain --presets=day,dusk` | rain (and the same with `--weather=mist`, `hazy`, `storm`) |
| `phone_rig.sh run shots_up0 --shots=user://look --fullsize --look=day --upscale=0` and `... shots_up1 ... --upscale=1` | upscaler at the full screen size: thin lines, wires, far road marks |
| `phone_rig.sh run shots_cars --shots=user://look --cars=1 --presets=day,golden "--views=cars:168,-601:80:-4"` | car paint and glass with the sky |
| `phone_rig.sh run shots_air --shots=user://look --air=1 --presets=day,night "--views=gulls:600,200:95:10;smoke:-760,-1330:21:10"` | gulls and smoke |

Things to look at on the phone screen (not in a file): the water's ripples moving, the clouds drifting, the running day
(`--cycle=120` on a drive) for anything that jumps, the lamp halos at night, how dark the night is (`NIGHT.ambient_energy`
in `look.gd` is the one number to raise).
