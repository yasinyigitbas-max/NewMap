"""Carry props (player / NPC hand props) — module b_incarry, page J (own 1024 page; never pages A/B/C/W/H/I),
near + col only, one material. Real-world scale. Origin at the footprint centre on the ground (z=0, front -Y), so a
dropped / placed prop sits on the floor; hand attach points are exported as empty nodes in the near glb
(grip_r / grip_l, see GRIPS) by c_grips.py and recorded in manifest_incarry.json.
Grip node convention (Godot, Y-up): origin = centre of the hand's closed fist on the handle; local +X runs along
the handle bar, +Y up (the prop hangs along -Y). Two-hand props carry grip_l / grip_r on opposite faces.
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math, random
import mathutils
from mathutils import Vector, Matrix
import pg
from b_inshared import sg

def V(*a): return Vector(a)
def nfaces(b): return len(b.bm.faces)
def xform(b, n0, fn):
    vs=set()
    for f in list(b.bm.faces)[n0:]:
        for vv in f.verts: vs.add(vv)
    for vv in vs: vv.co=fn(vv.co.copy())

# trims on page J (tiling): bag insides, glue patches
TR={'kraft_in':('kraft_paper',(0.48,0.48)), 'kraft_in_bot':('kraft_paper',(0.48,0.48)), 'kraft_patch':('kraft_paper',(0.48,0.48)), 'white_in':('paper_white',(0.48,0.48))}
TINT={'kraft_in':(1.12,1.10,1.06), 'kraft_in_bot':(1.05,1.03,1.0), 'kraft_patch':(1.30,1.26,1.20), 'white_in':(1.0,1.0,1.0)}

def grid(b, P, nu, nv, key, flip=False, luv_scale=(1.0,1.0)):
    """surface patch P(s,t) (s,t in 0..1) as an nu x nv quad grid in one island; metre uvs from the arc lengths"""
    pts=[[P(i/nu,j/nv) for j in range(nv+1)] for i in range(nu+1)]
    us=[[0.0]*(nv+1) for _ in range(nu+1)]; vs=[[0.0]*(nv+1) for _ in range(nu+1)]
    for j in range(nv+1):
        for i in range(1,nu+1): us[i][j]=us[i-1][j]+(pts[i][j]-pts[i-1][j]).length
    for i in range(nu+1):
        for j in range(1,nv+1): vs[i][j]=vs[i][j-1]+(pts[i][j]-pts[i][j-1]).length
    # straighten u per column (mean) so the island is a clean rectangle-ish shape
    verts=[]; idx={}
    for i in range(nu+1):
        for j in range(nv+1): idx[i,j]=len(verts); verts.append(pts[i][j])
    polys=[]; luv=[]
    for i in range(nu):
        for j in range(nv):
            q=[(i,j),(i+1,j),(i+1,j+1),(i,j+1)]
            if flip: q=q[::-1]
            polys.append(tuple(idx[a] for a in q)); luv.append([(us[a][c]*luv_scale[0],vs[a][c]*luv_scale[1]) for a,c in q])
    return b.faces(verts,polys,key,luv,smooth=True)

# ------------------------------------------------------------------ paper shopping bag
def _vnoise(seed):
    r=random.Random(seed); W=[(r.uniform(-1,1),r.uniform(-1,1),r.uniform(0,6.283),r.uniform(0.6,1.0)) for _ in range(9)]
    def f(x,z,sc):
        return sum(a*math.sin((x*kx+z*kz)/sc*6.283+ph) for kx,kz,ph,a in W)/4.0
    return f

def paper_bag(b, hi, W=0.32, D=0.16, H=0.40, paper='kraft_paper', inside='kraft_in', patch='kraft_patch', cord='rope_kraft',
              ink='ink_navy', print_fn=None, hh=0.105, hx=0.055, fill=0.0, handle='cord', contents=None, inside_bot=None, gkey=None):
    """retail paper carrier bag (SOS style): front / back panels with a slight fill bulge, side gussets pinched in
    at the top along their centre crease, flat bottom, 40 mm turned-in top cuff, twisted paper-cord handles glued
    inside under a reinforcing patch, flat-pack fold creases (bottom fold line, gusset diagonals) in the bake.
    print_fn(b, hi, face_point) adds the printed artwork (high only) on both faces."""
    b.cur_sym=2   # back = front turned 180 deg: one shared bake (print reads right on both faces)
    wr=_vnoise(7); wr2=_vnoise(19)
    g_top=0.028                 # gusset crease pinch at the rim
    bulge=0.006+0.010*fill
    def pinch(t): return g_top*t**1.8
    def wrinkle(x,z):
        if not hi: return 0.0
        w=0.00028*wr(x,z,0.16)+0.00010*wr2(x,z,0.05)
        # flat-pack crease: bottom fold line at z=D/2 (the bottom was folded up flat against the face)
        w+=-0.0007*math.exp(-((z-D/2)/0.0025)**2)
        # soft handling crease, fading toward the edges
        w+=-0.00035*math.exp(-((z-0.61*H-0.02*math.sin(x*9))/0.004)**2)*max(0.0,math.cos(x/W*math.pi))
        return w
    def face_y(x,z):
        """outer front surface y (front = -Y) at (x,z)"""
        s=(x+W/2)/W; t=z/H
        bz=math.sin(math.pi*min(1,max(0,s)))*(math.sin(math.pi*min(1.0,t*0.85+0.08))**0.8)
        return -D/2-bulge*bz-wrinkle(x,z)
    PRINT_FACE=face_y
    nu,nv=sg(hi,2,40),sg(hi,2,48)
    for rot in (0.0,math.pi):
        R=Matrix.Rotation(rot,3,'Z'); n0=nfaces(b)
        # outer front panel
        grid(b,lambda s,t: V(-W/2+W*s, face_y(-W/2+W*s,H*t), H*t),nu,nv,paper)
        # side gusset (left side for rot 0): front corner -> crease -> back corner, two half panels
        for half in (0,1):
            def Pg(s,t,half=half):
                z=H*t; cx=-W/2+pinch(t)
                if half==0: y0,y1=-D/2,0.0; x0,x1=-W/2,cx
                else: y0,y1=0.0,D/2; x0,x1=cx,-W/2
                x=x0+(x1-x0)*s; y=y0+(y1-y0)*s
                # gusset diagonal fold creases near the bottom (hi): small dents along the 45 deg lines
                if hi:
                    dd=abs((s if half==0 else 1-s)*D/2-z)
                    x+=0.0007*math.exp(-(dd/0.0025)**2)*(1 if z<D/2+0.01 else 0)
                    x+=0.00025*wr(y,z,0.12)
                return V(x,y,z)
            grid(b,Pg,sg(hi,1,10),sg(hi,2,48),gkey or paper,flip=True)
        # bottom (outer), front half
        grid(b,lambda s,t: V(-W/2+W*s, -D/2*(1-t), 0.0),sg(hi,1,8),sg(hi,1,4),gkey or paper,flip=True)
        # inner walls (cuff: 40 mm turned in; the cuff edge is a 0.6 mm step in the high), inner bottom, rim
        off=lambda z: (0.0040 if hi else 0.0007)+(0.0006 if (hi and z>H-0.04) else 0.0)
        _io=0.0040 if hi else 0.0008
        grid(b,lambda s,t: V(-W/2+_io+(W-2*_io)*s, face_y(-W/2+W*s,H*t)+off(H*t), max(0.0006,H*t)),nu,sg(hi,2,48),inside,flip=True)
        for half in (0,1):
            def Pi(s,t,half=half):
                io=0.0040 if hi else 0.0008; z=max(0.0006,H*t); cx=-W/2+pinch(t)+io
                if half==0: y0,y1=-D/2+io,0.0; x0,x1=-W/2+io,cx
                else: y0,y1=0.0,D/2-io; x0,x1=cx,-W/2+io
                return V(x0+(x1-x0)*s,y0+(y1-y0)*s,z)
            grid(b,Pi,1,sg(hi,2,24),inside)
        grid(b,lambda s,t: V(-W/2+0.0008+(W-0.0016)*s, (-D/2+0.0008)*(1-t), 0.0006),1,1,inside_bot or inside+'_bot')
        # rim strip (top edge of the folded paper)
        P0=lambda s: V(-W/2+W*s, face_y(-W/2+W*s,H), H)
        grid(b,lambda s,t: P0(s)+V(0,off(H)*t,0),sg(hi,2,20),1,gkey or paper)
        # glue patch inside the front face over the cord ends
        pw,ph,pz=0.17,0.05,H-0.060
        def Pp(s,t):
            e=min(s*pw,(1-s)*pw,t*ph,(1-t)*ph); o=0.0010+0.0062*min(1.0,e/0.0035)
            return V(-pw/2+pw*s, face_y(-pw/2+pw*s,pz+ph*t)+o, pz+ph*t)
        grid(b,Pp,sg(hi,4,24),sg(hi,2,10),patch,flip=True) if hi else grid(b,lambda s,t: Pp(0.02+0.96*s,0.07+0.86*t),4,1,patch,flip=True)
        # twisted paper-cord handle: ends under the patch, over the rim, arched loop leaning in toward the centre
        rr=0.0034
        Np=sg(hi,10,24); pts=[]
        yin=face_y(0,H)+0.0044
        pts.append(V(-hx, face_y(-hx,H-0.045)+0.0044, H-0.045))
        for k in range(Np+1):
            a=math.pi*k/Np
            x=-hx*math.cos(a)*(1+0.10*math.sin(a)); z=H+hh*math.sin(a)**0.9
            y=yin+(-0.012-yin)*math.sin(a)**1.3
            pts.append(V(x,y,z))
        pts.append(V(hx, face_y(hx,H-0.045)+0.0044, H-0.045))
        if handle=='cord': b.sweep(pts,rr,sg(hi,3,10),cord,cap0=False,cap1=False)
        else: ribbon(b,pts,0.024,cord,hi)
        if rot: xform(b,n0,lambda co,R=R: R@co)
    if contents:
        b.cur_sym=1; contents(b,hi,W,D,H); b.cur_sym=2
    if hi and print_fn:
        for rot in (0.0,math.pi):
            n0=nfaces(b); print_fn(b,PRINT_FACE,ink)
            if rot: xform(b,n0,lambda co: Matrix.Rotation(math.pi,3,'Z')@co)
    b.cbox((0,0,0),(W+0.01,D+0.02,H))

FONT_SERIF='/usr/share/fonts/truetype/sand-box/google/DM Serif Display/DMSerifDisplay-Regular.ttf'
FONT_COND='/usr/share/fonts/truetype/sand-box/google/Barlow Condensed/BarlowCondensed-Bold.ttf'
def _onface(b, n0, face_y, lift=0.00035):
    """drape print geometry added since n0 onto the bag face (front, -Y)"""
    xform(b,n0,lambda co: V(co.x, face_y(co.x,co.z)-lift, co.z))
def _crown(b, cx, cz, w, key):
    """flat five-point crown emblem in the XZ plane (front face), triangles only"""
    h=w*0.62; bw=w; bh=h*0.28; y=-1.0
    P=lambda x,z: V(cx+x,y,cz+z)
    def tri(a,b_,c):
        b.faces([a,b_,c],[(0,1,2)],key,[[(a.x,a.z),(b_.x,b_.z),(c.x,c.z)]])
    def quad(a,b_,c,d): b.faces([a,b_,c,d],[(0,1,2,3)],key,[[(p.x,p.z) for p in (a,b_,c,d)]])
    quad(P(-bw/2,0),P(bw/2,0),P(bw/2,bh),P(-bw/2,bh))
    xs=[-bw/2,-bw/4,0,bw/4,bw/2]; hs=[h,h*0.72,h,h*0.72,h]
    for i in range(5):
        x=xs[i]; d=bw*0.095
        x0=max(-bw/2,x-d*1.4); x1=min(bw/2,x+d*1.4)
        tri(P(x0,bh),P(x1,bh),P(x,hs[i]-h*0.08))
        # jewel ball on each point
        n=8; c=P(x,hs[i]); r=d*0.55
        ring=[c+V(r*math.cos(2*math.pi*k/n),0,r*math.sin(2*math.pi*k/n)) for k in range(n)]
        b.faces([c]+ring,[(0,1+k,1+(k+1)%n) for k in range(n)][::1],key,[[(p.x,p.z) for p in [c,ring[k],ring[(k+1)%n]]] for k in range(n)])
    quad(P(-bw/2,-h*0.10),P(bw/2,-h*0.10),P(bw/2,-h*0.03),P(-bw/2,-h*0.03))
def _fix_front(b, n0):
    """faces built in the XZ plane at y=-1 face -Y? flip any face whose normal points +Y"""
    for f in list(b.bm.faces)[n0:]:
        f.normal_update()
        if f.normal.y>0: f.normal_flip()
def print_crown_city(b, face_y, ink):
    """'Crown City Mercantile' one-colour flexo print, centred on the face"""
    n0=nfaces(b)
    _crown(b,0.0,0.262,0.072,ink)
    pg.add_text(b,'Crown City',0.064,(0,-1.0,0.205),(1,0,0),(0,0,1),0.0002,ink,font=FONT_SERIF,res=4,back=False,sides=False)
    pg.add_text(b,'MERCANTILE',0.034,(0,-1.0,0.160),(1,0,0),(0,0,1),0.0002,ink,font=FONT_COND,res=3,back=False,sides=False)
    for z in (0.1765,0.1405):
        b.faces([V(-0.072,-1,z),V(0.072,-1,z),V(0.072,-1,z+0.0035),V(-0.072,-1,z+0.0035)],[(0,1,2,3)],ink,[[(0,0),(0.144,0),(0.144,0.0035),(0,0.0035)]])
    pg.add_text(b,'CORONADO',0.024,(0,-1.0,0.118),(1,0,0),(0,0,1),0.0002,ink,font=FONT_COND,res=3,back=False,sides=False)
    _fix_front(b,n0); _onface(b,n0,face_y)

def bag_paper_kraft(b, hi=False):
    """medium kraft carrier bag, navy Crown City Mercantile print, kraft twisted-cord handles"""
    paper_bag(b,hi,print_fn=print_crown_city)


# ================================================================== carry batch helpers
FONT_SANS='/usr/share/fonts/truetype/sand-box/google/Barlow Condensed/BarlowCondensed-Bold.ttf'
FONT_MARK='/usr/share/fonts/truetype/sand-box/google/Permanent Marker/PermanentMarker-Regular.ttf'
FONT_STEN='/usr/share/fonts/truetype/sand-box/google/Black Ops One/BlackOpsOne-Regular.ttf'
FONT_CINZ='/usr/share/fonts/truetype/sand-box/google/Cinzel/Cinzel-VariableFont_wght.ttf'
def M_rot(axis, a): return Matrix.Rotation(a,3,axis)
def place(b, n0, M=None, t=(0,0,0)):
    M=M or Matrix.Identity(3); T=V(*t); xform(b,n0,lambda co: M@co+T)

def ribbon(b, pts, w, key, hi, t=0.0007, w1=None, pn=None, across=False):
    """flat strip along a path in a vertical plane: width in-plane (perpendicular to the path), thickness along the
    plane normal; two faces (front/back). w1: width at the end (taper)."""
    pn_=pn; P=[Vector(p) for p in pts]; n=len(P)
    pn=(P[-1]-P[0]).cross(V(0,0,1)); pn=V(0,1,0) if pn.length<1e-6 else pn.normalized()   # plane normal (horizontal)
    pn=V(0,1,0) if abs(pn.y)>=abs(pn.x) else V(1,0,0)
    if pn_ is not None: pn=V(*pn_)
    L=[0.0]
    for i in range(1,n): L.append(L[-1]+(P[i]-P[i-1]).length)
    for side in (-1,1):
        vs=[]; luv=[]
        for i,p in enumerate(P):
            tg=(P[min(i+1,n-1)]-P[max(i-1,0)]).normalized(); q=tg.cross(pn).normalized()
            ww=w if w1 is None else w+(w1-w)*L[i]/L[-1]
            off=(pn*side*t) if not across else (-q*side*t)
            if across: q=pn
            vs+= [p-q*ww/2+off, p+q*ww/2+off]
        polys=[]; uv=[]
        for i in range(n-1):
            a,b_,c,d=2*i,2*i+1,2*i+3,2*i+2
            q=(a,b_,c,d) if side>0 else (a,d,c,b_)
            polys.append(q); uv.append([( (0.0 if k%2==0 else w), L[k//2]) for k in q])
        b.faces(vs,polys,key,uv,smooth=True)

def loft(b, rings, key, cap0=False, cap1=False, smooth=True):
    """closed rings (same count, CCW seen from the ring's +normal side) -> quad strip; one island"""
    m=len(rings[0]); R=[[Vector(p) for p in r] for r in rings]
    per=[[0.0] for _ in R]
    for i,r in enumerate(R):
        for k in range(1,m+1): per[i].append(per[i][-1]+(r[k%m]-r[k-1]).length)
    vcum=[0.0]
    for i in range(1,len(R)): vcum.append(vcum[-1]+sum((R[i][k]-R[i-1][k]).length for k in range(m))/m)
    vs=[]; idx={}
    for i,r in enumerate(R):
        for k in range(m+1): idx[i,k]=len(vs); vs.append(r[k%m])
    polys=[]; luv=[]
    for i in range(len(R)-1):
        for k in range(m):
            q=[(i,k),(i,k+1),(i+1,k+1),(i+1,k)]
            polys.append(tuple(idx[a] for a in q)); luv.append([(per[a][c],vcum[a]) for a,c in q])
    b.faces(vs,polys,key,luv,smooth=smooth)
    for cap,r,flip in ((cap0,R[0],True),(cap1,R[-1],False)):
        if not cap: continue
        c=sum(r,Vector())/m
        P=[c]+r; pl=[]; lu=[]
        for k in range(m):
            tri=(0,1+k,1+(k+1)%m) if not flip else (0,1+(k+1)%m,1+k)
            pl.append(tri); lu.append([(P[j].x,P[j].y) for j in tri])
        b.faces(P,pl,key,lu,smooth=smooth)

def sring(cx, cy, z, a, bb, n, e=4.0, phase=0.0):
    """superellipse ring (CCW from +Z), starts on +X (phase in radians)"""
    out=[]
    for k in range(n):
        t=phase+2*math.pi*k/n; c,s_=math.cos(t),math.sin(t)
        out.append(V(cx+a*math.copysign(abs(c)**(2/e),c), cy+bb*math.copysign(abs(s_)**(2/e),s_), z))
    return out

def blob(b, c, r, key, hi, squash=(1,1,1), n=None, bot_cap=True, upper=False):
    """low-poly sphere (orange, crumpled paper)"""
    nu=n or sg(hi,6,14); nv=max(3,nu//2)
    rings=[]
    for j in (range(1,nv) if not upper else range(nv//2,nv)):
        ph=-math.pi/2+math.pi*j/nv; rr=r*math.cos(ph); z=r*math.sin(ph)
        rings.append([V(c[0]+rr*math.cos(2*math.pi*k/nu)*squash[0],c[1]+rr*math.sin(2*math.pi*k/nu)*squash[1],c[2]+z*squash[2]) for k in range(nu)])
    loft(b,rings,key)
    bot=V(c[0],c[1],c[2]-r*squash[2]); top=V(c[0],c[1],c[2]+r*squash[2])
    for ring,pole,up in (((rings[0],bot,False),) if bot_cap else ())+((rings[-1],top,True),):
        P=[pole]+ring; pl=[]; lu=[]
        for k in range(nu):
            tri=(0,1+k,1+(k+1)%nu) if up else (0,1+(k+1)%nu,1+k)
            pl.append(tri); lu.append([(P[j].x,P[j].y) for j in tri])
        b.faces(P,pl,key,lu,smooth=True)

class Plane:
    """2D drawing on a flat decal: origin o (centre), unit X right, Y up; normal N = X x Y (outward)"""
    def __init__(s, b, o, X, Y, lift=0.0003): s.b=b; s.o=V(*o); s.X=V(*X).normalized(); s.Y=V(*Y).normalized(); s.N=s.X.cross(s.Y); s.l=lift
    def P(s, u, v, d=0.0): return s.o+s.X*u+s.Y*v+s.N*(s.l+d)
    def rect(s, u0, v0, u1, v1, key, d=0.0):
        s.b.faces([s.P(u0,v0,d),s.P(u1,v0,d),s.P(u1,v1,d),s.P(u0,v1,d)],[(0,1,2,3)],key,[[(u0,v0),(u1,v0),(u1,v1),(u0,v1)]])
    def text(s, txt, size, uv, key, font=FONT_SANS):
        u,v=uv
        pg.add_text(s.b,txt,size,tuple(s.P(u,v)),tuple(s.X),tuple(s.Y),0.0002,key,font=font,res=3,back=False,sides=False)
    def poly(s, pts, key, d=0.0):
        c=(sum(p[0] for p in pts)/len(pts),sum(p[1] for p in pts)/len(pts)); P=[s.P(*c,d)]+[s.P(u,v,d) for u,v in pts]; n=len(pts)
        s.b.faces(P,[(0,1+k,1+(k+1)%n) for k in range(n)],key,[[ (c if j==0 else pts[j-1]) for j in (0,1+k,1+(k+1)%n)] for k in range(n)])
    def ring(s, cu, cv, r0, r1, key, n=24):
        for k in range(n):
            a0=2*math.pi*k/n; a1=2*math.pi*(k+1)/n
            Q=[(cu+r0*math.cos(a0),cv+r0*math.sin(a0)),(cu+r1*math.cos(a0),cv+r1*math.sin(a0)),(cu+r1*math.cos(a1),cv+r1*math.sin(a1)),(cu+r0*math.cos(a1),cv+r0*math.sin(a1))]
            s.b.faces([s.P(*q) for q in Q],[(0,1,2,3)],key,[Q])
    def disc(s, cu, cv, r, key, n=16): s.poly([(cu+r*math.cos(2*math.pi*k/n),cv+r*math.sin(2*math.pi*k/n)) for k in range(n)],key)
    def arc(s, cu, cv, r, a0, a1, w, key, n=10):
        for k in range(n):
            t0=a0+(a1-a0)*k/n; t1=a0+(a1-a0)*(k+1)/n
            Q=[(cu+(r-w/2)*math.cos(t0),cv+(r-w/2)*math.sin(t0)),(cu+(r+w/2)*math.cos(t0),cv+(r+w/2)*math.sin(t0)),(cu+(r+w/2)*math.cos(t1),cv+(r+w/2)*math.sin(t1)),(cu+(r-w/2)*math.cos(t1),cv+(r-w/2)*math.sin(t1))]
            if (a1-a0)<0: Q=[Q[1],Q[0],Q[3],Q[2]]
            s.b.faces([s.P(*q) for q in Q],[(0,1,2,3)],key,[Q])

def decal(b, hi, o, X, Y, w, h, bg, draw=None, lift=0.0006):
    """baked label / print panel: one low quad (bg region) lifted off the surface; draw(pl) adds the print (high only)"""
    pl=Plane(b,o,X,Y,lift); pl.rect(-w/2,-h/2,w/2,h/2,bg)
    if hi: pl.rect(-w/2-0.005,-h/2-0.005,w/2+0.005,h/2+0.005,bg,d=-0.0002)
    if hi and draw: dp=Plane(b,o,X,Y,lift+0.0003); draw(dp)

def barcode(pl, u0, v0, w, h, key, seed=3):
    r=random.Random(seed); u=u0
    while u<u0+w:
        bw=r.choice((0.0008,0.0008,0.0014,0.002)); pl.rect(u,v0,min(u+bw,u0+w),v0+h,key); u+=bw+r.choice((0.0008,0.0012,0.0018))

def handle_arc(b, x0, x1, y, z, hgt, r, key, hi, seg=None, n=None, sq=True, flat=1.0):
    """carry handle: arched bar along X between mounts at x0..x1 (top at z+hgt)"""
    n=n or sg(hi,6,16); pts=[]
    for k in range(n+1):
        t=k/n; a=math.pi*t
        pts.append(V(x0+(x1-x0)*t, y, z+hgt*math.sin(a)**0.7))
    n0=nfaces(b); b.sweep(pts,r,seg or sg(hi,4,10),key,cap0=False,cap1=False,sq=sq and not hi)
    if flat!=1.0: xform(b,n0,lambda co: V(co.x,y+(co.y-y)*flat,co.z))

def strap(b, pts, w, t, key, hi):
    """padded strap / band with a thickness: rectangle section swept along pts (width along the side normal)"""
    ribbon(b,pts,w,key,hi,t=t/2)

# ================================================================== paper bags 2-3
def print_maison(b, face_y, ink):
    """'MAISON CORAL' boutique bag: thin double frame + serif wordmark + shell mark, gold foil"""
    n0=nfaces(b); pl=Plane(b,(0,-1.0,0.15),(1,0,0),(0,0,1),0.0)
    pl.rect(-0.086,-0.086,0.086,-0.0815,ink); pl.rect(-0.086,0.0815,0.086,0.086,ink)
    pl.rect(-0.086,-0.086,-0.0815,0.086,ink); pl.rect(0.0815,-0.086,0.086,0.086,ink)
    pl.text('MAISON',0.044,(0,0.010),ink,font=FONT_SERIF); pl.text('CORAL',0.044,(0,-0.030),ink,font=FONT_SERIF)
    pl.arc(0,0.052,0.018,math.radians(10),math.radians(170),0.0035,ink,n=12)          # shell fan
    for a in (30,60,90,120,150):
        t=math.radians(a); pl.rect(-0.0012,0.052,0.0012,0.052+0.017,ink) if a==90 else None
        if a!=90:
            c,s_=math.cos(t),math.sin(t); P=[(0.002*s_,0.052-0.002*c),(0.018*c+0.0012*s_,0.052+0.018*s_-0.0012*c),(0.018*c-0.0012*s_,0.052+0.018*s_+0.0012*c),(-0.002*s_,0.052+0.002*c)]
            pl.poly(P,ink)
    pl.text('CORONADO  ·  PARIS',0.012,(0,-0.058),ink,font=FONT_SANS)
    _fix_front(b,n0); xform(b,n0,lambda co: V(co.x, face_y(co.x,co.z)-0.00035, co.z))

def bag_paper_boutique(b, hi=False):
    """small white boutique bag, black twisted-rope handles, gold 'MAISON CORAL' print"""
    paper_bag(b,hi,W=0.24,D=0.10,H=0.28,paper='paper_white',inside='white_in',patch='white_patch',cord='rope_black',
              ink='ink_gold',print_fn=print_maison,hh=0.090,hx=0.042,inside_bot='white_in_bot',gkey='white_g')

def print_market(b, face_y, ink):
    """'Orange Ave. Market' grocery print: sun-and-leaf mark, big wordmark, strapline"""
    n0=nfaces(b); pl=Plane(b,(0,-1.0,0.0),(1,0,0),(0,0,1),0.0)
    pl.disc(0,0.262,0.030,'ink_orange',n=20); pl.ring(0,0.262,0.034,0.038,ink,n=24)
    pl.poly([(0.004,0.292),(0.028,0.318),(0.034,0.300),(0.012,0.290)],ink)       # leaf
    pl.text('ORANGE AVE.',0.040,(0,0.196),ink,font=FONT_SANS); pl.text('MARKET',0.058,(0,0.152),ink,font=FONT_SANS)
    pl.rect(-0.10,0.120,0.10,0.124,ink); pl.text('FRESH  ·  LOCAL  ·  SINCE 1961',0.016,(0,0.104),ink,font=FONT_SANS)
    _fix_front(b,n0); xform(b,n0,lambda co: V(co.x, face_y(co.x,co.z)-0.00035, co.z))

def grocery_contents(b, hi, W, D, H):
    """baguette leaning out of the back corner + a wine bottle neck"""
    n0=nfaces(b); n=sg(hi,7,14)
    b.tube((0,0,0),(0,0,0.06),0.0,0.030,n,'crust',cap0=False,cap1=False)
    b.tube((0,0,0.06),(0,0,0.40),0.030,0.030,n,'crust',cap0=False,cap1=False)
    b.tube((0,0,0.40),(0,0,0.47),0.030,0.004,n,'crust',cap0=False,cap1=True)
    if hi:   # scoring slashes on the crust
        for k in range(4):
            z=0.12+k*0.075; b.box((0,-0.031,z),(0.018,0.004,0.028),'label_white',rz=0.0,rx=0.5)
    place(b,n0,M_rot('X',-0.22)@M_rot('Y',-0.06),(W*0.24,D*0.10,0.02))
    n0=nfaces(b); m=sg(hi,6,14)
    prof=[(0.036,0.0),(0.036,0.20),(0.030,0.25),(0.014,0.29),(0.013,0.36),(0.0145,0.375),(0.0,0.375)]
    b.lathe(prof[:5],m,'glass_g',c=(0,0,0),cap_top=False,cap_bot=False)
    b.lathe(prof[4:],m,'cap_r',c=(0,0,0),cap_top=False,cap_bot=False)
    place(b,n0,M_rot('Y',-0.12)@M_rot('X',0.10),(-W*0.24,0.01,0.02))

def bag_paper_grocery(b, hi=False):
    """large kraft grocery bag with flat paper handles, green 'Orange Ave. Market' print, baguette + bottle"""
    paper_bag(b,hi,W=0.36,D=0.20,H=0.38,print_fn=print_market,ink='ink_green',hh=0.095,hx=0.060,fill=0.6,
              handle='flat',cord='kraft_h',contents=grocery_contents,gkey='kraft_g')

# ================================================================== plastic bags
def tshirt_bag(b, hi, W=0.30, D=0.16, H=0.33, key='film', print_fn=None, hh=0.15, contents=None, fine=True):
    """filled T-shirt carrier bag: gusseted bottom, round fill bulge, top drawn closed, two loop handles cut from
    the top gathered in the fist (grip at the top)"""
    b.cur_sym=1; n=sg(hi,12,40); e=2.4   # own bake per face (the shared 180 deg match split the curved panel)
    def ab(t):
        a=W/2*(0.90+0.10*math.sin(math.pi*min(1,t*1.15)))-W*0.04*t**3
        bb=D/2*(0.72+0.30*math.sin(math.pi*min(1,t*1.05))**0.7)*(1-0.80*t**4)+0.006
        return a,bb
    ts=([0.0,0.06,0.25,0.50,0.75,0.90,1.0] if fine else [0.0,0.06,0.35,0.70,0.90,1.0]) if not hi else [i/36 for i in range(37)]
    n=sg(hi,16 if fine else 12,40); nh=n//2
    kt=key+'_t' if key+'_t' in TR else key
    def SP(k,t):   # half ring point k (0..nh, -X -> front -> +X) at height t
        a,bb=ab(t); th=math.pi+math.pi*k/nh; c,s_=math.cos(th),math.sin(th)
        p=V(a*math.copysign(abs(c)**(2/e),c), bb*math.copysign(abs(s_)**(2/e),s_), H*t)
        if hi:   # film wrinkles: radial ripple
            p=p+V(p.x,p.y,0).normalized()*0.0015*math.sin(9*th+t*7)*math.sin(math.pi*t)
        return p
    for rot in (0.0,math.pi):
        n0=nfaces(b)
        q=nh//4   # printed front panel (middle half of the half ring) on the bake; the curved sides on the film trim
        grid(b,lambda s_,t_: SP(round(s_*q),ts[round(t_*(len(ts)-1))]),q,len(ts)-1,kt)
        grid(b,lambda s_,t_: SP(q+round(s_*(nh-2*q)),ts[round(t_*(len(ts)-1))]),nh-2*q,len(ts)-1,key)
        grid(b,lambda s_,t_: SP(nh-q+round(s_*q),ts[round(t_*(len(ts)-1))]),q,len(ts)-1,kt)
        for t_,up in ((0.0,False),(1.0,True)):
            ring=[SP(k,t_) for k in range(nh+1)]; c=V(0,0,H*t_); vs=[c]+ring; polys=[]; uv=[]
            for k in range(nh):
                q=(0,1+k,2+k) if up else (0,2+k,1+k); polys.append(q); uv.append([(vs[i].x,vs[i].y) for i in q])
            b.faces(vs,polys,kt,uv,smooth=True)
        if rot: xform(b,n0,lambda co: M_rot('Z',math.pi)@co)
    def surf_y(x,z):
        a,bb=ab(z/H); u=min(0.999,abs(x)/a); return -bb*(1-u**e)**(1/e)
    for rot in (0.0,math.pi):
        n0=nfaces(b); a,_=ab(1.0)
        P=[V(-a*0.80,0,H-0.012),V(-a*0.70,0,H+hh*0.35),V(-a*0.45,0,H+hh*0.75),V(-0.035,0,H+hh*0.98),V(0.012,0,H+hh)]
        if hi:   # smooth the path
            from mathutils.geometry import interpolate_bezier
            Q=[]
            for i in range(len(P)-1):
                Q+=[P[i]+(P[i+1]-P[i])*k/6 for k in range(6)]
            P=Q+[P[-1]]
        ribbon(b,P,0.085,kt,hi,t=0.0045,w1=0.028)
        if rot: xform(b,n0,lambda co: M_rot('Z',math.pi)@co)
    b.cur_sym=1
    if contents: contents(b,hi,W,D,H)
    if hi and print_fn:
        for rot in (0.0,math.pi):
            n0=nfaces(b); print_fn(b); xform(b,n0,lambda co: V(co.x, surf_y(co.x,co.z)-0.0024, co.z))
            if rot: xform(b,n0,lambda co: M_rot('Z',math.pi)@co)
    b.cbox((0,0,0),(W,D+0.02,H))

def print_thankyou(b):
    n0=nfaces(b); pl=Plane(b,(0,-1.0,0.0),(1,0,0),(0,0,1),0.0); ink='ink_red'
    for i,z in enumerate((0.235,0.195,0.155)): pl.text('THANK YOU',0.036,(0,z),ink,font=FONT_SANS)
    pl.ring(0,0.090,0.028,0.032,ink,n=24); pl.disc(-0.010,0.098,0.0035,ink,n=8); pl.disc(0.010,0.098,0.0035,ink,n=8)
    pl.arc(0,0.092,0.016,math.radians(200),math.radians(340),0.0035,ink,n=10)
    pl.text('HAVE A NICE DAY!',0.017,(0,0.048),ink,font=FONT_SANS)
    _fix_front(b,n0)

def bag_plastic_thankyou(b, hi=False):
    """white T-shirt bag, red THANK YOU x3 + smiley print, filled"""
    tshirt_bag(b,hi,print_fn=print_thankyou)

def corner_contents(b, hi, W, D, H):
    n0=nfaces(b); m=sg(hi,6,12)
    prof=[(0.010,0.0),(0.012,0.06),(0.0125,0.075)]
    b.lathe(prof,m,'glass_green',c=(0,0,0),cap_top=False,cap_bot=False)
    b.lathe([(0.0125,0.075),(0.0135,0.077),(0.0135,0.092),(0.0,0.092)],m,'cap_red',c=(0,0,0),cap_top=False,cap_bot=False)
    place(b,n0,M_rot('Y',0.25),(W*0.16,0.0,H-0.035))

def bag_plastic_corner(b, hi=False):
    """small pale-blue corner-shop bag, unprinted, a soda bottle neck poking out of the knot"""
    tshirt_bag(b,hi,W=0.24,D=0.12,H=0.27,key='film_blue',hh=0.12,contents=corner_contents,fine=False)

def print_tote(pl):
    ink='ink_green'
    pl.text('CORONADO',0.024,(0,0.030),ink); pl.text('FRESH',0.046,(0,-0.004),ink)
    pl.rect(-0.07,-0.032,0.07,-0.029,ink); pl.text('REUSE ME  ·  100x',0.013,(0,-0.046),ink)
    pl.poly([(0.052,0.040),(0.070,0.062),(0.074,0.044),(0.058,0.036)],'leaf_green')

def bag_tote_woven(b, hi=False):
    """reusable woven-PP grocery tote: boxy, bound top edge, long flat strap handles stitched down the faces,
    printed white label panel"""
    W,D,H=0.38,0.20,0.32
    b.cur_sym=2
    for rot in (0.0,math.pi):
        n0=nfaces(b)
        b.box((0,-D/2+0.001,0),(W,0.002,H),'woven_b',skip=('back',),ch=0)
        b.box((-W/2+0.001,-D/4,0),(0.002,D/2,H),'woven_b',skip=('right',),ch=0)
        b.box((0,-D/2+0.0005,H-0.028),(W+0.003,0.004,0.028),'band_b',skip=('back','bottom'),ch=0)
        b.box((0,-D/2+0.0038,0.002),(W-0.006,0.0015,H-0.03),'woven_in',skip=('front',),ch=0)
        for x in (-0.085,0.085):
            b.box((x,-D/2-0.0012,0.04),(0.030,0.0012,H-0.04),'band_b',skip=('back','bottom'),ch=0)
        P=[V(-0.085,-D/2-0.0015,H-0.03),V(-0.084,-D/2-0.003,H+0.035),V(-0.062,-D/2+0.02,H+0.095),V(0,-0.03,H+0.13),V(0.062,-D/2+0.02,H+0.095),V(0.084,-D/2-0.003,H+0.035),V(0.085,-D/2-0.0015,H-0.03)]
        if not hi: P=[P[0],P[1],P[2],P[3],P[4],P[5],P[6]]
        ribbon(b,P,0.030,'band_b',hi,t=0.0012)
        if rot: xform(b,n0,lambda co: M_rot('Z',math.pi)@co)
    b.box((0,0,0),(W,D,0.002),'woven_b',skip=('top',),ch=0); b.box((0,0,0.004),(W-0.006,D-0.006,0.001),'woven_in',skip=('bottom',),ch=0)
    b.cur_sym=1
    decal(b,hi,(0,-D/2-0.0016,0.14),(1,0,0),(0,0,1),0.17,0.12,'label_white',print_tote)
    decal(b,hi,(0,D/2+0.0016,0.14),(-1,0,0),(0,0,1),0.17,0.12,'label_white',print_tote)
    b.cbox((0,0,0),(W,D,H))

# ================================================================== briefcases (trims only, no bake slot)
def briefcase_leather(b, hi=False):
    """classic attache: brown pebble leather hard case, darker piping on the lid seam, brass latches with
    combination wheels, brass handle mounts, stitched leather handle, brass feet"""
    W,D,H=0.44,0.11,0.32; zs=H*0.80
    b.box((0,0,0.004),(W,D,zs-0.004),'lea_br',ch=0.012)
    b.box((0,0.002,zs+0.002),(W-0.002,D-0.004,H-zs-0.002),'lea_br',ch=0.012)
    b.box((0,0.001,zs-0.003),(W+0.003,D+0.003,0.006),'lea_dk',ch=0.002)                 # piping on the lid seam
    for x in (-0.15,0.15):
        b.box((x,-D/2-0.004,zs-0.018),(0.050,0.006,0.036),'brass',ch=0.003)            # latch plates
        b.box((x,-D/2-0.0075,zs-0.006),(0.030,0.004,0.014),'brass_dk',ch=0.0015)
    for x in (-0.095,0.095):
        b.box((x,-D/2-0.003,zs-0.012),(0.034,0.004,0.016),'brass',ch=0.002)            # combination wheels
        b.box((x,-D/2-0.0052,zs-0.010),(0.024,0.0016,0.010),'lea_dk',skip=('top','bottom','back'),ch=0)
    for x in (-0.065,0.065):
        b.box((x,0,H-0.002),(0.026,0.022,0.012),'brass',ch=0.003)                        # handle mounts
    handle_arc(b,-0.062,0.062,0,H+0.010,0.040,0.0085,'lea_dk',hi,n=sg(hi,6,14),flat=0.75)
    for x in (-W/2+0.03,W/2-0.03):
        for y in (-D/2+0.02,D/2-0.02): b.box((x,y,0),(0.012,0.012,0.004),'brass',ch=0)
    b.cbox((0,0,0),(W,D,H))

def briefcase_aluminium(b, hi=False):
    """aluminium hard case: brushed shells with pressed ribs, black ABS frame band and corner caps, chrome latches,
    black ABS handle"""
    W,D,H=0.46,0.13,0.33
    b.box((0,0,0),(W,D,H),'alu',ch=0.008)
    b.box((0,0,-0.003),(W+0.008,0.022,H+0.006),'abs_blk',ch=0.004)                         # frame band (mid-depth)
    for y in (-D/2,D/2):
        sgn=-1 if y<0 else 1
        for z in (0.07,0.165,0.26): b.box((0,y+sgn*0.002,z),(W-0.07,0.004,0.010),'alu',skip=('back',) if sgn<0 else ('front',),ch=0)  # ribs
    for x in (-W/2+0.02,W/2-0.02):
        for z in (0.0,H-0.03):
            for y in (-D/2+0.02,D/2-0.02): b.box((x,y,z-0.002),(0.040,0.040,0.030),'abs_blk',ch=0)
    for x in (-0.15,0.15): b.box((x,-0.013,H+0.002),(0.05,0.026,0.010),'chrome',ch=0.003)
    for x in (-0.06,0.06): b.box((x,0,H+0.002),(0.028,0.030,0.016),'abs_blk',ch=0.004)
    handle_arc(b,-0.058,0.058,0,H+0.014,0.034,0.010,'abs_blk',hi,n=sg(hi,6,14),flat=0.8)
    b.cbox((0,0,0),(W,D,H))

def briefcase_laptop(b, hi=False):
    """soft navy nylon laptop bag: padded rounded body, front zip pocket with a pull, black webbing handles
    meeting in a leather wrap, chrome D-rings for the shoulder strap"""
    W,D,H=0.40,0.085,0.29
    zs=[0.0,0.012,H*0.5,H-0.014,H] if not hi else [0.0,0.004,0.012,0.03,H*0.25,H*0.5,H*0.75,H-0.03,H-0.012,H-0.004,H]
    rings=[]
    for z in zs:
        t=z/H; edge=min(z,H-z)
        sh=min(1.0,0.55+edge/0.025*0.45)
        bul=1+0.10*math.sin(math.pi*t)
        rings.append(sring(0,0,z,W/2*(0.985 if edge<0.002 else 1.0),D/2*sh*bul,sg(hi,12,32),6.0))
    loft(b,rings,'nyl_navy',cap0=True,cap1=True)
    # front pocket (padded panel) + zip
    pr=[]
    for z in ([0.03,0.04,0.17,0.185] if not hi else [0.03,0.035,0.045,0.10,0.17,0.18,0.185]):
        edge=min(z-0.03,0.185-z); sh=min(1.0,0.35+edge/0.012*0.65)
        pr.append(sring(0,-D/2*1.02,z,0.165,0.022*sh,sg(hi,10,28),5.0))
    loft(b,pr,'nyl_navy2',cap0=False,cap1=True)
    b.box((0,-D/2*1.02-0.0235,0.162),(0.29,0.004,0.006),'zip_blk',ch=0)
    b.box((0.10,-D/2*1.02-0.027,0.140),(0.010,0.003,0.024),'chrome',ch=0)
    b.box((0,-D/2-0.0008,0.215),(0.05,0.002,0.022),'lea_dk',ch=0)                           # logo patch
    for sgn in (-1,1):   # top zip along the spine
        pass
    b.box((0,0,H-0.001),(W-0.05,0.008,0.003),'zip_blk',ch=0)
    for x in (-W/2-0.006,W/2+0.006):
        b.box((x,0,H-0.03),(0.006,0.020,0.022),'lea_dk',ch=0)
        n0=nfaces(b); b.sweep([V(0,0,0),V(0,0.012,0.012),V(0,0,0.024),V(0,-0.012,0.012),V(0,0,0)],0.0025,sg(hi,3,6),'chrome',cap0=False,cap1=False)
        place(b,n0,None,(x+(0.004 if x>0 else -0.004),0,H-0.012))
    for sgn in (-1,1):
        P=[V(-0.085,sgn*(D/2*0.95),H-0.06),V(-0.08,sgn*0.030,H+0.02),V(-0.04,sgn*0.010,H+0.065),V(0,sgn*0.006,H+0.075),V(0.04,sgn*0.010,H+0.065),V(0.08,sgn*0.030,H+0.02),V(0.085,sgn*(D/2*0.95),H-0.06)]
        ribbon(b,P,0.026,'web_blk',hi,t=0.0015)
    b.box((0,0,H+0.062),(0.10,0.030,0.024),'lea_dk',ch=0.006)                                # handle wrap
    b.cbox((0,0,0),(W,D+0.02,H))

# ================================================================== backpacks (held by the top haul loop)
def pack_body(b, hi, W, D, H, key, top=0.06):
    zs=[0.0,0.03,H*0.45,H-top,H-top*0.35,H] if not hi else [0.0,0.008,0.03,0.08,H*0.25,H*0.45,H*0.65,H-top,H-top*0.6,H-top*0.3,H-top*0.1,H]
    rings=[]
    for z in zs:
        t=z/H; dome=1.0 if z<=H-top else math.sqrt(max(0.04,1-((z-(H-top))/top)**2))
        sh=min(1.0,0.62+z/0.03*0.38)
        a=W/2*(0.92+0.08*math.sin(math.pi*t))*dome; bb=D/2*sh*(0.88+0.12*math.sin(math.pi*t))*dome
        rings.append(sring(0,0,z,a,bb,sg(hi,10,30),3.6))
    loft(b,rings,key,cap0=True,cap1=True)
    return rings

def pack_pocket(b, hi, W, D, z0, z1, ydepth, key, y0):
    pr=[]
    zz=[z0,z0+0.01,(z0+z1)/2,z1-0.01,z1] if not hi else [z0+(z1-z0)*k/10 for k in range(11)]
    for z in zz:
        edge=min(z-z0,z1-z); sh=min(1.0,0.30+edge/0.03*0.70)
        pr.append(sring(0,y0,z,W/2,ydepth*sh,sg(hi,10,26),3.0))
    loft(b,pr,key,cap0=True,cap1=True)

def shoulder_straps(b, hi, D, H, key, xs=0.06, xb=0.11):
    for sgn in (-1,1):
        P=[V(sgn*xs,D/2*0.8,H-0.05),V(sgn*(xs+0.01),D/2+0.016,H-0.10),V(sgn*(xs+0.03),D/2+0.024,H*0.55),V(sgn*(xb-0.01),D/2+0.020,H*0.25),V(sgn*xb,D/2*0.9,0.05)]
        n0=nfaces(b); ribbon(b,P,0.060,key,hi,t=0.007,w1=0.030,pn=(0,1,0))
        xform(b,n0,lambda co: co)   # (straps lie on the back panel)

def haul_loop(b, hi, y, z, key, w=0.022):
    P=[V(-0.035,y,z-0.004),V(-0.026,y,z+0.022),V(0,y,z+0.034),V(0.026,y,z+0.022),V(0.035,y,z-0.004)]
    ribbon(b,P,w,key,hi,t=0.0015,pn=(0,1,0),across=True)

def zip_line(b, hi, W, D, H, top, key, y0=0.0, frac=0.86):
    """zip track running round the front of the dome"""
    n=sg(hi,7,20); pts=[]
    for k in range(n+1):
        t=math.pi*(1-frac)/2+math.pi*frac*k/n
        pts.append(V(-W/2*0.86*math.cos(t),-D/2*0.9*math.sin(t)+y0,H-top*0.55+0.02*math.sin(t)))
    b.sweep(pts,0.003,3,key,cap0=False,cap1=False)

def backpack_daypack(b, hi=False):
    """navy nylon daypack: domed body, red front pocket with zip, black padded shoulder straps, webbing haul loop"""
    W,D,H=0.29,0.17,0.43
    pack_body(b,hi,W,D,H,'nyl_navy',top=0.07)
    pack_pocket(b,hi,0.21,D,0.05,0.23,0.035,'nyl_red',-D/2*0.92)
    b.box((0,-D/2*0.92-0.035,0.218),(0.17,0.004,0.005),'zip_blk',ch=0)
    b.box((0.06,-D/2*0.92-0.037,0.198),(0.008,0.003,0.026),'web_blk',ch=0)
    zip_line(b,hi,W,D,H,0.07,'zip_blk')
    shoulder_straps(b,hi,D,H,'nyl_blk')
    haul_loop(b,hi,0.02,H-0.004,'web_blk')
    b.box((0,-D/2*0.92-0.0365,0.12),(0.045,0.002,0.018),'abs_wht',ch=0)                      # logo tab
    b.cbox((0,0,0),(W,D+0.05,H))

def backpack_school(b, hi=False):
    """grey school backpack: bigger body, two stacked teal-trimmed front pockets, side mesh pocket with a water bottle"""
    W,D,H=0.32,0.20,0.46
    pack_body(b,hi,W,D,H,'nyl_grey',top=0.08)
    pack_pocket(b,hi,0.24,D,0.04,0.18,0.040,'nyl_grey2',-D/2*0.92)
    pack_pocket(b,hi,0.20,D,0.20,0.31,0.025,'nyl_teal',-D/2*0.94)
    b.box((0,-D/2*0.92-0.040,0.17),(0.20,0.004,0.005),'zip_blk',ch=0)
    b.box((0,-D/2*0.94-0.025,0.30),(0.16,0.004,0.005),'zip_blk',ch=0)
    zip_line(b,hi,W,D,H,0.08,'nyl_teal')
    shoulder_straps(b,hi,D,H,'nyl_blk',xs=0.065,xb=0.12)
    haul_loop(b,hi,0.025,H-0.004,'web_blk')
    # side mesh pocket + bottle
    n0=nfaces(b); m=sg(hi,8,16)
    b.lathe([(0.034,0.0),(0.034,0.17),(0.030,0.19),(0.014,0.205),(0.014,0.22),(0.0,0.22)],m,'abs_blue',c=(0,0,0),cap_top=False,cap_bot=True)
    place(b,n0,None,(W/2+0.022,0.0,0.03))
    b.box((W/2+0.012,0,0.03),(0.046,0.10,0.09),'web_blk',ch=0.006)
    b.cbox((0,0,0),(W+0.06,D+0.05,H))

def backpack_canvas(b, hi=False):
    """olive canvas rucksack: drawstring body, brown leather top flap with two straps + brass buckles, leather base"""
    W,D,H=0.30,0.17,0.42
    zs=[0.0,0.03,H*0.5,H-0.02,H] if not hi else [0.0,0.008,0.03,0.08,H*0.25,H*0.5,H*0.75,H-0.04,H-0.02,H-0.008,H]
    rings=[sring(0,0,z,W/2*(0.95+0.05*math.sin(math.pi*z/H))*(0.9 if z>=H-0.001 else 1.0),D/2*min(1.0,0.65+z/0.03*0.35)*(0.9 if z>=H-0.001 else 1.0),sg(hi,10,30),3.4) for z in zs]
    loft(b,rings,'canvas_ol',cap0=True,cap1=True)
    b.box((0,0,0),(W+0.004,D*0.9,0.05),'lea_br',ch=0.010)                                   # leather base
    # flap: over the top and down the front
    n=sg(hi,4,10); pts=[]
    for k in range(n+1):
        t=k/n; a=math.pi/2*t
        pts.append(V(0,D/2*0.85-(D*0.92)*math.sin(a)-0.004,H+0.012-0.012*math.sin(a)-(0.0)))
    pts+= [V(0,-D/2-0.010,H-0.06),V(0,-D/2-0.012,H-0.12)]
    ribbon(b,pts,0.25,'lea_br',hi,t=0.0030,pn=(1,0,0),across=True)
    for x in (-0.07,0.07):
        b.box((x,-D/2-0.004,0.12),(0.022,0.006,0.17),'lea_dk',ch=0)                         # straps on the front
        b.box((x,-D/2-0.010,H-0.16),(0.030,0.006,0.030),'brass',ch=0.003)                    # buckles
        b.box((x,-D/2-0.0125,H-0.15),(0.022,0.003,0.010),'lea_dk',ch=0)
    shoulder_straps(b,hi,D,H,'lea_dk',xs=0.055,xb=0.11)
    haul_loop(b,hi,0.03,H+0.016,'lea_dk',w=0.020)
    b.cbox((0,0,0),(W,D+0.05,H))

# ================================================================== cardboard boxes (kraft board trim, baked labels)
def card_box(b, W, D, H, key='board', ch=0.004, tape=True, tape_ends=0.07, seam=True):
    b.box((0,0,0),(W,D,H),key,ch=ch)
    if seam: b.box((0,0,H),(W-0.006,0.003,0.0006),'board_dk',ch=0)
    if tape:
        b.box((0,0,H+0.0004),(W+0.0016,0.048,0.0008),'tape',ch=0)
        for sx in (-1,1):
            b.box((sx*(W/2+0.0004),0,H-tape_ends),(0.0008,0.048,tape_ends+0.0012),'tape',ch=0)

def ship_label(pl):
    k='ink_black'
    pl.rect(-0.050,0.026,0.050,0.034,k); pl.text('PRIORITY',0.007,(-0.026,0.0305),'ink_white')
    pl.text('SHIP TO:',0.006,(-0.036,0.018),k)
    for i,w in enumerate((0.060,0.072,0.050)): pl.rect(-0.046,0.010-0.007*i,-0.046+w,0.0125-0.007*i,k)
    barcode(pl,-0.046,-0.030,0.080,0.014,k); pl.text('1Z 84F 2A0 03 9921 4467',0.0045,(-0.006,-0.034),k)
    pl.rect(0.030,0.004,0.046,0.020,k)

def box_ship_small(b, hi=False):
    """small taped shipping box with a printed shipping label"""
    W,D,H=0.30,0.22,0.16
    card_box(b,W,D,H)
    decal(b,hi,(0.035,0.055,H+0.0012),(1,0,0),(0,1,0),0.105,0.075,'label_white',ship_label)
    b.cbox((0,0,0),(W,D,H))

def fragile_tape(pl):
    for u in (-0.15,0.0,0.15): pl.text('FRAGILE',0.020,(u,0.0),'ink_white')
    for u in (-0.075,0.075): pl.rect(u-0.008,-0.008,u+0.008,0.008,'ink_white')

def marker_kitchen(pl):
    pl.text('KITCHEN',0.050,(0,0.010),'ink_black',font=FONT_MARK); pl.rect(-0.10,-0.030,0.07,-0.026,'ink_black')
    pl.text('plates + glasses',0.020,(0,-0.050),'ink_black',font=FONT_MARK)

def box_moving(b, hi=False):
    """medium moving box: hand-holes, red FRAGILE tape over the top, KITCHEN in marker"""
    W,D,H=0.45,0.35,0.35
    card_box(b,W,D,H,tape=False)
    for sx in (-1,1):
        b.box((sx*(W/2+0.0003),0,H*0.72),(0.0012,0.11,0.035),'hole',ch=0)
    decal(b,hi,(0,0,H+0.0009),(1,0,0),(0,1,0),W+0.002,0.050,'tape_red',fragile_tape)
    for sx in (-1,1):
        decal(b,hi,(sx*(W/2+0.0009),0,H-0.035),(0,-sx,0),(0,0,1),0.050,0.070,'tape_red') if False else None
        b.box((sx*(W/2+0.0005),0,H-0.07),(0.0008,0.050,0.0712),'tape_r',ch=0)
    decal(b,hi,(0,-D/2-0.0008,0.18),(1,0,0),(0,0,1),0.26,0.14,'label_white',marker_kitchen)
    b.cbox((0,0,0),(W,D,H))

def box_open(b, hi=False):
    """open box, four flaps splayed, crumpled packing paper and two books inside"""
    W,D,H=0.40,0.30,0.28; t=0.004
    b.box((0,0,0),(W,D,H),'board',skip=('top',),ch=0.003)
    n0=nfaces(b); b.box((0,0,0.002),(W-2*t,D-2*t,H-0.002),'board_in',skip=('top',),ch=0)
    for f in list(b.bm.faces)[n0:]: f.normal_flip()
    b.box((0,-D/2+t/2,H),(W,t,0.0012),'board',ch=0); b.box((0,D/2-t/2,H),(W,t,0.0012),'board',ch=0)
    b.box((-W/2+t/2,0,H),(t,D,0.0012),'board',ch=0); b.box((W/2-t/2,0,H),(t,D,0.0012),'board',ch=0)
    for sy in (-1,1):   # long flaps (hinge along X)
        n0=nfaces(b); b.box((0,sy*0.075,0),(W-0.004,0.150,0.003),'board',ch=0)
        place(b,n0,M_rot('X',sy*math.radians(-118)),(0,sy*D/2,H)) if False else None
        xform(b,n0,lambda co,sy=sy: M_rot('X',sy*math.radians(-62))@V(co.x,co.y,co.z)+V(0,sy*D/2,H))
    for sx in (-1,1):   # short flaps
        n0=nfaces(b); b.box((sx*0.07,0,0),(0.140,D-0.004,0.003),'board',ch=0)
        xform(b,n0,lambda co,sx=sx: M_rot('Y',sx*math.radians(70))@V(co.x,co.y,co.z)+V(sx*W/2,0,H))
    for (x,y,r) in ((-0.10,0.06,0.075),(0.0,-0.05,0.08),(0.11,0.07,0.07),(0.06,-0.08,0.06)):
        blob(b,(x,y,H-0.045),r,'paper_crumple',hi,squash=(1.0,0.9,0.55),n=sg(hi,6,14))
    b.box((-0.05,0.02,H-0.11),(0.16,0.22,0.035),'book_red',ch=0.004,rz=0.15,rx=0.35)
    b.cbox((0,0,0),(W,D,H))

def this_side_up(pl):
    k='ink_black'
    for u in (-0.17,0.17):
        pl.rect(u-0.004,-0.030,u+0.004,0.010,k); pl.poly([(u-0.014,0.008),(u+0.014,0.008),(u,0.030)],k)
    pl.text('THIS SIDE UP',0.024,(0,0.012),k); pl.text('DESK LAMP  ·  MODEL CL-40  ·  BRASS',0.011,(0,-0.020),k)
    # lamp line drawing
    pl.rect(-0.10,-0.060,-0.04,-0.056,k); pl.rect(-0.072,-0.056,-0.068,-0.030,k)
    pl.poly([(-0.068,-0.032),(-0.064,-0.034),(-0.040,-0.010),(-0.044,-0.008)],k)
    pl.poly([(-0.050,-0.004),(-0.020,-0.012),(-0.028,-0.030),(-0.056,-0.020)],k)
    barcode(pl,0.03,-0.065,0.07,0.020,k,seed=8)

def box_long(b, hi=False):
    """long product box (desk lamp), taped ends, printed THIS SIDE UP side"""
    W,D,H=0.70,0.22,0.18
    card_box(b,W,D,H,tape_ends=0.06)
    decal(b,hi,(0,-D/2-0.0008,H*0.5),(1,0,0),(0,0,1),0.40,0.14,'kraft_board',this_side_up)
    b.cbox((0,0,0),(W,D,H))

def box_stack(b, hi=False):
    """two taped boxes stacked (carried as one), label on the top box"""
    card_box(b,0.42,0.32,0.24)
    n0=nfaces(b); card_box(b,0.32,0.25,0.18)
    xform(b,n0,lambda co: M_rot('Z',0.12)@co+V(0.02,-0.01,0.24))
    decal(b,hi,(0.03,-0.01,0.4212),(math.cos(0.12),math.sin(0.12),0),(-math.sin(0.12),math.cos(0.12),0),0.105,0.075,'label_white',ship_label)
    b.cbox((0,0,0),(0.42,0.32,0.42))

def citrus_print(pl):
    pl.disc(-0.12,0.0,0.030,'ink_orange',n=18); pl.poly([(-0.118,0.028),(-0.098,0.048),(-0.094,0.034),(-0.110,0.026)],'ink_green')
    pl.text('CORONADO',0.026,(0.03,0.016),'ink_green'); pl.text('CITRUS',0.040,(0.03,-0.018),'ink_orange')
    pl.text('NAVEL ORANGES  ·  40 LB',0.011,(0.03,-0.044),'ink_green')

def box_produce(b, hi=False):
    """open produce box with hand-holes, printed citrus brand, oranges"""
    W,D,H=0.46,0.30,0.20; t=0.004
    b.box((0,0,0),(W,D,H),'board_w',skip=('top',),ch=0.003)
    n0=nfaces(b); b.box((0,0,0.002),(W-2*t,D-2*t,H-0.002),'board_in',skip=('top',),ch=0)
    for f in list(b.bm.faces)[n0:]: f.normal_flip()
    b.box((0,-D/2+t/2,H),(W,t,0.0012),'board_w',ch=0); b.box((0,D/2-t/2,H),(W,t,0.0012),'board_w',ch=0)
    b.box((-W/2+t/2,0,H),(t,D,0.0012),'board_w',ch=0); b.box((W/2-t/2,0,H),(t,D,0.0012),'board_w',ch=0)
    for sx in (-1,1): b.box((sx*(W/2+0.0003),0,H-0.06),(0.0012,0.10,0.032),'hole',ch=0)
    decal(b,hi,(0,-D/2-0.0008,H*0.5),(1,0,0),(0,0,1),0.34,0.12,'paper_white',citrus_print)
    decal(b,hi,(0,D/2+0.0008,H*0.5),(-1,0,0),(0,0,1),0.34,0.12,'paper_white',citrus_print)
    r=0.038; k=0
    for i,x in enumerate((-0.16,-0.08,0.0,0.08,0.16)):
        for j,y in enumerate((-0.08,0.0,0.08)):
            if (i+j)%2==1 and not (i==2): continue
            if (i,j) in ((0,2),(4,0)): continue      # two gaps: the box is not brim full
            blob(b,(x+0.01*((i*7+j)%3-1),y,H-0.040+0.006*((i+j)%2)),r,'orange_peel',hi,squash=(1,1,0.94),n=sg(hi,8,16),bot_cap=hi,upper=not hi); k+=1
    b.cbox((0,0,0),(W,D,H))

# ================================================================== wooden crates (pine trim)
def crate_produce(b, hi=False):
    """slatted pine produce crate: corner posts, three side slats, solid ends with a hand slot, stencilled end"""
    W,D,H=0.50,0.32,0.28; s=0.012
    for x in (-W/2+0.016,W/2-0.016):
        for y in (-D/2+0.016,D/2-0.016): b.box((x,y,0),(0.026,0.026,H),'pine',ch=0.003)
    for y in (-D/2+s/2,D/2-s/2):
        for z in (0.02,0.11,0.20): b.box((0,y,z),(W,s,0.07),'pine2',ch=0.003)
    for x in (-W/2+s/2,W/2-s/2):
        b.box((x,0,0.0),(s,D-0.05,0.19),'pine',ch=0); b.box((x,0,0.235),(s,D-0.05,0.045),'pine',ch=0)
    for y in (-0.10,0.0,0.10): b.box((0,y,0.0),(W-0.05,0.08,s),'pine2',skip=('bottom',),ch=0)
    for sx in (-1,1):
        decal(b,hi,(sx*(W/2+0.0008),0,0.10),(0,sx,0),(0,0,1),0.22,0.13,'pine_d',lambda pl: (pl.text('CORONADO',0.036,(0,0.034),'ink_black',font=FONT_STEN),pl.text('FARMS',0.052,(0,-0.012),'ink_black',font=FONT_STEN),pl.text('GROWN IN CALIFORNIA',0.014,(0,-0.050),'ink_black',font=FONT_STEN)))
    b.cbox((0,0,0),(W,D,H))

def wine_brand(pl):
    k='ink_black'
    pl.ring(0,0.026,0.020,0.023,k,n=24); pl.text('C',0.026,(0,0.024),k,font=FONT_CINZ)
    pl.text('CORONADO CELLARS',0.020,(0,-0.012),k,font=FONT_CINZ); pl.rect(-0.08,-0.026,0.08,-0.0245,k)
    pl.text('CABERNET  ·  1952  ·  RESERVE',0.010,(0,-0.038),k,font=FONT_SANS)

def crate_wine(b, hi=False):
    """small closed wine crate, boxed corners, sliding lid with a finger notch, burnt-in brand on the lid"""
    W,D,H=0.34,0.18,0.18; t=0.012
    b.box((0,-D/2+t/2,0),(W,t,H-t),'pine_w',ch=0.002); b.box((0,D/2-t/2,0),(W,t,H-t),'pine_w',ch=0.002)
    b.box((-W/2+t/2,0,0),(t,D-2*t,H-t),'pine_w2',ch=0.002); b.box((W/2-t/2,0,0),(t,D-2*t,H-t),'pine_w2',ch=0.002)
    b.box((0,0,0),(W-2*t,D-2*t,t),'pine_w',skip=('top',),ch=0)
    b.box((0.006,0,H-t),(W,D-0.004,t),'pine',ch=0.002)
    b.box((W/2-0.02,0,H),(0.012,0.05,0.0008),'board_dk',ch=0)
    decal(b,hi,(0,0,H+0.0008),(1,0,0),(0,1,0),0.20,0.12,'pine_d',wine_brand)
    b.cbox((0,0,0),(W,D,H))

def crate_rope(b, hi=False):
    """dark-stained storage box with lid, black steel corner brackets and jute rope handles at the ends"""
    W,D,H=0.50,0.30,0.25
    b.box((0,0,0),(W,D,H-0.05),'pine_dk',ch=0.006)
    b.box((0,0,H-0.052),(W+0.006,D+0.006,0.052),'pine_dk',ch=0.006)
    for z in (0.065,0.13): b.box((0,-D/2-0.0007,z),(W-0.02,0.0014,0.003),'board_dk',ch=0)       # plank joints
    for sx in (-1,1):
        for sy in (-1,1):
            for z,o in ((0.0,0.0),(H-0.058,0.003)):
                x=sx*(W/2+o); y=sy*(D/2+o)
                b.box((x-sx*0.022,y+sy*0.0012,z),(0.046,0.0024,0.058),'iron',skip=('back',) if sy<0 else ('front',),ch=0)
                b.box((x+sx*0.0012,y-sy*0.022,z),(0.0024,0.046,0.058),'iron',skip=('right',) if sx<0 else ('left',),ch=0)
    for sx in (-1,1):
        n0=nfaces(b); pts=[V(0,-0.055,0),V(0.012,-0.05,-0.02),V(0.02,-0.03,-0.035),V(0.022,0,-0.04),V(0.02,0.03,-0.035),V(0.012,0.05,-0.02),V(0,0.055,0)]
        b.sweep(pts,0.007,sg(hi,4,10),'rope_kraft',cap0=True,cap1=True)
        xform(b,n0,lambda co,sx=sx: V(sx*(W/2+0.004+co.x),co.y,co.z+0.15))
        for y in (-0.055,0.055): b.box((sx*(W/2+0.002),y,0.135),(0.006,0.024,0.030),'iron',ch=0.002)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ registry
TR.update({'film_t':('film',(0.48,0.48)),'pine_w':('pine',(0.48,0.48)),'pine_w2':('pine',(0.48,0.48)),'white_g':('paper_white',(0.48,0.48)),'kraft_g':('kraft_paper',(0.48,0.48)),'kraft_h':('kraft_paper',(0.48,0.48)),
 'crust':('bread_crust',(0.48,0.48)),'glass_g':('glass_green',(0.48,0.48)),'cap_r':('cap_red',(0.48,0.48)),'white_in':('paper_white',(0.48,0.48)),'white_in_bot':('paper_white',(0.48,0.48)),'white_patch':('paper_white',(0.48,0.48)),
 'film_blue':('film',(0.48,0.48)),'woven_b':('woven',(0.24,0.24)),'woven_in':('woven',(0.24,0.24)),'band_b':('webbing',(0.24,0.24)),
 'lea_br':('leather',(0.48,0.48)),'lea_dk':('leather',(0.48,0.48)),'brass':('metal',(0.48,0.48)),'brass_dk':('metal',(0.48,0.48)),
 'alu':('metal',(0.48,0.48)),'chrome':('metal',(0.48,0.48)),'abs_blk':('abs',(0.48,0.48)),'abs_wht':('abs',(0.48,0.48)),'abs_blue':('abs',(0.48,0.48)),
 'nyl_navy':('nylon',(0.24,0.24)),'nyl_navy2':('nylon',(0.24,0.24)),'nyl_red':('nylon',(0.24,0.24)),'nyl_blk':('nylon',(0.24,0.24)),
 'nyl_grey':('nylon',(0.24,0.24)),'nyl_grey2':('nylon',(0.24,0.24)),'nyl_teal':('nylon',(0.24,0.24)),'zip_blk':('abs',(0.48,0.48)),
 'web_blk':('webbing',(0.24,0.24)),'canvas_ol':('canvas',(0.24,0.24)),
 'board':('kraft_board',(0.48,0.48)),'board_w':('kraft_board',(0.48,0.48)),'board_in':('kraft_board',(0.48,0.48)),'board_dk':('kraft_board',(0.48,0.48)),
 'hole':('kraft_board',(0.48,0.48)),'tape':('tape',(0.48,0.48)),'tape_r':('tape',(0.48,0.48)),'paper_crumple':('paper_white',(0.48,0.48)),
 'book_red':('abs',(0.48,0.48)),'pine':('pine',(0.48,0.48)),'pine2':('pine',(0.48,0.48)),'pine_dk':('pine',(0.48,0.48)),'iron':('metal',(0.48,0.48)),
})
TINT.update({'film_t':(1.0,1.0,1.0),'pine_w':(0.86,0.70,0.52),'pine_w2':(0.80,0.64,0.46),'white_g':(1.0,1.0,1.0),'kraft_g':(1.0,1.0,1.0),'kraft_h':(1.04,1.02,1.0),
 'crust':(1.0,1.0,1.0),'glass_g':(1.0,1.0,1.0),'cap_r':(1.0,1.0,1.0),'white_in':(1.10,1.10,1.10),'white_in_bot':(1.05,1.05,1.05),'white_patch':(1.12,1.12,1.12),
 'film_blue':(0.70,0.86,1.02),'woven_b':(0.16,0.34,0.70),'woven_in':(0.14,0.30,0.62),'band_b':(0.08,0.16,0.38),
 'lea_br':(0.56,0.33,0.18),'lea_dk':(0.30,0.17,0.09),'brass':(1.00,0.80,0.45),'brass_dk':(0.80,0.60,0.30),
 'alu':(1.02,1.02,1.03),'chrome':(1.15,1.16,1.18),'abs_blk':(0.10,0.10,0.11),'abs_wht':(1.10,1.10,1.10),'abs_blue':(0.20,0.50,0.85),
 'nyl_navy':(0.12,0.17,0.34),'nyl_navy2':(0.14,0.20,0.38),'nyl_red':(0.72,0.12,0.10),'nyl_blk':(0.10,0.10,0.11),
 'nyl_grey':(0.42,0.44,0.47),'nyl_grey2':(0.32,0.34,0.37),'nyl_teal':(0.05,0.50,0.52),'zip_blk':(0.08,0.08,0.09),
 'web_blk':(0.10,0.10,0.11),'canvas_ol':(0.50,0.52,0.34),
 'board':(1.0,1.0,1.0),'board_w':(1.04,1.02,1.0),'board_in':(0.92,0.88,0.84),'board_dk':(0.55,0.50,0.45),'hole':(0.18,0.15,0.12),
 'tape':(1.0,1.0,1.0),'tape_r':(1.05,0.24,0.18),'paper_crumple':(1.0,1.0,0.98),'book_red':(0.62,0.12,0.10),
 'pine':(1.0,1.0,1.0),'pine2':(0.95,0.92,0.88),'pine_dk':(0.50,0.34,0.22),'iron':(0.28,0.28,0.30),
})
_C=dict(dir='props/indoor/carry',pdir='indoor_carry',trim=TR,trim_tint=TINT,page='j',
        conds=['clean'],cat='prop',bevel=0.0,no_ch=True,mount='ground',cage=0.006,ray=0.02)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
IN_AO={'big':0.40,'floor':0.50,'floor_big':0.50}   # bag insides: vertex AO floor (a closed shell went black)
TB=dict(no_bake=True)       # trims only: no bake slot
# hand attach points, Blender space (Z up, front -Y); c_grips.py converts to glTF Y-up.
# one-hand props: grip_r = grip_l at the handle (+X along the bar); boxes / crates: grip_l on the -X face, grip_r on +X
GRIPS={
    'bag_paper_kraft':{'grip_r':(0.0,0.0,0.40+0.100),'grip_l':(0.0,0.0,0.40+0.100),'hold':'one_hand_hang'},
    'bag_paper_boutique':{'grip_r':(0.0,0.0,0.28+0.085),'grip_l':(0.0,0.0,0.28+0.085),'hold':'one_hand_hang'},
    'bag_paper_grocery':{'grip_r':(0.0,0.0,0.38+0.090),'grip_l':(0.0,0.0,0.38+0.090),'hold':'one_hand_hang'},
    'bag_plastic_thankyou':{'grip_r':(0.006,0.0,0.33+0.140),'grip_l':(0.006,0.0,0.33+0.140),'hold':'one_hand_hang'},
    'bag_plastic_corner':{'grip_r':(0.006,0.0,0.27+0.112),'grip_l':(0.006,0.0,0.27+0.112),'hold':'one_hand_hang'},
    'bag_tote_woven':{'grip_r':(0.0,0.0,0.32+0.125),'grip_l':(0.0,0.0,0.32+0.125),'hold':'one_hand_hang'},
    'briefcase_leather':{'grip_r':(0.0,0.0,0.32+0.040),'grip_l':(0.0,0.0,0.32+0.040),'hold':'one_hand_hang'},
    'briefcase_aluminium':{'grip_r':(0.0,0.0,0.33+0.040),'grip_l':(0.0,0.0,0.33+0.040),'hold':'one_hand_hang'},
    'briefcase_laptop':{'grip_r':(0.0,0.0,0.29+0.072),'grip_l':(0.0,0.0,0.29+0.072),'hold':'one_hand_hang'},
    'backpack_daypack':{'grip_r':(0.0,0.02,0.43+0.024),'grip_l':(0.0,0.02,0.43+0.024),'hold':'one_hand_hang'},
    'backpack_school':{'grip_r':(0.0,0.025,0.46+0.024),'grip_l':(0.0,0.025,0.46+0.024),'hold':'one_hand_hang'},
    'backpack_canvas':{'grip_r':(0.0,0.03,0.42+0.044),'grip_l':(0.0,0.03,0.42+0.044),'hold':'one_hand_hang'},
    'box_ship_small':{'grip_l':(-0.15,0.0,0.07),'grip_r':(0.15,0.0,0.07),'hold':'two_hand_sides'},
    'box_moving':{'grip_l':(-0.225,0.0,0.252),'grip_r':(0.225,0.0,0.252),'hold':'two_hand_sides'},
    'box_open':{'grip_l':(-0.20,0.0,0.12),'grip_r':(0.20,0.0,0.12),'hold':'two_hand_sides'},
    'box_long':{'grip_l':(-0.30,0.0,0.08),'grip_r':(0.30,0.0,0.08),'hold':'two_hand_sides'},
    'box_stack':{'grip_l':(-0.21,0.0,0.10),'grip_r':(0.21,0.0,0.10),'hold':'two_hand_sides'},
    'box_produce':{'grip_l':(-0.23,0.0,0.156),'grip_r':(0.23,0.0,0.156),'hold':'two_hand_sides'},
    'crate_produce':{'grip_l':(-0.25,0.0,0.257),'grip_r':(0.25,0.0,0.257),'hold':'two_hand_sides'},
    'crate_wine':{'grip_l':(-0.17,0.0,0.08),'grip_r':(0.17,0.0,0.08),'hold':'two_hand_sides'},
    'crate_rope':{'grip_l':(-0.27,0.0,0.115),'grip_r':(0.27,0.0,0.115),'hold':'two_hand_sides'},
}
PROPS=[
    _p('bag_paper_kraft',bag_paper_kraft,'tiny',300,side=192,trim_ao=IN_AO),
    _p('bag_paper_boutique',bag_paper_boutique,'tiny',300,side=192,trim_ao=IN_AO),
    _p('bag_paper_grocery',bag_paper_grocery,'tiny',300,side=192,trim_ao=IN_AO),
    _p('bag_plastic_thankyou',bag_plastic_thankyou,'tiny',300,side=192,cage=0.010,ray=0.03),
    _p('bag_plastic_corner',bag_plastic_corner,'tiny',300,side=32),
    _p('bag_tote_woven',bag_tote_woven,'tiny',300,side=64),
    _p('briefcase_leather',briefcase_leather,'small',600,**TB),
    _p('briefcase_aluminium',briefcase_aluminium,'small',600,**TB),
    _p('briefcase_laptop',briefcase_laptop,'small',600,**TB),
    _p('backpack_daypack',backpack_daypack,'small',600,**TB),
    _p('backpack_school',backpack_school,'small',600,**TB),
    _p('backpack_canvas',backpack_canvas,'small',600,**TB),
    _p('box_ship_small',box_ship_small,'tiny',300,side=48),
    _p('box_moving',box_moving,'tiny',300,side=96),
    _p('box_open',box_open,'tiny',300,**TB),
    _p('box_long',box_long,'tiny',300,side=96),
    _p('box_stack',box_stack,'small',600,side=48),
    _p('box_produce',box_produce,'tiny',300,side=128),
    _p('crate_produce',crate_produce,'small',600,side=96),
    _p('crate_wine',crate_wine,'small',600,side=64),
    _p('crate_rope',crate_rope,'small',600,side=32),
]
INDOOR_LOOK=True
pg.REG.setdefault('pine_d.clean',pg.REG['pine.clean'])   # baked decal backgrounds that must match the pine trim
