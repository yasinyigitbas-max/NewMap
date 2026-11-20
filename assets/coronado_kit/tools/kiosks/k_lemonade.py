"""Lemonade / fresh-juice stand: painted board counter with a printed front sign, varnished top, four posts carrying a yellow and
white striped gable canopy with scalloped valances, three glass beverage dispensers on stands, lever juicer, crates of lemons
and oranges, cups, chalk price board. Customer side = +Z."""
import numpy as np, math
from kgeo import *
import kparts as P
KID = 'lemonade'; NAME = 'prop_kiosk_lemonade_stand'
CX, CZ, CY = 0.85, 0.36, 0.95     # counter half width / half depth / height
PY = 2.18; RIDGE = 2.50; EZ = 0.62; EX = 1.02

def dispenser(m, base, col, k, canon):
    lod = m.lod; b = np.asarray(base, float)
    if lod == 'far': return
    # chrome stand
    st = m.isl('le_dstand', TAU*0.12, 0.12, 'chrome', weight=0.9, kind='plain')
    prof = [(0.11, 0.0), (0.11, 0.012), (0.10, 0.02), (0.10, 0.10), (0.115, 0.105), (0.0001, 0.11)] if lod != 'mid' else [(0.11, 0.0), (0.11, 0.11), (0.0001, 0.11)]
    lathe(m, prof, b, Y, Z, K(lod, 24, 10, 6, 6), st, canon=canon)
    # glass jar with liquid
    ji = m.isl('le_jar%d' % k, TAU*0.105, 0.42, 'glassy', col=col, kind='jar', level=0.78, weight=1.0)
    jp = [(0.0001, 0.11), (0.09, 0.11), (0.105, 0.13), (0.105, 0.40), (0.095, 0.43), (0.06, 0.44), (0.0001, 0.44)]
    if m.hp: jp = [tuple(p) for p in catmull(jp, 14)]
    lathe(m, jp, b, Y, Z, K(lod, 28, 10, 6, 6), ji, canon=True)
    if lod in ('hp', 'near'):
        li = m.isl('le_jlid', TAU*0.065, 0.05, 'chrome', weight=1.0, kind='plain')
        lathe(m, [(0.066, 0.435), (0.066, 0.455), (0.03, 0.465), (0.012, 0.47), (0.012, 0.485), (0.0001, 0.49)], b, Y, Z, K(lod, 20, 8, 6, 6), li, canon=canon)
        sp = m.isl('le_spigot', TAU*0.012, 0.08, 'chrome', weight=1.0, kind='plain')
        tube(m, [b + np.array([0, 0.15, 0.10]), b + np.array([0, 0.15, 0.15]), b + np.array([0, 0.13, 0.165])], 0.011, K(lod, 8, 5, 4, 4), sp, canon=canon, caps=(False, True))
        tube(m, [b + np.array([0, 0.16, 0.14]), b + np.array([0, 0.20, 0.135])], 0.006, K(lod, 8, 4, 4, 4), sp, canon=False, caps=(False, True))
        # fruit slices floating (texture) -> handled by jar painter

def build(m):
    lod = m.lod; hp = m.hp
    # ---- counter carcass: painted boards
    bbox(m, (0, CY/2, 0), (2*CX, CY, 2*CZ), 'le_body', 'wpaint', r=0.01, ncs=K(lod, 2, 1, 0, 0), top=False, bottom=False, col='#f3efe2',
         boards=0.11, weight=0.7, share=True, sides=(1, 1, 1, 0), grain='b', boards_axis='a')
    if lod != 'far':
        # open back with a shelf (vendor side)
        bi = m.isl('le_inner', 2*CX, CY, 'interior', col='#d9d0bc', weight=0.3)
        quad(m, (CX-0.02, 0.0, -CZ+0.02), (-CX+0.02, 0.0, -CZ+0.02), (-CX+0.02, CY-0.04, -CZ+0.02), (CX-0.02, CY-0.04, -CZ+0.02), bi) if False else None
        quad(m, (-CX+0.02, 0.02, CZ-0.02), (CX-0.02, 0.02, CZ-0.02), (CX-0.02, CY-0.04, CZ-0.02), (-CX+0.02, CY-0.04, CZ-0.02), bi) if False else None
        # inner faces: back of front panel + inner sides (visible from the open back)
        quad(m, (CX-0.02, 0.0, CZ-0.02), (-CX+0.02, 0.0, CZ-0.02), (-CX+0.02, CY-0.05, CZ-0.02), (CX-0.02, CY-0.05, CZ-0.02), bi, canon=True)
        isd = m.isl('le_inner_s', 2*CZ, CY, 'interior', col='#d9d0bc', weight=0.2)
        quad(m, (CX-0.02, 0.0, -CZ), (CX-0.02, 0.0, CZ-0.02), (CX-0.02, CY-0.05, CZ-0.02), (CX-0.02, CY-0.05, -CZ), isd, canon=True)
        quad(m, (-CX+0.02, 0.0, CZ-0.02), (-CX+0.02, 0.0, -CZ), (-CX+0.02, CY-0.05, -CZ), (-CX+0.02, CY-0.05, CZ-0.02), isd, canon=False)
        bbox(m, (0, 0.42, -0.02), (2*CX-0.05, 0.025, 2*CZ-0.08), 'le_shelf', 'wood', col='#b88a5a', weight=0.4, grain='a')
        bbox(m, (0, 0.03, -0.02), (2*CX-0.05, 0.02, 2*CZ-0.08), 'le_floor', 'wood', col='#9a7550', weight=0.3, bottom=False, grain='a')
        if lod in ('hp', 'near'):
            # stock on the shelf: cup sleeves, lemon bag, sugar bags
            for k, (x, c) in enumerate(((-0.55, '#f2f0e8'), (-0.35, '#f2f0e8'), (0.1, '#e9d9a8'), (0.35, '#e9d9a8'))):
                bbox(m, (x, 0.53, -0.08), (0.16, 0.20, 0.16), 'le_stock%d' % (k // 2), 'plastic', col=c, r=0.02, rb=0.02, canon=k % 2 == 0, weight=0.5, bottom=False, kind='plain')
            P.crate(m, (0.62, 0.435, -0.05), (0.36, 0.22, 0.28), 'or2', fill=True, fill_col='#f08a1c', fruit_r=0.04, seed=5, canon=False)
    # ---- printed front sign + varnished top
    bbox(m, (0, 0.55, CZ+0.008), (1.54, 0.58, 0.016), 'le_sign', 'sign', sign='lemon_front', r=0.01, ncs=K(lod, 2, 1, 0, 0),
         sides=(1, 1, 1, 0), weight=1.6, share=True)
    bbox(m, (0, CY+0.025, 0.02), (2*CX+0.12, 0.05, 2*CZ+0.16), 'le_top', 'wood', r=0.012, rb=0.01, col='#c99a5f', grain='a', weight=0.9)
    top = CY + 0.05
    # ---- posts + canopy
    for k, (x, zz) in enumerate(((CX-0.04, CZ-0.03), (-CX+0.04, CZ-0.03), (CX-0.04, -CZ+0.03), (-CX+0.04, -CZ+0.03))):
        bbox(m, (x, top + (PY-top)/2, zz), (0.06, PY-top, 0.06), 'le_post', 'wpaint', col='#f3efe2', r=0.006, ncs=K(lod, 2, 1, 0, 0),
             top=False, bottom=False, canon=k == 0, weight=0.5, grain='b', chips=0.7)
    if lod != 'far':
        ri = m.isl('le_ridge', TAU*0.02, 2*EX+0.1, 'wood', col='#c99a5f', weight=0.4, grain='b')
        tube(m, [(-EX-0.03, RIDGE-0.03, 0.0), (EX+0.03, RIDGE-0.03, 0.0)], 0.02, K(lod, 8, 6, 4, 3), ri)
        for s in (1, -1):   # eave rails
            tube(m, [(-EX, PY+0.005, s*(CZ-0.03)), (EX, PY+0.005, s*(CZ-0.03))], 0.018, K(lod, 8, 5, 4, 3), ri, canon=False)
            for x in (CX-0.04, -CX+0.04):   # rafters
                tube(m, [(x, PY, s*(CZ-0.03)), (x, RIDGE-0.03, 0.0)], 0.016, K(lod, 8, 4, 3, 3), ri, canon=False)
    n = K(lod, 10, 2, 1, 1)
    sl = math.hypot(EZ, RIDGE-PY)
    ci = m.isl('le_canopy', 2*EX+0.02, sl+0.02, 'fabric', colours=('#f6d02a', '#f7f4ea'), kind='stripes', stripe_w=0.13, stripe_axis='a', weight=0.65)
    cb = m.isl('le_canopyb', 2*EX+0.02, sl+0.02, 'fabric', colours=('#f6d02a', '#f7f4ea'), kind='stripes_under', stripe_w=0.13, stripe_axis='a', weight=0.3)
    ce = m.isl('le_canopye', 0.5, 0.01, 'fabric', colours=('#f6d02a', '#f6d02a'), kind='plain_fab', bake=False, weight=0.2)
    xs = np.linspace(-EX, EX, n+1); fs = np.linspace(0, 1, n+1)
    for s in (1, -1):
        G = np.array([[[x, RIDGE + (PY-0.03-RIDGE)*f - (0.025*math.sin(math.pi*f)*(0.6+0.4*math.sin(math.pi*(x+EX)/(2*EX))) if lod != 'far' else 0), s*EZ*f] for x in xs] for f in fs])
        A = np.array([[x + EX + 0.01 for x in xs] for f in fs]); B = np.array([[f*sl for x in xs] for f in fs])
        slab(m, G, 0.004, ci, cb, ce, canon=s == 1, Atop=A, Btop=B, up_hint=(0, 1, 0), edges=hp, bottom=lod != 'far')
        if lod != 'far':
            vi = m.isl('le_val', 2*EX+0.02, 0.17, 'fabric', colours=('#f6d02a', '#f7f4ea'), kind='stripes_val', stripe_w=0.13, stripe_axis='a', weight=0.6)
            pts = [(-EX, PY-0.032, s*EZ), (EX, PY-0.032, s*EZ)]
            if s < 0: pts = pts[::-1]
            P.valance_strip(m, pts, 0.15, vi, scallops_per_m=1/0.26, outward=(0, 0, s))
    # gable-end triangles of the canopy (fabric, both ends)
    if lod != 'far':
        gi = m.isl('le_gable', 2*EZ, RIDGE-PY+0.02, 'fabric', colours=('#f7f4ea', '#f7f4ea'), kind='plain_fab', weight=0.4)
        for s in (1, -1):
            pts = [np.array([s*EX, PY-0.03, -EZ]), np.array([s*EX, PY-0.03, EZ]), np.array([s*EX, RIDGE, 0.0])]
            uv = [(0.001, 0.001), (2*EZ, 0.001), (EZ, RIDGE-PY+0.03)]
            if s > 0: pts = pts[::-1]; uv = uv[::-1]   # wind so the outer face points out along s*x
            m.poly(pts, uv, gi, canon=s > 0)
            pts2 = [p - np.array([s*0.004, 0, 0]) for p in pts[::-1]]
            m.poly(pts2, uv[::-1], gi, canon=False)
    # ---- counter dressing
    for k, (x, c) in enumerate(((-0.55, '#f2d43a'), (-0.28, '#f07a8a'), (-0.01, '#f59a2a'))):
        dispenser(m, (x, top, -0.08), c, k, canon=k == 0)
    if lod in ('hp', 'near'):
        # lever juicer (chrome)
        jb = m.isl('le_juicer', 0.3, 0.3, 'chrome', weight=1.0, kind='plain')
        bbox(m, (0.32, top+0.012, -0.12), (0.16, 0.024, 0.20), 'le_jbase', 'chrome', r=0.02, rb=0.008, weight=1.0, bottom=False)
        tube(m, [(0.32, top+0.02, -0.20), (0.32, top+0.36, -0.20)], 0.016, K(lod, 10, 6, 4, 4), jb, caps=(False, True))
        tube(m, [(0.32, top+0.33, -0.20), (0.32, top+0.30, -0.08), (0.32, top+0.36, 0.08)], 0.010, K(lod, 8, 5, 4, 4), jb, canon=False, caps=(False, True))
        lathe(m, [(0.0001, top+0.025), (0.055, top+0.025), (0.06, top+0.07), (0.0001, top+0.072)], np.array([0.32, 0, -0.10]), Y, Z, K(lod, 16, 8, 6, 6),
              m.isl('le_jcup', TAU*0.06, 0.1, 'chrome', weight=1.0, kind='plain'))
        lathe(m, [(0.06, top+0.24), (0.065, top+0.26), (0.0001, top+0.27)], np.array([0.32, 0, -0.10]), Y, Z, K(lod, 16, 8, 6, 6),
              m.isl('le_jcone', TAU*0.06, 0.05, 'chrome', weight=1.0, kind='plain'))
        tube(m, [(0.32, top+0.30, -0.18), (0.32, top+0.27, -0.10)], 0.012, 6, jb, canon=False)
        P.cup_stack(m, (0.55, top, 0.12), 14, 'white', 'le')
        P.cup_stack(m, (0.64, top, 0.10), 9, 'white', 'le', canon=False)
        P.napkin_box(m, (0.15, top, 0.18))
        P.tip_jar(m, (0.72, top, -0.12))
        # loose lemons on the counter
        lm = m.isl('le_lemon', TAU*0.035, 0.08, 'food', kind='lemons', col='#f2cc1f', weight=1.2)
        for k, (x, zz) in enumerate(((0.05, 0.10), (-0.02, 0.18), (0.08, 0.22))):
            r = 0.034; prof = [(r*math.sin(a)+0.0001, -r*math.cos(a)*1.15) for a in np.linspace(0, math.pi, K(lod, 9, 5, 4, 4))]
            lathe(m, prof, np.array([x, top+r*1.12, zz]), X, Y, K(lod, 12, 6, 6, 6), lm, canon=k == 0)
    P.crate(m, (-0.18, top, 0.17), (0.34, 0.14, 0.26), 'lem', fill=True, fill_col='#f2cc1f', fruit_r=0.034, seed=3)
    # ---- crates on the ground beside the stand
    P.crate(m, (CX+0.35, 0.0, 0.10), (0.48, 0.28, 0.34), 'gnd', fill=False, yaw=math.radians(8))
    P.crate(m, (CX+0.35, 0.28, 0.10), (0.48, 0.28, 0.34), 'or', fill=True, fill_col='#f08a1c', fruit_r=0.042, seed=4, yaw=math.radians(8), canon=None)
    # ---- chalk board on the front-left post
    if lod != 'far':
        bbox(m, (-CX+0.04, 1.62, CZ+0.03), (0.42, 0.56, 0.02), 'le_chalkf', 'wood', col='#8a6038', r=0.01, ncs=K(lod, 2, 1, 0, 0), sides=(1, 0, 1, 1), weight=0.5)
        bbox(m, (-CX+0.04, 1.62, CZ+0.041), (0.37, 0.51, 0.003), 'le_chalk', 'sign', sign='lemon_chalk', chalk=True, sides=(0, 1, 0, 0), top=False, bottom=False, weight=1.5)
    m.col = [((0, CY/2, 0), (2*CX, CY, 2*CZ)), ((CX+0.35, 0.28, 0.10), (0.52, 0.56, 0.42))] + \
            [((x, (CY+PY)/2, zz), (0.06, PY-CY, 0.06)) for x in (CX-0.04, -CX+0.04) for zz in (CZ-0.03, -CZ+0.03)]

LINEUP_W = 2.7; H = 2.6; FIG = (-1.6, 0, 0.7)
VIEWS = dict(napkin=((0.45, 1.30, 0.75), (0.15, 1.10, 0.18), 30), hero=((2.9, 1.8, 3.6), (0.05, 1.25, 0.0), 35), front=((0.0, 1.5, 4.8), (0.0, 1.35, 0.0), 35),
             back=((-2.8, 1.9, -3.2), (0.0, 1.1, 0.0), 35), top=((0.7, 1.75, 1.5), (-0.1, 1.1, 0.0), 40),
             wheel=((2.0, 0.9, 1.6), (1.2, 0.45, 0.1), 40), under=((0.3, 1.3, 1.4), (0.0, 2.3, 0.0), 28))

if __name__ == '__main__':
    for lod in ('hp', 'near', 'mid', 'far'):
        m = Mesh(lod, KID); build(m); V = np.array(m.V)
        print(lod, m.tris(), 'islands', len(m.islands), 'bounds', V.min(0).round(3), V.max(0).round(3))
