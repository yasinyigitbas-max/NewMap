"""Page I (indoor) base atlas: tiling trim tiles at 128 px/m (inner 112 px = 0.875 m, 8 px wrap pad).
Writes only props_i_* under the indoor kit. Never touches atlases A/B/C/W.

Tiles (row y=0): ti_wood, ti_laminate, ti_metal, ti_paint, ti_fabric, ti_glass, ti_plastic, ti_brass
Row y=128 reserved for later tiles. Bake slots start at y=256.

Run: python3 tools/i_trims.py && IN_KIT=... python3 kit/props/_tools/props_compose.py i
"""
import json, os, sys, numpy as np, cv2
from PIL import Image
sys.path.insert(0,'/workspace/coronado_kit_v2/props/_tools')
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import trim_regions as TR
from trim_regions import crop, hp, lum, nrm_from_height, streaks, norm01
K=os.environ.get('IN_KIT','/workspace/coronado_kit_v2/_staging/indoor/kit')
SRC=K+'/props/_bake_src'; ATLP=K+'/atlases/props_atlas.json'
os.makedirs(SRC,exist_ok=True); os.makedirs(K+'/atlases',exist_ok=True)
SS=TR.SS; PAD=8; N=1024; TU=TV=112; PM=0.875
rng=np.random.default_rng(21)
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
def tone(c,base,amt=0.08):
    l=stdz(lum(c)); return np.clip(np.asarray(base,np.float32)[None,None,:]*(1+amt*l[...,None]),0,1)
def cav_ao(h,s=3.0,k=2.5):
    return np.clip(1-k*np.clip(blur(h,SS*s)-h,0,None),0.25,1)

def T_wood():
    # Furniture oak: vertical planks, grain running along V (up the panel).
    # Cathedral figure and pores — not OSB / strand-board (no horizontal flake streaks).
    nboard=4
    bw=PM/nboard
    u=xx/ppm; v=yy/ppm
    bi=np.floor(u/bw).astype(int)%nboard
    fu=(u%bw)/bw
    # fine axial pores / fibre: long along V, short along U
    nse=rng.random((S,S)).astype(np.float32)
    q=np.pad(nse,((S,S),(S,S)),mode='wrap')
    fibre=stdz(cv2.GaussianBlur(q,(0,0),sigmaX=SS*0.45,sigmaY=SS*9.0)[S:2*S,S:2*S])
    pore=stdz(cv2.GaussianBlur(q,(0,0),sigmaX=SS*0.22,sigmaY=SS*2.2)[S:2*S,S:2*S])
    col=np.zeros((S,S,3),np.float32)
    h=np.zeros((S,S),np.float32)
    # mid oak, slightly golden, not orange, not muddy
    base=np.array([0.55,0.38,0.21],np.float32)
    dark=np.array([0.38,0.24,0.13],np.float32)
    for k in range(nboard):
        m=(bi==k)
        rng_k=np.random.default_rng(21+k*17)
        val=1+rng_k.uniform(-0.06,0.05)
        hue=np.array([1.0, rng_k.uniform(0.96,1.04), rng_k.uniform(0.92,1.02)],np.float32)
        # cathedral centreline, periods that tile in V (PM and PM/2)
        ph=rng_k.uniform(0,2*np.pi)
        ph2=rng_k.uniform(0,2*np.pi)
        cx=(k+0.5)*bw
        cl=cx+(0.038*np.sin(v*(2*np.pi/(PM/2))+ph)
               +0.016*np.sin(v*(2*np.pi/PM)+ph2))
        dist=u-cl
        # growth rings (latewood darker, thinner). Period tiles across a board width enough to vary.
        ring_ph=rng_k.uniform(0,2*np.pi)
        rings=np.sin(dist*(2*np.pi/0.020)+0.35*np.sin(v*(2*np.pi/(PM/2))+ring_ph))
        late=np.clip(rings,0,1)**1.6
        board=base[None,None,:]*hue[None,None,:]*val
        board=board*(1-0.34*late[...,None])+dark[None,None,:]*hue[None,None,:]*val*0.34*late[...,None]
        board=board*(1+0.06*fibre[...,None]-0.04*pore[...,None])
        col=np.where(m[...,None],np.clip(board,0,1),col)
        # slight crown on each plank + ring micro-height + pores
        crown=np.sin(np.clip(fu,0,1)*np.pi)
        hk=0.10*crown-0.05*late+0.03*fibre-0.02*pore
        h=np.where(m,hk,h)
    # visible tight plank seams (vertical)
    gap=(np.minimum(fu,1-fu)*bw<0.0012).astype(np.float32)
    gap=blur(gap,SS*0.28)
    col=col*(1-gap[...,None]*0.38)
    # a hair darker along the seam
    col=col*(1-gap[...,None]*np.array([0.02,0.03,0.04],np.float32))
    h=h-gap*0.60
    ao=cav_ao(h,1.6,0.85)
    ro=np.clip(0.44+0.07*fibre-0.12*gap,0.22,0.68)
    nrm=nrm_from_height(blur(h,SS*0.35),1.20)
    return np.clip(col,0,1),nrm,np.dstack([ao,ro,np.zeros_like(h)])

def T_laminate():
    # pale quartz / solid-surface laminate: fine mineral speckles, slight gloss, no concrete grain
    nse=blur(rng.random((S,S)).astype(np.float32),SS*0.35)
    nse2=blur(rng.random((S,S)).astype(np.float32),SS*1.2)
    col=np.array([0.90,0.87,0.80],np.float32)[None,None,:]*(0.97+0.05*nse[...,None])
    # sparse darker mineral flecks
    fleck=(rng.random((S,S)).astype(np.float32)<0.012).astype(np.float32)
    fleck=blur(fleck,SS*0.25)
    col=np.clip(col*(1-0.18*fleck[...,None])+np.array([0.62,0.58,0.50])*0.18*fleck[...,None],0,1)
    # very faint warm veins
    vein=0.5+0.5*np.sin((xx*0.7+yy*0.15)/S*2*np.pi*3 + 0.4*nse2*2)
    col=col*(1-0.03*vein[...,None])+np.array([0.84,0.80,0.72])*0.03*vein[...,None]
    h=stdz(nse)*0.02+fleck*0.04
    ao=cav_ao(h,1.2,0.6)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.4),0.6),np.dstack([ao,np.full_like(h,0.26),np.zeros_like(h)])

def T_metal():
    # fine brushed stainless, procedural. Do not use metal_plate — that PH set is diamond plate.
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

def T_paint():
    # smooth satin enamel (vertex-tintable, authored light grey): faint orange peel and roller mottle only.
    # No concrete photo (it read as plaster / concrete and showed a seam).
    nse=stdz(blur(rng.random((S,S)).astype(np.float32),SS*0.5))
    mot=stdz(blur(rng.random((S,S)).astype(np.float32),SS*6.0))
    col=np.array([0.86,0.86,0.85],np.float32)[None,None,:]*(1+0.008*nse[...,None]+0.008*mot[...,None])
    h=nse*0.012
    ao=np.clip(0.97+0.03*mot,0.9,1)
    ro=np.clip(0.42+0.04*mot,0.3,0.55)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.5),0.5),np.dstack([ao,ro,np.zeros_like(h)])

def T_fabric():
    # tight woven upholstery, light neutral for tint
    c=crop('denim_fabric',PM*0.35,PM*0.35,TU,TV,41)
    col=tone(c,[0.78,0.76,0.72],0.08)
    weave=stdz(lum(c))
    h=weave*0.25
    ao=cav_ao(h,1.0,0.8)
    return col,nrm_from_height(blur(h,SS*0.3),0.9),np.dstack([ao,np.full_like(h,0.82),np.zeros_like(h)])

def T_glass():
    # Opaque kit glass / mirror: cool mid grey-blue with a readable interior reflection.
    # Never a black void, never transparent. Light enough to read as glass in shadow.
    base=np.array([0.48,0.54,0.58],np.float32)
    nse=blur(rng.random((S,S)).astype(np.float32),SS*2.0)
    st=streaks(TU,TV,51,n=5,width=(0.01,0.04))
    col=np.clip(base[None,None,:]*(0.90+0.12*nse[...,None])+np.array([0.62,0.66,0.70])*0.16*st[...,None],0,1)
    u=xx/S; v=yy/S
    # soft periodic diagonal reflection bands (tile in u and v) and a faint lighter top
    band=0.5+0.5*np.sin((u+v)*2*np.pi*2)
    band2=np.clip(np.sin((u+v*1.0)*2*np.pi*1+0.6),0,1)**6
    col=col+np.array([0.10,0.12,0.13])*0.5*band[...,None]+np.array([0.30,0.32,0.34])*0.45*band2[...,None]
    h=st*0.03+stdz(nse)*0.015
    ao=np.clip(0.94+0.06*nse,0.80,1)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.6),0.4),np.dstack([ao,np.full_like(h,0.08),np.full_like(h,0.72)])

def T_plastic():
    # smooth injection ABS: faint flow lines and a few ejector dimples, no tile grid
    nse=blur(rng.random((S,S)).astype(np.float32),SS*0.8)
    flow=streaks(TU,TV,61,n=6,width=(0.02,0.06))
    col=np.array([0.80,0.80,0.78],np.float32)[None,None,:]*(0.97+0.05*nse[...,None])
    col=col*(1-0.04*flow[...,None])
    h=stdz(nse)*0.02+flow*0.015
    for i in range(6):
        px=rng.uniform(0,S); py=rng.uniform(0,S); r=0.005*ppm
        d=np.sqrt(wrapd(xx,px,S)**2+wrapd(yy,py,S)**2)
        ring=np.clip(1-np.abs(d-r*0.55)/(0.0010*ppm),0,1)
        h-=ring*0.20
    ao=cav_ao(h,1.2,0.6)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.4),0.6),np.dstack([ao,np.full_like(h,0.38),np.zeros_like(h)])

def T_brass():
    # satin brushed brass, horizontal brushing, light tarnish (procedural; the metal_plate crop read as gold foil)
    nse=blur(rng.random((S,S)).astype(np.float32),SS*0.4)
    st=streaks(TU,TV,72,n=40,width=(0.0008,0.003)).T
    tarn=np.clip(stdz(blur(rng.random((S,S)).astype(np.float32),SS*5))-0.6,0,1)
    col=np.array([0.78,0.60,0.32],np.float32)[None,None,:]*(0.95+0.06*nse[...,None])
    col=col*(1-0.08*st[...,None])+np.array([0.92,0.78,0.50])*0.08*st[...,None]
    col=col*(1-0.12*tarn[...,None])+np.array([0.45,0.36,0.20])*0.12*tarn[...,None]
    h=st*0.05+stdz(nse)*0.01
    ao=cav_ao(h,1.0,0.5)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.3),0.8),np.dstack([ao,np.full_like(h,0.32),np.full_like(h,0.9)])

TILES=[
    ('ti_wood',0,0,T_wood),
    ('ti_laminate',128,0,T_laminate),
    ('ti_metal',256,0,T_metal),
    ('ti_paint',384,0,T_paint),
    ('ti_fabric',512,0,T_fabric),
    ('ti_glass',640,0,T_glass),
    ('ti_plastic',768,0,T_plastic),
    ('ti_brass',896,0,T_brass),
]

def blank_atlas():
    return {
        'size': {'color':1024,'normal':1024,'orm':1024},
        'size_i': {'color':1024,'normal':512,'orm':256},
        'pages': {'clean':'props_i_color_clean.png','worn':'props_i_color_clean.png','dirty':'props_i_color_clean.png'},
        'cell_m_per_px': 1.0/256.0,
        'conditions': ['clean','worn','dirty'],
        'bake_area': [0,256,1024,1024],
        'materials': {},
        'regions': {},
        'runtime_pages': {
            'i_clean':'props_i_color_clean.png',
            'i_normal':'props_i_normal.png',
            'i_orm':'props_i_orm.png'
        },
        'note': (
            'Page I indoor props. Runtime 1024 colour / 512 normal / 256 ORM = 1.75 MB at ASTC 4x4 with mips. '
            'Streamed only with interiors; not counted in the 8 MB street props cap '
            '(pages A+B+C+grime+W stay at 7.583 MB). Never overwrite A/B/C/W. Indoor props ship near+col only (no mid/far).'
        ),
    }


# Per-key source swatches (row y=128): tinted crops of the parent tile, used by the high-poly bake.
# Low-poly tiling still uses the ti_* trim regions via the builder TRIM map.
SWATCHES=[
    # name, parent tile, rgb tint
    ('oak','ti_wood',(1.00,0.96,0.90)),
    ('walnut','ti_wood',(0.62,0.45,0.32)),
    ('lam','ti_laminate',(1.0,0.97,0.90)),
    ('steel','ti_metal',(1.0,1.0,1.0)),
    ('chrome','ti_metal',(1.15,1.16,1.18)),
    ('alum','ti_metal',(0.95,0.95,0.97)),
    ('brass','ti_brass',(1.0,1.0,1.0)),
    ('paint_cream','ti_paint',(1.0,0.96,0.88)),
    ('paint_black','ti_paint',(0.12,0.12,0.12)),
    ('paint_navy','ti_paint',(0.16,0.20,0.38)),
    ('fabric','ti_fabric',(0.55,0.22,0.18)),
    ('glass','ti_glass',(1.0,1.0,1.0)),
    ('plastic','ti_plastic',(0.92,0.92,0.90)),
    ('plastic_black','ti_plastic',(0.12,0.12,0.13)),
    ('rubber','ti_plastic',(0.10,0.10,0.10)),
    ('ceramic','ti_paint',(0.82,0.28,0.18)),
    ('leaf','ti_paint',(0.22,0.42,0.20)),
    ('soil','ti_paint',(0.22,0.16,0.10)),
    ('badge','ti_brass',(1.05,0.9,0.55)),
    ('screen','ti_glass',(0.7,1.1,1.4)),
    ('label','ti_paint',(1.15,1.12,1.02)),
    ('keypad','ti_plastic',(0.15,0.16,0.18)),
    ('goods','ti_paint',(0.85,0.55,0.30)),
    ('menu','ti_paint',(1.1,1.05,0.92)),
    ('mirror','ti_glass',(1.8,2.0,2.2)),
]

def blit_swatches(P, nor, orm, R):
    # parent tile pixels already in P/nor/orm at their px rects
    side=32
    for i,(name,parent,tint) in enumerate(SWATCHES):
        x= (i*40) % 1024
        y= 128 + 40*((i*40)//1024)
        pr=R[parent+'.clean']['px']; px,py,pw,ph=pr
        # take inner 32 of the parent tile
        src=P['clean'][py+8:py+8+side, px+8:px+8+side,:3].astype(np.float32)/255.0
        src=np.clip(src*np.array(tint,np.float32),0,1)
        # paper / screen extra marks
        if name=='screen':
            yy,xx=np.mgrid[0:side,0:side]
            src=src*0.4+np.array([0.15,0.45,0.55],np.float32)*(0.3+0.2*np.sin(yy/3.0))[...,None]
            src=np.clip(src,0,1)
        if name=='menu':
            # faint ruled lines
            src[::6,:,:]=np.clip(src[::6,:,:]*0.7,0,1)
        if name=='goods':
            # bottle-like vertical bands
            for k in range(0,side,6):
                src[:,k:k+3]=np.clip(src[:,k:k+3]*np.array([0.6,0.8,1.1]),0,1)
        if name=='mirror':
            yy,xx=np.mgrid[0:side,0:side]
            grad=0.70+0.30*(yy/side)
            src=np.clip(np.array([0.62,0.70,0.76],np.float32)*grad[...,None]
                        +np.array([0.22,0.24,0.26])*0.35*np.sin(xx/5.0)[...,None],0,1)
            # faint bright window in the upper half
            win=np.clip(1-np.maximum(np.abs(xx-side/2)/(side*0.28), np.abs(yy-side*0.38)/(side*0.18)),0,1)
            src=src*(1-0.4*win[...,None])+np.array([0.82,0.88,0.94])*0.4*win[...,None]
        c8=(src*255+0.5).astype(np.uint8)
        for c in P:
            P[c][y:y+side,x:x+side,:3]=c8; P[c][y:y+side,x:x+side,3]=255
        nor[y:y+side,x:x+side]=nor[py+8:py+8+side, px+8:px+8+side]
        orm[y:y+side,x:x+side]=orm[py+8:py+8+side, px+8:px+8+side]
        for c in ('clean','worn','dirty'):
            R[f'{name}.{c}']={'px':[x,y,side,side],'uv':[x/N,(y)/N,(x+side)/N,(y+side)/N],'m':[0.25,0.25],'trim':False,'page':'i','tile_px':side}
        print('swatch',name,(x,y))

def main():
    A=json.load(open(ATLP)) if os.path.exists(ATLP) else blank_atlas()
    R={}
    A=blank_atlas(); A['regions']=R
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
            R[f'{name}.{c}']={'px':[x,y,w,h],'uv':[(x+PAD)/N,(y+PAD)/N,(x+PAD+TU)/N,(y+PAD+TV)/N],'m':[PM,PM],'trim':True,'page':'i','tile_px':TU}
        print('tile',name,(x,y),'mean',np.round(col.reshape(-1,3).mean(0),3), flush=True)
    blit_swatches(P,nor,orm,R)
    import i_goods
    for k,(gname,kind,seed) in enumerate(i_goods.BANDS):
        gc,gn,go=i_goods.band(kind,seed); y=160+32*k
        for c in P: P[c][y:y+32,:,:3]=(gc*255+0.5).astype(np.uint8); P[c][y:y+32,:,3]=255
        nor[y:y+32,:]=(np.clip(gn,0,1)*255+0.5).astype(np.uint8); orm[y:y+32,:]=(np.clip(go,0,1)*255+0.5).astype(np.uint8)
        for c in ('clean','worn','dirty'):
            R[f'{gname}.{c}']={'px':[0,y,1024,32],'uv':[0.0,(y+1)/N,1.0,(y+31)/N],'m':[8.0,0.25],'trim':True,'page':'i','tile_px':128,'goods':True}
        print('goods band',gname,y)
    for c in P: Image.fromarray(P[c]).save(f'{SRC}/props_i_base_color_{c}.png')
    Image.fromarray(nor).save(f'{SRC}/props_i_base_normal.png'); Image.fromarray(orm).save(f'{SRC}/props_i_base_orm.png')
    # high-poly bake source (1024 working size, not the shipped 512/256 maps)
    for c in P: Image.fromarray(P[c]).save(f'{SRC}/props_src_color_{c}.png')
    Image.fromarray(nor).save(f'{SRC}/props_src_normal.png'); Image.fromarray(orm).save(f'{SRC}/props_src_orm.png')
    t=ATLP+'.tmp'; json.dump(A,open(t,'w'),indent=1); os.replace(t,ATLP)
    print('wrote',ATLP,'base + src pages in',SRC)

if __name__=='__main__':
    main()
