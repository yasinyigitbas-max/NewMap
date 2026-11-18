"""City-kit terrain -> the game's terrain data format (17 Nov, terrain step 3).

Writes map_dc/coronado/terrain/data_citykit/: the SAME files the game reads from terrain/data/ (meta.json, height.f32z,
class.r8z, shore_dist.r8z, water_dist.r8z, ground_params.*, golf_detail.*, bank.json, riprap.json, pools.json),
so the game runs on the city kit's ground with the user arg --citykit (CoronadoTerrain.data_dir()). terrain/data/ and
the live game are untouched; the switch-over happens with the rest of the city-kit integration.

  heights  world 4 m samples: inside the city grid box the city kit terrain (terrain_grid.npz, bilinear in the grid
           frame u, v = grid.to_grid(x, z)); a 16 m hand-over to today's ground at the box's land edges; outside the
           box today's ground, except the coast CUT (plan.CUT: the Strand / Shores / south base are sea now): sea floor
           sloping 8 % down from the cut line to today's depth
  class    city box: sea / bay (the nearest of today's water classes), sand on the beach band (smooth distance to the
           coast <= 25 m and height < 1.6 m), grass on the rest of the land (the pieces cover streets and blocks)
  shore_dist / water_dist   recomputed exactly as bake_terrain.py does, from the new class map
  ground_params             bake_ground_params.py run on this directory (CORONADO_TERRAIN_DATA); the noise
           textures are map-independent and stay in terrain/data/ only
  golf / bank / riprap / pools   today's features minus everything inside the city box or the cut (the golf course,
           the Shore Blvd revetment and the hotel pools come back with their hero sites)
  far_drop  not written (missing file = 0 everywhere; the city terrain is smooth). Rerun bake_far_drop.py if the far
           tiles ever show through.
Usage: python3 -I tools/city/pilot/zoning/bake_game_terrain.py
"""
import json, os, sys, shutil, zlib, subprocess
import numpy as np
from scipy import ndimage
import shapely
from shapely.geometry import Polygon, LineString

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "../../../.."))
SRC = os.path.join(ROOT, "map_dc/coronado/terrain/data")
OUT = os.path.join(ROOT, "map_dc/coronado/terrain/data_citykit")
KIT = os.path.join(ROOT, "map_dc/coronado/city_kit")
sys.path.insert(0, HERE)
from grid import O, A, B          # noqa: E402
import plan                       # noqa: E402

BLEND = 16.0       # terrain.py pins the box's outer node rings to today's ground: only a seam-free hand-over is left


def main():
    os.makedirs(OUT, exist_ok=True)
    m = json.load(open(os.path.join(SRC, "meta.json")))
    W, Hh = m["size_px"]; ox, oz = m["origin_xz"]; mpp = m["metres_per_pixel"]
    old = np.frombuffer(zlib.decompress(open(os.path.join(SRC, m["height_file"]), "rb").read()), "<f4").reshape(Hh, W).astype(float)
    cw, ch = m["class_size"]; cres = m["class_res"]
    cold = np.frombuffer(zlib.decompress(open(os.path.join(SRC, m["class_file"]), "rb").read()), np.uint8).reshape(ch, cw)
    tg = np.load(os.path.join(KIT, "zoning/terrain_grid.npz"))
    T = tg["heights"].astype(float); tsea = tg["sea"]; u0 = float(tg["u0"]); v0 = float(tg["v0"]); st = float(tg["step"])
    tny, tnx = T.shape; u1 = u0 + st * (tnx - 1); v1 = v0 + st * (tny - 1)
    coast = json.load(open(os.path.join(KIT, "zoning/coast.json")))

    def to_uv(X, Z):
        dx = X - O[0]; dz = Z - O[1]
        return dx * B[0] + dz * B[1], dx * A[0] + dz * A[1]

    def tsample(arr, U, V):
        fx = np.clip((U - u0) / st, 0, tnx - 1.001); fy = np.clip((V - v0) / st, 0, tny - 1.001)
        i = fx.astype(int); j = fy.astype(int); tx = fx - i; ty = fy - j
        return (arr[j, i] * (1 - tx) * (1 - ty) + arr[j, i + 1] * tx * (1 - ty) + arr[j + 1, i] * (1 - tx) * ty + arr[j + 1, i + 1] * tx * ty)

    # ---- heights
    X = ox + mpp * np.arange(W)[None, :] + 0 * np.arange(Hh)[:, None]
    Z = oz + mpp * np.arange(Hh)[:, None] + 0 * np.arange(W)[None, :]
    U, V = to_uv(X, Z)
    inbox = (U >= u0) & (U <= u1) & (V >= v0) & (V <= v1)
    edge = np.minimum.reduce([U - u0, u1 - U, V - v0, v1 - V])
    wgt = np.clip(edge / BLEND, 0.0, 1.0); wgt = wgt * wgt * (3 - 2 * wgt)
    city = tsample(T, U, V)
    cut = Polygon(plan.CUT)
    incut = shapely.contains_xy(cut, X, Z)
    cut_line = LineString(list(cut.exterior.coords))
    dcut = shapely.distance(cut_line, shapely.points(X.ravel(), Z.ravel())).reshape(X.shape)
    outside = np.where(incut, np.minimum(old, np.maximum(0.3 - 0.08 * dcut, np.minimum(old, -0.5 - 0.02 * dcut))), old)
    # the city box's sea edge: the box rows next to the sea keep the city's sea floor; blend only where both are land
    h = np.where(inbox, wgt * city + (1 - wgt) * outside, outside)
    hq_min, hq_max = float(h.min()), float(h.max())
    open(os.path.join(OUT, "height.f32z"), "wb").write(zlib.compress(h.astype("<f4").tobytes(), 9))
    # ---- class (2.5 m grid)
    Xc = ox + cres * (np.arange(cw)[None, :] + 0.0) + 0 * np.arange(ch)[:, None]
    Zc = oz + cres * (np.arange(ch)[:, None] + 0.0) + 0 * np.arange(cw)[None, :]
    Uc, Vc = to_uv(Xc, Zc)
    inb = (Uc >= u0) & (Uc <= u1) & (Vc >= v0) & (Vc <= v1)
    edgec = np.minimum.reduce([Uc - u0, u1 - Uc, Vc - v0, v1 - Vc])
    city_here = inb & (edgec > BLEND * 0.5)
    hc = tsample(T, Uc, Vc)
    seac = tsample(tsea.astype(float), Uc, Vc) > 0.5
    cutc = shapely.contains_xy(cut, Xc, Zc)
    wet_old = np.isin(cold, (0, 7))
    _, (jj, ii) = ndimage.distance_transform_edt(~wet_old, return_indices=True)
    nearest_water = cold[jj, ii]                     # sea (0) on the ocean side, bay (7) on the bay side
    from shapely.geometry import MultiLineString
    cl = MultiLineString([[tuple(p) for p in l] for l in coast["sea"] if len(l) > 1])
    c = cold.copy()
    # the cut: today's land there becomes water of the nearest kind
    c = np.where(cutc & ~wet_old, nearest_water, c)
    # the city box: water / sand / grass
    idx = np.nonzero(city_here)
    dco = shapely.distance(cl, shapely.points(Uc[idx], Vc[idx]))
    dcoast = np.full(c.shape, 1e9); dcoast[idx] = dco
    land_city = city_here & ~seac
    c = np.where(city_here & seac, nearest_water, c)
    c = np.where(land_city, 3, c)                                    # grass
    c = np.where(land_city & (dcoast <= 25.0) & (hc < 1.6), 2, c)    # sand: the beach band
    c = c.astype(np.uint8)
    open(os.path.join(OUT, "class.r8z"), "wb").write(zlib.compress(c.tobytes(), 9))
    # shore / water distance: the same formulas as bake_terrain.py
    shore = ndimage.distance_transform_edt(~np.isin(c, (0, 7))) * cres
    open(os.path.join(OUT, "shore_dist.r8z"), "wb").write(zlib.compress(np.clip(shore * 8.0, 0, 255).astype(np.uint8).tobytes(), 9))
    wet = np.isin(c, (0, 7))
    w2 = ndimage.zoom(wet.astype(np.float32), 2, order=1) > 0.5
    wd2 = ndimage.gaussian_filter(ndimage.distance_transform_edt(w2) * cres / 2.0, 16.0)
    wd = wd2.reshape(ch, 2, cw, 2).mean((1, 3))
    open(os.path.join(OUT, "water_dist.r8z"), "wb").write(zlib.compress(np.clip(wd * 4.0, 0, 255).astype(np.uint8).tobytes(), 9))
    # ---- meta
    m2 = dict(m); m2["min_m"] = hq_min; m2["max_m"] = hq_max
    m2["note_citykit"] = "city-kit terrain (tools/city/pilot/zoning/bake_game_terrain.py from zoning/terrain_grid.npz); read with --citykit"
    counts = np.bincount(c.ravel(), minlength=16)
    m2["class_counts_citykit"] = {m["classes"][k]: int(counts[k]) for k in range(16) if counts[k]}
    json.dump(m2, open(os.path.join(OUT, "meta.json"), "w"), indent=1)
    # ---- side features: drop what lies in the city box or the cut

    def gone(x, z):
        x = np.asarray(x, float); z = np.asarray(z, float)
        uu, vv = to_uv(x, z)
        return ((uu >= u0) & (uu <= u1) & (vv >= v0) & (vv <= v1)) | shapely.contains_xy(cut, x, z)

    rp = json.load(open(os.path.join(SRC, "riprap.json")))
    bl = np.array(rp["boulders"], dtype=object)
    keep = [b for b in rp["boulders"] if not gone(b[0], b[1])]
    rp["boulders"] = keep; json.dump(rp, open(os.path.join(OUT, "riprap.json"), "w"))
    bk = json.load(open(os.path.join(SRC, "bank.json")))
    vv_ = np.array(bk["v"], float).reshape(-1, 3); ii_ = np.array(bk["i"], int).reshape(-1, 3)
    vg = gone(vv_[:, 0], vv_[:, 2])
    tk = ~vg[ii_].any(1)
    used = np.unique(ii_[tk]); remap = -np.ones(len(vv_), int); remap[used] = np.arange(len(used))
    bk["v"] = [round(float(x), 2) for x in vv_[used].ravel()]; bk["i"] = [int(x) for x in remap[ii_[tk]].ravel()]
    json.dump(bk, open(os.path.join(OUT, "bank.json"), "w"))
    pl = json.load(open(os.path.join(SRC, "pools.json")))
    pl["pools"] = [p for p in pl["pools"] if not gone(p["ring"][0][0], p["ring"][0][1])]
    json.dump(pl, open(os.path.join(OUT, "pools.json"), "w"))
    gd = json.load(open(os.path.join(SRC, "golf_detail.json")))
    TILE = 200.0
    def tile_gone(t):
        xs = [ox + TILE * t[0] + a for a in (0, TILE)]; zs = [oz + TILE * t[1] + b for b in (0, TILE)]
        return bool(gone([xs[0], xs[1], xs[0], xs[1], (xs[0] + xs[1]) / 2], [zs[0], zs[0], zs[1], zs[1], (zs[0] + zs[1]) / 2]).any())
    ntiles = len(gd["tiles"])
    gd["tiles"] = [t for t in gd["tiles"] if not tile_gone(t["tile"])]
    # repack the kept tiles' byte slices into a smaller golf_detail.bin (offsets rewritten)
    blob = open(os.path.join(SRC, "golf_detail.bin"), "rb").read(); out_b = bytearray()
    for t in gd["tiles"]:
        for k in ("v", "c", "n", "i", "wv", "wc", "wi"):
            if k in t:
                o_, n_ = t[k]; t[k] = [len(out_b), n_]; out_b += blob[o_:o_ + n_]
    open(os.path.join(OUT, "golf_detail.bin"), "wb").write(bytes(out_b))
    json.dump(gd, open(os.path.join(OUT, "golf_detail.json"), "w"))
    for f in ("far_drop.f32z",):
        p = os.path.join(OUT, f)
        if os.path.exists(p): os.remove(p)
    # ---- ground params + noise from this directory
    env = dict(os.environ); env["CORONADO_TERRAIN_DATA"] = OUT
    subprocess.run([sys.executable, "-I", os.path.join(ROOT, "map_dc/coronado/terrain/tools/bake_ground_params.py")], check=True, env=env)
    for f in ("noise_lattice.r8z", "noise_macro.r8z"):     # map-independent (fixed seed): the game reads them from data/
        os.remove(os.path.join(OUT, f))
    # ---- checks
    print("heights %dx%d, min %.1f max %.1f m; city box samples %d" % (W, Hh, hq_min, hq_max, int(inbox.sum())))
    print("riprap %d -> %d, bank tris %d -> %d, pools -> %d, golf tiles %d -> %d" % (len(bl), len(keep), len(ii_), int(tk.sum()), len(pl["pools"]), ntiles, len(gd["tiles"])))
    print("classes in the city box:", {m["classes"][k]: int(v) for k, v in enumerate(np.bincount(c[city_here], minlength=16)) if v})
    gy, gx = np.gradient(h, mpp)
    seam = inbox & (wgt > 0) & (wgt < 1) & (h > 0.3)
    print("blend band (land): max slope %.1f %%" % (100 * np.hypot(gx, gy)[seam].max() if seam.any() else 0.0))


if __name__ == "__main__":
    main()
