#!/usr/bin/env python3
"""Before / after sheets from the rig's --shots pictures: pair_<view>_<day|night>.jpg, before on top, after below
(and after with bloom under that, when those pictures exist), each with a caption bar.
Run from the repo root:  python3 tools/city/look/make_pairs.py map_dc/coronado/city_kit/review/look_18nov/sky
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

NOTE = "cloud preview: no sun shadows, no sky reflection, buildings drawn ~40% too dark (software GPU)"
LABELS = {"before": "BEFORE (--look=0)", "after": "AFTER (--look=1)", "after_bloom": "AFTER + BLOOM (--bloom=1)"}


def main(folder):
    font = ImageFont.truetype(os.path.join("ui", "fonts", "Overpass.ttf"), 26)
    small = ImageFont.truetype(os.path.join("ui", "fonts", "Overpass.ttf"), 20)
    keys = sorted({f.rsplit("_", 1)[0] for f in os.listdir(folder) if f.endswith("_before.jpg")})
    for k in keys:
        rows = [t for t in ("before", "after", "after_bloom") if os.path.exists(os.path.join(folder, f"{k}_{t}.jpg"))]
        ims = [Image.open(os.path.join(folder, f"{k}_{t}.jpg")).convert("RGB") for t in rows]
        w, h = ims[0].size
        bar = 40
        sheet = Image.new("RGB", (w, (h + bar) * len(ims)), (20, 20, 20))
        d = ImageDraw.Draw(sheet)
        for i, (t, im) in enumerate(zip(rows, ims)):
            y = i * (h + bar)
            d.text((14, y + 6), f"{k.replace('_', ' ')}  -  {LABELS[t]}", fill=(240, 240, 240), font=font)
            d.text((w - 14, y + 10), NOTE, fill=(170, 170, 170), font=small, anchor="ra")
            sheet.paste(im, (0, y + bar))
        out = os.path.join(folder, f"pair_{k}.jpg")
        sheet.save(out, quality=88)
        print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "map_dc/coronado/city_kit/review/look_18nov/sky")
