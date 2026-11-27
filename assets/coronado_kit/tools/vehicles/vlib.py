"""Vehicle builder library (Blender 4.5). Author space: metres, Z up, the car's FRONT towards -Y, its LEFT (driver's
side) towards +X, origin on the ground under the middle of the car. glTF export gives Y up, front +Z, left +X: the
frame of the game's current cars (CityCar).

The shell is a loft of cross-sections ("stations") along the length. Each station is a half ring of 9 points from the
bottom centre round the left side to the top centre, mirrored for the right side (16 points round). The interval from
one station to the next carries a ZONE; a face's part (body, door, bonnet, boot, bumper, glass ...) follows from its
zone, its segment of the ring (0 underside .. 7 roof) and its side. Openings are real: a door is cut out of the shell
along station lines, given its own thickness and inner trim, and pivots on its hinge.
"""
import bpy, bmesh, math, os, sys
from mathutils import Vector, Matrix
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'weapons'))
import wlib as w
from wlib import V, box, extrude, sweep, lathe, loft, cyl, rrect, circle, bevel, cut, join, smooth

# ------------------------------------------------------------------ materials of the vehicles (added to wlib's table)
# key: base rgb, rough, metal, wear rgb, wear rough, wear metal, wear amount, dirt amount, relief, relief strength
VM = {
    'paint':      ((0.78, 0.78, 0.78), 0.30, 0.0, (0.55, 0.55, 0.55), 0.55, 0.0, 0.10, 0.25, 'none', 0.0),   # tinted in game
    'paint_blk':  ((0.025, 0.026, 0.028), 0.30, 0.0, (0.20, 0.20, 0.20), 0.55, 0.0, 0.10, 0.25, 'none', 0.0),
    'paint_wht':  ((0.80, 0.80, 0.79), 0.30, 0.0, (0.55, 0.55, 0.55), 0.55, 0.0, 0.10, 0.25, 'none', 0.0),
    'paint_red':  ((0.45, 0.025, 0.02), 0.30, 0.0, (0.30, 0.10, 0.08), 0.55, 0.0, 0.10, 0.25, 'none', 0.0),
    'paint_yel':  ((0.75, 0.52, 0.02), 0.30, 0.0, (0.45, 0.35, 0.10), 0.55, 0.0, 0.10, 0.25, 'none', 0.0),
    'paint_grn':  ((0.06, 0.20, 0.08), 0.35, 0.0, (0.20, 0.22, 0.18), 0.55, 0.0, 0.10, 0.30, 'none', 0.0),
    'paint_org':  ((0.70, 0.22, 0.02), 0.35, 0.0, (0.40, 0.25, 0.15), 0.55, 0.0, 0.10, 0.30, 'none', 0.0),
    'paint_blu':  ((0.03, 0.08, 0.30), 0.30, 0.0, (0.15, 0.18, 0.25), 0.55, 0.0, 0.10, 0.25, 'none', 0.0),
    'glass':      ((0.035, 0.045, 0.055), 0.05, 0.0, (0.06, 0.07, 0.08), 0.10, 0.0, 0.05, 0.15, 'none', 0.0),
    'trim_blk':   ((0.03, 0.03, 0.032), 0.55, 0.0, (0.09, 0.09, 0.09), 0.70, 0.0, 0.20, 0.40, 'fine', 0.15),
    'chrome':     w.MDEF['chrome'],
    'rubber':     ((0.025, 0.025, 0.026), 0.85, 0.0, (0.07, 0.07, 0.07), 0.90, 0.0, 0.20, 0.50, 'fine', 0.30),
    'tyre':       ((0.028, 0.028, 0.030), 0.88, 0.0, (0.08, 0.075, 0.07), 0.95, 0.0, 0.30, 0.70, 'tread', 0.80),
    'rim':        ((0.55, 0.56, 0.58), 0.30, 1.0, (0.40, 0.40, 0.40), 0.50, 1.0, 0.15, 0.50, 'none', 0.0),
    'rim_steel':  ((0.06, 0.06, 0.065), 0.45, 0.6, (0.40, 0.40, 0.40), 0.50, 1.0, 0.25, 0.60, 'none', 0.0),
    'lamp_head':  ((0.75, 0.76, 0.78), 0.05, 0.5, (0.60, 0.60, 0.60), 0.20, 0.5, 0.05, 0.15, 'lens', 0.40),
    'lamp_tail':  ((0.45, 0.02, 0.02), 0.08, 0.0, (0.40, 0.05, 0.05), 0.20, 0.0, 0.05, 0.15, 'lens', 0.40),
    'lamp_ind':   ((0.85, 0.40, 0.02), 0.08, 0.0, (0.70, 0.35, 0.05), 0.20, 0.0, 0.05, 0.15, 'lens', 0.40),
    'lamp_blue':  ((0.02, 0.10, 0.75), 0.08, 0.0, (0.05, 0.10, 0.50), 0.20, 0.0, 0.05, 0.15, 'lens', 0.40),
    'lamp_red':   ((0.70, 0.02, 0.02), 0.08, 0.0, (0.50, 0.05, 0.05), 0.20, 0.0, 0.05, 0.15, 'lens', 0.40),
    'grille':     ((0.02, 0.02, 0.022), 0.60, 0.2, (0.10, 0.10, 0.10), 0.60, 0.5, 0.10, 0.50, 'mesh', 0.90),
    'plate':      ((0.82, 0.82, 0.80), 0.50, 0.0, (0.50, 0.48, 0.45), 0.60, 0.0, 0.20, 0.40, 'none', 0.0),
    'int_fabric': ((0.09, 0.09, 0.095), 0.90, 0.0, (0.14, 0.14, 0.14), 0.90, 0.0, 0.20, 0.35, 'weave', 0.35),
    'int_plastic': ((0.05, 0.05, 0.052), 0.65, 0.0, (0.12, 0.12, 0.12), 0.70, 0.0, 0.15, 0.30, 'fine', 0.25),
    'int_trim':   ((0.16, 0.155, 0.15), 0.75, 0.0, (0.22, 0.21, 0.20), 0.80, 0.0, 0.15, 0.35, 'fine', 0.15),
    'int_carpet': ((0.05, 0.05, 0.05), 0.95, 0.0, (0.10, 0.09, 0.08), 0.95, 0.0, 0.20, 0.60, 'weave', 0.50),
    'gauge':      ((0.01, 0.01, 0.012), 0.20, 0.0, (0.01, 0.01, 0.012), 0.20, 0.0, 0.0, 0.0, 'none', 0.0),
    'under':      ((0.04, 0.04, 0.04), 0.85, 0.3, (0.12, 0.10, 0.08), 0.90, 0.5, 0.30, 0.80, 'fine', 0.20),
    'steel_bare': ((0.35, 0.35, 0.36), 0.45, 1.0, (0.25, 0.20, 0.15), 0.70, 0.6, 0.30, 0.60, 'fine', 0.20),
    'alu':        ((0.62, 0.63, 0.64), 0.40, 1.0, (0.45, 0.45, 0.45), 0.55, 1.0, 0.20, 0.50, 'brush', 0.15),
    'alu_tread':  ((0.58, 0.59, 0.60), 0.35, 1.0, (0.40, 0.40, 0.40), 0.55, 1.0, 0.25, 0.60, 'checker', 0.80),
}
w.MDEF.update(VM)
for k in ('paint', 'paint_blk', 'paint_wht', 'paint_red', 'paint_yel', 'paint_grn', 'paint_org', 'paint_blu', 'glass'):
    w.VAR[k] = (0.97, 1.02)
# alpha of the colour map (car_paint.gdshader): 1 = body paint (takes the car's paint colour), 0.5 = glass, 0 = own colour
for k in w.MDEF:
    w.MASK[k] = 1.0 if k == 'paint' else (0.5 if k == 'glass' else 0.0)

# ------------------------------------------------------------------ the shell
SEGS = 8          # segments of a half ring: 0 underside, 1 sill curve, 2 lower side, 3 shoulder, 4 glass low, 5 glass high, 6 roof rail, 7 roof
NR = 16           # points round a full ring


def half_ring(s):
    """the 9 half-ring points (x, z) of a station dict: zb bottom, zbl belt, zt top, w half width, wt roof half width,
    sh shoulder drop, tb tumblehome, cr crown"""
    zb, zbl, zt, wd, wt = s['zb'], s['zbl'], s['zt'], s['w'], s['wt']
    sh = s.get('sh', 0.07)
    sill = min(s.get('sill', 0.10), (zbl - zb) * 0.35)
    gh = zt - zbl
    xb = wd - s.get('tb', 0.025)                     # belt (top of the door skin)
    x5 = xb + (wt - xb) * 0.35
    rail = s.get('rail', min(0.05, gh * 0.25)) if gh > 0.02 else 0.0
    x7 = wt - min(0.10, wt * 0.18)
    pts = [(0.0, zb), (wd * 0.93, zb), (wd, zb + sill), (wd, zbl - min(sh, (zbl - zb) * 0.3)), (xb, zbl),
           (x5, zbl + gh * 0.45), (wt, zt - rail), (x7, zt), (0.0, zt + s.get('cr', 0.012))]
    if gh <= 0.02:      # no glasshouse (bonnet, boot): a flat crowned deck
        pts[5] = (xb - (xb - wt) * 0.2, zbl + 0.004)
        pts[6] = (wt, zt + 0.006)
        pts[7] = (x7, zt + 0.010)
    return pts


def full_ring(s, y):
    h = half_ring(s)
    left = [V(x, y, z) for x, z in h]                    # P0 .. P8
    right = [V(-x, y, z) for x, z in h[7:0:-1]]           # R7 .. R1
    return left + right                                  # 16 points, closed


def seg_side(k):
    """face k of a ring (from point k to k+1): (segment 0..7, side 'l' / 'r')"""
    return (k, 'l') if k < 8 else (15 - k, 'r')


def interp_station(a, b, t):
    return {k: (a[k] + (b[k] - a[k]) * t if isinstance(a.get(k), (int, float)) and isinstance(b.get(k), (int, float)) else a.get(k))
            for k in set(a) | set(b)}


def shell(stations, classify):
    """loft the stations; classify(zone, seg, side) -> part name. Returns {part: object}. Caps are 'cap_f' / 'cap_r'."""
    bm = bmesh.new()
    rings = [[bm.verts.new(p) for p in full_ring(s, s['y'])] for s in stations]
    lay_part = bm.faces.layers.int.new('part')
    names = []

    def pid(n):
        if n not in names:
            names.append(n)
        return names.index(n)
    for i in range(len(rings) - 1):
        z = stations[i]['zone']
        A, B = rings[i], rings[i + 1]
        for k in range(NR):
            l = (k + 1) % NR
            f = bm.faces.new((A[k], A[l], B[l], B[k]))
            sg, sd = seg_side(k)
            f[lay_part] = pid(classify(z, sg, sd))
    f = bm.faces.new(rings[0][::-1]); f[lay_part] = pid(classify('cap_f', -1, 'c'))
    f = bm.faces.new(rings[-1]); f[lay_part] = pid(classify('cap_r', -1, 'c'))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    # seams: every ring edge where the part or the zone changes is a separate object anyway; inside a part, cut the
    # long edges at the sill, the belt, the roof rail and both centre lines, and ring edges at zone changes
    for i, R in enumerate(rings):
        for k in (0, 2, 4, 6, 8, 10, 12, 14):
            if i + 1 < len(rings):
                e = bm.edges.get((R[k], rings[i + 1][k]))
                if e: e.seam = True
        if 0 < i < len(rings) - 1 and stations[i]['zone'] != stations[i - 1]['zone']:
            for k in range(NR):
                e = bm.edges.get((R[k], R[(k + 1) % NR]))
                if e: e.seam = True
    out = {}
    for pi, n in enumerate(names):
        if n is None:
            continue
        b2 = bm.copy()
        lp = b2.faces.layers.int['part']
        bmesh.ops.delete(b2, geom=[f for f in b2.faces if f[lp] != pi], context='FACES')
        me = bpy.data.meshes.new(n)
        b2.to_mesh(me)
        b2.free()
        ob = bpy.data.objects.new(n, me)
        w.coll().objects.link(ob)
        out[n] = ob
    bm.free()
    return out


def set_mats(ob, fn):
    """per face material from fn(face centre, normal) -> key (the object's own materials are replaced)"""
    me = ob.data
    keys = []
    idx = []
    for p in me.polygons:
        k = fn(p.center, p.normal)
        if k not in keys:
            keys.append(k)
        idx.append(keys.index(k))
    me.materials.clear()
    for k in keys:
        me.materials.append(w.MAT(k))
    for p, i in zip(me.polygons, idx):
        p.material_index = i
    return ob


def thicken(ob, t, inner_key, rim_key=None):
    """give a panel thickness inwards; the inner shell gets inner_key (door card, bonnet underside)"""
    me = ob.data
    if not me.materials:
        me.materials.append(w.MAT('paint'))
    n0 = len(me.materials)
    me.materials.append(w.MAT(inner_key))
    if rim_key:
        me.materials.append(w.MAT(rim_key))
    m = ob.modifiers.new('sol', 'SOLIDIFY')
    m.thickness = t
    m.offset = -1.0
    m.use_rim = True
    m.use_even_offset = True
    m.material_offset = n0
    m.material_offset_rim = n0 + (1 if rim_key else 0)
    m.use_flip_normals = False
    w._apply(ob, m)
    return ob


def pivot(ob, p):
    """put the object's origin at p (world), keeping the mesh where it is"""
    p = Vector(p)
    ob.data.transform(Matrix.Translation(-p))
    ob.location = p
    return ob


def marker(name, p):
    e = bpy.data.objects.new(name, None)
    e.location = Vector(p)
    w.coll().objects.link(e)
    return e


# ------------------------------------------------------------------ wheels
def wheel(name, r, width, hi, rim_key='rim', spokes=5, side=1):
    """tyre + rim around the X axis, centred at the origin (moved to its hub by the caller)"""
    seg = 32 if hi else 14
    tw = width / 2
    rr = r * 0.62
    prof = [(-tw * 0.9, r * 0.70), (-tw, r * 0.86), (-tw * 0.85, r * 0.98), (-tw * 0.5, r), (tw * 0.5, r), (tw * 0.85, r * 0.98),
            (tw, r * 0.86), (tw * 0.9, r * 0.70)]
    tyre = lathe(name + '_tyre', prof, seg, 'tyre', (-0.0, 0, 0), axis=(1, 0, 0), close_ends=False)
    # rim: dish on the outer face (+x side when side=1)
    s = side
    rim = lathe(name + '_rim', [(s * tw * 0.80, 0.0), (s * tw * 0.80, rr * 0.25), (s * tw * 0.62, rr * 0.30), (s * tw * 0.70, rr * 0.95),
                                (s * tw * 0.90, rr), (s * tw * 0.90, r * 0.71)], seg, rim_key, (0, 0, 0), axis=(1, 0, 0), close_ends=False)
    parts = [tyre, rim]
    inner = lathe(name + '_in', [(-s * tw * 0.90, r * 0.71), (-s * tw * 0.90, 0.0)], seg, 'under', (0, 0, 0), axis=(1, 0, 0), close_ends=False)
    parts.append(inner)
    if hi:
        # spokes as raised bars on the dish, lug nuts, tread grooves and sidewall bump
        for k in range(spokes):
            a = 2 * math.pi * k / spokes
            d = V(0, math.cos(a), math.sin(a))
            p0 = d * rr * 0.28
            p1 = d * rr * 0.92
            sp = sweep(name + '_sp', [V(s * tw * 0.66, 0, 0) + p0, V(s * tw * 0.72, 0, 0) + p1], rrect(0.035, 0.022, 0.006, 2), rim_key)
            parts.append(sp)
        for k in range(5):
            a = 2 * math.pi * (k + 0.5) / 5
            c = V(s * tw * 0.66, math.cos(a) * rr * 0.17, math.sin(a) * rr * 0.17)
            parts.append(cyl(name + '_lug', c, c + V(s * 0.012, 0, 0), 0.009, 0.008, 8, 'chrome'))
        parts.append(cyl(name + '_cap', V(s * tw * 0.64, 0, 0), V(s * tw * 0.68, 0, 0), rr * 0.12, rr * 0.10, 16, rim_key))
    return parts


# ------------------------------------------------------------------ interior pieces
def seat(name, at, wd, hi, key='int_fabric', bench=False, back_h=0.58):
    """a seat: cushion + backrest (+ headrest), at = the hip point (H point) on the cushion"""
    x, y, z = at
    parts = []
    cush = box(name + '_c', (x - wd / 2, y - 0.30, z - 0.12), (x + wd / 2, y + 0.18, z - 0.02), key)
    bh = back_h
    back = extrude(name + '_b', [(y + 0.14, z - 0.10), (y + 0.24, z - 0.10), (y + 0.24 + 0.16 * bh, z + bh - 0.02), (y + 0.24 + 0.16 * bh - 0.09, z + bh)], x - wd / 2, x + wd / 2, key)
    parts += [cush, back]
    if not bench and bh > 0.50:
        hr = box(name + '_h', (x - 0.12, y + 0.20 + 0.16 * bh, z + bh + 0.02), (x + 0.12, y + 0.30 + 0.16 * bh, z + bh + 0.18), key)
        parts.append(hr)
    if hi:
        for o in parts:
            bevel(o, 0.02, 2, 30)
    base = box(name + '_base', (x - wd / 2 + 0.05, y - 0.22, z - 0.30), (x + wd / 2 - 0.05, y + 0.10, z - 0.12), 'int_plastic')
    parts.append(base)
    return parts


def steering_wheel(name, centre, tilt, r, hi):
    """ring + spokes in its own frame, built at the origin facing -Y (toward the driver is +Y), then turned and placed"""
    seg = 24 if hi else 10
    ring = sweep(name, [V(r * math.cos(2 * math.pi * k / seg), 0, r * math.sin(2 * math.pi * k / seg)) for k in range(seg + 1)],
                 circle(0.014, 6 if hi else 4), 'int_plastic', caps=False)
    hub = cyl(name + '_hub', V(0, 0.03, 0), V(0, -0.03, 0), 0.06, 0.07, 12 if hi else 6, 'int_plastic')
    sp = [box(name + '_s', (-r, -0.012, -0.012), (r, 0.012, 0.012), 'int_plastic'),
          box(name + '_s2', (-0.012, -0.012, -r), (0.012, 0.012, 0.0), 'int_plastic')]
    ob = join([ring, hub] + sp, name)
    ob.data.transform(Matrix.Rotation(-tilt, 4, 'X'))
    ob.data.transform(Matrix.Translation(Vector(centre)))
    return ob
