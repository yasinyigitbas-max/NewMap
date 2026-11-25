# Clip measurements

`clip_measurements.csv` holds one row for each of the 408 Mixamo files in Yasin's shared folder (356 loose files and 52 from three packs), measured on 25 Nov 2026 by reading each FBX directly. No raw Mixamo file is stored here.

How it was measured: `measure_clips.py` (with the small FBX reader `fbxp.py`) reads the hip position keys and every joint's rotation keys, then works out where the hands, feet and head are on each frame. Lengths are metres, times seconds, angles degrees. Run it as `python3 -I measure_clips.py out.json clip1.fbx clip2.fbx ...`.

Checks that the method is right: in every standing clip the feet come out at 0.00 m, the head top at 1.81 m, and the two stair clips come out at 0.49 to 0.50 m for two steps.

| Column | Meaning |
|---|---|
| src | `loose` or the pack name |
| dur, frames, fps | length of the clip |
| fwd, side, rise | hip travel from first to last frame: forward, sideways (+ is the character's left), up |
| horiz, path_len | straight-line and along-the-path ground travel of the hips |
| speed, peak_speed | `horiz / dur`, and the fastest frame |
| yaw_delta | how far the hips turn, first to last frame (+ is to the left) |
| hips_y0, hips_y1, hips_ymin, hips_ymax, hips_ymax_t | hip height at start, end, lowest, highest, and when it is highest |
| feet_y0, feet_y1 | height of the lowest foot joint at start and end (end minus start = the height climbed or dropped) |
| feet_min, feet_max_low | lowest the feet go; highest point reached by the lower foot (obstacle clearance) |
| hand_max, hand_max_t, hand_min | highest and lowest wrist height, and when the highest is reached |
| head_y0, head_min, head_max | top of the head |
| loop_err | largest difference between the first and last pose (0 = a clean loop) |
| skin, joints, ver | whether the file carries a mesh, its joint count, its FBX version |

Hand heights are wrist joints; the gripping palm is about 0.08 m further along the hand.

`catalogue_candidates.csv` holds the same measurements for 31 clips that are not in the folder, taken from a public copy of the Mixamo catalogue (https://huggingface.co/datasets/Linzhan/Mixamo-Animations-Characters). They are on a different body (hip to ankle 0.83 m, against 0.889 m for the folder's clips), so heights read about 7 % low.

`kimodo_clips.csv` holds the measurements of the seven clips generated with Kimodo (through Replicate) for the gaps Mixamo cannot fill, with the sentence used for each. `clean_kimodo.py` removes the leftover animation layer from a Kimodo Mixamo-FBX export; `fix_kimodo.py` then rebuilds its hip path from the matching `.npz` so the feet sit on the ground and stop sliding. Run them in that order: `python3 -I clean_kimodo.py in.fbx clean.fbx`, then `python3 -I fix_kimodo.py clean.fbx in.npz out.fbx`. `fbxrw.py` is the FBX reader/writer they use.

Rows with source `loose2` are the 18 clips added to the folder later on 25 Nov 2026. `glb_skeleton.py` prints the joints and rest positions of a GLB character (used on the Meshy player model): `python3 -I glb_skeleton.py model.glb`.
