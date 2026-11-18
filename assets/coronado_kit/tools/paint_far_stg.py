#!/usr/bin/env python3
"""Paint the far front slot of the merged storage rows (modular/examples_map/stg_row2, stg_row3; MAP_NEEDS_16nov item 4).
Their far is a painted 10-tri box (assemble_map._far_painted_box): the front face samples F_bb_1 from u=100 m (18 m = the
3-bay row; stg_row2 uses the first 12 m). The slot holds the mid front view of stg_row3 (z-buffered: wall, sign band, roll-up
doors, coping; ground to the 4.8 m parapet top) baked at the strip's scale (10 px/m across, the strip height = 4.8 m), so
the far reads like the mid at range. u 98.2-200 m of F_bb_1 is sampled by no other far (occupancy scan, 16 Nov).
usage: paint_far_stg.py  (paints over textures/far_color.png in place; idempotent). paint_far_garages.py calls paint()."""
import os, sys
import numpy as np
from PIL import Image
HERE=os.path.dirname(os.path.abspath(__file__)); KIT=os.path.dirname(HERE)
sys.path.insert(0,HERE); sys.path.insert(0,KIT+'/modular/tools')
FC=KIT+'/textures/far_color.png'
KEY='F_bb_1'; U=100.0; SPAN=18.0; TOP=4.8; PAD=3
SRC=KIT+'/modular/examples_map/stg_row3/mod_stg_row3_mid.glb'
def front_view(glb,x0,x1,y0,y1,wpx,hpx):
    """true front view of the +Z-facing triangles (z-buffer: the nearest face wins, so roof plant behind the parapet is
    hidden as in game), colour = atlas texel x vertex colour, as far_match samples it"""
    import far_match as F
    P,N,UV,C,I,tex=F._mesh(glb)
    V0,V1,V2=P[I[:,0]],P[I[:,1]],P[I[:,2]]
    fn=np.cross(V1-V0,V2-V0); fn/=np.maximum(np.linalg.norm(fn,axis=1,keepdims=True),1e-12)
    keep=np.where(fn[:,2]>0.55)[0]
    img=np.zeros((hpx,wpx,3),np.float32); zb=np.full((hpx,wpx),-1e9)
    th,tw=tex.shape[:2]
    for i in keep:
        t=I[i]; pts=P[t]; px=(pts[:,0]-x0)/(x1-x0)*wpx-0.5; py=(y1-pts[:,1])/(y1-y0)*hpx-0.5
        a=np.array([[px[1]-px[0],px[2]-px[0]],[py[1]-py[0],py[2]-py[0]]]); det=np.linalg.det(a)
        if abs(det)<1e-12: continue
        mnx,mxx=max(0,int(np.floor(px.min()))),min(wpx-1,int(np.ceil(px.max()))); mny,mxy=max(0,int(np.floor(py.min()))),min(hpx-1,int(np.ceil(py.max())))
        if mxx<mnx or mxy<mny: continue
        XX,YY=np.meshgrid(np.arange(mnx,mxx+1),np.arange(mny,mxy+1))
        bc=np.stack([XX-px[0],YY-py[0]],-1)@np.linalg.inv(a).T; b1,b2=bc[...,0],bc[...,1]; b0=1-b1-b2
        m=(b0>=-1e-4)&(b1>=-1e-4)&(b2>=-1e-4)
        z=b0*pts[0,2]+b1*pts[1,2]+b2*pts[2,2]
        sub=zb[mny:mxy+1,mnx:mxx+1]; m&=z>sub+1e-5
        if not m.any(): continue
        uv=UV[t]; uu=np.mod(b0*uv[0,0]+b1*uv[1,0]+b2*uv[2,0],1.0); vv=np.clip(b0*uv[0,1]+b1*uv[1,1]+b2*uv[2,1],0,1-1e-9)
        col=tex[(vv*th).astype(int),(uu*tw).astype(int)]
        if C is not None: col=col*(b0[...,None]*C[t[0]]+b1[...,None]*C[t[1]]+b2[...,None]*C[t[2]])
        img[mny:mxy+1,mnx:mxx+1][m]=col[m]; sub[m]=z[m]
    return img
def slot():
    import json
    reg=json.load(open(KIT+'/textures/atlas_layout.json'))['far']['regions'][KEY]; x0,y0,x1,y1=reg['px']
    hpx=y1-y0; wpx=int(round(SPAN*10)); SS=4
    im=front_view(SRC,-SPAN/2,SPAN/2,0.0,TOP,wpx*SS,hpx*SS)
    img=im.reshape(hpx,SS,wpx,SS,3).mean((1,3))   # box filter: anti-aliased at the strip scale
    img=np.concatenate([np.repeat(img[:,:1],PAD,1),img,np.repeat(img[:,-1:],PAD,1)],1)   # pads: edge columns
    return img,y0,y1,int(round(U*10))-PAD
def paint(OUT):
    img,y0,y1,c0=slot(); OUT[y0:y1,c0:c0+img.shape[1]]=img
    print('stg rows front',KEY,f'u {U:.1f}-{U+SPAN:.1f} m  px {c0}-{c0+img.shape[1]}')
    return OUT
if __name__=='__main__':
    A=np.asarray(Image.open(FC).convert('RGB')).astype(np.float32)/255.0
    A=paint(A.copy()); Image.fromarray((np.clip(A,0,1)*255+0.5).astype(np.uint8)).save(FC); print('wrote',FC)
