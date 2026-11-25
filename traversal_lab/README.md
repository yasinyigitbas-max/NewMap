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
| 2 | import player_v4 and three clips; one climb clip to settle upward travel | next |

## Stage 0: what to look at
The automatic test already measures every obstacle against its label and checks that a replay repeats exactly.
What it cannot see, and Yasin should check once by walking the course with `]`:
1. Every station shows its label and the label is readable.
2. The readout (top left) changes as you move: state, speed, height, and the green height graph.
3. Record a short walk (F5, walk, F6), press F7 twice: the body takes the same path both times.


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
| people slow down and lean into curves (6.8 deg at normal walking speed); the turn clips curve 36 deg a stride | the path curves no faster than that: about 50 deg a second at a walk, 40 at a run |
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
6. **Weight**: this is the main one. Starting takes about a step, stopping from a run takes a few strides, and it turns
   in an arc, not on a pin. Say if that feels too heavy or too light; those three values are easy to change.
