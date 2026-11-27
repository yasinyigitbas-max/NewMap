"""vcheck.py [names...]: validate the vehicles (python3 + numpy + PIL). Exit 1 on any FAIL.
Per veh_<name>.glb: triangles within the class budget; every mesh node uses at most the two materials veh_<name> and
veh_<name>_glass; POSITION NORMAL TEXCOORD_0 TANGENT present; the three map URIs resolve and have the right sizes;
required parts present (body, >= 4 wheels, steering_wheel, interior, at least one door); a door's / lid's node origin
(its hinge) sits on the edge of its own mesh; markers seat_fl and entry_l present; no degenerate triangles; UVs in 0..1
and no texel used twice across the vehicle (the page is shared by all its parts)."""
import json, os, struct, sys
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
D = os.path.join(ROOT, 'vehicles')
man = json.load(open(os.path.join(D, 'manifest_vehicles.json')))
names = sys.argv[1:] or list(man)
BUDGET = {'compact': 4300, 'saloon': 4300, 'sports': 4300, 'suv': 4300, 'pickup': 4500, 'service': 4500, 'emergency': 4800,
          'van': 4500, 'truck': 5000, 'bus': 6000}
CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}
fails = []


def ok(c, m):
    if not c:
        fails.append(m)


def rd(p):
    d = open(p, 'rb').read(); jl = struct.unpack('<I', d[12:16])[0]
    js = json.loads(d[20:20 + jl]); off = 20 + jl; bl = struct.unpack('<I', d[off:off + 4])[0]
    return js, d[off + 8:off + 8 + bl]


def acc(js, b, i):
    a = js['accessors'][i]; bv = js['bufferViews'][a['bufferView']]
    o = bv.get('byteOffset', 0) + a.get('byteOffset', 0); n = NC[a['type']]
    arr = np.frombuffer(b, dtype=CT[a['componentType']], count=a['count'] * n, offset=o)
    return arr.reshape(a['count'], n) if n > 1 else arr


rows = []
for name in names:
    rec = man[name]
    p = os.path.join(D, 'veh_%s.glb' % name)
    js, b = rd(p)
    for im, sz in zip(js['images'], (1024, 512, 512)):
        f = os.path.normpath(os.path.join(D, im['uri']))
        ok(os.path.exists(f), name + ': missing ' + im['uri'])
        if os.path.exists(f):
            ok(Image.open(f).size == (sz, sz), name + ': %s size %s' % (im['uri'], Image.open(f).size))
    mats = [m['name'] for m in js['materials']]
    ok(set(mats) <= {'veh_' + name, 'veh_' + name + '_glass'}, name + ': materials %s' % mats)
    nodes = {n.get('name'): n for n in js['nodes']}
    parts = [n for n in js['nodes'] if 'mesh' in n]
    pn = [n['name'] for n in parts]
    ok('body' in pn and 'interior' in pn and 'steering_wheel' in pn, name + ': body / interior / steering_wheel missing')
    ok(sum(1 for n in pn if n.startswith('wheel_')) >= 4, name + ': fewer than 4 wheels')
    ok(any(n.startswith(('door', 'busdoor')) for n in pn), name + ': no door')
    ok('mk_seat_fl' in nodes and 'mk_entry_l' in nodes, name + ': seat / entry markers missing')
    total = 0
    UVR = 2048
    cover = np.zeros((UVR, UVR), np.int16)
    for n in parts:
        mesh = js['meshes'][n['mesh']]
        t = np.array(n.get('translation', [0, 0, 0]))
        lo = np.full(3, 1e9); hi = np.full(3, -1e9)
        for pr in mesh['primitives']:
            ok({'POSITION', 'NORMAL', 'TEXCOORD_0', 'TANGENT'} <= set(pr['attributes']), name + '/' + n['name'] + ': attributes')
            P = acc(js, b, pr['attributes']['POSITION']).astype(np.float64)
            UV = acc(js, b, pr['attributes']['TEXCOORD_0']).astype(np.float64)
            I = acc(js, b, pr['indices']).astype(np.int64).reshape(-1, 3)
            total += len(I)
            lo = np.minimum(lo, P.min(0)); hi = np.maximum(hi, P.max(0))
            a, bb, c = P[I[:, 0]], P[I[:, 1]], P[I[:, 2]]
            ar = np.linalg.norm(np.cross(bb - a, c - a), axis=1) / 2
            ok((ar > 1e-10).all(), name + '/' + n['name'] + ': %d degenerate triangles' % (ar <= 1e-10).sum())
            ok(UV.min() >= -1e-4 and UV.max() <= 1 + 1e-4, name + '/' + n['name'] + ': UVs outside 0..1')
            for tri in I:
                pts = [(UV[k, 0] * UVR, UV[k, 1] * UVR) for k in tri]
                xs = [q[0] for q in pts]; ys = [q[1] for q in pts]
                x0, y0 = int(max(min(xs) - 1, 0)), int(max(min(ys) - 1, 0))
                x1, y1 = int(min(max(xs) + 2, UVR)), int(min(max(ys) + 2, UVR))
                if x1 <= x0 or y1 <= y0:
                    continue
                sub = Image.new('L', (x1 - x0, y1 - y0), 0)
                ImageDraw.Draw(sub).polygon([(x - x0, y - y0) for x, y in pts], fill=1)
                s = np.asarray(sub, np.int16)
                s = s & np.roll(s, 1, 0) & np.roll(s, -1, 0) & np.roll(s, 1, 1) & np.roll(s, -1, 1)
                cover[y0:y1, x0:x1] += s
        nm = n['name']
        if nm.startswith(('door', 'busdoor', 'back_door')) or nm in ('bonnet', 'boot', 'tailgate'):
            # the hinge (node origin) must lie on the part's own bounding box edge: local 0 near a face of the box
            d = np.minimum(np.abs(lo), np.abs(hi))
            ok((d < 0.06).sum() >= 2, name + '/' + nm + ': hinge not on an edge (local box %s .. %s)' % (lo.round(3), hi.round(3)))
    ov = int((cover > 1).sum())
    ok(ov < 50, name + ': UV overlap %d texels' % ov)
    ok(total == rec['tris'], name + ': tris %d vs manifest %d' % (total, rec['tris']))
    ok(total <= BUDGET.get(rec['cls'], 4500), name + ': %d tris over budget %d' % (total, BUDGET.get(rec['cls'], 4500)))
    rows.append((name, rec['cls'], total, BUDGET.get(rec['cls'], 4500), len(parts), ' x '.join('%.2f' % v for v in rec['size']), 100 * (cover > 0).mean(), os.path.getsize(p)))
print('%-15s %-10s %5s %6s %5s %-18s %6s %8s' % ('vehicle', 'class', 'tris', 'budget', 'parts', 'size w x l x h', 'fill%', 'bytes'))
for r in rows:
    print('%-15s %-10s %5d %6d %5d %-18s %6.1f %8d' % r)
for f in fails:
    print('FAIL', f)
print('RESULT', 'PASS' if not fails else 'FAIL (%d)' % len(fails))
sys.exit(1 if fails else 0)
