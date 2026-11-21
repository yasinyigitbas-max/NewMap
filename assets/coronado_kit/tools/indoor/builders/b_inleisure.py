"""Indoor leisure props (bar games) — original geometry, page I, near+col only. No mid/far.

pool_table: 7 ft coin-op bar table (play field 1.98 x 0.99 m), walnut cabinet, green felt,
cushion rails with jaw cuts, six pocket liners, diamond sights, coin slide + ball-return window,
racked 15 balls under a wooden rack, cue ball, a cue lying across the cloth, chalk on the rail.
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math
from mathutils import Vector
from b_inshared import sg, maker_plate, TR as _TR, TINT as _TINT

TR=dict(_TR); TINT=dict(_TINT)
for k,t in {'felt':'ti_fabric','felt_rail':'ti_fabric','walnut_dk':'ti_wood','leather':'ti_fabric','chalk':'ti_paint',
            'pearl':'ti_paint','b_white':'ti_paint','b_yellow':'ti_paint','b_blue':'ti_paint','b_red':'ti_paint',
            'b_purple':'ti_paint','b_orange':'ti_paint','b_green':'ti_paint','b_maroon':'ti_paint','b_black':'ti_paint',
            'maple':'ti_wood','hole':'ti_paint'}.items():
    TR[k]=(t,(0.875,0.875))
TINT.update({
    'felt':(0.10,0.42,0.27), 'felt_rail':(0.085,0.36,0.23), 'walnut_dk':(0.40,0.27,0.18), 'leather':(0.17,0.10,0.07),
    'chalk':(0.25,0.50,0.85), 'pearl':(1.15,1.12,1.02), 'maple':(1.10,1.00,0.80), 'hole':(0.025,0.022,0.020),
    'b_white':(1.14,1.12,1.04), 'b_yellow':(1.00,0.78,0.08), 'b_blue':(0.10,0.20,0.70), 'b_red':(0.80,0.08,0.06),
    'b_purple':(0.34,0.12,0.50), 'b_orange':(1.00,0.42,0.05), 'b_green':(0.06,0.44,0.20), 'b_maroon':(0.45,0.07,0.09),
    'b_black':(0.05,0.05,0.05),
})

def _q(b, pts, key, want):
    """quad/poly with its normal forced toward `want`"""
    P=[Vector(p) for p in pts]; n=Vector((0,0,0))
    for i in range(len(P)): n+=P[i].cross(P[(i+1)%len(P)])
    if n.dot(Vector(want))<0: P=P[::-1]
    return b.quad(P,key)

BALLS=['b_yellow','b_blue','b_red','b_purple','b_orange','b_green','b_maroon','b_black']
def ball(b, c, num, hi=False, r=0.0286, yaw=0.0):
    """num 0 = cue ball, 1-8 solids, 9-15 stripes (white cap, coloured band). Three rings (62, 20, -28 deg) give a
    round silhouette; open below -28 deg (the ball sits on the cloth, the underside is never seen)."""
    x,y,z=c; z=z+r; n=sg(hi,8,16)
    col='b_white' if num==0 else BALLS[(num-1)%8]
    top='b_white' if (num==0 or num>8) else col
    E=[math.radians(a) for a in ((62,20,-28) if not hi else (70,45,20,-5,-30,-60,-85))]
    def ring(e): return [Vector((x+r*math.cos(e)*math.cos(yaw+2*math.pi*i/n),y+r*math.cos(e)*math.sin(yaw+2*math.pi*i/n),z+r*math.sin(e))) for i in range(n)]
    R=[ring(e) for e in E]; T=Vector((x,y,z+r))
    vs=[T]+R[0]; polys=[]; luv=[]
    for i in range(n):
        j=(i+1)%n; polys.append((0,1+i,1+j)); a0=2*math.pi*r*i/n; a1=2*math.pi*r*(i+1)/n
        luv.append([(0.5*(a0+a1),r),(a0,0.8*r),(a1,0.8*r)])
    b.faces(vs,polys,top,luv,smooth=True)
    for k in range(len(R)-1):
        vs=R[k]+R[k+1]; polys=[]; luv=[]
        for i in range(n):
            j=(i+1)%n; polys.append((i,n+i,n+j,j)); a0=2*math.pi*r*i/n; a1=2*math.pi*r*(i+1)/n
            luv.append([(a0,r*math.sin(E[k])),(a0,r*math.sin(E[k+1])),(a1,r*math.sin(E[k+1])),(a1,r*math.sin(E[k]))])
        b.faces(vs,polys,col,luv,smooth=True)

def pocket(b, c, r_in, r_out, z_top, z_felt, hi=False):
    """moulded leather pocket liner on the rail: rolled lip, skirt down to the cloth, recessed near-black throat"""
    x,y=c; n=sg(hi,10,20)
    def ring(r,z): return [Vector((x+r*math.cos(2*math.pi*(i+0.5)/n),y+r*math.sin(2*math.pi*(i+0.5)/n),z)) for i in range(n)]
    O=ring(r_out,z_top-0.004); I=ring(r_in,z_top); Ob=ring(r_out,z_felt+0.001); Id=ring(r_in*0.96,z_felt+0.004)
    for i in range(n):
        j=(i+1)%n
        _q(b,[O[i],O[j],I[j],I[i]],'leather',(0,0,1))                    # rolled lip
        _q(b,[Ob[i],Ob[j],O[j],O[i]],'leather',(O[i].x-x,O[i].y-y,0))    # skirt down to the cloth
        _q(b,[I[i],I[j],Id[j],Id[i]],'hole',(x-I[i].x,y-I[i].y,0))       # throat wall
    _q(b,Id,'hole',(0,0,1))                                              # throat floor (in shadow)

def cushion(b, p0, p1, inward, j0, j1, z_felt, z_top):
    """rubber cushion covered in cloth. p0->p1 = nose line on the play-field edge, inward = unit vector to the
    table centre, j0/j1 = jaw cut (how much shorter the nose is than the back at each end)."""
    p0=Vector(p0); p1=Vector(p1); a=(p1-p0).normalized(); n=Vector(inward)
    back=0.050
    def P(t,off,z): return p0+a*t+(-n)*off+Vector((0,0,z))
    L=(p1-p0).length
    T0,T1=P(-j0,back,z_top-0.002),P(L+j1,back,z_top-0.002)
    N0,N1=P(0,0,z_top-0.014),P(L,0,z_top-0.014)
    F0,F1=P(0.006,0.012,z_felt),P(L-0.006,0.012,z_felt)
    K0,K1=P(-j0,back,z_felt),P(L+j1,back,z_felt)
    up=n*0.35+Vector((0,0,1))
    _q(b,[T0,T1,N1,N0],'felt_rail',up)
    _q(b,[N0,N1,F1,F0],'felt_rail',n)
    _q(b,[T0,N0,F0,K0],'felt_rail',-a)
    _q(b,[T1,N1,F1,K1],'felt_rail',a)

def pool_table(b, hi=False):
    L,W=2.24,1.27           # outside of the rail caps
    Lp,Wp=1.98,0.99         # play field (cushion nose to nose)
    zf,zt=0.765,0.800       # cloth, rail top
    cw=0.050                # cushion depth (nose to cap)
    xi,yi=Lp/2,Wp/2
    # --- cloth (slate bed)
    b.box((0,0,zf-0.03),(Lp+2*cw+0.004,Wp+2*cw+0.004,0.03),'felt',skip=('bottom',))
    # --- rail caps (walnut): an outer band all round + inner bands cut back at the pockets, so no wood shows
    # inside a pocket throat (the liner lip covers the cut ends)
    capw=(W-Wp)/2-cw; ob_l,ob_e=0.052,0.044; hz=0.045
    for s in (-1,1):
        b.box((0,s*(W/2-ob_l/2),zt-hz),(L,ob_l,hz),'walnut',ch=0)                                   # long outer band
        b.box((s*(L/2-ob_e/2),0,zt-hz),(ob_e,W-2*ob_l,hz),'walnut',ch=0)                             # end outer band
        iw=W/2-ob_l-(yi+cw); yc=s*(yi+cw+iw/2)
        for x0,x1 in ((-(xi-0.025),-0.052),(0.052,xi-0.025)):
            b.box(((x0+x1)/2,yc,zt-hz),(x1-x0,iw,hz),'walnut',ch=0)                                 # long inner band
        ie=L/2-ob_e-(xi+cw)
        b.box((0,s*(W/2-0.020),zt-hz-0.012),(L+0.012,0.052,0.040),'walnut')                  # stepped edge moulding (long)
        b.box((s*(L/2-0.020),0,zt-hz-0.012),(0.052,W+0.012,0.040),'walnut')                  # stepped edge moulding (end)
        b.box((s*(xi+cw+ie/2),0,zt-hz),(ie,2*(yi-0.025),hz),'walnut',ch=0)                          # end inner band
    # --- diamond sights (mother of pearl inlays)
    ds=0.011
    def diamond(x,y): b.quad([(x-ds,y,zt+0.0006),(x,y-ds*0.7,zt+0.0006),(x+ds,y,zt+0.0006),(x,y+ds*0.7,zt+0.0006)],'pearl')
    for s in (-1,1):
        yc=s*(W/2-0.026)
        for k in (1,2,3):
            for sx in (-1,1): diamond(sx*xi*k/4,yc)
        xc=s*(L/2-0.022)
        for k in (-1,0,1): diamond(xc,k*yi/2)
    # --- cushions with jaw cuts at the pockets
    cj,sj=0.060,0.062       # corner / side pocket mouth half-openings along the rail
    for s in (-1,1):
        y=s*yi
        cushion(b,(-xi+cj,y,0),(-sj,y,0),(0,-s,0),0.035,0.008,zf,zt)
        cushion(b,(sj,y,0),(xi-cj,y,0),(0,-s,0),0.008,0.035,zf,zt)
        x=s*xi
        cushion(b,(x,-yi+cj,0),(x,yi-cj,0),(-s,0,0),0.035,0.035,zf,zt)
    # --- six pockets
    for sx in (-1,1):
        for sy in (-1,1):
            pocket(b,(sx*(xi+0.030),sy*(yi+0.030)),0.056,0.084,zt+0.004,zf,hi)
        pass
    for sy in (-1,1):
        pocket(b,(0,sy*(yi+0.038)),0.050,0.076,zt+0.004,zf,hi)
    # --- apron (walnut), corner castings (brushed chrome), bead moulding under the cap
    ah=0.20; az=zt-0.045-ah
    b.box((0,0,az),(L-0.03,W-0.03,ah),'walnut',skip=('top',))
    b.box((0,0,az-0.018),(L-0.05,W-0.05,0.018),'walnut_dk',skip=('top',))          # lower bead
    for sx in (-1,1):
        for sy in (-1,1):
            cx_,cy_=sx*(L/2-0.015),sy*(W/2-0.015)
            b.box((cx_-sx*0.034,cy_+sy*0.003,az-0.012),(0.074,0.008,ah+0.006),'chrome',skip=('bottom',))   # casting, long face
            b.box((cx_+sx*0.003,cy_-sy*0.034,az-0.012),(0.008,0.074,ah+0.006),'chrome',skip=('bottom',))   # casting, end face
    for sy in (-1,1):
        b.box((0,sy*((W-0.03)/2+0.003),az+0.045),(L-0.46,0.006,0.11),'walnut_dk')
    b.box((-((L-0.03)/2+0.003),0,az+0.045),(0.006,W-0.40,0.11),'walnut_dk')
    # --- lower cabinet (bar-box body), black kick band
    cbx,cby=L-0.42,W-0.36; cz=0.17
    b.box((0,0,cz),(cbx,cby,az-0.018-cz),'walnut_dk',skip=('top',))
    b.box((0,0,cz-0.03),(cbx+0.02,cby+0.02,0.03),'paint_black',skip=('top',))
    # --- legs: tapered square posts under the corner castings, black plinth feet
    for sx in (-1,1):
        for sy in (-1,1):
            x,y=sx*(L/2-0.13),sy*(W/2-0.13)
            b.tube((x,y,0.05),(x,y,az-0.018),0.050,0.068,4,'walnut',cap0=False,cap1=False,sq=True)
            b.box((x,y,0.0),(0.13,0.13,0.05),'paint_black',skip=('bottom',))
    # --- coin slide on the foot end apron (+X): chrome plate, slide bar, coin slots, return knob
    ex=L/2-0.015
    b.box((ex+0.004,0,az+0.035),(0.008,0.30,0.12),'chrome')
    b.box((ex+0.016,0,az+0.070),(0.022,0.22,0.040),'steel')
    for yy in (-0.06,-0.02,0.02,0.06):
        b.box((ex+0.0275,yy,az+0.083),(0.002,0.022,0.006),'hole')
    b.tube((ex+0.027,0.0,az+0.090),(ex+0.045,0.0,az+0.090),0.010,0.010,sg(hi,6,12),'steel',cap0=False,cap1=True)
    b.box((ex+0.009,0,az+0.135),(0.004,0.10,0.014),'badge')                         # coin price card (bake)
    # --- ball-return window on the foot end of the cabinet, three balls in the tray
    wx=cbx/2; wz=0.36
    b.box((wx+0.002,0,wz-0.012),(0.006,0.46,0.012),'chrome'); b.box((wx+0.002,0,wz+0.10),(0.006,0.46,0.012),'chrome')
    b.box((wx+0.002,-0.224,wz),(0.006,0.012,0.10),'chrome'); b.box((wx+0.002,0.224,wz),(0.006,0.012,0.10),'chrome')
    b.quad([(wx+0.0055,-0.218,wz),(wx+0.0055,0.218,wz),(wx+0.0055,0.218,wz+0.10),(wx+0.0055,-0.218,wz+0.10)],'hole')
    b.box((wx+0.022,0,wz-0.012),(0.040,0.44,0.010),'chrome')                         # tray lip
    for k,yy in enumerate((-0.12,-0.06,0.02)):
        ball(b,(wx+0.026,yy,wz-0.002),(3,11,6)[k],hi,yaw=k)
    # --- balls: 8-ball rack at the foot spot, cue ball at the head spot
    d=2*0.0286+0.0004; xf=xi/2
    order=[1, 9,2, 10,8,3, 11,7,14,4, 5,13,15,6,12]; i=0
    for row in range(5):
        for j in range(row+1):
            ball(b,(xf+row*d*math.cos(math.radians(30)),(j-row/2)*d,zf),order[i],hi,yaw=0.37*i); i+=1
    ball(b,(-xi/2,0.04,zf),0,hi)
    # wooden triangle rack around the balls
    ax=xf-0.045; bx_=xf+4*d*0.866+0.040; hw=(bx_-ax)*math.tan(math.radians(30))
    pA=Vector((ax,0,0)); pB=Vector((bx_,hw,0)); pC=Vector((bx_,-hw,0))
    for a_,c_ in ((pA,pB),(pB,pC),(pC,pA)):
        m=(a_+c_)/2; dv=c_-a_; ang=math.atan2(dv.y,dv.x)
        b.box((m.x,m.y,zf),(dv.length+0.02,0.016,0.032),'maple',rz=ang)
    # --- a cue lying across the cloth (butt, wrap, maple shaft, ferrule, tip) and chalk on the head rail
    c0=Vector((-0.80,-0.34,0)); c1=Vector((0.40,0.10,0)); ln=(c1-c0)
    def seg(t0,t1,r0,r1,key,cap0=False,cap1=False):
        p0=c0+ln*t0; p1=c0+ln*t1
        b.tube((p0.x,p0.y,zf+0.0145),(p1.x,p1.y,zf+0.0145-(0.008*(t1))),r0,r1,sg(hi,6,12),key,cap0=cap0,cap1=cap1)
    seg(0.00,0.10,0.0150,0.0145,'paint_black',cap0=True)
    seg(0.10,0.30,0.0145,0.0135,'walnut')
    seg(0.30,0.44,0.0135,0.0126,'leather')
    seg(0.44,0.47,0.0126,0.0124,'brass')
    seg(0.47,0.985,0.0124,0.0068,'maple')
    seg(0.985,0.996,0.0068,0.0066,'paint_white')
    seg(0.996,1.0,0.0066,0.0062,'chalk',cap1=True)
    b.box((-(L/2-0.022),yi*0.55,zt),(0.022,0.022,0.020),'chalk',rz=0.4)
    # --- maker plate on the front apron
    maker_plate(b,(0.0,-(W/2-0.015)-0.003,az+0.07),hi,w=0.09,h=0.026)
    b.cbox((0,0,0),(L,W,zt))

_C=dict(dir='props/indoor/leisure',pdir='indoor_leisure',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('pool_table',pool_table,'large',2400),
]

INDOOR_LOOK=True   # run.py: chamfer edge highlight + per-part colour variation in COLOR_0
