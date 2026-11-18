# Runtime bake and the four trials (18 Nov 2026)

Yasin, after the audit (`AUDIT_PERF_LIFE_18NOV.md`): "do the 4 things you mentioned. show me samples where its
possible before a map wide roll out." Later: "triangles are fine ... try to keep draw calls as low as possible."
And: the engine's mobile light grid (`docs/engine`) gives up to 32 live lights for a fixed cost: use it for lights.

Nothing in the locked pieces changed (lock test RESULT PASS). Sample pictures: `map_dc/coronado/city_kit/review/samples_18nov/`.
The sample area is the city centre, apartments, civic band and stadium (32 cells of 200 m).

## Status
| Item | State |
|---|---|
| Stale plan picture | replaced (`zoning/city_assembled_wip.png`) |
| 1. Kit textures compressed with mipmaps | DONE for the whole kit (it cannot be done per sample). Texture memory 143 -> 38 MB |
| 2. Runtime bake | tool works; baked for the SAMPLE AREA only. Not rolled out |
| 3. Movement | wind, cycling signals, night windows / lamps: in the bake's shaders, shown on the sample |
| 4. Paint tint and shop-name plates | trial on the apartments sample, in memory only |

## 2. The runtime bake
`tools/city/bake/`. It reads the locked pieces and the layout and writes game-ready data to
`map_dc/coronado/city_kit/runtime/` (not in git: it is derived, see "Decisions"). It never writes a piece.

| Output | What |
|---|---|
| `lib/` | every model, collision shape and runtime material once, named by a hash of its content |
| `cells/cell_X_Z.scn` | one scene per 200 m cell: buildings (near, mid), ground, wear marks, props, collision, stalls, lamp anchors |
| `far/far_world.scn` | the far tier of the whole island, always loaded |
| `manifest.json` | which pieces (sha256) each cell came from |

How it gets the draw calls down:
- **Far world:** all far building boxes, tree cards and big far props of the island in a few meshes (2 materials, 1 km
  chunks). Small props (under 2.5 m) get no far version.
- **Texture arrays** (`make_arrays.py` -> `runtime_tex/`): the prop pages, the plant pages and the nine ground textures
  each become one array, so every prop of a batch shares one material, every plant another, the ground a third.
- **Merged batches:** near props per 64 m (models over 1,000 triangles stay instanced), mid props per cell, the
  ground of a cell in one draw, the wear marks of a cell in one draw.
- **Each prop still switches tier at its own distance:** the shaders collapse a prop outside its distance window, so
  a big batch does not pop as a block.
- **Wear level rides with each prop,** so clean / worn / dirty no longer split materials.

### Measured on the sample area (20 street views, same method as the audit)
| | Draw calls (median / worst) | Triangles sent (median / worst) |
|---|---|---|
| Raw pieces, whole city loaded | 942 / 1,412 | 383k / 548k |
| Raw pieces, 300 m radius, no skyline | 126 / 213 | 72k / 112k |
| **Baked: streamed cells + far world (whole skyline)** | **65 / 87** | 329k / 454k |
| Budget (the game's gate, everything included) | 150 | 300k |

- Triangles are above the gate's 300k in the densest views. They are triangles SENT; props outside their distance
  window are collapsed and draw nothing. Finer batches send fewer (down to 179k) but cost draws (up to 128), so per
  Yasin's word the big batches stay. A cut that costs no draws is still open: re-triangulating flat ground.
- Loaded set (12-14 cells + far world): 224 MB video memory (79 textures, 134 meshes).
- A cell loads in 18 ms on average, 46 ms worst (this machine, warm), on a loader thread; it is built on a worker
  thread; adding it to the scene costs at most 1.9 ms on the main thread.
- Streaming: see "The streamer" below.
- Disk: 79 MB of cells + 14 MB of models for the 32 sample cells. Merging trees is what makes cells big (46 MB with a
  600-triangle merge limit, at about 8 more draws a view).
- `bake_runtime.gd --check`: 32 cells, 0 stale.

### The streamer (`tools/city/bake/city_stream.gd`, rewritten 18 Nov; nothing taken from the old game)
Yasin: "go for it" (a robust streaming setup), hoped top speed about 280 km/h (78 m/s), no fast travel. From the old
game only FACTS were read (fastest car 210 km/h, first person, the player can look back, camera far 900 m, sun
shadows 50 m, Jolt physics, phone budget 1.5 ms a frame for streaming, and its phone lessons: shaders are built when
a mesh loads, collider adds hitch, more than 3 loads at once froze the Redmi).

| Part | What it does | Measured (cloud) |
|---|---|---|
| Forward lead | the loading range is swept ahead by 2 s of travel (max 200 m) | 60 m/s drawing: 15 m late -> 2 m |
| Queue | nearest first, 2 loads at a time on the streamer's OWN low-priority threads (not the engine's pool), stale requests taken off the list or dropped | no cell late at 209, 281, 360 km/h (not drawing); phone: none late at 108-281 km/h |
| No hole | the far world shows a cell's far versions until the cell is really in (`ck_cells_loaded`) | - |
| Shared things stay | every baked material is held for the streamer's life | letting one go cost ~250 ms |
| Cell add | built on a worker thread, added whole | 0.3-0.5 ms (was up to 33 ms) |
| Collision as data, made in steps | a cell carries its collision as plain data (`col_data.gd`), triangle shapes cut to 400 triangles; the streamer makes the bodies itself, nearest first: at most 6 bodies, 1,200 new triangles and 2 ms of main thread a frame | phone: a body is in the world within 1.6 s of its cell, the physics thread's wait is 0.5 ms median, 6 ms at 99 % |
| Removal in parts | 1.5 ms a frame, in frames when nothing loads | step worst 2-3 ms (was 45) |
| Memory cap | at most 30 cells; beyond it far versions | cap never hit (17-18 cells at once) |
| `prepare()` / `is_ready()` | get a place ready before the player is put there; ready = every cell in AND the collision within 70 m attached | phone: 0.5-2.6 s for a far jump, no frame over 39 ms meanwhile |
| `warm_up()` | draws `lib/warm.scn`: one of every kind of material and vertex format (41 draws), keeps them, and takes 192 MB of graphics memory once and gives it back | phone: 0.5 s (0.07-0.12 s of it the memory) |

Whole city (140 cells, 208 MB cells + 33 MB models, baked in 65 s). Drives, not drawing: ring 6.5 km at 281 km/h: 101
cells in, 94 out, none late; frame median 2.4 ms, 99 % 6.6 ms, 3 frames over 50 ms. Zigzag 6.8 km at 209 km/h: none
late, 2 over 50 ms. Diagonal at 360 km/h: none late.
ANSWERED on the phone the same evening: see "The streamer on the phone" below. Cells in parts were not needed.

### The streamer on the phone: what the hitches were, and what was done (18 Nov evening)
Yasin: "streaming is the backbone of this game, we need it to work healthy agile and robust ... tackle the problem".
Method: a loop of 3 km on streets through civic, centre, apartments and the gritty edge (`--plan=stream`: 108, 210,
281 km/h), a probe that times the physics and the render server every frame (`--probe`), switches that turn one thing
off (`--nocol`, `--hide`, `--loader=`), marks through a slow frame (scripts, streamer, draw, wait for physics). One
cause at a time, each proven on the Redmi before the next.

| # | What a slow frame was | How it was proven | What was done |
|---|---|---|---|
| 1 | Attaching a collision body: 29-41 ms of waiting for the physics thread | `--nocol`: those frames gone (8 -> 0); `tools/city/audit/col_census.gd`: every populated cell had ONE body of 7,000-25,000 triangles | the bake cuts triangle collision to 400 triangles a piece, 1,600 a body |
| 2 | The moment two cells are asked for: 52-350 ms of waiting for the physics step, with no shape being made | the probe caught the wait; unchanged by `--nocol` and `--hide` | a threaded load with sub-threads fills the engine's thread pool with a cell's hundreds of files, and the physics engine and the renderer run their jobs on that pool. The streamer now has its own loader threads |
| 3 | 600 small collision files a cell, read one after another: 1-3 s a cell (PC) | request-to-in times with the own loader | a cell's collision data is stored in the cell's own file |
| 4 | The first cell that brings a new kind of material: textures loaded, shader built in the drive | `tools/city/audit/cell_deps.gd`: the kit's ground atlas and the wire shader were not held | the bake warms and holds the first of every kind; a check line prints anything a cell needs that is not held (`mat_census.gd` lists kinds) |
| 5 | Once a session, the first cells streamed after the start: 61-546 ms inside the draw with 0.9 ms of drawing | the marks | the render side fetching its next block of graphics memory. The warm-up now takes 192 MB and gives it back, so that happens behind the loading screen (69-120 ms there) |
| 6 | One cell in plus six bodies in a frame: 16 ms of main thread in the streamer | the marks | bodies are made inside 2 ms a frame; their shapes go straight on the body (no node a shape): 3.5 -> 2.4 ms for the heaviest |

The loop on the Redmi, before and after (frames over 33 / 50 / 100 ms in 2.6 minutes of driving):
`stream_probe` (this morning's streamer) 36 / 12 / 1 -> `stream_split` 10 / 8 / 1 -> `stream_own` 2 / 1 / 1 ->
`stream_reserve` 0 / 0 / 0 -> `stream_final` 1 / 0 / 0 (one frame of 39 ms). No cell late in any of them.
The zones test: `zones_720` 36 / 3 / 0 with teleports of 1.0-5.5 s and frames up to 81 ms while they load ->
`zones_final` 6 / 1 / 0 with teleports of 0.6-2.7 s and no frame over 29 ms while they load. Its one frame over 50 ms
(53 ms, 47 of them in the draw) is the instant the test flips day to night at the start of the night drive; a
44 ms frame at the waterfront waited 35 ms for the physics step with nothing loading or attaching (once, not
explained).

THE BUDGET AND THE GATE. `tools/city/rig/health.py` grades a phone run PASS or FAIL: no cell late, no collision late
within 40 m, no frame over 50 ms, at most 0.2 % of a drive's frames over 33 ms, a teleport ready in 3 s with no frame
over 50 ms meanwhile, a collision body in the world within 3 s of its cell, no error. `phone_rig.sh` prints it after
every run. `stream_final` is the first run that passes; `zones_final` fails on the day-to-night frame alone.

SOAK (PC, 18 Nov 20:22-20:47, `OUT/soak.log`, not in git): 48 drives in one process, six rounds of the loop at
210 km/h, the ring at 281 km/h and six teleports to zones (two at night). Round by round, at the end of the same
drive: objects, nodes and resources the same (ring: 3,274 objects five rounds running; centre 6,219-6,226), video
memory the same to the megabyte (206-299 MB by drive), static memory +1 MB after the second round and flat from the
fourth, no orphan nodes left at the end of any teleport drive, nothing waiting in the streamer's queues. No leak and
nothing piling up in 25 minutes. Its frame times do not count: the look pictures (round 2) and another session's bake
(rounds 3-5) ran on the same graphics card; in the one undisturbed round (6) no drive had a frame over 33 ms but the
ring (2). Three late frames (220 m) in round 4's loop fall inside the other session's bake. Unbounded but tiny:
`add_ms` / `ready_ms` in city_stream.gd grow by one number per cell that arrives.

What the streamer does NOT solve (measured, not streaming):
- The frame rate itself: at 720p the phone sits at the 60 fps step with a 99 % frame of 25-26 ms, in every zone, with
  nothing loading. That is pixels and triangles (the centre sends 0.7-1.4 M), not streaming.
- Graphics memory: 584 MB from the system against 190-290 MB of the engine's own count, at every resolution. The
  reading of cause 5 (the driver holds memory in big blocks) fits it, but it was not measured block by block. If it is
  that, the lasting fix is in the engine build (smaller blocks for a streaming game), not here.
- The tiers still switch in hard cuts and a cell's far -> mid switch is the whole cell at once (see "THE TIERS").
  That is the next streaming job: fades, and roads in the far world.
- One run each, debug build. The numbers moved by about 7 frames over 33 ms between two identical zones runs.

### Collision per place (19 Nov, after the first growth)
The first growth's pieces south of the gritty edge (-600 / -800, -1200) nearly doubled the collision made there: 123k ->
236k units in the gritty night drive of the zones test. The streamer makes 1,200 units a frame (and 2 ms), so the
teleport to the gritty edge at night took 3.6 s (limit 3 s) and a body waited 4.8 s (`warmnight_zones`). The
streamer's collision work was all tuned before the growth (the PC session confirmed there was nothing further to merge).
Three changes, measured one at a time on the Redmi (zones gate, stream gate):

| # | Change | Default | Zones: teleports / worst body wait | Stream gate |
|---|---|---|---|---|
| - | before (`warmnight_zones`) | - | 0.1-3.6 s / 4.8 s: FAIL | PASS |
| 1 | the nearest body first counts the places being prepared too (a teleport's destination), not only the player | ON | 0.1-1.8 s / 5.3 s: FAIL on body waits (`col1_zones`) | PASS (`col1_stream`) |
| 2 | while a prepare() is pending (a teleport: the player is not there), the collision budgets a frame are `prepare_boost` (4) times larger | ON | 0.1-1.3 s / 3.2 s: FAIL on one body (`col2_zones`, with 1) | PASS, worst frame 32 ms (`col2_stream`) |
| 3 | collision only within `col_range` (100 m) of the player, the lead and prepared places; farther bodies wait as data; "a body waited" counts from coming into range | OFF (trial) | 0.1-1.0 s / 0.9 s; collision made down to about a fifth (gritty night 236k -> 29k) | FAIL: one frame of 86-414 ms |

- Change 3 does what it should for collision, but EVERY stream run with a range had one frame stalled in the draw
  (81-406 ms of it in the draw, GPU 13-14 ms, nothing attaching) on 5th St at 210 km/h, at the same place each time,
  while two cells were loading: `col23_stream` 86 ms, `col23_stream_repeat` 101 ms, `col3_stream` (range alone) 414 ms,
  `col150_stream` (150 m) 328 ms; the zones runs with it had one 75-96 ms frame during a teleport. Without a range
  (`col2_stream`) the same lap is clean. Why a smaller collision load makes the DRAW stall is not understood: the
  signature is that of cause 5 above (the driver fetching graphics memory inside the draw), whose timing the range
  may shift. So change 3 stays OFF (`--colrange=100` to try it) until that is found.
- With the defaults (1 and 2) the zones gate still FAILS on one body: in the gritty night drive a body waited 3.2 s
  from its cell's arrival (limit 3 s). Teleports are all under 1.4 s.
- THE LIMIT OF COLLISION PER PLACE NOW: the streamer makes 1,200 units a frame while driving (4,800 during a teleport).
  A place stays inside the 3 s body budget while the collision of the cells round it stays under about
  1,200 x 60 x 3 = 216k units; the gritty edge with the growth is at about 236-268k in the night drive. Growth beyond
  that needs change 3 working, or a higher budget a frame (measure the physics wait with `--probe`), or cheaper
  collision in the pieces (a convex point counts as one unit: a guess, not measured).

### The tiers (19 Nov, a PC session with the Redmi; branch `claude/ecstatic-archimedes-922d2c`)
Yasin: "i think it snaps from near to far directly and everythings appereance change suddenly as we get near".
Three things were built. Each has its own switch, and each was measured on the phone (Redmi, 720p, debug build, one
run each unless said). Runs are in `review/phone/tiers_*`, `night_*`, `gritty_*`. Pictures are in `review/tiers/`.

| # | What | Switch | Default | Cost on the phone |
|---|---|---|---|---|
| 1 | FAR GROUND: every cell's ground (streets, pavements, plazas, park ground) in the far world | streamer `far_ground`, rig `--nofarground` | ON | 1 draw, 20,000 triangles (12,100 vertices) for the whole island, one 1760 x 1760 ETC2 picture (1.3 MB file). GPU time the same: night centre with it off / on 11.39 / 11.40 ms by day, 14.24 / 14.23 at night |
| 2 | FAR TO MID BY DISTANCE: an arriving cell's objects take over from their far versions nearest first, sweeping out from the camera to 220 m in `arrive_s` (0.5 s), not all in the arrival frame | streamer `tiers` + `arrive_s`, rig `--tiers --arrive=` | OFF | included in 3 (same compile switch) |
| 3 | FADES at 60 m and 220 m: the two tiers overlap over `tier_band` (8 m) and share its pixels by a screen-door dither (opaque, no blending, never a hole, never a pixel twice) | streamer `tiers` + `tier_band`, rig `--tiers --band=` | OFF | see below: about 0.1-0.4 ms of GPU in most zones, 4 ms (40 %) in the gritty edge |

How it works:
- `bake_runtime.gd _build_far_ground`: one height grid for the island (20 m, the highest ground triangle over each
  point, so neighbouring patches meet without cracks) and a top-down picture of the real ground. The bake renders
  the ground with its own materials, unlit, at twice the size, then scales it down to 1.25 m a texel, with mipmaps,
  VRAM-compressed. One 200 m patch per cell, all in one mesh (`far_world.scn` node `far_ground`,
  `shaders/rt/rt_far_ground.gdshader`). A patch collapses in its vertex shader in the frame its cell is in. Per
  pixel: one texture read, lit like the ground. 100 of the 141 cells have ground pieces. A quarter-size copy of the
  picture is in `review/tiers/pc_check/`.
- `shaders/rt/rt_tier.gdshaderinc`: every tier shader (rt_bldg, rt_prop_*, rt_foliage_*, rt_far_*) now cuts its
  tier exactly at its window in the vertex shader. Buildings get their window and pivot as instance values (near
  0-60 m, mid 60-220 m, measured to the same pivot as the far box). The bake widens node ranges by 4 m (BAND_MAX / 2)
  so a band can be drawn. The kit's 2 m hysteresis already gave that much overlap (56-64 m, 218-224 m), and draws did
  not change: stream 77 / 72 / 74 average, zones 61-128.
- The fade and sweep code sits behind `#define CK_TIERS`. The baked materials do NOT have it, so with tiers off the
  city pays nothing for it. `city_stream.gd set_tiers(true)` gives every held material a copy of its shader with the
  define, made at runtime from the shader's own text (one source, no extra files). Call it before `warm_up()`: the
  first warm-up with tiers on took 7 s on the phone (new shaders compiled); later starts use the cache.
- `ck_cells_loaded` now holds 0..1 per cell. With tiers on, a cell ramps from 0 to 1 over `arrive_s` after it is
  added, and the shaders' switch to far is S = 220 m x ramp. New global shader value `ck_tier_band`
  (project.godot `[shader_globals]`; the game repo needs it too at integration).
- Per pixel with tiers on: one branch on a per-object value. Inside a band, 5 ALU of noise and a discard. The real
  cost is that a shader that CAN discard loses the GPU's early hidden-pixel removal for everything it draws.

The cost of tiers on, measured (GPU median ms a frame; the frame time itself sits on the 60 fps vsync step and hides
small costs, so the rig now prints `gpu_ms` on every `map` line):

| Run | off | on |
|---|---|---|
| stream loop 108 / 210 / 280 km/h | 13.13 / 13.38 / 12.99 | 13.57 / 13.48 / 13.37 |
| zones, by day (9 zones and 7th St) | 9.9 (gritty), 13.4-14.5 | 13.9 (gritty), 13.3-14.8 |
| centre / gritty at night | 14.28 / 14.06 | 14.57 / 19.02 |
| gritty alone, day / night (`gritty_g_*`) | 9.75 / 10.19 (repeat 9.72 / 10.17) | 13.88 / 14.13; band 0: 10.22 / 14.05 |

- Both stream loops pass the health gate (`tiers_off_stream`, `tiers_on_stream`: STREAM HEALTH PASS, no cell late).
  Frames over 33 ms: off 0 / 0 / 1, on 2 / 1 / 2, none over 50 ms.
- Zones medians against `zones_final` (16.5-16.8 ms): tiers off 14.9-16.9 (gritty by day is faster, 14.9 against
  16.5; three drives are 0.1 ms slower, within what two identical runs differ by). Tiers on: 16.6-17.1 by day and
  23.7 ms in the gritty edge at night.
- So the tiers cost GPU time where much is drawn over itself (the gritty edge: chain-link, trees, fences). The fade
  pattern itself is part of it (by day band 0 is free, the full band costs 4 ms), and so is the possible discard
  (at night band 0 already costs 4 ms). They stay OFF until there is a cheaper way. Candidates, not tried: the fade
  only on buildings (the switch Yasin sees most), not on plants and fences; or a separate fading material only for
  objects inside a band.

What is NOT solved:
- With tiers off (the default) the near / mid / far switches are still hard cuts, now exactly at 60 m and 220 m,
  with no 56-64 m double draw any more. The pop Yasin saw is still there by default. The fades exist and can be
  seen with `--tiers`, but they cost too much in dense, layered places.
- The zones gate fails on the day-to-night switch alone: the first half second of night draws at 40-49 ms of GPU a
  frame (two frames of 52 ms). The same with the far ground off (`night_nofg` / `night_fg`), and `zones_final`
  failed on the same moment (53 ms). Not a streaming or tier matter: the first frames of window glow, lamp halos
  and lights. Untouched.
- Pictures are stills. A dither band shows only as a fine pattern in a still (`after_tiers/bldg_*`), and the sweep
  is not in the pictures. Judge both on the phone with `--tiers`.
- Far ground: where no piece has ground (most blocks between the streets) it shows the rig's plane green; in the
  game that is the terrain's place. The far picture's greens and road greys are a little lighter than the real
  ground at the switch (seen from the air in `pc_check/aerial_*`). Wires, park ground tiers and small props still
  appear only when their cell arrives (about 240 m or farther away).
- The bake's small props (the kit gives them a mid range of 58-60 m) are drawn by the bake's mid batches over
  60-220 m. Seen while reading the code, not changed: a look decision.
- One run each. Battery 30-34 C over the evening.

Also found and fixed on the way: a start load (`update_focus(p, true)`) now attaches its collision at once. Since the
sibling fix of this evening, the start cells' bodies trickled in at 1,200 triangles a frame through the warm-up: one
body 9.9 s after its cell, and the gate failed (`tiers_off_stream` first try).

Pictures (`review/tiers/`, from the phone, `bash tools/city/rig/phone_rig.sh shots NAME [rig args]`): `before`
(far ground off, tiers off), `after_farground` (the default now), `after_tiers` (`--tiers`). The same 16 views each:
a tower on 7th St (`c_ne_18__twr_glass`, 36 m off the street) at 40, 56, 60, 64, 80, 150, 212, 218, 222, 228, 260 m,
then `street_eye`, `street_high`, `junction_north`, `hill_view`, `aerial`.

### The phone test (`tools/city/rig/`)
`rig.tscn` is the project's main scene: an Android export of this repo is the test app. It drives five routes
(50, 108, 210, 280 km/h by day, 50 km/h at night with lamp lights) and logs frame times, slow frames with what the
streamer was doing, late cells, draws, triangles, memory. On Yasin's PC, Git Bash, in the clone:
`bash tools/city/rig/phone_rig.sh all run1` bakes, exports (preset "Rig", the game's Android template and engine),
installs, runs and pushes `map_dc/coronado/city_kit/review/phone/run1.txt`. Remote Control showed the PC's folders
but the PC does not offer them to a cloud session, so the script is the way.

RUN ON THE REDMI, 18 Nov (a session on Yasin's PC; result `review/phone/run1.txt`, commit 49b2038, debug build).
Phone 22041216UG, Mali-G610 MC6, Android 13, screen 2460x1080 at 3D scale 0.5. Engine line: `coronado_all7` (the
game's current template; its build_info lists the light-grid patch, so the grid is present; the brief expected all3).
Vsync could not be turned off on the phone ("V-Sync mode Disabled is not available"), so frame times step with the
120 Hz screen: 8.3 ms is the floor, the next step is 16.7 ms.

| Drive | median | 99 % | worst | over 33 / 50 / 100 ms | draws avg / max | triangles avg / max | late cells |
|---|---|---|---|---|---|---|---|
| town 50 km/h | 8.9 ms | 26.6 | 64 | 2 / 1 / 0 | 57 / 119 | 240k / 526k | 0 |
| ring 108 km/h | 8.6 ms | 18.7 | 31 | 0 / 0 / 0 | 49 / 74 | 188k / 320k | 0 |
| zigzag 210 km/h | 10.1 ms | 20.4 | 76 | 2 / 1 / 0 | 60 / 118 | 285k / 611k | 0 |
| ring 280 km/h | 8.8 ms | 19.0 | 24 | 0 / 0 / 0 | 50 / 93 | 209k / 494k | 0 |
| centre at night 50 km/h | 16.8 ms | 26.3 | 59 | 7 / 1 / 0 | 121 / 205 | 628k / 1,352k | 0 |

- 18,681 frames in 215 s: 11 over 33 ms, 3 over 50 ms, none over 100 ms. No cell late (220 m or 60 m), none dropped,
  no body late, at any speed.
- The three frames over 50 ms (`RIG slow`): 64 ms at 0.3 s of the first drive with nothing loading (the first frames
  after the warm-up); 76 ms at 210 km/h while two cells were loading (`0_-6`, `0_-9`); 59 ms at night in the frame a
  cell came in with two collision bodies. The other 8 frames over 33 ms are not explained: the rig only describes
  frames over 50 ms.
- THE OPEN QUESTION, answered: cell loading does hitch on the real phone, but rarely: 2 frames (59 and 76 ms) in 215 s
  of driving, against 20-46 ms in the cloud. Main-thread work itself is small (cell add 0.95-1.30 ms, body 0.99 ms,
  removal step 4.10 ms worst, at night): the long frames are the wait on the loader thread, as in the cloud. Cells
  that arrive in parts would be the fix; whether two such frames in 3.5 minutes justify it is Yasin's call.
- Night in the centre is the heavy case: median 16.8 ms (about 60 fps, half the frames above 16.7 ms), draws 205 at
  the worst view (budget 150), triangles 1.35 M at the worst (gate 300k; Yasin: triangles are fine). By day draws stay
  inside the budget (max 119).
- Memory: 607 MB in all at 60 s (graphics 330 MB, native heap 171 MB); the engine's own count 92-118 MB static,
  186-278 MB video. Start: first area 481 ms, warm-up 9.6 s; a far start made ready in 1.9-2.0 s by day, 3.6 s at night.
  Battery 26.9 -> 28.7 C. No `Shader cache miss`, no error in the log.

SECOND RUN, THE POPULATED ZONES (`review/phone/zones1.txt`, commit ac5932a; Yasin: "the test was mostly in empty
ground ... make it teleport between gritty, city center, waterfront etc"). Plan `zones` (`--plan=zones`): a teleport
to each zone's sample junction, 25 s at 60 km/h on its own streets, far jumps on purpose; then 7th St through civic,
centre and apartments at 210 km/h; then the centre and the gritty edge at night. Same phone, same settings.

| Zone | median | 99 % | worst | over 33 / 50 ms | draws avg / max | triangles avg / max | teleport ready | worst frame while it loads |
|---|---|---|---|---|---|---|---|---|
| gritty edge | 8.9 ms | 19.2 | 21 | 0 / 0 | 98 / 129 | 490k / 721k | (start) | - |
| city centre | 14.5 ms | 21.1 | 27 | 0 / 0 | 88 / 122 | 737k / 1,353k | 2.2 s | 245 ms |
| waterfront | 10.4 ms | 19.3 | 36 | 1 / 0 | 89 / 123 | 601k / 820k | 2.7 s | 23 ms |
| industrial | 10.3 ms | 19.2 | 22 | 0 / 0 | 87 / 119 | 394k / 530k | 2.0 s | 19 ms |
| apartments | 15.8 ms | 22.0 | 29 | 0 / 0 | 121 / 189 | 815k / 1,220k | 3.9 s | 33 ms |
| pilot (high street) | 12.3 ms | 20.0 | 32 | 0 / 0 | 89 / 120 | 517k / 775k | 2.8 s | 27 ms |
| commercial strip | 10.6 ms | 19.4 | 32 | 0 / 0 | 75 / 103 | 446k / 672k | 2.3 s | 38 ms |
| civic | 13.4 ms | 19.5 | 30 | 0 / 0 | 95 / 134 | 492k / 751k | 2.7 s | 19 ms |
| stadium | 9.7 ms | 19.2 | 23 | 0 / 0 | 58 / 73 | 186k / 228k | 0.1 s (next door) | 18 ms |
| 7th St at 210 km/h | 14.6 ms | 23.0 | 30 | 0 / 0 | 104 / 191 | 630k / 1,365k | 0.7 s | 60 ms |
| centre at night | 16.4 ms | 25.8 | 93 | 3 / 1 | 103 / 138 | 742k / 1,355k | 0.8 s | 57 ms |
| gritty edge at night | 16.8 ms | 26.1 | 39 | 1 / 0 | 113 / 141 | 496k / 721k | 3.1 s | 73 ms |

- 22,841 frames in 295 s of driving: 5 over 33 ms, 1 over 50 ms, none over 100 ms. No cell late, none dropped.
- By day, in the zones, nothing over 36 ms, the fast pass down 7th St included (21 cells in, 28 out).
- The one real hitch: 93 ms at night in the centre while TWO cells were loading at once (`-1_-1`, `0_-1`). The 76 ms
  frame of run1 was also with two cells loading. Worth one run with `--loading=1` (no rebuild) before building
  cells in parts.
- A teleport takes 2.0-3.9 s until the new zone is ready. The frames meanwhile (the player still looks at the old
  place) stutter: 19-73 ms, once 245 ms. A fade or a held picture would hide it; nothing does so far.
- Frame rate: the centre and the apartments run at about 65-70 fps by day (median 14.5-15.8 ms); at night the two
  zones measured sit at 60 fps or under (median 16.4-16.8 ms, half the frames over 16.7 ms).
- Draws stay inside 150 except the apartments (189 at the worst view) and the 7th St pass (191). Triangles are far
  over the 300k gate in every zone but the stadium (Yasin: triangles are fine).
- Memory at 60 s: 873 MB in all, 583 MB of it graphics (run1: 607 / 330). The engine's own count never passed 294 MB
  video, so the rest is the driver's; taken once, right after the first teleport. Not understood yet: watch it.
- Warm-up took 0.4 s (run1: 9.6 s): the phone kept the shaders from run1. Battery 26.8 -> 30.4 C.
- The rig now takes drives of its own without a rebuild: `--drive=NAME/ROUTE/KMH/SECONDS/NIGHT` (Yasin: "inject
  this run ... instead of rebuilding"). 3D is drawn at 1230x540 (scale 0.5); `--scale=1.0` for the full screen.

THIRD RUN, THE SAME ZONES AT FULL RESOLUTION (`review/phone/zones_full.txt`, `--plan=zones --scale=1.0`: 3D at
2460x1080 instead of 1230x540; Yasin: "i need a test run at full res too"). Median frame, half | full:
gritty 8.9 | 16.9, centre 14.5 | 19.2, waterfront 10.4 | 16.4, industrial 10.3 | 16.3, apartments 15.8 | 24.4,
pilot 12.3 | 17.0, strip 10.6 | 16.9, civic 13.4 | 20.2, stadium 9.7 | 24.9, 7th St at 210 km/h 14.6 | 24.7,
centre at night 16.4 | 31.0, gritty at night 16.8 | 17.1 ms.
- The phone is limited by PIXELS, not by the map's draws: the same draws and triangles cost 1.3-2.6 times the frame
  time at four times the pixels. At full resolution no zone holds 60 fps (40-60 fps by day, 32 fps in the centre at
  night). The stadium's jump (9.7 -> 24.9 ms with the fewest triangles of all) is not explained: late in the run,
  battery 29.4 -> 32.1 C; heat or overdraw, not checked.
- 15,193 frames: 362 over 33 ms (219 of them are the night centre simply running at 31 ms), 15 over 50, 1 over 100
  (181 ms, gritty, two cells loading at once). No cell late, none dropped.
- Of the 16 frames of 45 ms or more, 13 are frames in which collision bodies were attached ("bodies +2") or a cell
  came in, though the attach itself is timed at 1.3 ms at most on the main thread. Two candidates, not told apart
  yet: the physics thread taking the bodies, or the first drawing of the cell that just arrived. `--bodies=1` and
  `--loading=1` (no rebuild) would tell.
- Teleports take longer: 2.0-5.6 s (half resolution: 2.0-3.9 s).
- Memory at 60 s: 901 MB, graphics 584 MB: the same graphics figure as at half resolution, so it is not the
  picture buffers.

THE SETTING TESTS AT 720p (Yasin: "ok run the tests"; "make the games default resolution 720p ... just inject it").
The rig now draws 3D 720 lines high by default (1640x720 on the Redmi; the installed app was given `--scale=0.6667`,
no rebuild). All runs `--plan=zones`, results in `review/phone/`:

| Run | frames over 33 / 50 / 100 ms | worst | late cells | teleport ready |
|---|---|---|---|---|
| `zones_720` (baseline) | 36 / 3 / 0 | 72 ms | 0 | 1.0-5.5 s |
| `zones_720_repeat` (the same again) | 29 / 2 / 0 | 60 ms | 0 | 0.8-5.5 s |
| `zones_720_loading1` (`--loading=1`) | 36 / 4 / 0 | 52 ms | 0 | 0.9-5.3 s |
| `zones_720_bodies1` (`--bodies=1`) | 33 / 2 / 1 | 124 ms | 0 | 1.5-8.7 s |

- At 720p every zone but the gritty edge by day sits at the 60 fps step (median 16.5-16.9 ms; gritty 10.4): the
  phone cannot reach 120 fps there, so vsync holds it at 60. 99 % 25-28 ms. This hides small differences: a change
  only shows if it pushes frames over a step.
- Two identical runs differ by 7 frames over 33 ms (36 and 29). So `--loading=1` and `--bodies=1` changed NOTHING
  that can be measured; one body a frame makes teleports slower. One loader at a time still had no late cell at
  210 km/h (request to in: 265 ms worst, against 572).
- So the hitches (45-70 ms, 5 to 9 a run) do not come from how much is done in a frame. Most fall on a frame that
  attaches a collision body or takes a cell in, whatever the count. Still two candidates: the physics thread taking
  a body, or the first drawing of a new cell. To tell them apart the rig needs a switch that is not there yet
  (collision off, or physics on the main thread): a rebuild. NOT DONE.
- LIGHTS (Yasin: the engine's grid makes 1 or 20 lights cost the same). Night drives in centre, apartments and gritty,
  `night_720_lights20` / `_lights20_repeat` / `_lights1` / `_lights0`: medians 16.6 / 16.1 / 16.5 (centre), 17.0 /
  16.9 / 16.8 (apartments), 16.8 / 16.8 / 16.8 (gritty) for 20 / 1 / 0 lights. The same, inside the 60 fps step. The
  first 20-light run had one odd drive (gritty 23.9 ms) that the repeat did not show: noise.
- Heat: the battery went from 29.5 to 36.2 C over the afternoon's runs; the repeat at 35 C was not slower.
- Memory: 857-873 MB in all, 568-575 MB graphics, in every run.

THE TIERS (done on 19 Nov: see "The tiers" above; what follows is how it stood before). (Yasin, watching the phone: "i think it snaps from near to far directly and everythings appereance
change suddenly as we get near"). From the code, not yet from pictures: near 0-60 m, mid 60-220 m, far world beyond;
every switch is a hard cut (`VISIBILITY_RANGE_FADE_DISABLED`); far -> mid happens for a whole 200 m cell in the
frame the cell arrives; props under 2.5 m and a cell's roads and ground have no far version at all (the rig shows a
flat green plane there). Not checked: how different the kit's mid meshes are from the near ones.

What the first runs on Windows found (all fixed, in the script or the rig):
- The export never returned: gradle's daemon outlives the build on Windows and holds the log open. Now run without it.
- The template copy took the game's whole last build with it (1.6 GB): the editor scanned it and about 1,200 of the
  game's file names went into the APK as empty files. Now only the template is copied and it gets a `.gdignore`.
- Git on the PC had no author set, and `git add` got a `/c/...` path it rejects: the result was never pushed.
- The first phone run was thrown away: the rig asked the physics for the ground height from a normal frame, which
  fails when physics runs on its own thread (Jolt on Android): 5,256 errors and the camera sunk into the road (Yasin
  saw it). The ray is now cast in the physics step. The streamer also printed a warning per collision body (302).
- A Windows clone with `core.autocrlf=true` made the lock test fail on 5 plan files (line endings only): the repo
  now has a `.gitattributes` that turns conversion off. RESULT PASS after it.
- Times on this PC: first import 10 min (no hang with many threads), bake 140 s, export 3.5 min, run 4 min.

### Commands (repo root, real renderer)
```bash
python3 tools/city/bake/make_arrays.py
```
```bash
godot --headless --path . --import
```
```bash
xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/bake/bake_runtime.gd -- --area=60,-600,520
```
`--all` bakes the whole city, `--check` lists cells whose pieces changed since the bake.
Preview and measure: `tools/city/bake/rt_shots.gd` (`--cams`, `--probe --detail`, `--drive`, `--night`, `--lights`,
`--tint`, `--plates`, `--frames`). The streamer the game can use: `tools/city/bake/city_stream.gd`.

## 3. Movement (all in the bake's shaders, `city_kit/shaders/rt`)
- **Wind:** crowns sway, leaves flutter, trunks stay put. Global values `ck_wind_strength`, `ck_wind_dir`. No extra draw.
- **Signals:** red / amber / green cycle on a 30 s clock, cross streets half a cycle apart.
  KNOWN FLAW: the green street-name board on the mast arm has the same green as the lens and lights with it. The
  lens faces need marking (in the kit model, or by the bake; a first try at the bake did not finish).
- **Night:** `ck_night` 0..1. Windows come on bay by bay (the kit's glow mask), each lamp gets a halo and a pool of
  light on the ground (2 draws a cell, hidden by day), and the bake records every lamp as a light anchor.
  `city_lights.gd` puts real lights on the nearest anchors: meant for the light grid (budget 20 of the 32, the rest
  for rooms and cars). The sample pictures use 8 real lights, the stock engine's limit per mesh.
- The interior rooms' light counts (up to 17) are fine with the light grid; no room was changed.

## 4. Tint and shop-name plates (trial, in memory only)
- **Tint:** `rt_bldg.gdshader` takes a paint tint and a wear offset per building (no extra material or draw). The tint
  fades out on dark and on saturated texels, so glass and coloured trims keep their colour. Light trims are tinted
  with the wall.
- **Plates:** `sign_plates.gd` puts a plate 2 cm in front of every painted or blank sign board (rectangles from the
  interiors' `room_contracts.json`), name from a list. 34 plates on the apartments sample. Civic boards that already
  say what the building is are kept.

## Found on the way
- **The cloud preview draws buildings too dark.** The original `bldg_wear.gdshader` renders about 40 % darker on the
  cloud's software GPU in the Mobile renderer than the same shader in OpenGL or Forward+ (0.32 against 0.44 mean).
  One more uniform in the shader and the Mobile result matches the other two. So every cloud shot so far showed
  buildings darker than a real GPU should. The baked city shows the brighter (matching) result. Worth one look on the PC.
- **Most near props have no normal or roughness map bound.** `kit_lib.prop_wear_mat` names its material files by the
  colour atlas only; the first prop to create `pw_props_color_clean_55.tres` was a mid tier (no normal, no ORM), and
  every near prop of that page reuses it. The bake keeps this look. Binding the maps is a look change: Yasin's call.
- With mipmaps, cut-out leaves thin out at a distance. The bake's plant shader corrects it; raw pieces do not.

## Not done
- Whole-city bake and the game side (the game repo's streamer and global shader values).
- Signals: the flaw above. Far buildings do not light their windows at night (the far atlas has no glow mask).
- Far ground: done 19 Nov (see "The tiers"); where no piece has ground the terrain (rig: a plane) shows.
- Phone: eleven runs (run1, zones1, zones_full, the 720p set; debug build, see "The phone test"). Not run: `--loading=1` (the next one to do),
  `--nowarm`, `--plan=speed`, `--scale=1.0`, a release build, a repeat to see how much the numbers move.

## Decisions for Yasin
1. Roll the bake out to the whole city? (`--all`; a few minutes by my estimate, the sample area took 45 s.)
2. Baked data in git, or baked at integration? It is derived and large (about 90 MB for the sample area).
3. Merge limit: 1,000 triangles (65 draws a view, 79 MB of cells) or 600 (about 73 draws, 46 MB)?
4. Wind, night and signals: keep as shown, or change strength / colours first?
5. Tint and plates: roll out to all samples, change the palette or the name lists, or drop?
6. Bind the props' normal and roughness maps (see "Found on the way")?
