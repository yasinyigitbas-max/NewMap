"""Indoor food-service props (shop-gap batch 3, module b_infoodsvc) — original geometry, page I, near+col only. No mid/far.
Shared page-I trims + per-key vertex tint (one material per prop); small unique bake slots only for print
(signs, labels, badges). Wall-backed props have their back on +Y (viewer at -Y).
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math, random
from mathutils import Vector
from b_inshared import sg, maker_plate, leveler
from b_inretailfx import TR as _TR, TINT as _TINT, _q, V, ring_pts, nfaces, xform

TR=dict(_TR); TINT=dict(_TINT)
_NEW={
 'ss':('ti_metal',(0.95,0.96,0.98)), 'ss_dk':('ti_metal',(0.55,0.56,0.58)), 'kick_blk':('ti_paint',(0.10,0.10,0.11)),
 'ketchup':('ti_plastic',(0.65,0.05,0.04)), 'mustard':('ti_plastic',(1.00,0.78,0.08)), 'mayo':('ti_plastic',(1.05,1.02,0.90)),
 'salsa_r':('ti_paint',(0.62,0.10,0.05)), 'salsa_g':('ti_paint',(0.35,0.50,0.15)), 'pico':('ti_paint',(0.85,0.32,0.16)),
 'crema':('ti_paint',(1.05,1.00,0.90)), 'lime':('ti_paint',(0.45,0.72,0.15)), 'ice':('ti_paint',(1.02,1.05,1.10)), 'ice2':('ti_paint',(0.86,0.93,1.02)),
 'kraft':('ti_paint',(0.80,0.62,0.42)), 'bread':('ti_paint',(0.85,0.52,0.22)), 'bread_dk':('ti_paint',(0.55,0.30,0.12)),
 'crust_lt':('ti_paint',(1.00,0.80,0.48)), 'wicker':('ti_wood',(1.00,0.80,0.50)), 'glaze_pink':('ti_paint',(1.08,0.55,0.70)),
 'glaze_choc':('ti_paint',(0.32,0.17,0.08)), 'glaze_wht':('ti_paint',(1.08,1.05,0.98)), 'dough':('ti_paint',(0.95,0.66,0.32)),
 'cone':('ti_paint',(0.92,0.62,0.30)), 'conch_pink':('ti_paint',(1.02,0.62,0.68)), 'conch_yel':('ti_paint',(1.05,0.88,0.50)),
 'conch_choc':('ti_paint',(0.45,0.25,0.12)), 'hotdog':('ti_paint',(0.70,0.26,0.12)), 'bun':('ti_paint',(1.00,0.76,0.45)),
 'coffee_dk':('ti_glass',(0.20,0.10,0.05)), 'meat_pink':('ti_paint',(0.92,0.52,0.50)), 'meat_red':('ti_paint',(0.66,0.20,0.18)),
 'cheese':('ti_paint',(1.05,0.85,0.35)), 'fish_silver':('ti_paint',(0.72,0.76,0.80)), 'fish_red':('ti_paint',(0.85,0.30,0.25)),
 'fish_dk':('ti_paint',(0.38,0.44,0.50)), 'lemon':('ti_paint',(1.10,0.95,0.30)), 'rice':('ti_paint',(1.05,1.02,0.92)),
 'beans':('ti_paint',(0.45,0.25,0.15)), 'greens':('ti_paint',(0.25,0.45,0.15)), 'sauce_r':('ti_paint',(0.60,0.15,0.08)),
 'ice_blue':('ti_paint',(0.15,0.40,0.85)), 'frz_wht':('ti_paint',(1.05,1.06,1.06)), 'tray_brn':('ti_plastic',(0.35,0.22,0.15)),
 'airpot':('ti_metal',(0.80,0.82,0.85)), 'cup_wht':('ti_paint',(1.06,1.05,1.02)), 'lam_wd':('ti_laminate',(0.75,0.55,0.35)),
 'sugar_pk':('ti_paint',(1.05,0.60,0.70)), 'sugar_bl':('ti_paint',(0.35,0.55,0.95)), 'sugar_yl':('ti_paint',(1.05,0.90,0.30)),
 'red_lam':('ti_laminate',(0.70,0.10,0.08)), 'coffee_bean':('ti_paint',(0.30,0.17,0.08)), 'grinder_red':('ti_paint',(0.70,0.08,0.06)),
}
for k,(t,c) in _NEW.items(): TR[k]=(t,(0.875,0.875)); TINT[k]=c
SL=['sl_%d'%i for i in range(8)]

def counter(b, L, D, H, body, top, kick=True, top_t=0.03, c=(0,0)):
    x,y=c
    if kick: b.box((x,y+0.03,0),(L-0.06,D-0.06,0.10),'kick_blk',skip=('bottom',))
    b.box((x,y,0.10 if kick else 0),(L,D,H-top_t-(0.10 if kick else 0)),body)
    b.box((x,y,H-top_t),(L+0.02,D+0.02,top_t),top)
def frontq(b, x0, x1, y, z0, z1, key, n=(0,-1,0)):
    _q(b,[(x0,y,z0),(x1,y,z0),(x1,y,z1),(x0,y,z1)],key,n)
def topq(b, x0, x1, y0, y1, z, key):
    _q(b,[(x0,y0,z),(x1,y0,z),(x1,y1,z),(x0,y1,z)],key,(0,0,1))
def pump(b, x, y, z, key, hi, h=0.20, r=0.045):
    """condiment pump: bottle body, white pump head, spout toward -Y"""
    n=sg(hi,6,12)
    b.tube((x,y,z),(x,y,z+h),r,r,n,key,cap0=False,cap1=True)
    b.tube((x,y,z+h),(x,y,z+h+0.03),0.016,0.016,sg(hi,5,8),'mayo' if key!='mayo' else 'paint_white',cap0=False,cap1=False)
    b.box((x,y-0.01,z+h+0.03),(0.04,0.07,0.025),'paint_white' if key!='mayo' else 'steel')
    b.tube((x,y-0.04,z+h+0.04),(x,y-0.065,z+h+0.025),0.006,0.005,4,'paint_white',cap0=False,cap1=True)
def airpot(b, x, y, z, hi, band='paint_black'):
    n=sg(hi,8,14)
    b.lathe([(0.075,0.0),(0.078,0.02),(0.075,0.30),(0.065,0.32)],n,'airpot',c=(x,y,z),cap_top=False)
    b.box((x,y,z+0.32),(0.13,0.15,0.05),band); b.box((x,y-0.08,z+0.30),(0.04,0.03,0.06),band)
    frontq(b,x-0.035,x+0.035,y-0.0785,z+0.12,z+0.19,'label')
def napkin_box(b, x, y, z, hi):
    b.box((x,y,z),(0.16,0.13,0.17),'ss')
    frontq(b,x-0.06,x+0.06,y-0.0655,z+0.02,z+0.14,'paint_white')
def tray_stack(b, x, y, z, n, key, w=0.45, d=0.35):
    for i in range(n): b.box((x,y,z+i*0.022),(w-0.004*i,d-0.004*i,0.02),key,ch=0,skip=('bottom',) if i else ())
def pan(b, x, y, z, w, d, key, hi, depth=0.03, mound=True):
    """hotel pan set into a counter: ss rim + food surface below the rim, low mound"""
    frame=0.012
    for (a0,a1,b0,b1) in ((x-w/2,x+w/2,y-d/2,y-d/2+frame),(x-w/2,x+w/2,y+d/2-frame,y+d/2),(x-w/2,x-w/2+frame,y-d/2,y+d/2),(x+w/2-frame,x+w/2,y-d/2,y+d/2)):
        topq(b,a0,a1,b0,b1,z+0.012,'ss')
    zf=z+0.004
    if mound:
        c=V(x,y,zf+0.03); P=[V(x-w/2+frame,y-d/2+frame,zf),V(x+w/2-frame,y-d/2+frame,zf),V(x+w/2-frame,y+d/2-frame,zf),V(x-w/2+frame,y+d/2-frame,zf)]
        for i in range(4):
            j=(i+1)%4; n_=((P[j]-P[i]).cross(c-P[i])).normalized(); _q(b,[P[i],P[j],c],key,tuple(n_))
    else: topq(b,x-w/2+frame,x+w/2-frame,y-d/2+frame,y+d/2-frame,zf,key)
    for (p,q,nn) in (((x-w/2+frame,y-d/2+frame),(x+w/2-frame,y-d/2+frame),(0,1,0)),((x+w/2-frame,y+d/2-frame),(x-w/2+frame,y+d/2-frame),(0,-1,0))):
        _q(b,[(p[0],p[1],zf),(q[0],q[1],zf),(q[0],q[1],z+0.012),(p[0],p[1],z+0.012)],'ss_dk',nn)
def sneeze(b, x0, x1, y, z, h=0.42, d=0.30, hi=False):
    """sneeze guard: chrome posts + glass top shelf + slanted front glass edge band (frame only, food stays visible)"""
    for x in (x0,x1):
        b.tube((x,y,z),(x,y,z+h),0.012,0.012,sg(hi,6,10),'chrome',cap0=False,cap1=True)
        b.tube((x,y,z+h-0.02),(x,y-d,z+h-0.12),0.010,0.010,sg(hi,5,8),'chrome',cap0=False,cap1=True)
    b.box(((x0+x1)/2,y-0.02,z+h),(x1-x0+0.04,0.22,0.012),'glass',ch=0)
    b.tube((x0,y-d,z+h-0.12),(x1,y-d,z+h-0.12),0.008,0.008,sg(hi,5,8),'chrome',cap0=True,cap1=True)
def torus(b, c, R, r, top, bot, hi, n=None):
    m=sg(hi,2,8); n=n or sg(hi,6,16)
    up=[(R+r*math.cos(math.pi*i/m),r*math.sin(math.pi*i/m)) for i in range(m+1)]
    if not hi: up=[(R+r,-r*0.5),(R+r*0.25,r),(R-r,-r*0.5)]
    b.lathe(up,n,top,c=c,cap_top=False,cap_bot=False)
    if hi:
        dn=[(R+r*math.cos(math.pi+math.pi*i/m),r*math.sin(math.pi+math.pi*i/m)) for i in range(m+1)]
        b.lathe(dn,n,bot,c=c,cap_top=False,cap_bot=False)
def flat_prism(b, pts, z0, z1, key, side=None, top=None):
    """outline in XY extruded between z0 and z1"""
    T=[V(x,y,z1) for x,y in pts]; B=[V(x,y,z0) for x,y in pts]
    _q(b,T,top or key,(0,0,1)); _q(b,B[::-1],side or key,(0,0,-1))
    for i in range(len(pts)):
        j=(i+1)%len(pts); d=T[j]-T[i]; _q(b,[B[i],B[j],T[j],T[i]],side or key,(d.y,-d.x,0))
def text(b, hi, s, size, origin, key='label', xdir=(1,0,0), ydir=(0,0,1)):
    if hi:
        import pg as _pg
        _pg.add_text(b,s,size,origin,xdir,ydir,0.0015,key)

# ------------------------------------------------------------------ condiment_station
def condiment_station(b, hi=False):
    """cafe milk & sugar station: walnut cabinet with a quartz-look top, three airpots (whole, skim, oat) on a
    drip tray, sugar caddy with coloured sachets, cup-lid organiser, napkin box, stir-stick cup, a waste
    opening with a brass flap in the front panel."""
    L,D,H=1.00,0.50,0.90
    counter(b,L,D,H,'walnut','paint_cream')
    frontq(b,-0.30,0.0,-D/2-0.001,0.45,0.62,'kick_blk')                       # waste opening
    b.box((-0.15,-D/2-0.004,0.60),(0.30,0.008,0.02),'brass',ch=0)
    for x in (-0.48+0.25,0.30):                                                # door panel grooves
        frontq(b,x-0.002,x+0.002,-D/2-0.0008,0.14,0.80,'walnut_dk')
    b.box((-0.25,0.05,H),(0.50,0.24,0.012),'ss_dk',ch=0)                      # drip tray
    for i,(x,bd) in enumerate(((-0.40,'paint_black'),(-0.25,'paint_navy'),(-0.10,'grinder_red'))):
        airpot(b,x,0.06,H+0.012,hi,bd)
    # sugar caddy
    b.box((0.12,-0.08,H),(0.14,0.09,0.06),'ss')
    for i,k in enumerate(('sugar_pk','sugar_bl','sugar_yl','kraft')):
        b.box((0.075+i*0.03,-0.08,H+0.04),(0.024,0.075,0.04),k,ch=0,skip=('bottom',))
    # lid organiser: three stacked lid columns
    b.box((0.33,0.08,H),(0.26,0.12,0.03),'plastic_black')
    for i in range(3): b.tube((0.25+i*0.08,0.08,H+0.03),(0.25+i*0.08,0.08,H+0.12),0.036,0.036,sg(hi,8,12),'cup_wht' if i!=1 else 'plastic_black',cap0=False,cap1=True)
    napkin_box(b,0.38,-0.12,H,hi)
    b.tube((0.22,-0.14,H),(0.22,-0.14,H+0.11),0.03,0.034,sg(hi,8,12),'ss',cap0=False,cap1=False)
    for k in range(5 if hi else 3):
        a=k*1.25; b.tube((0.22+0.012*math.cos(a),-0.14+0.012*math.sin(a),H+0.02),(0.22+0.02*math.cos(a),-0.14+0.02*math.sin(a),H+0.17),0.0025,0.0025,3,'oak',cap0=False,cap1=False)
    b.box((L/2-0.10,-D/2-0.0035,0.80),(0.10,0.002,0.03),'badge',ch=0)
    b.cbox((0,0,0),(L+0.02,D+0.02,H+0.37))

# ------------------------------------------------------------------ coffee_grinder_retail_shelf
def bag(b, x, y, z, w, d, h, key, hi, lab=True):
    """stand-up coffee bag: body + folded top crimp + front label"""
    b.box((x,y,z),(w,d,h),key,ch=0 if not hi else None)
    b.box((x,y,z+h),(w*0.98,d*0.35,0.03),key,ch=0,skip=('bottom',))
    if lab: frontq(b,x-w*0.36,x+w*0.36,y-d/2-0.0008,z+h*0.25,z+h*0.70,'label')
def coffee_grinder_retail_shelf(b, hi=False):
    """roaster retail wall: oak open shelving (three shelves) stocked with kraft and black coffee bags with
    printed labels, a red commercial bulk grinder with a bean hopper on the lower counter, scoop and bean bin."""
    W,D,H=1.20,0.40,1.80
    for sx in (-1,1): b.box((sx*(W/2-0.015),0,0),(0.03,D,H),'oak')
    b.box((0,D/2-0.01,0),(W,0.02,H),'paint_black')
    b.box((0,0,0),(W-0.06,D,0.86),'oak'); b.box((0,0,0.86),(W,D+0.02,0.03),'walnut')
    for x in (-0.29,0.29): frontq(b,x-0.25,x+0.25,-D/2-0.0008,0.10,0.78,'walnut_dk')       # cupboard doors
    R=random.Random(11)
    for k,z in enumerate((1.20,1.52)):
        b.box((0,0.02,z-0.025),(W-0.06,D-0.04,0.025),'oak')
        for i in range(6):
            x=-W/2+0.12+i*0.19; key=('kraft','paint_black','kraft','grinder_red','kraft','paint_black')[(i+k)%6]
            bag(b,x,-0.02,z,0.13,0.08,0.20,key,hi)
            if hi or i%2==0: bag(b,x,0.08,z,0.13,0.08,0.20,key,hi,lab=False)
    # counter stock: low bags + grinder
    for i in range(3): bag(b,-0.45+i*0.15,-0.03,0.89,0.12,0.08,0.16,('kraft','paint_black','kraft')[i],hi)
    gx=0.30; z=0.89
    b.box((gx,0.0,z+0.0),(0.001,0.001,0.001),'ss',ch=0) if False else None
    b.box((gx,0.0,z),(0.24,0.28,0.06),'grinder_red')                                       # base
    b.box((gx,0.06,z+0.06),(0.20,0.16,0.42),'grinder_red')                                  # column
    b.box((gx,-0.06,z+0.06),(0.16,0.08,0.03),'ss_dk')                                       # bag ledge
    b.box((gx,-0.025,z+0.16),(0.07,0.05,0.10),'ss')                                         # spout
    frontq(b,gx-0.06,gx+0.06,-0.0205,z+0.32,z+0.42,'label')
    b.lathe([(0.04,0.0),(0.13,0.22),(0.13,0.26)],sg(hi,8,14),'glass',c=(gx,0.06,z+0.48),cap_top=False,cap_bot=True)
    b.lathe([(0.03,0.0),(0.11,0.17)],sg(hi,8,14),'coffee_bean',c=(gx,0.06,z+0.485),cap_top=True,cap_bot=False)
    b.box((W/2-0.12,-D/2-0.004,0.03),(0.09,0.002,0.03),'badge',ch=0)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ salsa_bar
def salsa_bar(b, hi=False):
    """taqueria salsa bar: stainless counter with a red tiled front, six salsa crocks bedded in crushed ice
    (roja, verde, pico, crema, pickled onion, chile de arbol), lime-wedge bowl, ramekin stacks, ladles, sneeze guard."""
    L,D,H=1.20,0.60,0.90
    b.box((0,0.03,0),(L-0.06,D-0.06,0.10),'kick_blk',skip=('bottom',))
    b.box((0,0,0.10),(L,D,H-0.13),'ss')
    for i in range(8):                                                                    # tile courses (front)
        for j in range(4):
            x0=-L/2+0.02+i*(L-0.04)/8; z0=0.14+j*0.16
            frontq(b,x0+0.004,x0+(L-0.04)/8-0.004,-D/2-0.0008,z0+0.004,z0+0.152,'red_lam' if (i+j)%2 else 'grinder_red')
    b.box((0,0,H-0.03),(L+0.02,D+0.02,0.03),'ss')
    # ice well
    topq(b,-0.50,0.50,-0.20,0.14,H+0.0005,'ice')
    R=random.Random(4)
    for k in range(sg(hi,10,30)):                                                       # ice lumps
        x=R.uniform(-0.48,0.48); y=R.uniform(-0.18,0.12); s=R.uniform(0.02,0.035)
        b.box((x,y,H),(s,s,s*0.6),'ice2' if k%2 else 'ice',rz=R.uniform(0,3),ch=0,skip=('bottom',))
    keys=['salsa_r','salsa_g','pico','crema','conch_pink','sauce_r']
    for i,k in enumerate(keys):
        x=-0.42+i*0.168; y=-0.03
        b.lathe([(0.055,0.0),(0.068,0.10),(0.074,0.11)],sg(hi,8,14),'ceramic' if i%2 else 'paint_cream',c=(x,y,H-0.02),cap_top=False,cap_bot=False)
        _q(b,ring_pts((x,y),0.066,sg(hi,8,14),H+0.07),k,(0,0,1))
        b.tube((x+0.03,y,H+0.07),(x+0.06,y+0.05,H+0.20),0.004,0.004,3,'ss',cap0=False,cap1=True)   # ladle handle
    # lime bowl + ramekins at the right end, stacked ramekins left
    b.lathe([(0.05,0.0),(0.10,0.06)],sg(hi,8,14),'paint_white',c=(0.40,0.20,H),cap_top=False,cap_bot=True)
    for k in range(sg(hi,5,9)):
        a=k*2.4; r=0.05*math.sqrt((k+1)/6)
        b.box((0.40+r*math.cos(a),0.20+r*math.sin(a),H+0.045),(0.035,0.02,0.02),'lime',rz=a,ch=0)
    for x in (-0.45,-0.36):
        b.tube((x,0.21,H),(x,0.21,H+0.12),0.03,0.035,sg(hi,6,10),'paint_white',cap0=False,cap1=True)
    sneeze(b,-0.56,0.56,0.24,H,0.42,0.38,hi)
    b.box((L/2-0.08,-D/2-0.0035,0.05),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(L+0.02,D+0.02,H+0.44))

# ------------------------------------------------------------------ tray_return_condiment_station
def tray_return_condiment_station(b, hi=False):
    """fast-food tray return & condiment island: laminate cabinet with two push-flap waste openings ('THANK YOU'
    header), tray shelf on top with stacked brown trays, ketchup / mustard / mayo pumps, napkin & straw dispensers."""
    L,D,H=1.20,0.60,1.00
    counter(b,L,D,H,'red_lam','paint_cream')
    for x in (-0.30,0.30):
        frontq(b,x-0.20,x+0.20,-D/2-0.001,0.62,0.86,'ss')
        frontq(b,x-0.18,x+0.18,-D/2-0.0018,0.64,0.84,'ss_dk')
        b.tube((x-0.17,-D/2-0.012,0.84),(x+0.17,-D/2-0.012,0.84),0.006,0.006,4,'chrome',cap0=True,cap1=True)
    frontq(b,-0.34,0.34,-D/2-0.0012,0.40,0.55,'ty_sign' if not hi else 'paint_cream')
    text(b,hi,'THANK YOU',0.09,(0,-D/2-0.0022,0.475),'ceramic')
    b.box((0,-D/2-0.004,0.12),(L-0.10,0.004,0.02),'ss',ch=0)
    # upper tray shelf (rear) on posts
    for x in (-0.55,0.55): b.box((x,0.20,H),(0.03,0.03,0.40),'ss')
    b.box((0,0.20,H+0.40),(L,0.22,0.02),'ss')
    tray_stack(b,-0.30,0.20,H+0.42,6,'tray_brn',0.42,0.20)
    tray_stack(b,0.25,0.20,H+0.42,4,'tray_brn',0.42,0.20)
    for i,k in enumerate(('ketchup','mustard','mayo','ketchup')):
        pump(b,-0.42+i*0.15,0.05,H,k,hi)
    napkin_box(b,0.25,-0.05,H,hi)
    b.tube((0.45,-0.05,H),(0.45,-0.05,H+0.22),0.05,0.05,sg(hi,8,12),'glass',cap0=False,cap1=False)
    for k in range(sg(hi,4,9)):
        a=k*2.1; b.tube((0.45+0.02*math.cos(a),-0.05+0.02*math.sin(a),H+0.02),(0.45+0.025*math.cos(a),-0.05+0.025*math.sin(a),H+0.26),0.003,0.003,3,'sl_0' if k%2 else 'mag_white',cap0=False,cap1=True)
    b.box((L/2-0.10,-D/2-0.0035,0.90),(0.09,0.002,0.03),'badge',ch=0)
    b.cbox((0,0,0),(L+0.02,D+0.02,H+0.44))

# ------------------------------------------------------------------ host_stand
def host_stand(b, hi=False):
    """restaurant host podium: tapered walnut lectern on a black plinth, brass kick band, sloped top with a
    reservation tablet and pen, menu pockets on the front, small brass lamp."""
    W0,W1,D,H=0.56,0.62,0.42,1.12
    b.box((0,0,0),(W0+0.02,D+0.02,0.06),'paint_black')
    b.box((0,-D/2-0.006,0.06),(W0,0.004,0.025),'brass',ch=0)
    P=[(-W0/2,0.06),(W0/2,0.06),(W1/2,H-0.06),(-W1/2,H-0.06)]
    b.prism(P,-D/2,D/2,'walnut')
    for k in range(4 if hi else 3):                                                       # vertical flutes
        x=-0.15+k*(0.30/(3 if hi else 2))
        frontq(b,x-0.006,x+0.006,-D/2-0.0008,0.14,H-0.16,'walnut_dk')
    # sloped top + lip
    zt=H-0.06; t=0.20
    TP=[V(-W1/2-0.02,-D/2-0.03,zt),V(W1/2+0.02,-D/2-0.03,zt),V(W1/2+0.02,D/2+0.01,zt+0.10),V(-W1/2-0.02,D/2+0.01,zt+0.10)]
    _q(b,TP,'walnut',(0,-0.45,0.9))
    _q(b,[TP[1],TP[0],V(-W1/2-0.02,-D/2-0.03,zt-0.03),V(W1/2+0.02,-D/2-0.03,zt-0.03)],'walnut',(0,-1,0))
    _q(b,[TP[2],TP[3],V(-W1/2-0.02,D/2+0.01,zt-0.03),V(W1/2+0.02,D/2+0.01,zt-0.03)],'walnut',(0,1,0))
    for sx in (-1,1): _q(b,[V(sx*(W1/2+0.02),-D/2-0.03,zt-0.03),V(sx*(W1/2+0.02),D/2+0.01,zt-0.03),V(sx*(W1/2+0.02),D/2+0.01,zt+0.10),V(sx*(W1/2+0.02),-D/2-0.03,zt)][::(1 if sx>0 else -1)],'walnut',(sx,0,0))
    nv=V(0,-0.45,0.9).normalized(); al=(TP[3]-TP[0]).normalized()
    def P2(u,v,w): return V(u,TP[0].y,TP[0].z)+al*v+nv*w
    _q(b,[P2(-0.17,0.08,0.004),P2(0.17,0.08,0.004),P2(0.17,0.34,0.004),P2(-0.17,0.34,0.004)],'tv_blk',tuple(nv))   # tablet
    _q(b,[P2(-0.155,0.095,0.0048),P2(0.155,0.095,0.0048),P2(0.155,0.325,0.0048),P2(-0.155,0.325,0.0048)],'screen',tuple(nv))
    pc=P2(0.24,0.20,0.008); b.tube(pc-V(0,0.06,0),pc+V(0,0.07,0.02),0.004,0.004,4,'brass',cap0=True,cap1=True)
    # menu pockets on the front
    for x in (-0.13,0.13):
        frontq(b,x-0.11,x+0.11,-D/2-0.02,0.62,0.72,'glass')
        frontq(b,x-0.10,x+0.10,-D/2-0.012,0.64,0.86,'paint_navy')
    b.tube((W1/2-0.06,D/2-0.04,zt+0.09),(W1/2-0.06,D/2-0.04,zt+0.36),0.006,0.006,4,'brass',cap0=False,cap1=False)
    b.lathe([(0.065,0.0),(0.06,0.012),(0.012,0.06)],sg(hi,8,12),'brass',c=(W1/2-0.06,D/2-0.04,zt+0.30),cap_top=False,cap_bot=False)
    _q(b,ring_pts((W1/2-0.06,D/2-0.04),0.058,sg(hi,8,12),zt+0.012+0.30)[::-1],'lemon',(0,0,-1))
    b.box((0,-D/2-0.0035,0.30),(0.09,0.002,0.03),'badge',ch=0)
    b.cbox((0,0,0),(W1+0.04,D+0.04,H+0.04))

# ------------------------------------------------------------------ bread_basket_rack
def loaf(b, c, L, r, key, score, hi, rz=0.0):
    """loaf lying along its length: squashed lathe on its side + scoring slashes on top"""
    x,y,z=c; n=sg(hi,5,12)
    n0=nfaces(b)
    prof=[(0.0,-L/2),(r*0.7,-L/2+0.01),(r,-L/2+r*0.8),(r,L/2-r*0.8),(r*0.7,L/2-0.01),(0.0,L/2)] if hi else [(0.0,-L/2),(r*0.9,-L/2+r*0.6),(r*0.9,L/2-r*0.6),(0.0,L/2)]
    b.lathe(prof,n,key,c=(0,0,0),cap_top=False,cap_bot=False)
    ca,sa=math.cos(rz),math.sin(rz)
    xform(b,n0,lambda co: V(x+(co.z)*ca-(co.x)*sa,y+(co.z)*sa+(co.x)*ca,z+r*0.75+co.y*0.75))
    if score:
        for k in range(3 if L>0.3 else 2):
            u=-L/3+k*L/(3 if L>0.3 else 2.2)
            p=V(x+u*ca,y+u*sa,z+r*1.5+0.002); d=V(ca,sa,0)*0.035; s_=V(-sa,ca,0)*0.008
            _q(b,[p-d-s_,p+d-s_,p+d+s_,p-d+s_],score,(0,0,1))
def boule(b, c, r, key, score, hi):
    n=sg(hi,6,12); x,y,z=c
    b.lathe([(r,0.0),(r*1.02,r*0.25),(r*0.85,r*0.6),(r*0.45,r*0.82),(0.0,r*0.88)] if hi else [(r,0.0),(r*0.92,r*0.45),(r*0.5,r*0.8),(0.0,r*0.88)],n,key,c=c,cap_top=False,cap_bot=False)
    _q(b,[(x-r*0.45,y-0.006,z+r*0.86),(x+r*0.45,y-0.006,z+r*0.86),(x+r*0.45,y+0.006,z+r*0.86),(x-r*0.45,y+0.006,z+r*0.86)],score,(0,0,1))
def basket(b, x, y, z, w, d, h, rx, hi):
    """woven basket tilted forward by rx: wicker walls + weave bands"""
    n0=nfaces(b)
    b.box((0,0,0),(w,d,0.012),'wicker',ch=0)
    for (a,bb,nn) in (((-w/2,-d/2),(w/2,-d/2),(0,-1,0)),((w/2,d/2),(-w/2,d/2),(0,1,0)),((w/2,-d/2),(w/2,d/2),(1,0,0)),((-w/2,d/2),(-w/2,-d/2),(-1,0,0))):
        _q(b,[(a[0],a[1],0),(bb[0],bb[1],0),(bb[0],bb[1],h),(a[0],a[1],h)],'wicker',nn)
        _q(b,[(bb[0],bb[1],0),(a[0],a[1],0),(a[0],a[1],h),(bb[0],bb[1],h)],'bread_dk',tuple(-v for v in nn))
        o=V(*nn)*0.0008
        _q(b,[V(a[0],a[1],h-0.025)+o,V(bb[0],bb[1],h-0.025)+o,V(bb[0],bb[1],h-0.005)+o,V(a[0],a[1],h-0.005)+o],'walnut',nn)
    import mathutils
    M=mathutils.Matrix.Rotation(rx,3,'X')
    xform(b,n0,lambda co: M@co+V(x,y,z))
def bread_basket_rack(b, hi=False):
    """bakery bread wall rack: rustic oak frame, three tiers of forward-tilted wicker baskets holding baguettes,
    batards and boules, a chalk price board on top."""
    W,D,H=1.20,0.50,1.70
    for sx in (-1,1):
        for sy in (-1,1): b.box((sx*(W/2-0.03),sy*(D/2-0.03),0),(0.05,0.05,H),'oak')
    for z in (0.12,):
        b.box((0,0,z),(W,D,0.02),'oak')
    R=random.Random(7)
    tiers=((0.22,'bag'),(0.70,'bat'),(1.18,'boule'))
    for k,(z,kind) in enumerate(tiers):
        for sy in (-1,1): b.box((0,sy*(D/2-0.03),z-0.04),(W-0.06,0.03,0.04),'oak')
        for i,x in enumerate((-0.28,0.28)):
            basket(b,x,0.0,z,0.52,0.38,0.12,0.22,hi)
            cz=z+0.014
            if kind=='bag':
                for j in range(3 if not hi else 4):
                    yy=-0.02+0.02*j; loaf(b,(x-0.18+j*0.12,yy,cz+yy*0.22),0.46,0.032,'bread','crust_lt',hi,rz=math.pi/2+R.uniform(-0.25,0.25))
            elif kind=='bat':
                for j in range(3): yy=-0.10+j*0.10; loaf(b,(x,yy,cz+yy*0.22+0.01*j),0.32,0.055,'bread' if j%2 else 'bread_dk','crust_lt',hi,rz=R.uniform(-0.15,0.15))
            else:
                for j in range(3): yy=-0.04+0.06*(j%2); boule(b,(x-0.15+j*0.15,yy,cz+yy*0.22),0.075,'bread_dk' if j==1 else 'bread','crust_lt',hi)
    b.box((0,0.0,H),(W,D,0.03),'oak')
    b.box((0,0.20,H+0.03),(0.60,0.03,0.28),'walnut')
    frontq(b,-0.27,0.27,0.1848,H+0.05,H+0.29,'bread_sign' if not hi else 'paint_black')
    text(b,hi,'FRESH BREAD',0.075,(0,0.1838,H+0.17),'label')
    b.box((W/2-0.10,-D/2+0.02,0.06),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(W,D,H+0.31))

# ------------------------------------------------------------------ high_chair
def high_chair(b, hi=False):
    """restaurant wooden high chair: splayed beech legs with stretchers, moulded seat, bent backrest slats,
    wrap-around arm bar, crotch post and a lap strap."""
    Wf,Df=0.52,0.56; Wt,Dt=0.36,0.36; Hs=0.56
    pts=[]
    for sx in (-1,1):
        for sy in (-1,1):
            p0=V(sx*Wf/2,sy*Df/2,0.0); p1=V(sx*Wt/2,sy*Dt/2,Hs)
            b.tube(p0,p1,0.02,0.018,sg(hi,6,10),'oak',cap0=True,cap1=False); pts.append((p0,p1))
    for z in (0.18,0.36):                                                                   # stretchers
        f=z/Hs; w=Wf/2+(Wt/2-Wf/2)*f; d=Df/2+(Dt/2-Df/2)*f
        for (a,c) in (((-w,-d),(w,-d)),((-w,d),(w,d)),((-w,-d),(-w,d)),((w,-d),(w,d))):
            if z==0.18 or a[1]==c[1]: b.tube(V(a[0],a[1],z),V(c[0],c[1],z),0.011,0.011,sg(hi,5,8),'oak',cap0=False,cap1=False)
    b.box((0,0,Hs),(Wt+0.04,Dt+0.02,0.03),'oak')
    b.box((0,0,Hs+0.03),(Wt-0.04,Dt-0.06,0.004),'walnut',ch=0)
    # back posts + slats
    for sx in (-1,1): b.tube(V(sx*Wt/2,Dt/2,Hs),V(sx*(Wt/2+0.01),Dt/2+0.06,Hs+0.46),0.017,0.015,sg(hi,6,10),'oak',cap0=False,cap1=True)
    for z,h in ((Hs+0.34,0.09),(Hs+0.18,0.05)):
        b.box((0,Dt/2+0.06*(z-Hs)/0.46,z),(Wt+0.01,0.018,h),'oak',rx=-0.13)
    # arm bar wraps the front
    zb=Hs+0.20
    P=[V(-Wt/2-0.01,Dt/2+0.03,zb),V(-Wt/2-0.02,-Dt/2+0.02,zb),V(-0.10,-Dt/2-0.03,zb),V(0.10,-Dt/2-0.03,zb),V(Wt/2+0.02,-Dt/2+0.02,zb),V(Wt/2+0.01,Dt/2+0.03,zb)]
    b.sweep(P,0.016,sg(hi,5,8),'oak',cap0=True,cap1=True)
    for sx in (-1,1): b.tube(V(sx*Wt/2,-Dt/2+0.03,Hs+0.03),V(sx*(Wt/2+0.015),-Dt/2+0.03,zb),0.012,0.012,sg(hi,5,8),'oak',cap0=False,cap1=False)
    b.tube(V(0,-Dt/2+0.06,Hs+0.03),V(0,-Dt/2-0.02,zb),0.013,0.013,sg(hi,5,8),'oak',cap0=False,cap1=False)   # crotch post
    b.sweep([V(-Wt/2+0.02,Dt/2-0.02,Hs+0.032),V(-0.06,-0.02,Hs+0.05),V(0.06,-0.02,Hs+0.05),V(Wt/2-0.02,Dt/2-0.02,Hs+0.032)],0.006,3,'paint_navy',cap0=False,cap1=False)
    b.box((0,-0.02,Hs+0.04),(0.05,0.012,0.03),'plastic_black',ch=0)
    b.box((0,Dt/2+0.02,0.30),(0.06,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(Wf,Df+0.04,Hs+0.48))

# ------------------------------------------------------------------ cone_and_topping_station
def cone_and_topping_station(b, hi=False):
    """ice-cream parlour topping counter: white cabinet with a pastel stripe, eight topping bins (sprinkles,
    nuts, cookie, gummies...) under a glass shelf, waffle-cone sleeves in a chrome rack, three sauce pumps."""
    L,D,H=1.20,0.60,0.92
    counter(b,L,D,H,'paint_white','paint_cream')
    for k,(z,key) in enumerate(((0.55,'glaze_pink'),(0.62,'sugar_bl'),(0.69,'sugar_yl'))):
        frontq(b,-L/2,L/2,-D/2-0.0008,z,z+0.05,key)
    keys=['sl_0','glaze_choc','sl_2','dough','sl_4','glaze_wht','sl_1','lime']
    for i,k in enumerate(keys):
        x=-0.50+(i%4)*0.14; y=-0.18+(i//4)*0.14
        b.box((x,y,H),(0.13,0.13,0.06),'ss',skip=('bottom','top'),ch=0)
        topq(b,x-0.064,x+0.064,y-0.064,y+0.064,H+0.045,k)
        if hi:
            R=random.Random(i)
            for j in range(12): b.box((x+R.uniform(-0.05,0.05),y+R.uniform(-0.05,0.05),H+0.045),(0.008,0.004,0.003),SL[(i+j)%8],rz=R.uniform(0,3),ch=0)
    sneeze(b,-0.58,-0.02,0.08,H,0.40,0.30,hi)
    # cone sleeves in a chrome rack
    b.box((0.25,0.10,H),(0.24,0.18,0.02),'chrome')
    for i in range(3):
        x=0.18+i*0.07
        for zz in (H+0.10,H+0.26): b.tube((x,0.10,zz),(x,0.10,zz+0.012),0.037,0.037,sg(hi,6,10),'chrome',cap0=False,cap1=False)
        for j in range(3 if not hi else 4):
            zz=H+0.04+j*0.065
            b.tube((x,0.10,zz),(x,0.10,zz+0.10),0.008,0.032,sg(hi,6,10),'cone',cap0=False,cap1=False)
    for i,k in enumerate(('glaze_choc','sauce_r','cheese')):
        pump(b,0.45,-0.20+i*0.13,H,k,hi,h=0.16,r=0.04)
    b.box((L/2-0.10,-D/2-0.0035,0.82),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(L+0.02,D+0.02,H+0.42))

# ------------------------------------------------------------------ donut_display_rack
def donut(b, c, glaze, hi, R=0.042, r=0.020, spr=None):
    x,y,z=c
    torus(b,(x,y,z+r),R,r,glaze,'dough',hi)
    if spr and hi:
        for k in range(8):
            a=k*0.785; b.box((x+R*math.cos(a),y+R*math.sin(a),z+2*r-0.001),(0.008,0.003,0.003),SL[k%8],rz=a,ch=0)
def donut_display_rack(b, hi=False):
    """donut shop display: black-framed glass-front case on a counter base, four slanted tiers of trays with
    glazed, chocolate, pink-sprinkle and powdered donuts, paper doilies, price tags along the tray edges."""
    W,D,H=1.20,0.62,1.45; zb=0.85
    counter(b,W,D,zb,'paint_black','ss',kick=True)
    for sx in (-1,1): b.box((sx*(W/2-0.015),0,zb),(0.03,D,H-zb),'frz_wht')
    b.box((0,D/2-0.01,zb),(W,0.02,H-zb),'paint_cream')
    b.box((0,0,H),(W,D,0.04),'frz_wht')
    frontq(b,-W/2+0.03,W/2-0.03,-D/2+0.001,zb+0.01,H-0.005,'glass') if False else None
    b.box((0,-D/2+0.01,zb),(W-0.06,0.02,0.04),'paint_black')
    b.box((0,-D/2+0.01,H-0.05),(W-0.06,0.02,0.05),'paint_black')
    glz=[('glaze_wht',False),('glaze_choc',True),('glaze_pink',True),('crust_lt',False),('glaze_choc',False),('cheese',False)]
    for k in range(4):
        z=zb+0.05+k*0.13; y0=-0.20+k*0.08
        b.box((0,y0+0.10,z),(W-0.08,0.22,0.012),'paint_cream',rx=0.12)
        frontq(b,-W/2+0.04,W/2-0.04,y0-0.012,z,z+0.03,'mag_white')
        for i in range(6):
            x=-W/2+0.12+i*0.192; g,sp=glz[(i+k)%6]
            for j in (range(2 if k<3 else 1) if hi else (1,)):
                donut(b,(x+(j*0.03-0.015 if hi else j*0.02),y0+0.05+j*0.10,z+0.012+j*0.012),g,hi,spr=sp)
            frontq(b,x-0.025,x+0.025,y0-0.0128,z+0.004,z+0.026,'lotto_yel')
    b.box((0,-D/2+0.02,H+0.04),(0.60,0.02,0.10),'paint_black')
    frontq(b,-0.27,0.27,-D/2+0.0095,H+0.05,H+0.13,'donut_sign' if not hi else 'paint_cream')
    text(b,hi,'DONUTS',0.075,(0,-D/2+0.0085,H+0.09),'ceramic')
    topq(b,-W/2+0.04,W/2-0.04,-D/2+0.04,D/2-0.04,H-0.0005,'lemon') if False else _q(b,[(-W/2+0.04,-D/2+0.04,H-0.001),(W/2-0.04,-D/2+0.04,H-0.001),(W/2-0.04,D/2-0.04,H-0.001),(-W/2+0.04,D/2-0.04,H-0.001)][::-1],'mag_white',(0,0,-1))
    b.box((W/2-0.10,-D/2-0.0035,0.30),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(W+0.02,D+0.02,H+0.14))

# ------------------------------------------------------------------ coffee_station_roller_grill
def coffee_station_roller_grill(b, hi=False):
    """c-store hot counter: laminate base cabinet; left a stainless roller grill with eight chrome rollers and
    hot dogs under a sneeze guard, bun warmer drawer below; right two black coffee brewers with glass pots on
    warmers, cup stacks and a lid rack; COFFEE header card."""
    L,D,H=1.40,0.65,0.92
    counter(b,L,D,H,'lam_wd','paint_cream')
    # roller grill
    gx=-0.36; gw,gd=0.60,0.42
    b.box((gx,0.0,H),(gw,gd,0.12),'ss')
    b.box((gx,-gd/2-0.005,H+0.02),(gw-0.04,0.01,0.06),'tv_blk',ch=0)                     # control strip
    for k in range(2): b.tube((gx-0.20+k*0.40,-gd/2-0.013,H+0.05),(gx-0.20+k*0.40,-gd/2-0.025,H+0.05),0.012,0.012,6,'steel',cap0=False,cap1=True)
    topq(b,gx-gw/2+0.02,gx+gw/2-0.02,-gd/2+0.02,gd/2-0.02,H+0.1205,'ss_dk')
    R=random.Random(5)
    for i in range(8):
        y=-gd/2+0.05+i*(gd-0.10)/7
        b.tube((gx-gw/2+0.04,y,H+0.13),(gx+gw/2-0.04,y,H+0.13),0.011,0.011,sg(hi,5,8),'chrome',cap0=False,cap1=False)
    for i in range(7):
        y=-gd/2+0.075+i*(gd-0.10)/7; x0=gx+R.uniform(-0.06,0.06)
        for j in range(3 if i%2 else 2):
            xc=x0-0.16+j*0.16
            b.tube((xc-0.065,y,H+0.155),(xc+0.065,y,H+0.155),0.012,0.012,sg(hi,5,8),'hotdog',cap0=True,cap1=True)
    sneeze(b,gx-gw/2,gx+gw/2,gd/2-0.02,H+0.12,0.26,0.30,hi)
    frontq(b,gx-0.25,gx+0.25,-D/2-0.0008,0.55,0.80,'ss'); b.box((gx,-D/2-0.012,0.74),(0.18,0.02,0.02),'chrome',ch=0)   # bun drawer
    # coffee brewers
    for i,x in enumerate((0.18,0.48)):
        b.box((x,0.10,H),(0.24,0.36,0.04),'tv_blk')
        b.box((x,0.20,H+0.04),(0.24,0.16,0.50),'tv_blk')
        b.box((x,0.03,H+0.40),(0.24,0.30,0.14),'tv_blk')
        frontq(b,x-0.09,x+0.09,-0.1205,H+0.43,H+0.51,'ss')
        b.box((x,0.00,H+0.36),(0.14,0.14,0.04),'ss',ch=0)                                 # brew basket
        b.lathe([(0.03,0.0),(0.075,0.04),(0.078,0.10),(0.05,0.16),(0.045,0.19)],sg(hi,8,14),'coffee_dk',c=(x,0.0,H+0.045),cap_top=True,cap_bot=False)
        b.box((x,-0.06,H+0.16),(0.02,0.08,0.03),'tv_blk',ch=0)                             # pot handle
        b.box((x,-0.0805,H+0.045),(0.12,0.002,0.02),'grinder_red' if i else 'tv_grey',ch=0)
    for i in range(3):                                                                    # cup stacks + lid rack
        x=0.12+i*0.11; b.tube((x,-0.22,H),(x,-0.22,H+0.22),0.035,0.045,sg(hi,8,12),'cup_wht',cap0=False,cap1=True)
    b.box((0.55,-0.20,H),(0.14,0.12,0.12),'plastic_black')
    b.box((0.33,0.30,H+0.54),(0.62,0.02,0.16),'grinder_red')
    frontq(b,0.06,0.60,0.2895,H+0.56,H+0.68,'cof_sign' if not hi else 'paint_cream')
    text(b,hi,'COFFEE',0.09,(0.33,0.2885,H+0.62),'paint_black')
    b.box((L/2-0.10,-D/2-0.0035,0.05),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(L+0.02,D+0.02,H+0.70))

# ------------------------------------------------------------------ ice_merchandiser
def ice_merchandiser(b, hi=False):
    """bagged-ice merchandiser (indoor): white insulated chest-height freezer, two hinged doors with chrome
    handles and gaskets, big blue ICE panel with snowflake band, kick louvre, condensing unit grille."""
    L,D,H=1.30,0.78,1.40
    b.box((0,0.02,0),(L-0.04,D-0.06,0.10),'kick_blk',skip=('bottom',))
    for i in range(6 if hi else 4): frontq(b,-L/2+0.10,L/2-0.10,-D/2+0.007-0.0008,0.02+i*(0.08/(6 if hi else 4)),0.03+i*(0.08/(6 if hi else 4)),'steel_dk')
    b.box((0,0,0.10),(L,D,H-0.10),'frz_wht')
    b.box((0,0,H),(L+0.02,D+0.02,0.04),'frz_wht')
    for x in (-L/4,L/4):
        frontq(b,x-L/4+0.02,x+L/4-0.02,-D/2-0.006,0.16,H-0.06,'frz_wht')
        b.box((x,-D/2-0.003,0.15),(L/2-0.02,0.006,H-0.20),'rubber',skip=('front',),ch=0)
        frontq(b,x-L/4+0.05,x+L/4-0.05,-D/2-0.0068,0.55,1.08,'ice_blue')
        frontq(b,x-L/4+0.05,x+L/4-0.05,-D/2-0.0068,0.50,0.53,'ice_blue')
        hx=x+(L/4-0.06)*(1 if x<0 else -1)
        b.box((hx,-D/2-0.03,0.70),(0.03,0.03,0.30),'chrome')
    frontq(b,-L/2+0.06,L/2-0.06,-D/2-0.0072,1.12,1.30,'paint_navy')
    frontq(b,-0.22,0.22,-D/2-0.0078,1.13,1.29,'ice_sign' if not hi else 'paint_navy')
    text(b,hi,'ICE',0.15,(0,-D/2-0.0088,1.21),'label')
    for x in (-L/4,L/4):
        frontq(b,x-0.08,x+0.08,-D/2-0.0076,0.62,0.98,'frz_wht') if False else None
    b.box((L/2-0.12,-D/2-0.009,0.16),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(L+0.02,D+0.02,H+0.04))

# ------------------------------------------------------------------ pan_dulce_tray_rack
def concha(b, c, key, hi, r=0.052):
    x,y,z=c; n=sg(hi,6,10)
    b.lathe([(r,0.0),(r*1.02,0.012),(r*0.80,0.035),(r*0.40,0.048),(0.0,0.050)] if hi else [(r*1.02,0.0),(r*0.75,0.038),(0.0,0.050)],n,key,c=c,cap_top=False,cap_bot=False)
    if hi:
        for k in range(3):
            a=k*math.pi/3; d=V(math.cos(a),math.sin(a),0)*r*0.8
            _q(b,[V(x,y,z+0.051)-d-V(0,0,0)+V(-d.y,d.x,0)*0.02,V(x,y,z+0.051)+d+V(-d.y,d.x,0)*0.02,V(x,y,z+0.051)+d-V(-d.y,d.x,0)*0.02,V(x,y,z+0.051)-d-V(-d.y,d.x,0)*0.02],'bread_dk',(0,0,1))
def pan_dulce_tray_rack(b, hi=False):
    """panaderia self-serve rack: tall chrome-framed case with five aluminium sheet trays of conchas (pink,
    yellow, chocolate), cuernos and orejas, acrylic sliding doors pulled open, tray-and-tongs stand on top."""
    W,D,H=0.92,0.66,1.80
    for sx in (-1,1):
        for sy in (-1,1): b.box((sx*(W/2-0.015),sy*(D/2-0.015),0),(0.03,0.03,H),'chrome')
    b.box((0,0,0),(W,D,0.06),'tv_grey'); b.box((0,0,H-0.04),(W,D,0.04),'tv_grey')
    for sx in (-1,1):
        for z in (0.06,H-0.06): b.box((sx*(W/2-0.015),0,z),(0.02,D-0.04,0.02),'chrome')
    b.box((0,D/2-0.01,0.06),(W-0.04,0.02,H-0.10),'paint_cream')
    kinds=['conch_pink','conch_yel','conch_choc','cuerno','oreja']
    for k in range(5):
        z=0.18+k*0.30
        b.box((0,0,z),(W-0.06,D-0.06,0.012),'alum',ch=0)
        topq(b,-W/2+0.05,W/2-0.05,-D/2+0.05,D/2-0.05,z+0.0125,'paint_cream')
        frontq(b,-W/2+0.03,W/2-0.03,-D/2+0.0298,z-0.008,z+0.022,'alum')
        kind=kinds[k]
        for i in range(4):
            for j in range((3 if hi else 2) if kind!='cuerno' else 2):
                x=-W/2+0.13+i*0.22; y=-D/2+0.12+j*((0.20 if hi else 0.24) if kind!='cuerno' else 0.25)
                if kind.startswith('conch'): concha(b,(x,y,z+0.012),kind,hi)
                elif kind=='cuerno': loaf(b,(x,y,z+0.012),0.16,0.035,'bread','crust_lt',hi,rz=0.4)
                else:
                    b.lathe([(0.055,0.0),(0.055,0.015),(0.0,0.02)],sg(hi,6,10),'crust_lt',c=(x,y,z+0.012),cap_top=False,cap_bot=False)
                    if hi: _q(b,[(x-0.04,y-0.004,z+0.033),(x+0.04,y-0.004,z+0.033),(x+0.04,y+0.004,z+0.033),(x-0.04,y+0.004,z+0.033)],'bread',(0,0,1))
        frontq(b,-0.06,0.06,-D/2+0.0296-0.0008,z-0.004,z+0.018,'label')                    # price tag
    # trays & tongs on top
    tray_stack(b,0,-0.02,H,5,'alum',0.40,0.30)
    for sx in (-1,1): b.box((0.05+sx*0.01,-0.02,H+0.11),(0.012,0.25,0.012),'ss',rz=0.15*sx,ch=0)
    b.box((0,-D/2+0.02,H-0.17),(0.50,0.02,0.12),'conch_pink')
    frontq(b,-0.23,0.23,-D/2+0.0095,H-0.16,H-0.06,'pd_sign' if not hi else 'paint_cream')
    text(b,hi,'PAN DULCE',0.06,(0,-D/2+0.0085,H-0.11),'ceramic')
    b.box((W/2-0.09,-D/2+0.018,0.02),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(W,D,H+0.13))

# ------------------------------------------------------------------ deli_slicer_counter
def deli_slicer_counter(b, hi=False):
    """deli prep counter: stainless work table with undershelf, a gravity-feed meat slicer (round blade with
    guard ring, carriage, thickness knob, white enamel body), a ham log and a cheese block, digital scale,
    stacked deli paper and a cutting board."""
    L,D,H=1.20,0.70,0.90
    for sx in (-1,1):
        for sy in (-1,1): b.tube((sx*(L/2-0.04),sy*(D/2-0.04),0),(sx*(L/2-0.04),sy*(D/2-0.04),H-0.04),0.02,0.02,sg(hi,6,10),'ss',cap0=False,cap1=False)
    b.box((0,0,0.20),(L-0.04,D-0.04,0.02),'ss')
    b.box((0,0,H-0.04),(L,D,0.04),'ss')
    b.box((0,D/2-0.01,H),(L,0.02,0.10),'ss')
    for i in range(3): b.box((-0.35+i*0.30,0,0.22),(0.26,0.40,0.12),'kraft' if i!=1 else 'tv_grey',ch=0)
    # slicer
    sx_=-0.20; sy_=0.02
    b.box((sx_,sy_,H),(0.50,0.40,0.05),'frz_wht')
    b.box((sx_+0.10,sy_+0.10,H+0.05),(0.18,0.16,0.20),'frz_wht')                    # motor housing
    bc=V(sx_+0.10,sy_-0.02,H+0.22); n=sg(hi,12,24)
    ring=[bc+V(0.15*math.cos(2*math.pi*i/n),0,0.15*math.sin(2*math.pi*i/n)) for i in range(n)]
    _q(b,ring,'ss',(0,-1,0))
    rg=[bc+V(0.165*math.cos(2*math.pi*i/n),-0.012,0.165*math.sin(2*math.pi*i/n)) for i in range(n)]
    for i in range(n):
        j=(i+1)%n; _q(b,[rg[i],rg[j],rg[j]+V(0,0.03,0),rg[i]+V(0,0.03,0)],'frz_wht',tuple((rg[i]+rg[j])/2-bc-V(0,-0.012,0)))
    _q(b,[bc+V(0.05*math.cos(2*math.pi*i/8),-0.0015,0.05*math.sin(2*math.pi*i/8)) for i in range(8)],'frz_wht',(0,-1,0))   # centre cover
    b.box((sx_-0.12,sy_-0.05,H+0.05),(0.22,0.20,0.03),'ss',rx=0.0)                  # carriage tray
    b.box((sx_-0.12,sy_+0.04,H+0.08),(0.22,0.02,0.10),'ss')                         # fence
    b.tube((sx_-0.20,sy_-0.15,H+0.07),(sx_-0.20,sy_-0.15,H+0.22),0.012,0.012,sg(hi,6,8),'ss',cap0=False,cap1=True)
    b.tube((sx_-0.20,sy_-0.15,H+0.22),(sx_-0.20,sy_-0.15,H+0.26),0.022,0.022,sg(hi,6,10),'plastic_black',cap0=False,cap1=True)
    b.tube((sx_+0.25,sy_-0.12,H+0.03),(sx_+0.28,sy_-0.12,H+0.03),0.035,0.035,sg(hi,8,12),'plastic_black',cap0=False,cap1=True)   # thickness knob
    b.tube((sx_-0.17,sy_-0.01,H+0.105),(sx_-0.03,sy_-0.01,H+0.105),0.045,0.045,sg(hi,8,14),'meat_pink',cap0=True,cap1=True)       # ham on the carriage
    # cheese block + cutting board + scale + paper
    b.box((0.30,0.05,H),(0.36,0.26,0.025),'oak')
    b.box((0.28,0.07,H+0.025),(0.16,0.10,0.09),'cheese')
    b.tube((0.36,-0.04,H+0.025+0.04),(0.42,-0.04,H+0.065),0.04,0.04,sg(hi,8,12),'meat_red',cap0=True,cap1=True)
    b.box((0.40,-0.25,H),(0.26,0.18,0.03),'tv_grey'); b.box((0.40,-0.26,H+0.03),(0.22,0.14,0.005),'ss',ch=0)
    b.box((0.40,-0.18,H+0.03),(0.22,0.03,0.08),'tv_grey',rx=-0.4); frontq(b,0.33,0.47,-0.195,H+0.06,H+0.09,'screen')
    for i in range(4 if hi else 2): b.box((0.10,-0.24,H+i*0.004),(0.20,0.18,0.004),'paint_white' if i%2 else 'label',ch=0,skip=('bottom',))
    b.box((L/2-0.10,-D/2-0.0035,H-0.035),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(L,D,H+0.40))

# ------------------------------------------------------------------ steam_table
def steam_table(b, hi=False):
    """cafeteria / buffet steam table: four-well stainless hot table with a tray slide on the front, hotel pans
    of rice, beans, greens and red sauce with serving spoons, a double sneeze guard, heat-lamp bar, dial knobs."""
    L,D,H=1.60,0.70,0.90
    b.box((0,0.03,0),(L-0.06,D-0.06,0.10),'kick_blk',skip=('bottom',))
    b.box((0,0,0.10),(L,D,H-0.13),'ss')
    for i in range(4):
        x=-L/2+0.20+i*0.40
        frontq(b,x-0.16,x+0.16,-D/2-0.0008,0.20,0.70,'ss_dk')
        b.tube((x,-D/2-0.005,0.78),(x,-D/2-0.025,0.78),0.016,0.016,sg(hi,6,10),'plastic_black',cap0=False,cap1=True)
    b.box((0,0,H-0.03),(L+0.02,D+0.02,0.03),'ss')
    for sx in (-1,1):                                                                     # tray slide
        b.box((sx*(L/2-0.06),-D/2-0.12,0.86),(0.03,0.20,0.03),'ss')
    for k in range(3): b.tube((-L/2,-D/2-0.08-k*0.05,0.90),(L/2,-D/2-0.08-k*0.05,0.90),0.010,0.010,sg(hi,5,8),'ss',cap0=True,cap1=True)
    foods=['rice','beans','greens','sauce_r']
    for i,k in enumerate(foods):
        x=-L/2+0.20+i*0.40
        pan(b,x,-0.05,H,0.34,0.30,k,hi)
        b.tube((x+0.06,-0.08,H-0.005),(x+0.10,0.08,H+0.07),0.006,0.006,3,'ss',cap0=False,cap1=True)
        b.box((x+0.04,-0.12,H-0.004),(0.06,0.08,0.01),'ss',ch=0)
    sneeze(b,-L/2+0.04,L/2-0.04,0.22,H,0.45,0.42,hi)
    b.box((0,0.20,H+0.40),(L-0.10,0.10,0.04),'ss')                                         # heat-lamp bar
    for i in range(4): frontq(b,-L/2+0.08+i*0.40,-L/2+0.32+i*0.40,0.149,H+0.40,H+0.41,'lemon') if False else _q(b,[(-L/2+0.10+i*0.40,0.16,H+0.399),(-L/2+0.30+i*0.40,0.16,H+0.399),(-L/2+0.30+i*0.40,0.24,H+0.399),(-L/2+0.10+i*0.40,0.24,H+0.399)],'lemon',(0,0,-1))
    b.box((L/2-0.10,-D/2-0.0035,0.13),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,-0.07,0),(L+0.02,D+0.16,H+0.47))

# ------------------------------------------------------------------ fish_on_ice_display
def fish(b, c, L, key, belly, hi, rz=0.0):
    """whole fish lying on its side: outline prism (body + tail), lighter belly band, eye, gill line"""
    x,y,z=c; t=L*0.13
    O=[(-0.50,0.0),(-0.40,0.07),(-0.15,0.13),(0.15,0.11),(0.32,0.05),(0.40,0.10),(0.50,0.11),(0.47,0.0),(0.50,-0.11),(0.40,-0.10),(0.32,-0.05),(0.15,-0.09),(-0.15,-0.11),(-0.40,-0.06)]
    ca,sa=math.cos(rz),math.sin(rz)
    P=[(x+(px*ca-py*sa)*L,y+(px*sa+py*ca)*L) for px,py in O]
    body=[P[i] for i in (0,1,2,3,4,10,11,12,13)]; tail=[P[i] for i in (4,5,6,7,8,9,10)]
    flat_prism(b,body,z,z+t,key)
    flat_prism(b,tail,z,z+t*0.4,key)
    def W(px,py,dz=0.0008): return (x+(px*ca-py*sa)*L,y+(px*sa+py*ca)*L,z+t+dz)
    _q(b,[W(-0.40,-0.04),W(0.30,-0.035),W(0.15,-0.08),W(-0.15,-0.10)],belly,(0,0,1))
    _q(b,[W(-0.37,0.025),W(-0.34,0.025),W(-0.34,0.045),W(-0.37,0.045)],'paint_black',(0,0,1))
    _q(b,[W(-0.28,-0.06),W(-0.27,-0.06),W(-0.25,0.08),W(-0.26,0.08)],'fish_dk',(0,0,1))
def fish_on_ice_display(b, hi=False):
    """fishmonger ice display: stainless tub on a tiled base, sloped bed of crushed ice, whole fish (snapper,
    sea bass, mackerel) laid in rows, lemon halves and parsley, stick-in price tags, a front drip rail."""
    L,D,H=1.40,0.80,0.85
    b.box((0,0.03,0),(L-0.06,D-0.06,0.10),'kick_blk',skip=('bottom',))
    b.box((0,0,0.10),(L,D,H-0.30),'paint_white')
    for i in range(10):
        for j in range(3): frontq(b,-L/2+0.01+i*0.138+0.003,-L/2+0.01+(i+1)*0.138-0.003,-D/2-0.0008,0.13+j*0.14+0.003,0.13+(j+1)*0.14-0.003,'ice_blue' if (i+j)%2 else 'paint_white')
    # tub: back wall higher, sloped ice bed
    zf,zb=H-0.18,H+0.02
    b.box((0,0,H-0.20),(L,D,0.02),'ss')
    for sx in (-1,1): _q(b,[(sx*L/2,-D/2,H-0.20),(sx*L/2,D/2,H-0.20),(sx*L/2,D/2,zb+0.08),(sx*L/2,-D/2,zf+0.06)][::(1 if sx>0 else -1)],'ss',(sx,0,0))
    frontq(b,-L/2,L/2,-D/2,H-0.20,zf+0.06,'ss')
    _q(b,[(L/2,D/2,H-0.20),(-L/2,D/2,H-0.20),(-L/2,D/2,zb+0.08),(L/2,D/2,zb+0.08)],'ss',(0,1,0))
    b.tube((-L/2,-D/2-0.015,zf+0.06),(L/2,-D/2-0.015,zf+0.06),0.012,0.012,sg(hi,5,8),'ss',cap0=True,cap1=True)
    nb=sg(hi,6,12)
    for i in range(nb):                                                                  # ice bed (alternating strips)
        y0=-D/2+0.02+i*(D-0.04)/nb; y1=y0+(D-0.04)/nb
        z0=zf+(zb-zf)*(y0+D/2)/D; z1=zf+(zb-zf)*(y1+D/2)/D
        _q(b,[(-L/2+0.02,y0,z0),(L/2-0.02,y0,z0),(L/2-0.02,y1,z1),(-L/2+0.02,y1,z1)],'ice' if i%2 else 'ice2',(0,-(zb-zf)/D,1))
    R=random.Random(12)
    rows=(('fish_red','conch_pink',0.36),('fish_silver','mayo',0.32),('fish_dk','fish_silver',0.26))
    for r,(k,bel,Lf) in enumerate(rows):
        y=-0.25+r*0.24; z=zf+(zb-zf)*(y+D/2)/D
        for i in range(4):
            x=-0.48+i*0.32+R.uniform(-0.02,0.02)
            fish(b,(x,y,z),Lf,k,bel,hi,rz=0.35+R.uniform(-0.08,0.08))
        if r<2:
            for j in range(3):
                xx=-0.32+j*0.32; b.lathe([(0.03,0.0),(0.03,0.012),(0.0,0.014)] if hi else [(0.031,0.0),(0.0,0.014)],sg(hi,6,10),'lemon',c=(xx,y+0.12,z+0.005),cap_top=False,cap_bot=False)
                b.box((xx+0.05,y+0.12,z),(0.05,0.04,0.03),'greens',rz=R.uniform(0,3),ch=0,skip=('bottom',))
        for i in range(2):
            x=-0.40+i*0.70; b.tube((x,y-0.08,z),(x,y-0.08,z+0.10),0.002,0.002,3,'ss',cap0=False,cap1=False)
            b.box((x,y-0.08,z+0.10),(0.06,0.002,0.04),'label',ch=0)
    b.box((L/2-0.10,-D/2-0.0035,0.11),(0.08,0.002,0.025),'badge',ch=0) if False else None
    b.box((L/2-0.10,-D/2-0.0035,0.06),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(L+0.03,D,H+0.12))

# ------------------------------------------------------------------ registry
_C=dict(dir='props/indoor/foodsvc',pdir='indoor_foodsvc',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
W_=dict(cage=0.04,ray=0.12)
PROPS=[
    _p('condiment_station',condiment_station,'medium',1200,**W_),
    _p('coffee_grinder_retail_shelf',coffee_grinder_retail_shelf,'medium',1200,**W_),
    _p('salsa_bar',salsa_bar,'medium',1200,**W_),
    _p('tray_return_condiment_station',tray_return_condiment_station,'medium',1200,side=80,**W_),
    _p('host_stand',host_stand,'small',600,**W_),
    _p('bread_basket_rack',bread_basket_rack,'medium',1200,side=80),
    _p('high_chair',high_chair,'small',600),
    _p('cone_and_topping_station',cone_and_topping_station,'medium',1200,**W_),
    _p('donut_display_rack',donut_display_rack,'medium',1200,side=80,**W_),
    _p('coffee_station_roller_grill',coffee_station_roller_grill,'medium',1200,side=80,**W_),
    _p('ice_merchandiser',ice_merchandiser,'medium',600,side=96),
    _p('pan_dulce_tray_rack',pan_dulce_tray_rack,'large',1500,side=80,**W_),
    _p('deli_slicer_counter',deli_slicer_counter,'medium',1200,**W_),
    _p('steam_table',steam_table,'medium',1200,shift=(0.0,0.105),**W_),
    _p('fish_on_ice_display',fish_on_ice_display,'medium',1200,**W_),
]
INDOOR_LOOK=True
