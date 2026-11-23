# Rig a Meshy character with Mixamo's own skeleton (65 bones, fingers) by fitting it in Blender, then play Mixamo
# clips on it. Used because Mixamo's auto-rigger API refused our calls (23 Nov).
#   <venv with bpy 4.2>/bin/python tools/people/meshy/fit_mixamo_rig.py MESH.glb JOINTS.json OUT.glb CLIP.fbx ...
# JOINTS.json: joint centres measured on the mesh, metres, Blender axes (z up, facing -y), left side (+x); the right
# side is mirrored. Keys: hip, knee, ankle, toe, toe_end, shoulder, elbow, wrist, hand_tip.
# How the clips are carried over: each of our bones copies the WORLD rotation of the same Mixamo bone. Our bones are
# the Mixamo bones moved onto this body (their axes turned by the smallest rotation), so a limb points exactly where
# the clip's limb points, whatever pose the mesh was made in (Meshy's A-pose). The hips copy the clip's hips position
# (shifted by the difference in hip height).
import bpy, sys, json, math
from mathutils import Vector, Matrix

args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[4:]
MESH, JOINTS, OUT, CLIPS = args[0], args[1], args[2], args[3:]
J = {k: Vector(v) for k, v in json.load(open(JOINTS)).items()}

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=MESH)
mesh = [o for o in bpy.context.selected_objects if o.type == 'MESH'][0]
for o in list(bpy.data.objects):
    if o.type != 'MESH': bpy.data.objects.remove(o)


def import_clip(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path, automatic_bone_orientation=False)
    arm = [o for o in set(bpy.data.objects) - before if o.type == 'ARMATURE'][0]
    return arm


src0 = import_clip(CLIPS[0])
rig = src0.copy(); rig.data = src0.data.copy(); rig.animation_data_clear(); rig.name = 'Armature'
bpy.context.scene.collection.objects.link(rig)
for b in rig.pose.bones:
    b.location = (0, 0, 0); b.rotation_quaternion = (1, 0, 0, 0); b.rotation_euler = (0, 0, 0); b.scale = (1, 1, 1)

inv = rig.matrix_world.inverted()   # world -> armature space (the clips' armature has scale 0.01, rot 90 about x)
mw = rig.matrix_world

bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
eb = rig.data.edit_bones
P = 'mixamorig:'


def W(v): return mw @ v
def A(v): return inv @ v


def mirror(v, side): return Vector((v.x * side, v.y, v.z))


# Snapshot every bone first, then disconnect them all: moving a connected bone's tail drags its child's head along,
# which put the fingers inside the body on the first try.
ORIG = {b.name: (W(b.head), W(b.tail), (mw.to_3x3() @ b.z_axis).normalized()) for b in eb}
for b in eb: b.use_connect = False


def place_chain(names, targets):
    """Move bones so bone i runs targets[i] -> targets[i+1]; axes turned by the smallest rotation. Returns the
    rotation of the last bone (world) and its old head (world), for carrying children rigidly."""
    last = None
    for i, n in enumerate(names):
        b = eb[P + n]
        oh, ot, oz = ORIG[P + n]
        nh, nt = targets[i], targets[i + 1]
        R = (ot - oh).normalized().rotation_difference((nt - nh).normalized())
        b.use_connect = False
        b.head = A(nh); b.tail = A(nt)
        b.align_roll(mw.to_3x3().inverted() @ (R @ oz))
        last = (R, oh, nh, (ot - oh).length, (nt - nh).length)
    return last


def carry(names, R, pivot_old, pivot_new, s):
    """Move child bones rigidly with their parent: rotate R about the old pivot, scale s, put on the new pivot."""
    for n in names:
        b = eb[P + n]
        oh, ot, oz = ORIG[P + n]
        b.head = A(pivot_new + (R @ (oh - pivot_old)) * s)
        b.tail = A(pivot_new + (R @ (ot - pivot_old)) * s)
        b.align_roll(mw.to_3x3().inverted() @ (R @ oz))


for side, S in ((1, 'Left'), (-1, 'Right')):
    m = lambda k: mirror(J[k], side)
    # arm: shoulder bone ends at the arm's root; fingers follow the hand
    sh = eb[P + S + 'Shoulder']; sh.use_connect = False; sh.tail = A(m('shoulder'))
    R, oh, nh, ol, nl = place_chain([S + 'Arm', S + 'ForeArm', S + 'Hand'], [m('shoulder'), m('elbow'), m('wrist'), m('wrist') + (m('hand_tip') - m('wrist')) * 0.42])
    hand = eb[P + S + 'Hand']
    fingers = [b.name[len(P):] for b in eb if b.name.startswith(P + S + 'Hand') and b.name != P + S + 'Hand']
    # fingers: rotate with the hand about the wrist, scaled to this hand's length
    s = (m('hand_tip') - m('wrist')).length / 0.221
    carry(fingers, R, oh, nh, s)
    # leg
    R, oh, nh, ol, nl = place_chain([S + 'UpLeg', S + 'Leg', S + 'Foot', S + 'ToeBase'], [m('hip'), m('knee'), m('ankle'), m('toe'), m('toe_end')])
    if (P + S + 'Toe_End') in eb:
        carry([S + 'Toe_End'], R, oh, nh, 1.0)

bpy.ops.object.mode_set(mode='OBJECT')

# hips height difference, for the clips' root motion
hips_src = (src0.matrix_world @ src0.data.bones[P + 'Hips'].head_local)
hips_ours = (mw @ rig.data.bones[P + 'Hips'].head_local)
leg_ratio = ((J['hip'] - J['ankle']).length) / ((src0.matrix_world @ src0.data.bones[P + 'LeftUpLeg'].head_local) - (src0.matrix_world @ src0.data.bones[P + 'LeftFoot'].head_local)).length
print('leg ratio', round(leg_ratio, 3))

# bind with automatic (heat) weights. Heat weighting fails on a mesh split at its UV seams (glTF splits vertices
# there) and on the clips' 0.01 armature scale: weld the seams (UVs are kept per corner) and apply the scale first.
bpy.ops.object.select_all(action='DESELECT')
bpy.context.view_layer.objects.active = mesh; mesh.select_set(True)
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.0001); bpy.ops.object.mode_set(mode='OBJECT')
mesh.select_set(False)
bpy.context.view_layer.objects.active = rig; rig.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
mw = rig.matrix_world
hips_ours = (mw @ rig.data.bones[P + 'Hips'].head_local)
bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True); rig.select_set(True); bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
unweighted = sum(1 for v in mesh.data.vertices if not any(g.weight > 0 for g in v.groups))
print('vertices without weights', unweighted, 'of', len(mesh.data.vertices))
import os, collections
if os.environ.get('RIGDEBUG'):
    names = {g.index: g.name for g in mesh.vertex_groups}
    for lo, hi, xm in ((1.0, 1.3, 0.1), (0.6, 0.85, 0.3), (0.3, 0.6, 0.3)):
        cnt = collections.Counter()
        for v in mesh.data.vertices:
            co = mesh.matrix_world @ v.co
            if lo < co.z < hi and abs(co.x) < xm and v.groups:
                cnt[names[max(v.groups, key=lambda g: g.weight).group]] += 1
        print('DEBUG z', lo, hi, cnt.most_common(6))
    print('DEBUG mesh mw', mesh.matrix_world.to_translation(), mesh.dimensions, 'parent', mesh.parent)
    [print('DEBUG bone', b.name, [round(c,3) for c in rig.matrix_world @ b.head_local], [round(c,3) for c in rig.matrix_world @ b.tail_local]) for b in rig.data.bones if any(k in b.name for k in ('LeftHand','LeftForeArm','LeftArm'))]
    print('DEBUG hips', rig.matrix_world @ rig.data.bones[P + 'Hips'].head_local, 'spine2', rig.matrix_world @ rig.data.bones[P + 'Spine2'].head_local)
    sys.exit(0)

# clips
for path in CLIPS:
    name = path.rsplit('/', 1)[-1].rsplit('.', 1)[0]
    src = import_clip(path)
    sc = bpy.context.scene
    act = src.animation_data.action
    f0, f1 = [int(round(f)) for f in act.frame_range]
    for pb in rig.pose.bones:
        for c in list(pb.constraints): pb.constraints.remove(c)
        c = pb.constraints.new('COPY_ROTATION'); c.target = src; c.subtarget = pb.name
        c.target_space = 'WORLD'; c.owner_space = 'WORLD'
    hp = rig.pose.bones[P + 'Hips']
    c = hp.constraints.new('COPY_LOCATION'); c.target = src; c.subtarget = P + 'Hips'
    c.target_space = 'WORLD'; c.owner_space = 'WORLD'
    # shift the source so its hips sit at our hip height (rotations are unaffected)
    src.location.z += (hips_ours.z - hips_src.z)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode='POSE'); bpy.ops.pose.select_all(action='SELECT')
    rig.animation_data_create()
    bpy.ops.nla.bake(frame_start=f0, frame_end=f1, only_selected=True, visual_keying=True, clear_constraints=True,
                     use_current_action=False, bake_types={'POSE'})
    bpy.ops.object.mode_set(mode='OBJECT')
    baked = rig.animation_data.action; baked.name = name
    tr = rig.animation_data.nla_tracks.new(); tr.name = name
    tr.strips.new(name, int(baked.frame_range[0]), baked)
    rig.animation_data.action = None
    bpy.data.objects.remove(src)
    print('clip', name, f0, f1)

for o in list(bpy.data.objects):
    if o not in (rig, mesh): bpy.data.objects.remove(o)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', export_animation_mode='NLA_TRACKS',
                          export_image_format='JPEG', export_jpeg_quality=92, export_force_sampling=True)
print('EXPORTED', OUT)
