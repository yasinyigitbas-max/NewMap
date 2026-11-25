# Traversal work: where we are (read this first after a break or a context compression)

Last updated 25 Nov 2026, session "Traversal system research and design", branch `claude/intelligent-bardeen-errnbs`.

## What Yasin asked for
A robust Rockstar-style traversal system for the game (Godot 4.7, Jolt, Mixamo clips), after five failed attempts. He asked for a study from real sources first. Two rules he set:
- **Do not use or salvage the earlier human-movement study** (it was written from memory). It lives on other branches (for example `claude/festive-faraday-20ltx2`); do not read it.
- **Do not be influenced by what is already in the game.** The old player code, the `lab/*` branches and the old animation skill were not read, on purpose.

## What exists (all on this branch)
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

## Waiting on Yasin
1. **The Mixamo rig of player_v4 and his clips** (PC job, `reports/Mixamo rig and re-download.md`). First batch of 35 clips is enough to start.
2. **Fresh code or on top of the old player?** Recommended: a separate, self-contained scene and code until it passes its stages. Not answered yet.
3. **Who watches the stage tests?** Yasin on the PC, or videos recorded in the cloud (not yet checked that Godot can render video here). Not answered yet.

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
