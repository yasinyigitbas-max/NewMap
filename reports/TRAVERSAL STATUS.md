# Traversal work: where we are (read this first after a break or a context compression)

Last updated 25 Nov 2026, session "Traversal system research and design". Merged to `main` on 25 Nov at Yasin's word ("merge the branch to main"); later work continues on branch `claude/intelligent-bardeen-errnbs`.

## What Yasin asked for
A robust Rockstar-style traversal system for the game (Godot 4.7, Jolt, Mixamo clips), after five failed attempts. He asked for a study from real sources first. Two rules he set:
- **Do not use or salvage the earlier human-movement study** (it was written from memory). It lives on other branches (for example `claude/festive-faraday-20ltx2`); do not read it.
- **Do not be influenced by what is already in the game.** The old player code, the `lab/*` branches and the old animation skill were not read, on purpose.

## What exists (on main)
| File | What |
|---|---|
| `reports/Hybrid character traversal study.md` | the report: Part 1 findings, Part 2 design and staged build order, Part 3 measurements of the clips and the character |
| `reports/Mixamo rig and re-download.md` | PC instructions: rig player_v4 on Mixamo, re-download clips for him in four batches |
| `reports/Mixamo download list.md` | older list of 17 missing clips; done, the clips are in Drive |
| `research_notes/Hybrid character traversal study/*.md` | the six sets of sourced research notes |
| `research_notes/.../clip_measurements/` | `clip_measurements.csv` (426 clips), `catalogue_candidates.csv`, `kimodo_clips.csv`, and the tools: `measure_clips.py`, `fbxp.py`, `fbxrw.py`, `clean_kimodo.py`, `fix_kimodo.py`, `glb_skeleton.py` |
| `assets/people/meshy/player_v4/` | the new character made on Meshy: concept, unrigged mesh, Meshy's Mixamo-skeleton rig, and the zip to upload to Mixamo |

## Decisions made
- **Architecture (report Part 2):** four layers (code-driven body, clips, IK corrections, ragdoll for impacts only); floating capsule first, full-height capsule with a step sweep as the fallback; one traversal move per stage; every stage has a visible pass/fail test.
- **Character:** the player is the Meshy man. `player_v3` (branch `claude/cool-galileo-6y68se`) has a lopsided skeleton. `player_v4` was made on 25 Nov: same look, symmetric, flat shoes. Meshy's rigs always come out with legs about 0.75 m and arms about 0.47 m, 15 % shorter than X Bot, the body all clips were made on.
- **Route 1 chosen by Yasin (25 Nov):** Mixamo rigs player_v4 and the clips are downloaded again for him, on the PC.
- **NPCs** keep the X Bot clip set and are retargeted in the game.
- **Bonnet slide:** no clip exists (Mixamo has none, Kimodo failed); left out for now.

## Update, later on 25 Nov
- Mixamo rigged player_v4 on the PC; 366 clips for him are in the Drive folder `player_v4` (link: https://drive.google.com/drive/folders/1wXMD5l9UYaO05UKQDtkyItY7TRd22-1v). Measured: 272 of the 369 wanted clips are there and right; see `reports/player_v4 clips what arrived.md` and the report section "player_v4 rigged by Mixamo".
- His Mixamo skeleton: 65 joints, hip to ankle 0.829 m, shoulder to wrist 0.465 m. A few clips slide; a travel scale of about 0.95 is to be tested at Stage 3.
- Still missing for the build: `Running Right Turn`, `Start Walking`, `Crouching Idle` (batch 1), eight clips of batch 2, five of batch 3. The rigged character file (T-pose with skin) is not in Drive yet.
- The clip lists by Drive file name were wrong for Mixamo (names with brackets are not Mixamo names). Use `reports/Mixamo clip list by name.md` and `reports/mixamo_download_player_v4.js`.
- The Kimodo clips are still on X Bot; remake them on his skeleton once the rigged character file is available.

## The build has started (25 Nov, evening)
- Yasin's answers: **start fresh**, tied into the game later ("start fresh if you think we can easily tie it into the game when the time comes"); **he play-tests** ("whenever you need to have eyes on what you do, tell me").
- Tie-in check: the current player is one `CharacterBody3D` class (`CityPlayer`, C++) with a small set of calls the game uses (move, jump, crouch, freeze, ride, knock, act ...). The new system will be given the same calls at integration. Only that interface was read, not how the old player works.
- The work is in **`traversal_lab/`**, a self-contained Godot project (Jolt, 60 ticks), code under `traversal_lab/traversal/` = `res://traversal/`. See `traversal_lab/README.md` for how to run it, the keys and the stage table.
- **Stage 0 is built** (62-station measured course, readout, input record / replay). `tests/test_stage0.gd` says RESULT PASS. It still needs Yasin's eyes once (labels readable, readout moves, replay repeats): the three checks are in the README.
- **Stage 1 is built and its automatic test passes** (`tests/test_stage1.gd`, 31 checks, with a ten-minute random walk): the floating capsule works under Jolt, so the fallback was not needed. It **needs Yasin's eyes** for the feel: the list is in `traversal_lab/README.md`, "Stage 1: what to look at".
- **Standing rule from Yasin (25 Nov): "do not forget to remind yourself of the movement study and acting according to it at every step."** Before each stage re-read the relevant part of the report; every movement number in the code names the finding it follows, or is marked as not in the study. The README has the rule and a study-against-code table per stage.
- The cloud can render the lab: `xvfb-run` with lavapipe, see `traversal_lab/tests/shot.gd`.
- **Next: Stage 2**, import player_v4 (needs the rigged character file from Mixamo, T-pose with skin, which is not in Drive yet) and idle, walk, run; then `Running Jump Climb` on a 1.00 m box to settle upward travel.
- In the cloud, Godot 4.7.2 is not installed: download the Linux build from the Godot GitHub releases; headless runs work with Jolt.

## Waiting on Yasin
1. **The Mixamo rig of player_v4 and his clips** (PC job, `reports/Mixamo rig and re-download.md`). First batch of 35 clips is enough to start.
2. Fresh code or on top of the old player: answered, fresh (see above).
3. Who watches the stage tests: answered, Yasin play-tests when told eyes are needed.

## Next steps, in order
1. When the Mixamo-rigged `player_v4_mixamo.fbx` and the `player_v4` clip folder are in Drive: measure his skeleton and the clips (`measure_clips.py`), add to the report.
2. Remake the seven Kimodo clips on his skeleton (they are on X Bot now): generate, then `clean_kimodo.py`, then `fix_kimodo.py`.
3. Stage 0 (measured test course) and Stage 1 (bare capsule) can start without waiting for any of the above.

## Where things are, and what works from where
- **Clips:** Yasin's shared Google Drive folder "mixamo" (public link, readable from the cloud with `gdown`): https://drive.google.com/drive/folders/1ApuKUaGgrlvYGPT_g_9ceyBitAokmAR_ . Raw Mixamo files stay out of git.
- **Mixamo login:** only on Yasin's PC (DESKTOP-7TL87SN). A cloud session cannot log in, and a task card started "in the cloud" cannot either. The PC's folders are not offered to cloud sessions at present.
- **Kimodo:** on Replicate as `sprited/kimodo`; the Replicate key is on the environment. The account had under 5 dollars of credit (limit: 6 runs a minute). Its FBX export needs the two fix tools.
- **Meshy:** key saved on the "Default" environment on 25 Nov (host `api.meshy.ai`); 819 credits left. Rigging takes `skeleton_template: mixamo`. Meshy task files expire about three days after they are made; the v4 files are already saved in `assets/people/meshy/player_v4/`.
- **Godot 4.7.2** is not installed in the cloud container; download the Linux build from the Godot GitHub releases when needed.
- **Not in git** (they contain the X Bot mesh): the seven Kimodo FBX clips. They were sent to Yasin as `Kimodo_clips.zip` and he put them in the Drive folder as `KM *.fbx`.

## Things found out the hard way
- `CharacterBody3D` does not use Jolt's own character controller; no stair stepping comes with it.
- Mixamo clips have no root bone; travel is in the hips; clip names repeat, so the description identifies a clip.
- The braced-hang clips do not share one height; place the body by the hands.
- The hands slide in the Mixamo climb clips; pin them with arm IK.
- Kimodo's Mixamo FBX export keeps the uploaded character's own animation on a second layer and puts the hips in the wrong place.
- A remake on Meshy does not change the skeleton's proportions.
