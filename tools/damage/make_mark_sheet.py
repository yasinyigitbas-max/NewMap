#!/usr/bin/env python3
"""The damage system's two texture sheets (25 Nov 2026, made here, no downloads):

  assets/damage/marks.png   4 x 4 tiles of 128 px: hit marks, drawn MULTIPLIED onto the surface (white = no change),
                            so they darken a lit wall by day and a dark wall by night the same way (no light of their own).
  assets/damage/sprites.png 4 x 4 tiles of 64 px: the particles (dust, chips, sparks, splinters, leaves, glass, drops),
                            drawn mixed (alpha).

The tile numbers are the C++ constants in native/src/city_damage.h (MARK_* and SPR_*): keep them in step.
Run: python3 -I tools/damage/make_mark_sheet.py   (deterministic: same files every run)
"""
import math
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "damage")
T = 128          # mark tile
S = 64           # sprite tile
rng = np.random.default_rng(25112026)


def grid(n):
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    x = (x + 0.5) / n * 2.0 - 1.0
    y = (y + 0.5) / n * 2.0 - 1.0
    return x, y, np.sqrt(x * x + y * y), np.arctan2(y, x)


def noise(n, scale, octaves=4):
    """value noise, tiling not needed (each tile fades to white at its edge)"""
    out = np.zeros((n, n), np.float32)
    amp = 1.0
    tot = 0.0
    for o in range(octaves):
        g = max(2, int(scale * (2 ** o)))
        base = rng.random((g + 1, g + 1)).astype(np.float32)
        img = Image.fromarray((base * 255).astype(np.uint8)).resize((n, n), Image.BICUBIC)
        out += amp * (np.asarray(img, np.float32) / 255.0)
        tot += amp
        amp *= 0.5
    return out / tot


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def angular_noise(ang, k, amt):
    """a radius wobble round the angle (chipped edge)"""
    r = np.zeros_like(ang)
    for i in range(1, k + 1):
        r += rng.uniform(-1, 1) * np.cos(i * ang + rng.uniform(0, 6.28)) / i
    return 1.0 + amt * r


def hole(core_rgb, chip_rgb, core_r, chip_r, cracks=0, chip_amt=0.35, n=T):
    """a bullet hole: a dark core, a chipped ring (spall), optional hairline cracks. Returns RGB in 0..1, white = none."""
    x, y, r, a = grid(n)
    nz = noise(n, 6)
    core_edge = core_r * angular_noise(a, 7, 0.25)
    chip_edge = chip_r * angular_noise(a, 11, chip_amt) * (0.85 + 0.3 * nz)
    core = 1.0 - smooth(core_edge * 0.8, core_edge, r)
    chip = (1.0 - smooth(chip_edge * 0.75, chip_edge, r)) * (0.55 + 0.45 * nz)
    img = np.ones((n, n, 3), np.float32)
    for c in range(3):
        img[..., c] = img[..., c] * (1 - chip) + chip_rgb[c] * chip
        img[..., c] = img[..., c] * (1 - core) + core_rgb[c] * core
    for _ in range(cracks):
        ang0 = rng.uniform(-math.pi, math.pi)
        length = rng.uniform(0.45, 0.9)
        d = np.abs(np.sin(a - ang0)) * r
        along = np.cos(a - ang0) * r
        wob = 0.012 + 0.01 * nz
        line = (1.0 - smooth(0.0, wob, d)) * (along > 0) * (1.0 - smooth(length * 0.6, length, r))
        for c in range(3):
            img[..., c] = img[..., c] * (1 - 0.55 * line) + 0.35 * line * chip_rgb[c]
    return img


def scuff(rgb, sx, sy, strength, streaks=0.0, n=T):
    x, y, r, a = grid(n)
    nz = noise(n, 5)
    e = np.sqrt((x / sx) ** 2 + (y / sy) ** 2)
    m = (1.0 - smooth(0.55, 1.0, e)) * (0.45 + 0.55 * nz) * strength
    if streaks > 0:
        st = noise(n, 3, 2)
        lines = 0.5 + 0.5 * np.sin(y * 60.0 + st * 9.0)
        m *= (1.0 - streaks) + streaks * lines
    img = np.ones((n, n, 3), np.float32)
    for c in range(3):
        img[..., c] = 1.0 - m * (1.0 - rgb[c])
    return img


def bark_scar(n=T):
    x, y, r, a = grid(n)
    nz = noise(n, 4)
    e = np.sqrt((x / 0.45) ** 2 + (y / 0.85) ** 2)
    m = 1.0 - smooth(0.6, 1.0, e * (0.9 + 0.2 * nz))
    fib = 0.5 + 0.5 * np.sin(x * 40.0 + noise(n, 3, 2) * 6.0)
    pale = np.array([0.95, 0.83, 0.62])          # the light wood under the bark (mul: just darker than white)
    img = np.ones((n, n, 3), np.float32)
    for c in range(3):
        img[..., c] = 1.0 - m * (1.0 - pale[c] * (0.85 + 0.15 * fib))
    edge = smooth(0.75, 0.9, e) * (1.0 - smooth(0.9, 1.05, e))
    for c in range(3):
        img[..., c] *= 1.0 - 0.45 * edge
    return img


def splinter_hole(n=T):
    img = hole((0.16, 0.11, 0.07), (0.86, 0.74, 0.55), 0.09, 0.32, cracks=0, chip_amt=0.5, n=n)
    x, y, r, a = grid(n)
    nz = noise(n, 4)
    # splinters along the grain (x): torn, pale fibres either side
    fib = (np.abs(y) < 0.10 + 0.06 * nz) * (1.0 - smooth(0.25, 0.75, np.abs(x)))
    for c, v in enumerate((0.88, 0.76, 0.56)):
        img[..., c] = np.minimum(img[..., c], 1.0 - fib * (1.0 - v))
    return img


def tyre(n=T):
    x, y, r, a = grid(n)
    nz = noise(n, 6)
    band = (1.0 - smooth(0.55, 0.9, np.abs(y))) * (1.0 - smooth(0.8, 1.0, np.abs(x)))
    tread = 0.75 + 0.25 * np.sin(x * 45.0)
    m = band * tread * (0.5 + 0.5 * nz) * 0.55
    img = np.ones((n, n, 3), np.float32)
    for c in range(3):
        img[..., c] = 1.0 - m * 0.85
    return img


def divot(n=T):
    x, y, r, a = grid(n)
    nz = noise(n, 6)
    m = (1.0 - smooth(0.3, 0.7 + 0.2 * nz, r)) * (0.6 + 0.4 * nz)
    img = np.ones((n, n, 3), np.float32)
    for c, v in enumerate((0.45, 0.36, 0.27)):
        img[..., c] = 1.0 - m * (1.0 - v)
    return img


def fade_edge(img):
    """every tile ends white at its border, so a quad never shows a hard square"""
    n = img.shape[0]
    x, y, r, a = grid(n)
    e = np.maximum(np.abs(x), np.abs(y))
    f = smooth(0.82, 0.98, e)[..., None]
    return img * (1 - f) + f


def marks_sheet():
    tiles = [
        # 0..3 bullet holes on masonry and render (grey, brick, cream render, stone)
        hole((0.10, 0.10, 0.10), (0.72, 0.72, 0.70), 0.08, 0.30, cracks=3),               # 0 concrete
        hole((0.13, 0.07, 0.05), (0.80, 0.62, 0.55), 0.08, 0.34, cracks=2, chip_amt=0.5), # 1 brick
        hole((0.12, 0.11, 0.10), (0.82, 0.80, 0.76), 0.07, 0.40, cracks=4, chip_amt=0.45),# 2 stucco (render flakes wide)
        hole((0.11, 0.11, 0.12), (0.70, 0.70, 0.72), 0.07, 0.24, cracks=1, chip_amt=0.2), # 3 stone
        # 4 wood, 5 metal (a small dent with a ring), 6 asphalt chip, 7 plastic
        splinter_hole(),
        hole((0.20, 0.20, 0.22), (0.55, 0.56, 0.60), 0.06, 0.14, cracks=0, chip_amt=0.05),
        hole((0.30, 0.30, 0.30), (0.62, 0.62, 0.62), 0.10, 0.30, cracks=0, chip_amt=0.6),
        hole((0.14, 0.14, 0.14), (0.80, 0.80, 0.80), 0.06, 0.16, cracks=5, chip_amt=0.1),
        # 8 bark scar, 9 ground divot (dirt, grass, sand), 10 punch scuff, 11 kick scuff (a sole)
        bark_scar(),
        divot(),
        scuff((0.55, 0.52, 0.50), 0.55, 0.55, 0.6),
        scuff((0.35, 0.33, 0.32), 0.38, 0.75, 0.75, streaks=0.3),
        # 12 car scrape (long, along x), 13 tyre rubber, 14 heavy chip (a car into masonry), 15 a second concrete hole
        scuff((0.42, 0.42, 0.44), 0.95, 0.35, 0.85, streaks=0.8),
        tyre(),
        hole((0.25, 0.24, 0.23), (0.62, 0.61, 0.60), 0.30, 0.70, cracks=6, chip_amt=0.5),
        hole((0.09, 0.09, 0.09), (0.68, 0.68, 0.66), 0.07, 0.26, cracks=4, chip_amt=0.4),
    ]
    sheet = np.ones((T * 4, T * 4, 3), np.float32)
    for i, t in enumerate(tiles):
        t = fade_edge(np.clip(t, 0, 1))
        sheet[(i // 4) * T:(i // 4 + 1) * T, (i % 4) * T:(i % 4 + 1) * T] = t
    return Image.fromarray((sheet * 255 + 0.5).astype(np.uint8), "RGB")


def sprite(kind, n=S):
    x, y, r, a = grid(n)
    nz = noise(n, 4)
    rgb = np.ones((n, n, 3), np.float32)
    al = np.zeros((n, n), np.float32)
    if kind == "puff":
        al = (1.0 - smooth(0.2, 1.0, r * (0.85 + 0.3 * nz))) * 0.9
        rgb[:] = 1.0
    elif kind == "chip":      # an irregular chunk (tinted per surface in the shader)
        e = r * angular_noise(a, 5, 0.35)
        al = 1.0 - smooth(0.45, 0.55, e)
        rgb *= (0.75 + 0.25 * nz)[..., None]
    elif kind == "spark":     # a hot streak along y
        al = (1.0 - smooth(0.0, 0.18, np.abs(x))) * (1.0 - smooth(0.6, 1.0, np.abs(y)))
        rgb[..., 0] = 1.0; rgb[..., 1] = 0.85; rgb[..., 2] = 0.45
    elif kind == "splinter":  # a thin wooden sliver
        al = (1.0 - smooth(0.05, 0.12, np.abs(x + 0.15 * y))) * (1.0 - smooth(0.7, 0.9, np.abs(y)))
        rgb *= (0.8 + 0.2 * nz)[..., None]
    elif kind == "leaf":
        e = np.sqrt((x / 0.45) ** 2 + (y / 0.85) ** 2)
        al = 1.0 - smooth(0.85, 1.0, e)
        vein = 1.0 - 0.35 * (1.0 - smooth(0.0, 0.05, np.abs(x)))
        rgb *= vein[..., None]
    elif kind == "shard":     # a glass triangle with a bright edge
        inside = (y > -0.7) & (y < 0.6 - 1.3 * np.abs(x))
        al = inside.astype(np.float32) * 0.75
        edge = inside & ((y > 0.45 - 1.3 * np.abs(x)) | (y < -0.55))
        rgb[:] = 0.85
        rgb[edge] = 1.0
    elif kind == "drop":      # water
        al = (1.0 - smooth(0.25, 0.5, r)) * 0.8
    elif kind == "clod":      # dirt, grass bits
        e = r * angular_noise(a, 6, 0.45)
        al = 1.0 - smooth(0.4, 0.55, e)
        rgb *= (0.7 + 0.3 * nz)[..., None]
    out = np.zeros((n, n, 4), np.float32)
    out[..., :3] = np.clip(rgb, 0, 1)
    out[..., 3] = np.clip(al, 0, 1)
    return out


def sprites_sheet():
    kinds = ["puff", "chip", "spark", "splinter", "leaf", "shard", "drop", "clod"]
    sheet = np.zeros((S * 4, S * 4, 4), np.float32)
    for i, k in enumerate(kinds):
        sheet[(i // 4) * S:(i // 4 + 1) * S, (i % 4) * S:(i % 4 + 1) * S] = sprite(k)
    return Image.fromarray((sheet * 255 + 0.5).astype(np.uint8), "RGBA")


def main():
    os.makedirs(OUT, exist_ok=True)
    marks_sheet().save(os.path.join(OUT, "marks.png"), optimize=True)
    sprites_sheet().save(os.path.join(OUT, "sprites.png"), optimize=True)
    print("wrote", os.path.join(OUT, "marks.png"), "and sprites.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
