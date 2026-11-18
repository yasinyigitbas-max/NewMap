"""Waterfront set 2: timber pier (snap-in, 0.5 m grid). Reference (shape only): Coronado Ferry Landing / Oceanside pier:
creosoted round timber piles in 3 m bents, double-depth cap beams, X-bracing, 3x12 stringers at 0.6 m, 2x6 deck planks with
gaps, fascia boards, bull rail (curb) on spacer blocks, horn cleats, timber guard railing, galvanized ladders and lamps.
Datum as the quay: z=0 harbour bed, still water 1.5, deck top 3.0. Modules run along Y (seaward = -Y), 4.0 m wide.
pier_straight / pier_rail_end: x -2..2, y -3..3 (tile along Y every 6 m). pier_thead: x -6..6, y -3..3; its back edge
(y=+3, x -2..2) takes a pier module (T-head origin = pier origin - 6 m in Y). Module ends are open (snap rule 1).
quay_pier_root: 6 m quay module whose middle 4 m carries a timber landing from the fender line y=-1.0 to the paving, so a pier
module placed with origin (x, -4.0) butts onto it plank-to-plank."""
import math
from mathutils import Vector, Matrix
import pg
import wf_parts as P
from wf_parts import rect, rec, cbox, ccyl, cleat, ladder, nut, seg_n, WL, DECK
def bolt_head(b,c,axis,r=0.012,key='galvanized',hi=False):
    """pier bolt: full washer + hex nut + thread stub in the high-poly, a square nut (10 tris) on the low-poly"""
    if hi: return P.bolt_head(b,c,axis,r,key,True)
    nut(b,Vector(c),axis,r*1.15,r*0.8,key,sides=4)
def cleat_lite(b,c,rz=0.0,hi=False,tier='near',key='galvanized'):
    """horn cleat; the low-poly drops the foot plates and uses 6-sided horns (~70 tris), the high-poly is the full cast cleat"""
    if hi: return cleat(b,c,rz,True,tier,key)
    x,y,z=c; R=Matrix.Rotation(rz,3,'Z'); Pp=lambda a,bb,cc: Vector((x,y,z))+R@Vector((a,bb,cc)); L=0.46
    for s_ in (-1,1): b.tube(Pp(s_*0.09,0,0),Pp(s_*0.08,0,0.075),0.045,0.032,6,key,cap0=False,cap1=False)
    b.sweep([Pp(-L/2,0,0.095),Pp(0,0,0.08),Pp(L/2,0,0.095)],0.028,6,key,cap0=True,cap1=True)
import b_wfquay as Q
PI=math.pi
ZP=2.94; ZS=2.64; ZCAP=2.34          # plank underside, stringer underside, cap underside
PL_W=0.14; PL_G=0.01                  # plank width / gap (0.15 pitch)
def q(b,pts,key,out):
    """quad with an explicit outward direction (flipped to match)"""
    pts=[Vector(p) for p in pts]; n=Vector((0,0,0))
    for i in range(len(pts)): n+=pts[i].cross(pts[(i+1)%len(pts)])
    if n.dot(Vector(out))<0: pts=pts[::-1]
    return b.quad(pts,key)
def obox(b,p0,p1,w,h,key,up=(0,0,1),ends=(True,True),skip=()):
    """box along p0->p1, section w (side) x h (up), centred on the segment"""
    p0=Vector(p0); p1=Vector(p1); d=(p1-p0).normalized(); u=Vector(up)
    s=u.cross(d).normalized(); uu=d.cross(s).normalized()
    C=lambda p,a,c: p+s*(a*w/2)+uu*(c*h/2)
    F={'top':([C(p0,-1,1),C(p1,-1,1),C(p1,1,1),C(p0,1,1)],uu),'bottom':([C(p0,-1,-1),C(p0,1,-1),C(p1,1,-1),C(p1,-1,-1)],-uu),
       's1':([C(p0,1,-1),C(p0,1,1),C(p1,1,1),C(p1,1,-1)],s),'s0':([C(p0,-1,-1),C(p1,-1,-1),C(p1,-1,1),C(p0,-1,1)],-s)}
    for k,(pts,o) in F.items():
        if k not in skip: q(b,pts,key,o)
    if ends[0]: q(b,[C(p0,-1,-1),C(p0,-1,1),C(p0,1,1),C(p0,1,-1)],key,-d)
    if ends[1]: q(b,[C(p1,-1,-1),C(p1,1,-1),C(p1,1,1),C(p1,-1,1)],key,d)
def plank(b,x0,x1,yc,hi,tier,ends=(True,True),sides=(True,True)):
    """2x6 deck plank along X; the high-poly has 5 mm arris chamfers, a cupped top and nail heads over each stringer"""
    w=PL_W; t=DECK-ZP
    if not hi:   # low-poly: plank sides only where a module edge exposes them (1 cm gaps hide the rest)
        obox(b,(x0,yc,ZP+t/2),(x1,yc,ZP+t/2),w,t,'wood_weathered',skip=('bottom',)+tuple(k for k,e in (('s0',sides[0]),('s1',sides[1])) if not e),ends=ends); return
    c=0.005; prof=[(-w/2,ZP),(-w/2,DECK-c),(-w/2+c,DECK),(0,DECK-0.0015),(w/2-c,DECK),(w/2,DECK-c),(w/2,ZP)]
    for i in range(len(prof)-1):
        (a,za),(cc,zc)=prof[i],prof[i+1]
        nrm=Vector((0,(zc-za),-(cc-a)))*-1
        q(b,[(x0,yc+a,za),(x1,yc+a,za),(x1,yc+cc,zc),(x0,yc+cc,zc)],'wood_weathered',Vector((0,-(zc-za),(cc-a))))
    for xe,sg in ((x0,-1),(x1,1)):
        if ends[0 if sg<0 else 1]: q(b,[Vector((xe,yc+a,z)) for a,z in prof],'wood_weathered',(sg,0,0))
def nails(b,x,yc):
    for dy in (-0.04,0.04): b.tube((x,yc+dy,DECK-0.0015),(x,yc+dy,DECK+0.0015),0.0045,0.0045,6,'galvanized',cap0=False,cap1=True)
def pile(b,x,y,hi,tier,ztop=ZCAP,r=0.17,cap=False):
    sg=seg_n(tier,hi,8,6,24)
    if hi:   # slight natural taper, check cracks as shallow grooves, drift-bolt head under the cap
        b.tube((x,y,0),(x,y,ztop),r+0.012,r,sg,'wood_pole',cap0=False,cap1=cap)
        for k in range(3):
            a=k*2.1+0.4; b.box((x+(r+0.004)*math.cos(a),y+(r+0.004)*math.sin(a),0.4+k*0.5),(0.012,0.006,0.9),'wood_pole',rz=a+PI/2)
    else: b.tube((x,y,0),(x,y,ztop),r+0.006,r,sg,'wood_pole',cap0=False,cap1=cap)
    if cap and tier!='mid':   # galvanized pile cap (cone) on a pile standing proud of the deck structure
        b.tube((x,y,ztop),(x,y,ztop+0.02),r+0.015,r+0.015,sg,'galvanized',cap0=False,cap1=False)
        b.tube((x,y,ztop+0.02),(x,y,ztop+0.07),r+0.015,0.0,sg,'galvanized',cap0=False,cap1=False)
    ccyl(b,(x,y,0),r,ztop,rail=True)
def bent(b,y,xs,hi,tier,cap_x=None,r=0.17):
    """one 3 m bent: piles, double cap beam (2 x 3x12 bolted either side of the pile heads -> read as one 0.30 deep cap),
    X-braces between pile pairs on both faces, through-bolts"""
    x0,x1=cap_x or (min(xs)-0.25,max(xs)+0.25)
    for x in xs: pile(b,x,y,hi,tier,r=r)
    if tier=='mid':
        b.box(((x0+x1)/2,y,ZCAP),(x1-x0,0.30,ZS-ZCAP),'wood_weathered',skip=('top',)); return
    for s in (-1,1):   # two cap timbers
        obox(b,(x0,y+s*0.08,ZCAP+0.15),(x1,y+s*0.08,ZCAP+0.15),0.14,0.30,'wood_weathered',skip=('top',))
    for x in xs:
        for zz in (ZCAP+0.09,ZCAP+0.21):
            bolt_head(b,(x,y-0.15,zz),(0,-1,0),0.014,'galvanized',hi)
            if hi: bolt_head(b,(x,y+0.15,zz),(0,1,0),0.014,'galvanized',hi)
    xs=sorted(xs)
    for i in range(0,len(xs)-1,1):
        if i%2: continue
        a,c=xs[i],xs[i+1]
        for s,(za,zc) in ((-1,(0.85,ZCAP-0.05)),(1,(ZCAP-0.05,0.85))):
            yy=y+s*(r+0.045)
            obox(b,(a,yy,za),(c,yy,zc),0.07,0.20,'wood_weathered',up=(0,0,1))
            if tier!='mid':
                for xx,zz in ((a,za),(c,zc)):
                    if hi or zz>WL: bolt_head(b,(xx,yy+s*0.035,zz),(0,s,0),0.013,'galvanized',hi)   # low-poly: submerged bolts dropped
def stringers(b,xs,y0,y1,hi,tier,ends=(False,False)):
    for x in xs: obox(b,(x,y0,(ZS+ZP)/2),(x,y1,(ZS+ZP)/2),0.075,ZP-ZS,'wood_weathered',skip=('top',) if hi else ('top','bottom'),ends=ends)
def deck(b,x0,x1,y0,y1,hi,tier,strx,cut=None,ends=(False,False)):
    """planks across X at 0.15 pitch; cut=(cx0,cx1,cy0) leaves a gap (not used yet)"""
    if tier=='mid':
        rect(b,(x0,y0,DECK),(x1-x0,0,0),(0,y1-y0,0),'wood_weathered')
        rect(b,(x0,y1,ZS),(x1-x0,0,0),(0,y0-y1,0),'wood_weathered'); return
    n=int(round((y1-y0)/(PL_W+PL_G)))
    for i in range(n):
        yc=y0+(i+0.5)*(y1-y0)/n
        plank(b,x0,x1,yc,hi,tier,ends=ends,sides=(i==0,i==n-1))
        if hi:
            for x in strx: nails(b,x,yc)
def fascia(b,p0,p1,out,hi,tier):
    """2x12 fascia board on the stringer ends / outer stringer, top flush with the deck"""
    p0=Vector(p0); p1=Vector(p1); o=Vector(out).normalized()*0.05
    rect_pts=[p0+Vector((0,0,ZS-0.04)),p1+Vector((0,0,ZS-0.04)),p1+Vector((0,0,DECK)),p0+Vector((0,0,DECK))]
    q(b,[p+o for p in rect_pts],'wood_weathered',o)
    q(b,[rect_pts[3],rect_pts[2],rect_pts[2]+o,rect_pts[3]+o],'wood_weathered',(0,0,1))
    q(b,[rect_pts[0],rect_pts[1],rect_pts[1]+o,rect_pts[0]+o],'wood_weathered',(0,0,-1))
    if tier!='mid':
        L=(p1-p0).length; n=max(1,int(L/1.5))
        for k in range(n+1):
            pp=p0+(p1-p0)*(k/n if n else 0)
            if hi: bolt_head(b,pp+o+Vector((0,0,ZS+0.05)),o,0.012,'galvanized',hi)
def curb(b,p0,p1,out,hi,tier,gaps=(),open_gaps=()):
    """bull rail: 6x6 timber on 4x6 spacer blocks every 1.5 m (scupper gaps), set 0.10 in from the deck edge.
    gaps: list of t (0..1) where a cleat sits in a gap in the rail."""
    # open_gaps: t or (t, half-width m) -- e.g. a gangway landing needs (t, 0.75)
    og=[(g,0.35) if not isinstance(g,(tuple,list)) else tuple(g) for g in open_gaps]
    if tier=='mid':
        p0=Vector(p0); p1=Vector(p1); o=Vector(out).normalized(); L=(p1-p0).length; d=(p1-p0)/L
        a=p0-o*0.175; t0=0.0
        for g,hw in sorted(og)+[(1.0+0.35/L,0.35)]:   # mid keeps only the wide openings (cleat gaps are filled)
            if g*L-hw-t0>=0.3:
                A=a+d*t0; C=a+d*min(L,g*L-hw); obox(b,(A.x,A.y,DECK+0.125),(C.x,C.y,DECK+0.125),0.15,0.25,'wood_weathered',skip=('bottom',))
            t0=g*L+hw
        return
    p0=Vector(p0); p1=Vector(p1); o=Vector(out).normalized(); L=(p1-p0).length; d=(p1-p0)/L
    a=p0-o*0.175; c=p1-o*0.175
    segs=[]; t0=0.0
    for g,hw in sorted([(g,0.35) for g in gaps]+og): segs.append((t0,g*L-hw)); t0=g*L+hw
    segs.append((t0,L))
    for s0,s1 in segs:
        if s1-s0<0.3: continue
        A=a+d*s0; C=a+d*s1
        obox(b,(A.x,A.y,DECK+0.175),(C.x,C.y,DECK+0.175),0.15,0.15,'wood_weathered',skip=('bottom',))
        nb=max(2,int(round((s1-s0)/2.0))+1)
        for k in range(nb):
            t=s0+0.1+(s1-s0-0.2)*k/(nb-1); B=a+d*t
            obox(b,(B.x-d.x*0.07,B.y-d.y*0.07,DECK+0.05),(B.x+d.x*0.07,B.y+d.y*0.07,DECK+0.05),0.12,0.10,'wood_weathered',skip=('bottom',) if hi else ('bottom','top'))
            if hi: bolt_head(b,(B.x,B.y,DECK+0.25),(0,0,1),0.014,'galvanized',hi)
        m=(A+C)/2; ang=math.atan2(d.y,d.x); cbox(b,(m.x,m.y,DECK),(s1-s0,0.15,0.25),rz=ang,rail=False)
    for g in gaps:
        B=a+d*(g*L); cleat_lite(b,(B.x,B.y,DECK),rz=math.atan2(d.y,d.x),hi=hi,tier=tier)
def rubstrip(b,x,y,sx,hi,tier,z0=1.0):
    """vertical 6x8 rubbing strip bolted to the outer pile and the fascia (boats lie against these)"""
    xx=x+sx*0.075
    obox(b,(xx,y,z0),(xx,y,DECK-0.01),0.20,0.15,'wood_weathered',up=(sx,0,0),ends=(True,True))
    if tier!='mid':
        for zz in (z0+0.25,ZS+0.15): bolt_head(b,(xx+sx*0.075,y,zz),(sx,0,0),0.014,'galvanized',hi)
def timber_rail(b,pts,hi,tier,H=1.07,spacing=1.5,gate=None):
    """4x4 posts on the deck edge (bolted through the fascia), 2x4 mid + top rails between post faces (railcheck: every rail
    end meets a post), chamfered post tops. Posts are recorded as grounded 'v' members, rails as 'h'."""
    if tier=='mid':
        for i in range(len(pts)-1):
            a=Vector(pts[i]); c=Vector(pts[i+1])
            obox(b,a+Vector((0,0,H-0.05)),c+Vector((0,0,H-0.05)),0.06,0.10,'wood_weathered')
            for p in (a,c): b.box((p.x,p.y,p.z),(0.09,0.09,H),'wood_weathered',skip=('bottom',))
        return
    posts=[]
    for i in range(len(pts)-1):
        a=Vector(pts[i]); c=Vector(pts[i+1]); L=(c-a).length; n=max(1,math.ceil(L/spacing-1e-6))
        for k in range(n): posts.append(a+(c-a)*(k/n))
    posts.append(Vector(pts[-1])); pw=0.09
    for p in posts:
        b.box((p.x,p.y,p.z),(pw,pw,H-0.02),'wood_weathered',skip=('bottom','top'))
        top=p+Vector((0,0,H-0.02)); hp=pw/2
        b.faces([top+Vector((-hp,-hp,0)),top+Vector((hp,-hp,0)),top+Vector((hp,hp,0)),top+Vector((-hp,hp,0)),top+Vector((0,0,0.03))],
                [(0,1,4),(1,2,4),(2,3,4),(3,0,4)],'wood_weathered',[[(0,0),(0.09,0),(0.045,0.05)]]*4)
        rec('v',tuple(p),tuple(top),pw/2)
        if hi:
            for zz in (0.35,0.75): bolt_head(b,(p.x,p.y-hp,p.z+zz),(0,-1,0),0.01,'galvanized',hi)
    for k in range(len(posts)-1):
        a=posts[k]; c=posts[k+1]; d=(c-a); d.z=0; d.normalize()
        for zz,h_ in ((H-0.10,0.09),(0.52,0.09)):
            p0=a+d*(pw/2)+Vector((0,0,zz)); p1=c-d*(pw/2)+Vector((0,0,zz))
            obox(b,p0,p1,0.04,h_,'wood_weathered')
            rec('h',tuple(p0),tuple(p1),0.02)
            if hi:
                for pp in (p0,p1): bolt_head(b,pp+d*(0.03 if pp is p0 else -0.03)+Vector((0,0,0))+d.cross(Vector((0,0,1)))*0.02,d.cross(Vector((0,0,1))),0.007,'galvanized',hi)
    for i in range(len(pts)-1):
        a=Vector(pts[i]); c=Vector(pts[i+1]); m=(a+c)/2; L=(c-a).length; ang=math.atan2(c.y-a.y,c.x-a.x)
        cbox(b,(m.x,m.y,a.z),(L+0.09,0.10,H+0.02),rz=ang,rail=True)
def lamp(b,x,y,hi,tier,z=DECK):
    """harbour lamp: galvanized pole on a bolted base, cast cap, acorn lantern (glass is opaque dark here: no alpha)"""
    sg=seg_n(tier,hi,10,8,24)
    if hi: P.base_plate(b,(x,y,z),0.26,0.02,'galvanized',hi,4,0.01)
    else: b.box((x,y,z),(0.26,0.26,0.02),'galvanized',skip=('bottom',))
    prof=[(0.075,z+0.02),(0.07,z+0.30),(0.055,z+0.36),(0.05,z+3.3),(0.07,z+3.34),(0.07,z+3.38)]
    if tier=='mid': prof=[(0.072,z+0.02),(0.055,z+0.36),(0.05,z+3.3),(0.07,z+3.38)]
    b.lathe(prof,sg,'paint_black',c=(x,y,0),cap_top=False)
    b.lathe([(0.10,z+3.38),(0.16,z+3.50),(0.17,z+3.72),(0.12,z+3.86),(0.0,z+3.88)],sg,'glass_dark',c=(x,y,0),cap_top=False)
    b.lathe([(0.18,z+3.86),(0.20,z+3.90),(0.10,z+3.98),(0.03,z+4.06),(0.0,z+4.10)],sg,'paint_black',c=(x,y,0),cap_top=False)
    ccyl(b,(x,y,z),0.08,3.4,rail=True)
# ---------------------------------------------------------------- pier modules
PX4=(-1.75,-0.58,0.58,1.75)
STRX4=[-1.85+i*0.617 for i in range(7)]
def _common4(b,hi,tier):
    for y in (-1.5,1.5): bent(b,y,PX4,hi,tier,cap_x=(-1.98,1.98))
    if tier!='mid': stringers(b,STRX4,-3.0,3.0,hi,tier)
    deck(b,-2.0,2.0,-3.0,3.0,hi,tier,STRX4)
    for s in (-1,1): fascia(b,(s*2.0,3.0 if s<0 else -3.0,0),(s*2.0,-3.0 if s<0 else 3.0,0),(s,0,0),hi,tier)
    cbox(b,(0,0,ZS),(4.0,6.0,DECK-ZS))
def straight(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier
    if tier=='near' and not hi: P.reset()
    _common4(b,hi,tier)
    for s in (-1,1):
        curb(b,(s*2.0,-3.0,0),(s*2.0,3.0,0),(s,0,0),hi,tier,gaps=(0.5,))
        if tier!='mid':
            for y in (-1.5,1.5): rubstrip(b,s*1.93,y,s,hi,tier)
def straight_hi(b): straight(b,hi=True)
def straight_mid(b): straight(b,tier='mid')
def rail_end(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier
    if tier=='near' and not hi: P.reset()
    _common4(b,hi,tier)
    fascia(b,(-2.05,-3.0,0),(2.05,-3.0,0),(0,-1,0),hi,tier)          # end fascia closes the deck
    if tier=='mid':
        rect(b,(-2.0,-3.05,ZS-0.04),(4.0,0,0),(0,0,DECK-ZS+0.04),'wood_weathered')
    timber_rail(b,[(-1.93,3.0,DECK),(-1.93,-2.93,DECK),(1.93,-2.93,DECK),(1.93,3.0,DECK)],hi,tier)
    if tier!='mid':
        for s in (-1,1):
            for y in (-1.5,1.5): rubstrip(b,s*1.93,y,s,hi,tier)
        # fishing bench against the end rail
        for x in (-0.9,0.9): b.box((x,-2.55,DECK),(0.08,0.36,0.42),'wood_weathered',skip=('bottom',))
        b.box((0,-2.55,DECK+0.42),(2.2,0.40,0.05),'wood_weathered',skip=())
        cbox(b,(0,-2.55,DECK),(2.2,0.4,0.47))
def rail_end_hi(b): rail_end(b,hi=True)
def rail_end_mid(b): rail_end(b,tier='mid')
PX12=(-5.6,-3.3,-1.1,1.1,3.3,5.6)
STRX12=[-5.85]+[-1.85+i*0.617 for i in range(-6,13)]+[5.85]   # middle 4 m on the straight module's stringer lines so they continue across the joint
def thead(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier
    if tier=='near' and not hi: P.reset()
    for y in (-1.5,1.5): bent(b,y,PX12,hi,tier,cap_x=(-5.98,5.98))
    if tier!='mid': stringers(b,STRX12,-3.0,3.0,hi,tier)
    deck(b,-6.0,6.0,-3.0,3.0,hi,tier,STRX12)
    fascia(b,(-6.05,-3.0,0),(6.05,-3.0,0),(0,-1,0),hi,tier)
    for s in (-1,1): fascia(b,(s*6.0,-3.0,0),(s*6.0,3.0,0),(s,0,0),hi,tier)
    for s in (-1,1): fascia(b,(s*2.0,3.0,0),(s*6.05,3.0,0),(0,1,0),hi,tier)
    if tier=='mid':
        rect(b,(-6.0,-3.05,ZS-0.04),(12.0,0,0),(0,0,DECK-ZS+0.04),'wood_weathered')
    curb(b,(-6.0,-3.0,0),(6.0,-3.0,0),(0,-1,0),hi,tier,gaps=(0.25,0.75),open_gaps=(0.5,))
    for s in (-1,1):
        if s<0: curb(b,(s*6.0,-3.0,0),(s*6.0,3.0,0),(s,0,0),hi,tier,gaps=(0.2,),open_gaps=((3.5/6.0,0.75),))   # west: gangway landing gap centred y=+0.5 (on grid), +-0.75
        else: curb(b,(s*6.0,-3.0,0),(s*6.0,3.0,0),(s,0,0),hi,tier,gaps=(0.5,))
        curb(b,(s*2.15,3.0,0),(s*6.0,3.0,0),(0,1,0),hi,tier)
    if tier!='mid':
        for x in (-4.45,4.45):   # vertical rubbing strips on the seaward face between the piles
            Q._rot_part(b,lambda: rubstrip(b,0.0,0.0,1,hi,tier),-PI/2,(x,-3.0,0))
    # boarding ladder on the seaward face (curb gap at x=0) on its own backing pile; hoops land on the deck
    pile(b,0.0,-3.22,hi,tier,ztop=ZS,r=0.15,cap=True)
    ladder(b,0.0,-3.37,0.6,DECK,hi,tier,stand=0.13,yland=0.80)
    cbox(b,(0,0,ZS),(12.0,6.0,DECK-ZS))
def thead_hi(b): thead(b,hi=True)
def thead_mid(b): thead(b,tier='mid')
def pier_lamp(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier
    if tier=='near' and not hi: P.reset()
    lamp(b,0,0,hi,tier,z=0.0)
    if tier=='mid': return
    sg=seg_n(tier,hi,10,5,24)
    for k in range(6):   # lantern frame ribs
        a=k*PI/3; b.box((0.172*math.cos(a),0.172*math.sin(a),3.50),(0.016,0.016,0.22),'paint_black',rz=a,skip=('bottom','top'))
    b.lathe([(0.105,0.36),(0.105,0.80),(0.09,0.84)],sg,'paint_black',c=(0,0,0),cap_top=True)        # base shroud with access door
    b.box((0,-0.105,0.45),(0.09,0.012,0.26),'paint_black',skip=('back',))
    b.lathe([(0.03,4.10),(0.03,4.16),(0.045,4.19),(0.0,4.24)],sg,'paint_black',c=(0,0,0),cap_top=False) # finial
    if hi:
        for zz in (0.36,0.80,3.3): b.lathe([(0.07 if zz>1 else 0.108,zz-0.006),(0.078 if zz>1 else 0.114,zz),(0.07 if zz>1 else 0.108,zz+0.006)],sg,'paint_black',c=(0,0,0),cap_top=False)
        bolt_head(b,(0.0,-0.118,0.52),(0,-1,0),0.006,'paint_black',True)
def pier_lamp_far(b):
    # crossed double-sided cards (pole + lantern) and an octagonal cap: matches the 8-sided mid in every ortho view
    for n,t in ((Vector((0,-1,0)),Vector((1,0,0))),(Vector((-1,0,0)),Vector((0,-1,0)))):
        for (w0,z0,z1) in ((0.055,0.0,3.38),(0.18,3.38,4.10)):
            q(b,[-t*w0+Vector((0,0,z0)),t*w0+Vector((0,0,z0)),t*w0+Vector((0,0,z1)),-t*w0+Vector((0,0,z1))],'twf_flat',n)
    r=0.2; z=3.9; pts=[Vector((r*math.cos(k*PI/4+PI/8),r*math.sin(k*PI/4+PI/8),z)) for k in range(8)]
    b.poly(pts,'twf_flat')
# ---------------------------------------------------------------- far tiers (open hull, painted from mid)
def _far(b,x0,x1,y0,y1,bents,pxs,end=False,top=DECK+0.25,under=True):
    rect(b,(x0,y0,DECK),(x1-x0,0,0),(0,y1-y0,0),'twf_flat')
    if under: rect(b,(x0,y1,ZS),(x1-x0,0,0),(0,y0-y1,0),'twf_flat')
    for s,x in ((-1,x0),(1,x1)):
        q(b,[(x,y0,ZS),(x,y1,ZS),(x,y1,top),(x,y0,top)],'twf_flat',(s,0,0))
    if end: q(b,[(x0,y0,ZS),(x1,y0,ZS),(x1,y0,top),(x0,y0,top)],'twf_flat',(0,-1,0))
    for y in bents:   # each bent (piles + cap) collapses to one post silhouette per side view
        for s,x in ((-1,x0+0.25),(1,x1-0.25)):
            q(b,[(x,y-0.18,0),(x,y+0.18,0),(x,y+0.18,ZS),(x,y-0.18,ZS)],'twf_flat',(s,0,0))
def straight_far(b): _far(b,-2.0,2.0,-3.0,3.0,(-1.5,1.5),PX4)
def _pile45(b,x,y,z1,w=0.51):
    """far: one double-sided quad at 45 deg in plan; projects to a 0.36 m pile in both the end and the side view"""
    d=Vector((0.7071,-0.7071,0))*(w/2)
    q(b,[Vector((x,y,0))-d,Vector((x,y,0))+d,Vector((x,y,z1))+d,Vector((x,y,z1))-d],'twf_flat',(-1,-1,0))
def rail_end_far(b):
    x0,x1,y0,y1=-2.0,2.0,-3.0,3.0; H=1.07
    rect(b,(x0,y0,DECK),(x1-x0,0,0),(0,y1-y0,0),'twf_flat')
    q(b,[(x0,y0,ZCAP),(x1,y0,ZCAP),(x1,y0,DECK),(x0,y0,DECK)],'twf_flat',(0,-1,0))                   # end deck band + caps
    q(b,[(x0,y0,DECK+H-0.12),(x1,y0,DECK+H-0.12),(x1,y0,DECK+H),(x0,y0,DECK+H)],'twf_flat',(0,-1,0)) # end top rail
    q(b,[(x0,y0,ZS),(x0,y1,ZS),(x0,y1,DECK),(x0,y0,DECK)],'twf_flat',(-1,0,0))                       # side deck band
    q(b,[(x0,y0,DECK+H-0.12),(x0,y1,DECK+H-0.12),(x0,y1,DECK+H),(x0,y0,DECK+H)],'twf_flat',(-1,0,0)) # side top rail
    for x in PX4: _pile45(b,x,-1.5,ZCAP)
    _pile45(b,PX4[0],1.5,ZCAP)   # back bent: hidden behind a front pile in the end view
def thead_far(b):
    x0,x1,y0,y1=-6.0,6.0,-3.0,3.0; top=DECK+0.25
    rect(b,(x0,y0,DECK),(x1-x0,0,0),(0,y1-y0,0),'twf_flat')
    q(b,[(x0,y0,ZCAP),(x1,y0,ZCAP),(x1,y0,top),(x0,y0,top)],'twf_flat',(0,-1,0))
    q(b,[(x0,y0,ZS),(x0,y1,ZS),(x0,y1,top),(x0,y0,top)],'twf_flat',(-1,0,0))
    for i,x in enumerate(PX12): _pile45(b,x,-1.5 if i%2 else 1.5,ZCAP)   # alternate bents: end view sees all 6, side view both bents
    _pile45(b,0.0,-3.25,DECK,w=0.6)   # ladder + its backing pile

# ---------------------------------------------------------------- quay module that takes a pier
def pier_root(b,hi=False,tier='near'):
    """quay straight whose middle 4 m (x -2..2) is a timber landing: the seawall steps back under it to a concrete ledge
    (wall top 2.34), the landing's stringers bear on the ledge, planks run from the fender line y=-1.0 to the paving."""
    P.TIER['t']='hi' if hi else tier
    if tier=='near' and not hi: P.reset()
    YF=Q.YF
    Q.wall_and_coping(b,[(-3.0,YF),(-2.0,YF)],tier,hi,caps=(False,True)); Q.wall_and_coping(b,[(2.0,YF),(3.0,YF)],tier,hi,caps=(True,False))
    Q.safety_line(b,[(-3.0,Q.YC),(-2.0,Q.YC)],tier); Q.safety_line(b,[(2.0,Q.YC),(3.0,Q.YC)],tier)
    # recessed wall face under the landing: same banded seawall, top at the ledge
    for x0,x1 in ((-2.0,2.0),):
        Q._band(b,(x0,YF),(x1,YF),0.0,ZCAP,tier)
        rect(b,(x0,YF,ZCAP),(x1-x0,0,0),(0,Q.YB-YF,0),'concrete')                        # ledge top
        q(b,[(x0,Q.YB,ZCAP),(x1,Q.YB,ZCAP),(x1,Q.YB,DECK),(x0,Q.YB,DECK)],'concrete',(0,-1,0))            # back of the recess
    for s in (-1,1):   # end faces of the wall body and the coping where the quad steps back for the landing
        x=s*2.0
        q(b,[(x,YF,ZCAP),(x,Q.YB,ZCAP),(x,Q.YB,Q.ZC),(x,YF,Q.ZC)],'concrete',(-s,0,0))
        q(b,[(x,Q.YC,Q.ZC),(x,Q.YB,Q.ZC),(x,Q.YB,DECK),(x,Q.YC,DECK)],'stone',(-s,0,0))
    Q.paving(b,-3.0,-2.0,Q.YB,1.0); Q.paving(b,2.0,3.0,Q.YB,1.0)
    # landing: stringers on the ledge, planks from the fender line to the back of the coping line, then paving behind
    if tier!='mid': stringers(b,STRX4,-1.0,Q.YB,hi,tier,ends=(True,True))
    else: rect(b,(-2.0,-1.0,ZS),(4.0,0,0),(0,0,DECK-ZS),'wood_weathered')
    deck(b,-2.0,2.0,-1.0,Q.YB,hi,tier,STRX4)
    Q.paving(b,-2.0,2.0,Q.YB,1.0)
    # the landing's own outer bent of piles on the fender line (carries the stringer ends)
    for x in PX4: pile(b,x,-0.85,hi,tier,ztop=ZCAP,r=0.15)
    for yy in (-0.85,-0.40):   # cap on the landing piles + sill on the ledge: the stringers bear on both
        b.box((0,yy,ZCAP),(3.96,0.28,ZS-ZCAP),'wood_weathered',skip=('top','bottom') if yy<-0.6 else ('top','bottom','back'))
    for x in (-2.6,2.6): Q.fender_pile(b,x,YF,0.0,2.60,hi,tier)
    cbox(b,(0,-0.575,ZS),(4.0,0.85,DECK-ZS))
def pier_root_hi(b): pier_root(b,hi=True)
def pier_root_mid(b): pier_root(b,tier='mid')
def pier_root_far(b):
    Q.far_straight(b)
# ----------------------------------------------------------------
TR=dict(Q.TR); TR['wood_weathered']=('tw_timber',(0.875,0.875),3.0)   # long members: grain stretched along the length to 3 m cells
WX={'water':WL,'algae':0.7,'barnacle':0.6,'salt':0.35,'edge':0.25,'streak':0.15}
_C=dict(cls='large',conds=['clean'],page='w',dir='props/waterfront/pier',pdir='waterfront_pier',trim=TR,trim_mid=2.0,uv_from_near='face',
        far_flat=True,double_far=True,trim_ao={'big':0.4,'floor_big':0.88,'floor':0.6},dens=128,wx=WX,cage=0.02,ray=0.08)
def _wrap(fn,name):
    def near(b):
        fn(b); P.save_rails(name,pg.K+'/props/waterfront/_rails')
    return near
PROPS=[
 dict(name='pier_straight',near=_wrap(straight,'pier_straight'),high=straight_hi,mid=straight_mid,far=straight_far,max_side=160,**_C),
 dict(name='pier_rail_end',near=_wrap(rail_end,'pier_rail_end'),high=rail_end_hi,mid=rail_end_mid,far=rail_end_far,max_side=160,**_C),
 dict(name='pier_thead',near=_wrap(thead,'pier_thead'),high=thead_hi,mid=thead_mid,far=thead_far,max_side=192,**_C),
 dict(name='pier_lamp',near=_wrap(lambda b: pier_lamp(b),'pier_lamp'),high=lambda b: pier_lamp(b,hi=True),mid=lambda b: pier_lamp(b,tier='mid'),far=pier_lamp_far,max_side=64,
      **dict(_C,cls='small',wx=None)),
 dict(name='quay_pier_root',near=_wrap(pier_root,'quay_pier_root'),high=pier_root_hi,mid=pier_root_mid,far=pier_root_far,max_side=128,
      **dict(_C,dir='props/waterfront/quay',pdir='waterfront_quay')),
]
