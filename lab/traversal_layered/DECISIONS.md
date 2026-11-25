# Experiment B (layered, GTA-style): decisions

Every design decision, with the study section (`STUDY.md`) it follows. A decision with no study section is marked
**(no section: question it)**. Conflicts between this approach and the study are listed at the end; the study wins.

Contract: `LAB_BRIEF.md` (copy of `docs/locomotion/lab/LAB_BRIEF.md`). Study: `STUDY.md`.

## 0. Ground rules of this experiment
| # | Decision | Study |
|---|---|---|
| 0.1 | Its own Godot 4.7.2 project in `lab/traversal_layered/`, Jolt for every platform (`3d/physics_engine="Jolt Physics"`, not only Android), physics interpolation on, 60 Hz physics. | 7.1, 6.5 |
| 0.2 | All runtime code in C++ (GDExtension in `native/`): movement, animation stack, IK, camera, input. GDScript only for the clip-build tool and the tests. | brief |
| 0.3 | Mixamo files are never committed, and nothing derived from them either (no baked `.res`). A fetch-and-build step downloads them from Yasin's Drive on first Play (Windows and Linux alike), loads them with Godot's runtime `FBXDocument`, retargets and measures them, and caches the result in `user://`. | brief (Mixamo terms) |
| 0.4 | One animation system moves the body: the capsule is authoritative, the clip stack only poses the skeleton over it. Nothing else writes the root. | brief ("two systems both moving the body") |

## 1. Body and retargeting
| # | Decision | Study |
|---|---|---|
| 1.1 | player_v3 imported with Fix Silhouette OFF (brief trap). Its rig (Meshy, 54 bones, no toe end, no twist bones) is mapped by name to the humanoid profile; clips are mapped the same way. | 5.5, 6.3 |
| 1.2 | Own retargeter, the same code for every clip: world-space rotation delta from the source rest, applied to a target *reference pose*. **Revised 25 Nov evening:** each limb is swung **whole** (hip→ankle; shoulder→wrist with the hand and fingers; the clavicle on its own) so the body keeps its own rest joint angles; the first version swung each bone and bent the mesh knee 16-19° backward (STATUS #14). Feet, spine, head keep the body's rest. | v2 1.2 (rest-relative), 12.4, 13.3 |
| 1.3 | Motion scaled by the straight-leg ratio (rest hip→ankle, body / clip), the ankles kept at their standing height. | v2 12.4, 13.3 |
| 1.4 | Root motion made at build time: hips' horizontal travel and yaw moved to a ground root; bob, sway, tilt stay on the hips. | 5.3 |
| 1.5 | The root's direction comes from a 0.2 s smoothing (no sway), its progress along that direction from a 0.05 s one, so braking and pushing stay sharp and stops are not stretched. | 5.3, 4.1 |
| 1.6 | The leg ratio and reference pose are taken per file: "with skin" files carry a different skeleton than "without skin" ones. | 5.2, 5.4 |

## 2. Clip measurement (at build time, stored with each clip)
| # | Decision | Study |
|---|---|---|
| 2.1 | Per frame: foot contact (toe/heel height and speed thresholds), per clip: speed, cycle length, foot phase (left down = phase 0), contact windows, loop seam error. | 4.1, 4.2, 5.4, 6.5 |
| 2.2 | Loops cut to one stride starting at left heel-strike, so walk and run share a phase and blend in sync. | 4.1, 6.5 (sync) |
| 2.3 | Duplicates in the library (same take saved twice) are detected by hash and kept once. | brief |

## 3. Locomotion core (step 4)
| # | Decision | Study |
|---|---|---|
| 3.1 | Capsule-led (GTA V): the stick sets a desired velocity; the capsule accelerates to it with profiles tuned to reach walk speed in 2-3 steps and run speed in 3-5 steps, and stop a walk in 1-2 steps. The clip stack follows the capsule (distance matching for starts and stops, stride warping for loops). | 2.3, 2.4, 8.3, 8.5/1 |
| 3.2 | Speed bands: walk 1.2-1.8 m/s, run 3-4.6+ m/s; the 1.8-2.2 m/s band is crossed, never held. | 2.1, 2.2 |
| 3.3 | Loop speed matching: playback rate within ±20 %, beyond that stride warping (scale the feet's forward reach, keep cycle time), beyond ±30 % the next clip. | 4.1 |
| 3.4 | Phase-synced blending between walk and run loops (one shared normalized foot phase). | 4.1, 6.5 |
| 3.5 | Starts, stops and pivots chosen by the current foot phase; where only one foot's clip exists, the mirrored clip covers the other foot. | 2.3, 2.4, 2.5, 4.2 |
| 3.6 | Every switch is inertialized (offset + velocity decayed over ~0.2 s), never crossfaded. | 4.2 |
| 3.7 | Small turns are carried inside the steps (turn rate 6 rad/s walking, 3.2 at a run); over 135° a pivot clip (the one that turns the asked way, timed to its planting foot); starts up to 120° off are a straight start warped by spinning on the stance foot (7 rad/s), from a run 60°+ the turning run start. | 2.5, 8.3 |
| 3.8 | Layered idle: after a stop or pivot the legs and hips keep that clip's final stance and only the upper body plays the idle clip, so the planted feet never slide to the idle clip's stance. | 4.2 (leave a clip at a matching pose), 4.1 |
| 3.9 | A stop is over when the second foot has come down alongside (then idle, inertialized); after its entry strike it plays at rate 1. | 2.4 |
| 3.10 | In root-motion modes the capsule never goes faster than the speed it came in with (stops, pivots) or 1.1 x the asked speed (starts): some clips' roots spike. | 4.1 |
| 3.11 | Starts hand over to the loop at the first strike after which the start's root speed is >= 85 % of its top speed; the loop keeps the capsule's speed (no jump). | 4.2 |
| 3.12 | No input lock: releasing during a start's weight shift goes straight back to idle; during a start, to a stop; pushing during a stop goes back into the loop on the foot that is down. | brief (responsive), 8.3 |

## 4. Procedural layers
| # | Decision | Study |
|---|---|---|
| 4.1 | Whole-body lean from the feet: atan(v²/(g r)) into curves, atan(a/g) for acceleration, smoothed 0.1-0.2 s. | 2.5, 4.5 |
| 4.2 | Head leads turns by 0.2-0.3 s and stays level (counter-rotates trunk sway). | 1.2/6, 2.5, 4.5 |
| 4.3 | Foot IK: knee pole over the second toe, soft IK at full reach, ankle limited to 20° up / 50° down, heel lifts past the limit. | 1.2/3, 1.2/4, 4.x |
| 4.4 | Forearm twist shared forearm/hand (the body has no twist bones). | 1.2/1, 5.1 |
| 4.5 | Foot lock while a foot is in a clip contact window, as a correction offset that keeps the contact point still: the heel while it is down, moving to the ball as the heel lifts. | 4.1, 2.1 |
| 4.6 | Knee pole = the foot's yaw only, clamped to +-40° of the body's forward (after toe-off the foot points down and back and flipped the knee backward). | 1.2/3 |
| 4.7 | Pelvis drop up to 5 cm (smoothed) when a planted foot is out of reach. | 2.6, 4.1 |
| 4.8 | Heel and ball never go under their standing heights above the ground probe. | 4.6/3 |
| 4.9 | A locked foot that goes more than 4 % past the leg's reach is let go with a 5 cm lift (0.25 s) instead of dragged. **(see conflicts)** | 4.1 |
| 4.10 | The acceleration lean is used only in the loop (starts and stops have their own lean in the clip); the turn lean everywhere. | 2.5, 4.5 |

## 5. Camera and controls
| # | Decision | Study |
|---|---|---|
| 5.1 | Third person over the shoulder, ~3.4 m, eased, never cut. | brief |
| 5.2 | Controls exactly as the brief (no extra buttons); traversal starts from movement. | brief, 8.5/2 |

## 6. World contract (Yasin, 25 Nov; `WORLD_CONTRACT.md`, copied in)
| # | Decision | Study / source |
|---|---|---|
| 6.1 | Layers: capsule on layer 2, collides with 1\|4\|8\|16\|32 (mask 61), never debris (64). | contract 1 |
| 6.2 | Every ground / step / traversal probe uses mask 1\|4\|8 (= 13). Debris is never stood on, climbed or vaulted; an intact window or door is a wall, a broken one an opening. | contract 1, study 3.1 rules |
| 6.3 | Probes are live every tick; nothing cached across frames, so `obstacle_changed(AABB)` needs no cache to clear today. If a cache is ever added it is dropped on that signal. | contract 3 |
| 6.4 | The course gets a breakable bin stand-in (layer 3, becomes layer-7 debris when hit), a window and a door (layer 4) with tests. No punches or kicks in this lab yet; when added, their contact frame calls a stub `strike(from, to, radius, amount, kind, source)`. | contract 4 |

## 7. Clip library facts that shape the design (measured 25 Nov on player_v3, leg ratio 0.86)
| # | Fact / decision | Study |
|---|---|---|
| 7.1 | On this body (leg chain 0.86 of Mixamo's) the clips are slower: walk 1.54 m/s (brisk), jog 2.69, run 3.80, fast run 5.09. Keyboard walk 1.55, stick walk 1.0-1.55, run 2.7-4.2, Shift 4.6. | 2.1, 2.2, 4.1 |
| 7.2 | One walk start (right foot first) and one walk stop (left foot plants first): the other foot's versions are mirrors. | 2.3, 2.4, 4.2 |
| 7.3 | Starts include ~0.6 s of standing before the weight shift: the start is entered ~0.2 s before the first foot lifts, never at frame 0. | 2.3, 8.3 (responsive) |

## Against study v2 (25 Nov evening; `STUDY.md` is now v2, the sections in the tables below are v1's)
Each decision with its v2 section and whether it stands. "Breaks" decisions are listed in `STATUS.md` with their fix.
| Decision | v2 section | Verdict |
|---|---|---|
| 0.1 Jolt, physics interpolation | 13.5, 14 | stands |
| 0.2 C++ runtime | brief | stands |
| 0.3 Mixamo never committed | 12, brief | stands |
| 0.4 capsule authoritative, one system moves the body | 10.1 step 1 | stands, but the controller must obey Part 3 |
| 1.1-1.6 retargeting | 1.0 (measure the runtime skeleton), 12, 13.3 | stands; the knee hinge and sole points must be captured on the body (1.1, 1.2) |
| 2.1-2.3 clip measurement | 10.6, 10.7 | contacts must come from sole points (1.7) |
| 3.1 capsule-led | 10.1 step 1, 3.4 | stands |
| 3.2 speed bands | 4.1 (walk-run 2.0-2.2) | stands |
| 3.3 rate ±20 %, then stride | 10.1 step 3, 10.6 | stands |
| 3.4 phase-synced blends | 10.6 | stands |
| 3.5 starts / stops by foot | 4.5, 4.6 | stands |
| 3.6 inertialization | 10.5 | stands |
| 3.7 turn rates 6 / 3.2 rad/s, start warp 7 rad/s | 3.3, 4.6 | **breaks** (STATUS #1, #7, #8) |
| 3.8 layered idle | 4.6 | stands |
| 3.9 stop ends with the second foot down | 4.6, 3.4 (`STOP_STEPS`) | stands; run stop must still have ≥ 2 contacts |
| 3.10 speed caps | 3.4 | stands |
| 3.11 start hand-over | 4.5 | stands |
| 3.12 no input lock | 4.5 | stands |
| 4.1 lean from acceleration, added to the clip's | 3.2, 10.1 step 4 | **breaks** (STATUS #2, #3) |
| 4.2 head lead | 4.6, 2.4 | partly: head level not measured (STATUS #12) |
| 4.3 foot IK, ankle 20° up | 10.3, 1.4, 2.1, 2.2 | **breaks** (STATUS #4, #5, #6) |
| 4.4 forearm twist 50/50 | 6.11 | stands, unmeasured |
| 4.5 foot lock heel → ball | 10.6, 1.7 | stands; add yaw (STATUS #7) |
| 4.6 knee pole from the foot's yaw | 10.3 | **breaks** (STATUS #4) |
| 4.7 pelvis drop | 10.1 step 6, 10.3 | stands |
| 4.8 floor clamp | 1.7, 10.2 | stands; on sole points |
| 4.9 forced foot release | 6.12 | **breaks** (STATUS #9) |
| 4.10 accel lean only in the loop | 3.2 | replaced by one lean source |
| 5.1-5.2 camera, controls | brief | stands |
| 6.1-6.4 world contract | 6.12 (never on debris) | stands |
| 7.1-7.3 clip facts | 4.1, 4.3 | stands |

## Conflicts with the study
- **Walk stop takes ~1.6 s, the study says 1-2 steps.** The only walk stop clip (Mixamo "Stop Walking") makes a slow second
  step (0.9 s). Not faked; a crisp stop is in `CLIPS_WANTED.md`.
- **Knee over 140° in the run's swing** (7-11 frames per run): it is in the Mixamo run itself (layers off: same count).
  Study 1.1 gives 140° as the full range. Left as it is until a limit layer is added for swing (it would change the clip's
  look).
- **4.9 (forced release)** lifts a foot the clip still marks as planted, with no weight shift: the study lists "re-plant
  steps with no weight shift" as a mistake. It happens 2-8 times per scenario, in stops and pivots, when the clip's
  stance doesn't fit our speed. Better clips (stops, pivots per foot) would remove most of it.
- **Starts warp a straight start up to 120°** by spinning on the stance foot; the study's medium turns are a step turn or a
  spin turn (2.5), so this is the spin turn, but a real start-turn clip would also shift the weight first.

## 8. The v2 rebuild (26 Nov: Yasin, "build one new version with every clip you have from kimodo and completely guided by the study")
Built in the study's own order (9.6, 10.1): the validator first, then clips, controller, layers, limiter, fuzzer.
| # | Decision | Study |
|---|---|---|
| 8.1 | One C++ measuring module (`native/src/body.*`) for the validator, the limiter and the clip audit, on world-space bone transforms (skeleton global x bone global, interpolated when on, bases orthonormalised, metres). | 0.1/1-2, 1.0, 1.5 |
| 8.2 | Anatomical frames: the skeleton's axes at rest (player_v3 faces +Z, left = +X, checked at load), carried by every bone; every angle is rest-relative, so the rig's bent rest knees (29 / 16 deg bones, straight mesh) read 0. | 1.0, 1.2 |
| 8.3 | Knee: signed by geometry (ankle behind the hip-knee line, seen from the thigh's own forward = cross(thigh, hinge)), hinge perpendicular to the rest thigh, carried by UpLeg; varus and twist against it. | 1.2, 1.3 |
| 8.4 | Ankle: yaw about the shin's long axis, pitch above the plane normal to it, roll of the sole normal about the foot's forward against the shin's vertical plane (an Euler split; a swing-twist split read a pure twist as 30 deg of roll and was replaced after its mutation test failed). | 1.4 |
| 8.5 | Sole points from the mesh: vertices skinned > 60 % to Foot / ToeBase, the lowest 1.5 cm layer: heel = rearmost, balls = most medial / lateral within 2 cm of the toe joint, toe tip = foremost; heel carried by Foot, the rest by ToeBase. | 1.1, 1.7 |
| 8.6 | Elbow hinge = perpendicular to the rest upper arm and the body's forward (the palm side of a T-pose with palms down), not from the rest bend (player_v3's 18 deg rest elbow bend is upward, not a flexion). Checked on running clips: must read +70..+110. | 1.2 |
| 8.7 | Centre of pressure: each foot's contact points (heel, balls, heel+balls); two feet weighted by 1 / (horizontal distance to the CoM + 5 cm). An estimate, as 1.6 allows; it is why the per-frame lean check has 10 deg. **(approximation: question it)** | 1.6, 3.2 |
| 8.8 | Time rules evaluated at the centre of a +-40 ms window (at least +-1.5 frames) with a least-squares quadratic; discontinuity = the centre sample against a fit through its neighbours (centre excluded). A step closes at a new foot contact, or after 0.6 s of one stance (so standing still is judged too). | 1.8, 3.2 |
| 8.9 | Contacts by rays from 0.5 m above each sole point, mask 1\|4\|8; normals steeper than 30 deg ignored for the foot's ground normal (risers). | 1.7, 10.4 |
| 8.10 | Mutation tests (`tests/mutation_test.gd`): 357 cases, each rule and each axis on both sides, in the rest, A-pose, T-pose, random root yaw, random root tilt and random hip rotation. Extra rules that a test pose itself causes (a foot lifted while marked planted, a tilt sinking the toes) are listed per case as allowed; single-joint cases allow nothing else. | 9.2 |
| 8.11 | Body bones are shorter than v2 1.0's sanity range (thigh 0.38 m, shin 0.37 m, hip height 0.91 m): a warning, not a stop. It is Yasin's body. **(conflict: noted)** | 1.0 |
