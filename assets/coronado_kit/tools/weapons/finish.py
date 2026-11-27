"""finish.py <work> <out_dir> <manifest>: point each exported near glb at the shared page G (relative URIs, same layout
as the carry props on page J), add the grip / muzzle nodes as children of the mesh node, write manifest_weapons.json.
Grip and muzzle points are authored in Blender space (Z up, muzzle -Y) and converted to glTF (Y up, muzzle +Z)."""
import sys, os, json, struct
W, OUT, MAN = sys.argv[1:4]
info = json.load(open(os.path.join(W, 'build_info.json')))
info.pop('_build')
REL = '../../atlases/'
def rd(p):
    d = open(p, 'rb').read(); jl = struct.unpack('<I', d[12:16])[0]
    return json.loads(d[20:20 + jl]), d[20 + jl:]
def wr(p, js, rest):
    j = json.dumps(js, separators=(',', ':')).encode(); j += b' ' * ((4 - len(j) % 4) % 4)
    open(p, 'wb').write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(j) + len(rest)) + struct.pack('<II', len(j), 0x4E4F534A) + j + rest)
g = lambda v: [round(v[0], 4), round(v[2], 4), round(-v[1], 4)]
man = {}
for name, rec in info.items():
    p = os.path.join(OUT, rec['file_base'] + '_clean_near.glb')
    js, rest = rd(p)
    js['images'] = [{'uri': REL + 'props_g_color_clean.png'}, {'uri': REL + 'props_g_normal.png'}, {'uri': REL + 'props_g_orm.png'}]
    js['samplers'] = [{'magFilter': 9729, 'minFilter': 9987, 'wrapS': 33071, 'wrapT': 33071}]
    js['textures'] = [{'sampler': 0, 'source': i} for i in range(3)]
    js['materials'] = [{'name': 'props_g_atlas',
                        'pbrMetallicRoughness': {'baseColorTexture': {'index': 0, 'texCoord': 0}, 'metallicRoughnessTexture': {'index': 2},
                                                 'metallicFactor': 1.0, 'roughnessFactor': 1.0},
                        'normalTexture': {'index': 1}, 'occlusionTexture': {'index': 2}}]
    for m in js['meshes']:
        for pr in m['primitives']:
            pr['material'] = 0
            assert {'POSITION', 'NORMAL', 'TEXCOORD_0', 'TANGENT', 'COLOR_0'} <= set(pr['attributes']), pr['attributes']
    mn = [i for i, n in enumerate(js['nodes']) if 'mesh' in n]
    assert len(mn) == 1
    js['nodes'] = [n for n in js['nodes'] if 'mesh' in n]
    js['nodes'][0]['name'] = rec['file_base'] + '_near'
    js['nodes'][0].pop('children', None)
    pts = {k: g(v) for k, v in rec['grips'].items()}
    if rec.get('muzzle'):
        pts['muzzle'] = g(rec['muzzle'])
    kids = []
    for k, t in pts.items():
        js['nodes'].append({'name': k, 'translation': t}); kids.append(len(js['nodes']) - 1)
    js['nodes'][0]['children'] = kids
    js['scenes'][0]['nodes'] = [0]
    js.pop('extensionsUsed', None)
    wr(p, js, rest)
    rec['grips'] = {'space': 'glTF / Godot local, metres, Y up, muzzle / business end +Z, origin = grip_r',
                    'points': {k: v for k, v in pts.items() if k.startswith('grip')}, 'hold': rec.pop('hold')}
    rec['muzzle'] = pts.get('muzzle')
    man[name] = rec
    print('finished', name, pts)
json.dump(man, open(MAN, 'w'), indent=1)
print('manifest', MAN, len(man))
