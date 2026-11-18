#!/usr/bin/env python3
"""The one small texture the look pack's sky reads (tools/city/look/sky.gdshader): sky_noise.png, 256 x 256, tiles.
  R  cloud shapes (soft noise, few big lumps)
  G  cloud detail (finer noise, breaks the edges up)
  B  stars (a few single bright texels, most of them dim)
Run from the repo root:  python3 tools/city/look/make_sky_tex.py      (needs numpy + Pillow; same result every run)
"""
import os
import numpy as np
from PIL import Image

N = 256


def tile_noise(rng, cells):
    """Value noise that tiles: a random grid of `cells` x `cells`, smoothly interpolated up to N x N."""
    g = rng.random((cells, cells)).astype(np.float32)
    t = np.arange(N, dtype=np.float32) * cells / N
    i0 = np.floor(t).astype(int) % cells
    i1 = (i0 + 1) % cells
    f = t - np.floor(t)
    f = f * f * f * (f * (f * 6 - 15) + 10)
    fx = f[None, :]
    fy = f[:, None]
    a = g[i0][:, i0] * (1 - fx) + g[i0][:, i1] * fx
    b = g[i1][:, i0] * (1 - fx) + g[i1][:, i1] * fx
    return a * (1 - fy) + b * fy


def fbm(rng, first, octaves, gain=0.5):
    out = np.zeros((N, N), np.float32)
    amp = 1.0
    tot = 0.0
    cells = first
    for _ in range(octaves):
        out += tile_noise(rng, cells) * amp
        tot += amp
        amp *= gain
        cells *= 2
    out /= tot
    lo, hi = np.percentile(out, 1), np.percentile(out, 99)
    return np.clip((out - lo) / (hi - lo), 0, 1)


def main():
    rng = np.random.default_rng(1811)
    shape = fbm(rng, 3, 5, 0.52)
    detail = fbm(rng, 8, 4, 0.6)
    stars = np.zeros((N, N), np.float32)
    n = 150
    ys = rng.integers(0, N, n)
    xs = rng.integers(0, N, n)
    stars[ys, xs] = np.clip(rng.random(n) ** 3.0 * 0.9 + 0.1, 0, 1)
    img = np.stack([shape, detail, stars], axis=2)
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sky_noise.png")
    Image.fromarray((img * 255 + 0.5).astype(np.uint8), "RGB").save(out, optimize=True)
    print("wrote", out, os.path.getsize(out) // 1024, "KB")


if __name__ == "__main__":
    main()
