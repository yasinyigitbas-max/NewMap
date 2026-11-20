"""Paleta (ice-pop) pushcart, paletero style: white insulated box with three round hatch lids, chrome tube frame, two spoked
wheels, push bar with a row of brass bells, chip-bag rack, small rainbow umbrella. Customer side = +Z, push end = -X."""
import numpy as np, math
from kgeo import *
import kparts as P
KID = 'paleta'; NAME = 'prop_kiosk_paleta_cart'
BX, BZ, BY0, BY1 = 0.42, 0.29, 0.42, 0.98

def spoked_wheel(m, C, ax, R, name, canon):
    """light cart wheel: tyre + rim (lathe) + 12 wire spokes + hub (spokes near/hp only)."""
    C = np.asarray(C, float); ax = nrm(ax); ref = Y; oth = np.cross(ax, ref)
    P.cart_wheel.__wrapped__ if False else None
    segs = K(m.lod, 64, 16, 10, 8)
    t = np.linspace(-1, 1, K(m.lod, 13, 5, 3, 3)); ang = t*math.radians(125); w = 0.038
    prof = np.stack([R - w*0.5 + w*0.5*np.cos(ang), w*0.5*np.sin(ang)], 1); prof[0, 0] = prof[-1, 0] = R - w*0.85
    Lp = float(np.sum(np.linalg.norm(np.diff(prof, axis=0), axis=1)))
    isl = m.isl('tyre_pal', TAU*R/4, Lp*1.2, 'rubber', kind='tyre', weight=1.0)
    lathe(m, prof[::-1], C, ax, ref, segs, isl, repeats=4 if segs % 4 == 0 else 1, canon=canon, flip=True)
    if m.lod == 'far': return
    rr = R - w*0.85
    isl2 = m.isl('rim_pal', TAU*rr, 0.06, 'chrome', weight=1.0, kind='plain')
    rp = [(rr+0.002, -0.014), (rr-0.012, -0.010), (rr-0.012, 0.010), (rr+0.002, 0.014)]
    lathe(m, rp, C, ax, ref, segs, isl2, canon=canon, flip=True)    # visible rim channel faces the hub
    lathe(m, rp, C, ax, ref, segs, isl2, canon=False, flip=False) if m.hp else None
    if m.lod in ('hp', 'near'):
        hi = m.isl('hub_pal', TAU*0.02, 0.09, 'chrome', weight=1.0, kind='plain')
        lathe(m, [(0.012, -0.045), (0.02, -0.04), (0.02, 0.04), (0.012, 0.045)], C, ax, ref, K(m.lod, 16, 6, 6, 6), hi, canon=canon)
        si = m.isl('spoke_pal', 0.02, R, 'chrome', weight=0.5, kind='plain')
        ns = 12
        for k in range(ns):
            a = TAU*k/ns; side = 1 if k % 2 else -1
            d = math.cos(a)*ref + math.sin(a)*oth
            tube(m, [C + ax*side*0.035 + d*0.02, C + d*(rr-0.01)], 0.0018, K(m.lod, 6, 3, 3, 3), si, canon=canon and k == 0)

def build(m):
    lod = m.lod; hp = m.hp
    # ---- insulated box (white, rounded)
    bbox(m, (0, (BY0+BY1)/2, 0), (2*BX, BY1-BY0, 2*BZ), 'pa_box', 'paint', r=0.05, rb=0.035, weight=0.9, share=False,
         col='#f3f1ea', kind='box', top=False)
    # lid deck with three round hatches
    bbox(m, (0, BY1+0.02, 0), (2*BX+0.02, 0.04, 2*BZ+0.02), 'pa_lid', 'paint', r=0.055, rb=0.015, weight=0.9, col='#f6f4ee', bottom=False)
    hi = m.isl('pa_hatch', TAU*0.11, 0.12, 'chrome', weight=1.2, kind='plain')
    for k, x in enumerate((-0.25, 0.0, 0.25)):
        if lod == 'far': continue
        prof = [(0.105, BY1+0.04), (0.105, BY1+0.052), (0.09, BY1+0.058), (0.0001, BY1+0.06)] if not hp else \
               [(0.106, BY1+0.04), (0.106, BY1+0.05), (0.102, BY1+0.055), (0.09, BY1+0.058), (0.03, BY1+0.061), (0.0001, BY1+0.062)]
        lathe(m, prof, np.array([x, 0, 0.0]), Y, Z, K(lod, 32, 10, 8, 6), hi, canon=k == 0)
        if lod in ('hp', 'near'):
            kn = m.isl('pa_knob', TAU*0.015, 0.05, 'black', weight=1.0, kind='plain')
            tube(m, [(x-0.035, BY1+0.075, 0.0), (x+0.035, BY1+0.075, 0.0)], 0.009, K(lod, 8, 4, 4, 4), kn, canon=k == 0, caps=(True, True))
            if hp:
                for xx in (x-0.035, x+0.035): tube(m, [(xx, BY1+0.06, 0), (xx, BY1+0.075, 0)], 0.006, 8, kn, canon=False)
    # printed decal panels: both long sides + front end
    for zs, sid in ((1, 'paleta_side'), (-1, 'paleta_side')):
        bbox(m, (0.0, 0.69, zs*(BZ+0.003)), (0.70, 0.40, 0.006), 'pa_dec'+('p' if zs > 0 else 'n'), 'sign', r=0.02,
             ncs=K(lod, 3, 1, 0, 0), sides=(0, 1, 0, 0) if zs > 0 else (0, 0, 0, 1), top=False, bottom=False, weight=1.7, sign=sid, share=False)
    bbox(m, (BX+0.003, 0.70, 0.0), (0.006, 0.36, 0.44), 'pa_decf', 'sign', r=0.02, ncs=K(lod, 3, 1, 0, 0), sides=(1, 0, 0, 0),
         top=False, bottom=False, weight=1.6, sign='paleta_front', share=False)
    bbox(m, (-BX-0.003, 0.70, 0.0), (0.006, 0.36, 0.44), 'pa_decb', 'sign', r=0.02, ncs=K(lod, 3, 1, 0, 0), sides=(0, 0, 1, 0),
         top=False, bottom=False, weight=1.0, sign='paleta_front', share=False)   # push end decal (seen past the push bar)
    # ---- chrome bumper rail around the box (top + bottom edge), reads at distance and breaks up the white box
    if lod != 'far':
        br = m.isl('pa_bumper', TAU*0.009, 3.0, 'chrome', weight=0.6, kind='pole')
        for k, y in enumerate((BY0+0.035, BY1-0.035)):
            ring = [(BX+0.008, y, BZ-0.05), (BX+0.008, y, -BZ+0.05), (BX-0.05, y, -BZ-0.008), (-BX+0.05, y, -BZ-0.008),
                    (-BX-0.008, y, -BZ+0.05), (-BX-0.008, y, BZ-0.05), (-BX+0.05, y, BZ+0.008), (BX-0.05, y, BZ+0.008), (BX+0.008, y, BZ-0.05)]
            tube(m, ring, 0.009, K(lod, 8, 4, 3, 3), br, canon=k == 0)
    # ---- chrome frame: corner posts + lower tray rails + push bar
    fi = m.isl('pa_frame', TAU*0.014, 1.2, 'chrome', weight=0.7, kind='pole')
    if lod != 'far':
        sides = K(lod, 12, 6, 4, 3)
        for k, (x, z) in enumerate(((BX+0.015, BZ+0.015), (-BX-0.015, BZ+0.015), (BX+0.015, -BZ-0.015), (-BX-0.015, -BZ-0.015))):
            tube(m, [(x, 0.18, z), (x, BY1+0.03, z)], 0.013, sides, fi, canon=k == 0)
        for z in (BZ+0.015, -BZ-0.015):
            tube(m, [(BX+0.015, 0.40, z), (-BX-0.015, 0.40, z)], 0.012, sides, fi, canon=False)
        for x in (BX+0.015, -BX-0.015):
            tube(m, [(x, 0.40, BZ+0.015), (x, 0.40, -BZ-0.015)], 0.012, sides, fi, canon=False)
        # push bar: up and back from the -x posts, crossbar at 1.05 m
        pts = [(-BX-0.015, 0.75, BZ+0.015), (-BX-0.12, 0.98, BZ+0.015), (-BX-0.17, 1.06, BZ-0.03), (-BX-0.17, 1.06, -BZ+0.03),
               (-BX-0.12, 0.98, -BZ-0.015), (-BX-0.015, 0.75, -BZ-0.015)]
        tube(m, catmull(pts, K(lod, 40, 12, 7, 4)), 0.013, sides, fi, canon=False)
        if lod in ('hp', 'near'):
            gi = m.isl('pa_grip', TAU*0.019, 0.4, 'rubber', weight=1.0, kind='grip')
            tube(m, [(-BX-0.17, 1.06, 0.2), (-BX-0.17, 1.06, -0.2)], 0.019, K(lod, 12, 6, 4, 3), gi, caps=(True, True))
            # bells hanging from a strap under the push bar
            for k, z in enumerate((-0.12, -0.04, 0.04, 0.12)):
                P.bell(m, (-BX-0.16, 1.015, z), s=0.9 if k % 2 else 1.0, canon=k == 0)
            st = m.isl('pa_strap', 0.3, 0.02, 'black', weight=0.6, kind='plain')
            bbox(m, (-BX-0.165, 1.027, 0.0), (0.012, 0.012, 0.3), 'pa_strap', 'black', canon=True)
        # axle + kick stand
        tube(m, [(0.22, 0.165, BZ+0.05), (0.22, 0.165, -BZ-0.05)], 0.012, sides, fi, canon=False)
        for z in (BZ+0.015, -BZ-0.015):
            tube(m, [(0.22, 0.165, z), (BX+0.015, 0.40, z)], 0.011, sides, fi, canon=False)
            tube(m, [(0.22, 0.165, z), (-0.05, 0.40, z)], 0.011, sides, fi, canon=False)
        lg = m.isl('pa_leg', 0.08, 0.3, 'black', weight=0.6, kind='plain')
        for z in (BZ-0.02, -BZ+0.02):
            tube(m, [(-BX-0.015, 0.40, z), (-BX-0.06, 0.012, z)], 0.011, sides, fi, canon=False)
            if lod in ('hp', 'near'):
                bbox(m, (-BX-0.06, 0.012, z), (0.05, 0.024, 0.05), 'pa_foot', 'rubber', r=0.01, weight=0.7, bottom=False, canon=m.first('pa_foot'), kind='plain')
        # under-tray (mesh shelf) with a cooler bag
        bbox(m, (0.0, 0.40, 0.0), (2*BX, 0.012, 2*BZ), 'pa_tray', 'black', weight=0.6, bottom=True, kind='plain')
    for k, z in enumerate((BZ+0.07, -BZ-0.07)):
        spoked_wheel(m, (0.22, 0.165, z), (0, 0, 1 if z > 0 else -1), 0.165, 'pal', canon=k == 0)
    # ---- chip-bag rack hanging off the vendor (-z) side
    if lod in ('hp', 'near'):
        rk = m.isl('pa_rack', TAU*0.004, 0.5, 'chrome', weight=0.5, kind='plain')
        for z in (-BZ-0.10,):
            tube(m, [(-0.36, 0.95, -BZ-0.015), (-0.36, 0.95, z), (0.36, 0.95, z), (0.36, 0.95, -BZ-0.015)][::-1], 0.004, K(lod, 6, 3, 3, 3), rk)
        cols = ['#d63a2a', '#f0b224', '#2b8a3e', '#2a62b8', '#d63a2a', '#8e44ad']
        for k, x in enumerate(np.linspace(-0.30, 0.30, 6)):
            ci = m.isl('pa_chips%d' % (k % 3), 0.13, 0.20, 'food', col=cols[k], kind='chips', weight=1.3)
            bbox(m, (x, 0.84, -BZ-0.10), (0.10, 0.20, 0.035 if not m.hp else 0.03), 'pa_chips%d' % (k % 3), 'food', r=0.012, rb=0.01,
                 ncs=K(lod, 3, 1, 0, 0), npb=K(lod, 3, 1, 0, 0), weight=1.3, col=cols[k], kind='chips', canon=k < 3)
    # ---- small rainbow umbrella on a clamp at the front corner
    P.pole(m, (BX+0.015, BY1+0.03, -BZ-0.015), (BX+0.015, 2.12, -BZ-0.015), 0.013, 'pa_umb')
    P.umbrella(m, (BX+0.015, 2.14, -BZ-0.015), R=0.68, rise=0.22, name='pa', unique=True, valance=0.09,
               colours=('#e8413c', '#f39a2b', '#f6d32d', '#53b94a', '#2fb5d6', '#3a6cc6', '#8e5bc4', '#f06aa0'))
    m.col = [((-0.07, 0.53, 0.0), (1.02, 1.06, 0.80))]

LINEUP_W = 1.9; H = 2.2; FIG = (-1.2, 0, -0.4)
VIEWS = dict(hero=((2.0, 1.5, 2.6), (0.05, 0.85, 0.0), 40), wide=((2.8, 2.0, 3.6), (0.1, 1.15, -0.2), 40), front=((0.0, 1.2, 3.4), (0.0, 0.95, 0.0), 40),
             back=((-2.3, 1.5, -2.1), (0.0, 0.85, 0.0), 40), top=((-0.9, 1.65, 0.9), (-0.25, 1.0, 0.0), 40),
             wheel=((1.0, 0.45, 1.2), (0.22, 0.25, 0.3), 45), under=((0.2, 1.0, 1.0), (0.4, 1.9, -0.3), 30))

if __name__ == '__main__':
    for lod in ('hp', 'near', 'mid', 'far'):
        m = Mesh(lod, KID); build(m); V = np.array(m.V)
        print(lod, m.tris(), 'islands', len(m.islands), 'bounds', V.min(0).round(3), V.max(0).round(3))
