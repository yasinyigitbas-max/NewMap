# The player's animation system: where it is, why interactions look bad, the plan (step 1, 22 Nov 2026)

Yasin, 22 Nov: "take only clips from festive work, not the code or the animation tuning. build the work on top of
animator branches work with every advanced feature like taking cover, picking objects, slope or tight area walk,
different animation shuffles"; "i need studio quality animations, im willing to fine tune as much as needed".

This is a read of the code and the clips. No code changed in this step.

## 1. What main plays today (the Animator's system, `native/src/city_player.cpp` + `city_ped.cpp`)
- One `AnimationPlayer` per figure. A new clip is a plain crossfade of 0.3 s (0.18 s for one-shots)
  (`city_ped.cpp:245`). Every clip starts at its frame 0. Matching the stride (the same foot down) is switched off
  (`city_ped.cpp:252`, `if (false && ...)`, "no seek of mine", 21 Nov).
- Libraries loaded: the default one, `ual`, `step`, `mx` (`city_ped.cpp:81-91`). **The festive player libraries are
  on disk in main but nothing loads them**: `characters/rocketbox/clips_player_{trav,act,walk,run,idle}_<g>.res`
  ("ptrav", "pact", "pwalk", "prun", "pidle").
- Climbs, vaults and steps (`city_player.cpp:330-395`, `try_climb` 746-843): the capsule is put at
  `climb_from + the clip's own hip travel`. The figure is drawn at `climb_from` and the clip moves it. At the clip's end
  the body is set to `climb_to` (the real top).
- **The hand grip, the foot plant and the lean are all switched off** (`city_player.cpp:699, 739, 877, 726`: "Mixamo's
  clips as they are, Yasin 21 Nov").
- Out of a climb: 0.45 s forced into `ual/Idle_Loop`, then walking only for 1.1 s (`city_player.cpp:396-419`).
- One vault for every fence from 0.24 to 1.4 m: `mx/Vault_Over_Box_to_Cover`, a 3.5 s take that ends crouched in
  cover (`city_player.cpp:373, 799`).

## 2. Why each thing Yasin sees happens
| What he sees | Cause |
|---|---|
| "jumps to the sky" after a climb starts | The climb clip carries the hips as high as the wall it was recorded on, not the wall in front of him. On a 1.2 m wall a take made for about 2 m lifts him 0.8 m over the top, and at the end he is snapped down onto `climb_to`. Nothing fits the clip's height to the real ledge. |
| hands don't hold the edge | Hand IK is off. The clip's hands land where the mocap wall was: in the air, or inside the wall. |
| pops between moves | 0.3 s crossfades between a clip with root motion and a loop drawn in place: the hips swing through the blend. Loops change on the wrong foot because stride matching is off. |
| stiff after a climb or vault | 0.45 s of forced Idle, then a forced walk. |
| feet skate in starts and stops | The foot plant is off, and the start, stop and turn clips play at rates other than their own pace. |

Festive (`origin/festive-faraday-work`: `native/src/city_player_traversal.cpp`, `city_player_moves.cpp`; read for
its features and its mistakes, none of its code is used):
- It fitted a clip to the world by moving the WHOLE figure (height dy, shift dxz, an added sine "lift" arc, a travel
  scale) over windows that include planted feet (`trav_pose`). Result: planted feet slide and the body floats over
  the obstacle.
- No hand grip in any traversal move (`hand_grip.h` included, never used): hands never touched an edge.
- Clips cut in partway (`t0 = air - 0.3`), with the pop then covered by figure and yaw offsets during a crossfade
  (`trav_hand`, `trav_fo`, `trav_yo`): patch on patch.
- Clips used for the wrong job: Running_Jump_Climb when walking up to a box, Vault_Over_Box_To_Cover (ends crouched in
  cover) for every walking vault, a running jump over bushes. Facings hard-coded ("the standing idles' hips face -39
  degrees").
- Its feature list and thresholds are a good spec, and they are kept: falls by height (3 / 5 / 7 m), losing balance
  at an edge after 15 s, cover from 0.6 m (standing cover from 1.45 m), thin under 0.6 m, short under 1.2 m, climbs
  to 2.5 m, carry one or two hands, benches from front / side / behind, bumps and trips, the sidestep through a gap,
  the look-at.

## 3. The clips we have (festive's libraries, plus what main already plays)
- **ptrav** (60): standing / running jumps, jump downs, soft and hard landings, falls (flat, on his back, from losing
  balance, falling idle, falling to landing), getting up, crouch in/out/idle/walk/sneak L R/to sprint, cover
  (stand to cover a/b, cover to stand a/b, idle, crouch idle, cover to cover, turns, sneaks L R, sneak off, look
  round a corner), vaults (Vault_Over_Box_To_Cover, Jumping_Over_Into_Combat), climbs (Running_Jump_Climb,
  Braced_Hang_To_Crouch, Stand_To_Freehang, Hanging_Idle, Climbing_Single, Climbing_Double, Sprint_To_Wall_Climb).
  Each one carries meta measured at make time: `elev` per frame, `air_at / apex_at / land_at`, `top_at`, `hand0`,
  `hands_low_*`, `face0 / face_end`, `flip`.
- **pact** (33): carrying with two hands (box turn, walk, jog, run, stop) and one hand (briefcase idle, walk, turns;
  shopping bag), benches (stand to sit, sitting idle, sitting talking, sit to stand), bumps (3 shoves, hit on the
  back, shoulder hit and fall, jogging stumble, 2 trips, stumble backwards), strafes (the sidestep through a gap),
  the put down / pick up (Tender_Placement), doors (open outwards, open inwards).
- **pwalk / prun / pidle**: walk starts / loops / stops / turns / 180s (both feet, by mirroring), runs (5 fast loops,
  starts, stops, turns, 180s), base idles (5 packs).

Gaps that limit quality (no code can make these up; more clips would fix them):
- **One vault take** for every height, and it ends in cover. A real vault set is low (0.5-0.8 m) and high (0.8-1.2 m),
  walking and running, landing into walk / run / idle.
- **Climbs at only a few heights.** A good set: 1 m (mantle), 1.5 m, 2 m (hang and pull), each with a walk-in and a
  run-in.
- **Pick up from the floor**: only Tender_Placement (0.4-0.5 m surface). Missing: from the floor, one hand, two hands.
- **Slopes / stairs**: only Ascending_Stairs. Missing: stairs down, walking up and down a slope.
- **Doors**: push and pull only, no "locked".

Warping will fit what we have to heights near the recorded one (about +/-30 %). Beyond that a clip will look stretched,
so a missing height should be filled with a new take, not stretched further.

## 4. The new system (C++, on main; one piece at a time)
1. **One owner of the body at any moment.** Each state says who moves the capsule: the controller (walking), or the
   clip's root motion (a move), or warped root motion (a move fitted to the world). Never two at once.
2. **Inertialized hand-overs** instead of crossfades. At a switch the new clip plays at once. The difference between
   the old pose and the new one (per bone, plus the hips' place) is stored and decays to zero over 0.15-0.3 s on a
   smooth curve that also keeps its speed. That is the Gears of War method, and it costs one pose per figure, not two.
   It removes the hip swing between a root-motion clip and an in-place loop.
3. **Motion warping.** Each traversal clip gets warp windows (from its own meta: the hands' contact, `top_at`,
   `land_at`). Inside a window its root motion is scaled so a chosen moment lands on a target read from the world
   (the hand plant on the real edge, the top on the real top, the landing on the real ground). Outside the windows,
   and whenever a foot is planted, the clip plays exactly as recorded.
4. **Contact IK, from the clip's own contacts.** For each clip, the windows where a hand or foot touches something are
   measured once at make time: the hand's speed is near zero at the edge height. During that window the hand is pinned
   to the edge point found by rays (two-bone IK, the wrist turned onto the surface, fingers curled), its weight fading
   in and out over about 0.1 s. Feet are pinned to the ground where they are planted (foot lock against sliding), with
   the hips lowered when one foot stands lower (slopes, kerbs).
5. **Enter / loop / exit for every action, with variants.** Cover, carry, sit, crouch, hang: the variant is picked
   by speed, angle and leading foot, and never the same take twice in a row (the "shuffles").
6. **Locomotion**: starts, stops and turns on the right foot (stride matching back on, through the inertializer);
   the foot plant on; slope lean and stride on ramps; the tight-space sidestep; a lean into turns, with the strength
   set by Yasin.

Everything is a module beside `CityPlayer`, not stacked on its update: `anim_inertial`, `anim_warp`, `anim_contacts`
(made at clip-build time, read at runtime), `player_locomotion`, `player_traversal`, `player_actions`. Each comes with
a headless test that prints numbers.

## 5. What "good" is measured as (each step's test prints these)
- Hand to edge during a contact window: under 3 cm. Hand over or under the top: under 2 cm.
- Hips never higher than the real top + the clip's own clearance (no "sky"). Height pop in any frame: under 3 cm.
- A planted foot's slide: under 2 cm. Hips' speed jump at a hand-over: under 0.5 m/s.
- Each move tried at 3 heights or angles. Numbers cannot see the feel: Yasin plays it, says what is wrong, and that
  gets fixed.

## 6. Order of work
1. The base: load the festive libraries; the inertializer in place of crossfades; one owner of the body.
2. Vault (low and high, walk and run) with warping and hand contact IK.
3. Climbs (mantle, hang and pull, double) the same way, then jump down, hang and drop, falls and landings by height.
4. Locomotion: stride-matched starts, stops and turns; the foot plant; slopes and stairs; the tight-space sidestep;
   idle and walk shuffles.
5. Crouch and cover (enter / idle / sneak / corner / turn / exit).
6. Pick up and put down, carry (one and two hands, prop on the grips), benches, doors, bumps.

Each one is built, tested and pushed on its own. Yasin plays it and gives notes.

## 7. Building and testing
`native/build.sh` builds for Windows and Android on Yasin's PC. A cloud session can download Godot and godot-cpp and
build a Linux copy of the module, so tests run headless here and only the playing is left for Yasin's PC.

## 8. Step 2, the base (22 Nov): what is built, what the numbers say
New, all in `native/src/` (character-generic, no player-only code; NPCs can own one later):
- `mo_clip.{h,cpp}`: each clip measured once from its own tracks (hips, feet, toes, hands per 1/30 s in the figure's
  frame, facing, speeds over the ground, foot contacts by height), pose matching (`best_entry`), and THE BODY'S
  TRAVEL READ FROM THE PLANTED FEET (`root_v`): the converter's smoothed vz / vx pace did not match the feet.
- `mo_inertial.{h,cpp}` (`MoInertial`, first modifier on the skeleton): inertialized hand-overs (Bollo's quintic),
  root bone taken in the world so a re-anchored figure does not jump, ONE history entry per engine frame.
- `mo_limbs.{h,cpp}` (`MoLimbs`, second modifier): foot lock (a foot the clip has down is pinned where it landed,
  its offset fading 0.15 s after the clip lifts it; two-bone IK, the knee toward the clip's own); hand targets ready
  for the vault / climb step.
- `mo_motor.{h,cpp}` (`mo::Motor`): idle (3 forward-facing idles, fidgets every 9-21 s, never the same twice), starts
  (walk a / b, run, run turning starts), loops by pace (walk x2, jog x3, run x3; never the same walk twice running),
  stops (the stop and the moment of it most like the feet now), turns on the spot (the take nearest the angle), 180
  pivots while moving. It plays clips itself (manual AnimationPlayer, time set each frame). One owner of the body.
- `CityPlayer`: the motor has him while he is on the ground and nothing else does; the old code keeps jumps, climbs,
  crouch, swimming, combat, acts, talk, phone, and the two hand over both ways. `--old-moves` turns the motor off.
- `native/build_linux.sh`: a Linux copy of the module for headless tests in a cloud session.
- `tests/people/test_motor_base.gd`: 19 phases of locomotion, new and old.

Measured (`test_motor_base.gd`, 60 fps, flat ground; the drawn figure after every modifier):
| | new | old |
|---|---|---|
| hips' height jump in one frame, worst | 3.2 cm (run pivot); every other phase 0.7-2.9 | 4.2 cm |
| hips' level speed jump in one frame | 14 of 19 phases under 1.2 m/s (0.16-0.94); 5 at 1.3-2.0 | 0.2-2.4, most hand-overs 1.0-2.0 |
| planted foot slide (the clip's own contacts) | stand 2.3 cm, stops 3-6, starts 6-13, loops 6, turns 4-6 | not measurable the same way (no contacts) |
OPEN (next fixes): the 180 pivots slide a planted foot 30-41 cm (both feet are "down" while the body turns; the travel
from the feet is wrong there); the run stop has a hitch at 0.17 s that is IN the clip (it is there with the hand-over
off: prun/stop_a / stop_b, made with festive's "stance_fit"); walk -> run and stops hand over at 1.3-1.6 m/s.
What the numbers cannot see: the arms, the spine, the look. Yasin plays it.

Traps found (also in the skill): read the pose on `skeleton_updated` (a read in `_process` saw the raw clip, before
the modifiers); the skeleton can be posed twice in a frame (a seek, then its own update): count frames, not passes;
the skeleton node is scaled 0.01 (bone units are cm); the root's offset speed is the hips' own, not their world speed.

### Step 2, second pass (22 Nov): the pivots and the stops
- The run stops and the right run pivot are Mixamo's own takes now (`mx/Run_To_Stop`, `Run_To_Stop_2`,
  `Running_Turn_180`): festive's prun copies were tuned (`_fit_stance` bent the legs toward the idle's stance; the
  turns' pace smoothed) and the stop had a hitch inside it.
- A raw clip whose pose already turns ignores the converter's "yaw" curve (Run_To_Stop's pose turns -43 degrees and its
  yaw said -47: played both, he turned twice). Decided per clip from its measured facing (`ClipData::yaw_turns`).
- A clip that turns the body round counts a foot down only within 2 cm of its floor (the stepping foot was taken as
  planted).
- LET GO while moving: the loop runs on (at most 0.7 s) until its stride is where a stop's opening pose is, and the stop
  starts from there (cut in anywhere, a hand-over swept a planted foot 66 cm).
- CONTACT ALIGNMENT at every hand-over: the new clip is placed so its planted foot lands on the foot already pinned.
- A foot is pinned only when the drawn ankle is within 15 cm of the ground (a hand-over held a foot 25 cm up while
  the new clip had it down).
| phase | slide before -> now (cm) |
|---|---|
| run stop | 13.2 -> 6.9 |
| run turn back (pivot) | 40.9 -> 1.0 |
| walk turn back (pivot) | 30.2 -> 6.0 |
| turns on the spot | 3.2-4.0 -> 2.7-3.2 |
| walk stop (first) | 5.7 -> 28.8 (OPEN: one stop_b case) |
Tried and taken back, with their numbers: travel from the lower foot only (walks 35 cm), from the foot nearest the
clip's own travel (walks 35 cm), the clip's own travel for turning clips (pivots unchanged), the floor rule for every
clip (stops 12 cm), a soft foot lock easing at 0.8 m/s (walks 18 cm), pinning at the clip's own foot instead of the drawn
one (standing 18 cm, runs 26-35 cm).
Still failing the 1.2 m/s hip speed check: run stop 1.62, walk -> run 1.56, run pivot 1.96, a second run stop 1.63.

### Step 2, third pass and step 3 finished (22 Nov): every base phase and every traversal lane passes
`test_motor_base.gd` RESULT PASS (19 phases), `test_motor_trav.gd` RESULT PASS (12 lanes), `test_step_up.gd` PASS.
What changed, and why (each measured before / after):
- THE TEST WAS WRONG FIRST: it read the clip's contact flags one frame AHEAD of the pose it measured (the first pose
  of a frame comes from the motor's seek, after the motor stepped on). A foot swinging in at 7 m/s showed as 12 cm of
  "slide". Every earlier slide number in this file is partly that. The test now pairs each pose with its own state,
  and reports PULL: how far the foot lock holds a planted foot off where the clip has it once a hand-over is over (a
  leg bent off its own pose), re-plant steps and hand-overs left out.
- The figure stands on the ground under the body (a ray), not on the capsule's height (it bobbed 4 mm every other
  frame and sank 3 cm after a vault's snap: the vaults' landing "pop").
- BODY TRAVEL (mo_clip root_v): per 1/30 s interval, from the foot that is really planted (when the two disagree by
  0.35 m/s, the one nearer the clip's pace; the other is then not down); a foot sliding along the floor in a clip that
  carries itself is not down; contacts shorter than 0.1 s are blips. What is smoothed is the HIPS' path in the world
  (1-2-3-2-1 over five intervals, in the clip's start frame so a turning clip is right): the body takes up the 30 Hz
  keys' noise, the foot lock the little left. (Smoothing the travel alone smeared a run stop's plant: a 1.6 m/s stall.)
- The yaw-curve check (is the turn in the pose or the curve) is made at the curve's largest turn, not at its end: the
  walk stops sway -0.22 rad and back in both, and turned twice.
- At every hand-over: the new clip turned so its hips face as the drawn ones (not into a loop: there the facing is the
  way he travels), and placed so its planted foot is on the pinned one, or (none) its hips on the drawn hips. Left to
  the inertial offset, the hips' turn and place swung the whole figure (and a foot pinned meanwhile).
- THE BODY FOLLOWS ITS PLANTED FEET: a pinned foot the clip no longer has there draws the body toward it (3 per second,
  at most 0.5 m/s) instead of bending the leg (a walk stop held a leg 25 cm off for 0.6 s).
- RE-PLANT STEPS (MoLimbs): standing (idle, stop), a planted foot held 4 cm or more off the clip's stance for 0.15 s
  lifts and steps there (an arc 6 cm high, 0.3 s, one foot at a time). Before: after a hand-over the feet kept the old
  stance for as long as he stood (legs 10-17 cm off).
- Coming to a stand, the idle (of three) and the moment of it whose stance is most like the feet now.
- Pivots wait (at most a step, 0.35 s) for the stride that fits a pivot's opening; a full reversal takes either side.
- The motor's clips play with CUBIC interpolation between their 30 Hz keys (straight lines kinked a fast turn at every
  key: the run pivot's hips changed speed 1.3 m/s in a frame).
- The trav body (capsule) never goes over the top (it followed the tucked feet 73 cm over a 1.6 m wall).
| phase | slide | hips speed jump | pull after hand-overs |
|---|---|---|---|
| all 19 | 0.0-2.0 cm | 0.12-1.14 m/s | 3-6 cm in walks, runs, turns; 12-20 cm early in the stops (the swing leg's blend still decaying when it lands; the body follows it out within 0.3 s) |
OPEN: the stops' landing pull (a better stop entry: match the swing foot's landing spot, not just the pose).

## 9. Step 4, slopes, kerbs and stairs (22 Nov): `tests/people/test_motor_slopes.gd`
Built (character-generic, in mo_motor / mo_limbs):
- THE FIGURE'S FLOOR is the ground under the body on a critically damped spring (10 rad/s; snaps over 0.45 m: a drop, a
  teleport), not the capsule's height. The figure hangs under the body: after the host lifts the body onto a kerb, the
  figure is put back (Motor::replace) - before, the lift dragged it up 4-8 cm for a frame.
- EACH FOOT FITTED to the ground under it (rays at the clip's foot each frame): fully while the clip has it on its floor,
  only upward in the swing (over a step's edge). On a STEP (level ground both, 4 cm apart) the sole stands on the higher
  one only when the ball and mid-sole are over it.
- A PIN'S HEIGHT is the clip's own contact height on the ground at the pin (eased 0.1 s), not the blended pose's.
- THE HIPS DROP for a fitted foot lower than the clip's (downhill, a step down), on a spring (14 down / 9 up rad/s);
  eased by a rate they popped 4-5 cm a frame at every stair.
- SOLES TILTED onto the ground's slope while down (at most 30 degrees).
- THE LANDING ON A STEP decided in the swing: the clip's next contact looked up (within 0.2 s), its spot predicted, the
  ground sampled along the sole; the foot steered onto the level stretch under its middle (whole sole on it, or
  centred). Moving the pin after landing showed as a 7 cm slide.
- Kerbs and stairs are WALKED by the new system: CityPlayer's old step-up clip (try_climb, rise <= 24 cm) is skipped
  while the motor has him (Yasin: "kerbs shouldnt require step up animation"); the capsule's lift stays.
- The body keeps the new system over a crest run fast (ground within 0.5 m under him).
- A LOOP GOES STRAIGHT on average (its cycle's sideways drift removed: the run drifted 2.7 m left in 14 m).
- Re-plant steps fire at once when a standing foot is 12 cm off; a pin about to break (30 cm) steps instead of snapping.
- The body-follow reads the DRAWN frame's pull (read mid-step it alternated) and accelerates at most 4 m/s^2.
- MoLimbs' timers count each frame once (the skeleton can be posed twice a frame).
| lane | float / sink (cm) | slide | hip pop |
|---|---|---|---|
| ramps 8, 15, 22, 30 deg, walked and run | 0.3-3.3 / 0.3-2.0 | 0.1-1.4 | 0.4-1.4 |
| stairs 12 cm walked | 1.9 / 1.6 | 0.8 | 0.8 |
| kerb 15 cm walked / run | (flips between 0.6 and 14.7 / 0.4-4.5 with the toe estimate) | 0-2.5 | 0.6-0.9 |
| stairs 17 cm walked / run | 16-17 / 0.4-0.6 at the first and last steps | 1.6-5.4 | 1.0 |
OPEN: the 17 cm stairs' first and last steps, and the kerb: the figures have NO TOE BONE, the ball of the foot is taken
13 cm ahead of the ankle; whether the sole stands on the step's edge or before it decides these numbers, and the test
and the motor estimate the toe differently. Yasin's eye on stairs decides the next fix (a stair-climb clip set would be
the studio answer for long flights; ask Yasin for "stairs up / down" takes).

## 10. Step 5, crouch and cover (22 Nov): `native/src/mo_motor_cover.cpp`, `tests/people/test_motor_cover.gd` PASS
- THE CROUCH (C / Ctrl, CityPlayer's own key; the motor now does it): Standing_To_Crouched in, Crouched_To_Standing out
  (root clips: the figure at an anchor, the body following the hips), Crouching_Idle and Crouched_Walking between
  (steered at 2.5 rad/s). No crouched start / stop clip: the walk's rate eased up from 0.45 and down to it, and on
  letting go it runs on to the stride most like the idle. Switches inside the crouch keep the body where it is (facing
  alignment only: the walk's hips ride 34 cm higher and further on than the idle's).
- COVER (Q; `request_cover()`): a wall the way he faces or pushes within 1.6 m, else the nearest round him; from 1.45 m
  high standing cover (Cover_Idle), from 0.6 m crouched (Crouch_Cover_Idle). In: Stand_To_Cover_a / _b as a root clip
  facing the wall, its end warped so the body ends 0.30 m (standing) / 0.38 m (crouched) off the wall. Along it: the
  cover sneaks (in-place loops that travel sideways about 1 m/s; Left/Right_Cover_Sneak_a, Crouched_Sneaking_Left/Right),
  the body held at the wall's distance, stopped 0.85 m before its end, a reversal passing through the idle, a stop
  waiting for the stride most like the idle. Out: Cover_To_Stand_b / _a (a root clip back off the wall).
- Festive's cover clips were captured in different frames (Cover_Idle half round against Stand_To_Cover's end; the
  sneaks' hips 15 degrees off the idle's): hand-overs in cover turn the new clip onto the drawn hips by any amount
  (align_full) and leave the body where the wall puts it (face_only); a sneak then turns (6/s) until its own travel runs
  along the wall.
- Fixed on the way: a sideways loop keeps its travel (the straight-loop correction had removed a sneak's whole
  travel); the old kerb step is skipped in cover (touching the wall read as a kerb's face: 4 cm a frame along it); the
  body does not follow its pinned feet in cover (it drifted 30 cm off the wall); a pin about to break steps whenever
  the other foot holds him, else fades (never snaps).
| lane | states | gap to the wall | along | slide | pop | hips speed jump |
|---|---|---|---|---|---|---|
| crouch | stance, crouch | - | - | 0.7 cm | 0.6 cm | 0.67 m/s |
| tall cover | in, cover, out | 0.30-0.30 m | 3.5 m, inside the ends | 1.0 cm | 0.4 cm | 1.14 m/s |
| low cover | in, cover, out | 0.30-0.38 m | 3.1 m, inside the ends | 0.2 cm | 0.5 cm | 1.18 m/s |
NOT YET: peeking round a corner (Crouch_Look_Around_Corner), turning in cover (Standing/Crouch_Cover_Turn), cover to
cover (Crouch_Cover_To_Cover), sneaking off the cover (Sneak_Off_The_Cover), a crouched turn on the spot. What the test
cannot see: his back and hands against the wall, where he looks - Yasin plays it.

## 11. Step 6, carrying (22 Nov): `native/src/mo_motor_carry.cpp`, `tests/people/test_motor_carry.gd` PASS
- A BOX in both hands (G toggles one, to try it; `set_carry(1)`): Walking_Carry and Jogging_With_Box_a as loops, steered
  at 2.6 rad/s and slowed into sharp turns; no carried start: the rate eased up from about 0.6 m/s; on letting go, eased
  down and on to the stride most like the idle. The idle is the held tail of Walk_Carry_Stop (from 3.0 s, looped with a
  hand-over at its seam; its hips stand 1.4 m from the clip's origin, played in place by the clip's figure offset
  Clip::off). The box is where the clip's hands hold it (their middle, on a spring), as wide as the carry walk's palms
  are apart, and BOTH HANDS ARE PINNED TO ITS SIDES (MoLimbs' hand reach): every clip holds the same box.
- A BRIEFCASE / SHOPPING BAG in the right hand (`set_carry(2 / 3)`): Briefcase_Idle, Walk_With_Briefcase /
  Walking_With_Shopping_Bag; the bag where the clip's right hand is (on a spring), the hand pinned to its handle.
- The motor says where the thing is (Motor::carry_xf); CityPlayer draws a placeholder (a cardboard box, a briefcase, a
  paper bag). Switches inside a carry keep the body where it is (facing alignment only: the idle's stance against a
  stride, the contact alignment jumped the body 40 cm).
| lane | hands to the box | prop, most in a frame | slide | pop | hips speed jump |
|---|---|---|---|---|---|
| box (walk, stop, jog, stop) | 0.1 cm | 4.4 cm | 0.2 cm | 0.9 cm | 1.16 m/s |
| briefcase (walk, stop) | - | 3.0 cm | 2.2 cm | 0.5 cm | 0.66 m/s |
NOT YET: picking up and putting down (no clip in festive's set for a pick-up from the floor; Tender_Placement, 9.3 s, is
a slow careful put-down: ask Yasin for "pick up a box / put it down" takes), turning on the spot with a box (Box_Turn_a
/ _b, Carrying_Turn are there), the briefcase's turns, running with a bag. What the test cannot see: the fingers, the
box's look - Yasin plays it.
