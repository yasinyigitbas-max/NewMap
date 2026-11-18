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
    # a display bike in the left hoop (front wheel in the hoop): ring wheels with hubs and spokes, diamond
    # frame, saddle, flat bars; reads instantly as a bike shop fixture
    from mathutils import Vector as _V
    bx=-0.38; R=0.33; wz=R+0.0
    def wheel(yc):
        n=sg(hi,14,28)
        pts=[P(bx,yc+R*math.cos(2*math.pi*k/n),wz+R*math.sin(2*math.pi*k/n)) for k in range(n+1)]
        b.sweep(pts,0.016,4,'rubber',cap0=False,cap1=False)
        b.tube(P(bx-0.03,yc,wz),P(bx+0.03,yc,wz),0.025,0.025,sg(hi,6,10),'steel',cap0=True,cap1=True)
        for k in range(sg(hi,4,12)):
            a=math.pi*k/sg(hi,4,12)
            b.tube(P(bx,yc-R*0.95*math.cos(a),wz-R*0.95*math.sin(a)),P(bx,yc+R*0.95*math.cos(a),wz+R*0.95*math.sin(a)),0.002,0.002,3,'chrome',cap0=False,cap1=False)
    yf,yr=0.10,0.10+1.02
    yr=yf+0.98
    wheel(yf); wheel(yr)
    bb=(bx,yf+0.56,wz-0.02); st=(bx,yf+0.62,wz+0.48); ht=(bx,yf+0.17,wz+0.44); hl=(bx,yf+0.20,wz+0.30)
    fr='paint_red'
    for a_,b_ in ((bb,st),(st,ht),(bb,hl),(hl,ht),(bb,(bx,yr,wz)),(st,(bx,yr,wz)),(ht,(bx,yf,wz))):
        b.tube(P(*a_),P(*b_),0.018,0.018,sg(hi,5,10),fr,cap0=False,cap1=False)
    b.box(P(bx,st[1]+0.02,st[2]+0.06),(0.07,0.24,0.04),'vinyl')                  # saddle
    b.tube(P(bx,st[1],st[2]),P(bx,st[1]+0.02,st[2]+0.06),0.012,0.012,5,'chrome',cap0=False,cap1=False)
    b.tube(P(bx,ht[1],ht[2]),P(bx,ht[1]-0.02,ht[2]+0.10),0.014,0.014,5,'chrome',cap0=False,cap1=False)
    b.tube(P(bx-0.28,ht[1]-0.02,ht[2]+0.10),P(bx+0.28,ht[1]-0.02,ht[2]+0.10),0.011,0.011,5,'paint_black',cap0=True,cap1=True)
    b.tube(P(bx,bb[1],bb[2]),P(bx+0.05,bb[1],bb[2]),0.05,0.05,sg(hi,8,14),'steel',cap0=False,cap1=True)   # chainring
    maker_plate(b,P(0,0.20,0.06),hi,w=0.07,h=0.016)
    b.cbox((0,0.488,0),(W,1.68,H))   # stand + display bike, centred on the shifted footprint


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
    # two boards: true planform (pointed nose, squash tail), thin rails rising to a domed deck, stringer, fins
    from mathutils import Vector as _V
    def _board(x,z0,deck,rail,L=0.84,Wb=0.26,n=sg(hi,7,14)):
        half=[]
        for k in range(n+1):
            t=k/n; y=-L/2+t*L
            w=Wb/2*(math.sin(math.pi*min(1,t*1.08))**0.55)*(0.85 if t<0.15 else 1.0)
            if t<0.02: w=Wb*0.18     # squash tail
            half.append((w,y))
        out=[(w,y) for w,y in half]+[(-w,y) for w,y in half[::-1] if w>1e-4]
        def ring(sc,z): return [_V((x+px*sc,py,z)) for px,py in out]
        R0=ring(1.0,z0); R1=ring(1.0,z0+0.018); R2=ring(0.78,z0+0.055)
        m=len(out)
        b.quad(R0[::-1],rail)
        for a in range(m):
            c_=(a+1)%m
            b.quad([R0[a],R0[c_],R1[c_],R1[a]],rail); b.quad([R1[a],R1[c_],R2[c_],R2[a]],deck)
        b.quad(R2,deck)
        b.box((x,0.0,z0+0.055),(0.006,L*0.92,0.003),rail)                       # stringer
        for fx,fy,fh in ((0,-L/2+0.06,0.09),(-0.07,-L/2+0.10,0.07),(0.07,-L/2+0.10,0.07)):
            b.prism([(x+fx-0.003,z0),(x+fx+0.003,z0),(x+fx+0.003,z0-fh*0.7),(x+fx-0.003,z0-fh)],fy-0.04,fy+0.04,rail) if False else \
            b.box((x+fx,fy,z0-fh),(0.006,0.07,fh),rail,skip=('top',))
    _board(0.0,0.546,'paint_white','paint_navy')
    _board(0.0,1.046,'paint_yellow','paint_white',L=0.78,Wb=0.24)
    maker_plate(b,(0,0.0,0.06),hi,w=0.06,h=0.014)
    b.cbox((0,0,0),(W,D,H))


def weight_bench(b, hi=False):
    W,D,H=1.40,0.60,1.15
    # pad
    b.box((-0.15,0.0,0.42),(0.90,0.32,0.08),'paint_black')
    b.box((-0.15,0.0,0.48),(0.86,0.28,0.06),'vinyl',ch=0.02)
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
        r_=0.11 if abs(y)<0.3 else 0.085
        b.tube((0.40,y-0.025,1.06),(0.40,y+0.025,1.06),r_,r_,sg(hi,12,20),'rubber',cap0=True,cap1=True,smooth=True)
        b.tube((0.40,y-0.03,1.06),(0.40,y+0.03,1.06),0.03,0.03,sg(hi,8,12),'chrome',cap0=True,cap1=True,smooth=True)
    for y in (-0.40,0.40):
        b.tube((0.40,y-0.012,1.06),(0.40,y+0.012,1.06),0.028,0.028,sg(hi,8,12),'paint_red',cap0=True,cap1=True)
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
    _p('bike_stand',bike_stand,'medium',1100,shift=(0,-0.488)),
    _p('surfboard_rack',surfboard_rack,'medium',800),
    _p('weight_bench',weight_bench,'medium',900),
]

INDOOR_LOOK=True   # run.py: chamfer edge highlight + per-part colour variation in COLOR_0
