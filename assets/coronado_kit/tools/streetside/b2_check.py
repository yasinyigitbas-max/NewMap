#!/usr/bin/env python3
"""Waterfront checks per piece: (1) paint the far tier (vertex colour = mid colour seen from the same side / far swatch),
(2) kit props validator (SPEC s1-s4), (3) far_match: front + plan silhouette IoU >= 0.8 and mean colour dE <= 15 (CIE76,
the kit's far_match threshold), (4) railcheck (SPEC s7: every rail end within 1.5 cm of other geometry and not buried more
than 1 cm, every post foot on something), (5) collision split (<=12 main + <=16 post/rail, posts/piles/bollards/rails present).
usage: wf_check.py <name> ...   -> reports/<name>.json"""
import sys, os, json, glob, subprocess, numpy as np
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0,'/workspace/coronado_kit_v2/modular/tools'); sys.path.insert(0,'/workspace/coronado_kit_v2/tools')
import wf_glb as G
import far_match as FM
from railcheck import pt_tri_dist
W='/workspace/coronado_kit_v2/_staging/props_batch2'; K='/workspace/coronado_kit_v2/_staging/waterfront/kit'   # page W lives in the waterfront staging kit (props/batch2 is a symlink to this folder)
SW=G.srgb2lin(np.array([230/255]*3))
GAP=0.015; PEN=0.010
def man():
    m={}
    for f in glob.glob(K+'/props/manifest_b2*.json'):
        for k,v in json.load(open(f)).items(): m[k]=dict(v,_man=f)
    return m
def files(name,rec):
    d=None
    for p in glob.glob(K+f'/props/batch2/**/prop_{name}_clean_near.glb',recursive=True): d=os.path.dirname(p)
    return {t:f'{d}/prop_{name}_clean_{t}.glb' for t in ('near','mid','far')} | {'col':f'{d}/prop_{name}_col.glb'}, d
def paint_far(fm,fn):
    mm=G.mesh(fm); fa=G.mesh(fn); P=fa['P']; I=fa['I']
    v0,v1,v2=P[I[:,0]],P[I[:,1]],P[I[:,2]]; n=np.cross(v1-v0,v2-v0); n/=np.maximum(np.linalg.norm(n,axis=1,keepdims=True),1e-12)
    views=list(G.VIEWS); F=np.array([G.VIEWS[v][2] for v in views],float); best=np.argmax(n@F.T,axis=1)
    acc=np.zeros((len(P),3)); wsum=np.zeros(len(P)); res=0.03
    cache={}
    for vi,vn in enumerate(views):
        sel=np.where(best==vi)[0]
        if not len(sel): continue
        fr=G.frame_of([mm,fa],vn,0.1); cm,_,mk=G.raster(mm,vn,fr,res)
        R,U,_F=[np.array(v,float) for v in G.VIEWS[vn]]
        for t in sel:
            tri=P[I[t]]; u=(tri@R-fr[0])/res; v=(fr[3]-tri@U)/res
            H,Wd=mk.shape; gx,gy=np.meshgrid(np.arange(Wd)+0.5,np.arange(H)+0.5)
            x0,x1,x2=u; y0,y1,y2=v; den=(y1-y2)*(x0-x2)+(x2-x1)*(y0-y2)
            if abs(den)<1e-9: continue
            a=((y1-y2)*(gx-x2)+(x2-x1)*(gy-y2))/den; b=((y2-y0)*(gx-x2)+(x0-x2)*(gy-y2))/den; c=1-a-b
            ins=(a>=-0.02)&(b>=-0.02)&(c>=-0.02)&mk
            if ins.sum()<3:   # tiny / edge-on far face: its projected box grown by 1.5 px first (a wide circle mixed in neighbouring parts)
                ins=(gx>=u.min()-1.5)&(gx<=u.max()+1.5)&(gy>=v.min()-1.5)&(gy<=v.max()+1.5)&mk
            if ins.sum()<1:
                cx,cy=u.mean(),v.mean(); r=8; ins=((gx-cx)**2+(gy-cy)**2<r*r)&mk
            col=cm[ins].mean(0) if ins.any() else np.array([0.5,0.5,0.5])
            ar=np.linalg.norm(np.cross(tri[1]-tri[0],tri[2]-tri[0]))/2
            for k in I[t]: acc[k]+=col*ar; wsum[k]+=ar
    C=acc/np.maximum(wsum[:,None],1e-12)/SW
    G.write_color0(fn,fa,np.clip(C,0,1))
    return float(np.clip(C,0,1).max())
def _lab(c): return FM._rgb_to_lab(G.lin2srgb(c))
GATE={}   # pieces whose length axis is Y: the front view looks at the open snap end
def gate_of(name):
    for k,v in GATE.items():
        if name.startswith(k): return v
    return ('front','top')
def far_match(fm,fn,gate=('front','top')):
    mm=G.mesh(fm); fa=G.mesh(fn); out={}
    from scipy.ndimage import binary_dilation
    ok=True
    for vn in ('front','top','left'):
        fr=G.frame_of([mm,fa],vn,0.05); res=max(0.02,max(fr[1]-fr[0],fr[3]-fr[2])/256)
        cm,_,km=G.raster(mm,vn,fr,res); cf,_,kf=G.raster(fa,vn,fr,res)
        r=max(1,int(round(0.04/res))); kmd=binary_dilation(km,iterations=r); kfd=binary_dilation(kf,iterations=r)
        iou=float((kmd&kfd).sum()/max((kmd|kfd).sum(),1))
        de=float(np.linalg.norm(_lab(cm[km].mean(0))-_lab(cf[kf].mean(0)))) if km.any() and kf.any() else 99
        out[vn]={'iou':round(iou,3),'dE':round(de,1)}
        if vn not in gate: out[vn]['note']='info only (snap ends are open)'
        if vn in gate and (iou<0.8 or de>15): ok=False
    return ok,out
def _ray(o,d,tri):
    v0,v1,v2=tri[:,0],tri[:,1],tri[:,2]; e1=v1-v0; e2=v2-v0; p=np.cross(d,e2); det=(e1*p).sum(1); ok=np.abs(det)>1e-12
    inv=np.where(ok,1/np.where(ok,det,1),0); t=o-v0; u=(t*p).sum(1)*inv; q=np.cross(t,e1); v=(d*q).sum(1)*inv; w=(e2*q).sum(1)*inv
    h=ok&(u>=0)&(v>=0)&(u+v<=1)&(w>1e-6)
    if not h.any(): return None,None
    j=np.argmin(np.where(h,w,np.inf)); return float(w[j]),float(det[j])
def to_gl(p): return np.array([p[0],p[2],-p[1]],float)
def seg_dist(X,A,B):
    d=B-A; t=np.clip(((X-A)@d)/max(d@d,1e-12),0,1); return np.linalg.norm(X-(A+t[:,None]*d),axis=1)
def railcheck(fn,rj):
    m=G.mesh(fn); P=m['P']; I=m['I']; T=P[I]; out=[]; R=json.load(open(rj))['rails']
    for k,(kind,a,b,r,pts) in enumerate(R):
        pl=[to_gl(p) for p in pts]
        # own triangles: every vertex within r*1.5 + 4 mm of the member polyline
        dmin=np.full(len(P),np.inf)
        for i in range(len(pl)-1): dmin=np.minimum(dmin,seg_dist(P,pl[i],pl[i+1]))
        own=(dmin[I]<=r*1.5+0.004).all(1); oth=T[~own]
        ends=[]
        if kind=='v':
            lo=pl[0] if pl[0][1]<=pl[-1][1] else pl[-1]; ends=[(lo,np.array([0,-1.0,0]))]
        else:
            ends=[(pl[0],(pl[0]-pl[1])/np.linalg.norm(pl[0]-pl[1])),(pl[-1],(pl[-1]-pl[-2])/np.linalg.norm(pl[-1]-pl[-2]))]
        for E,d in ends:
            dist=float(pt_tri_dist(E[None],oth[:,0],oth[:,1],oth[:,2]).min()) if len(oth) else 9
            if kind=='v' and E[1]<=GAP: dist=min(dist,abs(E[1]))
            # end zone: the last 5 cm of the member (a foot standing on a bracket beside it)
            if dist>GAP and len(oth):
                Z=np.array([E-d*s for s in np.linspace(0,0.05,6)]); dz=pt_tri_dist(Z,oth[:,0],oth[:,1],oth[:,2]).min()-r
                dist=min(dist,max(float(dz),0.0))
            s_b,det_b=_ray(E,-d,oth) if len(oth) else (None,None)
            pen=s_b if (s_b is not None and s_b<0.2 and det_b is not None and det_b<0) else 0.0   # back-face hit = end is inside a closed solid
            s_f,_=_ray(E,d,oth) if len(oth) else (None,None)
            okk=(dist<=GAP) and pen<=PEN
            out.append(dict(member=k,kind=kind,end=[round(x,3) for x in E],gap=round(dist,4),pen=round(pen,4),ok=okk))
    return all(o['ok'] for o in out),out
def validate(d,fs):
    r=subprocess.run(['python3',K+'/props/validate_props.py',d],capture_output=True,text=True)
    tag=os.path.basename(d.rstrip('/')); res=json.load(open(K+f'/reports/props_validation_{tag}.json'))
    mine={os.path.basename(v) for v in fs.values()}
    rows=[x for x in res if x['file'] in mine]
    return all(x['ok'] for x in rows),rows
def uvsrc(name,fs):
    """guard against reused / foreign atlas regions: every near+mid triangle must sample a page-W trim tile or this
    piece's own bake slot, and no bake slot on page W may overlap a trim tile (a slot painted over a tile = building
    texture bleeding onto other pieces)"""
    A=json.load(open(K+'/atlases/props_atlas.json')); Z=A['size_w']['color']
    tiles=[v['px'] for k,v in A['regions'].items() if k.endswith('.clean') and v.get('page')=='w' and v.get('trim')]
    S=json.load(open(K+'/props/_bake/slots_w.json'))['slots']; own=S.get(name,[])
    def inter(a,b): return a[0]<b[0]+b[2] and b[0]<a[0]+a[2] and a[1]<b[1]+b[3] and b[1]<a[1]+a[3]
    clash=[(n,r,t) for n,rs in S.items() for r in rs for t in tiles if inter(r,t)]
    clash+=[(a,b) for a in S for b in S if a<b for ra in S[a] for rb in S[b] if inter(ra,rb)]
    out={'slot_overlaps':len(clash)}; ok=not clash
    for tier in ('near','mid'):
        if not os.path.exists(fs[tier]): continue
        m=G.mesh(fs[tier]); uv=m['UV'][m['I']].mean(1)*Z; bad=0
        for x,y in uv:
            if not any(r[0]-1<=x<=r[0]+r[2]+1 and r[1]-1<=y<=r[1]+r[3]+1 for r in tiles+own): bad+=1
        out[tier+'_foreign_tris']=bad; ok=ok and bad==0
        if m['js']['images'][0]['uri'].split('/')[-1]!='props_w_color_clean.png': out[tier+'_page']='WRONG'; ok=False
    return ok,out
def check(name):
    M=man(); rec=M[name]; fs,d=files(name,rec); rep={'name':name,'tiers':rec['tiers'],'budget':rec['budget'],'class':rec['class']}
    if os.path.exists(fs['far']): rep['far_paint_max']=paint_far(fs['mid'],fs['far'])
    rep['validator_ok'],rep['validator']=validate(d,fs)
    if os.path.exists(fs['far']): rep['far_match_ok'],rep['far_match']=far_match(fs['mid'],fs['far'],gate_of(name))
    rj=f'{K}/props/batch2/_rails/{name}_rails.json'
    if os.path.exists(rj):
        J=json.load(open(rj)); rep['col_split']=J['col']
        rep['col_ok']=J['col']['main']<=12 and J['col']['rail']<=16
        if J['rails']: rep['rail_ok'],rep['railcheck']=railcheck(fs['near'],rj)
    rep['uvsrc_ok'],rep['uvsrc']=uvsrc(name,fs)
    rep['bake_px']=rec.get('bake_slot_px'); rep['bake_px_per_m']=rec.get('bake_px_per_m'); rep['high_tris']=rec.get('high_tris')
    rep['pass']=all(rep.get(k,True) for k in ('validator_ok','far_match_ok','col_ok','rail_ok','uvsrc_ok'))
    os.makedirs(W+'/reports',exist_ok=True); json.dump(rep,open(f'{W}/reports/{name}.json','w'),indent=1)
    return rep
if __name__=='__main__':
    for n in sys.argv[1:]:
        r=check(n)
        print(n,'PASS' if r['pass'] else 'FAIL',r['tiers'],'val',r.get('validator_ok'),'far',r.get('far_match'),'rail',r.get('rail_ok'),'col',r.get('col_split'),'uv',r.get('uvsrc'))
        for v in r['validator']:
            if not v['ok'] or v.get('warn'): print('  ',v['file'],v['errs'],v.get('warn'))
        for x in r.get('railcheck',[]):
            if not x['ok']: print('  RAIL',x)
