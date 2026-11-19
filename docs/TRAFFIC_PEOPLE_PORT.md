# Traffic and people for the new map, in C++ (Stage 0: inventory and plan, 18-19 Nov 2026)

Yasin: "bring the traffic and people here as completely cplus plus first, then we run the extensions on the phone".
And, while this was being written: "all of them must fit into the new map flawlessly, improve the code whereevr you
can, think that you work at rockstar studios and you need to implement npc and traffic for the new GTA game.
everything must be in C PLUS PLUS".

This page is the plan. No code yet. How it was made: the old game was READ ONLY, at the snapshot on this PC
(`C:\coronado_..._src6_source\coronado-actprobe1-source\project`, commit `bd26fce`, the same one
`docs/OLD_GAME_SYSTEMS_REVIEW.md` read). I read the C++ headers and the setup, spawn and drawing code myself; three
helpers read the script layer, the crowd assets and the talking characters and reported with file and line. Nothing
there was run or changed. Numbers marked "estimate" are not measured.

## 1. The short version
- The old game's traffic and crowd each have a clean C++ core with NO engine types in it (`tc::Sim`, `cc::Sim`):
  flat arrays, a fixed number of cars and walkers, a step that allocates nothing. Those cores come over.
- Round each core the old game still runs a script layer EVERY tick and EVERY frame (lists below). None of that comes
  over. It is written new, in C++, for this map: fed by the streamer, drawn as batches, no node per car.
- The old data does not fit: its lane graph is the OLD streets. The new map needs its own lane graph, pavements,
  crossings and signal plan, made by a tool from the locked street skeleton and checked against the baked ground.
- The TALKING, the reactions and the city life are in the job too (Yasin, 19 Nov, section 4): after the walking crowd.

## 2. The old C++ (`native/src`, 7,900 lines), file by file
| File | Lines | What it is | Here |
|---|---|---|---|
| `traffic_sim.h` | 374 | the traffic core's data: lanes and junction connectors as flat polylines, up to 128 cars as arrays, config | TAKE, then change (section 8) |
| `traffic_setup.cpp` | 589 | lanes -> pieces, Bezier connectors through junctions, speed caps in curves, which movements conflict, grids, parked cars that reach into a lane | TAKE; parked cars become per cell (they stream) |
| `traffic_step.cpp` | 1,165 | one tick: following (IDM), junction reservations, signals, stop signs, lane changes, passing a parked car, "never move into a body", spawning and removing | TAKE; the spawn ring is rewritten (speed) |
| `traffic_route.cpp` | 403 | routed cars: timetable buses, scripted cars (the old taxi ride) | TAKE the router; buses wait for bus routes on the new streets (not in this job) |
| `traffic_peds.cpp` | 514 | a second, simpler walker system inside the traffic (pavements beside the lanes, crossings), drawn by the crowd as "guests" | NOT taken: one walker system instead of two (section 8) |
| `traffic_core.h/.cpp` | 526 | the script face of the core: packed arrays in, packed arrays out | NOT taken: nothing calls it from script any more |
| `traffic_draw.h/.cpp` | 446 | moves one NODE RIG per car, spins wheels, fills far-car batches | NOT taken as it is: its interpolation and "upload only what changed" ideas are kept, the node rigs go |
| `crowd_sim.h/.cpp` | 2,069 | the crowd core: walk graph, A* routes, keep-right lanes, passing, parties (couples, families), places (homes, shops, benches, bus stops), meetings, pauses, crossings with gap acceptance, fleeing, up to 1,024 walkers in three tiers | TAKE, then change |
| `crowd_core.h/.cpp` | 611 | the script face of the crowd + the far-figure rows | far-figure rows kept, the face is written new |
| `car_core.h/.cpp` | 1,267 | the PLAYER's car (engine, gears, steering, sound) | not in this job (no player car here yet) |
| `bike_riders.h/.cpp` | 220 | up to 8 cyclists | not in this job; listed for later |
| `breakables_core`, `ground_native` | 603 | hit scan for breakable props; ground heights from the old road meshes | not needed: heights come with the new graph |

## 3. The old scripts: what still runs every tick, and where it goes
"Live" = runs in the old game's default path today.

| Script | Lines | Live? | What it does | In the new map |
|---|---|---|---|---|
| `traffic/traffic.gd` (the autoload) | 403 | live | steps the sim at 20 Hz; builds and pools a node rig per car (1 ms a frame, one new rig a frame: a car is INVISIBLE until its rig exists); far batches; a collider node per near car; signal lamps (a mesh per lamp, a string compare per approach) | C++ node `CityTraffic` |
| `traffic2/traffic2_sim.gd` | 347 | live | per tick: pushes camera, player, other bodies; rebuilds a dictionary per car and per walker for the other scripts (in practice almost every tick) | gone: C++ reads the arrays directly |
| `traffic2/traffic2_data.gd` | 299 | load | packs the old road graph, parked cars, pavements, bus routes | replaced by the graph tool (C++) |
| `traffic/traffic_wrecks.gd` | 92 | live | turns a hit car into a physics wreck | later, with the player's car |
| `traffic/traffic_sim.gd` | 2,179 | fallback only | the OLD script traffic | not taken |
| `traffic/car_mesh.gd` | 431 | dead | procedural test cars | not taken |
| `vehicles/car_models.gd` | 1,067 | live | the car catalogue, rigs, LODs, paint | its TABLE (sizes, weights, colours) goes into C++ data; the rigs go |
| `crowd2/crowd2.gd` | 803 | live | per frame: feeds view, player, props, signals (0.25 s); steps; picks the near bodies; plays their clips; shows / grows the far batches; towels; 12 capsules round the player | C++ node `CityCrowd` |
| `crowd2/crowd2_data.gd` | 312 | load + 0.25 s | reads the OLD walk graph (23,007 nodes, 153 km), homes, shops, benches, densities | replaced by the graph tool; densities by zone |
| `crowd2/crowd2_life.gd` | 382 | live | reactions (danger, scream, film), beggars, night workers, umbrellas, murmur sound | C++, Stage 3c (separable: the walking does not need it) |
| `crowd2/crowd2_social.gd`, `crowd2_person.gd` | 107 | live | the bridge to the TALKING feature | C++, Stage 4 |
| `map_dc/coronado/npc/talk/*`, `voice/*`, `ui/npc/*` | 3,700 | live | the talking: logic, memory, voice, captions, the choice boxes | C++, Stage 4 (section 4) |
| `map_dc/coronado/npc/people/npc_people.gd` | 807 | live | the body library: 41 bodies, looks, materials; skins every far body into 12 poses in SCRIPT at load | the pose bake becomes an offline tool; the library a C++ table |

Per frame and per tick, the old game runs in SCRIPT (its own numbers: traffic 2.5-3.2 ms a frame on the Redmi before
the C++ core, 0.82 ms a frame in the cloud after it; there is no phone number since the rewrite):
1. traffic: the 20 Hz step call, the gathering of other bodies, a NEW packed array of them every tick, the dictionary
   rebuild for other scripts, rig building, collider on / off, the signal lamps;
2. crowd: the whole frame loop (view, feed, step call, near list, clip playing per body, far batch show / grow,
   events), the slow tick, umbrellas, reactions.
In the new map ALL of it is C++ inside two engine nodes. The test app's script only creates the two nodes and sets
numbers on them (three lines in `rig.gd`); it calls nothing per frame.

## 4. What "people" covers, and the question for Yasin
IN this job: the walking street crowd. People walk the pavements, keep right, pass each other, wait at kerbs, cross
at crossings (on green at signals, in a gap elsewhere, cars yield), walk in pairs and families, stop for a phone
call or a shop window, step aside for the player, run from danger.

ALSO IN, after it: the reactions, the city life and the TALKING (Yasin's answer is below). What the talking is in
the old game (read, not run):
- There are no special talking characters. ANY walker of the street crowd within 2 m of the player on foot gets a
  "Talk" button. It is the English-practice small talk (A1-A2 level, with a Turkish helper line): a greeting, then
  three choices (the nearest named place, the active mission or a hint, one small-talk topic). The player taps a
  line and must SAY it into the microphone (Android's Google speech-to-text, online only, three tries; typing or
  skip as fallback). The walker answers with a recorded clip and a caption box. Its party stands still meanwhile and
  its body plays a talk animation. Each person remembers the player for a while (a grudge for 24 h, "Hi again").
- All scripted, nothing generated: templates filled with a place name, a direction, walking minutes, the clock.
- Size. Code: talk logic 890 lines (`npc/talk/npc_talk.gd`, `npc_memory_store.gd`), interface 830
  (`ui/npc/*`, `ui/dialogue/choice_list.gd`, `ui/caption_help.gd`), voice and captions 2,000 (`voice/*`), the Android
  speech plugin (202 lines of Java + its build). Content: four JSON files (8 topics, 92 situations and 14 shop talks
  that are not used today, the groups), and 2,658 recorded clips, 39 MB (`audio/npc/f`, `audio/npc/m`).
- Per frame it costs nothing until a talk is open.
- What ties it to the OLD map: the walk graph, homes and shops with the real town's names, "the Hotel Bel", "the
  ferry landing", the zone names, and A CLIP PER PLACE NAME: new shop and street names need new recordings.
- What it needs that this repo does not have: a player on foot, an interact button, the caption and choice
  interface, the microphone plugin in the Android build, the save file (memory), the mission and job lists it quotes.

THE QUESTION WAS: not now, as a stage 4, or drop? YASIN ANSWERED (19 Nov): "does your work include every single
one of npc related systems right? npcs meeting, ractions, city life, speaking to them etc". So ALL of it is in this
job, in C++:
- meetings, parties, pauses, benches, bus stops, fleeing: inside the crowd core, Stage 3;
- reactions and city life (the old `crowd2_life.gd`: scream / film / call at a danger, "look out" for fast cars,
  beggars, night workers, umbrellas in rain, the murmur): written new in C++, Stage 3c;
- speaking to them: Stage 4. The talk logic, the memory, the caption and choice boxes (engine controls, made and
  driven from C++), the talk animation, the microphone plugin in the test app's Android build.
What that needs, said plainly:
- a player on foot: the test app gets a simple walking stand-in (a camera at eye height with a walk button), only
  so the talk and the reactions can be tried. It is not the game's player;
- the voice: the 2,658 clips come over (39 MB). Lines with no place name are used as they are. Lines that name a
  place of the OLD town cannot be used: they need new recordings (the old game renders them with its own tool,
  `tools/voice/render_kokoro.py`) once the new map's shop and street names are fixed. Until then those lines show
  their caption without a voice. YASIN: the place names are the thing to settle;
- the missions and jobs the old talk quotes do not exist here: those lines are left out until the game has them.

## 5. The DATA the new map must give (none of it exists yet)
This repo only borrows `map_dc/roads/lane_graph.json`, which is the OLD streets (4,892 edges from the real town's
map). It is not used. What the new streets have: the locked skeleton (`zoning/grading.json`, `review/sites.json`: 93
junctions, 165 blocks, 34.3 km: residential 11.1 km, standard 7.5, ring 6.9, the 3rd / 4th St arterials 3.2, high
street 1.9, centre 1.6, bridge 1.3, strip 0.6, truck 0.4), the cross-sections (`ROADKIT_SPEC.md` and the piece
libraries: lane edges, kerbs, parkways, pavements, crossings, stop bars as constants), the pieces placed
(`city_grid_layout.json`, `review/*_sites.json`) and the baked ground.

| Data | From what | How |
|---|---|---|
| LANE GRAPH: lane centre lines, lane count and width, speed limit, lane neighbours | skeleton + section table | a C++ builder (`StreetGraph`) lays lanes beside each block's centre line. Two-way everywhere (3rd / 4th St are two-way arterials with a centre turn lane, per ROADKIT_SPEC). The ring's curves and the bridge use the blocks' own point lists |
| JUNCTIONS: which lane leads to which, stop line positions, who has right of way | `sites.json` legs + the junction rules of ROADKIT_SPEC (residential / standard: all-way stop; any arterial or Amber crossing: signals; a T into the ring: the stem stops) | connectors per junction (straight, left, right; no U-turns); the old core then builds the curves and the conflict lists itself |
| SIGNALS | the bake's signal shader | the lamps already cycle in the shader (30 s: green 40 %, amber 10 %, red 50 %, cross street half a cycle later, a start time per junction). The sim will use EXACTLY that plan and drive the shader's clock (`ck_signal_time`, the hook the shader comment already names), so a car stops at the red the player sees |
| HEIGHTS | the baked ground | every lane and pavement point is dropped on the baked ground once, by the tool. Rule kept: smooth heights, no jumps |
| A CHECK that the graph is ON the street | the baked ground | the ring leaves the skeleton line by up to 20 m at the waterfront, so the skeleton alone is not trusted: the tool measures kerb to kerb at every point, moves the lanes where the built street differs, and must report 0 lane points off the asphalt and 0 pavement points off a walk |
| PAVEMENTS and CORNERS | section table (walk between kerb / parkway and the property line) | both sides of every block, joined at the corners |
| CROSSINGS | the crosswalk positions of the junction libraries | at signals: walk on the crossing street's red; at stops and mid-block: gap acceptance |
| PARKING STALLS | the baked cells' meta `stalls` ([x, y, z, yaw, grade], already there) | the tool reads all cells once and stores the stalls with the graph, so the sim knows where parked cars reach into a lane BEFORE a cell loads. Which stalls are taken is decided by a hash of the stall (the same answer in the sim and on screen, every session) |
| DENSITY: how many cars and people where, by hour | zone of the block (`zoning`) | a small table by section and zone (centre and high street busy, residential quiet, industrial trucks by day). The old game had measured traffic counts of the real town; the new town has none, so this is a design table. YASIN may want to tune it |
| PLACES people go: doors, benches, bus stops, park and beach spots | the pieces' props and the interiors' door list | Stage 3b (people walk and cross first, in 3a) |
| NAMED PLACES for the talk ("where is the ...?") | the shop assignment of the interiors, the street names of the skeleton | Stage 4; the names decide which voice clips must be recorded again |
| BUS ROUTES and stops | - | does not exist for the new streets. Buses are left out until Yasin wants them |

Output: `map_dc/coronado/city_kit/traffic/streets.bin` (small, in git, made by the tool) and a top-view picture of the
lanes, pavements and crossings over the street map for Yasin to look at. Frame: the grid frame the pieces, the bake
and the rig already use (x = u, z = v). The game's placement (Amber's 26 degree bearing, the world offset) is one
transform at integration.

The bake is NOT changed for any of this: the tool reads the baked cells. If Stage 2 finds something the cells do not
carry, it will be added in the smallest way and said.

## 6. The ASSETS
Cars. This repo has, borrowed from the game: `vehicles/models/lod/<id>_q.res` for 12 vehicles (volt_s, volt_x,
stern_e, stern_g, sakura, sakura_t, van, fiamma_r, fiamma_gt, taxi, bus_city, bus_mini; body and wheels in one mesh),
the paint shader and the 1024 atlas. Enough for the near car. Missing here, present in the old game's
`vehicles/models/lod/` (5.7 MB in all): `<id>_far.res` (the cheaper mid model), `<id>_imp.res` (a 40-triangle
far box), `<id>_q_body.res` + `<id>_q_w0..3.res` (body and wheels apart, for turning wheels) and
`Textures/car_atlas_512.png`. Stage 2 copies the far, box and wheel meshes and the small atlas (about 3 MB).
That is 8 cars, a pickup, a van and two buses; there is no truck (the industrial zone would want one: an asset to
find, not in this job). WHERE THEY COME FROM, and a gap to close: the nine `sf_*` cars are by Daniel Zhabotinsky
(Sketchfab, CC BY 4.0, modified), the city bus by MaG80 (CC BY 4.0), the minibus by Innerscene (CC0). CC BY needs
the credit shown; this repo has the meshes but NO credits file for them. Stage 2 adds `vehicles/CREDITS.md` from the
old game's `vehicles/CAR_CREDITS.md`.

People. None here. The old game's are Microsoft Rocketbox (MIT licence), in `characters/rocketbox/`: 41 bodies (22
men, 19 women) as near (2,500 triangles), `_l1` (1,500) and far (500) meshes, 9.8 MB; two skeleton scenes 2.6 MB;
two clip libraries 12.4 MB (49 clips each: walk, run, idle, sit, phone, wave, talk ...); one colour and one mask
texture, 16.6 MB (512 x 512 x 41 layers). About 41 MB for all 41 bodies. Stage 3 starts with 10-12 bodies (each body
in view is a draw call; see section 9), about 15-18 MB, and says the size before it copies. The originals
(`rb_male.glb`, `rb_female.glb`, 60 MB) are not needed.

Sound: the crowd murmur and the talk voices come with stages 3c and 4. Engine sound and horns: not in this job.

## 7. The BUILD
How the old game builds (checked on this PC, not from memory):
- `native/SConstruct` (25 lines) compiles `src/*.cpp` against a godot-cpp checkout given by `GODOT_CPP`.
- godot-cpp: branch `4.5` at `27d9dd2`, with one local line (`#include <cstdlib>` in `src/godot.cpp`, needed by the
  new llvm-mingw). `compatibility_minimum = "4.5"`. The engine is 4.7.2 (Yasin's build `coronado_all7`: 4.7.2 plus
  patches that, by the engine notes' own rule, never change bound methods or the extension interface), so a 4.5
  module loads in it. Proven by the old game on the same phone.
- Windows: llvm-mingw (`tools_native/llvm-mingw-20261104-ucrt-x86_64`), `scons platform=windows use_mingw=yes
  use_llvm=yes arch=x86_64 target=template_debug`.
- Android: NDK `29.0.14206865` (in the PC's Android SDK), `scons platform=android arch=arm64 target=template_debug`
  and again `template_release`, linked with `-static-libstdc++` (the APK ships no C++ runtime library). Two files:
  a debug .so and a release .so; a release APK with only the debug one crashed at start in the old game.
- Present on this PC: Python 3.12, SCons 4.8.1, JDK 17, the NDK, llvm-mingw, godot-cpp with its Windows debug and
  Android release libraries built.

How it is built here (done in Stage 1; where it differs from this plan's first draft, it says so):
- `native/` in this repo: `src/`, `build.sh`, `coronado_city.gdextension.in`. `bash native/build.sh` builds the
  Windows dll and the Android .so in under a minute. It does NOT run scons: it compiles `src/*.cpp` with exactly the
  flags godot-cpp's scons uses (read from a dry run) and links godot-cpp's static library. Why: scons keeps its own
  record per folder, so every checkout would have rebuilt godot-cpp itself, about an hour on this PC (4 threads).
- godot-cpp has its OWN copy for this repo, outside git, at `C:\Users\yasin\NewMap\OUT\native_tools\godot-cpp`
  (same commit, same one-line fix), so nothing is built inside the old game's folders. `build.sh` makes it when it
  is missing and takes the two static libraries the old game's tools folder already has (same commit; the generated
  headers were compared: identical). Without them it builds them with scons.
- ONE Android library, not two (first draft: debug + release): built like a release (no debug checks) and used by
  debug AND release exports. The extension interface is plain C, so it loads in a debug engine, and the old game's
  "release library missing" crash cannot happen with one file. The Windows dll keeps the debug checks. The .so
  needs only libc, libm and libdl, exports one symbol (`coronado_city_init`) and is laid out for 16 KB pages.
- THE BINARIES AND THE `.gdextension` FILE STAY OUT OF GIT, like the bake (`runtime/`) and the Android template:
  `build.sh` writes them. Why: every checkout that has a `.gdextension` file loads it, and a cloud session on Linux
  would print an error on every run (there is no Linux library unless it builds one). This way the four zone
  sessions and the look sessions never see the module. `phone_rig.sh export` will call `build.sh` first when the
  sources are newer than the libraries. At integration into the game the binaries can go into git as the old game
  does: Yasin's or the PC session's call then.
- Export: preset "Rig" already exports all resources; the exporter packs the Android .so of a `.gdextension` into
  the APK by itself. No preset change expected; Stage 1 proves it.
- No script fallback: when the module is missing and traffic or people are asked for, the test app says so in one
  `RIG ERROR` line and runs without them.

## 8. How it will be built: the design, and what is better than the old
Three engine classes, all C++ (`native/src`), plus the two plain cores:

| Class | What |
|---|---|
| `StreetGraph` | builds the graph of section 5 from the skeleton, checks it against the baked ground, saves / loads `streets.bin`. The tool script is ten lines that call it |
| `CityTraffic` (a node) | owns the traffic core, its own thread, the car batches, the parked cars, the collision pool. Hooks: the streamer's `cell_in` / `cell_out` signals and its loaded-cell list |
| `CityCrowd` (a node) | the same for the walkers |

What changes against the old game, and why:
1. THE STEP LEAVES THE MAIN THREAD. The old step runs on the main thread (the review's one leftover: perhaps
   0.5-1 ms on the phone). Here each core steps on its OWN thread at 20 Hz (never the engine's thread pool: the
   streamer's lesson, physics and drawing run their jobs there). The main thread only blends between the last two
   states of each car and writes the batch rows.
2. NO NODE PER CAR. The old game builds a node tree per car at ANY distance (body + a wheel batch = 2 draws a near
   car, and a car is invisible until its rig is built, one a frame). Here every car is a row in a batch:
   per car model one batch for near cars (wheels turn and steer in the vertex shader), one for the mid model, and
   ONE batch of 40-triangle boxes for every far car of every model. Draws depend on how many MODELS are in view, not
   on how many cars. Parked cars are rows in the same batches, so they add no draws. Estimate: 10-25 draws for
   traffic, to be measured.
3. THE SPAWN RING MOVES WITH SPEED. Old: a fixed ring 70-340 m round the camera, never nearer than 160 m in view,
   4 tries a tick: at 280 km/h that is 2.3 s of road, the street ahead empties. New: cars are placed on lanes inside
   the cells the streamer has loaded or asked for (it already leads 2 s ahead, up to 200 m), weighted forward by the
   closing speed; the nearest a car may appear in view grows with speed (4 s of travel, at least 160 m); cars behind
   are let go sooner. Cars leave with their cell.
4. PARKED CARS STREAM WITH THE CELLS. Old: all parked boxes fixed at build, attached one cell per 0.1 s (the review:
   too slow above 130 km/h). New: a cell's stalls become batch rows in the frame the cell is in; no node, no limit.
5. COLLISION WITHOUT ATTACH HITCHES. A fixed pool of box bodies is made ONCE behind the loading screen and only
   MOVED afterwards (the nearest moving cars). Parked cars: one static body of boxes per cell, handed over through
   a queue, nearest first, one a frame. Boxes, not triangle meshes: the streamer's hitch was triangles.
6. ONE WALKER SYSTEM. The old game has two (the traffic's own walkers and the crowd, glued by a "guest" list).
   Here the crowd core owns every walker; the traffic sees them as moving boxes and yields at crossings (the
   traffic core already has that rule).
7. SIGNALS: one clock for the lamps the player sees and the cars' rule (section 5). The old game compared strings
   per approach every 0.25 s in script and drew a mesh per lamp.
8. LOAD: the old game skins 41 bodies into 12 poses in script at every start. Here that is baked once by a tool.

Kept as it is because it is good: the cores' model (following, reservations at junctions, "never move into a body",
tiers by distance, deterministic for a seed), the far figures (one pose picture per body, no skeleton), the
upload-only-on-change rule.

## 9. What it will cost (said before it is measured)
`docs/DRAW_CENSUS.md`: in the dense zones the city already draws 88-121 calls on average and up to 189 (apartments),
against a budget of 150, and trees and shadows take most of the GPU. So:
- Traffic: 10-25 draws by estimate. Fine in most zones, over the budget's worst views in apartments and on 7th St.
- People, on the old game's budget: 18 near skinned bodies = 18 draws (+ their shadows) and 18 skeletons on the CPU,
  plus one draw per body MODEL in view for the far figures. With 12 models: about 30 draws. Together with traffic a
  busy street adds 40-55 draws by estimate. That will NOT fit under 150 in the dense zones as they are.
- The way out, if the phone confirms it: near people drawn like the far ones (pose pictures, no skeleton, one draw
  per model whatever the count), keeping a handful of real skinned bodies only right next to the player. Stage 3
  starts with 18 as asked, measures, and says.
Every stage reports the real numbers from the rig's probe at 720p: main thread ms, physics thread wait, GPU ms, draws.

## 10. The order of work, and what each stage is measured by
| Stage | What | Done when |
|---|---|---|
| 0 | this page | pushed; Yasin answers section 4 |
| 1 | `native/` builds for Windows and Android; the test app loads it and prints one line from a C++ class | the line in the PC log AND in a phone run; stream health gate PASS; lock test RESULT PASS |
| 2a | `StreetGraph` and its tool; `streets.bin`; the picture | 0 lane points off the asphalt, heights within 3 cm of the ground, every junction leg connected; the picture pushed |
| 2b | the traffic core on the new graph, on its own thread, no drawing | a PC test: 30 sim-minutes at 80 cars: 0 overlapping cars (the core's own audit), no car standing over 2 minutes except at a red, the same result twice for one seed; step time printed |
| 2c | car batches, parked cars (section 14: one pool with the moving cars, pulling in and out of kerb stalls, the same street every time), signals on the shader clock, the speed ring, collision; rig options `--traffic=N` `--parked=0/1` (`--cars` is already the look session's demo and stays theirs) | PC pictures by day and night; a 280 km/h drive on the PC with cars ahead all the way |
| 2d | the phone | gate PASS with `--traffic=20`, `40`, `80`, and with parked cars off and on as their own line; a table: main thread ms, physics wait, GPU ms, draws, against the same run without traffic; runs in `review/phone/` |
| 3a | the crowd core on the new pavements and crossings; far figures; 18 near bodies; `--people=N` | PC test: 0 walkers off a walk, 0 inside a car, crossings used; pictures |
| 3b | the phone; then places (doors, benches, bus stops) | gate PASS with people on; the same cost table; the honest answer on the draw budget |
| 3c | reactions and city life in C++ (danger, witnesses, beggars, night workers, umbrellas, murmur) | a PC test that triggers each; pictures; phone gate PASS |
| 4 | speaking to them: talk logic, memory, captions and choices, talk animation, microphone plugin; a walking stand-in in the test app | a talk from greeting to goodbye on the PC (typed) and on the phone (spoken); which lines have a voice and which wait for new recordings, as a list |
After every stage: lock test RESULT PASS, commit, push, a job board line.

## 11. Not in this job (listed so nothing is lost)
The player's car (`car_core`), wrecks, honks and hits (they need the player's car), buses and their timetable, the
taxi ride, cyclists, breakable props, engine sound. The core's hooks for them (events, scripted cars, routes) stay
in the code. (The talking, the reactions and the city life were on this list in the first draft; Yasin put them in.)

## 12. Risks, said now
- The graph tool is the hard part: lanes must sit on streets that were built by hand, family by family. The check
  against the baked ground is what makes it safe; where it fails, the block is listed, not hidden.
- Junction deadlocks: the old game still had one cluster that jammed after 15 minutes without its "remove a stuck
  car" rule. The new grid is simpler (crossroads and T's on a 200 m lattice), but it is not proven until 2b runs.
- The phone at 720p lowers its GPU clock (census), so small GPU costs do not show there; costs will be given as
  measured, with that caveat.
- The module is built against the 4.5 extension API: anything added to the engine in 4.6 / 4.7 is not reachable from
  it. Nothing in this plan needs it.

## 13. Stage 1 result: the module on the PC and on the phone (19 Nov, 00:26)
- `native/`: `src/` (class `CityNative`: a version line and a test that starts the module's own threads),
  `build.sh`, `coronado_city.gdextension.in`. `bash native/build.sh`: Windows dll 717 KB, Android .so 727 KB, 47 s
  from nothing, seconds after a change.
- PC (official 4.7.2): `RIG native coronado_city 0.1 debug windows x86_64, godot-cpp 4.5 | its own threads: ok`.
- PHONE (`review/phone/native1_stream.txt`, engine `coronado_all7`, Redmi, 720p, debug export, `--plan=stream
  --probe`): `RIG native coronado_city 0.1 release android arm64, godot-cpp 4.5 | its own threads: ok (4 threads,
  2.0 ms; the device reports 8)`. The exporter packed the .so by itself (`lib/arm64-v8a/` in the APK); the export
  preset was not changed. STREAM HEALTH PASS: no cell late, no frame over 33 ms in any of the three drives
  (108 / 210 / 280 km/h: median 16.2 / 16.8 / 16.7 ms, worst 30 / 31 / 31 ms).
- THE BASELINE the traffic and the people will be measured against (this run, nothing of theirs on): draws 79-82 on
  average, 196-198 at the worst view; GPU 13.5 ms median; physics thread wait 0.5-0.6 ms median, 6-7 ms at 99 %;
  905 MB in all at 60 s. The worst view is already over the 150-draw budget before a single car is drawn.
- Seen, not mine: a collision body waited 2.9 s for its place at 210 km/h, just under the gate's 3 s (the collision
  session is on it).
- Lock test RESULT PASS (401 pieces, 19 plan files), with the module loaded, no error line.
- `phone_rig.sh export` builds the module first; `rig.gd` prints the `RIG native` line (or says the module is not in
  the build). Nothing else in the rig, the streamer or the bake was touched.
- The phone was shared: another session's test series was running. This run waited for it, and that session's APK
  was put back on the phone afterwards.

## 14. PARKED CARS (added 19 Nov; Yasin: "tell it to bring parked cars to the game", "i think the traffic code needs to know about the parked cars locations right?")
Yes: the traffic must know them, and here it does from the start. Parked cars are a full part of the port, in C++,
and they share everything with the moving cars. This section goes with sections 5, 8 and 10.

What the old game does (`vehicles/parked_cars.gd`, 403 lines of script; read, not run): parked cars from a list
measured on the real town, one batch per car model and distance band (up to 28 draws), box colliders per 50 m cell.
What the review found wrong: near cars drawn twice, every batch uploaded again every 0.1 s whether anything changed
or not, one cell attached per 0.1 s (too slow above 130 km/h). The traffic core gets the parked boxes ONCE at build
and can never change them. What it does is kept; how it does it is not.

What the new map already gives (measured from the bake of 18 Nov, 141 cells, by a throwaway script):
- 4,524 stalls in 86 cells, each `[x, y, z, yaw, grade]`; the busiest cell has 226.
- 3,008 are at the KERB, parallel to the street, in the parking lane: 4.5 m from the street's centre line on
  residential, standard and strip side streets (lane edge 3.3 m, kerb 5.7 m), 10.3 m on Amber (lanes to 9.1 m, kerb
  11.5 m). None on the 3rd / 4th St arterials, none on truck streets, a few on the ring.
- 1,516 are OFF the street: car parks and alley parking behind the buildings (978 across their aisle, 507 along
  it), 20 to 125 m from a street's centre line; 17 nose-in stalls along the ring.

What the data LACKS (a note for the pieces and the bake; pieces are locked, nothing is changed here):
- a stall has no KIND (kerb / car park, parallel / nose-in) and no SIZE. Both can be told from where it lies and how
  it is turned, so the tool works them out and prints what it could not class (must be 0);
- DRIVEWAYS are not recorded: the pieces know their aprons (constants in the piece libraries) but do not write them
  down as they do the stalls. So the graph knows where a kerb has NO stall (a hydrant, a bus zone, an apron), which is
  what a parking car needs, but it does not know the way INTO a car park. Until the pieces record their aprons and
  aisles (one more list beside `stalls`: `[x, z, yaw, width]`), cars in car parks are parked for good; only kerb
  stalls take part in the traffic. Yasin's word would be needed to add that list to locked pieces.

How it is built (Stage 2):
1. THE GRAPH KNOWS THE STALLS. The tool reads every cell's stalls into `streets.bin`: each kerb stall is tied to its
   lane (which lane, where along it, which side), each car-park stall to its cell. So before any cell loads the sim
   knows which kerb has parking, where a parked row runs beside a lane, and where the gaps are.
2. ONE CAR, TWO STATES. A parked car and a moving car are rows of the same pool and the same batches. A moving car
   can pull over into a free kerb stall, stop, and become parked; a parked car signals, waits for a gap and pulls
   out. (The old core already has the moves for this, written for its taxi: pull over to the kerb, hold, release.
   They are opened to every car.) This is also the best answer to the speed problem: new cars can come from the kerb
   in plain view instead of appearing at the edge of sight, and leave the same way.
3. THE SAME STREET EVERY TIME. Which stalls are filled, with which model and colour, comes from a fixed seed per
   cell, kept in one small table for the whole city (two bytes a stall). A stall that traffic changed keeps its
   change for the session, so a street the player comes back to is as they left it.
4. STREAMED AND CHEAP. A cell's parked cars are drawn from the frame the cell is in and gone when it leaves: rows
   in the shared batches (near model, mid model, the 40-triangle far box), no node, no extra draw. When nothing
   moves nothing is uploaded; a moving car re-sends only its own block of rows. Collision: small static bodies of
   boxes (a 32 m block each, as the streamer does its own), handed to the physics thread nearest first, a few a
   frame; a car that drives off switches its box off.
   LOW DETAIL ONLY (Yasin, 19 Nov: "make sure the parked cars are low detail versions, high detailed ones break the
   game"): a parked car is NEVER drawn with a detailed model. Up close it is the light model (`<id>_far.res`, about
   8 % of the full car's triangles), far away the 40-triangle box. The full models are not in this repo; the
   "quarter" model (30 %) is kept for the few MOVING cars nearest the camera. A car that pulls out of a stall changes
   to the moving cars' models as it leaves; one that parks goes back to the light one. Stage 2c reports the
   triangles per parked car and per street as measured.
5. THE WALKERS go round parked cars: the crowd gets the parked boxes near each walker as standing obstacles, as it
   gets the moving ones.

Measured on the phone as its own line (Stage 2d): 0 parked cars against a normal street's worth, with the same
numbers as the traffic table (main thread ms, physics wait, GPU ms, draws).

## 15. Stage 2a result: the streets as traffic and people use them (19 Nov, 01:45)
`tools/city/traffic/make_streets.gd` (a few lines; all the work is the C++ class `StreetGraph`, `native/src/street_*`)
reads the BAKED city and the locked skeleton and writes `map_dc/coronado/city_kit/traffic/streets.bin` (540 KB), the
full report `traffic/streets_report.txt` and eleven check pictures in `review/traffic/`. Run it after every bake:
`godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/traffic/make_streets.gd`
(71 s to read the 141 cells, 3 s to build).

How it works, in short. The skeleton only says which street joins which junction. Everything else is MEASURED from
the baked ground, whose triangles say what they are (asphalt, concrete, grass, white paint, yellow paint):
- every street is cut across every 2 m: where its median ends, where its kerb is, where its pavement runs, to a
  centimetre. The lanes are laid from those kerbs with the piece libraries' own lane widths; a block whose two halves
  were built by different pieces changes its lanes on the way;
- where the skeleton line lies beside the built street (the waterfront: up to 7 m, in a tight curve where four lanes
  become two), the tool FOLLOWS the street itself from one junction to the next;
- a stop bar is found as a white line right across an approach, signals from the signal heads the bake flags. So
  which approach stops, and where, is what is painted and built: 27 junctions with signals on every approach, 40
  all-way stops, 24 T-junctions where only the side street stops, the bridge ramp with no stop;
- the path through a junction is the same curve the traffic will drive (one shared function). Each is checked as
  wide as a car, and takes a wider curve when the plain one would touch a kerb corner (17 of 974 do);
- pavements get a walk line down their middle, corners where two legs' lines meet (pushed onto the pavement at wide
  kerb returns), a crossing just inside every stop bar;
- parking stalls: 3,010 at the kerb, each tied to the lane beside it and its place along it; 1,514 in car parks.

The numbers (all from the report; "must be 0" lines):
| Check | Result |
|---|---|
| lanes | 449, 75.3 km, on 167 street pieces between 96 nodes |
| lane points off the asphalt / over nothing / too near a kerb for a car's width | 0 / 0 / 0 of 41,619 |
| paths through junctions touching a kerb (car width) | 0 of 974 |
| steepest lane, largest height kink | 8.0 %, 1 cm |
| approaches with no way on, streets of an unknown kind | 0, 0 |
| pavements | 880 stretches, 61.0 km; points on the road 0 |
| pavement points with no ground | 9: eight at the centre junction's missing corners (below), one at the waterfront junction's beach stub |
| crossings | 276 (101 at signals); 4 have no paint (the truck junction paints stop bars only) |
| kerb stalls off the asphalt | 0 |

FOUND IN THE MAP (for Yasin; nothing was changed):
- 1st St (bay front) has a HOLE of 54 m, from u 328 to 372 at v -1600: no street is built there (the place kept for
  the ferry landing). The lanes and pavements are cut at both edges; no traffic passes until it is built.
- The city-centre junction (Amber x 7th) has NO GROUND under its four pavement corners (about 6 x 6 m each, inside
  the kerb returns; checked two ways, nothing in the baked cell covers them). People would walk over a hole there.
- The truck junction (J Ave x 3rd) has stop bars but no painted crossings; people cross there on unmarked crossings.
- The bridge's far end is where the map ends: cars will appear and leave there.
- Driveways into car parks are not recorded (section 14): the 1,514 car-park stalls are for parked cars only.

Not done in 2a, said plainly: the 3rd / 4th St left-turn pockets (the painted centre lane before a junction) are not
lanes yet: a car turning left there waits in the inner through lane. Lanes are one per direction where a block is
partly one lane wide. Both are on the list for after the traffic runs.

## 16. Stage 2b result: the traffic core drives on the new streets (19 Nov, 03:40)
The old game's traffic core (`traffic_sim.h`, `traffic_setup.cpp`, `traffic_step.cpp`, `traffic_route.cpp`, 2,500
lines) is in `native/src`, fitted to this map, behind the C++ class `CityTraffic` (`city_traffic.*`). No drawing yet:
this stage is the driving itself, proven by a test with no picture.

THE TEST: `godot --headless --path . -s res://tests/traffic/test_traffic_core.gd -- --minutes=30` -> RESULT PASS.
Nine runs of 30 traffic minutes (20 steps a second, as in the game): the whole city with 190 cars, every car stepped
every tick; and the city centre, the 3rd St arterial, the ring at the waterfront and the bridge's foot as the game
will run them, each at the busiest hour and at twice the busiest hour. In every run:
- no two cars ever overlap (checked once a traffic second by a check of its own), no crash;
- at the busiest hour no car stands longer than 2 minutes anywhere except at a red light, with the old "take a stuck
  car away" rule switched OFF (so nothing is hidden); at twice the busiest hour (more cars than the junctions can
  pass: queues) nothing locks up;
- the same seed gives the same traffic, run after run and process after process;
- one step for 190 cars: 0.32 ms on this PC (a slow laptop); for the 30-35 cars round the camera: 0.02 ms.

WHAT HAD TO CHANGE IN THE OLD CORE FOR THIS MAP (each found by the test, each a real fault on these streets):
1. LEFT TURNS NEVER GOT THROUGH. The map's signals have a 12 s green and no left-turn phase. The old rule made a
   left-turner wait for a long gap in oncoming traffic: on a busy street it stood for good, with its lane behind it.
   Now a car that has waited at its line to turn left takes the amber and the first seconds of red, as drivers do,
   and the street that has just got its green waits for the junction to clear.
2. A FAIRNESS RULE. A car that has waited long at the head of its lane (a side street on the ring, a left-turner)
   asks for a way through, and drivers who can still stop comfortably let it go. Two that ask never wait for each
   other: the one that waited longer goes.
3. LANES CHANGE WHERE THE STREET CHANGES. My first lanes gave a block the fewest lanes of its narrowest part, so two
   lanes merged into one right AT a junction and halved it. Now a street is cut where it really narrows or widens
   (3 places), and the cars merge there.
4. THE LEFT-TURN LANES ARE REAL LANES. The arterials paint a left-turn lane in the middle before a signal (white
   arrows). The tool finds them from the paint (60 of them); cars that turn left wait there and the two through
   lanes stay free.
5. HOW MANY CARS. The old game asked for its full number of cars wherever the camera was. Now each street carries
   what its kind carries (cars per metre of lane, chosen as about half of what this map's junctions can pass), and
   the number given to the traffic is only the upper limit. Round the city centre that is about 32 cars within
   340 m at the busiest hour; the whole city about 330.
6. A CAR STUCK SIDEWAYS. A car that stopped at its line a little to one side was never let into the junction
   ("straighten up first"), and standing still it could not: it stood for ever. After 4 s it now goes.
7. THE EDGE OF THE MAP. The bridge's far end is a way out and a way in: cars drive on to it at speed and are gone,
   others arrive from it. The hole in 1st St is a true dead end: cars do not drive into it.
8. THE OLD CORE READS A VALUE IT NEVER SET, somewhere in its step (found because two identical runs differed by a
   car or two; the compiler's own checks do not find the place, and nor did I). The module is now built so that every
   local value starts at zero (`-ftrivial-auto-var-init=zero`, in `native/build.sh`, on the PC and on the phone
   alike), which makes the behaviour defined and the same everywhere. Said plainly: the fault is contained, not
   located.

Not solved, said plainly:
- At twice the busiest hour the city centre still has left-turners that wait up to three and a half minutes. That
  is beyond what the streets carry, but it shows the limit: this map's signal plan is tight.
- Left-turn lanes exist where they are painted (3rd / 4th St, the ring). Amber has none: a car turning left off
  Amber waits in the inner lane, and the lane behind it waits or changes lane.
- Buses, the old taxi ride and scripted cars: the code came over with the core, nothing uses it yet.

## 17. Stage 2c result: the traffic is DRAWN, with the parked cars (19 Nov, on the PC; the phone is Stage 2d)
The C++ node `CityTraffic` now runs the traffic in the test app: `--traffic=N` (most moving cars; 0 = none, the
default), `--parked=1|0`, `--density=x`, `--carshadows=1|0`, `--carbodies=1|0` (`tools/city/rig/rig.gd`; the script
only sets these numbers and asks for one report line a drive). Pictures: `review/traffic/pc/` (day and night;
`tools/city/traffic/traffic_shots.gd` takes them again).

HOW IT RUNS (no script in any frame or tick):
- THE DRIVING runs on its own thread, 20 steps a second. The main thread never waits for it: it copies the last two
  poses of every car (a lock held for a copy) and draws each car between them, so cars move smoothly at any frame rate.
  It never touches the engine's thread pool (the streamer's).
- DRAWING: no node per car. Every car is a row in one of a few batches (the graphics card draws a batch in one call):
  the near model (5-9 thousand triangles, the 4 nearest moving cars within 22 m), the light model (2.4-4.4 thousand,
  to 85 m), and ONE 60-triangle shape for every car beyond that. On a street on the PC: 4 to 10 batches a frame.
- PARKED CARS are the light model within 35 m and the 60-triangle shape beyond (Yasin: "low detail only": the near
  model is never used for a parked car). Which stall is taken, by which car and colour, comes from the stall's own
  number: the same street every time. 70 % of kerb stalls, 55 % of car-park stalls. The far batch of ALL parked cars
  of the loaded cells is sent to the graphics card only when a cell comes or goes; the cut between the two versions
  is done by the shader at the same distance in both, so there is never a gap or a double car.
- CELLS: cars appear only on streets whose cell is loaded and leave with their cell (the streamer's `cell_in` /
  `cell_out` signals; nothing in the streamer changed).
- THE RING MOVES WITH THE SPEED: cars appear in a ring whose centre runs 2 s ahead of the camera (200 m at most),
  and the faster the camera, the more tries a step. On the PC loop: 22.6 cars round the camera at 108 km/h, 23.9 at
  281 km/h (the streets there carry 23-25). Before the fix it was 10 at 281 km/h.
- LAMPS: head and tail lights are one more batch of small glows (tail lights brighter when braking, by day too
  within 60 m); a lamp shows only to the side it faces. They do not light the road (a real light per car is too dear
  on the phone). The car models do not mark their lamp texels, so my first way (the car's own shader) lit nothing.
- COLLISION: a pool of 24 boxes, made once and only moved: the nearest moving cars within 70 m and parked cars
  within 30 m get one, at most 2 newly placed a physics step. On its own layer (5): the test camera's ground ray does
  not see it.
- THE SIGNAL LAMPS AND THE TRAFFIC SHARE ONE CLOCK. Two additions to the bake's prop shader
  (`shaders/rt/rt_prop.gdshaderinc`, the lines of the signal lamp only; said here because the brief says to):
  the lamps read the traffic's clock (`ck_signal_time`; -1 = no traffic, their own clock as before) and take their
  junction's start from the same whole-second number as the traffic. FOUND ON THE WAY: the lamps found their
  junction by a fixed 200 m lattice, and the junctions at x = 500 lay ON a lattice line, so the heads of ONE junction
  ran on two clocks (9 heads). The streets tool now searches the lattice so that every head stands at least 31 m
  inside its junction's tile (`ck_signal_grid`, a new check that must be 0: it is 0 of 168 heads).

THE TRAFFIC ITSELF GOT BETTER (the test of Stage 2b failed after the signal clock changed; both causes were real):
- STRAIGHT BEFORE LEFT. A car going straight on at a green could be starved by oncoming cars turning left across
  it, each cleared while still rolling up to the line (3rd St: one stood through four greens). It now asks, and
  the left-turners that can still stop let it go.
- A CAR STANDING WITH ITS NOSE ON THE LINE never let a long-waiting car through (the rule asked for half a metre to
  spare). A standing car can always stay standing.
- Test now: RESULT PASS, and at TWICE the busiest hour no car stands over 2 minutes anywhere (it was up to 3.5).

MEASURED ON THE PC (a slow laptop, 960x540, loop at 108 / 210 / 281 km/h, most 80 cars, parked cars on):
main thread for the traffic 0.09-0.10 ms a frame (worst 2.1), the driving step 0.03-0.04 ms on its own thread
(worst 2.3), 5-6 batches drawn, 4-5 of them sent a frame, about 500-560 parked cars in the loaded cells of which 5
stand within 35 m. The phone numbers are Stage 2d.

ALSO: the cars' paint is a weighted pick (white 18 %, black, silver, grey 15 % each, blue, red, beige, green, light
blue, maroon); the car models are now IN the phone build (`vehicles/*` was excluded from the export, `streets.bin`
is included); the cars' credits came over (`vehicles/CAR_CREDITS.md`: Daniel Zhabotinsky and MaG80, CC BY 4.0).

NOT DONE YET, said plainly:
- A parked car does not pull out and a moving one does not park (section 14, point 2). Moving cars keep clear of
  parked ones because the kerb stalls lie in the parking strip beside the lane (0.85 m between a lane's car and a
  parked car on the 5.7 m streets); the narrow streets have no stalls.
- Wheels do not turn; indicators do not blink (the lamp batch has no amber yet).
- The far shape is one model's (a saloon) scaled to each car: a bus beyond 85 m is a long saloon.
- One far picture showed coloured squares: that was the old `streets.bin` (no slope value for parked cars) giving
  broken rows; rebuilt, and a row can no longer be broken. Run `make_streets.gd` after every bake.
- Walkers and parked cars: Stage 3.

## 18. Stage 2d result: the traffic on the phone, and parked cars that pull out and park (19 Nov)

### What a street with traffic costs (Redmi, Mali-G610, 3D at 720p, the stream loop at 108 / 210 / 281 km/h)
Runs in `review/phone/`: `traffic0_stream` (the same app, no traffic), `traffic20_stream` / `traffic20b_stream`,
`traffic40_stream` / `traffic40b_stream`, `traffic80_stream`, `traffic40_noparked_stream`, `traffic40_zones`.
Every number is the range over the three drives of a run.

| run | moving cars (average / most) | parked cars in the loaded cells | draws (average) | triangles (average) | GPU ms (median / p95) | frame ms (median) | traffic on the main thread | physics wait (median) | the stream gate |
|---|---|---|---|---|---|---|---|---|---|
| no traffic | 0 | 0 | 79-82 | 410-436 k | 13.6-13.7 / 15.2-15.4 | 16.4-16.8 | 0 | 0.5 | PASS |
| `--traffic=20` | 18-19 / 20 | 500-550 | 89-93 | 515-543 k | 13.5-13.7 / 15.7-16.1 | 16.3-16.8 | 0.22-0.25 ms | 0.4 | first run FAIL (one frame of 59 ms), repeat PASS |
| `--traffic=40 --density=1.7` | 31-33 / 40 | 510-550 | 91-94 | 535-562 k | 13.6-13.7 / 15.7-16.4 | 16.4-16.8 | 0.26 ms | 0.5-0.6 | PASS, twice |
| `--traffic=80 --density=3.4` | 36-39 / 57 | 510-555 | 92-95 | 549-575 k | 13.6-13.7 / 15.8-16.5 | 16.4-16.8 | 0.26-0.28 ms | 0.4-0.6 | PASS |
| `--traffic=40`, parked cars OFF | 31-33 / 40 | 0 | 85-90 | 447-488 k | 13.6 / 15.3-15.8 | 16.4-16.7 | 0.20 ms | 0.5-0.6 | PASS |

SAID PLAINLY:
- A STREET WITH TRAFFIC AND PARKED CARS COSTS about 12 more draws, about 125,000 more triangles, 0.26 ms of the main
  thread, and nothing I can measure in the frame time: the median frame is 16.4-16.8 ms with and without traffic
  (the phone is held by its screen rate), the GPU's median moves by less than 0.1 ms and its 95th percentile by
  0.5 to 1 ms. The driving itself runs on its own thread: 0.16 ms a step for 20 cars, 0.27 ms for 40 (worst 2.3 ms), 20 times a
  second.
  The physics thread's wait does not change (the cars' 24 boxes are only moved). Memory: about 11-15 MB more
  graphics memory, 2-3 MB more of the app's own.
- THE PARKED CARS ALONE (the line with them off against the line with them on): 5 more draws, about 85,000 more
  triangles, 0.06 ms on the main thread, no measurable GPU time. About 500 stand in the loaded cells at any time,
  6 of them near enough for the light model.
- "80 cars" WAS NOT REACHED. The streets round the camera carry about 26 at the busiest hour; asking for 3.4 times
  that gave 36-39 on average and 57 at most, because a car needs a free gap to appear in. The cost above did not
  grow between 31 and 39 cars. More than about 57 moving cars within 340 m does not happen on these streets.
- THE ONE FAILED RUN: the first run with traffic after installing the app had one frame of 59 ms in its first drive
  (the run without traffic had 49 ms at the same moment; the limit is 50). The traffic's own work in that frame was
  1.3 ms; the time was the engine preparing the car shaders for the first time (`draw_cpu 16 ms`). Every later run
  passed, also after a new install of the final app. The warm-up draws every car batch behind the loading screen, but
  it does not catch everything on the very first start after an install: NOT SOLVED, said so.
- At 281 km/h the cars are there: 18.7 of 20, 32.5 of 40 round the camera (the ring runs ahead with the speed).

### Parked cars are part of the traffic now (section 14, point 2)
`native/src/traffic_parking.h`, on the old core's own "drive to a goal and pull over" (the buses' and the taxi's).
A parked car and a moving car are the same car in two states:
- A PARKED CAR PULLS OUT: about every few seconds one of the parked cars at a kerb within 300 m starts, when its lane
  is free for 45 m behind and the stall ahead is empty; it keeps its model and colour, its stall is empty from then.
- A MOVING CAR PARKS: a car picks a free kerb stall 35-120 m ahead on its own lane (the stall before it must be
  free: it swings in nose first), slows, steers in over the last 14 m and stops; the stall takes its model and
  colour and the moving car is gone. Buses do not park.
- While a car goes in or out, the parked cars round it are boxes to the driving core: it never moves into them.
  Otherwise the lanes themselves keep 0.85 m off the parked cars.
- A cell that leaves puts its stalls back to what they hold at first: the same street every time you come back.
- THE TEST (`tests/traffic/test_traffic_core.gd`, 12 runs now) has three runs with parking: in 30 traffic minutes
  72 / 38 / 59 cars pulled out and 52 / 16 / 37 parked, and NO moving car ever touched a parked one (checked once a
  second with a check of its own). RESULT PASS. On the phone loop: 22-28 pulled out and 5-8 parked in 2.5 minutes.
- WHAT THE CORE NEEDED: a car pulling in steers as hard as one changing lane (at the gentle rate it stopped with the
  sideways move unfinished), and it does not "drive round" the car standing in the next stall.

NOT DONE in the traffic, said plainly: wheels do not turn, indicators do not blink; a car does not reverse into a
stall (it needs the stall before it free); car parks take no part (the pieces do not record their driveways); the
far shape of a bus is a stretched saloon; the very first start after an install can show one slow frame (above).

THE ZONES PLAN (teleports between the zones, day and night, `traffic40_zones` against `traffic0_zones`): with 40 cars
no drive has a frame over 33 ms except one of 33 ms (the night drives too: the lamp glows cost nothing measurable).
Both runs FAIL the gate at the same place for the same reason, with and without traffic: at the `gritty_night`
teleport a collision body waits 5.0 s (limit 3 s) and the teleport is ready after 3.6 s. That is this branch's
streamer (the collision work of the streaming session is not merged here), not the traffic.

THE TERRAIN (Yasin, 19 Nov: "did you check the terrain while you were writing the code?"). What was checked: every
lane, pavement and stall takes its height from the BAKED GROUND of the cells (the graded pieces), and the tool checks
it: lanes run from 1.4 m to 14.0 m, the steepest stretch is 7.8 % (153 of 3,093 stretches are steeper than 4 %), no
lane point and no stall is without ground, the largest height kink at a lane point is 1.6 cm; a parked car's slope
is read from the ground under it (steepest 7.4 %); moving cars pitch with their lane. What was NOT checked: the
separate terrain files (`map_dc/coronado/terrain/data_citykit`, the land between and round the pieces): this code
never reads them. Cars and people are only on the pieces' streets and pavements, so they do not need them, but where
the terrain and a piece's ground disagree, this job would not see it. Also: a car does not lean sideways (no roll:
on a street with a cross slope it stands level across); 9 pavement points have no ground (the holes of section 15).

## 21. Cars that STEER, and a car to drive (19 Nov, on the working branch)
Yasin: "cars just slide into turns instead of steering into turns, take abrupt u turns, lock the traffic up ... make
the cars and their physics gta 5 level, if not minimum gta 4 ... 100% in C plus plus".

### What was wrong, and what was kept
The old core's BRAIN is sound and stays: following by time gap, junction go-aheads, signals, stop signs, right of way,
"never move into a body", the spawn ring, the parking's books. Its BODY was the fault: a car was a dot at (lane, s,
sideways offset) with its nose glued to the line's direction. Through a bend the whole car pivoted about its middle
(it "slid"), a lane change was a sideways slide, and nothing limited how fast it could turn.

### The body now (`native/src/traffic_body.h`, used by `traffic_step.cpp`)
- The core's (s, lat) is only THE LINE THE DRIVER AIMS FOR. The car is a steered body: front wheels turn at a
  driver's hand rate (1 rad/s), no further than their lock (35 degrees, a bus 46) and no further than gives 4 m/s2 of
  sideways push at its speed; the rear axle follows. The driver looks 2.6-12 m down his line (by speed) and steers at
  that point. The heading changes only because the car moves on turned wheels: no turning on the spot, no turn
  tighter than a car's, no sideways slide.
- The veto ("never move into a body") is on the body's own box. s is where the body's middle lies along the line.
- The line itself moves sideways only as a car can steer: its sideways speed builds and runs out no faster than a
  6.7 m radius allows, and it slows into its place without a kink.
- Into and out of a kerb stall a car drives an S laid along the ROAD (20 m in, ending 4 m before it stops; 11 m out),
  and only where the kerb is free for it (no parked car in the 20 m before the stall / 15.5 m after it). A car that is
  out of its lane keeps seeing the parked cars round it until it is back (it used to forget them after 9 s).
- In a junction a car is slow enough for the SHARPEST part of its path (the old cap smoothed a path's bend over 10 m).
- The body leans out of a turn and dips under the brakes (a spring) and swings back; near and light models are
  drawn leaning.
- U-turns: the streets have no U-turn paths (the streets tool makes straight, left and right only).

### The test (`tests/traffic/test_traffic_core.gd`, 12 runs of 30 traffic minutes): RESULT PASS
| | old body (sections 16-18) | steered body |
|---|---|---|
| overlapping pairs; cars standing over 2 min not at a red | 0; 0 | 0; 0 |
| crashes / emergency brakes / moves refused, a run | 0 / 0-2 / 0-2 | 0 / 0 / 0 |
| hardest sideways push | up to 11 m/s2 | 4.0 m/s2 |
| most turn of a near car in one step (a twentieth of a second) | whatever the line does | 2.5 degrees |
| a car holding its lane: its middle off its line | 0 (it IS the line) | 0.22 m at most |
| while it changes line (lane change, pulling out or in): behind its line | 0 | up to 1.2 m (it follows, never leads) |
| in a junction: its middle off the path | 0 | 0.80 m at most (right turns at 5 m/s) |
| a moving car touching a parked one | 0 | 0 |
| a car in its stall: off the middle / off the direction | set there | 0.00 m / 0.0 degrees (driven there) |
| cars that parked in 30 min (residential / centre / high street) | 38-42 / 19-20 / 30-33 | 24 / 9 / 11 (they need free kerb now) |
| a step for 190 cars on the PC | 0.32 ms | 0.36 ms |
The same seed gives the same state. Lock test RESULT PASS. To follow ONE car: `-- --trace=ID --only=PART_OF_RUN_NAME`.

### The kerbs: what is checked and what is NOT
The streets tool (`street_build.cpp`, `check_paths`) now DRIVES the steered body (the longest, widest car, at the
turn's own speed) along every junction path and picks, per path, the curve on which neither the path as wide as a
car nor the driven body leaves the asphalt. Run on today's bake (layout 2d21a036): 109,239 places of the body
checked, off the asphalt in 280 on 10 paths, ALL at the three places where that bake's Amber Ave is broken (below);
the other 1,287 paths are clean. BUT `streets.bin` in git is still the one made from the earlier bake (55b2b1dc): on
it the body was NOT checked against the ground (that bake is gone) and its curves were chosen for the old body. So
"a steered car never touches a kerb" is NOT proven for the file in git. It needs a fresh bake and a streets run.

### FOUND IN THE MAP (not the traffic code): Amber Ave between z -1100 and -800
On today's bake the tool measures Amber Ave's blocks b038 / b039 differently from the bake the streets were made
from: b039's kerb is 4.5 m from the middle instead of 11.5 m, the median is gone, "LANES CHANGE 2 + 2 -> 1 + 1" at
(-1.8, -1096) and (-1.6, -936), node 36 moved 5.5 m, 9 paths touch a kerb at nodes 37 / 96 / 97, 1 lane point and 1
kerb stall are off the asphalt. On a streets file made from it the whole-city traffic run jams at (-8, -826).
Something lies over Amber's outer lanes there since the growth was merged. NOT looked at (no picture taken), nothing
changed. The report is kept locally (`OUT/streets_report_bake_2d21a036_v2.txt`). Until Yasin says, the committed
`streets.bin` stays.

### The physical car (`native/src/veh_dyn.h/.cpp`, plain C++; `native/src/city_car.*`, class `CityCar`)
For the car the player drives (and, next, for a traffic car that is hit). A rigid body on four sprung wheels:
- springs with a softer way in than out, bump stops, an anti-roll bar per axle, a roll-centre height (how much it leans);
- tyres that keep how far their tread is bent: that one state gives the grip curve (rise, peak, a little less
  beyond it: the slide), a locked wheel's pull, and a car that stands still on a hill; forward and side grip share
  one circle;
- engine torque by revs, a clutch that takes up from idle like an automatic, gears by revs and pedal with a cut in
  pull, a differential with a little lock, front / rear / all wheel drive; brakes by axle, a handbrake, ABS;
- a steering lock that shrinks with speed to what the tyres can use, the inner wheel turning more than the outer,
  the wheel easing toward a slide.
Two FEELS for each of the 12 models (`make_spec`): IV = soft springs, little damping, a low roll centre, tyres that
let go early and gently (it leans, dives, squats, slides); V = stiffer, flatter, more grip, ABS.
`CityCar` puts it on one of the engine's rigid bodies: the engine keeps the place and does the crashes, the C++ works
out every force in 6 small steps a physics step (one ray per wheel). Body and wheels are drawn apart (meshes
`*_q_body.res` and `*_q_w0..3.res`, 2.3 MB, brought from the old game: the body mesh notes where its wheels are and
the physical wheels sit exactly there). Keys, pad and a chase camera are in the class. `CityTraffic.set_player_car`
gives the traffic the player's car as a box: drivers brake for it and go round it.

Console test (`bash native/tests/run_veh_test.sh`, no Godot, 12 cars x 2 feels): RESULT PASS. The saloon (stern_g):
0-100 km/h in 8.0 s, top 223 km/h, 100-0 in 46.8 m, side grip 0.93 g, leans 3.4 degrees at half a g and 5.9 at the
limit, dives 4.1 degrees under the brakes, its tail comes out under power (IV); 7.9 s, 37.6 m with ABS, 1.08 g, 1.2 /
2.4 degrees (V). The sports car: 4.8 s / 3.7 s, 326 km/h. Front-drive cars push wide instead of sliding. Every car
stands still, holds a 15 % hill on the handbrake, settles after a sudden turn of the wheel; a handbrake turn brings
the tail round (not the buses').
Engine test (`tests/car/test_city_car.gd`, headless, `--fixed-fps 60`): RESULT PASS for stern_g IV and fiamma_r V:
the same 0-100 and braking as the console test (8.0 s, 47.2 m; 3.8 s, 35.5 m), a wall at 68-73 km/h stops it where
it is, upright; it reverses away.
Drive it: `--car=stern_g` (GTA 4 feel) or `--car=stern_g/V`, with `--at=x,z,yaw` and `--traffic=N` (rig.gd).

### NOT done / NOT checked
- Nobody has DRIVEN it: the feel is tuned to numbers, not to a hand. Yasin drives, says what is wrong, it is tuned.
- The engine test ran on the PC's default physics engine. The phone runs Jolt: not run there. No phone run of any of
  this (the Redmi comes last).
- `--car` in the test app was TRIED UNATTENDED (19 Nov evening, `-- --car=stern_g --at=-600,-1000,90 --traffic=20
  --quit`, which leaves by itself after 12 s): the car is set on the street of the streamed city and stands on its
  four wheels, the traffic runs beside it. Two faults found by that try and mended: the car was set down before the
  street's collision was there (it fell through the world), and a start point exactly on a cell's edge (every 200 m)
  has no ground a ray can find. Left alone it now holds itself (no creep). NOBODY HAS PRESSED A KEY IN IT YET.
- A traffic car that is hit still stops as a box for a few seconds; it is not yet handed to the physical car to be
  shoved and spun. That hand-over is the next step.
- Traffic cars' wheels are part of one mesh: they do not turn or steer on screen (the body's lean is drawn).
- No engine sound, no tyre marks, no damage.

## 22. People, step 1: a body that keeps its own balance (19 Nov, on the working branch)
Yasin: "i want my gta 5 level npcs ... they need to balance themselves, be able to pushed around and resist falls,
just like in the euphoria engine GTA4 minimum"; "you can get the old npcs from the game BUT FULLY WRITTEN IN C PLUS
PLUS, not a single script if you can help it"; "i have about 40 animated bodies standard with 50 bones".

### What it is
- `native/src/ped_body.h/.cpp` (plain C++, class `pb::Person`): thirteen jointed bodies (pelvis, chest, head, upper
  arms, forearms, thighs, calves, feet) with muscles and a small physics of their own, 8 small steps a frame. No
  engine joints: the same on the PC and on the phone.
  BALANCE: the upper body is real, the legs carry it. It watches the point on the ground it is falling toward
  (where it is + its speed x a third of a second). While that point is under its feet it only moves where it presses
  on them: small pushes are held without a step. When the point leaves its feet it steps, quickly, to where the
  point WILL be when the foot lands, again and again if it must (to the side with cross-over steps); then it shifts
  its weight onto one foot and brings the other home. `skill` makes a person steadier or frailer.
  FALL: when it cannot be caught the legs become bodies too: a rag doll whose arms reach for the ground on the side
  it falls to, whose knees fold and whose neck holds, and whose strength drains away in about a second.
  REST: it lies still. Cars are moving boxes it is pushed and thrown by.
- `native/src/city_ped.*` (class `CityPed`): the old game's 50-bone figure. Animated while nothing touches it; at a
  `push` (or a car's box reaching it) the body takes over FROM THE POSE THE BONES HAD, the bones follow the body, and
  afterwards the animation is blended back in (standing), or the "get_up" clip from how it lies.
- Brought from the old game: `characters/rocketbox/` (41 bodies in three detail levels, the two skeleton scenes, 49
  clips each for men and women, the two texture arrays, the person shaders), 36 MB. Microsoft Rocketbox, MIT licence
  (LICENSE.txt is with them).

### What was measured
Console test `bash native/tests/run_ped_test.sh` (26 cases, a shove = a push lasting a fifth of a second): RESULT PASS.
| what is done to it | what it does |
|---|---|
| nothing; nothing on a 14 % slope | stands, 0 steps |
| 15 N s (a nudge) | no step, leans 5 degrees |
| 30 / 50 N s from behind | 1 / 2 steps, 0.2 / 0.3 m, quiet again after 1.9 / 1.4 s |
| 80 / 120 / 170 N s from behind | 3 / 3 / 5 steps, 0.7 / 1.1 / 2.3 m, leans 11-18 degrees, quiet after 1.9-2.4 s |
| 240 N s and more from behind | goes down (after 5 steps), lies still |
| 80 / 170 N s in the chest | 3 / 7 steps backward, 0.7 / 3.3 m, stays up |
| 30 / 80 N s from the side | no step / 5 steps, stays up; 170 from the side: goes down after 8 steps |
| 60 N s at one shoulder; a kick of 90 N s at a leg | 2 / 6 steps, stays up |
| a frail person (skill 0.55) | holds 50 N s, goes down at 120 |
| an athlete (skill 1.3) | holds 170 N s in 3 steps |
| a car at walking pace | is pushed along on its feet, 7 m |
| a car at 30 / 60 km/h | thrown 12 / 27 m, lies still |
In every case: no part faster than 28 m/s, nothing under the ground, nothing left inside the car.
Engine test `tests/people/test_city_ped.gd` (headless, the real figure M1): RESULT PASS. It stands in its animation
(50 bones, head joint 1.59 m up); the body takes over with no jump (0.000 m); 60 N s: 2 steps, no fall, the animation
takes over again at the same height; 420 N s: down, still, up again; a car at 30 km/h: down, still, up again.
ONE look by eye (`review/people_19nov/body_sheet.jpg`, five pictures from the side): the figure's limbs follow the
body correctly (a real stride in the stagger, flat on the ground after the charge, nothing twisted).

### NOT done / NOT checked
- It was looked at in FIVE still pictures, never in motion. How the stagger, the fall and the get-up LOOK is not
  judged. In the picture taken 1.3 s into the get-up the figure already stands: the rise from the ground is probably
  too quick or the clip does not start lying. To be looked at in motion.
- The person wears one plain colour: the people's real look (texture arrays, outfit colours) is the crowd's drawing.
- THE WALKING CROWD IS NOT HERE: who walks where, crossings, groups, places, reactions, talking (sections 4 and 10,
  stages 3a-4). The crowd core on the other branch does not pass its test. This step is only the body of one person.
- Nothing calls `CityPed` yet but the two tests: no player on foot, the traffic's cars are not handed to it as boxes.
- While it balances its legs are drawn from hip to foot (not bodies): they can pass through each other in a
  cross-over step. Its parts do not collide with each other, nor with walls and props (only the ground and cars).
- The muscles pull toward the standing pose with the arms down, not toward the animation's pose.
- Not on the phone. Its cost was not measured (it is 13 bodies, 12 joints, 8 small steps a frame for each person
  that is physical at that moment; a handful at once is the intent).

### The get-up, looked into (19 Nov evening)
FOUND IN THE CLIPS: the old game's set has NO rise from lying. `get_up`, `wake_up`, `stand_up` (and `sit_to_stand`)
are one and the same clip, a rise from a SEAT (the hips start 42 cm lower, are up after 1.6 s); `die` is a copy of
`idle`; `sleep` is the only lying pose. That is why the figure stood 1.3 s after it lay flat: the lying pose was
blended straight into a clip that is already rising.
INTERIM (in `CityPed::to_animation`): for the first second the clip barely runs (0.3 of its pace) while the pose the
body lay in is blended into the clip's seated start: it gathers itself into a crouch; then it rises at the clip's own
pace. Lying to standing now takes 3.2 s. Engine test RESULT PASS; four pictures `review/people_19nov/getup_sheet.jpg`
(lies, crouches 0.8 s in, nearly up 1.9 s in, stands).
THIS IS STILL A BLEND, NOT A GET-UP: nobody rolls over, props himself on his hands, or gets a knee under him. The real
one is the body pushing itself up with its own muscles (to be done with the crowd), or two new clips (from the back,
from the front). Never seen in motion.

## 23. A car that is hit is a real car (19 Nov evening, on the working branch)
Yasin, after the compaction: "act like a developer working for rockstars next GTA and tackle the problems".
The problem: a traffic car that was hit only stood still for a few seconds, and the player's car did not even touch
the traffic's boxes (its collision mask did not include their layer): it drove through them.

### What it is (all in `CityTraffic`, `native/src/city_traffic_run.cpp`: `knock`, `loose_update`, `_physics_process`)
- SIX PHYSICAL CARS are made at the start and put away (class `CityCar`: the same springs, tyres and weight the
  player drives). Every model's body and wheel meshes are held from the start, so a knock makes and loads nothing.
- Every physics step each car near the camera (a moving row or a parked car) is tested against the player's car and
  against every car already knocked loose: will the two boxes touch within a sixth of a second at the speed they
  come at each other (over 1.2 m/s)? If so the traffic car STOPS BEING A ROW AND A BOX: a physical car takes its
  model, colour, place, speed and wheel angle a moment BEFORE the touch. The knock itself is the engine's: weight
  against weight, shoved, spun, rolled. A knocked car knocks the next one the same way (a pile-up).
- A parked car that is knocked stands with its handbrake on. A driver who is hit holds his wheel for a third of a
  second, then brakes.
- AFTERWARDS: a driver whose car stands on its wheels, along a lane (within 23 degrees), within 3.6 m of it, with
  nothing in its way, DRIVES ON after 3.5 s: the car is a car of the traffic again from that very place and steers
  back to its lane (the same steered pull-out as from a kerb). Otherwise it stays where it lies; the traffic sees it
  as a box, brakes for it and goes round it. It is taken away when the camera is 120 m off (180 m if still moving).
  A knocked parked car never drives on.
- The traffic's collision boxes are STATIC now, not kinematic (see the trap below).
- `set_player_car` gives the player's car the traffic's layer in its mask, and the knocked cars take its feel (IV / V).

### What was measured
`godot --headless --path . -s res://tests/traffic/test_knock.gd` (real streets, real traffic, a flat test ground; in
real time, about a minute): RESULT PASS.
- into a parked car at about 40 km/h, 45 degrees onto its flank: it became a physical car, its stall is empty, it was
  shoved 7.0 m, fastest 6.5 m/s, 0.03 m from the ground's height; the player's car felt 16 g and is on its wheels;
- head-on into a moving car (31 km/h against 43 km/h): it became a physical car, pushed back 3.8 m, both on their
  wheels;
- with the player's car against its bumper its driver stays (refused: something stands in its way); 0.3 s after the
  player's car is out of the way he drives on as a car of the traffic.
The car's own engine test (tests/car) RESULT PASS again with the same numbers (its setup code was split in two).

### NOT done / NOT checked
- NOBODY HAS SEEN IT: no window was opened. How a knock LOOKS is not judged.
- Not tried in the streamed city (the test lays its own flat ground), not on the phone / Jolt.
- The 12-run traffic test was NOT rerun: the core and its test path were not touched (the knock lives in the game's
  step, not in `run_test`).
- A driver whose car lies across the road or on its roof stays for good: no reversing, no three-point turn, nobody
  gets out. No damage, no dents, no smoke, no sound.
- A stall that is knocked in the very frame its car pulls out could give two cars for one (not seen, not excluded).
- Each knocked car is 5 draws (body and four wheels) while it is out: up to 30 with all six out.
- Buses can be knocked like cars; never tried.

### The trap (paid for with one run)
A KINEMATIC body that is moved from one car to another, or put away 500 m below, counts that jump as its speed for a
step and hands it to whatever it touches: the first knocked car left at 28,000 m/s. The pool's boxes were kinematic
since stage 2c and are reassigned to the nearest cars every frame; nothing could touch them until now.

## 24. The traffic's wheels turn (19 Nov evening)
The cars right by the camera (the four nearest within 22 m, the "near model") are drawn as a body and four wheels
now: per model ONE more batch, four rows a car, the one wheel mesh turned about for the right-hand side
(`CityTraffic::put_wheels`). The front wheels show the angle the driver's hands hold (the steered body's own number),
all four roll by the metres the car has gone, and they stay on the road while the body leans and dips over them.
Beyond 22 m nothing changed (one mesh a car, wheels and all). Cost: at most 4 more draws (one for each model among
the four nearest cars), 16 rows a frame.
SEEN ONCE: `review/traffic_19nov/wheels_sheet.jpg` (a van in a bend, front wheels 9 degrees to the left, from its
front corner and from above): the wheels sit in their arches, the front one is turned, the rim faces out.
NOT CHECKED: the right-hand wheels (the same mesh turned about) were not in the picture; never seen in motion (do
they roll the right way); buses; the phone. Around (-600, -1000) no car turned its front wheels more than 12 degrees
in 75 s: the bends there are wide.
