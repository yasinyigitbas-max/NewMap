import json, math
import os
R=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../../../map_dc/coronado/city_kit/interiors/')
v=json.load(open(R+'builtin/validate_bays.json')); con=json.load(open(R+'room_contracts.json'))['models']
def budget(m):
    c=con[m]; w=c['footprint_wd'][0]; L=max(c['footprint_wd']); g=m.split('/')[0]; n=m.split('/')[1]
    if n.startswith('ck_brk3') or n.startswith('ck_grt_row') or n=='mod_brk_row': return 3500,'apartment block (3-storey row)'
    if g=='houses': return 2500,'large house'
    if g in ('civic','public') or 'courthouse' in n or 'hospital' in n: return 5000,'civic'
    if 'twr' in n: return 4000*max(1,math.ceil(c.get('storeys',1)/10)),'tower'
    if g=='apartments' or 'motel' in n or 'inn' in n: return (3500 if L<=30 else 5000),'apartment'
    if g=='industrial' or 'warehouse' in n: return 2000,'warehouse'
    if g=='urban': return 5000,'urban block'
    return max(2500, 1200*math.ceil(w/6)),'shop (1200 / 6 m, min 2500)'
rows=[]
for k,x in v.items():
    if k.endswith('|near'):
        m=k[:-5]; b,cat=budget(m); rows.append((m,x['ext_tris'],x['all_bays_tris'],b,cat))
over=[r for r in rows if r[2]>r[3]]
for r in sorted(rows,key=lambda r:r[2]-r[3],reverse=True)[:12]: print(r)
print(len(rows),'models; over budget',len(over), 'already over before interiors', sum(1 for r in rows if r[1]>r[3]))
pass
B=json.load(open(R+'builtin/bays.json'))
for r in rows:
    B['models'][r[0]]['near_budget']=r[3]; B['models'][r[0]]['budget_class']=r[4]; B['models'][r[0]]['ext_tris']=r[1]
    B['models'][r[0]]['lean']=bool(B['models'][r[0]].get('lean')) or r[2]>r[3]
import os; os.remove(R+'builtin/bays.json'); json.dump(B,open(R+'builtin/bays.json','w'),indent=1)
# the rollout status for docs/INDOORS.md (spec_md.py): counts, per-tier cost, overruns, skips
import statistics as S
st = json.load(open(R + 'builtin/make_interiors_stats.json'))
sh = [x['shell_tris'] for x in st.values()]
places = sum(len(bb['places']) for mm in B['models'].values() for bb in mm['bays'])
status = {
    'models': len(B['models']), 'bays': sum(len(mm['bays']) for mm in B['models'].values()), 'bay_places': places,
    'skipped': B.get('skipped', {}),
    'shell_tris_avg': round(S.mean(sh)), 'shell_tris_max': max(sh),
    'glass_tris_avg': round(S.mean([x['glass_tris'] for x in st.values()])),
    'lights_avg': round(S.mean([x['lights'] for x in st.values()]), 1),
    'lean': sorted(m for m, x in B['models'].items() if x.get('lean')), 'lean2': sorted(m for m, x in B['models'].items() if x.get('lean2')),
    'front_only': sorted(m for m, x in B['models'].items() if x.get('front_only')),
    'over': [dict(model=r[0], ext=r[1], with_interiors=r[2], budget=r[3], cls=r[4], over_before=r[1] > r[3]) for r in sorted(rows, key=lambda r: r[2] - r[3], reverse=True) if r[2] > r[3]],
}
p = R + 'builtin/rollout_status.json'
if os.path.exists(p): os.remove(p)
json.dump(status, open(p, 'w'), indent=1)
print('status', {k: v for k, v in status.items() if k not in ('lean', 'lean2', 'front_only', 'over')})
