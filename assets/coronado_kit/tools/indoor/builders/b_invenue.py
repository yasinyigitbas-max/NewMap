"""Indoor venue props — original geometry, page I, near+col only.

theatre_seat, ticket_booth.
Chairs get collision. Delete stale _bake/tiles/<name>_* after geo changes.
"""
import math
from b_inshared import (
    sg, leveler, screw, maker_plate, bottle_card, can_card, TR, TINT,
)

# ------------------------------------------------------------------ theatre_seat
def theatre_seat(b, hi=False):
    """Cinema / auditorium seat: cast end standards with hardwood arm caps, curved upholstered back on a
    moulded shell, flip-up seat with a rolled front edge, cup holder, aisle number plate."""
    from b_inshared import arc_slab
    W,D,H=0.58,0.70,0.98
    # cast end standards (graphite) with a stepped foot and a reveal line
    for sgn in (-1,1):
        x=sgn*0.275
        b.box((x,0.02,0.0),(0.05,0.56,0.04),'paint_grey',skip=('bottom',),ch=0.008)       # foot plate
        b.box((x,0.04,0.04),(0.044,0.46,0.56),'paint_grey',ch=0.012)                     # standard panel
        b.box((x+sgn*0.023,0.04,0.12),(0.004,0.36,0.40),'paint_black')                   # outer reveal panel
        b.box((x,0.03,0.60),(0.07,0.52,0.035),'walnut',ch=0.012)                          # hardwood arm cap
        b.box((x,-0.22,0.585),(0.07,0.04,0.015),'paint_black')                            # cap end grip
        for y in (-0.16,0.22): b.box((x,y,0.0),(0.08,0.06,0.012),'steel')                # floor fixings
    # flip seat: moulded under-shell + cushion with a rolled front
    b.box((0,0.00,0.34),(0.47,0.44,0.05),'plastic_black',ch=0.015)
    b.box((0,0.01,0.39),(0.46,0.40,0.07),'fabric',ch=0.02)
    b.tube((-0.225,-0.19,0.42),(0.225,-0.19,0.42),0.042,0.042,sg(hi,6,12),'fabric',cap0=True,cap1=True,smooth=True)
    b.tube((-0.24,0.16,0.38),(0.24,0.16,0.38),0.014,0.014,sg(hi,6,12),'steel',cap0=True,cap1=True,smooth=True)  # hinge bar
    # curved back: moulded shell (outer, faces the row behind) + upholstered pad (faces the sitter)
    arc_slab(b,(0,-0.55),0.80,106,74,0.44,H,0.05,'plastic_black',seg=sg(hi,4,10))
    arc_slab(b,(0,-0.55),0.748,104,76,0.50,H-0.06,0.035,'fabric',seg=sg(hi,4,10))
    # lumbar roll + head roll on the pad (reads as channel stitching)
    for z in (0.62,0.84):
        b.tube((-0.19,0.165,z),(0.19,0.165,z),0.022,0.022,sg(hi,5,10),'fabric',cap0=True,cap1=True,smooth=True)
    b.box((0,0.255,H-0.02),(0.42,0.04,0.025),'walnut',ch=0.01)                            # back top rail
    # cup holder ring in the right arm cap
    b.tube((0.275,-0.17,0.635),(0.275,-0.17,0.605),0.042,0.042,sg(hi,8,14),'plastic_black',cap0=False,cap1=True,smooth=True)
    b.tube((0.275,-0.17,0.636),(0.275,-0.17,0.60),0.034,0.034,sg(hi,8,14),'paint_black',cap0=False,cap1=True,smooth=True)
    # aisle / seat number plate on the back shell and on the standard
    b.box((0,0.256,0.86),(0.09,0.010,0.045),'brass',ch=0.004)
    b.box((0,0.262,0.86),(0.05,0.004,0.022),'paint_black')
    b.box((-0.30,-0.10,0.48),(0.006,0.06,0.05),'brass')
    maker_plate(b,(0,0.26,0.30),hi,w=0.05,h=0.012,rz=180)
    b.cbox((0,0.02,0),(W+0.04,0.60,H))


# ------------------------------------------------------------------ ticket_booth
def ticket_booth(b, hi=False):
    W,D,H=1.20,1.00,2.20
    tw=0.04
    # floor
    b.box((0,0.0,0.0),(W,D,0.04),'lam',skip=('bottom',))
    # three walls + a front with a window (complete booth, not a half opening)
    b.box((0,D/2-tw/2,0.04),(W,tw,H-0.12),'paint_red')
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*tw/2,0.0,0.04),(tw,D,H-0.12),'paint_red')
        # exterior reveals
        b.box((x+sgn*(tw+0.006),0.0,0.20),(0.012,D-0.16,0.80),'paint_cream')
        b.box((x+sgn*(tw+0.006),0.0,1.20),(0.012,D-0.16,0.70),'paint_cream')
    # front wall with a window opening: jambs + transom + sill (the opening is glazed)
    win_w, win_h = 0.80, 0.55
    sill_z=1.00
    jamb=(W-win_w)/2
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*jamb/2,-(D/2)+tw/2,0.04),(jamb,tw,H-0.12),'paint_red')
    # below the sill (solid front / counter face): red with a sunburst-style brass inlay panel
    b.box((0,-(D/2)+tw/2,0.04),(win_w,tw,sill_z-0.04),'paint_red')
    b.box((0,-(D/2)-0.004,0.22),(win_w-0.10,0.008,0.62),'paint_cream')
    b.box((0,-(D/2)-0.008,0.26),(win_w-0.18,0.006,0.54),'paint_red')
    for x in (-0.12,0.0,0.12):
        b.box((x,-(D/2)-0.012,0.30),(0.010,0.004,0.46),'brass')
    for z in (0.20,0.86):
        b.box((0,-(D/2)-0.006,z),(win_w,0.008,0.014),'brass')
    # transom / header above the window
    b.box((0,-(D/2)+tw/2,sill_z+win_h),(win_w,tw,H-0.12-(sill_z+win_h)),'paint_red')
    # window frame + opaque glass
    b.box((0,-(D/2)+0.01,sill_z),(win_w+0.04,0.05,0.03),'oak')  # sill
    b.box((0,-(D/2)+0.01,sill_z+win_h-0.03),(win_w+0.04,0.05,0.03),'oak')
    for x,sgn in ((-win_w/2,1),(win_w/2,-1)):
        b.box((x, -(D/2)+0.01,sill_z),(0.03,0.05,win_h),'oak')
    # opaque kit glass (no void), a speak-through grille disc and a hanging "tickets" card behind the pane
    b.box((0,-(D/2)+0.012,sill_z+0.03),(win_w-0.06,0.008,win_h-0.06),'glass')
    b.tube((0,-(D/2)+0.006,sill_z+0.20),(0,-(D/2)+0.0,sill_z+0.20),0.055,0.055,sg(hi,10,16),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube((0,-(D/2)-0.001,sill_z+0.20),(0,-(D/2)-0.002,sill_z+0.20),0.040,0.040,sg(hi,10,16),'paint_black',cap0=False,cap1=True,smooth=True)
    b.box((0.22,-(D/2)+0.004,sill_z+0.30),(0.22,0.006,0.12),'paint_cream',ch=0.01)
    for k,z in enumerate((sill_z+0.38,sill_z+0.35,sill_z+0.32)):
        b.box((0.22,-(D/2)-0.0,z),(0.16-0.04*k,0.003,0.014),'paint_red' if k==0 else 'paint_black')
    # striped canvas awning over the window (prism, slopes out to the queue)
    ay0,ay1=-(D/2)-0.005,-(D/2)-0.24; az0,az1=sill_z+win_h+0.18,sill_z+win_h+0.02
    nst=6; ww=win_w+0.12
    for i in range(nst):
        x0=-ww/2+ww*i/nst; x1=x0+ww/nst
        b.quad([(x0,ay1,az1),(x1,ay1,az1),(x1,ay0,az0),(x0,ay0,az0)],'paint_red' if i%2==0 else 'paint_cream')
        b.quad([(x0,ay1,az1),(x0,ay0,az0),(x1,ay0,az0),(x1,ay1,az1)],'paint_black')
        b.quad([(x0,ay1,az1-0.06),(x1,ay1,az1-0.06),(x1,ay1,az1),(x0,ay1,az1)],'paint_red' if i%2==0 else 'paint_cream')  # valance
        b.quad([(x0,ay1,az1-0.06),(x0,ay1,az1),(x1,ay1,az1),(x1,ay1,az1-0.06)],'paint_black')
    for x in (-ww/2,ww/2):
        b.tube((x,ay0,az0),(x,ay1,az1),0.008,0.008,sg(hi,4,8),'brass',cap0=False,cap1=True,smooth=True)
    # speak hole / deal tray in the sill
    b.box((0,-(D/2)-0.04,sill_z-0.02),(0.28,0.14,0.04),'steel')
    b.box((0,-(D/2)-0.04,sill_z+0.00),(0.22,0.10,0.02),'steel')
    b.tube((0.22,-(D/2)-0.01,sill_z+0.18),(0.22,-(D/2)-0.04,sill_z+0.18),0.03,0.03,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
    # ticket slot
    b.box((-0.22,-(D/2)-0.01,sill_z-0.04),(0.14,0.04,0.03),'paint_black')
    # interior counter
    b.box((0,-0.20,0.92),(W-0.16,0.40,0.04),'lam')
    b.box((0,-0.20,0.20),(W-0.20,0.30,0.70),'paint_cream')
    # shelf
    b.box((0,0.20,1.40),(W-0.16,0.30,0.024),'oak')
    # cornice / roof
    b.box((0,0.0,H-0.08),(W+0.06,D+0.06,0.08),'oak')
    b.box((0,0.0,H-0.12),(W-0.04,D-0.04,0.03),'oak')
    # header sign with typography as geo
    b.box((0,-(D/2)-0.02,H-0.28),(W-0.20,0.04,0.14),'paint_navy')
    for i,x in enumerate((-0.36,-0.18,0.0,0.18,0.36)):
        b.box((x,-(D/2)-0.04,H-0.24),(0.10,0.016,0.05),'paint_cream')
    b.box((0,-(D/2)-0.04,H-0.30),(W-0.40,0.016,0.012),'brass')
    # marquee bulbs around the header board
    for k in range(9):
        x=-0.44+k*0.11
        for z in (H-0.31,H-0.125):
            b.lathe([(0.0,z-0.012),(0.014,z),(0.0,z+0.014)],sg(hi,4,10),'paint_white',c=(x,-(D/2)-0.045,0),cap_top=False)
    # brass edge beads on the corners
    for x in (-W/2-0.002,W/2+0.002):
        b.box((x,-(D/2)-0.002,0.04),(0.012,0.012,H-0.16),'brass')
    # exterior paneling on sides and back
    b.box((0,D/2+0.010,0.04),(W-0.10,0.016,0.10),'oak')
    for z in (0.70,1.30,1.90):
        b.box((0,D/2+0.010,z),(W-0.14,0.016,0.04),'oak')
    for x in (-0.30,0.0,0.30):
        b.box((x,D/2+0.010,0.04),(0.03,0.016,H-0.22),'oak')
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*(tw+0.010),0.0,0.04),(0.016,D-0.12,0.10),'oak')
        for z in (0.70,1.30,1.90):
            b.box((x+sgn*(tw+0.010),0.0,z),(0.016,D-0.16,0.04),'oak')
    # corner posts
    for x in (-W/2+0.03,W/2-0.03):
        for y in (-D/2+0.03,D/2-0.03):
            b.box((x,y,0.04),(0.06,0.06,H-0.14),'oak')
    # kick
    b.box((0,-(D/2)+0.03,0.04),(W-0.12,0.03,0.10),'paint_black')
    maker_plate(b,(0.40,-(D/2)+0.03,0.20),hi,w=0.07,h=0.016)
    for x in (-W/2+0.10,W/2-0.10):
        for y in (-D/2+0.10,D/2-0.10):
            leveler(b,(x,y),hi)
    b.cbox((0,-0.107,0),(W,1.275,H))   # booth body + awning, centred on the shifted footprint



# ------------------------------------------------------------------ stanchion
def stanchion(b, hi=False):
    H=1.00
    seg=sg(hi,12,18)
    oy=0.16
    def P(x,y,z): return (x,y+oy,z)
    # weighted base: rubber foot ring + spun chrome dome (lathe), satin post, crown cap, belt cassette
    c0=P(0,0,0)
    b.lathe([(0.0,0.0),(0.185,0.0),(0.185,0.012)],seg,'rubber',c=c0,cap_top=False)
    b.lathe([(0.185,0.012),(0.18,0.03),(0.15,0.05),(0.09,0.068),(0.04,0.078),(0.026,0.084)],seg,'chrome',c=c0,cap_top=False)
    b.tube(P(0,0,0.084),P(0,0,H-0.10),0.026,0.026,sg(hi,10,14),'alum',cap0=False,cap1=False,smooth=True)
    b.lathe([(0.026,H-0.10),(0.034,H-0.09),(0.034,H-0.035),(0.042,H-0.025),(0.042,H-0.012),(0.025,H),(0.0,H+0.006)],sg(hi,10,16),'chrome',c=c0,cap_top=False)
    # belt cassette housing (chamfered) with slot + navy belt, end clip on a chrome tongue
    b.box(P(0,-0.045,H-0.085),(0.07,0.05,0.06),'plastic_black',ch=0.012)
    b.box(P(0,-0.071,H-0.075),(0.012,0.004,0.04),'paint_black')
    b.box(P(0,-0.30,H-0.065),(0.004,0.46,0.045),'paint_navy')
    b.box(P(0,-0.30,H-0.067),(0.0045,0.46,0.004),'paint_cream')
    b.box(P(0,-0.30,H-0.026),(0.0045,0.46,0.004),'paint_cream')
    b.box(P(0,-0.545,H-0.072),(0.018,0.05,0.06),'chrome',ch=0.006)
    b.box(P(0,0.03,H-0.07),(0.05,0.02,0.035),'plastic_black',ch=0.008)   # receiver slot on the back
    maker_plate(b,P(0,-0.12,0.06),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(0.40,0.88,H))


def poster_case(b, hi=False):
    W,D,H=0.80,0.08,1.20
    fw=0.05
    # hinged poster case, wall-mounted, lock on the side
    b.box((0,0,0.0),(W,D,fw),'alum',skip=('bottom',))
    b.box((0,0,H-fw),(W,D,fw),'alum')
    b.box((-(W/2)+fw/2,0,0.0),(fw,D,H),'alum',skip=('bottom',))
    b.box(((W/2)-fw/2,0,0.0),(fw,D,H),'alum',skip=('bottom',))
    # mid mitre step
    b.box((0,-0.01,fw-0.006),(W-fw,0.02,0.016),'alum')
    b.box((0,-0.01,H-fw-0.010),(W-fw,0.02,0.016),'alum')
    # back board
    b.box((0,D/2-0.008,fw),(W-2*fw,0.012,H-2*fw),'paint_cream')
    # designed poster (event / film one-sheet, no branding): geometry colour blocks, all near, 2-tri quads
    y=-0.014; x0,x1=-(W/2)+fw+0.02,(W/2)-fw-0.02; z0,z1=fw+0.02,H-fw-0.02
    def pq(xa,xb,za,zb,k,dy=0.0):
        b.quad([(xa,y-dy,za),(xb,y-dy,za),(xb,y-dy,zb),(xa,y-dy,zb)],k)
    pq(x0,x1,z0,z1,'paint_navy')                                  # night sky
    pq(x0,x1,z0,z0+0.30,'paint_purple',0.001)                     # dusk band
    pq(x0,x1,z0+0.30,z0+0.36,'paint_orange',0.001)                # horizon glow
    # sun disc (fan) sitting on the horizon
    import math as _m
    cx,cz,r=0.06,z0+0.36,0.17; n=sg(hi,10,16)
    pts=[(cx+r*_m.cos(_m.pi*i/n),y-0.002,cz+r*_m.sin(_m.pi*i/n)) for i in range(n+1)]
    from mathutils import Vector as _V
    b.faces([_V((cx,y-0.002,cz))]+[_V(q) for q in pts],[(0,i+1,i+2) for i in range(n)],'paint_yellow',[[(0,0),(pts[i][0],pts[i][2]),(pts[i+1][0],pts[i+1][2])] for i in range(n)])
    # city / palm silhouette strip in front of the sun
    for xa,xb,h in ((x0,x0+0.10,0.20),(x0+0.10,x0+0.16,0.12),(x0+0.16,x0+0.26,0.26),(x1-0.22,x1-0.12,0.18),(x1-0.12,x1,0.24)):
        pq(xa,xb,z0+0.30,z0+0.30+h,'paint_black',0.003)
    # title block + tagline + credit block + date strip
    pq(x0+0.05,x1-0.05,z1-0.22,z1-0.10,'paint_cream',0.002)
    for k,(xa,xb) in enumerate(((x0+0.09,x1-0.20),(x0+0.09,x1-0.32))):
        pq(xa,xb,z1-0.15-0.04*k,z1-0.125-0.04*k,'paint_red',0.003)
    pq(x0+0.12,x1-0.12,z1-0.27,z1-0.255,'paint_cream',0.002)
    for k in range(4):
        pq(x0+0.06,x1-0.06-0.05*(k%2),z0+0.05+0.03*k,z0+0.065+0.03*k,'paint_white',0.002)
    pq(x0+0.06,x0+0.30,z0+0.20,z0+0.26,'paint_orange',0.002)
    # lock + hinge knuckles
    b.box((W/2+0.01,0.0,H/2),(0.03,0.03,0.06),'steel')
    b.tube((W/2+0.02,0.0,H/2),(W/2+0.03,0.0,H/2),0.010,0.010,sg(hi,8,12),'steel',cap0=False,cap1=True,smooth=True)
    for z in (0.20,H-0.20):
        b.tube((-W/2,0.0,z-0.02),(-W/2,0.0,z+0.02),0.010,0.010,sg(hi,6,10),'steel',cap0=True,cap1=True,smooth=True)
    # wall flanges
    for x in (-W/2+0.12,W/2-0.12):
        for z in (0.12,H-0.12):
            b.box((x,D/2+0.008,z),(0.05,0.014,0.05),'steel')
    maker_plate(b,(0,0.0,0.02),hi,w=0.05,h=0.012)
    b.cbox((0,0,0),(W+0.04,D+0.02,H))


_C=dict(dir='props/indoor/venue',pdir='indoor_venue',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('theatre_seat',theatre_seat,'medium',800),
    _p('ticket_booth',ticket_booth,'large',1800,shift=(0,0.107),side=96,cage=0.04,ray=0.12),
    _p('stanchion',stanchion,'small',500),
    _p('poster_case',poster_case,'medium',700,side=96,mount='wall',cage=0.04,ray=0.12),
]

INDOOR_LOOK=True   # run.py: chamfer edge highlight + per-part colour variation in COLOR_0
