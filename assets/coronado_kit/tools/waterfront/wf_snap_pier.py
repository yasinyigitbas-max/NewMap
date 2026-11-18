"""pier snap check: at each joint the deck cross-section (planks, stringers, fascia, curb) of piece A's open end must match
piece B's, and the top-of-walk profile must continue. Builder coords. Pier modules run along y (water at -y)."""
import sys, os, json, numpy as np
sys.path.insert(0,os.path.dirname(__file__)); import wf_glb as G, wf_snap as S
D='/workspace/coronado_kit_v2/_staging/waterfront/kit/props/waterfront'
def f(g,n): return f'{D}/{g}/prop_{n}_clean_near.glb'
def sec(fn,y,yoff):
    T=S.tris(fn); T=T.copy(); T[:,:,1]+=yoff
    d=T[:,:,1]-y; k=(d.min(1)<-1e-7)&(d.max(1)>1e-7); out=[]
    for t,dd in zip(T[k],d[k]):
        p=[t[i]+(t[(i+1)%3]-t[i])*(dd[i]/(dd[i]-dd[(i+1)%3])) for i in range(3) if dd[i]*dd[(i+1)%3]<0]
        if len(p)==2:
            n=max(2,int(np.linalg.norm(p[1]-p[0])/0.01)+1); out+= [p[0]+(p[1]-p[0])*s for s in np.linspace(0,1,n)]
    o=np.array(out); return o[:,[0,2]] if len(o) else np.zeros((0,2))
def walk(Sx):   # top-of-walk height per 10 cm across the deck
    r={}
    for u in np.arange(-1.6,1.6,0.1):   # inside the curbs (curb blocks/gaps may differ per module)
        k=(Sx[:,0]>=u)&(Sx[:,0]<u+0.1)&(Sx[:,1]>2.5)&(Sx[:,1]<3.1)
        if k.any(): r[round(u,1)]=float(Sx[k,1].max())
    return r
# joint: name, (group,A, plane y in A, A placed y), (group,B, plane y in B, B placed y)   -- shared plane in world y
J=[('straight|straight',('pier','pier_straight',-3.0,-4.0),('pier','pier_straight',3.0,-10.0)),
   ('straight|thead',   ('pier','pier_straight',-3.0,-10.0),('pier','pier_thead',3.0,-16.0)),
   ('straight|rail_end',('pier','pier_straight',-3.0,-10.0),('pier','pier_rail_end',3.0,-16.0)),
   ('pier_root|straight',('quay','quay_pier_root',-1.0,0.0),('pier','pier_straight',3.0,-4.0))]
rep=[]; ok_all=True
for nm,(ga,a,ya,pa),(gb,b,yb,pb) in J:
    w=ya+pa
    Sa=sec(f(ga,a),w+0.01,pa); Sb=sec(f(gb,b),w-0.01,pb)
    wa,wb=walk(Sa),walk(Sb); us=sorted(set(wa)&set(wb))
    wdev=max(abs(wa[u]-wb[u]) for u in us) if us else 99
    if 'root' in nm: hdev=None; ok=wdev<=0.02 and len(us)>=28
    else:
        z=lambda X: X[(X[:,1]>2.3)&(X[:,1]<3.02)&(np.abs(X[:,0])<=1.95)]   # side fascias (x=+-2) end on the T-head back fascia by design
        hdev=float(S.haus(z(Sa),z(Sb))); ok=wdev<=0.02 and hdev<=0.03 and len(us)>=28
    ok_all&=ok; rep.append(dict(joint=nm,walk_bins=len(us),walk_dev_m=round(wdev,3),deck_section_hausdorff_m=None if hdev is None else round(hdev,3),ok=bool(ok)))
    print(rep[-1])
json.dump(rep,open('/workspace/coronado_kit_v2/_staging/waterfront/reports/pier_snap.json','w'),indent=1); print('ALL','OK' if ok_all else 'FAIL')
