# Key-pose builder for the Kimodo round 3 test (Lab B). Builds poses on Kimodo's SOMA skeleton (rest = T-pose, identity
# rotations, Y up, +Z forward, metres) from a few numbers: hips position, trunk pitch, hand and foot targets, solved
# with two-bone IK (knee pole forward, elbow pole down-back), hands palm-down fingers forward, feet flat forward.
import numpy as np, json
rest = json.load(open('ref/rest77.json'))
names = json.load(open('out/probe_walkstop/metadata.json'))['joint_names']
J = {n: i for i, n in enumerate(names)}
par = {n: rest[n]['parent'] for n in names}
RP = {n: np.array(rest[n]['pos']) for n in names}
S30 = ["Hips","Spine1","Spine2","Chest","Neck1","Neck2","Head","Jaw","LeftEye","RightEye","LeftShoulder","LeftArm",
       "LeftForeArm","LeftHand","LeftHandThumbEnd","LeftHandMiddleEnd","RightShoulder","RightArm","RightForeArm",
       "RightHand","RightHandThumbEnd","RightHandMiddleEnd","LeftLeg","LeftShin","LeftFoot","LeftToeBase","RightLeg",
       "RightShin","RightFoot","RightToeBase"]

def rx(a): c, s = np.cos(a), np.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def ry(a): c, s = np.cos(a), np.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def off(n): return RP[n] - RP[par[n]]
def nrm(v): return v / np.linalg.norm(v)
def rotvec(R):
    c = np.clip((np.trace(R) - 1) / 2, -1, 1); a = np.arccos(c)
    if a < 1e-6: return np.zeros(3)
    if a > np.pi - 1e-4:
        w, v = np.linalg.eigh((R + np.eye(3)) / 2); return v[:, np.argmax(w)] * a
    return np.array([R[2,1]-R[1,2], R[0,2]-R[2,0], R[1,0]-R[0,1]]) / (2*np.sin(a)) * a
def basis(u, n):
    return np.column_stack([u, n, np.cross(u, n)])

def two_bone(a, l1, l2, t, pole, u0, p0):
    """global rotations (upper, lower) for a chain whose rest direction is u0 and rest bend direction p0."""
    d = t - a; dist = np.linalg.norm(d)
    dist = min(dist, (l1 + l2) * 0.995); dn = nrm(d); t = a + dn * dist
    pp = (pole - a) - dn * np.dot(pole - a, dn); pn = nrm(pp)
    ca = np.clip((l1*l1 + dist*dist - l2*l2) / (2*l1*dist), -1, 1)
    mid = a + dn * (l1 * ca) + pn * (l1 * np.sqrt(1 - ca*ca))
    n0 = nrm(np.cross(u0, p0))
    u1 = nrm(mid - a); n1 = nrm(np.cross(u1, pn if np.linalg.norm(np.cross(u1, pn)) > 1e-6 else p0))
    # bend plane normal must be the same for both bones: n = cross(hip->ankle, pole)
    n = nrm(np.cross(dn, pn))
    Rup = basis(u1, n) @ basis(u0, n0).T
    u2 = nrm(t - mid)
    Rlo = basis(u2, n) @ basis(u0, n0).T
    return Rup, Rlo, mid, t

def pose(hips, pitch=0.0, spine=0.0, hands=None, feet=None, knee_pole=None, elbow_pole=None, head=0.0, hang_arms=0.0):
    """hips: position; pitch: hips forward tilt (rad); spine: extra forward bend shared by Spine1/Spine2/Chest;
    hands/feet: {'Left': target or None, 'Right': ...}; returns (local rotations 77x3x3, globals, positions)."""
    G, X = {}, {}
    hands = hands or {}; feet = feet or {}
    for n in names:
        p = par[n]
        if p == "": G[n] = rx(pitch); X[n] = np.array(hips, float); continue
        X[n] = X[p] + G[p] @ off(n)
        g = G[p]
        if n in ("Spine1", "Spine2", "Chest"): g = G[p] @ rx(spine / 3)
        if n == "Head": g = rx(-(pitch + spine) * 0.6 + head) if True else g
        for side, sgn in (("Left", 1), ("Right", -1)):
            if n == side + "Arm":
                tgt = hands.get(side)
                if tgt is not None:
                    a = X[n]; l1 = np.linalg.norm(off(side + "ForeArm")); l2 = np.linalg.norm(off(side + "Hand"))
                    pole = a + (elbow_pole if elbow_pole is not None else np.array([0, -0.6, -0.8])) + np.array([sgn * 0.3, 0, 0])
                    Rup, Rlo, mid, tt = two_bone(a, l1, l2, np.array(tgt, float), pole, np.array([sgn * 1.0, 0, 0]), np.array([0, 0, -1.0]))
                    G["_lo_" + side] = Rlo; g = Rup
                else:
                    g = ry(0) @ rx(0) @ np.array([[np.cos(sgn*-1.3), -np.sin(sgn*-1.3), 0], [np.sin(sgn*-1.3), np.cos(sgn*-1.3), 0], [0, 0, 1]])  # arm down ~75 deg
                    g = G[p] @ g
            if n == side + "ForeArm" and ("_lo_" + side) in G: g = G["_lo_" + side]
            if n == side + "Hand" and hands.get(side) is not None: g = ry(-sgn * np.pi / 2)  # palm down, fingers forward
            if n == side + "Leg":
                tgt = feet.get(side)
                if tgt is not None:
                    a = X[n]; l1 = np.linalg.norm(off(side + "Shin")); l2 = np.linalg.norm(off(side + "Foot"))
                    pole = a + ((np.array(knee_pole) * np.array([sgn, 1, 1])) if knee_pole is not None else np.array([0, 0, 1.0]))
                    Rup, Rlo, mid, tt = two_bone(a, l1, l2, np.array(tgt, float), pole, np.array([0, -1.0, 0]), np.array([0, 0, 1.0]))
                    G["_llo_" + side] = Rlo; g = Rup
            if n == side + "Shin" and ("_llo_" + side) in G: g = G["_llo_" + side]
            if n == side + "Foot" and feet.get(side) is not None: g = np.eye(3)  # flat, forward
        G[n] = g
    L = np.zeros((len(names), 3, 3))
    for n in names:
        p = par[n]; L[J[n]] = G[n] if p == "" else G[p].T @ G[n]
    return L, G, X

def fullbody(frame, L, hips):
    return {"type": "fullbody", "frame_indices": [frame], "local_joints_rot": [[rotvec(L[J[n]]).tolist() for n in S30]],
            "root_positions": [list(map(float, hips))], "smooth_root_2d": [[float(hips[0]), float(hips[2])]]}

ANK = 0.07; WR = 0.04
def check(name, X, want):
    for j, t in want.items():
        e = np.linalg.norm(X[j] - np.array(t)); print(f"   {name}: {j} off target {e*100:.1f} cm")
