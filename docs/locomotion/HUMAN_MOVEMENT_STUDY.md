# How people really move: the law for Coronado's locomotion and traversal (version 2)

Version 1 was written on 25 Nov 2026. Version 2 is a rewrite, made later that day after both traversal labs (procedural
and layered) produced a runner with a **knee bent backward, a rolled ankle and a 70° lean**. Their reports said
"backward knees: 0" and "joints past range: 0". Version 1 described a healthy body correctly, but it did not say how
to **measure** a game body against it, it left one formula uncapped, it had one limit that was wrong, and its checks
could pass a broken pose. Version 2 is written so that it **cannot be followed in a way that produces that picture**.

What this document is now:
- **A specification**, not a description. Every rule says what is measured, on which bones, in which frame, with
  which sign, what the limit is, and which test fails when the rule is broken.
- **About the final pose on screen**, never about an internal target. A lean "capped at 16°" in a variable means
  nothing if the bones the player sees lean 70°.
- **Three kinds of rule**:
  - **HARD**: anatomy or physics. A healthy person can't do it. Zero frames allowed, in any state, with any input.
  - **SOFT**: possible, but only in some situations (a hard landing, a stumble, an athlete). Allowed only in the
    states listed with it, and for at most the time given.
  - **TYPICAL**: what an ordinary man does. Targets for the look, checked by comparing to reference footage.

Body: an ordinary adult man, about 1.75 m, leg (hip joint to floor) about 0.90 m, about 75 kg, in street shoes.
Numbers vary about ±10-15 % between people. Where a number is from a named study it says so; the sources are in
Part 16.

| Part | What |
|---|---|
| 0 | How to use this document; what went wrong with version 1 |
| 1 | Measuring the body: segment frames, signed joint angles, centre of mass, lean |
| 2 | Joint limits: hard, soft and typical, coupled limits, joint speeds |
| 3 | Whole-body physics: balance, friction, lean, turn rate, flight, accelerations |
| 4 | Gait by speed: walking and running joint curves, starts, stops, turns |
| 5 | Slopes, stairs and kerbs |
| 6 | The city's obstacles, by height (going up, over, down; hanging; narrow ground; crouch; cover; walls; cars; doors) |
| 7 | Perception: what a viewer notices first |
| 8 | The failure catalogue: every way it looks wrong, its cause, the check that catches it |
| 9 | Verification: the validator, tests that must be able to fail, free play, the visual check |
| 10 | Building it so it can't break: the order of the pose pipeline, the final limiter |
| 11 | Thresholds in one table |
| 12-15 | Mixamo files, Godot's skeleton system, Jolt physics, how Rockstar does it (unchanged from version 1) |
| 16 | Sources, and the list of corrections to version 1 |

---

## Part 0 - How to use this document

### 0.1 The rules for whoever builds on it
1. **Measure the final pose.** Every check reads the bones' global transforms **after the last modifier** (IK, look-at,
   lean, every layer), on the frame that is drawn. Never check a target, a clip value or a variable.
2. **Measure with a sign, on every axis.** A joint angle without a direction can't tell a knee bent forward from one
   bent backward. A limit on one axis of a three-axis joint (the ankle's up / down only) leaves the other two free.
   Part 1 gives the exact frames and signs.
3. **Every check must be shown to fail.** Before a check counts, feed it a pose known to be broken (Part 9.2) and see
   it fire. A check that has never failed proves nothing.
4. **Free play, not only scripts.** Fixed test moves find fixed bugs. The bugs a player finds come from fast reversals,
   flicks, tight circles, camera spins, hitches and stairs at an angle. Part 9.3 is the input fuzzer.
5. **Look at it.** Numbers can't say "this looks human". Every change ends with rendered frame strips beside real
   reference footage (Part 9.4), looked at and described, before anyone else plays it.
6. **Hard rules are enforced in code, not hoped for.** A final limiter (Part 10.2) runs last and makes a hard
   violation impossible to draw. The validator still counts how often the limiter had to act: if it acts often, the
   layers before it are wrong.
7. **Physics before poses.** The controller may never ask the body for something a body can't do (a 4.6 m/s run
   turning on a 1.4 m radius). Part 3 limits the controller itself; the pose can't fix a physically impossible path.

### 0.2 What went wrong (the 24-25 Nov attempts), as a lesson
| What the player saw | What the code did | Rule here |
|---|---|---|
| Knee bent backward while running | Lab A measured the knee as the unsigned angle between thigh and shin: 30° backward read as a normal 30° bend. Its IK pole came from the foot's direction, so a twisted foot swung the knee backward. | 1.3 (signed knee, hinge axis carried by the thigh), 10.3 (pole from the thigh and pelvis, never the foot) |
| Ankle looking broken (foot rolled onto its side) | Both labs limited only how far the foot points up. Roll and twist of the foot against the shin were never limited or measured. | 1.4, 2.1 (ankle on three axes) |
| About 70° lean when running | Lab B turned a 4.6 m/s run at 3.2 rad/s: a 1.44 m radius, which needs 14.7 m/s² sideways and a 56° lean, more than shoe friction allows. Its comment said "about 3 m radius, 35°". Each layer capped its own lean, then the clip's lean, the spine bend and the turn lean stacked. Nothing measured the drawn body. | 3.3-3.4 (turn rate limited by lean and friction), 1.6 (lean measured on the final pose), 10.2 (final limiter) |
| "Joints past range: 0", "backward knees: 0" | The checks could not fail, and they ran only in 14 scripted moves. | 0.1 rules 3-4, Part 9 |
| "Hips pop under 2 cm a frame" passed | 2 cm a frame of change at 60 fps is 72 m/s², over 7 g. The threshold was ten times too loose. | 3.6 |

---

## Part 1 - Measuring the body

Bones in a game skeleton have arbitrary local axes (Mixamo, Meshy, Biped, and the rest pose's A or T, all differ).
**Never read an anatomical angle from a bone's local Euler angles.** Build anatomical frames from **joint positions**,
plus axes captured once and carried by the bone that owns them. Every sign below is **anchored in geometry** (where a
point lies relative to the body), never in "whatever the code returns", so the test can't agree with a wrong axis.

### 1.0 World space, scale and the skeleton you measure
- `Skeleton3D.get_bone_global_pose()` is relative to the **skeleton node**, not the world. If anything tilts or scales
  the model node (a lean applied to the node is a common shortcut), skeleton space hides it. Measure in world space:
  `world = skeleton.global_transform * bone_global_pose` (with physics interpolation on, the skeleton's **interpolated**
  global transform for the drawn frame). Orthonormalise the bases before use.
- **Scale**: Mixamo imports often carry a 0.01 scale (centimetres). All thresholds here are in metres in world space;
  measure after the scale, never in bone-local units.
- **Measure the runtime skeleton**: Godot's import options (BoneMap renames such as `LeftUpperLeg`, the retargeter's
  "Overwrite Axis" and "Fix Silhouette") change bone names and the rest pose. Capture every axis **after import, on the
  skeleton the game animates**, never from the source file.
- Names below are Mixamo's without the `mixamorig:` prefix; map them through the project's BoneMap. End bones
  (`LeftToe_End`, `HeadTop_End`) may be stripped on import: don't depend on them.
- **Sanity checks at load** (fail loudly): `LeftUpLeg` lies on the body's left (+X when facing +Z); the toes are ahead
  of the ankles; the head is above the hips; bone lengths are plausible (thigh 0.40-0.50 m, shin 0.38-0.48 m).

### 1.1 Points used
| Point | Where |
|---|---|
| hip joint L / R | `LeftUpLeg` / `RightUpLeg` origins |
| knee | `LeftLeg` / `RightLeg` |
| ankle | `LeftFoot` / `RightFoot` |
| pelvis centre | the midpoint of the two hip joints |
| lumbar top, chest, neck base, head | `Spine1`, `Spine2`, `Neck`, `Head` |
| shoulder, elbow, wrist, knuckles | `LeftArm`, `LeftForeArm`, `LeftHand`, `LeftHandMiddle1` (and right) |
| **sole points** (per foot) | captured once **from the mesh**, as offsets in the foot bone's frame (heel) or toe bone's frame (the rest): **heel** (rearmost, lowest sole vertex), **inner ball** (under the big toe's joint), **outer ball** (under the little toe's joint, ~8-9 cm from the inner one), **toe tip**. Not bone origins: the `ToeBase` origin sits 3-4 cm above the sole, and points on the foot's centre line can't show a roll. |

### 1.2 Axes, captured once, owned by a bone
Capture each axis as a world vector on a known pose, convert it into the **local frame of the owning bone**
(`axis_local = pose_global(bone).basis.inverse() * axis_world`), and at run time use
`axis_world = global_pose(bone).basis * axis_local`.

Body directions for one side use a **medial** vector (toward the body's middle; facing +Z, the body's left is +X):
`m = −X` for the left leg and arm, `+X` for the right, carried by the pelvis. Every side-dependent sign (inversion, abduction, rotation,
toe-out, varus) is defined with `m`, so left and right read the same way.

| Axis | Owner | Captured as |
|---|---|---|
| pelvis forward `p_f`, pelvis left `p_l` | `Hips` | rest: body forward (+Z, checked: toes ahead); right hip → left hip, orthogonalised against up |
| knee hinge `a` (thigh side) | `UpLeg` | rest: `normalize(L − t·dot(L, t))`, with `L` = body left and `t` = the rest thigh direction, i.e. **perpendicular to the rest thigh** (so an A-pose's spread leg reads 0 out of plane). Verified on a clip frame with the knee bent 40-90°: `cross(thigh, shin)` agrees within 10°; if not, take the axis from that frame. |
| knee hinge `a_s` (shin side) | `Leg` | the same vector, captured into the shin bone in the same pose |
| foot forward `F`, sole up `U` | `Foot` | from the sole points: `F` = heel → midpoint of the balls; `U` = normal of the heel / inner ball / outer ball plane, pointing up |
| chest forward | `Spine2` | body forward |
| elbow hinge `e` | `Arm` | `normalize(cross(upper arm, forearm))` from a frame where the elbow is clearly bent the right way (60-100°: any running frame of a reference clip). **Not** from a straight A or T pose, where the palm's direction decides it and differs between rigs. |
| head forward | `Head` | body forward |

**Never** derive the knee's hinge from the foot, the toe direction, the velocity or the IK target. The hinge belongs to
the thigh.

**Rest-relative rotations.** Every joint rotation is measured as the **deviation from the rest pose**:
`q = (rest_local)⁻¹ · current_local`, re-expressed in the anatomical frame. Canonicalise before reading angles:
if `q.w < 0`, negate `q` (otherwise a 10° twist can read 350°).

### 1.3 Knee (hinge with a little twist)
```
t = normalize(knee - hip) ; s = normalize(ankle - knee)
a = UpLeg_basis * hinge_local                          // carried by the thigh
t_p = normalize(t - a*dot(t,a)) ; s_p = normalize(s - a*dot(s,a))
mag = acos(clamp(dot(t_p, s_p), -1, 1))                // size of the bend in the hinge plane
// SIGN FROM GEOMETRY: the thigh's own forward is f_t = normalize(cross(a, t)) oriented so that
// dot(f_t, p_f) > 0 at rest (check once). A normal bend puts the ankle BEHIND the hip→knee line:
sign = dot(ankle - knee, f_t) < 0 ? +1 : -1
knee_flex  = sign * mag                                // + bent normally, − bent backward
knee_varus = asin(clamp(dot(s, a), -1, 1)) * side_sign // out of the hinge plane, + = knee outward (bow-legged)
knee_twist = signed angle between (Leg_basis * hinge_local_shin) and a, about s
```
The geometric sign can't be "calibrated" into agreeing with a wrong axis: a knee is bent backward exactly when the
ankle is in front of the line through the hip and knee, seen from the thigh's own side. Also check it on a reference
walking clip: `knee_flex` must be ≥ −2 on every frame.

### 1.4 Ankle and foot (three axes)
In the shin's frame: shin axis `s`, hinge `a_s`, shin forward `f_s = normalize(cross(s, a_s))`, asserted at rest:
`dot(f_s, p_f) > 0` (if not, the rig's axis is the other way: negate `a_s` and `a`, and say so in the log).
```
dorsi     = angle of F above its rest angle, in the plane normal to a_s       (+ = toes up)
inversion = roll of U about F against rest, sign by m: + = sole turned toward the body's middle (weight on the outer edge)
foot_abd  = yaw of F about s against rest, sign by m: + = toes out
```
**Against the ground, in contact** (the rolled-ankle check): when 2 or more sole points are within 1 cm of the
ground, the angle between `U` and the ground normal under the foot (from the same rays) is the **sole roll** and **sole
pitch**. Also the toe joint's bend (+ = toes bent up).

### 1.5 Hip, spine, neck, shoulder, elbow, wrist
- **Hip** (thigh against the pelvis frame `p_f`, `p_l`, `p_u`): flexion = angle of the thigh in the sagittal plane
  (+ forward, i.e. the knee ahead of the hip along `p_f`); abduction = out of the sagittal plane (sign by `m`: + = away
  from the middle); **rotation** = twist of the knee hinge `a` about the thigh against rest (sign by `m`: + = knee
  turned outward). Hip rotation is what catches a "backward knee" made by twisting the whole thigh round.
- **Spine**: lumbar = `Hips` → `Spine1` (deviation of the pelvis-to-Spine1 frame), thoracic = `Spine1` → `Spine2`;
  each: flexion (+ forward), side bend, twist, by swing-twist.
- **Neck**: `Spine2` frame against `Head` frame, same three.
- **Shoulder**: the upper arm direction in the chest frame: elevation (angle from hanging down), plane of elevation
  (forward / side / back), and the arm's twist by swing-twist about the arm.
- **Elbow**: like the knee, with `e` carried by the upper arm; sign from geometry (the wrist in front of the
  shoulder→elbow line, on the hand's side of the bend, is +).
- **Forearm**: pronation / supination = twist of the hand frame about the forearm axis against the elbow hinge.
  **Wrist**: flexion / extension and radial / ulnar deviation of the hand against the forearm.

**Swing-twist decomposition** (rest-relative rotation `q`, canonicalised `q.w ≥ 0`, about axis `d` in the parent's
anatomical frame):
```
p = dot(q.xyz, d) * d ; twist = normalize(Quaternion(p.x, p.y, p.z, q.w)) ; swing = q * twist.inverse()
twist_angle = 2*atan2(dot(q.xyz, d), q.w)   // signed, in (−180, 180]
swing_angle = 2*acos(clamp(|swing.w|, 0, 1))
```
If the projection and `q.w` are both ~0 (a 180° swing), the twist is undefined: treat it as a hard violation (no human
joint swings 180°). **The validator and the final limiter use this same function and the same limit shapes**, so they
can't disagree at the edges.

### 1.6 Centre of mass and lean
Centre of mass (CoM) from segment masses (de Leva 1996, adult men, % of body mass; CoM position along each segment):

| Segment | Mass % | CoM along the segment |
|---|---|---|
| head + neck | 6.9 | about halfway from the neck base to the top of the head |
| trunk (pelvis centre to neck base) | 43.5 | about halfway (sources give 0.45-0.55; use 0.5) |
| upper arm (each) | 2.7 | 0.58 from the shoulder |
| forearm | 1.6 | 0.46 from the elbow |
| hand | 0.6 | 0.79 from the wrist toward the middle knuckle |
| thigh | 14.2 | 0.41 from the hip |
| shin | 4.3 | 0.44 from the knee |
| foot | 1.4 | 0.44 from the heel to the toe tip |

The CoM is computed every frame from the world positions; filtered as in 1.8 before any acceleration is taken.

Three leans, each split into **forward** (along the pelvis's facing) and **sideways**:
- **Whole-body lean**: the line from the **centre of pressure** (CoP) to the CoM, against vertical. The CoP is
  estimated as the contact sole points weighted toward where the weight is: the ball when the heel is up, the heel at
  heel strike, the middle of heel and balls when flat; between two feet in double support, weighted by each foot's
  share (move it linearly from the back foot to the front one across the double support). Only on the feet in walking,
  running, starts, stops and turns; hangs, vaults, wall leans and cover have hand contacts and their own rules (6.12).
- **Trunk lean**: pelvis centre → neck base against vertical: what the eye reads as "how far he leans".
- **Trunk bend**: trunk lean minus the step-averaged whole-body lean: how much of the lean comes from folding at
  the waist rather than from the feet.

A run that leans into a turn leans **from the feet**: averaged over a step, the whole-body lean and the trunk lean are
close and the trunk bend is small. Within each step the whole-body lean swings back and forth with the foot's position
(3.2); judge "from the feet" on the step average.

### 1.7 Foot contact
Per foot, per physics tick: for each sole point (1.1), a ray from **0.5 m above** the point straight down (mask
1|4|8), so a point already under the surface still finds it. A point is **in contact** while within 1 cm of the
surface (above or below); **sunk** when more than 1 cm below; **hovering** when the foot is meant to be planted and the
point is more than 1 cm above. All slide, hover, sink and roll checks use these points, not the bone origins.

### 1.8 Filtering and time windows (frame-rate independent)
- Every limit with a time in it is in **milliseconds**, never frames.
- Before taking a velocity or acceleration, low-pass the signal (CoM position, joint angles) with a filter whose
  cut-off is ~12 Hz (for example a second-order Butterworth, or a quadratic fit over a ±40 ms window). Raw second
  differences amplify noise as 1/dt²: at 60 fps, 0.3 mm of IK jitter already reads 1 m/s².
- **Pops are caught as discontinuities**, not only as speeds: on each frame, compare every joint angle and the CoM
  with the value predicted from a smooth fit through the surrounding ±40 ms. A joint off its fit by more than 3°, or the
  CoM by more than 0.5 cm, is a pop, at any frame rate (a 40° knee snap in one 30 fps frame is only 1200 °/s, under the
  speed limit, but it is far off the fit).

---

## Part 2 - Joint limits

Angles are the signed angles of Part 1. "0" is standing straight (anatomical neutral). Hard = never, on any frame.
Soft = only in the listed situations. Typical = what an ordinary man uses.

### 2.1 The table
| Joint, axis | HARD (never past) | SOFT (only when) | TYPICAL walking / running |
|---|---|---|---|
| **Knee** flexion | -5 to 155 | 140-155: deep squat, hard landing, kneeling; -5 to 0: standing still, late walk stance | walk 0-65, jog 10-105, sprint 10-130 |
| Knee varus / valgus (out of the hinge plane) | ±8 | ±4-8: landing, cutting (inward only) | within ±3 |
| Knee twist (shin about its axis) | ±5 when flexion < 20; ±25 when flexion > 60 (linear between) | | within ±3 when straight, ±10 when bent past 60 |
| **Ankle** up (dorsiflexion) | knee flex < 15: 25; knee flex > 30: 40 (linear between) | above 20 with a straight knee: only on a steep uphill; above 30: squat, deep landing, running stance | walk 10, run stance 20-30 (Part 4) |
| Ankle down (plantarflexion) | 55 | 45-55: tiptoe, reaching with the toes, flight in a jump | walk push-off 15-20, run 20-30 |
| Ankle inversion (sole in, on the outer edge) | 30 | above 10 in contact: only when the ground slopes that way under the foot | within ±5 |
| Ankle eversion (sole out) | 15 | above 8 in contact: only on a side slope | within ±5 |
| **Sole against the ground**, with 2+ sole points in contact | roll and pitch 5° from the ground under the foot (except the heel lifting about the ball, which is pitch, allowed) | | 0-2 |
| Foot twist (toes out / in, against the shin) | out 30, in 20 | | toes out 5-10 |
| Toe joint (ball) bend up | 80 | above 60: push-off, kneeling, crouch on the toes | push-off 40-55 |
| **Hip** flexion | 125 with knee flex > 60; **90 with knee flex < 20** (hamstrings), linear between | above 110: climbing, a high step, a deep squat | walk -15 to 35, run -15 to 60, sprint -15 to 85 |
| Hip extension | 30 | 20-30: sprint push-off, a lunge | walk 10-20 at the end of stance |
| Hip abduction / adduction | out 45, in 30 | out above 25: side steps, straddling, a wide landing | ±10 |
| Hip rotation | in 40, out 50 | | ±10 |
| **Lumbar** (pelvis to Spine1) flexion / extension | forward 50, back 25 | | ±10 |
| Lumbar side bend | 25 | | ±5 |
| Lumbar twist | 10 | | ±5 |
| **Thoracic** (Spine1 to Spine2) twist | 35 | above 20: throwing, looking back | walk ±5-7, run ±10-15 against the pelvis |
| Thoracic forward / back | forward 30, back 20 | | small |
| **Neck** forward / back | forward 50, back 60 | | head pitched down 10-30 on stairs down and before obstacles |
| Neck turn | 80 | above 60: looking back | leads turns by 10-25 (4.6) |
| Neck side bend | 45 | | counter to the trunk's sway, head level |
| **Shoulder** elevation (arm from hanging) | 180 (cone, front and side), 60 behind | above 150: hanging, reaching up | walk: arm ±15-25 fore and aft; run: 30-40 forward, 30-50 back |
| Shoulder across the body (horizontal adduction) | 40 | | run: hands reach the centre line, never cross it |
| Shoulder twist | in 70, out 90 | | |
| **Elbow** flexion | -10 to 150 | -10 to 0: only pushing or hanging with locked arms | walk 15-45, run 70-110 |
| Forearm pronation / supination | 85 each way | | neutral (thumb forward) |
| Wrist flexion / extension | 80 / 90 | extension above 70: only pushing on a top, a press, a hand on a wall | slight extension |
| Wrist radial / ulnar | 20 / 35 | | |
| Fingers (knuckle, middle, end) | 90 / 110 / 90, and never past -5 | | resting curl (6.11) |

### 2.2 Coupled limits (one joint limits another)
- **Hip flexion with a straight knee is limited by the hamstrings**: with the knee under 20° the hip stops near 90°
  (less for a stiff man, 70-80°). Kicks and high steps bend the knee first.
- **Ankle up with a straight knee is limited by the calf** (gastrocnemius crosses the knee): about 20° with the knee
  straight, 30-40° with it bent (the weight-bearing lunge test, normal 35-45° of shin tilt). Version 1's "the ankle runs
  out at 20° up" is only the straight-knee case. Running stance needs about 25-30° and is normal.
- **Knee twist needs a bent knee**: a straight knee is locked against twist (the "screw-home" lock).
- **The shoulder blade moves with the arm**: above 30° of elevation, about one degree of blade rotation for every two
  of arm (scapulohumeral rhythm). An arm raised 150° with a still blade is a dislocated look.
- **A side slope steeper than ~15°** can't be met by rolling the ankle further (eversion stops at 15°): the foot turns
  across the slope or the person walks diagonally, and the uphill knee bends more.
- **Neck plus eyes**: the eyes turn up to ±30° alone; beyond that the head turns. A look-at that turns only the head to
  80° with the chest still is the limit; past it the chest turns.

### 2.3 Joint speeds (how fast a joint can move)
A joint that moves faster than a human can, even for one frame, reads as a pop. Measured on the final pose, as the
change of the signed angle per second, after the filter of 1.8. Joint speed alone misses a snap at a low frame rate;
the discontinuity check of 1.8 catches those.

| Joint | HARD | Typical peak |
|---|---|---|
| Knee | 1500 °/s | walk 300-400; run 700-900; sprint swing 1000-1300 |
| Hip | 1000 °/s | walk 200; run 500; sprint 700-800 |
| Ankle | 1200 °/s | walk 250-350; run push-off and landing 600-900 |
| Spine (each axis) | 300 °/s | 50-150 |
| Neck turn | 500 °/s (a fast look) | 100-200 |
| Shoulder | 1200 °/s | run arm swing 300-500 |
| Elbow | 1500 °/s | 200-400 |

Impacts (a landing, a car hit) may exceed these for at most 50 ms, only while a ragdoll or impact state owns the body.

### 2.4 Things that are not one joint but are still hard rules
- **Knee over the toes**, while the foot is in contact and the knee is bent more than 20°: the shin's forward `f_s` and
  the foot's forward, both flattened, within 25° (HARD 35°). (In swing or kneeling the shin can be near horizontal and
  the flattened direction means nothing: not checked there.)
- **No limb inside the body**: hands, forearms and elbows never inside the trunk's or the other arm's volume; the
  thighs never through each other. Check with capsules around the segments (radius: trunk 0.14 m, thigh 0.07, shin
  0.05, upper arm 0.05, forearm 0.04).
- **Feet don't cross under the body** in walking and running (the swing foot passes the stance foot at 5 cm or more),
  except a crossover step, a balance walk, or a turn's crossover cut.
- **Hands and feet in contact stay put** (1.7, 4.1, 8).
- **Head level**: in walking and running on the straight, the head's roll against the horizon stays within ±5° and
  its pitch changes less than ±5° over a stride (the eyes are stabilised). Leaning into a turn, the head stays more
  upright than the trunk: its roll is at most half the trunk's sideways lean.

---

## Part 3 - Whole-body physics

The body is a mass of ~75 kg moved only by forces from the ground (and hands, when they hold something). Every
movement must be one that ground forces could produce. If the controller asks for an impossible path, no pose can make
it look right.

### 3.1 Grip (friction) and what it allows
Horizontal force can't exceed μ × the vertical force. With street shoes (μ = coefficient of friction):

| Ground | μ | Most horizontal acceleration (μ·g) | Lean that matches it, atan(μ) |
|---|---|---|---|
| dry asphalt, concrete, brick | 0.6-0.8 | 6-8 m/s² | 31-39° |
| wet asphalt, concrete | 0.4-0.6 | 4-6 m/s² | 22-31° |
| grass, dry | 0.35-0.5 | 3.5-5 m/s² | 19-27° |
| wet tile, polished stone, metal plate | 0.2-0.3 | 2-3 m/s² | 11-17° |

These are the **physical** maxima, reached only by someone trying hard (a footballer's cut). An ordinary man stays well
inside them: about **20° of lean is the comfortable most** for a runner or a horse rounding a bend (commonly quoted
figure; Part 16), and ~0.4-0.5 g of horizontal acceleration in everyday hurrying.

### 3.2 Lean is decided by acceleration
The ground force on a foot points (nearly) from the contact through the CoM; otherwise the body would start spinning.
So, **instantaneously, with one foot in contact**: `tan(lean) = a_h / (g + a_v)`, where `a_h` and `a_v` are the CoM's
horizontal and vertical accelerations on that frame. Averaged over whole steps this is `atan(a_mean / g)`: forward for
speeding up, back for braking, inward for turning (`a = v² / r`).

**Within every step the whole-body lean swings**, even at a steady speed: at touchdown the foot is ahead of the CoM
(the body is braking, lean back), at toe-off behind it (pushing, lean forward). At a 4.6 m/s run, touchdown 0.3 m
ahead of a CoM 1.0 m up gives about 17° back, swinging to ~15-20° forward at toe-off. A walk swings ±10-15° over each
stance. That swing is correct; a constant lean "from the feet" all through the stride is the mistake. So the rules
are on two time scales:
- **Per frame (HARD)**, in walking, running, starts, stops and turns, with a foot in contact and no stumble: the
  measured whole-body lean (CoP to CoM, 1.6) and `atan(a_h / (g + a_v))` agree within 10° (the CoP is an estimate;
  a flat foot alone carries ~±6° of uncertainty). In flight there is no support: skip it.
- **Averaged over each step (HARD)**: the mean whole-body lean ≤ atan(μ) of the ground (≤ 35° on dry ground) in any
  direction, and it matches `atan(a_mean / g)` within 5°. A lean with no acceleration (leaning into a turn that isn't
  happening) or an acceleration with no lean (turning sharply while upright) both look wrong.
- **Trunk lean** (pelvis → neck base, what the eye reads; 1.6), in walking and running, **HARD**: forward ≤ 30°,
  back ≤ 15°, sideways ≤ 25°; and the **trunk bend** (trunk lean minus the step-averaged whole-body lean) ≤ 15° in any
  direction. This closes the loophole of a runner folded 70° at the waist with the hips pushed back over the feet:
  the whole-body lean looks fine, the trunk doesn't. Crouching, climbing, landing and the first step of a hard start
  may go further, only in those states.
- **SOFT** (step-averaged): sideways 20-28°: a hard cut, on dry ground, for 1-2 steps. Forward 20-30°: the first 1-2
  steps of a hard start. Back 15-28°: the last steps of a hard stop.
- **Wet or slippery ground**: the per-step cap atan(μ) is lower (wet tile ~11-17°), so the controller must turn and
  brake more gently there (3.3, 3.4); the per-frame swing at touchdown isn't capped by μ (it is a moment of braking).
- **TYPICAL** (step-averaged): steady run, whole body ~0-3° forward (air drag) and the **trunk** 5-12° forward; turns
  at a run 5-15° inward; walking turns under 5°.
- **In braking the legs do the leaning**: the feet are placed ahead and the whole-body lean goes back, while the trunk
  stays near upright (0-10° back). In a hard start the whole body and the trunk both lean forward.

### 3.3 Turning: how fast the heading may change
A smooth curve at speed v with lean θ has radius `r = v² / (g·tanθ)` and turn rate `ω = g·tanθ / v`. So:

| Speed | Lean 15° (typical) | Lean 20° (comfortable most) | Lean 30° (hard cut, dry) |
|---|---|---|---|
| 3.0 m/s (jog) | r 3.4 m, ω 50°/s | r 2.5 m, ω 68°/s | r 1.6 m, ω 108°/s |
| 4.6 m/s (run) | r 8.0 m, ω 33°/s | r 5.9 m, ω 44°/s | r 3.7 m, ω 70°/s |
| 6.0 m/s (fast run) | r 13.7 m, ω 25°/s | r 10.1 m, ω 34°/s | r 6.4 m, ω 54°/s |

- **HARD**: a sustained curve (more than 2 steps) is never tighter than the **20° column** for the current speed (or
  atan(μ) of the ground if lower); the **30° column** is allowed only for 1-2 steps of a cut on dry ground.
- A **sharper change of direction is a cut**, made **on a foot plant**, not by turning continuously: the planted foot
  pushes the body's velocity into a new direction in one stance. How much one plant can turn the path is set by grip:
  the most velocity change in one stance is about `μ·g·t_contact` ≈ 7 m/s² × 0.25 s ≈ 1.7-2 m/s, so keeping the speed,
  one plant turns the path by `2·asin(Δv / 2v)`:

  | Speed at the plant | One plant turns the path by at most |
  |---|---|
  | 4.6 m/s | ~20-25° |
  | 3.0 m/s | ~35-40° |
  | 2.0 m/s | ~55-60° |
  | 1.4 m/s and below | ~90° |

  So a 45° cut at a 4.6 m/s run takes two plants, or a slowdown first; a 90° turn needs the speed down near 1.5 m/s;
  for 135-180° the runner brakes to under ~1.5 m/s and pivots (4.6).
- **Walking turns are different**: the body is an inverted pendulum, not a leaning runner. A walking step can change the
  heading by 30-60° (step turn or spin turn, 4.6) with almost no lean.
- The 24 Nov lab turned 4.6 m/s at 3.2 rad/s (183°/s): r = 1.44 m, needing a 56° lean. Impossible at any μ.

### 3.4 Speeding up and slowing down
| Move | Ordinary man (the player) |
|---|---|
| Walk 0 → 1.4 m/s | 2-3 steps, ~1.0 s, ≤ 2 m/s² |
| Run 0 → 4.6 m/s | 3-5 steps, 1.2-1.6 s, peak 4-5 m/s² on the first steps (lean 22-27°) |
| Sprint 0 → 7 m/s | 6-10 steps, 2.5-3.5 s |
| Walk 1.4 → 0 | 1-2 steps |
| Run 4.6 → 0 | 2-4 steps, 2-3 m, peak 4-5 m/s² (lean back 22-27°) |

Athletes go to 6-7 m/s² (a 4.6 m/s stop in ~1.6 m, a 0.9 s start), which needs 31-36° of lean: not for the player.

**Why stopping takes steps** (the extrapolated centre of mass, Hof 2005): with CoM height l ≈ 1.0 m,
`ω0 = √(g/l) ≈ 3.1 /s`; the body can only stop over a foot placed beyond `x + v/ω0`. At 1.4 m/s that is 0.45 m ahead
(one step can do it); at 4.6 m/s it is 1.5 m ahead (no single step can), so the runner brakes over 2-4 steps.
**HARD**: no stop from a run in fewer than 2 foot contacts; the body never stands still with its CoM outside the feet.

### 3.5 Vertical motion and flight
- **In the air the CoM follows a parabola exactly**: horizontal velocity constant, vertical acceleration −9.81 m/s².
  Arms and legs can move, the CoM can't change its path. Viewers notice errors in **horizontal** speed in the air more
  than in vertical, and an added acceleration more than a slowdown (Reitsma and Pollard 2003).
- **HARD**: the CoM never accelerates **downward faster than gravity** (+1 m/s² tolerance). Snapping down to the
  ground, or a hips drop that is quicker than a fall, breaks this and is the most common "pop".
- **HARD**: with no foot or hand in contact, the CoM stays within 1 cm of the parabola set at take-off (its position
  and velocity then), and horizontal CoM acceleration ≤ 1 m/s² (game air control, if any, kept under this and never
  shown as a lean). A clip's authored root does **not** give this by itself (the clip's CoM in flight is not an exact
  parabola): the pipeline corrects the root in flight so the computed CoM follows it (10.1).
- Ordinary jumps: standing vertical jump 0.40-0.50 m (CoM rise), air time ~0.6 s; running jump 0.3-0.5 m rise,
  3-4 m long; stepping off a 1 m ledge at a walk lands ~0.6 m out.
- Landing forces: a 1 m drop landed softly (knees to 60-90°) peaks at 2.5-4 × body weight over 0.1-0.2 s; landed stiff,
  4-6 × in 50 ms. The softer the knees, the longer the landing: the stand-up takes 0.2-0.5 s.

### 3.6 Accelerations of the body on screen (replaces version 1's "2 cm a frame")
Measured on the final pose, on the CoM (and on the pelvis centre as a cross-check), after the 12 Hz filter of 1.8.
Durations are in milliseconds.

| Axis, state | HARD | Typical |
|---|---|---|
| horizontal, feet in contact | μ·g of the ground + 1 m/s² (about 8-9 on dry ground) | walk ±1-2; run ±3-5 |
| horizontal, in the air | 1 m/s² | 0 |
| vertical up, in contact | 30 m/s² (3 g) above gravity; landings up to 80 for ≤ 100 ms (a deep landing from 2 m) | walk ±3; run stance 10-20 |
| vertical down | g + 1 m/s² | |

At 60 fps, 9 m/s² is only 0.25 cm of change in the per-frame step. Version 1's "2 cm a frame" allowed 72 m/s².

Jerk (the change of acceleration) shows up as shaking: the CoM's acceleration should not reverse sign more than twice
per step. IK targets that fight each other show up here first.

---

## Part 4 - Gait by speed

### 4.1 Walking: numbers by speed (adult man, street shoes)
| Speed | Cadence (steps/min) | Step length | Stride time | Stance | Double support | CoM up-down | Step width |
|---|---|---|---|---|---|---|---|
| 0.8 m/s (slow, browsing) | 85 | 0.56 m | 1.41 s | 65 % | 2 × 15 % | 2-3 cm | 10-14 cm |
| 1.0 | 95 | 0.63 | 1.26 | 63 % | 2 × 13 % | 3 | 9-13 |
| **1.3 (normal)** | 108 | 0.72 | 1.11 | 61 % | 2 × 11 % | 4-5 | 8-12 |
| 1.6 (brisk) | 118 | 0.81 | 1.02 | 60 % | 2 × 10 % | 5 | 8-11 |
| 1.9 (very fast) | 126 | 0.90 | 0.95 | 58 % | 2 × 8 % | 5-6 | 7-10 |

- **HARD**: in a walk, at least one foot is always in contact; both feet down twice per stride.
- Walk to run at **2.0-2.2 m/s** (Froude number 0.5: `√(0.5·g·leg)` ≈ 2.1 m/s for a 0.9 m leg); run back to walk
  ~0.1-0.2 m/s lower. Don't let the player cruise between 1.9 and 2.2: make it a transition.
- CoM sideways sway 3-5 cm in all (over each standing foot in turn).

### 4.2 Walking: joint angles through the stride (1.3 m/s; 0 % = right heel strike)
Signed as in Part 1 (hip + forward, knee + bent, ankle + toes up). After Perry and Winter; ±5° between people.

| % stride | Phase | Hip | Knee | Ankle | Toes | Pelvis (right side) |
|---|---|---|---|---|---|---|
| 0 | heel strike | +30 | +3 | 0 | 0 | forward 4-5°, level |
| 7 | foot flat | +28 | +15 | −7 | 0 | |
| 12 | loading peak | +25 | +18 | −3 | 0 | left side dropping to −4-5° |
| 30 | mid stance | +5 | +5 | +7 | 0 | level, highest point of the body |
| 45 | heel rises | −8 | +4 | +10 (peak up) | +15 | back 4-5° |
| 55 | end of stance | −12 (peak back) | +20 | 0 | +40 | |
| 62 | toe off | −5 | +40 | −18 (peak down) | +50 | |
| 73 | swing, foot passing | +20 | +62 (peak) | −5 | 0 | |
| 87 | swing, reaching | +32 (peak) | +30 | 0 | 0 | |
| 100 | heel strike | +30 | +3 | 0 | 0 | |

- Trunk: upright, 0-5° forward; thorax turns against the pelvis ±3-7°.
- Arms: shoulder +10 forward to −20 back (bigger with speed), elbow 15-45° (more bent at the front), forearm neutral,
  hands below the waist. Opposite arm forward with each leg.
- Toe clearance in swing: only **1-2 cm** at its lowest (around 70-75 %).
- Head: up-down follows the CoM (4-5 cm), but its pitch stays within ±3° and its roll within ±2° (stabilised).

### 4.3 Running: numbers by speed
| Speed | Cadence | Step length | Ground contact | Flight per step | CoM up-down | Foot lands |
|---|---|---|---|---|---|---|
| 2.5 m/s (slow jog) | 158 | 0.95 m | 0.30 s | 0.08 s | 9-10 cm | mostly heel or flat (street shoes) |
| 3.5 (jog) | 164 | 1.28 | 0.25 | 0.12 | 8-9 | heel / midfoot |
| **4.6 (run)** | 170 | 1.62 | 0.21 | 0.14 | 7-8 | midfoot |
| 6.0 (fast run) | 180 | 2.00 | 0.17 | 0.16 | 6 | midfoot / forefoot |
| 8.0 (sprint) | 200 | 2.40 | 0.12 | 0.18 | 5 | forefoot |

- **HARD** above 2.5 m/s on level or downhill ground: a run has a flight phase on every step; both feet are never down
  at once for more than 20 ms (contacts read at the physics rate), except in the steps of a start, a stop or a cut. A
  slow jog under 2.5 m/s and running uphill may have almost no flight: SOFT there.
- The foot lands **0.2-0.35 m ahead of the CoM**, the shin near vertical at touchdown (tilted forward ≤ 10°).
  Overstriding (the foot far ahead, the knee straight, the shin tilted forward) looks wrong.
- Step width near 0-5 cm: the feet land almost on one line.
- The hips are **lowest at mid stance** (the leg is a spring), the opposite of walking.

### 4.4 Running: joint angles through the stride (3.5-4.6 m/s; 0 % = right foot strike)
After Novacheck's running review and later running-gait studies; at a sprint the swing values grow (column on the right).

| % stride | Phase | Hip | Knee | Ankle | Sprint differences |
|---|---|---|---|---|---|
| 0 | touchdown | +35 to +40 | +15 to +20 | 0 to +5 (heel / flat) | hip +50, ankle −10 (forefoot) |
| 10-15 | mid stance (lowest) | +15 | **+40 to +45** | **+20 to +30** (peak up, knee bent: normal) | knee +35-40 |
| 35-40 | toe off | −10 to −15 (peak back) | +15 to +25 (**not straight**) | −20 to −30 | hip −15, ankle −30 |
| 55-65 | early swing | +10 | +80 to +95 | −10 | knee +120 |
| 70-75 | swing peak knee | +35 | +90 to +105 (peak) | 0 to +10 | knee +125-135 |
| 85 | late swing | +45 to +55 (peak) | +40 | +5 | hip +75-85 |
| 95 | reaching down | +40 | +15 to +20 | +5 | |

- Trunk: 5-12° forward at steady speed, more while accelerating. Thorax turns against the pelvis ±10-15°.
- Pelvis: forward tilt 15-20° baseline ±3-5°, side drop ±5-8°, turn ±5-10°.
- Arms: elbow 70-110° (about 90 on average, swinging ±10-20° with the arm), shoulder from 30-40° forward to 30-50°
  back; hands from chest height in front to the hip behind; slightly across the body, **never across the centre line**.
- The knee **never straightens** in a run (minimum ~10-15° at touchdown and toe off).

### 4.5 Starting
1. Before the first step (in a real start: 0.3-0.4 s): the pressure under the feet moves **back and toward the
   stepping leg**, which tips the body forward and onto the standing leg. Then the stepping foot lifts.
2. The body falls forward and the first foot steps to catch it. The first step is 60-70 % of a normal one.
3. Full speed: walk in 2-3 steps, run in 3-5, sprint 6-10 (3.4).
- **Responsiveness**: a game can't wait 0.4 s. Compress the weight shift to 0.1-0.15 s and overlap it with the head
  and trunk turning toward the stick. **Rule**: something visible answers the stick within 0.1 s (head, trunk, the
  weight shift); the first foot leaves the ground within 0.25 s from standing.
- Starting straight into the walk loop (no weight shift) looks like gliding off.

### 4.6 Stopping and turning
**Stopping**: walking 1-2 steps; running 2-4 (3.4). The last step is shorter, the second foot comes alongside, the
body sways back 1-2 cm and settles (an overshoot, not a freeze). People stop **on whichever foot is next**.

**Turning, top-down order**: eyes → head → chest → pelvis → feet.
- The head turns toward the new direction **about 0.2 s before** the body changes path, up to ~25° ahead of the path;
  it starts at a roughly constant **distance** before the turn point (~1.1 m in walking), not a constant time (Grasso,
  Patla and others; Part 16). The trunk follows, the feet last.

**Walking turns**
| Turn | How | Steps |
|---|---|---|
| < 30° | inside the steps: each foot lands rotated a little | 1-2 |
| 30-90° | **step turn** (the outside foot steps out to the side, the body turns over it; more stable, the usual choice) or **spin turn** (pivot on the inside foot, the other leg swings round; quicker, less stable) | 1-2 |
| 90-180° | a spin turn over 2-3 steps, or a stop and turn on the spot (small steps, 3-4 of them) | 2-4 |

**Running turns**
| Turn | How |
|---|---|
| within the lean limit (3.3) | a curve, leaning from the feet |
| sharper (one plant: ~20-25° at 4.6 m/s, ~35-40° at 3 m/s; 3.3) | a **side-step cut**: the outside foot plants wide, the knee bends, the body is pushed into the new direction; or a **crossover cut** for 20-30° (turning left, the right leg crosses in front of the left and pushes off) |
| 45-90° | slow down over 1-2 steps, then a side-step cut |
| 135-180° (reversal) | brake over 1-2 steps (leaning back from the feet), **plant** wide with the foot on the turn side, pivot the body over it (the hips turn first, the trunk with them), push off the other way. 0.6-1.0 s from full run to running back. Left and right versions. Rotating a run in place is the classic glide. |

Turning on the spot (standing): the feet make 2-4 small steps (each ~45°), heel and ball lifting; the feet never spin
flat on the ground. **HARD**: a foot in contact never rotates about the vertical more than 5° while flat; pivots happen
on the ball, with the heel up.

---

## Part 5 - Slopes, stairs and kerbs

### 5.1 Slopes and ramps
| | Uphill | Downhill |
|---|---|---|
| Trunk | leans forward ≈ the slope angle + a few degrees | upright or slightly back |
| Steps | shorter, quicker | shorter, slower |
| Knee at landing | more bent (pushing up) | more bent (braking): the knee absorbs |
| Ankle | more up (≈ +slope angle at mid stance); the **heel lifts** when the need passes the limit of 2.1 (straight knee 25°, bent knee 40°) | heel first, the ankle lowers the foot |
| Arms | swing more, drive | held slightly out for balance |

- Up to ~5° (most streets; wheelchair ramps max ~4.8°): walking looks the same; the feet align, nothing else.
- 5-15°: the lean and shorter steps above are visible.
- 15-25°: steep: strong lean, heels off uphill; people zigzag downhill.
- Over ~30°: they turn sideways, use their hands, or scramble. **HARD**: no straight-down walk past 30°.
- Side slope: the sole follows the ground (inversion / eversion within 2.1's soft range), the **leg stays vertical**, the
  downhill leg bends more, the pelvis takes the lower foot's height.

### 5.2 Stairs
Typical steps: riser 15-19 cm, tread 25-30 cm (pitch 30-37°).

**Going up**: forefoot or whole foot lands about a third onto the tread, never heel first. The stance knee ~60° and the
hip ~60° at landing; the body rises by straightening them. Swing knee lifts to 80-100° (toe clears the nosing by
3-5 cm). Trunk 10-15° forward. Cadence 90-110 steps/min: ~0.3 m/s up, ~0.45-0.55 m/s along. Running up: two at a time,
on the balls of the feet.

**Going down**: toes first on the next tread, then the heel lowers; the landing knee nearly straight then bending to
80-90° as the body lowers. Trunk upright; **eyes down** (head 20-30° pitched) for the first steps. Cadence 100-120.
The heel overhangs on short treads.

**Animating**: the hips travel on a smooth line parallel to the stair pitch (with a small bounce per step), the feet go
to discrete heights. Step length is warped so every foot lands on a tread, never on a nosing (**HARD**: a foot's
contact points never on the edge, i.e. ball and heel both on the same tread or the ball on a tread with the heel
hanging over the step below, going down only).

**Coarse collision stairs** (city porches, docks): the collision is a block, the picture is steps. The feet must follow
the **visible** steps (the map supplies per-step collision, or a stair marker with riser and tread), never the block.

### 5.3 Kerbs (curbs)
Coronado's kerbs are 10-16 cm.
- People don't stop. The swing leg lifts more in the step before (foot 3-5 cm above the kerb), lands flat or forefoot on
  top, and the hips rise during that stance. The step onto it is a bit shorter.
- **2-3 steps before**, step lengths adjust so no foot lands on the edge (they look at the kerb about 2 steps ahead).
- Down a kerb: the leading leg reaches down, lands forefoot-flat, the knee absorbs; the step is a little longer.
- Up to ~20 cm all of it happens inside the walk. From ~20 cm people make an **obvious** bigger step: trunk forward, a
  pause in the rhythm, sometimes a hand on the thigh.

---

## Part 6 - The city's obstacles, by height

Body landmarks (1.75 m adult) used to choose the action:

| Landmark | Height |
|---|---|
| ankle | 0.08 m |
| shin middle | 0.25 |
| knee | 0.50 |
| hip (hip joint) | 0.90 |
| waist | 1.05 |
| chest | 1.30 |
| shoulder | 1.45 |
| eyes / head top | 1.65 / 1.75 |
| standing reach (finger tips) | 2.20-2.30 |
| reach with a running jump | 2.60-2.80 (a wall-run step adds 0.3-0.6 m: an athletic 3.0-3.4 m) |

### 6.1 Going up

| Height | Name | What a real person does | Hands | Time |
|---|---|---|---|---|
| < 3 cm | lip | nothing; foot IK only | - | - |
| 3-20 cm | kerb, single step | stepped inside the walk (5.3) | - | in stride |
| 20-45 cm | bench seat, low wall, planter | **big step up**: hip 80-100° flex, trunk forward 20-30°, push off the back foot; thin (< 30 cm deep): **step over** | maybe one on the knee or the top | ~0.6-0.8 s |
| 45-80 cm | knee- to thigh-high wall | **low mantle**: both hands on top, hop, knee onto the top, stand up on it; or a **step-vault** if going over | both, palms down | 1.0-1.4 s |
| 80-120 cm | hip-chest: railing, car bonnet, fence | going over: **vault** (6.2); going onto: **mantle** - small jump, arms lock straight on top, swing a foot or knee up | both | 1.2-1.8 s |
| 1.2-1.8 m | chest to head: walls, van roof | **climb**: jump, hands on top, **pull** (elbows down and back, chest to the edge), then the **press**: elbows rotate up over the hands, wrists extend, push to straight arms, then a foot up beside the hands, stand | both; hook then push | 1.5-2.5 s |
| 1.8-2.5 m | above the head | **jump to hang**, or a **wall-run step** (one foot pushes off the wall at ~0.6-0.9 m) to catch the edge; then the pull-up and press as above | hang from the hook grip | 2-3 s |
| 2.5-3.2 m | high wall | only athletic (wall-run, two steps) | | |
| > 3.2 m | | **not climbable** without features: a drainpipe, ladder, window sills, a bin to step on | | |

Rules:
- **Pull then press.** The hardest-looking part of a climb is the change from pulling (hands in front of the chest,
  elbows below) to pushing (shoulders over the hands, elbows straight up). In that moment the chest comes over the
  edge and the elbows swing up from below to behind. Clips that skip it look like the body is lifted on a string.
- **Feet help.** On a wall the feet scrabble and push on the face (one or two steps up the wall) while pulling. A
  free-hanging pull with dangling legs is only for overhangs.
- **Hands land first, then the body comes to the hands.** The hands are pinned on the top from contact until they leave
  (HARD: a gripping hand moves less than 1 cm on the surface).
- **No room to stand?** If the top is narrower than a foot (< 25 cm) or there is no headroom (< 1.8 m clear), people do
  not mantle onto it: they vault over, or they stay hanging.

### 6.2 Going over (vaults)

All vaults hinge on the **takeoff spot**: 0.8-1.2 m before the obstacle when running, about one step when walking. The
steps before are adjusted to arrive on it (people do this 2-3 steps out).

| Vault | Height | Speed | How | Who |
|---|---|---|---|---|
| **step-over** | < 50 cm, thin | walk | lift the lead leg over, then the trail leg; hip turns | anyone |
| **step / safety vault** | 0.6-1.1 m | walk-jog | one hand on top, the **same-side foot** steps on top, the other leg passes between, land on the far side | anyone (most natural for a "normal" person) |
| **sit / slide-over** | 0.8-1.1 m, deep (car bonnet, table) | walk-jog | sit on the hip, swing both legs over, slide off; the **hood slide** on a car | anyone |
| **speed vault** | 0.8-1.2 m, thin | run | one hand on top, body turns sideways, both legs together over the side | fit |
| **lazy / turn-around vault** | 0.8-1.2 m | jog, diagonal approach | both hands in turn, legs swing over at an angle | fit |
| **kong / monkey** | 0.8-1.3 m, long | sprint | both hands on top, dive forward, knees tucked between arms, push off | athletic |

For a normal man the **step vault** (one hand, one foot on top) under 1.1 m and the **slide-over** on cars are the
believable defaults; the speed vault when he is running. Over a fence of 0.5-1.2 m a running man speed-vaults;
at 1.2-1.4 m most people climb over (both hands, a foot on the top, swing over, drop) rather than
vault.

### 6.3 Going down

| Drop | What people do | Landing |
|---|---|---|
| < 20 cm | step down inside the walk | lead leg reaches, forefoot first, knee bends 20-30° |
| 20-50 cm | **step down** (keep walking): lead leg reaches down, the trail knee bends deep to lower the body | knee to 40-50° |
| 0.5-1.0 m | **hop / jump down** facing forward; or sit on the edge and slide off; slower people turn and step down backwards with a hand on the top | both feet, forefoot first, knees 50-70°, arms forward |
| 1.0-2.0 m | **jump down** with a deep landing (knees 80-100°, hips flexed, hands may touch); or **hang-drop**: turn round, crouch, hands on the edge, lower to hanging, drop (saves ~2 m: hands-to-feet length) | deep crouch, 0.2-0.4 s to recover |
| 2.0-3.0 m | hang-drop; with forward speed a **roll** (diagonal over one shoulder to the opposite hip) | roll or hard landing |
| > 3.0-3.5 m | hurt (stagger, fall, damage) | |

- **Landing order:** toes/ball → heel → ankle bends → knee → hip. The deeper the drop, the deeper and longer each.
  A landing that hits the knees and hips all at once looks like a pose swap.
- Stepping **off** an edge at walking speed, the body keeps its forward speed: the drop is a short arc, not straight down.
- **Climbing down a tall thing faces the wall.** Low things (< 1 m): face forward, hop. Mid (1-1.5 m): sit / turn side-on.
  Tall: turn round, kneel, hands on the edge, lower legs over, hang, drop. Mirror of the climb up.

### 6.4 Hanging and shimmying

- **Free hang:** arms straight, shoulders shrugged up, head between the arms (looking up or at the wall), body still
  swings a little (pendulum, ~2 s period for a 2 m body), legs together, toes pointing down, knees slightly bent.
- **Braced hang** (wall below): feet on the wall at about hip height below the hands, knees bent, hips away from the
  wall. More stable; this is how people mostly hang on buildings.
- **Shimmy** sideways: the leading hand moves first (lifts, slides 30-50 cm, re-grips), then the trailing hand follows
  (to ~shoulder width); the feet walk along the wall. Each hand move ~0.4-0.5 s.
- From a hang: pull up (6.1), drop (6.3), or move round a corner (hands cross the corner one at a time).

### 6.5 Narrow and wide surfaces (wall tops, kerbs edges, pipes, beams)

| Width | Behaviour |
|---|---|
| > 60 cm | normal walk (a pavement) |
| 30-60 cm (wall top) | step width shrinks toward 0, steps a bit shorter; people lean slightly away from the bigger drop |
| 10-30 cm (beam, kerb edge, narrow wall) | **balance walk**: feet in one line (heel in front of toe), toes out 10-20°, short steps (0.3-0.5 m), slow (0.5-0.8 m/s), knees soft, **arms out to the sides** (raised 40-80°, bent at the elbow), trunk upright, eyes 2-3 m ahead (not at the feet), corrections from the **hips** (the hip bends and the arms swing to catch a wobble) |
| < 10 cm, round (pipe, rail) | balance walk with the foot turned out ~20-30° and the arch over the pipe, even slower (0.3-0.5 m/s); or sideways shuffle; or straddle / crawl on hands and knees |

- On wide ground balance is held with the **ankles** (tiny invisible sways). On narrow ground the ankle cannot do it;
  the **hips and arms** do - visibly. That is the whole look of a balance walk.
- Running along a wall top is possible to ~20 cm width for athletic people; the arms stay out.
- A wobble: an arm swings up on the side away from the fall, the trunk bends the other way, a quick step or a crouch.
  If it fails, they crouch and grab the surface.

### 6.6 Crouching and crouch-walking

- **Crouch (ready / low):** hips down so the head is at ~1.0-1.2 m: knees 90-120°, hips 90-110°, trunk forward 20-40°,
  heels down if the ankle allows (20-35°) otherwise on the balls of the feet. Arms forward or a hand on the knee/ground.
- **Full squat:** head ~0.9 m, knees ~140°.
- **Crouch walk:** shorter steps (0.4-0.5 m), slower (0.8-1.5 m/s), wider stance (15-25 cm), the hips stay low with
  small bounce, foot lands flatter, trunk forward. Running in a crouch is a hunch-run, not a squat-walk.
- **Entering** takes 0.3-0.5 s (the hips drop first, the trunk tips forward with it); **leaving** 0.3-0.4 s.
- Crouch to clear headroom: the head goes under at ~1.2-1.3 m clearance.

### 6.7 Cover (walls, cars, corners)

- **Low cover** (0.8-1.2 m: car, planter, low wall): crouch with the back or the side to it; the shoulder touches;
  the head stays below the top. Peeking: rise from the crouch, head and shoulder over the top, or lean out at the end.
- **High cover** (wall, pillar, corner): stand with the back or a shoulder on it; the hands on the wall (fingers spread
  at chest height); peeking round a corner: lean the head and the near shoulder out from the waist, the feet stay put.
- **Moving between covers**: hunched run, then a sideways stop into the new cover (the shoulder meets it, a hand
  braces).
- **Behind a car**: the engine block and wheels stop things, so people kneel by the front wheel; along the car they
  move crouched, one hand trailing on the body.

### 6.8 Walls and corners in everyday movement

- People keep **20-40 cm off walls** when walking; nobody brushes them.
- Turning a tight corner fast, a hand goes out to the wall (a palm push) to turn round it.
- Leaning on a wall: one shoulder or the back; the feet 30-40 cm out; one knee bent with the foot against the wall.

### 6.9 Cars

- Around a parked car: 30-50 cm off it; past the mirror they turn the shoulder.
- **Over the bonnet**: sit-slide (hood slide) when in a hurry (bonnet ~0.8-1.0 m); hands on the bonnet, hip slides,
  legs swing, land on the far side.
- **Onto the roof** (1.4-1.6 m car, 1.8-2.0 m van): a foot on a wheel / the bumper / the bonnet first, then up; people
  never mantle straight onto a car roof from the ground.
- Getting in and out of a car is its own set of moves (open, duck the head under the roof line, sit, swing the legs in).

### 6.10 Doors

- Approaching, people slow from ~1.4 to ~0.8 m/s in the last 1.5 m, and the **hand reaches before the body arrives**
  (the reach starts 0.5-0.7 m from the door). Handles are at ~0.95-1.05 m.
- **Push door** (opens away): hand on the handle or flat on the door at chest height, push, and **walk through while it
  is still opening**; the pushing arm stays on the door as the body passes, then lets go. No stop.
- **Pull door** (opens toward): stop, grab, step **back and to the hinge side's opposite** while pulling, the door
  swings past, then step round it and through. A stop and a sidestep are unavoidable.
- Doorways are 0.8-0.9 m: the shoulders turn slightly when two people pass, or when carrying something.
- The **hinge side** decides which hand: the hand nearest the handle side.


### 6.11 Hands and grips
1. **Twist lives in the forearm, not the wrist.** The radius rolls round the ulna along the whole forearm. Twisting only
   the hand bone gives the "candy wrapper" wrist. Spread the twist over the forearm (twist bones, or 50/50 between
   the forearm and the hand).
2. **The shoulder blade moves** (2.2). Hanging from a ledge the shoulders **shrug up toward the ears**; reaching for a
   ledge the shoulder comes forward. A figure that hangs with the shoulders level looks dead.
3. **Fingers are never straight at rest**: softly curled, more toward the pinky (index ~15-20°, pinky ~40-50° at the
   knuckle), the thumb relaxed beside the index.
4. **Square edge**: a **hook grip** (knuckles straight-ish, middle and end joints bent over the edge, palm flat on top,
   thumb alongside the index, not under). **Round rail or pipe**: a **full wrap** (all three joints bent, the thumb round
   the other side). **Pushing down on a top** (vault, press): an **open palm**, fingers forward and spread, wrist
   extended 60-90°, the heel of the hand carrying the weight.

### 6.12 Hard rules for every traversal move
- **Contact first, then the push.** The CoM gains height only while a hand or foot is pushing on something (or in a
  jump's ballistic arc). Rising with no contact is the "lifted on a string" look. **HARD**.
- **Limbs don't stretch.** Bone lengths are constant (±0.5 mm). Shoulder to a gripping palm ≤ arm length (~0.60 m),
  hip to a planted ankle ≤ the rig's own thigh + shin length (measured on the skeleton, about 0.82-0.85 m). If the target is further, the body moves or the hand /
  foot lets go. **HARD**.
- **Gripping hands and planted feet stay put**: < 1 cm of slide on the surface while in contact. **HARD**.
- **The body stays out of the world**: the segment capsules of 2.4 never sink more than 1 cm into geometry on mask
  1|4|8 (palms and soles may touch). The head never passes through anything. **HARD**.
- **Never on debris**: no probe, foot or hand uses layer 7 (64) (the world contract). **HARD**.
- **Square to the edge**: at hand contact on a climb or mantle, the body faces the edge within 15°. TYPICAL; HARD 30°.
- **Not faster than a body**: a 0.8 m mantle takes ≥ 0.9 s, a 1.8 m climb ≥ 1.4 s, a pull-up ≥ 0.6 s. Quicker looks
  lifted. TYPICAL minimums.
- **Landings in order**: toes/ball, then heel, then the ankle bends, the knee, the hip, each starting 20-40 ms after the
  one before. Peak knee bend grows with the drop: ~30-50° for 0.5 m, 60-90° for 1-2 m, 90-110° (and hands down) for
  2-3 m.
- **Clip warping** stays within ±20 % of the clip's own distance or height in each window, and adds ≤ 15° of turn.

---

## Part 7 - Perception: what a viewer notices first

- **Foot sliding is seen from under ~2 cm** (Pražák, Hoyet and O'Sullivan 2011: participants perceived even very low
  footskate, under 21 mm in most conditions). Hence the target of 0.5 cm and the HARD limit of 1 cm per contact. The same
  study found viewers preferred a fix that **slightly lengthened the limbs** to one using IK and smoothing: smoothing
  artefacts are seen more readily than a tiny length change. (We keep bones rigid, 6.12, but it shows how visible
  smoothing is.)
- **A moving camera hides slips** (the threshold rises with camera motion). Judge with a **still camera**, side-on and
  front-on, never only from the chase camera.
- **In the air, horizontal errors are seen before vertical ones, and added speed before lost speed** (Reitsma and
  Pollard 2003). The more human the character looks, the more sensitive viewers are (Reitsma, Andrews and Pollard
  2008). A realistic body raises the bar.
- **People read movement from the joints alone.** A dozen moving dots on the joints are enough to recognise a walking
  person, their weight and mood (Johansson's point-light studies, 1973). So a perfect mesh can't hide wrong joint timing.
- **The order in which things look wrong** (practical ranking from animation work, for triage):
  1. impossible joints (a knee backward, a rolled ankle, a twisted neck);
  2. ground contact (sliding, sinking, hovering, a foot spinning flat);
  3. balance (a lean that doesn't match the motion, a body standing outside its feet);
  4. pops and shaking;
  5. timing (cadence that doesn't match speed, arms in the wrong phase, too-quick climbs);
  6. lifelessness (no head lead, a rigid pelvis, straight fingers, a frozen idle).
- **On the phone the character is small**: the silhouette, the lean, the feet on the ground and the head carry the
  look; fingers matter less. The phone also runs at 30-60 fps, so a pop lasts longer on screen.
- **Weight** is read from the bounce, the depth of landings and how many steps a stop takes. A runner that stops in one
  step looks weightless (3.4).

---

## Part 8 - The failure catalogue

Every look-wrong seen in the attempts so far, and the usual others. "Check" is the measurement that catches it (all on
the final pose); a fix that doesn't make that check pass is not a fix.

| # | What it looks like | Usual cause | Check | Fix |
|---|---|---|---|---|
| 1 | **Knee bends backward** | IK pole taken from the foot, the velocity or the target; a target past reach flips the pole; blending poses through a 180° quaternion path | 1.3 signed knee < −5 | pole from the thigh / pelvis frame (10.3); soft reach; the final limiter (10.2) |
| 2 | Knee snaps straight then bends (IK pop at full reach) | target at or past the leg's length | discontinuity (1.8); reach > 99.9 % | soft reach above 99 % (10.3), lower the pelvis instead |
| 3 | Knees knock in or bow out | pole off to the side; foot yawed | varus ±8; hip rotation; knee over the toes (2.4) | pole over the second toe, foot yaw limited |
| 4 | **Ankle looks broken** (foot rolled onto its edge, twisted) | foot oriented to a ground normal with no limit (a kerb edge returns a 45° normal); a clip's foot unclamped | 1.4 inversion / eversion / twist; sole vs ground | average the normal under heel and ball; limit the foot against the shin on all three axes |
| 5 | Foot pointing sideways or back | foot yaw from the velocity during a pivot | foot twist (2.1) | foot yaw from the body, limited; pivot on the ball |
| 6 | Heel or toes through the floor or a step | ankle limit dropping the heel; foot IK on one point only | contact points > 1 cm below the surface | lift the heel about the ball; IK on heel and ball |
| 7 | Foot hovering while "planted" | contact by the bone, not the sole | contact points > 1 cm above | contact on heel / ball / toe points (1.7) |
| 8 | **Feet slide** | clip speed ≠ body speed; blends out of phase | slide per contact > 1 cm | play rate ±20 %, stride warping, phase-synced blends, foot lock |
| 9 | Moonwalk / treadmill (steps don't match travel) | cadence and step length not from the speed | cadence and step length vs 4.1 / 4.3 ±15 % | drive cadence from speed |
| 10 | Ice-skating turns (body turns, feet spin flat) | capsule rotates while the feet stay in their pose | foot yaw while flat > 5° | turn by steps; pivot on the ball |
| 11 | **Over-lean (the 70° runner)** | controller curves too tight for the speed; layers each add lean | whole-body lean > atan(μ); trunk lean; lean vs atan(a/g) | limit the turn rate (3.3), cuts on plants, one lean source, final limiter |
| 12 | Lean with no reason, or the wrong way | lean from the stick, not from the acceleration | lean vs acceleration (3.2: per frame ±8°, per step ±5°) | lean from the measured acceleration |
| 13 | Folding at the waist instead of leaning from the feet | lean applied to the spine | trunk bend vs whole-body lean | lean the whole body about the support point |
| 14 | Hips pop or snap down | a cut between poses; ground snap | 3.6 accelerations; down > g | inertialization; ground following within g |
| 15 | Shaking, jitter | IK targets fighting; springs not frame-rate safe | acceleration sign changes per step; frame-rate test (9.3) | one owner per bone; dt-correct springs |
| 16 | Floaty or rocket jumps | gravity scaled; air control | flight parabola (3.5) | real g; no air acceleration |
| 17 | Lifted on a string (climb) | root tweened separately from the limbs | CoM rises without contact (6.12) | root from the clip, warped; contacts drive the rise |
| 18 | Stretchy arms or legs | IK with no reach limit; scale tracks | bone lengths; reach | let go or move the body |
| 19 | Walk with a flight phase, run with both feet down | wrong clip for the speed; blend between them | 4.1 / 4.3 | gait switch at 2.0-2.2 m/s with a transition |
| 20 | Hands through the body; arms across the centre | IK on the arms, bad clips | capsules (2.4) | limit the shoulder's horizontal adduction |
| 21 | Same arm and leg forward | mirrored clip, phase offset | shoulder against same-side hip in phase for > 20 % of the stride | arms from the leg phase |
| 22 | Candy-wrapper wrist | twist only on the hand bone | forearm twist share (6.11) | spread the twist |
| 23 | Head bobs, snaps, or turns after the body | no head stabilisation; look-at too fast | head roll, pitch range; neck speed; head lead (4.6) | head stabilised, leads by ~0.2 s |
| 24 | Spine S-curve, broken neck | each spine bone given the full bend | spine and neck limits per segment | share the bend (lumbar 30 %, thoracic 70 % of twist; flexion spread) |
| 25 | Robotic walk | rigid pelvis, no counter-turn of the chest | pelvis and thorax ranges below the typical minimum | pelvis turn ±4-5°, drop ±4-5°, chest counter ±3-7° |
| 26 | Dead hands | fingers straight | finger angles | resting curl (6.11) |
| 27 | Stop or start on the wrong foot | clip by time, not by foot phase | slide at the transition | choose by the foot that is next |
| 28 | Glide pivot (a run turned in place) | heading changed with no plant | heading change without a contact (3.3) | brake, plant, pivot |
| 29 | Foot on a stair's nosing | step length not warped to the treads | 5.2 | warp the last steps |
| 30 | Hips and arms on different rhythms in a climb | root and limbs from different sources | contact timing vs CoM rise | root motion from the same clip |
| 31 | Hanging with level shoulders | no shoulder-blade motion | blade vs arm elevation (2.2) | scapulohumeral rhythm |
| 32 | Looks different at 30 and 144 fps | springs or damping per frame, not per second | 9.3 frame-rate runs | dt-correct maths |
| 33 | Body through walls or cars | probes and pose disagree | capsules vs world (6.12) | probe with the body's real shape |
| 34 | Body snaps round 180° in a frame | facing set, not turned | pelvis yaw speed > 720 °/s | turn through the pivot (4.6) |

---

## Part 9 - Verification: how to know it is right before anyone plays it

### 9.1 The validator
- A C++ node that reads the **final** pose: in Godot 4.4+, a `SkeletonModifier3D` placed **last** in the skeleton's
  modifier stack (after IK, look-at and every layer); it sees exactly what is drawn. With physics interpolation on, it
  also checks the interpolated pose of the drawn frame.
- Every frame it computes everything in Part 1 (signed joint angles on every axis, joint speeds, CoM, the three leans,
  contacts, slide, hover, sink, capsules against each other and the world, bone lengths, accelerations) and tests
  every HARD rule, and every SOFT rule against its allowed states.
- It writes a log line per violation: frame, time, rule id (e.g. `KNEE_FLEX_MIN`), side, value, limit, the
  controller's state, the input, and the random seed. It also counts how often the final limiter (10.2) had to act.
- In a debug build it draws: red joints where a rule broke, the whole-body lean line, the CoM path, the contacts.

### 9.2 Every check must be able to fail (mutation tests)
Before trusting the validator, pose the skeleton directly with known values and check that the right rule fires, with
the right sign, and nothing else fires. Run them with the **final limiter off** (it would hide the pose), for **both
sides**, in the rig's own rest pose **and** in an A-pose and a T-pose variant, at a random root yaw and a random
root tilt, and with random hip rotation added: the result must be the same in every case.

| Pose given | Must fire |
|---|---|
| knee −20 (backward) on a bent standing leg | `KNEE_FLEX_MIN` |
| knee +30 forward | nothing |
| knee +40 forward, but the whole thigh rotated 120° inward (the knee visibly bending backward) | `HIP_ROTATION` |
| shin 15° out of the hinge plane | `KNEE_VARUS` |
| foot rolled 40° onto its outer edge | `ANKLE_INVERSION` |
| foot planted on flat ground, rolled 20° (2 sole points down) | `SOLE_ROLL` |
| a foot sunk 3 cm into the ground | `CONTACT_SINK` |
| foot twisted 60° out | `FOOT_TWIST` |
| ankle 30° up with a straight knee | `ANKLE_DORSI` |
| ankle 30° up with the knee at 45° | nothing |
| hip 110° forward with a straight knee | `HIP_FLEX_COUPLED` |
| whole body leaning 50° with no acceleration | `LEAN_MAX` and `LEAN_MISMATCH` |
| trunk folded 60° forward at the waist, hips pushed back so the CoM stays over the feet | `TRUNK_LEAN` and `TRUNK_BEND` |
| a knee snapped 40° in one frame at 30 fps | `POSE_DISCONTINUITY` |
| the skeleton node itself tilted 40° (lean put on the node) | `LEAN_MAX` (world space, 1.0) |
| hips dropped 5 cm in one frame | `COM_DOWN_GT_G` |
| planted foot moved 3 cm | `FOOT_SLIDE` |
| hand inside the chest | `SELF_INTERSECT` |
| both feet down in the middle of a run | `RUN_DOUBLE_SUPPORT` |
| rest pose; a clean reference walk | nothing at all |

Each joint axis is also checked: rest pose reads 0; +30 the anatomical way reads +30; −10 reads −10, where "the
anatomical way" is defined by geometry (1.3: the ankle behind the hip-knee line), not by the code's own axis. And on a
clean reference clip, every frame reads inside the TYPICAL ranges (no false alarms).

**The limiter has its own tests**: each broken pose above goes in, a pose inside the HARD limits comes out, the
limiter's counter goes up by one, and the contacts that were fine stay where they were.

These tests run first, every time; if one fails, no other result counts.

### 9.3 Free play, not only scripts (the input fuzzer)
Scripted moves find scripted bugs. Bots play for a long time with seeded random input:
- a stick that changes direction and amount at random, 2-10 times a second;
- full reversals at full run, every 0.5-3 s;
- the stick turning in circles at every rate; flicks of 50-150 ms; run on / off spam; stop-go spam;
- camera spins (up to 720°/s) while running;
- running diagonally into walls, cars, kerbs, stairs and slopes at 0-60° to them;
- frame rates of 20, 30, 60 and 144, and random hitches (a single 100-250 ms frame);
- wet and slippery ground (lower μ).
At least 30 minutes of simulated play per bot per build. Any HARD violation must reproduce from its seed. Also record
real play (Yasin's input) and replay it through the validator.

The validator checks **both** the pose **before** the final limiter and the pose after it, and logs both.

**Pass**: 0 HARD violations after the limiter; **before** the limiter, 0 violations of the knee, ankle, sole, hip
rotation and lean rules beyond 1° (the limiter may only shave rounding, never repair a broken pose: a clamped frame is a
pop the player sees); other joints clamped on under 0.01 % of frames; SOFT only in their states; frame-rate runs agree
(same input, same pose within 1°/1 cm whatever the frame rate).

### 9.4 Look at it (the visual check)
For every move (walk, run, start, stop, each turn, each obstacle):
- Render **contact sheets** with a fixed orthographic camera from the **side** and the **front** (and from above for
  turns): 10-12 frames per stride or per move, plus a quarter-speed video. Draw the whole-body lean line, the CoM path
  and the contact points on them.
- Put **real reference footage of the same move at the same speed** beside it, scaled to the same leg length.
- The builder **looks at the images and writes what it sees** against each row of Part 8 before calling anything done.
- Also look through the game's chase camera at phone resolution, still and moving.

### 9.5 Reference footage
- Best: film real people with a phone, side-on, tripod, 60-240 fps, with distance markers on the ground: walks at
  0.8-1.9 m/s, runs at 2.5-6, starts, stops, cuts, reversals, stairs up and down, kerbs, vaults, climbs, drops.
- Public motion-capture sets are useful to **read numbers from**, not to ship: CMU Graphics Lab, LAFAN1 (Ubisoft,
  CC BY-NC-ND: no commercial use), AMASS (research licence). Check each licence before anything goes into the game.

### 9.6 Order of acceptance
1. Mutation tests (9.2) pass.
2. Free play (9.3): 0 HARD violations.
3. TYPICAL statistics within ±15 % of Part 4's tables (cadence, step length, bounce, contact time, joint peaks).
4. Visual check (9.4) written up, with the contact sheets attached.
5. Only then does Yasin play it. The report says what the checks **can't** see.

---

## Part 10 - Building it so it can't break

### 10.1 The pose pipeline, in order (each stage owns its bones; nothing after the limiter changes the pose)
1. **Controller** (the capsule's path): speed, acceleration and turn rate limited by Part 3 (3.3 turn rate by lean and
   grip; cuts on foot plants; stops over 2+ contacts). The controller is the first place a 70° lean is prevented.
2. **Base motion**: clips (layered) or a gait generator (procedural), chosen by speed and **foot phase**.
3. **Warping**: playback rate within ±20 %, then stride warping (scale the feet's reach, keep the cycle time), then
   orientation warping of the legs within ±45°. Beyond those: switch to another clip or a turn move.
4. **Whole-body lean**: **one** source, from the measured acceleration (3.2), rotating the body about the support point.
   If the clip already leans, measure its own lean at its own speed and add only the difference.
5. **Flight correction**: with no contact, move the root so the computed CoM follows the parabola set at take-off
   (3.5); the limbs keep their motion.
6. **Pelvis height and leg IK**: feet onto the ground (heel and balls), the pelvis lowered to the lower foot, soft reach
   and the knee pole from the pelvis (10.3).
7. **Upper body**: spine share, head look-at that leads (4.6) and stabilises, arms from the leg phase, hand IK.
8. **Final limiter** (10.2).
9. **Validator** (9.1), read-only, on the poses before and after the limiter.

### 10.2 The final limiter
A `SkeletonModifier3D` just before the validator. For every joint, on the final pose, using Part 1's frames:
- **Knee and elbow**: project the lower bone onto the hinge plane (removes varus beyond ±8), clamp the signed flexion to
  [−5, 155] (elbow [−10, 150]), clamp the twist by the flexion-dependent limit. Same function and limit shapes as the
  validator (1.5).
- **Ankle**: clamp dorsiflexion by the knee-dependent limit, plantarflexion, inversion, eversion and foot twist; if a
  foot in contact was moved, lift the heel about the ball (never push the foot into the ground).
- **Hip, shoulder**: swing-twist with a cone for the swing (ellipse: different limits forward / back / side) and a range
  for the twist; the hip's flexion limit depends on the knee (2.2).
- **Spine and neck**: per segment, three axes.
- **Trunk lean**: if it exceeds 3.2's hard limit for the state, rotate the whole body back about the support point
  (not the spine alone). The step-averaged lean limits are the controller's job (10.1 step 1); a per-frame limiter
  can't fix a path that needs too much lean.
- Every clamp is **counted** by the validator, and the pose before the clamp is logged. The limiter is a safety net
  for the shipped game, not a fix: in testing it must have nothing to do (9.3).

### 10.3 The knee pole (the cause of the backward knee)
- The knee bends in the plane spanned by the hip→ankle line and a **pole direction built from the pelvis**: the
  pelvis's forward, turned about the hip→ankle line by the hip rotation the **base motion** asked for (the clip's or the
  gait generator's hip rotation, before any IK), clamped to ±15°. Never from the IK's own result (that would be
  circular: the hip rotation is what the pole produces).
- The foot's direction may pull the pole by at most 15° more (knee over the toes), only while the foot is in contact,
  so the total stays within the hip rotation limits.
- After the solve, the hip rotation (1.5) is measured: a thigh twisted to put the knee behind is `HIP_ROTATION`.
- **Never** from the velocity, the stick, the IK target or the foot alone. Never flip the pole when the hip→ankle line
  passes near the pole direction: keep the previous plane (hysteresis).
- **Soft reach**: with thigh and shin about equal, reach = cos(knee/2), so 97 % of the leg already means a 28° knee
  (a crouched walk) and 99.9 % is 3°. So the reach is left alone up to 99 % and only then eased smoothly toward 99.9 %
  (knee ≥ ~3°), never reaching 100 %. A target past that: the pelvis drops or the foot lifts; the knee never passes
  straight. Walking heel strike (+3°) and running touchdown (+15-20°) must stay reachable.

### 10.4 Foot orientation
- Ground normal from **two rays** (under the heel and under the ball), averaged; ignore a normal more than 30° from up
  (a kerb's edge or a step's riser) and use the tread's.
- Pitch and roll follow that normal within the ankle's limits; yaw follows the body's facing within the foot twist
  limit, plus a toe-out of 5-10°.

### 10.5 Smoothing and blending
- Springs and dampers **per second, not per frame**: the exact critically damped spring, or `1 − exp(−dt/τ)`. Never
  `lerp(a, b, 0.2)` each frame (it changes with frame rate: 9.3 catches it).
- **Inertialization** for every switch (keep the old pose's velocity and decay the difference over ~0.15-0.25 s), not
  crossfades of incompatible poses.
- Quaternions: before blending, flip one if `dot(a, b) < 0` (shortest path). A blend that takes the long way round
  turns a joint through 270° on screen, a classic source of backward knees in blends.

### 10.6 Feet sliding (from version 1, still true)
- **Know each clip's own speed** (measure the planted foot over a cycle) and play it so the clip speed equals the body
  speed: within ±20 % change the playback rate; beyond that stride-warp or blend to the next clip.
- **Blend only clips of matching phase**: mark each clip's foot contacts and sync by phase, not time.
- **Foot lock**: pin the planted foot from contact to lift-off. It hides small errors only; it can't hide a 30 % speed
  mismatch, and a locked foot under a body that moves on stretches the leg (6.12).

### 10.7 Traversal clips that don't fit the obstacle (motion warping, from version 1)
1. **Mark contacts in each clip**: the frame each hand and foot touches the top, the frame they let go, and where the
   top's edge is in the clip's space (its height and distance).
2. **Measure the world**: the edge's position, height, depth and facing (rays forward at knee, waist, chest, head; down
   from above for the top and its depth; from beyond the far side for the landing). Probes use mask 1|4|8.
3. **Pick the clip whose height is nearest** (keep clips for ~0.5, 1.0, 1.5, 2.0 m) and **warp only within windows**:
   start → hand contact (move and scale the root so the hands arrive at the edge); hand contact → foot contact (scale
   the rise to the real height); after that unwarped. Each scale within ±20 %.
4. **IK last**: hands pinned on the edge, feet on the top, only while the clip says they are in contact (a weight curve
   per limb, faded in and out over 0.1 s).
5. **The root comes from the clip**, warped, never a separate tween (8, row 30).

### 10.8 The approach
- Detect obstacles **1.5-3 m ahead** (more when running), not on contact.
- Shorten or stretch the **last 2 steps** (±15 %) so the takeoff foot lands at the right distance (vault 0.8-1.2 m,
  climb 0.4-0.6 m, kerb: no foot on the edge).
- Turn the body square to the edge over the last step.

### 10.9 Life on top of the base motion
- **Head**: toward the move direction ~0.2 s before turning; at the edge before a climb; down before a drop or stairs
  down; at a person being talked to.
- **Pelvis** follows the lower foot on uneven ground; turns and drops with the steps (4.2).
- **Arms** out on narrow ground, a hand to the wall at tight fast corners, a hand toward a door as it nears.
- **Idle**: the weight moves from foot to foot every 4-8 s; breathing moves the chest 1-2 mm.

---

## Part 11 - Thresholds in one table

### 11.1 Choosing the move (by what the probes measure)
| Situation | Move |
|---|---|
| up < 3 cm | foot IK only |
| up 3-20 cm | step up inside the walk (5.3) |
| up 20-45 cm | obvious big step up; thin: step over |
| up 0.45-1.2 m, top ≥ 25 cm deep, room to stand | mantle (both hands, knee up) |
| over 0.5-1.1 m, thin, walking | step vault (hand and foot on top) |
| over 0.8-1.2 m, thin, running | speed vault (one hand) |
| over 0.8-1.0 m, deep (car bonnet) | slide-over |
| over 1.2-1.5 m, thin | climb over (both hands, a foot on top, swing, drop) |
| up 1.2-2.5 m, room to stand | jump, hang or catch, pull, press, stand |
| up > 2.5 m | nothing (unless a pipe or ladder is marked) |
| down < 0.5 m | step down in stride |
| down 0.5-1.0 m | hop down |
| down 1.0-2.0 m | jump down, deep landing; at an edge with no speed: hang-drop |
| down 2.0-3.0 m | hang-drop, or a roll when moving fast |
| down > 3.5 m | hurt |
| ground 10-30 cm wide | balance walk |
| round, < 10 cm | slow balance walk or shuffle |
| headroom < 1.3 m | crouch |
| wall 0.8-1.2 m beside, crouched | low cover |
| door within 1.5 m ahead | slow, reach, push through or pull and step round |

### 11.2 The HARD limits (all on the final pose; zero frames; every HARD row of 2.1 applies)
Signs and frames as in Part 1; times in ms; everything measured in world space (1.0).

| Rule (validator id) | Limit | Part |
|---|---|---|
| knee flexion, signed (`KNEE_FLEX_MIN/MAX`) | −5 to 155° | 2.1, 1.3 |
| knee out of its hinge plane (`KNEE_VARUS`) | ±8° | 2.1 |
| knee twist (`KNEE_TWIST`) | ±5° when straight, ±25° past 60° of bend | 2.1 |
| ankle up (`ANKLE_DORSI`) | 25° (knee < 15°) to 40° (knee > 30°) | 2.1-2.2 |
| ankle down (`ANKLE_PLANTAR`) | 55° | 2.1 |
| ankle inversion / eversion (`ANKLE_INVERSION`, `ANKLE_EVERSION`) | 30° / 15°, signed by side | 2.1, 1.4 |
| foot twist against the shin (`FOOT_TWIST`) | 30° out, 20° in | 2.1 |
| sole against the ground, 2+ points down (`SOLE_ROLL`) | 5° | 2.1, 1.4 |
| toe joint (`TOE_BEND`) | 80° up | 2.1 |
| hip flexion (`HIP_FLEX_COUPLED`) | 90° with the knee under 20°, 125° with it past 60° | 2.2 |
| hip extension (`HIP_EXT`) | 30° | 2.1 |
| hip abduction / adduction (`HIP_ABD`) | 45° out, 30° in | 2.1 |
| hip rotation (`HIP_ROTATION`) | 40° in, 50° out | 2.1, 1.5 |
| lumbar (`SPINE_LUMBAR`) | forward 50, back 25, side 25, twist 10° | 2.1 |
| thoracic (`SPINE_THORACIC`) | forward 30, back 20, twist 35° | 2.1 |
| neck (`NECK`) | forward 50, back 60, turn 80, side 45° | 2.1 |
| shoulder (`SHOULDER_CONE`, `SHOULDER_TWIST`) | elevation 180° front and side, 60° behind; across the body 40°; twist 70° in, 90° out | 2.1 |
| elbow (`ELBOW`) | −10 to 150° | 2.1 |
| forearm (`FOREARM_TWIST`) | 85° each way | 2.1 |
| wrist (`WRIST`) | flexion 80, extension 90, radial 20, ulnar 35° | 2.1 |
| fingers (`FINGERS`) | never past −5°; 90 / 110 / 90° | 2.1 |
| joint speeds (`JOINT_SPEED`) | knee 1500, hip 1000, ankle 1200, shoulder 1200, elbow 1500, spine 300, neck 500 °/s | 2.3 |
| pose discontinuity (`POSE_DISCONTINUITY`) | 3° off a joint's smooth ±40 ms fit; 0.5 cm for the CoM | 1.8 |
| knee over the toes, foot in contact, knee bent > 20° (`KNEE_OVER_TOE`) | 35° | 2.4 |
| whole-body lean, per frame, a foot in contact (`LEAN_MISMATCH`) | within 10° of atan(a_h / (g + a_v)) | 3.2 |
| whole-body lean, averaged per step (`LEAN_MAX`, `LEAN_MISMATCH`) | ≤ atan(μ) (35° dry); within 5° of atan(a_mean / g) | 3.2 |
| trunk lean in walking and running (`TRUNK_LEAN`) | forward 30°, back 15°, sideways 25° | 3.2 |
| trunk bend (`TRUNK_BEND`) | 15° beyond the step-averaged whole-body lean | 3.2 |
| head (`HEAD_LEVEL`) | roll 5° on the straight, ≤ half the trunk's lean in turns; pitch change 5° per stride | 2.4 |
| path curvature (`TURN_RATE`) | sustained: the 20° lean column (3.3); 30° only for 1-2 steps of a cut | 3.3 |
| change of direction per plant (`CUT_ANGLE`) | 3.3's table | 3.3 |
| stopping a run (`STOP_STEPS`) | ≥ 2 foot contacts | 3.4 |
| CoM down faster than g (`COM_DOWN_GT_G`) | never (+1 m/s²) | 3.5 |
| CoM in flight (`FLIGHT_PARABOLA`) | within 1 cm of the take-off parabola; horizontal acceleration ≤ 1 m/s² | 3.5 |
| CoM horizontal acceleration in contact (`COM_ACCEL_H`) | μ·g + 1 m/s² | 3.6 |
| CoM vertical acceleration (`COM_ACCEL_V`) | 30 m/s² above g; landings 80 for ≤ 100 ms | 3.6 |
| foot or hand slide in contact (`FOOT_SLIDE`, `HAND_SLIDE`) | 1 cm per contact | 6.12, 7 |
| contact points into the ground (`CONTACT_SINK`) | 1 cm | 1.7 |
| planted foot hovering (`CONTACT_HOVER`) | 1 cm | 1.7 |
| foot spinning flat (`FOOT_SPIN`) | 5° | 4.6 |
| walk: a foot always down (`WALK_FLIGHT`); run above 2.5 m/s on the level: never both down > 20 ms (`RUN_DOUBLE_SUPPORT`) | | 4.1, 4.3 |
| bone lengths (`BONE_LENGTH`) | ±0.5 mm | 6.12 |
| limbs through the body (`SELF_INTERSECT`) or the world (`WORLD_INTERSECT`) | 1 cm | 2.4, 6.12 |
| rising with no contact in a climb (`RISE_NO_CONTACT`) | never | 6.12 |
| pelvis yaw speed (`PELVIS_YAW_SPEED`) | 720 °/s | 8 |
| final limiter acting before-limiter on knee, ankle, sole, hip rotation, lean (`LIMITER_ACTED`) | never beyond 1° in testing | 9.3 |

### 11.3 TYPICAL targets (looked at, compared to footage, ±15 %)
Walk 1.3 m/s: 108 steps/min, 0.72 m steps, bounce 4-5 cm, knee peak 60-65°, toe clearance 1-2 cm. Run 4.6 m/s: 170
steps/min, 1.62 m steps, contact 0.21 s, flight 0.14 s, bounce 7-8 cm, stance knee 40-45°, swing knee 90-105°, trunk
5-12° forward. Head leads turns by ~0.2 s. Foot slide target 0.5 cm.

---
## Part 12 - Mixamo files

Mixamo (Adobe, free) auto-rigs an uploaded mesh and retargets a library of mocap clips onto it. Its skeleton has
become a de-facto standard: thousands of clips and asset-store characters use it.

### 12.1 The skeleton

About 65 bones with the fingers, **no root bone: `Hips` is the top**. Names carry a prefix: `mixamorig:` normally,
`mixamorig1:`, `mixamorig2:` ... when the same account rigged several characters (a common cause of "the clip does not
play on my character": the prefix differs). Godot cannot keep `:` in a bone path, so on import the names appear as
`mixamorig_Hips` etc.

```
Hips
├─ Spine ─ Spine1 ─ Spine2
│                     ├─ Neck ─ Head ─ HeadTop_End          (LeftEye / RightEye on some characters)
│                     ├─ LeftShoulder ─ LeftArm ─ LeftForeArm ─ LeftHand
│                     │      └─ LeftHandThumb1-4, LeftHandIndex1-4, LeftHandMiddle1-4, LeftHandRing1-4, LeftHandPinky1-4
│                     └─ RightShoulder ─ ... (mirror)
├─ LeftUpLeg ─ LeftLeg ─ LeftFoot ─ LeftToeBase ─ LeftToe_End
└─ RightUpLeg ─ ... (mirror)
```

Things it does **not** have: twist bones (forearm, upper arm, thigh), IK helper bones (hand / foot IK targets, a
ground-level root), a jaw, prop bones. The forearm twist (6.11 rule 1) has to be made by the engine (Godot 4.6
`BoneTwistDisperser3D`, 6.4) or by careful skin weights.

### 12.2 The files

- **FBX**, binary, **1 unit = 1 cm** (the file carries a 0.01 scale). After import check that the hips are at ~1 m,
  not 100 m, and that the scale was applied to position tracks too.
- **Rest pose: T-pose** (arms straight out sideways). Y is up, the character faces +Z. Each bone's local Y points
  along the bone toward its child.
- Download options: **With Skin** (mesh + skeleton + clip) or **Without Skin** (skeleton + clip only: use it for
  every clip after the first); **Frames per second** (24 / 30 / 60; 30 by default); **Keyframe reduction** (none /
  uniform / non-uniform: use none, reduction causes foot slide); **In Place** (for moving clips: removes the hips'
  horizontal travel, keeps the bob).
- Per-clip sliders on the site: **Character Arm-Space** (pushes the arms away from the body so they do not go through
  a bulky mesh), **Overdrive** (speed), **Trim**, **Mirror**, and clip-specific ones (stride, height, energy).

### 12.3 Root motion and Mixamo

Because there is no root bone, **the travel is on `Hips`**. For root motion you make a root yourself:
1. Export **without In Place**.
2. Add a `Root` bone on the ground under the hips (in Blender; Godot's humanoid profile has a `Root`).
3. Move each frame's horizontal hips travel and heading (yaw) to `Root`; leave the hips' up-down bob, tilt and sway on
   `Hips`.

In Place clips have no travel, so the game must guess the speed: that is where foot slide comes from. With In Place,
measure the clip's real speed (a planted foot's travel per cycle) and store it with the clip.

### 12.4 Known quirks

- Mocap clips are cleaned, but many still **slide slightly**, and many have **feet a few cm into or above the floor**
  (the auto-rig places the ankle by guesswork). Foot IK and foot lock cover this.
- The auto-rig guesses the knees, elbows and chin from the mesh; on stylised meshes the knees can point a little in.
- Retargeting between different proportions changes the stride: a walk put on shorter legs takes the same steps with
  shorter legs and slides. Root motion must be **scaled by the leg-length ratio** (Godot's "Normalize Position
  Tracks", 6.3).
- Many clips start and end on different feet or poses and do not loop cleanly: check the loop seam.

### 12.5 The names side by side (Mixamo, Godot's humanoid profile, 3ds Max Biped)

The player's figure uses **3ds Max Biped** names (`Bip01_*`, as in `native/src/hand_grip.cpp`). The three standards:

| Mixamo | Godot `SkeletonProfileHumanoid` | 3ds Max Biped |
|---|---|---|
| (none) | `Root` | `Bip01` (the root, on the ground) |
| `Hips` | `Hips` | `Bip01_Pelvis` |
| `Spine`, `Spine1`, `Spine2` | `Spine`, `Chest`, `UpperChest` | `Bip01_Spine`, `Bip01_Spine1`, `Bip01_Spine2` |
| `Neck`, `Head` | `Neck`, `Head` | `Bip01_Neck`, `Bip01_Head` |
| `LeftShoulder` | `LeftShoulder` | `Bip01_L_Clavicle` |
| `LeftArm` | `LeftUpperArm` | `Bip01_L_UpperArm` |
| `LeftForeArm` | `LeftLowerArm` | `Bip01_L_Forearm` |
| `LeftHand` | `LeftHand` | `Bip01_L_Hand` |
| `LeftHandThumb1-3` | `LeftThumbMetacarpal`, `-Proximal`, `-Distal` | `Bip01_L_Finger0`, `Finger01`, `Finger02` |
| `LeftHandIndex1-3` | `LeftIndexProximal`, `-Intermediate`, `-Distal` | `Bip01_L_Finger1`, `Finger11`, `Finger12` |
| `LeftHandMiddle1-3` | `LeftMiddleProximal` ... | `Bip01_L_Finger2`, `Finger21`, `Finger22` |
| `LeftHandRing1-3` / `LeftHandPinky1-3` | `LeftRing...` / `LeftLittle...` | `Finger3x` / `Finger4x` |
| `LeftUpLeg` | `LeftUpperLeg` | `Bip01_L_Thigh` |
| `LeftLeg` | `LeftLowerLeg` | `Bip01_L_Calf` |
| `LeftFoot` | `LeftFoot` | `Bip01_L_Foot` |
| `LeftToeBase` | `LeftToes` | `Bip01_L_Toe0` |

Two Biped traps: in a default Biped the **clavicles hang from the neck**, and the **thighs hang from the first spine
bone, not the pelvis**. Rotating `Bip01_Pelvis` then does not carry the legs, and code written for Mixamo (legs under
the hips) moves the wrong bones. Check the player's hierarchy before writing any pelvis tilt or hips IK.

---

## Part 13 - Godot's skeleton system (4.4-4.6)

### 13.1 The pieces

| Node / resource | What it is |
|---|---|
| `Skeleton3D` | the bones: each has a **rest** (bind pose) and a **pose** (position, rotation, scale, local to its parent). `get_bone_pose*` is local; `get_bone_global_pose` is in the skeleton's space (times the node's `global_transform` for world). |
| `Skin` / `MeshInstance3D.skin` | binds the mesh to the bones |
| `BoneAttachment3D` | a node that follows (or drives) one bone: a prop in the hand, a camera on the head |
| `AnimationMixer` (base of `AnimationPlayer`, `AnimationTree`) | plays clips onto the skeleton |
| `AnimationTree` | the blend graph: `AnimationNodeStateMachine`, `BlendSpace1D` / `2D`, `BlendTree` with `OneShot`, `Transition`, `TimeScale`, `TimeSeek`, `Add2`, `Blend2` |
| `SkeletonModifier3D` (4.4+) | a child of `Skeleton3D` that changes the pose **after the animation**: IK, look-at, springs, constraints, ragdoll. Hand and foot IK are these. |
| `PhysicalBoneSimulator3D` + `PhysicalBone3D` | ragdoll: bones driven by physics bodies, blended by `influence` |

### 13.2 One frame, in order

1. The `AnimationMixer` advances and writes the clips' blended pose. Its `callback_mode_process` is **physics, idle or
   manual**. For a `CharacterBody3D` moved in `_physics_process`, use physics (or manual, calling `advance(delta)` right
   after moving the body) so the clip and the body move on the same tick.
2. **Root motion**: with the mixer's `root_motion_track` set (e.g. `%GeneralSkeleton:Root`), that bone's movement is
   **not** applied to the bone; it is handed over each tick (`get_root_motion_position()`,
   `get_root_motion_rotation()`, and accumulators). You move the body by it (velocity = the rotated root delta / delta,
   then `move_and_slide()`). Blended clips blend their root motion too.
3. The skeleton's **modifiers** run one after another (in their order as children; each sees the pose the one before
   left), each blended in by its `influence`. A modifier overrides `_process_modification_with_delta(delta)` and
   applies its full result (the skeleton applies the influence; `delta` may be 0 just after init). The signal
   `modification_processed` fires when one finishes: the moment to read the final pose.
4. Skinning: the mesh is drawn.

So a sensible modifier order for the player: foot plant / pelvis (legs and hips) → hand grip (arms; needs the hips
final) → look-at (head; needs the chest final) → twist disperser and angular-velocity limit last.

### 13.3 Importing and retargeting

- Import dock, **Retarget > Bone Map**: create a `BoneMap` with `SkeletonProfileHumanoid`. Godot auto-maps common English
  bone names (Mixamo maps by itself; Biped mostly, check the fingers and clavicles).
- **Rename Bones** renames the skeleton to the profile's names (`Hips`, `LeftUpperLeg` ...). After that, **every clip
  imported the same way plays on every character imported the same way**.
- **Rest Fixer** makes the rests match Godot's reference: T-pose, facing +Z, Y up, +Y from a joint to its child, +X
  rotation bends like the muscle contracting.
  - **Overwrite Axis**: rewrites every bone's axes to that convention. The page calls it the most important option for
    sharing clips; it breaks anything that relied on the original rest (bone rotations written in code).
  - **Fix Silhouette**: turns an A-pose model into a T-pose rest (a filter for bones to leave; a height adjustment for
    bent knees).
  - **Normalize Position Tracks**: divides position tracks by the hips' height (`motion_scale`), so root motion fits a
    taller or shorter body.
  - **Remove Tracks**: drop position tracks of unimportant bones (mocap has noisy position keys on every bone, which
    stretch limbs on another body); `Root` and `Hips` are kept.
- At runtime (4.4+) `RetargetModifier3D` lets one animated skeleton drive differently shaped bodies.

### 13.4 The modifier family (Godot's "Inverse kinematics returns to Godot 4.6" article and class reference)

| Version | Modifier | Use for the player |
|---|---|---|
| 4.4 | `LookAtModifier3D` | head and eyes leading turns; looking at an edge or a person |
| 4.4 | `RetargetModifier3D` | one clip skeleton for many bodies |
| 4.5 | `SpringBoneSimulator3D` | hair, jacket, bag straps: secondary motion |
| 4.5 | `BoneConstraint3D`: `AimModifier3D`, `CopyTransformModifier3D`, `ConvertTransformModifier3D` | e.g. a twist bone taking part of the hand's roll; in 4.6 it can target any `Node3D` |
| 4.5 | `ModifierBoneTarget3D` | a node that sits on a bone after modification |
| 4.6 | `TwoBoneIK3D` | legs and arms (always deterministic) |
| 4.6 | `ChainIK3D` > `SplineIK3D` (deterministic); `IterateIK3D` > `FABRIK3D`, `CCDIK3D`, `JacobianIK3D` | spines, fingers round a pipe |
| 4.6 | `BoneTwistDisperser3D` | spreads a child's twist up its parents: the forearm twist (6.11 rule 1) |
| 4.6 | `LimitAngularVelocityModifier3D` | caps how fast bones may turn: removes IK pops |

`SkeletonIK3D` (the old node) still exists, deprecated. `IterateIK3D` can carry its state between frames (smooth, but
the pose depends on history) or be deterministic (same input, same pose; with few iterations it may not reach). The
article suggests the angular-velocity limit to calm the jumps deterministic IK can make. A hand-written C++ two-bone
reach is fine too; the 4.6 nodes are the ready-made alternative.

### 13.5 Other Godot pieces that matter for traversal

- **Animation markers** (4.4+): named times inside a clip. Use them for foot contacts (`L_down`, `R_down`), hand
  contacts (`hand_on_edge`) and warp windows (10.7).
- **BlendSpace `sync`**: keeps the clips of a blend space running at zero weight so they stay in step. It syncs by
  time, so the clips need **the same length and the same foot timing** (cut walk and run to one stride each, left foot
  down at 0).
- **Physics interpolation** (3D since 4.4): if physics ticks at 60 Hz and the screen draws at another rate, a body
  moved in physics and a figure posed in idle shake against each other. `project.godot` does not set it.

---

## Part 14 - Jolt physics

### 14.1 What it is

Jolt (by Jorrit Rouwe, open source; used in Horizon Forbidden West and Death Stranding 2) is a multi-core rigid-body
engine. Godot added it in 4.4 and made it the **default for new projects in 4.6**; existing projects keep their setting.

**This project:** `project.godot` sets only `3d/physics_engine.android="Jolt Physics"`. **The phone runs Jolt; the PC
runs the default engine (Godot Physics).** Every climb, kerb and step tested on the PC runs on a different collision
engine from the phone. Margins and contact normals differ (14.3), so a threshold tuned on the PC can behave differently
on the Redmi.

### 14.2 How it works (the parts that matter to a character)

- **Broad phase**: a tree of bounding boxes in layers (Godot maps its collision layers and masks onto it).
- **Narrow phase**: GJK / EPA on **convex shapes with a convex radius**: boxes and cylinders are slightly rounded.
- **Solver**: sequential impulses with position correction (the Baumgarte factor); bodies that stop fall asleep in
  islands.
- **Triangle meshes** (`ConcavePolygonShape3D`: the city's ground and buildings): a moving shape can catch on the inner
  edge between two triangles ("ghost collisions"). Jolt has active-edge detection and an enhanced internal-edge removal
  against it (14.3).
- Jolt has its own character controllers, `Character` (a rigid body) and `CharacterVirtual` (a kinematic shape with
  built-in stair walking and stick-to-floor). **Godot does not use them**: `CharacterBody3D` is Godot's own
  `move_and_slide()` on shape casts. So in Godot **no engine walks stairs for you**: kerbs and steps are the game's job
  (Part 5).

### 14.3 Differences from Godot Physics that touch the player (Godot 4.6 "Using Jolt Physics")

- **Collision margins**: Jolt shrinks the shape by the margin, then adds it back as a rounded shell: the size stays,
  **the corners round off**. The margin is `Collision Margin Fraction` × the shape's smallest side, capped by the
  shape's `margin`. The page warns margins can give odd normals in shape queries: a body touching a kerb's corner can
  get a tilted normal.
- **Ghost collisions**: `Collisions > Active Edge Threshold` and `Simulation > Use Enhanced Internal Edge Removal` (and
  the same for queries and motion queries). They do not help between two separate bodies (a kerb mesh meeting a road
  mesh).
- **Ray casts**: `face_index` is always -1 unless `Queries > Enable Ray Cast Face Index` is on (about 25 % more memory
  on triangle meshes). It matters if footstep sounds or surfaces are looked up by face.
- **Kinematic bodies** do not touch static or other kinematic bodies unless `Simulation > Generate All Kinematic
  Contacts` is on.
- **Contact impulses** are estimates (exact only when the two bodies touch nothing else): do not judge how hard a hit
  was from them.
- `Area3D` does not see static bodies by default (`simulation/areas_detect_static_bodies`).
- Physics on its own thread (`Run On Separate Thread`) is marked experimental; the phone rig uses it.

### 14.4 The capsule and the kerb (geometry, any engine)

`move_and_slide()` takes a contact as floor if its normal is within `floor_max_angle` (45° by default) of up. A capsule
of radius r touching the top edge of a step of height h gets a normal tilted by acos((r − h) / r):

| capsule radius | step 5 cm | step 10 cm | step 15 cm |
|---|---|---|---|
| 0.25 m | 37° (floor: rides up) | 53° (wall) | 66° (wall) |
| 0.30 m | 34° (floor) | 48° (wall) | 60° (wall) |
| 0.35 m | 31° (floor) | 44° (floor: rides up) | 55° (wall) |

A 0.3 m capsule rides over edges up to about 9 cm by itself (with a bump as it rolls over the edge) and stops at a
real kerb. So the step-up has to be the game's own, and it should decide alone: lift the body by the measured
height, and keep the capsule's bottom off small edges. The common pattern is a "floating capsule": the capsule held a
step-height above the ground by a ray or shape cast, so small edges never touch it. Other `CharacterBody3D` settings
that matter: `floor_snap_length` (stays on the ground going down kerbs and slopes), `floor_constant_speed` (same speed
up and down a slope), `floor_stop_on_slope`, `floor_block_on_wall`, `safe_margin` (0.001), `max_slides` (6).

---

## Part 15 - How Rockstar does it (GTA IV / V, RDR 1 / 2)

Sources: Rockstar's interviews about Euphoria, the GDC listing of Mike Jones's talk "Filling Marston's Boots: Player
Locomotion in Red Dead Redemption 2" (I found no slides or recording), what the games show, and what their modding
scene knows. Rockstar has published little about its animation internals; points marked *observed* come from watching
the games, not from Rockstar.

### 15.1 The technology

- **RAGE** (Rockstar Advanced Game Engine) runs all four games.
- **Euphoria** (NaturalMotion): an "active ragdoll". The body is simulated as physics, and small controllers drive its
  muscles: balance, a step to catch itself, arms out when falling, grabbing onto things, protecting the head. It is
  blended with ordinary animation: a person walks on clips, is hit, Euphoria takes the body, a get-up clip takes it
  back. GTA IV (2008) was its first big use; then RDR, GTA V, and RDR2, where Rockstar said it had "really evolved" it,
  for people and animals.
- **Animation data** (*from modding*): clips sit in "animation dictionaries"; walking styles are **clipsets** swapped
  per person (`move_m@drunk@...`, `move_m@brave`, `move_f@...`), so one locomotion system plays many personalities;
  blending runs in node networks ("MoVE" networks) that scripts drive.

### 15.2 GTA IV (2008) and RDR (2010): weight first

- *Observed:* heavy momentum: starts and stops take steps, turns at a run plant and pivot, the body leans into curves.
  Weighty, sometimes sluggish.
- Euphoria everywhere: stumbling down stairs when pushed, grabbing a car when hit, staggering when shot, drunk walking.
- Rockstar's first **cover system** (IV): a button snaps to cover; blind fire; peek over or round; move along it.
- *Observed:* climbing from one jump button: near a ledge it becomes a grab and pull-up, chosen by height. Ladders are
  their own mode. Low fences are climbed rather than vaulted at speed.

### 15.3 GTA V (2013): control first

- *Observed:* less momentum than IV: quicker starts, tighter turns, sprint by tapping; Euphoria toned down. A
  deliberate swap of realism for control.
- *Observed:* context traversal from the jump button: a low obstacle is vaulted, a mid one climbed, a high one jumped
  at and climbed if reachable, chosen by the measured height.
- Jumping down: a landing stumble or roll from medium heights; above that a Euphoria fall.
- A crouched stealth walk with its own clipset; per-character walking styles (Michael, Franklin, Trevor) by clipset.

### 15.4 RDR2 (2018): realism first

- *Observed:* Arthur's movement is **animation-led**: a step finishes before he turns, starts and stops pick the foot,
  a 180° turn is a real pivot. Many players called it sluggish; that is the price of the weight.
- Speed from the stick's lean plus tapping to run; a forced slow walk in camp; gaits change with terrain, and deep snow
  and mud slow him and lift his knees.
- *Observed:* feet and hips fitted to the ground everywhere (slopes, rocks, stairs) and **hands touching the world**
  (pushing doors open while walking through, a hand on a horse).
- People turn their heads to look at the player and at events.
- Climbing is contextual (fences, rocks, wagon beds, onto horses); fence vaults with a hand on the rail; no free
  climbing on walls.
- Bumping in crowds is physical: people shoulder each other and react.

### 15.5 What Coronado can take from them

1. **Choose the feel on purpose**: GTA V's responsive or RDR2's weighty. A touch-controlled phone game leans GTA V:
   commit to an animation only where it reads (a pivot, a climb) and keep starts and stops short (0.2-0.4 s).
2. **One button, chosen by height** (all four games). Add the vault / climb-over split by
   speed and the obstacle's depth (6.2, 11.1).
3. **Walking styles as data** (clipsets): a set of clips per personality, swapped per person, for the crowd and for the
   player's states (tired, drunk, hurt).
4. **Physics balance under clips** (Euphoria): a body that catches shoves and bumps with steps; for the
   player on bumps and landings, and for the crowd.
5. **Hands and eyes on the world**: look-at, a hand on doors and walls, pinned grips; the details people remember.

### Sources (parts 12-15)

- [Inverse kinematics returns to Godot 4.6](https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/)
- [SkeletonModifier3D class reference (4.6)](https://docs.godotengine.org/en/4.6/classes/class_skeletonmodifier3d.html)
- [Retargeting 3D skeletons (4.6)](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/retargeting_3d_skeletons.html)
- [Using Jolt Physics (4.6)](https://docs.godotengine.org/en/4.6/tutorials/physics/using_jolt_physics.html)
- [Godot 4.6 release notes](https://godotengine.org/releases/4.6/)
- [GDC: Learn the secrets of Red Dead Redemption 2's player locomotion](https://gdconf.com/news/learn-secrets-red-dead-redemption-2s-player-locomotion-gdc)
- [Rockstar on Euphoria in RDR2 (wccftech)](https://wccftech.com/rockstar-euphoria-evolved-rdr2/)
- [Euphoria (software), Wikipedia](https://en.wikipedia.org/wiki/Euphoria_(software))
- [Mixamo bone naming (mocaponline guide)](https://mocaponline.com/blogs/mocap-news/skeleton-hierarchy-animation-guide)

---

## Part 16 - Sources, and what changed from version 1

### 16.1 Corrections to version 1
| Version 1 said | Wrong because | Version 2 |
|---|---|---|
| "The ankle runs out at 20° up; don't let IK bend it further" | 20° is the limit **with a straight knee** (the calf crosses the knee). With the knee bent the ankle reaches 30-40°, and a normal run uses 20-30° in stance. | 2.1, 2.2: 25° with a straight knee, 40° with a bent one; running stance 20-30° is normal |
| Turn lean = atan(v²/(g·r)), no limit | Gives 60-70° on tight turns at speed. Friction caps it near atan(μ) ≈ 35°, comfort near 20°. The turn itself must be limited. | 3.1-3.3: lean caps, turn rate limit, cuts on plants |
| Hips "pop" if they move more than ~2 cm a frame | That is 72 m/s² (7 g) at 60 fps: ten times too loose, and it depends on the frame rate | 3.6: accelerations in m/s²; never down faster than g |
| "At most 5° past straight" for the knee, with no way to measure it | An unsigned angle can't tell forward from backward | 1.3: signed angle about a hinge axis carried by the thigh |
| A 10-item checklist "to look at frame by frame" | Not measurable, not testable, scripted moves only | Parts 8-9: catalogue, validator, mutation tests, free play, visual check |
| Starting: "the weight shifts sideways onto the standing leg and slightly back" | Half right: the pressure under the feet first moves **back and toward the stepping leg**, which tips the body forward and onto the standing leg | 4.5 |
| No joint speeds, no coupled limits, no whole-body balance, no friction, no perception data | | 2.2, 2.3, 3, 7 |
| Mentioned the old game's systems (HandGrip, FootPlant, CityPlayer, "done" items) | Steered fresh builds toward the old code | removed |

Version 2's first draft was then reviewed by an independent reader, as a biomechanist and an animation programmer
looking for loopholes. Its findings are fixed in this text: the soft reach (97 % forced a crouched walk; now eased
only above 99 %), the trunk-bend limit (a runner folded at the waist passed), hip rotation in the tests and the limit
table (a backward knee made by twisting the thigh passed), world space and scale (a lean put on the model node was
invisible), signs anchored in geometry and per side, the sole-against-ground roll and sole points from the mesh,
lean measured from the centre of pressure with the vertical acceleration and the in-step swing, cut angles limited by
grip, frame-rate independent filtering and a discontinuity check, the CoM parabola in flight, and the limiter tested
and forbidden to repair poses in testing.

### 16.2 Which numbers were checked against a source on 25 Nov 2026
- Footskate perceived under ~21 mm in most conditions: Pražák, Hoyet and O'Sullivan, "Perceptual evaluation of
  footskate cleanup", SCA 2011 ([Eurographics library](https://diglib.eg.org/handle/10.2312/SCA.SCA11.287-294));
  camera motion raises the slip threshold: "Perceptual thresholds for foot slipping in animated characters"
  ([CORE](https://core.ac.uk/works/153922345)).
- Horizontal errors in flight noticed more than vertical; added accelerations more than decelerations: Reitsma and
  Pollard, "Perceptual metrics for character animation: sensitivity to errors in ballistic motion", ACM TOG 2003
  ([CMU RI](https://ri.cmu.edu/?p=8709)); more sensitivity for human-like characters: Reitsma, Andrews and Pollard 2008
  ([CMU RI](https://www.ri.cmu.edu/?p=10106)).
- The head turns ~0.2 s (0.2-0.6 s in various studies) before the body, up to ~25° ahead of the path, at a roughly
  constant distance (~1.1 m) before the turn: walking-and-turning studies (Grasso et al.; Patla et al.), e.g.
  [Exp Brain Res 2008](https://link.springer.com/article/10.1007/s00221-008-1525-3),
  [PubMed 18688604](https://pubmed.ncbi.nlm.nih.gov/18688604/).
- About 10° of ankle dorsiflexion needed for walking and ~30° for running; weight-bearing lunge (knee bent) measures
  the loaded range: [Physiopedia, weight-bearing lunge test](https://www.physio-pedia.com/Weight-bearing_Lunge_Test),
  [Human Kinetics, ankle flexibility test](https://us.humankinetics.com/blogs/excerpt/ankle-flexibility-test).
- Running hip extension ~28-30° and ankle dorsiflexion ~13-21° in recreational runners (one study; others report up
  to ~25-30°): [PMC7875396](https://pmc.ncbi.nlm.nih.gov/articles/PMC7875396).
- ~20° as the lean a runner (or a horse) accepts rounding a bend: a secondary, commonly quoted figure
  ([Common Tread](https://www.revzilla.com/common-tread/learning-leaning)); lean = atan(lateral / vertical ground
  force) confirmed in turning animals ([SICB abstract](https://sicb.org/?p=27132)). No peer-reviewed human cutting-lean
  number was found; the caps in 3.2 are from friction and this figure.
- Sprint starts: forward lean helps point the ground force horizontally, but the advantage isn't settled across studies
  ([Swansea 2022](https://cronfa.swan.ac.uk/Record/cronfa62380/Download/62380__27897__7052fa38a21d419b8dc8c5b87b3d51f2.pdf),
  [Western Sydney](https://researchers.westernsydney.edu.au/en/publications/transition-from-upright-to-greater-forward-lean-posture-predicts-/)).

### 16.3 Standard references (numbers taken from them as commonly reported, not re-checked line by line)
- Perry and Burnfield, *Gait Analysis: Normal and Pathological Function* (walking phases and joint curves, 4.2).
- Winter, *Biomechanics and Motor Control of Human Movement* (walking curves, joint speeds).
- Novacheck, "The biomechanics of running", *Gait & Posture* 1998 (running phases and joint curves, 4.4).
- de Leva, "Adjustments to Zatsiorsky-Seluyanov's segment inertia parameters", *J Biomech* 1996 (segment masses, 1.6).
- Hof, Gazendam and Sinke, "The condition for dynamic stability", *J Biomech* 2005 (extrapolated centre of mass, 3.4).
- Grood and Suntay 1983; Wu et al., ISB recommendations 2002 and 2005 (joint coordinate systems, Part 1).
- AAOS joint motion norms (ranges, 2.1); Inman 1944 (shoulder rhythm, 2.2).
- Alexander, walk-run transition at Froude ≈ 0.5 (4.1).
- Johansson, "Visual perception of biological motion", 1973 (Part 7).
- Friction of shoes on common surfaces: pedestrian slip-resistance literature (3.1; ranges, not single values).
