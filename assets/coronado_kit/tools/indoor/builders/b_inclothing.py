"""Indoor clothing props — original geometry, page I, near+col only.

clothes_rack, fitting_room (full cubicle), mannequin, shoe_bench, shoe_wall.
Unique merch in the bake; no unique card on the high mesh; silhouettes
inside the cage. Delete stale _bake/tiles/<name>_* after any geo change.
"""
import math
from mathutils import Vector
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT,
)

def garment_card(b, c, h=0.70, w=0.26, body='paint_navy'):
    """Flat hanging garment silhouette for the unique bake (in-cage)."""
    x,y,z=c
    # shoulders / yoke
    b.box((x,y,z+h*0.78),(w,0.004,h*0.14),body)
    # body
    b.box((x,y,z), (w*0.82,0.004,h*0.82),body)
    # short sleeves
    b.box((x-w*0.48,y,z+h*0.68),(w*0.22,0.004,h*0.20),body)
    b.box((x+w*0.48,y,z+h*0.68),(w*0.22,0.004,h*0.20),body)
    b.box((x,y-0.003,z+h*0.40),(w*0.50,0.003,h*0.18),'label')

def hanger(b, c, hi=False, w=0.22):
    x,y,z=c
    # hook
    b.tube((x,y,z+0.04),(x,y,z+0.09),0.005,0.005,sg(hi,6,10),'steel',cap0=False,cap1=True,smooth=True)
    b.tube((x,y,z+0.09),(x,y-0.02,z+0.11),0.005,0.005,sg(hi,6,10),'steel',cap0=False,cap1=True,smooth=True)
    # shoulders
    b.box((x,y,z+0.03),(w,0.010,0.012),'plastic')
    b.box((x,y,z+0.00),(0.012,0.010,0.04),'plastic')  # spine

# ------------------------------------------------------------------ clothes_rack
def clothes_rack(b, hi=False):
    W,D,H=1.40,0.55,1.70
    # end frames: squared bow with a top beam and a lower stretcher
    for x,sgn in ((-W/2,1),(W/2,-1)):
        # uprights
        b.tube((x,-(D/2)+0.06,0.10),(x,-(D/2)+0.06,H-0.06),0.014,0.014,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
        b.tube((x,(D/2)-0.06,0.10),(x,(D/2)-0.06,H-0.06),0.014,0.014,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
        # top arch (two legs + cap)
        b.tube((x,-(D/2)+0.06,H-0.06),(x,0.0,H-0.01),0.014,0.014,sg(hi,8,12),'chrome',cap0=False,cap1=False,smooth=True)
        b.tube((x,0.0,H-0.01),(x,(D/2)-0.06,H-0.06),0.014,0.014,sg(hi,8,12),'chrome',cap0=False,cap1=False,smooth=True)
        # lower side stretcher
        b.tube((x,-(D/2)+0.06,0.28),(x,(D/2)-0.06,0.28),0.010,0.010,sg(hi,6,10),'chrome',cap0=False,cap1=False,smooth=True)
        # caster forks + wheels
        for y in (-(D/2)+0.06,(D/2)-0.06):
            b.box((x,y,0.05),(0.03,0.02,0.06),'steel')
            b.tube((x-0.02,y,0.03),(x+0.02,y,0.03),0.025,0.025,sg(hi,8,12),'rubber',cap0=True,cap1=True,smooth=True)
            b.tube((x-0.016,y,0.03),(x+0.016,y,0.03),0.010,0.010,sg(hi,6,10),'steel',cap0=True,cap1=True,smooth=True)
    # hanging rail
    b.tube((-W/2,0.0,H-0.10),(W/2,0.0,H-0.10),0.016,0.016,sg(hi,10,14),'chrome',cap0=True,cap1=True,smooth=True)
    # mid brace under the rail
    b.tube((0,-(D/2)+0.06,H-0.14),(0,(D/2)-0.06,H-0.14),0.010,0.010,sg(hi,6,10),'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0,0.0,H-0.14),(0,0.0,H-0.10),0.010,0.010,sg(hi,6,10),'chrome',cap0=False,cap1=False,smooth=True)
    # lower shelf / shoe bar
    b.box((0,0.0,0.26),(W-0.10,D-0.16,0.016),'steel')
    b.tube((-W/2+0.04,0.0,0.26),(W/2-0.04,0.0,0.26),0.008,0.008,sg(hi,6,10),'chrome',cap0=True,cap1=True,smooth=True)
    # hangers + garments
    n=5
    bodies=('paint_navy','fabric','paint_cream','paint_black','oak')
    for i in range(n):
        x=-0.52+i*0.26
        hanger(b,(x,0.0,H-0.22),hi,w=0.20)
        if not hi:
            b.box((x,0.02,0.70),(0.22,0.008,0.70),'goods')
        if hi:
            garment_card(b,(x,0.02-0.006,0.68),h=0.72,w=0.22,body=bodies[i%len(bodies)])
    maker_plate(b,(0,D/2-0.08,0.30),hi,w=0.07,h=0.016,rz=180)
    b.cbox((0,0,0),(W+0.08,D+0.08,H+0.04))


# ------------------------------------------------------------------ fitting_room  (FULL CUBICLE)
def fitting_room(b, hi=False):
    W,D,H=1.10,1.16,2.12
    tw=0.04
    # ajar door swings toward -Y; shift the stall +Y so the footprint stays centred
    oy=0.09
    def y(v): return v+oy
    # floor plate / threshold
    b.box((0,y(0.0),0.0),(W,D,0.04),'lam',skip=('bottom',))
    b.box((0,y(-(D/2)+0.03),0.04),(W-0.08,0.06,0.02),'steel')
    # three walls + front jambs (complete enclosure, full height)
    b.box((0,y(D/2-tw/2),0.04),(W,tw,H-0.12),'paint_cream')
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*tw/2,y(0.0),0.04),(tw,D,H-0.12),'paint_cream')
        # exterior panel reveals
        b.box((x+sgn*(tw+0.006),y(0.0),0.20),(0.012,D-0.16,0.70),'paint_cream')
        b.box((x+sgn*(tw+0.006),y(0.0),1.05),(0.012,D-0.16,0.70),'paint_cream')
    opening=0.64
    jamb=(W-opening)/2
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*jamb/2,y(-(D/2)+tw/2),0.04),(jamb,tw,H-0.12),'paint_cream')
    # transom above the door — no half opening
    b.box((0,y(-(D/2)+tw/2),H-0.28),(opening,tw,0.16),'paint_cream')
    # cornice / roof cap
    b.box((0,y(0.0),H-0.08),(W+0.04,D+0.04,0.08),'oak')
    b.box((0,y(0.0),H-0.12),(W-0.04,D-0.04,0.03),'oak')
    # corner posts
    for x in (-W/2+0.03,W/2-0.03):
        for yy in (-D/2+0.03,D/2-0.03):
            b.box((x,y(yy),0.04),(0.06,0.06,H-0.14),'oak')
    # door: box z is the BOTTOM. Slightly ajar so the bench reads.
    door_w=opening-0.04
    door_h=H-0.36
    ang=math.radians(-22)
    hinge_x=-opening/2+0.02
    hinge_y=y(-(D/2)+tw/2+0.01)
    cx=hinge_x + (door_w/2)*math.cos(ang)
    cy=hinge_y + (door_w/2)*math.sin(ang)
    b.box((cx,cy,0.08),(door_w,0.028,door_h),'paint_navy',rz=-22)
    # door stiles / rails / kick
    b.box((cx,cy,0.08),(door_w-0.02,0.032,0.10),'paint_navy',rz=-22)
    b.box((cx,cy,0.08+door_h-0.08),(door_w-0.02,0.032,0.08),'paint_navy',rz=-22)
    b.box((cx+0.02*math.cos(ang),cy+0.02*math.sin(ang),1.00),(0.22,0.016,0.36),'glass',rz=-22)
    hx=hinge_x + (door_w-0.06)*math.cos(ang)
    hy=hinge_y + (door_w-0.06)*math.sin(ang)
    b.tube((hx,hy,1.00),(hx-0.04*math.sin(ang),hy+0.04*math.cos(ang),1.00),0.010,0.010,sg(hi,6,10),'brass',cap0=True,cap1=True,smooth=True)
    b.box((hx,hy,0.96),(0.04,0.02,0.08),'brass',rz=-22)
    for z in (0.30,0.90,1.60):
        b.tube((hinge_x,hinge_y-0.01,z-0.03),(hinge_x,hinge_y-0.01,z+0.03),0.012,0.012,sg(hi,6,10),'steel',cap0=True,cap1=True,smooth=True)
    # occupancy latch on the transom
    b.box((0.18,y(-(D/2)-0.01),H-0.26),(0.08,0.03,0.05),'steel')
    b.tube((0.18,y(-(D/2)-0.03),H-0.24),(0.18,y(-(D/2)-0.04),H-0.24),0.016,0.016,sg(hi,8,12),'ceramic',cap0=False,cap1=True,smooth=True)
    # stall number plaque
    b.box((-0.20,y(-(D/2)-0.01),H-0.26),(0.10,0.02,0.06),'badge')
    # interior bench, hooks, shelf, opaque mirror
    b.box((0,y(D/2-0.20),0.42),(0.70,0.28,0.06),'oak')
    b.box((0,y(D/2-0.20),0.48),(0.66,0.24,0.04),'fabric')
    for x in (-0.28,0.28):
        b.box((x,y(D/2-0.10),0.04),(0.04,0.04,0.38),'oak')
        b.box((x,y(D/2-0.30),0.04),(0.04,0.04,0.38),'oak')
    for yy in (0.10,-0.20):
        b.tube((W/2-0.05,y(yy),1.50),(W/2-0.12,y(yy),1.50),0.008,0.008,sg(hi,6,10),'brass',cap0=True,cap1=False,smooth=True)
        b.tube((W/2-0.12,y(yy),1.50),(W/2-0.12,y(yy),1.42),0.007,0.007,sg(hi,6,10),'brass',cap0=False,cap1=True,smooth=True)
    b.box((0,y(D/2-0.16),1.70),(0.70,0.20,0.024),'oak')
    b.box((0,y(D/2-0.05),0.85),(0.50,0.016,0.70),'steel')
    b.box((0,y(D/2-0.06),0.88),(0.44,0.010,0.64),'glass')
    # soffit light bar
    b.box((0,y(0.0),H-0.16),(0.50,0.08,0.03),'steel')
    b.box((0,y(0.0),H-0.17),(0.44,0.06,0.016),'paint_cream')
    # interior skirting
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.06,y(0.0),0.04),(0.02,D-0.08,0.08),'oak')
    b.box((0,y(D/2-0.06),0.04),(W-0.12,0.02,0.08),'oak')
    # exterior paneling: oak skirting, dados and battens so the sides/back are not blank slabs
    b.box((0,y(D/2+0.010),0.04),(W-0.08,0.016,0.10),'oak')
    for z in (0.70,1.30,1.82):
        b.box((0,y(D/2+0.010),z),(W-0.12,0.016,0.04),'oak')
    for x in (-0.30,0.0,0.30):
        b.box((x,y(D/2+0.010),0.04),(0.03,0.016,H-0.20),'oak')
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*(tw+0.010),y(0.0),0.04),(0.016,D-0.12,0.10),'oak')
        for z in (0.70,1.30,1.82):
            b.box((x+sgn*(tw+0.010),y(0.0),z),(0.016,D-0.16,0.04),'oak')
        for yy in (-0.28,0.0,0.28):
            b.box((x+sgn*(tw+0.010),y(yy),0.04),(0.016,0.03,H-0.20),'oak')
    # front jamb trim
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.08,y(-(D/2)-0.008),0.04),(0.04,0.016,H-0.16),'oak')
    maker_plate(b,(W/2-0.08,y(0.0),0.20),hi,w=0.07,h=0.016,rz=90)
    b.cbox((0,0,0),(W,D+0.22,H))


def mannequin(b, hi=False):
    H=1.70
    seg=sg(hi,10,16)
    # base + column
    b.tube((0,0,0.0),(0,0,0.04),0.22,0.22,sg(hi,12,18),'steel',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.04),(0,0,0.08),0.18,0.16,sg(hi,12,18),'steel',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,0.08),(0,0,0.78),0.016,0.016,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
    # hip block sitting on the pole
    b.tube((0,0,0.78),(0,0,0.86),0.05,0.05,seg,'plastic',cap0=False,cap1=True,smooth=True)
    # pelvis
    b.tube((0,0,0.86),(0,0,1.02),0.13,0.11,seg,'paint_cream',cap0=True,cap1=False,smooth=True)
    # waist / torso
    b.tube((0,0,1.02),(0,0,1.22),0.11,0.13,seg,'paint_cream',cap0=False,cap1=False,smooth=True)
    b.tube((0,0,1.22),(0,0,1.44),0.13,0.16,seg,'paint_cream',cap0=False,cap1=False,smooth=True)
    # chest cap / neck boss
    b.tube((0,0,1.44),(0,0,1.50),0.16,0.08,seg,'paint_cream',cap0=False,cap1=True,smooth=True)
    # neck ring + egg head
    b.tube((0,0,1.50),(0,0,1.57),0.04,0.045,sg(hi,8,12),'paint_cream',cap0=False,cap1=False,smooth=True)
    b.tube((0,0,1.56),(0,0,1.58),0.05,0.05,sg(hi,8,12),'paint_cream',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,1.57),(0,0,1.64),0.07,0.085,seg,'paint_cream',cap0=False,cap1=False,smooth=True)
    b.tube((0,0,1.64),(0,0,1.74),0.085,0.055,seg,'paint_cream',cap0=False,cap1=True,smooth=True)
    # shoulders
    b.tube((-0.16,0,1.42),(0.16,0,1.42),0.05,0.05,sg(hi,8,12),'paint_cream',cap0=True,cap1=True,smooth=True)
    # arms (slightly forward, hanging)
    for sgn in (-1,1):
        b.tube((sgn*0.18,0.02,1.40),(sgn*0.22,0.06,1.10),0.045,0.038,sg(hi,8,12),'paint_cream',cap0=True,cap1=False,smooth=True)
        b.tube((sgn*0.22,0.06,1.10),(sgn*0.20,0.08,0.86),0.036,0.030,sg(hi,8,12),'paint_cream',cap0=False,cap1=True,smooth=True)
        # wrist cap
        b.tube((sgn*0.20,0.08,0.86),(sgn*0.20,0.08,0.83),0.032,0.028,sg(hi,6,10),'paint_cream',cap0=False,cap1=True,smooth=True)
    # legs
    for sgn in (-1,1):
        b.tube((sgn*0.07,0.02,0.88),(sgn*0.09,0.04,0.48),0.07,0.055,sg(hi,8,12),'paint_cream',cap0=True,cap1=False,smooth=True)
        b.tube((sgn*0.09,0.04,0.48),(sgn*0.08,0.03,0.16),0.050,0.042,sg(hi,8,12),'paint_cream',cap0=False,cap1=True,smooth=True)
        # ankle cap
        b.tube((sgn*0.08,0.03,0.16),(sgn*0.08,0.03,0.12),0.040,0.036,sg(hi,6,10),'paint_cream',cap0=False,cap1=True,smooth=True)
    # maker plate on the base
    maker_plate(b,(0,-0.16,0.05),hi,w=0.06,h=0.014)
    b.ccyl((0,0,0),0.22,H)


# ------------------------------------------------------------------ shoe_bench
def shoe_bench(b, hi=False):
    W,D,H=1.10,0.42,0.48
    th=0.04
    # slat seat (individual slats, park-bench bar)
    for i in range(5):
        y=-0.14+i*0.07
        b.box((0,y,H-th),(W-0.08,0.06,th),'oak')
    # breadboard ends
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.03,0.0,H-th),(0.06,D-0.04,th+0.004),'oak')
    # apron
    b.box((0,-(D/2)+0.03,H-th-0.06),(W-0.16,0.024,0.05),'oak')
    b.box((0,(D/2)-0.03,H-th-0.06),(W-0.16,0.024,0.05),'oak')
    # legs with a collar and a taper block
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.07,D/2-0.07):
            b.box((x,y,0.04),(0.055,0.055,H-th-0.04),'oak')
            b.box((x,y,0.10),(0.07,0.07,0.03),'oak')
            b.box((x,y,H-th-0.08),(0.07,0.07,0.04),'oak')
            leveler(b,(x,y),hi)
    # stretchers + lower shoe shelf (slats)
    b.box((0,0.0,0.16),(W-0.20,0.03,0.03),'oak')
    b.box((0,0.0,0.16),(0.03,D-0.18,0.03),'oak')
    for i in range(4):
        y=-0.12+i*0.08
        b.box((0,y,0.18),(W-0.22,0.05,0.016),'oak')
    # mid front leg for a longer bench look
    b.box((0,-(D/2)+0.07,0.04),(0.05,0.05,H-th-0.04),'oak')
    # shoe horn hook on one end
    b.tube((W/2-0.04,0.0,H-0.02),(W/2-0.04,0.0,H+0.10),0.008,0.008,sg(hi,6,10),'steel',cap0=False,cap1=True,smooth=True)
    b.tube((W/2-0.04,0.0,H+0.10),(W/2-0.10,0.0,H+0.10),0.007,0.007,sg(hi,6,10),'steel',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,-(D/2)+0.04,0.22),hi,w=0.07,h=0.014)
    b.cbox((0,0,0),(W,D,H+0.12))


# ------------------------------------------------------------------ shoe_wall
def shoe_wall(b, hi=False):
    W,D,H=1.20,0.36,2.00
    # carcass
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.02,0.0,0.08),(0.04,D,H-0.16),'oak',skip=('bottom',))
    b.box((0,D/2-0.016,0.08),(W-0.06,0.016,H-0.16),'oak')  # back
    b.box((0,0.0,0.0),(W,D,0.08),'oak',skip=('bottom',))
    b.box((0,0.0,H-0.08),(W,D,0.08),'oak')
    b.box((0,-0.01,H-0.12),(W-0.04,D-0.04,0.03),'oak')
    # grid: 4 rows x 4 columns of cubbies
    rows=4; cols=4
    zw0,zw1=0.12,H-0.20
    xw0,xw1=-W/2+0.04,W/2-0.04
    for r in range(rows+1):
        z=zw0+r*(zw1-zw0)/rows
        b.box((0,0.0,z),(W-0.08,D-0.04,0.016),'oak')
    for c in range(cols+1):
        x=xw0+c*(xw1-xw0)/cols
        b.box((x,0.0,0.12),(0.016,D-0.04,H-0.24),'oak')
    # front lip / ticket on each row
    for r in range(rows):
        z=zw0+(r+0.0)*(zw1-zw0)/rows
        b.box((0,-(D/2)+0.02,z+0.01),(W-0.12,0.016,0.018),'oak')
        if not hi:
            # one goods card per row (shoes face -Y)
            zc=z+(zw1-zw0)/rows*0.55
            b.box((0,-(D/2)+0.08,zc),(W-0.16,0.008,min(0.28,(zw1-zw0)/rows-0.10)),'goods')
    if hi:
        y=-(D/2)+0.08-0.006
        bodies=('paint_navy','paint_cream','paint_black','oak','fabric','brass')
        for r in range(rows):
            z=zw0+(r+0.22)*(zw1-zw0)/rows
            for c in range(cols):
                x=xw0+(c+0.5)*(xw1-xw0)/cols
                key=bodies[(r+c)%len(bodies)]
                # shoe side-silhouette: sole + upper
                b.box((x,y,z),(0.18,0.004,0.06),key)           # sole
                b.box((x-0.02,y,z+0.08),(0.14,0.004,0.10),key) # upper
                b.box((x+0.04,y,z+0.04),(0.08,0.004,0.04),'label')
    maker_plate(b,(0,-(D/2)+0.03,0.10),hi,w=0.07,h=0.014)
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))


# ------------------------------------------------------------------ registry
_C=dict(dir='props/indoor/clothing',pdir='indoor_clothing',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('clothes_rack',clothes_rack,'medium',1000,side=96,cage=0.04,ray=0.12),
    _p('fitting_room',fitting_room,'large',2500),
    _p('mannequin',mannequin,'medium',900),
    _p('shoe_bench',shoe_bench,'small',550),
    _p('shoe_wall',shoe_wall,'medium',1100,side=96,cage=0.04,ray=0.12),
]
