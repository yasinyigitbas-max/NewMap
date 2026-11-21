#!/usr/bin/env python3
"""Cut the fill under the ferry landing (hero, 21 Nov; brief: "check no fl_* fill piece overlaps the site, adjust if
so"). A hand change to three fill pieces' data (make_fill.py's rule: "a fix to one piece later is a hand change to that
piece"), then build_fill.gd --only rebuilds their .scn. It takes out:
  - every ground triangle whose centre lies inside the landing's ground (n_ferry_landing: u 190 - 490 from 1st St's bay
    walk v -1618.3 to the land edge v -1750, and the two revetments to their toe v -1758: u 190 - 212, 384 - 490) or
    inside the 1st St ferry gap the signalised T now covers (j_rg_nw_e350_n1600: u 327.5 - 372.5, v -1618.3 - -1585.7)
  - every fill prop standing inside those rects or within 1 m of them
The fill's sand and bay bed seaward of the seawall / revetment toes stays (the beach and the bed the sea shows).
Originals are kept in OUT/fill/pieces_before_ferry/ (run once; re-running starts from those originals).
  python3 -I tools/city/hero/ferry/cut_fill.py
"""
import json, os, shutil, sys
import numpy as np
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../.."))
D = os.path.join(ROOT, "OUT/fill/pieces"); KEEP = os.path.join(ROOT, "OUT/fill/pieces_before_ferry")
RECTS = [(190.0, -1750.0, 490.0, -1618.3), (190.0, -1758.0, 212.0, -1750.0), (384.0, -1758.0, 490.0, -1750.0),
         (327.5, -1618.3, 372.5, -1585.7)]
NAMES = ["fl_0_m9", "fl_1_m9", "fl_2_m9", "fl_3_m9", "fl_0_m8", "fl_1_m8", "fl_2_m8"]

def inside(u, v, m=0.0):
    r = np.zeros(u.shape, bool)
    for (u0, v0, u1, v1) in RECTS: r |= (u > u0 - m) & (u < u1 + m) & (v > v0 - m) & (v < v1 + m)
    return r

os.makedirs(KEEP, exist_ok=True)
for n in NAMES:
    j, b = os.path.join(D, n + ".json"), os.path.join(D, n + ".bin")
    if not os.path.exists(j): continue
    if not os.path.exists(os.path.join(KEEP, n + ".json")):
        shutil.copy2(j, KEEP); shutil.copy2(b, KEEP)
    d = json.load(open(os.path.join(KEEP, n + ".json")))
    a = np.fromfile(os.path.join(KEEP, n + ".bin"), dtype=np.float32).reshape(-1, 11)
    parts, surfs, off, cut_t = [], [], 0, 0
    for s in d["surfaces"]:
        v = a[s["offset"] // 44: s["offset"] // 44 + s["count"]].reshape(-1, 3, 11)
        c = v[:, :, [0, 2]].mean(axis=1)
        keep = ~inside(c[:, 0], c[:, 1])
        cut_t += int((~keep).sum())
        v = v[keep].reshape(-1, 11)
        if len(v): surfs.append({"mat": s["mat"], "count": int(len(v)), "offset": off}); parts.append(v); off += len(v) * 44
    pr = d.get("props", []) or []
    pk = [p for p in pr if not inside(np.array([p[2]]), np.array([p[4]]), 1.0)[0]]
    print("%s: triangles cut %d of %d, props cut %d of %d" % (n, cut_t, int(a.shape[0] // 3), len(pr) - len(pk), len(pr)))
    if cut_t == 0 and len(pk) == len(pr):
        continue
    d["surfaces"] = surfs; d["props"] = pk; d["tris"] = int(off // 44 // 3)
    (np.concatenate(parts) if parts else np.zeros((0, 11), np.float32)).astype(np.float32).tofile(b)
    json.dump(d, open(j, "w"))
