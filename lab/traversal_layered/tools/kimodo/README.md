# Kimodo test scripts (Lab B, 25 Nov 2026)
Python tools used for the Kimodo test (`KIMODO_TEST.md`). They call replicate.com (`sprited/kimodo`) with the
Replicate key the cloud proxy injects, and write outputs to `out/` beside them (never committed). `keys.py` builds key
poses on Kimodo's SOMA skeleton (needs `ref/rest77.json`, dumped from any Kimodo GLB with `probe/dump_rest.gd`-style
code); `round3.py` defines the climb / mantle / vault key poses; `score_r3.py` scores the samples.
Note: in Kimodo prompts a period starts a new segment. Write "one and a half meters", never "1.5 meters".
