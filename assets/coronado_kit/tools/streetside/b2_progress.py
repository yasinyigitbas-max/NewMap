"""rebuild the piece table + page-W usage in PROGRESS.md from the manifests and reports/*.json"""
import json,glob,os,re,datetime,numpy as np
B='/workspace/coronado_kit_v2/_staging/props_batch2'; K='/workspace/coronado_kit_v2/_staging/waterfront/kit'
man={}
for f in glob.glob(K+'/props/manifest_b2*.json'): man.update(json.load(open(f)))
GROUP={'signage':['pylon_sign','drive_thru_menu','bus_stop_sign'],'motel':['vending_soda','vending_snack','ice_chest'],
       'parking':['wheel_stop_concrete','wheel_stop_rubber','shopping_cart','cart_corral'],'residential':['balcony_clutter','dingbat_stair','buzzer_panel','clothesline']}
S=json.load(open(K+'/props/_bake/slots_w.json'))['slots']
rows=[]; tot=0
for g,ns in GROUP.items():
    for n in ns:
        r=json.load(open(f'{B}/reports/{n}.json')) if os.path.exists(f'{B}/reports/{n}.json') else {}
        m=man.get(n,{}); t=r.get('tiers',m.get('tiers',{}))
        sl=S.get(n,[]); px=sum(w*h for _,_,w,h in sl); tot+=px
        fm=r.get('far_match',{}); fs=' / '.join(f"{v} {fm[v]['iou']:.2f} ΔE{fm[v]['dE']:.0f}" for v in ('front','top') if v in fm)
        rc=r.get('rail_ok'); rcs='—' if rc is None else ('PASS' if rc else 'FAIL')
        if rc is not None:
            try: rcs+=f" ({len(eval(r['railcheck']))} ends)"
            except Exception: pass
        cs=r.get('col_split',{}); col=f"{cs.get('main',0)}+{cs.get('rail',0)} rail" if cs else '—'
        slot=f"{sl[0][2]}² @({sl[0][0]},{sl[0][1]}) {m.get('bake_px_per_m','?')} px/m" if sl else '—'
        trims=', '.join(sorted(m.get('trim',{}).keys()))
        rows.append(f"| {g} | {n} | {r.get('class',m.get('class'))} | {t.get('near')} / {r.get('budget',m.get('budget'))} | {t.get('mid')} | {t.get('far')} | {slot} | {trims or '—'} | {col} | {rcs} | {fs} | {'PASS' if r.get('validator_ok') else 'FAIL'} | {'PASS' if r.get('uvsrc_ok') else 'FAIL'} | **{'PASS' if r.get('pass') else 'FAIL'}** |")
# page W occupancy
A=json.load(open(K+'/atlases/props_atlas.json'))['regions']
occ=np.zeros((1024,1024),bool)
for k,v in A.items():
    if v.get('page')=='w' and k.endswith('.clean'): x,y,w,h=v['px']; occ[y:y+h,x:x+w]=True
for k,v in S.items():
    for x,y,w,h in v: occ[y:y+h,x:x+w]=True
free=int((~occ).sum())
tab="\n".join(["| group | piece | class | near / budget | mid | far | page-W slot | page-W trims | collision | railcheck | far match (gated) | validator | uv src | result |",
               "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]+rows)
mem=f"""- Page W (1024 colour / 512 normal / 256 ORM, 1.75 MB, approved and pushed per the 03:47 note): batch-2 bake slots use **{tot:,} px** ({tot/1024/1024*100:.1f} % of the page). Page W free after batch 2: **{free:,} px** ({free/1024/1024*100:.1f} %).
- Texture memory: batch 2 adds **0 MB**. It shares page W, and every far tier uses the `twf_flat` swatch. Props total stays at **7.583 of 8 MB**."""
P=open(B+'/PROGRESS.md').read()
now=datetime.datetime.now().strftime('%H:%M')
P=re.sub(r'Updated [^\n]*',f'Updated {now} UTC+3, Nov 17.',P,count=1)
P=re.sub(r'## Pieces\n.*?\n\n',f'## Pieces\n{tab}\n\n',P,flags=re.S)
P=re.sub(r'<!--mem-->.*?<!--/mem-->',f'<!--mem-->\n{mem}\n<!--/mem-->',P,flags=re.S) if '<!--mem-->' in P else P.replace('## Pieces',f'<!--mem-->\n{mem}\n<!--/mem-->\n\n## Pieces')
open(B+'/PROGRESS.md','w').write(P); print(tab); print(mem)
