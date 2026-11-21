"""Hotel Bel additions to the shared CITY atlas (additive: only pixels that no region uses are written).
 - R_shingle: red painted 3-tab shingle roof tile strip (from R_comp's own texture, recoloured), px rows 2016-2047
   (unused, black) -- same 0.5 m tile and 16 m u-period as R_metal (32 px tall)
 - S_shingle: its swatch (mid / far fallback), 24 x 24 in the unused block x 1408-1800, y 1628-1700
 - SG_hotelbel: 'HOTEL BEL' sign board, 288 x 60, same style as SG_hotel (red board, cream border and serif letters)
Normal / ORM pages (1024) get R_comp's own normal / ORM rows for the shingles, flat values for the rest.
usage: atlas_add.py <textures dir>   (checks that every pixel outside the new rects is unchanged)"""
import sys, json, numpy as np
from PIL import Image, ImageDraw, ImageFont
T = sys.argv[1]
L = json.load(open(T + '/city_layout.json'))
R = L['regions']
col = np.asarray(Image.open(T + '/city_color.png').convert('RGB')).copy()
nor = np.asarray(Image.open(T + '/city_normal.png').convert('RGB')).copy()
orm = np.asarray(Image.open(T + '/city_orm.png').convert('RGB')).copy()
col0, nor0, orm0 = col.copy(), nor.copy(), orm.copy()
NEW = {'R_shingle': [0, 2016, 2048, 2048], 'S_shingle': [1720, 1640, 1744, 1664], 'SG_hotelbel': [1412, 1634, 1700, 1694]}
occ = np.zeros((2048, 2048), bool)
for k, v in R.items():
    if k in NEW: continue
    x0, y0, x1, y1 = v['px']; occ[y0:y1, x0:x1] = True
for k, (x0, y0, x1, y1) in NEW.items():
    assert not occ[max(0, y0 - 2):y1 + 2, max(0, x0 - 2):x1 + 2].any(), k
# ---- shingles: R_comp rows recoloured to a painted red (Victorian resort roofs), luminance kept for the 3-tab pattern
x0, y0, x1, y1 = R['R_comp']['px']
src = col0[y0:y1].astype(np.float32)
src = np.asarray(Image.fromarray(src.astype(np.uint8)).resize((2048, 32), Image.LANCZOS)).astype(np.float32)
lum = src.mean(2); n = lum / lum.mean()
red = np.array([178.0, 52.0, 40.0])
sh = red[None, None, :] * np.clip(0.55 + 0.45 * n, 0.35, 1.45)[..., None]
# a faint warm fade on the exposed tab, darker butt line at each course (rows 0-1 and 15-16 of the 32)
col[2016:2048] = np.clip(sh, 0, 255).astype(np.uint8)
ny0, ny1 = y0 // 2, y1 // 2
nor[1008:1024] = np.asarray(Image.fromarray(nor0[ny0:ny1]).resize((1024, 16), Image.LANCZOS))
ormr = np.asarray(Image.fromarray(orm0[ny0:ny1]).resize((1024, 16), Image.LANCZOS)).copy()
ormr[..., 1] = np.clip(ormr[..., 1].astype(int) - 15, 0, 255)      # painted: a touch less rough than bare asphalt
orm[1008:1024] = ormr
# ---- swatch
sx0, sy0, sx1, sy1 = NEW['S_shingle']
col[sy0:sy1, sx0:sx1] = np.clip(sh.reshape(-1, 3).mean(0), 0, 255).astype(np.uint8)
# ---- sign
gx0, gy0, gx1, gy1 = NEW['SG_hotelbel']; W, H = gx1 - gx0, gy1 - gy0
im = Image.new('RGB', (W, H), (232, 222, 196)); d = ImageDraw.Draw(im)
d.rectangle([3, 3, W - 4, H - 4], fill=(205, 192, 160))
d.rectangle([6, 6, W - 7, H - 7], fill=(148, 30, 28))
d.rectangle([9, 9, W - 10, H - 10], outline=(214, 186, 120), width=1)
f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf', 30)
txt = 'HOTEL BEL'; sp = 4
ws = [d.textlength(c, font=f) for c in txt]; tw = sum(ws) + sp * (len(txt) - 1)
x = (W - tw) / 2; yb = H / 2 + 1
for c, w_ in zip(txt, ws):
    d.text((x + 1, yb + 1), c, font=f, fill=(70, 12, 12), anchor='lm'); d.text((x, yb), c, font=f, fill=(242, 232, 206), anchor='lm'); x += w_ + sp
for cx in (16, W - 17): d.ellipse([cx - 2, H / 2 - 2, cx + 2, H / 2 + 2], fill=(214, 186, 120))
col[gy0:gy1, gx0:gx1] = np.asarray(im)
for k, (a0, b0, a1, b1) in NEW.items():
    if k == 'R_shingle': continue
    nor[b0 // 2:b1 // 2, a0 // 2:a1 // 2] = (128, 128, 255); orm[b0 // 2:b1 // 2, a0 // 2:a1 // 2] = (255, 200, 0)
# ---- proof: nothing outside the new rects changed
mask = np.zeros((2048, 2048), bool)
for (a0, b0, a1, b1) in NEW.values(): mask[b0:b1, a0:a1] = True
m2 = mask[::2, ::2]
assert (col[~mask] == col0[~mask]).all() and (nor[~m2] == nor0[~m2]).all() and (orm[~m2] == orm0[~m2]).all()
Image.fromarray(col).save(T + '/city_color.png'); Image.fromarray(nor).save(T + '/city_normal.png'); Image.fromarray(orm).save(T + '/city_orm.png')
uv = lambda p: [p[0] / 2048, p[1] / 2048, p[2] / 2048, p[3] / 2048]
R['R_shingle'] = {'kind': 'tile', 'px': NEW['R_shingle'], 'uv': uv(NEW['R_shingle']), 'tile_m': 1.0, 'u_period_m': 16.0, 'note': 'Hotel Bel: red painted 3-tab shingles (R_comp recoloured)'}
p = NEW['S_shingle']; R['S_shingle'] = {'kind': 'swatch', 'of': 'R_shingle', 'px': p, 'uv_center': [(p[0] + p[2]) / 4096, (p[1] + p[3]) / 4096]}
R['SG_hotelbel'] = {'kind': 'sign', 'px': NEW['SG_hotelbel'], 'uv': uv(NEW['SG_hotelbel']), 'size_m': [2.88, 0.6], 'tile_x': False, 'glow': False}
L['signs']['SG_hotelbel'] = 'HOTEL BEL'
json.dump(L, open(T + '/city_layout.json', 'w'), indent=1)
print('ok: R_shingle, S_shingle, SG_hotelbel added; all other pixels unchanged')
