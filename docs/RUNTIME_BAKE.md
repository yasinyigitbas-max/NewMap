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

What the streamer does NOT solve (measured, not streaming):
- The frame rate itself: at 720p the phone sits at the 60 fps step with a 99 % frame of 25-26 ms, in every zone, with
  nothing loading. That is pixels and triangles (the centre sends 0.7-1.4 M), not streaming.
- Graphics memory: 584 MB from the system against 190-290 MB of the engine's own count, at every resolution. The
  reading of cause 5 (the driver holds memory in big blocks) fits it, but it was not measured block by block. If it is
  that, the lasting fix is in the engine build (smaller blocks for a streaming game), not here.
- The tiers still switch in hard cuts and a cell's far -> mid switch is the whole cell at once (see "THE TIERS").
  That is the next streaming job: fades, and roads in the far world.
- One run each, debug build. The numbers moved by about 7 frames over 33 ms between two identical zones runs.

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

THE TIERS (Yasin, watching the phone: "i think it snaps from near to far directly and everythings appereance
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
- Far ground: beyond the loaded cells the game's terrain shows, not the roads.
- Phone: eleven runs (run1, zones1, zones_full, the 720p set; debug build, see "The phone test"). Not run: `--loading=1` (the next one to do),
  `--nowarm`, `--plan=speed`, `--scale=1.0`, a release build, a repeat to see how much the numbers move.

## Decisions for Yasin
1. Roll the bake out to the whole city? (`--all`; a few minutes by my estimate, the sample area took 45 s.)
2. Baked data in git, or baked at integration? It is derived and large (about 90 MB for the sample area).
3. Merge limit: 1,000 triangles (65 draws a view, 79 MB of cells) or 600 (about 73 draws, 46 MB)?
4. Wind, night and signals: keep as shown, or change strength / colours first?
5. Tint and plates: roll out to all samples, change the palette or the name lists, or drop?
6. Bind the props' normal and roughness maps (see "Found on the way")?
