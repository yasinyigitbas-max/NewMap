"""LOD match: how much a building's picture jumps at each switch (lod_shots.gd: the same camera, the two tiers).
Mean absolute RGB difference (0-255) over the middle of the frame (the building): 59 m near -> mid, 219 m mid -> far.
usage: shots_pop.py DIR(with before/ after/) OUT.json"""
import sys, os, json
import numpy as np
from PIL import Image
def c(p, s):
    a = np.asarray(Image.open(p).convert('RGB')).astype(float); H, W = a.shape[:2]
    return a[H // 2 - s // 2:H // 2 + s // 2, W // 2 - s // 2:W // 2 + s // 2]
src = sys.argv[1]; res = {}
shots = sorted({f.rsplit('_', 1)[0] for f in os.listdir(os.path.join(src, 'after'))})
for sh in shots:
    r = {}
    for v in ('before', 'after'):
        d = os.path.join(src, v)
        r[v] = [round(float(np.abs(c(f'{d}/{sh}_59n.png', 300) - c(f'{d}/{sh}_59m.png', 300)).mean()), 2),
                round(float(np.abs(c(f'{d}/{sh}_219m.png', 120) - c(f'{d}/{sh}_219f.png', 120)).mean()), 2)]
    res[sh] = r
    print(f"{sh:16s} near->mid {r['before'][0]:6.2f} -> {r['after'][0]:6.2f}   mid->far {r['before'][1]:6.2f} -> {r['after'][1]:6.2f}")
b = np.array([res[k]['before'] for k in res]); a = np.array([res[k]['after'] for k in res])
print('mean', b.mean(0).round(2), '->', a.mean(0).round(2))
json.dump(res, open(sys.argv[2], 'w'), indent=1)
