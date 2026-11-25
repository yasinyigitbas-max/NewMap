import numpy as np, json, glob
names = json.load(open('out/probe_walkstop/metadata.json'))['joint_names']; J = {n: i for i, n in enumerate(names)}
tests = json.load(open('ref/r3_tests.json'))
BODY = [n for n in names if not any(k in n for k in ("Hand", "Foot", "Toe", "Thumb", "Index", "Middle", "Ring", "Pinky"))]
res = {}
for k, t in tests.items():
    rows = []
    for f in sorted(glob.glob(f'out/r3b_{k}/*.npz')):
        d = np.load(f); P = d['posed_joints']; G = d['global_rot_mats']; T = P.shape[0]
        a, b = t['grip']
        hand_names = ["LeftHand", "RightHand"][:len(t['hands'])]
        grip = max(np.linalg.norm(P[a:b+1, J[h]] - np.array(e), axis=1).max() for h, e in zip(hand_names, t['hands']))
        w = t['wall']; pen = 0.0
        for n in BODY + ["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]:
            p = P[:, J[n]]
            inside = (np.abs(p[:, 0]) < 1.0) & (p[:, 2] > w['z0'] + 0.03) & (p[:, 2] < w['z1'] - 0.03) & (p[:, 1] < w['top'] - 0.03)
            if inside.any():
                depth = np.minimum.reduce([p[inside, 2] - w['z0'], w['z1'] - p[inside, 2], w['top'] - p[inside, 1]])
                pen = max(pen, depth.max())
        end_hips = t['keys'][-1][1][1] if k != 'vault_1m0' else 1.0
        hip_excess = max(0.0, P[:, J['Hips'], 1].max() - (end_hips + 0.15 if k != 'vault_1m0' else w['top'] + 0.8))
        endf = abs(P[-10:, [J['LeftFoot'], J['RightFoot']], 1].mean() - t['end_feet_y'])
        kb = 0
        for side in ("Left", "Right"):
            hip, knee, ank = P[:, J[side + "Leg"]], P[:, J[side + "Shin"]], P[:, J[side + "Foot"]]
            ax = G[:, J[side + "Leg"]] @ np.array([1.0, 0, 0])
            tt = knee - hip; ss = ank - knee
            ft = np.cross(tt, ax); ft /= np.linalg.norm(ft, axis=1, keepdims=True)
            tn = tt / np.linalg.norm(tt, axis=1, keepdims=True); sn = ss / np.linalg.norm(ss, axis=1, keepdims=True)
            mag = np.degrees(np.arccos(np.clip((tn * sn).sum(1), -1, 1)))
            back = ((ss * ft).sum(1) > 0) & (mag > 5)
            kb += int(back.sum())
        score = grip + 3 * pen + hip_excess + endf + 0.02 * kb
        rows.append((score, f.split('/')[-1], grip, pen, hip_excess, endf, kb))
    rows.sort()
    res[k] = rows
    print(f"\n{k}: sample  score  grip-drift  wall-pen  hips-too-high  end-err  knee-back-frames")
    for r in rows[:6]: print(f"  {r[1]:22s} {r[0]:5.2f}  {r[2]*100:5.1f}cm   {r[3]*100:5.1f}cm   {r[4]*100:5.1f}cm   {r[5]*100:5.1f}cm   {r[6]}")
    print(f"  ... worst: {rows[-1][1]} {rows[-1][0]:.2f};  samples with grip < 5 cm and no wall pen > 3 cm: {sum(1 for r in rows if r[2] < 0.05 and r[3] < 0.03)}/{len(rows)}")
json.dump({k: [r[1] for r in v[:3]] for k, v in res.items()}, open('ref/r3b_best.json', 'w'))
