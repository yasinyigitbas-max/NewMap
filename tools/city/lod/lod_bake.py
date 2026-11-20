#!/usr/bin/env python3
"""LOD match bake (Yasin, 20 Nov 2026: "our buildings mid and far looks are too different and we can clearly see them snap
into view ... Mid and far ones need to look as similar as possible to the near ones, at least in geometry if not detail.
Now some buildings look like covered with glass completely but once we are near we see that there are cement sections in
between the glass layers").

Why: the kit's generator made the mid and far tiers from their own simplified recipes, not from the near model:
 - mid: `mid_ops` (kit tools city_urban.py) merged every column of upper windows into ONE floor-to-roof glass strip
   (towers, offices, the mall, the hospital / university, merged modular rows), and walls / roofs became flat swatches;
 - far: a box hull painted with a GENERIC tiled facade from far_color.png (F_c_tower_3, F_c_apt_3 ...): wrong storey
   count, wrong colours (a red brick block turned cream), windows where the near has none.
What this does: keeps each mid / far mesh's GEOMETRY (outline, setbacks, roofs: within the tier budgets, node names,
file names) and replaces its TEXTURE by the near model itself, projected onto every face of the mid and the far hull
(an orthographic bake of the near's albedo x vertex colour, so its floor bands, spandrels, brick, signs, roof colour
and baked AO come along). All buildings share ONE page (textures/bld_lod_color.png, RGBA: alpha = 1 - glass, so the
mid's glass still reflects the sky like the near's). The far hull reuses the mid's texels where it lies in the same
plane. Small parts the mid drops (rails, lamps, sills) are painted onto the faces behind them.

usage: lod_bake.py [--only=a,b] [--density=PX_PER_M] [--dry] [--jobs=N]
       lod_bake.py --unused --page=bld_lod_color_b.png --report=lod_match_b.json   (the types no piece places yet: page B)
writes: textures/bld_lod_color.png, every <name>_mid.glb / _far.glb in place (kit buildings + modular examples),
        and for the city-kit merged buildings (.scn) a dump in /tmp/lod_ck_out for apply_ck.gd."""
import sys, os, json, glob, math, hashlib, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import glbr, lod_audit
from PIL import Image
from multiprocessing import Pool
REPO = '/workspace/NewMap'; KIT = REPO + '/assets/coronado_kit'
PAGE = KIT + '/textures/bld_lod_color.png'
PW = PH = int(os.environ.get('LOD_PAGE_PX', 2048))      # page B (unplaced types): LOD_PAGE_PX=1024
PAD = 3            # gutter px around every chart (mip 1-2 safe)
SS = 2             # supersampling of the bake
DIN, DOUT = 0.6, 1.6   # slab around a face: near geometry from 0.6 m behind to 1.6 m in front of the plane is baked

def tri_planes(m):
    P, I = m['P'], m['I']
    n = np.cross(P[I[:, 1]] - P[I[:, 0]], P[I[:, 2]] - P[I[:, 0]]); a = np.linalg.norm(n, axis=1)
    ok = a > 1e-10; n[ok] /= a[ok][:, None]
    d = np.einsum('ij,ij->i', n, P[I[:, 0]])
    return n, d, a * 0.5, ok

def charts_of(m, angle=0.995, dist=0.03):
    """connected coplanar triangle groups -> [dict(tris, n, d, R, U, F)]"""
    P, I = m['P'], m['I']; n, d, area, ok = tri_planes(m)
    key = np.round(P * 1000).astype(np.int64)
    vid = {}
    for k, row in enumerate(map(tuple, key)): vid.setdefault(row, len(vid))
    V = np.array([vid[tuple(r)] for r in key])
    par = list(range(len(I)))
    def f(x):
        while par[x] != x: par[x] = par[par[x]]; x = par[x]
        return x
    by_v = {}
    for t in np.nonzero(ok)[0]:
        for v in V[I[t]]: by_v.setdefault(v, []).append(t)
    for v, ts in by_v.items():
        for i in range(len(ts)):
            for j in range(i + 1, len(ts)):
                a, b = ts[i], ts[j]
                if n[a] @ n[b] > angle and abs(d[a] - d[b]) < dist:
                    ra, rb = f(a), f(b)
                    if ra != rb: par[ra] = rb
    groups = {}
    for t in np.nonzero(ok)[0]: groups.setdefault(f(t), []).append(t)
    out = []
    for g in groups.values():
        g = np.array(g); w = area[g]
        nn = (n[g] * w[:, None]).sum(0); nn /= max(1e-9, np.linalg.norm(nn))
        dd = float((d[g] * w).sum() / max(1e-12, w.sum()))
        F = -nn
        up0 = np.array([0.0, 1.0, 0.0]) if abs(nn[1]) < 0.9 else np.array([0.0, 0.0, -1.0])
        R = np.cross(F, up0); R /= np.linalg.norm(R); U = np.cross(R, F)
        pts = P[I[g].ravel()]
        out.append(dict(tris=g, n=nn, d=dd, R=R, U=U, F=F, area=float(w.sum()),
                        rect=(float((pts @ R).min()), float((pts @ R).max()), float((pts @ U).min()), float((pts @ U).max()))))
    return out

VOX = 0.5
def hull(m, lo, shape):
    """visual hull from 3 orthographic silhouettes (front, side, top) on a VOX grid: a voxel is in when all three see it"""
    from scipy import ndimage
    X, Y, Z = shape
    sil = {}
    for ax, (R, U) in {'z': (np.array([1.0, 0, 0]), np.array([0, 1.0, 0])), 'x': (np.array([0, 0, 1.0]), np.array([0, 1.0, 0])), 'y': (np.array([1.0, 0, 0]), np.array([0, 0, 1.0]))}.items():
        F = np.cross(U, R)
        lo_u, lo_v = lo @ R, lo @ U
        nu = {'z': X, 'x': Z, 'y': X}[ax]; nv = {'z': Y, 'x': Y, 'y': Z}[ax]
        b = (lo_u, lo_u + nu * VOX, lo_v, lo_v + nv * VOX)
        _, cov, _, _ = glbr.render_basis(m, R, U, F, 1.0 / VOX * 2, b, mode='albedo', cull=False)
        cov = cov.reshape(nv, 2, nu, 2).max((1, 3))[::-1]        # rows bottom-up, 1 cell = VOX
        sil[ax] = ndimage.binary_closing(cov > 0.5, iterations=1) | (cov > 0.5)
    H = sil['z'].T[:, :, None] & sil['x'].T[None, :, :] & sil['y'][None, :, :].transpose(0, 2, 1).transpose(2, 0, 1).transpose(1, 2, 0)[:, None, :] if False else None
    sz, sx, sy = sil['z'], sil['x'], sil['y']        # sz[y, x], sx[y, z], sy[z, x]
    Hh = sz.T[:, :, None] & sx[None, :, :] & sy.T[:, None, :]
    return Hh, sil

def surface_vox(m, lo, shape, step=0.2):
    """voxels touched by the model's surface (points sampled every ~step m on each triangle)"""
    P, I = m['P'], m['I']; occ = np.zeros(shape, bool)
    a, b, c = P[I[:, 0]], P[I[:, 1]], P[I[:, 2]]
    L = np.maximum(np.linalg.norm(b - a, axis=1), np.linalg.norm(c - a, axis=1)); n = np.clip(np.ceil(L / step).astype(int), 1, 200)
    for k in np.unique(n):
        sel = n == k; g = np.linspace(0, 1, k + 1)
        u, v = np.meshgrid(g, g); ok = (u + v) <= 1.0; u, v = u[ok], v[ok]
        pts = a[sel][:, None] + (b[sel] - a[sel])[:, None] * u[None, :, None] + (c[sel] - a[sel])[:, None] * v[None, :, None]
        ix = np.floor((pts.reshape(-1, 3) - lo) / VOX).astype(int)
        ok2 = np.all((ix >= 0) & (ix < np.array(shape)), axis=1); ix = ix[ok2]
        occ[ix[:, 0], ix[:, 1], ix[:, 2]] = True
    return occ

def shell_occ(S, a, b):
    """share of a box's side + top shell cells that hold near surface (the bottom is the ground: not asked)"""
    x0, y0, z0 = a; x1, y1, z1 = b
    tot = hit = 0
    for sl in (S[x0:x1, y0:y1, z0], S[x0:x1, y0:y1, z1 - 1], S[x0, y0:y1, z0:z1], S[x1 - 1, y0:y1, z0:z1], S[x0:x1, y1 - 1, z0:z1]):
        tot += sl.size; hit += sl.sum()
    return hit / max(1, tot)

def far_boxes(near, far, room, cost=10):
    """boxes for the masses the far hull leaves out (a canopy, a porch, a wing), biggest gain first, within `room`
    triangles. A box must be a real mass: at least 45 % of its side and top cells hold the near's surface (so a
    canopy on posts gives a slab at the canopy's height, not a solid block down to the ground)."""
    from scipy import ndimage
    if room < cost: return []
    P = np.concatenate([near['P'], far['P']]); lo = P.min(0) - VOX; hi = P.max(0) + VOX
    shape = tuple(int(np.ceil(v)) for v in (hi - lo) / VOX)
    if np.prod(shape) > 6e6: return []
    Hn, sn = hull(near, lo, shape); Hf, sf = hull(far, lo, shape)
    S = surface_vox(near, lo, shape)
    miss = Hn & ~ndimage.binary_dilation(Hf, iterations=1)
    lab, k = ndimage.label(miss)
    cands = []
    def fit(cells, depth=0):
        if len(cells) < 4: return
        a, b = cells.min(0), cells.max(0) + 1
        if shell_occ(S, a, b) >= 0.45 and len(cells) / np.prod(b - a) >= 0.5:
            cands.append((a, b, len(cells))); return
        if depth >= 6: return
        # split where the near's surface density changes most (canopy band / open space under it)
        best = None
        for ax in range(3):
            if b[ax] - a[ax] < 2: continue
            prof = np.array([S[tuple(slice(a[i], b[i]) if i != ax else j for i in range(3))].mean() for j in range(a[ax], b[ax])])
            for cut in range(1, len(prof)):
                sc = abs(prof[:cut].mean() - prof[cut:].mean())
                if best is None or sc > best[0]: best = (sc, ax, a[ax] + cut)
        if best is None: return
        _, ax, cut = best
        fit(cells[cells[:, ax] < cut], depth + 1); fit(cells[cells[:, ax] >= cut], depth + 1)
    for i in range(1, k + 1):
        c = np.argwhere(lab == i)
        if len(c) * VOX ** 3 < 2.0: continue
        fit(c)
    def gain(a, b):
        g = 0.0
        for ax, s in (('z', sf['z']), ('x', sf['x']), ('y', sf['y'])):
            if ax == 'z': blk = s[a[1]:b[1], a[0]:b[0]]
            elif ax == 'x': blk = s[a[1]:b[1], a[2]:b[2]]
            else: blk = s[a[2]:b[2], a[0]:b[0]]
            g += (~blk).sum() * VOX * VOX
        return g
    cands = sorted(((gain(a, b), a, b) for a, b, n in cands), key=lambda x: -x[0])
    out = []
    for g, a, b in cands:
        if room < cost or g < 4.0: break
        out.append((lo + a * VOX, lo + b * VOX)); room -= cost
    return out

def box_mesh(boxes):
    P, N, I = [], [], []
    for (a, b) in boxes:
        x0, y0, z0 = a; x1, y1, z1 = b
        faces = [((x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1), (0, 0, 1)), ((x1, y0, z0), (x0, y0, z0), (x0, y1, z0), (x1, y1, z0), (0, 0, -1)),
                 ((x1, y0, z1), (x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (1, 0, 0)), ((x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0), (-1, 0, 0)),
                 ((x0, y1, z1), (x1, y1, z1), (x1, y1, z0), (x0, y1, z0), (0, 1, 0))]
        for *q, n in faces:
            base = len(P); P += q; N += [n] * 4; I += [(base, base + 1, base + 2), (base, base + 2, base + 3)]
    return np.array(P, float), np.array(N, float), np.array(I, np.int64)

CK_BLD = REPO + '/map_dc/coronado/city_kit/buildings/'
def budget_of(t):
    """[near, mid, far] maximums (SPEC section 4) and the class. Kit buildings: their stats.json (the generator scaled
    the class by units: per 10 storeys, per 6 m of frontage...). City-kit merged buildings (no budget in their stats):
    the SPEC class by kind, scaled the same way: shop / service rows and the fast-food per 6 m of frontage, apartment
    rows up to 30 m long one apartment block, the storage row a warehouse, the distribution centre one warehouse per
    24 x 24 m shed it is made of."""
    if not t['near'].endswith('.json'):
        st = os.path.join(os.path.dirname(t['near']), 'stats.json')
        if os.path.exists(st):
            j = json.load(open(st))
            if j.get('budget'): return [int(v) for v in j['budget']], j.get('budget_class', j.get('cat', '?')) + (' x%g' % j['budget_units'] if j.get('budget_units') else '')
        # a modular assembly without a budget in its stats: the class by name, its size from the near
        nm = os.path.basename(os.path.dirname(t['near']))
        P = glbr.load_any(t['near'])['P']; w, d = float(np.ptp(P[:, 0])), float(np.ptp(P[:, 2])); h = float(P[:, 1].max())
    else:
        nm = os.path.basename(t['near'])[:-len('_near.json')]
        st = json.load(open(CK_BLD + nm + '/stats.json')); w, d = st['footprint_wd']; h = st.get('height', 10.0)
    w = max(6.0, round(w / 6.0) * 6.0)
    if 'twr' in nm:
        u = max(1.0, round(h / 3.3) / 10.0); return [int(4000 * u), int(1200 * u), int(80 * u)], 'tower per 10 storeys x%g' % u
    if 'house' in nm or 'garage' in nm: return [1650, 500, 40], 'mod_house_small (snap-in house)'
    if 'civ_' in nm: return [5000, 1500, 120], 'civic'
    if 'bank' in nm: return [2500, 750, 60], 'corner shop / bank'
    if '_svc_' in nm or 'fastfood' in nm or '_grt_' in nm or 'shop' in nm or 'svb_' in nm or 'svc_' in nm:
        u = w / 6.0; return [int(1200 * u), int(350 * u), int(20 * u)], 'shop bay per 6 m x%g' % u
    if 'apt3_' in nm or 'brk3_' in nm or nm in ('apt_row', 'brk_row'): return ([3500, 1000, 80], 'apartment block') if w <= 30 else ([5000, 1500, 120], 'large apartment block')
    if 'wh_dist' in nm:
        u = round(w * d / 576.0); return [2000 * u, 600 * u, 40 * u], 'warehouse x%d sheds' % u
    if 'stg_row' in nm or 'wh_shed' in nm: return [2000, 600, 40], 'warehouse (storage row)'
    return [3500, 1000, 80], 'apartment block (default)'

def far_budget(t): return budget_of(t)[0][2]

def plan(name, t, dens):
    """charts for one building: mid charts, far charts mapped into mid charts where coplanar"""
    near, mid, far = (glbr.load_any(t[k]) for k in ('near', 'mid', 'far'))
    nf0 = nf_orig = len(far['I']); budget = far_budget(t); rehull = False
    if nf0 > budget and os.environ.get('LOD_REHULL', '1') == '1':
        # the far is over its budget (city-kit rows merged from the modules' own fars): a new far from boxes only,
        # fitted to the near's masses the same way, within the budget
        # (one closed box of the old far's extent first, so the hull is never open; boxes only for what sticks out)
        bp, bn, bi = box_mesh([(far['P'].min(0), far['P'].max(0))])
        far = dict(far, P=bp, N=bn, I=bi, UV=np.zeros((len(bp), 2)), C=np.ones((len(bp), 4))); nf0 = 0; rehull = True
        budget_left = budget - len(bi)
    boxes = far_boxes(near, far, (budget_left if rehull else budget - nf0)) if os.environ.get('LOD_BOXES', '1') == '1' else []
    if boxes:
        bp, bn, bi = box_mesh(boxes)
        far = dict(far, P=np.concatenate([far['P'], bp]), N=np.concatenate([far['N'], bn]), I=np.concatenate([far['I'], bi + len(far['P'])]),
                   UV=np.concatenate([far['UV'], np.zeros((len(bp), 2))]), C=np.concatenate([far['C'], np.ones((len(bp), 4))]))
    cm = charts_of(mid); cf = charts_of(far)
    for c in cf: c['box'] = bool(np.all(c['tris'] >= nf0))
    for c in cm: c['own'] = True
    for c in cf:
        c['host'] = None
        for j, h in enumerate(cm):
            if c['n'] @ h['n'] < 0.99 or abs(c['d'] - h['d']) > 0.35: continue
            pts = far['P'][far['I'][c['tris']].ravel()]
            u, v = pts @ h['R'], pts @ h['U']; r = h['rect']; tol = 0.25
            if u.min() >= r[0] - tol and u.max() <= r[1] + tol and v.min() >= r[2] - tol and v.max() <= r[3] + tol:
                c['host'] = j; break
        c['own'] = c['host'] is None
    sizes = []
    for c in cm + cf:
        if not c['own']: continue
        r = c['rect']; w = int(math.ceil((r[1] - r[0]) * dens)) + 2 * PAD; h = int(math.ceil((r[3] - r[2]) * dens)) + 2 * PAD
        c['wh'] = (max(w, 2 * PAD + 2), max(h, 2 * PAD + 2)); sizes.append(c['wh'])
    return dict(name=name, files=t, cm=cm, cf=cf, tris={'near': len(near['I']), 'mid': len(mid['I']), 'far': nf_orig}, far_budget=budget, rehull=rehull, boxes=[(list(map(float, a)), list(map(float, b))) for a, b in boxes],
                far_geo=dict(P=far['P'], N=far['N'], I=far['I']))

def pack(charts, W, H):
    """shelf packing, tallest first; returns False if it does not fit"""
    order = sorted(range(len(charts)), key=lambda i: (-charts[i]['wh'][1], -charts[i]['wh'][0]))
    x = y = sh = 0
    for i in order:
        w, h = charts[i]['wh']
        if w > W: return False
        if x + w > W: x = 0; y += sh; sh = 0
        if y + h > H: return False
        charts[i]['xy'] = (x, y); x += w; sh = max(sh, h)
    return True

def dilate(rgb, cov, it=12):
    rgb = rgb.copy(); cov = cov.copy()
    for _ in range(it):
        if cov.all(): break
        acc = np.zeros_like(rgb); cnt = np.zeros(cov.shape, np.float32)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            r = np.roll(np.roll(rgb, dy, 0), dx, 1); c = np.roll(np.roll(cov, dy, 0), dx, 1)
            acc += r * c[..., None]; cnt += c
        new = (~cov.astype(bool)) & (cnt > 0)
        rgb[new] = acc[new] / cnt[new][:, None]; cov = cov.astype(bool) | new
    if not cov.all():
        m = rgb[cov.astype(bool)].mean(0) if cov.any() else np.array([0.7, 0.7, 0.7])
        rgb[~cov.astype(bool)] = m
    return rgb

def bake_chart(near, src, c, dens):
    """the chart's pixels (h, w, 4): RGB sRGB of the near (src tier's own texture where the near has nothing), A = 1 - glass"""
    w, h = c['wh']; r = c['rect']
    u0 = r[0] - PAD / dens; v1 = r[3] + PAD / dens
    b = (u0, u0 + w / dens, v1 - h / dens, v1)
    zf = -c['d']
    zwin = (zf - DOUT, zf + DIN)
    # the slab grows until the near covers the face: far hulls sit at the parapet's top, the roof deck lies lower
    for din in ((DIN, 2.0, 5.0) if c['n'][1] > 0.5 else (DIN, 1.5, 3.0)):
        rgb, cov, gl, _ = glbr.render_basis(near, c['R'], c['U'], c['F'], dens * SS, b, zwin=(zf - DOUT, zf + din), mode='albedo')
        if cov.mean() > 0.9: break
    if cov.mean() < 0.999:      # what the near leaves empty in the slab: the tier's own look
        rgb2, cov2, _, _ = glbr.render_basis(src, c['R'], c['U'], c['F'], dens * SS, b, zwin=(zf - 0.4, zf + 0.4), mode='albedo', cull=False)
        hole = (cov < 0.5) & (cov2 > 0.5)
        rgb[hole] = rgb2[hole]; cov = np.maximum(cov, cov2)
    rgb = dilate(rgb, cov > 0.5)
    # box-filter down to the page density (supersampled bake = smooth edges, no shimmer)
    H2, W2 = rgb.shape[:2]
    rgb = rgb[:h * SS, :w * SS].reshape(h, SS, w, SS, 3).mean((1, 3)) if (H2 >= h * SS and W2 >= w * SS) else np.asarray(Image.fromarray((rgb * 255).astype(np.uint8)).resize((w, h), Image.BOX)) / 255.0
    gl = gl[:h * SS, :w * SS].reshape(h, SS, w, SS).mean((1, 3)) if (gl.shape[0] >= h * SS and gl.shape[1] >= w * SS) else np.zeros((h, w))
    return np.dstack([rgb, 1.0 - gl])

def new_mesh(m, charts, cf_hosts, page_charts, dens):
    """per-chart vertex split; UV into the page. returns (P, N, UV, I) in the tier's world frame"""
    P, I, N = m['P'], m['I'], m['N']
    outP, outN, outUV, outI = [], [], [], []
    tri_chart = {}
    for c in charts:
        hc = c if c['own'] else page_charts[c['host']]
        for t in c['tris']: tri_chart[int(t)] = hc
    nv = 0
    for c_id in set(id(v) for v in tri_chart.values()):
        pass
    cache = {}
    n_t, _, _, okt = tri_planes(m)
    for t in range(len(I)):
        hc = tri_chart.get(t)
        if hc is None: continue      # degenerate
        x0, y0 = hc['xy']; r = hc['rect']; w, h = hc['wh']
        u0 = r[0] - PAD / dens; v1 = r[3] + PAD / dens
        tri = []
        for vi in I[t]:
            k = (id(hc), int(vi))
            if k not in cache:
                p = P[vi]
                px = x0 + np.clip((p @ hc['R'] - u0) * dens, 0.5, w - 0.5); py = y0 + np.clip((v1 - p @ hc['U']) * dens, 0.5, h - 0.5)
                cache[k] = nv; nv += 1
                outP.append(p); outN.append(N[vi] if np.linalg.norm(N[vi]) > 0.1 else n_t[t]); outUV.append((px / PW, py / PH))
            tri.append(cache[k])
        outI.append(tri)
    return np.array(outP), np.array(outN), np.array(outUV), np.array(outI, dtype=np.int64)

# ------------------------------------------------------------------ driver
SWATCH = 4         # a small or downward face gets one flat 4 x 4 texel cell (uniform: no mip bleed)
def classify(c):
    r = c['rect']; w, h = r[1] - r[0], r[3] - r[2]
    c['swatch'] = bool(c['n'][1] < -0.5 or min(w, h) < 0.4 or w * h < 1.0)

def size_charts(p, dens):
    for c in p['cm'] + p['cf']:
        if not c['own']: continue
        classify(c)
        if c['swatch']: c['wh'] = (SWATCH, SWATCH); continue
        r = c['rect']
        c['wh'] = (int(math.ceil((r[1] - r[0]) * dens)) + 2 * PAD, int(math.ceil((r[3] - r[2]) * dens)) + 2 * PAD)

def density_of(name, base):
    if name.endswith('pub_stadium'): return base * 0.35     # 200 m across, used once: seen from afar
    return base

def _plan_job(a): return plan(a[0], a[1], 1.0)

def _bake_job(a):
    p, dens = a
    near = glbr.load_any(p['files']['near']); tiers = {'mid': glbr.load_any(p['files']['mid']), 'far': glbr.load_any(p['files']['far'])}
    outs = []
    for key, src in (('cm', tiers['mid']), ('cf', tiers['far'])):
        for c in p[key]:
            if not c['own']: continue
            if c['swatch']:
                cc = dict(c); cc['wh'] = (max(3, int(math.ceil((c['rect'][1] - c['rect'][0]) * 4)) + 2 * PAD), max(3, int(math.ceil((c['rect'][3] - c['rect'][2]) * 4)) + 2 * PAD))
                px = bake_chart(near, src, cc, 4.0)
                outs.append(np.broadcast_to(px.reshape(-1, 4).mean(0), (SWATCH, SWATCH, 4)).copy())
            else:
                outs.append(bake_chart(near, tiers['mid'] if c.get('box') else src, c, dens))
    return outs

def main():
    args = dict(a[2:].split('=', 1) if '=' in a else (a[2:], '1') for a in sys.argv[1:] if a.startswith('--'))
    jobs = int(args.get('jobs', 5))
    census = json.load(open(args.get('census', '/workspace/NewMap_review/lod_match/census.json')))
    items = []
    for n, t in lod_audit.find(KIT):
        grp, nm = n.split('/')
        k = n if grp == 'ck' else ('modular/' + n if grp.startswith('examples') else n)
        if 'only' in args and nm not in args['only'].split(','): continue
        if 'only' not in args and (k in census) == ('unused' in args): continue      # --unused: the kit's types no piece places (page B)
        items.append((n, t))
    print('buildings', len(items), flush=True)
    with Pool(jobs) as pool: plans = pool.map(_plan_job, items, chunksize=1)
    # the densest page that fits
    lo, hi = 1.0, float(args.get('density', 8.0)); best = None
    for _ in range(14):
        d = (lo + hi) / 2
        allc = []
        for p in plans:
            size_charts(p, density_of(p['name'], d)); allc += [c for c in p['cm'] + p['cf'] if c['own']]
        if pack(allc, PW, PH): lo = d; best = d
        else: hi = d
    d = float(args['fixdens']) if 'fixdens' in args else best
    allc = []
    for p in plans:
        p['dens'] = density_of(p['name'], d); size_charts(p, p['dens']); allc += [c for c in p['cm'] + p['cf'] if c['own']]
    assert pack(allc, PW, PH)
    used = sum(c['wh'][0] * c['wh'][1] for c in allc) / (PW * PH)
    print('density %.2f px/m, %d charts, page fill %.0f %%' % (d, len(allc), used * 100), flush=True)
    if 'dry' in args: return
    global PAGE
    if 'page' in args: PAGE = KIT + '/textures/' + args['page']
    if 'test' in args: PAGE = args['test'] + '/bld_lod_color.png'; os.makedirs(args['test'], exist_ok=True)
    with Pool(jobs) as pool: res = pool.map(_bake_job, [(p, p['dens']) for p in plans], chunksize=1)
    page = np.zeros((PH, PW, 4), np.float32); page[..., 3] = 1.0; page[..., :3] = 0.5
    for p, outs in zip(plans, res):
        k = 0
        for key in ('cm', 'cf'):
            for c in p[key]:
                if not c['own']: continue
                x, y = c['xy']; w, h = c['wh']; px = outs[k]; k += 1
                page[y:y + h, x:x + w] = px[:h, :w]
    Image.fromarray((np.clip(page, 0, 1) * 255 + 0.5).astype(np.uint8), 'RGBA').save(PAGE)
    # meshes
    report = []
    for p in plans:
        bud, cls = budget_of(p['files'])
        r = {'name': p['name'], 'tris_before': p['tris'], 'dens': round(p['dens'], 2), 'far_budget': p['far_budget'], 'budget': bud, 'budget_class': cls, 'far_rehull': p.get('rehull', False), 'far_boxes': len(p['boxes'])}
        for tier, key in (('mid', 'cm'), ('far', 'cf')):
            src = glbr.load_any(p['files'][tier]) if tier == 'mid' else p['far_geo']
            P, N, UV, I = new_mesh(src, p[key], None, p['cm'], p['dens'])
            if 'test' in args:
                np.savez(args['test'] + '/%s_%s.npz' % (p['name'].replace('/', '__'), tier), P=P, N=N, UV=UV, I=I)
            else: write_tier(p['files'][tier], P, N, UV, I)
            r['tris_' + tier] = int(len(I))
        report.append(r)
    if 'test' in args: return
    json.dump({'density': d, 'page': [PW, PH], 'page_file': os.path.basename(PAGE), 'fill': used, 'buildings': report}, open(REPO + '/assets/coronado_kit/reports/' + args.get('report', 'lod_match.json'), 'w'), indent=1)
    print('done', len(report), flush=True)

def write_tier(path, P, N, UV, I):
    if path.endswith('.json'): return write_ck(path, P, N, UV, I)
    g = pygltf_new(path, P, N, UV, I)

def pygltf_new(path, P, N, UV, I):
    import pygltflib as G
    old = G.GLTF2().load(path)
    nodename = old.nodes[0].name; meshname = old.meshes[0].name; matname = old.materials[0].name
    rel = os.path.relpath(PAGE, os.path.dirname(path))
    P = P.astype(np.float32); N = N.astype(np.float32); N /= np.maximum(1e-9, np.linalg.norm(N, axis=1))[:, None]
    UV = UV.astype(np.float32); C = np.ones((len(P), 4), np.float32); idx = I.astype(np.uint32).ravel()
    blobs = [P.tobytes(), N.tobytes(), UV.tobytes(), C.tobytes(), idx.tobytes()]
    off = 0; views = []; data = b''
    for b in blobs:
        views.append(G.BufferView(buffer=0, byteOffset=off, byteLength=len(b), target=34963 if b is blobs[-1] else 34962))
        data += b; pad = (-len(data)) % 4; data += b'\0' * pad; off = len(data)
    acc = [G.Accessor(bufferView=0, componentType=5126, count=len(P), type='VEC3', min=P.min(0).tolist(), max=P.max(0).tolist()),
           G.Accessor(bufferView=1, componentType=5126, count=len(P), type='VEC3'),
           G.Accessor(bufferView=2, componentType=5126, count=len(P), type='VEC2'),
           G.Accessor(bufferView=3, componentType=5126, count=len(P), type='VEC4'),
           G.Accessor(bufferView=4, componentType=5125, count=len(idx), type='SCALAR')]
    prim = G.Primitive(attributes=G.Attributes(POSITION=0, NORMAL=1, TEXCOORD_0=2, COLOR_0=3), indices=4, material=0)
    mat = G.Material(name=matname, pbrMetallicRoughness=G.PbrMetallicRoughness(baseColorTexture=G.TextureInfo(index=0), metallicFactor=0.0, roughnessFactor=0.85), alphaMode='OPAQUE', doubleSided=False)
    g = G.GLTF2(asset=G.Asset(version='2.0', generator='NewMap tools/city/lod/lod_bake.py (near-matched mid / far)'), scene=0, scenes=[G.Scene(nodes=[0])],
                nodes=[G.Node(mesh=0, name=nodename)], meshes=[G.Mesh(name=meshname, primitives=[prim])], materials=[mat],
                samplers=[G.Sampler(magFilter=9729, minFilter=9987, wrapS=33071, wrapT=33071)], textures=[G.Texture(sampler=0, source=0)],
                images=[G.Image(uri=rel, mimeType='image/png')], accessors=acc, bufferViews=views, buffers=[G.Buffer(byteLength=len(data))])
    g.set_binary_blob(data); g.save_binary(path)

CK_OUT = '/tmp/lod_ck_out'
def write_ck(jpath, P, N, UV, I):
    """the city-kit merged buildings are Godot scenes: write the arrays for apply_ck.gd (same format as dump_mesh.gd)"""
    os.makedirs(CK_OUT, exist_ok=True)
    meta = json.load(open(jpath)); X = np.array(meta['xf']).reshape(4, 3); B = X[:3].T; o = X[3]
    Pl = (P - o) @ np.linalg.inv(B).T; Nl = N @ np.linalg.inv(B).T
    nv = len(P); f = np.zeros((nv, 12), np.float32); f[:, :3] = Pl; f[:, 3:6] = Nl; f[:, 6:8] = UV; f[:, 8:12] = 1.0
    Ig = I[:, ::-1].astype(np.int32)      # back to Godot's clockwise winding
    base = os.path.basename(jpath)[:-5]
    open(CK_OUT + '/' + base + '.bin', 'wb').write(f.tobytes() + Ig.tobytes())
    json.dump({'src': meta['src'], 'nv': nv, 'ni': int(Ig.size), 'page': 'res://assets/coronado_kit/textures/bld_lod_color.png'}, open(CK_OUT + '/' + base + '.json', 'w'))

if __name__ == '__main__':
    main()
