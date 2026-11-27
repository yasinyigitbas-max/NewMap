---
name: coronado-traversal
description: The player's and the NPCs' movement in the traversal lab (traversal_lab/, native/traversal/) - how a move is built and proven, the study gate, the C++ port and its parity proof, NPC bodies from Meshy, the exe for Yasin's play-test, and the traps that cost hours in the 26-27 Nov 2026 sessions. Read before touching traversal_lab/, native/traversal/, tools/traversal/, assets/people/meshy/, or before telling Yasin anything about movement is done. Use for "fix this move", "add a move / a clip", "make it C++", "add an NPC body", "send me an exe", "why does parity fail", carry / weapon / hand-held props.
---

# Coronado traversal: how the work is done

Read in this order, every session and again after every context compression (Yasin's rule):
1. `reports/TRAVERSAL JOB BOARD.md` - the queue, his rules and decisions, what is waiting on his eyes.
2. `reports/Hybrid character traversal study.md` - ALL of it (about 810 lines; read it in three parts, the Read tool
   refuses it whole) - and `traversal_lab/study/README.md`. The study is the authority ("LIKE THE HOLY BOOK").
3. `reports/TRAVERSAL STATUS.md` (checkpoints; how to fall back) and `reports/TRAVERSAL HANDOVER.md`.

## His rules that decide most things

- **Change only what he points at.** No change that touches every clip, nothing "improved" on the way, nothing
  approved broken. A fix is one thing changed.
- **The checks are locked.** `traversal_lab/study/bars.json` and `tests/audit.gd` change only at his word (commit
  lines `Checks-changed:` and `Yasin: "..."`). If a line fails, fix the movement, never the line.
- **A number the study does not give** is marked `NOT in the study` in the code and told to him as mine.
- **Everything that runs in a tick is C++** (his ground rule). Tests and tool-time scripts may be scripts.
- **The player is protected.** NPC code lives apart (`traversal/npc/`, `trav_npc.*`). A change inside a file the
  player uses is shown to him first.
- **Reports:** plain words, short, what was NOT checked, what was not seen in frames. Never a result before its
  output has been read.
- Ragdolls (stages 19, 20) wait for his go. The phone pass comes last.
- "Looking fine" is not "make it the default": a default changes only when he says so in so many words.

## The loop for any change in traversal_lab/

1. Make the one change.
2. Run everything, in the background, with the tree frozen (do not edit traversal_lab/ or rebuild the library while
   they run: the audit stamps a fingerprint of the tree, and a running godot has the .so open):
   - every `tests/test_stage*.gd` (stage 1 with `-- --minutes=10`), `tests/test_sit_phone.gd`, then the audit:
     `godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/audit.gd`
   - the same again with `-- --native`.
   The stage tests can run side by side; the audit runs alone, last. About 25 minutes a pass.
3. Read the results: every test `RESULT PASS`; the audit 26 of 114, THE SAME LINES (diff the `^FAIL` names against
   the last known list; the count alone is not enough).
4. Commit: stage `traversal_lab/study/audit_result.json` with the change. Message `trav<n>: plain words`, his words
   quoted, what was proven, what was not done, `No new number.` or the numbers that are mine, and
   `Study: "<a sentence of the study, word for word>"`. The gate (`.githooks/commit-msg`) checks the quote against
   the file, checks the audit ran on this exact tree, and writes the audit line itself. For a number the study
   does not give: `Study: the study is silent on this, the number is mine` + `Yasin: "<his words>"`.
5. Push to the work branch only. `.gd.uid` files in a follow-up `trav<n>b` commit. Never `git add -A`.
   Raw Mixamo / Kimodo files (`traversal_lab/assets_src/`) never go into git.
- Files outside traversal_lab/ (native/, tools/, reports/) are not gated: commit them at once, so that the stop
  hook's "uncommitted changes" is only ever about what is waiting on the audit.

## How a move is built (the study: "align, play, fit, hand IK, hand back")

- A `_try_x()` reads the detector's record, refuses with a plain-word `refused`, or fills `_plan` and calls
  `body.begin_move(callable, input)`. The callable `_x(t)` returns where the body is at `t`: `pos`, `yaw`,
  `clip_t`, `air`, `free` (feet not fitted), `hand` (holds), `base`, `done`, `exit`.
- The take's own hip path, measured at `_ready`, carries the body; it is stretched to what was measured, never the
  other way round. Hands are held on the measured place by `hand_place` from contact to release.
- Clip facts (when a foot leaves, where the take's edge is) are read off the take in the lab and written next to
  the constant with where they came from.
- A hold on a thing in the hand (the phone) is refitted at modifier time (`_phone_refit`), not from last tick's pose.

## The C++ port (native/traversal/)

Script and C++ live side by side. Since trav96 (27 Nov, his word) C++ is the default and `-- --script` asks for the
scripts (`main.gd`, `_made()` in character.gd); without the built library the lab falls back to the scripts. The
readout's first line says which is running. So "every test" is: plain (C++), then again with `-- --script`. New
moves are written in C++ only; the scripts are the frozen fallback of what was approved up to trav95.

**Build.** `bash native/traversal/build.sh linux|windows` -> `traversal_lab/bin/` + `traversal.gdextension` (not in
git). A fresh container has no toolchain: `pip install --break-system-packages scons`; clone godot-cpp branch 4.5
(commit 27d9dd2) into `OUT/native_tools/godot-cpp`; `scons -j4 platform=linux arch=x86_64 target=template_debug`
(25 minutes); for Windows `apt-get install -y g++-mingw-w64-x86-64` and
`scons platform=windows use_mingw=yes arch=x86_64 target=template_debug`; then
`godot --headless --path traversal_lab --import` once.

**Translating a script, line for line** (eleven files so far, each byte for byte the same):
- GDScript `float` = C++ `double`. A Vector3's parts are 32-bit: widen each with `D()` before arithmetic, narrow
  on the way back. Vector3 times a scalar goes through `mul()` (the scalar is narrowed, as GDScript does).
- wrapf, lerpf, clampf, lerp_angle, rotate_toward, move_toward, smoothstep, fposmod: the engine's own formulas in
  doubles (`trav_math.h`, or local to the file), never godot-cpp's float versions.
- godot-cpp hands back some engine doubles as floats: `Animation::get_length()` must be read `a->get("length")`.
- Same names. Everything another script reads by name is served by `_get` / `_set`; a child class's `_get` calls
  the parent's on a miss. Every function handed to `begin_move` or called by a test is bound.
- Constants: made from the script by a small Python tool into `*_consts.inc`, `*_ctor.inc`, `*_get.inc`. Never
  copied by hand.
- `Dictionary.merge()` without overwrite keeps an existing key: translate it key by key with "only if missing".
- A C++ `dict["key"]` on a missing key PUTS THE KEY IN; the script stops with an error (and its exported game
  reads nothing and goes on). Where a key may be missing, ask `has` first, and do as the script does in the tests.
- Classes newer than the 4.5 bindings (TwoBoneIK3D, blend-space sync mode) are made with
  `ClassDBSingleton::instantiate` and driven with `call` / `set`.
- Windows names to keep off: `near`, `far`.

**Proof of a layer, all three read after the runs:**
1. `bash tools/traversal/parity.sh <folder>` says `PARITY RESULT PASS`: the same input on both versions, four runs
   (every station x walk / run / crouch / jump; two random runs; every station with the act key), 203,200 ticks,
   compared byte for byte: the body's numbers, the detector's records, every bone's finished pose, each move's
   plan. `EXTRA="--npc=npc_04"` runs it on an NPC body. When a new layer goes in, add ITS numbers to
   `tests/parity_run.gd`, and check the run really exercises it (it prints how many moves were begun: a run that
   begins none proves nothing; the first act-key run began 2).
2. Every stage test with `-- --native`.
3. The audit with `-- --native`: 26 of 114, the same lines.
Then the same tests on the scripts, then the Windows build.
- A parity difference of 1e-7 is a float where a double belongs. A difference in one hash column is a text
  (`refused`) or a key that one side has and the other has not.

## NPC bodies (Meshy)

- Recipe: `python3 -I tools/traversal/make_npc.py <name> <height> "<description>"` (41 credits a body: the player
  concept redrawn as another person with the arms STRAIGHT OUT, image to 3D at 5,000 triangles, rigging on the
  mixamo skeleton with fingers), then `godot --headless --path traversal_lab -s res://tools/build_npc.gd --
  --name=<name>` twice with `--import` between. Who each body is: `assets/people/meshy/cast.json`.
- Meshy calls carry `Authorization: Bearer dummy`: the proxy puts the key in. No key in a file or in chat.
- Meshy's rigger is not steady: 32 to 74 bones, extra bones of its own, sometimes no fingers. `build_npc.gd`
  re-poses each onto the player's 66-bone standard and prints what it did. Arms held low fuse the sleeve to the
  shirt; extra arm bones mapped to the chest "break" the arms: look at every new body in frames.
- NPCs use the player's clips unchanged; `body_fit` puts the hips where their own legs need them and gives them
  their own stride. See one in the lab: `-- --npc=npc_04`.
- Kimodo takes the rest pose from the character file it is given (`custom_fbx`): give it his Mixamo body WITH skin
  in its T-pose (every bone rotation zero). Given a take as it was, every result came back with the arms spread.
  A 37-byte or broken upload makes its FBX step crash (SIGSEGV in the prediction's error). The upload lasts a day.
- New takes are baked with a copy of `tools/build_clips.gd` pointed at their own folder, so that no existing clip
  is baked again; after `tools/build_library.gd` check that every animation the library had is the same key for key.
- Mixamo is reachable only on Yasin's PC. Kimodo (Replicate) and Meshy are reachable from the cloud.

## The exe for his play-test

1. `godot --headless --path traversal_lab --export-pack "Windows" <folder>/lab.pck`; start the pack from an EMPTY
   folder (`godot --headless --main-pack lab.pck --fixed-fps 60 --quit-after 1200`), with and without
   `-- --native`; count `SCRIPT ERROR` (must be 0). For the C++ run the Linux library must be in `<folder>/bin/`,
   or it falls back to the scripts without failing (an `ERROR: Can't open dynamic library` line says so).
2. `--export-release "Windows" <folder>/TraversalLab.exe` (the dll lands beside it); add the two start files
   ("Start C++ version.bat" runs `TraversalLab.exe -- --native`); zip to `traversal_lab/out/TraversalLab_trav<n>.zip`
   and send it with SendUserFile.
3. Say what could not be checked: no Windows here, so the dll's first run is on his PC.

## Looking at it

Copy a shot script to `traversal_lab/tests/zz_shot.gd`, run
`xvfb-run -a godot --path traversal_lab --rendering-driver vulkan --fixed-fps 60 -s res://tests/zz_shot.gd -- --out=<png>`,
read the picture, delete the zz file (and its .uid) before any audit. A pose is not "right" until it has been
seen in a frame; say which frames were looked at.

## Traps that cost time

- Editing traversal_lab/ or rebuilding the library while a suite runs: the audit's fingerprint no longer matches,
  or a running test loses its library.
- `rm -f $VAR/*` is blocked in this shell: use literal paths.
- A suite summary that only counts failures hides a changed list: diff the names.
- A patch by line number after another edit lands in the wrong place: match on exact text and assert one match.
- The Read tool refuses the study whole: `limit` / `offset` in three parts.
- The stop hook asks for a commit while the audit is still running: commit what is not gated, wait for the rest.
