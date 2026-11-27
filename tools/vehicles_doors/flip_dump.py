"""flip_dump.py <prefix> ...: give a mesh_dump-format mesh Godot's winding (front faces clockwise) when it was written by
an older zh_build.py in Blender's (no 'winding' mark). Idempotent."""
import sys, os, json
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import meshio
for p in sys.argv[1:]:
    j, V, I = meshio.read(p)
    if j.get('winding') == 'godot':
        print('ok already', p); continue
    T = I.reshape(-1, 3)[:, [0, 2, 1]].reshape(-1)
    j['winding'] = 'godot'
    meshio.write(p, V, T, {k: v for k, v in j.items() if k not in ('verts', 'indices')})
    print('flipped', os.path.basename(p), len(T) // 3)
