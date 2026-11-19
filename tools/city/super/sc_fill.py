"""How much of the city is built, and where the empty places are (19 Nov 2026, Yasin: "Check how much of the city is
filled by percentage now. And list empty places"). Reads only: the piece ground of every layout row (superchecker
read-outs), the land grid (land / sea) and the zone plan (zoning/zones.py).

On a 2 m grid: a cell is BUILT where any piece's ground lies (blocks, streets, junctions, samples, fills). The empty
land cells form pockets; a pocket that touches the sea or the edge of the land box is outside the city (beach, open
land beyond the last street). Every other pocket is an empty place inside the city. The city = built + those pockets.

  python -I tools/city/super/sc_fill.py           -> prints the table, writes OUT/super/fill.json and OUT/super/fill.png
"""
import json, math, os, sys
import numpy as np
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sc_lib as L

Q = 2.0


def zones():
    src = open(os.path.join(L.REPO, 'tools/city/pilot/zoning/zones.py'), encoding='utf-8').read()
    ns = {}; exec(compile(src.split('\nMUST=')[0], 'zones', 'exec'), ns)
    return ns['Z']


def in_poly(x, z, poly):
    inside = np.zeros(x.shape, bool); n = len(poly)
    for k in range(n):
        x1, z1 = poly[k]; x2, z2 = poly[(k + 1) % n]
        c = ((z1 > z) != (z2 > z)) & (x < (x2 - x1) * (z - z1) / np.where(z2 != z1, z2 - z1, 1e-9) + x1)
        inside ^= c
    return inside


def run():
    rows = L.load_layout()
    L.ensure_dumps(sorted(set(r.piece for r in rows)), say=False)
    land = L.Land()
    ny, nx = land.H.shape
    x0 = land.u0; z0 = land.v0; W = int((nx - 1) * land.s / Q); H = int((ny - 1) * land.s / Q)
    built = np.zeros((H, W), bool); kind = np.zeros((H, W), np.int8)          # 1 street, 2 block / sample / fill
    cache = {}
    for r in rows:
        if r.piece.startswith(('w_', 't_', 'x_')): continue
        if r.piece not in cache:
            try: cache[r.piece] = L.Dump(r.piece).ground()
            except Exception: cache[r.piece] = []
        street = r.piece.startswith(('s_', 'j_'))
        for name, T in cache[r.piece]:
            Tw = r.pts(T)
            nr = np.cross(Tw[:, 1] - Tw[:, 0], Tw[:, 2] - Tw[:, 0]); ln = np.linalg.norm(nr, axis=1)
            Tw = Tw[(ln > 1e-7) & (np.abs(nr[:, 1]) >= 0.5 * np.maximum(ln, 1e-12))]
            for t in Tw:
                p = t[:, [0, 2]]; lo = np.floor((p.min(0) - [x0, z0]) / Q).astype(int); hi = np.floor((p.max(0) - [x0, z0]) / Q).astype(int)
                i = np.arange(max(lo[0], 0), min(hi[0], W - 1) + 1); j = np.arange(max(lo[1], 0), min(hi[1], H - 1) + 1)
                if not len(i) or not len(j): continue
                X, Z = np.meshgrid(x0 + (i + 0.5) * Q, z0 + (j + 0.5) * Q)
                a, b, c = p
                d = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
                if abs(d) < 1e-12: continue
                w0 = ((b[1] - c[1]) * (X - c[0]) + (c[0] - b[0]) * (Z - c[1])) / d; w1 = ((c[1] - a[1]) * (X - c[0]) + (a[0] - c[0]) * (Z - c[1])) / d
                m = (w0 >= -1e-6) & (w1 >= -1e-6) & (1 - w0 - w1 >= -1e-6)
                sub = built[j[0]:j[-1] + 1, i[0]:i[-1] + 1]; sub |= m
                ks = kind[j[0]:j[-1] + 1, i[0]:i[-1] + 1]; ks[m & (ks == 0)] = 1 if street else 2
                if not street: ks[m] = 2
    # land / sea on the 2 m grid
    XX, ZZ = np.meshgrid(x0 + (np.arange(W) + 0.5) * Q, z0 + (np.arange(H) + 0.5) * Q)
    sea = land.sea.astype(bool)
    si = np.clip(np.round((XX - x0) / land.s).astype(int), 0, nx - 1); sj = np.clip(np.round((ZZ - z0) / land.s).astype(int), 0, ny - 1)
    seac = sea[sj, si] & ~built
    empty = ~built & ~seac
    lab, n = ndimage.label(empty)
    # pockets touching the sea or the box edge are outside the city
    out = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]])).tolist())
    near_sea = ndimage.binary_dilation(seac, iterations=2)
    out |= set(np.unique(lab[near_sea & empty]).tolist())
    out.discard(0)
    Z = zones(); zmask = {}
    for k, (nm, col, polys) in Z.items():
        m = np.zeros((H, W), bool)
        for pg in polys: m |= in_poly(XX, ZZ, pg)
        zmask[k] = m
    sl = ndimage.find_objects(lab)
    places = []
    for idx in range(1, n + 1):
        if idx in out: continue
        s = sl[idx - 1]; m = lab[s] == idx; area = float(m.sum() * Q * Q)
        if area < 400.0: continue                     # slivers between pieces (under 20 x 20 m) are not places
        jj, ii = np.nonzero(m); cx = float(XX[s][m].mean()); cz = float(ZZ[s][m].mean())
        hs = land.at(XX[s][m], ZZ[s][m])
        zc = {k: int((zm[s] & m).sum()) for k, zm in zmask.items()}; zk = max(zc, key=zc.get) if max(zc.values()) > 0 else None
        share = zc[zk] / m.sum() if zk else 0
        places.append({'area_ha': round(area / 1e4, 2), 'centre': [round(cx), round(cz)], 'box': [round(float(XX[s][m].min())), round(float(ZZ[s][m].min())), round(float(XX[s][m].max())), round(float(ZZ[s][m].max()))],
                       'zone': (Z[zk][0] if zk else 'no zone in the plan'), 'zone_key': zk, 'zone_share': round(share, 2),
                       'rise_m': round(float(hs.max() - hs.min()), 1), 'height_m': [round(float(hs.min()), 1), round(float(hs.max()), 1)]})
    places.sort(key=lambda p: -p['area_ha'])
    b_area = float(built.sum() * Q * Q); blk = float((kind == 2).sum() * Q * Q); st = float((kind == 1).sum() * Q * Q)
    e_area = sum(p['area_ha'] for p in places) * 1e4
    slivers = float(sum((lab == i).sum() for i in range(1, n + 1) if i not in out) * Q * Q) - e_area
    city = b_area + e_area + slivers
    res = {'city_ha': round(city / 1e4, 1), 'built_ha': round(b_area / 1e4, 1), 'blocks_ha': round(blk / 1e4, 1), 'streets_ha': round(st / 1e4, 1),
           'empty_ha': round(e_area / 1e4, 1), 'slivers_ha': round(slivers / 1e4, 1), 'built_pct': round(100 * b_area / city, 1),
           'blocks_pct_of_block_land': round(100 * blk / (blk + e_area + slivers), 1), 'places': places}
    json.dump(res, open(os.path.join(L.OUT, 'fill.json'), 'w'), indent=1)
    try:
        from PIL import Image, ImageDraw
        img = np.zeros((H, W, 3), np.uint8); img[:] = (225, 222, 214); img[seac] = (140, 180, 210)
        img[kind == 1] = (95, 95, 100); img[kind == 2] = (120, 165, 105)
        for i in range(1, n + 1):
            pass
        inside = np.isin(lab, [i for i in range(1, n + 1) if i not in out]); img[inside] = (235, 120, 90)
        im = Image.fromarray(img[::-1] if False else img).resize((W // 2, H // 2), Image.NEAREST); dr = ImageDraw.Draw(im)
        for k, p in enumerate(places):
            x = (p['centre'][0] - x0) / Q / 2; y = (p['centre'][1] - z0) / Q / 2
            dr.text((x - 4, y - 5), str(k + 1), fill=(0, 0, 0))
        im.save(os.path.join(L.OUT, 'fill.png'))
    except Exception as e:
        print('picture not made:', e)
    return res


if __name__ == '__main__':
    r = run()
    print('CITY %.1f ha (the land inside the last streets): built %.1f ha = %.1f %% (blocks and samples %.1f ha, streets %.1f ha); empty places %.1f ha; slivers between pieces %.1f ha' % (
        r['city_ha'], r['built_ha'], r['built_pct'], r['blocks_ha'], r['streets_ha'], r['empty_ha'], r['slivers_ha']))
    print('of the land for blocks (the city less its streets): %.1f %% built' % r['blocks_pct_of_block_land'])
    print('%d empty places of 0.04 ha or more:' % len(r['places']))
    for k, p in enumerate(r['places']):
        print('%3d  %5.2f ha  centre (%5d, %5d)  %-40s rise %4.1f m (%.1f..%.1f)' % (k + 1, p['area_ha'], p['centre'][0], p['centre'][1], p['zone'][:40], p['rise_m'], p['height_m'][0], p['height_m'][1]))
