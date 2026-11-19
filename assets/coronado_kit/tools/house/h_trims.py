"""Page H (house) base atlas: tiling trim tiles at 128 px/m (inner 112 px = 0.875 m, 8 px wrap pad).
Writes only props_h_* under the house kit. Never touches atlases A/B/C/W or page I.

Tiles row y=0: th_walnut, th_wash, th_paint, th_linen, th_metal, th_brass, th_ceramic, th_glass
Row y=128: th_rattan, th_stone (128), then 32 px tint swatches.
Rows y=192-255 reserved for rug pattern bands.
Bake slots from y=256.

Run: python3 tools/h_trims.py && IN_KIT=... python3 kit/props/_tools/props_compose.py h
"""
import json, os, sys, numpy as np, cv2
from PIL import Image
sys.path.insert(0,'/workspace/coronado_kit_v2/props/_tools')
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import trim_regions as TR
from trim_regions import crop, hp, lum, nrm_from_height, streaks, norm01
K=os.environ.get('IN_KIT','/workspace/coronado_kit_v2/_staging/house/kit')
SRC=K+'/props/_bake_src'; ATLP=K+'/atlases/props_atlas.json'
os.makedirs(SRC,exist_ok=True); os.makedirs(K+'/atlases',exist_ok=True)
SS=TR.SS; PAD=8; N=1024; TU=TV=112; PM=0.875
rng=np.random.default_rng(37)
S=TU*SS; ppm=S/PM
yy,xx=np.mgrid[0:S,0:S].astype(np.float32)
def wrapd(a,b,P):
    d=np.abs(a-b)%P; return np.minimum(d,P-d)
def _wblur(a,s):
    q=np.pad(a,((S,S),(S,S))+(((0,0),) if a.ndim==3 else ()),mode='wrap')
    return cv2.GaussianBlur(q,(0,0),s)[S:2*S,S:2*S]
blur=_wblur
def stdz(a):
    a=hp(a); return (a-a.mean())/(a.std()+1e-5)
def cav_ao(h,s=3.0,k=2.5):
    return np.clip(1-k*np.clip(blur(h,SS*s)-h,0,None),0.25,1)

def T_walnut():
    # Mid-century walnut: vertical planks, dark chocolate with warm figure, cathedral grain.
    nboard=4
    bw=PM/nboard
    u=xx/ppm; v=yy/ppm
    bi=np.floor(u/bw).astype(int)%nboard
    fu=(u%bw)/bw
    nse=rng.random((S,S)).astype(np.float32)
    q=np.pad(nse,((S,S),(S,S)),mode='wrap')
    fibre=stdz(cv2.GaussianBlur(q,(0,0),sigmaX=SS*0.45,sigmaY=SS*9.0)[S:2*S,S:2*S])
    pore=stdz(cv2.GaussianBlur(q,(0,0),sigmaX=SS*0.22,sigmaY=SS*2.2)[S:2*S,S:2*S])
    col=np.zeros((S,S,3),np.float32)
    h=np.zeros((S,S),np.float32)
    base=np.array([0.38,0.24,0.14],np.float32)
    dark=np.array([0.22,0.13,0.08],np.float32)
    for k in range(nboard):
        m=(bi==k)
        rng_k=np.random.default_rng(37+k*19)
        val=1+rng_k.uniform(-0.05,0.05)
        hue=np.array([1.0, rng_k.uniform(0.96,1.04), rng_k.uniform(0.90,1.00)],np.float32)
        ph=rng_k.uniform(0,2*np.pi); ph2=rng_k.uniform(0,2*np.pi)
        cx=(k+0.5)*bw
        cl=cx+(0.038*np.sin(v*(2*np.pi/(PM/2))+ph)+0.016*np.sin(v*(2*np.pi/PM)+ph2))
        dist=u-cl
        ring_ph=rng_k.uniform(0,2*np.pi)
        rings=np.sin(dist*(2*np.pi/0.018)+0.35*np.sin(v*(2*np.pi/(PM/2))+ring_ph))
        late=np.clip(rings,0,1)**1.6
        board=base[None,None,:]*hue[None,None,:]*val
        board=board*(1-0.40*late[...,None])+dark[None,None,:]*hue[None,None,:]*val*0.40*late[...,None]
        board=board*(1+0.06*fibre[...,None]-0.04*pore[...,None])
        col=np.where(m[...,None],np.clip(board,0,1),col)
        crown=np.sin(np.clip(fu,0,1)*np.pi)
        hk=0.10*crown-0.05*late+0.03*fibre-0.02*pore
        h=np.where(m,hk,h)
    gap=(np.minimum(fu,1-fu)*bw<0.0012).astype(np.float32)
    gap=blur(gap,SS*0.28)
    col=col*(1-gap[...,None]*0.45)
    h=h-gap*0.12
    ao=cav_ao(h,1.6,0.7)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.35),0.7),np.dstack([ao,np.full_like(h,0.48),np.zeros_like(h)])

def T_wash():
    # Whitewashed / beach oak: pale vertical boards, faint grain showing through wash.
    nboard=5
    bw=PM/nboard
    u=xx/ppm; v=yy/ppm
    bi=np.floor(u/bw).astype(int)%nboard
    fu=(u%bw)/bw
    nse=rng.random((S,S)).astype(np.float32)
    q=np.pad(nse,((S,S),(S,S)),mode='wrap')
    fibre=stdz(cv2.GaussianBlur(q,(0,0),sigmaX=SS*0.4,sigmaY=SS*8.0)[S:2*S,S:2*S])
    col=np.zeros((S,S,3),np.float32)
    h=np.zeros((S,S),np.float32)
    base=np.array([0.84,0.80,0.72],np.float32)
    grain=np.array([0.62,0.52,0.38],np.float32)
    for k in range(nboard):
        m=(bi==k)
        rng_k=np.random.default_rng(91+k*13)
        val=1+rng_k.uniform(-0.04,0.04)
        ph=rng_k.uniform(0,2*np.pi)
        rings=np.sin((u-(k+0.5)*bw)*(2*np.pi/0.022)+0.3*np.sin(v*(2*np.pi/PM)+ph))
        late=np.clip(rings,0,1)**1.4
        board=base*val
        board=board[None,None,:]*(1-0.22*late[...,None])+grain[None,None,:]*0.22*late[...,None]
        board=board*(1+0.04*fibre[...,None])
        # worn wash: slightly more grain near plank edges
        edge=np.clip(1-np.minimum(fu,1-fu)*8,0,1)
        board=board*(1-0.08*edge[...,None])+grain[None,None,:]*0.08*edge[...,None]
        col=np.where(m[...,None],np.clip(board,0,1),col)
        h=np.where(m,0.08*np.sin(np.clip(fu,0,1)*np.pi)+0.03*fibre-0.03*late,h)
    gap=(np.minimum(fu,1-fu)*bw<0.0010).astype(np.float32)
    gap=blur(gap,SS*0.25)
    col=col*(1-gap[...,None]*0.22)
    h=h-gap*0.10
    ao=cav_ao(h,1.4,0.6)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.35),0.6),np.dstack([ao,np.full_like(h,0.55),np.zeros_like(h)])

def T_paint():
    nse=stdz(blur(rng.random((S,S)).astype(np.float32),SS*0.5))
    mot=stdz(blur(rng.random((S,S)).astype(np.float32),SS*6.0))
    col=np.array([0.86,0.86,0.85],np.float32)[None,None,:]*(1+0.008*nse[...,None]+0.008*mot[...,None])
    h=nse*0.012
    ao=np.clip(0.97+0.03*mot,0.9,1)
    ro=np.clip(0.42+0.04*mot,0.3,0.55)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.5),0.5),np.dstack([ao,ro,np.zeros_like(h)])

def T_linen():
    # Tight plain-weave linen, light sand, tintable. Procedural, no photo crop.
    u=xx/ppm; v=yy/ppm
    thread=0.0016
    wx=np.abs((u/thread)%1-0.5)*2
    wy=np.abs((v/thread)%1-0.5)*2
    # basket: over/under
    over=((np.floor(u/thread).astype(int)+np.floor(v/thread).astype(int))%2==0).astype(np.float32)
    weave=np.where(over,wx*0.65+wy*0.35,wy*0.65+wx*0.35)
    nse=stdz(blur(rng.random((S,S)).astype(np.float32),SS*0.6))
    slub=stdz(blur(rng.random((S,S)).astype(np.float32),SS*3.5))
    col=np.array([0.80,0.76,0.68],np.float32)[None,None,:]*(0.96+0.08*weave[...,None]+0.03*nse[...,None]+0.03*slub[...,None])
    h=(weave-0.5)*0.20+nse*0.02+slub*0.03
    ao=cav_ao(h,1.0,0.7)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.25),0.9),np.dstack([ao,np.full_like(h,0.82),np.zeros_like(h)])

def T_metal():
    nse=blur(rng.random((S,S)).astype(np.float32),SS*0.45)
    st=streaks(TU,TV,22,n=48,width=(0.0008,0.003))
    st2=streaks(TU,TV,23,n=10,width=(0.006,0.016))
    base=np.array([0.70,0.72,0.74],np.float32)
    col=base[None,None,:]*(0.94+0.08*nse[...,None])
    col=col*(1-0.12*st[...,None])+np.array([0.86,0.87,0.88])*0.12*st[...,None]
    col=col*(1-0.06*st2[...,None])+np.array([0.60,0.61,0.63])*0.06*st2[...,None]
    h=st*0.07+st2*0.05+stdz(nse)*0.015
    ao=cav_ao(h,1.0,0.6)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.3),1.0),np.dstack([ao,np.full_like(h,0.20),np.full_like(h,0.92)])

def T_brass():
    nse=blur(rng.random((S,S)).astype(np.float32),SS*0.4)
    st=streaks(TU,TV,72,n=40,width=(0.0008,0.003)).T
    tarn=np.clip(stdz(blur(rng.random((S,S)).astype(np.float32),SS*5))-0.6,0,1)
    col=np.array([0.78,0.60,0.32],np.float32)[None,None,:]*(0.95+0.06*nse[...,None])
    col=col*(1-0.08*st[...,None])+np.array([0.92,0.78,0.50])*0.08*st[...,None]
    col=col*(1-0.12*tarn[...,None])+np.array([0.45,0.36,0.20])*0.12*tarn[...,None]
    h=st*0.05+stdz(nse)*0.01
    ao=cav_ao(h,1.0,0.5)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.3),0.8),np.dstack([ao,np.full_like(h,0.32),np.full_like(h,0.9)])

def T_ceramic():
    # Pale glazed ceramic, faint crackle and kiln mottle, tintable.
    nse=stdz(blur(rng.random((S,S)).astype(np.float32),SS*1.2))
    mot=stdz(blur(rng.random((S,S)).astype(np.float32),SS*7.0))
    # crackle: ridge of a thresholded noise
    cr=blur(rng.random((S,S)).astype(np.float32),SS*2.2)
    crack=np.clip(1-np.abs(cr-0.5)/(0.02),0,1)
    crack=blur(crack,SS*0.25)
    base=np.array([0.90,0.88,0.84],np.float32)
    col=base[None,None,:]*(1+0.03*nse[...,None]+0.04*mot[...,None])
    col=col*(1-0.10*crack[...,None])+np.array([0.70,0.66,0.60])*0.10*crack[...,None]
    h=nse*0.02+mot*0.015-crack*0.04
    ao=cav_ao(h,1.2,0.5)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.4),0.5),np.dstack([ao,np.full_like(h,0.22),np.zeros_like(h)])

def T_glass():
    base=np.array([0.48,0.54,0.58],np.float32)
    nse=blur(rng.random((S,S)).astype(np.float32),SS*2.0)
    st=streaks(TU,TV,51,n=5,width=(0.01,0.04))
    col=np.clip(base[None,None,:]*(0.90+0.12*nse[...,None])+np.array([0.62,0.66,0.70])*0.16*st[...,None],0,1)
    u=xx/S; v=yy/S
    band=0.5+0.5*np.sin((u+v)*2*np.pi*2)
    band2=np.clip(np.sin((u+v*1.0)*2*np.pi*1+0.6),0,1)**6
    col=col+np.array([0.10,0.12,0.13])*0.5*band[...,None]+np.array([0.30,0.32,0.34])*0.45*band2[...,None]
    # faint window reflection
    win=np.clip(1-np.maximum(np.abs(u-0.38)/0.18, np.abs(v-0.62)/0.14),0,1)
    col=col*(1-0.35*win[...,None])+np.array([0.82,0.88,0.94])*0.35*win[...,None]
    h=st*0.03+stdz(nse)*0.015
    ao=np.clip(0.94+0.06*nse,0.80,1)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.6),0.4),np.dstack([ao,np.full_like(h,0.08),np.full_like(h,0.72)])

def T_rattan():
    # Woven cane: hexagonal / open hexagonal weave baked as height + warm cane colour (holes painted dark, not cut out).
    u=xx/ppm; v=yy/ppm
    # hex grid
    sx,sy=0.018,0.016
    colx=u/sx; row=v/sy
    odd=(np.floor(row).astype(int)%2)*0.5
    fx=(colx+odd)%1; fy=row%1
    # distance to hex edge
    # approximate: three axis distances
    ax=np.abs(fx-0.5); ay=np.abs(fy-0.5)
    edge=np.minimum(np.minimum(ax,ay), np.abs(ax+ay*0.58-0.45))
    strand=np.clip(1-edge/0.12,0,1)
    hole=np.clip((edge-0.16)/0.10,0,1)
    nse=stdz(blur(rng.random((S,S)).astype(np.float32),SS*0.5))
    cane=np.array([0.84,0.68,0.42],np.float32)
    dark=np.array([0.48,0.34,0.20],np.float32)
    col=cane[None,None,:]*(0.94+0.08*nse[...,None])*strand[...,None]+dark[None,None,:]*hole[...,None]
    h=strand*0.22-hole*0.10+nse*0.02
    ao=cav_ao(h,1.4,0.9)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.3),1.0),np.dstack([ao,np.full_like(h,0.55),np.zeros_like(h)])

def T_stone():
    # Soft plaster / pale marble, tintable to terracotta or honed stone.
    nse=stdz(blur(rng.random((S,S)).astype(np.float32),SS*1.5))
    nse2=stdz(blur(rng.random((S,S)).astype(np.float32),SS*6.0))
    vein=0.5+0.5*np.sin((xx*0.35+yy*1.1)/S*2*np.pi*4 + 0.8*nse2)
    vein=np.clip(vein**6,0,1)
    base=np.array([0.86,0.84,0.80],np.float32)
    col=base[None,None,:]*(1+0.04*nse[...,None]+0.03*nse2[...,None])
    col=col*(1-0.16*vein[...,None])+np.array([0.70,0.68,0.64])*0.16*vein[...,None]
    h=nse*0.03+nse2*0.02-vein*0.02
    ao=cav_ao(h,1.5,0.5)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.5),0.5),np.dstack([ao,np.full_like(h,0.50),np.zeros_like(h)])

TILES=[
    ('th_walnut',0,0,T_walnut),
    ('th_wash',128,0,T_wash),
    ('th_paint',256,0,T_paint),
    ('th_linen',384,0,T_linen),
    ('th_metal',512,0,T_metal),
    ('th_brass',640,0,T_brass),
    ('th_ceramic',768,0,T_ceramic),
    ('th_glass',896,0,T_glass),
    ('th_rattan',0,128,T_rattan),
    ('th_stone',128,128,T_stone),
]

def blank_atlas():
    return {
        'size': {'color':1024,'normal':1024,'orm':1024},
        'size_h': {'color':1024,'normal':512,'orm':256},
        'pages': {'clean':'props_h_color_clean.png','worn':'props_h_color_clean.png','dirty':'props_h_color_clean.png'},
        'cell_m_per_px': 1.0/256.0,
        'conditions': ['clean','worn','dirty'],
        'bake_area': [0,256,1024,1024],
        'materials': {},
        'regions': {},
        'runtime_pages': {
            'h_clean':'props_h_color_clean.png',
            'h_normal':'props_h_normal.png',
            'h_orm':'props_h_orm.png'
        },
        'note': (
            'Page H house furniture and decor. Runtime 1024 colour / 512 normal / 256 ORM = 1.75 MB at ASTC 4x4 with mips. '
            'Streamed only with interiors; not counted in the 8 MB street props cap '
            '(pages A+B+C+grime+W stay at 7.583 MB). Never overwrite A/B/C/W or page I. '
            'House props ship near+col only (no mid/far).'
        ),
    }

SWATCHES=[
    ('walnut','th_walnut',(1.00,1.00,1.00)),
    ('teak','th_walnut',(1.15,0.95,0.70)),
    ('wash','th_wash',(1.00,1.00,1.00)),
    ('oak_light','th_wash',(1.05,0.98,0.88)),
    ('paint_cream','th_paint',(1.04,1.00,0.92)),
    ('paint_white','th_paint',(1.10,1.10,1.08)),
    ('paint_black','th_paint',(0.12,0.12,0.12)),
    ('paint_navy','th_paint',(0.12,0.16,0.32)),
    ('paint_mustard','th_paint',(0.90,0.68,0.16)),
    ('paint_olive','th_paint',(0.32,0.38,0.22)),
    ('paint_coral','th_paint',(0.78,0.32,0.28)),
    ('paint_aqua','th_paint',(0.40,0.62,0.62)),
    ('paint_sand','th_paint',(0.86,0.78,0.62)),
    ('paint_red','th_paint',(0.62,0.10,0.08)),
    ('paint_orange','th_paint',(0.95,0.42,0.06)),
    ('paint_grey','th_paint',(0.28,0.29,0.31)),
    ('linen','th_linen',(1.00,1.00,1.00)),
    ('linen_sand','th_linen',(1.05,0.98,0.85)),
    ('linen_olive','th_linen',(0.55,0.58,0.36)),
    ('linen_mustard','th_linen',(0.95,0.72,0.28)),
    ('steel','th_metal',(1.00,1.00,1.00)),
    ('chrome','th_metal',(1.15,1.16,1.18)),
    ('brass','th_brass',(1.00,1.00,1.00)),
    ('gilt','th_brass',(1.18,1.02,0.62)),
    ('ceramic','th_ceramic',(1.00,1.00,1.00)),
    ('ceramic_white','th_ceramic',(1.08,1.07,1.04)),
    ('ceramic_teal','th_ceramic',(0.35,0.55,0.52)),
    ('ceramic_coral','th_ceramic',(0.85,0.40,0.32)),
    ('ceramic_lava','th_ceramic',(0.22,0.14,0.12)),
    ('glass','th_glass',(1.00,1.00,1.00)),
    ('mirror','th_glass',(1.20,1.28,1.36)),
    ('rattan','th_rattan',(1.00,1.00,1.00)),
    ('stone','th_stone',(1.00,1.00,1.00)),
    ('plaster','th_stone',(1.06,1.04,0.98)),
    ('wax','th_paint',(1.08,1.04,0.92)),
    ('leather','th_walnut',(0.70,0.40,0.28)),
    ('paper','th_paint',(1.12,1.10,1.02)),
    ('spine_navy','th_paint',(0.14,0.16,0.32)),
    ('spine_red','th_paint',(0.50,0.12,0.10)),
    ('spine_green','th_paint',(0.18,0.32,0.22)),
    ('badge','th_brass',(1.05,0.98,0.80)),
    ('label','th_paint',(1.10,1.08,0.95)),
]

def blit_swatches(P, nor, orm, R):
    side=32
    x0,y0=256,128
    for i,(name,parent,tint) in enumerate(SWATCHES):
        col=i%24; row=i//24
        x=x0+col*(side)
        y=y0+row*(side)
        if x+side>N or y+side>192:
            print('swatch overflow',name,(x,y)); continue
        pr=R[parent+'.clean']['px']; px,py,pw,ph=pr
        src=P['clean'][py+8:py+8+side, px+8:px+8+side,:3].astype(np.float32)/255.0
        src=np.clip(src*np.array(tint,np.float32),0,1)
        c8=(src*255+0.5).astype(np.uint8)
        for c in P:
            P[c][y:y+side,x:x+side,:3]=c8; P[c][y:y+side,x:x+side,3]=255
        nor[y:y+side,x:x+side]=nor[py+8:py+8+side, px+8:px+8+side]
        orm[y:y+side,x:x+side]=orm[py+8:py+8+side, px+8:px+8+side]
        for c in ('clean','worn','dirty'):
            R[f'{name}.{c}']={'px':[x,y,side,side],'uv':[x/N,y/N,(x+side)/N,(y+side)/N],'m':[0.25,0.25],'trim':False,'page':'h','tile_px':side}
        print('swatch',name,(x,y))

def main():
    A=blank_atlas(); R={}
    A['regions']=R
    P={c:np.full((N,N,4),(128,128,128,255),np.uint8) for c in ('clean','worn','dirty')}
    nor=np.full((N,N,3),(128,128,255),np.uint8); orm=np.full((N,N,3),(255,200,0),np.uint8)
    dn=lambda a: cv2.resize(a.astype(np.float32),(TU,TV),interpolation=cv2.INTER_AREA)
    pad=lambda a: np.pad(a,((PAD,PAD),(PAD,PAD))+(((0,0),) if a.ndim==3 else ()),mode='wrap')
    for name,x,y,fn in TILES:
        col,nr,om=fn(); w=h=TU+2*PAD
        c8=(np.clip(pad(dn(col)),0,1)*255+0.5).astype(np.uint8)
        for c in P: P[c][y:y+h,x:x+w,:3]=c8; P[c][y:y+h,x:x+w,3]=255
        nor[y:y+h,x:x+w]=(np.clip(pad(dn(nr)),0,1)*255+0.5).astype(np.uint8)
        orm[y:y+h,x:x+w]=(np.clip(pad(dn(om)),0,1)*255+0.5).astype(np.uint8)
        for c in ('clean','worn','dirty'):
            R[f'{name}.{c}']={'px':[x,y,w,h],'uv':[(x+PAD)/N,(y+PAD)/N,(x+PAD+TU)/N,(y+PAD+TV)/N],'m':[PM,PM],'trim':True,'page':'h','tile_px':TU}
        print('tile',name,(x,y),'mean',np.round(col.reshape(-1,3).mean(0),3), flush=True)
    blit_swatches(P,nor,orm,R)
    for c in P: Image.fromarray(P[c]).save(f'{SRC}/props_h_base_color_{c}.png')
    Image.fromarray(nor).save(f'{SRC}/props_h_base_normal.png'); Image.fromarray(orm).save(f'{SRC}/props_h_base_orm.png')
    for c in P: Image.fromarray(P[c]).save(f'{SRC}/props_src_color_{c}.png')
    Image.fromarray(nor).save(f'{SRC}/props_src_normal.png'); Image.fromarray(orm).save(f'{SRC}/props_src_orm.png')
    t=ATLP+'.tmp'; json.dump(A,open(t,'w'),indent=1); os.replace(t,ATLP)
    print('wrote',ATLP,'base + src pages in',SRC)

if __name__=='__main__':
    main()
