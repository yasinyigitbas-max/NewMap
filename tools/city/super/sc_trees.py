"""Superchecker, the hand-placed trees (19 Nov 2026).
Yasin: "removing existing trees entirely from every area it inspects, and only places them by hand according to tree
plantation plan we made"; docs/TREE_PLAN.md is that plan (which areas get trees, how many, the in-view limit).

A tree list is a plain file, map_dc/coronado/city_kit/zoning/trees/<area>.json, written BY HAND:
  {"area": "...", "piece": "<the block or street piece it belongs to>", "zone": "...", "rule": "<the plan's rule for
   this zone, in its words>", "trees": [{"base": "tree_eucalyptus_b", "at": [x, y, z], "yaw": 40, "scale": 0.9,
   "why": "<what this one tree is there for>"}, ...]}
Places are city coordinates. This tool does NOT choose a tree or a place. It only
  check   every line against the ground and what stands there (below), and against the plan's in-view limit
  where   says what the ground is at a spot (surface, height, the nearest things) - to read a place before writing it
and `sc.py trees <area>` then builds the list into the piece t_<area> (sc_trees.gd).
What `check` tests for each tree:
  ground        under the trunk: grass, mulch (an open well or a bed), gravel or sand. Never paving or asphalt.
  height        the line's y is the ground's height there (2 cm)
  fence         0.9 m clear of every fence and wall panel
  building      1.2 m clear of every building wall; 2.5 m clear in front of every door
  props         its trunk clear of every other thing on the ground; 2.5 m clear of an outdoor stair
  stall         not on a parking stall
  spacing       3 m from the next hand-placed tree
  why           every line says why
and for the list: from every 10 m of the streets round it, at most 8 broadleaf crowns and 12 trees of any kind within
60 m (the plan's limit), counting the hand-placed trees of ALL lists. Builder trees still standing in pieces that
have not been through the checker are NOT counted: they are to go.

  python -I tools/city/super/sc_trees.py check <area>        python -I tools/city/super/sc_trees.py where <piece> <x> <z>
"""
import json, math, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sc_lib as L
import sc_find as F

TREES = os.path.join(L.CK, 'zoning/trees')
BROADLEAF = ('tree_jacaranda', 'tree_coral', 'tree_magnolia', 'tree_ficus', 'tree_eucalyptus')


def load(area):
    return json.load(open(os.path.join(TREES, area + '.json'), encoding='utf-8'))


def all_lists():
    out = {}
    if os.path.isdir(TREES):
        for f in sorted(os.listdir(TREES)):
            if f.endswith('.json'): out[f[:-5]] = json.load(open(os.path.join(TREES, f), encoding='utf-8'))
    return out


def lists_of_piece(piece):
    return [a for a, j in all_lists().items() if j.get('piece') == piece]


def context(piece, dump_dir=None):
    rows = L.load_layout()
    me = [r for r in rows if r.piece == piece]
    if not me: sys.exit('no layout row places %s' % piece)
    return F.Ctx(rows, me[0], dump_dir=dump_dir, reach=45.0)


def where(piece, x, z):
    c = context(piece)
    g = c.S.ground(x, z)
    print('at (%.2f, %.2f): %s' % (x, z, ('%s at height %.3f (piece %s)' % (g[1], g[0], next((r.piece for r in [c.me] + c.neigh if r.id == g[2]), '?'))) if g else 'no ground of any piece'))
    near = []
    for it in c.near((x, z), 8.0):
        d = L.quad_dist(it.quad, (x, z))
        if d < 6.0 and it.kind != 'tree': near.append((d, it.base))
    for b in c.blds:
        if b.quad is not None:
            d = L.quad_dist(b.quad, (x, z))
            if d < 12.0: near.append((d, 'building ' + b.name))
    for d, n in sorted(near)[:10]: print('   %5.2f m  %s' % (d, n))


def check(area, dump_dir=None, say=True):
    j = load(area); piece = j['piece']
    c = context(piece, dump_dir=dump_dir)
    fence = [(o.ctr - o.along() * o.half[0], o.ctr + o.along() * o.half[0]) for o in c.all_items if o.kind in ('fence', 'gate')]
    stalls = []
    for r in [c.me] + c.neigh:
        for s in c.dumps[r.id].meta.get('stalls', []) or []:
            p = r.pts([[float(s[0]), 0.0, float(s[1])]])[0]
            stalls.append(L.rect_quad(p[[0, 2]], (1.15, 2.4), math.radians(float(s[2]) + r.yaw)))
    bad = 0; rows = []
    T = j['trees']
    for k, t in enumerate(T):
        x, y, z = [float(v) for v in t['at']]; probs = []
        if not (c.lo[0] - 45 <= x <= c.hi[0] + 45 and c.lo[1] - 45 <= z <= c.hi[1] + 45): probs.append('outside the area round %s' % piece)
        if not L.Kit.man(t['base']): probs.append('no kit model "%s"' % t['base'])
        g = c.S.ground(x, z)
        if g is None: probs.append('no ground under it')
        else:
            if g[1] not in L.SOFT: probs.append('stands on %s' % g[1])
            if abs(g[0] - y) > 0.02: probs.append('its height %.3f is not the ground\'s %.3f' % (y, g[0]))
        for a, e in fence:
            d = L.seg_dist((x, z), a, e)
            if d < 0.9: probs.append('%.2f m from a fence or wall panel' % d); break
        for b in c.blds:
            if b.quad is None: continue
            d = L.quad_dist(b.quad, (x, z))
            if d < 1.2: probs.append('%.2f m from the wall of %s' % (d, b.name)); break
            for nm, dp in b.doors:
                if np.hypot(dp[0] - x, dp[2] - z) < 2.5: probs.append('within 2.5 m of a door of %s' % b.name); break
        trunk = L.rect_quad((x, z), (0.3, 0.3), 0.0)
        for it in c.near((x, z), 8.0):
            if it.kind == 'tree' or it.mount != 'ground' or F.has(it.base, F.GROUND_COVER) or F.has(it.base, F.FLAT): continue
            if it.y0 > y + 2.5: continue
            if it.base.startswith('prop_dingbat_stair') and L.quad_dist(it.quad, (x, z)) < 2.5: probs.append('within 2.5 m of an outdoor stair'); break
            if L.quad_hit(trunk, it.quad, 1.0): probs.append('its trunk stands in %s' % it.base); break
        if any(L.in_quad(q, (x, z)) for q in stalls): probs.append('on a parking stall')
        for k2, t2 in enumerate(T):
            if k2 != k and np.hypot(float(t2['at'][0]) - x, float(t2['at'][2]) - z) < 3.0: probs.append('under 3 m from tree %d of this list' % (k2 + 1)); break
        if not str(t.get('why', '')).strip(): probs.append('no reason given')
        twins = [k2 + 1 for k2, t2 in enumerate(T) if k2 != k and t2['base'] == t['base'] and abs(float(t2.get('scale', 1.0)) - float(t.get('scale', 1.0))) < 0.03 and abs(float(t2.get('yaw', 0.0)) - float(t.get('yaw', 0.0))) < 5.0
                 and np.hypot(float(t2['at'][0]) - x, float(t2['at'][2]) - z) < 30.0]
        if len(twins) >= 2: probs.append('the same model, size and turn as trees %s within 30 m ("trees look like copy pasted")' % ', '.join(str(v) for v in twins[:4]))
        rows.append((k + 1, t['base'], (x, y, z), probs)); bad += len(probs) > 0
    # the plan's limit on trees in view, from the streets round the piece
    every = []
    for a2, j2 in all_lists().items():
        for t in (j['trees'] if a2 == area else j2['trees']): every.append((t['base'], float(t['at'][0]), float(t['at'][2])))
    if area not in all_lists():
        for t in T: every.append((t['base'], float(t['at'][0]), float(t['at'][2])))
    pts = {}
    S = c.S
    for k in range(len(S.T)):
        if S.kind[k] != 'ground' or S.mat[k] != 'asphalt': continue
        p = next((r.piece for r in c.neigh if r.id == S.own[k]), '')
        if not p.startswith(('s_', 'j_')): continue
        m = S.T[k].mean(0); pts[(round(m[0] / 10), round(m[2] / 10))] = (m[0], m[2])
    worst_b = 0; worst_a = 0
    for (px, pz) in pts.values():
        nb = sum(1 for b, x, z in every if np.hypot(x - px, z - pz) <= 60 and F.has(b, BROADLEAF))
        na = sum(1 for b, x, z in every if np.hypot(x - px, z - pz) <= 60)
        worst_b = max(worst_b, nb); worst_a = max(worst_a, na)
    cap_ok = worst_b <= 8 and worst_a <= 12
    if say:
        print('TREE LIST %s (piece %s, zone %s): %d trees' % (area, piece, j.get('zone', '?'), len(T)))
        print('  the plan\'s rule here: %s' % j.get('rule', '(not written in the list)'))
        for n, base, at, probs in rows:
            print('  %2d %-22s (%.1f, %.2f, %.1f)  %s' % (n, base, at[0], at[1], at[2], 'ok' if not probs else 'NOT OK: ' + '; '.join(probs)))
        print('  in view from the streets round it (%d points, 60 m): at most %d broadleaf (limit 8) and %d of any kind (limit 12): %s' % (len(pts), worst_b, worst_a, 'ok' if cap_ok else 'OVER THE LIMIT'))
        print('  (hand-placed trees of all lists are counted; builder trees still standing in other pieces are not)')
        print('TREE LIST %s: %s' % (area, 'ok' if bad == 0 and cap_ok else '%d line(s) not ok%s' % (bad, '' if cap_ok else ', over the in-view limit')))
    return bad == 0 and cap_ok


if __name__ == '__main__':
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == 'check': sys.exit(0 if check(a[1]) else 1)
    if len(a) >= 4 and a[0] == 'where': where(a[1], float(a[2]), float(a[3]))
    else: sys.exit(__doc__)
