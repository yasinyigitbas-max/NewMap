# Traversal lab: two experiments, one brief

Written 25 Nov 2026 for two cloud sessions working at the same time. Yasin will **play both results himself** and
choose. Everything here applies to both, unless it says A or B.

- **A, procedural**: the body's motion is generated at runtime from the world (footsteps, centre of mass, IK), not
  played from clips.
- **B, layered**: a GTA-style stack. A clip-driven locomotion core, then warping, contact IK, procedural layers and a
  physics reaction layer on top.

## The goal, in Yasin's words
"An advanced locomotion and traversal system ... i'm having difficulties making the animations play right."
"**I want a system that's both realistic and responsive.**"

- **Realistic** means the study: `docs/locomotion/HUMAN_MOVEMENT_STUDY.md`, parts 1-4 above all.
- **Responsive** means GTA V-like control, not RDR2's slowness (study 8.3-8.5):
  - the body visibly answers a stick change within **~0.1 s**: a lean, a step adjusting, the head turning
  - starts reach speed in 2-3 steps; a walk stops in 1-2 steps; never waits a whole stride for no reason
  - turns and pivots happen in the step they are asked for
  - vaults, climbs, steps and drops start by themselves and can be **aborted until the hands or feet commit**
  - there is no input lock longer than the real movement needs
- When the two pull apart, realism of the **contacts** (feet, hands) and **timing** wins; style flourishes give way to
  responsiveness.

## The study is the law (read this twice)
1. Before writing anything, read `docs/locomotion/HUMAN_MOVEMENT_STUDY.md` from start to end. It is on branch
   `claude/festive-faraday-20ltx2`:
   `git fetch origin claude/festive-faraday-20ltx2 && git show origin/claude/festive-faraday-20ltx2:docs/locomotion/HUMAN_MOVEMENT_STUDY.md > lab/<your folder>/STUDY.md`
   Keep that copy in your lab folder and treat it as the spec.
2. Every design decision goes into `lab/<your folder>/DECISIONS.md` with **the study section(s) it follows**, e.g.
   "knee pole = foot's forward (1.2 rule 3)". A decision with no study section is a decision to question.
3. Before every commit, run the study's **4.6 checklist** on what you changed, plus the Part 1-3 numbers it touches
   (joint limits, gait timing, heights). Write the result in the commit message.
4. After any context compression: re-read `STUDY.md`, `DECISIONS.md` and this brief before touching code.
5. If your approach and the study disagree, the study wins. Note the conflict in `DECISIONS.md`.

### Mistakes the previous attempts made (found by comparing them to the study; do not repeat)
- The knee aimed the way the body faces instead of over the toes, so knees caved in or twisted on turned feet. (1.2/3)
- No ankle limit: the sole forced onto slopes past ~20° instead of the heel lifting. (1.2/4)
- Legs snapped straight at the end of reach: no soft IK. (4.x)
- No forearm twist, so the wrist twisted like a sweet wrapper. (1.2/1)
- The head never led a turn, an edge or a drop. (2.5, 4.5)
- The turning lean bent only the upper spine (a sideways "C"), not the whole body from the feet. (2.5)
- Playback rate stretched 0.55-1.5x instead of changing stride length. (4.1)
- On stairs the hips chased the ground under the body on a lagging spring, bobbing each step, instead of gliding on
  the stair pitch. (2.7)
- Slopes didn't change posture, step length or pace. (2.6)
- Re-plant steps moved a foot with no weight shift. (2.3)
- One vault clip for every fence, ending in a fight stance. A "running jump climb" used even from a standstill. A hang
  clip squeezed onto chest-high walls. (3.1, 3.2)
- No step adjustment before take-off; obstacles probed at only two heights. (3.2, 4.4)
- The same soft landing for a 0.5 m hop and a 2.9 m drop. (3.3)
- PC and phone on different physics engines. (7.1)
- Two systems both moving the body. Every fix was a patch on a patch.

## Isolation (Yasin: "I do not want either of them to use the existing traversal system at all")
You start from `main`: a full copy of the game, so you can learn the real obstacles. You must **not** be influenced
by the game's existing movement, animation or traversal work.

### Never open, run, copy or imitate
- `native/src/city_player*`, `city_ped*`, `ped_body*`, `hand_grip*`, `foot_*`, `mo_*`, `anim_retarget*`, `rig_names*`,
  `city_car_door*`, and the rider parts of `city_bike*`
- `tests/people/`, `tools/people/`, `docs/ANIMATION_PLAN.md`, `docs/OLD_CONTROLS_SPEC.md` (the controls are restated
  below), and any `.claude/skills/*animation*` or `*traffic-people*` skill
- these branches: `festive-faraday-work`, `claude/animator`, `claude/cool-galileo-*`, `claude/anim-checkpoint-*`,
  `claude/perf-bugs`, and anything else about the player
- the clip libraries the old systems built: `characters/rocketbox/*.res`, `characters/hero_v3/*.res`, and anything
  under `characters/*` except `characters/quaternius_ual`

### Allowed, read-only, to learn the obstacles
- `map_dc/coronado/city_kit/` (the hand-made pieces `.scn`, layouts, plans), `assets/coronado_kit/` (meshes, `SPEC.md`,
  `README.md`), `map_dc/coronado/terrain/`, `assets/roads/`.

Measure what is really there: kerb heights, steps and stairs (riser and tread), ramps and slopes, low and high walls,
fences and railings, benches, planters, bins, cars and vans, ledges and drops, narrow wall tops, doors and doorways,
cover-height walls, gaps. Write it to `lab/<your folder>/OBSTACLES.md` (heights, widths, depths, how often, which
pieces). Both experiments do this survey; do it yourself, don't share.

### Where your work lives
- Only under `lab/traversal_procedural/` (A) or `lab/traversal_layered/` (B). Never edit anything outside your folder.
- Your folder is **its own Godot project** (its own `project.godot`), so the game project never loads it and you never
  load the game's systems. Copy in what you need (a few real kit pieces and their meshes for a "real street" test,
  the body); don't reference game paths.
- Your branch only: `lab/procedural` or `lab/layered`. Never push to `main` or any other branch; no PR unless Yasin
  asks. Commit and push after every step (house rule).
- The repo's `CLAUDE.md` describes the city-kit map work. Its house rules (commit and push, honest reports, say what a
  check cannot see) apply; its tasks do not. Don't do map work.

## Same conditions for both (so the comparison is fair)
- **Godot 4.7.2** (Yasin's version; Linux build from the official GitHub releases for headless tests).
- **Jolt physics everywhere**: PC, tests and phone (study 7.1). Physics interpolation on (study 6.5).
- **Runtime code in C++** (a GDExtension inside your folder, `lab/<folder>/native`); GDScript only for tools and tests
  (house rule). Build a Linux library for your tests and a **Windows DLL** (mingw-w64 cross-compile with godot-cpp) so
  Yasin can open your project in Godot 4.7.2 on Windows and press Play.
- **The body**: Yasin's player, `player_v3`. Take **only these asset files**, from branch
  `origin/claude/cool-galileo-6y68se`, with
  `git show origin/claude/cool-galileo-6y68se:<path> > <your copy>` and nothing else from that branch:
  - `assets/people/humanoid/player_v3.glb`
  - `assets/people/humanoid/player_v3_texture_0.png`, `player_v3_normal.png`, `player_v3_texture_0_metallic_roughness.png`
  - `assets/people/humanoid/bonemap_meshy.tres`, `bonemap_mixamo.tres` (`BoneMap` to Godot's `SkeletonProfileHumanoid`)

  Import trap: keep **Fix Silhouette OFF** for the body (it bakes his feet toes-up), and use the same rest-fixer
  settings for the body and every clip you retarget onto it.
- **Obstacle course** (one scene, same layout in both, built from your survey). At least these, from study Part 3:
  - kerbs 10, 12, 15, 16 cm; single steps 20 and 24 cm
  - stairs: riser 17 cm, tread 28 cm, 8 steps up to a landing and down again; a steep flight (riser 19, tread 25)
  - ramps 5°, 10°, 15°, 25°, and one walked across sideways
  - blocks 0.3, 0.5, 0.8, 1.0, 1.2, 1.5, 1.8, 2.2, 2.6, 3.2 m high and deep enough to stand on
  - thin fences and railings 0.9, 1.1, 1.3 m
  - a car (bonnet 0.85 m, roof 1.45 m), a van (roof 1.9 m), a bench (0.45 m), a planter (0.6 m)
  - ledges with drops of 0.3, 0.6, 1.0, 1.5, 2.2, 3.0, 4.0 m
  - wall tops 60, 30 and 20 cm wide; a 10 cm pipe
  - a 1.25 m low ceiling; cover walls 1.0 m and 2.0 m with outside corners
  - a push door and a pull door; a 0.6 m gap
  - plus a stretch of real city-kit pieces, and anything your survey found that this list misses
- **Controls** (Yasin's; no extra buttons):
  - PC: W A S D or the left stick (analogue: walk to run by how far it is pushed), Shift runs, C crouch toggle,
    Space jump, mouse or right stick for the camera.
  - Touch: the left half of the screen is a floating stick (full at 80 px); the right half looks; a **double tap on
    the left = crouch toggle**, on the right = jump.
  - Vault, climb, step, drop, mantle and narrow-ledge walking **start by themselves** from movement. **Cover starts by
    itself** when crouched and pushing into a wall.
- **Camera**: third person behind the shoulder, about 3.4 m, eased (never cut).
- **The tests print the same numbers**:
  - planted-foot slide (cm), hand-on-edge error (cm)
  - hips pop (cm per frame at 60 fps), joints past the study's ranges (count)
  - stick-to-response latency (ms), time to full speed and time to stop (s)
  - for each course item: done, refused, or failed

  Numbers can't judge feel; Yasin plays it. Never call anything good from test films alone. Judge through the game
  camera with real input.

## The clips you may use
- **Mixamo** (Yasin's Drive folder `1ApuKUaGgrlvYGPT_g_9ceyBitAokmAR_`, public link). `clip_manifest.tsv` here lists
  every file's Drive id. Fetch one with
  `curl -sL -o "<name>" "https://drive.usercontent.google.com/download?id=<id>&export=download&confirm=t"`.
  Three packs are zips in the same list: Male Locomotion, Action Adventure, Male Injured.
  **The repo is public: never commit Mixamo files.** Keep them git-ignored and fetched by a script (Mixamo's terms
  allow use in a game, not sharing the raw files).
- **Measured** (`clip_measurements.tsv`, made with `fbx_scan.py`):
  - one 65-bone `mixamorig:` skeleton for every file, 30 fps, centimetres, one body (hips about 1.0 m)
  - about 25 files are the same take saved twice (`L_Start_Walking` = `Start_Walking`: there is no left-foot start)
  - walks: one ordinary walk at 1.8 m/s (brisk), no 1.3 m/s walk
  - runs: a good spread from 2.6 to 6.2 m/s, with strafes, backwards, 90° and 180° turns
  - starts and stops: one walk start and one walk stop only
  - stairs are about 45° steep (city stairs are 30-37°); there is one walking-down take and no running down
  - ladders: a full set; crouch and cover: a full set; doors: push, pull and slide
  - climbs: about 7, all for walls of 1 m (running only) or 2.1-2.3 m, none from standing at knee, waist or chest
    height
  - vaults: two, both made for other jobs (`Jumping Over Into Combat`, `Vault Over Box to Cover`). There is no step
    vault, speed vault, bonnet slide, step-over or climb-over-a-fence.
- **Quaternius UAL1 and UAL2** (in `main`: `characters/quaternius_ual/*.glb`, CC0, 254 clips, its own skeleton):
  - ClimbUp_1m and 2m, StepUp, SafetyVault, GetOffWall_2m
  - wall climbing that moves up, down and sideways, and a ledge climb
  - 8-way walk, jog and crouch, jogs leaning left and right, Turn90 / Turn180, sprint in and out, slides, wall runs
  - stylised, so it reads differently next to mocap
- **Rokoko free mocap** (Drive file `1oxJBKbT7AeXexSMDU4j0rkGoibnEOxK1`, 769 MB, 582 FBX): combat, idles, acting,
  falls. **No traversal at all.** Ignore it unless you need idles.
- Missing clips: write the exact list (what, which height, which foot, which speed) in `lab/<folder>/CLIPS_WANTED.md`
  for Yasin. Don't stretch a clip past about ±20-30 % to fake one.

## A, procedural: the brief
- Motion is computed at runtime from the world. The pieces:
  - a **footstep planner** (where each foot lands, from speed, turn and the ground ahead)
  - a **centre-of-mass path**: an inverted pendulum for the walk, a spring-mass model for the run, a ballistic arc in
    the air
  - **swing arcs** with real toe clearance
  - **full-body IK** with the study's joint limits
  - spine, arms and head driven from the body's motion
  - traversal planned from **contact points found on the geometry**: hand and foot targets, then a body path through
    them
- Clips are **not played**. You may sample a few **static key poses** from the Mixamo library as style targets (the
  Overgrowth approach, study 8 and our discussion), but timing, weight and contacts must come from the model.
- Responsiveness is the approach's natural strength. Realism of the gait is its weak point: put your best work there
  (study 2.1-2.5).
- One solver for everything. No mode-specific hacks that move the body behind the solver's back.

## B, layered: the brief
- The GTA V-style stack, built fresh:
  1. a **clip-driven locomotion core**: a state graph with blend spaces, or motion matching if the data allows
  2. **inertialization** for every switch, no crossfades
  3. **stride and orientation warping**; loops joined on matching feet; foot-phase starts, stops and pivots
  4. **motion warping** of traversal clips onto the real edge, only inside marked windows, within ±20-30 %
  5. **contact IK** (feet, hands, fingers) from contact windows measured on each clip
  6. **procedural layers**: whole-body lean, head look-at, pelvis and stairs pitch, ankle limits, soft IK, forearm
     twist
  7. a **physics reaction layer** for bumps and landings
- Every clip is measured at import (contacts, speed, foot phase, edge height) and the data is kept with it.
- Where the library has no clip for a case, don't force a wrong one: list it in `CLIPS_WANTED.md`, and, until it
  exists, let the case be refused cleanly.

## Order of work (both)
1. Read the study. Write `DECISIONS.md` skeleton.
2. Survey the obstacles (`OBSTACLES.md`).
3. Set up the lab project: Godot 4.7.2, Jolt, the body imported cleanly (feet flat on the floor at rest), the course,
   the camera, the controls, the test harness.
4. Standing, walking, running, starts, stops, turns. Show Yasin a Windows-playable build before going further.
5. Kerbs, steps, stairs, slopes.
6. Vaults, mantles, climbs, drops, landings.
7. Crouch, cover, narrow surfaces, doors, low ceilings.
8. Polish against the 4.6 checklist; the phone comes last.

After each of steps 4-7: commit, push, and write in `lab/<folder>/STATUS.md` what works, what doesn't, what the
numbers are, and what a check cannot see. Then stop and tell Yasin it is ready to play.
