import json, sys, os, subprocess
sys.path.insert(0, '../scripts'); sys.path.insert(0, '.')
from run import run
CH = "https://api.replicate.com/v1/files/NDY3MzI5YzctYzY0NC00NTUwLTljNTItYzI0NjQwOTJiOTZh.fbx"     # uploaded 26 Nov 16:17 UTC, expires 27 Nov 16:16 UTC
JOBS = json.load(open(sys.argv[1]))
for name, prompt, dur, seeds in JOBS:
    for sd in seeds:
        d = 'out/%s_s%d' % (name, sd)
        if os.path.exists(d + '/kimodo_motion_00.fbx'): continue
        run(d, dict(prompt=prompt, duration=dur, seed=sd, output_format='all', preview=True, custom_fbx=CH, image_size=384))
