# Add finger bones to a Meshy auto-rig (it has none: 24 bones). Mesh, texture and the other bones stay as Meshy made
# them; only the hand's skin weight is shared out between the hand and the new finger bones (inverse distance to each
# bone, power 4). Measured for the first Meshy player (T-pose, palm down, thumb to the front = -y in Blender).
#   <venv with bpy 4.2>/bin/python tools/people/meshy/add_fingers.py IN.glb HAND.json OUT.glb
# HAND.json (left hand, metres along the arm from the wrist / Blender y / z): knuckle, fingers{name: [y, z, length]},
# thumb[[along, y, z] x 4 joints]. The right hand is mirrored.
import bpy, sys, json
from mathutils import Vector
from mathutils.geometry import intersect_point_line

a = sys.argv[sys.argv.index('--') + 1:]
IN, HAND, OUT = a[0], a[1], a[2]
H = json.load(open(HAND))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=IN)
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
mesh = [o for o in bpy.data.objects if o.type == 'MESH'][0]
mw = arm.matrix_world; inv = mw.inverted()

new = {}   # bone name -> (head world, tail world, side)
for side, S in ((1, 'Left'), (-1, 'Right')):
    w = mw @ arm.data.bones[S + 'Hand'].head_local
    P = lambda along, y, z: Vector((w.x + side * along, y, z))
    k = H['knuckle']
    for fname, (y, z, length) in H['fingers'].items():
        pts = [P(k, y, z)]
        for f in (0.45, 0.75, 1.0): pts.append(P(k + length * f, y, z))
        for i in range(3): new[f'{S}Hand{fname}{i + 1}'] = (pts[i], pts[i + 1], S)
    t = [P(*j) for j in H['thumb']]
    for i in range(3): new[f'{S}HandThumb{i + 1}'] = (t[i], t[i + 1], S)

bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
eb = arm.data.edit_bones
for n, (h, t, S) in new.items():
    b = eb.new(n)
    b.head = inv @ h; b.tail = inv @ t
    b.align_roll(inv.to_3x3() @ Vector((0, 0, 1)))
    i = int(n[-1])
    b.parent = eb[S + 'Hand'] if i == 1 else eb[n[:-1] + str(i - 1)]
    b.use_connect = i > 1
bpy.ops.object.mode_set(mode='OBJECT')

# share the hand weight out
for S in ('Left', 'Right'):
    hg = mesh.vertex_groups[S + 'Hand']
    wrist = mw @ arm.data.bones[S + 'Hand'].head_local
    mids = [v for n, v in new.items() if n.endswith('1') and v[2] == S and 'Thumb' not in n]
    knuck = sum((v[0] for v in mids), Vector()) / len(mids)
    segs = {S + 'Hand': (wrist, knuck)}
    segs.update({n: (v[0], v[1]) for n, v in new.items() if v[2] == S})
    groups = {n: (mesh.vertex_groups.get(n) or mesh.vertex_groups.new(name=n)) for n in segs}
    moved = 0
    for v in mesh.data.vertices:
        wh = next((g.weight for g in v.groups if g.group == hg.index), 0.0)
        if wh <= 0: continue
        co = mesh.matrix_world @ v.co
        ws = {}
        for n, (p0, p1) in segs.items():
            q, f = intersect_point_line(co, p0, p1)
            q = p0 if f < 0 else (p1 if f > 1 else q)
            ws[n] = 1.0 / max((co - q).length, 0.004) ** 4
        tot = sum(ws.values())
        for n, x in ws.items():
            groups[n].add([v.index], wh * x / tot, 'REPLACE')
        moved += 1
    print(S, 'hand vertices shared out', moved)

bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', export_animations=False,
                          export_image_format='AUTO')
print('WROTE', OUT, len(arm.data.bones), 'bones')
