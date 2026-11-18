"""Indoor services props — original geometry, page I, near+col only.

washer, dryer, garment_rail, workbench, laundry_counter.
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT,
)

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
        b.box((0,y,cz-side/2),(side,0.004,side),'plastic')          # pale glass field
        b.tube((0,y-0.001,cz),(0,y-0.004,cz),0.11,0.11,16,'steel',cap0=True,cap1=False,smooth=True)
        b.tube((0,y-0.002,cz),(0,y-0.005,cz),0.04,0.04,12,'chrome',cap0=True,cap1=False,smooth=True)
        for i in range(8):
            a=2*math.pi*i/8
            b.box((0.07*math.cos(a),y-0.003,cz+0.07*math.sin(a)),(0.02,0.003,0.02),'paint_black')
        # agitator paddle (box z is BOTTOM — lift it so it is centred on the drum)
        b.box((0,y-0.003,cz-0.015),(0.16,0.004,0.03),'paint_cream')
        b.box((0,y-0.003,cz-0.08),(0.03,0.004,0.16),'paint_cream')
        b.box((-0.06,y-0.003,cz+0.02),(0.08,0.003,0.06),'paint_cream')  # window highlight
    # hinge (left) and latch (right)
    for z in (0.30,0.62):
        b.box((-0.27,cy-0.01,z),(0.05,0.04,0.07),'steel')
    b.box((0.26,cy-0.02,0.46),(0.06,0.03,0.06),'steel')
    b.box((0.28,cy-0.04,0.46),(0.04,0.02,0.03),'chrome')
    # detergent drawer with two compartments, slightly proud
    b.box((-0.18,-(D/2)+0.01,H-0.11),(0.26,0.10,0.06),'plastic')
    b.box((-0.24,-(D/2)-0.02,H-0.11),(0.08,0.04,0.04),'plastic')
    b.box((-0.18,-(D/2)-0.01,H-0.11),(0.01,0.03,0.04),'paint_black')  # divider
    # top console: bezel, two knobs, a display and three buttons
    b.box((0.16,-(D/2)+0.05,H-0.03),(0.30,0.16,0.05),'paint_black')
    b.box((0.16,-(D/2)+0.02,H-0.01),(0.26,0.12,0.03),'paint_black')
    b.tube((0.06,-(D/2)+0.00,H+0.01),(0.06,-(D/2)-0.025,H+0.01),0.024,0.024,sg(hi,8,12),'plastic_black',cap0=False,cap1=True,smooth=True)
    b.tube((0.16,-(D/2)+0.00,H+0.01),(0.16,-(D/2)-0.02,H+0.01),0.018,0.018,sg(hi,8,12),'plastic',cap0=False,cap1=True,smooth=True)
    b.box((0.26,-(D/2)-0.01,H+0.00),(0.10,0.03,0.025),'screen')
    for i,x in enumerate((0.08,0.16,0.24)):
        b.box((x+0.10,-(D/2)+0.02,H-0.04),(0.03,0.02,0.012),'plastic')
    # kick vent
    for i in range(5):
        b.box((0,-(D/2)+0.02,0.018+i*0.012),(W-0.16,0.02,0.006),'steel')
    maker_plate(b,(0.20,-(D/2)+0.03,0.16),hi,w=0.07,h=0.016)
    b.cbox((0,0,0),(W,D,H+0.04))


def dryer(b, hi=False):
    W,D,H=0.64,0.70,0.95
    _appliance_shell(b,W,D,H,hi,'paint_cream')
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
        b.box((0,y,cz-side/2),(side,0.004,side),'plastic')
        b.tube((0,y-0.001,cz),(0,y-0.004,cz),0.09,0.09,16,'steel',cap0=True,cap1=False,smooth=True)
        for a in (0,60,120):
            b.box((0,y-0.003,cz-0.014),(0.16,0.004,0.028),'paint_cream', rz=a)
        b.tube((0,y-0.002,cz),(0,y-0.005,cz),0.028,0.028,10,'chrome',cap0=True,cap1=False,smooth=True)
        b.box((-0.04,y-0.003,cz+0.02),(0.07,0.003,0.05),'paint_cream')
    # hinge on the right
    for z in (0.36,0.64):
        b.box((0.25,cy-0.01,z),(0.05,0.04,0.07),'steel')
    b.box((-0.25,cy-0.02,0.50),(0.06,0.03,0.06),'steel')
    # wide lint filter under the door, with a mesh of bars
    b.box((0,cy+0.02,0.22),(0.40,0.08,0.05),'steel')
    b.box((0,cy-0.01,0.22),(0.16,0.03,0.02),'paint_black')
    for i in range(5):
        b.box((-0.14+i*0.07,cy-0.02,0.22),(0.012,0.04,0.03),'steel')
    # control: one large timer knob, a heat row of three buttons, no detergent drawer
    b.box((0,-(D/2)+0.05,H-0.03),(0.44,0.16,0.05),'paint_black')
    b.tube((0,-(D/2)+0.00,H+0.01),(0,-(D/2)-0.035,H+0.01),0.032,0.032,sg(hi,10,14),'plastic_black',cap0=False,cap1=True,smooth=True)
    b.tube((0,-(D/2)-0.02,H+0.015),(0,-(D/2)-0.04,H+0.015),0.010,0.010,sg(hi,6,10),'chrome',cap0=False,cap1=True,smooth=True)  # pointer
    for x in (-0.16,0.0,0.16):
        b.box((x,-(D/2)+0.02,H-0.05),(0.06,0.03,0.016),'plastic')
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
    # five dry-cleaning bags on hangers (garment + plastic bag)
    bodies=('paint_navy','fabric','paint_cream','paint_black','oak')
    for i,x in enumerate((-0.56,-0.28,0.0,0.28,0.56)):
        b.box((x,0.0,H-0.16),(0.20,0.010,0.012),'plastic')
        b.tube((x,0.0,H-0.12),(x,0.0,H-0.08),0.005,0.005,sg(hi,6,10),'steel',cap0=False,cap1=True,smooth=True)
        # bag + garment face the FRONT (-Y). The unique card IS the bag face.
        # (A plastic shell in front of the bake would hide the clothes.)
        if not hi:
            b.box((x,-0.04,0.55),(0.20,0.008,0.90),'goods')
        if hi:
            from b_inclothing import garment_card
            # frosted-bag field, then the garment slightly in front for the bake
            b.box((x,-0.046,0.55),(0.22,0.004,0.92),'plastic')
            b.box((x,-0.046,1.36),(0.24,0.004,0.12),'plastic')
            garment_card(b,(x,-0.052,0.62),h=0.70,w=0.16,body=bodies[i%len(bodies)])
        # paper ticket as cream geo (not a black unbaked label island)
        b.box((x+0.08,-0.05,H-0.22),(0.04,0.004,0.05),'paint_cream')
        b.box((x+0.08,-0.051,H-0.21),(0.03,0.003,0.012),'paint_navy')
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
    maker_plate(b,P(0,-(D/2)+0.04,0.50),hi,w=0.07,h=0.016)
    b.cbox((0,0,0),(W,D+0.16,H))


def laundry_counter(b, hi=False):
    W,D,H=1.80,0.70,1.10
    th=0.036
    b.box((0,0.0,0.92-th),(W,D,th),'lam')
    b.box((0,-(D/2)+0.012,0.92-th-0.006),(W-0.04,0.022,0.014),'lam')
    # header / sign board with typography in the bake
    b.box((0,0.04,0.92),(W-0.24,0.12,0.16),'oak')
    # sign board: typography is real geo, so it cannot collapse to a black bake island
    b.box((0,-(D/2)+0.08,0.94),(W-0.36,0.04,0.12),'paint_navy')
    # "CLEANERS" as a row of cream bars plus a gold rule
    b.box((0,-(D/2)+0.06,1.015),(W-0.50,0.008,0.018),'paint_cream')
    for i,x in enumerate((-0.52,-0.36,-0.20,-0.04,0.12,0.28,0.44)):
        w=0.08 if i not in (2,3) else 0.10
        b.box((x,-(D/2)+0.06,0.97),(w,0.008,0.028),'paint_cream')
    b.box((0,-(D/2)+0.06,0.955),(W-0.56,0.008,0.006),'brass')
    # body
    b.box((0,0.04,0.10),(W-0.08,D-0.10,0.92-th-0.12),'paint_cream',skip=('bottom',))
    b.box((0,0.04,0.0),(W-0.06,D-0.16,0.10),'paint_black',skip=('bottom',))
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.03,0.0,0.0),(0.06,D,0.92-0.02),'oak',skip=('bottom',))
    # drop-off well / bag slot on the left
    b.box((-0.45,-(D/2)+0.16,0.92-th-0.16),(0.55,0.36,0.16),'oak')
    b.box((-0.45,-(D/2)+0.16,0.92-th-0.16),(0.45,0.28,0.12),'paint_black')
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
    # hole dimples — boxes, not tubes, and a sparse near grid so we stay under budget
    rows=5 if not hi else 9
    cols=6 if not hi else 10
    for r in range(rows):
        for c in range(cols):
            x=-0.45+c*(0.90/(cols-1))
            z=0.24+r*((H-0.40)/(rows-1))
            b.box((x,D/2-0.055,z),(0.012,0.008,0.012),'paint_black')
    # hanging hooks + baked merch (tools / packaged goods)
    for i,x in enumerate((-0.40,-0.15,0.15,0.40)):
        z=1.20
        b.tube((x,D/2-0.06,z),(x,D/2-0.16,z),0.007,0.007,sg(hi,6,10),'steel',cap0=True,cap1=True,smooth=True)
        b.tube((x,D/2-0.16,z),(x,D/2-0.16,z-0.06),0.007,0.007,sg(hi,6,10),'steel',cap0=False,cap1=True,smooth=True)
        if not hi:
            b.box((x,D/2-0.18,z-0.28),(0.10,0.008,0.36),'goods')
        if hi:
            bodies=('steel','paint_navy','oak','plastic_black')
            b.box((x,D/2-0.18-0.006,z-0.30),(0.08,0.004,0.32),bodies[i%4])
            b.box((x,D/2-0.19,z-0.12),(0.05,0.003,0.06),'label')
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
    _p('pegboard_wall',pegboard_wall,'medium',1100,side=96,cage=0.04,ray=0.12),
]
