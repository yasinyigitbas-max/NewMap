"""check.py: validate the weapons batch (plain python3 + numpy + PIL). Exit 1 on any FAIL.
Per near glb: triangles within the class budget, one mesh / one primitive / one material (props_g_atlas), POSITION NORMAL
TEXCOORD_0 TANGENT COLOR_0 present, the three page G URIs resolve, grip_r at the origin, grip / muzzle nodes present as the
manifest says, UVs inside 0..1, no two triangles sharing texels (overlap), no degenerate triangles, the mesh encloses
positive volume (faces outward). Per col glb: one mesh named col, POSITION only. Page sizes 1024 / 512 / 256."""
import json, os, struct, sys
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
D = os.path.join(ROOT, 'props', 'weapons')
man = json.load(open(os.path.join(ROOT, 'props', 'manifest_weapons.json')))
CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}
fails = []


def rd(p):
    d = open(p, 'rb').read()
    jl = struct.unpack('<I', d[12:16])[0]
    js = json.loads(d[20:20 + jl])
    off = 20 + jl
    bl = struct.unpack('<I', d[off:off + 4])[0]
    return js, d[off + 8:off + 8 + bl]


def acc(js, bin_, i):
    a = js['accessors'][i]
    bv = js['bufferViews'][a['bufferView']]
    o = bv.get('byteOffset', 0) + a.get('byteOffset', 0)
    n = NC[a['type']]
    arr = np.frombuffer(bin_, dtype=CT[a['componentType']], count=a['count'] * n, offset=o)
    if a.get('normalized'):
        arr = arr.astype(np.float32) / np.iinfo(CT[a['componentType']]).max
    return arr.reshape(a['count'], n) if n > 1 else arr


def ok(cond, msg):
    if not cond:
        fails.append(msg)
    return cond


for sz, f in ((1024, 'props_g_color_clean.png'), (512, 'props_g_normal.png'), (256, 'props_g_orm.png')):
    im = Image.open(os.path.join(ROOT, 'atlases', f))
    ok(im.size == (sz, sz), '%s is %s, want %d' % (f, im.size, sz))
UVR = 2048
cover = np.zeros((UVR, UVR), np.int32)
rows = []
for name, rec in man.items():
    p = os.path.join(D, rec['file_base'] + '_clean_near.glb')
    js, b = rd(p)
    ok(len(js['meshes']) == 1 and len(js['meshes'][0]['primitives']) == 1, name + ': one mesh, one primitive')
    pr = js['meshes'][0]['primitives'][0]
    ok(set(pr['attributes']) >= {'POSITION', 'NORMAL', 'TEXCOORD_0', 'TANGENT', 'COLOR_0'}, name + ': attributes %s' % list(pr['attributes']))
    ok(len(js['materials']) == 1 and js['materials'][0]['name'] == 'props_g_atlas', name + ': one material props_g_atlas')
    for im in js['images']:
        ok(os.path.exists(os.path.normpath(os.path.join(D, im['uri']))), name + ': missing ' + im['uri'])
    P = acc(js, b, pr['attributes']['POSITION']).astype(np.float64)
    UV = acc(js, b, pr['attributes']['TEXCOORD_0']).astype(np.float64)
    I = acc(js, b, pr['indices']).astype(np.int64).reshape(-1, 3)
    nt = len(I)
    ok(nt == rec['tiers']['near'], name + ': tris %d vs manifest %d' % (nt, rec['tiers']['near']))
    ok(nt <= rec['budget'], name + ': %d tris over budget %d' % (nt, rec['budget']))
    a, bb, c = P[I[:, 0]], P[I[:, 1]], P[I[:, 2]]
    area = np.linalg.norm(np.cross(bb - a, c - a), axis=1) / 2
    ok((area > 1e-9).all(), name + ': %d degenerate triangles' % (area <= 1e-9).sum())
    vol = np.einsum('ij,ij->i', a, np.cross(bb, c)).sum() / 6
    ok(vol > 0, name + ': signed volume %.3g (faces inward?)' % vol)
    ok(UV.min() >= -1e-4 and UV.max() <= 1 + 1e-4, name + ': UVs outside 0..1')
    # overlap: rasterise each triangle into a counter (glTF v down)
    # overlap: rasterise each triangle (shrunk by a texel) into one counter for the whole page
    for t in I:
        pts = [(UV[k, 0] * UVR, UV[k, 1] * UVR) for k in t]
        xs = [q[0] for q in pts]; ys = [q[1] for q in pts]
        x0, y0 = int(max(min(xs) - 1, 0)), int(max(min(ys) - 1, 0))
        x1, y1 = int(min(max(xs) + 2, UVR)), int(min(max(ys) + 2, UVR))
        if x1 <= x0 or y1 <= y0:
            continue
        sub = Image.new('L', (x1 - x0, y1 - y0), 0)
        ImageDraw.Draw(sub).polygon([(x - x0, y - y0) for x, y in pts], fill=1)
        s = np.asarray(sub, np.int32)
        # shrink by one pixel so shared edges do not count as overlap
        s = s & np.roll(s, 1, 0) & np.roll(s, -1, 0) & np.roll(s, 1, 1) & np.roll(s, -1, 1)
        cover[y0:y1, x0:x1] += s
    names = [n.get('name') for n in js['nodes']]
    ok(js['nodes'][0].get('translation') is None, name + ': mesh node must sit at the origin')
    for g in rec['grips']['points']:
        ok(g in names, name + ': grip node %s missing' % g)
    ok(rec['grips']['points'].get('grip_r') == [0, 0, 0], name + ': grip_r is not the origin')
    if rec.get('muzzle'):
        ok('muzzle' in names, name + ': muzzle node missing')
    cj, cb = rd(os.path.join(D, rec['file_base'] + '_col.glb'))
    ok([n.get('name') for n in cj['nodes']] == ['col'] and list(cj['meshes'][0]['primitives'][0]['attributes']) == ['POSITION'], name + ': col glb')
    rows.append((name, nt, rec['budget'], rec['length'], rec['px_per_m_colour'], os.path.getsize(p)))
ov = (cover > 1).sum()
ok(ov == 0, 'UV overlap: %d texels (of %d) covered twice' % (ov, UVR * UVR))
print('%-15s %6s %6s %8s %8s %8s' % ('weapon', 'tris', 'budget', 'length', 'px/m', 'bytes'))
for r in rows:
    print('%-15s %6d %6d %8.3f %8.0f %8d' % r)
print('page fill %.1f %%, overlap texels %d' % (100 * (cover > 0).mean(), ov))
for f in fails:
    print('FAIL', f)
print('RESULT', 'PASS' if not fails else 'FAIL (%d)' % len(fails))
sys.exit(1 if fails else 0)
