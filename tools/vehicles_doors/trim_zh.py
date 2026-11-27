"""blender -b -P trim_zh.py -- <in.glb> <out.glb> [render_dir]
Trim one of Daniel Zhabotinsky's Sketchfab cars (CC BY 4.0) down to the game's level (~5k triangles for a car with its
cabin): parts nobody sees are deleted (underside, suspension, inner bumper shells, badges, plates), the rest is reduced by
edge collapse (UVs kept) to a budget per kind of part. The modelled interior is KEPT (reduced): it is the cabin.
Prints triangles before / after per kind; with a render dir, renders original and trimmed side by side for review.
This is the comparison step only: no atlas bake or door cut yet (one material per car comes later)."""
import bpy, sys, os, math, re
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:]
SRC, DST = argv[0], argv[1]
REN = argv[2] if len(argv) > 2 else None
DROP = re.compile(r'(suspension|badge|numberplate)', re.I)
# kind -> budget (triangles for all parts of that kind together)
KINDS = [('wheel', re.compile(r'wheel', re.I), 4 * 190),
         ('under', re.compile(r'bottom', re.I), 900),          # (frame, floor pan; on the MD trucks also the bed and grille)
         ('interior', re.compile(r'interior|steering', re.I), 1000),
         ('lights', re.compile(r'lightbar|headlights_glass|taillights|light|blinker|reverse', re.I), 450),
         ('glass', re.compile(r'glass|windshield', re.I), 400),
         ('body', re.compile(r'.'), 2600)]


def tris(o):
    o.data.calc_loop_triangles()
    return len(o.data.loop_triangles)


def kind_of(n):
    if re.search(r'interior|steering', n, re.I):      # (a steering wheel is not a wheel)
        return 'interior'
    for k, rx, _ in KINDS:
        if rx.search(n):
            return k
    return 'body'


def load(path):
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.data.objects if o.type == 'MESH']


def trim(meshes):
    before = {}
    after = {}
    for o in list(meshes):
        if DROP.search(o.name):
            before['dropped'] = before.get('dropped', 0) + tris(o)
            bpy.data.objects.remove(o)
            continue
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    groups = {}
    for o in meshes:
        groups.setdefault(kind_of(o.name), []).append(o)
    for k, rx, budget in KINDS:
        obs = groups.get(k, [])
        t0 = sum(tris(o) for o in obs)
        before[k] = before.get(k, 0) + t0
        if budget and t0 > budget:
            ratio = budget / t0
            for o in obs:
                m = o.modifiers.new('dec', 'DECIMATE')
                m.decimate_type = 'COLLAPSE'
                m.ratio = ratio
                m.use_collapse_triangulate = True
                with bpy.context.temp_override(object=o, active_object=o):
                    bpy.ops.object.modifier_apply(modifier=m.name)
        after[k] = sum(tris(o) for o in obs)
    return before, after


def render(objs_offset, path):
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'; sc.cycles.samples = 24; sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = 1400, 560
    sc.view_settings.view_transform = 'AgX'
    if not sc.world:
        sc.world = bpy.data.worlds.new('W')
    sc.world.use_nodes = True
    sc.world.node_tree.nodes['Background'].inputs[0].default_value = (0.6, 0.64, 0.7, 1)
    if 'sun' not in bpy.data.objects:
        ld = bpy.data.lights.new('sun', 'SUN'); ld.energy = 3.5
        lo = bpy.data.objects.new('sun', ld); sc.collection.objects.link(lo); lo.rotation_euler = (0.8, 0, 0.7)
        cd = bpy.data.cameras.new('c'); cd.type = 'ORTHO'; cd.ortho_scale = 13.5
        cam = bpy.data.objects.new('c', cd); sc.collection.objects.link(cam); sc.camera = cam
        bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    cam = bpy.data.objects['c']
    d = Vector((0.45, -1.0, 0.42)).normalized()
    cam.location = Vector((objs_offset / 2, 0, 0.8)) + d * 16
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


meshes = load(SRC)
t_orig = sum(tris(o) for o in meshes)
before, after = trim(meshes)
t_new = sum(tris(o) for o in bpy.data.objects if o.type == 'MESH')
print('TRIM %s: %d -> %d tris | before %s | after %s' % (os.path.basename(SRC), t_orig, t_new, before, after))
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', use_selection=False, export_animations=False)
if REN:
    # the original beside the trimmed one (moved 6 m along x)
    trimmed = [o for o in bpy.data.objects if o.type == 'MESH']
    roots = [o for o in bpy.data.objects if o.parent is None and o.type in ('MESH', 'EMPTY')]
    for o in roots:
        o.location.x += 6.0
    before_objs = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=SRC)
    render(6.0, os.path.join(REN, os.path.basename(SRC).replace('.glb', '_compare.png')))
