"""snap / tiling check: wall cross-sections at the open module ends must match between neighbours.
Builder coords (x, y=-glb z, z=glb y). Each joint: (pieceA, end plane A, pieceB, end plane B, transform B->A frame).
A section is sampled as dense 2D points (u along the plane horizontal, height) and compared with a symmetric Hausdorff."""
import sys, os, json, numpy as np
sys.path.insert(0,os.path.dirname(__file__)); import wf_glb as G
D='/workspace/coronado_kit_v2/_staging/waterfront/kit/props/waterfront'
def tris(fn):
    m=G.mesh(fn); P=m['P']; B=np.stack([P[:,0],-P[:,2],P[:,1]],1); return B[m['I']]
def section(T,axis,val,umin,umax):
    """plane coord[axis]=val cut through the mesh: each crossing triangle gives a segment, sampled every ~1 cm"""
    out=[]
    d=T[:,:,axis]-val; k=(d.min(1)<-1e-7)&(d.max(1)>1e-7)
    for t,dd in zip(T[k],d[k]):
        pts=[]
        for i in range(3):
            a,b=t[i],t[(i+1)%3]; da,db=dd[i],dd[(i+1)%3]
            if da*db<0: pts.append(a+(b-a)*(da/(da-db)))
        if len(pts)==2:
            n=max(2,int(np.linalg.norm(pts[1]-pts[0])/0.01)+1)
            for s_ in np.linspace(0,1,n): out.append(pts[0]+(pts[1]-pts[0])*s_)
    if not out: return np.zeros((0,2))
    out=np.array(out); u=out[:,1 if axis==0 else 0]; z=out[:,2]
    k=(u>=umin)&(u<=umax)&(z>0.05)&(z<2.95); return np.stack([u[k],z[k]],1)
def haus(A,B):
    if len(A)==0 or len(B)==0: return 99
    d=np.sqrt(((A[:,None,:]-B[None,:,:])**2).sum(-1)); return max(d.min(1).max(),d.min(0).max())
def wall_profile(S):
    """front-most wall surface per 5 cm height band: the profile a neighbour must continue"""
    out=[]
    for z0 in np.arange(0.1,2.9,0.05):
        k=(S[:,1]>=z0)&(S[:,1]<z0+0.05)
        if k.any(): out.append((round(z0,2),round(float(S[k,0].min()),3)))
    return out
def f(n): return f'{D}/quay/prop_{n}_clean_near.glb'
J=[ # name, A piece, A plane (axis, value, water-side u range), B piece, B plane, u offset B->A
 ('straight|straight',      'quay_straight',(0, 3.0),'quay_straight',(0,-3.0),0.0),
 ('straight|bollards',      'quay_straight',(0, 3.0),'quay_straight_bollards',(0,-3.0),0.0),
 ('straight|stair',         'quay_straight',(0, 3.0),'quay_stair',(0,-3.0),0.0),
 ('stair|straight',         'quay_stair',(0, 3.0),'quay_straight',(0,-3.0),0.0),
 ('straight|corner_out.a',  'quay_straight',(0, 3.0),'quay_corner_out',(0,-1.0),0.0),
 ('corner_out.b|straight',  'quay_corner_out',(1, 1.0),'quay_straight',(0,-3.0),None),   # rotated: corner u = x, straight u = y
 ('straight|corner_in.a',   'quay_straight',(0, 3.0),'quay_corner_in',(0,-2.0),-1.0),
 ('corner_in.b|straight',   'quay_corner_in',(1,-2.0),'quay_straight',(0,-3.0),None),
]
if __name__=="__main__":
    rep=[]; ok_all=True
    for nm,a,(ax,av),b,(bx,bv),off in J:
        Ta=tris(f(a)); Tb=tris(f(b))
        Sa=section(Ta,ax,av-np.sign(av)*0.01,-2.5,2.5); Sb=section(Tb,bx,bv-np.sign(bv)*0.01,-1.2 if off is None or off==0 else -2.5,2.0)
        pa=wall_profile(Sa); pb=wall_profile(Sb)
        if ax==1:   # arm running along y: u is x. corner_out arm has the water at +x (mirror), corner_in arm at -x
            sg=-1.0 if 'corner_out' in a else 1.0
            pa=wall_profile(np.stack([sg*Sa[:,0],Sa[:,1]],1))
        da=dict(pa); db=dict(pb); zs=sorted(set(da)&set(db))
        if off is None:   # b straight vs rotated arm: compare relative to each one's own wall face at 1.0 m height
            ra=da.get(1.0); rb=db.get(1.0); dev=max(abs((da[z]-ra)-(db[z]-rb)) for z in zs) if zs and ra is not None and rb is not None else 99
        else:
            dev=max(abs(da[z]-(db[z]+off)) for z in zs) if zs else 99
        ok=dev<=0.02 and len(zs)>40; ok_all&=ok
        rep.append(dict(joint=nm,bands=len(zs),max_dev_m=round(float(dev),3),ok=bool(ok)))
        print(nm,'OK' if ok else 'FAIL',len(zs),round(float(dev),3))
    json.dump(rep,open('/workspace/coronado_kit_v2/_staging/waterfront/reports/quay_snap.json','w'),indent=1)
    print('ALL', 'OK' if ok_all else 'FAIL')
