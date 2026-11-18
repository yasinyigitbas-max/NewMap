"""Validate every modular piece and example assembly against SPEC.md (via tools/validate.py check_file) plus modular rules.
Modular relaxations (documented in README): size/footprint/origin-centre/ground checks are replaced by snap checks; the far
'closed hull' rule becomes 'open only on the declared snap planes or the ground'; mid<=50% of near is waived for trims
under 60 near tris. Writes modular/reports/validation_modular.{json,md}"""
import os, sys, json, glob
import numpy as np
import far_match
KIT=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0,KIT+'/tools'); import validate as V
M=KIT+'/modular'
SKIP=('out of range','origin far from footprint centre','far footprint not centred','model not standing on y=0','geometry below ground','bottom faces at ground')
BAKE_H=set(os.path.basename(f)[:-11] for f in glob.glob(KIT+'/textures/bake/*_normal.png'))
BAKE_C=set(os.path.basename(f)[:-11] for f in glob.glob(KIT+'/textures/bake_city/*_normal.png'))|BAKE_H

def edges_open(path):
    g,acc=V.load(path); p=g.meshes[0].primitives[0]
    P=acc(p.attributes.POSITION).astype(np.float64); I=acc(p.indices).astype(np.int64).reshape(-1,3)
    key={}; ids=np.array([key.setdefault(tuple(v),len(key)) for v in np.round(P,4)]); T=ids[I]
    Pu=np.zeros((len(key),3))
    for k,i in key.items(): Pu[i]=k
    E={}
    for t in T:
        for a,b in ((t[0],t[1]),(t[1],t[2]),(t[2],t[0])): E[(a,b)]=E.get((a,b),0)+1
    return [(Pu[a],Pu[b]) for (a,b) in E if (b,a) not in E]

def on_planes(a,b,planes):
    if a[1]<0.01 and b[1]<0.01: return True
    for (ax,val,sg,ymax) in planes:
        if abs(a[ax]-val)<0.004 and abs(b[ax]-val)<0.004: return True
    return False

def piece(d):
    st=json.load(open(d+'/stats.json')); name=st['name']; errs=[]; files={}
    ctx={'imgsize':{},'no_door':st.get('no_door',True)}
    bud=st['budget']
    for t in ('near','mid','far','col'):
        f=f"{d}/mod_{name}_{t}.glb"
        if not os.path.exists(f): errs.append(f'missing {t}'); continue
        r=V.check_file(f,bud,ctx); files[t]=r
        errs+=[f'{t}: {e}' for e in r['errors'] if not any(k in e for k in SKIP)]
        if t=='far':
            planes=[(ax,val,sg,ymax if ymax is not None else 1e9) for (ax,val,sg,ymax) in st['open_planes']]
            bad=[e for e in edges_open(f) if not on_planes(e[0],e[1],planes)]
            if bad: errs.append(f'far: {len(bad)} open edges off the snap planes (hull must be closed except at snaps)')
    ne,mi=files.get('near'),files.get('mid')
    if ne and mi:
        ratio=mi['tris']/max(1,ne['tris'])
        if ratio>0.5 and ne['tris']>=60: errs.append(f'mid is {ratio:.0%} of near')
    if ne and 'bbox' in ne:
        mn=ne['bbox'][0][1]; by=st.get('base_y',0.0)
        if by==0.0 and abs(mn)>0.02: errs.append(f'not standing on y=0 (min y {mn:.3f})')
        # a gable-end roof piece may carry its downspout to the ground (near only): then the mid tier must sit on the plate
        if by>0 and st.get('ground_reach') and mi and 'bbox' in mi: mn=mi['bbox'][0][1]
        if by>0 and not (by-0.3<=mn<=by+0.01): errs.append(f'roof piece base {mn:.2f} not at its plate {by}')
        if mn<-0.005: errs.append('geometry below ground')
    sn=st.get('snap') or {}
    if ne and sn.get('module') and sn.get('type') not in ('house_roof',):
        w=sn['module']; mnx,mxx=ne['bbox'][0][0],ne['bbox'][1][0]
        if mnx<-w/2-0.003 or mxx>w/2+0.003: errs.append(f'near crosses its snap ends ({mnx:.3f}..{mxx:.3f} vs +-{w/2})')
        if abs(w/0.5-round(w/0.5))>1e-6: errs.append('module not on the 0.5 m grid')
    if st.get('logic_errors'): errs+=['logic: '+e for e in st['logic_errors']]
    city=b'city_color.png' in open(f"{d}/mod_{name}_near.glb",'rb').read(6000)
    O=[r for r in st['near']['regions'] if r.startswith('O_')]
    miss=[r for r in O if r not in (BAKE_C if city else BAKE_H)]
    if miss: errs.append(f'opening regions without a high-poly bake: {miss}')
    fm=far_match.check(d, st)
    if fm and not fm.get('ok'):
        errs.append('far facade does not match mid: '+fm['reason'])
    return dict(name=name,group=os.path.basename(os.path.dirname(d.rstrip('/'))),cls=st['budget_class'],budget=bud,
                tris=[files.get(t,{}).get('tris') for t in ('near','mid','far')],col_boxes=files.get('col',{}).get('boxes'),
                regions_O=O,errors=errs,ok=not errs)

def example(d):
    L=json.load(open(d+'/layout.json')); name=L['name']; errs=[]; files={}; ctx={'imgsize':{},'no_door':False}
    for t in ('near','mid','far','col'):
        r=V.check_file(f"{d}/mod_{name}_{t}.glb",L['budget'],ctx); files[t]=r
        errs+=[f'{t}: {e}' for e in r['errors'] if 'origin far from footprint centre' not in e]
    bad,vol=V.far_closed(f"{d}/mod_{name}_far.glb")
    if bad: errs.append(f'far hull not closed ({bad} bad edges)')
    if vol<=0: errs.append('far hull inside-out')
    ratio=files['mid']['tris']/max(1,files['near']['tris'])
    if ratio>0.5: errs.append(f'mid is {ratio:.0%} of near')
    return dict(name=name,cls=L['budget_class'],budget=L['budget'],tris=[files[t]['tris'] for t in ('near','mid','far')],
                col_boxes=files['col'].get('boxes'),pieces=len(L['pieces']),mid_ratio=round(ratio,2),errors=errs,ok=not errs)

def main():
    P=[piece(d) for d in sorted(glob.glob(M+'/pieces/*/*/')) if os.path.exists(d+'/stats.json')]
    X=[example(d) for d in sorted(glob.glob(M+'/examples/*/')) if os.path.exists(d+'/layout.json')]
    ok_pieces={p['name'] for p in P if p['ok']}
    for x in X:
        L=json.load(open(f"{M}/examples/{x['name']}/layout.json"))
        bad=sorted({q['piece'] for q in L['pieces'] if q['piece'] not in ok_pieces})
        if bad: x['errors'].append(f'uses failing pieces {bad}'); x['ok']=False
    os.makedirs(M+'/reports',exist_ok=True)
    json.dump(dict(pieces=P,examples=X),open(M+'/reports/validation_modular.json','w'),indent=1,default=str)
    with open(M+'/reports/validation_modular.md','w') as fh:
        fh.write(f"# Modular starter set validation\n\nPieces: {sum(p['ok'] for p in P)}/{len(P)} pass. Examples: {sum(x['ok'] for x in X)}/{len(X)} pass.\n\n")
        fh.write('Snap-in houses are checked against `mod_house_small` = 1650/500/40 (SPEC §7: snap-in houses 1650 cap, approved by Yasin 15 Nov 2026 19:36) and must meet the full house detail floor, chimney and entry-step railing included.\n\n')
        fh.write('| group | piece | class | near/mid/far | budget | col boxes | baked opening regions | result |\n|---|---|---|---|---|---|---|---|\n')
        for p in P: fh.write(f"| {p['group']} | {p['name']} | {p['cls']} | {'/'.join(map(str,p['tris']))} | {'/'.join(map(str,p['budget']))} | {p['col_boxes']} | {', '.join(p['regions_O']) or '-'} | {'PASS' if p['ok'] else 'FAIL: '+'; '.join(p['errors'])} |\n")
        fh.write('\n## Example assemblies\n\n| example | class | near/mid/far | budget | pieces | col boxes | mid/near | result |\n|---|---|---|---|---|---|---|---|\n')
        for x in X: fh.write(f"| {x['name']} | {x['cls']} | {'/'.join(map(str,x['tris']))} | {'/'.join(map(str,x['budget']))} | {x['pieces']} | {x['col_boxes']} | {x['mid_ratio']} | {'PASS' if x['ok'] else 'FAIL: '+'; '.join(x['errors'])} |\n")
    print(f"pieces {sum(p['ok'] for p in P)}/{len(P)}  examples {sum(x['ok'] for x in X)}/{len(X)}")
    for p in P+X:
        if not p['ok']: print('FAIL',p['name'],p['errors'][:5])
if __name__=='__main__': main()
