"""Read / write the mesh_dump.gd format in Blender. Godot frame (Y up, front +Z) <-> Blender (Z up, front -Y):
blender (x, y, z) = godot (x, -z, y)."""
import json, struct
import numpy as np

STRIDE = 3 + 3 + 4 + 2 + 2


def read(prefix):
    j = json.load(open(prefix + '.json'))
    raw = open(prefix + '.bin', 'rb').read()
    nv, ni = j['verts'], j['indices']
    V = np.frombuffer(raw, dtype=np.float32, count=nv * STRIDE).reshape(nv, STRIDE).copy()
    I = np.frombuffer(raw, dtype=np.int32, count=ni, offset=nv * STRIDE * 4).copy()
    return j, V, I


def write(prefix, V, I, meta):
    open(prefix + '.bin', 'wb').write(V.astype(np.float32).tobytes() + I.astype(np.int32).tobytes())
    m = dict(meta)
    m['verts'] = int(len(V)); m['indices'] = int(len(I))
    json.dump(m, open(prefix + '.json', 'w'), indent=1)


def g2b(p):
    return (p[0], -p[2], p[1])


def b2g(p):
    return (p[0], p[2], -p[1])
