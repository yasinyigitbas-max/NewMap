import json, sys
# usage: room_decide.py <room> "<n>:<erase|keep>:<why>" ...   (my decision for each open room line)
room = sys.argv[1]; p = 'OUT/super/find/%s.fixes.json' % room; fx = json.load(open(p)); d = {}
for a in sys.argv[2:]:
    n, act, why = a.split(':', 2); d[int(n)] = (act, why)
out = []
for f in fx['fixes']:
    if f['n'] in d:
        act, why = d[f['n']]
        if act == 'keep': fx.setdefault('kept', []).append(dict(f, reason='kept: ' + why)); continue
        f['op'] = 'remove'; f.pop('to', None); f['chosen'] = True; f['reason'] = 'erased: ' + why + ' [' + f['reason'] + ']'
    out.append(f)
fx['fixes'] = out; json.dump(fx, open(p, 'w'), indent=1); print('decided', room, len(d))
