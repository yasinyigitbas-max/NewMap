# The look in the game (18 Nov): what the game calls, what it needs, what it costs

The look is one node, `tools/city/look/look.gd` (a plain `Node`), plus the files beside it in `tools/city/look/`.
The test app (`tools/city/rig/rig.gd`) is the only user so far; this is how the game would take it over. Branch
`claude/look-sky`, not merged. Costs are per pixel of a phone limited by pixels; none is measured on the phone yet
(`docs/LOOK_PHONE_TESTS.md` lists the runs that measure them).

## 1. Setting it up (once, at the start of the game)
```gdscript
const Look := preload("res://tools/city/look/look.gd")
var look := Look.new()
look.sea = true            # the water (needs the game NOT to draw its own sea plane at 0 m; see 4)
look.glow = true           # the lamps' halos and pools
look.cycle = 0.0           # the game drives the clock itself (see 2), or seconds per day for a running day
add_child(look)            # builds sky, haze, sun, colour tables, sky maps, sea; owns the WorldEnvironment and the sun
look.attach_stream(city_stream)   # the streamer: the look restyles each cell as it comes in (glow) and sets ck_night
```
Set the `@export` values BEFORE `add_child` (they decide what is built). `look.env` and `look.sun` are the
Environment and the DirectionalLight3D: the game should not make its own.
Start-up cost: three 16^3 colour tables (~10 ms each, GDScript), the sea mesh (~33k triangles, tens of ms), two
small SubViewports (128 x 64 and, with cars, 128 x 128).

## 2. What the game calls, and when
| Call | When | What it does |
|---|---|---|
| `look.set_hour(h)` | the game's clock moved (every 0.5 s of game time is plenty; NOT every frame) | the look at hour `h` (0..24): sun path, moon, sky, haze, light, the city's night (`ck_night`) |
| `look.cycle = s` | instead of the above: the look runs its own clock, a day in `s` seconds | steps itself every `cycle_step` (0.5 s) |
| `look.set_preset("golden")` | a fixed time for a mission / cutscene | morning, noon, day, day_half, day_clear, golden, dusk, night, overcast |
| `look.weather = "rain"`, then `set_hour` / `set_preset` again | the weather changes | mist, hazy, storm, rain, "" = clear. Mist burns off by the clock; rain wants `wet` (see 4) |
| `look.lights()` | every time the game places its real lamp lights | 0..1, how far the city's night is on (for `city_lights.gd update_lights`) |
| nothing per frame | | the look's `_process` only moves the clouds (one global value) and, with `cycle`, its clock |

Every call above changes numbers only. One call costs about 0.4 ms on the main thread (cloud measure), redraws the
128 x 64 sky map once (8,192 pixels), and makes the engine redraw its sky reflection map (spread over frames when the
look runs a day; a one-off step when the game calls `set_hour` itself: call it at most twice a second).

## 3. Global shader values and project settings it needs
In the game these go into `project.godot` `[shader_globals]` (the test app adds the first four at run time):
| Value | Type | Set by | Read by |
|---|---|---|---|
| `ck_sky_drift` | vec2 | look, every frame | the sky (cloud drift) |
| `ck_sky_map` | sampler2D | look, once | sea, wet ground, glass snippet (`sky_reflect.gdshaderinc`), car env |
| `ck_wet` | float | look | wet ground snippet |
| `refl_env` | vec2 | look (`(1, 0)`) | the game's car shader (`vehicles/car_paint.gdshader`); the game already has it |
| `ck_night`, `ck_wind_dir`, `ck_wind_strength`, `ck_cells_loaded` | | streamer / game | city shaders (already in project.godot) |
| `ck_look_sky_top`, `ck_look_sky_horizon` | color | look, when they exist | the buildings' glass (`claude/look-buildings`) |
No other project setting changes. The upscaler (below) is a viewport setting.

## 4. The parts, what they cost, what is finished
| Part | Files | Per pixel | State |
|---|---|---|---|
| Sky, clouds, sun, moon, stars | `sky.gdshader`, `sky_common.gdshaderinc`, `sky_noise.png` | sky pixels only: 2 texture reads (3 at night), the moon's one only on its pixels | finished |
| Haze | the engine's distance fog (look sets it) | one exp + blend on every surface | finished |
| Light, times of day, weather | `look.gd` PRESETS, `day_cycle.gd`, `weather.gd` | nothing | finished; the day variants wait for Yasin's pick |
| Colour grade | `look.gd` grade tables | one 3D table read per screen pixel, in the last pass that runs anyway | finished |
| Sun shadow's end | `look.gd` (2 blended splits, fade from 30 m) | blending only where the splits meet; 2 splits instead of the engine's 4 = two shadow passes less | finished, not seen with real shadows in the cloud |
| Sea | `sea.gd`, `sea.gdshader`, `sea_map.png` (from `make_sea.py`) | 3 reads per water pixel, unshaded; 1 draw | finished. The game must not draw its own sea plane at 0 m (two planes would flicker); the rig lowers its green stand-in plane 2 m |
| Lamp glow | `glow.gdshader` (put on each cell's glow nodes by the look) | a few sums per glow pixel | works as a swap; the clean way is the patch note `docs/look_patches/glow.md` (in `rt_glow`, owned by the streaming session) |
| Bloom | look `bloom` | a blur chain + 1 read a pixel | off; measure first |
| Upscaler (SGSR) | the viewport: `scaling_3d_mode = FSR` + `fsr_sharpness` | one extra pass at the screen's size | NEEDS YASIN'S ENGINE (patch c, in `coronado_all7`); a stock engine falls back to bilinear |
| Sky map for reflections | `sky_map.gdshader`, `sky_reflect.gdshaderinc` | 1 read on glass / wet pixels | the map is finished; the glass and the ground do not use it yet (two lines each, the building / streaming sessions' shaders) |
| Car paint and glass | `car_env.gdshader` (feeds `env_pano` of the game's car shader) | none extra: the car shader reads its panorama already | finished for the env; the game sets `env_pano` on its car materials to `look.car_map.get_texture()` and creates `car_map` (today only with `cars = true`) |
| Life in the air | `air.gd`, `air.gdshader` | small see-through quads, 1 draw | finished, off until measured; fixed places (waterfront, the steel mill) |
| Wet ground | `demo_wet_ground.gdshader` | 2 more reads per ground pixel | DEMO: a copy of `rt_ground` swapped in; the real change is two lines in `rt_ground` |
| Blob shadows | `blob_shadows.gd`, `blob.gdshader` | small far quads, +5-8 draws | DEMO: reads meshes at load (hitches); needs the bake note `docs/look_patches/blob_shadows.md` |
| Parked cars | look `cars` | one draw a car | DEMO, pictures only |
| Pictures | `look_shots.gd`, `make_pairs.py`, `measure.py`, `upscale_sheet.py` | | tools, not for the game |

## 5. Still open (Yasin's calls)
- Which day: `day` (GTA 4 palette), `day_half`, `day_clear` (`review/look_18nov/variants/`).
- Bloom, upscaler, air: after the phone runs.
- The running day's speed and where the game's clock lives.
