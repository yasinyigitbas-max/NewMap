"""Waterfront set 6: small props. Builder coords Z up, front = -Y, origin = bottom centre (z 0 = the surface it stands on).
Water pieces (buoy_*) use the harbour datum: z 0 = bed, WL 1.5 (sinker on the bed, float at the waterline).
Shared page-W trims (gelcoat / canvas / galv / teak / timber / rubber / foul) carry the surfaces; only signs, number plates,
lettering and small castings bake into each prop's patch (48-64 px); all-trim pieces have no slot (no_bake)."""
import math
from mathutils import Vector, Matrix
import pg
import wf_parts as P
import b_wfpier as WP
from wf_parts import PI, cbox, ccyl, bolt_head
from wf_boat import face, Hull, deck, wire, cleat_small
V=Vector
def xf_since(b,n0,M):
    b.bm.verts.ensure_lookup_table()
    for v in b.bm.verts[n0:]: v.co=M@v.co
def plate(b,c,w,h,normal,txt=None,sub=None,hi=False,key='plastic_white',tkey='paint_navy',ts=0.6):
    """baked sign plate (proud quad) with optional lettering (high-poly only -> bake)"""
    c=V(c); n=V(normal).normalized(); up=V((0,0,1)) if abs(n.z)<0.9 else V((0,1,0)); u=up.cross(n).normalized()*-1; u=n.cross(up).normalized()*-1
    u=-n.cross(up).normalized()
    pts=[c-u*w/2-up*h/2,c+u*w/2-up*h/2,c+u*w/2+up*h/2,c-u*w/2+up*h/2]
    face(b,pts,key,tuple(n))
    if hi and txt:
        pg.add_text(b,txt,h*ts*(0.75 if sub else 1.0),tuple(c+n*0.0015+up*(h*0.15 if sub else 0)),tuple(u),tuple(up),0.0008,tkey)
        if sub: pg.add_text(b,sub,h*0.2,tuple(c+n*0.0015-up*h*0.28),tuple(u),tuple(up),0.0007,tkey)
def ringt(b,c,R,r,n,keys,axis='y',seg=4,phase=0.0):
    """torus in the plane normal to axis, split into len(keys) arcs (alternating colour bands)"""
    c=V(c); k=len(keys); per=n//k
    for j,key in enumerate(keys):
        pts=[]
        for i in range(per+1):
            a=phase+2*PI*(j*per+i)/n
            d=V((math.cos(a),0,math.sin(a))) if axis=='y' else (V((0,math.cos(a),math.sin(a))) if axis=='x' else V((math.cos(a),math.sin(a),0)))
            pts.append(c+d*R)
        b.sweep(pts,r,seg,key,cap0=False,cap1=False)
def chain(b,p0,p1,sag,n,key='cast_iron',hi=False):
    """stud-less chain as alternating flat links along a sagging path p0->p1"""
    p0=V(p0); p1=V(p1); pts=[p0+(p1-p0)*(i/n)+V((0,0,-sag*4*(i/n)*(1-i/n))) for i in range(n+1)]
    for i in range(n):
        a,c=pts[i],pts[i+1]; d=(c-a); up=V((0,1,0)) if i%2 else V((1,0,0))
        if abs(d.normalized().dot(up))>0.9: up=V((0,0,1))
        WP.obox(b,a,c,0.030,0.010,key,up=tuple(up),ends=(False,False))
    return pts
# ===================================================================== life-ring stand
def lifering(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'
    PH=1.75
    b.box((0,0,0.012 if not mid else 0),(0.08,0.08,PH),'galvanized',skip=('bottom',))
    if not mid:
        b.box((0,0,0),(0.20,0.20,0.012),'galvanized',skip=('bottom',))
        for dx in (-0.07,0.07):
            for dy in (-0.07,0.07):
                if hi: bolt_head(b,(dx,dy,0.012),(0,0,1),0.008,'galvanized',hi)
                else: b.box((dx,dy,0.012),(0.018,0.018,0.008),'galvanized',skip=('bottom',))
        b.box((0,0,PH+0.012),(0.10,0.10,0.012),'galvanized',skip=())                                   # cap
    # sign board on two brackets, front
    b.box((0,-0.05,PH-0.36),(0.48,0.012,0.32),'galvanized',skip=('front',) if not mid else ())
    plate(b,(0,-0.0565,PH-0.20),0.46,0.30,(0,-1,0),'LIFE RING','IN EMERGENCY  THROW  CALL 911',hi,tkey='paint_red',ts=0.5)
    # ring on two stainless pins, red/white bands, grab line with 4 seizings, throw-line coil on a hook
    rc=V((0,-0.10,0.92)); R=0.30; rr=0.05
    n=16 if not mid else 8
    ringt(b,rc,R,rr,n,['plastic_orange','wood_white']*2 if not mid else ['plastic_orange'],axis='y',seg=6 if not mid else 4,phase=PI/4)
    for sx in (-1,1): b.tube(V((sx*0.18,-0.04,rc.z+0.24)),V((sx*0.18,-0.16,rc.z+0.24)),0.010,0.010,4,'stainless',cap0=False,cap1=True)
    if not mid:
        gl=[rc+V((R*1.18*math.cos(a),-0.0,R*1.18*math.sin(a))) for a in [2*PI*i/16 for i in range(17)]]
        gl=[q if i%4 else rc+V(((q-rc).x/1.18,0,(q-rc).z/1.18)) for i,q in enumerate(gl)]
        b.sweep(gl,0.007,3,'paint_beige',cap0=False,cap1=False)
        # heaving line: made fast to the bottom seizing, hanging as a coiled loop in front of the post
        tb=rc+V((0,0,-R)); m=10; cc=tb+V((0,-0.01,-0.15))
        loop=[tb]+[cc+V((0.13*math.sin(2*PI*i/m),-0.012*math.cos(2*PI*i/m),0.15*math.cos(2*PI*i/m))) for i in range(1,m)]+[tb]
        b.sweep(loop,0.018,4,'paint_beige',cap0=False,cap1=False)
        b.sweep([tb+V((-0.03,0,0.01)),tb+V((0.0,-0.02,-0.03)),tb+V((0.03,0,0.01))],0.012,4,'paint_beige',cap0=False,cap1=False)   # hitch round the ring
        plate(b,(0,0.0415,1.25),0.16,0.10,(0,1,0),'STAND','NO. 4',hi,tkey='paint_navy',ts=0.45)
    if tier=='near': ccyl(b,(0,0,0),0.06,PH+0.03,rail=True); cbox(b,(0,-0.10,0.55),(0.72,0.14,0.74))
def lifering_far(b):
    face(b,[V((-0.05,0,0)),V((0.05,0,0)),V((0.05,0,1.76)),V((-0.05,0,1.76))],'twf_flat',(0,-1,0))
    face(b,[V((-0.24,-0.06,1.39)),V((0.24,-0.06,1.39)),V((0.24,-0.06,1.71)),V((-0.24,-0.06,1.71))],'twf_flat',(0,-1,0))
    c=V((0,-0.10,0.92)); R=0.35
    face(b,[c+V((R*math.cos(a),0,R*math.sin(a))) for a in [PI/8+2*PI*i/8 for i in range(8)]],'twf_flat',(0,-1,0))
    face(b,[V((-0.33,-0.15,1.25)),V((0.33,-0.15,1.25)),V((0.33,-0.06,1.25)),V((-0.33,-0.06,1.25))],'twf_flat',(0,0,1))     # ring (plan)
    face(b,[V((-0.24,-0.058,1.72)),V((0.24,-0.058,1.72)),V((0.24,-0.042,1.72)),V((-0.24,-0.042,1.72))],'twf_flat',(0,0,1))     # board (plan)
    face(b,[V((-0.05,-0.05,1.78)),V((0.05,-0.05,1.78)),V((0.05,0.05,1.78)),V((-0.05,0.05,1.78))],'twf_flat',(0,0,1))         # post cap (plan)
# ===================================================================== buoys (harbour datum: bed z 0, WL 1.5)
BWL=1.5
def _sinker(b,c,mid,mush=False):
    x,y,z=c
    if mush: b.lathe([(0.32,0.0),(0.30,0.10),(0.12,0.16),(0.05,0.18),(0.05,0.40),(0.0,0.41)] if not mid else [(0.32,0.0),(0.1,0.16),(0.04,0.40),(0.0,0.41)],8 if not mid else 6,'cast_iron',c=(x,y,0),cap_top=False)
    else:
        b.box((x,y,0),(0.55,0.55,0.30),'concrete',skip=('bottom',))
        b.lathe([(0.04,0.30),(0.04,0.40),(0.0,0.40)],6,'cast_iron',c=(x,y,0),cap_top=False) if not mid else None
    return V((x,y,0.40 if not mush else 0.41))
def buoy_mooring(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'
    R=0.40; zc=BWL+0.08; seg=12 if not mid else 8
    ang=[-PI/2+PI*i/6 for i in range(7)] if not mid else [-PI/2+PI*i/4 for i in range(5)]
    prof=[(max(0.0,R*math.cos(a)),zc+R*math.sin(a)) for a in ang]
    bands=[('paint_black',lambda z: z<BWL+0.02),('plastic_blue',lambda z: abs(z-zc)<0.15),('paint_white',lambda z: True)]
    for j in range(len(prof)-1):
        zm=(prof[j][1]+prof[j+1][1])/2; key=next(k for k,f in bands if f(zm))
        b.lathe([prof[j],prof[j+1]],seg,key,c=(0,0,0),cap_top=False)
    # through-rod with top eye + bottom swivel, pickup pennant float with number tag
    b.tube(V((0,0,zc+R-0.01)),V((0,0,zc+R+0.10)),0.025,0.025,6,'galvanized',cap0=False,cap1=False)
    if not mid:
        ringt(b,(0,0,zc+R+0.16),0.06,0.012,8,['galvanized'],axis='y',seg=4)
        b.tube(V((0,0,zc-R+0.01)),V((0,0,zc-R-0.10)),0.03,0.03,6,'galvanized',cap0=False,cap1=True)
        pf=V((0.55,0.15,BWL))
        b.lathe([(0.07,BWL-0.06),(0.08,BWL+0.10),(0.05,BWL+0.16),(0.0,BWL+0.17)],8,'plastic_orange',c=(pf.x,pf.y,0),cap_top=False)
        b.tube(pf+V((0,0,0.16)),pf+V((0,0,0.95)),0.012,0.010,4,'paint_white',cap0=False,cap1=True)
        plate(b,pf+V((0,-0.008,0.82)),0.10,0.16,(0,-1,0),'22','CYH',hi,tkey='paint_navy',ts=0.55)
        plate(b,pf+V((0,0.008,0.82)),0.10,0.16,(0,1,0),'22','CYH',hi,tkey='paint_navy',ts=0.55)
        b.sweep([V((0,0,zc+R+0.16)),V((0.25,0.08,BWL+0.02)),pf+V((0,0,0.05))],0.010,3,'paint_beige',cap0=False,cap1=False)   # pennant
    top=_sinker(b,(0.0,0.9,0),mid,mush=True)
    if mid: b.tube(V((0,0,zc-R)),top,0.02,0.02,3,'cast_iron',cap0=False,cap1=False)
    else: chain(b,V((0,0,zc-R-0.10)),top,0.15,12,hi=hi)
    if tier=='near': ccyl(b,(0,0,BWL-0.35),R,0.85,rail=True); cbox(b,(0,0.9,0),(0.64,0.64,0.42))
def buoy_mooring_far(b):
    zc=BWL+0.08; R=0.42
    face(b,[V((R*math.cos(a),0,zc+R*math.sin(a))) for a in [-PI/2+2*PI*i/8 for i in range(8)]],'twf_flat',(0,-1,0))
    face(b,[V((R*math.cos(a),R*math.sin(a),zc+0.01)) for a in [2*PI*i/6 for i in range(6)]],'twf_flat',(0,0,1))
    face(b,[V((-0.32,0.9,0.0)),V((0.32,0.9,0.0)),V((0.08,0.9,0.16)),V((-0.08,0.9,0.16))],'twf_flat',(0,-1,0))              # mushroom sinker
    face(b,[V((-0.04,0.45,0.16)),V((0.04,0.45,0.16)),V((0.04,0.45,zc-R)),V((-0.04,0.45,zc-R))],'twf_flat',(0,-1,0))         # chain
    face(b,[V((-0.27,0.63,0.42)),V((0.27,0.63,0.42)),V((0.27,1.17,0.42)),V((-0.27,1.17,0.42))],'twf_flat',(0,0,1))          # sinker (plan)
def _marker(b,hi,tier,nun,num,col):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'
    R=0.42; z0=BWL-0.55; z1=BWL+0.65; seg=10 if not mid else 6
    b.lathe([(0.10,z0-0.02),(R,z0),(R,BWL)],seg,'paint_black',c=(0,0,0),cap_top=False,phase=PI/seg)             # fouled underwater body
    if nun:
        b.lathe([(R,BWL),(R,z1-0.35),(0.30,z1-0.12),(0.10,z1+0.25),(0.0,z1+0.30)] if not mid else [(R,BWL),(R,z1-0.35),(0.0,z1+0.30)],seg,col,c=(0,0,0),cap_top=False,phase=PI/seg)
    else:
        b.lathe([(R,BWL),(R,z1),(R-0.03,z1+0.03),(0.0,z1+0.03)] if not mid else [(R,BWL),(R,z1),(0.0,z1)],seg,col,c=(0,0,0),cap_top=False,phase=PI/seg)
    zt=z1+(0.30 if nun else 0.03)
    if not mid:
        for sx in (-1,1):   # lifting lugs
            b.box((sx*0.20,0,(z1+0.03 if not nun else z1-0.30)),(0.03,0.10,0.10),'galvanized',skip=('bottom',))
        b.lathe([(0.06,BWL+0.38),(0.06,BWL+0.40),(0.0,BWL+0.40)],6,'galvanized',c=(0,0,0),cap_top=False) if False else None
        zn=BWL+0.32
        for ny in (-1,1):   # retro-reflective number boards, both faces
            n_=V((0,ny,0)); c=V((0,ny*(R*math.cos(PI/seg)+0.004),zn))
            plate(b,c,0.34,0.36,(0,ny,0),num,None,hi,key='plastic_white',tkey='paint_black' if True else col,ts=0.8)
        b.box((0,0,zt),(0.04,0.04,0.34),'galvanized',skip=('bottom',))                                          # daymark/radar reflector mast
        for k in range(2): b.box((0,0,zt+0.12+k*0.09),(0.20,0.004,0.09),'galvanized',skip=(),rz=k*PI/2)       # radar reflector vanes
        b.lathe([(0.04,zt+0.34),(0.04,zt+0.40),(0.0,zt+0.42)],6,'glass_dark',c=(0,0,0),cap_top=False)
        for k in range(5): b.tube(V((0,0,zt+0.42)),V((0.05*math.cos(k*1.26),0.05*math.sin(k*1.26),zt+0.50)),0.002,0.002,3,'stainless',cap0=False,cap1=True)   # bird spikes
    b.tube(V((0,0,z0-0.02)),V((0,0,z0-0.55)),0.07,0.07,6 if not mid else 4,'paint_black',cap0=False,cap1=True)   # counterweight tube
    top=_sinker(b,(0.0,1.1,0),mid)
    if mid: b.tube(V((0,0,z0-0.55)),top,0.02,0.02,3,'cast_iron',cap0=False,cap1=False)
    else: chain(b,V((0,0,z0-0.57)),top,0.08,10,hi=hi)
    if tier=='near': ccyl(b,(0,0,z0-0.55),R,zt-z0+0.95,rail=True); cbox(b,(0,1.1,0),(0.56,0.56,0.42))
def _marker_far(b,nun):
    R=0.44; z0=BWL-0.55; z1=BWL+0.65; zt=z1+(0.30 if nun else 0.03)
    if nun: face(b,[V((-0.10,0,z0-0.02)),V((0.10,0,z0-0.02)),V((R,0,z0)),V((R,0,z1-0.35)),V((0.0,0,z1+0.30)),V((-R,0,z1-0.35)),V((-R,0,z0))],'twf_flat',(0,-1,0))
    else: face(b,[V((-0.10,0,z0-0.02)),V((0.10,0,z0-0.02)),V((R,0,z0)),V((R,0,z1)),V((-R,0,z1)),V((-R,0,z0))],'twf_flat',(0,-1,0))
    face(b,[V((R*math.cos(a),R*math.sin(a),z1+0.01)) for a in [2*PI*i/6 for i in range(6)]],'twf_flat',(0,0,1))
    face(b,[V((-0.07,0,z0-0.55)),V((0.07,0,z0-0.55)),V((0.07,0,z0-0.02)),V((-0.07,0,z0-0.02))],'twf_flat',(0,-1,0))       # counterweight tube
    face(b,[V((-0.03,0.55,0.40)),V((0.03,0.55,0.40)),V((0.03,0.55,z0-0.55)),V((-0.03,0.55,z0-0.55))],'twf_flat',(0,-1,0))  # chain
    face(b,[V((-0.28,1.1,0.0)),V((0.28,1.1,0.0)),V((0.28,1.1,0.40)),V((-0.28,1.1,0.40))],'twf_flat',(0,-1,0))
    face(b,[V((-0.28,0.82,0.42)),V((0.28,0.82,0.42)),V((0.28,1.38,0.42)),V((-0.28,1.38,0.42))],'twf_flat',(0,0,1))      # sinker (plan)
# ===================================================================== fuel-dock pump
def _droop(a,c,e,n=10):
    """quadratic Bezier a -> e pulled by control c (a hose hanging under its own weight)"""
    return [a*(1-t)**2+c*2*t*(1-t)+e*t*t for t in [k/(n-1) for k in range(n)]]
PX,PY0,PY1=0.70,-0.43,0.67   # plinth half-width, front / back edge
def fuelpump(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'
    b.box((0,(PY0+PY1)/2,0),(2*PX,PY1-PY0,0.12),'concrete',skip=('bottom',))                             # island plinth
    W,D,Hc=0.62,0.42,1.40; z0=0.12
    b.box((0,0,z0),(W,D,Hc),'paint_white',skip=('bottom',))
    b.box((0,0,z0+Hc),(W+0.08,D+0.06,0.26),'plastic_blue',skip=())                                       # lit header
    if not mid:
        for ny in (-1,1):
            plate(b,(0,ny*(D/2+0.03+0.002),z0+Hc+0.13),W+0.04,0.22,(0,ny,0),'MARINE FUEL','GAS  -  DIESEL',hi,key='plastic_blue',tkey='paint_white',ts=0.5)
            plate(b,(0,ny*(D/2+0.002),z0+1.05),0.50,0.36,(0,ny,0),'5.49   5.89','REGULAR  89        DIESEL',hi,key='plastic_white',tkey='paint_black',ts=0.32)
            face(b,[V((-0.20,ny*(D/2+0.004),z0+1.12)),V((0.20,ny*(D/2+0.004),z0+1.12)),V((0.20,ny*(D/2+0.004),z0+1.20)),V((-0.20,ny*(D/2+0.004),z0+1.20))],'glass_dark',(0,ny,0))
            b.box((0.18,ny*(D/2+0.02),z0+0.78),(0.14,0.04,0.12),'plastic_black',skip=('back' if ny<0 else 'front',))   # card reader / keypad
            face(b,[V((-0.26,ny*(D/2+0.002),z0+0.10)),V((0.26,ny*(D/2+0.002),z0+0.10)),V((0.26,ny*(D/2+0.002),z0+0.60)),V((-0.26,ny*(D/2+0.002),z0+0.60))],'galvanized',(0,ny,0))   # access door
        for sx in (-1,1):   # nozzle holster on each side; hose from a swivel outlet high on the side, drooping in a U to the nozzle
            hx=sx*(W/2); b.box((hx+sx*0.03,0,z0+0.85),(0.06,0.16,0.22),'plastic_black',skip=())                # holster boot
            nz=V((hx+sx*0.075,0,z0+0.93))
            b.box((nz.x,nz.y,nz.z),(0.05,0.08,0.18),'paint_green' if sx<0 else 'paint_yellow',skip=())         # nozzle body
            b.tube(nz+V((0,-0.03,0.16)),nz+V((sx*0.02,-0.16,0.20)),0.012,0.010,4,'stainless',cap0=False,cap1=True)   # spout
            so=V((hx+sx*0.025,0.12,z0+1.24)); b.box((so.x,so.y,so.z-0.03),(0.05,0.06,0.06),'galvanized',skip=())   # swivel outlet
            hp=_droop(so+V((sx*0.02,0,-0.02)),V((hx+sx*0.34,0.10,z0-0.30)),nz+V((0,0,0.005)),n=9 if not hi else 16)
            b.sweep(hp,0.017,6 if not hi else 10,'rubber_black',cap0=False,cap1=False)
            b.tube(nz+V((0,0,0.005)),nz+V((0,0,-0.05)),0.022,0.020,6,'rubber_black',cap0=False,cap1=False)        # strain relief
        b.box((W/2+0.005,-0.10,z0+1.22),(0.01,0.10,0.10),'paint_red',skip=())                              # emergency stop
        plate(b,(-W/2-0.002,-0.08,z0+1.22),0.18,0.12,(-1,0,0),'NO SMOKING','STOP ENGINE',hi,key='plastic_white',tkey='paint_red',ts=0.4)
        # fire extinguisher hung on a wall bracket on the back of the cabinet: body, shoulder, valve, lever, hose + horn, gauge
        fx=V((-0.16,D/2+0.075,z0+0.32))
        b.box((fx.x,D/2+0.01,fx.z+0.30),(0.10,0.02,0.06),'galvanized',skip=())
        b.box((fx.x,D/2+0.01,fx.z+0.05),(0.08,0.02,0.04),'galvanized',skip=())
        b.lathe([(0.0,fx.z),(0.07,fx.z),(0.075,fx.z+0.02),(0.075,fx.z+0.40),(0.06,fx.z+0.45),(0.025,fx.z+0.48),(0.0,fx.z+0.48)],8,'paint_red',c=(fx.x,fx.y,0),cap_top=False)
        b.tube(V((fx.x,fx.y,fx.z+0.48)),V((fx.x,fx.y,fx.z+0.54)),0.018,0.018,6,'plastic_black',cap0=False,cap1=True)   # valve
        b.box((fx.x+0.03,fx.y,fx.z+0.55),(0.10,0.02,0.015),'plastic_black',skip=(),rz=0.0)                            # lever
        b.sweep([V((fx.x+0.02,fx.y+0.01,fx.z+0.52)),V((fx.x+0.09,fx.y+0.02,fx.z+0.46)),V((fx.x+0.085,fx.y+0.03,fx.z+0.10))],0.008,4,'plastic_black',cap0=False,cap1=False)
        b.tube(V((fx.x+0.085,fx.y+0.03,fx.z+0.10)),V((fx.x+0.085,fx.y+0.03,fx.z+0.02)),0.016,0.010,6,'plastic_black',cap0=False,cap1=True)   # horn
        b.tube(V((fx.x-0.02,fx.y+0.01,fx.z+0.50)),V((fx.x-0.02,fx.y+0.035,fx.z+0.50)),0.014,0.014,6,'stainless',cap0=False,cap1=True)   # gauge
        # spill-kit drum (lid, rolling hoops) standing on the plinth behind the pump
        dr=V((0.40,0.47,z0))
        b.lathe([(0.18,dr.z),(0.18,dr.z+0.17),(0.19,dr.z+0.18),(0.18,dr.z+0.35),(0.19,dr.z+0.36),(0.18,dr.z+0.52),(0.19,dr.z+0.55),(0.0,dr.z+0.56)],10,'paint_yellow',c=(dr.x,dr.y,0),cap_top=False)
        plate(b,(dr.x,dr.y-0.1855,dr.z+0.26),0.16,0.10,(0,-1,0),'SPILL KIT','',hi,key='plastic_white',tkey='paint_black',ts=0.45)
    for sx in (-1,1):   # guard bollards at the island's front corners, bolted to the plinth: yellow posts, black reflective bands, domed caps
        bx=V((sx*0.56,-0.31,0.12))
        b.lathe([(0.055,bx.z),(0.055,bx.z+0.92),(0.045,bx.z+0.96),(0.02,bx.z+0.99),(0.0,bx.z+1.0)] if not mid else [(0.055,bx.z),(0.055,bx.z+1.0),(0.0,bx.z+1.0)],8 if not mid else 6,'paint_yellow',c=(bx.x,bx.y,0),cap_top=False)
        if not mid:
            for zb in (0.70,0.82): b.tube(V((bx.x,bx.y,bx.z+zb)),V((bx.x,bx.y,bx.z+zb+0.05)),0.057,0.057,8,'plastic_black',cap0=False,cap1=False)
            b.box((bx.x,bx.y,bx.z),(0.16,0.16,0.012),'galvanized',skip=('bottom',))
        if tier=='near': ccyl(b,(bx.x,bx.y,0),0.06,1.12,rail=True)
    if tier=='near': cbox(b,(0,0,0),(2*PX,0.86,z0+Hc+0.26)); cbox(b,(0.40,0.47,0.0),(0.40,0.40,0.68))
def fuelpump_far(b):
    face(b,[V((-PX,PY0,0)),V((PX,PY0,0)),V((PX,PY0,0.12)),V((-PX,PY0,0.12))],'twf_flat',(0,-1,0))
    face(b,[V((-0.35,-0.24,0.12)),V((0.35,-0.24,0.12)),V((0.35,-0.24,1.78)),V((-0.35,-0.24,1.78))],'twf_flat',(0,-1,0))
    face(b,[V((-0.35,-0.24,1.78)),V((0.35,-0.24,1.78)),V((0.35,0.24,1.78)),V((-0.35,0.24,1.78))],'twf_flat',(0,0,1))
    for sx in (-1,1): face(b,[V((sx*0.56-0.055,-0.31,0.12)),V((sx*0.56+0.055,-0.31,0.12)),V((sx*0.56+0.055,-0.31,1.12)),V((sx*0.56-0.055,-0.31,1.12))],'twf_flat',(0,-1,0))
    for y0,y1 in ((PY0,-0.24),(0.24,PY1)): face(b,[V((-PX,y0,0.12)),V((PX,y0,0.12)),V((PX,y1,0.12)),V((-PX,y1,0.12))],'twf_flat',(0,0,1))   # plinth rim (plan)
    for x0,x1 in ((-PX,-0.35),(0.35,PX)): face(b,[V((x0,-0.24,0.12)),V((x1,-0.24,0.12)),V((x1,0.24,0.12)),V((x0,0.24,0.12))],'twf_flat',(0,0,1))
# ===================================================================== boat on a trailer (the 15 ft skiff, outboard tilted up, on a galvanised bunk trailer)
import b_wfboats as BB
TLIFT=0.50   # skiff keel (z 0.12) sits on the bunks at z 0.62
def _trailer(b,mid,hi):
    g='galvanized'; zr=0.42; RX=0.55
    for sx in (-1,1):   # main rails (C-channel read as box beams), bunk risers, bunks, fenders, wheels, lights
        WP.obox(b,(sx*RX,-1.70,zr+0.05),(sx*RX,2.05,zr+0.05),0.06,0.10,g,ends=(not mid,True))
        WP.obox(b,(sx*RX,-1.70,zr+0.05),(0.0,-3.10,zr+0.05),0.06,0.10,g,ends=(False,False))                      # A-frame tongue arms
        for yb in (-0.95,1.45):
            b.box((sx*0.36,yb,zr+0.10),(0.05,0.05,0.16),g,skip=('bottom','top'))
            if not mid: b.box((sx*0.36,yb,zr+0.10),(0.42*0+0.05,0.05,0.04),g,skip=('bottom',),rz=0.0)
        WP.obox(b,(sx*0.36,-1.25,0.62-0.035),(sx*0.36,1.95,0.62-0.035),0.09,0.07,'rubber_black',up=(-sx*0.25,0,1),ends=(True,True))  # carpeted bunk
        wx=sx*0.86; wy=0.55
        b.lathe([(0.0,-0.115),(0.27,-0.115),(0.30,-0.08),(0.30,0.08),(0.27,0.115),(0.0,0.115)] if not mid else [(0.0,-0.10),(0.30,-0.10),(0.30,0.10),(0.0,0.10)],
                14 if not mid else 8,'rubber_black',c=(0,0,0),cap_top=False,sym=None) if False else None
        n0=len(b.bm.verts)
        prof=[(0.0,-0.11),(0.18,-0.115),(0.27,-0.11),(0.30,-0.07),(0.30,0.07),(0.27,0.11),(0.18,0.115),(0.0,0.11)] if not mid else [(0.0,-0.10),(0.30,-0.10),(0.30,0.10),(0.0,0.10)]
        b.lathe(prof,14 if not mid else 8,'rubber_black',c=(0,0,0),cap_top=False)
        if not mid: b.lathe([(0.0,0.116),(0.16,0.116),(0.0,0.118)],10,'galvanized',c=(0,0,0),cap_top=False)        # wheel rim / hub face
        M=Matrix.Translation(V((wx,wy,0.30)))@Matrix.Rotation(sx*PI/2,4,'Y'); xf_since(b,n0,M)
        WP.obox(b,(wx-sx*0.12,wy,0.30),(sx*RX,wy,0.30),0.06,0.06,g) if not mid else None                         # stub axle
        fz=[(wy+0.38*math.cos(a),0.30+0.38*math.sin(a)) for a in [PI*k/6 for k in range(7)]] if not mid else [(wy+0.38,0.30),(wy+0.27,0.57),(wy-0.27,0.57),(wy-0.38,0.30)]
        for (ya,za),(yc,zc) in zip(fz[:-1],fz[1:]):   # wrap-around fender
            face(b,[V((wx-0.14,ya,za)),V((wx-0.14,yc,zc)),V((wx+0.14,yc,zc)),V((wx+0.14,ya,za))],g,(0,ya-wy+yc-wy,za+zc-0.6))
        if not mid:
            b.box((sx*(RX+0.02),2.05,zr+0.12),(0.14,0.05,0.08),'paint_red',skip=())                                      # tail light
            b.box((sx*(RX+0.035),-1.6,zr+0.10),(0.006,0.05,0.025),'plastic_orange',skip=())                             # side marker
    WP.obox(b,(-RX,wy,zr+0.05),(RX,wy,zr+0.05),0.08,0.08,g,ends=(False,False))                                          # axle beam (spring seat)
    if not mid:
        for sx in (-1,1):
            WP.obox(b,(sx*RX,wy-0.42,zr),(sx*RX,wy+0.42,zr),0.05,0.035,g)                                                 # leaf spring
    for yc in (-1.40,0.20,1.95): WP.obox(b,(-RX,yc,zr+0.05),(RX,yc,zr+0.05),0.06,0.08,g,ends=(False,False))              # cross members
    WP.obox(b,(0,-1.40,zr+0.05),(0,-3.45,zr+0.05),0.08,0.10,g)                                                            # centre tongue
    b.box((0,-3.52,zr+0.02),(0.12,0.24,0.10),g,skip=())                                                                    # coupler
    if not mid:
        b.lathe([(0.05,zr+0.12),(0.05,zr+0.14),(0.0,zr+0.15)],8,'galvanized',c=(0,-3.60,0),cap_top=False)                  # ball socket cap
        for sx in (-1,1): chain(b,V((sx*0.05,-3.30,zr)),V((sx*0.10,-3.70,zr-0.02)),0.08,6,'galvanized',hi=hi)             # safety chains
        # swing-up tongue jack with foot wheel
        b.tube(V((0.10,-2.80,zr-0.30)),V((0.10,-2.80,zr+0.40)),0.03,0.03,6,g,cap0=False,cap1=True)
        b.tube(V((0.10,-2.80,zr+0.40)),V((0.20,-2.80,zr+0.42)),0.008,0.008,3,'plastic_black',cap0=False,cap1=True)
        n0=len(b.bm.verts); b.lathe([(0.0,-0.03),(0.075,-0.03),(0.075,0.03),(0.0,0.03)],8,'rubber_black',c=(0,0,0),cap_top=False)
        xf_since(b,n0,Matrix.Translation(V((0.10,-2.80,0.075)))@Matrix.Rotation(PI/2,4,'Y'))
        # winch stand with bow stop roller, winch drum + crank, strap to the bow eye
        ws=V((0,-2.85,zr+0.10))
        WP.obox(b,ws,ws+V((0,0.25,0.62)),0.06,0.06,g); WP.obox(b,ws+V((0,0.45,0)),ws+V((0,0.25,0.62)),0.05,0.05,g,ends=(False,False))
        n0=len(b.bm.verts); b.lathe([(0.0,-0.05),(0.05,-0.05),(0.04,0.0),(0.05,0.05),(0.0,0.05)],8,'rubber_black',c=(0,0,0),cap_top=False)
        xf_since(b,n0,Matrix.Translation(ws+V((0,0.29,0.74)))@Matrix.Rotation(PI/2,4,'Y'))                               # V bow roller (on the stem, above the eye)
        WP.obox(b,ws+V((0,0.25,0.62)),ws+V((0,0.29,0.74)),0.04,0.04,g,ends=(False,True))                                 # roller arm
        b.box((0,ws.y+0.19,ws.z+0.44),(0.16,0.10,0.10),'plastic_black',skip=())                                          # winch body on the post
        n1=len(b.bm.verts); b.lathe([(0.0,-0.06),(0.045,-0.06),(0.035,-0.05),(0.035,0.05),(0.045,0.06),(0.0,0.06)],8,'galvanized',c=(0,0,0),cap_top=False)
        xf_since(b,n1,Matrix.Translation(ws+V((0,0.25,0.54)))@Matrix.Rotation(PI/2,4,'Y'))                                # strap drum
        b.tube(ws+V((0.08,0.21,0.50)),ws+V((0.24,0.15,0.45)),0.008,0.008,3,g,cap0=False,cap1=True)                        # crank arm
        b.box((0.24,ws.y+0.15,ws.z+0.41),(0.02,0.03,0.08),'plastic_black',skip=())                                       # crank handle
        be=BB.KH.surf(0.02,BB.KWL+0.35,1,0.0)+V((0,0,TLIFT)); be.x=0.0
        ringt(b,be+V((0,-0.03,0)),0.03,0.008,8,['stainless'],axis='x',seg=4)                                             # bow eye (U-bolt in the stem)
        b.box((0,be.y+0.005,be.z-0.03),(0.05,0.012,0.06),'stainless',skip=())                                            # backing plate
        WP.obox(b,ws+V((0,0.25,0.575)),be+V((0,-0.058,0)),0.05,0.004,'paint_yellow',up=(1,0,0),ends=(False,False))         # winch strap: drum -> eye
        b.sweep([be+V((0,-0.058,0.005)),be+V((0,-0.03,0.035)),be+V((0,-0.002,0.005))],0.006,3,'galvanized',cap0=False,cap1=False)   # strap hook in the eye
        for sx in (-1,1):   # transom tie-down straps
            p=BB.KH.sheer(0.97); p.x*=sx; p+=V((0,0,TLIFT))
            WP.obox(b,p+V((sx*0.02,0,0)),V((sx*RX,BB.KH.y(0.97),zr+0.10)),0.04,0.004,'paint_yellow',up=(0,1,0),ends=(False,False))
        b.box((0,2.10,zr+0.05),(0.30,0.01,0.16),'plastic_white',skip=())                                                  # licence plate (baked)
        plate(b,(0,2.106,zr+0.13),0.28,0.14,(0,1,0),'7ZB 418','CALIFORNIA',hi,key='plastic_white',tkey='paint_navy',ts=0.45)
def boat_trailer(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'
    n0=len(b.bm.verts); nc=len(b.col)
    BB.skiff(b,hi=hi,tier=tier,tilt=1.05)
    xf_since(b,n0,Matrix.Translation(V((0,0,TLIFT))))
    for i in range(nc,len(b.col)):   # lift the skiff's collision with it
        k,c,*r=b.col[i]; b.col[i]=(k,(c[0],c[1],c[2]+TLIFT),*r)
    P.TIER['t']='hi' if hi else tier
    _trailer(b,mid,hi)
    if tier=='near':
        cbox(b,(0,0.15,0),(1.90,4.0,0.62)); cbox(b,(0,-2.75,0.0),(0.30,1.6,0.62))
        for sx in (-1,1): ccyl(b,(sx*0.86,0.55,0),0.30,0.60,rail=False)
def boat_trailer_far(b):
    # the skiff's far cards minus its side profile (left view is info-only), outboard card tilted up like the mid, lifted onto the bunks
    H=BB.KH; y=H.ys; zs=H.zs; hs=H.hs; yT=H.y(1.0); yc=yT+0.22; KWL=BB.KWL; L=V((0,0,TLIFT))
    face(b,[V((0,y(0)-0.02,zs(0.5)))+L,V((hs(0.25)+0.03,y(0.25),zs(0.5)))+L,V((hs(1.0)+0.02,yT,zs(0.5)))+L,V((-hs(1.0)-0.02,yT,zs(0.5)))+L,V((-hs(0.25)-0.03,y(0.25),zs(0.5)))+L],'twf_flat',(0,0,1))
    ym=y(0.6)
    face(b,[V(p)+L for p in ((-0.80,ym,zs(0.6)),(-0.30,ym,zs(0.2)),(0.0,ym,zs(0.0)+0.02),(0.30,ym,zs(0.2)),(0.80,ym,zs(0.6)),(0.64,ym,KWL),(0.0,ym,KWL-0.18),(-0.64,ym,KWL))],'twf_flat',(0,-1,0))
    pv=V((0,yT,zs(1.0)-0.04)); M=Matrix.Translation(L)@Matrix.Translation(pv)@Matrix.Rotation(1.05,4,'X')@Matrix.Translation(-pv)
    face(b,[M@V(p) for p in ((-0.16,yc,0.0),(0.16,yc,0.0),(0.16,yc,KWL+0.78),(-0.16,yc,KWL+0.78))],'twf_flat',(0,-1,0))
    face(b,[V((-1.0,0.55,0.0)),V((-0.72,0.55,0.0)),V((-0.72,0.55,0.42)),V((0.72,0.55,0.42)),V((0.72,0.55,0.0)),V((1.0,0.55,0.0)),V((1.0,0.55,0.68)),V((-1.0,0.55,0.68))],'twf_flat',(0,-1,0))   # wheels, fenders, axle/frame (front)
    face(b,[V((0.0,-3.66,0.52)),V((0.6,-1.7,0.52)),V((-0.6,-1.7,0.52))],'twf_flat',(0,0,1))        # tongue (plan)
# ===================================================================== kayak rack (2 x 3 cradles, 4 sit-on-top kayaks)
KL=3.6; KB=0.66; KD=0.16; KHD=0.18
def kayak(b,c,key,mid,hi):
    c=V(c); n=10 if not mid else 5
    ts=[i/(n-1) for i in range(n)]
    def ring(t):
        s=math.sin(PI*t)**0.55 if 0<t<1 else 0.0; w=KB/2*s; d=KD*(0.35+0.65*s); h=KHD*(0.4+0.6*s); x=-KL/2+KL*t
        zr=0.10*(abs(2*t-1))**3   # rocker
        P_=[(0,-d),(w*0.80,-d*0.55),(w,0.0),(w*0.75,h*0.75),(0,h),(-w*0.75,h*0.75),(-w,0.0),(-w*0.80,-d*0.55)] if not mid else [(0,-d),(w,0.0),(0,h),(-w,0.0)]
        return [c+V((x,yy,zz+zr+KD)) for yy,zz in P_]
    R=[ring(t) for t in ts]; m=len(R[0])
    for i in range(n-1):
        for j in range(m):
            a,bq,cq,dq=R[i][j],R[i+1][j],R[i+1][(j+1)%m],R[i][(j+1)%m]
            ce=(a+bq+cq+dq)/4; out=ce-V((ce.x,c.y,c.z+KD))
            q=[a,bq,cq,dq]; q=[p for k_,p in enumerate(q) if (p-q[k_-1]).length>1e-5]   # end rings are a vertical stem line: drop coincident corners
            if len(q)>=3: face(b,q,key,tuple(out))
    if not mid:   # cockpit well (moulded seat), deck bungees, carry toggles
        def dk(x):   # deck crown height (relative to c) at x
            t=(x+KL/2)/KL; s_=math.sin(PI*t)**0.55 if 0<t<1 else 0.0; return KD+KHD*(0.4+0.6*s_)+0.10*(abs(2*t-1))**3
        zc=dk(0.10)-0.005; cw=[c+V((0.10+0.55*math.cos(2*PI*k/8),0.20*math.sin(2*PI*k/8),zc+0.006)) for k in range(8)]
        cen=c+V((0.10,0,zc-0.04))
        for k in range(8): face(b,[cen,cw[(k+1)%8],cw[k]] if False else [cen,cw[k],cw[(k+1)%8]],'plastic_black',(0,0,1))
        b.box((c.x+0.42,c.y,c.z+zc-0.06),(0.06,0.34,0.16),'plastic_black',skip=('bottom',))                               # seat back
        for sy in (-1,1): b.tube(c+V((-1.10,sy*0.13,dk(-1.10)-0.012)),c+V((-0.60,-sy*0.16,dk(-0.60)-0.02)),0.005,0.005,3,'plastic_black',cap0=False,cap1=False)   # deck bungees
        for sx in (-1,1):   # carry toggles: cord loops out of the deck near each end
            xe=sx*(KL/2-0.16); zt_=dk(xe)
            b.sweep([c+V((xe,-0.04,zt_-0.01)),c+V((xe+sx*0.05,0.0,zt_+0.02)),c+V((xe,0.04,zt_-0.01))],0.007,3,'plastic_black',cap0=False,cap1=False)
def kayak_rack(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'; g='galvanized'
    XE=1.05; YU=(-0.85,0.0,0.85); ZT=(0.40,1.00,1.60); TOP=2.05
    for xe in (-XE,XE):
        for yu in YU:
            b.box((xe,yu,0.0),(0.06,0.06,TOP),g,skip=('bottom',))
            if not mid: b.box((xe,yu,0.0),(0.16,0.16,0.01),g,skip=('bottom',))
        WP.obox(b,(xe,-0.90,TOP-0.03),(xe,0.90,TOP-0.03),0.06,0.06,g)                                                     # head beam
        for zt in ZT:
            WP.obox(b,(xe,-0.85,zt),(xe,0.85,zt),0.05,0.05,g,ends=(False,False))                                          # cradle arm
            if not mid:
                for yc in (-0.42,0.42): b.box((xe,yc,zt+0.025),(0.10,0.40,0.03),'rubber_black',skip=('bottom',))          # pads
    for yu in (-0.85,0.85):
        WP.obox(b,(-XE,yu,0.12),(XE,yu,0.12),0.05,0.05,g,ends=(False,False)) if not mid else None                          # bottom ties (near)
        WP.obox(b,(-XE,yu,TOP-0.03),(XE,yu,TOP-0.03),0.05,0.05,g,ends=(False,False)) if not mid else None                 # top ties
    if not mid:
        for xe in (-XE,XE):   # knee braces in the end frames (above the top cradles, clear of every kayak)
            for sy in (-1,1): WP.obox(b,(xe,sy*0.85,TOP-0.40),(xe,sy*0.50,TOP-0.03),0.03,0.03,g,ends=(False,False))
        b.box((0,-0.88,TOP-0.32),(0.90,0.02,0.24),'wood_natural',skip=())                                                 # sign board
        plate(b,(0,-0.8915,TOP-0.20),0.84,0.20,(0,-1,0),'KAYAK RENTALS','SELF-SERVE  ·  PFD REQUIRED',hi,key='plastic_white',tkey='paint_navy',ts=0.5)
    for (yc,zt),key in (((-0.42,ZT[0]),'plastic_orange'),((0.42,ZT[0]),'paint_yellow'),((-0.42,ZT[1]),'plastic_blue'),((0.42,ZT[1]),'paint_green')):
        kayak(b,(0,yc,zt+0.055-KD*0.35-0.02),key,mid,hi)
    if tier=='near':
        for xe in (-XE,XE):
            for yu in YU: ccyl(b,(xe,yu,0),0.04,TOP,rail=True)
        cbox(b,(0,0,ZT[0]),(KL,1.4,0.40)); cbox(b,(0,0,ZT[1]),(KL,1.4,0.40))
def kayak_rack_far(b):
    w=0.33*0.83
    for zt in (0.40,1.00):
        z0=zt-0.02; z1=zt+0.32; zm=zt+0.18
        face(b,[V((-KL/2,-0.9,zm+0.06)),V((-0.9,-0.9,z0)),V((0.9,-0.9,z0)),V((KL/2,-0.9,zm+0.06)),V((0.9,-0.9,z1)),V((-0.9,-0.9,z1))],'twf_flat',(0,-1,0))
    for xe in (-1.05,1.05): face(b,[V((xe-0.04,-0.9,0)),V((xe+0.04,-0.9,0)),V((xe+0.04,-0.9,2.05)),V((xe-0.04,-0.9,2.05))],'twf_flat',(0,-1,0))
    for yc in (-0.42,0.42): face(b,[V((-KL/2,yc,1.40)),V((-0.9,yc-w,1.40)),V((0.9,yc-w,1.40)),V((KL/2,yc,1.40)),V((0.9,yc+w,1.40)),V((-0.9,yc+w,1.40))],'twf_flat',(0,0,1))
# ===================================================================== beach shower (stainless column on a teak grate)
def beach_shower(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'
    b.box((0,0,0),(1.10,1.10,0.08),'concrete',skip=('bottom',))                                                         # pad
    if not mid:
        for k in range(7): b.box((-0.45+k*0.15,0.05,0.08),(0.11,0.90,0.035),'wood_natural',skip=('bottom',))            # teak grate slats
        for yb in (-0.36,0.46): b.box((0,yb,0.08),(0.96,0.05,0.02),'wood_natural',skip=('bottom',))
        b.lathe([(0.06,0.081),(0.06,0.083),(0.0,0.084)],8,'cast_iron',c=(0,0.05,0),cap_top=False)                        # drain
    cx,cy=0,-0.45; Hc=2.25; seg=10 if not mid else 6
    b.lathe([(0.11,0.08),(0.11,0.10),(0.05,0.12)] if not mid else [(0.05,0.08)],8,'stainless',c=(cx,cy,0),cap_top=False) if not mid else None
    b.tube(V((cx,cy,0.08)),V((cx,cy,Hc)),0.05,0.05,seg,'stainless',cap0=False,cap1=False)
    arm=[V((cx,cy,Hc-0.02)),V((cx,cy,Hc+0.10)),V((cx,cy+0.10,Hc+0.17)),V((cx,cy+0.32,Hc+0.17)),V((cx,cy+0.42,Hc+0.12))]
    b.sweep(arm if not mid else [arm[0],arm[2],arm[4]],0.032,8 if not mid else 4,'stainless',cap0=False,cap1=False)
    hc=arm[-1]
    b.lathe([(0.0,-0.06),(0.11,-0.06),(0.12,-0.03),(0.06,0.0),(0.035,0.02)] if not mid else [(0.0,-0.06),(0.11,-0.04),(0.035,0.02)],12 if not mid else 6,'stainless',c=(hc.x,hc.y,hc.z),cap_top=False)
    if not mid:
        face(b,[V((hc.x+0.09*math.cos(2*PI*k/12),hc.y+0.09*math.sin(2*PI*k/12),hc.z-0.0605)) for k in range(12)][::-1],'plastic_black',(0,0,-1))   # nozzle plate
        for zb,lab in ((1.05,'push'),(0.45,'foot')):   # push-valve bodies + chrome buttons, overhead and foot rinse
            b.box((cx,cy+0.05,zb),(0.08,0.06,0.10),'stainless',skip=('back',))
            b.tube(V((cx,cy+0.08,zb+0.05)),V((cx,cy+0.10,zb+0.05)),0.025,0.025,8,'plastic_black',cap0=False,cap1=True)
        b.sweep([V((cx,cy+0.05,0.42)),V((cx,cy+0.14,0.40)),V((cx,cy+0.18,0.34))],0.014,6,'stainless',cap0=False,cap1=False)   # foot spout
        b.lathe([(0.065,Hc),(0.065,Hc+0.02),(0.0,Hc+0.05)],10,'stainless',c=(cx,cy,0),cap_top=False)                    # column cap
        b.box((cx,cy-0.06,1.40),(0.26,0.01,0.20),'plastic_white',skip=())
        plate(b,(cx,cy-0.0655,1.50),0.24,0.18,(0,-1,0),'RINSE OFF','SAND ONLY · NO SOAP',hi,key='plastic_white',tkey='paint_navy',ts=0.5)
        b.tube(V((cx,cy+0.04,0.12)),V((cx,cy+0.04,0.0)),0.02,0.02,6,'cast_iron',cap0=False,cap1=False) if False else None
    if tier=='near': ccyl(b,(cx,cy,0),0.06,Hc+0.15,rail=True); cbox(b,(0,0,0),(1.10,1.10,0.12))
def beach_shower_far(b):
    face(b,[V((-0.55,-0.55,0.0)),V((0.55,-0.55,0.0)),V((0.55,-0.55,0.12)),V((-0.55,-0.55,0.12))],'twf_flat',(0,-1,0))
    face(b,[V((-0.05,-0.5,0.12)),V((0.05,-0.5,0.12)),V((0.05,-0.5,2.42)),V((-0.05,-0.5,2.42))],'twf_flat',(0,-1,0))
    face(b,[V((-0.12,-0.5,2.28)),V((0.12,-0.5,2.28)),V((0.12,-0.5,2.36)),V((-0.12,-0.5,2.36))],'twf_flat',(0,-1,0))
    face(b,[V((-0.55,-0.55,0.12)),V((0.55,-0.55,0.12)),V((0.55,0.55,0.12)),V((-0.55,0.55,0.12))],'twf_flat',(0,0,1))
    face(b,[V((-0.12,-0.10,2.45)),V((0.12,-0.10,2.45)),V((0.12,0.10,2.45)),V((-0.12,0.10,2.45))],'twf_flat',(0,0,1))
# ===================================================================== beach volleyball net (sand court posts, padded, tensioned net, antennas, guys)
NW=9.5; NX=5.0; NT=2.43; NH=1.0
def volleyball_net(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'
    for sx in (-1,1):
        x=sx*NX
        b.tube(V((x,0,0)),V((x,0,2.60)),0.045,0.045,10 if not mid else 6,'aluminium',cap0=False,cap1=True)                  # post
        b.tube(V((x,0,0.0)),V((x,0,1.85)),0.11,0.11,10 if not mid else 6,'fabric',cap0=False,cap1=True)                     # pad
        if not mid:
            for z in (0.5,1.0,1.5): b.tube(V((x,0,z)),V((x,0,z+0.04)),0.113,0.113,10,'wood_white',cap0=False,cap1=False)   # pad straps
            b.box((x-sx*0.07,0,NT-0.05),(0.05,0.06,0.10),'plastic_black',skip=())                                       # net clamp
            b.box((x-sx*0.07,0,NT-NH-0.05),(0.05,0.06,0.10),'plastic_black',skip=())
            b.box((x+sx*0.06,0,1.35),(0.06,0.08,0.10),'aluminium',skip=())                                               # winch
            b.tube(V((x+sx*0.09,0,1.40)),V((x+sx*0.16,-0.05,1.40)),0.008,0.008,3,'plastic_black',cap0=False,cap1=True)
            b.lathe([(0.20,0.0),(0.20,0.02),(0.0,0.02)],10,'concrete',c=(x,0,0),cap_top=False)                           # sleeve collar in the sand
            for sy in (-1,1):   # guy lines to sand anchors
                a=V((x+sx*1.6,sy*1.0,0.0))
                b.tube(V((x,0,2.55)),a+V((0,0,0.05)),0.005,0.005,3,'paint_beige',cap0=False,cap1=False)
                b.box((a.x,a.y,0.0),(0.12,0.12,0.06),'plastic_black',skip=('bottom',))
        b.tube(V((x,0,NT-0.01)),V((x-sx*(NX-NW/2),0,NT-0.01)),0.006,0.006,3,'plastic_black',cap0=False,cap1=False)          # head cable to the clamp
    # net: white top band, bottom band, side bands, cord mesh (near: 10 cm squares as 0.25 m strands for budget; hi: full)
    x0,x1=-NW/2,NW/2; zb=NT-NH
    b.box((0,0,NT-0.07),(NW,0.012,0.07),'wood_white',skip=())
    b.box((0,0,zb),(NW,0.010,0.05),'wood_white',skip=())
    for sx in (-1,1): b.box((sx*(NW/2-0.025),0,zb),(0.05,0.011,NH),'wood_white',skip=())
    if not mid:
        for k in range(1,38):   # vertical cords
            x=x0+k*NW/38
            for ny in (-1,1): face(b,[V((x-0.004,ny*0.003,zb+0.05)),V((x+0.004,ny*0.003,zb+0.05)),V((x+0.004,ny*0.003,NT-0.07)),V((x-0.004,ny*0.003,NT-0.07))][::(1 if ny<0 else -1)],'plastic_black',(0,ny,0))
        for k in range(1,5):    # horizontal cords
            z=zb+0.05+k*(NH-0.12)/5
            for ny in (-1,1): face(b,[V((x0+0.05,ny*0.003,z-0.004)),V((x1-0.05,ny*0.003,z-0.004)),V((x1-0.05,ny*0.003,z+0.004)),V((x0+0.05,ny*0.003,z+0.004))][::(1 if ny<0 else -1)],'plastic_black',(0,ny,0))
        for sx in (-1,1):   # antennas, red/white
            xa=sx*(NW/2-0.55)
            for k in range(4): b.tube(V((xa,0.012,NT-NH+k*0.45)),V((xa,0.012,NT-NH+(k+1)*0.45)),0.005,0.005,4,'paint_red' if k%2 else 'wood_white',cap0=False,cap1=k==3)
        plate(b,(sx*0,-0.0075,NT-0.035),0.6,0.05,(0,-1,0),'CORONADO','',hi,key='plastic_white',tkey='paint_navy',ts=0.8)
    else:
        for k in range(1,10):
            x=x0+k*NW/10
            for ny in (-1,1): face(b,[V((x-0.006,ny*0.003,zb+0.05)),V((x+0.006,ny*0.003,zb+0.05)),V((x+0.006,ny*0.003,NT-0.07)),V((x-0.006,ny*0.003,NT-0.07))][::(1 if ny<0 else -1)],'plastic_black',(0,ny,0))
    if tier=='near':
        for sx in (-1,1): ccyl(b,(sx*NX,0,0),0.11,2.60,rail=True)
        cbox(b,(0,0,zb),(NW,0.05,NH))
def volleyball_net_far(b):
    for sx in (-1,1):
        face(b,[V((sx*NX-0.11,0,0)),V((sx*NX+0.11,0,0)),V((sx*NX+0.11,0,1.85)),V((sx*NX-0.11,0,1.85))],'twf_flat',(0,-1,0))
        face(b,[V((sx*NX-0.045,0,1.85)),V((sx*NX+0.045,0,1.85)),V((sx*NX+0.045,0,2.60)),V((sx*NX-0.045,0,2.60))],'twf_flat',(0,-1,0))
        face(b,[V((sx*NX-0.09,-0.09,1.86)),V((sx*NX+0.09,-0.09,1.86)),V((sx*NX+0.09,0.09,1.86)),V((sx*NX-0.09,0.09,1.86))],'twf_flat',(0,0,1))
    face(b,[V((-NW/2,-0.01,NT-0.07)),V((NW/2,-0.01,NT-0.07)),V((NW/2,-0.01,NT)),V((-NW/2,-0.01,NT))],'twf_flat',(0,-1,0))
    face(b,[V((-NW/2,-0.01,NT-NH)),V((NW/2,-0.01,NT-NH)),V((NW/2,-0.01,NT-NH+0.05)),V((-NW/2,-0.01,NT-NH+0.05))],'twf_flat',(0,-1,0))
    face(b,[V((-NW/2,-0.006,NT+0.001)),V((NW/2,-0.006,NT+0.001)),V((NW/2,0.006,NT+0.001)),V((-NW/2,0.006,NT+0.001))],'twf_flat',(0,0,1))
# ===================================================================== beach umbrellas (open striped market-style beach umbrella; closed / furled one)
UR=1.05; UA=2.30; UE=1.92
def _umb_base(b,mid,hi):
    b.lathe([(0.30,0.0),(0.30,0.06),(0.20,0.10),(0.07,0.13),(0.05,0.16),(0.0,0.16)] if not mid else [(0.30,0.0),(0.30,0.06),(0.05,0.16),(0.0,0.16)],12 if not mid else 6,'plastic_white' if False else 'plastic_black',c=(0,0,0),cap_top=False)   # fillable base
    if not mid: b.box((0.06,0,0.14),(0.06,0.03,0.03),'aluminium',skip=())                                                            # thumb screw
    b.tube(V((0,0,0.12)),V((0,0,1.10)),0.025,0.025,8 if not mid else 4,'wood_natural',cap0=False,cap1=False)                         # lower pole
    if not mid: b.tube(V((0,0,1.05)),V((0,0,1.15)),0.032,0.032,8,'aluminium',cap0=False,cap1=False)                                   # tilt/joint sleeve
def beach_umbrella(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'
    _umb_base(b,mid,hi)
    b.tube(V((0,0,1.10)),V((0,0,UA+0.02)),0.020,0.020,8 if not mid else 4,'wood_natural',cap0=False,cap1=False)
    n=8; ap=V((0,0,UA)); rm=lambda k,r,z: V((r*math.cos(2*PI*k/n+PI/n),r*math.sin(2*PI*k/n+PI/n),z))
    zm=UA-0.20; rM=UR*0.58
    for k in range(n):
        key='fabric' if k%2 else 'wood_white'
        a0,a1=rm(k,UR,UE),rm(k+1,UR,UE)
        if mid:
            face(b,[ap,a0,a1],key,tuple(rm(k+0.5,1,1.2)))
            face(b,[ap,a1,a0],key,tuple(rm(k+0.5,-0.3,-1)))
            face(b,[a0,a0+V((0,0,-0.09)),a1+V((0,0,-0.09)),a1],key,tuple(rm(k+0.5,1,0)))   # valance (outside)
        else:
            m0,m1=rm(k,rM,zm),rm(k+1,rM,zm)
            face(b,[ap,m0,m1],key,tuple(rm(k+0.5,1,1.6))); face(b,[m0,a0,a1,m1],key,tuple(rm(k+0.5,1,1.0)))
            face(b,[ap,m1,m0],key,tuple(rm(k+0.5,-0.2,-1))); face(b,[m1,a1,a0,m0],key,tuple(rm(k+0.5,-0.4,-1)))
            # valance: scalloped drop (centre deeper), both sides
            c_=(a0+a1)/2+V((0,0,-0.12)); d0,d1=a0+V((0,0,-0.06)),a1+V((0,0,-0.06))
            face(b,[a0,d0,c_,d1,a1],key,tuple(rm(k+0.5,1,0))); face(b,[a1,d1,c_,d0,a0],key,tuple(rm(k+0.5,-1,0)))
            # rib + stretcher (under the canopy)
            rk=rm(k,UR*0.98,UE-0.01); mk=rm(k,rM,zm-0.012)
            b.tube(ap+V((0,0,-0.03)),mk,0.006,0.006,3,'aluminium',cap0=False,cap1=False); b.tube(mk,rk,0.006,0.006,3,'aluminium',cap0=False,cap1=False)
            b.tube(V((0,0,1.75)),rm(k,rM*0.55,zm-0.05),0.005,0.005,3,'aluminium',cap0=False,cap1=False)
            b.sweep([rk,rk+V((0,0,-0.03))],0.008,4,'plastic_black',cap0=False,cap1=True)                                           # rib tip
    if not mid:
        b.lathe([(0.05,1.72),(0.05,1.80),(0.02,1.82)],8,'plastic_black',c=(0,0,0),cap_top=False)                                  # runner
        b.lathe([(0.10,UA-0.005),(0.10,UA+0.04),(0.06,UA+0.10),(0.03,UA+0.13),(0.0,UA+0.14)],8,'fabric',c=(0,0,0),cap_top=False)   # vent cap
        b.lathe([(0.015,UA+0.14),(0.015,UA+0.20),(0.0,UA+0.22)],6,'wood_natural',c=(0,0,0),cap_top=False)                         # finial
    if tier=='near': ccyl(b,(0,0,0),0.04,UA,rail=True); cbox(b,(0,0,0),(0.60,0.60,0.16))
def beach_umbrella_far(b):
    c8=UR*math.cos(PI/8); face(b,[V((-c8,0,UE-0.09)),V((c8,0,UE-0.09)),V((c8,0,UE)),V((0,0,UA+0.02)),V((-c8,0,UE))],'twf_flat',(0,-1,0))
    face(b,[V((-0.03,0,0.16)),V((0.03,0,0.16)),V((0.03,0,UE-0.09)),V((-0.03,0,UE-0.09))],'twf_flat',(0,-1,0))
    face(b,[V((-0.26,0,0)),V((0.26,0,0)),V((0.26,0,0.06)),V((0.0,0,0.16)),V((-0.26,0,0.06))],'twf_flat',(0,-1,0))
    face(b,[V((UR*math.cos(2*PI*k/8+PI/8),UR*math.sin(2*PI*k/8+PI/8),UA)) for k in range(8)],'twf_flat',(0,0,1))
def beach_umbrella_closed(b,hi=False,tier='near'):
    P.TIER['t']='hi' if hi else tier; mid=tier=='mid'
    _umb_base(b,mid,hi)
    b.tube(V((0,0,1.10)),V((0,0,UA+0.02)),0.020,0.020,8 if not mid else 4,'wood_natural',cap0=False,cap1=False)
    n=8; zl,zh=1.30,UA-0.02
    prof=[(0.04,zl),(0.13,zl+0.25),(0.16,zl+0.50),(0.12,zh-0.20),(0.05,zh)] if not mid else [(0.04,zl),(0.15,zl+0.45),(0.05,zh)]
    for j in range(len(prof)-1):   # furled canopy: gathered pleats (alternating radius = fold lines), striped panels
        (r0,z0),(r1,z1)=prof[j],prof[j+1]
        for k in range(n):
            key='fabric' if k%2 else 'wood_white'
            q=lambda kk,r,z: V((r*(1.0 if kk%1==0 else 0.8)*math.cos(2*PI*kk/n),r*math.sin(2*PI*kk/n),z))
            face(b,[q(k,r0,z0),q(k+1,r0,z0),q(k+1,r1,z1),q(k,r1,z1)],key,tuple(V((math.cos(2*PI*(k+0.5)/n),math.sin(2*PI*(k+0.5)/n),0))))
    if not mid:
        b.tube(V((0,0,zl+0.48)),V((0,0,zl+0.54)),0.165,0.165,8,'fabric',cap0=False,cap1=False)                                    # tie strap
        for k in range(n): b.sweep([V((0.045*math.cos(2*PI*k/n),0.045*math.sin(2*PI*k/n),zl)),V((0.06*math.cos(2*PI*k/n),0.06*math.sin(2*PI*k/n),zl-0.05))],0.008,3,'plastic_black',cap0=False,cap1=True)   # rib tips
        b.lathe([(0.06,zh),(0.05,zh+0.06),(0.0,zh+0.10)],8,'fabric',c=(0,0,0),cap_top=False)
        b.lathe([(0.015,zh+0.10),(0.015,zh+0.16),(0.0,zh+0.18)],6,'wood_natural',c=(0,0,0),cap_top=False)
    if tier=='near': ccyl(b,(0,0,0),0.17,UA+0.1,rail=True); cbox(b,(0,0,0),(0.60,0.60,0.16))
def beach_umbrella_closed_far(b):
    face(b,[V((-0.03,0,0.16)),V((0.03,0,0.16)),V((0.03,0,1.30)),V((-0.03,0,1.30))],'twf_flat',(0,-1,0))
    face(b,[V((-0.04,0,1.30)),V((0.04,0,1.30)),V((0.16,0,1.80)),V((0.05,0,UA+0.15)),V((-0.05,0,UA+0.15)),V((-0.16,0,1.80))],'twf_flat',(0,-1,0))
    face(b,[V((-0.30,0,0)),V((0.30,0,0)),V((0.20,0,0.10)),V((0.0,0,0.16)),V((-0.20,0,0.10))],'twf_flat',(0,-1,0))
    face(b,[V((0.30*math.cos(2*PI*k/6),0.30*math.sin(2*PI*k/6),0.12)) for k in range(6)],'twf_flat',(0,0,1))
def buoy_nun(b,hi=False,tier='near'): _marker(b,hi,tier,True,'2','paint_red')      # red nun "2" (starboard-hand, returning)
def buoy_can(b,hi=False,tier='near'): _marker(b,hi,tier,False,'3','paint_green')   # green can "3"
def buoy_nun_far(b): _marker_far(b,True)
def buoy_can_far(b): _marker_far(b,False)
# ===================================================================== registry
TRS=dict(BB.TRB)
TRS.update({'galvanized':('tw_galv',(0.875,0.875),6.0),'cast_iron':('tw_galv',(0.875,0.875),6.0),'plastic_orange':('tw_gelcoat',(0.875,0.875)),
            'paint_yellow':('tw_gelcoat',(0.875,0.875)),'plastic_blue':('tw_gelcoat',(0.875,0.875)),'paint_red':('tw_gelcoat',(0.875,0.875))})
TINTS=dict(BB.TINT)
TINTS.update({'galvanized':(1.0,1.0,1.0),'cast_iron':(0.30,0.28,0.26),'plastic_orange':(0.95,0.42,0.10),'paint_yellow':(0.95,0.76,0.12),
              'plastic_blue':(0.16,0.42,0.78),'paint_red':(0.78,0.14,0.10),'paint_green':(0.10,0.45,0.22),'fabric':(0.10,0.30,0.58)})
_C=dict(BB._C); _C.update(dir='props/waterfront/small',pdir='waterfront_small',trim=TRS,trim_tint=TINTS,max_side=64)
TR_TRAILER=dict(TRS,paint_red=BB.TRB['paint_red']); TI_TRAILER=dict(TINTS,paint_red=BB.TINT['paint_red'],paint_green=BB.TINT['paint_green'])
TR_PUMP=dict(TRS); TR_PUMP.pop('plastic_blue')   # lettered blue header plates bake
def _wrap(fn,name):
    def near(b): P.reset(); P.TIER['t']='near'; fn(b); P.save_rails(name,pg.K+'/props/waterfront/_rails')
    return near
def _p(name,fn,far,cls,**kw):
    return dict(name=name,near=_wrap(fn,name),high=lambda b: fn(b,hi=True),mid=lambda b: fn(b,tier='mid'),far=far,**dict(_C,cls=cls,**kw))
PROPS=[
 _p('lifering_stand',lifering,lifering_far,'small'),
 _p('buoy_mooring',buoy_mooring,buoy_mooring_far,'small'),
 _p('buoy_nun',buoy_nun,buoy_nun_far,'small'),
 _p('buoy_can',buoy_can,buoy_can_far,'small'),
 _p('fuel_pump',fuelpump,fuelpump_far,'medium',trim=TR_PUMP),
 _p('boat_trailer',boat_trailer,boat_trailer_far,'large',trim=TR_TRAILER,trim_tint=TI_TRAILER),
 _p('kayak_rack',kayak_rack,kayak_rack_far,'medium'),
 _p('beach_shower',beach_shower,beach_shower_far,'small'),
 _p('volleyball_net',volleyball_net,volleyball_net_far,'medium'),
 _p('beach_umbrella',beach_umbrella,beach_umbrella_far,'small',no_bake=True),   # all-trim (canvas / sail / teak / alu tiles)
 _p('beach_umbrella_closed',beach_umbrella_closed,beach_umbrella_closed_far,'small',no_bake=True),
]
