# Lab A (procedural): status after step 4

25 Nov 2026. Branch `lab/procedural`, folder `lab/traversal_procedural/`.

## How to play it (Windows)
1. Get the branch (`git fetch origin lab/procedural && git checkout lab/procedural`).
2. Open `lab/traversal_procedural/project.godot` in **Godot 4.7.2** (the first open imports the body, ~1 min).
3. Press **Play** (F5). Click the window once to capture the mouse; Esc frees it.
- W A S D walk, Shift + direction runs, mouse looks. A gamepad: left stick walks to runs by how far you push
  (a light push walks, a full push runs), right stick looks.
- Touch (phone, later): left half of the screen is a floating stick, right half looks.
- C, Space, double taps: read, but nothing uses them yet (crouch and jump come in steps 5-7).

The native library is committed for Windows (`bin/liblabproc.windows.template_debug.x86_64.dll`) and Linux, so no
build is needed. To rebuild: `native/BUILD.md`.

## What works (step 4)
- **Standing**: feet 20 cm apart, toes out 7°, weight moves from foot to foot every ~6 s, breathing.
- **Walking**: a planned footstep for every step. Heel strike, foot flat, the heel lifts, the foot rolls over the ball
  and then over the toe tips. The pelvis rides an inverted pendulum, turns and drops a little each step, and shifts
  over the standing foot. The chest counter-turns. Arms swing opposite to the legs.
- **Running**: a flight phase every step, the pelvis lowest at midstance, the foot lands under the knee, the heel
  kicks up behind, elbows ~90°, trunk forward.
- **Starts**: the weight moves onto one leg first, then the other leg steps; the first step is short.
- **Stops**: on whichever foot is next; the second foot comes alongside.
- **Turns**: small turns happen inside the steps. A 180° turn at a run brakes, pivots and pushes off the other way.
  The head turns to the new direction first, then the body follows.
- **Lean**: the whole body leans from the feet into turns, forward when speeding up and back when braking.
- **Controls and camera**: as in the brief. The camera sits behind the right shoulder at 3.4 m, eases, and is pulled in
  by walls.
- **World contract**: collision layers and masks as agreed with the damage system. The course has the bin (layer 3),
  debris (layer 7), a window and a door (layer 4). The feet ignore debris.
- **Course**: every item on the brief's list, plus what the survey found (the 1.26 m and 1.84 m fences, the 16.7 cm
  stoop). Kerbs, stairs and the rest are built but **not yet handled**: that is step 5.

## The numbers (`tests/test_locomotion.gd`, full output in `tests/last_run.txt`)
| Case | Planted-foot slide | Hips pop (per frame) | Joints past range | Other |
|---|---|---|---|---|
| idle 3 s | 0.00 cm | 0.03 cm | 0 | |
| walk start + 4 s | 1.24 cm | 2.45 cm | 0 | full speed 1.03 s; bob 6.0 cm; 120 steps/min, 0.70 m steps; never both feet off |
| walk stop | 0.08 cm | 2.72 cm | 0 | body stopped 0.38 s; feet set 0.78 s; 2 steps |
| run start + 5 s | 2.52 cm | 5.33 cm | 11 (hip) | full speed 1.10 s, 3 steps; bob 10.6 cm; 180 steps/min, 1.53 m steps; never both feet down |
| run stop | 1.01 cm | 3.33 cm | 0 | stopped 0.97 s; feet set 1.18 s; 3 steps |
| walk turn 90° | 3.62 cm | 3.46 cm | 8 (ankle) | facing the new way in 0.20 s |
| run turn 180° | 1.98 cm | 3.58 cm | 4 (hip) | turned 1.13 s; full speed back 2.02 s |
| run in a circle 6 s | 3.62 cm | 3.36 cm | 2 | |
| analog walk (stick 0.1-0.7) | 2.13 cm | 2.47 cm | 0 | |
| stop-go x6 | 1.31 cm | 2.38 cm | 0 | |

Stick-to-response latency: 17 ms in most cases (the head turns, or the lean starts, one frame after the stick moves),
83 ms when starting a walk from a stand. One outlier: the analog sweep reports 567 ms. I have not checked why yet;
the sweep changes the stick slowly, so it may be the measurement, not the body.

Since the start of step 4 (first working run of the same tests): worst slide 24 → 3.6 cm, worst hips pop 55 → 5.3 cm
a frame, joint frames past range 556 → 25.

## What does not work yet, honestly
- **Slide over 1 cm** (the study's 4.6 limit) in turns and in running, up to 3.6 cm. It is mostly on the heel when a
  turning foot lands.
- **Hips pop over 2 cm a frame** (4.6 item 5): 2.4-2.7 cm walking, up to 5.3 cm running. Most comes from the pelvis
  settling for a landing foot. It will not show as a jump, but it is above the study's line.
- **Walk bob 6 cm** (study 4-5) and **run bob 10.6 cm** (study 6-10). Both are written as conflicts in
  `DECISIONS.md`.
- The **hip goes past 30° extension** for a few frames in running and in the 180° turn. The **ankle goes past 50°
  down** at toe-off in the 90° walk turn.
- **The stance knee in a walk** stays at ~15-20° at midstance (the study says ~5°). That was a choice to keep the bob
  down.
- **The body is ahead of its capsule** when leaning: up to ~0.25 m at a hard start. Near walls the arms or head may
  poke into them.
- **Rig quirks**: the two feet have their bones in different places, so the right foot's toes can move ~1-2 cm at full
  heel lift. Fixed by measuring each foot from the mesh (`DECISIONS.md` 5.1), not by editing the body.
- **No real city-kit stretch on the course yet.** The survey chose the pieces (`OBSTACLES.md` section 16); copying them
  with their meshes is step 5's first job.
- **Not built yet**: kerbs, steps, stairs, slopes (step 5); vaults, climbs, drops (6); crouch, cover, narrow ground,
  doors (7). The ground probe already follows the floor height, but nothing plans steps onto kerbs.

## What a check cannot see
- **Feel.** The tests feed the stick directly. I checked once that real keys go through the input map and the game
  camera (W, then Shift, then a turn, then release: frames looked right), but I cannot play it. Please judge the
  response and the weight yourself.
- The tests measure the targets and the drawn bones, but **skin**: the knee or elbow mesh folding, the shoes going
  into the floor by a few mm, or the cloth stretching shows only on screen.
- **The look of the gait.** I looked at side, front and follow-camera renders of the walk, the run and standing.
  Faults I found that way and fixed: arms hanging behind the body, arms swinging inward. Others may remain: watch the
  hands (palm direction) and the trunk in running.
- **Frame rate.** Tested at 60 fps fixed. Physics interpolation is on but not tested at 144 Hz or at a low frame rate.
- **Windows.** The DLL is cross-compiled. It links only to Windows system DLLs, but I could not open it on Windows
  here.

## Next (after your word)
Step 5: kerbs, single steps, stairs and slopes, planned by the same footstep planner (no special modes), plus the
real city-kit stretch on the course.
