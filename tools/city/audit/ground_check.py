"""Ground check of the assembled city (19 Nov 2026; Yasin: "Many areas are sunk in too... I think these validators and
checkers don't do what they are supposed to do").

Reads the dump of tools/city/audit/ground_dump.gd and the terrain (zoning/terrain_grid.npz) and measures, on a 1 m
grid, the three things no check measured for a block:
  BURIED   the terrain lies over a piece's ground (by more than 5 cm): the piece is sunk into the land there
  HANGING  a piece's ground lies more than 30 cm over the terrain at the piece's own outer edge: it floats
  STEP     two different pieces meet (next to each other, or one over the other) with a jump of more than 20 cm
Sea cells are skipped. Kerbs (15 cm) and terraces inside ONE piece are not steps: only different pieces are compared.

  python tools/city/audit/ground_check.py OUT/ground [--picture=OUT/top/city_notrees_full.jpg]
Prints a table per family and the worst pieces; writes <dump>_check.json and, with --picture, a copy of the bird's-eye
picture (2 px a metre from x -1600, z -1800) with buried cells red, hanging cells blue and steps yellow.
"""
import json, sys, collections
import numpy as np

U0, V0, NX, NY = -1600.0, -1900.0, 3300, 2700


def family(piece, frm):
    if frm.startswith('grow_'):
        return frm
    if frm.startswith('sample'):
        return 'sample street' if piece[:2] in ('j_', 's_') else 'sample block'
    return 'road kit (%s)' % frm if frm else 'other'


def main():
    base = sys.argv[1]
    pic = next((a.split('=', 1)[1] for a in sys.argv[2:] if a.startswith('--picture=')), None)
    recs = json.load(open(base + '.json', encoding='utf-8'))
    V = np.fromfile(base + '_v.bin', '<f4').reshape(-1, 3)
    I = np.fromfile(base + '_i.bin', '<i4')
    t = np.load('map_dc/coronado/city_kit/zoning/terrain_grid.npz')
    TH = t['heights'].astype(np.float64); SEA = t['sea'].astype(bool); tu0 = float(t['u0']); tv0 = float(t['v0']); ts = float(t['step'])

    def terrain(x, z):
        fx = (x - tu0) / ts; fz = (z - tv0) / ts
        i = np.clip(np.floor(fx).astype(int), 0, TH.shape[1] - 2); j = np.clip(np.floor(fz).astype(int), 0, TH.shape[0] - 2)
        ax = np.clip(fx - i, 0, 1); az = np.clip(fz - j, 0, 1)
        h = (TH[j, i] * (1 - ax) + TH[j, i + 1] * ax) * (1 - az) + (TH[j + 1, i] * (1 - ax) + TH[j + 1, i + 1] * ax) * az
        sea = SEA[np.clip(np.round(fz).astype(int), 0, SEA.shape[0] - 1), np.clip(np.round(fx).astype(int), 0, SEA.shape[1] - 1)]
        return h, sea

    names = []; fams = []
    cells_l = []; ids_l = []; lo_l = []; hi_l = []
    for n, r in enumerate(recs):
        names.append(r['piece']); fams.append(family(r['piece'], r['from']))
        x = np.array(r['xf'], dtype=np.float64); B = x[:9].reshape(3, 3).T; o = x[9:]
        tris = []
        for name, vo, vn, io, inn in r['surf']:
            v = V[vo:vo + vn].astype(np.float64) @ B.T + o
            tris.append(v[I[io:io + inn]].reshape(-1, 3, 3))
        if not tris:
            continue
        T = np.concatenate(tris)
        nrm = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
        ln = np.linalg.norm(nrm, axis=1)
        ok = ln > 1e-9
        T = T[ok]; ny = np.abs(nrm[ok, 1]) / ln[ok]
        T = T[ny > 0.5]                                     # tops only: kerb faces and walls out
        if len(T) == 0:
            continue
        edge = np.maximum.reduce([np.linalg.norm(T[:, 1] - T[:, 0], axis=1), np.linalg.norm(T[:, 2] - T[:, 1], axis=1), np.linalg.norm(T[:, 0] - T[:, 2], axis=1)])
        k = np.clip(np.ceil(edge / 0.5).astype(int), 1, 16)
        px = []; py = []; pz = []
        for kk in np.unique(k):
            S = T[k == kk]
            ij = [(a / kk, b / kk) for a in range(kk + 1) for b in range(kk + 1 - a)]
            w = np.array([(1 - a - b, a, b) for a, b in ij])           # barycentric samples
            P = np.einsum('sw,twc->tsc', w, S).reshape(-1, 3)
            px.append(P[:, 0]); py.append(P[:, 1]); pz.append(P[:, 2])
        px = np.concatenate(px); py = np.concatenate(py); pz = np.concatenate(pz)
        ci = np.floor(px - U0).astype(np.int64); cj = np.floor(pz - V0).astype(np.int64)
        inb = (ci >= 0) & (ci < NX) & (cj >= 0) & (cj < NY)
        c = (cj * NX + ci)[inb]; y = py[inb]
        order = np.argsort(c, kind='stable'); c = c[order]; y = y[order]
        uc, start = np.unique(c, return_index=True)
        cells_l.append(uc); ids_l.append(np.full(len(uc), n)); lo_l.append(np.minimum.reduceat(y, start)); hi_l.append(np.maximum.reduceat(y, start))
    C = np.concatenate(cells_l); ID = np.concatenate(ids_l); LO = np.concatenate(lo_l); HI = np.concatenate(hi_l)
    cx = (C % NX) + 0.5 + U0; cz = (C // NX) + 0.5 + V0
    th, sea = terrain(cx, cz)
    over = th - HI                                           # > 0: the terrain covers the piece's highest ground in the cell
    # the top piece of every cell (dense), for neighbours
    top_id = np.full(NX * NY, -1, dtype=np.int64); top_lo = np.full(NX * NY, np.nan); top_hi = np.full(NX * NY, -1e9)
    o2 = np.argsort(HI, kind='stable')
    top_id[C[o2]] = ID[o2]; top_lo[C[o2]] = LO[o2]; top_hi[C[o2]] = HI[o2]
    occ = top_id >= 0
    G_id = top_id.reshape(NY, NX); G_lo = top_lo.reshape(NY, NX); G_hi = top_hi.reshape(NY, NX)
    # an edge cell of a piece: one of its four neighbours has no piece at all
    occ2 = occ.reshape(NY, NX)
    free = np.zeros_like(occ2)
    free[:, 1:] |= ~occ2[:, :-1]; free[:, :-1] |= ~occ2[:, 1:]; free[1:, :] |= ~occ2[:-1, :]; free[:-1, :] |= ~occ2[1:, :]
    is_edge = free.reshape(-1)[C]
    hang = (LO - th > 0.30) & is_edge & ~sea
    buried = (over > 0.05) & ~sea
    # steps between different pieces: side by side (the top pieces of two neighbouring cells) ...
    steps = []                                               # [cell, jump, id a, id b]
    for dj, di in ((0, 1), (1, 0)):
        a_id = G_id[:NY - dj, :NX - di]; b_id = G_id[dj:, di:]
        gap = np.maximum(G_lo[:NY - dj, :NX - di] - G_hi[dj:, di:], G_lo[dj:, di:] - G_hi[:NY - dj, :NX - di])
        m = (a_id >= 0) & (b_id >= 0) & (a_id != b_id) & (gap > 0.20)
        jj, ii = np.nonzero(m)
        for q in range(len(jj)):
            steps.append((int(jj[q] * NX + ii[q]), float(gap[jj[q], ii[q]]), int(a_id[jj[q], ii[q]]), int(b_id[jj[q], ii[q]])))
    # how much seam there is between families at all, and how much of it jumps
    fam_ix = {f: i for i, f in enumerate(sorted(set(fams)))}; fam_of = np.array([fam_ix[f] for f in fams] + [0])
    seam_all = collections.Counter(); seam_bad = collections.defaultdict(list)
    for dj, di in ((0, 1), (1, 0)):
        a_id = G_id[:NY - dj, :NX - di]; b_id = G_id[dj:, di:]
        gap = np.maximum(G_lo[:NY - dj, :NX - di] - G_hi[dj:, di:], G_lo[dj:, di:] - G_hi[:NY - dj, :NX - di])
        m = (a_id >= 0) & (b_id >= 0) & (a_id != b_id)
        fa = fam_of[a_id[m]]; fb = fam_of[b_id[m]]; g = gap[m]
        lo_f = np.minimum(fa, fb); hi_f = np.maximum(fa, fb)
        for q in np.unique(lo_f * 100 + hi_f):
            mm = (lo_f * 100 + hi_f) == q
            seam_all[int(q)] += int(mm.sum()); seam_bad[int(q)].extend(g[mm & (g > 0.20)].tolist())
    inv = {i: f for f, i in fam_ix.items()}
    seam_rows = []
    for q, n_all in seam_all.items():
        bad = np.array(seam_bad[q]) if seam_bad[q] else np.array([0.0])
        seam_rows.append((inv[q // 100], inv[q % 100], n_all, len(seam_bad[q]), float(np.median(bad)), float(bad.max())))
    # ... and one over the other in the same cell
    o3 = np.lexsort((HI, C)); C3 = C[o3]; ID3 = ID[o3]; LO3 = LO[o3]; HI3 = HI[o3]
    same = np.nonzero(C3[1:] == C3[:-1])[0]
    stacked = []
    for q in same:
        g = LO3[q + 1] - HI3[q]
        if g > 0.20 and ID3[q] != ID3[q + 1]:
            stacked.append((int(C3[q]), float(g), int(ID3[q]), int(ID3[q + 1])))      # the first is the one underneath

    # ---------------------------------------------------------------- report
    per = collections.defaultdict(lambda: {'cells': 0, 'buried': 0, 'buried30': 0, 'buried100': 0, 'deep': 0.0, 'hang': 0, 'step': 0, 'under': 0})
    fam = collections.defaultdict(lambda: {'pieces': set(), 'cells': 0, 'buried': 0, 'buried30': 0, 'buried100': 0, 'hang': 0, 'step': 0, 'under': 0})
    for n in np.unique(ID):
        m = ID == n; b = buried[m]; ov = over[m]
        p = per[n]; p['cells'] = int(m.sum()); p['buried'] = int(b.sum()); p['buried30'] = int((b & (ov > 0.30)).sum()); p['buried100'] = int((b & (ov > 1.0)).sum())
        p['deep'] = float(ov[b].max()) if b.any() else 0.0; p['hang'] = int(hang[m].sum())
    for c, g, a, b in steps:
        per[a]['step'] += 1; per[b]['step'] += 1
    for c, g, a, b in stacked:
        per[a]['under'] += 1
    for n, p in per.items():
        f = fam[fams[n]]; f['pieces'].add(n)
        for k2 in ('cells', 'buried', 'buried30', 'buried100', 'hang', 'step', 'under'): f[k2] += p[k2]
    print('GROUND-CHECK %d ground meshes, %d m2 of piece ground on the grid' % (len(recs), int(occ.sum())))
    print('%-26s %6s %9s | %8s %8s %8s | %7s | %6s %6s' % ('family', 'pieces', 'm2', 'buried', '>30 cm', '>1 m', 'hanging', 'steps', 'under'))
    for f in sorted(fam):
        v = fam[f]
        print('%-26s %6d %9d | %8d %8d %8d | %7d | %6d %6d' % (f, len(v['pieces']), v['cells'], v['buried'], v['buried30'], v['buried100'], v['hang'], v['step'], v['under']))
    tot = {k2: sum(v[k2] for v in fam.values()) for k2 in ('cells', 'buried', 'buried30', 'buried100', 'hang', 'step', 'under')}
    print('%-26s %6d %9d | %8d %8d %8d | %7d | %6d %6d' % ('ALL', len(per), tot['cells'], tot['buried'], tot['buried30'], tot['buried100'], tot['hang'], tot['step'] // 2, tot['under']))
    worst = sorted(per.items(), key=lambda kv: -kv[1]['buried30'])[:25]
    print('\nMost ground under the terrain (m2 more than 30 cm under), share of the piece, deepest:')
    for n, p in worst:
        if p['buried30'] == 0: break
        print('  %-28s %-14s %6d m2 %3d %%  deepest %.2f m' % (names[n], fams[n], p['buried30'], round(100.0 * p['buried30'] / max(p['cells'], 1)), p['deep']))
    print()
    print('Seams between families: metres of shared edge, metres with a jump over 20 cm, the usual jump, the largest:')
    for r in sorted(seam_rows, key=lambda r: -r[3]):
        if r[3] == 0: continue
        print('  %-26s | %-26s %6d m  %6d m (%2d %%)  usual %.2f m  largest %.2f m' % (r[0], r[1], r[2], r[3], round(100.0 * r[3] / max(r[2], 1)), r[4], r[5]))
    pairs = collections.Counter(); big = collections.defaultdict(float)
    for c, g, a, b in steps:
        key = tuple(sorted((names[a], names[b]))); pairs[key] += 1; big[key] = max(big[key], g)
    print('\nSteps between neighbouring pieces (metres of seam with a jump over 20 cm, the largest jump):')
    for key, cnt in pairs.most_common(25):
        print('  %-28s | %-28s %5d m  up to %.2f m' % (key[0], key[1], cnt, big[key]))
    sp = collections.Counter(); sb = collections.defaultdict(float)
    for c, g, a, b in stacked:
        key = (names[a], names[b]); sp[key] += 1; sb[key] = max(sb[key], g)
    print('\nA piece lying under another piece (m2, the gap between them):')
    for key, cnt in sp.most_common(15):
        print('  %-28s under %-28s %5d m2  up to %.2f m' % (key[0], key[1], cnt, sb[key]))
    json.dump({'families': {f: {k2: (len(v2) if k2 == 'pieces' else v2) for k2, v2 in v.items()} for f, v in fam.items()},
               'pieces': [{'piece': names[n], 'family': fams[n], **p} for n, p in per.items()]}, open(base + '_check.json', 'w'), indent=1)
    if pic:
        from PIL import Image
        Image.MAX_IMAGE_PIXELS = None
        im = np.array(Image.open(pic).convert('RGB')).astype(np.float32)

        def paint(cells, col, a=0.75):
            x = (cells % NX) + U0; z = (cells // NX) + V0
            pxx = ((x + 1600.0) * 2).astype(int); pzz = ((z + 1800.0) * 2).astype(int)
            for dx in (0, 1):
                for dz in (0, 1):
                    okk = (pxx + dx >= 0) & (pxx + dx < im.shape[1]) & (pzz + dz >= 0) & (pzz + dz < im.shape[0])
                    im[pzz[okk] + dz, pxx[okk] + dx] = im[pzz[okk] + dz, pxx[okk] + dx] * (1 - a) + np.array(col, dtype=np.float32) * a
        paint(C[buried & (over > 0.30)], (230, 30, 30)); paint(C[buried & (over <= 0.30)], (255, 140, 60), 0.5)
        paint(C[hang], (40, 90, 255))
        if steps: paint(np.array([s[0] for s in steps]), (255, 235, 0), 1.0)
        outp = pic.rsplit('.', 1)[0] + '_ground.jpg'
        big_im = Image.fromarray(im.astype(np.uint8)); big_im.save(outp, quality=88)
        big_im.resize((big_im.width * 3 // 8, big_im.height * 3 // 8), Image.LANCZOS).save(pic.rsplit('.', 1)[0] + '_ground_small.jpg', quality=88)
        print('\npicture: %s (red = more than 30 cm under the terrain, orange = 5-30 cm, blue = hanging edge, yellow = step)' % outp)


main()
