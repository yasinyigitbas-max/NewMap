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
