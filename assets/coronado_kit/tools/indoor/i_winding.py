#!/usr/bin/env python3
"""Heuristic winding check: per connected island, share of triangle area whose geometric normal points away from
the island centre. Islands under 35 % outward (and >= 8 tris) are reported as likely inverted."""
import sys, glob, os, numpy as np, pygltflib
KIT=os.environ.get('IN_KIT',os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/kit')
def load(p):
    g=pygltflib.GLTF2().load(p); blob=g.binary_blob(); pr=g.meshes[0].primitives[0]
    def acc(i):
        a=g.accessors[i]; bv=g.bufferViews[a.bufferView]; n={'SCALAR':1,'VEC3':3}[a.type]
        dt={5126:np.float32,5125:np.uint32,5123:np.uint16}[a.componentType]
        return np.frombuffer(blob,dt,count=a.count*n,offset=(bv.byteOffset or 0)+(a.byteOffset or 0)).reshape(-1,n) if n>1 else np.frombuffer(blob,dt,count=a.count,offset=(bv.byteOffset or 0)+(a.byteOffset or 0))
    return acc(pr.attributes.POSITION).astype(np.float64), acc(pr.indices).reshape(-1,3)
bad=0
for p in sorted(glob.glob(KIT+'/props/indoor/**/*_clean_near.glb',recursive=True)):
    P,T=load(p); key=np.round(P,4); _,inv=np.unique(key,axis=0,return_inverse=True); inv=inv.ravel()
    par=list(range(inv.max()+1))
    def fd(i):
        while par[i]!=i: par[i]=par[par[i]]; i=par[i]
        return i
    for a,b,c in inv[T]:
        ra,rb,rc=fd(a),fd(b),fd(c); par[rb]=ra; par[fd(rc)]=ra
    isl=np.array([fd(inv[t[0]]) for t in T])
    A=P[T[:,0]]; B=P[T[:,1]]; C=P[T[:,2]]; N=np.cross(B-A,C-A); ar=np.linalg.norm(N,axis=1)/2; cen=(A+B+C)/3
    flags=[]
    for r in np.unique(isl):
        m=isl==r
        if m.sum()<8: continue
        nn=N[m]/np.maximum(np.linalg.norm(N[m],axis=1,keepdims=True),1e-12)
        if np.abs(nn@nn[0]).min()>0.999: continue   # flat island (decal / fan): no inside/outside
        ic=(cen[m]*ar[m,None]).sum(0)/max(ar[m].sum(),1e-9)
        out=((N[m]*(cen[m]-ic)).sum(1)>0)
        frac=(ar[m]*out).sum()/max(ar[m].sum(),1e-9)
        if frac<0.35: flags.append((int(m.sum()),round(float(frac),2),np.round(ic,2).tolist()))
    if flags: bad+=1; print('CHECK',os.path.basename(p),flags)
print('winding check done,',bad,'files flagged')
