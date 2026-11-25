# Build Kimodo constraint files for the pinned traversal test (Lab B). Poses come from earlier Kimodo outputs (donors),
# turned to face +Z and moved so the pinned hand / foot lands exactly on the target. Kimodo frame: Y up, +Z forward,
# metres, the root starts at XZ (0,0) facing +Z, 30 fps.
import numpy as np, json, glob, sys
rest = json.load(open('ref/rest77.json'))
names77 = json.load(open('out/probe_walkstop/metadata.json'))['joint_names']
J77 = {n: i for i, n in enumerate(names77)}
S30 = ["Hips","Spine1","Spine2","Chest","Neck1","Neck2","Head","Jaw","LeftEye","RightEye","LeftShoulder","LeftArm",
       "LeftForeArm","LeftHand","LeftHandThumbEnd","LeftHandMiddleEnd","RightShoulder","RightArm","RightForeArm",
       "RightHand","RightHandThumbEnd","RightHandMiddleEnd","LeftLeg","LeftShin","LeftFoot","LeftToeBase","RightLeg",
       "RightShin","RightFoot","RightToeBase"]

def rotvec(R):
    c = np.clip((np.trace(R) - 1) / 2, -1, 1); a = np.arccos(c)
    if a < 1e-6: return np.zeros(3)
    if a > np.pi - 1e-4:
        w, v = np.linalg.eigh((R + np.eye(3)) / 2); ax = v[:, np.argmax(w)]; return ax * a
    ax = np.array([R[2,1]-R[1,2], R[0,2]-R[2,0], R[1,0]-R[0,1]]) / (2*np.sin(a)); return ax * a

def yaw(a):
    c, s = np.cos(a), np.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])

def fk(L, root):
    G, X = {}, {}
    for n in names77:
        par = rest[n]['parent']
        if par == "": G[n] = L[J77[n]]; X[n] = root
        else:
            off = np.array(rest[n]['pos']) - np.array(rest[par]['pos'])
            G[n] = G[par] @ L[J77[n]]; X[n] = X[par] + G[par] @ off
    return G, X

donors = []
for f in sorted(glob.glob('out/*/kimodo_motion_*.npz')):
    d = np.load(f)
    for i in range(0, d['local_rot_mats'].shape[0], 2): donors.append((f, i, d['local_rot_mats'][i]))

def facing(L):
    fw = L[J77['Hips']] @ np.array([0, 0, 1.0]); return np.arctan2(fw[0], fw[2])

def pick(effs, want, palm_down=False, foot_flat=False):
    """effs: joint names; want: offsets from the hips (facing +Z) they should have. Returns (L turned to +Z, score)."""
    best = None
    for f, i, L in donors:
        L2 = L.copy(); L2[J77['Hips']] = yaw(-facing(L)) @ L[J77['Hips']]
        G, X = fk(L2, np.zeros(3))
        sc = sum(np.linalg.norm(X[e] - np.array(w)) for e, w in zip(effs, want))
        for e in effs:
            if palm_down and 'Hand' in e: sc += 0.3 * (1 - (G[e] @ np.array([0, -1, 0]))[1])
            if foot_flat and 'Foot' in e: sc += 0.5 * (1 - (G[e] @ np.array([0, 1, 0]))[1])
        if best is None or sc < best[1]: best = (L2, sc, f, i)
    return best

def pose30(L):
    return [rotvec(L[J77[n]]).tolist() for n in S30]

def pin(kind, frame, L, eff, target):
    """kind: left-hand etc. Root placed so joint eff lands on target."""
    G, X = fk(L, np.zeros(3))
    root = np.array(target) - X[eff]
    return {"type": kind, "frame_indices": [frame], "local_joints_rot": [pose30(L)],
            "root_positions": [root.tolist()], "smooth_root_2d": [[float(root[0]), float(root[2])]]}

def path(frames, pts):
    return {"type": "root2d", "frame_indices": frames, "smooth_root_2d": pts}

ANKLE = 0.07   # SOMA ankle above the sole
WRIST = 0.04   # wrist above a flat palm
tests = {}
# step vault over a 1.0 m high, 0.3 m thick wall whose near face is 2.5 m ahead; left hand and left foot on top
H = 1.0
L, sc, f, i = pick(["LeftHand"], [[0.2, 0.0, 0.45]], palm_down=True)
Lf, scf, ff, fi = pick(["LeftFoot"], [[0.12, -0.05, 0.25]], foot_flat=True)
tests["vault_1m0"] = {"prompt": "A person jogs forward and does a step vault over a 1.0 meter high, 30 centimeter thick wall: the left hand on top of the wall, the left foot steps on top, the right leg swings over, he lands on the other side and keeps jogging.",
    "duration": 4, "cons": [path([0, 105], [[0, 0], [0, 6.0]]),
        pin("left-hand", 33, L, "LeftHand", [0.18, H + WRIST, 2.62]),
        pin("left-foot", 39, Lf, "LeftFoot", [0.10, H + ANKLE, 2.68])],
    "donors": [(f, i, sc), (ff, fi, scf)]}
# climb onto a 1.5 m wall (near face 1.2 m ahead, deep top): both hands on the edge, then both feet on top
H = 1.5
# no donor reaches both hands up onto an edge: build it (T-pose, both arms swung forward-up, palms stay down)
def arc(a, b):
    a = a / np.linalg.norm(a); b = b / np.linalg.norm(b); v = np.cross(a, b); c = np.dot(a, b)
    K = np.array([[0,-v[2],v[1]],[v[2],0,-v[0]],[-v[1],v[0],0]]); return np.eye(3) + K + K @ K / (1 + c)
Lc = np.tile(np.eye(3), (len(names77), 1, 1))
Lc[J77["LeftArm"]] = arc(np.array([1.0, 0, 0]), np.array([0.25, 0.55, 0.8]))
Lc[J77["RightArm"]] = arc(np.array([-1.0, 0, 0]), np.array([-0.25, 0.55, 0.8]))
Lc[J77["LeftHand"]] = arc(np.array([0.25, 0.55, 0.8]), np.array([0.1, -0.2, 1.0])) @ np.eye(3) if False else np.eye(3)
scc, fc, ic = 0.0, "built/arms-up", 0
Lt, sct, ft, it = pick(["LeftFoot"], [[0.1, -0.85, 0.2]], foot_flat=True)
def both_hands(frame):
    G, X = fk(Lc, np.zeros(3)); mid = (X["LeftHand"] + X["RightHand"]) / 2
    tgt = np.array([0.0, H + WRIST, 1.32]); root = tgt - mid
    c = {"frame_indices": [frame], "local_joints_rot": [pose30(Lc)], "root_positions": [root.tolist()], "smooth_root_2d": [[float(root[0]), float(root[2])]]}
    return [dict(c, type="left-hand"), dict(c, type="right-hand")]
tests["climb_1m5"] = {"prompt": "A person walks to a 1.5 meter high wall, jumps and grabs the top edge with both hands, pulls himself up, presses up on straight arms, puts one foot on top beside his hands and stands up on top of the wall.",
    "duration": 5, "cons": [path([0, 140], [[0, 0], [0, 1.75]])] + both_hands(38) + both_hands(70) +
        [pin("left-foot", 105, Lt, "LeftFoot", [0.12, H + ANKLE, 1.5])],
    "donors": [(fc, ic, scc), (ft, it, sct)]}
# big step up onto a 0.4 m box (near face 1.0 m ahead): right foot first, then left
H = 0.4
Ls, scs, fs, is_ = pick(["RightFoot"], [[-0.1, -0.55, 0.3]], foot_flat=True)
Ls2, scs2, fs2, is2 = pick(["LeftFoot"], [[0.1, -0.85, 0.05]], foot_flat=True)
tests["stepup_0m4"] = {"prompt": "A person walks to a 40 centimeter high box, steps up onto it with the right foot, brings the left foot up beside it and stands on top of the box.",
    "duration": 4, "cons": [path([0, 100], [[0, 0], [0, 1.3]]),
        pin("right-foot", 45, Ls, "RightFoot", [-0.10, H + ANKLE, 1.25]),
        pin("left-foot", 72, Ls2, "LeftFoot", [0.10, H + ANKLE, 1.32])],
    "donors": [(fs, is_, scs), (fs2, is2, scs2)]}
for k, t in tests.items():
    json.dump(t["cons"], open(f"ref/cons_{k}.json", "w"))
    print(k, "donors:", [(a.split('/')[1], b, round(c, 3)) for a, b, c in t["donors"]])
json.dump({k: {"prompt": t["prompt"], "duration": t["duration"]} for k, t in tests.items()}, open("ref/pin_tests.json", "w"), indent=1)
