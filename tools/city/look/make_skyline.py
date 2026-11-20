#!/usr/bin/env python3
"""THE SKYLINE RING (20 Nov, Yasin: "PLACE FLAT CARD ACCURATE VIEWS OF SAN DIEGO TO ALL FOUR SIDES, WHATEVER IS ACTUALLY
VISIBLE WHEN LOOKED TOWARD THAT DIRECTION FROM THE ISLAND ... EVER VISIBLE"). Paints the textures that
tools/city/look/skyline.gd draws round the horizon. Painted here, from real positions and heights
(map_dc/coronado/city_kit/skyline/landmarks.json, sources there): no photograph is used.

Geometry (all measured, see the README beside the textures):
  - the game world frame (map_dc/roads/lane_graph.json meta): x east m, z south m from 32.7157 N 117.1611 W,
    93,660.5 m a degree of longitude, 110,574 m a degree of latitude;
  - the city kit's grid frame (tools/city/pilot/zoning/grid.py): origin Amber (Orange Ave) x 10th St = world
    (-1757, 3296), +v along Amber toward SSW, +u along 10th toward ESE. So grid -v (-Z) points to bearing 26.40 deg
    (true), grid +u (+X) to 116.40 deg: TRUE NORTH IS 26.40 DEG ANTICLOCKWISE (to the left) OF -Z, seen from above;
  - the ring is painted as seen from C = grid (0, -600) (Orange Ave at 7th St, the middle of the built city, 32.6908 N
    117.1770 W), eye 6 m above the sea. Texture column = grid azimuth phi (0 = -Z, 90 = +X), clockwise.
Two layers, one texture (an atlas, rows 0-127 / 128-255 of the final 6144 x 256):
  NEAR  things 1-8 km away (downtown, the bridge, the shipyards, North Island, Point Loma, Coronado Shores):
        rows = elevation +5.5 .. -1.5 deg; skyline.gd stands them on a ring of radius r(phi) (RING below) so they
        shift with the camera like the real thing (parallax);
  FAR   everything beyond (mesas, mountains, Tijuana, the islands), the sea below the horizon, a soft haze band
        above it: rows = elevation +7 .. -3 deg, drawn by direction only.
A second texture (half size, one channel) holds where lights shine at night.
Elevation of a point at distance d and height h: atan((h - eye) / d) minus the earth's curve d (1 - k) / 2R
(k = 0.13 refraction). Haze painted with 1 - exp(-d / 25 km) toward the look's day haze colour; skyline.gd tints it
to the look's haze of the hour and adds more haze for thicker looks.
Run from the repo root:  python3 tools/city/look/make_skyline.py      (numpy, Pillow)
"""
import json, math, os, zlib
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../.."))
OUT = os.path.join(ROOT, "map_dc/coronado/city_kit/skyline")
LM = json.load(open(os.path.join(OUT, "landmarks.json")))

# --- frames -------------------------------------------------------------------------------------------------------
LAT0, LON0, MLON, MLAT = 32.7157, -117.1611, 93660.4974882212, 110574.0
GO = np.array([-1757.0, 3296.0]); GA = np.array([-0.4446, 0.8955]); GB = np.array([0.8955, 0.4446])
ROT = math.degrees(math.atan2(0.4446, 0.8955))          # 26.40: bearing of grid -v
C_GRID = (0.0, -600.0)
C_W = GO + GB * C_GRID[0] + GA * C_GRID[1]
EYE = 6.0
R_EARTH, K_REFR = 6371000.0, 0.13
HAZE_L = 25000.0
HAZE = np.array([0.80, 0.78, 0.71])                      # look.gd DAY "haze" (the sky's horizon colour by day)

def world(lat, lon): return np.array([(lon - LON0) * MLON, -(lat - LAT0) * MLAT])

def phi_d(lat, lon):
    p = world(lat, lon) - C_W
    bearing = math.degrees(math.atan2(p[0], -p[1])) % 360.0
    return (bearing - ROT) % 360.0, float(np.hypot(*p))

def elev(h, d):
    return math.degrees(math.atan2(h - EYE, d) - d * (1.0 - K_REFR) / (2.0 * R_EARTH))

def haze_of(d): return 1.0 - math.exp(-d / HAZE_L)

# near-ring radius by grid azimuth (m): where the near layer's things stand (skyline.gd reads the same table from
# skyline.json). Chosen as the distance of what dominates each direction (README).
RING = [(0, 3000), (30, 3100), (55, 2600), (70, 2100), (88, 2600), (100, 4800), (116, 2300), (138, 2100), (150, 5000),
        (210, 6200), (240, 6400), (268, 5500), (282, 2000), (296, 2000), (308, 4600), (330, 4000), (345, 3000), (360, 3000)]

# --- canvases ------------------------------------------------------------------------------------------------------
SS = 2
W = 6144; HN = 128; HF = 128
WS = W * SS
N_TOP, N_BOT = 5.5, -1.5
F_TOP, F_BOT = 7.0, -3.0

class Layer:
    def __init__(self, h, top, bot):
        self.h = h * SS; self.top = top; self.bot = bot
        self.rgb = np.zeros((self.h, WS, 3), np.float32); self.rgb[:] = HAZE
        self.a = np.zeros((self.h, WS), np.float32)
        self.lit = np.zeros((self.h, WS), np.float32)
    def x(self, phi): return phi / 360.0 * WS
    def y(self, el): return (self.top - el) / (self.top - self.bot) * self.h
    def mask(self, pts):
        """pts: [(phi, el)]; drawn three times (wrap round 360). Returns a float mask 0..1."""
        im = Image.new("L", (WS, self.h), 0); dr = ImageDraw.Draw(im)
        xy = [(self.x(p), self.y(e)) for p, e in pts]
        for off in (-WS, 0, WS):
            dr.polygon([(x + off, y) for x, y in xy], fill=255)
        return np.asarray(im, np.float32) / 255.0
    def put(self, m, col, alpha=1.0, lit=None):
        """over-composite through mask m. col / lit: a constant, a full-size array, or a function f(rows, cols) of
        the crop's pixel coordinates (only the columns the mask touches are worked on)"""
        cols = np.nonzero(m.max(axis=0) > 0)[0]
        if cols.size == 0: return
        c0, c1 = int(cols[0]), int(cols[-1]) + 1
        if c1 - c0 > WS // 2 and cols.size < (c1 - c0) // 2: c0, c1 = 0, WS      # wraps round: work on all
        sl = np.s_[:, c0:c1]
        k = m[sl] * alpha
        R = np.arange(self.h)[:, None] + 0.5; X = np.arange(c0, c1)[None, :] + 0.5
        def ev(v, three):
            if callable(v): return v(R, X)
            v = np.asarray(v, np.float32)
            if v.ndim >= 2 and v.shape[0] == self.h and v.shape[1] == WS: return v[sl]
            return v
        c = ev(col, True)
        self.rgb[sl] = self.rgb[sl] * (1.0 - k[..., None]) + c * k[..., None]
        self.a[sl] = self.a[sl] + k * (1.0 - self.a[sl])
        if lit is not None: self.lit[sl] = self.lit[sl] * (1.0 - k) + ev(lit, False) * k
        else: self.lit[sl] = self.lit[sl] * (1.0 - k)

def hazed(col, d, extra=0.0):
    t = min(1.0, haze_of(d) + extra)
    return np.asarray(col, np.float32) * (1.0 - t) + HAZE * t

rng = np.random.default_rng(20)

def noise1(n, scale, seed):
    """smooth 1-D noise over n samples, wrapping, features about `scale` samples wide"""
    r = np.random.default_rng(seed); k = max(4, int(n / scale))
    v = r.standard_normal(k + 1); v[-1] = v[0]
    xs = np.linspace(0, k, n, endpoint=False); i = xs.astype(int); f = xs - i; f = f * f * (3 - 2 * f)
    return v[i] * (1 - f) + v[i + 1] * f

# ==================================================================================================================
# FAR LAYER
far = Layer(HF, F_TOP, F_BOT)
yy = np.arange(far.h)[:, None] + 0.5
el_rows = far.top - yy / far.h * (far.top - far.bot)
# the sea from the end of the game's sea (900 m) to the horizon: mostly haze, a little deep water (the look's sea at
# 900 m is about 78 % fog, see look.gd DAY fog_density), a touch darker toward the bottom
sea_col = HAZE * 0.80 + np.array([0.16, 0.27, 0.32]) * 0.20
under = (el_rows < 0.0).astype(np.float32) * np.ones((1, WS), np.float32)
grad = np.clip(-el_rows / 3.0, 0, 1)[..., None]
far.put(under, sea_col * (1.0 - 0.10 * grad), 1.0)
# the haze band above the horizon: from 75 % at the horizon to nothing at +3.5 deg (the card's top melts into the sky)
band = np.clip(1.0 - el_rows / 3.5, 0, 1) ** 2 * (el_rows >= 0.0)
far.put(band * np.ones((1, WS), np.float32), HAZE, 0.75)

# --- mountains: a silhouette per distance band, each the highest of its peaks' cones, roughened by noise ---------------
phis = np.arange(WS) / WS * 360.0
def ang(a, b): return (a - b + 180.0) % 360.0 - 180.0
peaks = []
for nm, la, lo, h, spread in LM["mountains"]["peaks"]:
    p, d = phi_d(la, lo); peaks.append((nm, p, d, h, spread))
bands = [(55000, 1e9, 0.0), (30000, 55000, 0.0), (0, 30000, 0.0)]
for bi, (d0, d1, _) in enumerate(bands):
    sel = [pk for pk in peaks if d0 <= pk[2] < d1]
    if not sel: continue
    prof = np.full(WS, -9.0); dist = np.full(WS, 1e9)
    for nm, p, d, h, spread in sel:
        e = elev(h, d)
        dd = np.abs(ang(phis, p))
        x = dd / (spread * 1.6)
        shape = (e + 0.12) / (1.0 + x * x) ** 1.2 - 0.12      # a summit with long shoulders: neighbours join into one range
        better = shape > prof
        prof = np.where(better, shape, prof); dist = np.where(better, d, dist)
    rough = noise1(WS, WS / 360 * 0.35, 11 + bi) * 0.06 + noise1(WS, WS / 360 * 0.08, 21 + bi) * 0.02
    rough = rough + noise1(WS, WS / 360 * 1.2, 31 + bi) * 0.10
    prof = prof + rough * np.clip(prof + 0.12, 0, None)
    ok = prof > -0.3
    ytop = far.y(prof)
    m = np.clip(yy - ytop[None, :], 0.0, 1.0) * (ok[None, :])
    m *= (el_rows > -0.05)              # down to the horizon only (the sea is in front)
    dmean = float(np.median(dist[ok])) if ok.any() else 40000.0
    base = np.array([0.46, 0.43, 0.35]) if bi < 2 else np.array([0.44, 0.42, 0.33])      # dry chaparral, olive-brown
    col = np.zeros((far.h, WS, 3), np.float32)
    # lit slope / shade by the profile's slope (sun from the south: faces toward the island lit), haze by distance
    sm = np.convolve(np.concatenate([prof[-64:], prof, prof[:64]]), np.ones(65) / 65, mode='same')[64:-64]      # broad slopes only (no stripes)
    slope = np.gradient(sm); shade = np.clip(0.92 + slope * 60.0, 0.80, 1.05)
    for c in range(3):
        col[..., c] = base[c] * shade[None, :]
    hz = np.array([haze_of(x) for x in dist[::64]]); hz = np.interp(np.arange(WS), np.arange(0, WS, 64), hz)
    hz = np.clip(hz + 0.05 * (2 - bi), 0, 0.97)
    # lower slopes hazier (more air in front near the ground) - a gentle vertical gradient
    vg = np.clip((yy - ytop[None, :]) / 10.0, 0, 1) * 0.08
    t = np.clip(hz[None, :] + vg, 0, 0.98)[..., None]
    col = col * (1 - t) + HAZE * t
    far.put(m, col, 1.0)

# --- the mesas and the towns on them, the islands ------------------------------------------------------------------
for nm, la, lo, h, ext, dens in sorted(LM["low_land"]["list"], key=lambda r: -phi_d(r[1], r[2])[1]):
    p, d = phi_d(la, lo)
    e_top = elev(h, d) + 0.02
    n = noise1(WS, WS / 360 * 0.5, zlib.crc32(nm.encode()) % 1000) * 0.05
    dd = np.abs(ang(phis, p))
    xx = np.clip((dd - ext * 0.35) / (ext * 0.35), 0, 1); w = 1.0 - xx * xx * (3 - 2 * xx)      # a mesa: flat top, soft shoulders
    top = np.where(w > 0, -0.1 + (e_top + 0.1) * w + n * w * e_top, -9)
    m = np.clip(yy - far.y(top)[None, :], 0, 1) * (w[None, :] > 0) * (el_rows > -0.05)
    colland = hazed([0.50, 0.47, 0.40], d)
    col = np.ones((far.h, WS, 3), np.float32) * colland
    # buildings: small light / dark speckles on the slope and lights at night
    r = np.random.default_rng(zlib.crc32(nm.encode()))
    speck = (r.random((far.h, WS)) < 0.35 * dens).astype(np.float32)
    tone = r.random((far.h, WS)).astype(np.float32)
    bcol = np.stack([0.80 + 0.15 * tone, 0.76 + 0.12 * tone, 0.68 + 0.12 * tone], -1)
    bcol = hazed([0, 0, 0], d) + (1 - haze_of(d)) * bcol
    col = col * (1 - speck[..., None] * 0.3) + bcol * (speck[..., None] * 0.3)
    lit = (r.random((far.h, WS)) < 0.22 * dens).astype(np.float32) * (0.55 + 0.45 * r.random((far.h, WS)))
    far.put(m, col, 1.0, lit=lit * m)
for nm, la, lo, h, ln in LM["islands"]["list"]:
    p, d = phi_d(la, lo)
    e = elev(h, d); wdeg = math.degrees(ln / d) * 0.7      # seen end-on from the north-east, a little narrower
    pts = [(p - wdeg / 2, -0.05), (p - wdeg * 0.3, e * 0.55), (p - wdeg * 0.05, e), (p + wdeg * 0.15, e * 0.85), (p + wdeg * 0.42, e * 0.4), (p + wdeg / 2, -0.05)]
    far.put(far.mask(pts), hazed([0.48, 0.44, 0.38], d, 0.05), 1.0)
# Las Torres de Agua Caliente (Tijuana's twin towers), tiny at 26 km
la, lo, g, h = LM["low_land"]["torres"]
p, d = phi_d(la, lo)
for dx in (-0.025, 0.025):
    far.put(far.mask([(p + dx - 0.04, elev(g, d)), (p + dx + 0.04, elev(g, d)), (p + dx + 0.04, elev(g + h, d)), (p + dx - 0.04, elev(g + h, d))]), hazed([0.75, 0.72, 0.66], d), 1.0, lit=0.6)

# ==================================================================================================================
# NEAR LAYER
near = Layer(HN, N_TOP, N_BOT)
nyy = np.arange(near.h)[:, None] + 0.5

def rect(L, p, wdeg, e0, e1, col, lit=None):
    L.put(L.mask([(p - wdeg / 2, e0), (p + wdeg / 2, e0), (p + wdeg / 2, e1), (p - wdeg / 2, e1)]), col, 1.0, lit)

PAL = {"stone": [0.74, 0.68, 0.58], "stone_pink": [0.70, 0.56, 0.50], "white": [0.84, 0.83, 0.80], "glass_light": [0.58, 0.64, 0.68],
       "glass_blue": [0.40, 0.50, 0.58], "glass_dark": [0.26, 0.30, 0.33], "glass_green": [0.38, 0.52, 0.50]}

def tower(L, la, lo, h, wid, top, mat, ground=2.0, seed=0):
    p, d = phi_d(la, lo)
    wdeg = math.degrees(wid / d)
    e0 = elev(ground - 4.0, d); e1 = elev(ground + h * (0.9 if top in ("pyramid", "spire", "arch", "crown") else 1.0), d)
    x0, x1 = L.x(p - wdeg / 2), L.x(p + wdeg / 2); y0, y1 = L.y(e1), L.y(e0)
    m = L.mask([(p - wdeg / 2, e0), (p + wdeg / 2, e0), (p + wdeg / 2, e1), (p - wdeg / 2, e1)])
    base = np.asarray(PAL[mat], np.float32)
    fl_px = (L.y(elev(ground + 3.8, d)) - L.y(elev(ground, d)))
    fl_n = max(1, int(h / 3.8))
    r = np.random.default_rng(seed)
    litcells = r.random(fl_n + 2) < 0.5
    hz = haze_of(d)
    def colf(rows, xs):
        # two faces: the left a little darker (the sun in the south lights the faces toward the island);
        # floors (3.8 m) as faint lines, window bands on glass a little darker
        face = np.where(xs < (x0 + x1) / 2 + (x1 - x0) * 0.12, 0.86, 1.0)
        band = ((rows - y0) / max(fl_px, 0.6)) % 1.0
        winrow = (band > 0.35).astype(np.float32)
        shade = face * (1.0 - 0.10 * winrow * (1.0 if "glass" in mat else 0.6))
        return HAZE * hz + (1 - hz) * base * shade[..., None]
    def litf(rows, xs):
        band = ((rows - y0) / max(fl_px, 0.6)) % 1.0
        winrow = (band > 0.35).astype(np.float32)
        flr = np.clip(((y1 - rows) / max(fl_px, 0.6)).astype(int), 0, fl_n + 1)
        rr = np.random.default_rng(seed + 1).random((rows.shape[0], xs.shape[1]))
        return litcells[flr] * winrow * (rr < 0.55) * (0.5 + 0.5 * rr / 0.55)
    L.put(m, colf, 1.0, lit=litf)
    # crowns
    c2 = hazed(base * 0.9, d)
    if top == "pyramid":
        L.put(L.mask([(p - wdeg / 2, e1), (p + wdeg / 2, e1), (p + wdeg * 0.05, elev(ground + h, d)), (p - wdeg * 0.05, elev(ground + h, d))]), c2, 1.0, lit=0.0)
    elif top == "spire":
        L.put(L.mask([(p - wdeg * 0.3, e1), (p + wdeg * 0.3, e1), (p, elev(ground + h, d))]), c2, 1.0, lit=0.0)
    elif top == "arch":
        n = 9; pts = [(p - wdeg / 2 + wdeg * i / (n - 1), e1 + (elev(ground + h, d) - e1) * math.sin(math.pi * i / (n - 1))) for i in range(n)]
        L.put(L.mask([(p - wdeg / 2, e1)] + pts + [(p + wdeg / 2, e1)]), c2, 1.0, lit=0.0)
    elif top == "crown":
        L.put(L.mask([(p - wdeg * 0.35, e1), (p + wdeg * 0.35, e1), (p + wdeg * 0.3, elev(ground + h, d)), (p - wdeg * 0.3, elev(ground + h, d))]), c2, 1.0, lit=0.0)
    elif top == "stepped":
        rect(L, p, wdeg * 0.6, e1, elev(ground + h * 1.0 + 0.0, d) + 0.0, c2, lit=0.0)
    # a red light on the tallest (aviation lights)
    if h > 120:
        rect(L, p, max(wdeg * 0.08, 0.03), elev(ground + h, d) - 0.02, elev(ground + h, d) + 0.02, c2, lit=1.0)

# Point Loma (6-7.5 km): the ridge from the crest down to the bay shore
cr = LM["point_loma"]["crest"]
pts = [phi_d(la, lo) + (h,) for la, lo, h in cr]
top = [(p, elev(h, d)) for p, d, h in pts]
bottom = [(p, -0.12) for p, d, h in reversed(pts)]
dpl = float(np.mean([d for p, d, h in pts]))
mpl = near.mask(top + bottom)
plcol = np.ones((near.h, WS, 3), np.float32) * hazed([0.48, 0.47, 0.37], dpl)
r = np.random.default_rng(3)
speck = (r.random((near.h, WS)) < 0.08).astype(np.float32)[..., None]
plcol = plcol * (1 - speck * 0.4) + hazed([0.80, 0.78, 0.72], dpl) * speck * 0.4
near.put(mpl, plcol, 1.0, lit=(r.random((near.h, WS)) < 0.02) * 0.6 * mpl)
la, lo, g, h = LM["point_loma"]["lighthouse"]
p, d = phi_d(la, lo)
rect(near, p, math.degrees(8 / d), elev(g, d), elev(g + h, d), hazed([0.88, 0.86, 0.80], d), lit=0.0)
rect(near, p, math.degrees(4 / d), elev(g + h, d), elev(g + h + 3, d), hazed([0.3, 0.3, 0.3], d), lit=0.9)

# the low far shore in front of the mesas: Harbor Island, the airport, Shelter Island, Barrio Logan (a low grey line)
for p0, p1, d, hgt in [(300, 335, 4800, 14), (335, 355, 4000, 18), (30, 60, 3600, 22), (95, 118, 5200, 16)]:
    e = elev(hgt, d)
    n = noise1(WS, WS / 360 * 0.15, p0) * 0.03
    xs = np.arange(int(near.x(p0)), int(near.x(p1)))
    pp = xs / WS * 360.0
    tops = [(float(a), e + float(n[int(b) % WS])) for a, b in zip(pp[::8], xs[::8])]
    near.put(near.mask(tops + [(p1, -0.12), (p0, -0.12)]), hazed([0.55, 0.55, 0.52], d), 1.0, lit=None)

# the shipyards and the Navy's ships (east shore of the bay)
for la, lo, ln, hh in LM["shipyards"]["ships"]:
    p, d = phi_d(la, lo); wdeg = math.degrees(ln / d) * 0.6
    rect(near, p, wdeg, -0.12, elev(12, d), hazed([0.45, 0.48, 0.50], d))
    rect(near, p + wdeg * 0.1, wdeg * 0.25, elev(12, d), elev(hh * 0.7, d), hazed([0.50, 0.53, 0.55], d), lit=0.3)
    rect(near, p + wdeg * 0.12, max(wdeg * 0.03, 0.02), elev(hh * 0.7, d), elev(hh, d), hazed([0.40, 0.42, 0.44], d))
for la, lo, hh in LM["shipyards"]["cranes"]:
    p, d = phi_d(la, lo); wdeg = math.degrees(40 / d)
    c = hazed([0.62, 0.30, 0.22] if hh > 60 else [0.70, 0.62, 0.30], d)
    for s in (-0.5, 0.5):      # two legs, the beam on top
        rect(near, p + s * wdeg * 0.8, max(wdeg * 0.05, 0.02), -0.1, elev(hh, d), c)
    rect(near, p, wdeg * 1.6, elev(hh - 6, d), elev(hh, d), c, lit=0.4)

# North Island beyond the map: hangars, the tower, a carrier at the piers
for la, lo, ln, hh in LM["north_island"]["hangars"]:
    p, d = phi_d(la, lo); rect(near, p, math.degrees(ln / d) * 0.8, -0.12, elev(hh, d), hazed([0.62, 0.61, 0.58], d), lit=0.15)
la, lo, hh = LM["north_island"]["tower"]; p, d = phi_d(la, lo)
rect(near, p, math.degrees(8 / d), -0.1, elev(hh, d), hazed([0.70, 0.69, 0.66], d)); rect(near, p, math.degrees(14 / d), elev(hh - 5, d), elev(hh, d), hazed([0.35, 0.40, 0.42], d), lit=0.7)
la, lo, ln, hh = LM["north_island"]["carrier"]; p, d = phi_d(la, lo); wdeg = math.degrees(ln / d) * 0.55
hull = hazed([0.44, 0.46, 0.48], d)
near.put(near.mask([(p - wdeg / 2, -0.12), (p + wdeg / 2, -0.12), (p + wdeg * 0.56, elev(20, d)), (p - wdeg * 0.58, elev(20, d))]), hull, 1.0, lit=None)
rect(near, p + wdeg * 0.18, wdeg * 0.07, elev(20, d), elev(45, d), hazed([0.50, 0.52, 0.54], d), lit=0.5)
rect(near, p + wdeg * 0.20, max(wdeg * 0.015, 0.02), elev(45, d), elev(hh, d), hazed([0.38, 0.40, 0.42], d))

# downtown: the real low / mid-rise mass first (scatter, README says so), then the 50 real towers far to near
fill = LM["downtown_fill"]; r = np.random.default_rng(fill["seed"])
mats = ["stone", "white", "glass_light", "glass_dark", "stone_pink", "white"]
items = []
for i in range(fill["count"]):
    la = r.uniform(*fill["lat"]); lo = r.uniform(*fill["lon"])
    items.append((la, lo, float(r.uniform(12, 80) * r.uniform(0.6, 1.0)), float(r.uniform(22, 50)), "flat", mats[int(r.integers(len(mats)))], int(r.integers(1 << 30))))
for nm, la, lo, h, wid, top_, mat in LM["towers"]:
    if nm.startswith("k: Coronado Shores"): continue      # 3D boxes (SOLIDS below)
    items.append((la, lo, h, wid, top_, mat, zlib.crc32(nm.encode()) % (1 << 30)))
items.sort(key=lambda it: -phi_d(it[0], it[1])[1])
for la, lo, h, wid, top_, mat, sd in items:
    tower(near, la, lo, h, wid, top_, mat, seed=sd)
# Petco Park's light towers (k), small
for la, lo in [(32.7083, -117.1580), (32.7065, -117.1565), (32.7068, -117.1590)]:
    p, d = phi_d(la, lo); rect(near, p, math.degrees(5 / d), -0.1, elev(60, d), hazed([0.45, 0.45, 0.45], d), lit=0.2)

# SOLIDS (3D, at their true places): the bridge and Coronado Shores are 0.2-3 km from parts of the island, too near
# for any card (seen from the east shore the bridge starts 200 m away). They are simple boxes in the city frame, drawn
# by the same shader at the far end of the depth range (so still never clipped, never culled, behind every object of
# the city) but with their real position seen from the real camera: exact from anywhere. Written to skyline.json.
def grid(lat, lon):
    w = world(lat, lon) - GO
    return float(w @ GB), float(w @ GA)

SUN = np.array([math.sin(math.radians(180 - ROT)), -math.cos(math.radians(180 - ROT))])      # toward the south, grid frame
solids = []
def quad(a, b, c, d, col, light=0.0, n=None):
    if n is not None:
        lam = 0.80 + 0.22 * float(np.dot(n, SUN)) if abs(n[1] if len(n) == 3 else 0) < 0.5 else 0.95
        col = [float(x) * lam for x in col]
    solids.append([[round(float(v), 2) for v in a], [round(float(v), 2) for v in b], [round(float(v), 2) for v in c], [round(float(v), 2) for v in d], [round(float(x), 3) for x in col] + [light]])

def box(cx, cz, ux, uz, half_l, half_w, y0, y1, col, light=0.0, top_col=None):
    """a box: centre, unit axis (ux, uz) along its length"""
    vx, vz = -uz, ux
    P = [(cx + ux * a * half_l + vx * b * half_w, cz + uz * a * half_l + vz * b * half_w) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    for k in range(4):
        (x0, z0), (x1, z1) = P[k], P[(k + 1) % 4]
        n = np.array([z1 - z0, -(x1 - x0)]); n = n / (np.linalg.norm(n) + 1e-9)
        quad((x0, y0, z0), (x1, y0, z1), (x1, y1, z1), (x0, y1, z0), col, light, n)
    quad((P[0][0], y1, P[0][1]), (P[1][0], y1, P[1][1]), (P[2][0], y1, P[2][1]), (P[3][0], y1, P[3][1]), top_col or [c * 0.92 for c in col], 0.0)

# the bridge: a smooth curve (Catmull-Rom) through the deck points, blue box girders, white rail with lights, piers
dk = [(grid(la, lo), h) for la, lo, h in LM["bridge"]["deck"]]
ctrl = [((x, z), h) for (x, z), h in dk]
ctrl = [ctrl[0]] + ctrl + [ctrl[-1]]
curve = []
for i in range(1, len(ctrl) - 2):
    for t in np.linspace(0, 1, 10, endpoint=False):
        def cr(k):
            p0, p1, p2, p3 = (np.array(list(ctrl[i + j][0]) + [ctrl[i + j][1]]) for j in (-1, 0, 1, 2))
            return 0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3)
        curve.append(cr(0))
curve.append(np.array(list(ctrl[-2][0]) + [ctrl[-2][1]]))
HW = 10.0      # half the deck's width (five lanes, k)
blue = [0.30, 0.45, 0.64]; rail = [0.80, 0.80, 0.77]; conc = [0.74, 0.73, 0.70]
along = 0.0; next_pier = 60.0
for a, b in zip(curve[:-1], curve[1:]):
    dx, dz = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dz); ux, uz = dx / L, dz / L; vx, vz = -uz, ux
    def side(sg, y0a, y1a, y0b, y1b, col, light=0.0):
        n = np.array([vx * sg, vz * sg])
        quad((a[0] + vx * HW * sg, y0a, a[1] + vz * HW * sg), (b[0] + vx * HW * sg, y0b, b[1] + vz * HW * sg), (b[0] + vx * HW * sg, y1b, b[1] + vz * HW * sg), (a[0] + vx * HW * sg, y1a, a[1] + vz * HW * sg), col, light, n)
    for sg in (-1, 1):
        side(sg, a[2] - 4.5, a[2], b[2] - 4.5, b[2], blue)
        side(sg, a[2], a[2] + 1.1, b[2], b[2] + 1.1, rail, 0.8)
    quad((a[0] - vx * HW, a[2] - 4.5, a[1] - vz * HW), (b[0] - vx * HW, b[2] - 4.5, b[1] - vz * HW), (b[0] + vx * HW, b[2] - 4.5, b[1] + vz * HW), (a[0] + vx * HW, a[2] - 4.5, a[1] + vz * HW), [c * 0.6 for c in blue])
    quad((a[0] - vx * HW, a[2] + 0.05, a[1] - vz * HW), (b[0] - vx * HW, b[2] + 0.05, b[1] - vz * HW), (b[0] + vx * HW, b[2] + 0.05, b[1] + vz * HW), (a[0] + vx * HW, a[2] + 0.05, a[1] + vz * HW), [0.32, 0.32, 0.33])
    along += L
    while along >= next_pier:
        t = 1.0 - (along - next_pier) / L; px, pz, ph = a[0] + dx * t, a[1] + dz * t, a[2] + (b[2] - a[2]) * t
        if ph > 11.0:      # a pier: a slab across the deck, narrower toward the top (the bridge's tapered piers), in the water
            box(px, pz, vx, vz, HW * 0.75, 2.6, -3.0, ph - 4.5, conc)
        next_pier += LM["bridge"]["pier_every_m"]
# Coronado Shores: ten towers along the beach (k), long side along the shore
sh = [t for t in LM["towers"] if t[0].startswith("k: Coronado Shores")]
g0 = grid(sh[0][1], sh[0][2]); g1 = grid(sh[-1][1], sh[-1][2])
ax = np.array([g1[0] - g0[0], g1[1] - g0[1]]); ax /= np.linalg.norm(ax)
for i, (nm, la, lo, h, wid, top_, mat) in enumerate(sh):
    x, z = grid(la, lo)
    box(x, z, ax[0], ax[1], 17.0, 10.0, 0.0, 3.0 + h, [0.86, 0.85, 0.82] if i % 3 else [0.80, 0.79, 0.74], 0.35, [0.62, 0.62, 0.60])
SOLIDS = solids

# ==================================================================================================================
# out: downsample (the paint is 2x), atlas, lights
def down(a):
    h, w = a.shape[:2]
    return a.reshape(h // SS, SS, w // SS, SS, *a.shape[2:]).mean(axis=(1, 3))

def finish(L):
    rgb = down(L.rgb); a = down(L.a); lit = down(L.lit)
    return rgb, np.clip(a, 0, 1), np.clip(lit, 0, 1)

nr, na, nl = finish(near)
fr, fa, fl = finish(far)
# keep the rows next to the atlas seam clear (mip maps): the near layer's last rows and the far layer's first rows
na[-6:] = 0.0; fa[:6] = 0.0
img = np.zeros((HN + HF, W, 4), np.float32)
img[:HN, :, :3] = nr; img[:HN, :, 3] = na
img[HN:, :, :3] = fr; img[HN:, :, 3] = fa
# transparent texels carry the haze colour (no dark fringes when filtered)
tr = img[..., 3] < 0.004
img[tr, :3] = HAZE
Image.fromarray(np.round(np.clip(img, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "skyline_day.png"), optimize=True)
lights = np.zeros((HN + HF, W), np.float32); lights[:HN] = nl * na; lights[HN:] = fl * fa
lights = lights.reshape((HN + HF) // 2, 2, W // 2, 2).max(axis=(1, 3))      # half size; the max keeps single lights
Image.fromarray(np.round(np.clip(lights, 0, 1) * 255).astype(np.uint8), "L").save(os.path.join(OUT, "skyline_lights.png"), optimize=True)
meta = {"note": "written by tools/city/look/make_skyline.py; read by tools/city/look/skyline.gd",
        "frame": "grid frame of the city kit: phi = azimuth from -Z clockwise (0 = -Z, 90 = +X); true bearing = phi + rot_deg",
        "rot_deg": ROT, "centre_grid": list(C_GRID), "centre_latlon": [LAT0 - C_W[1] / MLAT, LON0 + C_W[0] / MLON], "eye_m": EYE,
        "near_el": [N_TOP, N_BOT], "far_el": [F_TOP, F_BOT], "rows": [HN, HF], "size": [W, HN + HF], "ring": RING, "solids": SOLIDS}
json.dump(meta, open(os.path.join(OUT, "skyline.json"), "w"), separators=(",", ":"))
# a labelled strip for the README / review (4 quarters)
rv = os.path.join(ROOT, "map_dc/coronado/city_kit/review/skyline"); os.makedirs(rv, exist_ok=True)
prev = np.zeros((HN + HF, W, 3), np.float32)
sky = np.array([0.62, 0.69, 0.78])
for i in range(3): prev[..., i] = img[..., i] * img[..., 3] + sky[i] * (1 - img[..., 3])
Image.fromarray(np.round(np.clip(prev, 0, 1) * 255).astype(np.uint8)).save(os.path.join(rv, "atlas_preview.png"))
print("wrote", os.path.join(OUT, "skyline_day.png"), img.shape, "and skyline_lights.png", lights.shape)
for nm, la, lo in [("One America Plaza", 32.71583, -117.16861), ("Point Loma lighthouse", 32.6722, -117.2409), ("San Miguel", 32.69641, -116.9364), ("Cuyamaca", 32.94674, -116.60672), ("Otay", 32.59457, -116.84467), ("Islas Coronado Sur", 32.410, -117.248)]:
    p, d = phi_d(la, lo); print(f"  {nm:24s} bearing {(p + ROT) % 360:6.1f}  grid phi {p:6.1f}  {d / 1000:5.1f} km")
