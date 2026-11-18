#!/usr/bin/env python3
"""Before / after sheets from the rig's --shots pictures: pair_<view>_<day|night>.jpg, before on top, after below
(and after with bloom under that, when those pictures exist), each with a caption bar.
Run from the repo root:  python3 tools/city/look/make_pairs.py map_dc/coronado/city_kit/review/look_18nov/sky
Grids instead (one sheet per view):  ... make_pairs.py <folder> --sheet=morning,noon,golden,dusk,night,overcast
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


def sheet(folder, names, cols=2):
    """sheet_<view>.jpg: every <view>_<name>.jpg of a view at half size in a grid, captioned (times of day)."""
    font = ImageFont.truetype(os.path.join("ui", "fonts", "Overpass.ttf"), 22)
    views = sorted({f.split("_", 1)[0] for f in os.listdir(folder) if f.endswith(".jpg") and not f.startswith("sheet_")})
    for v in views:
        ims = [(n, os.path.join(folder, f"{v}_{n}.jpg")) for n in names if os.path.exists(os.path.join(folder, f"{v}_{n}.jpg"))]
        if not ims:
            continue
        w, h = 820, 360
        bar = 32
        rows = (len(ims) + cols - 1) // cols
        out = Image.new("RGB", (w * cols, (h + bar) * rows), (20, 20, 20))
        d = ImageDraw.Draw(out)
        for i, (n, path) in enumerate(ims):
            x, y = (i % cols) * w, (i // cols) * (h + bar)
            d.text((x + 10, y + 4), f"{v}  -  {n}", fill=(240, 240, 240), font=font)
            out.paste(Image.open(path).convert("RGB").resize((w, h), Image.LANCZOS), (x, y + bar))
        dst = os.path.join(folder, f"sheet_{v}.jpg")
        out.save(dst, quality=88)
        print("wrote", dst)


def compare(out_path, rows):
    """one sheet of labelled pictures stacked: rows = [(label, path), ...] (missing paths are left out)"""
    font = ImageFont.truetype(os.path.join("ui", "fonts", "Overpass.ttf"), 26)
    small = ImageFont.truetype(os.path.join("ui", "fonts", "Overpass.ttf"), 20)
    rows = [(l, p) for l, p in rows if os.path.exists(p)]
    if len(rows) < 2:
        return
    ims = [Image.open(p).convert("RGB") for _, p in rows]
    w, h = ims[0].size
    bar = 40
    sheet_im = Image.new("RGB", (w, (h + bar) * len(ims)), (20, 20, 20))
    d = ImageDraw.Draw(sheet_im)
    for i, ((label, _), im) in enumerate(zip(rows, ims)):
        y = i * (h + bar)
        d.text((14, y + 6), label, fill=(240, 240, 240), font=font)
        d.text((w - 14, y + 10), NOTE, fill=(170, 170, 170), font=small, anchor="ra")
        sheet_im.paste(im.resize((w, h)), (0, y + bar))
    sheet_im.save(out_path, quality=88)
    print("wrote", out_path)


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[2].startswith("--sheet="):
        sheet(sys.argv[1], sys.argv[2].split("=", 1)[1].split(","))
    else:
        main(sys.argv[1] if len(sys.argv) > 1 else "map_dc/coronado/city_kit/review/look_18nov/sky")
