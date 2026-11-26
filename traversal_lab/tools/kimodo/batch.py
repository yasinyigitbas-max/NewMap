import json, sys, os, subprocess
sys.path.insert(0, '../scripts'); sys.path.insert(0, '.')
from run import run
CH = "https://api.replicate.com/v1/files/ZTVmZGQzNzItMmI5OS00MjFhLWI2YmUtM2ViYTY0OTRjZjRl.fbx"
JOBS = json.load(open(sys.argv[1]))
for name, prompt, dur, seeds in JOBS:
    for sd in seeds:
        d = 'out/%s_s%d' % (name, sd)
        if os.path.exists(d + '/kimodo_motion_00.fbx'): continue
        run(d, dict(prompt=prompt, duration=dur, seed=sd, output_format='all', preview=True, custom_fbx=CH, image_size=384))
