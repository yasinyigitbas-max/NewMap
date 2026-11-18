"""Page I goods bands: shelf product facings, front view, 128 px/m (matches the trim density).
Three bands of 1024 x 32 px at rows 160/192/224 (1 px gutter top and bottom, 30 px inner = 0.25 m).
One band spans 8 m of shelf, so a run never shows a visible repeat. Branding-free: colour blocks,
stripes and blank label panels only, no lettering or logos.

band 0 tg_grocery : cereal boxes, cans, jars, cartons, bottles, bags (grocery / pharmacy / general)
band 1 tg_bottles : wine, liquor, beer, shampoo / tonic bottles, tubs (bar / salon / liquor)
band 2 tg_spines  : book spines, shoe boxes, folded textiles, card packs (books / clothing / gift)
"""
import numpy as np, cv2
SS=4; PXM=128; W=1024; BH=32; IN=30
def _rgb(h,s,v):
    import colorsys; return np.array(colorsys.hsv_to_rgb(h%1,s,v),np.float32)
PAL=[(0.00,0.78,0.80),(0.03,0.70,0.85),(0.08,0.80,0.90),(0.12,0.75,0.92),(0.15,0.60,0.95),(0.30,0.55,0.60),
     (0.36,0.65,0.50),(0.52,0.55,0.70),(0.58,0.70,0.70),(0.62,0.65,0.45),(0.70,0.45,0.55),(0.83,0.45,0.70),
     (0.95,0.55,0.75),(0.0,0.0,0.92),(0.0,0.0,0.18),(0.10,0.30,0.75)]
def band(kind, seed):
    r=np.random.default_rng(seed); H=BH*SS; WW=W*SS; ppm=PXM*SS
    col=np.zeros((H,WW,3),np.float32); hgt=np.zeros((H,WW),np.float32); rough=np.full((H,WW),0.85,np.float32)
    met=np.zeros((H,WW),np.float32); occ=np.zeros((H,WW),np.float32)
    # background: deep shelf back, lighter at the bottom (light from the front spills onto the shelf lip)
    yy=np.arange(H,dtype=np.float32)[:,None]/H
    col[:]=np.array([0.10,0.10,0.11])[None,None,:]*(0.7+0.6*yy)[...,None]; occ[:]=0.35+0.25*yy
    g0=SS; base=H-SS   # 1 px gutters
    x=0.0
    while x<WW-2:
        # one product, repeated as 2-6 facings
        if kind=='grocery': t=r.choice(['box','box','can','jar','bottle','carton','bag'])
        elif kind=='bottles': t=r.choice(['wine','wine','liquor','beer','pump','tub','tall'])
        else: t=r.choice(['book']*8+['shoebox','fold','pack'])
        if t in ('box',): w,h=r.uniform(0.07,0.11),r.uniform(0.17,0.25)
        elif t=='can': w,h=0.068,r.choice([0.105,0.12])
        elif t=='jar': w,h=r.uniform(0.07,0.09),r.uniform(0.10,0.15)
        elif t=='bottle': w,h=r.uniform(0.06,0.08),r.uniform(0.18,0.245)
        elif t=='carton': w,h=0.07,r.uniform(0.18,0.22)
        elif t=='bag': w,h=r.uniform(0.12,0.16),r.uniform(0.14,0.20)
        elif t=='wine': w,h=0.075,r.uniform(0.225,0.245)
        elif t=='liquor': w,h=r.uniform(0.07,0.09),r.uniform(0.19,0.245)
        elif t=='beer': w,h=0.062,r.uniform(0.18,0.20)
        elif t=='pump': w,h=r.uniform(0.06,0.075),r.uniform(0.17,0.21)
        elif t=='tub': w,h=r.uniform(0.07,0.09),r.uniform(0.07,0.10)
        elif t=='tall': w,h=r.uniform(0.045,0.06),r.uniform(0.15,0.20)
        elif t=='book': w,h=r.uniform(0.018,0.045),r.uniform(0.15,0.245)
        elif t=='shoebox': w,h=r.uniform(0.30,0.34),r.uniform(0.11,0.13)
        elif t=='fold': w,h=r.uniform(0.26,0.32),r.uniform(0.045,0.07)
        else: w,h=r.uniform(0.06,0.10),r.uniform(0.12,0.20)
        n=int(r.integers(3,9)) if t=='book' else int(r.integers(2,6))
        if t in ('shoebox','fold'): n=1
        hu,sa,va=PAL[r.integers(len(PAL))]; c1=_rgb(hu+r.uniform(-.02,.02),sa,va); c2=_rgb(hu+r.uniform(.3,.7),r.uniform(.2,.8),r.uniform(.6,.95))
        glass={'wine':np.array([0.10,0.22,0.12]),'liquor':np.array([0.55,0.32,0.10]),'beer':np.array([0.30,0.16,0.05])}.get(t)
        if t=='liquor' and r.random()<0.4: glass=np.array([0.62,0.66,0.62])
        if t=='wine' and r.random()<0.3: glass=np.array([0.32,0.10,0.08])
        stackfold=t=='fold'
        for k in range(n):
            if t=='book':
                hu,sa,va=PAL[r.integers(len(PAL))]; c1=_rgb(hu,sa*0.8,va*0.8); w=r.uniform(0.018,0.045); h=r.uniform(0.17,0.245)
            if stackfold:   # folded textile stack: 3-4 layers
                nl=int(r.integers(3,5)); hh=h; layer_h=0.24/nl
                for L in range(nl):
                    cc=_rgb(hu+r.uniform(-.05,.05),sa*r.uniform(.6,1),va*r.uniform(.8,1.05))
                    x0=int(x+r.uniform(0,0.01)*ppm); x1=int(x+w*ppm-r.uniform(0,0.01)*ppm)
                    y1=base-int(L*layer_h*ppm); y0=y1-int(layer_h*ppm*0.92)
                    col[y0:y1,x0:x1]=cc; hgt[y0:y1,x0:x1]=0.6; occ[y0:y1,x0:x1]=1
                    col[y0:y0+SS,x0:x1]*=1.18; col[y1-SS:y1,x0:x1]*=0.7
                break
            x0=int(x); x1=int(x+w*ppm)-SS//2; y1=base; y0=max(g0,int(base-h/0.25*IN*SS))
            if x1>=WW-1: break
            ww=x1-x0; xs=np.arange(ww,dtype=np.float32)/max(ww-1,1); cyl=np.sqrt(np.clip(1-(2*xs-1)**2,0,1))
            reg=(slice(y0,y1),slice(x0,x1)); hh_=y1-y0
            ys=(np.arange(hh_,dtype=np.float32)/max(hh_-1,1))[:,None]   # 0 top .. 1 bottom
            body=np.ones((hh_,ww),bool)
            if t in ('bottle','wine','liquor','beer','pump','tall'):
                neck=0.42 if t=='wine' else 0.35 if t in ('liquor','beer') else 0.22
                nw=0.30 if t!='pump' else 0.22
                shoulder=ys<neck; xm=np.abs(2*xs[None,:]-1)
                prof=np.where(ys<neck*0.55, nw, nw+(1-nw)*np.clip((ys-neck*0.55)/(neck*0.45),0,1)**0.7)
                body=xm<=prof
                if t=='pump': body|=(ys<0.12)&(xs[None,:]>0.45)&(xs[None,:]<0.95)&(ys>0.02)
            elif t in ('can','jar','tub'):
                body[:]=True
            cbase=glass if glass is not None else c1
            shade=(0.55+0.45*cyl)[None,:] if t not in ('box','carton','book','shoebox','pack','bag') else (0.80+0.2*cyl**0.3)[None,:]
            block=cbase[None,None,:]*shade[...,None]*np.ones((hh_,1,1),np.float32)
            # label / graphics (branding-free)
            if t in ('box','carton','pack'):
                block[(ys>0.08)[:,0]&(ys<0.20)[:,0]]=c2
                m=((ys>0.30)&(ys<0.70))[:,0]; block[m,int(ww*0.14):int(ww*0.86)]=np.array([0.93,0.91,0.86])
                block[((ys>0.82)&(ys<0.90))[:,0]]=c2*0.8
            elif t in ('can','jar','tub'):
                if t=='can': block[(ys<0.06)[:,0]|(ys>0.95)[:,0]]=np.array([0.72,0.73,0.75]); met[reg]=0.0
                if t=='jar': block[(ys<0.16)[:,0]]=c2*0.9*shade[0][None,:,None][0]
                if t=='tub': block[(ys<0.18)[:,0]]=np.array([0.92,0.92,0.90])
                m=((ys>0.30)&(ys<0.78))[:,0]; block[m]=c2[None,None,:]*shade[...,None][0]
            elif t in ('bottle','wine','liquor','beer','pump','tall'):
                lab0,lab1=(0.55,0.85) if t in ('wine','liquor','beer') else (0.40,0.80)
                m=((ys>lab0)&(ys<lab1))[:,0]; block[m]=(np.array([0.92,0.88,0.78]) if t=='wine' else c2)[None,None,:]*shade[...,None][0]
                cap=(ys<0.07)[:,0]; block[cap]=(np.array([0.70,0.12,0.10]) if t=='wine' else c1*0.6+0.2)
                if t in ('bottle','pump','tall') and glass is None: pass
            elif t=='book':
                block[((ys>0.08)&(ys<0.11))[:,0]]=np.array([0.85,0.75,0.40]); block[((ys>0.86)&(ys<0.89))[:,0]]=np.array([0.85,0.75,0.40])
                m=((ys>0.25)&(ys<0.60))[:,0]; block[m,int(ww*0.3):int(ww*0.7)]=c2
            elif t=='shoebox':
                block[((ys>0.0)&(ys<0.22))[:,0]]=c1*0.75   # lid
                block[((ys>0.45)&(ys<0.70))[:,0],int(ww*0.08):int(ww*0.30)]=np.array([0.95,0.95,0.93])
            elif t=='bag':
                block=block*(0.9+0.1*np.sin(xs*18)[None,:,None]); block[(ys<0.10)[:,0]]=c1*0.6
                m=((ys>0.35)&(ys<0.75))[:,0]; block[m,int(ww*0.2):int(ww*0.8)]=c2
            # specular streak on glass / plastic
            if t in ('bottle','wine','liquor','beer','pump','tall','jar','can','tub'):
                sp=np.exp(-((xs-0.28)/0.06)**2)[None,:]; block=block+0.35*sp[...,None]
            sub=col[reg]; sub[body]=np.clip(block[body],0,1); col[reg]=sub
            hs=hgt[reg]; hs[body]=(0.6*cyl[None,:]*np.ones((hh_,1)))[body] if shade.shape[1]==ww else 0.6; hgt[reg]=hs
            os_=occ[reg]; os_[body]=0.78+0.22*np.clip(ys*1.0,0,1).repeat(ww,1)[body]; occ[reg]=os_
            rs=rough[reg]; rs[body]=0.25 if (glass is not None or t in ('bottle','pump','tall','jar')) else 0.6; rough[reg]=rs
            # dark contact line at the base and a 1 px gap between facings
            col[y1-SS:y1,x0:x1]*=0.55
            x=x1+SS//2
        x+= r.uniform(0.004,0.012)*ppm
        if r.random()<0.10: x+=r.uniform(0.03,0.08)*ppm   # an empty facing / gap now and then
    occ=cv2.GaussianBlur(occ,(0,0),SS*0.8)
    def dn(a): return cv2.resize(a,(W,BH),interpolation=cv2.INTER_AREA)
    gx=cv2.Sobel(cv2.GaussianBlur(hgt,(0,0),SS*0.6),cv2.CV_32F,1,0,ksize=3); gy=cv2.Sobel(cv2.GaussianBlur(hgt,(0,0),SS*0.6),cv2.CV_32F,0,1,ksize=3)
    nr=np.dstack([-gx*1.5,gy*1.5,np.ones_like(hgt)]); nr/=np.linalg.norm(nr,axis=2,keepdims=True); nr=nr*.5+.5
    return np.clip(dn(col),0,1),dn(nr),np.dstack([dn(occ),dn(rough),dn(met)])
BANDS=[('tg_grocery','grocery',101),('tg_bottles','bottles',202),('tg_spines','spines',303)]
if __name__=='__main__':
    from PIL import Image
    out=[]
    for nm,k,s in BANDS:
        c,n,o=band(k,s); out.append((c*255).astype(np.uint8))
    Image.fromarray(np.vstack(out)).resize((2048,192),Image.NEAREST).save('/tmp/rev/goods.png'); print('ok')
