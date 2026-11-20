"""Core parametric mesh kit for the street-food kiosks (pure numpy; runs in Blender and system python).
glTF frame: X = right (seen from the customer), Y up, Z = towards the customer (front). Origin on the ground, footprint centre.
Every part is a parametric grid, so UVs (island-local metres a,b) match across LODs. LOD: 'hp' (bake source), 'near', 'mid', 'far'.
Adapted from tools/bicycle/geo.py (Mesh, tube, lathe, orient)."""
import numpy as np, math
TAU = 2*math.pi
X, Y, Z = np.eye(3)

def nrm(v):
    v = np.asarray(v, float); n = np.linalg.norm(v, axis=-1, keepdims=True); return v/np.maximum(n, 1e-12)

def K(lod, hp, near, mid, far):
    return {'hp': hp, 'near': near, 'mid': mid, 'far': far}[lod]

def catmull(P, n):
    P = np.asarray(P, float); Q = np.vstack([2*P[0]-P[1], P, 2*P[-1]-P[-2]])
    segs = len(P)-1; out = []
    for i in range(n):
        u = i/(n-1)*segs; k = min(int(u), segs-1); t = u-k
        p0, p1, p2, p3 = Q[k], Q[k+1], Q[k+2], Q[k+3]
        out.append(0.5*((2*p1) + (-p0+p2)*t + (2*p0-5*p1+4*p2-p3)*t*t + (-p0+3*p1-3*p2+p3)*t**3))
    return np.array(out)

def frames(P, up=None):
    T = nrm(np.gradient(P, axis=0))
    ref = np.array([1.0, 0, 0]) if up is None else np.asarray(up, float)
    if abs(np.dot(ref, T[0])) > 0.9: ref = np.array([0, 1.0, 0]) if abs(T[0][1]) < 0.9 else np.array([0, 0, 1.0])
    N = [nrm(np.cross(np.cross(T[0], ref), T[0]))]
    for i in range(1, len(P)):
        b = np.cross(T[i-1], T[i]); s = np.linalg.norm(b); n = N[-1]
        if s > 1e-9:
            b /= s; ang = math.atan2(s, np.dot(T[i-1], T[i]))
            n = n*math.cos(ang) + np.cross(b, n)*math.sin(ang) + b*np.dot(b, n)*(1-math.cos(ang))
        n = nrm(n - T[i]*np.dot(n, T[i])); N.append(n)
    N = np.array(N); return T, N, np.cross(T, N)

class Mesh:
    """V, AB (island-local metres), ISL (island per vertex), F, FN (node), FB (bake-canonical), FP (part id)."""
    def __init__(s, lod, kid=''):
        s.lod = lod; s.kid = kid; s.V = []; s.AB = []; s.ISL = []; s.F = []; s.FN = []; s.FB = []
        s.islands = {}; s.FP = []; s.part = 0; s.depth = 0; s.hint = {}; s._first = set(); s.col = []
    @property
    def hp(s): return s.lod == 'hp'
    def first(s, key):
        if key in s._first: return False
        s._first.add(key); return True
    def begin(s):
        if s.depth == 0: s.part += 1
        s.depth += 1
    def end(s): s.depth -= 1
    def isl(s, name, w, h, mat, weight=1.0, minpx=(4, 4), bake=True, **kw):
        if name not in s.islands:
            s.islands[name] = dict(w=float(max(w, 1e-4)), h=float(max(h, 1e-4)), mat=mat, weight=weight, minpx=minpx, bake=bake, **kw)
        return name
    def grid(s, P, A, B, island, node='main', flip=False, canon=True):
        P = np.asarray(P, float); R, C = P.shape[:2]
        A = np.broadcast_to(np.asarray(A, float), (R, C)); B = np.broadcast_to(np.asarray(B, float), (R, C))
        if s.depth == 0: s.part += 1
        base = len(s.V)
        s.V.extend(P.reshape(-1, 3)); s.AB.extend(np.stack([A, B], -1).reshape(-1, 2)); s.ISL.extend([island]*(R*C))
        for r in range(R-1):
            for c in range(C-1):
                q = [base+r*C+c, base+r*C+c+1, base+(r+1)*C+c+1, base+(r+1)*C+c]
                s._quad(q, flip, node, canon)
    def _tri(s, t, node, canon):
        a, b, c = (np.asarray(s.V[i]) for i in t)
        if np.linalg.norm(np.cross(b-a, c-a)) < 1e-11: return
        s.F.append(list(t)); s.FN.append(node); s.FB.append(canon); s.FP.append(s.part)
    def _quad(s, q, flip, node, canon):
        # split along the shorter diagonal (better shading on curved grids)
        V = s.V
        d02 = np.linalg.norm(np.asarray(V[q[0]])-V[q[2]]); d13 = np.linalg.norm(np.asarray(V[q[1]])-V[q[3]])
        tris = ([q[0], q[1], q[2]], [q[0], q[2], q[3]]) if d02 <= d13*1.0001 else ([q[0], q[1], q[3]], [q[1], q[2], q[3]])
        for t in tris:
            s._tri(t[::-1] if flip else t, node, canon)
    def poly(s, pts, uvs, island, node='main', flip=False, canon=True):
        if s.depth == 0: s.part += 1
        base = len(s.V)
        for p, (a, b) in zip(pts, uvs):
            s.V.append(np.asarray(p, float)); s.AB.append((a, b)); s.ISL.append(island)
        for i in range(1, len(pts)-1):
            t = [base, base+i, base+i+1]
            s._tri(t[::-1] if flip else t, node, canon)
    def tris(s): return len(s.F)

# ---------------------------------------------------------------- primitives
def rrect_loop(hx, hz, r, ncs):
    """rounded rectangle (x,z) loop, CCW seen from +y, starting at (+hx, -hz+r) going towards +z. returns (pts, face_id per pt)
    ncs = corner segments (0 = sharp). face ids: 0 = +x, 1 = +z, 2 = -x, 3 = -z (corner middles split faces)."""
    r = max(min(r, hx*0.999, hz*0.999), 0.0)
    pts = []
    cs = [(hx-r, hz-r, 0), (-hx+r, hz-r, 90), (-hx+r, -hz+r, 180), (hx-r, -hz+r, 270)]
    for cx, cz, a0 in cs:
        n = max(ncs, 0)
        if n == 0:
            pts.append((cx + (r if a0 in (0, 270) else -r), cz + (r if a0 in (0, 90) else -r)))
            continue
        for i in range(n+1):
            a = math.radians(a0 + 90*i/n); pts.append((cx + r*math.cos(a), cz + r*math.sin(a)))
    return np.array(pts)

def bbox(m, c, size, name, mat, node='main', r=0.0, rb=0.0, ncs=None, npb=None, top=True, bottom=True, axes=None,
         weight=1.0, canon=True, share=None, wtop=None, wbot=0.35, bake=True, sides=(1, 1, 1, 1), **kw):
    """Bevelled box. c = centre, size = (sx, sy, sz) along axes (ex, ey, ez) (default X, Y, Z).
    r = vertical-edge radius, rb = top/bottom edge radius. ncs/npb = segment counts (default by LOD: hp 4, near 1, mid/far 0).
    Islands: name_x (+x side, shared with -x unless share=False), name_z (+z side), name_bz (-z side), name_top, name_bot.
    sides = (+x, +z, -x, -z) flags (0 = omit that side face)."""
    ex, ey, ez = (X, Y, Z) if axes is None else [nrm(a) for a in axes]
    if np.dot(np.cross(ex, ey), ez) < 0: ex = -ex   # left-handed frame -> keep faces outward (mirror x)
    c = np.asarray(c, float); sx, sy, sz = size; hx, hy, hz = sx/2, sy/2, sz/2
    if ncs is None: ncs = K(m.lod, 4, 1, 0, 0) if r > 0 else 0
    if npb is None: npb = K(m.lod, 4, 1, 0, 0) if rb > 0 else 0
    if ncs == 0: r = 0.0
    if npb == 0: rb = 0.0
    r = min(r, hx*0.95, hz*0.95); rb = min(rb, hy*0.45, hx*0.45, hz*0.45)
    # profile (d inset, y)
    prof = []
    if rb > 0 and bottom:
        for i in range(npb+1):
            t = -math.pi/2 + (math.pi/2)*i/npb
            prof.append((rb - rb*math.cos(t), -hy + rb + rb*math.sin(t)))
    else: prof.append((0.0, -hy))
    if rb > 0 and top:
        for i in range(npb+1):
            t = (math.pi/2)*i/npb
            prof.append((rb - rb*math.cos(t), hy - rb + rb*math.sin(t)))
    else: prof.append((0.0, hy))
    prof = np.array(prof)
    Lp = np.r_[0, np.cumsum(np.linalg.norm(np.diff(prof, axis=0), axis=1))]
    share = True if share is None else share
    nmx = name + '_x'; nmz = name + '_z'; nbz = name + '_bz'; nmx2 = nmx if share else name + '_nx'
    lens = {0: sz, 1: sx, 2: sz, 3: sx}
    isls = {0: nmx, 1: nmz, 2: nmx2, 3: nbz}
    for f, nmf in isls.items():
        m.isl(nmf, lens[f]+0.002, Lp[-1]+0.002, mat, weight=weight, bake=bake, **kw)
    m.begin()
    loops = [rrect_loop(hx-d, hz-d, max(r-d, 0.0), ncs) for d, _ in prof]
    npt = len(loops[0]); per_corner = (ncs+1) if (ncs > 0 and r > 0) else 1
    # face segments: start of face f at the middle of corner f-1 ... the loop goes corner0(+x+z)->corner1(-x+z)->...
    # corner k occupies indices [k*pc, (k+1)*pc). Side between corner k and k+1 = face (k+1) (k=0: +z face).
    def seg_pts(L, f):
        pc = per_corner
        k0 = (f - 1) % 4   # corner before face f
        idx0 = k0*pc + pc//2 if pc > 1 else k0*pc
        idx1 = ((k0+1) % 4)*pc + (pc//2 if pc > 1 else 0)
        mids_odd = pc > 1 and pc % 2 == 0   # even count of corner points -> mid between two points
        ids = []
        i = idx0
        while True:
            ids.append(i % npt)
            if i % npt == idx1 % npt and len(ids) > 1: break
            i += 1
        P = L[ids]
        if mids_odd:
            P = P.copy()
            a0 = L[(idx0-1) % npt]; a1 = L[idx1 % npt - 1 if idx1 % npt else npt-1]
            P[0] = (L[(idx0-1) % npt] + L[idx0 % npt])/2
            P[-1] = (L[(idx1-1) % npt] + L[idx1 % npt])/2
        return P
    for f in range(4):
        if not sides[f]: continue
        Ps = [seg_pts(L, f) for L in loops]
        S = np.array([[c + p[0]*ex + y*ey + p[1]*ez for p in P] for P, (_, y) in zip(Ps, prof)])
        # a: arclength along the outer loop for this face, centred so a=0 at the face's left edge
        P0 = Ps[int(np.argmax([np.ptp(P) for P in Ps]))]
        al = np.r_[0, np.cumsum(np.linalg.norm(np.diff(P0, axis=0), axis=1))]
        al = al/al[-1]*lens[f] if al[-1] > 0 else al
        A = np.broadcast_to(al[None, :], S.shape[:2]) + 0.001
        if f == 2 and share: A = lens[f] - A + 0.002   # mirror so +x and -x read the same way
        B = np.broadcast_to(Lp[:, None], S.shape[:2]) + 0.001
        cf = canon and not (f == 2 and share and sides[0])   # -x is canonical when +x is omitted
        m.grid(S, A, B, isls[f], node, flip=True, canon=cf)
    for is_top, use in ((True, top), (False, bottom)):
        if not use: continue
        L = loops[-1] if is_top else loops[0]
        y = prof[-1][1] if is_top else prof[0][1]
        nm = name + ('_top' if is_top else '_bot')
        mn = L.min(0)
        m.isl(nm, (L[:, 0].max()-mn[0])+0.002, (L[:, 1].max()-mn[1])+0.002, mat,
              weight=(wtop if wtop is not None else weight) if is_top else wbot*weight, bake=bake, **kw)
        pts = [c + p[0]*ex + y*ey + p[1]*ez for p in L]
        uvs = [(p[0]-mn[0]+0.001, (L[:, 1].max()-p[1]) + 0.001) for p in L]
        # loop is CCW seen from +y (x right, z down in the plane?) -> check winding with the normal
        # Newell normal of the whole loop (the first 3 points can coincide when r <= rb -> wrong winding, culled in Godot)
        nrm_ = np.zeros(3)
        for i in range(len(pts)): nrm_ += np.cross(pts[i]-c, pts[(i+1) % len(pts)]-c)
        want = ey if is_top else -ey
        fl = np.dot(nrm_, want) < 0
        if len(L) > 4 and not m.hp and False:
            pass
        m.poly(pts, uvs, nm, node, flip=fl, canon=canon)
    m.end()
    return name

def tube(m, P, r, sides, island, node='main', caps=(False, False), up=None, ellip=1.0, canon=True, a0=0.0, rot=0.0):
    """sweep circle along polyline P (r scalar or per point). UV a = around, b = along."""
    m.begin()
    P = np.asarray(P, float); n = len(P)
    r = np.atleast_1d(np.asarray(r, float))
    r = np.full(n, r[0]) if len(r) == 1 else (r if len(r) == n else np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(r)), r))
    T, N, Bn = frames(P, up)
    L = np.r_[0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
    circ = TAU*float(r.max())*(1+ellip)/2
    ang = np.linspace(0, TAU, sides+1) + rot
    G = P[:, None, :] + r[:, None, None]*(np.cos(ang)[None, :, None]*N[:, None, :] + ellip*np.sin(ang)[None, :, None]*Bn[:, None, :])
    A = (np.linspace(0, 1, sides+1)[None, :]*circ + a0)*np.ones((n, 1)) + 0.001
    B = L[:, None]*np.ones((1, sides+1)) + 0.001
    if island not in m.islands: raise KeyError(island)
    m.grid(G, A, B, island, node, canon=canon)
    for end, k, fl in ((caps[0], 0, False), (caps[1], n-1, True)):
        if not end or m.lod == 'far': continue
        ring = G[k][:-1]; cnt = P[k]
        mat = m.islands[island]['mat']
        ci = m.isl('cap_'+mat, 0.06, 0.06, mat, bake=False, weight=0.6)
        uv = [(0.03+0.028*math.cos(a), 0.03+0.028*math.sin(a)) for a in ang[:-1]]
        pts = list(ring)
        nn = np.cross(pts[1]-pts[0], pts[2]-pts[0]); want = -T[0] if k == 0 else T[-1]
        m.poly(pts, uv, ci, node, flip=np.dot(nn, want) < 0, canon=False)
    m.end()
    return G

def lathe(m, prof, center, ax, ref, segs, island, node='main', a_range=(0.0, TAU), repeats=1, canon=True, flip=False, Aref=None, cap_top=False, cap_bot=False, cap_isl=None):
    """revolve profile [(r, h)] (ordered bottom->top for outward normals) about ax through center. ref = angle-0 direction.
    UV a = arc at Aref (default max r), b = profile arclength. repeats: sectors overlap in UV (only sector 0 canonical)."""
    m.begin()
    prof = np.asarray(prof, float); ax = nrm(ax); ref = nrm(np.asarray(ref, float) - ax*np.dot(ref, ax)); oth = np.cross(ax, ref)
    Lp = np.r_[0, np.cumsum(np.linalg.norm(np.diff(prof, axis=0), axis=1))]
    rr = float(prof[:, 0].max()) if Aref is None else Aref
    span = a_range[1]-a_range[0]; per = max(segs//repeats, 1)
    for k in range(repeats):
        th = a_range[0] + span*(k*per + np.arange(per+1))/(per*repeats)
        G = center + prof[None, :, 0:1]*(np.cos(th)[:, None, None]*ref + np.sin(th)[:, None, None]*oth) + prof[None, :, 1:2]*ax
        A = ((th-th[0])*rr)[:, None]*np.ones((1, len(prof))) + 0.001
        B = Lp[None, :]*np.ones((len(th), 1)) + 0.001
        # winding: rows = angle (ccw about ax), cols = profile upward -> normal = d(theta) x d(prof)
        m.grid(G, A, B, island, node, flip=not flip, canon=(canon and k == 0))
    full = abs(span-TAU) < 1e-6
    for use, idx, up in ((cap_bot, 0, -1), (cap_top, -1, 1)):
        if not use or not full: continue
        rcap, hcap = prof[idx]
        if rcap < 1e-5: continue
        n = segs
        th = TAU*np.arange(n)/n
        pts = [center + rcap*(math.cos(t)*ref + math.sin(t)*oth) + hcap*ax for t in th]
        ci = cap_isl or island+'_cap'
        mat = m.islands[island]['mat']
        m.isl(ci, 2*rcap+0.002, 2*rcap+0.002, mat, bake=m.islands[island].get('bake', True), weight=m.islands[island]['weight'])
        uv = [(rcap+rcap*math.cos(t)+0.001, rcap+rcap*math.sin(t)+0.001) for t in th]
        nn = np.cross(pts[1]-pts[0], pts[2]-pts[0])
        m.poly(pts, uv, ci, node, flip=np.dot(nn, ax*up) < 0, canon=canon)
    m.end()
    return span*rr/repeats, Lp[-1]

def slab(m, G, t, top_isl, bot_isl, edge_isl, node='main', canon=True, Atop=None, Btop=None, up_hint=None, edges=True, bottom=True):
    """thin shell from a top-surface grid G (R,C,3): bottom = G - n*t (n = grid normal). edge strips join them.
    top UV: Atop/Btop (default arclength along cols/rows)."""
    G = np.asarray(G, float); R, C = G.shape[:2]
    dU = np.gradient(G, axis=1); dV = np.gradient(G, axis=0)
    n = nrm(np.cross(dV, dU))
    if up_hint is not None:
        if (n.reshape(-1, 3) @ np.asarray(up_hint)).mean() < 0: n = -n
    if Atop is None:
        Atop = np.r_[0, np.cumsum(np.linalg.norm(np.diff(G[R//2], axis=0), axis=1))][None, :]*np.ones((R, 1))
    if Btop is None:
        Btop = np.r_[0, np.cumsum(np.linalg.norm(np.diff(G[:, C//2], axis=0), axis=1))][:, None]*np.ones((1, C))
    Atop = Atop + 0.001; Btop = Btop + 0.001
    m.begin()
    Gb = G - n*t
    # top: normal must be +n. grid quad (r,c)->(r,c+1)->(r+1,c+1): normal = dU x dV
    fl_top = np.dot(np.cross(G[0, 1]-G[0, 0], G[1, 0]-G[0, 0]), n[0, 0]) < 0
    m.grid(G, Atop, Btop, top_isl, node, flip=fl_top, canon=canon)
    if bottom:
        m.grid(Gb, Atop, Btop, bot_isl, node, flip=not fl_top, canon=canon)
    if edges and m.lod != 'far':
        for rows in ((0, None), (R-1, None)):
            r_ = rows[0]
            E = np.stack([G[r_], Gb[r_]])
            Aa = np.r_[0, np.cumsum(np.linalg.norm(np.diff(G[r_], axis=0), axis=1))][None, :]*np.ones((2, 1)) + 0.001
            Bb = np.array([[0.001], [t+0.001]])*np.ones((1, C))
            # outward = away from the grid interior
            out = G[r_, C//2] - G[min(max(r_ + (1 if r_ == 0 else -1), 0), R-1), C//2]
            nn = np.cross(E[0, 1]-E[0, 0], E[1, 0]-E[0, 0])
            if C > 1: m.grid(E, Aa, Bb, edge_isl, node, flip=np.dot(nn, out) < 0, canon=False)
        for c_ in (0, C-1):
            E = np.stack([G[:, c_], Gb[:, c_]])
            Aa = np.r_[0, np.cumsum(np.linalg.norm(np.diff(G[:, c_], axis=0), axis=1))][None, :]*np.ones((2, 1)) + 0.001
            Bb = np.array([[0.001], [t+0.001]])*np.ones((1, R))
            out = G[R//2, c_] - G[R//2, min(max(c_ + (1 if c_ == 0 else -1), 0), C-1)]
            nn = np.cross(E[0, 1]-E[0, 0], E[1, 0]-E[0, 0])
            if R > 1: m.grid(E, Aa, Bb, edge_isl, node, flip=np.dot(nn, out) < 0, canon=False)
    m.end()

def quad(m, p0, p1, p2, p3, island, node='main', canon=True, ab=None):
    """single quad p0..p3 CCW seen from the front. ab = 4 uv pairs (default metric)."""
    if ab is None:
        w = np.linalg.norm(np.asarray(p1)-p0); h = np.linalg.norm(np.asarray(p3)-p0)
        ab = [(0.001, h+0.001), (w+0.001, h+0.001), (w+0.001, 0.001), (0.001, 0.001)]
    m.poly([np.asarray(p, float) for p in (p0, p1, p2, p3)], ab, island, node, canon=canon)

# ---------------------------------------------------------------- orientation fix (ray parity, per connected piece)
def orient(m, max_tests=9):
    V = np.asarray(m.V, float); F = np.asarray(m.F, int); FP = np.asarray(m.FP)
    flipped = 0
    for p in np.unique(FP):
        fi = np.where(FP == p)[0]
        T = V[F[fi]]
        e1 = T[:, 1]-T[:, 0]; e2 = T[:, 2]-T[:, 0]
        fnr = np.cross(e1, e2); ar = np.linalg.norm(fnr, axis=1); fn = fnr/np.maximum(ar[:, None], 1e-20)
        cen = T.mean(1)
        parent = {}
        def find(a):
            while parent.get(a, a) != a:
                parent[a] = parent.get(parent[a], parent[a]); a = parent[a]
            return a
        # connectivity through shared positions (grids of one part do not share vertex ids)
        key = {}
        for t in F[fi]:
            for v in t:
                kk = tuple(np.round(V[v], 5)); key.setdefault(kk, v)
        def kid(v): return key[tuple(np.round(V[v], 5))]
        for t in F[fi]:
            r0 = find(kid(t[0]))
            for v in t[1:]:
                rv = find(kid(v))
                if rv != r0: parent[rv] = r0
        comp = np.array([find(kid(t[0])) for t in F[fi]])
        for cc in np.unique(comp):
            ci = np.where(comp == cc)[0]
            sel = ci[np.argsort(-ar[ci])[:max_tests]]
            odd = 0; tot = 0
            for k in sel:
                o = cen[k] + fn[k]*1e-5; d = fn[k]
                pv = np.cross(d, e2); det = (e1*pv).sum(1)
                ok = np.abs(det) > 1e-14
                inv = np.where(ok, 1.0/np.where(ok, det, 1), 0)
                tv = o - T[:, 0]; u = (tv*pv).sum(1)*inv
                qv = np.cross(tv, e1); v = (qv*d).sum(1)*inv; t = (e2*qv).sum(1)*inv
                hit = ok & (u >= 0) & (v >= 0) & (u+v <= 1) & (t > 2e-5)
                hit[k] = False
                tot += 1; odd += int(hit.sum()) % 2
            if tot and odd*2 > tot:
                for k in ci:
                    f = m.F[fi[k]]; m.F[fi[k]] = [f[0], f[2], f[1]]
                flipped += len(ci)
    return flipped
