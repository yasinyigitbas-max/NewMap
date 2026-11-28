"""CITY LIGHT, part 2 of 3 (look uplift, 28 Nov). Reads runtime/far/city_height.f32 (city_light_bake.gd, part 1: the
highest surface over every 2 m of the island) and writes what the city's shaders read for their light:

  city_ao.u8   RGBA, one texel per height texel: how much SKY a point sees (0 none .. 255 all), at 0.5, 5, 14 and 35 m
               above the ground. A street between tall buildings sees less sky than an open car park, a wall's foot
               less than its top: that is the darkening a real city has and our flat ambient light lacks.
  city_hg.f32  two floats a texel: the highest surface (metres) and the ground under it (metres). The shaders march the
               first towards the sun for the FAR shadows (past the engine's 50 m), and use the second to know how high
               above the ground a pixel is.

Part 3 (city_light_bake.gd --pack) turns both into textures the game loads. Measures only; places nothing.
  python -I tools/city/look/make_city_light.py [runtime_dir]
"""
import json, sys, os, math
import numpy as np
from scipy import ndimage

RT = sys.argv[1] if len(sys.argv) > 1 else "map_dc/coronado/city_kit/runtime"
FAR = os.path.join(RT, "far")
meta = json.load(open(os.path.join(FAR, "city_height.json")))
W, H, T = int(meta["w"]), int(meta["h"]), float(meta["texel"])
hgt = np.fromfile(os.path.join(FAR, "city_height.f32"), dtype=np.float32).reshape(H, W).astype(np.float32)

# the ground: the city's surface with every building taken out (lowest within 48 m, then the highest of that within
# 48 m: an "opening", which keeps hills and removes anything narrower than 48 m), smoothed
k = int(round(48.0 / T)) | 1
ground = ndimage.grey_opening(hgt, size=(k, k))
ground = ndimage.gaussian_filter(ground, sigma=6.0 / T)
ground = np.minimum(ground, hgt)

LEVELS = [0.5, 5.0, 14.0, 35.0]                       # metres above the ground: R, G, B, A
DIRS = 16
STEPS = [2.0, 4.0, 6.0, 9.0, 12.0, 16.0, 21.0, 27.0, 34.0, 42.0, 52.0, 64.0]


def shifted(a, dx, dz):
    """a moved so that out[z, x] = a[z + dz, x + dx] (edges repeat)"""
    ix = np.clip(np.arange(W) + dx, 0, W - 1)
    iz = np.clip(np.arange(H) + dz, 0, H - 1)
    return a[iz][:, ix]


ao = np.zeros((H, W, 4), dtype=np.float32)
for li, lv in enumerate(LEVELS):
    base = ground + lv
    occ = np.zeros((H, W), dtype=np.float32)
    for d in range(DIRS):
        ang = 2.0 * math.pi * (d + 0.5) / DIRS
        cx, cz = math.cos(ang), math.sin(ang)
        best = np.zeros((H, W), dtype=np.float32)       # the steepest rise seen along this direction (tan)
        for s in STEPS:
            dx = int(round(cx * s / T)); dz = int(round(cz * s / T))
            if dx == 0 and dz == 0:
                continue
            dist = math.hypot(dx, dz) * T
            rise = (shifted(hgt, dx, dz) - base) / dist
            np.maximum(best, rise, out=best)
        # the sky lost in this direction: the horizon's elevation, cos-weighted (sin^2 of the angle, as a cosine-
        # weighted hemisphere loses it)
        s2 = best * best / (1.0 + best * best)
        occ += s2
    vis = 1.0 - occ / DIRS
    # inside a building (its surface above this level) nobody looks; a wall pixel that reads a texel there (the far
    # world's box is not the real outline) must get the sky of the nearest point OUTSIDE, not the dark of the inside
    inside = hgt > base + 0.25
    if inside.any():
        _, (iz, ix) = ndimage.distance_transform_edt(inside, return_indices=True)
        vis = vis[iz, ix]
    ao[:, :, li] = vis
    print("CITYLIGHT level %4.1f m: sky seen mean %.3f, 5th percentile %.3f" % (lv, vis.mean(), np.percentile(vis, 5)))

# a little blur: the 2 m steps of the far world's boxes must not show on the ground
for li in range(4):
    ao[:, :, li] = ndimage.gaussian_filter(ao[:, :, li], sigma=0.8)
(np.clip(ao, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8).tofile(os.path.join(FAR, "city_ao.u8"))
np.stack([hgt, ground], axis=-1).astype(np.float32).tofile(os.path.join(FAR, "city_hg.f32"))

# a look at it (not used by the game): the sky seen at the ground, black = none
try:
    from PIL import Image
    Image.fromarray((np.clip(ao[:, :, 0], 0, 1) * 255).astype(np.uint8)).save(os.path.join(FAR, "city_ao_small.png"))
except Exception as e:
    print("CITYLIGHT no preview:", e)
print("CITYLIGHT wrote city_ao.u8 and city_hg.f32 (%d x %d); ground %.1f..%.1f m" % (W, H, ground.min(), ground.max()))
