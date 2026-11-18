"""Props batch 2a (staging): shop pylon sign, drive-thru menu board, bus-stop pole sign, motel soda + snack vending machines,
ice merchandiser chest, parking wheel stops (precast concrete, recycled rubber), shopping cart, cart corral.
Shape refs (real types, generic artwork): strip-mall multi-tenant pylon with stucco legs and clay-tile cap (Orange Ave style),
QSR outdoor 3-panel digital/backlit menu board + order-point speaker post, MTS-style bus-stop flag on 2-3/8 in galvanized pole,
Dixie-Narco style soda venders, glass-front spiral snack vender, outdoor ice merchandiser (Leer style), 6 ft precast wheel stop,
Unarco-style wire cart, galvanized-pipe cart corral. All names/brands are fictional (Crownado)."""
import math, random
from mathutils import Vector
import pg
import wf_parts as P
from b2_common import *
V=Vector
def T_(hi,t): P.TIER['t']='hi' if hi else t
# ===================================================================== pylon sign (large)
PW,LX,LW,LD,LH=2.8,1.175,0.45,0.70,5.6
CAB=[1.15+i*0.98 for i in range(4)]; CH=0.90; CW=1.86; CD=0.30
TEN=[('CROWN DRUG','paint_red','plastic_white'),('SEASIDE NAILS','paint_navy','plastic_white'),('TACO SURF','plastic_orange','paint_yellow'),('ISLAND CLEANERS','paint_green','plastic_white')]
def pylon_sign(b,hi=False,t='near'):
    T_(hi,t); mid=t=='mid'
    # planter curb + soil (stucco pylon stands in a raised planter)
    for (cx,cy,w,d) in ((0,-0.75,3.6,0.15),(0,0.75,3.6,0.15),(-1.725,0,0.15,1.35),(1.725,0,0.15,1.35)):
        b.box((cx,cy,0),(w,d,0.30),'concrete',skip=('bottom',))
    b.box((0,0,0),(3.3,1.35,0.24),'stone',skip=('bottom','front','back','left','right'))   # mulch top
    for s in (-1,1):   # stucco legs on plinths, cap band
        x=s*LX
        b.box((x,0,0.24),(LW+0.10,LD+0.10,0.36),'stucco',skip=('bottom',))
        b.box((x,0,0.60),(LW,LD,LH-0.60),'stucco',skip=('bottom','top'))
        if not mid:
            for zz in (2.2,3.9): b.box((x,0,zz),(LW+0.012,LD+0.012,0.02),'stucco',skip=('bottom','top'))   # control-joint reveals
    b.box((0,0,0.24),(2*LX-LW,0.40,0.86),'stucco',skip=('bottom','left','right'))   # base wall with address
    for i,z0 in enumerate(CAB):   # tenant cabinets: bronze aluminium body, white lit faces both sides, retainer frames
        b.box((0,0,z0),(CW,CD,CH),'paint_bronze',skip=('left','right','front','back') if not mid else ('left','right'))
        if not mid:
            for yf,o in ((-CD/2,-1),(CD/2,1)):
                q(b,[(-CW/2+0.06,yf,z0+0.06),(CW/2-0.06,yf,z0+0.06),(CW/2-0.06,yf,z0+CH-0.06),(-CW/2+0.06,yf,z0+CH-0.06)],'plastic_white',(0,o,0))
                y2=yf+o*0.025
                for (a,c,w,h) in (((-CW/2,yf,z0),(CW/2,yf,z0),0,0),):
                    pass
                # retainer: 4 lips (bottom, top, left, right) proud of the face
                obox(b,(-CW/2,yf+o*0.0125,z0+0.03),(CW/2,yf+o*0.0125,z0+0.03),0.025,0.06,'paint_bronze',up=(0,0,1),ends=(False,False),skip=('s0',) if o>0 else ('s1',))
                obox(b,(-CW/2,yf+o*0.0125,z0+CH-0.03),(CW/2,yf+o*0.0125,z0+CH-0.03),0.025,0.06,'paint_bronze',ends=(False,False),skip=('s0',) if o>0 else ('s1',))
                for sx in (-1,1):
                    obox(b,(sx*(CW/2-0.03),yf+o*0.0125,z0+0.06),(sx*(CW/2-0.03),yf+o*0.0125,z0+CH-0.06),0.06,0.025,'paint_bronze',up=(0,-o,0),ends=(False,False),skip=('bottom',))
                if hi:
                    nm,fg,bg=TEN[i]
                    b.box((0,yf+o*0.0006,z0+0.07),(CW-0.14,0.001,CH-0.14),bg,skip=('bottom','top','left','right'))
                    b.box((-0.62,yf+o*0.0012,z0+0.2),(0.42,0.001,0.5),fg,skip=('bottom','top','left','right'))   # logo block
                    frontal_text(b,nm,0.20,(0.22,0,z0+CH/2),fg,yf+o*0.0012,back=o>0,depth=0.0015)
                    for k in range(8): nut4(b,(-CW/2+0.1+k*0.24,yf+o*0.025,z0+0.03),(0,o,0),0.006,'stainless',hi)
        else:
            pass
    # header cabinet (stucco-clad) with recessed lit name panel both sides
    HZ=LH; HW_,HD,HH=3.0,0.62,1.4
    b.box((0,0,HZ),(HW_,HD,HH),'stucco',skip=('front','back') if not mid else ())
    if not mid:
        for o in (-1,1):
            yf=o*HD/2; yi=o*(HD/2-0.05)
            x0,x1,z0,z1=-HW_/2+0.15,HW_/2-0.15,HZ+0.18,HZ+HH-0.22
            # frame around the recess (stucco) and the recess reveal
            for pts in (((-HW_/2,yf,HZ),(HW_/2,yf,HZ),(HW_/2,yf,z0),(-HW_/2,yf,z0)),((-HW_/2,yf,z1),(HW_/2,yf,z1),(HW_/2,yf,HZ+HH),(-HW_/2,yf,HZ+HH)),
                        ((-HW_/2,yf,z0),(x0,yf,z0),(x0,yf,z1),(-HW_/2,yf,z1)),((x1,yf,z0),(HW_/2,yf,z0),(HW_/2,yf,z1),(x1,yf,z1))):
                q(b,pts,'stucco',(0,o,0))
            for pts,n in ((((x0,yf,z0),(x1,yf,z0),(x1,yi,z0),(x0,yi,z0)),(0,0,1)),(((x0,yf,z1),(x1,yf,z1),(x1,yi,z1),(x0,yi,z1)),(0,0,-1)),
                          (((x0,yf,z0),(x0,yi,z0),(x0,yi,z1),(x0,yf,z1)),(1,0,0)),(((x1,yf,z0),(x1,yi,z0),(x1,yi,z1),(x1,yf,z1)),(-1,0,0))):
                q(b,pts,'stucco',n)
            q(b,[(x0,yi,z0),(x1,yi,z0),(x1,yi,z1),(x0,yi,z1)],'plastic_white',(0,o,0))
            if hi:
                frontal_text(b,'CROWN PLAZA',0.42,(0,0,HZ+0.80),'paint_navy',yi+o*0.0008,back=o>0,depth=0.003)
                frontal_text(b,'SHOPS  ·  DINING  ·  SERVICES',0.13,(0,0,HZ+0.37),'paint_red',yi+o*0.0008,back=o>0,depth=0.0015)
                frontal_text(b,'1021',0.16,(0,0,0.70),'paint_bronze',o*0.2+o*0.0006,back=o>0,depth=0.004) if True else None
    # cornice band + clay-tile hip cap
    cz=HZ+HH
    b.box((0,0,cz),(HW_+0.16,HD+0.16,0.10),'stucco',skip=('bottom',) if mid else ())
    rz=cz+0.10; ov=0.14; X0,X1,Y0,Y1=-HW_/2-ov,HW_/2+ov,-HD/2-ov,HD/2+ov; RH=0.42
    ridge=[(X0+(Y1-Y0)/2,0,rz+RH),(X1-(Y1-Y0)/2,0,rz+RH)]
    q(b,[(X0,Y0,rz),(X1,Y0,rz),ridge[1],ridge[0]],'terracotta',(0,-1,1)); q(b,[(X1,Y1,rz),(X0,Y1,rz),ridge[0],ridge[1]],'terracotta',(0,1,1))
    b.faces([V((X0,Y0,rz)),V(ridge[0]),V((X0,Y1,rz))],[(0,1,2)],'terracotta',[[(0,0),(0.5,0.5),(1,0)]])
    b.faces([V((X1,Y1,rz)),V(ridge[1]),V((X1,Y0,rz))],[(0,1,2)],'terracotta',[[(0,0),(0.5,0.5),(1,0)]])
    q(b,[(X0,Y0,rz),(X0,Y1,rz),(X1,Y1,rz),(X1,Y0,rz)],'terracotta',(0,0,-1))   # eave soffit
    if not mid:   # barrel tile courses on the two long slopes + ridge cap
        n=int((X1-X0)/0.22)
        for s in (-1,1):
            ys,ye=s*(Y1),0.0
            for k in range(n):
                x=X0+0.11+k*(X1-X0-0.22)/(n-1)
                # tiles shorten toward the hips
                hx=min(x-X0,X1-x); yy=min(abs(ys),hx)
                if yy<0.12: continue
                p0=V((x,s*yy,rz+(abs(ys)-yy)*RH/abs(ys)+0.03)); p1=V((x,0.0,rz+RH+0.02))
                b.tube(p0,p1,0.045,0.04,4 if not hi else 10,'terracotta',cap0=hi,cap1=False,phase=PI/4)
        b.tube(V(ridge[0])+V((0,0,0.03)),V(ridge[1])+V((0,0,0.03)),0.06,0.06,4 if not hi else 12,'terracotta',cap0=True,cap1=True,phase=PI/4)
    if not mid:
        # Spanish-revival detail: corbel brackets under the header, inset tile panels + stepped plinth caps on the legs,
        # second cornice step, hip tiles on the 4 hips, cabinet clip angles into the legs
        for s in (-1,1):
            x=s*LX
            for o in (-1,1):
                yf=o*LD/2
                for k,(w,h) in enumerate(((0.20,0.10),(0.28,0.10),(0.36,0.12))):   # stepped corbel on each leg face (widens upward)
                    b.box((x,yf+o*(0.015+k*0.02),HZ-0.32+k*0.10),(w,0.03+k*0.04,h),'stucco',skip=())
                # inset glazed tile panel (blue/yellow Talavera) in a raised frame, mid-leg
                pz=4.35
                for pts in (((x-0.17,yf,pz),(x+0.17,yf,pz),(x+0.17,yf+o*0.02,pz),(x-0.17,yf+o*0.02,pz)),):
                    pass
                b.box((x,yf+o*0.01,pz),(0.36,0.02,0.36),'stucco',skip=('back',))
                b.box((x,yf+o*0.021,pz+0.03),(0.30,0.002,0.30),'paint_navy',skip=('back',))
                if hi:
                    for i in range(3):
                        for j in range(3):
                            c=(x-0.10+i*0.10,yf+o*0.0225,pz+0.08+j*0.10)
                            b.box(c,(0.09,0.002,0.09),'paint_yellow' if (i+j)%2 else 'paint_white',skip=('back',))
                            b.box((c[0],c[1]+o*0.001,c[2]+0.025),(0.04,0.002,0.04),'paint_navy',skip=('back',),rx=0)
            b.box((x,0,0.60),(LW+0.06,LD+0.06,0.05),'stucco',skip=('bottom',))       # plinth cap step
            for zz,dz in ((0.12,0.0),):
                pass
            for k in range(3):   # cabinet clip angles (galvanized) where each cabinet meets the leg
                z0=CAB[k]+0.2
                for o in (-1,1): b.box((s*(CW/2+0.02),o*0.11,z0),(0.05,0.05,0.12),'galvanized',skip=())
        b.box((0,0,cz-0.06),(HW_+0.06,HD+0.06,0.06),'stucco',skip=('bottom',))       # lower cornice step
        for (hx,hy) in ((X0,Y0),(X1,Y0),(X0,Y1),(X1,Y1)):   # hip tile rows
            rx_=ridge[0] if hx<0 else ridge[1]
            b.tube(V((hx,hy,rz+0.03)),V(rx_)+V((0,0,0.03)),0.05,0.05,4 if not hi else 10,'terracotta',cap0=True,cap1=False,phase=PI/4)
        # ground uplights in the planter, aimed at the cabinets
        for s in (-1,1):
            x=s*0.55; b.box((x,-0.55,0.24),(0.16,0.12,0.10),'paint_black',skip=('bottom',))
            q(b,[(x-0.06,-0.611,0.27),(x+0.06,-0.611,0.27),(x+0.06,-0.611,0.32),(x-0.06,-0.611,0.32)],'glass_dark',(0,-1,0)) if False else None
            b.box((x,-0.55,0.34),(0.12,0.08,0.006),'glass_dark',skip=('bottom',))
        # electrical: disconnect box + conduit on the back of the east leg
        b.box((LX,LD/2+0.06,1.1),(0.22,0.12,0.30),'galvanized',skip=('back',))
        b.tube((LX,LD/2+0.06,1.1),(LX,LD/2+0.06,0.24),0.016,0.016,6,'galvanized',cap0=False,cap1=False)
        b.box((LX+0.12,LD/2+0.09,1.22),(0.02,0.03,0.10),'paint_red',skip=('back',))   # handle
        if hi:
            frontal_text(b,'DANGER 277V',0.03,(LX,0,1.32),'paint_yellow',LD/2+0.121,back=True)
            for x in (-0.9,0.9): b.lathe([(0.11,0.24),(0.09,0.36),(0.0,0.42)],10,'paint_green',c=(x,-0.2,0))   # boxwood mounds
        else:
            for x in (-0.9,0.9): b.lathe([(0.12,0.24),(0.08,0.38),(0.0,0.42)],5,'paint_green',c=(x,-0.2,0),cap_top=False)
    if t=='near':
        for s in (-1,1): cbox(b,(s*LX,0,0),(LW+0.1,LD+0.1,LH))
        cbox(b,(0,0,0.24),(2*LX-LW,CD,LH-0.24)); cbox(b,(0,0,LH),(HW_+0.3,HD+0.3,HH+0.6)); cbox(b,(0,0,0),(3.6,1.65,0.30))
def pylon_far(b):
    # double-sided cards: front silhouette, side silhouette, cap + planter tops
    top=LH+1.4+0.10+0.42
    q(b,[(-1.4,0,0.3),(1.4,0,0.3),(1.4,0,LH),(-1.4,0,LH)],'twf_flat',(0,-1,0))
    q(b,[(-1.65,0,LH),(1.65,0,LH),(1.0,0,top),(-1.0,0,top)],'twf_flat',(0,-1,0))
    q(b,[(-1.8,0,0),(1.8,0,0),(1.8,0,0.3),(-1.8,0,0.3)],'twf_flat',(0,-1,0))
    q(b,[(0,-0.4,0.3),(0,0.4,0.3),(0,0.4,LH),(0,-0.4,LH)],'twf_flat',(-1,0,0))
    q(b,[(-1.65,-0.45,LH+1.45),(1.65,-0.45,LH+1.45),(1.65,0.45,LH+1.45),(-1.65,0.45,LH+1.45)],'twf_flat',(0,0,1))
    q(b,[(-1.8,-0.82,0.29),(1.8,-0.82,0.29),(1.8,0.82,0.29),(-1.8,0.82,0.29)],'twf_flat',(0,0,1))
# ===================================================================== drive-thru menu board (medium, near)
def drive_thru_menu(b,hi=False,t='near'):
    T_(hi,t)
    b.box((0,0,0),(2.9,0.8,0.12),'concrete',skip=('bottom',))                       # island curb pad
    b.box((-0.3,0.05,0.12),(2.2,0.42,0.48),'brick',skip=('bottom',))                  # brick pedestal
    b.box((-0.3,0.05,0.60),(2.28,0.48,0.05),'concrete',skip=('bottom',))              # precast cap
    x0=-0.3; W,H,D,Z=2.36,1.72,0.26,0.65
    b.box((x0,0.05,Z),(W,D,H),'paint_black',skip=('bottom','front'))
    yf=0.05-D/2
    # 3 backlit menu panels in a black frame (mullions + rails as the frame face)
    pw=(W-0.16-0.08)/3
    for pts in (((x0-W/2,yf,Z),(x0+W/2,yf,Z),(x0+W/2,yf,Z+0.08),(x0-W/2,yf,Z+0.08)),((x0-W/2,yf,Z+H-0.18),(x0+W/2,yf,Z+H-0.18),(x0+W/2,yf,Z+H),(x0-W/2,yf,Z+H))):
        q(b,pts,'paint_black',(0,-1,0))
    xs=[x0-W/2]+[x0-W/2+0.08+k*(pw+0.04)+pw for k in range(2)]
    for k in range(3):
        a=x0-W/2+0.08+k*(pw+0.04); c=a+pw
        q(b,[(a,yf+0.015,Z+0.08),(c,yf+0.015,Z+0.08),(c,yf+0.015,Z+H-0.18),(a,yf+0.015,Z+H-0.18)],'plastic_white',(0,-1,0))
        for (p0,p1) in (((a,yf,Z+0.08),(a,yf+0.015,Z+0.08)),): pass
    for k in range(4):   # frame stiles proud of the panels
        xa=x0-W/2+k*(pw+0.04) if k<3 else x0+W/2-0.08
        w_=0.08 if k in (0,3) else 0.04; xa=xa if k in (0,3) else xa+0.08-0.04+0.0
        xa=[x0-W/2,x0-W/2+0.08+pw,x0-W/2+0.08+2*pw+0.04,x0+W/2-0.08][k]; w_=[0.08,0.04,0.04,0.08][k]
        b.box((xa+w_/2,yf+0.0075,Z+0.08),(w_,0.015,H-0.26),'paint_black',skip=('bottom','top','back'))
    # header light box with the logo + visor hood
    b.box((x0,0.05,Z+H),(W+0.04,D+0.04,0.30),'paint_red',skip=('bottom',))
    q(b,[(x0-W/2-0.02,yf-0.02-0.001,Z+H+0.04),(x0+W/2+0.02,yf-0.021,Z+H+0.04),(x0+W/2+0.02,yf-0.021,Z+H+0.26),(x0-W/2-0.02,yf-0.021,Z+H+0.26)],'plastic_white',(0,-1,0)) if hi else None
    for s in (-1,1): b.box((x0+s*(W/2+0.01),yf-0.10,Z+H-0.22),(0.02,0.2,0.2),'paint_black',skip=('top',))   # hood cheeks
    b.box((x0,yf-0.10,Z+H-0.04),(W+0.04,0.22,0.03),'paint_black',rx=-0.25)                # hood
    # order-point speaker post with confirmation screen and canopy; yellow pipe bollard
    sx=1.18
    b.box((sx,0.0,0.12),(0.12,0.12,1.0),'paint_black',skip=('bottom','top'))
    b.box((sx,0.0,1.12),(0.44,0.18,0.62),'paint_black',skip=('bottom',))
    b.box((sx,-0.091,1.40),(0.34,0.004,0.26),'glass_dark',skip=('back',))                 # order confirmation screen
    b.box((sx,-0.092,1.18),(0.26,0.004,0.16),'aluminium',skip=('back',))                  # speaker grille plate
    b.box((sx,-0.05,1.74),(0.56,0.36,0.04),'paint_red',rx=-0.12,skip=())                  # canopy
    b.lathe([(0.055,0.12),(0.055,1.05),(0.04,1.12),(0.0,1.13)],8,'paint_yellow',c=(sx+0.05,-0.55,0),cap_top=False)
    b.lathe([(0.075,0.12),(0.075,0.16),(0.055,0.17)],8,'concrete',c=(sx+0.05,-0.55,0),cap_top=False)
    b.tube((sx,0.07,0.12),(sx,0.07,0.0),0.02,0.02,6,'galvanized',cap0=False,cap1=False) if False else None
    b.box((sx,0.08,0.12),(0.05,0.04,0.95),'galvanized',skip=('bottom','top','front'))     # cable raceway
    if hi:
        # menu artwork: section headers, items, prices, photos
        cats=[('BURGERS',['BAY BURGER 6.49','DOUBLE CROWN 8.29','SURF & TURF 9.99','VEGGIE WAVE 6.99']),
              ('COMBOS',['#1 BAY COMBO 9.49','#2 CROWN COMBO 11.29','#3 FISH TACO 8.99','KIDS MEAL 5.49']),
              ('DRINKS & SHAKES',['FOUNTAIN 1.99','ICED TEA 1.99','SHAKE 3.99','COFFEE 1.79'])]
        for k,(hd,items) in enumerate(cats):
            a=x0-W/2+0.08+k*(pw+0.04); cx=a+pw/2; yy=yf+0.015-0.0008
            b.box((cx,yy,Z+H-0.32),(pw-0.04,0.0008,0.11),'paint_red',skip=('back',))
            frontal_text(b,hd,0.075,(cx,0,Z+H-0.265),'plastic_white',yy-0.0004)
            b.box((cx,yy,Z+H-0.75),(pw-0.10,0.0008,0.38),'plastic_orange',skip=('back',))   # food photo panel
            for j,it in enumerate(items): frontal_text(b,it,0.05,(cx,0,Z+H-0.86-j*0.09-0.06),'paint_black',yy-0.0004)
        frontal_text(b,'BURGER BAY',0.16,(x0,0,Z+H+0.15),'plastic_white',yf-0.022,depth=0.003)
        frontal_text(b,'PLEASE ORDER HERE',0.035,(sx,0,1.315),'plastic_white',-0.0905)
        for i in range(6):
            for j in range(4): b.box((sx-0.1+i*0.04,-0.0945,1.13+j*0.035),(0.018,0.001,0.018),'rubber_black',skip=('back',))
        for x in (-1.2,-0.6,0.6,1.2): nut4(b,(x,-0.3,0.12),(0,0,1),0.012,'galvanized',hi)
        for k in range(6): b.box((x0+W/2+0.0005,0.05,Z+0.3+k*0.18),(0.001,0.16,0.02),'rubber_black')   # side cooling louvres
        b.box((x0,yf+0.0005,Z+0.03),(0.5,0.001,0.03),'stainless',skip=('back',))
    if t=='near':
        cbox(b,(0,0,0),(2.9,0.8,0.12)); cbox(b,(x0,0.05,0.12),(W,D+0.2,H+0.83)); cbox(b,(sx,0,0.12),(0.44,0.2,1.7)); ccyl(b,(sx+0.05,-0.55,0.12),0.06,1.0,rail=True)
# ===================================================================== bus-stop pole sign (medium, near)
def bus_stop_sign(b,hi=False,t='near'):
    T_(hi,t); sg=10 if not hi else 24
    b.lathe([(0.16,0.0),(0.15,0.05),(0.06,0.06)],sg,'concrete',c=(0,0,0),cap_top=False)          # footing collar
    b.tube((0,0,0.05),(0,0,3.20),0.030,0.030,sg,'galvanized',cap0=False,cap1=False)
    b.lathe([(0.034,3.20),(0.036,3.23),(0.02,3.25),(0.0,3.26)],sg,'galvanized',c=(0,0,0),cap_top=False)   # pole cap
    # bus flag on two band clamps (decal both faces)
    fy=-0.045; fz=2.35
    b.box((0.24,fy,fz),(0.45,0.004,0.60),'plastic_white',skip=('bottom','top','left','right') if not hi else ())
    if hi:   # flag artwork (baked, both faces): navy header band, BUS STOP, bus pictogram, red route band, MTS footer
        for o in (-1,1):
            yy=fy+o*0.0022; bk=(o>0)
            b.box((0.24,yy,fz+0.44),(0.43,0.0008,0.14),'paint_navy',skip=())
            frontal_text(b,'BUS',0.075,(0.24,0,fz+0.48),'paint_white',yy+o*0.0006,back=bk,depth=0.0008)
            frontal_text(b,'STOP',0.045,(0.24,0,fz+0.455) if False else (0.24,0,fz+0.452),'paint_white',yy+o*0.0006,back=bk,depth=0.0008)
            b.box((0.24,yy,fz+0.20),(0.30,0.0008,0.14),'paint_black',skip=())        # bus body
            for wx in (0.13,0.20,0.27,0.34): b.box((wx,yy+o*0.0006,fz+0.29),(0.05,0.0008,0.04),'paint_white',skip=())   # windows
            for wx in (0.15,0.33): b.lathe([(0.025,0),(0.0,0)],12,'paint_black',c=(wx,yy,fz+0.20),cap_top=False) if False else b.box((wx,yy,fz+0.17),(0.05,0.0008,0.05),'paint_black',skip=())
            b.box((0.24,yy,fz+0.08),(0.43,0.0008,0.06),'paint_red',skip=())
            frontal_text(b,'MTS  ·  619-233-3004',0.022,(0.24,0,fz+0.035),'paint_navy',yy,back=bk,depth=0.0008)
    q(b,[(0.015,fy-0.002,fz),(0.015,fy+0.002,fz),(0.015,fy+0.002,fz+0.6),(0.015,fy-0.002,fz+0.6)],'aluminium',(-1,0,0))
    q(b,[(0.465,fy-0.002,fz),(0.465,fy+0.002,fz),(0.465,fy+0.002,fz+0.6),(0.465,fy-0.002,fz+0.6)],'aluminium',(1,0,0))
    for zz in (fz+0.1,fz+0.5):   # band clamps + bracket arms
        b.tube((0,0,zz-0.02),(0,0,zz+0.02),0.036,0.036,8,'stainless',cap0=False,cap1=False)
        b.box((0.02,fy+0.02,zz-0.02),(0.04,0.04,0.04),'stainless',skip=())
        if hi: nut4(b,(0.04,fy+0.03,zz),(1,0,0),0.006,'stainless',hi)
    # route tabs above the flag
    for k,rt in enumerate(('901','904')):
        z=fz+0.64+k*0.17
        b.box((0.24,fy,z),(0.45,0.004,0.15),'paint_white',skip=('bottom','top'))
        for zz in (z+0.03,z+0.12): b.tube((0,0,zz-0.015),(0,0,zz+0.015),0.035,0.035,6,'stainless',cap0=False,cap1=False)
        if hi:
            frontal_text(b,rt,0.10,(0.30,0,z+0.075),'paint_black',fy-0.002,depth=0.001); frontal_text(b,rt,0.10,(0.30,0,z+0.075),'paint_black',fy+0.002,back=True,depth=0.001)
            frontal_text(b,'MTS',0.05,(0.08,0,z+0.075),'paint_red',fy-0.002,depth=0.001); frontal_text(b,'MTS',0.05,(0.08,0,z+0.075),'paint_red',fy+0.002,back=True,depth=0.001)
    # schedule holder (lockable display case) at eye height
    b.box((0,-0.075,1.25),(0.26,0.06,0.48),'paint_navy',skip=('back',))
    b.box((0,-0.106,1.29),(0.21,0.002,0.36),'glass_dark',skip=('back',))
    for zz in (1.32,1.62): b.tube((0,0,zz-0.015),(0,0,zz+0.015),0.035,0.035,6,'stainless',cap0=False,cap1=False)
    b.box((0,-0.045,1.30),(0.06,0.03,0.38),'stainless',skip=('front','back'))
    if hi:
        b.box((0,-0.1072,1.30),(0.19,0.0008,0.34),'paint_white',skip=('back',))
        frontal_text(b,'ROUTE 901 / 904',0.022,(0,0,1.61),'paint_navy',-0.1078)
        for j in range(10): b.box((0,-0.1078,1.30+0.02+j*0.026),(0.15,0.0006,0.006),'paint_black',skip=('back',))
        frontal_text(b,'STOP ID 13821',0.018,(0,0,1.275),'paint_black',-0.1078)
        b.box((0.11,-0.107,1.45),(0.012,0.006,0.03),'brass',skip=('back',))
    if t=='near': ccyl(b,(0,0,0),0.04,3.26,rail=True); cbox(b,(0.24,fy,fz),(0.46,0.02,0.97))
# ===================================================================== motel vending: soda / snack / ice (small, near)
def _feet(b,w,d,hi):
    for sx in (-1,1):
        for sy in (-1,1): b.lathe([(0.025,0.0),(0.025,0.03),(0.015,0.04)],6 if not hi else 12,'rubber_black',c=(sx*(w/2-0.06),sy*(d/2-0.06),0),cap_top=False)
def vending_soda(b,hi=False,t='near'):
    T_(hi,t); W,D,H=0.95,0.85,1.83; z0=0.04
    _feet(b,W,D,hi)
    b.box((0,0,z0),(W,D,H-z0),'paint_red',skip=('front',))
    yf=-D/2
    # door: graphic panel (left), selection column (right), delivery bin at the bottom, kick plate
    q(b,[(-W/2,yf,z0),(W/2,yf,z0),(W/2,yf,z0+0.10),(-W/2,yf,z0+0.10)],'paint_black',(0,-1,0))
    b.box((0,yf-0.015,z0+0.10),(W,0.03,H-z0-0.10),'paint_red',skip=('back','front'))
    g0,g1=-W/2+0.04,W/2-0.27
    q(b,[(-W/2,yf-0.03,z0+0.10),(W/2,yf-0.03,z0+0.10),(W/2,yf-0.03,z0+0.38),(-W/2,yf-0.03,z0+0.38)],'paint_red',(0,-1,0))
    q(b,[(-W/2,yf-0.03,H-0.06),(W/2,yf-0.03,H-0.06),(W/2,yf-0.03,H),(-W/2,yf-0.03,H)],'paint_red',(0,-1,0))
    q(b,[(-W/2,yf-0.03,z0+0.38),(g0,yf-0.03,z0+0.38),(g0,yf-0.03,H-0.06),(-W/2,yf-0.03,H-0.06)],'paint_red',(0,-1,0))
    q(b,[(g1,yf-0.03,z0+0.38),(g1+0.02,yf-0.03,z0+0.38),(g1+0.02,yf-0.03,H-0.06),(g1,yf-0.03,H-0.06)],'paint_red',(0,-1,0))
    q(b,[(g0,yf-0.034,z0+0.38),(g1,yf-0.034,z0+0.38),(g1,yf-0.034,H-0.06),(g0,yf-0.034,H-0.06)],'plastic_white',(0,-1,0))   # lit graphic panel
    b.box((W/2-0.125,yf-0.03,z0+0.38),(0.23,0.02,H-z0-0.44),'paint_black',skip=('back',))   # selection column
    for k in range(8): b.box((W/2-0.125,yf-0.05,z0+0.80+k*0.105),(0.17,0.012,0.075),'plastic_white',skip=('back',))
    b.box((W/2-0.125,yf-0.06,z0+0.48),(0.16,0.03,0.22),'aluminium',skip=('back',))            # coin + bill mech plate
    b.box((W/2-0.125,yf-0.075,z0+0.44),(0.06,0.015,0.04),'aluminium',skip=('back',))         # coin return cup
    b.box((-0.08,yf-0.045,z0+0.13),(0.48,0.015,0.20),'paint_black',skip=('back',))           # delivery bin flap
    b.tube((W/2-0.125,yf-0.03,z0+0.36),(W/2-0.125,yf-0.07,z0+0.36),0.016,0.016,6,'stainless',cap0=False,cap1=True)   # T-handle lock
    b.box((W/2-0.125,yf-0.07,z0+0.33),(0.012,0.012,0.06),'stainless',skip=())
    b.tube((0.2,D/2,z0+0.15),(0.2,D/2+0.06,z0),0.008,0.008,4,'rubber_black',cap0=False,cap1=False)   # power cord
    if hi:
        yy=yf-0.0345
        b.box((-0.12,yy,z0+0.40),(0.62,0.001,1.30),'paint_red',skip=('back',))
        frontal_text(b,'ICE COLD',0.10,(-0.12,0,z0+1.52),'plastic_white',yy-0.0006,depth=0.0015)
        frontal_text(b,'CROWN COLA',0.085,(-0.12,0,z0+1.38),'paint_yellow',yy-0.0006,depth=0.0015)
        for k in range(3): b.tube((-0.30+k*0.18,yy-0.03,z0+0.62),(-0.30+k*0.18,yy-0.03,z0+0.98),0.032,0.032,12,['plastic_white','paint_yellow','paint_navy'][k],cap1=True)
        for k in range(8): frontal_text(b,'1.75',0.026,(W/2-0.125,0,z0+0.83+k*0.105),'paint_black',yf-0.0566)
        b.box((W/2-0.125,yf-0.0755,z0+0.55),(0.07,0.001,0.012),'rubber_black',skip=('back',))   # bill slot
        b.box((W/2-0.09,yf-0.0755,z0+0.63),(0.006,0.001,0.03),'rubber_black',skip=('back',))   # coin slot
        frontal_text(b,'EXACT CHANGE ONLY',0.014,(W/2-0.125,0,z0+0.67),'paint_red',yf-0.0756)
        for k in range(6): b.box((0,D/2+0.0005,z0+0.15+k*0.05),(0.5,0.001,0.02),'rubber_black')  # rear condenser louvres
        b.box((-0.08,yf-0.0526,z0+0.29),(0.2,0.001,0.02),'paint_white',skip=('back',))
        frontal_text(b,'PUSH',0.02,(-0.08,0,z0+0.30),'paint_black',yf-0.0532)
    if t=='near': cbox(b,(0,-0.02,0),(W,D+0.04,H))
def vending_snack(b,hi=False,t='near'):
    T_(hi,t); W,D,H=1.00,0.90,1.83; z0=0.04
    _feet(b,W,D,hi)
    b.box((0,0,z0),(W,D,H-z0),'paint_black',skip=('front',))
    yf=-D/2; g0,g1,gz0,gz1=-W/2+0.06,W/2-0.30,z0+0.46,H-0.10
    # cabinet door frame (black), glass window over the spiral trays, keypad column, retrieval door
    for pts in (((-W/2,yf,z0),(W/2,yf,z0),(W/2,yf,gz0),(-W/2,yf,gz0)),((-W/2,yf,gz1),(W/2,yf,gz1),(W/2,yf,H),(-W/2,yf,H)),
                ((-W/2,yf,gz0),(g0,yf,gz0),(g0,yf,gz1),(-W/2,yf,gz1)),((g1,yf,gz0),(W/2,yf,gz0),(W/2,yf,gz1),(g1,yf,gz1))):
        q(b,pts,'paint_black',(0,-1,0))
    yi=yf+0.03
    for pts,n in ((((g0,yf,gz0),(g1,yf,gz0),(g1,yi,gz0),(g0,yi,gz0)),(0,0,1)),(((g0,yf,gz1),(g1,yf,gz1),(g1,yi,gz1),(g0,yi,gz1)),(0,0,-1)),
                  (((g0,yf,gz0),(g0,yi,gz0),(g0,yi,gz1),(g0,yf,gz1)),(1,0,0)),(((g1,yf,gz0),(g1,yi,gz0),(g1,yi,gz1),(g1,yf,gz1)),(-1,0,0))):
        q(b,pts,'paint_black',n)
    q(b,[(g0,yi,gz0),(g1,yi,gz0),(g1,yi,gz1),(g0,yi,gz1)],'glass_dark',(0,-1,0))
    b.box((W/2-0.15,yf-0.012,gz0+0.30),(0.20,0.012,0.72),'aluminium',skip=('back',))      # keypad / payment panel
    b.box((W/2-0.15,yf-0.022,gz0+0.82),(0.12,0.01,0.06),'glass_dark',skip=('back',))      # display
    b.box((W/2-0.15,yf-0.024,gz0+0.52),(0.12,0.012,0.16),'stainless',skip=('back',))      # keypad block
    b.box((W/2-0.15,yf-0.026,gz0+0.36),(0.12,0.016,0.10),'paint_black',skip=('back',))     # card reader
    b.box((-0.10,yf-0.012,z0+0.12),(0.50,0.012,0.22),'paint_black',skip=('back',))         # retrieval door
    b.box((-0.10,yf-0.022,z0+0.30),(0.20,0.01,0.025),'aluminium',skip=('back',))
    b.tube((W/2-0.15,yf,z0+0.30),(W/2-0.15,yf-0.04,z0+0.30),0.016,0.016,6,'stainless',cap0=False,cap1=True)
    b.tube((-0.2,D/2,z0+0.15),(-0.2,D/2+0.06,z0),0.008,0.008,4,'rubber_black',cap0=False,cap1=False)
    if hi:
        cols=['paint_red','paint_yellow','plastic_blue','plastic_orange','paint_green','paint_white']
        for r in range(5):
            zr=gz0+0.08+r*0.235
            b.box(((g0+g1)/2,yi+0.12,zr-0.03),(g1-g0-0.02,0.30,0.012),'aluminium')     # tray
            for c_ in range(6):
                x=g0+0.05+c_*(g1-g0-0.1)/5
                b.tube((x,yi+0.02,zr),(x,yi+0.25,zr),0.035,0.035,8,'stainless',cap0=False,cap1=False)   # spiral (as a coil sleeve)
                b.box((x,yi+0.05,zr-0.02),(0.065,0.018,0.14),cols[(r*2+c_)%6])                       # front packet
                b.box((x,yi-0.0005,zr-0.035),(0.04,0.001,0.012),'plastic_white',skip=('back',))       # price tag
        for i in range(3):
            for j in range(4): b.box((W/2-0.19+i*0.04,yf-0.0305,gz0+0.455+j*0.035),(0.026,0.004,0.026),'aluminium',skip=('back',))
        frontal_text(b,'SNACKS',0.07,((g0+g1)/2,0,gz1+0.045),'paint_yellow',yf-0.0006,depth=0.0015)
        frontal_text(b,'PUSH',0.02,(-0.10,0,z0+0.19),'plastic_white',yf-0.0126)
    if t=='near': cbox(b,(0,-0.02,0),(W,D+0.04,H))
def ice_chest(b,hi=False,t='near'):
    T_(hi,t); W,D,H=1.36,0.78,1.24
    for sx in (-1,1): b.box((sx*(W/2-0.05),0,0),(0.06,D-0.04,0.08),'galvanized',skip=('bottom',))   # base rails
    b.box((0,0,0.08),(W,D,H-0.08-0.06),'paint_white',skip=('front','bottom'))
    yf=-D/2
    # top with rounded front edge (2 chamfer facets)
    zt=H-0.06
    q(b,[(-W/2,yf,zt),(W/2,yf,zt),(W/2,yf+0.02,zt+0.045),(-W/2,yf+0.02,zt+0.045)],'paint_white',(0,-1,0.7))
    q(b,[(-W/2,yf+0.02,zt+0.045),(W/2,yf+0.02,zt+0.045),(W/2,yf+0.06,H),(-W/2,yf+0.06,H)],'paint_white',(0,-0.5,1))
    q(b,[(-W/2,yf+0.06,H),(W/2,yf+0.06,H),(W/2,D/2,H),(-W/2,D/2,H)],'paint_white',(0,0,1))
    for sx in (-1,1):
        q(b,[(sx*W/2,yf,zt),(sx*W/2,yf+0.02,zt+0.045),(sx*W/2,yf+0.06,H),(sx*W/2,D/2,H),(sx*W/2,D/2,zt)],'paint_white',(sx,0,0)) if False else None
        b.faces([V((sx*W/2,yf,zt)),V((sx*W/2,D/2,zt)),V((sx*W/2,D/2,H)),V((sx*W/2,yf+0.06,H)),V((sx*W/2,yf+0.02,zt+0.045))],
                [(0,1,2,3,4)] if sx>0 else [(4,3,2,1,0)],'paint_white',[[(0,0),(1,0),(1,0.06),(0.1,0.06),(0.03,0.04)]])
    # front: louvred compressor grille band, two doors with gaskets, lever handles, padlock hasp
    q(b,[(-W/2,yf,0.08),(W/2,yf,0.08),(W/2,yf,0.36),(-W/2,yf,0.36)],'paint_white',(0,-1,0))
    for k in range(5): obox(b,(-0.40,yf-0.01,0.13+k*0.045),(0.40,yf-0.01,0.13+k*0.045),0.02,0.03,'paint_white',up=(0,-0.5,1),ends=(False,False),skip=('bottom',))
    q(b,[(-W/2,yf,0.36),(W/2,yf,0.36),(W/2,yf,zt),(-W/2,yf,zt)],'paint_white',(0,-1,0))
    for sx in (-1,1):
        cx=sx*W/4
        b.box((cx,yf-0.015,0.40),(W/2-0.06,0.03,zt-0.44),'plastic_white',skip=('back',))   # door skins bake (ICE lettering); the cabinet tiles tw_paint
        b.box((cx+(-sx)*0.24,yf-0.045,0.78),(0.04,0.03,0.20),'aluminium',skip=('back',))      # lever handle
        for zz in (0.48,zt-0.12): b.box((cx+sx*(W/4-0.05),yf-0.035,zz),(0.03,0.02,0.07),'aluminium',skip=('back',))   # hinges
    b.box((0,yf-0.04,0.84),(0.05,0.012,0.07),'stainless',skip=('back',))                          # hasp
    b.box((0,yf-0.055,0.77),(0.04,0.02,0.05),'brass',skip=())                                     # padlock body
    b.tube((W/2,0.2,0.12),(W/2+0.05,0.2,0.0),0.012,0.012,6,'rubber_black',cap0=False,cap1=False)   # defrost drain hose
    b.tube((-0.4,D/2,0.25),(-0.4,D/2+0.08,0.0),0.008,0.008,4,'rubber_black',cap0=False,cap1=False)
    if hi:
        for sx in (-1,1):
            frontal_text(b,'ICE',0.30,(sx*W/4,0,0.86),'plastic_blue',yf-0.0306,depth=0.004)
            b.box((sx*W/4,yf-0.0305,0.62),(0.5,0.0008,0.06),'plastic_blue',skip=('back',))
            frontal_text(b,'SELF SERVE  ·  10 LB  2.99',0.026,(sx*W/4,0,0.62+0.03),'plastic_white',yf-0.0316)
            b.box((sx*W/4,yf-0.0302,0.40+0.01),(W/2-0.07,0.0008,0.012),'rubber_black',skip=('back',))   # gasket line
        b.tube((0,yf-0.055,0.80),(0,yf-0.055,0.83),0.012,0.012,8,'stainless',cap0=False,cap1=False)
        frontal_text(b,'KEEP CLOSED',0.03,(0,0,zt-0.02),'plastic_blue',yf-0.0006)
    if t=='near': cbox(b,(0,-0.03,0),(W,D+0.06,H))
# ===================================================================== wheel stops (tiny, near)
def _extrude(b,prof,x0,x1,key,cap=True):
    """profile (y,z) list (closed, CCW seen from +x) extruded along x"""
    n=len(prof)
    for i in range(n):
        (ya,za),(yb,zb)=prof[i],prof[(i+1)%n]
        if za<1e-4 and zb<1e-4: continue
        nrm=V((0,zb-za,-(yb-ya))) ; c=V((0,(ya+yb)/2,(za+zb)/2))
        q(b,[(x0,ya,za),(x1,ya,za),(x1,yb,zb),(x0,yb,zb)],key,(0,(zb-za),-(yb-ya)) if True else nrm)
    if cap:
        for x,o in ((x0,-1),(x1,1)):
            pts=[V((x,y,z)) for y,z in prof]
            if o<0: pts=pts[::-1]
            b.faces(pts,[tuple(range(n))],key,[[(p.y,p.z) for p in pts]])
def wheel_stop_concrete(b,hi=False,t='near'):
    T_(hi,t); L=1.83
    prof=[(0.075,0.0),(0.075,0.075),(0.050,0.100),(-0.050,0.100),(-0.075,0.075),(-0.075,0.0)][::-1]
    # body with two drain notches under it (three blocks), chamfered ends
    segs=[(-L/2,-0.55),(-0.45,0.45),(0.55,L/2)]
    for k,(a,c) in enumerate(segs):
        _extrude(b,prof,a,c,'paint_yellow' if not hi else 'concrete',cap=(k!=1))
    notch=[(0.075,0.03),(0.075,0.075),(0.050,0.100),(-0.050,0.100),(-0.075,0.075),(-0.075,0.03)][::-1]
    for (a,c) in ((-0.55,-0.45),(0.45,0.55)):
        _extrude(b,notch,a,c,'paint_yellow' if not hi else 'concrete',cap=False)
        q(b,[(a,-0.075,0.03),(c,-0.075,0.03),(c,0.075,0.03),(a,0.075,0.03)],'concrete',(0,0,-1))
        for x,o in ((a,1),(c,-1)): q(b,[(x,-0.075,0.0),(x,0.075,0.0),(x,0.075,0.03),(x,-0.075,0.03)],'concrete',(o,0,0))
    for x in (-0.6,0.6):   # rebar pins in their holes
        b.lathe([(0.022,0.1005),(0.016,0.0985)],6 if not hi else 16,'rubber_black',c=(x,0,0),cap_top=True)
        b.tube((x,0,0.096),(x,0,0.108),0.0125,0.0125,6 if not hi else 12,'rust' if False else 'cast_iron',cap0=False,cap1=True)
    if hi:
        # yellow paint layer with chips: painted boxes over the top and front/back faces, missing patches
        import random; r=random.Random(5)
        x=-L/2+0.02
        while x<L/2-0.05:
            w=r.uniform(0.05,0.22)
            if r.random()>0.18:
                b.box((x+w/2,0,0.1),(w,0.1,0.0015),'paint_yellow',skip=('bottom',))
                for s in (-1,1): b.box((x+w/2,s*0.0755,0.02),(w,0.0015,0.052),'paint_yellow',skip=('back',) if s<0 else ('front',))
            x+=w+r.uniform(0.0,0.02)
        for k in range(14):   # spalls at the arrises
            xx=r.uniform(-0.85,0.85); s=r.choice((-1,1)); b.box((xx,s*0.064,0.083),(r.uniform(0.02,0.06),0.02,0.02),'concrete',rz=r.uniform(-0.3,0.3))
    if t=='near': cbox(b,(0,0,0),(L,0.15,0.10))
def wheel_stop_rubber(b,hi=False,t='near'):
    T_(hi,t); L=1.83
    prof=[(0.075,0.0),(0.075,0.05),(0.06,0.085),(0.03,0.10),(-0.03,0.10),(-0.06,0.085),(-0.075,0.05),(-0.075,0.0)][::-1]
    _extrude(b,prof,-L/2,L/2,'rubber_black')
    for x0 in (-0.62,0.32):   # yellow reflective strips (raised)
        for (ya,za),(yb,zb) in ((prof[3],prof[4]),(prof[4],prof[5]),(prof[2],prof[3])) if False else (((-0.06,0.086),(-0.03,0.1005)),((-0.03,0.1005),(0.03,0.1005)),((0.03,0.1005),(0.06,0.086))):
            q(b,[(x0,ya,za+0.0015),(x0+0.30,ya,za+0.0015),(x0+0.30,yb,zb+0.0015),(x0,yb,zb+0.0015)],'paint_yellow',(0,(zb-za),-(yb-ya)) if False else (0,-(zb-za)*0+0.0,1))
    for x in (-0.75,0.0,0.75):   # spike heads in counterbored holes
        b.lathe([(0.028,0.1005),(0.020,0.094),(0.0,0.094)],6 if not hi else 16,'rubber_black',c=(x,0,0),cap_top=False)
        b.lathe([(0.016,0.094),(0.016,0.10),(0.0,0.104)],6 if not hi else 16,'galvanized',c=(x,0,0),cap_top=False)
    if hi:
        for k in range(30): b.box((-L/2+0.06+k*0.06,0,0.1),(0.008,0.05,0.002),'rubber_black')   # moulded grip ribs
        frontal_text(b,'RECYCLED RUBBER  ·  MADE IN USA',0.02,(0,0,0.03),'rubber_black',-0.0755,depth=0.0012)
    if t=='near': cbox(b,(0,0,0),(L,0.15,0.10))
# ===================================================================== shopping cart (medium, near)
CL=0.92; BZ0,BZ1=0.55,1.00
def _cart_pts():
    # basket: top rim (x half 0.27, y -0.46..0.42), bottom (x half 0.21, y -0.36..0.40)
    top=[V((-0.27,-0.46,BZ1)),V((0.27,-0.46,BZ1)),V((0.27,0.42,BZ1)),V((-0.27,0.42,BZ1))]
    bot=[V((-0.21,-0.34,BZ0)),V((0.21,-0.34,BZ0)),V((0.21,0.40,BZ0)),V((-0.21,0.40,BZ0))]
    return top,bot
def shopping_cart(b,hi=False,t='near'):
    T_(hi,t); top,bot=_cart_pts(); W='galvanized'; rw=0.0035 if not hi else 0.003; rr=0.007; sg=4 if not hi else 8
    def wire(p0,p1,r=rw,key=W,s=None): b.tube(p0,p1,r,r,s or sg,key,cap0=False,cap1=False,sq=(not hi))
    L=lambda a,c,f: a+(c-a)*f
    # rim + bottom frame
    for i in range(4):
        wire(top[i],top[(i+1)%4],rr,s=(6 if not hi else 12)); wire(bot[i],bot[(i+1)%4],0.005)
    for i in range(4): wire(top[i],bot[i],0.006)
    # side walls (left/right): horizontal + vertical wires
    for (ta,tb,ba,bb) in ((top[0],top[3],bot[0],bot[3]),(top[1],top[2],bot[1],bot[2])):
        for f in (0.25,0.5,0.75): wire(L(ta,ba,f),L(tb,bb,f))
        n=10
        for k in range(1,n): wire(L(ta,tb,k/n),L(ba,bb,k/n))
    # front (nose) and back gate walls
    for (ta,tb,ba,bb) in ((top[0],top[1],bot[0],bot[1]),(top[3],top[2],bot[3],bot[2])):
        for f in (0.25,0.5,0.75): wire(L(ta,ba,f),L(tb,bb,f))
        for k in range(1,6): wire(L(ta,tb,k/6),L(ba,bb,k/6))
    # floor grid
    for k in range(1,6): wire(L(bot[0],bot[1],k/6),L(bot[3],bot[2],k/6))
    for k in range(1,4): wire(L(bot[0],bot[3],k/4),L(bot[1],bot[2],k/4))
    # chassis: side frame tubes from the rear casters up to the handle, base U-frame, lower rack
    tr=0.011; ts=6 if not hi else 12
    for s in (-1,1):
        p=[V((s*0.24,0.40,0.11)),V((s*0.24,0.44,BZ0-0.02)),V((s*0.26,0.50,BZ1+0.03)),V((s*0.26,0.56,1.03))]
        for i in range(3): b.tube(p[i],p[i+1],tr,tr,ts,W,cap0=False,cap1=False)
        b.tube(V((s*0.20,-0.36,0.11)),V((s*0.24,0.40,0.11)),tr,tr,ts,W,cap0=False,cap1=False)       # base rail
        b.tube(V((s*0.20,-0.30,0.11)),V((s*0.21,-0.30,BZ0)),0.008,0.008,ts,W,cap0=False,cap1=False)   # front basket strut
    b.tube(V((-0.20,-0.36,0.11)),V((0.20,-0.36,0.11)),tr,tr,ts,W,cap0=False,cap1=False)
    b.tube(V((-0.27,0.56,1.03)),V((0.27,0.56,1.03)),0.014,0.014,ts,W,cap0=True,cap1=True)
    b.tube(V((-0.22,0.56,1.03)),V((0.22,0.56,1.03)),0.019,0.019,ts,'paint_red',cap0=True,cap1=True)   # handle grip
    b.box((0,0.53,0.92),(0.30,0.015,0.10),'paint_red',skip=(),rx=-0.4)                               # handle ad panel
    for k in range(5): wire(V((-0.18+k*0.09,-0.30,0.15)),V((-0.18+k*0.09,0.36,0.15)),0.004)            # lower rack
    wire(V((-0.20,-0.30,0.15)),V((0.20,-0.30,0.15)),0.005); wire(V((-0.22,0.36,0.15)),V((0.22,0.36,0.15)),0.005)
    # casters: swivel plate, fork, wheel
    for (x,y) in ((-0.20,-0.33),(0.20,-0.33),(-0.24,0.38),(0.24,0.38)):
        b.box((x,y,0.095),(0.06,0.06,0.012),'galvanized',skip=())
        for o in (-1,1): b.box((x+o*0.02,y+0.015,0.05),(0.006,0.03,0.05),'galvanized',skip=())
        b.tube((x-0.014,y+0.02,0.05),(x+0.014,y+0.02,0.05),0.05,0.05,8 if not hi else 16,'rubber_black',cap0=True,cap1=True)
    for (x,y) in ((-0.27,-0.46),(0.27,-0.46)): b.box((x,y,BZ1-0.06),(0.04,0.04,0.08),'paint_red',skip=())   # nose bumpers
    b.box((0,0.30,BZ1-0.01),(0.40,0.20,0.012),'paint_red',skip=())   # child seat flap (folded)
    if hi:
        frontal_text(b,'CROWN MARKET',0.03,(0,0,0.0),'plastic_white',0.0,depth=0.0) if False else None
        text(b,'CROWN MARKET',0.032,(0,0.5225,0.925),(-1,0,0),'plastic_white',0.0012,yd=(0,0.37,0.93))
        for (x,y) in ((-0.20,-0.33),(0.20,-0.33),(-0.24,0.38),(0.24,0.38)):
            for k in range(8): b.box((x,y+0.02,0.05),(0.032,0.004,0.1),'rubber_black',rx=k*PI/8)   # tread
            nut4(b,(x+0.024,y+0.02,0.05),(1,0,0),0.006,'galvanized',hi)
    if t=='near': cbox(b,(0,0,0.11),(0.56,0.92,0.92)); cbox(b,(0,0.52,0.9),(0.56,0.1,0.16))
# ===================================================================== cart corral (large)
CXS=(-1.83,-0.61,0.61,1.83); CY=0.68; CH=1.0
def cart_corral(b,hi=False,t='near'):
    T_(hi,t); mid=t=='mid'; sg=8 if not hi else 16; r=0.03 if not mid else 0.03
    if mid: sg=6
    for s in (-1,1):
        for x in CXS:
            b.tube((x,s*CY,0.01 if not mid else 0.0),(x,s*CY,CH-r),r,r,sg,'galvanized',cap0=False,cap1=True)
            if not mid:
                P.rec('v',(x,s*CY,0.0),(x,s*CY,CH-r),r)
                b.box((x,s*CY,0),(0.16,0.16,0.01),'galvanized',skip=('bottom',))
                for k in ((-1,-1),(1,1)) if not hi else ((-1,-1),(1,1),(-1,1),(1,-1)): nut4(b,(x+k[0]*0.055,s*CY+k[1]*0.055,0.01),(0,0,1),0.009,'galvanized',hi)
        # top rail + mid rail, continuous along the side; the entry end bends down to the ground (grounded)
        for zz in (CH-r,0.5):
            e=r*0.97   # rails end on the end-post faces (run through the middle posts)
            b.tube((CXS[0]+e,s*CY,zz),(CXS[-1]-e,s*CY,zz),r*0.9 if zz>0.6 else 0.022,r*0.9 if zz>0.6 else 0.022,sg,'galvanized',cap0=False,cap1=False)
            if not mid: P.rec('h',(CXS[0]+e,s*CY,zz),(CXS[-1]-e,s*CY,zz),0.027 if zz>0.6 else 0.022)
        # entry flare guides
        p=[V((CXS[0]-r*0.97,s*CY,0.75)),V((CXS[0]-0.35,s*(CY+0.25),0.75)),V((CXS[0]-0.45,s*(CY+0.30),0.01))]
        b.tube(p[0],p[1],0.024,0.024,sg,'galvanized',cap0=False,cap1=False); b.tube(p[1],p[2],0.024,0.024,sg,'galvanized',cap0=False,cap1=False)
        if not mid:
            P.rec('p',tuple(p[0]),tuple(p[2]),0.024,pts=[tuple(x) for x in p])
            b.box((p[2].x,p[2].y,0),(0.12,0.12,0.01),'galvanized',skip=('bottom',))
            obox(b,(CXS[0],s*CY,0.006),(CXS[-1],s*CY,0.006),0.08,0.012,'galvanized',ends=(True,True),skip=('bottom',))   # ground flat bar
    # closed back end: top + mid rail loop between the two last posts, sign mast with CART RETURN sign
    for zz in (CH-r,0.5):
        e=r*0.97
        b.tube((CXS[-1],-CY+e,zz),(CXS[-1],CY-e,zz),0.027 if zz>0.6 else 0.022,0.027 if zz>0.6 else 0.022,sg,'galvanized',cap0=False,cap1=False)
        if not mid: P.rec('h',(CXS[-1],-CY+e,zz),(CXS[-1],CY-e,zz),0.027)
    b.tube((CXS[-1],0,CH),(CXS[-1],0,2.0),0.03,0.03,sg,'galvanized',cap0=False,cap1=True)
    b.box((CXS[-1],0,1.55),(0.02,1.0,0.42),'paint_white',skip=('bottom',) if not mid else ())
    if not mid:
        P.rec('v',(CXS[-1],0,CH),(CXS[-1],0,2.0),0.03)
        for zz in (1.62,1.88): b.tube((CXS[-1]-0.03,0,zz),(CXS[-1]+0.03,0,zz),0.034,0.034,6,'stainless',cap0=False,cap1=False) if False else b.box((CXS[-1],0,zz-0.02),(0.075,0.075,0.04),'stainless',skip=())
        for x in CXS[1:3]:   # cross ties overhead? no: low cross bar at the back only (carts nest from the open end)
            pass
        if hi:
            for o in (-1,1):
                text(b,'CART',0.14,(CXS[-1]+o*0.0115,0,1.84),(0,-o,0),'paint_red',0.002); text(b,'RETURN',0.14,(CXS[-1]+o*0.0115,0,1.66),(0,-o,0),'paint_red',0.002)
                b.box((CXS[-1]+o*0.0108,0,1.37),(0.001,0.9,0.05),'paint_red',skip=('bottom',))
            for s in (-1,1):
                for x in CXS:
                    for zz in (0.25,0.85): b.tube((x,s*CY,zz),(x,s*CY,zz+0.05),r+0.001,r+0.001,16,'paint_red',cap0=False,cap1=False)   # reflective bands
    if t=='near':
        for s in (-1,1): cbox(b,(0,s*CY,0),(3.72,0.07,CH),rail=True)
        cbox(b,(CXS[-1],0,0),(0.07,2*CY,CH),rail=True); cbox(b,(CXS[-1],0,CH),(0.07,1.0,1.0),rail=True)
def _tilt(b,p0,p1,w,key):
    p0=V(p0); p1=V(p1); d=(p1-p0).normalized(); n=d.cross(V((0,0,1))).normalized(); u=(n+V((0,0,1))).normalized()*(w*0.7071)
    q(b,[p0-u,p1-u,p1+u,p0+u],key,tuple(d.cross(u)))
def corral_far(b):
    # 45-degree rail strips read in both the front and the top view; post cards; sign mast + plate
    for s in (-1,1): _tilt(b,(CXS[0],s*CY,CH-0.03),(CXS[-1],s*CY,CH-0.03),0.07,F)
    _tilt(b,(CXS[0],-CY,0.5),(CXS[-1],-CY,0.5),0.06,F)
    _tilt(b,(CXS[-1],-CY,CH-0.03),(CXS[-1],CY,CH-0.03),0.07,F)
    for x in CXS: q(b,[(x-0.03,-CY,0),(x+0.03,-CY,0),(x+0.03,-CY,2.0 if x==CXS[-1] else CH),(x-0.03,-CY,2.0 if x==CXS[-1] else CH)],F,(0,-1,0))   # end post card runs up the sign mast
    yf=-CY-0.25; x0=CXS[0]   # entry flare guide: two thin wedges
    b.faces([V((x0,yf,0.78)),V((x0-0.33,yf,0.78)),V((x0-0.33,yf,0.72))],[(0,1,2)],F,[[(0,0),(1,0),(1,1)]])
    b.faces([V((x0-0.31,yf,0.78)),V((x0-0.48,yf,0.0)),V((x0-0.42,yf,0.0))],[(0,1,2)],F,[[(0,0),(1,0),(1,1)]])
    q(b,[(CXS[-1],-0.5,1.34),(CXS[-1],0.5,1.34),(CXS[-1],0.5,1.97),(CXS[-1],-0.5,1.97)],F,(-1,0,0))
# ===================================================================== registry
TR_SIGN={'concrete':CONC,'aluminium':ALU,'stainless':ALU}
_D=lambda **k: dict(BASE,**k)
def _n(fn,name): return wrap(fn,name)
PROPS=[
 _D(name='pylon_sign',cls='large',dir='props/batch2/signage',near=_n(pylon_sign,'pylon_sign'),high=lambda b: pylon_sign(b,hi=True),mid=lambda b: pylon_sign(b,t='mid'),far=pylon_far,
    double_far=True,max_side=256,dens=64,trim={'concrete':CONC,'galvanized':GALV,'stucco':PAINT}),
 _D(name='drive_thru_menu',cls='medium',dir='props/batch2/signage',near=_n(drive_thru_menu,'drive_thru_menu'),high=lambda b: drive_thru_menu(b,hi=True),max_side=192,dens=110,trim={'concrete':CONC,'galvanized':GALV}),
 _D(name='bus_stop_sign',cls='medium',dir='props/batch2/signage',near=_n(bus_stop_sign,'bus_stop_sign'),high=lambda b: bus_stop_sign(b,hi=True),max_side=112,dens=160,trim=TR_SIGN),
 _D(name='vending_soda',cls='small',dir='props/batch2/motel',near=_n(vending_soda,'vending_soda'),high=lambda b: vending_soda(b,hi=True),max_side=144,dens=128,trim={'paint_red':PAINT}),
 _D(name='vending_snack',cls='small',dir='props/batch2/motel',near=_n(vending_snack,'vending_snack'),high=lambda b: vending_snack(b,hi=True),max_side=144,dens=128),
 _D(name='ice_chest',cls='small',dir='props/batch2/motel',near=_n(ice_chest,'ice_chest'),high=lambda b: ice_chest(b,hi=True),max_side=128,dens=128,trim={'galvanized':GALV,'paint_white':PAINT}),
 _D(name='wheel_stop_concrete',cls='tiny',dir='props/batch2/parking',near=_n(wheel_stop_concrete,'wheel_stop_concrete'),high=lambda b: wheel_stop_concrete(b,hi=True),max_side=64,dens=160),
 _D(name='wheel_stop_rubber',cls='tiny',dir='props/batch2/parking',near=_n(wheel_stop_rubber,'wheel_stop_rubber'),high=lambda b: wheel_stop_rubber(b,hi=True),max_side=64,dens=160),
 _D(name='shopping_cart',cls='medium',dir='props/batch2/parking',near=_n(shopping_cart,'shopping_cart'),high=lambda b: shopping_cart(b,hi=True),max_side=96,dens=128,trim={'galvanized':GALVL}),
 _D(name='cart_corral',cls='large',dir='props/batch2/parking',near=_n(cart_corral,'cart_corral'),high=lambda b: cart_corral(b,hi=True),mid=lambda b: cart_corral(b,t='mid'),far=corral_far,
    double_far=True,max_side=128,dens=128,trim={'galvanized':GALVL}),
]
# ===================================================================== mid + far tiers for the near-only pieces (03:33 steering: every piece gets mid + far)
F='twf_flat'
def _quad2(b,pts,key,n):   # two-sided quad (mid tiers export single-sided)
    q(b,pts,key,n); q(b,pts,key,tuple(-c for c in n))
def menu_mid(b):
    boxes(b,[('concrete',(0,0,0),(2.9,0.8,0.12)),('brick',(-0.3,0.05,0.12),(2.2,0.42,0.48)),('paint_black',(-0.3,0.05,0.60),(2.36,0.26,1.77))])
    yf=0.05-0.13; x0=-0.3; pw=(2.36-0.24)/3
    for k in range(3):
        a=x0-1.18+0.08+k*(pw+0.04); q(b,[(a,yf-0.002,0.73),(a+pw,yf-0.002,0.73),(a+pw,yf-0.002,2.19),(a,yf-0.002,2.19)],'plastic_white',(0,-1,0))
    q(b,[(x0-1.2,yf-0.21,2.37),(x0+1.2,yf-0.21,2.37),(x0+1.2,yf+0.01,2.40),(x0-1.2,yf+0.01,2.40)],'paint_black',(0,0,1))   # hood
    boxes(b,[('paint_black',(1.18,0,0.12),(0.40,0.16,1.20)),('paint_red',(1.18,-0.05,1.32),(0.56,0.36,0.44)),('paint_yellow',(1.23,-0.55,0.12),(0.12,0.12,1.0))])
def menu_far(b):
    boxes(b,[(F,(0,0,0.0),(2.9,0.8,0.12)),(F,(-0.3,0.05,0.12),(2.4,0.5,2.30))])   # pad + board (speaker post drops out at far)
def bus_mid(b):
    P.TIER['t']='mid'
    b.tube((0,0,0.0),(0,0,3.26),0.032,0.032,4,'galvanized',cap0=False,cap1=True)
    b.box((0.24,-0.045,2.35),(0.45,0.006,0.60),'plastic_white',skip=('bottom','top','left'))
    b.box((0.24,-0.045,2.99),(0.45,0.006,0.32),'paint_white',skip=('bottom','left'))
    b.box((0,-0.075,1.25),(0.26,0.06,0.48),'paint_navy',skip=('back','bottom'))
def bus_far(b):
    q(b,[(-0.035,0,0),(0.035,0,0),(0.035,0,3.26),(-0.035,0,3.26)],F,(0,-1,0))
    q(b,[(0,-0.035,0),(0,0.035,0),(0,0.035,3.26),(0,-0.035,3.26)],F,(-1,0,0))
    q(b,[(0.015,-0.045,2.35),(0.465,-0.045,2.35),(0.465,-0.045,3.31),(0.015,-0.045,3.31)],F,(0,-1,0))
    q(b,[(-0.13,-0.105,1.25),(0.13,-0.105,1.25),(0.13,-0.045,1.73),(-0.13,-0.045,1.73)],F,(0,-1,0.12))   # schedule case: front + top in one card
    for (x0,x1,y0,y1,z) in ((-0.045,0.045,-0.045,0.045,3.26),(0.015,0.465,-0.05,-0.04,3.31)):   # tops (top view): pole cap, flag + route tabs
        q(b,[(x0,y0,z),(x1,y0,z),(x1,y1,z),(x0,y1,z)],F,(0,0,1))
def _vend_mid(W,D,H,body,door):
    def f(b):
        boxes(b,[(body,(0,0,0.0),(W,D,H))])
        yf=-D/2-0.003
        q(b,[(-W/2+0.06,yf,0.5),(W/2-0.30,yf,0.5),(W/2-0.30,yf,H-0.10),(-W/2+0.06,yf,H-0.10)],door,(0,-1,0))
        q(b,[(W/2-0.27,yf,0.5),(W/2-0.05,yf,0.5),(W/2-0.05,yf,H-0.10),(W/2-0.27,yf,H-0.10)],'stainless',(0,-1,0))
        q(b,[(-W/2+0.10,yf,0.12),(W/2-0.32,yf,0.12),(W/2-0.32,yf,0.40),(-W/2+0.10,yf,0.40)],'rubber_black',(0,-1,0))
    return f
def _box_far(W,D,H,cy=0.0,z0=0.0):
    return lambda b: boxes(b,[(F,(0,cy,z0),(W,D,H-z0))])
def ice_mid(b):
    boxes(b,[('galvanized',(0,0,0),(1.30,0.70,0.08)),('paint_white',(0,0,0.08),(1.36,0.78,1.16))])
    for x0 in (-0.64,0.02):
        q(b,[(x0,-0.393,0.30),(x0+0.62,-0.393,0.30),(x0+0.62,-0.393,1.08),(x0,-0.393,1.08)],'paint_navy',(0,-1,0))
def _ws_mid(prof):
    def f(b):
        _extrude(b,prof,-0.915,0.915,'concrete' if len(prof)==6 else 'rubber_black')
    return f
def ws_far(b):
    _extrude(b,[(0.075,0.0),(0.06,0.10),(-0.06,0.10),(-0.075,0.0)][::-1],-0.915,0.915,F)
def cart_mid(b):
    P.TIER['t']='mid'; top,bot=_cart_pts(); W='galvanized'
    for i in range(4):
        a,c=top[i],top[(i+1)%4]; d,e=bot[i],bot[(i+1)%4]; m=(a+c+d+e)/4; n=(m-V((0,0.03,0.78)))
        n.z=0; _quad2(b,[d,e,c,a],W,tuple(n))
    _quad2(b,[bot[0],bot[1],bot[2],bot[3]],W,(0,0,1))
    for s in (-1,1):
        p=[V((s*0.24,0.40,0.11)),V((s*0.26,0.50,BZ1+0.03)),V((s*0.26,0.56,1.03))]
        for i in range(2): b.tube(p[i],p[i+1],0.012,0.012,4,W,cap0=False,cap1=False)
        b.tube(V((s*0.20,-0.36,0.11)),V((s*0.24,0.40,0.11)),0.012,0.012,4,W,cap0=False,cap1=False)
    b.tube(V((-0.27,0.56,1.03)),V((0.27,0.56,1.03)),0.019,0.019,4,'paint_red',cap0=True,cap1=True)
    _quad2(b,[V((-0.20,-0.30,0.15)),V((0.20,-0.30,0.15)),V((0.22,0.36,0.15)),V((-0.22,0.36,0.15))],W,(0,0,1))
    for (x,y) in ((-0.20,-0.33),(0.20,-0.33),(-0.24,0.38),(0.24,0.38)): b.box((x,y+0.02,0.0),(0.03,0.10,0.10),'rubber_black',skip=('bottom','top'))
def cart_far(b):
    top,bot=_cart_pts()
    q(b,[V((-0.27,-0.46,0.0)),V((-0.27,0.56,0.0)),V((-0.27,0.56,1.03)),V((-0.27,-0.46,1.0))],F,(-1,0,0))   # side silhouette card
    q(b,[V((-0.21,-0.46,0.55)),V((0.21,-0.46,0.55)),V((0.27,-0.46,1.0)),V((-0.27,-0.46,1.0))],F,(0,-1,0))  # basket front
    q(b,[V((-0.27,0.56,0.99)),V((0.27,0.56,0.99)),V((0.27,0.56,1.06)),V((-0.27,0.56,1.06))],F,(0,1,0))     # handle
    for s_ in (-1,1): q(b,[V((s_*0.24-0.02,0.45,0.0)),V((s_*0.24+0.02,0.45,0.0)),V((s_*0.26+0.02,0.45,1.03)),V((s_*0.26-0.02,0.45,1.03))],F,(0,1,0))   # frame legs
    q(b,[V((-0.25,-0.33,0.0)),V((0.25,-0.33,0.0)),V((0.25,-0.33,0.16)),V((-0.25,-0.33,0.16))],F,(0,-1,0))   # casters + lower rack
    q(b,[top[0],top[1],top[2],top[3]],F,(0,0,1))
_EXTRA={'drive_thru_menu':(menu_mid,menu_far,False),'bus_stop_sign':(bus_mid,bus_far,True),
 'vending_soda':(_vend_mid(0.95,0.85,1.83,'paint_red','plastic_white'),_box_far(0.95,0.85,1.83),False),
 'vending_snack':(_vend_mid(1.00,0.90,1.83,'paint_black','glass_dark'),_box_far(1.00,0.90,1.83),False),
 'ice_chest':(ice_mid,_box_far(1.36,0.78,1.24),False),
 'wheel_stop_concrete':(_ws_mid([(0.075,0.0),(0.075,0.075),(0.050,0.100),(-0.050,0.100),(-0.075,0.075),(-0.075,0.0)][::-1]),ws_far,False),
 'wheel_stop_rubber':(_ws_mid([(0.075,0.0),(0.075,0.05),(0.045,0.095),(-0.045,0.095),(-0.075,0.05),(-0.075,0.0)][::-1]),ws_far,False),
 'shopping_cart':(cart_mid,cart_far,True)}
for d in PROPS:
    if d['name'] in _EXTRA:
        m,f,dbl=_EXTRA[d['name']]; d['mid']=m; d['far']=f
        if dbl: d['double_far']=True
# page-W slot sizes (budget: batch 2 <= 180k px of page W)
# ===================================================================== 04:46 detail pass: sides / backs of the motel boxes + menu board back
M_=pg.MIRROR
def _side_strip(b,x,o,yc,zc,L,w,ang,key):
    """planar strip on a side face x (normal o along x), direction ang in the y-z plane"""
    d=V((0,math.cos(ang),math.sin(ang))); n=V((0,-math.sin(ang),math.cos(ang))); c=V((x,yc,zc))
    q(b,[c-d*L/2-n*w/2,c+d*L/2-n*w/2,c+d*L/2+n*w/2,c-d*L/2+n*w/2],key,(o,0,0))
def _side_disc(b,x,o,yc,zc,r,key,n=16):
    pts=[V((x,yc+r*math.cos(2*PI*i/n),zc+r*math.sin(2*PI*i/n))) for i in range(n)]
    nn=V((0,0,0))
    for i in range(n): nn+=pts[i].cross(pts[(i+1)%n])
    if nn.x*o<0: pts=pts[::-1]
    b.faces(pts,[tuple(range(n))],key,[[(p.y,p.z) for p in pts]])
def _cord(b,x,yb,z,hi,flip=1):
    """power cord from the rear strain relief down to the floor and out to a moulded plug"""
    pts=[V((x,yb,z)),V((x,yb+0.05,z-0.06)),V((x,yb+0.07,0.012)),V((x+flip*0.22,yb+0.28,0.012)),V((x+flip*0.30,yb+0.42,0.012))]
    b.box((x,yb+0.01,z-0.03),(0.04,0.02,0.06),'plastic_black',skip=('back',))               # strain-relief gland
    for a,c in zip(pts[:-1],pts[1:]): b.tube(a,c,0.007,0.007,8 if hi else 4,'rubber_black',cap0=False,cap1=False)
    e=pts[-1]; d=(pts[-1]-pts[-2]).normalized()
    b.box(e+d*0.03-V((0,0,0.012)),(0.05,0.065,0.03),'plastic_black',rz=math.atan2(d.y,d.x)-PI/2,skip=('bottom',))
    if hi:
        for s in (-1,1): b.box(e+d*0.075+V((-d.y,d.x,0))*s*0.007,(0.004,0.02,0.012),'stainless',rz=math.atan2(d.y,d.x)-PI/2)
def _rear_grille(b,cx,yb,z0,w,h,hi,n=8,key='stainless'):
    b.box((cx,yb+0.006,z0),(w,0.012,h),key,skip=('front',))
    if hi:
        for k in range(n): b.box((cx,yb+0.014,z0+0.03+k*(h-0.06)/(n-1)),(w-0.06,0.006,0.016),'rubber_black',rx=0.5)
        for (x,z) in ((cx-w/2+0.02,z0+0.02),(cx+w/2-0.02,z0+0.02),(cx-w/2+0.02,z0+h-0.02),(cx+w/2-0.02,z0+h-0.02)): nut4(b,(x,yb+0.012,z),(0,1,0),0.006,'stainless',hi)
def _rating_plate(b,cx,yb,z,lines,hi):
    b.box((cx,yb+0.001,z),(0.16,0.002,0.10),'plastic_white',skip=('front',))
    if hi:
        for j,s in enumerate(lines): frontal_text(b,s,0.011,(cx,0,z+0.075-j*0.016),'paint_black',yb+0.0022,back=True,depth=0.0004)
def _kick(b,W,D,z0,hi,yfront):
    """brushed stainless kick plate wrapping front + sides (scuffed), on the base"""
    q(b,[(-W/2,yfront-0.004,z0),(W/2,yfront-0.004,z0),(W/2,yfront-0.004,z0+0.10),(-W/2,yfront-0.004,z0+0.10)],'stainless',(0,-1,0))
    b.cur_sym=M_
    for s in (-1,1): q(b,[(s*(W/2+0.004),-D/2,z0),(s*(W/2+0.004),D/2-0.05,z0),(s*(W/2+0.004),D/2-0.05,z0+0.10),(s*(W/2+0.004),-D/2,z0+0.10)],'stainless',(s,0,0))
    b.cur_sym=1
    if hi:
        rr=random.Random(11)
        for k in range(9):   # shoe scuffs + dents
            b.box((rr.uniform(-W/2+0.08,W/2-0.08),yfront-0.0048,z0+rr.uniform(0.02,0.08)),(rr.uniform(0.03,0.12),0.0008,rr.uniform(0.004,0.012)),'rubber_black',skip=('back',),rx=0,rz=0)
        for x in (-W/2+0.03,W/2-0.03): nut4(b,(x,yfront-0.004,z0+0.05),(0,-1,0),0.005,'stainless',hi)
def _levelers(b,W,D,hi):
    for sx in (-1,1):
        for sy in (-1,1): b.tube((sx*(W/2-0.06),sy*(D/2-0.06),0.03),(sx*(W/2-0.06),sy*(D/2-0.06),0.042),0.022,0.022,6,'stainless',cap0=False,cap1=False,smooth=False)
def _standoffs(b,W,yb,H):
    for s in (-1,1): b.box((s*(W/2-0.08),yb+0.03,H-0.12),(0.06,0.06,0.06),'rubber_black',skip=('front',))
def soda_x(b,hi=False,t='near'):
    vending_soda(b,hi,t); W,D,H=0.95,0.85,1.83; z0=0.04; yf=-D/2; yb=D/2
    # side branding panels (bilateral: both sides share texels, so the art is abstract: swoosh, crown disc, bottle)
    b.cur_sym=M_
    for s in (-1,1):
        x=s*(W/2+0.003); q(b,[(x,-D/2+0.04,z0+0.16),(x,D/2-0.06,z0+0.16),(x,D/2-0.06,H-0.08),(x,-D/2+0.04,H-0.08)],'plastic_white',(s,0,0))
        if hi:
            x2=s*(W/2+0.0045); q(b,[(x2,-D/2+0.045,z0+0.165),(x2,D/2-0.065,z0+0.165),(x2,D/2-0.065,H-0.085),(x2,-D/2+0.045,H-0.085)],'paint_red',(s,0,0))
            x3=s*(W/2+0.006)
            for k in range(8):   # white swoosh + yellow pinstripe (sine)
                y_a=-D/2+0.05+k*(D-0.12)/8; y_c=y_a+(D-0.12)/8; ym=(y_a+y_c)/2
                za=0.95+0.12*math.sin(ym*6); zc=0.95+0.12*math.sin(y_c*6)
                ang=math.atan2(0.12*6*math.cos(ym*6),1.0)
                _side_strip(b,x3,s,ym,(za+zc)/2,(y_c-y_a)*1.06,0.09,ang,'plastic_white')
                _side_strip(b,s*(W/2+0.0068),s,ym,(za+zc)/2-0.07,(y_c-y_a)*1.06,0.018,ang,'paint_yellow')
            _side_disc(b,x3,s,0.05,1.45,0.17,'paint_yellow',24); _side_disc(b,s*(W/2+0.0068),s,0.05,1.45,0.14,'paint_red',24)
            for k in range(5): _side_strip(b,s*(W/2+0.0074),s,0.05-0.08+k*0.04,1.47,0.07,0.022,PI/2,'paint_yellow')   # crown points
            prof=[(0.0,0.03),(0.05,0.07),(0.30,0.07),(0.40,0.03),(0.48,0.025)]   # bottle silhouette (z, half width)
            for (za,ra),(zc,rc) in zip(prof[:-1],prof[1:]):
                q(b,[(x3,0.25-ra,0.30+za),(x3,0.25+ra,0.30+za),(x3,0.25+rc,0.30+zc),(x3,0.25-rc,0.30+zc)],'glass_dark',(s,0,0))
            _side_strip(b,s*(W/2+0.0068),s,0.25,0.48,0.14,0.07,0,'plastic_white')
    b.cur_sym=1
    _kick(b,W,D,z0,hi,yf)
    _rear_grille(b,0.0,yb,z0+0.10,0.62,0.34,hi)
    _rating_plate(b,-0.25,yb,H-0.35,['CROWN BEVERAGE CO','MODEL CV-600','115V  60HZ  9.0A','SER 4417-0921'],hi)
    _standoffs(b,W,yb,H); _levelers(b,W,D,hi); _cord(b,0.2,yb,z0+0.30,hi)
    # bill + coin mech bezel: raised black bezel with a chrome surround, lit bill slot, chrome coin cup
    xm=W/2-0.125
    b.box((xm,yf-0.075,z0+0.53),(0.13,0.018,0.07),'paint_black',skip=('back',))
    b.box((xm,yf-0.085,z0+0.555),(0.09,0.004,0.008),'plastic_white',skip=('back',))
    b.tube((xm+0.045,yf-0.075,z0+0.64),(xm+0.045,yf-0.088,z0+0.64),0.018,0.014,8 if hi else 6,'stainless',cap0=False,cap1=True)
    if hi:
        b.box((xm,yf-0.0865,z0+0.575),(0.02,0.001,0.006),'paint_green',skip=('back',))   # bill LED
        frontal_text(b,'$1  $5',0.012,(xm,0,z0+0.535),'plastic_white',yf-0.0845)
def snack_x(b,hi=False,t='near'):
    vending_snack(b,hi,t); W,D,H=1.00,0.90,1.83; z0=0.04; yf=-D/2; yb=D/2
    b.cur_sym=M_
    rr=random.Random(5)
    for s in (-1,1):
        x=s*(W/2+0.003); q(b,[(x,-D/2+0.04,z0+0.16),(x,D/2-0.06,z0+0.16),(x,D/2-0.06,H-0.08),(x,-D/2+0.04,H-0.08)],'plastic_white',(s,0,0))
        if hi:
            rr=random.Random(5)
            x2=s*(W/2+0.0045); q(b,[(x2,-D/2+0.045,z0+0.165),(x2,D/2-0.065,z0+0.165),(x2,D/2-0.065,H-0.085),(x2,-D/2+0.045,H-0.085)],'plastic_blue',(s,0,0))
            x3=s*(W/2+0.006)
            _side_strip(b,x3,s,0.0,H-0.22,D-0.14,0.16,0,'paint_yellow')        # header band
            cols=['paint_red','paint_yellow','plastic_orange','paint_green','paint_white']
            for k in range(9):   # tumbling snack packs
                _side_strip(b,s*(W/2+0.0062+0.0003*k),s,rr.uniform(-0.3,0.25),rr.uniform(0.55,1.35),rr.uniform(0.13,0.2),rr.uniform(0.18,0.26),rr.uniform(-0.6,0.6),cols[k%5])
            for k in range(12): _side_strip(b,s*(W/2+0.0055),s,0.18,0.55,0.34,0.03,k*PI/12,'paint_yellow')   # starburst
            _side_disc(b,s*(W/2+0.0058),s,0.18,0.55,0.11,'paint_red',16)
    b.cur_sym=1
    _kick(b,W,D,z0,hi,yf)
    _rear_grille(b,0.0,yb,z0+0.10,0.66,0.34,hi)
    _rating_plate(b,0.25,yb,H-0.35,['CROWN VENDING','MODEL SN-5','115V  60HZ  4.5A','SER 5532-1188'],hi)
    _standoffs(b,W,yb,H); _levelers(b,W,D,hi); _cord(b,-0.2,yb,z0+0.30,hi,flip=-1)
    xm=W/2-0.15; gz0=z0+0.46   # bill acceptor + coin insert bezel on the payment panel
    b.box((xm,yf-0.03,gz0+0.22),(0.13,0.02,0.07),'paint_black',skip=('back',))
    b.box((xm,yf-0.041,gz0+0.24),(0.09,0.004,0.008),'plastic_white',skip=('back',))
    b.tube((xm+0.04,yf-0.012,gz0+0.70),(xm+0.04,yf-0.026,gz0+0.70),0.016,0.012,8 if hi else 6,'stainless',cap0=False,cap1=True)
    b.box((xm,yf-0.022,gz0+0.12),(0.08,0.02,0.05),'stainless',skip=('back',))   # coin return
    if hi: b.box((xm,yf-0.0415,gz0+0.26),(0.02,0.001,0.006),'paint_green',skip=('back',))
def ice_x(b,hi=False,t='near'):
    ice_chest(b,hi,t); W,D,H=1.36,0.78,1.24; yf=-D/2; yb=D/2; zt=H-0.06
    # side branding (bilateral; abstract: blue band, ice cubes, snowflake) + base grime band, sides and back
    b.cur_sym=M_
    for s in (-1,1):
        x=s*(W/2+0.003)
        q(b,[(x,yf+0.02,0.30),(x,yb-0.03,0.30),(x,yb-0.03,1.10),(x,yf+0.02,1.10)],'plastic_white',(s,0,0))
        q(b,[(x,yf+0.02,0.08),(x,yb-0.03,0.08),(x,yb-0.03,0.26),(x,yf+0.02,0.26)],'plastic_white',(s,0,0))
        if hi:
            x3=s*(W/2+0.0045)
            _side_strip(b,x3,s,0.0,0.52,D-0.10,0.14,0,'plastic_blue')
            for k,(yc,zc,a) in enumerate(((-0.20,0.80,0.2),(-0.05,0.86,-0.3),(-0.13,0.95,0.5))):   # cubes
                _side_strip(b,s*(W/2+0.005+0.0004*k),s,yc,zc,0.10,0.10,a,'plastic_blue'); _side_strip(b,s*(W/2+0.0058+0.0004*k),s,yc,zc,0.075,0.075,a,'glass_dark')
            for k in range(3):   # snowflake
                a=k*PI/3; _side_strip(b,s*(W/2+0.005),s,0.18,0.86,0.30,0.018,a,'plastic_blue')
                for e in (-1,1):
                    c=V((0,0.18+math.cos(a)*0.10*e,0.86+math.sin(a)*0.10*e))
                    for bb in (-0.5,0.5): _side_strip(b,s*(W/2+0.0054),s,c.y,c.z,0.07,0.012,a+bb*PI/1.5,'plastic_blue')
            rr=random.Random(7)
            for k in range(26):   # splash grime at the base
                _side_strip(b,s*(W/2+0.0046+0.0001*k),s,rr.uniform(yf+0.05,yb-0.06),rr.uniform(0.09,0.12+0.10*rr.random()),rr.uniform(0.03,0.12),rr.uniform(0.01,0.05),rr.uniform(-0.3,0.3),['paint_beige','stone','paint_bronze'][k%3])
    b.cur_sym=1
    q(b,[(-W/2+0.02,yb+0.003,0.08),(W/2-0.02,yb+0.003,0.08),(W/2-0.02,yb+0.003,0.26),(-W/2+0.02,yb+0.003,0.26)],'plastic_white',(0,1,0))
    if hi:
        rr=random.Random(9)
        for k in range(20): b.box((rr.uniform(-W/2+0.06,W/2-0.06),yb+0.0045,rr.uniform(0.09,0.18)),(rr.uniform(0.04,0.14),0.001,rr.uniform(0.01,0.05)),['paint_beige','stone','paint_bronze'][k%3],rx=0)
    # rear compressor louvres (condensing unit bay) with a grille frame, rating plate, cord
    b.box((0.0,yb+0.005,0.30),(0.96,0.010,0.36),'stainless',skip=('front',))
    for k in range(6): obox(b,(-0.44,yb+0.02,0.35+k*0.052),(0.44,yb+0.02,0.35+k*0.052),0.02,0.03,'paint_white',up=(0,0.5,1),ends=(False,False),skip=('bottom',))
    _rating_plate(b,0.45,yb,0.95,['CROWN ICE SYSTEMS','MODEL IM-50','R-404A  115V 7A','SER 6610-0244'],hi)
    _cord(b,-0.55,yb,0.30,hi,flip=-1)
    # top: door pivot hinges at the outer top corners, sealed top panel (salt + dust bloom via wx), centre mullion cap
    for sx in (-1,1):
        b.box((sx*(W/2-0.05),yf+0.04,H),(0.07,0.07,0.014),'aluminium',skip=('bottom',))
        b.tube((sx*(W/2-0.05),yf+0.02,H),(sx*(W/2-0.05),yf+0.02,H+0.026),0.008,0.008,6,'stainless',cap0=False,cap1=True)
    q(b,[(-W/2+0.03,yf+0.09,H+0.002),(W/2-0.03,yf+0.09,H+0.002),(W/2-0.03,yb-0.03,H+0.002),(-W/2+0.03,yb-0.03,H+0.002)],'plastic_white',(0,0,1))
    if hi:
        for k in range(1,4): b.box((-W/2+k*W/4,0.05,H+0.002),(0.004,D-0.16,0.0015),'stone')     # panel seams
        rr=random.Random(13)
        for k in range(14): b.box((rr.uniform(-0.6,0.6),rr.uniform(-0.25,0.33),H+0.0025),(rr.uniform(0.05,0.2),rr.uniform(0.03,0.12),0.0008),['paint_beige','stone'][k%2],rz=rr.uniform(0,PI))
        for x in (-0.62,0.62):
            for y in (yf+0.11,yb-0.05): nut4(b,(x,y,H+0.002),(0,0,1),0.005,'stainless',hi)
    # door gasket lines (black rubber reveal around each door), hasp staple + second hasp leaf
    for sx in (-1,1):
        cx=sx*W/4; hw=(W/2-0.06)/2; z0d,z1d=0.40,zt-0.04
        for pts in (((cx-hw-0.012,z0d-0.012),(cx+hw+0.012,z0d)),((cx-hw-0.012,z1d),(cx+hw+0.012,z1d+0.012)),((cx-hw-0.012,z0d),(cx-hw,z1d)),((cx+hw,z0d),(cx+hw+0.012,z1d))):
            (xa,za),(xc,zc)=pts; q(b,[(xa,yf-0.004,za),(xc,yf-0.004,za),(xc,yf-0.004,zc),(xa,yf-0.004,zc)],'rubber_black',(0,-1,0))
    b.box((0.035,yf-0.04,0.83),(0.03,0.012,0.10),'stainless',skip=('back',))
    b.tube((-0.012,yf-0.05,0.80),(-0.012,yf-0.07,0.80),0.006,0.006,6,'stainless',cap0=False,cap1=False)
def menu_x(b,hi=False,t='near'):
    drive_thru_menu(b,hi,t); x0=-0.3; W,H,D,Z=2.36,1.72,0.26,0.65; yb=0.05+D/2; pw=(W-0.16-0.08)/3
    # rear: three hinged access panels with latches and a high-voltage label, cooling louvres
    for k in range(3):
        a=x0-W/2+0.08+k*(pw+0.04); c=a+pw; cx=(a+c)/2
        b.box((cx,yb+0.002,Z+0.10),(pw-0.02,0.004,H-0.30),'paint_black',skip=('front',))
        b.tube((a+0.012,yb+0.008,Z+0.14),(a+0.012,yb+0.008,Z+H-0.24),0.007,0.007,6,'stainless',cap0=True,cap1=True)   # piano hinge
        for zz in (Z+0.35,Z+H-0.45):
            b.box((c-0.05,yb+0.012,zz),(0.03,0.016,0.06),'stainless',skip=('front',))
        b.box((cx,yb+0.0045,Z+H-0.36),(0.14,0.002,0.08),'paint_yellow',skip=('front',))
        if hi:
            frontal_text(b,'DANGER 120V',0.018,(cx,0,Z+H-0.33),'paint_black',yb+0.0056,back=True,depth=0.0004)
            frontal_text(b,f'PANEL {k+1}',0.014,(cx,0,Z+H-0.37),'paint_black',yb+0.0056,back=True,depth=0.0004)
            for zz in (Z+0.35,Z+H-0.45): b.tube((c-0.05,yb+0.02,zz),(c-0.05,yb+0.022,zz),0.006,0.006,12,'rubber_black',cap1=True)
            for j in range(8): b.box((cx,yb+0.0045,Z+0.25+j*0.03),(pw*0.5,0.001,0.012),'rubber_black',rx=0.4)   # vent louvres
            rr=random.Random(20+k)
            for j in range(5): b.box((cx+rr.uniform(-pw/3,pw/3),yb+0.0042,Z+rr.uniform(0.15,0.6)),(0.004,0.0006,rr.uniform(0.15,0.4)),'stone')   # weather streaks
    # electrical disconnect box with conduit to the island pad, two straps, coupling; anchor clips + bolts at the cabinet base
    ex=x0+0.80; b.box((ex,0.27,Z+0.05),(0.30,0.18,0.40),'galvanized',skip=('front',))
    b.box((ex+0.16,0.30,Z+0.25),(0.025,0.04,0.12),'paint_red',skip=())                     # disconnect handle
    b.box((ex,0.361,Z+0.30),(0.12,0.002,0.07),'paint_yellow',skip=('front',))
    b.tube((ex,0.32,Z+0.05),(ex,0.32,0.12),0.021,0.021,8 if hi else 6,'galvanized',cap0=False,cap1=False)
    for zz in (0.18,Z-0.05): b.tube((ex,0.32,zz),(ex,0.32,zz+0.04),0.027,0.027,8 if hi else 6,'galvanized',cap0=True,cap1=True)
    for zz in (0.32,0.52): b.box((ex,0.30,zz),(0.07,0.08,0.012),'galvanized',skip=())       # one-hole straps back to the pedestal
    if hi:
        frontal_text(b,'DISCONNECT',0.016,(ex,0,Z+0.34),'paint_black',0.3622,back=True,depth=0.0004)
        for (x,z) in ((ex-0.12,Z+0.08),(ex+0.12,Z+0.08),(ex-0.12,Z+0.42),(ex+0.12,Z+0.42)): nut4(b,(x,0.36,z),(0,1,0),0.006,'stainless',hi)
    for x in (x0-0.9,x0-0.3,x0+0.3,x0+0.9):
        for yy,o in ((yb,1),(0.05-D/2,-1)):
            if o>0 and abs(x-ex)<0.25: continue
            b.box((x,yy+o*0.012,Z),(0.08,0.024,0.05),'galvanized',skip=('bottom',))
            nut4(b,(x,yy+o*0.024,Z+0.025),(0,o,0),0.009,'galvanized',hi)
    b.box((1.18,0.0,0.12),(0.24,0.24,0.012),'galvanized',skip=('bottom',))                  # speaker post base plate
    for sx_ in (-1,1):
        for sy_ in (-1,1): nut4(b,(1.18+sx_*0.09,sy_*0.09,0.132),(0,0,1),0.009,'galvanized',hi)
_WXW={'salt':0.06,'edge':0.40,'streak':0.25,'pit':0.4}
for d in PROPS:
    fn={'vending_soda':soda_x,'vending_snack':snack_x,'ice_chest':ice_x,'drive_thru_menu':menu_x}.get(d['name'])
    if fn:
        d['near']=wrap(fn,d['name']); d['high']=(lambda f: (lambda b: f(b,hi=True)))(fn); d['wx']=_WXW
_SIDE={'pylon_sign':256,'drive_thru_menu':144,'bus_stop_sign':96,'vending_soda':160,'vending_snack':160,'ice_chest':128,'wheel_stop_concrete':48,'wheel_stop_rubber':48,'shopping_cart':64,'cart_corral':96}
for d in PROPS: d['max_side']=_SIDE[d['name']]
fin(PROPS,keep=(('wheel_stop_rubber','rubber_black'),('drive_thru_menu','paint_black'),('bus_stop_sign','galvanized')))
