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
    W,D,H=0.58,0.70,0.95
    # floor mounts / legs
    for x in (-0.22,0.22):
        b.box((x,0.10,0.0),(0.05,0.40,0.06),'steel',skip=('bottom',))
        b.box((x,0.28,0.0),(0.08,0.08,0.03),'steel',skip=('bottom',))
        b.box((x,-0.16,0.0),(0.05,0.08,0.36),'steel',skip=('bottom',))
        b.box((x,-0.16,0.0),(0.08,0.08,0.03),'steel',skip=('bottom',))
    # seat pan (slightly thick, flip-seat hinge at the back)
    b.box((0,-0.06,0.36),(0.46,0.40,0.05),'steel')
    b.box((0,-0.06,0.40),(0.42,0.36,0.06),'fabric')
    b.box((0,-0.06,0.39),(0.44,0.38,0.02),'paint_black')  # welt
    # hinge tube at the back of the seat
    b.tube((-0.22,0.16,0.38),(0.22,0.16,0.38),0.012,0.012,sg(hi,8,12),'steel',cap0=True,cap1=True,smooth=True)
    # back: two-pad stack (lumbar + shoulder) so it is not a single square slab
    b.box((0,0.22,0.48),(0.48,0.10,0.06),'steel')
    b.box((0,0.18,0.54),(0.42,0.09,0.22),'fabric')          # lumbar
    b.box((0,0.20,0.76),(0.38,0.09,0.22),'fabric')          # shoulder, slightly narrower
    b.box((0,0.24,0.54),(0.44,0.06,0.48),'steel')           # rear shell
    b.box((0,0.18,0.48),(0.46,0.11,0.03),'paint_black')
    # waterfall front on the seat
    b.box((0,-0.24,0.38),(0.40,0.06,0.06),'fabric')
    # arms
    for sgn in (-1,1):
        b.box((sgn*0.26,0.04,0.42),(0.06,0.36,0.06),'steel')
        b.box((sgn*0.26,0.04,0.47),(0.05,0.32,0.04),'paint_black')
        b.box((sgn*0.26,0.20,0.42),(0.06,0.06,0.40),'steel')
        b.box((sgn*0.26,0.04,0.52),(0.06,0.34,0.03),'fabric')  # arm pad
    # cup holder on the right arm
    b.tube((0.26,-0.10,0.50),(0.26,-0.10,0.54),0.035,0.035,sg(hi,10,14),'plastic_black',cap0=True,cap1=False,smooth=True)
    b.tube((0.26,-0.10,0.50),(0.26,-0.10,0.53),0.028,0.028,sg(hi,8,12),'plastic',cap0=True,cap1=False,smooth=True)
    # row / seat number plaque
    b.box((0,0.28,0.82),(0.08,0.02,0.04),'badge')
    maker_plate(b,(0,0.28,0.20),hi,w=0.05,h=0.012,rz=180)
    b.cbox((0,0,0),(W+0.08,D,H))


# ------------------------------------------------------------------ ticket_booth
def ticket_booth(b, hi=False):
    W,D,H=1.20,1.00,2.20
    tw=0.04
    # floor
    b.box((0,0.0,0.0),(W,D,0.04),'lam',skip=('bottom',))
    # three walls + a front with a window (complete booth, not a half opening)
    b.box((0,D/2-tw/2,0.04),(W,tw,H-0.12),'paint_cream')
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*tw/2,0.0,0.04),(tw,D,H-0.12),'paint_cream')
        # exterior reveals
        b.box((x+sgn*(tw+0.006),0.0,0.20),(0.012,D-0.16,0.80),'paint_cream')
        b.box((x+sgn*(tw+0.006),0.0,1.20),(0.012,D-0.16,0.70),'paint_cream')
    # front wall with a window opening: jambs + transom + sill (the opening is glazed)
    win_w, win_h = 0.80, 0.55
    sill_z=1.00
    jamb=(W-win_w)/2
    for x,sgn in ((-W/2,1),(W/2,-1)):
        b.box((x+sgn*jamb/2,-(D/2)+tw/2,0.04),(jamb,tw,H-0.12),'paint_cream')
    # below the sill (solid front / counter face)
    b.box((0,-(D/2)+tw/2,0.04),(win_w,tw,sill_z-0.04),'paint_cream')
    # transom / header above the window
    b.box((0,-(D/2)+tw/2,sill_z+win_h),(win_w,tw,H-0.12-(sill_z+win_h)),'paint_cream')
    # window frame + opaque glass
    b.box((0,-(D/2)+0.01,sill_z),(win_w+0.04,0.05,0.03),'oak')  # sill
    b.box((0,-(D/2)+0.01,sill_z+win_h-0.03),(win_w+0.04,0.05,0.03),'oak')
    for x,sgn in ((-win_w/2,1),(win_w/2,-1)):
        b.box((x, -(D/2)+0.01,sill_z),(0.03,0.05,win_h),'oak')
    # window is a unique baked interior, not a black/glass void
    if not hi:
        b.box((0,-(D/2)-0.004,sill_z+0.04),(win_w-0.08,0.010,win_h-0.08),'mirror')
    if hi:
        y=-(D/2)-0.012
        b.box((0,y,sill_z+0.04),(win_w-0.10,0.004,win_h-0.08),'paint_cream')
        b.box((0,y,sill_z+0.22),(win_w-0.16,0.004,0.16),'plastic')
        b.box((-0.12,y,sill_z+0.14),(0.20,0.004,0.28),'paint_navy')  # clerk silhouette
        b.box((0.16,y,sill_z+0.28),(0.18,0.004,0.10),'paint_cream')
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
    b.cbox((0,0,0),(W,D+0.12,H))



# ------------------------------------------------------------------ stanchion
def stanchion(b, hi=False):
    H=1.00
    seg=sg(hi,12,18)
    oy=0.16
    def P(x,y,z): return (x,y+oy,z)
    b.tube(P(0,0,0.0),P(0,0,0.04),0.20,0.20,seg,'chrome',cap0=True,cap1=True,smooth=True)
    b.tube(P(0,0,0.04),P(0,0,0.08),0.16,0.10,sg(hi,10,16),'chrome',cap0=False,cap1=True,smooth=True)
    b.tube(P(0,0,0.08),P(0,0,H-0.08),0.022,0.022,sg(hi,10,14),'chrome',cap0=False,cap1=False,smooth=True)
    b.tube(P(0,0,H-0.08),P(0,0,H-0.01),0.05,0.05,sg(hi,10,16),'chrome',cap0=False,cap1=True,smooth=True)
    b.box(P(0,-0.04,H-0.06),(0.06,0.04,0.04),'paint_black')
    b.box(P(0,-0.28,H-0.055),(0.03,0.48,0.018),'paint_navy')
    b.box(P(0,-0.52,H-0.055),(0.04,0.04,0.03),'chrome')
    b.box(P(0,0.05,H-0.06),(0.04,0.03,0.03),'paint_black')
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
    # poster art on the front of the opening (not behind opaque glass)
    if not hi:
        b.box((0,-0.012,fw+0.03),(W-2*fw-0.04,0.006,H-2*fw-0.06),'goods')
    if hi:
        y=-0.012-0.006
        b.box((0,y,0.20),(W-0.20,0.004,H-0.36),'paint_navy')
        b.box((0,y,0.85),(W-0.28,0.004,0.08),'paint_cream')
        b.box((-0.12,y,0.40),(0.28,0.004,0.22),'leaf')
        b.box((0.14,y,0.50),(0.16,0.004,0.14),'brass')
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
    _p('ticket_booth',ticket_booth,'large',1800,side=96,cage=0.04,ray=0.12),
    _p('stanchion',stanchion,'small',500),
    _p('poster_case',poster_case,'medium',700,side=96,mount='wall',cage=0.04,ray=0.12),
]
