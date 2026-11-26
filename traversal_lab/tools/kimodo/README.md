# Kimodo pipeline scripts

Copied on 26 Nov 2026 from the cloud session's scratch disk so they are not lost. They were written to run there and
have that session's habits baked in: run them from this folder, and expect to fix paths.

| File | Does |
|---|---|
| `run.py` | one prediction on Replicate (`sprited/kimodo`) and download of its outputs. Sends a dummy bearer value: the session proxy puts the real one in. Never put a key here. |
| `batch.py jobs.json` | runs a list of `[name, prompt, seconds, [seeds]]` into `out/<name>_s<seed>/`. `CH` is the target character file uploaded to Replicate; that upload expires, so upload the character again and change it. |
| `post.py` | for every take in `out/`: `clean_kimodo` (tidy the FBX), `fix_kimodo` (foot fix, needs the take's NPZ), measure, and a preview sheet |
| `clean_kimodo.py`, `fix_kimodo.py`, `measure.py`, `fbxrw.py`, `fbxp.py` | the steps and the FBX reader / writer they use |
| `audition.sh walk|run <takes>` | bakes each take as `KM_Walk` or `KM_Run` and runs the study audit on it. Its paths point at the old scratch disk. |

A take goes into the build as: `fixed.fbx` copied to `traversal_lab/assets_src/clips/<Name>.fbx`, then
`godot --headless --path traversal_lab --import`, a loop cut added to `CUTS` in `tools/build_clips.gd`
(`-- --table` prints the foot data to choose it from), then the bake.

Prompt lessons are in `reports/TRAVERSAL HANDOVER.md`, section 6.
