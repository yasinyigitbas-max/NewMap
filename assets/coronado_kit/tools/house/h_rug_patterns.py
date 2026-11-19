#!/usr/bin/env python3
"""Paint eight rug pattern bands into page H, y=192–255, x=256–1023.

Does not touch trim tiles, tint swatches, the art bank, bake slots,
or the main A/B/C/W / page I atlases. Runtime stays 1.75 MB.

Run: python3 tools/h_rug_patterns.py && IN_KIT=... python3 kit/props/_tools/props_compose.py h
"""
import json, os, math
from pathlib import Path
import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont

K=os.environ.get('IN_KIT','/workspace/coronado_kit_v2/_staging/house/kit')
SRC=K+'/props/_bake_src'
ATLP=K+'/atlases/props_atlas.json'
N=1024
# reserved free band: right of rattan/stone (x>=256), below bake slots (y<256), above swatches (y>=192)
BAND_X0, BAND_Y0, BAND_W, BAND_H = 256, 192, 768, 64
GAP=4

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

def wrap_grad(a, axis):
    return np.gradient(a, axis=axis)

def pile_maps(col, ht, rough0=0.78, ao_amt=0.12, nrm_amp=2.4, blur_s=0.4):
    h,w=ht.shape
    nor=nrm_from_height(blur(ht,blur_s), nrm_amp)
    edge=np.zeros((h,w),np.float32)
    # soft tile-seam AO only if we want; keep field open
    ao=np.clip(1.0 - ao_amt*np.clip(-ht,0,None)*2.0, 0.65, 1.0)
    rough=np.clip(rough0 + 0.10*ht + 0.04*(np.random.default_rng(3).random((h,w))-0.5), 0.45, 0.95)
    metal=np.zeros_like(ao)
    return col, nor, np.dstack([ao,rough,metal])

# ------------------------------------------------------------------ patterns (u,v in 0-1)

def pat_mcm(w,h):
    # one-shot panel, aspect ~1.41, hard-edged Girard/MCM motif with a border
    uu,vv=np.meshgrid(np.linspace(0,1,w,endpoint=True,dtype=np.float32),
                      np.linspace(0,1,h,endpoint=True,dtype=np.float32))
    cream=np.array([0.86,0.80,0.68],np.float32)
    navy=np.array([0.16,0.20,0.32],np.float32)
    mustard=np.array([0.78,0.58,0.18],np.float32)
    olive=np.array([0.32,0.38,0.24],np.float32)
    rust=np.array([0.62,0.28,0.20],np.float32)
    gold=np.array([0.70,0.54,0.24],np.float32)
    col=np.broadcast_to(cream,(h,w,3)).copy()
    def stamp(mask, rgb):
        nonlocal col
        col=np.where(np.asarray(mask)[...,None], np.array(rgb,np.float32), col)
    def ell(cx,cy,rx,ry):
        return ((uu-cx)/rx)**2+((vv-cy)/ry)**2 <= 1.0
    # mustard boomerang
    stamp(ell(0.40,0.50,0.32,0.26) & ~ell(0.50,0.40,0.20,0.16), mustard)
    # olive kidney
    stamp(ell(0.74,0.44,0.16,0.24) & ~ell(0.82,0.52,0.08,0.12), olive)
    # navy vertical slab and top bar
    stamp((uu>0.14)&(uu<0.23)&(vv>0.22)&(vv<0.78), navy)
    stamp((uu>0.48)&(uu<0.86)&(vv>0.22)&(vv<0.30), navy)
    stamp(ell(0.58,0.70,0.09,0.13), rust)
    stamp(ell(0.30,0.72,0.06,0.09), mustard)
    # navy border + thin gold inner line (hard)
    bw,gw=0.075,0.022
    on_navy=((uu<bw)|(uu>1-bw)|(vv<bw*1.15)|(vv>1-(bw*1.15)))
    on_gold=((uu<bw+gw)|(uu>1-(bw+gw))|(vv<(bw+gw)*1.15)|(vv>1-(bw+gw)*1.15)) & ~on_navy
    stamp(on_gold, gold)
    stamp(on_navy, navy)
    rr=np.random.default_rng(11).random((h,w)).astype(np.float32)
    col=np.clip(col*(0.97+0.06*blur(rr,0.5)[...,None]),0,1)
    ht=0.06*blur(rr,0.5)+0.04*on_navy.astype(np.float32)
    return pile_maps(col, ht, 0.80)

def pat_jute(w,h):
    # wide basket ribs that survive the 512/256 normal downsample
    # (period ~16 px in a 64 px tile -> ~8 px in the 32 px normal)
    uu,vv=np.meshgrid(np.linspace(0,1,w,endpoint=False,dtype=np.float32),
                      np.linspace(0,1,h,endpoint=False,dtype=np.float32))
    pu,pv=4.0,4.0
    cu=(uu*pu)%1; cv=(vv*pv)%1
    horiz=((np.floor(uu*pu).astype(int)+np.floor(vv*pv).astype(int))%2==0)
    fibre_h=np.sin(cv*math.pi)
    fibre_v=np.sin(cu*math.pi)
    fibre=np.where(horiz, fibre_h, fibre_v)
    tan=np.array([0.70,0.56,0.34],np.float32)
    straw=np.array([0.84,0.72,0.48],np.float32)
    dark=np.array([0.42,0.32,0.18],np.float32)
    col=tan*(0.45+0.55*(fibre*0.5+0.5))[...,None] + straw*0.12
    gap=((cu<0.10)|(cv<0.10))
    col=np.where(gap[...,None], dark*0.75+col*0.25, col)
    rr=np.random.default_rng(12).random((h,w)).astype(np.float32)
    col=np.clip(col*(0.94+0.12*blur(rr,0.5)[...,None]),0,1)
    ht=0.70*fibre + 0.08*blur(rr,0.5) - 0.35*gap.astype(np.float32)
    return pile_maps(col, ht, 0.86, nrm_amp=5.0, blur_s=0.25)

def pat_floral(w,h):
    # tileable motel floral field (border is a mesh bind). Hard edges, wrap-safe.
    uu,vv=np.meshgrid(np.linspace(0,1,w,endpoint=False,dtype=np.float32),
                      np.linspace(0,1,h,endpoint=False,dtype=np.float32))
    field=np.array([0.80,0.74,0.58],np.float32)
    col=np.broadcast_to(field,(h,w,3)).copy()
    def wrap(d):
        return d-np.round(d)
    def leaf(cx,cy,rx,ry,ang,rgb,alpha=0.95):
        ca,sa=math.cos(ang),math.sin(ang)
        dx,dy=wrap(uu-cx), wrap(vv-cy)
        u= ca*dx+sa*dy; v=-sa*dx+ca*dy
        d=np.sqrt((u/max(rx,1e-6))**2+(v/max(ry,1e-6))**2)
        # ~1 px AA, otherwise a hard silhouette
        aa=max(1.2/max(w,h), 0.06)
        m=np.clip((1.0-d)/aa, 0, 1)
        nonlocal col
        col=col*(1-m[...,None]*alpha)+np.array(rgb,np.float32)*m[...,None]*alpha
    def bloom(cx,cy,r,rgb, n=6):
        for k in range(n):
            a=2*math.pi*k/n + 0.18
            leaf(cx+r*0.40*math.cos(a), cy+r*0.40*math.sin(a), r*0.44, r*0.28, a, rgb, 0.96)
        heart=np.clip(np.array(rgb,np.float32)*0.65+np.array([0.18,0.10,0.0],np.float32),0,1)
        leaf(cx,cy,r*0.26,r*0.26,0, heart, 0.98)
    leaf_c=np.array([0.26,0.38,0.20],np.float32)
    leaf_d=np.array([0.20,0.30,0.16],np.float32)
    # a few wrap-safe sprays so the tile repeats cleanly at 0.45 x 0.40 m
    leaf(0.18,0.28,0.07,0.14, 0.7, leaf_c)
    leaf(0.18,0.28,0.06,0.12,-0.5, leaf_d)
    leaf(0.70,0.22,0.07,0.13,-0.8, leaf_c)
    leaf(0.62,0.78,0.08,0.14, 0.4, leaf_d)
    leaf(0.88,0.58,0.06,0.12, 0.2, leaf_c)
    leaf(0.08,0.72,0.06,0.11,-0.3, leaf_d)
    bloom(0.38,0.48,0.13,[0.72,0.22,0.28],6)
    bloom(0.78,0.68,0.11,[0.76,0.34,0.26],6)
    bloom(0.58,0.18,0.10,[0.64,0.18,0.22],5)
    bloom(0.14,0.82,0.09,[0.70,0.28,0.30],5)
    col=np.clip(col,0,1)
    rr=np.random.default_rng(13).random((h,w)).astype(np.float32)
    # keep a hint of weave, no soft blur on the motif itself
    col=np.clip(col*(0.98+0.03*rr[...,None]),0,1)
    ht=0.05*rr+0.04*np.sin(uu*18*np.pi)+0.03*np.sin(vv*14*np.pi)
    return pile_maps(col, ht, 0.76, blur_s=0.15, nrm_amp=1.6)

def pat_runner(w,h):
    uu,vv=np.meshgrid(np.linspace(0,1,w,endpoint=False,dtype=np.float32),
                      np.linspace(0,1,h,endpoint=False,dtype=np.float32))
    cream=np.array([0.84,0.78,0.62],np.float32)
    navy=np.array([0.14,0.18,0.30],np.float32)
    rust=np.array([0.58,0.26,0.18],np.float32)
    # stripes along v (length of the runner when v is the short period? )
    # tile will be mapped with u along width of runner (0.70) and v along length — set later
    s=(uu*6)%1
    col=np.broadcast_to(cream,(h,w,3)).copy()
    col=np.where(((s<0.18)|(s>0.82))[...,None], navy, col)
    col=np.where(((s>0.40)&(s<0.52))[...,None], rust, col)
    # thin pinstripe
    col=np.where(((s>0.22)&(s<0.25))[...,None], navy*0.7+cream*0.3, col)
    rr=np.random.default_rng(14).random((h,w)).astype(np.float32)
    col=np.clip(col*(0.96+0.08*blur(rr,0.5)[...,None]),0,1)
    ht=0.06*np.sin(uu*w*1.2)+0.05*blur(rr,0.5)
    return pile_maps(col, ht, 0.80)

def pat_accent(w,h):
    uu,vv=np.meshgrid(np.linspace(0,1,w,endpoint=True,dtype=np.float32),
                      np.linspace(0,1,h,endpoint=True,dtype=np.float32))
    sand=np.array([0.80,0.72,0.54],np.float32)
    teal=np.array([0.22,0.40,0.40],np.float32)
    mustard=np.array([0.76,0.56,0.20],np.float32)
    col=np.broadcast_to(sand,(h,w,3)).copy()
    # concentric diamond
    d=np.abs(uu-0.5)+np.abs(vv-0.5)
    col=np.where((d<0.22)[...,None], teal, col)
    col=np.where(((d>=0.22)&(d<0.30))[...,None], mustard, col)
    col=np.where(((d>=0.42)&(d<0.50))[...,None], teal, col)
    # border
    b=np.minimum(np.minimum(uu,1-uu), np.minimum(vv,1-vv))
    col=np.where((b<0.07)[...,None], teal*0.7, col)
    rr=np.random.default_rng(15).random((h,w)).astype(np.float32)
    col=np.clip(col*(0.96+0.08*blur(rr,0.5)[...,None]),0,1)
    ht=0.05*blur(rr,0.5)+0.03*np.sin((uu+vv)*30)
    return pile_maps(col, ht, 0.78)

def pat_round(w,h):
    # circular medallion in a square; corners will be cut by the disc mesh
    uu,vv=np.meshgrid(np.linspace(-1,1,w,dtype=np.float32),
                      np.linspace(-1,1,h,dtype=np.float32))
    r=np.sqrt(uu*uu+vv*vv)
    ang=np.arctan2(vv,uu)
    cream=np.array([0.86,0.80,0.64],np.float32)
    navy=np.array([0.16,0.22,0.34],np.float32)
    gold=np.array([0.72,0.54,0.22],np.float32)
    teal=np.array([0.24,0.42,0.42],np.float32)
    col=np.broadcast_to(cream,(h,w,3)).copy()
    rings=[(0.18,navy),(0.28,gold),(0.48,cream),(0.58,teal),(0.78,cream),(0.90,navy),(0.98,gold)]
    prev=0.0
    for rad,c in rings:
        m=((r>=prev)&(r<rad))
        col=np.where(m[...,None], c, col)
        prev=rad
    # sunburst in the center
    sun=(r<0.18)*(0.5+0.5*np.cos(ang*12))
    col=col*(1-0.35*sun[...,None])+gold*0.35*sun[...,None]
    # outside the circle: navy (won't be seen)
    col=np.where((r>1.0)[...,None], navy, col)
    rr=np.random.default_rng(16).random((h,w)).astype(np.float32)
    col=np.clip(col*(0.96+0.08*blur(rr,0.5)[...,None]),0,1)
    ht=0.05*blur(rr,0.5)+0.04*np.sin(r*18)
    return pile_maps(col, ht, 0.78)

def pat_terry(w,h):
    rr=np.random.default_rng(17)
    # loop clusters
    n=max(w,h)
    loops=np.zeros((h,w),np.float32)
    yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
    for i in range(int(w*h*0.35)):
        cx,cy=rr.uniform(0,w-1), rr.uniform(0,h-1)
        rad=rr.uniform(1.1,2.2)
        d=np.sqrt((xx-cx)**2+(yy-cy)**2)
        loops+=np.clip(1-(d/rad)**2,0,0.8)*rr.uniform(0.4,1.0)
    loops=np.clip(loops,0,1)
    loops=blur(loops,0.35)
    cotton=np.array([0.86,0.84,0.78],np.float32)
    shadow=np.array([0.70,0.68,0.62],np.float32)
    col=cotton*(0.7+0.3*loops)[...,None] + shadow*(1-loops)[...,None]*0.15
    col=np.clip(col,0,1)
    ht=0.28*loops + 0.04*rr.random((h,w)).astype(np.float32)
    return pile_maps(col, ht, 0.88, ao_amt=0.08)

def pat_shag(w,h):
    # calm solid rust shag: one hue, subtle darker valleys, pile in the normal
    rr=np.random.default_rng(18)
    yy,xx=np.mgrid[0:h,0:w].astype(np.float32)
    rust=np.array([0.62,0.28,0.16],np.float32)
    rust_d=np.array([0.46,0.20,0.12],np.float32)
    ht=np.full((h,w),0.20,np.float32)
    def wrap_d(cx,cy):
        dx=np.minimum(np.abs(xx-cx), np.minimum(np.abs(xx-cx+w), np.abs(xx-cx-w)))
        dy=np.minimum(np.abs(yy-cy), np.minimum(np.abs(yy-cy+h), np.abs(yy-cy-h)))
        return np.sqrt(dx*dx+dy*dy)
    for i in range(28):
        cx,cy=rr.uniform(0,w-1), rr.uniform(0,h-1)
        rad=rr.uniform(6.0,12.0)
        m=np.clip(1.0-(wrap_d(cx,cy)/rad)**2,0,1)**0.65
        ht=np.maximum(ht, m*rr.uniform(0.70,1.0))
    flock=rr.random((h,w)).astype(np.float32)
    ht=np.clip(ht+0.08*(flock-0.4),0,1)
    # colour stays in the rust family — valleys a little darker, not a second hue
    mix=np.clip(0.35+0.65*ht,0,1)
    col=rust_d*(1-mix[...,None])+rust*mix[...,None]
    col=np.clip(col*(0.96+0.06*blur(flock,0.8)[...,None]),0,1)
    return pile_maps(col, ht, 0.92, ao_amt=0.12, nrm_amp=6.0, blur_s=0.35)

# name, fn, slot w,x offset computed, tiling?, period_m (Pu,Pv)
SPECS=[
    ('tr_rug_mcm',    pat_mcm,     90, False, (2.32, 1.62)),  # one-shot, field aspect ~1.43
    ('tr_rug_jute',   pat_jute,    64, True,  (0.40, 0.40)),
    ('tr_rug_floral', pat_floral, 160, True,  (0.45, 0.40)),  # tiled in-band, sharper px/m; slot unmoved
    ('tr_rug_runner', pat_runner,  96, True,  (0.70, 0.35)),  # u across the 0.70 width
    ('tr_rug_accent', pat_accent,  96, False, (1.20, 0.80)),
    ('tr_rug_round',  pat_round,   64, False, (1.50, 1.50)),
    ('tr_rug_terry',  pat_terry,   64, True,  (0.25, 0.25)),
    ('tr_rug_shag',   pat_shag,    96, True,  (0.40, 0.40)),
]

def main():
    A=json.load(open(ATLP))
    R=A['regions']
    P={c:np.array(Image.open(f'{SRC}/props_h_base_color_{c}.png').convert('RGBA')) for c in ('clean','worn','dirty')}
    nor=np.array(Image.open(f'{SRC}/props_h_base_normal.png').convert('RGB'))
    orm=np.array(Image.open(f'{SRC}/props_h_base_orm.png').convert('RGB'))
    # clear only the reserved rug band (leave swatches, rattan, stone, art, bakes)
    for c in P:
        P[c][BAND_Y0:BAND_Y0+BAND_H, BAND_X0:BAND_X0+BAND_W]=(128,128,128,255)
    nor[BAND_Y0:BAND_Y0+BAND_H, BAND_X0:BAND_X0+BAND_W]=(128,128,255)
    orm[BAND_Y0:BAND_Y0+BAND_H, BAND_X0:BAND_X0+BAND_W]=(255,200,0)

    x=BAND_X0
    preview=[]
    for name,fn,pw, tiling, period in SPECS:
        if x+pw>BAND_X0+BAND_W:
            raise SystemExit(f'rug band overflow at {name}')
        y,w,h=BAND_Y0, pw, BAND_H
        col,nr,om=fn(w,h)
        c8=(np.clip(col,0,1)*255+0.5).astype(np.uint8)
        for c in P:
            P[c][y:y+h,x:x+w,:3]=c8; P[c][y:y+h,x:x+w,3]=255
        nor[y:y+h,x:x+w]=(np.clip(nr,0,1)*255+0.5).astype(np.uint8)
        orm[y:y+h,x:x+w]=(np.clip(om,0,1)*255+0.5).astype(np.uint8)
        pad=1 if tiling else 2
        for cond in ('clean','worn','dirty'):
            R[f'{name}.{cond}']={
                'px':[x,y,w,h],
                'uv':[(x+pad)/N,(y+pad)/N,(x+w-pad)/N,(y+h-pad)/N],
                'm':[period[0], period[1]],
                'trim':True,'page':'h','tile_px':min(w,h),'rug':True,'tiling':tiling
            }
        print(f'  placed {name} at ({x},{y}) {w}x{h} tiling={tiling} period={period}')
        preview.append((name, Image.fromarray(c8), tiling))
        x+=pw+GAP

    for c in P:
        Image.fromarray(P[c]).save(f'{SRC}/props_h_base_color_{c}.png')
        Image.fromarray(P[c]).save(f'{SRC}/props_src_color_{c}.png')
    Image.fromarray(nor).save(f'{SRC}/props_h_base_normal.png')
    Image.fromarray(orm).save(f'{SRC}/props_h_base_orm.png')
    Image.fromarray(nor).save(f'{SRC}/props_src_normal.png')
    Image.fromarray(orm).save(f'{SRC}/props_src_orm.png')
    tmp=ATLP+'.tmp'; json.dump(A,open(tmp,'w'),indent=1); os.replace(tmp,ATLP)

    # contact of the eight bands, scaled up
    outdir='/workspace/coronado_kit_v2/_staging/house/previews'
    os.makedirs(outdir, exist_ok=True)
    scale=4
    pad=12; label=22
    tiles=[]
    for name,im,tiling in preview:
        im=im.resize((im.width*scale, im.height*scale), Image.Resampling.NEAREST)
        tiles.append((name.replace('tr_rug_',''), im, tiling))
    W=pad+sum(im.width+pad for _,im,_ in tiles)
    H=pad+label+max(im.height for _,im,_ in tiles)+pad
    grid=Image.new('RGB',(W,H),(32,32,34))
    try:
        font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
    except Exception:
        font=ImageFont.load_default()
    d=ImageDraw.Draw(grid)
    x=pad
    for name,im,tiling in tiles:
        d.text((x,6), f"{name}{'  tile' if tiling else '  panel'}", fill=(230,230,226), font=font)
        grid.paste(im,(x, pad+label))
        x+=im.width+pad
    grid.save(outdir+'/house_rug_bands.jpg', quality=92)
    print('wrote', outdir+'/house_rug_bands.jpg')

if __name__=='__main__':
    main()
