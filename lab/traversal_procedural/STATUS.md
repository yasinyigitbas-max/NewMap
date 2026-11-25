# Lab A (procedural): status after step 5

25 Nov 2026. Branch `lab/procedural`, folder `lab/traversal_procedural/`. Step 4's report is below this one.

## Step 5: kerbs, steps, stairs, slopes

**How to try it**: open the project in Godot 4.7.2 and press Play (see "How to play it" below). On the course:
kerbs and steps are the lane to the right of the start (x 8), stairs next to it (x 14), ramps after that (x 20), the
side-slope at x 26. The **real street** (city-kit piece `s_apt` with 15 cm kerbs, the porch house, a bench) is at
x -60: walk left from the start for ~60 m.

### What works
- **Kerbs and single steps** are walked over inside the stride. He looks at the kerb, places his steps so no foot
  lands on the edge, lifts the swing foot 3-5 cm over it, lands flat on top. Stepping down, the foot reaches out past
  the edge and then lowers, toes first. From 20 cm he slows ("an obvious bigger step").
- **Stairs**: one tread per step walking, two running. Going up, the ball of the foot sits on the tread and the heel
  hangs over the step below; the knee lifts high over each nosing; the trunk leans forward. Going down, toes first, the
  heel lowers, eyes down. The hips glide on the stair pitch. He slows down before the first step, so the first step
  lands on the first tread.
- **Slopes**: up to 5° nothing changes. Steeper, the steps get shorter and quicker and he slows down. Uphill the trunk
  leans into the slope, the feet land flatter and the heels lift on steep ground. Downhill the heel lands first. On the
  side-slope each foot follows the ground and the lower leg bends more.
- **The real city kerb** (15 cm, city-kit street): up, down, at a 40° angle and running across all work.

### The numbers (`tests/test_terrain.gd`, output in `tests/last_terrain.txt`)
32 course items: **31 done, 1 refused, 0 failed.**

| Item | Slide | Hips pop per frame | Joints past range |
|---|---|---|---|
| kerbs 10-16 cm walking | 0.83 cm | 3.0-3.3 cm | 0 |
| kerbs 10-16 cm running | 0.77 cm | 1.9-2.3 cm | 0-8 |
| steps 20 / 24 cm walking | 0.8 cm | 6.4 / 7.8 cm | 0 / 2 |
| steps 20 / 24 cm running | 2.6 cm | 3.3 / 3.9 cm | 4 / 10 |
| stairs 17/28 up and down, walking | 0.82 cm | 3.6 cm | 0 |
| stairs 17/28 up and down, running | 2.6 cm | 6.7 cm | 8 |
| steep stairs 19/25, walking | 0.80 cm | 7.3 cm | 7 |
| stoop 3 x 16.7 cm onto a porch | 0.83 cm | 3.5 cm | 1 |
| ramps 5° / 10° / 15° up and down | 0.5-0.8 cm | 2.1-5.3 cm | 0 |
| ramp 25° up / down | 3.0 / 2.2 cm | 5.6 / 9.8 cm | 0 / 24 |
| ramp 15° up, running | 2.3 cm | 4.8 cm | 7 |
| side-slope 10° | 0.83 cm | 1.5 cm | 0 |
| real kerb (city kit): up, down, at 40°, running | 0.7-0.8 cm | 2.3-3.5 cm | 0-3 |
| **real porch: refused** | | | |

Flat ground after these changes (`tests/last_run.txt`): every case slides under 1 cm (worst 0.83). Walking pop is
1.3 cm a frame (under the study's 2 cm), running up to 3.5 cm. Joints past range: 14 frames in all.

### What does not work yet
- **The real porch is refused.** Its collision is a 0.20 m block, then the deck 0.30 m above it. The picture shows three
  16.7 cm steps. A 0.30 m step is a "big step up" (study 3.1), which comes with step 6. This is the survey's warning
  about the city: **collision stairs are coarse** (porches, docks 0.55 m, courthouse 0.62 m, dingbat stairs 0.72 m
  blocks). Feet that probe the world will treat them as climbs, not stairs. The fix belongs to the map (a collision
  box per step). I did not touch the map. See `DECISIONS.md` section 7.
- **Hips pop over 2 cm a frame** on the 20-24 cm steps (6-8 cm), the steep 19/25 stairs (7 cm), the 25° descent
  (10 cm) and running on stairs (7 cm). Normal stairs, kerbs and ramps are at 2-5 cm. This is still above the study's
  line.
- **Joints past range** on the 25° descent (24 frames: the knee bends past 140° and the ankle points down past 50°).
  The study (2.6) says people over ~30° turn sideways or use their hands; at 25° he still walks straight down.
- **Slide over 1 cm** on the 25° ramp (3 cm), and when running over the 20-24 cm steps and on stairs (2.6 cm).
- **Stairs feel slow**: one tread per step at the study's cadence is 0.44 m/s along the stair. That follows the study;
  GTA V barely slows on stairs. It's your choice if he should take stairs faster.
- **Drops deeper than the 24 cm step** (ledges, the deck lane) are step 6.

### What a check cannot see
- The **look**: I checked side views of a kerb, going up stairs and coming down. They look right to me: knee lift,
  feet on treads, eyes down on the way down. I have not looked at every item. Please walk the course and the real
  street yourself.
- Skin against the step: a shoe may graze a nosing by a few mm (the clearance is checked at the heel, ball and toe
  tip, not on the whole shoe).
- Stairs that turn, or that are approached at an angle, are not on the course.

---

# Step 4 report (25 Nov)

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
