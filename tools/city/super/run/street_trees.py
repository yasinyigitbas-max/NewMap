"""Street trees BY HAND (19 Nov 2026, the streets pass): shows the builder trees of one street piece so a person can pick,
and writes the list a person picked. It chooses nothing itself.

  show  <piece>                          every old tree: number, species, side, metres along, ground, well or grass,
                                         gap to the previous one on the same side, what stands within 3 m
  write <piece> <zone> <rule> <pick>...  writes zoning/trees/<area>.json; a pick is  n:why  (keep tree n on its spot)
                                         or  n=base:why  (a tree of species base on old spot n, for a run of one species)
For a piece that stands in the layout more than once, each pick is written once for EVERY place the piece stands
(world coordinates, from the tree's spot in the piece), so all its places get the same trees.
"""
import json, os, sys
sys.path.insert(0, 'tools/city/super')
import numpy as np
import sc_lib as L, sc_trees as T

TREES = 'map_dc/coronado/city_kit/zoning/trees'


def old_trees(P):
    d = json.load(open('OUT/super/find/%s.faults.json' % P))
    return [f for f in d['faults'] if f['kind'] == 'tree_out']


def show(P):
    c = T.context(P); ts = old_trees(P); last = {}
    rows = [r for r in L.load_layout() if r.piece == P]
    print('TREES of %s: %d (the piece stands %d time(s) in the layout)' % (P, len(ts), len(rows)))
    lo, hi = L.Dump(P).bbox(); ax = 0 if (hi[0] - lo[0]) > (hi[1] - lo[1]) else 2     # the street runs along its long side
    sx = 2 - ax; mid = (lo[sx // 2] + hi[sx // 2]) * 0.5
    print('  the street runs along local %s; side = local %s %s %.1f' % ('xz'[ax // 2], 'xz'[sx // 2], 'from', mid))
    order = sorted(range(len(ts)), key=lambda i: (ts[i]['item']['local'][sx] > mid, ts[i]['item']['local'][ax]))
    for i in order:
        f = ts[i]; loc = f['item']['local']; x, y, z = f['at']; g = c.S.ground(x, z)
        lz = loc[ax]
        paved = sum(1 for dx, dz in ((1.3, 0), (-1.3, 0), (0, 1.3), (0, -1.3)) if (c.S.ground(x + dx, z + dz) or [0, ''])[1] in L.PAVED)
        side = ('+' if loc[sx] > mid else '-') + '%.1f' % (loc[sx] - mid)
        gap = '' if side not in last else '%.1f' % abs(lz - last[side]); last[side] = lz
        near = sorted([(round(float(L.quad_dist(it.quad, (x, z))), 1), it.base.replace('prop_', '')) for it in c.near((x, z), 5.0)
                       if it.kind != 'tree' and L.quad_dist(it.quad, (x, z)) < 3])[:3]
        print('  %2d %-20s %s along %6.1f gap %5s  %-8s %-5s near %s' % (i, f['item']['base'], side, lz, gap, g[1] if g else '-',
              'WELL' if paved >= 3 else '', near))


def write(P, zone, rule, picks):
    ts = old_trees(P); rows = [r for r in L.load_layout() if r.piece == P]; out = []; c = T.context(P)
    for pk in picks:
        head, why = pk.split(':', 1)
        n, base = (head.split('=') + [None])[:2]; f = ts[int(n)]
        for k, r in enumerate(rows):
            w = r.pts(np.array([f['item']['local']]))[0]
            g = c.S.ground(float(w[0]), float(w[2]))          # the builder sank its trunks a few cm: stand on the ground
            if g: w[1] = g[0]
            out.append({'base': base or f['item']['base'], 'cond': 'normal', 'at': [round(float(v), 3) for v in w],
                        'yaw': (len(out) * 113) % 360, 'scale': [0.95, 0.85, 0.9][len(out) % 3],
                        'why': why + ('' if len(rows) == 1 else ' (place %d of %d of this piece)' % (k + 1, len(rows)))})
    area = P.split('_', 1)[1]; p = os.path.join(TREES, area + '.json')
    if not out:
        if os.path.exists(p): os.remove(p)
        print('STREET TREES %s: none (no list)' % P); return
    json.dump({'area': area, 'piece': P, 'zone': zone, 'rule': rule,
               'written': '19 Nov 2026 (PC session, streets pass): picked by hand from the builder trees\' spots, one by one',
               'trees': out}, open(p, 'w', encoding='utf-8', newline='\n'), indent=1)
    print('STREET TREES %s: %d trees -> %s' % (P, len(out), p))


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == 'show': show(a[1])
    elif a[0] == 'write': write(a[1], a[2], a[3], a[4:])
