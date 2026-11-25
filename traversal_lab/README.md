# Traversal lab

A self-contained Godot 4.7 project for building the player's movement and traversal one tested stage at a time
(`reports/Hybrid character traversal study.md`, Part 2). Jolt physics, 60 ticks a second. The code is in
`traversal/` (`res://traversal/`), so it can be copied into the game at the same path when it is ready.

## Working rule: the movement study first, at every step (Yasin, 25 Nov)
"do not forget to remind yourself of the movement study and acting according to it at every step."
Before building or changing anything in a stage:
1. Re-read the part of `reports/Hybrid character traversal study.md` that the stage touches (Part 1 for how people
   move, Part 3 for this character's own measured numbers).
2. Every number in the code that describes movement carries a comment saying which finding it follows. A number the
   study does not give is marked `NOT in the study` and is a value to tune by eye, never passed off as sourced.
3. The stage's table below lists what the study says and what the code does, so the two can be compared.

## Run it (PC)
Open this folder (`traversal_lab`) as a project in Godot 4.7.2 and press Play, or:

    Godot_v4.7.2-stable_win64.exe --path traversal_lab

| Key | Does |
|---|---|
| W A S D / left stick | move (relative to the camera) |
| Shift | run |
| mouse | look round; Esc frees the mouse |
| `[` and `]` | previous / next station |
| R | back to the start of this station |
| F5 / F6 | start / stop recording your input |
| F7 | replay the recording from where it began |
| F8 / F9 | save / load the recording |

## Automatic test

    Godot_v4.7.2-stable_win64.exe --headless --path traversal_lab -s res://tests/test_stage0.gd
    Godot_v4.7.2-stable_win64.exe --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage1.gd -- --minutes=10

Each must end with `RESULT PASS`. `--plain` after `--` runs the lab with the old stand-in body.

## Stages
| Stage | What | State |
|---|---|---|
| 0 | the measured course (62 stations), the readout, record / replay | automatic test passes; needs Yasin's eyes once |
| 1 | the body alone (capsule): kerbs, stairs, ramps, walls, ledges | automatic test passes; **needs Yasin's eyes** |
| 2-3 (first pass) | player_v4 on the body with idle, two walks, jog, run and a jump | built, seen in pictures; **needs Yasin's eyes**; no automatic test yet |

## Stage 0: what to look at
The automatic test already measures every obstacle against its label and checks that a replay repeats exactly.
What it cannot see, and Yasin should check once by walking the course with `]`:
1. Every station shows its label and the label is readable.
2. The readout (top left) changes as you move: state, speed, height, and the green height graph.
3. Record a short walk (F5, walk, F6), press F7 twice: the body takes the same path both times.


## The character (first pass of Stages 2 and 3)
Built early, out of order, because a bare capsule with no jump could not be judged (Yasin, 25 Nov).
- `traversal/character/player_v4.scn`: Mixamo's rig of player_v4 (65 joints, full fingers), made by
  `tools/build_character.gd` from the rigged FBX. The raw FBX and the raw clips stay in `assets_src/` (not in git).
- `traversal/character/clips/*.res`: clips baked onto his skeleton by `tools/build_clips.gd`, a rotation per bone per
  frame plus the hips' path. No Blender step and no root bone: the travel is taken out when the clip is sampled.
- `traversal/character/character.gd` poses the skeleton. It only looks; the body alone decides where he is.
- Moving: the two loops either side of the body's speed are blended at the same point of the stride, and the stride
  advances by distance covered, so the feet keep pace with the ground. Clip speeds on him: slow walk 1.07 m/s, walk
  1.76, jog 2.53, run 5.82.
- Jump: a push-off first (0.30 s standing, as the study gives for the push-off of a standing jump; 0.10 s from a run,
  the take-off time of the Running Jump clip), then the body rises 0.45 m (an average standing jump raises the body
  0.41 to 0.50 m). The pose comes from the `Jump` clip; landings from `Falling To Landing` and `Hard Landing`.

- Arms (Yasin's play-test, 25 Nov: "his arms are almost sticking to his body"): each upper arm is swung 9 degrees out
  from the chest (`arm_open_deg`; set by eye, not from the study). The clips were captured on a slimmer body.
- Lean: he leans into a turn by tan(lean) = speed x turn rate / g, capped at what was measured on people (6.8 degrees
  at a normal walk, 13 at a run).

Not done yet, and known: no automatic test of foot sliding; no start, stop or turn clips (the body's speed changes
but the legs just blend); no foot IK on stairs and slopes; no running-jump clip (missing from the download);
he can still steer during a landing.

## Stage 1: the body alone
`traversal/body/body.gd`. A floating capsule: the capsule covers the body from 0.32 m above the feet to the top of
the head, and one short downward sphere probe finds the ground, so kerbs and stair risers pass under it. The thin
"leg" under the capsule in the lab is only there to show the float.

What it does not use, and why: `move_and_slide()` (under Jolt it has no stair stepping, unreliable floor flags, and
in floating mode it keeps full speed along a wall), so the body slides by its own rule.

| The study says | The body does |
|---|---|
| comfortable walking 1.3 to 1.45 m/s; running 2.5 to 4.5 m/s | walk 1.4, run 4.5 (Stage 3 replaces these with the clips' own speeds) |
| a walk reaches about 90 % of its speed on the first step, steady by the third | 90 % of walking speed after about 0.55 s |
| a walk stops in under two steps | stops from a walk in 0.6 s |
| stopping from a flat-out run: 5 steps, 2.9 m | brakes at 6.2 m/s2 from a run: 0.73 s and 1.6 m from 4.5 m/s |
| a sharp turn is a step or spin turn of about 75 deg a step, made within one step; his Walking Turn 180 clip takes 1.00 s and Running Turn 180 0.67 s; over 300 deg a second is outside the data | the heading turns at 180 deg a second at a walk and 270 at a run (`tests/test_turn.gd`: a right angle in 0.47 s walking, 0.30 s running). The first version used the gentle-curve figure (36 deg a stride) for every turn, which Yasin found "very very slow" |
| people slow to turn (0.96 m/s on a 1 m circle against 1.61 straight) and a sudden turn starts with braking | up to 40 % of the speed is given up in a right-angle turn; a turn-round at a run brakes to 2.0 m/s first (that 2.0 is not from the study) |
| people lean into a corner by 4.4, 6.8 and 12.7 deg at slow, normal and fast walking; 13.6 deg on a sprinted curve | the figure leans about its feet, capped at 6.8 deg walking and 13 running |
| people do not reverse at speed | asked to go nearly the opposite way, it brakes first |
| kerbs 0.10 to 0.20 m, risers to 0.25 m are walked over; 0.30 m is the top of "walk over it" | anything up to 0.30 m is stepped onto, 0.35 m and above is a wall |
| real streets reach 19 deg | walks 19 deg; ground steeper than 28 deg cannot be stood on (the 28 is NOT in the study) |
| steps to reach a run: not found | 0.6 s time constant, marked as a value to tune |

On steep stairs the feet can only follow the ground so fast, so the body slows down at a run, going up and down.

### Stage 1: what to look at (Yasin)
The automatic test checks heights, speeds, states and a ten-minute random walk. What it cannot judge is the feel:
1. **Kerbs and stairs** (stations 1 to 3, 15, 16): walk and run up and down. The body should rise and sink smoothly,
   with no hop and no hitch at the top or bottom.
2. **Single steps** (stations 4 to 14): it climbs up to 0.30 m and is stopped dead by 0.35 m and higher.
3. **Ramps** (17 to 21): 5, 10 and 19 degrees are walked at a steady speed; on 30 and 45 it cannot climb and slides back.
4. **Walls** (22 onward): run into one head-on and at an angle. It should stop or slide along, with no shaking.
5. **Ledges** (stations 15, 16): walk up the stairs and off the side of the top landing. It should fall at once
   and land without a bounce. Walking off a kerb should be a step down, not a fall.
6. **Weight**: this is the main one. Starting takes about a step, stopping from a run takes a few strides, and a
   turn takes about a step (a turn-round at a run brakes first). Say if that feels too heavy or too light.
