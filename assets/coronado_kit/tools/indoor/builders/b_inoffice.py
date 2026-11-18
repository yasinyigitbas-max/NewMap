"""Indoor office props — original geometry, page I, near+col only.

filing_cabinet, office_chair, office_desk.
Chairs get collision. Delete stale _bake/tiles/<name>_* after geo changes.
"""
import math
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT,
)

# ------------------------------------------------------------------ filing_cabinet
def filing_cabinet(b, hi=False):
    W,D,H=0.50,0.62,1.32
    b.box((0,0.0,0.0),(W,D,0.06),'paint_black',skip=('bottom',))  # kick / plinth
    b.box((0,0.0,0.06),(W,D,H-0.06),'steel',skip=('bottom',))
    # four drawers, each with a recessed handle and a label plate
    h_d=(H-0.08)/4
    for i in range(4):
        z=0.08+i*h_d
        b.box((0,-(D/2)+0.02,z+0.012),(W-0.04,0.03,h_d-0.024),'paint_cream')
        # recessed handle bar
        b.box((0,-(D/2)+0.00,z+h_d-0.06),(W-0.12,0.02,0.018),'steel')
        b.box((0,-(D/2)-0.01,z+h_d-0.06),(0.22,0.016,0.012),'steel')
        # label holder
        b.box((0.12,-(D/2)-0.005,z+0.08),(0.12,0.010,0.04),'steel')
        if hi:
            b.box((0.12,-(D/2)-0.010,z+0.08),(0.10,0.004,0.03),'label')
        # side gaps / rails hint
        b.box((0,-(D/2)+0.025,z),(W-0.02,0.008,0.008),'paint_black')
    # lock on the top drawer
    b.tube((0.18,-(D/2)-0.01,H-0.14),(0.18,-(D/2)-0.025,H-0.14),0.012,0.012,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
    # anti-tip / counterweight flange on the back
    b.box((0,D/2+0.01,H-0.08),(0.16,0.02,0.04),'steel')
    maker_plate(b,(0,D/2-0.02,0.20),hi,w=0.06,h=0.014,rz=180)
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))


# ------------------------------------------------------------------ office_chair
def office_chair(b, hi=False):
    H=1.05
    seg=sg(hi,10,16)
    # 5-star base with casters
    b.tube((0,0,0.10),(0,0,0.14),0.06,0.06,seg,'steel',cap0=True,cap1=True,smooth=True)
    for i in range(5):
        a=2*math.pi*i/5
        x,y=0.28*math.cos(a),0.28*math.sin(a)
        b.box((x*0.5,y*0.5,0.12),(0.28,0.04,0.025), 'steel', rz=math.degrees(a))
        # caster
        b.box((x,y,0.06),(0.04,0.03,0.06),'steel',rz=math.degrees(a))
        b.tube((x-0.02*math.sin(a),y+0.02*math.cos(a),0.03),
               (x+0.02*math.sin(a),y-0.02*math.cos(a),0.03),
               0.022,0.022,sg(hi,8,12),'rubber',cap0=True,cap1=True,smooth=True)
    # gas lift
    b.tube((0,0,0.14),(0,0,0.42),0.025,0.022,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,0.36),(0,0,0.46),0.04,0.04,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
    # seat
    b.box((0,0.02,0.46),(0.44,0.42,0.05),'steel')
    b.box((0,0.02,0.50),(0.40,0.38,0.06),'fabric')
    b.box((0,0.02,0.49),(0.42,0.40,0.02),'paint_black')  # welt
    # back: split pads + a narrower shoulder, rear shell
    b.box((0,0.24,0.62),(0.38,0.06,0.40),'steel')
    b.box((0,0.16,0.62),(0.32,0.08,0.14),'fabric')          # lumbar
    b.box((0,0.18,0.80),(0.30,0.07,0.18),'fabric')          # shoulder
    b.box((0,0.20,0.98),(0.22,0.06,0.08),'fabric')          # headrest
    # back post
    b.tube((0,0.18,0.50),(0,0.22,0.70),0.016,0.016,sg(hi,8,12),'steel',cap0=True,cap1=True,smooth=True)
    # tilt lever
    b.tube((-0.08,-0.16,0.48),(-0.20,-0.22,0.46),0.008,0.008,sg(hi,6,10),'steel',cap0=True,cap1=True,smooth=True)
    # arms
    for sgn in (-1,1):
        b.tube((sgn*0.22,-0.04,0.50),(sgn*0.22,-0.04,0.70),0.014,0.014,sg(hi,8,12),'steel',cap0=True,cap1=True,smooth=True)
        b.tube((sgn*0.22,-0.04,0.70),(sgn*0.22,0.12,0.70),0.014,0.014,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
        b.box((sgn*0.22,0.04,0.72),(0.05,0.20,0.03),'paint_black')
    maker_plate(b,(0,0.22,0.48),hi,w=0.05,h=0.012,rz=180)
    b.cbox((0,0,0),(0.64,0.70,H))


# ------------------------------------------------------------------ office_desk
def office_desk(b, hi=False):
    W,D,H=1.50,0.75,0.74
    th=0.036
    b.box((0,0.0,H-th),(W,D,th),'oak')
    b.box((0,-(D/2)+0.012,H-th-0.006),(W-0.04,0.022,0.014),'oak')
    # grommet
    b.tube((0.50,0.20,H-th),(0.50,0.20,H+0.004),0.025,0.025,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
    b.tube((0.50,0.20,H-th-0.004),(0.50,0.20,H-th+0.002),0.020,0.020,sg(hi,8,12),'paint_black',cap0=True,cap1=False,smooth=True)
    # pedestal on the right (three drawers)
    pw,pd=0.40,D-0.08
    b.box((W/2-pw/2-0.04,0.02,0.08),(pw,pd,H-th-0.10),'paint_cream',skip=('bottom',))
    b.box((W/2-pw/2-0.04,0.02,0.0),(pw,pd-0.06,0.08),'paint_black',skip=('bottom',))
    for i,z in enumerate((0.16,0.34,0.52)):
        b.box((W/2-pw/2-0.04,-(D/2)+0.06,z),(pw-0.06,0.03,0.14),'oak')
        b.box((W/2-pw/2-0.04,-(D/2)+0.04,z+0.04),(0.10,0.02,0.016),'brass')
    # left pedestal (two drawers + a file)
    b.box((-W/2+pw/2+0.04,0.02,0.08),(pw,pd,H-th-0.10),'paint_cream',skip=('bottom',))
    b.box((-W/2+pw/2+0.04,0.02,0.0),(pw,pd-0.06,0.08),'paint_black',skip=('bottom',))
    b.box((-W/2+pw/2+0.04,-(D/2)+0.06,0.20),(pw-0.06,0.03,0.16),'oak')
    b.box((-W/2+pw/2+0.04,-(D/2)+0.04,0.24),(0.10,0.02,0.016),'brass')
    b.box((-W/2+pw/2+0.04,-(D/2)+0.06,0.46),(pw-0.06,0.03,0.20),'oak')
    b.box((-W/2+pw/2+0.04,-(D/2)+0.04,0.50),(0.10,0.02,0.016),'brass')
    # modesty panel
    b.box((0,(D/2)-0.03,0.12),(W-0.90,0.024,H-th-0.20),'oak')
    # cable tray under the top
    b.box((0,0.10,H-th-0.08),(0.50,0.16,0.04),'steel')
    # mid stretcher
    b.box((0,0.0,0.16),(W-0.90,0.04,0.03),'oak')
    maker_plate(b,(0,-(D/2)+0.03,0.20),hi,w=0.07,h=0.014)
    for x in (-W/2+0.10,W/2-0.10):
        for y in (-D/2+0.10,D/2-0.10):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))


_C=dict(dir='props/indoor/office',pdir='indoor_office',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('filing_cabinet',filing_cabinet,'medium',800,side=64),
    _p('office_chair',office_chair,'medium',800),
    _p('office_desk',office_desk,'medium',1000),
]
