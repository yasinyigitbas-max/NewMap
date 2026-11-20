"""Export per kiosk: near / mid / far (one mesh, one material) + col (boxes). Materials rewritten by kfix_glb.py."""
import bpy, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kbl_common import *
OUT = ROOT + '/glb'; os.makedirs(OUT, exist_ok=True)
def export(path, objs):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    kw = dict(filepath=path, export_format='GLB', use_selection=True, export_yup=True, export_apply=True, export_texcoords=True,
              export_normals=True, export_tangents=True, export_materials='EXPORT', export_cameras=False, export_lights=False,
              export_animations=False, export_skins=False, export_morph=False, export_extras=False)
    try: bpy.ops.export_scene.gltf(**kw, export_vertex_color='NONE')
    except TypeError: bpy.ops.export_scene.gltf(**kw, export_colors=False)
L = json.load(open(ROOT+'/work/layout.json'))
only = os.environ.get('ONLY')
for mod in kcommon.mods():
    if only and mod.KID not in only.split(','): continue
    for lod in ('near', 'mid', 'far'):
        clear()
        ob = make_obj(kcommon.build(mod, lod), f'{mod.NAME}_{lod}', L)
        ob.data.materials.append(bpy.data.materials.new('kiosks' if lod == 'near' else 'kiosks_lod'))
        export(f'{OUT}/{mod.NAME}_{lod}.glb', [ob])
    clear()
    m = kcommon.build(mod, 'near'); vb = []; faces = []
    for (c, s) in m.col:
        c = np.asarray(c, float); h = np.asarray(s, float)/2; b = len(vb)
        for x in (-1, 1):
            for y in (-1, 1):
                for z in (-1, 1): vb.append(tuple(g2b(c + h*np.array([x, y, z])).tolist()))
        faces += [(b+0, b+1, b+3, b+2), (b+4, b+6, b+7, b+5), (b+0, b+4, b+5, b+1), (b+2, b+3, b+7, b+6), (b+0, b+2, b+6, b+4), (b+1, b+5, b+7, b+3)]
    me = bpy.data.meshes.new('col'); me.from_pydata(vb, [], faces); me.update()
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bmesh.ops.triangulate(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    co = bpy.data.objects.new('col', me); bpy.context.scene.collection.objects.link(co)
    export(f'{OUT}/{mod.NAME}_col.glb', [co])
    print('exported', mod.NAME)
print('EXPORT DONE')
