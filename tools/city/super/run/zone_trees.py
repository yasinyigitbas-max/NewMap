"""Tree lists from the plan's rule for a zone (docs/TREE_PLAN.md), on the spots the builder trees stood on (Yasin, 19 Nov:
"if the plan puts new trees in old spots it is fine, stick to the plan"). Run BEFORE block.sh so wells of kept trees
stay open.
  wells  a tree in a well in the paving (soil with paving round it): kept (high street and city centre want them)
  lawn   a tree on a lawn or bed: kept at the zone's share, the trees at least SPACING m apart, the rest go
  python -I tools/city/super/run/zone_trees.py <piece> <area> <zone label> <lawn share 0..1> [spacing m]
"""
import json, sys, math
sys.path.insert(0, 'tools/city/super')
import sc_trees as T
P, area, zone, share = sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4]); SP = float(sys.argv[5]) if len(sys.argv) > 5 else 10.0
RULES = {'high street': 'docs/TREE_PLAN.md: high street - trees in wells on the shop side; residential yards: one yard tree for every two or three houses, never against a fence or a wall',
         'residential': 'docs/TREE_PLAN.md: residential yards - one yard tree for every two or three houses, in back yards and at lot corners, never against a fence or a wall (813 -> about 400)',
         'commercial strip': 'docs/TREE_PLAN.md: commercial strip few - the palm parkway; one tree per car-park island end',
         'waterfront': 'docs/TREE_PLAN.md: waterfront palms only - spaced palms on the promenade'}
c = T.context(P); d = json.load(open('OUT/super/find/%s.faults.json' % P))
olds = [f for f in d['faults'] if f['kind'] == 'tree_out']
wells = []; lawn = []
for f in olds:
    x, y, z = f['at']; g = c.S.ground(x, z)
    if not g: continue
    paved = sum(1 for dx, dz in ((1.3, 0), (-1.3, 0), (0, 1.3), (0, -1.3)) if (c.S.ground(x + dx, z + dz) or [0, ''])[1] in ('concrete', 'paving', 'plaza'))
    walls = min([T.L.quad_dist(b.quad, (x, z)) for b in c.blds if b.quad is not None] or [99])
    rec = (f['item']['base'], x, round(g[0], 3), z, walls)
    if g[1] == 'mulch' and paved >= 3: wells.append(rec)
    elif g[1] in ('grass', 'mulch') and walls >= 2.0: lawn.append(rec)
keep = []
for r in wells:
    if all(math.hypot(r[1] - k[1], r[3] - k[3]) >= 3.0 for k in keep): keep.append(r + ('a tree in a pavement well',))
want = int(round(len(lawn) * share))
for r in sorted(lawn, key=lambda r: -r[4]):              # the trees standing most freely first
    if len([k for k in keep if k[5] != 'a tree in a pavement well']) >= want: break
    if all(math.hypot(r[1] - k[1], r[3] - k[3]) >= SP for k in keep): keep.append(r + ('a yard tree standing free, %.0f m from the nearest wall' % r[4],))
trees = [{'base': b, 'cond': 'normal', 'at': [x, y, z], 'yaw': (k * 113) % 360, 'scale': [0.95, 0.85, 0.9][k % 3], 'why': 'kept on its spot: ' + w}
         for k, (b, x, y, z, _, w) in enumerate(keep)]
p = 'map_dc/coronado/city_kit/zoning/trees/%s.json' % area
if trees:
    json.dump({'area': area, 'piece': P, 'zone': zone, 'rule': RULES.get(zone, zone), 'written': '19 Nov 2026 (PC session, city-wide superchecker run): the plan\'s share of the builder trees kept on their spots, the rest out', 'trees': trees}, open(p, 'w'), indent=1)
print('ZONE TREES %s: %d stood (%d in wells, %d free on lawns) -> %d kept' % (P, len(olds), len(wells), len(lawn), len(trees)))
