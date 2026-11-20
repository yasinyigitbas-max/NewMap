"""Hot dog cart: stainless body, griddle + two domed steam-well lids, condiments, big blue/yellow umbrella, two pneumatic
wheels, folding legs, push handle, side-mounted propane tank. Customer side = +Z. ~1.75 x 0.9 m footprint (umbrella 1.9 m)."""
import numpy as np, math
from kgeo import *
import kparts as P
KID = 'hotdog'; NAME = 'prop_kiosk_hotdog_cart'
BX0, BX1, BZ, BY0, BY1 = -0.62, 0.62, 0.33, 0.36, 0.90

def dome_lid(m, x0, x1, z0, z1, y0, h, isl, canon):
    """lengthwise half-dome lid (along x) with end caps."""
    n = K(m.lod, 16, 5, 3, 2)
    th = np.linspace(0, math.pi, n+1)
    hz = (z1-z0)/2; zc = (z0+z1)/2
    xs = [x0, x1]
    G = np.array([[[x, y0 + h*math.sin(t), zc + hz*math.cos(t)] for t in th] for x in xs])
    arc = np.r_[0, np.cumsum(np.linalg.norm(np.diff(G[0], axis=0), axis=1))]
    A = np.array([[x-x0 for _ in th] for x in xs]) + 0.001
    B = np.array([arc for _ in xs]) + 0.001
    m.begin()
    m.grid(G, A, B, isl, flip=True, canon=canon)   # outward (was inward: culled in Godot)
    capi = m.isl(isl+'_end', 2*hz+0.002, h+0.002, 'steel', weight=1.0)
    for x, fl in ((x0, True), (x1, False)):
        pts = [np.array([x, y0 + h*math.sin(t), zc + hz*math.cos(t)]) for t in th]
        uv = [(p[2]-z0+0.001, p[1]-y0+0.001) for p in pts]
        nn = np.cross(pts[1]-pts[0], pts[2]-pts[0]); want = np.array([1.0 if x == x1 else -1.0, 0, 0])
        m.poly(pts, uv, capi, flip=np.dot(nn, want) < 0, canon=canon)
    m.end()

def build(m):
    hp = m.hp; lod = m.lod
    # ---- body
    bbox(m, ((BX0+BX1)/2, (BY0+BY1)/2, 0), (BX1-BX0, BY1-BY0, 2*BZ), 'hd_body', 'steel', r=0.03, rb=0.02,
         weight=1.0, share=True, top=False, kind='body', grain='a')
    if hp:
        # vendor-side doors (raised panels with seams) + vent louvres on the +x end + rivet rows
        for xc in (-0.29, 0.29):
            bbox(m, (xc, 0.625, -BZ-0.003), (0.5, 0.42, 0.008), 'hd_door', 'steel', r=0.01, rb=0.006, ncs=3, npb=3, bake=True)
            tube(m, [(xc+0.16*np.sign(-xc), 0.66, -BZ-0.012), (xc+0.16*np.sign(-xc), 0.76, -BZ-0.012)], 0.007, 8,
                 m.isl('hd_hpbits', 0.05, 0.05, 'steel', bake=False))
        for k in range(6):
            bbox(m, (BX1+0.002, 0.52+k*0.035, 0.0), (0.006, 0.012, 0.32), 'hd_louvre', 'steel', r=0.004, rb=0.004, ncs=2, npb=2, bake=False)
        for xs in np.linspace(BX0+0.04, BX1-0.04, 24):
            for (y, z) in ((BY1-0.015, BZ+0.0015), (BY0+0.015, BZ+0.0015), (BY1-0.015, -BZ-0.0015), (BY0+0.015, -BZ-0.0015)):
                lathe(m, [(0.004, 0), (0.0035, 0.0015), (0.0001, 0.002)], np.array([xs, y, z]), (0, 0, np.sign(z)), (1, 0, 0), 8,
                      'hd_hpbits', canon=False)
    elif lod == 'near':
        # door handles (real geometry: they read at 2 m)
        hi = m.isl('hd_handle', 0.04, 0.12, 'chrome', weight=1.0, kind='plain')
        for k, xc in enumerate((-0.29, 0.29)):
            x = xc+0.16*np.sign(-xc)
            tube(m, [(x, 0.66, -BZ-0.012), (x, 0.76, -BZ-0.012)], 0.007, 4, hi, canon=k == 0)
    # ---- printed menu panel on the customer face
    bbox(m, (0.0, 0.63, BZ+0.004), (1.04, 0.40, 0.008), 'hd_sign', 'sign', r=0.012, ncs=K(lod, 3, 1, 0, 0), sides=(1, 1, 1, 0),
         bottom=True, weight=1.9, sign='hotdog_front', canon=True)
    # ---- top deck tray with lip
    bbox(m, (0, BY1+0.015, 0), (1.30, 0.03, 0.72), 'hd_deck', 'steel', r=0.035, rb=0.01, weight=1.0, kind='deck', grain='a')
    if hp:
        for z in (0.35, -0.35):
            bbox(m, (0, BY1+0.036, z), (1.28, 0.014, 0.012), 'hd_lip', 'steel', r=0.004, rb=0.005, ncs=2, npb=2, bake=False)
    top = BY1 + 0.03
    # griddle (left) with raised splash edges
    bbox(m, (-0.40, top+0.025, 0.02), (0.42, 0.05, 0.44), 'hd_grill', 'black', r=0.01, rb=0.006, weight=1.3, bottom=False,
         kind='griddle')
    if lod in ('hp', 'near'):
        bbox(m, (-0.40, top+0.075, -0.19), (0.42, 0.05, 0.012), 'hd_splash', 'steel', r=0.004, rb=0.004, ncs=K(lod, 2, 0, 0, 0),
             npb=K(lod, 2, 1, 0, 0), weight=1.1, bottom=False)
        # sausages on the griddle
        si = m.isl('hd_sausage', TAU*0.013, 0.17, 'food', weight=1.6, kind='sausage')
        for k in range(5):
            z = -0.10 + k*0.06; x = -0.40 + (0.03 if k % 2 else -0.02)
            pts = [(x-0.075, top+0.064, z), (x, top+0.064, z+0.004), (x+0.075, top+0.064, z)]
            if hp: pts = catmull(pts, 9)
            tube(m, pts, 0.0125, K(lod, 12, 5, 4, 4), si, caps=(True, True), canon=k == 0, up=(0, 1, 0))
        # buns tray
        bi = m.isl('hd_buns', 0.2, 0.14, 'food', weight=1.4, kind='buns')
        bbox(m, (-0.40, top+0.065, 0.17), (0.30, 0.035, 0.09), 'hd_bunbox', 'food', r=0.02, rb=0.012, weight=1.4, bottom=False, kind='buns')
    # two domed steam-well lids
    li = m.isl('hd_lid', 0.30, 0.30, 'steel', weight=1.1, kind='lid', grain='a')
    for k, x in enumerate((0.03, 0.37)):
        dome_lid(m, x-0.15, x+0.15, -0.17, 0.17, top, 0.075 if lod != 'far' else 0.06, li, canon=k == 0)
        if lod in ('hp', 'near'):
            kn = m.isl('hd_knob', TAU*0.012, 0.06, 'black', weight=1.0, kind='plain')
            tube(m, [(x-0.05, top+0.079, 0.0), (x+0.05, top+0.079, 0.0)], 0.009, K(lod, 8, 4, 4, 4), kn, canon=k == 0, caps=(True, True))
    # condiments + napkins on the front-right corner of the deck
    for k, (c, nm) in enumerate((('red', 'ketchup'), ('yellow', 'mustard'), ('green', 'relish'))):
        P.squeeze_bottle(m, (0.36 + k*0.075, top, 0.27), c, nm)
    P.napkin_box(m, (-0.05, top, 0.25))
    # ---- umbrella pole + sign + umbrella
    P.pole(m, (0.0, top, -0.25), (0.0, 2.32, -0.25), 0.017, 'hd_umb')
    if lod != 'far':
        bbox(m, (0.0, 1.62, -0.25), (0.46, 0.30, 0.05), 'hd_polesign', 'sign', r=0.02, ncs=K(lod, 3, 1, 0, 0), weight=1.5,
             sign='hotdog_pole', share=False, kind='sign')
    P.umbrella(m, (0.0, 2.34, -0.25), R=0.98, rise=0.30, name='hd', colours=('#f3c623', '#1d5aa6'))
    # ---- running gear: wheels, axle, legs, handle
    for k, z in enumerate((BZ+0.055, -BZ-0.055)):
        P.cart_wheel(m, (0.40, 0.205, z), (0, 0, 1 if z > 0 else -1), R=0.205, w=0.075, name='hd', hub_col='#34373c')
    if lod != 'far':
        ai = m.isl('hd_axle', TAU*0.014, 0.9, 'black', weight=0.6, kind='plain')
        tube(m, [(0.40, 0.205, -BZ-0.02), (0.40, 0.205, BZ+0.02)], 0.014, K(lod, 8, 6, 4, 3), ai)
        for z in (BZ-0.02, -BZ+0.02):  # axle hangers
            bbox(m, (0.40, 0.29, z), (0.05, 0.16, 0.012), 'hd_hanger', 'black', weight=0.7, share=True, canon=m.first('hd_hanger'))
        li2 = m.isl('hd_leg', 0.10, 0.4, 'black', weight=0.6, kind='plain')
        for k, z in enumerate((0.25, -0.25)):
            bbox(m, (-0.50, BY0/2, z), (0.035, BY0, 0.035), 'hd_leg', 'black', r=0.004, ncs=K(lod, 2, 0, 0, 0), top=False, bottom=False,
                 canon=k == 0)
            if lod in ('hp', 'near'):
                bbox(m, (-0.50, 0.012, z), (0.06, 0.024, 0.06), 'hd_foot', 'rubber', r=0.01, ncs=K(lod, 3, 1, 0, 0), weight=0.8, bottom=False,
                     canon=k == 0, kind='plain')
        tube(m, [(-0.50, 0.12, 0.25), (-0.50, 0.12, -0.25)], 0.011, K(lod, 8, 4, 4, 3), m.isl('hd_brace', TAU*0.011, 0.52, 'black', weight=0.6, kind='plain'))
        # push handle (U bar) + rubber grip
        hi = m.isl('hd_handlebar', TAU*0.016, 1.2, 'chrome', weight=0.8, kind='pole')
        pts = [(-0.60, 0.80, 0.28), (-0.80, 0.93, 0.28), (-0.86, 0.95, 0.22), (-0.86, 0.95, -0.22), (-0.80, 0.93, -0.28), (-0.60, 0.80, -0.28)]
        tube(m, catmull(pts, K(lod, 40, 12, 7, 4)), 0.016, K(lod, 12, 6, 4, 3), hi)
        if lod in ('hp', 'near'):
            gi = m.isl('hd_grip', TAU*0.021, 0.36, 'rubber', weight=1.0, kind='grip')
            tube(m, [(-0.86, 0.95, 0.17), (-0.86, 0.95, -0.17)], 0.021, K(lod, 12, 6, 4, 3), gi, caps=(True, True))
        # propane tank on a bracket at the +x end, chained
        bbox(m, (0.79, 0.07, 0), (0.34, 0.025, 0.34), 'hd_tankshelf', 'black', r=0.01, rb=0.006, weight=0.7, kind='plain')
        for z in (0.15, -0.15):
            tube(m, [(0.62, 0.40, z), (0.95, 0.08, z)], 0.011, K(lod, 8, 4, 4, 3), ai, canon=False)
        P.propane_tank(m, (0.79, 0.083, 0.0), name='lp', colour='#e9e6dd')
    else:
        P.propane_tank(m, (0.79, 0.0, 0.0), name='lp', colour='#e9e6dd')
    m.col = [((0.03, 0.47, 0.0), (1.82, 0.94, 0.86))]

LINEUP_W = 2.3; H = 2.4; FIG = (-1.3, 0, -0.3)
VIEWS = dict(hero=((2.6, 1.7, 3.2), (0.0, 0.95, 0.0), 40), front=((0.0, 1.3, 4.2), (0.0, 1.05, 0.0), 40),
             back=((-2.4, 1.6, -3.0), (0.0, 0.9, 0.0), 40), top=((0.9, 1.75, 1.2), (0.0, 0.97, 0.0), 40),
             wheel=((1.2, 0.55, 1.15), (0.4, 0.3, 0.3), 45), under=((0.4, 1.1, 1.3), (0.0, 1.95, -0.25), 30))

if __name__ == '__main__':
    for lod in ('hp', 'near', 'mid', 'far'):
        m = Mesh(lod, KID); build(m); V = np.array(m.V)
        print(lod, m.tris(), 'islands', len(m.islands), 'bounds', V.min(0).round(3), V.max(0).round(3))
