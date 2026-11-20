"""Which blocks of the map are still empty (20 Nov 2026; Yasin: "which areas are left empty in the map?").

Reads the ground dump of tools/city/audit/ground_dump.gd (every piece's ground mesh, assembled city) and, on a 1 m grid,
marks what each square metre is: street (road kit pieces j_ / s_ and the ring / bridge), built (any other piece: blocks,
samples, zone growth, fills, hospital, campus), or nothing. Blocks are the 200 m squares of the street lattice (corners
on multiples of 200 m in the grid frame). Prints every block inside the ring road with its share built, and draws a plan.

  python tools/city/audit/empty_blocks.py OUT/ground [--png=OUT/top/empty_blocks.png]
"""
import json, sys
import numpy as np

U0, V0, NX, NY = -1600.0, -1900.0, 3300, 2700
ROAD = ('j_', 's_', 'x_', 'w_')


def main():
    base = sys.argv[1]
    png = next((a.split('=', 1)[1] for a in sys.argv[2:] if a.startswith('--png=')), None)
    recs = json.load(open(base + '.json', encoding='utf-8'))
    V = np.fromfile(base + '_v.bin', '<f4').reshape(-1, 3); I = np.fromfile(base + '_i.bin', '<i4')
    kind = np.zeros(NX * NY, np.uint8)        # 0 nothing, 1 street, 2 built
    for r in recs:
        k = 1 if r['piece'].startswith(ROAD) else 2
        x = np.array(r['xf'], dtype=np.float64); B = x[:9].reshape(3, 3).T; o = x[9:]
        for name, vo, vn, io, inn in r['surf']:
            v = V[vo:vo + vn].astype(np.float64) @ B.T + o
            T = v[I[io:io + inn]].reshape(-1, 3, 3)
            # sample each triangle every ~0.7 m
            e = np.maximum.reduce([np.linalg.norm(T[:, 1] - T[:, 0], axis=1), np.linalg.norm(T[:, 2] - T[:, 1], axis=1), np.linalg.norm(T[:, 0] - T[:, 2], axis=1)])
            n = np.clip(np.ceil(e / 0.7).astype(int), 1, 40)
            for kk in np.unique(n):
                S = T[n == kk]
                w = np.array([(1 - a / kk - b / kk, a / kk, b / kk) for a in range(kk + 1) for b in range(kk + 1 - a)])
                P = np.einsum('sw,twc->tsc', w, S).reshape(-1, 3)
                ci = np.floor(P[:, 0] - U0).astype(np.int64); cj = np.floor(P[:, 2] - V0).astype(np.int64)
                ok = (ci >= 0) & (ci < NX) & (cj >= 0) & (cj < NY)
                idx = cj[ok] * NX + ci[ok]
                kind[idx] = np.maximum(kind[idx], k)
    G = kind.reshape(NY, NX)
    # the ring road's box: the extent of the street pieces
    sj, si = np.nonzero(G == 1)
    x0, x1 = U0 + si.min(), U0 + si.max(); z0, z1 = V0 + sj.min(), V0 + sj.max()
    rows = []
    for bz in range(int(np.floor(z0 / 200)), int(np.ceil(z1 / 200))):
        for bx in range(int(np.floor(x0 / 200)), int(np.ceil(x1 / 200))):
            a = int((bx * 200 - U0)); b = int((bz * 200 - V0))
            sub = G[max(b, 0):max(b + 200, 0), max(a, 0):max(a + 200, 0)]
            if sub.size == 0: continue
            street = (sub == 1).mean(); built = (sub == 2).mean(); land = 1.0 - street
            if street == 0 and built == 0: continue            # outside the city (no street touches it)
            share = built / land if land > 0 else 0.0
            rows.append((bx * 200, bz * 200, share, street))
    rows.sort(key=lambda r: (r[1], r[0]))
    empty = [r for r in rows if r[2] < 0.10]; part = [r for r in rows if 0.10 <= r[2] < 0.60]; full = [r for r in rows if r[2] >= 0.60]
    tot_land = sum(1 - r[3] for r in rows); tot_built = sum(r[2] * (1 - r[3]) for r in rows)
    print('EMPTY-BLOCKS %d blocks of 200 m touched by streets: %d built (60 %%+), %d partly, %d empty (under 10 %%); land between the streets built: %.0f %%' % (len(rows), len(full), len(part), len(empty), 100 * tot_built / max(tot_land, 1e-9)))
    print('empty blocks (corner x, z):', ' '.join('(%d,%d)' % (r[0], r[1]) for r in empty))
    print('partly built (corner x, z, share):', ' '.join('(%d,%d %d%%)' % (r[0], r[1], round(100 * r[2])) for r in part))
    json.dump({'blocks': [{'x': r[0], 'z': r[1], 'built': r[2], 'street': r[3]} for r in rows]}, open(base + '_blocks.json', 'w'))
    if png:
        from PIL import Image, ImageDraw, ImageFont
        img = np.zeros((NY, NX, 3), np.uint8); img[:] = (214, 222, 200)
        img[G == 1] = (90, 90, 95); img[G == 2] = (60, 140, 70)
        im = Image.fromarray(img)
        d = ImageDraw.Draw(im, 'RGBA')
        try: f = ImageFont.truetype('arialbd.ttf', 28)
        except Exception: f = ImageFont.load_default()
        for r in empty:
            px = int(r[0] - U0); pz = int(r[1] - V0)
            d.rectangle((px + 6, pz + 6, px + 194, pz + 194), outline=(220, 40, 40, 255), width=5)
        for r in part:
            px = int(r[0] - U0); pz = int(r[1] - V0)
            d.rectangle((px + 6, pz + 6, px + 194, pz + 194), outline=(240, 170, 0, 255), width=4)
            d.text((px + 70, pz + 85), '%d%%' % round(100 * r[2]), fill=(120, 80, 0, 255), font=f)
        a0 = int(x0 - U0) - 60; b0 = int(z0 - V0) - 60; a1 = int(x1 - U0) + 60; b1 = int(z1 - V0) + 60
        im = im.crop((max(a0, 0), max(b0, 0), min(a1, NX), min(b1, NY)))
        d = ImageDraw.Draw(im)
        d.text((20, 15), 'green = built, grey = streets, pale = empty land; red box = empty block, orange = partly built (share built). North is up.', fill=(20, 20, 20), font=f)
        im.save(png)
        print('picture', png, im.size)


main()
