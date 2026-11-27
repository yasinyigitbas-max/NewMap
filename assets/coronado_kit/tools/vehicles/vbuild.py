"""blender -b -P vbuild.py -- <vehicle|all> [--quick]
One vehicle at a time: the game model (parts as their own nodes, each on its hinge / hub), the high model, one
shared unwrap, the bake (normal, AO, colour, roughness, metal, paint/glass mask), vpost.py composes the maps, the glb is
exported and vfinish.py points it at its maps and adds the markers. Writes assets/coronado_kit/vehicles/."""
import bpy, bmesh, sys, os, json, math, subprocess, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import vlib as vl
import wlib as w
import vmodels
from mathutils import Vector, Matrix
import numpy as np

ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
OUT = os.path.join(ROOT, 'vehicles')
argv = sys.argv[sys.argv.index('--') + 1:]
QUICK = '--quick' in argv
names = [a for a in argv if not a.startswith('--')]
if not names or names == ['all']:
    names = list(vmodels.FLEET)
RES = 1024   # (final maps: colour 1024, normal and ORM 512; --quick only lowers the samples)
WORK0 = os.environ.get('V_WORK', os.path.join(HERE, '_bake'))
os.makedirs(os.path.join(OUT, 'tex'), exist_ok=True)
t0 = time.time()
# texel weight per part family (seen less: smaller share of the page)
TEXEL = {'interior': 0.55, 'wheel': 0.8, 'lamps': 1.2, 'steering_wheel': 0.6}


def log(*a):
    print('[V %5.0fs]' % (time.time() - t0), *a, flush=True)


def clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    w.MATS.clear()
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)
    for i in list(bpy.data.images):
        bpy.data.images.remove(i)


def edit(objs):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')


def build_one(name):
    spec = vmodels.FLEET[name]
    WORK = os.path.join(WORK0, name)
    os.makedirs(WORK, exist_ok=True)
    clear()
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.render.threads_mode = 'FIXED'
    sc.render.threads = os.cpu_count() or 4
    lo_res = spec['build'](spec['p'], False)
    lows = {}
    for n, obs in lo_res['parts'].items():
        ob = w.join(obs, n)
        bm = bmesh.new()
        bm.from_mesh(ob.data)
        bmesh.ops.dissolve_degenerate(bm, dist=1e-5, edges=bm.edges)
        bmesh.ops.triangulate(bm, faces=bm.faces, quad_method='BEAUTY', ngon_method='BEAUTY')
        bm.to_mesh(ob.data)
        bm.free()
        w.smooth(ob, 40)
        lows[n] = ob
    hi_res = spec['build'](spec['p'], True)
    highs = [o for obs in hi_res['parts'].values() for o in obs]
    for o in highs:
        if not any(p.use_smooth for p in o.data.polygons):
            w.smooth(o, 35)
    ntri = {n: w.tris(o) for n, o in lows.items()}
    total = sum(ntri.values())
    log(name, 'low', total, 'tris', 'high', sum(w.tris(o) for o in highs))
    # unwrap: seams from the shell / primitives, one page for the whole vehicle
    lo_list = list(lows.values())
    for o in lo_list:                                    # seams on every sharp crease too (closed boxes would fold)
        bm = bmesh.new(); bm.from_mesh(o.data)
        for e in bm.edges:
            if len(e.link_faces) != 2 or e.calc_face_angle(0) > math.radians(55):
                e.seam = True
        bm.to_mesh(o.data); bm.free()
    for o in lo_list:
        edit([o])
        bpy.ops.uv.unwrap(method='ANGLE_BASED', fill_holes=True, correct_aspect=True, margin=0.0)
        bpy.ops.object.mode_set(mode='OBJECT')
    edit(lo_list)
    bpy.ops.uv.average_islands_scale()
    bpy.ops.object.mode_set(mode='OBJECT')
    for n, o in lows.items():
        k = next((v for key, v in TEXEL.items() if n.startswith(key)), 1.0)
        if k != 1.0:
            for l in o.data.uv_layers.active.data:
                l.uv = l.uv * k
    edit(lo_list)
    bpy.ops.uv.pack_islands(udim_source='CLOSEST_UDIM', rotate=True, rotate_method='ANY', scale=True, merge_overlap=False,
                            margin_method='FRACTION', margin=0.003, pin=False, shape_method='CONCAVE')
    bpy.ops.object.mode_set(mode='OBJECT')
    # bake: a joined copy of the low parts against every high part
    copies = []
    for o in lo_list:
        c = o.copy(); c.data = o.data.copy(); w.coll().objects.link(c); copies.append(c)
    bake_lo = w.join(copies, 'BAKE_LO')
    bmat = bpy.data.materials.new('BAKE'); bmat.use_nodes = True
    img_node = bmat.node_tree.nodes.new('ShaderNodeTexImage'); bmat.node_tree.nodes.active = img_node
    bake_lo.data.materials.clear(); bake_lo.data.materials.append(bmat)
    for o in lo_list:
        o.hide_render = True
    B = sc.render.bake
    B.use_selected_to_active = True
    B.use_cage = False
    B.cage_extrusion = 0.012
    B.max_ray_distance = 0.03
    B.margin_type = 'EXTEND'
    B.use_clear = True
    B.normal_space = 'TANGENT'

    def do_bake(kind, fname, samples, emit=None, margin=None):
        img = bpy.data.images.new(fname, RES, RES, alpha=False, float_buffer=True)
        img.colorspace_settings.name = 'Non-Color' if kind != 'EMIT' or emit not in ('color',) else 'Linear Rec.709'
        img_node.image = img
        sc.cycles.samples = samples
        B.margin = (6 if QUICK else 12) if margin is None else margin
        w.bake_mode(emit)
        bpy.ops.object.select_all(action='DESELECT')
        for o in highs:
            o.select_set(True)
        bake_lo.select_set(True)
        bpy.context.view_layer.objects.active = bake_lo
        t = time.time()
        bpy.ops.object.bake(type=kind)
        buf = np.empty(RES * RES * 4, dtype=np.float32)
        img.pixels.foreach_get(buf)
        np.save(os.path.join(WORK, fname + '.npy'), buf.reshape(RES, RES, 4)[::-1].copy())
        bpy.data.images.remove(img)
        log(' baked', fname, '%.0fs' % (time.time() - t))
    S = (lambda q, f: q if QUICK else f)
    do_bake('NORMAL', 'normal', S(4, 6))
    do_bake('AO', 'ao', S(24, 40))
    do_bake('EMIT', 'color', S(8, 12), emit='color')
    do_bake('EMIT', 'rough', S(6, 8), emit='rough')
    do_bake('EMIT', 'metal', S(6, 8), emit='metal')
    do_bake('EMIT', 'amask', 1, emit='amask', margin=S(6, 12))
    do_bake('EMIT', 'mask', 1, emit='mask', margin=0)
    w.bake_mode(None)
    r = subprocess.run(['python3', os.path.join(HERE, 'vpost.py'), WORK, os.path.join(OUT, 'tex'), name], capture_output=True, text=True)
    print(r.stdout, r.stderr)
    if r.returncode:
        raise SystemExit('vpost failed')
    # export: every part a node on its pivot; glass faces a material of their own
    bpy.data.objects.remove(bake_lo)
    for o in highs:
        bpy.data.objects.remove(o)
    m_body = bpy.data.materials.new('veh_' + name)
    m_glass = bpy.data.materials.new('veh_' + name + '_glass')
    gmat = w.MATS['glass'][0] if 'glass' in w.MATS else None
    for n, o in lows.items():
        me = o.data
        isg = [gmat is not None and p.material_index < len(me.materials) and me.materials[p.material_index] == gmat for p in me.polygons]
        me.materials.clear()
        me.materials.append(m_body)
        me.materials.append(m_glass)
        for p, g in zip(me.polygons, isg):
            p.material_index = 1 if g else 0
        if 'Col' not in me.color_attributes:
            ca = me.color_attributes.new('Col', 'BYTE_COLOR', 'CORNER')
            for v in ca.data:
                v.color = (1, 1, 1, 1)
        me.color_attributes.active_color = me.color_attributes['Col']
        vl.pivot(o, lo_res['pivots'][n])
        o.hide_render = False
    bpy.ops.object.select_all(action='DESELECT')
    for o in lo_list:
        o.select_set(True)
    bpy.context.view_layer.objects.active = lo_list[0]
    p_glb = os.path.join(OUT, 'veh_%s.glb' % name)
    bpy.ops.export_scene.gltf(filepath=p_glb, export_format='GLB', use_selection=True, export_yup=True, export_apply=False,
                              export_animations=False, export_cameras=False, export_lights=False, export_extras=False,
                              export_normals=True, export_tangents=True, export_texcoords=True, export_materials='EXPORT',
                              export_image_format='NONE', export_vertex_color='ACTIVE')
    dims = [max((o.matrix_world @ v.co)[i] for o in lo_list for v in o.data.vertices) - min((o.matrix_world @ v.co)[i] for o in lo_list for v in o.data.vertices) for i in range(3)]
    info = {'name': name, 'cls': spec['cls'], 'note': spec.get('note', ''), 'tris': total, 'parts_tris': ntri,
            'pivots': {n: list(lo_res['pivots'][n]) for n in lows}, 'markers': {k: list(v) for k, v in lo_res['markers'].items()},
            'axles': list(lo_res['axles']), 'wheel_r': lo_res['r'], 'size': [round(d, 3) for d in dims], 'res': RES}
    json.dump(info, open(os.path.join(WORK, 'info.json'), 'w'), indent=1)
    r = subprocess.run(['python3', os.path.join(HERE, 'vfinish.py'), WORK, OUT, name], capture_output=True, text=True)
    print(r.stdout, r.stderr)
    if r.returncode:
        raise SystemExit('vfinish failed')
    log('DONE', name, total, 'tris')


for n in names:
    build_one(n)
    import gc; gc.collect()
