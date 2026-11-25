# Round 3: key poses (study v2 6.1 / 6.2 / 6.12) + Kimodo in-betweening. Kimodo frame: start at (0,0) facing +Z, 30 fps.
import json, numpy as np
exec(open('keys.py').read())
_pose = pose
def pose(hips, **kw):
    hips = np.array(hips, float)
    for _ in range(40):
        L, G, X = _pose(hips, **kw)
        hs = [(s_, t_) for s_, t_ in (kw.get('hands') or {}).items() if t_ is not None]
        err = [np.array(t_) - X[s_ + 'Hand'] for s_, t_ in hs]
        if not err or max(np.linalg.norm(e) for e in err) < 0.005: return L, G, X
        hips = hips + np.mean(err, axis=0) * 0.7
    return L, G, X
T = {}
pk = lambda d: {"Left": d[0], "Right": d[1]}

# --- CLIMB onto a 1.5 m wall, near face at z = 1.2 m, deep top. 6.1: hands on top, pull, press, foot up, stand.
H, Z = 1.5, 1.2
eL, eR = [0.22, H + WR, Z + 0.12], [-0.22, H + WR, Z + 0.12]
keys = []
# K1 (f42): at the wall, hands on the edge, knees bent ready to jump
L, G, X = pose([0, 0.82, Z - 0.42], pitch=0.15, spine=0.2, hands=pk([eL, eR]), feet=pk([[0.12, ANK, Z - 0.35], [-0.12, ANK, Z - 0.3]]))
keys.append((42, L, X["Hips"])); check("climb K1", X, {"LeftHand": eL, "RightHand": eR})
# K2 (f60): pulled up, chest at the edge, elbows bent down, feet scrabbling on the wall face
L, G, X = pose([0, 1.12, Z - 0.30], pitch=0.25, spine=0.25, hands=pk([eL, eR]), elbow_pole=np.array([0, -0.6, -1.0]), knee_pole=[1.0, -0.2, -0.4],
               feet=pk([[0.12, 0.55, Z - 0.17], [-0.12, 0.30, Z - 0.18]]))
keys.append((60, L, X["Hips"])); check("climb K2", X, {"LeftHand": eL, "RightHand": eR})
# K3 (f76): the press: shoulders over the hands, arms nearly straight, hips at the edge
L, G, X = pose([0, 1.55, Z - 0.12], pitch=0.75, spine=0.35, hands=pk([eL, eR]), elbow_pole=np.array([0, 0.2, -1.0]), knee_pole=[1.0, -0.2, -0.4],
               feet=pk([[0.12, 0.95, Z - 0.17], [-0.12, 0.80, Z - 0.18]]))
keys.append((76, L, X["Hips"])); check("climb K3", X, {"LeftHand": eL, "RightHand": eR})
# K4 (f92): left foot on top beside the hands, knee deep, trunk forward
L, G, X = pose([0, H + 0.45, Z + 0.05], pitch=0.7, spine=0.3, hands=pk([eL, eR]), elbow_pole=np.array([0, 0.2, -1.0]), knee_pole=[0.6, 0.6, -0.5],
               feet=pk([[0.14, H + ANK, Z + 0.32], [-0.12, H - 0.25, Z - 0.17]]))
keys.append((92, L, X["Hips"])); check("climb K4", X, {"LeftFoot": [0.14, H + ANK, Z + 0.32]})
# K5 (f125): standing on top
L, G, X = pose([0, H + 0.93, Z + 0.55], feet=pk([[0.11, H + ANK, Z + 0.55], [-0.11, H + ANK, Z + 0.55]]))
keys.append((125, L, X["Hips"]))
T["climb_1m5"] = {"prompt": "A person walks to a wall one and a half meters high, puts both hands on the top edge, jumps and pulls himself up with his feet pushing on the wall, presses up on straight arms with his chest over the edge, puts his left foot on top beside his hands and stands up on top of the wall.",
                  "duration": 4.5, "keys": keys, "path": [[0, [0, 0]]],
                  "wall": {"top": H, "z0": Z, "z1": Z + 3.0}, "grip": (42, 92), "hands": [eL, eR], "end_feet_y": H + ANK}

# --- MANTLE onto a 0.8 m wall, near face z = 1.0, deep top. 6.1: both hands, hop, knee onto the top, stand.
H, Z = 0.8, 1.0
eL, eR = [0.22, H + WR, Z + 0.12], [-0.22, H + WR, Z + 0.12]
keys = []
L, G, X = pose([0, 0.86, Z - 0.42], pitch=0.45, spine=0.35, hands=pk([eL, eR]), feet=pk([[0.12, ANK, Z - 0.35], [-0.12, ANK, Z - 0.3]]))
keys.append((36, L, X["Hips"])); check("mantle K1", X, {"LeftHand": eL, "RightHand": eR})
L, G, X = pose([0, 1.12, Z - 0.16], pitch=0.75, spine=0.3, hands=pk([eL, eR]), elbow_pole=np.array([0, 0.1, -1.0]), knee_pole=[0.6, 0.6, -0.5],
               feet=pk([[0.12, H + 0.05, Z - 0.25], [-0.12, 0.35, Z - 0.25]]))
keys.append((50, L, X["Hips"])); check("mantle K2 (knee up, foot behind)", X, {"LeftHand": eL})
L, G, X = pose([0, H + 0.5, Z + 0.15], pitch=0.6, spine=0.3, hands=pk([eL, eR]), elbow_pole=np.array([0, 0.1, -1.0]), knee_pole=[0.6, 0.6, -0.5],
               feet=pk([[0.13, H + ANK, Z + 0.35], [-0.12, H - 0.2, Z - 0.17]]))
keys.append((64, L, X["Hips"])); check("mantle K3", X, {"LeftFoot": [0.13, H + ANK, Z + 0.35]})
L, G, X = pose([0, H + 0.93, Z + 0.55], feet=pk([[0.11, H + ANK, Z + 0.55], [-0.11, H + ANK, Z + 0.55]]))
keys.append((95, L, X["Hips"]))
T["mantle_0m8"] = {"prompt": "A person walks to a wall eighty centimeters high, puts both hands on top, hops up pressing on straight arms, puts his left knee and then his left foot on top, and stands up on top of the wall.",
                   "duration": 4, "keys": keys, "path": [[0, [0, 0]]],
                   "wall": {"top": H, "z0": Z, "z1": Z + 3.0}, "grip": (36, 64), "hands": [eL, eR], "end_feet_y": H + ANK}

# --- STEP VAULT over a 1.0 m wall, 0.3 m thick, near face z = 2.5. 6.2: one hand on top, same-side foot on top,
# the other leg passes between, land on the far side.
H, Z = 1.0, 2.5
hL = [0.18, H + WR, Z + 0.12]
keys = []
L, G, X = pose([0, 1.0, Z - 0.45], pitch=0.35, spine=0.2, hands=pk([hL, None]), knee_pole=[0.3, 0.8, 0.2],
               feet=pk([[0.1, 0.55, Z - 0.28], [-0.1, ANK, Z - 0.6]]))
keys.append((34, L, X["Hips"])); check("vault K1 (hand down, left knee up)", X, {"LeftHand": hL})
L, G, X = pose([0, H + 0.62, Z + 0.15], pitch=0.35, spine=0.2, hands=pk([hL, None]),
               feet=pk([[0.1, H + ANK, Z + 0.18], [-0.12, H + 0.35, Z + 0.15]]))
keys.append((44, L, X["Hips"])); check("vault K2 (left foot on top)", X, {"LeftFoot": [0.1, H + ANK, Z + 0.18]})
L, G, X = pose([0, 0.85, Z + 0.95], pitch=0.15, feet=pk([[0.1, 0.45, Z + 0.6], [-0.12, ANK, Z + 1.1]]))
keys.append((56, L, X["Hips"]))
T["vault_1m0"] = {"prompt": "A person jogs forward and does a step vault over a wall one meter high and thirty centimeters thick: left hand on top of the wall, left foot steps on top, the right leg swings over, he lands on the other side and keeps jogging forward.",
                  "duration": 4, "keys": keys, "path": [[0, [0, 0]], [110, [0, Z + 3.5]]],
                  "wall": {"top": H, "z0": Z, "z1": Z + 0.3}, "grip": (34, 44), "hands": [hL], "end_feet_y": ANK}

out = {}
for k, t in T.items():
    cons = [fullbody(f, L, hp) for f, L, hp in t["keys"]]
    cons.append({"type": "root2d", "frame_indices": [p[0] for p in t["path"]], "smooth_root_2d": [p[1] for p in t["path"]]})
    json.dump(cons, open(f"ref/r3_{k}.json", "w"))
    out[k] = {kk: (vv if kk != "keys" else [[f, list(map(float, h))] for f, _, h in vv]) for kk, vv in t.items()}
json.dump(out, open("ref/r3_tests.json", "w"), indent=1)
print("ok", list(T))
