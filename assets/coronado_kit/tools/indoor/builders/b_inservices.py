"""Indoor services props — original geometry, page I, near+col only.

washer, dryer, garment_rail, workbench, laundry_counter.
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT, stock,
)

def hanging_garment(b, c, hi=False, w=0.18, h=0.78, body='paint_navy', kind='shirt'):
    """A thick hanging garment that reads from the side, not a flat card."""
    x,y,z=c
    if kind=='trousers':
        b.box((x-0.045,y,z),(0.070,0.040,h*0.82),body)
        b.box((x+0.045,y,z),(0.070,0.040,h*0.82),body)
        b.box((x,y,z+h*0.78),(0.16,0.045,h*0.12),body)
        return
    # torso + yoke
    hem=0.88 if kind=='jacket' else 0.70
    b.box((x,y,z+h*(1-hem)),(w*0.84,0.045,h*hem-h*0.12),body)
    b.box((x,y,z+h*0.80),(w*0.70,0.048,h*0.12),body)  # yoke / collar
    # sleeves
    sl=0.28 if kind=='jacket' else 0.20
    b.box((x-w*0.52,y,z+h*0.66),(w*0.30,0.040,h*sl),body)
    b.box((x+w*0.52,y,z+h*0.66),(w*0.30,0.040,h*sl),body)
    if kind=='jacket':
        b.box((x,y-0.024,z+h*0.40),(0.012,0.006,h*0.36),'paint_black')  # placket


def _appliance_shell(b, W, D, H, hi=False, color='paint_cream'):
    b.box((0,0.0,0.08),(W,D,H-0.08),'%s'%color,skip=('bottom',))
    b.box((0,0.0,0.0),(W+0.01,D+0.01,0.08),'paint_black',skip=('bottom',))
    # top plate
    b.box((0,0.0,H-0.04),(W+0.01,D+0.01,0.04),'steel')
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)

# ------------------------------------------------------------------ washer
def washer(b, hi=False):
    W,D,H=0.64,0.70,0.95
    _appliance_shell(b,W,D,H,hi,'paint_cream')
    # recessed side panels and a back service plate so the cabinet is not a plain box
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.010,0.0,0.16),(0.012,D-0.10,H-0.28),'paint_cream')
        b.box((x+sgn*0.004,0.0,0.16),(0.006,D-0.14,0.010),'paint_cream')
        b.box((x+sgn*0.004,0.0,H-0.20),(0.006,D-0.14,0.010),'paint_cream')
    b.box((0,D/2-0.008,0.16),(W-0.12,0.012,H-0.28),'paint_cream')
    # rear inlets + drain hose
    b.tube((0.16,D/2-0.02,H-0.14),(0.16,D/2+0.04,H-0.14),0.016,0.016,sg(hi,8,12),'plastic',cap0=False,cap1=True,smooth=True)
    b.tube((-0.16,D/2-0.02,H-0.14),(-0.16,D/2+0.04,H-0.14),0.016,0.016,sg(hi,8,12),'plastic',cap0=False,cap1=True,smooth=True)
    b.tube((0.00,D/2+0.03,0.18),(0.00,D/2+0.03,H-0.22),0.014,0.014,sg(hi,8,12),'paint_navy',cap0=True,cap1=True,smooth=True)
    b.tube((0.00,D/2-0.01,0.18),(0.00,D/2+0.03,0.18),0.014,0.014,sg(hi,8,12),'paint_navy',cap0=True,cap1=False,smooth=True)
    # front panel seams and a recessed door well so it is not a plain box
    b.box((0,-(D/2)+0.01,0.10),(W-0.04,0.012,0.008),'paint_cream')
    b.box((0,-(D/2)+0.01,H-0.16),(W-0.04,0.012,0.008),'paint_cream')
    for x in (-W/2+0.04,W/2-0.04):
        b.box((x,-(D/2)+0.01,0.10),(0.008,0.012,H-0.22),'paint_cream')
    # proud rubber/chrome feet
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            b.tube((x,y,0.0),(x,y,0.03),0.022,0.022,sg(hi,8,12),'chrome',cap0=True,cap1=False,smooth=True)
            b.tube((x,y,0.0),(x,y,0.012),0.028,0.028,sg(hi,8,12),'rubber',cap0=True,cap1=False,smooth=True)
    cy, cz = -(D/2)+0.02, 0.46
    # chrome ring + rubber boot; the drum is a unique bake (no black glass slab in front)
    b.tube((0,cy,cz),(0,cy-0.025,cz),0.25,0.25,sg(hi,16,24),'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0,cy-0.01,cz),(0,cy-0.03,cz),0.22,0.20,sg(hi,16,24),'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0,cy-0.02,cz),(0,cy-0.035,cz),0.195,0.185,sg(hi,16,24),'rubber',cap0=False,cap1=False,smooth=True)
    # flat square card inset inside the boot so unique UVs stay a clean rectangle
    y_card=cy-0.042
    side=0.24
    if not hi:
        b.box((0,y_card,cz-side/2),(side,0.008,side),'goods')
    if hi:
        y=y_card-0.008
        b.box((0,y,cz-side/2),(side,0.004,side),'paint_cream')       # pale glass field (not a dark well)
        b.tube((0,y-0.001,cz),(0,y-0.004,cz),0.11,0.11,16,'steel',cap0=True,cap1=False,smooth=True)
        b.tube((0,y-0.002,cz),(0,y-0.005,cz),0.04,0.04,12,'chrome',cap0=True,cap1=False,smooth=True)
        for i in range(8):
            a=2*math.pi*i/8
            b.box((0.07*math.cos(a),y-0.003,cz+0.07*math.sin(a)),(0.028,0.003,0.018),'paint_cream')
        # agitator paddle (box z is BOTTOM — lift it so it is centred on the drum)
        b.box((0,y-0.003,cz-0.015),(0.16,0.004,0.03),'paint_cream')
        b.box((0,y-0.003,cz-0.08),(0.03,0.004,0.16),'paint_cream')
        b.box((-0.06,y-0.003,cz+0.04),(0.08,0.003,0.07),'plastic')  # window highlight
    # hinge (left) and latch (right)
    for z in (0.30,0.62):
        b.box((-0.27,cy-0.01,z),(0.05,0.04,0.07),'steel')
    b.box((0.26,cy-0.02,0.46),(0.06,0.03,0.06),'steel')
    b.box((0.28,cy-0.04,0.46),(0.04,0.02,0.03),'chrome')
    # detergent drawer with two compartments, slightly proud
    b.box((-0.18,-(D/2)+0.01,H-0.11),(0.26,0.10,0.06),'plastic')
    b.box((-0.24,-(D/2)-0.02,H-0.11),(0.08,0.04,0.04),'plastic')
    b.box((-0.18,-(D/2)-0.01,H-0.11),(0.01,0.03,0.04),'paint_black')  # divider
    # full-width front fascia so the console reads from the side, not a tiny top brick
    b.box((0,-(D/2)+0.03,H-0.12),(W-0.06,0.10,0.08),'paint_cream')
    b.box((0.10,-(D/2)+0.00,H-0.10),(0.36,0.08,0.06),'paint_black')
    b.tube((0.00,-(D/2)-0.02,H-0.08),(0.00,-(D/2)-0.05,H-0.08),0.024,0.024,sg(hi,8,12),'plastic_black',cap0=False,cap1=True,smooth=True)
    b.tube((0.10,-(D/2)-0.02,H-0.08),(0.10,-(D/2)-0.04,H-0.08),0.018,0.018,sg(hi,8,12),'plastic',cap0=False,cap1=True,smooth=True)
    b.box((0.22,-(D/2)-0.03,H-0.09),(0.10,0.03,0.025),'screen')
    for i,x in enumerate((0.00,0.08,0.16)):
        b.box((x+0.14,-(D/2)-0.01,H-0.13),(0.03,0.02,0.012),'plastic')
    # kick vent
    for i in range(5):
        b.box((0,-(D/2)+0.02,0.018+i*0.012),(W-0.16,0.02,0.006),'steel')
    maker_plate(b,(0.20,-(D/2)+0.03,0.16),hi,w=0.07,h=0.016)
    b.cbox((0,0,0),(W,D,H+0.04))


def dryer(b, hi=False):
    W,D,H=0.64,0.70,0.95
    _appliance_shell(b,W,D,H,hi,'paint_cream')
    # recessed side panels + a back service plate (distinct from the washer's hose)
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.010,0.0,0.16),(0.012,D-0.10,H-0.28),'paint_cream')
        b.box((x+sgn*0.004,0.0,0.16),(0.006,D-0.14,0.010),'paint_cream')
        b.box((x+sgn*0.004,0.0,H-0.20),(0.006,D-0.14,0.010),'paint_cream')
    b.box((0,D/2-0.008,0.16),(W-0.12,0.012,H-0.28),'paint_cream')
    # different from the washer: a full-width lint grill, a smaller window, hinge on the right, a single timer
    b.box((0,-(D/2)+0.01,0.10),(W-0.04,0.012,0.008),'paint_cream')
    b.box((0,-(D/2)+0.01,H-0.20),(W-0.04,0.012,0.008),'paint_cream')
    for x in (-W/2+0.04,W/2-0.04):
        b.box((x,-(D/2)+0.01,0.10),(0.008,0.012,H-0.28),'paint_cream')
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            b.tube((x,y,0.0),(x,y,0.03),0.022,0.022,sg(hi,8,12),'chrome',cap0=True,cap1=False,smooth=True)
            b.tube((x,y,0.0),(x,y,0.012),0.028,0.028,sg(hi,8,12),'rubber',cap0=True,cap1=False,smooth=True)
    cy, cz = -(D/2)+0.02, 0.50
    b.tube((0,cy,cz),(0,cy-0.025,cz),0.22,0.22,sg(hi,16,24),'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0,cy-0.01,cz),(0,cy-0.03,cz),0.19,0.17,sg(hi,16,24),'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0,cy-0.02,cz),(0,cy-0.035,cz),0.165,0.155,sg(hi,16,24),'rubber',cap0=False,cap1=False,smooth=True)
    y_card=cy-0.042
    side=0.20
    if not hi:
        b.box((0,y_card,cz-side/2),(side,0.008,side),'goods')
    if hi:
        y=y_card-0.008
        b.box((0,y,cz-side/2),(side,0.004,side),'paint_cream')
        b.tube((0,y-0.001,cz),(0,y-0.004,cz),0.09,0.09,16,'steel',cap0=True,cap1=False,smooth=True)
        for a in (0,60,120):
            b.box((0,y-0.003,cz-0.014),(0.16,0.004,0.028),'paint_cream', rz=a)
        b.tube((0,y-0.002,cz),(0,y-0.005,cz),0.028,0.028,10,'chrome',cap0=True,cap1=False,smooth=True)
        b.box((-0.04,y-0.003,cz+0.03),(0.07,0.003,0.06),'plastic')
    # hinge on the right
    for z in (0.36,0.64):
        b.box((0.25,cy-0.01,z),(0.05,0.04,0.07),'steel')
    b.box((-0.25,cy-0.02,0.50),(0.06,0.03,0.06),'steel')
    # wide lint filter under the door, with a mesh of bars
    b.box((0,cy+0.02,0.22),(0.40,0.08,0.05),'steel')
    b.box((0,cy-0.01,0.22),(0.16,0.03,0.02),'paint_black')
    for i in range(5):
        b.box((-0.14+i*0.07,cy-0.02,0.22),(0.012,0.04,0.03),'steel')
    # control: full-width front fascia, one large timer knob, a heat row of three buttons
    b.box((0,-(D/2)+0.03,H-0.12),(W-0.06,0.10,0.08),'paint_cream')
    b.box((0,-(D/2)+0.00,H-0.10),(0.44,0.08,0.06),'paint_black')
    b.tube((0,-(D/2)-0.02,H-0.08),(0,-(D/2)-0.06,H-0.08),0.032,0.032,sg(hi,10,14),'plastic_black',cap0=False,cap1=True,smooth=True)
    b.tube((0,-(D/2)-0.04,H-0.075),(0,-(D/2)-0.065,H-0.075),0.010,0.010,sg(hi,6,10),'chrome',cap0=False,cap1=True,smooth=True)  # pointer
    for x in (-0.16,0.0,0.16):
        b.box((x,-(D/2)-0.01,H-0.14),(0.06,0.03,0.016),'plastic')
    # rear vent already distinguishes the back
    b.tube((0,D/2-0.02,0.30),(0,D/2+0.05,0.30),0.04,0.04,sg(hi,10,14),'steel',cap0=False,cap1=True,smooth=True)
    b.tube((0,D/2+0.04,0.30),(0,D/2+0.06,0.30),0.05,0.05,sg(hi,10,14),'steel',cap0=True,cap1=True,smooth=True)
    for i in range(5):
        b.box((0,-(D/2)+0.02,0.018+i*0.012),(W-0.16,0.02,0.006),'steel')
    maker_plate(b,(-0.20,-(D/2)+0.03,0.16),hi,w=0.07,h=0.016)
    b.cbox((0,0,0),(W,D+0.08,H+0.04))


def garment_rail(b, hi=False):
    W,D,H=1.50,0.48,1.70
    # inverted-U ends + a lower stretcher (distinct from the arched clothes_rack)
    for x in (-W/2,W/2):
        b.tube((x,-(D/2)+0.06,0.10),(x,-(D/2)+0.06,H-0.04),0.016,0.016,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
        b.tube((x,(D/2)-0.06,0.10),(x,(D/2)-0.06,H-0.04),0.016,0.016,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
        b.tube((x,-(D/2)+0.06,H-0.04),(x,(D/2)-0.06,H-0.04),0.016,0.016,sg(hi,8,12),'chrome',cap0=False,cap1=False,smooth=True)
        b.tube((x,-(D/2)+0.06,0.28),(x,(D/2)-0.06,0.28),0.010,0.010,sg(hi,6,10),'chrome',cap0=False,cap1=False,smooth=True)
        for y in (-(D/2)+0.06,(D/2)-0.06):
            b.box((x,y,0.05),(0.03,0.02,0.06),'steel')
            b.tube((x-0.02,y,0.03),(x+0.02,y,0.03),0.024,0.024,sg(hi,8,12),'rubber',cap0=True,cap1=True,smooth=True)
    # hanging rail + lower rail
    b.tube((-W/2,0.0,H-0.08),(W/2,0.0,H-0.08),0.016,0.016,sg(hi,10,14),'chrome',cap0=True,cap1=True,smooth=True)
    b.tube((-W/2,0.0,0.28),(W/2,0.0,0.28),0.012,0.012,sg(hi,8,12),'chrome',cap0=True,cap1=True,smooth=True)
    # mid upright
    b.tube((0,0.0,0.28),(0,0.0,H-0.08),0.012,0.012,sg(hi,8,12),'chrome',cap0=False,cap1=False,smooth=True)
    # five hanging garments on hangers (real near geo, not bare rail or flat bake cards)
    bodies=('paint_navy','fabric','paint_cream','paint_black','oak')
    kinds=('shirt','jacket','shirt','trousers','jacket')
    for i,x in enumerate((-0.56,-0.28,0.0,0.28,0.56)):
        # hanger
        b.tube((x,0.0,H-0.12),(x,0.0,H-0.08),0.005,0.005,sg(hi,6,10),'steel',cap0=False,cap1=True,smooth=True)
        b.box((x,0.0,H-0.16),(0.20,0.010,0.012),'plastic')
        b.box((x,0.0,H-0.20),(0.012,0.010,0.04),'plastic')
        hanging_garment(b,(x,0.0,0.62),hi,w=0.18,h=0.78,body=bodies[i],kind=kinds[i])
        # paper ticket
        b.box((x+0.08,-0.04,H-0.22),(0.04,0.004,0.05),'paint_cream')
        b.box((x+0.08,-0.041,H-0.21),(0.03,0.003,0.012),'paint_navy')
    maker_plate(b,(0,D/2-0.08,0.32),hi,w=0.06,h=0.014,rz=180)
    b.cbox((0,0,0),(W+0.08,D+0.08,H))


# ------------------------------------------------------------------ workbench
def workbench(b, hi=False):
    W,D,H=1.60,0.70,1.50
    th=0.06
    oy=0.08
    def P(x,y,z): return (x,y+oy,z)
    b.box(P(0,0.0,0.90-th),(W,D,th),'oak')
    b.box(P(0,0.0,0.90-th-0.02),(W-0.04,D-0.04,0.02),'oak')
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            b.box(P(x,y,0.04),(0.06,0.06,0.90-th-0.04),'steel')
            b.box(P(x,y,0.04),(0.10,0.10,0.04),'steel')
            leveler(b,(x,y+oy),hi)
    b.box(P(0,0.0,0.20),(W-0.20,0.04,0.04),'steel')
    b.box(P(0,0.0,0.20),(0.04,D-0.20,0.04),'steel')
    b.box(P(0,0.0,0.24),(W-0.24,D-0.20,0.024),'oak')
    b.box(P(W/2-0.16,-(D/2)+0.08,0.90),(0.22,0.16,0.06),'steel')
    b.box(P(W/2-0.16,-(D/2)+0.02,0.94),(0.16,0.08,0.05),'steel')
    b.tube(P(W/2-0.16,-(D/2)-0.04,0.96),P(W/2-0.16,-(D/2)-0.14,0.96),0.012,0.012,sg(hi,8,12),'steel',cap0=True,cap1=True,smooth=True)
    b.box(P(W/2-0.16,-(D/2)-0.16,0.96),(0.08,0.03,0.03),'steel')
    b.box(P(0,-(D/2)+0.06,0.70),(0.40,0.08,0.12),'oak')
    b.box(P(0,-(D/2)+0.02,0.70),(0.10,0.02,0.016),'steel')
    b.box(P(0,D/2-0.02,0.90),(W-0.10,0.024,0.58),'paint_cream')
    for x in (-0.50,-0.20,0.10,0.40):
        for z in (1.10,1.30):
            b.tube(P(x,D/2-0.04,z),P(x,D/2-0.12,z),0.006,0.006,sg(hi,6,8),'steel',cap0=True,cap1=True,smooth=True)
    for x in (-W/2+0.12,W/2-0.12):
        b.box(P(x,D/2+0.01,1.00),(0.06,0.012,0.06),'steel')
        b.box(P(x,D/2+0.01,1.40),(0.06,0.012,0.06),'steel')
    # tools hung on the back board: hammer, two spanners, hand saw, screwdrivers, tape measure, and a
    # few items on the bench top (toolbox, mallet, coffee tin of pencils)
    yb=D/2-0.06
    b.tube(P(-0.50,yb,1.02),P(-0.50,yb,1.30),0.013,0.013,6,'walnut',cap0=True,cap1=True)
    b.box(P(-0.50,yb,1.30),(0.12,0.03,0.035),'steel')
    for k,x in enumerate((-0.30,-0.25)):
        b.box(P(x,yb,1.06+k*0.02),(0.025,0.012,0.24-k*0.04),'chrome')
        b.box(P(x,yb,1.28),(0.045,0.012,0.04),'chrome')
    b.prism([(-0.05,1.04),(0.20,1.04),(0.20,1.12),(0.02,1.16),(-0.05,1.16)],P(0,yb,0)[1]-0.003,P(0,yb,0)[1]+0.003,'steel')
    b.box(P(-0.08,yb,1.08),(0.07,0.03,0.10),'paint_red')
    for k in range(3):
        b.tube(P(0.30+k*0.05,yb,1.10),P(0.30+k*0.05,yb,1.20),0.009,0.009,5,('paint_yellow','paint_red','paint_black')[k],cap0=True,cap1=False)
        b.tube(P(0.30+k*0.05,yb,1.02),P(0.30+k*0.05,yb,1.10),0.003,0.003,4,'chrome',cap0=True,cap1=False)
    b.tube(P(0.52,yb,1.24),P(0.52,yb-0.04,1.24),0.04,0.04,8,'paint_yellow',cap0=True,cap1=True)
    b.box(P(-0.45,0.05,0.90),(0.40,0.20,0.16),'paint_red')
    b.box(P(-0.45,0.05,1.06),(0.36,0.18,0.02),'paint_red'); b.box(P(-0.45,0.05,1.08),(0.18,0.02,0.03),'paint_black')
    b.tube(P(0.20,0.10,0.90),P(0.20,0.10,1.00),0.04,0.04,8,'steel',cap0=False,cap1=False)
    maker_plate(b,P(0,-(D/2)+0.04,0.50),hi,w=0.07,h=0.016)
    b.cbox((0,0,0),(W,D+0.16,H))


def laundry_counter(b, hi=False):
    W,D,H=1.80,0.70,1.10
    th=0.036
    b.box((0,0.0,0.92-th),(W,D,th),'lam')
    b.box((0,-(D/2)+0.012,0.92-th-0.006),(W-0.04,0.022,0.014),'lam')
    # oak backsplash / header, small brass nameplate, folded laundry — no placeholder letter bar
    b.box((0,0.04,0.92),(W-0.24,0.12,0.16),'oak')
    b.box((0.0,-(D/2)+0.08,1.00),(0.40,0.010,0.07),'brass')
    b.box((0.0,-(D/2)+0.076,1.00),(0.34,0.006,0.05),'paint_cream')
    if not hi:
        b.box((0.0,-(D/2)+0.072,1.00),(0.30,0.003,0.036),'label')
    else:
        for i,x in enumerate((-0.11,-0.055,0.0,0.055,0.11)):
            b.box((x,-(D/2)+0.072,1.005),(0.04,0.003,0.018),'paint_navy')
    # folded towel stacks on the header (cloth, not blue blocks)
    for x in (-0.62,0.62):
        b.box((x,0.02,0.92),(0.22,0.16,0.03),'fabric')
        b.box((x,0.00,0.95),(0.20,0.14,0.025),'paint_cream')
        b.box((x,0.02,0.975),(0.18,0.13,0.02),'fabric')
    # body
    b.box((0,0.04,0.10),(W-0.08,D-0.10,0.92-th-0.12),'paint_cream',skip=('bottom',))
    b.box((0,0.04,0.0),(W-0.06,D-0.16,0.10),'paint_black',skip=('bottom',))
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.03,0.0,0.0),(0.06,D,0.92-0.02),'oak',skip=('bottom',))
    # drop-off slot in the countertop, rimmed, not a missing front panel
    b.box((-0.50,0.04,0.92),(0.50,0.28,0.02),'oak')   # raised rim
    b.box((-0.50,0.04,0.92-th-0.02),(0.42,0.22,0.02),'paint_black')  # well floor, recessed
    # a folded drop-off bag sitting in the well
    b.box((-0.50,0.04,0.92-th),(0.28,0.16,0.05),'paint_navy')
    b.box((-0.50,0.02,0.92-th+0.05),(0.24,0.14,0.03),'paint_cream')
    # hanging ticket rail
    b.tube((-0.10,-(D/2)+0.02,0.88),(0.60,-(D/2)+0.02,0.88),0.007,0.007,sg(hi,6,10),'chrome',cap0=True,cap1=True,smooth=True)
    for x in (0.00,0.20,0.40):
        b.box((x,-(D/2)+0.02,0.82),(0.04,0.002,0.06),'label')
    # scale platter on the right
    b.box((0.60,-(D/2)+0.20,0.92),(0.28,0.28,0.02),'steel')
    b.box((0.60,-(D/2)+0.20,0.94),(0.22,0.22,0.012),'steel')
    # framed front: oak stiles/rails and inset cream panels (not placeholder blocks)
    b.box((0,-(D/2)+0.05,0.14),(0.05,0.04,0.70),'oak')
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.10,-(D/2)+0.04,0.14),(0.05,0.04,0.70),'oak')
    b.box((0,-(D/2)+0.04,0.14),(W-0.20,0.04,0.05),'oak')
    b.box((0,-(D/2)+0.04,0.78),(W-0.20,0.04,0.05),'oak')
    b.box((0,-(D/2)+0.04,0.46),(W-0.20,0.04,0.04),'oak')
    for x,z in ((-0.48,0.22),(-0.48,0.52),(0.48,0.22),(0.48,0.52)):
        b.box((x,-(D/2)+0.03,z),(0.70,0.018,0.22),'lam')
        b.box((x,-(D/2)+0.02,z+0.02),(0.62,0.014,0.18),'paint_cream')
    b.box((0,-(D/2)+0.02,0.46),(W-0.22,0.016,0.016),'brass')
    # staff drawers
    for x in (-0.30,0.30):
        b.box((x,(D/2)-0.04,0.30),(0.36,0.04,0.16),'oak')
        b.box((x,(D/2)-0.02,0.30),(0.08,0.02,0.016),'brass')
    maker_plate(b,(0.70,-(D/2)+0.03,0.20),hi,w=0.07,h=0.016)
    for x in (-W/2+0.12,W/2-0.12):
        for y in (-D/2+0.12,D/2-0.10):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))



# ------------------------------------------------------------------ pegboard_wall
def pegboard_wall(b, hi=False):
    W,D,H=1.20,0.22,2.00
    # frame + wall flanges (rails meet the wall)
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.03,0.0,0.08),(0.06,D,H-0.16),'oak',skip=('bottom',))
        b.box((x+sgn*0.03,D/2+0.008,0.16),(0.08,0.012,0.08),'steel')
        b.box((x+sgn*0.03,D/2+0.008,H-0.18),(0.08,0.012,0.08),'steel')
    b.box((0,0.0,0.0),(W,D,0.10),'oak',skip=('bottom',))
    b.box((0,0.0,H-0.08),(W,D,0.08),'oak')
    b.box((0,-0.01,H-0.12),(W+0.02,D+0.02,0.04),'oak')
    # pegboard field
    b.box((0,D/2-0.04,0.10),(W-0.12,0.03,H-0.22),'paint_cream')
    # perforation: a regular grid of dark single-quad holes (2 tris each) on the board face
    yb=D/2-0.04-0.015-0.0008
    nr,nc=9,11
    for r in range(nr):
        for c in range(nc):
            x=-0.52+c*(1.04/(nc-1)); z=0.36+r*((H-0.52-0.36)/(nr-1)); h=0.005
            b.quad([(x-h,yb,z-h),(x+h,yb,z-h),(x+h,yb,z+h),(x-h,yb,z+h)],'paint_black')
    # merchandise: 3 rows x 5 hooks, each a stack of blister cards (card, clear bubble, hang-tab header)
    cols=('paint_red','paint_navy','paint_yellow','paint_green','paint_orange','paint_purple','paint_grey')
    rows=((1.50,0.09,0.13,0.05),(1.08,0.11,0.18,0.06),(0.62,0.13,0.22,0.07))   # hook z, card w, card h, stack depth
    yf=D/2-0.055
    for ri,(z,cw,chh,sd) in enumerate(rows):
        for ci in range(5):
            x=-0.44+ci*0.22
            b.tube((x,yf,z),(x,yf-0.17,z+0.012),0.0045,0.0045,sg(hi,4,8),'chrome',cap0=False,cap1=True,smooth=True)
            k=cols[(ri*5+ci*3)%len(cols)]
            y0=yf-0.02-sd/2
            b.box((x,y0,z-chh+0.015),(cw,sd,chh),k)
            b.box((x,y0-sd/2-0.002,z-0.012),(cw,0.004,0.03),'paint_white')                 # hang-tab header
            b.box((x,y0-sd/2-0.012,z-chh+0.04),(cw*0.62,0.022,chh*0.55),'plastic')   # blister bubble
    # lower shelf
    b.box((0,0.0,0.28),(W-0.14,D-0.04,0.020),'oak')
    maker_plate(b,(0,-(D/2)+0.04,0.14),hi,w=0.07,h=0.014)
    b.cbox((0,0,0),(W,D+0.04,H))


_C=dict(dir='props/indoor/services',pdir='indoor_services',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('washer',washer,'medium',1100,side=96,cage=0.04,ray=0.12),
    _p('dryer',dryer,'medium',1100,side=96,cage=0.04,ray=0.12),
    _p('garment_rail',garment_rail,'medium',1100,side=96,cage=0.04,ray=0.12),
    _p('workbench',workbench,'medium',1100),
    _p('laundry_counter',laundry_counter,'medium',1200,side=64),
    _p('pegboard_wall',pegboard_wall,'medium',1200,side=96,cage=0.04,ray=0.12),
]

INDOOR_LOOK=True   # run.py: chamfer edge highlight + per-part colour variation in COLOR_0
