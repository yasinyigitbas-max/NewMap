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


# ---- batch 1 (leisure / bar) materials: page-I trims + per-key vertex tint (one material, no new textures)
for k,t in {'sisal':'ti_fabric','d_black':'ti_paint','d_cream':'ti_paint','d_red':'ti_paint','d_green':'ti_paint',
            'chalkbd':'ti_paint','chalk_w':'ti_paint','flight_a':'ti_plastic','flight_b':'ti_plastic',
            'neon_r':'ti_plastic','neon_y':'ti_plastic','neon_b':'ti_plastic','glow_r':'ti_paint','glow_y':'ti_paint','glow_b':'ti_paint','glow_rh':'ti_paint','glow_yh':'ti_paint','glow_bh':'ti_paint',
            'acrylic_blk':'ti_plastic','jb_orange':'ti_plastic','jb_red':'ti_plastic','jb_yellow':'ti_plastic','jb_green':'ti_plastic',
            'grille':'ti_fabric','vinyl_rec':'ti_plastic','oak_barrel':'ti_wood','iron':'ti_metal','bottle_g':'ti_glass',
            'bottle_d':'ti_glass','bottle_r':'ti_glass','foil_r':'ti_paint','foil_g':'ti_paint','cork_k':'ti_fabric',
            'sl_0':'ti_paint','sl_1':'ti_paint','sl_2':'ti_paint','sl_3':'ti_paint','sl_4':'ti_paint','sl_5':'ti_paint',
            'sl_6':'ti_paint','sl_7':'ti_paint','crate_or':'ti_plastic','crate_bl':'ti_plastic','pine':'ti_wood',
            'pop_red':'ti_paint','hdpe_edge':'ti_plastic','hdpe_under':'ti_plastic','hdpe_band':'ti_plastic','hdpe_scuff':'ti_paint','hdpe_scuff2':'ti_paint','popcorn':'ti_fabric','popcorn2':'ti_fabric','kettle':'ti_metal','hdpe':'ti_plastic','seat_pad':'ti_fabric',
            'chair_frame':'ti_metal','jb_win':'ti_glass','keg_cap_g':'ti_plastic','keg_cap_r':'ti_plastic','hose':'ti_plastic','gold':'ti_brass'}.items():
    TR[k]=(t,(0.875,0.875))
TINT.update({
    'sisal':(0.92,0.80,0.58), 'd_black':(0.07,0.07,0.07), 'd_cream':(1.05,0.95,0.74), 'd_red':(0.78,0.07,0.06),
    'd_green':(0.05,0.40,0.18), 'chalkbd':(0.11,0.13,0.12), 'chalk_w':(1.05,1.05,1.00), 'flight_a':(0.95,0.20,0.10),
    'flight_b':(0.10,0.35,0.95), 'neon_r':(1.75,0.34,0.30), 'neon_y':(1.75,1.38,0.36), 'neon_b':(0.36,0.98,1.85),
    'glow_r':(0.36,0.035,0.04), 'glow_y':(0.34,0.24,0.035), 'glow_b':(0.035,0.12,0.34), 'glow_rh':(0.95,0.10,0.09), 'glow_yh':(0.92,0.66,0.10), 'glow_bh':(0.10,0.42,0.98), 'acrylic_blk':(0.05,0.05,0.06),
    'jb_orange':(1.25,0.55,0.12), 'jb_red':(1.10,0.12,0.10), 'jb_yellow':(1.30,1.05,0.30), 'jb_green':(0.20,0.85,0.45),
    'grille':(0.20,0.12,0.09), 'vinyl_rec':(0.04,0.04,0.045), 'oak_barrel':(0.78,0.55,0.36), 'iron':(0.28,0.27,0.26),
    'bottle_g':(0.10,0.24,0.12), 'bottle_d':(0.16,0.06,0.07), 'bottle_r':(1.00,0.55,0.50), 'foil_r':(0.55,0.06,0.10),
    'foil_g':(0.85,0.68,0.25), 'cork_k':(0.85,0.66,0.44), 'pine':(1.12,1.00,0.78),
    'sl_0':(0.85,0.20,0.12), 'sl_1':(0.12,0.30,0.65), 'sl_2':(0.95,0.78,0.20), 'sl_3':(0.15,0.15,0.16), 'sl_4':(0.92,0.90,0.84),
    'sl_5':(0.20,0.55,0.35), 'sl_6':(0.70,0.35,0.60), 'sl_7':(0.95,0.50,0.20),
    'crate_or':(0.95,0.42,0.08), 'crate_bl':(0.10,0.28,0.70), 'pop_red':(0.50,0.02,0.025), 'popcorn':(1.38,1.30,1.02), 'popcorn2':(1.30,1.08,0.52),
    'kettle':(1.10,1.10,1.12), 'hdpe':(0.98,0.98,0.95), 'hdpe_edge':(0.84,0.84,0.82), 'hdpe_under':(0.40,0.40,0.40), 'hdpe_band':(0.70,0.70,0.69), 'hdpe_scuff':(0.80,0.79,0.76), 'hdpe_scuff2':(0.88,0.86,0.82), 'seat_pad':(0.20,0.24,0.34), 'chair_frame':(0.30,0.31,0.33), 'jb_win':(1.05,0.70,0.32),
    'keg_cap_g':(0.10,0.50,0.25), 'keg_cap_r':(0.75,0.10,0.08), 'hose':(0.95,0.95,0.92), 'gold':(1.10,0.95,0.60),
})

def _arcpts(c, r, a0, a1, n, y):
    return [Vector((c[0]+r*math.cos(math.radians(a0+(a1-a0)*i/n)), y, c[1]+r*math.sin(math.radians(a0+(a1-a0)*i/n)))) for i in range(n+1)]

# ------------------------------------------------------------------ dartboard (wall cabinet, doors open)
DART_NUM=[20,1,18,4,13,6,10,15,2,17,3,19,7,16,8,11,14,9,12,5]
def dartboard(b, hi=False):
    """bristle board in a walnut cabinet with both doors swung open (chalk scoreboards inside the doors), three darts
    in the board. Bullseye at the regulation 1.73 m; back of the cabinet on the wall (+Y), viewer at -Y."""
    zc=1.73; W,H,D=0.60,0.64,0.10; yb=0.0; yf=yb-D           # cabinet front plane yf (-0.10)
    z0=zc-H/2
    # cabinet: back board, frame (top, bottom, sides), inner dark felt surround
    b.box((0,yb-0.012,z0),(W,0.012,H),'walnut')
    for s in (-1,1): b.box((s*(W/2-0.011),yb-D/2,z0),(0.022,D,H),'walnut')
    b.box((0,yb-D/2,z0),(W-0.044,D,0.022),'walnut'); b.box((0,yb-D/2,z0+H-0.022),(W-0.044,D,0.022),'walnut')
    b.box((0,yb-(D+0.016)/2,z0+H),(W+0.03,D+0.016,0.026),'walnut_dk',ch=0,skip=('back',))      # crown moulding
    b.box((0,yb-(D+0.010)/2,z0-0.018),(W+0.02,D+0.010,0.018),'walnut_dk',ch=0,skip=('back',))  # plinth
    _q(b,[(-W/2+0.022,yb-0.0125,z0+0.022),(W/2-0.022,yb-0.0125,z0+0.022),(W/2-0.022,yb-0.0125,z0+H-0.022),(-W/2+0.022,yb-0.0125,z0+H-0.022)],'d_black',(0,-1,0))
    # doors open flat against the wall either side, chalkboard inside each, walnut frame + brass hinges
    dw=W/2; dt=0.018
    for s in (-1,1):
        xc=s*(W/2+dw/2+0.004)
        b.box((xc,yf+0.06,z0),(dw,dt,H),'walnut')
        yd=yf+0.06-dt/2                                                    # door front face
        b.box((xc,yd-0.0015,z0+0.035),(dw-0.05,0.003,H-0.07),'chalkbd',ch=0,skip=('back',))
        yr=yd-0.0032; xa_,xb_=xc-dw/2+0.022,xc+dw/2-0.022; za_,zb_=z0+0.028,z0+H-0.028
        for (P0,P1,P2,P3) in (((xa_,za_),(xb_,za_),(xb_,za_+0.008),(xa_,za_+0.008)),((xa_,zb_-0.008),(xb_,zb_-0.008),(xb_,zb_),(xa_,zb_)),
                              ((xa_,za_),(xa_+0.008,za_),(xa_+0.008,zb_),(xa_,zb_)),((xb_-0.008,za_),(xb_,za_),(xb_,zb_),(xb_-0.008,zb_))):
            _q(b,[(P0[0],yr,P0[1]),(P1[0],yr,P1[1]),(P2[0],yr,P2[1]),(P3[0],yr,P3[1])],'walnut_dk',(0,-1,0))   # moulded frame round the slate
        for zz in (z0+0.08,z0+H-0.14): _q(b,[(s*W/2-0.006,yf-0.0005,zz),(s*W/2+0.006,yf-0.0005,zz),(s*W/2+0.006,yf-0.0005,zz+0.06),(s*W/2-0.006,yf-0.0005,zz+0.06)],'brass',(0,-1,0))
        # chalk: ruled columns + tally strokes (geometry, no texture)
        yy=yd-0.0035
        xl,xr=xc-dw/2+0.04,xc+dw/2-0.04
        _q(b,[(xl,yy,z0+H-0.10),(xr,yy,z0+H-0.10),(xr,yy,z0+H-0.094),(xl,yy,z0+H-0.094)],'chalk_w',(0,-1,0))
        _q(b,[(xc-0.002,yy,z0+0.06),(xc+0.002,yy,z0+0.06),(xc+0.002,yy,z0+H-0.06),(xc-0.002,yy,z0+H-0.06)],'chalk_w',(0,-1,0))
        rnd=[(0.03,0.04),(0.07,0.025),(0.05,0.035),(0.04,0.03)]
        for k,(w1,w2) in enumerate(rnd):
            zz=z0+H-0.15-k*0.085
            _q(b,[(xl+0.01,yy,zz),(xl+0.01+w1,yy,zz),(xl+0.01+w1,yy,zz+0.008),(xl+0.01,yy,zz+0.008)],'chalk_w',(0,-1,0))
            _q(b,[(xc+0.02,yy,zz-0.006),(xc+0.02+w2,yy,zz-0.006),(xc+0.02+w2,yy,zz+0.002),(xc+0.02,yy,zz+0.002)],'chalk_w',(0,-1,0))
    # the board: sisal rim + segment face on the plane y=yb-0.052
    R=0.2255; yfb=yb-0.052; n=20
    b.tube((0,yb-0.0125,zc),(0,yfb,zc),R,R,sg(hi,20,40),'d_black',cap0=False,cap1=False,smooth=True,phase=math.radians(9))
    rings=[(0.0159,0.099,'s'),(0.099,0.107,'t'),(0.107,0.162,'s'),(0.162,0.170,'t')]
    for i in range(n):
        a0=math.radians(90-18*i-9); a1=math.radians(90-18*i+9)
        dark=(i%2==0)
        for r0,r1,kind in rings:
            key=('d_black' if dark else 'd_cream') if kind=='s' else ('d_red' if dark else 'd_green')
            P=[(r0*math.cos(a0),yfb,zc+r0*math.sin(a0)),(r1*math.cos(a0),yfb,zc+r1*math.sin(a0)),
               (r1*math.cos(a1),yfb,zc+r1*math.sin(a1)),(r0*math.cos(a1),yfb,zc+r0*math.sin(a1))]
            _q(b,P,key,(0,-1,0))
    # number ring (unique bake: numbers baked from the high-poly), wire ring
    nr=sg(hi,20,40); A=[math.radians(9+360*i/nr) for i in range(nr+1)]
    for i in range(nr):
        P=[(0.170*math.cos(A[i]),yfb,zc+0.170*math.sin(A[i])),(R*math.cos(A[i]),yfb,zc+R*math.sin(A[i])),
           (R*math.cos(A[i+1]),yfb,zc+R*math.sin(A[i+1])),(0.170*math.cos(A[i+1]),yfb,zc+0.170*math.sin(A[i+1]))]
        _q(b,P,'paint_black' if hi else 'numring',(0,-1,0))
    if hi:
        import pg as _pg
        for i,num in enumerate(DART_NUM):
            a=math.radians(90-18*i); rr=0.197
            _pg.add_text(b,str(num),0.030,(rr*math.cos(a),yfb-0.0015,zc+rr*math.sin(a)),(math.sin(a),0,-math.cos(a)),(math.cos(a),0,math.sin(a)),0.002,'paint_white')
    # bulls (outer green, inner red), slightly raised
    b.tube((0,yfb,zc),(0,yfb-0.002,zc),0.0159,0.0159,sg(hi,10,20),'d_green',cap0=False,cap1=True)
    b.tube((0,yfb-0.002,zc),(0,yfb-0.003,zc),0.0064,0.0064,sg(hi,6,16),'d_red',cap0=False,cap1=True)
    # three darts (tungsten barrel, nylon shaft, flights crossed)
    for (dx,dz,tilt) in ((0.012,0.140,0.10),(-0.034,0.128,-0.08),(0.060,-0.050,0.05)):
        p0=Vector((dx,yfb,zc+dz)); d=Vector((tilt,-1.0,0.18)).normalized()
        p1=p0+d*0.045; p2=p1+d*0.035; p3=p2+d*0.040
        b.tube(p0,p1,0.0012,0.0035,sg(hi,4,10),'steel',cap0=False,cap1=False)
        b.tube(p1,p2,0.0035,0.0030,sg(hi,5,10),'gold',cap0=False,cap1=False)
        b.tube(p2,p3,0.0022,0.0020,4,'plastic_black',cap0=False,cap1=True)
        side=Vector((1,0,0)); up=d.cross(side).normalized(); side=up.cross(d).normalized()
        for ax,key in ((side,'flight_a'),(up,'flight_b')):
            q=[p2+d*0.010,p3+d*0.002,p3+d*0.002+ax*0.016,p2+d*0.022+ax*0.016]
            b.faces([Vector(v) for v in q],[(0,1,2,3)],key,[[(0,0),(0.03,0),(0.03,0.016),(0.012,0.016)]])
            q=[p2+d*0.010,p2+d*0.022-ax*0.016,p3+d*0.002-ax*0.016,p3+d*0.002]
            b.faces([Vector(v) for v in q],[(0,1,2,3)],key,[[(0,0),(0.012,0.016),(0.03,0.016),(0.03,0)]])
    b.cbox((0,yb-D/2,z0),(W+2*dw+0.01,D,H))

# ------------------------------------------------------------------ neon_wall_sign
def _neon(b, paths, r, key, glow, yt, ysh, hi):
    """lit tube (over-bright tint, near-white core colour) + a two-step glow halo painted on the backer behind it
    (outer wide dim band, inner narrow hot band): the kit has one opaque material and no emissive map, so the glow
    is carried by vertex tint on the backer, which reads as light spill on a phone screen."""
    for P in paths:
        pts=[Vector((x,yt,z)) for x,z in P]
        b.sweep(pts,r,sg(hi,4,10),key,cap0=hi,cap1=hi)
        for i in range(len(P)-1):
            a=Vector((P[i][0],0,P[i][1])); c=Vector((P[i+1][0],0,P[i+1][1])); t=(c-a); L=t.length
            if L<1e-6: continue
            t/=L
            for wd,ex,gk,dy in ((0.021,0.012,glow,0.0),(0.0095,0.004,glow+'h',0.0018)):
                nrm=Vector((-t.z,0,t.x))*wd; e=t*ex
                q=[a-nrm-e,c-nrm+e,c+nrm+e,a+nrm-e]
                _q(b,[(v.x,ysh-dy,v.z) for v in q],gk,(0,-1,0))
def _letter(ch, x, z, h, w):
    """block-script neon strokes for B E R O P N (x,z polylines, rounded bends)"""
    m=h*0.5; c=w*0.28
    if ch=='B': return [[(x,z),(x,z+h),(x+w-c,z+h),(x+w,z+h-c),(x+w,z+m+c*0.6),(x+w-c,z+m),(x,z+m)],
                        [(x+w-c,z+m),(x+w+0.01,z+m-c),(x+w+0.01,z+c),(x+w-c+0.01,z),(x,z)]]
    if ch=='E': return [[(x+w,z+h),(x,z+h),(x,z),(x+w,z)],[(x,z+m),(x+w*0.75,z+m)]]
    if ch=='R': return [[(x,z),(x,z+h),(x+w-c,z+h),(x+w,z+h-c),(x+w,z+m+c*0.6),(x+w-c,z+m),(x,z+m)],[(x+w*0.45,z+m),(x+w,z)]]
    return []
def neon_wall_sign(b, hi=False):
    """'BEER' in red glass tube with a yellow beer-mug outline and a blue underline on a black acrylic backer,
    chrome stand-offs, transformer box + clear cable. Backer on the wall (+Y)."""
    zb=1.55; W,H=0.86,0.50; yb=0.0
    b.box((0,yb-0.010,zb),(W,0.010,H),'acrylic_blk',ch=0,skip=('back',))
    b.box((0,yb-0.014,zb+0.03),(W-0.06,0.004,H-0.06),'acrylic_blk',ch=0,skip=('back',))
    for (x0_,z0_,x1_,z1_) in ((-W/2+0.03,zb+0.03,W/2-0.03,zb+0.034),(-W/2+0.03,zb+H-0.034,W/2-0.03,zb+H-0.03),
                              (-W/2+0.03,zb+0.03,-W/2+0.034,zb+H-0.03),(W/2-0.034,zb+0.03,W/2-0.03,zb+H-0.03)):
        _q(b,[(x0_,yb-0.0163,z0_),(x1_,yb-0.0163,z0_),(x1_,yb-0.0163,z1_),(x0_,yb-0.0163,z1_)],'chrome',(0,-1,0))   # polished routed edge
    for x in (-W/2+0.04,W/2-0.04):
        for z in (zb+0.04,zb+H-0.04):
            b.tube((x,yb-0.010,z),(x,yb-0.026,z),0.009,0.009,sg(hi,4,12),'chrome',cap0=False,cap1=True,phase=math.pi/4)
    yt=yb-0.032; ysh=yb-0.0166
    h,w=0.16,0.085; x0=-0.08; zl=zb+0.17
    paths=[]
    for i,chr_ in enumerate('BEER'): paths+=_letter(chr_,x0+i*(w+0.035),zl,h,w)
    _neon(b,paths,0.0065,'neon_r',None or 'glow_r',yt,ysh,hi)
    # beer mug: body, rim, handle, foam bubbles
    mx,mz=-0.30,zb+0.13; mw,mh=0.13,0.20
    mug=[[(mx,mz+mh),(mx+0.01,mz+0.02),(mx+0.03,mz),(mx+mw-0.03,mz),(mx+mw-0.01,mz+0.02),(mx+mw,mz+mh)],
         [(mx+mw,mz+mh*0.8),(mx+mw+0.05,mz+mh*0.75),(mx+mw+0.055,mz+mh*0.35),(mx+mw+0.005,mz+mh*0.28)],
         [(mx-0.01,mz+mh),(mx+0.02,mz+mh+0.04),(mx+0.06,mz+mh+0.025),(mx+0.09,mz+mh+0.045),(mx+mw+0.01,mz+mh)]]
    _neon(b,mug,0.0065,'neon_y','glow_y',yt,ysh,hi)
    _neon(b,[[(x0-0.01,zl-0.05),(x0+4*(w+0.035)-0.025,zl-0.05)]],0.0055,'neon_b','glow_b',yt,ysh,hi)
    # tube supports (glass standoffs) + transformer box under the backer corner, cable
    for (x,z) in ((x0+0.02,zl+0.08),(x0+0.30,zl+0.08),(mx+0.06,mz+0.10)):
        b.tube((x,yb-0.014,z),(x,yt+0.006,z),0.004,0.004,4,'plastic',cap0=False,cap1=True)
    b.box((W/2-0.09,yb-0.0175,zb+0.04),(0.07,0.0015,0.02),'badge',ch=0)                 # maker sticker
    b.sweep([Vector((W/2-0.03,yb-0.003,zb+0.03)),Vector((W/2-0.03,yb-0.003,zb-0.01)),Vector((W/2-0.03,yb-0.003,zb-0.16))],0.0028,4,'hose',cap0=False,cap1=False)
    b.cbox((0,yb-0.04,zb),(W,0.08,H))

# ------------------------------------------------------------------ keg_stack
def keg(b, c, hi=False, cap='keg_cap_g', coupler=False, label_rz=0.0):
    """US half-barrel keg (15.5 gal, 0.41 x 0.59 m): rolling ribs, chimes with handle slots, top dish + spear."""
    x,y,z=c; n=sg(hi,10,24)
    prof=[(0.180,0.0),(0.199,0.010),(0.199,0.056),(0.203,0.090),(0.203,0.168),(0.213,0.183),(0.203,0.198),
          (0.203,0.392),(0.213,0.407),(0.203,0.422),(0.203,0.500),(0.199,0.534),(0.199,0.580),(0.182,0.590),(0.182,0.548)]
    b.lathe(prof,n,'steel',c=(x,y,z),cap_top=False,cap_bot=False)
    # top dish + spear valve + plastic cap
    b.lathe([(0.182,0.548),(0.08,0.552),(0.0,0.556)],n,'steel',c=(x,y,z),cap_top=False)
    b.tube((x,y,z+0.556),(x,y,z+0.578),0.030,0.030,sg(hi,6,16),'chrome',cap0=False,cap1=True)
    if coupler:
        b.tube((x,y,z+0.578),(x,y,z+0.615),0.034,0.034,sg(hi,8,16),'chrome',cap0=False,cap1=True)
        b.box((x+0.035,y-0.01,z+0.588),(0.05,0.02,0.012),'paint_black')                       # coupler handle
        b.sweep([Vector((x,y,z+0.615)),Vector((x,y,z+0.66)),Vector((x-0.10,y+0.08,z+0.70)),Vector((x-0.25,y+0.20,z+0.62))],0.006,sg(hi,5,10),'hose',cap0=False,cap1=True)
        b.sweep([Vector((x-0.02,y,z+0.60)),Vector((x-0.08,y-0.06,z+0.64)),Vector((x-0.20,y-0.10,z+0.62))],0.005,sg(hi,5,10),'crate_bl',cap0=False,cap1=True)
    else:
        b.tube((x,y,z+0.578),(x,y,z+0.586),0.036,0.036,sg(hi,8,16),cap,cap0=False,cap1=True)
    # handle slots in the top chime (dark), keg collar label
    ac=0.199*math.cos(math.pi/n)+0.001
    _q(b,[(x-0.05,y-ac,z+0.552),(x+0.05,y-ac,z+0.552),(x+0.05,y-ac,z+0.574),(x-0.05,y-ac,z+0.574)],'hole',(0,-1,0))
    _q(b,[(x-0.05,y+ac,z+0.552),(x+0.05,y+ac,z+0.552),(x+0.05,y+ac,z+0.574),(x-0.05,y+ac,z+0.574)],'hole',(0,1,0))
    ap=0.203*math.cos(math.pi/n)
    b.box((x,y-ap-0.0015,z+0.26),(0.10,0.002,0.07),'label',ch=0)                     # brewery tag, flat on the front facet
def keg_stack(b, hi=False):
    """taproom keg stack: three half-barrels in a row on the floor, one stacked on the middle; the right keg is
    tapped (coupler + beer line + gas line), the others carry coloured brewery caps."""
    xs=(-0.212,0.212)
    keg(b,(xs[0],0.0,0.006),hi,'keg_cap_g'); keg(b,(xs[1],0.0,0.006),hi,coupler=True)
    keg(b,(xs[0],0.0,0.598),hi,'keg_cap_r')
    # rubber anti-slip mat under the pair
    b.box((0,0,0),(0.90,0.48,0.006),'rubber',skip=('bottom',),ch=0)
    b.cbox((0,0,0),(0.84,0.42,0.60)); b.cbox((xs[0],0,0.60),(0.42,0.42,0.59))

# ------------------------------------------------------------------ jukebox
def jukebox(b, hi=False):
    """1946-style arched jukebox (0.94 W x 0.62 D x 1.52 H): walnut cabinet, glowing coloured plastic arch bands,
    dome window onto the record changer, title-strip selector, chrome grille over the speaker cloth, coin plate."""
    W,D,Hs=0.94,0.60,1.05; R=W/2; na=sg(hi,10,24)
    yf,yb=-D/2,D/2
    arch=[(-W/2,0.0),(W/2,0.0)]+[(R*math.cos(math.radians(180*i/na)),Hs+R*math.sin(math.radians(180*i/na))) for i in range(na+1)]
    b.prism(arch,yf+0.06,yb,'walnut')
    # plinth
    b.box((0,0.02,0),(W+0.04,D,0.08),'walnut_dk',skip=('bottom',))
    # front fascia layers: outer arch band (orange) + inner arch band (red), side pilasters to the floor
    def band(r0,r1,y0,y1,key,zbot):
        pts=[(r0*math.cos(math.radians(180*i/na)),Hs+r0*math.sin(math.radians(180*i/na))) for i in range(na+1)]
        inn=[(r1*math.cos(math.radians(180*i/na)),Hs+r1*math.sin(math.radians(180*i/na))) for i in range(na+1)]
        for i in range(na):
            for (P,Q,want) in (((pts[i],pts[i+1]),(inn[i+1],inn[i]),(0,-1,0)),):
                _q(b,[(P[0][0],y0,P[0][1]),(P[1][0],y0,P[1][1]),(Q[0][0],y0,Q[0][1]),(Q[1][0],y0,Q[1][1])],key,want)
            a0,a1=pts[i],pts[i+1]
            _q(b,[(a0[0],y0,a0[1]),(a1[0],y0,a1[1]),(a1[0],y1,a1[1]),(a0[0],y1,a0[1])],key,(a0[0]+a1[0],0,a0[1]+a1[1]-2*Hs))
        for sx in (-1,1):
            xo,xi_=sx*r0,sx*r1
            _q(b,[(xo,y0,zbot),(xi_,y0,zbot),(xi_,y0,Hs),(xo,y0,Hs)],key,(0,-1,0))
            _q(b,[(xo,y0,zbot),(xo,y1,zbot),(xo,y1,Hs),(xo,y0,Hs)],key,(sx,0,0))
    band(R-0.005,R-0.085,yf+0.02,yf+0.20,'jb_orange',0.30)
    band(R-0.085,R-0.125,yf+0.035,yf+0.06,'jb_red',0.30)
    # bubble tubes: vertical cylinders on the pilasters (yellow), chrome caps
    for sx in (-1,1):
        x=sx*(R-0.045)
        b.tube((x,yf+0.012,0.32),(x,yf+0.012,Hs-0.02),0.016,0.016,sg(hi,6,12),'jb_yellow',cap0=False,cap1=False)
        b.tube((x,yf+0.012,0.30),(x,yf+0.012,0.33),0.019,0.019,sg(hi,6,12),'chrome',cap0=False,cap1=True)
    # upper dome window: dark glass set back, record + tone arm behind it, chrome frame
    rw=R-0.125; yw=yf+0.057
    win=[(-rw,Hs-0.05)]+[(rw*math.cos(math.radians(180-180*i/na)),Hs+rw*math.sin(math.radians(180-180*i/na))) for i in range(na+1)]+[(rw,Hs-0.05)]
    _q(b,[(x,yw,z) for x,z in win],'jb_win',(0,-1,0))
    b.tube((0,yw-0.004,Hs+0.12),(0,yw-0.010,Hs+0.12),0.125,0.125,sg(hi,12,28),'vinyl_rec',cap0=False,cap1=True)
    b.tube((0,yw-0.010,Hs+0.12),(0,yw-0.012,Hs+0.12),0.045,0.045,sg(hi,8,16),'jb_red',cap0=False,cap1=True)
    b.box((0.13,yw-0.03,Hs+0.20),(0.16,0.012,0.014),'chrome',rz=0.0,rx=0.0)
    for x in (-0.17,0.17):
        b.box((x,yw-0.02,Hs-0.04),(0.09,0.03,0.14),'chrome')                              # changer posts
    b.box((0,yw-0.025,Hs-0.05),(0.30,0.04,0.025),'chrome')                                 # carriage
    # crest on the crown + chrome trim line round the arch top
    b.box((0,yf+0.11,Hs+R-0.012),(0.12,0.06,0.05),'gold')
    # selector: chrome frame with title strips (unique bake) and push buttons
    zs=Hs-0.20
    b.box((0,yf+0.035,zs),(2*rw+0.02,0.05,0.16),'chrome')
    b.box((0,yf+0.008,zs+0.02),(2*rw-0.06,0.004,0.12),'label' if hi else 'titles',ch=0)
    if hi:   # two rows of five title cards: red song line + navy artist line (baked into the strip)
        for r_ in range(2):
            for c_ in range(5):
                cx=-rw+0.06+c_*(2*rw-0.12)/4; cz=zs+0.035+r_*0.055
                b.box((cx,yf+0.0045,cz+0.024),(0.085,0.002,0.009),'ceramic',ch=0)
                b.box((cx,yf+0.0045,cz+0.008),(0.07,0.002,0.008),'paint_navy',ch=0)
                b.box((cx+0.046,yf+0.0045,cz),(0.002,0.002,0.046),'paint_black',ch=0)
    for i in range(10):
        b.box((-rw+0.06+i*(2*rw-0.12)/9,yf+0.02,zs-0.02),(0.026,0.03,0.018),'paint_cream')
    # speaker: cloth panel + chrome grille bars + centre medallion
    zg0,zg1=0.36,zs-0.06; gw=2*(R-0.13)
    b.box((0,yf+0.05,zg0),(gw,0.012,zg1-zg0),'grille',ch=0)
    nb=sg(hi,9,9)
    for i in range(nb):
        x=-gw/2+0.03+i*(gw-0.06)/(nb-1)
        b.box((x,yf+0.038,zg0+0.01),(0.010,0.012,zg1-zg0-0.02),'chrome')
    b.box((0,yf+0.036,(zg0+zg1)/2-0.012),(gw-0.02,0.014,0.024),'chrome')
    b.tube((0,yf+0.036,(zg0+zg1)/2),(0,yf+0.028,(zg0+zg1)/2),0.05,0.05,sg(hi,10,20),'gold',cap0=False,cap1=True)
    # lower kick panel + coin entry plate with slot, maker plate
    b.box((0,yf+0.06-0.004,0.08),(W-0.04,0.008,0.20),'walnut_dk')
    b.box((0.30,yf+0.012,zs+0.05),(0.07,0.012,0.10),'chrome')
    b.box((0.30,yf+0.0055,zs+0.11),(0.03,0.002,0.006),'hole')
    maker_plate(b,(0.0,yf+0.051,0.13),hi,w=0.12,h=0.03)
    b.cbox((0,0,0),(W+0.04,D,Hs+R))

# ------------------------------------------------------------------ wine_barrel_display
def bottle(b, c, hi=False, glass='bottle_g', foil='foil_r', label=True, lying=None):
    x,y,z=c; n=sg(hi,8,16)
    prof=[(0.0,0.0),(0.036,0.0),(0.037,0.012),(0.037,0.205),(0.030,0.235),(0.014,0.262),(0.0145,0.300),(0.0,0.300)]
    if lying is None:
        b.lathe(prof[1:6],n,glass,c=(x,y,z),cap_top=False,cap_bot=True)
        b.lathe([(0.014,0.262),(0.0145,0.302)],n,foil,c=(x,y,z),cap_top=True)
        if label: b.lathe([(0.0375,0.06),(0.0375,0.15)],n,'label',c=(x,y,z),cap_top=False)
def wine_barrel_display(b, hi=False):
    """225 L Bordeaux barrique stood on end as a display: oak staves, four iron hoops, head with three bottles,
    a stemmed glass and a chalk price card; a pine wine crate with lying bottles leans at the foot."""
    n=sg(hi,14,32)
    H=0.95; rb,rm=0.290,0.355
    prof=[(rb-0.004,0.0),(rb,0.012)]+[(rb+(rm-rb)*math.sin(math.pi*t),H*t) for t in (0.16,0.34,0.5,0.66,0.84)]+[(rb,H-0.012),(rb-0.004,H)]
    b.lathe(prof,n,'oak_barrel',cap_top=False,cap_bot=False,phase=math.pi/n)
    b.lathe([(rb-0.004,H),(rb-0.020,H),(rb-0.020,H-0.025)],n,'oak_barrel',cap_top=False,phase=math.pi/n)       # chime
    b.lathe([(rb-0.020,H-0.025),(0.0,H-0.025)],n,'oak_barrel',cap_top=False,phase=math.pi/n)                    # head
    # stave joints: thin dark lines down the belly (every second facet edge)
    for i in range(0,n,2):
        a=2*math.pi*i/n
        pts=[]
        for t in (0.0,0.16,0.34,0.5,0.66,0.84,1.0):
            r=rb+(rm-rb)*math.sin(math.pi*t)+0.0015; pts.append((r*math.cos(a),r*math.sin(a),H*t))
        for k in range(len(pts)-1):
            p0,p1=Vector(pts[k]),Vector(pts[k+1]); tg=Vector((-math.sin(a),math.cos(a),0))*0.0018
            _q(b,[p0-tg,p0+tg,p1+tg,p1-tg],'walnut_dk',(math.cos(a),math.sin(a),0))
    # four iron hoops
    for t in (0.06,0.22,0.78,0.94):
        r=rb+(rm-rb)*math.sin(math.pi*t)+0.004; z=H*t
        b.lathe([(r+0.002,z-0.024),(r+0.003,z+0.024)],n,'iron',cap_top=False,phase=math.pi/n)
    # bung: flush cork disc in a dark ring on the front stave (flat, so it casts no vertex-AO smudge on the belly)
    ab=-math.pi/2-math.pi/n                       # centre of the front-left stave facet (lathe phase pi/n)
    nb=Vector((math.cos(ab),math.sin(ab),0)); tb=Vector((-math.sin(ab),math.cos(ab),0)); zb_=Vector((0,0,1))
    for rr,kk,dy in ((0.032,'walnut_dk',0.0012),(0.022,'cork_k',0.0018)):
        cb=nb*(rm*math.cos(math.pi/n)+dy)+zb_*(H*0.5)
        _q(b,[cb+tb*(rr*math.cos(2*math.pi*i/8))+zb_*(rr*math.sin(2*math.pi*i/8)) for i in range(8)],kk,tuple(nb))
    # display on the head: three bottles, a glass of red, price card
    zt=H-0.025
    bottle(b,(-0.10,0.05,zt),hi,'bottle_g','foil_r'); bottle(b,(-0.01,0.13,zt),hi,'bottle_d','foil_g'); bottle(b,(0.06,0.02,zt),hi,'bottle_r','foil_g')
    ng=sg(hi,8,16)
    b.lathe([(0.035,0.0),(0.036,0.003),(0.004,0.008),(0.004,0.09),(0.030,0.105),(0.042,0.14),(0.040,0.19)],ng,'glass',c=(0.16,-0.10,zt),cap_top=False)
    b.lathe([(0.040,0.12),(0.0,0.12)],ng,'bottle_d',c=(0.16,-0.10,zt+0.002),cap_top=False)
    b.box((-0.12,-0.14,zt),(0.06,0.04,0.02),'oak',rz=0.3); b.box((-0.12,-0.14,zt+0.02),(0.10,0.006,0.07),'chalkbd',rz=0.3)
    b.box((-0.12,-0.144,zt+0.03),(0.07,0.002,0.04),'label',rz=0.3)
    # pine crate at the foot, two bottles lying in it
    cx,cy,cw,cd,ch=0.36,-0.30,0.36,0.26,0.17
    b.box((cx,cy,0),(cw,cd,0.012),'pine',rz=-0.5)
    rz=-0.5; c_,s_=math.cos(rz),math.sin(rz)
    def L(lx,ly): return (cx+lx*c_-ly*s_, cy+lx*s_+ly*c_)
    for (lx,ly,w,d) in ((0,-cd/2+0.006,cw,0.012),(0,cd/2-0.006,cw,0.012),(-cw/2+0.006,0,0.012,cd),(cw/2-0.006,0,0.012,cd)):
        px,py=L(lx,ly); b.box((px,py,0.0),(w,d,ch),'pine',rz=rz)
    px,py=L(0,-cd/2-0.001); b.box((px,py,0.06),(0.16,0.002,0.05),'badge',rz=rz)
    for ly in (-0.05,0.06):
        p0=L(-0.15,ly); p1=L(0.07,ly); p2=L(0.13,ly)
        b.tube((p0[0],p0[1],0.05),(p1[0],p1[1],0.05),0.036,0.036,sg(hi,8,16),'bottle_g' if ly<0 else 'bottle_d',cap0=True,cap1=False)
        b.tube((p1[0],p1[1],0.05),(p2[0],p2[1],0.05),0.036,0.014,sg(hi,8,16),'bottle_g' if ly<0 else 'bottle_d',cap0=False,cap1=False)
        p3=L(0.175,ly); b.tube((p2[0],p2[1],0.05),(p3[0],p3[1],0.05),0.0145,0.0145,sg(hi,6,12),'foil_r',cap0=False,cap1=True)
    b.ccyl((0,0,0),rm,H); b.cbox((cx,cy,0),(cw,cd,ch),rz=-0.5)

# ------------------------------------------------------------------ record_crate_bins
def _sleeves(b, x0, x1, y0, y1, zb, n, hi, rnd, tilt=0.20, h=0.315, cover_first=False):
    """n LP sleeves standing on edge from y0 (front) to y1, leaning back by `tilt` rad; front, back and top faces"""
    keys=['sl_%d'%i for i in range(8)]
    for i in range(n):
        y=y0+(y1-y0)*(i+0.5)/n; k=keys[rnd[i%len(rnd)]]
        dy=h*math.sin(tilt); dz=h*math.cos(tilt); t=0.0035
        xa,xb=x0+0.004*((i*7)%3),x1-0.004*((i*5)%3)
        F=[(xa,y-t,zb),(xb,y-t,zb),(xb,y-t+dy,zb+dz),(xa,y-t+dy,zb+dz)]
        Bk=[(xb,y+t,zb),(xa,y+t,zb),(xa,y+t+dy,zb+dz),(xb,y+t+dy,zb+dz)]
        cov=cover_first and i==0
        _q(b,F,(('screen' if cover_first==1 else 'ceramic') if (cov and hi) else ('cover' if cov else k)),(0,-math.cos(tilt),math.sin(tilt)))
        if cov and hi:   # cover art 3 mm in front of the near cover: disc, title band, stripe
            nv=Vector((0,-math.cos(tilt),math.sin(tilt))); up=Vector((0,math.sin(tilt),math.cos(tilt)))
            o=Vector(((xa+xb)/2,y-t,zb))+nv*0.003; ww=(xb-xa)
            disc=[o+Vector((0.06*math.cos(2*math.pi*j/24),0,0))+up*(0.15+0.075*math.sin(2*math.pi*j/24)) for j in range(24)]
            b.faces(disc,[tuple(range(24))],'paint_black',[[(v.x,v.z) for v in disc]])
            for (zz,hh,kk,x0_,x1_) in ((0.255,0.035,'label',-0.13,0.13),(0.035,0.018,'paint_cream' if cover_first==1 else 'paint_navy',-0.13,0.02),(0.065,0.006,'brass',-0.13,0.10)):
                q=[o+Vector((x0_,0,0))+up*zz,o+Vector((x1_,0,0))+up*zz,o+Vector((x1_,0,0))+up*(zz+hh),o+Vector((x0_,0,0))+up*(zz+hh)]
                _q(b,q,kk,nv)
        _q(b,Bk,k,(0,math.cos(tilt),-math.sin(tilt)))
        _q(b,[F[3],F[2],Bk[2],Bk[3]][::-1],k,(0,0,1))
def record_crate_bins(b, hi=False):
    """record-shop browser: pine bin table with two LP bins (sleeves leaning back, A-Z divider cards), two plastic
    milk crates of records on the under-shelf, price card."""
    W,D,H=0.84,0.62,0.62; leg=0.045
    for sx in (-1,1):
        for sy in (-1,1): b.box((sx*(W/2-leg/2),sy*(D/2-leg/2),0),(leg,leg,H),'pine')
    b.box((0,0,0.10),(W-0.02,D-0.02,0.018),'pine')                       # under-shelf
    for sy in (-1,1): b.box((0,sy*(D/2-0.01),0.08),(W-2*leg,0.02,0.04),'pine')
    # bins: floor + walls, front wall lower
    bw=(W-0.03)/2; bh=0.22
    b.box((0,0,H),(W,D,0.018),'pine')
    for xc in (-bw/2-0.005,bw/2+0.005):
        b.box((xc,-D/2+0.009,H),(bw,0.018,0.11),'pine'); b.box((xc,D/2-0.009,H),(bw,0.018,bh),'pine')
    for x in (-W/2+0.009,0.0,W/2-0.009):
        b.box((x,0,H),(0.018,D,0.11),'pine'); b.box((x,D/4,H+0.11),(0.018,D/2,bh-0.11),'pine')
    rnd=[0,4,2,1,3,5,7,6,1,0,3,2,4,6,5,7,2,1,0,3,7,4]
    for k,xc in enumerate((-bw/2-0.005,bw/2+0.005)):
        _sleeves(b,xc-bw/2+0.015,xc+bw/2-0.015,-D/2+0.03,D/2-0.05,H+0.018,sg(hi,20,20),hi,rnd[k*3:]+rnd[:k*3],cover_first=k+1)
        for yy,lab in ((-0.12,0),(0.08,1)):
            b.box((xc+bw/2-0.06-0.10*lab,yy,H+0.018),(0.07,0.003,0.36),'paint_white' if lab else 'sl_2',rx=-0.20,ch=0)   # divider tab above the sleeves
    # two milk crates under (blue, orange) with records
    for k,(xc,key) in enumerate(((-0.19,'crate_bl'),(0.20,'crate_or'))):
        cw,cd,ch=0.33,0.33,0.28; z0=0.118
        b.box((xc,0,z0),(cw,cd,0.012),key)
        for (lx,ly,w,d) in ((0,-cd/2+0.006,cw,0.012),(0,cd/2-0.006,cw,0.012),(-cw/2+0.006,0,0.012,cd),(cw/2-0.006,0,0.012,cd)):
            b.box((xc+lx,ly,z0),(w,d,ch),key)
        for j in range(3):   # grid slots on the front face
            for i in range(4):
                _q(b,[(xc-cw/2+0.03+i*0.075,-cd/2-0.0005,z0+0.04+j*0.08),(xc-cw/2+0.08+i*0.075,-cd/2-0.0005,z0+0.04+j*0.08),
                      (xc-cw/2+0.08+i*0.075,-cd/2-0.0005,z0+0.09+j*0.08),(xc-cw/2+0.03+i*0.075,-cd/2-0.0005,z0+0.09+j*0.08)],'hole',(0,-1,0))
        _sleeves(b,xc-cw/2+0.015,xc+cw/2-0.015,-cd/2+0.03,cd/2-0.03,z0+0.012,10,hi,rnd[k*5:],tilt=0.08,h=0.24)
    b.box((W/2-0.10,-D/2-0.012,H+0.03),(0.12,0.004,0.07),'badge')
    b.cbox((0,0,0),(W,D,H+0.30))

# ------------------------------------------------------------------ concession_popcorn_machine
def concession_popcorn_machine(b, hi=False):
    """cinema / venue popcorn wagon: red cart with two spoked wheels and a push handle, glass cabinet (frames
    only + reflection streaks, no alpha), stainless kettle hanging from the roof, heaped popcorn, lit header sign."""
    W,D=0.72,0.50; zc=0.86; Hc=0.66
    # cart body + drawer + corner posts
    b.box((0,0,0.32),(W,D,zc-0.32),'pop_red')
    b.box((0,-D/2-0.004,0.40),(W-0.12,0.008,0.30),'pop_red')
    b.box((0,-D/2-0.012,0.53),(0.16,0.014,0.03),'chrome')
    b.box((0,0,zc-0.02),(W+0.04,D+0.04,0.03),'chrome')
    # wheels (left), legs with feet (right), push handle
    for sy in (-1,1):
        y=sy*(D/2+0.03); cz=0.30
        wx=-W/2+0.18; nw=sg(hi,14,32)
        o_=Vector((wx,y,cz)); ax=Vector((0,1,0))
        ring_o=[o_+Vector((0.30*math.cos(2*math.pi*i/nw),0,0.30*math.sin(2*math.pi*i/nw))) for i in range(nw)]
        ring_i=[o_+Vector((0.265*math.cos(2*math.pi*i/nw),0,0.265*math.sin(2*math.pi*i/nw))) for i in range(nw)]
        for i in range(nw):
            j=(i+1)%nw; d=Vector((0,0.02,0))
            _q(b,[ring_o[i]-d,ring_o[j]-d,ring_o[j]+d,ring_o[i]+d],'rubber',(ring_o[i]-o_))                   # tyre
            _q(b,[ring_i[i]-d,ring_i[j]-d,ring_i[j]+d,ring_i[i]+d],'pop_red',(o_-ring_i[i]))                 # rim inside
            for sd in (-1,1): _q(b,[ring_o[i]+d*sd,ring_o[j]+d*sd,ring_i[j]+d*sd,ring_i[i]+d*sd],'pop_red' if sd*sy<0 else 'rubber',(0,sd,0))
        for k in range(8):
            a=2*math.pi*k/8+0.2; e=Vector((math.cos(a),0,math.sin(a)))
            b.tube(o_+e*0.04,o_+e*0.27,0.009,0.007,4,'gold',cap0=False,cap1=False)
        b.tube((wx,y-0.03,cz),(wx,y+0.03,cz),0.045,0.045,sg(hi,8,16),'gold',cap0=True,cap1=True)
        b.box((W/2-0.06,sy*(D/2-0.05),0),(0.05,0.05,0.32),'pop_red')
        b.box((W/2-0.06,sy*(D/2-0.05),0),(0.07,0.07,0.02),'rubber',skip=('bottom',))
    b.tube((-W/2+0.18,-D/2-0.06,0.30),(-W/2+0.18,D/2+0.06,0.30),0.015,0.015,sg(hi,6,12),'chrome',cap0=True,cap1=True)
    b.sweep([Vector((W/2,-D/2+0.05,0.70)),Vector((W/2+0.20,-D/2+0.05,0.80)),Vector((W/2+0.20,D/2-0.05,0.80)),Vector((W/2,D/2-0.05,0.70))],0.012,sg(hi,6,12),'chrome',cap0=False,cap1=False)
    # glass cabinet: red corner posts, chrome sill, roof with sign
    z0=zc+0.01; pw=0.035
    for sx in (-1,1):
        for sy in (-1,1): b.box((sx*(W/2-pw/2),sy*(D/2-pw/2),z0),(pw,pw,Hc),'pop_red')
    b.box((0,0,z0),(W,D,0.04),'pop_red',skip=('bottom',))
    b.box((0,0,z0+Hc),(W+0.04,D+0.04,0.05),'pop_red')
    b.box((0,0,z0+Hc+0.05),(W-0.04,D-0.04,0.02),'chrome')
    # header sign (unique bake: lettering on the hi) both faces
    b.box((0,0,z0+Hc+0.07),(W-0.08,0.06,0.16),'pop_red')
    for sy in (-1,1):
        b.box((0,sy*0.031,z0+Hc+0.085),(W-0.16,0.002,0.13),'label' if hi else 'badge_sign',ch=0)
        if hi:
            import pg as _pg
            _pg.add_text(b,'POPCORN',0.10,(0,sy*0.034,z0+Hc+0.15),(-sy*1,0,0) if sy>0 else (1,0,0),(0,0,1),0.002,'ceramic')
    # top caps (chrome ball finials)
    for sx in (-1,1):
        b.tube((sx*(W/2-0.06),0,z0+Hc+0.23),(sx*(W/2-0.06),0,z0+Hc+0.27),0.02,0.012,sg(hi,6,12),'gold',cap0=True,cap1=True)
    # glass: reflection streak strips on the front and side panes (sheen without alpha)
    # chrome glass-stop bead along the sill and under the roof (the panes themselves are left open: no alpha)
    for zz in (z0+0.04,z0+Hc-0.012):
        for sy in (-1,1): b.box((0,sy*(D/2-0.004),zz),(W-0.07,0.008,0.012),'chrome',ch=0)
        for sx in (-1,1): b.box((sx*(W/2-0.004),0,zz),(0.008,D-0.07,0.012),'chrome',ch=0)
    # kettle on its rod from the roof, lid, tilt handle
    kz=z0+Hc-0.30
    b.tube((0,0,z0+Hc),(0,0,kz+0.17),0.008,0.008,6,'chrome',cap0=False,cap1=False)
    b.lathe([(0.04,0.0),(0.11,0.02),(0.125,0.07),(0.125,0.15),(0.12,0.16)],sg(hi,10,24),'kettle',c=(0,0,kz),cap_top=True,cap_bot=True)
    b.tube((0.12,0,kz+0.12),(0.24,0,kz+0.14),0.008,0.008,6,'paint_black',cap0=False,cap1=True)
    # popcorn heap: jittered dome + overflow
    import random; R_=random.Random(7)
    nx,ny=sg(hi,7,16),sg(hi,5,12); zf=z0+0.04
    V=[]; F=[]
    for j in range(ny+1):
        for i in range(nx+1):
            x=-W/2+pw+(W-2*pw)*i/nx; y=-D/2+pw+(D-2*pw)*j/ny
            u=2*i/nx-1; v=2*j/ny-1
            h=0.20*max(0.0,1-0.50*u*u-0.40*v*v)+0.05+(R_.uniform(-0.03,0.03) if 0<i<nx and 0<j<ny else R_.uniform(-0.012,0.012))
            V.append(Vector((x,y,zf+h)))
    F2=[]
    for j in range(ny):
        for i in range(nx):
            a=j*(nx+1)+i; t1=(a,a+1,a+nx+2); t2=(a,a+nx+2,a+nx+1)
            if (i+j)%2: t1=(a,a+1,a+nx+1); t2=(a+1,a+nx+2,a+nx+1)
            F.append(t1); F2.append(t2)
    b.faces(V,F,'popcorn',[[(V[k].x,V[k].y) for k in f] for f in F],smooth=False)        # faceted = popped clusters
    b.faces(V,F2,'popcorn2',[[(V[k].x,V[k].y) for k in f] for f in F2],smooth=False)
    edge=[j*(nx+1)+0 for j in range(ny+1)][::-1]+[0+i for i in range(1,nx+1)]+[j*(nx+1)+nx for j in range(1,ny+1)]+[ny*(nx+1)+i for i in range(nx-1,-1,-1)]
    for k in range(len(edge)-1):   # skirt: the heap meets the cabinet floor (no gap under the edge)
        A_,B_=V[edge[k]],V[edge[k+1]]
        _q(b,[Vector((A_.x,A_.y,zf)),Vector((B_.x,B_.y,zf)),B_,A_],'popcorn',(A_.x+B_.x,A_.y+B_.y,0))
    # loose kernels on the heap and the sill (3-sided puffs)
    for k in range(sg(hi,22,22)):
        u=R_.uniform(-0.85,0.85); v=R_.uniform(-0.8,0.8)
        x=u*(W/2-pw); y=v*(D/2-pw); h=0.20*max(0.0,1-0.50*u*u-0.40*v*v)+0.05
        b.tube((x,y,zf+h-0.008),(x+R_.uniform(-0.01,0.01),y,zf+h+0.022),0.022,0.006,3,'popcorn',cap0=False,cap1=False,phase=R_.uniform(0,6))
    # scoop + a filled striped bag on the sill
    b.box((0.20,-0.12,zf+0.06),(0.08,0.06,0.03),'kettle',rz=0.4)
    b.cbox((0,0,0),(W+0.40,D+0.12,z0+Hc+0.25))

# ------------------------------------------------------------------ folding_table_chairs
def folding_chair(b, c, yaw, hi=False):
    x,y,z=c; ca,sa=math.cos(yaw),math.sin(yaw)
    def P(lx,ly,lz): return Vector((x+lx*ca-ly*sa,y+lx*sa+ly*ca,z+lz))
    n=sg(hi,6,10); r=0.011
    for sx in (-1,1):
        # front leg up to the seat, rear leg/back post up to the backrest top (crossed X)
        b.tube(P(sx*0.20,-0.20,0.0),P(sx*0.20,0.06,0.46),r,r,n,'chair_frame',cap0=True,cap1=False)
        b.tube(P(sx*0.19,0.22,0.0),P(sx*0.19,0.17,0.83),r,r,n,'chair_frame',cap0=True,cap1=True)
        b.tube(P(sx*0.20,-0.21,0.46),P(sx*0.20,0.17,0.46),r*0.9,r*0.9,n,'chair_frame',cap0=True,cap1=True)
        b.box(P(sx*0.20,-0.20,0),(0.03,0.03,0.012),'rubber',rz=yaw,skip=('bottom',))
        b.box(P(sx*0.19,0.22,0),(0.03,0.03,0.012),'rubber',rz=yaw,skip=('bottom',))
    b.tube(P(-0.20,-0.12,0.10),P(0.20,-0.12,0.10),r*0.8,r*0.8,n,'chair_frame',cap0=False,cap1=False)
    b.tube(P(-0.19,0.20,0.12),P(0.19,0.20,0.12),r*0.8,r*0.8,n,'chair_frame',cap0=False,cap1=False)
    b.box(P(0,-0.03,0.455),(0.42,0.40,0.05),'seat_pad',rz=yaw)
    b.box(P(0,0.18,0.60),(0.40,0.03,0.20),'seat_pad',rz=yaw,rx=-0.10)
def folding_table_chairs(b, hi=False):
    """6 ft white HDPE folding table (1.83 x 0.76 x 0.74) on grey steel fold-out legs, two padded folding chairs.
    Recipe use: community / event rooms only (senior centre, venue back rooms). Never in bar / pub / taproom recipes."""
    L,Wd,H=1.83,0.76,0.74; n=sg(hi,6,10); r=0.0125
    b.box((0,0,H-0.045),(L,Wd,0.045),'hdpe',keys={'front':'hdpe_edge','back':'hdpe_edge','left':'hdpe_edge','right':'hdpe_edge','bottom':'hdpe_under'})
    # moulded edge band (slightly darker grey) and everyday scuffs on the top
    for sy in (-1,1): _q(b,[(-L/2,sy*(Wd/2+0.0008),H-0.030),(L/2,sy*(Wd/2+0.0008),H-0.030),(L/2,sy*(Wd/2+0.0008),H-0.018),(-L/2,sy*(Wd/2+0.0008),H-0.018)],'hdpe_band',(0,sy,0))
    import random; R_=random.Random(11)
    for k in range(9):
        x=R_.uniform(-0.8,0.8); y=R_.uniform(-0.3,0.3); a=R_.uniform(0,math.pi); l=R_.uniform(0.05,0.16); w=R_.uniform(0.004,0.012)
        d=Vector((math.cos(a),math.sin(a),0)); nn=Vector((-d.y,d.x,0))
        c=Vector((x,y,H+0.0007))
        _q(b,[c-d*l/2-nn*w/2,c+d*l/2-nn*w*0.2,c+d*l/2+nn*w*0.2,c-d*l/2+nn*w/2],'hdpe_scuff',(0,0,1))
    for (x,y,r_) in ((0.35,0.12,0.06),(-0.55,-0.18,0.045)):   # faint ring marks
        _q(b,[(x+r_*math.cos(2*math.pi*i/8),y+r_*math.sin(2*math.pi*i/8),H+0.0006) for i in range(8)],'hdpe_scuff2',(0,0,1))
    b.box((0,0,H-0.075),(L-0.06,Wd-0.06,0.03),'paint_grey',skip=('top',))              # steel apron frame
    b.box((0,0,H-0.058),(L-0.012,Wd-0.012,0.013),'paint_grey',ch=0,skip=('top',))      # moulded rim lip (shadow line)
    for sx in (-1,1):
        x=sx*(L/2-0.13)
        for sy in (-1,1):
            b.tube((x,sy*(Wd/2-0.06),0.0),(x,sy*(Wd/2-0.06),H-0.075),r,r,n,'chair_frame',cap0=True,cap1=False)
            b.box((x,sy*(Wd/2-0.06),0),(0.035,0.035,0.012),'rubber',skip=('bottom',))
        b.tube((x,-(Wd/2-0.06),0.10),(x,Wd/2-0.06,0.10),r*0.8,r*0.8,n,'chair_frame',cap0=False,cap1=False)
        b.tube((x,0,0.10),(x-sx*0.45,0,H-0.075),r*0.7,r*0.7,n,'chair_frame',cap0=False,cap1=False)   # fold brace
    b.box((0,0,H-0.08),(0.30,0.04,0.004),'chair_frame')                                 # centre lock plate
    folding_chair(b,(-0.42,Wd/2+0.16,0),0.0,hi)
    folding_chair(b,(0.42,-Wd/2-0.16,0),math.pi,hi)
    b.box((L/2-0.03,-Wd/2-0.0005,H-0.04),(0.08,0.001,0.03),'badge')
    b.cbox((0,0,0),(L,Wd,H)); b.cbox((-0.42,Wd/2+0.16,0),(0.46,0.46,0.86)); b.cbox((0.42,-Wd/2-0.16,0),(0.46,0.46,0.86))

_C=dict(dir='props/indoor/leisure',pdir='indoor_leisure',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
PROPS=[
    _p('pool_table',pool_table,'large',2400),
    _p('dartboard',dartboard,'small',600,side=96,mount='wall',cage=0.04,ray=0.12,shift=(0.0,0.087)),
    _p('neon_wall_sign',neon_wall_sign,'small',600,mount='wall',cage=0.04,ray=0.12),
    _p('keg_stack',keg_stack,'medium',1200),
    _p('jukebox',jukebox,'medium',1200,cage=0.04,ray=0.12),
    _p('wine_barrel_display',wine_barrel_display,'medium',1200,shift=(-0.117,0.073)),
    _p('record_crate_bins',record_crate_bins,'medium',1200,side=96,cage=0.04,ray=0.12),
    _p('concession_popcorn_machine',concession_popcorn_machine,'medium',1200,side=96,cage=0.04,ray=0.12),
    _p('folding_table_chairs',folding_table_chairs,'medium',1100),
]

INDOOR_LOOK=True   # run.py: chamfer edge highlight + per-part colour variation in COLOR_0
