# Lab A (procedural): design decisions

Every decision names the study section it follows (`STUDY.md`, a copy of `docs/locomotion/HUMAN_MOVEMENT_STUDY.md`).
A decision with no section is marked **(no section: question it)**. Conflicts with the study are marked **CONFLICT**.

## 0. Project and shared conditions

| # | Decision | Follows |
|---|---|---|
| 0.1 | Own Godot project in `lab/traversal_procedural/` (own `project.godot`); nothing from the game is loaded. | brief, isolation |
| 0.2 | Godot 4.7.2, Jolt for 3D physics on every platform, 60 physics ticks, physics interpolation on. | 7.1, 6.5 |
| 0.3 | Runtime in C++ (GDExtension `native/`, godot-cpp), Linux `.so` for tests, Windows `.dll` by mingw-w64. GDScript only for tools and tests. | brief |
| 0.4 | Body: `player_v3.glb` imported with `bonemap_meshy.tres`, bones renamed to `SkeletonProfileHumanoid`, rest fixer: apply node transforms (the 0.01 armature scale goes into the skeleton, so it is in metres), overwrite axis on, **Fix Silhouette off**. | brief, 6.3 |
| 0.5 | No clip is ever played. All poses are computed from the rest pose each tick ("rest-relative": every bone's world rotation = a delta rotation x its rest rotation), so the code never depends on the bone axes. | brief A, 5.4 |

## 1. The body model

| # | Decision | Follows |
|---|---|---|
| 1.1 | Body numbers are measured from the rest pose at start-up (hip joints, knee, ankle, ball of the foot, shoulder, elbow, wrist), not typed in. player_v3: 1.83 m tall, hip joints at 0.91 m, thigh 0.37 m, shin 0.37-0.39 m, ankle 0.16-0.17 m above the sole. | 3 (landmarks), 5.4 |
| 1.2 | Legs and arms are two-bone IK with a hinge built from a **pole**: the knee's pole is the foot's forward direction (over the second toe), never the body's facing. | 1.2 rule 3; brief mistake 1 |
| 1.3 | Soft IK: the leg never snaps straight; above 97 % of its reach the reach is eased (exponential), and the pelvis drops first so the soft zone is rarely entered. | 4.x; brief mistake 3 |
| 1.4 | Ankle limit 20° up / 50° down. If a pose asks for more dorsiflexion the **heel lifts** (the foot rolls about the ball) and the leg is solved again. | 1.2 rule 4, 1.1 |
| 1.5 | Knee 0-140°, at most 5° past straight (the analytic solve cannot bend it backward). | 1.1 |
| 1.6 | Forearm twist: the hand's roll about the forearm axis is shared 50/50 between the forearm and the hand. | 1.2 rule 1; brief mistake 4 |
| 1.7 | Fingers never straight: resting curl, index ~15-20°, little finger ~40-50° at the knuckle, thumb beside the index. | 1.2 rule 7 |
| 1.8 | Head stabilised: it holds its own world yaw/pitch target (look direction) and counter-rotates against the trunk's sway and bob. | 1.2 rule 6, 2.5 |

## 2. Gait (the weak point of procedural: most work goes here)

| # | Decision | Follows |
|---|---|---|
| 2.1 | One gait clock per stride: left foot strikes at phase 0, right at 0.5. Duty factor (stance share) walk 0.60-0.62, run 0.40 falling to 0.30 with speed. Walk has two double-support spells; run has two flight spells. | 2.1, 2.2 |
| 2.2 | Cadence from speed. Walk: 75 + 30·v steps/min (1.35 m/s → 115, step 0.70 m). Run: 150 + 5·v (4.6 m/s → 173, step 1.6 m). Speed comes from stride length, never from playing faster. | 2.1, 2.2, 4.1; brief mistake 7 |
| 2.3 | Walk-run switch at 2.0-2.2 m/s with hysteresis, done at a foot strike. The 1.8-2.2 band is not a speed the stick can hold (stick mapping jumps over it). | 2.2 |
| 2.4 | Footstep planner: a swinging foot's landing spot is re-planned every tick until it lands: body position predicted at touchdown + velocity x half the coming stance time (the body is over the foot at midstance), ± half the step width (walk 10 cm, run 6 cm) across the heading, toes out 7°. A planted foot never moves (planted-foot slide 0 by construction). | 2.1, 2.2 ("foot lands under the knee"), 4.1 |
| 2.5 | Centre of mass, walk: inverted pendulum, hips highest at mid single support, lowest in double support, 4-5 cm per step at 1.35 m/s (scaled by speed), 2-4 cm side shift over the standing foot. Run: spring-mass, hips lowest at midstance, 6-10 cm. | 2.1, 2.2 |
| 2.6 | Foot roll: heel strike with the toes up, foot slaps flat in the loading 10 %, heel lifts from 30 % (terminal stance), toes bend up to ~55° at push-off, ankle 15-20° down at toe-off. Run: lands mid-foot under the knee. | 2.1, 2.2 |
| 2.7 | Swing arc: the ankle rises early (heel lifts behind, knee to 60-65° walk, 90-130° run), the toe clears the ground by 1-2 cm walking at mid-swing, then the leg reaches forward. | 2.1, 2.2 |
| 2.8 | Pelvis: yaw ±4-5° with the reaching leg, drops ±5° on the swing side; the chest counter-turns ±5-7°. | 1.2 rule 5, 1.1 (lumbar/thoracic) |
| 2.9 | Arms swing opposite the legs from the shoulder ±15-20° walking (elbow 20-45°, more on the forward swing); running elbows ~90°, hands forward and slightly in, never across the centre line. Arms are solved by the same two-bone IK (hand target), elbow pole behind and out. | 2.1, 2.2 |
| 2.10 | Trunk lean: running 5-15° forward; acceleration lean atan(a/g); turning lean atan(v²/(g·r)) = atan(v·ω/g); **from the feet** (the whole body rotates about the ground point), smoothed 0.1-0.15 s. | 2.2, 2.5, 4.5; brief mistake 6 |

## 3. Starts, stops, turns, responsiveness

| # | Decision | Follows |
|---|---|---|
| 3.1 | Response inside 0.1 s: on the tick the stick moves, the head turns to the new direction and the lean starts; the first step lifts within ~0.1-0.15 s. | brief (responsive), 2.5, 8.5 |
| 3.2 | Start: the clock starts just before the chosen foot's lift-off, so the pelvis first shifts sideways onto the standing leg (the same pelvis-over-stance-foot rule as the walk, no special case); the first step is short because the body is still slow. Walk full speed in 2-3 steps, run in 3-5. | 2.3 |
| 3.3 | Stop: the speed target goes to 0; the planner aims each landing at the predicted stopping point ± half stance width, so the last step is short and the second foot comes alongside; stops on **whichever foot is next**. Walk 1-2 steps, run 2-4. The clock halts once both feet are down at their idle spots. | 2.4 |
| 3.4 | Turns: small turns inside the steps (each foot lands rotated to the heading at touchdown). Big reversals at a run: the velocity is acceleration-limited (braking stronger than speeding up), so the body plants, brakes, pivots and pushes off the other way; the feet land wherever the planner puts them. | 2.5 |
| 3.5 | Head leads the turn by ~0.2-0.3 s: the head aims at the stick direction at once, the body yaw follows at a limited rate. | 2.5, 4.5 |
| 3.6 | Idle: both feet down, stance ~22 cm, weight moves foot to foot every 4-8 s, breathing. A foot that is far from its idle spot after a turn re-plants with a weight shift first. | 4.5, 2.3; brief mistake 10 |
| 3.7 | Catch step: a planted foot whose hip has moved past the leg's reach is lifted early (balance), rather than stretching the leg. | 2.3 (falling and catching) |

## 4. Controls, camera

| # | Decision | Follows |
|---|---|---|
| 4.1 | PC: W A S D / left stick, analogue walk to run by stick push (deadzone 0.2, walk 0.7-1.5 m/s up to 0.75, run 3.0-4.6 m/s from 0.85); keyboard W = walk 1.4, Shift = run 4.6. Touch: left half floating stick (80 px full), right half look, double taps = crouch (left) / jump (right). | brief controls, 2.1, 2.2 |
| 4.2 | Camera third person behind the shoulder, ~3.4 m, eased, never cut, pulled in by walls. | brief camera |

## 5. Learned while tuning step 4 (each found by a test number or a trace, then checked against the study)

| # | Decision | Follows |
|---|---|---|
| 5.1 | The rig's toe bones sit at different places on the two feet (left ball 14 cm ahead of the ankle bone, right 10 cm; the right ankle bone is mid-foot). The foot rolls over the **anatomical ball, 72 % of the sole from the heel**, measured on the mesh, not over the toe bone. On the right foot the toes may move ~1-2 cm at full heel lift (the mesh bends at its bone, not at the ball). | 1.1 toes, 2.1 terminal stance |
| 5.2 | Push-off in two stages: roll over the ball with the toes flat up to 45°, then over the **toe tips** with the toes held bent (toe-off). Without it the trailing leg could not reach and the pelvis was dragged down 8 cm. | 2.1 (pre-swing, toes bend ~55°) |
| 5.3 | Heel lift is geometric: a trailing foot lifts its heel as far as the leg needs to stay within 97.5 % of its length (knee soft), never later than that. Only a foot **behind** the hip does this. | 2.1 ("body falls forward over the ball"), 1.2 rule 4 |
| 5.4 | The pelvis never asks a planted leg for more than 98.5 % of its length (inside the soft-IK zone), and the limit is fed back into the pelvis spring so releasing it does not pop. | 4.5 "pelvis follows the lower foot", 4.6 item 1 and 5 |
| 5.5 | Midstance knee ~15° (pelvis cap at 99 % leg), heel strike knee nearly straight. Walk bob measures 6 cm at 1.4 m/s. | 2.1 (study 4-5 cm: 1 cm over; see conflicts) |
| 5.6 | The swing foot moves **relative to the body** (an oval about the hip) and is handed to its world landing spot over the last 20 % of the swing. A world-space path made the running foot overshoot 0.6 m ahead with a straight knee. | 2.2 "foot lands under the knee", 1.1 knee in swing |
| 5.7 | Footsteps are planned under the **leaning body**, not under the capsule; when stopping, under the capsule (where he will stand). | 2.5 lean from the feet, 2.4 |
| 5.8 | Lean: a critically damped spring on atan(a/g), at most 16° and at most ~57°/s, so the hips never move more than ~2 cm a frame from it. | 2.5 (3 m/s² ≈ 17°), 4.5 (0.1-0.2 s), 4.6 item 5 |
| 5.9 | On the heel (loading), an ankle past 20° up is solved by the foot slapping flat about the heel, not by lifting the heel. | 2.1 loading, 1.2 rule 4 |
| 5.10 | Walk start 1.3 m/s² (full 1.4 m/s in ~1 s), run start 4 m/s² (4.6 m/s in 1.1 s, 3 steps), walk stop 3 m/s² (2 steps), run stop up to 7 m/s² (3 steps). | 2.3, 2.4, brief (responsive) |
| 5.11 | Relaxed arms hang 7° forward and 10° out from the body line; the swing is about that. | 2.1 arms |
| 5.12 | A planted foot past its stance share always lifts (the share changes with speed); a foot that stayed down to finish a stop is marked and skipped for that stride only. Found by the analog-stick test (a foot was left behind). | 2.1 timing |

## 6. World contract (WORLD_CONTRACT.md, 25 Nov, relayed from Yasin by the game's session; the file is on the brief branch)

| # | Decision | Follows |
|---|---|---|
| 6.1 | Layers as in the contract: capsule on layer 2, colliding with 1, 3, 4, 5, 6 (not debris). Every probe (ground, foot, camera) uses mask 1, 3, 4 (never debris). | contract 1 |
| 6.2 | Probes are live every tick; nothing is cached across frames yet, so `obstacle_changed` has nothing to drop. When traversal caches edges (step 6) it must listen to it. | contract 3 |
| 6.3 | The course has a breakable-bin stand-in (layer 3), a debris slab (layer 7), a window and a door leaf (layer 4). Test: walking over the debris slab, the feet stay on the ground (PASS). Window-as-wall and broken-window-as-opening are traversal tests, for step 6-7. | contract 4 |
| 6.4 | No punches or kicks exist, so no `strike()` call yet. | contract 4 |

## 7. Step 5: kerbs, steps, stairs, slopes (the same planner, no separate modes)

| # | Decision | Follows |
|---|---|---|
| 7.1 | A live ground profile every tick: ~70 rays from 0.4 m behind to 2.4 m ahead along the path, each starting 0.5 m above the last sample (follows stairs up); a ray that starts inside something ends the profile (a wall: step 6). Edges = height jumps over 2.5 cm; slope fitted over the next 1.2 m; stairs = two or more same-way edges 0.18-0.5 m apart with 8-26 cm risers. Nothing is kept across frames. | 4.4 (look 1.5-3 m ahead), 2.8, WORLD_CONTRACT 3 |
| 7.2 | Landing choice: each landing slides up to 25 % of the step (45 % on stairs) to the nearest spot where the sole is on one level, preferring a spot from which the next step is also clear, and sticking to its earlier choice. No foot ever lands across an edge or into a riser. | 2.8 ("no foot lands on the edge", adjust 2-3 steps out), 4.4 |
| 7.3 | On stairs the **ball** carries the foot: the heel may hang over the step below going up, the toes over the step below going down, never into a higher level. The foot's height is read under the ball. One tread per step walking, two running. | 2.7 ("a third of the way onto the tread", "heel overhangs slightly") |
| 7.4 | Below a drop the heel lands 6 cm + a quarter of the drop past the edge (3 cm on stairs). | 2.8 (down a kerb: the step is a little longer), 3.3 |
| 7.5 | Swing clearance per sole point (heel, ball, toe tip): each clears the ground under it by 3-5 cm, and the toe also what is just ahead of it; the margin fades at lift-off and touchdown; on flat ground no extra margin (toe clearance 1-2 cm). | 2.7 (toe clears the nosing by 3-5 cm), 2.8 (foot raised 3-5 cm above the kerb), 2.1 |
| 7.6 | Stepping down, the foot first reaches out past the edge, then lowers; stepping up, it rises first, then moves onto the step. | 2.8 ("the leading leg reaches down"), 2.7 (swing knee lifts 80-100°) |
| 7.7 | Landing: up a step flat / forefoot, down a step toes first (the heel lowers as the knee brakes), level ground heel first; on a smooth slope uphill flatter, downhill heel first. | 2.7, 2.6, 3.3 (toes → heel → ankle → knee) |
| 7.8 | The hips ride the line between the support foot and where the next foot goes, so on stairs they glide on the pitch instead of stepping. A swinging foot near touchdown pulls the hips' target down to meet it (soft); a planted leg keeps them within 97.5 % of its length, lowering at most 1.8 cm a frame, with an instant limit only past 99.5 %. | 2.7 ("a smooth line parallel to the stair pitch"), 4.5, 4.6 item 5 |
| 7.9 | Speed: stairs at one tread per step (~95 steps/min up, ~105 down; 150 running), braking toward that pace over the last metre; a step over 18 cm slows him to 1 m/s ("a pause in rhythm"); slopes over 5° slow 1.2 % per degree, with a slightly quicker step (shorter steps). | 2.7, 2.8, 2.6 |
| 7.10 | Posture: trunk forward uphill (≈ the slope × 0.8 + 3°) and 12° on stairs up; slightly back downhill; eyes down 22° on stairs down, 8° when an edge is 0.3-1.8 m ahead. | 2.6, 2.7, 2.8 (look at the kerb ~2 steps ahead), 4.5 |
| 7.11 | The capsule's height follows the ground under it through a 0.08 s filter (the collision capsule floats 0.25 m up; steps over that are step 6's job). | 7.4 floating capsule |
| 7.12 | Springs use the exact critically damped step (a stiff spring no longer jumps a quarter of the gap in one frame). | 4.6 item 5 |

**Finding about the real city (for the map, not changed here):** the survey said collision stairs are coarse, and the
real porch confirms it: its collision is a 0.20 m block and then the deck 0.30 m above it, while the picture shows three
16.7 cm risers. A procedural (or any) foot system that probes the collision sees a 0.30 m step there, which is a "big
step up" (3.1), not stairs. Dock, courthouse and dingbat stairs collide as 0.55-0.72 m blocks. Either the collision
gets a box per step (or a ramp the feet can read the steps from the mesh), or these become climbs.

## Conflicts with the study
- Walk bob 6.0 cm vs the study's 4-5 cm (±15 %). The pendulum geometry of this body (leg 0.77 m, 0.70 m steps) gives
  ~6 cm; lowering it further means bending the stance knee more than the study's ~5-15° at midstance. Kept the knee.
- Run bob 10.6 cm vs 6-10 cm: just over, from the landing dip. To be tuned in polish (step 8).
- Stairs walking speed: one tread per step at ~95 steps/min gives 0.44 m/s along the stair. That is what the study's
  numbers give; it will feel slower than GTA V, where stairs barely slow the player. Kept the study; say if you want
  him quicker on stairs (two treads at a time is a one-line choice).
