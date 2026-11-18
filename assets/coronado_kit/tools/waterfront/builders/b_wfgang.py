"""Waterfront set 2b: marina gangway (aluminium truss, ADA-style picket guards). Builder coords (Z up, seaward = -Y).
Origin = bottom centre at FLOAT-DECK level: the toe rollers and the toe transition plate rest on z=0 (float deck, world 1.95).
Frame y -4.5 (toe) .. +4.95 (pier fascia face; the deck edge is at 5.0); walkway top rises 0.20 -> 1.05 (1:11.2). The hinge leaf lies on the pier deck
y 5.0 .. 5.5 at z 1.05 (= pier deck 3.0 when the float deck is at 1.95). Toe plate y -5.5 .. -4.5 slopes to the float.
Placement: origin (x, pier_deck_edge_y - 5.0), z = float deck. Bbox y -5.5 .. 5.5 (11 m, on the 0.5 m grid)."""
import math
from mathutils import Vector
import pg
import wf_parts as P
import b_wfpier as WP
from wf_parts import PI, rect, seg_n, cbox
bolt_head=WP.bolt_head
q=WP.q; obox=WP.obox
Y0,Y1=-4.5,4.95; Z0,Z1=0.20,1.05; HW=0.62; H=1.07; DEP=0.18
def zw(y): return Z0+(y-Y0)/(Y1-Y0)*(Z1-Z0)
def W(x,y,dz=0.0): return Vector((x,y,zw(y)+dz))
NP=9; PY=[Y0+i*(Y1-Y0)/(NP-1) for i in range(NP)]
def truss_side(b,s,hi,tier):
    x=s*HW; up=Vector((0,0,1))
    # bottom chord: 50x180 rect section under the walkway edge; guard top rail (round 48 mm) and the infill frame rails
    obox(b,W(x,Y0,-DEP/2),W(x,Y1,-DEP/2),0.05,DEP,'aluminium')
    if tier=='mid':
        for o in (1,-1): q(b,[W(x+o*0.012,Y0),W(x+o*0.012,Y1),W(x+o*0.012,Y1,H-0.05),W(x+o*0.012,Y0,H-0.05)],'aluminium',(o*s,0,0))
        b.tube(W(x,Y0,H-0.024),W(x,Y1,H-0.024),0.026,0.026,6,'aluminium',cap0=True,cap1=True)
        return
    sg=seg_n(tier,hi,8,6,16)
    for i,y in enumerate(PY):   # truss posts 50x50, welded to the chord
        b.box((x,y,zw(y)),(0.05,0.05,H-0.03),'aluminium',skip=('bottom','top'))   # top capped by the guard rail
        P.rec('v',(x,y,zw(y)),(x,y,zw(y)+H-0.03),0.025)
        if hi:
            for zz in (0.12,0.95): bolt_head(b,(x+s*0.026,y,zw(y)+zz),(s,0,0),0.006,'stainless',hi)
    b.tube(W(x,Y0-0.03,H-0.024),W(x,Y1+0.03,H-0.024),0.024,0.024,seg_n(tier,hi,6,6,16),'aluminium',cap0=True,cap1=True)   # guard top rail on the posts
    P.rec('h',tuple(W(x,Y0-0.03,H-0.024)),tuple(W(x,Y1+0.03,H-0.024)),0.024)
    for zz in (0.10,0.92):   # picket frame rails between posts
        a,c=Y0+0.025,Y1-0.025   # continuous, welded through the posts; ends on the end-post faces
        obox(b,W(x,a,zz),W(x,c,zz),0.03,0.03,'aluminium',ends=(False,False))
        P.rec('h',tuple(W(x,a,zz)),tuple(W(x,c,zz)),0.015)
    # pickets 20x20 at 115 mm (4" sphere rule), between the frame rails
    for i in range(NP-1):
        a,c=PY[i]+0.025,PY[i+1]-0.025; n=int((c-a)/0.115)
        for k in range(n):
            y=a+(c-a)*(k+0.5)/n
            b.tube(W(x,y,0.115),W(x,y,0.905),0.01,0.01,4,'aluminium',cap0=False,cap1=False,sq=True)
    # ADA grab rail inside the guard, 0.86 m, on cast brackets from every post
    xi=x-s*0.085
    b.tube(W(xi,Y0+0.02,0.86),W(xi,Y1-0.02,0.86),0.019,0.019,seg_n(tier,hi,6,6,16),'aluminium',cap0=True,cap1=True)
    _gp=[W(x-s*0.025,Y0+0.02,0.86),W(xi,Y0+0.02,0.86),W(xi,Y1-0.02,0.86),W(x-s*0.025,Y1-0.02,0.86)]
    P.rec('p',tuple(_gp[0]),tuple(_gp[-1]),0.019,pts=_gp)   # one grab rail: return - run - return, both ends on end posts
    for y in PY[1:-1]:
        b.tube(W(x-s*0.025,y,0.80),W(xi+s*0.01,y,0.84),0.012,0.012,4,'aluminium',cap0=False,cap1=False,sq=True)
    for y in (Y0+0.02,Y1-0.02):   # grab-rail returns onto the end posts (no open ends)
        b.tube(W(xi,y,0.86),W(x-s*0.025,y,0.86),0.019,0.019,seg_n(tier,hi,6,6,16),'aluminium',cap0=False,cap1=False)
    for i in range(4):   # collision: rail boxes per run quarter (stepped)
        a,c=Y0+i*(Y1-Y0)/4,Y0+(i+1)*(Y1-Y0)/4
        cbox(b,(x,(a+c)/2,zw((a+c)/2)-0.05),(0.08,c-a,H+0.05),rail=True)
def walkway(b,hi,tier):
    # walkway: extruded aluminium deck, 1.24 m between the chords, 50 mm deep, with anti-slip cleats every 0.3 m
    L=Y1-Y0
    q(b,[W(-HW,Y0,0),W(HW,Y0,0),W(HW,Y1,0),W(-HW,Y1,0)],'aluminium',(0,0,1))
    q(b,[W(-HW,Y0,-0.05),W(-HW,Y1,-0.05),W(HW,Y1,-0.05),W(HW,Y0,-0.05)],'aluminium',(0,0,-1))
    for y,o in ((Y0,-1),(Y1,1)): q(b,[W(-HW,y,-DEP),W(HW,y,-DEP),W(HW,y,0),W(-HW,y,0)],'aluminium',(0,o,0))   # end channels
    if tier=='mid': return
    n=int(L/0.4)
    for k in range(n):   # cleats: 25x12 mm transverse, ends die into the kick rails
        y=Y0+0.15+k*L/n
        obox(b,W(-HW+0.025,y,0.006),W(HW-0.025,y,0.006),0.025,0.012,'rubber_black' if hi else 'aluminium',up=(0,0,1),ends=(False,False),skip=('bottom',))
    for i in range(NP):   # floor beams under the deck at every post
        y=PY[i]; obox(b,W(-HW+0.025,y,-0.05-0.04),W(HW-0.025,y,-0.05-0.04),0.05,0.08,'aluminium',ends=(False,False),skip=('top',))
    if hi:   # extrusion grooves on the walk surface (bake only)
        for k in range(1,24): obox(b,W(-HW+k*0.0517,Y0+0.02,0.0015),W(-HW+k*0.0517,Y1-0.02,0.0015),0.004,0.003,'aluminium',ends=(False,False),skip=('bottom',))
    # utility run under the west chord: shore-power cable + potable-water hose, clipped at each floor beam
    for dx,r,k in ((0.06,0.018,'rubber_black'),(0.11,0.014,'plastic_blue')):
        b.tube(W(-HW+dx,Y0+0.05,-0.14),W(-HW+dx,Y1-0.05,-0.14),r,r,6,k,cap0=True,cap1=True)
    for y in PY[1:-1]: b.box((-HW+0.085,y,zw(y)-0.17),(0.12,0.02,0.04),'stainless',skip=('top',))
    for i in range(4):
        a,c=Y0+i*(Y1-Y0)/4,Y0+(i+1)*(Y1-Y0)/4
        cbox(b,(0,(a+c)/2,zw(c)-DEP),(2*HW,c-a,DEP))
def toe(b,hi,tier):
    sg=seg_n(tier,hi,10,6,24)
    # nylon toe rollers r=0.10 on stainless axles in fork brackets bolted under the chords
    for s in (-1,1):
        x=s*0.45; y=Y0+0.25
        b.tube((x-0.05,y,0.10),(x+0.05,y,0.10),0.10,0.10,sg,'plastic_white',cap0=True,cap1=True)
        if tier=='mid': continue
        for o in (-1,1):
            b.box((x+o*0.065,y,0.10),(0.012,0.16,zw(y)-DEP-0.10+0.002),'stainless',skip=())   # fork cheeks up to the chord
        b.tube((x-0.08,y,0.10),(x+0.08,y,0.10),0.012,0.012,6,'stainless',cap0=True,cap1=True)
        bolt_head(b,(x+0.08,y,0.10),(1,0,0),0.012,'stainless',hi); bolt_head(b,(x-0.08,y,0.10),(-1,0,0),0.012,'stainless',hi)
        b.box((x,y,zw(y)-DEP-0.012),(0.16,0.20,0.012),'stainless',skip=())   # fork plate
    # toe transition plate (diamond tread), piano hinge on the end channel, lip resting on the float deck
    t=0.012; pz=Vector((0,0,1))
    q(b,[Vector((-HW+0.04,-5.5,0.0)),Vector((HW-0.04,-5.5,0.0)),W(HW-0.04,Y0,-0.005),W(-HW+0.04,Y0,-0.005)],'aluminium',(0,0,1))
    q(b,[Vector((-HW+0.04,-5.5,0.0)),Vector((-HW+0.04,-5.5,0.0))+pz*t,Vector((HW-0.04,-5.5,0.0))+pz*t,Vector((HW-0.04,-5.5,0.0))],'aluminium',(0,-1,0)) if hi else None
    b.tube(W(-HW+0.04,Y0,-0.005),W(HW-0.04,Y0,-0.005),0.014,0.014,seg_n(tier,hi,6,4,12),'stainless',cap0=True,cap1=True)
    cbox(b,(0,-5.0,0.0),(2*HW-0.08,1.0,0.1))
    # rubber lip strip on the plate nose
    if tier!='mid': obox(b,(-HW+0.05,-5.47,0.006),(HW-0.05,-5.47,0.006),0.05,0.012,'rubber_black',ends=(True,True),skip=('bottom',))
def head(b,hi,tier):
    # deck-mounted hinge: two knuckle sets on base plates lag-bolted to the pier deck, hinge leaf plate on the deck y 5.0..5.5
    sg=seg_n(tier,hi,8,6,16)
    q(b,[W(-HW+0.04,Y1,0.008),W(HW-0.04,Y1,0.008),Vector((HW-0.04,5.5,Z1+0.012)),Vector((-HW+0.04,5.5,Z1+0.012))],'aluminium',(0,0,1))
    for x0,x1 in ((-HW+0.04,HW-0.04),):
        q(b,[Vector((x0,5.5,Z1)),Vector((x1,5.5,Z1)),Vector((x1,5.5,Z1+0.012)),Vector((x0,5.5,Z1+0.012))],'aluminium',(0,1,0))
    for s in (-1,1):
        x=s*(HW-0.02)
        b.tube((x-s*0.0,Y1+0.06,Z1+0.035),(x-s*0.16,Y1+0.06,Z1+0.035),0.035,0.035,sg,'stainless',cap0=True,cap1=True)
        if tier!='mid':
            b.box((x-s*0.08,Y1+0.10,Z1),(0.22,0.18,0.012),'stainless',skip=('bottom',))
            for k in range(4): bolt_head(b,(x-s*(0.01+0.05*k),Y1+0.17,Z1+0.012),(0,0,1),0.008,'stainless',hi)
            b.box((x-s*0.08,Y1+0.02,zw(Y1)-0.12),(0.2,0.012,0.15),'stainless',skip=())   # hinge strap on the end channel
    cbox(b,(0,5.25,Z1-0.002),(2*HW-0.08,0.5,0.03))
def gangway(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier
    if tier=='near' and not hi: P.reset()
    for s in (-1,1): truss_side(b,s,hi,tier)
    walkway(b,hi,tier); toe(b,hi,tier); head(b,hi,tier)
def gangway_far(b):
    # side band (double-sided, x=0: both trusses project onto it), walk top, toe plate
    q(b,[W(0,Y0,-DEP),W(0,Y1,-DEP),W(0,Y1,H),W(0,Y0,H)],'twf_flat',(-1,0,0))
    q(b,[W(-HW-0.03,Y0,H*0+0.0),W(HW+0.03,Y0,0.0),W(HW+0.03,Y1,0.0),W(-HW-0.03,Y1,0.0)],'twf_flat',(0,0,1))
    q(b,[Vector((-HW,-5.5,0.0)),Vector((HW,-5.5,0.0)),W(HW,Y0,0),W(-HW,Y0,0)],'twf_flat',(0,0,1))
    q(b,[W(-HW,Y1,0),W(HW,Y1,0),Vector((HW,5.5,Z1)),Vector((-HW,5.5,Z1))],'twf_flat',(0,0,1))
    for s in (-1,1): q(b,[Vector((s*0.45,Y0+0.15,0.0)),Vector((s*0.45,Y0+0.35,0.0)),Vector((s*0.45,Y0+0.35,0.2)),Vector((s*0.45,Y0+0.15,0.2))],'twf_flat',(1,0,0))
TR=dict(WP.TR); TR['aluminium']=('tw_galv',(0.875,0.875),10.0)   # extrusions: one long cell per member (brushed grain runs along it)
_C=dict(WP._C); _C.update(dir='props/waterfront/gangway',pdir='waterfront_gangway',trim=TR,wx={'water':-9,'algae':0.0,'barnacle':0.0,'salt':0.35,'edge':0.3,'streak':0.1})
def _wrap(fn,name):
    def near(b): fn(b); P.save_rails(name,pg.K+'/props/waterfront/_rails')
    return near
PROPS=[dict(name='gangway',near=_wrap(gangway,'gangway'),high=lambda b: gangway(b,hi=True),mid=lambda b: gangway(b,tier='mid'),far=gangway_far,max_side=128,**_C)]
