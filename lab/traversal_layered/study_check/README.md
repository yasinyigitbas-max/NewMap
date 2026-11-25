# study_check: the judge of lab B (LOCKED)

Built 25 Nov 2026 by the session that wrote the study, after Yasin asked "how do we force them to keep the study file
in mind at every step?". The rules for the lab are in `RULES.md`; this file is for Yasin and the overseer.

## Pieces
| File | What |
|---|---|
| `native/src/study_check.*` | `StudyCheck`, a SkeletonModifier3D validator (study 9.1, 11.2), C++ (GDExtension of its own, so the lab's code can't change it) |
| `study_check.gdextension`, `native/bin/*.dll` | the Windows library (built on Yasin's PC); the Linux one is built by `check.sh` in the cloud |
| `tests/mutation.gd` | 196 cases (9.2): calibration of every axis (rest 0, +30, -10 checked by geometry) and the broken-pose table, both sides, T- and A-pose, random yaw / tilt / hip rotation |
| `tests/fuzz.gd` | seeded free play on the lab's own player (9.3) |
| `tests/rate_compare.gd` | the same input at 60 / 30 / 20 / 144 fps must give the same pose (1 deg / 1 cm) |
| `check.sh` | the gate: lock, build, mutation, free play; `quick` ~1 min, `full` ~8 min |
| `hooks/*.sh` | wired in `.claude/settings.json`: rules at every session start and compression, locked files, the push gate, the stop rule |
| `SCOPE` | `flat` (open ground) until the locomotion passes; then `course` |

## The lock
`check.sh` compares `study_check/`, `STUDY.md`, the lab's `CLAUDE.md` and `.claude/settings.json` with
`origin/lab/checker` and fails if any differ. The lab session is told never to push to `lab/checker`. This is
tamper-evident, not tamper-proof: a session could still rewrite a hook script; `git diff origin/lab/checker --
<those paths>` on lab/layered shows it at once.

## Checked on 25 Nov 2026 (Windows, Godot 4.7.2)
- Mutation tests: PASS at 20, 30, 60 and 144 fps with four seeds (196 cases each). They found and fixed four bugs of my
  own before anything was handed over: inversion measured against the pelvis (a leg swung out read as a rolled ankle),
  the toe joint measured from the ball, low-frame-rate fits smoothing a 5 cm hip drop away, and the test harness
  teleporting under physics interpolation.
- Rest pose on the ground: 0 violations.
- The raw Mixamo files on their own skeleton (no retargeting, sole points from the foot bones, `sole_mode=bones`):
  walk: knee twist up to 22 deg near straight (limit 5) and pops only at the loop seam; run: knee varus 9.4 (8), lumbar
  twist 21 (10), wrist 34 sideways, pops up to 9 deg at foot strike (30 fps keys, linear interpolation); slow run:
  ankle up 43-45 (40), fingers 96 (90). The study's limits are kept; the lab cleans the clips at build time.
- Lab B's code at faab9966b (25 Nov, 14:31; its locomotion is still the 9f5ca0b91 one), the whole gate on Yasin's PC:
  quick 31 s, full 4 min 47 s, both FAIL. In 30 minutes of free play at 60 fps it breaks 35 rules, among them: knee out of
  plane up to 39 deg, ankle rolled out up to 62 deg, foot twisted 60, knee twisted 76, trunk folded 59 deg beyond the
  whole-body lean, the CoM accelerating sideways at up to 203 m/s2 (limit 8.85), feet hovering or sinking on thousands of
  frames, turns at 640 deg/s where 92 is the limit. Frame-rate agreement: with the input fed per physics tick the
  capsule is identical to the millimetre at 30, 60 and 144 fps, but the drawn pose differs by up to 35 deg: the pose
  layer depends on the frame rate.

## What it can't see
How the motion looks (frame strips beside reference footage, 9.4), skin problems (the waist pinching), feet crossing
under the body, wet ground, hands in traversal (no hand contacts yet), and anything outside the scope. Wrist and finger
signs assume this body's palms face down at rest (checked by the mutation tests only for this body).
