"""Hotel Bel, the one hero building (SPEC: 15,000 / 4,000 / 300 tris near / mid / far; one mesh + one material per tier on
the shared CITY atlas; no transparency). Hand-designed for its site: Amber Ave x Ocean Blvd, the corner where the real town
has its great Victorian beach resort (white clapboard, red shingle roofs, red conical turrets, stacked verandas to the sea).

Frame (kit convention): front = +Z = Amber Ave (the town side, the pedestrian entrance); +X = right = the ocean (south,
Ocean Blvd and the beach); -Z = back = the hotel's motor court off the rear lot (the guests' car entrance, porte-cochere);
-X = left = north, the Beach Cinema next door.

Masses (why each is there):
 - main block 35 x 15 m, 4 storeys (lobby 4.2 m + 3 x 3.3 m), steep red hip roof with gabled dormers on every slope:
   the long clapboard body of a seaside resort, room windows in a 2.6 m rhythm;
 - the CROWN TOWER on the Amber x Ocean corner: a 12-sided tower one storey above the eave with a tall red cone and
   finial, the landmark seen from the beach, the boulevard and down Amber;
 - two octagonal turrets with red cones on the other outer corners (north-front by the cinema, south-back by the garden);
 - entrance pavilion in the middle of the Amber front: a cross gable over a columned entrance porch with the
   HOTEL BEL board, balconies on the 2nd and 3rd floors;
 - verandas: a railed veranda along the Amber front either side of the entrance (French doors from the lobby and the
   restaurant), and the three-level ocean veranda on the south end (each floor's doors open onto it);
 - porte-cochere at the back over the motor court lane (arriving cars, luggage), with its own HOTEL BEL board;
 - brick chimneys with corbels, iron cresting on the ridge, finials, belt courses at every floor, corner boards,
   bracketed eaves with K-gutters and downspouts, lamps at every door."""
import math, numpy as np
from build import Building
import city_parts   # noqa  (registers the city part kinds)
from geom import Solid
FL = 0.3; GF = 4.2; ST = 3.3; NS = 4
LV = [FL] + [FL + GF + ST * i for i in range(NS - 1)]          # floor levels 0.3, 4.5, 7.8, 11.1
W = FL + GF + ST * (NS - 1)                                     # eave 14.4
WHITE = (0.96, 0.95, 0.91); TRIM = (0.98, 0.97, 0.94); GREEN = (0.20, 0.32, 0.26)
RS = 'R_shingle'; PITCH = 0.9; O = 0.6; F_ = 0.18
X0, X1, Z0, Z1 = -17.5, 17.5, -7.5, 7.5

T = {'t': 'trim', 'mat': 'T_white', 'tint': TRIM}
SOF = {'t': 'swatch', 'mat': 'S_soffit', 'tint': TRIM}
SWH = {'t': 'swatch', 'mat': 'S_white', 'tint': TRIM}
RAIL = {'t': 'rail', 'mat': 'T_rail', 'tint': TRIM}
RF = {'t': 'roof', 'mat': RS, 'tint': (1, 1, 1)}
DK = {'t': 'trim', 'mat': 'T_metal', 'tint': (0.13, 0.13, 0.14)}
GRN = {'t': 'trim', 'mat': 'T_metal', 'tint': GREEN}
CON = {'t': 'trim', 'mat': 'T_concrete', 'tint': (0.88, 0.87, 0.84)}
def DECK(ax): return {'t': 'plane', 'mat': 'T_deck', 'axis': ax, 'tint': (1, 1, 1)}

def _solid(s, tier, planes, roles, name='solid', tiers=('near', 'mid', 'far'), meta=None, overlay=False):
    if tier not in tiers: return []
    so = Solid([(tuple(map(float, n)), float(d)) for n, d in planes], list(roles), name)
    if overlay: so.nocut = True; so.overlay = True
    return [(so, list(roles), meta or {'type': name})]
Building._solid = _solid

def win(k, c, lv, w=1.1, h=1.8, sill=0.85, **kw): return dict(k=k, c=round(c, 3), w=w, t0=round(LV[lv] + sill, 3), t1=round(LV[lv] + sill + h, 3), **kw)
def door(k, c, lv, w=1.6, h=2.3, **kw): return dict(k=k, c=round(c, 3), w=w, t0=round(LV[lv], 3), t1=round(LV[lv] + h, 3), **kw)

def roof_y(x, z):
    """main hip roof surface over (x, z) (planes as the block builds them)"""
    d = min(X1 - abs(x), Z1 - abs(z))
    return W + F_ + PITCH * (d + O)

def hotel_bel():
    b = Building('lmk_hotel_bel', 'landmark', wall='W_siding', tint=WHITE, trim=TRIM, roof=RS, style='victorian_beach_resort')
    b.floor = FL; b.budget = 'hero'; b.storeys = NS
    b.floor_lines = [LV[1], LV[2], LV[3], W]
    # ------------------------------------------------------------ openings (2.6 m room rhythm)
    big = dict(cx=X1 - 2.0, cz=Z1 - 2.0, a=4.6, sides=12)        # crown tower
    tn = dict(cx=X0 + 1.5, cz=Z1 - 0.3, a=2.4, sides=8)           # north-front turret
    ts = dict(cx=X1 - 1.4, cz=Z0 + 0.9, a=2.5, sides=8)           # south-back turret
    PAV = 4.5; PZ = Z1 + 1.2                                     # pavilion half width, front plane
    front = []
    bays_l = [-13.2, -10.6, -8.0, -5.6]                           # (the north turret covers x < -14.3)
    bays_r = [5.6, 8.0, 10.2]                                     # (the crown tower covers x > 10.6)
    for lv in range(NS):
        for c in bays_l + bays_r:
            if lv == 0:
                if c in (-10.6, 8.0): front.append(door('civic_door', c, 0, w=1.6, h=2.8))      # onto the front veranda
                else: front.append(win('victorian', c, 0, w=1.2, h=2.5, sill=0.75))
            else: front.append(win('victorian', c, lv))
    back = []
    for lv in range(NS):
        for c in [-14.4, -11.8, -9.2, -6.6, -4.0, 4.0, 6.6, 9.2, 11.8]:
            if lv == 0 and c in (-14.4,): back.append(door('apt_door', c, 0, w=1.0, h=2.2)); continue   # kitchen service door
            if lv == 0: back.append(win('victorian', c, 0, w=1.2, h=2.3, sill=0.95)); continue
            back.append(win('victorian', c, lv))
        if lv > 0:
            for c in (-1.3, 1.3): back.append(win('victorian', c, lv))
    back.append(door('civic_door', 0.0, 0, w=2.0, h=2.9))        # the motor-court entrance under the porte-cochere
    left = []
    for lv in range(NS):
        for c in (-5.0, -2.4, 0.2, 2.8):
            left.append(win('victorian', c, lv) if lv else win('victorian', c, 0, w=1.2, h=2.3, sill=0.95))
    right = []                                                    # the ocean end: doors onto each veranda level
    for lv in range(NS):
        for c in (-5.6, -3.0, -0.4, 2.0):
            if lv < 3 and c in (-3.0, 2.0) or (lv < 3 and c == -0.4 and lv == 0): right.append(door('patio', c, lv, w=1.5, h=2.3))
            else: right.append(win('victorian', c, lv))
    ops = {'front': front, 'back': back, 'left': left, 'right': right}
    b.add('block', x0=X0, x1=X1, z0=Z0, z1=Z1, W=W, roof='hip', pitch=PITCH, o=O, f=F_, openings=ops, sills=True, sill_tint=TRIM,
          head_trim=True, belt=[LV[1] - 0.22, LV[2] - 0.22, LV[3] - 0.22], corner_boards=True, rafters=True, rafter_spacing=1.0,
          rafter_sides=('front', 'back', 'right', 'left'), rafter_size=(0.09, 0.16), gutter_tint=TRIM,
          downspouts=[('back', X0 + 0.3), ('back', -2.6), ('back', 2.6), ('left', Z0 + 0.3), ('front', -4.9), ('front', 4.9)],
          roof_vents=[], ac_unit=[], meter=[('back', X0 + 1.6)], hose_bib=[('back', X0 + 3.0)],
          foundation_mat=('W_stucco', (0.62, 0.60, 0.56)))
    # ------------------------------------------------------------ entrance pavilion (cross gable) + porch + balconies
    pav_ops = {'front': [door('civic_door', 0.0, 0, w=2.2, h=3.0)] +
               [door('patio', 0.0, lv, w=1.4, h=2.3) for lv in (1, 2)] + [win('victorian', 0.0, 3)] +
               [win('victorian', c, lv) for lv in (1, 2, 3) for c in (-2.6, 2.6)] +
               [win('victorian', c, 0, w=1.2, h=2.5, sill=0.75) for c in (-2.9, 2.9)] +
               [dict(k='louver', c=0.0, w=1.1, t0=round(W + 1.1, 3), t1=round(W + 2.1, 3))]}
    b.add('block', x0=-PAV, x1=PAV, z0=Z1 - 1.0, z1=PZ, W=W, roof='gable', axis='z', pitch=PITCH, o=O, rake=0.35, f=F_, openings=pav_ops,
          sills=True, sill_tint=TRIM, head_trim=True, belt=[LV[1] - 0.22, LV[2] - 0.22, LV[3] - 0.22], corner_boards=True,
          rafters=True, rafter_spacing=1.0, rafter_sides=('right', 'left'), gutter_tint=TRIM, downspouts=[], roof_vents=[],
          foundation_mat=('W_stucco', (0.62, 0.60, 0.56)))
    b.add('porch', x0=-3.4, x1=3.4, z0=PZ, depth=2.6, roof='gable', pitch=0.7, o=0.3, f=0.16, post=0.34, beam=FL + 3.7, steps=(-2.2, 2.2),
          rail=False, roofmat=RS, base_h=0.45, posts=[-3.2, -1.25, 1.25, 3.2])
    b.add('sign', side='front', wall=PZ + 2.6 + 0.3, c=0.0, y=FL + 3.98, w=3.4, h=0.72, region='SG_hotelbel', depth=0.06, bracket=False)
    b.add('fixtures', side='front', wall=PZ, items=[('lamp', -1.55, FL + 2.3), ('lamp', 1.55, FL + 2.3)])
    for lv in (1, 2):
        b.add('balcony', x0=-1.3, x1=1.3, z0=PZ, depth=1.1, y=LV[lv], rail_tint=TRIM)
        for bx in (-1.15, 1.15):    # scroll brackets under the balcony slab
            b.add('box', x0=bx - 0.06, x1=bx + 0.06, y0=LV[lv] - 0.75, y1=LV[lv] - 0.25, z0=PZ + 0.002, z1=PZ + 0.5, top=None, side=T, bottom=T,
                  tiers=('near',), meta={'type': 'bracket'}, name='bracket', overlay=True)
    # ------------------------------------------------------------ the crown tower and the two turrets
    def facets_out(t, want):
        out = []
        for i in range(t['sides']):
            th = 2 * math.pi * i / t['sides'] + math.pi / 2; n = (math.cos(th), math.sin(th))
            if want(n): out.append(i)
        return out
    bt_out = facets_out(big, lambda n: n[0] > -0.2 and n[1] > -0.2)
    bt_ops = {}
    for i in bt_out:
        lst = [dict(k='victorian', c=0.0, w=1.0, t0=round(LV[0] + 0.75, 3), t1=round(LV[0] + 3.2, 3))]
        lst += [dict(k='victorian', c=0.0, w=1.0, t0=round(LV[lv] + 0.85, 3), t1=round(LV[lv] + 2.65, 3)) for lv in (1, 2, 3)]
        lst += [dict(k='victorian', c=0.0, w=1.0, t0=round(W + 0.9, 3), t1=round(W + 2.6, 3))]
        bt_ops[i] = lst
    for i in range(big['sides']):        # belvedere storey: windows all round (it stands clear of the main roof)
        if i not in bt_out: bt_ops[i] = [dict(k='victorian', c=0.0, w=1.0, t0=round(W + 0.9, 3), t1=round(W + 2.6, 3))]
    BTW = W + 3.6
    b.add('turret', cx=big['cx'], cz=big['cz'], a=big['a'], W=BTW, pitch=1.55, o=0.45, f=0.2, sides=12, openings=bt_ops, wall='W_siding', tint=WHITE,
          far_flat='cap', far_h=BTW + 0.2 + 1.55 * (big['a'] + 0.45), belt=(LV[1] - 0.22, LV[2] - 0.22, LV[3] - 0.22, W - 0.1, BTW - 0.3), turret_roof=RS)
    for t, h in ((tn, W + 2.2), (ts, W + 2.2)):
        if t is tn: want = lambda n: n[1] > -0.2 or n[0] < -0.5
        else: want = lambda n: n[0] > -0.2 or n[1] < -0.2
        o_ = {}
        for i in facets_out(t, want):
            o_[i] = [dict(k='victorian', c=0.0, w=0.9, t0=round(LV[lv] + 0.9, 3), t1=round(LV[lv] + 2.6, 3)) for lv in (1, 2, 3)]
            o_[i].append(dict(k='victorian', c=0.0, w=0.9, t0=round(W + 0.35, 3), t1=round(W + 1.75, 3)))
        b.add('turret', cx=t['cx'], cz=t['cz'], a=t['a'], W=h, pitch=2.1, o=0.35, f=0.16, sides=8, openings=o_, wall='W_siding', tint=WHITE,
              far_flat='cap', far_h=h + 0.16 + 2.1 * (t['a'] + 0.35), belt=(LV[1] - 0.22, LV[2] - 0.22, LV[3] - 0.22, h - 0.25), turret_roof=RS)
    # finials on every cone (a mast and a ball)
    for t, h, k in ((big, BTW, 1.55), (tn, W + 2.2, 2.1), (ts, W + 2.2, 2.1)):
        o_ = 0.45 if t is big else 0.35; f_ = 0.2 if t is big else 0.16
        apex = h + f_ + k * (t['a'] + o_) - 0.25
        top = apex + (2.0 if t is big else 1.3)
        b.add('box', x0=t['cx'] - 0.05, x1=t['cx'] + 0.05, y0=apex, y1=top, z0=t['cz'] - 0.05, z1=t['cz'] + 0.05, top=DK, side=DK, bottom=None,
              tiers=('near', 'mid'), meta={'type': 'finial'}, name='finial', overlay=True)
        q = 0.16 if t is big else 0.12
        b.add('prism_y', cx=t['cx'], cz=t['cz'], y0=apex + 0.45, y1=apex + 0.45 + 2 * q, r=q, sides=6, top=DK, side=DK, bottom=DK, tiers=('near',),
              meta={'type': 'finial'}, overlay=True)
    # ------------------------------------------------------------ dormers (gabled, one room window each)
    def dormer(side, c, depth_in=1.3, w=1.9):
        if side in ('front', 'back'):
            sgn = 1 if side == 'front' else -1
            zf = sgn * (Z1 - depth_in); zb = sgn * (Z1 - depth_in - 2.6)
            y0 = roof_y(c, zf) - 0.08; yw = y0 + 1.55
            za, zb_ = sorted((zf, zb))
            o_ = {side: [dict(k='victorian', c=round(c, 3), w=0.9, t0=round(y0 + 0.25, 3), t1=round(y0 + 1.35, 3))]}
            b.add('block', x0=c - w / 2, x1=c + w / 2, z0=za, z1=zb_, W=yw, y0=y0, roof='gable', axis='z', pitch=0.95, o=0.18, rake=0.18, f=0.12,
                  openings=o_, sills=True, sill_tint=TRIM, gutters=False, downspouts=[], roof_vents=[], foundation=False, corner_boards=True)
        else:
            sgn = 1 if side == 'right' else -1
            xf = sgn * (X1 - depth_in); xb = sgn * (X1 - depth_in - 2.6)
            y0 = roof_y(xf, c) - 0.08; yw = y0 + 1.55
            xa, xb_ = sorted((xf, xb))
            o_ = {side: [dict(k='victorian', c=round(c, 3), w=0.9, t0=round(y0 + 0.25, 3), t1=round(y0 + 1.35, 3))]}
            b.add('block', x0=xa, x1=xb_, z0=c - w / 2, z1=c + w / 2, W=yw, y0=y0, roof='gable', axis='x', pitch=0.95, o=0.18, rake=0.18, f=0.12,
                  openings=o_, sills=True, sill_tint=TRIM, gutters=False, downspouts=[], roof_vents=[], foundation=False, corner_boards=True)
    for c in (-10.6, -7.6): dormer('front', c)
    for c in (-12.4, -8.0, -3.6, 3.6, 8.0): dormer('back', c)
    dormer('right', -3.0); dormer('left', 0.0)
    # ------------------------------------------------------------ chimneys + ridge cresting
    R = W + F_ + PITCH * (Z1 + O)
    for cx in (-6.0, 6.0):
        top = R + 1.4
        b.add('chimney', x0=cx - 0.45, x1=cx + 0.45, z0=-0.5, z1=0.5, top=top, base=R - PITCH * 0.5 - 0.3, mat='W_brick', capstyle='slab')
        b.add('chimney_trim', x0=cx - 0.45, x1=cx + 0.45, z0=-0.5, z1=0.5, top=top, ridge=R, pitch=PITCH)
    rx = X1 - Z1      # hip ridge runs x -10 .. 10
    for (a_, b_) in ((-rx, -6.55), (-5.45, 5.45), (6.55, rx)):
        b.add('box', x0=a_, x1=b_, y0=R + 0.06, y1=R + 0.10, z0=-0.02, z1=0.02, top=DK, side=DK, bottom=DK, tiers=('near',), meta={'type': 'cresting'}, name='cresting', overlay=True)
        n = max(1, int((b_ - a_) / 1.2))
        for k in range(n + 1):
            fx = a_ + 0.05 + (b_ - a_ - 0.1) * k / n
            b.add('box', x0=fx - 0.02, x1=fx + 0.02, y0=R + 0.102, y1=R + 0.42, z0=-0.02, z1=0.02, top=DK, side=DK, bottom=DK, tiers=('near',), meta={'type': 'cresting'}, name='finial', overlay=True)
    # ------------------------------------------------------------ front verandas (Amber), either side of the entrance
    for (va, vb, st) in ((X0 + 3.1, -PAV - 0.1, -10.6), (PAV + 0.1, 10.5, 8.0)):
        n = max(2, int(round((vb - va) / 2.9)))
        posts = [round(va + 0.15 + (vb - va - 0.3) * i / n, 3) for i in range(n + 1)]
        b.add('porch', x0=va, x1=vb, z0=Z1, depth=2.5, roof='shed', pitch=0.22, o=0.3, f=0.16, post=0.2, beam=FL + 3.2, steps=(st - 0.9, st + 0.9),
              rail=True, roofmat=RS, posts=posts, wall_top=LV[1] - 0.3, gutter=True, gutter_tint=TRIM, rafters='white', rafter_spacing=0.9, base_h=0.3)
        for px in posts[1:-1]:      # sawn brackets at the post heads
            for sx in (-1, 1):
                b.add('box', x0=px + sx * 0.10 - 0.03 + (0.03 if sx > 0 else -0.27), x1=px + sx * 0.10 + 0.03 + (0.24 if sx > 0 else -0.03),
                      y0=FL + 3.2 - 0.34, y1=FL + 3.2 - 0.14, z0=Z1 + 2.5 - 0.15 - 0.2 / 2 - 0.03, z1=Z1 + 2.5 - 0.15 - 0.2 / 2 + 0.03,
                      top=T, side=T, bottom=T, tiers=('near',), meta={'type': 'bracket'}, name='bracket', overlay=True)
    # ------------------------------------------------------------ the ocean veranda: three levels on the south end
    VD = 2.8; za, zb = Z0 + 0.25 + 2.0, Z1 - 6.1         # clear of the south-back turret and the crown tower
    xo = X1 + VD
    vposts = [round(za + (zb - za) * i / 3, 3) for i in range(4)]
    tops = [FL, LV[1], LV[2]]
    for li, y in enumerate(tops):
        y_slab0 = 0.0 if li == 0 else y - 0.28
        b.add('box', x0=X1 - 0.05, x1=xo, y0=y_slab0, y1=y, z0=za, z1=zb, top=DECK((0, 0, 1)), side=T, bottom=None if li == 0 else SOF,
              tiers=('near', 'mid'), meta={'type': 'floor', 'top': y, 'rect': (X1, xo, za, zb), 'balcony': li > 0, 'side': 'right'}, name='vdeck')
        ytop = (tops[li + 1] - 0.28) if li < 2 else LV[3] - 0.45
        for pz in vposts:
            pz_ = min(max(pz, za + 0.11), zb - 0.11)
            b.add('box', x0=xo - 0.32, x1=xo - 0.1, y0=y + 0.002, y1=ytop - 0.002, z0=pz_ - 0.11, z1=pz_ + 0.11, top=None, side=T, bottom=None,
                  tiers=('near', 'mid'), meta={'type': 'post'}, name='vpost')
            if li == 0:
                pass
            for sz in (-1, 1):       # brackets at the post heads
                b.add('box', x0=xo - 0.24, x1=xo - 0.18, y0=ytop - 0.36, y1=ytop - 0.14, z0=pz_ + (0.11 if sz > 0 else -0.33), z1=pz_ + (0.33 if sz > 0 else -0.11),
                      top=T, side=T, bottom=T, tiers=('near',), meta={'type': 'bracket'}, name='bracket', overlay=True)
        # balustrade between the posts on the outer edge, and on both ends (ground level: open at the garden steps)
        for i in range(len(vposts) - 1):
            a0 = min(max(vposts[i], za + 0.11), zb - 0.11) + 0.112; a1 = min(max(vposts[i + 1], za + 0.11), zb - 0.11) - 0.112
            if li == 0 and i == 1:      # steps down to the garden in the middle bay
                b.add('stoop', side='right', c=round((a0 + a1) / 2, 3), wall=xo, w=round(a1 - a0 - 0.2, 3), depth=0.9, floor=FL)
                continue
            b.add('box', x0=xo - 0.24, x1=xo - 0.18, y0=y + 0.002, y1=y + 0.95, z0=a0, z1=a1, top=SWH, side=RAIL, bottom=None, tiers=('near',), meta={'type': 'rail'}, name='rail')
        for ze in (za + 0.02, zb - 0.08):
            b.add('box', x0=X1 + 0.002, x1=xo - 0.322, y0=y + 0.002, y1=y + 0.95, z0=ze, z1=ze + 0.06, top=SWH, side=RAIL, bottom=None, tiers=('near',), meta={'type': 'rail'}, name='rail')
    # the veranda roof: a red shed roof over the top level, sloping out to the sea
    ry = LV[3] - 0.45; rk = 0.25; ro = 0.35
    b.add('solid', planes=[((0, -1, 0), -ry), ((1, 0, 0), xo + ro), ((-1, 0, 0), -X1), ((0, 0, 1), zb + 0.2), ((0, 0, -1), -(za - 0.2)),
                           ((rk, 1, 0), ry + 0.16 + rk * (xo + ro))],
          roles=[SOF, T, None, T, T, RF], name='vroof', tiers=('near', 'mid', 'far'), meta={'type': 'porch_roof'})
    b.add('sign', side='right', wall=xo + ro, c=round((za + zb) / 2, 3), y=ry - 0.02, w=2.9, h=0.6, region='SG_hotelbel', depth=0.05, bracket=False) if False else None
    # ------------------------------------------------------------ porte-cochere over the motor court (back)
    GW = {'t': 'wall', 'mat': 'W_siding', 'tint': WHITE, 'bands': None, 'openings': [], 'side': None}
    PCW = 3.6; PCD = 6.0; pz0 = Z0 - PCD; pb = FL + 3.9
    b.add('stoop', side='back', c=0.0, wall=Z0, w=5.6, depth=1.4)
    for px in (-PCW + 0.2, PCW - 0.2):
        for pz in (pz0 + 0.3,):
            b.add('box', x0=px - 0.2, x1=px + 0.2, y0=0.0, y1=0.6, z0=pz - 0.2, z1=pz + 0.2, top=CON, side=CON, bottom=None, tiers=('near', 'mid'), meta={'type': 'post'}, name='pcbase')
            b.add('box', x0=px - 0.14, x1=px + 0.14, y0=0.6, y1=pb - 0.002, z0=pz - 0.14, z1=pz + 0.14, top=None, side=T, bottom=None, tiers=('near', 'mid'), meta={'type': 'post'}, name='pcpost')
            for sx in (-1, 1):
                b.add('box', x0=px + (0.14 if sx > 0 else -0.42), x1=px + (0.42 if sx > 0 else -0.14), y0=pb - 0.45, y1=pb - 0.2, z0=pz - 0.035, z1=pz + 0.035,
                      top=T, side=T, bottom=T, tiers=('near',), meta={'type': 'bracket'}, name='bracket', overlay=True)
    b.add('solid', planes=[((0, -1, 0), -pb), ((0, 0, -1), -(pz0 - 0.35)), ((0, 0, 1), Z0 - 0.01), ((1, 0, 0), PCW + 0.35), ((-1, 0, 0), PCW + 0.35),
                           ((0.55, 1, 0), pb + 0.2 + 0.55 * (PCW + 0.35)), ((-0.55, 1, 0), pb + 0.2 + 0.55 * (PCW + 0.35))],
          roles=[SOF, GW, None, T, T, RF, RF], name='pcroof', tiers=('near', 'mid', 'far'), meta={'type': 'porch_roof'})
    b.add('sign', side='back', wall=pz0 - 0.35, c=0.0, y=pb - 0.05, w=2.9, h=0.6, region='SG_hotelbel', depth=0.05, bracket=False)
    # ------------------------------------------------------------ lamps, vents, service fixtures
    b.add('fixtures', side='back', wall=Z0, items=[('lamp', -1.5, FL + 2.4), ('lamp', 1.5, FL + 2.4), ('lamp', -13.6, FL + 2.3), ('vent', -12.6, FL + 3.4),
                                                   ('conduit', X0 + 0.9, 0.3, W - 0.4), ('vent', 12.6, FL + 3.4)])
    b.add('stoop', side='back', c=-14.4, wall=Z0, w=1.6, depth=1.2)
    b.add('fixtures', side='left', wall=X0, items=[('sconce', -6.4, 2.8), ('vent', 4.2, 0.45), ('vent', -3.7, 0.45)])
    b.add('fixtures', side='front', wall=Z1, items=[('lamp', -10.6 + 1.1, FL + 2.2), ('lamp', 8.0 + 1.1, FL + 2.2)])
    b.add('fixtures', side='right', wall=X1, items=[('lamp', -1.7, FL + 2.1), ('lamp', -1.7, LV[1] + 2.0), ('lamp', -1.7, LV[2] + 2.0)])
    return b

DESIGNS = [hotel_bel]
