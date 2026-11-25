# Kimodo's Mixamo FBX export keeps the uploaded character's own animation on a second layer.
# Keep only the layer Kimodo wrote ("BaseLayer"), start the clip at the origin. Usage: clean_kimodo.py in.fbx out.fbx
import sys, os, copy
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fbxrw
def clean(src, dst):
    doc = fbxrw.read(src)
    objs = [n for n in doc['top'] if n[0] == b'Objects'][0]; conns = [n for n in doc['top'] if n[0] == b'Connections'][0]
    ids = {k[1][0][1]: k for k in objs[2]}
    nm = lambda k: k[1][1][1].split(b'\0')[0]
    layers = [i for i, k in ids.items() if k[0] == b'AnimationLayer']
    stack = [i for i, k in ids.items() if k[0] == b'AnimationStack'][0]
    C = [c[1] for c in conns[2]]
    on = {}   # curve node -> layer
    for a in C:
        if a[0][1] == b'OO' and ids.get(a[1][1], [b''])[0] == b'AnimationCurveNode' and a[2][1] in layers: on[a[1][1]] = a[2][1]
    count = {l: sum(1 for v in on.values() if v == l) for l in layers}
    keep = [l for l in layers if nm(ids[l]) == b'BaseLayer' and count[l] > 0]
    assert len(keep) == 1, {nm(ids[l]): count[l] for l in layers}
    keep = keep[0]
    drop = set(l for l in layers if l != keep) | set(n for n, l in on.items() if l != keep)
    for a in C:
        if a[0][1] == b'OP' and a[2][1] in drop and ids.get(a[1][1], [b''])[0] == b'AnimationCurve': drop.add(a[1][1])
    objs[2][:] = [k for k in objs[2] if k[1][0][1] not in drop]
    conns[2][:] = [c for c in conns[2] if c[1][1][1] not in drop and c[1][2][1] not in drop]
    if not any(c[1][0][1] == b'OO' and c[1][1][1] == keep and c[1][2][1] == stack for c in conns[2]):
        t = copy.deepcopy([c for c in conns[2] if c[1][0][1] == b'OO'][0])
        t[1][1] = (t[1][1][0], keep); t[1][2] = (t[1][2][0], stack); conns[2].append(t)
    # start at the origin on the ground plane
    hips = [i for i, k in ids.items() if k[0] == b'Model' and nm(k).endswith(b'Hips')][0]
    cn = [c[1][1][1] for c in conns[2] if c[1][0][1] == b'OP' and c[1][2][1] == hips and c[1][3][1] == b'Lcl Translation'][0]
    for c in conns[2]:
        if c[1][0][1] == b'OP' and c[1][2][1] == cn and c[1][3][1] in (b'd|X', b'd|Z'):
            kv = fbxrw.child(ids[c[1][1][1]], b'KeyValueFloat')[0]; v = kv[1][0][1]
            kv[1][0] = (kv[1][0][0], [x - v[0] for x in v])
    fbxrw.write(doc, dst)
    return dict(layers={nm(ids[l]).decode(): count[l] for l in layers}, removed=len(drop))
if __name__ == '__main__':
    print(clean(sys.argv[1], sys.argv[2]))
