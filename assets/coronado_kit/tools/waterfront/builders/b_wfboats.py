"""Waterfront set 4: moored boats. Builder coords Z up, bow -> -Y (front), beam on X; origin = lowest point (keel / skeg) centre.
MOORING DATUM: every boat has its designed waterline at local z = WL (listed per boat); place it at world z = 1.5 - WL so it floats
on the harbour WL 1.5 (bed z 0). Hulls / decks / sails / canvas / cushions / spars sample the shared page-W trim tiles
(tw_gelcoat, tw_nonskid, tw_sail, tw_plank, tw_vinyl, tw_foul, tw_canvas, tw_teak, tw_galv, tw_rubber) tinted per key; only
lettering, winches, anchors and small castings bake into each boat's 64 px patch."""
import math
from mathutils import Vector
import pg
import wf_parts as P
import b_wfpier as WP
from wf_parts import PI, cbox, ccyl
from wf_boat import *
V=Vector
def tab(T):
    """piecewise-linear table [(t,v),...] -> f(t)"""
    def f(t):
        for (a,va),(c,vc) in zip(T[:-1],T[1:]):
            if t<=c: return va+(vc-va)*(t-a)/max(c-a,1e-9)
        return T[-1][1]
    return f
def smooth_tab(T):
    f=tab(T)
    return lambda t: (f(max(0,t-0.02))+f(t)+f(min(1,t+0.02)))/3
def T_(hi,t): P.TIER['t']='hi' if hi else t
def name_board(b,c,w,h,txt,sub,hi,normal=(0,1,0),key_txt='paint_navy'):
    """baked lettering board (decal patch) proud of a hull face"""
    c=V(c); n=V(normal).normalized(); u=n.cross(V((0,0,1))).normalized()*-1 if abs(n.z)<0.9 else V((1,0,0))
    if n.y>0: u=V((-1,0,0))
    if n.x>0.5: u=V((0,1,0))
    if n.x<-0.5: u=V((0,-1,0))
    vz=V((0,0,1))
    pts=[c-u*w/2-vz*h/2+n*0.004,c+u*w/2-vz*h/2+n*0.004,c+u*w/2+vz*h/2+n*0.004,c-u*w/2+vz*h/2+n*0.004]
    face(b,pts,'plastic_white',tuple(n))
    if hi:
        pg.add_text(b,txt,h*(0.55 if sub else 0.8),tuple(c+n*0.0055+vz*(h*0.15 if sub else 0)),tuple(u),(0,0,1),0.0012,key_txt)
        if sub: pg.add_text(b,sub,h*0.25,tuple(c+n*0.0055-vz*h*0.3),tuple(u),(0,0,1),0.0010,key_txt)
# ===================================================================== sailboat: 30 ft masthead sloop "SEA BISCUIT"
SL=9.2; SWL=1.40
SH=Hull(SL,hs=smooth_tab([(0,0.03),(0.1,0.62),(0.25,1.20),(0.5,1.50),(0.7,1.48),(0.9,1.36),(1,1.26)]),
        hw=smooth_tab([(0,0.02),(0.12,0.45),(0.3,1.05),(0.5,1.30),(0.75,1.20),(0.92,0.98),(1,0.86)]),
        zs=smooth_tab([(0,SWL+1.08),(0.25,SWL+0.92),(0.55,SWL+0.80),(0.85,SWL+0.76),(1,SWL+0.78)]),
        zk=smooth_tab([(0,SWL-0.04),(0.08,SWL-0.22),(0.3,SWL-0.46),(0.5,SWL-0.50),(0.75,SWL-0.36),(0.95,SWL-0.10),(1,SWL-0.06)]),
        WL=SWL,boot=0.09,flare=0.02,keys=('paint_red','paint_navy','paint_white'))
TS_N=[0,0.03,0.07,0.12,0.18,0.26,0.35,0.45,0.55,0.65,0.75,0.85,0.93,1.0]
TS_M=[0,0.08,0.22,0.42,0.62,0.82,1.0]
def hull_pt(H,ts,t,z,off=0.006):
    """point on the built (faceted) hull skin at station t, height z: interpolates between the two built stations around t
    (so decals / windows sit exactly on the low-poly faces), pushed `off` outward. Returns (x>0, y)."""
    i=max(0,min(len(ts)-2,next((k for k in range(len(ts)-1) if ts[k]<=t<=ts[k+1]),len(ts)-2)))
    a,c=ts[i],ts[i+1]; f=(t-a)/max(c-a,1e-9)
    x=hull_x(H,a,z)*(1-f)+hull_x(H,c,z)*f; y=H.yz(a,z)*(1-f)+H.yz(c,z)*f
    return x+off,y
def hull_strip(b,H,ts,t0,t1,z0,z1,key,sx,off=0.006):
    """decal strip on the hull side between t0..t1, z0..z1, split at every built station so it never cuts the faceted skin"""
    tt=[t0]+[t for t in ts if t0<t<t1]+[t1]
    for a,c in zip(tt[:-1],tt[1:]):
        pa0,pa1,pc0,pc1=hull_pt(H,ts,a,z0,off),hull_pt(H,ts,a,z1,off),hull_pt(H,ts,c,z0,off),hull_pt(H,ts,c,z1,off)
        face(b,[V((sx*pa0[0],pa0[1],z0)),V((sx*pc0[0],pc0[1],z0)),V((sx*pc1[0],pc1[1],z1)),V((sx*pa1[0],pa1[1],z1))],key,(sx,0,0))
def hull_port(b,H,ts,tc,zc,w,h,sx,n=10,frame=0.025,mid=False):
    """hull-side port / window: a rounded outline whose every vertex lies on the lofted skin (follows the curvature), a stainless
    frame ring 3 mm proud and tinted glass 5 mm proud inside it -- flush, never a flat slab"""
    def ring(ww,hh,off):
        pts=[]
        for i in range(n):
            a=2*PI*i/n; cu,cv=math.cos(a),math.sin(a)
            e=0.55 if w>2.5*h else 1.0   # long bands: squarer outline (rounded-rect), small ports: ellipse
            u=math.copysign(abs(cu)**e,cu)*ww/2; v=math.copysign(abs(cv)**e,cv)*hh/2
            pts.append(H.surf(tc+u/H.L,zc+v,sx,off))
        return pts
    def fan(pts,cen,key):   # centre fan: every triangle lies on the curved skin (no non-planar n-gon -> no jagged triangulation)
        for i in range(len(pts)): face(b,[cen,pts[i],pts[(i+1)%len(pts)]],key,(sx,0,0))
    if not mid:   # frame = annulus between the frame outline and the glass outline
        A=ring(w+2*frame,h+2*frame,0.007); B=ring(w,h,0.007)
        for i in range(n): face(b,[A[i],A[(i+1)%n],B[(i+1)%n],B[i]],'stainless',(sx,0,0))
    fan(ring(w,h,0.009),H.surf(tc,zc,sx,0.009),'glass_dark')
def hull_board(b,H,ts,tc,zc,w,h,txt,hi,sx,key_txt='paint_navy'):
    """registration / name board laid flush on the faceted hull side (split per station), lettering on its chord plane (hi only)"""
    dt=w/(2*H.L); t0,t1=tc-dt,tc+dt
    hull_strip(b,H,ts,t0,t1,zc-h/2,zc+h/2,'plastic_white',sx,off=0.005)
    if hi:
        a=hull_pt(H,ts,t0,zc,0.0062); c=hull_pt(H,ts,t1,zc,0.0062)
        pa=V((sx*a[0],a[1],zc)); pc=V((sx*c[0],c[1],zc)); u=(pc-pa).normalized()
        if sx<0: u=-u
        pg.add_text(b,txt,h*0.8,tuple((pa+pc)/2),tuple(u),(0,0,1),0.0012,key_txt)
def hull_x(H,t,z):
    """half-breadth of the hull skin at station t, height z (topsides interpolation)"""
    pts=H.sec(t)
    for (xa,za),(xc,zc) in zip(pts[:-1],pts[1:]):
        if za<=z<=zc: return xa+(xc-xa)*(z-za)/max(zc-za,1e-9)
    return pts[-1][0]
def sloop(b,hi=False,tier='near'):
    T_(hi,tier); mid=tier=='mid'; H=SH
    ts=TS_M if mid else ([i/30 for i in range(31)] if hi else TS_N)
    H.build(b,ts,'mid' if mid else 'near')
    zs=H.zs; hs=H.hs; y=H.y
    TC0,TC1,TK0,TK1=0.30,0.62,0.62,0.97
    side=lambda t: hs(t)-0.36
    # ---- deck: cambered foredeck, side decks along the cabin and cockpit, after deck
    fts=[t for t in ts if t<=TC0]+([TC0] if TC0 not in ts else [])
    deck(b,H,sorted(set(fts)),None,'stucco',camber=0.05)
    mts=sorted(set([TC0,TK1]+[t for t in ts if TC0<t<TK1]))
    deck(b,H,mts,side,'stucco')
    deck(b,H,[TK1,1.0],None,'stucco',camber=0.0)
    zdf=lambda x,t: zs(t)+0.05*(1-abs(x)/max(hs(t),1e-3))   # foredeck camber
    if not mid:
        rubrail(b,H,ts,'rubber_black',0.045,0.06)
        sheer_strip(b,H,ts,'wood_natural',h=0.035,off=-0.03)                     # teak toe rail
    # ---- cabin trunk with raked front, cambered top, portlights, handrails, companionway, dorades
    cts=[TC0,0.36,0.44,0.52,TC1] if not mid else [TC0,0.46,TC1]
    ch=lambda t: 0.30+0.14*min(1,(t-TC0)/0.08)
    zt=lambda t: zs(t)+ch(t)
    for i in range(len(cts)-1):
        a,c=cts[i],cts[i+1]
        for sx in (1,-1):
            face(b,[V((sx*side(a),y(a),zs(a))),V((sx*side(c),y(c),zs(c))),V((sx*(side(c)-0.08),y(c),zt(c))),V((sx*(side(a)-0.08),y(a),zt(a)))],'paint_white',(sx,0,0.3))
            face(b,[V((sx*(side(a)-0.08),y(a),zt(a))),V((sx*(side(c)-0.08),y(c),zt(c))),V((0,y(c),zt(c)+0.06)),V((0,y(a),zt(a)+0.06))],'stucco',(0,0,1))
    a=TC0; yf=y(a)+0.10
    for sx in (1,-1): face(b,[V((sx*side(a),y(a),zs(a))),V((0,y(a),zs(a))),V((0,yf,zt(a)+0.06)),V((sx*(side(a)-0.08),yf,zt(a)))],'paint_white',(0,-1,0.6))
    for sx in (1,-1):   # fix the first top quad to the raked front
        pass
    c=TC1
    face(b,[V((side(c),y(c),zs(c))),V((-side(c),y(c),zs(c))),V((-(side(c)-0.08),y(c),zt(c))),V((0,y(c),zt(c)+0.06)),V((side(c)-0.08,y(c),zt(c)))],'paint_white',(0,1,0))
    if not mid:
        for sx in (1,-1):
            for k,(t0,t1) in enumerate(((0.335,0.385),(0.41,0.47),(0.50,0.56))):   # portlights (smoked acrylic in alloy frames)
                zz0=zs(t0)+0.12; zz1=zs(t0)+0.24
                xo=lambda t,z: sx*(side(t)-0.08*(z-zs(t))/ch(t)+0.005)
                xf=lambda t,z: sx*(side(t)-0.08*(z-zs(t))/ch(t)+0.003); f_=0.02
                face(b,[V((xf(t0,zz0-f_),y(t0)-f_,zz0-f_)),V((xf(t1,zz0-f_),y(t1)+f_,zz0-f_)),V((xf(t1,zz1+f_),y(t1)+f_,zz1+f_)),V((xf(t0,zz1+f_),y(t0)-f_,zz1+f_))],'stainless',(sx,0,0.3))
                face(b,[V((xo(t0,zz0),y(t0),zz0)),V((xo(t1,zz0),y(t1),zz0)),V((xo(t1,zz1),y(t1),zz1)),V((xo(t0,zz1),y(t0),zz1))],'glass_dark',(sx,0,0.3))
            for (t0,t1) in ((0.36,0.58),):   # teak grab rail on the cabin top
                x=sx*(side(0.45)-0.22); pa=V((x,y(t0),zt(t0)+0.03)); pc=V((x,y(t1),zt(t1)+0.03))
                WP.obox(b,pa,pc,0.03,0.04,'wood_natural')
                for f in (0.0,0.5,1.0):
                    p=pa+(pc-pa)*f; b.box((p.x,p.y,p.z-0.04),(0.03,0.05,0.025),'wood_natural',skip=('bottom','top'))
        # companionway: sliding hatch + garage, teak washboards, mast step, dorade cowls, halyard winches
        yc0,yc1=y(0.53),y(TC1)
        b.box((0,(yc0+yc1)/2,zt(0.57)+0.06),(0.72,yc1-yc0,0.07),'paint_white',skip=('bottom',))
        face(b,[V((-0.30,y(TC1)+0.004,zs(TC1)+0.02)),V((0.30,y(TC1)+0.004,zs(TC1)+0.02)),V((0.30,y(TC1)+0.004,zt(TC1)+0.04)),V((-0.30,y(TC1)+0.004,zt(TC1)+0.04))],'wood_natural',(0,1,0))
        for sx in (1,-1):
            b.lathe([(0.07,0.0),(0.07,0.12),(0.05,0.18),(0.0,0.2)],8 if not hi else 16,'paint_white',c=(sx*0.35,y(0.33),zt(0.33)+0.02),cap_top=False)
            b.tube(V((sx*0.35,y(0.33)-0.02,zt(0.33)+0.17)),V((sx*0.35,y(0.33)-0.13,zt(0.33)+0.17)),0.065,0.07,8 if not hi else 16,'paint_white',cap0=False,cap1=False)
            winch(b,(sx*0.42,y(0.585),zt(0.585)+0.02),0.05,0.11,'cast_iron',8 if not hi else 20)
    # ---- cockpit well, seats + cushions, coamings, tiller, primaries, traveller, instrument plate
    kts=[TK0,0.72,0.82,0.90,TK1] if not mid else [TK0,TK1]
    wc=lambda t: hs(t)-0.34; zsole=lambda t: zs(t)-0.55
    if mid:
        face(b,[V((-wc(TK0),y(TK0),zs(TK0)-0.02)),V((wc(TK0),y(TK0),zs(TK0)-0.02)),V((wc(TK1),y(TK1),zs(TK1)-0.02)),V((-wc(TK1),y(TK1),zs(TK1)-0.02))],'stucco',(0,0,1))
    else:
        for i in range(len(kts)-1):
            a,c=kts[i],kts[i+1]
            face(b,[V((-0.30,y(a),zsole(a))),V((0.30,y(a),zsole(a))),V((0.30,y(c),zsole(c))),V((-0.30,y(c),zsole(c)))],'stucco',(0,0,1))   # sole
            for sx in (1,-1):
                zse=lambda t: zsole(t)+0.42
                face(b,[V((sx*0.30,y(a),zsole(a))),V((sx*0.30,y(c),zsole(c))),V((sx*0.30,y(c),zse(c))),V((sx*0.30,y(a),zse(a)))],'paint_white',(-sx,0,0))   # seat front
                face(b,[V((sx*0.30,y(a),zse(a))),V((sx*0.30,y(c),zse(c))),V((sx*wc(c),y(c),zse(c))),V((sx*wc(a),y(a),zse(a)))],'stucco',(0,0,1))       # seat top
                face(b,[V((sx*wc(a),y(a),zse(a))),V((sx*wc(c),y(c),zse(c))),V((sx*wc(c),y(c),zs(c)+0.20)),V((sx*wc(a),y(a),zs(a)+0.20))],'paint_white',(-sx,0,0))   # coaming inner
                face(b,[V((sx*wc(a),y(a),zs(a)+0.20)),V((sx*wc(c),y(c),zs(c)+0.20)),V((sx*(wc(c)+0.05),y(c),zs(c)+0.20)),V((sx*(wc(a)+0.05),y(a),zs(a)+0.20))],'wood_natural',(0,0,1))   # teak coaming cap
                face(b,[V((sx*(wc(a)+0.05),y(a),zs(a))),V((sx*(wc(c)+0.05),y(c),zs(c))),V((sx*(wc(c)+0.05),y(c),zs(c)+0.20)),V((sx*(wc(a)+0.05),y(a),zs(a)+0.20))],'paint_white',(sx,0,0))
        for (t_,o) in ((TK1,-1),):
            face(b,[V((-wc(t_),y(t_),zsole(t_))),V((wc(t_),y(t_),zsole(t_))),V((wc(t_),y(t_),zs(t_))),V((-wc(t_),y(t_),zs(t_)))],'paint_white',(0,o,0))   # aft cockpit wall
        face(b,[V((-wc(TK0),y(TK0)+0.001,zsole(TK0))),V((wc(TK0),y(TK0)+0.001,zsole(TK0))),V((wc(TK0),y(TK0)+0.001,zs(TK0))),V((-wc(TK0),y(TK0)+0.001,zs(TK0)))],'paint_white',(0,1,0))   # bridge-deck face
        for sx in (1,-1):
            for (t0,t1) in ((0.645,0.78),(0.795,0.93)):
                z0=zsole(t0)+0.42; b.box((sx*(0.30+wc(t0))/2,(y(t0)+y(t1))/2,z0),(wc(t0)-0.32,y(t1)-y(t0),0.07),'vinyl_seat',skip=('bottom',))
            winch(b,(sx*(wc(0.70)+0.16),y(0.70),zs(0.70)+0.02),0.075,0.16,'cast_iron',8 if not hi else 24)
            cleat_small(b,(sx*(hs(0.95)-0.12),y(0.95),zs(0.95)),PI/2,'aluminium')
            cleat_small(b,(sx*(hs(0.06)-0.04),y(0.06),zdf(hs(0.06)-0.04,0.06)),PI/2,'aluminium')
        ys,yt=y(0.955),y(0.80)
        b.tube(V((0,ys,zsole(0.955))),V((0,ys,zs(0.955)+0.05)),0.04,0.04,8,'aluminium',cap0=False,cap1=True)   # rudder stock head
        WP.obox(b,V((0,ys,zs(0.955)+0.06)),V((0,yt,zs(0.80)+0.30)),0.045,0.06,'wood_natural')                   # tiller
        WP.obox(b,V((-wc(0.9)+0.05,y(0.9),zsole(0.9)+0.43)),V((wc(0.9)-0.05,y(0.9),zsole(0.9)+0.43)),0.05,0.03,'aluminium',ends=(True,True))   # traveller
        name_board(b,(0,y(TK0)+0.006,zs(TK0)-0.12),0.40,0.10,'DEPTH  WIND  SPD','',hi,normal=(0,1,0),key_txt='paint_black')
    # ---- keel fin + bulb (antifouled), spade rudder
    kt0,kt1=0.40,0.56; ya0,ya1=y(kt0),y(kt1); zr=min(H.zk(kt0),H.zk(kt1))+0.02
    tip=[(ya0+0.55,0.32),(ya1+0.05,0.32)]
    for sx in (1,-1):
        th=0.07 if not mid else 0.06
        face(b,[V((sx*th,ya0,zr)),V((sx*th,ya1,zr)),V((sx*0.045,tip[1][0],tip[1][1])),V((sx*0.045,tip[0][0],tip[0][1]))],'paint_red',(sx,0,0))
    face(b,[V((0.07,ya0,zr)),V((-0.07,ya0,zr)),V((-0.045,tip[0][0],tip[0][1])),V((0.045,tip[0][0],tip[0][1]))],'paint_red',(0,-1,-0.3))
    face(b,[V((0.07,ya1,zr)),V((-0.07,ya1,zr)),V((-0.045,tip[1][0],tip[1][1])),V((0.045,tip[1][0],tip[1][1]))],'paint_red',(0,1,0))
    yb0,yb1=tip[0][0]-0.30,tip[1][0]+0.25
    sg=6 if mid else (8 if not hi else 20)
    b.tube(V((0,yb0+0.35,0.17)),V((0,yb1-0.25,0.17)),0.17,0.15,sg,'paint_red',cap0=False,cap1=False,phase=PI/sg)
    b.tube(V((0,yb0+0.35,0.17)),V((0,yb0,0.17)),0.17,0.02,sg,'paint_red',cap0=False,cap1=True,phase=PI/sg)
    b.tube(V((0,yb1-0.25,0.17)),V((0,yb1,0.17)),0.15,0.02,sg,'paint_red',cap0=False,cap1=True,phase=PI/sg)
    for sx in (-1,1):   # bulb wear shoe: lead shoe cheeks down to the keel bottom (= origin)
        face(b,[V((sx*0.05,yb0+0.25,0.0)),V((sx*0.05,yb1-0.2,0.0)),V((sx*0.06,yb1-0.2,0.05)),V((sx*0.06,yb0+0.25,0.05))],'paint_red',(sx,0,0))
    yr0,yr1=y(0.90),y(0.955)+0.05; zrt=H.zk(0.93)+0.02
    rb0,rb1=yr0+0.10,yr1-0.03   # tapered spade: raked leading edge, foil-thick root, thin tip
    for sx in (1,-1):
        face(b,[V((sx*0.035,yr0,zrt)),V((sx*0.035,yr1,zrt)),V((sx*0.012,rb1,0.55)),V((sx*0.022,rb0,0.55))],'paint_red',(sx,0,0))
    face(b,[V((0.035,yr0,zrt)),V((-0.035,yr0,zrt)),V((-0.022,rb0,0.55)),V((0.022,rb0,0.55))],'paint_red',(0,-1,-0.2))
    face(b,[V((-0.035,yr1,zrt)),V((0.035,yr1,zrt)),V((0.012,rb1,0.55)),V((-0.012,rb1,0.55))],'paint_red',(0,1,0))
    face(b,[V((0.022,rb0,0.55)),V((-0.022,rb0,0.55)),V((-0.012,rb1,0.55)),V((0.012,rb1,0.55))],'paint_red',(0,0,-1))
    # ---- spars + rig: deck-stepped mast on the cabin top, boom + flaked main under a sail cover, roller-furled genoa
    ym=y(0.335); zm0=zt(0.335)+0.05; ZMH=zm0+11.0
    b.tube(V((0,ym,zm0)),V((0,ym,ZMH)),0.085,0.06,4 if mid else (8 if not hi else 16),'aluminium',cap0=True,cap1=True,phase=PI/4 if mid else 0)
    zsp=zm0+5.9
    for sx in (1,-1): WP.obox(b,V((0,ym,zsp)),V((sx*0.95,ym,zsp+0.08)),0.05,0.025,'aluminium',ends=(False,True))
    zb=zm0+0.95; yb_end=y(0.93)
    b.tube(V((0,ym+0.07,zb)),V((0,yb_end,zb+0.05)),0.055,0.05,4 if mid else 6,'aluminium',cap0=True,cap1=True)
    b.tube(V((0,ym+0.25,zb+0.13)),V((0,yb_end-0.25,zb+0.15)),0.15,0.09,4 if mid else (6 if not hi else 12),'fabric',cap0=True,cap1=True,phase=PI/4)   # sail cover (navy)
    stem=V((0,y(0.02)+0.02,zs(0.02)+0.02)); mh=V((0,ym,ZMH-0.15))
    d=(mh-stem); L=d.length
    b.tube(stem+d*0.06,stem+d*0.86,0.11,0.035,4 if mid else (6 if not hi else 12),'fabric',cap0=True,cap1=True)       # furled genoa (sunbrella UV strip)
    if not mid:
        b.lathe([(0.0,0.0),(0.07,0.0),(0.07,0.12),(0.03,0.16)],8,'aluminium',c=(stem.x,stem.y,stem.z+0.0),cap_top=False)   # furler drum
        b.tube(V((0,ym,ZMH)),V((0.0,ym+0.30,ZMH+0.05)),0.04,0.03,4,'aluminium',cap0=True,cap1=True)                         # masthead crane
        b.tube(V((0,ym,ZMH)),V((0,ym,ZMH+0.9)),0.007,0.004,3,'aluminium',cap0=False,cap1=True)                              # VHF whip
        b.box((0,ym+0.30,ZMH+0.05),(0.004,0.18,0.10),'paint_red',skip=())                                                    # windex vane
        b.tube(V((0,ym-0.08,zm0+3.2)),V((0,ym-0.20,zm0+3.25)),0.03,0.04,6,'paint_white',cap0=False,cap1=True)               # steaming light
        b.tube(V((0,ym+0.12,zb-0.20)),V((0,ym+0.9,zb)),0.02,0.02,4,'aluminium',cap0=True,cap1=True)                          # vang
        mb=V((0,yb_end-0.05,zb)); tr=V((0,y(0.9),zs(0.9)-0.55+0.45))
        for o in (-0.10,0.10): b.tube(mb+V((o*0.2,0,-0.05)),tr+V((o,0,0.03)),0.006,0.006,3,'paint_beige',cap0=False,cap1=False)   # mainsheet
        b.tube(V((0.05,ym,zm0+0.4)),V((0.05,ym,ZMH-0.3)),0.006,0.006,3,'paint_beige',cap0=False,cap1=False)                   # halyard
    # standing rigging (1x19 wire)
    cp=lambda sx,t: V((sx*(hs(t)-0.13),y(t),zs(t)+0.01))
    stays=[(stem,mh),(V((0,y(0.995),zs(0.995)+0.02)),V((0,ym,ZMH)))]
    for sx in (1,-1):
        spt=V((sx*0.95,ym,zsp+0.08))
        stays+=[(cp(sx,0.35),spt),(spt,V((0,ym,ZMH-0.2))),(cp(sx,0.31),V((0,ym,zsp-0.05))),(cp(sx,0.39),V((0,ym,zsp-0.05)))]
    if mid: stays=stays[:2]   # shrouds are sub-pixel at mid range
    for a,c in stays: wire(b,a,c,0.005,'aluminium',3)
    # ---- guard rails: bow pulpit, stanchions, stern pushpit, double lifelines (railcheck members)
    RZ=0.62; r=0.0125
    if not mid:
        tp0,tp1=0.03,0.11
        legs=[(sx,tp1) for sx in (1,-1)]
        pul=[]
        for sx in (-1,1):
            x=sx*(hs(tp1)-0.07); pul.append(V((x,y(tp1),zdf(x,tp1))))
        p0,p1=pul
        ring=[p0,p0+V((0,0,RZ)),V((-0.18,y(tp0),zs(tp0)+RZ)),V((0.18,y(tp0),zs(tp0)+RZ)),p1+V((0,0,RZ)),p1]
        b.sweep(ring,r,6 if not hi else 12,'aluminium',cap0=False,cap1=False); P.rec('p',tuple(ring[0]),tuple(ring[-1]),r,pts=[tuple(q) for q in ring])
        for f_ in (0.35,0.65):
            pa=ring[2]+(ring[3]-ring[2])*f_
            pass
        for sx in (-1,1):   # forward pulpit legs to the stem head
            x=sx*0.12; pf=V((x,y(0.035),zdf(x,0.035))); top=V((sx*0.18*0.9,y(tp0),zs(tp0)+RZ-r))
            top.y=y(tp0)+0.0; b.tube(pf,top,r,r,6,'aluminium',cap0=False,cap1=False); P.rec('v',tuple(pf),tuple(top),r)
        tq0,tq1=0.88,0.99
        push=[]
        for sx in (1,-1):
            x=sx*(hs(tq0)-0.08); push.append(V((x,y(tq0),zs(tq0))))
        q0,q1=push
        pr=[q0,q0+V((0,0,RZ)),V((q0.x,y(tq1),zs(tq1)+RZ)),V((q1.x,y(tq1),zs(tq1)+RZ)),q1+V((0,0,RZ)),q1]
        b.sweep(pr,r,6 if not hi else 12,'aluminium',cap0=False,cap1=False); P.rec('p',tuple(pr[0]),tuple(pr[-1]),r,pts=[tuple(q) for q in pr])
        for sx in (1,-1):   # aft pushpit legs on the after deck
            pa=V((sx*(hs(tq1)-0.14),y(tq1)-0.0,zs(tq1))); top=V((pa.x,pa.y,zs(tq1)+RZ-r))
            b.tube(pa,top,r,r,6,'aluminium',cap0=False,cap1=False); P.rec('v',tuple(pa),tuple(top),r)
        for sx in (1,-1):
            st=[0.26,0.46,0.66]
            xs_=[sx*(hs(t)-0.07) for t in st]
            for t,x in zip(st,xs_):
                zb_=zdf(x,t) if t<=TC0 else zs(t); top=V((x,y(t),zs(t)+RZ-0.005))
                b.tube(V((x,y(t),zb_)),top,0.011,0.011,6,'aluminium',cap0=False,cap1=True); P.rec('v',(x,y(t),zb_),tuple(top),0.011)
                b.box((x,y(t),zb_),(0.05,0.05,0.006),'aluminium',skip=('bottom',))
            pf=pul[0 if sx<0 else 1]; pq=push[1 if sx<0 else 0]
            for zz in (RZ,0.33):
                a_=V((pf.x,pf.y+r,pf.z+zz)); c_=V((pq.x,pq.y-r,pq.z+zz))
                pts=[a_]+[V((x,y(t),(zdf(x,t) if t<=TC0 else zs(t))+zz)) for t,x in zip(st,xs_)]+[c_]
                for u,w_ in zip(pts[:-1],pts[1:]): b.tube(u,w_,0.003,0.003,3,'aluminium',cap0=False,cap1=False)
                P.rec('p',tuple(a_),tuple(c_),0.003,pts=[tuple(q) for q in pts])
        # fenders on the starboard side hanging from the lower lifeline, bow roller + anchor, solar panel on the pushpit
        for t in (0.36,0.52,0.70):
            x=hs(t)+0.10; zf=SWL+0.40
            fender(b,(x,y(t),zf),0.55,0.10,'paint_navy',tier,line_to=(hs(t)-0.07,y(t),zs(t)+0.33))
        ya=y(0.075); za=zdf(0,0.075)
        b.box((0,ya,za),(0.10,0.34,0.025),'aluminium',skip=('bottom',))                             # deck chock
        b.box((0,ya,za+0.025),(0.05,0.30,0.03),'stainless',skip=('bottom',))                        # plow anchor stowed in the chock
        b.box((0,ya-0.13,za+0.025),(0.22,0.08,0.03),'stainless',skip=('bottom',))
        sp=V((0,y(0.99)+0.12,zs(0.99)+RZ+0.06))
        face(b,[sp+V((-0.45,-0.25,0)),sp+V((0.45,-0.25,0)),sp+V((0.45,0.25,0.06)),sp+V((-0.45,0.25,0.06))],'glass_dark',(0,0,1))
        b.box((0,sp.y,sp.z-0.03),(0.92,0.52,0.03),'aluminium',skip=('top',))
        # dodger over the companionway: alloy frame, navy canvas, clear windows
        da,dc=y(0.535),y(TC1)+0.02; zd=zt(0.58)+0.06; w=0.80
        face(b,[V((-w,da,zd)),V((w,da,zd)),V((w*0.85,da+0.30,zd+0.55)),V((-w*0.85,da+0.30,zd+0.55))],'fabric',(0,-1,0.6))
        face(b,[V((-w*0.85,da+0.30,zd+0.55)),V((w*0.85,da+0.30,zd+0.55)),V((w*0.85,dc,zd+0.58)),V((-w*0.85,dc,zd+0.58))],'fabric',(0,0,1))
        for sx in (1,-1):
            face(b,[V((sx*w,da,zd)),V((sx*w,dc,zd)),V((sx*w*0.85,dc,zd+0.58)),V((sx*w*0.85,da+0.30,zd+0.55))],'fabric',(sx,0,0))
            face(b,[V((sx*0.08,da-0.004,zd+0.08)),V((sx*0.62,da-0.004,zd+0.08)),V((sx*0.55,da+0.22-0.004,zd+0.44)),V((sx*0.10,da+0.22-0.004,zd+0.44))],'glass_dark',(0,-1,0.6))
        b.tube(V((-w,da,zd)),V((-w*0.85,da+0.30,zd+0.55)),0.012,0.012,4,'aluminium',cap0=False,cap1=False)
        b.tube(V((w,da,zd)),V((w*0.85,da+0.30,zd+0.55)),0.012,0.012,4,'aluminium',cap0=False,cap1=False)
        # (no name / registration plates -- clean hull and stripes)
    else:
        for sx in (1,-1):
            pts=[V((sx*(hs(t)-0.07),y(t),zs(t)+RZ)) for t in (0.08,0.30,0.60,0.95)]
            for u,w_ in zip(pts[:-1],pts[1:]): b.tube(u,w_,0.012,0.012,3,'aluminium',cap0=False,cap1=False)
        b.box((0,y(0.58),zt(0.58)+0.06),(1.5,0.35,0.55),'fabric',skip=('bottom',))
    if tier=='near':
        for (t0,t1,z0) in ((0.02,0.30,SWL-0.3),(0.30,0.70,SWL-0.5),(0.70,1.0,SWL-0.3)):
            cbox(b,(0,(y(t0)+y(t1))/2,z0),(2*max(hs(t0),hs(t1)),y(t1)-y(t0),max(zs(t0),zs(t1))-z0+(0.45 if TC0<=t0<TC1 else 0.0)))
        cbox(b,(0,(ya0+ya1)/2+0.2,0.0),(0.36,ya1-ya0+0.6,zr)); ccyl(b,(0,ym,zm0),0.09,11.0,rail=True)
        for sx in (1,-1): cbox(b,(sx*(hs(0.5)-0.07),y(0.5),zs(0.5)),(0.06,y(0.88)-y(0.11),RZ),rail=True)
def sloop_far(b):
    H=SH; y=H.y; zs=H.zs; hs=H.hs
    prof=[V((0,y(0)-0.02,zs(0))),V((0,y(0.33),zs(0.33)+0.44)),V((0,y(0.62),zs(0.62)+0.44)),V((0,y(1.0),zs(1.0))),V((0,y(1.0),SWL-0.06)),
          V((0,y(0.53),0.0)),V((0,y(0.38),0.0))]
    face(b,prof,'twf_flat',(-1,0,0))
    top=[V((0,y(0)-0.02,zs(0.3))),V((hs(0.36)+0.05,y(0.36),zs(0.3))),V((hs(1.0)+0.03,y(1.0),zs(0.3))),
         V((-hs(1.0)-0.03,y(1.0),zs(0.3))),V((-hs(0.36)-0.05,y(0.36),zs(0.3)))]
    face(b,top,'twf_flat',(0,0,1))
    ym=y(0.47); zt_=zs(0.5)
    sec=[V((-1.55,ym,zt_+0.3)),V((-0.95,ym,zt_+0.3)),V((-0.95,ym,zt_+1.05)),V((0.95,ym,zt_+1.05)),V((0.95,ym,zt_+0.3)),V((1.55,ym,zt_+0.3)),V((1.34,ym,SWL)),V((0.48,ym,SWL-0.42)),V((0.0,ym,0.0)),V((-0.48,ym,SWL-0.42)),V((-1.34,ym,SWL))]
    face(b,sec,'twf_flat',(0,-1,0))
    m0=y(0.335)
    zsp=SH.zs(0.335)+0.49+5.9; ztop=SH.zs(0.335)+0.5+11.2
    face(b,[V((-0.12,m0,zt_+1.05)),V((0.12,m0,zt_+1.05)),V((0.08,m0,ztop)),V((-0.08,m0,ztop))],'twf_flat',(0,-1,0))
# ===================================================================== motorboat: 28 ft express cruiser "REEL TIME", twin outboards
EWL=0.70
EH=Hull(7.5,hs=smooth_tab([(0,0.04),(0.08,0.62),(0.22,1.08),(0.42,1.30),(0.7,1.32),(1,1.26)]),
        hw=smooth_tab([(0,0.02),(0.12,0.50),(0.3,1.02),(0.5,1.14),(1,1.12)]),
        zs=smooth_tab([(0,EWL+1.38),(0.2,EWL+1.20),(0.45,EWL+1.02),(0.8,EWL+0.92),(1,EWL+0.90)]),
        zk=smooth_tab([(0,EWL+0.2),(0.08,EWL-0.20),(0.25,EWL-0.40),(0.5,EWL-0.46),(1,EWL-0.42)]),
        WL=EWL,boot=0.11,flare=0.05,chine=(smooth_tab([(0,0.02),(0.12,0.46),(0.3,0.98),(0.5,1.10),(1,1.08)]),
                                          smooth_tab([(0,EWL),(0.12,EWL-0.06),(0.3,EWL-0.10),(1,EWL-0.08)])),
        keys=('paint_black','paint_navy','paint_white'),y0=-4.25,rake=(0.62,0.22))
EH.band=0.07   # edge loop under the rub rail (AO wedge fix)
ETS_N=[0,0.03,0.07,0.12,0.19,0.27,0.36,0.47,0.60,0.75,0.88,1.0]
ETS_M=[0,0.10,0.28,0.50,0.75,1.0]
def _outboard(b,x,yT,hi,mid):
    """300 hp outboard on the transom bracket: cowl, midsection, cavitation plate, gearcase torpedo, skeg to z 0, 3-blade prop"""
    yc=yT+0.42; zc0=EWL+0.62
    if mid:
        b.box((x,yc,zc0),(0.50,0.72,0.62),'paint_white',skip=('bottom',)); b.box((x,yc-0.02,0.0),(0.16,0.36,zc0),'plastic_black',skip=('top','bottom')); return
    b.box((x,yc,zc0),(0.50,0.72,0.42),'paint_white',skip=('bottom',),keys={'top':'paint_white'})       # lower cowl
    WP.obox(b,V((x,yc-0.33,zc0+0.42)),V((x,yc+0.30,zc0+0.42)),0.46,0.0001,'paint_white',ends=(False,False),skip=('bottom','s0','s1'))
    face(b,[V((x-0.23,yc-0.34,zc0+0.42)),V((x+0.23,yc-0.34,zc0+0.42)),V((x+0.20,yc-0.24,zc0+0.62)),V((x-0.20,yc-0.24,zc0+0.62))],'paint_white',(0,-1,0.5))
    face(b,[V((x-0.20,yc-0.24,zc0+0.62)),V((x+0.20,yc-0.24,zc0+0.62)),V((x+0.18,yc+0.26,zc0+0.58)),V((x-0.18,yc+0.26,zc0+0.58))],'paint_white',(0,0,1))
    face(b,[V((x+0.23,yc+0.36,zc0+0.42)),V((x-0.23,yc+0.36,zc0+0.42)),V((x-0.18,yc+0.26,zc0+0.58)),V((x+0.18,yc+0.26,zc0+0.58))],'paint_white',(0,1,0.4))
    for sx in (1,-1):
        face(b,[V((x+sx*0.23,yc-0.34,zc0+0.42)),V((x+sx*0.23,yc+0.36,zc0+0.42)),V((x+sx*0.18,yc+0.26,zc0+0.58)),V((x+sx*0.20,yc-0.24,zc0+0.62))],'paint_white',(sx,0,0.3))
        face(b,[V((x+sx*0.2505,yc-0.20,zc0+0.22)),V((x+sx*0.2505,yc+0.28,zc0+0.22)),V((x+sx*0.2505,yc+0.28,zc0+0.30)),V((x+sx*0.2505,yc-0.20,zc0+0.30))],'paint_navy',(sx,0,0))   # cowl wrap stripe
        face(b,[V((x+sx*0.2505,yc+0.12,zc0+0.06)),V((x+sx*0.2505,yc+0.30,zc0+0.06)),V((x+sx*0.2505,yc+0.30,zc0+0.14)),V((x+sx*0.2505,yc+0.12,zc0+0.14))],'plastic_black',(sx,0,0))   # air intake louvre
    b.box((x,yc+0.02,EWL-0.08),(0.20,0.40,zc0-EWL+0.08),'plastic_black',skip=('top','bottom'))             # midsection
    b.box((x,yc+0.05,EWL-0.10),(0.36,0.56,0.02),'plastic_black',skip=())                                   # anti-cavitation plate
    b.box((x,yc-0.40,EWL+0.15),(0.24,0.08,0.40),'stainless',skip=())                                     # transom clamp bracket
    b.tube(V((x,yc-0.26,0.26)),V((x,yc+0.24,0.26)),0.085,0.075,6,'plastic_black',cap0=True,cap1=False,phase=PI/6)   # gearcase torpedo
    b.box((x,yc-0.05,0.26),(0.08,0.30,EWL-0.36),'plastic_black',skip=('top','bottom'))                     # gearcase strut
    face(b,[V((x,yc-0.10,0.20)),V((x,yc+0.18,0.20)),V((x,yc+0.16,0.0)),V((x,yc+0.02,0.0))],'plastic_black',(1,0,0))   # skeg (lowest point)
    face(b,[V((x,yc-0.10,0.20)),V((x,yc+0.18,0.20)),V((x,yc+0.16,0.0)),V((x,yc+0.02,0.0))],'plastic_black',(-1,0,0))
    hub=V((x,yc+0.26,0.26))
    b.tube(hub,hub+V((0,0.14,0)),0.05,0.03,6,'stainless',cap0=False,cap1=True)
    for k in range(3):   # 3-blade stainless prop
        a=k*2*PI/3+0.4; d=V((math.cos(a),0,math.sin(a)))
        face(b,[hub+V((0,0.03,0))+d*0.04,hub+V((0,0.10,0))+d*0.04,hub+V((0,0.09,0))+d*0.19+V((0,0,0)),hub+V((0,0.03,0))+d*0.18],'stainless',(d.z,0.3,-d.x))
def express(b,hi=False,tier='near'):
    T_(hi,tier); mid=tier=='mid'; H=EH
    ts=ETS_M if mid else ([i/28 for i in range(29)] if hi else ETS_N)
    H.build(b,ts,'mid' if mid else 'near')
    zs=H.zs; hs=H.hs; y=H.ys; yT=H.y(1.0)   # y(t): sheer-line y (raked stem)
    TW,TK=0.40,0.97              # windshield station, aft cockpit wall
    gw=lambda t: hs(t)-0.26      # cockpit inner half-width
    zsole=lambda t: zs(t)-0.78
    # ---- foredeck (cambered non-skid) with sunpad, hatch, anchor locker, windlass
    fts=sorted(set([t for t in ts if t<=TW]+[TW]))
    deck(b,H,fts,None,'stucco',camber=0.07)
    zdf=lambda x,t: zs(t)+0.07*(1-abs(x)/max(hs(t),1e-3))
    kts=sorted(set([TW,TK]+[t for t in ts if TW<t<TK]))
    deck(b,H,kts,gw,'paint_white')       # gunwale tops
    deck(b,H,[TK,1.0],None,'stucco',camber=0.0)
    if not mid:
        rubrail(b,H,ts,'stainless',0.04,0.05)
        sheer_strip(b,H,ts,'paint_navy',h=0.11,off=0.004,dz=-0.30)                                     # navy cove stripe
        for t0,t1 in ((0.12,0.30),):
            b.box((0,(y(t0)+y(t1))/2,zs(0.21)+0.04),(1.10,y(t1)-y(t0),0.10),'vinyl_seat',skip=('bottom',))   # bow sunpad
            for k in range(3): b.box((0,y(t0)+(k+0.5)*(y(t1)-y(t0))/3,zs(0.21)+0.14),(1.08,0.012,0.006),'paint_beige',skip=('bottom',))   # pad seams
        b.box((0,y(0.34),zs(0.34)+0.05),(0.56,0.56,0.05),'glass_dark',skip=('bottom',))                   # deck hatch (smoked)
        b.box((0,y(0.34),zs(0.34)+0.05),(0.62,0.62,0.02),'aluminium',skip=('bottom',))
        b.box((0,y(0.05),zs(0.05)+0.04),(0.18,0.40,0.03),'paint_white',skip=('bottom',))                  # anchor locker lid
        b.lathe([(0.07,0.0),(0.07,0.10),(0.04,0.14),(0.0,0.15)],8,'stainless',c=(0,y(0.09),zs(0.09)+0.05),cap_top=False)   # windlass
        ya=y(0.035); za=zdf(0,0.035)
        b.box((0,ya,za),(0.10,0.22,0.02),'stainless',skip=('bottom',))                                   # flush stem-head plate (inside the sheer)
    # ---- windshield: centre + wrap panels, frame, centre walk-through opening
    zw0=zs(TW)+0.02; yw0=y(TW); yw1=yw0+0.38; zw1=zw0+0.58; xw=gw(TW)+0.10
    if mid:
        face(b,[V((-xw,yw0,zw0)),V((xw,yw0,zw0)),V((xw*0.9,yw1,zw1)),V((-xw*0.9,yw1,zw1))],'glass_dark',(0,-1,0.6))
    else:
        for sx in (1,-1):
            face(b,[V((sx*0.30,yw0,zw0)),V((sx*xw*0.82,yw0+0.06,zw0)),V((sx*xw*0.74,yw1+0.04,zw1)),V((sx*0.30,yw1,zw1))],'glass_dark',(0,-1,0.6))
            face(b,[V((sx*xw*0.82,yw0+0.06,zw0)),V((sx*xw,yw0+0.42,zw0)),V((sx*xw*0.92,yw1+0.42,zw1-0.06)),V((sx*xw*0.74,yw1+0.04,zw1))],'glass_dark',(sx,-0.5,0.4))
            b.sweep([V((sx*0.30,yw0,zw0)),V((sx*0.30,yw1,zw1)),V((sx*xw*0.74,yw1+0.04,zw1)),V((sx*xw*0.92,yw1+0.42,zw1-0.06))],0.014,4,'stainless',cap0=False,cap1=True)
        face(b,[V((-0.30,yw0,zw0)),V((0.30,yw0,zw0)),V((0.30,yw0+0.05,zw0+0.10)),V((-0.30,yw0+0.05,zw0+0.10))],'glass_dark',(0,-1,0.6))   # centre door (low)
    # ---- cockpit: sole, inner sides, helm console + wheel + dash, helm & companion seats, aft bench, table
    if mid:
        face(b,[V((-gw(TW),y(TW),zs(TW)-0.3)),V((gw(TW),y(TW),zs(TW)-0.3)),V((gw(TK),y(TK),zs(TK)-0.3)),V((-gw(TK),y(TK),zs(TK)-0.3))],'stucco',(0,0,1))
        b.box((0.45,y(0.47),zs(0.47)-0.3),(0.7,0.4,0.55),'paint_white',skip=('bottom',))
    else:
        for i in range(len(kts)-1):
            a,c=kts[i],kts[i+1]
            face(b,[V((-gw(a),y(a),zsole(a))),V((gw(a),y(a),zsole(a))),V((gw(c),y(c),zsole(c))),V((-gw(c),y(c),zsole(c)))],'stucco',(0,0,1))
            for sx in (1,-1):
                face(b,[V((sx*gw(a),y(a),zsole(a))),V((sx*gw(c),y(c),zsole(c))),V((sx*gw(c),y(c),zs(c))),V((sx*gw(a),y(a),zs(a)))],'paint_white',(-sx,0,0))
        face(b,[V((-gw(TK),y(TK),zsole(TK))),V((gw(TK),y(TK),zsole(TK))),V((gw(TK),y(TK),zs(TK))),V((-gw(TK),y(TK),zs(TK)))],'paint_white',(0,-1,0))
        face(b,[V((-gw(TW),y(TW),zsole(TW))),V((gw(TW),y(TW),zsole(TW))),V((gw(TW),y(TW),zs(TW))),V((-gw(TW),y(TW),zs(TW)))],'paint_white',(0,1,0))
        face(b,[V((-0.28,y(TW)+0.005,zsole(TW))),V((0.28,y(TW)+0.005,zsole(TW))),V((0.28,y(TW)+0.005,zsole(TW)+0.62)),V((-0.28,y(TW)+0.005,zsole(TW)+0.62))],'wood_natural',(0,1,0))   # cabin door (teak)
        # helm console (stbd) with raked dash, chart plotter, wheel, throttles
        hx=gw(0.45)-0.42; hy0,hy1=y(TW)+0.02,y(TW)+0.62; zh=zsole(0.45)
        b.box((hx,(hy0+hy1)/2,zh),(0.72,hy1-hy0,0.80),'paint_white',skip=('bottom',))
        face(b,[V((hx-0.34,hy1-0.02,zh+0.80)),V((hx+0.34,hy1-0.02,zh+0.80)),V((hx+0.34,hy1-0.26,zh+0.98)),V((hx-0.34,hy1-0.26,zh+0.98))],'plastic_black',(0,1,0.7))   # dash
        face(b,[V((hx-0.34,hy1-0.26,zh+0.98)),V((hx+0.34,hy1-0.26,zh+0.98)),V((hx+0.34,hy0,zh+0.98)),V((hx-0.34,hy0,zh+0.98))],'plastic_black',(0,0,1))
        face(b,[V((hx-0.34,hy1-0.02,zh+0.80)),V((hx-0.34,hy1-0.26,zh+0.98)),V((hx-0.34,hy0,zh+0.98)),V((hx-0.34,hy0,zh+0.80))],'paint_white',(-1,0,0))
        face(b,[V((hx+0.34,hy1-0.02,zh+0.80)),V((hx+0.34,hy1-0.26,zh+0.98)),V((hx+0.34,hy0,zh+0.98)),V((hx+0.34,hy0,zh+0.80))],'paint_white',(1,0,0))
        face(b,[V((hx-0.26,hy1-0.075,zh+0.85)),V((hx+0.10,hy1-0.075,zh+0.85)),V((hx+0.10,hy1-0.195,zh+0.94)),V((hx-0.26,hy1-0.195,zh+0.94))],'glass_dark',(0,1,0.7))   # MFD screen
        wc=V((hx+0.18,hy1+0.02,zh+0.86))
        b.lathe([(0.20,-0.012),(0.20,0.012),(0.17,0.012),(0.17,-0.012)],12 if not hi else 32,'stainless',c=(0,0,0),cap_top=False) if False else None
        rim=[wc+V((0.19*math.cos(a),-0.06*math.sin(a)*0.0,0.19*math.sin(a))) for a in [k*2*PI/10 for k in range(11)]]
        rim=[V((p.x,p.y-0.05*(p.z-wc.z)/0.19*0.5,p.z)) for p in rim]
        b.sweep(rim,0.014,4,'stainless',cap0=False,cap1=False)                                            # wheel rim
        for k in range(3):
            a=PI/2+k*2*PI/3; b.tube(wc,V((wc.x+0.18*math.cos(a),wc.y-0.045*math.sin(a)*0.5,wc.z+0.18*math.sin(a))),0.008,0.008,3,'stainless',cap0=False,cap1=False)
        b.tube(wc,V((wc.x,hy1-0.16,wc.z+0.10)),0.025,0.03,6,'stainless',cap0=True,cap1=False)
        for o in (-0.30,-0.22): b.tube(V((hx+o,hy1-0.20,zh+0.97)),V((hx+o,hy1-0.08,zh+1.12)),0.010,0.010,4,'stainless',cap0=False,cap1=True)   # throttles
        # helm + companion seats: pedestal, vinyl bolster seat with backrest
        for sx,yy in ((hx,hy1+0.55),(-hx,hy1+0.55)):
            b.tube(V((sx,yy,zsole(0.5))),V((sx,yy,zsole(0.5)+0.45)),0.05,0.05,6,'stainless',cap0=False,cap1=False)
            b.box((sx,yy,zsole(0.5)+0.45),(0.62,0.52,0.14),'vinyl_seat',skip=())
            WP.obox(b,V((sx,yy+0.24,zsole(0.5)+0.59)),V((sx,yy+0.30,zsole(0.5)+1.10)),0.62,0.12,'vinyl_seat',up=(0,-1,0))
            b.box((sx,yy-0.27,zsole(0.5)+0.40),(0.60,0.04,0.06),'stainless',skip=('bottom',))
        # companion console (port) with glovebox + grab rail
        b.box((-hx,(hy0+hy1)/2,zh),(0.72,hy1-hy0,0.72),'paint_white',skip=('bottom',))
        face(b,[V((-hx-0.30,hy1+0.004,zh+0.22)),V((-hx+0.30,hy1+0.004,zh+0.22)),V((-hx+0.30,hy1+0.004,zh+0.58)),V((-hx-0.30,hy1+0.004,zh+0.58))],'wood_natural',(0,1,0))
        b.sweep([V((-hx-0.30,hy1-0.10,zh+0.72)),V((-hx-0.30,hy1-0.10,zh+0.84)),V((-hx+0.30,hy1-0.10,zh+0.84)),V((-hx+0.30,hy1-0.10,zh+0.72))],0.012,4,'stainless',cap0=False,cap1=False)
        # aft L-lounge + transom bench + teak table on a pedestal
        ya=y(0.80); yb=y(TK)
        b.box((0,(ya+yb)/2+0.25,zsole(0.85)),(2*gw(0.9)-0.02,0.55,0.44),'paint_white',skip=('bottom',))
        b.box((0,(ya+yb)/2+0.25,zsole(0.85)+0.44),(2*gw(0.9)-0.06,0.53,0.10),'vinyl_seat',skip=('bottom',))
        WP.obox(b,V((0,yb-0.06,zsole(0.85)+0.54)),V((0,yb-0.02,zs(TK)+0.02)),2*gw(0.9)-0.06,0.10,'vinyl_seat',up=(0,-1,0))
        b.box((-gw(0.7)+0.28,y(0.70),zsole(0.7)),(0.52,y(0.80)-y(0.70)+0.4,0.44),'paint_white',skip=('bottom',))
        b.box((-gw(0.7)+0.28,y(0.70),zsole(0.7)+0.44),(0.50,y(0.80)-y(0.70)+0.38,0.10),'vinyl_seat',skip=('bottom',))
        b.tube(V((-0.2,y(0.78),zsole(0.78))),V((-0.2,y(0.78),zsole(0.78)+0.66)),0.04,0.04,6,'stainless',cap0=False,cap1=False)
        b.box((-0.2,y(0.78),zsole(0.78)+0.66),(0.70,0.90,0.04),'wood_natural',skip=())
        # cockpit drain scupper + transom door
        face(b,[V((gw(TK)-0.6,y(TK)-0.004,zsole(TK)+0.02)),V((gw(TK)-0.15,y(TK)-0.004,zsole(TK)+0.02)),V((gw(TK)-0.15,y(TK)-0.004,zs(TK)-0.05)),V((gw(TK)-0.6,y(TK)-0.004,zs(TK)-0.05))],'paint_white',(0,-1,0))
    # ---- hardtop: 4 alloy posts on the gunwales, fibreglass roof, radar dome, nav light, whip antennas, LED + speaker pods
    tp=(0.46,0.72); zr=zsole(0.6)+2.05; px=lambda t: gw(t)+0.10
    seg=4 if mid else 6
    for t in tp:
        for sx in (1,-1):
            b.tube(V((sx*px(t),y(t),zs(t))),V((sx*(px(t)-0.10),y(t)+0.05,zr)),0.035,0.035,seg,'aluminium',cap0=False,cap1=False)
            if not mid: b.box((sx*px(t),y(t),zs(t)),(0.10,0.10,0.01),'aluminium',skip=('bottom',))
    yr0,yr1=y(tp[0])-0.45,y(tp[1])+0.35; rx0=px(tp[0])+0.04
    b.box((0,(yr0+yr1)/2,zr),(2*rx0,yr1-yr0,0.08),'paint_white',skip=())
    if not mid:
        face(b,[V((-rx0+0.1,yr0+0.05,zr+0.08)),V((rx0-0.1,yr0+0.05,zr+0.08)),V((rx0-0.1,yr1-0.05,zr+0.12)),V((-rx0+0.1,yr1-0.05,zr+0.12))],'paint_white',(0,0,1))
        face(b,[V((-rx0+0.08,yr0+0.01,zr+0.08)),V((rx0-0.08,yr0+0.01,zr+0.08)),V((rx0-0.1,yr0+0.05,zr+0.08)),V((-rx0+0.1,yr0+0.05,zr+0.08))],'paint_white',(0,-1,1))
        b.lathe([(0.26,0.0),(0.26,0.12),(0.20,0.20),(0.0,0.22)],8 if not hi else 20,'paint_white',c=(0,(yr0+yr1)/2-0.3,zr+0.12),cap_top=False)   # radar dome
        b.tube(V((0,yr1-0.15,zr+0.12)),V((0,yr1-0.15,zr+0.62)),0.012,0.012,4,'stainless',cap0=False,cap1=True)   # all-round light pole
        b.lathe([(0.03,0.0),(0.03,0.06),(0.0,0.07)],6,'glass_dark',c=(0,yr1-0.15,zr+0.62),cap_top=False)
        for sx in (1,-1):
            b.tube(V((sx*(rx0-0.15),yr1-0.25,zr+0.10)),V((sx*(rx0-0.15),yr1-0.30,zr+2.3)),0.010,0.005,3,'paint_white',cap0=False,cap1=True)   # VHF whips
            b.box((sx*(rx0-0.10),yr0+0.05,zr+0.08),(0.10,0.08,0.06),'glass_dark',skip=('bottom',))              # spreader LEDs
            b.lathe([(0.08,0.0),(0.08,0.10),(0.0,0.12)],6,'plastic_black',c=(sx*0.7,yr1-0.5,zr),cap_top=False) if False else None
            b.box((sx*0.55,(yr0+yr1)/2+0.3,zr-0.12),(0.22,0.22,0.12),'plastic_black',skip=())                      # underside speaker pods
    # ---- swim platform + transom bracket, transom door, swim ladder hatch, stern cleats, twin outboards
    zp=EWL+0.20
    b.box((0,yT+0.36,zp-0.05),(2*hs(1.0)-0.10,0.72,0.08),'paint_white',skip=())
    if not mid:
        b.box((0,yT+0.36,zp+0.03),(2*hs(1.0)-0.16,0.66,0.02),'wood_natural',skip=('bottom',))
        for k in range(7): b.box((-hs(1.0)+0.20+k*(2*hs(1.0)-0.4)/6,yT+0.36,zp+0.05),(0.012,0.64,0.003),'plastic_black',skip=('bottom',))   # teak seams
        b.box((-0.95,yT+0.60,zp+0.05),(0.32,0.18,0.03),'stainless',skip=('bottom',))                         # flush ladder hatch
        for sx in (1,-1):
            cleat_small(b,(sx*(hs(1.0)-0.12),y(0.96),zs(0.96)),PI/2,'stainless')
            cleat_small(b,(sx*(hs(0.48)-0.06),y(0.48),zs(0.48)),PI/2,'stainless')
            cleat_small(b,(sx*(hs(0.05)-0.06),y(0.05),zdf(hs(0.05)-0.06,0.05)),PI/2,'stainless')
    for sx in (1,-1): _outboard(b,sx*0.40,yT+0.32,hi,mid)
    # ---- bow rail (stainless, 2 stanchions per side + bow loop), fenders on the stbd gunwale
    RZ=0.50; r=0.0125
    if not mid:
        t0r,t1r=0.03,0.40
        sts=[0.12,0.24]
        ring=[]
        for sx in (-1,1):
            x=sx*(hs(t1r)-0.10)
            if sx<0: ring+=[V((x,y(t1r),zdf(x,t1r))),V((x,y(t1r),zdf(x,t1r)+RZ))]+[V((sx*(hs(t)-0.08),y(t),zdf(sx*(hs(t)-0.08),t)+RZ)) for t in sts[::-1]]
            else: ring+=[V((sx*(hs(t)-0.08),y(t),zdf(sx*(hs(t)-0.08),t)+RZ)) for t in sts]+[V((x,y(t1r),zdf(x,t1r)+RZ)),V((x,y(t1r),zdf(x,t1r)))]
            if sx<0: ring+=[V((-0.20,y(t0r),zs(t0r)+RZ*0.9)),V((0.20,y(t0r),zs(t0r)+RZ*0.9))]
        b.sweep(ring,r,6 if not hi else 12,'stainless',cap0=False,cap1=False); P.rec('p',tuple(ring[0]),tuple(ring[-1]),r,pts=[tuple(q) for q in ring])
        for t in sts:
            for sx in (1,-1):
                x=sx*(hs(t)-0.08); top=V((x,y(t),zdf(x,t)+RZ-r))
                b.tube(V((x,y(t),zdf(x,t))),top,0.011,0.011,6,'stainless',cap0=False,cap1=False); P.rec('v',(x,y(t),zdf(x,t)),tuple(top),0.011)
                b.box((x,y(t),zdf(x,t)),(0.05,0.05,0.006),'stainless',skip=('bottom',))
        for sx in (-1,1):
            x=sx*0.11; pf=V((x,y(0.035),zdf(x,0.035)))
            top=V((x,y(t0r),zs(t0r)+RZ*0.9-r)); b.tube(pf,top,r,r,6,'stainless',cap0=False,cap1=False); P.rec('v',tuple(pf),tuple(top),r)
        for t in (0.50,0.68):
            x=hs(t)+0.09; fender(b,(x,y(t),EWL+0.55),0.50,0.09,'paint_navy',tier,line_to=(hs(t)-0.02,y(t),zs(t)))
    else:
        for sx in (1,-1):
            pts=[V((sx*(hs(t)-0.08),y(t),zs(t)+RZ)) for t in (0.04,0.20,0.40)]
            for u,w_ in zip(pts[:-1],pts[1:]): b.tube(u,w_,0.012,0.012,3,'stainless',cap0=False,cap1=False)
    if tier=='near':
        for (t0,t1,z0) in ((0.03,0.30,EWL-0.3),(0.30,1.0,EWL-0.45)):
            cbox(b,(0,(y(t0)+y(t1))/2,z0),(2*max(hs(t0),hs(t1)),y(t1)-y(t0),max(zs(t0),zs(t1))-z0))
        cbox(b,(0,yT+0.36,zp-0.05),(2*hs(1.0),0.72,0.10))
        cbox(b,(0,yT+0.75,0.0),(1.3,0.8,EWL+1.25))
        cbox(b,(0,(yr0+yr1)/2,zr),(2*rx0,yr1-yr0,0.10))
        for t in tp:
            for sx in (1,-1): ccyl(b,(sx*(px(t)-0.05),y(t),zs(t)),0.05,zr-zs(t),rail=True)
        for sx in (1,-1): cbox(b,(sx*(hs(0.22)-0.08),y(0.22),zs(0.22)),(0.06,y(0.40)-y(0.04),RZ),rail=True)
def express_far(b):
    H=EH; y=H.ys; zs=H.zs; hs=H.hs; yT=H.y(1.0); zr=zs(0.6)-0.78+2.05
    prof=[V((0,y(0)-0.02,zs(0))),V((0,y(0.40),zs(0.40)+0.6)),V((0,y(0.40),zr+0.08)),V((0,yT-0.2,zr+0.08)),V((0,yT-0.2,zs(1.0))),
          V((0,yT+0.95,EWL+1.24)),V((0,yT+0.95,0.0)),V((0,H.y(0.0),EWL-0.02))]
    face(b,prof,'twf_flat',(-1,0,0))
    top=[V((0,y(0)-0.02,zs(0.5))),V((hs(0.2)+0.06,y(0.2),zs(0.5))),V((hs(1.0)+0.04,yT+0.7,zs(0.5))),V((-hs(1.0)-0.04,yT+0.7,zs(0.5))),V((-hs(0.2)-0.06,y(0.2),zs(0.5)))]
    face(b,top,'twf_flat',(0,0,1))
    ym=y(0.6); z6=zs(0.6)
    face(b,[V((-1.31,ym,z6)),V((-1.12,ym,z6+0.62)),V((1.12,ym,z6+0.62)),V((1.31,ym,z6)),V((1.13,ym,EWL)),V((0.0,ym,EWL-0.46)),V((-1.13,ym,EWL))],'twf_flat',(0,-1,0))
    face(b,[V((-1.10,ym,zr)),V((1.10,ym,zr)),V((1.10,ym,zr+0.10)),V((-1.10,ym,zr+0.10))],'twf_flat',(0,-1,0))
    for sx in (1,-1): face(b,[V((sx*0.40-0.10,yT+0.6,0.0)),V((sx*0.40+0.10,yT+0.6,0.0)),V((sx*0.40+0.10,yT+0.6,EWL-0.1)),V((sx*0.40-0.10,yT+0.6,EWL-0.1))],'twf_flat',(0,-1,0))
# ===================================================================== fishing boat: 40 ft wooden salmon troller "MARY ELLEN"
TWL=1.35
TH=Hull(11.0,hs=smooth_tab([(0,0.05),(0.1,1.05),(0.3,1.80),(0.55,1.95),(0.8,1.85),(1,1.50)]),
        hw=smooth_tab([(0,0.02),(0.12,0.80),(0.35,1.62),(0.55,1.74),(0.85,1.48),(1,1.02)]),
        zs=smooth_tab([(0,TWL+2.05),(0.25,TWL+1.55),(0.6,TWL+1.22),(0.9,TWL+1.30),(1,TWL+1.40)]),
        zk=smooth_tab([(0,TWL-0.05),(0.08,TWL-0.62),(0.25,0.42),(0.5,0.36),(0.85,0.46),(1,TWL-0.30)]),
        WL=TWL,boot=0.12,flare=0.06,keys=('paint_red','paint_green','wood_weathered'),rake=(0.45,0.22))
TTS_N=[0,0.03,0.07,0.12,0.18,0.26,0.35,0.45,0.55,0.65,0.75,0.85,0.93,1.0]
TTS_M=[0,0.10,0.26,0.45,0.65,0.85,1.0]
def troller(b,hi=False,tier='near'):
    T_(hi,tier); mid=tier=='mid'; H=TH
    ts=TTS_M if mid else ([i/30 for i in range(31)] if hi else TTS_N)
    H.build(b,ts,'mid' if mid else 'near')
    zs=H.zs; hs=H.hs; y=H.ys; yT=H.y(1.0)
    BW=0.50 if not mid else 0.45
    # ---- full keel + deadwood to the origin, rudder hung on the sternpost, bronze wheel in the aperture
    kp=[(0.10,0.30),(0.30,0.08),(0.60,0.02),(0.90,0.0)]
    for sx in (1,-1):
        for (ta,za),(tc,zc) in zip(kp[:-1],kp[1:]):
            face(b,[V((sx*0.11,H.y(ta),za)),V((sx*0.11,H.y(tc),zc)),V((sx*0.11,H.y(tc),H.zk(tc)+0.04)),V((sx*0.11,H.y(ta),H.zk(ta)+0.04))],'paint_red',(sx,0,0))
    face(b,[V((0.11,H.y(0.10),0.30)),V((-0.11,H.y(0.10),0.30)),V((-0.06,H.y(0.06),H.zk(0.06)+0.04)),V((0.06,H.y(0.06),H.zk(0.06)+0.04))],'paint_red',(0,-1,-0.5))
    ya_,yr0,yr1=H.y(0.90),H.y(0.925),H.y(0.995)
    face(b,[V((0.11,ya_,0.0)),V((-0.11,ya_,0.0)),V((-0.11,ya_,H.zk(0.9)+0.04)),V((0.11,ya_,H.zk(0.9)+0.04))],'paint_red',(0,1,0))   # sternpost / aperture face
    zrt=H.zk(0.96)+0.02
    for sx in (1,-1): face(b,[V((sx*0.05,yr0,0.05)),V((sx*0.05,yr1,0.08)),V((sx*0.05,yr1,zrt)),V((sx*0.05,yr0,zrt))],'paint_red',(sx,0,0))
    face(b,[V((0.05,yr1,0.08)),V((-0.05,yr1,0.08)),V((-0.05,yr1,zrt)),V((0.05,yr1,zrt))],'paint_red',(0,1,0))
    face(b,[V((-0.11,ya_,0.0)),V((0.11,ya_,0.0)),V((0.05,yr1,0.08)),V((-0.05,yr1,0.08))],'paint_red',(0,0,-1)) if False else None
    b.box((0,(ya_+yr1)/2,0.0),(0.14,yr1-ya_,0.05),'cast_iron',skip=('bottom',))                                      # keel shoe / heel
    if not mid:
        hub=V((0,(ya_+yr0)/2,0.45))
        for k in range(3):
            a=k*2*PI/3+0.3; d=V((math.cos(a),0,math.sin(a)))
            face(b,[hub+d*0.05+V((0,-0.03,0)),hub+d*0.05+V((0,0.03,0)),hub+d*0.30+V((0,0.02,0)),hub+d*0.28+V((0,-0.04,0))],'brass',(d.z,0.2,-d.x))
        b.tube(hub+V((0,-0.10,0)),hub+V((0,0.08,0)),0.05,0.04,6,'brass',cap0=False,cap1=True)
    # ---- deck, bulwarks (planked outside, painted inside, teak cap), scuppers, guard (rub) rail
    deck(b,H,ts,None,'wood_natural',camber=0.08)
    sts=ts if not mid else ts
    for sx in (1,-1):
        for i in range(len(sts)-1):
            ta,tc=sts[i],sts[i+1]; a,c=H.sheer(ta),H.sheer(tc); a.x*=sx; c.x*=sx; up=V((0,0,BW))
            fa,fc=taper(ta,0.07),taper(tc,0.07); ia=V((-sx*0.07*fa,0,0)); ic=V((-sx*0.07*fc,0,0))
            face(b,[a,c,c+up,a+up],'wood_weathered',(sx,-0.3 if ta<0.1 else 0,0))
            if not mid:
                if tc>0.03: face(b,[a+ia,c+ic,c+ic+up,a+ia+up],'paint_white',(-sx,0,0))
                face(b,[a+up+ia*1.15,c+up+ic*1.15,c+up+V((sx*0.03*fc,0,0.03)),a+up+V((sx*0.03*fa,0,0.03))],'wood_natural',(0,0,1))   # cap rail
    if not mid:
        rubrail(b,H,ts,'wood_pole',0.06,0.09)
        sheer_strip(b,H,ts,'paint_green',h=0.06,off=0.004,dz=BW-0.10)   # green sheer plank
    # ---- wheelhouse: planked walls, raked front with 3 windows, side windows + stbd door, visor, green roof
    W0,W1=0.27,0.50; wy0,wy1=y(W0),y(W1); wz=zs(0.40); wh=2.05; ww=1.25
    zf=lambda t: zs(t)
    if mid:
        b.box((0,(wy0+wy1)/2,zs(W1)-0.1),(2*ww,wy1-wy0,wh+zs(0.40)-zs(W1)+0.1),'wood_white',skip=('bottom',),keys={'top':'paint_green'})
    else:
        zr=wz+wh
        fr=0.30   # front rake (m)
        for sx in (1,-1):
            face(b,[V((sx*ww,wy0+fr,zs(W0))),V((sx*ww,wy1,zs(W1))),V((sx*ww,wy1,zr)),V((sx*ww,wy0,zr))],'wood_white',(sx,0,0))
        face(b,[V((-ww,wy0+fr,zs(W0))),V((ww,wy0+fr,zs(W0))),V((ww,wy0,zr)),V((-ww,wy0,zr))],'wood_white',(0,-1,0.15))
        face(b,[V((-ww,wy1,zs(W1))),V((ww,wy1,zs(W1))),V((ww,wy1,zr)),V((-ww,wy1,zr))],'wood_white',(0,1,0))
        b.box((0,(wy0+wy1)/2,zr),(2*ww+0.16,wy1-wy0+0.30,0.08),'paint_green',skip=())                                 # roof + overhang
        face(b,[V((-ww-0.08,wy0-0.15,zr)),V((ww+0.08,wy0-0.15,zr)),V((ww+0.08,wy0-0.50,zr+0.10)),V((-ww-0.08,wy0-0.50,zr+0.10))],'paint_green',(0,-0.3,1))   # sun visor
        face(b,[V((-ww-0.08,wy0-0.15,zr)),V((-ww-0.08,wy0-0.50,zr+0.10)),V((ww+0.08,wy0-0.50,zr+0.10)),V((ww+0.08,wy0-0.15,zr))],'paint_green',(0,0.3,-1))
        for sx in (1,-1):   # corner posts
            WP.obox(b,V((sx*ww,wy0+fr,zs(W0))),V((sx*ww,wy0,zr)),0.07,0.07,'paint_green',ends=(False,False))
            WP.obox(b,V((sx*ww,wy1,zs(W1))),V((sx*ww,wy1,zr)),0.07,0.07,'paint_green',ends=(False,False))
        gz0,gz1=wz+1.05,wz+1.75
        def fw(xa,xb,za,zb):   # front window on the raked front (y follows the rake)
            yy=lambda z: wy0+fr*(zr-z)/(zr-zs(W0))-0.006
            face(b,[V((xa,yy(za),za)),V((xb,yy(za),za)),V((xb,yy(zb),zb)),V((xa,yy(zb),zb))],'glass_dark',(0,-1,0.15))
        for xa,xb in ((-1.12,-0.40),(-0.34,0.34),(0.40,1.12)): fw(xa,xb,gz0,gz1)
        for sx in (1,-1):
            for ya,yb in ((wy0+0.25,wy0+0.85),(wy0+1.0,wy0+1.55)):
                face(b,[V((sx*(ww+0.006),ya,gz0)),V((sx*(ww+0.006),yb,gz0)),V((sx*(ww+0.006),yb,gz1)),V((sx*(ww+0.006),ya,gz1))],'glass_dark',(sx,0,0))
        dy0,dy1=wy1-0.85,wy1-0.15
        face(b,[V((ww+0.008,dy0,zs(W1)+0.12)),V((ww+0.008,dy1,zs(W1)+0.12)),V((ww+0.008,dy1,wz+1.92)),V((ww+0.008,dy0,wz+1.92))],'paint_green',(1,0,0))      # stbd door
        face(b,[V((ww+0.012,dy0+0.12,wz+1.25)),V((ww+0.012,dy1-0.12,wz+1.25)),V((ww+0.012,dy1-0.12,wz+1.75)),V((ww+0.012,dy0+0.12,wz+1.75))],'glass_dark',(1,0,0))
        face(b,[V((-0.45,wy1+0.006,zs(W1)+0.10)),V((0.25,wy1+0.006,zs(W1)+0.10)),V((0.25,wy1+0.006,wz+1.90)),V((-0.45,wy1+0.006,wz+1.90))],'paint_green',(0,1,0))   # aft door
        face(b,[V((0.50,wy1+0.006,gz0)),V((1.05,wy1+0.006,gz0)),V((1.05,wy1+0.006,gz1)),V((0.50,wy1+0.006,gz1))],'glass_dark',(0,1,0))
        # roof gear: open radar array, searchlight, horn, VHF whips, liferaft canister in cradle, stove pipe
        rc=V((0,(wy0+wy1)/2+0.2,zr+0.08))
        b.box((rc.x,rc.y,rc.z),(0.25,0.25,0.22),'plastic_white',skip=('bottom',))
        b.box((rc.x,rc.y,rc.z+0.22),(1.30,0.14,0.10),'plastic_white',skip=())
        b.lathe([(0.10,0.0),(0.12,0.16),(0.0,0.17)],6,'stainless',c=(-0.6,wy0+0.1,zr+0.08),cap_top=False)
        b.tube(V((0.55,wy0+0.05,zr+0.20)),V((0.55,wy0-0.25,zr+0.20)),0.03,0.08,6,'stainless',cap0=True,cap1=False)
        b.box((0.55,wy0+0.05,zr+0.08),(0.05,0.05,0.12),'stainless',skip=('bottom',))
        for sx in (1,-1): b.tube(V((sx*1.05,wy1-0.15,zr+0.08)),V((sx*1.10,wy1-0.15,zr+3.2)),0.012,0.006,3,'paint_white',cap0=False,cap1=True)
        lr=V((-0.55,wy1-0.45,zr+0.24))
        b.tube(lr+V((0,-0.40,0)),lr+V((0,0.40,0)),0.22,0.22,8,'plastic_white',cap0=True,cap1=True)
        for o in (-0.25,0.25): b.box((lr.x,lr.y+o,zr+0.08),(0.40,0.06,0.10),'stainless',skip=('bottom',))
        b.tube(V((0.85,wy1-0.6,zr+0.08)),V((0.85,wy1-0.6,zr+0.65)),0.06,0.06,6,'cast_iron',cap0=False,cap1=False)
        b.lathe([(0.12,0.0),(0.12,0.04),(0.0,0.08)],6,'cast_iron',c=(0.85,wy1-0.6,zr+0.65),cap_top=False)
        # life ring on the aft wall
        lc=V((0.75+0.0,wy1+0.05,wz+0.95)); n_=8
        pts=[lc+V((0.30*math.cos(2*PI*i/n_),0,0.30*math.sin(2*PI*i/n_))) for i in range(n_+1)]
        b.sweep(pts,0.06,4,'plastic_orange',cap0=False,cap1=False)
    # ---- mast + crosstree, stowed trolling poles, stays, lights
    ym=y(0.22); zd=zs(0.22); ZM=zd+8.0
    b.tube(V((0,ym,zd)),V((0,ym,ZM)),0.11,0.07,4 if mid else (6 if not hi else 14),'wood_pole',cap0=False,cap1=True)
    zx=zd+6.6
    pv=[(sx,V((sx*(hs(0.25)-0.20),y(0.25),zs(0.25)+0.45))) for sx in (1,-1)]
    tip=lambda sx: V((sx*1.15,ym+0.9,zd+11.6))
    for sx,p in pv:
        t_=tip(sx); b.tube(p,t_,0.075,0.035,4 if mid else 6,'wood_pole',cap0=True,cap1=True)
        f=(zx-p.z)/(t_.z-p.z); q=p+(t_-p)*f
        WP.obox(b,V((0,ym,zx)),q,0.08,0.08,'wood_pole',ends=(False,True)) if not mid else b.tube(V((0,ym,zx)),q,0.04,0.04,3,'wood_pole',cap0=False,cap1=False)
        if not mid:
            b.box((p.x,p.y,p.z-0.45),(0.14,0.20,0.40),'cast_iron',skip=('bottom',))                                  # pole pivot bracket on the bulwark
            wire(b,t_,V((0,ym,ZM)),0.006,'stainless',3)                                                             # topping lift
            wire(b,t_,V((sx*(hs(0.08)-0.10),y(0.08),zs(0.08)+BW)),0.005,'stainless',3)                             # forward guy
            b.lathe([(0.03,0.0),(0.04,0.06),(0.0,0.08)],5,'brass',c=(t_.x,t_.y,t_.z-0.4),cap_top=False)             # strike bell
    if not mid:
        wire(b,V((0,y(0.0)+0.05,zs(0)+0.1)),V((0,ym,ZM-0.2)),0.007,'stainless',3)                                  # forestay
        for sx in (1,-1): wire(b,V((sx*(hs(0.24)-0.03),y(0.24),zs(0.24)+BW)),V((0,ym,zx+0.1)),0.007,'stainless',3)
        b.box((0,ym-0.12,ZM-0.6),(0.12,0.06,0.14),'plastic_white',skip=())                                        # steaming light box
        b.lathe([(0.05,0.0),(0.05,0.10),(0.0,0.12)],6,'glass_dark',c=(0,ym,ZM),cap_top=False)
    # ---- fish hold hatch, trolling pit with gurdies, anchor + windlass, bitts + cleats, tyre fenders, lettering
    if not mid:
        hy0,hy1=y(0.56),y(0.68); zh=zs(0.62)
        b.box((0,(hy0+hy1)/2,zh),(1.30,hy1-hy0,0.30),'wood_natural',skip=('bottom','top'))
        b.box((0,(hy0+hy1)/2,zh+0.30),(1.36,hy1-hy0+0.06,0.06),'paint_green',skip=('bottom',))
        for o in (-0.3,0.3): b.box((0,(hy0+hy1)/2+o,zh+0.36),(1.38,0.05,0.01),'paint_beige',skip=('bottom',))       # hatch lashings
        py0,py1=y(0.86),y(0.95); zp=zs(0.90)
        for sx in (1,-1):
            b.box((sx*0.62,(py0+py1)/2,zp),(0.06,py1-py0,0.45),'wood_natural',skip=('bottom',))
        for yy in (py0,py1): b.box((0,yy,zp),(1.30,0.06,0.45),'wood_natural',skip=('bottom',))
        face(b,[V((-0.59,py0+0.03,zp+0.02)),V((0.59,py0+0.03,zp+0.02)),V((0.59,py1-0.03,zp+0.02)),V((-0.59,py1-0.03,zp+0.02))],'plastic_black',(0,0,1))   # pit well (shadowed)
        for sx in (1,-1):   # hydraulic gurdies on the pit coaming
            gc=V((sx*0.95,(py0+py1)/2,zp+0.55))
            b.tube(gc+V((-0.14,0,0)),gc+V((0.14,0,0)),0.16,0.16,6 if not hi else 16,'stainless',cap0=True,cap1=True)
            b.box((gc.x,gc.y,zp),(0.06,0.20,0.40),'paint_green',skip=('bottom',))
            b.tube(gc+V((sx*0.14,0,0)),gc+V((sx*0.30,-0.2,0.4)),0.012,0.012,3,'stainless',cap0=False,cap1=True)     # block arm
        b.lathe([(0.10,0.0),(0.10,0.18),(0.07,0.22),(0.0,0.23)],6,'cast_iron',c=(0,y(0.07),zs(0.07)+0.05),cap_top=False)   # windlass
        ya=y(0.13); za=zs(0.13)+0.08
        b.box((0,ya,za),(0.07,0.55,0.05),'galvanized',skip=('bottom',))                                          # fisherman anchor lashed on deck
        b.box((0,ya-0.24,za),(0.62,0.07,0.05),'galvanized',skip=('bottom',))
        b.box((0,ya+0.24,za),(0.40,0.05,0.04),'galvanized',skip=('bottom',))
        for t in (0.12,0.97):
            for sx in (1,-1):
                bc=V((sx*(hs(t)-0.35),y(t),zs(t)))
                b.tube(bc,bc+V((0,0,0.32)),0.06,0.06,6,'cast_iron',cap0=False,cap1=True)                            # bitts
        for t in (0.42,0.62,0.78):   # tyre fenders over the port bulwark
            p=H.sheer(t); p.x=-p.x-0.12; c=p+V((0,0,-0.55)); n_=10
            pts=[c+V((0,0.26*math.cos(2*PI*i/n_),0.26*math.sin(2*PI*i/n_))) for i in range(n_+1)]
            b.sweep(pts,0.085,4,'rubber_black',cap0=False,cap1=False)
            wire(b,c+V((0,0,0.33)),V((-(hs(t)-0.03),y(t),zs(t)+BW)),0.008,'paint_beige',3)
    else:
        b.box((0,(y(0.56)+y(0.68))/2,zs(0.62)),(1.36,y(0.68)-y(0.56),0.36),'paint_green',skip=('bottom',))
        b.box((0,(y(0.86)+y(0.95))/2,zs(0.9)),(1.30,y(0.95)-y(0.86),0.45),'wood_natural',skip=('bottom',))
        b.box((0,(y(0.27)+y(0.50))/2,zs(0.40)+2.13),(1.30,0.14,0.30),'plastic_white',skip=('bottom',))
    if tier=='near':
        for (t0,t1,z0) in ((0.03,0.25,TWL-0.6),(0.25,0.75,0.35),(0.75,1.0,0.4)):
            cbox(b,(0,(H.y(t0)+H.y(t1))/2,z0),(2*max(hs(t0),hs(t1)),H.y(t1)-H.y(t0),max(zs(t0),zs(t1))+BW-z0))
        cbox(b,(0,(H.y(0.10)+H.y(0.995))/2,0.0),(0.24,H.y(0.995)-H.y(0.10),0.45))
        cbox(b,(0,(wy0+wy1)/2,zs(W1)),(2*ww,wy1-wy0,wz+wh-zs(W1)+0.1))
        ccyl(b,(0,ym,zd),0.11,8.0,rail=True)
        for sx,p in pv: ccyl(b,(p.x*0.8,p.y,p.z),0.08,10.5,rail=True)
def troller_far(b):
    H=TH; y=H.ys; zs=H.zs; hs=H.hs; yT=H.y(1.0); wz=zs(0.40); zr=wz+2.13
    prof=[V((0,y(0)-0.02,zs(0)+0.5)),V((0,y(0.27),zr)),V((0,y(0.50),zr)),V((0,yT,zs(1.0)+0.5)),V((0,yT,TWL-0.3)),
          V((0,H.y(0.93),0.0)),V((0,H.y(0.10),0.30)),V((0,H.y(0.0),TWL-0.05))]
    face(b,prof,'twf_flat',(-1,0,0))
    top=[V((0,y(0)-0.02,zs(0.5)+0.5)),V((hs(0.22)+0.06,y(0.22),zs(0.5)+0.5)),V((hs(1.0)+0.05,yT,zs(0.5)+0.5)),V((-hs(1.0)-0.05,yT,zs(0.5)+0.5)),V((-hs(0.22)-0.06,y(0.22),zs(0.5)+0.5))]
    face(b,top,'twf_flat',(0,0,1))
    ym=y(0.45); z5=zs(0.45)
    face(b,[V((-1.97,ym,z5+0.5)),V((-1.25,ym,zr)),V((1.25,ym,zr)),V((1.97,ym,z5+0.5)),V((1.70,ym,TWL)),V((0.0,ym,0.0)),V((-1.70,ym,TWL))],'twf_flat',(0,-1,0))
    m=y(0.22); zd=zs(0.22)
    face(b,[V((-0.10,m,zr)),V((0.10,m,zr)),V((0.07,m,zd+8.0)),V((-0.07,m,zd+8.0))],'twf_flat',(0,-1,0))
    for sx in (1,-1):
        p=V((sx*(hs(0.25)-0.20),y(0.25),zs(0.25)+0.45)); t_=V((sx*1.15,m+0.9,zd+11.6))
        face(b,[p+V((-0.07,0,0)),p+V((0.07,0,0)),t_+V((0.04,0,0)),t_+V((-0.04,0,0))],'twf_flat',(0,-1,0))
# ===================================================================== skiff: 15 ft open fibreglass skiff with a 25 hp tiller outboard
KWL=0.30
KH=Hull(4.5,hs=smooth_tab([(0,0.05),(0.1,0.42),(0.3,0.70),(0.6,0.80),(1,0.72)]),
        hw=smooth_tab([(0,0.02),(0.15,0.40),(0.4,0.66),(1,0.64)]),
        zs=smooth_tab([(0,KWL+0.74),(0.3,KWL+0.60),(1,KWL+0.50)]),
        zk=smooth_tab([(0,KWL),(0.1,KWL-0.12),(0.4,KWL-0.18),(1,KWL-0.15)]),
        WL=KWL,boot=0.06,flare=0.06,chine=(smooth_tab([(0,0.02),(0.15,0.36),(0.4,0.62),(1,0.60)]),smooth_tab([(0,KWL),(0.15,KWL-0.05),(1,KWL-0.05)])),
        keys=('paint_red','paint_white','paint_green'),y0=-2.35,rake=(0.35,0.25))
KTS_N=[0,0.04,0.09,0.16,0.25,0.36,0.50,0.65,0.80,0.92,1.0]
KTS_M=[0,0.12,0.35,0.65,1.0]
def skiff(b,hi=False,tier='near',tilt=0.0):
    """tilt (rad): outboard tilted up about the transom-clamp pivot (trailered / beached)"""
    T_(hi,tier); mid=tier=='mid'; H=KH
    ts=KTS_M if mid else ([i/24 for i in range(25)] if hi else KTS_N)
    H.build(b,ts,'mid' if mid else 'near')
    zs=H.zs; hs=H.hs; y=H.ys; yT=H.y(1.0)
    TB=0.14; zso=lambda t: KWL-0.04 if t>0.12 else KWL+0.05   # sole height
    li=lambda t: hs(t)-0.035
    fl=lambda t: max(0.05,H.hw(t)*0.80)
    # ---- bow deck, inner liner (sides + sole), gunwale cap, transom inner face + knee
    deck(b,H,sorted(set([t for t in ts if t<=TB]+[TB])),None,'stucco',camber=0.03)
    its=sorted(set([TB]+[t for t in ts if t>TB]))
    for i in range(len(its)-1):
        a,c=its[i],its[i+1]
        for sx in (1,-1):
            face(b,[V((sx*fl(a),y(a),zso(a))),V((sx*fl(c),y(c),zso(c))),V((sx*li(c),y(c),zs(c)-0.02)),V((sx*li(a),y(a),zs(a)-0.02))],'paint_white',(-sx,0,0.3))   # liner side
            if not mid:
                pa,pc=H.sheer(a),H.sheer(c); pa.x*=sx; pc.x*=sx
                face(b,[pa+V((-sx*0.05,0,-0.02)),pc+V((-sx*0.05,0,-0.02)),pc+V((sx*0.01,0,0.0)),pa+V((sx*0.01,0,0.0))],'wood_natural',(0,0,1))   # gunwale cap
                face(b,[pa+V((sx*0.012,0,0.0)),pc+V((sx*0.012,0,0.0)),pc+V((sx*0.012,0,-0.06)),pa+V((sx*0.012,0,-0.06))],'wood_natural',(sx,0,0))
        face(b,[V((-fl(a),y(a),zso(a))),V((fl(a),y(a),zso(a))),V((fl(c),y(c),zso(c))),V((-fl(c),y(c),zso(c)))],'stucco',(0,0,1))   # sole
    face(b,[V((-li(TB),y(TB),zs(TB)-0.02)),V((li(TB),y(TB),zs(TB)-0.02)),V((fl(TB),y(TB),zso(TB))),V((-fl(TB),y(TB),zso(TB)))],'paint_white',(0,1,0))   # bow bulkhead
    face(b,[V((-li(1.0),yT-0.03,zs(1.0)-0.02)),V((li(1.0),yT-0.03,zs(1.0)-0.02)),V((fl(1.0),yT-0.03,zso(1.0))),V((-fl(1.0),yT-0.03,zso(1.0)))],'paint_white',(0,-1,0))   # transom inner
    # ---- thwarts (teak), stern seat with locker, oars in oarlocks, fuel tank + line, anchor + rode, life cushion
    for t,w,dz in ((0.36,0.30,0.30),(0.62,0.30,0.30),(0.90,0.40,0.28)):
        zt=zso(t)+dz; dtw=w/(2*H.L); x=min(hull_x(H,max(0,t-dtw),zt),hull_x(H,t,zt),hull_x(H,min(1,t+dtw),zt))-0.03 if not mid else li(t)-0.05   # narrowest end: no corner through the skin
        b.box((0,y(t),zt),(2*x,w,0.04),'wood_natural',skip=() if not mid else ('bottom',))
        if not mid: b.box((0,y(t),zso(t)),(0.08,0.08,dz),'wood_natural',skip=('bottom','top'))
    if not mid:
        b.box((0,y(0.90)-0.21,zso(0.9)),(2*fl(0.9)-0.05,0.02,0.28),'paint_white',skip=('bottom','top'))                       # stern-seat locker front
        face(b,[V((-0.12,y(0.90)-0.222,zso(0.9)+0.08)),V((0.12,y(0.90)-0.222,zso(0.9)+0.08)),V((0.12,y(0.90)-0.222,zso(0.9)+0.20)),V((-0.12,y(0.90)-0.222,zso(0.9)+0.20))],'plastic_black',(0,-1,0))
        for sx in (1,-1):   # oarlocks on the gunwale + oars shipped along the thwarts
            ol=H.sheer(0.48); ol.x*=sx
            b.tube(ol,ol+V((0,0,0.08)),0.012,0.012,4,'stainless',cap0=False,cap1=False)
            b.sweep([ol+V((0,-0.04,0.08)),ol+V((0,-0.04,0.12)),ol+V((0,0.04,0.12)),ol+V((0,0.04,0.08))],0.008,3,'stainless',cap0=False,cap1=False)
            ox=sx*0.42; oz=zso(0.6)+0.34+0.025
            b.tube(V((ox,y(0.20),oz)),V((ox,y(0.80),oz)),0.022,0.020,6,'wood_natural',cap0=True,cap1=True)                    # loom
            face(b,[V((ox-0.07,y(0.80),oz)),V((ox+0.07,y(0.80),oz)),V((ox+0.07,y(0.98),oz)),V((ox-0.07,y(0.98),oz))],'wood_natural',(0,0,1))   # blade
            face(b,[V((ox-0.07,y(0.80),oz-0.004)),V((ox+0.07,y(0.80),oz-0.004)),V((ox+0.07,y(0.98),oz-0.004)),V((ox-0.07,y(0.98),oz-0.004))],'wood_natural',(0,0,-1))
            b.tube(V((ox,y(0.20)-0.12,oz)),V((ox,y(0.20),oz)),0.016,0.022,6,'plastic_black',cap0=True,cap1=False)              # grip
        fc=V((-0.32,y(0.80),zso(0.8)))
        b.box((fc.x,fc.y,fc.z),(0.30,0.46,0.26),'plastic_orange',skip=('bottom',))                                           # 6 gal fuel tank
        b.tube(fc+V((0,-0.12,0.26)),fc+V((0,-0.12,0.31)),0.03,0.03,6,'plastic_black',cap0=False,cap1=True)
        b.box((fc.x,fc.y+0.08,fc.z+0.26),(0.20,0.06,0.04),'plastic_orange',skip=('bottom',))                                 # handle
        b.sweep([fc+V((0.10,0.20,0.20)),fc+V((0.25,0.40,0.10)),V((0.0,yT-0.05,zso(1.0)+0.12)),V((0.0,yT-0.05,zs(1.0)+0.05))],0.008,3,'plastic_black',cap0=False,cap1=False)   # fuel line + primer
        ac=V((0.05,y(0.22),zso(0.22)))
        b.box((ac.x,ac.y,ac.z),(0.05,0.30,0.03),'cast_iron',skip=('bottom',))                                                 # danforth anchor
        b.box((ac.x,ac.y+0.12,ac.z),(0.32,0.06,0.03),'cast_iron',skip=('bottom',))
        n_=8; rc=V((-0.18,y(0.24),zso(0.24)+0.04))
        b.sweep([rc+V((0.13*math.cos(2*PI*i/n_),0.13*math.sin(2*PI*i/n_),0)) for i in range(n_+1)],0.035,3,'paint_beige',cap0=False,cap1=False)   # coiled rode
        b.box((0.2,y(0.70),zso(0.7)),(0.38,0.38,0.06),'plastic_orange',skip=('bottom',))                                    # throwable cushion
        cleat_small(b,(0,y(0.06),zs(0.06)+0.02),PI/2,'stainless',L=0.14)
        rubrail(b,H,ts,'rubber_black',0.035,0.05)                                                                           # rub strake
        for o in (-0.22,0.0,0.22): b.box((o,(y(0.30)+y(0.86))/2,zso(0.5)),(0.12,y(0.86)-y(0.30),0.025),'wood_natural',skip=('bottom',))   # floorboards
        b.lathe([(0.03,0.0),(0.03,0.05),(0.0,0.07)],6,'glass_dark',c=(0,y(0.03),zs(0.03)+0.02),cap_top=False)              # bow nav light
        for sx in (1,-1): b.tube(V((sx*(li(0.75)-0.03),y(0.75),zs(0.75)-0.20)),V((sx*(li(0.75)-0.01),y(0.75)+0.05,zs(0.75)+0.02)),0.025,0.025,6,'stainless',cap0=True,cap1=False)   # rod holders
        b.box((0.30,y(0.95),zso(0.95)),(0.10,0.10,0.14),'plastic_white',skip=('bottom',))                                   # bilge pump
    # ---- 25 hp tiller outboard on the transom
    x=0.0; yc=yT+0.22; zc0=KWL+0.40; n0=len(b.bm.verts)
    if mid:
        b.box((x,yc,zc0),(0.32,0.44,0.40),'paint_white',skip=('bottom',)); b.box((x,yc,0.0),(0.10,0.22,zc0),'plastic_black',skip=('top','bottom'))
    else:
        b.box((x,yc,zc0),(0.32,0.46,0.26),'paint_white',skip=('bottom',))
        face(b,[V((x-0.15,yc-0.22,zc0+0.26)),V((x+0.15,yc-0.22,zc0+0.26)),V((x+0.12,yc-0.14,zc0+0.38)),V((x-0.12,yc-0.14,zc0+0.38))],'paint_white',(0,-1,0.6))
        face(b,[V((x-0.12,yc-0.14,zc0+0.38)),V((x+0.12,yc-0.14,zc0+0.38)),V((x+0.11,yc+0.16,zc0+0.36)),V((x-0.11,yc+0.16,zc0+0.36))],'paint_white',(0,0,1))
        face(b,[V((x+0.15,yc+0.23,zc0+0.26)),V((x-0.15,yc+0.23,zc0+0.26)),V((x-0.11,yc+0.16,zc0+0.36)),V((x+0.11,yc+0.16,zc0+0.36))],'paint_white',(0,1,0.5))
        for sx in (1,-1):
            face(b,[V((x+sx*0.15,yc-0.22,zc0+0.26)),V((x+sx*0.15,yc+0.23,zc0+0.26)),V((x+sx*0.11,yc+0.16,zc0+0.36)),V((x+sx*0.12,yc-0.14,zc0+0.38))],'paint_white',(sx,0,0.3))
            face(b,[V((x+sx*0.1605,yc-0.15,zc0+0.10)),V((x+sx*0.1605,yc+0.18,zc0+0.10)),V((x+sx*0.1605,yc+0.18,zc0+0.15)),V((x+sx*0.1605,yc-0.15,zc0+0.15))],'paint_navy',(sx,0,0))
        b.box((x,yc+0.02,KWL-0.06),(0.11,0.24,zc0-KWL+0.06),'plastic_black',skip=('top','bottom'))
        b.box((x,yc+0.03,KWL-0.08),(0.22,0.34,0.015),'plastic_black',skip=())
        b.box((x,yc-0.23,zs(1.0)-0.18),(0.16,0.06,0.24),'stainless',skip=())                                                  # transom clamps
        for sx in (1,-1): b.tube(V((x+sx*0.06,yc-0.27,zs(1.0)-0.02)),V((x+sx*0.06,yc-0.34,zs(1.0)-0.02)),0.012,0.012,4,'plastic_black',cap0=False,cap1=True)
        b.tube(V((x,yc-0.18,zc0+0.15)),V((x+0.02,yc-0.80,zc0+0.22)),0.022,0.018,6,'plastic_black',cap0=False,cap1=True)        # tiller arm
        b.tube(V((x,yc-0.10,0.12)),V((x,yc+0.18,0.12)),0.045,0.04,6,'plastic_black',cap0=True,cap1=False)
        face(b,[V((x,yc-0.05,0.09)),V((x,yc+0.12,0.09)),V((x,yc+0.11,0.0)),V((x,yc+0.02,0.0))],'plastic_black',(1,0,0))
        face(b,[V((x,yc-0.05,0.09)),V((x,yc+0.12,0.09)),V((x,yc+0.11,0.0)),V((x,yc+0.02,0.0))],'plastic_black',(-1,0,0))
        hub=V((x,yc+0.20,0.12))
        for k in range(3):
            a=k*2*PI/3+0.4; d=V((math.cos(a),0,math.sin(a)))
            face(b,[hub+d*0.03,hub+d*0.03+V((0,0.05,0)),hub+d*0.11+V((0,0.05,0)),hub+d*0.11],'stainless',(d.z,0.3,-d.x))
    if tilt:
        from mathutils import Matrix
        pv=V((0,yT+0.0,zs(1.0)-0.04)); M=Matrix.Translation(pv)@Matrix.Rotation(tilt,4,'X')@Matrix.Translation(-pv)
        b.bm.verts.ensure_lookup_table()
        for v in b.bm.verts[n0:]: v.co=M@v.co
    if tier=='near':
        cbox(b,(0,(H.y(0.0)+H.y(0.3))/2,KWL-0.15),(2*hs(0.3),H.y(0.3)-H.y(0.0),zs(0.0)-KWL+0.15))
        cbox(b,(0,(H.y(0.3)+yT)/2,KWL-0.18),(2*hs(0.6),yT-H.y(0.3),zs(0.3)-KWL+0.18))
        cbox(b,(0,yc,0.0),(0.34,0.48,zc0+0.40))
def skiff_far(b):
    H=KH; y=H.ys; zs=H.zs; hs=H.hs; yT=H.y(1.0); yc=yT+0.22
    face(b,[V((0,y(0)-0.02,zs(0))),V((0,yT,zs(1.0))),V((0,yc+0.22,KWL+0.78)),V((0,yc+0.22,0.0)),V((0,H.y(0.4),KWL-0.18)),V((0,H.y(0.0),KWL))],'twf_flat',(-1,0,0))
    face(b,[V((0,y(0)-0.02,zs(0.5))),V((hs(0.25)+0.03,y(0.25),zs(0.5))),V((hs(1.0)+0.02,yT,zs(0.5))),V((-hs(1.0)-0.02,yT,zs(0.5))),V((-hs(0.25)-0.03,y(0.25),zs(0.5)))],'twf_flat',(0,0,1))
    ym=y(0.6)
    face(b,[V((-0.80,ym,zs(0.6))),V((-0.30,ym,zs(0.2))),V((0.0,ym,zs(0.0)+0.02)),V((0.30,ym,zs(0.2))),V((0.80,ym,zs(0.6))),V((0.64,ym,KWL)),V((0.0,ym,KWL-0.18)),V((-0.64,ym,KWL))],'twf_flat',(0,-1,0))   # section + rising bow sheer behind it
    face(b,[V((-0.16,yc,0.0)),V((0.16,yc,0.0)),V((0.16,yc,KWL+0.78)),V((-0.16,yc,KWL+0.78))],'twf_flat',(0,-1,0))
# ===================================================================== registry
TRB=dict(WP.TR)
TRB.update({'paint_white':('tw_gelcoat',(0.875,0.875)),'paint_navy':('tw_gelcoat',(0.875,0.875)),'glass_dark':('tw_gelcoat',(0.875,0.875)),
            'plastic_black':('tw_gelcoat',(0.875,0.875)),'paint_red':('tw_foul',(0.875,0.875)),'paint_black':('tw_foul',(0.875,0.875)),
            'stucco':('tw_nonskid',(0.875,0.875)),'wood_white':('tw_sail',(0.875,0.875)),'fabric':('tw_canvas',(0.875,0.875),3.0),
            'vinyl_seat':('tw_vinyl',(0.875,0.875)),'wood_natural':('tw_teak',(0.875,0.875),3.0),'aluminium':('tw_galv',(0.875,0.875),6.0),
            'stainless':('tw_galv',(0.875,0.875),6.0),'rubber_black':('tw_rubber',(0.875,0.875),3.0),'paint_beige':('tw_canvas',(0.875,0.875),6.0),
            'wood_pole':('tw_timber',(0.875,0.875),6.0),'paint_green':('tw_gelcoat',(0.875,0.875))})
TINT={'paint_white':(1.0,1.0,0.99),'paint_navy':(0.12,0.17,0.32),'glass_dark':(0.26,0.33,0.38),'plastic_black':(0.10,0.10,0.10),
      'paint_red':(0.70,0.20,0.15),'paint_black':(0.20,0.20,0.22),'stucco':(1.0,0.98,0.92),'wood_white':(1.0,1.0,1.0),'fabric':(0.20,0.27,0.45),
      'vinyl_seat':(1.0,0.97,0.88),'aluminium':(1.12,1.12,1.14),'stainless':(1.2,1.2,1.2),'paint_beige':(1.05,1.0,0.88),'paint_green':(0.16,0.34,0.24)}
WXB={'water':None,'algae':0.0,'barnacle':0.0,'salt':0.15,'edge':0.25,'streak':0.15}
_C=dict(WP._C); _C.update(dir='props/waterfront/boats',pdir='waterfront_boats',trim=TRB,trim_tint=TINT,wx={'salt':0.15,'edge':0.25,'streak':0.15,'pit':0.3},max_side=64)
def _wrap(fn,name):
    def near(b): P.reset(); P.TIER['t']='near'; fn(b); P.save_rails(name,pg.K+'/props/waterfront/_rails')
    return near
PROPS=[
 dict(name='boat_sloop',near=_wrap(sloop,'boat_sloop'),high=lambda b: sloop(b,hi=True),mid=lambda b: sloop(b,tier='mid'),far=sloop_far,**dict(_C,cls='large')),
 dict(name='boat_troller',near=_wrap(troller,'boat_troller'),high=lambda b: troller(b,hi=True),mid=lambda b: troller(b,tier='mid'),far=troller_far,
      **dict(_C,cls='large',trim=dict(TRB,wood_weathered=('tw_plank',(0.875,0.875)),wood_white=('tw_plank',(0.875,0.875))),trim_tint=dict(TINT,wood_weathered=(1.0,1.0,0.98),wood_white=(1.02,1.0,0.93)))),
 dict(name='boat_skiff',near=_wrap(skiff,'boat_skiff'),high=lambda b: skiff(b,hi=True),mid=lambda b: skiff(b,tier='mid'),far=skiff_far,**dict(_C,cls='medium')),
 dict(name='boat_express',near=_wrap(express,'boat_express'),high=lambda b: express(b,hi=True),mid=lambda b: express(b,tier='mid'),far=express_far,**dict(_C,cls='large',no_bake=True)),
]
