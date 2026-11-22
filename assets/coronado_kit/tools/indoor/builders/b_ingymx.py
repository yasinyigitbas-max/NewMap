"""Indoor gym / sport / bike / bait props (shop-gap batch 6, module b_ingymx) — original geometry, page I, near+col
only. Shared page-I trims + per-key vertex tint (one material per prop); 32 px unique bake slots (page I is nearly
full). Ground props: origin at footprint centre, front toward -Y.
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math, random
import mathutils
from mathutils import Vector
from b_inshared import sg
from b_intrade import TR as _TR, TINT as _TINT, _q, V, nfaces, xform, frontq, topq, text, caster, badge, tyre, SL

TR=dict(_TR); TINT=dict(_TINT)
_NEW={
 'db_blk':('ti_plastic',(0.10,0.10,0.11)), 'gym_red':('ti_paint',(0.80,0.08,0.06)), 'belt':('ti_plastic',(0.09,0.09,0.10)),
 'frame_blk':('ti_paint',(0.10,0.10,0.11)), 'frame_slv':('ti_metal',(0.80,0.81,0.83)), 'bike_teal':('ti_paint',(0.05,0.55,0.55)),
 'tank_yel':('ti_paint',(1.00,0.80,0.05)), 'tank_alu':('ti_metal',(0.82,0.83,0.85)), 'tank_blu':('ti_paint',(0.10,0.30,0.75)),
 'tank_red':('ti_paint',(0.80,0.12,0.08)), 'rod_blk':('ti_plastic',(0.10,0.10,0.10)), 'rod_grn':('ti_paint',(0.10,0.40,0.25)),
 'rod_wht':('ti_paint',(0.95,0.95,0.93)), 'cork':('ti_wood',(0.85,0.66,0.42)), 'bait_wht':('ti_plastic',(1.02,1.02,1.00)),
 'bait_blu':('ti_plastic',(0.15,0.40,0.70)), 'water_dk':('ti_glass',(0.18,0.38,0.42)), 'minnow':('ti_metal',(0.75,0.78,0.72)),
 'net':('ti_fabric',(0.25,0.30,0.25)),
}
for k,(t,c) in _NEW.items(): TR[k]=(t,(0.875,0.875)); TINT[k]=c
def hexdb(b, x, y, z, L, r, hi, head='db_blk'):
    """hex dumbbell lying front-to-back (along Y): two hex heads + chrome handle"""
    h=0.055+r*0.6
    b.tube((x,y-L/2,z),(x,y-L/2+h,z),r,r,6,head,cap0=True,cap1=hi,smooth=False,phase=math.pi/6)
    b.tube((x,y+L/2-h,z),(x,y+L/2,z),r,r,6,head,cap0=hi,cap1=True,smooth=False,phase=math.pi/6)
    b.tube((x,y-L/2+h,z),(x,y+L/2-h,z),0.016,0.016,sg(hi,4,8),'chrome',cap0=False,cap1=False)

# ------------------------------------------------------------------ dumbbell_rack
def dumbbell_rack(b, hi=False):
    """two-tier commercial dumbbell rack: black steel frame with angled saddle trays, ten pairs of rubber hex
    dumbbells graded light to heavy, weight numbers on the tray lip."""
    W=1.80; D=0.62
    for x in (-W/2+0.04,0.0,W/2-0.04):
        b.box((x,0.18,0),(0.06,0.06,0.88),'frame_blk')
        b.box((x,-0.10,0),(0.06,0.06,0.48),'frame_blk')
        b.box((x,0.04,0),(0.06,D,0.04),'frame_blk')
    for (y,z,rx) in ((-0.12,0.44,0.25),(0.14,0.82,0.25)):
        b.box((0,y,z),(W,0.26,0.03),'frame_blk')
        b.box((0,y-0.13,z-0.02),(W,0.012,0.06),'gym_red',ch=0)
    R=[0.050,0.054,0.058,0.062,0.066,0.070,0.074,0.078,0.082,0.088]
    for t,(y,z) in enumerate(((-0.12,0.47),(0.14,0.85))):
        for i in range(5):
            k=i if t==1 else i+5
            r=R[k]; L=0.30+0.008*k
            x=-W/2+0.18+i*0.36
            for sx in (-1,1): hexdb(b,x+sx*(r+0.004),y,z+0.03+r*0.87,L,r,hi)
            b.box((x,y-0.131,z-0.035),(0.06,0.002,0.03),'paper',ch=0)
    badge(b,W/2-0.15,-0.262,0.43)
    b.cbox((0,0.04,0),(W,D,0.98))

# ------------------------------------------------------------------ rowing_machine
def rowing_machine(b, hi=False):
    """air rowing ergometer: aluminium monorail on front/rear legs, black flywheel housing with air vents, PM
    monitor on a swing arm, sliding seat, foot stretchers with straps, handle hooked on the chain."""
    L=2.40
    zr=0.36
    n0=nfaces(b); b.box((0,0,-0.03),(1.70,0.10,0.06),'tank_alu'); xform(b,n0,lambda co: mathutils.Matrix.Rotation(-0.085,3,'Y')@co+V(-0.30,0,zr-0.02))
    b.box((-1.18,0,0),(0.10,0.50,0.05),'frame_blk'); b.box((-1.18,0,0.05),(0.08,0.08,zr-0.13),'frame_blk')
    # front frame + flywheel housing
    b.box((0.75,0,0),(0.10,0.56,0.05),'frame_blk')
    b.tube((0.62,0,0.30),(0.75,0,0.05),0.035,0.035,sg(hi,5,8),'frame_blk',cap0=False,cap1=False)
    c=V(0.86,0,0.40); n=sg(hi,10,18)
    b.tube(c+V(0,-0.14,0),c+V(0,0.14,0),0.30,0.30,n,'frame_blk',cap0=True,cap1=True)
    for sy in (-1,1):
        for k in range(sg(hi,4,8)):
            a=2*math.pi*k/sg(hi,4,8)
            P=[c+V(0.08*math.cos(a),sy*0.1405,0.08*math.sin(a)),c+V(0.26*math.cos(a-0.12),sy*0.1405,0.26*math.sin(a-0.12)),c+V(0.26*math.cos(a+0.12),sy*0.1405,0.26*math.sin(a+0.12))]
            _q(b,P,'slot_dk',(0,sy,0))
    b.box((0.62,0,0.30),(0.20,0.16,0.24),'frame_blk')
    # monitor arm + monitor
    b.sweep([V(0.62,0,0.52),V(0.45,0,0.80),V(0.38,0,0.98)],0.018,sg(hi,5,8),'frame_blk',cap0=False,cap1=True)
    b.box((0.36,0,0.96),(0.06,0.20,0.18),'frame_blk',rx=0.0)
    _q(b,[V(0.329,-0.08,0.99),V(0.329,0.08,0.99),V(0.329,0.08,1.11),V(0.329,-0.08,1.11)],'screen',(-1,0,0))
    # foot stretchers
    for sy in (-1,1):
        n0=nfaces(b); b.box((0,0,0),(0.10,0.13,0.28),'frame_blk'); xform(b,n0,lambda co,sy=sy: mathutils.Matrix.Rotation(-0.75,3,'Y')@co+V(0.40,sy*0.10,zr+0.02))
        b.box((0.40,sy*0.10,zr+0.14),(0.10,0.135,0.02),'gym_red',ch=0) if False else None
        b.box((0.46,sy*0.10,zr+0.20),(0.03,0.14,0.04),'gym_red',ch=0)
    # handle + chain
    b.tube((0.56,-0.24,0.60),(0.56,0.24,0.60),0.016,0.016,sg(hi,5,8),'frame_blk',cap0=True,cap1=True)
    b.tube((0.56,-0.24,0.60),(0.56,-0.12,0.60),0.022,0.022,sg(hi,5,8),'rubber',cap0=True,cap1=True)
    b.tube((0.56,0.12,0.60),(0.56,0.24,0.60),0.022,0.022,sg(hi,5,8),'rubber',cap0=True,cap1=True)
    b.tube((0.57,0,0.60),(0.66,0,0.40),0.005,0.005,3,'steel_dk',cap0=False,cap1=False)
    # seat
    xs=-0.35; zs=zr+0.03+0.085*0.35
    b.box((xs,0,zs),(0.18,0.14,0.05),'frame_blk')
    b.box((xs,0,zs+0.05),(0.36,0.30,0.06),'leather_blk')
    badge(b,-0.30,-0.0512,zr-0.0)
    b.cbox((0.0,0,0),(2.10,0.60,1.15))

# ------------------------------------------------------------------ treadmill
def treadmill(b, hi=False):
    """commercial treadmill: deck with black belt between grey side rails and step-up plates, motor hood at the
    front, twin uprights to a console with screen and keypad, side handrails, pulse grips, red safety key."""
    L,W=2.00,0.86
    b.box((0,0,0),(L,W,0.10),'frame_blk')
    b.box((-0.08,0,0.10),(1.55,0.52,0.06),'belt')
    for sy in (-1,1): b.box((-0.08,sy*0.35,0.10),(1.60,0.16,0.065),'tank_alu')
    for k in range(sg(hi,0,6)): topq(b,-0.85+k*0.3,-0.84+k*0.3,-0.26,0.26,0.1605,'tv_grey')
    b.tube((-0.88,-0.26,0.11),(-0.88,0.26,0.11),0.05,0.05,sg(hi,6,10),'tank_alu',cap0=True,cap1=True)
    b.box((0.82,0,0.08),(0.36,W,0.22),'frame_blk')
    frontq(b,0.66,0.98,0,0,0,'paper') if False else None
    b.box((0.82,-W/2-0.002,0.14),(0.20,0.002,0.06),'gym_red',ch=0)
    # uprights + console
    for sy in (-1,1):
        b.sweep([V(0.86,sy*0.38,0.28),V(0.80,sy*0.38,0.95),V(0.66,sy*0.36,1.28)],0.035,sg(hi,6,8),'frame_blk',cap0=False,cap1=False)
        b.sweep([V(0.70,sy*0.38,1.10),V(0.15,sy*0.40,1.05)],0.022,sg(hi,5,8),'frame_slv',cap0=False,cap1=True)
        b.tube((0.48,sy*0.39,1.07),(0.62,sy*0.385,1.09),0.028,0.028,sg(hi,5,8),'ss',cap0=True,cap1=True)
    n0=nfaces(b); b.box((0,0,-0.06),(0.07,0.80,0.34),'frame_blk')
    M=mathutils.Matrix.Rotation(-0.55,3,'Y'); xform(b,n0,lambda co: M@co+V(0.66,0,1.30))
    sc=V(0.66,0,1.30)+M@V(-0.036,0,0.03)
    nn=M@V(-1,0,0)
    up=M@V(0,0,1)
    _q(b,[sc+V(0,-0.22,0)-up*0.07,sc+V(0,0.22,0)-up*0.07,sc+V(0,0.22,0)+up*0.10,sc+V(0,-0.22,0)+up*0.10],'screen',tuple(nn))
    kc=V(0.66,0,1.30)+M@V(-0.036,0,-0.11)
    _q(b,[kc+V(0,-0.28,0)-up*0.025,kc+V(0,0.28,0)-up*0.025,kc+V(0,0.28,0)+up*0.025,kc+V(0,-0.28,0)+up*0.025],'keypad',tuple(nn))
    b.box((0.56,0.30,1.16),(0.03,0.04,0.03),'gym_red',ch=0)
    badge(b,-0.70,-W/2-0.001,0.04)
    b.cbox((0,0,0),(L,W,1.50))

# ------------------------------------------------------------------ bike_repair_stand
def bike_repair_stand(b, hi=False):
    """bike-shop workstand: folding tripod base, telescopic post with quick-release collar, swivel clamp head
    holding a teal road bike by the seatpost (wheels, frame triangle, bars, saddle, chainring), tool tray."""
    c=V(0,0.30,0)
    for a in (math.pi/2+0.0, math.pi/2+2.1, math.pi/2+4.2):
        e=c+V(0.45*math.cos(a),0.45*math.sin(a),0.0)
        b.tube(c+V(0,0,0.35),e+V(0,0,0.02),0.016,0.016,sg(hi,5,6),'frame_blk',cap0=False,cap1=False)
        b.box((e.x,e.y,0),(0.05,0.05,0.03),'rubber',ch=0)
    b.tube(c,c+V(0,0,0.95),0.025,0.025,sg(hi,6,8),'frame_blk',cap0=True,cap1=False)
    b.tube(c+V(0,0,0.95),c+V(0,0,1.30),0.019,0.019,sg(hi,6,8),'frame_slv',cap0=False,cap1=False)
    b.box((c.x,c.y,0.93),(0.06,0.06,0.04),'gym_red',ch=0)
    b.tube(c+V(0,0,1.30),c+V(0,-0.18,1.32),0.02,0.02,sg(hi,5,8),'frame_blk',cap0=False,cap1=False)
    b.box((0,0.12,1.26),(0.08,0.08,0.10),'frame_blk')
    b.box((0,0.30,0.62),(0.36,0.20,0.02),'frame_blk')
    for i,k in enumerate(('gym_red','oil_yel','pole_blu')): b.box((-0.10+i*0.10,0.30,0.64),(0.06,0.12,0.02),k,ch=0)
    # bike: hung by the seatpost at (0,0.12,1.30); frame in the XZ plane at y=0.06
    y=0.06; sp=V(0.0,y,1.26)
    bb=V(0.10,y,0.82); st=V(-0.02,y,1.20); ht=V(0.58,y,1.18); hb=V(0.60,y,1.04)
    rw=V(-0.32,y,0.86); fw=V(0.70,y,0.86)
    for p,q,r in ((bb,st,0.016),(st,ht,0.016),(bb,hb,0.020),(bb,rw,0.010),(st,rw,0.010),(hb,ht,0.020),(hb,fw,0.012)):
        b.tube(p,q,r,r,sg(hi,4,6),'bike_teal',cap0=False,cap1=False)
    b.tube(st,sp+V(0,0,0.06),0.012,0.012,4,'frame_slv',cap0=False,cap1=False)
    b.box((sp.x-0.04,y,sp.z+0.06),(0.24,0.07,0.04),'leather_blk')
    b.tube(ht,ht+V(0.02,0,0.08),0.012,0.012,4,'frame_slv',cap0=False,cap1=False)
    b.sweep([ht+V(0.02,-0.20,0.08),ht+V(0.10,-0.20,0.05),ht+V(0.10,-0.20,-0.02)],0.011,4,'rubber',cap0=True,cap1=False)
    b.tube(ht+V(0.02,-0.20,0.08),ht+V(0.02,0.20,0.08),0.011,0.011,4,'rubber',cap0=True,cap1=True)
    b.sweep([ht+V(0.02,0.20,0.08),ht+V(0.10,0.20,0.05),ht+V(0.10,0.20,-0.02)],0.011,4,'rubber',cap0=False,cap1=True)
    for wc in (rw,fw):
        tyre(b,(wc.x,wc.y,wc.z),'y',0.335,0.30,0.028,hi,key='rubber',side='frame_blk',nn=20)
        b.tube(wc+V(0,-0.03,0),wc+V(0,0.03,0),0.02,0.02,4,'frame_slv',cap0=True,cap1=True)
        for k in range(sg(hi,4,8)):
            a=math.pi*k/sg(hi,4,8)
            b.tube(wc+V(0.30*math.cos(a),0,0.30*math.sin(a)),wc-V(0.30*math.cos(a),0,0.30*math.sin(a)),0.002,0.002,3,'frame_slv',cap0=False,cap1=False)
    b.tube(bb+V(0,-0.04,0),bb+V(0,-0.03,0),0.10,0.10,sg(hi,10,16),'frame_slv',cap0=True,cap1=True)
    badge(b,0.0,0.30-0.10-0.001,0.63)
    b.cbox((0.20,0.312,0),(1.40,0.90,1.45))

# ------------------------------------------------------------------ dive_tank_rack
def dive_tank_rack(b, hi=False):
    """dive-shop cylinder rack: powder-coated two-row floor rack with padded cradles and a retaining bar holding
    nine scuba cylinders (yellow, aluminium, blue, one red) with valves and handwheels, rubber boots, a coiled
    regulator hose on one valve."""
    W,D=1.50,0.52
    b.box((0,0,0),(W,D,0.06),'frame_blk')
    for sx in (-1,1):
        b.box((sx*(W/2-0.03),0,0.06),(0.04,D,0.80),'frame_blk')
    for (y,z) in ((-0.13,0.55),(0.13,0.55),(-0.13,0.25),(0.13,0.25)):
        b.box((0,y-0.13 if y<0 else y+0.13,z),(W-0.06,0.03,0.05),'frame_blk')
    b.box((0,0,0.06),(W-0.08,0.04,0.80),'frame_blk')
    cols=['tank_yel','tank_alu','tank_yel','tank_blu','tank_alu','tank_red','tank_yel','tank_alu','tank_blu']
    n=sg(hi,8,14); i=0
    for row,y in enumerate((-0.13,0.13)):
        cnt=5 if row==0 else 4
        for k in range(cnt):
            x=-W/2+0.18+k*0.285+(0.14 if row else 0)
            r=0.092 if cols[i]!='tank_alu' else 0.090; h=0.66
            b.tube((x,y,0.06),(x,y,0.12),r+0.006,r+0.006,n,'rubber',cap0=False,cap1=False)
            b.lathe([(r,0.0),(r,h-0.10),(r*0.70,h-0.03),(0.035,h)],n,cols[i],c=(x,y,0.12),cap_top=True,cap_bot=False)
            b.box((x,y,0.12+h),(0.05,0.05,0.07),'chrome')
            b.tube((x,y-0.025,0.12+h+0.04),(x,y-0.05,0.12+h+0.04),0.03,0.03,sg(hi,5,8),'frame_blk' if i%2 else 'pole_blu',cap0=False,cap1=True)
            frontq(b,x-0.05,x+0.05,y-r-0.0015,0.40,0.50,'mag_white') if row==0 else None
            i+=1
    x=-W/2+0.18; y=-0.13
    b.sweep([V(x,y-0.03,0.86),V(x-0.12,y-0.10,0.80),V(x-0.02,y-0.16,0.70),V(x+0.12,y-0.14,0.78)],0.008,4,'rubber',cap0=True,cap1=True)
    badge(b,W/2-0.12,-D/2-0.001,0.02)
    b.cbox((0,0,0),(W,D,0.95))

# ------------------------------------------------------------------ rod_rack
def rod_rack(b, hi=False):
    """tackle-shop floor rod rack: hardwood base with a row of rod-butt cups and an upper comb rail on two posts,
    twelve rods standing (graphite blanks in black, green, white with cork grips and spinning reels), price tags."""
    W,D=1.40,0.40
    b.box((0,0,0),(W,D,0.10),'walnut')
    for sx in (-1,1):
        b.box((sx*(W/2-0.04),0.12,0.10),(0.06,0.06,1.40),'walnut')
    b.box((0,0.12,1.42),(W,0.08,0.06),'walnut')
    topq(b,-W/2+0.06,W/2-0.06,0.08,0.081,1.4805,'paper') if False else None
    keys=['rod_blk','rod_grn','rod_wht','rod_blk','rod_blk','rod_grn','rod_wht','rod_blk','rod_grn','rod_blk','rod_wht','rod_grn']
    R=random.Random(3)
    for i,k in enumerate(keys):
        x=-W/2+0.12+i*(W-0.24)/11; y=-0.06 if i%2 else 0.04
        top=V(x+R.uniform(-0.03,0.03),0.12,1.45+R.uniform(0.6,0.95))
        bot=V(x,y,0.10)
        b.tube(bot+V(0,0,-0.02),bot+V(0,0,0.04),0.022,0.022,sg(hi,5,8),'rubber',cap0=False,cap1=True)
        d=(top-bot)
        g0=bot+d*0.01; g1=bot+d*0.13
        b.tube(g0,g1,0.014,0.012,sg(hi,4,6),'cork',cap0=True,cap1=False)
        b.tube(g1,top,0.008,0.003,sg(hi,3,5),k,cap0=False,cap1=True)
        if i%3!=2:   # spinning reel on the front of the rod
            rp=bot+d*0.18
            b.tube(rp,rp+V(0,-0.07,0),0.006,0.006,3,'steel_dk',cap0=False,cap1=False)
            b.tube(rp+V(-0.025,-0.075,0),rp+V(0.025,-0.075,0),0.032,0.032,sg(hi,6,10),'frame_blk' if i%2 else 'tank_alu',cap0=True,cap1=True)
        if i%2==0: b.box((x,y-0.03,0.36),(0.03,0.002,0.05),'paper',ch=0)
    for i in range(12):
        x=-W/2+0.12+i*(W-0.24)/11
        topq(b,x-0.012,x+0.012,0.06,0.10,1.4805,'slot_dk')
    badge(b,0.0,-D/2-0.001,0.03)
    b.cbox((0,0,0),(W,D,2.45))

# ------------------------------------------------------------------ bait_tank
def bait_tank(b, hi=False):
    """bait-shop live well: white insulated tank on a blue stand, hinged lid propped open, dark aerated water with
    silver minnows at the surface, bubbler stone line, aerator pump on the side, long-handled dip net."""
    L,W,H=1.20,0.62,0.62
    b.box((0,0,0),(L,W,0.30),'bait_blu')
    b.box((0,0,0.30),(L,W,0.04),'bait_blu')
    zt=0.34+H
    for (x,y,w,d) in ((0,-W/2+0.03,L,0.06),(0,W/2-0.03,L,0.06),(-L/2+0.03,0,0.06,W-0.12),(L/2-0.03,0,0.06,W-0.12)):
        b.box((x,y,0.34),(w,d,H),'bait_wht')
    topq(b,-L/2+0.06,L/2-0.06,-W/2+0.06,W/2-0.06,zt-0.08,'water_dk')
    R=random.Random(4)
    for i in range(sg(hi,10,18)):
        x=R.uniform(-L/2+0.12,L/2-0.12); y=R.uniform(-W/2+0.12,W/2-0.12); a=R.uniform(0,math.pi)
        dx,dy=0.035*math.cos(a),0.035*math.sin(a)
        _q(b,[V(x-dx,y-dy,zt-0.0795),V(x+dy*0.25,y-dx*0.25,zt-0.0795),V(x+dx,y+dy,zt-0.0795),V(x-dy*0.25,y+dx*0.25,zt-0.0795)],'minnow',(0,0,1))
    for i in range(sg(hi,4,8)):
        x=-L/2+0.2+i*(L-0.4)/(sg(hi,4,8)-1)
        topq(b,x-0.02,x+0.02,-0.03,0.03,zt-0.0790,'paint_white')
    # lid propped open (hinged at the back)
    n0=nfaces(b); b.box((0,-W/2,0),(L,W,0.05),'bait_wht')
    M=mathutils.Matrix.Rotation(-1.75,3,'X'); xform(b,n0,lambda co: M@co+V(0,W/2,zt))
    b.box((L/2+0.04,0.0,0.50),(0.10,0.16,0.14),'frame_blk')
    b.sweep([V(L/2+0.04,0,0.64),V(L/2+0.04,0,zt+0.06),V(L/2-0.10,0,zt+0.06),V(L/2-0.10,0,zt-0.10)],0.005,3,'rod_wht',cap0=False,cap1=False)
    # dip net leaning on the side
    b.tube((-L/2-0.04,-0.20,0.02),(-L/2-0.04,-0.02,1.20),0.012,0.012,sg(hi,4,6),'tank_alu',cap0=True,cap1=False)
    c=V(-L/2-0.04,0.03,1.33); n=sg(hi,6,10)
    P=[c+V(0,0.13*math.cos(2*math.pi*k/n)*0.6,0.13*math.sin(2*math.pi*k/n)) for k in range(n)]
    b.sweep(P+[P[0]],0.006,3,'tank_alu',cap0=False,cap1=False)
    _q(b,P,'net',(-1,0,0)); _q(b,P[::-1],'net',(1,0,0))
    frontq(b,-0.20,0.20,-W/2-0.0008,0.08,0.24,'bait_sign' if not hi else 'bait_blu')
    text(b,hi,'LIVE BAIT',0.05,(0,-W/2-0.0018,0.16),'paint_white')
    badge(b,L/2-0.12,-W/2-0.001,0.40)
    b.cbox((0.019,0.078,0),(L+0.12,W+0.10,zt+0.10)); b.cbox((-L/2-0.04+0.019,-0.05+0.078,0),(0.06,0.30,1.46))

# ------------------------------------------------------------------ registry
_C=dict(dir='props/indoor/gymx',pdir='indoor_gymx',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=32,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
W_=dict(cage=0.04,ray=0.12)
PROPS=[
    _p('dumbbell_rack',dumbbell_rack,'medium',1200),
    _p('rowing_machine',rowing_machine,'medium',800),
    _p('treadmill',treadmill,'medium',1000),
    _p('bike_repair_stand',bike_repair_stand,'medium',1200,shift=(-0.20,-0.312)),
    _p('dive_tank_rack',dive_tank_rack,'medium',1200),
    _p('rod_rack',rod_rack,'medium',1000),
    _p('bait_tank',bait_tank,'medium',800,shift=(-0.019,-0.078)),
]
INDOOR_LOOK=True
