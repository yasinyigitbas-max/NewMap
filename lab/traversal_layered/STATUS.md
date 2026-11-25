# Lab B (layered, GTA-style): status after step 4

25 Nov 2026. Branch `lab/layered`, folder `lab/traversal_layered/`. **Step 4 is ready to play.** I stopped here, as the
brief says.

## How to play it (Windows)
1. Pull the branch `lab/layered`.
2. Open Godot **4.7.2**. Import `lab/traversal_layered/project.godot` and open it. The editor imports the body once.
3. Press **Play (F5)**. The first time, it downloads 14 clip files from your Drive folder (about 20 MB) and builds the
   clip library on your PC. This takes a few seconds and needs the internet. They go to your Godot user folder, never
   into the repo. After that it starts straight away.
4. Controls (yours, nothing extra):
   - W A S D or the left stick: walk; push the stick far, or hold Shift, to run.
   - Mouse or the right stick: camera. Click to capture the mouse, Esc to release it.
   - Phone: the left half of the screen is the stick, the right half looks.
   - C / Space are read but do nothing yet: crouch and jump are steps 6-7.
   - F1 hides the debug text.
5. The open ground in front of the course is for walking and running. The course (kerbs, stairs, ramps, blocks, fences,
   car, van, ledges, wall tops, low ceiling, cover walls, doors, window, bin) is built, but the player doesn't handle it
   yet. That is steps 5-7. For now he walks into things like a capsule.

**Not tested on Windows by me.** The Windows DLL is built (mingw-w64, needs only KERNEL32 and msvcrt). I tried to run
it under Wine here, but Wine 9 crashes on Godot itself, so I could not test it. Everything else was tested on Linux with
the same Godot 4.7.2. If it doesn't open, send me the first red line in the Output panel.

## What works
- **The stack:** clip locomotion core → inertialization on every switch (no crossfades) → stride / rate warping and
  orientation warping → foot lock and leg IK → lean, head, pelvis, forearm-twist layers. Runtime is C++
  (`native/src`); only the clip build, the HUD and the tests are GDScript.
- **Clips:** retargeted from the Mixamo files onto player_v3 by my own code, the same way for every clip. Each clip is
  measured when it is built: contacts, foot phase, speed, entry and exit marks.
- **Idle**, **walk**, **jog**, **run**, **fast run** in one phase-synced blend. Speed follows the stick. Playback rate
  stays within ±20 %, and stride warping covers the rest.
- **Starts** from standing, chosen by the angle:
  - ahead: weight shift first, then the step;
  - up to 120° off: spins on the stance foot;
  - behind (walking): the walking 180 turn;
  - running 60°+ off: the turning run start.
  - The first visible movement comes 17-67 ms after the stick.
- **Stops** on whichever foot is next. The stop clip is chosen and timed so its planting foot lands when ours would.
- **Pivots** (180° at a run or a walk), turning the asked way.
- **Turns inside the steps** while walking and running, with the whole body leaning into the curve from the feet.
- **No input locks:**
  - release during a start: back to idle;
  - push during a stop: back into the walk on the foot that is down;
  - tap: a twitch, then idle.
- **Head** turns toward the stick at once and leads the body.
- **Feet:** knees over the toes, ankle limited to 20° up, soft reach, and never through the floor.
- **World contract:** layers and masks as agreed (capsule on layer 2, probes 1|4|8). The course has the bin (layer 3),
  the window and the two doors (layer 4).

## The numbers (tests/loco_test.gd, 60 fps, 14 scenarios)
| scenario | foot slide | hips pop | joints out | latency | to full speed | to stop |
|---|---|---|---|---|---|---|
| walk start ahead, 3 s, stop | 3.0 cm | 1.7 cm | 0 | 33 ms | 1.58 s | 1.92 s |
| walk start 90° left | 4.5 | 0.9 | 0 | 17 | 1.55 | 1.63 |
| walk start 180° | 6.1 | 1.8 | 0 | 17 | 0.85 | 1.63 |
| run start, 3 s, stop | 4.0 | 1.8 | 8 | 67 | 0.90 | 0.45 |
| run start 90° right | 4.6 | 3.5 | 8 | 17 | 1.45 | 0.67 |
| Shift run 4.6 m/s | 3.9 | 1.8 | 8 | 67 | 0.98 | 0.45 |
| slow walk (half stick) | 3.0 | 0.7 | 0 | 33 | 1.42 | 1.68 |
| walk → run → walk | 3.0 | 1.4 | 8 | 33 | 1.58 | 1.78 |
| run, reverse 180° (pivot) | **14.9** | **5.6** | 12 | 67 | 0.90 | 0.48 |
| walk, reverse 180° | **11.6** | 1.7 | 0 | 33 | 1.58 | 1.63 |
| run, 90° turn | 4.0 | 3.5 | 11 | 67 | 0.90 | 0.67 |
| run in a circle | 7.3 | 1.8 | 0 | 67 | 0.90 | 0.45 |
| tap and release | 2.0 | 0.6 | 0 | 33 | - | 0.03 |
| stop, then go again | 3.0 | 1.4 | 0 | 33 | 1.58 | 1.77 |

How to read them:
- **Foot slide** is the most a planted foot's contact point (the heel, or the ball once the heel lifts) moves in one
  contact. The study wants under 1 cm. It is 3-5 cm in walks, runs and stops, and 12-15 cm in pivots.
- **Hips pop** is the change in the hips' per-frame motion. The study wants under 2 cm. It is 0.7-1.8 cm, except
  3.5-5.6 cm when a run turns hard or pivots.
- **Joints out** are frames past the study's ranges. All of them are "knee over 140°" in the run's swing, and they are in
  the Mixamo run itself. Backward knees: 0.
- **Latency** is the first visible answer to the stick (the hips move, the head turns, or the body moves).

The numbers have improved a lot since the first build (slides were 17-45 cm and every run had backward knees), but
they are not at the study's limits yet.

## What doesn't work yet (honest)
1. **Pivots slide** 12-15 cm and pop 5.6 cm. The 180 clips are spin turns on one foot. My foot lock holds the foot's
   position but doesn't yet turn the foot in place around the ball.
2. **Walk stops take about 1.6 s** (the study says 1-2 steps). The only walk-stop clip makes a slow second step.
   It is on the wanted list.
3. **Feet lifted early:** 2-8 times per scenario, a foot the clip marks as planted is out of reach. It is lifted
   (5 cm, 0.25 s) rather than dragged, but with no weight shift. This shows most in stops and pivots.
4. **Run stops end turned** 37° (that is in the clip).
5. **No real crouch, jump, traversal or cover yet** (steps 5-7). Stairs, kerbs and slopes are not handled: the capsule
   just stops at a kerb.
6. **The real city-kit street** stretch is not in the course yet. I'll copy it in at step 5, with kerbs. The survey
   (`OBSTACLES.md`) names the five pieces.
7. **Forearm twist:** the body has no twist bones, so half the hand's twist rolls the forearm bone. I can't judge from
   here whether that looks right on the mesh.

## What a check cannot see
- **Feel.** Is 1.5 s to full walking speed too slow for you? Does the start's weight shift feel late, or the stop
  floaty? Only playing tells.
- **The mesh.** All checks are on bone positions. Skin folding (elbows, the forearm twist, knees at 140°) and the feet
  touching the floor visually are not measured.
- **The look of the warps.** A start spun 120° on one foot may look like skating even when the numbers are fine.
- **The camera's ease**, and the touch controls. Touch was not tried on a phone at all (the phone comes last).
- **Windows** (see above).

## Files
- `STUDY.md`, `LAB_BRIEF.md`, `WORLD_CONTRACT.md`: the rules.
- `DECISIONS.md`: every decision with its study section, and the conflicts.
- `OBSTACLES.md`: the city survey.
- `CLIPS_WANTED.md`: the clips to make.
- `native/src`: the C++ stack, built to `native/bin` (Linux `.so`, Windows `.dll`).
- `tools/`: clip build (retarget, measure), course builder, script check.
- `scenes/`: boot (first-run download and build), main, course.
- `tests/loco_test.gd`: the numbers above.
- `tests/shots.gd`: screenshots.

Rebuild the native library (Linux or cross to Windows): see `native/SConstruct`. godot-cpp `master` (19 Nov 2026),
built against Godot 4.7.2's `extension_api.json`.

## Note
A session working on the game's damage system sent me the world contract (`WORLD_CONTRACT.md`). I adopted it
(DECISIONS 6.x). I could not send it a reply from this cloud session.
