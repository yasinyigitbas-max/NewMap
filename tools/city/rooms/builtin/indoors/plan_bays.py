"""Built-in interiors rollout: which bays of which kit models carry an interior, and which kinds each must furnish.
Reads interiors/builtin/indoors_spec.json (the INDOORS places), the assignment rows (piece, bay [s0, s1], door_along)
and room_contracts.json. Writes interiors/builtin/bays.json: {model: {"bays": [{s0, s1, door_along, door_w, kinds,
places}], "floor": box, "clear_h"}} and lists models skipped (no contract)."""
import json, glob, os, collections
REPO = '/workspace/NewMap'; R = REPO + '/map_dc/coronado/city_kit/interiors/'
spec = json.load(open(R + 'builtin/indoors_spec.json'))
con = json.load(open(R + 'room_contracts.json'))['models']
rows = {}
for f in sorted(glob.glob(R + 'assignment_*.json')):
    if 'samples' in f: continue
    j = json.load(open(f)); j = j if isinstance(j, list) else j.get('rooms', [])
    for r in j:
        if isinstance(r, dict) and r.get('id'): rows.setdefault(r['id'], r)
out = {}; skipped = collections.defaultdict(list); noroww = []
for p in spec['places']:
    m = p['model']; c = con.get(m); r = rows.get(p['id'])
    if not c: skipped[m].append(p['id']); continue
    if not r: noroww.append(p['id']); continue
    ents = [e for e in c['entrances'] if e.get('kind') != 'residential' and int(e.get('floor', 0)) == 0 and e['facade'] == 'front']
    da = float(r.get('door_along', 0.0))
    e = min(ents, key=lambda e: abs(float(e['along']) - da)) if ents else None
    if e is None or abs(float(e['along']) - da) > 0.3: skipped[m].append(p['id'] + ' (no front entrance at %.2f)' % da); continue
    f0 = c['floors'][0]
    bay = r.get('bay') or [f0['box_min'][0], f0['box_max'][0]]
    M = out.setdefault(m, dict(box_min=f0['box_min'], box_max=f0['box_max'], clear_h=f0['clear_h'], bays=[]))
    b = next((b for b in M['bays'] if abs(b['door_along'] - float(e['along'])) < 0.05), None)
    if b is None:
        s0 = max(float(bay[0]), f0['box_min'][0]); s1 = min(float(bay[1]), f0['box_max'][0])
        if s0 > f0['box_min'][0] + 0.35: s0 += 0.1      # a party wall: each side's shell 0.1 m off the midline
        if s1 < f0['box_max'][0] - 0.35: s1 -= 0.1
        b = dict(s0=round(s0, 3), s1=round(s1, 3), door_along=float(e['along']), door_w=float(e['w']), kinds=[], places=[])
        M['bays'].append(b)
    if p['dress'] not in b['kinds']: b['kinds'].append(p['dress'])
    b['places'].append(p['id'])
for M in out.values():
    M['bays'].sort(key=lambda b: b['door_along'])
    for i, b in enumerate(M['bays']): b['i'] = i
json.dump(dict(models=out, skipped=skipped, no_row=noroww), open(R + 'builtin/bays.json', 'w'), indent=1)
nb = sum(len(M['bays']) for M in out.values())
print('models', len(out), 'bays', nb, 'places', sum(len(b['places']) for M in out.values() for b in M['bays']), 'skipped', {k: len(v) for k, v in skipped.items()}, 'no row', noroww)
