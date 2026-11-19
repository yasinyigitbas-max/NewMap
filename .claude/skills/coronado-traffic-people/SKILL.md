---
name: coronado-traffic-people
description: Traffic, parked cars and the walking crowd of Coronado's city kit map, all in C++ (the native module in native/, classes CityTraffic, CityCrowd, StreetGraph). Read before touching native/src, tools/city/traffic, tests/traffic, tests/crowd, streets.bin, the rig's --traffic options, or any phone measurement of traffic or people; for "cars go on the pavement", "cars stand at a green", "parked cars cost too much", "people stand inside each other", "is the city sunk under the terrain", and before telling Yasin any of it is done. Holds the build, the pipeline after a bake, the checks that must be 0, the traps that cost hours on 19 Nov 2026, and how to do this work without burning Yasin's usage or his PC.
---

# Coronado traffic and people (C++), learned 19 Nov 2026

The full record is `docs/TRAFFIC_PEOPLE_PORT.md` (sections 13-20 are results). The job board entry is at the top of
`map_dc/coronado/city_kit/JOB_BOARD.md`. Read those two, not old transcripts.

## Where it stands (branch `claude/strange-jang-5426ac`, not merged)
- DONE: the module on PC and phone; the streets tool; the old traffic core on the new streets; drawing; parked cars
  that pull out and park; signal lamps on the traffic's clock; phone numbers.
- STARTED, NOT PASSING: the walking crowd (`crowd_sim.*`, `city_crowd.*`, `tests/crowd/test_crowd_core.gd`). It walks
  the pavements, queues at kerbs, uses the signals; people still stand inside each other on narrow pavements.
  `city_crowd.cpp` and the test still carry DEBUG lines (`dbg_kinds`, `near_kinds`): remove before "done".
- NOT STARTED: drawing people (far figures, 18 near bodies), places (doors, benches), reactions, speaking.
- NOT DONE in traffic: wheels turning on screen, indicators, reversing into a stall, car parks, roll on cross slopes,
  a hit traffic car handed to the physical car (`CityCar`).

## Since 19 Nov ~14:00 (working branch `claude/festive-faraday-20ltx2`; doc section 21)
- Traffic cars are STEERED BODIES (`traffic_body.h`): the core's (s, lat) is the line the driver aims for, the body
  follows it on turned wheels. Never bring back a pose made from the line (`pose_at`) for a moving car.
- The physical car: `veh_dyn.*` (plain C++) + `CityCar` (`city_car.*`); two feels (IV, V). Tests:
  `bash native/tests/run_veh_test.sh` (console, seconds) and `tests/car/test_city_car.gd` (headless, `--fixed-fps 60`).
- Traps paid for on 19 Nov: (1) a sideways move must be one a car can steer: lay it along the ROAD (the S of `plan()`),
  not along the clock, or a slow car never finishes it. (2) The body must FOLLOW its line, never lead it: the core has
  only cleared the way as far as the line has gone. (3) A car standing a hand's width off its line took the parked car
  beside it for one ahead of it and stood for good: the body's own corridor has no margin. (4) A car out of its lane
  must keep seeing the parked cars until it is back, not for a fixed time. (5) Junction speed must fit the SHARPEST
  part of a path. (6) `make_streets.gd` on a newer bake silently gives other streets: compare the report's first line
  (layout_sha) and its CHECK lines with git's before keeping the file. (7) One car's history beats ten guesses:
  `--trace=ID --only=PART_OF_RUN_NAME` on the traffic test prints it. (8) A heredoc with an apostrophe in it broke
  again: notes and patches go into a file made with the Write tool. (9) A thing set on the streamed city needs the
  place made ready first (`st.prepare` / `is_ready`), and a ray exactly on a cell's edge (every 200 m) finds no ground.

- People, step 1 (19 Nov ~17:00, doc section 22): `ped_body.*` = a body that balances, staggers, falls, lies (plain
  C++; test `bash native/tests/run_ped_test.sh`, `N` as argument traces case N frame by frame); `city_ped.*` = class
  `CityPed`, the old game's 50-bone figure driven by animation or by that body (tests/people). Paid for: two passive
  spring legs never come to rest after a saving step (the rear leg keeps pushing): the body must choose WHERE ON ITS
  FEET IT PRESSES and step to where it WILL be falling when the foot lands; a foot must not step twice in a row
  because of a sideways drift; a test shove must last (a fifth of a second), a hammer blow folds the body at the
  waist. The walking crowd is still NOT on this branch.

## Yasin's rules for this job (his words are in the doc)
- Everything in C++: no script in any frame or tick, no script fallback. Tool-time scripts are fine.
- Parked cars are LOW DETAIL only. Cars must never touch a pavement, a kerb or grass. Cars move naturally.
- Keep draw calls low; triangles matter less. Budget: 150 draws.
- Short plain words. Say what was NOT checked. "Done" needs the test output.
- Do not merge, do not open a pull request, unless he says so. Locked pieces never change.

## How to work without wasting his usage or his PC (the lesson that hurt most)
Yasin: "half of my fable usage ... went to toilet", "the PC is choking". This PC has 4 threads and 8 GB.
- ONE question, ONE run. Decide what number or picture settles the question before starting anything.
- Never rerun a 12-run test to see one line: print the line you need the first time. Add counters, not reruns.
- No picture hunting. A wide lens at street level lies (parallel parked cars looked angled): take ONE picture from
  straight above, or print the numbers. Do not read picture after picture into the conversation.
- A long run goes to the background, and nothing else heavy runs beside it. Do not run tests, builds or exports while
  Yasin is working on the PC unless he asked.
- Bash heredocs break on apostrophes and turn `\n` inside C strings into real newlines. Write patch scripts with the
  Write tool into `OUT/`, and fix a single line with the Edit tool. Do not fight the shell twice.
- Read a file once. Grep for the lines you need instead of reading 100-line windows again.
- When a check fails, trace the ONE car or walker named in the failure (an id), not the whole run.

## Build
`bash native/build.sh [windows|android|all]`. No scons: it compiles `native/src/*.cpp` and links the prebuilt
godot-cpp libraries in `C:\Users\yasin\NewMap\OUT\native_tools\godot-cpp`. Binaries and the `.gdextension` file are
NOT in git. `-ftrivial-auto-var-init=zero` stays: the old traffic core reads a value it never set.
Do not build Android while a phone export is copying the library.

## The pipeline after EVERY bake (heights and streets are data, never code)
1. `godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/traffic/make_streets.gd -- --nopics`
   -> `city_kit/traffic/streets.bin` + `streets_report.txt`. These must be 0: lane points off the asphalt, paths
   touching a kerb, kerb stalls off the asphalt, stalls without ground, signal heads in another clock tile.
2. `godot --headless --path . -s res://tools/city/traffic/ground_vs_terrain.gd` then
   `python tools/city/traffic/ground_vs_terrain.py` -> buried / floating ground against `zoning/terrain_grid.npz`
   and `review/traffic/ground_vs_terrain.png`.
3. `godot --headless --path . -s res://tests/traffic/test_traffic_core.gd -- --minutes=30` -> RESULT PASS
   (12 runs; no overlap, nobody over 2 minutes, no moving car touching a parked one, same seed same state).
4. `godot --headless --path . -s res://tests/city_kit/test_locked_pieces.gd` -> RESULT PASS.
A stale `streets.bin` gives broken car rows (coloured squares on screen). When a field of the file changes, rebuild it.

## THE TERRAIN (Yasin found the zone sessions' work "sunk in elevation")
- No height is written in the C++ or the tests. Lanes, pavements, stalls, cars and walkers take their height from the
  baked ground through `make_streets.gd`. Fix the elevation, bake, run the pipeline: everything stands on the new ground.
- This code never reads the terrain files. Nobody was checking the built ground against the terrain: step 2 above is
  that check. Run it on the bake you are working on, and say which bake that was.
- Know what your branch contains before answering. On 19 Nov this branch had 443 pieces and the working branch 521:
  the numbers measured here said nothing about the new blocks.
- Wait for the elevation before attaching PLACES to blocks (doors, benches, bus stops). Streets and walking can go on.

## How it is built (so nobody rebuilds it worse)
- TRAFFIC: `tc::Sim` (old game's core, plain C++) on its own thread, 20 steps a second. The main thread copies the
  last two poses and draws between them. It never touches the engine's thread pool.
- DRAWING: no node per car. Rows of a few RenderingServer multimeshes: near model (4 nearest within 22 m), light model
  to 85 m, one 60-triangle shape beyond. Parked: light model within 35 m, the shape to 280 m, nothing beyond; the far
  batch is rebuilt when the camera moved 40 m or a stall changed, never per frame. No car model casts a shadow: one
  shadows-only batch of the shape does it for every car within 55 m. Lamps are one batch of glows.
- PARKING: `traffic_parking.h` on the core's own pull-over (`Sim::park_at`, `Sim::unpark`). A stall's first car comes
  from the stall's number: the same street every time. A cell that leaves resets its stalls.
- SIGNALS: lamps and traffic share `ck_signal_time`; the junction's tile comes from `ck_signal_grid`, searched by the
  streets tool so every head stands in its junction's tile.
- CELLS: the streamer's `cell_in` / `cell_out` signals only. Nothing in `city_stream.gd` or `bake_runtime.gd` changed.
- CROWD: `cc::Sim` (old core) fed by `CityCrowd::load_streets`: the tool's pavement stretches cut into 8 m pieces
  (the core spawns and plans by piece), each with its own measured half width, crossings whole.

## Traps, each paid for
- A fixed lattice for the signal clock put heads of one junction on two clocks (junctions at x = 250, 500, -951).
- The old core starved a car going straight at a green behind oncoming left-turners, and a car standing with its nose
  ON its line never let anybody through. Both fixed in `can_enter`; the test is sensitive to signal offsets.
- A parking car "avoided" the car in the next stall and never entered its own. A parking car must steer at the lane
  change rate or it stops with the sideways move unfinished.
- The car models do not mark their lamp texels: lamps cannot be lit from the car's own shader.
- `vehicles/*` was excluded from the phone export: the car models were not in the app.
- The first run after installing the app can have one slow frame (the engine prepares the car shaders): not solved.
- The crowd core was written for pavements 2-6 m wide; this map's are 1.4-1.6 m. Parties must go single file, waiting
  people must queue, and the old "walk through after 1.5 s" must not be the answer.
- `new cc::Sim()` for every test run: the old `reset()` kept party numbers and slot contents, so one seed gave two runs.
- Its own audit measures followers against a stale centre line: use `CityCrowd::off_walk()` (true distance to any piece).

## The phone (Redmi, shared with other sessions)
`bash tools/city/rig/phone_rig.sh export | install | run NAME args` (`PUSH=0` to keep results local until the end).
Before a run: `adb shell pidof com.yasin.citykit.rig` must be empty; tell the other session by SendMessage; when done
put ITS app back with `adb install -r` and send "phone free". One fresh run after an install proves less than two runs.
Measure with a no-traffic run of the SAME app in the SAME session. Numbers of 19 Nov: doc section 18.
