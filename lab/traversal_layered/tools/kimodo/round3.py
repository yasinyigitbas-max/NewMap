# Round 3: key poses (study v2 6.1 / 6.2 / 6.12) + Kimodo in-betweening. Kimodo frame: start at (0,0) facing +Z, 30 fps.
import json, numpy as np
exec(open('keys.py').read())
_pose = pose
def hip_rotation(G, X, side):
    t = X[side + 'Shin'] - X[side + 'Leg']; t = t / np.linalg.norm(t)
    ax = G[side + 'Leg'] @ np.array([1.0, 0, 0]); pl = G['Hips'] @ np.array([1.0, 0, 0])
    axp = ax - t * ax.dot(t); axp /= np.linalg.norm(axp); plp = pl - t * pl.dot(t); plp /= np.linalg.norm(plp)
    return float(np.degrees(np.arctan2(t.dot(np.cross(plp, axp)), plp.dot(axp))))
def hip_flexion(G, X, side):
    t = X[side + 'Shin'] - X[side + 'Leg']; t = t / np.linalg.norm(t)
    pf = G['Hips'] @ np.array([0, 0, 1.0]); pd = -(G['Hips'] @ np.array([0, 1.0, 0]))
    return float(np.degrees(np.arctan2(t.dot(pf), t.dot(pd))))
WALL = None
def wall_pen(X):
    if WALL is None: return 0.0, ""
    top, z0, z1 = WALL; worst = (0.0, "")
    for a, b, rad in (("Hips", "Chest", 0.13), ("LeftLeg", "LeftShin", 0.07), ("RightLeg", "RightShin", 0.07), ("LeftShin", "LeftFoot", 0.05), ("RightShin", "RightFoot", 0.05)):
        for k in range(7):
            p = X[a] + (X[b] - X[a]) * k / 6
            d = min(p[2] + rad - z0, z1 - (p[2] - rad), top - (p[1] - rad))
            if abs(p[0]) < 0.8 and d > worst[0]: worst = (d, a + "-" + b)
    return worst
def pose(hips, **kw):
    hips = np.array(hips, float)
    for _ in range(40):
        L, G, X = _pose(hips, **kw)
        hs = [(s_, t_) for s_, t_ in (kw.get('hands') or {}).items() if t_ is not None]
        err = [np.array(t_) - X[s_ + 'Hand'] for s_, t_ in hs]
        if not err or max(np.linalg.norm(e) for e in err) < 0.005: break
        hips = hips + np.mean(err, axis=0) * 0.7
    pen = wall_pen(X)
    print(f"      body into the wall: {pen[0]*100:.0f} cm {pen[1]}")
    if pen[0] > 0.03: raise SystemExit(f"KEY POSE REFUSED: {pen[1]} {pen[0]*100:.0f} cm inside the wall")
    for sd in ("Left", "Right"):
        h = hip_rotation(G, X, sd)
        # sign by side: + = knee turned outward (v2 1.5); limits out 50, in 40
        out = h if sd == "Left" else -h
        hf = hip_flexion(G, X, sd)
        print(f"      hip rotation {sd}: {out:.0f} deg, hip flexion {hf:.0f} deg")
        if hf > 120: raise SystemExit(f"KEY POSE REFUSED: {sd} hip flexion {hf:.0f} deg (limit 125)")
        if out > 50 or out < -40: raise SystemExit(f"KEY POSE REFUSED: {sd} hip rotation {out:.0f} deg (limit in 40 / out 50)")
    return L, G, X
T = {}
pk = lambda d: {"Left": d[0], "Right": d[1]}

# --- CLIMB onto a 1.5 m wall, near face at z = 1.2 m, deep top. 6.1: hands on top, pull, press, foot up, stand.
H, Z = 1.5, 1.2
WALL = (H, Z, Z + 3.0)
eL, eR = [0.22, H + WR, Z + 0.12], [-0.22, H + WR, Z + 0.12]
keys = []
# K1 (f42): at the wall, hands on the edge, knees bent ready to jump
L, G, X = pose([0, 0.82, Z - 0.42], pitch=0.15, spine=0.2, hands=pk([eL, eR]), feet=pk([[0.12, ANK, Z - 0.35], [-0.12, ANK, Z - 0.3]]))
keys.append((42, L, X["Hips"])); check("climb K1", X, {"LeftHand": eL, "RightHand": eR})
# K2 (f60): pulled up, chest at the edge, elbows bent down, feet scrabbling on the wall face
L, G, X = pose([0, 1.12, Z - 0.30], pitch=0.25, spine=0.25, hands=pk([eL, eR]), elbow_pole=np.array([0, -0.6, -1.0]), knee_pole=[0.45, 0.0, 1.0],
               feet=pk([[0.12, 0.28, Z - 0.16], [-0.12, 0.20, Z - 0.18]]))
keys.append((60, L, X["Hips"])); check("climb K2", X, {"LeftHand": eL, "RightHand": eR})
# K3 (f76): the press: shoulders over the hands, arms nearly straight, hips at the edge
L, G, X = pose([0, 1.55, Z - 0.16], pitch=0.75, spine=0.35, hands=pk([eL, eR]), elbow_pole=np.array([0, 0.2, -1.0]), knee_pole=[0.45, 0.0, 0.9],
               feet=pk([[0.14, 0.66, Z - 0.17], [-0.14, 0.60, Z - 0.18]]))
keys.append((76, L, X["Hips"])); check("climb K3", X, {"LeftHand": eL, "RightHand": eR})
# K5 (f125): standing on top
L, G, X = pose([0, H + 0.93, Z + 0.55], feet=pk([[0.11, H + ANK, Z + 0.55], [-0.11, H + ANK, Z + 0.55]]))
keys.append((125, L, X["Hips"]))
T["climb_1m5"] = {"prompt": "A person walks to a wall one and a half meters high, puts both hands on the top edge, jumps and pulls himself up with his feet pushing on the wall, presses up on straight arms with his chest over the edge, puts his left foot on top beside his hands and stands up on top of the wall.",
                  "duration": 4.5, "keys": keys, "path": [[0, [0, 0]]],
                  "wall": {"top": H, "z0": Z, "z1": Z + 3.0}, "grip": (42, 76), "hands": [eL, eR], "end_feet_y": H + ANK}

# --- MANTLE onto a 0.8 m wall, near face z = 1.0, deep top. 6.1: both hands, hop, knee onto the top, stand.
H, Z = 0.8, 1.0
WALL = (H, Z, Z + 3.0)
eL, eR = [0.22, H + WR, Z + 0.12], [-0.22, H + WR, Z + 0.12]
keys = []
L, G, X = pose([0, 0.86, Z - 0.42], pitch=0.45, spine=0.35, hands=pk([eL, eR]), feet=pk([[0.12, ANK, Z - 0.35], [-0.12, ANK, Z - 0.3]]))
keys.append((36, L, X["Hips"])); check("mantle K1", X, {"LeftHand": eL, "RightHand": eR})
L, G, X = pose([0, 1.12, Z - 0.16], pitch=0.75, spine=0.3, hands=pk([eL, eR]), elbow_pole=np.array([0, 0.1, -1.0]), knee_pole=[0.3, 0.0, 1.0],
               feet=pk([[0.12, 0.25, Z - 0.30], [-0.12, 0.15, Z - 0.32]]))
keys.append((50, L, X["Hips"])); check("mantle K2 (knee up, foot behind)", X, {"LeftHand": eL})
L, G, X = pose([0, H + 0.93, Z + 0.55], feet=pk([[0.11, H + ANK, Z + 0.55], [-0.11, H + ANK, Z + 0.55]]))
keys.append((95, L, X["Hips"]))
T["mantle_0m8"] = {"prompt": "A person walks to a wall eighty centimeters high, puts both hands on top, hops up pressing on straight arms, puts his left knee and then his left foot on top, and stands up on top of the wall.",
                   "duration": 4, "keys": keys, "path": [[0, [0, 0]]],
                   "wall": {"top": H, "z0": Z, "z1": Z + 3.0}, "grip": (36, 50), "hands": [eL, eR], "end_feet_y": H + ANK}

# (step vault left out of this round: its key poses don't pass the gates yet)

out = {}
for k, t in T.items():
    cons = [fullbody(f, L, hp) for f, L, hp in t["keys"]]
    cons.append({"type": "root2d", "frame_indices": [p[0] for p in t["path"]], "smooth_root_2d": [p[1] for p in t["path"]]})
    json.dump(cons, open(f"ref/r3_{k}.json", "w"))
    out[k] = {kk: (vv if kk != "keys" else [[f, list(map(float, h))] for f, _, h in vv]) for kk, vv in t.items()}
json.dump(out, open("ref/r3_tests.json", "w"), indent=1)
print("ok", list(T))
