#!/bin/bash
# rooms: every open choose line erased (delete when unsure), then fix-room each; trees: the old builder trees' spots
# tested as hand-placed spots, to pick from
PY=${SC_PY:-/c/Users/yasin/AppData/Local/Programs/Python/Python312/python}
P=$1
for r in $($PY -I -c "import json,os; p='OUT/super/find/$P.rooms.json'; print(' '.join(json.load(open(p))['rooms']) if os.path.exists(p) else '')"); do
  $PY -I -c "
import json
p='OUT/super/find/$r.fixes.json'; fx=json.load(open(p)); n=0
for f in fx['fixes']:
    if f.get('mode')=='choose' and not f.get('chosen'):
        f['op']='remove'; f.pop('to',None); f['chosen']=True; f['reason']='erased: no plainly safe place (Yasin: delete when unsure) ['+f['reason']+']'; n+=1
json.dump(fx,open(p,'w'),indent=1)
"
  $PY -I tools/city/super/sc.py fix-room $r 2>&1 | grep -E "LEFT|PROOF RESULT|NOT DONE|nothing to carry" | sed "s/^/  $r: /" | cut -c1-150
done
$PY -I - <<PYEOF
import sys, json; sys.path.insert(0, 'tools/city/super')
import sc_trees as T, sc_lib as L, numpy as np
c = T.context('$P'); d = json.load(open('OUT/super/find/$P.faults.json'))
for f in d['faults']:
    if f['kind'] != 'tree_out': continue
    x, y, z = f['at']; g = c.S.ground(x, z)
    near = sorted([(round(float(L.quad_dist(it.quad, (x, z))), 1), it.base.replace('prop_', '')) for it in c.near((x, z), 6.0) if it.kind != 'tree' and L.quad_dist(it.quad, (x, z)) < 4])[:2]
    walls = min([L.quad_dist(b.quad, (x, z)) for b in c.blds if b.quad is not None] or [99])
    print('  old %-20s (%.1f, %.3f, %.1f) on %-8s wall %.1f m, near %s' % (f['item']['base'], x, g[0] if g else y, z, g[1] if g else '-', walls, near))
PYEOF
