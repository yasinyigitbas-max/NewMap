"""Waterfront set 5: promenade. Builder coords Z up, water side = -Y (front), run along X; origin = bottom centre.
prom_rail       4.0 m seaside railing module (0.5 m grid): 3 posts (end posts flush with the module ends, so two snapped modules
                form a bolted twin post with no gap), teak cap rail, top + bottom rails, square pickets at 115 mm.
prom_rail_wall  2.0 m end module: one grounded post at the snap end, the rails and cap run into bolted wall flanges at x=+1.0
                (place with the flange face against a building / quay wall; the flange plates are the end, never a free end).
Every run therefore ends on a grounded post (prom_rail ends) or a wall flange (prom_rail_wall). Base plates sit at z 0 (place on
the quay / promenade deck, e.g. z 3.0 on the quay).
prom_boardwalk  4.0 x 3.0 m boardwalk strip: 2x6 planks across the walk on 3 joists, fascia boards, concrete footings at z 0,
                deck top z 0.32. Snap ends at x=+-2.0 are open (joist/plank ends meet the next module)."""
import math
from mathutils import Vector
import pg
import wf_parts as P
import b_wfpier as WP
from wf_parts import PI, cbox, ccyl, bolt_head, seg_n
from wf_boat import face
V=Vector
H=1.07; PW=0.08; CAP_W=0.14; CAP_T=0.04; ZB=0.12; ZT=H-CAP_T-0.06; PK=0.018; PSP=0.115
def _post(b,x,hi,tier,wall=False):
    mid=tier=='mid'; zt=H-CAP_T
    z0=0.09 if not mid else 0.0   # post rises out of the cast shoe (shoe top 0.09)
    b.box((x,0,z0),(PW,PW,zt-z0),'aluminium',skip=('bottom','top'))
    P.rec('v',(x,0,z0),(x,0,zt),PW/2)
    if mid: return
    b.box((x,0,0),(0.17,0.17,0.012),'aluminium',skip=('bottom',))                              # base plate
    for dx in (-0.055,0.055):
        for dy in (-0.055,0.055):
            if hi: bolt_head(b,(x+dx,dy,0.012),(0,0,1),0.008,'stainless',hi)
            else: b.box((x+dx,dy,0.012),(0.018,0.018,0.008),'stainless',skip=('bottom',))
    b.box((x,0,0.012),(PW+0.024,PW+0.024,0.05),'aluminium',skip=('bottom',))                    # cast shoe
    face(b,[V((x-PW/2-0.012,-PW/2-0.012,0.062)),V((x+PW/2+0.012,-PW/2-0.012,0.062)),V((x+PW/2,-PW/2,0.09)),V((x-PW/2,-PW/2,0.09))],'aluminium',(0,-1,1))
    face(b,[V((x+PW/2+0.012,PW/2+0.012,0.062)),V((x-PW/2-0.012,PW/2+0.012,0.062)),V((x-PW/2,PW/2,0.09)),V((x+PW/2,PW/2,0.09))],'aluminium',(0,1,1))
    b.box((x,0,zt-0.10),(PW+0.016,PW+0.016,0.03),'aluminium',skip=())                           # collar under the cap
    if hi:
        for zz in (ZB+0.02,ZT+0.02): bolt_head(b,(x,-PW/2,zz),(0,-1,0),0.006,'stainless',hi)
def _bay(b,x0,x1,hi,tier,cap=True):
    """rails + pickets between post faces x0 (right face of the left post) and x1 (left face of the right post / wall flange)"""
    mid=tier=='mid'
    for zz,hh,ww in ((ZB,0.05,0.035),(ZT,0.05,0.035)):
        WP.obox(b,V((x0,0,zz+hh/2)),V((x1,0,zz+hh/2)),ww,hh,'aluminium',ends=(False,False))
        P.rec('h',(x0,0,zz+hh/2),(x1,0,zz+hh/2),0.0175)
    n=max(1,int(round((x1-x0)/PSP))); 
    for k in range(1,n):
        x=x0+(x1-x0)*k/n
        if mid:
            for s in (-1,1): face(b,[V((x-PK/2,s*PK/2,ZB+0.05)),V((x+PK/2,s*PK/2,ZB+0.05)),V((x+PK/2,s*PK/2,ZT)),V((x-PK/2,s*PK/2,ZT))],'aluminium',(0,s,0))
        else:
            b.box((x,0,ZB+0.05),(PK,PK,ZT-ZB-0.05),'aluminium',skip=('bottom','top'))
def _cap(b,x0,x1,hi,tier):
    zt=H-CAP_T
    b.box(((x0+x1)/2,0,zt),(x1-x0,CAP_W,CAP_T),'wood_natural',skip=('left','right'))
    if tier!='mid':
        for s in (-1,1):   # eased (rounded) top edges
            face(b,[V((x0,s*CAP_W/2,H)),V((x1,s*CAP_W/2,H)),V((x1,s*(CAP_W/2-0.012),H+0.008)),V((x0,s*(CAP_W/2-0.012),H+0.008))],'wood_natural',(0,s,1))
        face(b,[V((x0,-(CAP_W/2-0.012),H+0.008)),V((x1,-(CAP_W/2-0.012),H+0.008)),V((x1,CAP_W/2-0.012,H+0.008)),V((x0,CAP_W/2-0.012,H+0.008))],'wood_natural',(0,0,1))
    P.rec('h',(x0,0,zt+CAP_T/2),(x1,0,zt+CAP_T/2),0.02)
def rail(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier
    xs=[-2.0+PW/2,0.0,2.0-PW/2]
    for x in xs: _post(b,x,hi,tier)
    for a,c in zip(xs[:-1],xs[1:]): _bay(b,a+PW/2,c-PW/2,hi,tier)
    _cap(b,-2.0,2.0,hi,tier)
    if tier!='mid':
        b.box((0,-PW/2-0.002,0.55),(0.20,0.004,0.12),'plastic_white',skip=('back','bottom','top'))   # no-climbing / no-fishing plaque (baked)
        if hi: pg.add_text(b,'NO FISHING',0.035,(0,-PW/2-0.0045,0.62),(1,0,0),(0,0,1),0.0008,'paint_navy'); pg.add_text(b,'FROM RAILING',0.025,(0,-PW/2-0.0045,0.575),(1,0,0),(0,0,1),0.0007,'paint_navy')
    if tier=='near': cbox(b,(0,0,0),(4.0,0.17,H+0.01),rail=True)
def rail_far(b):
    face(b,[V((-2.0,0,ZB)),V((2.0,0,ZB)),V((2.0,0,H)),V((-2.0,0,H))],'twf_flat',(0,-1,0))
    face(b,[V((-2.0,-CAP_W/2,H)),V((2.0,-CAP_W/2,H)),V((2.0,CAP_W/2,H)),V((-2.0,CAP_W/2,H))],'twf_flat',(0,0,1))
    for x in (-2.0+PW/2,0.0,2.0-PW/2): face(b,[V((x-0.06,0,0.0)),V((x+0.06,0,0.0)),V((x+0.06,0,ZB)),V((x-0.06,0,ZB))],'twf_flat',(0,-1,0))
def rail_wall(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier
    x0=-1.0+PW/2; xw=1.0; tf=0.012
    _post(b,x0,hi,tier)
    _bay(b,x0+PW/2,xw-tf,hi,tier)
    _cap(b,-1.0,xw-tf,hi,tier)
    # wall flanges: rails and cap end on bolted plates whose back face is the wall plane x=+1.0
    for zz,hh,ww in ((ZB,0.05,0.035),(ZT,0.05,0.035)):
        b.box((xw-tf/2,0,zz-0.035),(tf,0.11,hh+0.07),'aluminium',skip=('right',))
        if tier!='mid':
            for dz in (-0.02,hh+0.02):
                if hi: bolt_head(b,(xw-tf,0,zz+dz),(-1,0,0),0.007,'stainless',hi)
                else: b.box((xw-tf-0.004,0,zz+dz-0.008),(0.008,0.016,0.016),'stainless',skip=('right',))
    b.box((xw-tf/2,0,H-CAP_T-0.03),(tf,CAP_W+0.03,CAP_T+0.06),'aluminium',skip=('right',))
    if tier!='mid':
        for dy in (-0.06,0.06):
            if hi: bolt_head(b,(xw-tf,dy,H-0.02),(-1,0,0),0.007,'stainless',hi)
            else: b.box((xw-tf-0.004,dy,H-0.028),(0.008,0.016,0.016),'stainless',skip=('right',))
    if tier=='near': cbox(b,(0,0,0),(2.0,0.17,H+0.01),rail=True)
def rail_wall_far(b):
    face(b,[V((-1.0,0,ZB)),V((1.0,0,ZB)),V((1.0,0,H)),V((-1.0,0,H))],'twf_flat',(0,-1,0))
    face(b,[V((-1.0,-CAP_W/2,H)),V((1.0,-CAP_W/2,H)),V((1.0,CAP_W/2,H)),V((-1.0,CAP_W/2,H))],'twf_flat',(0,0,1))
    face(b,[V((-1.0+PW/2-0.06,0,0.0)),V((-1.0+PW/2+0.06,0,0.0)),V((-1.0+PW/2+0.06,0,ZB)),V((-1.0+PW/2-0.06,0,ZB))],'twf_flat',(0,-1,0))
    face(b,[V((0.99,-0.055,ZB-0.035)),V((0.99,0.055,ZB-0.035)),V((0.99,0.055,H)),V((0.99,-0.055,H))],'twf_flat',(-1,0,0))
# ---------------------------------------------------------------- boardwalk strip
BL,BW_,ZD=4.0,3.0,0.32; PL_W=0.14; PL_T=0.038
def boardwalk(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'
    zj=ZD-PL_T
    # concrete footings (z 0) + galvanized post bases, 4x6 joists along X, fascia boards on both long edges
    for x in (-1.25,1.25):
        for y in (-1.15,0.0,1.15):
            b.box((x,y,0.0),(0.30,0.30,0.12),'concrete',skip=('bottom',))
            if not mid:
                b.box((x,y,0.12),(0.10,0.14,zj-0.14-0.12),'wood_weathered',skip=('bottom','top'))      # short 4x4 stub post
                b.box((x,y,0.12),(0.14,0.16,0.01),'galvanized',skip=('bottom',))
    for y in (-1.15,0.0,1.15):
        b.box((0,y,zj-0.14),(BL,0.09,0.14),'wood_weathered',skip=('left','right','top') if not mid else ('left','right','top','bottom'))
    for s in (-1,1):
        yf=s*(BW_/2)
        b.box((0,yf-s*0.0125,ZD-0.20),(BL,0.025,0.20),'wood_weathered',skip=('left','right','bottom'))   # fascia
        if not mid:
            for x in [-1.75+0.5*i for i in range(8)]:
                if hi: bolt_head(b,(x,yf+s*0.0,ZD-0.07),(0,s,0),0.006,'galvanized',hi)
                else: b.box((x,yf,ZD-0.075),(0.012,0.004,0.012),'galvanized',skip=('back' if s<0 else 'front',))
    # planks across the walk (along Y), 6 mm gaps, cupped + checked in the bake, nail pairs over each joist
    n=int(BL/(PL_W+0.006)); pitch=BL/n
    if mid:
        face(b,[V((-BL/2,-BW_/2,ZD)),V((BL/2,-BW_/2,ZD)),V((BL/2,BW_/2,ZD)),V((-BL/2,BW_/2,ZD))],'wood_weathered',(0,0,1))
    else:
        for i in range(n):
            x=-BL/2+pitch*(i+0.5); w=pitch-0.006
            b.box((x,0,zj),(w,BW_-0.06,PL_T),'wood_weathered',skip=('bottom','left','right') if not hi else ('bottom',))
            if hi:
                for y in (-1.15,0.0,1.15):
                    for dx in (-0.04,0.04): b.box((x+dx,y,ZD),(0.008,0.008,0.002),'galvanized',skip=('bottom',))
    if tier=='near': cbox(b,(0,0,0),(BL,BW_,ZD))
def boardwalk_far(b):
    face(b,[V((-BL/2,-BW_/2,ZD)),V((BL/2,-BW_/2,ZD)),V((BL/2,BW_/2,ZD)),V((-BL/2,BW_/2,ZD))],'twf_flat',(0,0,1))
    for s in (-1,1): face(b,[V((-BL/2,s*BW_/2,ZD-0.20)),V((BL/2,s*BW_/2,ZD-0.20)),V((BL/2,s*BW_/2,ZD)),V((-BL/2,s*BW_/2,ZD))],'twf_flat',(0,s,0))
    for s in (-1,1): face(b,[V((s*BL/2,-BW_/2,0.0)),V((s*BL/2,BW_/2,0.0)),V((s*BL/2,BW_/2,ZD)),V((s*BL/2,-BW_/2,ZD))],'twf_flat',(s,0,0))
# ---------------------------------------------------------------- registry
TRP=dict(WP.TR)
TRP.update({'aluminium':('tw_galv',(0.875,0.875),6.0),'stainless':('tw_galv',(0.875,0.875),6.0),'galvanized':('tw_galv',(0.875,0.875),6.0),
            'wood_natural':('tw_teak',(0.875,0.875),3.0),'wood_weathered':('tw_timber',(0.875,0.875),3.0)})
TINTP={'aluminium':(0.36,0.32,0.28),'stainless':(1.1,1.1,1.1),'galvanized':(1.0,1.0,1.0),'wood_natural':(1.0,1.0,1.0)}
_C=dict(WP._C); _C.update(dir='props/waterfront/promenade',pdir='waterfront_promenade',trim=TRP,trim_tint=TINTP,wx={'water':None,'salt':0.20,'edge':0.30,'streak':0.15,'pit':0.3},max_side=64)
def _wrap(fn,name):
    def near(b): P.reset(); P.TIER['t']='near'; fn(b); P.save_rails(name,pg.K+'/props/waterfront/_rails')
    return near
PROPS=[
 dict(name='prom_rail',near=_wrap(rail,'prom_rail'),high=lambda b: rail(b,hi=True),mid=lambda b: rail(b,tier='mid'),far=rail_far,**dict(_C,cls='medium')),
 dict(name='prom_rail_wall',near=_wrap(rail_wall,'prom_rail_wall'),high=lambda b: rail_wall(b,hi=True),mid=lambda b: rail_wall(b,tier='mid'),far=rail_wall_far,**dict(_C,cls='medium',no_bake=True)),   # all-trim piece (no baked faces): no page-W slot
 dict(name='prom_boardwalk',near=_wrap(boardwalk,'prom_boardwalk'),high=lambda b: boardwalk(b,hi=True),mid=lambda b: boardwalk(b,tier='mid'),far=boardwalk_far,**dict(_C,cls='medium',no_bake=True)),   # all-trim (timber / concrete / galv tiles)
]
