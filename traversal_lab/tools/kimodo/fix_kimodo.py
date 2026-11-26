# Put a Kimodo-exported Mixamo FBX back on the ground, using Kimodo's own NPZ for the true foot height,
# and start it at the origin. Usage: fix_kimodo.py in.fbx in.npz out.fbx
import sys, os, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fbxrw
from measure import measure
def slide(t, P):
    out = []
    for s in ('Left', 'Right'):
        toe = P[s + 'ToeBase']; v = np.hypot(np.diff(toe[:,0]), np.diff(toe[:,2])) / np.diff(t)
        m = (toe[1:,1] < toe[:,1].min() + 0.03)
        if m.any(): out.append(v[m].mean())
    return float(np.mean(out)) if out else 0.0
def fix(src, npz, dst):
    t, P, yaw, meta = measure(src)
    low_f = np.min(np.stack([p[:,1] for p in P.values()]), 0)
    J = np.load(npz)['posed_joints']; low_n = np.maximum(J[:,:,1].min(1), 0.0)
    # Kimodo's own skeleton: joint 0 is the pelvis, 67-69 the left hip, knee, ankle
    soma_leg = np.linalg.norm(J[0,67]-J[0,68]) + np.linalg.norm(J[0,68]-J[0,69])
    my_leg = np.linalg.norm(P['LeftUpLeg'][0]-P['LeftLeg'][0]) + np.linalg.norm(P['LeftLeg'][0]-P['LeftFoot'][0])
    sc = my_leg / soma_leg
    xz = {'X': (J[:,0,0]-J[0,0,0]) * sc * 100.0, 'Z': (J[:,0,2]-J[0,0,2]) * sc * 100.0}
    n = min(len(low_f), len(low_n)); assert abs(len(low_f) - len(low_n)) <= 1, (len(low_f), len(low_n))
    dy = np.zeros(len(low_f)); dy[:n] = low_f[:n] - low_n[:n]; dy[n:] = dy[n-1]
    doc = fbxrw.read(src)
    objs = [n_ for n_ in doc['top'] if n_[0] == b'Objects'][0]; conns = [n_ for n_ in doc['top'] if n_[0] == b'Connections'][0]
    ids = {k[1][0][1]: k for k in objs[2]}
    hips = [i for i, k in ids.items() if k[0] == b'Model' and k[1][1][1].split(b'\0')[0].endswith(b'Hips')][0]
    cn = [c[1][1][1] for c in conns[2] if c[1][0][1] == b'OP' and c[1][2][1] == hips and c[1][3][1] == b'Lcl Translation'][0]
    done = set()
    for c in conns[2]:
        if c[1][0][1] == b'OP' and c[1][2][1] == cn:
            ax = c[1][3][1][-1:].decode(); cur = ids[c[1][1][1]]
            kv = fbxrw.child(cur, b'KeyValueFloat')[0]; vals = kv[1][0][1]
            assert len(vals) == len(dy), (ax, len(vals), len(dy))
            if ax == 'Y': new = [v - d * 100.0 for v, d in zip(vals, dy)]
            else: new = [float(xz[ax][min(i, len(J)-1)]) for i in range(len(vals))]
            kv[1][0] = (kv[1][0][0], new)
            dflt = fbxrw.child(cur, b'Default')
            if dflt: dflt[0][1][0] = (dflt[0][1][0][0], new[0])
            done.add(ax)
    assert done == set('XYZ'), done
    fbxrw.write(doc, dst)
    t2, P2, _, _ = measure(dst)
    low2 = np.min(np.stack([p[:,1] for p in P2.values()]), 0)
    return dict(leg_scale=round(float(sc),3), lift_removed=(round(float(dy.min()),3), round(float(dy.max()),3)), lowest_after=(round(float(low2.min()),3), round(float(low2.max()),3)), foot_slide=round(slide(t2, P2), 3))
if __name__ == '__main__':
    print(fix(*sys.argv[1:4]))
