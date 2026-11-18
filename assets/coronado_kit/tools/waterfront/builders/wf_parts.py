"""Waterfront set: shared parts (builder space: metres, Z up, front/water side = -Y; exports to glTF Y-up, front +Z).
Datum for every water piece: z = 0 is the harbour bed at the wall toe, design still water WL = 1.5, quay / pier deck = 3.0.
Railing members are recorded in RAILS (near tier only) for wf_railcheck.py; collision parts are counted main/rail."""
import math, json, os
from mathutils import Vector, Matrix
import pg
PI=math.pi
V=lambda *a: Vector(a if len(a)==3 else a[0])
WL=1.5; DECK=3.0
RAILS=[]          # (kind, p0, p1, r)   kind: 'h' rail / 'v' post / 'p' polyline grab rail
COLN={'main':0,'rail':0}
TIER={'t':'near'}
def reset():
    RAILS.clear(); COLN['main']=0; COLN['rail']=0
def rec(kind,p0,p1,r,pts=None):
    if TIER['t']=='near': RAILS.append((kind,tuple(p0),tuple(p1),r,[tuple(q) for q in (pts or [p0,p1])]))
def cbox(b,c,size,rz=0.0,rail=False):
    b.cbox(c,size,rz)
    if TIER['t']=='near': COLN['rail' if rail else 'main']+=1
def ccyl(b,c,r,h,rail=True):
    b.ccyl(c,r,h)
    if TIER['t']=='near': COLN['rail' if rail else 'main']+=1
def rect(b,o,u,v,key,decal=False):
    """quad o, o+u, o+u+v, o+v (normal = u x v)"""
    o=Vector(o); u=Vector(u); v=Vector(v); return b.quad([o,o+u,o+u+v,o+v],key,decal=decal)
def seg_n(tier,hi,near,mid,hiseg=None):
    return (hiseg or near*2) if hi else (mid if tier=='mid' else near)
# ---------------------------------------------------------------- hardware
def nut(b,c,axis,r,h,key='galvanized',sides=6):
    c=Vector(c); a=Vector(axis).normalized(); b.tube(c,c+a*h,r,r*0.95,sides,key,cap0=False,cap1=True,smooth=False)
def bolt_head(b,c,axis,r=0.012,key='galvanized',hi=False):
    c=Vector(c); a=Vector(axis).normalized()
    if hi:
        b.tube(c,c+a*0.003,r*1.6,r*1.6,12,key,cap0=False,cap1=True)   # washer
        nut(b,c+a*0.003,a,r,r*0.8,key)
        b.tube(c+a*(0.003+r*0.8),c+a*(0.003+r*1.5),r*0.5,r*0.45,8,key,cap1=True)   # thread stub
    else: nut(b,c,a,r,r*0.8,key)
def base_plate(b,c,w,t,key,hi,bolts=4,br=0.012):
    x,y,z=c; b.box((x,y,z),(w,w,t),key,skip=('bottom',))
    if hi or bolts:
        for i in range(bolts):
            a=PI/4+i*2*PI/bolts; r=w*0.5*0.72*1.4142
            bolt_head(b,(x+r*math.cos(a)*0.7071,y+r*math.sin(a)*0.7071,z+t),(0,0,1),br,key,hi)
def bollard(b,c,hi=False,tier='near',key='paint_black',text=None):
    """cast-iron tee-head mooring bollard (Pacific-coast pattern): square base plate with 4 hold-down bolts, waisted barrel,
    flared head, cross horns. ~0.55 m high."""
    x,y,z=c; sg=seg_n(tier,hi,14,8,32)
    if tier!='mid': base_plate(b,(x,y,z),0.46,0.035,key,hi,4 if tier=='near' or hi else 0,0.016)
    else: b.box((x,y,z),(0.46,0.46,0.035),key,skip=('bottom',))
    z0=z+0.035
    prof=[(0.16,0.0),(0.155,0.03),(0.135,0.10),(0.125,0.22),(0.128,0.30),(0.15,0.36),(0.19,0.41),(0.19,0.46),(0.15,0.49),(0.0,0.50)]
    if tier=='mid': prof=[(0.16,0.0),(0.125,0.22),(0.19,0.41),(0.19,0.46),(0.0,0.50)]
    b.lathe([(r,z0+h) for r,h in prof],sg,key,c=(x,y,0),cap_top=False)
    hz=z0+0.30; hl=0.27
    hs=seg_n(tier,hi,10,6,20)
    for s in (-1,1):
        b.tube((x+s*0.11,y,hz),(x+s*hl,y,hz+0.03),0.06,0.05,hs,key,cap0=False,cap1=False)
        # knob end
        p=Vector((x+s*hl,y,hz+0.03)); d=Vector((s,0,0.11)).normalized()
        b.tube(p,p+d*0.025,0.05,0.062,hs,key,cap0=False,cap1=False); b.tube(p+d*0.025,p+d*0.045,0.062,0.0,hs,key,cap0=False,cap1=False)
    if hi:
        for zz in (0.10,0.36):   # casting seams / fillet rings
            b.lathe([(prof[2][0]+0.004 if zz<0.2 else 0.153,z0+zz-0.004),(prof[2][0]+0.008 if zz<0.2 else 0.157,z0+zz),(prof[2][0]+0.004 if zz<0.2 else 0.153,z0+zz+0.004)],sg,key,c=(x,y,0),cap_top=False)
        if text: pg.add_text(b,text,0.034,(x,y,z0+0.4995),(1,0,0),(0,1,0),0.004,key)
    ccyl(b,(x,y,z),0.19,0.53,rail=True)
def cleat(b,c,rz=0.0,hi=False,tier='near',key='galvanized',L=0.46):
    """cast horn cleat bolted on two feet"""
    x,y,z=c; R=Matrix.Rotation(rz,3,'Z'); P=lambda a,bb,cc: Vector((x,y,z))+R@Vector((a,bb,cc))
    sg=seg_n(tier,hi,8,6,16)
    for s in (-1,1):
        b.tube(P(s*0.09,0,0),P(s*0.08,0,0.075),0.045,0.032,sg,key,cap0=False,cap1=False)
        if hi or tier=='near': bolt_head(b,P(s*0.15,0,0),(0,0,1),0.01,key,hi); b.box(P(s*0.12,0,0)-Vector((0,0,0)),(0.09,0.08,0.012),key,skip=('bottom',),rz=rz)
    b.sweep([P(-L/2,0,0.095),P(-0.15,0,0.085),P(0,0,0.08),P(0.15,0,0.085),P(L/2,0,0.095)],0.028,sg,key,cap0=True,cap1=True)
def ring(b,c,nrm,R=0.11,r=0.018,hi=False,tier='near',key='galvanized'):
    """mooring ring hanging from an eye plate on a wall face (normal nrm)"""
    c=Vector(c); n=Vector(nrm).normalized(); up=Vector((0,0,1)); side=up.cross(n).normalized()
    pl=[c+side*(-0.09)+up*(-0.07),c+side*0.09+up*(-0.07),c+side*0.09+up*0.07,c+side*(-0.09)+up*0.07]
    o=n*0.02
    b.quad([p+o for p in pl],key)
    for i in range(4): b.quad([pl[i],pl[(i+1)%4],pl[(i+1)%4]+o,pl[i]+o],key)
    if hi or tier=='near':
        for sx in (-0.06,0.06):
            for sz in (-0.045,0.045): bolt_head(b,c+o+side*sx+up*sz,n,0.009,key,hi)
    eye=c+o+n*0.035
    b.tube(c+o,eye,0.025,0.022,8,key,cap0=False,cap1=False)
    n_=seg_n(tier,hi,12,8,24)
    # ring hangs in the plane (up, side) below the eye
    pts=[eye-up*R+up*math.sin(-PI/2+2*PI*i/n_)*R+side*math.cos(-PI/2+2*PI*i/n_)*R+n*0.0 for i in range(n_+1)]
    b.sweep(pts,r,seg_n(tier,hi,6,4,10),key,cap0=False,cap1=False)
# ---------------------------------------------------------------- timber fender pile with galvanized brackets
def fender_pile(b,x,yf,z0,z1,hi=False,tier='near',w=0.30,key='wood_weathered',bkey='galvanized',brackets=(0.9,1.9,2.6)):
    """square timber fender pile with chamfered arrises standing on the harbour bed in front of the wall face yf;
    galvanized U-straps through-bolted to the wall"""
    y=yf-w/2; sg=8 if tier!='mid' else 4
    r=w/2/math.cos(PI/8) if sg==8 else w/2*1.0
    if sg==8: b.tube((x,y,z0),(x,y,z1),r,r,8,key,cap0=False,cap1=False,smooth=False,phase=PI/8)
    else: b.box((x,y,z0),(w,w,z1-z0),key,skip=('bottom','top'))
    # weathered top: galvanized cap plate with a slight pyramid
    t=0.02; b.box((x,y,z1),(w+0.02,w+0.02,t),bkey,skip=('bottom',))
    b.faces([Vector((x-(w+0.02)/2,y-(w+0.02)/2,z1+t)),Vector((x+(w+0.02)/2,y-(w+0.02)/2,z1+t)),Vector((x+(w+0.02)/2,y+(w+0.02)/2,z1+t)),Vector((x-(w+0.02)/2,y+(w+0.02)/2,z1+t)),Vector((x,y,z1+t+0.05))],
            [(0,1,4),(1,2,4),(2,3,4),(3,0,4)],bkey,[[(0,0),(0.32,0),(0.16,0.12)]]*4)
    if tier=='mid': return
    for zb in brackets:
        if zb>z1-0.1: continue
        bw=0.06; th=0.012
        b.box((x,y-w/2-th/2,zb),(w+2*th,th,bw),bkey,skip=())                       # front strap
        for s in (-1,1): b.box((x+s*(w/2+th/2),y+0.0,zb),(th,w,bw),bkey,skip=('front',))   # side straps to the wall
        bolt_head(b,(x,y-w/2-th,zb+bw/2),(0,-1,0),0.016,bkey,hi)
    ccyl(b,(x,y,z0),w/2,z1-z0+0.07,rail=True)
# ---------------------------------------------------------------- ladder in a wall niche
def ladder(b,x,yb,z0,ztop,hi=False,tier='near',key='galvanized',W=0.45,stand=0.13,hoop_h=1.0,yland=0.35,rec_rails=True):
    """galvanized quay ladder: flat-bar stringers stand `stand` off the niche back wall yb (facing -Y), 30 cm rungs,
    stringers continue over the coping as grab hoops that land on the quay deck on bolted foot plates. Wall brackets
    every ~0.9 m, the lowest one at the stringer foot (no floating ends)."""
    if tier=='mid':
        for s in (-1,1): b.box((x+s*W/2,yb-stand,z0),(0.03,0.06,ztop-z0),key,skip=('bottom','top','back'))
        return
    ys=yb-stand; sg=seg_n(tier,hi,6,4,12)
    for s in (-1,1):
        xs=x+s*W/2
        b.box((xs,ys,z0),(0.012,0.065,ztop-z0),key,skip=('top',))                                  # flat bar 65 x 12
        rec('v',(xs,ys,z0),(xs,ys,ztop),0.03)
        # grab hoop: round bar from the stringer head up and over onto the deck
        pts=[Vector((xs,ys,ztop)),Vector((xs,ys,ztop+hoop_h*0.85)),Vector((xs,ys+0.08,ztop+hoop_h)),Vector((xs,ys+yland-0.08,ztop+hoop_h)),Vector((xs,ys+yland,ztop+hoop_h*0.85)),Vector((xs,ys+yland,DECK+0.012))]
        if hi:   # smooth bends in the high-poly
            pts=[pts[0],pts[1]]+[Vector((xs,ys+0.08-0.08*math.cos(a),ztop+hoop_h*0.85+0.15*math.sin(a))) for a in [k*PI/12 for k in range(1,6)]]+[pts[3]]+[Vector((xs,ys+yland-0.08+0.08*math.sin(a),ztop+hoop_h*0.85+0.15*math.cos(a))) for a in [k*PI/12 for k in range(1,6)]]+[pts[5]]
        b.sweep(pts,0.02,sg,key,cap0=False,cap1=False)
        rec('p',tuple(pts[0]),tuple(pts[-1]),0.02,pts)
        # deck foot plate + bolts
        b.box((xs,ys+yland,DECK),(0.10,0.10,0.012),key,skip=('bottom',))
        if hi or tier=='near':
            for dx in (-0.032,0.032): bolt_head(b,(xs+dx,ys+yland,DECK+0.012),(0,0,1),0.008,key,hi)
        # wall brackets
        zb=z0+0.02
        while zb<ztop-0.2:
            b.box((xs,(ys+0.0325+yb)/2,zb),(0.05,yb-ys-0.0325,0.06),key,skip=('front',))
            b.box((xs,yb-0.006,zb-0.03),(0.12,0.012,0.12),key,skip=('back',))      # wall plate
            if hi:
                for dx in (-0.04,0.04): bolt_head(b,(xs+dx,yb-0.012,zb+0.06),(0,-1,0),0.007,key,hi)
            zb+=0.9
    z=z0+0.30
    while z<ztop-0.05:
        b.tube((x-W/2+0.006,ys,z),(x+W/2-0.006,ys,z),0.014,0.014,sg,key,cap0=False,cap1=False)
        z+=0.30
    cbox(b,(x,ys,z0),(W+0.04,0.07,ztop-z0),rail=True)
# ---------------------------------------------------------------- galvanized pipe guard railing
def guardrail(b,pts,hi=False,tier='near',key='galvanized',H=1.07,spacing=1.5,r=0.024,r2=0.021,z=None,mid=True,end_posts=(True,True),flange=True):
    """posts on base flanges (4 bolts) along the polyline pts (x,y,z_floor), top rail + mid rail between posts.
    Each rail segment ends on a post face (touching, not buried). Corners get a post."""
    if tier=='mid': return
    sg=seg_n(tier,hi,8,6,16)
    posts=[]
    for i in range(len(pts)-1):
        a=Vector(pts[i]); c=Vector(pts[i+1]); L=(c-a).length; n=max(1,math.ceil(L/spacing-1e-6))
        for k in range(n): posts.append(a+(c-a)*(k/n))
    posts.append(Vector(pts[-1]))
    for k,p in enumerate(posts):
        top=p+Vector((0,0,H))
        b.tube(p+Vector((0,0,0.01 if flange else 0)),top,r,r,sg,key,cap0=False,cap1=True)
        rec('v',tuple(p),tuple(top),r)
        if flange:
            b.tube(p,p+Vector((0,0,0.01)),0.07,0.07,sg,key,cap0=False,cap1=True)
            if hi or tier=='near':
                for i in range(4 if hi else 2):
                    a=PI/4+i*(PI/2 if hi else PI); bolt_head(b,p+Vector((0.048*math.cos(a),0.048*math.sin(a),0.01)),(0,0,1),0.006,key,hi)
        if hi: b.lathe([(r+0.004,H-0.004),(r+0.004,H+0.006),(0.0,H+0.012)],sg,key,c=p,cap_top=False)
    rails=[H-r]+([0.55] if mid else [])
    for k in range(len(posts)-1):
        a=posts[k]; c=posts[k+1]; d=(c-a); d.z=0; L=d.length; d.normalize()
        for zz,rr in zip(rails,(r,r2)):
            p0=a+d*(r*0.95)+Vector((0,0,zz)); p1=c-d*(r*0.95)+Vector((0,0,zz))
            b.tube(p0,p1,rr,rr,sg,key,cap0=False,cap1=False)
            rec('h',tuple(p0),tuple(p1),rr)
    # collision: one rail box per straight run (merged posts + rails), 1.07 m high, 0.08 thick
    for i in range(len(pts)-1):
        a=Vector(pts[i]); c=Vector(pts[i+1]); m=(a+c)/2; L=(c-a).length; ang=math.atan2(c.y-a.y,c.x-a.x)
        cbox(b,(m.x,m.y,a.z),(L+0.06,0.08,H+0.02),rz=ang,rail=True)
    return posts
def save_rails(name, outdir):
    os.makedirs(outdir,exist_ok=True)
    json.dump({'rails':RAILS,'col':dict(COLN)},open(f'{outdir}/{name}_rails.json','w'))
