"""GLB -> FBX for Cascadeur (Blender's own importer / exporter, bpy).
   python3 tools/people/humanoid/to_fbx.py IN_DIR OUT_DIR   (every .glb under IN_DIR, the same folders under OUT_DIR)
Needs bpy (here: /home/user/mpfb/bpylib on sys.path)."""
import os, sys
sys.path.insert(0, '/home/user/mpfb/bpylib')
import bpy
src, dst = sys.argv[1], sys.argv[2]
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
