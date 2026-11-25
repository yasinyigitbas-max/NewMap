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
| 1.2 | Own retargeter, the same code for every clip: world-space rotation delta from the source rest, applied to a target *reference pose* in which limb bones (upper arm, forearm, thigh, shin) are swung to point the way the Mixamo T-pose points. Feet, spine, head keep the body's own rest (sole angle comes from the body, then foot IK). | 5.4, 6.3 (rest fixer, done consistently) |
| 1.3 | Hips translation scaled by the hips-height ratio (body 1.00 m / clip ~1.0 m). | 5.4 ("scaled by the leg-length ratio"), 6.3 (normalize position tracks) |
| 1.4 | Root motion made at build time: hips' horizontal travel and yaw moved to a ground root; bob, sway, tilt stay on the hips. | 5.3 |

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
| 3.7 | Small turns (< 45°) are carried inside the steps by orientation; 45-135° by turn clips; 180° by the pivot clips. | 2.5 |

## 4. Procedural layers
| # | Decision | Study |
|---|---|---|
| 4.1 | Whole-body lean from the feet: atan(v²/(g r)) into curves, atan(a/g) for acceleration, smoothed 0.1-0.2 s. | 2.5, 4.5 |
| 4.2 | Head leads turns by 0.2-0.3 s and stays level (counter-rotates trunk sway). | 1.2/6, 2.5, 4.5 |
| 4.3 | Foot IK: knee pole over the second toe, soft IK at full reach, ankle limited to 20° up / 50° down, heel lifts past the limit. | 1.2/3, 1.2/4, 4.x |
| 4.4 | Forearm twist shared forearm/hand (the body has no twist bones). | 1.2/1, 5.1 |
| 4.5 | Foot lock while a foot is in a clip contact window. | 4.1 |

## 5. Camera and controls
| # | Decision | Study |
|---|---|---|
| 5.1 | Third person over the shoulder, ~3.4 m, eased, never cut. | brief |
| 5.2 | Controls exactly as the brief (no extra buttons); traversal starts from movement. | brief, 8.5/2 |

## Conflicts with the study
(none yet)
