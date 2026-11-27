"""blender -b -P zh_build.py -- <source.glb> <out_dir> <id> [--quick]
One of Daniel Zhabotinsky's Sketchfab cars (CC BY 4.0) made into a game car with ONE material:
  1. the original (full detail) is placed in the game frame: front -Y in Blender (= +Z in Godot), left +X, wheels on the
     ground (z = 0), centred on its footprint;
  2. the game model: a trimmed copy (trim_zh.py's rules; the modelled cabin is kept), wheels apart, all the rest one body;
  3. one unwrap for body + wheels (cabin and underside get a smaller share of the page);
  4. bake from the original onto it: colour (the plain body paint baked as a light neutral, so the game's paint colour
     tints it; liveries keep their colours), roughness, metal, normal, AO, and the paint / glass mask of
     car_paint.gdshader (alpha: 1 paint, 0.5 glass, 0 own colour);
  5. writes <out>/<id>_body and <id>_w0..3 (mesh_dump format, Godot frame) and <id>_bake/*.npy, and <id>_info.json
     (wheel hubs and radius, size). zh_post.py makes the maps, cut_doors.py the doors, mesh_pack.gd the .res files."""
import bpy, bmesh, sys, os, json, math, re, time
import numpy as np
from mathutils import Vector, Matrix
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import meshio

argv = sys.argv[sys.argv.index('--') + 1:]
SRC, OUT, ID = argv[0], argv[1], argv[2]
QUICK = '--quick' in argv
RES = 1024 if QUICK else 2048
BK = os.path.join(OUT, ID + '_bake')
os.makedirs(BK, exist_ok=True)
t0 = time.time()


def log(*a):
    print('[ZH %4.0fs]' % (time.time() - t0), *a, flush=True)


DROP = re.compile(r'(suspension|badge|numberplate)', re.I)
KINDS = [('wheel', re.compile(r'wheel', re.I), 4 * 500),    # (~500 a wheel: at 300 the trimmed tyre cut 3-6 cm inside the real one and baked white stripes)
         ('under', re.compile(r'bottom', re.I), 900),
         ('interior', re.compile(r'interior|steering', re.I), 1000),
         ('lights', re.compile(r'lightbar|headlights_glass|taillights|light|blinker|reverse', re.I), 450),
         ('glass', re.compile(r'glass|windshield', re.I), 400),
         ('body', re.compile(r'.'), 2600)]
TEXEL = {'interior': 0.55, 'under': 0.35, 'wheel': 0.5}


def kind_of(n):
    if re.search(r'interior|steering', n, re.I):      # (a steering wheel is not a wheel)
        return 'interior'
    for k, rx, _ in KINDS:
        if rx.search(n):
            return k
    return 'body'


def tris(o):
    o.data.calc_loop_triangles()
    return len(o.data.loop_triangles)


def apply_all(o):
    with bpy.context.temp_override(object=o, active_object=o, selected_objects=[o], selected_editable_objects=[o]):
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


# ---------------------------------------------------------------- 1. the original in the game frame
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
bpy.ops.import_scene.gltf(filepath=SRC)
for o in list(bpy.data.objects):          # flatten the hierarchy into world transforms
    if o.type == 'MESH':
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
for o in [o for o in bpy.data.objects if o.type != 'MESH']:
    bpy.data.objects.remove(o)
hi = [o for o in bpy.data.objects if o.type == 'MESH']
for o in hi:
    if o.data.users > 1:
        o.data = o.data.copy()
    apply_all(o)


def bounds(obs):
    pts = [v.co for o in obs for v in o.data.vertices]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi_ = Vector([max(p[i] for p in pts) for i in range(3)])
    return lo, hi_


lo, hi_b = bounds(hi)
size = hi_b - lo
if size.length > 40:                      # (models in centimetres)
    for o in hi:
        o.data.transform(Matrix.Scale(0.01, 4))
    lo, hi_b = bounds(hi)
# the length along Y, the front towards -Y: the headlights tell where the front is
heads = [o for o in hi if re.search(r'headlight', o.name, re.I)]
hc = sum((sum((v.co for v in o.data.vertices), Vector()) / max(1, len(o.data.vertices)) for o in heads), Vector()) / max(1, len(heads))
ctr = (lo + hi_b) / 2
R = Matrix.Identity(4)
if size.x > size.y:                       # long in x: turn so the headlights end goes to -y
    R = Matrix.Rotation(math.radians(-90 if hc.x > ctr.x else 90), 4, 'Z')
elif hc.y > ctr.y:
    R = Matrix.Rotation(math.radians(180), 4, 'Z')
for o in hi:
    o.data.transform(R)
wheels_hi = [o for o in hi if kind_of(o.name) == 'wheel']
lo, hi_b = bounds(hi)
wl, wh = bounds(wheels_hi) if wheels_hi else (lo, hi_b)
shift = Vector((-(lo.x + hi_b.x) / 2, -(lo.y + hi_b.y) / 2, -wl.z))
for o in hi:
    o.data.transform(Matrix.Translation(shift))
lo, hi_b = bounds(hi)
log(ID, 'size %.2f x %.2f x %.2f' % tuple(hi_b - lo), 'high tris', sum(tris(o) for o in hi))

# ---------------------------------------------------------------- 2. the game model
def dup(o):
    c = o.copy(); c.data = o.data.copy(); bpy.context.scene.collection.objects.link(c); return c


low = [dup(o) for o in hi if not DROP.search(o.name)]
groups = {}
for o in low:
    groups.setdefault(kind_of(o.name), []).append(o)
for k, rx, budget in KINDS:
    obs = groups.get(k, [])
    t = sum(tris(o) for o in obs)
    if budget and t > budget:
        for o in obs:
            m = o.modifiers.new('dec', 'DECIMATE'); m.decimate_type = 'COLLAPSE'; m.ratio = budget / t; m.use_collapse_triangulate = True
            with bpy.context.temp_override(object=o, active_object=o):
                bpy.ops.object.modifier_apply(modifier=m.name)
# wheels: one object each, named by where they are
wheels = []
for o in groups.get('wheel', []):
    c = sum((v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
    wheels.append((c, o))
# (some models split a wheel into tyre / rim objects: merge those sharing a hub)
hubs = []
for c, o in wheels:
    for h in hubs:
        if (h[0] - c).length < 0.25:
            h[1].append(o); break
    else:
        hubs.append([c, [o]])
for h in hubs:
    for o in h[1]:
        o['kind'] = 'wheel'
for o in low:
    if o.get('kind') != 'wheel':
        o['kind'] = kind_of(o.name)


def join(obs, name):
    if len(obs) > 1:
        with bpy.context.temp_override(active_object=obs[0], selected_editable_objects=obs, selected_objects=obs):
            bpy.ops.object.join()
    obs[0].name = name; obs[0].data.name = name
    return obs[0]


# texel weights go on the faces before the parts are joined (a face attribute survives the join)
for o in low:
    o.data.attributes.new('texel', 'FLOAT', 'FACE')
    w = TEXEL.get(o['kind'], 1.0)
    for d in o.data.attributes['texel'].data:
        d.value = w
body_parts = [o for o in low if o.get('kind') != 'wheel']
body = join(body_parts, 'body')
wheel_objs = []
for i, h in enumerate(sorted(hubs, key=lambda h: (-h[0].y, h[0].x))):
    wheel_objs.append(join(h[1], 'w%d' % i))
# ONE wheel for all four (the front-left one, turned about for the right side): the four share their UVs, so the wheel
# gets four times the texels (the white-wall ring and the lettering broke into blocks on a quarter share each)
def bbox_c(o):      # (the axle: the middle of the bounds; a vertex mean leans to the busy outer face)
    vs = [v.co for v in o.data.vertices]
    return Vector([(max(v[k] for v in vs) + min(v[k] for v in vs)) / 2 for k in range(3)])


w_c = [bbox_c(o) for o in wheel_objs]
def unwrap_alone(o):
    while o.data.uv_layers:
        o.data.uv_layers.remove(o.data.uv_layers[0])
    o.data.uv_layers.new(name='UV')
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.0, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.object.mode_set(mode='OBJECT')


def dims(o):
    vs = [v.co for v in o.data.vertices]
    return sorted(max(v[k] for v in vs) - min(v[k] for v in vs) for k in range(3))


tmpl = wheel_objs[0]
unwrap_alone(tmpl)
for i in range(1, len(wheel_objs)):
    o = wheel_objs[i]
    if any(abs(a - b) > 0.02 for a, b in zip(dims(o), dims(tmpl))):     # (a different wheel: twin rears on a truck) its own UVs
        log('wheel %d differs from the front one: own UVs' % i)
        unwrap_alone(o)
        continue
    o.data = tmpl.data.copy()
    M = Matrix.Translation(w_c[i]) @ (Matrix.Rotation(math.pi, 4, 'Z') if (w_c[i].x > 0) != (w_c[0].x > 0) else Matrix.Identity(4)) @ Matrix.Translation(-w_c[0])
    o.data.transform(M)
# one mesh for unwrapping, packing and baking (a multi-object pack laid every part over the whole page); a face
# attribute 'part' (0 body, 1.. the wheels) splits it again afterwards
while body.data.uv_layers:      # (one UV layer named 'UV' on every part, or the join keeps them apart)
    body.data.uv_layers.remove(body.data.uv_layers[0])
body.data.uv_layers.new(name='UV')
parts_in = [body] + wheel_objs
hub_c = []
for pi, o in enumerate(parts_in):
    o.data.attributes.new('part', 'INT', 'FACE')
    for d in o.data.attributes['part'].data:
        d.value = pi
    if pi:
        hub_c.append(bbox_c(o))
J = join(parts_in, 'J')
bm = bmesh.new(); bm.from_mesh(J.data)
bmesh.ops.dissolve_degenerate(bm, dist=1e-5, edges=bm.edges)
bmesh.ops.triangulate(bm, faces=bm.faces, quad_method='BEAUTY', ngon_method='BEAUTY')
bm.to_mesh(J.data); bm.free()
log('low tris', tris(J))

# ---------------------------------------------------------------- 3. one unwrap
def edit(obs):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')


# the body is unwrapped here; the wheels keep the template's UVs (shared by all four)
edit([J])
bm = bmesh.from_edit_mesh(J.data)
lay = bm.faces.layers.int.get('part')
for f in bm.faces:
    f.select = f[lay] == 0
bmesh.update_edit_mesh(J.data)
bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.0, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.average_islands_scale()
bpy.ops.object.mode_set(mode='OBJECT')
# the shared wheel: 1.5 x the texel density of the body (scaled as a whole, about one point: its islands stay whole)
uv = J.data.uv_layers['UV'].data
pa = J.data.attributes['part'].data
wl = [li for p in J.data.polygons if pa[p.index].value > 0 for li in p.loop_indices]
if wl:
    c0 = sum((uv[li].uv for li in wl), Vector((0, 0))) / len(wl)
    for li in set(wl):
        uv[li].uv = c0 + (uv[li].uv - c0) * 1.5
# (one texel density for all: shrinking single faces split them into thousands of islands and wasted the page)
edit([J])
bpy.ops.uv.pack_islands(udim_source='CLOSEST_UDIM', rotate=True, rotate_method='ANY', scale=True, merge_overlap=True,
                        margin_method='FRACTION', margin=0.003, pin=False, shape_method='CONCAVE')
bpy.ops.object.mode_set(mode='OBJECT')
lows = [J]

# ---------------------------------------------------------------- 4. bake from the original
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'
sc.render.threads_mode = 'FIXED'; sc.render.threads = os.cpu_count() or 4
# the high model's materials: opaque for the bake; plain body paint = light neutral (tinted in the game)
PAINT = []
for m in bpy.data.materials:
    if not m.use_nodes:
        continue
    b = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if not b:
        continue
    for l in list(b.inputs['Alpha'].links):
        m.node_tree.links.remove(l)
    b.inputs['Alpha'].default_value = 1.0
    if re.search(r'bodymat', m.name, re.I) and not b.inputs['Base Color'].links:
        b.inputs['Base Color'].default_value = (0.8, 0.8, 0.8, 1)
        PAINT.append(m.name)
    if hasattr(m, 'blend_method'):
        m.blend_method = 'OPAQUE'


def mask_of(m):
    if m.name in PAINT:
        return 1.0
    if re.search(r'glass|transp|windshield', m.name, re.I) and not re.search(r'light', m.name.replace('Lights_and_Glass', 'glass'), re.I):
        return 0.5
    if re.search(r'Lights_and_Glass_Transperent', m.name):
        return 0.5
    return 0.0


# glass objects decide by object name too (their material is shared with lamp lenses)
GLASS_OBJ = re.compile(r'(windshield|glass_driver|glass_passenger|glass_passanger|body_glass|rear_glass|glass_rear|_glass$)', re.I)
bake_lo = J
keep_mats = list(J.data.materials)
bmat = bpy.data.materials.new('BAKE'); bmat.use_nodes = True
img_node = bmat.node_tree.nodes.new('ShaderNodeTexImage'); bmat.node_tree.nodes.active = img_node
bake_lo.data.materials.clear(); bake_lo.data.materials.append(bmat)
B = sc.render.bake
B.use_selected_to_active = True; B.use_cage = False
B.cage_extrusion = 0.05; B.max_ray_distance = 0.12
B.margin_type = 'EXTEND'; B.use_clear = True; B.normal_space = 'TANGENT'


def emission_mode(fn):
    """every high material emits fn(material, bsdf) -> (socket or None, value) ; None restores"""
    for m in bpy.data.materials:
        if not m.use_nodes or m == bmat:
            continue
        nt = m.node_tree
        out = next((n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL'), None)
        b = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if not out or not b:
            continue
        em = nt.nodes.get('_em') or nt.nodes.new('ShaderNodeEmission')
        em.name = '_em'
        for l in list(out.inputs[0].links):
            nt.links.remove(l)
        if fn is None:
            nt.links.new(b.outputs[0], out.inputs[0])
            continue
        for l in list(em.inputs['Color'].links):
            nt.links.remove(l)
        sock, val = fn(m, b)
        if sock is not None:
            nt.links.new(sock, em.inputs['Color'])
        else:
            em.inputs['Color'].default_value = (val, val, val, 1)
        nt.links.new(em.outputs[0], out.inputs[0])


def bake(kind, name, samples, margin=None, pass_color=False):
    img = bpy.data.images.new(name, RES, RES, alpha=False, float_buffer=True)
    img.colorspace_settings.name = 'Linear Rec.709' if name == 'color' else 'Non-Color'
    img_node.image = img
    sc.cycles.samples = samples
    B.margin = (8 if QUICK else 16) if margin is None else margin
    if pass_color:
        B.use_pass_direct = False; B.use_pass_indirect = False; B.use_pass_color = True
    bpy.ops.object.select_all(action='DESELECT')
    for o in hi:
        o.select_set(True)
    bake_lo.select_set(True)
    bpy.context.view_layer.objects.active = bake_lo
    t = time.time()
    bpy.ops.object.bake(type=kind)
    buf = np.empty(RES * RES * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    np.save(os.path.join(BK, name + '.npy'), buf.reshape(RES, RES, 4)[::-1].copy())
    bpy.data.images.remove(img)
    log(' baked', name, '%.0fs' % (time.time() - t))


S = (lambda q, f: q if QUICK else f)
bake('DIFFUSE', 'color', S(4, 8), pass_color=True)
bake('ROUGHNESS', 'rough', S(4, 8))
bake('NORMAL', 'normal', S(4, 8))
bake('AO', 'ao', S(32, 96))
emission_mode(lambda m, b: (b.inputs['Metallic'].links[0].from_socket if b.inputs['Metallic'].links else None, b.inputs['Metallic'].default_value))
bake('EMIT', 'metal', S(4, 8))
glass_mats = set()
for o in hi:
    if GLASS_OBJ.search(o.name):
        for m in o.data.materials:
            if m:
                glass_mats.add(m.name)
# glass objects share a material with lamp lenses: give them their own copy for the mask
for o in hi:
    if GLASS_OBJ.search(o.name):
        for i, m in enumerate(o.data.materials):
            if m and not m.name.endswith('_GLASSMASK'):
                c = bpy.data.materials.get(m.name + '_GLASSMASK') or m.copy()
                c.name = m.name + '_GLASSMASK' if not c.name.endswith('_GLASSMASK') else c.name
                o.data.materials[i] = c
emission_mode(lambda m, b: (None, 0.5 if m.name.endswith('_GLASSMASK') else (1.0 if m.name in PAINT else 0.0)))
bake('EMIT', 'amask', 1)
emission_mode(lambda m, b: (None, 1.0))
bake('EMIT', 'cover', 1, margin=0)
emission_mode(None)

# ---------------------------------------------------------------- 5. the game meshes in the Godot frame
# split the baked mesh back into the body and its wheels
def part_obj(pi, name):
    me = J.data.copy()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    bm = bmesh.new(); bm.from_mesh(me)
    lay = bm.faces.layers.int.get('part')
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f[lay] != pi], context='FACES')
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')   # (the other parts' vertices)
    bm.to_mesh(me); bm.free()
    return o


body = part_obj(0, 'body')
wheel_objs = [part_obj(i + 1, 'w%d' % i) for i in range(len(hub_c))]
bpy.data.objects.remove(J)
lows = [body] + wheel_objs


def dump(o, name, origin=Vector()):
    me = o.data
    me.calc_loop_triangles()
    me.calc_tangents(uvmap='UV')
    uv = me.uv_layers['UV'].data
    rows = []
    for t in me.loop_triangles:
        for li in (t.loops[0], t.loops[2], t.loops[1]):   # (Godot's front faces wind clockwise: Blender's the other way)
            l = me.loops[li]
            p = me.vertices[l.vertex_index].co - origin
            n = l.normal
            tg = l.tangent
            u = uv[li].uv
            gp = meshio.b2g(p); gn = meshio.b2g(n); gt = meshio.b2g(tg)
            rows.append([*gp, *gn, *gt, l.bitangent_sign, u.x, 1.0 - u.y, u.x, 1.0 - u.y])
    V = np.array(rows, np.float32)
    meshio.write(os.path.join(OUT, name), V, np.arange(len(V)), {'metas': {}, 'format': 0, 'winding': 'godot'})
    return len(V) // 3


for o in lows:
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.set_sharp_from_angle(angle=math.radians(40))
info = {'id': ID, 'source': os.path.basename(SRC), 'wheels': [], 'tris': {}}
info['tris']['body'] = dump(body, ID + '_body')
for i, o in enumerate(wheel_objs):
    c = sum((v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
    lo_w, hi_w = bounds([o])
    r = max(hi_w.y - lo_w.y, hi_w.z - lo_w.z) / 2
    info['tris']['w%d' % i] = dump(o, '%s_w%d' % (ID, i), origin=c)
    info['wheels'].append({'center': list(meshio.b2g(c)), 'radius': r})
    # the light tier's wheel (22-85 m): the same wheel reduced to ~120 triangles, its UVs (and so its bake) kept
    lw = dup(o)
    t = tris(lw)
    if t > 120:
        m = lw.modifiers.new('dec', 'DECIMATE'); m.decimate_type = 'COLLAPSE'; m.ratio = 120 / t; m.use_collapse_triangulate = True
        with bpy.context.temp_override(object=lw, active_object=lw):
            bpy.ops.object.modifier_apply(modifier=m.name)
    info['tris']['w%d_lo' % i] = dump(lw, '%s_w%d_lo' % (ID, i), origin=c)
lo, hi_b = bounds(lows)
info['size_godot'] = [hi_b.x - lo.x, hi_b.z - lo.z, hi_b.y - lo.y]
info['paint_materials'] = PAINT
info['res'] = RES
json.dump(info, open(os.path.join(OUT, ID + '_info.json'), 'w'), indent=1)
log('DONE', ID, info['tris'], 'size', [round(v, 2) for v in info['size_godot']], 'paint', PAINT)
