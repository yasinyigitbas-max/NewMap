"""Indoor-places props (the INDOORS spec's missing props: worship, court, lecture, clinic, ...) - original geometry,
page K (own 1024 page: rows 0-255 = the page-I trim tiles copied, bake slots from y=256; never pages A/B/C/W/H/I/J),
near + col only, one material. Real-world scale; origin at the footprint centre on the floor; FRONT = -Y in Blender
(glTF / Godot +Z: the seat front, toward the person who uses it - BuiltinLib facing convention).
Pilot (22 Nov 2026): church_pew. Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math
from mathutils import Vector
import pg
from b_inshared import TR as _TR, TINT as _TINT, maker_plate

TR=dict(_TR); TINT=dict(_TINT)
for k,t in {'pw':'ti_wood','pw_dk':'ti_wood','cush':'ti_fabric','cush_dk':'ti_fabric',
            'bk_red':'ti_fabric','bk_navy':'ti_fabric','bk_black':'ti_fabric','bk_page':'ti_paint','env':'ti_paint'}.items():
    TR[k]=(t,(0.875,0.875))
PW=(0.60,0.40,0.25)          # pew stain: warm medium-dark oak (multiplies the ti_wood oak tile)
TINT.update({'pw_dk':(0.50,0.33,0.20),'cush':(0.40,0.05,0.07),'cush_dk':(0.30,0.04,0.055),
             'bk_red':(0.55,0.09,0.08),'bk_navy':(0.10,0.13,0.30),'bk_black':(0.13,0.12,0.12),
             'bk_page':(0.95,0.92,0.84),'env':(1.0,0.98,0.94)})

V=Vector
def _orient(pts, want):
    n=V((0,0,0))
    for i in range(len(pts)): n+=pts[i].cross(pts[(i+1)%len(pts)])
    return pts if n.dot(V(want))>=0 else pts[::-1]

def arc(c, r, a0, a1, n):
    """points on a circle in the (y,z) plane, angles in degrees, a0 -> a1 inclusive"""
    return [(c[0]+r*math.cos(math.radians(a0+(a1-a0)*i/n)), c[1]+r*math.sin(math.radians(a0+(a1-a0)*i/n))) for i in range(n+1)]

def ext_x(b, prof, x0, x1, key, caps=(True,True), grain='x', skip=(), cap_key=None):
    """extrude a closed (y,z) profile along X from x0 to x1. Side quads get metre uvs with the grain (tile v) along X
    ('x') or along the outline ('arc'); caps are single n-gons (grain vertical). skip: edge indices left open (hidden)."""
    P=[V(p) for p in prof]; n=len(P)
    cy=sum(p.x for p in P)/n; cz=sum(p.y for p in P)/n
    # outline orientation: signed area in (y,z)
    A=sum(P[i].x*P[(i+1)%n].y-P[(i+1)%n].x*P[i].y for i in range(n))/2
    acc=0.0; out=[]
    for i in range(n):
        a=P[i]; c=P[(i+1)%n]; L=(c-a).length
        if i in skip or L<1e-6: acc+=L; continue
        q=[V((x0,a.x,a.y)),V((x1,a.x,a.y)),V((x1,c.x,c.y)),V((x0,c.x,c.y))]
        # outward normal in (y,z): for CCW outline (A>0) it is (dz,-dy)
        d=c-a; on=V((0, d.y, -d.x)) if A>0 else V((0,-d.y,d.x))
        if grain=='x': l=[(acc,x0),(acc,x1),(acc+L,x1),(acc+L,x0)]
        else: l=[(x0,acc),(x1,acc),(x1,acc+L),(x0,acc+L)]
        nn=(q[1]-q[0]).cross(q[3]-q[0])
        if nn.dot(on)<0: q=[q[0],q[3],q[2],q[1]]; l=[l[0],l[3],l[2],l[1]]
        out+=b.faces(q,[(0,1,2,3)],key,[l],smooth=False)
        acc+=L
    for x,want,on in ((x0,(-1,0,0),caps[0]),(x1,(1,0,0),caps[1])):
        if not on: continue
        pts=_orient([V((x,p.x,p.y)) for p in P],want)
        out+=b.faces(pts,[tuple(range(n))],cap_key or key,[[(p.y,p.z) for p in pts]],smooth=False)
    return out

def ext_y(b, prof, y0, y1, key, caps=(True,True), skip=()):
    """extrude a closed (x,z) profile along Y (front y0 -> back y1); grain along the outline; caps vertical grain"""
    P=[V(p) for p in prof]; n=len(P)
    A=sum(P[i].x*P[(i+1)%n].y-P[(i+1)%n].x*P[i].y for i in range(n))/2
    acc=0.0; out=[]
    for i in range(n):
        a=P[i]; c=P[(i+1)%n]; L=(c-a).length
        if i in skip or L<1e-6: acc+=L; continue
        q=[V((a.x,y0,a.y)),V((a.x,y1,a.y)),V((c.x,y1,c.y)),V((c.x,y0,c.y))]
        d=c-a; on=V((d.y,0,-d.x)) if A>0 else V((-d.y,0,d.x))
        l=[(y0,acc),(y1,acc),(y1,acc+L),(y0,acc+L)]
        nn=(q[1]-q[0]).cross(q[3]-q[0])
        if nn.dot(on)<0: q=[q[0],q[3],q[2],q[1]]; l=[l[0],l[3],l[2],l[1]]
        out+=b.faces(q,[(0,1,2,3)],key,[l],smooth=False); acc+=L
    for y,want,on in ((y0,(0,-1,0),caps[0]),(y1,(0,1,0),caps[1])):
        if not on: continue
        pts=_orient([V((p.x,y,p.y)) for p in P],want)
        out+=b.faces(pts,[tuple(range(n))],key,[[(p.x,p.z) for p in pts]],smooth=False)
    return out

def fq(b, pts, key, want, a, c, smooth=False):
    """one quad, wound so its normal points along want; metre uvs a x c"""
    q=_orient([V(p) for p in pts],want)
    return b.faces(q,[(0,1,2,3)],key,[[(0,0),(a,0),(a,c),(0,c)]],smooth=smooth)

def box(b, c, size, key, skip=()):
    """plain box with the grain along its longest horizontal axis (c = bottom centre)"""
    x,y,z=c; w,d,h=size
    if w>=d:
        prof=[(y-d/2,z),(y+d/2,z),(y+d/2,z+h),(y-d/2,z+h)]
        sk=tuple({'bottom':0,'back':1,'top':2,'front':3}[s] for s in skip if s in ('bottom','back','top','front'))
        return ext_x(b,prof,x-w/2,x+w/2,key,caps=('left' not in skip,'right' not in skip),skip=sk)
    prof=[(x-w/2,z),(x+w/2,z),(x+w/2,z+h),(x-w/2,z+h)]
    sk=tuple({'bottom':0,'right':1,'top':2,'left':3}[s] for s in skip if s in ('bottom','right','top','left'))
    return ext_y(b,prof,y-d/2,y+d/2,key,caps=('front' not in skip,'back' not in skip),skip=sk)

# ------------------------------------------------------------------ church_pew
PEW_W=3.00; PEW_D=0.62; PEW_H=0.95; END_T=0.05
def pew_end_profile(hi):
    s=2 if hi else 1
    p=[(-0.31,0.0),(-0.215,0.0)]
    p+=[(y,z) for y,z in arc((0.0,-0.10),0.205,180-14,14,4*s)][1:-1]        # toe-kick arch between the feet
    p+=[(0.215,0.0),(0.31,0.0),(0.31,0.80)]
    p+=arc((0.245,0.88),0.065,-12,150,5*s)                                   # rounded back ear
    p+=[(0.13,0.872),(0.05,0.826),(-0.05,0.752),(-0.15,0.698),(-0.235,0.684)] # concave sweep down to the arm
    p+=arc((-0.282,0.652),0.032,90,180,2*s)[0:]                              # arm nose
    p+=[(-0.314,0.60),(-0.298,0.44),(-0.296,0.22),(-0.31,0.07)]               # front edge: slight waist, foot flare
    out=[]
    for q in p:
        if not out or (V(q)-V(out[-1])).length>1e-4: out.append(q)
    if (V(out[0])-V(out[-1])).length<1e-4: out.pop()
    return out

def church_pew(b, hi=False, W=PEW_W):
    W=W; xe=W/2-END_T; s=2 if hi else 1
    # --- bench ends (mirror-shared bake; the outer face carries the carved panel)
    b.cur_sym=pg.MIRROR
    prof=pew_end_profile(hi)
    for sg in (-1,1):
        x0,x1=(-W/2,-xe) if sg<0 else (xe,W/2)
        ext_x(b,prof,x0,x1,'pw',grain='arc')
        if hi:
            xo=x0 if sg<0 else x1; d=-sg     # d: inward direction (+x on the left end)
            # raised field panel: gothic arch, 7 mm proud, bevelled by the high-poly bevel
            fp=[(-0.165,0.17),(0.150,0.17),(0.150,0.50)]+[(y,z) for y,z in arc((-0.0075+0.0,0.50),0.1575,0,90,6)][1:]
            fp=[(0.150,0.17),(0.150,0.50)]+arc((-0.165+0.1575*2-0.1575,0.50),0.1575,0,180,12)[1:-1]+[(-0.165,0.50),(-0.165,0.17)]
            fx0,fx1=(xo-0.013,xo) if sg<0 else (xo,xo+0.013)
            ext_x(b,fp,fx0,fx1,'pw')
            # inner bead around the field (sunk line): thin raised rim 3 mm, 12 mm wide
            # carved Latin cross on the field, 5 mm further proud
            cx0,cx1=(xo-0.024,xo-0.013) if sg<0 else (xo+0.013,xo+0.024)
            for (y,z,w_,h_) in ((-0.0075,0.24,0.034,0.30),(-0.0075,0.43,0.15,0.034)):
                ext_x(b,[(y-w_/2,z),(y+w_/2,z),(y+w_/2,z+h_),(y-w_/2,z+h_)],cx0,cx1,'pw')
            # roundel at the crossing
            ext_x(b,arc((-0.0075,0.447),0.045,0,360,16)[:-1],cx0,cx1,'pw')
            ext_x(b,arc((-0.0075,0.447),0.030,0,360,16)[:-1],(cx0-0.005) if sg<0 else cx1,(cx0) if sg<0 else cx1+0.005,'pw')
            # plinth band at the foot and a cap moulding line under the arm sweep
            ext_x(b,[(-0.300,0.075),(0.300,0.075),(0.300,0.095),(-0.300,0.095)],(xo-0.004) if sg<0 else xo,xo if sg<0 else xo+0.004,'pw')
    b.cur_sym=1
    # --- seat board with a bullnose front (top 0.40 front, 0.39 back: 1.5 deg rake)
    seat=[(-0.296,0.372),(0.115,0.360),(0.115,0.388)]+[(0.115,0.388)]
    seat=[(-0.290,0.368),(0.118,0.358),(0.118,0.388),(-0.270,0.402)]+arc((-0.282,0.388),0.016,100,250,2*s)[1:]
    ext_x(b,seat,-xe,xe,'pw',caps=(False,False))
    # --- upholstered cushion (burgundy), rounded front, piping line
    ct,cb=0.447,0.399
    cush=[(-0.286,cb+0.004),(0.100,cb-0.006),(0.104,ct-0.012),(0.090,ct-0.006),(-0.240,ct)]+arc((-0.262,ct-0.024),0.024,90,250,3*s)[1:]
    ext_x(b,cush,-xe+0.012,xe-0.012,'cush',skip=(0,))
    # --- front apron under the seat
    box(b,(0,-0.262,0.300),(2*xe,0.024,0.068),'pw_dk',skip=('left','right','back','top'))
    # --- back: two-segment raked panel (lumbar curve), top rail with a rounded cap
    bk=[(0.112,0.365),(0.142,0.365),(0.168,0.600),(0.222,0.860),(0.192,0.860),(0.139,0.605)]
    ext_x(b,bk,-xe,xe,'pw',caps=(False,False))
    rail=[(0.178,0.848),(0.252,0.848),(0.262,0.872)]+arc((0.228,0.886),0.032,10,170,3*s)[1:-1]+[(0.190,0.894),(0.172,0.872)]
    ext_x(b,rail,-xe,xe,'pw_dk',caps=(False,False))
    # lumbar moulding strip across the back (rear face): breaks the long plank, catches light from the aisle
    box(b,(0,0.170,0.596),(2*xe,0.012,0.018),'pw_dk',skip=('left','right','bottom'))
    # --- centre support under the seat (3 m span)
    mid=[(-0.250,0.0),(-0.165,0.0),(-0.135,0.05),(0.085,0.05),(0.115,0.0),(0.165,0.0),(0.150,0.358),(-0.250,0.368)]
    ext_x(b,mid,-0.022,0.022,'pw_dk')
    # --- hymnal racks on the back (for the row behind): shelf, lip, end blocks, centre divider
    zr=0.560
    ext_x(b,[(0.150,zr),(0.300,zr),(0.300,zr+0.016),(0.150,zr+0.016)],-xe,xe,'pw_dk',caps=(False,False),skip=(3,))
    box(b,(0,0.292,zr),(2*xe,0.016,0.105),'pw',skip=('left','right','bottom'))
    box(b,(0,0.222,zr),(0.024,0.14,0.105),'pw_dk',skip=('bottom','front'))
    # books: hymnals (red), bibles (black), a navy service book, an offering envelope box
    books=[(-1.30,'bk_red',0.150,0.225,0.0),(-1.13,'bk_red',0.150,0.225,0.06),(-0.96,'bk_black',0.140,0.215,0.0),
           (-0.60,'bk_red',0.150,0.225,-0.04),(-0.42,'bk_navy',0.130,0.200,0.0),
           (0.30,'bk_red',0.150,0.225,0.03),(0.48,'bk_black',0.140,0.215,0.0),(0.66,'bk_red',0.150,0.225,0.0),
           (1.02,'bk_red',0.150,0.225,-0.05),(1.20,'bk_navy',0.130,0.200,0.0)]
    for (x,k,w_,h_,lean) in books:
        x=x*W/3.0
        y=0.262; z=zr+0.016
        # book leaning back against the back panel: a box tilted about X
        import mathutils
        R=mathutils.Matrix.Rotation(math.radians(10+lean*60),3,'X')
        bw,bd,bh=w_,0.034,h_
        def P(a,c_,e): return V((x,y,z))+R@V((a,c_,e))
        C=[P(-bw/2,-bd/2,0),P(bw/2,-bd/2,0),P(bw/2,bd/2,0),P(-bw/2,bd/2,0),P(-bw/2,-bd/2,bh),P(bw/2,-bd/2,bh),P(bw/2,bd/2,bh),P(-bw/2,bd/2,bh)]
        ax=lambda v: R@V(v)
        fq(b,[C[3],C[2],C[6],C[7]],k,ax((0,1,0)),bw,bh)          # back cover (seen from the row behind)
        fq(b,[C[4],C[5],C[6],C[7]],'bk_page',ax((0,0,1)),bw,bd)  # top edge (pages)
        fq(b,[C[0],C[3],C[7],C[4]],k,ax((-1,0,0)),bd,bh)         # spine side
        fq(b,[C[2],C[1],C[5],C[6]],'bk_page',ax((1,0,0)),bd,bh)  # fore-edge
        if hi: fq(b,[C[1],C[0],C[4],C[5]],k,ax((0,-1,0)),bw,bh)
    # offering envelopes + pencil holder block at the centre divider
    box(b,(-0.08,0.232,zr+0.016),(0.11,0.060,0.075),'env',skip=('bottom',))
    box(b,(0.08,0.272,zr+0.016),(0.06,0.026,0.080),'pw_dk',skip=('bottom',))
    # --- collision: seat block + back block
    b.cbox((0,-0.02,0.0),(W,0.58,0.45))
    b.cbox((0,0.21,0.45),(W,0.20,0.47))

# ================================================================== shared helpers for the batch
def ext_z(b, prof, z0, z1, key, caps=(True,True), skip=(), cap_key=None):
    """extrude a closed plan (x,y) profile vertically z0 -> z1; sides grain along the outline, caps grain along X"""
    P=[V(p) for p in prof]; n=len(P)
    A=sum(P[i].x*P[(i+1)%n].y-P[(i+1)%n].x*P[i].y for i in range(n))/2
    acc=0.0; out=[]
    for i in range(n):
        a=P[i]; c=P[(i+1)%n]; L=(c-a).length
        if i in skip or L<1e-6: acc+=L; continue
        q=[V((a.x,a.y,z0)),V((c.x,c.y,z0)),V((c.x,c.y,z1)),V((a.x,a.y,z1))]
        d=c-a; on=V((d.y,-d.x,0)) if A>0 else V((-d.y,d.x,0))
        l=[(acc,z0),(acc+L,z0),(acc+L,z1),(acc,z1)]
        nn=(q[1]-q[0]).cross(q[3]-q[0])
        if nn.dot(on)<0: q=[q[0],q[3],q[2],q[1]]; l=[l[0],l[3],l[2],l[1]]
        out+=b.faces(q,[(0,1,2,3)],key,[l],smooth=False); acc+=L
    for z,want,on in ((z0,(0,0,-1),caps[0]),(z1,(0,0,1),caps[1])):
        if not on: continue
        pts=_orient([V((p.x,p.y,z)) for p in P],want)
        out+=b.faces(pts,[tuple(range(n))],cap_key or key,[[(p.y,p.x) for p in pts]],smooth=False)
    return out
def circ(c, r, n, a0=0.0):
    return [(c[0]+r*math.cos(a0+2*math.pi*i/n), c[1]+r*math.sin(a0+2*math.pi*i/n)) for i in range(n)]
def rrect(x0,y0,x1,y1,r,n=3):
    """rounded rectangle outline (CCW)"""
    pts=[]
    for (cx,cy,a) in ((x1-r,y0+r,-90),(x1-r,y1-r,0),(x0+r,y1-r,90),(x0+r,y0+r,180)):
        for i in range(n+1): t=math.radians(a+90*i/n); pts.append((cx+r*math.cos(t),cy+r*math.sin(t)))
    return pts
def cyl(b, c, r, h, seg, key, top=True, bot=False):
    return b.tube((c[0],c[1],c[2]),(c[0],c[1],c[2]+h),r,r,seg,key,cap0=bot,cap1=top)
def rod(b, p0, p1, r, seg, key, caps=False):
    return b.tube(p0,p1,r,r,seg,key,cap0=caps,cap1=caps)
def txt(b, hi, s, size, o, key, xd=(1,0,0), yd=(0,0,1)):
    if hi: pg.add_text(b,s,size,o,xd,yd,0.0006,key,back=False,sides=False)
def fields(b, hi, x0, x1, z0, z1, y, n, key, depth=0.012, m=0.06, gap=0.05, arch=False, face=-1):
    """high only: n raised panel fields on a vertical face at y (facing -Y when face=-1, +X/-X not supported)"""
    if not hi: return
    w=(x1-x0-2*m-(n-1)*gap)/n
    for i in range(n):
        a=x0+m+i*(w+gap); bb=a+w
        if arch:
            r=w/2; pr=[(a,z0+m),(bb,z0+m)]+[(a+r+r*math.cos(math.radians(t)), z1-m-r+r*math.sin(math.radians(t))) for t in range(0,181,15)]
        else: pr=[(a,z0+m),(bb,z0+m),(bb,z1-m),(a,z1-m)]
        ext_y(b,pr,y-depth if face<0 else y,y if face<0 else y+depth,key)
def bevel_plate(b, hi, x, y, z, w, h, key, t='', tk='paint_black', size=None, face=-1):
    """small plate on a -Y face (baked) with optional lettering"""
    box(b,(x,y-0.004 if face<0 else y+0.004,z),(w,0.008,h),key,skip=('back',) if face<0 else ('front',))
    if t: txt(b,hi,t,size or h*0.55,(x,y-0.0085,z+h/2) if face<0 else (x,y+0.0085,z+h/2),tk,(1,0,0) if face<0 else (-1,0,0))

# ------------------------------------------------------------------ court_bench (gallery bench, austere)
def court_bench(b, hi=False):
    W=3.0; xe=W/2-0.05
    pr=[(-0.29,0.0),(-0.20,0.0),(-0.20,0.045),(0.20,0.045),(0.20,0.0),(0.29,0.0),(0.29,0.86)]+arc((0.245,0.875),0.045,-20,110,2*(2 if hi else 1))[1:]+[(-0.21,0.655),(-0.29,0.645)]
    b.cur_sym=pg.MIRROR
    for sg in (-1,1):
        x0,x1=(-W/2,-xe) if sg<0 else (xe,W/2)
        ext_x(b,pr,x0,x1,'wal',grain='arc')
        if hi:   # sunk-moulded field (raised border) on the aisle face
            xo=x0 if sg<0 else x1
            ext_x(b,[(-0.20,0.13),(0.20,0.13),(0.20,0.56),(-0.13,0.56),(-0.20,0.50)],(xo-0.008) if sg<0 else xo,xo if sg<0 else xo+0.008,'wal')
    b.cur_sym=1
    ext_x(b,[(-0.285,0.405),(0.12,0.395),(0.12,0.432),(-0.27,0.445),(-0.29,0.43)],-xe,xe,'wal',caps=(False,False))
    for z,y in ((0.50,0.155),(0.62,0.185),(0.74,0.215)):     # three raked back slats
        ext_x(b,[(y,z),(y+0.025,z),(y+0.045,z+0.095),(y+0.02,z+0.095)],-xe,xe,'wal',caps=(False,False))
    ext_x(b,[(0.22,0.84),(0.275,0.84),(0.28,0.875),(0.23,0.885)],-xe,xe,'wal_dk',caps=(False,False))
    box(b,(0,0.145,0.36),(2*xe,0.035,0.06),'wal_dk',skip=('left','right'))
    box(b,(0,-0.255,0.32),(2*xe,0.025,0.075),'wal_dk',skip=('left','right','back','top'))
    ext_x(b,[(-0.24,0.0),(-0.16,0.0),(-0.13,0.05),(0.08,0.05),(0.11,0.0),(0.16,0.0),(0.15,0.39),(-0.24,0.40)],-0.022,0.022,'wal_dk')
    # brass row plate on the aisle end (left) + right
    for sg in (-1,1):
        xo=-W/2 if sg<0 else W/2
        ext_x(b,[(-0.05,0.70),(0.05,0.70),(0.05,0.74),(-0.05,0.74)],xo-0.004 if sg<0 else xo,xo if sg<0 else xo+0.004,'badge')
    b.cbox((0,-0.02,0.0),(W,0.56,0.45)); b.cbox((0,0.20,0.45),(W,0.18,0.45))

# ------------------------------------------------------------------ lectern (audience side = -Y, reader at +Y)
def lectern(b, hi=False):
    ext_x(b,[(-0.25,0.0),(0.25,0.0),(0.25,0.07),(-0.25,0.07)],-0.31,0.31,'wal_dk')                    # plinth
    ext_x(b,[(-0.21,0.07),(0.21,0.07),(0.21,0.97),(-0.21,1.09)],-0.26,0.26,'wal',skip=())             # body
    ext_x(b,[(-0.26,1.07),(-0.235,1.12),(0.245,1.005),(0.255,0.975),(0.22,0.965)],-0.30,0.30,'wal_dk') # sloped desk top
    ext_x(b,[(0.215,0.995),(0.25,0.985),(0.255,1.03),(0.235,1.035)],-0.29,0.29,'wal_dk',caps=(True,True)) # book stop lip
    box(b,(0,-0.215,0.86),(0.54,0.03,0.05),'wal_dk',skip=('back',))                                  # cornice band
    box(b,(0,-0.215,0.09),(0.54,0.03,0.07),'wal_dk',skip=('back',))
    for x in (-0.25,0.25): box(b,(x,-0.205,0.07),(0.05,0.05,0.88),'wal_dk',skip=('bottom',))          # pilasters
    fields(b,hi,-0.22,0.22,0.16,0.86,-0.21,1,'wal',depth=0.012,m=0.03,arch=True)
    bevel_plate(b,hi,0,-0.211,0.56,0.16,0.045,'plate','PULPIT','paint_black',0.024)
    # reading shelf (reader side) + gooseneck microphone
    box(b,(0,0.20,0.62),(0.44,0.06,0.025),'wal_dk',skip=('front',))
    rod(b,(0.18,0.21,0.99),(0.17,0.12,1.22),0.007,6,'plastic_black'); cyl(b,(0.17,0.12,1.22),0.014,0.05,6,'plastic_black')
    b.cbox((0,0,0),(0.6,0.5,1.1))

# ------------------------------------------------------------------ altar_table (congregation = -Y)
def altar_table(b, hi=False):
    box(b,(0,0,0),(2.0,0.80,0.10),'pw_dk',skip=('bottom',))                                    # plinth
    box(b,(0,0,0.10),(1.86,0.68,0.82),'pw',skip=('bottom','top'))                             # body
    box(b,(0,0,0.92),(2.0,0.84,0.06),'pw_dk',skip=())                                          # mensa
    for x in (-0.93,0.93): box(b,(x,-0.33,0.10),(0.09,0.06,0.82),'pw_dk',skip=('bottom','top','back'))
    fields(b,hi,-0.88,0.88,0.10,0.92,-0.34,3,'pw',depth=0.014,m=0.07,gap=0.08,arch=True)
    # linen cloth: top sheet + front and side falls; burgundy antependium with a gold cross
    box(b,(0,0,0.98),(1.96,0.80,0.006),'linen',skip=('bottom',))
    box(b,(0,-0.405,0.70),(1.98,0.008,0.286),'linen',skip=())
    for x in (-0.985,0.985): box(b,(x,0,0.70),(0.008,0.80,0.286),'linen',skip=())
    box(b,(0,-0.413,0.46),(0.50,0.008,0.50),'cush',skip=('back',))
    box(b,(0,-0.418,0.80),(0.50,0.004,0.05),'brass',skip=('back',))
    box(b,(0,-0.419,0.56),(0.04,0.004,0.22),'brass',skip=('back',)); box(b,(0,-0.419,0.66),(0.14,0.004,0.035),'brass',skip=('back',))
    box(b,(0,-0.418,0.465),(0.50,0.004,0.025),'brass',skip=('back',))
    b.cbox((0,0,0),(2.0,0.84,0.99))

# ------------------------------------------------------------------ judge_bench (courtroom = -Y, judge at +Y, on a 0.3 m dais)
def judge_bench(b, hi=False):
    W=3.6
    box(b,(0,0,0),(W,1.0,0.30),'wal_dk',skip=('bottom',))                                     # dais
    box(b,(0,-0.505,0.0),(W+0.01,0.01,0.06),'rubber',skip=('bottom','back'))                  # kick strip
    box(b,(0,-0.42,0.30),(W-0.04,0.08,0.88),'wal',skip=('bottom',))                           # front wall
    box(b,(0,-0.36,1.18),(W,0.30,0.05),'wal_dk')                                              # top ledge
    box(b,(0,-0.465,1.10),(W-0.04,0.02,0.06),'wal_dk',skip=('back','bottom'))                 # cornice
    box(b,(0,-0.465,0.30),(W-0.04,0.02,0.10),'wal_dk',skip=('back','bottom'))                 # base rail
    for x in (-1.2,-0.30,0.30,1.2): box(b,(x,-0.47,0.30),(0.06,0.03,0.82),'wal_dk',skip=('bottom','back'))
    for sg in (-1,1): box(b,(sg*(W/2-0.04),-0.05,0.30),(0.08,0.66,0.93),'wal',skip=('bottom',))  # side returns
    box(b,(0,-0.09,1.00),(W-0.16,0.62,0.035),'wal_dk')                                        # judge's work top
    box(b,(0,-0.32,0.30),(W-0.16,0.02,0.70),'wal_dk',skip=('front','top'))                    # modesty back
    fields(b,hi,-1.77,-1.23,0.30,1.10,-0.46,1,'wal',m=0.08); fields(b,hi,1.23,1.77,0.30,1.10,-0.46,1,'wal',m=0.08)
    fields(b,hi,-1.17,-0.33,0.30,1.10,-0.46,1,'wal',m=0.08); fields(b,hi,0.33,1.17,0.30,1.10,-0.46,1,'wal',m=0.08)
    # state seal on the centre panel
    pr=circ((0,0.74),0.20,16); ext_y(b,pr,-0.485,-0.465,'plate')
    if hi:
        ext_y(b,circ((0,0.74),0.15,24),-0.49,-0.485,'brass'); txt(b,hi,'SUPERIOR COURT',0.032,(0,-0.4905,0.84),'paint_black')
        txt(b,hi,'CORONADO',0.03,(0,-0.4905,0.64),'paint_black')
        for k in range(5): ext_y(b,[(-0.05+0.025*k,0.70),(-0.04+0.025*k,0.70),(-0.04+0.025*k,0.78),(-0.05+0.025*k,0.78)],-0.494,-0.49,'paint_black')
    bevel_plate(b,hi,0,-0.512,1.205,0.5,0.06,'plate','HON. JUDGE M. ALVAREZ','paint_black',0.032)
    # desk kit: monitor, gavel + block, files
    box(b,(0.9,-0.10,1.035),(0.22,0.18,0.012),'plastic_black'); box(b,(0.9,-0.12,1.047),(0.05,0.04,0.12),'plastic_black')
    box(b,(0.9,-0.125,1.13),(0.56,0.03,0.33),'plastic_black',skip=('front',)); box(b,(0.9,-0.142,1.15),(0.52,0.004,0.29),'screen',skip=('back',))
    cyl(b,(-0.6,-0.20,1.035),0.06,0.03,10,'wal_dk'); rod(b,(-0.72,-0.10,1.08),(-0.52,-0.12,1.08),0.012,6,'wal_dk',caps=True)
    cyl(b,(-0.52,-0.12,1.06),0.032,0.04,8,'wal_dk',top=True)
    box(b,(0.2,-0.15,1.035),(0.34,0.25,0.04),'label',skip=('bottom',))
    # high-back leather chair
    cyl(b,(0,0.30,0.30),0.30,0.04,8,'chrome'); cyl(b,(0,0.30,0.34),0.03,0.24,6,'chrome',top=False)
    ext_x(b,[(0.04,0.58),(0.50,0.58),(0.50,0.68),(0.06,0.70)],-0.27,0.27,'leather')
    ext_x(b,[(0.44,0.66),(0.54,0.66),(0.60,1.38),(0.50,1.40)],-0.26,0.26,'leather')
    for sg in (-1,1): box(b,(sg*0.30,0.30,0.70),(0.07,0.40,0.05),'leather')
    b.cbox((0,0,0),(W,1.0,0.30)); b.cbox((0,-0.36,0.30),(W,0.28,0.93))

# ------------------------------------------------------------------ witness_box
def witness_box(b, hi=False):
    W,D=1.4,1.2
    box(b,(0,0,0),(W,D,0.20),'wal_dk',skip=('bottom',))
    box(b,(0,-0.57,0.20),(W,0.06,0.82),'wal',skip=('bottom',))
    for sg in (-1,1): box(b,(sg*0.67,-0.05,0.20),(0.06,0.98,0.82),'wal',skip=('bottom',))
    box(b,(0,-0.57,1.02),(W+0.04,0.10,0.045),'wal_dk')
    for sg in (-1,1): box(b,(sg*0.67,-0.05,1.02),(0.10,0.98,0.045),'wal_dk')
    box(b,(0,0.585,0.0),(0.4,0.03,0.20),'wal_dk',skip=('bottom',))
    fields(b,hi,-0.70,0.70,0.20,1.02,-0.60,2,'wal',m=0.08,gap=0.06)
    if hi:
        for sg in (-1,1):
            xo=sg*0.70
            ext_x(b,[(-0.48,0.28),(0.36,0.28),(0.36,0.94),(-0.48,0.94)],(xo-0.012) if sg<0 else xo,xo if sg<0 else xo+0.012,'wal')
    # witness chair (wood, upholstered seat), facing the court
    for (x,y) in ((-0.22,-0.30),(0.22,-0.30),(-0.22,0.06),(0.22,0.06)): box(b,(x,y,0.20),(0.04,0.04,0.43),'wal_dk',skip=('bottom',))
    box(b,(0,-0.12,0.63),(0.50,0.44,0.05),'leather')
    ext_x(b,[(0.04,0.66),(0.08,0.66),(0.13,1.12),(0.09,1.12)],-0.24,0.24,'wal_dk')
    box(b,(0,0.08,0.78),(0.40,0.03,0.24),'leather')
    # gooseneck microphone on the front rail
    box(b,(0.32,-0.55,1.065),(0.08,0.08,0.02),'plastic_black'); rod(b,(0.32,-0.55,1.085),(0.27,-0.42,1.30),0.006,6,'plastic_black'); cyl(b,(0.27,-0.42,1.30),0.015,0.05,6,'plastic_black')
    b.cbox((0,0,0),(W,D,0.2)); b.cbox((0,-0.40,0.2),(W,0.40,0.87))

# ------------------------------------------------------------------ jury_box (2 rows of 6, rear row on a riser)
def _jchair(b, x, y, z):
    cyl(b,(x,y,z),0.03,0.30,6,'chrome',top=False)
    cyl(b,(x,y,z),0.18,0.02,6,'chrome')
    ext_x(b,[(y-0.21,z+0.40),(y+0.21,z+0.40),(y+0.21,z+0.48),(y-0.23,z+0.47)],x-0.24,x+0.24,'leather')
    ext_x(b,[(y+0.16,z+0.48),(y+0.25,z+0.48),(y+0.30,z+0.95),(y+0.21,z+0.96)],x-0.23,x+0.23,'leather')
def jury_box(b, hi=False):
    W,D=4.0,1.6
    box(b,(0,0,0),(W,D,0.12),'wal_dk',skip=('bottom',))
    box(b,(0,0.38,0.12),(W-0.12,0.84,0.22),'wal_dk',skip=('bottom',))                         # rear riser
    box(b,(0,-0.76,0.12),(W,0.08,0.84),'wal',skip=('bottom',))                                # front wall
    for sg in (-1,1): box(b,(sg*1.96,0.04,0.12),(0.08,1.52,0.84),'wal',skip=('bottom',))
    box(b,(0,-0.76,0.96),(W+0.04,0.13,0.045),'wal_dk')
    for sg in (-1,1): box(b,(sg*1.96,0.04,0.96),(0.13,1.52,0.045),'wal_dk')
    for x in (-1.32,-0.66,0.0,0.66,1.32): box(b,(x,-0.805,0.12),(0.05,0.02,0.84),'wal_dk',skip=('bottom','back'))
    box(b,(0,-0.805,0.80),(W-0.1,0.02,0.05),'wal_dk',skip=('bottom','back','left','right'))
    box(b,(0,-0.805,0.12),(W-0.1,0.02,0.10),'wal_dk',skip=('bottom','back','left','right'))
    for x in (-1.65,-0.99,-0.33,0.33,0.99,1.65):
        _jchair(b,x,-0.38,0.12); _jchair(b,x,0.30,0.34)
    if hi:
        for i in range(6):
            x=-1.98+0.04+0.66*i+0.33
            ext_y(b,[(x-0.25,0.30),(x+0.25,0.30),(x+0.25,0.74),(x-0.25,0.74)],-0.83,-0.815,'wal')
    b.cbox((0,0,0),(W,D,0.34)); b.cbox((0,-0.76,0.34),(W,0.10,0.66))

# ------------------------------------------------------------------ conference_table (boat-shaped)
def conference_table(b, hi=False):
    L,Wt=3.0,1.2; n=8 if hi else 5
    pr=[]
    for i in range(n+1): t=math.radians(-90+180*i/n); pr.append((L/2-0.55+0.55*math.cos(t), (Wt/2)*math.sin(t)*0.92))
    pr=[]
    for i in range(n+1): t=math.radians(-90+180*i/n); pr.append((1.05+0.45*math.cos(t),0.60*math.sin(t)))
    pr+=[(0.0,0.62)]
    for i in range(n+1): t=math.radians(90+180*i/n); pr.append((-1.05+0.45*math.cos(t),0.60*math.sin(t)))
    pr+=[(0.0,-0.62)]
    ext_z(b,pr,0.715,0.75,'wal',caps=(False,True))
    pr2=[(x*0.97,y*0.94) for x,y in pr]; ext_z(b,pr2,0.70,0.715,'wal_dk',caps=(True,False))
    for x in (-0.85,0.85):
        ext_z(b,rrect(x-0.11,-0.22,x+0.11,0.22,0.04,2),0.06,0.70,'wal_dk',caps=(False,False))
        box(b,(x,0,0),(0.30,0.80,0.06),'steel',skip=('bottom',))
    box(b,(0,0,0.25),(1.5,0.08,0.10),'steel',skip=())                                          # stretcher
    # centre cable box with a flip lid
    box(b,(0,0,0.75),(0.34,0.14,0.012),'alum',skip=('bottom',)); box(b,(0,0.0,0.762),(0.30,0.10,0.003),'keypad',skip=('bottom',))
    b.cbox((0,0,0),(3.0,1.24,0.75))

# ------------------------------------------------------------------ chart_table (broker's plan chest, chart under glass)
def chart_table(b, hi=False):
    W,D=1.6,1.0
    box(b,(0,0.02,0),(W-0.08,D-0.12,0.08),'plastic_black',skip=('bottom',))
    box(b,(0,0,0.08),(W,D,0.82),'wal',skip=('bottom','top','front'))
    for i in range(5):
        z=0.09+i*0.16
        box(b,(0,-0.49,z),(W-0.06,0.03,0.15),'wal' if i%2 else 'wal_dk',skip=('back',))
        for x in (-0.45,0.45): box(b,(x,-0.515,z+0.065),(0.14,0.02,0.025),'brass',skip=('back',))
        if hi: box(b,(0,-0.51,z+0.06),(0.09,0.005,0.03),'label',skip=('back',))
    box(b,(0,0,0.90),(W+0.04,D+0.04,0.04),'wal_dk')
    box(b,(0,0,0.94),(W-0.06,D-0.06,0.003),'label',skip=('bottom',))                          # chart (baked)
    box(b,(0,0,0.944),(W-0.06,D-0.06,0.006),'glass',skip=('bottom',)) if False else None
    if hi:   # nautical chart: coastline, depth contours, compass rose, title
        z=0.9435
        coast=[(-0.74,0.10),(-0.45,0.16),(-0.30,0.05),(-0.10,0.12),(0.05,0.30),(0.25,0.22),(0.40,0.40),(0.74,0.42),(0.74,0.47),(-0.74,0.47)]
        ext_z(b,coast,z,z+0.0005,'oak'.replace('oak','lam'))
        ext_z(b,rrect(-0.20,-0.12,0.15,0.02,0.07,3),z,z+0.0005,'lam')
        for k,r in enumerate((0.09,0.06)): 
            for ang in range(0,360,45): ext_z(b,[(0.52+0.003*math.cos(math.radians(ang+90)),-0.25),(0.52+r*math.cos(math.radians(ang)),-0.25+r*math.sin(math.radians(ang))),(0.52-0.003*math.cos(math.radians(ang+90)),-0.25)],z+0.0005,z+0.001,'paint_navy')
        txt(b,hi,'SAN DIEGO BAY',0.05,(-0.35,-0.36,z+0.001),'paint_navy',(1,0,0),(0,1,0))
        txt(b,hi,'Coronado  Point Loma  Harbor Approaches',0.022,(-0.35,-0.41,z+0.001),'paint_navy',(1,0,0),(0,1,0))
        for k in range(9): ext_z(b,[(-0.74+0.18*k,-0.47),(-0.739+0.18*k,-0.47),(-0.739+0.18*k,0.47),(-0.74+0.18*k,0.47)],z,z+0.0004,'paint_navy')
    # parallel ruler + dividers lying on the chart
    box(b,(0.10,-0.25,0.943),(0.45,0.05,0.008),'plastic',skip=('bottom',)); box(b,(0.10,-0.18,0.943),(0.45,0.05,0.008),'plastic',skip=('bottom',))
    rod(b,(-0.30,0.25,0.947),(-0.12,0.32,0.947),0.003,4,'chrome'); rod(b,(-0.30,0.25,0.947),(-0.14,0.20,0.947),0.003,4,'chrome')
    b.cbox((0,0,0),(1.64,1.04,0.95))

# ------------------------------------------------------------------ drafting_table (user at -Y; board rises toward +Y)
def drafting_table(b, hi=False):
    for sg in (-1,1):
        x=sg*0.62
        box(b,(x,0,0),(0.05,0.82,0.035),'paint_black',skip=('bottom',))
        rod(b,(x,-0.25,0.035),(x,0.0,0.74),0.018,4,'paint_black'); rod(b,(x,0.25,0.035),(x,0.0,0.74),0.018,4,'paint_black')
        box(b,(x,0,0.70),(0.05,0.70,0.04),'paint_black')
        for y in (-0.38,0.38): cyl(b,(x,y,0),0.022,0.012,6,'rubber')
    rod(b,(-0.62,0.0,0.36),(0.62,0.0,0.36),0.016,4,'paint_black')
    ang=math.radians(22); c=V((0,0,0.80))
    def T(x,y,z): return c+V((x, y*math.cos(ang)-z*math.sin(ang), y*math.sin(ang)+z*math.cos(ang)))
    corners=[(-0.70,-0.44),(0.70,-0.44),(0.70,0.44),(-0.70,0.44)]
    top=[T(x,y,0.025) for x,y in corners]; bot=[T(x,y,0) for x,y in corners]
    fq(b,top,'lam',T(0,0,1)-T(0,0,0),1.4,0.88); fq(b,bot[::-1],'paint_grey',T(0,0,-1)-T(0,0,0),1.4,0.88)
    for i in range(4):
        a,bb=i,(i+1)%4
        fq(b,[bot[a],bot[bb],top[bb],top[a]],'paint_black',(T(*corners[a],0.0)+T(*corners[bb],0.0))/2-T(0,0,0),1.0,0.025)
    # drawing sheet (blueprint, baked), straightedge, pencil ledge, lamp
    sh=[T(x,y,0.026) for x,y in [(-0.52,-0.34),(0.42,-0.34),(0.42,0.32),(-0.52,0.32)]]
    fq(b,sh,'screen',T(0,0,1)-T(0,0,0),0.94,0.66)
    if hi:
        for (x0,y0,x1,y1) in [(-0.45,-0.25,0.30,-0.245),(-0.45,0.20,0.30,0.205),(-0.45,-0.25,-0.445,0.205),(0.295,-0.25,0.30,0.205),
                              (-0.30,-0.10,0.10,-0.095),(-0.30,-0.10,-0.295,0.12),(0.10,-0.10,0.105,0.12),(-0.30,0.115,0.105,0.12),(-0.12,-0.25,-0.115,-0.10),(0.33,-0.30,0.40,-0.295)]:
            pts=[T(x0,y0,0.0265),T(x1,y0,0.0265),T(x1,y1,0.0265),T(x0,y1,0.0265)]; fq(b,pts,'paint_white',T(0,0,1)-T(0,0,0),0.1,0.1)
        txt(b,hi,'BEACH HOUSE - EAST ELEV.',0.022,T(0.15,-0.31,0.0266),'paint_white',(1,0,0),tuple(T(0,1,0)-T(0,0,0)))
    st=[T(x,y,0.035) for x,y in [(-0.70,0.02),(0.70,0.02),(0.70,0.07),(-0.70,0.07)]]; fq(b,st,'plastic',T(0,0,1)-T(0,0,0),1.4,0.05)
    box(b,(0,-0.46,0.66),(1.36,0.06,0.03),'paint_black'); box(b,(0.3,-0.47,0.69),(0.16,0.008,0.008),'paint_yellow')
    rod(b,(0.66,0.30,0.95),(0.66,0.30,1.30),0.01,6,'chrome'); rod(b,(0.66,0.30,1.30),(0.40,0.05,1.38),0.009,6,'chrome')
    b.tube((0.40,0.05,1.38),(0.36,0.02,1.28),0.03,0.07,8,'paint_black',cap0=True,cap1=False)
    b.cbox((0,0,0),(1.40,0.90,0.98))

# ------------------------------------------------------------------ reception_desk (L, visitors at -Y, staff behind)
def reception_desk(b, hi=False):
    # main run along X (x -1.5..1.5, y -0.70..-0.10), return along Y at x 0.90..1.50
    box(b,(-0.30,-0.68,0),(2.40,0.04,0.08),'steel',skip=('bottom','back'))
    box(b,(-0.30,-0.65,0),(2.40,0.06,1.02),'wal',skip=('bottom','back'))
    box(b,(1.47,0.0,0),(0.06,1.40,1.02),'wal',skip=('bottom','left'))
    box(b,(1.20,-0.65,0),(0.60,0.06,1.02),'wal',skip=('bottom','back','left'))
    box(b,(-1.47,-0.40,0),(0.06,0.56,1.02),'wal',skip=('bottom',))
    box(b,(0.30,-0.70,0.42),(2.40,0.012,0.22),'paint_cream',skip=('back',))                  # light band
    box(b,(-0.17,-0.63,1.02),(2.70,0.24,0.035),'paint_cream')                                 # transaction ledge
    box(b,(1.42,0.0,1.02),(0.30,1.40,0.035),'paint_cream')
    box(b,(-0.05,-0.30,0.74),(2.80,0.56,0.03),'lam'); box(b,(1.12,0.30,0.74),(0.56,0.80,0.03),'lam')
    box(b,(1.0,0.45,0),(0.50,0.55,0.70),'paint_grey',skip=('bottom',))                        # pedestal drawers
    box(b,(-1.0,-0.62,0.6),(0.5,0.004,0.12),'badge',skip=('back',)) if False else None
    bevel_plate(b,hi,-0.75,-0.711,0.70,0.62,0.12,'plate','RECEPTION','paint_black',0.075)
    # monitor, keyboard, phone, sign-in clipboard, bell
    box(b,(0.2,-0.20,0.77),(0.22,0.18,0.012),'plastic_black'); box(b,(0.2,-0.18,0.782),(0.05,0.04,0.14),'plastic_black')
    box(b,(0.2,-0.17,0.88),(0.58,0.03,0.36),'plastic_black',skip=('back',)) 
    box(b,(0.2,-0.187,0.90),(0.54,0.004,0.32),'screen',skip=('back',))
    box(b,(0.2,-0.02,0.77),(0.44,0.15,0.018),'keypad',skip=('bottom',))
    box(b,(-0.55,-0.10,0.77),(0.18,0.20,0.06),'plastic_black',skip=('bottom',))
    box(b,(-0.6,-0.64,1.055),(0.24,0.20,0.01),'label',skip=('bottom',))
    b.tube((0.6,-0.63,1.055),(0.6,-0.63,1.095),0.045,0.02,8,'chrome',cap0=False,cap1=True)
    b.cbox((-0.30,-0.40,0),(2.40,0.62,1.06)); b.cbox((1.20,0.0,0),(0.60,1.40,1.06))

# ------------------------------------------------------------------ stage_platform (6 x 2.6 deck, two step flights at the front)
def stage_platform(b, hi=False):
    box(b,(0,0.20,0),(6.0,2.60,0.60),'stage',skip=('bottom','top','front'))
    box(b,(0,0.20,0.58),(6.0,2.60,0.02),'stage',skip=('bottom',))
    box(b,(0,-1.10,0.0),(6.0,0.02,0.58),'skirt',skip=('back',))
    if True:   # skirt pleats
        for i in range(24): box(b,(-2.875+i*0.25,-1.12,0.0),(0.12,0.02,0.57),'skirt',skip=('back','bottom','top'))
    box(b,(0,-1.11,0.58),(6.0,0.04,0.02),'paint_white',skip=('bottom','back'))                 # nosing
    for sx in (-2.45,2.45):
        for k,(y,h) in enumerate(((-1.42,0.20),(-1.26,0.40))):
            box(b,(sx,y,0),(1.0,0.16 if k==0 else 0.16,h),'stage',skip=('bottom','back') if k else ('bottom',))
            box(b,(sx,y-0.08,h-0.02),(1.0,0.03,0.02),'paint_white',skip=('bottom','back'))
    maker_plate(b,(1.6,-1.133,0.05),hi,0.10,0.03)
    b.cbox((0,0.20,0),(6.0,2.60,0.60)); b.cbox((0,-1.30,0),(6.0,0.40,0.30))

# ------------------------------------------------------------------ dental_chair (patient's feet -Y, head + unit at +Y)
def dental_chair(b, hi=False):
    ext_z(b,rrect(-0.30,-0.10,0.30,0.55,0.12,2),0.0,0.05,'paint_white',caps=(False,True))
    box(b,(0,0.10,0.05),(0.30,0.34,0.34),'paint_white',skip=('bottom',))
    box(b,(0,0.0,0.39),(0.46,0.80,0.07),'paint_grey')
    up=[(-0.90,0.36),(-0.78,0.48),(-0.42,0.56),(0.0,0.57),(0.12,0.60),(0.50,0.98),(0.58,1.06),(0.66,1.13),(0.78,1.16)]
    lo=[(0.80,1.10),(0.70,1.04),(0.60,0.96),(0.46,0.86),(0.08,0.48),(0.0,0.46),(-0.40,0.45),(-0.78,0.38),(-0.88,0.30)]
    ext_x(b,up+lo,-0.27,0.27,'vinyl')
    ext_x(b,[(0.64,1.08),(0.86,1.14),(0.86,1.22),(0.64,1.18)],-0.13,0.13,'vinyl')         # headrest pad
    for sg in (-1,1): box(b,(sg*0.31,0.05,0.62),(0.07,0.42,0.05),'vinyl'); box(b,(sg*0.31,0.18,0.46),(0.04,0.04,0.17),'paint_white')
    # cuspidor post + bowl (patient's left)
    box(b,(-0.46,0.40,0.0),(0.16,0.16,0.80),'paint_white',skip=('bottom',)); b.lathe([(0.04,0.80),(0.13,0.83),(0.12,0.90),(0.10,0.88),(0.02,0.84)],10,'ceramic_w',c=(-0.46,0.40,0))
    # delivery unit arm with an instrument tray (right)
    rod(b,(0.36,0.30,0.46),(0.42,0.10,0.86),0.02,6,'paint_white'); rod(b,(0.42,0.10,0.86),(0.50,-0.20,0.90),0.018,6,'paint_white')
    box(b,(0.50,-0.30,0.90),(0.40,0.30,0.04),'paint_white'); box(b,(0.50,-0.32,0.94),(0.34,0.22,0.006),'steel',skip=('bottom',))
    for k in range(4): rod(b,(0.36+0.07*k,-0.18,0.95),(0.36+0.07*k,-0.40,0.955),0.006,4,'chrome')
    # operating light on its post
    rod(b,(0.0,0.62,0.05),(0.0,0.62,1.95),0.035,8,'paint_white'); rod(b,(0.0,0.62,1.92),(0.0,0.05,1.92),0.025,6,'paint_white')
    box(b,(0.0,0.0,1.80),(0.36,0.16,0.10),'paint_white'); box(b,(0.0,0.0,1.795),(0.30,0.12,0.006),'mirror',skip=('top',))
    maker_plate(b,(0,-0.074,0.20),hi,0.10,0.03)
    b.cbox((0,0.0,0),(0.66,1.80,0.80)); b.cbox((0,0.62,0),(0.12,0.12,1.95))

# ------------------------------------------------------------------ exam_bed (long along X, head +X)
def exam_bed(b, hi=False):
    box(b,(0,0.02,0),(1.50,0.58,0.06),'plastic_black',skip=('bottom',))
    box(b,(0,0.02,0.06),(1.56,0.62,0.50),'paint_cream',skip=('bottom','front'))
    for i,(x,w) in enumerate(((-0.52,0.48),(0.0,0.48),(0.52,0.48))):
        box(b,(x,-0.30,0.30),(w,0.02,0.24),'paint_cream',skip=('back',)); box(b,(x,-0.312,0.48),(0.16,0.012,0.02),'chrome',skip=('back',))
    box(b,(0,-0.30,0.08),(0.80,0.06,0.18),'paint_grey',skip=('back',))                        # pull-out step
    box(b,(0,-0.33,0.24),(0.80,0.02,0.02),'rubber',skip=('back',))
    ext_x(b,[(-0.34,0.56),(0.34,0.56),(0.34,0.63),(0.31,0.66),(-0.31,0.66),(-0.34,0.63)],-0.95,0.25,'vinyl')
    ang=math.radians(32)
    def R(x,y,z): return V((0.25+x*math.cos(ang),y,0.56+x*math.sin(ang)+z))
    prof=[(0,-0.34,0),(0.68,-0.34,0),(0.68,-0.34,0.09),(0,-0.34,0.09)]
    pts0=[R(x,-0.34,z) for x,_,z in prof]; pts1=[R(x,0.34,z) for x,_,z in prof]
    for i in range(4):
        a,c=i,(i+1)%4
        fq(b,[pts0[a],pts0[c],pts1[c],pts1[a]],'vinyl',((pts0[a]+pts0[c])/2-(sum(pts0,V())/4)),0.68,0.68)
    fq(b,pts0,'vinyl',(0,-1,0),0.68,0.09); fq(b,pts1,'vinyl',(0,1,0),0.68,0.09)
    # paper roll at the head end + paper strip over the top
    rod(b,(0.92,-0.25,1.00),(0.92,0.25,1.00),0.05,8,'paint_white',caps=True)
    ext_x(b,[(-0.25,0.663),(0.25,0.663),(0.25,0.668),(-0.25,0.668)],-0.95,0.25,'paint_white',caps=(True,True))
    pts=[R(0,-0.25,0.093),R(0.62,-0.25,0.093),R(0.62,0.25,0.093),R(0,0.25,0.093)]; fq(b,pts,'paint_white',(-math.sin(ang),0,math.cos(ang)),0.62,0.5)
    maker_plate(b,(0.60,-0.293,0.10),hi,0.08,0.025)
    b.cbox((0,0,0),(1.90,0.70,0.66))

# ------------------------------------------------------------------ physio_table (hi-lo, face hole at +X)
def physio_table(b, hi=False):
    for x in (-0.55,0.55):
        box(b,(x,0,0.03),(0.06,0.62,0.05),'paint_grey')
        for y in (-0.28,0.28): cyl(b,(x,y,0),0.035,0.03,6,'rubber')
    rod(b,(-0.55,0,0.06),(0.55,0,0.52),0.025,4,'paint_grey'); rod(b,(0.55,0,0.06),(-0.55,0,0.52),0.025,4,'paint_grey')
    box(b,(0,0,0.25),(0.16,0.12,0.12),'paint_black')
    box(b,(-0.10,0,0.52),(1.30,0.50,0.05),'paint_grey')
    ext_x(b,[(-0.35,0.57),(0.35,0.57),(0.35,0.64),(0.32,0.67),(-0.32,0.67),(-0.35,0.64)],-0.95,0.45,'vinyl')
    hp=[(-0.35,0.57),(0.35,0.57),(0.35,0.64),(0.32,0.67),(-0.32,0.67),(-0.35,0.64)]
    for (y0,y1) in ((-0.35,-0.07),(0.07,0.35)):
        ext_x(b,[(max(y0,yy),zz) if yy<0 else (min(y1,yy),zz) for yy,zz in hp] if False else [(y0,0.57),(y1,0.57),(y1,0.67),(y0,0.67)],0.46,0.95,'vinyl')
    ext_x(b,[(-0.07,0.57),(0.07,0.57),(0.07,0.67),(-0.07,0.67)],0.85,0.95,'vinyl')
    for sg in (-1,1): box(b,(0.70,sg*0.40,0.50),(0.30,0.12,0.04),'vinyl')                   # arm boards
    maker_plate(b,(0,-0.063,0.27),hi,0.08,0.025)
    b.cbox((0,0,0),(1.90,0.70,0.67))

# ------------------------------------------------------------------ privacy_curtain_rail (L track + wave curtain)
def privacy_curtain_rail(b, hi=False):
    H=2.30; zt=2.26
    rod(b,(-1.2,-1.2,zt),(1.2,-1.2,zt),0.012,4,'alum',caps=True); rod(b,(-1.2,-1.2,zt),(-1.2,1.2,zt),0.012,4,'alum',caps=True)
    for p in ((1.2,-1.2),(-1.2,1.2),(-1.2,-1.2)): rod(b,(p[0],p[1],zt),(p[0],p[1],H),0.008,4,'chrome')
    def wave(p0,p1,n,amp,z0,z1,key):
        P0=V(p0); P1=V(p1); d=(P1-P0); L=d.length; d.normalize(); nrm=V((-d.y,d.x))
        pts=[P0+d*(L*i/n)+nrm*(amp*(1 if i%2 else -1)) for i in range(n+1)]
        acc=0.0
        for i in range(n):
            a,c=pts[i],pts[i+1]; l=(c-a).length
            q=[V((a.x,a.y,z0)),V((c.x,c.y,z0)),V((c.x,c.y,z1)),V((a.x,a.y,z1))]
            b.faces(q,[(0,1,2,3)],key,[[(acc,z0),(acc+l,z0),(acc+l,z1),(acc,z1)]])
            b.faces(q[::-1],[(0,1,2,3)],key,[[(acc,z1),(acc+l,z1),(acc+l,z0),(acc,z0)][::-1]])
            acc+=l
    wave((-1.2,-1.2),(0.35,-1.2),10,0.05,0.40,2.18,'curtain')       # front run, drawn 2/3 open
    wave((-1.2,1.2),(-1.2,-1.2),12,0.05,0.40,2.18,'curtain')
    box(b,(-0.43,-1.2,2.18),(1.55,0.02,0.05),'curtain_dk') ; box(b,(-1.2,0,2.18),(0.02,2.4,0.05),'curtain_dk')
    maker_plate(b,(-1.0,-1.215,2.24),hi,0.06,0.02)
    b.cbox((-1.2,0,0.40),(0.10,2.4,1.80)); b.cbox((-0.43,-1.2,0.40),(1.55,0.10,1.80)); b.cbox((0,0,2.22),(2.44,2.44,0.06))

# ------------------------------------------------------------------ water_cooler
def water_cooler(b, hi=False):
    box(b,(0,0,0),(0.32,0.32,0.06),'plastic_black',skip=('bottom',))
    box(b,(0,0,0.06),(0.32,0.32,0.88),'paint_white',skip=('bottom','front'))
    box(b,(0,-0.155,0.06),(0.32,0.01,0.88),'paint_grey',skip=('back',))
    box(b,(0,-0.165,0.70),(0.22,0.012,0.14),'paint_black',skip=('back',))                    # tap recess
    box(b,(0,-0.165,0.68),(0.20,0.06,0.02),'plastic_black',skip=('back',))                   # drip tray
    for x,k in ((-0.05,'tap_blue'),(0.05,'tap_red')): box(b,(x,-0.19,0.80),(0.03,0.04,0.035),k,skip=('back',))
    box(b,(0,-0.16,0.50),(0.20,0.006,0.06),'label',skip=('back',))
    b.lathe([(0.075,0.94),(0.135,0.97),(0.135,1.05),(0.13,1.07),(0.135,1.09),(0.135,1.20),(0.10,1.27),(0.03,1.29),(0.025,1.30)],12,'bottle',cap_top=True)
    b.cbox((0,0,0),(0.32,0.32,1.30))

# ------------------------------------------------------------------ lecture_seating_row (6 fixed seats, tablet arms)
def lecture_seating_row(b, hi=False):
    n=6; p=0.62; x0=-(n*p)/2
    for i in range(n+1):
        x=x0+i*p
        ext_x(b,[(-0.22,0.0),(0.26,0.0),(0.26,0.06),(0.14,0.62),(-0.08,0.66),(-0.22,0.60)],x-0.03,x+0.03,'std')
        box(b,(x,-0.05,0.62),(0.07,0.30,0.035),'lam')                                          # arm cap
    for i in range(n):
        x=x0+(i+0.5)*p
        ext_x(b,[(-0.26,0.42),(0.16,0.43),(0.16,0.50),(-0.24,0.49),(-0.27,0.46)],x-0.25,x+0.25,'seatfab')
        box(b,(x,0.0,0.36),(0.46,0.38,0.05),'plastic_black')
        ext_x(b,[(0.17,0.46),(0.22,0.46),(0.30,0.90),(0.25,0.91)],x-0.26,x+0.26,'seatfab')
        ext_x(b,[(0.225,0.46),(0.235,0.46),(0.315,0.90),(0.305,0.90)],x-0.26,x+0.26,'plastic_black')
        # tablet (kidney-ish) on the right arm
        tp=rrect(x+0.02,-0.40,x+0.30,-0.06,0.05,2); ext_z(b,tp,0.70,0.718,'lam')
        rod(b,(x+0.28,-0.06,0.70),(x+0.31,0.0,0.64),0.01,4,'alum')
    maker_plate(b,(x0+0.034,-0.10,0.30),hi,0.06,0.025,rz=math.pi/2)
    b.cbox((0,0.02,0),(n*p+0.06,0.56,0.62)); b.cbox((0,0.25,0.62),(n*p+0.06,0.10,0.30))

# ------------------------------------------------------------------ tablet_arm_chair
def tablet_arm_chair(b, hi=False):
    for x in (-0.22,0.22):
        rod(b,(x,-0.26,0.0),(x,0.24,0.0),0.011,6,'chrome')
        rod(b,(x,-0.24,0.0),(x,-0.20,0.43),0.011,6,'chrome'); rod(b,(x,0.22,0.0),(x,0.18,0.43),0.011,6,'chrome')
        rod(b,(x,0.18,0.43),(x,0.24,0.80),0.011,6,'chrome')
    box(b,(0,-0.02,0.20),(0.40,0.36,0.012),'chrome')                                           # book grid
    ext_x(b,[(-0.22,0.43),(0.20,0.42),(0.21,0.455),(-0.21,0.47),(-0.23,0.455)],-0.23,0.23,'shell')
    ext_x(b,[(0.20,0.50),(0.235,0.50),(0.27,0.84),(0.235,0.845)],-0.22,0.22,'shell')
    rod(b,(0.26,0.10,0.43),(0.26,-0.05,0.70),0.012,6,'chrome')
    tp=[(0.10,-0.34),(0.30,-0.34),(0.32,-0.20),(0.32,0.02),(0.22,0.06),(0.18,-0.12),(0.08,-0.20)]
    ext_z(b,tp,0.70,0.718,'lam')
    maker_plate(b,(0,0.235,0.62),hi,0.06,0.02,rz=math.pi)
    b.cbox((0,0,0),(0.56,0.62,0.72))

# ------------------------------------------------------------------ boards (wall: back at +Y, face -Y)
def whiteboard_wall(b, hi=False):
    W,H=2.40,1.20
    box(b,(0,0.01,0.0),(W,0.02,H),'label',skip=('back',))
    for z,h in ((0.0,0.03),(H-0.03,0.03)): box(b,(0,-0.005,z),(W,0.03,h),'alum',skip=('back',))
    for x in (-W/2+0.015,W/2-0.015): box(b,(x,-0.005,0.0),(0.03,0.03,H),'alum',skip=('back',))
    box(b,(0,-0.05,0.0),(1.6,0.07,0.025),'alum',skip=('back',)); box(b,(0,-0.085,0.0),(1.6,0.006,0.045),'alum',skip=('back',))
    for i,k in enumerate(('tap_blue','tap_red','paint_black')): rod(b,(-0.5+0.14*i,-0.05,0.032),(-0.38+0.14*i,-0.05,0.032),0.008,6,k,caps=True)
    box(b,(0.35,-0.05,0.025),(0.14,0.05,0.04),'paint_black'); box(b,(0.35,-0.05,0.065),(0.14,0.05,0.012),'felt')
    if hi:
        y=-0.0005
        txt(b,hi,'Week 7: Coastal Ecology',0.075,(-0.45,y,1.04),'paint_navy'); 
        for k,s in enumerate(('- tide pools & zonation','- kelp forest food web','- estuary sediment','Quiz Friday!')):
            txt(b,hi,s,0.05,(-0.60,y,0.88-0.10*k),'ceramic' if k==3 else 'paint_navy')
        for (cx,cz) in ((0.55,0.80),(0.85,0.55),(0.40,0.45),(0.75,0.95)):
            ext_y(b,circ((cx,cz),0.07,10),y-0.0004,y,'leaf')
        for (a,c) in (((0.55,0.80),(0.85,0.55)),((0.55,0.80),(0.40,0.45)),((0.55,0.80),(0.75,0.95))):
            A=V(a); C=V(c); d=(C-A).normalized(); nn=V((-d.y,d.x))*0.006
            ext_y(b,[tuple(A+nn),tuple(C+nn),tuple(C-nn),tuple(A-nn)],y-0.0003,y,'leaf')
    b.cbox((0,0,0),(W,0.06,H))
def projector_screen(b, hi=False):
    W=2.40
    box(b,(0,-0.02,1.66),(W+0.10,0.10,0.12),'paint_white'); for_=None
    for x in (-W/2-0.03,W/2+0.03): ext_x(b,circ((-0.02,1.72),0.065,6),x-0.015 if x<0 else x,x if x<0 else x+0.015,'paint_grey')
    box(b,(0,-0.01,0.20),(W-0.06,0.006,1.46),'screenfab',skip=('back',))
    for z,h in ((1.56,0.10),(0.20,0.06)): box(b,(0,-0.0135,z),(W-0.06,0.002,h),'paint_black',skip=('back',))
    for x in (-W/2+0.06,W/2-0.06): box(b,(x,-0.0135,0.26),(0.06,0.002,1.30),'paint_black',skip=('back',))
    box(b,(0,-0.015,0.15),(W-0.04,0.03,0.05),'alum'); box(b,(0,-0.035,0.06),(0.04,0.01,0.09),'plastic_black')
    maker_plate(b,(0.9,-0.073,1.68),hi,0.10,0.03)
    b.cbox((0,0,0.15),(W,0.10,1.65))
def noticeboard_wall(b, hi=False):
    W,H=1.20,0.90
    box(b,(0,0.005,0.0),(W,0.03,H),'cork',skip=('back',))
    for z,h in ((0.0,0.04),(H-0.04,0.04)): box(b,(0,-0.005,z),(W,0.04,h),'oak',skip=('back',))
    for x in (-W/2+0.02,W/2-0.02): box(b,(x,-0.005,0.0),(0.04,0.04,H),'oak',skip=('back',))
    fl=[(-0.38,0.52,0.30,0.30,'label','BAKE SALE','Sat 10am'),(-0.04,0.55,0.21,0.28,'badge','YOGA','Tue/Thu'),(0.30,0.50,0.30,0.22,'flyer_g','BEACH','CLEAN-UP'),
        (-0.36,0.10,0.28,0.30,'flyer_y','LOST CAT','call 555'),(0.0,0.08,0.24,0.32,'label','CHOIR','new voices'),(0.33,0.12,0.26,0.24,'flyer_b','BOOK','CLUB')]
    for (x,z,w,h,k,t1,t2) in fl:
        box(b,(x,-0.012,z),(w,0.002,h),k,skip=('back',))
        txt(b,hi,t1,h*0.16,(x,-0.0132,z+h*0.70),'paint_black'); txt(b,hi,t2,h*0.10,(x,-0.0132,z+h*0.42),'paint_navy')
        if hi: ext_y(b,circ((x,z+h-0.02),0.008,6),-0.020,-0.013,'ceramic')
    b.cbox((0,0,0),(W,0.04,H))
def directory_board(b, hi=False):
    W,H=1.0,1.6
    box(b,(0,0.01,0),(W,0.02,H),'keypad',skip=('back',))
    for z,h in ((0.0,0.03),(H-0.03,0.03),(H-0.20,0.012)): box(b,(0,-0.005,z),(W,0.03,h),'alum',skip=('back',))
    for x in (-W/2+0.015,W/2-0.015): box(b,(x,-0.005,0),(0.03,0.03,H),'alum',skip=('back',))
    box(b,(0,-0.002,H-0.18),(W-0.06,0.006,0.14),'plate',skip=('back',))
    txt(b,hi,'DIRECTORY',0.08,(0,-0.0055,H-0.11),'paint_black')
    rows=['LOBBY / INFORMATION    1','RECORDS  101','PERMITS  102','CASHIER  103','ADMISSIONS  110','STUDENT SERVICES  115','FINANCIAL AID  120',
          'LECTURE HALL A  130','LIBRARY  2','DEAN\'S OFFICE  201','FACULTY OFFICES  210-240','RESTROOMS  >','ELEVATOR  <']
    for k,s in enumerate(rows): txt(b,hi,s,0.042,(0,-0.0005,H-0.30-0.095*k),'paint_white')
    box(b,(0,-0.012,0.03),(W-0.06,0.004,H-0.24),'glass',skip=('back',)) if False else None
    b.cbox((0,0,0),(W,0.05,H))
def departure_board(b, hi=False):
    W,H=2.0,0.6
    box(b,(0,0,0),(W,0.10,H),'paint_black')
    box(b,(0,-0.051,0.04),(W-0.08,0.004,H-0.12),'keypad',skip=('back',))
    box(b,(0,-0.051,H-0.075),(W-0.08,0.004,0.06),'screen',skip=('back',))
    txt(b,hi,'DEPARTURES      ROUTE        TIME      BAY',0.034,(0,-0.0535,H-0.045),'paint_white')
    rows=[('901  IMPERIAL BEACH','10:15','1'),('904  ORANGE AVE','10:22','2'),('FERRY  BROADWAY PIER','10:30','DOCK'),('901  SAN DIEGO','10:41','1'),('93  NORTH ISLAND','10:55','3')]
    for k,(a,t,bay) in enumerate(rows):
        z=H-0.13-0.085*k
        txt(b,hi,a,0.044,(-0.42,-0.0535,z),'brass'); txt(b,hi,t,0.044,(0.38,-0.0535,z),'brass'); txt(b,hi,bay,0.044,(0.78,-0.0535,z),'brass')
    for x in (-0.8,0.8): rod(b,(x,0,H),(x,0,H+0.40),0.008,4,'chrome')
    b.cbox((0,0,0),(W,0.10,H))
def listing_board_wall(b, hi=False):
    W,H=1.80,1.20
    box(b,(0,0.01,0),(W,0.02,H),'paint_navy',skip=('back',))
    for z,h in ((0.0,0.03),(H-0.03,0.03)): box(b,(0,-0.005,z),(W,0.03,h),'alum',skip=('back',))
    for x in (-W/2+0.015,W/2-0.015): box(b,(x,-0.005,0),(0.03,0.03,H),'alum',skip=('back',))
    box(b,(0,-0.001,H-0.15),(W-0.08,0.004,0.10),'label',skip=('back',)); txt(b,hi,'FEATURED HOMES - CORONADO',0.06,(0,-0.0035,H-0.10),'paint_navy')
    prices=['$1,895,000','$2,450,000','$989,000','$3,200,000','$1,250,000','$4,750,000','$1,595,000','$2,095,000']
    for i in range(8):
        cx=-0.63+0.42*(i%4); cz=0.55 if i<4 else 0.10; w,h=0.38,0.40
        box(b,(cx,-0.002,cz),(w,0.004,h),'label',skip=('back',))
        if hi:
            y=-0.0045
            ext_y(b,[(cx-0.17,cz+0.13),(cx+0.17,cz+0.13),(cx+0.17,cz+0.37),(cx-0.17,cz+0.37)],y-0.0003,y,'screen')
            ext_y(b,[(cx-0.17,cz+0.13),(cx+0.17,cz+0.13),(cx+0.17,cz+0.17),(cx-0.17,cz+0.17)],y-0.0006,y,'leaf')
            hx=cx-0.06+0.03*(i%3); ext_y(b,[(hx-0.09,cz+0.17),(hx+0.09,cz+0.17),(hx+0.09,cz+0.26),(hx-0.09,cz+0.26)],y-0.0006,y,'paint_cream')
            ext_y(b,[(hx-0.11,cz+0.26),(hx+0.11,cz+0.26),(hx,cz+0.32)],y-0.0009,y,'ceramic')
            ext_y(b,[(hx-0.02,cz+0.17),(hx+0.02,cz+0.17),(hx+0.02,cz+0.22),(hx-0.02,cz+0.22)],y-0.0012,y,'walnut')
            if i%2: rod(b,(cx+0.13,y-0.001,cz+0.17),(cx+0.13,y-0.001,cz+0.33),0.006,4,'walnut'); ext_y(b,circ((cx+0.13,cz+0.34),0.035,7),y-0.0012,y,'leaf')
            txt(b,hi,prices[i],0.045,(cx,y,cz+0.085),'paint_navy'); txt(b,hi,'3 BD  2 BA  ocean view' if i%2 else '4 BD  3 BA  pool',0.022,(cx,y,cz+0.035),'paint_black')
    b.cbox((0,0,0),(W,0.05,H))
def key_rack_wall(b, hi=False):
    W,H=0.80,0.60
    box(b,(0,0.005,0),(W,0.03,H),'wal',skip=('back',))
    box(b,(0,-0.012,H-0.11),(0.30,0.006,0.07),'plate',skip=('back',)); txt(b,hi,'ROOM KEYS',0.04,(0,-0.0155,H-0.075),'paint_black')
    for r,z in enumerate((0.30,0.08)):
        for i in range(8):
            x=-0.33+i*0.094
            if hi: rod(b,(x,-0.01,z+0.14),(x,-0.035,z+0.15),0.003,4,'brass',caps=True); txt(b,hi,str(101+r*8+i),0.02,(x,-0.0105,z+0.175),'brass')
            if (i*3+r)%5!=2:
                fq(b,[V((x-0.016,-0.03,z)),V((x+0.016,-0.03,z)),V((x+0.016,-0.03,z+0.075)),V((x-0.016,-0.03,z+0.075))],'tag_r' if (i+r)%3==0 else 'tag_g' if (i+r)%3==1 else 'tag_b',(0,-1,0),0.032,0.075)
                fq(b,[V((x-0.005,-0.028,z+0.075)),V((x+0.005,-0.028,z+0.075)),V((x+0.005,-0.028,z+0.14)),V((x-0.005,-0.028,z+0.14))],'brass',(0,-1,0),0.01,0.065)
    b.cbox((0,0,0),(W,0.06,H))
def cubicle_partition(b, hi=False):
    W,H=1.60,1.30
    box(b,(0,0,0.05),(W-0.06,0.05,H-0.08),'panelfab',skip=('bottom','top','left','right'))
    for x in (-W/2+0.03,W/2-0.03): box(b,(x,0,0.0),(0.06,0.06,H-0.03),'alum',skip=('bottom',))
    box(b,(0,0,H-0.03),(W,0.06,0.03),'alum'); box(b,(0,0,0.0),(W-0.06,0.055,0.05),'plastic_black',skip=('bottom','left','right'))
    for x in (-W/2+0.03,W/2-0.03): box(b,(x,0,0),(0.06,0.50,0.02),'alum',skip=('bottom',))
    box(b,(-0.30,-0.0265,0.80),(0.21,0.002,0.28),'label',skip=('back',)); txt(b,hi,'Q3 TARGETS',0.026,(-0.30,-0.028,1.02),'paint_navy')
    if hi:
        for k in range(6): ext_y(b,[(-0.38,0.86+0.025*k),(-0.22-0.02*(k%3),0.86+0.025*k),(-0.22-0.02*(k%3),0.865+0.025*k),(-0.38,0.865+0.025*k)],-0.0285,-0.028,'paint_black')
    box(b,(0.25,-0.0265,0.90),(0.12,0.002,0.12),'badge',skip=('back',)) 
    box(b,(0.40,-0.0265,0.86),(0.10,0.002,0.10),'flyer_g',skip=('back',))
    b.cbox((0,0,0),(W,0.06,H))

# ------------------------------------------------------------------ machines
def atm_wall(b, hi=False):
    box(b,(0,0.17,0),(0.80,0.06,1.70),'paint_grey',skip=('back',))                           # wall fascia
    box(b,(0,0.13,0.0),(0.80,0.02,0.10),'plastic_black',skip=('back',))
    box(b,(0,0.02,0.82),(0.62,0.26,0.22),'vault',skip=('back',)); box(b,(0,0.08,1.04),(0.60,0.14,0.48),'vault_dk',skip=('back','bottom'))                             # unit body
    box(b,(0,0.12,1.50),(0.78,0.04,0.20),'atm_hdr',skip=('back',))                           # lit header
    txt(b,hi,'ATM  24h',0.10,(0,0.0985,1.60),'screen')
    ang=math.radians(18)
    sc=[V((-0.24,-0.095,1.20)),V((0.24,-0.095,1.20)),V((0.24,-0.095+0.30*math.sin(ang),1.20+0.30*math.cos(ang))),V((-0.24,-0.095+0.30*math.sin(ang),1.20+0.30*math.cos(ang)))]
    fq(b,sc,'screen',(0,-math.cos(ang),math.sin(ang)),0.48,0.30)
    ext_x(b,[(-0.11,1.0),(0.04,1.0),(0.04,1.04),(-0.11,1.04)],-0.29,0.29,'vault_dk')               # keypad shelf
    box(b,(-0.05,-0.06,1.04),(0.20,0.14,0.006),'keypad',skip=('bottom',))
    box(b,(0.17,-0.06,1.04),(0.10,0.10,0.006),'keypad',skip=('bottom',))
    box(b,(0.18,-0.112,1.13),(0.10,0.01,0.02),'plastic_black',skip=('back',)); box(b,(0,-0.112,0.90),(0.30,0.01,0.03),'plastic_black',skip=('back',))
    for sg in (-1,1): ext_x(b,[(-0.11,1.04),(0.13,1.04),(0.13,1.52),(0.00,1.52)],sg*0.31-0.01,sg*0.31+0.01,'vault_dk')   # privacy hood
    box(b,(0,0.01,1.52),(0.64,0.24,0.012),'vault_dk')
    if hi:
        txt(b,hi,'WELCOME',0.05,(0,-0.090+0.12*math.sin(ang),1.20+0.20*math.cos(ang)),'paint_white',(1,0,0),(0,math.sin(ang),math.cos(ang)))
        txt(b,hi,'insert card',0.025,(0,-0.090+0.06*math.sin(ang),1.20+0.10*math.cos(ang)),'paint_cream',(1,0,0),(0,math.sin(ang),math.cos(ang)))
    b.cbox((0,0.05,0.0),(0.80,0.30,1.70))
def ticket_machine(b, hi=False):
    box(b,(0,0,0),(0.80,0.50,0.06),'plastic_black',skip=('bottom',))
    box(b,(0,0.02,0.06),(0.78,0.46,1.62),'tm_body',skip=('bottom','front'))
    box(b,(0,-0.215,0.06),(0.78,0.03,1.62),'paint_white',skip=('back',))
    ext_x(b,[(-0.25,1.68),(0.25,1.68),(0.25,1.76),(-0.21,1.80),(-0.25,1.78)],-0.40,0.40,'tm_body')
    box(b,(0,-0.235,1.48),(0.70,0.012,0.18),'tm_hdr',skip=('back',)); txt(b,hi,'TICKETS',0.10,(0,-0.2415,1.57),'paint_white')
    txt(b,hi,'MTS  trolley . bus . ferry',0.03,(0,-0.2415,1.50),'paint_white')
    box(b,(-0.08,-0.24,1.06),(0.42,0.02,0.32),'plastic_black',skip=('back',)); box(b,(-0.08,-0.251,1.08),(0.38,0.004,0.28),'screen',skip=('back',))
    if hi:
        txt(b,hi,'Choose ticket',0.032,(-0.08,-0.2535,1.30),'paint_white')
        for k in range(3): ext_y(b,[(-0.24,1.12+0.055*k),(0.08,1.12+0.055*k),(0.08,1.16+0.055*k),(-0.24,1.16+0.055*k)],-0.254,-0.2535,'badge' if k==2 else 'chrome')
    box(b,(0.24,-0.24,1.12),(0.12,0.03,0.16),'steel',skip=('back',)); box(b,(0.24,-0.256,1.20),(0.06,0.004,0.01),'plastic_black',skip=('back',))
    box(b,(0.24,-0.24,0.96),(0.12,0.03,0.10),'keypad',skip=('back',))
    box(b,(0,-0.24,0.62),(0.36,0.04,0.16),'plastic_black',skip=('back',))                    # ticket tray
    box(b,(0,-0.262,0.66),(0.30,0.004,0.06),'paint_black',skip=('back',))
    box(b,(0,-0.232,0.18),(0.60,0.004,0.34),'label',skip=('back',)); txt(b,hi,'SYSTEM MAP',0.03,(0,-0.235,0.48),'paint_navy')
    if hi:
        for (x0,z0,x1,z1,k) in ((-0.25,0.24,0.25,0.25,'ceramic'),(-0.10,0.22,-0.09,0.44,'screen'),(0.05,0.30,0.25,0.42,'leaf')):
            ext_y(b,[(x0,z0),(x1,z0),(x1,z1+0.008),(x0,z1+0.008)],-0.2355,-0.235,k)
    b.cbox((0,0,0),(0.80,0.50,1.80))
def reverse_vending_machine(b, hi=False):
    box(b,(0,0,0),(1.0,0.78,0.08),'plastic_black',skip=('bottom',))
    box(b,(0,0.02,0.08),(1.0,0.76,1.82),'paint_white',skip=('bottom','front'))
    box(b,(0,-0.37,0.08),(1.0,0.02,1.82),'rvm_green',skip=('back',))
    box(b,(0,-0.385,1.46),(0.90,0.01,0.38),'label',skip=('back',))
    txt(b,hi,'BOTTLE & CAN',0.085,(0,-0.3905,1.73),'leaf'); txt(b,hi,'RETURN',0.10,(0,-0.3905,1.60),'leaf'); txt(b,hi,'5c - 10c per container',0.035,(0,-0.3905,1.50),'paint_black')
    ext_y(b,circ((0,1.12),0.13,14),-0.43,-0.38,'steel'); ext_y(b,circ((0,1.12),0.085,12),-0.432,-0.43,'paint_black')
    if hi: ext_y(b,circ((0,1.12),0.11,24),-0.433,-0.432,'chrome')
    box(b,(0.32,-0.40,1.02),(0.22,0.03,0.18),'plastic_black',skip=('back',)); box(b,(0.32,-0.417,1.04),(0.18,0.004,0.14),'screen',skip=('back',))
    txt(b,hi,'0.45',0.05,(0.32,-0.4195,1.10),'paint_white')
    box(b,(0.32,-0.40,0.86),(0.12,0.03,0.04),'plastic_black',skip=('back',))
    box(b,(-0.32,-0.39,0.86),(0.16,0.012,0.22),'label',skip=('back',)); txt(b,hi,'insert one at a time',0.018,(-0.32,-0.3965,1.00),'paint_black')
    box(b,(0,-0.40,0.20),(0.70,0.04,0.30),'paint_grey',skip=('back',))
    b.cbox((0,0,0),(1.0,0.80,1.90))
def queue_ticket_dispenser(b, hi=False):
    b.lathe([(0.0,0.0),(0.15,0.0),(0.15,0.02),(0.11,0.035)],8,'paint_black',cap_top=True)
    cyl(b,(0,0,0.035),0.022,1.10,6,'chrome',top=False)
    box(b,(0,0,1.10),(0.16,0.12,0.16),'tm_hdr')
    box(b,(0,-0.062,1.14),(0.10,0.002,0.03),'paint_black',skip=('back',))
    fq(b,[V((-0.03,-0.065,1.135)),V((0.03,-0.065,1.135)),V((0.03,-0.10,1.12)),V((-0.03,-0.10,1.12))],'label',(0,-0.4,1),0.06,0.04)
    box(b,(0,0,1.26),(0.28,0.03,0.14),'label'); txt(b,hi,'TAKE A NUMBER',0.03,(0,-0.0155,1.35),'paint_black')
    box(b,(0,-0.017,1.27),(0.10,0.004,0.05),'keypad',skip=('back',)); txt(b,hi,'47',0.04,(0,-0.0195,1.295),'ceramic')
    b.cbox((0,0,0),(0.30,0.30,1.40))
def drive_thru_window(b, hi=False):
    W,H=1.20,1.20
    for z,h in ((0.0,0.06),(H-0.06,0.06)): box(b,(0,0.10,z),(W,0.20,h),'alum')
    for x in (-W/2+0.03,W/2-0.03): box(b,(x,0.10,0.06),(0.06,0.20,H-0.12),'alum',skip=('bottom','top'))
    box(b,(-0.27,0.13,0.06),(0.54,0.02,H-0.12),'glass',skip=())
    box(b,(0.27,0.17,0.06),(0.54,0.02,H-0.12),'glass',skip=())
    box(b,(0,0.13,0.06),(0.04,0.04,H-0.12),'alum',skip=('bottom','top'))
    box(b,(0,-0.10,0.0),(W+0.06,0.20,0.03),'steel')                                          # inside ledge
    box(b,(-0.36,-0.10,0.03),(0.36,0.14,0.10),'paint_black',skip=('bottom',))                # cash drawer
    box(b,(0.36,-0.05,0.03),(0.18,0.10,0.24),'plastic_black',skip=('bottom',)); box(b,(0.36,-0.101,0.12),(0.14,0.004,0.10),'screen',skip=('back',))
    txt(b,hi,'#214  $12.85',0.022,(0.36,-0.1035,0.18),'paint_white')
    box(b,(0,0.115,H-0.25),(0.36,0.004,0.12),'label',skip=()); txt(b,hi,'PULL',0.05,(0,0.1125,H-0.19),'ceramic',(1,0,0))
    b.cbox((0,0.0,0),(W,0.20,H))
def _disc_y(b, c, r, y0, y1, n, key, caps=(True,False)):
    return ext_y(b,circ(c,r,n,math.pi/n),y0,y1,key,caps=caps)
def vault_door(b, hi=False):
    W,H=2.0,2.2; cz=1.10
    box(b,(0,0.10,0),(W,0.20,0.15),'steel'); box(b,(0,0.10,H-0.15),(W,0.20,0.15),'steel')
    for x in (-W/2+0.075,W/2-0.075): box(b,(x,0.10,0.15),(0.15,0.20,H-0.30),'steel',skip=('bottom','top'))
    box(b,(0,0.18,0.15),(W-0.30,0.04,H-0.30),'paint_grey',skip=('back',))
    n=20 if hi else 14
    _disc_y(b,(0,cz),0.86,-0.06,0.16,n,'vault',caps=(False,False))
    _disc_y(b,(0,cz),0.86,-0.06,-0.06,n,'vault',caps=(True,False)) if False else None
    ext_y(b,[(x,z) for x,z in circ((0,cz),0.86,n,math.pi/n)],-0.06,-0.06+0.0001,'vault',caps=(False,False)) if False else None
    _disc_y(b,(0,cz),0.86,-0.06,0.16,n,'vault',caps=(True,False))
    _disc_y(b,(0,cz),0.74,-0.10,-0.06,n,'vault_dk',caps=(True,False))
    _disc_y(b,(0,cz),0.56,-0.13,-0.10,n,'vault',caps=(True,False))
    _disc_y(b,(0,cz),0.12,-0.20,-0.13,10,'chrome',caps=(True,False))
    for k in range(12):
        a=2*math.pi*k/12; cyl_c=(0.80*math.cos(a),cz+0.80*math.sin(a))
        _disc_y(b,cyl_c,0.03,-0.075,-0.06,6,'chrome',caps=(True,False))
    for k in range(4):
        a=math.pi/4+math.pi/2*k
        rod(b,(0.10*math.cos(a),-0.18,cz+0.10*math.sin(a)),(0.40*math.cos(a),-0.24,cz+0.40*math.sin(a)),0.022,6,'chrome')
        b.tube((0.40*math.cos(a),-0.24,cz+0.40*math.sin(a)),(0.45*math.cos(a),-0.245,cz+0.45*math.sin(a)),0.032,0.032,6,'chrome',cap0=True,cap1=True)
    for z in (cz-0.55,cz+0.55): rod(b,(0.86,-0.04,z-0.18),(0.86,-0.04,z+0.18),0.07,8,'steel',caps=True); box(b,(0.88,0.02,z-0.14),(0.18,0.10,0.28),'steel')
    box(b,(-0.36,-0.131,cz+0.18),(0.24,0.008,0.08),'plate',skip=('back',))
    txt(b,hi,'MOSLER',0.04,(-0.36,-0.1355,cz+0.235),'paint_black'); txt(b,hi,'TIME LOCK',0.022,(-0.36,-0.1355,cz+0.20),'paint_black')
    box(b,(0.36,-0.131,cz+0.16),(0.14,0.008,0.14),'keypad',skip=('back',))
    b.cbox((0,0.0,0),(W,0.40,H))

# ------------------------------------------------------------------ misc
def luggage_cart(b, hi=False):
    box(b,(0,0,0.12),(1.06,0.58,0.05),'paint_black',skip=())
    box(b,(0,0,0.17),(1.04,0.56,0.012),'cush',skip=('bottom',))
    for x in (-0.47,0.47):
        for y in (-0.23,0.23):
            cyl(b,(x,y,0.0),0.05,0.04,6,'rubber'); box(b,(x,y,0.04),(0.04,0.06,0.08),'chrome',skip=('top',))
    for (a,c) in (((-0.53,-0.29),(0.53,-0.29)),((0.53,-0.29),(0.53,0.29)),((0.53,0.29),(-0.53,0.29)),((-0.53,0.29),(-0.53,-0.29))):
        rod(b,(a[0],a[1],0.15),(c[0],c[1],0.15),0.014,6,'brass')
    for x in (-0.50,0.50):
        rod(b,(x,-0.24,0.17),(x,-0.24,1.55),0.016,6,'brass'); rod(b,(x,0.24,0.17),(x,0.24,1.55),0.016,6,'brass')
        b.sweep([(x,-0.24,1.55)]+[(x,0.24*math.cos(math.radians(t)),1.55+0.24*math.sin(math.radians(t))) for t in range(-150,-29,30)][1:]+[(x,0.24,1.55)],0.016,6,'brass',cap0=False,cap1=False) if False else None
        pts=[(x,-0.24*math.cos(math.radians(t)),1.55+0.22*math.sin(math.radians(t))) for t in range(0,181,30)]
        b.sweep(pts,0.016,6,'brass',cap0=False,cap1=False)
    rod(b,(-0.50,0,1.77),(0.50,0,1.77),0.018,6,'brass',caps=True)
    # a suitcase and a duffel on the deck
    box(b,(-0.18,0.0,0.182),(0.62,0.40,0.24),'case'); box(b,(-0.18,0.0,0.422),(0.18,0.03,0.03),'plastic_black')
    rod(b,(0.18,-0.18,0.32),(0.18,0.18,0.32),0.13,8,'duffel',caps=True)
    maker_plate(b,(0.30,-0.293,0.13),hi,0.10,0.03)
    b.cbox((0,0,0),(1.10,0.60,1.80))
def model_house_display(b, hi=False):
    box(b,(0,0,0),(0.66,0.66,0.06),'paint_black',skip=('bottom',))
    box(b,(0,0,0.06),(0.60,0.60,0.80),'paint_white',skip=('bottom',))
    box(b,(0,0,0.86),(0.80,0.80,0.03),'oak')
    box(b,(0,0,0.89),(0.74,0.74,0.012),'lawn',skip=('bottom',))
    box(b,(0.10,-0.20,0.902),(0.12,0.34,0.002),'paint_cream',skip=('bottom',))
    box(b,(-0.18,-0.25,0.902),(0.20,0.14,0.002),'pool',skip=('bottom',))
    box(b,(0.02,0.12,0.902),(0.44,0.26,0.16),'house',skip=('bottom',))
    box(b,(0.27,0.06,0.902),(0.18,0.20,0.11),'house',skip=('bottom',))
    ext_x(b,[(-0.01,1.062),(0.25,1.062),(0.12,1.15)],-0.21,0.25,'roof')
    ext_x(b,[(-0.05,1.012),(0.17,1.012),(0.06,1.06)],0.18,0.37,'roof')
    for x in (-0.12,0.0,0.12): box(b,(x,-0.011,0.95),(0.06,0.004,0.06),'screen',skip=('back',))
    box(b,(0.27,-0.041,0.902),(0.12,0.004,0.08),'paint_grey',skip=('back',))
    for (x,y) in ((-0.30,0.25),(0.30,-0.28)):
        rod(b,(x,y,0.90),(x+0.01,y,1.10),0.006,4,'walnut')
        for k in range(5): pg.B.quad(b,[V((x,y,1.10)),V((x+0.07*math.cos(k*1.256),y+0.07*math.sin(k*1.256),1.06)),V((x+0.08*math.cos(k*1.256+0.2),y+0.08*math.sin(k*1.256+0.2),1.075))],'lawn')
    box(b,(0,-0.402,0.862),(0.22,0.004,0.026),'plate',skip=('back',))
    txt(b,hi,'THE PALMS  lot 12',0.018,(0,-0.4045,0.875),'paint_black')
    b.cbox((0,0,0),(0.80,0.80,1.15))
def pizza_oven(b, hi=False):
    box(b,(0,0,0),(1.60,1.40,0.95),'steel',skip=('bottom','front'))
    box(b,(0,-0.69,0),(1.60,0.02,0.95),'steel',skip=('back',))
    box(b,(0,-0.705,0.08),(1.20,0.012,0.45),'paint_black',skip=('back',))                    # wood store opening
    for k in range(6): rod(b,(-0.50,-0.66+0.0,0.14+0.07*(k//3)+0.0),(0.50,-0.66,0.14+0.07*(k//3)),0.032,6,'walnut',caps=True) if k%3==0 else rod(b,(-0.52+0.18*(k%3),-0.62,0.14+0.07*(k//3)),(0.48+0.0*(k%3),-0.62,0.14+0.07*(k//3)),0.03,6,'walnut',caps=True)
    box(b,(0,0,0.95),(1.64,1.44,0.05),'stone')
    n=12 if hi else 10
    prof=[(0.74,1.0),(0.74,1.12),(0.70,1.30),(0.60,1.46),(0.44,1.58),(0.24,1.65),(0.0,1.67)]
    b.lathe(prof,n,'dome',c=(0,0.05,0),cap_top=False)
    # mouth: arch front with steel trim + ember glow inside
    ar=[(-0.26,1.0),(0.26,1.0)]+[(0.26*math.cos(math.radians(t)),1.18+0.12*math.sin(math.radians(t))) for t in range(0,181,30)][0:]
    ar=[(-0.27,1.0),(0.27,1.0),(0.27,1.18)]+[(0.27*math.cos(math.radians(t)),1.18+0.13*math.sin(math.radians(t))) for t in range(30,151,30)]+[(-0.27,1.18)]
    ext_y(b,ar,-0.78,-0.62,'steel')
    ar2=[(-0.21,1.02),(0.21,1.02),(0.21,1.17)]+[(0.21*math.cos(math.radians(t)),1.17+0.10*math.sin(math.radians(t))) for t in range(30,151,30)]+[(-0.21,1.17)]
    ext_y(b,ar2,-0.785,-0.78,'ember',caps=(True,False))
    box(b,(0,-0.78,0.98),(0.62,0.06,0.03),'steel')                                          # landing shelf
    rod(b,(0,0.30,1.62),(0,0.30,2.10),0.10,8,'steel_dk')
    box(b,(0,-0.701,0.70),(0.40,0.006,0.12),'plate',skip=('back',)); txt(b,hi,'FORNO NAPOLI',0.045,(0,-0.705,0.76),'paint_black')
    if hi:
        for k in range(10): ext_y(b,[(-0.17+0.035*k,1.04),(-0.15+0.035*k,1.04),(-0.15+0.035*k,1.06),(-0.17+0.035*k,1.06)],-0.79,-0.785,'badge')
    b.cbox((0,0,0),(1.64,1.44,1.60))

# ------------------------------------------------------------------ showroom_car (lofted coupe body, length along X, nose +X)
def showroom_car(b, hi=False):
    # stations: x, bottom z, rocker half-width, belt z, belt half-width, roof z, roof half-width, glass?
    S=[(-2.25,0.36,0.70,0.66,0.66,0.70,0.40,0),(-2.18,0.28,0.80,0.80,0.80,0.84,0.55,0),(-2.00,0.26,0.86,0.84,0.84,0.88,0.62,0),
       (-1.72,0.48,0.88,0.86,0.86,0.90,0.65,0),(-1.38,0.62,0.88,0.87,0.87,0.92,0.66,0),(-1.04,0.48,0.88,0.88,0.86,1.14,0.60,1),
       (-0.70,0.26,0.89,0.89,0.85,1.30,0.58,1),(-0.20,0.25,0.90,0.90,0.85,1.36,0.60,1),(0.30,0.25,0.90,0.90,0.85,1.33,0.60,1),
       (0.80,0.26,0.89,0.88,0.86,1.06,0.66,1),(1.04,0.48,0.88,0.86,0.86,0.92,0.70,0),(1.38,0.62,0.87,0.84,0.85,0.86,0.70,0),
       (1.72,0.48,0.86,0.80,0.82,0.80,0.66,0),(2.00,0.28,0.80,0.72,0.74,0.73,0.58,0),(2.20,0.30,0.66,0.60,0.60,0.62,0.40,0),(2.26,0.36,0.50,0.52,0.48,0.54,0.30,0)]
    def prof(st):
        x,zb,wr,zbl,wb,zr,wrf,gl=st
        zt=zr; zm=zb+0.6*(zbl-zb)
        return [(0.0,zb+0.02),(wr-0.04,zb),(wr,zb+0.06),(wr+0.01,zm),(wb,zbl),(wrf+0.06,zt-0.04),(wrf*0.5,zt),(0.0,zt+0.005)]
    keys_band=lambda gl: ['carblk','carblk','car','car','glass' if gl else 'car','car','car']
    for sgn in (-1,1):
        for i in range(len(S)-1):
            A=prof(S[i]); Bp=prof(S[i+1]); xa=S[i][0]; xb=S[i+1][0]; gl=S[i][7] and S[i+1][7]
            for j in range(len(A)-1):
                k=keys_band(gl)[j]
                if j==4 and (S[i][7] or S[i+1][7]) and not gl: k='car'
                q=[V((xa,sgn*A[j][0],A[j][1])),V((xb,sgn*Bp[j][0],Bp[j][1])),V((xb,sgn*Bp[j+1][0],Bp[j+1][1])),V((xa,sgn*A[j+1][0],A[j+1][1]))]
                cen=sum(q,V())/4; out=V((0,sgn*0.6,0.5))+V((0,0,0)); want=V((0,cen.y,cen.z-0.55)).normalized()
                L1=(q[1]-q[0]).length; L2=(q[3]-q[0]).length
                fq(b,q,k,want,L1,L2)
    for st,want in ((S[0],(-1,0,0)),(S[-1],(1,0,0))):
        P=prof(st); x=st[0]; pts=[V((x,-y,z)) for y,z in P[::-1]]+[V((x,y,z)) for y,z in P[1:-1]]
        q=_orient(pts,want); b.faces(q,[tuple(range(len(q)))],'car',[[(p.y,p.z) for p in q]])
    # lights, grille, plates, mirrors, handles
    for sg in (-1,1):
        box(b,(2.205,sg*0.42,0.62),(0.06,0.26,0.07),'headlamp'); box(b,(-2.215,sg*0.44,0.70),(0.05,0.30,0.07),'taillamp')
        box(b,(0.70,sg*0.93,0.93),(0.12,0.06,0.07),'carblk')
        box(b,(-0.30,sg*0.905,0.80),(0.14,0.02,0.025),'chrome')
    box(b,(2.24,0,0.42),(0.04,0.60,0.14),'keypad'); box(b,(2.255,0,0.30),(0.02,0.30,0.08),'label'); box(b,(-2.26,0,0.48),(0.02,0.30,0.08),'label')
    txt(b,hi,'CORONADO',0.04,(2.2665,0,0.34),'paint_navy',(0,1,0),(0,0,1)); txt(b,hi,'CORONADO',0.04,(-2.2715,0,0.52),'paint_navy',(0,-1,0),(0,0,1))
    # wheels: tyre (tread + sidewall) and rim face, axis along Y
    n=14 if not hi else 24
    for xw in (-1.38,1.38):
        for sg in (-1,1):
            yo=sg*0.90; yi=sg*0.68; c=V((xw,0,0.33))
            def ring(r,y): return [V((xw+r*math.cos(2*math.pi*k/n),y,0.33+r*math.sin(2*math.pi*k/n))) for k in range(n)]
            R1=ring(0.33,yo-sg*0.02); R2=ring(0.33,yi); R0=ring(0.30,yo); Rr=ring(0.21,yo+sg*0.005)
            for k in range(n):
                k2=(k+1)%n
                fq(b,[R1[k],R2[k],R2[k2],R1[k2]],'tyre',(R1[k]+R1[k2])/2-V((xw,(yo+yi)/2,0.33)),0.15,0.22)
                fq(b,[R0[k],R1[k],R1[k2],R0[k2]],'tyre',V((0,sg,0))+((R0[k]+R0[k2])/2-V((xw,yo,0.33)))*0.5,0.15,0.03)
                fq(b,[Rr[k],R0[k],R0[k2],Rr[k2]],'tyre',V((0,sg,0)),0.15,0.09)
            q=_orient(Rr,(0,sg,0)); b.faces(q,[tuple(range(n))],'rim',[[(p.x,p.z) for p in q]])
            if hi:
                for s5 in range(5):
                    a=2*math.pi*s5/5; ext_y(b,[(xw+0.04*math.cos(a+0.25),0.33+0.04*math.sin(a+0.25)),(xw+0.19*math.cos(a+0.12),0.33+0.19*math.sin(a+0.12)),(xw+0.19*math.cos(a-0.12),0.33+0.19*math.sin(a-0.12)),(xw+0.04*math.cos(a-0.25),0.33+0.04*math.sin(a-0.25))],*( (yo+sg*0.005,yo+sg*0.02) if sg>0 else (yo-sg*0.0-0.02,yo-0.005)),'chrome')
            # arch liner
            box(b,(xw,sg*0.70,0.36),(0.80,0.02,0.32),'carblk',skip=('bottom',))
    b.cbox((0,0,0),(4.5,1.80,1.36))

def church_pew_short(b, hi=False): church_pew(b, hi, 1.80)   # 1.8 m: two per side in a church block
# ================================================================== POLISH (22 Nov, pass 2/3): priority props rebuilt
def _lerp(a,b_,t): return a+(b_-a)*t
# ------------------------------------------------------------------ showroom_car: unbranded mid-size coupe, nose +X
def _car_st(x):
    ax=abs(x)
    # plan half width (body), tapering at the ends
    e=max(0.0,(ax-1.80)/0.48); wr=0.89*(1-0.42*e*e)
    # roof / deck height along X
    if x<-1.18: zr=_lerp(0.95,0.90,min(1,(-1.18-x)/1.1)) - 0.10*max(0,(-2.0-x)/0.28)
    elif x<-0.50: zr=_lerp(0.95,1.33,(x+1.18)/0.68)
    elif x<0.30: zr=1.33+0.02*math.sin((x+0.5)/0.8*math.pi)
    elif x<1.10: zr=_lerp(1.33,0.93,(x-0.30)/0.80)
    else: zr=_lerp(0.93,0.80,(x-1.10)/1.18) - 0.06*max(0,(x-2.05)/0.23)
    cab=-1.18<x<1.10
    wrf=0.60 if cab else 0.74*(1-0.5*e*e)
    # body bottom: wheel arches (r 0.37 about the axle at z 0.33)
    zb=0.24
    for xw in (-1.38,1.38):
        dx=x-xw
        if abs(dx)<0.37: zb=max(zb,0.33+math.sqrt(0.37**2-dx*dx)-0.02)
    if ax>2.05: zb=max(zb,0.24+0.5*(ax-2.05))
    zbl=min(0.90,zr-0.03) if cab else zr-0.03
    zsh=min(zbl-0.09,zr-0.11)
    return dict(x=x,zb=zb,wr=wr,zbl=zbl,zsh=zsh,zr=zr,wrf=wrf,cab=cab)
def _car_prof(s):
    zb,wr,zbl,zsh,zr,wrf=s['zb'],s['wr'],s['zbl'],s['zsh'],s['zr'],s['wrf']
    p2=min(zb+0.07,zsh-0.05); p3=max(p2+0.03,_lerp(p2,zsh,0.55))
    return [(0.0,zb),(wr-0.07,zb),(wr-0.01,p2),(wr+0.005,p3),(wr+0.012,zsh),(wr-0.035,zbl),(wrf+0.05,zr-(0.045 if s['cab'] else 0.012)),(wrf*0.55,zr-0.004),(0.0,zr)]
def showroom_car(b, hi=False):
    XS=[-2.28,-2.24,-2.16,-2.04,-1.88]+[-1.38+d for d in (-0.37,-0.30,-0.20,-0.07,0.07,0.20,0.30,0.37)]+[-0.88,-0.62,-0.30,0.0,0.30,0.55,0.80]+[1.38+d for d in (-0.37,-0.30,-0.20,-0.07,0.07,0.20,0.30,0.37)]+[1.80,1.96,2.08,2.18,2.25,2.29]
    S=[_car_st(x) for x in XS]; P=[_car_prof(s) for s in S]
    nb=len(P[0])-1
    def key(i,j):
        s0,s1=S[i],S[i+1]; xm=(s0['x']+s1['x'])/2
        if j==0: return 'carblk'
        if j==1: return 'carblk' if (abs(xm)>2.0 or abs(abs(xm)-1.38)<0.40) else 'car'
        if j==5 and s0['cab'] and s1['cab']:
            if -0.22<xm<-0.10: return 'cglass'             # B pillar (blacked, reads as one glasshouse)
            return 'cglass'
        if j in (6,7) and s0['cab'] and s1['cab'] and (xm>0.32 or xm<-0.52): return 'cglass'   # windscreen / rear screen
        if j==2 and abs(xm)>2.02: return 'carblk'           # bumper valance
        return 'car'
    for sg in (-1,1):
        for i in range(len(S)-1):
            A=P[i]; Bp=P[i+1]; xa=S[i]['x']; xb=S[i+1]['x']
            LA=[0.0]; LB=[0.0]
            for j in range(nb): LA.append(LA[-1]+math.hypot(A[j+1][0]-A[j][0],A[j+1][1]-A[j][1])); LB.append(LB[-1]+math.hypot(Bp[j+1][0]-Bp[j][0],Bp[j+1][1]-Bp[j][1]))
            for j in range(nb):
                q=[V((xa,sg*A[j][0],A[j][1])),V((xb,sg*Bp[j][0],Bp[j][1])),V((xb,sg*Bp[j+1][0],Bp[j+1][1])),V((xa,sg*A[j+1][0],A[j+1][1]))]
                if (q[0]-q[3]).length<1e-4 and (q[1]-q[2]).length<1e-4: continue
                cen=sum(q,V())/4; want=V((0,cen.y,cen.z-0.60)).normalized()
                uv=[(xa,LA[j]),(xb,LB[j]),(xb,LB[j+1]),(xa,LA[j+1])]     # continuous metre uvs: x along, arc length round
                n_=V((0,0,0))
                for t in range(4): n_+=q[t].cross(q[(t+1)%4])
                if n_.dot(want)<0: q=q[::-1]; uv=uv[::-1]
                b.faces(q,[(0,1,2,3)],key(i,j),[uv],smooth=(j>0))
    for s,pr,want in ((S[0],P[0],(-1,0,0)),(S[-1],P[-1],(1,0,0))):
        x=s['x']; pts=[V((x,-y,z)) for y,z in pr[::-1]]+[V((x,y,z)) for y,z in pr[1:-1]]
        q=_orient(pts,want); b.faces(q,[tuple(range(len(q)))],'carblk' if want[0]>0 else 'car',[[(p.y,p.z) for p in q]])
    # door shut lines + sill, near geometry (3 mm proud, carblk)
    def at(x):
        for i in range(len(S)-1):
            if S[i]['x']<=x<=S[i+1]['x']:
                t=(x-S[i]['x'])/(S[i+1]['x']-S[i]['x']); return [(_lerp(a[0],c[0],t),_lerp(a[1],c[1],t)) for a,c in zip(P[i],P[i+1])]
    for xs in (0.86,-0.16,-1.02):
        pr=at(xs)
        for sg in (-1,1):
            for j in (2,3,4):
                a,c=pr[j],pr[j+1]
                q=[V((xs-0.004,sg*(a[0]+0.003),a[1])),V((xs+0.004,sg*(a[0]+0.003),a[1])),V((xs+0.004,sg*(c[0]+0.003),c[1])),V((xs-0.004,sg*(c[0]+0.003),c[1]))]
                fq(b,q,'carblk',(0,sg,0),0.008,0.1)
    for sg in (-1,1):
        # door handles, mirrors, side repeater
        for xh in (0.55,-0.40):
            pr=at(xh); y=pr[4][0]+0.012; z=pr[4][1]-0.04
            box(b,(xh,sg*y,z),(0.13,0.02,0.022),'chrome',skip=('left','right') if False else ())
        pr=at(0.95); y=pr[5][0]
        box(b,(0.95,sg*(y+0.06),pr[5][1]+0.01),(0.10,0.10,0.025),'carblk')
        box(b,(0.93,sg*(y+0.13),pr[5][1]+0.0),(0.14,0.06,0.09),'car')
        # head / tail lamps hugging the body corners
        box(b,(2.275,sg*0.36,0.64),(0.04,0.22,0.07),'headlamp',skip=('back',))
        box(b,(-2.275,sg*0.33,0.66),(0.03,0.30,0.08),'taillamp',skip=('front',))
        box(b,(2.26,sg*0.55,0.36),(0.03,0.14,0.05),'headlamp')   # fog lamp
        box(b,(-2.265,sg*0.56,0.40),(0.03,0.10,0.03),'taillamp')  # reflector
        # sill strip
        pr0=at(-0.95); pr1=at(0.95)
        fq(b,[V((-0.95,sg*(pr0[2][0]+0.004),pr0[2][1]-0.02)),V((0.95,sg*(pr1[2][0]+0.004),pr1[2][1]-0.02)),V((0.95,sg*(pr1[2][0]+0.004),pr1[2][1]+0.01)),V((-0.95,sg*(pr0[2][0]+0.004),pr0[2][1]+0.01))],'chrome',(0,sg,0),1.9,0.03)
    # grille (unbranded): dark mesh panel + chrome surround on the nose, plates
    box(b,(2.29,0,0.465),(0.02,0.60,0.15),'carblk',skip=('back',)); box(b,(2.296,0,0.615),(0.012,0.62,0.012),'chrome',skip=('back',))
    box(b,(-2.275,0,0.695),(0.02,0.36,0.02),'taillamp',skip=('front',))
    box(b,(2.30,0,0.37),(0.012,0.32,0.085),'label',skip=('back',)); box(b,(-2.29,0,0.45),(0.012,0.32,0.09),'label',skip=('front',))
    txt(b,hi,'DEMO',0.05,(2.3065,0,0.4125),'paint_navy',(0,1,0),(0,0,1)); txt(b,hi,'DEMO',0.05,(-2.2965,0,0.495),'paint_navy',(0,-1,0),(0,0,1))
    box(b,(-2.255,0,0.30),(0.04,1.40,0.08),'carblk')      # rear diffuser
    # wheels: tyre (tread + rounded shoulder), recessed dark dish, 5 spokes, rim lip, brake disc
    n=20
    for xw in (-1.38,1.38):
        for sg in (-1,1):
            yo=sg*0.905; yi=sg*0.70; zc=0.33
            def ring(r,y,nn=n): return [V((xw+r*math.cos(2*math.pi*k/nn),y,zc+r*math.sin(2*math.pi*k/nn))) for k in range(nn)]
            T1=ring(0.33,yo-sg*0.03); T2=ring(0.33,yi); S1=ring(0.305,yo); R0=ring(0.235,yo+sg*0.004); R1=ring(0.215,yo-sg*0.02)
            for k in range(n):
                k2=(k+1)%n; mid=V((xw,(yo+yi)/2,zc))
                fq(b,[T1[k],T2[k],T2[k2],T1[k2]],'tyre',(T1[k]+T1[k2])/2-mid,0.15,0.20,smooth=True)
                fq(b,[S1[k],T1[k],T1[k2],S1[k2]],'tyre',V((0,sg,0))+((S1[k]+S1[k2])/2-V((xw,yo,zc)))*1.5,0.15,0.04)
                fq(b,[R0[k],S1[k],S1[k2],R0[k2]],'tyre',V((0,sg,0)),0.15,0.07)
                fq(b,[R1[k],R0[k],R0[k2],R1[k2]],'rim',V((0,sg,0))-((R0[k]+R0[k2])/2-V((xw,yo,zc)))*2,0.1,0.03)
            q=_orient(R1,(0,sg,0)); b.faces(q,[tuple(range(n))],'carblk',[[(p.x,p.z) for p in q]])
            for s5 in range(5):
                a=2*math.pi*s5/5+0.3; ca,sa=math.cos(a),math.sin(a); pa,pb=-sa,ca
                p0=(xw+0.05*ca,zc+0.05*sa); p1=(xw+0.215*ca,zc+0.215*sa)
                pr=[(p0[0]+pa*0.028,p0[1]+pb*0.028),(p1[0]+pa*0.022,p1[1]+pb*0.022),(p1[0]-pa*0.022,p1[1]-pb*0.022),(p0[0]-pa*0.028,p0[1]-pb*0.028)]
                y0,y1=(yo-0.022,yo-0.006) if sg>0 else (yo+0.006,yo+0.022)
                ext_y(b,pr,y0,y1,'rim',caps=(sg<0,sg>0))
            hub=circ((xw,zc),0.055,8); y0,y1=(yo-0.02,yo-0.002) if sg>0 else (yo+0.002,yo+0.02)
            ext_y(b,hub,y0,y1,'rim',caps=(sg<0,sg>0))
            box(b,(xw-0.20,sg*0.80,0.33),(0.08,0.06,0.10),'paint_red' if False else 'taillamp')   # brake caliper
            box(b,(xw,sg*0.70,0.36),(0.78,0.02,0.34),'carblk',skip=('bottom',))
    b.cbox((0,0,0),(4.56,1.82,1.36))

# ------------------------------------------------------------------ stage_platform
def stage_platform(b, hi=False):
    W,D,H=6.0,2.60,0.60; yf=-1.10
    box(b,(0,0.20,0),(W,D,H-0.03),'stage',skip=('bottom','top','front'))
    box(b,(0,0.20,H-0.03),(W,D,0.03),'stage',skip=('bottom',))                                  # deck
    # deck seams (the 1.2 x 2.4 m risers): thin dark strips across the deck
    for x in (-1.8,-0.6,0.6,1.8): box(b,(x,0.20,H),(0.006,D,0.001),'paint_black',skip=('bottom','left','right','front','back'))
    box(b,(0,0.20,H),(W,0.006,0.001),'paint_black',skip=('bottom','left','right','front','back'))
    # black box-pleat skirt: one zig-zag strip
    n=36; pts=[V((-W/2+W*i/n,yf-0.02-(0.025 if i%2 else 0.0),0)) for i in range(n+1)]
    for i in range(n):
        a,c=pts[i],pts[i+1]
        fq(b,[V((a.x,a.y,0.0)),V((c.x,c.y,0.0)),V((c.x,c.y,H-0.05)),V((a.x,a.y,H-0.05))],'skirt',(0,-1,0),W/n,H-0.05)
    box(b,(0,yf-0.035,H-0.06),(W+0.02,0.05,0.04),'skirt_dk',skip=('back','bottom'))           # skirt clip band
    box(b,(0,yf-0.02,H-0.02),(W+0.02,0.06,0.025),'paint_white',skip=('back','bottom'))         # nosing / edge line
    for sx in (-2.45,2.45):
        for k,(y,h) in enumerate(((-1.46,0.20),(-1.30,0.40))):
            box(b,(sx,y,0),(1.0,0.16,h),'stage',skip=('bottom','back') if k else ('bottom',))
            box(b,(sx,y-0.08,h-0.012),(1.0,0.04,0.012),'paint_yellow',skip=('bottom','back'))  # safety nosing
        for xo in (sx-0.52,sx+0.52):                                                           # stringers
            ext_x(b,[(-1.55,0.0),(-1.13,0.0),(-1.13,0.60),(-1.38,0.40),(-1.55,0.20)],xo-0.02,xo+0.02,'stage_dk')
        # handrail on the outer side
        xo=sx+(0.50 if sx>0 else -0.50)
        rod(b,(xo,-1.50,0.20),(xo,-1.50,1.10),0.02,4,'paint_black'); rod(b,(xo,-1.18,0.60),(xo,-1.18,1.45),0.02,4,'paint_black')
        rod(b,(xo,-1.50,1.10),(xo,-1.18,1.45),0.022,6,'paint_black',caps=True)
    # two wedge floor monitors + a mic stand at the front edge
    for x in (-0.9,0.9):
        ext_x(b,[(-0.98,H),(-0.62,H),(-0.62,H+0.30),(-0.72,H+0.32)],x-0.22,x+0.22,'carblk' if False else 'plastic_black')
        box(b,(x,-0.98+0.0,H+0.02),(0.36,0.004,0.20),'keypad',skip=('back',)) if False else None
    cyl(b,(0,-0.80,H),0.13,0.015,8,'plastic_black'); rod(b,(0,-0.80,H+0.015),(0,-0.80,H+1.45),0.010,6,'chrome')
    rod(b,(0,-0.80,H+1.45),(0,-0.98,H+1.52),0.008,6,'plastic_black'); b.tube((0,-0.98,H+1.52),(0,-1.07,H+1.55),0.016,0.022,6,'plastic_black',cap0=False,cap1=True)
    maker_plate(b,(1.6,yf-0.066,0.05),hi,0.10,0.03)
    b.cbox((0,0.20,0),(W,D,H)); b.cbox((0,-1.30,0),(W,0.40,0.30))

# ------------------------------------------------------------------ cubicle_partition (free-standing 1.6 x 1.3 panel)
def cubicle_partition(b, hi=False):
    W,H,T=1.60,1.30,0.06
    box(b,(0,0,0.10),(W-0.08,T,H-0.14),'panelfab',skip=('bottom','top','left','right'))
    cap=[(-T/2-0.004,0.0),(T/2+0.004,0.0),(T/2+0.004,0.015)]+[(0.034*math.cos(math.radians(t)),0.015+0.022*math.sin(math.radians(t))) for t in (30,60,90,120,150)]+[(-T/2-0.004,0.015)]
    ext_x(b,[(y,z+H-0.04) for y,z in cap],-W/2,W/2,'alum')                                           # rounded top cap
    for x in (-W/2+0.02,W/2-0.02):
        ext_z(b,rrect(x-0.02,-T/2-0.004,x+0.02,T/2+0.004,0.012,2),0.03,H-0.04,'alum',caps=(False,False))  # posts
        ext_x(b,[(-0.26,0.0),(0.26,0.0),(0.24,0.03),(-0.24,0.03)],x-0.025,x+0.025,'alum')                 # stabiliser feet
        cyl(b,(x,-0.23,0.0),0.018,0.012,6,'rubber'); cyl(b,(x,0.23,0.0),0.018,0.012,6,'rubber')
    box(b,(0,0,0.03),(W-0.08,T+0.006,0.08),'plastic_black',skip=('bottom','left','right'))            # power raceway
    for x in (-0.35,0.35):
        box(b,(x,-T/2-0.006,0.045),(0.07,0.004,0.05),'plastic',skip=('back',))                          # duplex outlets
        if hi:
            for dz in (0.055,0.075): box(b,(x,-T/2-0.0085,0.045+dz-0.045),(0.012,0.002,0.006),'paint_black',skip=('back',))
    # tack board papers + pushpins, a three-tier paper tray hung on the panel, a coat hook on the back
    box(b,(-0.30,-T/2-0.0015,0.80),(0.21,0.002,0.28),'label',skip=('back',)); txt(b,hi,'Q3 TARGETS',0.026,(-0.30,-T/2-0.003,1.02),'paint_navy')
    if hi:
        for k in range(6): ext_y(b,[(-0.38,0.86+0.025*k),(-0.22-0.02*(k%3),0.86+0.025*k),(-0.22-0.02*(k%3),0.865+0.025*k),(-0.38,0.865+0.025*k)],-T/2-0.0035,-T/2-0.003,'paint_black')
    box(b,(-0.02,-T/2-0.0015,0.92),(0.13,0.002,0.10),'flyer_y',skip=('back',)); txt(b,hi,'TEAM',0.02,(-0.02,-T/2-0.003,0.985),'paint_black')
    box(b,(0.18,-T/2-0.0015,0.86),(0.12,0.002,0.15),'badge',skip=('back',))
    box(b,(0.32,-T/2-0.0015,0.94),(0.10,0.002,0.10),'flyer_g',skip=('back',))
    for (x,z) in ((-0.30,1.07),(-0.02,1.01),(0.18,1.0),(0.32,1.03)): box(b,(x,-T/2-0.008,z),(0.010,0.006,0.010),'tag_r',skip=('back',))
    for k in range(3):
        z=0.52+0.075*k
        ext_x(b,[(-T/2-0.30,z),(-T/2,z),(-T/2,z+0.05),(-T/2-0.012,z+0.05),(-T/2-0.012,z+0.008),(-T/2-0.30,z+0.008)],0.12,0.50,'alum_dk')
        box(b,(0.31,-T/2-0.16,z+0.008),(0.32,0.25,0.012),'label',skip=('bottom',)) if k!=1 else None
    box(b,(0.12,-T/2-0.006,0.50),(0.012,0.012,0.25),'alum_dk',skip=('back',)); box(b,(0.50,-T/2-0.006,0.50),(0.012,0.012,0.25),'alum_dk',skip=('back',))
    rod(b,(-0.55,T/2,1.12),(-0.55,T/2+0.05,1.10),0.006,6,'chrome'); rod(b,(-0.55,T/2+0.05,1.10),(-0.55,T/2+0.06,1.14),0.006,6,'chrome',caps=True)
    box(b,(-0.55,T/2+0.0015,0.70),(0.20,0.002,0.26),'label',skip=('front',))
    bevel_plate(b,hi,0.70,-T/2-0.002,1.10,0.10,0.04,'plate','4B-12','paint_black',0.022)
    b.cbox((0,0,0),(W,0.06,H))

# ------------------------------------------------------------------ projector_screen (wall, manual pull-down, budget 220)
def projector_screen(b, hi=False):
    W=2.40; zc=1.70
    case=[(0.05,zc-0.045),(0.0,zc-0.06),(-0.04,zc-0.045),(-0.05,zc),(-0.04,zc+0.045),(0.0,zc+0.06),(0.05,zc+0.045)]
    ext_x(b,[(y-0.01,z) for y,z in case],-W/2-0.03,W/2+0.03,'paint_white',caps=(False,False),skip=(6,))
    for x in (-W/2-0.03,W/2+0.03):
        ext_x(b,[(y-0.012,z) for y,z in [(-0.07,zc-0.07),(0.045,zc-0.07),(0.045,zc+0.07),(-0.07,zc+0.07)]],x-0.012 if x<0 else x,x if x<0 else x+0.012,'plastic_black',skip=(1,))
    # fabric: one baked quad (the black masking borders live on the bake)
    fq(b,[V((-W/2+0.03,-0.02,0.21)),V((W/2-0.03,-0.02,0.21)),V((W/2-0.03,-0.02,zc-0.06)),V((-W/2+0.03,-0.02,zc-0.06))],'scrn_face',(0,-1,0),W-0.06,zc-0.27)
    if hi:
        for z,h in ((zc-0.18,0.12),(0.21,0.06)): box(b,(0,-0.0215,z),(W-0.06,0.002,h),'paint_black',skip=('back',))
        for x in (-W/2+0.06,W/2-0.06): box(b,(x,-0.0215,0.27),(0.06,0.002,zc-0.45),'paint_black',skip=('back',))
    bar=[(-0.035,0.16),(-0.005,0.15),(0.0,0.17),(-0.005,0.215),(-0.035,0.205)]
    ext_x(b,bar,-W/2+0.01,W/2-0.01,'alum')                                                     # weighted bottom bar
    b.tube((0,-0.03,0.15),(0,-0.04,0.08),0.006,0.006,4,'plastic_black',cap0=False,cap1=False)   # pull loop / cord
    ext_x(b,[(-0.052,0.03),(-0.028,0.03),(-0.028,0.09),(-0.052,0.09)],-0.025,0.025,'plastic_black')
    for x in (-0.9,0.9): box(b,(x,0.025,zc-0.04),(0.06,0.02,0.10),'alum',skip=('back',))       # wall brackets
    bevel_plate(b,hi,0.95,-0.071,zc-0.018,0.12,0.03,'plate','SCREEN 100"','paint_black',0.016)
    b.cbox((0,0,0.15),(W,0.10,1.65))

# ------------------------------------------------------------------ drive_thru_window (wall, inside face -Y)
def drive_thru_window(b, hi=False):
    W,H=1.20,1.17; z0=0.03   # sill = counter top (the bake places the prop at the window's height)
    fr=[(0.0,0.0),(0.20,0.0),(0.20,0.06),(0.04,0.06),(0.04,0.04),(0.0,0.04)]
    for z,flip in ((z0,False),(z0+H-0.06,True)):
        ext_x(b,[(y-0.05,z+(0.06-zz if flip else zz)) for y,zz in fr],-W/2,W/2,'alum')
    for sg in (-1,1):
        x=sg*(W/2-0.03)
        box(b,(x,0.05,z0+0.06),(0.06,0.20,H-0.12),'alum',skip=('bottom','top'))
    box(b,(-0.27,0.09,z0+0.06),(0.54,0.012,H-0.12),'glass',skip=('bottom','top'))            # fixed pane
    box(b,(0.28,0.05,z0+0.06),(0.56,0.012,H-0.12),'glass',skip=('bottom','top'))              # sliding pane (half open)
    for x in (0.0,0.55): box(b,(x,0.05,z0+0.06),(0.035,0.035,H-0.12),'alum_dk',skip=('bottom','top'))
    box(b,(0.03,0.03,z0+0.45),(0.02,0.03,0.20),'plastic_black')                              # pull handle
    box(b,(0.28,0.042,z0+H-0.30),(0.18,0.004,0.08),'label',skip=('back',)); txt(b,hi,'PULL',0.045,(0.28,0.0395,z0+H-0.26),'ceramic')
    # inside: stainless pass-through counter on two brackets, cash drawer, POS, headset hook, order display
    ext_x(b,[(-0.25,0.0),(0.05,0.0),(0.05,z0),(-0.235,z0),(-0.25,z0-0.012)],-W/2-0.03,W/2+0.03,'steel')
    box(b,(-0.34,-0.10,z0),(0.38,0.26,0.10),'plastic_black',skip=('bottom',))                  # cash drawer
    box(b,(-0.34,-0.232,z0+0.02),(0.06,0.004,0.02),'chrome',skip=('back',))
    box(b,(0.32,-0.12,z0),(0.18,0.12,0.03),'plastic_black',skip=('bottom',))
    ext_x(b,[(-0.17,z0+0.03),(-0.13,z0+0.03),(-0.10,z0+0.27),(-0.14,z0+0.27)],0.20,0.44,'plastic_black')   # POS screen, tilted
    fq(b,[V((0.215,-0.172,z0+0.05)),V((0.425,-0.172,z0+0.05)),V((0.425,-0.142,z0+0.255)),V((0.215,-0.142,z0+0.255))],'screen',(0,-1,0.15),0.21,0.2)
    txt(b,hi,'#214  $12.85',0.022,(0.32,-0.162,z0+0.17),'paint_white',(1,0,0),(0,0.146,0.989))
    # order-ready display on the window head, inside
    box(b,(-0.30,-0.02,z0+H+0.0),(0.36,0.06,0.10),'plastic_black'); box(b,(-0.30,-0.0505,z0+H+0.015),(0.32,0.002,0.07),'keypad',skip=('back',))
    txt(b,hi,'ORDER 214',0.035,(-0.30,-0.052,z0+H+0.05),'badge')
    box(b,(0.48,0.01,z0+0.70),(0.04,0.05,0.04),'plastic_black'); rod(b,(0.48,-0.015,z0+0.72),(0.48,-0.06,z0+0.68),0.005,4,'chrome')
    box(b,(0.48,-0.065,z0+0.60),(0.10,0.02,0.08),'plastic_black')                              # headset on the hook
    b.cbox((0,0.05,0),(W,0.20,z0+H)); b.cbox((0,-0.10,0),(W,0.30,z0+0.10))

# ------------------------------------------------------------------ departure_board (ceiling-hung, face -Y)
def departure_board(b, hi=False):
    W,H=2.0,0.62; D=0.10
    ext_x(b,[(-D/2+0.015,0),(D/2,0),(D/2,H),(-D/2+0.015,H),(-D/2,H-0.015),(-D/2,0.015)],-W/2,W/2,'paint_black')
    box(b,(0,-D/2-0.001,0.035),(W-0.06,0.003,H-0.14),'keypad',skip=('back',))                 # split-flap field (baked)
    box(b,(0,-D/2-0.001,H-0.095),(W-0.06,0.003,0.07),'screen',skip=('back',))                 # header bar
    txt(b,hi,'DEPARTURES',0.042,(-0.62,-D/2-0.003,H-0.06),'paint_white')
    txt(b,hi,'DESTINATION',0.026,(-0.30,-D/2-0.003,H-0.06),'paint_white'); txt(b,hi,'TIME',0.026,(0.34,-D/2-0.003,H-0.06),'paint_white')
    txt(b,hi,'BAY',0.026,(0.58,-D/2-0.003,H-0.06),'paint_white'); txt(b,hi,'STATUS',0.026,(0.82,-D/2-0.003,H-0.06),'paint_white')
    rows=[('901','IMPERIAL BEACH','10:15','1','ON TIME'),('904','ORANGE AVE','10:22','2','BOARDING'),('F','BROADWAY PIER','10:30','D','ON TIME'),
          ('901','SAN DIEGO','10:41','1','DELAYED'),('93','NORTH ISLAND','10:55','3','ON TIME')]
    if hi:
        for k in range(len(rows)):
            z=H-0.17-0.083*k
            for (x0,x1) in ((-0.95,-0.70),(-0.66,0.18),(0.24,0.46),(0.50,0.66),(0.70,0.96)):     # flap tiles
                n=max(1,int((x1-x0)/0.045))
                for i in range(n):
                    a=x0+(x1-x0)*i/n
                    box(b,(a+(x1-x0)/n/2,-D/2-0.0025,z-0.006),((x1-x0)/n-0.006,0.002,0.064),'plastic_black',skip=('back',))
                box(b,((x0+x1)/2,-D/2-0.0047,z+0.025),(x1-x0,0.001,0.002),'paint_black',skip=('back',))
    for k,(rt,a,t,bay,st) in enumerate(rows):
        z=H-0.145-0.083*k; y=-D/2-0.0048
        txt(b,hi,rt,0.040,(-0.825,y,z),'brass'); txt(b,hi,a,0.040,(-0.24,y,z),'brass'); txt(b,hi,t,0.040,(0.35,y,z),'brass'); txt(b,hi,bay,0.040,(0.58,y,z),'brass')
        txt(b,hi,st,0.032,(0.83,y,z),'leaf' if st!='DELAYED' else 'ceramic')
    # clock module on the right end, ceiling hangers with plates, cable
    _disc_y(b,(0,H+0.17),0.14,-0.035,0.035,14,'paint_black',caps=(True,True))
    _disc_y(b,(0,H+0.17),0.12,-0.039,-0.035,14,'label',caps=(True,False))
    if hi:
        box(b,(0,-0.041,H+0.17),(0.008,0.002,0.09),'paint_black',skip=('back',)); box(b,(0.03,-0.042,H+0.165),(0.065,0.002,0.008),'paint_black',skip=('back',))
        for k in range(12): a=2*math.pi*k/12; box(b,(0.105*math.cos(a),-0.040,H+0.17+0.105*math.sin(a)-0.006),(0.006,0.002,0.012),'paint_black',skip=('back',))
    for x in (-0.8,0.8):
        rod(b,(x,0,H),(x,0,H+0.40),0.008,6,'chrome'); cyl(b,(x,0,H+0.40),0.04,0.02,8,'chrome',top=True)
        box(b,(x,0,H),(0.06,0.04,0.02),'paint_black',skip=('bottom',))
    box(b,(0,0,H),(0.04,0.03,0.04),'paint_black',skip=('bottom',))                          # clock stem
    b.cbox((0,0,0),(W,0.10,H))

# ------------------------------------------------------------------ key_rack_wall (hotel / motel key board)
def key_rack_wall(b, hi=False):
    W,H=0.80,0.60
    box(b,(0,0.01,0),(W-0.04,0.02,H-0.04),'wal',skip=('back',))
    for z,h in ((0.0,0.04),(H-0.06,0.06)): box(b,(0,0.0,z),(W,0.04,h),'wal_dk',skip=('back',))
    for x in (-W/2+0.02,W/2-0.02): box(b,(x,0.0,0.04),(0.04,0.04,H-0.10),'wal_dk',skip=('back','bottom','top'))
    ext_x(b,[(-0.03,H),(0.02,H),(0.02,H+0.025),(-0.035,H+0.03),(-0.035,H+0.012)],-W/2-0.02,W/2+0.02,'wal_dk')   # crown
    box(b,(0,-0.002,0.0),(W+0.02,0.06,0.025),'wal_dk',skip=('back',))                          # ledge
    box(b,(0,-0.012,H-0.13),(0.30,0.006,0.07),'plate',skip=('back',)); txt(b,hi,'ROOM KEYS',0.04,(0,-0.0155,H-0.095),'paint_black')
    for r,z in enumerate((0.27,0.06)):
        box(b,(0,-0.004,z+0.155),(W-0.10,0.006,0.012),'brass',skip=('back',))                  # hook rail
        for i in range(8):
            x=-0.33+i*0.094
            fq(b,[V((x-0.003,-0.007,z+0.165)),V((x+0.003,-0.007,z+0.165)),V((x+0.003,-0.034,z+0.172)),V((x-0.003,-0.034,z+0.172))],'brass',(0,0,1),0.006,0.03)
            fq(b,[V((x-0.003,-0.007,z+0.158)),V((x+0.003,-0.007,z+0.158)),V((x+0.003,-0.034,z+0.165)),V((x-0.003,-0.034,z+0.165))],'brass',(0,0,-1),0.006,0.03)
            txt(b,hi,str(101+r*8+i),0.02,(x,-0.0105,z+0.19),'brass')
            if (i*3+r)%5!=2:
                kk='tag_r' if (i+r)%3==0 else 'tag_g' if (i+r)%3==1 else 'tag_b'
                tg=_orient([V((x-0.016,-0.030,z)),V((x+0.016,-0.030,z)),V((x+0.016,-0.030,z+0.06)),V((x,-0.030,z+0.078)),V((x-0.016,-0.030,z+0.06))],(0,-1,0))
                b.faces(tg,[(0,1,2,3,4)],kk,[[(p_.x,p_.z) for p_ in tg]])
                fq(b,[V((x-0.005,-0.031,z+0.075)),V((x+0.005,-0.031,z+0.075)),V((x+0.005,-0.031,z+0.15)),V((x-0.005,-0.031,z+0.15))],'brass',(0,-1,0),0.01,0.075)
                if hi: txt(b,hi,str(101+r*8+i),0.012,(x,-0.0345,z+0.035),'paint_white')
    b.cbox((0,0,0),(W,0.06,H))

# ------------------------------------------------------------------ model_house_display (low table-top model, ~0.56 m)
def model_house_display(b, hi=False):
    box(b,(0,0,0),(0.80,0.80,0.04),'paint_black',skip=('bottom',))                            # plinth toe
    box(b,(0,0,0.04),(0.76,0.76,0.24),'paint_white',skip=('bottom','top'))
    box(b,(0,0,0.245),(0.77,0.77,0.035),'wal_dk',skip=('bottom','top'))                       # walnut band under the tray
    box(b,(0,0,0.075),(0.765,0.765,0.008),'paint_grey',skip=('bottom','top'))                  # reveal line
    box(b,(0,-0.385,0.12),(0.34,0.006,0.075),'plate',skip=('back',))                           # front plaque
    txt(b,hi,'BAYVIEW TERRACE',0.032,(0,-0.3885,0.162),'paint_black'); txt(b,hi,'PHASE 2  -  4 HOMES',0.022,(0,-0.3885,0.133),'paint_black')
    box(b,(0,0,0.28),(0.80,0.80,0.025),'oak')                                                 # oak tray
    box(b,(0,0,0.305),(0.74,0.74,0.008),'lawn',skip=('bottom',))
    zg=0.313
    box(b,(0.10,-0.22,zg),(0.14,0.30,0.002),'paint_cream',skip=('bottom',))                  # driveway
    box(b,(-0.10,-0.31,zg),(0.05,0.12,0.002),'paint_cream',skip=('bottom',))                  # path
    box(b,(-0.20,-0.20,zg),(0.20,0.13,0.003),'pool',skip=('bottom',))
    for (x,y,w,d) in ((-0.20,-0.27,0.24,0.012),(-0.20,-0.13,0.24,0.012),(-0.32,-0.20,0.012,0.15),(-0.08,-0.20,0.012,0.15)): box(b,(x,y,zg),(w,d,0.006),'paint_white',skip=('bottom',))
    # two-storey house + garage wing, hip roofs, chimney, porch
    box(b,(-0.02,0.12,zg),(0.40,0.24,0.15),'house',skip=('bottom',))
    box(b,(0.26,0.08,zg),(0.18,0.20,0.09),'house',skip=('bottom',))
    def hip(x0,x1,y0,y1,z,h,ov=0.015):
        x0-=ov; x1+=ov; y0-=ov; y1+=ov; r=min(x1-x0,y1-y0)/2
        P=[V((x0,y0,z)),V((x1,y0,z)),V((x1,y1,z)),V((x0,y1,z))]; R=[V((x0+r,(y0+y1)/2,z+h)),V((x1-r,(y0+y1)/2,z+h))]
        fq(b,[P[0],P[1],R[1],R[0]],'roof',(0,-1,1),x1-x0,0.1); fq(b,[P[2],P[3],R[0],R[1]],'roof',(0,1,1),x1-x0,0.1)
        b.faces(_orient([P[1],P[2],R[1]],(1,0,1)),[(0,1,2)],'roof',[[(0,0),(0.1,0),(0.05,0.1)]])
        b.faces(_orient([P[3],P[0],R[0]],(-1,0,1)),[(0,1,2)],'roof',[[(0,0),(0.1,0),(0.05,0.1)]])
        b.faces(_orient([P[0],P[1],P[2],P[3]],(0,0,-1)),[(0,1,2,3)],'paint_white',[[(0,0),(0.1,0),(0.1,0.1),(0,0.1)]])
    hip(-0.22,0.18,0.0,0.24,zg+0.15,0.08); hip(0.17,0.35,-0.02,0.18,zg+0.09,0.05)
    box(b,(-0.16,0.20,zg+0.15),(0.04,0.04,0.11),'stone')
    # windows (baked dark glass), door, garage door, porch posts
    for x in (-0.15,-0.05,0.08):
        for z in (zg+0.03,zg+0.095): box(b,(x,-0.0015,z),(0.045,0.003,0.04),'screen',skip=('back',))
    box(b,(0.0,-0.0015,zg),(0.04,0.003,0.07),'walnut',skip=('back',)) if False else None
    box(b,(0.26,-0.0215,zg),(0.12,0.003,0.07),'paint_grey',skip=('back',))
    box(b,(-0.02,-0.03,zg+0.075),(0.14,0.06,0.006),'house')
    for x in (-0.08,0.04): box(b,(x,-0.055,zg),(0.008,0.008,0.075),'paint_white',skip=('bottom','top'))
    # palms + shrubs + a little car
    for (x,y,h) in ((-0.30,0.25,0.20),(0.31,-0.29,0.17),(-0.33,-0.05,0.14)):
        rod(b,(x,y,zg),(x+0.012,y,zg+h),0.006,4,'walnut')
        for k in range(6): pg.B.quad(b,[V((x+0.012,y,zg+h)),V((x+0.08*math.cos(k*1.047),y+0.08*math.sin(k*1.047),zg+h-0.045)),V((x+0.09*math.cos(k*1.047+0.25),y+0.09*math.sin(k*1.047+0.25),zg+h-0.03))],'lawn_dk')
    for (x,y) in ((0.18,0.25),(-0.30,0.12),(0.33,0.22)): b.lathe([(0.0,zg),(0.03,zg+0.01),(0.03,zg+0.03),(0.0,zg+0.045)],6,'lawn_dk',c=(x,y,0),cap_top=False)
    box(b,(0.10,-0.25,zg+0.002),(0.05,0.10,0.025),'tag_b'); box(b,(0.10,-0.245,zg+0.027),(0.044,0.05,0.015),'cglass')
    # brass lot plate + price card on a little stand
    box(b,(0,-0.402,0.285),(0.26,0.004,0.02),'plate',skip=('back',)); txt(b,hi,'THE PALMS  lot 12',0.014,(0,-0.4045,0.295),'paint_black')
    ext_x(b,[(-0.38,zg),(-0.34,zg),(-0.33,zg+0.10),(-0.335,zg+0.10)],0.20,0.34,'label'); txt(b,hi,'FROM $1.89M',0.018,(0.27,-0.365,zg+0.055),'paint_navy',(1,0,0),(0,0.1,0.995))
    b.cbox((0,0,0),(0.80,0.80,0.56))

# ------------------------------------------------------------------ dental_chair (feet -Y, head + unit +Y)
def dental_chair(b, hi=False):
    ext_z(b,rrect(-0.30,-0.15,0.30,0.55,0.14,3),0.0,0.04,'paint_white',caps=(False,True))           # base plate
    ext_z(b,rrect(-0.15,0.02,0.15,0.30,0.06,2),0.04,0.36,'paint_white',caps=(False,True))           # lift column
    for k in range(4): ext_z(b,rrect(-0.155,0.015,0.155,0.305,0.06,2),0.08+0.06*k,0.09+0.06*k,'paint_grey',caps=(False,False))
    box(b,(0,0.05,0.36),(0.48,0.84,0.06),'paint_grey')                                              # seat frame
    # upholstered shell: seat + back + leg rest, piped edge
    up=[(-0.92,0.38),(-0.88,0.46),(-0.80,0.50),(-0.42,0.57),(-0.10,0.58),(0.06,0.59),(0.16,0.64),(0.36,0.86),(0.52,1.02),(0.62,1.10),(0.70,1.15)]
    lo=[(0.72,1.10),(0.64,1.04),(0.54,0.96),(0.38,0.80),(0.18,0.56),(0.08,0.46),(-0.10,0.44),(-0.42,0.43),(-0.78,0.37),(-0.90,0.31)]
    ext_x(b,up+lo,-0.26,0.26,'vinyl')
    ext_x(b,[(y,z+0.012) for y,z in up[1:8]]+[(y-0.0,z-0.0) for y,z in up[1:8][::-1]],-0.20,0.20,'vinyl_dk',caps=(True,True)) if False else None
    for sg in (-1,1): ext_x(b,[(y,z) for y,z in up],sg*0.262-0.006,sg*0.262+0.006,'vinyl_dk',caps=(True,True)) if False else None
    # piping lines across the cushion breaks (seat / back / leg)
    for (y,z) in ((0.10,0.59),(-0.42,0.575)): box(b,(0,y,z-0.01),(0.52,0.02,0.02),'vinyl_dk')
    # headrest on its slide
    box(b,(0,0.73,1.08),(0.10,0.06,0.10),'paint_grey')
    ext_x(b,[(0.66,1.12),(0.86,1.18),(0.90,1.23),(0.86,1.27),(0.66,1.22)],-0.14,0.14,'vinyl')
    # arm rests
    for sg in (-1,1):
        box(b,(sg*0.31,-0.02,0.64),(0.08,0.44,0.05),'vinyl'); ext_x(b,[(0.14,0.46),(0.19,0.46),(0.19,0.64),(0.14,0.64)],sg*0.31-0.015,sg*0.31+0.015,'paint_white')
    # foot control on a cable
    ext_z(b,rrect(0.30,-0.55,0.52,-0.35,0.06,2),0.0,0.05,'paint_grey',caps=(False,True)); box(b,(0.41,-0.45,0.05),(0.12,0.10,0.01),'rubber',skip=('bottom',))
    b.sweep([(0.30,-0.45,0.02),(0.15,-0.30,0.01),(0.12,0.0,0.02)],0.006,4,'plastic_black',cap0=False,cap1=False)
    # cuspidor post + bowl + water spout (patient's left)
    ext_z(b,rrect(-0.65,0.32,-0.48,0.49,0.04,2),0.0,0.86,'paint_white',caps=(False,True))
    b.lathe([(0.03,0.86),(0.12,0.88),(0.13,0.92),(0.11,0.925),(0.08,0.90),(0.03,0.89)],12,'ceramic_w',c=(-0.57,0.36,0),cap_top=False)
    rod(b,(-0.53,0.44,0.86),(-0.53,0.44,1.0),0.008,6,'chrome'); rod(b,(-0.53,0.44,1.0),(-0.53,0.36,0.98),0.007,6,'chrome',caps=True)
    cyl(b,(-0.62,0.42,0.86),0.03,0.07,8,'cglass',top=True)                                             # cup
    # delivery unit: arm, tray, 4 handpieces in holders with hoses
    rod(b,(0.36,0.30,0.42),(0.40,0.20,0.86),0.025,8,'paint_white'); b.sweep([(0.40,0.20,0.86),(0.46,0.0,0.90),(0.52,-0.18,0.90)],0.02,8,'paint_white',cap0=False,cap1=True)
    ext_z(b,rrect(0.32,-0.46,0.72,-0.16,0.05,2),0.88,0.92,'paint_white',caps=(True,True))
    box(b,(0.52,-0.32,0.92),(0.30,0.18,0.008),'steel',skip=('bottom',))
    for k in range(4):
        x=0.38+0.08*k
        box(b,(x,-0.47,0.86),(0.04,0.03,0.06),'paint_grey')
        rod(b,(x,-0.48,0.92),(x+0.01,-0.50,1.04),0.008,6,'chrome',caps=True)
        b.sweep([(x,-0.47,0.86),(x+0.02,-0.52,0.72),(x+0.04,-0.40,0.66)],0.005,4,'plastic_black',cap0=False,cap1=False)
    for k in range(3): rod(b,(0.42+0.07*k,-0.28,0.93),(0.42+0.07*k,-0.38,0.935),0.004,4,'chrome')
    # operating light: post, swing arm, curved head
    rod(b,(0.0,0.62,0.04),(0.0,0.62,1.95),0.035,8,'paint_white'); rod(b,(0.0,0.62,1.93),(0.0,0.10,1.93),0.025,8,'paint_white',caps=True)
    rod(b,(0.0,0.10,1.93),(0.0,0.06,1.86),0.02,6,'paint_white')
    ext_x(b,[(-0.08,1.80),(0.08,1.80),(0.10,1.84),(0.06,1.88),(-0.06,1.88),(-0.10,1.84)],-0.18,0.18,'paint_white')
    box(b,(0,0.0,1.795),(0.30,0.14,0.006),'mirror',skip=('top',))
    for sg in (-1,1): rod(b,(sg*0.19,-0.02,1.84),(sg*0.24,-0.06,1.83),0.01,6,'paint_grey',caps=True)
    # monitor on the light post
    rod(b,(0.0,0.62,1.45),(0.30,0.50,1.45),0.015,6,'paint_white'); box(b,(0.34,0.45,1.32),(0.34,0.03,0.24),'plastic_black')
    fq(b,[V((0.18,0.433,1.34)),V((0.50,0.433,1.34)),V((0.50,0.433,1.54)),V((0.18,0.433,1.54))],'screen',(0,-1,0),0.32,0.2)
    maker_plate(b,(0,-0.124,0.22),hi,0.10,0.03)
    b.cbox((0,0.0,0),(0.66,1.80,0.80)); b.cbox((0,0.62,0),(0.12,0.12,1.95))

# ------------------------------------------------------------------ pizza_oven (Neapolitan dome on a stand, mouth -Y)
def pizza_oven(b, hi=False):
    box(b,(0,0,0.06),(1.60,1.40,0.89),'steel',skip=('bottom','front'))
    box(b,(0,0,0),(1.56,1.36,0.06),'rubber',skip=('bottom',))                                    # plinth
    # front panel as a frame round the open wood store
    box(b,(0,-0.69,0.55),(1.60,0.02,0.40),'steel',skip=('back',)); box(b,(0,-0.69,0.06),(1.60,0.02,0.06),'steel',skip=('back',))
    for sg in (-1,1): box(b,(sg*0.695,-0.69,0.12),(0.21,0.02,0.43),'steel',skip=('back','top','bottom'))
    for x in (-0.79,0.79): box(b,(x,-0.705,0.06),(0.03,0.012,0.89),'steel_dk',skip=('back',))     # corner trims
    box(b,(0,-0.705,0.55),(1.20,0.012,0.025),'steel_dk',skip=('back',)); box(b,(0,-0.705,0.095),(1.20,0.012,0.025),'steel_dk',skip=('back',))
    fq(b,[V((-0.59,-0.40,0.12)),V((0.59,-0.40,0.12)),V((0.59,-0.40,0.55)),V((-0.59,-0.40,0.55))],'paint_black',(0,-1,0),1.18,0.43)   # store back
    fq(b,[V((-0.59,-0.68,0.12)),V((0.59,-0.68,0.12)),V((0.59,-0.40,0.12)),V((-0.59,-0.40,0.12))],'steel_dk',(0,0,1),1.18,0.28)     # store floor
    for sg in (-1,1): fq(b,[V((sg*0.59,-0.68,0.12)),V((sg*0.59,-0.40,0.12)),V((sg*0.59,-0.40,0.55)),V((sg*0.59,-0.68,0.55))],'steel_dk',(-sg,0,0),0.28,0.43)
    for r_ in range(3):
        for i in range(5-r_):
            x=-0.48+0.24*i+0.12*r_; z=0.175+0.10*r_
            _disc_y(b,(x,z),0.05,-0.66,-0.41,6,'walnut',caps=(True,False))
            if hi: _disc_y(b,(x,z),0.035,-0.663,-0.66,6,'oak',caps=(True,False))
    box(b,(0,0,0.95),(1.66,1.46,0.06),'stone')                                                   # hearth slab
    box(b,(0,-0.745,0.95),(1.66,0.02,0.06),'stone_dk',skip=('back',))
    n=16 if hi else 14
    prof=[(0.76,1.01),(0.76,1.12),(0.72,1.30),(0.62,1.46),(0.46,1.58),(0.25,1.66),(0.0,1.68)]
    b.lathe(prof,n,'dome',c=(0,0.05,0),cap_top=False)
    b.lathe([(0.775,1.01),(0.775,1.07),(0.76,1.07)],n,'dome_dk',c=(0,0.05,0),cap_top=False)      # base band
    # brick arch facade around the mouth, keystone, ember mouth, landing
    ar=[(-0.32,1.01),(0.32,1.01),(0.32,1.20)]+[(0.32*math.cos(math.radians(t)),1.20+0.16*math.sin(math.radians(t))) for t in range(20,161,20)]+[(-0.32,1.20)]
    ext_y(b,ar,-0.80,-0.58,'brick')
    box(b,(0,-0.81,1.30),(0.08,0.03,0.09),'stone')
    ar2=[(-0.22,1.03),(0.22,1.03),(0.22,1.17)]+[(0.22*math.cos(math.radians(t)),1.17+0.11*math.sin(math.radians(t))) for t in range(30,151,30)]+[(-0.22,1.17)]
    ext_y(b,ar2,-0.805,-0.80,'paint_black',caps=(True,False))
    box(b,(0,-0.806,1.03),(0.36,0.004,0.045),'ember',skip=('back','bottom'))               # glowing bed of embers
    if hi:
        for k in range(8): ext_y(b,[(-0.16+0.04*k,1.035),(-0.14+0.04*k,1.035),(-0.145+0.04*k,1.06),(-0.155+0.04*k,1.06)],-0.81,-0.8085,'badge')
        for z in (1.07,1.12,1.17):                                                               # mortar courses
            for sg in (-1,1): fq(b,[V((sg*0.225,-0.8005,z)),V((sg*0.32,-0.8005,z)),V((sg*0.32,-0.8005,z+0.006)),V((sg*0.225,-0.8005,z+0.006))],'stone',(0,-1,0),0.1,0.006)
        for t in range(10,171,20):                                                               # arch voussoirs
            ca,sa=math.cos(math.radians(t)),math.sin(math.radians(t))
            a=V((0.225*ca,-0.8005,1.17+0.115*sa)); c=V((0.32*ca,-0.8005,1.20+0.16*sa)); nn=V((-sa,0,ca))*0.003
            fq(b,[a-nn,c-nn,c+nn,a+nn],'stone',(0,-1,0),0.1,0.006)
    box(b,(0,-0.80,1.00),(0.70,0.10,0.03),'stone')
    # flue with a cap and a damper band, thermometer, plate, peel + brush leaning on the stand
    rod(b,(0,0.30,1.60),(0,0.30,2.04),0.10,10,'steel_dk'); b.tube((0,0.30,2.04),(0,0.30,2.12),0.16,0.05,10,'steel_dk',cap0=True,cap1=True)
    cyl(b,(0,0.30,1.78),0.11,0.04,10,'steel')
    cyl(b,(0.36,-0.70,1.30),0.04,0.01,10,'chrome') if False else None
    _disc_y(b,(0.40,1.30),0.05,-0.71,-0.68,10,'chrome',caps=(True,False)); _disc_y(b,(0.40,1.30),0.04,-0.712,-0.71,10,'label',caps=(True,False))
    box(b,(0,-0.702,0.70),(0.44,0.006,0.13),'plate',skip=('back',)); txt(b,hi,'FORNO NAPOLI',0.045,(0,-0.706,0.765),'paint_black')
    for (x,tool) in ((0.70,'peel'),(0.62,'brush')):
        rod(b,(x,-0.74,0.06),(x-0.04,-0.74,1.40),0.012,6,'oak',caps=True)
        if tool=='peel': ext_y(b,rrect(x-0.17,0.06,x+0.15,0.36,0.10,2),-0.755,-0.745,'chrome')
        else: box(b,(x-0.04,-0.75,1.40),(0.16,0.04,0.05),'brass')
    b.cbox((0,0,0),(1.66,1.46,1.60))

# ================================================================== POLISH detail passes (wrappers: base geometry + added detail)
def _wrap(base, extra):
    def f(b, hi=False):
        base(b, hi); extra(b, hi)
    f.__name__=base.__name__; return f
def _glass_tumbler(b,x,y,z,r=0.03,h=0.10): b.lathe([(0.0,z),(r*0.85,z),(r,z+h),(r*0.9,z+h)],8,'cglass',c=(x,y,0),cap_top=False)
def _pitcher(b,x,y,z):
    b.lathe([(0.0,z),(0.05,z),(0.06,z+0.06),(0.05,z+0.16),(0.055,z+0.20),(0.045,z+0.20)],8,'cglass',c=(x,y,0),cap_top=False)
    b.sweep([(x+0.05,y,z+0.16),(x+0.09,y,z+0.14),(x+0.09,y,z+0.07),(x+0.055,y,z+0.05)],0.007,4,'cglass',cap0=False,cap1=False)
def _candle(b,x,y,z,h=0.18):
    b.lathe([(0.05,z),(0.055,z+0.02),(0.018,z+0.04),(0.014,z+0.16),(0.035,z+0.18),(0.035,z+0.19),(0.0,z+0.19)],8,'brass',c=(x,y,0),cap_top=False)
    cyl(b,(x,y,z+0.19),0.018,h,8,'linen',top=True); b.tube((x,y,z+0.19+h),(x,y,z+0.19+h+0.035),0.008,0.0,4,'ember',cap0=False,cap1=False)
def _book_open(b,x,y,z,w,d,tilt_deg=0.0,key='bk_red'):
    t=math.radians(tilt_deg); up=V((0,-math.sin(t),math.cos(t))); fw=V((0,math.cos(t),math.sin(t)))
    o=V((x,y,z)); 
    for sg in (-1,1):
        a=o+V((0,0,0)); c=o+V((sg*w/2,0,0))
        q=[a+fw*(-d/2)+up*0.012,c+fw*(-d/2)+up*0.006,c+fw*(d/2)+up*0.006,a+fw*(d/2)+up*0.012]
        fq(b,q,'bk_page',up,w/2,d)
    q=[o+V((-w/2-0.005,0,0))+fw*(-d/2-0.005),o+V((w/2+0.005,0,0))+fw*(-d/2-0.005),o+V((w/2+0.005,0,0))+fw*(d/2+0.005),o+V((-w/2-0.005,0,0))+fw*(d/2+0.005)]
    fq(b,q,key,up,w,d)
def _plant_small(b,x,y,z,h=0.30):
    b.lathe([(0.0,z),(0.06,z),(0.075,z+0.11),(0.08,z+0.12),(0.0,z+0.12)],8,'ceramic_w',c=(x,y,0),cap_top=False)
    for k in range(7):
        a=k*0.9; L=h*(0.6+0.4*((k*37)%10)/10)
        pg.B.quad(b,[V((x,y,z+0.11)),V((x+0.10*math.cos(a)-0.02*math.sin(a),y+0.10*math.sin(a)+0.02*math.cos(a),z+0.11+L*0.7)),V((x+0.12*math.cos(a),y+0.12*math.sin(a),z+0.11+L))],'lawn_dk')

# court_bench: solid back board, stretcher, glides, plates both faces of the ends
def _x_court_bench(b,hi):
    box(b,(0,0.252,0.47),(2.90,0.014,0.36),'wal_dk',skip=('left','right','bottom'))
    box(b,(0,0.20,0.07),(2.90,0.04,0.05),'wal_dk',skip=('left','right'))
    for x in (-1.47,1.47):
        for y in (-0.25,0.25): box(b,(x,y,-0.004),(0.05,0.06,0.006),'rubber',skip=('bottom',)) if False else None
    for x in (-0.75,0.75): ext_x(b,[(-0.20,0.0),(-0.14,0.0),(-0.12,0.04),(0.08,0.04),(0.10,0.0),(0.15,0.0),(0.14,0.39),(-0.20,0.40)],x-0.018,x+0.018,'wal_dk')
court_bench=_wrap(court_bench,_x_court_bench)

# lectern: brass cross, open book on the desk, reading lamp, water glass
def _x_lectern(b,hi):
    box(b,(0,-0.226,0.63),(0.035,0.008,0.20),'brass',skip=('back',)); box(b,(0,-0.226,0.745),(0.13,0.008,0.035),'brass',skip=('back',))
    a=V((0,-0.235,1.12)); c=V((0,0.245,1.005)); m=(a+c)/2; d=(c-a).normalized(); n=V((0,-d.z,d.y)) if d.z<0 else V((0,d.z,-d.y))
    ang=math.degrees(math.atan2(-(c.z-a.z),(c.y-a.y)))
    _book_open(b,0,m.y-0.02,m.z+0.012,0.34,0.24,-ang,'bk_black')
    rod(b,(-0.22,0.20,1.0),(-0.20,0.12,1.16),0.006,6,'brass'); b.tube((-0.20,0.12,1.16),(-0.12,0.06,1.12),0.025,0.035,8,'tag_g',cap0=True,cap1=False)
    cyl(b,(-0.22,0.20,0.99),0.035,0.012,8,'brass')
    _glass_tumbler(b,0.14,0.20,0.645)
lectern=_wrap(lectern,_x_lectern)

# altar_table: candlesticks, cross, missal on a stand, chalice
def _x_altar_table(b,hi):
    zt=0.986
    for x in (-0.78,0.78): _candle(b,x,0.12,zt,0.20)
    box(b,(0,0.26,zt),(0.18,0.10,0.04),'brass'); box(b,(0,0.26,zt+0.04),(0.03,0.025,0.42),'brass'); box(b,(0,0.26,zt+0.32),(0.20,0.025,0.03),'brass')
    ext_x(b,[(-0.12,zt+0.10),(-0.12,zt),(0.08,zt)],-0.14,0.14,'brass')
    _book_open(b,0,-0.02,zt+0.055,0.30,0.21,-27,'bk_red')
    b.lathe([(0.04,zt),(0.04,zt+0.01),(0.008,zt+0.03),(0.008,zt+0.09),(0.045,zt+0.12),(0.05,zt+0.17),(0.045,zt+0.17)],8,'brass',c=(0.42,0.05,0),cap_top=False)
altar_table=_wrap(altar_table,_x_altar_table)

# judge_bench: flags, banker's lamp, microphone, water
def _x_judge_bench(b,hi):
    for (x,k) in ((-1.45,'flag_r'),(1.45,'tag_b')):
        cyl(b,(x,0.40,0.30),0.16,0.05,10,'brass'); rod(b,(x,0.40,0.35),(x,0.40,2.45),0.016,6,'brass')
        b.lathe([(0.0,2.45),(0.03,2.47),(0.0,2.56)],6,'brass',c=(x,0.40,0),cap_top=False)
        b.tube((x+0.02,0.40,2.38),(x+0.03,0.40,1.55),0.10,0.035,8,k,cap0=True,cap1=False)
        rod(b,(x+0.02,0.40,2.38),(x+0.09,0.40,2.30),0.005,4,'brass') if False else None
    cyl(b,(1.35,-0.05,1.035),0.07,0.02,8,'brass'); rod(b,(1.35,-0.05,1.055),(1.35,-0.05,1.32),0.008,6,'brass')
    ext_x(b,[(-0.12,1.30),(0.02,1.30),(0.02,1.34)]+[(-0.05+0.07*math.cos(math.radians(t)),1.30+0.07*math.sin(math.radians(t))) for t in (60,90,120)]+[(-0.12,1.34)],1.17,1.53,'tag_g')
    cyl(b,(0.0,-0.30,1.035),0.045,0.012,8,'plastic_black'); rod(b,(0,-0.30,1.047),(0.0,-0.40,1.26),0.006,6,'plastic_black'); cyl(b,(0,-0.41,1.26),0.013,0.05,6,'plastic_black')
    _pitcher(b,-1.20,-0.05,1.035); _glass_tumbler(b,-1.05,-0.15,1.035)
judge_bench=_wrap(judge_bench,_x_judge_bench)

# witness_box: chair inside, bible + water on the ledge, swing-gate handle
def _x_witness_box(b,hi):
    _pitcher(b,0.52,-0.57,1.065); _glass_tumbler(b,0.40,-0.57,1.065)
    box(b,(-0.67,-0.30,1.065),(0.14,0.21,0.035),'bk_black',skip=('bottom',)); box(b,(-0.67,-0.301,1.071),(0.141,0.20,0.024),'bk_page',skip=('bottom','top','left'))
    box(b,(0.705,0.25,0.55),(0.02,0.03,0.12),'brass')                 # gate latch
    for sg in (-1,1): box(b,(sg*0.67,0.44,0.20),(0.10,0.04,0.85),'wal_dk',skip=('bottom',))   # gate posts
witness_box=_wrap(witness_box,_x_witness_box)

# jury_box: water pitchers, plate
def _x_jury_box(b,hi):
    for x in (-1.2,1.2): _pitcher(b,x,-0.72,0.96); _glass_tumbler(b,x+0.14,-0.70,0.96)
    bevel_plate(b,hi,0,-0.81,0.80,0.36,0.05,'plate','JURY','paint_black',0.032)
jury_box=_wrap(jury_box,_x_jury_box)

# conference_table: speakerphone, notepads + pens, carafes and glasses
def _x_conference_table(b,hi):
    z=0.765
    ext_z(b,[(0.0,0.14),(-0.13,-0.08),(0.13,-0.08)],z,z+0.03,'plastic_black',caps=(False,True))
    for a in (90,210,330): cyl(b,(0.10*math.cos(math.radians(a)),0.10*math.sin(math.radians(a))-0.02,z),0.025,0.012,6,'plastic_black')
    box(b,(0,-0.003,z+0.03),(0.06,0.03,0.002),'screen',skip=('bottom',))
    for (x,y,r) in ((-0.95,-0.32,0.1),(-0.30,-0.34,-0.05),(0.45,-0.33,0.05),(0.95,0.32,0.08),(-0.55,0.33,-0.1)):
        box(b,(x,y,z),(0.21,0.29,0.012),'label',skip=('bottom',))
        rod(b,(x+0.13,y-0.10,z+0.006),(x+0.15,y+0.08,z+0.006),0.004,4,'tag_b',caps=True)
    for x in (-0.6,0.6): _pitcher(b,x,0.02,z); _glass_tumbler(b,x+0.15,0.10,z,0.03,0.09); _glass_tumbler(b,x-0.15,-0.08,z,0.03,0.09)
conference_table=_wrap(conference_table,_x_conference_table)

# chart_table: parallel rule + dividers on the glass, swing-arm magnifier lamp
def _x_chart_table(b,hi):
    z=0.952
    box(b,(-0.25,0.05,z),(0.46,0.06,0.006),'plastic',skip=('bottom',)); box(b,(-0.25,0.13,z),(0.46,0.06,0.006),'plastic',skip=('bottom',))
    for x in (-0.38,-0.12): box(b,(x,0.09,z+0.006),(0.012,0.10,0.004),'brass',skip=('bottom',))
    rod(b,(0.30,-0.15,z+0.004),(0.42,0.02,z+0.004),0.003,4,'brass'); rod(b,(0.30,-0.15,z+0.004),(0.47,-0.12,z+0.004),0.003,4,'brass')
    box(b,(0.72,0.42,z-0.06),(0.06,0.08,0.10),'paint_black'); rod(b,(0.72,0.42,z+0.04),(0.68,0.36,z+0.42),0.008,6,'paint_black'); rod(b,(0.68,0.36,z+0.42),(0.40,0.20,z+0.34),0.008,6,'paint_black')
    b.tube((0.40,0.20,z+0.34),(0.40,0.20,z+0.30),0.09,0.09,12,'paint_black',cap0=True,cap1=False); _disc_y if False else None
chart_table=_wrap(chart_table,_x_chart_table)

# drafting_table: pencil cup, pencils and a tape roll on the ledge, foot rail
def _x_drafting_table(b,hi):
    cyl(b,(-0.55,-0.46,0.69),0.03,0.09,8,'tag_b',top=False)
    for k in range(3): rod(b,(-0.56+0.01*k,-0.46,0.72),(-0.57+0.02*k,-0.47+0.005*k,0.83),0.003,4,'paint_yellow',caps=True)
    b.lathe([(0.02,0.69),(0.035,0.69),(0.035,0.71),(0.02,0.71)],8,'plastic',c=(-0.40,-0.46,0),cap_top=False)
drafting_table=_wrap(drafting_table,_x_drafting_table)

# reception_desk: vertical walnut fins on the front, LED strip under the ledge, orchid, card stand, pen cup
def _x_reception_desk(b,hi):
    for i in range(14):
        x=-1.42+0.17*i
        if x>0.85: break
        box(b,(x,-0.69,0.08),(0.035,0.024,0.32),'wal_dk',skip=('back',))
    box(b,(-0.17,-0.745,1.012),(2.68,0.006,0.008),'label',skip=('top',))
    _plant_small(b,1.42,-0.50,1.055,0.30)
    ext_x(b,[(-0.70,1.055),(-0.66,1.055),(-0.67,1.12)],-0.10,0.0,'chrome'); box(b,(-0.05,-0.675,1.06),(0.09,0.004,0.055),'label') if False else None
    cyl(b,(-0.30,-0.15,0.77),0.035,0.10,8,'plastic_black',top=False)
    for k in range(2): rod(b,(-0.30,-0.15,0.80),(-0.30+0.02*k,-0.14,0.90),0.004,4,'tag_b' if k else 'paint_black',caps=True)
reception_desk=_wrap(reception_desk,_x_reception_desk)

# exam_bed: pull-out step, pillow, chrome pulls
def _x_exam_bed(b,hi):
    box(b,(-0.30,-0.36,0.0),(0.50,0.12,0.19),'paint_white',skip=('bottom','back'))
    box(b,(-0.30,-0.36,0.19),(0.50,0.12,0.012),'rubber',skip=('bottom',))
    ext_x(b,[(-0.22,0.0),(0.22,0.0),(0.24,0.04),(0.20,0.08),(-0.20,0.08),(-0.24,0.04)],0.62,0.86,'linen') if False else None
    for x in (-0.55,-0.10,0.35): box(b,(x,-0.30,0.50),(0.12,0.012,0.015),'chrome',skip=('back',))
exam_bed=_wrap(exam_bed,_x_exam_bed)

# physio_table: bolster roll, folded towel, foot control bar
def _x_physio_table(b,hi):
    z=0.67
    rod(b,(-0.80,-0.25,z+0.08),(-0.80,0.25,z+0.08),0.08,10,'vinyl',caps=True)
    box(b,(0.10,0.0,z),(0.40,0.30,0.04),'linen',skip=('bottom',)); box(b,(0.10,-0.12,z+0.04),(0.40,0.06,0.004),'linen_dk',skip=('bottom',))
physio_table=_wrap(physio_table,_x_physio_table)

# privacy_curtain_rail: runner gliders on the tracks, ceiling plates
def _x_privacy_curtain_rail(b,hi):
    zt=2.26
    for k in range(5): box(b,(-1.15+0.30*k,-1.2,zt-0.035),(0.02,0.03,0.035),'plastic',skip=('top',))
    for k in range(6): box(b,(-1.2,1.10-0.40*k,zt-0.035),(0.03,0.02,0.035),'plastic',skip=('top',))
    for p in ((1.2,-1.2),(-1.2,1.2),(-1.2,-1.2)): box(b,(p[0],p[1],2.29),(0.08,0.08,0.01),'chrome',skip=('top',))
privacy_curtain_rail=_wrap(privacy_curtain_rail,_x_privacy_curtain_rail)

# water_cooler: cup dispenser on the side
def _x_water_cooler(b,hi):
    rod(b,(0.175,0.0,0.78),(0.175,0.0,1.05),0.035,6,'cglass',caps=False); cyl(b,(0.175,0.0,0.76),0.04,0.02,6,'plastic',top=True,bot=True)
water_cooler=_wrap(water_cooler,_x_water_cooler)

# lecture_seating_row: row plates on the aisle standards, floor beam
def _x_lecture_seating_row(b,hi):
    for sg in (-1,1):
        x=sg*1.893
        ext_x(b,[(-0.05,0.62),(0.05,0.62),(0.05,0.70),(-0.05,0.70)],x-0.004 if sg<0 else x,x if sg<0 else x+0.004,'plate')
        if hi: txt(b,hi,'ROW F',0.03,(x+sg*0.0045,0.0,0.66),'paint_black',(0,-sg,0),(0,0,1))
    box(b,(0,0.05,0.0),(3.70,0.12,0.04),'steel_dk',skip=('bottom','left','right'))
lecture_seating_row=_wrap(lecture_seating_row,_x_lecture_seating_row)

# tablet_arm_chair: wire book basket under the seat, glides
def _x_tablet_arm_chair(b,hi):
    z=0.22
    for (a,c) in (((-0.20,-0.15),(0.20,-0.15)),((0.20,-0.15),(0.20,0.15)),((0.20,0.15),(-0.20,0.15)),((-0.20,0.15),(-0.20,-0.15))):
        rod(b,(a[0],a[1],z),(c[0],c[1],z),0.004,4,'chrome'); rod(b,(a[0],a[1],z+0.08),(c[0],c[1],z+0.08),0.004,4,'chrome')
    for x in (-0.10,0.0,0.10): rod(b,(x,-0.15,z),(x,0.15,z),0.003,4,'chrome')
    box(b,(0.05,0.0,z+0.004),(0.22,0.28,0.03),'bk_navy')
tablet_arm_chair=_wrap(tablet_arm_chair,_x_tablet_arm_chair)

# whiteboard_wall: three markers and an eraser on the tray
def _x_whiteboard_wall(b,hi):
    for (x,z,w,h) in ((0.95,0.62,0.21,0.28),(0.70,0.18,0.21,0.28)):
        fq(b,[V((x-w/2,-0.0015,z)),V((x+w/2,-0.0015,z)),V((x+w/2,-0.0015,z+h)),V((x-w/2,-0.0015,z+h))],'label',(0,-1,0),w,h)
        box(b,(x,-0.008,z+h-0.03),(0.025,0.006,0.025),'tag_r',skip=('back','bottom'))
    for (x,z) in ((0.20,1.0),(-0.95,0.30)): box(b,(x,-0.008,z),(0.025,0.006,0.025),'tag_b',skip=('back','bottom'))
whiteboard_wall=_wrap(whiteboard_wall,_x_whiteboard_wall)

# noticeboard_wall: business cards, brass corner caps
def _x_noticeboard_wall(b,hi):
    for (x,z) in ((0.50,0.38),(0.52,0.30),(-0.52,0.70)): box(b,(x,-0.012,z),(0.09,0.002,0.05),'label',skip=('back',))
    for (x,z) in ((-0.58,0.0),(0.58,0.0),(-0.58,0.86),(0.58,0.86)): box(b,(x,-0.027,z),(0.05,0.004,0.04),'brass',skip=('back',))
noticeboard_wall=_wrap(noticeboard_wall,_x_noticeboard_wall)

# directory_board: stand-off pins, YOU ARE HERE strip
def _x_directory_board(b,hi):
    for (x,z) in ((-0.44,0.06),(0.44,0.06),(-0.44,1.52),(0.44,1.52)): _disc_y(b,(x,z),0.016,-0.026,-0.005,8,'chrome',caps=(True,False))
    box(b,(0,-0.002,0.06),(0.60,0.004,0.06),'screen',skip=('back',)); txt(b,hi,'YOU ARE HERE: GROUND FLOOR',0.026,(0,-0.0045,0.09),'paint_white')
directory_board=_wrap(directory_board,_x_directory_board)

# listing_board_wall: SOLD riders on two cards, brochure pocket, stand-offs
def _x_listing_board_wall(b,hi):
    for (cx,cz) in ((-0.21,0.55),(0.63,0.10)):
        fq(b,[V((cx-0.19,-0.006,cz+0.30)),V((cx-0.05,-0.006,cz+0.40)),V((cx-0.02,-0.006,cz+0.37)),V((cx-0.16,-0.006,cz+0.27))],'atm_hdr',(0,-1,0),0.2,0.04)
        txt(b,hi,'SOLD',0.03,(cx-0.10,-0.0065,cz+0.335),'paint_white',(0.8,0,0.6),(-0.6,0,0.8))
    ext_x(b,[(-0.06,0.0),(0.0,0.0),(0.0,0.16),(-0.006,0.16),(-0.06,0.10)],-0.25,0.25,'cglass')
    for k in range(3): box(b,(-0.15+0.15*k,-0.03,0.01),(0.11,0.012,0.17),'label',skip=('bottom',))
listing_board_wall=_wrap(listing_board_wall,_x_listing_board_wall)

# atm_wall: camera dome, lit card slot, receipt slot, braille plate, surround light strips
def _x_atm_wall(b,hi):
    b.lathe([(0.04,1.48),(0.035,1.465),(0.02,1.455),(0.0,1.45)],8,'plastic_black',c=(0,-0.03,0),cap_top=False) if False else None
    _disc_y(b,(0.0,1.495),0.025,-0.105,-0.085,8,'plastic_black',caps=(True,False))
    box(b,(0.18,-0.116,0.97),(0.10,0.006,0.025),'leaf',skip=('back',))
    box(b,(-0.05,-0.116,0.86),(0.08,0.006,0.012),'plastic_black',skip=('back',))
    box(b,(-0.22,-0.116,0.94),(0.07,0.004,0.05),'plate',skip=('back',))
    for x in (-0.395,0.395): box(b,(x,0.134,0.10),(0.012,0.012,1.35),'label',skip=('back',))
atm_wall=_wrap(atm_wall,_x_atm_wall)

# ticket_machine: canopy, side route map, plinth, coin cup
def _x_ticket_machine(b,hi):
    ext_x(b,[(-0.31,1.74),(0.25,1.74),(0.25,1.82),(-0.25,1.82),(-0.31,1.79)],-0.42,0.42,'tm_body')
    box(b,(0.402,0.0,0.75),(0.004,0.38,0.62),'label',skip=('left',))
    if hi:
        txt(b,hi,'ROUTE MAP',0.035,(0.405,0.0,1.30),'paint_navy',(0,1,0),(0,0,1))
        for k,(y0,z0,y1,z1) in enumerate(((-0.15,0.85,0.15,1.20),(-0.15,1.05,0.15,0.90),(-0.05,0.80,-0.05,1.25))):
            b.sweep([(0.405,y0,z0),(0.405,(y0+y1)/2+0.04,(z0+z1)/2),(0.405,y1,z1)],0.004,4,('tag_r','tag_b','tag_g')[k],cap0=False,cap1=False)
    box(b,(0,0,0),(0.82,0.53,0.05),'rubber',skip=('bottom',))
    box(b,(0.20,-0.262,0.55),(0.12,0.012,0.08),'steel_dk',skip=('back',))
ticket_machine=_wrap(ticket_machine,_x_ticket_machine)

# reverse_vending_machine: lit header strip, side graphic, bin door handles
def _x_reverse_vending_machine(b,hi):
    box(b,(0,-0.42,1.86),(0.98,0.01,0.04),'label',skip=('back',))
    box(b,(0.503,0.0,0.55),(0.004,0.60,0.80),'flyer_g',skip=('left',))
    txt(b,hi,'RECYCLE  5c',0.05,(0.506,0.0,1.05),'paint_white',(0,1,0),(0,0,1)); txt(b,hi,'per bottle / can',0.03,(0.506,0.0,0.98),'paint_white',(0,1,0),(0,0,1))
    for x in (-0.30,0.30): box(b,(x,-0.425,0.40),(0.12,0.02,0.02),'chrome')
reverse_vending_machine=_wrap(reverse_vending_machine,_x_reverse_vending_machine)

# queue_ticket_dispenser: round base, pole collar
def _x_queue_ticket_dispenser(b,hi):
    ext_z(b,circ((0,0),0.15,10),0.0,0.02,'paint_black',caps=(False,True)); cyl(b,(0,0,0.02),0.03,0.04,8,'chrome')
queue_ticket_dispenser=_wrap(queue_ticket_dispenser,_x_queue_ticket_dispenser)

# vault_door: frame bolt heads, threshold plate, time-lock window
def _x_vault_door(b,hi):
    for k in range(10):
        z=0.25+0.19*k
        for x in (-0.93,0.93): _disc_y(b,(x,z),0.018,-0.005,0.0,6,'chrome',caps=(True,False))
    box(b,(0,-0.175,0.0),(1.70,0.15,0.015),'steel_dk',skip=('bottom',))
    box(b,(0.36,-0.136,1.10+0.32),(0.20,0.006,0.10),'cglass',skip=('back',))
vault_door=_wrap(vault_door,_x_vault_door)

# luggage_cart: rubber bumper band instead of rod rails; garment bag + hangers on the top rail
def luggage_cart(b, hi=False):
    box(b,(0,0,0.12),(1.06,0.58,0.05),'paint_black',skip=())
    box(b,(0,0,0.17),(1.04,0.56,0.012),'cush',skip=('bottom',))
    for x in (-0.47,0.47):
        for y in (-0.23,0.23):
            cyl(b,(x,y,0.0),0.05,0.04,6,'rubber'); box(b,(x,y,0.04),(0.04,0.06,0.08),'chrome',skip=('top',))
    ext_z(b,rrect(-0.545,-0.305,0.545,0.305,0.04,1),0.125,0.165,'rubber',caps=(False,False))
    for x in (-0.50,0.50):
        rod(b,(x,-0.24,0.17),(x,-0.24,1.55),0.016,6,'brass'); rod(b,(x,0.24,0.17),(x,0.24,1.55),0.016,6,'brass')
        pts=[(x,-0.24*math.cos(math.radians(t)),1.55+0.22*math.sin(math.radians(t))) for t in range(0,181,30)]
        b.sweep(pts,0.016,6,'brass',cap0=False,cap1=False)
    rod(b,(-0.50,0,1.77),(0.50,0,1.77),0.018,6,'brass',caps=True)
    box(b,(-0.18,0.0,0.182),(0.62,0.40,0.24),'case'); box(b,(-0.18,0.0,0.422),(0.18,0.03,0.03),'plastic_black')
    rod(b,(0.18,-0.18,0.32),(0.18,0.18,0.32),0.13,8,'duffel',caps=True)
    # garment bag on a hanger
    fq(b,[V((0.20,0.0,1.77)),V((0.12,0.0,1.70)),V((0.28,0.0,1.70)),V((0.20,0.0,1.77))],'chrome',(0,-1,0),0.1,0.1) if False else None
    ext_x(b,[(-0.05,0.70),(0.05,0.70),(0.06,1.66),(0.0,1.71),(-0.06,1.66)],0.06,0.34,'case_g')
    rod(b,(0.20,0.0,1.71),(0.20,0.0,1.77),0.004,4,'chrome')
    maker_plate(b,(-0.30,-0.203,0.28),hi,0.10,0.03)
    b.cbox((0,0,0),(1.10,0.60,1.80))

# ================================================================== keys, tints, PROPS
NEWK={'wal':('ti_wood',(0.50,0.32,0.20)),'wal_dk':('ti_wood',(0.36,0.22,0.14)),'linen':('ti_fabric',(1.0,0.98,0.94)),
 'leather':('ti_fabric',(0.26,0.11,0.075)),'stage':('ti_wood',(0.17,0.16,0.15)),'skirt':('ti_fabric',(0.09,0.09,0.10)),
 'vinyl':('ti_plastic',(0.14,0.42,0.46)),'ceramic_w':('ti_paint',(1.0,1.0,1.0)),'curtain':('ti_fabric',(0.58,0.74,0.80)),
 'curtain_dk':('ti_fabric',(0.40,0.55,0.62)),'tap_blue':('ti_plastic',(0.10,0.25,0.75)),'tap_red':('ti_plastic',(0.80,0.10,0.08)),
 'bottle':('ti_glass',(0.50,0.72,0.95)),'std':('ti_wood',(0.95,0.80,0.60)),'seatfab':('ti_fabric',(0.12,0.16,0.34)),
 'shell':('ti_plastic',(0.20,0.38,0.62)),'felt':('ti_fabric',(0.14,0.14,0.14)),'screenfab':('ti_paint',(1.0,1.0,1.0)),
 'cork':('ti_fabric',(0.66,0.46,0.28)),'panelfab':('ti_fabric',(0.36,0.42,0.48)),'tm_body':('ti_paint',(0.12,0.30,0.62)),
 'rvm_green':('ti_paint',(0.10,0.45,0.25)),'tag_r':('ti_plastic',(0.80,0.12,0.10)),'tag_g':('ti_plastic',(0.15,0.55,0.25)),
 'tag_b':('ti_plastic',(0.12,0.30,0.75)),'case':('ti_plastic',(0.10,0.12,0.16)),'duffel':('ti_fabric',(0.45,0.30,0.15)),
 'lawn':('ti_fabric',(0.30,0.52,0.22)),'pool':('ti_paint',(0.30,0.70,0.85)),'house':('ti_paint',(1.0,0.97,0.90)),
 'roof':('ti_paint',(0.70,0.30,0.18)),'stone':('ti_paint',(0.55,0.53,0.50)),'dome':('ti_fabric',(0.62,0.24,0.13)),
 'ember':('ti_paint',(1.0,0.45,0.08)),'steel_dk':('ti_metal',(0.35,0.35,0.37)),'vault':('ti_metal',(0.70,0.72,0.74)),
 'vault_dk':('ti_metal',(0.48,0.49,0.51)),'car':('ti_metal',(0.62,0.06,0.07)),'carblk':('ti_plastic',(0.08,0.08,0.09)),
 'headlamp':('ti_glass',(1.0,1.0,1.0)),'taillamp':('ti_glass',(0.75,0.06,0.05)),'tyre':('ti_plastic',(0.07,0.07,0.07)),
 'rim':('ti_metal',(0.85,0.86,0.88)),
 'cglass':('ti_metal',(0.11,0.14,0.18)),'skirt_dk':('ti_fabric',(0.05,0.05,0.06)),'stage_dk':('ti_wood',(0.12,0.11,0.10)),
 'alum_dk':('ti_metal',(0.45,0.46,0.48)),'lawn_dk':('ti_fabric',(0.18,0.38,0.14)),'vinyl_dk':('ti_plastic',(0.08,0.28,0.30)),
 'stone_dk':('ti_paint',(0.40,0.38,0.36)),'dome_dk':('ti_fabric',(0.42,0.16,0.09)),'case_g':('ti_fabric',(0.10,0.14,0.22)),
 'flag_r':('ti_fabric',(0.70,0.08,0.08)),'linen_dk':('ti_fabric',(0.85,0.82,0.78))}
for k,(t,c) in NEWK.items(): TR[k]=(t,(0.875,0.875)); TINT[k]=c
WOODK={'pw','wal'}     # wood keys on baked (focal) faces too: vertex tint on every face of the key, not trim_tint
TINT['pw']=PW
_C=dict(dir='props/indoor/places',pdir='indoor',trim=TR,trim_tint={k:v for k,v in TINT.items() if k not in WOODK},
        tint={k:TINT[k] for k in WOODK},page='k',conds=['clean'],cat='prop',bevel=0.003,no_ch=True,max_side=128)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
WALL=dict(mount='wall',cage=0.04,ray=0.10)
PROPS=[
    _p('church_pew',church_pew,'medium',1200,focal=[((-1.51,-0.33,-0.01),(-1.495,0.33,0.97))],hero=True,dens=240,max_side=192,cage=0.04,ray=0.10),
    _p('church_pew_short',church_pew_short,'medium',800,focal=[((-0.91,-0.33,-0.01),(-0.895,0.33,0.97))],hero=True,dens=240,max_side=128,cage=0.04,ray=0.10),
    _p('court_bench',court_bench,'medium',900,focal=[((-1.51,-0.30,-0.01),(-1.495,0.30,0.95))],max_side=128,cage=0.04,ray=0.10),
    _p('lectern',lectern,'small',450,focal=[((-0.27,-0.216,0.07),(0.27,-0.204,1.0))],hero=True,dens=200,cage=0.04,ray=0.10),
    _p('altar_table',altar_table,'medium',800,focal=[((-0.94,-0.345,0.10),(0.94,-0.335,0.92))],hero=True,dens=150,max_side=192,cage=0.04,ray=0.10),
    _p('judge_bench',judge_bench,'large',1800,focal=[((-1.80,-0.47,0.30),(1.80,-0.455,1.10)),((-1.80,-0.10,0.30),(-1.795,0.30,1.23)),((1.795,-0.10,0.30),(1.80,0.30,1.23))],hero=True,dens=110,max_side=192,cage=0.04,ray=0.10),
    _p('witness_box',witness_box,'medium',900,focal=[((-0.70,-0.605,0.20),(0.70,-0.595,1.02)),((-0.705,-0.55,0.20),(-0.695,0.45,1.02)),((0.695,-0.55,0.20),(0.705,0.45,1.02))],hero=True,dens=120,max_side=192,cage=0.04,ray=0.10),
    _p('jury_box',jury_box,'large',1500,focal=[((-2.0,-0.805,0.12),(2.0,-0.795,0.96))],hero=True,dens=90,max_side=192,cage=0.04,ray=0.10),
    _p('conference_table',conference_table,'large',1200,max_side=64),
    _p('chart_table',chart_table,'medium',800,max_side=192,hero=True,dens=140),
    _p('drafting_table',drafting_table,'medium',800,max_side=160,hero=True,dens=160),
    _p('reception_desk',reception_desk,'large',1500,max_side=128),
    _p('stage_platform',stage_platform,'medium',600,max_side=96),
    _p('dental_chair',dental_chair,'large',1500,max_side=96),
    _p('exam_bed',exam_bed,'medium',700,max_side=64),
    _p('physio_table',physio_table,'medium',700,max_side=64),
    _p('privacy_curtain_rail',privacy_curtain_rail,'small',400,max_side=64),
    _p('water_cooler',water_cooler,'small',350,max_side=64),
    _p('lecture_seating_row',lecture_seating_row,'large',1500,max_side=64),
    _p('tablet_arm_chair',tablet_arm_chair,'small',500,max_side=64),
    _p('whiteboard_wall',whiteboard_wall,'tiny',250,max_side=192,hero=True,dens=110,**WALL),
    _p('projector_screen',projector_screen,'tiny',220,max_side=128,dens=60,**WALL),
    _p('noticeboard_wall',noticeboard_wall,'tiny',250,max_side=160,hero=True,dens=200,**WALL),
    _p('directory_board',directory_board,'tiny',250,max_side=160,hero=True,dens=150,**WALL),
    _p('departure_board',departure_board,'small',350,max_side=160,hero=True,dens=170,**WALL),
    _p('listing_board_wall',listing_board_wall,'small',400,max_side=192,hero=True,dens=150,**WALL),
    _p('key_rack_wall',key_rack_wall,'tiny',250,focal=[((-0.41,-0.012,0.0),(0.41,-0.008,0.61))],max_side=128,hero=True,dens=220,**WALL),
    _p('cubicle_partition',cubicle_partition,'medium',600,max_side=128,hero=True,dens=300),
    _p('atm_wall',atm_wall,'small',500,max_side=128,hero=True,dens=300,**WALL),
    _p('ticket_machine',ticket_machine,'medium',700,max_side=128,hero=True,dens=220,cage=0.04,ray=0.10),
    _p('reverse_vending_machine',reverse_vending_machine,'medium',800,max_side=128,hero=True,dens=200,cage=0.04,ray=0.10),
    _p('queue_ticket_dispenser',queue_ticket_dispenser,'tiny',200,max_side=64,hero=True,dens=400),
    _p('drive_thru_window',drive_thru_window,'small',400,max_side=96,dens=200,**WALL),
    _p('vault_door',vault_door,'large',1500,max_side=64,**WALL),
    _p('luggage_cart',luggage_cart,'small',500,max_side=64),
    _p('model_house_display',model_house_display,'small',500,max_side=96,hero=True,dens=300),
    _p('pizza_oven',pizza_oven,'medium',1000,max_side=128,dens=160,cage=0.04,ray=0.10),
    _p('showroom_car',showroom_car,'large',2500,max_side=128),
]
INDOOR_LOOK=True   # run.py: chamfer edge highlight + per-part colour variation in COLOR_0
