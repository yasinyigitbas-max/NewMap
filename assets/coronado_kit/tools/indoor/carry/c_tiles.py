"""Page J (carry props) base: bake-source material cells + region table. Never touches pages A/B/C/W/H/I or
props_atlas.json in the repo: the regions go to kit/atlases/props_atlas.json of the carry scratch kit (build-time
lookup only) and to a copy props_j_regions.json next to this script.

Layout (1024 px page, rows 0-255 reserved, bake slots from y=256):
 row y=0, 128 px cells (2x supersampled, wrap-tiled):
   x=0 kraft_paper  x=128 paper_white  x=256 kraft_board  x=384 pine  x=512 leather  x=640 nylon  x=768 film  x=896 tape
 row y=128: cords 32x128 (length along v): rope_kraft x=0, rope_white x=40, rope_black x=80
   32 px swatches from x=120 step 40: ink_black ink_navy ink_red ink_green ink_white ink_gold
Only the cells a built prop uses are filled; the rest stay neutral grey until their variants are built.
"""
import os, json, sys, numpy as np, cv2
from PIL import Image
K=os.environ.get('IN_KIT','/workspace/coronado_kit_v2/_staging/carry/kit')
SRC=K+'/props/_bake_src'; os.makedirs(SRC,exist_ok=True); os.makedirs(K+'/atlases',exist_ok=True)
N=1024; SS=2
rng=np.random.default_rng(1952)
COL=np.zeros((N,N,3),np.float32)+0.5; NOR=np.zeros((N,N,3),np.float32); NOR[...,2]=1; ORM=np.zeros((N,N,3),np.float32); ORM[...,0]=1; ORM[...,1]=0.8
REG={}
def reg(name,px,m,trim=False):
    x,y,w,h=px
    for c in ('clean','worn','dirty'):
        REG[f'{name}.{c}']={'px':[x,y,w,h],'uv':[(x+2)/N,(y+2)/N,(x+w-2)/N,(y+h-2)/N],'m':list(m),'trim':trim,'page':'j','tile_px':w-4}
def wblur(a,s):
    H,W=a.shape[:2]; q=np.pad(a,((H,H),(W,W))+(((0,0),) if a.ndim==3 else ()),mode='wrap')
    return cv2.GaussianBlur(q,(0,0),s)[H:2*H,W:2*W]
def noise(h,w,s,oct=4):
    o=np.zeros((h,w),np.float32); a=1.0
    for i in range(oct):
        o+=a*wblur(rng.standard_normal((h,w)).astype(np.float32),s/(2**i)); a*=0.5
    o-=o.mean(); return o/(o.std()+1e-6)
def nrm(hgt,strength):
    gx=(np.roll(hgt,-1,1)-np.roll(hgt,1,1))*0.5; gy=(np.roll(hgt,-1,0)-np.roll(hgt,1,0))*0.5
    n=np.dstack([-gx*strength,gy*strength,np.ones_like(hgt)]); n/=np.linalg.norm(n,axis=2,keepdims=True); return n
def put(px,col,hgt,strength,rough,metal=0.0):
    x,y,w,h=px; S=lambda a: cv2.resize(a,(w,h),interpolation=cv2.INTER_AREA)
    COL[y:y+h,x:x+w]=S(col); n=S(nrm(hgt,strength)); n/=np.linalg.norm(n,axis=2,keepdims=True); NOR[y:y+h,x:x+w]=n
    ORM[y:y+h,x:x+w,0]=1.0; ORM[y:y+h,x:x+w,1]=S(rough) if np.ndim(rough) else rough; ORM[y:y+h,x:x+w,2]=metal
def fibres(h,w,n,lmin,lmax,ang_sd=0.35):
    """short paper fibres: thin anti-aliased strokes, mostly along x (machine direction)"""
    f=np.zeros((h,w),np.float32)
    for _ in range(n):
        L=rng.uniform(lmin,lmax); a=rng.normal(0,ang_sd); x0=rng.uniform(0,w); y0=rng.uniform(0,h)
        p0=(int(x0*16),int(y0*16)); p1=(int((x0+L*np.cos(a))*16),int((y0+L*np.sin(a))*16))
        v=rng.uniform(-1,1)
        for dx in (-w,0,w):
            for dy in (-h,0,h):
                cv2.line(f,(p0[0]+dx*16,p0[1]+dy*16),(p1[0]+dx*16,p1[1]+dy*16),float(v),1,cv2.LINE_AA,shift=4)
    return f
def paper(base,dark_specks=True,fib=1.0,cyc=0.0):
    S=128*SS
    mott=noise(S,S,18,4)*0.022+noise(S,S,4,2)*0.014
    fb=fibres(S,S,int(2600*fib),3,14)
    lum=1+mott+fb*0.05
    col=np.clip(np.asarray(base,np.float32)[None,None,:]*lum[...,None],0,1)
    if dark_specks:
        sp=(rng.random((S,S))>(0.9993 if base[0]<0.8 else 0.9997)).astype(np.float32); sp=cv2.GaussianBlur(sp,(0,0),0.8)*6
        col*=np.clip(1-0.35*sp,0.5,1)[...,None]
    hgt=fb*0.35+noise(S,S,10,3)*0.06+noise(S,S,2.5,2)*0.14
    rough=np.clip(0.86+mott*0.6,0.7,0.95)
    return col,hgt,rough
def srgb2lin(c): c=np.asarray(c,np.float32); return c  # tiles are stored in sRGB like page I
# ---- kraft paper (shopping bag): unbleached kraft, machine-direction fibres, mottling, rare dark specks
c,h,r=paper((0.69,0.52,0.35)); put([0,0,128,128],c,h,1.3,r); reg('kraft_paper',[0,0,128,128],(0.48,0.48),trim=True)
c,h,r=paper((0.93,0.92,0.89),fib=0.8); put([128,0,128,128],c,h,1.1,r); reg('paper_white',[128,0,128,128],(0.48,0.48),trim=True)
# ---- twisted paper cord: 3-ply twist stripes along u (cord length), 128x32 cell, m 0.40 x 0.10
def rope(base,px):
    x,y,w,h=px; Hs,Ws=h*SS,w*SS
    yy,xx=np.mgrid[0:Hs,0:Ws].astype(np.float32)
    per=Hs/(0.40/0.009)        # one ply every 9 mm along the cord (cord length runs along v)
    t=((yy+xx*0.9)/per)%1.0
    ridge=np.sin(np.pi*t)**0.6
    hgt=ridge+fibres(Hs,Ws,500,2,6,0.6)*0.25
    lum=0.86+0.22*ridge+noise(Hs,Ws,6,2)*0.03
    col=np.clip(np.asarray(base,np.float32)[None,None,:]*lum[...,None],0,1)
    put(px,col,hgt,3.0,0.88)
c0=(0.64,0.48,0.31); rope(c0,[0,128,32,128]); reg('rope_kraft',[0,128,32,128],(0.10,0.40))
rope((0.92,0.91,0.88),[40,128,32,128]); reg('rope_white',[40,128,32,128],(0.10,0.40))
rope((0.10,0.10,0.11),[80,128,32,128]); reg('rope_black',[80,128,32,128],(0.10,0.40))
# ---- print inks: flexo ink on kraft, slight mottle (ink sits in the fibres)
INK={'ink_black':(0.09,0.09,0.10),'ink_navy':(0.10,0.17,0.33),'ink_red':(0.62,0.12,0.10),'ink_green':(0.12,0.33,0.22),
     'ink_white':(0.92,0.91,0.87),'ink_gold':(0.70,0.55,0.25)}
for i,(k,v) in enumerate(INK.items()):
    x=120+40*i; S=32*SS; m=noise(S,S,3,2)
    col=np.clip(np.asarray(v,np.float32)[None,None,:]*(1+0.05*m[...,None]),0,1)
    put([x,128,32,32],col,m*0.15,1.0,0.78); reg(k,[x,128,32,32],(0.25,0.25))
def u8(a): return (np.clip(a,0,1)*255+0.5).astype(np.uint8)
for c in ('clean','worn','dirty'):
    a=np.dstack([u8(COL),np.full((N,N),255,np.uint8)])
    Image.fromarray(a).save(f'{SRC}/props_j_base_color_{c}.png'); Image.fromarray(a).save(f'{SRC}/props_src_color_{c}.png')
n=u8(NOR*0.5+0.5); Image.fromarray(n).save(SRC+'/props_j_base_normal.png'); Image.fromarray(n).save(SRC+'/props_src_normal.png')
o=u8(ORM); Image.fromarray(o).save(SRC+'/props_j_base_orm.png'); Image.fromarray(o).save(SRC+'/props_src_orm.png')
atl={'size':N,'page':'j','note':'Page J carry props (build-time region table, scratch kit only). Runtime 1024 colour / 512 normal / 256 ORM.',
     'bake_area':[0,256,1024,1024],'regions':REG}
json.dump(atl,open(K+'/atlases/props_atlas.json','w'),indent=1)
json.dump(atl,open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'props_j_regions.json'),'w'),indent=1)
print('page J base written,',len(REG)//3,'regions')
