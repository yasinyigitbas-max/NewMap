"""RE-RIG a Meshy body: its joints moved to where the anatomy is (Yasin 23 Nov: "rerig"). Meshy's auto-rig ran his spine,
hips and head joints along his back (69-74 % of the body's depth from the front, the x-ray showed it); a body turning
about joints at its back bends wrong in every move. Each listed joint is moved, front to back only, to a share of the
body's depth measured at its height from the mesh (the front: -y in Blender, his face's way); the legs' knee and ankle
to their own section's middle; the shoulders / elbows / wrists left (each already at its arm section's middle).
The skin keeps Meshy's weights and our finger bones; it is bound again at the new joints (the export writes the new
rest). Run:
  PYTHONPATH=<bpy dir> python3 -I tools/people/meshy/rerig.py IN.glb OUT.glb"""
import sys
sys.path.insert(0, '/home/user/mpfb/bpylib')
import bpy

# the share of the body's depth from the front where each joint belongs (anatomy: the hip joints near the middle, the
# lumbar spine a little behind it, the thoracic spine further back, the neck and the skull's joint near the middle)
TARGET = {'Hips': 0.55, 'LeftUpLeg': 0.55, 'RightUpLeg': 0.55, 'Spine02': 0.62, 'Spine01': 0.62, 'Spine': 0.60,
          'neck': 0.55, 'Head': 0.58}
LEG_SECTION = []   # (knees and ankles left: at the ankle the section is the whole shoe, heel to toe - its middle is not the joint; the x-ray showed the legs right)


def main(src, out):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    mesh = next(o for o in bpy.data.objects if o.type == 'MESH')
    dg = bpy.context.evaluated_depsgraph_get()
    V = [mesh.matrix_world @ v.co for v in mesh.evaluated_get(dg).to_mesh().vertices]
    inv = arm.matrix_world.inverted()

    def depth(z, x0, xlim):
        ys = [v.y for v in V if abs(v.z - z) < 0.015 and abs(v.x - x0) < xlim]
        return (min(ys), max(ys)) if ys else None

    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm.data.edit_bones
    moves = {}
    for name, share in TARGET.items():
        b = eb.get(name)
        if not b: continue
        h = arm.matrix_world @ b.head
        x0 = h.x if 'UpLeg' in name else 0.0
        xlim = 0.09 if 'UpLeg' in name else (0.12 if name in ('neck', 'Head') else 0.16)
        d = depth(h.z, x0, xlim)
        if not d: continue
        moves[name] = (d[0] + share * (d[1] - d[0])) - h.y
    for name in LEG_SECTION:
        b = eb.get(name)
        if not b: continue
        h = arm.matrix_world @ b.head
        d = depth(h.z, h.x, 0.08)
        if d: moves[name] = (d[0] + d[1]) * 0.5 - h.y
    # move the heads (world y), keeping each moved bone's connected parent's tail on it; a bone's own tail moves with its
    # head unless a child is moved to it (then it follows the child)
    for name, dy in moves.items():
        b = eb[name]
        wh = arm.matrix_world @ b.head
        wh.y += dy
        b.head = inv @ wh
        print("MOVED %-10s %+.1f cm" % (name, dy * 100))
    for b in eb:
        kids = [c for c in b.children if c.name in moves]
        if b.name in moves and not kids and not b.children:
            pass
        # (a bone's tail on its first moved child's head, if it pointed at that child before)
        for c in b.children:
            if c.use_connect: b.tail = c.head
    for b in eb:
        if b.name in moves and len(b.children) == 1 and b.children[0].name not in moves:
            pass
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_animations=False)
    print("RERIG written", out)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
