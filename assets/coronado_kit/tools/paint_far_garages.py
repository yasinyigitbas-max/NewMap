#!/usr/bin/env python3
"""Paint the garage / carport far faces into free spans of two far strips (MAP_NEEDS item 2, far detail under the 12-tri cap).
Each design's far is a 10-tri box; each of its 4 wall faces maps (houses_map._far_painted) to its own slot of F_stucco_1
(row A: 1-car), F_siding_1 (row B: 2-car) or F_bb_1 (row C: carports), all from u=60 m. Stretch-stamp far faces (<= 80 m,
|u| <= ~45 m with far_u0) never sample u 60-155 m; negative u wraps to u > 160 m. The slot shows the mid at far scale: wall colour (the far wall strip x tint), the garage door
(light panels), person door, window, carport open bay (dark) + post / beams (trim), gable / rake fascia / roof above the eaves.
Idempotent (slots and pads are fully overwritten). The untouched atlas is kept in _archive/far_color_pre_garage_paint_16nov.png."""
import os, sys, shutil
os.environ.setdefault('KIT_ATLAS','house')
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE); KIT=os.path.dirname(HERE)
import numpy as np
from PIL import Image
import build, houses_map as H
FC=KIT+'/textures/far_color.png'; BK=KIT+'/_archive/far_color_pre_garage_paint_16nov.png'
if not os.path.exists(BK): os.makedirs(os.path.dirname(BK),exist_ok=True); shutil.copy2(FC,BK)
A=np.asarray(Image.open(BK).convert('RGB')).astype(np.float32)/255.0   # always paint over the pristine atlas
OUT=A.copy()
def strip(key):
    x0,y0,x1,y1=build.FAR[key]['px']; return A[y0:y1,x0:x1]
def tex(key,hpx,wpx,tile_m=None,h_m=None,ss=1):
    """wall / roof strip resampled to hpx x wpx (10 px per m horizontally; vertical: the strip's tile spans tile_m metres)"""
    s=strip(key); sh=s.shape[0]
    ys=(np.arange(hpx)+0.5)/hpx*h_m if h_m else np.arange(hpx)
    rows=((ys/tile_m)*sh).astype(int)%sh if tile_m else np.arange(hpx)%sh
    cols=(np.arange(wpx)//ss)%s.shape[1]
    return s[rows][:,cols]
def col(key): return strip(key).reshape(-1,3).mean(0)
GLASS=col('F_glass'); DOOR=np.array([0.84,0.84,0.82]); LINE=np.array([0.60,0.60,0.58])
TERRA=np.array([0.62,0.36,0.26])
ROOFK={'R_comp':'F_comp','R_clay':'F_clay','R_flat':'F_flat','R_metal':'F_metal','R_shake':'F_shake'}
SS=4   # paint at 4x and box-filter down: anti-aliased rake / gable edges and opening borders
def paint_face(pt,sd,w,hpx=35):
    img,pad=_paint(pt,sd,w,hpx*SS,SS)
    H_,W_=img.shape[:2]
    return img.reshape(H_//SS,SS,W_//SS,SS,3).mean((1,3)),pad
def _paint(pt,sd,w,hpx,ss):
    h=pt['top']; W=pt['W']; wpx=int(round(w*10))*ss; pad=3
    WPX=wpx+2*pad*ss
    wallkey='F_'+pt['wall'][2:]+'_blank'
    img=tex(wallkey,hpx,WPX//ss*ss,tile_m=3.0,h_m=h,ss=ss)*np.array(pt['tint'])
    rimg=tex(ROOFK[pt['roof']],hpx,WPX,tile_m=8.0,h_m=h,ss=ss)
    shade=img*0.62                                 # the stucco wall seen through an open bay, in shade
    trim=np.array(pt['trim'])
    Y=(hpx-1-np.arange(hpx)+0.5)/hpx*h            # metres at each pixel row (row 0 = top)
    U=(np.arange(WPX)-pad*ss+0.5)/(10.0*ss)               # metres from the face's left edge
    UU,YY=np.meshgrid(U,Y)
    def fill(mask,c): img[mask]=c if np.ndim(c)==1 else c[mask]
    gable_end=(pt['kind'] in ('gable','carport')) and sd in ('front','back')
    if pt['kind']=='flat':
        fill(YY>h-0.10,TERRA)                     # terracotta coping on the parapet
    elif gable_end:
        o=0.3 if pt['kind']=='gable' else 0.25
        half=w/2+o; yr=W+(h-W)*(1-np.abs(UU-w/2)/half)  # rake line (roof underside at the face)
        if pt['kind']=='carport':
            fill((YY>W)&(YY<=yr-0.14),trim)       # carport: the roof's gable-end triangle is trim
        fill((YY>yr-0.14)&(YY<=yr),trim)          # rake fascia
        fill(YY>yr,rimg)                          # roof seen above the rake
    else:
        fill((YY>W)&(YY<=W+0.16),trim)            # eave fascia / gutter
        fill(YY>W+0.16,rimg)
    for (k,a,b,y0,y1) in pt['el'].get(sd,[]):
        m=(UU>=a)&(UU<b)&(YY>=y0)&(YY<y1)
        if k=='garage':
            fr=(UU>=a-0.1)&(UU<b+0.1)&(YY>=y0)&(YY<y1+0.1); fill(fr,trim); fill(m,DOOR)
            for yl in np.arange(y0+0.55,y1-0.1,0.55): fill(m&(np.abs(YY-yl)<0.06),LINE)   # panel joints
        elif k=='door':
            fr=(UU>=a-0.08)&(UU<b+0.08)&(YY>=y0)&(YY<y1+0.08); fill(fr,trim); fill(m,trim*0.92)
        elif k=='window':
            fr=(UU>=a-0.08)&(UU<b+0.08)&(YY>=y0-0.08)&(YY<y1+0.08); fill(fr,trim); fill(m,GLASS)
        elif k=='bay':
            fill(m,shade); fill(m&(YY<y0+0.18),shade*0.62)   # lit back / side wall in shade, darker slab band at the floor
        elif k in ('post','beam'): fill(m,trim)
    return img,pad
def main():
    slots=H._far_slots()
    for f in H.GAR:
        b=f(); pt=getattr(b,'_paint',None)
        if not pt: continue
        for sd,(key,U) in slots[b.name].items():
            w=H._face_w(pt,sd); x0,y0,x1,y1=build.FAR[key]['px']
            img,pad=paint_face(pt,sd,w,hpx=y1-y0)
            c0=int(round(U*10))-pad
            OUT[y0:y1,c0:c0+img.shape[1]]=np.clip(img,0,1)
            print(b.name,sd,key,f'u {U:.1f}-{U+w:.1f} m  px {c0}-{c0+img.shape[1]}')
    import paint_far_stg; paint_far_stg.paint(OUT)   # the merged stg rows' far front slot (F_bb_1 u 100-118 m), kept on a repaint
    Image.fromarray((OUT*255+0.5).astype(np.uint8)).save(FC)
    print('wrote',FC)
if __name__=='__main__': main()
