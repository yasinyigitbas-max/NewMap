"""Night windows for the far buildings (look job 5, 18 Nov): the kit's far atlas paints windows as dark marks on lighter
wall bands, and has no glow mask (docs/RUNTIME_BAKE.md "Not done"). This finds the windows in it - texels clearly
darker than the wall around them, on bands light enough to be walls - and writes the atlas again with that mask in
its ALPHA channel, so the far shader reads colour and mask in ONE texture read (docs/look_patches/far_windows.md).
Derived data: map_dc/coronado/city_kit/runtime_tex/far_color_glow.png (+ a preview of the mask). The kit file is not touched.
Run from the repo root: python3 -I tools/city/look/make_far_glow.py
"""
import os
import numpy as np
from PIL import Image, ImageFilter

SRC = "assets/coronado_kit/textures/far_color.png"
OUT = "map_dc/coronado/city_kit/runtime_tex/far_color_glow.png"


def drop_runs(b, longest):
    """band edges are long runs, windows are short: clear every run of a row longer than `longest`"""
    b = b.copy()
    for y in range(b.shape[0]):
        row = b[y]; x = 0; n = row.size
        while x < n:
            if row[x]:
                e = x
                while e < n and row[e]:
                    e += 1
                if e - x > longest:
                    row[x:e] = False
                x = e
            else:
                x += 1
    return b


def main():
    im = Image.open(SRC).convert("RGB")
    a = np.asarray(im).astype(float) / 255.0
    lum = a @ np.array([0.299, 0.587, 0.114])
    L = Image.fromarray((lum * 255).astype(np.uint8))
    bg = np.asarray(L.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MedianFilter(9))).astype(float) / 255.0
    win = (lum < bg * 0.62) & (bg > 0.3)
    w = drop_runs(drop_runs(win, 24).T, 40).T
    m = Image.fromarray((w * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    # on the darker bands the frames are found, not the glass: close the rings into whole windows
    m = m.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(7))
    mask = drop_runs(drop_runs(np.asarray(m) > 127, 30).T, 40).T.astype(float)
    rgba = np.dstack([np.asarray(im), (mask * 255).astype(np.uint8)])
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    Image.fromarray(rgba.astype(np.uint8), "RGBA").save(OUT)
    Image.fromarray((mask * 255).astype(np.uint8)).resize((1024, 1024)).save(OUT.replace(".png", "_mask_preview.png"))
    print("FAR_GLOW %s window texels %.1f %%" % (OUT, 100.0 * mask.mean()))


if __name__ == "__main__":
    main()
