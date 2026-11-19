"""Superchecker: the rest of the list given to Yasin on 19 Nov, written in after he asked "why arent the check list
full yet? write them in", and the collisions ("checker should add collisions to everything that sit on the ground,
including columns of buildings, some of them lack it").

Two mix-ins: `More` for the outdoor finder (sc_find.Finder), `RoomMore` for the indoor one (sc_rooms.RoomFinder).
Everything here measures and lists; fix lines are the fixer's own kinds. Kinds that are new on 19 Nov evening have
been run on two blocks only: their "sure" note says "look" wherever a picture should confirm a finding.
"""
import json, math, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sc_lib as L

FLAT = ("prop_manhole", "prop_storm_drain", "prop_sprinkler_popup")
NO_COLLIDER_NEEDED = FLAT + ("plant_lawn_patch", "plant_iceplant", "prop_shade_sail", "prop_clothesline", "prop_tennis_net", "prop_volleyball_net", "prop_buoy_", "prop_sprinkler_impact",
                             "prop_balcony_clutter", "plant_bougainvillea_wall")
LOT_THINGS = ("prop_bollard", "prop_wheel_stop", "prop_cone", "prop_channelizer", "prop_barricade", "prop_k_rail", "prop_water_barrier", "prop_lot_light", "prop_cart_corral", "prop_shopping_cart",
              "prop_dumpster", "prop_container", "prop_speed", "prop_pay_station", "prop_parking_meter", "prop_fuel_pump", "prop_boat_trailer", "prop_golf_cart", "prop_temp_fence")
LIFE = ("prop_park_bench", "prop_picnic_table", "prop_patio_set", "prop_adirondack", "prop_bbq", "prop_play_structure", "prop_swing_set", "prop_slide")
PLAY = ("prop_play_structure", "prop_swing_set", "prop_slide")


def has(base, names):
    return any(base.startswith(n) for n in names)


def seg_d(p, a, b):
    """distance from point p [2] to segments a[n,2]-b[n,2]"""
    d = b - a; l2 = (d * d).sum(1)
    t = np.clip(((p - a) * d).sum(1) / np.maximum(l2, 1e-12), 0.0, 1.0)
    return np.linalg.norm(p - (a + d * t[:, None]), axis=1)


class More:
    # ------------------------------------------------------------------ the piece's own edges, once
    def edges(self):
        if hasattr(self, '_edges'): return self._edges
        c = self.c; me = c.me.id; ups = []; verts = []
        for name, T in c.dump.ground():
            Tw = c.me.pts(T)
            nr = np.cross(Tw[:, 1] - Tw[:, 0], Tw[:, 2] - Tw[:, 0]); ln = np.linalg.norm(nr, axis=1)
            up = (ln > 1e-7) & (np.abs(nr[:, 1]) >= 0.5 * np.maximum(ln, 1e-12))
            ups.append(Tw[up]); verts.append(Tw[(~up) & (ln > 1e-7)])
        self._edges = []; self._va = np.zeros((0, 2)); self._vb = np.zeros((0, 2)); self._vy = np.zeros((0, 2))
        T = np.concatenate(ups) if ups else np.zeros((0, 3, 3))
        if not len(T): return self._edges
        V = np.concatenate(verts)
        if len(V):      # upright faces as a line in the plan with a height range
            xz = V[:, :, [0, 2]]
            d01 = np.linalg.norm(xz[:, 0] - xz[:, 1], axis=1); d12 = np.linalg.norm(xz[:, 1] - xz[:, 2], axis=1); d20 = np.linalg.norm(xz[:, 2] - xz[:, 0], axis=1)
            pick = np.argmax(np.stack([d01, d12, d20], 1), 1); ia = np.array([0, 1, 2])[pick]; ib = np.array([1, 2, 0])[pick]
            r = np.arange(len(V)); self._va = xz[r, ia]; self._vb = xz[r, ib]; self._vy = np.stack([V[:, :, 1].min(1), V[:, :, 1].max(1)], 1)
        P = T.reshape(-1, 3); key = np.round(P * 100).astype(np.int64)
        kid = (key[:, 0] + 400000) * 1_000_003 * 1_000_033 + (key[:, 1] + 100000) * 1_000_033 + (key[:, 2] + 400000)
        _, vid = np.unique(kid, return_inverse=True); vid = vid.reshape(-1, 3)
        e = np.concatenate([vid[:, [0, 1]], vid[:, [1, 2]], vid[:, [2, 0]]]); e.sort(axis=1)
        pa = np.concatenate([T[:, 0], T[:, 1], T[:, 2]]); pb = np.concatenate([T[:, 1], T[:, 2], T[:, 0]])
        ek = e[:, 0].astype(np.int64) * 4_000_037 + e[:, 1]
        _, first, cnt = np.unique(ek, return_index=True, return_counts=True)
        sel = first[cnt == 1]
        for a, b in zip(pa[sel], pb[sel]):
            d = b[[0, 2]] - a[[0, 2]]; l = float(np.hypot(d[0], d[1]))
            if l < 0.2: continue
            d = d / l; nrm = np.array([d[1], -d[0]]); mid = (a + b) / 2
            ip = c.S.ground(mid[0] + nrm[0] * 0.3, mid[2] + nrm[1] * 0.3, own=me); im = c.S.ground(mid[0] - nrm[0] * 0.3, mid[2] - nrm[1] * 0.3, own=me)
            if (ip is None) != (im is None):
                out = nrm if ip is None else -nrm; m = max(1, int(math.ceil(l)))
                for q in range(m):
                    p = a + (b - a) * ((q + 0.5) / m)
                    inn = c.S.ground(p[0] - out[0] * 0.2, p[2] - out[1] * 0.2, own=me)
                    nb = c.ground_near(p[0] + out[0] * 0.25, p[2] + out[1] * 0.25, p[1])
                    if nb is not None and nb[2] == me: nb = None
                    self._edges.append(('outer', p, out, inn[1] if inn else None, nb, l / m))
            elif ip is not None and abs(ip[0] - im[0]) > 0.05:
                self._edges.append(('inner', mid, nrm, None, (ip[0], im[0]), l))
        return self._edges

    def more_ground(self):
        c = self.c; me = c.me.id
        step = 0.0; worst = 0.0; at = None; noap = 0.0; nat = None; self.mouths = []
        for kind, p, out, own_mat, nb, l in self.edges():
            if kind == 'inner':
                lo = min(nb); hi = max(nb)
                if len(self._va):
                    near = seg_d(p[[0, 2]], self._va, self._vb) < 0.15
                    cov = near & (self._vy[:, 0] <= lo + 0.06) & (self._vy[:, 1] >= hi - 0.06)
                    if cov.any(): continue
                step += l
                if hi - lo > worst: worst = hi - lo; at = p
            elif own_mat == 'asphalt' and nb is not None and self.piece_of(nb[2]).startswith(('s_', 'j_')):
                self.mouths.append(p)
                if nb[1] in ('grass', 'mulch') or abs(nb[0] - p[1]) > 0.06:
                    noap += l
                    if nat is None: nat = p
        if step > 0.5:
            self.add('ground_step', '%.0f m of steps inside this piece\'s own ground have no face between the two levels (highest %.2f m): you look under the upper sheet' % (step, worst), at, amount=step, sure='measured; look: a wall prop may stand there')
        if noap > 0.5:
            self.add('drive_no_apron', '%.0f m of this piece\'s asphalt meets the street across grass or a step, not at an apron' % noap, nat, amount=noap, sure='measured against the street piece beside it')
        # low ground near the sea (pads near water stand at 1.35 m or more)
        if c.land.sea is not None:
            i0 = int((c.lo[0] - 40 - c.land.u0) / c.land.s); i1 = int((c.hi[0] + 40 - c.land.u0) / c.land.s); j0 = int((c.lo[1] - 40 - c.land.v0) / c.land.s); j1 = int((c.hi[1] + 40 - c.land.v0) / c.land.s)
            if np.asarray(c.land.sea)[max(j0, 0):max(j1, 0) + 1, max(i0, 0):max(i1, 0) + 1].any():
                low = 0.0
                for name, T in c.dump.ground():
                    if name == 'sand': continue
                    Tw = c.me.pts(T); nr = np.cross(Tw[:, 1] - Tw[:, 0], Tw[:, 2] - Tw[:, 0]); y = Tw[:, :, 1].mean(1)
                    low += float((0.5 * np.abs(nr[:, 1]))[(y >= 0.10) & (y < 1.35)].sum())
                if low > 5.0: self.add('ground_low', '%.0f m2 of this piece\'s ground beside the sea stands under 1.35 m (floods and flickers against the sea plane)' % low, (c.lo[0], 1.0, c.lo[1]), amount=low)
        # buildings: slope round them, the garage door's drive, one in another, one off its block
        for b in c.my_blds:
            if b.quad is None: continue
            ring = L.rect_quad(b.pos[[0, 2]], (b.w * 0.5 + 0.35, b.d * 0.5 + 0.35), b.yaw); ys = []
            for k in range(4):
                for t in np.linspace(0.05, 0.95, 7):
                    q = ring[k] + (ring[(k + 1) % 4] - ring[k]) * t
                    g = c.ground_near(q[0], q[1], b.pos[1])
                    if g: ys.append(g[0])
            if ys and max(ys) - min(ys) > 0.30:
                self.add('building_slope', '%s: the ground round it differs by %.2f m: it has no level pad' % (b.name, max(ys) - min(ys)), b.pos, amount=max(ys) - min(ys), sure='measured')
            if b.kit.startswith('garages/'):
                q = b.world([0, 0, b.d * 0.5 + 1.0]); g = c.ground_near(q[0], q[2], b.pos[1])
                if g and abs(g[0] - b.pos[1]) > 0.10:
                    self.add('garage_step', '%s: the drive in front of its door is %.2f m %s its floor' % (b.name, abs(g[0] - b.pos[1]), 'over' if g[0] > b.pos[1] else 'under'), (q[0], g[0], q[2]), amount=abs(g[0] - b.pos[1]))
            for o in c.blds:
                if o is b or o.quad is None or (o.inst.id == me and id(o) < id(b)): continue
                if abs(o.pos[0] - b.pos[0]) > 60 or abs(o.pos[2] - b.pos[2]) > 60: continue
                qa = L.rect_quad(b.pos[[0, 2]], (max(0.1, b.w * 0.5 - 0.1), max(0.1, b.d * 0.5 - 0.1)), b.yaw); qb = L.rect_quad(o.pos[[0, 2]], (max(0.1, o.w * 0.5 - 0.1), max(0.1, o.d * 0.5 - 0.1)), o.yaw)
                if L.quad_hit(qa, qb, 1.0): self.add('building_overlap', '%s stands in %s' % (b.name, o.name), b.pos)
            inner = L.rect_quad(b.pos[[0, 2]], (max(0.1, b.w * 0.5 - 0.3), max(0.1, b.d * 0.5 - 0.3)), b.yaw); off = 0; road = False
            for k in range(4):
                for q in (inner[k], (inner[k] + inner[(k + 1) % 4]) / 2):
                    if c.S.ground(q[0], q[1], own=me) is None:
                        off += 1; g = c.S.ground(q[0], q[1])
                        if g and self.piece_of(g[2]).startswith(('s_', 'j_')): road = True
            if off: self.add('building_off_block', '%s reaches %s' % (b.name, 'onto a street piece' if road else 'beyond its own block\'s ground'), b.pos, sure='measured at %d of 8 points of its footprint' % off)

    # ------------------------------------------------------------------ where props stand
    def strip(self, it, axes, blds, fsegs):
        """how far paving runs from a prop along each of two axes: [(neg, pos), (neg, pos)] in metres (8 m at most)"""
        c = self.c; out = []
        for ax in axes:
            ext = []
            for sgn in (-1.0, 1.0):
                d = 0.0
                while d < 8.0:
                    q = it.ctr + ax * sgn * (d + 0.2)
                    g = c.ground_near(q[0], q[1], it.y0)
                    if g is None or g[1] not in L.PAVED or abs(g[0] - it.y0) > 0.4: break
                    if any(L.in_quad(b.quad, q) for b in blds): break
                    if fsegs is not None and len(fsegs[0]) and (seg_d(q, fsegs[0], fsegs[1]) < 0.12).any(): break
                    d += 0.2
                ext.append(d)
            out.append(ext)
        return out

    def more_props(self):
        import sc_find as F
        c = self.c; me = c.me.id
        ya = math.radians(c.me.yaw); ex = np.array([math.cos(ya), -math.sin(ya)]); ez = np.array([math.sin(ya), math.cos(ya)])
        fa = np.array([o.ctr - o.along() * o.half[0] for o in c.all_items if o.kind in ('fence', 'gate')] or np.zeros((0, 2))); fb = np.array([o.ctr + o.along() * o.half[0] for o in c.all_items if o.kind in ('fence', 'gate')] or np.zeros((0, 2)))
        stairs = [o for o in c.all_items if o.base.startswith('prop_dingbat_stair') or o.base.startswith('prop_quay_stair')]
        gates = [o for o in c.all_items if o.kind == 'gate']
        block = not c.me.piece.startswith(('s_', 'j_'))
        for it in c.items:
            if it.mount != 'ground' or it.lifted or it.kind in ('fence', 'post', 'gate', 'tree', 'post_overhead') or has(it.base, FLAT) or has(it.base, F.GROUND_COVER) or has(it.base, F.WF_STRUCT): continue
            g = c.ground_near(it.ctr[0], it.ctr[1], it.y0)
            if g is None or abs(g[0] - it.y0) > 1.2: continue
            mat = g[1]; own = g[2]
            # a building's own structure through the prop (the real mesh, not the footprint)
            ys, ix = c.S.hits(it.ctr[0], it.ctr[1])
            if it.y1 - it.y0 < 3.0 and any(c.S.kind[k] == 'bld' and it.y0 + 0.25 < y < it.y1 - 0.10 for y, k in zip(ys, ix)):
                self.add('in_model', '%s: a part of a building\'s own mesh passes through it' % it.base, it.pos, it, mode='choose', fix=self.fix_move(it), sure='look: an awning or a porch rail may be meant')
            # stair feet and gates
            for s in stairs:
                if s is not it and L.quad_dist(s.quad, it.ctr) < 1.5 and not L.in_quad(s.quad, it.ctr):
                    self.add('stair_foot', '%s stands within 1.5 m of an outdoor stair' % it.base, it.pos, it, mode='choose', fix=self.fix_move(it), sure='look: the rule is the stair\'s FOOT, 2.5 m; the check cannot tell which end that is'); break
            for gt in gates:
                zone = L.rect_quad(gt.ctr, (max(gt.half[0], 0.4), 1.3), gt.yaw)
                if L.in_quad(zone, it.ctr) and it.kind != 'hedge':
                    self.add('gate_blocked', '%s stands in the way through a gate' % it.base, it.pos, it, mode='choose', fix=self.fix_move(it)); break
            # lane mouths: where the piece's asphalt meets the street
            # (cloud-top, 19 Nov) not a traffic signal: a signal mast stands at the corner by the mouth on purpose
            # (j_rg_e660_n1000 and j_rg_nw_e0_n1600 lost theirs this way; put back)
            if mat in L.HARD and own == me and not has(it.base, LOT_THINGS) and not has(it.base, ('prop_signal',)) and any(np.hypot(m[0] - it.ctr[0], m[2] - it.ctr[1]) < 3.0 for m in getattr(self, 'mouths', [])):
                self.add('lane_mouth', '%s stands in the mouth of a drive or lane' % it.base, it.pos, it, mode='choose', fix=self.fix_move(it))
            # a narrow path (check_life.gd's rule): paved under it, planting on both sides across, paving both ways along
            if block and mat in ('concrete', 'paving', 'plaza'):
                for a1, a2 in ((ex, ez), (ez, ex)):
                    m = lambda q: (c.ground_near(q[0], q[1], it.y0) or (0, None))[1]
                    if m(it.ctr + a1 * 1.1) in L.SOFT and m(it.ctr - a1 * 1.1) in L.SOFT and m(it.ctr + a2 * 1.5) in L.PAVED and m(it.ctr - a2 * 1.5) in L.PAVED:
                        self.add('on_path', '%s stands in a narrow path' % it.base, it.pos, it, mode='choose', fix=self.fix_move(it)); break
            # the walk it stands on: how much of its width is left
            if mat in L.PAVED:
                near_b = [b for b in c.blds if b.quad is not None and abs(b.pos[0] - it.ctr[0]) < 40 and abs(b.pos[2] - it.ctr[1]) < 40]
                (xn, xp), (zn, zp) = self.strip(it, (ex, ez), near_b, (fa, fb))
                wx = xn + xp; wz = zn + zp
                cross = None
                if wx < 7.0 and wz >= max(3.0, wx): cross = (ex, xn, xp, wx)
                elif wz < 7.0 and wx >= max(3.0, wz): cross = (ez, zn, zp, wz)
                if cross is not None:
                    ax, n_, p_, w = cross; hw = float(np.abs((it.quad - it.ctr) @ ax).max())
                    clear = max(n_ - hw, p_ - hw) + 0.2
                    if w >= 1.4 and clear < 1.2 and has(it.base, ('prop_signal',)):
                        # (cloud-top, 19 Nov) a traffic signal post stands at the corner where its heads must be seen from
                        # the stop line: there is no other right place, and erasing it leaves an approach with no signal.
                        # The first street junctions lost three posts this way (j_ar_ad3, j_ar_ad5, j_ar_g3; put back).
                        self.add('walk_narrow', '%s leaves %.1f m of a %.1f m wide walk (a signal post: reported, not moved)' % (it.base, max(clear, 0.0), w), it.pos, it, amount=clear, mode='report', sure='a signal post belongs at its corner; look before calling it a fault')
                    elif w >= 1.4 and clear < 1.2:
                        self.add('walk_narrow', '%s leaves %.1f m of a %.1f m wide walk' % (it.base, max(clear, 0.0), w), it.pos, it, amount=clear, mode='choose', fix=self.fix_move(it), sure='measured across the paving it stands on; other things beside it are not counted')
                    if it.base.startswith('prop_bike_rack') and abs(float(it.along() @ ax)) > 0.7:
                        self.add('rack_across', 'the bike rack stands across the walk, not along it', it.pos, it, mode='choose', fix=self.fix_move(it, turn=90.0))
                if has(it.base, ('prop_vending', 'prop_ice_chest')) and self.piece_of(own).startswith(('s_', 'j_')):
                    self.add('vending_on_walk', '%s stands on the sidewalk' % it.base, it.pos, it, mode='choose', fix=self.fix_move(it))
            # over the edge of its block
            if block and own == me:
                offc = sum(1 for q in it.quad if c.S.ground(q[0], q[1], own=me) is None)
                if offc and it.kind in ('prop', 'plant'):
                    self.add('over_edge', '%s hangs over the edge of its block (%d of its 4 corners)' % (it.base, offc), it.pos, it, mode='choose', fix=self.fix_move(it))
            # seats and tables with no reason to be where they are
            if block and has(it.base, LIFE):
                dd = min([np.hypot(dp[0] - it.ctr[0], dp[2] - it.ctr[1]) for b in c.blds for _, dp in b.doors] or [99.0])
                dw = min([L.quad_dist(b.quad, it.ctr) for b in c.blds if b.quad is not None] or [99.0])
                mates = sum(1 for o in c.near(it.ctr, 6.0) if o is not it and has(o.base, LIFE) and np.hypot(*(o.ctr - it.ctr)) < 5.0)
                if dd > 18.0 and dw > 8.0 and mates == 0:
                    self.add('no_reason', '%s stands alone: no door within 18 m, no wall within 8 m, nothing to sit with' % it.base, it.pos, it, sure='look: Yasin\'s "why are those table and chairs there?"')
        # benches at picnic tables, sails over nothing, lamps turned from the road
        for it in c.items:
            b = it.base
            if b.startswith('prop_park_bench'):
                if any(o.base.startswith('prop_picnic_table') and L.quad_dist(o.quad, it.ctr) < 1.6 for o in c.near(it.ctr, 6.0)):
                    self.add('stray_bench', 'a bench stands beside a picnic table (the table has its own seats)', it.pos, it, mode='choose', fix=self.fix_move(it))
            if b.startswith('prop_shade_sail'):
                if not any(o is not it and has(o.base, LIFE) and L.in_quad(it.quad, o.ctr) for o in c.near(it.ctr, 8.0)):
                    self.add('sail_over_nothing', 'a shade sail with no table, seat or play item under it', it.pos, it, sure='rule: "a shade sail goes OVER the table it shades"')
            for name, vec, reach in (('prop_lamp_cobra', it.front(), 3.0), ('prop_signal_mast_arm', -it.along(), 4.0)):
                if b.startswith(name):
                    m = lambda q: (c.S.ground(q[0], q[1]) or (0, None))[1]
                    p = it.pos[[0, 2]]
                    if m(p + vec * reach) not in L.HARD and m(p - vec * reach) in L.HARD:
                        self.add('arm_away', '%s: its arm points away from the road' % b, it.pos, it, mode='auto', fix=self.fix_move(it, turn=180.0), sure='measured: asphalt lies behind it, not under its arm')
        # play areas and empty ground
        plays = [it for it in c.items if has(it.base, PLAY)]; seen = set()
        for it in plays:
            if it.n in seen: continue
            grp = [o for o in plays if np.hypot(*(o.ctr - it.ctr)) < 14.0]
            for o in grp: seen.add(o.n)
            if len(grp) < 3: self.add('park_empty', 'a play area with %d play item(s): a park needs three or more' % len(grp), it.pos, it, sure='rule: "parks are too empty, there is only a slide"')
        if block:
            pts = np.array([it.ctr for it in c.items] + [b.pos[[0, 2]] for b in c.my_blds] or np.zeros((0, 2)))
            cells = []
            for x in np.arange(c.lo[0] + 1, c.hi[0], 2.0):
                for z in np.arange(c.lo[1] + 1, c.hi[1], 2.0):
                    g = c.S.ground(x, z, own=me)
                    if g and g[1] in L.SOFT and (not len(pts) or np.hypot(pts[:, 0] - x, pts[:, 1] - z).min() > 12.0): cells.append((x, z, g[0]))
            if len(cells) * 4.0 >= 300.0:
                m = np.array(cells).mean(0)
                self.add('empty_area', '%.0f m2 of open ground with nothing within 12 m' % (len(cells) * 4.0), (m[0], m[2], m[1]), amount=len(cells) * 4.0, sure='look')

    # ------------------------------------------------------------------ fences and yards
    def more_fences(self):
        c = self.c; me = c.me.id
        panels = [o for o in c.all_items if o.kind == 'fence' and o.mount == 'ground']; seen = set()
        for it in c.items:
            if it.kind != 'fence' or it.mount != 'ground': continue
            ax = it.along(); nrm = np.array([-ax[1], ax[0]])
            if it.base.startswith('fence_chainlink') and not it.base.startswith('fence_chainlink_lot'):
                for s in (-1.0, 1.0):
                    g = c.S.ground(it.ctr[0] + nrm[0] * s * 1.5, it.ctr[1] + nrm[1] * s * 1.5)
                    if g and self.piece_of(g[2]).startswith(('s_', 'j_')):
                        self.add('chainlink_street', 'chain-link stands along a street', it.pos, it, sure='rule: "chain-link only round yards inside a block"; look: gritty front yards were built so'); break
            for o in panels:
                if o is it or (o.n, it.n) in seen or abs(float(o.along() @ ax)) < 0.95: continue
                d = o.ctr - it.ctr; across = abs(float(d @ nrm)); along = abs(float(d @ ax))
                if 0.25 < across < 1.5 and along < (it.half[0] + o.half[0]) * 0.5:
                    seen.add((it.n, o.n)); self.add('double_fence', '%s stands %.1f m behind %s' % (it.base, across, o.base), it.pos, it, amount=across, sure='rule: "never one fence behind another"'); break
        # every house's back yard closed: flood from behind the house, stopped by fences, walls, gates, hedges, buildings
        houses = [b for b in c.my_blds if b.kit.startswith('houses/') and b.quad is not None]
        if not houses: return
        q = 0.5; x0 = c.lo[0] - 2; z0 = c.lo[1] - 2; nx = int((c.hi[0] - c.lo[0] + 4) / q) + 1; nz = int((c.hi[1] - c.lo[1] + 4) / q) + 1
        wall = np.zeros((nz, nx), bool)
        def mark(p):
            i = int((p[0] - x0) / q); j = int((p[1] - z0) / q)
            if 0 <= i < nx and 0 <= j < nz: wall[j, i] = True
        for o in c.all_items:
            if o.kind not in ('fence', 'gate', 'hedge') or o.mount != 'ground': continue
            ax = o.along(); n2 = np.array([-ax[1], ax[0]]); hl = o.half[0] + 0.15
            for t in np.arange(-hl, hl + 0.01, 0.2):
                for w in (-0.2, 0.0, 0.2): mark(o.ctr + ax * t + n2 * w)
        for b in c.blds:
            if b.quad is None: continue
            for u in np.arange(-b.w / 2, b.w / 2 + 0.01, 0.25):
                for v in np.arange(-b.d / 2, b.d / 2 + 0.01, 0.25): mark(b.world([u, 0, v])[[0, 2]])
        kindmap = {}
        def cell_kind(i, j):
            if (i, j) not in kindmap:
                g = c.S.ground(x0 + (i + 0.5) * q, z0 + (j + 0.5) * q)
                kindmap[(i, j)] = 'out' if (g is None or g[2] != me) else ('hard' if g[1] in L.HARD else 'soft')
            return kindmap[(i, j)]
        for b in houses:
            st = b.world([0, 0, -b.d * 0.5 - 2.5])[[0, 2]]
            i = int((st[0] - x0) / q); j = int((st[1] - z0) / q)
            if not (0 <= i < nx and 0 <= j < nz) or wall[j, i] or cell_kind(i, j) != 'soft': continue
            todo = [(i, j)]; seen2 = {(i, j)}; leak = None
            while todo and len(seen2) < 6000 and leak is None:
                ci, cj = todo.pop()
                for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ni, nj = ci + di, cj + dj
                    if (ni, nj) in seen2 or not (0 <= ni < nx and 0 <= nj < nz) or wall[nj, ni]: continue
                    k = cell_kind(ni, nj)
                    if k != 'soft': leak = (x0 + (ni + 0.5) * q, z0 + (nj + 0.5) * q, k); break
                    seen2.add((ni, nj)); todo.append((ni, nj))
            if leak:
                self.add('yard_open', '%s: its back yard is not closed: you walk from behind the house %s without passing a fence or a gate' % (b.name, 'onto asphalt' if leak[2] == 'hard' else 'out of the block'), (leak[0], b.pos[1], leak[1]),
                         sure='measured by walking a 0.5 m grid from 2.5 m behind the house; mending it is a fence, not one item')

    # ------------------------------------------------------------------ wear: oil, patches
    def more_wear(self):
        import sc_find as F
        c = self.c; street = c.me.piece.startswith(('s_', 'j_'))
        covers = [it.ctr for it in c.all_items if it.base.startswith(('prop_manhole', 'prop_storm_drain'))]
        for path, surf, V in c.dump.decals():
            if len(V) % 6: continue
            W = c.me.pts(V[:, :3]).reshape(-1, 6, 3); U = V[:, 3:5].reshape(-1, 6, 2); C = V[:, 5:8].reshape(-1, 6, 3); Lc = V[:, :3].reshape(-1, 6, 3)
            for k in range(len(W)):
                P = W[k]; ctr = P.mean(0); n = np.cross(P[1] - P[0], P[2] - P[0]); ln = np.linalg.norm(n)
                if ln < 1e-9 or abs(n[1]) / ln < 0.5: continue
                uc = U[k].mean(0); tile = int(uc[0] * 4) + 4 * int(uc[1] * 4)
                g = c.ground_near(ctr[0], ctr[2], ctr[1])
                if g is None: continue
                if tile in (6, 7) and not street and g[1] != 'asphalt' and g[2] == c.me.id and not self.is_drive(ctr):
                    near_roll = False
                    for b in c.blds:
                        if b.open and any(o['region'] in ('O_rollup', 'O_garage') for o in b.open.get('openings', [])) and b.quad is not None and L.quad_dist(b.quad, ctr[[0, 2]]) < 8.0: near_roll = True; break
                    if not near_roll:
                        self.add('oil_no_car', 'an oil mark on %s with no stall, garage or roll-up door near it' % g[1], ctr, mode='auto', fix={'op': 'remove_decal', 'wear': path, 'surface': surf, 'at': [float(v) for v in Lc[k].mean(0)]}, sure='rule: "oil where cars park"')
                if street and tile in (2, 3) and g[1] in L.HARD:
                    sx = float(np.linalg.norm(P[1] - P[0])); sz = float(np.linalg.norm(P[2] - P[1]))
                    if max(sx, sz) / max(min(sx, sz), 0.01) < 3.0 and not any(np.hypot(cv[0] - ctr[0], cv[1] - ctr[2]) < 2.5 for cv in covers):
                        self.add('patch_alone', 'a dark patch alone on the road (%.1f x %.1f m): it reads as the shadow of nothing' % (sx, sz), ctr, sure='rule of 17 Nov: dark patches only as long narrow trench strips or round a manhole; a locked street piece')
                if tile in (4, 5) and float(C[k].mean()) > 0.8:
                    self.add('pale_white', 'a pale patch left white (tint %.2f): it reads as a white square' % float(C[k].mean()), ctr, sure='rule of 16 Nov: pale patches tinted grey, about 0.5')

    # ------------------------------------------------------------------ stalls, wires
    def more_misc(self):
        c = self.c
        for s in c.dump.meta.get('stalls', []) or []:
            p = c.me.pts([[float(s[0]), 0.0, float(s[1])]])[0]; q = L.rect_quad(p[[0, 2]], (1.0, 2.2), math.radians(float(s[2]) + c.me.yaw))
            for b in c.blds:
                if b.quad is None or (b.kit.startswith('garages/') or 'carport' in b.kit): continue
                inner = L.rect_quad(b.pos[[0, 2]], (max(0.1, b.w * 0.5 - 0.2), max(0.1, b.d * 0.5 - 0.2)), b.yaw)
                if L.quad_hit(q, inner, 1.0): self.add('stall_in_building', 'a parking stall lies inside %s (a parked car is drawn there)' % b.name, (p[0], b.pos[1], p[2])); break
        W = getattr(c, 'wires', None)
        if W is None or not len(W):
            poles = [it for it in c.items if it.base.startswith('prop_utility_pole')]
            if poles: self.add('pole_no_wire', '%d utility poles and no wire piece anywhere near: the poles carry nothing' % len(poles), poles[0].pos, poles[0], amount=len(poles), sure='measured: no w_* piece reaches this piece')
            return
        for b in c.my_blds:
            if b.quad is None: continue
            lp = (W - b.pos) @ np.linalg.inv(b.B)
            ins = (np.abs(lp[:, 0]) < b.w * 0.5 - 0.3) & (np.abs(lp[:, 2]) < b.d * 0.5 - 0.3) & (lp[:, 1] > 1.0) & (lp[:, 1] < b.h - 0.4)
            if ins.sum() >= 2: self.add('wire_in_building', 'a wire runs through %s (%d of its points inside the walls)' % (b.name, int(ins.sum())), W[np.argmax(ins)], amount=int(ins.sum()), sure='measured against the footprint and height')
        for it in c.items:
            if not it.base.startswith('prop_utility_pole'): continue
            d = np.hypot(W[:, 0] - it.pos[0], W[:, 2] - it.pos[2])
            if not ((d < 2.0) & (np.abs(W[:, 1] - it.y1) < 3.5)).any():
                self.add('pole_no_wire', 'a utility pole with no wire on it', it.pos, it, sure='measured: no wire point within 2 m of its top')

    # ------------------------------------------------------------------ collisions (Yasin 19 Nov)
    def more_collisions(self):
        import sc_find as F
        c = self.c
        X, grp = c.dump.cols()
        Xw = c.me.xf(X)[:, 9:12] if len(X) else np.zeros((0, 3))
        missing = {}
        for it in c.items:
            if it.mount != 'ground' or it.lifted or it.kind == 'tree' or has(it.base, NO_COLLIDER_NEEDED) or has(it.base, F.WF_STRUCT): continue
            if (it.y1 - it.y0) < 0.25: continue                                  # flat things underfoot
            g0 = c.S.ground(it.ctr[0], it.ctr[1])
            if g0 is not None and it.y0 - g0[0] > 1.5: continue                   # on a roof: nobody walks into it
            if len(Xw) and (np.linalg.norm(Xw - it.pos, axis=1) < 0.03).any(): continue
            missing[it.base] = missing.get(it.base, 0) + 1
            self.add('no_collision', '%s has no collision: you walk and drive through it' % it.base, it.pos, it, mode='auto', sure='measured: no collider at its place',
                     fix={'op': 'add_collider', 'base': it.base, 'cond': it.cond, 'at': [float(v) for v in it.local[9:12]]})
        # the buildings' own columns and posts: parts of the near mesh between 0.4 and 1.6 m up with no collision near
        seen = {}
        for b in c.my_blds:
            if b.model not in seen: seen[b.model] = columns_without_collision(b.model)
            cols = seen[b.model]
            if cols is None: continue
            for k, (cx, cz, sx, sz, y0, y1) in enumerate(cols):
                if any(abs(bx[0] - cx) <= bx[3] / 2 + 0.05 and abs(bx[2] - cz) <= bx[5] / 2 + 0.05 for bx in b.boxes): continue      # this building already carries a box there
                w = b.world([cx, (y0 + y1) / 2, cz])
                self.add('column_no_collision', '%s: a %.1f x %.1f m column or post of the building has no collision' % (b.name, sx, sz), w, mode='auto', sure='measured: the model\'s mesh stands there between 0.4 and 1.6 m up, its collision shape does not; look at big ones',
                         fix={'op': 'add_box', 'node': next(x['path'] for x in c.dump.j['buildings'] if x['name'] == b.name and np.allclose(c.me.xf([x['xf']])[0][9:12], b.pos, atol=1e-3)),
                              'at': [float(v) for v in c.me.pts_inv(w)], 'box': [float(cx), float((y0 + y1) / 2), float(cz), float(sx + 0.04), float(y1 - y0), float(sz + 0.04)], 'name': 'sc_col_%d' % k})

    def run_more(self):
        for fn in (self.more_ground, self.more_props, self.more_fences, self.more_wear, self.more_misc, self.more_collisions):
            try: fn()
            except Exception as e:
                import traceback
                self.notes.append('the check "%s" stopped with an error and is NOT in this result: %s' % (fn.__name__, str(e)[:120]))
                self.err = traceback.format_exc()


_colcache = {}
def columns_without_collision(key):
    """small upright parts of a building model that its own collision shape does not cover:
    [(centre x, centre z, size x, size z, y0, y1)] in the model's frame; None when the model was never read out"""
    if key in _colcache: return _colcache[key]
    M = L.Kit.model(key); C = L.Kit.model_col(key)
    if M is None or C is None: _colcache[key] = None; return None
    q = 0.25
    def occupancy(T, lo, hi):
        occ = set()
        if not len(T): return occ
        ymin = T[:, :, 1].min(1); ymax = T[:, :, 1].max(1)
        for t in T[(ymin < hi) & (ymax > lo)]:
            for a, b in ((0, 1), (1, 2), (2, 0)):
                p0 = t[a]; p1 = t[b]; n = max(2, int(np.linalg.norm(p1 - p0) / 0.12) + 1)
                for s in np.linspace(0, 1, n):
                    p = p0 + (p1 - p0) * s
                    if lo <= p[1] <= hi: occ.add((int(math.floor(p[0] / q)), int(math.floor(p[2] / q))))
        return occ
    near = occupancy(M, 0.4, 1.6); col = occupancy(C, 0.2, 2.2)
    colx = set()
    for (i, j) in col:
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1): colx.add((i + di, j + dj))
    free = [cc for cc in near if cc not in colx]
    out = []; left = set(free)
    while left:
        st = left.pop(); grp = [st]; todo = [st]
        while todo:
            ci, cj = todo.pop()
            for di in (-1, 0, 1):
                for dj in (-1, 0, 1):
                    n2 = (ci + di, cj + dj)
                    if n2 in left: left.remove(n2); grp.append(n2); todo.append(n2)
        g = np.array(grp); sx = (g[:, 0].max() - g[:, 0].min() + 1) * q; sz = (g[:, 1].max() - g[:, 1].min() + 1) * q
        if sx > 1.6 or sz > 1.6: continue                       # a wall or a rail with no collision: reported apart, not boxed
        cx = (g[:, 0].min() + g[:, 0].max() + 1) * q / 2; cz = (g[:, 1].min() + g[:, 1].max() + 1) * q / 2
        # its real extent from the mesh's own points in that square
        P = M.reshape(-1, 3); m = (np.abs(P[:, 0] - cx) <= sx / 2 + 0.05) & (np.abs(P[:, 2] - cz) <= sz / 2 + 0.05) & (P[:, 1] < 3.2)
        if m.sum() < 6: continue
        Q = P[m]
        if Q[:, 1].max() - Q[:, 1].min() < 1.0: continue           # not an upright thing
        out.append((float((Q[:, 0].min() + Q[:, 0].max()) / 2), float((Q[:, 2].min() + Q[:, 2].max()) / 2), float(max(Q[:, 0].max() - Q[:, 0].min(), 0.12)), float(max(Q[:, 2].max() - Q[:, 2].min(), 0.12)), float(max(Q[:, 1].min(), 0.0)), float(Q[:, 1].max())))
    _colcache[key] = out
    return out


# ============================================================================================ indoors
class RoomMore:
    def more_rooms(self):
        import sc_rooms as R
        r = self.r; fl = self.floor_items()
        a = R.assignments().get(r.name) or {}
        model = str(a.get('model', '')); con = L.Kit.openings(model) if model else None
        # ---- the room against its building: floor level, openings
        if con:
            T = r.dump.shell()
            if len(T):
                n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]); ln = np.linalg.norm(n, axis=1)
                upf = T[(ln > 1e-7) & (np.abs(n[:, 1]) > 0.9 * np.maximum(ln, 1e-12))]
                if len(upf):
                    fy = float(np.round(upf[:, :, 1].mean(1), 2).min()); want = float((con.get('floors') or [{}])[0].get('y', 0.0))
                    if abs(fy - want) > 0.08: self.add('floor_level', 'the room\'s floor stands at %.2f m, the building\'s floor at %.2f m' % (fy, want), (r.cx, fy, r.cz), amount=abs(fy - want), sure='measured from the room\'s lowest face against the building\'s measured sill')
            bay = a.get('bay')
            mine = []
            for o in r.open:
                ax, p, a0, a1 = o[0], float(o[1]), float(o[2]), float(o[3])
                fac = ('front' if p > 0 else 'back') if ax == 'z' else ('right' if p > 0 else 'left')
                mine.append((fac, a0, a1, o[-1]))
                ok = any(c2['facade'] == fac and int(c2.get('floor', 0)) == 0 and min(a1, float(c2['along']) + float(c2['w']) / 2) - max(a0, float(c2['along']) - float(c2['w']) / 2) > 0.5 * min(a1 - a0, float(c2['w'])) for c2 in con.get('openings', []))
                if not ok: self.add('opening_no_match', 'the room has a %s on its %s wall where the building shows none' % (o[-1], fac), (r.cx, 1.2, r.cz), sure='measured against the building\'s own doors and windows')
            if r.open:
                for c2 in con.get('openings', []):
                    if int(c2.get('floor', 0)) != 0 or float(c2['w']) < 0.7: continue
                    al = float(c2['along']); fac = c2['facade']
                    if bay and fac in ('front', 'back') and not (float(bay[0]) + 0.2 <= al <= float(bay[1]) - 0.2): continue
                    if bay and fac in ('left', 'right') and not ((fac == 'left' and float(bay[0]) <= -(con.get('footprint_wd', [0, 0])[0]) / 2 + 0.6) or (fac == 'right' and float(bay[1]) >= con.get('footprint_wd', [0, 0])[0] / 2 - 0.6)): continue
                    if not any(f2 == fac and a0 - 0.2 <= al <= a1 + 0.2 for f2, a0, a1, _ in mine):
                        self.add('opening_missed', 'the building shows a %s on its %s side at %.1f m that the room does not have: a painted one with a wall behind' % (c2['region'].replace('O_', '').replace('_', ' '), fac, al), (r.cx, 1.2, r.cz), sure='look')
            # ---- the shop's front and its sign boards
            if 'ck_grt_row2' in model: self.add('shop_painted_windows', 'this model\'s windows are painted boarded: never an open shop', (r.cx, 0, r.cz))
            da = a.get('door_along')
            if da is not None:
                regs = [c2['region'] for c2 in con.get('openings', []) if int(c2.get('floor', 0)) == 0 and abs(float(c2['along']) - float(da)) < 0.5 and c2['facade'] == 'front']
                if regs and not any(x in ('O_shopdoor', 'O_storefront', 'O_civic_door', 'O_rollup', 'O_glass_plain') for x in regs):
                    self.add('shop_house_door', 'the shop sits behind a house door (%s): the room cut does not open it as a shop front' % ', '.join(sorted(set(x.replace('O_', '') for x in regs))), (r.cx, 0, r.cz), sure='look')
            named = a.get('signs') or []
            name_words = set(w.lower() for w in str(r.shop.get('name', '')).replace('&', ' ').split() if len(w) > 2)
            for sg in con.get('signs', []) or []:
                al = float(sg.get('along', 0)); fac = sg.get('facade', 'front')
                if bay and fac in ('front', 'back') and not (float(bay[0]) <= al <= float(bay[1])): continue
                if any(str(x.get('facade')) == fac and abs(float(x.get('along', 99)) - al) < 0.6 for x in named): continue
                txt = str(sg.get('text', '')).strip()
                if txt and not (set(w.lower() for w in txt.split()) & name_words):
                    self.add('sign_wrong', 'the building\'s painted sign says "%s"; the shop is "%s" and no plate covers it' % (txt, r.shop.get('name', '?')), (r.cx, 2.8, r.cz), sure='from the model\'s measured sign boards and the room\'s list of plates')
                elif not txt:
                    self.add('sign_blank', 'a sign board of the building (%s side, at %.1f m) is left blank' % (fac, al), (r.cx, 2.8, r.cz), sure='from the model\'s measured sign boards and the room\'s list of plates')
        elif model: self.add('not_measured', 'the building model %s has no measured doors, windows and sign boards: the room is not checked against it' % model, (r.cx, 0, r.cz), sure='a gap of the check')
        # ---- the shop window shows nothing
        for o in r.open:
            if o[-1] != 'window' or float(o[3]) - float(o[2]) < 1.4 or float(o[4]) > 0.95: continue
            z, _ = r.zone(o, 1.6)
            if not any(L.quad_hit(it.quad, z, 1.0) for it in r.items):
                self.add('window_empty', 'a %.1f m shop window with nothing behind it within 1.6 m' % (float(o[3]) - float(o[2])), z.mean(0)[[0, 0, 1]] * [1, 0, 1], sure='rule: "a display or seating in the window"; look')
        # ---- seats without their table, stools without a bar
        tables = [it for it in fl if has(it.base, ('prop_cafe_table', 'prop_restaurant_table', 'prop_office_desk', 'prop_nail_table', 'prop_display_table', 'prop_shop_counter', 'prop_bar_counter', 'prop_checkout_counter', 'prop_laundry_counter', 'prop_workbench', 'prop_mirror_station'))]
        for it in fl:
            if it.base in ('prop_cafe_chair', 'prop_bar_stool'):
                if not any(L.quad_dist(t.quad, it.ctr) < 0.9 for t in tables):
                    self.add('chair_alone' if it.base == 'prop_cafe_chair' else 'stool_alone', '%s stands at no table, bar or counter' % it.base.replace('prop_', ''), it.pos, it, sure='look')
        # ---- things standing on furniture: sunk into it or hovering over it
        for it in r.items:
            if it.mount == 'wall' or it.y0 < 0.3: continue
            under = [o for o in fl if o is not it and L.in_quad(o.quad, it.ctr)]
            if not under: continue
            top = max(o.y1 for o in under)
            if it.y0 > top + 0.05:
                self.add('hovers', '%s hovers %.0f cm over the %s under it' % (it.base.replace('prop_', ''), (it.y0 - top) * 100, under[0].base.replace('prop_', '')), it.pos, it, amount=it.y0 - top, mode='auto',
                         fix={'op': 'move', 'base': it.base, 'cond': it.cond, 'at': [float(v) for v in it.local[9:12]], 'to': [float(it.local[9]), float(it.local[10] - (it.y0 - top)), float(it.local[11])]})
            elif it.y0 < top - 0.40:
                self.add('sunk_in', '%s stands %.0f cm inside the %s under it' % (it.base.replace('prop_', ''), (top - it.y0) * 100, under[0].base.replace('prop_', '')), it.pos, it, amount=top - it.y0, sure='look: measured against the furniture\'s highest point, its top may be lower')
        # ---- the staff door lines up with the back door
        backs = [o for o in r.open if o[-1] == 'door' and not any(o[0] == e[0] and abs(float(o[1]) - float(e[1])) < 0.05 for e in r.entr)]
        parts = [s for s in r.solids if (s[2] - s[0]) > 3 * (s[3] - s[1])]
        for o in backs:
            if o[0] != 'z' or not parts: continue
            zp = float(parts[0][1]); row = sorted((s[0], s[2]) for s in parts if abs(s[1] - zp) < 0.3)
            x0 = min(f[0] for f in r.floors); x1 = max(f[2] for f in r.floors); gaps = []; cur = x0
            for a0, a1 in row:
                if a0 - cur > 0.6: gaps.append((cur, a0))
                cur = max(cur, a1)
            if x1 - cur > 0.6: gaps.append((cur, x1))
            if gaps and not any(min(g1, float(o[3])) - max(g0, float(o[2])) > 0.5 for g0, g1 in gaps):
                self.add('staff_door_off', 'the way through the partition does not line up with the back door', ((float(o[2]) + float(o[3])) / 2, 1.0, zp), sure='look')
        # ---- wear marks under furniture or off the floor
        for path, surf, V in r.dump.decals():
            if len(V) % 6: continue
            W = V[:, :3].reshape(-1, 6, 3)
            for k in range(len(W)):
                P = W[k]; ctr = P.mean(0); n = np.cross(P[1] - P[0], P[2] - P[0]); ln = np.linalg.norm(n)
                if ln < 1e-9 or abs(n[1]) / ln < 0.5: continue
                fx = {'op': 'remove_decal', 'wear': path, 'surface': surf, 'at': [float(v) for v in ctr]}
                if not r.inside(ctr[0], ctr[2]): self.add('wear_outside', 'a wear mark lies outside the room\'s floor', ctr, mode='auto', fix=fx)
                elif any(o.y0 < 0.1 and min(o.half) > 0.25 and L.in_quad(o.quad, ctr[[0, 2]]) and all(L.in_quad(o.quad, q[[0, 2]]) for q in P) for o in fl):
                    self.add('wear_under', 'a wear mark lies wholly under a piece of furniture', ctr, mode='auto', fix=fx, sure='rule: "wear where people walk, queue and work"')


# ============================================================================================ the layout, the lock, the cost
def layout_faults(rows=None):
    """faults of the city layout file itself: [(kind, text)]"""
    lay = json.load(open(L.LAYOUT, encoding='utf-8'))['instances']; out = []
    have = set(f[:-4] for f in os.listdir(L.PIECES) if f.endswith('.scn')); used = {}
    for i, r in enumerate(lay):
        p = str(r['piece']); used.setdefault(p, []).append(i)
        if p not in have: out.append(('layout_missing', 'row %d names the piece %s, which has no file' % (i, p)))
        if p.startswith(('w_', 'x_', 't_')) and any(abs(float(v)) > 1e-6 for v in r.get('pos', [0, 0, 0])):
            # a wire, overlay or tree piece built in city coordinates must sit at zero; sample wire pieces are built round their sample
            if p.startswith(('x_', 't_')): out.append(('layout_offset', 'row %d: %s is built in city coordinates but is placed at %s' % (i, p, r.get('pos'))))
    seen = {}
    for i, r in enumerate(lay):
        k = (str(r['piece']), tuple(round(float(v), 2) for v in r.get('pos', [0, 0, 0])), round(float(r.get('yaw', 0)), 1))
        if k in seen: out.append(('layout_double', 'rows %d and %d place %s twice at the same spot' % (seen[k], i, k[0])))
        seen[k] = i
    spot = {}
    for i, r in enumerate(lay):
        p = str(r['piece'])
        if p.startswith(('w_', 'x_', 't_', 'd_')): continue
        k = (tuple(round(float(v), 1) for v in r.get('pos', [0, 0, 0])), round(float(r.get('yaw', 0)), 1), p.rsplit('_', 1)[-1] if p.startswith(('r_q_', 'g_', 'i_v', 'm_gr')) else p)
        spot.setdefault(k, []).append(p)
    unused = sorted(p for p in have if p not in used and not p.startswith('zz_'))
    if unused: out.append(('layout_unused', '%d piece files are placed by no row: %s%s' % (len(unused), ', '.join(unused[:12]), ' ...' if len(unused) > 12 else '')))
    return out


def lock_state(piece, folder=None):
    """'locked, unchanged' / 'locked, BUT THE FILE DIFFERS' / 'draft (not locked)'"""
    lk = json.load(open(os.path.join(L.CK, 'locked.json'), encoding='utf-8'))
    if folder is None:
        e = lk.get('pieces', {}).get(piece)
        if not e: return 'draft (not locked)'
        return 'locked, the file is what was locked' if e.get('sha256') == L.sha_file(os.path.join(L.PIECES, piece + '.scn')) else 'LOCKED, BUT THE FILE DIFFERS from what was locked'
    files = lk.get('files', {})
    key = next((k for k in files if k.endswith('/' + piece + '.scn')), None)
    if not key: return 'draft (not locked)'
    e = files[key]; sha = e.get('sha256') if isinstance(e, dict) else e
    return 'locked, the file is what was locked' if sha == L.sha_file(os.path.join(folder, piece + '.scn')) else 'LOCKED, BUT THE FILE DIFFERS from what was locked'


def cost(dump):
    """what the piece costs to draw, standing in it: (draw batches of the near tier, triangles of the near tier)"""
    draws = 0; tris = 0
    for b in dump.j['props']:
        if b['tier'] in ('near', '') and b['count']:
            draws += 1; tris += int(b.get('tris', 0)) * int(b['count'])
    for g in dump.j['ground']:
        for s in g['surf']:
            if s['tris']: draws += 1; tris += int(s['tris'])
    for b in dump.j['buildings']:
        st = L.Kit.stats(b['kit']) if b['kit'] else {}
        draws += 1; tris += int((st.get('near') or {}).get('tris', 0))
    draws += len(dump.j['wear'])
    return draws, tris
