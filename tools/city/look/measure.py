#!/usr/bin/env python3
"""LOOK QUEUE 3, JOB 1: numbers for "murky". For each picture: mean brightness, contrast, mean saturation, clipping.
  bright   mean luminance (Rec. 709 on the sRGB values), 0..255
  contrast spread between the dark and the bright end: 95th minus 5th percentile of luminance, 0..255
  sat      mean saturation (HSV S of each pixel), 0..100 %
  sky_sat  the same for the top fifth of the picture (where the sky usually is)
  black / white   share of pixels clipped (luminance under 4 / over 251), %
Run from the repo root:  python3 tools/city/look/measure.py <picture or folder> [...]   (--md for a markdown table)
Compare pictures taken THE SAME WAY (the cloud draws buildings ~40 % too dark, no shadows): presets against each
other and against the old look from the same views, not against absolute targets.
"""
import os
import sys
import numpy as np
from PIL import Image


def stats(path):
    a = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
    lum = a[..., 0] * 0.2126 + a[..., 1] * 0.7152 + a[..., 2] * 0.0722
    mx = a.max(axis=2); mn = a.min(axis=2)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    top = sat[: max(1, a.shape[0] // 5)]
    p5, p95 = np.percentile(lum, [5, 95])
    return {"bright": float(lum.mean()), "contrast": float(p95 - p5), "sat": float(sat.mean() * 100), "sky_sat": float(top.mean() * 100),
            "black": float((lum < 4).mean() * 100), "white": float((lum > 251).mean() * 100)}


def main(args):
    md = "--md" in args
    files = []
    for a in args:
        if a.startswith("--"):
            continue
        if os.path.isdir(a):
            files += [os.path.join(a, f) for f in sorted(os.listdir(a)) if f.endswith(".jpg") and not f.startswith(("pair_", "sheet_", "crop_", "var_"))]
        else:
            files.append(a)
    if md:
        print("| picture | bright | contrast | sat % | sky sat % | black % | white % |")
        print("|---|---|---|---|---|---|---|")
    for f in files:
        s = stats(f)
        name = os.path.relpath(f, "map_dc/coronado/city_kit/review/look_18nov") if "look_18nov" in f else f
        if md:
            print(f"| {name} | {s['bright']:.0f} | {s['contrast']:.0f} | {s['sat']:.0f} | {s['sky_sat']:.0f} | {s['black']:.1f} | {s['white']:.1f} |")
        else:
            print(f"{name:50s} bright {s['bright']:5.1f}  contrast {s['contrast']:5.1f}  sat {s['sat']:5.1f}%  sky_sat {s['sky_sat']:5.1f}%  black {s['black']:4.1f}%  white {s['white']:4.1f}%")


if __name__ == "__main__":
    main(sys.argv[1:])
