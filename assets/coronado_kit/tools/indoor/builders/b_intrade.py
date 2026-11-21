"""Indoor trade / auto / marine props (shop-gap batch 5, module b_intrade) — original geometry, page I, near+col only.
Shared page-I trims + per-key vertex tint (one material per prop); small (<=48 px) unique bake slots only for
badges / print. Ground props: origin at footprint centre, front toward -Y.
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math, random
import mathutils
from mathutils import Vector
from b_inshared import sg
from b_insvcshop import TR as _TR, TINT as _TINT, _q, V, nfaces, xform, frontq, topq, text, flat_prism, caster, badge, SL

TR=dict(_TR); TINT=dict(_TINT)
_NEW={
 'hull_wht':('ti_paint',(1.04,1.04,1.02)), 'antifoul':('ti_paint',(0.42,0.08,0.07)), 'boot_blu':('ti_paint',(0.08,0.20,0.55)),
 'teak':('ti_wood',(0.85,0.62,0.40)), 'hoist_red':('ti_paint',(0.78,0.08,0.06)), 'ram_blk':('ti_metal',(0.12,0.12,0.13)),
 'eng_gry':('ti_metal',(0.30,0.32,0.34)), 'eng_blu':('ti_paint',(0.10,0.25,0.62)), 'oil_yel':('ti_plastic',(1.00,0.78,0.05)),
 'oil_blk':('ti_plastic',(0.10,0.10,0.11)), 'oil_blu':('ti_plastic',(0.10,0.30,0.75)), 'oil_red':('ti_plastic',(0.80,0.10,0.08)),
 'oil_grn':('ti_plastic',(0.10,0.50,0.25)), 'oil_slv':('ti_metal',(0.75,0.76,0.78)), 'rack_blu':('ti_paint',(0.12,0.28,0.62)),
 'rack_org':('ti_paint',(0.95,0.42,0.05)), 'pallet':('ti_wood',(0.80,0.66,0.46)), 'wrap':('ti_glass',(0.92,0.94,0.96)),
 'tyre':('ti_plastic',(0.07,0.07,0.075)), 'tyre_sw':('ti_plastic',(0.16,0.16,0.17)), 'tool_red':('ti_paint',(0.82,0.06,0.05)),
 'mach_gry':('ti_paint',(0.55,0.58,0.60)), 'mach_blu':('ti_paint',(0.10,0.32,0.62)), 'lumber':('ti_wood',(1.00,0.86,0.62)),
 'lumber_dk':('ti_wood',(0.80,0.62,0.40)), 'ply':('ti_wood',(0.95,0.80,0.55)), 'iron':('ti_metal',(0.50,0.52,0.54)),
 'saw_yel':('ti_paint',(1.00,0.74,0.05)), 'blade':('ti_metal',(0.85,0.86,0.88)), 'wt_lead':('ti_metal',(0.45,0.46,0.48)),
}
for k,(t,c) in _NEW.items(): TR[k]=(t,(0.875,0.875)); TINT[k]=c

def rotz_place(b, n0, M, at):
    xform(b,n0,lambda co: M@co+V(*at))
def tyre(b, at, axis, Ro, Ri, w, hi, key='tyre', side='tyre_sw', rim=None, sides=(True,True), nn=None, bore=True):
    """tyre as a closed lathe ring (tread + sidewalls + bore), built on Z then turned to `axis` ('x','y','z')"""
    n=sg(hi,nn or 14,24); n0=nfaces(b)
    if hi: P=[(Ri,-w*0.40),(Ro-0.03,-w*0.48),(Ro,-w*0.40),(Ro,w*0.40),(Ro-0.03,w*0.48),(Ri,w*0.40),(Ri,-w*0.40)]
    else:  P=[(Ri,-w*0.42),(Ro,-w*0.42),(Ro,w*0.42),(Ri,w*0.42),(Ri,-w*0.42)]
    for i in range(len(P)-1):
        k=key if abs(P[i][0]-Ro)<1e-6 and abs(P[i+1][0]-Ro)<1e-6 else side
        if not hi and abs(P[i][1]-P[i+1][1])<1e-6 and not sides[0 if P[i][1]<0 else 1]: continue
        if not hi and abs(P[i][0]-Ri)<1e-6 and abs(P[i+1][0]-Ri)<1e-6 and not bore: continue
        b.lathe([P[i],P[i+1]],n,k,c=(0,0,0),cap_top=False,cap_bot=False)
    if rim:
        b.lathe([(Ri,w*0.1),(Ri*0.35,w*0.18),(0.0,w*0.18)],n,rim,c=(0,0,0),cap_top=False,cap_bot=False)
        b.lathe([(0.0,-w*0.18),(Ri*0.35,-w*0.18),(Ri,-w*0.1)],n,rim,c=(0,0,0),cap_top=False,cap_bot=False)
    M={'z':mathutils.Matrix.Identity(3),'x':mathutils.Matrix.Rotation(math.pi/2,3,'Y'),'y':mathutils.Matrix.Rotation(math.pi/2,3,'X')}[axis]
    rotz_place(b,n0,M,at)

# ------------------------------------------------------------------ boat_on_stands
def boat_on_stands(b, hi=False):
    """boatyard workshop: 4.6 m centre-console fibreglass runabout on keel blocks and four screw jack stands; white
    topsides, navy boot stripe, red antifouling, teak-trimmed deck, console with windscreen, outboard on transom."""
    L=4.6; zk=0.42; Hs=1.05
    ns=sg(hi,8,14); X=[-L/2+L*i/ns for i in range(ns+1)]
    def half(x):                                           # half-breadth, keel rise, sheer height at station x
        t=(x+L/2)/L
        w=0.86*(1-max(0,(t-0.55)/0.45)**1.8) if t<1 else 0.0
        w=max(w,0.03)
        kr=0.42*max(0,(t-0.62)/0.38)**1.6                  # forefoot rises
        sh=Hs+0.12*t*t
        return w,zk+kr,zk+sh
    secs=[]
    for x in X:
        w,k,s=half(x)
        prm=[(0.0,0.0),(0.30,0.07/(s-k)),(0.74,0.25),(0.82,0.36),(0.97,0.80),(1.0,1.0)] if hi else [(0.0,0.0),(0.74,0.25),(0.82,0.36),(1.0,1.0)]
        secs.append([(x,u*w,k+v*(s-k),v) for u,v in prm])
    wl=zk+0.36*(Hs)                                         # boot stripe band ~ chine height
    for i in range(ns):
        A,B=secs[i],secs[i+1]
        for j in range(len(A)-1):
            vt=A[j+1][3]
            key='antifoul' if vt<=0.26 else ('boot_blu' if vt<=0.37 else 'hull_wht')
            for sy in (1,-1):
                Q=[V(A[j][0],sy*A[j][1],A[j][2]),V(B[j][0],sy*B[j][1],B[j][2]),V(B[j+1][0],sy*B[j+1][1],B[j+1][2]),V(A[j+1][0],sy*A[j+1][1],A[j+1][2])]
                mid=(Q[0]+Q[2])/2; _q(b,Q,key,(0,sy,(mid.z-(zk+0.5))*0.6))
        # deck strip (slightly below sheer = gunwale lip)
        a=A[-1]; c=B[-1]
        _q(b,[V(a[0],-a[1]+0.04,a[2]-0.02),V(c[0],-c[1]+0.04,c[2]-0.02),V(c[0],c[1]-0.04,c[2]-0.02),V(a[0],a[1]-0.04,a[2]-0.02)],'teak' if 0<i<ns-2 else 'hull_wht',(0,0,1))
        for sy in (1,-1): _q(b,[V(a[0],sy*a[1],a[2]),V(c[0],sy*c[1],c[2]),V(c[0],sy*(c[1]-0.04),c[2]-0.02),V(a[0],sy*(a[1]-0.04),a[2]-0.02)],'hull_wht',(0,sy*0.3,1))
    # transom
    T=secs[0]; P=[V(T[0][0],-p[1],p[2]) for p in T[::-1]]+[V(T[0][0],p[1],p[2]) for p in T[1:]]
    _q(b,P,'hull_wht',(-1,0,0))
    # rub rail
    b.sweep([V(x,half(x)[0]+0.012,half(x)[2]-0.03) for x in X[:-1]]+[V(X[-1],0.0,half(X[-1])[2]-0.03)]+[V(x,-half(x)[0]-0.012,half(x)[2]-0.03) for x in X[-2::-1]],0.018,4,'paint_grey',cap0=True,cap1=True)
    # console + windscreen + seat
    zd=zk+Hs-0.02
    b.box((0.25,0,zd),(0.55,0.62,0.85),'hull_wht')
    n0=nfaces(b); b.box((0,0,0),(0.012,0.66,0.40),'glass'); xform(b,n0,lambda co: mathutils.Matrix.Rotation(-0.45,3,'Y')@co+V(0.50,0,zd+0.85))
    b.box((0.25,0,zd+0.85),(0.55,0.62,0.03),'paint_grey',ch=0)
    frontq(b,-0.25+0.25,0.25+0.25,0,0,0,'paper') if False else None
    _q(b,[V(-0.0205,-0.22,zd+0.55),V(-0.0205,0.22,zd+0.55),V(-0.0205,0.22,zd+0.80),V(-0.0205,-0.22,zd+0.80)],'tv_blk',(-1,0,0))
    b.tube((-0.03,0.0,zd+0.70),(-0.10,0.0,zd+0.72),0.012,0.012,5,'chrome',cap0=False,cap1=False)
    b.tube((-0.10,0.0,zd+0.72),(-0.10,0.0,zd+0.72),0.14,0.14,sg(hi,8,12),'tv_blk',cap0=True,cap1=False) if False else None
    b.box((-0.60,0,zd),(0.50,0.80,0.45),'hull_wht'); b.box((-0.60,0,zd+0.45),(0.52,0.82,0.10),'leather_crm')
    b.box((-0.84,0,zd+0.55),(0.08,0.80,0.36),'leather_crm')
    b.box((-1.6,0,zd),(0.7,1.2,0.40),'hull_wht'); b.box((-1.6,0,zd+0.40),(0.72,1.22,0.08),'leather_crm')
    for sy in (1,-1): b.tube((0.9,sy*0.62,zd+0.0),(-1.6,sy*0.70,zd+0.0),0.0,0.0,3,'chrome',cap0=False,cap1=False) if False else None
    # bow rail
    bp=[V(0.9,0.66,zd+0.38),V(1.7,0.42,zd+0.42),V(2.15,0.0,zd+0.46),V(1.7,-0.42,zd+0.42),V(0.9,-0.66,zd+0.38)]
    b.sweep(bp,0.012,sg(hi,4,6),'chrome',cap0=True,cap1=True)
    for p in bp: b.tube((p.x,p.y,zd+0.08),p,0.01,0.01,4,'chrome',cap0=False,cap1=False)
    # outboard
    xo=-L/2
    b.box((xo-0.03,0,zd-0.20),(0.08,0.22,0.22),'steel_dk')                     # transom bracket
    b.lathe([(0.17,0.0),(0.19,0.20),(0.17,0.40),(0.10,0.50),(0.0,0.52)],sg(hi,8,12),'paint_black',c=(xo-0.26,0,zd-0.12),cap_top=False,cap_bot=True)
    b.box((xo-0.26,0,zd+0.20),(0.40,0.02,0.05),'paint_grey',ch=0) if False else None
    b.box((xo-0.20,0,zk+0.05),(0.14,0.10,zd-zk-0.17),'paint_black')
    b.box((xo-0.20,0,zk-0.02),(0.36,0.05,0.10),'paint_black')
    b.box((xo-0.20,0,zk+0.08),(0.30,0.20,0.012),'paint_grey',ch=0)
    n=sg(hi,3,3)
    for k in range(3):
        a=2*math.pi*k/3; c=V(xo-0.18,0,zk+0.02)
        _q(b,[c+V(-0.10,0,0),c+V(-0.13,0.12*math.cos(a),0.12*math.sin(a)),c+V(-0.13,0.12*math.cos(a+0.6),0.12*math.sin(a+0.6))],'ss',(-1,0,0))
    # keel blocks + jack stands
    for x in (-1.3,0.2):
        b.box((x,0,0),(0.40,0.40,0.14),'oak'); b.box((x,0,0.14),(0.36,0.30,zk-0.14),'oak')
    for x in (-1.2,0.6):
        w,k,s=half(x); zs=k+0.30*(s-k)
        for sy in (1,-1):
            yb=sy*(w*0.80+0.32); c=V(x,yb,0)
            for a in (0,2.1,4.2):
                b.tube(c+V(0.28*math.cos(a),0.28*math.sin(a),0.0),c+V(0,0,0.55),0.016,0.016,4,'rack_blu',cap0=False,cap1=False)
            b.tube(c+V(0,0,0.55),V(x,sy*(w*0.80),zs-0.02),0.022,0.022,sg(hi,5,6),'galv',cap0=False,cap1=True)
            b.box((x,sy*(w*0.80+0.01),zs-0.06),(0.18,0.05,0.12),'rubber',ch=0)
    badge(b,-L/2+0.6,-0.67,zk+0.75)
    b.cbox((-0.209,0,0),(L+0.45,2.40,zk+Hs+1.25))

# ------------------------------------------------------------------ engine_hoist
def engine_hoist(b, hi=False):
    """2-ton folding shop crane: red H base with long legs and castors, square upright, boom on a hydraulic ram
    (black cylinder, chrome rod, pump handle), load chain and hook holding a small blue inline engine block."""
    for sy in (-1,1):
        b.box((0.30,sy*0.38,0.06),(1.45,0.08,0.08),'hoist_red')
        caster(b,1.0,sy*0.38,hi,0.04); caster(b,-0.38,sy*0.38,hi,0.04)
    b.box((-0.40,0,0.06),(0.10,0.84,0.10),'hoist_red')
    b.box((-0.40,0,0.16),(0.10,0.10,1.30),'hoist_red')
    for sy in (-1,1): b.tube((-0.40,sy*0.05,0.20),(0.05,sy*0.36,0.10),0.018,0.018,4,'hoist_red',cap0=False,cap1=False)
    # boom: from top of upright forward and up
    p0=V(-0.40,0,1.42); p1=V(0.95,0,1.68)
    d=(p1-p0); n0=nfaces(b)
    b.box((0,0,-0.045),(d.length,0.09,0.09),'hoist_red')
    ang=math.atan2(d.z,d.x); M=mathutils.Matrix.Rotation(-ang,3,'Y'); mid=(p0+p1)/2
    xform(b,n0,lambda co: M@co+mid)
    b.box((-0.40,0,1.40),(0.14,0.14,0.06),'steel_dk')
    # ram
    r0=V(-0.36,0,0.42); r1=p0+d*0.42
    rm=r0+(r1-r0)*0.58
    b.tube(r0,rm,0.045,0.045,sg(hi,6,10),'ram_blk',cap0=True,cap1=True)
    b.tube(rm,r1,0.020,0.020,sg(hi,5,8),'chrome',cap0=False,cap1=True)
    b.box((r0.x-0.02,0,r0.z-0.12),(0.12,0.12,0.12),'ram_blk')
    b.tube((r0.x+0.02,0,r0.z-0.04),(r0.x+0.30,0.0,r0.z+0.26),0.010,0.010,4,'chrome',cap0=False,cap1=True)
    # chain + hook
    hz=1.12
    for i in range(sg(hi,6,10)):
        z=p1.z-0.05-i*(p1.z-0.05-hz)/sg(hi,6,10)
        b.box((p1.x,0,z-0.035),(0.012 if i%2 else 0.004,0.004 if i%2 else 0.012,0.035),'steel_dk',ch=0)
    b.sweep([V(p1.x,0,hz),V(p1.x,0,hz-0.06),V(p1.x+0.04,0,hz-0.09),V(p1.x+0.06,0,hz-0.05)],0.008,4,'steel_dk',cap0=True,cap1=True)
    # engine block on two chains
    ex,ez=p1.x,0.66
    for sx in (-1,1): b.tube((p1.x,0,hz-0.06),(ex+sx*0.20,0,ez+0.38),0.005,0.005,3,'steel_dk',cap0=False,cap1=False)
    b.box((ex,0,ez),(0.50,0.28,0.30),'eng_blu')
    b.box((ex,0,ez+0.30),(0.46,0.18,0.08),'eng_gry')
    b.box((ex,-0.17,ez+0.10),(0.42,0.06,0.10),'eng_gry',ch=0)
    b.box((ex,0,ez-0.12),(0.48,0.24,0.12),'eng_gry')
    b.tube((ex+0.25,0,ez+0.10),(ex+0.30,0,ez+0.10),0.08,0.08,sg(hi,8,12),'steel_dk',cap0=False,cap1=True)
    badge(b,0.40,-0.421,0.10)
    b.cbox((0.39,0,0),(1.56,0.92,1.80))

# ------------------------------------------------------------------ oil_can_shelf
def oil_can_shelf(b, hi=False):
    """auto-parts gondola bay of motor oil: grey steel shelving with pegged back, four shelves of quart bottles in
    brand colours with price strips, gallon jugs on the base deck, red promo header."""
    W,D,H=1.22,0.46,1.70
    b.box((0,D/2-0.02,0),(W,0.03,H),'mach_gry')
    for sx in (-1,1): b.box((sx*(W/2-0.02),0,0),(0.04,D,H),'steel_dk')
    b.box((0,0,0),(W,D,0.12),'steel_dk')
    b.box((0,D/2-0.04,H),(W,0.04,0.22),'oil_red')
    text(b,hi,'MOTOR OIL',0.06,(0,D/2-0.0605,H+0.11),'paint_white')
    frontq(b,-0.30,0.30,D/2-0.0602,H+0.04,H+0.18,'oil_sign' if not hi else 'oil_red')
    R=random.Random(5)
    brands=['oil_yel','oil_blk','oil_blu','oil_red','oil_grn','oil_slv']
    zs=[0.12,0.48,0.82,1.16,1.48]
    for li,z in enumerate(zs):
        b.box((0,0,z),(W-0.08,D,0.02),'mach_gry',ch=0)
        frontq(b,-W/2+0.04,W/2-0.04,-D/2-0.0008,z-0.03,z+0.02,'paper' if li%2 else 'sugar_yl')
        if li==0:          # gallon jugs
            for i in range(6):
                x=-W/2+0.12+i*0.195; k=brands[i%6]
                b.box((x,-0.05,z+0.02),(0.16,0.26,0.27),k)
                b.tube((x+0.04,-0.12,z+0.29),(x+0.04,-0.12,z+0.32),0.02,0.02,sg(hi,5,8),'oil_blk',cap0=False,cap1=True)
                frontq(b,x-0.06,x+0.06,-0.1808,z+0.08,z+0.20,'mag_white')
            continue
        bk=brands[(li*2)%6]; bk2=brands[(li*2+1)%6]
        for i in range(10):
            x=-W/2+0.08+i*0.117; k=bk if i<5 else bk2
            y=-D/2+0.07
            b.box((x,y,z+0.02),(0.095,0.06,0.22),k,ch=0 if not hi else None,skip=('bottom',))
            if hi or i%2==0: b.tube((x+0.02,y,z+0.24),(x+0.02,y,z+0.27),0.016,0.016,sg(hi,4,8),'oil_blk' if k!='oil_blk' else 'oil_yel',cap0=False,cap1=True)
            frontq(b,x-0.04,x+0.04,y-0.0308,z+0.06,z+0.15,'mag_white')
            if hi:
                for rr in (1,2): b.box((x,y+rr*0.13,z+0.02),(0.095,0.06,0.22),k)
        if not hi:                 # rear rows as one block per brand run (only their fronts/tops read)
            for g,k in ((0,bk),(1,bk2)):
                x0=-W/2+0.08+g*5*0.117-0.0475; x1=x0+4*0.117+0.095
                b.box(((x0+x1)/2,-D/2+0.07+0.165,z+0.02),(x1-x0,0.19,0.22),k,ch=0,skip=('bottom',))
    badge(b,W/2-0.10,-D/2-0.001,0.04)
    b.cbox((0,0,0),(W,D,H+0.22))

# ------------------------------------------------------------------ pallet_racking
def pallet_racking(b, hi=False):
    """trade-counter warehouse bay: blue punched uprights with diagonal bracing, orange step beams on three levels,
    wire mesh decks, wooden pallets with cartons and shrink-wrapped loads, floor-level pallet."""
    W,D,H=2.70,1.00,2.60
    for sx in (-1,1):
        for sy in (-1,1):
            x=sx*(W/2-0.04); y=sy*(D/2-0.04)
            b.box((x,y,0),(0.08,0.07,H),'rack_blu')
            b.box((x,y,0),(0.16,0.14,0.01),'steel_dk',ch=0)
            for k in range(sg(hi,6,14)):
                z=0.25+k*(H-0.4)/sg(hi,6,14)
                frontq(b,x-0.012,x+0.012,y-0.0358*sy if sy<0 else y+0.0358,z,z+0.05,'slot_dk',(0,sy,0))
        # frame bracing
        x=sx*(W/2-0.04)
        for k in range(4):
            za=0.15+k*0.60; zb=za+0.60
            b.tube((x,-D/2+0.06,za if k%2==0 else zb),(x,D/2-0.06,zb if k%2==0 else za),0.012,0.012,4,'rack_blu',cap0=False,cap1=False)
    levels=[0.0,0.95,1.85]
    R=random.Random(9)
    for li,z in enumerate(levels):
        if z>0:
            for sy in (-1,1): b.box((0,sy*(D/2-0.04),z-0.12),(W-0.08,0.05,0.12),'rack_org')
            for k in range(sg(hi,4,8)):
                yy=-D/2+0.08+k*(D-0.16)/(sg(hi,4,8)-1)
                b.box((0,yy,z-0.012),(W-0.12,0.006,0.008),'wire',ch=0)
            for k in range(3): b.box((-W/2+0.45+k*0.9,0,z-0.05),(0.03,D-0.10,0.04),'wire',ch=0)
        for p in range(2):
            px=-W/2+0.70+p*1.30; pz=z+0.01
            b.box((px,0,pz),(1.0,0.92 if z>0 else 0.95,0.03),'pallet')
            for sx in (-1,0,1): b.box((px+sx*0.44,0,pz+0.03),(0.10,0.90,0.08),'pallet_dk' if False else 'lumber_dk')
            b.box((px,0,pz+0.11),(1.0,0.92,0.025),'pallet')
            for k in range(5): frontq(b,px-0.5,px+0.5,-0.4608,pz+0.11+0.0,pz+0.135,'lumber_dk') if (k==0 and False) else None
            top=pz+0.135
            kind=(li+p)%3
            if kind==0:      # stacked cartons
                for cx in range(2):
                    for cz in range(2 if z<1.8 else 1):
                        b.box((px-0.24+cx*0.48,0,top+cz*0.34),(0.46,0.80,0.33),'kraft',ch=0)
                        frontq(b,px-0.24+cx*0.48-0.10,px-0.24+cx*0.48+0.10,-0.4008,top+cz*0.34+0.10,top+cz*0.34+0.22,'mag_white')
            elif kind==1:    # shrink-wrapped load
                hh=0.62 if z<1.8 else 0.55
                b.box((px,0,top),(0.96,0.86,hh),'oil_blu' if li else 'oil_yel')
                b.box((px,-0.002,top+0.02),(0.98,0.866,hh-0.04),'wrap',ch=0)
            else:            # drums
                for cx in range(2):
                    for cy in range(2):
                        b.tube((px-0.24+cx*0.48,-0.21+cy*0.42,top),(px-0.24+cx*0.48,-0.21+cy*0.42,top+0.58 if z<1.8 else top+0.50),0.19,0.19,sg(hi,8,12),'eng_blu' if cy else 'oil_red',cap0=False,cap1=True)
    badge(b,-W/2+0.20,-D/2-0.001,0.10)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ tire_rack
def tire_rack(b, hi=False):
    """tyre shop display: two-tier tubular steel rack with tyres standing on their treads in V cradles (eight on
    the floor tier, five on the top tier), price tags hanging from the top rail."""
    W,D=2.00,0.42
    for sx in (-1,1):
        x=sx*(W/2-0.02)
        for sy in (-1,1): b.box((x,sy*(D/2-0.02),0),(0.04,0.04,1.55),'steel_dk',ch=0 if not hi else None)
        for z in (0.05,0.78): b.box((x,0,z),(0.04,D,0.04),'steel_dk',ch=0 if not hi else None)
    for z in (0.05,0.78):
        for sy in (-1,1): b.box((0,sy*0.10,z+0.02),(W-0.04,0.03,0.03),'steel_dk',ch=0 if not hi else None)
    b.box((0,-D/2+0.02,1.51),(W,0.04,0.04),'steel_dk',ch=0 if not hi else None)
    b.box((0,D/2-0.02,1.51),(W,0.04,0.04),'steel_dk',ch=0 if not hi else None)
    sizes=[(0.33,0.21,0.21),(0.33,0.21,0.21),(0.34,0.22,0.23),(0.34,0.22,0.23),(0.31,0.20,0.19),(0.31,0.20,0.19),(0.35,0.22,0.25),(0.35,0.22,0.25)]
    x=-W/2+0.06
    for i,(Ro,Ri,w) in enumerate(sizes):
        x+=w/2+0.005
        tyre(b,(x,0,0.09+Ro),'x',Ro,Ri,w,hi,nn=12,bore=(i==0 or i==len(sizes)-1))
        x+=w/2
    x=-W/2+0.25
    for i,(Ro,Ri,w) in enumerate(sizes[:4]):
        x+=w/2+0.12
        tyre(b,(x,0,0.82+Ro),'x',Ro,Ri,w,hi,nn=12)
        b.box((x,-D/2+0.019,1.38),(0.07,0.002,0.10),'paper' if i%2 else 'sugar_yl',ch=0)
        x+=w/2+0.12
    badge(b,W/2-0.12,-D/2-0.001,0.06)
    b.cbox((0,0,0),(W,max(D,0.50),1.55))

# ------------------------------------------------------------------ tool_chest
def tool_chest(b, hi=False):
    """mechanic's rolling tool chest: glossy red roller cabinet (six drawers, chrome bar pulls, side handle,
    castors, rubber-mat top) with a top chest (five drawers, lift lid), a few tools on top."""
    W,D=0.98,0.48
    for sx in (-1,1):
        for sy in (-1,1): caster(b,sx*(W/2-0.07),sy*(D/2-0.07),hi,0.05)
    b.box((0,0,0.11),(W,D,0.86),'tool_red')
    b.box((0,0,0.97),(W+0.01,D+0.01,0.012),'rubber',ch=0)
    hs=[0.10,0.10,0.10,0.15,0.18,0.20]; z=0.92
    for i,h in enumerate(hs):
        z-=h
        frontq(b,-W/2+0.03,W/2-0.03,-D/2-0.0008,z+0.008,z+h-0.008,'tool_red')
        frontq(b,-W/2+0.03,W/2-0.03,-D/2-0.0012,z+h-0.010,z+h-0.006,'kick_blk')
        b.box((0,-D/2-0.018,z+h-0.04),(W-0.14,0.012,0.014),'chrome',ch=0)
    b.tube((W/2+0.02,-0.15,0.85),(W/2+0.02,0.15,0.85),0.012,0.012,5,'chrome',cap0=True,cap1=True)
    for sy in (-1,1): b.tube((W/2,sy*0.15,0.85),(W/2+0.02,sy*0.15,0.85),0.01,0.01,4,'chrome',cap0=False,cap1=False)
    # top chest
    zt=0.982
    b.box((0,0.03,zt),(W-0.02,D-0.08,0.40),'tool_red')
    z=zt+0.36
    for i,h in enumerate([0.07,0.07,0.07,0.07,0.08]):
        z-=h
        frontq(b,-W/2+0.04,W/2-0.04,-D/2+0.0692,z+0.006,z+h-0.006,'tool_red')
        b.box((0,-D/2+0.058,z+h-0.03),(W-0.20,0.010,0.012),'chrome',ch=0)
    b.box((0,0.03,zt+0.40),(W,D-0.06,0.06),'tool_red')
    b.box((0,-D/2+0.07,zt+0.36),(0.20,0.01,0.03),'chrome',ch=0)
    # tools on the lid
    b.box((-0.20,0.0,zt+0.46),(0.26,0.035,0.012),'chrome',rz=0.3,ch=0)
    b.box((0.18,0.05,zt+0.46),(0.22,0.05,0.04),'oil_yel',ch=0)
    b.tube((0.05,-0.08,zt+0.47),(0.30,-0.10,zt+0.47),0.009,0.009,4,'chrome',cap0=True,cap1=True)
    badge(b,0.0,-D/2-0.0016,0.94)
    b.cbox((0,0,0),(W+0.05,D,1.45))

# ------------------------------------------------------------------ wheel_balancer
def wheel_balancer(b, hi=False):
    """tyre-shop wheel balancer: grey cabinet with weight-tray top, blue side panel, horizontal shaft on the right
    carrying a wheel (tyre on alloy rim) under a raised hood guard, display pod on a post, foot brake pedal."""
    b.box((0,0,0),(0.62,0.58,0.88),'mach_gry')
    b.box((0,0,0.88),(0.66,0.60,0.06),'mach_blu')
    for i in range(sg(hi,6,10)):
        x=-0.27+i*0.54/(sg(hi,6,10)-1)
        b.box((x,-0.10,0.94),(0.045,0.32,0.004),'wt_lead' if i%2 else 'ss_dk',ch=0)
    frontq(b,-0.28,0.28,-0.2908,0.10,0.80,'mach_blu')
    b.box((-0.10,-0.30,0.0),(0.14,0.10,0.05),'rubber',ch=0)
    # display pod
    b.tube((-0.20,0.20,0.94),(-0.20,0.20,1.30),0.025,0.025,sg(hi,5,8),'steel_dk',cap0=False,cap1=False)
    b.box((-0.20,0.18,1.30),(0.40,0.10,0.26),'mach_gry',rx=-0.2)
    _q(b,[V(-0.36,0.128,1.34),V(-0.04,0.128,1.34),V(-0.04,0.112,1.52),V(-0.36,0.112,1.52)],'screen',(0,-1,0.1))
    # shaft + wheel
    b.tube((0.31,0.0,0.62),(0.62,0.0,0.62),0.025,0.025,sg(hi,6,8),'chrome',cap0=False,cap1=True)
    b.tube((0.31,0.0,0.62),(0.36,0.0,0.62),0.09,0.09,sg(hi,8,12),'steel_dk',cap0=False,cap1=True)
    tyre(b,(0.50,0.0,0.62),'x',0.30,0.20,0.20,hi,rim='blade')
    b.tube((0.60,0.0,0.62),(0.64,0.0,0.62),0.06,0.03,sg(hi,6,8),'paint_red',cap0=True,cap1=True)
    # hood guard raised behind the wheel
    n=sg(hi,6,10); c=V(0.50,0.05,0.62); n0=nfaces(b)
    for i in range(n):
        a0=math.pi*0.15+math.pi*0.85*i/n; a1=math.pi*0.15+math.pi*0.85*(i+1)/n
        P=[c+V(-0.13,0.37*math.cos(a0),0.37*math.sin(a0)),c+V(0.13,0.37*math.cos(a0),0.37*math.sin(a0)),c+V(0.13,0.37*math.cos(a1),0.37*math.sin(a1)),c+V(-0.13,0.37*math.cos(a1),0.37*math.sin(a1))]
        mid=(P[0]+P[2])/2-c; _q(b,P,'mach_blu',tuple(mid.normalized()))
        _q(b,P[::-1],'steel_dk',tuple(-mid.normalized()))
    b.tube((0.36,0.30,0.70),(0.36,0.32,0.96),0.015,0.015,4,'steel_dk',cap0=False,cap1=False)
    badge(b,0.18,-0.2912,0.84)
    b.cbox((0.12,0.015,0),(0.90,0.80,1.40))

# ------------------------------------------------------------------ lumber_rack
def lumber_rack(b, hi=False):
    """building-supply cantilever lumber rack: three steel columns on long feet with four levels of arms, carrying
    bundles of pine studs and boards of mixed lengths, a few cedar boards and plywood sheets on the bottom."""
    W=2.40; H=2.20
    cols=[-1.05,0.0,1.05]
    for x in cols:
        b.box((x,0.10,0),(0.10,0.90,0.10),'rack_blu')
        b.box((x,0.30,0.10),(0.10,0.10,H),'rack_blu')
        for z in (0.40,0.95,1.50,2.05):
            b.box((x,-0.07,z),(0.06,0.64,0.06),'rack_blu')
            b.box((x,-0.38,z+0.06),(0.06,0.03,0.05),'rack_blu',ch=0)
    R=random.Random(21)
    for li,z in enumerate((0.46,1.01,1.56,2.11)):
        y=-0.33; zz=z
        if li==0:
            for k in range(3): b.box((0,-0.05,zz+k*0.02),(2.44,0.60,0.019),'ply' if k<2 else 'lumber',ch=0); continue
        nb=sg(hi,4,6)
        for row in range(2 if li<3 else 1):
            y=-0.33
            for k in range(nb):
                ln=R.choice((2.44,2.44,3.05,1.83)) if li!=2 else 2.44
                wd=R.choice((0.09,0.14,0.185)); th=0.038
                key='lumber' if (k+row+li)%4 else 'lumber_dk'
                b.box((R.uniform(-0.05,0.05),y+wd/2,zz+row*th),(min(ln,2.5),wd-0.004,th-0.002),key,ch=0 if not hi else None,skip=() if hi else ('bottom',))
                if hi: frontq(b,-0.02,0.02,0,0,0,'paper') if False else None
                y+=wd
                if y>0.20: break
        if li==3: b.box((0.6,-0.25,zz+0.04),(0.08,0.002,0.06),'paper',ch=0)
    # sheet leaning? keep it inside the footprint: bundle strap
    for x in (-0.6,0.6): b.box((x,-0.10,1.01),(0.02,0.62,0.10),'oil_red',ch=0) if False else None
    badge(b,0.0,0.249,0.20)
    b.cbox((0,0.078,0),(W+0.1,0.90,H+0.10))

# ------------------------------------------------------------------ table_saw
def table_saw(b, hi=False):
    """10-inch cabinet table saw: grey enclosed cabinet with dust port, cast-iron top with mitre slots and insert
    plate, blade rising through it with riving knife and clear blade guard, rip fence on front rail, extension wing,
    yellow paddle switch, height and tilt handwheels."""
    b.box((0,0,0),(0.55,0.52,0.80),'mach_gry')
    b.box((0,0,0),(0.60,0.56,0.06),'steel_dk')
    b.tube((0.0,0.26,0.20),(0.0,0.34,0.20),0.05,0.05,sg(hi,6,10),'steel_dk',cap0=False,cap1=False)
    T=0.86
    b.box((0,0,0.80),(0.70,0.68,0.06),'iron')
    b.box((0.60,0,0.80),(0.50,0.68,0.06),'iron',ch=0)
    for x in (-0.18,0.20): topq(b,x-0.01,x+0.01,-0.34,0.34,T+0.0008,'slot_dk')
    topq(b,-0.04,0.06,-0.20,0.20,T+0.0006,'paint_red')
    # blade: disc in the YZ plane, partly above the table
    n=sg(hi,10,16); c=V(0.01,0.0,T-0.06)
    pts=[c+V(0,0.127*math.cos(2*math.pi*i/n),0.127*math.sin(2*math.pi*i/n)) for i in range(n)]
    pts=[p if p.z>T+0.001 else V(p.x,p.y,T+0.001) for p in pts]
    _q(b,pts,'blade',(-1,0,0)); _q(b,[p+V(0.003,0,0) for p in pts][::-1],'blade',(1,0,0))
    b.box((0.01,0.10,T),(0.003,0.06,0.10),'steel_dk',ch=0)
    b.box((0.01,0.03,T+0.10),(0.07,0.24,0.08),'glass')
    # front rail + fence
    b.box((0.20,-0.37,T-0.08),(1.20,0.05,0.06),'steel_dk')
    b.box((0.30,0,T),(0.06,0.70,0.07),'steel_dk')
    b.box((0.30,-0.38,T-0.10),(0.10,0.06,0.17),'steel_dk')
    b.box((-0.18,-0.36,T-0.16),(0.09,0.05,0.07),'saw_yel')
    for (x,z) in ((0.0,0.50),):
        b.tube((x,-0.26,z),(x,-0.32,z),0.08,0.08,sg(hi,8,12),'steel_dk',cap0=False,cap1=True)
        b.tube((x+0.05,-0.32,z),(x+0.05,-0.36,z),0.012,0.012,4,'chrome',cap0=False,cap1=True)
    b.tube((0.276,-0.05,0.45),(0.33,-0.05,0.45),0.07,0.07,sg(hi,8,12),'steel_dk',cap0=False,cap1=True)
    badge(b,0.0,-0.2612,0.70)
    b.cbox((0.225,-0.03,0),(1.20,0.80,0.98))

# ------------------------------------------------------------------ registry
_C=dict(dir='props/indoor/trade',pdir='indoor_trade',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=48,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
W_=dict(cage=0.04,ray=0.12)
PROPS=[
    _p('boat_on_stands',boat_on_stands,'large',2000,shift=(0.209,0.0)),
    _p('engine_hoist',engine_hoist,'medium',1000,shift=(-0.39,0.0)),
    _p('oil_can_shelf',oil_can_shelf,'medium',1200,**W_),
    _p('pallet_racking',pallet_racking,'large',1500),
    _p('tire_rack',tire_rack,'large',1500),
    _p('tool_chest',tool_chest,'medium',800,**W_),
    _p('wheel_balancer',wheel_balancer,'medium',1000,shift=(-0.12,-0.015)),
    _p('lumber_rack',lumber_rack,'large',1200,shift=(0.0,-0.078),max_side=32),
    _p('table_saw',table_saw,'medium',800,shift=(-0.225,0.03),max_side=32),
]
INDOOR_LOOK=True
