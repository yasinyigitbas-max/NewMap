"""Indoor gift / books / pharmacy props — original geometry, page I, near+col only.

card_spinner, gallery_frame, pharmacy_shelf, bookcase.
Unique merch in the bake; no unique card on high; silhouettes inside the cage.
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT,
)

# ------------------------------------------------------------------ card_spinner
def card_spinner(b, hi=False):
    H=1.55
    R=0.28
    # base + column
    b.tube((0,0,0.0),(0,0,0.04),0.22,0.22,sg(hi,12,16),'steel',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.04),(0,0,0.08),0.16,0.14,sg(hi,10,14),'steel',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,0.08),(0,0,H-0.06),0.018,0.018,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
    # three tiers, six pockets each — the card itself is the goods plane
    tiers=(0.42,0.82,1.22)
    n=6
    bodies=('paint_navy','paint_cream','leaf','oak','fabric','brass')
    for ti,z in enumerate(tiers):
        b.tube((0,0,z),(0,0,z+0.016),0.055,0.055,sg(hi,8,12),'chrome',cap0=True,cap1=True,smooth=True)
        # ring (open cylinder wall)
        b.tube((0,0,z+0.004),(0,0,z+0.012),R,R,sg(hi,10,14),'chrome',cap0=False,cap1=False,smooth=True)
        for i in range(n):
            a=2*math.pi*i/n
            deg=math.degrees(a)+90
            cx,cy=(R-0.02)*math.cos(a),(R-0.02)*math.sin(a)
            # steel lip under the card
            b.box((cx,cy,z+0.02),(0.09,0.04,0.010),'steel',rz=deg)
            if not hi:
                b.box((cx,cy,z+0.04),(0.08,0.006,0.20),'goods',rz=deg)
            if hi:
                ox=-0.010*math.cos(a); oy=-0.010*math.sin(a)
                b.box((cx+ox,cy+oy,z+0.05),(0.07,0.004,0.18),bodies[(ti+i)%len(bodies)],rz=deg)
                b.box((cx+ox*1.2,cy+oy*1.2,z+0.15),(0.05,0.003,0.04),'label',rz=deg)
    b.tube((0,0,H-0.06),(0,0,H),0.04,0.015,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,-0.16,0.05),hi,w=0.06,h=0.014)
    b.ccyl((0,0,0),0.32,H)


def gallery_frame(b, hi=False):
    W,D,H=0.70,0.06,0.90
    fw=0.055
    # hollow frame, not a solid slab (art must be visible on the front)
    b.box((0,0,0.0),(W,D,fw),'oak',skip=('bottom',))
    b.box((0,0,H-fw),(W,D,fw),'oak')
    b.box((-(W/2)+fw/2,0,0.0),(fw,D,H),'oak',skip=('bottom',))
    b.box(((W/2)-fw/2,0,0.0),(fw,D,H),'oak',skip=('bottom',))
    # inner step
    fw2=0.028
    b.box((0,-0.008,fw-0.006),(W-fw,0.02,fw2),'oak')
    b.box((0,-0.008,H-fw-fw2+0.006),(W-fw,0.02,fw2),'oak')
    b.box((-(W/2)+fw+fw2/2-0.006,-0.008,fw),(fw2,0.02,H-2*fw),'oak')
    b.box(((W/2)-fw-fw2/2+0.006,-0.008,fw),(fw2,0.02,H-2*fw),'oak')
    # back board
    b.box((0,D/2-0.006,fw),(W-2*fw,0.010,H-2*fw),'paint_cream')
    # art on the front of the opening
    if not hi:
        b.box((0,-0.010,fw+0.02),(W-2*fw-0.04,0.006,H-2*fw-0.04),'goods')
    else:
        y=-0.010-0.006
        b.box((0,y,0.18),(W-0.22,0.004,H-0.32),'paint_navy')
        b.box((-0.08,y,0.34),(0.22,0.004,0.28),'leaf')
        b.box((0.10,y,0.26),(0.16,0.004,0.16),'brass')
        b.box((0,y,0.68),(W-0.28,0.004,0.06),'paint_cream')
    # hanging hardware + wall flanges
    b.box((0,D/2+0.004,H-0.10),(0.16,0.010,0.04),'steel')
    for x in (-W/2+0.10,W/2-0.10):
        b.box((x,D/2+0.006,H-0.12),(0.04,0.012,0.04),'steel')
        b.box((x,D/2+0.006,0.10),(0.04,0.012,0.04),'steel')
    b.tube((-W/2+0.12,0.0,H-0.10),(0,0.0,H-0.02),0.004,0.004,sg(hi,6,8),'steel',cap0=True,cap1=False,smooth=True)
    b.tube(( W/2-0.12,0.0,H-0.10),(0,0.0,H-0.02),0.004,0.004,sg(hi,6,8),'steel',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.0,0.02),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W,D+0.02,H))


def pharmacy_shelf(b, hi=False):
    W,D,H=1.10,0.38,2.00
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.02,0.0,0.08),(0.04,D,H-0.16),'paint_cream',skip=('bottom',))
        b.box((x+sgn*0.02,D/2+0.006,0.16),(0.07,0.010,0.07),'steel')
        b.box((x+sgn*0.02,D/2+0.006,H-0.18),(0.07,0.010,0.07),'steel')
    b.box((0,D/2-0.012,0.08),(W-0.06,0.016,H-0.16),'paint_cream')
    b.box((0,0.0,0.0),(W,D,0.08),'paint_cream',skip=('bottom',))
    b.box((0,0.0,H-0.08),(W,D,0.08),'paint_cream')
    b.box((0,-0.01,H-0.12),(W-0.04,D-0.04,0.03),'paint_cream')
    # mid upright
    b.box((0,0.0,0.08),(0.024,D-0.04,H-0.20),'paint_cream')
    zs=(0.24,0.58,0.92,1.26,1.60)
    for z in zs:
        b.box((0,-0.01,z),(W-0.06,D-0.04,0.016),'paint_cream')
        b.box((0,-(D/2)+0.016,z-0.014),(W-0.10,0.012,0.018),'plastic')
        if not hi:
            b.box((0,-(D/2)+0.08,z+0.12),(W-0.14,0.008,0.20),'goods')
    if hi:
        y=-(D/2)+0.08-0.006
        bodies=('paint_navy','paint_cream','leaf','plastic','brass','oak','paint_black')
        for row,z in enumerate(zs):
            for col in range(8):
                x=-0.44+col*0.12
                # medicine box
                b.box((x,y,z+0.03),(0.09,0.004,0.16),bodies[(row+col)%len(bodies)])
                b.box((x,y-0.003,z+0.12),(0.07,0.003,0.05),'label')
    # lockable lower cupboard
    b.box((0,0.0,0.08),(W-0.08,D-0.04,0.16),'paint_cream')
    b.box((0,-(D/2)+0.02,0.10),(0.40,0.02,0.12),'paint_cream')
    b.box((0,-(D/2)+0.00,0.16),(0.06,0.02,0.016),'steel')
    maker_plate(b,(0.35,-(D/2)+0.03,0.12),hi,w=0.07,h=0.014)
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))


# ------------------------------------------------------------------ bookcase
def bookcase(b, hi=False):
    W,D,H=1.00,0.34,2.05
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.025,0.0,0.0),(0.05,D,H-0.06),'oak',skip=('bottom',))
    b.box((0,D/2-0.012,0.08),(W-0.08,0.016,H-0.16),'oak')
    b.box((0,0.0,0.0),(W,D,0.10),'oak',skip=('bottom',))
    b.box((0,0.0,H-0.08),(W,D,0.08),'oak')
    # dentil-ish cornice
    b.box((0,-0.01,H-0.12),(W+0.02,D+0.02,0.04),'oak')
    b.box((0,0.0,H-0.16),(W-0.04,D-0.02,0.03),'oak')
    # mid upright
    b.box((0,0.0,0.10),(0.028,D-0.04,H-0.24),'oak')
    # closed cupboard at the base, then four open shelves of books
    b.box((0,-(D/2)+0.02,0.12),(W-0.14,0.03,0.36),'oak')
    for x in (-0.22,0.22):
        b.box((x,-(D/2)+0.01,0.14),(0.38,0.024,0.32),'oak')
        b.box((x,-(D/2)+0.00,0.28),(0.08,0.016,0.016),'brass')
    zs=(0.58,0.94,1.30,1.66)
    for z in zs:
        b.box((0,0.0,z),(W-0.08,D-0.04,0.018),'oak')
        if not hi:
            b.box((0,-(D/2)+0.06,z+0.14),(W-0.14,0.008,0.24),'goods')
    if hi:
        y=-(D/2)+0.06-0.006
        bodies=('oak','walnut','paint_navy','paint_cream','leaf','paint_black','brass','fabric')
        for row,z in enumerate(zs):
            # tightly packed spines of varying widths and heights
            x=-0.42
            k=0
            while x<0.42:
                w=0.04+((row*3+k)*0.017)%0.05
                h=0.18+((row+k)*0.03)%0.10
                b.box((x+w/2,y,z+0.02),(w-0.004,0.004,h),bodies[(row+k)%len(bodies)])
                if k%3==0:
                    b.box((x+w/2,y-0.003,z+0.08),(w-0.01,0.003,0.05),'label')
                x+=w
                k+=1
    maker_plate(b,(0,-(D/2)+0.03,0.14),hi,w=0.07,h=0.014)
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))


_C=dict(dir='props/indoor/gift',pdir='indoor_gift',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('card_spinner',card_spinner,'medium',900,side=96,cage=0.04,ray=0.12),
    _p('gallery_frame',gallery_frame,'small',400,side=96,mount='wall',cage=0.04,ray=0.12),
    _p('pharmacy_shelf',pharmacy_shelf,'medium',1100,side=96,cage=0.04,ray=0.12),
    _p('bookcase',bookcase,'medium',1100,side=128,cage=0.04,ray=0.12),
]
