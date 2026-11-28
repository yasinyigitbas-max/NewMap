# Look uplift (28 Nov, branch `claude/look-uplift`)

Yasin, 28 Nov: "tell me how the looks can be improved BY A LOT without adding a lot of performance cost. the world still
looks mostly empty"; "go ahead with all of the queue"; "go for both 15 and 16"; "go on with your queue, then try 30fps
cap". The audit (23 views, day / golden / night) is the artifact "Coronado Look Audit"; its pictures and every
before / after are in `map_dc/coronado/city_kit/review/look_uplift/`.

Branch: cut from `claude/night-28nov` (edd30e9e0), with the night session's r7 and its crowd / holes commits merged in.
Every change is switchable. Nothing locked changed (lock test RESULT PASS, 666 pieces).

## What changed, item by item

| # | Item | Where | Switch | State |
|---|---|---|---|---|
| 0 | Grade test | `review/look_uplift/step0_grade_day_half_clear.jpg` | `--look=day_half` | `day_half` reads much better; the default stays `day` (Yasin's choice, 18 Nov) |
| 3 | City light: sky darkening, warm bounce on walls, far sun shadows | `tools/city/look/city_light.sh` (after every bake; `phone_rig.sh bake` runs it), `shaders/rt/rt_city_light.gdshaderinc` in the six city shaders | `--citylight=0`, global `ck_city_light` | done |
| 1 | Golden hour on the streets | `look.gd` golden preset 17 deg from -52 | preset | done |
| 2 | Night ground: a moon that shows the asphalt | `look.gd` NIGHT sun 0.34 | - | done |
| 3 | Cars at night | `look.gd` sets `refl_env.x` by the night; `car_paint.gdshader` night street read softer | - | done |
| 4 | Floating white cards | night session (city_rooms.cpp, r7) | - | done there |
| 4 | Blocky car paint (dark cars in black / beige blocks) | NOT fixed: the 27 Nov rebuilt car meshes vs their maps (car pipeline) | - | `bug_near_car_uv_blocks.jpg`, `bug_far_car_park_blocks.jpg` |
| 5/6 | Signs, billboards, fuel canopies lit | `bake_runtime.gd` light anchors kind 2; `city_lights.gd` pool 26 | `--lights=` | done (rebake) |
| 7 | Windows on the far city and the skyline towers | `rt_far.gdshaderinc`, `skyline.gdshader` | - | done |
| 8 | Ground variation | `rt_ground.gdshader` | `--ground=0`, `ck_look_ground` | done |
| 9 | Far crowd from the new bodies | `tools/city/traffic/make_people_new.gd` -> `characters/meshy_far/`; `CityCrowd::use_new_far` | (on with the new people) | done; also Yasin's "Npcs spawn bunched up suddenly" |
| 9 | Crowd density | `rig.gd`: the game 400 people, density 3.5 (was 200 at 1: ~92 people round the player) | `--pdensity=` | done, phone cost NOT measured |
| 10 | Headlights light the road | `native/src/city_car_lights.*` (CityCarLights, 8 spots) | - | done |
| 10 | Night on foot / in the game | `rig.gd` walk loop hands the look's night to the traffic and the lamp lights | - | done |
| 11 | More traffic | NOT done: Yasin, 28 Nov: no more parked cars (~8000 for ~10000 people); moving traffic left at 40 until the phone is measured | - | - |
| 12 | Junction variety | `x_look_life` overlay (`zoning/look_life.json`): each of the 7 `j_apt` crossings its own patches, oil, covers | - | done; validator NOT run (memory) |
| 13 | Empty lots | `x_look_life`: the park lawn at 373,-690; one yard sprinkler | - | the back yards on the hill wait for a measured ground |
| - | 30 fps | `rig.gd`: the game `Engine.max_fps = 30` (it ran at 60) | `--maxfps=`, `--physhz=` (test) | done, phone NOT measured |

## Not done / not checked
- The phone: nothing here has run on the Redmi or the S23 yet (the phones were in use by the night session).
- The sustained heat test (20 minutes, frame time and temperature) is the next measurement; the per-pixel parts of the
  look (city light, ground variation) should then move into the bake (vertex colours) for low-end phones.
- The game's own clock (CityGame hour) does not drive the look's time of day: the game is always day.
- Car paint blocks (above); the back yards at 100,-40 (ground).
