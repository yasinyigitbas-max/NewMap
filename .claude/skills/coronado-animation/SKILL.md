---
name: coronado-animation
description: The player's (and later the crowd's) animation system for Coronado - studio-quality blending, motion warping, hand / foot contact IK, enter-loop-exit actions, traversal (vault, climb, jump, fall, cover, crouch), carry, sit, pick up, slopes, tight spaces. Holds the studied industry techniques, the diagnosis of the Animator (main) and festive-faraday systems, Yasin's rules for this work, the clip inventory and the measured targets. Read BEFORE touching native/src/city_player*, city_ped*, hand_grip*, foot plant, body_layer, anim_*, tools/people/make_player_*.gd or tests/people, before answering any "the animation looks wrong" note, and whenever in doubt about how to blend or fit a clip.
---

# Coronado animation (started 22 Nov 2026)

The plan and diagnosis with file:line references: `docs/ANIMATION_PLAN.md`. This skill is the short form plus
the rules. Re-read both after a context compression.

## Yasin's words for this work (newest last)
- 21 Nov (to the Animator): "I TOLD YOU TO REPLACE ALL YOUR CODE WITH CLIPS", "add them to animations raw", "you still
  add things to them like jumps, remove all your modifications". The point: no invented motion added on top of the clips.
- 22 Nov: "nothing is broken in festive faraday work's work ... animations look terrible tho, they are great one by one
  ... problem starts when the character interacts with objects".
- 22 Nov: "take only clips from festive work, not the code or the animation tuning. build the work on top of animator
  branches work with every advanced feature like taking cover, picking objects, slope or tight area walk, different
  animation shuffles". "hands should hold edges of things when we interact with them like when we vault, character
  shouldnt jump to the sky after initiating climbs".
- 22 Nov: "i need studio quality animations, im willing to fine tune as much as needed. think that you are making the
  next gta for rockstar and you are the animation guy."
- 22 Nov: he agreed (after it was put to him) that warping, contact IK and inertialization run at runtime: the clip's
  motion and timing stay as recorded, only where it lands is fitted, only in contact / flight windows.
- 22 Nov: "work in your own branch, project is moving forward fast, I dont want anything to break." -> work ONLY on the
  session branch (`claude/cool-galileo-6y68se` on 22 Nov); never push to main, never merge into main, no PR unless asked.
  Keep changes additive and behind the player's own code paths; the crowd (CityPed for NPCs) must keep working.
- 22 Nov: "animators animations played terrible too, just keep in mind. You might have to make a new system from
  scratch for players movement. I eventually want every npc to have players capabilities too." -> the Animator's
  playback is NOT a quality bar to keep; a new movement / animation system from scratch is allowed. Design it as a
  CHARACTER component (a "body" with locomotion, traversal, actions, IK) that any figure can own, driven by a
  controller: the player's input today, an NPC brain later. Nothing player-only (camera, keys, touch) inside it.
  Keep the per-frame cost low enough for many NPCs later (LOD: full IK and warping near the camera, cheaper far).

## The techniques (studied 22 Nov; GDC / SIGGRAPH: Gears of War 4 inertialization and warping, Horizon Zero Dawn
## traversal, RDR2 locomotion, UE5 motion warping)
1. **Inertialization, not crossfades.** On a switch the new clip plays at full weight at once. Store per bone the
   offset (old pose - new pose) and its velocity; decay it to zero over 0.15-0.3 s with a curve that starts at the
   offset's own velocity (Bollo's quintic, or a critically damped spring). One pose evaluated, not two. A crossfade of
   a root-motion clip and an in-place loop swings the hips: inertialization does not.
2. **Motion warping.** Mark warp windows on a clip (by its own meta: hand contact, top_at, land_at, apex). Inside a
   window scale or offset the ROOT MOTION so a chosen frame lands on a world target (hand plant on the real edge, the
   top on the real top, the landing on the real ground). Warp only while the feet are OFF the ground (Guerrilla:
   "looks best when feet are not touching ground"). Outside windows play exactly as recorded. Keep warp within about
   +/-30 % of the recorded height / distance; beyond that pick another take or ask Yasin for a new clip.
3. **Contact IK from the clip's own contacts.** Measure once, at clip-build time, the windows where a hand or foot is
   in contact (speed near zero at the contact height). At runtime, in that window only, pin it to the world point
   found by rays (two-bone IK, wrist turned onto the surface normal, fingers curled), weight eased in and out over
   about 0.1 s. Hands that float or sink into ledges are what players notice first.
4. **Foot lock / plant.** A planted foot stays put (no skating). Hips lowered for the lower foot on slopes and kerbs.
5. **Enter / loop / exit with variants** for every action (cover, carry, sit, crouch, hang), picked by speed, approach
   angle and leading foot; never the same take twice in a row (shuffles).
6. **One owner of the body at a time.** The controller (locomotion), the clip's root motion (a move), or warped root
   motion. Two systems moving the capsule at once = every "launch" / "pop" bug.
7. **Locomotion:** starts, stops, turns and pivots chosen by the foot that is down; loops changed on the same stride
   phase (sync markers); stride and play rate matched to speed; lean into turns; slope lean / stride.

## What went wrong before (do not repeat)
- **Animator (main, 21 Nov):** hand grip, foot plant and lean switched OFF (`city_player.cpp` ~699, 739, 877, 726);
  a climb clip carries the hips as high as ITS wall, then he is snapped onto the real top (the "sky jump"); 0.3 s
  crossfades, each clip from frame 0, stride matching off (`city_ped.cpp` ~245-252); 0.45 s forced Idle after a climb;
  one vault clip (that ends in cover) for every fence; the festive libraries are on disk but not loaded.
- **Festive (origin/festive-faraday-work, `city_player_traversal.cpp`, `city_player_moves.cpp`):** fitted clips by
  offsetting the WHOLE figure (dy, dxz, an added sine "lift" arc, hscale) over windows that include planted feet ->
  feet slide, body floats; NO hand grip in any traversal move; clips cut in mid-way (`t0 = air - 0.3`) and the pop
  patched with figure / yaw offsets during a crossfade (patch on patch); clips used for the wrong job
  (Running_Jump_Climb for walking up to a box, Vault_Over_Box_To_Cover for every walking vault, a running jump over
  bushes); hard-coded facings ("the standing idles' hips face -39 degrees"). Its feature list and thresholds are fine
  to take as a spec (falls by height 3 / 5 / 7 m, edge balance after 15 s, cover from 0.6 m / standing from 1.45 m,
  thin < 0.6 m, short < 1.2 m, climbs to 2.5 m).

## The clips (festive's libraries, in main on disk; `tools/people/make_player_*.gd` makes them)
`characters/rocketbox/clips_player_{trav,act,walk,run,idle}_<male|female>.res` = libraries ptrav / pact / pwalk / prun
/ pidle (see the TAKES lists in those scripts for names). Each clip has meta measured at make time: elev (per frame),
elev0, rise, air_at, apex_at, land_at, leave_at, impact_at, top_at, face0 / face_end / face, flip, lat, lo0 / lo_end,
hand0, key_at, hands_low_*, root, turning; walks: vz / vx / yaw / pace curves, ph_in / ph_out, slide_cm.
Rocketbox skeleton: Bip01_* bones (Bip01_Pelvis, Bip01_L_Hand, Bip01_L_Foot, Bip01_L_Thigh ...).
Gaps (ask Yasin for clips rather than stretch): vaults low / high walk / run, climbs at 1 / 1.5 / 2 m, pick up from the
floor, stairs down, slope walks.

## Targets every test prints (numbers can't judge feel: Yasin plays it)
Hand to edge in a contact window < 3 cm, over / under the top < 2 cm; hips never above the real top + the clip's own
clearance; height pop in a frame < 3 cm; planted foot slide < 2 cm; hips' speed jump at a hand-over < 0.5 m/s. Each
move at 3 heights / angles.

## House rules that apply here
LF endings; tests are SceneTree scripts that print PASS / FAIL and quit by themselves; one fix = one thing changed;
say what a check cannot see; commit and push after every step (session branch only); `native/build.sh` builds on
Yasin's PC (Windows / Android) - a cloud session builds a Linux copy for headless tests.

## The new system (step 2 built 22 Nov; docs/ANIMATION_PLAN.md section 8)
Files: native/src/mo_clip, mo_inertial (MoInertial), mo_limbs (MoLimbs: foot lock, re-plant steps, hands), mo_motor
(mo::Motor; align_facing / align_contacts / align_hips at every play(), the body follows its planted feet),
mo_motor_trav (vault / climb); tools/people/dump_mo_clip.gd prints a clip as mo_clip measures it; CityPlayer hands the
body to the motor on the ground (`motor_can`), the old code keeps the rest; `--old-moves` turns it off. Test:
tests/people/test_motor_base.gd (`-- --only=new|old --trace --no-inertial --no-footlock`).
Build and run here: `bash native/build_linux.sh` (godot-cpp in /root/native_tools/godot-cpp, scons platform=linux
target=template_debug, about 10 min once), Godot 4.7.2 from github godot-builds releases on PATH as `godot`.
TRAPS (each cost a run):
- Measure the drawn pose on `Skeleton3D.skeleton_updated`, not in _process (that is the raw clip before modifiers),
  and keep only the LAST pose of a frame (seek(update=true) poses the skeleton again in the same frame).
- A modifier that keeps history (MoInertial, MoLimbs) must count engine frames, not modifier passes.
- The figure's skeleton node is scaled 0.01: bone space is centimetres. Convert with the skeleton's global transform.
- Inertialization: the offset's speed is the bone's own (against the figure); a root's world speed made T collapse.
- Quaternion angle near zero: use atan2(|xyz|, w), not acos / sqrt(1-w*w) (floats lose every digit).
- In-place clips (pwalk / prun / turns): move the body by the travel read from the planted feet (ClipData root_v), not
  by the converter's vz / vx (they do not match the feet: hitches, 6-12 cm slides).
- Foot contacts for a clip: by height near the local lowest + small vertical speed. Not by level speed (that needs the
  travel, which is what the contacts are used to find).
- A test's own contact guess (height + speed) counts a slowly dragged toe as a slide: use the clip's contacts.
- ...and read them for the SAME frame as the pose: the motor steps (and seeks) before the frame's last pose is drawn;
  read at the next frame's first pose they are a frame ahead (a 7 m/s swing foot = 12 cm false slide).
- Slide alone is blind with a foot lock on (the lock holds it): also measure PULL (lock vs clip foot) once a hand-over
  is over. During a hand-over the pull is the lock doing its job.
- The converter's yaw curve and the pose can both carry the same turn: judge at the curve's largest turn, not its end.
- Clips at 30 Hz played with linear interpolation kink at every key in fast turns: the motor sets cubic.
- Never trust the capsule's height for drawing: ray the ground (place()).
