"""Waterfront set 3: marina. Floating main walk (2.5 x 6 m module), finger slip (1.0 x 7.5 m with root gussets), marina pile with
HDPE cap + float pile-guide hoop, fibreglass dock box. Builder coords: Z up, seaward/front = -Y; glTF Y-up, front +Z.
FLOAT DATUM: floats' origin = bottom centre of the float pontoons. Placed at world z = 1.20 they float with the deck top at
local 0.75 = world 1.95 (the gangway toe level) and the still waterline at local 0.30 (world WL 1.5).
  marina_float   x -3..3 (snaps end to end every 6 m), y -1.25..1.25 (deck edge; rub rails stand 0.08 proud).
  marina_finger  root face at y = 0 (bolts to a float side: origin = (x, float_side_y) rotated so -Y points away), tip y = -7.5.
PILE DATUM: marina_pile origin = harbour bed (z 0) like the quay; the guide hoop sits at the float deck (world 1.95) and its
  bracket plate bears on a rub-rail face at y = +0.40 (pile centre 0.40 m out from the float's rub rail).
dock_box: ground mount on a deck (origin at the deck surface)."""
import math
from mathutils import Vector, Matrix
import pg
import wf_parts as P
import b_wfpier as WP
from wf_parts import PI, rect, seg_n, cbox, ccyl
q=WP.q; obox=WP.obox; bolt_head=P.bolt_head
V=Vector
WLL=0.30; ZF=0.48; ZW0,ZW1=0.46,0.71; ZD=0.75   # waterline, float top, whaler band, deck top (local)
def T(hi,tier): P.TIER['t']='hi' if hi else tier
def ext(b,prof,x0,x1,key_fn,caps=True,axis='x'):
    """closed profile (u,z) CCW seen from +axis, extruded along x (axis='x': u=y) or y (axis='y': u=x); key_fn(z_mid)->key"""
    n=len(prof)
    def Pt(t,u,z): return V((t,u,z)) if axis=='x' else V((u,t,z))
    for i in range(n):
        (ua,za),(ub,zb)=prof[i],prof[(i+1)%n]
        if za<1e-5 and zb<1e-5: continue   # bottom (never seen; floats are 0.3 under water)
        nu,nz=(zb-za),-(ub-ua)
        out=(0,nu,nz) if axis=='x' else (nu,0,nz)
        q(b,[Pt(x0,ua,za),Pt(x1,ua,za),Pt(x1,ub,zb),Pt(x0,ub,zb)],key_fn((za+zb)/2),out)
    if caps:
        for t,o in ((x0,-1),(x1,1)):
            pts=[Pt(t,u,z) for u,z in prof]; nn=V((0,0,0))
            for i in range(n): nn+=pts[i].cross(pts[(i+1)%n])
            ax=V((o,0,0)) if axis=='x' else V((0,o,0))
            if nn.dot(ax)<0: pts=pts[::-1]
            b.faces(pts,[tuple(range(n))],key_fn(0.2),[[(p.y if axis=='x' else p.x,p.z) for p in pts]])
def wkey(z): return 'cmu' if z<WLL else 'plastic_black'   # fouled below the waterline / black polyethylene above
def float_prof(w,hi):
    """rotomoulded float drum section (u,z): chamfered bottom + top edges, split at the waterline"""
    h=w/2; c=0.07
    return [(-h+c,0.0),(h-c,0.0),(h,c),(h,WLL),(h,ZF-0.03),(h-0.03,ZF),(-h+0.03,ZF),(-h,ZF-0.03),(-h,WLL),(-h,c)]
def drum(b,cx,cy,L,w,hi,tier,along='x'):
    pr=float_prof(w,hi)
    if along=='x': pr=[(u+cy,z) for u,z in pr]; ext(b,pr,cx-L/2,cx+L/2,wkey,axis='x')
    else: pr=[(u+cx,z) for u,z in pr]; ext(b,pr,cy-L/2,cy+L/2,wkey,axis='y')
    if hi:   # moulded stiffening ribs + drain plug boss
        for k in range(1,int(L/0.3)):
            t=-L/2+k*L/int(L/0.3)
            for s in (-1,1):
                if along=='x': b.box((cx+t,cy+s*(w/2+0.004),0.10),(0.05,0.008,0.30),'plastic_black',skip=('bottom',))
                else: b.box((cx+s*(w/2+0.004),cy+t,0.10),(0.008,0.05,0.30),'plastic_black',skip=('bottom',))
def boards(b,x0,x1,y0,y1,hi,tier,along='x',pitch=0.15,bw=0.14):
    """deck boards across the walk: top faces only + a dark sub-floor under the gaps; board ends as one strip each side"""
    n=int(round((x1-x0 if along=='x' else y1-y0)/pitch))
    for k in range(n):
        a=(x0 if along=='x' else y0)+k*pitch+(pitch-bw)/2; c=a+bw
        if along=='x': q(b,[(a,y0,ZD),(c,y0,ZD),(c,y1,ZD),(a,y1,ZD)],'wood_weathered',(0,0,1))
        else: q(b,[(x0,a,ZD),(x1,a,ZD),(x1,c,ZD),(x0,c,ZD)],'wood_weathered',(0,0,1))
        if hi:   # eased arrises + screws (bake)
            for s in (0.2,0.8):
                for e in (0.03,0.97):
                    if along=='x': b.lathe([(0.004,ZD),(0.0,ZD+0.001)],8,'galvanized',c=(a+bw*s,y0+(y1-y0)*e,0),cap_top=False)
                    else: b.lathe([(0.004,ZD),(0.0,ZD+0.001)],8,'galvanized',c=(x0+(x1-x0)*e,a+bw*s,0),cap_top=False)
    q(b,[(x0,y0,ZD-0.04),(x1,y0,ZD-0.04),(x1,y1,ZD-0.04),(x0,y1,ZD-0.04)],'wood_weathered',(0,0,1))   # framing seen through the gaps
    if along=='x':
        for y,o in ((y0,-1),(y1,1)): q(b,[(x0,y,ZD-0.04),(x1,y,ZD-0.04),(x1,y,ZD),(x0,y,ZD)],'wood_weathered',(0,o,0))
    else:
        for x,o in ((x0,-1),(x1,1)): q(b,[(x,y0,ZD-0.04),(x,y1,ZD-0.04),(x,y1,ZD),(x,y0,ZD)],'wood_weathered',(o,0,0))
def whaler(b,p0,p1,o,hi,tier,bolts=True):
    """timber whaler (75 x 250) on the float side, outward normal o, with through-bolts every 0.6 m and a vinyl D rub rail"""
    p0=V(p0); p1=V(p1); d=(p1-p0); L=d.length; d.normalize(); on=V(o)
    obox(b,p0-on*0.04+V((0,0,(ZW0+ZW1)/2-p0.z)),p1-on*0.04+V((0,0,(ZW0+ZW1)/2-p1.z)),0.08,ZW1-ZW0,'wood_weathered',ends=(True,True))
    # rub rail: 60 x 150 D profile on the whaler face (rounded in the bake)
    rc=lambda p: p+on*0.03+V((0,0,0.585-p.z))
    obox(b,rc(p0),rc(p1),0.06,0.15,'plastic_white',ends=(True,True),skip=())
    if hi:
        for s in (-1,1): b.tube(rc(p0)+on*0.03+V((0,0,s*0.05)),rc(p1)+on*0.03+V((0,0,s*0.05)),0.02,0.02,12,'plastic_white',cap0=False,cap1=False)
    if bolts and tier=='near' or hi:
        n=max(1,int(L/0.6))
        for k in range(n):
            p=p0+d*((k+0.5)*L/n)
            for z in (ZW0+0.04,ZW1-0.04): bolt_head(b,V((p.x,p.y,z))+on*0.0005,on,0.011,'galvanized',hi) if (hi or k%2==0) else None
def corner_plate(b,c,o,hi):
    c=V(c); on=V(o); t=V((-on.y,on.x,0))
    b.box(c+on*0.005,(0.22 if abs(on.x)<0.5 else 0.012,0.012 if abs(on.x)<0.5 else 0.22,0.22),'galvanized',skip=())
    for s in (-1,1): bolt_head(b,c+on*0.011+t*s*0.07+V((0,0,0.11)),on,0.012,'galvanized',hi)
# ---------------------------------------------------------------- main float module
FL,FW=6.0,2.5
def float_main(b,hi=False,tier='near'):
    T(hi,tier); mid=tier=='mid'
    if mid:
        for cy in (-0.62,0.62): ext(b,[(cy-0.55,0.0),(cy+0.55,0.0),(cy+0.55,WLL),(cy+0.55,ZF),(cy-0.55,ZF),(cy-0.55,WLL)],-2.9,2.9,wkey)
        b.box((0,0,ZW0),(FL,FW,ZD-ZW0),'wood_weathered',skip=('bottom',))
        for s in (-1,1): b.box((0,s*(FW/2+0.03),0.51),(FL,0.06,0.15),'plastic_white',skip=('back' if s<0 else 'front',))
        for x in (-1.5,1.5):
            for s in (-1,1): b.box((x,s*1.12,ZD),(0.42,0.06,0.09),'galvanized',skip=('bottom',))
        return
    for cx in (-1.5,1.5):
        for cy in (-0.62,0.62): drum(b,cx,cy,2.85,1.1,hi,tier)
    for s in (-1,1): whaler(b,(-FL/2,s*FW/2,0),(FL/2,s*FW/2,0),(0,s,0),hi,tier)
    # internal frame: stringers over the drums + joists at the ends (module-to-module connection) and mid
    for y in (-0.62,0.62): b.box((0,y,ZF),(FL,0.09,ZD-0.04-ZF),'wood_weathered',skip=('top','bottom'))
    for x in (-FL/2+0.04,0.0,FL/2-0.04): b.box((x,0,ZF),(0.08,FW-0.16,ZD-0.04-ZF),'wood_weathered',skip=('top','bottom'))
    boards(b,-FL/2,FL/2,-FW/2,FW/2,hi,tier)
    # module-to-module connector plates on the deck (through-rods into the end joists) + a utility access hatch
    for x in (-FL/2+0.09,FL/2-0.09):
        for y in (-0.95,0.95):
            b.box((x,y,ZD),(0.16,0.30,0.006),'galvanized',skip=('bottom',))
            for yy in (y-0.09,y+0.09): bolt_head(b,V((x,yy,ZD+0.006)),V((0,0,1)),0.013,'galvanized',hi)
    b.box((0.0,0.55,ZD),(0.62,0.46,0.01),'galvanized',skip=('bottom',))
    b.box((0.0,0.36,ZD+0.01),(0.14,0.03,0.012),'stainless',skip=('bottom',))
    if hi:
        for i in range(10):
            for j in range(7): b.box((-0.27+i*0.06,0.37+j*0.06,ZD+0.01),(0.03,0.006,0.0015),'galvanized',rz=0.6*(1 if (i+j)%2 else -1))   # tread-plate pattern
        pg.add_text(b,'WATER  POWER',0.035,(0.0,0.73,ZD+0.0105),(1,0,0),(0,1,0),0.0008,'paint_yellow')
    for x in (-1.5,1.5):
        for s in (-1,1): (P.cleat if hi else WP.cleat_lite)(b,(x,s*(FW/2-0.13),ZD),0.0,hi,tier)
    for x in (-FL/2+0.02,FL/2-0.02):   # moulded vinyl corner bumpers wrapping the rub-rail ends (ends stay snap-flush)
        for s in (-1,1):
            b.tube((x,s*(FW/2+0.06),0.48),(x,s*(FW/2+0.06),0.69),0.05,0.05,seg_n(tier,hi,6,4,16),'plastic_white',cap0=True,cap1=True)
    for x in (-FL/2+0.13,FL/2-0.13):
        for s in (-1,1): corner_plate(b,(x,s*(FW/2+0.06),ZW0+0.01),(0,s,0),hi)
    # utility: PVC conduit + water line in hangers under the deck edge (seen from the water)
    for (y,r) in ((-0.95,0.03),(-0.85,0.02)):
        b.tube((-FL/2,y,ZF+0.06),(FL/2,y,ZF+0.06),r,r,12 if hi else 6,'plastic_white',cap0=False,cap1=False)
    if hi:
        pg.add_text(b,'B-DOCK',0.08,(0.0,-FW/2-0.0605,0.585),(1,0,0),(0,0,1),0.002,'paint_navy')
    if tier=='near':
        cbox(b,(0,0,0),(FL,FW+0.16,ZD))
        for x in (-1.5,1.5):
            for s in (-1,1): cbox(b,(x,s*(FW/2-0.13),ZD),(0.46,0.12,0.12))
def float_far(b):
    b.box((0,0,0),(FL,FW+0.12,ZD),'twf_flat',skip=('bottom',))
# ---------------------------------------------------------------- finger slip
GL=7.5; GW=1.0
def finger(b,hi=False,tier='near'):
    T(hi,tier); mid=tier=='mid'; h=GW/2
    if mid:
        ext(b,[(-0.42,0.0),(0.42,0.0),(0.42,WLL),(0.42,ZF),(-0.42,ZF),(-0.42,WLL)],-GL+0.1,-0.1,wkey,axis='y')
        b.box((0,-GL/2,ZW0),(GW,GL,ZD-ZW0),'wood_weathered',skip=('bottom',))
        for s in (-1,1):
            b.box((s*(h+0.03),-GL/2,0.51),(0.06,GL,0.15),'plastic_white',skip=())
            b.faces([V((s*h,0,ZD)),V((s*1.5,0,ZD)),V((s*h,-1.0,ZD))],[(0,1,2) if s<0 else (2,1,0)],'wood_weathered',[[(0,0),(1,0),(0,1)]])
            q(b,[(s*1.5,0,ZW0),(s*h,-1.0,ZW0),(s*h,-1.0,ZD),(s*1.5,0,ZD)],'wood_weathered',(s,-1,0))
        b.box((0,-GL-0.03,0.51),(GW+0.12,0.06,0.15),'plastic_white',skip=())
        return
    for k in range(3): drum(b,0.0,-1.30-k*2.45,2.30,0.84,hi,tier,along='y')
    for s in (-1,1): whaler(b,(s*h,0,0),(s*h,-GL,0),(s,0,0),hi,tier)
    whaler(b,(-h-0.08,-GL,0),(h+0.08,-GL,0),(0,-1,0),hi,tier)
    for x in (-0.3,0.3): b.box((x,-GL/2,ZF),(0.09,GL,ZD-0.04-ZF),'wood_weathered',skip=('top','bottom'))
    boards(b,-h,h,-GL,0.0,hi,tier,along='y')
    # root gussets (knee braces): triangular decked frames 1.0 m each way onto the main float side, diagonal whaler + rub rail
    for s in (-1,1):
        a=V((s*1.5,0,0)); c=V((s*h,-1.0,0)); o=V((s,-1,0)).normalized()
        whaler(b,a,c,tuple(o),hi,tier,bolts=False)
        b.faces([V((s*h,0,ZD)),V((s*1.5,0,ZD)),V((s*h,-1.0,ZD))],[(0,1,2) if s<0 else (2,1,0)],'wood_weathered',[[(0,0),(1,0),(0,1)]])
        b.faces([V((s*h,0,ZW0)),V((s*1.5,0,ZW0)),V((s*h,-1.0,ZW0))],[(2,1,0) if s<0 else (0,1,2)],'wood_weathered',[[(0,0),(1,0),(0,1)]])
        b.box((s*(h+0.5),-0.03,ZW0),(1.0,0.06,ZD-ZW0),'galvanized',skip=('top','bottom'))   # root connector angle on the main float side
        for x in (s*0.8,s*1.25): bolt_head(b,V((x,-0.061,ZW0+0.14)),V((0,-1,0)),0.012,'galvanized',hi)
    for y in (-2.5,-6.5):
        for s in (-1,1): (P.cleat if hi else WP.cleat_lite)(b,(s*(h-0.12),y,ZD),PI/2,hi,tier)
    if hi: pg.add_text(b,'B-14',0.10,(h-0.25,-GL+0.35,ZD+0.0005),(0,1,0),(-1,0,0),0.001,'paint_white')
    if tier=='near':
        cbox(b,(0,-GL/2,0),(GW+0.16,GL,ZD)); cbox(b,(0,-0.5,ZW0),(3.0,1.0,ZD-ZW0))
def finger_far(b):
    b.box((0,-GL/2-0.04,0),(GW+0.12,GL+0.08,ZD),'twf_flat',skip=('bottom',))
    for s in (-1,1): q(b,[(s*1.5,0,ZW0),(s*0.56,-1.0,ZW0),(s*0.56,-1.0,ZD),(s*1.5,0,ZD)],'twf_flat',(s,-1,0))   # gusset faces (double_far)
    for s in (-1,1): b.faces([V((s*0.56,0,ZD)),V((s*1.5,0,ZD)),V((s*0.56,-1.0,ZD))],[(0,1,2) if s<0 else (2,1,0)],'twf_flat',[[(0,0),(1,0),(0,1)]])
# ---------------------------------------------------------------- marina pile + cap + guide hoop
PT=5.2; PS=0.36; ZH=1.95
def pile(b,hi=False,tier='near'):
    T(hi,tier); mid=tier=='mid'; c=0.03; h=PS/2
    prof=[(-h+c,-h),(h-c,-h),(h,-h+c),(h,h-c),(h-c,h),(-h+c,h),(-h,h-c),(-h,-h+c)]   # chamfered square (prestressed concrete)
    if mid: prof=[(-h,-h),(h,-h),(h,h),(-h,h)]
    zs=[0.0,0.6,1.5,PT]   # band splits: buried/scour, fouled below WL, splash + dry above
    keys=['cmu','cmu','concrete']
    for i in range(3):
        z0,z1=zs[i],zs[i+1]
        for j in range(len(prof)):
            (xa,ya),(xb,yb)=prof[j],prof[(j+1)%len(prof)]
            q(b,[(xa,ya,z0),(xb,yb,z0),(xb,yb,z1),(xa,ya,z1)],keys[i],(yb-ya,-(xb-xa),0))
    # HDPE pile cap: square skirt + pyramid (white), strap band
    sk=h+0.025
    for j,(xa,ya,xb,yb) in enumerate(((-sk,-sk,sk,-sk),(sk,-sk,sk,sk),(sk,sk,-sk,sk),(-sk,sk,-sk,-sk))):
        q(b,[(xa,ya,PT-0.18),(xb,yb,PT-0.18),(xb,yb,PT),(xa,ya,PT)],'plastic_white',(yb-ya,-(xb-xa),0))
        b.faces([V((xa,ya,PT)),V((xb,yb,PT)),V((0,0,PT+0.26))],[(0,1,2)],'plastic_white',[[(0,0),(1,0),(0.5,1)]])
    if not mid:
        q(b,[(-sk,-sk,PT-0.18),(sk,-sk,PT-0.18),(sk,sk,PT-0.18),(-sk,sk,PT-0.18)],'plastic_white',(0,0,-1))   # skirt underside
        for j,(xa,ya,xb,yb) in enumerate(((-sk,-sk,sk,-sk),(sk,-sk,sk,sk),(sk,sk,-sk,sk),(-sk,sk,-sk,-sk))):   # stainless strap
            o=V((yb-ya,-(xb-xa),0)).normalized()*0.003
            q(b,[V((xa,ya,PT-0.11))+o,V((xb,yb,PT-0.11))+o,V((xb,yb,PT-0.08))+o,V((xa,ya,PT-0.08))+o],'stainless',tuple(o))
        if hi:   # bird spike on the apex, mould line, lifting-loop recess, tide-gauge stencil
            b.tube((0,0,PT+0.26),(0,0,PT+0.40),0.004,0.002,8,'stainless',cap1=True)
            for k in range(8): pg.add_text(b,f'{k+1}',0.07,(0,-h-0.001,1.0+k*0.5),(1,0,0),(0,0,1),0.001,'paint_white')
            for k in range(8): b.box((0.12,-h-0.0008,1.0+k*0.5+0.02),(0.08,0.0016,0.012),'paint_white',skip=('back',))
    if not mid:   # retro-reflective night band (orange) + cast lifting inserts near the head
        e=h+0.002
        for (xa,ya,xb,yb) in ((-e,-e,e,-e),(e,-e,e,e),(e,e,-e,e),(-e,e,-e,-e)):
            q(b,[(xa,ya,PT-0.62),(xb,yb,PT-0.62),(xb,yb,PT-0.47),(xa,ya,PT-0.47)],'plastic_orange',(yb-ya,-(xb-xa),0))
        for sx in (-1,1): b.tube((sx*0.08,-h,PT-0.9),(sx*0.08,-h-0.008,PT-0.9),0.025,0.025,8,'galvanized',cap0=False,cap1=True)
    # float pile-guide hoop at the float deck: square galvanized frame with 4 UHMW rollers, two arms to a plate on the rub rail
    g=h+0.09; zh=ZH-0.10
    sg=seg_n(tier,hi,6,4,12)
    rim=[V((-g,-g,zh)),V((g,-g,zh)),V((g,g,zh)),V((-g,g,zh))]
    for i in range(4): b.tube(rim[i],rim[(i+1)%4],0.03,0.03,sg,'galvanized',cap0=True,cap1=True)
    if not mid:
        for i in range(4):   # rollers on axles, bearing on the pile faces
            m=(rim[i]+rim[(i+1)%4])/2; ax=(rim[(i+1)%4]-rim[i]).normalized(); inn=-V((m.x,m.y,0)).normalized()
            cr=m+inn*0.045
            b.tube(cr-ax*0.11,cr+ax*0.11,0.045,0.045,seg_n(tier,hi,8,6,16),'plastic_black',cap0=True,cap1=True)
            for s in (-1,1): b.box(cr+ax*s*0.125-V((0,0,0.05)),(0.03 if abs(ax.x)>0.5 else 0.09,0.09 if abs(ax.x)>0.5 else 0.03,0.10),'galvanized',skip=())
    for x in (-0.14,0.14):   # arms to the bracket plate (pile -> float side at +Y)
        b.tube(V((x,g,zh)),V((x,0.395,zh)),0.025,0.025,sg,'galvanized',cap0=False,cap1=False)
    b.box((0,0.40,zh-0.12),(0.44,0.012,0.26),'galvanized',skip=())
    if not mid:
        for x in (-0.17,0.17):
            for z in (zh-0.07,zh+0.09): bolt_head(b,V((x,0.394,z)),V((0,-1,0)),0.012,'galvanized',hi)
    if tier=='near':
        ccyl(b,(0,0,0),PS*0.6,PT+0.26); cbox(b,(0,0.1,zh-0.12),(2*g+0.06,2*g+0.2,0.26))
def pile_far(b):
    h=PS/2+0.02
    for (xa,ya,xb,yb) in ((-h,-h,h,-h),(h,-h,h,h),(h,h,-h,h),(-h,h,-h,-h)):
        q(b,[(xa,ya,0),(xb,yb,0),(xb,yb,PT+0.1),(xa,ya,PT+0.1)],'twf_flat',(yb-ya,-(xb-xa),0))
    q(b,[(-0.30,-0.30,ZH-0.12),(0.30,-0.30,ZH-0.12),(0.30,0.41,ZH-0.12),(-0.30,0.41,ZH-0.12)],'twf_flat',(0,0,1))   # hoop + arms (top)
    q(b,[(-0.30,-0.30,ZH-0.13),(0.30,-0.30,ZH-0.13),(0.30,-0.30,ZH-0.07),(-0.30,-0.30,ZH-0.07)],'twf_flat',(0,-1,0))
    b.faces([V((-h,-h,PT+0.1)),V((h,-h,PT+0.1)),V((h,h,PT+0.1)),V((-h,h,PT+0.1))],[(0,1,2,3)],'twf_flat',[[(0,0),(1,0),(1,1),(0,1)]])
# ---------------------------------------------------------------- dock box
DW,DDp,DH=1.52,0.62,0.62
def dock_box(b,hi=False,tier='near'):
    T(hi,tier); mid=tier=='mid'; c=0.05
    body=[(-DW/2+c,-DDp/2),(DW/2-c,-DDp/2),(DW/2,-DDp/2+c),(DW/2,DDp/2-c),(DW/2-c,DDp/2),(-DW/2+c,DDp/2),(-DW/2,DDp/2-c),(-DW/2,-DDp/2+c)]
    if mid: body=[(-DW/2,-DDp/2),(DW/2,-DDp/2),(DW/2,DDp/2),(-DW/2,DDp/2)]
    def walls(pr,z0,z1,key,inset=0.0,taper=0.0):
        for j in range(len(pr)):
            (xa,ya),(xb,yb)=pr[j],pr[(j+1)%len(pr)]
            f=lambda x,y,z: (x*(1-inset-taper*(z-z0)),y*(1-inset-taper*(z-z0)*1.5),z)
            kk=key if (key!='plastic_white' or -(xb-xa)<-1e-6) else 'paint_white'   # gelcoat: front face baked (decals), sides/back tw_paint tinted
            q(b,[f(xa,ya,z0),f(xb,yb,z0),f(xb,yb,z1),f(xa,ya,z1)],kk,(yb-ya,-(xb-xa),0))
    walls(body,0.0 if mid else 0.04,DH-0.08,'plastic_white')          # slightly drafted moulded body
    if not mid:
        walls(body,0.0,0.04,'plastic_black',inset=0.02)              # recessed rubber base
    # lid: overhanging cap with drip edge + moulded non-skid top
    lid=[(x*1.015,y*1.04) for x,y in body]
    walls(lid,DH-0.08,DH,'plastic_white')
    if mid: b.faces([V((x,y,DH)) for x,y in lid],[tuple(range(len(lid)))],'plastic_white',[[(x,y) for x,y in lid]])
    else:   # lid top in two halves, mirror-shared across x = 0 (symmetric non-skid moulding, no lettering)
        yl=DDp/2*1.04; b.cur_sym=pg.MIRROR
        for sx in (-1,1):
            hp=[(0.0,-yl)]+[(x,y) for x,y in lid if x*sx>0]+[(0.0,yl)]
            hp=sorted(hp,key=lambda p: math.atan2(p[1],p[0]-sx*0.3))
            pts=[V((x,y,DH)) for x,y in hp]
            b.faces(pts,[tuple(range(len(pts)))],'plastic_white',[[(x,y) for x,y in hp]])
        b.cur_sym=1
        b.faces([V((x,y,DH-0.08)) for x,y in lid][::-1],[tuple(range(len(lid)))],'paint_white',[[(x,y) for x,y in lid]])   # lid underside (seen in the gap)
        y0=-DDp/2*1.04
        b.box((0,y0-0.012,DH-0.14),(0.10,0.024,0.10),'stainless',skip=('back',))          # hasp + staple
        b.box((0,y0-0.035,DH-0.20),(0.05,0.02,0.06),'brass',skip=())                       # padlock body
        b.tube((0,y0-0.035,DH-0.17),(0,y0-0.035,DH-0.14),0.012,0.012,6,'stainless',cap0=False,cap1=False)
        for x in (-0.45,0.45): b.box((x,DDp/2*1.04+0.01,DH-0.10),(0.16,0.02,0.05),'stainless',skip=('front',))   # piano-hinge leaves
        b.tube((-0.55,DDp/2*1.04+0.02,DH-0.075),(0.55,DDp/2*1.04+0.02,DH-0.075),0.008,0.008,6,'stainless',cap0=True,cap1=True)
        for s in (-1,1):   # recessed side handles
            b.box((s*(DW/2+0.002),0,0.40),(0.008,0.22,0.06),'plastic_black',skip=())
        for x in (-0.62,0.62):   # deck tie-down feet (bolted)
            for s in (-1,1): b.box((x,s*(DDp/2+0.03),0),(0.10,0.06,0.012),'stainless',skip=('bottom',)); bolt_head(b,V((x,s*(DDp/2+0.04),0.012)),V((0,0,1)),0.008,'stainless',hi)
        if hi:
            for i in range(18):   # non-skid diamond pattern
                for j in range(6): b.box((-DW/2+0.12+i*0.075,-DDp/2+0.09+j*0.085,DH),(0.03,0.03,0.002),'plastic_white',rz=PI/4)
            pg.add_text(b,'B-14',0.09,(0.45,-DDp/2-0.0012,0.36),(1,0,0),(0,0,1),0.001,'paint_navy')
            pg.add_text(b,'CORONADO YACHT HARBOR',0.03,(-0.25,-DDp/2-0.0012,0.30),(1,0,0),(0,0,1),0.0008,'paint_navy')
            b.box((-0.62,-DDp/2-0.001,0.18),(0.12,0.002,0.12),'paint_red',skip=('back',))   # fire-extinguisher inside sticker
            pg.add_text(b,'NO FUEL',0.02,(-0.62,-DDp/2-0.0025,0.18),(1,0,0),(0,0,1),0.0006,'paint_white')
    if tier=='near': cbox(b,(0,0,0),(DW+0.04,DDp+0.08,DH))
def dock_box_far(b):
    b.box((0,0,0),(DW*1.01,DDp*1.03,DH),'twf_flat',skip=('bottom',))
# ---------------------------------------------------------------- shore-power / water pedestal (bolts to a float deck)
def pedestal(b,hi=False,tier='near'):
    T(hi,tier); mid=tier=='mid'; w,d,H=0.26,0.22,1.05
    b.box((0,0,0),(0.40,0.34,0.012),'galvanized',skip=('bottom',))                       # deck mounting plate
    b.box((0,0,0.012),(w,d,H-0.012),'plastic_white',skip=('bottom',) if mid else ('bottom','top'))   # column
    if mid:
        b.box((0,0,H),(w+0.04,d+0.04,0.10),'plastic_white',skip=('bottom',)); return
    b.lathe([(0.0,H),(0.17,H),(0.17,H+0.03),(0.12,H+0.12),(0.0,H+0.12)],seg_n(tier,hi,8,6,24),'plastic_white',c=(0,0,0),cap_top=True)   # cap
    b.tube((0,0,H+0.03),(0,0,H+0.10),0.125,0.115,seg_n(tier,hi,8,6,24),'glass_dark',cap0=False,cap1=False)   # lantern lens band
    for s in (-1,1):   # receptacle hoods (30A/50A) both slip sides, with flip lids
        b.box((s*(w/2+0.035),0,0.62),(0.07,0.14,0.16),'plastic_black',skip=('front' if s<0 else 'back',) if False else ())
        b.box((s*(w/2+0.071),0,0.70),(0.002,0.12,0.012),'paint_yellow',skip=())
    b.box((0,-d/2-0.004,0.82),(0.16,0.008,0.12),'glass_dark',skip=('back',))              # meter window
    b.box((0,-d/2-0.005,0.36),(0.14,0.01,0.08),'paint_navy',skip=('back',))               # slip number plate
    b.tube((0.06,-d/2,0.30),(0.06,-d/2-0.07,0.30),0.012,0.012,6,'brass',cap0=False,cap1=True)   # hose bib
    b.box((0.06,-d/2-0.07,0.33),(0.05,0.012,0.012),'paint_red',skip=())                   # tap handle
    b.box((-0.06,-d/2-0.01,0.05),(0.08,0.02,0.10),'plastic_black',skip=('back',))         # conduit entry gland
    if hi:
        pg.add_text(b,'B-14',0.05,(0,-d/2-0.0102,0.36),(1,0,0),(0,0,1),0.0008,'paint_white')
        pg.add_text(b,'30A  50A',0.025,(0,-d/2-0.0015,0.72),(1,0,0),(0,0,1),0.0006,'paint_navy')
        for k in range(6): b.box((0,-d/2-0.0012,0.95+k*0.012),(0.18,0.002,0.004),'plastic_white')   # louvres
        for x in (-0.16,0.16):
            for y in (-0.13,0.13): bolt_head(b,V((x,y,0.012)),V((0,0,1)),0.008,'stainless',hi)
    if tier=='near': ccyl(b,(0,0,0),0.17,H+0.12)
def pedestal_far(b):
    b.box((0,0,0),(0.34,0.28,1.17),'twf_flat',skip=('bottom',))
    q(b,[(-0.20,-0.17,0.013),(0.20,-0.17,0.013),(0.20,0.17,0.013),(-0.20,0.17,0.013)],'twf_flat',(0,0,1))   # deck plate (top view)
# ----------------------------------------------------------------
TR=dict(WP.TR); TR.update({'wood_weathered':('tw_timber',(0.875,0.875),3.0),'plastic_black':('tw_rubber',(0.875,0.875),2.0),'cmu':('tw_tide',(0.875,0.875)),
         'plastic_white':('tw_paint',(0.875,0.875),6.0),'concrete':('tw_conc_top',(0.875,0.875))})
WXF={'water':WLL,'algae':0.7,'barnacle':0.5,'salt':0.35,'edge':0.25,'streak':0.15}
_C=dict(WP._C); _C.update(dir='props/waterfront/marina',pdir='waterfront_marina',trim=TR,wx=WXF,trim_tint={'plastic_white':(0.88,0.88,0.86)})
def _wrap(fn,name):
    def near(b): P.reset(); P.TIER['t']='near'; fn(b); P.save_rails(name,pg.K+'/props/waterfront/_rails')
    return near
PROPS=[
 dict(name='marina_float',near=_wrap(float_main,'marina_float'),high=lambda b: float_main(b,hi=True),mid=lambda b: float_main(b,tier='mid'),far=float_far,max_side=128,**_C),
 dict(name='marina_finger',near=_wrap(finger,'marina_finger'),high=lambda b: finger(b,hi=True),mid=lambda b: finger(b,tier='mid'),far=finger_far,max_side=128,**_C),
 dict(name='marina_pile',near=_wrap(pile,'marina_pile'),high=lambda b: pile(b,hi=True),mid=lambda b: pile(b,tier='mid'),far=pile_far,max_side=96,
      **dict(_C,cls='medium',wx=dict(WXF,water=1.5),trim=dict(TR,plastic_white=('tw_paint',(0.875,0.875),2.0),concrete=('tw_conc_top',(0.875,0.875),5.0),cmu=('tw_tide',(0.875,0.875),2.0)))),
 dict(name='dock_box',near=_wrap(dock_box,'dock_box'),high=lambda b: dock_box(b,hi=True),mid=lambda b: dock_box(b,tier='mid'),far=dock_box_far,max_side=112,
      **dict(_C,cls='small',wx={'water':-9,'algae':0.0,'barnacle':0.0,'salt':0.3,'edge':0.3,'streak':0.1},trim=dict({k:v for k,v in TR.items() if k!='plastic_white'},paint_white=('tw_paint',(0.875,0.875),2.0)),trim_tint={'paint_white':(0.93,0.93,0.91)})),
 dict(name='marina_pedestal',near=_wrap(pedestal,'marina_pedestal'),high=lambda b: pedestal(b,hi=True),mid=lambda b: pedestal(b,tier='mid'),far=pedestal_far,max_side=64,
      **dict(_C,cls='small',wx={'water':-9,'algae':0.0,'barnacle':0.0,'salt':0.3,'edge':0.3,'streak':0.1},trim={k:v for k,v in TR.items() if k!='plastic_white'},trim_tint={})),
]
