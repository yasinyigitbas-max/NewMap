"""Street-taco stand under a 3 x 3 m pop-up canopy: red pyramid roof with printed front valance, telescoping legs with sandbag
weights, scissor truss, folding table in a sarape cloth, al-pastor trompo, plancha, salsa tubs, tortilla basket, cooler,
propane tank and an A-frame chalkboard. Customer side = +Z."""
import numpy as np, math
from kgeo import *
import kparts as P
KID = 'taco'; NAME = 'prop_kiosk_taco_stand'
HW = 1.45       # leg half spacing
EAVE = 2.08; APEX = 2.78; RH = 1.52  # roof half width at eave

def roof(m):
    lod = m.lod
    n = K(lod, 12, 3, 1, 1)
    isl = m.isl('ta_roof', 2*RH*1.02, math.hypot(RH, APEX-EAVE)+0.05, 'fabric', colours=('#8a0f15', '#8a0f15'), kind='roofpanel', rh=RH, sl=math.hypot(RH, APEX-EAVE), weight=0.55)
    isl_b = m.isl('ta_roofb', 2*RH*1.02, math.hypot(RH, APEX-EAVE)+0.05, 'fabric', colours=('#740c11', '#740c11'), kind='umbrella_under1', weight=0.3)
    isl_e = m.isl('ta_roofe', 0.5, 0.01, 'fabric', colours=('#8a0f15', '#8a0f15'), kind='plain_fab', bake=False, weight=0.2)
    for k in range(4):
        ang = k*math.pi/2
        R = np.array([[math.cos(ang), 0, math.sin(ang)], [0, 1, 0], [-math.sin(ang), 0, math.cos(ang)]])
        G = []; A = []; B = []
        sl = math.hypot(RH, APEX-EAVE)
        for i in range(n+1):          # rows from eave (i=0) to apex
            f = i/n; row = []; ar = []; br = []
            for j in range(n+1):
                g = j/n
                x = (-RH + 2*RH*g)*(1-f); zz = RH*(1-f)
                sag = (0.035*math.sin(math.pi*f)*math.sin(math.pi*g)) if lod != 'far' else 0.0
                y = EAVE + (APEX-EAVE)*f - sag
                row.append(R @ np.array([x, y, zz])); ar.append(x + RH + 0.01); br.append(f*sl)
            G.append(row); A.append(ar); B.append(br)
        slab(m, np.array(G), 0.004, isl, isl_b, isl_e, canon=k == 0, Atop=np.array(A), Btop=np.array(B), up_hint=(0, 1, 0),
             edges=m.hp, bottom=lod != 'far')
    # valances: front printed banner, other three plain red
    if lod != 'far':
        vi = m.isl('ta_val', 2*RH+0.02, 0.31, 'fabric', colours=('#8a0f15', '#8a0f15'), kind='valance', weight=0.6)
        vf = m.isl('ta_banner', 2*RH+0.02, 0.31, 'sign', sign='taco_banner', weight=1.5)
        for k in range(4):
            ang = k*math.pi/2
            R = np.array([[math.cos(ang), 0, math.sin(ang)], [0, 1, 0], [-math.sin(ang), 0, math.cos(ang)]])
            p0 = R @ np.array([RH, EAVE, RH]); p1 = R @ np.array([-RH, EAVE, RH])
            G = np.array([[p0, p1], [p0 - Y*0.30, p1 - Y*0.30]])
            if k == 0:   # banner: one-sided printed front (+z) face, plain back
                slab(m, G, 0.003, vf, vi, vi, canon=True, Atop=np.array([[0, 2*RH], [0, 2*RH]]), Btop=np.array([[0, 0], [0.30, 0.30]]),
                     up_hint=(0, 0, 1), edges=False)
            else:
                slab(m, G, 0.003, vi, vi, vi, canon=k == 1, Atop=np.array([[0, 2*RH], [0, 2*RH]]), Btop=np.array([[0, 0], [0.30, 0.30]]),
                     up_hint=tuple(R @ np.array([0, 0, 1.0])), edges=False)

def frame(m):
    lod = m.lod
    for k, (x, zz) in enumerate(((HW, HW), (-HW, HW), (HW, -HW), (-HW, -HW))):
        bbox(m, (x, 0.72, zz), (0.04, 1.44, 0.04), 'ta_leg', 'paint', r=0.004, ncs=K(lod, 2, 1, 0, 0), top=False, bottom=False,
             col='#9a9da2', kind='plain', canon=k == 0, weight=0.6)
        bbox(m, (x, 1.44 + (EAVE-1.44)/2, zz), (0.032, EAVE-1.44, 0.032), 'ta_legu', 'paint', r=0.004, ncs=K(lod, 2, 1, 0, 0),
             top=False, bottom=False, col='#a7aaae', kind='plain', canon=k == 0, weight=0.6)
        if lod in ('hp', 'near'):
            bbox(m, (x, 0.005, zz), (0.12, 0.01, 0.12), 'ta_foot', 'black', bottom=False, canon=k == 0, weight=0.5)
            bbox(m, (x, 1.44, zz), (0.05, 0.05, 0.05), 'ta_collar', 'black', r=0.006, rb=0.004, canon=k == 0, weight=0.6)
            # sandbag weight wrapped on the leg
            bbox(m, (x, 0.08, zz), (0.24, 0.15, 0.13), 'ta_sand', 'fabric', r=0.05, rb=0.05, ncs=K(lod, 4, 2, 0, 0), npb=K(lod, 4, 1, 0, 0),
                 colours=('#2b2e30', '#2b2e30'), kind='plain_fab', canon=k == 0, bottom=False, weight=0.8)
    if lod in ('hp', 'near'):
        # scissor truss on the four sides + roof rafters to a centre hub
        ti = m.isl('ta_truss', TAU*0.012, 3.0, 'paint', col='#a7aaae', kind='plain', weight=0.4)
        for k in range(4):
            ang = k*math.pi/2
            R = np.array([[math.cos(ang), 0, math.sin(ang)], [0, 1, 0], [-math.sin(ang), 0, math.cos(ang)]])
            for a0, a1 in (((HW, EAVE-0.03), (-HW, EAVE-0.30)), ((HW, EAVE-0.30), (-HW, EAVE-0.03))):
                for seg in range(2):   # two X's per side
                    xa = a0[0] + (a1[0]-a0[0])*seg/2; xb = a0[0] + (a1[0]-a0[0])*(seg+1)/2
                    ya = a0[1] if seg == 0 else (a0[1]+a1[1])/2; yb = (a0[1]+a1[1])/2 if seg == 0 else a1[1]
                    ya, yb = (a0[1], a1[1]) if seg == 0 else (a1[1], a0[1])
                    tube(m, [R @ np.array([xa, ya, HW]), R @ np.array([xb, yb, HW])], 0.011, K(m.lod, 8, 4, 3, 3), ti, canon=False)
            tube(m, [R @ np.array([HW, EAVE-0.02, HW]), np.array([0, APEX-0.05, 0])], 0.011, K(m.lod, 8, 4, 3, 3), ti, canon=k == 0)
        tube(m, [np.array([0, APEX-0.05, 0]), np.array([0, EAVE-0.25, 0])], 0.014, K(m.lod, 8, 4, 3, 3), ti, canon=False)

def table(m):
    lod = m.lod
    zc = 0.35
    # sarape cloth over the table (top + skirt, open below)
    bbox(m, (0.0, 0.53, zc), (1.86, 0.46, 0.80), 'ta_cloth', 'fabric', r=0.02, rb=0.025, ncs=K(lod, 3, 1, 0, 0), npb=K(lod, 3, 1, 0, 0),
         bottom=False, colours=('#e4442f', '#f3b32a'), kind='sarape', weight=0.8, share=False, wtop=0.9)
    if lod != 'far':
        # inner face of the skirt from the back (vendor side) so it is not see-through: dark underside quad
        ui = m.isl('ta_under', 1.8, 0.45, 'fabric', colours=('#5a2a20', '#5a2a20'), kind='plain_fab', weight=0.25)
        quad(m, (0.92, 0.31, zc-0.39), (-0.92, 0.31, zc-0.39), (-0.92, 0.75, zc-0.39), (0.92, 0.75, zc-0.39), ui) if False else None
        li = m.isl('ta_tleg', TAU*0.012, 0.75, 'paint', col='#3a3c3e', kind='plain', weight=0.4)
        for x in (0.85, -0.85):
            tube(m, [(x, 0.0, zc-0.33), (x, 0.30, zc-0.33)], 0.012, K(lod, 8, 4, 3, 3), li, canon=x > 0)
            tube(m, [(x, 0.0, zc+0.33), (x, 0.30, zc+0.33)], 0.012, K(lod, 8, 4, 3, 3), li, canon=False)
    top = 0.76
    # plancha (flat-top griddle) on the left
    bbox(m, (-0.50, top+0.06, zc-0.05), (0.66, 0.12, 0.46), 'ta_planch', 'steel', r=0.02, rb=0.01, weight=1.0, bottom=False, grain='a',
         top=False)
    bbox(m, (-0.50, top+0.125, zc-0.05), (0.62, 0.012, 0.42), 'ta_plate', 'black', weight=1.0, bottom=False, kind='griddle')
    if lod in ('hp', 'near'):
        kn = m.isl('ta_knob', TAU*0.014, 0.04, 'black', weight=1.0, kind='plain')
        for k, x in enumerate((-0.68, -0.50, -0.32)):
            tube(m, [(x, top+0.05, zc+0.18), (x, top+0.05, zc+0.215)], 0.014, K(lod, 10, 6, 4, 4), kn, canon=k == 0, caps=(False, True))
        # tortillas + meat on the plancha (low food mounds)
        tf = m.isl('ta_tort', 0.2, 0.2, 'food', kind='tortilla', weight=1.2)
        for k, (x, zz) in enumerate(((-0.62, zc-0.12), (-0.45, zc-0.02), (-0.62, zc+0.06))):
            lathe(m, [(0.075, top+0.131), (0.07, top+0.138), (0.0001, top+0.139)], np.array([x, 0, zz]), Y, Z, K(lod, 16, 8, 6, 6), tf, canon=k == 0)
        mt = m.isl('ta_meatpile', 0.3, 0.2, 'food', kind='meat', weight=1.2)
        bbox(m, (-0.33, top+0.145, zc-0.1), (0.22, 0.03, 0.15), 'ta_meatpile', 'food', r=0.04, rb=0.012, kind='meat', bottom=False, weight=1.2)
    # trompo (vertical al-pastor spit) on the right
    if lod != 'far':
        bbox(m, (0.52, top+0.05, zc-0.15), (0.30, 0.10, 0.30), 'ta_tbase', 'steel', r=0.02, rb=0.01, weight=1.0, bottom=False, grain='a')
        n = K(lod, 32, 10, 6, 6)
        mi = m.isl('ta_meat', TAU*0.15, 0.55, 'food', kind='meat', weight=1.1)
        # inverted-cone stack of marinated pork (wide shoulders at the top, tapering down), stacked-slab ridges
        prof = [(0.035, top+0.10), (0.075, top+0.115), (0.095, top+0.20), (0.118, top+0.32), (0.140, top+0.44), (0.146, top+0.50),
                (0.12, top+0.545), (0.06, top+0.556), (0.03, top+0.558)]
        base = np.array(catmull(prof, 64) if m.hp else (catmull(prof, 17) if lod == 'near' else prof), float)
        if lod in ('hp', 'near'):
            ys = base[:, 1]; body = (ys > top+0.12) & (ys < top+0.52)
            amp = 0.007 if m.hp else 0.004
            base[:, 0] = base[:, 0] + np.where(body, amp*np.sin((ys-top)/0.034*TAU) + (0.004*np.sin((ys-top)/0.011*TAU) if m.hp else 0), 0)
        prof = [tuple(p) for p in base]
        lathe(m, prof, np.array([0.52, 0, zc-0.15]), Y, Z, n, mi, canon=True)
        pi_ = m.isl('ta_pine', TAU*0.06, 0.2, 'food', kind='pineapple', weight=1.1)
        lathe(m, [(0.02, top+0.55), (0.055, top+0.57), (0.06, top+0.62), (0.045, top+0.66), (0.02, top+0.67)], np.array([0.52, 0, zc-0.15]), Y, Z,
              K(lod, 16, 8, 6, 6), pi_, canon=True)
        rod = m.isl('ta_rod', TAU*0.006, 0.8, 'chrome', weight=0.5, kind='plain')
        tube(m, [(0.52, top+0.10, zc-0.15), (0.52, top+0.80, zc-0.15)], 0.006, K(lod, 8, 4, 4, 4), rod)
        if lod in ('hp', 'near'):
            lv = m.isl('ta_leaves', 0.2, 0.15, 'food', kind='leaves', col='#4f7d2c', weight=1.0)
            for k in range(5):
                a = TAU*k/5
                tube(m, [(0.52, top+0.665, zc-0.15), (0.52+0.06*math.cos(a), top+0.75, zc-0.15+0.06*math.sin(a))], [0.012, 0.002], 4, lv, canon=k == 0)
            # vertical heater panel behind the trompo
            bbox(m, (0.52, top+0.38, zc-0.38), (0.32, 0.56, 0.05), 'ta_heater', 'steel', r=0.01, rb=0.01, weight=0.9, grain='b')
    # salsas, limes, tortilla basket, squeeze bottles, napkins on the counter front
    for k, (x, col) in enumerate(((-0.05, '#a3201a'), (0.07, '#3f7d2b'), (0.19, '#d9661c'), (0.31, '#c94a3a'))):
        P.tub(m, (x, top, zc+0.30), 0.048, 0.06, col, ('salsa%d' % k))
    P.tub(m, (-0.18, top, zc+0.30), 0.075, 0.05, '#7fae3a', 'limes', fill_kind='lemons', wall='#c9a777')
    if lod in ('hp', 'near'):
        bi = m.isl('ta_basket', TAU*0.11, 0.12, 'fabric', colours=('#e7d9b8', '#2c8f6a'), kind='stripes', stripe_w=0.03, stripe_axis='b', weight=1.0)
        lathe(m, [(0.0001, top), (0.10, top), (0.11, top+0.07), (0.07, top+0.085), (0.0001, top+0.09)], np.array([0.05, 0, zc+0.08]), Y, Z,
              K(lod, 24, 10, 6, 6), bi, canon=True)
    P.squeeze_bottle(m, (0.44, top, zc+0.30), 'red', 'ketchup')
    P.squeeze_bottle(m, (0.51, top, zc+0.30), 'green', 'relish')
    P.napkin_box(m, (0.64, top, zc+0.27))

def build(m):
    lod = m.lod
    roof(m); frame(m); table(m)
    P.propane_tank(m, (-0.60, 0.0, -0.40), name='lp', colour='#e9e6dd')
    P.cooler(m, (-1.10, 0.0, 0.10), size=(0.62, 0.42, 0.40), yaw=math.radians(80), colour='#2f6fb3', name='ta')
    P.cup_stack(m, (-1.12, 0.42, 0.18), 12, 'white', 'ta')
    P.cooler(m, (1.05, 0.0, -0.55), size=(0.50, 0.36, 0.34), yaw=math.radians(-15), colour='#e04a2c', name='ta2')
    # A-frame chalkboard in front
    if lod != 'far':
        af = (0.95, 0.0, 1.95); hgt = 0.95; spread = 0.17
        for s in (1, -1):
            tilt = math.atan2(spread, hgt) * s
            ez = np.array([0.0, math.sin(tilt), math.cos(tilt)]) * s
            ey = np.array([0.0, math.cos(tilt), -math.sin(tilt)])
            c = np.array([af[0], hgt/2 + 0.012, af[2] + s*spread/2])
            bbox(m, c, (0.60, hgt/math.cos(tilt), 0.03), 'ta_afr', 'wood', r=0.01, rb=0.01, ncs=K(lod, 3, 1, 0, 0), npb=K(lod, 3, 1, 0, 0),
                 axes=(np.array([1.0, 0, 0]), ey, ez), col='#9b6b3e', share=True, canon=s == 1, sides=(1, 0, 1, 1), weight=0.8)
            bbox(m, c + ez*0.016 + ey*0.03, (0.52, hgt*0.82, 0.004), 'ta_chalk%d' % (s > 0), 'sign', axes=(np.array([1.0, 0, 0]), ey, ez),
                 sides=(0, 1, 0, 0), top=False, bottom=False, sign='taco_chalk', chalk=True, weight=1.4, share=False)
    else:
        bbox(m, (0.95, 0.47, 1.95), (0.6, 0.95, 0.2), 'ta_afr', 'wood', col='#9b6b3e', bottom=False)
    m.col = [((x, EAVE/2, zz), (0.06, EAVE, 0.06)) for x in (HW, -HW) for zz in (HW, -HW)] + \
            [((0.0, 0.40, 0.35), (1.86, 0.80, 0.80)), ((-1.10, 0.21, 0.10), (0.45, 0.42, 0.65)), ((1.05, 0.18, -0.55), (0.55, 0.36, 0.45)),
             ((0.95, 0.47, 1.95), (0.62, 0.95, 0.24))]

LINEUP_W = 3.4; H = 2.8; FIG = (-2.0, 0, 1.0); FOOT = (0.0, 0.0)  # canopy leg square centre
VIEWS = dict(hero=((3.8, 2.7, 5.2), (0.0, 1.25, 0.3), 35), roof=((4.6, 5.2, 6.2), (0.0, 1.4, 0.0), 35), front=((0.0, 1.6, 6.2), (0.0, 1.35, 0.0), 35),
             back=((-3.2, 2.0, -4.4), (0.0, 1.1, 0.0), 35), top=((0.9, 1.7, 1.8), (0.0, 0.85, 0.3), 40),
             wheel=((1.6, 0.9, 2.9), (0.9, 0.5, 1.9), 40), under=((0.5, 1.3, 1.2), (0.0, 2.3, 0.0), 26))

if __name__ == '__main__':
    for lod in ('hp', 'near', 'mid', 'far'):
        m = Mesh(lod, KID); build(m); V = np.array(m.V)
        print(lod, m.tris(), 'islands', len(m.islands), 'bounds', V.min(0).round(3), V.max(0).round(3))
