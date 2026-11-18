"""Props batch 2b (staging): dingbat apartment pieces + yard. Balcony with clutter (wall mount), dingbat exterior stair run with
top landing (ground), door-entry buzzer / intercom panel (wall mount), T-post clothesline with laundry.
dingbat_stair: the run and the top door landing butt a building wall at y=+0.5 (stair side handrail on wall brackets with
rosettes, landing end guard dies into a cast wall flange at (LX1, 0.5)); place it with the wall face on y=+0.5.
Shape refs: 1950s-60s SoCal dingbat: cantilevered concrete balcony with square-picket steel guard, open-riser steel stair
(C-channel stringers, concrete-filled pan treads) to a second-floor door landing; surface stainless entry panel (12-key,
directory, camera); 2 in galvanized T-post clothesline, 4 lines. Wall plane for wall pieces: y = 0, object at -y."""
import math, random
from mathutils import Vector
import pg
import wf_parts as P
from b2_common import *
V=Vector
def T_(hi,t): P.TIER['t']='hi' if hi else t
def pickets(b,p0,p1,z0,z1,sp,key,hi,w=0.016):
    p0=V(p0); p1=V(p1); L=(p1-p0).length; n=max(1,int(L/sp))
    for k in range(n):
        p=p0+(p1-p0)*((k+0.5)/n)
        b.box((p.x,p.y,z0),(w,w,z1-z0),key,skip=('bottom','top'))
# ===================================================================== balcony with clutter (large, wall)
BW,BD,BT=3.0,1.2,0.15; RH=1.07
def balcony(b,hi=False,t='near'):
    T_(hi,t); mid=t=='mid'
    # cantilever slab with drip groove + stucco-finished edge, steel-trowel top
    b.box((0,-BD/2,0),(BW,BD,BT),'stucco',skip=('back','top'))
    if mid: obox(b,(-BW/2+0.03,-BD+0.04,-0.006),(BW/2-0.03,-BD+0.04,-0.006),0.012,0.012,'stucco',ends=(False,False),skip=('top','s0'))   # drip lip (keeps the near datum)
    b.box((0,-BD/2,BT),(BW-0.0,BD,0.0001),'concrete',skip=('bottom','front','back','left','right'))
    if not mid:
        obox(b,(-BW/2+0.03,-BD+0.04,-0.006),(BW/2-0.03,-BD+0.04,-0.006),0.012,0.012,'stucco',ends=(False,False),skip=('top',))   # drip groove lip
    z=BT
    # guard: posts at the corners + mid front, flat-bar top rail, bottom rail, square pickets at 110 mm
    path=[V((-BW/2+0.03,-0.0,z)),V((-BW/2+0.03,-BD+0.03,z)),V((BW/2-0.03,-BD+0.03,z)),V((BW/2-0.03,-0.0,z))]
    if mid:
        for i in range(3):
            a,c=path[i],path[i+1]; n=(c-a).cross(V((0,0,1))).normalized()
            for o in (1,-1): q(b,[a+n*0.008*o,c+n*0.008*o,c+n*0.008*o+V((0,0,RH)),a+n*0.008*o+V((0,0,RH))],'paint_black',n*o)
    else:
        posts=[path[1],path[2],(path[1]+path[2])/2]
        for p in posts:
            b.box((p.x,p.y,z),(0.04,0.04,RH-0.012),'paint_black',skip=('bottom','top')); P.rec('v',(p.x,p.y,z+0.008),(p.x,p.y,z+RH-0.012),0.02)   # base plate top -> cap rail underside
            b.box((p.x,p.y,z),(0.09,0.09,0.008),'paint_black',skip=('bottom',))
            if hi:
                for k in ((1,1),(-1,-1),(1,-1),(-1,1)): nut4(b,(p.x+k[0]*0.03,p.y+k[1]*0.03,z+0.008),(0,0,1),0.005,'paint_black',hi)
        for i in range(3):
            a,c=path[i],path[i+1]
            obox(b,a+V((0,0,RH-0.006)),c+V((0,0,RH-0.006)),0.05,0.012,'paint_black',ends=(i==0,i==2))     # cap rail
            obox(b,a+V((0,0,0.10)),c+V((0,0,0.10)),0.03,0.012,'paint_black',ends=(i==0,i==2))            # bottom rail
            d_=(c-a).normalized(); ra=a+d_*(0.02 if i>=1 else 0.0); rc=c-d_*(0.02 if i<=1 else 0.0)   # rail ends on the corner-post faces / the wall flange
            P.rec('h',tuple(ra+V((0,0,RH-0.006))),tuple(rc+V((0,0,RH-0.006))),0.02); P.rec('h',tuple(ra+V((0,0,0.10))),tuple(rc+V((0,0,0.10))),0.012)
            pickets(b,a,c,z+0.106,z+RH-0.012,0.11,'paint_black',hi)
        for p in (path[0],path[3]):   # wall flange plates where the side rails meet the wall
            b.box((p.x,-0.003,z+0.06),(0.07,0.006,RH-0.03),'paint_black',skip=('back',))
            if hi:
                for zz in (0.12,RH-0.06): nut4(b,(p.x,-0.006,z+zz),(0,-1,0),0.006,'paint_black',hi)
    # ---- clutter: 2 folding lawn chairs, side table, 3 potted plants, drying rack with laundry, broom
    sg=6 if not hi else 12
    for (cx,cy,rz) in ((-0.95,-0.62,0.35),(-0.20,-0.70,-0.25)):
        ca,sa=math.cos(rz),math.sin(rz); R=lambda x,y,zz: V((cx+x*ca-y*sa,cy+x*sa+y*ca,z+zz))
        if mid:
            b.box((cx,cy,z),(0.55,0.5,0.42),'aluminium',rz=rz,skip=('bottom',)); b.box(tuple(R(0,0.25,0.42)),(0.55,0.04,0.45),'plastic_green',rz=rz,skip=('bottom',)); continue
        for s in (-1,1):
            for p0,p1 in ((R(s*0.27,-0.25,0),R(s*0.27,0.15,0.42)),(R(s*0.27,0.22,0),R(s*0.27,-0.20,0.40)),(R(s*0.27,0.15,0.42),R(s*0.27,0.30,0.88)),
                          (R(s*0.27,-0.25,0.62),R(s*0.27,0.2,0.62))):
                b.tube(p0,p1,0.011,0.011,4 if not hi else 10,'aluminium',cap0=False,cap1=False,sq=not hi)
        for (a,c) in ((R(-0.27,-0.22,0.40),R(0.27,-0.22,0.40)),(R(-0.27,0.28,0.85),R(0.27,0.28,0.85))): b.tube(a,c,0.011,0.011,4 if not hi else 10,'aluminium',cap0=False,cap1=False,sq=not hi)
        # webbing seat + back (both faces)
        for pts in ((R(-0.26,-0.22,0.41),R(0.26,-0.22,0.41),R(0.26,0.15,0.43),R(-0.26,0.15,0.43)),(R(-0.26,0.16,0.44),R(0.26,0.16,0.44),R(0.26,0.29,0.85),R(-0.26,0.29,0.85))):
            for o in (1,-1):
                n=(pts[1]-pts[0]).cross(pts[3]-pts[0]).normalized()*o
                q(b,[p+n*0.002 for p in pts],'plastic_green',n)
        if hi:
            for k in range(7):
                for pts in ((R(-0.26+k*0.075,-0.22,0.412),R(-0.21+k*0.075,-0.22,0.412)),): b.box(tuple((pts[0]+pts[1])/2+V((0,0.19,0.006))),(0.05,0.37,0.003),'paint_white',rz=rz)
    # bistro side table
    tx,ty=-0.58,-0.95
    b.lathe([(0.20,0.55),(0.20,0.57),(0.0,0.575)],8 if not hi else 20,'paint_white',c=(tx,ty,z),cap_top=False) if not mid else b.lathe([(0.2,0.55),(0.0,0.57)],6,'paint_white',c=(tx,ty,z),cap_top=False)
    if not mid:
        b.lathe([(0.0,0.548),(0.20,0.548)],8 if not hi else 20,'paint_white',c=(tx,ty,z),cap_top=False)
        b.tube((tx,ty,z+0.03),(tx,ty,z+0.55),0.018,0.018,6,'paint_white',cap0=False,cap1=False)
        b.lathe([(0.14,0.0),(0.13,0.02),(0.02,0.03)],8,'paint_white',c=(tx,ty,z),cap_top=False)
        b.lathe([(0.04,0.575),(0.035,0.66),(0.045,0.7),(0.0,0.7)],6,'glass_dark',c=(tx+0.06,ty,z),cap_top=False)   # bottle
    # potted plants: terracotta pots, strap-leaf clumps (snake plant / dracaena) and a mounded geranium
    for (px,py,pr,ph,kind) in ((0.55,-0.25,0.17,0.32,'strap'),(1.05,-0.28,0.13,0.25,'mound'),(1.25,-0.95,0.20,0.36,'strap')):
        if mid:
            b.lathe([(pr*0.75,0),(pr,ph),(0.0,ph)],6,'terracotta',c=(px,py,z),cap_top=False)
            b.lathe([(pr*0.9,ph),(pr*0.8,ph+0.35),(0.0,ph+0.55)],5,'paint_green',c=(px,py,z),cap_top=False); continue
        b.lathe([(pr*0.72,0.0),(pr*0.92,ph-0.04),(pr,ph-0.04),(pr,ph),(pr*0.9,ph),(pr*0.88,ph-0.05)],sg+2,'terracotta',c=(px,py,z),cap_top=False)
        b.lathe([(pr*0.88,ph-0.05),(0.0,ph-0.05)],sg+2,'stone',c=(px,py,z),cap_top=False)   # soil
        rr=random.Random(int(px*100))
        if kind=='strap':
            for k in range(9 if not hi else 14):
                a=rr.uniform(0,2*PI); h=rr.uniform(0.45,0.8); lean=rr.uniform(0.05,0.25); w=0.035
                base=V((px+math.cos(a)*0.03,py+math.sin(a)*0.03,z+ph-0.05)); tip=base+V((math.cos(a)*lean,math.sin(a)*lean,h)); mid_=(base+tip)/2+V((math.cos(a)*lean*0.3,math.sin(a)*lean*0.3,0))
                sd=V((-math.sin(a),math.cos(a),0))*w
                for o in (1,-1):
                    f=[base-sd,base+sd,mid_+sd*0.8,mid_-sd*0.8]; n=(f[1]-f[0]).cross(f[3]-f[0]).normalized()*o
                    q(b,[p+n*0.001 for p in f],'paint_green',n)
                    b.faces([mid_-sd*0.8+n*0.001,mid_+sd*0.8+n*0.001,tip+n*0.001] if o>0 else [tip+n*0.001,mid_+sd*0.8+n*0.001,mid_-sd*0.8+n*0.001],[(0,1,2)],'paint_green',[[(0,0),(1,0),(0.5,1)]])
        else:
            b.lathe([(pr*0.85,ph-0.05),(pr*1.25,ph+0.06),(pr*1.15,ph+0.16),(pr*0.6,ph+0.24),(0.0,ph+0.26)],sg,'paint_green',c=(px,py,z),cap_top=False)
            for k in range(5 if not hi else 9):
                a=k*2*PI/5; b.lathe([(0.035,ph+0.24),(0.03,ph+0.28),(0.0,ph+0.29)],5,'paint_red',c=(px+math.cos(a)*pr*0.7,py+math.sin(a)*pr*0.7,z),cap_top=False)
    # gullwing drying rack (white coated wire) with towels + a T-shirt
    rx,ry=0.55,-0.85
    if mid:
        b.box((rx,ry,z),(0.75,0.5,0.95),'paint_white',skip=('bottom',))
    else:
        for s in (-1,1):
            for o in (-1,1):
                b.tube((rx+s*0.36,ry+o*0.25,z),(rx+s*0.36,ry+o*0.05,z+0.95),0.007,0.007,4,'paint_white',cap0=False,cap1=False,sq=not hi)
            b.tube((rx+s*0.36,ry-0.05,z+0.95),(rx+s*0.36,ry+0.05,z+0.95),0.007,0.007,4,'paint_white',cap0=False,cap1=False,sq=not hi)
        rods=[]
        for k in range(4):
            for o in (-1,1):
                f=(k+1)/5; y=ry+o*(0.25-0.20*f); zz=z+0.95*f
                rods.append((y,zz)); b.tube((rx-0.36,y,zz),(rx+0.36,y,zz),0.004,0.004,3 if not hi else 8,'paint_white',cap0=False,cap1=False)
        b.tube((rx-0.36,ry,z+0.95),(rx+0.36,ry,z+0.95),0.006,0.006,4,'paint_white',cap0=False,cap1=False)
        # laundry: towel over the top rail, towel and T-shirt over side rods (two-sided drapes)
        def drape(x0,x1,y,zt,hang,key,dy=0.0):
            for o in (-1,1):
                yy=y+o*0.012
                pts=[V((x0,yy,zt)),V((x1,yy,zt)),V((x1,yy+o*dy,zt-hang)),V((x0,yy+o*dy,zt-hang))]
                for oo in (1,-1):
                    n=V((0,o*oo,0)); q(b,[p+n*0.001 for p in pts],key,n)
        drape(rx-0.30,rx+0.05,ry,z+0.955,0.55,'plastic_blue',0.06)
        drape(rx+0.10,rx+0.32,ry+0.13,z+0.57,0.40,'paint_yellow',0.03)
        drape(rx-0.32,rx-0.02,ry-0.13,z+0.57,0.32,'paint_white',0.02)
    # broom leaning in the corner
    if not mid:
        b.tube((BW/2-0.12,-0.10,z),(BW/2-0.05,-0.05,z+1.25),0.012,0.012,5,'wood_natural',cap0=False,cap1=True)
        b.box((BW/2-0.12,-0.13,z),(0.26,0.06,0.10),'paint_red',rz=0.6)
    if t=='near':
        cbox(b,(0,-BD/2,0),(BW,BD,BT))
        for i in range(3):
            a,c=path[i],path[i+1]; m=(a+c)/2; ang=math.atan2(c.y-a.y,c.x-a.x); cbox(b,(m.x,m.y,z),((c-a).length+0.05,0.06,RH),rz=ang,rail=True)
        cbox(b,(-0.6,-0.7,z),(1.4,0.6,0.9)); cbox(b,(0.8,-0.6,z),(1.2,0.9,1.0))
def balcony_far(b):
    b.box((0,-BD/2,-0.012),(BW,BD,BT+0.012),'twf_flat',skip=('back',))
    for pts,n in ((((-BW/2+0.03,-BD+0.03,BT),(BW/2-0.03,-BD+0.03,BT),(BW/2-0.03,-BD+0.03,BT+RH),(-BW/2+0.03,-BD+0.03,BT+RH)),(0,-1,0)),
                  (((-BW/2+0.03,0,BT),(-BW/2+0.03,-BD+0.03,BT),(-BW/2+0.03,-BD+0.03,BT+RH),(-BW/2+0.03,0,BT+RH)),(-1,0,0)),
                  (((BW/2-0.03,-BD+0.03,BT),(BW/2-0.03,0,BT),(BW/2-0.03,0,BT+RH),(BW/2-0.03,-BD+0.03,BT+RH)),(1,0,0))):
        q(b,pts,'twf_flat',n)
# ===================================================================== dingbat stair run with top door landing (large, ground)
NR=16; RISE=2.88/NR; GO=0.28; SW=0.95; YW=0.5   # wall face at y=+0.5 (stair against the wall)
XB=-2.75; XL=XB+(NR-1)*GO   # landing starts where the last tread would be
def stair(b,hi=False,t='near'):
    T_(hi,t); mid=t=='mid'; ZL=NR*RISE
    y0,y1=-SW/2,SW/2-0.02
    # bottom pad, top landing on two pipe posts, wall ledger
    b.box((XB+0.05,0,0),(0.9,1.1,0.08),'concrete',skip=('bottom',))
    LX0,LX1=XL,XL+1.25
    b.box(((LX0+LX1)/2,(y0+YW)/2,ZL-0.2),(LX1-LX0,YW-y0,0.2),'paint_black',skip=('back',) if True else ())
    q(b,[(LX0,y0,ZL+0.001),(LX1,y0,ZL+0.001),(LX1,YW,ZL+0.001),(LX0,YW,ZL+0.001)],'concrete',(0,0,1))
    for x in (LX0+0.05,LX1-0.05):
        b.tube((x,y0+0.05,0.0 if mid else 0.10),(x,y0+0.05,ZL-0.2),0.045,0.045,6 if mid else (8 if not hi else 16),'paint_black',cap0=False,cap1=False)
        if not mid:
            P.rec('v',(x,y0+0.05,0.112),(x,y0+0.05,ZL-0.2),0.045)   # base plate top -> landing frame
            b.lathe([(0.16,0.0),(0.15,0.10),(0.0,0.10)],8,'concrete',c=(x,y0+0.05,0),cap_top=False)
            b.box((x,y0+0.05,0.10),(0.16,0.16,0.012),'cast_iron',skip=('bottom',))
    # stringers: C-channel along the slope (outer + wall side)
    SA=V((XB+0.045,0,0.20)); SC=V((XL,0,ZL-0.2))   # foot butts against the newel face   # stringer top edge; the foot is raised so the 0.22 m web clears the ground
    stop=lambda x: SA.z+(x-SA.x)*(SC.z-SA.z)/(SC.x-SA.x)
    for y in (y0+0.03,y1-0.01):
        a=V((SA.x,y,SA.z)); c=V((SC.x,y,SC.z))
        d=(c-a).normalized(); up=V((0,0,1)); nrm=d.cross(V((0,1,0))).normalized()*-1
        obox(b,a+nrm*0.11,c+nrm*0.11,0.06,0.22,'paint_black',up=tuple(nrm),ends=(True,False))
    # treads: concrete-filled steel pans, open risers
    for k in range(NR-1):
        x=XB+k*GO; zt=(k+1)*RISE
        b.box((x+GO/2,(y0+y1)/2+0.015,zt-0.04),(GO+0.02,SW-0.08,0.04),'paint_black',skip=('top',) if not mid else ('top','left','right'))
        q(b,[(x-0.01,y0+0.055,zt),(x+GO+0.01,y0+0.055,zt),(x+GO+0.01,y1-0.025,zt),(x-0.01,y1-0.025,zt)],'concrete',(0,0,1))
        if hi:
            b.box((x+0.02,(y0+y1)/2,zt),(0.03,SW-0.1,0.002),'paint_yellow')     # nosing stripe
            for yy in (y0+0.06,y1-0.04): nut4(b,(x+GO/2,yy,zt-0.03),(0,-1 if yy<0 else 1,0),0.006,'cast_iron',hi)
    # guards: stair (outer side) and landing (front + end), square pickets at 110 mm, flat cap rail
    gp=[V((XB+0.02,y0+0.03,0.08)),V((XL,y0+0.03,ZL)),V((LX1-0.02,y0+0.03,ZL)),V((LX1-0.02,YW,ZL))]
    if mid:
        for (a,c,h0) in ((gp[0],gp[1],0.9),(gp[1],gp[2],RH),(gp[2],gp[3],RH)):
            n=(c-a).cross(V((0,0,1))).normalized()
            for o in (1,-1): q(b,[a+n*0.01*o,c+n*0.01*o,c+n*0.01*o+V((0,0,RH)),a+n*0.01*o+V((0,0,0.9 if a.z<0.5 else RH))],'paint_black',n*o)
    else:
        # posts: grounded newel at the foot, two on the outer stringer, landing corners
        nz=lambda x: max(0.08,(x-XB)/GO*RISE)
        for x in (XB+0.02,XB+1.42,XB+2.82):
            z0=stop(x) if x>XB+0.1 else 0.08    # newel on the pad; the others stand on the stringer top
            zt_=(gp[0].z+(x-gp[0].x)*(gp[1].z-gp[0].z)/(gp[1].x-gp[0].x))+0.95-0.007 if x>XB+0.1 else 0.08+0.95+0.007   # up to the cap rail underside (newel: cap above the rail)
            b.box((x,y0+0.03,z0),(0.045,0.045,zt_-z0),'paint_black',skip=('bottom','top')); P.rec('v',(x,y0+0.03,z0+(0.01 if x<=XB+0.1 else 0.0)),(x,y0+0.03,zt_),0.022)
        b.box((XB+0.02,y0+0.03,0.08),(0.12,0.12,0.01),'cast_iron',skip=('bottom',))
        for p in (gp[1],gp[2]):
            b.box((p.x,p.y,ZL),(0.045,0.045,RH),'paint_black',skip=('bottom','top')); P.rec('v',tuple(p),tuple(p+V((0,0,RH))),0.022)
        # sloped rails (stair) then level rails (landing); landing end rail dies into a wall flange
        sl=[(gp[0]+V((0,0,0.95)),gp[1]+V((0,0,0.95))),(gp[0]+V((0,0,0.10)),gp[1]+V((0,0,0.10)))]
        for a,c in sl:
            d_=(c-a).normalized()*0.0225; obox(b,a+d_,c-d_,0.045,0.014,'paint_black',ends=(True,True)); P.rec('h',tuple(a+d_),tuple(c-d_),0.02)   # rails stop at the post faces
        n_=int((gp[1]-gp[0]).length/0.13)
        for k in range(n_):
            f=(k+0.5)/n_; p=gp[0]+(gp[1]-gp[0])*f
            b.box((p.x,p.y,p.z+0.107),(0.016,0.016,0.836),'paint_black',skip=('bottom','top'))
        for i,(a,c) in enumerate(((gp[1],gp[2]),(gp[2],gp[3]))):
            for zz in (RH-0.007,0.10):
                obox(b,a+V((0,0,zz)),c+V((0,0,zz)),0.045,0.014,'paint_black',ends=(i==0 and False,i==1)); d_=(c-a).normalized()*0.0225
                P.rec('h',tuple(a+V((0,0,zz))+d_),tuple(c+V((0,0,zz))-(d_ if i==0 else V((0,0,0)))),0.02)   # post faces; the end rail dies into the wall flange
            pickets(b,a,c,ZL+0.107,ZL+RH-0.014,0.11,'paint_black',hi)
        b.box((gp[3].x,YW-0.003,ZL+0.06),(0.07,0.006,RH-0.03),'cast_iron',skip=('back',))   # wall flange
        # wall-side handrail on brackets, returns to the wall at both ends
        hp=[V((XB+0.30,YW-0.075,0.90+0.30/GO*RISE)),V((XL-0.30,YW-0.075,0.90+(XL-0.30-XB)/GO*RISE))]
        b.tube(hp[0],hp[1],0.019,0.019,6 if not hi else 16,'paint_black',cap0=False,cap1=False)
        for p in hp:
            b.tube(p,V((p.x,YW,p.z)),0.019,0.019,6 if not hi else 16,'paint_black',cap0=False,cap1=False)
            b.box((p.x,YW-0.003,p.z-0.035),(0.07,0.006,0.07),'cast_iron',skip=('back',))   # wall rosette plate (return end)
            if hi:
                for o in (-1,1): nut4(b,(p.x+o*0.024,YW-0.006,p.z),(0,-1,0),0.004,'cast_iron',hi)
        P.rec('p',(hp[0].x,YW,hp[0].z),(hp[1].x,YW,hp[1].z),0.019,pts=[(hp[0].x,YW,hp[0].z),tuple(hp[0]),tuple(hp[1]),(hp[1].x,YW,hp[1].z)])
        for f in (0.33,0.66):
            p=hp[0]+(hp[1]-hp[0])*f; b.box((p.x,YW-0.04,p.z-0.06),(0.012,0.08,0.012),'cast_iron',skip=()); b.box((p.x,YW-0.003,p.z-0.06),(0.06,0.006,0.06),'cast_iron',skip=('back',))
        # under-landing details: door mat on the landing, porch light? (building), unit number plaque on the post
        b.box((LX0+0.62,YW-0.28,ZL),(0.7,0.4,0.012),'rubber_black',skip=('bottom',))
        if hi: text(b,'2B',0.06,(LX1-0.05-0.0,y0+0.05-0.046,ZL-0.6),(1,0,0),'brass',0.003)
    if t=='near':
        for k in range(4):
            a=XB+k*(XL-XB)/4; c=XB+(k+1)*(XL-XB)/4; cbox(b,((a+c)/2,0,0),(c-a,SW,(k+0.5)*(ZL/4)))
        cbox(b,((LX0+LX1)/2,(y0+YW)/2,ZL-0.2),(LX1-LX0,YW-y0,0.2)); ccyl(b,(LX0+0.05,y0+0.05,0),0.05,ZL-0.2,rail=True); ccyl(b,(LX1-0.05,y0+0.05,0),0.05,ZL-0.2,rail=True)
        cbox(b,((XB+XL)/2,y0+0.03,0),(XL-XB,0.06,ZL+0.95),rail=True); cbox(b,((LX0+LX1)/2,y0+0.03,ZL),(LX1-LX0,0.06,RH),rail=True); cbox(b,(LX1-0.02,(y0+YW)/2,ZL),(0.06,YW-y0,RH),rail=True)
def stair_far(b):
    ZL=NR*RISE; y0=-SW/2; LX1=XL+1.25
    q(b,[(XB-0.05,0,0),(XL,0,ZL-0.25),(XL,0,ZL+0.95),(XB-0.05,0,0.95)],'twf_flat',(0,-1,0))
    q(b,[(XL,0,ZL-0.2),(LX1,0,ZL-0.2),(LX1,0,ZL+RH),(XL,0,ZL+RH)],'twf_flat',(0,-1,0))
    for x in (XL+0.05,LX1-0.05): q(b,[(x-0.045,0,0),(x+0.045,0,0),(x+0.045,0,ZL-0.2),(x-0.045,0,ZL-0.2)],'twf_flat',(0,-1,0))
    q(b,[(XB-0.05,y0,0.2),(XL,y0,ZL),(XL,YW,ZL),(XB-0.05,YW,0.2)],'twf_flat',(0,0,1))
    q(b,[(XL,y0,ZL+0.01),(LX1,y0,ZL+0.01),(LX1,YW,ZL+0.01),(XL,YW,ZL+0.01)],'twf_flat',(0,0,1))
    q(b,[(LX1,y0,ZL-0.2),(LX1,YW,ZL-0.2),(LX1,YW,ZL+RH),(LX1,y0,ZL+RH)],'twf_flat',(1,0,0))
# ===================================================================== buzzer / intercom panel (tiny, wall)
def buzzer(b,hi=False,t='near'):
    T_(hi,t); W,H,D=0.22,0.40,0.035; c=0.008
    # surface box with chamfered front edges
    yf=-D
    b.box((0,-(D-c)/2,0),(W,D-c,H),'stainless',skip=('back','front','bottom') if False else ('back','front'))
    pts=lambda y,i: [V((-W/2+i,y,i)),V((W/2-i,y,i)),V((W/2-i,y,H-i)),V((-W/2+i,y,H-i))]
    A=pts(-(D-c),0.0); B_=pts(-D,c)
    for i in range(4): q(b,[A[i],A[(i+1)%4],B_[(i+1)%4],B_[i]],'stainless',[(0,-0.5,-1),(1,-0.5,0),(0,-0.5,1),(-1,-0.5,0)][i])
    q(b,B_,'stainless',(0,-1,0))
    # directory window, speaker grille, camera bubble, keypad 3x4, call button, conduit into the wall below
    b.box((0,yf-0.004,0.27),(0.16,0.004,0.09),'glass_dark',skip=('back',))
    b.box((0,yf-0.002,0.215),(0.12,0.002,0.03),'aluminium',skip=('back',))
    b.lathe([(0.016,0.0),(0.012,0.008),(0.0,0.012)],6 if not hi else 16,'glass_dark',c=(0,0,0),cap_top=False) if False else b.tube((0.07,yf,0.35),(0.07,yf-0.012,0.35),0.014,0.008,6 if not hi else 16,'glass_dark',cap0=False,cap1=True)
    for i in range(3):
        for j in range(4):
            b.box((-0.045+i*0.045,yf-0.004,0.06+j*0.035),(0.032,0.004,0.024),'stainless',skip=('back','bottom','left','right') if not hi else ('back',))
    b.tube((0.0,yf,0.035),(0.0,yf-0.006,0.035),0.012,0.012,8 if not hi else 20,'brass',cap0=False,cap1=True) if False else None
    b.tube((0.07,yf,0.06),(0.07,yf-0.006,0.06),0.014,0.014,8 if not hi else 20,'brass',cap0=False,cap1=True)
    # wall mounting: stainless back flange (flush to the wall), rain hood, surface conduit with straps down to an LB that
    # turns into the wall (the panel snaps on any apartment wall: wall plane y=0, panel bottom at 1.15 m)
    b.box((0,-0.003,-0.035),(W+0.06,0.006,H+0.07),'stainless',skip=('back',))
    b.box((0,-0.033,H+0.035),(W+0.05,0.06,0.006),'stainless',skip=(),rx=-0.15)
    for s_ in (-1,1): b.faces([V((s_*(W/2+0.02),-0.006,H+0.035)),V((s_*(W/2+0.02),-0.062,H+0.04)),V((s_*(W/2+0.02),-0.006,H-0.03))],[(0,1,2) if s_>0 else (2,1,0)],'stainless',[[(0,0),(1,0),(0,1)]])
    b.tube((0,-0.014,-0.035),(0,-0.014,-0.27),0.012,0.012,6 if not hi else 16,'galvanized',cap0=False,cap1=False)
    b.box((0,-0.018,-0.33),(0.05,0.036,0.07),'galvanized',skip=('back',))                      # LB body into the wall
    b.box((0,-0.0365,-0.33),(0.04,0.003,0.06),'galvanized',skip=('back',))                     # LB cover
    for zz in (-0.12,-0.22): b.box((0,-0.014,zz),(0.06,0.03,0.012),'galvanized',skip=('back',))   # one-hole straps
    if hi:
        for zz in (-0.305,-0.355): b.tube((0,-0.038,zz),(0,-0.040,zz),0.004,0.004,8,'stainless',cap1=True)
        for zz in (-0.12,-0.22): b.tube((0.022,-0.006,zz),(0.022,-0.008,zz),0.004,0.004,8,'stainless',cap1=True)
        for (x,z) in ((-W/2-0.015,-0.02),(W/2+0.015,-0.02),(-W/2-0.015,H+0.0),(W/2+0.015,H+0.0)): b.tube((x,-0.006,z),(x,-0.008,z),0.005,0.005,8,'stainless',cap1=True)
    if hi:
        for j in range(5):
            frontal_text(b,['1  GARCIA','2  NGUYEN','3  O\'BRIEN','4  PATEL','5  MGR'][j],0.012,(-0.02,0,0.305-j*0.016),'plastic_white',yf-0.0042,depth=0.0005)
        keys=['1','2','3','4','5','6','7','8','9','*','0','#']
        for i in range(3):
            for j in range(4): frontal_text(b,keys[(3-j)*3+i],0.014,(-0.045+i*0.045,0,0.072+j*0.035),'paint_black',yf-0.0045,depth=0.0005)
        for i in range(6):
            for j in range(3): b.box((-0.04+i*0.016,yf-0.0022,0.205+j*0.01),(0.005,0.001,0.005),'rubber_black',skip=('back',))
        for (x,z) in ((-0.095,0.015),(0.095,0.015),(-0.095,0.385),(0.095,0.385)): b.tube((x,yf,z),(x,yf-0.002,z),0.004,0.004,8,'stainless',cap1=True)
        frontal_text(b,'CALL',0.012,(0.07,0,0.085),'paint_black',yf-0.0005,depth=0.0004)
    if t=='near': cbox(b,(0,-0.03,-0.33),(W+0.06,0.06,H+0.41))
# ===================================================================== clothesline (medium, near)
PX=2.5; ARM=0.6; LINES=(-0.45,-0.15,0.15,0.45); PH=2.0
def clothesline(b,hi=False,t='near'):
    T_(hi,t); sg=8 if not hi else 16
    for s in (-1,1):
        x=s*PX
        b.lathe([(0.10,0.0),(0.09,0.04),(0.035,0.05)],8,'concrete',c=(x,0,0),cap_top=False)
        b.tube((x,0,0.04),(x,0,PH),0.030,0.030,sg,'galvanized',cap0=False,cap1=False); P.rec('v',(x,0,0.04),(x,0,PH),0.03)
        b.tube((x,-ARM,PH+0.03),(x,ARM,PH+0.03),0.024,0.024,sg,'galvanized',cap0=True,cap1=True)
        b.box((x,0,PH-0.04),(0.08,0.10,0.10),'galvanized',skip=())                        # tee fitting
        for o in (-1,1): b.tube((x,0,PH-0.35),(x,o*0.38,PH+0.01),0.014,0.014,6,'galvanized',cap0=False,cap1=False)   # braces
        for y in LINES:
            b.box((x,y,PH+0.005),(0.02,0.01,0.03),'galvanized',skip=('top',))               # line eye
            if s>0: b.box((x-0.08,y,PH+0.0),(0.12,0.012,0.012),'stainless',skip=())          # turnbuckle
    # lines with sag (4 segments each)
    zL=PH-0.0; sag=0.07
    def lz(x): return zL-sag*(1-(x/PX)**2)
    for y in LINES:
        xs=[-PX+0.02+k*(2*PX-0.04)/4 for k in range(5)]
        for i in range(4): b.tube((xs[i],y,lz(xs[i])),(xs[i+1],y,lz(xs[i+1])),0.0028,0.0028,3 if not hi else 8,'plastic_white',cap0=False,cap1=False)
    # laundry (two-faced drapes, sag-following top edge) + clothespins
    rr=random.Random(3)
    items=[(-1.9,-0.85,LINES[1],0.95,'paint_white','sheet'),(-0.55,0.0,LINES[2],0.55,'plastic_blue','towel'),(0.15,0.65,LINES[2],0.48,'paint_red','towel'),
           (1.0,1.55,LINES[0],0.62,'paint_yellow','shirt'),(-0.4,0.05,LINES[3],0.75,'paint_navy','jeans'),(1.4,1.7,LINES[3],0.25,'paint_white','socks')]
    for (x0,x1,y,h,key,kind) in items:
        n=3 if kind=='sheet' else 2
        xs=[x0+(x1-x0)*k/n for k in range(n+1)]
        for i in range(n):
            a,c=xs[i],xs[i+1]; za,zc=lz(a)-0.005,lz(c)-0.005
            ha=h*(0.96 if i%2 else 1.0); hc=h*(1.0 if i%2 else 0.96)
            if kind=='shirt': ha=hc=h
            if kind=='jeans': ha=hc=h
            sw=0.02 if i%2 else -0.02
            pts=[V((a,y,za)),V((c,y,zc)),V((c,y+sw,zc-hc)),V((a,y-sw,za-ha))]
            for o in (1,-1):
                nn=(pts[1]-pts[0]).cross(pts[3]-pts[0]).normalized()*o
                q(b,[p+nn*0.0015 for p in pts],key,nn)
        if kind=='shirt':   # sleeves
            for sx,xa in ((-1,x0),(1,x1)):
                pts=[V((xa,y,lz(xa)-0.02)),V((xa+sx*0.18,y,lz(xa)-0.10)),V((xa+sx*0.14,y,lz(xa)-0.22)),V((xa,y,lz(xa)-0.17))]
                for o in (1,-1):
                    nn=V((0,o,0)); q(b,[p+nn*0.0015 for p in pts],key,nn)
        if kind=='jeans':   # leg split: dark gap quad
            m=(x0+x1)/2; q(b,[(m-0.01,y-0.004,lz(m)-0.30),(m+0.01,y-0.004,lz(m)-0.30),(m+0.01,y-0.004,lz(m)-h),(m-0.01,y-0.004,lz(m)-h)],'rubber_black',(0,-1,0)) if False else None
        for xp in (x0+0.03,x1-0.03):   # pegs
            b.box((xp,y,lz(xp)-0.045),(0.012,0.016,0.075),'wood_natural',skip=())
    # prop pole holding up the middle of the sheet line, laundry basket
    b.tube((-1.35,LINES[1]-0.25,0.0),(-1.35,LINES[1],lz(-1.35)+0.02),0.02,0.02,5 if not hi else 10,'wood_natural',cap0=False,cap1=True)
    b.lathe([(0.20,0.0),(0.24,0.26),(0.25,0.27),(0.235,0.27),(0.19,0.012)],8 if not hi else 24,'plastic_blue',c=(0.6,-0.9,0),cap_top=False)
    b.lathe([(0.19,0.012),(0.0,0.012)],8,'plastic_blue',c=(0.6,-0.9,0),cap_top=False)
    b.lathe([(0.20,0.16),(0.12,0.22),(0.0,0.24)],6,'paint_white',c=(0.6,-0.9,0),cap_top=False)   # folded laundry
    if hi:
        for k in range(16):
            a=k*2*PI/16; b.box((0.6+math.cos(a)*0.235,-0.9+math.sin(a)*0.235,0.08),(0.05,0.012,0.1),'rubber_black',rz=a+PI/2)   # basket slots
    if t=='near':
        for s in (-1,1): ccyl(b,(s*PX,0,0),0.04,PH,rail=True); cbox(b,(s*PX,0,PH-0.02),(0.06,2*ARM,0.08),rail=True)
        cbox(b,(0.6,-0.9,0),(0.5,0.5,0.27))
# ===================================================================== registry
_D=lambda **k: dict(BASE,**k)
PROPS=[
 _D(name='balcony_clutter',cls='large',dir='props/batch2/residential',near=wrap(balcony,'balcony_clutter'),high=lambda b: balcony(b,hi=True),mid=lambda b: balcony(b,t='mid'),far=balcony_far,
    mount='wall',wall_y=0.0,max_side=192,dens=110,trim={'paint_black':BLACKL,'concrete':CONC,'aluminium':ALU}),
 _D(name='dingbat_stair',cls='large',dir='props/batch2/residential',near=wrap(stair,'dingbat_stair'),high=lambda b: stair(b,hi=True),mid=lambda b: stair(b,t='mid'),far=stair_far,
    double_far=True,max_side=176,dens=110,trim={'paint_black':BLACKL,'concrete':CONC}),
 _D(name='buzzer_panel',cls='tiny',dir='props/batch2/residential',near=wrap(buzzer,'buzzer_panel'),high=lambda b: buzzer(b,hi=True),mount='wall',wall_y=0.0,max_side=64,dens=256,trim={'galvanized':GALV}),
 _D(name='clothesline',cls='medium',dir='props/batch2/residential',near=wrap(clothesline,'clothesline'),high=lambda b: clothesline(b,hi=True),max_side=128,dens=110,trim={'galvanized':GALV}),
]
# ===================================================================== mid + far for buzzer and clothesline (every piece ships 3 tiers)
F='twf_flat'
def buzzer_mid(b):
    b.box((0,-0.003,-0.035),(0.28,0.006,0.47),'stainless',skip=('back',))
    b.box((0,-0.0175,0),(0.22,0.035,0.40),'stainless',skip=('back',))
    b.box((0,-0.033,0.435),(0.27,0.06,0.006),'stainless',skip=('back',))
    b.box((0,-0.014,-0.33),(0.05,0.03,0.295),'galvanized',skip=('back','top'))   # conduit + LB into the wall
def buzzer_far(b):
    b.box((0,-0.03,-0.035),(0.28,0.06,0.48),F,skip=('back',))
    q(b,[(-0.025,-0.032,-0.33),(0.025,-0.032,-0.33),(0.025,-0.032,-0.035),(-0.025,-0.032,-0.035)],F,(0,-1,0))
def cl_mid(b):
    P.TIER['t']='mid'
    for s in (-1,1):
        x=s*PX
        b.tube((x,0,0.0),(x,0,PH),0.03,0.03,4,'galvanized',cap0=False,cap1=False)
        b.box((x,0,PH-0.01),(0.05,2*ARM,0.05),'galvanized',skip=('bottom',) if False else ())
    for y in LINES:
        for o in (1,-1): q(b,[(-PX,y-0.01,PH-0.02),(PX,y-0.01,PH-0.02),(PX,y+0.01,PH-0.02),(-PX,y+0.01,PH-0.02)],'plastic_white',(0,0,o))
    for (x0,x1,y,h,key) in ((-1.9,-0.85,LINES[1],0.95,'paint_white'),(-0.55,0.0,LINES[2],0.55,'plastic_blue'),(0.15,0.65,LINES[2],0.48,'paint_red'),
                            (1.0,1.55,LINES[0],0.62,'paint_yellow'),(-0.4,0.05,LINES[3],0.75,'paint_navy'),(1.4,1.7,LINES[3],0.25,'paint_white')):
        z=PH-0.07*(1-(((x0+x1)/2)/PX)**2)-0.005
        for o in (1,-1): q(b,[(x0,y,z),(x1,y,z),(x1,y,z-h),(x0,y,z-h)],key,(0,o,0))
    b.lathe([(0.20,0.0),(0.25,0.27),(0.0,0.27)],6,'plastic_blue',c=(0.6,-0.9,0),cap_top=False)
def _tilt(b,p0,p1,w,key):
    """45-degree strip along p0->p1 (thin members: shows in both the front and the top view)"""
    p0=V(p0); p1=V(p1); d=(p1-p0).normalized(); n=d.cross(V((0,0,1))).normalized(); u=(n+V((0,0,1))).normalized()*(w*0.7071)
    q(b,[p0-u,p1-u,p1+u,p0+u],key,tuple(d.cross(u)))
def cl_far(b):
    # posts (front), the 4 lines as flat ribbons (top view), two laundry cards, the basket
    for s in (-1,1):
        x=s*PX; q(b,[(x-0.04,0,0),(x+0.04,0,0),(x+0.04,0,PH+0.05),(x-0.04,0,PH+0.05)],F,(0,-1,0))
    for y in LINES: q(b,[(-PX,y-0.012,PH-0.02),(PX,y-0.012,PH-0.02),(PX,y+0.012,PH-0.02),(-PX,y+0.012,PH-0.02)],F,(0,0,1))
    for (x0,x1,h) in ((-1.9,-0.85,0.98),(-0.55,0.05,0.80),(0.05,0.65,0.60),(1.0,1.7,0.66)):   # laundry cards: sheet, jeans, towels, shirt + socks
        q(b,[(x0,LINES[1],PH-0.03),(x1,LINES[1],PH-0.03),(x1,LINES[1],PH-h),(x0,LINES[1],PH-h)],F,(0,-1,0))
for d in PROPS:
    if d['name']=='buzzer_panel': d.update(mid=buzzer_mid,far=buzzer_far)
    if d['name']=='clothesline': d.update(mid=cl_mid,far=cl_far,double_far=True)
_SIDE={'balcony_clutter':192,'dingbat_stair':96,'buzzer_panel':64,'clothesline':128}
for d in PROPS: d['max_side']=_SIDE[d['name']]
for d in PROPS:
    pass   # (stair: steel tiles tw_paint; only the hardware bakes, no squash needed)
fin(PROPS)   # stair: plain steel tiles tw_paint (black tint); plates, brackets, rosettes, bolts bake as cast_iron
