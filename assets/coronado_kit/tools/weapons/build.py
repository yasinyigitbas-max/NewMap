"""blender -b -P build.py -- [--quick]
Builds every weapon in models.WEAPONS: low (game) and high (bake source) models, packs all lows onto page G,
bakes colour / normal / AO / roughness / metal, composes the page (post.py), exports near + col glbs, writes
manifest_weapons.json. --quick bakes at 1024 with fewer samples (look-dev only).
"""
import bpy, bmesh, sys, os, json, math, subprocess, time, importlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import wlib as w
import models
importlib.reload(models)
from mathutils import Vector, Matrix

ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))            # assets/coronado_kit
OUT = os.path.join(ROOT, 'props', 'weapons')
ATL = os.path.join(ROOT, 'atlases')
WORK = os.environ.get('W_WORK', os.path.join(HERE, '_bake'))
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
QUICK = '--quick' in argv
RES = 1024 if QUICK else 2048
os.makedirs(OUT, exist_ok=True)
os.makedirs(WORK, exist_ok=True)
t0 = time.time()


def log(*a):
    print('[W %5.0fs]' % (time.time() - t0), *a, flush=True)


# ---------------------------------------------------------------- scene
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
for m in list(bpy.data.meshes):
    bpy.data.meshes.remove(m)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.render.threads_mode = 'FIXED'
sc.render.threads = os.cpu_count() or 4

lows, highs, info = {}, {}, {}
for name, d in models.WEAPONS.items():
    w.SEED[0] += 1
    lo_parts = d['build'](False)
    for o in lo_parts:
        w.smooth(o, d.get('low_angle', 40))
    lo = w.join(lo_parts, 'prop_%s_near' % name)
    # triangulate now so the bake tangents match the exported mesh exactly
    bm = bmesh.new()
    bm.from_mesh(lo.data)
    bmesh.ops.dissolve_degenerate(bm, dist=1e-5, edges=bm.edges)   # bevel clamp can collapse tight corners
    bmesh.ops.triangulate(bm, faces=bm.faces, quad_method='BEAUTY', ngon_method='BEAUTY')
    bm.to_mesh(lo.data)
    bm.free()
    lo.data.materials.clear()
    hi_parts = d['build'](True)
    for o in hi_parts:
        if not any(p.use_smooth for p in o.data.polygons):
            w.smooth(o, 32)
    lows[name] = lo
    highs[name] = hi_parts
    nt = w.tris(lo)
    hi_t = sum(w.tris(o) for o in hi_parts)
    info[name] = {'tris': nt, 'high_tris': hi_t}
    log('built', name, 'low', nt, 'budget', d['budget'], 'high', hi_t, 'OVER' if nt > d['budget'] else '')

# ---------------------------------------------------------------- UVs: per-object smart project, one shared pack
def edit_all(objs):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')


for name, lo in lows.items():
    edit_all([lo])
    # seams were placed by the primitives (cap outlines + one long edge per strip): each part unrolls as a few islands
    bpy.ops.uv.unwrap(method='ANGLE_BASED', fill_holes=True, correct_aspect=True, margin=0.0)
    bpy.ops.object.mode_set(mode='OBJECT')
lo_list = list(lows.values())
edit_all(lo_list)
bpy.ops.uv.average_islands_scale()
bpy.ops.object.mode_set(mode='OBJECT')
for name, lo in lows.items():
    wt = models.WEAPONS[name].get('texel', 1.0)
    if wt != 1.0:
        for l in lo.data.uv_layers.active.data:
            l.uv = l.uv * wt
edit_all(lo_list)
bpy.ops.uv.pack_islands(udim_source='CLOSEST_UDIM', rotate=True, rotate_method='ANY', scale=True, merge_overlap=False,
                        margin_method='FRACTION', margin=0.003, pin=False, shape_method=os.environ.get('W_SHAPE', 'CONCAVE'))
bpy.ops.object.mode_set(mode='OBJECT')

def uv_fill():
    s = 0.0
    for lo in lows.values():
        me = lo.data
        me.calc_loop_triangles()
        uv = me.uv_layers.active.data
        for t in me.loop_triangles:
            a, b_, c = (uv[i].uv for i in t.loops)
            s += abs((b_ - a).cross(c - a)) / 2
    return s


log('uv fill %.1f %%' % (100 * uv_fill()))
if os.environ.get('W_UVONLY'):
    dump = {}
    for n, lo in lows.items():
        uv = lo.data.uv_layers.active.data
        dump[n] = [[tuple(uv[i].uv) for i in t.loops] for t in lo.data.loop_triangles]
    json.dump(dump, open(os.path.join(WORK, 'uv.json'), 'w'))
    raise SystemExit(0)

# ---------------------------------------------------------------- bake
SP = 1.0
for i, name in enumerate(lows):
    off = Vector((i * SP, 0, 0))
    lows[name].location = off
    for o in highs[name]:
        o.location = off
copies = []
for n, lo in lows.items():
    c = lo.copy()
    c.data = lo.data.copy()
    w.coll().objects.link(c)
    copies.append(c)
bake_lo = w.join(copies, 'BAKE_LO')
bm_ = bpy.data.materials.new('BAKE')
bm_.use_nodes = True
img_node = bm_.node_tree.nodes.new('ShaderNodeTexImage')
bm_.node_tree.nodes.active = img_node
bake_lo.data.materials.clear()
bake_lo.data.materials.append(bm_)
for n in lows:
    lows[n].hide_render = True
all_hi = [o for n in highs for o in highs[n]]

B = sc.render.bake
B.use_selected_to_active = True
B.use_cage = False
B.cage_extrusion = 0.004
B.max_ray_distance = 0.012
B.margin = 6 if QUICK else 12
B.margin_type = 'EXTEND'
B.use_clear = True
B.normal_space = 'TANGENT'


def do_bake(kind, fname, samples, noncolor=True, emit_channel=None):
    img = bpy.data.images.new(fname, RES, RES, alpha=False, float_buffer=True)
    img.colorspace_settings.name = 'Non-Color' if noncolor else 'Linear Rec.709'
    img_node.image = img
    sc.cycles.samples = samples
    w.bake_mode(emit_channel)
    bpy.ops.object.select_all(action='DESELECT')
    for o in all_hi:
        o.select_set(True)
    bake_lo.select_set(True)
    bpy.context.view_layer.objects.active = bake_lo
    t = time.time()
    bpy.ops.object.bake(type=kind)
    import numpy as np
    buf = np.empty(RES * RES * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    np.save(os.path.join(WORK, fname + '.npy'), buf.reshape(RES, RES, 4)[::-1].copy())
    log('baked', fname, '%.0fs' % (time.time() - t))


S = (lambda q, f: q if QUICK else f)
do_bake('NORMAL', 'normal', S(4, 8))
do_bake('AO', 'ao', S(32, 64))
do_bake('EMIT', 'color', S(8, 16), noncolor=False, emit_channel='color')
do_bake('EMIT', 'rough', S(8, 16), emit_channel='rough')
do_bake('EMIT', 'metal', S(8, 16), emit_channel='metal')
B.margin = 0
do_bake('EMIT', 'mask', 1, emit_channel='mask')
w.bake_mode(None)

r = subprocess.run(['python3', os.path.join(HERE, 'post.py'), WORK, ATL], capture_output=True, text=True)
print(r.stdout, r.stderr)
if r.returncode:
    raise SystemExit('post.py failed')

# ---------------------------------------------------------------- export
bpy.data.objects.remove(bake_lo)
for o in all_hi:
    o.hide_render = True
    o.hide_set(True)
gm = bpy.data.materials.new('props_g_atlas')
man_p = os.path.join(ROOT, 'props', 'manifest_weapons.json')


def area3(me):
    me.calc_loop_triangles()
    return sum(t.area for t in me.loop_triangles)


def area_uv(me):
    uv = me.uv_layers.active.data
    s = 0.0
    for t in me.loop_triangles:
        a, b, c = (uv[i].uv for i in t.loops)
        s += abs((b - a).cross(c - a)) / 2
    return s


def export(obs, path, col=False):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:
        o.hide_set(False)
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    kw = dict(filepath=path, export_format='GLB', use_selection=True, export_yup=True, export_apply=True,
              export_animations=False, export_cameras=False, export_lights=False, export_extras=False)
    if col:
        kw.update(export_normals=False, export_texcoords=False, export_materials='NONE', export_vertex_color='NONE')
    else:
        kw.update(export_normals=True, export_tangents=True, export_texcoords=True, export_materials='EXPORT',
                  export_image_format='NONE', export_vertex_color='ACTIVE')
    bpy.ops.export_scene.gltf(**kw)


manifest = {}
for name, lo in lows.items():
    d = models.WEAPONS[name]
    lo.location = (0, 0, 0)
    lo.hide_render = False
    lo.data.materials.clear()
    lo.data.materials.append(gm)
    if 'Col' not in lo.data.color_attributes:
        ca = lo.data.color_attributes.new('Col', 'BYTE_COLOR', 'CORNER')
        for v in ca.data:
            v.color = (1, 1, 1, 1)
    lo.data.color_attributes.active_color = lo.data.color_attributes['Col']
    base = 'prop_%s' % name
    p_near = os.path.join(OUT, base + '_clean_near.glb')
    export([lo], p_near)
    # collision: one box (or boxes) from the model's spec, else the low's bounds
    cb = d.get('col') or [tuple(min(v.co[i] for v in lo.data.vertices) for i in range(3)),
                          tuple(max(v.co[i] for v in lo.data.vertices) for i in range(3))]
    boxes = cb if isinstance(cb[0][0], (tuple, list)) else [cb]
    cobs = [w.box('c%d' % k, a, b, None) for k, (a, b) in enumerate(boxes)]
    co = w.join(cobs, 'col') if len(cobs) > 1 else cobs[0]
    co.name = 'col'
    co.data.name = 'col'
    export([co], os.path.join(OUT, base + '_col.glb'), col=True)
    bpy.data.objects.remove(co)
    lo.data.calc_loop_triangles()
    a3 = area3(lo.data)
    auv = area_uv(lo.data)
    pxm = math.sqrt(auv / a3) * 1024 if a3 else 0
    dims = [max(v.co[i] for v in lo.data.vertices) - min(v.co[i] for v in lo.data.vertices) for i in range(3)]
    manifest[name] = {
        'file_base': base, 'batch': 'weapons', 'kind': d['kind'], 'class': d['cls'], 'budget': d['budget'],
        'conds': ['clean'], 'mount': 'hand', 'tiers': {'near': info[name]['tris']}, 'high_tris': info[name]['high_tris'],
        'length': round(dims[1], 3), 'width': round(dims[0], 3), 'height': round(dims[2], 3),
        'atlas_page': 'props_g_*', 'px_per_m_colour': round(pxm, 1), 'col': len(boxes),
        'grips': d['grips'], 'hold': d['hold'], 'muzzle': d.get('muzzle'), 'note': d.get('note', ''),
    }
    log('exported', name, info[name]['tris'], 'tris', '%.0f px/m' % pxm)
json.dump({'_build': {'res': RES, 'quick': QUICK}, **manifest}, open(os.path.join(WORK, 'build_info.json'), 'w'), indent=1)
r = subprocess.run(['python3', os.path.join(HERE, 'finish.py'), WORK, OUT, man_p], capture_output=True, text=True)
print(r.stdout, r.stderr)
if r.returncode:
    raise SystemExit('finish.py failed')
log('DONE')
