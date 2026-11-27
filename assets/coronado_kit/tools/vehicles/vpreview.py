"""blender -b -P vpreview.py -- <out_dir> <vehicle> [hi|lo]
Shape check without baking: builds the vehicle (high model by default), renders it closed from the front 3/4, rear 3/4
and the side, then with every door, the bonnet and the boot open (the cut lines and the inside)."""
import bpy, sys, os, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import vlib as vl
import wlib as w
import vmodels
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index('--') + 1:]
OUT, NAME = argv[0], argv[1]
HI = (argv[2] if len(argv) > 2 else 'hi') == 'hi'
os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
spec = vmodels.FLEET[NAME]
res = spec['build'](spec['p'], HI)
parts = {}
tris = 0
for n, obs in res['parts'].items():
    ob = w.join(obs, n)
    vl.pivot(ob, res['pivots'][n])
    parts[n] = ob
    tris += w.tris(ob)
print('PARTS', NAME, 'hi' if HI else 'lo', tris, 'tris', sorted(parts))
sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.samples = int(os.environ.get('V_SAMPLES', '24'))
sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = 900, 560
sc.view_settings.view_transform = 'AgX'
wd = bpy.data.worlds.new('W'); sc.world = wd; wd.use_nodes = True
wd.node_tree.nodes['Background'].inputs[0].default_value = (0.55, 0.58, 0.62, 1)
wd.node_tree.nodes['Background'].inputs[1].default_value = 0.7
bpy.ops.mesh.primitive_plane_add(size=60)
gm = bpy.data.materials.new('g'); gm.use_nodes = True
gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.3, 0.3, 0.31, 1)
bpy.context.object.data.materials.append(gm)
ld = bpy.data.lights.new('sun', 'SUN'); ld.energy = 3.5
lo = bpy.data.objects.new('sun', ld); sc.collection.objects.link(lo); lo.rotation_euler = (math.radians(50), 0, math.radians(35))
cd = bpy.data.cameras.new('c'); cd.lens = 50
cam = bpy.data.objects.new('c', cd); sc.collection.objects.link(cam); sc.camera = cam
# paint shows as a mid blue so the tinted areas are obvious
pm = w.MATS.get('paint')
if pm:
    for n in pm[0].node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            for l in list(n.inputs['Base Color'].links):
                pm[0].node_tree.links.remove(l)
            n.inputs['Base Color'].default_value = (0.10, 0.18, 0.35, 1)
L = max(4.0, max(abs(v) for v in res['axles']) * 2 + 1.5)


def shot(fn, d, tgt=(0, 0, 0.75), dist=None):
    d = Vector(d).normalized()
    t = Vector(tgt)
    cam.location = t + d * (dist or L * 1.45)
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = os.path.join(OUT, '%s_%s.png' % (NAME, fn))
    bpy.ops.render.render(write_still=True)


shot('front', (-0.9, -1.0, 0.45))
shot('rear', (-0.8, 1.0, 0.5))
shot('side', (1, 0.0001, 0.12))
for n, ob in parts.items():
    if n.startswith('door'):
        s = 1 if n.endswith('_l') else -1
        ob.rotation_euler.z = s * math.radians(-60)
    elif n == 'bonnet':
        ob.rotation_euler.x = math.radians(-55)
    elif n in ('boot', 'tailgate'):
        ob.rotation_euler.x = math.radians(70)
shot('open', (-1.0, -0.6, 0.6))
shot('open_r', (-0.8, 1.0, 0.7))
print('DONE')
