import bpy, bmesh, sys, os, json, math
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kgeo, pack, kcommon
from kcommon import ROOT, SPACING

def g2b(v):
    v = np.asarray(v, float); return np.stack([v[..., 0], -v[..., 2], v[..., 1]], -1)

def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def make_obj(m, name, L, canon_only=False, owner=None, bake_only=False, offset=(0, 0, 0)):
    """m: kgeo.Mesh -> Blender object. canon_only: FB faces only; owner: dict island->kid (keep only faces whose island is owned
    by m.kid); bake_only: drop islands with bake=False. offset in glTF metres."""
    F = np.array(m.F); keep = np.ones(len(F), bool)
    ISLf = np.array([m.ISL[f[0]] for f in m.F])
    if canon_only: keep &= np.array(m.FB)
    if owner is not None: keep &= np.array([owner.get(k) == m.kid for k in ISLf])
    if bake_only: keep &= np.array([L['islands'].get(k, {}).get('bake', True) for k in ISLf])
    F = F[keep]
    if len(F) == 0: return None
    used = np.unique(F.ravel()); remap = -np.ones(len(m.V), int); remap[used] = np.arange(len(used))
    V = np.array(m.V)[used] + np.asarray(offset, float)
    me = bpy.data.meshes.new(name)
    me.from_pydata(g2b(V).tolist(), [], remap[F].tolist()); me.update()
    uvl = me.uv_layers.new(name='UVMap')
    uv = kcommon.uv_array(m, L)[used]
    lv = np.array([l.vertex_index for l in me.loops])
    uvl.data.foreach_set('uv', uv[lv].ravel())
    me.polygons.foreach_set('use_smooth', [True]*len(me.polygons))
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    return ob
