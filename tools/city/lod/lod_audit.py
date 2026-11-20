#!/usr/bin/env python3
"""LOD match audit (Yasin, 20 Nov: "mid and far ones need to look as similar as possible to the near ones").
For every kit building / modular example: render near, mid, far with glbr (same frame, 5 views), compare
near vs mid at the 60 m switch (6.4 px/m: Redmi 2460x1080 at 3D scale 0.5, 70 deg vertical FOV) and mid vs far at
220 m (1.75 px/m). Writes <out>/audit.json and per-building strips <out>/strips/<name>_<pair>.png.
usage: lod_audit.py OUT [--kit=DIR] [--only=a,b] [--jobs=4]"""
import sys, os, json, glob, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import glbr
from multiprocessing import Pool
VIEWS = [(0, 8), (90, 8), (180, 8), (270, 8), (40, 28)]
PPM_HI = 12.8
SW = {'near_mid': 6.4, 'mid_far': 1.75, 'near_far': 1.75}

def find(kit):
    out = []
    for d in sorted(glob.glob(kit + '/buildings/*/*/')) + sorted(glob.glob(kit + '/modular/examples*/*/')):
        t = {}
        for tier in ('near', 'mid', 'far'):
            f = glob.glob(d + '*_%s.glb' % tier)
            if f: t[tier] = f[0]
        if len(t) == 3: out.append((d.rstrip('/').split('/')[-2] + '/' + d.rstrip('/').split('/')[-1], t))
    dump = os.environ.get('CK_DUMP', '/tmp/ck_dump')      # city-kit merged buildings (.scn), dumped by dump_mesh.gd
    for j in sorted(glob.glob(dump + '/*_near.json')):
        nm = os.path.basename(j)[:-10]; t = {k: j.replace('_near.json', '_%s.json' % k) for k in ('near', 'mid', 'far')}
        if all(os.path.exists(v) for v in t.values()): out.append(('ck/' + nm, t))
    return out

def lum(a): return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114

def compare(A, aA, B, aB):
    """A,B composed srgb (same size); aA,aB alpha"""
    un = (aA > 0.5) | (aB > 0.5); it = (aA > 0.5) & (aB > 0.5)
    iou = it.sum() / max(1, un.sum())
    d = np.abs(A - B).mean(-1)
    mad = float(d[un].mean()) if un.any() else 0.0
    lA, lB = lum(A), lum(B)
    dark = lambda l, m: float((l[m] < 0.3).mean()) if m.any() else 0.0
    gA, gB = dark(lA, it), dark(lB, it)
    # floor-band structure: row profiles of luminance inside the common silhouette, high-passed
    def prof(l, m):
        r = np.array([l[i][m[i]].mean() if m[i].sum() > 2 else np.nan for i in range(l.shape[0])])
        return r
    pA, pB = prof(lA, it), prof(lB, it); ok = ~(np.isnan(pA) | np.isnan(pB))
    corr = 1.0
    if ok.sum() > 6:
        x, y = pA[ok] - np.convolve(pA[ok], np.ones(5) / 5, 'same'), pB[ok] - np.convolve(pB[ok], np.ones(5) / 5, 'same')
        if x.std() > 0.01 and y.std() > 0.01: corr = float(np.corrcoef(x, y)[0, 1])
        elif x.std() > 0.02 or y.std() > 0.02: corr = 0.0      # bands in one, none in the other
    return dict(iou=round(float(iou), 3), mad=round(mad, 4), dark_a=round(gA, 3), dark_b=round(gB, 3), band_corr=round(corr, 3))

def one(job):
    name, t, out = job
    try:
        M = {k: glbr.load_any(v) for k, v in t.items()}
        for k, m in M.items():
            if m['albedo'] and m['albedo'].endswith('bld_lod_color.png'): m['glass_alpha'] = True
        res = {'name': name, 'files': t, 'tris': {k: int(len(m['I'])) for k, m in M.items()}, 'views': []}
        strips = {p: [] for p in SW}
        for az, el in VIEWS:
            b = None
            # common frame: union of all tiers' extents
            R, U, F = glbr.view_basis(az, el)
            P = np.concatenate([m['P'] for m in M.values()])
            u, v = P @ R, P @ U; b = (u.min() - 1, u.max() + 1, v.min() - 1, v.max() + 1)
            R_ = {}
            for k, m in M.items():
                orm = M['near']['orm'] if (k == 'mid' and not m.get('glass_alpha')) else None
                rgb, a, _ = glbr.render(m, az, el, PPM_HI, b, orm=orm)
                R_[k] = (glbr.compose(rgb, a), a)
            vr = {'view': [az, el]}
            for pair, ppm in SW.items():
                x, y = pair.split('_'); f = PPM_HI / ppm
                A, aA = glbr.down(R_[x][0], f), glbr.down(R_[x][1], f)
                B, aB = glbr.down(R_[y][0], f), glbr.down(R_[y][1], f)
                vr[pair] = compare(A, aA, B, aB)
                if (az, el) in [(40, 28), (0, 8)]: strips[pair].append(np.concatenate([glbr.down(R_[x][0], PPM_HI / 6.4), glbr.down(R_[y][0], PPM_HI / 6.4)], 1))
            res['views'].append(vr)
        for pair in SW:
            s = res['agg_' + pair] = {k: round(float(np.mean([v[pair][k] for v in res['views']])), 3) for k in ('iou', 'mad', 'band_corr')}
            s['dark_diff'] = round(float(np.mean([abs(v[pair]['dark_a'] - v[pair]['dark_b']) for v in res['views']])), 3)
            # one number: colour error + silhouette + glass share + lost banding
            s['score'] = round(s['mad'] * 4 + (1 - s['iou']) * 2 + s['dark_diff'] * 2 + max(0.0, 0.8 - s['band_corr']) * 0.5, 3)
            os.makedirs(out + '/strips', exist_ok=True)
            hmax = max(i.shape[0] for i in strips[pair]); pad = [np.pad(i, ((0, hmax - i.shape[0]), (0, 4), (0, 0)), constant_values=1.0) for i in strips[pair]]
            glbr.to_img(np.concatenate(pad, 1)).save(out + '/strips/%s_%s.png' % (name.replace('/', '__'), pair))
        return res
    except Exception as e:
        import traceback; return {'name': name, 'error': traceback.format_exc()}

if __name__ == '__main__':
    out = sys.argv[1]; kit = '/workspace/NewMap/assets/coronado_kit'; only = None; jobs = 4
    for a in sys.argv[2:]:
        if a.startswith('--kit='): kit = a[6:]
        if a.startswith('--only='): only = set(a[7:].split(','))
        if a.startswith('--jobs='): jobs = int(a[7:])
    items = [(n, t, out) for n, t in find(kit) if not only or n.split('/')[-1] in only]
    os.makedirs(out, exist_ok=True)
    with Pool(jobs) as p: R = p.map(one, items, chunksize=1)
    json.dump(R, open(out + '/audit.json', 'w'), indent=1)
    ok = [r for r in R if 'error' not in r]
    for pair in SW:
        print('== worst', pair)
        for r in sorted(ok, key=lambda r: -r['agg_' + pair]['score'])[:15]: print('  %-40s %s tris %s' % (r['name'], r['agg_' + pair], r['tris']))
    for r in R:
        if 'error' in r: print('ERR', r['name'], r['error'][-300:])
