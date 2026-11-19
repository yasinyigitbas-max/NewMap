"""Superchecker, part 2: FIND what is wrong in one piece of the city, outdoors (19 Nov 2026).

It measures and lists; it changes nothing. For one layout row it loads that piece and the pieces around it (from the
dumps of sc_dump.gd), the land and the kit's own lists, and writes
  <out>/<piece>.faults.json   every fault: what, where, how much, and how sure the check is
  <out>/<piece>.fixes.json    one line per item that can be mended by changing that ONE item
  <out>/<piece>.plan.png      a plan of the piece with every fault numbered
A fix line is one of the fixer's kinds (move / remove / remove_decal / fill_well) with the item's own place.
  "auto"   there is one right answer and the line holds it (a prop in the air goes down to the ground under it; a
           wear mark off its surface goes; every tree goes: the tree plan)
  "choose" the item must go somewhere else and a person has to pick where: the line is written WITHOUT a new
           place and the fixer will not run it until `to` is filled in by hand
Faults that are not one item (ground, buildings) are reported only.

  python -I tools/city/super/sc_find.py <piece> [--row=N] [--dump=<folder with a changed copy's dump>] [--out=<folder>]
"""
import json, math, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sc_lib as L

TOL_AIR = 0.06          # a prop this far over what it stands on is "in the air"
TOL_SUNK = 0.10
WF_STRUCT = ("prop_quay_", "prop_pier_", "prop_marina_", "prop_gangway", "prop_prom_", "prop_boat_", "prop_buoy_", "prop_dock_", "prop_lifering", "prop_kayak", "prop_lifeguard")
GROUND_COVER = ("plant_lawn_patch", "plant_iceplant")
BANNED = ("plant_lawn_patch",)                      # Yasin 16 Nov: grass tufts "look terrible"
PLAY = ("prop_play_structure", "prop_swing_set", "prop_slide")
SEATS = ("prop_park_bench", "prop_picnic_table", "prop_patio_set", "prop_adirondack", "prop_bench_bus_stop")
BINS = ("prop_trash_cart", "prop_trash_receptacle", "prop_recycling_receptacle", "prop_dumpster")
SOFT_LIFE = SEATS + PLAY + ("prop_bbq", "plant_potted", "prop_vending", "prop_ice_chest", "prop_clothesline", "prop_garden_arbor")
FLAT = ("prop_manhole", "prop_storm_drain", "prop_sprinkler_popup", "prop_wheel_stop", "prop_skate_", "prop_tennis", "prop_volleyball", "prop_headstone_flat")
# wear atlas tiles (kit_lib.gd): which ground each kind of mark belongs on
TILE_NAME = {0: 'crack', 1: 'crack', 2: 'sealed patch', 3: 'sealed patch', 4: 'pale patch', 5: 'pale patch', 6: 'oil', 7: 'oil', 8: 'tyre marks', 9: 'manhole', 10: 'drain', 11: 'utility cover', 12: 'valve', 13: 'paint', 14: 'grime', 15: 'tyre scuff'}
TILE_OK = {0: L.HARD + L.PAVED, 1: L.HARD + L.PAVED, 2: L.HARD, 3: L.HARD, 4: L.HARD + L.PAVED, 5: L.HARD + L.PAVED,
           6: L.HARD + ('concrete', 'gravel', 'plaza'), 7: L.HARD + ('concrete', 'gravel', 'plaza'), 8: L.HARD + ('gravel',), 15: L.HARD + ('gravel',),
           9: L.HARD + L.PAVED, 10: L.HARD + L.PAVED, 11: L.HARD + L.PAVED, 12: L.HARD + L.PAVED, 13: L.HARD + L.PAVED, 14: L.HARD + L.PAVED + ('gravel',)}


def has(base, names):
    return any(base.startswith(n) for n in names)


class Bld:
    pass


def buildings_of(dump, inst):
    out = []
    for b in dump.j['buildings']:
        o = Bld(); o.inst = inst; o.name = b['name']; o.kit = b['kit']; o.model = b['model']
        o.T = inst.xf([b['xf']])[0]; o.pos = o.T[9:12].copy(); o.yaw = math.atan2(o.T[6], o.T[8])
        o.B = o.T[:9].reshape(3, 3)                                   # rows = the columns
        o.st = L.Kit.stats(o.kit) if o.kit else {}
        fw = o.st.get('footprint_wd', [0, 0]); o.w = float(fw[0]); o.d = float(fw[1]); o.h = float(o.st.get('height', 3.0))
        o.quad = L.rect_quad(o.pos[[0, 2]], (o.w * 0.5, o.d * 0.5), o.yaw) if o.w > 0 else None
        o.open = L.Kit.openings(o.kit)
        o.doors = [(str(d[0]), o.world([float(d[1]), 0.0, o.d * 0.5])) for d in o.st.get('doors_front', [])]
        out.append(o)
    return out


def _bld_world(self, p):
    return np.asarray(p, float) @ self.B + self.pos
def _bld_local(self, p):
    return (np.asarray(p, float) - self.pos) @ np.linalg.inv(self.B)
Bld.world = _bld_world; Bld.local = _bld_local


class Ctx:
    """one piece and what stands round it"""
    def __init__(self, rows, row, dump_dir=None, reach=14.0):
        self.rows = rows; self.me = row
        self.dump = L.Dump(row.piece, folder=dump_dir or L.DUMP)
        lo, hi = self.dump.bbox(); c4 = row.pts(np.array([[lo[0], 0, lo[1]], [hi[0], 0, lo[1]], [hi[0], 0, hi[1]], [lo[0], 0, hi[1]]]))
        self.lo = c4[:, [0, 2]].min(0); self.hi = c4[:, [0, 2]].max(0)
        self.neigh = []
        boxes = Ctx.boxes(rows)
        for r in rows:
            if r.id == row.id or r.piece.startswith(('x_', 'w_')): continue
            b = boxes.get(r.id)
            if b is None: continue
            if b[0] > self.hi[0] + reach or b[2] < self.lo[0] - reach or b[1] > self.hi[1] + reach or b[3] < self.lo[1] - reach: continue
            self.neigh.append(r)
        self.dumps = {row.id: self.dump}
        for r in self.neigh: self.dumps[r.id] = L.Dump(r.piece)
        self.S = L.Surf(); self.blds = []; self.items = []; self.all_items = []
        for r in [row] + self.neigh:
            d = self.dumps[r.id]
            for name, T in d.ground(): self.S.add(r.pts(T), name, r.id, 'ground')
            bl = buildings_of(d, r); self.blds += bl
            for b in bl:
                M = L.Kit.model(b.model)
                if M is not None: self.S.add(M @ b.B + b.pos, 'building', r.id, 'bld')
            its = L.items_of(d, r); self.all_items += its
            if r.id == row.id: self.items = its
        self.S.build()
        self.land = L.Land()
        self.grid = {}
        for k, it in enumerate(self.all_items):
            self.grid.setdefault((int(it.ctr[0] // 4), int(it.ctr[1] // 4)), []).append(k)
        self.my_blds = [b for b in self.blds if b.inst.id == row.id]

    _boxes = None
    @staticmethod
    def boxes(rows):
        """city xz box of every layout row, kept in OUT/super/boxes.json by the scene's sha"""
        if Ctx._boxes is not None: return Ctx._boxes
        cache = os.path.join(L.OUT, 'boxes.json'); old = {}
        if os.path.exists(cache):
            try: old = json.load(open(cache))
            except Exception: old = {}
        loc = {}; out = {}; dirty = False
        for r in rows:
            if r.piece not in loc:
                pj = os.path.join(L.DUMP, r.piece + '.json')
                if not os.path.exists(pj): loc[r.piece] = None; continue
                sha = json.load(open(pj, encoding='utf-8')).get('sha256', '')
                if old.get(r.piece, {}).get('sha') == sha: loc[r.piece] = old[r.piece]
                else:
                    lo, hi = L.Dump(r.piece).bbox()
                    loc[r.piece] = {'sha': sha, 'box': [float(lo[0]), float(lo[1]), float(hi[0]), float(hi[1])]} if np.isfinite(lo).all() else {'sha': sha, 'box': None}
                    dirty = True
            e = loc[r.piece]
            if not e or not e.get('box'): continue
            b = e['box']; c = r.pts(np.array([[b[0], 0, b[1]], [b[2], 0, b[1]], [b[2], 0, b[3]], [b[0], 0, b[3]]]))[:, [0, 2]]
            out[r.id] = [float(c[:, 0].min()), float(c[:, 1].min()), float(c[:, 0].max()), float(c[:, 1].max())]
        if dirty:
            os.makedirs(L.OUT, exist_ok=True); json.dump({k: v for k, v in loc.items() if v}, open(cache, 'w'))
        Ctx._boxes = out
        return out

    def near(self, p, r):
        out = []; n = int(r // 4) + 1; cx = int(p[0] // 4); cz = int(p[1] // 4)
        for i in range(cx - n, cx + n + 1):
            for j in range(cz - n, cz + n + 1):
                out += self.grid.get((i, j), [])
        return [self.all_items[k] for k in out]

    def ground_near(self, x, z, y):
        """the piece ground at this point whose height is closest to y: (height, material, owner) or None"""
        ys, ix = self.S.hits(x, z); best = None
        for yy, k in zip(ys, ix):
            if self.S.kind[k] != 'ground': continue
            if best is None or abs(yy - y) < abs(best[0] - y): best = (float(yy), self.S.mat[k], int(self.S.own[k]))
        return best


class Finder:
    def __init__(self, ctx):
        self.c = ctx; self.faults = []; self.notes = []; self.counts = {}

    def add(self, kind, text, at, item=None, fix=None, mode='report', amount=None, sure='rule', extra=None):
        f = {'n': len(self.faults) + 1, 'kind': kind, 'text': text, 'at': [round(float(v), 3) for v in at], 'mode': mode, 'sure': sure}
        if amount is not None: f['amount'] = round(float(amount), 3)
        if item is not None:
            f['item'] = {'base': item.base, 'cond': item.cond, 'batch': item.bpath, 'index': item.idx, 'local': [round(float(v), 5) for v in item.local[9:12]]}
        if fix is not None: f['fix'] = fix
        if extra: f.update(extra)
        self.faults.append(f); self.counts[kind] = self.counts.get(kind, 0) + 1
        return f

    def fix_move(self, it, dy=0.0, turn=0.0, d=None):
        a = it.local[9:12]; to = a.copy()
        if d is not None: to = to + np.asarray(d, float)
        to[1] += dy
        f = {'op': 'move', 'base': it.base, 'cond': it.cond, 'at': [float(v) for v in a], 'to': [float(v) for v in to]}
        if abs(turn) > 1e-6: f['turn'] = float(turn)
        return f

    def fix_remove(self, it):
        return {'op': 'remove', 'base': it.base, 'cond': it.cond, 'at': [float(v) for v in it.local[9:12]]}

    # ------------------------------------------------------------------ props against what they stand on
    def supports(self, it, x, z):
        """heights of everything a ground prop may stand on at this point: piece ground, a building's own floors and
        steps, and the tops of props that are made to carry things"""
        ys, ix = self.c.S.hits(x, z)
        out = [(float(y), self.c.S.kind[k]) for y, k in zip(ys, ix)]
        for o in self.c.near((x, z), 6.0):
            if o is it or o.kind in ('tree', 'fence', 'post', 'gate'): continue
            if o.y1 > it.y0 + 0.2 or o.y1 < it.y0 - 1.5: continue
            if L.in_quad(o.quad, (x, z)): out.append((o.y1, 'prop'))
        return out

    def check_standing(self):
        c = self.c
        for it in c.items:
            if it.mount != 'ground' or it.kind in ('fence', 'post', 'gate', 'hedge'): continue
            if has(it.base, WF_STRUCT) or has(it.base, GROUND_COVER): continue
            x, z = (it.pos[0], it.pos[2]) if it.kind in ('tree', 'post_overhead') else (it.ctr[0], it.ctr[1])
            sup = self.supports(it, x, z)
            if not sup:
                # nothing under its middle: try its origin, then call it off the ground altogether
                sup = self.supports(it, it.pos[0], it.pos[2])
                if not sup:
                    self.add('off_ground', '%s stands over no ground of any piece' % it.base, it.pos, it, mode='choose', fix=self.fix_move(it))
                    continue
            d = [it.y0 - s for s, _ in sup]
            if min(abs(v) for v in d) <= TOL_AIR: continue
            if any(k == 'bld' and -0.2 <= v <= 0.4 for v, (s, k) in zip(d, sup)): continue      # on a roof or a porch: slopes and mesh detail
            below = [v for v in d if v > 0]; above = [(-v, k) for v, (s, k) in zip(d, sup) if v < 0 and k == 'ground']
            if below and (not above or min(below) < min(a for a, _ in above)):
                gap = min(below)
                it.lifted = gap > 1.2
                if has(it.base, FLAT) and gap < 0.10: continue
                self.add('in_air', '%s hangs %.2f m over what is under it' % (it.base, gap), it.pos, it, amount=gap,
                         mode='auto' if gap <= 1.2 else 'choose', fix=self.fix_move(it, dy=-gap),
                         sure='rule' if gap <= 1.2 else 'look: it may belong on a roof or a deck the check does not know')
            elif above:
                up = min(a for a, _ in above)
                lim = 0.30 if it.kind in ('tree', 'post_overhead') else TOL_SUNK      # trunks and poles are set into the ground
                if up <= lim: continue
                self.add('sunk', '%s is %.2f m into the ground' % (it.base, up), it.pos, it, amount=up, mode='auto' if up <= 1.0 else 'choose', fix=self.fix_move(it, dy=up),
                         sure='rule' if up <= 1.0 else 'look: more than 1 m, it may stand under a terrace on purpose')

    def check_fences(self):
        c = self.c
        panels = [it for it in c.all_items if it.kind in ('fence', 'gate')]
        posts = [it for it in c.all_items if it.kind == 'post']
        for it in c.items:
            if it.kind not in ('fence', 'gate', 'hedge', 'post') or it.mount != 'ground': continue      # (barbed wire rides on a wall's top)
            ax = it.along(); hl = max(it.half[0], 0.05)
            pts = [it.ctr + ax * hl * t for t in ((-0.95, -0.5, 0.0, 0.5, 0.95) if it.kind != 'post' else (0.0,))]
            # the ground a panel stands on is the HIGHER side of its line: along a terrace edge or a lot line between two
            # levels the low side has the retaining face under the panel, and that is not a gap
            # (a panel may also stand on the LOW side: Yasin's rule is "at the lowest ground along its length")
            side = np.array([-ax[1], ax[0]]); gs = []; gl = []
            for p in pts:
                hs = [c.S.ground(p[0] + side[0] * o, p[1] + side[1] * o) for o in (-0.3, 0.0, 0.3)]
                hs = [h[0] for h in hs if h is not None and abs(h[0] - it.y0) < 2.5]
                if hs: gs.append(max(hs)); gl.append(min(hs))
            if gs:
                gmin = min(gs)
                if it.y0 - gmin > 0.10:
                    self.add('fence_air', '%s: its low end hangs %.2f m over the ground' % (it.base, it.y0 - gmin), it.pos, it, amount=it.y0 - gmin, mode='auto',
                             fix=self.fix_move(it, dy=-(it.y0 - gmin) - 0.03))
                elif min(gl) - it.y0 > 0.25:
                    self.add('fence_sunk', '%s stands %.2f m into the ground along its whole length' % (it.base, min(gl) - it.y0), it.pos, it, amount=min(gl) - it.y0, mode='auto',
                             fix=self.fix_move(it, dy=(min(gl) - it.y0) - 0.03))
            if it.kind == 'fence' and it.scale > 1.03:
                self.add('fence_stretched', '%s is stretched to %.0f %% of its length' % (it.base, it.scale * 100), it.pos, it, amount=it.scale, mode='report')
            if it.kind == 'fence':
                for b in c.blds:
                    if b.quad is None: continue
                    q = b.pos[[0, 2]] + (b.quad - b.pos[[0, 2]]) * 0.9
                    if L.in_quad(q, it.ctr) and it.y0 < b.pos[1] + 1.0:
                        self.add('fence_in_building', '%s runs through %s' % (it.base, b.name), it.pos, it, mode='choose', fix=self.fix_remove(it), sure='rule'); break
        # a fence end that meets nothing (check_life.gd's rule, here WITH the neighbours loaded)
        ends = []
        for it in panels:
            if it.base.startswith('fence_temp_fence') or it.mount != 'ground': continue
            ax = it.along(); hl = it.half[0]
            ends.append((it.ctr + ax * hl, ax, it)); ends.append((it.ctr - ax * hl, -ax, it))
        for k, (p, dirn, it) in enumerate(ends):
            if it.inst.id != c.me.id or it.kind == 'gate': continue      # a gate closes a run: its own free end is the opening
            ok = False
            for j, (q, d2, o) in enumerate(ends):
                if j == k or (j ^ 1) == k: continue
                if abs(q[0] - p[0]) > 7 or abs(q[1] - p[1]) > 7: continue
                q2 = ends[j ^ 1][0]
                if L.seg_dist(p, q, q2) < 0.35: ok = True; break
                dd = q - p; ln = float(np.hypot(dd[0], dd[1]))
                if 0.5 < ln < 6.5 and float(dd @ dirn) / ln > 0.97 and float(d2 @ dirn) < -0.97: ok = True; break
            if not ok:
                for b in c.blds:
                    if b.quad is not None and L.quad_dist(b.quad, p) < 0.6: ok = True; break
            if not ok:
                for o in posts:
                    if abs(o.pos[0] - p[0]) < 0.3 and abs(o.pos[2] - p[1]) < 0.3:
                        # a post alone does not close a run: it must carry another panel
                        pass
                g = c.S.ground(p[0] + dirn[0] * 0.6, p[1] + dirn[1] * 0.6)
                if g is None: ok = True          # the run ends at the edge of everything that is loaded
            if not ok:
                self.add('fence_end', '%s: this end leads nowhere' % it.base, (p[0], it.y0, p[1]), it, mode='report')
        # a joint without a post (only where that fence type has posts in this piece at all)
        kinds_with_posts = set()
        for o in posts:
            kinds_with_posts.add(o.base.replace('_post', '').replace('fence_', ''))
        for it in c.items:
            if it.kind != 'fence': continue
            key = it.base.replace('fence_', '')
            fam = [k for k in kinds_with_posts if k in key or key in k]
            if not fam: continue
            ax = it.along()
            for s in (-1, 1):
                p = it.ctr + ax * it.half[0] * s
                # an end that lies inside the next panel's length is an overlap (a shortened run), not a joint
                lapped = False
                for o in panels:
                    if o is it or abs(o.ctr[0] - p[0]) > 3 or abs(o.ctr[1] - p[1]) > 3: continue
                    oa = o.ctr - o.along() * o.half[0]; ob = o.ctr + o.along() * o.half[0]
                    if L.seg_dist(p, oa, ob) < 0.1 and np.hypot(*(p - oa)) > 0.25 and np.hypot(*(p - ob)) > 0.25: lapped = True; break
                if lapped: continue
                if not any(abs(o.pos[0] - p[0]) < 0.25 and abs(o.pos[2] - p[1]) < 0.25 for o in posts):
                    if any(b.quad is not None and L.quad_dist(b.quad, p) < 0.5 for b in c.blds): continue
                    self.add('fence_no_post', '%s: no post at this joint' % it.base, (p[0], it.y0, p[1]), it, mode='report')

    # ------------------------------------------------------------------ props against each other and the buildings
    def check_overlap(self):
        c = self.c; seen = set()
        for it in c.items:
            if has(it.base, GROUND_COVER) or it.base.startswith('prop_shade_sail'): continue
            for o in c.near(it.ctr, 8.0):
                if o is it or (o.inst.id == it.inst.id and o.n <= it.n): continue
                if has(o.base, GROUND_COVER) or o.base.startswith('prop_shade_sail'): continue
                fa = it.kind in ('fence', 'post', 'gate'); fb = o.kind in ('fence', 'post', 'gate')
                if fa and fb: continue
                if it.kind == 'hedge' and o.kind == 'hedge': continue
                if has(it.base, WF_STRUCT) and has(o.base, WF_STRUCT): continue
                if (it.mount != 'ground') != (o.mount != 'ground') and (fa or fb): continue        # a vine or a light on a wall panel
                if it.y1 <= o.y0 + 0.08 or o.y1 <= it.y0 + 0.08: continue                           # one over the other
                if has(it.base, FLAT) or has(o.base, FLAT): continue
                if not L.quad_hit(it.quad, o.quad, 0.90): continue
                if it.base == o.base and np.hypot(*(it.pos[[0, 2]] - o.pos[[0, 2]])) < 0.03 and abs(it.pos[1] - o.pos[1]) < 0.03:
                    self.add('double', 'two %s in exactly the same place' % it.base, it.pos, it, mode='auto', fix=dict(self.fix_remove(it), nth=0)); continue
                key = (min(id(it), id(o)), max(id(it), id(o)))
                if key in seen: continue
                seen.add(key)
                # the one to move is the lighter thing: not a fence, not the bigger footprint
                mv = it
                if fa and not fb: mv = o
                elif not fa and not fb and (o.half[0] * o.half[1] < it.half[0] * it.half[1]) and o.inst.id == c.me.id: mv = o
                if mv.inst.id != c.me.id: mv = it
                other = o if mv is it else it
                self.add('overlap', '%s stands in the same space as %s' % (mv.base, other.base), mv.pos, mv, mode='choose', fix=self.fix_move(mv),
                         extra={'with': {'base': other.base, 'at': [round(float(v), 2) for v in other.pos], 'piece': other.inst.piece}})

    def check_buildings_props(self):
        c = self.c
        for it in c.items:
            if has(it.base, GROUND_COVER): continue
            lifted = it.mount != 'ground'
            for b in c.blds:
                if b.quad is None: continue
                if abs(b.pos[0] - it.ctr[0]) > 40 or abs(b.pos[2] - it.ctr[1]) > 40: continue
                up = it.y0 - b.pos[1]
                if not lifted and up < 1.2 and it.kind not in ('fence', 'post', 'gate'):
                    q = b.pos[[0, 2]] + (b.quad - b.pos[[0, 2]]) * 1.0
                    inner = L.rect_quad(b.pos[[0, 2]], (max(0.1, b.w * 0.5 - 0.15), max(0.1, b.d * 0.5 - 0.15)), b.yaw)
                    if L.quad_hit(it.quad, inner, 1.0) and L.in_quad(inner, it.ctr):
                        self.add('in_building', '%s stands inside %s' % (it.base, b.name), it.pos, it, mode='choose', fix=self.fix_move(it)); break
                    for nm, dp in b.doors:
                        zone = L.rect_quad(b.world([b.local(dp)[0], 0, b.d * 0.5 + 0.8])[[0, 2]], (0.75, 0.8), b.yaw)
                        if L.quad_hit(it.quad, zone, 1.0) and not has(it.base, FLAT):
                            self.add('door', '%s stands in front of the %s of %s' % (it.base, nm.replace('_', ' '), b.name), it.pos, it, mode='choose', fix=self.fix_move(it)); break
                    if b.open:
                        for o in b.open.get('openings', []):
                            if int(o.get('floor', 0)) != 0 or o['region'] not in ('O_rollup', 'O_garage', 'O_storefront', 'O_shopdoor', 'O_civic_door'): continue
                            deep = 4.0 if o['region'] in ('O_rollup', 'O_garage') else 1.2
                            fac = o['facade']; al = float(o['along']); hw = float(o['w']) * 0.5
                            if fac in ('front', 'back'):
                                s = 1.0 if fac == 'front' else -1.0
                                zc = b.world([al, 0, s * (b.d * 0.5 + deep * 0.5)]); hx, hz = hw, deep * 0.5
                            else:
                                s = 1.0 if fac == 'right' else -1.0
                                zc = b.world([s * (b.w * 0.5 + deep * 0.5), 0, al]); hx, hz = deep * 0.5, hw
                            zone = L.rect_quad(zc[[0, 2]], (hx, hz), b.yaw)
                            if L.in_quad(zone, it.ctr) and not has(it.base, FLAT):
                                what = {'O_rollup': 'roll-up door', 'O_garage': 'garage door', 'O_storefront': 'shop window', 'O_shopdoor': 'shop door', 'O_civic_door': 'door'}[o['region']]
                                self.add('opening', '%s stands in front of a %s of %s' % (it.base, what, b.name), it.pos, it, mode='choose', fix=self.fix_move(it),
                                         sure='rule' if deep > 2 else 'look: a display or a bench may belong at a shop window'); break
                    if b.kit.startswith('garages/'):
                        zone = L.rect_quad(b.world([0, 0, b.d * 0.5 + 2.5])[[0, 2]], (b.w * 0.5 - 0.3, 2.5), b.yaw)
                        if L.in_quad(zone, it.ctr) and not has(it.base, FLAT):
                            self.add('garage', '%s stands in front of the garage %s' % (it.base, b.name), it.pos, it, mode='choose', fix=self.fix_move(it)); break
            # wall items: on a wall, clear of every opening
            if it.mount == 'wall':
                on = None
                for b in c.blds:
                    if b.w <= 0: continue
                    lp = b.local(it.pos)
                    if abs(lp[0]) <= b.w * 0.5 + 0.15 and abs(abs(lp[2]) - b.d * 0.5) < 0.45: on = (b, 'front' if lp[2] > 0 else 'back', lp[0], lp)
                    elif abs(lp[2]) <= b.d * 0.5 + 0.15 and abs(abs(lp[0]) - b.w * 0.5) < 0.45: on = (b, 'right' if lp[0] > 0 else 'left', lp[2], lp)
                    if on: break
                if on is None:
                    near_wall = any(o.kind in ('fence', 'gate') and L.quad_dist(o.quad, it.pos[[0, 2]]) < 0.4 for o in c.near(it.pos[[0, 2]], 4.0))
                    if not near_wall and not it.base.startswith('plant_'):
                        near_any = any(b.quad is not None and L.quad_dist(b.quad, it.pos[[0, 2]]) < 1.6 for b in c.blds)
                        self.add('no_wall', '%s is a wall item with no wall behind it' % it.base, it.pos, it, mode='choose', fix=self.fix_move(it),
                                 sure='rule' if not near_any else 'look: it hangs under a porch or on a wall the footprint does not show')
                    continue
                b, fac, al, lp = on
                if lp[1] > b.h + 0.2:
                    self.add('over_roof', '%s hangs above the roof line of %s' % (it.base, b.name), it.pos, it, mode='choose', fix=self.fix_move(it))
                if b.open is None:
                    self.notes.append('wall items on %s: its doors and windows are not measured, not checked' % b.kit); continue
                if it.base == 'prop_ac_window':
                    inwin = any(o['facade'] == fac and abs(al - float(o['along'])) < float(o['w']) * 0.5 and float(o['y0']) - 0.3 < lp[1] < float(o['y1']) for o in b.open.get('openings', []) if 'win' in o['region'] or o['region'] in ('O_small_white', 'O_small_dark', 'O_ribbon', 'O_glass_plain'))
                    if not inwin: self.add('ac_no_window', 'window air conditioner not in a window of %s' % b.name, it.pos, it, mode='choose', fix=self.fix_move(it))
                    continue
                hw = float(it.man.get('footprint_w', 0.4)) * 0.5; y0 = lp[1]; y1 = lp[1] + float(it.man.get('height', 0.4))
                for o in b.open.get('openings', []):
                    if o['facade'] != fac: continue
                    if al - hw < float(o['along']) + float(o['w']) * 0.5 - 0.03 and al + hw > float(o['along']) - float(o['w']) * 0.5 + 0.03 and y0 < float(o['y1']) - 0.03 and y1 > float(o['y0']) + 0.03:
                        deep = min(float(o['along']) + float(o['w']) * 0.5 - (al - hw), (al + hw) - (float(o['along']) - float(o['w']) * 0.5), float(o['y1']) - y0, y1 - float(o['y0']))
                        self.add('over_opening', '%s hangs %.0f cm over a %s of %s' % (it.base, deep * 100, o['region'].replace('O_', '').replace('_', ' '), b.name), it.pos, it, amount=deep, mode='choose', fix=self.fix_move(it),
                                 sure='rule' if deep >= 0.12 else 'look: only its edge laps the opening'); break

    # ------------------------------------------------------------------ surfaces
    def check_surfaces(self):
        c = self.c; stalls = []
        for s in c.dump.meta.get('stalls', []) or []:
            p = c.me.pts([[float(s[0]), 0.0, float(s[1])]])[0]
            stalls.append(L.rect_quad(p[[0, 2]], (1.15, 2.4), math.radians(float(s[2]) + c.me.yaw)))
        fence_segs = [(o.ctr - o.along() * o.half[0], o.ctr + o.along() * o.half[0]) for o in c.all_items if o.kind == 'fence']
        for it in c.items:
            if it.mount != 'ground' or it.lifted: continue
            g = c.ground_near(it.pos[0], it.pos[2], it.y0)
            mat = g[1] if g else None; own = g[2] if g else None
            if g is None or abs(g[0] - it.y0) > 1.2: continue
            b = it.base
            if it.kind == 'tree' and mat in L.HARD + L.PAVED and mat != 'curb':
                self.add('tree_hard', '%s grows out of %s' % (b, mat), it.pos, it, mode='auto', fix=self.fix_remove(it))
            if it.kind == 'tree':
                for a, e in fence_segs:
                    if L.seg_dist(it.pos[[0, 2]], a, e) < 0.9:
                        self.add('tree_fence', '%s stands within 0.9 m of a fence' % b, it.pos, it, mode='report'); break
            if has(b, PLAY) and mat not in ('mulch', 'sand'):
                self.add('play_surface', '%s stands on %s, not on bark or sand' % (b, mat), it.pos, it, mode='choose', fix=self.fix_move(it))
            if b.startswith('prop_utility_pole') and mat in L.HARD:
                self.add('pole_asphalt', '%s stands on %s' % (b, mat), it.pos, it, mode='report', sure='rule (a pole carries wires: moving it means the wire piece too)')
            if has(b, SOFT_LIFE) and mat in L.HARD:
                self.add('on_asphalt', '%s stands on %s where vehicles go' % (b, mat), it.pos, it, mode='choose', fix=self.fix_move(it))
            elif mat in L.HARD and own is not None and own != c.me.id and not has(b, FLAT) and it.kind not in ('tree',):
                p = next((r.piece for r in c.neigh if r.id == own), '')
                if p.startswith(('s_', 'j_')): self.add('on_road', '%s stands on the road surface of %s' % (b, p), it.pos, it, mode='choose', fix=self.fix_move(it))
            for q in stalls:
                if L.in_quad(q, it.ctr) and not has(b, FLAT) and it.kind not in ('tree', 'post_overhead') and not b.startswith(('prop_bollard', 'prop_cart_corral')):
                    self.add('in_stall', '%s stands in a parking stall' % b, it.pos, it, mode='choose', fix=self.fix_move(it)); break
            if has(b, BANNED):
                self.add('banned', '%s: grass tufts are banned (16 Nov)' % b, it.pos, it, mode='auto', fix=self.fix_remove(it))
            if not c.me.piece.startswith(('s_', 'j_')):
                if b.startswith('prop_hydrant') or b.startswith('prop_hose_reel_cart'):
                    dwall = min([L.quad_dist(bb.quad, it.pos[[0, 2]]) for bb in c.blds if bb.quad is not None] or [99])
                    edge = self.edge_dist(it.pos[0], it.pos[2])
                    if dwall > 2.0 and edge > 2.5:
                        self.add('hydrant_nowhere', '%s stands %.1f m from any building wall and %.1f m inside the block' % (b, dwall, edge), it.pos, it, mode='choose', fix=self.fix_move(it))
                if has(b, BINS):
                    dwall = min([L.quad_dist(bb.quad, it.pos[[0, 2]]) for bb in c.blds if bb.quad is not None] or [99])
                    dfence = min([L.seg_dist(it.pos[[0, 2]], a, e) for a, e in fence_segs] or [99])
                    if dwall > 1.3 and dfence > 1.3 and not b.startswith('prop_dumpster'):
                        self.add('bin_open', '%s stands in the open (%.1f m from a wall, %.1f m from a fence)' % (b, dwall, dfence), it.pos, it, mode='choose', fix=self.fix_move(it))
            if b.startswith('prop_park_bench') or b.startswith('prop_bench_bus_stop') or b.startswith('prop_adirondack'):
                f = it.front(); p = it.pos[[0, 2]]
                blocked = lambda dirn: any(bb.quad is not None and L.quad_dist(bb.quad, p + dirn * 0.9) < 0.05 for bb in c.blds) or any(L.seg_dist(p + dirn * 0.8, a, e) < 0.35 for a, e in fence_segs)
                if blocked(f):
                    self.add('seat_faces_wall', '%s faces a wall or a fence at arm\'s length' % b, it.pos, it, mode='auto' if not blocked(-f) else 'choose',
                             fix=self.fix_move(it, turn=180.0) if not blocked(-f) else self.fix_move(it), sure='look: turned round it faces the other way; is there something to look at?')

    def piece_of(self, row_id):
        if row_id == self.c.me.id: return self.c.me.piece
        return next((r.piece for r in self.c.neigh if r.id == row_id), '')

    def is_drive(self, q):
        """a point on a drive: within 8 m in front of a garage, or on a parking stall of this piece"""
        c = self.c
        for b in c.blds:
            if b.kit.startswith('garages/') or 'garage' in b.kit:
                lp = b.local(q)
                if abs(lp[0]) <= b.w * 0.5 + 0.5 and -0.5 <= lp[2] - b.d * 0.5 <= 8.0: return True
        for s in c.dump.meta.get('stalls', []) or []:
            p = c.me.pts([[float(s[0]), 0.0, float(s[1])]])[0]
            if np.hypot(p[0] - q[0], p[2] - q[2]) < 3.0: return True
        return False

    _edge = None
    def edge_dist(self, x, z):
        """how far inside its own piece's ground a point lies (0 at the edge), by probing outward"""
        for r in (0.5, 1.0, 1.5, 2.0, 2.5, 3.0):
            for a in range(8):
                g = self.c.S.ground(x + r * math.cos(a * math.pi / 4), z + r * math.sin(a * math.pi / 4), own=self.c.me.id)
                if g is None: return r - 0.5
        return 3.0

    # ------------------------------------------------------------------ wear marks
    def check_wear(self):
        c = self.c
        for path, surf, V in c.dump.decals():
            if len(V) % 6: self.notes.append('wear mesh %s is not made of six-vertex marks: not checked' % path); continue
            W = c.me.pts(V[:, :3]).reshape(-1, 6, 3); U = V[:, 3:5].reshape(-1, 6, 2); A = V[:, 8].reshape(-1, 6)
            Lc = V[:, :3].reshape(-1, 6, 3)
            for k in range(len(W)):
                P = W[k]; ctr = P.mean(0)
                n = np.cross(P[1] - P[0], P[2] - P[0]); ln = np.linalg.norm(n)
                if ln < 1e-9 or abs(n[1]) / ln < 0.5: continue                          # an upright mark (kerb paint)
                uc = U[k].mean(0); tile = int(uc[0] * 4) + 4 * int(uc[1] * 4)
                name = TILE_NAME.get(tile, 'mark'); okm = TILE_OK.get(tile, L.HARD + L.PAVED)
                corners = np.unique(np.round(P, 4), axis=0)
                bad = None
                for p in list(corners) + [ctr]:
                    q = ctr + (p - ctr) * 0.9
                    g = c.ground_near(q[0], q[2], q[1])
                    if g is None or abs(g[0] - q[1]) > 0.25: bad = 'hangs over the edge of the ground'; break
                    # a street piece's paved ground is the SIDEWALK (Yasin 19 Nov: "i want no tire marks on the sidewalks
                    # too"): no tyre marks, no oil, no asphalt patches there. Inside a block, concrete carries tyre marks
                    # only as a drive: within 8 m of a garage or on a parking stall.
                    walk = g[1] in L.PAVED and self.piece_of(g[2]).startswith(('s_', 'j_'))
                    if walk and tile in (2, 3, 6, 7, 8, 15): bad = 'lies on the sidewalk'; break
                    if g[1] not in okm:
                        if tile in (8, 15) and g[1] in ('concrete', 'paving', 'plaza') and not walk and self.is_drive(q): continue
                        bad = 'lies on %s' % g[1]; break
                if bad is None:
                    for b in c.blds:
                        if b.quad is not None and L.in_quad(b.pos[[0, 2]] + (b.quad - b.pos[[0, 2]]) * 0.92, ctr[[0, 2]]) and ctr[1] < b.pos[1] + 0.5: bad = 'lies under the building %s' % b.name; break
                if bad:
                    lc = Lc[k].mean(0)
                    self.add('wear', '%s mark %s' % (name, bad), ctr, mode='auto', fix={'op': 'remove_decal', 'wear': path, 'surface': surf, 'at': [float(v) for v in lc]})

    # ------------------------------------------------------------------ ground (reported, not one item)
    def check_ground(self):
        c = self.c; me = c.me.id
        buried = 0.0; worst = 0.0; wat = None; sea = 0.0; n = 0
        for name, T in c.dump.ground():
            Tw = c.me.pts(T)
            nr = np.cross(Tw[:, 1] - Tw[:, 0], Tw[:, 2] - Tw[:, 0]); ln = np.linalg.norm(nr, axis=1)
            up = (ln > 1e-7) & (np.abs(nr[:, 1]) >= 0.5 * np.maximum(ln, 1e-12))
            Tu = Tw[up]; area = 0.5 * np.abs(nr[up, 1])
            ctr = Tu.mean(1)
            if not len(ctr): continue
            lh = c.land.at(ctr[:, 0], ctr[:, 2]); over = lh - ctr[:, 1]
            m = over > 0.05
            buried += float(area[m].sum()); n += len(ctr)
            if m.any() and float(over.max()) > worst: worst = float(over.max()); wat = ctr[int(np.argmax(over))]
            if name != 'sand': sea += float(area[ctr[:, 1] < 0.10].sum())
        if buried > 1.0:
            self.add('ground_buried', '%.0f m2 of this piece\'s ground lies under the land (deepest %.2f m)' % (buried, worst), wat, amount=buried, mode='report', sure='measured against the 4 m land grid')
        if sea > 1.0:
            self.add('ground_sea', '%.0f m2 of this piece\'s ground lies at or under sea level' % sea, (c.lo[0], 0, c.lo[1]), amount=sea, mode='report')
        # buildings against the ground they stand on
        for b in c.my_blds:
            if b.quad is None: continue
            ring = L.rect_quad(b.pos[[0, 2]], (b.w * 0.5 + 0.35, b.d * 0.5 + 0.35), b.yaw)
            hs = []
            for k in range(4):
                for t in np.linspace(0.05, 0.95, 7):
                    p = ring[k] + (ring[(k + 1) % 4] - ring[k]) * t
                    g = c.ground_near(p[0], p[1], b.pos[1])
                    if g: hs.append((g[0], p))
            if not hs: continue
            ys = np.array([h for h, _ in hs]); fl = b.pos[1]
            hi = float(ys.max()); lo = float(ys.min())
            if hi - fl > 0.12:
                self.add('building_sunk', '%s: the ground at its wall stands %.2f m over its floor' % (b.name, hi - fl), hs[int(np.argmax(ys))][1][[0, 0, 1]] * [1, 0, 1] + [0, hi, 0], amount=hi - fl, mode='report')
            if fl - lo > 0.30:
                self.add('building_floats', '%s: its floor stands %.2f m over the ground at its wall (no pad under it)' % (b.name, fl - lo), hs[int(np.argmin(ys))][1][[0, 0, 1]] * [1, 0, 1] + [0, lo, 0], amount=fl - lo, mode='report',
                         sure='look: a retaining face or a porch may close it')
            for nm, dp in b.doors:
                p = b.world([b.local(dp)[0], 0, b.d * 0.5 + 0.9])
                g = c.ground_near(p[0], p[2], fl)
                if g and abs(g[0] - fl) > 0.35:
                    self.add('door_step', '%s: the ground in front of its %s is %.2f m %s the floor' % (b.name, nm.replace('_', ' '), abs(g[0] - fl), 'over' if g[0] > fl else 'under'), (p[0], g[0], p[2]), amount=abs(g[0] - fl), mode='report',
                             sure='look: steps or a porch of the model may reach it')
            if not b.kit:
                self.add('no_kit_note', '%s carries no note of which kit model it is: the other checks skip it' % b.name, b.pos, mode='report')
        # the outer edge of the piece's ground against what lies beside it
        self.check_edges()

    def check_edges(self):
        c = self.c; me = c.me.id
        tris = []
        for name, T in c.dump.ground():
            Tw = c.me.pts(T)
            nr = np.cross(Tw[:, 1] - Tw[:, 0], Tw[:, 2] - Tw[:, 0]); ln = np.linalg.norm(nr, axis=1)
            tris.append(Tw[(ln > 1e-7) & (np.abs(nr[:, 1]) >= 0.5 * np.maximum(ln, 1e-12))])
        if not tris: return
        T = np.concatenate(tris)
        if not len(T): return
        P = T.reshape(-1, 3); key = np.round(P * 100).astype(np.int64)
        kid = (key[:, 0] + 400000) * 1_000_003 * 1_000_033 + (key[:, 1] + 100000) * 1_000_033 + (key[:, 2] + 400000)
        _, vid = np.unique(kid, return_inverse=True); vid = vid.reshape(-1, 3)
        e = np.concatenate([vid[:, [0, 1]], vid[:, [1, 2]], vid[:, [2, 0]]]); e.sort(axis=1)
        pa = np.concatenate([T[:, 0], T[:, 1], T[:, 2]]); pb = np.concatenate([T[:, 1], T[:, 2], T[:, 0]])
        ek = e[:, 0].astype(np.int64) * 4_000_037 + e[:, 1]
        _, first, cnt = np.unique(ek, return_index=True, return_counts=True)
        sel = first[cnt == 1]; A = pa[sel]; B = pb[sel]
        step_m = 0.0; step_worst = 0.0; step_at = None; gap_m = 0.0; gap_at = None
        for a, b in zip(A, B):
            d = b[[0, 2]] - a[[0, 2]]; l = float(np.hypot(d[0], d[1]))
            if l < 0.2: continue
            d = d / l; nrm = np.array([d[1], -d[0]]); mid = (a + b) / 2
            ins_p = c.S.ground(mid[0] + nrm[0] * 0.3, mid[2] + nrm[1] * 0.3, own=me); ins_m = c.S.ground(mid[0] - nrm[0] * 0.3, mid[2] - nrm[1] * 0.3, own=me)
            if (ins_p is None) == (ins_m is None): continue
            out = nrm if ins_p is None else -nrm
            m = max(1, int(math.ceil(l)))
            for q in range(m):
                p = a + (b - a) * ((q + 0.5) / m)
                o1 = c.ground_near(p[0] + out[0] * 0.25, p[2] + out[1] * 0.25, p[1])
                if o1 is not None and o1[2] != me:
                    st = abs(o1[0] - p[1])
                    if st > 0.03 and not (0.10 <= st <= 0.20 and o1[1] in L.HARD + ('curb',)):
                        step_m += l / m
                        if st > step_worst: step_worst = st; step_at = p
                elif o1 is None:
                    o2 = c.ground_near(p[0] + out[0] * 1.2, p[2] + out[1] * 1.2, p[1])
                    if o2 is not None and o2[2] != me:
                        gap_m += l / m
                        if gap_at is None: gap_at = p
        if step_m > 0.5:
            self.add('edge_step', '%.0f m of this piece\'s edge meets the piece beside it at another height (largest step %.2f m)' % (step_m, step_worst), step_at, amount=step_m, mode='report',
                     sure='measured; kerbs of 10-20 cm against a road are left out; x_wall_feet puts a face under the high side')
        if gap_m > 0.5:
            self.add('edge_gap', '%.0f m of this piece\'s edge has a strip of bare land between it and the piece beside it' % gap_m, gap_at, amount=gap_m, mode='report')

    # ------------------------------------------------------------------ trees (docs/TREE_PLAN.md) and the files' own faults
    def check_trees(self, kept):
        c = self.c
        for it in c.items:
            if it.kind != 'tree': continue
            self.add('tree_out', '%s: every builder tree goes (tree plan); trees come back by hand in the area\'s own tree list' % it.base, it.pos, it, mode='auto', fix=self.fix_remove(it), sure='Yasin 19 Nov')
            if any(np.hypot(k[0] - it.pos[0], k[1] - it.pos[2]) < 0.7 for k in kept): continue
            g = c.ground_near(it.pos[0], it.pos[2], it.y0)
            if g and g[1] == 'mulch' and g[2] == c.me.id:
                gl = [gg['path'] for gg in c.dump.j['ground']]
                self.add('well', 'the well of %s: paved over once its tree is gone, unless it is no well (the fixer tests it)' % it.base, it.pos, mode='auto', sure='Yasin 19 Nov',
                         fix={'op': 'fill_well', 'ground': gl[0] if gl else 'ground', 'at': [float(v) for v in it.local[9:12]], 'if_well': True})

    def check_files(self):
        c = self.c; tot = {}
        for b, X in c.dump.batches():
            if b['count'] == 0: self.add('empty_batch', 'the batch %s holds no instance' % b['path'], c.me.pos, mode='report'); continue
            tot.setdefault((b['base'], b['cond']), {}).setdefault(b['tier'], 0)
            tot[(b['base'], b['cond'])][b['tier']] += b['count']
            if not np.isfinite(X).all() or np.abs(X[:, :9]).sum() < 1e-6:
                self.add('empty_batch', 'the batch %s holds no real placement (saved without the renderer?)' % b['path'], c.me.pos, mode='report'); continue
            if b['tier'] in ('near', 'mid'):
                P = X[:, [9, 11]]; rad = float(np.linalg.norm(P - (P.min(0) + P.max(0)) / 2, axis=1).max())
                lim = 45.0 if b['tier'] == 'near' else 90.0
                if rad > lim + 2.0:
                    self.add('wide_batch', 'the batch %s spreads %.0f m from its middle (limit %.0f): its far props may never draw' % (b['path'], rad, lim), c.me.pts([[P[:, 0].mean(), 0, P[:, 1].mean()]])[0], amount=rad, mode='report',
                             sure='rule; split_props.gd mends it without moving anything')
        for (base, cond), t in tot.items():
            if len(set(t.values())) > 1:
                self.add('tier_count', '%s %s: its detail tiers hold different numbers of it (%s)' % (base, cond, ', '.join('%s %d' % kv for kv in sorted(t.items()))), c.me.pos, mode='report')

    def run(self, kept_trees=()):
        self.check_trees(kept_trees)
        self.check_standing()
        self.check_fences()
        self.check_overlap()
        self.check_buildings_props()
        self.check_surfaces()
        self.check_wear()
        self.check_ground()
        self.check_files()
        return self.faults


WHAT_IT_CHECKS = [
    ('tree_out / well', 'every tree and palm of the piece is listed to go; a well under one is listed to be paved'),
    ('in_air / sunk', 'each ground prop against what is under its middle: piece ground, a building\'s own floor or steps, a prop made to carry things'),
    ('fence_air / fence_sunk / fence_stretched / fence_in_building / fence_end / fence_no_post', 'each fence, wall, gate and hedge panel along its length'),
    ('overlap / double', 'two props in the same space (real outline of each model; trees by their trunk)'),
    ('in_building / door / opening / garage', 'a prop inside a building\'s footprint or in front of its doors, shop fronts, roll-ups, garage'),
    ('no_wall / over_roof / over_opening / ac_no_window', 'wall items against the wall, the roof line and the measured doors and windows'),
    ('tree_hard / tree_fence / play_surface / pole_asphalt / on_asphalt / on_road / in_stall / banned / hydrant_nowhere / bin_open / seat_faces_wall', 'surface and place rules from Yasin\'s corrections'),
    ('wear', 'each wear mark\'s corners and middle against the ground under it, the piece\'s edge and the buildings'),
    ('ground_buried / ground_sea / building_sunk / building_floats / door_step / edge_step / edge_gap', 'the piece\'s ground against the land, its buildings and its neighbours (reported only)'),
    ('empty_batch / wide_batch / tier_count / no_kit_note', 'faults of the file itself'),
]
CANNOT_SEE = [
    'whether a prop makes sense where it stands, or a yard reads as lived in: by eye',
    'tyre marks with no cause beside them (a braking mark with no stop line): only the surface is checked',
    'props on roofs and decks of models the check has no mesh for; over 1.2 m it asks instead of acting',
    'walk widths, parks that are too empty, repeated trees: not written yet',
    'the rooms: the indoor checker is a separate step',
]


def kept_trees():
    """trees of the hand-placed tree lists (zoning/trees/*.json): a well one stands in is not paved"""
    d = os.path.join(L.CK, 'zoning/trees'); out = []
    if os.path.isdir(d):
        for f in sorted(os.listdir(d)):
            if f.endswith('.json'):
                for t in json.load(open(os.path.join(d, f), encoding='utf-8')).get('trees', []): out.append((float(t['at'][0]), float(t['at'][-1])))
    return out


def plan_png(ctx, faults, path, px=8.0):
    try:
        from PIL import Image, ImageDraw
    except Exception:
        return False
    lo = ctx.lo - 6; hi = ctx.hi + 6
    W = int((hi[0] - lo[0]) * px); H = int((hi[1] - lo[1]) * px)
    if W * H > 60_000_000: px = px / 2; W //= 2; H //= 2
    im = Image.new('RGB', (W, H), (228, 226, 220)); dr = ImageDraw.Draw(im)
    col = {'asphalt': (88, 88, 92), 'white': (235, 235, 235), 'yellow': (228, 190, 70), 'concrete': (190, 188, 182), 'curb': (160, 158, 154), 'grass': (126, 168, 104), 'mulch': (142, 110, 84),
           'paving': (214, 204, 186), 'plaza': (150, 142, 132), 'gravel': (186, 180, 168), 'sand': (232, 216, 170), 'tactile': (220, 180, 60), 'wall': (150, 146, 140)}
    def xy(p): return ((p[0] - lo[0]) * px, (p[1] - lo[1]) * px)
    S = ctx.S
    order = np.argsort(S.T[:, :, 1].mean(1)) if len(S.T) else []
    for k in order:
        if S.kind[k] != 'ground': continue
        c0 = col.get(S.mat[k], (200, 200, 200))
        if S.own[k] != ctx.me.id: c0 = tuple(int(v * 0.6 + 255 * 0.4) for v in c0)
        dr.polygon([xy(S.T[k, e][[0, 2]]) for e in range(3)], fill=c0)
    for b in ctx.blds:
        if b.quad is not None: dr.polygon([xy(q) for q in b.quad], fill=(196, 150, 120) if b.inst.id == ctx.me.id else (214, 190, 176), outline=(90, 60, 40))
    for it in ctx.all_items:
        mine = it.inst.id == ctx.me.id
        c1 = (40, 110, 50) if it.kind == 'tree' else ((70, 70, 70) if it.kind in ('fence', 'post', 'gate') else ((60, 130, 60) if it.kind in ('hedge', 'plant') else (50, 70, 150)))
        if not mine: c1 = tuple(int(v * 0.5 + 255 * 0.5) for v in c1)
        if it.kind == 'tree': x, y = xy(it.pos[[0, 2]]); dr.ellipse([x - 5, y - 5, x + 5, y + 5], outline=c1)
        else: dr.polygon([xy(q) for q in it.quad], outline=c1)
    for f in faults:
        if f['kind'] in ('tree_out', 'well'): continue
        x, y = xy((f['at'][0], f['at'][2]))
        c2 = (210, 30, 30) if f['mode'] != 'report' else (200, 110, 0)
        dr.ellipse([x - 7, y - 7, x + 7, y + 7], outline=c2, width=2)
        dr.text((x + 8, y - 6), str(f['n']), fill=c2)
    im.save(path)
    return True


def find(piece, row=None, dump_dir=None, out=None, say=True):
    rows = L.load_layout()
    mine = [r for r in rows if r.piece == piece]
    if not mine: sys.exit('no layout row places %s' % piece)
    r = mine[0] if row is None else next(x for x in mine if x.id == row)
    names = sorted(set(x.piece for x in rows))
    L.ensure_dumps(names, say=say)
    ctx = Ctx(rows, r, dump_dir=dump_dir)
    F = Finder(ctx); F.run(kept_trees())
    out = out or os.path.join(L.OUT, 'find'); os.makedirs(out, exist_ok=True)
    fixes = []
    for f in F.faults:
        if 'fix' not in f: continue
        line = dict(f['fix']); line['n'] = f['n']; line['kind'] = f['kind']; line['mode'] = f['mode']; line['reason'] = f['text']
        fixes.append(line)
    res = {'piece': piece, 'row': r.id, 'pos': [float(v) for v in r.pos], 'yaw': r.yaw, 'sha256': ctx.dump.j.get('sha256'), 'placed': len(mine),
           'props': len(ctx.items), 'buildings': len(ctx.my_blds), 'neighbours': [x.piece for x in ctx.neigh], 'counts': F.counts,
           'checks': WHAT_IT_CHECKS, 'cannot_see': CANNOT_SEE, 'notes': sorted(set(F.notes)), 'faults': F.faults}
    json.dump(res, open(os.path.join(out, piece + '.faults.json'), 'w', encoding='utf-8'), indent=1)
    json.dump({'scene': piece, 'fixes': fixes}, open(os.path.join(out, piece + '.fixes.json'), 'w', encoding='utf-8'), indent=1)
    plan_png(ctx, F.faults, os.path.join(out, piece + '.plan.png'))
    if say:
        print('SUPERCHECK %s (row %d, used %d time(s)): %d props, %d buildings, %d pieces round it' % (piece, r.id, len(mine), len(ctx.items), len(ctx.my_blds), len(ctx.neigh)))
        for k, v in sorted(F.counts.items(), key=lambda kv: -kv[1]): print('  %-18s %4d' % (k, v))
        modes = {}
        for f in F.faults: modes[f['mode']] = modes.get(f['mode'], 0) + 1
        print('  one right answer: %d; a place to be chosen by hand: %d; reported only: %d' % (modes.get('auto', 0), modes.get('choose', 0), modes.get('report', 0)))
        for n in sorted(set(F.notes))[:6]: print('  note: ' + n)
    return res, ctx


if __name__ == '__main__':
    a = [x for x in sys.argv[1:] if not x.startswith('--')]
    if not a: sys.exit(__doc__)
    opt = dict(x[2:].split('=', 1) for x in sys.argv[1:] if x.startswith('--') and '=' in x)
    find(a[0], row=int(opt['row']) if 'row' in opt else None, dump_dir=opt.get('dump'), out=opt.get('out'))
