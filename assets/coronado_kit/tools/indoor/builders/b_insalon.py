"""Indoor salon props — original geometry, page I, near+col only.

barber_chair, mirror_station, nail_table, salon_product_shelf, wash_basin.
Chairs get collision. Unique merch in the bake; no unique card on high;
silhouettes inside the cage. Delete stale _bake/tiles/<name>_* after geo changes.
"""
import math
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT, stock,
)

def salon_bottle(b, c, hi=False, h=0.16, body='paint_navy', cap='paint_cream', kind='pump'):
    """Low-poly bottle or jar that sits on a shelf (near + high). Boxes, not tubes, to stay in budget."""
    x,y,z=c
    if kind=='jar':
        b.box((x,y,z),(0.048,0.048,h*0.80),body)
        b.box((x,y,z+h*0.80),(0.038,0.038,h*0.20),cap)
    else:
        b.box((x,y,z),(0.040,0.040,h*0.58),body)
        b.box((x,y,z+h*0.58),(0.022,0.022,h*0.20),body)
        b.box((x,y,z+h*0.78),(0.024,0.024,h*0.22),cap)
    # no separate label card — body/cap colour has to carry the merch at this budget


# ------------------------------------------------------------------ barber_chair
def barber_chair(b, hi=False):
    H=1.15
    seg=sg(hi,12,18)
    # footrest and pump lever pull the footprint; shift so origin stays centred
    ox,oy=-0.04,0.12
    def P(x,y,z): return (x+ox,y+oy,z)
    # white enamel bell base on a chrome foot ring + rubber-gaitered hydraulic column + pump pedal
    b.tube(P(0,0,0.0),P(0,0,0.03),0.28,0.28,seg,'chrome',cap0=True,cap1=False,smooth=True)
    b.tube(P(0,0,0.03),P(0,0,0.12),0.27,0.16,seg,'paint_white',cap0=False,cap1=True,smooth=True)
    b.tube(P(0,0,0.12),P(0,0,0.42),0.05,0.05,sg(hi,8,14),'chrome',cap0=False,cap1=False,smooth=True)
    for z in (0.16,0.25):
        b.tube(P(0,0,z),P(0,0,z+0.05),0.068,0.068,sg(hi,8,14),'rubber',cap0=False,cap1=True,smooth=True)
    b.tube(P(0.10,0.0,0.10),P(0.30,-0.06,0.07),0.012,0.012,sg(hi,5,10),'chrome',cap0=True,cap1=False,smooth=True)
    b.box(P(0.33,-0.07,0.05),(0.10,0.05,0.022),'rubber',ch=0.006)
    # seat: chrome-banded pan + chamfered black vinyl cushion with a waterfall front roll
    b.box(P(0,0.02,0.42),(0.52,0.44,0.05),'chrome',ch=0.015)
    b.box(P(0,0.01,0.47),(0.50,0.42,0.08),'vinyl',ch=0.025)
    b.tube(P(-0.24,-0.20,0.51),P(0.24,-0.20,0.51),0.04,0.04,sg(hi,6,12),'vinyl',cap0=True,cap1=True,smooth=True)
    # curved, raked back: chrome-edged shell (outside) + vinyl pad (inside), channel rolls
    from b_inshared import arc_slab
    arc_slab(b,(ox,-0.52+oy),0.76,107,73,0.56,1.04,0.05,'paint_white',seg=sg(hi,4,10))
    arc_slab(b,(ox,-0.52+oy),0.712,105,75,0.58,1.02,0.04,'vinyl',seg=sg(hi,4,10))
    for z in (0.68,0.80,0.92):
        b.tube(P(-0.17,0.145,z),P(0.17,0.145,z),0.02,0.02,sg(hi,5,10),'vinyl',cap0=True,cap1=True,smooth=True)
    b.box(P(0,0.24,1.04),(0.42,0.04,0.02),'chrome',ch=0.008)
    # adjustable headrest: chrome stem + rounded vinyl bolster
    b.tube(P(0,0.22,1.04),P(0,0.20,1.16),0.012,0.012,sg(hi,6,10),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube(P(-0.12,0.17,1.20),P(0.12,0.17,1.20),0.055,0.055,sg(hi,8,14),'vinyl',cap0=True,cap1=True,smooth=True)
    # arms: chrome sweep + vinyl pad with chrome end caps
    for sgn in (-1,1):
        x=sgn*0.29
        b.tube(P(x,0.18,0.47),P(x,0.16,0.80),0.016,0.016,sg(hi,6,12),'chrome',cap0=True,cap1=True,smooth=True)
        b.tube(P(x,-0.16,0.47),P(x,-0.18,0.78),0.016,0.016,sg(hi,6,12),'chrome',cap0=True,cap1=True,smooth=True)
        b.box(P(x,-0.01,0.78),(0.075,0.44,0.05),'vinyl',ch=0.02)
        b.box(P(x,-0.24,0.775),(0.08,0.02,0.055),'chrome',ch=0.006)
    # Chrome collar clamped to the hydraulic column just under the seat.
    # The footrest hangs off this collar, so column and footrest read as one mechanism.
    b.tube(P(0,0,0.33),P(0,0,0.42),0.078,0.078,sg(hi,12,16),'chrome',cap0=True,cap1=True,smooth=True)
    b.tube(P(0,0,0.35),P(0,0,0.40),0.090,0.090,sg(hi,12,16),'chrome',cap0=True,cap1=True,smooth=True)
    # Circular footring around the column (classic barber chair)
    rr, rz = 0.17, 0.20
    nring=0
    for i in range(nring):
        a0=2*math.pi*i/nring; a1=2*math.pi*(i+1)/nring
        b.tube(P(rr*math.cos(a0),rr*math.sin(a0),rz),
               P(rr*math.cos(a1),rr*math.sin(a1),rz),
               0.012,0.012,sg(hi,6,8),'chrome',cap0=False,cap1=False,smooth=True)
    for i in range(0):
        a=2*math.pi*i/4 + math.pi/4
        b.tube(P(0.08*math.cos(a),0.08*math.sin(a),0.22),
               P(rr*math.cos(a),rr*math.sin(a),rz),
               0.008,0.008,sg(hi,6,8),'chrome',cap0=True,cap1=True,smooth=True)
    # Heavy chrome arms from the collar forward and down to the footrest
    b.tube(P(-0.06,-0.07,0.37),P(-0.11,-0.48,0.30),0.018,0.015,sg(hi,8,12),'chrome',cap0=True,cap1=True,smooth=True)
    b.tube(P( 0.06,-0.07,0.37),P( 0.11,-0.48,0.30),0.018,0.015,sg(hi,8,12),'chrome',cap0=True,cap1=True,smooth=True)
    b.box(P(0,-0.50,0.27),(0.38,0.16,0.045),'chrome')
    b.box(P(0,-0.50,0.31),(0.34,0.13,0.03),'paint_black')
    maker_plate(b,P(0,0.27,0.75),hi,w=0.06,h=0.014,rz=180)
    b.cbox((0,0,0),(0.70,1.10,H+0.10))


def mirror_station(b, hi=False):
    W,D,H=1.20,0.42,2.05
    # vanity counter
    b.box((0,0.0,0.0),(W,D,0.10),'paint_cream',skip=('bottom',))
    b.box((0,0.0,0.10),(W-0.06,D-0.06,0.68),'paint_cream',skip=('bottom',))
    b.box((0,0.0,0.78),(W,D,0.04),'lam')
    # front drawers
    for x in (-0.32,0.32):
        b.box((x,-(D/2)+0.03,0.22),(0.50,0.03,0.22),'oak')
        b.box((x,-(D/2)+0.01,0.22),(0.10,0.02,0.018),'brass')
        b.box((x,-(D/2)+0.03,0.50),(0.50,0.03,0.20),'oak')
        b.box((x,-(D/2)+0.01,0.50),(0.10,0.02,0.018),'brass')
    b.box((0,-(D/2)+0.03,0.10),(W-0.10,0.02,0.08),'paint_black')  # kick
    # backsplash
    b.box((0,D/2-0.03,0.82),(W,0.06,0.12),'lam')
    # hollow oak frame — stiles and rails only, never a slab in front of the glass
    fw,fd=0.06,0.05
    yf=D/2-0.04
    b.box((-(W/2)+fw/2,yf,0.94),(fw,fd,H-0.94-0.06),'oak')
    b.box(((W/2)-fw/2,yf,0.94),(fw,fd,H-0.94-0.06),'oak')
    b.box((0,yf,0.94),(W-0.04,fd,fw),'oak')
    b.box((0,yf,H-0.06-fw),(W-0.04,fd,fw),'oak')
    # inner rebate (still frame, not a fill)
    b.box((0,yf-0.008,0.94+fw-0.01),(W-2*fw+0.02,0.02,0.016),'oak')
    b.box((0,yf-0.008,H-0.06-fw-0.006),(W-2*fw+0.02,0.02,0.016),'oak')
    # thin backer behind the opening only, so the sides stay oak and the glass is free
    b.box((0,yf+fd/2-0.004,0.94+fw),(W-2*fw,0.008,H-0.94-0.06-2*fw),'paint_cream')
    # reflection card is the FRONT face of the opening (box z is the BOTTOM)
    y_m=yf-fd/2-0.008
    z0=0.94+fw+0.01
    mh=H-0.94-0.06-2*fw-0.02
    mw=W-2*fw-0.04
    if not hi:
        b.box((0,y_m,z0),(mw,0.008,mh),'mirror')
    if hi:
        y=y_m-0.008
        # bright salon reflection — light wall, a window, a light floor; never a black void
        b.box((0,y,z0),(mw-0.02,0.004,mh),'paint_cream')
        b.box((0,y-0.001,z0),(mw-0.02,0.004,mh*0.20),'lam')              # floor
        b.box((0,y-0.001,z0+mh*0.52),(mw*0.62,0.004,mh*0.34),'steel')   # window field
        b.box((0,y-0.002,z0+mh*0.54),(mw*0.56,0.003,mh*0.30),'plastic') # bright sky
        # muntins
        b.box((0,y-0.003,z0+mh*0.68),(mw*0.56,0.003,0.012),'paint_cream')
        b.box((0,y-0.003,z0+mh*0.52),(0.012,0.003,mh*0.34),'paint_cream')
        # soft mid-room silhouette (chair), mid-light, not a black slab
        b.box((0.16,y-0.002,z0+mh*0.20),(0.16,0.003,mh*0.22),'plastic')
        b.box((0.16,y-0.002,z0+mh*0.36),(0.12,0.003,0.06),'plastic')
        # bulb glints along the top
        for x in (-0.42,-0.21,0.0,0.21,0.42):
            b.box((x,y-0.002,z0+mh-0.08),(0.06,0.003,0.06),'paint_cream')
    # Hollywood bulbs around the frame (front-facing)
    bulbs=[]
    # top row
    for i in range(6):
        bulbs.append((-0.48+i*0.19, -(0.0)+ (D/2)-0.08, H-0.10))
    # sides
    for z in (1.15,1.40,1.65):
        bulbs.append((-W/2+0.06, D/2-0.08, z))
        bulbs.append(( W/2-0.06, D/2-0.08, z))
    for x,y,z in bulbs:
        b.tube((x,y,z),(x,y-0.03,z),0.022,0.022,sg(hi,8,12),'paint_cream',cap0=False,cap1=True,smooth=True)
        b.tube((x,y,z),(x,y+0.01,z),0.012,0.012,sg(hi,6,10),'brass',cap0=True,cap1=False,smooth=True)
    # product shelf under the mirror / on the counter back — bottles stay below the glass
    b.box((0,D/2-0.14,0.82),(W-0.20,0.16,0.018),'oak')
    bodies=('paint_navy','paint_cream','leaf','brass','plastic','paint_black')
    for i in range(4):
        salon_bottle(b,(-0.30+i*0.20, D/2-0.20, 0.838), hi, h=0.14,
                     body=bodies[i%len(bodies)], cap='paint_cream',
                     kind='jar' if i%2 else 'pump')
    # wall flanges on the back of the mirror
    for x in (-W/2+0.10,W/2-0.10):
        for z in (1.10,H-0.12):
            b.box((x,D/2+0.01,z),(0.06,0.012,0.06),'steel')
    for x in (-W/2+0.10,W/2-0.10):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    maker_plate(b,(0,-(D/2)+0.03,0.16),hi,w=0.07,h=0.016)
    b.cbox((0,0,0),(W,D+0.06,H))


# ------------------------------------------------------------------ nail_table
def nail_table(b, hi=False):
    W,D,H=1.10,0.62,0.78
    th=0.036
    # top + bullnose
    b.box((0,0.0,H-th),(W,D,th),'lam')
    b.box((0,-(D/2)+0.012,H-th-0.006),(W-0.04,0.022,0.014),'lam')
    # body + kick
    b.box((0,0.04,0.10),(W-0.08,D-0.12,H-th-0.12),'paint_cream',skip=('bottom',))
    b.box((0,0.04,0.0),(W-0.06,D-0.16,0.10),'paint_black',skip=('bottom',))
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.03,0.0,0.0),(0.06,D,H-0.02),'oak',skip=('bottom',))
    # two drawers on the technician side (+Y)
    for x in (-0.28,0.28):
        b.box((x,(D/2)-0.03,0.28),(0.42,0.04,0.16),'oak')
        b.box((x,(D/2)-0.01,0.28),(0.08,0.02,0.016),'brass')
    # padded hand rest at the customer edge
    b.box((0,-(D/2)+0.14,H),(0.36,0.16,0.06),'fabric')
    b.box((0,-(D/2)+0.14,H-0.01),(0.38,0.18,0.02),'paint_black')
    # bottle rack at the back of the top
    b.box((0,D/2-0.12,H),(0.70,0.16,0.04),'oak')
    stock(b,-0.33,0.33,D/2-0.17,H+0.04,0.12,'tg_bottles',depth=0.10,hi=hi)
    # articulated lamp
    b.tube((0.40,D/2-0.10,H),(0.40,D/2-0.10,H+0.28),0.012,0.012,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube((0.40,D/2-0.10,H+0.28),(0.10,-(D/2)+0.16,H+0.34),0.010,0.010,sg(hi,8,12),'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0.10,-(D/2)+0.16,H+0.34),(0.10,-(D/2)+0.16,H+0.22),0.010,0.010,sg(hi,6,10),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube((0.10,-(D/2)+0.16,H+0.22),(0.10,-(D/2)+0.16,H+0.16),0.06,0.07,sg(hi,10,14),'paint_cream',cap0=False,cap1=True,smooth=True)  # shade
    # towel cubby / vent on the front
    b.box((0,-(D/2)+0.03,0.30),(0.28,0.04,0.16),'paint_navy')
    b.box((0,-(D/2)+0.01,0.30),(0.22,0.02,0.10),'paint_black')
    maker_plate(b,(0.40,-(D/2)+0.03,0.18),hi,w=0.06,h=0.014)
    for x in (-W/2+0.10,W/2-0.10):
        for y in (-D/2+0.10,D/2-0.10):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H+0.36))


# ------------------------------------------------------------------ salon_product_shelf
def salon_product_shelf(b, hi=False):
    W,D,H=1.00,0.36,2.00
    # thicker end panels so the sides read as a cabinet, not a wafer
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.03,0.0,0.08),(0.06,D,H-0.16),'oak',skip=('bottom',))
        b.box((x+sgn*0.01,-(D/2)+0.02,0.16),(0.02,0.02,H-0.28),'oak')  # front stile
        b.box((x+sgn*0.03,D/2+0.008,0.16),(0.08,0.012,0.08),'steel')
        b.box((x+sgn*0.03,D/2+0.008,H-0.18),(0.08,0.012,0.08),'steel')
    # solid back + a recessed fascia (not a bare cream slab)
    b.box((0,D/2-0.02,0.08),(W-0.08,0.04,H-0.16),'oak')
    b.box((0,D/2-0.04,0.16),(W-0.16,0.02,H-0.28),'paint_cream')
    b.box((0,0.0,0.0),(W,D,0.10),'oak',skip=('bottom',))
    b.box((0,0.0,H-0.08),(W,D,0.08),'oak')
    b.box((0,-0.01,H-0.12),(W+0.02,D+0.02,0.04),'oak')
    # mid upright + lower cupboard
    b.box((0,0.0,0.10),(0.028,D-0.04,H-0.22),'oak')
    b.box((0,-(D/2)+0.03,0.12),(W-0.14,0.03,0.22),'oak')
    b.box((0,-(D/2)+0.01,0.18),(0.08,0.02,0.016),'brass')
    zs=(0.36,0.70,1.04,1.38,1.70)
    bodies=('paint_navy','paint_cream','leaf','brass','plastic','paint_black','oak')
    caps=('paint_cream','brass','paint_cream','plastic','paint_cream','brass','paint_cream')
    for row,z in enumerate(zs):
        b.box((0,-0.01,z),(W-0.06,D-0.04,0.016),'oak')
        b.box((0,-(D/2)+0.016,z-0.014),(W-0.10,0.012,0.018),'plastic')
        # stocked bays: shampoo / tonic facings (page-I bottle band), plus one modelled hero pump per bay
        # at eye level so the silhouette breaks the front plane
        for k,(x0,x1) in enumerate(((-W/2+0.065,-0.018),(0.018,W/2-0.065))):
            stock(b,x0,x1,-(D/2)+0.07+0.012*((row+k)%2),z+0.016,0.24 if row<4 else 0.22,'tg_bottles' if (row+k)%3 else 'tg_grocery',depth=0.22,hi=hi)
            if row==2:
                salon_bottle(b,((x0+x1)/2+0.12*(1 if k else -1),-(D/2)+0.04,z+0.016),hi,h=0.22,body=bodies[(row+k)%len(bodies)],cap=caps[k],kind='pump')
    maker_plate(b,(0,-(D/2)+0.03,0.12),hi,w=0.07,h=0.014)
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))


# ------------------------------------------------------------------ wash_basin
def wash_basin(b, hi=False):
    # backwash unit: bowl behind, seat in front, all on one footprint
    W,D,H=0.70,1.20,1.10
    seg=sg(hi,12,18)
    # reclining shampoo chair (forward, -Y): chamfered pedestal, black vinyl seat with waterfall roll,
    # curved raked back that meets the bowl's neck rest, padded arms
    from b_inshared import arc_slab
    b.box((0,-0.30,0.0),(0.46,0.50,0.06),'paint_black',skip=('bottom',),ch=0.015)
    b.box((0,-0.28,0.06),(0.30,0.36,0.30),'paint_black',ch=0.02)
    b.box((0,-0.30,0.36),(0.52,0.48,0.04),'chrome',ch=0.012)
    b.box((0,-0.31,0.40),(0.50,0.44,0.09),'vinyl',ch=0.03)
    b.tube((-0.24,-0.52,0.45),(0.24,-0.52,0.45),0.04,0.04,sg(hi,6,12),'vinyl',cap0=True,cap1=True,smooth=True)
    arc_slab(b,(0,-0.86),0.84,106,74,0.46,0.86,0.06,'paint_black',seg=sg(hi,4,10))
    arc_slab(b,(0,-0.86),0.778,104,76,0.49,0.84,0.04,'vinyl',seg=sg(hi,4,10))
    for sgn in (-1,1):
        b.box((sgn*0.28,-0.26,0.40),(0.06,0.34,0.20),'paint_black',ch=0.02)
        b.box((sgn*0.28,-0.27,0.60),(0.085,0.40,0.05),'vinyl',ch=0.02)
    # bowl plinth at the back
    b.box((0,0.28,0.0),(0.62,0.50,0.72),'paint_cream',skip=('bottom',),ch=0.02)
    b.box((0,0.28,0.0),(0.64,0.52,0.08),'paint_black',skip=('bottom',))
    # ceramic-white bowl (paint_cream, not terracotta ceramic)
    # bowl is a wide tapered tube opening upward, slightly scooped toward the seat
    b.tube((0,0.22,0.70),(0,0.18,0.86),0.16,0.26,seg,'paint_white',cap0=True,cap1=False,smooth=True)
    b.tube((0,0.18,0.86),(0,0.16,0.92),0.26,0.24,seg,'paint_white',cap0=False,cap1=True,smooth=True)
    # inner well (light grey glaze in shadow, drain)
    b.tube((0,0.18,0.78),(0,0.16,0.925),0.14,0.21,sg(hi,10,16),'paint_grey',cap0=True,cap1=False,smooth=True)
    # headrest cushion on the bowl lip (toward the seat)
    b.box((0,-0.05,0.86),(0.24,0.10,0.07),'vinyl',ch=0.025)
    # faucet and sprayer
    b.tube((0,0.36,0.92),(0,0.36,1.10),0.014,0.014,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube((0,0.36,1.10),(0,0.16,1.10),0.012,0.012,sg(hi,8,12),'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0,0.16,1.10),(0,0.16,1.00),0.012,0.016,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
    # sprayer on a hose hook, right side
    b.tube((0.18,0.32,0.92),(0.18,0.32,1.02),0.010,0.010,sg(hi,6,10),'chrome',cap0=True,cap1=True,smooth=True)
    b.tube((0.18,0.32,1.02),(0.22,0.20,0.96),0.008,0.008,sg(hi,6,10),'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0.22,0.20,0.96),(0.22,0.20,0.90),0.016,0.012,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
    # handles
    for sgn in (-1,1):
        b.box((sgn*0.10,0.36,0.94),(0.04,0.04,0.05),'chrome')
        b.tube((sgn*0.10,0.38,0.96),(sgn*0.10,0.42,0.96),0.010,0.010,sg(hi,6,10),'chrome',cap0=False,cap1=True,smooth=True)
    # cabinet door on the seat-facing side of the plinth, plus a side towel rail
    b.box((0,0.03+0.012,0.14),(0.52,0.008,0.50),'paint_cream')
    b.box((0,0.03+0.004,0.14),(0.54,0.010,0.012),'oak')
    b.box((0,0.03+0.004,0.62),(0.54,0.010,0.012),'oak')
    for x in (-0.26,0.26,0.0):
        b.box((x,0.03+0.004,0.14),(0.010,0.010,0.50),'oak')
    b.box((0.18,0.02,0.36),(0.08,0.02,0.016),'chrome')
    # towel rail on the right side
    b.tube((0.32,0.12,0.55),(0.32,0.44,0.55),0.010,0.010,sg(hi,8,12),'chrome',cap0=True,cap1=True,smooth=True)
    b.box((0.32,0.12,0.55),(0.04,0.03,0.03),'chrome')
    b.box((0.32,0.44,0.55),(0.04,0.03,0.03),'chrome')
    b.box((0.32,0.28,0.40),(0.03,0.20,0.16),'paint_white',ch=0.01)  # folded towel over the rail
    # P-trap visible on the left side, not buried in the plinth
    b.tube((-0.32,0.20,0.20),(-0.32,0.20,0.08),0.022,0.022,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube((-0.32,0.20,0.08),(-0.32,0.36,0.08),0.022,0.022,sg(hi,8,12),'chrome',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,0.53,0.30),hi,w=0.06,h=0.014,rz=180)
    for x in (-0.24,0.24):
        for y in (0.10,0.46):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H+0.04))


# ------------------------------------------------------------------ registry
_C=dict(dir='props/indoor/salon',pdir='indoor_salon',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('barber_chair',barber_chair,'medium',1100),
    _p('mirror_station',mirror_station,'medium',1200,side=128,cage=0.04,ray=0.12),
    _p('nail_table',nail_table,'medium',900,side=96,cage=0.04,ray=0.12),
    _p('salon_product_shelf',salon_product_shelf,'medium',1200,side=96,cage=0.04,ray=0.12),
    _p('wash_basin',wash_basin,'medium',1200),
]

INDOOR_LOOK=True   # run.py: chamfer edge highlight + per-part colour variation in COLOR_0
