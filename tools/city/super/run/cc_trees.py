"""City centre (docs/TREE_PLAN.md: "few - wells on the wide pavements only, none in courts or alleys"): of the trees that
stood on a piece, the ones in a WELL (soil inside paving) are kept on their own spot; the ones on lawns, in courts and
yards go. Writes zoning/trees/<area>.json (or nothing when no tree stood in a well). Run BEFORE block.sh, so the checker
leaves the kept trees' wells open."""
import json, sys, os
sys.path.insert(0, 'tools/city/super')
import sc_trees as T
P = sys.argv[1]; area = 'cc_' + P[len('n_cc_'):]
c = T.context(P); d = json.load(open('OUT/super/find/%s.faults.json' % P)); trees = []
for f in d['faults']:
    if f['kind'] != 'tree_out': continue
    x, y, z = f['at']; g = c.S.ground(x, z)
    if not g or g[1] != 'mulch': continue
    paved = sum(1 for dx, dz in ((1.3, 0), (-1.3, 0), (0, 1.3), (0, -1.3)) if (c.S.ground(x + dx, z + dz) or [0, ''])[1] in ('concrete', 'paving', 'plaza'))
    if paved < 3: continue                     # a bed in a lawn, not a well in the pavement
    trees.append({'base': f['item']['base'], 'cond': 'normal', 'at': [x, round(g[0], 3), z], 'yaw': (len(trees) * 113) % 360, 'scale': [0.95, 0.85, 0.9][len(trees) % 3],
                  'why': 'kept on its spot: a tree in a well in the paving, as the plan wants for the city centre'})
p = 'map_dc/coronado/city_kit/zoning/trees/%s.json' % area
if trees:
    json.dump({'area': area, 'piece': P, 'zone': 'city centre', 'rule': 'docs/TREE_PLAN.md: city centre few - wells on the wide pavements only, none in courts or alleys (zone 48 -> about 40)',
               'written': '19 Nov 2026 (PC session, city-wide superchecker run): the trees standing in wells in the paving kept on their spots, the trees of lawns, courts and yards out', 'trees': trees}, open(p, 'w'), indent=1)
print('CC TREES %s: %d kept in wells' % (P, len(trees)))
