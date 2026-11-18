"""Indoor sport props — original geometry, page I, near+col only.

bike_stand, surfboard_rack, weight_bench.
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT,
)

# ------------------------------------------------------------------ bike_stand
def bike_stand(b, hi=False):
    W,D,H=1.40,0.80,0.95
    oy=-0.10
    def P(x,y,z): return (x,y+oy,z)
    # floor frame, grounded
    b.box(P(0,0.10,0.0),(W,0.50,0.05),'steel',skip=('bottom',))
        # two forward-facing U hoops (open toward -Y so they read from the front)
    for x in (-0.38,0.38):
        half=0.14
        b.tube(P(x-half,0.10,0.05),P(x-half,0.10,H-0.12),0.018,0.018,sg(hi,8,12),'steel',cap0=False,cap1=False,smooth=True)
        b.tube(P(x+half,0.10,0.05),P(x+half,0.10,H-0.12),0.018,0.018,sg(hi,8,12),'steel',cap0=False,cap1=False,smooth=True)
        b.tube(P(x-half,0.10,H-0.12),P(x,0.10,H),0.018,0.018,sg(hi,8,12),'steel',cap0=False,cap1=False,smooth=True)
        b.tube(P(x,0.10,H),P(x+half,0.10,H-0.12),0.018,0.018,sg(hi,8,12),'steel',cap0=False,cap1=False,smooth=True)
        b.tube(P(x-half,0.10,0.42),P(x+half,0.10,0.42),0.012,0.012,sg(hi,6,10),'steel',cap0=False,cap1=False,smooth=True)
        b.box(P(x,0.10,0.05),(0.08,0.70,0.06),'steel')
        b.tube(P(x,0.40,0.05),P(x,0.40,0.50),0.016,0.016,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
        b.tube(P(x,0.10,0.42),P(x,0.40,0.50),0.012,0.012,sg(hi,6,10),'steel',cap0=False,cap1=False,smooth=True)
        b.box(P(x-half,0.10,0.0),(0.10,0.10,0.03),'steel',skip=('bottom',))
        b.box(P(x+half,0.10,0.0),(0.10,0.10,0.03),'steel',skip=('bottom',))
        b.box(P(x,0.40,0.0),(0.10,0.10,0.03),'steel',skip=('bottom',))
    maker_plate(b,P(0,0.20,0.06),hi,w=0.07,h=0.016)
    b.cbox((0,0,0),(W,D,H))


def surfboard_rack(b, hi=False):
    W,D,H=0.70,0.90,1.55
    # A-frame, grounded feet
    for sgn in (-1,1):
        b.tube((sgn*0.26,-(D/2)+0.08,0.04),(sgn*0.08,0.0,H-0.04),0.018,0.018,sg(hi,8,12),'steel',cap0=True,cap1=False,smooth=True)
        b.tube((sgn*0.26,(D/2)-0.08,0.04),(sgn*0.08,0.0,H-0.04),0.018,0.018,sg(hi,8,12),'steel',cap0=True,cap1=False,smooth=True)
        b.box((sgn*0.26,-(D/2)+0.08,0.0),(0.10,0.10,0.04),'steel',skip=('bottom',))
        b.box((sgn*0.26,(D/2)-0.08,0.0),(0.10,0.10,0.04),'steel',skip=('bottom',))
    b.tube((-0.08,0.0,H-0.04),(0.08,0.0,H-0.04),0.016,0.016,sg(hi,8,12),'steel',cap0=True,cap1=True,smooth=True)
    # two padded rails, front-to-back
    for z in (0.50,1.00):
        b.tube((-0.16,-0.30,z),(0.16,-0.30,z),0.014,0.014,sg(hi,8,12),'steel',cap0=True,cap1=True,smooth=True)
        b.tube((-0.16, 0.30,z),(0.16, 0.30,z),0.014,0.014,sg(hi,8,12),'steel',cap0=True,cap1=True,smooth=True)
        b.box((0,-0.30,z+0.016),(0.30,0.04,0.028),'rubber')
        b.box((0, 0.30,z+0.016),(0.30,0.04,0.028),'rubber')
    # two boards: stepped taper so the silhouette reads as a board, not a box
    def _board(x,z0,color,accent,length=0.76):
        # segs: (y_centre, y_len, x_thick, z_height, z_lift)
        segs=((0.30,0.14,0.040,0.09,0.04),
              (0.14,0.18,0.050,0.14,0.01),
              (0.00,0.16,0.052,0.16,0.00),
              (-0.16,0.16,0.048,0.13,0.01),
              (-0.30,0.12,0.040,0.08,0.03))
        for yc,yl,xt,zh,zl in segs:
            b.box((x,yc,z0+zl),(xt,yl,zh),color)
        # stringer
        b.box((x,0.0,z0+0.07),(0.008,length-0.08,0.02),accent)
        # tail fin under the rail
        b.box((x,-0.30,z0-0.04),(0.012,0.08,0.08),accent)
    _board(-0.04,0.56,'paint_navy','paint_cream')
    _board(0.06,1.06,'paint_cream','paint_navy',length=0.70)
    maker_plate(b,(0,0.0,0.06),hi,w=0.06,h=0.014)
    b.cbox((0,0,0),(W,D,H))


def weight_bench(b, hi=False):
    W,D,H=1.40,0.60,1.15
    # pad
    b.box((-0.15,0.0,0.42),(0.90,0.32,0.08),'paint_black')
    b.box((-0.15,0.0,0.48),(0.86,0.28,0.06),'fabric')
    # steel frame
    b.box((-0.15,0.0,0.30),(0.90,0.06,0.06),'steel')
    for x in (-0.50,0.20):
        for y in (-0.16,0.16):
            b.box((x,y,0.04),(0.06,0.06,0.28),'steel')
            b.box((x,y,0.04),(0.10,0.10,0.04),'steel')
    # foot stretchers
    b.box((-0.15,0.0,0.06),(0.80,0.06,0.04),'steel')
    b.box((-0.15,0.0,0.06),(0.06,0.36,0.04),'steel')
    # uprights / barbell rests at the head
    for y in (-0.22,0.22):
        b.box((0.50,y,0.04),(0.06,0.06,H-0.04),'steel')
        b.box((0.50,y,0.04),(0.12,0.12,0.04),'steel')
        # J-cup
        b.box((0.42,y,1.00),(0.10,0.05,0.04),'steel')
        b.box((0.38,y,1.00),(0.04,0.05,0.08),'steel')
    # crossmember between uprights
    b.box((0.50,0.0,0.90),(0.05,0.50,0.05),'steel')
    # barbell + plates
    b.tube((0.40,-0.42,1.06),(0.40,0.42,1.06),0.016,0.016,sg(hi,8,12),'chrome',cap0=True,cap1=True,smooth=True)
    for y in (-0.36,-0.28,0.28,0.36):
        b.tube((0.40,y-0.03,1.06),(0.40,y+0.03,1.06),0.10,0.10,sg(hi,10,14),'paint_black',cap0=True,cap1=True,smooth=True)
    # mid brace
    b.box((0.10,0.0,0.20),(0.04,0.36,0.04),'steel')
    maker_plate(b,(-0.40,0.0,0.32),hi,w=0.06,h=0.014,rz=180)
    b.cbox((0,0,0),(W,D,H))


_C=dict(dir='props/indoor/sport',pdir='indoor_sport',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('bike_stand',bike_stand,'medium',800),
    _p('surfboard_rack',surfboard_rack,'medium',800),
    _p('weight_bench',weight_bench,'medium',900),
]
