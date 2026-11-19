"""House furniture — 26 residential pieces, page H, near+col only.

Origin at the footprint centre, underside on y=0, front −Y (glTF +Z).
upper_cabinet is wall-hung with the pivot at the bottom of the case.
One material on page H; collision is one box or one cylinder.
"""
import math
from mathutils import Vector

def sg(hi, lo, hi_n):
    return hi_n if hi else lo

def maker_plate(b, c, hi=False, w=0.04, h=0.010, rz=0.0, key='badge'):
    b.box(c,(w,0.004,h),key,rz=rz)

def four_legs(b, W, D, z0, z1, r0, r1, se, key='walnut', inset=0.045, ferrule=True):
    """Tapered legs, r0 at the floor, r1 at the apron. Optional brass ferrule."""
    pts=((-W*0.5+inset,-D*0.5+inset),(W*0.5-inset,-D*0.5+inset),
         (-W*0.5+inset, D*0.5-inset),(W*0.5-inset, D*0.5-inset))
    for x,y in pts:
        b.tube((x,y,z0),(x,y,z1),r0,r1,se,key,cap0=True,cap1=True,smooth=True)
        if ferrule:
            b.tube((x,y,z0),(x,y,z0+0.012),r0*1.15,r0*1.05,max(6,se-2),'brass',cap0=True,cap1=True,smooth=True)
    return pts

def bar_pull(b, x, y, z, w, key='brass', se=8):
    for s in (-1,1):
        b.tube((x+s*w*0.38,y,z),(x+s*w*0.38,y-0.012,z),0.004,0.004,se,key,cap0=True,cap1=True,smooth=True)
    b.tube((x-w*0.5,y-0.012,z),(x+w*0.5,y-0.012,z),0.005,0.005,se,key,cap0=True,cap1=True,smooth=True)

def knob(b, c, key='brass', r=0.009, se=8, toward=-1):
    x,y,z=c
    b.tube((x,y,z),(x,y+toward*0.014,z),r*0.45,r,se,key,cap0=True,cap1=True,smooth=True)

def raised_panel(b, c, size, key, t=0.016):
    """Door or drawer front with a slightly proud inner panel.
    `c` is the door's own bottom-centre (place it in front of the carcass)."""
    x,y,z=c; W,D,H=size
    b.box(c,size,key)
    b.box((x, y-D*0.5-0.001, z+t),(W-2*t, 0.006, H-2*t),key)

def carcass(b, c, size, key, top_over=0.012, top_h=0.024):
    """Closed case: body has no top face; an overhanging slab sits on it
    so the lid cannot z-fight with the carcass or bake a black AO hole."""
    x,y,z=c; W,D,H=size
    body_h=max(0.04, H-top_h)
    b.box((x,y,z),(W,D,body_h),key, skip=('top',))
    b.box((x,y,z+body_h),(W+2*top_over, D+2*top_over, top_h),key)

def door_y(D, thick=0.022):
    """Bottom-centre Y of a door that sits just in front of a carcass of depth D."""
    return -D*0.5 - thick*0.5

def apron(b, W, D, z, t=0.05, h=0.06, key='walnut', inset=0.02):
    b.box((0, -D*0.5+t*0.5, z),(W-inset, t, h),key)
    b.box((0,  D*0.5-t*0.5, z),(W-inset, t, h),key)
    b.box((-(W*0.5)+t*0.5, 0, z),(t, D-2*t-inset, h),key)
    b.box(( (W*0.5)-t*0.5, 0, z),(t, D-2*t-inset, h),key)

# ------------------------------------------------------------------ living

def sofa_3seat(b, hi=False):
    W,D,H=2.10,0.90,0.86
    se=sg(hi,8,10)
    four_legs(b,W*0.96,D*0.88,0.0,0.16,0.014,0.026,se,'walnut',inset=0.07)
    # walnut deck and rear rail
    b.box((0,0.02,0.16),(W, D*0.90, 0.08),'walnut')
    b.box((0, D*0.5-0.07, 0.24),(W, 0.14, H-0.24),'walnut')
    # three seat cushions with a slight gap
    cw=(W-0.10)/3.0
    for x in (-cw, 0.0, cw):
        b.box((x, -0.05, 0.24),(cw-0.018, D*0.62, 0.15),'linen_sand')
        # back cushion
        b.box((x, D*0.32, 0.40),(cw-0.018, 0.14, H-0.46),'linen_olive')
    # solid arms with a padded cap
    for x in (-W*0.5+0.075, W*0.5-0.075):
        b.box((x, 0.00, 0.24),(0.15, D*0.90, 0.32),'walnut')
        b.box((x, 0.00, 0.56),(0.17, D*0.90, 0.08),'linen_sand')
    # thin welt along the deck front
    b.box((0, -D*0.5+0.04, 0.23),(W-0.16, 0.012, 0.012),'linen_mustard')
    maker_plate(b,(0, D*0.4, 0.18),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W,D,H))

def lounge_chair(b, hi=False):
    W,D,H=0.78,0.85,0.92
    se=sg(hi,8,10)
    four_legs(b,W*0.88,D*0.82,0.0,0.32,0.012,0.022,se,'walnut',inset=0.05)
    # slightly reclined seat
    b.box((0,-0.04,0.32),(0.62,0.52,0.07),'walnut')
    b.box((0,-0.04,0.39),(0.58,0.48,0.07),'linen_sand')
    # angled back (rx tilts the top toward +Y)
    b.box((0, 0.28, 0.40),(0.62,0.09,0.50),'walnut', rx=math.radians(-16))
    b.box((0, 0.24, 0.46),(0.56,0.07,0.42),'linen_olive', rx=math.radians(-16))
    # open arms: front post, rail, rear post
    for x in (-0.34, 0.34):
        b.tube((x,-0.28,0.32),(x,-0.28,0.62),0.016,0.013,se,'walnut',cap0=True,cap1=True,smooth=True)
        b.tube((x, 0.26,0.56),(x, 0.26,0.72),0.016,0.013,se,'walnut',cap0=True,cap1=True,smooth=True)
        b.tube((x,-0.28,0.62),(x, 0.26,0.72),0.013,0.013,se,'walnut',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.20,0.34),hi,w=0.04,h=0.010)
    b.cbox((0,0,0),(W,D,H))

def ottoman(b, hi=False):
    W,D,H=0.70,0.55,0.42
    se=sg(hi,8,10)
    four_legs(b,W,D,0.0,0.18,0.012,0.020,se,'walnut',inset=0.05)
    b.box((0,0,0.18),(W,D,0.07),'walnut')
    b.box((0,0,0.25),(W-0.04,D-0.04,0.15),'linen_sand')
    # welt
    b.box((0,0,0.248),(W-0.02,D-0.02,0.012),'linen_mustard')
    maker_plate(b,(0,0.20,0.20),hi,w=0.035,h=0.008)
    b.cbox((0,0,0),(W,D,H))

def coffee_table(b, hi=False):
    W,D,H=1.20,0.60,0.40
    se=sg(hi,8,10)
    four_legs(b,W,D,0.0,0.36,0.013,0.022,se,'walnut',inset=0.05)
    # lowered shelf
    b.box((0,0,0.12),(W-0.12,D-0.12,0.018),'walnut')
    apron(b,W,D,0.30,t=0.04,h=0.06,key='walnut',inset=0.04)
    b.box((0,0,0.36),(W,D,0.04),'walnut')
    # thin brass edge cap on the top
    b.box((0, -D*0.5+0.004, 0.395),(W,0.008,0.006),'brass')
    b.box((0,  D*0.5-0.004, 0.395),(W,0.008,0.006),'brass')
    maker_plate(b,(0,0,0.13),hi,w=0.05,h=0.010)
    b.cbox((0,0,0),(W,D,H))

def side_table(b, hi=False):
    # round MCM drinks table, three splayed legs
    R,H=0.25,0.55
    se=sg(hi,12,16)
    b.tube((0,0,H-0.028),(0,0,H),R,R,se,'walnut',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,H-0.034),(0,0,H-0.028),R*0.92,R,se,'walnut',cap0=False,cap1=False,smooth=True)
    # three slightly splayed legs
    for i in range(3):
        a=2*math.pi*i/3 + 0.4
        x0,y0=(R-0.06)*math.cos(a),(R-0.06)*math.sin(a)
        x1,y1=(R-0.03)*math.cos(a),(R-0.03)*math.sin(a)
        b.tube((x0,y0,0.0),(x1,y1,H-0.034),0.012,0.016,sg(hi,8,10),'walnut',cap0=True,cap1=True,smooth=True)
        b.tube((x0,y0,0.0),(x0,y0,0.012),0.014,0.012,6,'brass',cap0=True,cap1=True,smooth=True)
    # small shelf ring
    b.tube((0,0,0.22),(0,0,0.236),R*0.55,R*0.55,se,'walnut',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.08,0.226),hi,w=0.03,h=0.008)
    b.ccyl((0,0,0),R,H)

def credenza(b, hi=False):
    W,D,H=1.80,0.45,0.75
    se=sg(hi,8,10)
    four_legs(b,W,D,0.0,0.18,0.014,0.024,se,'walnut',inset=0.06)
    carcass(b,(0,0,0.18),(W,D,H-0.18),'walnut', top_over=0.012, top_h=0.024)
    # sliding doors, proud of the front, slight overlap
    dw=(W-0.04)*0.5; dy=door_y(D)
    raised_panel(b,(-dw*0.5-0.01,dy,0.22),(dw,0.022,H-0.30),'walnut',t=0.020)
    raised_panel(b,( dw*0.5+0.01,dy-0.002,0.22),(dw,0.022,H-0.30),'teak',t=0.020)
    bar_pull(b,-0.42,dy,0.48,0.10,se=se)
    bar_pull(b, 0.42,dy-0.002,0.48,0.10,se=se)
    maker_plate(b,(0,D*0.4,0.22),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W+0.02,D+0.02,H))

def floor_lamp(b, hi=False):
    se=sg(hi,10,14)
    # disc base
    b.tube((0,0,0.0),(0,0,0.018),0.18,0.16,se,'brass',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.018),(0,0,0.028),0.16,0.04,se,'brass',cap0=False,cap1=True,smooth=True)
    # stem
    b.tube((0,0,0.028),(0,0,1.20),0.012,0.010,se,'brass',cap0=False,cap1=True,smooth=True)
    # cone shade, linen
    b.tube((0,0,1.16),(0,0,1.55),0.22,0.09,sg(hi,14,18),'linen_mustard',cap0=False,cap1=False,smooth=True)
    # inner spider
    b.tube((0,0,1.52),(0,0,1.55),0.09,0.03,se,'brass',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,0.10,0.012),hi,w=0.03,h=0.008)
    b.ccyl((0,0,0),0.22,1.55)

def tv_console(b, hi=False):
    W,D,H=1.20,0.40,0.55
    se=sg(hi,8,10)
    four_legs(b,W,D,0.0,0.12,0.012,0.020,se,'walnut',inset=0.05)
    carcass(b,(0,0,0.12),(W,D,H-0.12),'walnut', top_over=0.010, top_h=0.022)
    dy=door_y(D)
    raised_panel(b,(-0.32,dy,0.16),(0.52,0.022,H-0.26),'walnut',t=0.018)
    raised_panel(b,( 0.32,dy,0.16),(0.52,0.022,H-0.26),'walnut',t=0.018)
    knob(b,(-0.12,dy,0.36),se=se)
    knob(b,( 0.12,dy,0.36),se=se)
    # ventilation slots on the sides (shallow recesses)
    for x in (-W*0.5, W*0.5):
        for i,z in enumerate((0.22,0.28,0.34,0.40)):
            b.box((x,0,z),(0.008,0.16,0.018),'paint_grey')
    # back cable notch (visual only, under the top)
    b.box((0, D*0.5-0.01, H-0.08),(0.08,0.02,0.03),'paint_grey')
    maker_plate(b,(0,D*0.35,0.16),hi,w=0.04,h=0.010)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ kitchen

def fridge_home(b, hi=False):
    # 1950s rounded fridge, cream enamel, split freezer door, chrome latch
    W,D,H=0.76,0.80,1.70
    se=sg(hi,12,16)
    r=0.070
    # short rounded feet
    for x,y in ((-0.28,-0.28),(0.28,-0.28),(-0.28,0.28),(0.28,0.28)):
        b.tube((x,y,0.0),(x,y,0.06),0.028,0.024,sg(hi,8,10),'steel',cap0=True,cap1=True,smooth=True)
    z0=0.06
    th=0.028
    body_top=H-th
    # rounded-rect carcass ends under a single lid so unique-bake AO
    # cannot punch a hole along coplanar top seams
    b.box((0,0,z0),(W-2*r, D, body_top-z0),'paint_cream', skip=('top',))
    b.box((-(W*0.5)+r*0.5, 0, z0),(r, D-2*r, body_top-z0),'paint_cream', skip=('top',))
    b.box(( (W*0.5)-r*0.5, 0, z0),(r, D-2*r, body_top-z0),'paint_cream', skip=('top',))
    for sx,sy in ((-1,-1),(1,-1),(-1,1),(1,1)):
        cx,cy=sx*(W*0.5-r), sy*(D*0.5-r)
        b.tube((cx,cy,z0),(cx,cy,body_top),r,r,se,'paint_cream',cap0=True,cap1=True,smooth=True)
    # one closed lid, slight overhang; square corners read as a period cap
    over=0.008
    b.box((0,0,body_top),(W+2*over, D+2*over, th),'paint_cream')
    # split doors, proud of the front: freezer on top, fridge below
    dy=-D*0.5-0.018
    # fridge door
    b.box((0, dy, 0.10),(W-0.10, 0.036, 1.04),'paint_cream')
    # freezer door, tight under the lid (small reveal)
    fz, fh = 1.17, body_top-1.17-0.016
    b.box((0, dy, fz),(W-0.10, 0.036, fh),'paint_cream')
    # gaskets
    b.box((0, dy+0.016, 0.10),(W-0.08, 0.006, 1.04),'paint_grey')
    b.box((0, dy+0.016, fz),(W-0.08, 0.006, fh),'paint_grey')
    # chrome latch handles (horizontal, 1950s) — thick and proud so they read at sheet scale
    for z,w in ((0.70,0.18),(1.40,0.16)):
        b.tube((0.16, dy-0.030, z),(0.16+w, dy-0.030, z),0.018,0.018,se,'chrome',cap0=True,cap1=True,smooth=True)
        b.tube((0.16, dy, z),(0.16, dy-0.030, z),0.011,0.011,8,'chrome',cap0=True,cap1=True,smooth=True)
        b.tube((0.16+w, dy, z),(0.16+w, dy-0.030, z),0.011,0.011,8,'chrome',cap0=True,cap1=True,smooth=True)
        b.box((0.16+w*0.5, dy-0.002, z),(w+0.05, 0.008, 0.038),'chrome')
    b.box((0.22, dy-0.003, 1.52),(0.10,0.006,0.04),'badge')
    maker_plate(b,(0,D*0.35,0.12),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W,D+0.04,H))

def range_gas(b, hi=False):
    W,D,H=0.76,0.66,0.92
    se=sg(hi,8,10)
    b.box((0,0,0.0),(W,D,0.08),'steel')  # toe
    b.box((0,0,0.08),(W,D,0.62),'paint_cream')
    # cooktop
    b.box((0,0,0.70),(W,D,0.04),'paint_grey')
    # backsplash
    b.box((0, D*0.5-0.04, 0.74),(W,0.08,H-0.74),'paint_cream')
    # four burners + grates
    for x,y in ((-0.18,-0.12),(0.18,-0.12),(-0.18,0.14),(0.18,0.14)):
        b.tube((x,y,0.74),(x,y,0.755),0.09,0.09,se,'paint_black',cap0=True,cap1=True,smooth=True)
        # cross grate
        b.box((x,y,0.755),(0.16,0.014,0.012),'steel')
        b.box((x,y,0.755),(0.014,0.16,0.012),'steel')
    # oven door + opaque window
    b.box((0,-D*0.5+0.02,0.10),(W-0.10,0.04,0.48),'paint_cream')
    b.box((0,-D*0.5-0.002,0.22),(0.42,0.012,0.22),'glass')
    # handle
    b.tube((-0.22,-D*0.5-0.016,0.54),(0.22,-D*0.5-0.016,0.54),0.009,0.009,se,'chrome',cap0=True,cap1=True,smooth=True)
    # four knobs on the front rail
    for i,x in enumerate((-0.24,-0.08,0.08,0.24)):
        b.tube((x,-D*0.5-0.006,0.66),(x,-D*0.5-0.018,0.66),0.012,0.014,se,'chrome',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0.0,D*0.35,0.12),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W,D,H))

def sink_base(b, hi=False):
    W,D,H=1.20,0.62,0.90
    se=sg(hi,8,10)
    # cabinet
    b.box((0,0,0.0),(W,D,0.08),'wash')  # kick
    b.box((0,0,0.08),(W,D,0.70),'wash', skip=('top',))
    dy=door_y(D,0.024)
    raised_panel(b,(-0.30,dy,0.12),(0.54,0.024,0.58),'wash',t=0.018)
    raised_panel(b,( 0.30,dy,0.12),(0.54,0.024,0.58),'wash',t=0.018)
    knob(b,(-0.08,dy,0.40),se=se)
    knob(b,( 0.08,dy,0.40),se=se)
    # counter, slightly overhanging (sits on the open carcass)
    b.box((0,0,0.78),(W+0.03,D+0.04,0.04),'wash')
    # farm-style basin: apron on the front, open well
    b.box((0,-D*0.5-0.02,0.62),(0.72,0.06,0.16),'ceramic_white')
    b.box((0,-0.04,0.70),(0.62,0.40,0.02),'ceramic_white')  # well floor
    b.box((0,-0.04-0.19,0.72),(0.62,0.04,0.08),'ceramic_white')
    b.box((0,-0.04+0.19,0.72),(0.62,0.04,0.08),'ceramic_white')
    b.box((-0.31,-0.04,0.72),(0.04,0.40,0.08),'ceramic_white')
    b.box(( 0.31,-0.04,0.72),(0.04,0.40,0.08),'ceramic_white')
    # faucet gooseneck
    b.tube((0, 0.20, 0.82),(0, 0.20, 1.05),0.012,0.012,se,'chrome',cap0=True,cap1=False,smooth=True)
    b.tube((0, 0.20, 1.05),(0,-0.02, 1.05),0.011,0.011,se,'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0,-0.02, 1.05),(0,-0.02, 0.96),0.011,0.016,se,'chrome',cap0=False,cap1=True,smooth=True)
    # tap handles
    for x in (-0.08,0.08):
        b.tube((x,0.20,0.82),(x,0.20,0.92),0.008,0.008,6,'chrome',cap0=True,cap1=True,smooth=True)
    # drip rail on the front edge
    b.box((0,-D*0.5-0.008,0.78),(W+0.02,0.016,0.012),'chrome')
    maker_plate(b,(0,D*0.35,0.14),hi,w=0.05,h=0.010)
    b.cbox((0,0,0),(W+0.02,D+0.04,1.06))


def upper_cabinet(b, hi=False):
    # wall-hung; pivot at the bottom of the case
    W,D,H=0.80,0.32,0.70
    se=sg(hi,8,10)
    carcass(b,(0,0,0.0),(W,D,H-0.07),'wash', top_over=0.008, top_h=0.020)
    # stepped crown
    b.box((0,0,H-0.07),(W+0.04,D+0.02,0.03),'wash')
    b.box((0,-0.008,H-0.04),(W+0.06,D+0.036,0.04),'wash')
    dy=door_y(D)
    # two doors with a clear centre gap and side margins
    dw=0.34
    raised_panel(b,(-0.19,dy,0.05),(dw,0.022,H-0.16),'wash',t=0.016)
    raised_panel(b,( 0.19,dy,0.05),(dw,0.022,H-0.16),'wash',t=0.016)
    knob(b,(-0.04,dy,H*0.48),se=se, r=0.011)
    knob(b,( 0.04,dy,H*0.48),se=se, r=0.011)
    maker_plate(b,(0,D*0.3,0.04),hi,w=0.04,h=0.010)
    b.cbox((0,0,0),(W+0.06,D+0.04,H+0.01))

# ------------------------------------------------------------------ dining

def dining_table(b, hi=False):
    W,D,H=1.50,0.90,0.75
    se=sg(hi,8,10)
    four_legs(b,W,D,0.0,0.68,0.016,0.028,se,'walnut',inset=0.07)
    apron(b,W,D,0.62,t=0.05,h=0.08,key='walnut',inset=0.06)
    b.box((0,0,0.70),(W,D,0.05),'walnut')
    maker_plate(b,(0,0,0.63),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W,D,H))

def dining_chair(b, hi=False):
    W,D,H=0.46,0.52,0.86
    se=sg(hi,8,10)
    # slightly splayed legs
    legs=((-0.17,-0.18),(0.17,-0.18),(-0.18,0.18),(0.18,0.18))
    for i,(x,y) in enumerate(legs):
        r0,r1=0.010,0.016
        b.tube((x,y,0.0),(x*0.95,y*0.95,0.42),r0,r1,se,'walnut',cap0=True,cap1=True,smooth=True)
        b.tube((x,y,0.0),(x,y,0.012),0.012,0.010,6,'brass',cap0=True,cap1=True,smooth=True)
    # seat
    b.box((0,0,0.42),(0.42,0.40,0.04),'walnut')
    b.box((0,0,0.46),(0.40,0.38,0.04),'linen_sand')
    # back posts and three slats
    for x in (-0.17,0.17):
        b.tube((x,0.18,0.42),(x,0.20,0.86),0.014,0.012,se,'walnut',cap0=True,cap1=True,smooth=True)
    b.tube((-0.17,0.20,0.84),(0.17,0.20,0.84),0.010,0.010,se,'walnut',cap0=True,cap1=True,smooth=True)
    for z in (0.58,0.68,0.78):
        b.box((0,0.20,z),(0.28,0.012,0.04),'walnut')
    maker_plate(b,(0,0.12,0.44),hi,w=0.03,h=0.008)
    b.cbox((0,0,0),(W,D,H))

def sideboard(b, hi=False):
    W,D,H=1.60,0.45,0.85
    se=sg(hi,8,10)
    four_legs(b,W,D,0.0,0.16,0.014,0.024,se,'walnut',inset=0.06)
    carcass(b,(0,0,0.16),(W,D,H-0.16),'walnut', top_over=0.012, top_h=0.024)
    dy=door_y(D)
    dw=(W-0.06)/3.0
    for i,x in enumerate((-dw,0.0,dw)):
        raised_panel(b,(x,dy,H-0.30),(dw-0.016,0.022,0.18),'walnut',t=0.016)
        bar_pull(b,x,dy,H-0.21,0.10,se=se)
    raised_panel(b,(-0.38,dy,0.20),(0.74,0.022,H-0.54),'walnut',t=0.018)
    raised_panel(b,( 0.38,dy,0.20),(0.74,0.022,H-0.54),'walnut',t=0.018)
    knob(b,(-0.08,dy,0.48),se=se)
    knob(b,( 0.08,dy,0.48),se=se)
    maker_plate(b,(0,D*0.35,0.20),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W+0.02,D+0.02,H))

# ------------------------------------------------------------------ bedroom

def bed_queen(b, hi=False):
    W,D,H=1.70,2.15,1.05
    se=sg(hi,8,10)
    # legs: four at the posts, plus the headboard sits on the back pair
    four_legs(b,W,D,0.0,0.22,0.016,0.026,se,'walnut',inset=0.08,ferrule=True)
    # side rails and foot rail
    b.box((0,0,0.22),(W-0.04,D-0.10,0.10),'walnut')
    # platform / mattress
    b.box((0,0,0.32),(W-0.06,D-0.12,0.18),'linen')
    # coverlet with a fold at the foot (−Y)
    b.box((0,0.06,0.50),(W-0.04,D-0.28,0.07),'linen_sand')
    b.box((0,-D*0.5+0.28,0.50),(W-0.04,0.28,0.09),'linen_mustard')
    # two pillows against the headboard
    for x in (-0.38,0.38):
        b.box((x, D*0.5-0.32, 0.57),(0.62,0.22,0.16),'linen')
    # mid-century headboard: wide walnut panel, slightly proud, rounded-looking top rail
    b.box((0, D*0.5-0.05, 0.22),(W+0.06,0.08,0.70),'walnut')
    b.tube((-W*0.5-0.02, D*0.5-0.05, 0.92),(W*0.5+0.02, D*0.5-0.05, 0.92),0.04,0.04,se,'walnut',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0,0.26),hi,w=0.06,h=0.012)
    b.cbox((0,0,0),(W+0.06,D,H))

def nightstand(b, hi=False):
    # one MCM box on tapered legs, single drawer in the front
    W,D,H=0.50,0.40,0.58
    se=sg(hi,8,10)
    four_legs(b,W,D,0.0,0.12,0.011,0.018,se,'walnut',inset=0.04)
    carcass(b,(0,0,0.12),(W,D,H-0.12),'walnut', top_over=0.008, top_h=0.022)
    dy=door_y(D)
    raised_panel(b,(0,dy,0.26),(W-0.06,0.022,0.22),'walnut',t=0.014)
    bar_pull(b,0,dy,0.37,0.10,se=se)
    maker_plate(b,(0,D*0.3,0.16),hi,w=0.03,h=0.008)
    b.cbox((0,0,0),(W+0.016,D+0.016,H))

def dresser(b, hi=False):
    W,D,H=1.30,0.50,0.80
    se=sg(hi,8,10)
    four_legs(b,W,D,0.0,0.12,0.013,0.022,se,'walnut',inset=0.055)
    carcass(b,(0,0,0.12),(W,D,H-0.12),'walnut', top_over=0.012, top_h=0.024)
    dy=door_y(D)
    dw=(W-0.08)/2.0
    dh=(H-0.24)/3.0
    for ix,x in enumerate((-dw*0.5, dw*0.5)):
        for iz,z in enumerate((0.16, 0.16+dh, 0.16+2*dh)):
            raised_panel(b,(x,dy,z),(dw-0.016,0.022,dh-0.020),'walnut',t=0.014)
            bar_pull(b,x,dy,z+(dh-0.020)*0.5,0.12,se=se)
    maker_plate(b,(0,D*0.35,0.16),hi,w=0.05,h=0.010)
    b.cbox((0,0,0),(W+0.02,D+0.02,H))

# ------------------------------------------------------------------ bathroom


def claw_foot(b, x, y, h=0.16, se=8):
    """Stylised brass claw: a ball on the floor, ankle up to the tub, three toes."""
    L=math.hypot(x,y) or 1.0
    ox,oy=x/L, y/L
    br=0.030
    # ball
    b.tube((x,y,0.016),(x,y,0.016+br*1.85),br,br*0.92,se,'brass',cap0=True,cap1=True,smooth=True)
    # ankle
    b.tube((x,y,0.016+br*1.55),(x,y,h),br*0.52,br*0.38,se,'brass',cap0=False,cap1=True,smooth=True)
    # three toes fanning outward, each with a small pad
    for a in (-0.72, 0.0, 0.72):
        ca,sa=math.cos(a),math.sin(a)
        tx,ty=ox*ca-oy*sa, ox*sa+oy*ca
        x1,y1=x+tx*0.058, y+ty*0.058
        b.tube((x+tx*0.008, y+ty*0.008, 0.032),(x1,y1,0.012),0.013,0.009,max(6,se-2),'brass',cap0=True,cap1=True,smooth=True)
        b.tube((x1,y1,0.0),(x1,y1,0.012),0.012,0.009,6,'brass',cap0=True,cap1=True,smooth=True)

def toilet(b, hi=False):
    # close-coupled: pedestal, oval bowl, seat + lid, tank seated on the rear deck
    se=sg(hi,20,28)
    yc=-0.12  # bowl centre, toward the front
    def oval(z, rx, ry, yoff=yc):
        return [Vector((rx*math.cos(2*math.pi*i/se), yoff+ry*math.sin(2*math.pi*i/se), z)) for i in range(se)]
    def stitch(a,c,key):
        for i in range(se):
            j=(i+1)%se
            b.quad([a[i],a[j],c[j],c[i]], key)
    def cap(pts, z, key, inward=False):
        c=Vector((0,yc,z))
        luv=[[(0,0),(pts[i].x,pts[i].y),(pts[(i+1)%se].x,pts[(i+1)%se].y)] for i in range(se)]
        faces=[(0,i+1,1+((i+1)%se)) for i in range(se)]
        if inward: faces=[(f[0],f[2],f[1]) for f in faces]
        b.faces([c]+pts, faces, key, luv)
    # pedestal
    stitch(oval(0.00,0.11,0.13), oval(0.10,0.13,0.15), 'enamel')
    stitch(oval(0.10,0.13,0.15), oval(0.18,0.14,0.16), 'enamel')
    cap(oval(0.00,0.11,0.13), 0.00, 'enamel')
    # bowl flare to the rim
    stitch(oval(0.18,0.14,0.16), oval(0.30,0.20,0.24), 'enamel')
    stitch(oval(0.30,0.20,0.24), oval(0.40,0.22,0.26), 'enamel')
    # rolled rim inward
    stitch(oval(0.40,0.22,0.26), oval(0.40,0.16,0.19), 'enamel')
    # glossy well
    stitch(oval(0.40,0.16,0.19), oval(0.26,0.13,0.16), 'enamel_in')
    cap(oval(0.26,0.13,0.16), 0.26, 'enamel_in')
    # rear deck that the tank sits on (meets the back of the bowl)
    b.box((0, 0.16, 0.36),(0.46, 0.22, 0.06),'enamel')
    # rounded tank, single lid sitting on the open carcass (no coplanar top)
    tw,td,z0t,body_h,tr=0.44,0.20,0.42,0.30,0.040
    tse=sg(hi,8,10)
    b.box((0, 0.20, z0t),(tw-2*tr, td, body_h),'enamel', skip=('top',))
    b.box((-(tw*0.5)+tr*0.5, 0.20, z0t),(tr, td-2*tr, body_h),'enamel', skip=('top',))
    b.box(( (tw*0.5)-tr*0.5, 0.20, z0t),(tr, td-2*tr, body_h),'enamel', skip=('top',))
    for sx,sy in ((-1,-1),(1,-1),(-1,1),(1,1)):
        cx,cy=sx*(tw*0.5-tr), 0.20+sy*(td*0.5-tr)
        b.tube((cx,cy,z0t),(cx,cy,z0t+body_h),tr,tr,tse,'enamel',cap0=True,cap1=True,smooth=True)
    b.box((0, 0.20, z0t+body_h),(tw+0.02, td+0.02, 0.04),'enamel')
    # seat ring
    stitch(oval(0.415,0.205,0.245,yc-0.01), oval(0.430,0.205,0.245,yc-0.01), 'enamel')
    stitch(oval(0.430,0.205,0.245,yc-0.01), oval(0.430,0.125,0.150,yc-0.01), 'enamel')
    stitch(oval(0.430,0.125,0.150,yc-0.01), oval(0.415,0.125,0.150,yc-0.01), 'enamel')
    # lid, closed, slightly rearward
    lid=oval(0.455,0.210,0.250, yc+0.02)
    cap(lid, 0.455, 'enamel')
    b.tube((0, yc+0.24, 0.42),(0, yc+0.24, 0.455),0.012,0.012,8,'enamel',cap0=True,cap1=True,smooth=True)
    # flush lever and supply
    b.tube((0.18,0.08,0.70),(0.28,0.08,0.70),0.007,0.007,6,'chrome',cap0=True,cap1=True,smooth=True)
    b.tube((0.16,0.22,0.00),(0.16,0.22,0.42),0.008,0.008,6,'chrome',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.28,0.50),hi,w=0.04,h=0.010)
    b.cbox((0,0,0),(0.52,0.70,0.84))

def vanity_sink(b, hi=False):
    W,D,H=0.90,0.50,0.88
    se=sg(hi,8,10)
    four_legs(b,W,D,0.0,0.14,0.012,0.018,se,'wash',inset=0.05,ferrule=False)
    b.box((0,0,0.14),(W,D,0.60),'wash', skip=('top',))
    dy=door_y(D)
    raised_panel(b,(-0.22,dy,0.18),(0.40,0.022,0.48),'wash',t=0.016)
    raised_panel(b,( 0.22,dy,0.18),(0.40,0.022,0.48),'wash',t=0.016)
    knob(b,(-0.06,dy,0.42),se=se)
    knob(b,( 0.06,dy,0.42),se=se)
    # enamel top + basin
    b.box((0,0,0.74),(W+0.02,D+0.02,0.04),'enamel')
    b.tube((0,-0.02,0.70),(0,-0.02,0.78),0.16,0.18,sg(hi,12,16),'enamel',cap0=True,cap1=False,smooth=True)
    b.tube((0,-0.02,0.72),(0,-0.02,0.76),0.11,0.12,sg(hi,10,12),'enamel_in',cap0=True,cap1=False,smooth=True)
    # faucet
    b.tube((0,0.14,0.78),(0,0.14,0.96),0.010,0.010,se,'chrome',cap0=True,cap1=False,smooth=True)
    b.tube((0,0.14,0.96),(0,0.00,0.96),0.009,0.009,se,'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0,0.00,0.96),(0,0.00,0.88),0.009,0.014,se,'chrome',cap0=False,cap1=True,smooth=True)
    for x in (-0.07,0.07):
        b.tube((x,0.14,0.78),(x,0.14,0.88),0.007,0.007,6,'chrome',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,D*0.32,0.18),hi,w=0.04,h=0.010)
    b.cbox((0,0,0),(W+0.02,D+0.02,H+0.08))

def bathtub(b, hi=False):
    # clawfoot, rolled rim, 1.70 x 0.75, 0.58
    W,D,H=1.70,0.75,0.58
    se=sg(hi,16,20)
    rx,ry=W*0.5-0.04, D*0.5-0.04
    def ring(z, sx, sy):
        return [Vector((rx*sx*math.cos(2*math.pi*i/se), ry*sy*math.sin(2*math.pi*i/se), z)) for i in range(se)]
    def stitch(a,c,key):
        for i in range(se):
            j=(i+1)%se
            b.quad([a[i],a[j],c[j],c[i]], key)
    foot=ring(0.16,0.78,0.72)
    belly=ring(0.28,0.92,0.90)
    rim_in=ring(0.50,0.96,0.94)
    rim=ring(0.56,1.00,1.00)
    rim_out=ring(0.50,1.04,1.04)
    stitch(foot,belly,'enamel')
    stitch(belly,rim_in,'enamel')
    stitch(rim_in,rim,'enamel')
    stitch(rim,rim_out,'enamel')
    # well floor
    c=Vector((0,0,0.20))
    luv=[[(0,0),(foot[i].x,foot[i].y),(foot[(i+1)%se].x,foot[(i+1)%se].y)] for i in range(se)]
    b.faces([c]+foot, [(0,i+1,1+((i+1)%se)) for i in range(se)], 'enamel_in', luv)
    # glossy white interior
    well=ring(0.24,0.70,0.64)
    stitch(rim_in, well, 'enamel_in')
    c2=Vector((0,0,0.22))
    luv2=[[(0,0),(well[i].x,well[i].y),(well[(i+1)%se].x,well[(i+1)%se].y)] for i in range(se)]
    b.faces([c2]+well, [(0,i+1,1+((i+1)%se)) for i in range(se)], 'enamel_in', luv2)
    # four stylised claw feet: ball + 3 toes, brass
    for x,y in ((-rx*0.72,-ry*0.62),(rx*0.72,-ry*0.62),(-rx*0.72,ry*0.62),(rx*0.72,ry*0.62)):
        claw_foot(b,x,y,h=0.16,se=sg(hi,8,10))
    # spout and overflow at the +Y end
    b.tube((0, ry*0.55, 0.50),(0, ry*0.70, 0.58),0.014,0.014,sg(hi,8,10),'chrome',cap0=True,cap1=False,smooth=True)
    b.tube((0, ry*0.70, 0.58),(0, ry*0.55, 0.58),0.014,0.018,sg(hi,8,10),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube((0, ry*0.85, 0.40),(0, ry*0.92, 0.40),0.016,0.016,8,'chrome',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0,0.18),hi,w=0.05,h=0.010)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ laundry

def washer_home(b, hi=False):
    W,D,H=0.68,0.70,0.95
    se=sg(hi,12,16)
    # feet
    for x,y in ((-0.26,-0.26),(0.26,-0.26),(-0.26,0.26),(0.26,0.26)):
        b.box((x,y,0.0),(0.06,0.06,0.04),'steel')
    b.box((0,0,0.04),(W,D,H-0.04),'paint_cream')
    # front-load door (opaque glass) with a chrome ring
    cy,cz= -D*0.5-0.008, 0.48
    b.tube((0, -D*0.5+0.01, 0.48),(0, -D*0.5-0.012, 0.48),0.20,0.20,se,'chrome',cap0=True,cap1=False,smooth=True)
    b.tube((0, -D*0.5-0.012, 0.48),(0, -D*0.5-0.016, 0.48),0.17,0.17,se,'glass',cap0=True,cap1=True,smooth=True)
    # soap drawer
    b.box((-0.16,-D*0.5-0.006,0.82),(0.22,0.04,0.07),'paint_grey')
    # badge and control knob
    b.box((0.16,-D*0.5-0.002,0.84),(0.10,0.006,0.04),'badge')
    b.tube((0.16,-D*0.5-0.010,0.76),(0.16,-D*0.5-0.020,0.76),0.016,0.018,se,'chrome',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,D*0.35,0.10),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W,D+0.03,H))

def dryer_home(b, hi=False):
    W,D,H=0.68,0.70,0.95
    se=sg(hi,10,12)
    for x,y in ((-0.26,-0.26),(0.26,-0.26),(-0.26,0.26),(0.26,0.26)):
        b.box((x,y,0.0),(0.06,0.06,0.04),'steel')
    b.box((0,0,0.04),(W,D,H-0.04),'paint_cream')
    # solid door with a small lint window
    b.box((0,-D*0.5+0.018,0.14),(W-0.10,0.04,0.62),'paint_cream')
    b.box((0,-D*0.5-0.002,0.36),(0.22,0.012,0.16),'glass')
    # handle
    b.tube((0.22,-D*0.5-0.014,0.48),(0.22,-D*0.5-0.014,0.62),0.009,0.009,se,'chrome',cap0=True,cap1=True,smooth=True)
    # lint door (lower front)
    b.box((0,-D*0.5-0.002,0.16),(0.28,0.016,0.08),'paint_grey')
    # badge + knob, matching the washer
    b.box((0.16,-D*0.5-0.002,0.84),(0.10,0.006,0.04),'badge')
    b.tube((0.16,-D*0.5-0.010,0.76),(0.16,-D*0.5-0.020,0.76),0.016,0.018,se,'chrome',cap0=True,cap1=True,smooth=True)
    # vent cuff on the back
    b.tube((0.20, D*0.5-0.01, 0.20),(0.20, D*0.5+0.04, 0.20),0.04,0.04,se,'steel',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,D*0.35,0.10),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W,D+0.04,H))

def laundry_hamper(b, hi=False):
    R,H=0.20,0.58
    se=sg(hi,12,16)
    # woven vessel
    b.tube((0,0,0.0),(0,0,0.04),0.16,0.18,se,'rattan',cap0=True,cap1=False,smooth=True)
    b.tube((0,0,0.04),(0,0,0.48),0.18,0.20,se,'rattan',cap0=False,cap1=False,smooth=True)
    # ventilation slits as darker recessed bands
    for z in (0.14,0.26,0.38):
        b.tube((0,0,z),(0,0,z+0.02),0.181,0.201,se,'paint_sand',cap0=False,cap1=False,smooth=True)
    # lid
    b.tube((0,0,0.48),(0,0,0.52),0.20,0.205,se,'rattan',cap0=False,cap1=False,smooth=True)
    b.tube((0,0,0.52),(0,0,0.58),0.205,0.14,se,'rattan',cap0=False,cap1=True,smooth=True)
    # small handle
    b.tube((-0.05,0,0.58),(0.05,0,0.58),0.008,0.008,6,'walnut',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0.16,0.08),hi,w=0.03,h=0.008)
    b.ccyl((0,0,0),R+0.01,H)

# ------------------------------------------------------------------ garage

def storage_cabinet(b, hi=False):
    W,D,H=0.90,0.45,1.80
    se=sg(hi,8,10)
    # metal case on a plinth
    b.box((0,0,0.0),(W,D,0.06),'steel')
    carcass(b,(0,0,0.06),(W,D,H-0.06),'paint_grey', top_over=0.006, top_h=0.020)
    dy=door_y(D)
    raised_panel(b,(-0.22,dy,0.10),(0.42,0.022,H-0.22),'paint_grey',t=0.018)
    raised_panel(b,( 0.22,dy,0.10),(0.42,0.022,H-0.22),'paint_grey',t=0.018)
    bar_pull(b,-0.06,dy,0.95,0.12,key='steel',se=se)
    bar_pull(b, 0.06,dy,0.95,0.12,key='steel',se=se)
    # vent slots at the top of each door
    for x in (-0.22,0.22):
        for z in (1.58,1.64,1.70):
            b.box((x,-D*0.5-0.002,z),(0.22,0.008,0.016),'steel')
    maker_plate(b,(0,D*0.3,0.12),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W,D,H))

def workbench_garage(b, hi=False):
    W,D,H=1.50,0.60,0.90
    se=sg(hi,8,10)
    # square legs, no ferrule
    for x,y in ((-0.68,-0.24),(0.68,-0.24),(-0.68,0.24),(0.68,0.24)):
        b.box((x,y,0.0),(0.08,0.08,0.80),'paint_grey')
    # lower shelf
    b.box((0,0,0.18),(W-0.20,D-0.08,0.04),'wash')
    # thick wood top, slightly proud
    b.box((0,0,0.80),(W,D,0.10),'walnut')
    # vice block on the right front corner
    b.box((0.58,-D*0.5+0.08,0.90),(0.22,0.16,0.08),'steel')
    b.tube((0.50,-D*0.5+0.08,0.98),(0.66,-D*0.5+0.08,0.98),0.016,0.016,se,'steel',cap0=True,cap1=True,smooth=True)
    b.tube((0.66,-D*0.5+0.08,0.98),(0.78,-D*0.5+0.08,0.98),0.012,0.012,se,'steel',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,0,0.82),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W,D,H+0.08))

# ------------------------------------------------------------------ materials

PM=(0.875,0.875)
TR={
    'walnut':('th_walnut',PM),'teak':('th_walnut',PM),'wash':('th_wash',PM),
    'paint_cream':('th_paint',PM),'paint_white':('th_paint',PM),'paint_black':('th_paint',PM),
    'paint_grey':('th_paint',PM),'paint_sand':('th_paint',PM),
    'linen':('th_linen',PM),'linen_sand':('th_linen',PM),'linen_olive':('th_linen',PM),'linen_mustard':('th_linen',PM),
    'steel':('th_metal',PM),'chrome':('th_metal',PM),'brass':('th_brass',PM),
    'ceramic_white':('th_ceramic',PM),'ceramic_teal':('th_ceramic',PM),
    'enamel':('th_enamel',PM),'enamel_in':('th_enamel_in',PM),
    'glass':('th_glass',PM),'rattan':('th_rattan',PM),
}
TINT={
    'walnut':(1.00,1.00,1.00),'teak':(1.15,0.95,0.70),'wash':(1.00,1.00,1.00),
    'paint_cream':(1.04,1.00,0.92),'paint_white':(1.10,1.10,1.08),'paint_black':(0.12,0.12,0.12),
    'paint_grey':(0.42,0.43,0.45),'paint_sand':(0.86,0.78,0.62),
    'linen':(1.00,1.00,1.00),'linen_sand':(1.05,0.98,0.85),'linen_olive':(0.55,0.58,0.36),'linen_mustard':(0.95,0.72,0.28),
    'steel':(1.00,1.00,1.00),'chrome':(1.18,1.20,1.22),'brass':(1.00,1.00,1.00),
    'ceramic_white':(1.08,1.07,1.04),'ceramic_teal':(0.35,0.55,0.52),
    'enamel':(1.00,1.00,1.00),'enamel_in':(1.04,1.04,1.05),
    'glass':(1.00,1.00,1.00),'rattan':(1.15,1.10,1.00),
    'badge':(1,1,1),
}

INDOOR_LOOK=True

_C=dict(dir='props/house/furn',pdir='house_furn',trim=TR,trim_tint=TINT,page='h',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d

PROPS=[
    _p('sofa_3seat',       sofa_3seat,       'medium',1100),
    _p('lounge_chair',     lounge_chair,     'medium', 900),
    _p('ottoman',          ottoman,          'small',  500),
    _p('coffee_table',     coffee_table,     'small',  550, case=True),
    _p('side_table',       side_table,       'small',  500),
    _p('credenza',         credenza,         'medium',1100, case=True),
    _p('floor_lamp',       floor_lamp,       'small',  550),
    _p('tv_console',       tv_console,       'medium', 900, case=True),
    _p('fridge_home',      fridge_home,      'medium',1100, case=True),
    _p('range_gas',        range_gas,        'medium',1100),
    _p('sink_base',        sink_base,        'medium',1100),
    _p('upper_cabinet',    upper_cabinet,    'medium', 800, mount='wall', case=True),
    _p('dining_table',     dining_table,     'medium', 900, case=True),
    _p('dining_chair',     dining_chair,     'small',  550),
    _p('sideboard',        sideboard,        'medium',1100, case=True),
    _p('bed_queen',        bed_queen,        'medium',1100),
    _p('nightstand',       nightstand,       'small',  500, case=True),
    _p('dresser',          dresser,          'medium',1100, case=True),
    _p('toilet',           toilet,           'medium', 900, ch_fill=0.84),
    _p('vanity_sink',      vanity_sink,      'medium',1000),
    _p('bathtub',          bathtub,          'medium',1100),
    _p('washer_home',      washer_home,      'medium',1000),
    _p('dryer_home',       dryer_home,       'medium',1000),
    _p('laundry_hamper',   laundry_hamper,   'small',  400),
    _p('storage_cabinet',  storage_cabinet,  'medium',1000, case=True),
    _p('workbench_garage', workbench_garage, 'medium',1000),
]
