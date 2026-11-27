"""blender -b -P cabin_cube.py -- <cut_dir> <car> <out.png>
The parallax cabin's picture: the car's own body mesh (after the door cut) seen from the middle of its cabin box,
six 90-degree views packed 3 x 2 (+X -X +Y / -Y +Z -Z, Godot frame), each 512 px. Paint texels render as a light
grey lining (from inside, the shell is the headliner and door cards); glass is clear, so the windows across the car
read bright; trim keeps its colour. car_paint.gdshader samples it by the direction from the box centre."""
import bpy, sys, os, json, math
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import meshio
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index('--') + 1:]
CUT, CAR, OUT = argv
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
FACE = 512
# where the picture's cabin furniture goes (Godot frame: z forward, y up): front seats' hip (z, y), their x, the bench's
# z, the dash (front z, rear z) and its top
CABIN = {'sakura': dict(hip=(-0.42, 0.56), seat_x=0.38, rear_z=-1.18, dash_z=(0.55, 0.22), dash_y=1.00)}
info = json.load(open(os.path.join(CUT, CAR + '_doors.json')))
lo, hi = np.array(info['cabin']['lo']), np.array(info['cabin']['hi'])
centre = (lo + hi) / 2
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
m = bpy.data.materials.new('m'); m.use_nodes = True; nt = m.node_tree
bs = nt.nodes['Principled BSDF']
TEX = os.environ.get('CABIN_TEX') or os.path.join(ROOT, 'vehicles/models/cartex/trim_albedo.png')   # (a Zhabotinsky car: its own colour map)
tx = nt.nodes.new('ShaderNodeTexImage'); tx.image = bpy.data.images.load(TEX)
pm = nt.nodes.new('ShaderNodeMath'); pm.operation = 'GREATER_THAN'; pm.inputs[1].default_value = 0.75
nt.links.new(tx.outputs['Alpha'], pm.inputs[0])
mx = nt.nodes.new('ShaderNodeMix'); mx.data_type = 'RGBA'
nt.links.new(pm.outputs[0], mx.inputs[0]); nt.links.new(tx.outputs[0], mx.inputs[6]); mx.inputs[7].default_value = (0.42, 0.40, 0.37, 1)
geo = nt.nodes.new('ShaderNodeNewGeometry')
mx2 = nt.nodes.new('ShaderNodeMix'); mx2.data_type = 'RGBA'
nt.links.new(geo.outputs['Backfacing'], mx2.inputs[0]); nt.links.new(mx.outputs[2], mx2.inputs[6]); mx2.inputs[7].default_value = (0.20, 0.19, 0.18, 1)
nt.links.new(mx2.outputs[2], bs.inputs['Base Color'])
bs.inputs['Roughness'].default_value = 0.8
# glass (alpha 0.3 .. 0.75): fully clear
g1 = nt.nodes.new('ShaderNodeMath'); g1.operation = 'GREATER_THAN'; g1.inputs[1].default_value = 0.3
g2 = nt.nodes.new('ShaderNodeMath'); g2.operation = 'LESS_THAN'; g2.inputs[1].default_value = 0.75
nt.links.new(tx.outputs['Alpha'], g1.inputs[0]); nt.links.new(tx.outputs['Alpha'], g2.inputs[0])
gm = nt.nodes.new('ShaderNodeMath'); gm.operation = 'MULTIPLY'
nt.links.new(g1.outputs[0], gm.inputs[0]); nt.links.new(g2.outputs[0], gm.inputs[1])
inv = nt.nodes.new('ShaderNodeMath'); inv.operation = 'SUBTRACT'; inv.inputs[0].default_value = 1.0
nt.links.new(gm.outputs[0], inv.inputs[1]); nt.links.new(inv.outputs[0], bs.inputs['Alpha'])
for name in (CAR + '_body', CAR + '_door_l', CAR + '_door_r'):
    j, V, I = meshio.read(os.path.join(CUT, name))
    if 'door' in name:
        V = V.copy(); V[:, 0:3] += np.array(info['doors'][name[-1]]['hinge'])
    me = bpy.data.meshes.new(name)
    me.from_pydata([meshio.g2b(v[0:3]) for v in V], [], [tuple(I[k:k + 3]) for k in range(0, len(I), 3)])
    uv = me.uv_layers.new(name='UV')
    for li, l in enumerate(me.loops):
        uv.data[li].uv = (V[l.vertex_index][10], 1 - V[l.vertex_index][11])
    me.materials.append(m)
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
# the cabin that is not there: seats, dash, steering wheel, floor (the scrapped fleet's interior pieces), in the picture only
sys.path.insert(0, os.path.join(ROOT, 'assets/coronado_kit/tools/vehicles'))
import vlib as vl
from vlib import box, extrude
C = CABIN.get(CAR)
B = lambda x, y, z: meshio.g2b((x, y, z))
if C is None:     # a car with a modelled cabin: the picture is of that cabin, nothing added
    C = dict(hip=None)
hip = C['hip']
for s_ in ((1, -1) if hip else ()):
    x, y, z = B(s_ * C['seat_x'], hip[1], hip[0])
    vl.seat('seat', (x, y, z), 0.50, True, back_h=0.55)
if hip:
  x, y, z = B(0, hip[1] + 0.03, C['rear_z'])
  vl.seat('bench', (x, y, z), 1.30, True, bench=True, back_h=0.50)
if hip:
  d0, d1 = C['dash_z']
  dash = extrude('dash', [(-d1, C['dash_y'] - 0.02), (-d0, C['dash_y'] + 0.03), (-d0 + 0.12, C['dash_y'] - 0.08),
                          (-d0 + 0.10, C['dash_y'] - 0.35), (-d1, C['dash_y'] - 0.40)], -0.74, 0.74, 'int_plastic')
  vl.steering_wheel('sw', Vector(B(C['seat_x'], hip[1] + 0.42, hip[0] + 0.42)), math.radians(-25), 0.18, True)
  fl = box('floor', (-0.75, -0.6, 0.355), (0.75, 1.3, 0.365), 'int_carpet')
  cons = box('console', (-0.09, -(C['dash_z'][0] - 0.15), hip[1] - 0.20), (0.09, -(hip[0] + 0.15), hip[1] + 0.02), 'int_plastic')
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.samples = 64; sc.cycles.use_denoising = True
sc.cycles.transparent_max_bounces = 8
sc.render.resolution_x = sc.render.resolution_y = FACE
sc.view_settings.view_transform = 'Standard'
sc.view_settings.exposure = -0.3
wd = bpy.data.worlds.new('W'); sc.world = wd; wd.use_nodes = True
wd.node_tree.nodes['Background'].inputs[0].default_value = (0.78, 0.82, 0.88, 1)
wd.node_tree.nodes['Background'].inputs[1].default_value = 1.6
ld = bpy.data.lights.new('dome', 'POINT'); ld.energy = 25; ld.shadow_soft_size = 0.4
lo_ = bpy.data.objects.new('dome', ld); sc.collection.objects.link(lo_)
lo_.location = meshio.g2b(centre + np.array([0, 0.25, 0]))
cd = bpy.data.cameras.new('c'); cd.type = 'PERSP'; cd.angle = math.radians(90); cd.clip_start = 0.01
cam = bpy.data.objects.new('c', cd); sc.collection.objects.link(cam); sc.camera = cam
cam.location = meshio.g2b(centre)
# faces in the Godot frame: forward f, up u (image right = f x u); the shader uses the same table
FACES = [((1, 0, 0), (0, 1, 0)), ((-1, 0, 0), (0, 1, 0)), ((0, 1, 0), (0, 0, -1)),
         ((0, -1, 0), (0, 0, 1)), ((0, 0, 1), (0, 1, 0)), ((0, 0, -1), (0, 1, 0))]
for i, (f, u) in enumerate(FACES):
    fb, ub = Vector(meshio.g2b(f)), Vector(meshio.g2b(u))
    rb = fb.cross(ub)
    # camera looks down its -Z with +Y up: columns = (right, up, -forward)
    R = Matrix((rb, ub, -fb)).transposed()
    cam.matrix_world = Matrix.Translation(cam.location) @ R.to_4x4()
    p = os.path.join(os.path.dirname(OUT), '_face%d.png' % i)
    sc.render.filepath = p
    bpy.ops.render.render(write_still=True)
import subprocess
r = subprocess.run(['python3', '-c', 'import sys; from PIL import Image; F=%d; A=Image.new("RGB",(F*3,F*2))\nfor i in range(6): A.paste(Image.open(sys.argv[1]+"/_face%%d.png"%%i).convert("RGB"),((i%%3)*F,(i//3)*F))\nA.save(sys.argv[2])' % FACE,
                    os.path.dirname(OUT), OUT], capture_output=True, text=True)
print(r.stderr)
print('CUBE', OUT, 'centre', centre.round(3).tolist())
