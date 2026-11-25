# Traversal lab

A self-contained Godot 4.7 project for building the player's movement and traversal one tested stage at a time
(`reports/Hybrid character traversal study.md`, Part 2). Jolt physics, 60 ticks a second. The code is in
`traversal/` (`res://traversal/`), so it can be copied into the game at the same path when it is ready.

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

It must end with `RESULT PASS`.

## Stages
| Stage | What | State |
|---|---|---|
| 0 | the measured course (62 stations), the readout, record / replay | automatic test passes; needs Yasin's eyes once |
| 1 | the body alone (capsule): kerbs, stairs, ramps, walls, ledges | next |

## Stage 0: what to look at
The automatic test already measures every obstacle against its label and checks that a replay repeats exactly.
What it cannot see, and Yasin should check once by walking the course with `]`:
1. Every station shows its label and the label is readable.
2. The readout (top left) changes as you move: state, speed, height, and the green height graph.
3. Record a short walk (F5, walk, F6), press F7 twice: the body takes the same path both times.

The body in Stage 0 is a plain stand-in (it will get stuck on steps; that is expected). Stage 1 replaces it.
