"""Slope check for a Coronado height map (Yasin 16 Nov: "elevation smooth, no sudden steep rises").

Reads a height map in the game's format (meta.json + zlib float32, 4 m samples) and reports, on land only:
- grade: rise over run between neighbouring samples, in percent
- kink: change of grade from one sample to the next (a sudden step even when the slope itself is moderate)
Fails (exit 1) if land outside the allowed edge band breaks a limit. Map-edge cliffs (Point Loma, west edge) and the
shore band are reported but not failed: they are not city streets.

  python -I tools/city/check_grades.py [--data=map_dc/coronado/terrain/data] [--max_grade=18] [--max_kink=6]
        [--edge=600] [--list=20]
"""
import json
import sys
import zlib

import numpy as np

args = {k.lstrip("-"): v for k, _, v in (a.partition("=") for a in sys.argv[1:])}
DATA = args.get("data", "map_dc/coronado/terrain/data")
MAX_GRADE = float(args.get("max_grade", 18))   # % ; streets: avenues 6, residential 12, a few postcard streets 18
MAX_KINK = float(args.get("max_kink", 6))      # % change of grade per 4 m step
EDGE = float(args.get("edge", 600))            # m from the map's west edge treated as cliffs, reported only
LIST = int(args.get("list", 20))

meta = json.load(open(f"{DATA}/meta.json", encoding="utf-8"))
W, H = meta["size_px"]
step = meta["metres_per_pixel"]
ox, oz = meta["origin_xz"]
a = np.frombuffer(zlib.decompress(open(f"{DATA}/{meta['height_file']}", "rb").read()), "<f4").reshape(H, W).astype(np.float64)

land = a > 0.5
gx = np.diff(a, axis=1) / step
gz = np.diff(a, axis=0) / step
grade = np.zeros_like(a)
grade[:, :-1] = np.maximum(grade[:, :-1], np.abs(gx))
grade[:, 1:] = np.maximum(grade[:, 1:], np.abs(gx))
grade[:-1, :] = np.maximum(grade[:-1, :], np.abs(gz))
grade[1:, :] = np.maximum(grade[1:, :], np.abs(gz))
grade *= 100.0
kink = np.zeros_like(a)
kx = np.abs(np.diff(gx, axis=1)) * 100.0
kz = np.abs(np.diff(gz, axis=0)) * 100.0
kink[:, 1:-1] = np.maximum(kink[:, 1:-1], kx)
kink[1:-1, :] = np.maximum(kink[1:-1, :], kz)

# land next to sea is the shore band: banks may be steep there
near_sea = ~land
for _ in range(3):
    s = near_sea.copy()
    s[1:, :] |= near_sea[:-1, :]; s[:-1, :] |= near_sea[1:, :]; s[:, 1:] |= near_sea[:, :-1]; s[:, :-1] |= near_sea[:, 1:]
    near_sea = s
xs = ox + step * np.arange(W)
edge = np.broadcast_to(xs < ox + EDGE, a.shape)
judged = land & ~near_sea & ~edge

def stats(name, v):
    p = np.percentile(v, [50, 95, 99, 100]) if v.size else [0, 0, 0, 0]
    print(f"{name}: p50 {p[0]:.1f}%  p95 {p[1]:.1f}%  p99 {p[2]:.1f}%  max {p[3]:.0f}%")

print(f"height map {W}x{H} at {step:g} m; land samples {int(land.sum())}, judged {int(judged.sum())}")
stats("grade (judged land)", grade[judged])
stats("kink  (judged land)", kink[judged])
bad = judged & ((grade > MAX_GRADE) | (kink > MAX_KINK))
print(f"reported only: shore band {int((land & near_sea).sum())} samples, west edge {int((land & edge).sum())} samples")
print(f"limits: grade <= {MAX_GRADE:g}%, kink <= {MAX_KINK:g}% per {step:g} m")

ys, xs_i = np.nonzero(bad)
if ys.size:
    cells = {}
    for y, x in zip(ys, xs_i):
        k = (int((ox + step * x) // 100 * 100), int((oz + step * y) // 100 * 100))
        c = cells.setdefault(k, [0, 0.0, 0.0])
        c[0] += 1; c[1] = max(c[1], grade[y, x]); c[2] = max(c[2], kink[y, x])
    print(f"FAIL {int(bad.sum())} samples in {len(cells)} 100 m cells over a limit (worst first):")
    for k, c in sorted(cells.items(), key=lambda kv: -kv[1][1])[:LIST]:
        print(f"  cell x={k[0]} z={k[1]}: {c[0]} samples, max grade {c[1]:.0f}%, max kink {c[2]:.0f}%")
    sys.exit(1)
print("PASS no sudden or steep rises on judged land")
