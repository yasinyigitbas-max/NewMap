"""The baked ground of the city against the terrain grid (19 Nov; Yasin: "all of their work is sunk in elevation").

    godot --headless --path . -s res://tools/city/traffic/ground_vs_terrain.gd     (writes OUT/ground_grid.*)
    python tools/city/traffic/ground_vs_terrain.py                                 (this: numbers + a picture)

Both are on the terrain grid's own 4 m points (zoning/terrain_grid.npz, the kit's frame). d = terrain - ground:
  d near -0.05 m : as the terrain tool leaves it (the terrain 5 cm under the built ground)
  d > +0.10 m    : the TERRAIN LIES OVER the built ground there: the piece is buried (sunk)
  d < -0.30 m    : the built ground FLOATS over the terrain
Writes map_dc/coronado/city_kit/review/traffic/ground_vs_terrain.png (red = buried, blue = floating, grey = fits).
"""
import json, sys
import numpy as np

b = np.load('map_dc/coronado/city_kit/zoning/terrain_grid.npz')
H = b['heights'].astype('f4'); sea = b['sea'].astype(bool); u0 = float(b['u0']); v0 = float(b['v0']); st = float(b['step'])
m = json.load(open('OUT/ground_grid.json'))
G = np.fromfile('OUT/ground_grid.f32', dtype='<f4').reshape(m['ny'], m['nx'], 2)
assert (m['x0'], m['z0'], m['step']) == (u0, v0, st) and G.shape[:2] == H.shape, 'the two grids differ'
gy = G[:, :, 0]; layer = G[:, :, 1].astype(int)
has = ~np.isnan(gy)
d = np.where(has, H - gy, np.nan)
land = has & ~sea
n = int(land.sum())
print('baked ground on %d grid points (%.2f km2), of the terrain grid %d x %d at %.0f m; heights of the built ground %.1f .. %.1f m' % (n, n * st * st / 1e6, H.shape[1], H.shape[0], st, float(np.nanmin(gy)), float(np.nanmax(gy))))
dd = d[land]
print('terrain minus built ground: median %+.2f m | 1 %% %+.2f, 5 %% %+.2f, 95 %% %+.2f, 99 %% %+.2f | least %+.2f, most %+.2f' % (np.median(dd), *np.percentile(dd, [1, 5, 95, 99]), dd.min(), dd.max()))
fits = (dd >= -0.30) & (dd <= 0.10); bur = dd > 0.10; flo = dd < -0.30
print('fits (terrain 0.10 above .. 0.30 under): %.1f %% | BURIED (terrain over the ground by more than 0.10 m): %.1f %% = %.0f m2, of it more than 0.5 m: %.0f m2, more than 1 m: %.0f m2 | FLOATING (ground more than 0.30 m over the terrain): %.1f %% = %.0f m2, more than 1 m: %.0f m2' % (
    fits.mean() * 100, bur.mean() * 100, bur.sum() * st * st, (dd > 0.5).sum() * st * st, (dd > 1.0).sum() * st * st, flo.mean() * 100, flo.sum() * st * st, (dd < -1.0).sum() * st * st))
NAMES = ['asphalt', 'concrete', 'grass', 'dry ground', 'travertine', 'white paint', 'yellow paint', 'gravel', 'sand']
for l in range(9):
    q = land & (layer == l)
    if q.sum() < 50: continue
    x = d[q]
    print('   %-12s %7d points: median %+.2f | buried %.1f %% (deepest %+.2f) | floating %.1f %% (highest %+.2f)' % (NAMES[l], q.sum(), np.median(x), (x > 0.10).mean() * 100, x.max(), (x < -0.30).mean() * 100, x.min()))
# by 200 m tile: where it is wrong
ny, nx = H.shape
rows = []
T = int(200 / st)
for j0 in range(0, ny, T):
    for i0 in range(0, nx, T):
        q = land[j0:j0 + T, i0:i0 + T]
        if q.sum() < 100: continue
        x = d[j0:j0 + T, i0:i0 + T][q]
        rows.append(((x > 0.10).mean(), (x < -0.30).mean(), np.median(x), x.max(), x.min(), u0 + i0 * st, v0 + j0 * st, int(q.sum())))
print('200 m tiles with built ground: %d | tiles where more than 5 %% of the ground is buried: %d | more than 5 %% floating: %d' % (len(rows), sum(1 for r in rows if r[0] > 0.05), sum(1 for r in rows if r[1] > 0.05)))
print('the tiles with the most BURIED ground:')
for r in sorted(rows, reverse=True)[:12]:
    if r[0] <= 0.005: break
    print('   x %5.0f..%5.0f  z %5.0f..%5.0f: buried %4.1f %% (deepest %+.2f m), floating %4.1f %%, median %+.2f, %d points' % (r[5], r[5] + 200, r[6], r[6] + 200, r[0] * 100, r[3], r[1] * 100, r[2], r[7]))
print('the tiles with the most FLOATING ground:')
for r in sorted(rows, key=lambda r: -r[1])[:8]:
    if r[1] <= 0.005: break
    print('   x %5.0f..%5.0f  z %5.0f..%5.0f: floating %4.1f %% (highest %+.2f m), buried %4.1f %%, %d points' % (r[5], r[5] + 200, r[6], r[6] + 200, r[1] * 100, r[4], r[0] * 100, r[7]))
try:
    from PIL import Image
    img = np.zeros((ny, nx, 3), dtype=np.uint8); img[:] = (16, 22, 30)
    img[~has & ~sea] = (46, 58, 44)
    k = np.clip(np.nan_to_num(d), -1.0, 1.0)
    grey = np.array([120, 120, 120])
    for cond, col in (((d > 0.10) & land, np.array([235, 40, 30])), ((d < -0.30) & land, np.array([40, 110, 240]))):
        w = np.clip(np.abs(k) / 0.6, 0.35, 1.0)[..., None]
        img = np.where(cond[..., None], (grey * (1 - w) + col * w).astype(np.uint8), img)
    img = np.where(((d <= 0.10) & (d >= -0.30) & land)[..., None], grey.astype(np.uint8), img)
    Image.fromarray(img).resize((nx * 2, ny * 2), Image.NEAREST).save('map_dc/coronado/city_kit/review/traffic/ground_vs_terrain.png')
    print('picture: map_dc/coronado/city_kit/review/traffic/ground_vs_terrain.png (north at the top = low z; red buried, blue floating, grey fits)')
except Exception as e:
    print('no picture:', e)
