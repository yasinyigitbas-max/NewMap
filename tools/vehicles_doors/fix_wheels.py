"""fix_wheels.py <game_dir> <id>: repair the wheel dumps of cars built before zh_build.py dropped the other parts'
loose vertices (their hub was the whole car's vertex mean): put the wheel back where it was, measure its real hub (the
middle of its own faces' bounds) and radius, and re-centre it. Idempotent (a wheel already about its hub stays)."""
import sys, os, json
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import meshio
G, ID = sys.argv[1:3]
p = os.path.join(G, ID + '_info.json')
info = json.load(open(p))
for k, w in enumerate(info['wheels']):
    j, V, I = meshio.read(os.path.join(G, '%s_w%d' % (ID, k)))
    P = V[:, 0:3] + np.array(w['center'], np.float32)
    lo, hi = P.min(0), P.max(0)
    c = (lo + hi) / 2
    r = float(max(hi[1] - lo[1], hi[2] - lo[2]) / 2)
    V = V.copy(); V[:, 0:3] = P - c
    meshio.write(os.path.join(G, '%s_w%d' % (ID, k)), V, I, j)
    lo = os.path.join(G, '%s_w%d_lo' % (ID, k))
    if os.path.exists(lo + '.json'):      # (its light copy was written about the same wrong hub)
        jl, VL, IL = meshio.read(lo); VL = VL.copy(); VL[:, 0:3] = VL[:, 0:3] + np.array(w['center'], np.float32) - c
        meshio.write(lo, VL, IL, jl)
    info['wheels'][k] = {'center': [float(x) for x in c], 'radius': r}
    print(ID, 'w%d' % k, 'hub', c.round(3), 'r %.3f' % r, 'width %.3f' % (hi[0] - lo[0]))
json.dump(info, open(p, 'w'), indent=1)
