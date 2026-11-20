"""LOD match: before / after sheets from lod_shots.gd pictures (DIR/{before,after}/<shot>_<58|62|218|222>.png).
One row per shot, each pair from ONE camera: 59 m near | mid, before then after  ||  219 m mid | far, before then after."""
import sys, os
from PIL import Image, ImageDraw
src, out = sys.argv[1], sys.argv[2]
shots = sorted({f.rsplit('_', 1)[0] for f in os.listdir(os.path.join(src, 'after')) if f.endswith('.png')})
C = 300
def crop(p, d):
    im = Image.open(p).convert('RGB'); W, H = im.size
    s = 440 if d < 100 else 150
    return im.crop((W // 2 - s // 2, H // 2 - s // 2, W // 2 + s // 2, H // 2 + s // 2)).resize((C, C), Image.LANCZOS if d < 100 else Image.NEAREST)
rows = []
for sh in shots:
    row = Image.new('RGB', (C * 8 + 30, C + 22), (255, 255, 255)); dr = ImageDraw.Draw(row)
    x = 0
    for grp in (('59n', '59m'), ('219m', '219f')):
        for ver in ('before', 'after'):
            for d in grp:
                p = os.path.join(src, ver, f'{sh}_{d}.png')
                if os.path.exists(p): row.paste(crop(p, int(d[:-1])), (x, 22))
                dr.text((x + 4, 4), f'{sh} {ver} {d[:-1]} m {dict(n="near", m="mid", f="far")[d[-1]]}', fill=(0, 0, 0))
                x += C
        x += 30
    row.save(os.path.join(out, f'{sh}.png')); rows.append(row)
for k in range(0, len(rows), 6):
    part = rows[k:k + 6]; sheet = Image.new('RGB', (part[0].width, sum(r.height for r in part)), (255, 255, 255)); y = 0
    for r in part: sheet.paste(r, (0, y)); y += r.height
    sheet.save(os.path.join(out, f'sheet_{k // 6 + 1}.png'))
print(len(rows), 'rows')
