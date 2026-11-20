"""Shared detail parts for the kiosks (bottles, napkin box, propane tank, cooler, wheels, umbrella, valance, signs, food)."""
import numpy as np, math
from kgeo import *

def small(m):  # small dressing parts live on hp + near only
    return m.lod in ('hp', 'near')

# ---------------------------------------------------------------- condiments / counter dressing
def squeeze_bottle(m, base, colour, name, canon=None):
    """220 mm squeeze bottle with nozzle. colour key: red / yellow / green / white / orange"""
    if not small(m): return
    isl = m.isl('bottle_'+name, TAU*0.03, 0.24, 'plastic', col=colour, weight=1.5, kind='bottle')
    can = m.first(isl) if canon is None else canon
    seg = K(m.lod, 24, 8, 6, 6)
    prof = [(0.0001, 0.0), (0.026, 0.002), (0.029, 0.012), (0.03, 0.15), (0.027, 0.17), (0.022, 0.175), (0.021, 0.19),
            (0.016, 0.195), (0.012, 0.205), (0.006, 0.235), (0.002, 0.245), (0.0001, 0.246)]
    if not m.hp: prof = [prof[i] for i in (0, 2, 3, 4, 6, 7, 9, 11)]
    lathe(m, prof, np.asarray(base, float), Y, Z, seg, isl, canon=can)

def napkin_box(m, c, yaw=0.0, canon=None):
    if not small(m): return
    ex = np.array([math.cos(yaw), 0, -math.sin(yaw)]); ez = np.array([math.sin(yaw), 0, math.cos(yaw)])
    can = m.first('napkin') if canon is None else canon
    bbox(m, np.asarray(c, float)+np.array([0, 0.09, 0]), (0.13, 0.18, 0.12), 'napkin', 'chrome', r=0.012, rb=0.01,
         ncs=K(m.lod, 4, 1, 0, 0), npb=K(m.lod, 4, 1, 0, 0), axes=(ex, Y, ez), weight=1.6, canon=can, bottom=False, kind='napkin')
    if m.lod in ('hp', 'near'):   # paper napkins fanning out of the dispenser slot
        for k, (dx, dz, ang) in enumerate(((-0.018, -0.006, -0.12), (0.02, 0.006, 0.15))):   # two fanned sheets, not coplanar
            ey_ = nrm(Y*math.cos(ang) + ex*math.sin(ang)); ex_ = nrm(np.cross(ey_, ez))
            bbox(m, np.asarray(c, float)+np.array([0, 0.195, 0])+ex*dx+ez*dz, (0.085, 0.04, 0.004), 'napkin_paper', 'plastic', col='#f7f5ee',
                 axes=(ex_, ey_, ez), weight=0.8, canon=can and k == 0, bottom=False, kind='plain', share=True)

def cup_stack(m, base, n_cups=10, colour='white', name='cups', canon=None):
    if not small(m): return
    isl = m.isl('cups_'+name, TAU*0.045, 0.32, 'plastic', col=colour, weight=1.2, kind='cups')
    can = m.first(isl) if canon is None else canon
    seg = K(m.lod, 24, 8, 6, 6)
    h = 0.11 + 0.012*(n_cups-1)
    prof = [(0.0001, 0.0), (0.03, 0.0), (0.045, h-0.004), (0.047, h), (0.040, h), (0.0001, h-0.003)]
    if m.hp:
        rows = [(0.0001, 0.0), (0.03, 0.0)]
        for i in range(n_cups):   # stacked rims
            y = 0.11*0 + 0.012*i + 0.098
            rr = 0.03 + (0.045-0.03)*(y/h)
            rows += [(rr+0.0005, y), (rr+0.0025, y+0.002), (rr+0.0005, y+0.004)]
        rows += [(0.045, h-0.004), (0.047, h), (0.040, h), (0.0001, h-0.003)]
        prof = rows
    lathe(m, prof, np.asarray(base, float), Y, Z, seg, isl, canon=can)

def tip_jar(m, base, canon=None):
    if not small(m): return
    isl = m.isl('tipjar', TAU*0.06, 0.2, 'glassy', col='#cfe3e6', weight=1.2, kind='tipjar')
    can = m.first(isl) if canon is None else canon
    prof = [(0.0001, 0), (0.055, 0), (0.06, 0.01), (0.06, 0.14), (0.045, 0.16), (0.045, 0.175), (0.0001, 0.176)]
    lathe(m, prof, np.asarray(base, float), Y, Z, K(m.lod, 24, 8, 6, 6), isl, canon=can)

def propane_tank(m, base, h=0.46, r=0.155, name='tank', colour='#e8e6df', canon=None):
    """20 lb style propane cylinder with foot ring, collar and valve."""
    if m.lod == 'far': return
    isl = m.isl('tank_'+name, TAU*r, h+0.25, 'paint', col=colour, weight=1.0, kind='tank')
    can = m.first(isl) if canon is None else canon
    seg = K(m.lod, 32, 12, 8, 6)
    b = np.asarray(base, float)
    if m.hp:
        prof = [(r*0.82, 0.0), (r*0.86, 0.0), (r*0.86, 0.045), (r*0.9, 0.05)]
        for t in np.linspace(0, 1, 6)[1:]:
            a = t*math.pi/2; prof.append((r*0.9 + 0.1*r*math.sin(a), 0.05 + 0.05*r*(1-math.cos(a))))
        prof += [(r, h*0.25), (r, h*0.72)]
        for t in np.linspace(0, 1, 9)[1:]:
            a = t*math.pi/2; prof.append((r*math.cos(a)*0.98 + 0.001, h*0.72 + (h*0.86-h*0.72)*math.sin(a)*1.0))
        prof = [p for p in prof if p[0] > 0.03] + [(0.03, h*0.9)]
    elif m.lod == 'near':
        prof = [(r*0.86, 0.0), (r*0.86, 0.045), (r, 0.08), (r, h*0.72), (r*0.78, h*0.84), (0.03, h*0.9)]
    else:
        prof = [(r, 0.0), (r, h*0.72), (r*0.6, h*0.87), (0.03, h*0.9)]
    lathe(m, prof, b, Y, Z, seg, isl, canon=can, cap_top=True)
    if m.lod in ('hp', 'near'):
        # carry collar (ring with two hand holes) + valve
        isl2 = m.isl('tank_collar_'+name, TAU*r*0.75, 0.13, 'paint', col=colour, weight=1.1, kind='tank')
        prof2 = [(r*0.66, h*0.8), (r*0.70, h*0.8), (r*0.70, h*1.06), (r*0.66, h*1.06)] if m.hp else [(r*0.69, h*0.82), (r*0.69, h*1.06)]
        lathe(m, prof2, b, Y, Z, K(m.lod, 32, 10, 8, 6), isl2, canon=can)
        if m.hp:  # inner face
            lathe(m, [(r*0.66, h*1.06), (r*0.66, h*0.8)], b, Y, Z, 32, isl2, canon=can)
        isl3 = m.isl('valve', TAU*0.025, 0.12, 'brass', weight=1.4, kind='valve')
        vp = [(0.026, h*0.9), (0.026, h*0.93), (0.012, h*0.95), (0.012, h*0.98), (0.03, h*0.99), (0.03, h*1.01), (0.0001, h*1.015)]
        lathe(m, vp, b, Y, Z, K(m.lod, 16, 6, 6, 6), isl3, canon=can)
        tube(m, [b+np.array([0, h*0.95, 0]), b+np.array([0.05, h*0.95, 0])], 0.008, K(m.lod, 8, 4, 4, 4), isl3, canon=False, caps=(False, True))

def cooler(m, c, size=(0.62, 0.40, 0.38), yaw=0.0, colour='#2f6fb3', name='cooler', canon=None):
    """ice chest: coloured body, white lid, handles, latch."""
    ex = np.array([math.cos(yaw), 0, -math.sin(yaw)]); ez = np.array([math.sin(yaw), 0, math.cos(yaw)])
    c = np.asarray(c, float); sx, sy, sz = size
    can = m.first('cooler_'+name) if canon is None else canon
    hb = sy*0.78
    bbox(m, c+np.array([0, hb/2, 0]), (sx, hb, sz), 'cooler_'+name, 'plastic', r=0.03, rb=0.02, axes=(ex, Y, ez), weight=0.9,
         canon=can, bottom=False, top=m.lod == 'far', col=colour, kind='cooler')
    if m.lod == 'far': return
    bbox(m, c+np.array([0, hb + (sy-hb)/2, 0]), (sx+0.01, sy-hb, sz+0.01), 'coolerlid_'+name, 'plastic', r=0.03, rb=0.015,
         axes=(ex, Y, ez), weight=0.9, canon=can, col='#eeeeea', kind='coolerlid')
    if small(m):
        isl = m.isl('cooler_handle', 0.06, 0.3, 'plastic', col='#e8e8e2', weight=1.0, kind='plain')
        for s in (-1, 1):
            p0 = c + ex*(s*(sx/2+0.005)) + Y*(hb*0.7)
            P = [p0 + ez*(-0.11), p0 + ex*s*0.03 + ez*(-0.08), p0 + ex*s*0.03 + ez*0.08, p0 + ez*0.11]
            tube(m, catmull(P, K(m.lod, 12, 5, 4, 4)), 0.011, K(m.lod, 8, 4, 4, 4), isl, canon=can and s == 1)

# ---------------------------------------------------------------- wheels
def cart_wheel(m, C, axis, R=0.2, w=0.07, name='cartwheel', node='main', canon=None, hub_col='#c9ccd0', spokes=0):
    """pneumatic cart wheel: tyre (rubber, lathe, 6 UV sectors) + steel rim/disc + hub."""
    C = np.asarray(C, float); ax = nrm(axis)
    ref = Y if abs(ax[1]) < 0.9 else Z
    can = m.first('wheel_'+name) if canon is None else canon
    segs = K(m.lod, 72, 18, 12, 8)
    if m.lod == 'far':
        segs = 8
    t = np.linspace(-1, 1, K(m.lod, 17, 5, 3, 3))
    ang = t*math.radians(120)
    rc = R - w*0.45
    tr = np.stack([rc + w*0.45*np.cos(ang), w*0.5*np.sin(ang)], 1)
    tr[0, 0] = tr[-1, 0] = R*0.72
    # profile ordered bottom->top in lathe means (r, h along axis): go from -h to +h over the crown (outer) -> normals outward
    prof = tr[::-1] if True else tr
    Lp = float(np.sum(np.linalg.norm(np.diff(tr, axis=0), axis=1)))
    isl = m.isl('tyre_'+name, TAU*R/6, Lp*1.2, 'rubber', weight=1.0, kind='tyre')
    reps = 6 if segs % 6 == 0 else 1
    if m.lod == 'far': reps = 1
    lathe(m, prof[:, ::1], C, ax, ref, segs, isl, node, repeats=reps, canon=can, flip=True)
    if m.lod == 'far':   # flat disc both sides so the far wheel is not a hollow ring
        isl2 = m.isl('rim_'+name, TAU*R*0.72, 0.2, 'paint', col=hub_col, weight=1.1, kind='rim')
        oth = np.cross(ax, ref); rr = R*0.72
        for s_ in (1, -1):
            pts = [C + s_*ax*w*0.3 + rr*(math.cos(t)*ref + math.sin(t)*oth) for t in TAU*np.arange(8)/8]
            uv = [(rr*(0.2 + 0.1*k), 0.05) for k in range(8)]   # all on the painted disc band
            nn = np.cross(pts[1]-pts[0], pts[2]-pts[0])
            m.poly(pts, uv, isl2, node, flip=np.dot(nn, s_*ax) < 0, canon=False)
        return
    # rim + disc (one profile from outer face inward, both faces)
    rr = R*0.72
    if m.hp:
        dp = [(rr, w*0.42), (rr-0.006, w*0.36), (rr*0.8, w*0.30), (rr*0.55, w*0.32), (rr*0.40, w*0.42), (0.03, w*0.5), (0.0001, w*0.52)]
    elif m.lod == 'near':
        dp = [(rr, w*0.42), (rr*0.8, w*0.30), (rr*0.42, w*0.40), (0.0001, w*0.52)]
    else:
        dp = [(rr, w*0.42), (0.0001, w*0.45)]
    dp = np.array(dp)
    isl2 = m.isl('rim_'+name, TAU*rr, 0.2, 'paint', col=hub_col, weight=1.1, kind='rim')
    for s in (1, -1):
        prof2 = dp.copy(); prof2[:, 1] *= s
        if s == 1: prof2 = prof2   # from rim (outer r) inward to the hub cap at +w/2: outward = +axis side
        lathe(m, prof2, C, ax, ref, K(m.lod, 48, 12, 8, 8), isl2, node, canon=can and s == 1, flip=(s == -1))   # each disc faces out along s*axis
    if m.hp:   # lug nuts and valve stem for the bake
        isl3 = m.isl('lug', 0.03, 0.02, 'chrome', bake=False)
        for k in range(5):
            a = TAU*k/5; p = C + w*0.42*ax + 0.045*(math.cos(a)*ref + math.sin(a)*np.cross(ax, ref))
            lathe(m, [(0.008, 0), (0.008, 0.012), (0.0001, 0.014)], p, ax, ref, 6, isl3, canon=False)

# ---------------------------------------------------------------- umbrella (market/cart umbrella with sagging panels + scalloped valance)
def umbrella(m, top, R=0.95, rise=0.32, panels=8, name='umb', colours=('#f2c230', '#1f5fa8'), valance=0.11, node='main', canon=None, unique=False):
    """top = pole top point (canopy apex). 2-panel UV sectors (stripe colour A/B), canonical sector 0."""
    top = np.asarray(top, float)
    can = m.first('umb_'+name) if canon is None else canon
    sub = K(m.lod, 8, 2, 1, 1); rows = K(m.lod, 10, 3, 2, 1)
    pa = TAU/panels
    sector_w = 2*pa*R
    isl_t = m.isl('umbtop_'+name, sector_w, R*1.05, 'fabric', weight=0.75, colours=colours, kind='umbrella')
    isl_b = m.isl('umbbot_'+name, sector_w, R*1.05, 'fabric', weight=0.3, colours=colours, kind='umbrella_under')
    isl_e = m.isl('umbedge_'+name, 0.5, 0.01, 'fabric', bake=False, weight=0.3, colours=colours, kind='plain')
    def surf(th0, th1, n_t):
        th = np.linspace(th0, th1, n_t+1)
        rr = np.linspace(0, 1, rows+1)**1.0
        # radial profile: slightly domed
        G = []; A = []; Bv = []
        for ri in rr:
            row = []; ar = []; br = []
            for t in th:
                frac = ((t - th0) % pa)/pa
                sag = 0.045*R*ri*math.sin(math.pi*frac)**1.0 if m.lod != 'far' else 0.0
                r_ = max(R*ri, 0.0005)
                # rib line: drop = rise*(ri) (cone) with a dome bulge
                y = -rise*ri + 0.05*math.sin(math.pi*ri)*R*0.6 - sag
                rp = r_*(1 - 0.03*math.sin(math.pi*frac)) if ri > 0 else 0.0005
                row.append(top + np.array([rp*math.cos(t), y, rp*math.sin(t)]))
                ar.append((t-th0)*R); br.append(ri*R)
            G.append(row); A.append(ar); Bv.append(br)
        return np.array(G), np.array(A), np.array(Bv)
    nsec = panels//2
    for k in range(nsec):
        th0 = k*2*pa + pa/2*0; th1 = th0 + 2*pa
        G, A, Bv = surf(th0, th1, 2*sub)
        it, ib, ck = isl_t, isl_b, can and k == 0
        if unique:
            cs = (colours[(2*k) % len(colours)], colours[(2*k+1) % len(colours)])
            it = m.isl(f'umbtop_{name}{k}', sector_w, R*1.05, 'fabric', weight=0.75, colours=cs, kind='umbrella')
            ib = m.isl(f'umbbot_{name}{k}', sector_w, R*1.05, 'fabric', weight=0.3, colours=cs, kind='umbrella_under')
            ck = can
        slab(m, G, 0.004, it, ib, isl_e, node, canon=ck, Atop=A, Btop=Bv, up_hint=(0, 1, 0),
             edges=m.lod == 'hp', bottom=m.lod != 'far')
    if valance and m.lod != 'far':
        isl_v = m.isl('umbval_'+name, sector_w*1.02, valance+0.01, 'fabric', weight=0.8, colours=colours, kind='valance')
        nsc = K(m.lod, 10, 4, 2, 2)
        for k in range(nsec):
            pts_t = []; pts_b = []; Av = []
            for pi_ in range(2):
                t0 = k*2*pa + pi_*pa
                p0 = np.array([R*math.cos(t0), 0, R*math.sin(t0)]); p1 = np.array([R*math.cos(t0+pa), 0, R*math.sin(t0+pa)])
                for j in range(nsc+1):
                    if pi_ == 1 and j == 0: continue
                    f = j/nsc
                    p = p0*(1-f) + p1*f
                    p = p/np.linalg.norm(p)*R*1.0
                    yb = -valance + 0.028*(1-abs(math.sin(math.pi*f))) if m.lod != 'mid' else -valance + 0.012
                    pts_t.append(top + p + np.array([0, -rise + 0.05*0*R, 0]) + np.array([0, 0.05*math.sin(math.pi)*R*0.6, 0]))
                    pts_b.append(pts_t[-1] + np.array([0, yb, 0]))
                    Av.append((pi_ + f)*pa*R)
            G = np.array([pts_t, pts_b])
            Bv = np.array([[0.0]*len(Av), [valance]*len(Av)])
            # small outward flare
            G[1] = G[1] + nrm(G[1]-top*np.array([1, 0, 1]) - np.array([0, G[1][0][1], 0]))*0.0
            iv, cv = isl_v, can and k == 0
            if unique:
                cs = (colours[(2*k) % len(colours)], colours[(2*k+1) % len(colours)])
                iv = m.isl(f'umbval_{name}{k}', sector_w*1.02, valance+0.01, 'fabric', weight=0.8, colours=cs, kind='valance'); cv = can
            slab(m, G, 0.003, iv, iv, isl_e, node, canon=cv, Atop=np.array([Av, Av]), Btop=Bv, up_hint=None, edges=False)
    if m.lod in ('hp', 'near'):
        # ribs under the canopy + finial
        isl_r = m.isl('umbrib', 0.03, R*1.1, 'steel', weight=0.5, kind='plain')
        for k in range(panels):
            t = k*pa
            p_out = top + np.array([R*0.98*math.cos(t), -rise*0.98 + 0.05*math.sin(math.pi*0.98)*R*0.6 - 0.008, R*0.98*math.sin(t)])
            p_in = top + np.array([0.02*math.cos(t), -0.02, 0.02*math.sin(t)])
            tube(m, [p_in, p_out], 0.0045, K(m.lod, 6, 3, 3, 3), isl_r, node, canon=can and k == 0)
            # stretcher
            q = top + np.array([0.0, -0.45, 0.0]); pm = p_in*0.45 + p_out*0.55 - np.array([0, 0.012, 0])
            tube(m, [q + np.array([0.012*math.cos(t), 0, 0.012*math.sin(t)]), pm], 0.0035, K(m.lod, 6, 3, 3, 3), isl_r, node, canon=False)
        isl_f = m.isl('finial', TAU*0.02, 0.08, 'plastic', col='#f4f2ea', weight=1.2, kind='plain')
        lathe(m, [(0.022, 0), (0.024, 0.01), (0.018, 0.03), (0.008, 0.05), (0.0001, 0.06)], top + np.array([0, -0.004, 0]), Y, Z,
              K(m.lod, 16, 6, 6, 6), isl_f, node, canon=can)

def pole(m, p0, p1, r, name='pole', mat='chrome', node='main', canon=None, col=None):
    isl = m.isl('pole_'+name, TAU*r, np.linalg.norm(np.asarray(p1)-p0)+0.01, mat, weight=0.8, col=col, kind='pole')
    can = m.first(isl) if canon is None else canon
    tube(m, [np.asarray(p0, float), np.asarray(p1, float)], r, K(m.lod, 12, 6, 4, 3), isl, node, canon=can)

# ---------------------------------------------------------------- scalloped valance strip along a polyline (awnings)
def valance_strip(m, pts, depth, isl, node='main', canon=True, scallops_per_m=4.0, t=0.003, outward=None):
    """vertical fabric strip hanging from polyline pts with scalloped lower edge."""
    pts = np.asarray(pts, float)
    L = np.r_[0, np.cumsum(np.linalg.norm(np.diff(pts, axis=0), axis=1))]
    tot = L[-1]
    nsc = max(int(round(tot*scallops_per_m)), 1)
    per = K(m.lod, 8, 3, 1, 1)
    s = np.linspace(0, tot, nsc*per+1)
    P = np.stack([np.interp(s, L, pts[:, k]) for k in range(3)], 1)
    f = (s/tot*nsc) % 1.0
    drop = depth - (0.03 if m.lod in ('hp', 'near') else 0.015)*(1-np.abs(np.sin(math.pi*f)))
    G = np.array([P, P - np.outer(drop, Y)])
    A = np.array([s, s]); B = np.array([np.zeros_like(s), drop])
    slab(m, G, t, isl, isl, isl, node, canon=canon, Atop=A, Btop=B, up_hint=outward, edges=False)

# ---------------------------------------------------------------- food piles (HP: individual fruits; LP: lumpy surface)
def _fruit_layout(sx, sz, h, fruit_r, seed, mound):
    rng = np.random.default_rng(seed)
    nx = max(int(sx/(fruit_r*1.9)), 1); nz = max(int(sz/(fruit_r*1.9)), 1)
    out = []
    for layer in range(2):
        for i in range(nx - layer):
            for j in range(nz - layer):
                x = -sx/2 + fruit_r + (i + 0.5*layer)*(sx-2*fruit_r)/max(nx-1, 1) + rng.normal(0, fruit_r*0.08)
                z = -sz/2 + fruit_r + (j + 0.5*layer)*(sz-2*fruit_r)/max(nz-1, 1) + rng.normal(0, fruit_r*0.08)
                ctr = 1 - (abs(x)/(sx/2))**2*0.5 - (abs(z)/(sz/2))**2*0.5
                y = -fruit_r*0.6 + layer*fruit_r*1.2*ctr + mound*h*ctr*0.4
                rr = fruit_r*(0.92 + 0.12*rng.random())
                ax_ = nrm(rng.normal(0, 0.3, 3) + np.array([0, 1, 0]))
                out.append((x, y, z, rr, ax_))
    return out

def fruit_pile(m, c, sx, sz, h, fruit_r, isl, node='main', canon=True, seed=1, mound=0.6):
    """pile filling a crate opening of sx x sz at height c (top of crate). HP = spheres; near = height-field grid that follows the
    tops of the same spheres (each fruit reads as a bump in silhouette); mid/far = mound."""
    c = np.asarray(c, float)
    fruits = _fruit_layout(sx, sz, h, fruit_r, seed, mound)
    if m.hp:
        for (x, y, z, rr, ax_) in fruits:
            prof = [(rr*math.sin(a)+0.00005, -rr*math.cos(a)*1.08) for a in np.linspace(0, math.pi, 7)]
            lathe(m, prof, c + np.array([x, y, z]), ax_, X if abs(ax_[0]) < 0.9 else Z, 10, isl, node, canon=False)
        return
    if m.lod == 'near':
        nxg = max(int(round(sx/(fruit_r*0.95))), 2); nzg = max(int(round(sz/(fruit_r*0.95))), 2)
        xs = np.linspace(-sx/2, sx/2, nxg+1); zs = np.linspace(-sz/2, sz/2, nzg+1)
        G = np.zeros((nzg+1, nxg+1, 3)); A = np.zeros_like(G[..., 0]); B = np.zeros_like(G[..., 0])
        for i, z in enumerate(zs):
            for j, x in enumerate(xs):
                y = fruit_r*0.1
                for (fx, fy, fz, rr, _) in fruits:
                    d2 = (x-fx)**2 + (z-fz)**2
                    if d2 < rr*rr: y = max(y, fy + math.sqrt(rr*rr - d2)*1.08)
                edge = (i in (0, nzg)) or (j in (0, nxg))
                if edge: y = min(y, fruit_r*0.5)
                G[i, j] = c + np.array([x, y, z]); A[i, j] = x + sx/2 + 0.001; B[i, j] = z + sz/2 + 0.001
        m.grid(G, A, B, isl, node, flip=True, canon=canon)
        return
    rng = np.random.default_rng(seed)
    n = K(m.lod, 0, 5, 2, 1)
    xs = np.linspace(-sx/2, sx/2, n+1); zs = np.linspace(-sz/2, sz/2, n+1)
    G = np.zeros((n+1, n+1, 3)); A = np.zeros((n+1, n+1)); B = np.zeros((n+1, n+1))
    for i, z in enumerate(zs):
        for j, x in enumerate(xs):
            ctr = max(0.0, 1 - (abs(x)/(sx/2))**2*0.5 - (abs(z)/(sz/2))**2*0.5)
            edge = (abs(x) > sx/2-1e-6) or (abs(z) > sz/2-1e-6)
            y = (mound*h*ctr*0.4 + fruit_r*0.55) if not edge else fruit_r*0.1
            G[i, j] = c + np.array([x, y, z]); A[i, j] = x + sx/2 + 0.001; B[i, j] = z + sz/2 + 0.001
    m.grid(G, A, B, isl, node, flip=True, canon=canon)

# ---------------------------------------------------------------- more dressing
def syrup_bottle(m, base, colour, k, canon=None):
    """750 ml syrup bottle with pour spout, coloured syrup (shave ice)."""
    if not small(m): return
    isl = m.isl('syrup_'+str(k), TAU*0.035, 0.32, 'glassy', col=colour, weight=1.3, kind='jar', level=0.82)
    can = m.first(isl) if canon is None else canon
    prof = [(0.0001, 0), (0.033, 0), (0.035, 0.01), (0.035, 0.19), (0.03, 0.21), (0.014, 0.25), (0.013, 0.27), (0.009, 0.275), (0.004, 0.31), (0.0001, 0.312)]
    if not m.hp: prof = [prof[i] for i in (0, 1, 3, 5, 6, 8, 9)]
    lathe(m, prof, np.asarray(base, float), Y, Z, K(m.lod, 20, 6, 6, 6), isl, canon=can)

def tub(m, base, r, h, fill_col, k, canon=None, fill_kind='salsa', wall='#f4f4ee'):
    """round deli tub with food filling (salsa, limes...)."""
    if not small(m): return
    isl = m.isl('tub_'+k, TAU*r, h*2.2, 'plastic', col=wall, weight=1.0, kind='plain')
    can = m.first(isl) if canon is None else canon
    b = np.asarray(base, float)
    prof = [(0.0001, 0), (r*0.85, 0), (r, h), (r*0.96, h)] if not m.hp else [(0.0001, 0), (r*0.85, 0), (r*0.86, 0.004), (r, h-0.004), (r*1.02, h), (r*0.97, h)]
    lathe(m, prof, b, Y, Z, K(m.lod, 24, 8, 6, 6), isl, canon=can)
    fi = m.isl('fill_'+k, 2*r, 2*r, 'food', col=fill_col, kind=fill_kind, weight=1.0)
    lathe(m, [(r*0.96, h*0.88), (r*0.5, h*0.95), (0.0001, h*0.97)], b, Y, Z, K(m.lod, 24, 8, 6, 6), fi, canon=can)

def bell(m, top, s=1.0, canon=None):
    """brass hand bell (paletero cart)."""
    if not small(m): return
    isl = m.isl('bell', TAU*0.03*s, 0.08*s, 'brass', weight=1.4, kind='plain')
    can = m.first('bell_inst') if canon is None else canon
    t = np.asarray(top, float)
    prof = [(0.032*s, -0.06*s), (0.03*s, -0.052*s), (0.022*s, -0.03*s), (0.016*s, -0.01*s), (0.008*s, 0.0), (0.0001, 0.002*s)]
    lathe(m, prof, t, Y, Z, K(m.lod, 20, 7, 6, 6), isl, canon=can)
    if m.hp:   # inner wall
        lathe(m, [(0.0001, -0.012*s), (0.02*s, -0.032*s), (0.03*s, -0.06*s)], t, Y, Z, 20, isl, canon=False)

def crate(m, c, size, name, yaw=0.0, canon=None, fill=None, fill_col='#f2cc1f', fruit_r=0.035, seed=1):
    """wooden slat crate (open top) with optional fruit pile (HP fruits -> baked)."""
    ex = np.array([math.cos(yaw), 0, -math.sin(yaw)]); ez = np.array([math.sin(yaw), 0, math.cos(yaw)])
    c = np.asarray(c, float); sx, sy, sz = size
    can = m.first('crate_'+name) if canon is None else canon
    bbox(m, c+np.array([0, sy/2, 0]), size, 'crate_'+name, 'wood', r=0.006, rb=0.006, ncs=K(m.lod, 2, 0, 0, 0), npb=K(m.lod, 2, 1, 0, 0),
         axes=(ex, Y, ez), top=False, bottom=False, weight=1.0, canon=can, col='#c7a06a', kind='crate', slats=True)
    if m.hp:   # slat gaps + corner posts for the bake
        for f in (1, -1):
            for zz in (1, -1):
                bbox(m, c + ex*(f*(sx/2-0.012)) + ez*(zz*(sz/2+0.004)) + np.array([0, sy/2, 0]), (0.024, sy, 0.012), 'crate_hp', 'wood', r=0.003, rb=0.003, ncs=2, npb=2, axes=(ex, Y, ez), bake=False)
    if fill and m.lod != 'far':
        fi = m.isl('pile_'+name, sx, sz, 'food', col=fill_col, kind='lemons', weight=1.2)
        fruit_pile(m, c + np.array([0, sy*0.82, 0]), sx-0.02, sz-0.02, sy*0.5, fruit_r, fi, canon=can, seed=seed)
    elif m.lod != 'far':
        # inner floor so the open crate is not see-through
        fi = m.isl('crate_floor_'+name, sx, sz, 'wood', col='#a88457', weight=0.5)
        quad(m, c + np.array([-sx/2+0.01, 0.02, sz/2-0.01]), c + np.array([sx/2-0.01, 0.02, sz/2-0.01]),
             c + np.array([sx/2-0.01, 0.02, -sz/2+0.01]), c + np.array([-sx/2+0.01, 0.02, -sz/2+0.01]), fi, canon=can)
