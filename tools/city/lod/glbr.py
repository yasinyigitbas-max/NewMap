"""Small software renderer for the kit's building GLBs (near / mid / far), for LOD-match audits and bakes.
No GPU, no Blender: numpy z-buffer rasteriser, orthographic, nearest texel. Shading is close to the bake's rt_bldg
(albedo * vertex colour, sun + sky) so tiers can be compared pixel for pixel at the real switch distances."""
import json, os, struct, numpy as np, pygltflib
from PIL import Image
_TEX = {}
def tex(path, rgba=False):
    k = (path, rgba)
    if k not in _TEX:
        im = Image.open(path).convert('RGBA' if rgba else 'RGB'); _TEX[k] = np.asarray(im, dtype=np.float32) / 255.0
    return _TEX[k]
_MIPS = {}
def mips(path, rgba=False):
    """box-filtered mip chain of a texture (filtered bakes: no moire from nearest sampling of 256 px/m atlases)"""
    k = (path, rgba)
    if k not in _MIPS:
        a = tex(path, rgba); out = [a]
        while min(a.shape[:2]) > 8:
            h, w = a.shape[0] // 2 * 2, a.shape[1] // 2 * 2
            a = a[:h, :w].reshape(h // 2, 2, w // 2, 2, -1).mean((1, 3)); out.append(a)
        _MIPS[k] = out
    return _MIPS[k]
def srgb2lin(c): return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
def lin2srgb(c): c = np.clip(c, 0, 1); return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)

def _acc(g, blob, i):
    a = g.accessors[i]; bv = g.bufferViews[a.bufferView]
    n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[a.type]
    dt = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8, 5122: np.int16}[a.componentType]
    off = (bv.byteOffset or 0) + (a.byteOffset or 0)
    itemsize = np.dtype(dt).itemsize * n
    stride = bv.byteStride or itemsize
    raw = np.frombuffer(blob, dtype=np.uint8, count=stride * (a.count - 1) + itemsize, offset=off)
    if stride == itemsize: arr = raw.view(dt).reshape(a.count, n)
    else: arr = np.stack([raw[k * stride:k * stride + itemsize].view(dt) for k in range(a.count)])
    arr = arr.astype(np.float32)
    if a.normalized:
        arr = arr / float(np.iinfo(dt).max)
    return arr if n > 1 else arr[:, 0]

def _node_mat(nd):
    if nd.matrix: return np.array(nd.matrix, dtype=np.float64).reshape(4, 4).T
    M = np.eye(4)
    if nd.scale: M = np.diag(list(nd.scale) + [1]) @ M
    if nd.rotation:
        x, y, z, w = nd.rotation
        R = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)], [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)], [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
        R4 = np.eye(4); R4[:3, :3] = R; M = R4 @ M
    if nd.translation: T = np.eye(4); T[:3, 3] = nd.translation; M = T @ M
    return M

def load(path):
    """-> dict(P (n,3), N, UV, C (n,4), I (m,3), tex: albedo image path, orm path or None)"""
    g = pygltflib.GLTF2().load(path); blob = g.binary_blob()
    base = os.path.dirname(path)
    P, N, UV, C, I = [], [], [], [], []; nv = 0; albedo = None; orm = None
    def walk(ni, M):
        nonlocal nv, albedo, orm
        nd = g.nodes[ni]; M = M @ _node_mat(nd)
        if nd.mesh is not None:
            for pr in g.meshes[nd.mesh].primitives:
                p = _acc(g, blob, pr.attributes.POSITION); n = len(p)
                ph = np.c_[p, np.ones(n)] @ M.T; P.append(ph[:, :3])
                nn = _acc(g, blob, pr.attributes.NORMAL) if pr.attributes.NORMAL is not None else np.zeros((n, 3))
                N.append(nn @ np.linalg.inv(M[:3, :3]))
                UV.append(_acc(g, blob, pr.attributes.TEXCOORD_0) if pr.attributes.TEXCOORD_0 is not None else np.zeros((n, 2)))
                c = _acc(g, blob, pr.attributes.COLOR_0) if pr.attributes.COLOR_0 is not None else np.ones((n, 4))
                if c.shape[1] == 3: c = np.c_[c, np.ones(n)]
                C.append(c)
                idx = _acc(g, blob, pr.indices).astype(np.int64).reshape(-1, 3) if pr.indices is not None else np.arange(n).reshape(-1, 3)
                I.append(idx + nv); nv += n
                if pr.material is not None and albedo is None:
                    m = g.materials[pr.material]
                    def img(ti):
                        return os.path.normpath(os.path.join(base, g.images[g.textures[ti].source].uri))
                    if m.pbrMetallicRoughness and m.pbrMetallicRoughness.baseColorTexture: albedo = img(m.pbrMetallicRoughness.baseColorTexture.index)
                    if m.pbrMetallicRoughness and m.pbrMetallicRoughness.metallicRoughnessTexture: orm = img(m.pbrMetallicRoughness.metallicRoughnessTexture.index)
        for c in nd.children or []: walk(c, M)
    sc = g.scenes[g.scene or 0]
    for ni in sc.nodes: walk(ni, np.eye(4))
    if not P: return None
    return dict(P=np.concatenate(P), N=np.concatenate(N), UV=np.concatenate(UV), C=np.concatenate(C), I=np.concatenate(I), albedo=albedo, orm=orm)

SUN = np.array([0.45, 0.75, 0.48]); SUN /= np.linalg.norm(SUN)
def view_basis(az_deg, el_deg):
    """camera looks FROM direction (az around +Y from +Z toward +X, elevation)"""
    a, e = np.radians(az_deg), np.radians(el_deg)
    fwd = -np.array([np.sin(a) * np.cos(e), np.sin(e), np.cos(a) * np.cos(e)])      # view direction
    right = np.cross(fwd, [0, 1, 0]); right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    return right, up, fwd

def render(m, az, el, ppm, bounds=None, glass_reflect=True, orm=None):
    """orthographic render from (az, el); ppm = pixels per metre. returns (rgb srgb HxWx3, alpha HxW, bounds)
    bounds = (u0,u1,v0,v1) in view-plane metres (so tiers share the frame)."""
    R, U, F = view_basis(az, el)
    rgb, a, g, bounds = render_basis(m, R, U, F, ppm, bounds, mode='lit', glass_reflect=glass_reflect, orm=orm)
    return rgb, a, bounds

def render_basis(m, R, U, F, ppm, bounds=None, zwin=None, mode='lit', glass_reflect=True, orm=None, cull=True):
    """R, U = image right / up (unit), F = view direction. zwin = (zmin, zmax) along F: only surface points inside
    are drawn (a slab). mode 'lit' (sun + sky, as rt_bldg) or 'albedo' (texture * vertex colour, sRGB, no light).
    returns (rgb sRGB, coverage, glass 0..1 from the ORM, bounds)"""
    P = m['P']; u = P @ R; v = P @ U; z = P @ F
    if bounds is None: bounds = (u.min() - 1, u.max() + 1, v.min() - 1, v.max() + 1)
    u0, u1, v0, v1 = bounds
    W = max(1, int(np.ceil((u1 - u0) * ppm - 1e-6))); H = max(1, int(np.ceil((v1 - v0) * ppm - 1e-6)))
    X = (u - u0) * ppm; Y = (v1 - v) * ppm
    zb = np.full((H, W), np.inf, np.float32); col = np.zeros((H, W, 3), np.float32); gls = np.zeros((H, W), np.float32)
    ga = m.get('glass_alpha', False)
    A = tex(m['albedo'], ga) if m['albedo'] else None
    ormp = orm or m['orm']; O = tex(ormp) if ormp else None
    TH, TW = (A.shape[0], A.shape[1]) if A is not None else (1, 1)
    I = m['I']; UV = m['UV']; C = m['C']
    p0, p1, p2 = P[I[:, 0]], P[I[:, 1]], P[I[:, 2]]
    fn = np.cross(p1 - p0, p2 - p0); ln = np.linalg.norm(fn, axis=1); ok = ln > 1e-9
    fn[ok] /= ln[ok][:, None]
    sel = ok & (((fn @ F) < 0) if cull else True)
    # cheap pre-cull: triangles off the frame or outside the slab
    xs3 = X[I]; ys3 = Y[I]; zs3 = z[I]
    sel &= (xs3.max(1) >= 0) & (xs3.min(1) <= W) & (ys3.max(1) >= 0) & (ys3.min(1) <= H)
    if zwin is not None: sel &= (zs3.max(1) >= zwin[0]) & (zs3.min(1) <= zwin[1])
    for t in np.nonzero(sel)[0]:
        i0, i1, i2 = I[t]
        xs = xs3[t]; ys = ys3[t]
        bx0 = max(int(np.floor(xs.min())), 0); bx1 = min(int(np.ceil(xs.max())), W - 1)
        by0 = max(int(np.floor(ys.min())), 0); by1 = min(int(np.ceil(ys.max())), H - 1)
        if bx1 < bx0 or by1 < by0: continue
        gx, gy = np.meshgrid(np.arange(bx0, bx1 + 1) + 0.5, np.arange(by0, by1 + 1) + 0.5)
        d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(d) < 1e-12: continue
        w0 = ((ys[1] - ys[2]) * (gx - xs[2]) + (xs[2] - xs[1]) * (gy - ys[2])) / d
        w1 = ((ys[2] - ys[0]) * (gx - xs[2]) + (xs[0] - xs[2]) * (gy - ys[2])) / d
        w2 = 1 - w0 - w1
        ins = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
        if not ins.any(): continue
        zz = w0 * z[i0] + w1 * z[i1] + w2 * z[i2]
        if zwin is not None: ins &= (zz >= zwin[0]) & (zz <= zwin[1])
        sub = zb[by0:by1 + 1, bx0:bx1 + 1]
        win = ins & (zz < sub - 1e-4)
        if not win.any(): continue
        uu = w0 * UV[i0, 0] + w1 * UV[i1, 0] + w2 * UV[i2, 0]
        vv = w0 * UV[i0, 1] + w1 * UV[i1, 1] + w2 * UV[i2, 1]
        cc = (w0[..., None] * C[i0, :3] + w1[..., None] * C[i1, :3] + w2[..., None] * C[i2, :3])
        lod = 0
        if mode == 'albedo':
            duv = np.cross(np.r_[UV[i1] - UV[i0], 0], np.r_[UV[i2] - UV[i0], 0])[2] * TW * TH
            dpx = abs(d)
            if dpx > 1e-9 and abs(duv) > 1e-12: lod = int(np.clip(np.floor(0.5 * np.log2(abs(duv) / dpx) + 0.5), 0, 8))
        if A is not None:
            Am = mips(m['albedo'], ga)[min(lod, len(mips(m['albedo'], ga)) - 1)] if lod else A
            th, tw = Am.shape[:2]
            tx = (np.mod(uu, 1.0) * tw).astype(np.int32).clip(0, tw - 1); ty = (np.mod(vv, 1.0) * th).astype(np.int32).clip(0, th - 1)
            ax = Am[ty, tx]; alb = srgb2lin(ax[..., :3])
        else: alb = np.full(gx.shape + (3,), 0.8)
        n = fn[t]
        gl = np.zeros(gx.shape, np.float32)
        if O is not None:
            if lod:
                ol = max(0, lod - int(round(np.log2(TW / O.shape[1])))); Om = mips(ormp)[min(ol, len(mips(ormp)) - 1)]
            else: Om = O
            O_ = Om
            oy = (np.mod(vv, 1.0) * O_.shape[0]).astype(np.int32).clip(0, O_.shape[0] - 1); ox = (np.mod(uu, 1.0) * O_.shape[1]).astype(np.int32).clip(0, O_.shape[1] - 1)
            o = O_[oy, ox]; gl = (1 - np.clip((o[..., 1] - 0.1) / 0.12, 0, 1)) * (1 - np.clip((o[..., 2] - 0.1) / 0.2, 0, 1)) * (1 - abs(n[1]))
        if ga and A is not None: gl = (1 - ax[..., 3]) * (1 - abs(n[1]))
        if mode == 'albedo':
            shade = alb * cc
        else:
            lam = max(0.0, float(n @ SUN)); sky = 0.55 + 0.25 * n[1]
            shade = alb * cc * (lam * 0.9 + sky * 0.45)
            if glass_reflect and (O is not None or ga):
                shade = shade * (1 - 0.35 * gl[..., None]) + gl[..., None] * 0.35 * np.array([0.55, 0.65, 0.8])
        sub[win] = zz[win]
        col[by0:by1 + 1, bx0:bx1 + 1][win] = shade[win]
        gls[by0:by1 + 1, bx0:bx1 + 1][win] = gl[win]
    alpha = np.isfinite(zb).astype(np.float32)
    return lin2srgb(col), alpha, gls, bounds

def compose(rgb, alpha, bg=(0.78, 0.84, 0.9)):
    return rgb * alpha[..., None] + np.array(bg) * (1 - alpha[..., None])

def to_img(a): return Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8))
def down(a, f):
    """box-filter downsample by float factor via PIL"""
    im = to_img(a) if a.ndim == 3 else Image.fromarray((a * 255).astype(np.uint8))
    w, h = im.size; im = im.resize((max(1, round(w / f)), max(1, round(h / f))), Image.BOX)
    return np.asarray(im, dtype=np.float32) / 255.0

def load_dump(jpath, root='/workspace/NewMap'):
    """a mesh dumped by dump_mesh.gd (.json + .bin)"""
    meta = json.load(open(jpath)); raw = open(jpath[:-5] + '.bin', 'rb').read(); off = 0
    P, N, UV, C, I = [], [], [], [], []; nv = 0; albedo = orm = None
    X = np.array(meta['xf']).reshape(4, 3); B = X[:3].T; o = X[3]
    for s in meta['surfaces']:
        f = np.frombuffer(raw, np.float32, s['nv'] * 12, off).reshape(-1, 12); off += s['nv'] * 48
        ix = np.frombuffer(raw, np.int32, s['ni'], off).reshape(-1, 3); off += s['ni'] * 4
        P.append(f[:, :3] @ B.T + o); N.append(f[:, 3:6] @ B.T); UV.append(f[:, 6:8]); C.append(f[:, 8:12]); I.append(ix + nv); nv += s['nv']
        if albedo is None and s['albedo']: albedo = s['albedo'].replace('res://', root + '/')
        if orm is None and s.get('orm'): orm = s['orm'].replace('res://', root + '/')
    # Godot winding is clockwise for front faces: flip to the CCW convention render() expects
    I = [i[:, ::-1] for i in I]
    return dict(P=np.concatenate(P).astype(np.float64), N=np.concatenate(N), UV=np.concatenate(UV).astype(np.float64), C=np.concatenate(C).astype(np.float64), I=np.concatenate(I).astype(np.int64), albedo=albedo, orm=orm)

def load_any(p):
    return load_dump(p) if p.endswith('.json') else load(p)
