"""Page H art bank: eight painterly / poster artworks for the house frames.
Paints colour, a brush-height normal and an ORM (R = canvas AO) into the
reserved atlas band at y=512-1023. Never touches A/B/C/W or page I.

Run: python3 tools/h_art.py && IN_KIT=... python3 kit/props/_tools/props_compose.py h
"""
import json, os, math
from pathlib import Path
import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont

K=os.environ.get('IN_KIT','/workspace/coronado_kit_v2/_staging/house/kit')
SRC=K+'/props/_bake_src'; ATLP=K+'/atlases/props_atlas.json'
N=1024
rng=np.random.default_rng(11)

def blur(a,s,mode='reflect'):
    if s<=0: return a
    k=int(max(3, s*6//1*2+1))
    if a.ndim==3:
        out=np.empty_like(a,np.float32)
        for i in range(a.shape[2]):
            out[...,i]=cv2.GaussianBlur(np.pad(a[...,i],((k,k),(k,k)),mode=mode),(0,0),s)[k:-k,k:-k]
        return out
    return cv2.GaussianBlur(np.pad(a,((k,k),(k,k)),mode=mode),(0,0),s)[k:-k,k:-k]

def nrm_from_height(h, amp=1.0):
    dx=np.gradient(h, axis=1); dy=np.gradient(h, axis=0)
    n=np.dstack((-dx*amp, dy*amp, np.ones_like(h)))
    n/=np.maximum(np.linalg.norm(n,axis=2,keepdims=True),1e-6)
    return n*0.5+0.5

def canvas(h,w, seed=0):
    rr=np.random.default_rng(seed)
    grain=blur(rr.random((h,w)).astype(np.float32), 0.6, 'reflect')
    # fine weave
    yy,xx=np.mgrid[0:h,0:w]
    weave=0.5+0.5*np.sin(xx*2*np.pi/3.2)*np.sin(yy*2*np.pi/3.0)
    return (grain-0.5)*0.08+(weave-0.5)*0.04

def lerp(a,b,t):
    a=np.asarray(a,np.float32); b=np.asarray(b,np.float32)
    t=np.clip(np.asarray(t,np.float32),0,1)
    if a.ndim==1:
        if t.ndim==1: t=t[:,None,None]
        elif t.ndim==2: t=t[...,None]
        return a*(1-t)+b*t
    if t.ndim < a.ndim: t=t[...,None]
    return a*(1-t)+b*t

def stamp(col, ht, cx, cy, rx, ry, ang, rgb, alpha, happ=0.0, hard=0.45):
    """Soft elliptical dab. cx,cy in pixels, rx,ry radii, ang radians, rgb 0-1, alpha 0-1."""
    H,W=ht.shape
    # tight bbox
    r=int(math.ceil(max(rx,ry)*1.6+2))
    x0,x1=max(0,int(cx)-r), min(W,int(cx)+r+1)
    y0,y1=max(0,int(cy)-r), min(H,int(cy)+r+1)
    if x1<=x0 or y1<=y0: return
    yy,xx=np.mgrid[y0:y1,x0:x1].astype(np.float32)
    ca,sa=math.cos(ang),math.sin(ang)
    dx,dy=xx-cx, yy-cy
    u= ca*dx+sa*dy; v=-sa*dx+ca*dy
    d=np.sqrt((u/max(rx,0.4))**2+(v/max(ry,0.4))**2)
    m=np.clip(1-d,0,1)
    m=m**hard
    m*=alpha
    if m.max()<1e-4: return
    rgb=np.asarray(rgb,np.float32)
    col[y0:y1,x0:x1] = col[y0:y1,x0:x1]*(1-m[...,None]) + rgb[None,None,:]*m[...,None]
    if happ:
        ht[y0:y1,x0:x1] = ht[y0:y1,x0:x1]*(1-m*0.7) + (ht[y0:y1,x0:x1]+happ)*m*0.7 + happ*m*0.3

def stroke(col, ht, x0,y0,x1,y1, width, rgb, alpha=0.8, happ=0.02, n=None, wobble=0.0, taper=True):
    length=math.hypot(x1-x0,y1-y0)
    n=n or max(3, int(length/(max(width,1)*0.45)))
    ang=math.atan2(y1-y0,x1-x0)
    for i in range(n+1):
        t=i/max(n,1)
        x=x0+(x1-x0)*t + wobble*math.sin(t*7.0+width)
        y=y0+(y1-y0)*t + wobble*math.cos(t*5.0+width)
        w=width*(0.55+0.45*math.sin(t*math.pi)) if taper else width
        a=alpha*(0.7+0.3*math.sin(t*math.pi))
        rgb_i=np.clip(np.asarray(rgb,np.float32)*(0.92+0.16*((i*17)%10)/10),0,1)
        stamp(col,ht,x,y,w, w*0.55, ang, rgb_i, a, happ)

def wash(col, ht, mask, rgb, alpha=0.35):
    m=np.clip(mask,0,1)*alpha
    rgb=np.asarray(rgb,np.float32)
    col[...] = col*(1-m[...,None])+rgb[None,None,:]*m[...,None]

def vgrad(h,w, y0,y1):
    y=np.linspace(0,1,h,dtype=np.float32)[:,None]
    t=(y-y0)/(y1-y0+1e-6)
    return np.clip(t,0,1)*np.ones((1,w),np.float32)

def disc_mask(h,w,cx,cy,r, soft=0.3):
    yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
    d=np.sqrt((xx-cx)**2+(yy-cy)**2)/max(r,1)
    return np.clip((1-d)/(soft+1e-6),0,1)

# ------------------------------------------------------------------ paintings (work at 2x, then down to slot)

def _prep(aspect, long=360):
    # aspect = width/height of the picture opening
    if aspect>=1:
        w,h=long, int(round(long/aspect))
    else:
        h,w=long, int(round(long*aspect))
    w,h=max(w,64), max(h,64)
    col=np.full((h,w,3), 0.90, np.float32)
    ht=np.zeros((h,w), np.float32)
    return col,ht,w,h

def paint_seascape():
    col,ht,w,h=_prep(1.40)
    yy=np.linspace(0,1,h,dtype=np.float32)[:,None]
    # sky: deep blue high, milky near the horizon
    sky=np.clip((0.55-yy)/0.55,0,1)*np.ones((1,w),np.float32)
    a=np.array([0.45,0.68,0.86],np.float32)*(0.55+0.45*sky[...,None])
    b=np.array([0.93,0.88,0.75],np.float32)*((1-sky)*0.85)[...,None]
    col[:]=a+b
    # sun and glow just above the horizon
    wash(col,ht,disc_mask(h,w,w*0.74,h*0.46,h*0.28,0.85),[1.00,0.86,0.52],0.45)
    stamp(col,ht,w*0.74,h*0.47,h*0.045,h*0.045,0,[1.0,0.94,0.72],0.9,0.01,hard=0.75)
    # soft clouds
    rr=np.random.default_rng(3)
    for i in range(18):
        stamp(col,ht,rr.uniform(0.02,0.7)*w, rr.uniform(h*0.08,h*0.38),
              rr.uniform(22,55), rr.uniform(7,16), rr.uniform(-0.2,0.2),
              [0.96,0.95,0.93], rr.uniform(0.12,0.32), 0.003, hard=0.25)
    # distant headland
    for t in np.linspace(0,1,12):
        x=w*0.02+w*0.22*t
        y=h*0.50 - 8*math.sin(t*math.pi) - (4 if t>0.6 else 0)
        stroke(col,ht,x,h*0.52,x,y, 5.0, [0.28,0.32,0.30], 0.4, 0.0, taper=False)
    # sea
    sea=np.clip((yy-0.50)/0.50,0,1)
    wash(col,ht,sea,[0.10,0.28,0.46],0.92)
    rr=np.random.default_rng(5)
    for i in range(70):
        y=rr.uniform(h*0.52,h*0.84)
        t=(y-h*0.52)/(h*0.32)
        rgb=[0.12+0.10*t, 0.30+0.12*t, 0.48+0.08*(1-t)]
        stroke(col,ht,rr.uniform(-10,w),y, rr.uniform(0,w)+40,y+rr.uniform(-2,2),
               rr.uniform(2.0,5.0), rgb, 0.28, 0.004, wobble=2.0, taper=True)
    # horizon haze
    wash(col,ht,np.exp(-((yy-0.50)*28)**2)*np.ones((1,w)),[0.86,0.88,0.90],0.55)
    # wet sand + dry sand
    wash(col,ht,np.clip((yy-0.82)/0.08,0,1),[0.62,0.55,0.42],0.7)
    wash(col,ht,np.clip((yy-0.90)/0.10,0,1),[0.84,0.72,0.52],0.85)
    # foam streaks along the wash
    rr=np.random.default_rng(6)
    for i in range(22):
        y=rr.uniform(h*0.80,h*0.90)
        x=rr.uniform(0,w)
        stroke(col,ht,x,y,x+rr.uniform(18,50),y+rr.uniform(-2,3), rr.uniform(2,4),
               [0.93,0.93,0.90], 0.45, 0.006, wobble=1.5)
    return _finish(col,ht,11)


def paint_hotel():
    col,ht,w,h=_prep(1.29)
    yy=np.linspace(0,1,h,dtype=np.float32)[:,None]
    # sky
    sky=np.clip((0.58-yy)/0.58,0,1)*np.ones((1,w),np.float32)
    a=np.array([0.50,0.74,0.90],np.float32)*sky[...,None]
    b=np.array([0.94,0.90,0.80],np.float32)*((1-sky)*0.5)[...,None]
    c=np.array([0.50,0.74,0.90],np.float32)*((1-sky)*0.5)[...,None]
    col[:]=a+b+c
    rr=np.random.default_rng(8)
    for i in range(12):
        stamp(col,ht,rr.uniform(0,w),rr.uniform(h*0.04,h*0.28),rr.uniform(18,40),rr.uniform(5,12),0,
              [0.96,0.95,0.93],0.22,0.0,hard=0.28)
    # ocean
    wash(col,ht,np.clip((yy-0.58)/0.22,0,1),[0.16,0.44,0.62],0.9)
    for i in range(24):
        y=rr.uniform(h*0.58,h*0.78)
        stroke(col,ht,0,y,w,y+rr.uniform(-2,2), 2.5, [0.22,0.50,0.68], 0.18, 0.002, taper=False)
    # sand
    wash(col,ht,np.clip((yy-0.76)/0.10,0,1),[0.86,0.74,0.54],0.95)
    # --- hotel: long white body, red roofs, a big corner turret (Hotel del massing)
    body_x0,body_x1=w*0.16, w*0.88
    body_y0,body_y1=h*0.38, h*0.74
    # veranda posts and floor
    wash(col,ht, ((np.mgrid[0:h,0:w][0]>body_y1-14)&(np.mgrid[0:h,0:w][0]<body_y1+4)&
                  (np.mgrid[0:h,0:w][1]>body_x0)&(np.mgrid[0:h,0:w][1]<body_x1)).astype(np.float32),
         [0.55,0.42,0.30],0.7)
    for x in np.linspace(body_x0+8, body_x1-8, 11):
        stroke(col,ht,x,body_y1-14,x,body_y1+2, 1.8, [0.40,0.32,0.22], 0.7, 0.0, taper=False)
    # facade
    facade=((np.mgrid[0:h,0:w][0]>=body_y0)&(np.mgrid[0:h,0:w][0]<=body_y1-8)&
            (np.mgrid[0:h,0:w][1]>=body_x0)&(np.mgrid[0:h,0:w][1]<=body_x1)).astype(np.float32)
    wash(col,ht,blur(facade,1.0),[0.93,0.91,0.86],0.96)
    # facade brush
    for i in range(22):
        x=rr.uniform(body_x0,body_x1); y=rr.uniform(body_y0,body_y1-10)
        stroke(col,ht,x,y,x+rr.uniform(10,28),y, 2.2, [0.96,0.94,0.90], 0.18, 0.003)
    # windows
    for row in range(4):
        y=body_y0+12+row*14
        x=body_x0+8
        while x<body_x1-8:
            stroke(col,ht,x,y,x,y+8, 2.0, [0.32,0.46,0.56], 0.75, 0.0, taper=False)
            x+=7.5
    # main red roof, slightly broken by gables
    for t in np.linspace(0,1,28):
        x=body_x0-2+(body_x1-body_x0+4)*t
        stroke(col,ht,x,body_y0+3,x,body_y0-16-5*math.sin(t*math.pi*3), 3.4, [0.74,0.16,0.12], 0.8, 0.02, taper=False)
    def turret(cx, cy, r, hcone):
        # white drum
        for a in np.linspace(0,math.pi,12):
            stroke(col,ht, cx+r*math.cos(a), cy, cx+r*math.cos(a), cy+r*0.9, 3.0, [0.94,0.92,0.88], 0.75, 0.01)
        # windows on drum
        for a in (-0.8,0,0.8):
            stroke(col,ht,cx+r*0.4*math.sin(a),cy+6,cx+r*0.4*math.sin(a),cy+14,1.8,[0.32,0.46,0.56],0.7,0,taper=False)
        # red cone
        for t in np.linspace(0,1,16):
            ww=r*(1-t)*1.05
            stroke(col,ht,cx-ww, cy-t*hcone, cx+ww, cy-t*hcone, 2.6, [0.78,0.15,0.12], 0.85, 0.02, taper=False)
        stamp(col,ht,cx,cy-hcone,2.0,2.0,0,[0.35,0.12,0.10],0.9,0.0)
    # big characteristic turret, slightly left of centre, plus two smaller
    turret(w*0.30, body_y0-2, 20, 34)
    turret(w*0.52, body_y0-8, 26, 46)
    turret(w*0.78, body_y0-2, 18, 30)
    return _finish(col,ht,12)


def paint_palms():
    col,ht,w,h=_prep(0.44)
    yy=np.linspace(0,1,h,dtype=np.float32)[:,None]
    # sunset: violet, orange belt, gold sun
    col[:]=lerp(np.array([0.22,0.10,0.28]), np.array([0.95,0.48,0.20]), np.clip((yy-0.05)/0.50,0,1))
    col=lerp(col, np.array([1.0,0.78,0.32]), np.exp(-((yy-0.58)*5)**2))
    col=lerp(col, np.array([0.40,0.14,0.18]), np.clip((yy-0.70)/0.30,0,1))
    wash(col,ht,disc_mask(h,w,w*0.58,h*0.58,h*0.14,0.55),[1.0,0.86,0.42],0.85)
    stamp(col,ht,w*0.58,h*0.58,h*0.065,h*0.065,0,[1.0,0.93,0.58],0.95,0.01,hard=0.8)
    wash(col,ht,vgrad(h,w,0.80,1.0),[0.18,0.07,0.10],0.65)
    wash(col,ht,disc_mask(h,w,w*0.58,h*0.90,h*0.10,0.7),[0.85,0.40,0.18],0.3)
    def palm(cx, base, height, lean, seed):
        rr=np.random.default_rng(seed)
        x,y=cx,base
        segs=10
        for i in range(segs):
            t=i/(segs-1)
            x2=x+lean*(height/segs)*0.15+rr.uniform(-0.8,0.8)
            y2=y-height/segs
            stroke(col,ht,x,y,x2,y2, 5.0-t*2.8, [0.06,0.04,0.04], 0.92, 0.02, taper=False)
            x,y=x2,y2
        # long arching fronds (not a firework)
        for k,aoff in enumerate((-0.15,-0.55,-0.95,-1.35,-1.75,-2.15,-2.50)):
            a=aoff+lean*0.08
            L=height*(0.38+0.12*(k%3)/3)
            # rachis as a quadratic arc
            pts=[]
            for t in np.linspace(0,1,8):
                px=x+(L*t)*math.cos(a)
                py=y+(L*t)*math.sin(a)+ (t*t)*L*0.35
                pts.append((px,py))
            for i in range(len(pts)-1):
                stroke(col,ht,*pts[i],*pts[i+1], 2.0, [0.05,0.04,0.04], 0.88, 0.012, taper=False)
            for t in np.linspace(0.12,0.95,8):
                i=min(int(t*(len(pts)-1)), len(pts)-2)
                px,py=pts[i]
                side=L*0.16*(1-t*0.5)
                ang=a+math.pi/2
                stroke(col,ht,px,py,px+side*math.cos(ang),py+side*math.sin(ang)+side*0.2, 1.3, [0.05,0.04,0.04], 0.75, 0.005)
                stroke(col,ht,px,py,px-side*math.cos(ang)*0.7,py-side*math.sin(ang)*0.7+side*0.2, 1.3, [0.05,0.04,0.04], 0.7, 0.005)
    palm(w*0.30, h*0.93, h*0.64, -0.35, 21)
    palm(w*0.60, h*0.95, h*0.50,  0.45, 22)
    palm(w*0.82, h*0.96, h*0.34,  0.20, 23)
    return _finish(col,ht,13)


def paint_mcm():
    col,ht,w,h=_prep(1.0)
    # cream ground, brushed
    wash(col,ht,np.ones((h,w),np.float32),[0.90,0.86,0.76],1)
    rr=np.random.default_rng(14)
    for i in range(30):
        stroke(col,ht,rr.uniform(0,w),rr.uniform(0,h),rr.uniform(0,w),rr.uniform(0,h),
               rr.uniform(4,10),[0.88,0.84,0.74],0.15,0.004,wobble=3)
    def field(x0,y0,x1,y1,rgb, seed):
        rr=np.random.default_rng(seed)
        # ragged rectangle of dabs
        for i in range(80):
            x=rr.uniform(x0,x1); y=rr.uniform(y0,y1)
            # fade near edges
            ex=min(x-x0,x1-x)/max(8, (x1-x0)*0.08)
            ey=min(y-y0,y1-y)/max(8, (y1-y0)*0.08)
            a=0.55*np.clip(ex,0,1)*np.clip(ey,0,1)
            stamp(col,ht,x,y,rr.uniform(7,16),rr.uniform(5,12),rr.uniform(-0.5,0.5),
                  np.clip(np.array(rgb)*(0.9+0.2*rr.random()),0,1), a, 0.012, hard=0.4)
    field(0, h*0.55, w, h, [0.12,0.18,0.36], 31)            # navy sea field
    field(0, h*0.32, w*0.42, h*0.62, [0.28,0.40,0.24], 32)  # olive hill
    field(w*0.72, 0, w, h*0.48, [0.72,0.20,0.16], 33)       # red bar
    # textured sun disc
    for a in np.linspace(0,math.pi,16):
        for r in np.linspace(0,1,8):
            x=w*0.50+(w*0.16*r)*math.cos(a)
            y=h*0.55+(h*0.16*r)*math.sin(a)
            stamp(col,ht,x,y,8,6,a,[0.90,0.62,0.14],0.45,0.015,hard=0.5)
    # scumbled overlaps
    rr=np.random.default_rng(15)
    for i in range(18):
        stroke(col,ht,rr.uniform(0,w),rr.uniform(0,h),rr.uniform(0,w),rr.uniform(0,h),
               rr.uniform(2,5),[0.90,0.86,0.76],0.12,0.002,wobble=2)
    return _finish(col,ht,14)

def paint_botanical():
    col,ht,w,h=_prep(0.77)
    wash(col,ht,np.ones((h,w),np.float32),[0.93,0.89,0.80],1)
    # faint paper stain
    rr=np.random.default_rng(16)
    for i in range(8):
        stamp(col,ht,rr.uniform(0,w),rr.uniform(0,h),40,30,0,[0.86,0.80,0.68],0.08,0.0,hard=0.25)
    def leaf(x0,y0,x1,y1, rgb, seed):
        rr=np.random.default_rng(seed)
        # midrib
        stroke(col,ht,x0,y0,x1,y1, 1.6, np.array(rgb)*0.7, 0.7, 0.01, wobble=1.0)
        L=math.hypot(x1-x0,y1-y0); ang=math.atan2(y1-y0,x1-x0)
        for t in np.linspace(0.08,0.92,9):
            px=x0+(x1-x0)*t; py=y0+(y1-y0)*t
            side=L*0.22*(math.sin(t*math.pi)**0.8)
            for s in (-1,1):
                stroke(col,ht,px,py, px+s*side*math.cos(ang+math.pi/2), py+s*side*math.sin(ang+math.pi/2),
                       3.2, np.clip(np.array(rgb)*(0.85+0.25*rr.random()),0,1), 0.5, 0.01, wobble=0.8)
    # branching stems
    stroke(col,ht,w*0.50,h*0.98,w*0.46,h*0.40, 2.2, [0.32,0.28,0.16], 0.8, 0.015, wobble=1.5, taper=True)
    stroke(col,ht,w*0.48,h*0.62,w*0.22,h*0.30, 1.8, [0.32,0.28,0.16], 0.7, 0.01, wobble=1.2)
    stroke(col,ht,w*0.48,h*0.55,w*0.78,h*0.22, 1.8, [0.32,0.28,0.16], 0.7, 0.01, wobble=1.2)
    # eucalyptus-like leaves
    greens=[[0.28,0.42,0.28],[0.36,0.48,0.30],[0.22,0.36,0.24],[0.45,0.50,0.32],[0.30,0.38,0.22]]
    pairs=[(w*0.46,h*0.42,w*0.20,h*0.18),(w*0.45,h*0.50,w*0.18,h*0.38),
           (w*0.48,h*0.38,w*0.72,h*0.10),(w*0.50,h*0.48,w*0.82,h*0.28),
           (w*0.50,h*0.58,w*0.78,h*0.48),(w*0.44,h*0.70,w*0.22,h*0.58),
           (w*0.52,h*0.68,w*0.74,h*0.62),(w*0.46,h*0.80,w*0.28,h*0.72),
           (w*0.50,h*0.78,w*0.70,h*0.72)]
    for i,(a,b,c,d) in enumerate(pairs):
        leaf(a,b,c,d, greens[i%len(greens)], 40+i)
    # one small coral bud
    stamp(col,ht,w*0.76,h*0.20, 7,7,0,[0.72,0.32,0.28],0.7,0.02,hard=0.5)
    return _finish(col,ht,17)

def paint_surf():
    col,ht,w,h=_prep(0.78)
    wash(col,ht,np.ones((h,w),np.float32),[0.93,0.86,0.66],1)
    # navy sky field with a soft fade
    wash(col,ht,np.clip((0.55-np.linspace(0,1,h)[:,None])/0.55,0,1)*np.ones((1,w)),[0.10,0.16,0.32],0.96)
    stamp(col,ht,w*0.78,h*0.22,h*0.09,h*0.09,0,[0.92,0.60,0.14],0.95,0.02,hard=0.75)
    # solid breaking wave
    # face of the wave (navy)
    for t in np.linspace(0,1,28):
        x=w*0.10+w*0.78*t
        y=h*0.60 - math.sin(t*math.pi)*h*0.20 + (t**1.6)*h*0.16
        stroke(col,ht,x,y+6, x, y-10-8*math.sin(t*math.pi), 8.5, [0.12,0.30,0.50], 0.8, 0.015, taper=False)
    # lip / foam
    for t in np.linspace(0.08,0.88,20):
        x=w*0.14+w*0.70*t
        y=h*0.58 - math.sin(t*math.pi)*h*0.20
        stroke(col,ht,x-4,y-8, x+6,y+2, 4.0, [0.96,0.94,0.88], 0.8, 0.02)
    rr=np.random.default_rng(18)
    for i in range(14):
        stamp(col,ht,rr.uniform(w*0.25,w*0.75),rr.uniform(h*0.40,h*0.58),7,3,rr.uniform(-1,1),[0.96,0.95,0.90],0.5,0.008,hard=0.4)
    wash(col,ht,vgrad(h,w,0.78,1.0),[0.86,0.70,0.42],0.88)
    # filled block caps
    def glyph(ch, x, y, s, rgb):
        s=float(s); lw=max(2.8, s*0.16)
        def H(a,b):
            stroke(col,ht,x+a[0]*s,y+a[1]*s,x+b[0]*s,y+b[1]*s,lw,rgb,0.95,0.012,taper=False)
        # also fill with a second slightly thicker pass for weight
        P={
            'C':[((0.20,0.18),(0.82,0.18)),((0.20,0.18),(0.20,0.82)),((0.20,0.82),(0.82,0.82))],
            'O':[((0.22,0.18),(0.78,0.18)),((0.78,0.18),(0.78,0.82)),((0.78,0.82),(0.22,0.82)),((0.22,0.82),(0.22,0.18))],
            'R':[((0.20,0.18),(0.20,0.82)),((0.20,0.18),(0.80,0.18)),((0.80,0.18),(0.80,0.46)),((0.80,0.46),(0.20,0.46)),((0.20,0.46),(0.80,0.82))],
            'N':[((0.20,0.82),(0.20,0.18)),((0.20,0.18),(0.80,0.82)),((0.80,0.82),(0.80,0.18))],
            'A':[((0.16,0.82),(0.50,0.16)),((0.50,0.16),(0.84,0.82)),((0.30,0.56),(0.70,0.56))],
            'D':[((0.20,0.18),(0.20,0.82)),((0.20,0.18),(0.68,0.18)),((0.68,0.18),(0.84,0.50)),((0.84,0.50),(0.68,0.82)),((0.68,0.82),(0.20,0.82))],
            'S':[((0.80,0.20),(0.24,0.20)),((0.24,0.20),(0.24,0.48)),((0.24,0.48),(0.76,0.48)),((0.76,0.48),(0.76,0.80)),((0.76,0.80),(0.20,0.80))],
            'U':[((0.20,0.18),(0.20,0.70)),((0.20,0.70),(0.50,0.84)),((0.50,0.84),(0.80,0.70)),((0.80,0.70),(0.80,0.18))],
            'F':[((0.22,0.18),(0.22,0.82)),((0.22,0.18),(0.84,0.18)),((0.22,0.48),(0.70,0.48))],
        }
        for a,b in P.get(ch,[]):
            H(a,b)
    word='CORONADO'
    s=w*0.105
    x0=(w-len(word)*s*0.80)/2
    for i,ch in enumerate(word):
        glyph(ch, x0+i*s*0.80, h*0.05, s, [0.93,0.86,0.66])
    word='SURF'
    s=w*0.175
    x0=(w-len(word)*s*0.82)/2
    for i,ch in enumerate(word):
        glyph(ch, x0+i*s*0.82, h*0.80, s, [0.12,0.16,0.30])
    return _finish(col,ht,18)


def paint_floral():
    col,ht,w,h=_prep(0.82)
    wash(col,ht,np.ones((h,w),np.float32),[0.90,0.84,0.70],1)
    rr=np.random.default_rng(19)
    for i in range(10):
        stamp(col,ht,rr.uniform(0,w),rr.uniform(0,h),55,40,0,[0.82,0.74,0.58],0.08,0.0,hard=0.25)
    # trailing stems
    stroke(col,ht,w*0.15,h*0.95,w*0.40,h*0.40, 2.0, [0.30,0.38,0.22], 0.55, 0.01, wobble=2.5)
    stroke(col,ht,w*0.40,h*0.55,w*0.78,h*0.20, 1.8, [0.30,0.38,0.22], 0.5, 0.01, wobble=2.0)
    stroke(col,ht,w*0.35,h*0.70,w*0.70,h*0.80, 1.8, [0.30,0.38,0.22], 0.5, 0.01, wobble=2.0)
    def leaf(x0,y0,x1,y1, rgb):
        stroke(col,ht,x0,y0,x1,y1, 1.4, np.array(rgb)*0.8, 0.6, 0.008, wobble=0.8)
        ang=math.atan2(y1-y0,x1-x0); L=math.hypot(x1-x0,y1-y0)
        for t in (0.3,0.55,0.8):
            px,py=x0+(x1-x0)*t, y0+(y1-y0)*t
            side=L*0.28
            stroke(col,ht,px,py,px+side*math.cos(ang+1.1),py+side*math.sin(ang+1.1), 3.5, rgb, 0.5, 0.01)
    for (a,b,c,d) in ((w*0.30,h*0.70,w*0.14,h*0.58),(w*0.48,h*0.50,w*0.30,h*0.40),
                      (w*0.62,h*0.36,w*0.80,h*0.28),(w*0.55,h*0.75,w*0.72,h*0.68)):
        leaf(a,b,c,d,[0.34,0.44,0.26])
    def rose(cx,cy,r, rgb, seed):
        rr=np.random.default_rng(seed)
        for k in range(16):
            a=k*0.40 + 0.15
            rad=r*(0.35+0.55*(k%5)/5)
            px,py=cx+rad*math.cos(a), cy+rad*0.9*math.sin(a)
            stamp(col,ht,px,py, r*0.42, r*0.22, a,
                  np.clip(np.array(rgb)*(0.82+0.28*rr.random()),0,1), 0.42, 0.016, hard=0.38)
        stamp(col,ht,cx,cy, r*0.22, r*0.22, 0, np.array(rgb)*0.65+[0.12,0.06,0], 0.65, 0.02, hard=0.5)
    rose(w*0.40,h*0.40, 42, [0.72,0.26,0.30], 41)
    rose(w*0.68,h*0.30, 32, [0.64,0.20,0.34], 42)
    rose(w*0.60,h*0.62, 36, [0.76,0.34,0.28], 43)
    rose(w*0.28,h*0.66, 26, [0.62,0.24,0.30], 44)
    rose(w*0.78,h*0.52, 22, [0.70,0.30,0.32], 45)
    return _finish(col,ht,19)


def paint_portrait():
    col,ht,w,h=_prep(0.80)
    # olive-brown studio, mid-century
    yy=np.linspace(0,1,h,dtype=np.float32)[:,None]
    col[:]=lerp(np.array([0.42,0.40,0.32]), np.array([0.58,0.50,0.38]), yy)
    # soft vignette
    wash(col,ht,1-disc_mask(h,w,w*0.5,h*0.45,h*0.7,0.8),[0.28,0.26,0.22],0.35)
    # shoulders / jacket as a simple mass
    jacket=np.zeros((h,w),np.float32)
    yy2,xx=np.mgrid[0:h,0:w].astype(np.float32)
    # trapezoid torso
    jacket[(yy2>h*0.64) & (np.abs(xx-w*0.5) < w*0.32+(yy2-h*0.64)*0.25)]=1
    wash(col,ht,blur(jacket,2.0),[0.18,0.20,0.28],0.92)
    # pale collar
    stroke(col,ht,w*0.38,h*0.66,w*0.62,h*0.66, 5.0, [0.82,0.78,0.70], 0.7, 0.01, taper=False)
    # neck
    neck=disc_mask(h,w,w*0.50,h*0.62,w*0.08,0.5)
    neck=np.where((yy2>h*0.54)&(yy2<h*0.70), neck, 0)
    wash(col,ht,neck,[0.74,0.56,0.44],0.85)
    # head — a filled ellipse, not a radial stamp
    head=disc_mask(h,w,w*0.50,h*0.40, w*0.20, 0.35)
    # squash vertically a little
    yy3,xx3=np.mgrid[0:h,0:w].astype(np.float32)
    head=np.clip(1-np.sqrt(((xx3-w*0.50)/(w*0.19))**2+((yy3-h*0.40)/(h*0.22))**2)/0.85,0,1)
    wash(col,ht,head,[0.78,0.60,0.46],0.95)
    # hair cap: dark brown mass over the crown and sides, bob-like
    hair=np.clip(1-np.sqrt(((xx3-w*0.50)/(w*0.22))**2+((yy3-h*0.30)/(h*0.20))**2)/0.85,0,1)
    hair=np.where(yy3<h*0.48, hair, hair*np.clip((h*0.54-yy3)/ (h*0.08),0,1))
    # open the face (subtract a lower ellipse)
    face_open=np.clip(1-np.sqrt(((xx3-w*0.50)/(w*0.15))**2+((yy3-h*0.42)/(h*0.16))**2)/0.9,0,1)
    hair=np.clip(hair-face_open*0.85,0,1)
    wash(col,ht,blur(hair,1.2),[0.16,0.10,0.08],0.92)
    # a few hair strokes for direction
    for a in np.linspace(-0.9, 0.9, 7):
        stroke(col,ht, w*0.50+w*0.16*math.sin(a), h*0.22+8*math.cos(a)*0.3,
               w*0.50+w*0.20*math.sin(a), h*0.38, 3.5, [0.12,0.08,0.06], 0.45, 0.008, wobble=0.8)
    # features, few confident marks
    stroke(col,ht,w*0.40,h*0.38,w*0.46,h*0.375, 1.6, [0.22,0.14,0.10], 0.75, 0.0)
    stroke(col,ht,w*0.54,h*0.375,w*0.60,h*0.38, 1.6, [0.22,0.14,0.10], 0.75, 0.0)
    stamp(col,ht,w*0.43,h*0.415, 3.4,2.6,0, [0.18,0.16,0.16], 0.85, 0.0, hard=0.65)
    stamp(col,ht,w*0.57,h*0.415, 3.4,2.6,0, [0.18,0.16,0.16], 0.85, 0.0, hard=0.65)
    # catchlights
    stamp(col,ht,w*0.435,h*0.410, 1.2,1.2,0, [0.9,0.88,0.84], 0.7, 0.0, hard=0.8)
    stamp(col,ht,w*0.575,h*0.410, 1.2,1.2,0, [0.9,0.88,0.84], 0.7, 0.0, hard=0.8)
    # nose hint, mouth
    stroke(col,ht,w*0.50,h*0.43,w*0.50,h*0.48, 1.4, [0.62,0.42,0.34], 0.4, 0.0)
    stroke(col,ht,w*0.46,h*0.515,w*0.54,h*0.515, 1.8, [0.58,0.30,0.28], 0.7, 0.0)
    # blush
    stamp(col,ht,w*0.40,h*0.47, 11,7,0, [0.80,0.46,0.38], 0.18, 0.0, hard=0.3)
    stamp(col,ht,w*0.60,h*0.47, 11,7,0, [0.80,0.46,0.38], 0.18, 0.0, hard=0.3)
    return _finish(col,ht,20)


def _finish(col, ht, seed):
    h,w=ht.shape
    g=canvas(h,w,seed)
    col=np.clip(col+g[...,None]*0.35,0,1)
    ht=ht+g*0.15
    # slight paper AO at the rim
    yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
    rim=np.minimum(np.minimum(xx,w-1-xx), np.minimum(yy,h-1-yy))
    edge=np.clip(1-rim/6.0,0,1)
    ao=np.clip(1.0 - 0.18*edge - 0.08*np.clip(-ht,0,None)*3, 0.55, 1.0)
    nor=nrm_from_height(blur(ht,0.6,'reflect'), 2.2)
    rough=np.clip(0.68 + 0.10*canvas(h,w,seed+3) + 0.08*edge, 0.4, 0.9)
    metal=np.zeros_like(ao)
    orm=np.dstack([ao, rough, metal])
 # slot packing into y=512..1023. Source paintings live in art_src/.
# Long side 128–256 px by on-screen importance (frame opening area).
# Cropped to the mat-inset opening aspect of the assigned frame.

ART_SRC='/workspace/coronado_kit_v2/_staging/house/art_src'

# name, source stem, aspect (opening w/h), long-side px, crop anchor (ax,ay), surface
# surface: 'oil' = canvas weave in normal + roughness; 'glaze' = low ORM roughness (glass sheen)
SPECS=[
    # hero wall piece (0.90 × 0.70)
    ('art_hotel',     'hotel',     1.345, 256, (0.50, 0.42), 'glaze'),
    ('art_mcm',       'mcm',       1.000, 240, (0.50, 0.50), 'glaze'),
    ('art_palms',     'palms',     0.372, 256, (0.48, 0.55), 'oil'),
    ('art_seascape',  'seascape',  1.521, 248, (0.50, 0.58), 'oil'),
    ('art_botanical', 'botanical', 0.723, 232, (0.50, 0.50), 'glaze'),
    ('art_floral',    'floral',    0.765, 208, (0.50, 0.52), 'oil'),
    ('art_surf',      'surf',      0.712, 176, (0.50, 0.50), 'glaze'),
    ('art_portrait',  'portrait',  0.722, 128, (0.50, 0.48), 'oil'),
]

def _slot_size(aspect, long):
    if aspect>=1:
        w,h=long, max(64,int(round(long/aspect)))
    else:
        h,w=long, max(64,int(round(long*aspect)))
    return int(w),int(h)

def crop_to_aspect(im, aspect, ax=0.5, ay=0.5):
    W,H=im.size
    if W/H > aspect:
        nw=int(round(H*aspect)); nh=H
    else:
        nw=W; nh=int(round(W/aspect))
    nx=int(round((W-nw)*ax)); ny=int(round((H-nh)*ay))
    nx=max(0,min(W-nw,nx)); ny=max(0,min(H-nh,ny))
    return im.crop((nx,ny,nx+nw,ny+nh))

def pack(rects):
    """rects: list of (name,w,h). Place with 8px gap in the 1024x512 bank starting y=512."""
    gap=8; x,y=8,512; row_h=0; out={}
    # place tallest first within a simple left-to-right wrap (stable, predictable)
    items=sorted(rects, key=lambda r: -r[2])
    for name,w,h in items:
        if x+w+gap>N:
            x=8; y+=row_h+gap; row_h=0
        if y+h>N:
            raise SystemExit(f'art bank overflow placing {name} at {x},{y} {w}x{h}')
        out[name]=(x,y,w,h)
        x+=w+gap; row_h=max(row_h,h)
    return out

def _rim(h,w, px=5.0):
    yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
    rim=np.minimum(np.minimum(xx,w-1-xx), np.minimum(yy,h-1-yy))
    return np.clip(1-rim/px,0,1)

def maps_oil(col, seed=1):
    """Canvas weave + residual brush thickness. ORM R = soft AO, G = cloth roughness."""
    h,w=col.shape[:2]
    rr=np.random.default_rng(seed)
    yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
    pu,pv=3.5, 3.15
    weave=0.5*(np.sin(xx*2*np.pi/pu)+np.sin(yy*2*np.pi/pv))
    cross=0.25*np.sin(xx*2*np.pi/pu)*np.sin(yy*2*np.pi/pv)
    grain=blur(rr.random((h,w)).astype(np.float32), 0.45)-0.5
    lum=(0.299*col[...,0]+0.587*col[...,1]+0.114*col[...,2]).astype(np.float32)
    brush=lum-blur(lum, 1.15)
    ht=weave*0.32 + cross*0.18 + grain*0.07 + brush*0.40
    nor=nrm_from_height(blur(ht, 0.35), 2.0)
    edge=_rim(h,w, 4.5)
    ao=np.clip(1.0 - 0.10*np.clip(0.25-weave,0,1) - 0.12*edge, 0.70, 1.0)
    rough=np.clip(0.64 + 0.12*weave + 0.07*grain + 0.06*edge, 0.48, 0.90)
    metal=np.zeros_like(ao)
    return nor, np.dstack([ao,rough,metal])

def maps_glaze(col, seed=2):
    """Almost-flat glass over the print. ORM G is low, with a soft diagonal sheen."""
    h,w=col.shape[:2]
    rr=np.random.default_rng(seed)
    lum=(0.299*col[...,0]+0.587*col[...,1]+0.114*col[...,2]).astype(np.float32)
    grain=blur(rr.random((h,w)).astype(np.float32), 0.6)-0.5
    # residual print texture, heavily damped under glass
    ht=blur(lum-blur(lum, 2.0), 0.8)*0.07 + grain*0.015
    nor=nrm_from_height(ht, 0.55)
    edge=_rim(h,w, 5.0)
    yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
    # broad diagonal catch-light in roughness only (not painted into colour)
    sheen=np.exp(-(((xx/(w-1)+yy/(h-1))-0.85)/0.38)**2)
    rough=np.clip(0.18 - 0.10*sheen + 0.03*grain + 0.04*edge, 0.06, 0.30)
    ao=np.clip(1.0 - 0.10*edge, 0.85, 1.0)
    metal=np.zeros_like(ao)
    return nor, np.dstack([ao,rough,metal])

def main():
    A=json.load(open(ATLP))
    R=A['regions']
    P={c:np.array(Image.open(f'{SRC}/props_h_base_color_{c}.png').convert('RGBA')) for c in ('clean','worn','dirty')}
    nor=np.array(Image.open(f'{SRC}/props_h_base_normal.png').convert('RGB'))
    orm=np.array(Image.open(f'{SRC}/props_h_base_orm.png').convert('RGB'))
    P={c:p.copy() for c,p in P.items()}
    for c in P:
        P[c][512:,:]=(128,128,128,255)
    nor[512:,:]=(128,128,255)
    orm[512:,:]=(255,180,0)

    painted=[]
    preview_rows=[]
    for name, stem, asp, long, (ax,ay), surf in SPECS:
        src=Path(ART_SRC)/f'{stem}.jpg'
        if not src.exists():
            raise SystemExit(f'missing painted source {src}')
        im=Image.open(src).convert('RGB')
        im=crop_to_aspect(im, asp, ax, ay)
        w,h=_slot_size(asp, long)
        im=im.resize((w,h), Image.Resampling.LANCZOS)
        col=np.asarray(im, np.float32)/255.0
        if surf=='oil':
            nr,om=maps_oil(col, seed=hash(name)%10007)
        else:
            nr,om=maps_glaze(col, seed=hash(name)%10007)
        painted.append((name,w,h,col,nr,om,surf))
        preview_rows.append((name, im, surf))
        print(f'  loaded {name} from {stem}.jpg  {w}x{h}  {surf}', flush=True)

    slots=pack([(n,w,h) for n,w,h,_,_,_,_ in painted])
    for name,w,h,col,nr,om,surf in painted:
        x,y,w,h=slots[name]
        c8=(np.clip(col,0,1)*255+0.5).astype(np.uint8)
        for c in P:
            P[c][y:y+h,x:x+w,:3]=c8; P[c][y:y+h,x:x+w,3]=255
        nor[y:y+h,x:x+w]=(np.clip(nr,0,1)*255+0.5).astype(np.uint8)
        orm[y:y+h,x:x+w]=(np.clip(om,0,1)*255+0.5).astype(np.uint8)
        pad=2
        for cond in ('clean','worn','dirty'):
            R[f'{name}.{cond}']={
                'px':[x,y,w,h],
                'uv':[(x+pad)/N,(y+pad)/N,(x+w-pad)/N,(y+h-pad)/N],
                'm':[1.0,1.0],
                'trim':True,'page':'h','tile_px':min(w,h),'art':True,'surface':surf
            }
        print(' placed',name,'at',(x,y),'size',(w,h),'surface',surf)

    for c in P:
        Image.fromarray(P[c]).save(f'{SRC}/props_h_base_color_{c}.png')
        Image.fromarray(P[c]).save(f'{SRC}/props_src_color_{c}.png')
    Image.fromarray(nor).save(f'{SRC}/props_h_base_normal.png')
    Image.fromarray(orm).save(f'{SRC}/props_h_base_orm.png')
    Image.fromarray(nor).save(f'{SRC}/props_src_normal.png')
    Image.fromarray(orm).save(f'{SRC}/props_src_orm.png')
    tmp=ATLP+'.tmp'; json.dump(A,open(tmp,'w'),indent=1); os.replace(tmp,ATLP)

    outdir='/workspace/coronado_kit_v2/_staging/house/previews'
    os.makedirs(outdir, exist_ok=True)
    tw=320; pads=16; label=28
    cols=4; rows=2
    grid=Image.new('RGB',(cols*(tw+pads)+pads, rows*(tw+pads+label)+pads),(32,32,34))
    try:
        font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 16)
    except Exception:
        font=ImageFont.load_default()
    d=ImageDraw.Draw(grid)
    for i,(name,im,surf) in enumerate(preview_rows):
        r,c=divmod(i,cols)
        scale=min(tw/im.width, tw/im.height)
        im=im.resize((max(1,int(im.width*scale)), max(1,int(im.height*scale))), Image.Resampling.LANCZOS)
        x=pads+c*(tw+pads)+(tw-im.width)//2
        y=pads+r*(tw+pads+label)+label+(tw-im.height)//2
        grid.paste(im,(x,y))
        d.text((pads+c*(tw+pads), pads+r*(tw+pads+label)+4),
               f"{name.replace('art_','')}  ({surf})", fill=(230,230,225), font=font)
    grid.save(outdir+'/house_art_bank.jpg', quality=92)
    print('wrote', outdir+'/house_art_bank.jpg', 'and updated base atlas')

if __name__=='__main__':
    main()
