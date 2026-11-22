"""Indoor service-shop props (shop-gap batch 4, module b_insvcshop) — original geometry, page I, near+col only.
Shared page-I trims + per-key vertex tint (one material per prop); small (64 px) unique bake slots only for
print and badges. Wall props: centred on the origin, back on +Y (viewer at -Y).
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math, random
from mathutils import Vector
from b_inshared import sg
from b_infoodsvc import TR as _TR, TINT as _TINT, _q, V, ring_pts, nfaces, xform, counter, frontq, topq, text, flat_prism

TR=dict(_TR); TINT=dict(_TINT)
_NEW={
 'pole_red':('ti_paint',(0.80,0.06,0.06)), 'pole_blu':('ti_paint',(0.10,0.22,0.70)), 'bag_clr':('ti_glass',(0.95,0.97,1.00)),
 'safe_gry':('ti_metal',(0.38,0.40,0.42)), 'leather_blk':('ti_fabric',(0.08,0.08,0.09)), 'leather_crm':('ti_fabric',(1.00,0.92,0.80)),
 'basin_wht':('ti_paint',(1.05,1.05,1.04)), 'water':('ti_glass',(0.45,0.70,0.85)), 'po_brass':('ti_brass',(1.00,0.80,0.45)),
 'grille':('ti_metal',(0.60,0.62,0.64)), 'paper':('ti_paint',(1.08,1.07,1.02)), 'copier_gry':('ti_plastic',(0.80,0.80,0.79)),
 'canvas':('ti_fabric',(0.85,0.82,0.72)), 'mint':('ti_paint',(0.55,0.85,0.75)), 'bp_red':('ti_plastic',(0.75,0.10,0.10)),
}
for k,(t,c) in _NEW.items(): TR[k]=(t,(0.875,0.875)); TINT[k]=c
SL=['sl_%d'%i for i in range(8)]; TS=['ts_%d'%i for i in range(8)]

def caster(b, x, y, hi, r=0.035):
    b.box((x,y,r*2),(0.03,0.03,0.025),'steel_dk',ch=0)
    b.tube((x-0.012,y,r),(x+0.012,y,r),r,r,sg(hi,6,10),'rubber',cap0=True,cap1=True)
def badge(b, x, y, z, rz=0.0):
    b.box((x,y,z),(0.08,0.002,0.025),'badge',rz=rz,ch=0)

# ------------------------------------------------------------------ garment_conveyor
def garment(b, x, y, zt, key, hi, bag=True):
    """bagged garment hanging side-on (thin in x): hanger hook, shoulders, body; clear bag skin over it"""
    b.tube((x,y,zt),(x,y,zt+0.05),0.003,0.003,3,'chrome',cap0=False,cap1=False)
    S=[(-0.03,-0.02),(0.03,-0.02),(0.20,-0.08),(0.22,-0.95),(-0.22,-0.95),(-0.20,-0.08)]
    pts=[(y+u,zt+v) for u,v in S]
    B=[(y-0.225,zt-0.95),(y+0.225,zt-0.95),(y+0.225,zt-1.03),(y-0.225,zt-1.03)]
    for sx,nn in ((-1,(-1,0,0)),(1,(1,0,0))):
        xx=x+sx*0.012
        _q(b,[V(xx,p[0],p[1]) for p in (pts if sx<0 else pts[::-1])],key,nn)
        if bag: _q(b,[V(xx,p[0],p[1]) for p in (B if sx<0 else B[::-1])],'bag_clr',nn)
        if hi: _q(b,[V(xx+sx*0.001,y-0.012,zt-0.10),V(xx+sx*0.001,y+0.012,zt-0.10),V(xx+sx*0.001,y+0.012,zt-0.60),V(xx+sx*0.001,y-0.012,zt-0.60)][::(1 if sx<0 else -1)],'paper',nn)
    _q(b,[V(x-0.012,y-0.20,zt-0.08),V(x+0.012,y-0.20,zt-0.08),V(x+0.012,y+0.20,zt-0.08),V(x-0.012,y+0.20,zt-0.08)],key,(0,0,1))
def garment_conveyor(b, hi=False):
    """dry-cleaner garment conveyor: steel A-frame stands carrying an oval chrome rail loop at 1.9 m, bagged
    shirts, suits and dresses on wire hangers with paper ticket tags, a foot-pedal control box."""
    L,W,Z=2.20,0.62,1.90
    for sx in (-1,1):
        x=sx*(L/2-0.12)
        b.box((x,0,0),(0.08,W+0.10,0.04),'steel_dk')
        b.tube((x,0,0.04),(x,0,Z+0.06),0.025,0.025,sg(hi,6,10),'steel_dk',cap0=False,cap1=True)
        b.box((x,0,Z),(0.05,W,0.04),'steel_dk')
    n=sg(hi,6,12); P=[]
    for sx in (1,-1):
        for i in range(n+1):
            a=-math.pi/2+math.pi*i/n if sx>0 else math.pi/2+math.pi*i/n
            P.append(V(sx*(L/2-W/2)+W/2*math.cos(a),W/2*math.sin(a),Z))
    P.append(P[0])
    b.sweep(P,0.014,sg(hi,5,8),'chrome',cap0=False,cap1=False)
    keys=['ts_2','ts_3','denim','ts_1','ts_2','ts_6','ts_3','ts_0','ts_2','denim','ts_5','ts_3']
    i=0
    for sy in (-1,1):
        for k in range(6):
            x=-L/2+W/2+0.08+k*(L-W-0.16)/5
            garment(b,x,sy*W/2,Z-0.02,keys[i%12],hi); i+=1
            if hi or k%2==0: b.box((x,sy*W/2+0.0,Z-0.42),(0.03,0.06,0.04),'paper',ch=0)
    b.box((L/2-0.05,-W/2-0.12,0),(0.18,0.14,0.10),'mint')
    b.box((L/2-0.05,-W/2-0.12,0.10),(0.14,0.10,0.02),'rubber',ch=0)
    badge(b,-L/2+0.12,-W/2-0.051,0.012)
    b.cbox((0,0,0),(L,W+0.12,Z+0.08))

# ------------------------------------------------------------------ barber_pole
def barber_pole(b, hi=False):
    """wall barber pole: chrome dome cap and base cup, glass cylinder with red / white / blue helical stripes,
    wall bracket plates."""
    yb=0.12; R=0.075; z0=1.55; h=0.55; y=yb-0.11
    for zz in (z0-0.02,z0+h+0.02): b.box((0,yb-0.02,zz-0.04),(0.06,0.04,0.08),'chrome')
    for zz in (z0-0.01,z0+h+0.01): b.box((0,(yb-0.04+y)/2,zz-0.01),(0.02,yb-0.04-y,0.02),'chrome')
    n=sg(hi,10,20)
    # sheared cylinder grid: each ring is rotated along the helix, so face columns ARE the stripes
    turns=1.6; nr=12 if not hi else 24; nz=sg(hi,10,24); pat=['pole_red','pole_red','paint_white','pole_blu','pole_blu','paint_white']
    if hi: pat=[k for k in pat for _ in (0,1)]
    def Pt(i,j): a=2*math.pi*i/nr+2*math.pi*turns*j/nz; return V(R*math.cos(a),y+R*math.sin(a),z0+h*j/nz)
    for j in range(nz):
        for i in range(nr):
            a=2*math.pi*(i+0.5)/nr+2*math.pi*turns*(j+0.5)/nz
            _q(b,[Pt(i,j),Pt(i+1,j),Pt(i+1,j+1),Pt(i,j+1)],pat[i%len(pat)],(math.cos(a),math.sin(a),0))
    b.lathe([(R+0.012,0.0),(R+0.012,0.03),(R*0.7,0.08),(0.0,0.10)],n,'chrome',c=(0,y,z0+h),cap_top=False,cap_bot=True)
    b.lathe([(0.0,-0.10),(R*0.7,-0.08),(R+0.012,-0.03),(R+0.012,0.0)],n,'chrome',c=(0,y,z0),cap_top=True,cap_bot=False)
    badge(b,0,yb-0.0405,z0-0.04)
    b.cbox((0,(y+yb)/2-0.065,z0-0.10),(2*R+0.03,yb-y+R,h+0.20))

# ------------------------------------------------------------------ change_machine
def change_machine(b, hi=False):
    """laundromat bill changer: heavy brushed-steel cabinet, illuminated header 'CHANGE', bill acceptor bezel,
    coin cup with chrome hood, instruction label, keyed service lock, bolted to a plinth."""
    W,D,H=0.48,0.36,1.45
    b.box((0,0,0),(W+0.04,D+0.04,0.08),'paint_black')
    b.box((0,0,0.08),(W,D,H-0.08),'ss')
    b.box((0,-0.01,H-0.24),(W+0.01,D,0.22),'paint_navy')
    frontq(b,-0.20,0.20,-D/2-0.0118,H-0.21,H-0.05,'chg_sign' if not hi else 'paint_navy')
    text(b,hi,'CHANGE',0.08,(0,-D/2-0.013,H-0.13),'sugar_yl')
    frontq(b,-W/2+0.03,W/2-0.03,-D/2-0.0008,0.10,H-0.27,'ss_dk')
    b.box((0,-D/2-0.03,0.98),(0.22,0.06,0.10),'tv_blk')                                   # bill bezel
    frontq(b,-0.08,0.08,-D/2-0.0605,1.02,1.035,'lemon')
    frontq(b,-0.10,0.10,-D/2-0.0010,0.78,0.94,'label')
    b.box((0,-D/2-0.07,0.42),(0.20,0.14,0.02),'ss')                                       # coin cup
    for sx in (-1,1): b.box((sx*0.10,-D/2-0.07,0.42),(0.01,0.14,0.10),'ss',ch=0)
    b.box((0,-D/2-0.14,0.42),(0.20,0.01,0.06),'ss',ch=0)
    b.box((0,-D/2-0.06,0.52),(0.20,0.12,0.04),'chrome',rx=-0.25)
    b.tube((0.15,-D/2,0.66),(0.15,-D/2-0.012,0.66),0.016,0.016,sg(hi,6,10),'brass',cap0=False,cap1=True)
    badge(b,-0.15,-D/2-0.002,0.15)
    b.cbox((0,-0.062,0),(W+0.04,D+0.07,H))

# ------------------------------------------------------------------ laundry_cart
def laundry_cart(b, hi=False):
    """laundromat wire cart: chrome wire basket on four casters, hanging bar on two uprights, bottom shelf,
    a folded towel and a detergent jug in the basket."""
    L,W=0.70,0.48; zb,zt=0.42,0.72
    for sx in (-1,1):
        for sy in (-1,1):
            x,y=sx*(L/2-0.03),sy*(W/2-0.03)
            b.tube((x,y,0.10),(x,y,zt),0.010,0.010,sg(hi,5,8),'chrome',cap0=False,cap1=False); caster(b,x,y,hi)
    for z in (zb,zt,0.16):
        P=[V(-L/2,-W/2,z),V(L/2,-W/2,z),V(L/2,W/2,z),V(-L/2,W/2,z),V(-L/2,-W/2,z)]
        b.sweep(P,0.007,sg(hi,4,6),'chrome',cap0=False,cap1=False)
    for i in range(1,9):
        x=-L/2+i*L/9
        for sy in (-1,1): b.tube((x,sy*W/2,zb),(x,sy*W/2,zt),0.0028,0.0028,3,'chrome',cap0=False,cap1=False)
    for i in range(1,6):
        y=-W/2+i*W/6
        for sx in (-1,1): b.tube((sx*L/2,y,zb),(sx*L/2,y,zt),0.0028,0.0028,3,'chrome',cap0=False,cap1=False)
    topq(b,-L/2,L/2,-W/2,W/2,zb,'grille'); topq(b,-L/2,L/2,-W/2,W/2,0.16,'grille')
    for sx in (-1,1): b.tube((sx*(L/2-0.03),0,zt),(sx*(L/2-0.03),0,1.62),0.012,0.012,sg(hi,6,8),'chrome',cap0=False,cap1=False)
    b.tube((-L/2+0.03,0,1.62),(L/2-0.03,0,1.62),0.012,0.012,sg(hi,6,8),'chrome',cap0=True,cap1=True)
    for i in range(3 if not hi else 4): b.tube((-0.15+i*0.10,0,1.62),(-0.15+i*0.10,0,1.66),0.003,0.003,3,'chrome',cap0=False,cap1=False)
    b.box((-0.12,0.0,zb),(0.30,0.24,0.10),'ts_1',ch=0)
    for k in range(3): frontq(b,-0.27,0.03,-0.1208,zb+0.02+k*0.03,zb+0.024+k*0.03,'paper')
    b.box((0.18,0.05,zb),(0.12,0.08,0.20),'sugar_bl'); b.tube((0.21,0.05,zb+0.20),(0.21,0.05,zb+0.23),0.018,0.018,6,'paint_white',cap0=False,cap1=True)
    frontq(b,0.14,0.22,0.0092,zb+0.05,zb+0.14,'label')
    badge(b,L/2-0.08,-W/2-0.0016,0.20)
    b.cbox((0,0,0),(L,W,1.64))

# ------------------------------------------------------------------ dispensary_counter_partition
def dispensary_counter_partition(b, hi=False):
    """cannabis-dispensary check-in counter: oak-slat front, quartz top, three framed acrylic partition panels
    with a pass-through slot, ID scanner tablet on a stand, small menu card holder."""
    L,D,H=1.60,0.60,1.05
    b.box((0,0.03,0),(L-0.06,D-0.06,0.10),'kick_blk',skip=('bottom',))
    b.box((0,0,0.10),(L,D,H-0.14),'paint_black')
    for i in range(int(L/0.06)):
        x=-L/2+0.03+i*0.06; b.box((x,-D/2-0.012,0.12),(0.04,0.024,H-0.18),'oak',ch=0 if not hi else None)
    b.box((0,0,H-0.04),(L+0.04,D+0.06,0.04),'paint_cream')
    for i in range(3):
        x=-L/2+L/6+i*L/3; w=L/3-0.02
        for sx in (-1,1): b.box((x+sx*w/2,0,H),(0.02,0.03,0.70),'paint_black')
        b.box((x,0,H+0.68),(w,0.03,0.02),'paint_black')
        frontq(b,x-w/2+0.01,x+w/2-0.01,-0.0005,H+0.12 if i==1 else H,H+0.68,'glass')
        if i==1: b.box((x,0,H),(w,0.03,0.02),'paint_black'); b.box((x,0,H+0.10),(w,0.03,0.02),'paint_black')
    b.box((0.45,-0.15,H),(0.10,0.10,0.01),'tv_blk')
    b.tube((0.45,-0.15,H+0.01),(0.45,-0.16,H+0.14),0.008,0.008,4,'tv_blk',cap0=False,cap1=False)
    b.box((0.45,-0.17,H+0.13),(0.20,0.02,0.14),'tv_blk',rx=-0.35); frontq(b,0.36,0.54,-0.183,H+0.145,H+0.25,'screen') if False else None
    nv=V(0,-math.cos(0.35),math.sin(0.35)); c=V(0.45,-0.181,H+0.20)
    _q(b,[c+V(-0.09,0,0)-V(0,math.sin(0.35)*0.055,-math.cos(0.35)*0.055)*-1,c+V(0.09,0,0)-V(0,math.sin(0.35)*0.055,-math.cos(0.35)*0.055)*-1,c+V(0.09,0,0)+V(0,math.sin(0.35)*0.055,-math.cos(0.35)*0.055)*-1,c+V(-0.09,0,0)+V(0,math.sin(0.35)*0.055,-math.cos(0.35)*0.055)*-1],'screen',tuple(nv))
    b.box((-0.50,-0.18,H),(0.12,0.06,0.01),'glass',ch=0); b.box((-0.50,-0.18,H+0.01),(0.10,0.01,0.14),'mint',rx=-0.2)
    badge(b,L/2-0.12,-D/2-0.0255,0.13)
    b.cbox((0,0,0),(L+0.04,D+0.06,H+0.70))

# ------------------------------------------------------------------ blood_pressure_kiosk
def blood_pressure_kiosk(b, hi=False):
    """pharmacy blood-pressure kiosk: moulded white seat with a wrap-around side tower, cuff tunnel in the
    armrest, touchscreen on the tower, red heart logo panel, privacy wing."""
    b.box((0,0.05,0),(0.70,0.80,0.06),'copier_gry')
    b.box((-0.08,0.10,0.06),(0.46,0.46,0.38),'basin_wht')                                    # seat base
    b.box((-0.08,0.08,0.44),(0.48,0.50,0.08),'paint_navy')                                   # cushion
    b.box((-0.08,0.36,0.44),(0.48,0.10,0.62),'basin_wht'); b.box((-0.08,0.30,0.54),(0.42,0.04,0.48),'paint_navy',rx=0.08)
    b.box((0.27,0.10,0.06),(0.22,0.70,1.40),'basin_wht')                                      # tower
    b.box((0.27,-0.02,0.62),(0.24,0.42,0.12),'basin_wht')                                     # armrest with cuff
    b.tube((0.27,-0.24,0.70),(0.27,0.14,0.70),0.055,0.055,sg(hi,8,14),'tv_grey',cap0=True,cap1=False)
    _q(b,ring_pts((0.27,-0.24),0.045,sg(hi,8,14),0.0)and[V(0.27+0.045*math.cos(2*math.pi*i/8),-0.2405,0.70+0.045*math.sin(2*math.pi*i/8)) for i in range(8)][::-1],'tv_blk',(0,-1,0))
    b.box((0.155,0.0,1.05),(0.02,0.36,0.26),'tv_blk',rz=0.0)
    _q(b,[(0.144,0.16,1.07),(0.144,-0.16,1.07),(0.144,-0.16,1.29),(0.144,0.16,1.29)],'screen',(-1,0,0))
    _q(b,[(0.1445,0.16,1.32),(0.1445,-0.16,1.32),(0.1445,-0.16,1.44),(0.1445,0.16,1.44)],'bp_sign' if not hi else 'paint_cream',(-1,0,0))
    text(b,hi,'BLOOD PRESSURE',0.035,(0.1435,0.0,1.38),'ceramic',xdir=(0,-1,0))
    b.box((0.27,-0.25,0.06),(0.22,0.002,1.20),'bp_red',ch=0)
    badge(b,-0.25,-0.3505,0.02)
    b.cbox((0.0,0.05,0),(0.76,0.80,1.46))

# ------------------------------------------------------------------ pedicure_chair
def pedicure_chair(b, hi=False):
    """spa pedicure throne: tiled platform with a white acrylic foot basin and chrome faucet, raised padded
    massage chair in cream leather with piped seams, curved armrests, side cup holder and remote."""
    b.box((0,0.10,0),(0.80,1.30,0.42),'paint_cream')
    for i in range(4):
        frontq(b,-0.40+i*0.20+0.004,-0.20+i*0.20-0.004,-0.5508,0.01,0.41,'walnut' if i%2 else 'lam_wd')
    # basin in front of the platform on the floor
    b.lathe([(0.20,0.0),(0.22,0.18),(0.24,0.20),(0.21,0.205)],sg(hi,10,18),'basin_wht',c=(0,-0.75,0),cap_top=False,cap_bot=False)
    _q(b,ring_pts((0,-0.75),0.205,sg(hi,10,18),0.15),'water',(0,0,1))
    b.tube((0,-0.55,0.30),(0,-0.62,0.32),0.012,0.010,6,'chrome',cap0=False,cap1=True)
    b.box((0,-0.53,0.26),(0.10,0.04,0.06),'chrome')
    b.box((0,-0.42,0.30),(0.34,0.16,0.04),'leather_crm',rx=0.4)                               # footrest
    # chair
    zs=0.42
    b.box((0,0.20,zs),(0.62,0.62,0.30),'paint_black')
    b.box((0,0.16,zs+0.30),(0.58,0.60,0.14),'leather_crm')
    for k in range(2): frontq(b,-0.28,0.28,-0.1408,zs+0.33+k*0.05,zs+0.335+k*0.05,'leather_br')
    b.box((0,0.48,zs+0.30),(0.60,0.18,0.80),'leather_crm',rx=0.18)
    for k in range(3):
        z=zs+0.50+k*0.20; b.box((0,0.36-k*0.035,z),(0.56,0.02,0.012),'leather_br',rx=0.18,ch=0)
    for sx in (-1,1):
        b.box((sx*0.35,0.18,zs+0.30),(0.10,0.62,0.22),'leather_crm')
        b.box((sx*0.35,0.18,zs+0.52),(0.12,0.66,0.05),'walnut')
    b.tube((0.40,-0.14,zs+0.57),(0.40,-0.14,zs+0.62),0.04,0.04,sg(hi,8,12),'chrome',cap0=True,cap1=False)
    b.box((-0.35,-0.05,zs+0.57),(0.04,0.10,0.015),'tv_blk',ch=0)
    badge(b,0.30,-0.5508,0.30)
    b.cbox((0.015,0.106,0),(0.82,1.30,1.45)); b.ccyl((0.015,-0.744,0),0.24,0.21)

# ------------------------------------------------------------------ bulletproof_teller_window
def bulletproof_teller_window(b, hi=False):
    """check-cashing teller position: laminate counter with a stainless deal tray sunk under thick framed
    ballistic glass, round speaker grille, document slot, steel kick plate and a small 'NEXT TELLER' card."""
    L,D,H=1.20,0.60,1.05
    counter(b,L,D,H,'paint_navy','paint_cream')
    frontq(b,-L/2+0.02,L/2-0.02,-D/2-0.0008,0.12,0.40,'ss')
    b.box((0,0.02,H),(L,0.10,0.06),'safe_gry')
    for sx in (-1,1): b.box((sx*(L/2-0.04),0.02,H),(0.08,0.10,1.20),'safe_gry')
    b.box((0,0.02,H+1.14),(L,0.10,0.06),'safe_gry')
    frontq(b,-L/2+0.08,L/2-0.08,-0.0305,H+0.06,H+1.14,'glass')
    frontq(b,-L/2+0.08,L/2-0.08,-0.0300,H+0.06,H+1.14,'glass',(0,1,0)) if False else None
    c=V(0,-0.031,H+0.55); n=sg(hi,10,16)
    _q(b,[c+V(0.07*math.cos(2*math.pi*i/n),0,0.07*math.sin(2*math.pi*i/n)) for i in range(n)],'ss',(0,-1,0))
    for k in range(-2,3) if hi else range(-1,2):
        frontq(b,-0.05,0.05,-0.0318,H+0.55+k*0.022-0.004,H+0.55+k*0.022+0.004,'ss_dk')
    b.box((0,-0.14,H-0.02),(0.36,0.30,0.022),'ss')                                          # deal tray
    topq(b,-0.16,0.16,-0.28,0.0,H+0.003,'ss_dk')
    frontq(b,-0.15,0.15,-0.0308,H+0.08,H+0.10,'kick_blk')                                   # slot
    b.box((0.40,-0.20,H),(0.20,0.06,0.10),'paper',rx=-0.3)
    frontq(b,0.31,0.49,-0.2312,H+0.02,H+0.09,'teller_sign' if not hi else 'paper')
    text(b,hi,'NEXT TELLER',0.022,(0.40,-0.2322,H+0.055),'paint_black')
    badge(b,L/2-0.12,-D/2-0.0118,0.06)
    b.cbox((0,0,0),(L+0.02,D+0.02,H+1.20))

# ------------------------------------------------------------------ wall_safe
def wall_safe(b, hi=False):
    """in-wall safe (pawn / jewellery back office): heavy steel door in a recessed frame, combination dial with
    numbered ring, three-spoke handle, concealed hinge pins, keypad, brass maker plate."""
    yb=0.04; W,Hh=0.50,0.60; z0=0.90
    b.box((0,yb-0.02,z0),(W+0.08,0.04,Hh+0.08),'safe_gry')
    b.box((0,yb-0.04,z0+0.04),(W,0.03,Hh),'safe_gry')
    yf=yb-0.07
    frontq(b,-W/2+0.01,W/2-0.01,yf-0.0008,z0+0.05,z0+Hh+0.03,'steel_dk')
    frontq(b,-W/2+0.03,W/2-0.03,yf-0.0016,z0+0.07,z0+Hh+0.01,'safe_gry')
    n=sg(hi,12,24); dc=V(-0.06,yf,z0+0.40)
    b.tube(dc,dc+V(0,-0.03,0),0.07,0.065,n,'chrome',cap0=False,cap1=True)
    _q(b,[dc+V(0.05*math.cos(2*math.pi*i/n),-0.0315,0.05*math.sin(2*math.pi*i/n)) for i in range(n)],'paint_black',(0,-1,0))
    b.box((dc.x,yf-0.032,dc.z+0.066),(0.006,0.002,0.012),'paint_white',ch=0)
    hc=V(0.12,yf,z0+0.25)
    b.tube(hc,hc+V(0,-0.05,0),0.025,0.025,sg(hi,8,12),'chrome',cap0=False,cap1=True)
    for k in range(3):
        a=math.pi/2+k*2*math.pi/3; e=hc+V(0.10*math.cos(a),-0.045,0.10*math.sin(a))
        b.tube(hc+V(0,-0.045,0),e,0.010,0.010,sg(hi,5,8),'chrome',cap0=False,cap1=False)
        b.tube(e,e+V(0,-0.005,0),0.016,0.016,sg(hi,6,8),'paint_black',cap0=False,cap1=True)
    for zz in (z0+0.12,z0+Hh-0.06): b.tube((-W/2+0.02,yf-0.01,zz),(-W/2+0.02,yf-0.01,zz+0.06),0.012,0.012,sg(hi,6,8),'chrome',cap0=True,cap1=True)
    b.box((0.13,yf-0.006,z0+0.45),(0.10,0.012,0.12),'tv_blk'); frontq(b,0.095,0.165,yf-0.0125,z0+0.48,z0+0.55,'keypad')
    b.box((0,yf-0.0025,z0+0.10),(0.10,0.003,0.03),'badge',ch=0)
    b.cbox((0,(yb+yf)/2,z0),(W+0.08,yb-yf+0.06,Hh+0.08))

# ------------------------------------------------------------------ security_grille_counter
def security_grille_counter(b, hi=False):
    """liquor / check-cashing counter with a steel security grille: laminate counter, folding scissor grille
    across the front pulled half closed, overhead track box, padlock hasp, rubber mat on top."""
    L,D,H=1.40,0.60,1.00
    counter(b,L,D,H,'red_lam','paint_cream')
    b.box((0,0,H),(0.50,0.36,0.005),'rubber',ch=0)
    zt=2.10
    for sx in (-1,1): b.box((sx*(L/2+0.02),-D/2-0.06,0),(0.05,0.06,zt),'grille')
    b.box((0,-D/2-0.06,zt-0.12),(L+0.10,0.12,0.12),'grille')
    # scissor grille: pulled across half the width, diamond lattice
    x0,x1=-L/2,0.15; nd=sg(hi,6,10); y=-D/2-0.06
    for i in range(nd+1):
        x=x0+(x1-x0)*i/nd
        b.box((x,y,H+0.02),(0.02,0.02,zt-H-0.14),'grille',ch=0)
    for i in range(nd):
        xa=x0+(x1-x0)*i/nd; xb=x0+(x1-x0)*(i+1)/nd
        for k in range(4):
            za=H+0.04+k*0.24; zb=za+0.24
            for (p,q) in (((xa,za),(xb,zb)),((xa,zb),(xb,za))):
                d=V(q[0]-p[0],0,q[1]-p[1]); nn=V(-d.z,0,d.x).normalized()*0.006
                _q(b,[V(p[0],y-0.012,p[1])-nn,V(q[0],y-0.012,q[1])-nn,V(q[0],y-0.012,q[1])+nn,V(p[0],y-0.012,p[1])+nn],'grille',(0,-1,0))
    for zz in (H+0.02,zt-0.14): b.box(((x0+x1)/2,y,zz),(x1-x0,0.03,0.02),'grille',ch=0)
    b.box((x1+0.02,y-0.02,H+0.50),(0.03,0.02,0.10),'brass',ch=0)
    b.box((L/2-0.08,-D/2-0.02,0.80),(0.10,0.04,0.12),'safe_gry') if False else None
    badge(b,L/2-0.12,-D/2-0.0118,0.06)
    b.cbox((0,-0.04,0),(L+0.12,D+0.10,zt))

# ------------------------------------------------------------------ tattoo_bed_chair
def tattoo_bed_chair(b, hi=False):
    """tattoo studio bed: black hydraulic pedestal with chrome column, upholstered three-section bed (back
    raised), face hole headrest, padded arm rests, rolling stainless tray stand with ink caps and a wrapped
    machine."""
    b.box((0,0,0),(0.60,0.50,0.04),'paint_black')
    b.tube((0,0,0.04),(0,0,0.45),0.07,0.07,sg(hi,8,14),'chrome',cap0=False,cap1=False)
    b.box((0,0,0.45),(0.46,0.40,0.06),'paint_black')
    b.box((-0.10,0,0.52),(0.70,0.62,0.10),'leather_blk')                                   # seat
    b.box((0.45,0,0.48),(0.42,0.56,0.09),'leather_blk',rx=0.0)                              # leg rest (lowered)
    import mathutils
    n0=nfaces(b)
    b.box((-0.31,0,0),(0.62,0.62,0.09),'leather_blk')
    xform(b,n0,lambda co: mathutils.Matrix.Rotation(0.55,3,'Y')@co+V(-0.43,0,0.55))         # back section raised
    for k in range(3):                                                                    # tufting seams
        _q(b,[(-0.42+k*0.22,-0.31,0.6205),(-0.40+k*0.22,-0.31,0.6205),(-0.40+k*0.22,0.31,0.6205),(-0.42+k*0.22,0.31,0.6205)],'tv_grey',(0,0,1)) if k else None
    for sy in (-1,1):
        b.box((-0.10,sy*0.40,0.58),(0.50,0.12,0.06),'leather_blk')
        b.tube((-0.10,sy*0.34,0.52),(-0.10,sy*0.40,0.58),0.012,0.012,6,'chrome',cap0=False,cap1=False)
    # tray stand
    tx,ty=0.30,-0.62
    b.box((tx,ty,0),(0.36,0.36,0.03),'steel_dk')
    b.tube((tx,ty,0.03),(tx,ty,0.85),0.015,0.015,sg(hi,6,8),'chrome',cap0=False,cap1=False)
    b.box((tx,ty,0.85),(0.40,0.30,0.02),'ss')
    for i,k in enumerate(('pole_red','paint_black','pole_blu','sugar_yl','glaze_choc','lime')):
        b.tube((tx-0.12+i*0.04,ty-0.08,0.87),(tx-0.12+i*0.04,ty-0.08,0.885),0.012,0.012,sg(hi,5,8),k,cap0=False,cap1=True)
    b.box((tx+0.08,ty+0.05,0.87),(0.12,0.05,0.04),'mint',rz=0.4)
    b.box((tx-0.05,ty+0.06,0.87),(0.14,0.08,0.03),'paper',ch=0)
    badge(b,0.0,-0.2512,0.01)
    b.cbox((-0.148,0.005,0),(1.40,0.90,1.00)); b.cbox((tx-0.098,ty+0.005,0),(0.40,0.36,0.88))

# ------------------------------------------------------------------ flash_art_wall
def flash_art_wall(b, hi=False):
    """tattoo flash wall: plum painted panel with a grid of 4 x 3 framed flash sheets (black frames, cream
    paper, bold colour motifs: roses, swallows, daggers, hearts), a small shelf with portfolio binders below."""
    W,H=1.40,1.10; yb=0.04; z0=1.00
    b.box((0,yb-0.01,z0),(W,0.02,H),'paint_purple')
    R=random.Random(13)
    for r in range(3):
        for c in range(4):
            x=-W/2+0.18+c*0.347; z=z0+0.07+r*0.34; w,h=0.28,0.30
            b.box((x,yb-0.03,z),(w,0.02,h),'paint_black',ch=0)
            frontq(b,x-w/2+0.02,x+w/2-0.02,yb-0.0405,z+0.02,z+h-0.02,'paper')
            # motifs: bold old-school flash shapes (heart+banner, rose, dagger, star, swallow)
            yy=yb-0.0412
            def P(pts,k,dy=0.0): _q(b,[V(px,yy-dy,pz) for px,pz in pts],k,(0,-1,0))
            for m in range(2):
                cx=x+(-0.06 if m==0 else 0.06); cz=z+(0.19 if m==0 else 0.10)+R.uniform(-0.02,0.02); s=0.055
                t=(r*4+c+m*3)%5
                if t==0:   # heart + banner
                    hp=[(cx+s*16*math.sin(a)**3/17,cz+s*(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/17) for a in [2*math.pi*i/(12 if hi else 8) for i in range(12 if hi else 8)]]
                    P(hp[::-1],'pole_red'); P([(cx-s*1.2,cz-0.012),(cx+s*1.2,cz-0.012),(cx+s*1.2,cz+0.012),(cx-s*1.2,cz+0.012)],'sugar_yl',0.0005)
                elif t==1: # rose
                    P([(cx+s*0.8*math.cos(2*math.pi*i/8),cz+s*0.8*math.sin(2*math.pi*i/8)) for i in range(8)],'pole_red')
                    P([(cx+s*0.35*math.cos(2*math.pi*i/6+0.5),cz+s*0.35*math.sin(2*math.pi*i/6+0.5)) for i in range(6)],'paint_black',0.0005)
                    P([(cx-s*0.2,cz-s*0.7),(cx-s*1.3,cz-s*1.1),(cx-s*0.5,cz-s*0.4)],'lime')
                elif t==2: # dagger
                    P([(cx-s*0.12,cz-s*1.2),(cx,cz-s*1.7),(cx+s*0.12,cz-s*1.2),(cx+s*0.12,cz+s*0.6),(cx-s*0.12,cz+s*0.6)][::-1],'ss')
                    P([(cx-s*0.5,cz+s*0.6),(cx+s*0.5,cz+s*0.6),(cx+s*0.5,cz+s*0.75),(cx-s*0.5,cz+s*0.75)],'paint_black',0.0005)
                    P([(cx-s*0.1,cz+s*0.75),(cx+s*0.1,cz+s*0.75),(cx+s*0.1,cz+s*1.2),(cx-s*0.1,cz+s*1.2)],'pole_red',0.0005)
                elif t==3: # star
                    P([(cx+s*(0.9 if i%2==0 else 0.4)*math.cos(math.pi/2+math.pi*i/5),cz+s*(0.9 if i%2==0 else 0.4)*math.sin(math.pi/2+math.pi*i/5)) for i in range(10)],'pole_blu' if (r+c)%2 else 'sugar_yl')
                else:      # swallow
                    P([(cx-s*1.2,cz+s*0.5),(cx,cz-s*0.2),(cx+s*1.2,cz+s*0.5),(cx+s*0.5,cz-s*0.4),(cx,cz-s*0.6),(cx-s*0.5,cz-s*0.4)][::-1],'pole_blu')
                    P([(cx-s*0.25,cz-s*0.45),(cx+s*0.25,cz-s*0.45),(cx+s*0.25,cz-s*0.15),(cx-s*0.25,cz-s*0.15)],'pole_red',0.0005)
    b.box((0,yb-0.10,z0-0.10),(W-0.20,0.20,0.025),'walnut')
    for i in range(5): b.box((-0.40+i*0.06,yb-0.10,z0-0.075),(0.04,0.18,0.24),('paint_black','pole_red','paint_black','mint','paint_black')[i],ch=0)
    badge(b,W/2-0.10,yb-0.0215,z0+0.02)
    b.cbox((0,yb-0.10,z0-0.10),(W,0.20,H+0.10))

# ------------------------------------------------------------------ hood_dryer_chair
def hood_dryer_chair(b, hi=False):
    """salon hood dryer chair: chrome sled-base chair in black vinyl with channel stitching, hood dryer on an
    adjustable column behind it (domed white hood with vent slots, timer dial), magazine pocket."""
    b.box((0,0,0),(0.56,0.62,0.02),'chrome') if False else None
    for sx in (-1,1):
        b.sweep([V(sx*0.25,-0.30,0.01),V(sx*0.25,0.28,0.01),V(sx*0.25,0.30,0.40)],0.012,sg(hi,5,8),'chrome',cap0=True,cap1=True)
        b.tube((sx*0.25,-0.26,0.01),(sx*0.25,-0.22,0.40),0.012,0.012,sg(hi,5,8),'chrome',cap0=False,cap1=False)
    b.box((0,0.0,0.40),(0.56,0.56,0.12),'leather_blk')
    b.box((0,0.30,0.50),(0.56,0.12,0.50),'leather_blk',rx=0.15)
    for k in range(3 if hi else 2): b.box((-0.14+k*(0.28/(2 if hi else 1)),0.235,0.56),(0.006,0.002,0.42),'tv_grey',rx=0.15,ch=0)
    for sx in (-1,1): b.box((sx*0.30,0.02,0.52),(0.08,0.50,0.14),'leather_blk')
    # dryer column + hood
    b.box((0,0.48,0),(0.36,0.36,0.03),'chrome')
    b.tube((0,0.48,0.03),(0,0.48,1.10),0.025,0.025,sg(hi,6,10),'chrome',cap0=False,cap1=False)
    b.tube((0,0.48,1.10),(0,0.26,1.22),0.02,0.02,sg(hi,6,8),'chrome',cap0=False,cap1=False)
    hc=V(0,0.11,1.08); n=sg(hi,14,20)
    n0=nfaces(b)
    b.lathe([(0.20,0.0),(0.22,0.06),(0.21,0.18),(0.16,0.27),(0.06,0.32),(0.0,0.33)],n,'basin_wht',c=(0,0,0),cap_top=False,cap_bot=False)
    b.lathe([(0.0,0.0),(0.195,0.002)],n,'tv_grey',c=(0,0,0),cap_top=False,cap_bot=False)
    import mathutils
    M=mathutils.Matrix.Rotation(-0.6,3,'X')
    xform(b,n0,lambda co: M@co+hc)
    tc=hc+M@V(0,0.20,0.20)
    b.tube(tc,tc+V(0,0.03,0.0),0.03,0.03,sg(hi,6,10),'tv_blk',cap0=False,cap1=True)
    b.box((0,-0.29,0.20),(0.30,0.02,0.16),'leather_blk') if False else None
    badge(b,0.0,0.30-0.0011,0.04) if False else b.box((0,0.48-0.181,0.005),(0.08,0.002,0.02),'badge',ch=0)
    b.cbox((0,0.18,0),(0.68,0.80,1.45))

# ------------------------------------------------------------------ po_box_wall
def po_box_wall(b, hi=False):
    """post-office box wall: walnut surround, grid of 8 x 6 cast-brass PO box doors (two sizes), each with a
    glass eagle window, number plate and dial/keyhole, kick panel."""
    W,H=1.30,1.30; yb=0.10; z0=0.55
    b.box((0,yb-0.05,z0-0.05),(W+0.10,0.10,H+0.10),'walnut')
    b.box((0,yb-0.05,0),(W+0.10,0.10,z0-0.05),'walnut_dk')
    yf=yb-0.1008
    cols,rows=8,6; cw=W/cols; rh=(H-0.20)/rows
    for r in range(rows+1):
        big=(r==rows)
        for c in range(cols if not big else 4):
            w=cw if not big else W/4; x=-W/2+w/2+c*w; z=z0+(r*rh if not big else rows*rh); h=rh if not big else 0.20
            frontq(b,x-w/2+0.004,x+w/2-0.004,yf,z+0.004,z+h-0.004,'po_brass')
            frontq(b,x-w*0.28,x+w*0.28,yf-0.0006,z+h*0.45,z+h*0.85,'tv_blk')                    # window
            frontq(b,x-w*0.16,x+w*0.16,yf-0.0006,z+h*0.12,z+h*0.28,'brass')                     # number plate
            if hi or (r+c)%2==0: b.tube((x+w*0.32,yf,z+h*0.25),(x+w*0.32,yf-0.006,z+h*0.25),0.007,0.007,sg(hi,5,8),'brass',cap0=False,cap1=True)
    badge(b,W/2-0.08,yb-0.1012,0.10)
    b.cbox((0,yb-0.05,0),(W+0.10,0.10,H+z0+0.05))

# ------------------------------------------------------------------ parcel_scale
def parcel_scale(b, hi=False):
    """shipping-counter parcel scale: low steel base with a textured stainless platform, coiled cable to a
    tilted display head on a short pole, a small boxed parcel with label on the platform."""
    b.box((0,0,0),(0.40,0.40,0.06),'tv_grey')
    b.box((0,0,0.06),(0.38,0.38,0.012),'ss')
    for i in range(5 if hi else 3): topq(b,-0.17,0.17,-0.17+i*(0.34/(4 if hi else 2))-0.003,-0.17+i*(0.34/(4 if hi else 2))+0.003,0.0725,'ss_dk')
    b.tube((0,0.18,0.06),(0,0.18,0.36),0.012,0.012,sg(hi,6,8),'tv_grey',cap0=False,cap1=False)
    b.box((0,0.16,0.36),(0.20,0.05,0.10),'tv_grey',rx=-0.3)
    nv=V(0,-math.cos(0.3),math.sin(0.3)); c=V(0,0.1345,0.415)
    up=V(0,math.sin(0.3),math.cos(0.3))
    _q(b,[c-V(0.08,0,0)-up*0.03,c+V(0.08,0,0)-up*0.03,c+V(0.08,0,0)+up*0.03,c-V(0.08,0,0)+up*0.03],'screen',tuple(nv))
    b.box((0.02,-0.02,0.072),(0.22,0.16,0.14),'kraft')
    frontq(b,-0.06,0.08,-0.1008,0.10,0.18,'label')
    b.box((0.02,-0.02,0.212),(0.04,0.161,0.001),'paper',ch=0)
    badge(b,0.10,-0.2011,0.02)
    b.cbox((0,0,0),(0.40,0.40,0.47))

# ------------------------------------------------------------------ copier_large_format_printer
def copier_large_format_printer(b, hi=False):
    """print-shop wide-format printer: 1.5 m long printer body on a black stand with castors, media roll
    visible under the clear cover, control panel screen, ink bay doors, fabric output basket with a print
    curling into it."""
    L=1.55
    for sx in (-1,1):
        b.box((sx*(L/2-0.08),0,0.07),(0.06,0.50,0.03),'paint_black')
        b.box((sx*(L/2-0.08),0,0.10),(0.05,0.05,0.80),'paint_black')
        for sy in (-1,1): caster(b,sx*(L/2-0.08),sy*0.22,hi,0.03)
    b.tube((-L/2+0.08,0,0.30),(L/2-0.08,0,0.30),0.015,0.015,sg(hi,5,8),'paint_black',cap0=False,cap1=False)
    b.box((0,0.02,0.90),(L,0.48,0.26),'copier_gry')
    b.box((0,0.06,1.16),(L-0.10,0.36,0.10),'paint_black',ch=0)
    b.box((0,-0.10,1.12),(L-0.24,0.18,0.10),'glass',rx=0.4)
    b.tube((-L/2+0.18,-0.06,1.10),(L/2-0.18,-0.06,1.10),0.045,0.045,sg(hi,8,14),'paper',cap0=True,cap1=True)
    for sx in (-1,1): b.box((sx*(L/2-0.08),0.02,0.90),(0.16,0.50,0.30),'paint_black')
    b.box((L/2-0.08,-0.20,1.05),(0.14,0.06,0.10),'tv_blk',rx=-0.5); frontq(b,L/2-0.13,L/2-0.03,-0.2335,1.07,1.12,'screen')
    for i in range(4): frontq(b,-L/2+0.25+i*0.10,-L/2+0.33+i*0.10,-0.2208,0.93,1.07,('pole_blu','pole_red','sugar_yl','paint_black')[i])
    frontq(b,-L/2+0.20,-L/2+0.66,-0.2212,0.92,1.08,'copier_gry') if False else None
    # output basket + curling print
    for sx in (-1,1): b.tube((sx*(L/2-0.12),-0.10,0.40),(sx*(L/2-0.12),-0.40,0.40),0.008,0.008,4,'paint_black',cap0=False,cap1=True)
    P=[V(-L/2+0.14,-0.08,0.90),V(L/2-0.14,-0.08,0.90),V(L/2-0.14,-0.38,0.42),V(-L/2+0.14,-0.38,0.42)]
    _q(b,P,'canvas',(0,-0.85,0.5))
    n=sg(hi,4,8); prev=None
    for i in range(n+1):
        t=i/n; a=math.pi*0.9*t; y=-0.20-0.12*math.sin(a); z=0.88-0.30*t+0.06*math.cos(a)
        cur=(V(-0.45,y,z),V(0.45,y,z))
        if prev:
            nn=((prev[1]-prev[0]).cross(cur[0]-prev[0])).normalized()
            _q(b,[prev[1],prev[0],cur[0],cur[1]],'paper',tuple(-nn))
        prev=cur
    badge(b,-L/2+0.25,-0.2208,1.09)
    b.cbox((0,-0.065,0),(L,0.64,1.26))

# ------------------------------------------------------------------ registry
_C=dict(dir='props/indoor/svcshop',pdir='indoor_svcshop',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=64,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
W_=dict(cage=0.04,ray=0.12)
PROPS=[
    _p('garment_conveyor',garment_conveyor,'large',1500),
    _p('barber_pole',barber_pole,'small',500,mount='wall',**W_),
    _p('change_machine',change_machine,'medium',600,shift=(0.0,0.062),**W_),
    _p('laundry_cart',laundry_cart,'small',600),
    _p('dispensary_counter_partition',dispensary_counter_partition,'medium',1000,**W_),
    _p('blood_pressure_kiosk',blood_pressure_kiosk,'medium',800,**W_),
    _p('pedicure_chair',pedicure_chair,'medium',1000,shift=(-0.015,0.114),**W_),
    _p('bulletproof_teller_window',bulletproof_teller_window,'medium',800,**W_),
    _p('wall_safe',wall_safe,'small',600,mount='wall',**W_),
    _p('security_grille_counter',security_grille_counter,'medium',1000),
    _p('tattoo_bed_chair',tattoo_bed_chair,'medium',1000,shift=(0.148,0.170)),
    _p('flash_art_wall',flash_art_wall,'medium',800,mount='wall',**W_),
    _p('hood_dryer_chair',hood_dryer_chair,'medium',1000,shift=(0.0,-0.18)),
    _p('po_box_wall',po_box_wall,'medium',1200,mount='wall',**W_),
    _p('parcel_scale',parcel_scale,'small',400,**W_),
    _p('copier_large_format_printer',copier_large_format_printer,'medium',1200,shift=(0.0,0.065)),
]
INDOOR_LOOK=True
