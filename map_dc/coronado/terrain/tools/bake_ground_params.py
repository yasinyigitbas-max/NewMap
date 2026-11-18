#!/usr/bin/env python3
"""terrain-cheap1: bake what terrain.gdshader used to work out per pixel from world position alone.

Rerunnable: reads data/class.r8z + data/shore_dist.r8z (bake_terrain.py output), writes (data/):
  ground_params.r8z  zlib(RGBA8, class_size W*H, row 0 = north), same 2.5 m grid as class.r8z:
      R = effective class (bits 0-3) | shore flag << 4
          class 15 (raster path) already swapped for the ground class next to it (the old 8-tap loop, first of
          13 / 4 / 10 found on a 2-texel ring, else 3 lawn); shore flag = distance from the sea / bay edge < 10 m
          (the old `sd < 10.0` beach test). The shader reads R with textureGather (nearest, smooth borders).
      G = golf fairway fraction  (fairway or green texels, centre + rings r 2.8 m / 5.6 m, the old 17-tap loop)
      B = golf green fraction    (green texels, same taps)
      A = path wear fraction     (path texels on the 6-tap ring r 3 m, the old lawn-wear loop)
      G/B/A are the old loops' expected value (ring averaged over the old angle jitter, 2x2 supersampled per
      texel), read bilinear; the shader adds back the old jitter as a small noise wobble.
  noise_lattice.r8z  zlib(RGBA8 256x256): 4 independent value-noise lattices (uniform bytes, like the old h21 hash).
      One bilinear fetch at (floor(p) + smoothstep(fract(p)) + 0.5) / 256 = the old vnoise(p), 4 channels at once.
  noise_macro.r8z    zlib(RGBA8 1024x1024): seamless value noise, 2 m texels, tile 2048 m (larger than any view
      repeat matters for), lattice R 14.03 m, G 35.31 m, B 60.24 m, A 20.08 m (the old vnoise(q / 14|35|60|20)).
  ground_params.json sha256 of the two inputs (tests/test_terrain_params.gd flags a stale bake).
Run from anywhere: python3 map_dc/coronado/terrain/tools/bake_ground_params.py  (numpy only, ~20 s)."""
import hashlib, json, os, zlib
import numpy as np

DATA = os.environ.get("CORONADO_TERRAIN_DATA") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")   # city kit: data_citykit
meta = json.load(open(os.path.join(DATA, "meta.json"), encoding="utf-8"))
W, H = meta["class_size"]; RES = meta["class_res"]
cls_raw = open(os.path.join(DATA, "class.r8z"), "rb").read()
shore_raw = open(os.path.join(DATA, "shore_dist.r8z"), "rb").read()
cls = np.frombuffer(zlib.decompress(cls_raw), np.uint8).reshape(H, W)
shore = np.frombuffer(zlib.decompress(shore_raw), np.uint8).reshape(H, W)


def shifted(a, di, dj):
	"""a[j + dj, i + di] with edge clamp (the shader samplers clamp: repeat_disable)."""
	jj = np.clip(np.arange(H) + dj, 0, H - 1); ii = np.clip(np.arange(W) + di, 0, W - 1)
	return a[jj][:, ii]


def tap(a, du, dv):
	"""nearest texel at texel centre + (du, dv) texels: index i + floor(0.5 + du) (exact for every texel)."""
	return shifted(a, int(np.floor(0.5 + du)), int(np.floor(0.5 + dv)))


SUB = [(-0.25, -0.25), (0.25, -0.25), (-0.25, 0.25), (0.25, 0.25)]   # 2x2 supersample inside the texel


def ring_mean(ind, r_m, n_ang):
	"""mean of indicator over a ring of radius r_m (angles uniform), 2x2 supersampled."""
	acc = np.zeros((H, W), np.float32); r = r_m / RES
	for su, sv in SUB:
		for k in range(n_ang):
			a = 2.0 * np.pi * k / n_ang
			acc += tap(ind, su + np.cos(a) * r, sv + np.sin(a) * r)
	return acc / (len(SUB) * n_ang)


def centre_mean(ind):
	acc = np.zeros((H, W), np.float32)
	for su, sv in SUB: acc += tap(ind, su, sv)
	return acc / len(SUB)


# 1. path texels -> neighbouring ground class (old shader: 8 taps at angle k*0.785, 2 texels out, first 13/4/10 wins)
eff = cls.copy()
path = cls == 15
eff[path] = 3
found = np.zeros((H, W), bool)
for k in range(8):
	a = k * 0.785
	cn = tap(cls, np.cos(a) * 2.0, np.sin(a) * 2.0)
	hit = path & ~found & np.isin(cn, (13, 4, 10))
	eff[hit] = cn[hit]; found |= hit
# 2. shore flag: old test was `sd < 10.0` with sd = byte * 0.125 m
flag = (shore < 80).astype(np.uint8)
r_ch = (eff & 15) | (flag << 4)
# 3. golf fractions: old loop = centre + 8 taps r 2.8 m + 8 taps r 5.6 m, angles k*0.785 + vnoise*1.5 jitter -> ring mean
fwi = np.isin(cls, (4, 8)).astype(np.float32); gri = (cls == 8).astype(np.float32)
fw = (centre_mean(fwi) + 8.0 * ring_mean(fwi, 2.8, 32) + 8.0 * ring_mean(fwi, 5.6, 48)) / 17.0
gr = (centre_mean(gri) + 8.0 * ring_mean(gri, 2.8, 32) + 8.0 * ring_mean(gri, 5.6, 48)) / 17.0
# 4. path wear: old loop = 6 taps at angle k*1.047, r 3 m, count of path texels / 6 (no jitter: the same 6 taps)
pi_ = path.astype(np.float32)
pn = np.zeros((H, W), np.float32)
for su, sv in SUB:
	for k in range(6):
		a = k * 1.047
		pn += tap(pi_, su + np.cos(a) * 3.0 / RES, sv + np.sin(a) * 3.0 / RES)
pn /= len(SUB) * 6
u8 = lambda x: np.clip(np.rint(x * 255.0), 0, 255).astype(np.uint8)
params = np.stack([r_ch.astype(np.uint8), u8(fw), u8(gr), u8(pn)], axis=-1)
open(os.path.join(DATA, "ground_params.r8z"), "wb").write(zlib.compress(params.tobytes(), 9))

# 5. noise textures (fixed seed: rerun = same bytes)
rng = np.random.default_rng(20261111)
lat = rng.integers(0, 256, size=(256, 256, 4), dtype=np.uint8)
open(os.path.join(DATA, "noise_lattice.r8z"), "wb").write(zlib.compress(lat.tobytes(), 9))
MW = 1024; CELLS = (146, 58, 34, 102)   # lattice cells per 2048 m tile -> 14.03 / 35.31 / 60.24 / 20.08 m


def vnoise_periodic(n, size):
	lv = rng.random((n, n))
	p = (np.arange(size) + 0.5) * n / size
	i0 = np.floor(p).astype(int); f = p - i0; f = f * f * (3.0 - 2.0 * f)
	i0 %= n; i1 = (i0 + 1) % n
	a = lv[i0][:, i0] * (1 - f)[None, :] + lv[i0][:, i1] * f[None, :]
	b = lv[i1][:, i0] * (1 - f)[None, :] + lv[i1][:, i1] * f[None, :]
	return a * (1 - f)[:, None] + b * f[:, None]


macro = np.stack([u8(vnoise_periodic(n, MW)) for n in CELLS], axis=-1)
open(os.path.join(DATA, "noise_macro.r8z"), "wb").write(zlib.compress(macro.tobytes(), 9))
json.dump({"note": "terrain-cheap1 ground params (bake_ground_params.py); inputs sha256",
	"class_sha256": hashlib.sha256(open(os.path.join(DATA, "class.r8z"), "rb").read()).hexdigest(),
	"shore_sha256": hashlib.sha256(shore_raw).hexdigest(), "size": [W, H], "lattice": 256, "macro": MW,
	"macro_cells": list(CELLS), "macro_tile_m": 2048.0},
	open(os.path.join(DATA, "ground_params.json"), "w", encoding="utf-8", newline="\n"), indent=1)
print("paths %d (to 13/4/10: %d)  golf texels %d  shore-flag texels %d" % (path.sum(), found.sum(), (fwi > 0).sum(), flag.sum()))
for f in ("ground_params.r8z", "noise_lattice.r8z", "noise_macro.r8z"):
	print(f, os.path.getsize(os.path.join(DATA, f)), "bytes")
