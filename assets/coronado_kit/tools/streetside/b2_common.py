"""Props batch 2 (staging): shared helpers. Builder space: metres, Z up, front = -Y; exports glTF Y-up, front +Z.
Page W props (waterfront page; page B is full): large plain surfaces tile page-W trims (tw_*);
the unique bake holds lettering, hardware, castings and edges. Far tiers: flat swatch twf_flat, vertex-painted from the mid."""
import math
from mathutils import Vector
import pg
import wf_parts as P
from wf_parts import PI, rect, seg_n, cbox, ccyl, rec
def q(b,pts,key,out):
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
    for k,(pts,n) in F.items():
        if k not in skip: q(b,pts,key,n)
    if ends[0]: q(b,[C(p0,-1,-1),C(p0,1,-1),C(p0,1,1),C(p0,-1,1)],key,-d)
    if ends[1]: q(b,[C(p1,-1,-1),C(p1,1,-1),C(p1,1,1),C(p1,-1,1)],key,d)
def nut4(b,c,axis,r,key='galvanized',hi=False):
    """bolt head: hi = washer + hex nut + thread stub; low = 4-sided nut"""
    c=Vector(c); a=Vector(axis).normalized()
    if hi: P.bolt_head(b,c,a,r,key,True)
    else: b.tube(c,c+a*r*0.8,r,r*0.95,4,key,cap0=False,cap1=True,smooth=False)
def text(b,s,size,o,xd,key,depth=0.0012,yd=(0,0,1)):
    pg.add_text(b,s,size,o,xd,yd,depth,key)
def frontal_text(b,s,size,c,key,face_y,back=False,depth=0.0012):
    """lettering on a face at y=face_y facing -Y (back=True: facing +Y, reading correctly from behind)"""
    x,_,z=c
    if not back: text(b,s,size,(x,face_y-depth/2,z),(1,0,0),key,depth)
    else: text(b,s,size,(-x if False else x,face_y+depth/2,z),(-1,0,0),key,depth)
# page W trims (0.875 m tile pitch). Painted keys use tw_paint (white enamel photo trim) with a per-key trim_tint.
GALV=('tw_galv',(0.875,0.875),2.0); GALVL=('tw_galv',(0.875,0.875),6.0); CONC=('tw_conc_top',(0.875,0.875)); ALU=('tw_galv',(0.875,0.875),2.0)
BLACK=('tw_paint',(0.875,0.875),2.0); BLACKL=('tw_paint',(0.875,0.875),6.0); PAINT=('tw_paint',(0.875,0.875),2.0)
WOOD=('tw_teak',(0.875,0.875),2.0); FAB=('tw_canvas',(0.875,0.875)); RUBBER=('tw_rubber',(0.875,0.875),2.0)
TT={'stucco':(0.98,0.93,0.82),'paint_black':(0.075,0.075,0.08),'paint_white':(1,1,1),'paint_bronze':(0.30,0.22,0.15),'paint_red':(0.62,0.08,0.06)}
BASE=dict(conds=['clean'],page='w',dens=110,uv_from_near='face',trim_mid=2.0,far_flat=True,cage=0.02,ray=0.06)
DEFTRIM={'galvanized':GALV,'paint_black':BLACK,'rubber_black':RUBBER,'concrete':CONC}
def fin(defs,keep=()):
    """default page-W trims for plain keys (unless the piece keeps that key baked: keep=((name,key),..)), plus trim_tint for tw_paint keys"""
    for d in defs:
        tr=dict(DEFTRIM); tr.update(d.get('trim',{}))
        for n,k in keep:
            if d['name']==n: tr.pop(k,None)
        d['trim']=tr
        tt={k:TT[k] for k,v in tr.items() if v[0]=='tw_paint' and k in TT}
        if tt: d['trim_tint']=dict(tt,**d.get('trim_tint',{}))
    return defs
def boxes(b,L,key=None):
    """mid/far helper: list of (key,(cx,cy,z0),(w,d,h)) boxes without bottoms"""
    for k,c,s in L: b.box(c,s,key or k,skip=('bottom',))
def wrap(fn,name):
    def near(b):
        P.reset(); P.TIER['t']='near'; fn(b); P.save_rails(name,pg.K+'/props/batch2/_rails')
    return near
def tier(t):
    P.TIER['t']=t
def FLAT(): return 'twf_flat'
