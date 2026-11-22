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
              ink='ink_navy', print_fn=None, hh=0.105, hx=0.055, fill=0.0):
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
            grid(b,Pg,sg(hi,1,10),sg(hi,2,48),paper,flip=True)
        # bottom (outer), front half
        grid(b,lambda s,t: V(-W/2+W*s, -D/2*(1-t), 0.0),sg(hi,1,8),sg(hi,1,4),paper,flip=True)
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
        grid(b,lambda s,t: V(-W/2+0.0008+(W-0.0016)*s, (-D/2+0.0008)*(1-t), 0.0006),1,1,inside+'_bot')
        # rim strip (top edge of the folded paper)
        P0=lambda s: V(-W/2+W*s, face_y(-W/2+W*s,H), H)
        grid(b,lambda s,t: P0(s)+V(0,off(H)*t,0),sg(hi,2,20),1,paper)
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
        b.sweep(pts,rr,sg(hi,3,10),cord,cap0=False,cap1=False)
        if rot: xform(b,n0,lambda co,R=R: R@co)
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

# ------------------------------------------------------------------ registry
_C=dict(dir='props/indoor/carry',pdir='indoor_carry',trim=TR,trim_tint=TINT,page='j',
        conds=['clean'],cat='prop',bevel=0.0,no_ch=True,mount='ground',cage=0.006,ray=0.02)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
IN_AO={'big':0.40,'floor':0.50,'floor_big':0.50}   # bag insides: vertex AO floor (a closed shell went black)
# hand attach points, Blender space (Z up, front -Y); c_grips.py converts to glTF Y-up
GRIPS={
    'bag_paper_kraft':{'grip_r':(0.0,0.0,0.40+0.100),'grip_l':(0.0,0.0,0.40+0.100),'hold':'one_hand_hang'},
}
PROPS=[
    _p('bag_paper_kraft',bag_paper_kraft,'tiny',300,side=192,trim_ao=IN_AO),
]
INDOOR_LOOK=True
