"""Superchecker, shared reading code (19 Nov 2026). Reads only: the dumps written by sc_dump.gd, the layout, the
land, the kit's own lists (prop manifests, building stats, measured openings). Nothing here writes into the map.

Frames: a dump is in its scene's OWN frame. A layout row places a scene by a turn about the vertical (yaw, degrees)
and a position. `Inst` carries both and turns local numbers into city numbers (x = u, z = v, y up) and back.
A transform is 12 numbers: the basis' three columns (x, y, z), then the origin - as Godot stores it.
"""
import hashlib, json, math, os, subprocess, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '../../..'))
CK = os.path.join(REPO, 'map_dc/coronado/city_kit')
PIECES = os.path.join(CK, 'pieces')
ROOMS = os.path.join(CK, 'interiors/rooms')
KIT = os.path.join(REPO, 'assets/coronado_kit')
LAYOUT = os.path.join(CK, 'city_grid_layout.json')
LAND = os.path.join(CK, 'zoning/terrain_grid.npz')
OUT = os.path.join(REPO, 'OUT/super')
DUMP = os.path.join(OUT, 'dump')
RDUMP = os.path.join(OUT, 'dump_rooms')
MODELS = os.path.join(OUT, 'models')
DUMP_V = 3           # the read-out's format: an older read-out is read again
GODOT = os.environ.get('SC_GODOT', 'C:/Users/yasin/Godot_v4.7.2-stable_win64.exe')

HARD = ('asphalt', 'white', 'yellow')            # where vehicles go
PAVED = ('concrete', 'paving', 'plaza', 'tactile', 'curb')
SOFT = ('grass', 'mulch', 'gravel', 'sand')


def fwd(p):
    return p.replace('\\', '/')


def sha_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''): h.update(b)
    return h.hexdigest()


def godot(script, args, timeout=900, quiet=True):
    """run a Godot script of this folder with the real renderer; returns its printed lines"""
    cmd = [GODOT, '--path', REPO, '--rendering-method', 'mobile', '--resolution', '320x180', '-s', 'res://tools/city/super/' + script, '--'] + list(args)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, errors='replace')
        out = (r.stdout or '') + (r.stderr or '')
    except subprocess.TimeoutExpired as e:
        out = ((e.stdout or b'').decode(errors='replace') if isinstance(e.stdout, bytes) else (e.stdout or '')) + '\nSC-TIMEOUT'
    lines = [l for l in out.splitlines() if l.strip()]
    if not quiet:
        for l in lines: print('   | ' + l)
    return lines


def ensure_dumps(names, folder=PIECES, out=DUMP, chunk=40, say=True):
    """dump every named scene whose dump is missing or older than its file (by sha256)"""
    os.makedirs(out, exist_ok=True); os.makedirs(MODELS, exist_ok=True)
    stale = []
    for n in names:
        src = os.path.join(folder, n + '.scn'); dj = os.path.join(out, n + '.json')
        if not os.path.exists(src): continue
        ok = False
        if os.path.exists(dj) and os.path.exists(dj[:-5] + '.bin'):
            try:
                jj = json.load(open(dj, encoding='utf-8')); ok = jj.get('sha256') == sha_file(src) and jj.get('v') == DUMP_V
            except Exception: ok = False
        if not ok: stale.append(n)
    res_dir = 'res://' + fwd(os.path.relpath(folder, REPO)) + '/'
    for i in range(0, len(stale), chunk):
        part = stale[i:i + chunk]
        if say: print('  reading %d scenes (%d of %d)' % (len(part), min(i + chunk, len(stale)), len(stale)), flush=True)
        lines = godot('sc_dump.gd', ['--out=' + fwd(out), '--models=' + fwd(MODELS), '--dir=' + res_dir, '--names=' + ','.join(part)])
        if not any(l.startswith('SC-DUMP done') for l in lines):
            print('  !! the read of this part did not finish:', [l for l in lines if 'ERROR' in l or 'SC-' in l][-3:])
    return stale


# ---------------------------------------------------------------- transforms
def yaw_mat(deg):
    a = math.radians(deg); c = math.cos(a); s = math.sin(a)
    return np.array([[c, 0.0, s], [0.0, 1.0, 0.0], [-s, 0.0, c]])


class Inst:
    """one layout row: a scene placed in the city"""
    def __init__(self, row_id, piece, pos=(0, 0, 0), yaw=0.0, frm=''):
        self.id = row_id; self.piece = piece; self.pos = np.array(pos, float); self.yaw = float(yaw); self.frm = frm
        self.R = yaw_mat(self.yaw)

    def pts(self, p):                      # local points [.., 3] -> city
        return np.asarray(p, float) @ self.R.T + self.pos

    def pts_inv(self, p):
        return (np.asarray(p, float) - self.pos) @ self.R

    def xf(self, t):                       # local transforms [n, 12] -> city
        t = np.asarray(t, float).reshape(-1, 12); o = np.empty_like(t)
        for k in range(3): o[:, 3 * k:3 * k + 3] = t[:, 3 * k:3 * k + 3] @ self.R.T
        o[:, 9:12] = t[:, 9:12] @ self.R.T + self.pos
        return o


def xf_apply(t, p):
    """transform(s) [n, 12] applied to points [m, 3] -> [n, m, 3]"""
    t = np.asarray(t, float).reshape(-1, 12); p = np.asarray(p, float).reshape(-1, 3)
    B = t[:, :9].reshape(-1, 3, 3)                      # rows are the columns
    return np.einsum('mk,nkj->nmj', p, B) + t[:, None, 9:12]


# ---------------------------------------------------------------- the kit's own lists
class Kit:
    _man = None; _stats = {}; _open = None; _models = {}
    MANIFESTS = ["props/manifest_city.json", "props/manifest_construction.json", "props/manifest_fences.json", "props/manifest_house.json", "props/manifest_park.json", "props/manifest_street.json", "props/manifest_yard.json", "props/manifest_wfquay.json", "props/manifest_wfpier.json", "props/manifest_wfgang.json", "props/manifest_wfmarina.json", "props/manifest_b2a.json", "props/manifest_b2b.json", "props/manifest_wfboats.json", "props/manifest_wfprom.json", "props/manifest_wfsmall.json", "props/manifest_inshared.json", "props/manifest_infood.json", "props/manifest_ingrocery.json", "props/manifest_inclothing.json", "props/manifest_insalon.json", "props/manifest_ingift.json", "props/manifest_inoffice.json", "props/manifest_inservices.json", "props/manifest_insport.json", "props/manifest_invenue.json", "foliage/manifest_foliage.json"]

    @classmethod
    def man(cls, base):
        if cls._man is None:
            cls._man = {}
            for f in cls.MANIFESTS:
                p = os.path.join(KIT, f)
                if not os.path.exists(p): continue
                v = json.load(open(p, encoding='utf-8'))
                for e in (v if isinstance(v, list) else v.values()): cls._man[str(e['file_base'])] = e
        return cls._man.get(base, {})

    @classmethod
    def stats(cls, folder):
        if folder not in cls._stats:
            if folder.startswith('ck/'): d = os.path.join(CK, 'buildings', folder[3:])
            elif folder.startswith('modular/'): d = os.path.join(KIT, folder)
            else: d = os.path.join(KIT, 'buildings', folder)
            p = os.path.join(d, 'stats.json')
            cls._stats[folder] = json.load(open(p, encoding='utf-8')) if folder and os.path.exists(p) else {}
        return cls._stats[folder]

    @classmethod
    def openings(cls, folder):
        """measured doors and windows of a building model (interiors/room_contracts*.json), or None"""
        if cls._open is None:
            cls._open = {}
            d = os.path.join(CK, 'interiors')
            for f in sorted(os.listdir(d)):
                if f.startswith('room_contracts') and f.endswith('.json'):
                    try: cls._open.update(json.load(open(os.path.join(d, f), encoding='utf-8')).get('models', {}))
                    except Exception: pass
        return cls._open.get(folder)

    _cols = {}
    @classmethod
    def model_col(cls, key):
        """a building model's own collision: triangles [n, 3, 3] in the model's frame, or None if never read out"""
        if key not in cls._cols:
            pj = os.path.join(MODELS, key + '.col.json')
            cls._cols[key] = np.fromfile(pj[:-5] + '.bin', '<f4').reshape(-1, 3, 3).astype(np.float64) if os.path.exists(pj) else None
        return cls._cols[key]

    @classmethod
    def model(cls, key):
        """a building model's near mesh: triangles [n, 3, 3] in the model's frame (from sc_dump.gd), or None"""
        if key not in cls._models:
            pj = os.path.join(MODELS, key + '.json')
            if not os.path.exists(pj): cls._models[key] = None
            else:
                cls._models[key] = np.fromfile(pj[:-5] + '.bin', '<f4').reshape(-1, 3, 3).astype(np.float64)
        return cls._models[key]


# ---------------------------------------------------------------- a dumped scene
class Dump:
    def __init__(self, name, folder=DUMP, path=None):
        pj = path or os.path.join(folder, name + '.json')
        self.j = json.load(open(pj, encoding='utf-8')); self.name = name
        self.f = np.fromfile(pj[:-5] + '.bin', '<f4')
        self.meta = self.j.get('meta', {})

    def ground(self):
        """[(surface name, triangles [n, 3, 3])] of every 'ground' mesh"""
        out = []
        for g in self.j['ground']:
            for s in g['surf']:
                if s['tris']: out.append((s['name'], self.f[s['off']:s['off'] + s['tris'] * 9].reshape(-1, 3, 3).astype(np.float64)))
        return out

    def decals(self):
        """[(wear node path, surface, verts [n, 9] = xyz uv rgba)]"""
        return [(w['path'], w['surface'], self.f[w['off']:w['off'] + w['verts'] * 9].reshape(-1, 9).astype(np.float64)) for w in self.j['wear']]

    def batches(self):
        for b in self.j['props']:
            yield b, self.f[b['off']:b['off'] + b['count'] * 12].reshape(-1, 12).astype(np.float64)

    def cols(self):
        c = self.j.get('cols') or {}
        if not c.get('count'): return np.zeros((0, 12)), []
        return self.f[c['off']:c['off'] + c['count'] * 12].reshape(-1, 12).astype(np.float64), c['group']

    def shell(self):
        for m in self.j['meshes']:
            if m.get('name') == 'shell' and m.get('dumped'):
                return self.f[m['off']:m['off'] + m['dumped'] * 9].reshape(-1, 3, 3).astype(np.float64)
        return np.zeros((0, 3, 3))

    def wires(self):
        """every triangle of a wire piece's meshes [n, 3, 3] (pieces named w_*)"""
        out = [self.f[m['off']:m['off'] + m['dumped'] * 9].reshape(-1, 3, 3).astype(np.float64) for m in self.j['meshes'] if m.get('dumped') and m.get('name') != 'shell']
        return np.concatenate(out) if out else np.zeros((0, 3, 3))

    def bbox(self):
        """xz box of the ground (or of the props where there is no ground), in the scene's frame"""
        lo = np.array([np.inf, np.inf]); hi = -lo
        for _, T in self.ground():
            P = T.reshape(-1, 3)[:, [0, 2]]; lo = np.minimum(lo, P.min(0)); hi = np.maximum(hi, P.max(0))
        if not np.isfinite(lo).all():
            for _, X in self.batches():
                if len(X): lo = np.minimum(lo, X[:, [9, 11]].min(0)); hi = np.maximum(hi, X[:, [9, 11]].max(0))
        if not np.isfinite(lo).all():
            W = self.wires()
            if len(W): P = W.reshape(-1, 3)[:, [0, 2]]; lo = P.min(0); hi = P.max(0)
        return lo, hi


OVERHEAD = ('prop_utility_pole', 'prop_lot_light', 'prop_billboard', 'prop_lamp_cobra', 'prop_lamp_', 'prop_traffic_signal', 'prop_mast', 'prop_shade_sail', 'prop_street_sign', 'prop_sign_', 'prop_flagpole', 'prop_water_tower', 'prop_bus_stop_sign')


class Item:
    """one placed prop (its near-tier instance), in city numbers"""
    __slots__ = ('inst', 'bpath', 'idx', 'base', 'cond', 'T', 'pos', 'yaw', 'scale', 'quad', 'y0', 'y1', 'mount', 'man', 'local', 'half', 'ctr', 'kind', 'lifted', 'n')

    def front(self):                      # unit vector the prop faces (its +Z), in the plan
        return np.array([math.sin(self.yaw), math.cos(self.yaw)])

    def along(self):                      # its +X in the plan
        return np.array([math.cos(self.yaw), -math.sin(self.yaw)])


def kind_of(base):
    b = base
    if b.startswith('tree_') or b.startswith('palm_'): return 'tree'
    if b.startswith('fence_'):
        if '_post' in b: return 'post'
        if '_gate' in b: return 'gate'
        return 'fence'
    if b.startswith('hedge_'): return 'hedge'
    if b.startswith('plant_') or b.startswith('shrub_') or b.startswith('bush_') or b.startswith('flower'): return 'plant'
    if any(b.startswith(o) for o in OVERHEAD): return 'post_overhead'
    return 'prop'


def items_of(dump, inst, tier='near'):
    """every prop of a dumped scene as an Item (near tier; rooms have one tier with an empty name)"""
    out = []
    tiers = set(b['tier'] for b in dump.j['props'])
    want = tier if tier in tiers else ''
    for b, X in dump.batches():
        if b['tier'] != want or not len(X): continue
        man = Kit.man(b['base'])
        ab = np.array(b['aabb'], float); lo = ab[:3]; hi = ab[:3] + ab[3:]
        kd = kind_of(b['base'])
        if kd == 'tree': lo = np.array([-0.3, lo[1], -0.3]); hi = np.array([0.3, hi[1], 0.3])
        elif kd == 'post_overhead': lo = np.array([-0.22, lo[1], -0.22]); hi = np.array([0.22, hi[1], 0.22])
        cs = np.array([[lo[0], lo[1], lo[2]], [hi[0], lo[1], lo[2]], [hi[0], lo[1], hi[2]], [lo[0], lo[1], hi[2]],
                       [lo[0], hi[1], lo[2]], [hi[0], hi[1], lo[2]], [hi[0], hi[1], hi[2]], [lo[0], hi[1], hi[2]]])
        Xw = inst.xf(X)
        W = xf_apply(Xw, cs)                                   # [n, 8, 3]
        for i in range(len(X)):
            it = Item(); it.inst = inst; it.bpath = b['path']; it.idx = i; it.base = b['base']; it.cond = b['cond']; it.T = Xw[i]; it.local = X[i]
            it.pos = Xw[i, 9:12].copy(); it.yaw = math.atan2(Xw[i, 6], Xw[i, 8]); it.scale = float(np.linalg.norm(Xw[i, 0:3]))
            it.quad = W[i, :4][:, [0, 2]].copy(); it.y0 = float(W[i, :, 1].min()); it.y1 = float(W[i, :, 1].max())
            it.ctr = it.quad.mean(0); it.half = np.array([(hi[0] - lo[0]) * 0.5 * it.scale, (hi[2] - lo[2]) * 0.5 * it.scale])
            it.man = man; it.mount = str(man.get('mount', 'ground')); it.kind = kd; it.lifted = False; it.n = len(out)
            out.append(it)
    return out


# ---------------------------------------------------------------- surfaces to stand on
class Surf:
    """Up-facing triangles (piece ground, and the buildings' own floors, steps and decks) in a 4 m grid."""
    CELL = 4.0

    def __init__(self):
        self.T = []; self.mat = []; self.own = []; self.kind = []; self._built = False

    def add(self, tris, mat, own, kind='ground'):
        if not len(tris): return
        n = np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0]); ln = np.linalg.norm(n, axis=1)
        ok = (ln > 1e-7) & (np.abs(n[:, 1]) >= 0.5 * np.maximum(ln, 1e-12))
        t = tris[ok]
        if not len(t): return
        self.T.append(t); self.mat += [mat] * len(t); self.own += [own] * len(t); self.kind += [kind] * len(t)

    def build(self):
        self.T = np.concatenate(self.T) if len(self.T) else np.zeros((0, 3, 3))
        self.mat = np.array(self.mat, dtype=object); self.own = np.array(self.own, dtype=np.int64); self.kind = np.array(self.kind, dtype=object)
        T = self.T; self.grid = {}
        lo = np.floor(T[:, :, [0, 2]].min(1) / self.CELL).astype(int); hi = np.floor(T[:, :, [0, 2]].max(1) / self.CELL).astype(int)
        for k in range(len(T)):
            for cx in range(lo[k, 0], hi[k, 0] + 1):
                for cz in range(lo[k, 1], hi[k, 1] + 1):
                    self.grid.setdefault((cx, cz), []).append(k)
        self.grid = {k: np.array(v) for k, v in self.grid.items()}
        a = T[:, 0]; b = T[:, 1]; c = T[:, 2]
        self.den = (b[:, 2] - c[:, 2]) * (a[:, 0] - c[:, 0]) + (c[:, 0] - b[:, 0]) * (a[:, 2] - c[:, 2])
        self._built = True
        return self

    def hits(self, x, z):
        """every surface over the point: (heights, triangle numbers)"""
        idx = self.grid.get((int(math.floor(x / self.CELL)), int(math.floor(z / self.CELL))))
        if idx is None: return np.zeros(0), np.zeros(0, int)
        T = self.T[idx]; a = T[:, 0]; b = T[:, 1]; c = T[:, 2]; d = self.den[idx]
        ok = np.abs(d) > 1e-12; d = np.where(ok, d, 1.0)
        w0 = ((b[:, 2] - c[:, 2]) * (x - c[:, 0]) + (c[:, 0] - b[:, 0]) * (z - c[:, 2])) / d
        w1 = ((c[:, 2] - a[:, 2]) * (x - c[:, 0]) + (a[:, 0] - c[:, 0]) * (z - c[:, 2])) / d
        w2 = 1.0 - w0 - w1
        m = ok & (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
        return (w0 * a[:, 1] + w1 * b[:, 1] + w2 * c[:, 1])[m], idx[m]

    def top(self, x, z, own=None, kinds=None, below=None):
        """the highest surface over the point: (height, material, owner, kind) or None"""
        ys, ix = self.hits(x, z)
        best = None
        for y, k in zip(ys, ix):
            if own is not None and self.own[k] != own: continue
            if kinds is not None and self.kind[k] not in kinds: continue
            if below is not None and y > below: continue
            if best is None or y > best[0]: best = (float(y), self.mat[k], int(self.own[k]), self.kind[k])
        return best

    def ground(self, x, z, own=None):
        return self.top(x, z, own=own, kinds=('ground',))


class Land:
    def __init__(self, path=LAND):
        t = np.load(path); self.H = t['heights'].astype(np.float64); self.u0 = float(t['u0']); self.v0 = float(t['v0']); self.s = float(t['step'])
        self.sea = t['sea'] if 'sea' in t.files else None

    def at(self, x, z):
        ny, nx = self.H.shape
        fx = (np.asarray(x, float) - self.u0) / self.s; fz = (np.asarray(z, float) - self.v0) / self.s
        i = np.clip(np.floor(fx).astype(int), 0, nx - 2); j = np.clip(np.floor(fz).astype(int), 0, ny - 2); a = fx - i; b = fz - j
        H = self.H
        return (H[j, i] * (1 - a) + H[j, i + 1] * a) * (1 - b) + (H[j + 1, i] * (1 - a) + H[j + 1, i + 1] * a) * b


# ---------------------------------------------------------------- plan geometry
def quad_hit(qa, qb, shrink=1.0):
    """two convex quads [4, 2] overlap (separating axes); shrink < 1 pulls both in toward their centres first"""
    if shrink != 1.0:
        ca = qa.mean(0); cb = qb.mean(0); qa = ca + (qa - ca) * shrink; qb = cb + (qb - cb) * shrink
    for q in (qa, qb):
        for k in range(4):
            e = q[(k + 1) % 4] - q[k]; ax = np.array([-e[1], e[0]]); ln = np.hypot(ax[0], ax[1])
            if ln < 1e-9: continue
            ax = ax / ln
            pa = qa @ ax; pb = qb @ ax
            if pa.max() < pb.min() + 1e-9 or pb.max() < pa.min() + 1e-9: return False
    return True


def in_quad(q, p):
    s = 0
    for k in range(4):
        e = q[(k + 1) % 4] - q[k]; r = np.asarray(p) - q[k]; c = e[0] * r[1] - e[1] * r[0]
        if abs(c) < 1e-12: continue
        if s == 0: s = 1 if c > 0 else -1
        elif (c > 0) != (s > 0): return False
    return True


def rect_quad(c, half, yaw):
    """corners [4, 2] of a rectangle: centre c (x, z), half sizes along its own x / z, turned by yaw (as Godot's)"""
    ax = np.array([math.cos(yaw), -math.sin(yaw)]); az = np.array([math.sin(yaw), math.cos(yaw)])
    c = np.asarray(c, float)
    return np.array([c - ax * half[0] - az * half[1], c + ax * half[0] - az * half[1], c + ax * half[0] + az * half[1], c - ax * half[0] + az * half[1]])


def seg_dist(p, a, b):
    p = np.asarray(p, float); a = np.asarray(a, float); b = np.asarray(b, float)
    d = b - a; l2 = float(d @ d)
    t = 0.0 if l2 < 1e-12 else max(0.0, min(1.0, float((p - a) @ d) / l2))
    return float(np.linalg.norm(p - (a + d * t)))


def quad_dist(q, p):
    """distance from a point to a convex quad (0 inside)"""
    if in_quad(q, p): return 0.0
    return min(seg_dist(p, q[k], q[(k + 1) % 4]) for k in range(4))


def load_layout(path=LAYOUT):
    rows = json.load(open(path, encoding='utf-8'))['instances']
    return [Inst(i, str(r['piece']), r.get('pos', [0, 0, 0]), r.get('yaw', 0), str(r.get('from', ''))) for i, r in enumerate(rows)]
