"""Weapons kit library (runs inside Blender 4.5). Hand-modelled parts, a high model (bevels, details, surface
relief) baked onto a low game model. Author space: metres, Z up, muzzle / business end towards -Y, origin at the
right-hand grip point. glTF export turns this into Y up, muzzle +Z (Godot MODEL_FRONT).
"""
import bpy, bmesh, math
from mathutils import Vector, Matrix

COLL = None


def coll():
    global COLL
    if COLL is None or COLL.name not in bpy.data.collections:
        COLL = bpy.data.collections.new('W')
        bpy.context.scene.collection.children.link(COLL)
    return COLL


def _seam(bm, a, b):
    e = bm.edges.get((a, b))
    if e is not None:
        e.seam = True


def _seam_loop(bm, vs):
    for i in range(len(vs)):
        _seam(bm, vs[i], vs[(i + 1) % len(vs)])


def _obj(name, bm, mat):
    me = bpy.data.meshes.new(name)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    coll().objects.link(ob)
    if mat is not None:
        me.materials.append(MAT(mat))
    return ob


def V(*a):
    return Vector(a)


# ------------------------------------------------------------------ primitives
def extrude(name, pts, x0, x1, mat, M=None):
    """side profile pts [(y,z)...] (either winding, may be concave) extruded across X from x0 to x1"""
    bm = bmesh.new()
    a = [bm.verts.new((x0, y, z)) for y, z in pts]
    b = [bm.verts.new((x1, y, z)) for y, z in pts]
    n = len(pts)
    bm.faces.new(a)
    bm.faces.new(b[::-1])
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    _seam_loop(bm, a)
    _seam_loop(bm, b)
    _seam(bm, a[0], b[0])
    if M is not None:
        bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
    return _obj(name, bm, mat)


def extrude_z(name, pts, z0, z1, mat, M=None):
    """top-view profile [(x,y)] extruded along Z"""
    bm = bmesh.new()
    a = [bm.verts.new((x, y, z0)) for x, y in pts]
    b = [bm.verts.new((x, y, z1)) for x, y in pts]
    n = len(pts)
    bm.faces.new(a)
    bm.faces.new(b[::-1])
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    _seam_loop(bm, a)
    _seam_loop(bm, b)
    _seam(bm, a[0], b[0])
    if M is not None:
        bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
    return _obj(name, bm, mat)


def box(name, lo, hi, mat, M=None):
    x0, y0, z0 = lo
    x1, y1, z1 = hi
    return extrude(name, [(y0, z0), (y1, z0), (y1, z1), (y0, z1)], x0, x1, mat, M)


def frame_for(d):
    d = d.normalized()
    up = V(0, 0, 1) if abs(d.z) < 0.9 else V(1, 0, 0)
    u = d.cross(up).normalized()
    v = u.cross(d).normalized()
    return u, v


def sweep(name, path, prof, mat, caps=True, scales=None, twist=0.0):
    """closed 2D profile [(u,v)] swept along a 3D polyline (parallel-transport frames). scales[i] scales the profile
    at path point i (taper). twist = total rotation in radians along the path."""
    bm = bmesh.new()
    path = [Vector(p) for p in path]
    n = len(path)
    tans = []
    for i in range(n):
        if i == 0:
            t = path[1] - path[0]
        elif i == n - 1:
            t = path[-1] - path[-2]
        else:
            t = (path[i + 1] - path[i]).normalized() + (path[i] - path[i - 1]).normalized()
        tans.append(t.normalized())
    u, v = frame_for(tans[0])
    rings = []
    for i in range(n):
        if i > 0:
            q = tans[i - 1].rotation_difference(tans[i])
            u = (q @ u).normalized()
            v = (q @ v).normalized()
        s = scales[i] if scales else 1.0
        a = twist * i / max(1, n - 1)
        ca, sa = math.cos(a), math.sin(a)
        # miter: stretch the section across the bend so walls keep thickness
        ring = []
        for pu, pv in prof:
            ru = pu * ca - pv * sa
            rv = pu * sa + pv * ca
            ring.append(bm.verts.new(path[i] + (u * ru + v * rv) * s))
        rings.append(ring)
    m = len(prof)
    for i in range(n - 1):
        for k in range(m):
            l = (k + 1) % m
            bm.faces.new((rings[i][k], rings[i][l], rings[i + 1][l], rings[i + 1][k]))
    for i in range(n - 1):
        _seam(bm, rings[i][0], rings[i + 1][0])
    if caps:
        bm.faces.new(rings[0][::-1])
        bm.faces.new(rings[-1])
        _seam_loop(bm, rings[0])
        _seam_loop(bm, rings[-1])
    return _obj(name, bm, mat)


def circle(r, seg, rx=None, start=0.0):
    rx = r if rx is None else rx
    return [(rx * math.cos(start + 2 * math.pi * k / seg), r * math.sin(start + 2 * math.pi * k / seg)) for k in range(seg)]


def rrect(w, h, r, seg=2):
    """rounded rectangle centred at 0 (w along u, h along v), seg verts per corner (seg=1 -> chamfer)"""
    pts = []
    cs = [(w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90), (-w / 2 + r, -h / 2 + r, 180), (w / 2 - r, -h / 2 + r, 270)]
    for cx, cy, a0 in cs:
        for k in range(seg + 1):
            a = math.radians(a0 + 90 * k / seg)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def cyl(name, p0, p1, r0, r1, seg, mat, caps=True, start=None):
    p0, p1 = Vector(p0), Vector(p1)
    st = math.pi / seg if start is None else start
    prof = circle(1.0, seg, start=st)
    sc = [r0, r1]
    return sweep(name, [p0, p1], prof, mat, caps, scales=sc)


def lathe(name, prof, seg, mat, p0=(0, 0, 0), axis=(0, -1, 0), close_ends=True):
    """prof [(t, r)] along axis from p0 (t metres). r=0 ends are collapsed to a pole."""
    bm = bmesh.new()
    ax = Vector(axis).normalized()
    u, v = frame_for(ax)
    p0 = Vector(p0)
    rings = []
    for t, r in prof:
        c = p0 + ax * t
        if r <= 1e-6:
            rings.append([bm.verts.new(c)])
        else:
            rings.append([bm.verts.new(c + (u * math.cos(2 * math.pi * k / seg) + v * math.sin(2 * math.pi * k / seg)) * r)
                          for k in range(seg)])
    for i in range(len(rings) - 1):
        A, B = rings[i], rings[i + 1]
        for k in range(seg):
            l = (k + 1) % seg
            if len(A) == 1:
                bm.faces.new((A[0], B[k], B[l]))
            elif len(B) == 1:
                bm.faces.new((A[k], B[0], A[l]))
            else:
                bm.faces.new((A[k], B[k], B[l], A[l]))
    for i in range(len(rings) - 1):
        _seam(bm, rings[i][0], rings[i + 1][0])
    rl = None                                      # cut cone-like runs where the radius changes a lot (straighter strips)
    for (t, r), ring in zip(prof, rings):
        if len(ring) == 1:
            continue
        if rl is not None and abs(r - rl) / rl > 0.35:
            _seam_loop(bm, ring)
            rl = r
        elif rl is None:
            rl = r
    if len(rings[0]) == 1 and len(rings) > 2:      # pole caps become their own discs
        _seam_loop(bm, rings[1])
    if len(rings[-1]) == 1 and len(rings) > 2:
        _seam_loop(bm, rings[-2])
    if close_ends:
        if len(rings[0]) > 1:
            bm.faces.new(rings[0][::-1])
            _seam_loop(bm, rings[0])
        if len(rings[-1]) > 1:
            bm.faces.new(rings[-1])
            _seam_loop(bm, rings[-1])
    return _obj(name, bm, mat)


# ------------------------------------------------------------------ modifiers (high model only)
def _apply(ob, mod):
    with bpy.context.temp_override(object=ob, active_object=ob, selected_objects=[ob]):
        bpy.ops.object.modifier_apply(modifier=mod.name)


def bevel(ob, w, seg=2, angle=35, clamp=True):
    m = ob.modifiers.new('bv', 'BEVEL')
    m.width = w
    m.segments = seg
    m.limit_method = 'ANGLE'
    m.angle_limit = math.radians(angle)
    m.use_clamp_overlap = clamp
    m.harden_normals = False
    m.miter_outer = 'MITER_ARC'
    m.mark_seam = True
    _apply(ob, m)
    # bevel faces replace the original seam edges: re-cut at every crease over 20 deg so strips (and the thin
    # chamfer rings around an outline) still open
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    for e in bm.edges:
        if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(20):
            e.seam = True
    bm.to_mesh(ob.data)
    bm.free()
    return ob


def cut(ob, cutter, delete_cutter=True):
    m = ob.modifiers.new('cut', 'BOOLEAN')
    m.operation = 'DIFFERENCE'
    m.solver = 'EXACT'
    m.object = cutter
    _apply(ob, m)
    if delete_cutter:
        bpy.data.objects.remove(cutter)
    return ob


def union(ob, other):
    m = ob.modifiers.new('un', 'BOOLEAN')
    m.operation = 'UNION'
    m.solver = 'EXACT'
    m.object = other
    _apply(ob, m)
    bpy.data.objects.remove(other)
    return ob


def smooth(ob, angle=32):
    for p in ob.data.polygons:
        p.use_smooth = True
    ob.data.set_sharp_from_angle(angle=math.radians(angle))
    return ob


def flat(ob):
    for p in ob.data.polygons:
        p.use_smooth = False
    return ob


def tris(ob):
    ob.data.calc_loop_triangles()
    return len(ob.data.loop_triangles)


# ------------------------------------------------------------------ materials (procedural, baked to the page)
# key: base rgb, base roughness, metallic, wear rgb, wear rough, wear metal, wear amount, dirt amount, relief kind, relief strength
MDEF = {
    'blued':     ((0.045, 0.047, 0.052), 0.40, 1.0, (0.46, 0.46, 0.48), 0.28, 1.0, 0.45, 0.35, 'brush', 0.15),
    'steel':     ((0.30, 0.30, 0.31), 0.34, 1.0, (0.58, 0.58, 0.60), 0.22, 1.0, 0.35, 0.30, 'brush', 0.15),
    'satin':     ((0.55, 0.55, 0.56), 0.30, 1.0, (0.72, 0.72, 0.73), 0.18, 1.0, 0.30, 0.20, 'brush', 0.25),
    'chrome':    ((0.80, 0.80, 0.82), 0.10, 1.0, (0.70, 0.70, 0.72), 0.30, 1.0, 0.25, 0.20, 'none', 0.0),
    'alu_black': ((0.030, 0.031, 0.034), 0.55, 0.30, (0.36, 0.36, 0.38), 0.35, 1.0, 0.38, 0.40, 'fine', 0.10),
    'parkerized': ((0.06, 0.062, 0.060), 0.70, 0.55, (0.32, 0.32, 0.33), 0.35, 1.0, 0.35, 0.40, 'fine', 0.20),
    'poly_black': ((0.034, 0.035, 0.037), 0.62, 0.0, (0.10, 0.10, 0.105), 0.70, 0.0, 0.35, 0.45, 'fine', 0.10),
    'poly_stip':  ((0.032, 0.033, 0.035), 0.80, 0.0, (0.10, 0.10, 0.105), 0.80, 0.0, 0.40, 0.55, 'stipple', 0.80),
    'poly_tan':   ((0.21, 0.16, 0.105), 0.68, 0.0, (0.34, 0.28, 0.20), 0.75, 0.0, 0.40, 0.50, 'fine', 0.12),
    'rubber':     ((0.025, 0.025, 0.026), 0.90, 0.0, (0.09, 0.09, 0.09), 0.90, 0.0, 0.25, 0.50, 'fine', 0.20),
    'rubber_grip': ((0.022, 0.022, 0.024), 0.85, 0.0, (0.10, 0.10, 0.10), 0.85, 0.0, 0.30, 0.40, 'wrap', 0.60),
    'walnut':     ((0.12, 0.058, 0.030), 0.42, 0.0, (0.30, 0.17, 0.09), 0.70, 0.0, 0.55, 0.45, 'grain', 0.35),
    'walnut_chk': ((0.11, 0.052, 0.027), 0.60, 0.0, (0.28, 0.16, 0.09), 0.70, 0.0, 0.45, 0.45, 'checker', 0.70),
    'ash':        ((0.50, 0.37, 0.23), 0.48, 0.0, (0.40, 0.30, 0.20), 0.70, 0.0, 0.55, 0.55, 'grain', 0.30),
    'ash_dark':   ((0.11, 0.06, 0.035), 0.42, 0.0, (0.52, 0.40, 0.26), 0.65, 0.0, 0.60, 0.40, 'grain', 0.30),
    'tape':       ((0.030, 0.030, 0.032), 0.75, 0.0, (0.14, 0.13, 0.12), 0.85, 0.0, 0.55, 0.65, 'wrap', 0.90),
    'paint_red':  ((0.40, 0.035, 0.025), 0.45, 0.0, (0.42, 0.40, 0.38), 0.40, 1.0, 0.95, 0.60, 'fine', 0.10),
    'glass_amb':  ((0.20, 0.075, 0.010), 0.08, 0.0, (0.30, 0.16, 0.06), 0.30, 0.0, 0.20, 0.40, 'none', 0.0),
    'cloth':      ((0.55, 0.50, 0.40), 0.95, 0.0, (0.28, 0.22, 0.16), 0.95, 0.0, 0.80, 0.90, 'weave', 0.70),
    'label':      ((0.44, 0.38, 0.27), 0.80, 0.0, (0.30, 0.24, 0.15), 0.85, 0.0, 0.90, 0.90, 'fine', 0.15),
    'label_ink':  ((0.32, 0.05, 0.04), 0.70, 0.0, (0.30, 0.24, 0.15), 0.85, 0.0, 0.90, 0.80, 'fine', 0.10),
    'brass':      ((0.55, 0.40, 0.15), 0.35, 1.0, (0.75, 0.60, 0.30), 0.25, 1.0, 0.30, 0.30, 'none', 0.0),
    'sight_dot':  ((0.80, 0.78, 0.70), 0.50, 0.0, (0.80, 0.78, 0.70), 0.50, 0.0, 0.0, 0.10, 'none', 0.0),
    'sight_org':  ((0.85, 0.25, 0.03), 0.50, 0.0, (0.85, 0.25, 0.03), 0.50, 0.0, 0.0, 0.10, 'none', 0.0),
}
MATS = {}
VAR = {}       # (vehicles) colour variation range per key, default (0.82, 1.12)
MASK = {}      # (vehicles) colour-map alpha per material key: 1 paint, 0.5 glass, 0 own colour
SEED = [0]


def MAT(key):
    if key in MATS:
        return MATS[key][0]
    base, br, bm_, wc, wr, wm, wa, da, relief, rs = MDEF[key]
    m = bpy.data.materials.new('m_' + key)
    m.use_nodes = True
    nt = m.node_tree
    N = nt.nodes
    L = nt.links
    for n in list(N):
        N.remove(n)
    out = N.new('ShaderNodeOutputMaterial')
    bsdf = N.new('ShaderNodeBsdfPrincipled')
    L.new(bsdf.outputs[0], out.inputs[0])
    tc = N.new('ShaderNodeTexCoord')
    obc = tc.outputs['Object']

    def noise(scale, detail=4, rough=0.55, vec=None, dim='3D'):
        n = N.new('ShaderNodeTexNoise')
        n.noise_dimensions = dim
        n.inputs['Scale'].default_value = scale
        n.inputs['Detail'].default_value = detail
        n.inputs['Roughness'].default_value = rough
        L.new(vec or obc, n.inputs['Vector'])
        return n.outputs['Fac']

    def mr(x, a, b, c=0.0, d=1.0, interp='LINEAR'):
        n = N.new('ShaderNodeMapRange')
        n.interpolation_type = interp
        L.new(x, n.inputs['Value'])
        n.inputs['From Min'].default_value = a
        n.inputs['From Max'].default_value = b
        n.inputs['To Min'].default_value = c
        n.inputs['To Max'].default_value = d
        return n.outputs['Result']

    def math_(op, a, b=None):
        n = N.new('ShaderNodeMath')
        n.operation = op
        for i, x in enumerate((a, b)):
            if x is None:
                continue
            if isinstance(x, (int, float)):
                n.inputs[i].default_value = x
            else:
                L.new(x, n.inputs[i])
        return n.outputs[0]

    def mixc(f, a, b):
        n = N.new('ShaderNodeMix')
        n.data_type = 'RGBA'
        for sock, x in ((n.inputs[0], f), (n.inputs[6], a), (n.inputs[7], b)):
            if isinstance(x, (int, float)):
                sock.default_value = x
            elif isinstance(x, tuple):
                sock.default_value = (*x, 1)
            else:
                L.new(x, sock)
        return n.outputs[2]

    def mixf(f, a, b):
        n = N.new('ShaderNodeMix')
        n.data_type = 'FLOAT'
        for sock, x in ((n.inputs[0], f), (n.inputs[2], a), (n.inputs[3], b)):
            if isinstance(x, (int, float)):
                sock.default_value = x
            else:
                L.new(x, sock)
        return n.outputs[0]

    # masks: convex edges (AO inside), cavities (AO), breakup noise
    aoi = N.new('ShaderNodeAmbientOcclusion')
    aoi.inside = True
    aoi.only_local = True
    aoi.samples = 12
    aoi.inputs['Distance'].default_value = 0.0022
    edge = math_('SUBTRACT', 1.0, aoi.outputs['AO'])
    aoc = N.new('ShaderNodeAmbientOcclusion')
    aoc.only_local = True
    aoc.samples = 12
    aoc.inputs['Distance'].default_value = 0.012
    cav = math_('SUBTRACT', 1.0, aoc.outputs['AO'])
    br1 = noise(38.0, 6, 0.6)
    br2 = noise(160.0, 3, 0.5)
    ebr = math_('MULTIPLY', mr(br1, 0.35, 0.70), mr(br2, 0.30, 0.65, 0.4, 1.0))
    wear = mr(math_('MULTIPLY', mr(edge, 0.05, 0.45), ebr), 0.12, 0.40, 0.0, wa, 'SMOOTHSTEP')
    # scratches: thin stretched noise
    mp = N.new('ShaderNodeMapping')
    mp.inputs['Scale'].default_value = (22.0, 1.0, 22.0)   # scratches run along the length (Y)
    L.new(obc, mp.inputs['Vector'])
    scr = mr(noise(90.0, 2, 0.5, mp.outputs[0]), 0.625, 0.645, 0.0, 0.3 * wa, 'SMOOTHSTEP')
    wear = math_('MAXIMUM', wear, math_('MULTIPLY', scr, mr(br1, 0.4, 0.6)))
    dirt = mr(math_('MULTIPLY', mr(cav, 0.0, 0.6), mr(noise(25.0, 4), 0.35, 0.7, 0.5, 1.0)), 0.0, 1.0, 0.0, da)

    # base colour with low-frequency variation (+ wood grain colour)
    var = mr(noise(9.0, 5, 0.6), 0.3, 0.7, *VAR.get(key, (0.82, 1.12)))
    bcol = N.new('ShaderNodeMix')
    bcol.data_type = 'RGBA'
    bcol.blend_type = 'MULTIPLY'
    bcol.inputs[0].default_value = 1.0
    bcol.inputs[6].default_value = (*base, 1)
    L.new(var, bcol.inputs[7])
    col = bcol.outputs[2]
    height = None
    if relief == 'grain':
        mpg = N.new('ShaderNodeMapping')
        mpg.inputs['Scale'].default_value = (14.0, 1.2, 14.0)   # grain runs along Y
        L.new(obc, mpg.inputs['Vector'])
        wv = N.new('ShaderNodeTexWave')
        wv.wave_type = 'RINGS'
        wv.rings_direction = 'Y'
        wv.inputs['Scale'].default_value = 1.0
        wv.inputs['Distortion'].default_value = 9.0
        wv.inputs['Detail'].default_value = 5.0
        wv.inputs['Detail Scale'].default_value = 1.5
        L.new(mpg.outputs[0], wv.inputs['Vector'])
        g = mr(wv.outputs['Fac'], 0.2, 0.9)
        col = mixc(math_('MULTIPLY', g, 0.75), col, tuple(c * 0.45 for c in base))
        height = math_('MULTIPLY', g, 0.6)
    elif relief == 'stipple':
        vo = N.new('ShaderNodeTexVoronoi')
        vo.inputs['Scale'].default_value = 700.0
        L.new(obc, vo.inputs['Vector'])
        height = mr(vo.outputs['Distance'], 0.0, 0.6, 1.0, 0.0)
    elif relief == 'checker':
        a = N.new('ShaderNodeTexWave')
        a.wave_profile = 'SIN'
        a.bands_direction = 'DIAGONAL'
        a.inputs['Scale'].default_value = 260.0
        L.new(obc, a.inputs['Vector'])
        mpc = N.new('ShaderNodeMapping')
        mpc.inputs['Scale'].default_value = (-1.0, 1.0, 1.0)
        mpc.inputs['Rotation'].default_value = (0.0, 0.0, math.radians(90))
        L.new(obc, mpc.inputs['Vector'])
        b = N.new('ShaderNodeTexWave')
        b.wave_profile = 'SIN'
        b.bands_direction = 'DIAGONAL'
        b.inputs['Scale'].default_value = 260.0
        L.new(mpc.outputs[0], b.inputs['Vector'])
        height = math_('MINIMUM', a.outputs['Fac'], b.outputs['Fac'])
    elif relief == 'wrap':
        mpw = N.new('ShaderNodeMapping')
        mpw.inputs['Rotation'].default_value = (0.0, math.radians(60), 0.0)
        L.new(obc, mpw.inputs['Vector'])
        w = N.new('ShaderNodeTexWave')
        w.wave_profile = 'SAW'
        w.bands_direction = 'Y'
        w.inputs['Scale'].default_value = 32.0
        L.new(mpw.outputs[0], w.inputs['Vector'])
        height = mr(w.outputs['Fac'], 0.0, 1.0)
        col = mixc(math_('MULTIPLY', mr(w.outputs['Fac'], 0.85, 1.0), 0.6), col, tuple(c * 2.2 for c in base))
    elif relief == 'weave':
        a = N.new('ShaderNodeTexWave')
        a.bands_direction = 'X'
        a.inputs['Scale'].default_value = 420.0
        L.new(obc, a.inputs['Vector'])
        b = N.new('ShaderNodeTexWave')
        b.bands_direction = 'Z'
        b.inputs['Scale'].default_value = 420.0
        L.new(obc, b.inputs['Vector'])
        height = math_('MULTIPLY', a.outputs['Fac'], b.outputs['Fac'])
        # burnt / soaked tip, stains
        col = mixc(mr(noise(14.0, 5), 0.45, 0.75, 0.0, 0.7), col, (0.10, 0.075, 0.05))
    elif relief == 'brush':
        mpb = N.new('ShaderNodeMapping')
        mpb.inputs['Scale'].default_value = (900.0, 6.0, 900.0)
        L.new(obc, mpb.inputs['Vector'])
        height = mr(noise(1.0, 2, 0.5, mpb.outputs[0]), 0.3, 0.7)
    elif relief == 'tread':                      # (tyres) grooves round the circumference and blocks across
        a = N.new('ShaderNodeTexWave')
        a.bands_direction = 'X'
        a.wave_profile = 'SAW'
        a.inputs['Scale'].default_value = 28.0
        L.new(obc, a.inputs['Vector'])
        r_ = N.new('ShaderNodeTexWave')
        r_.wave_type = 'RINGS'
        r_.rings_direction = 'X'
        r_.inputs['Scale'].default_value = 90.0
        L.new(obc, r_.inputs['Vector'])
        height = math_('MULTIPLY', mr(a.outputs['Fac'], 0.1, 0.3), mr(r_.outputs['Fac'], 0.3, 0.5))
    elif relief == 'lens':                       # (lamps) fine prism ribs
        a = N.new('ShaderNodeTexWave')
        a.bands_direction = 'X'
        a.inputs['Scale'].default_value = 120.0
        L.new(obc, a.inputs['Vector'])
        height = a.outputs['Fac']
    elif relief == 'mesh':                       # (grilles) a square mesh
        a = N.new('ShaderNodeTexWave')
        a.bands_direction = 'X'
        a.wave_profile = 'SAW'
        a.inputs['Scale'].default_value = 55.0
        L.new(obc, a.inputs['Vector'])
        b = N.new('ShaderNodeTexWave')
        b.bands_direction = 'Z'
        b.wave_profile = 'SAW'
        b.inputs['Scale'].default_value = 55.0
        L.new(obc, b.inputs['Vector'])
        height = math_('MINIMUM', mr(a.outputs['Fac'], 0.0, 0.25), mr(b.outputs['Fac'], 0.0, 0.25))
        col = mixc(math_('SUBTRACT', 1.0, height), col, (0.003, 0.003, 0.003))
    elif relief == 'fine':
        height = noise(500.0, 2, 0.5)
    col = mixc(wear, col, wc)
    col = mixc(dirt, col, (0.035, 0.03, 0.025))
    rough = mixf(wear, br, wr)
    rough = mixf(dirt, rough, 0.85)
    rough = math_('ADD', rough, mr(noise(30.0, 3), 0.3, 0.7, -0.06, 0.06))
    rough = math_('MINIMUM', math_('MAXIMUM', rough, 0.04), 1.0)
    metal = mixf(wear, bm_, wm)
    metal = mixf(dirt, metal, 0.0)
    L.new(col, bsdf.inputs['Base Color'])
    L.new(rough, bsdf.inputs['Roughness'])
    L.new(metal, bsdf.inputs['Metallic'])
    if height is not None and rs > 0:
        bp = N.new('ShaderNodeBump')
        bp.inputs['Strength'].default_value = rs
        bp.inputs['Distance'].default_value = 0.0004
        L.new(height, bp.inputs['Height'])
        L.new(bp.outputs['Normal'], bsdf.inputs['Normal'])
    em = N.new('ShaderNodeEmission')
    MATS[key] = (m, {'color': col, 'rough': rough, 'metal': metal}, bsdf, out, em)
    return m


def bake_mode(channel):
    """channel in color / rough / metal: wire that signal to an Emission shader; None restores the BSDF"""
    for key, (m, socks, bsdf, out, em) in MATS.items():
        L = m.node_tree.links
        for l in list(out.inputs[0].links):
            L.remove(l)
        if channel is None:
            L.new(bsdf.outputs[0], out.inputs[0])
        else:
            for l in list(em.inputs['Color'].links):
                L.remove(l)
            if channel == 'mask':
                em.inputs['Color'].default_value = (1, 1, 1, 1)
            elif channel == 'amask':
                a = MASK.get(key, 0.0)
                em.inputs['Color'].default_value = (a, a, a, 1)
            else:
                L.new(socks[channel], em.inputs['Color'])
            L.new(em.outputs[0], out.inputs[0])


def loft(name, rings, mat, caps=True):
    """rings: list of equal-length lists of 3D points; consecutive rings joined by quads"""
    bm = bmesh.new()
    R = [[bm.verts.new(Vector(p)) for p in r] for r in rings]
    m = len(rings[0])
    for i in range(len(R) - 1):
        for k in range(m):
            l = (k + 1) % m
            bm.faces.new((R[i][k], R[i][l], R[i + 1][l], R[i + 1][k]))
    for i in range(len(R) - 1):
        _seam(bm, R[i][0], R[i + 1][0])
    if caps:
        bm.faces.new(R[0][::-1])
        bm.faces.new(R[-1])
        _seam_loop(bm, R[0])
        _seam_loop(bm, R[-1])
    return _obj(name, bm, mat)


def split_mat(ob, key, pred, planes=()):
    """bisect the mesh by planes [(co, no)], then give faces whose centre satisfies pred(c) the material key"""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    for co, no in planes:
        g = bm.verts[:] + bm.edges[:] + bm.faces[:]
        bmesh.ops.bisect_plane(bm, geom=g, plane_co=co, plane_no=no)
    me = ob.data
    if MAT(key).name not in [m.name for m in me.materials if m]:
        me.materials.append(MAT(key))
    idx = [m.name for m in me.materials].index(MAT(key).name)
    for f in bm.faces:
        if pred(f.calc_center_median()):
            f.material_index = idx
    bm.to_mesh(me)
    bm.free()
    return ob


def join(objs, name):
    objs = [o for o in objs if o is not None]
    if len(objs) == 1:
        objs[0].name = name
        objs[0].data.name = name
        return objs[0]
    with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, selected_objects=objs):
        bpy.ops.object.join()
    ob = objs[0]
    ob.name = name
    ob.data.name = name
    return ob


def mirror_x(ob):
    """copy of ob mirrored across X=0 (for left/right details)"""
    me = ob.data.copy()
    o2 = bpy.data.objects.new(ob.name + '_mx', me)
    coll().objects.link(o2)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.transform(bm, matrix=Matrix.Scale(-1, 4, (1, 0, 0)), verts=bm.verts)
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    return o2
