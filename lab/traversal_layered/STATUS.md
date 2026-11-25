# Lab B (layered, GTA-style): status

## 25 Nov, evening: Yasin judged the step 4 build terrible. Checked against study v2. Work stopped.

Yasin saw a knee bent backward, an ankle rolled onto its side and a ~70° lean while running. My report said "backward
knees 0, joints out 0". Both were true of my checks and false of the picture: my checks could not fail. `STUDY.md` is now
version 2 (commit 542668d28 on `claude/festive-faraday-20ltx2`). Below, every problem I found by reading my own code
against it, the v2 section it breaks, and how I would fix it. **Nothing is fixed yet: waiting for Yasin's word.**

### What caused what Yasin saw
| # | Problem in my build | Breaks (v2) | Fix I'd make |
|---|---|---|---|
| 1 | **Run turn rate 3.2 rad/s** (183°/s) at 4.6 m/s: a 1.44 m radius, needs a 56° lean. My code comment said "~3 m, 35°": wrong arithmetic. Walking turns at 6 rad/s (344°/s), far more than a step turn. | 3.3 (`TURN_RATE`), 0.1 rule 7, 8 #11 | Controller turn rate from the 20° lean column: ω = g·tan20°/v (0.77 rad/s at 4.6, 1.2 at 3.0), 30° only for 1-2 steps of a cut. Sharper changes become cuts on a foot plant (≤ 20-25° per plant at 4.6 m/s), 45-90° slows first, 135-180° brakes under 1.5 m/s then pivots. Walking: 30-60° per step, by step turns. |
| 2 | **Lean stacks from four sources**: the clip's own lean, my side lean (up to 34°), my forward lean (up to 20°) and the turn itself; nothing measured the drawn body. The side lean came from the impossible turn rate of #1, so it sat at its cap. | 3.2 (`LEAN_MAX`, `TRUNK_LEAN`, `TRUNK_BEND`), 10.1 step 4 (one source), 10.2, 8 #11-13 | One lean source: measure the clip's own lean at its speed and add only the difference needed for the CoM acceleration (atan(a/g)); a final limiter on the trunk lean; the validator measures CoP→CoM and pelvis→neck on the final pose. |
| 3 | **My lean tilts the hips about a point under them, then IK puts the feet back where the unleaned clip had them**: the legs absorb the tilt by bending sideways and twisting. With #1 this is where the backward knee and the rolled ankle come from. | 3.2, 10.1 (order), 8 #13 | Lean the whole body about the support point (the CoP), feet included, before foot IK; never tilt only the pelvis. |
| 4 | **Knee pole from the foot's yaw** (clamped ±40° of the body's forward), placed in front of the *clip's* knee in skeleton space, not the pelvis frame. It ignores the hip rotation the clip asked for, and it doesn't follow a tilted pelvis. | 10.3, 1.2 ("never derive the hinge from the foot"), 8 #1 | Pole from the pelvis forward, turned by the clip's own hip rotation (±15°), the foot allowed ≤ 15° more and only in contact; hysteresis near the hip→ankle line. |
| 5 | **Ankle limited on one axis only** (dorsiflexion, and with v1's wrong 20°). Roll (inversion / eversion) and twist were never limited or measured. The foot keeps the clip's orientation in skeleton space while the shin is leaned sideways, so the ankle rolls by the lean angle (34°+). | 1.4, 2.1 (`ANKLE_INVERSION/EVERSION`, `FOOT_TWIST`, `SOLE_ROLL`), 2.2 (knee-coupled 25-40°), 8 #4 | Foot against the shin limited on all three axes with v2's numbers; sole against the ground from heel and ball rays; heel lifts about the ball when the limit is reached. |
| 6 | **Soft IK starts at 97 % of reach** (a 28° knee already) | 10.3 (leave alone to 99 %, ease to 99.9 %) | Change the curve; pelvis drop or foot lift beyond. |

### Other places my build breaks v2
| # | Problem | Breaks (v2) | Fix I'd make |
|---|---|---|---|
| 7 | **Feet spin flat**: when the capsule turns (loop turns, the 7 rad/s start warp, pivots) a locked foot keeps its position but turns with the body. | 4.6 (`FOOT_SPIN` 5°), 8 #10 | Lock the foot's yaw too; turn by steps, pivot only on the ball with the heel up. |
| 8 | **Run reversal pivots straight from 4.2 m/s**, no braking first. | 3.3, 4.6 (brake under 1.5 m/s, plant, pivot), 8 #28 | Brake over 1-2 steps (lean back), then the pivot clip. |
| 9 | **Forced foot release** (lifts a "planted" foot that is out of reach, no weight shift). | 6.12, 4.5, 8 #8 | Keep the leg reachable (controller and stride warping), not lift. |
| 10 | **Slides 3-15 cm** (limit 1 cm, target 0.5), measured on bone origins, not on sole points. | 1.7, 7, 6.12 (`FOOT_SLIDE`) | Sole points; fix the speed and phase matching first. |
| 11 | **No final limiter**, no validator in the modifier stack. | 9.1, 10.2 | A validator modifier last, a limiter before it, both from one measuring function. |
| 12 | Head levelled only by half, roll not measured; head turn up to 69° with the chest still. | 2.4 (`HEAD_LEVEL`), 2.2 (eyes / chest) | Measure; head roll ≤ half the trunk lean. |
| 13 | Spine, hip, shoulder, elbow, wrist and fingers never measured. | 2.1 | The validator measures every row of 2.1. |


### Found later the same evening (Yasin's screenshots of the Kimodo climb and mantle)
| # | Problem | Breaks (v2) | Fix I'd make |
|---|---|---|---|
| 14 | **The retargeter puts a backward knee into every clip.** player_v3's mesh leg is straight at rest, but its knee bone sits ~10 cm in front of the leg's line (bones at 29° left, 16° right). Decision 1.2 swings the thigh and shin bones to point like the source's, so a straight source leg makes the **mesh** knee ~29° backward while the bones look fine. Measured on the body (`tests/clip_audit.gd`): the straightest knee reads 29° in every clip. Very likely also the backward knee in the step 4 build. | 1.2 (rest-relative, hinge from geometry), 1.3, 2.1 `KNEE_FLEX_MIN`, 8 #1 | Legs keep the body's rest in the retarget reference pose (no swing): a straight source leg gives a straight mesh leg. Knees measured relative to the body's rest; a straight leg must read ~0°. |
| 15 | **Retargeted traversal clips don't touch the wall.** The retarget scales the motion by the leg ratio (0.89), so the climb's hands land 1.65 m high and 1.09 m ahead instead of on the 1.5 m edge 1.32 m ahead; the body passed 34-56 cm through the wall I drew. My wall check used joint points with a 3 cm margin, not the body's volume. | 10.7 (warp to the real edge), 2.4 / 6.12 (capsules, `WORLD_INTERSECT`) | Fit traversal clips to the edge after retargeting (motion warping in windows, ±20 %); check body capsules against the world on the drawn body. |
| 16 | **My Kimodo scores were measured on Kimodo's skeleton, not on the body**, and I judged small strips by eye. | 0.1 rule 1 (measure the final pose) | Score clips only after retargeting, on the body, with `tests/clip_audit.gd` (to be grown into the v2 validator). |

The Kimodo verdict (KIMODO_TEST.md, round 3) is therefore open again until #14 and #15 are fixed.

**Correction to #14 (same evening):** the first audit tool that "measured 29° on every clip" never applied the pose (it ran
before the engine updated the skeleton) and measured the rest pose. Rewritten with its own forward kinematics and a
mutation test (v2 9.2: rest reads 0, +30 reads +30, -20 reads -20, both sides). Measured properly, the **old retargeter
bent the mesh knee 16-19° backward in 25-30 frames** of the climb and mantle: the cause was real.

### Fixed (25 Nov evening, Yasin's "go")
| # | Fix | Result (measured on the body, `tests/clip_audit.gd`, mutation-tested) |
|---|---|---|
| 14 | Retargeter swings each limb **whole** (hip→ankle, shoulder→wrist, hand and fingers with the arm), keeping the body's own rest joint angles; leg ratio from the straight leg (hip→ankle). DECISIONS 1.2. | Backward knees: climb 0, Kimodo walk 0, Mixamo walk 0, Mixamo run 0, Kimodo run 1 frame at -5° (the limit). Old retargeter: 25-30 frames at -16 to -19°. |
| 14b | Runtime leg IK: reach capped at the mesh's straight leg (rest hip→ankle), soft reach 99 % → 99.9 % (v2 10.3). | loco_test (now with the signed, rest-relative knee): 0 backward-knee frames in all 14 scenarios. |

### Fixed later the same evening (Yasin: "still leaning almost 70 degrees when running")
| # | Fix | Result (loco_test, trunk lean measured on the drawn body, pelvis centre -> neck, v2 1.6) |
|---|---|---|
| 1 | Turn rate from the 20° lean column: w = g tan20 / v (49°/s at 4.2 m/s), walking 2.5 rad/s; a big turn at a run brakes to ~1.6 m/s first; no new pivot within 1 s of the last (v2 3.3) | camera spinning 90 and 180°/s while running: no pivot spam (8 switches, was 198) |
| 2 | One lean source: the clip's own trunk lean is measured, only the acceleration's difference is added, and the total is held inside the trunk limits every frame (v2 3.2, 10.1 step 4) | was: sideways 36°, forward 46° (together ~60°). Now: sideways max 24°, forward max 30° in all 16 scenarios |

**This is still not a study-v2 build.** Not checked yet and probably wrong: ankle roll / twist and the sole (1.4, 2.1),
feet spinning flat (4.6), CoM accelerations (3.6), head level (2.4), spine shares and arms, foot slide at the sole
points (1.7), stop steps (3.4), the fuzzer (9.3). Recommendation: no more patches; the rebuild in v2's order with the
checker first.

### Still open after this fix
| # | Problem | Notes |
|---|---|---|
| 17 | **Waist pinches thin when the hips fold hard** (the jump of the climb; Yasin's "mid-section lost" is probably this too). Seen in both the old and new retargeter. | It's the mesh's skin weights at the waist (Meshy auto-rig), which bone checks can't see. Options: the v2 hip-flexion limit (125° with the knee bent) in the limiter; or better weights on the body in Blender (Yasin's asset). Not decided. |
| 18 | The retarget change shifted the clips' measured speeds and exposed the old step 4 controller: the run reversal now flips pivot / loop 20 times; hips accelerations up to 8 cm/frame second difference. | That controller is what v2 says to rebuild (#1, #8); not patched. |
| 19 | The mantle's second key pose (knee up, foot behind) folds the leg completely flat on one frame (my key pose, not the retargeter). | Fixed: the key-pose builder now refuses poses past the hip-rotation / hip-flexion limits or inside the wall. |
| 20 | **First audit tool never applied the pose** (it measured the rest pose; the "29° on every clip" was the rest angle). | Fixed: own forward kinematics + mutation test. |
| 21 | **Knees measured against the thigh's own hinge miss a twisted thigh** (Yasin's second screenshot: knees pointing back with a "normal" bend). | Fixed in the audit: hip rotation (v2 1.5) and the knee seen from the pelvis are measured too. |
| 22 | Retargeted climbs / mantles put the thighs 11-30 cm into the wall even when the source is clear (legs scaled 0.84, arms not). | Needs the traversal layer (v2 10.7, 6.12) on the body; step 6. |


### Why my checks passed a broken pose
- The knee was the **unsigned** angle between thigh and shin, plus a "knee behind the hip-ankle line along the body's
  facing" test with my own thresholds (flex > 8°, 2 cm). Nothing measured hip rotation, varus or twist, so a thigh
  twisted round, or a leg tilted by the lean, read as normal (v2 1.3, 1.5).
- No ankle roll, twist or sole check at all (1.4).
- "Hips pop" allowed 2 cm/frame (72 m/s²); v2 3.6 allows ~9 m/s² horizontal.
- No lean, CoM or trunk measurement (1.6, 3.2).
- Not one check was ever fed a broken pose (9.2 mutation tests), and only 14 scripted moves ran (9.3 fuzzer).
- The camera in my screenshots was static and side-on, and I looked at straight runs, not hard turns. The worst case
  (turning at a run) was never rendered.

### How I'd rebuild, in v2's order (9.6, 10.1), if Yasin says go
1. The validator first (9.1), with the mutation tests of 9.2, all of them made to fail on purpose.
2. Then the controller (#1, #8), then one lean source (#2, #3), then the knee pole and the ankle (#4, #5, #6), then the
   foot yaw (#7), then the limiter (#11).
3. The fuzzer (9.3), and contact sheets beside reference footage (9.4), before Yasin plays it again.

---

## Earlier: status after step 4 (superseded by the v2 check above)

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
