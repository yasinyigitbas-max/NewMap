import json, sys, numpy as np
# which of my moves landed where the copy shows a new fault
P = sys.argv[1]
fx = json.load(open('OUT/super/work/%s.applied.json' % P))['fixes']; pos = np.array(json.load(open('OUT/super/find/%s.faults.json' % P))['pos'])
yaw = json.load(open('OUT/super/find/%s.faults.json' % P)).get('yaw', 0.0)
a = json.load(open('OUT/super/work/find/%s.faults.json' % P)); b = json.load(open('OUT/super/find/%s.faults.json' % P))
key = lambda f: (f['kind'], (f.get('item') or {}).get('base', ''), round(f['at'][0], 1), round(f['at'][2], 1))
old = {}
for f in b['faults']: old[key(f)] = old.get(key(f), 0) + 1
c = np.cos(np.radians(yaw)); s = np.sin(np.radians(yaw))
for f in a['faults']:
    k = key(f)
    if old.get(k, 0) > 0: old[k] -= 1; continue
    d = np.array(f['at']) - pos; loc = np.array([c * d[0] - s * d[2], d[1], s * d[0] + c * d[2]])
    near = [(int(x['n']), x['base'].replace('prop_', '')) for x in fx if x['op'] == 'move' and np.linalg.norm(np.array(x['to'])[[0, 2]] - loc[[0, 2]]) < 1.3]
    print(f['kind'], (f.get('item') or {}).get('base', '').replace('prop_', ''), [round(v, 1) for v in f['at']], '-> my lines:', near)
