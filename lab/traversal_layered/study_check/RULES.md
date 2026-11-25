# Lab B: the rules that are enforced (printed at every session start and after every context compression)

**LOCKED.** Written by the session that wrote the study, on Yasin's order (25 Nov 2026), after two builds that ignored
the study. You may not edit anything in `study_check/`, `STUDY.md`, `CLAUDE.md` (this folder's) or `.claude/settings.json`:
the hooks block it and the gate compares them with `origin/lab/checker`. Disagree with a rule? Write it in STATUS.md for
Yasin. Never work around it.

## Yasin's words
- "both results are terrible" (the 25 Nov builds); "a posture like this was supposed to be impossible ... knee is bent
  backwards, ankle looks broken, ... lean while running reaches 70 degrees."
- "how do we force them to keep the study file in mind at every step?" This file and the gate are the answer.

## The law
`STUDY.md` (the human-movement study, version 2) is the specification. Part 0.1's seven rules, in short:
1. Measure the **final drawn pose**, never a target or a variable. 2. Signed angles on **every axis**.
3. Every check must be **shown to fail** first. 4. **Free play**, not scripts. 5. **Look at it** (frame strips beside
reference footage) before anyone plays it. 6. Hard rules **enforced in code**: a final limiter, which must have
**nothing to do** in testing. 7. **Physics before poses**: the controller never asks for a path a body can't do.

## The judge: `study_check/` (not yours)
- `StudyCheck` (C++, `study_check/native`) is the validator of study 9.1 and 11.2: a SkeletonModifier3D placed last on
  the body's skeleton. It measures the drawn pose in world space and tests the HARD limits (knees, ankles on three axes,
  sole against the ground, hips with rotation, spine, neck, shoulders, elbows, wrists, fingers, joint speeds, pops,
  centre of mass, the three leans, turn rate, cuts, stops, flight, contacts, slides, bone lengths, limbs through the body
  and the world, the limiter's work).
- `tests/mutation.gd`: 196 broken and calibrated poses; it proves every rule fires (9.2). It runs first; if it fails,
  nothing else counts.
- `tests/fuzz.gd`: seeded free play on YOUR player (9.3): stick changes, reversals, circles, flicks, run and stop spam,
  camera spins to 720 deg/s, hitches, 20 / 30 / 60 / 144 fps, and the frame-rate agreement.
- `check.sh quick` (about 1 minute) and `check.sh full` (about 8 minutes) print `GATE RESULT PASS` or `FAIL`.

## How the gate is enforced (hooks in .claude/settings.json)
- **Session start / after compression**: this file is printed. Read it, then STUDY.md's parts for your current step.
- **Before `git push`** of anything that can reach `lab/layered`: `check.sh full` runs; a FAIL blocks the push. Push
  work in progress to `lab/layered-wip` instead (allowed in any state). Only a PASS reaches Yasin's branch.
- **Before editing a locked file**: blocked.
- **When you stop**: if your code changed since the last gate run, stopping is blocked until you run
  `bash lab/traversal_layered/study_check/check.sh quick` and put its summary in your report.

## Your interface to the judge (required)
- The player node has `get_contact(side) -> bool` (the foot is meant to be planted) and may have
  `get_check_state() -> String`: `"loco"` (walk, run, start, stop, turn) unless it is truly crouching, climbing,
  vaulting, landing (at most 100 ms after a contact) or in a ragdoll. The report prints the time spent in each state.
  A state used to dodge a rule is cheating.
- The final limiter (10.2), when you have one, is a SkeletonModifier3D **class named `FinalLimiter`**, node name
  `FinalLimiter`, direct child of the skeleton, just before the end, with `get_clamp_count() -> int`. The gate puts a
  "pre" checker just before it and fails any frame where it changed a knee, ankle, sole, hip rotation or lean by more
  than 1 deg, or changed other joints on more than 0.01 % of frames.

## How to work (in this order, study 10.1 and 9.6)
1. Before writing code for a step, read the STUDY.md parts it touches and list in DECISIONS.md, per decision, the
   section it follows.
2. Build in the pipeline order of 10.1: controller limited by Part 3 -> base motion -> warping -> one lean source ->
   flight correction -> pelvis and leg IK (10.3 pole, soft reach) -> upper body -> FinalLimiter -> (the judge).
3. After every change: `check.sh quick`. Fix what it reports at the stage that causes it (never in the limiter).
4. A step is done only with `check.sh full` PASS, then the visual check (9.4: frame strips, side and front, beside
   reference footage, described in STATUS.md against Part 8), then Yasin plays it. Say what the checks can't see.
5. The source clips themselves break some rules (measured on the raw Mixamo files, on their own skeleton, 25 Nov):
   the walk's knee twists 22 deg near straight (limit 5), the run's knee goes 9 deg out of plane (limit 8) and its
   lumbar twists 20 deg (limit 10), the slow run's ankle reaches 43-45 deg up (limit 40), the wrists 21-34 deg sideways
   (limits 20 / 35), the fingers 95 deg (limit 90), and the 30 fps keys make corners (3-9 deg pops) at the run's foot
   strike and at every loop seam. Clean them when you build the clip cache (resample, remove shin twist, blend the
   seam, redistribute the spine); the judge measures what is drawn.

## Scope
`study_check/SCOPE` says which part of the world free play covers: `flat` (open ground, step 4) now. Yasin or the
overseer moves it to `course` when the locomotion passes; you don't.
