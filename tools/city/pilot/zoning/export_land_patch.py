"""Export the land (zoning/terrain_grid.npz, 4 m nodes) under a rectangle as a GDScript table, so a piece's ground can
follow the land exactly (bilinear between the nodes). Reads the land only; writes the .gd table.
  python3 -I tools/city/pilot/zoning/export_land_patch.py <u0> <v0> <u1> <v1> <out.gd> <name>
"""
import sys, math, numpy as np
u0, v0, u1, v1 = map(float, sys.argv[1:5]); out, name = sys.argv[5], sys.argv[6]
T = np.load('map_dc/coronado/city_kit/zoning/terrain_grid.npz')
H = T['heights']; tu, tv, st = float(T['u0']), float(T['v0']), float(T['step'])
i0 = math.floor((u0 - tu) / st); i1 = math.ceil((u1 - tu) / st)
j0 = math.floor((v0 - tv) / st); j1 = math.ceil((v1 - tv) / st)
P = H[j0:j1 + 1, i0:i1 + 1]
with open(out, 'w') as f:
    f.write('extends RefCounted\n')
    f.write('## The land (zoning/terrain_grid.npz) under %s, exported %s by tools/city/pilot/zoning/export_land_patch.py: world\n' % (name, '19 Nov'))
    f.write('## heights on the land\'s own 4 m nodes, rows along v (north first), bilinear between them. Measured data, not a rule.\n')
    f.write('const U0 := %.1f\nconst V0 := %.1f\nconst STEP := %.1f\nconst NU := %d\nconst NV := %d\n' % (tu + i0 * st, tv + j0 * st, st, P.shape[1], P.shape[0]))
    f.write('const H := [\n')
    for r in P: f.write('\t' + ', '.join('%.3f' % x for x in r) + ',\n')
    f.write(']\n\n')
    f.write('static func at(u: float, v: float) -> float:\n')
    f.write('\tvar fx := clampf((u - U0) / STEP, 0.0, NU - 1.001); var fz := clampf((v - V0) / STEP, 0.0, NV - 1.001)\n')
    f.write('\tvar i := int(fx); var j := int(fz); var a := fx - i; var b := fz - j\n')
    f.write('\tvar h00: float = H[j * NU + i]; var h10: float = H[j * NU + i + 1]; var h01: float = H[(j + 1) * NU + i]; var h11: float = H[(j + 1) * NU + i + 1]\n')
    f.write('\treturn lerpf(lerpf(h00, h10, a), lerpf(h01, h11, a), b)\n')
print(out, P.shape, 'min %.2f max %.2f' % (P.min(), P.max()))
