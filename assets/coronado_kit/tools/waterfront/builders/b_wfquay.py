"""Waterfront set 1: quay / seawall edge (snap-in, 0.5 m grid). References (shape only): San Diego Bay / Coronado Ferry
Landing and Oceanside harbor quays: cast concrete seawall with a granite coping, square timber fender piles on galvanized
straps, galvanized quay ladders with grab hoops, cast-iron tee-head bollards, harbour steps parallel to the wall.
Datum (wf_parts): z=0 harbour bed at the toe, still water 1.5, coping/deck top 3.0. Front (water side) = -Y here (+Z in glTF).
Straight module 6.0 x 2.0 m: fender face line y=-1.0, wall face -0.70, coping -0.75..-0.15, paving to the back edge +1.0.
Back faces (against fill), bottoms (harbour bed) and the snap ends are open by design (modular rule 1)."""
import math
from mathutils import Vector, Matrix
import pg
import wf_parts as P
from wf_parts import rect, rec, cbox, ccyl, bollard, cleat, ring, fender_pile, ladder, guardrail, bolt_head, WL, DECK
PI=math.pi
ZC=2.70; ZT=1.75; YF=-0.70; YC=-0.75; YB=-0.15; YE=-1.0
TR={'cmu':('tw_tide',(0.875,0.875)),'stucco':('tw_tide_hi',(0.875,0.875)),'concrete':('tw_conc_top',(0.875,0.875)),'paint_beige':('tw_conc',(0.875,0.875)),'stone':('tw_granite',(0.875,0.875)),
    'brick':('tw_paver',(0.875,0.875)),'wood_weathered':('tw_timber',(0.875,0.875),2.0)}
ZM=0.875; ZBM=2.41   # submerged / barnacle-band split, capping-beam underside
def _band(b,p0,p1,z0,z1,tier):
    """wall face between plan points p0->p1 (water on the right): submerged growth below 0.875, barnacle band to the
    high-water line 1.75, cast concrete above (drip streaks from the coping, wet foot)"""
    p0=Vector((p0[0],p0[1],0)); p1=Vector((p1[0],p1[1],0)); u=p1-p0; up=Vector((0,0,1))
    for a,c,k in ((0.0,ZM,'cmu'),(ZM,ZT,'stucco'),(ZT,99.0,'concrete')):
        lo=max(z0,a); hi_=min(z1,c)
        if hi_>lo+1e-4: rect(b,p0+up*lo,u,up*(hi_-lo),k)
def offset(pts,d):
    """offset a plan polyline by d to the RIGHT of travel (towards the water) with mitred joints"""
    out=[]; n=len(pts)
    def nr(a,b): t=Vector((b[0]-a[0],b[1]-a[1],0)).normalized(); return Vector((t.y,-t.x,0))
    for i in range(n):
        if i==0: m=nr(pts[0],pts[1]); out.append(Vector((pts[0][0],pts[0][1],0))+m*d); continue
        if i==n-1: m=nr(pts[-2],pts[-1]); out.append(Vector((pts[-1][0],pts[-1][1],0))+m*d); continue
        n0=nr(pts[i-1],pts[i]); n1=nr(pts[i],pts[i+1]); m=(n0+n1); k=1+n0.dot(n1)
        out.append(Vector((pts[i][0],pts[i][1],0))+m*(d/k))
    return out
TP=0.875   # trim tile period (m)
def refine(face,tier):
    """split short (curved-run) segments of a plan polyline at tile edges and give each segment its u start along the run,
    so narrow arc facets continue the tile instead of each re-sampling a stretched sliver. Long segments map whole cells
    (cell edges = tile edges) and reset the run."""
    P_=TP*(2.0 if tier=='mid' else 1.0); out=[face[0]]; us=[]; cum=0.0
    for i in range(len(face)-1):
        a=Vector((face[i][0],face[i][1],0)); c=Vector((face[i+1][0],face[i+1][1],0)); L=(c-a).length
        if L>=0.6*P_: us.append(None); out.append(face[i+1]); cum=0.0; continue
        t=0.0
        while True:
            nxt=(math.floor(cum/TP+1e-6)+1)*TP-cum
            if t+nxt>=L-1e-4: us.append(cum); cum+=L-t; out.append(face[i+1]); break
            q=a+(c-a)*((t+nxt)/L); us.append(cum); out.append((q.x,q.y)); cum+=nxt; t+=nxt
    return out,us
def wall_and_coping(b,face,tier,hi,soffit=True,top=True,back_d=0.55,caps=(False,False)):
    """wall face along the plan polyline `face` (water on the right) + granite coping (overhang 0.05, 3 cm arris chamfer)"""
    face,US=refine(face,tier)
    try: return _wall_and_coping(b,face,US,tier,hi,soffit,top,back_d,caps)
    finally: b.u_start=None
def _wall_and_coping(b,face,US,tier,hi,soffit,top,back_d,caps):
    up=Vector((0,0,1))
    f5=offset(face,0.05); f2=offset(face,0.02 if tier!='mid' else 0.05); bk=offset(face,-back_d); f0=offset(face,0.0); fb=offset(face,0.025)
    if tier=='mid':
        for i in range(len(face)-1): b.u_start=US[i]; _band(b,face[i],face[i+1],0.0,ZC,tier)
    else:   # cast capping beam under the coping: 25 mm proud, chamfered underside (shadow line)
        for i in range(len(face)-1):
            b.u_start=US[i]; _band(b,face[i],face[i+1],0.0,ZBM,tier)
            b.quad([f0[i]+up*ZBM,f0[i+1]+up*ZBM,fb[i+1]+up*(ZBM+0.025),fb[i]+up*(ZBM+0.025)],'paint_beige')
            rect(b,fb[i]+up*(ZBM+0.025),fb[i+1]-fb[i],up*(ZC-ZBM-0.025),'paint_beige')
        b.u_start=None
        for e,cap in ((0,caps[0]),(len(face)-1,caps[1])):
            if not cap: continue
            q=[f0[e]+up*ZBM,fb[e]+up*(ZBM+0.025),fb[e]+up*ZC,f0[e]+up*ZC]
            t=(Vector((face[1][0]-face[0][0],face[1][1]-face[0][1],0)) if e==0 else Vector((face[-1][0]-face[-2][0],face[-1][1]-face[-2][1],0)))
            nq=(q[1]-q[0]).cross(q[2]-q[0])
            if (nq.dot(t)>0)==(e==0): q=q[::-1]
            b.quad(q,'paint_beige')
    for i in range(len(face)-1):
        a,c=f5[i],f5[i+1]; b.u_start=US[i]
        if tier=='mid':
            rect(b,a+up*ZC,c-a,up*(DECK-ZC),'stone')
        else:
            rect(b,a+up*ZC,c-a,up*(DECK-0.03-ZC),'stone')
            b.quad([a+up*(DECK-0.03),c+up*(DECK-0.03),f2[i+1]+up*DECK,f2[i]+up*DECK],'stone')
        if top: b.quad([f2[i]+up*DECK,f2[i+1]+up*DECK,bk[i+1]+up*DECK,bk[i]+up*DECK],'stone')
        if soffit and tier!='mid': b.quad([fb[i]+up*ZC,fb[i+1]+up*ZC,f5[i+1]+up*ZC,f5[i]+up*ZC],'stone')
    return f5,f2,bk
def paving(b,x0,x1,y0,y1,key='brick'):
    rect(b,(x0,y0,DECK),(x1-x0,0,0),(0,y1-y0,0),key)
def safety_line(b,pts_front,tier,inset=0.06,w=0.09):
    """yellow quay-edge line painted on the coping top (2 mm proud: paint build-up)"""
    if tier=='mid': return
    a=offset(pts_front,-inset); c=offset(pts_front,-inset-w); up=Vector((0,0,DECK+0.002))
    for i in range(len(a)-1): b.quad([a[i]+up,a[i+1]+up,c[i+1]+up,c[i]+up],'paint_yellow')
def weep(b,x,z,yf=YF,hi=False):
    b.tube((x,yf+0.002,z),(x,yf-0.05,z),0.045,0.045,8 if not hi else 16,'plastic_white',cap0=False,cap1=False)
    b.tube((x,yf-0.05,z),(x,yf-0.05+0.04,z),0.045,0.032,8 if not hi else 16,'plastic_black',cap0=False,cap1=False)   # bore (dark)
def scupper(b,x,hi=False):
    """cast-iron deck-drain outlet through the capping beam (dark mouth, rust stain baked below)"""
    y=YF-0.025; z=2.47
    b.box((x,y-0.03,z),(0.26,0.06,0.16),'cast_iron',skip=('back',))
    rect(b,(x-0.09,y-0.0601,z+0.03),(0.18,0,0),(0,0,0.08),'plastic_black')
    if hi:
        for sx in (-0.11,0.11): bolt_head(b,(x+sx,y-0.06,z+0.08),(0,-1,0),0.008,'cast_iron',hi)
def pit_cover(b,x,y,hi=False,text='WATER'):
    b.box((x,y,DECK),(0.60,0.45,0.012),'cast_iron',skip=('bottom',))
    if hi:
        for i in range(9): b.box((x-0.24+i*0.06,y-0.05,DECK+0.012),(0.025,0.22,0.004),'cast_iron',skip=('bottom',))
        pg.add_text(b,text,0.05,(x,y+0.15,DECK+0.012),(1,0,0),(0,1,0),0.004,'cast_iron')
        for sx in (-1,1): b.box((x+sx*0.25,y-0.17,DECK+0.012),(0.05,0.03,0.004),'cast_iron',skip=('bottom',))   # lift keyholes rims
# =============================================================== straight 6 m
def straight(b,hi=False,tier='near',ladder_on=True,variant=''):
    P.TIER['t']='hi' if hi else tier
    if tier=='near' and not hi: P.reset()
    X0,X1=-3.0,3.0; NX=0.45; YN=YF+0.22   # ladder niche half width, niche back
    up=Vector((0,0,1))
    if ladder_on:
        L=[(X0,YF),(-NX,YF)]; R=[(NX,YF),(X1,YF)]
        wall_and_coping(b,L,tier,hi,caps=(False,True)); wall_and_coping(b,R,tier,hi,caps=(True,False))
        # niche: sides + back (tide / concrete) and the granite notch at the coping
        _band(b,(-NX,YF),(-NX,YN),0,ZC,tier)        # niche left side (faces +x)
        _band(b,(NX,YN),(NX,YF),0,ZC,tier)
        _band(b,(-NX,YN),(NX,YN),0,ZC,tier)
        rect(b,(-NX,YN,ZC),(2*NX,0,0),(0,0,DECK-ZC),'stone')                          # notch front (granite)
        for s in (-1,1):   # notch side faces of the copings (pentagon section)
            x=s*NX; prof=[(YC,ZC),(YN,ZC),(YN,DECK),(YC+0.03,DECK),(YC,DECK-0.03)] if tier!='mid' else [(YC,ZC),(YN,ZC),(YN,DECK),(YC,DECK)]
            pts=[Vector((x,y,z)) for y,z in prof]
            if s>0: pts=pts[::-1]
            b.quad(pts,'stone')
        rect(b,(-NX,YN,DECK),(2*NX,0,0),(0,YB-YN,0),'stone')                         # notch coping top
        safety_line(b,[(X0,YC),(-NX,YC)],tier); safety_line(b,[(NX,YC),(X1,YC)],tier)
    else:
        wall_and_coping(b,[(X0,YF),(X1,YF)],tier,hi); safety_line(b,[(X0,YC),(X1,YC)],tier)
    paving(b,X0,X1,YB,1.0)
    # expansion joint sealant strips (vertical) at the panel joints x=-1.5 / +1.5 sit behind the fenders: x = -2.25, 2.25 instead
    if tier!='mid':
        for x in (-2.25,2.25):
            rect(b,(x-0.012,YF-0.003,0.0),(0.024,0,0),(0,0,ZC),'rubber_black')
        for x in (-0.95,0.95,-2.65,2.65):
            if not ladder_on or abs(x)>NX+0.1: weep(b,x,1.95,hi=hi)
    for x in (-1.5,1.5): fender_pile(b,x,YF,0.0,2.60,hi,tier)
    bollard(b,(-1.5 if ladder_on else -1.5,(YC+YB)/2,DECK),hi,tier,text='CROWNADO HARBOR')
    if not ladder_on: bollard(b,(1.5,(YC+YB)/2,DECK),hi,tier,text='CROWNADO HARBOR')
    if ladder_on:
        ladder(b,0.0,YN,0.30,ZC-0.02,hi,tier,yland=0.62)
        if tier!='mid': ring(b,(2.35,YF,2.30),(0,-1,0),hi=hi,tier=tier)
    elif tier!='mid':
        ring(b,(0.0,YF,2.30),(0,-1,0),hi=hi,tier=tier)
    if tier!='mid': pit_cover(b,2.1 if ladder_on else -0.3,0.45,hi); scupper(b,-2.65 if ladder_on else 2.65,hi)
    if tier=='near' and not hi:
        cbox(b,(0,0.125,0),(6.0,1.75,DECK)) if not ladder_on else (cbox(b,(-1.725,0.125,0),(2.55,1.75,DECK)),cbox(b,(1.725,0.125,0),(2.55,1.75,DECK)),cbox(b,(0,(YN+1.0)/2,0),(0.9,1.0-YN,DECK)))
def straight_hi(b): straight(b,hi=True)
def straight_mid(b): straight(b,tier='mid')
def straight_nl(b,hi=False,tier='near'): straight(b,hi,tier,ladder_on=False)
def straight_nl_hi(b): straight_nl(b,hi=True)
def straight_nl_mid(b): straight_nl(b,tier='mid')
def far_straight(b,X0=-3.0,X1=3.0,yfar=-0.85,bol=((-1.5,),)):
    up=Vector((0,0,1))
    rect(b,(X0,yfar,0),(X1-X0,0,0),(0,0,ZT),'twf_flat'); rect(b,(X0,yfar,ZT),(X1-X0,0,0),(0,0,DECK-ZT),'twf_flat')
    rect(b,(X0,yfar,DECK),(X1-X0,0,0),(0,1.0-yfar,0),'twf_flat')
def straight_far(b): far_straight(b)
# =============================================================== outside corner 2 x 2 m (rounded granite corner R 0.6)
def _arc(cx,cy,R,a0,a1,n):
    return [(cx+R*math.cos(a0+(a1-a0)*k/n),cy+R*math.sin(a0+(a1-a0)*k/n)) for k in range(n+1)]
def corner_out(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier
    if tier=='near' and not hi: P.reset()
    Rr=0.6; cx,cy=0.70-Rr,YF+Rr; n=12 if hi else (2 if tier=='mid' else 6)
    face=[(-1.0,YF)]+_arc(cx,cy,Rr,-PI/2,0,n)+[(0.70,1.0)]
    f5,f2,bk=wall_and_coping(b,face,tier,hi,top=False)
    up=Vector((0,0,DECK))
    # coping top: straight runs as quads, the arc as a fan from the sharp back corner (0.15,-0.15)
    Bc=Vector((0.15,YB,DECK))
    b.quad([f2[0]+up,f2[1]+up,Vector((0.10,YB,DECK)),Vector((-1.0,YB,DECK))],'stone')
    for i in range(1,len(f2)-2): b.faces([f2[i]+up,f2[i+1]+up,Bc],[(0,1,2)],'stone',[[(0,0),(0.3,0),(0.15,0.4)]])
    b.quad([f2[-2]+up,f2[-1]+up,Vector((0.15,1.0,DECK)),Vector((0.15,-0.10,DECK))],'stone')
    b.faces([f2[-2]+up,Vector((0.15,-0.10,DECK)),Bc],[(0,1,2)],'stone',[[(0,0),(0.3,0),(0.1,0.3)]])
    b.faces([f2[1]+up,Bc,Vector((0.10,YB,DECK))],[(0,1,2)],'stone',[[(0,0),(0.3,0),(0.1,0.3)]])
    paving(b,-1.0,0.15,YB,1.0)
    safety_line(b,[(-1.0,YC)]+_arc(cx,cy,Rr+0.05,-PI/2,0,n)+[(0.75,1.0)],tier)
    # fenders on both arms, a cylindrical rubber corner fender on chains at the 45 deg point, corner bollard
    fender_pile(b,-0.55,YF,0.0,2.60,hi,tier)
    # arm B fender (faces +x): build at origin then rotate the new geometry
    _rot_part(b,lambda: fender_pile(b,0.0,0.0,0.0,2.60,hi,tier),PI/2,(0.70,0.55,0))
    a=-PI/4; fx,fy=cx+(Rr+0.18)*math.cos(a),cy+(Rr+0.18)*math.sin(a)
    if tier!='mid':
        sg=24 if hi else 12
        b.tube((fx,fy,1.25),(fx,fy,2.35),0.18,0.18,sg,'rubber_black',cap0=True,cap1=True)
        ex,ey=cx+(Rr+0.05)*math.cos(a),cy+(Rr+0.05)*math.sin(a)
        # eye plate on the coping face, shackle + chain down to the fender's top eye
        b.box((ex-0.01*math.cos(a),ey-0.01*math.sin(a),2.78),(0.14,0.02,0.12),'galvanized',rz=a+PI/2,skip=('back',))
        top=Vector((fx,fy,2.35)); eye=Vector((ex+0.03*math.cos(a),ey+0.03*math.sin(a),2.84))
        _chain(b,eye,top+Vector((0,0,0.0)),hi)
    else:
        b.tube((fx,fy,1.25),(fx,fy,2.35),0.18,0.18,6,'rubber_black',cap0=True,cap1=True)
    bollard(b,(cx+0.35*math.cos(a)+0.0,cy+0.35*math.sin(a),DECK),hi,tier,text='CROWNADO HARBOR')
    if tier=='near' and not hi:
        cbox(b,(0.0,0.0,0),(2.0,2.0,DECK))
        ccyl(b,(fx,fy,1.25),0.18,1.10,rail=False)
def _chain(b,p0,p1,hi):
    """short galvanized chain: alternating link loops between two points"""
    p0=Vector(p0); p1=Vector(p1); d=p1-p0; L=d.length; d.normalize(); n=max(2,int(L/0.07))
    side=d.cross(Vector((1,0,0))) if abs(d.x)<0.9 else d.cross(Vector((0,1,0))); side.normalize(); s2=d.cross(side)
    for k in range(n):
        c=p0+d*(L*(k+0.5)/n); ax=side if k%2==0 else s2; ll=L/n*0.62
        pts=[c+d*ll*math.cos(t)*1.0+ax*0.018*math.sin(t) for t in [2*PI*i/(10 if hi else 6) for i in range((10 if hi else 6)+1)]]
        b.sweep(pts,0.006,4 if not hi else 6,'galvanized',cap0=False,cap1=False)
def _rot_part(b,fn,ang,t=(0,0,0)):
    """run a part builder at the origin, then rotate the faces / collision / rail records it added about z and move them by t"""
    n0=set(b.bm.verts); c0=len(b.col); r0=len(P.RAILS)
    fn()
    R=Matrix.Rotation(ang,3,'Z'); t=Vector(t)
    for v in b.bm.verts:
        if v not in n0: v.co=t+R@v.co
    for i in range(c0,len(b.col)):
        e=list(b.col[i]); p=t+R@Vector(e[1]); e[1]=(p.x,p.y,p.z)
        if e[0]=='box': e[3]=e[3]+ang
        b.col[i]=tuple(e)
    for i in range(r0,len(P.RAILS)):
        k,a,bb,r,pp=P.RAILS[i]; P.RAILS[i]=(k,tuple(t+R@Vector(a)),tuple(t+R@Vector(bb)),r,[tuple(t+R@Vector(x)) for x in pp])
def corner_out_hi(b): corner_out(b,hi=True)
def corner_out_mid(b): corner_out(b,tier='mid')
def corner_out_far(b):
    Rr=0.6; cx,cy=0.70-Rr,YF+Rr; ff=-0.85
    pts=[(-1.0,ff)]+_arc(cx,cy,Rr+0.15,-PI/2,0,2)+[(0.85,1.0)]
    for i in range(len(pts)-1):
        p0=Vector((pts[i][0],pts[i][1],0)); p1=Vector((pts[i+1][0],pts[i+1][1],0)); rect(b,p0,p1-p0,(0,0,DECK),'twf_flat')
    top=[Vector((x,y,DECK)) for x,y in pts]+[Vector((-1.0,1.0,DECK))]
    b.faces(top[::-1],[tuple(range(len(top)))],'twf_flat',[[(p.x,p.y) for p in top[::-1]]])
# =============================================================== inside corner 4 x 4 m L (water quadrant x<0.3, y<0.3)
def corner_in(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier
    if tier=='near' and not hi: P.reset()
    W=0.30
    face=[(-2.0,W),(W,W),(W,-2.0)]
    f5,f2,bk=wall_and_coping(b,face,tier,hi)
    paving(b,-2.0,2.0,W+0.55,2.0); paving(b,W+0.55,2.0,-2.0,W+0.55)
    safety_line(b,[(-2.0,W-0.05),(W-0.05,W-0.05),(W-0.05,-2.0)],tier)
    # concave-corner timber rubbing post (touches both walls) + arm fenders
    _corner_post(b,W,hi,tier)
    fender_pile(b,-1.35,W,0.0,2.60,hi,tier)
    # arm B fender: wall face x=W facing -x; pile centre at (W-0.15, -1.35)
    _armB_fender(b,W,-1.35,hi,tier)
    cleat(b,(-1.0,W+0.27,DECK),0.0,hi,tier)
    cleat(b,(W+0.27,-0.9,DECK),PI/2,hi,tier)
    if tier!='mid':
        weep(b,-0.6,1.95,yf=W,hi=hi)
        ring(b,(-0.30,W,2.30),(0,-1,0),hi=hi,tier=tier)
    if tier=='near' and not hi:
        cbox(b,(0.0,(W+2.0)/2,0),(4.0,2.0-W,DECK)); cbox(b,((W+2.0)/2,(-2.0+W)/2,0),(2.0-W,2.0+W,DECK))
def _corner_post(b,W,hi,tier):
    w=0.30; x=W-w/2; y=W-w/2
    if tier=='mid': b.box((x,y,0),(w,w,2.62),'wood_weathered',skip=('bottom','back','right')); return
    r=w/2/math.cos(PI/8); b.tube((x,y,0),(x,y,2.62),r,r,8,'wood_weathered',cap0=False,cap1=True,smooth=False,phase=PI/8)
    for zb in (0.9,1.9):
        b.box((x-w/2-0.006,y,zb),(0.012,w+0.0,0.06),'galvanized')      # straps on the two exposed faces
        b.box((x,y-w/2-0.006,zb),(w,0.012,0.06),'galvanized')
        bolt_head(b,(x-w/2-0.012,y,zb+0.03),(-1,0,0),0.016,'galvanized',hi); bolt_head(b,(x,y-w/2-0.012,zb+0.03),(0,-1,0),0.016,'galvanized',hi)
    ccyl(b,(x,y,0),w/2,2.62,rail=True)
def _armB_fender(b,W,yc,hi,tier):
    w=0.30; x=W-w/2
    import wf_parts as PP
    if tier=='mid': b.box((x,yc,0),(w,w,2.60),'wood_weathered',skip=('bottom','top')); return
    _rot_part(b,lambda: fender_pile(b,0.0,0.0,0.0,2.60,hi,tier),-PI/2,(W,yc,0))
def corner_in_hi(b): corner_in(b,hi=True)
def corner_in_mid(b): corner_in(b,tier='mid')
def corner_in_far(b):
    W=0.30; ff=W-0.15
    rect(b,(-2.0,ff,0),(2.0+ff,0,0),(0,0,DECK),'twf_flat'); rect(b,(ff,ff,0),(0,-2.0-ff,0),(0,0,DECK),'twf_flat')
    top=[Vector((-2.0,ff,DECK)),Vector((ff,ff,DECK)),Vector((ff,-2.0,DECK)),Vector((2.0,-2.0,DECK)),Vector((2.0,2.0,DECK)),Vector((-2.0,2.0,DECK))]
    b.faces(top,[(0,1,2,3,4,5)],'twf_flat',[[(p.x,p.y) for p in top]])
# =============================================================== harbour steps (6 m module): flight parallel to the wall
SX1=1.1; NR=8; TRD=0.30; ZL=1.65; XL=-2.5; YR=0.50
def _zs(i): return DECK-(i+1)*(DECK-ZL)/NR      # tread i top
def stair(b,hi=False,tier='near'):
    """8 granite treads from the quay top down to a 1.5 m landing 15 cm above still water, cut into the quay between the
    wall face (open to the water) and a retaining wall; wall-mounted handrail on the retaining wall, guard railing round
    the opening on the quay top, bollard, mooring ring on the landing end wall."""
    P.TIER['t']='hi' if hi else tier
    if tier=='near' and not hi: P.reset()
    up=Vector((0,0,1))
    # quay either side of the opening
    wall_and_coping(b,[(-3.0,YF),(XL,YF)],tier,hi,caps=(False,True)); wall_and_coping(b,[(SX1,YF),(3.0,YF)],tier,hi,caps=(True,False))
    safety_line(b,[(SX1,YC),(3.0,YC)],tier)
    paving(b,-3.0,XL,YB,1.0); paving(b,SX1,3.0,YB,1.0); paving(b,XL,SX1,YR+0.30,1.0)
    # coping end faces at the opening (overhang strip) + end wall + back wall coping
    for x,sg in ((XL,1),(SX1,-1)):
        q=[Vector((x,YC,ZC)),Vector((x,YF,ZC)),Vector((x,YF,DECK)),Vector((x,YC,DECK))]
        b.quad(q if sg>0 else q[::-1],'stone')
    # end wall x=XL facing +x above the landing (y from wall face to retaining wall)
    rect(b,(XL,YF,ZL),(0,YR-YF,0),(0,0,ZC-ZL),'concrete'); rect(b,(XL,YF,ZC),(0,YR-YF,0),(0,0,DECK-ZC),'stone')
    # retaining (back) wall y=YR facing -y, column by column over the treads
    cols=[(XL,-1.3+0.0,ZL)]+[(SX1-(i+1)*TRD,SX1-i*TRD,_zs(i)) for i in range(NR-1,-1,-1)]
    cols=[(XL,SX1-NR*TRD,ZL)]+[(SX1-(i+1)*TRD,SX1-i*TRD,_zs(i)) for i in range(NR-1,-1,-1)]
    for x0,x1,z in cols:
        if z<ZC-1e-4: rect(b,(x0,YR,z),(x1-x0,0,0),(0,0,ZC-z),'concrete')
        rect(b,(x0,YR,ZC),(x1-x0,0,0),(0,0,DECK-ZC),'stone')
    rect(b,(XL,YR,DECK),(SX1-XL,0,0),(0,0.30,0),'stone')                           # back-wall coping top
    # treads + risers (granite) and the landing slab
    rect(b,(XL,YF,ZL),(SX1-NR*TRD-XL,0,0),(0,YR-YF,0),'stone')                     # landing
    for i in range(NR):
        x1=SX1-i*TRD; x0=x1-TRD; z=_zs(i); zp=DECK if i==0 else _zs(i-1)
        rect(b,(x0,YF,z),(TRD,0,0),(0,YR-YF,0),'stone')                              # tread
        q=[Vector((x1,YF,z)),Vector((x1,YR,z)),Vector((x1,YR,zp)),Vector((x1,YF,zp))]   # riser faces -x
        b.quad(q[::-1],'stone')
        # water-side face of the flight (wall face plane) for this tread column
        _band(b,(x0,YF),(x1,YF),0.0,min(z,ZC),tier)
        if z>ZC: rect(b,(x0,YF,ZC),(TRD,0,0),(0,0,z-ZC),'stone')
        if tier!='mid' and hi:   # nosing groove (anti-slip) in the high-poly
            b.box((x0+0.05,(YF+YR)/2,z),(0.02,YR-YF-0.1,0.003),'stone')
    _band(b,(XL,YF),(SX1-NR*TRD,YF),0.0,ZL,tier)                                  # under the landing
    # fender + bollard on the long side, ring on the landing end wall
    fender_pile(b,2.0,YF,0.0,2.60,hi,tier)
    bollard(b,(2.35,(YC+YB)/2,DECK),hi,tier,text='CROWNADO HARBOR')
    if tier!='mid':
        ring(b,(XL,-0.10,2.25),(1,0,0),hi=hi,tier=tier)
        weep(b,2.7,1.95,hi=hi); weep(b,-2.75,1.95,hi=hi)
        # wall-mounted handrail on the retaining wall: 0.9 m over the nosings, returns into the wall on flanged plates
        hy=YR-0.075; h=0.90
        zt=DECK+h; xt=SX1+0.15; xb=SX1-NR*TRD-0.15; zb=ZL+h
        slope=(DECK-ZL)/(NR*TRD)
        pts=[Vector((SX1+0.30,hy,DECK)),Vector((SX1+0.30,hy,zt)),Vector((SX1,hy,zt)),Vector((SX1-NR*TRD,hy,zb)),Vector((xb,hy,zb)),Vector((xb,YR,zb))]
        sg=16 if hi else 8
        b.sweep(pts,0.021,sg,'galvanized',cap0=False,cap1=False)
        rec('p',tuple(pts[0]),tuple(pts[-1]),0.021,pts)
        b.tube(pts[0],pts[0]+Vector((0,0,0.008)),0.06,0.06,sg,'galvanized',cap0=False,cap1=True)       # deck flange (newel foot)
        b.tube(pts[-1],pts[-1]+Vector((0,-0.008,0)),0.045,0.045,sg,'galvanized',cap0=False,cap1=True)   # wall flange
        if hi or tier=='near':
            for dx in (-0.04,0.04): bolt_head(b,pts[0]+Vector((dx,0,0.008)),(0,0,1),0.006,'galvanized',hi)
        n=4
        for k in range(1,n):   # intermediate brackets: arm from the rail down/back to a wall plate
            t=k/n; p=pts[2].lerp(pts[3],t); pw=Vector((p.x,YR,p.z-0.07)); pr=Vector((p.x,hy,p.z-0.021))
            b.sweep([pr,Vector((p.x,hy,p.z-0.07)),pw],0.008,6,'galvanized',cap0=False,cap1=False)
            b.tube(pw,pw+Vector((0,-0.008,0)),0.035,0.035,sg,'galvanized',cap0=False,cap1=True)
        # guard railing round the opening on the quay top
        guardrail(b,[(SX1,YR+0.15,DECK),(XL-0.15,YR+0.15,DECK),(XL-0.15,YC+0.13,DECK)],hi,tier)
    if tier=='near' and not hi:
        cbox(b,(-2.75,0.125,0),(0.5,1.75,DECK)); cbox(b,(2.05,0.125,0),(1.9,1.75,DECK)); cbox(b,((XL+SX1)/2,(YR+1.0)/2,0),(SX1-XL,1.0-YR,DECK))
        cbox(b,((XL+SX1-NR*TRD)/2,(YF+YR)/2,0),(SX1-NR*TRD-XL,YR-YF,ZL))
        for i in range(NR):
            x1=SX1-i*TRD; cbox(b,(x1-TRD/2,(YF+YR)/2,0),(TRD,YR-YF,_zs(i)))
        cbox(b,(SX1-NR*TRD/2,YR-0.075,ZL),(NR*TRD+0.6,0.06,DECK-ZL+0.9),rz=0.0,rail=True)
def stair_hi(b): stair(b,hi=True)
def stair_mid(b): stair(b,tier='mid')
def stair_far(b):
    ff=-0.85
    rect(b,(-3.0,ff,0),(6.0,0,0),(0,0,ZL),'twf_flat')
    rect(b,(-3.0,ff,ZL),(XL+3.0,0,0),(0,0,DECK-ZL),'twf_flat'); rect(b,(SX1,ff,ZL),(3.0-SX1,0,0),(0,0,DECK-ZL),'twf_flat')
    rect(b,(XL,ff,ZL),(SX1-XL,0,0),(0,YR-ff,DECK-ZL),'twf_flat')                     # stepped flight as one ramp plane
    rect(b,(-3.0,ff,DECK),(XL+3.0,0,0),(0,1.0-ff,0),'twf_flat'); rect(b,(SX1,ff,DECK),(3.0-SX1,0,0),(0,1.0-ff,0),'twf_flat')
    rect(b,(XL,YR,DECK),(SX1-XL,0,0),(0,1.0-YR,0),'twf_flat')
# =============================================================== catalogue
_C=dict(cls='large',conds=['clean'],page='w',dir='props/waterfront/quay',pdir='waterfront_quay',trim=TR,trim_mid=2.0,uv_from_near='face',
        far_flat=True,trim_ao={'big':0.4,'floor_big':0.88,'floor':0.6},dens=128,wx={'water':WL,'algae':0.6,'barnacle':0.5,'salt':0.35,'edge':0.3,'streak':0.2},cage=0.02,ray=0.08)
def _wrap(fn,name):
    def near(b):
        fn(b); P.save_rails(name,pg.K+'/props/waterfront/_rails')
    return near
PROPS=[
 dict(name='quay_straight',near=_wrap(straight,'quay_straight'),high=straight_hi,mid=straight_mid,far=straight_far,max_side=192,**_C),
 dict(name='quay_straight_bollards',near=_wrap(straight_nl,'quay_straight_bollards'),high=straight_nl_hi,mid=straight_nl_mid,far=straight_far,max_side=160,**_C),
 dict(name='quay_corner_out',near=_wrap(corner_out,'quay_corner_out'),high=corner_out_hi,mid=corner_out_mid,far=corner_out_far,max_side=160,**_C),
 dict(name='quay_corner_in',near=_wrap(corner_in,'quay_corner_in'),high=corner_in_hi,mid=corner_in_mid,far=corner_in_far,max_side=160,**_C),
 dict(name='quay_stair',near=_wrap(stair,'quay_stair'),high=stair_hi,mid=stair_mid,far=stair_far,max_side=192,**_C),
]
