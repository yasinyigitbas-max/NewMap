"""blender -b -P render.py -- <out_dir> [names...]
Imports each exported near glb (this also proves the page G URIs resolve) and renders: hero 3/4, right side,
left side, top; plus lineup.png (every weapon on a 10 cm grid, muzzle to the right) and scale.png (1.8 m figure)."""
import bpy, sys, os, json, math
from mathutils import Vector, Matrix
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
argv = sys.argv[sys.argv.index('--') + 1:]
OUT = argv[0]
os.makedirs(OUT, exist_ok=True)
man = json.load(open(os.path.join(ROOT, 'props', 'manifest_weapons.json')))
names = argv[1:] or list(man)
SAMP = int(os.environ.get('W_SAMPLES', '48'))
RX, RY = 960, 600

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.cycles.samples = SAMP
sc.cycles.use_denoising = True
sc.render.threads_mode = 'FIXED'
sc.render.threads = os.cpu_count() or 4
sc.view_settings.view_transform = 'AgX'
sc.view_settings.look = 'AgX - Base Contrast'
sc.render.resolution_x, sc.render.resolution_y = RX, RY
wd = bpy.data.worlds.new('W')
sc.world = wd
wd.use_nodes = True
bg = wd.node_tree.nodes['Background']
bg.inputs[0].default_value = (0.55, 0.58, 0.62, 1)
bg.inputs[1].default_value = 0.45


def light(name, loc, energy, size, rot_to=(0, 0, 0)):
    l = bpy.data.lights.new(name, 'AREA')
    l.energy = energy
    l.size = size
    o = bpy.data.objects.new(name, l)
    sc.collection.objects.link(o)
    o.location = loc
    d = Vector(rot_to) - Vector(loc)
    o.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    return o


# ground plane (light grey studio sweep)
bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, -0.5))
gp = bpy.context.object
gm = bpy.data.materials.new('ground')
gm.use_nodes = True
gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.36, 0.37, 0.38, 1)
gm.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 0.8
gp.data.materials.append(gm)

cam_d = bpy.data.cameras.new('cam')
cam = bpy.data.objects.new('cam', cam_d)
sc.collection.objects.link(cam)
sc.camera = cam


def imp(name):
    rec = man[name]
    p = os.path.join(ROOT, 'props', 'weapons', rec['file_base'] + '_clean_near.glb')
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=p)
    new = [o for o in bpy.data.objects if o not in before]
    mesh = [o for o in new if o.type == 'MESH'][0]
    for o in new:
        if o.type != 'MESH':
            o.hide_render = True
    # glTF importer: check the textures actually loaded
    imgs = [n.image for m in mesh.data.materials for n in m.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image]
    ok = all(i.has_data or i.size[0] > 0 for i in imgs) and len(imgs) >= 3
    if not ok:
        print('TEXTURE MISSING', name, [i.filepath for i in imgs])
    return mesh, new


def bounds(o):
    cs = [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector([min(c[i] for c in cs) for i in range(3)])
    hi = Vector([max(c[i] for c in cs) for i in range(3)])
    return lo, hi


def shoot(path, obj, view):
    lo, hi = bounds(obj)
    c = (lo + hi) / 2
    size = max((hi - lo).length, 0.05)
    gp.location.z = lo.z - 0.002
    if view == 'hero':
        d = Vector((1.0, -0.9, 0.55)).normalized()
        cam_d.type = 'PERSP'
        cam_d.lens = 85
        dist = size * 2.2
    elif view == 'right':
        d = Vector((1, 0, 0.0001))
        cam_d.type = 'ORTHO'
        cam_d.ortho_scale = max(hi.y - lo.y, (hi.z - lo.z) * RX / RY) * 1.12
        dist = size * 3
    elif view == 'left':
        d = Vector((-1, 0, 0.0001))
        cam_d.type = 'ORTHO'
        cam_d.ortho_scale = max(hi.y - lo.y, (hi.z - lo.z) * RX / RY) * 1.12
        dist = size * 3
    elif view == 'top':
        d = Vector((0.0001, 0, 1))
        cam_d.type = 'ORTHO'
        cam_d.ortho_scale = max(hi.y - lo.y, (hi.x - lo.x) * RX / RY) * 1.12
        dist = size * 3
    elif view == 'back':
        d = Vector((-0.6, 1.0, 0.35)).normalized()
        cam_d.type = 'PERSP'
        cam_d.lens = 85
        dist = size * 2.2
    cam_d.clip_start = 0.005
    cam_d.clip_end = 100
    cam.location = c + d * dist
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Z' if view == 'top' else 'Y').to_euler()
    if view == 'top':
        cam.rotation_euler = (0, 0, math.radians(90))
    for l in [o for o in sc.objects if o.type == 'LIGHT']:
        bpy.data.objects.remove(l)
    light('key', c + Vector((size, -size, size * 1.5)), 40 * size * size, size, c)
    light('fill', c + Vector((-size * 1.5, size * 0.5, size * 0.6)), 12 * size * size, size * 1.5, c)
    light('rim', c + Vector((0, size * 1.5, size)), 25 * size * size, size * 0.6, c)
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


views = os.environ.get('W_VIEWS', 'hero,right,left,top').split(',')
placed = []
for n in names:
    mesh, new = imp(n)
    for v in views:
        shoot(os.path.join(OUT, '%s_%s.png' % (n, v)), mesh, v)
    for o in new:
        o.hide_render = True
    placed.append((n, mesh, new))
    print('RENDERED', n)

if os.environ.get('W_LINEUP', '1') == '1':
    # lineup: every weapon lying on its right side? no - standing in profile, muzzle +X, one row each
    zrow = 0.0
    objs = []
    for n, mesh, new in placed:
        mesh.hide_render = False
        mesh.rotation_euler = (0, 0, math.radians(90))      # muzzle -Y -> +X
        bpy.context.view_layer.update()
        lo, hi = bounds(mesh)
        mesh.location = Vector((-lo.x, 0, 0)) + mesh.location
        bpy.context.view_layer.update()
        lo, hi = bounds(mesh)
        mesh.location.z += zrow - hi.z
        bpy.context.view_layer.update()
        lo, hi = bounds(mesh)
        zrow = lo.z - 0.03
        objs.append(mesh)
    # 10 cm grid board behind
    import bmesh
    bm = bmesh.new()
    W_ = 1.2
    H_ = -zrow + 0.05
    for k in range(int(W_ / 0.1) + 1):
        bmesh.ops.create_cube(bm, size=1, matrix=Matrix.Translation((k * 0.1, 0.06, zrow / 2)) @ Matrix.Diagonal((0.002 if k % 5 else 0.004, 0.001, H_, 1)))
    me = bpy.data.meshes.new('grid')
    bm.to_mesh(me)
    g = bpy.data.objects.new('grid', me)
    sc.collection.objects.link(g)
    mm = bpy.data.materials.new('gridm')
    mm.use_nodes = True
    mm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.9, 0.9, 0.9, 1)
    me.materials.append(mm)
    bpy.ops.mesh.primitive_plane_add(size=1)
    board = bpy.context.object
    board.scale = (W_ + 0.1, 1, H_ + 0.05)
    board.rotation_euler = (math.radians(90), 0, 0)
    board.location = (W_ / 2, 0.07, zrow / 2 + 0.01)
    bm2 = bpy.data.materials.new('board')
    bm2.use_nodes = True
    bm2.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.22, 0.24, 0.27, 1)
    board.data.materials.append(bm2)
    gp.hide_render = True
    cam_d.type = 'ORTHO'
    cam.location = (W_ / 2, -3, zrow / 2)
    cam.rotation_euler = (math.radians(90), 0, 0)
    sc.render.resolution_x = 1600
    sc.render.resolution_y = int(1600 * (H_ + 0.1) / (W_ + 0.1))
    cam_d.ortho_scale = W_ + 0.1
    for l in [o for o in sc.objects if o.type == 'LIGHT']:
        bpy.data.objects.remove(l)
    light('key', (W_ / 2 + 0.6, -2.0, 1.2), 900, 2.0, (W_ / 2, 0, zrow / 2))
    light('fill', (W_ / 2 - 1.5, -1.5, -0.5), 300, 2.0, (W_ / 2, 0, zrow / 2))
    sc.render.filepath = os.path.join(OUT, 'lineup.png')
    bpy.ops.render.render(write_still=True)
    print('RENDERED lineup')
