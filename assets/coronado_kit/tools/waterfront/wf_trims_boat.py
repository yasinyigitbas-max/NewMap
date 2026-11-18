"""Page W boat trim tiles (Yasin 10:03, option 2): shared hull / deck / sail / plank / vinyl tiles in the reserved tile rows
(row 256 of page W), same 112 px inner + 8 px wrap pad at 128 px/m as wf_trims.py. Adds to the base pages in place (never
deletes the existing tiles or any bake region) and registers the regions; then props_compose.py w rebuilds the runtime page.
   tw_gelcoat  (0,256)   glossy white gelcoat topsides: orange peel, faint fairing waviness, chalking, fine crazing, rub scuffs
   tw_nonskid  (128,256) moulded gelcoat deck non-skid (pebble field in diamond panels with smooth margins)
   tw_sail     (256,256) dacron sailcloth: horizontal panel seams (double zig-zag stitch rows), crinkles, slight yellowing
   tw_plank    (384,256) painted carvel planking (workboat / ferry topsides): plank seams, fastening bungs, paint chips, rust weeps
   tw_vinyl    (512,256) marine vinyl upholstery: grain, piping seams, stitch rows
All tiles are near-white / neutral so the per-piece trim_tint (COLOR_0) colours them (navy hull, red antifouling, tan sail...)."""
import json, os, sys, numpy as np, cv2
from PIL import Image
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import wf_trims as W
from wf_trims import S,ppm,yy,xx,wrapd,blur,stdz,tone,cav_ao,nails,crop,lum,norm01,nrm_from_height,streaks,TU,TV,PM,PAD,N,SS,SRC,ATLP
rng=np.random.default_rng(301)
def noise(sc): return norm01(blur(rng.random((S,S)).astype(np.float32),SS*sc))
def T_gelcoat():
    peel=noise(0.6)-0.5; wav=np.sin(yy/S*2*np.pi*2+1.3)*0.5+noise(14)-0.5
    base=np.array([0.90,0.90,0.88],np.float32)
    chalk=noise(6); col=np.clip(base[None,None,:]*(1+0.02*peel[...,None]-0.05*(chalk[...,None]-0.5)),0,1)
    cz=np.zeros((S,S),np.float32)   # fine star crazing
    for i in range(10):
        cx,cy=rng.uniform(0,S,2)
        for k in range(5):
            a=rng.uniform(0,np.pi); L=rng.uniform(0.01,0.03)*ppm
            t=np.clip(((xx-cx)*np.cos(a)+(yy-cy)*np.sin(a))/L,-1,1); px=cx+t*L*np.cos(a); py=cy+t*L*np.sin(a)
            d=np.sqrt(wrapd(xx,px%S,S)**2+wrapd(yy,py%S,S)**2); cz=np.maximum(cz,np.clip(1-d/(0.0008*ppm),0,1))
    col=col*(1-0.25*cz[...,None])
    sc=streaks(TU,TV,302,n=5,width=(0.004,0.012))*np.clip(noise(3)*1.6-0.4,0,1)
    col=col*(1-0.12*sc[...,None])+np.array([0.55,0.52,0.47])*0.0
    h=peel*0.04+wav*0.03-cz*0.2
    ro=np.clip(0.22+0.25*chalk+0.15*sc,0,1)
    return col,nrm_from_height(blur(h,SS*0.5),1.0),np.dstack([cav_ao(h,2,0.6),ro,np.zeros_like(h)])
def T_nonskid():
    P=PM/2; m=0.022*ppm
    fx=(xx%(P*ppm)); fy=(yy%(P*ppm)); edge=np.minimum(np.minimum(fx,P*ppm-fx),np.minimum(fy,P*ppm-fy))
    field=np.clip((edge-m)/(0.004*ppm),0,1)
    peb=np.zeros((S,S),np.float32)
    for i in range(1400):
        cx,cy=rng.uniform(0,S,2); r=rng.uniform(0.0015,0.003)*ppm
        d=np.sqrt(wrapd(xx,cx,S)**2+wrapd(yy,cy,S)**2); peb=np.maximum(peb,np.clip(1-d/r,0,1)**0.6)
    h=peb*field*0.6-(1-field)*0.0+np.where(field<0.5,0.15,0.0)
    dirt=noise(1.2)
    col=np.array([0.88,0.88,0.85],np.float32)[None,None,:]*(1-0.10*(peb*field)[...,None])
    col=col*(1-0.10*(field*(1-peb)*dirt)[...,None])
    ro=np.where(field>0.5,0.75,0.3)
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.3),1.8),np.dstack([cav_ao(h,1.5,1.2),ro,np.zeros_like(h)])
def T_sail():
    c=crop('denim_fabric',PM*0.12,PM*0.12,TU,TV,311); weave=stdz(lum(c))
    v=yy/ppm; seam_p=PM/2; dv=np.minimum(v%seam_p,seam_p-v%seam_p)
    seam=(dv<0.010).astype(np.float32)
    stitch=np.zeros((S,S),np.float32)
    for o in (-0.007,0.007):
        z=((v+o)%seam_p); zz=np.minimum(z,seam_p-z)
        zig=np.abs(((xx/ppm)/0.006)%2-1)*0.003
        stitch=np.maximum(stitch,np.clip(1-np.abs(zz-zig)/(0.0007),0,1))
    crk=np.clip(noise(2.5)-0.5,0,1)*2
    col=np.array([0.93,0.92,0.88],np.float32)[None,None,:]*(1+0.02*weave[...,None])
    col=col*(1-0.05*seam[...,None])*(1-0.12*stitch[...,None])*(1-0.05*crk[...,None])
    yel=noise(8); col=col*(1-0.06*yel[...,None])+np.array([0.85,0.80,0.62])*0.06*yel[...,None]
    h=weave*0.05+seam*0.3+stitch*0.15+crk*0.25
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.4),0.9),np.dstack([cav_ao(h,1.5,0.8),np.full_like(h,0.85),np.zeros_like(h)])
def T_plank():
    pw=PM/5; v=yy/ppm; f=(v%pw)/pw; gap=(np.minimum(f,1-f)*pw<0.0035).astype(np.float32)
    g=crop('weathered_brown_planks',PM,PM,TU,TV,321); grain=stdz(lum(g))
    col=np.array([0.88,0.87,0.83],np.float32)[None,None,:]*(1+0.03*grain[...,None])
    bung=np.zeros((S,S),np.float32)
    for k in range(5):
        for u in (0.11,0.55): bung=np.maximum(bung,nails([u+0.03*(k%2)],[k*pw+pw/2],0.008))
    chip=np.clip((noise(1.0)-0.72)*6,0,1)*np.clip(noise(5)*1.5-0.3,0,1)
    wood=tone(g,[0.40,0.31,0.22],0.2)
    col=col*(1-chip[...,None])+wood*chip[...,None]
    weep=np.zeros((S,S),np.float32)
    for k in range(5):
        for u in (0.11,0.55):
            dx=wrapd(xx,(u+0.03*(k%2))*ppm,S); dy=((yy-(k*pw+pw/2)*ppm)%S)/ppm
            weep+=np.exp(-(dx/(0.004*ppm))**2)*np.clip(1-dy/0.12,0,1)*(dy>0)
    weep=np.clip(weep,0,1)*0.6; col=col*(1-weep[...,None]*0.5)+np.array([0.45,0.27,0.14])*weep[...,None]*0.5
    col=col*(1-0.6*gap[...,None])*(1-0.15*bung[...,None])
    h=-gap*1.0+bung*0.1-chip*0.25+grain*0.03+np.sin(np.clip(f,0,1)*np.pi)**0.3*0.2
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.5),1.6),np.dstack([cav_ao(h,2,1.5),np.clip(0.5+0.4*chip,0,1),np.zeros_like(h)])
def T_vinyl():
    c=crop('leather_white',PM*0.3,PM*0.3,TU,TV,331); gr=stdz(lum(c))
    v=yy/ppm; P=PM/4; d=np.minimum(v%P,P-v%P); pipe=np.clip(1-d/0.006,0,1)
    st=np.zeros((S,S),np.float32)
    for o in (-0.012,0.012):
        dd=np.abs(((v+o)%P)-0.0); dd=np.minimum(dd,P-dd); dash=(((xx/ppm)/0.008)%1<0.6)
        st=np.maximum(st,np.clip(1-dd/0.0008,0,1)*dash)
    col=np.array([0.90,0.89,0.86],np.float32)[None,None,:]*(1+0.03*gr[...,None])*(1-0.08*st[...,None])
    h=gr*0.05+pipe*0.5-st*0.2+np.sin(np.clip((v%P)/P,0,1)*np.pi)**0.5*0.3
    return np.clip(col,0,1),nrm_from_height(blur(h,SS*0.5),1.2),np.dstack([cav_ao(h,2,1.0),np.full_like(h,0.55),np.zeros_like(h)])
NEW=[('tw_gelcoat',0,256,T_gelcoat),('tw_nonskid',128,256,T_nonskid),('tw_sail',256,256,T_sail),('tw_plank',384,256,T_plank),('tw_vinyl',512,256,T_vinyl)]
def main():
    A=json.load(open(ATLP)); R=A['regions']
    occ=[(v['px'],k) for k,v in R.items() if v.get('page')=='w' and k.endswith('.clean') and not any(k.startswith(n+'.') for n,_,_,_ in NEW)]
    P={c:np.array(Image.open(f'{SRC}/props_w_base_color_{c}.png').convert('RGBA')) for c in ('clean','worn','dirty')}
    nor=np.array(Image.open(f'{SRC}/props_w_base_normal.png').convert('RGB')); orm=np.array(Image.open(f'{SRC}/props_w_base_orm.png').convert('RGB'))
    dn=lambda a: cv2.resize(a.astype(np.float32),(TU,TV),interpolation=cv2.INTER_AREA)
    pad=lambda a: np.pad(a,((PAD,PAD),(PAD,PAD))+(((0,0),) if a.ndim==3 else ()),mode='wrap')
    for name,x,y,fn in NEW:
        w=h=TU+2*PAD
        for (a,b_,c,d),k in occ: assert not (a<x+w and x<a+c and b_<y+h and y<b_+d), (name,k)
        assert y+h<=384
        col,nr,om=fn()
        c8=(np.clip(pad(dn(col)),0,1)*255+0.5).astype(np.uint8)
        for c in P: P[c][y:y+h,x:x+w,:3]=c8; P[c][y:y+h,x:x+w,3]=255
        nor[y:y+h,x:x+w]=(np.clip(pad(dn(nr)),0,1)*255+0.5).astype(np.uint8); orm[y:y+h,x:x+w]=(np.clip(pad(dn(om)),0,1)*255+0.5).astype(np.uint8)
        for c in ('clean','worn','dirty'):
            R[f'{name}.{c}']={'px':[x,y,w,h],'uv':[(x+PAD)/N,(y+PAD)/N,(x+PAD+TU)/N,(y+PAD+TV)/N],'m':[PM,PM],'trim':True,'page':'w','tile_px':TU}
        print('tile',name,(x,y),'mean',np.round(col.reshape(-1,3).mean(0),3))
    for c in P: Image.fromarray(P[c]).save(f'{SRC}/props_w_base_color_{c}.png')
    Image.fromarray(nor).save(f'{SRC}/props_w_base_normal.png'); Image.fromarray(orm).save(f'{SRC}/props_w_base_orm.png')
    t=ATLP+'.tmp'; json.dump(A,open(t,'w'),indent=1); os.replace(t,ATLP)
if __name__=='__main__': main()
