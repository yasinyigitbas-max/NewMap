#!/usr/bin/env python3
"""Look job 2: bilinear against SGSR, the same view at the phone's screen size (2460 x 1080, 3D drawn 720 lines).
For each <view>_day.jpg / <view>_day_sgsr.jpg: crop_<view>.jpg with two areas zoomed 2 x (left bilinear, right SGSR)
and a sharpness number (mean brightness step between neighbouring pixels in the crops; higher = sharper).
Run from the repo root:  python3 tools/city/look/upscale_sheet.py map_dc/coronado/city_kit/review/look_18nov/upscale
"""
import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

BOXES = [(1030, 330, 1440, 600), (150, 420, 560, 690)]      # the street's far end; the near-left kerb and pavement


def sharp(im):
    a = np.asarray(im.convert("L"), dtype=np.float32)
    return float(np.abs(np.diff(a, axis=1)).mean() + np.abs(np.diff(a, axis=0)).mean())


def main(folder):
    font = ImageFont.truetype(os.path.join("ui", "fonts", "Overpass.ttf"), 24)
    for f in sorted(os.listdir(folder)):
        if not f.endswith("_day.jpg"):
            continue
        v = f[:-8]
        b = Image.open(os.path.join(folder, f)).convert("RGB")
        s_path = os.path.join(folder, f"{v}_day_sgsr.jpg")
        if not os.path.exists(s_path):
            continue
        s = Image.open(s_path).convert("RGB")
        rows = []
        for box in BOXES:
            cb, cs = b.crop(box), s.crop(box)
            rows.append((cb.resize((cb.width * 2, cb.height * 2), Image.NEAREST), cs.resize((cs.width * 2, cs.height * 2), Image.NEAREST), sharp(cb), sharp(cs)))
        w, h = rows[0][0].size
        bar = 36
        out = Image.new("RGB", (w * 2 + 8, (h + bar) * len(rows)), (20, 20, 20))
        d = ImageDraw.Draw(out)
        for i, (cb, cs, nb, ns) in enumerate(rows):
            y = i * (h + bar)
            d.text((10, y + 6), f"{v}: BILINEAR (today)  sharpness {nb:.2f}", fill=(240, 240, 240), font=font)
            d.text((w + 18, y + 6), f"SGSR (--upscale=1)  sharpness {ns:.2f}", fill=(240, 240, 240), font=font)
            out.paste(cb, (0, y + bar)); out.paste(cs, (w + 8, y + bar))
        dst = os.path.join(folder, f"crop_{v}.jpg")
        out.save(dst, quality=90)
        print(f"wrote {dst}  sharpness bilinear / sgsr: " + ", ".join(f"{r[2]:.2f} / {r[3]:.2f}" for r in rows))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "map_dc/coronado/city_kit/review/look_18nov/upscale")
