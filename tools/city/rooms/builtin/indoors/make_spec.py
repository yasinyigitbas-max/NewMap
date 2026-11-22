import os as _os
def _w(p):      # (hard links into other trees: delete, then write)
    if _os.path.exists(p): _os.remove(p)
    return open(p, 'w')

import os
import csv, json, glob, os, collections, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
REPO = '/workspace/NewMap'; P = REPO + '/assets/coronado_kit/props/'
from kinds import SHOPS as K, DRESS, X, MISSING, DRESS_X
K = dict(K); K.update(X); DRESS = dict(DRESS); DRESS.update(DRESS_X)
inv = {}
for m in glob.glob(P + 'manifest_*.json'):
    for k, v in json.load(open(m)).items(): inv[k] = (os.path.basename(m)[9:-5], int(v.get('tiers', {}).get('near', v.get('budget', 0))), v.get('class'))
for k in ['vending_snack', 'vending_soda', 'ice_chest']: inv.setdefault(k, ('streetside', 900, 'medium'))
base = lambda x: x.split(' ')[0]
plan = [r for r in csv.DictReader(open('/workspace/share/shops_trim/shops_plan.csv')) if r['decision'] == 'KEEP']
spp = {r['room_id']: r for r in csv.DictReader(open('/workspace/share/shops_trim/shop_props_plan.csv'))}
aud = list(csv.DictReader(open('/workspace/share/shop_interiors/rollout_rooms_audit.csv')))
con = json.load(open(REPO + '/map_dc/coronado/city_kit/interiors/room_contracts.json'))['models']
assign = {}
for f in glob.glob(REPO + '/map_dc/coronado/city_kit/interiors/assignment_*.json'):
    if 'samples' in f: continue
    j = json.load(open(f)); j = j if isinstance(j, list) else j.get('rooms', [])
    for r in j:
        if isinstance(r, dict): assign.setdefault(r.get('id'), (os.path.basename(f), r))
kept_kinds = {r['kind'] for r in plan}
rep = {}
for f in glob.glob(REPO + '/map_dc/coronado/city_kit/interiors/rooms_*_report.json'):
    d = json.load(open(f)); it = d if isinstance(d, list) else d.get('rooms', list(d.values()))
    for x in it:
        if isinstance(x, dict) and x.get('w'):
            i = re.sub(r'^g_(strip_)?', '', x['id']); rep[i] = (round(x['w'], 1), round(x['d'], 1), x.get('props'))
STRAND_SWAP = []
places = []
def dims(model, along=None, rid=None):
    if rid in rep: return rep[rid][0], rep[rid][1], 'room report'
    c = con.get(model)
    if not c: return None, None, 'no contract'
    es = [e for e in c.get('entrances', []) if e.get('bay_w')]
    if along is not None and es: es.sort(key=lambda e: abs(float(e['along']) - float(along)))
    elif es: es.sort(key=lambda e: -e['bay_w'] * e['bay_d'])
    if es: return round(es[0]['bay_w'], 1), round(es[0]['bay_d'], 1), 'contract bay'
    f = c['floors'][0]['inner_wd']; return round(f[0], 1), round(f[1], 1), 'contract floor'
for r in plan:
    s = spp.get(r['room_id'], {})
    w, d = (float(s['room_w_m']), float(s['room_d_m'])) if s.get('room_w_m') else dims(r['building_model'], None, r['room_id'])[:2]
    places.append(dict(id=r['room_id'], name=r['name'], kind=r['kind'], dress=s.get('dress_as') or DRESS.get(r['name'], r['kind']), group='shop (kept, NEW-18 plan)',
        district=r['district'], piece=r['piece'], model=r['building_model'], w=w, d=d, has_row=r['room_id'] in assign))
for r in aud:
    if r['rollout'].startswith('YES') or (r['rollout'].startswith('DECIDE') and r['kind'] not in kept_kinds):
        a = assign.get(r['id'], (None, {}))[1]
        w, d, _ = dims(r['model'], a.get('door_along'), r['id'])
        places.append(dict(id=r['id'], name=r['name'], kind=r['kind'], dress=DRESS.get(r['name'], r['kind']),
            group='non-shop indoor place' if r['rollout'].startswith('YES') else 'Strand/Adela shop kept (one of a kind)',
            district='Strand / Adela' if r['id'].startswith('m_gr') else '', piece=r['piece'], model=r['model'], w=w, d=d, has_row=True))
    elif r['rollout'].startswith('DECIDE'):
        STRAND_SWAP.append(dict(id=r['id'], name=r['name'], kind=r['kind'], model=r['model'], piece=r['piece']))
for p in places:
    p['old_props'] = rep.get(p['id'], (0, 0, None))[2]; p['area'] = round((p['w'] or 0) * (p['d'] or 0)); p['size'] = 'S' if p['area'] < 70 else 'M' if p['area'] < 160 else 'L' if p['area'] < 320 else 'XL'
# kinds
used = collections.Counter(p['dress'] for p in places)
missing_by = collections.defaultdict(set); unknown = set()
kinds = {}
PROP_CAP = 25000
for k in sorted(used):
    if k not in K: unknown.add(k); continue
    core, stock, decor, miss, note = K[k]
    allp = [base(x) for x in core + stock + decor] + [base(x) for x in miss]
    miss_now = sorted({x for x in allp if x not in inv})
    for x in miss_now: missing_by[x].add(k)
    tri = lambda x: inv[x][1] if x in inv else MISSING.get(x, ('', 800))[1]
    ps = [p for p in places if p['dress'] == k]
    est = []
    for p in ps:
        n_stock = max(3, min(24, int(p['area'] / 8)))
        st = [base(x) for x in stock] or ['wall_shelf']
        t = sum(tri(base(x)) for x in core) + sum(tri(st[i % len(st)]) for i in range(n_stock)) + sum(tri(base(x)) for x in decor[:4])
        p['prop_tris_est'] = t; p['prop_tris_capped'] = min(t, PROP_CAP); est.append(t)
    kinds[k] = dict(places=len(ps), core=core, stock=stock, decor=decor, missing=miss_now, built_since_new21=sorted({base(x) for x in miss if base(x) in inv}),
        note=note, prop_tris_max=max(est), over_cap=sum(1 for t in est if t > PROP_CAP))
undocumented = sorted(x for x in missing_by if x not in MISSING)
if undocumented: print('UNDOCUMENTED MISSING PROPS', undocumented); sys.exit(1)
out = dict(generated='22 Nov 2026', places=places, kinds=kinds, missing={x: dict(zip(['class', 'near_tris', 'size_m', 'stand_in', 'kinds'], MISSING.get(x, ('?', 0, '?', '?', '')))) | {'used_by': sorted(missing_by[x])} for x in sorted(missing_by)},
    strand_swap=STRAND_SWAP, unknown_kinds=sorted(unknown), undocumented_missing=undocumented)
json.dump(out, _w(REPO + '/map_dc/coronado/city_kit/interiors/builtin/indoors_spec.json'), indent=1)
import spec_md
if os.path.exists(REPO + '/docs/INDOORS.md'): os.remove(REPO + '/docs/INDOORS.md')      # (hard links into other trees: never written through)
_w(REPO + '/docs/INDOORS.md').write(spec_md.md(out, inv))
grp = collections.Counter(p['group'] for p in places)
print(len(places), dict(grp), 'kinds', len(kinds), 'unknown', unknown, 'undocumented', undocumented)
print('no row', [p['id'] for p in places if not p['has_row']])
print('missing', len(missing_by), {x: sorted(v) for x, v in missing_by.items()})
print('over cap', {k: (v['prop_tris_max'], v['over_cap']) for k, v in kinds.items() if v['over_cap']})
print('nodims', [p['id'] for p in places if not p['w']])
