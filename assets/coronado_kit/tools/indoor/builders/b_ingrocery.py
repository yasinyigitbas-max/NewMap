"""Indoor grocery props — original geometry, page I, near+col only.

checkout_counter, chest_freezer, grocery_shelf, produce_stand.
Unique merch lives in the bake (no unique card on the high mesh;
silhouettes sit inside the cage). Delete stale _bake/tiles/<name>_* after
any geometry change.
"""
import math
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT,
)

# ------------------------------------------------------------------ checkout_counter
def checkout_counter(b, hi=False):
    W,D,H=2.00,0.72,0.92
    th=0.036
    # top with a slight bullnose front
    b.box((0,0.0,H-th),(W,D,th),'lam')
    b.box((0,-(D/2)+0.012,H-th-0.008),(W-0.04,0.024,0.016),'lam')
    # body + kick
    b.box((0,0.04,0.10),(W-0.06,D-0.08,H-th-0.12),'paint_cream',skip=('bottom',))
    b.box((0,0.04,0.0),(W-0.04,D-0.14,0.10),'paint_black',skip=('bottom',))
    # end panels
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.03,0.0,0.0),(0.06,D,H-0.02),'oak',skip=('bottom',))
    # front reveals, mid stile, brass waist
    b.box((0,-(D/2)+0.05,0.14),(0.04,0.04,H-th-0.20),'oak')
    for x in (-0.55,0.55):
        b.box((x,-(D/2)+0.045,0.18),(0.90,0.018,0.58),'oak')
        b.box((x,-(D/2)+0.032,0.20),(0.82,0.014,0.54),'lam')
        b.box((x,-(D/2)+0.028,0.22),(0.74,0.012,0.50),'paint_cream')
    b.box((0,-(D/2)+0.028,0.50),(W-0.20,0.014,0.016),'brass')
    # --- conveyor lane (customer left)
    # recessed well
    b.box((-0.42,-(D/2)+0.22,H-th+0.004),(0.92,0.36,0.018),'plastic_black')
    # belt
    b.box((-0.42,-(D/2)+0.22,H-th+0.014),(0.86,0.30,0.008),'rubber')
    # end rollers
    for x in (-0.82,-0.02):
        b.tube((x,-(D/2)+0.07,H-th+0.012),(x,-(D/2)+0.37,H-th+0.012),0.014,0.014,sg(hi,8,12),'steel',cap0=True,cap1=True,smooth=True)
    # belt slats (silhouette of a grocery belt)
    for i in range(7):
        b.box((-0.78+i*0.12,-(D/2)+0.22,H-th+0.020),(0.012,0.28,0.004),'rubber')
    # scanner glass + frame mid-lane
    b.box((0.14,-(D/2)+0.22,H-th+0.006),(0.22,0.28,0.010),'steel')
    b.box((0.14,-(D/2)+0.22,H-th+0.014),(0.16,0.22,0.006),'glass')
    # scale platter to the right of the glass
    b.box((0.36,-(D/2)+0.22,H-th+0.008),(0.20,0.24,0.012),'steel')
    b.box((0.36,-(D/2)+0.22,H-th+0.016),(0.16,0.18,0.006),'steel')
    # bagging well on the far right
    b.box((0.78,0.0,H-th-0.12),(0.36,D-0.10,0.12),'oak')  # well floor
    b.box((0.58,0.0,H-th-0.08),(0.04,D-0.12,0.16),'oak')  # divider
    # bag hooks under the well lip, customer side
    for x in (0.68,0.78,0.88):
        b.tube((x,-(D/2)+0.02,H-th-0.04),(x,-(D/2)-0.04,H-th-0.04),0.007,0.007,sg(hi,6,10),'steel',cap0=True,cap1=False,smooth=True)
        b.tube((x,-(D/2)-0.04,H-th-0.04),(x,-(D/2)-0.04,H-th-0.10),0.007,0.007,sg(hi,6,10),'steel',cap0=False,cap1=True,smooth=True)
    # cashier drawers (staff side, +Y)
    for i,x in enumerate((-0.35,0.05)):
        b.box((x,(D/2)-0.04,0.30),(0.30,0.04,0.16),'oak')
        b.box((x,(D/2)-0.02,0.30),(0.08,0.02,0.018),'brass')  # handle
    # keyboard shelf
    b.box((-0.55,(D/2)-0.10,H-th-0.12),(0.36,0.22,0.024),'oak')
    b.box((-0.55,(D/2)-0.10,H-th-0.10),(0.28,0.16,0.012),'plastic_black')
    # card terminal
    b.box((0.20,(D/2)-0.08,H-0.01),(0.12,0.10,0.06),'plastic_black')
    b.box((0.20,(D/2)-0.08,H+0.04),(0.10,0.08,0.03),'plastic')
    if hi:
        b.box((0.20,(D/2)-0.12,H+0.05),(0.08,0.004,0.02),'screen')
    # vertical scanner tower at mid-lane
    b.tube((0.14,-(D/2)+0.40,H),(0.14,-(D/2)+0.40,H+0.36),0.016,0.016,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
    b.box((0.14,-(D/2)+0.32,H+0.36),(0.10,0.16,0.12),'plastic_black')
    b.box((0.14,-(D/2)+0.24,H+0.36),(0.08,0.04,0.08),'glass')
    # receipt bump
    b.box((-0.10,(D/2)-0.10,H),(0.10,0.08,0.05),'plastic')
    maker_plate(b,(0.78,-(D/2)+0.03,0.22),hi,w=0.08,h=0.018)
    for x in (-W/2+0.12,W/2-0.12):
        for y in (-D/2+0.12,D/2-0.10):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D+0.08,H+0.42))


# ------------------------------------------------------------------ chest_freezer
def chest_freezer(b, hi=False):
    W,D,H=1.60,0.70,0.92
    # body
    b.box((0,0.0,0.08),(W,D,H-0.08-0.06),'paint_cream',skip=('bottom',))
    b.box((0,0.0,0.0),(W+0.02,D+0.02,0.08),'paint_black',skip=('bottom',))
    # compressor bulge on the right end
    b.box((W/2-0.08,0.04,0.08),(0.16,D-0.16,0.28),'paint_cream')
    b.box((W/2+0.005,0.04,0.10),(0.04,0.22,0.22),'paint_cream')  # proud end
    for i in range(6):
        b.box((W/2+0.02,0.04,0.12+i*0.028),(0.02,0.18,0.010),'steel')
    # thermostat
    b.box((-W/2+0.10,-(D/2)+0.02,0.55),(0.10,0.04,0.10),'plastic_black')
    b.tube((-W/2+0.10,-(D/2)+0.00,0.55),(-W/2+0.10,-(D/2)-0.02,0.55),0.018,0.018,sg(hi,8,12),'plastic',cap0=False,cap1=True,smooth=True)
    # lid rails
    b.box((0,0.0,H-0.06),(W-0.04,D-0.04,0.03),'steel')
    # two sliding lids — goods baked onto the glass so packs read through opaque kit glass
    for x in (-0.38,0.38):
        b.box((x,0.0,H-0.03),(0.74,D-0.10,0.024),'plastic_black')  # frame
        if not hi:
            b.box((x,0.0,H-0.012),(0.66,D-0.16,0.010),'goods')
        else:
            b.box((x,0.0,H-0.028),(0.66,D-0.16,0.010),'glass')
        # handle rail
        b.box((x,-(D/2)+0.08,H+0.004),(0.50,0.018,0.016),'steel')
        b.tube((x-0.24,-(D/2)+0.08,H+0.004),(x-0.24,-(D/2)+0.08,H-0.02),0.008,0.008,sg(hi,6,10),'steel',cap0=True,cap1=False,smooth=True)
        b.tube((x+0.24,-(D/2)+0.08,H+0.004),(x+0.24,-(D/2)+0.08,H-0.02),0.008,0.008,sg(hi,6,10),'steel',cap0=True,cap1=False,smooth=True)
    if hi:
        # frozen packs on the lid plane, in cage
        bodies=('paint_navy','paint_cream','leaf','oak','plastic','brass')
        y=0.0-0.006
        for col,x0 in enumerate((-0.38,0.38)):
            for i in range(3):
                for j in range(2):
                    xx=x0-0.22+i*0.22
                    yy=-0.12+j*0.22
                    key=bodies[(col+i+j)%len(bodies)]
                    b.box((xx,yy,H-0.006),(0.18,0.16,0.004),key)
                    b.box((xx,yy-0.003,H-0.002),(0.12,0.08,0.003),'label')
    # corner bumpers
    for x,y in ((-W/2+0.04,-D/2+0.04),(W/2-0.04,-D/2+0.04),(-W/2+0.04,D/2-0.04),(W/2-0.04,D/2-0.04)):
        b.tube((x,y,0.08),(x,y,0.18),0.03,0.03,sg(hi,8,12),'rubber',cap0=False,cap1=True,smooth=True)
    # front panel crease + lock hasp
    b.box((0,-(D/2)+0.01,0.48),(W-0.16,0.012,0.010),'paint_cream')
    b.box((0.10,-(D/2)+0.00,0.62),(0.04,0.02,0.06),'steel')
    b.box((0.10,-(D/2)-0.01,0.66),(0.08,0.03,0.016),'steel')
    # drain cap
    b.tube((0,-(D/2)+0.02,0.16),(0,-(D/2)-0.02,0.16),0.012,0.012,sg(hi,6,10),'steel',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,-(D/2)+0.03,0.40),hi,w=0.08,h=0.018)
    for x in (-W/2+0.12,W/2-0.12):
        for y in (-D/2+0.10,D/2-0.10):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W+0.04,D+0.04,H+0.04))


# ------------------------------------------------------------------ grocery_shelf
def grocery_shelf(b, hi=False):
    W,D,H=1.20,0.46,2.05
    # end standards
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.025,0.0,0.08),(0.05,D,H-0.16),'steel',skip=('bottom',))
        # slot ticks on the inner face (silhouette of an adjustable upright)
        if not hi:
            for i in range(10):
                z=0.22+i*0.16
                b.box((x+sgn*0.052,0.0,z),(0.006,0.06,0.008),'paint_black')
        else:
            for i in range(16):
                z=0.20+i*0.10
                b.box((x+sgn*0.052,0.0,z),(0.006,0.08,0.006),'paint_black')
    # back panel
    b.box((0,D/2-0.016,0.10),(W-0.08,0.016,H-0.22),'paint_cream')
    # kick + cornice
    b.box((0,0.0,0.0),(W,D,0.10),'steel',skip=('bottom',))
    b.box((0,-(D/2)+0.02,0.02),(W-0.10,0.02,0.06),'paint_black')
    b.box((0,0.0,H-0.08),(W,D,0.08),'steel')
    b.box((0,-0.01,H-0.12),(W-0.04,D-0.04,0.03),'steel')
    # mid upright
    b.box((0,0.0,0.10),(0.03,D-0.04,H-0.22),'steel')
    zs=(0.26,0.62,0.98,1.34,1.70)
    for z in zs:
        b.box((0,0.02,z),(W-0.10,D-0.08,0.018),'steel')
        # price channel / ticket strip
        b.box((0,-(D/2)+0.04,z-0.018),(W-0.14,0.016,0.022),'plastic')
        if hi:
            b.box((0,-(D/2)+0.03,z-0.018),(W-0.20,0.006,0.014),'label')
        # goods card on the shelf, facing -Y
        if not hi:
            b.box((0,-(D/2)+0.10,z+0.12),(W-0.16,0.008,0.20),'goods')
    if hi:
        y=-(D/2)+0.10-0.006
        bodies=('paint_navy','paint_cream','leaf','oak','plastic','brass','paint_black')
        for row,z in enumerate(zs):
            for col in range(6):
                x=-0.48+col*0.19
                if (row+col)%3==0:
                    bottle_card(b,(x,y,z+0.02),h=0.18,w=0.04,body=bodies[(row+col)%len(bodies)])
                else:
                    can_card(b,(x,y,z+0.02),h=0.14,w=0.05,body=bodies[(row+col)%len(bodies)])
    # hanging hook bar under the top shelf
    b.tube((-0.46,-(D/2)+0.08,1.64),(0.46,-(D/2)+0.08,1.64),0.007,0.007,sg(hi,6,10),'steel',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,-(D/2)+0.03,0.16),hi,w=0.08,h=0.016)
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))


# ------------------------------------------------------------------ produce_stand
def produce_stand(b, hi=False):
    W,D,H=1.40,0.70,1.15
    # base table
    b.box((0,0.0,0.0),(W,D,0.08),'oak',skip=('bottom',))
    b.box((0,0.0,0.08),(W-0.08,D-0.08,0.04),'oak')
    # four turned-ish legs
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            b.box((x,y,0.08),(0.06,0.06,0.46),'oak')
            b.box((x,y,0.20),(0.08,0.08,0.04),'oak')  # collar
            leveler(b,(x,y),hi)
    # lower storage shelf
    b.box((0,0.0,0.28),(W-0.16,D-0.16,0.024),'oak')
    # three stepped bins, front-to-back, slightly tilted toward the customer
    # tier floors
    tiers=(
        (0.52, 0.18, -0.16, 0.12),  # z, height of crate, y centre, depth
        (0.68, 0.20,  0.04, 0.16),
        (0.86, 0.22,  0.24, 0.18),
    )
    colors=('leaf','ceramic','oak','paint_cream','paint_navy')
    for i,(z,ch,yc,dd) in enumerate(tiers):
        # crate floor
        b.box((0,yc,z),(W-0.16,dd,0.020),'oak',rx=8)
        # crate ends
        for x,sgn in ((-W/2+0.10,1),(W/2-0.10,-1)):
            b.box((x,yc,z+ch*0.45),(0.018,dd,ch),'oak',rx=8)
        # front slats (the silhouette that reads "produce crate")
        nslat=4
        for s in range(nslat):
            zz=z+0.04+s*(ch-0.06)/(nslat-1)
            b.box((0,yc-(dd/2)+0.01,zz),(W-0.20,0.016,0.028),'oak',rx=8)
        # mid divider
        b.box((0,yc,z+ch*0.45),(0.016,dd-0.02,ch-0.02),'oak',rx=8)
        # produce card standing in the crate, facing -Y
        if not hi:
            b.box((0,yc-(dd/2)+0.04,z+ch*0.50),(W-0.24,0.008,ch-0.04),'goods',rx=8)
        if hi:
            y=yc-(dd/2)+0.04-0.006
            for col in range(4):
                x=-0.48+col*0.32
                key=colors[(i+col)%len(colors)]
                b.box((x,y,z+0.06),(0.26,0.004,ch-0.08),key,rx=8)
                b.box((x,y-0.003,z+ch*0.55),(0.16,0.003,0.05),'label',rx=8)
    # price rail across the front of each tier already implied; add a top sign board
    b.box((0,D/2-0.06,H-0.16),(W-0.20,0.03,0.22),'oak')
    b.box((0,D/2-0.08,H-0.16),(W-0.28,0.012,0.16),'label')
    # stretchers
    b.box((0,0.0,0.14),(W-0.20,0.04,0.03),'oak')
    b.box((0,0.0,0.14),(0.04,D-0.20,0.03),'oak')
    maker_plate(b,(0,-(D/2)+0.04,0.10),hi,w=0.08,h=0.016)
    b.cbox((0,0,0),(W,D,H))


# ------------------------------------------------------------------ registry

# ------------------------------------------------------------------ cigarette_cabinet
def cigarette_cabinet(b, hi=False):
    W,D,H=0.90,0.32,1.10
    # behind-counter cabinet, lockable, rows of pack slots
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.025,0.0,0.0),(0.05,D,H-0.04),'oak',skip=('bottom',))
    b.box((0,D/2-0.016,0.08),(W-0.08,0.02,H-0.16),'oak')
    b.box((0,0.0,0.0),(W,D,0.08),'oak',skip=('bottom',))
    b.box((0,0.0,H-0.06),(W,D,0.06),'oak')
    b.box((0,-0.01,H-0.10),(W+0.02,D+0.02,0.03),'oak')
    # mid stile
    b.box((0,0.0,0.08),(0.024,D-0.04,H-0.16),'oak')
    # 4 shelves of pack slots
    zs=(0.20,0.42,0.64,0.86)
    for z in zs:
        b.box((0,0.0,z),(W-0.10,D-0.04,0.016),'oak')
        # ticket lip
        b.box((0,-(D/2)+0.02,z-0.012),(W-0.14,0.014,0.016),'plastic')
        if not hi:
            b.box((0,-(D/2)+0.06,z+0.08),(W-0.16,0.008,0.14),'goods')
    if hi:
        y=-(D/2)+0.06-0.006
        bodies=('paint_navy','paint_cream','leaf','paint_black','brass','oak','fabric')
        for row,z in enumerate(zs):
            for col in range(8):
                x=-0.36+col*0.10
                b.box((x,y,z+0.02),(0.08,0.004,0.12),bodies[(row+col)%len(bodies)])
                b.box((x,y-0.003,z+0.08),(0.06,0.003,0.04),'label')
    # lower lockable drawer
    b.box((0,-(D/2)+0.02,0.10),(W-0.14,0.03,0.10),'oak')
    b.box((0,-(D/2)+0.00,0.14),(0.08,0.02,0.016),'steel')
    b.tube((0.16,-(D/2)-0.01,0.14),(0.16,-(D/2)-0.02,0.14),0.010,0.010,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,-(D/2)+0.03,0.10),hi,w=0.06,h=0.014)
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))


_C=dict(dir='props/indoor/grocery',pdir='indoor_grocery',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('checkout_counter',checkout_counter,'medium',1200),
    _p('chest_freezer',chest_freezer,'medium',1100,side=96,cage=0.04,ray=0.12),
    _p('grocery_shelf',grocery_shelf,'medium',1200,side=96,cage=0.04,ray=0.12),
    _p('produce_stand',produce_stand,'medium',1100,side=96,cage=0.04,ray=0.12),
    _p('cigarette_cabinet',cigarette_cabinet,'medium',900,side=96,cage=0.04,ray=0.12),
]
