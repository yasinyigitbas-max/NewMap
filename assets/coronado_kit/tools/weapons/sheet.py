"""sheet.py <render_dir> <out.png> [views]: contact sheet of the per-weapon renders (one row per weapon)."""
import sys, os, json
from PIL import Image, ImageDraw
R, out = sys.argv[1], sys.argv[2]
views = (sys.argv[3] if len(sys.argv) > 3 else 'hero,right').split(',')
names = [n for n in json.load(open(os.path.join(os.path.dirname(__file__), '..', '..', 'props', 'manifest_weapons.json')))]
w, h = 480, 300
S = Image.new('RGB', (w * len(views), h * len(names)), (30, 30, 30))
d = ImageDraw.Draw(S)
for i, n in enumerate(names):
    for j, v in enumerate(views):
        p = os.path.join(R, '%s_%s.png' % (n, v))
        if os.path.exists(p):
            S.paste(Image.open(p).convert('RGB').resize((w, h)), (j * w, i * h))
    d.text((6, i * h + 6), n, fill=(255, 255, 0))
S.save(out)
print(out, S.size)
