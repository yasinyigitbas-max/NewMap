"""Compose the shared kiosk texture page: colour (sRGB), normal (baked HP + photo detail), ORM (R = AO, G = rough, B = metal).
Work 2048 -> ship colour 1024, normal 512, ORM 512. Photo layers are ambientCG CC0 1K maps sampled in real-world metres per island."""
import os, sys, json, math, glob
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kgeo, pack, kcommon, ksigns
ROOT = kcommon.ROOT; CC0 = ROOT + '/cc0'; N = pack.ATLAS
L = json.load(open(ROOT+'/work/layout.json')); RECTS = L['rects']; ISL = L['islands']
SHIP = dict(color=int(os.environ.get('SHIP_COLOR', 1024)), normal=int(os.environ.get('SHIP_NORMAL', 512)), orm=int(os.environ.get('SHIP_ORM', 512)))

def srgb2lin(c): c = np.asarray(c, float); return np.where(c <= 0.04045, c/12.92, ((c+0.055)/1.055)**2.4)
def lin2srgb(c): c = np.clip(c, 0, 1); return np.where(c <= 0.0031308, c*12.92, 1.055*c**(1/2.4)-0.055)
NAMED = {'red': '#b4171c', 'yellow': '#e7b812', 'green': '#3f8a2c', 'white': '#efefe8', 'orange': '#e0701a', 'blue': '#2a62b8', 'pink': '#e86a9a'}
def hexc(h): h = NAMED.get(h, h).lstrip('#'); return np.array([int(h[i:i+2], 16)/255 for i in (0, 2, 4)])
def lin(h): return srgb2lin(hexc(h))
_cache = {}
GRAY = ('Scratches005', 'Fingerprints002', 'SurfaceImperfections003', 'Smear008')
def tex(name, kind='Color'):
    k = (name, kind)
    if k not in _cache:
        f = glob.glob(f'{CC0}/{name}/*_{kind}.jpg')
        im = Image.open(f[0]); gray = name in GRAY and kind == 'Color'
        im = im.convert('RGB') if kind in ('Color', 'NormalGL') and not gray else im.convert('L')
        _cache[k] = np.asarray(im).astype(np.float32)/255.0
    return _cache[k]
def samp(img, a, b, size_m, off=(0.0, 0.0), rot=0.0):
    H, W = img.shape[:2]
    if rot:
        c, s = math.cos(rot), math.sin(rot); a, b = a*c - b*s, a*s + b*c
    x = (a/size_m + off[0])*W; y = (b/size_m + off[1])*H
    if img.ndim == 2: return ndi.map_coordinates(img, [y, x], order=1, mode='grid-wrap')
    return np.stack([ndi.map_coordinates(img[..., c], [y, x], order=1, mode='grid-wrap') for c in range(img.shape[2])], -1)
def tex_grad(name, a, b, size_m, strength=1.0, off=(0, 0), rot=0.0):
    n = samp(tex(name, 'NormalGL'), a, b, size_m, off, rot)*2-1
    nz = np.maximum(n[..., 2], 0.2)
    ga = -n[..., 0]/nz*strength; gb = n[..., 1]/nz*strength
    if rot:
        c, s = math.cos(rot), math.sin(rot); ga, gb = ga*c + gb*s, -ga*s + gb*c
    return ga, gb
_ng = {}
def noise(a, b, scale, seed=0, octaves=3):
    out = 0; amp = 1; tot = 0
    for o in range(octaves):
        key = (seed, o)
        if key not in _ng:
            g = np.random.default_rng(seed*31+o).random((64, 64)).astype(np.float32)
            g = ndi.gaussian_filter(g, 1.0, mode='wrap'); _ng[key] = (g-g.min())/(g.max()-g.min()+1e-6)
        out = out + amp*ndi.map_coordinates(_ng[key], [b/scale*8 % 64, a/scale*8 % 64], order=1, mode='grid-wrap')
        tot += amp; amp *= 0.5; scale *= 0.5
    return out/tot
def grad_h(h, da, db):
    gb, ga = np.gradient(h, db, da); return ga, gb
def sstep(e0, e1, x): t = np.clip((x-e0)/(e1-e0), 0, 1); return t*t*(3-2*t)

# ---------------------------------------------------------------- world raster of canonical (owner) near faces
def raster_world():
    own = kcommon.owners()
    pos = np.zeros((N, N, 3), np.float32); nrmw = np.zeros((N, N, 3), np.float32); cov = np.zeros((N, N), bool)
    for mod in kcommon.mods():
        m = kcommon.build(mod, 'near')
        V = np.asarray(m.V); F = np.asarray(m.F); vn = np.zeros_like(V)
        fnrm = np.cross(V[F[:, 1]]-V[F[:, 0]], V[F[:, 2]]-V[F[:, 0]])
        for k in range(3): np.add.at(vn, F[:, k], fnrm)
        vn = vn/np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-12)
        UV = kcommon.uv_array(m, L); PX = np.stack([UV[:, 0]*N, (1-UV[:, 1])*N], 1)
        for fi, f in enumerate(m.F):
            if not m.FB[fi]: continue
            k = m.ISL[f[0]]
            if k not in RECTS or own.get(k) != m.kid: continue
            p = PX[f]; x0, y0 = np.floor(p.min(0)).astype(int); x1, y1 = np.ceil(p.max(0)).astype(int)
            x0 = max(x0, 0); y0 = max(y0, 0); x1 = min(x1, N-1); y1 = min(y1, N-1)
            if x1 < x0 or y1 < y0: continue
            yy, xx = np.mgrid[y0:y1+1, x0:x1+1]; q = np.stack([xx+0.5, yy+0.5], -1)
            v0 = p[1]-p[0]; v1 = p[2]-p[0]; d = v0[0]*v1[1]-v0[1]*v1[0]
            if abs(d) < 1e-12: continue
            w = q - p[0]
            l1 = (w[..., 0]*v1[1]-w[..., 1]*v1[0])/d; l2 = (v0[0]*w[..., 1]-v0[1]*w[..., 0])/d; l0 = 1-l1-l2
            ins = (l0 >= -0.02) & (l1 >= -0.02) & (l2 >= -0.02)
            if not ins.any(): continue
            P3 = l0[..., None]*V[f[0]] + l1[..., None]*V[f[1]] + l2[..., None]*V[f[2]]
            N3 = l0[..., None]*vn[f[0]] + l1[..., None]*vn[f[1]] + l2[..., None]*vn[f[2]]
            ys, xs = yy[ins], xx[ins]
            pos[ys, xs] = P3[ins]; nrmw[ys, xs] = N3[ins]; cov[ys, xs] = True
    idx = ndi.distance_transform_edt(~cov, return_distances=False, return_indices=True)
    return pos[idx[0], idx[1]], nrmw[idx[0], idx[1]], cov

class Ctx: pass

# ---------------------------------------------------------------- base materials -> (col_lin, rough, metal, ga, gb)
def z(c): return np.zeros_like(c.a)
def wear_layers(c, s=0.3):
    imp = samp(tex('SurfaceImperfections003'), c.a, c.b, s*1.6)
    scr = samp(tex('Scratches005'), c.a, c.b, s)
    return imp, scr

def m_steel(c, I):
    a, b = c.a, c.b
    rot = 0.0 if I.get('grain', 'a') == 'a' else math.pi/2
    br = samp(tex('Metal009'), a, b, 0.6, rot=rot).mean(-1)
    br2 = samp(tex('Metal011'), a, b, 1.1).mean(-1)
    imp, scr = wear_layers(c, 0.35)
    fp = samp(tex('Fingerprints002'), a, b, 0.22)
    sm = samp(tex('Smear008'), a, b, 0.8).mean(-1) if tex('Smear008').ndim == 3 else samp(tex('Smear008'), a, b, 0.8)
    col = lin('#c4c7cb')*(0.78 + 0.28*(br-br.mean()) + 0.10*(br2-br2.mean()) - 0.08*imp)[..., None]
    rough = 0.26 + 0.14*(1-br) + 0.18*scr + 0.12*fp + 0.12*imp
    ga, gb = tex_grad('Metal009', a, b, 0.6, 0.03, rot=rot)
    sga, sgb = tex_grad('Scratches005', a, b, 0.35, 0.05)
    # tea-stain (light rust) in occluded corners: real 304 stainless at the beach does this
    rust = samp(tex('Rust004'), a, b, 0.4); rl = rust.mean(-1)
    occl = np.clip((0.7 - c.ao)/0.5, 0, 1)
    bloom = np.clip((rl-0.45)*3, 0, 1)*occl*0.55
    col = col*(1-bloom[..., None]) + rust*0.55*bloom[..., None]
    rough = rough*(1-bloom) + 0.7*bloom
    return col, rough, 1.0 - 0.8*bloom, ga+sga, gb+sgb

def m_chrome(c, I):
    a, b = c.a, c.b
    imp, scr = wear_layers(c, 0.25)
    fp = samp(tex('Fingerprints002'), a, b, 0.2)
    m49 = samp(tex('Metal049A'), a, b, 0.3).mean(-1)
    col = lin('#dcdde0')*(0.9 + 0.1*m49)[..., None]
    rough = 0.08 + 0.2*scr + 0.1*fp
    ga, gb = tex_grad('Scratches005', a, b, 0.25, 0.04)
    return col, rough, np.ones_like(a), ga, gb

def m_brass(c, I):
    col, rough, metal, ga, gb = m_chrome(c, I)
    pat = noise(c.a, c.b, 0.05, seed=4)
    return lin('#b58a3c')*(0.8+0.3*pat)[..., None], rough+0.15, metal, ga, gb

def m_black(c, I):
    a, b = c.a, c.b
    imp, scr = wear_layers(c, 0.25)
    col = lin('#1b1c1e')*(1+0.5*imp+0.9*scr)[..., None]
    # powder coat chips showing grey primer / steel
    chips = np.clip((noise(a, b, 0.05, seed=12)-0.72)*8, 0, 1)*np.clip((0.75-c.ao)*2+0.4, 0, 1)
    col = col*(1-chips[..., None]) + lin('#7c7f83')*chips[..., None]
    rough = 0.5 + 0.2*imp + 0.2*scr - 0.15*chips
    ga, gb = tex_grad('PaintedMetal004', a, b, 0.4, 0.03)
    return col, rough, 0.8*chips, ga, gb

def m_paint(c, I):
    a, b = c.a, c.b
    base = lin(I.get('col') or '#d0d0d0')
    lum = samp(tex('PaintedMetal004'), a, b, 0.45).mean(-1)
    imp, scr = wear_layers(c, 0.3)
    col = base*(0.96 + 0.05*(lum-lum.mean()) - 0.06*imp + 0.12*scr)[..., None]
    chips = np.clip((noise(a, b, 0.06, seed=13)-0.74)*7, 0, 1)
    col = col*(1-chips[..., None]) + lin('#6e6a64')*chips[..., None]
    rough = 0.38 + 0.15*imp + 0.25*scr + 0.2*chips
    ga, gb = tex_grad('PaintedMetal004', a, b, 0.45, 0.03)
    metal = 0.6*chips
    if I.get('kind') == 'box':   # paletero cart: teal + pink pin-stripe bands near the base and below the lid
        y = c.pos[..., 1]
        bt = sstep(0.462, 0.465, y)*(1-sstep(0.488, 0.491, y)); bp = sstep(0.498, 0.501, y)*(1-sstep(0.507, 0.510, y))
        tt = sstep(0.915, 0.918, y)*(1-sstep(0.928, 0.931, y))
        col = col*(1-bt[..., None]) + lin('#16a3a0')*bt[..., None]
        col = col*(1-(bp+tt)[..., None]) + lin('#e8487a')*(bp+tt)[..., None]
    if I.get('kind') == 'rim':   # pressed-steel wheel disc: bright rim lip, groove ring, 5 cooling holes, plated hub + lug nuts
        rr = I['w']/TAU; r_ = np.clip(rr - b, 0, None); th = a/max(rr, 1e-3)
        lip = 1 - sstep(0.012, 0.016, b)
        col = col*(1-lip[..., None]) + lin('#a6aaaf')*lip[..., None]; metal = np.maximum(metal, lip); rough = rough*(1-lip) + 0.3*lip
        groove = np.exp(-((b-0.034)/0.0025)**2)
        col = col*(1-0.5*groove[..., None]); g1, g2 = grad_h(-0.0015*groove, c.da, c.db); ga = ga+g1; gb = gb+g2
        rc = rr*0.6; per = TAU/5; dth = (th % per) - per/2
        dist = np.sqrt((r_-rc)**2 + (r_*dth)**2); hole = 1 - sstep(rr*0.15, rr*0.18, dist)
        col = col*(1-hole[..., None]) + lin('#0b0b0c')*hole[..., None]; metal = metal*(1-hole); rough = rough*(1-hole) + 0.9*hole
        ring = 1 - sstep(rr*0.18, rr*0.22, dist); g1, g2 = grad_h(0.001*ring*(1-hole), c.da, c.db); ga = ga+g1; gb = gb+g2
        hub = sstep(rr*0.68, rr*0.72, b)
        col = col*(1-hub[..., None]) + lin('#c9ccd0')*(0.9+0.1*imp)[..., None]*hub[..., None]; metal = np.maximum(metal, hub); rough = rough*(1-hub) + 0.22*hub
        lug = np.exp(-(((r_-rr*0.3)**2 + (r_*((th % per)-per/2))**2)/(0.008**2)))
        col = col*(1-0.6*lug[..., None])
    return col, rough, metal, ga, gb

def m_plastic(c, I):
    a, b = c.a, c.b
    base = lin(I.get('col') or '#e0e0e0')
    pl = samp(tex('Plastic010'), a, b, 0.4).mean(-1)
    imp, scr = wear_layers(c, 0.2)
    col = base*(0.95 + 0.15*(pl-pl.mean()) - 0.05*imp)[..., None]
    rough = 0.32 + 0.15*imp + 0.15*scr
    ga, gb = tex_grad('Plastic010', a, b, 0.4, 0.03)
    kind = I.get('kind')
    if kind == 'bottle':   # solid coloured squeeze bottle, lighter printed label panel, translucent sheen
        base_c = {'red': '#b4171c', 'yellow': '#e7b812', 'green': '#3f8a2c', 'white': '#efefe8', 'orange': '#e0701a'}.get(I.get('col'), None)
        bc = lin(base_c) if base_c else base
        col = bc*(0.92+0.15*pl[..., None]) * np.ones_like(col)
        lab = sstep(0.05, 0.054, b)*(1 - sstep(0.125, 0.129, b))
        col = col*(1-lab[..., None]) + (bc*0.8 + lin('#f6f1e6')*0.2)*lab[..., None]
        word = lab*sstep(0.078, 0.082, b)*(1-sstep(0.098, 0.102, b))
        col = col*(1-word[..., None]) + bc*0.75*word[..., None]
        nozzle = sstep(0.19, 0.195, b)
        col = col*(1-nozzle[..., None]) + bc*0.8*nozzle[..., None]
        rough = np.where(lab > 0.5, 0.45 + 0.1*imp, 0.18 + 0.1*imp)
    if kind == 'cooler':
        # moulded ribs + faded sun-bleached top edge
        rib = 0.5+0.5*np.cos(b/0.05*TAU) if False else 0
        col = col*(0.92 + 0.08*noise(a, b, 0.3, seed=5))[..., None]
    if kind in ('surfboard', 'surfboard_b'):
        # glassed foam board: cream deck, teal rail band, two stringers, wax on the deck
        Wb = I['w']; ctr = np.abs(a - Wb/2)
        band = sstep(0.0, 0.01, ctr - (Wb/2 - 0.07))
        col = col*(1-band[..., None]) + lin('#2aa5a0')*band[..., None]
        stringer = np.abs(ctr) < 0.003
        col = np.where(stringer[..., None], lin('#8a6a44'), col)
        if kind == 'surfboard':
            wax = np.clip((noise(a, b, 0.05, seed=51)-0.45)*2, 0, 1)*sstep(0.6, 1.4, b)*(1-sstep(1.6, 1.9, b))
            col = col*(1-0.25*wax[..., None]) + lin('#f7f3e8')*0.25*wax[..., None]; rough = rough*(1-wax) + 0.75*wax
            stripe = np.abs(b - 1.25) < 0.04
            col = np.where(stripe[..., None], lin('#e45b74'), col)
        rough = rough*0.7
    if kind == 'cups':
        rim = (np.cos((b-0.098)/0.012*2*math.pi) > 0.92) & (b > 0.095)
        col = np.where(rim[..., None], col*0.85, col)
    return col, rough, z(c), ga, gb
TAU = 2*math.pi

def m_rubber(c, I):
    a, b = c.a, c.b
    r = samp(tex('Rubber004'), a, b, 0.18).mean(-1)
    col = lin('#141414')*(0.85 + 0.35*(r-0.5))[..., None]
    rough = 0.82 + 0.1*(r-0.5)
    ga, gb = tex_grad('Rubber004', a, b, 0.18, 0.2)
    if I.get('kind') == 'tyre':
        h = 0.5*sstep(0.4, 0.5, np.abs(np.sin(a/0.025*math.pi)))
        Lh = I['h']
        cen = np.abs(b - Lh*0.5/1.2) < Lh*0.18
        h = np.where(cen, h, 0.0)
        g1, g2 = grad_h(-0.0012*h, c.da, c.db); ga = ga + g1; gb = gb + g2
        col = col*(1 - 0.25*h)[..., None]
    if I.get('kind') == 'grip':
        h = 0.5+0.5*np.sin(b/0.006*TAU)
        g1, g2 = grad_h(0.0004*h, c.da, c.db); ga = ga+g1; gb = gb+g2
    return col, rough, z(c), ga, gb

def m_fabric(c, I):
    """canvas / vinyl awning: weave (Fabric026 luminance) + stripes/panels by island-local a + wrinkles + sun fade."""
    a, b = c.a, c.b
    w = samp(tex('Fabric026'), a, b, 0.25).mean(-1); w = (w-w.mean())/max(w.std(), 1e-3)
    cols = I.get('colours') or ('#f0f0f0', '#c03030')
    kind = I.get('kind')
    cA, cB = lin(cols[0]), lin(cols[1])
    if kind in ('umbrella', 'umbrella_under', 'valance'):
        # alternate colour per panel; sector = 2 panels, a in [0, 2*pa*R]
        wsec = I['w']
        t = (a % wsec)/wsec
        selB = sstep(0.497, 0.503, t) * (1 - sstep(0.997, 1.0, t)) if True else 0
        selB = (t >= 0.5).astype(float)
        col = cA*(1-selB[..., None]) + cB*selB[..., None]
        seam = np.clip(1 - np.minimum(np.abs(t-0.5), np.minimum(t, 1-t))*wsec/0.004, 0, 1)
    elif kind == 'sarape':
        pal = [lin(h) for h in ('#d8342a', '#f2b22c', '#2a8a5c', '#f4ead2', '#2b4c9a', '#e2672a', '#111111', '#f4ead2', '#c22a6a', '#f2b22c')]
        widths = [0.06, 0.02, 0.035, 0.008, 0.05, 0.015, 0.006, 0.008, 0.04, 0.02]
        per = sum(widths); edges = np.cumsum(widths)
        t = (c.b % per) if I.get('stripe_axis', 'b') == 'b' else (c.a % per)
        idx = np.searchsorted(edges, t)
        col = np.stack(pal)[np.clip(idx, 0, len(pal)-1)]
        seam = z(c)
        # woven speckle typical of sarape cloth
        col = col*(0.85 + 0.3*samp(tex('Fabric071'), a, b, 0.12).mean(-1)[..., None]*0.5)
    elif kind in ('stripes', 'awning', 'stripes_under', 'stripes_val'):
        sw = I.get('stripe_w', 0.12); ax_ = c.a if I.get('stripe_axis', 'a') == 'a' else c.b
        t = (ax_ % (2*sw))/(2*sw)
        selB = sstep(0.49, 0.51, t)*(1-sstep(0.99, 1.0, t)) + (1-sstep(0.0, 0.01, t))*0
        selB = (t >= 0.5).astype(float)
        col = cA*(1-selB[..., None]) + cB*selB[..., None]
        seam = np.clip(1 - np.minimum(np.abs(t-0.5), np.minimum(t, 1-t))*2*sw/0.003, 0, 1)
    elif kind == 'roofpanel':   # pop-up canopy roof panel: hip seams with binding tape, eave hem, tension folds from the corners
        RHp, slp = I['rh'], I['sl']; f = np.clip(b/slp, 0, 1)
        e = np.minimum(a - (0.01 + RHp*f), (2*RHp + 0.01 - RHp*f) - a)*math.hypot(1, RHp/slp)**-1
        col = cA*np.ones(a.shape+(1,))
        bind = 1 - sstep(0.018, 0.024, e)
        hem = 1 - sstep(0.028, 0.034, b)
        col = col*(1-0.35*np.maximum(bind, hem)[..., None])
        stitch = ((np.abs(e-0.03) < 0.0018) | (np.abs(b-0.04) < 0.0018)) & (np.sin((a+b)/0.007*TAU) > 0)
        col = np.where(stitch[..., None], col*0.7, col)
        seam = z(c)
        I['_folds'] = (e, f)
    else:
        col = cA*np.ones(a.shape+(1,)); seam = z(c)
    fade = noise(a, b, 0.5, seed=8)
    col = col*(0.93 + 0.07*w[..., None]*0.6) * (0.96 + 0.08*fade[..., None])
    col = col*(1 - 0.18*seam[..., None])
    if kind in ('umbrella_under', 'umbrella_under1', 'stripes_under'):
        col = col*0.78   # translucent canvas seen from below: darker, slightly warmer
        col = col*np.array([1.0, 0.97, 0.92])
    if kind in ('valance', 'stripes_val'):   # hem stitches top + bottom
        hem = (np.abs(b-0.012) < 0.0015) | (np.abs(b-(I['h']-0.035)) < 0.0015)
        dash = (np.sin(a/0.006*TAU) > 0)
        col = np.where((hem & dash)[..., None], col*0.8, col)
    # wrinkles / stretch folds
    wr = noise(a*0.6, b*2.0, 0.35, seed=9, octaves=2)
    ga, gb = tex_grad('Fabric026', a, b, 0.25, 0.25)
    g1, g2 = grad_h(0.004*wr, c.da, c.db)
    if kind == 'roofpanel':   # stronger diagonal tension folds radiating from the eave corners + hip-seam ridges
        e, f = I.pop('_folds')
        nf = noise(a*0.45, b*1.6, 0.18, seed=31, octaves=3) - 0.5          # irregular sags across the slope
        corner = np.exp(-e/0.25)*(1-f)                                        # tension folds near the hips, along the slope
        fold = (noise(a*2.5, b*0.6, 0.12, seed=32, octaves=2) - 0.5)*corner
        fold2 = nf
        h = 0.010*fold + 0.006*nf + 0.0025*(1 - sstep(0.0, 0.024, e))
        g1, g2 = grad_h(h, c.da, c.db)
        col = col*(1 + 0.25*(fold+fold2))[..., None]
    rough = 0.82 + 0.08*w*0.2
    if kind == 'roofpanel': rough = 0.95 + 0.03*w*0.2   # dull polyester canopy: kills most of the grazing sky sheen
    if I.get('vinyl'): rough = rough*0.7
    return col, rough, z(c), ga*0.6+g1, gb*0.6+g2

def m_wood(c, I):
    a, b = c.a, c.b
    rot = 0.0 if I.get('grain', 'a') == 'a' else math.pi/2
    wc = samp(tex('Wood049'), a, b, 1.2, rot=rot)
    base = lin(I.get('col') or '#b58a5a')
    lum = srgb2lin(wc).mean(-1); lum = lum/max(lum.mean(), 1e-3)
    col = base*(lum**1.1)[..., None]*0.95
    rough = 0.7 + 0.1*(1-lum)
    ga, gb = tex_grad('Wood049', a, b, 1.2, 0.3, rot=rot)
    if I.get('slats'):   # crate: three horizontal slats with dark gaps between
        t = (b % (I['h']/3))/(I['h']/3)
        gap = 1 - sstep(0.0, 0.08, t)*(1 - sstep(0.85, 0.93, t))
        col = col*(1 - 0.85*gap[..., None]); g1, g2 = grad_h(-0.006*gap, c.da, c.db); ga = ga + g1; gb = gb + g2
        stamp = (np.abs(b - I['h']*0.5) < 0.012) & (np.abs((a % 0.5) - 0.2) < 0.08)
        col = np.where(stamp[..., None], col*0.55, col)
    return col, rough, z(c), ga, gb

def m_wpaint(c, I):
    """painted wood (shiplap, trim, plywood): brush grain + chipped paint revealing weathered wood."""
    a, b = c.a, c.b
    rot = 0.0 if I.get('grain', 'a') == 'a' else math.pi/2
    base = lin(I.get('col') or '#7fc8c0')
    pw = samp(tex('PaintedWood007A'), a, b, 1.0, rot=rot).mean(-1); pw = (pw-pw.mean())/max(pw.std(), 1e-3)
    wg = samp(tex('WoodSiding008'), a, b, 1.4, rot=rot).mean(-1); wg = (wg-wg.mean())/max(wg.std(), 1e-3)
    imp, scr = wear_layers(c, 0.4)
    col = base*(0.95 + 0.04*pw + 0.03*wg - 0.05*imp)[..., None]
    chips = np.clip((noise(a, b, 0.08, seed=17) - 0.70 + 0.25*np.clip(0.6-c.ao, 0, 1))*6, 0, 1)*I.get('chips', 1.0)
    wood = samp(tex('Wood049'), a, b, 1.2, rot=rot)
    col = col*(1-chips[..., None]) + srgb2lin(wood)*0.75*chips[..., None]
    rough = 0.62 + 0.1*imp + 0.15*chips
    ga, gb = tex_grad('PaintedWood007A', a, b, 1.0, 0.25, rot=rot)
    # shiplap / board grooves along a (horizontal boards) when requested
    if I.get('boards'):
        bw = I['boards']; cc = c.pos[..., 1] if I.get('boards_world_y') else (a if I.get('boards_axis') == 'a' else b)
        t = (cc % bw)/bw
        groove = 1 - sstep(0.0, 0.06, t)*(1 - sstep(0.94, 1.0, t))
        g1, g2 = grad_h(-0.003*groove, c.da, c.db)
        if I.get('boards_world_y'): g1, g2 = 0*g1, 0*g2
        col = col*(1 - 0.35*groove[..., None])
        ga = ga + g1; gb = gb + g2
    return col, rough, z(c), ga, gb

def m_galv(c, I):
    a, b = c.a, c.b
    cs = samp(tex('CorrugatedSteel005'), a, b, 1.0)
    col = srgb2lin(cs)*0.9
    imp, scr = wear_layers(c, 0.5)
    rough = 0.45 + 0.2*imp
    ga, gb = tex_grad('CorrugatedSteel005', a, b, 1.0, 0.8)
    return col, rough, 0.7*np.ones_like(a), ga, gb

def m_glassy(c, I):
    a, b = c.a, c.b
    base = lin(I.get('col') or '#f0d040')
    imp = samp(tex('SurfaceImperfections003'), a, b, 0.3)
    col = base*(0.9 + 0.1*imp)[..., None]
    # liquid level band + highlight streak
    kind = I.get('kind')
    if kind == 'jar':
        lvl = I.get('level', 0.75)*I['h']
        above = sstep(lvl-0.004, lvl+0.004, b)
        col = col*(1-above[..., None]) + lin('#dfe6e4')*0.7*above[..., None]
        hl = np.exp(-((a % (I['w']/2)) - I['w']*0.08)**2/(2*0.006**2))
        col = col + 0.25*hl[..., None]
        rough = 0.05 + 0.05*imp
    else:
        rough = 0.08 + 0.1*imp
    return col, rough, z(c), z(c), z(c)

def m_interior(c, I):
    col, rough, metal, ga, gb = m_wpaint(c, dict(I, col=I.get('col') or '#d9d2c3'))
    return col*0.7, rough, metal, ga, gb

def m_food(c, I):
    a, b = c.a, c.b
    kind = I.get('kind')
    n1 = noise(a, b, 0.03, seed=21); n2 = noise(a, b, 0.012, seed=22)
    ga = gb = z(c); rough = 0.55*np.ones_like(a)
    if kind == 'sausage':
        col = lin('#8e3a22')*(0.8+0.4*n1)[..., None]
        marks = (np.abs(((b+0.01) % 0.035) - 0.0175) < 0.003)
        col = np.where(marks[..., None], col*0.35, col); rough = 0.35 + 0.2*n2
    elif kind == 'buns':
        col = lin('#d6a160')*(0.8+0.35*n1)[..., None]; col = col*(0.9+0.2*n2)[..., None]; rough = 0.8*np.ones_like(a)
    elif kind == 'lemons':
        col = lin(I.get('col') or '#f2cc1f')*(0.75+0.4*n1)[..., None]
        dimple = samp(tex('Plastic013A'), a, b, 0.08).mean(-1)
        ga, gb = tex_grad('Rubber004', a, b, 0.06, 0.15); rough = 0.45 + 0.2*n2
    elif kind == 'meat':   # al pastor: stacked marinated slabs (achiote red-orange), charred ridges, pale fat edges
        lay = (b + 0.004*n1) % 0.034 / 0.034
        ridge = np.exp(-((lay-0.5)/0.18)**2)
        slab_e = np.exp(-((lay-0.02)/0.04)**2) + np.exp(-((lay-0.98)/0.04)**2)
        col = lin('#c4461a')*(0.65+0.45*n2)[..., None]
        col = col*(1-0.45*slab_e[..., None]) + lin('#e8b07a')*0.35*slab_e[..., None]
        char = np.clip((n1 + 0.5*ridge - 0.75)*3.5, 0, 1)
        col = col*(1-0.75*char[..., None]) + lin('#2a140a')*0.75*char[..., None]
        ga, gb = grad_h(0.0015*ridge - 0.001*slab_e, c.da, c.db); rough = 0.35 + 0.35*char
    elif kind == 'pineapple':
        hx = (np.sin(a/0.02*TAU)*np.sin(b/0.02*TAU) > 0.2)
        col = np.where(hx[..., None], lin('#c99a2e'), lin('#8c6a1e'))*(0.8+0.3*n1)[..., None]; rough = 0.6*np.ones_like(a)
    elif kind == 'salsa':
        col = lin(I.get('col') or '#a3201a')*(0.7+0.5*n2)[..., None]
        flecks = np.clip((noise(a, b, 0.006, seed=23)-0.6)*5, 0, 1)
        col = col*(1-flecks[..., None]) + lin('#e8e2c8')*flecks[..., None]*0.8; rough = 0.25 + 0.2*n1
    elif kind == 'ice':
        ic = samp(tex('Ice002'), a, b, 0.2).mean(-1)
        col = lin(I.get('col') or '#f4f8fa')*(0.85+0.2*ic)[..., None]; rough = 0.3*np.ones_like(a)
    elif kind == 'tortilla':
        col = lin('#e6cf98')*(0.85+0.25*n1)[..., None]
        spots = np.clip((n2-0.7)*5, 0, 1); col = col*(1-0.5*spots[..., None]); rough = 0.8*np.ones_like(a)
    elif kind == 'leaves':
        col = lin(I.get('col') or '#4f7d2c')*(0.7+0.5*n1)[..., None]; rough = 0.5*np.ones_like(a)
    elif kind == 'shaveice':
        cs = I.get('cols') or ('#e8413c', '#f39a2b', '#2a7bd6')
        t = (a % I['w'])/I['w']
        i3 = np.clip((t*3).astype(int), 0, 2)
        col = np.stack([lin(h) for h in cs])[i3]
        ic = samp(tex('Ice002'), a, b, 0.1).mean(-1)
        col = col*(0.75 + 0.4*ic)[..., None] + 0.12*(1-sstep(0.0, 0.03, I['h']-b))[..., None]
        ga, gb = tex_grad('Ice002', a, b, 0.1, 0.4); rough = 0.35 + 0.2*ic
    elif kind == 'chips':
        # foil snack bag: crimped seals top + bottom, white oval label, yellow chip art, crinkles
        Wb, Hb = I['w'], I['h']; base = lin(I.get('col') or '#d84a2a')
        col = base*(0.8+0.25*n1)[..., None]*np.ones(a.shape+(1,))
        seal = (1 - sstep(0.012, 0.016, b)) + sstep(Hb-0.018, Hb-0.014, b)
        crimp = seal*(0.5+0.5*np.sin(a/0.004*TAU))
        col = col*(1-0.35*crimp[..., None])
        u_ = (a - Wb/2)/0.038; v_ = (b - Hb*0.58)/0.028
        oval = 1 - sstep(0.9, 1.0, u_**2 + v_**2)
        col = col*(1-oval[..., None]) + lin('#f6f2e6')*oval[..., None]
        word = oval*(np.abs(v_) < 0.28)*(np.sin(a/0.006*TAU) > -0.2)
        col = col*(1-word[..., None]) + base*0.6*word[..., None]
        u2 = (a - Wb/2)/0.03; v2 = (b - Hb*0.30)/0.022
        chip = 1 - sstep(0.85, 1.0, u2**2 + v2**2 + 0.3*np.sin(u2*5))
        col = col*(1-chip[..., None]) + lin('#e9b23a')*(0.8+0.3*n2)[..., None]*chip[..., None]
        wr = noise(a, b, 0.02, seed=61); ga, gb = grad_h(0.0012*wr + 0.0006*crimp, c.da, c.db)
        rough = 0.32 + 0.15*wr
    else:
        col = lin(I.get('col') or '#c08040')*(0.8+0.4*n1)[..., None]
    return col, rough, z(c), ga, gb

def m_sign(c, I):
    """printed sign: artwork mapped by world position on the face (orientation-proof) + print grain + sun fade + edge wear."""
    a, b = c.a, c.b
    nw = c.nw.reshape(-1, 3); inner = c.inner.reshape(-1) > 0
    n = nrm_mean = nw[inner].mean(0); n = n/np.linalg.norm(n)
    up = np.array([0.0, 1.0, 0.0]) - n*n[1]
    if np.linalg.norm(up) < 0.2: up = np.array([0.0, 0.0, -1.0]) - n*(-n[2])
    up = up/np.linalg.norm(up); right = np.cross(up, n)
    P = c.pos.reshape(-1, 3)
    u = P @ right; v = P @ up
    u0, u1 = u[inner].min(), u[inner].max(); v0, v1 = v[inner].min(), v[inner].max()
    art = ksigns.draw(I['sign'], u1-u0, v1-v0, 900)
    Hh, Ww = art.shape[:2]
    fx = (u-u0)/max(u1-u0, 1e-6)*(Ww-1); fy = (1-(v-v0)/max(v1-v0, 1e-6))*(Hh-1)
    rgb = np.stack([ndi.map_coordinates(art[..., k], [fy, fx], order=1, mode='nearest') for k in range(3)], -1).reshape(a.shape+(3,))
    col = srgb2lin(rgb)
    imp = samp(tex('SurfaceImperfections003'), a, b, 0.4)
    scr = samp(tex('Scratches005'), a, b, 0.3)
    fade = noise(a, b, 0.4, seed=31)
    col = col*(0.92 + 0.08*fade)[..., None]*(1-0.08*imp)[..., None]
    col = col*(1-0.25*scr[..., None]) + 0.25*scr[..., None]*lin('#d8d8d8')
    rough = 0.45 + 0.2*imp + 0.2*scr
    if I.get('chalk'):
        rough = 0.9*np.ones_like(a)
    ga, gb = tex_grad('Scratches005', a, b, 0.3, 0.02)
    return col, rough, z(c), ga, gb

MATS = dict(steel=m_steel, chrome=m_chrome, brass=m_brass, black=m_black, paint=m_paint, plastic=m_plastic, rubber=m_rubber,
            fabric=m_fabric, wood=m_wood, wpaint=m_wpaint, galv=m_galv, glassy=m_glassy, interior=m_interior, food=m_food, sign=m_sign)
DUST = dict(steel=0.35, chrome=0.25, brass=0.3, black=0.10, paint=0.3, plastic=0.35, rubber=0.08, fabric=0.3, wood=0.45, wpaint=0.3,
            galv=0.5, glassy=0.15, interior=0.1, food=0.0, sign=0.3)

# ---------------------------------------------------------------- main
def load16(p):
    a = np.asarray(Image.open(p)).astype(np.float32); return a/(65535.0 if a.max() > 255 else 255.0)

def main():
    nb = load16(ROOT+'/work/bake_normal.png')[..., :3]*2-1
    ao_b = load16(ROOT+'/work/bake_ao.png')
    if ao_b.ndim == 3: ao_b = ao_b[..., 0]
    if nb.shape[0] != N:
        nb = np.stack([ndi.zoom(nb[..., k], N/nb.shape[0], order=1) for k in range(3)], -1)
        ao_b = ndi.zoom(ao_b, N/ao_b.shape[0], order=1)
    pos, nrmw, cov = raster_world()
    COL = np.zeros((N, N, 3), np.float32); NRM = np.zeros((N, N, 3), np.float32); NRM[..., 2] = 1
    AO = np.ones((N, N), np.float32); RG = np.full((N, N), 0.6, np.float32); MT = np.zeros((N, N), np.float32)
    owner = np.zeros((N, N), bool)
    pad = pack.PAD
    for k, r in sorted(RECTS.items()):
        I = ISL[k]
        x0, y0 = r['x']-pad, r['y']-pad; W, H = r['w']+2*pad, r['h']+2*pad
        x0c, y0c = max(x0, 0), max(y0, 0); x1c, y1c = min(x0+W, N), min(y0+H, N)
        yy, xx = np.mgrid[y0c:y1c, x0c:x1c].astype(np.float32)
        if not r['rot']:
            a = (xx+0.5-r['x'])/r['w']*I['w']; b = (yy+0.5-r['y'])/r['h']*I['h']; da = I['w']/r['w']; db = I['h']/r['h']
        else:
            b = (xx+0.5-r['x'])/r['w']*I['h']; a = (yy+0.5-r['y'])/r['h']*I['w']; da = I['w']/r['h']; db = I['h']/r['w']
        c = Ctx(); c.name = k; c.a = a; c.b = b; c.da = da; c.db = db
        sl = (slice(y0c, y1c), slice(x0c, x1c))
        inner = np.zeros(a.shape, np.float32); iy0, ix0 = r['y']-y0c, r['x']-x0c
        inner[max(iy0, 0):iy0+r['h'], max(ix0, 0):ix0+r['w']] = 1
        c.inner = inner
        baked = I.get('bake', True) and not k.startswith('napkin_paper')   # 4 mm paper: cage self-hits -> flat AO/normal
        if baked and ao_b[r['y']:r['y']+r['h'], r['x']:r['x']+r['w']].mean() < 0.01:
            baked = False   # nothing baked into this island (no canonical face in near, e.g. far-only faces): flat AO/normal
        if baked:
            aoi = ndi.gaussian_filter(ao_b[sl]*inner, 1.2)/np.maximum(ndi.gaussian_filter(inner, 1.2), 1e-3)
            aoi = np.where(inner > 0, aoi, ao_b[sl])
        else:
            aoi = np.full(a.shape, 0.9, np.float32)
        c.ao = aoi; c.pos = pos[sl]; c.nw = nrmw[sl]
        col, rough, metal, ga, gb = MATS.get(I['mat'], m_paint)(c, I)
        rough = np.broadcast_to(np.asarray(rough, np.float32), a.shape); metal = np.broadcast_to(np.asarray(metal, np.float32), a.shape)
        # world-space weathering: beach sand dust low down + in crevices, grime streaks below
        y = c.pos[..., 1]; up = np.clip(c.nw[..., 1], 0, 1)
        sand = samp(tex('Ground054'), a, b, 0.6)
        dn = noise(a, b, 0.1, seed=41)
        dust = np.clip((0.35-y)/0.35, 0, 1)*0.45 + np.clip((0.6-aoi)/0.5, 0, 1)*0.3 + up*0.10
        dust = np.clip(dust*(0.5+0.9*dn), 0, 0.65)*DUST.get(I['mat'], 0.3)
        col = col*(1-dust[..., None]) + srgb2lin(sand)*0.8*dust[..., None]
        rough = np.clip(rough + 0.35*dust, 0.04, 1); metal = metal*(1-0.6*dust)
        aof = np.clip(aoi, 0, 1)
        col = col*(0.5 + 0.5*aof)[..., None]   # kit rule: AO also in base colour (softened)
        dx, dy = (-ga, gb) if not r['rot'] else (-gb, ga)
        nbk = nb[sl] if baked else np.dstack([z(c), z(c), np.ones_like(a)])
        nbk = nbk/np.maximum(np.linalg.norm(nbk, axis=-1, keepdims=True), 1e-6)
        nn = np.dstack([nbk[..., 0] + dx*nbk[..., 2], nbk[..., 1] + dy*nbk[..., 2], nbk[..., 2]])
        nn = nn/np.linalg.norm(nn, axis=-1, keepdims=True)
        free = ~owner[sl]
        for arr, val in ((COL, col), (NRM, nn)):
            arr[sl] = np.where(free[..., None], val, arr[sl])
        for arr, val in ((AO, aof), (RG, rough), (MT, metal)):
            arr[sl] = np.where(free, val, arr[sl])
        isl_ = (slice(r['y'], r['y']+r['h']), slice(r['x'], r['x']+r['w']))
        li = (slice(r['y']-y0c, r['y']-y0c+r['h']), slice(r['x']-x0c, r['x']-x0c+r['w']))
        COL[isl_] = col[li]; NRM[isl_] = nn[li]; AO[isl_] = aof[li]; RG[isl_] = rough[li]; MT[isl_] = metal[li]
        owner[isl_] = True
    # unused space: fill by nearest owned texel (keeps mips clean)
    idx = ndi.distance_transform_edt(~owner, return_distances=False, return_indices=True)
    for arr in (COL, NRM, AO, RG, MT): arr[...] = arr[idx[0], idx[1]]
    os.makedirs(ROOT+'/tex', exist_ok=True)
    Image.fromarray((lin2srgb(COL)*255+0.5).astype(np.uint8)).save(ROOT+'/work/color_2048.png')
    Image.fromarray(((NRM*0.5+0.5)*255+0.5).clip(0, 255).astype(np.uint8)).save(ROOT+'/work/normal_2048.png')
    orm = np.dstack([AO, RG, MT]); Image.fromarray((np.clip(orm, 0, 1)*255+0.5).astype(np.uint8)).save(ROOT+'/work/orm_2048.png')
    def down(arr, size):
        f = arr.shape[0]//size; return arr.reshape(size, f, size, f, -1).mean((1, 3))
    c_ = down(COL.astype(np.float64), SHIP['color'])
    n_ = down(NRM.astype(np.float64), SHIP['normal']); n_ /= np.linalg.norm(n_, axis=-1, keepdims=True)
    o_ = down(orm.astype(np.float64), SHIP['orm'])
    Image.fromarray((lin2srgb(c_)*255+0.5).astype(np.uint8)).save(ROOT+'/tex/kiosks_color.png', optimize=True)
    Image.fromarray(((n_*0.5+0.5)*255+0.5).clip(0, 255).astype(np.uint8)).save(ROOT+'/tex/kiosks_normal.png', optimize=True)
    Image.fromarray((np.clip(o_, 0, 1)*255+0.5).astype(np.uint8)).save(ROOT+'/tex/kiosks_orm.png', optimize=True)
    print('compose done', {k: v for k, v in SHIP.items()})

if __name__ == '__main__':
    main()
