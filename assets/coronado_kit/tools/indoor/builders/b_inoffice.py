"""Indoor office props — original geometry, page I, near+col only.

filing_cabinet, office_chair, office_desk.
Chairs get collision. Delete stale _bake/tiles/<name>_* after geo changes.
"""
import math
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT, arc_slab,
)

# ------------------------------------------------------------------ filing_cabinet
def filing_cabinet(b, hi=False):
    """4-drawer vertical file in graphite powder coat: proud drawer fronts with dark reveals, recessed
    chrome pulls, brass card holders with white cards, rolled top lip, recessed plinth, embossed side ribs."""
    W,D,H=0.47,0.62,1.32
    b.box((0,0.01,0.0),(W-0.03,D-0.04,0.07),'paint_black',skip=('bottom',))            # recessed plinth
    b.box((0,0.0,0.07),(W,D,H-0.09),'paint_grey',skip=('bottom','top'))                 # carcass
    b.box((0,0.0,H-0.02),(W+0.012,D+0.012,0.02),'paint_grey')                           # rolled top lip
    b.box((0,0.0,H-0.002),(W-0.02,D-0.02,0.004),'paint_black')                          # top insert line
    for sx in (-1,1):                                                                   # embossed side ribs
        for z in (0.40,0.90):
            b.box((sx*(W/2+0.003),0.02,z),(0.006,D-0.16,0.05),'paint_grey')
    h_d=(H-0.11)/4
    for i in range(4):
        z=0.08+i*h_d
        b.box((0,-(D/2)-0.004,z+0.004),(W-0.02,0.008,h_d-0.008),'paint_black')          # reveal shadow
        b.box((0,-(D/2)-0.010,z+0.010),(W-0.03,0.016,h_d-0.020),'paint_grey')           # drawer front
        # recessed pull: dark pocket + chrome lip
        b.box((0,-(D/2)-0.019,z+h_d-0.085),(0.20,0.004,0.035),'paint_black')
        b.tube((-0.10,-(D/2)-0.024,z+h_d-0.068),(0.10,-(D/2)-0.024,z+h_d-0.068),0.007,0.007,sg(hi,6,12),'chrome',cap0=True,cap1=True,smooth=True)
        # brass card holder with a white index card
        b.box((0,-(D/2)-0.020,z+0.08),(0.11,0.004,0.045),'brass')
        b.box((0,-(D/2)-0.023,z+0.085),(0.09,0.002,0.032),'label')
    b.tube((0.17,-(D/2)-0.02,H-0.06),(0.17,-(D/2)-0.032,H-0.06),0.011,0.011,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)   # lock
    b.box((0,D/2+0.008,H-0.10),(0.16,0.016,0.05),'paint_black')                         # anti-tip bracket
    maker_plate(b,(0,D/2-0.02,0.20),hi,w=0.06,h=0.014,rz=180)
    for x in (-W/2+0.07,W/2-0.07):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))


# ------------------------------------------------------------------ office_chair
def office_chair(b, hi=False):
    """mid-back task chair: polished 5-star base with twin-wheel casters, gas lift with a black shroud, contoured
    seat with a waterfall front, curved two-section back on a steel spine, loop arms with pads, tilt knob."""
    H=1.05
    seg=sg(hi,8,16)
    b.tube((0,0,0.085),(0,0,0.135),0.055,0.045,seg,'chrome',cap0=True,cap1=True,smooth=True)
    for i in range(5):
        a=2*math.pi*i/5+math.pi/2; ca,sa=math.cos(a),math.sin(a)
        b.sweep([(0.04*ca,0.04*sa,0.11),(0.20*ca,0.20*sa,0.095),(0.29*ca,0.29*sa,0.075)],0.018,sg(hi,5,10),'chrome',cap0=False,cap1=True)
        x,y=0.29*ca,0.29*sa
        b.box((x,y,0.05),(0.035,0.035,0.03),'plastic_black',rz=a)
        b.tube((x-0.018*sa,y+0.018*ca,0.026),(x+0.018*sa,y-0.018*ca,0.026),0.025,0.025,sg(hi,8,12),'rubber',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.13),(0,0,0.30),0.032,0.032,seg,'plastic_black',cap0=False,cap1=True,smooth=True)   # shroud
    b.tube((0,0,0.30),(0,0,0.42),0.014,0.014,seg,'chrome',cap0=False,cap1=False,smooth=True)
    b.box((0,0.02,0.40),(0.24,0.26,0.05),'plastic_black')                                            # mechanism
    b.tube((0.12,-0.04,0.42),(0.20,-0.04,0.42),0.008,0.008,6,'chrome',cap0=False,cap1=True)        # tilt lever
    b.tube((0.20,-0.04,0.42),(0.21,-0.04,0.42),0.014,0.014,sg(hi,6,10),'plastic_black',cap0=True,cap1=True)
    # contoured seat: shell + cushion with waterfall front
    b.box((0,0.02,0.44),(0.48,0.46,0.025),'plastic_black')
    b.prism([(-0.24,0.465),(0.24,0.465),(0.245,0.52),(0.23,0.545),(-0.23,0.545),(-0.245,0.52)],-0.21,0.25,'vinyl')
    b.prism([(-0.23,0.46),(0.23,0.46),(0.23,0.50),(-0.23,0.50)],-0.235,-0.205,'vinyl')                # waterfall
    # spine and two-section curved back
    b.sweep([(0,0.22,0.43),(0,0.30,0.47),(0,0.31,0.60)],0.018,4,'plastic_black',cap0=True,cap1=True,sq=True)
    # curved one-piece back (radius 0.55 about a point in front of the seat): cushion + black shell + lumbar seam
    arc_slab(b,(0,-0.30),0.62,112,68,0.56,1.02,0.065,'plastic_black',seg=sg(hi,4,10),back_key='vinyl')
    arc_slab(b,(0,-0.30),0.625,110,70,0.735,0.745,0.075,'plastic_black',seg=sg(hi,4,10))
    # loop arms with pads
    for sx in (-1,1):
        b.sweep([(sx*0.20,0.10,0.45),(sx*0.25,0.10,0.50),(sx*0.25,0.08,0.66),(sx*0.25,-0.06,0.67)],0.014,sg(hi,5,8),'plastic_black',cap0=True,cap1=True)
        b.box((sx*0.25,0.02,0.67),(0.06,0.24,0.028),'vinyl')
    maker_plate(b,(0,0.33,0.62),hi,w=0.05,h=0.012,rz=180)
    b.cbox((0,0,0),(0.62,0.62,H))


# ------------------------------------------------------------------ office_desk
def office_desk(b, hi=False):
    """double-pedestal clerk desk: oak top with a dark edge band, cream steel pedestals with proud oak drawer
    fronts, bar pulls, modesty panel; dressed with a monitor, keyboard, mouse, paper tray, pen cup and files."""
    W,D,H=1.50,0.75,0.74
    th=0.032
    b.box((0,0.0,H-th),(W,D,th),'oak')
    b.box((0,-(D/2)-0.002,H-th),(W,0.006,th),'walnut')                                  # front edge band
    pw,pd=0.42,D-0.06
    for sx in (-1,1):
        px=sx*(W/2-pw/2-0.03)
        b.box((px,0.01,0.07),(pw,pd,H-th-0.07),'paint_cream',skip=('bottom','top'))
        b.box((px,0.02,0.0),(pw-0.04,pd-0.06,0.07),'paint_black',skip=('bottom',))       # recessed plinth
        fronts=((0.09,0.17),(0.28,0.17),(0.47,0.17)) if sx>0 else ((0.09,0.30),(0.42,0.22))
        for z,hh in fronts:
            b.box((px,-(D/2)+0.025,z-0.004),(pw-0.02,0.006,hh+0.008),'paint_black')    # reveal
            b.box((px,-(D/2)+0.018,z),(pw-0.03,0.018,hh),'oak')
            b.box((px,-(D/2)+0.004,z+hh-0.045),(0.14,0.012,0.014),'chrome')
            for x in (px-0.06,px+0.06):
                b.box((x,-(D/2)+0.010,z+hh-0.045),(0.012,0.012,0.014),'chrome')
    b.box((0,(D/2)-0.05,0.18),(W-2*pw-0.06,0.020,H-th-0.22),'oak')                       # modesty panel
    b.box((0,(D/2)-0.05,0.18),(W-2*pw-0.06,0.024,0.012),'walnut')
    # grommet
    b.tube((0.50,0.24,H),(0.50,0.24,H+0.004),0.03,0.03,sg(hi,8,12),'plastic_black',cap0=False,cap1=True,smooth=True)
    # --- dressing ---
    T=H
    # monitor: base, neck, bezel, screen (unique bake), back shell
    mx,my=0.18,0.16
    b.box((mx,my,T),(0.22,0.16,0.012),'plastic_black')
    b.box((mx,my+0.03,T+0.012),(0.04,0.03,0.17),'plastic_black')
    b.box((mx,my,T+0.10),(0.56,0.035,0.33),'plastic_black')
    b.box((mx,my-0.019,T+0.115),(0.53,0.004,0.30),'screen')
    if hi:
        b.box((mx-0.10,my-0.022,T+0.30),(0.30,0.003,0.03),'paint_navy')
        for k in range(5): b.box((mx-0.12+k*0.06,my-0.022,T+0.16),(0.045,0.003,0.10),'plastic')
    # keyboard + mouse
    b.box((mx,-0.12,T),(0.44,0.15,0.018),'plastic_black')
    b.box((mx,-0.12,T+0.018),(0.41,0.13,0.004),'keypad')
    b.box((mx+0.30,-0.12,T),(0.06,0.10,0.025),'plastic_black')
    # paper tray (two tiers) with paper, pen cup, file stack
    tx,ty=-0.52,0.10
    for z in (0.0,0.07):
        b.box((tx,ty,T+z),(0.26,0.34,0.008),'plastic_black')
        b.box((tx,ty,T+z+0.008),(0.22,0.30,0.02),'label')
        for sx in (-1,1): b.box((tx+sx*0.125,ty,T+z),(0.01,0.34,0.06),'plastic_black')
    b.tube((-0.30,0.24,T),(-0.30,0.24,T+0.10),0.035,0.035,sg(hi,8,14),'paint_navy',cap0=False,cap1=False,smooth=True)
    for k,(dx,dy) in enumerate(((0.01,0.0),(-0.012,0.008),(0.0,-0.012))):
        b.tube((-0.30+dx,0.24+dy,T+0.06),(-0.30+dx*2.5,0.24+dy*2.5,T+0.15),0.004,0.004,6,('paint_red','paint_black','paint_navy')[k],cap0=False,cap1=True,smooth=True)
    for k in range(3):
        b.box((-0.18+0.004*k,-0.14,T+0.012*k),(0.24,0.32,0.012),('paint_navy','card','paint_green')[k],rz=math.radians(4-5*k))
    maker_plate(b,(0,(D/2)-0.035,0.24),hi,w=0.07,h=0.014,rz=180)
    for sx in (-1,1):
        for y in (-D/2+0.10,D/2-0.10):
            leveler(b,(sx*(W/2-0.10),y),hi)
    b.cbox((0,0,0),(W,D,H))


_C=dict(dir='props/indoor/office',pdir='indoor_office',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('filing_cabinet',filing_cabinet,'medium',1000,side=64),
    _p('office_chair',office_chair,'medium',1000,shift=(0,-0.035)),
    _p('office_desk',office_desk,'medium',1200,side=96),
]

INDOOR_LOOK=True   # run.py: chamfer edge highlight + per-part colour variation in COLOR_0
