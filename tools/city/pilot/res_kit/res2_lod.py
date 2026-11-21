#!/usr/bin/env python3
"""LOD match for the pilot ck_brk3_res2 WITHOUT repacking the shared page: its shell (sides, back, roof) is the same
geometry as ck_brk3_row2, so the mid reuses row2's baked triangles + UVs as they are; only the new front gets texels,
baked from the res2 near (front_bake.gd: orthographic, unshaded) and written into the page's EMPTY bottom strip
(rows 2015-2047 were fill grey; every other pixel unchanged). Two charts (front below / above y=6) so each fits.
Writes OUT/shops_apply/res/bake/{mid,far}.bin/.json for apply_res2_lod.gd."""
import json, numpy as np
from PIL import Image
R = '/workspace/NewMap/'; D = R + 'OUT/shops_apply/res/dump/'; B = R + 'OUT/shops_apply/res/bake/'
PAGE = R + 'assets/coronado_kit/textures/bld_lod_color.png'; PW = 2048; PAD = 3
DENS = 3.33319091796875; YS = 6.0; YT = 10.44; FILL = (128, 128, 128, 255)
def L(n):
    m = json.load(open(D + n + '.json')); raw = open(D + n + '.bin', 'rb').read(); s = m['surfaces'][0]; nv = s['nv']
    f = np.frombuffer(raw[:nv * 48], np.float32).reshape(nv, 12).copy(); I = np.frombuffer(raw[nv * 48:nv * 48 + s['ni'] * 4], np.int32).reshape(-1, 3).copy()
    return f, I
# ---- texels: bake (16 px/m, x -6..6, y 0..10.44) -> two charts at the page density
bake = Image.open(B + 'ck_brk3_res2.png').convert('RGB'); bw, bh = bake.size; ppm = bw / 12.0
arr = np.asarray(bake).astype(np.float32) / 255
glass = (arr.mean(-1) < 0.16).astype(np.float32)
GAIN = 0.978
def chart(y0, y1):
    r0 = int(round((YT - y1) * ppm)); r1 = int(round((YT - y0) * ppm))
    w = int(round(12 * DENS)); h = int(round((y1 - y0) * DENS))
    rgb = np.asarray(bake.crop((0, r0, bw, r1)).resize((w, h), Image.BOX)).astype(np.float32) / 255 * GAIN
    cov = np.asarray(Image.fromarray(glass[r0:r1]).resize((w, h), Image.BOX))
    a = np.clip(1 - 1.05 * cov, 0, 1)
    return np.dstack([rgb, a])
cA = chart(0, YS); cB = chart(YS, YT)
page = np.array(Image.open(PAGE)); before = page.copy()
strip = page[2015:]; assert (strip == FILL).all(), 'bottom strip is not empty any more'
ROW = 2015 + PAD
slots = {}
x = PAD
for nm, c in (('A', cA), ('B', cB)):
    h, w = c.shape[:2]; px = (np.clip(c, 0, 1) * 255 + 0.5).astype(np.uint8)
    padded = np.pad(px, ((PAD, PAD), (PAD, PAD), (0, 0)), mode='edge')
    page[ROW - PAD:ROW + h + PAD, x - PAD:x + w + PAD] = padded
    slots[nm] = (x, ROW, w, h); x += w + 2 * PAD + PAD
changed = np.any(page != before, -1); ys, xs = np.nonzero(changed)
assert ys.min() >= 2015, 'touched a pixel outside the empty strip'
Image.fromarray(page, 'RGBA').save(B + 'bld_lod_color_new.png')
print('charts', slots, 'pixels changed', int(changed.sum()), 'rows', ys.min(), ys.max(), 'cols', xs.min(), xs.max())
def uv(xx, yy):
    xx = np.asarray(xx, float); yy = np.asarray(yy, float)
    up = yy > YS + 1e-4
    out = np.zeros((len(xx), 2))
    for nm, sel, y0, y1 in (('A', ~up, 0, YS), ('B', up, YS, YT)):
        cx, cy, w, h = slots[nm]
        out[sel, 0] = (cx + (np.clip(xx[sel], -6, 6) + 6) / 12 * w) / PW
        out[sel, 1] = (cy + (y1 - np.clip(yy[sel], y0, y1)) / (y1 - y0) * h) / PW
    return out
def split_y(f, I, ys):
    """cut every triangle that crosses y = ys (so each lies in one chart)"""
    V = [r for r in f]; out = []
    def lerp(a, b):
        t = (ys - V[a][1]) / (V[b][1] - V[a][1]); v = V[a] + (V[b] - V[a]) * t; v[1] = ys; V.append(v); return len(V) - 1
    for t in I:
        s = [V[k][1] - ys for k in t]
        if all(d >= -1e-5 for d in s) or all(d <= 1e-5 for d in s): out.append(list(t)); continue
        # rotate so the lone vertex is first
        for r in range(3):
            a, b, c = t[r], t[(r + 1) % 3], t[(r + 2) % 3]; sa, sb, sc = s[r], s[(r + 1) % 3], s[(r + 2) % 3]
            if (sa > 0) != (sb > 0) and (sa > 0) != (sc > 0): break
        ab = lerp(a, b); ac = lerp(a, c)
        out += [[a, ab, ac], [ab, b, c], [ab, c, ac]]
    return np.array(V, np.float32), np.array(out, np.int32)
# ---- mid: row2's baked shell (tris 250..) + res2's own front relief (its first 332 tris) on the new charts
fr, Ir = L('ck_brk3_row2_mid'); fs, Is = L('ck_brk3_res2_mid')
shell_I = Ir[250:]; front_I = Is[:332]
fF, iF = split_y(fs, front_I, YS)
used = np.unique(iF); remap = -np.ones(len(fF), int); remap[used] = np.arange(len(used)); fF = fF[used]; iF = remap[iF]
# a vertex on y=6 shared by tris above and below needs one copy per chart
fF2 = []; iF2 = []
for t in iF:
    up = fF[t, 1].mean() > YS
    base = len(fF2)
    for k in t:
        v = fF[k].copy(); fF2.append((v, up)); 
    iF2.append([base, base + 1, base + 2])
P = np.array([v for v, _ in fF2]); UPS = np.array([u for _, u in fF2])
UV = np.zeros((len(P), 2))
for nm, sel, y0, y1 in (('A', ~UPS, 0, YS), ('B', UPS, YS, YT)):
    cx, cy, w, h = slots[nm]
    UV[sel, 0] = (cx + (np.clip(P[sel, 0], -6, 6) + 6) / 12 * w) / PW
    UV[sel, 1] = (cy + (y1 - np.clip(P[sel, 1], y0, y1)) / (y1 - y0) * h) / PW
P[:, 6:8] = UV; P[:, 8:12] = 1.0
used = np.unique(shell_I); rm = -np.ones(len(fr), int); rm[used] = np.arange(len(used))
mid_f = np.concatenate([fr[used], P]).astype(np.float32); mid_I = np.concatenate([rm[shell_I], np.array(iF2) + len(used)]).astype(np.int32)
# ---- far: row2's far hull; its front bands remapped onto the charts
ff, If = L('ck_brk3_row2_far'); ff = ff.copy(); newf = []; newI = []
for t in If:
    vs = ff[t].copy()
    if vs[0, 5] > 0.9 and abs(vs[:, 2] - 7.0).max() < 1e-3:
        up = vs[:, 1].mean() > YS
        cx, cy, w, h = slots['B' if up else 'A']; y0, y1 = (YS, YT) if up else (0, YS)
        vs[:, 6] = (cx + (vs[:, 0] + 6) / 12 * w) / PW
        vs[:, 7] = (cy + (y1 - np.clip(vs[:, 1], y0, y1)) / (y1 - y0) * h) / PW
    newI.append([len(newf), len(newf) + 1, len(newf) + 2]); newf += list(vs)
far_f = np.array(newf, np.float32); far_I = np.array(newI, np.int32)
for nm, f, I in (('mid', mid_f, mid_I), ('far', far_f, far_I)):
    open(B + nm + '.bin', 'wb').write(f.tobytes() + I.astype(np.int32).tobytes())
    json.dump({'nv': len(f), 'ni': int(I.size)}, open(B + nm + '.json', 'w')); print(nm, 'tris', len(I))
