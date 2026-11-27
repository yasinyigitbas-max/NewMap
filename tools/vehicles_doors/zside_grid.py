"""zside_grid.py <side.png> <out.png> [outline as z,y;z,y;...]: grid in the Godot frame over zside.py's picture (front left;
6 m across 2400 px, centre z 0 / y 1.0), optional door outline drawn in red, cropped to the car."""
import sys
from PIL import Image, ImageDraw, ImageOps
im = Image.open(sys.argv[1]).convert('L')
im = ImageOps.autocontrast(im, cutoff=1).convert('RGB')
d = ImageDraw.Draw(im)
W, H = im.size; s = W / 6.0
px = lambda z, y: (W / 2 - z * s, H / 2 - (y - 1.0) * s)
for k in range(-30, 31):
    z = k * 0.1; x, _ = px(z, 0)
    d.line([(x, 0), (x, H)], fill=(255, 140, 0) if k % 5 == 0 else (255, 215, 170))
    if k % 5 == 0:
        for yy in (60, 640):
            d.text((x + 3, yy), '%.1f' % z, fill=(200, 0, 0))
for k in range(0, 31):
    y = k * 0.1; _, yy = px(0, y)
    d.line([(0, yy), (W, yy)], fill=(0, 120, 255) if k % 5 == 0 else (170, 210, 255))
    if k % 5 == 0:
        for xx in (300, 1300, 2050):
            d.text((xx, yy + 2), 'y%.1f' % y, fill=(0, 0, 200))
if len(sys.argv) > 3 and sys.argv[3]:
    pts = [tuple(map(float, p.split(','))) for p in sys.argv[3].split(';')]
    d.line([px(*p) for p in pts + pts[:1]], fill=(255, 0, 0), width=3)
im.crop((W // 2 - 1000, 100, W // 2 + 1000, 860)).resize((1400, 532)).save(sys.argv[2])
