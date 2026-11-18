#!/usr/bin/env python3
"""LOOK QUEUE 2, JOB 3: the data of the look's sea (tools/city/look/sea.gd, sea.gdshader).
Writes tools/city/look/sea_map.png, 8 m a texel over the coast frame of zoning/coast.py (x -1800..1900, z -1950..900
in the city kit's own frame, which is the grid frame [u, v] of coast.json):
  R  water depth / 20 m (from zoning/terrain_grid.npz: the final terrain, sea plane at 0 m; deep water outside it)
  G  255 where the water surface is laid: the sea outside the island outline (zoning/coast.json "sea", which is the
     island's outline) plus 25 m onto the land, so the surface meets the beach under the land and the real waterline
     is where the flat water at 0 m cuts the beach: the 0 m contour, which is the line the shore foam piece
     (x_shore_foam, zoning/shore_foam.py) follows. So water and foam meet without a seam; the foam is not touched.
The ponds of coast.json are left out: they sit at land height (1.8-4.7 m), not at the sea's 0 m, and lie outside the
city's cells.
Run from the repo root:  python3 tools/city/look/make_sea.py      (numpy, Pillow, shapely)
"""
import json, os
import numpy as np
import shapely
from shapely.geometry import Polygon
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../..")
KIT = os.path.join(ROOT, "map_dc/coronado/city_kit")
X0, X1, Z0, Z1 = -1800.0, 1900.0, -1950.0, 900.0
STEP = 8.0
ONTO_LAND = 25.0
DEEP = 20.0


def main():
    coast = json.load(open(os.path.join(KIT, "zoning/coast.json")))
    island = Polygon(coast["sea"][0]).buffer(0)
    inner = island.buffer(-ONTO_LAND)
    g = np.load(os.path.join(KIT, "zoning/terrain_grid.npz"))
    H = g["heights"]; u0, v0, st = float(g["u0"]), float(g["v0"]), float(g["step"])
    xs = np.arange(X0, X1 + 0.1, STEP); zs = np.arange(Z0, Z1 + 0.1, STEP)
    XX, ZZ = np.meshgrid(xs, zs)
    land = shapely.contains_xy(island, XX, ZZ)
    under = shapely.contains_xy(inner, XX, ZZ)
    # depth: the terrain where it has data, else deep water
    fj = (XX - u0) / st; fi = (ZZ - v0) / st
    ok = (fj >= 0) & (fi >= 0) & (fj < H.shape[1] - 1) & (fi < H.shape[0] - 1)
    j = np.clip(fj.astype(int), 0, H.shape[1] - 2); i = np.clip(fi.astype(int), 0, H.shape[0] - 2)
    tj = np.clip(fj - j, 0, 1); ti = np.clip(fi - i, 0, 1)
    h = (H[i, j] * (1 - tj) * (1 - ti) + H[i, j + 1] * tj * (1 - ti) + H[i + 1, j] * (1 - tj) * ti + H[i + 1, j + 1] * tj * ti)
    # where the terrain's data ends, blend to deep water over 200 m (no step in the colour far out)
    edge = np.minimum.reduce([XX - u0, (u0 + st * (H.shape[1] - 1)) - XX, ZZ - v0, (v0 + st * (H.shape[0] - 1)) - ZZ])
    w = np.clip(edge / 200.0, 0.0, 1.0)
    depth = np.where(ok, np.clip(-h, 0.0, DEEP) * w + DEEP * (1 - w) * (~land), np.where(land, 0.0, DEEP))
    lay = ~under
    # the island runs past the frame in the west: no water strip along a frame edge that cuts through land
    rim = (XX < X0 + ONTO_LAND + STEP) | (XX > X1 - ONTO_LAND - STEP) | (ZZ < Z0 + ONTO_LAND + STEP) | (ZZ > Z1 - ONTO_LAND - STEP)
    lay[land & rim] = False
    img = np.zeros(XX.shape + (3,), np.uint8)
    img[..., 0] = np.round(depth / DEEP * 255).astype(np.uint8)
    img[..., 1] = np.where(lay, 255, 0).astype(np.uint8)
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sea_map.png")
    Image.fromarray(img, "RGB").save(out, optimize=True)
    meta = {"x0": X0, "z0": Z0, "step": STEP, "deep": DEEP, "w": int(XX.shape[1]), "h": int(XX.shape[0]), "onto_land": ONTO_LAND}
    json.dump(meta, open(out.replace(".png", ".json"), "w"), indent=1)
    print("wrote", out, img.shape[1], "x", img.shape[0], "px,", int(lay.sum()), "water texels;", os.path.getsize(out) // 1024, "KB")


if __name__ == "__main__":
    main()
