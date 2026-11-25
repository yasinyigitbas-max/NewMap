# Measure a Mixamo FBX clip: hips path, hand / foot / head world heights by forward kinematics.
import sys, os, json, math
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fbxp import parse
TICK = 46186158000.0
def eul(rx, ry, rz):  # FBX XYZ order: R = Rz*Ry*Rx, degrees; arrays -> (n,3,3)
    rx, ry, rz = [np.radians(np.atleast_1d(a).astype(float)) for a in (rx, ry, rz)]
    n = max(len(rx), len(ry), len(rz))
    rx, ry, rz = [np.broadcast_to(a, (n,)) for a in (rx, ry, rz)]
    cx, sx, cy, sy, cz, sz = np.cos(rx), np.sin(rx), np.cos(ry), np.sin(ry), np.cos(rz), np.sin(rz)
    R = np.empty((n, 3, 3))
    R[:,0,0]=cz*cy; R[:,0,1]=cz*sy*sx-sz*cx; R[:,0,2]=cz*sy*cx+sz*sx
    R[:,1,0]=sz*cy; R[:,1,1]=sz*sy*sx+cz*cx; R[:,1,2]=sz*sy*cx-cz*sx
    R[:,2,0]=-sy;   R[:,2,1]=cy*sx;          R[:,2,2]=cy*cx
    return R
def measure(path):
    ver, top = parse(path)
    T = {n[0]: n for n in top}
    unit = 1.0
    for k in T['GlobalSettings'][2]:
        if k[0] == 'Properties70':
            for pp in k[2]:
                if pp[1][0] == 'UnitScaleFactor': unit = pp[1][4]
    objs = {n[1][0]: (n[0], n[1][1].split('\x00')[0], n[1][2], n) for n in T['Objects'][2]}
    conns = [c[1] for c in T['Connections'][2]]
    models = {i: o for i, o in objs.items() if o[0] == 'Model'}
    par = {c[1]: c[2] for c in conns if c[0] == 'OO' and c[1] in models and (c[2] in models or c[2] == 0)}
    def props(n):
        r = {}
        for k in n[2]:
            if k[0] == 'Properties70':
                for pp in k[2]:
                    if pp[1][0] in ('Lcl Translation', 'Lcl Rotation', 'Lcl Scaling', 'PreRotation', 'RotationOrder'):
                        r[pp[1][0]] = pp[1][4:]
        return r
    cn = {i: o for i, o in objs.items() if o[0] == 'AnimationCurveNode'}
    cv = {i: o for i, o in objs.items() if o[0] == 'AnimationCurve'}
    cn_t = {c[1]: (c[2], c[3]) for c in conns if c[0] == 'OP' and c[1] in cn and c[2] in models}
    curves = {}  # (model, prop, axis) -> (t, v)
    for c in conns:
        if c[0] == 'OP' and c[1] in cv and c[2] in cn_t:
            m, prop = cn_t[c[2]]
            n = cv[c[1]][3]
            kt = np.array([k for k in n[2] if k[0] == 'KeyTime'][0][1][0], float) / TICK
            kv = np.array([k for k in n[2] if k[0] == 'KeyValueFloat'][0][1][0], float)
            curves[(m, prop, c[3][-1])] = (kt, kv)
    hips = [i for i, o in models.items() if o[1].endswith('Hips')][0]
    times = curves[(hips, 'Lcl Translation', 'Y')][0]
    nfr = len(times)
    def chan(m, prop, default):
        out = []
        for a, d in zip('XYZ', default):
            if (m, prop, a) in curves:
                kt, kv = curves[(m, prop, a)]
                out.append(np.interp(times, kt, kv) if len(kt) != nfr or kt[0] != times[0] else kv)
            else:
                out.append(np.full(nfr, d))
        return out
    G = {}
    def glob(i):
        if i in G: return G[i]
        p = props(models[i][3])
        t = np.stack(chan(i, 'Lcl Translation', p.get('Lcl Translation', [0, 0, 0])), 1)
        r = eul(*chan(i, 'Lcl Rotation', p.get('Lcl Rotation', [0, 0, 0])))
        pre = eul(*p.get('PreRotation', [0, 0, 0]))[0]
        R = pre[None] @ r
        pi = par.get(i, 0)
        if pi in models:
            PR, PT = glob(pi)
            G[i] = (PR @ R, PT + np.einsum('nij,nj->ni', PR, t))
        else:
            G[i] = (R, t)
        return G[i]
    pos = {}
    for i, o in models.items():
        if o[2] in ('LimbNode', 'Root', 'Null'):
            nm = o[1].split(':')[-1]
            pos[nm] = glob(i)[1] * unit / 100.0  # metres
    meta = dict(ver=ver, skin=any(o[0]=='Geometry' for o in objs.values()), joints=sum(1 for o in models.values() if o[2]=='LimbNode'),
        prerot=any(any(abs(x)>1e-3 for x in props(o[3]).get('PreRotation',[0,0,0])) for o in models.values()), unit=unit,
        eyes=any(o[1].endswith('LeftEye') for o in models.values()))
    Rh = glob(hips)[0]
    yaw = np.degrees(np.unwrap(np.arctan2(Rh[:,0,2], Rh[:,2,2])))
    return times - times[0], pos, yaw, meta
def summary(path):
    t, P, yaw, meta = measure(path)
    h = P['Hips']; lh, rh = P['LeftHand'], P['RightHand']
    lf, rf = P['LeftToeBase'], P['RightToeBase']; la, ra = P['LeftFoot'], P['RightFoot']
    head = P.get('HeadTop_End', P['Head'])
    dur = float(t[-1]); n = len(t)
    d = h[-1] - h[0]
    hd = math.hypot(d[0], d[2])
    feet_lo = np.minimum(np.minimum(lf[:,1], rf[:,1]), np.minimum(la[:,1], ra[:,1]))
    hands_hi = np.maximum(lh[:,1], rh[:,1])
    r = lambda x: round(float(x), 3)
    rel0 = np.stack([P[k][0]-h[0] for k in P]); rel1 = np.stack([P[k][-1]-h[-1] for k in P])
    loop_err = float(np.abs(rel0-rel1).max())
    hv = np.hypot(np.diff(h[:,0]), np.diff(h[:,2])) / np.maximum(np.diff(t), 1e-6) if n > 1 else np.zeros(1)
    return dict(clip=os.path.basename(path)[:-4], dur=r(dur), frames=n, fps=r((n-1)/dur) if dur > 0 else 0,
        hips_y0=r(h[0,1]), hips_y1=r(h[-1,1]), hips_ymin=r(h[:,1].min()), hips_ymax=r(h[:,1].max()),
        fwd=r(d[2]), side=r(d[0]), rise=r(d[1]), horiz=r(hd), speed=r(hd/dur) if dur > 0 else 0,
        feet_y0=r(feet_lo[0]), feet_y1=r(feet_lo[-1]), feet_min=r(feet_lo.min()), feet_max_low=r(feet_lo.max()),
        hand_max=r(hands_hi.max()), hand_max_t=r(t[int(hands_hi.argmax())]),
        head_y0=r(head[0,1]), head_min=r(head[:,1].min()), head_max=r(head[:,1].max()),
        ankle_l0=r(la[0,1]), ankle_r0=r(ra[0,1]), yaw0=r(yaw[0]), yaw_delta=r(yaw[-1]-yaw[0]), loop_err=r(loop_err),
        peak_speed=r(hv.max()), hips_ymax_t=r(t[int(h[:,1].argmax())]), hips_ymin_t=r(t[int(h[:,1].argmin())]),
        hand_min=r(min(lh[:,1].min(), rh[:,1].min())), feet_hi_max=r(max(la[:,1].max(), ra[:,1].max())),
        leg_len=r(np.linalg.norm(P['LeftUpLeg'][0]-P['LeftLeg'][0])+np.linalg.norm(P['LeftLeg'][0]-P['LeftFoot'][0])), arm_len=r(np.linalg.norm(P['LeftArm'][0]-P['LeftForeArm'][0])+np.linalg.norm(P['LeftForeArm'][0]-P['LeftHand'][0])),
        path_len=r(float(np.hypot(np.diff(h[:,0]), np.diff(h[:,2])).sum())), **meta)
if __name__ == '__main__':
    out = []
    for p in sys.argv[2:]:
        try: out.append(summary(p))
        except Exception as e: out.append(dict(clip=os.path.basename(p)[:-4], error=repr(e)[:200]))
    json.dump(out, open(sys.argv[1], 'w'), indent=0)
    print(len(out), 'clips,', sum('error' in o for o in out), 'errors')
