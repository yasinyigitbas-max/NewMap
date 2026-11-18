"""Close-up wall detail (look job 3, 18 Nov): one small tiling texture of fine plaster / masonry grain, mixed into the
building walls only near the camera (rt_bldg.gdshader, ck_look_detail). Made here from noise, nothing copied.
256 x 256, seamless, grey around 0.5 (0.5 = no change). Run from the repo root: python3 -I tools/city/look/make_detail.py
-> map_dc/coronado/city_kit/look/detail_wall.png
"""
import os
import numpy as np
from PIL import Image

N = 256
rng = np.random.default_rng(18)


def tile_noise(cells):
    """seamless value noise: random grid of cells x cells, bicubic-upscaled with wrap"""
    g = rng.random((cells, cells))
    big = np.tile(g, (3, 3))
    im = Image.fromarray((big * 255).astype(np.uint8)).resize((N * 3, N * 3), Image.BICUBIC)
    a = np.asarray(im).astype(float) / 255.0
    return a[N:2 * N, N:2 * N]


def main():
    d = 0.45 * tile_noise(8) + 0.3 * tile_noise(32) + 0.25 * tile_noise(128)
    d += 0.35 * (rng.random((N, N)) - 0.5) * 0.4          # grain
    pits = rng.random((N, N)) > 0.992                       # small pits and specks
    d[pits] -= 0.35
    d = (d - d.mean()) / (d.std() + 1e-6) * 0.11 + 0.5
    img = Image.fromarray((np.clip(d, 0, 1) * 255).astype(np.uint8), "L")
    out = "map_dc/coronado/city_kit/look/detail_wall.png"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print("DETAIL", out, img.size, "mean %.3f std %.3f" % (np.asarray(img).mean() / 255, np.asarray(img).std() / 255))


if __name__ == "__main__":
    main()
