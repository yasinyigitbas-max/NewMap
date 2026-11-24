"""GLB -> FBX for Cascadeur (Blender's own importer / exporter, bpy).
   python3 tools/people/humanoid/to_fbx.py IN_DIR OUT_DIR   (every .glb under IN_DIR, the same folders under OUT_DIR)
Needs bpy (here: /home/user/mpfb/bpylib on sys.path)."""
import os, sys
sys.path.insert(0, '/home/user/mpfb/bpylib')
import bpy
src, dst = sys.argv[1], sys.argv[2]
# MIXAMO NAMES (Yasin, 24 Nov, Cascadeur's Quick Rigging Tool: "select(): incompatible function arguments ... {None}" - it
# does not know Godot's humanoid names, its body-part slots stayed empty). With Mixamo's it recognises him by itself, and
# his Mixamo downloads go onto him by name. The way back maps them home (tools/people/humanoid, the import of edits).
def mixamo(n):
    m = {'Hips': 'Hips', 'Spine': 'Spine', 'Chest': 'Spine1', 'UpperChest': 'Spine2', 'Neck': 'Neck', 'Head': 'Head'}
    if n in m: return 'mixamorig:' + m[n]
    for side in ('Left', 'Right'):
        if not n.startswith(side): continue
        r = n[len(side):]
        limb = {'Shoulder': 'Shoulder', 'UpperArm': 'Arm', 'LowerArm': 'ForeArm', 'Hand': 'Hand', 'UpperLeg': 'UpLeg',
                'LowerLeg': 'Leg', 'Foot': 'Foot', 'Toes': 'ToeBase'}
        if r in limb: return 'mixamorig:' + side + limb[r]
        for f, mf in (('Thumb', 'Thumb'), ('Index', 'Index'), ('Middle', 'Middle'), ('Ring', 'Ring'), ('Little', 'Pinky')):
            if r.startswith(f):
                ph = r[len(f):]
                k = {'Metacarpal': 1, 'Proximal': 2, 'Distal': 3} if f == 'Thumb' else {'Proximal': 1, 'Intermediate': 2, 'Distal': 3}
                if ph in k: return 'mixamorig:%sHand%s%d' % (side, mf, k[ph])
    return None
RENAME = os.environ.get('KEEP_NAMES', '') == ''
files = []
for r, _, fs in os.walk(src):
    for f in fs:
        if f.endswith('.glb'): files.append(os.path.join(r, f))
files.sort()
done = 0
for f in files:
    out = os.path.join(dst, os.path.relpath(f, src))[:-4] + '.fbx'
    if os.path.exists(out): done += 1; continue
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene; sc.render.fps = 30; sc.render.fps_base = 1.0   # (the game's clips: 30 a second)
    bpy.ops.import_scene.gltf(filepath=f)
    acts = list(bpy.data.actions)
    if acts:   # (the clip's own length, not the scene's default 250 frames)
        a0, a1 = acts[0].frame_range
        sc.frame_start, sc.frame_end = int(round(a0)), max(int(round(a1)), int(round(a0)) + 1)
    if RENAME:
        for o in bpy.data.objects:
            if o.type != 'ARMATURE': continue
            for b in o.data.bones:
                nn = mixamo(b.name)
                if nn: b.name = nn   # (Blender renames the action's curves with the bone)
    model = f.endswith('his_model.glb')
    if not model:   # (the body came along only to make the bones a skeleton: out of the animation files)
        for o in [o for o in bpy.data.objects if o.type == 'MESH']: bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.export_scene.fbx(filepath=out, use_selection=False, add_leaf_bones=False, bake_anim=not model,
                             bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False, bake_anim_simplify_factor=0.0,
                             path_mode='COPY', embed_textures=model, object_types={'ARMATURE', 'MESH'} if model else {'ARMATURE'},
                             armature_nodetype='NULL', primary_bone_axis='Y', secondary_bone_axis='X')
    done += 1
    if done % 50 == 0: print('FBX', done, '/', len(files), flush=True)
print('FBX done', done, 'of', len(files))
