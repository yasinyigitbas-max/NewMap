"""vfinish.py <work> <out> <name>: point veh_<name>.glb's two materials (body, glass) at its maps (relative URIs), add the
markers (seats, entry spots, lamps, exhaust) as nodes, write the vehicle's entry in manifest_vehicles.json.
Markers are authored in Blender space (Z up, front -Y) and turned into glTF (Y up, front +Z)."""
import sys, os, json, struct
W, OUT, N = sys.argv[1:4]
info = json.load(open(os.path.join(W, 'info.json')))
p = os.path.join(OUT, 'veh_%s.glb' % N)
d = open(p, 'rb').read(); jl = struct.unpack('<I', d[12:16])[0]
js = json.loads(d[20:20 + jl]); rest = d[20 + jl:]
REL = 'tex/'
js['images'] = [{'uri': REL + 'veh_%s_%s.png' % (N, k)} for k in ('color', 'normal', 'orm')]
js['samplers'] = [{'magFilter': 9729, 'minFilter': 9987, 'wrapS': 33071, 'wrapT': 33071}]
js['textures'] = [{'sampler': 0, 'source': i} for i in range(3)]
def mat(name, glass):
    m = {'name': name, 'pbrMetallicRoughness': {'baseColorTexture': {'index': 0}, 'metallicRoughnessTexture': {'index': 2},
         'metallicFactor': 1.0, 'roughnessFactor': 1.0}, 'normalTexture': {'index': 1}, 'occlusionTexture': {'index': 2}}
    if glass:
        m['alphaMode'] = 'BLEND'; m['doubleSided'] = True
    return m
names = [m['name'] for m in js['materials']]
js['materials'] = [mat(n, n.endswith('_glass')) for n in names]
g = lambda v: [round(v[0], 4), round(v[2], 4), round(-v[1], 4)]
mk = []
for k, v in info['markers'].items():
    js['nodes'].append({'name': 'mk_' + k, 'translation': g(v)}); mk.append(len(js['nodes']) - 1)
js['scenes'][0]['nodes'] = js['scenes'][0]['nodes'] + mk
j = json.dumps(js, separators=(',', ':')).encode(); j += b' ' * ((4 - len(j) % 4) % 4)
open(p, 'wb').write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(j) + len(rest)) + struct.pack('<II', len(j), 0x4E4F534A) + j + rest)
man_p = os.path.join(OUT, 'manifest_vehicles.json')
man = json.load(open(man_p)) if os.path.exists(man_p) else {}
info['pivots'] = {k: g(v) for k, v in info['pivots'].items()}
info['markers'] = {k: g(v) for k, v in info['markers'].items()}
info['axles'] = [round(-a, 4) for a in info['axles']]
info['frame'] = 'glTF / Godot: metres, Y up, front +Z, left +X, origin on the ground under the car'
man[N] = info
json.dump(dict(sorted(man.items())), open(man_p, 'w'), indent=1)
print('finished', N, len(mk), 'markers')
