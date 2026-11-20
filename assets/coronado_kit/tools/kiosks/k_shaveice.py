"""Shave-ice shack: shiplap booth in seafoam paint on a timber skid, service window with counter shelf, striped scalloped awning,
corrugated mono-pitch roof, hand-painted roof sign, flavour board, side door, syrup bottle row, ice shaver, finished cones,
surfboard leaning on the wall. Customer side = +Z."""
import numpy as np, math
from kgeo import *
import kparts as P
KID = 'shaveice'; NAME = 'prop_kiosk_shaveice_shack'
HX, HZ = 1.2, 0.9          # booth half sizes
FL = 0.16                  # floor height (skid)
WT = 0.06                  # wall thickness
TOPF, TOPB = 2.48, 2.30    # wall top front / back
WY0, WY1, WX = 1.02, 1.95, 0.82   # window opening (y range, half width)
WALL = '#7cc7bd'; TRIM = '#f4f1e8'

def build(m):
    lod = m.lod; hp = m.hp
    # ---- skid + floor base
    bbox(m, (0, FL/2, 0), (2*HX+0.04, FL, 2*HZ+0.04), 'si_base', 'wood', r=0.0, rb=0.01, top=False, bottom=False, col='#6e5038',
         grain='a', weight=0.6)
    # ---- back + side walls (one shell, open front); shiplap boards in the colour/normal
    bbox(m, (0, FL + (TOPB-FL)/2, -WT/2), (2*HX, TOPB-FL, 2*HZ-WT), 'si_wall', 'wpaint', r=0.02, ncs=K(lod, 3, 1, 0, 0),
         top=False, bottom=False, sides=(1, 0, 1, 1), col=WALL, boards=0.14, weight=0.55, share=False)
    # sloped top strip of the side walls (front higher)
    if lod != 'far':
        si = m.isl('si_gable', 2*HZ, TOPF-TOPB+0.01, 'wpaint', col=WALL, boards=0.14, weight=0.6)
        for s in (1, -1):
            pts = [np.array([s*HX, TOPB, -HZ]), np.array([s*HX, TOPB, HZ]), np.array([s*HX, TOPF, HZ])]
            uv = [(0.001, 0.001), (2*HZ, 0.001), (2*HZ, TOPF-TOPB)]
            if s > 0: pts = pts[::-1]; uv = uv[::-1]   # outer face points along s*x (was inward)
            m.poly(pts, uv, si, canon=s > 0)
    # ---- front wall pieces around the window
    fz = HZ - WT/2
    fw = 'si_front'
    pieces = [((0, FL + (WY0-FL)/2), (2*HX, WY0-FL)),                  # below window
              ((0, WY1 + (TOPF-WY1)/2), (2*HX, TOPF-WY1)),             # header
              ((-(HX+WX)/2, (WY0+WY1)/2), (HX-WX, WY1-WY0)),           # left pier
              (((HX+WX)/2, (WY0+WY1)/2), (HX-WX, WY1-WY0))]            # right pier
    for k, ((x, y), (w, h)) in enumerate(pieces):
        bbox(m, (x, y, fz), (w, h, WT), fw+str(k), 'wpaint', top=False, bottom=False, sides=(0, 1, 0, 0) if k < 2 else (0, 1, 0, 0),
             col=WALL, boards=0.14, weight=0.75, share=False)
    # window reveal (jambs, sill underside, head) in trim colour
    if lod != 'far':
        ri = m.isl('si_reveal', 2*WX+0.02, WT+0.01, 'wpaint', col=TRIM, weight=0.6, chips=0.6)
        for (p0, p1, p2, p3) in (((-WX, WY1, HZ), (WX, WY1, HZ), (WX, WY1, HZ-WT), (-WX, WY1, HZ-WT)),       # head (faces down)
                                 ((-WX, WY0, HZ-WT), (WX, WY0, HZ-WT), (WX, WY0, HZ), (-WX, WY0, HZ)),       # sill (faces up)
                                 ((-WX, WY0, HZ-WT), (-WX, WY0, HZ), (-WX, WY1, HZ), (-WX, WY1, HZ-WT)),     # left jamb (faces +x)
                                 ((WX, WY0, HZ), (WX, WY0, HZ-WT), (WX, WY1, HZ-WT), (WX, WY1, HZ))):        # right jamb
            P3 = [np.array(p, float) for p in (p0, p1, p2, p3)]
            w = np.linalg.norm(P3[1]-P3[0]); h = np.linalg.norm(P3[3]-P3[0])
            m.poly(P3, [(0.001, 0.001), (w, 0.001), (w, h), (0.001, h)], ri, flip=True, canon=m.first('si_reveal'))   # face into the opening
        # trim boards: corner boards + window casing
        tr = 'si_trim'
        for k, x in enumerate((HX+0.005, -HX-0.005)):
            bbox(m, (x, FL + (TOPF-FL)/2 - 0.09, HZ-0.04), (0.03, TOPF-FL-0.18, 0.10), tr+'c', 'wpaint', col=TRIM, top=False, bottom=False,
                 r=0.005, ncs=K(lod, 2, 0, 0, 0), canon=k == 0, chips=0.8, weight=0.5, grain='b')
        for (x, y, w, h) in ((0, WY1+0.05, 2*WX+0.2, 0.10), (-WX-0.05, (WY0+WY1)/2, 0.10, WY1-WY0), (WX+0.05, (WY0+WY1)/2, 0.10, WY1-WY0)):
            bbox(m, (x, y, HZ+0.012), (w, h, 0.024), tr+('h' if w > h else 'v'), 'wpaint', col=TRIM, r=0.004, rb=0.004,
                 ncs=K(lod, 2, 1, 0, 0), npb=K(lod, 2, 1, 0, 0), canon=m.first(tr+('h' if w > h else 'v')+str(w > h and 0)) if w <= h else True,
                 chips=0.8, weight=0.6, grain='a' if w > h else 'b', bottom=w > h)
    if lod == 'far':   # far has no interior: close the service window with a dark recessed panel (no see-through)
        quad(m, (-WX, WY0, HZ-WT), (WX, WY0, HZ-WT), (WX, WY1, HZ-WT), (-WX, WY1, HZ-WT), 'si_chute_z', canon=False,
             ab=[(0.02, 0.08), (0.14, 0.08), (0.14, 0.02), (0.02, 0.02)])
    # ---- counter shelf + brackets
    bbox(m, (0, WY0+0.02, HZ+0.12), (2*WX+0.3, 0.04, 0.30), 'si_counter', 'wood', r=0.01, rb=0.008, col='#c79d68', grain='a', weight=1.0)
    if lod != 'far':
        for k, x in enumerate((-WX+0.05, WX-0.05)):
            pts = [np.array([x, WY0, HZ]), np.array([x, WY0, HZ+0.24]), np.array([x, WY0-0.24, HZ])]
            bi = m.isl('si_bracket', 0.25, 0.25, 'wpaint', col=TRIM, weight=0.5)
            bbox(m, (x, WY0-0.08, HZ+0.08), (0.04, 0.16, 0.16), 'si_bracket', 'wpaint', col=TRIM, canon=k == 0, weight=0.5, bottom=True)
    # ---- interior (seen through the window): back wall, sides, ceiling, floor, chest freezer, shelves
    if lod != 'far':
        ii = m.isl('si_int_back', 2*HX, TOPB-FL, 'interior', col='#e6ddc9', weight=0.18, boards=0.14)
        x0, x1 = -HX+WT, HX-WT; zb = -HZ+WT; zf = HZ-WT
        quad(m, (x0, FL, zb), (x1, FL, zb), (x1, TOPB-0.02, zb), (x0, TOPB-0.02, zb), ii, canon=True)
        isd = m.isl('si_int_side', 2*HZ, TOPF-FL, 'interior', col='#e6ddc9', weight=0.25, boards=0.14)
        quad(m, (x0, FL, zf), (x0, FL, zb), (x0, TOPB-0.02, zb), (x0, TOPF-0.02, zf), isd, canon=True)
        quad(m, (x1, FL, zb), (x1, FL, zf), (x1, TOPF-0.02, zf), (x1, TOPB-0.02, zb), isd, canon=False)
        ic = m.isl('si_int_ceil', 2*HX, 2*HZ, 'interior', col='#d8cfbd', weight=0.12)
        quad(m, (x0, TOPB-0.02, zb), (x1, TOPB-0.02, zb), (x1, TOPF-0.02, zf), (x0, TOPF-0.02, zf), ic, canon=True)   # faces down
        ifl = m.isl('si_int_floor', 2*HX, 2*HZ, 'wood', col='#8a6a4a', weight=0.14)
        quad(m, (x0, FL+0.005, zb), (x1, FL+0.005, zb), (x1, FL+0.005, zf), (x0, FL+0.005, zf), ifl, canon=True)
        # interior back-of-front-wall faces (seen through window at an angle)
        ifw = m.isl('si_int_front', 2*HX, TOPF-FL, 'interior', col='#e6ddc9', weight=0.15)
        for (a0, a1, b0, b1) in ((x0, x1, FL, WY0), (x0, x1, WY1, TOPF-0.02), (x0, -WX, WY0, WY1), (WX, x1, WY0, WY1)):
            quad(m, (a1, b0, zf), (a0, b0, zf), (a0, b1, zf), (a1, b1, zf), ifw, canon=m.first(('si_int_front', a0, b0)) and a0 == x0 and b0 == FL)
        # chest freezer + shelves on the back wall
        bbox(m, (-0.35, FL+0.42, -0.45), (1.1, 0.84, 0.62), 'si_freezer', 'paint', r=0.03, rb=0.02, col='#f2f2ee', weight=0.5, bottom=False)
        for k, y in enumerate((1.45, 1.80)):
            bbox(m, (0.0, y, -HZ+WT+0.13), (2*HX-2*WT-0.02, 0.025, 0.26), 'si_shelf', 'wood', col='#b88a5a', canon=k == 0, weight=0.4)
            if lod == 'near' or hp:
                for j, x in enumerate(np.linspace(-0.8, 0.8, 7)):
                    cl = ['#d83a3a', '#f0a020', '#3a8ad8', '#e6e6e0', '#6ab840', '#8e44ad', '#f06090'][j]
                    bbox(m, (x, y+0.09, -HZ+WT+0.13), (0.13, 0.16, 0.13), 'si_box%d' % (j % 4), 'plastic', col=cl, canon=k == 0 and j < 4, weight=0.5, bottom=False, kind='plain')
    # ---- awning: striped fabric on a frame, sloping out over the window, scalloped valance
    if True:
        ay0, ay1, ad = 2.36, 2.02, 0.85
        n = K(lod, 8, 2, 1, 1)
        ai = m.isl('si_awn', 2*WX+0.5, math.hypot(ad, ay0-ay1)+0.02, 'fabric', colours=('#f5f2ea', '#e45b74'), kind='stripes', stripe_w=0.15,
                   stripe_axis='a', weight=0.7)
        ab = m.isl('si_awnb', 2*WX+0.5, math.hypot(ad, ay0-ay1)+0.02, 'fabric', colours=('#f5f2ea', '#e45b74'), kind='stripes_under', stripe_w=0.15,
                   stripe_axis='a', weight=0.3)
        ae = m.isl('si_awne', 0.5, 0.01, 'fabric', colours=('#f5f2ea', '#e45b74'), kind='plain_fab', bake=False, weight=0.2)
        xs = np.linspace(-WX-0.24, WX+0.24, n+1); fs = np.linspace(0, 1, n+1)
        G = np.array([[[x, ay0 + (ay1-ay0)*f - (0.02*math.sin(math.pi*f) if lod != 'far' else 0), HZ + 0.03 + ad*f] for x in xs] for f in fs])
        A = np.array([[x + WX + 0.24 for x in xs] for f in fs]); B = np.array([[f*math.hypot(ad, ay0-ay1) for x in xs] for f in fs])
        slab(m, G, 0.004, ai, ab, ae, canon=True, Atop=A, Btop=B, up_hint=(0, 1, 0), edges=hp, bottom=lod != 'far')
        if lod != 'far':
            vi = m.isl('si_val', 2*WX+0.5, 0.17, 'fabric', colours=('#f5f2ea', '#e45b74'), kind='stripes_val', stripe_w=0.15, stripe_axis='a', weight=0.7)
            P.valance_strip(m, [(-WX-0.24, ay1-0.003, HZ+0.03+ad), (WX+0.24, ay1-0.003, HZ+0.03+ad)], 0.16, vi, scallops_per_m=6.0/1.0*0+ (1/0.15)/2,
                            outward=(0, 0, 1))
            if lod in ('hp', 'near'):
                fr = m.isl('si_awnframe', TAU*0.009, 1.0, 'chrome', weight=0.4, kind='plain')
                for k, x in enumerate((-WX-0.23, WX+0.23)):
                    tube(m, [(x, ay0-0.25, HZ+0.005), (x, ay1-0.01, HZ+0.03+ad-0.01)], 0.009, K(lod, 8, 4, 3, 3), fr, canon=k == 0)
    # ---- roof: corrugated sheet, mono-pitch, overhangs; fascia
    rx0, rx1, rz0, rz1 = -HX-0.15, HX+0.15, -HZ-0.15, HZ+0.28
    def ry(z): return TOPB + (TOPF-TOPB)*(z+HZ)/(2*HZ) + 0.03
    nn = K(lod, 2, 1, 1, 1)
    xs = np.linspace(rx0, rx1, nn+1); zs = np.linspace(rz0, rz1, nn+1)
    G = np.array([[[x, ry(z), z] for x in xs] for z in zs])
    rl = math.hypot(rz1-rz0, ry(rz1)-ry(rz0))
    A = np.array([[x - rx0 for x in xs] for z in zs]); B = np.array([[(z-rz0)/(rz1-rz0)*rl for x in xs] for z in zs])
    gi = m.isl('si_roof', rx1-rx0+0.01, rl+0.01, 'galv', weight=0.35)
    gb_ = m.isl('si_roofb', rx1-rx0+0.01, rl+0.01, 'galv', weight=0.2)
    ge = m.isl('si_roofe', rx1-rx0+0.01, 0.04, 'galv', weight=0.3)
    slab(m, G, 0.025, gi, gb_, ge, canon=True, Atop=A, Btop=B, up_hint=(0, 1, 0), edges=True, bottom=lod != 'far')
    if lod != 'far':
        # fascia board under the front roof edge
        bbox(m, (0, ry(rz1)-0.07, rz1-0.012), (rx1-rx0, 0.11, 0.024), 'si_fascia', 'wpaint', col=TRIM, weight=0.5, chips=0.8)
    # ---- roof sign (hand painted), on two posts
    sy0, sy1 = ry(HZ-0.15)+0.02, ry(HZ-0.15)+0.54
    bbox(m, (0, (sy0+sy1)/2, HZ-0.15), (2.3, sy1-sy0, 0.05), 'si_signb', 'wood', col='#b48c5e', r=0.01, ncs=K(lod, 2, 1, 0, 0),
         sides=(1, 0, 1, 1), weight=0.4, grain='a')   # raw plywood back + edges
    if lod in ('hp', 'near'):   # stiffening battens on the back of the sign
        for k, y in enumerate((sy0+0.10, sy1-0.10)):
            bbox(m, (0, y, HZ-0.15-0.025-0.015), (2.2, 0.06, 0.03), 'si_batten', 'wood', col='#9a7650', r=0.004, ncs=K(lod, 2, 0, 0, 0),
                 sides=(1, 0, 1, 1), bottom=True, canon=k == 0, weight=0.4, grain='a')
    bbox(m, (0, (sy0+sy1)/2, HZ-0.15+0.026), (2.24, sy1-sy0-0.06, 0.004), 'si_sign', 'sign', sign='shave_fascia', sides=(0, 1, 0, 0),
         top=False, bottom=False, weight=1.5)
    if lod in ('hp', 'near'):
        for k, x in enumerate((-0.8, 0.8)):
            bbox(m, (x, sy0-0.0, HZ-0.32), (0.06, 0.5, 0.06), 'si_signpost', 'wood', col='#8a6a4a', canon=k == 0, weight=0.4,
                 axes=(X, nrm(np.array([0, 1, 0.35])), nrm(np.cross(X, nrm(np.array([0, 1, 0.35]))))))
    # ---- flavour board on the right wall, side door on the left wall
    if lod != 'far':
        bbox(m, (HX+0.012, 1.45, HZ-0.45), (0.024, 0.80, 0.56), 'si_menub', 'wood', col='#7a5636', r=0.01, ncs=K(lod, 2, 1, 0, 0), sides=(0, 1, 0, 1), weight=0.4)
        bbox(m, (HX+0.026, 1.45, HZ-0.45), (0.004, 0.74, 0.50), 'si_menu', 'sign', sign='shave_menu', sides=(1, 0, 0, 0), top=False, bottom=False, weight=1.6)
        bbox(m, (-HX-0.012, FL + 1.0, -0.15), (0.024, 1.96, 0.82), 'si_door', 'wpaint', col='#e8735f', r=0.008, ncs=K(lod, 2, 1, 0, 0),
             sides=(0, 1, 1, 1), weight=0.6, chips=0.35, grain='b')
        if lod in ('hp', 'near'):
            dh = m.isl('si_doorknob', TAU*0.02, 0.06, 'brass', weight=1.0, kind='plain')
            lathe(m, [(0.012, 0), (0.02, 0.02), (0.024, 0.045), (0.0001, 0.06)], np.array([-HX-0.024, 1.1, 0.18]), -X, Y, K(lod, 12, 6, 6, 6), dh)
        if hp:   # door panels + hinges for the bake
            for y in (FL+0.55, FL+1.45):
                bbox(m, (-HX-0.027, y, -0.15), (0.008, 0.7, 0.62), 'si_dpanel', 'wpaint', r=0.01, rb=0.01, ncs=3, npb=3, bake=False)
    # ---- back wall services: electrical panel + conduit, louvred vent, hose bib (so the back is not a blank wall)
    if lod != 'far':
        bz = -HZ - 0.0
        bbox(m, (0.62, 1.38, bz-0.05), (0.30, 0.42, 0.10), 'si_panel', 'paint', col='#a9adb1', r=0.006, rb=0.006, ncs=K(lod, 2, 1, 0, 0),
             npb=K(lod, 2, 1, 0, 0), sides=(1, 0, 1, 1), weight=0.7)
        bbox(m, (-0.55, 1.92, bz-0.018), (0.50, 0.32, 0.036), 'si_ventf', 'wpaint', col=TRIM, sides=(1, 0, 1, 1), weight=0.6, chips=0.5)
        if lod in ('hp', 'near'):
            ci_ = m.isl('si_conduit', TAU*0.013, 1.2, 'paint', col='#9da1a5', weight=0.5, kind='plain')
            tube(m, [(0.62, 1.59, bz-0.05), (0.62, 1.70, bz-0.05), (0.62, 1.78, bz-0.02), (0.62, TOPB-0.02, bz-0.02)], 0.013, K(lod, 8, 5, 4, 3), ci_,
                 caps=(False, True))
            for k in range(5):   # vent louvres (angled slats)
                ey_ = nrm(np.array([0, 1.0, -0.8])); ez_ = nrm(np.cross(X, ey_))
                bbox(m, (-0.55, 1.80 + k*0.055, bz-0.03), (0.44, 0.05, 0.006), 'si_louvre', 'wpaint', col=TRIM, axes=(X, ey_, ez_),
                     sides=(1, 1, 1, 1), canon=k == 0, weight=0.5, chips=0.4, bottom=True)
            sp = m.isl('si_spigot', TAU*0.012, 0.12, 'brass', weight=1.0, kind='plain')
            tube(m, [(-0.2, 0.45, bz), (-0.2, 0.45, bz-0.07), (-0.2, 0.40, bz-0.09)], 0.011, K(lod, 8, 5, 4, 4), sp, caps=(False, True))
            lathe(m, [(0.03, -0.006), (0.032, 0.0), (0.03, 0.006)], np.array([-0.2, 0.45+0.03, bz-0.07]), Y, Z, K(lod, 12, 6, 6, 6),
                  m.isl('si_spigotw', TAU*0.03, 0.02, 'paint', col='#c0302a', weight=1.0, kind='plain'))
            tube(m, [(-0.2, 0.45+0.0, bz-0.07), (-0.2, 0.45+0.03, bz-0.07)], 0.006, 6, sp, canon=False)
            # coiled garden hose hanging under the spigot (torus)
            hi_ = m.isl('si_hose', TAU*0.012, 0.9, 'rubber', weight=0.5, kind='plain')
            for k in range(2):
                rr_ = 0.13 - 0.02*k
                pts = [(-0.2 + rr_*math.cos(t), 0.26 + rr_*0.9*math.sin(t), bz-0.03-0.025*k) for t in np.linspace(0, TAU, K(lod, 24, 12, 8, 6)+1)]
                tube(m, pts, 0.011, K(lod, 8, 4, 4, 4), hi_, canon=k == 0)
    # ---- counter dressing: syrup row, ice shaver, cones, cups, tip jar, napkins
    top = WY0 + 0.04
    cols = ['#d7192a', '#ff8a12', '#ffd21f', '#46b63a', '#2a7bd6', '#7d3cc8', '#ff5aa5', '#22c4c4']
    for k, c in enumerate(cols):
        P.syrup_bottle(m, (-0.70 + k*0.075, top, HZ+0.20), c, k)
    if lod != 'far':
        bbox(m, (0.38, top+0.17, HZ+0.12), (0.26, 0.34, 0.24), 'si_shaver', 'steel', r=0.02, rb=0.015, weight=1.0, bottom=False, grain='b')
        if lod in ('hp', 'near'):
            wi = m.isl('si_crank', TAU*0.07, 0.03, 'black', weight=1.0, kind='plain')
            lathe(m, [(0.06, -0.012), (0.075, 0.0), (0.06, 0.012)], np.array([0.38, top+0.40, HZ+0.12]), Y, Z, K(lod, 24, 10, 6, 6), wi)
            tube(m, [(0.38, top+0.34, HZ+0.12), (0.38, top+0.40, HZ+0.12)], 0.012, K(lod, 8, 4, 4, 4), wi, canon=False)
            ib = m.isl('si_iceblock', 0.5, 0.15, 'food', kind='ice', weight=1.0)
            bbox(m, (0.38, top+0.06, HZ+0.24+0.005), (0.16, 0.10, 0.004), 'si_chute', 'black', sides=(0, 1, 0, 0), top=False, bottom=False, weight=0.6)
    if lod in ('hp', 'near'):
        for k, (x, cs) in enumerate(((0.62, ('#e8413c', '#f39a2b', '#2a7bd6')), (0.72, ('#ffd21f', '#46b63a', '#ff5aa5')))):
            cu = m.isl('si_cone_cup', TAU*0.045, 0.11, 'plastic', col='#f7f6f0', weight=1.1, kind='plain')
            lathe(m, [(0.0001, top), (0.032, top), (0.045, top+0.10)], np.array([x, 0, HZ+0.18]), Y, Z, K(lod, 20, 8, 6, 6), cu, canon=k == 0)
            di = m.isl('si_dome%d' % k, TAU*0.05, 0.1, 'food', kind='shaveice', cols=cs, weight=1.2)
            prof = [(0.045, top+0.10)] + [(0.05*math.cos(a)+0.0001, top+0.10+0.055*math.sin(a)) for a in np.linspace(0.15, math.pi/2, K(lod, 8, 3, 2, 2))]
            lathe(m, prof, np.array([x, 0, HZ+0.18]), Y, Z, K(lod, 20, 8, 6, 6), di)
        P.cup_stack(m, (-0.05, top, HZ+0.16), 10, 'white', 'si')
        P.cup_stack(m, (0.05, top, HZ+0.13), 8, 'white', 'si', canon=False)
        P.tip_jar(m, (0.15, top, HZ+0.20))
        P.napkin_box(m, (-0.18, top, HZ+0.18))
    # ---- surfboard leaning on the left wall (front corner)
    if lod != 'far':
        L_, W_ = 2.05, 0.54
        n_ = K(lod, 24, 9, 5, 4)
        d = nrm(np.array([0.0, 1.0, 0.0])*math.cos(math.radians(14)) + np.array([1.0, 0, 0])*math.sin(math.radians(14)))
        bc = np.array([-HX-0.56, 0.0, 0.60])   # foot out from the wall, nose resting on it
        ex_ = np.array([0, 0, 1.0]); ny = nrm(np.cross(d, ex_))   # board normal (away from wall)
        t_ = np.linspace(0, 1, n_+1)
        outline = W_/2*np.sqrt(np.clip(np.sin(math.pi*t_), 0, 1))**0.9 + 0.003
        outline = outline*(0.6 + 0.4*np.sin(math.pi*np.clip(t_*1.05, 0, 1))**0.3)
        cols_ = K(lod, 4, 2, 1, 1)
        G = np.array([[bc + d*(0.02 + t*L_) + ex_*(-o + 2*o*j/cols_) + ny*(0.012*math.sin(math.pi*j/cols_)) for j in range(cols_+1)] for t, o in zip(t_, outline)])
        A = np.array([[(-o + 2*o*j/cols_) + W_/2 + 0.003 for j in range(cols_+1)] for o in outline]); B = np.array([[t*L_ for j in range(cols_+1)] for t in t_])
        sb = m.isl('si_board', W_+0.01, L_+0.01, 'plastic', col='#f5f0e0', kind='surfboard', weight=0.6)
        sbb = m.isl('si_boardb', W_+0.01, L_+0.01, 'plastic', col='#f5f0e0', kind='surfboard_b', weight=0.3)
        sbe = m.isl('si_boarde', 0.5, 0.06, 'plastic', col='#e8e2d0', kind='plain', bake=False, weight=0.3)
        slab(m, G, 0.055, sb, sbb, sbe, canon=True, Atop=A, Btop=B, up_hint=tuple(ny), edges=True)
    m.col = [((0, 1.24, -0.02), (2*HX+0.06, 2.48, 2*HZ+0.10)), ((0, WY0, HZ+0.12), (2*WX+0.3, 0.06, 0.30)), ((-HX-0.30, 1.0, 0.60), (0.5, 2.0, 0.56))]

LINEUP_W = 3.0; H = 3.1; FIG = (1.9, 0, 1.4)
VIEWS = dict(hero=((3.4, 2.0, 4.6), (0.0, 1.5, 0.3), 35), front=((0.0, 1.7, 5.8), (0.0, 1.6, 0.0), 35),
             back=((-3.4, 2.2, -4.2), (0.0, 1.4, 0.0), 35), top=((0.6, 1.75, 2.3), (0.0, 1.25, 0.9), 40),
             wheel=((-2.6, 1.3, 2.2), (-1.2, 1.0, 0.3), 40), under=((0.4, 1.5, 2.6), (0.0, 2.2, 1.2), 30))

if __name__ == '__main__':
    for lod in ('hp', 'near', 'mid', 'far'):
        m = Mesh(lod, KID); build(m); V = np.array(m.V)
        print(lod, m.tris(), 'islands', len(m.islands), 'bounds', V.min(0).round(3), V.max(0).round(3))
