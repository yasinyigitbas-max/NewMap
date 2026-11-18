"""Indoor food props — original geometry, page I, near+col only. No mid/far.

Approved 14: cafe_table, restaurant_table, cafe_chair, bar_stool, booth_bench,
espresso_machine, pastry_case, gelato_case, soda_fountain, bakery_shelf,
wine_backbar, kitchen_line, beer_taps, bar_counter.

Menu-board variants are baked art on the shared menu_board, not separate props.
Chairs and stools get collision. Unique merch lives in the bake (no unique
card on the high mesh; silhouettes sit inside the cage).
"""
import math
from mathutils import Vector, Matrix
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT,
)

def footring(b, z, R, r=0.010, seg=8, n=10, key='chrome'):
    """Closed footrest ring from short tubes (ends hide in the next segment)."""
    pts=[]
    for i in range(n):
        a0=2*math.pi*i/n; a1=2*math.pi*(i+1)/n
        b.tube((R*math.cos(a0),R*math.sin(a0),z),
               (R*math.cos(a1),R*math.sin(a1),z),
               r,r,seg,key,cap0=False,cap1=False,smooth=True)

def burner(b, c, hi=False, R=0.09):
    x,y,z=c
    b.tube((x,y,z),(x,y,z+0.008),R,R,sg(hi,10,16),'iron' if False else 'steel',cap0=True,cap1=False,smooth=True)
    # grate bars
    for i in range(3):
        o=-R*0.55+i*R*0.55
        b.box((x+o,y,z+0.010),(0.008,R*1.6,0.006),'steel')
        b.box((x,y+o,z+0.010),(R*1.6,0.008,0.006),'steel')
    # ring
    b.tube((x,y,z+0.004),(x,y,z+0.012),R*0.55,R*0.55,sg(hi,8,14),'steel',cap0=False,cap1=True,smooth=True)

# ------------------------------------------------------------------ cafe_table
def cafe_table(b, hi=False):
    R,H,th=0.38,0.75,0.032
    seg=sg(hi,16,24)
    # round top + drip edge
    b.tube((0,0,H-th),(0,0,H),R,R,seg,'oak',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,H-th-0.010),(0,0,H-th),R-0.008,R-0.004,seg,'oak',cap0=False,cap1=False,smooth=True)
    # underside spider / hook
    b.box((0,0,H-th-0.02),(0.16,0.16,0.016),'steel')
    if hi:
        for a in (0,90,180,270):
            screw(b,(0.05*math.cos(math.radians(a)),0.05*math.sin(math.radians(a)),H-th-0.02),(0,0,-1),True,'steel',0.003)
    # pedestal
    b.tube((0,0,0.10),(0,0,H-th-0.02),0.032,0.028,sg(hi,10,16),'steel',cap0=False,cap1=True,smooth=True)
    # collar
    b.tube((0,0,H-th-0.06),(0,0,H-th-0.02),0.045,0.045,sg(hi,10,16),'steel',cap0=False,cap1=True,smooth=True)
    # mid footring
    b.tube((0,0,0.22),(0,0,0.25),0.14,0.14,sg(hi,12,18),'chrome',cap0=True,cap1=True,smooth=True)
    b.tube((0,0,0.22),(0,0,0.28),0.012,0.012,sg(hi,8,12),'chrome',cap0=False,cap1=False,smooth=True)
    # spreading base (two disks) + four short feet
    b.tube((0,0,0.04),(0,0,0.10),0.16,0.05,sg(hi,12,20),'steel',cap0=False,cap1=False,smooth=True)
    b.tube((0,0,0.016),(0,0,0.04),0.20,0.16,sg(hi,12,20),'steel',cap0=False,cap1=False,smooth=True)
    for i in range(4):
        a=math.radians(45+i*90)
        x,y=0.16*math.cos(a),0.16*math.sin(a)
        b.box((x,y,0.0),(0.04,0.04,0.018),'steel',skip=('bottom',))
        b.tube((x,y,0.0),(x,y,0.006),0.014,0.014,sg(hi,6,10),'rubber',cap0=True,cap1=False)
    maker_plate(b,(0,-0.18,0.06),hi,w=0.06,h=0.016)
    b.ccyl((0,0,0),R+0.01,H)

# ------------------------------------------------------------------ restaurant_table
def restaurant_table(b, hi=False):
    W,D,H=1.20,0.80,0.76; th=0.032
    b.box((0,0,H-th),(W,D,th),'walnut')
    b.box((0,0,H-th-0.012),(W-0.03,D-0.03,0.012),'walnut')
    ah=0.10
    for (c,sz) in (
        ((0,-(D/2)+0.03,H-th-ah),(W-0.14,0.028,ah)),
        ((0,(D/2)-0.03,H-th-ah),(W-0.14,0.028,ah)),
        ((-(W/2)+0.03,0,H-th-ah),(0.028,D-0.14,ah)),
        (((W/2)-0.03,0,H-th-ah),(0.028,D-0.14,ah)),
    ):
        b.box(c,sz,'walnut')
    b.box((0,-(D/2)+0.032,H-th-ah-0.008),(W-0.16,0.022,0.010),'walnut')
    lw0,lw1=0.058,0.042
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            mid=(H-th-ah)*0.5
            b.box((x,y,0.05),(lw0,lw0,mid-0.05),'walnut',skip=('bottom',))
            b.box((x,y,mid-0.015),(lw0+0.008,lw0+0.008,0.03),'walnut')
            b.box((x,y,mid+0.015),(lw1,lw1,H-th-ah-mid-0.015),'walnut')
            b.box((x,y,0.0),(lw0+0.006,lw0+0.006,0.05),'brass',skip=('bottom',))
            b.tube((x,y,0.0),(x,y,0.008),0.022,0.022,sg(hi,6,10),'rubber',cap0=True,cap1=False)
            b.box((x,y,H-th-ah-0.02),(0.065,0.065,0.02),'walnut')
    # H stretcher
    b.box((0,0,0.22),(W-0.22,0.028,0.036),'walnut')
    b.box((-(W/2)+0.10,0,0.22),(0.028,D-0.24,0.036),'walnut')
    b.box(((W/2)-0.10,0,0.22),(0.028,D-0.24,0.036),'walnut')
    maker_plate(b,(0,-(D/2)+0.02,H-th-0.06),hi,w=0.07,h=0.016)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ cafe_chair
def cafe_chair(b, hi=False):
    # metal bistro chair, round padded seat, hoop back — distinct from the wood side_chair
    Rseat,sh,H=0.21,0.46,0.88
    seg=sg(hi,12,18)
    # seat pan + cushion + welt
    b.tube((0,0,sh-0.02),(0,0,sh+0.006),Rseat+0.01,Rseat+0.01,seg,'steel',cap0=True,cap1=False,smooth=True)
    b.tube((0,0,sh),(0,0,sh+0.04),Rseat-0.01,Rseat-0.01,seg,'fabric',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,sh+0.036),(0,0,sh+0.048),Rseat,Rseat,seg,'fabric',cap0=False,cap1=True,smooth=True)
    # four splayed tube legs
    reach=0.22
    for i,a in enumerate((45,135,225,315)):
        rad=math.radians(a)
        x0,y0=0.10*math.cos(rad),0.10*math.sin(rad)
        x1,y1=reach*math.cos(rad),reach*math.sin(rad)
        b.tube((x0,y0,sh-0.02),(x1,y1,0.016),0.012,0.012,sg(hi,8,12),'steel',cap0=False,cap1=False,smooth=True)
        b.tube((x1,y1,0.0),(x1,y1,0.016),0.014,0.014,sg(hi,6,10),'plastic_black',cap0=True,cap1=False)
    # footring / side stretchers, slightly below mid
    footring(b,0.20,0.16,r=0.007,seg=sg(hi,6,10),n=8,key='steel')
    # hoop back (U made of tubes) plus two vertical stays
    by=0.16
    b.tube((-0.13,by,sh),( -0.13,by+0.03,H-0.04),0.010,0.010,sg(hi,8,12),'steel',cap0=True,cap1=False,smooth=True)
    b.tube((0.13,by,sh),(0.13,by+0.03,H-0.04),0.010,0.010,sg(hi,8,12),'steel',cap0=True,cap1=False,smooth=True)
    # crest hoop
    for i in range(6):
        a0=math.pi*i/6; a1=math.pi*(i+1)/6
        p0=(-0.13*math.cos(a0), by+0.03+0.02*math.sin(a0), (H-0.04)+0.13*math.sin(a0))
        p1=(-0.13*math.cos(a1), by+0.03+0.02*math.sin(a1), (H-0.04)+0.13*math.sin(a1))
        # simpler: a flat crest rail + two small arcs as boxes would be cheaper
    # crest rail and two slats (readable hoop-back without a dense sweep)
    b.tube((-0.13,by+0.03,H-0.04),(0.13,by+0.03,H-0.04),0.010,0.010,sg(hi,8,12),'steel',cap0=True,cap1=True,smooth=True)
    b.tube((-0.13,by+0.03,H-0.04),(-0.04,by+0.05,H+0.02),0.009,0.009,sg(hi,6,10),'steel',cap0=False,cap1=False,smooth=True)
    b.tube((0.13,by+0.03,H-0.04),(0.04,by+0.05,H+0.02),0.009,0.009,sg(hi,6,10),'steel',cap0=False,cap1=False,smooth=True)
    b.tube((-0.04,by+0.05,H+0.02),(0.04,by+0.05,H+0.02),0.009,0.009,sg(hi,6,10),'steel',cap0=True,cap1=True,smooth=True)
    for x in (-0.06,0.06):
        b.tube((x,by+0.01,sh+0.04),(x,by+0.03,H-0.06),0.007,0.007,sg(hi,6,10),'steel',cap0=True,cap1=True,smooth=True)
    maker_plate(b,(0,-0.20,sh-0.03),hi,w=0.05,h=0.014)
    b.cbox((0,0,0),(reach*2+0.04,reach*2+0.04,H+0.03))

# ------------------------------------------------------------------ bar_stool
def bar_stool(b, hi=False):
    R,sh,H=0.18,0.75,0.90  # low back
    seg=sg(hi,12,18)
    # padded round seat
    b.tube((0,0,sh-0.024),(0,0,sh+0.004),R+0.008,R+0.008,seg,'steel',cap0=True,cap1=False,smooth=True)
    b.tube((0,0,sh-0.004),(0,0,sh+0.04),R-0.008,R-0.008,seg,'fabric',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,sh+0.036),(0,0,sh+0.048),R,R,seg,'fabric',cap0=False,cap1=True,smooth=True)
    # low backrest
    b.box((0,0.12,sh+0.04),(0.22,0.04,0.04),'steel')
    b.box((0,0.13,sh+0.08),(0.20,0.03,0.10),'fabric')
    b.box((0,0.13,H-0.02),(0.22,0.04,0.03),'steel')
    for x in (-0.08,0.08):
        b.tube((x,0.10,sh),(x,0.13,H-0.02),0.008,0.008,sg(hi,6,10),'steel',cap0=True,cap1=True,smooth=True)
    # chrome column + collar
    b.tube((0,0,0.12),(0,0,sh-0.024),0.028,0.028,sg(hi,10,16),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube((0,0,sh-0.06),(0,0,sh-0.02),0.04,0.04,sg(hi,10,16),'chrome',cap0=False,cap1=True,smooth=True)
    # footrest ring
    footring(b,0.32,0.16,r=0.009,seg=sg(hi,6,10),n=8,key='chrome')
    # four braces from column to ring
    for a in (0,90,180,270):
        rad=math.radians(a)
        b.tube((0.028*math.cos(rad),0.028*math.sin(rad),0.40),
               (0.16*math.cos(rad),0.16*math.sin(rad),0.32),
               0.006,0.006,sg(hi,6,8),'chrome',cap0=False,cap1=False,smooth=True)
    # weighted disk base + rubber ring
    b.tube((0,0,0.016),(0,0,0.12),0.18,0.05,sg(hi,12,20),'steel',cap0=False,cap1=False,smooth=True)
    b.tube((0,0,0.0),(0,0,0.018),0.20,0.18,sg(hi,12,20),'steel',cap0=True,cap1=False,smooth=True)
    b.tube((0,0,0.0),(0,0,0.008),0.20,0.20,sg(hi,12,18),'rubber',cap0=True,cap1=False,smooth=True)
    maker_plate(b,(0,-0.17,0.06),hi,w=0.05,h=0.014)
    b.ccyl((0,0,0),0.22,H)

# ------------------------------------------------------------------ booth_bench
def booth_bench(b, hi=False):
    W,D,H=1.30,0.62,1.05
    sh=0.45
    # plinth / kick
    b.box((0,0.02,0.0),(W,D-0.04,0.10),'paint_black',skip=('bottom',))
    # body under the seat
    b.box((0,0.02,0.10),(W-0.04,D-0.08,sh-0.14),'paint_cream',skip=('bottom',))
    # seat cushion + piping + bullnose
    b.box((0,-0.02,sh-0.04),(W-0.08,D-0.12,0.04),'walnut')
    b.box((0,-0.03,sh),(W-0.12,D-0.16,0.08),'fabric')
    b.box((0,-0.03,sh+0.076),(W-0.10,D-0.14,0.010),'fabric')
    b.box((0,-(D/2)+0.05,sh+0.01),(W-0.16,0.024,0.06),'fabric')
    # tall back, two cushions, wood cap and end panels
    b.box((0,(D/2)-0.06,sh),(W-0.08,0.08,H-sh-0.04),'paint_cream')
    gap=0.02; bw=(W-0.16-gap)/2
    for x in (-(bw+gap)/2,(bw+gap)/2):
        b.box((x,(D/2)-0.10,sh+0.04),(bw,0.07,H-sh-0.14),'fabric')
    b.box((0,(D/2)-0.08,sh+0.06),(0.016,0.05,H-sh-0.18),'walnut')
    b.box((0,(D/2)-0.07,H-0.05),(W-0.06,0.08,0.05),'walnut')  # cap rail
    # back panel dados so the rear is not a blank slab
    for z in (0.20,0.55,0.85):
        b.box((0,(D/2)+0.008,z),(W-0.16,0.016,0.03),'walnut')
    # end panels (full height, like a diner booth)
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.02,0.0,0.0),(0.04,D,H),'walnut',skip=('bottom',))
        b.box((x+sgn*0.04,-(D/2)+0.02,sh),(0.02,0.04,0.04),'walnut')  # arm cap
    # mid front stretcher already in body; add a stitching welt
    b.box((0,-0.03,sh+0.01),(0.012,D-0.20,0.06),'walnut')
    # front panel reveals
    b.box((0,-(D/2)+0.03,0.22),(W-0.16,0.008,0.008),'paint_black')
    for x in (-0.32,0.32):
        b.box((x,-(D/2)+0.03,0.14),(0.008,0.008,0.26),'paint_black')
    # coat hooks on the end panels
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.tube((x+sgn*0.05,(D/2)-0.16,0.92),(x+sgn*0.09,(D/2)-0.16,0.92),0.008,0.008,sg(hi,6,10),'brass',cap0=True,cap1=True)
        b.tube((x+sgn*0.09,(D/2)-0.16,0.92),(x+sgn*0.09,(D/2)-0.16,0.86),0.007,0.007,sg(hi,6,10),'brass',cap0=False,cap1=True)
    maker_plate(b,(0,-(D/2)+0.03,0.16),hi,w=0.06,h=0.016)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ espresso_machine
def espresso_machine(b, hi=False):
    W,D,H=0.72,0.54,0.70
    # main body
    b.box((0,0.01,0.06),(W,D-0.02,H-0.14),'paint_cream',skip=('bottom',))
    # base / drip tray
    b.box((0,0.0,0.0),(W+0.02,D,0.06),'steel',skip=('bottom',))
    b.box((0,-(D/2)+0.06,0.06),(W-0.10,0.16,0.02),'steel')  # tray
    # grate bars on the tray
    for i in range(7):
        x=-0.24+i*0.08
        b.box((x,-(D/2)+0.06,0.082),(0.010,0.14,0.006),'steel')
    # cup rail / warming tray on top
    b.box((0,0.0,H-0.08),(W,D,0.08),'paint_cream')
    b.box((0,0.0,H-0.02),(W-0.08,D-0.08,0.016),'steel')
    for i in range(5):
        x=-0.24+i*0.12
        b.box((x,0.0,H-0.004),(0.08,0.16,0.006),'paint_cream')  # cups as blocks on hi only would be better
    # two group heads on the customer/front (-Y is barista? usually barista faces +Y / groups face -Y toward barista... )
    # barista stands at -Y, groups face -Y
    for x in (-0.16,0.16):
        b.box((x,-(D/2)+0.04,0.38),(0.12,0.10,0.10),'steel')  # group housing
        b.tube((x,-(D/2)+0.00,0.36),(x,-(D/2)-0.06,0.30),0.018,0.018,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
        # portafilter
        b.tube((x,-(D/2)-0.04,0.30),(x,-(D/2)-0.12,0.26),0.028,0.028,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
        b.box((x,-(D/2)-0.16,0.26),(0.018,0.10,0.018),'steel')  # handle
        # shower / spouts
        b.tube((x-0.015,-(D/2)-0.05,0.26),(x-0.015,-(D/2)-0.05,0.18),0.006,0.006,sg(hi,6,8),'chrome',cap0=False,cap1=True)
        b.tube((x+0.015,-(D/2)-0.05,0.26),(x+0.015,-(D/2)-0.05,0.18),0.006,0.006,sg(hi,6,8),'chrome',cap0=False,cap1=True)
    # steam wand left, hot-water wand right
    for x,yaw in ((-W/2+0.04,-20),(W/2-0.04,20)):
        b.tube((x,-(D/2)+0.08,0.50),(x,-(D/2)-0.08,0.32),0.008,0.008,sg(hi,6,10),'chrome',cap0=True,cap1=True,smooth=True)
        b.tube((x,-(D/2)-0.08,0.32),(x,-(D/2)-0.10,0.28),0.010,0.010,sg(hi,6,8),'chrome',cap0=False,cap1=True,smooth=True)
    # gauges (unique)
    for x in (-0.10,0.10):
        b.tube((x,-(D/2)-0.004,0.56),(x,-(D/2)-0.010,0.56),0.028,0.028,sg(hi,10,14),'chrome',cap0=False,cap1=True,smooth=True)
        b.box((x,-(D/2)-0.012,0.545),(0.04,0.004,0.04),'badge')
    # button bank
    b.box((0,-(D/2)-0.004,0.48),(0.20,0.008,0.04),'plastic_black')
    if hi:
        for i in range(4):
            b.box((-0.075+i*0.05,-(D/2)-0.010,0.48),(0.028,0.006,0.018),'plastic')
    # hopper / grinder on the right rear
    b.tube((W/2-0.12,D/2-0.14,H-0.08),(W/2-0.12,D/2-0.14,H+0.16),0.06,0.055,sg(hi,10,16),'plastic_black',cap0=False,cap1=True,smooth=True)
    b.tube((W/2-0.12,D/2-0.14,H+0.14),(W/2-0.12,D/2-0.14,H+0.22),0.07,0.02,sg(hi,10,16),'plastic_black',cap0=False,cap1=True,smooth=True)
    # rear water reservoir — also recentres the footprint (portafilters sit forward)
    b.box((0,D/2+0.08,0.08),(W-0.12,0.22,H-0.16),'paint_cream',skip=('bottom',))
    b.box((0,D/2+0.08,H-0.10),(W-0.16,0.16,0.04),'steel')
    # steam knob
    for x in (-W/2+0.06,W/2-0.06):
        b.tube((x,-(D/2)+0.04,0.62),(x,-(D/2)-0.03,0.62),0.016,0.016,sg(hi,8,12),'plastic_black',cap0=False,cap1=True,smooth=True)
    for x in (-W/2+0.06,W/2-0.06):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W+0.04,D+0.16,H+0.22))

# ------------------------------------------------------------------ pastry_case
def pastry_case(b, hi=False):
    W,D,H=1.40,0.70,1.20
    pl,fw=0.10,0.032
    b.box((0,0,0.0),(W,D,pl),'paint_cream',skip=('bottom',))
    b.box((0,0,pl),(W-0.04,D-0.04,0.04),'paint_cream')
    # corner posts
    for x in (-W/2+fw/2,W/2-fw/2):
        for y in (-D/2+fw/2,D/2-fw/2):
            b.box((x,y,pl),(fw,fw,H-pl-0.05),'brass',skip=('bottom',))
    for z in (pl+0.02, 0.55, 0.88, H-0.05):
        b.box((0,-(D/2)+fw/2,z),(W-2*fw,fw,0.022),'brass')
        b.box((0,(D/2)-fw/2,z),(W-2*fw,fw,0.022),'brass')
        b.box((-(W/2)+fw/2,0,z),(fw,D-2*fw,0.022),'brass')
        b.box(((W/2)-fw/2,0,z),(fw,D-2*fw,0.022),'brass')
    # sloped front: two glass steps + a goods card on near
    if not hi:
        b.box((0,-(D/2)+0.04,pl+0.06),(W-2*fw-0.01,0.010,H-pl-0.16),'goods')
    for x,sgn in ((-W/2+fw*0.45,1),(W/2-fw*0.45,-1)):
        b.box((x,0,pl+0.04),(0.008,D-2*fw,H-pl-0.14),'glass')
    # rear staff access panel
    b.box((0,(D/2)-0.012,pl+0.04),(W-2*fw,0.016,H-pl-0.14),'paint_cream')
    # shelves
    for z in (0.42,0.74):
        b.box((0,0,z),(W-0.12,D-0.14,0.010),'glass')
    # cornice light
    b.box((0,0,H-0.05),(W,D,0.05),'paint_cream')
    b.box((0,-0.04,H-0.06),(W-0.12,0.22,0.012),'steel')
    # lock + hinges
    b.box((W/2-0.10,-(D/2)-0.004,0.88),(0.022,0.008,0.022),'badge')
    for z in (0.30,1.00):
        b.box((W/2-0.01,-(D/2)+0.01,z),(0.016,0.03,0.05),'brass')
    if hi:
        # pastry silhouettes in the front plane, inside the cage
        y=-(D/2)+0.04-0.006
        bodies=('paint_cream','oak','leaf','paint_navy','plastic','brass')
        for si,z in enumerate((0.44,0.76)):
            for col in range(6):
                x=-0.50+col*0.20
                key=bodies[(si+col)%len(bodies)]
                # tart / loaf / cake slab
                if col%3==0:
                    b.tube((x,y,z),(x,y,z+0.06),0.04,0.04,8,key,cap0=True,cap1=True,smooth=True)
                else:
                    b.box((x,y,z),(0.10,0.004,0.06),key)
                b.box((x,y-0.003,z+0.02),(0.06,0.003,0.02),'label')
        for x in (-W/2+0.08,W/2-0.08):
            for yy in (-D/2+0.08,D/2-0.08):
                leveler(b,(x,yy),True)
    else:
        for x in (-W/2+0.08,W/2-0.08):
            for yy in (-D/2+0.08,D/2-0.08):
                leveler(b,(x,yy),False)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ gelato_case
def gelato_case(b, hi=False):
    W,D,H=1.60,0.78,1.15
    # lower cabinet only — the well above is open at the front so tubs can be seen
    b.box((0,0.0,0.0),(W,D,0.52),'paint_cream',skip=('bottom',))
    b.box((0,0.0,0.0),(W+0.02,D,0.08),'paint_black',skip=('bottom',))
    # well floor, back and end walls
    b.box((0,0.04,0.52),(W-0.10,D-0.16,0.03),'steel')
    b.box((0,D/2-0.03,0.52),(W-0.08,0.06,0.38),'paint_cream')
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.03,0.02,0.52),(0.06,D-0.04,0.38),'paint_cream')
    # serving-deck lip at the front of the well (does not cover the tubs)
    b.box((0,-(D/2)+0.04,0.52),(W-0.10,0.10,0.05),'steel')
    b.box((0,-(D/2)+0.04,0.57),(W-0.16,0.08,0.012),'steel')
    # tubs face -Y, mid-well, fully visible through the open front
    if not hi:
        b.box((0,0.02,0.70),(W-0.22,0.010,0.28),'goods')
    if hi:
        y=0.02-0.006
        bodies=('paint_cream','oak','leaf','paint_navy','plastic','brass','fabric','paint_black')
        for col in range(6):
            x=-0.60+col*0.24
            b.box((x,y,0.68),(0.20,0.004,0.22),bodies[col%len(bodies)])
            b.box((x,y-0.003,0.80),(0.16,0.003,0.06),'label')
            b.box((x,y+0.02,0.76),(0.18,0.004,0.14),bodies[(col+3)%len(bodies)])
    # top canopy only — no front glass slab in front of the tubs
    b.box((0,0.10,0.96),(W-0.08,0.50,0.06),'glass')
    b.box((0,0.0,H-0.04),(W,D-0.08,0.08),'paint_cream')  # header
    b.box((0,-(D/2)+0.06,H-0.05),(W-0.20,0.02,0.04),'label')
    # canopy side returns
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.03,0.04,0.90),(0.04,D-0.12,0.20),'paint_cream')
    # side seams + rear kick vents so the cabinet is not a plain box
    for z in (0.16,0.34):
        b.box((0,-(D/2)+0.01,z),(W-0.16,0.012,0.012),'paint_cream')
    for i in range(5):
        b.box((0,D/2-0.01,0.10+i*0.03),(W-0.30,0.016,0.012),'steel')
    # scoop / water dip on the right lip
    b.box((W/2-0.16,-(D/2)+0.06,0.57),(0.14,0.10,0.06),'steel')
    b.tube((W/2-0.16,-(D/2)+0.06,0.63),(W/2-0.16,-(D/2)+0.06,0.70),0.04,0.04,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
    for x in (-W/2+0.10,W/2-0.10):
        for y in (-D/2+0.10,D/2-0.10):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ soda_fountain
def soda_fountain(b, hi=False):
    W,D,H=0.70,0.62,1.15
    b.box((0,0.0,0.0),(W,D,0.90),'paint_navy',skip=('bottom',))
    b.box((0,0.0,0.90),(W,D,0.08),'steel')
    # merchandiser header
    b.box((0,0.0,0.98),(W,D,0.17),'paint_navy')
    b.box((0,-(D/2)+0.01,1.02),(W-0.10,0.01,0.10),'label')
    # drip grill
    b.box((0,-(D/2)+0.10,0.90),(W-0.12,0.22,0.02),'steel')
    for i in range(6):
        b.box((-0.22+i*0.09,-(D/2)+0.10,0.922),(0.012,0.20,0.006),'steel')
    # ice / bin lid
    b.box((0,0.08,0.90),(0.36,0.28,0.04),'steel')
    b.box((0,0.08,0.94),(0.12,0.06,0.02),'plastic_black')  # handle
    # valve bank — 6 nozzles
    for i,x in enumerate((-0.22,-0.13,-0.04,0.05,0.14,0.23)):
        b.box((x,-(D/2)+0.04,0.96),(0.05,0.06,0.08),'chrome')
        b.tube((x,-(D/2)+0.00,0.96),(x,-(D/2)-0.04,0.88),0.008,0.008,sg(hi,6,10),'chrome',cap0=False,cap1=True,smooth=True)
        b.box((x,-(D/2)+0.01,1.04),(0.04,0.04,0.03),'plastic')  # button
        if hi:
            b.box((x,-(D/2)-0.005,1.03),(0.03,0.004,0.02),'label')
    # cup wells / lid caddy on the right
    b.tube((W/2-0.10,D/2-0.14,0.90),(W/2-0.10,D/2-0.14,1.02),0.05,0.05,sg(hi,10,14),'plastic',cap0=True,cap1=True,smooth=True)
    b.tube((W/2-0.10,D/2-0.14,1.02),(W/2-0.10,D/2-0.14,1.16),0.055,0.04,sg(hi,10,14),'plastic',cap0=False,cap1=True,smooth=True)
    # kick / vent
    b.box((0,-(D/2)+0.02,0.0),(W-0.08,0.04,0.10),'paint_black',skip=('bottom',))
    for i in range(4):
        b.box((0,-(D/2)+0.04,0.02+i*0.018),(W-0.16,0.02,0.008),'steel')
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.08,D/2-0.08):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D+0.06,H+0.02))

# ------------------------------------------------------------------ bakery_shelf
def bakery_shelf(b, hi=False):
    W,D,H=1.20,0.42,2.00
    # standards + end panels
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.02,0.0,0.08),(0.04,D,H-0.16),'oak',skip=('bottom',))
    b.box((0,D/2-0.02,0.08),(W-0.06,0.016,H-0.16),'paint_cream')  # back
    b.box((0,0.0,0.0),(W,D,0.10),'oak',skip=('bottom',))  # kick
    b.box((0,0.0,H-0.08),(W,D,0.08),'oak')  # cornice
    b.box((0,-0.01,H-0.12),(W-0.04,D-0.04,0.04),'oak')
    # mid upright
    b.box((0,0.0,0.10),(0.03,D-0.04,H-0.20),'oak')
    zs=(0.28,0.70,1.12,1.54)
    for z in zs:
        b.box((0,-0.01,z),(W-0.10,D-0.06,0.022),'oak')
        b.box((0,-D/2+0.02,z-0.018),(W-0.14,0.014,0.020),'plastic')  # price lip
        # close-in cream backer so the bay is not a black cavity
        b.box((0,0.06,z+0.022),(W-0.14,0.04,0.36),'paint_cream')
        if not hi:
            # unique loaf card along the shelf front
            b.box((0,-D/2+0.04,z+0.01),(W-0.16,0.008,0.14),'goods')
    if hi:
        y=-D/2+0.04-0.006
        bodies=('oak','paint_cream','walnut','plastic')
        for si,z in enumerate((0.30,0.72,1.14,1.56)):
            for col in range(5):
                x=-0.44+col*0.22
                key=bodies[(si+col)%len(bodies)]
                b.box((x,y,z),(0.16,0.004,0.10),key)  # loaf
                b.box((x,y-0.003,z+0.04),(0.10,0.003,0.03),'label')
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.06,D/2-0.06):
            leveler(b,(x,y),hi)
    maker_plate(b,(0,-(D/2)+0.01,0.04),hi,w=0.08,h=0.018)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ wine_backbar
def wine_backbar(b, hi=False):
    W,D,H=1.60,0.40,2.10
    # cabinet carcass
    b.box((0,0.0,0.0),(W,D,0.12),'walnut',skip=('bottom',))
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.025,0.0,0.12),(0.05,D,H-0.20),'walnut',skip=('bottom',))
    b.box((0,D/2-0.012,0.12),(W-0.10,0.016,H-0.22),'paint_cream')  # back (could read as opaque glass)
    b.box((0,0.0,H-0.08),(W,D,0.08),'walnut')  # cornice
    # lower cupboards
    b.box((0,0.0,0.12),(W-0.10,D,0.48),'walnut',skip=('bottom',))
    for x in (-0.40,0.40):
        b.box((x,-(D/2)+0.01,0.20),(0.36,0.016,0.32),'walnut')
        b.box((x,-(D/2)-0.006,0.36),(0.10,0.010,0.012),'brass')
    # mid work / glass rail
    b.box((0,0.0,0.60),(W-0.08,D,0.04),'walnut')
    b.tube((-W/2+0.10,-(D/2)+0.06,0.72),(W/2-0.10,-(D/2)+0.06,0.72),0.008,0.008,sg(hi,6,10),'chrome',cap0=True,cap1=True,smooth=True)
    # shelves behind
    for z in (0.90,1.20,1.50,1.80):
        b.box((0,0.0,z),(W-0.14,D-0.08,0.016),'oak')
    # upright dividers
    for x in (-0.50,-0.16,0.16,0.50):
        b.box((x,0.0,0.66),(0.016,D-0.06,H-0.66-0.12),'oak')
    # one unique card per row so the bottle bake stays readable
    for z in (0.72,1.02,1.32,1.62,1.88):
        if not hi:
            b.box((0,-(D/2)+0.02,z),(W-0.16,0.008,0.20),'goods')
    if hi:
        y=-(D/2)+0.02-0.006
        bodies=('paint_navy','leaf','oak','paint_cream','plastic_black','brass')
        for row,z in enumerate((0.74,1.04,1.34,1.64,1.90)):
            for col in range(8):
                x=-0.64+col*0.18
                bottle_card(b,(x,y,z),h=0.18,w=0.04,body=bodies[(row+col)%len(bodies)],cap='brass')
    for x in (-W/2+0.08,W/2-0.08):
        for y in (-D/2+0.06,D/2-0.06):
            leveler(b,(x,y),hi)
    maker_plate(b,(0,-(D/2)+0.01,0.06),hi,w=0.08,h=0.016)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ kitchen_line
def kitchen_line(b, hi=False):
    # 2.2 m cook line: range, oven, backsplash, overshelf / pass, short hood
    W,D,H=2.20,0.80,2.00
    # body
    b.box((0,0.02,0.0),(W,D-0.04,0.90),'steel',skip=('bottom',))
    b.box((0,0.0,0.0),(W+0.02,D,0.10),'paint_black',skip=('bottom',))
    # splash
    b.box((0,D/2-0.03,0.90),(W,0.06,0.45),'steel')
    # cooktop
    b.box((0,0.0,0.90),(W-0.06,D-0.08,0.04),'steel')
    # six burners in two rows
    for row,y in enumerate((-0.16,0.12)):
        for col in range(3):
            x=-0.70+col*0.70
            burner(b,(x,y,0.94),hi,R=0.10)
    # oven doors (two)
    for x in (-0.55,0.55):
        b.box((x,-(D/2)+0.01,0.12),(0.90,0.02,0.70),'steel')
        b.box((x,-(D/2)+0.00,0.14),(0.80,0.016,0.54),'paint_black')  # glass window, opaque
        b.box((x,-(D/2)-0.025,0.70),(0.36,0.018,0.020),'steel')  # handle
        for hx in (x-0.14,x+0.14):
            b.tube((hx,-(D/2)+0.01,0.70),(hx,-(D/2)-0.03,0.70),0.007,0.007,sg(hi,6,10),'steel',cap0=True,cap1=True)
        # hinges
        for z in (0.18,0.70):
            b.box((x+0.42,-(D/2)+0.01,z),(0.04,0.03,0.06),'steel')
    # knobs under the cooktop front
    for i in range(6):
        x=-0.85+i*0.34
        b.tube((x,-(D/2)+0.02,0.84),(x,-(D/2)-0.02,0.84),0.016,0.016,sg(hi,8,12),'plastic_black',cap0=False,cap1=True,smooth=True)
    # overshelf / pass
    for z in (1.35,1.62):
        b.box((0,D/2-0.16,z),(W-0.10,0.28,0.020),'steel')
    for x in (-W/2+0.06,W/2-0.06):
        b.box((x,D/2-0.16,0.90),(0.03,0.04,0.80),'steel')
    # pot rail
    b.tube((-W/2+0.12,D/2-0.30,1.85),(W/2-0.12,D/2-0.30,1.85),0.010,0.010,sg(hi,6,10),'chrome',cap0=True,cap1=True,smooth=True)
    if hi:
        for i,x in enumerate((-0.6,-0.2,0.2,0.6)):
            b.tube((x,D/2-0.30,1.85),(x,D/2-0.30,1.70),0.005,0.005,6,'chrome',cap0=True,cap1=True)
            b.box((x,D/2-0.30,1.62),(0.18,0.18,0.08),'steel')  # pot
    # short hood canopy
    b.box((0,0.04,1.88),(W-0.04,D-0.12,0.08),'steel')
    b.box((0,0.04,1.80),(W-0.20,D-0.28,0.08),'paint_black')  # filters
    b.box((0,D/2-0.16,H-0.06),(0.36,0.20,0.12),'steel')  # duct stub
    # towel bar on the front rail
    b.tube((-0.20,-(D/2)-0.03,0.78),(0.20,-(D/2)-0.03,0.78),0.008,0.008,sg(hi,6,10),'chrome',cap0=True,cap1=True)
    b.tube((-0.20,-(D/2)+0.01,0.78),(-0.20,-(D/2)-0.03,0.78),0.007,0.007,sg(hi,6,8),'chrome',cap0=True,cap1=True)
    b.tube((0.20,-(D/2)+0.01,0.78),(0.20,-(D/2)-0.03,0.78),0.007,0.007,sg(hi,6,8),'chrome',cap0=True,cap1=True)
    for x in (-W/2+0.10,W/2-0.10):
        for y in (-D/2+0.10,D/2-0.10):
            leveler(b,(x,y),hi)
    maker_plate(b,(0,-(D/2)+0.02,0.16),hi,w=0.10,h=0.02)
    b.cbox((0,0,0),(W,D+0.06,H))

# ------------------------------------------------------------------ beer_taps
def beer_taps(b, hi=False):
    # 4-tap tree on a drip tray, sits on the bar
    W,D,H=0.62,0.28,0.62
    # tray + grate
    b.box((0,0,0.0),(W,D,0.04),'steel',skip=('bottom',))
    b.box((0,0,0.04),(W-0.06,D-0.06,0.012),'steel')
    for i in range(6):
        b.box((-0.22+i*0.09,0.0,0.054),(0.012,D-0.10,0.006),'steel')
    # column
    b.tube((0,0.02,0.05),(0,0.02,0.42),0.028,0.028,sg(hi,10,16),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube((0,0.02,0.40),(0,0.02,0.50),0.04,0.022,sg(hi,10,16),'chrome',cap0=False,cap1=True,smooth=True)
    # four-way bridge
    b.tube((-0.20,0.02,0.46),(0.20,0.02,0.46),0.014,0.014,sg(hi,8,12),'chrome',cap0=True,cap1=True,smooth=True)
    # taps
    for i,x in enumerate((-0.20,-0.07,0.07,0.20)):
        b.tube((x,0.02,0.46),(x,-0.06,0.40),0.010,0.010,sg(hi,6,10),'chrome',cap0=False,cap1=True,smooth=True)
        b.tube((x,-0.06,0.40),(x,-0.08,0.32),0.012,0.012,sg(hi,6,10),'chrome',cap0=False,cap1=True,smooth=True)
        # handle
        col=('leaf','paint_navy','oak','paint_cream')[i]
        b.tube((x,-0.06,0.42),(x,-0.06,0.58),0.012,0.010,sg(hi,6,10),col,cap0=False,cap1=True,smooth=True)
        b.tube((x,-0.06,0.58),(x,-0.06,0.62),0.016,0.016,sg(hi,6,10),'chrome',cap0=False,cap1=True,smooth=True)
        b.box((x,-0.07,0.50),(0.03,0.008,0.04),'badge')  # tap badge
    # badge on the column
    b.box((0,-0.01,0.28),(0.05,0.006,0.04),'badge')
    b.cbox((0,0,0),(W,D+0.08,H))

# ------------------------------------------------------------------ bar_counter
def bar_counter(b, hi=False):
    W,D,H=2.20,0.70,1.10
    th=0.04
    # thick top + bullnose / armrest pad on the customer edge
    b.box((0,-0.02,H-th),(W,D+0.04,th),'oak')
    b.box((0,-(D/2)-0.02,H-th-0.02),(W-0.06,0.08,0.04),'oak')
    b.box((0,-(D/2)-0.02,H-0.01),(W-0.10,0.07,0.02),'fabric')  # padded armrest
    # die / front
    b.box((0,0.02,0.10),(W-0.06,D-0.08,H-th-0.12),'paint_cream',skip=('bottom',))
    # kick
    b.box((0,-(D/2)+0.04,0.0),(W-0.04,0.10,0.12),'paint_black',skip=('bottom',))
    b.box((0,(D/2)-0.04,0.0),(W-0.04,0.08,0.08),'paint_cream',skip=('bottom',))
    # staff work top / drip and speed rail on +Y
    b.box((0,(D/2)-0.10,H-th-0.04),(W-0.16,0.22,0.02),'steel')
    b.box((0,(D/2)-0.02,H-th-0.06),(W-0.20,0.04,0.06),'steel')  # speed rail
    # chrome footrail, returns into end posts (free-standing segment)
    rz,ry=0.30,-(D/2)+0.02
    b.tube((-W/2+0.12,ry,rz),(W/2-0.12,ry,rz),0.018,0.018,sg(hi,8,14),'chrome',cap0=False,cap1=False,smooth=True)
    for x in (-W/2+0.12,W/2-0.12):
        # down into a grounded post (not a floating end)
        b.tube((x,ry,rz),(x,ry,0.0),0.018,0.018,sg(hi,8,14),'chrome',cap0=False,cap1=True,smooth=True)
        b.tube((x,ry,0.0),(x,ry,0.04),0.04,0.04,sg(hi,8,12),'steel',cap0=True,cap1=False,smooth=True)  # base flange
        b.box((x,ry+0.03,0.12),(0.05,0.04,0.04),'steel')  # clip to kick
        if hi:
            screw(b,(x,ry+0.04,0.13),(0,1,0),True,'steel',0.003)
    # end panels / posts
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*0.03,0.0,0.0),(0.06,D,H-0.02),'oak',skip=('bottom',))
    # mid stile on the front
    b.box((0,-(D/2)+0.03,0.14),(0.04,0.04,H-th-0.18),'oak')
    # two inset front panels with a brass waist rail
    for x in (-0.55,0.55):
        b.box((x,-(D/2)+0.025,0.20),(0.90,0.02,0.70),'oak')
        b.box((x,-(D/2)+0.012,0.22),(0.82,0.016,0.66),'lam')
        b.box((x,-(D/2)+0.006,0.26),(0.74,0.012,0.58),'paint_cream')
    b.box((0,-(D/2)+0.008,0.52),(W-0.20,0.016,0.020),'brass')
    b.box((0,-(D/2)+0.008,0.18),(W-0.16,0.016,0.016),'brass')
    maker_plate(b,(0,-(D/2)+0.03,0.18),hi,w=0.08,h=0.018)
    for x in (-W/2+0.10,W/2-0.10):
        for y in (-D/2+0.12,D/2-0.10):
            leveler(b,(x,y),hi)
    b.cbox((0,0,0),(W,D+0.08,H))

# ------------------------------------------------------------------ registry
_C=dict(dir='props/indoor/food',pdir='indoor_food',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('cafe_table',cafe_table,'small',600),
    _p('restaurant_table',restaurant_table,'medium',800),
    _p('cafe_chair',cafe_chair,'small',550),
    _p('bar_stool',bar_stool,'small',550),
    _p('booth_bench',booth_bench,'small',600),
    _p('espresso_machine',espresso_machine,'medium',1100,side=96),
    _p('pastry_case',pastry_case,'medium',1100,side=96,cage=0.04,ray=0.12),
    _p('gelato_case',gelato_case,'medium',1100,side=96,cage=0.04,ray=0.12),
    _p('soda_fountain',soda_fountain,'medium',800,side=96),
    _p('bakery_shelf',bakery_shelf,'medium',1100,cage=0.04,ray=0.12),
    _p('wine_backbar',wine_backbar,'medium',1200,side=128,cage=0.04,ray=0.12),
    _p('kitchen_line',kitchen_line,'large',2000),
    _p('beer_taps',beer_taps,'small',600,side=96),
    _p('bar_counter',bar_counter,'medium',1200),
]
