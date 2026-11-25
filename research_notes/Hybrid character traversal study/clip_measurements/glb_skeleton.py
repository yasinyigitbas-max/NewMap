import sys, json, struct, numpy as np
def load(p):
    d = open(p, 'rb').read(); n = struct.unpack_from('<I', d, 12)[0]
    return json.loads(d[20:20+n])
def quat(q):
    x, y, z, w = q
    return np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)], [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)], [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]])
def skel(p):
    g = load(p); N = g['nodes']; par = {}
    for i, n in enumerate(N):
        for c in n.get('children', []): par[c] = i
    W = {}
    def w(i):
        if i in W: return W[i]
        n = N[i]
        if 'matrix' in n: M = np.array(n['matrix']).reshape(4, 4).T
        else:
            M = np.eye(4); M[:3,:3] = quat(n.get('rotation', [0,0,0,1])) * np.array(n.get('scale', [1,1,1])); M[:3,3] = n.get('translation', [0,0,0])
        W[i] = (w(par[i]) @ M) if i in par else M
        return W[i]
    joints = g['skins'][0]['joints'] if g.get('skins') else []
    out = {N[j].get('name', str(j)): (N[par[j]].get('name') if j in par else None, w(j)[:3,3]) for j in joints}
    return g, out
if __name__ == '__main__':
    g, sk = skel(sys.argv[1])
    print(sys.argv[1].split('/')[-1], '| joints', len(sk), '| meshes', len(g.get('meshes', [])), '| animations', [(a.get('name'), len(a['channels'])) for a in g.get('animations', [])][:8], '| materials', len(g.get('materials', [])))
    tris = sum(g['accessors'][p['indices']]['count']//3 for m in g.get('meshes', []) for p in m['primitives'] if 'indices' in p)
    ys = [g['accessors'][p['attributes']['POSITION']] for m in g['meshes'] for p in m['primitives']]
    print('triangles', tris, '| mesh bounds min', [a['min'] for a in ys][:2], 'max', [a['max'] for a in ys][:2])
    for k, (p, v) in sk.items(): print('  %-22s < %-18s (%.3f, %.3f, %.3f)' % (k, p, *v))
