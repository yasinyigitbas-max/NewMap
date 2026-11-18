"""Props page W (waterfront) base page: tiling trim tiles at 128 px/m (inner 112 px = 0.875 m, 8 px wrap pad), plus the
far-tier flat swatch. Height fields (boards, gaps, nail heads, tie holes, barnacles, checks, joints) are the high-poly
detail: normal and AO come from them, colour from the CC0 Poly Haven photos already credited in CREDITS_props.md.
Writes <WF_KIT>/props/_bake_src/props_w_base_{color_clean,color_worn,color_dirty,normal,orm}.png and registers the
regions (page 'w') in <WF_KIT>/atlases/props_atlas.json.   Run: python3 wf_trims.py && python3 props_compose.py w"""
import json, os, sys, numpy as np, cv2
from PIL import Image
sys.path.insert(0,'/workspace/coronado_kit_v2/props/_tools')
import trim_regions as TR
from trim_regions import crop, hp, lum, nrm_from, nrm_from_height, blendn, streaks, norm01
K=os.environ.get('WF_KIT','/workspace/coronado_kit_v2/_staging/waterfront/kit'); SRC=K+'/props/_bake_src'; ATLP=K+'/atlases/props_atlas.json'
SS=TR.SS; PAD=8; N=1024; TU=TV=112; PM=0.875
rng=np.random.default_rng(11)
S=TU*SS; ppm=S/PM
yy,xx=np.mgrid[0:S,0:S].astype(np.float32)
def wrapd(a,b,P): d=np.abs(a-b)%P; return np.minimum(d,P-d)
def blur(a,s): return cv2.GaussianBlur(a.astype(np.float32),(0,0),s,borderType=cv2.BORDER_WRAP) if hasattr(cv2,'BORDER_WRAP') else _wblur(a,s)
def _wblur(a,s):
    q=np.pad(a,((S,S),(S,S))+(((0,0),) if a.ndim==3 else ()),mode='wrap'); return cv2.GaussianBlur(q,(0,0),s)[S:2*S,S:2*S]
blur=_wblur
def stdz(a): a=hp(a); return (a-a.mean())/(a.std()+1e-5)
def tone(c,base,amt=0.08):
    l=stdz(lum(c)); return np.clip(np.asarray(base,np.float32)[None,None,:]*(1+amt*l[...,None]),0,1)
def cav_ao(h,s=3.0,k=2.5):
    return np.clip(1-k*np.clip(blur(h,SS*s)-h,0,None),0.25,1)
def nails(cx_list, cy_list, r_m=0.006):
    m=np.zeros((S,S),np.float32)
    for cx in cx_list:
        for cy in cy_list:
            d=np.sqrt(wrapd(xx,cx*ppm,S)**2+wrapd(yy,cy*ppm,S)**2); m=np.maximum(m,np.clip(1-d/(r_m*ppm),0,1))
    return m
def T_deck(variant='grey'):
    # 6 boards across v (140 mm + 6 mm gaps), grain along u, nail pairs at the joists (u = 0 and 0.4375 m)
    bw=PM/6; v=yy/ppm; bi=np.floor(v/bw).astype(int); fv=(v%bw)/bw
    src='wood_planks_grey' if variant=='grey' else 'weathered_brown_planks'
    g=crop(src,PM,PM,TU,TV,3+(variant!='grey')*10)
    col=np.zeros((S,S,3),np.float32)
    for k in range(6):
        sh=np.roll(g,int(rng.integers(0,S)),1); t=1+rng.uniform(-0.10,0.10); m=(bi==k)[...,None]
        col=np.where(m,sh*t,col)
    base=np.array([0.62,0.60,0.56] if variant=='grey' else [0.58,0.50,0.42],np.float32)
    col=np.clip(base*(1+0.22*stdz(lum(col))[...,None]),0,1)*np.where((bi%2==0)[...,None],1.0,0.95)
    gap=(np.minimum(fv,1-fv)*bw<0.003).astype(np.float32)
    crown=np.sin(np.clip(fv,0,1)*np.pi)**0.5*0.6
    grain=stdz(lum(crop(src,PM,PM,TU,TV,5,name='diffuse.jpg')))*0.08
    nm=np.zeros((S,S),np.float32)
    for ju in (0.0,PM/2):
        for k in range(6):
            for o in (0.028,bw-0.028): nm=np.maximum(nm,nails([ju+0.02*(k%2)],[k*bw+o]))
    h=crown*(1-gap)-gap*1.5+grain+nm*0.25
    rustb=np.clip(blur(nm,SS*2.5)*2.2,0,1)
    col=col*(1-gap[...,None]*0.85)+0.0
    col=col*(1-0.35*rustb[...,None])+np.array([0.35,0.22,0.12])*0.35*rustb[...,None]
    col=np.where(nm[...,None]>0.3,np.array([0.30,0.28,0.26]),col)
    ao=cav_ao(h,2.0,1.2)*(1-0.6*gap)
    ro=np.clip(0.86+0.05*grain-0.2*nm,0,1); me=nm*0.6
    return col,nrm_from_height(blur(h,SS*0.6),2.2),np.dstack([ao,ro,me])
def T_timber():
    # heavy weathered timber, grain along v (pile / beam length), drying checks, creosote-brown greyed
    c=crop('weathered_brown_planks',PM,PM,TU,TV,21); c=np.transpose(c,(1,0,2))
    col=tone(c,[0.46,0.40,0.33],0.22)
    h=stdz(lum(c))*0.12
    for k in range(5):   # checks: long thin cracks along v
        x=rng.uniform(0,S); w=rng.uniform(0.0015,0.0035)*ppm; y0=rng.uniform(0,S); L=rng.uniform(0.25,0.7)*ppm
        d=wrapd(xx,x+3*np.sin(yy/S*2*np.pi*rng.integers(1,3)),S); along=wrapd(yy,y0,S)<L/2
        m=(np.clip(1-d/w,0,1)*along).astype(np.float32); h-=m*1.2; col*=1-0.6*m[...,None]
    grey=norm01(blur(rng.random((S,S)).astype(np.float32),SS*6)); col=col*(1-0.25*grey[...,None])+np.array([0.62,0.60,0.56])*0.25*grey[...,None]
    ao=cav_ao(h,2.0,1.5); return col,nrm_from_height(blur(h,SS*0.6),1.8),np.dstack([ao,np.full_like(h,0.9),np.zeros_like(h)])
def T_conc(top_streaks=False):
    # cast concrete wall face: horizontal form-panel joint at v=0, two snap-tie holes (plugged), pitting, rust streaks below ties
    c=crop('concrete_floor_02',PM,PM,TU,TV,31); d=crop('dirty_concrete',PM,PM,TU,TV,32)
    col=tone(c,[0.66,0.65,0.62],0.07)*(0.9+0.1*norm01(lum(d)))[...,None]
    h=stdz(lum(crop('concrete_floor_02',PM,PM,TU,TV,31,gray=True,name='displacement.jpg')))*0.05
    j=(wrapd(yy,0,S)<0.004*ppm).astype(np.float32); h-=j*0.8
    ties=nails([0.22,0.655],[0.44],0.014); h-=ties*0.7
    st=np.zeros((S,S),np.float32)
    for tx in (0.22,0.655):
        w_=0.010*ppm; dx=wrapd(xx,tx*ppm,S); below=((yy-0.44*ppm)%S)/S   # image rows grow downwards = v grows; streak under the tie (towards lower v is up?)
        st+=np.exp(-(dx/w_)**2)*np.clip(1-((0.44*ppm-yy)%S)/(0.35*ppm),0,1)
    col=col*(1-0.25*st[...,None])+np.array([0.48,0.36,0.24])*0.25*st[...,None]
    col=col*(1-0.5*ties[...,None]); col=col*(1-0.35*j[...,None])
    if top_streaks:
        vv=yy/S   # 0 = top edge (under the coping), 1 = bottom edge (high-water line)
        dr=streaks(TU,TV,35,n=11,width=(0.006,0.025))*np.clip(1-vv*1.3,0,1)**1.5
        col=col*(1-0.30*dr[...,None])+np.array([0.40,0.37,0.33])*0.0
        ef=np.clip(1-vv/0.10,0,1)*norm01(blur(rng.random((S,S)).astype(np.float32),SS*2))
        col=col*(1-0.25*ef[...,None])+np.array([0.86,0.85,0.80])*0.25*ef[...,None]   # efflorescence under the coping
        wet=np.clip((vv-0.62)/0.38,0,1)**1.2*(0.75+0.25*norm01(blur(rng.random((S,S)).astype(np.float32),SS*2)))
        col=col*(1-0.50*wet[...,None])+np.array([0.29,0.30,0.25])*0.50*wet[...,None]     # wet foot / splash zone
        gr=np.clip((vv-0.88)/0.12,0,1)*norm01(blur(rng.random((S,S)).astype(np.float32),SS))
        col=col*(1-0.35*gr[...,None])+np.array([0.24,0.30,0.17])*0.35*gr[...,None]       # green film at the spray line
        h=h-0.15*wet*norm01(blur(rng.random((S,S)).astype(np.float32),SS))
    ao=cav_ao(h,2.5,2.0); return col,nrm_from_height(blur(h,SS*0.5),1.6),np.dstack([ao,np.full_like(h,0.9),np.zeros_like(h)])
def T_tide(upper=False):
    # tide-zone concrete: dark wet, green-brown algae, barnacle clusters (height cones), periodic
    c=crop('concrete_moss',PM,PM,TU,TV,41); c=c*0.5+np.dstack([lum(c)]*3)*0.5; col=tone(c,[0.43,0.43,0.37],0.25)
    h=stdz(lum(crop('concrete_moss',PM,PM,TU,TV,41,gray=True,name='displacement.jpg')))*0.1
    bm=np.zeros((S,S),np.float32)
    cl=rng.uniform(0,S,(6,2))
    for i in range(260):
        cx,cy=cl[rng.integers(0,6)]+rng.normal(0,0.06*ppm,2); r=rng.uniform(0.004,0.011)*ppm
        d=np.sqrt(wrapd(xx,cx%S,S)**2+wrapd(yy,cy%S,S)**2); cone=np.clip(1-d/r,0,1); bm=np.maximum(bm,cone**0.7)
    hole=(bm>0.85).astype(np.float32)
    h=h+bm*0.9-hole*0.5
    col=col*(1-0.8*np.clip(bm*1.5,0,1)[...,None])+np.array([0.74,0.72,0.64])*0.8*np.clip(bm*1.5,0,1)[...,None]
    col=col*(1-0.7*hole[...,None])
    if upper:   # barnacle band: thins out upwards and blends into wet concrete at the top edge (= high-water line)
        vv=yy/S   # 0 = top edge (z 1.75 = high-water line), 1 = bottom (z 0.875); still water WL 1.5 sits at vv 0.29
        nz=norm01(blur(rng.random((S,S)).astype(np.float32),SS*1.5))
        edge=0.20+0.07*(nz-0.5)                                   # ragged upper limit of the barnacle crust
        dry=np.clip((edge-vv)/0.03,0,1)
        wc=tone(crop('concrete_floor_02',PM,PM,TU,TV,31),[0.66,0.65,0.62],0.07)*0.45+np.array([0.27,0.27,0.23])*0.55
        sl=np.exp(-((vv-edge-0.02)/0.045)**2)                       # green-black slime fringe just under the tide line
        col=col*(1-0.55*sl[...,None])+np.array([0.13,0.17,0.09])*0.55*sl[...,None]
        salt=np.exp(-((vv-edge+0.035)/0.012)**2)*(0.6+0.4*nz)       # dried salt / tide mark just above it
        col=col*(1-dry[...,None])+wc*dry[...,None]; h=h*(1-dry)
        col=col*(1-0.35*salt[...,None])+np.array([0.80,0.79,0.73])*0.35*salt[...,None]
    else:
        col=col*0.82+np.array([0.20,0.24,0.16])*0.18
    ao=cav_ao(h,2.0,2.0); ro=np.clip(0.45+0.4*bm,0,1)   # wet = glossier
    return col,nrm_from_height(blur(h,SS*0.5),2.4),np.dstack([ao,ro,np.zeros_like(h)])
def T_granite():
    c=crop('rock_boulder_dry',PM*0.6,PM*0.6,TU,TV,51); c=np.dstack([lum(c)]*3); col=tone(c,[0.62,0.61,0.60],0.16)
    sp=(rng.random((S,S))>0.93).astype(np.float32); col=col*(1-0.25*sp[...,None])
    j=(wrapd(xx,0,S)<0.004*ppm).astype(np.float32)   # stone joint every 0.875 m along u
    h=stdz(lum(c))*0.05-j*1.0; col=col*(1-0.45*j[...,None])+np.array([0.5,0.49,0.47])*0.0
    ao=cav_ao(h,2.0,2.0); return col,nrm_from_height(blur(h,SS*0.5),1.6),np.dstack([ao,np.full_like(h,0.75),np.zeros_like(h)])
def T_paver():
    c=crop('concrete_floor_02',PM,PM,TU,TV,61); col=tone(c,[0.70,0.68,0.64],0.08)
    P=PM/2; jx=(wrapd(xx,0,S)%(P*ppm)); jx=np.minimum(jx,P*ppm-jx); jy=(yy%(P*ppm)); jy=np.minimum(jy,P*ppm-jy)
    j=((jx<0.004*ppm)|(jy<0.004*ppm)).astype(np.float32)
    pi_=(np.floor(xx/(P*ppm))+2*np.floor(yy/(P*ppm))).astype(int)
    t=np.choose(pi_%4,[1.0,0.95,1.03,0.97]); col=col*t[...,None]
    oil=norm01(blur(rng.random((S,S)).astype(np.float32),SS*5)); col=col*(1-0.12*np.clip(oil-0.55,0,1)[...,None]*3)
    h=stdz(lum(c))*0.04-j*0.9; col=col*(1-0.45*j[...,None])
    ao=cav_ao(h,2.0,2.0); return col,nrm_from_height(blur(h,SS*0.5),1.5),np.dstack([ao,np.full_like(h,0.88),np.zeros_like(h)])
def T_from(name):
    cols,nor,orm=TR.tile(name,TU,TV,(PM,PM)); return cols[1] if name=='tb_galv' else cols[0],nor,orm
def T_paint():
    col,nor,orm=T_from('tb_paint'); return col,nor,orm
def T_rubber():
    c=crop('asphalt_02',PM*0.5,PM*0.5,TU,TV,71); col=tone(c,[0.13,0.13,0.13],0.25)
    sc=np.zeros((S,S),np.float32)
    for i in range(40):
        x0=rng.uniform(0,S); y0=rng.uniform(0,S); L=rng.uniform(0.02,0.09)*ppm; a=rng.uniform(-0.3,0.3)
        t=np.clip(((xx-x0)*np.cos(a)+(yy-y0)*np.sin(a))/L,0,1); px=x0+t*L*np.cos(a); py=y0+t*L*np.sin(a)
        d=np.sqrt(wrapd(xx,px,S)**2+wrapd(yy,py,S)**2); sc=np.maximum(sc,np.clip(1-d/(0.0015*ppm),0,1))
    col=col*(1-0.5*sc[...,None])+np.array([0.32,0.31,0.30])*0.5*sc[...,None]
    h=stdz(lum(c))*0.05-sc*0.3; return col,nrm_from_height(blur(h,SS*0.5),1.2),np.dstack([cav_ao(h),np.full_like(h,0.92),np.zeros_like(h)])
def T_canvas():
    c=crop('denim_fabric',PM*0.25,PM*0.25,TU,TV,81); col=tone(c,[0.86,0.85,0.82],0.06)
    st=streaks(TU,TV,82,n=6,width=(0.02,0.06)); col=col*(1-0.10*st[...,None])
    h=stdz(lum(c))*0.3; return col,nrm_from_height(blur(h,SS*0.4),0.8),np.dstack([np.ones_like(h)*0.97,np.full_like(h,0.95),np.zeros_like(h)])
def T_teak():
    c=crop('fine_grained_wood',PM,PM,TU,TV,91); c=np.transpose(c,(1,0,2)); col=tone(c,[0.56,0.42,0.29],0.14)
    h=stdz(lum(c))*0.06; return col,nrm_from_height(blur(h,SS*0.5),1.0),np.dstack([cav_ao(h),np.full_like(h,0.45),np.zeros_like(h)])
def T_foul():
    # antifouled hull bottom (light neutral, vertex-tinted red / blue / black) with slime and weed growth
    col,nor,orm=T_from('tb_paint')
    g=norm01(blur(rng.random((S,S)).astype(np.float32),SS*3)); st=streaks(TU,TV,93,n=9,width=(0.01,0.03))
    m=np.clip((g-0.45)*2.5,0,1)*0.6+st*0.25
    col=col*(1-m[...,None])+np.array([0.30,0.33,0.22])*m[...,None]
    orm=orm.copy(); orm[...,1]=np.clip(orm[...,1]+0.2*m,0,1); return col,nor,orm
def T_rust():
    col,nor,orm=T_from('tb_rust'); return col,nor,orm
def T_galv():
    return T_from('tb_galv')
TILES=[('tw_deck',0,0,lambda:T_deck('grey')),('tw_timber',128,0,T_timber),('tw_conc',256,0,T_conc),('tw_tide',384,0,T_tide),('tw_tide_hi',896,128,lambda:T_tide(True)),('tw_conc_top',768,256,lambda:T_conc(True)),
       ('tw_granite',512,0,T_granite),('tw_paver',640,0,T_paver),('tw_galv',768,0,T_galv),('tw_paint',896,0,T_paint),
       ('tw_rubber',0,128,T_rubber),('tw_canvas',128,128,T_canvas),('tw_teak',256,128,T_teak),('tw_foul',384,128,T_foul),
       ('tw_rust',512,128,T_rust),('tw_deck_brown',640,128,lambda:T_deck('brown'))]
def main():
    A=json.load(open(ATLP)); R=A['regions']
    for k in [k for k in R if R[k].get('page')=='w']: del R[k]
    P={c:np.full((N,N,4),(128,128,128,255),np.uint8) for c in ('clean','worn','dirty')}
    nor=np.full((N,N,3),(128,128,255),np.uint8); orm=np.full((N,N,3),(255,200,0),np.uint8)
    dn=lambda a: cv2.resize(a.astype(np.float32),(TU,TV),interpolation=cv2.INTER_AREA)
    pad=lambda a: np.pad(a,((PAD,PAD),(PAD,PAD))+(((0,0),) if a.ndim==3 else ()),mode='wrap')
    for name,x,y,fn in TILES:
        col,nr,om=fn(); w=h=TU+2*PAD
        c8=(np.clip(pad(dn(col)),0,1)*255+0.5).astype(np.uint8)
        for c in P: P[c][y:y+h,x:x+w,:3]=c8
        nor[y:y+h,x:x+w]=(np.clip(pad(dn(nr)),0,1)*255+0.5).astype(np.uint8); orm[y:y+h,x:x+w]=(np.clip(pad(dn(om)),0,1)*255+0.5).astype(np.uint8)
        for c in ('clean','worn','dirty'):
            R[f'{name}.{c}']={'px':[x,y,w,h],'uv':[(x+PAD)/N,(y+PAD)/N,(x+PAD+TU)/N,(y+PAD+TV)/N],'m':[PM,PM],'trim':True,'page':'w','tile_px':TU}
        print('tile',name,(x,y),'mean',np.round(col.reshape(-1,3).mean(0),3))
    # far swatch: flat light neutral (far tiers are painted per face by vertex colour = mid colour / swatch)
    x,y=768,128
    for c in P: P[c][y:y+32,x:x+32,:3]=230
    nor[y:y+32,x:x+32]=(128,128,255); orm[y:y+32,x:x+32]=(255,230,0)
    for c in ('clean','worn','dirty'):
        R[f'twf_flat.{c}']={'px':[x,y,32,32],'uv':[(x+8)/N,(y+8)/N,(x+24)/N,(y+24)/N],'m':[100.0,100.0],'trim':True,'page':'w','tile_px':16}
    for c in P: Image.fromarray(P[c]).save(f'{SRC}/props_w_base_color_{c}.png')
    Image.fromarray(nor).save(f'{SRC}/props_w_base_normal.png'); Image.fromarray(orm).save(f'{SRC}/props_w_base_orm.png')
    A.setdefault('size_w',{'color':1024,'normal':512,'orm':256})
    A['runtime_pages'].update({'w_clean':'props_w_color_clean.png','w_normal':'props_w_normal.png','w_orm':'props_w_orm.png'})
    t=ATLP+'.tmp'; json.dump(A,open(t,'w'),indent=1); os.replace(t,ATLP)
if __name__=='__main__': main()
