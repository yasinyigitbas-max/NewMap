# Traversal work: handover (written 26 Nov 2026)

Yasin asked for this work to be handed to someone else. This file is written for that person. It says what exists,
what state it is really in, what is wrong with it, and what the previous session got wrong, so that none of it has to
be found out twice. Read it before `reports/TRAVERSAL STATUS.md` (the running log) and `traversal_lab/README.md`.

## 1. The short version

- **Goal (Yasin):** a robust, Rockstar-quality on-foot traversal system for the Coronado game (Godot 4.7.2, Jolt,
  Android first), built stage by stage from a sourced study, in a fresh self-contained project that is tied into the
  game later.
- **Where it is:** `traversal_lab/` on branch `claude/intelligent-bardeen-errnbs`. `main` stops at the commit
  `trav2` of 25 Nov; everything after it (15 commits) is on the branch only. Nothing is merged without Yasin's word.
- **How far:** stages 0 to 5 of the study's build order are built (course, body, import, idle / walk / run, feet and
  head, starts / stops / turns), plus stairs, steep slopes and walking off edges, which were added at Yasin's request.
  Crouch (6), detection (7) and every traversal move (8 onward) are not started.
- **Yasin's verdict on the last build (ninth exe, 26 Nov):** the slopes "look terrible again". He no longer trusts
  that the work follows the study, and he is right: section 4 lists where it does not.
- **Nobody but Yasin has seen this build move.** The previous session checked stills and frame sheets, never motion
  at full size. Treat every "looks fine" in the older notes as unverified.

## 2. Yasin's rules (his words; they stay in force)

- "do not attempt to salvage that study report. I dont want your info to be contaminated with it" (the earlier
  from-memory study, on other branches such as `claude/festive-faraday-20ltx2`: do not read it).
- "do not be influenced by anything in the game already."
- "do not forget to remind yourself of the movement study and acting according to it at every step."
- "MAKE DAMN SURE YOU TAKE THE STUDY INTO CONSIDERATION AT EVERY STEP! IF A MIXAMO CLIP VIOLATES IT EVEN IN IDLES,
  CHANGE IT WITH A KIMODO CLIP."
- "it would be better if you researched first and then ordered the clips."
- Kimodo prompts: no full stop inside a prompt (it starts a new motion segment); no decimals.
- He play-tests every exe himself: "whenever you need to have eyes on what you do, tell me."
- Raw Mixamo and Kimodo files stay out of git. No keys or secrets in files or chat. Push only to the work branch; no
  push to `main` and no pull request without his word. Commit and push after every step.
- Write to him in plain words; say what was not checked.

## 3. What exists and how to run it

| Thing | Where |
|---|---|
| The study (the authority) | `reports/Hybrid character traversal study.md` (810 lines: Part 1 findings, Part 2 design and build order, Part 3 clip measurements) |
| Sourced research notes | `research_notes/Hybrid character traversal study/*.md` (`steep_slopes.md` is the later side research on slopes) |
| The project | `traversal_lab/` (Godot 4.7.2, Jolt, 60 ticks); code in `traversal_lab/traversal/` |
| Body | `traversal/body/body.gd`: floating capsule, own ground probe and slide loop, speeds, turning, stairs and slope rules |
| Character | `traversal/character/character.gd` (which clip, at what time; start / stop / turn matching; stairs; slopes; drops), `feet.gd` and `foot_orient.gd` (foot IK), `clip_data.gd` |
| Baked clips | `traversal/character/clips/*.res` (in git; the build runs without the raw files) |
| Bake tool | `tools/build_clips.gd` (retargets raw FBX in `assets_src/clips/` onto player_v4, cuts loops; `-- --table` prints per-frame foot data) |
| Tests | `tests/test_stage0.gd`, `test_stage1.gd`, `test_turn.gd`, `test_starts.gd`, `test_feet.gd`, `test_study.gd` (SceneTree scripts; print PASS / FAIL lines and `RESULT`) |
| Renders | `tests/shot_moves.gd`, `shot_feet.gd` (stills), `tests/shot_climb.gd` (frames of a ramp climb or descent for ffmpeg) |
| Kimodo pipeline | `tools/kimodo/` (see its README) and `research_notes/.../clip_measurements/` (measurement tools and CSVs) |
| Log of Yasin's own Kimodo runs | `research_notes/.../clip_measurements/kimodo_takes_yasin_26nov.csv` |

Commands (cloud; Godot 4.7.2 headless):

    godot --headless --path traversal_lab --import                      # after adding or renaming any FBX
    godot --headless --path traversal_lab -s res://tools/build_clips.gd  # bake the clips
    godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_study.gd
    godot --headless --path traversal_lab --export-release "Windows" out/TraversalLab.exe
    xvfb-run -a godot --path traversal_lab --rendering-driver vulkan --fixed-fps 60 -s res://tests/shot_climb.gd -- --out=DIR --deg=45 [--down]

The long tests need about two minutes each. The bake hangs if a new FBX has not been imported first.

House rules for the code: LF endings, `preload` not `class_name`, cross-script access through `call(&"x")` and
`get(&"x")`, commit the `.gd.uid` files, never `git add -A`, commit messages `trav<n>: plain words`.

## 4. Where the build does NOT follow the study

These were found by reading the study against the code on 26 Nov. None of them was declared to Yasin when it was
made, which is the heart of his complaint.

| The study says (Part 2) | The build does |
|---|---|
| "One `CharacterBody3D` ... alone decides where the character is ... Animation never pushes it in this mode." In normal movement "the clips play to match the body's speed." | On steep slopes the clip sets the body's pace (`pace` and `steady` in `body.gd`, `DRIVEN` in `character.gd`), added on 26 Nov for Yasin's two takes. Walking a slope is normal movement, so this breaks the rule. **Undo this first.** |
| "One `AnimationTree` set to the physics tick", blend spaces with cyclic sync, clip alignment by `start_offset` | There is no `AnimationTree`. `character.gd` picks clips and computes every pose in code. Not recorded anywhere as a decision. |
| Layer 3 in a fixed order: pelvis offset, leg IK, arm IK, forearm twist disperser, look-at for spine, neck, head, an angular-velocity pop filter | Pelvis offset, leg `TwoBoneIK3D` and a left-arm `TwoBoneIK3D` exist. Look and lean are done in code on the pose. No twist disperser, no pop filter. |
| Slopes: "The right limit ... is not given by any source in the notes; choose it in Stage 1 on the test ramp." Two sentences on slope posture; trunk lean per degree and the maximum walkable slope are listed as not found. | Bands at 20, 35 and 50 degrees, climb rates, lean shares, the downhill easing and the 1.15 pace cap are from side research or invented. They are marked `NOT in the study` in the code, but several were presented to Yasin without that warning. |
| "Start with one clip per band and add variants only where a test shows a visible stretch." | Slopes went through five rounds of clip swaps and stacked corrections. |
| Record for every clip: travel, speed, heel-landing times, which foot is forward at start and end | Recorded for the Mixamo set (`player_v4_clips.csv`); not for most Kimodo takes. |
| Build order: "nothing starts until the stage before it passes" | Stairs, slopes and drops were built while stage 4 and 5 tests were still failing. |

The audit itself is weaker than it was described:

- `tests/test_study.gd` covers only walk, run and standing (27 lines). Yasin was told every behaviour would be
  checked.
- Several pass bars are wider than the study. These print PASS today: 113 steps a minute (study 115 to 120); pelvis
  turn 6 degrees (12); pelvis drop 11.8 degrees (8.5); walk knee peak 70 degrees (60); run hip bob 6.4 cm (8 to 9.5);
  arms opposite the legs 77 % of the time (always). Tighten the bars to the study's figures before trusting it.
- `tests/test_feet.gd` measures only ticks in which it takes a foot as planted. On steep ground it counts very few
  (3 on the 30 degree descent), so floating or sinking feet go unmeasured. A PASS there means little.

## 5. Test results on the last commit

| Test | Result |
|---|---|
| `test_stage0` | PASS |
| `test_turn` | PASS |
| `test_stage1` | 1 fail: 45 degree ramp with run held climbs 0.88 m/s of height (0.60 wanted). The ramp check was changed on 26 Nov from "steady speed" to "average climb rate within 30 %" to suit the pace-driven clip; put it back when that is undone. |
| `test_starts` | 1 fail: walk start, planted feet drift 2.7 cm (bar 2) |
| `test_study` | 1 fail: run knee peaks at 125 degrees (study 94 to 119). Mixamo run; Kimodo's fastest run was 2.8 m/s, too slow to replace it. |
| `test_feet` | 9 fail: flat walk drift 3.2 cm; all four going-down-stairs lines (feet 10 to 17 cm above the step); ramps 19, 30 and 45 degrees up (3 to 4.5 cm inside); 30 degrees down |

## 6. Slopes: the full story, because it is where the work went wrong

1. Yasin could not climb above 19 degrees and asked for steeper climbing with hands. Clips were ordered from Kimodo
   before the research was done; he corrected that.
2. Kimodo's text does not set a slope. Takes came out flat, at the wrong incline, or walking backwards. Takes were
   chosen by measured slope and stride, which gave clips with the right numbers that looked wrong ("a joke rather
   than a hard walk"; "we look like a small baby").
3. Each round added a correction on top of the last: the clip's own rise stripped, strides retimed, a trunk lean, a
   hand reach, foot IK. They interact. By the eighth exe Yasin saw "no feet touches the slope ... the guy just
   floats".
4. Yasin then wrote his own prompt on the Replicate page and got a clearly better climb at the first try. Lesson:
   describe a person and the struggle in one plain sentence; do not list measurements or instructions.
5. His uphill take (`KM_Climb_Hard`) and his long downhill take (`KMY_Down_Hands_Balance_Long`) were put in on
   26 Nov with: the clip driving the body's pace (wrong, see section 4); each foot fitted to the clip's own uneven
   ground (`clip_lump`) and laid level before fitting (`clip_pitch`). The measured foot error on the up ramps fell
   from 30 cm to 3 to 4 cm, but Yasin's verdict on the result was "they look terrible again".
6. Two real findings worth keeping: a generated clip does not walk an even slope (that uphill take's footfalls lie
   from 0.24 m under to 0.23 m over one), and it holds its feet tipped to its own slope. Any code that assumes an
   even plane under a Kimodo slope clip will float or sink the feet.

Not known: why the last build looks terrible to him. The previous session did not see it move and did not ask him
which part. Ask him, or film it at full size, before changing anything.

## 7. What the previous session got wrong (so it is not repeated)

- It said it would check the study at every step and worked from its memory of the study instead. After a context
  compression the study's text is gone unless the file is opened again.
- It reported an audit as covering everything when it covered three movements, and set that audit's bars loosely.
- It shipped builds on the strength of tests it had written itself and a few still frames, sometimes without
  re-running the tests.
- It answered Yasin's direct question about what was happening from memory until he called it out.
- It spent about 43 Kimodo prompts (roughly 100 takes) on Replicate, most discarded, on a problem that was in its
  own code and its way of choosing takes.
- It made decisions the study covers (who moves the body) without opening the relevant section.

A proposal was made to Yasin and not answered: hooks that enforce the study mechanically. (1) the compaction hook
prints the study's Part 2 itself; (2) a commit gate on `traversal_lab/` that refuses a commit unless it carries a
note quoting the study lines the change relies on, each quote checked word for word against the file, or the words
"the study is silent on this, the number is mine"; (3) the audit run in that gate with bars at the study's own
figures and a waiver list only Yasin edits. None of it is built.

## 8. Things that exist only outside git

| What | Where | Risk |
|---|---|---|
| Raw clips the bake reads (42 FBX: the Mixamo ones in use and the chosen Kimodo takes) | `traversal_lab/assets_src/clips/` in the old cloud session; a zip (`traversal_raw_clips.zip`, 20 MB) was sent to Yasin on 26 Nov | The session's disk is temporary. Without these the clips cannot be re-baked; the baked `.res` files in git still run. |
| All other Mixamo clips for player_v4 | Yasin's Drive folder `player_v4` (link in `TRAVERSAL STATUS.md`) | none |
| Yasin's own Kimodo runs | his Replicate history, listed with run ids in `kimodo_takes_yasin_26nov.csv` | Replicate may not keep outputs for long |
| The other roughly 100 Kimodo takes | the old session's scratch disk only | lost with it; none is worth keeping |
| The target character file for Kimodo (X Bot, Mixamo rig) | sent to Yasin on 26 Nov as `character.fbx`; the copy uploaded to Replicate expires 26 Nov 17:15 UTC | upload it again after that |
| Windows exe builds | sent to Yasin; not kept | rebuild with the export command |

Logins: Mixamo is reachable only on Yasin's PC. Replicate and Sketchfab go through the session proxy (no key needed;
the scripts send a dummy bearer value that the proxy replaces). The Meshy key is a network secret.

Yasin now runs Kimodo himself on the Replicate page (`sprited/kimodo`): model `Kimodo-SOMA-RP-v1.1`, the character
file in `custom_fbx`, `output_format` `all`, 3.5 s. His takes are named `KMY_...`, the earlier ones `KM_...`.

## 9. Suggested order of work

1. Ask Yasin what exactly looks terrible on the slopes, or film both ramps at full size and look.
2. Put the body back in charge on slopes (remove `pace`, `steady`, `DRIVEN`, and the changed ramp check), as the
   study requires. Decide with him whether the hands-down climb belongs in normal movement at all, or is a traversal
   move, where the study does let the clip drive the body.
3. Build the gates in section 7 if he wants them, and tighten the audit's bars to the study.
4. Settle the `AnimationTree` question with him: move to it as the study says, or record the code-posed approach as
   a decision he has agreed to.
5. Fix what fails on flat ground and stairs before more slope work: walk plant drift, the run knee, going down stairs.
6. Then the study's order: crouch (stage 6), detection (stage 7), one traversal move per stage from stage 8. The
   study's list of missing clips is in Part 3 ("Going up", "Vaults", "Going down").

## 10. Waiting on Yasin

- What looks terrible in the ninth exe.
- Whether to build the enforcement gates.
- Whether to merge the work branch into `main`.
- Whether walking down steep ground at about 0.7 m/s (the take's own pace) is acceptable; that cap is not sourced.
