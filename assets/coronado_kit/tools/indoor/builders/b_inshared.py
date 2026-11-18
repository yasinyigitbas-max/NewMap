"""Indoor shared props — original geometry, page I, near+col only. No mid/far."""
import math
from mathutils import Vector

def sg(hi, lo, hi_n):
    return hi_n if hi else lo

def leveler(b, c, hi=False):
    x,y=c[0],c[1]; seg=sg(hi,6,12)
    b.tube((x,y,0.0),(x,y,0.006),0.018,0.017,seg,'rubber',cap0=True,cap1=False,smooth=True)
    b.tube((x,y,0.005),(x,y,0.038),0.010,0.010,seg,'plastic',cap0=False,cap1=True,smooth=True)
    if hi:
        b.tube((x,y,0.032),(x,y,0.048),0.007,0.007,8,'steel',cap0=False,cap1=True,smooth=False)

def screw(b, c, n=(0,0,1), hi=False, key='steel', r=0.0045):
    n=Vector(n).normalized(); c=Vector(c); seg=sg(hi,8,14)
    b.tube(c-n*0.002, c+n*0.003, r, r*0.92, seg, key, cap0=False, cap1=True, smooth=True)
    if hi:
        b.tube(c-n*0.010, c-n*0.001, r*0.45, r*0.45, 8, key, cap0=True, cap1=False, smooth=True)

def bolt_row(b, pts, n=(0,0,1), hi=False, key='steel'):
    for p in pts: screw(b,p,n,hi,key)

def maker_plate(b, c, hi=False, w=0.07, h=0.022, rz=0.0):
    """Small unique-bake name plate so every prop has a bake slot (bevels, AO, lettering)."""
    b.box(c,(w,0.006,h),'badge',rz=rz)
    if hi:
        screw(b,(c[0]-w*0.35,c[1]+0.004,c[2]+h*0.5),(0,-1,0) if abs(rz)<0.01 else (0,1,0),True,'steel',0.0025)
        screw(b,(c[0]+w*0.35,c[1]+0.004,c[2]+h*0.5),(0,-1,0) if abs(rz)<0.01 else (0,1,0),True,'steel',0.0025)


def leaf_blade(b, c, length, width, thick=0.003, yaw=0.0, pitch=0.0, roll=0.0, key='leaf'):
    """Solid ovate / diamond leaf (4 tris). Opaque kit leaf, no alpha."""
    from mathutils import Matrix, Vector
    c=Vector(c)
    R=(Matrix.Rotation(math.radians(yaw),4,'Z') @
       Matrix.Rotation(math.radians(pitch),4,'X') @
       Matrix.Rotation(math.radians(roll),4,'Y'))
    def lp(x,y,z):
        return c + (R @ Vector((x,y,z)))
    hw,t=width*0.5, thick*0.5
    # stem at origin, tip at +X, width along Y
    top=[lp(0,0,t), lp(length*0.38,hw,t*0.6), lp(length,0,t), lp(length*0.38,-hw,t*0.6)]
    bot=[lp(0,0,-t), lp(length*0.38,-hw,-t*0.6), lp(length,0,-t), lp(length*0.38,hw,-t*0.6)]
    b.faces(top,[(0,1,2,3)],key,[[ (0,0),(0,width),(length,0),(0,-width) ]],smooth=True)
    b.faces(bot,[(0,1,2,3)],key,[[ (0,0),(0,-width),(length,0),(0,width) ]],smooth=True)

def bottle_card(b, c, h=0.22, w=0.048, body='plastic', cap='paint_cream'):
    """Flat bottle silhouette, 4 mm thick, for the unique bake (must sit inside the cage)."""
    x,y,z=c
    b.box((x,y,z),(w,0.004,h*0.70),body)
    b.box((x,y,z+h*0.70),(w*0.40,0.004,h*0.18),body)
    b.box((x,y,z+h*0.88),(w*0.44,0.004,h*0.12),cap)
    b.box((x,y-0.003,z+h*0.22),(w*0.82,0.003,h*0.28),'label')

def can_card(b, c, h=0.12, w=0.052, body='paint_navy'):
    x,y,z=c
    b.box((x,y,z),(w,0.004,h*0.90),body)
    b.box((x,y,z+h*0.90),(w*0.92,0.004,h*0.10),'alum')
    b.box((x,y-0.003,z+h*0.28),(w*0.80,0.003,h*0.30),'label')

# ------------------------------------------------------------------ shop_counter
def shop_counter(b, hi=False):
    W,D,H=1.82,0.64,0.96; th=0.036; kick_h,kick_d=0.10,0.07
    # laminate top, slight front overhang
    ov=0.018
    b.box((0,-ov*0.3,H-th),(W,D+ov,th),'lam',skip=())
    # bullnose / T-mold along customer edge (-Y)
    fy=-(D/2+ov*0.3)+0.004; seg=sg(hi,8,14)
    b.tube((-W/2+0.02,fy,H-th*0.45),(W/2-0.02,fy,H-th*0.45),0.009,0.009,seg,'plastic_black',cap0=True,cap1=True,smooth=True)
    # body: painted MDF, inset at the kick
    bw,bd=W-0.04,D-0.04
    b.box((0,0.01,kick_h),(bw,bd-kick_d,H-th-kick_h-0.002),'paint_cream',skip=('top','bottom'))
    # kick plate (customer side)
    b.box((0,-(D/2)+kick_d*0.5-0.005,0.0),(W-0.02,kick_d,kick_h),'paint_black',skip=('bottom',))
    # staff-side kick (shallower)
    b.box((0,(D/2)-0.03,0.0),(W-0.02,0.05,0.06),'paint_cream',skip=('bottom',))
    # customer-side panel reveals (break the slab into three bays)
    b.box((0,-(D/2)+0.008,0.50),(W-0.16,0.006,0.008),'paint_black')
    for x in (-W*0.28, W*0.28):
        b.box((x,-(D/2)+0.008,kick_h+0.04),(0.008,0.006,H-th-kick_h-0.10),'paint_black')
    # bag shelf (open to +Y staff side), mid height
    b.box((0,0.06,0.28),(W-0.10,0.38,0.018),'oak')
    # two vertical dividers under the top
    for x in (-W*0.22,W*0.22):
        b.box((x,0.04,0.28),(0.018,0.36,H-th-0.28),'oak',skip=('top',))
    # two cash / utility drawers facing staff (+Y)
    dw,dd,dh=0.42,0.46,0.12
    for dx,has_lock in ((0.42,True),(-0.42,False)):
        dz=0.62
        b.box((dx,(D/2)-dd/2-0.01,dz),(dw,dd,dh),'oak')
        b.box((dx,(D/2)-0.005,dz),(dw-0.01,0.016,dh-0.01),'oak')
        b.box((dx,(D/2)+0.012,dz+dh*0.55),(0.12,0.012,0.012),'brass')
        for x in (dx-0.05,dx+0.05):
            b.tube((x,(D/2)-0.004,dz+dh*0.55),(x,(D/2)+0.018,dz+dh*0.55),0.006,0.006,sg(hi,6,10),'brass',cap0=True,cap1=True)
        if has_lock:
            b.box((dx+0.14,(D/2)+0.008,dz+dh*0.3),(0.022,0.006,0.022),'badge',keys={'front':'badge'})
    # chrome footrail, customer side, returns into the kick (grounded ends)
    rz=0.26; ry=-(D/2)+0.02
    b.tube((-W/2+0.10,ry,rz),(W/2-0.10,ry,rz),0.016,0.016,sg(hi,8,14),'chrome',cap0=False,cap1=False,smooth=True)
    # return down into kick / brackets
    for x in (-W/2+0.10,W/2-0.10):
        b.tube((x,ry,rz),(x,ry,kick_h+0.01),0.016,0.016,sg(hi,6,12),'chrome',cap0=False,cap1=True,smooth=True)
        b.box((x,ry+0.018,kick_h+0.02),(0.04,0.03,0.03),'steel')  # flange into kick
        if hi: screw(b,(x,ry+0.028,kick_h+0.03),(0,1,0),True,'steel',0.0035)
    # grommet, left rear of top
    gx,gy= -W/2+0.16, D/2-0.12
    b.tube((gx,gy,H-0.002),(gx,gy,H+0.004),0.022,0.022,sg(hi,10,16),'steel',cap0=False,cap1=True,smooth=True)
    b.tube((gx,gy,H-th),(gx,gy,H-0.001),0.016,0.016,sg(hi,8,14),'plastic_black',cap0=False,cap1=False,smooth=True)
    # cable pass underneath
    if hi:
        b.tube((gx,gy,H-th-0.02),(gx,gy+0.08,H-th-0.08),0.008,0.008,8,'plastic_black',cap0=True,cap1=True,smooth=True)
    # front staff deadplate / drip strip
    b.box((0,-(D/2)+0.03,H-th-0.008),(W-0.08,0.04,0.008),'steel')
    # corner brackets under top
    if hi:
        for x in (-W/2+0.08,W/2-0.08):
            for y in (-D/2+0.10,D/2-0.10):
                b.box((x,y,H-th-0.012),(0.04,0.04,0.012),'steel')
                screw(b,(x,y,H-th-0.011),(0,0,-1),True)
    # four levelers
    inset=0.07
    for x in (-W/2+inset,W/2-inset):
        for y in (-D/2+inset+kick_d*0.4,D/2-inset):
            leveler(b,(x,y),hi)
    # till recess ring (unique, shallow)
    b.box((0.10,0.0,H+0.001),(0.28,0.22,0.003),'label')
    b.cbox((0,0,0),(W,D+0.04,H))

# ------------------------------------------------------------------ cash_register
def cash_register(b, hi=False):
    W,D,H=0.42,0.40,0.36
    # body
    b.box((0,0,0.018),(W,D,H-0.018),'paint_cream',skip=('bottom',))
    # rubber feet
    for x in (-W/2+0.04,W/2-0.04):
        for y in (-D/2+0.04,D/2-0.04):
            b.tube((x,y,0.0),(x,y,0.018),0.012,0.012,sg(hi,6,10),'rubber',cap0=True,cap1=False,smooth=True)
    # drawer (front -Y)
    b.box((0,-(D/2)+0.01,0.03),(W-0.04,0.02,0.11),'paint_black')
    b.box((0,-(D/2)-0.006,0.07),(0.10,0.012,0.012),'steel')  # handle
    for x in (-0.04,0.04):
        b.tube((x,-(D/2)+0.01,0.07),(x,-(D/2)-0.012,0.07),0.005,0.005,sg(hi,6,10),'steel',cap0=True,cap1=True)
    # key lock
    b.box((W/2-0.08,-(D/2)-0.002,0.08),(0.018,0.006,0.018),'badge')
    # keypad deck, sloped slightly via two boxes
    b.box((0,-0.04,H-0.02),(W-0.06,0.22,0.02),'plastic_black')
    # keys (unique bake on a plate)
    b.box((0,-0.05,H-0.001),(0.22,0.16,0.006),'keypad')
    if hi:
        # individual key caps (silhouette for the bake)
        for i in range(4):
            for j in range(4):
                b.box((-0.075+i*0.05,-0.10+j*0.04,H+0.004),(0.036,0.028,0.006),'plastic')
    # customer display, hinged up at the back
    b.box((0,D/2-0.08,H+0.07),(0.18,0.04,0.08),'plastic_black')
    b.box((0,D/2-0.082,H+0.07),(0.15,0.008,0.06),'screen')  # unique screen
    if hi:
        # POS chrome: header + two totals + a row of buttons (bakes onto screen)
        sy=D/2-0.076
        b.box((0,sy,H+0.10),(0.13,0.004,0.012),'paint_navy')
        b.box((-0.02,sy,H+0.06),(0.10,0.004,0.016),'plastic')
        b.box((0.05,sy,H+0.06),(0.04,0.004,0.016),'leaf')
        for i in range(3):
            b.box((-0.04+i*0.04,sy,H+0.045),(0.028,0.003,0.006),'plastic_black')
    # display stalks
    for x in (-0.06,0.06):
        b.tube((x,D/2-0.10,H-0.01),(x,D/2-0.08,H+0.03),0.007,0.007,sg(hi,6,10),'steel',cap0=True,cap1=True,smooth=True)
    # receipt slot + paper roll housing
    b.box((W/2-0.07,0.06,H+0.03),(0.10,0.12,0.08),'plastic_black')
    b.tube((W/2-0.12,0.06,H+0.055),(W/2-0.02,0.06,H+0.055),0.022,0.022,sg(hi,10,16),'plastic',cap0=True,cap1=True,smooth=True)
    b.box((W/2-0.07,-(0.02),H+0.01),(0.08,0.008,0.006),'label')  # slot
    # card reader on the right
    b.box((W/2+0.01,0.02,H-0.04),(0.04,0.10,0.06),'plastic_black')
    b.box((W/2+0.03,0.02,H-0.04),(0.008,0.08,0.04),'badge')
    # vents on sides
    if hi:
        for z in (0.14,0.18,0.22):
            b.box((-W/2-0.001,0.0,z),(0.003,0.08,0.008),'paint_black')
    # brand badge front
    b.box((0,-(D/2)-0.001,0.22),(0.08,0.003,0.02),'badge')
    b.cbox((0,0,0),(W+0.04,D,H+0.16))

# ------------------------------------------------------------------ wall_shelf
def wall_shelf(b, hi=False):
    W,D,H=1.00,0.32,2.00
    # two slotted standards
    for x in (-W/2+0.06,W/2-0.06):
        b.box((x,D/2-0.02,0.08),(0.04,0.036,H-0.16),'steel',skip=('bottom',))
        # wall flanges / plates
        b.box((x,D/2+0.006,0.14),(0.07,0.008,0.07),'steel')
        b.box((x,D/2+0.006,H-0.18),(0.07,0.008,0.07),'steel')
        if hi:
            for z in (0.14,H-0.18):
                for ox in (-0.02,0.02):
                    screw(b,(x+ox,D/2+0.011,z),(0,1,0),True,'steel',0.0035)
            # slot punches on the standard (baked mostly; a few modelled)
            for z in (0.25+i*0.15 for i in range(10)):
                b.box((x,D/2-0.038,z),(0.012,0.004,0.018),'paint_black')
    # kick / toe
    b.box((0,0.0,0.0),(W,D,0.10),'oak',skip=('bottom',))
    # four shelves + pins
    for z in (0.28,0.72,1.16,1.60):
        b.box((0,-0.01,z),(W-0.04,D-0.04,0.018),'oak')
        # price channel at front lip
        b.box((0,-D/2+0.012,z-0.016),(W-0.08,0.012,0.018),'plastic')
        # shelf pins
        for x in (-W/2+0.06,W/2-0.06):
            b.tube((x,-0.02,z-0.006),(x,-0.02,z),(0.005),0.005,sg(hi,6,10),'steel',cap0=True,cap1=False,smooth=True)
        if hi:
            # bracket tongues
            for x in (-W/2+0.06,W/2-0.06):
                b.box((x,0.04,z-0.02),(0.03,0.12,0.016),'steel')
    # top cap
    b.box((0,0.0,H-0.04),(W,D,0.04),'oak')
    # back panel
    b.box((0,D/2-0.038,0.10),(W-0.02,0.008,H-0.16),'paint_cream')
    # end panels
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.01,0.0,0.10),(0.018,D,H-0.14),'oak',skip=('bottom',))
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.04,D/2-0.04):
            leveler(b,(x,y),hi)
    maker_plate(b,(0,-(D/2)+0.01,0.04),hi,w=0.08,h=0.02)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ gondola_aisle
def gondola_aisle(b, hi=False):
    W,D,H=1.22,0.54,1.82
    # spine
    b.box((0,0,0.08),(W-0.04,0.04,H-0.16),'paint_cream',skip=('bottom',))
    # base deck both sides
    b.box((0,0,0.0),(W,D,0.12),'paint_cream',skip=('bottom',))
    # kick both long sides
    for y,s in ((-D/2+0.03,1),(D/2-0.03,-1)):
        b.box((0,y,0.0),(W-0.02,0.05,0.10),'paint_black',skip=('bottom',))
    # uprights
    for x in (-W/2+0.04,W/2-0.04):
        b.box((x,0,0.12),(0.04,0.06,H-0.20),'steel')
        if hi:
            for z in (0.3+i*0.15 for i in range(9)):
                b.box((x,0.0,z),(0.012,0.05,0.016),'paint_black')
    # pegboard / backer each side of the spine
    for ysgn in (-1,1):
        b.box((0,ysgn*0.032,0.20),(W-0.14,0.010,H-0.36),'paint_cream')
        # hook bar under each shelf bay
        for z in (0.55,0.99,1.43):
            b.box((0,ysgn*0.045,z),(W-0.18,0.012,0.010),'steel')
    # three shelves per side
    for ysgn in (-1,1):
        for z in (0.38,0.82,1.26):
            b.box((0,ysgn*(D/2-0.13),z),(W-0.10,0.22,0.016),'oak')
            b.box((0,ysgn*(D/2-0.03),z-0.014),(W-0.14,0.012,0.016),'plastic')  # price strip
            if hi:
                for x in (-W/2+0.04,W/2-0.04):
                    b.box((x,ysgn*0.10,z-0.02),(0.03,0.10,0.014),'steel')
    # top cap / cornice
    b.box((0,0,H-0.08),(W,D-0.04,0.08),'paint_cream')
    # end caps
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.015,0,0.12),(0.03,D-0.02,H-0.20),'paint_cream')
        b.box((x+sgn*0.001,0,H*0.55),(0.004,0.16,0.08),'badge')
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    maker_plate(b,(0,-(D/2)+0.01,0.04),hi,w=0.10,h=0.02)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ display_table
def display_table(b, hi=False):
    W,D,H=1.36,0.76,0.78; th=0.034
    # top + breadboard ends (grain-break silhouette)
    b.box((0,0,H-th),(W-0.12,D,th),'walnut')
    for x in (-W/2+0.03,W/2-0.03):
        b.box((x,0,H-th),(0.06,D,th),'walnut')
    # under-bevel / drip edge
    b.box((0,0,H-th-0.012),(W-0.04,D-0.02,0.012),'walnut')
    # apron, taller, with a bead on the lower edge
    ah=0.11
    for (c,sz) in (
        ((0,-(D/2)+0.032,H-th-ah),(W-0.16,0.030,ah)),
        ((0,(D/2)-0.032,H-th-ah),(W-0.16,0.030,ah)),
        ((-(W/2)+0.032,0,H-th-ah),(0.030,D-0.12,ah)),
        (((W/2)-0.032,0,H-th-ah),(0.030,D-0.12,ah)),
    ):
        b.box(c,sz,'walnut')
    # apron bead
    b.box((0,-(D/2)+0.034,H-th-ah-0.008),(W-0.18,0.024,0.010),'walnut')
    b.box((0,(D/2)-0.034,H-th-ah-0.008),(W-0.18,0.024,0.010),'walnut')
    # shallow drawer on the customer apron
    dw,dh=0.36,0.07
    b.box((0,-(D/2)+0.008,H-th-ah+0.015),(dw,0.016,dh),'walnut')
    b.box((0,-(D/2)-0.006,H-th-ah+0.045),(0.10,0.010,0.012),'brass')
    for x in (-0.04,0.04):
        b.tube((x,-(D/2)+0.010,H-th-ah+0.045),(x,-(D/2)-0.010,H-th-ah+0.045),0.005,0.005,sg(hi,6,10),'brass',cap0=True,cap1=True)
    # tapered square legs with brass sabots and a mid turning
    lw0,lw1=0.062,0.042; lh=H-th-ah
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            mid=lh*0.55
            b.box((x,y,0.05),(lw0,lw0,mid-0.05),'walnut',skip=('bottom',))
            # turning / collar
            b.box((x,y,mid-0.02),(lw0+0.008,lw0+0.008,0.04),'walnut')
            b.box((x,y,mid+0.02),(lw1,lw1,lh-mid-0.02),'walnut')
            b.box((x,y,0.006),(lw0+0.006,lw0+0.006,0.05),'brass',skip=('bottom',))
            b.tube((x,y,0.0),(x,y,0.008),0.024,0.024,sg(hi,6,10),'rubber',cap0=True,cap1=False)
            b.box((x,y,H-th-ah-0.024),(0.07,0.07,0.024),'walnut')
            if hi:
                screw(b,(x+0.02,y,H-th-ah-0.005),(0,0,1),True,'steel',0.003)
    # lower shelf + four-sided stretcher box
    b.box((0,0,0.22),(W-0.24,D-0.24,0.018),'walnut')
    for (c,sz) in (
        ((0,-(D/2)+0.12,0.18),(W-0.26,0.028,0.040)),
        ((0,(D/2)-0.12,0.18),(W-0.26,0.028,0.040)),
        ((-(W/2)+0.12,0,0.18),(0.028,D-0.26,0.040)),
        (((W/2)-0.12,0,0.18),(0.028,D-0.26,0.040)),
    ):
        b.box(c,sz,'walnut')
    if hi:
        for x in (-0.3,0.0,0.3):
            b.box((x,0,H+0.0005),(0.04,0.012,0.002),'oak')
    maker_plate(b,(0,-(D/2)+0.02,H-th-0.08),hi,w=0.08,h=0.018)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ glass_display_case
def glass_display_case(b, hi=False):
    W,D,H=1.24,0.58,1.10
    pl=0.10  # plinth
    fw=0.032  # frame width
    # plinth
    b.box((0,0,0.0),(W,D,pl),'paint_cream',skip=('bottom',))
    # felt pad on plinth top (unique/fabric)
    b.box((0,0,pl),(W-0.06,D-0.06,0.006),'fabric')
    # corner posts
    for x in (-W/2+fw/2,W/2-fw/2):
        for y in (-D/2+fw/2,D/2-fw/2):
            b.box((x,y,pl),(fw,fw,H-pl-0.04),'brass',skip=('bottom',))
    # rails: bottom, mid, top
    for z in (pl+0.01, 0.62, H-0.04):
        b.box((0,-(D/2)+fw/2,z),(W-2*fw,fw,0.024),'brass')
        b.box((0,(D/2)-fw/2,z),(W-2*fw,fw,0.024),'brass')
        b.box((-(W/2)+fw/2,0,z),(fw,D-2*fw,0.024),'brass')
        b.box(((W/2)-fw/2,0,z),(fw,D-2*fw,0.024),'brass')
    # opaque glass sides; full-height front is a goods card on near only.
    # High-poly stock sits in the same plane so the bake sees bottles, not the card.
    if not hi:
        b.box((0,-(D/2)+fw*0.45,pl+0.03),(W-2*fw-0.004,0.008,H-pl-0.12),'goods')
    for x,sgn in ((-W/2+fw*0.45,1),(W/2-fw*0.45,-1)):
        b.box((x,0,pl+0.03),(0.008,D-2*fw-0.004,H-pl-0.10),'glass')
    # glass shelves (visible as slim lips on the front bake / at the frame)
    for z in (0.40,0.78):
        b.box((0,0,z),(W-0.12,D-0.14,0.008),'glass')
    # back panel (wood, not glass)
    b.box((0,(D/2)-0.012,pl+0.02),(W-2*fw,0.016,H-pl-0.08),'paint_cream')
    # LED cornice
    b.box((0,0,H-0.04),(W,D,0.04),'paint_cream')
    b.box((0,-0.04,H-0.05),(W-0.10,0.20,0.012),'steel')  # light trough
    # lock on front rail
    b.box((W/2-0.10,-(D/2)-0.004,0.62),(0.024,0.008,0.024),'badge')
    # hinges on right
    for z in (pl+0.12, H-0.16):
        b.box((W/2-0.01,-(D/2)+0.01,z),(0.016,0.03,0.05),'brass')
    if hi:
        for x in (-W/2+0.08,W/2-0.08):
            for y in (-D/2+0.08,D/2-0.08):
                leveler(b,(x,y),True)
        # flat stock 6 mm in front of the glass plane (inside the bake cage)
        bodies=('plastic','paint_navy','paint_cream','plastic_black','leaf','oak')
        y=-(D/2)+fw*0.45-0.006
        for si,z in enumerate((0.408,0.788)):
            for col in range(6):
                x=-0.40+col*0.16
                key=bodies[(si+col)%len(bodies)]
                if col%2==0:
                    bottle_card(b,(x,y,z),h=0.18,w=0.06,body=key,cap='brass')
                else:
                    b.box((x,y,z),(0.08,0.004,0.10),key)
                    b.box((x,y-0.003,z+0.03),(0.06,0.003,0.04),'label')
    else:
        for x in (-W/2+0.08,W/2-0.08):
            for y in (-D/2+0.08,D/2-0.08):
                leveler(b,(x,y),False)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ waiting_bench
def waiting_bench(b, hi=False):
    W,D,H=1.52,0.56,0.88
    sh=0.43
    # four corner legs + a mid front leg, brass sabots
    for x in (-W/2+0.07,0.0,W/2-0.07):
        ys = (-D/2+0.07, D/2-0.07) if x!=0.0 else (-D/2+0.07,)
        for y in ys:
            b.box((x,y,0.02),(0.055,0.055,sh-0.05),'walnut',skip=('bottom',))
            b.box((x,y,0.0),(0.062,0.062,0.028),'brass',skip=('bottom',))
    # stretchers, slightly heavier, plus a front apron rail under the seat
    b.box((0,-(D/2)+0.07,0.14),(W-0.18,0.036,0.036),'walnut')
    b.box((0,(D/2)-0.07,0.14),(W-0.18,0.036,0.036),'walnut')
    b.box((-(W/2)+0.07,0,0.14),(0.036,D-0.18,0.036),'walnut')
    b.box(((W/2)-0.07,0,0.14),(0.036,D-0.18,0.036),'walnut')
    b.box((0,-(D/2)+0.04,sh-0.08),(W-0.16,0.030,0.040),'walnut')  # front apron
    # seat frame + two cushions with welt and a bullnose front
    b.box((0,0,sh-0.045),(W-0.06,D-0.06,0.045),'walnut')
    gap=0.02
    cw=(W-0.14-gap)/2
    for x in (-(cw+gap)/2,(cw+gap)/2):
        b.box((x,-0.01,sh),(cw,D-0.12,0.065),'fabric')
        b.box((x,-0.01,sh+0.062),(cw+0.010,D-0.10,0.008),'fabric')  # piping
        b.box((x,-(D/2)+0.04,sh+0.01),(cw-0.02,0.020,0.050),'fabric')  # bullnose
    b.box((0,-0.01,sh+0.012),(0.016,D-0.16,0.052),'walnut')
    # back: two cushions, mid stile, thicker crest
    b.box((0,(D/2)-0.06,sh+0.04),(W-0.10,0.050,0.045),'walnut')
    bw=(W-0.18-gap)/2
    for x in (-(bw+gap)/2,(bw+gap)/2):
        b.box((x,(D/2)-0.055,sh+0.08),(bw,0.055,0.30),'fabric')
        b.box((x,(D/2)-0.055,sh+0.37),(bw+0.008,0.060,0.010),'fabric')
    b.box((0,(D/2)-0.05,sh+0.10),(0.016,0.04,0.26),'walnut')  # mid stile
    b.box((0,(D/2)-0.04,H-0.05),(W-0.10,0.050,0.050),'walnut')  # crest
    # stiles, slightly thicker
    for x in (-W/2+0.09,W/2-0.09):
        b.box((x,(D/2)-0.05,sh),(0.048,0.055,H-sh),'walnut')
    # sculpted arms: post, pad, and a small corbel
    for x in (-W/2+0.05,W/2-0.05):
        b.box((x,0.02,sh+0.18),(0.062,D-0.16,0.048),'walnut')  # pad
        b.box((x,-(D/2)+0.12,sh),(0.048,0.048,0.20),'walnut')  # post
        b.box((x,-(D/2)+0.12,sh+0.16),(0.055,0.06,0.03),'walnut')  # corbel
    if hi:
        for x in (-0.45,-0.18,0.18,0.45):
            for y in (-0.10,0.08):
                b.tube((x,y,sh+0.065),(x,y,sh+0.074),0.007,0.007,8,'brass',cap0=False,cap1=True,smooth=True)
    maker_plate(b,(0,-(D/2)+0.04,0.16),hi,w=0.06,h=0.016)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ side_chair
def side_chair(b, hi=False):
    W,D,H=0.48,0.52,0.92
    sh=0.46
    rake=0.05
    # thicker legs, slight front splay via a wider stance
    for x in (-W/2+0.05,W/2-0.05):
        fy=-(D/2)+0.06
        b.box((x,fy,0.016),(0.048,0.048,sh-0.025),'oak',skip=('bottom',))
        b.tube((x,fy,0.0),(x,fy,0.018),0.020,0.020,sg(hi,6,10),'plastic_black',cap0=True,cap1=False)
        y0=D/2-0.055
        b.box((x,y0,0.016),(0.050,0.052,sh-0.025),'oak',skip=('bottom',))
        b.tube((x,y0,0.0),(x,y0,0.018),0.020,0.020,sg(hi,6,10),'plastic_black',cap0=True,cap1=False)
        b.box((x,y0+rake*0.45,sh),(0.044,0.044,H-sh-0.05),'oak')
    # heavier H and front stretchers + a front apron under the seat
    b.box((0,-(D/2)+0.06,0.18),(W-0.14,0.028,0.030),'oak')
    b.box((0,(D/2)-0.055,0.18),(W-0.14,0.028,0.030),'oak')
    b.box((-(W/2)+0.05,0,0.17),(0.026,D-0.16,0.030),'oak')
    b.box(((W/2)-0.05,0,0.17),(0.026,D-0.16,0.030),'oak')
    b.box((-(W/2)+0.05,0,0.30),(0.022,D-0.18,0.022),'oak')
    b.box(((W/2)-0.05,0,0.30),(0.022,D-0.18,0.022),'oak')
    b.box((0,-(D/2)+0.05,sh-0.07),(W-0.14,0.028,0.040),'oak')  # front apron
    # seat + welt + a slightly proud front rail
    b.box((0,-0.01,sh-0.034),(W-0.04,D-0.10,0.034),'oak')
    b.box((0,-0.01,sh),(W-0.07,D-0.13,0.048),'fabric')
    b.box((0,-0.01,sh+0.046),(W-0.06,D-0.12,0.008),'fabric')
    b.box((0,-(D/2)+0.06,sh+0.008),(W-0.10,0.020,0.036),'fabric')
    # wider crest, lower rail, three slats
    b.box((0,(D/2)-0.03+rake*0.45,H-0.055),(W-0.08,0.040,0.055),'oak')
    b.box((0,(D/2)-0.03+rake*0.25,sh+0.04),(W-0.14,0.032,0.036),'oak')
    for x in (-0.09,0.0,0.09):
        b.box((x,(D/2)-0.04+rake*0.3,sh+0.07),(0.038,0.028,0.30),'oak')
    # corner blocks
    for x in (-W/2+0.09,W/2-0.09):
        for y in (-D/2+0.11,D/2-0.11):
            b.box((x,y,sh-0.05),(0.045,0.045,0.020),'oak')
            if hi:
                screw(b,(x,y,sh-0.048),(0,0,1),True,'steel',0.003)
    maker_plate(b,(0,-(D/2)+0.05,0.22),hi,w=0.05,h=0.014)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ potted_plant
def potted_plant(b, hi=False):
    # glazed pot, saucer, soil, rubber-plant trunk and solid ovate leaves (no alpha)
    seg=sg(hi,10,18)
    # saucer
    b.tube((0,0,0.0),(0,0,0.022),0.16,0.17,seg,'ceramic',cap0=True,cap1=False,smooth=True)
    b.tube((0,0,0.016),(0,0,0.026),0.15,0.13,seg,'ceramic',cap0=False,cap1=True,smooth=True)
    # pot body + rim (four stacks, not six)
    b.tube((0,0,0.024),(0,0,0.08),0.11,0.125,seg,'ceramic',cap0=True,cap1=False,smooth=True)
    b.tube((0,0,0.08),(0,0,0.25),0.125,0.148,seg,'ceramic',cap0=False,cap1=False,smooth=True)
    b.tube((0,0,0.25),(0,0,0.28),0.155,0.150,seg,'ceramic',cap0=False,cap1=True,smooth=True)
    # soil
    b.tube((0,0,0.22),(0,0,0.255),0.125,0.125,seg,'soil',cap0=False,cap1=True,smooth=True)
    # branching trunk: main stem + a side shoot
    tseg=sg(hi,7,12)
    b.tube((0,0,0.24),(0.00,0.01,0.50),0.020,0.016,tseg,'oak',cap0=True,cap1=False,smooth=True)
    b.tube((0.00,0.01,0.50),(0.02,-0.01,0.80),0.016,0.011,tseg,'oak',cap0=False,cap1=True,smooth=True)
    b.tube((0.00,0.01,0.46),( -0.05,0.04,0.68),0.012,0.009,tseg,'oak',cap0=False,cap1=True,smooth=True)
    # fuller rubber-plant canopy — overlapping ovate blades, short box petioles
    leaves=[
        # c, length, width, yaw, pitch, roll
        ((0.04,-0.01,0.80), 0.22,0.11,  15,  28,  6),
        ((-0.02,0.05,0.74), 0.20,0.10, -55,  32, -8),
        ((0.08,0.02,0.70), 0.19,0.09,  70,  20,-10),
        ((-0.08,0.00,0.68), 0.20,0.10,-130,  24,  4),
        ((0.03,-0.07,0.62), 0.17,0.08, 155,  18,  8),
        ((-0.04,0.07,0.64), 0.16,0.08, -20,  30,  0),
        ((0.07,-0.04,0.54), 0.16,0.08, 100,  22, -6),
        ((-0.06,-0.05,0.52), 0.15,0.07,-160,  16,  8),
        ((0.02,0.06,0.48), 0.14,0.07,  35,  28,  0),
        ((-0.02,-0.06,0.42), 0.13,0.06, 190,  20,  5),
        ((0.05,0.01,0.38), 0.12,0.06,  80,  25, -4),
        ((-0.05,0.03,0.36), 0.11,0.05, -80,  22,  6),
    ]
    from mathutils import Matrix, Vector
    for i,(c,ln,wd,yaw,pitch,roll) in enumerate(leaves):
        R=(Matrix.Rotation(math.radians(yaw),4,'Z') @
           Matrix.Rotation(math.radians(pitch),4,'X') @
           Matrix.Rotation(math.radians(roll),4,'Y'))
        # petioles only on the larger outer leaves (boxes are 12 tris each)
        if i<6:
            pet=Vector(c) - (R @ Vector((0.035,0,0)))
            b.box((pet.x,pet.y,pet.z),(0.008,0.008,0.055),'oak',
                  rz=math.radians(yaw), rx=math.radians(pitch))
        leaf_blade(b,c,ln,wd,0.003,yaw,pitch,roll)
        if hi:
            mid=Vector(c) + (R @ Vector((ln*0.45,0,0.002)))
            b.box((mid.x,mid.y,mid.z),(0.004,0.004,ln*0.85),'oak',
                  rz=math.radians(yaw), rx=math.radians(pitch))
    # pot stamp (unique bake)
    b.box((0,-0.148,0.14),(0.04,0.006,0.02),'badge')
    b.ccyl((0,0,0),0.17,0.28)

# ------------------------------------------------------------------ indoor_bin
def indoor_bin(b, hi=False):
    # pedal bin: proud rim, liner lip, foot pedal. Segs kept modest so the extras fit under 250.
    seg=sg(hi,10,18); R=0.15; H=0.52
    b.tube((0,0,0.0),(0,0,0.022),R+0.010,R+0.008,seg,'rubber',cap0=True,cap1=False,smooth=True)
    b.tube((0,0,0.020),(0,0,H-0.07),R,R,seg,'steel',cap0=False,cap1=False,smooth=True)
    # rolled rim, clearly proud of the body
    b.tube((0,0,H-0.07),(0,0,H-0.02),R+0.008,R+0.008,seg,'chrome',cap0=False,cap1=False,smooth=True)
    b.tube((0,0,H-0.028),(0,0,H-0.012),R+0.010,R-0.004,seg,'chrome',cap0=False,cap1=True,smooth=True)
    # black liner lip, visible inside the rim (near, not just high)
    b.tube((0,0,H-0.055),(0,0,H-0.022),R-0.014,R-0.010,seg,'plastic_black',cap0=False,cap1=True,smooth=True)
    # lid + a front flap that reads as a swing lid
    b.tube((0,0,H-0.014),(0,0,H+0.004),R-0.006,R-0.04,seg,'steel',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,H+0.002),(0,0,H+0.022),R-0.04,R*0.30,sg(hi,8,14),'steel',cap0=False,cap1=True,smooth=True)
    # hinge at the back
    b.tube((-0.04,R-0.01,H-0.01),(0.04,R-0.01,H-0.01),0.007,0.007,sg(hi,6,10),'chrome',cap0=False,cap1=False,smooth=True)
    b.box((0,R-0.01,H-0.02),(0.07,0.022,0.022),'steel')
    # foot pedal and lever on the customer side (-Y)
    b.box((0,-(R)-0.025,0.012),(0.06,0.045,0.014),'steel')  # pedal pad
    b.box((0,-(R)+0.02,0.028),(0.016,0.08,0.012),'steel')   # lever
    b.box((0,-(R)+0.08,0.04),(0.03,0.03,0.03),'steel')      # pivot housing
    b.box((0,-(R)+0.002,H*0.52),(0.05,0.004,0.03),'badge')
    b.ccyl((0,0,0),R+0.02,H+0.02)

# ------------------------------------------------------------------ drinks_fridge
def drinks_fridge(b, hi=False):
    W,D,H=0.78,0.72,2.00
    # cabinet
    b.box((0,0.02,0.08),(W,D-0.04,H-0.20),'paint_black',skip=('bottom',))
    # base / grill
    b.box((0,0.0,0.0),(W,D,0.10),'paint_black',skip=('bottom',))
    # grill slats
    for i in range(6):
        y=-D/2+0.04
        b.box((0,y,0.02+i*0.012),(W-0.12,0.02,0.006),'steel')
    # header merchandiser
    b.box((0,0,H-0.12),(W,D,0.12),'paint_navy')
    b.box((0,-(D/2)+0.01,H-0.12),(W-0.08,0.01,0.08),'label')  # unique header art
    # door frame (front -Y)
    fw=0.04
    # door frame is built as rails around the glass below
    if not hi:
        b.box((0,-(D/2)+0.008,0.20),(W-0.14,0.010,H-0.40),'goods')  # baked bottle rows + opaque glass
    # frame rails around the glass (sit proud)
    b.box((0,-(D/2)+0.004,0.12),(W-0.04,0.028,0.08),'steel')  # bottom rail
    b.box((0,-(D/2)+0.004,H-0.20),(W-0.04,0.028,0.08),'steel')  # top rail
    b.box((-(W/2)+0.025,-(D/2)+0.004,0.12),(0.05,0.028,H-0.24),'steel')
    b.box(((W/2)-0.025,-(D/2)+0.004,0.12),(0.05,0.028,H-0.24),'steel')
    # gasket strip
    b.box((0,-(D/2)+0.022,0.18),(W-0.16,0.006,H-0.36),'rubber')
    # handle (left, vertical)
    hx,hy=-(W/2)+0.02, -(D/2)-0.03
    b.tube((hx,hy,0.70),(hx,hy,1.35),0.012,0.012,sg(hi,8,14),'chrome',cap0=True,cap1=True,smooth=True)
    b.tube((hx,-(D/2)+0.01,0.70),(hx,hy,0.70),0.010,0.010,sg(hi,6,10),'chrome',cap0=True,cap1=True)
    b.tube((hx,-(D/2)+0.01,1.35),(hx,hy,1.35),0.010,0.010,sg(hi,6,10),'chrome',cap0=True,cap1=True)
    # hinges right
    for z in (0.30,1.00,1.65):
        b.box((W/2-0.01,-(D/2)+0.01,z),(0.03,0.04,0.08),'steel')
        if hi: screw(b,(W/2+0.005,-(D/2)+0.02,z+0.02),(1,0,0),True,'steel',0.003)
    # thermostat knob
    b.box((W/2-0.08,D/2-0.15,1.70),(0.06,0.04,0.08),'plastic_black')
    b.tube((W/2-0.08,D/2-0.13,1.74),(W/2-0.08,D/2-0.10,1.74),0.016,0.016,sg(hi,8,12),'plastic',cap0=False,cap1=True,smooth=True)
    # legs
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            b.tube((x,y,0.0),(x,y,0.08),0.018,0.016,sg(hi,6,10),'steel',cap0=True,cap1=True)
    # price channel lips on the door (near + hi)
    for z in (0.45,0.85,1.25,1.55):
        b.box((0,-(D/2)+0.016,z),(W-0.20,0.008,0.014),'plastic')
    if hi:
        # flat bottle / can rows 6 mm in front of the door card (inside the bake cage)
        bodies=('paint_navy','plastic_black','paint_cream','plastic','leaf','oak')
        y=-(D/2)+0.008-0.006
        for row,z in enumerate((0.30,0.58,0.92,1.28)):
            for col in range(6):
                x=-0.24+col*0.08
                key=bodies[(row+col)%len(bodies)]
                if row==1:
                    can_card(b,(x,y,z),h=0.12,w=0.054,body=key)
                else:
                    bottle_card(b,(x,y,z),h=0.24 if row else 0.20,w=0.046,body=key,cap='paint_cream')
    b.cbox((0,0,0),(W,D+0.04,H))

# ------------------------------------------------------------------ brochure_rack
def brochure_rack(b, hi=False):
    W,D,H=0.48,0.38,1.55
    # weighted base
    b.box((0,0,0.0),(W+0.04,D+0.04,0.04),'paint_black',skip=('bottom',))
    b.box((0,0,0.04),(W,D,0.03),'steel')
    # uprights (open ends hidden in base / header)
    for x in (-W/2+0.04,W/2-0.04):
        b.tube((x,0.04,0.07),(x,0.04,H-0.06),0.010,0.010,sg(hi,6,12),'steel',cap0=False,cap1=False,smooth=True)
    # header
    b.box((0,0.04,H-0.10),(W-0.02,0.04,0.10),'paint_cream')
    b.box((0,-0.005,H-0.10),(W-0.06,0.008,0.08),'label')
    # one continuous back panel (not four separate plates)
    b.box((0,0.06,0.28),(W-0.08,0.008,1.16),'paint_cream')
    # four pockets. Near only has a 2-tri goods card per pocket; cover art is high-poly bake.
    for i,z in enumerate((0.28,0.58,0.88,1.18)):
        b.box((0,-0.06,z),(W-0.10,0.22,0.006),'plastic')
        b.box((0,-0.16,z+0.02),(W-0.10,0.006,0.04),'plastic')
        for x in (-W/2+0.08,W/2-0.08):
            b.box((x,-0.05,z),(0.006,0.22,0.05),'plastic')
        gw,gh=W-0.16,0.16
        z0=z+0.012
        if hi:
            # cover + a couple of ruled bars, 5 mm in front of the near card, no occluding goods box
            cover=('paint_navy','leaf','paint_cream','plastic_black')[i]
            b.box((0,-0.125,z0),(gw-0.02,0.004,gh),cover)
            b.box((0,-0.128,z0+gh*0.72),(gw-0.06,0.003,0.024),'label')
            for k in range(3):
                b.box((0,-0.128,z0+0.03+k*0.03),(gw-0.08,0.003,0.008),'paint_black')
        else:
            # thin unique card (12 tris, reliable box UVs). 4×12=48, still under the 400 cap.
            b.box((0,-0.12,z0),(gw,0.003,gh),'goods')
    # box feet (cheaper than tubes, same read)
    for x in (-W/2+0.06,W/2-0.06):
        for y in (-D/2+0.06,D/2-0.06):
            b.box((x,y,0.0),(0.024,0.024,0.010),'rubber',skip=('bottom',))
    b.cbox((0,0,0),(W+0.04,D+0.04,H))

# ------------------------------------------------------------------ menu_board
def menu_board(b, hi=False):
    W,D,H=1.70,0.07,0.92
    fw=0.04
    # main frame
    b.box((0,0,0.0),(W,D,fw),'oak',skip=('bottom',))  # sill
    b.box((0,0,H-fw),(W,D,fw),'oak')
    b.box((-(W/2)+fw/2,0,0.0),(fw,D,H),'oak',skip=('bottom',))
    b.box(((W/2)-fw/2,0,0.0),(fw,D,H),'oak',skip=('bottom',))
    # back board
    b.box((0,D/2-0.006,fw),(W-2*fw,0.010,H-2*fw),'paint_cream')
    # two/three menu sheets (unique bake)
    gap=0.03
    pw=(W-2*fw-2*gap)/2
    for i,x in enumerate((-pw/2-gap/2, pw/2+gap/2)):
        if not hi:
            b.box((x,-0.002,fw+0.04),(pw,0.004,H-2*fw-0.08),'menu')
        # clips at top
        for ox in (-pw/2+0.06,pw/2-0.06):
            b.box((x+ox,-0.012,H-fw-0.03),(0.03,0.012,0.02),'steel')
    if hi:
        # typography 5 mm in front of the near menu cards (no sheet on hi, so rays hit the type)
        for i,x in enumerate((-pw/2-gap/2, pw/2+gap/2)):
            b.box((x,-0.007,H-fw-0.12),(pw-0.08,0.004,0.05),'paint_black')
            for k in range(7):
                b.box((x-pw*0.12,-0.007,H-fw-0.22-k*0.08),(pw*0.55,0.004,0.014),'paint_navy' if k==0 else 'paint_black')
                b.box((x+pw*0.28,-0.007,H-fw-0.22-k*0.08),(0.10,0.004,0.014),'leaf')
    # cornice light
    b.box((0,-0.01,H-0.01),(W-0.08,0.05,0.02),'steel')
    b.box((0,-0.02,H-0.025),(W-0.12,0.03,0.01),'plastic')
    # mounting plates on the back (flanges)
    for x in (-W/2+0.16,W/2-0.16):
        for z in (0.12,H-0.12):
            b.box((x,D/2+0.006,z),(0.08,0.008,0.08),'steel')
            if hi:
                for ox in (-0.025,0.025):
                    for oz in (-0.025,0.025):
                        screw(b,(x+ox,D/2+0.011,z+oz),(0,1,0),True,'steel',0.003)
    # keyhole / hanger slots
    if hi:
        for x in (-W/2+0.16,W/2-0.16):
            b.box((x,D/2+0.012,H-0.16),(0.016,0.004,0.024),'paint_black')
    b.cbox((0,0,0),(W,D+0.02,H))

# ceramic / soil / leaf / menu are unique or mapped below
# ------------------------------------------------------------------ registry
TR={
    'oak':('ti_wood',(0.875,0.875)),
    'walnut':('ti_wood',(0.875,0.875)),
    'lam':('ti_laminate',(0.875,0.875)),
    'steel':('ti_metal',(0.875,0.875)),
    'chrome':('ti_metal',(0.875,0.875)),
    'alum':('ti_metal',(0.875,0.875)),
    'brass':('ti_brass',(0.875,0.875)),
    'paint_cream':('ti_paint',(0.875,0.875)),
    'paint_black':('ti_paint',(0.875,0.875)),
    'paint_navy':('ti_paint',(0.875,0.875)),
    'fabric':('ti_fabric',(0.875,0.875)),
    'glass':('ti_glass',(0.875,0.875)),
    'plastic':('ti_plastic',(0.875,0.875)),
    'plastic_black':('ti_plastic',(0.875,0.875)),
    'rubber':('ti_plastic',(0.875,0.875)),
    'ceramic':('ti_paint',(0.875,0.875)),
    'leaf':('ti_paint',(0.875,0.875)),
    'soil':('ti_paint',(0.875,0.875)),
}
TINT={
    'oak':(1.00,0.96,0.90),
    'walnut':(0.62,0.45,0.32),
    'lam':(1.0,0.97,0.90),
    'steel':(1.0,1.0,1.0),
    'chrome':(1.15,1.16,1.18),
    'alum':(0.95,0.95,0.97),
    'brass':(1.0,1.0,1.0),
    'paint_cream':(1.0,0.96,0.88),
    'paint_black':(0.12,0.12,0.12),
    'paint_navy':(0.16,0.20,0.38),
    'fabric':(0.55,0.22,0.18),
    'glass':(1.0,1.0,1.0),
    'plastic':(0.92,0.92,0.90),
    'plastic_black':(0.12,0.12,0.13),
    'rubber':(0.10,0.10,0.10),
    'ceramic':(0.82,0.28,0.18),  # terracotta / glaze
    'leaf':(0.22,0.42,0.20),
    'soil':(0.22,0.16,0.10),
}
_C=dict(dir='props/indoor/shared',pdir='indoor_shared',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('shop_counter',shop_counter,'medium',900),
    _p('cash_register',cash_register,'small',500,side=96,dir='props/indoor/shared'),
    _p('wall_shelf',wall_shelf,'medium',1000),
    _p('gondola_aisle',gondola_aisle,'medium',1100),
    _p('display_table',display_table,'medium',800),
    _p('glass_display_case',glass_display_case,'medium',1100,side=96,cage=0.04,ray=0.12),
    _p('waiting_bench',waiting_bench,'small',500),
    _p('side_chair',side_chair,'small',550),
    _p('potted_plant',potted_plant,'small',400),
    _p('indoor_bin',indoor_bin,'tiny',250),
    _p('drinks_fridge',drinks_fridge,'medium',1100,side=128,cage=0.04,ray=0.12),
    _p('brochure_rack',brochure_rack,'small',400,cage=0.04,ray=0.12),
    _p('menu_board',menu_board,'small',400,side=128,mount='wall',cage=0.04,ray=0.12),
]
