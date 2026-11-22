"""Indoor retail fixtures (shop-gap batch 2) — original geometry, page I, near+col only. No mid/far.
Shared page-I trims + per-key vertex tint (one material per prop); small unique bake slots only for print
(signs, screens, labels). Wall props are built centred on the origin with the back on +Y (viewer at -Y).
Delete stale _bake/tiles/<name>_* after any geometry change.
"""
import math, random
from mathutils import Vector
from b_inshared import sg, maker_plate, leveler
from b_inleisure import TR as _TR, TINT as _TINT, _q

TR=dict(_TR); TINT=dict(_TINT)
_NEW={
 'basket_red':('ti_plastic',(0.78,0.07,0.06)), 'basket_in':('ti_plastic',(0.55,0.05,0.04)), 'stand_blk':('ti_plastic',(0.10,0.10,0.11)),
 'slat':('ti_laminate',(0.92,0.91,0.88)), 'slot_dk':('ti_paint',(0.16,0.16,0.17)), 'steel_dk':('ti_metal',(0.42,0.43,0.45)),
 'atm_body':('ti_metal',(0.55,0.58,0.62)), 'atm_blue':('ti_paint',(0.08,0.24,0.62)), 'lotto_green':('ti_paint',(0.10,0.52,0.28)),
 'lotto_yel':('ti_paint',(1.10,0.86,0.12)), 'neoprene':('ti_plastic',(0.05,0.05,0.06)), 'np_teal':('ti_fabric',(0.05,0.55,0.60)),
 'np_red':('ti_fabric',(0.80,0.12,0.10)), 'np_blue':('ti_fabric',(0.10,0.28,0.80)), 'np_grey':('ti_fabric',(0.40,0.42,0.45)),
 'galv':('ti_metal',(0.80,0.82,0.84)), 'stand_grn':('ti_paint',(0.14,0.30,0.20)), 'stem':('ti_paint',(0.20,0.42,0.16)),
 'f_pink':('ti_paint',(1.10,0.40,0.62)), 'f_white':('ti_paint',(1.12,1.10,1.02)), 'f_yel':('ti_paint',(1.15,0.90,0.18)),
 'f_red':('ti_paint',(0.85,0.08,0.10)), 'f_purp':('ti_paint',(0.50,0.22,0.72)), 'f_org':('ti_paint',(1.10,0.50,0.10)),
 'cart_red':('ti_plastic',(0.75,0.06,0.05)), 'wire':('ti_metal',(1.05,1.06,1.08)),
 'cg_r':('ti_glass',(0.90,0.12,0.10)), 'cg_w':('ti_glass',(1.10,1.08,1.00)), 'cg_g':('ti_glass',(0.15,0.60,0.25)),
 'cg_y':('ti_glass',(1.10,0.85,0.20)), 'cg_b':('ti_glass',(0.20,0.40,0.95)), 'cg_p':('ti_glass',(0.70,0.25,0.75)), 'wax':('ti_paint',(1.12,1.08,0.96)),
 'herb_g':('ti_fabric',(0.35,0.48,0.20)), 'herb_b':('ti_fabric',(0.45,0.28,0.15)), 'herb_r':('ti_fabric',(0.70,0.18,0.12)),
 'herb_y':('ti_fabric',(0.95,0.75,0.30)), 'herb_p':('ti_fabric',(0.48,0.30,0.55)), 'jar':('ti_glass',(0.95,1.00,1.00)), 'lid_blk':('ti_metal',(0.18,0.18,0.18)),
 'sunburst':('ti_wood',(1.15,0.62,0.22)), 'sb_edge':('ti_wood',(0.25,0.10,0.05)), 'gt_red':('ti_paint',(0.70,0.06,0.07)), 'gt_blk':('ti_paint',(0.06,0.06,0.07)),
 'gt_cream':('ti_paint',(1.05,0.98,0.84)), 'rosewood':('ti_wood',(0.30,0.18,0.12)), 'tv_blk':('ti_plastic',(0.08,0.08,0.09)),
 'tv_grey':('ti_plastic',(0.55,0.55,0.56)), 'tv_beige':('ti_plastic',(0.92,0.86,0.72)), 'phone_wht':('ti_plastic',(1.05,1.05,1.04)),
 'leather_tan':('ti_fabric',(0.75,0.45,0.20)), 'leather_br':('ti_fabric',(0.35,0.20,0.10)), 'sole':('ti_plastic',(0.12,0.10,0.09)),
 'sole_y':('ti_plastic',(0.85,0.62,0.18)), 'lace':('ti_paint',(0.90,0.80,0.55)),
 'ts_0':('ti_fabric',(0.85,0.12,0.10)), 'ts_1':('ti_fabric',(0.12,0.30,0.70)), 'ts_2':('ti_fabric',(1.05,1.05,1.02)), 'ts_3':('ti_fabric',(0.12,0.12,0.13)),
 'ts_4':('ti_fabric',(0.95,0.80,0.20)), 'ts_5':('ti_fabric',(0.20,0.55,0.40)), 'ts_6':('ti_fabric',(0.55,0.62,0.70)), 'ts_7':('ti_fabric',(0.95,0.45,0.55)),
 'denim':('ti_fabric',(0.20,0.30,0.52)), 'denim_lt':('ti_fabric',(0.42,0.55,0.75)), 'knit':('ti_fabric',(0.70,0.62,0.50)),
 'mirror_dome':('ti_glass',(1.15,1.18,1.22)), 'bronze':('ti_brass',(0.55,0.40,0.25)), 'plinth':('ti_paint',(1.08,1.07,1.04)),
 'grip':('ti_paint',(0.08,0.08,0.08)), 'truck':('ti_metal',(0.85,0.86,0.88)), 'wheel_w':('ti_plastic',(1.05,1.02,0.92)),
 'vinyl_red':('ti_fabric',(0.62,0.08,0.08)), 'brannock':('ti_metal',(0.65,0.68,0.72)), 'mag_white':('ti_paint',(1.10,1.10,1.08)),
}
for k,(t,c) in _NEW.items(): TR[k]=(t,(0.875,0.875)); TINT[k]=c
def nfaces(b): return len(b.bm.faces)
def xform(b, n0, fn):
    """apply fn(co)->co once to every vertex of the faces added since face count n0"""
    vs=set()
    for f in list(b.bm.faces)[n0:]:
        for vv in f.verts: vs.add(vv)
    for vv in vs: vv.co=fn(vv.co.copy())
SL=['sl_%d'%i for i in range(8)]; TS=['ts_%d'%i for i in range(8)]

def V(*a): return Vector(a)
def ring_pts(c, r, n, z, ph=0.0): return [V(c[0]+r*math.cos(ph+2*math.pi*i/n), c[1]+r*math.sin(ph+2*math.pi*i/n), z) for i in range(n)]

def slatwall(b, W, H, yb, z0, key='slat', step=0.076, legs=False):
    """slatwall panel: board + dark slot lines (one quad each) at the 76 mm slat pitch"""
    b.box((0,yb-0.009,z0),(W,0.018,H),key)
    k=int(H/step)
    for i in range(1,k):
        z=z0+i*step; _q(b,[(-W/2+0.01,yb-0.0185,z-0.004),(W/2-0.01,yb-0.0185,z-0.004),(W/2-0.01,yb-0.0185,z+0.004),(-W/2+0.01,yb-0.0185,z+0.004)],'slot_dk',(0,-1,0))
    for sx in (-1,1): b.box((sx*(W/2+0.012),yb-0.012,z0-0.004),(0.024,0.024,H+0.008),'alum')

def hook(b, x, z, yb, L=0.20, hi=False):
    if not hi:
        b.box((x,yb-0.018-L/2,z),(0.008,L,0.008),'chrome',ch=0,skip=('back',)); return
    b.box((x,yb-0.024,z-0.02),(0.03,0.01,0.04),'chrome',ch=0)
    b.tube((x,yb-0.028,z),(x,yb-0.028-L,z+0.02),0.0035,0.0035,4,'chrome',cap0=False,cap1=True)

# ------------------------------------------------------------------ shopping_basket_stack
def basket_shell(b, c, top_w, top_d, bot_w, bot_d, h, key, inner=None, slots=True, floor=True):
    x,y,z=c
    T=[V(x-top_w/2,y-top_d/2,z+h),V(x+top_w/2,y-top_d/2,z+h),V(x+top_w/2,y+top_d/2,z+h),V(x-top_w/2,y+top_d/2,z+h)]
    B=[V(x-bot_w/2,y-bot_d/2,z),V(x+bot_w/2,y-bot_d/2,z),V(x+bot_w/2,y+bot_d/2,z),V(x-bot_w/2,y+bot_d/2,z)]
    for i in range(4):
        j=(i+1)%4; out=(T[i]+T[j]+B[i]+B[j])/4-V(x,y,z+h/2); out.z=0
        _q(b,[B[i],B[j],T[j],T[i]],key,out)
        if inner: _q(b,[B[i],B[j],T[j],T[i]],inner,-out)
        if slots:   # vent slots: two rows of dark slots per face
            for r in (0.30,0.52,0.74):
                for s in range(6 if i%2==0 else 4):
                    f0=(s+0.30)/(6 if i%2==0 else 4); f1=f0+0.40/(6 if i%2==0 else 4)
                    def P(f,t): return (B[i]+(B[j]-B[i])*f)*(1-t)+(T[i]+(T[j]-T[i])*f)*t+out.normalized()*0.0008
                    _q(b,[P(f0,r-0.035),P(f1,r-0.035),P(f1,r+0.035),P(f0,r+0.035)],'slot_dk',out)
    if floor: _q(b,B,inner or key,(0,0,1))
    return T
def shopping_basket_stack(b, hi=False):
    """nested stack of six red hand baskets on a low black stand, top basket open with its two chrome handles
    folded out, a 'BASKETS' card on a chrome stalk. 0.43 x 0.30 m baskets."""
    tw,td,bw,bd,h=0.43,0.30,0.36,0.24,0.21
    b.box((0,0,0),(0.46,0.34,0.06),'stand_blk',skip=('bottom',))
    for sx in (-1,1):
        for sy in (-1,1): b.box((sx*0.20,sy*0.14,0),(0.05,0.05,0.012),'rubber',skip=('bottom',))
    n=6; dz=0.035; z0=0.06
    basket_shell(b,(0,0,z0),tw,td,bw,bd,h,'basket_red',slots=True,floor=False)          # outer skin of the stack
    for k in range(1,n):   # each nested basket shows its rolled rim proud of the one below
        z=z0+k*dz; r=z0+h+(k-1)*dz
        b.box((0,0,r-0.004),(tw+0.012,td+0.012,0.012),'basket_red',skip=('bottom',),ch=0)
        b.box((0,0,r-0.008),(tw+0.004,td+0.004,0.004),'basket_in',skip=('top','bottom'),ch=0)
    zt=z0+(n-1)*dz
    basket_shell(b,(0,0,zt+0.004),tw+0.004,td+0.004,bw+0.004,bd+0.004,h,'basket_red',inner='basket_in',slots=True,floor=True)
    b.box((0,0,zt+h),(tw+0.016,td+0.016,0.014),'basket_red',skip=('bottom','top'),ch=0)
    T2=[V(-tw/2-0.008,-td/2-0.008,zt+h+0.014),V(tw/2+0.008,-td/2-0.008,zt+h+0.014),V(tw/2+0.008,td/2+0.008,zt+h+0.014),V(-tw/2-0.008,td/2+0.008,zt+h+0.014)]
    T1=[V(-tw/2,-td/2,zt+h+0.014),V(tw/2,-td/2,zt+h+0.014),V(tw/2,td/2,zt+h+0.014),V(-tw/2,td/2,zt+h+0.014)]
    for i in range(4):
        j=(i+1)%4; _q(b,[T1[i],T1[j],T2[j],T2[i]],'basket_red',(0,0,1)); _q(b,[T1[i]-V(0,0,0.016),T1[j]-V(0,0,0.016),T1[j],T1[i]],'basket_in',(-T1[i].x-T1[j].x,-T1[i].y-T1[j].y,0))
    # handles folded out over the long sides
    for sy in (-1,1):
        P=[V(-0.12,sy*(td/2+0.004),zt+h+0.006),V(-0.10,sy*(td/2+0.08),zt+h+0.02),V(0.10,sy*(td/2+0.08),zt+h+0.02),V(0.12,sy*(td/2+0.004),zt+h+0.006)]
        b.sweep(P,0.005,sg(hi,4,8),'chrome',cap0=False,cap1=False)
        b.tube(V(-0.07,sy*(td/2+0.08),zt+h+0.02),V(0.07,sy*(td/2+0.08),zt+h+0.02),0.011,0.011,sg(hi,6,10),'stand_blk',cap0=True,cap1=True)
    # card on a stalk
    b.tube((0.17,0.13,0.06),(0.17,0.13,0.95),0.006,0.006,4,'chrome',cap0=False,cap1=True)
    b.box((0.17,0.13,0.88),(0.20,0.006,0.12),'label' if hi else 'sign_k',ch=0)
    if hi:
        import pg as _pg
        for sy in (-1,1): _pg.add_text(b,'BASKETS',0.05,(0.17,0.13+sy*0.0045,0.94),(-sy,0,0),(0,0,1),0.0015,'ceramic')
    b.cbox((0,0,0),(tw+0.18,td+0.18,zt+h+0.03))

# ------------------------------------------------------------------ lottery_atm_stand
def lottery_atm_stand(b, hi=False):
    """corner-shop money corner: a free-standing cash machine (brushed steel, blue fascia, screen, keypad, card,
    receipt and cash slots, lit 'ATM' topper) next to a lottery play station (green slanted desk with play-slip
    pockets, two tethered pens, ticket checker)."""
    # ATM (left)
    ax=-0.30; W,D,H=0.52,0.58,1.50
    b.box((ax,0.02,0),(W,D,1.02),'atm_body')
    b.box((ax,0.02,0),(W+0.02,D+0.02,0.06),'steel_dk',skip=('bottom',))
    # upper head: tilted fascia
    b.box((ax,0.10,1.02),(W,D-0.16,H-1.02),'atm_body')
    yfh=0.10-(D-0.16)/2
    P=[(ax-W/2,yfh,1.02),(ax+W/2,yfh,1.02),(ax+W/2,yfh-0.10,1.08),(ax-W/2,yfh-0.10,1.08)]
    b.box((ax,yfh-0.05,1.02),(W,0.10,0.06),'atm_body')                                         # shelf
    _q(b,[(ax-W/2+0.02,yfh-0.0008,1.10),(ax+W/2-0.02,yfh-0.0008,1.10),(ax+W/2-0.02,yfh-0.0008,H-0.03),(ax-W/2+0.02,yfh-0.0008,H-0.03)],'atm_blue',(0,-1,0))
    b.box((ax,yfh-0.004,1.20),(0.30,0.006,0.22),'screen',ch=0)
    b.box((ax-0.07,yfh-0.104,1.064),(0.14,0.006,0.10),'keypad',rx=-0.5,ch=0)
    b.box((ax+0.11,yfh-0.003,1.12),(0.07,0.006,0.03),'steel_dk',ch=0); _q(b,[(ax+0.085,yfh-0.007,1.133),(ax+0.135,yfh-0.007,1.133),(ax+0.135,yfh-0.007,1.137),(ax+0.085,yfh-0.007,1.137)],'hole',(0,-1,0))
    b.box((ax+0.11,yfh-0.003,1.43),(0.08,0.006,0.02),'hole',ch=0)                              # receipt
    yfl=0.02-D/2
    b.box((ax,yfl-0.006,0.82),(0.26,0.012,0.06),'steel_dk',ch=0); _q(b,[(ax-0.10,yfl-0.0125,0.845),(ax+0.10,yfl-0.0125,0.845),(ax+0.10,yfl-0.0125,0.855),(ax-0.10,yfl-0.0125,0.855)],'hole',(0,-1,0))
    b.box((ax,yfl-0.003,0.30),(W-0.08,0.006,0.40),'atm_body')                                 # service door
    b.box((ax+0.18,yfl-0.008,0.48),(0.03,0.01,0.06),'steel_dk')
    # topper sign (baked lettering)
    b.box((ax,0.10,H),(W,0.14,0.16),'atm_blue')
    b.box((ax,0.10-0.071,H+0.02),(W-0.06,0.002,0.12),'paint_navy' if hi else 'atm_sign',ch=0)
    if hi:
        import pg as _pg
        _pg.add_text(b,'ATM',0.10,(ax,0.10-0.073,H+0.08),(1,0,0),(0,0,1),0.002,'label')
    # lottery play station (right)
    lx=0.36; lw,ld=0.56,0.42
    b.box((lx,0.06,0),(0.40,0.30,0.06),'steel_dk',skip=('bottom',))
    b.box((lx,0.06,0.06),(0.08,0.08,0.88),'steel_dk')
    zt=1.04; tilt=0.30
    b.box((lx,0.0,0.94),(lw,ld,0.06),'lotto_green',rx=0.0)
    # slanted writing surface
    yA,yB=-ld/2,ld/2; zA,zB=zt-0.02,zt+0.10
    _q(b,[(lx-lw/2,yA,zA),(lx+lw/2,yA,zA),(lx+lw/2,yB,zB),(lx-lw/2,yB,zB)],'lotto_yel',(0,-0.3,1))
    _q(b,[(lx-lw/2,yA,1.0),(lx+lw/2,yA,1.0),(lx+lw/2,yA,zA),(lx-lw/2,yA,zA)],'lotto_green',(0,-1,0))
    for sx in (-1,1): _q(b,[(lx+sx*lw/2,yA,1.0),(lx+sx*lw/2,yB,1.0),(lx+sx*lw/2,yB,zB),(lx+sx*lw/2,yA,zA)],'lotto_green',(sx,0,0))
    _q(b,[(lx+lw/2,yB,1.0),(lx-lw/2,yB,1.0),(lx-lw/2,yB,zB),(lx+lw/2,yB,zB)],'lotto_green',(0,1,0))
    # back board with slip pockets (each pocket a lip + slips)
    b.box((lx,yB+0.01,zB),(lw,0.02,0.34),'lotto_green')
    for i in range(4):
        x=lx-lw/2+0.07+i*0.14
        for zr in (zB+0.05,zB+0.20):
            b.box((x,yB-0.012,zr),(0.11,0.015,0.10),'label' if hi else 'mag_white',ch=0)
            b.box((x,yB-0.022,zr),(0.12,0.006,0.05),'lotto_yel' if i%2 else 'paint_white',ch=0)
    b.box((lx,yB+0.01,zB+0.34),(lw,0.03,0.16),'lotto_yel')
    b.box((lx,yB-0.006,zB+0.355),(lw-0.04,0.002,0.13),'lotto_sign' if not hi else 'leaf',ch=0)
    if hi:
        import pg as _pg
        _pg.add_text(b,'LOTTO',0.11,(lx,yB-0.0075,zB+0.42),(1,0,0),(0,0,1),0.0015,'label')
    for k,x in enumerate((lx-0.16,lx+0.16)):   # tethered pens
        y=-0.05; z=zA+(zB-zA)*(y-yA)/(yB-yA)+0.008
        b.tube((x,y,z),(x+0.09,y+0.03,z+0.01),0.004,0.004,4,'plastic_black',cap0=False,cap1=False)
        b.tube(V(x,y,z),V(x-0.02,yB-0.02,zB),0.0015,0.0015,3,'chrome',cap0=False,cap1=False)
    b.cbox((ax,0.02,0),(W+0.02,D+0.02,H+0.16)); b.cbox((lx,0.06,0),(lw,ld+0.04,zB+0.44))

# ------------------------------------------------------------------ magazine_rack
def magazine_rack(b, hi=False):
    """bookshop magazine rack: oak A-frame tiers, four sloped shelves each with a lip; magazines face out
    (cover colour + white masthead band + coverline), back side solid oak panel."""
    W=1.00; tiers=4; R=random.Random(5)
    for sx in (-1,1):   # side cheeks (stepped profile)
        x=sx*(W/2-0.011)
        prof=[(-0.24,0.0),(0.12,0.0),(0.12,1.32),(0.00,1.32),(-0.24,0.30)]
        Fp=[V(x-0.011,py,pz) for py,pz in prof]; Bp=[V(x+0.011,py,pz) for py,pz in prof]
        _q(b,Fp,'oak',(-1,0,0)); _q(b,Bp,'oak',(1,0,0))
        for i in range(len(prof)):
            j=(i+1)%len(prof); a,c=prof[i],prof[j]
            _q(b,[Fp[i],Fp[j],Bp[j],Bp[i]],'oak',(0,c[1]-a[1],-(c[0]-a[0])))
    b.box((0,0.11,0.0),(W-0.044,0.02,1.30),'oak')                                       # back panel
    b.box((0,0.0,0.0),(W-0.044,0.20,0.06),'oak')                                         # kick
    for k in range(tiers):
        zb=0.10+0.30*k; yb_=-0.20+0.075*k
        # sloped shelf board (leans back 15 deg) + front lip
        _q(b,[(-W/2+0.022,yb_,zb),(W/2-0.022,yb_,zb),(W/2-0.022,0.10,zb+0.06),(-W/2+0.022,0.10,zb+0.06)],'oak',(0,-0.2,1))
        b.box((0,yb_-0.005,zb-0.01),(W-0.044,0.016,0.045),'walnut',ch=0)
        # magazines: lean back on the board, 4-5 across
        n=5 if k%2 else 4; mw=(W-0.06)/n
        for i in range(n):
            x0=-W/2+0.03+i*mw+0.012; x1=x0+mw-0.024; h=0.27+0.02*R.random(); t=0.28
            bot=V(0,yb_+0.012,zb+0.012); top=bot+V(0,h*math.sin(t),h*math.cos(t)); nv=V(0,-math.cos(t),math.sin(t))
            key=SL[(k*5+i*3)%8]
            def P(x,f): return V(x,0,0)+bot+(top-bot)*f
            _q(b,[P(x0,0),P(x1,0),P(x1,1),P(x0,1)],key,nv)
            _q(b,[P(x0,0.80)+nv*0.0008,P(x1,0.80)+nv*0.0008,P(x1,0.96)+nv*0.0008,P(x0,0.96)+nv*0.0008],'mag_white' if key not in ('sl_4',) else 'sl_3',nv)
            _q(b,[P(x0+0.02,0.25)+nv*0.0008,P(x0+0.10,0.25)+nv*0.0008,P(x0+0.10,0.30)+nv*0.0008,P(x0+0.02,0.30)+nv*0.0008],'mag_white',nv)
            _q(b,[P(x0,1),P(x1,1),P(x1,1)-nv*0.006,P(x0,1)-nv*0.006],key,(0,0,1))
    b.box((W/2-0.12,-0.262,0.012),(0.10,0.002,0.03),'badge',ch=0)
    b.box((0,0.11,1.30),(W-0.044,0.02,0.13),'walnut')                                      # header board
    b.box((0,0.099,1.315),(0.52,0.002,0.10),'mag_sign' if not hi else 'paint_navy',ch=0)
    if hi:
        import pg as _pg
        _pg.add_text(b,'MAGAZINES',0.08,(0,0.0975,1.365),(1,0,0),(0,0,1),0.0015,'label')
    b.cbox((0,-0.06,0),(W,0.36,1.43))

# ------------------------------------------------------------------ wetsuit_rack
def _suit(b, x, y, zt, key, panel, hi):
    """full wetsuit hanging from its shoulders: flat-ish neoprene silhouette (front+back+edge), coloured shoulder
    and knee panels, back-zip cord."""
    S=[(0.00,0.00),(0.13,-0.02),(0.21,-0.08),(0.27,-0.42),(0.23,-0.44),(0.17,-0.14),(0.16,-0.62),(0.13,-1.30),
       (0.04,-1.30),(0.02,-0.72),(-0.02,-0.72),(-0.04,-1.30),(-0.13,-1.30),(-0.16,-0.62),(-0.17,-0.14),(-0.23,-0.44),(-0.27,-0.42),(-0.21,-0.08),(-0.13,-0.02)]
    t=0.035
    F=[V(x+px*0.86,y-t/2,zt+pz) for px,pz in S]; Bk=[V(x+px*0.86,y+t/2,zt+pz) for px,pz in S][::-1]
    # front / back as triangle fans from a centre point (concave outline: split into torso + legs + arms)
    for side,yy,nn in ((-1,y-t/2,(0,-1,0)),(1,y+t/2,(0,1,0))):
        def Pt(i): return V(x+S[i][0]*0.86,yy,zt+S[i][1])
        for poly in ([0,1,2,5,6,9,10,13,14,17,18],[2,3,4,5],[14,15,16,17],[6,7,8,9],[10,11,12,13]):
            _q(b,[Pt(i) for i in poly],key,nn)
        # shoulder panels + knee pads
        for poly,k2 in (([1,2,5],panel),([17,18,14],panel)):
            pp=[Pt(i)+V(0,(-0.0008 if side<0 else 0.0008),0) for i in poly]
            _q(b,pp,k2,nn)
        for xx in (0.085,-0.085):
            c=V(x+xx*0.86,yy+(-0.0008 if side<0 else 0.0008),zt-0.98)
            _q(b,[c+V(-0.035,0,-0.05),c+V(0.035,0,-0.05),c+V(0.035,0,0.05),c+V(-0.035,0,0.05)],'np_grey',nn)
    for i in range(len(S)):   # edge band
        j=(i+1)%len(S); a=V(x+S[i][0]*0.86,0,zt+S[i][1]); c=V(x+S[j][0]*0.86,0,zt+S[j][1]); d=c-a
        _q(b,[V(a.x,y-t/2,a.z),V(c.x,y-t/2,c.z),V(c.x,y+t/2,c.z),V(a.x,y+t/2,a.z)],key,(-d.z,0,d.x))
    # zip cord down the back
    b.sweep([V(x,y+t/2+0.002,zt-0.05),V(x,y+t/2+0.004,zt-0.55),V(x+0.03,y+t/2+0.01,zt-0.80)],0.003,3,panel,cap0=False,cap1=True)
def wetsuit_rack(b, hi=False):
    """surf/dive rental rail: chrome two-arm garment rail on a weighted base, six full wetsuits on wide
    shoulder hangers (black neoprene, colour shoulder panels, grey knee pads), size tabs on the rail."""
    L=1.50; H=1.78
    for sx in (-1,1):
        x=sx*(L/2)
        b.tube((x,0,0.04),(x,0,H),0.016,0.016,sg(hi,8,12),'chrome',cap0=False,cap1=True)
        b.box((x,0,0),(0.08,0.62,0.04),'steel_dk',skip=('bottom',))
        for sy in (-1,1): b.tube((x,sy*0.27,0.0),(x,sy*0.27,0.03),0.025,0.025,sg(hi,6,10),'rubber',cap0=False,cap1=True)
    b.tube((-L/2,0,H-0.02),(L/2,0,H-0.02),0.013,0.013,sg(hi,8,12),'chrome',cap0=True,cap1=True)
    keys=[('neoprene','np_teal'),('neoprene','np_red'),('neoprene','np_blue'),('neoprene','np_grey'),('np_blue','neoprene'),('neoprene','np_teal')]
    for i,(k,p) in enumerate(keys):
        x=-L/2+0.16+i*(L-0.32)/5; y=0.0
        b.sweep([V(x,0,H-0.02),V(x,0,H+0.03),V(x,-0.01,H+0.05)],0.003,3,'chrome',cap0=False,cap1=True)
        n0=nfaces(b)
        b.box((x,0,H-0.11),(0.44,0.03,0.035),'plastic_black',ch=0)                        # broad hanger
        _suit(b,x,0.0,H-0.09,k,p,hi)
        b.box((x+0.05,-0.016,H-0.05),(0.035,0.004,0.025),'paint_white' if i%2 else 'lotto_yel',ch=0)   # size tab
        yaw=-(math.pi/2-0.55)+(0.10 if i%2 else -0.06)
        ca,sa=math.cos(yaw),math.sin(yaw)
        xform(b,n0,lambda co,x=x,ca=ca,sa=sa: V(x+(co.x-x)*ca-co.y*sa,(co.x-x)*sa+co.y*ca,co.z))
    b.box((L/2-0.12,-0.315,0.01),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(L+0.08,0.62,H+0.05))

# ------------------------------------------------------------------ helmet_wall
def helmet(b, c, key, accent, hi=False, yaw=0.0):
    """road/BMX bike helmet: squashed dome (lathe), dark vent slots, accent stripe, visor peak, strap loop"""
    x,y,z=c; n=sg(hi,8,16)
    prof=[(0.125,0.0),(0.130,0.035),(0.118,0.085),(0.085,0.135),(0.040,0.160),(0.0,0.165)] if hi else [(0.125,0.0),(0.130,0.040),(0.110,0.105),(0.060,0.152),(0.0,0.165)]
    n0=nfaces(b)
    b.lathe(prof,n,key,c=(0,0,0),cap_top=False,cap_bot=False)
    M=__import__('mathutils').Matrix.Rotation(yaw,3,'Z')
    xform(b,n0,lambda co: M@V(co.x*0.95,co.y*1.22,co.z)+V(x,y,z))
    for k in (-1,0,1):   # vents (dark slots on the dome)
        a=math.radians(-90+k*30)+yaw
        for zz in ((0.115,0.14) if hi else (0.13,)):
            r=0.098 if zz<0.135 else 0.075
            ca_=math.cos(a-yaw); sa_=math.sin(a-yaw); lx=r*0.95*ca_; ly=r*1.22*sa_
            cx=x+lx*math.cos(yaw)-ly*math.sin(yaw); cy=y+lx*math.sin(yaw)+ly*math.cos(yaw)
            nv=V(math.cos(a),math.sin(a),0.4).normalized(); tg=V(-math.sin(a),math.cos(a),0)*0.012
            _q(b,[V(cx,cy,z+zz-0.016)-tg+nv*0.002,V(cx,cy,z+zz-0.016)+tg+nv*0.002,V(cx,cy,z+zz+0.016)+tg+nv*0.002,V(cx,cy,z+zz+0.016)-tg+nv*0.002],'hole',tuple(nv))
    # accent stripe around the shell
    for k in range(-2,3):
        a=-math.pi/2+yaw+k*0.30; nv=V(math.cos(a),math.sin(a),0.25).normalized()
        c=V(x+0.122*0.95*math.cos(a-yaw)*math.cos(yaw)-0.122*1.22*math.sin(a-yaw)*math.sin(yaw), y+0.122*0.95*math.cos(a-yaw)*math.sin(yaw)+0.122*1.22*math.sin(a-yaw)*math.cos(yaw), z+0.035)+nv*0.002
        tg=V(-math.sin(a),math.cos(a),0)*0.020
        if hi or k==0: _q(b,[c-tg,c+tg,c+tg+V(0,0,0.014),c-tg+V(0,0,0.014)],accent,tuple(nv))
    if hi: b.sweep([V(x-0.10,y-0.03,z),V(x,y-0.06,z-0.13),V(x+0.10,y-0.03,z)],0.004,3,'plastic_black',cap0=False,cap1=False)
    else: _q(b,[V(x-0.004,y-0.05,z-0.12),V(x+0.004,y-0.05,z-0.12),V(x+0.004,y-0.05,z),V(x-0.004,y-0.05,z)],'plastic_black',(0,-1,0))
def helmet_wall(b, hi=False):
    """bike / skate shop helmet wall: 1.2 x 1.5 m grey slatwall with twelve helmets on chrome hooks (three rows),
    mixed colourways, price strip on each row."""
    W,H=1.20,1.50; z0=0.55; yb=0.06
    slatwall(b,W,H,yb,z0)
    cols=[('sl_3','sl_0'),('sl_4','sl_1'),('sl_0','sl_3'),('sl_1','sl_4'),('np_teal','sl_3'),('sl_2','sl_3'),
          ('sl_3','sl_2'),('sl_5','sl_4'),('sl_6','sl_3'),('sl_4','sl_0'),('sl_7','sl_3'),('sl_1','sl_2')]
    i=0
    for r,zr in enumerate((z0+1.12,z0+0.70,z0+0.28)):
        for cidx in range(4):
            x=-W/2+0.15+cidx*(W-0.30)/3
            hook(b,x,zr+0.10,yb,0.16,hi)
            k,a=cols[i]; i+=1
            helmet(b,(x,yb-0.17,zr-0.02),k,a,hi,yaw=(0.75 if cidx%2 else -0.75))
        b.box((0,yb-0.022,zr-0.11),(W-0.04,0.008,0.03),'label' if hi else 'price_k',ch=0)
    b.cbox((0,yb-0.16,z0),(W,0.32,H))

# ------------------------------------------------------------------ folded_stack_table
def _stack(b, x, y, z, w, d, n, key, hi, rz=0.0, alt=None):
    """stack of n folded garments: one block + a fold crease band per garment on the front and sides"""
    th=0.034; h=n*th
    b.box((x,y,z),(w,d,h),key,rz=rz,ch=0)
    ca,sa=math.cos(rz),math.sin(rz)
    for k in range(n):
        zz=z+k*th+th*0.5
        fy=-d/2-0.0008
        p=lambda lx,lz: V(x+lx*ca-fy*sa,y+lx*sa+fy*ca,lz)
        _q(b,[p(-w/2,zz-0.003),p(w/2,zz-0.003),p(w/2,zz+0.003),p(-w/2,zz+0.003)],alt or 'slot_dk',(-sa,-ca,0))
    # top garment shows the shoulder fold + print patch
    p=lambda lx,ly: V(x+lx*ca-ly*sa,y+lx*sa+ly*ca,z+h+0.0008)
    _q(b,[p(-w*0.18,-d*0.10),p(w*0.18,-d*0.10),p(w*0.18,d*0.22),p(-w*0.18,d*0.22)],alt or 'mag_white',(0,0,1))
def folded_stack_table(b, hi=False):
    """clothing-store nesting tables: a big oak top on a black steel frame with a lower shelf, stacks of folded
    tees, knits and jeans in colour runs, a small acrylic price block."""
    L,D,H=1.50,0.80,0.80
    b.box((0,0,H-0.04),(L,D,0.04),'oak')
    for sx in (-1,1):
        for sy in (-1,1): b.box((sx*(L/2-0.05),sy*(D/2-0.05),0),(0.04,0.04,H-0.04),'paint_black')
    b.box((0,0,0.18),(L-0.06,D-0.06,0.025),'oak')
    for sy in (-1,1): b.box((0,sy*(D/2-0.05),H-0.10),(L-0.10,0.03,0.06),'paint_black')
    R=random.Random(3)
    tops=[('ts_2',4,None),('ts_1',5,None),('ts_3',4,'ts_2'),('ts_0',3,None),('denim',6,'denim_lt'),('knit',4,None),('ts_5',5,None),('denim_lt',5,'denim'),('ts_7',4,None)]
    for i,(k,n,alt) in enumerate(tops):
        cx=-L/2+0.20+(i%5)*0.275; cy=-0.17 if i<5 else 0.18
        _stack(b,cx,cy,H,0.27 if 'denim' not in k else 0.30,0.30,n,k,hi,rz=R.uniform(-0.05,0.05),alt=alt)
    for i,(k,n) in enumerate((('ts_4',4),('ts_6',5),('denim',4),('ts_0',3))):
        _stack(b,-L/2+0.25+i*0.33,0.0,0.205,0.28,0.30,n,k,hi,rz=R.uniform(-0.04,0.04))
    bx_=L/2-0.20
    b.box((bx_,0.0,0.205),(0.26,0.30,0.12),'knit',ch=0,skip=('bottom',))                  # woven sock basket
    for i in range(6 if not hi else 9):
        u=-0.08+(i%3)*0.08; v=-0.08+(i//3)*0.08 if not hi else -0.09+(i//3)*0.09
        b.tube((bx_+u,v-0.03,0.335),(bx_+u,v+0.03,0.335),0.025,0.025,sg(hi,5,10),SL[(i*3)%8] if i%2 else 'ts_2',cap0=True,cap1=True)
    b.box((L/2-0.15,-D/2+0.10,H),(0.10,0.04,0.07),'glass',rz=-0.3)
    b.box((L/2-0.15,-D/2+0.079,H+0.01),(0.08,0.002,0.05),'label',rz=-0.3,ch=0)
    b.cbox((0,0,0),(L,D,H+0.22))

# ------------------------------------------------------------------ bargain_bin
def bargain_bin(b, hi=False):
    """discount-store dump bin: chrome wire bin on casters (frame tubes + vertical wires), heaped with
    jumbled boxed goods, a red 'SALE' card on a clip stalk."""
    L,D,H=1.00,0.62,0.78; z0=0.14; R=random.Random(9)
    for sx in (-1,1):
        for sy in (-1,1):
            x,y=sx*(L/2-0.04),sy*(D/2-0.04)
            b.tube((x,y,0.03),(x,y,z0),0.010,0.010,4,'chrome',cap0=False,cap1=False)
            b.tube((x,y-0.012,0.035),(x,y+0.012,0.035),0.035,0.035,sg(hi,6,12),'rubber',cap0=True,cap1=True)
    b.box((0,0,z0),(L,D,0.012),'steel_dk')
    for zz in (z0,z0+H*0.5-0.07,H):
        P=[V(-L/2,-D/2,zz),V(L/2,-D/2,zz),V(L/2,D/2,zz),V(-L/2,D/2,zz),V(-L/2,-D/2,zz)]
        b.sweep(P,0.008,sg(hi,4,8),'wire',cap0=False,cap1=False)
    for sx in (-1,1):
        for sy in (-1,1): b.tube((sx*L/2,sy*D/2,z0),(sx*L/2,sy*D/2,H),0.009,0.009,4,'wire',cap0=False,cap1=False)
    for i in range(1,10):   # vertical wires, long sides
        x=-L/2+i*L/10
        for sy in (-1,1): b.tube((x,sy*D/2,z0),(x,sy*D/2,H),0.0035,0.0035,3,'wire',cap0=False,cap1=False)
    for i in range(1,6):
        y=-D/2+i*D/6
        for sx in (-1,1): b.tube((sx*L/2,y,z0),(sx*L/2,y,H),0.0035,0.0035,3,'wire',cap0=False,cap1=False)
    # heap of goods: boxes at random tilt, layered so the top reads as a mound
    keys=SL+['lotto_yel','np_teal','tv_beige']
    for k in range(sg(hi,26,26)):
        u=R.uniform(-0.42,0.42); v=R.uniform(-0.24,0.24); hgt=0.45*(1-0.9*u*u)*(1-1.2*v*v)
        w,d,h=R.uniform(0.08,0.20),R.uniform(0.06,0.14),R.uniform(0.04,0.16)
        b.box((u,v,z0+0.01+max(0.0,hgt-0.12)+R.uniform(0,0.08)),(w,d,h),keys[k%len(keys)],rz=R.uniform(0,3.1),rx=R.uniform(-0.3,0.3),ch=0,skip=('bottom',))
    for x in (-0.30,0.05,0.32):                                                             # clip-on price cards
        _q(b,[(x-0.045,-D/2-0.010,H-0.11),(x+0.045,-D/2-0.010,H-0.11),(x+0.045,-D/2-0.010,H-0.01),(x-0.045,-D/2-0.010,H-0.01)],'lotto_yel' if x<0.3 else 'basket_red',(0,-1,0))
        _q(b,[(x-0.03,-D/2-0.0108,H-0.085),(x+0.03,-D/2-0.0108,H-0.085),(x+0.03,-D/2-0.0108,H-0.05),(x-0.03,-D/2-0.0108,H-0.05)],'paint_black' if x<0.3 else 'mag_white',(0,-1,0))
    b.box((0,0,z0+0.01),(L-0.03,D-0.03,0.30),'sl_3',ch=0,skip=('bottom','top'))         # backing fill so nothing reads hollow
    b.box((0,0,z0+0.31),(L-0.03,D-0.03,0.001),'tv_beige',ch=0,skip=('bottom',))
    # SALE card
    b.tube((L/2-0.06,-D/2+0.02,H),(L/2-0.06,-D/2+0.02,H+0.32),0.004,0.004,3,'chrome',cap0=False,cap1=True)
    b.box((L/2-0.06,-D/2+0.02,H+0.25),(0.26,0.004,0.16),'fabric' if hi else 'sale_k',ch=0)
    if hi:
        import pg as _pg
        for sy in (-1,1): _pg.add_text(b,'SALE',0.10,(L/2-0.06,-D/2+0.02+sy*0.0035,H+0.33),(-sy,0,0),(0,0,1),0.0015,'label')
    b.cbox((0,0,0),(L+0.02,D+0.02,H))

# ------------------------------------------------------------------ flower_bucket_stand
def bouquet(b, c, keys, R, hi, n=7, spread=0.09, hgt=0.42):
    x,y,z=c
    for i in range(n):
        a=2*math.pi*i/n+R.uniform(-0.3,0.3); r=spread*(0.4+0.6*R.random()) if i else 0.0
        tip=V(x+r*math.cos(a),y+r*math.sin(a),z+hgt*(0.85+0.3*R.random()))
        if hi or i%2==0: b.tube(V(x,y,z+0.05),tip,0.004,0.004,3,'stem',cap0=False,cap1=False)
        k=keys[i%len(keys)]; s=0.035+0.015*R.random()
        b.tube(tip-V(0,0,0.01),tip+V(0,0,s*0.6),s*0.55,s,sg(hi,4,10),k,cap0=hi,cap1=True,phase=R.uniform(0,1))   # bloom cup
    for i in range(3):   # leaves
        a=R.uniform(0,6.28); b0=V(x,y,z+0.12)
        d=V(math.cos(a),math.sin(a),1.3).normalized()
        nn=V(-math.sin(a),math.cos(a),0)*0.022
        _q(b,[b0,b0+d*0.10+nn,b0+d*0.22,b0+d*0.10-nn],'leaf',tuple(d.cross(nn)))
def flower_bucket_stand(b, hi=False):
    """florist / corner-store flower stand: three green painted steps, galvanised buckets with cut bouquets
    (mixed colours), chalk price tags, a water tray."""
    W=1.10; steps=((0.0,0.0,0.34),(0.18,0.24,0.30),(0.36,0.48,0.26))   # (y offset, z, depth)
    for k,(yo,z,d) in enumerate(steps):
        y=-0.30+yo+0.18*k*0
        yc=-0.25+k*0.25
        b.box((0,yc,0),(W,0.26,z+0.24),'stand_grn')
        b.box((0,yc,z+0.24),(W+0.02,0.27,0.02),'paint_white',ch=0,skip=('bottom',))
    R=random.Random(4); palettes=[['f_pink','f_white'],['f_yel','f_org'],['f_red','f_red','f_white'],['f_purp','f_white'],['f_white','f_yel'],['f_org','f_red'],['f_pink','f_purp'],['f_yel','f_white']]
    i=0
    for k in range(3):
        yc=-0.25+k*0.25; zt=steps[k][1]+0.26
        for x in ((-0.36,0.0,0.36) if k!=1 else (-0.18,0.18)):
            b.lathe([(0.075,0.0),(0.095,0.25),(0.100,0.255),(0.094,0.255)] if hi else [(0.075,0.0),(0.097,0.255)],sg(hi,8,16),'galv',c=(x,yc,zt),cap_top=False,cap_bot=False)
            _q(b,ring_pts((x,yc),0.093,sg(hi,6,8),zt+0.20)[::1],'glow_b',(0,0,1))   # water
            bouquet(b,(x,yc,zt+0.12),palettes[i%len(palettes)],R,hi,n=8 if k==0 else 7,spread=0.10)
            _q(b,[(x-0.035,yc-0.0995,zt+0.10),(x+0.035,yc-0.0995,zt+0.10),(x+0.035,yc-0.0995,zt+0.15),(x-0.035,yc-0.0995,zt+0.15)],'chalkbd',(0,-1,0))
            i+=1
    b.box((W/2-0.10,-0.381,0.05),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,0,0),(W,0.76,1.30))

# ------------------------------------------------------------------ shopping_cart
def shopping_cart(b, hi=False):
    """supermarket trolley: chrome wire basket (tapered, perforated-look sides), red plastic handle with a
    coin-lock box, fold-down child seat flap, bottom tray, four swivel casters. Nestable (open back)."""
    L,W=0.92,0.54; zb,zt=0.42,0.98; R=random.Random(2)
    bw_back,bw_front=W,0.48; lf=-L/2+0.06   # front (x-) is narrower and lower
    def T(xf,side,z): 
        w=bw_front+(bw_back-bw_front)*xf; return V(-L/2+0.06+(L-0.12)*xf, side*w/2, z)
    # basket frame rails
    for z,fr in ((zb,0.0),(zt,1.0)):
        b.sweep([T(0,-1,z+(0.03 if z==zt else 0)),T(1,-1,z),T(1,1,z),T(0,1,z+(0.03 if z==zt else 0)),T(0,-1,z+(0.03 if z==zt else 0))],0.007,sg(hi,4,8),'wire',cap0=False,cap1=False)
    for xf in (0,0.33,0.66,1.0):
        for sd in (-1,1): b.tube(T(xf,sd,zb),T(xf,sd,zt),0.006,0.006,4,'wire',cap0=False,cap1=False)
    # wire mesh sides: thin longitudinal + vertical wires
    for z in (zb+0.11,zb+0.22,zb+0.33,zb+0.44):
        for sd in (-1,1): b.tube(T(0,sd,z),T(1,sd,z),0.0028,0.0028,3,'wire',cap0=False,cap1=False)
        b.tube(T(0,-1,z),T(0,1,z),0.0028,0.0028,3,'wire',cap0=False,cap1=False)
    for i in range(1,12):
        xf=i/12
        for sd in (-1,1): b.tube(T(xf,sd,zb),T(xf,sd,zt),0.0025,0.0025,3,'wire',cap0=False,cap1=False)
    for i in range(1,6):
        y=-bw_front/2+i*bw_front/6; b.tube(V(lf,y,zb),V(lf,y,zt+0.03),0.0025,0.0025,3,'wire',cap0=False,cap1=False)
    # floor grid (perforated look)
    _q(b,[T(0,-1,zb),T(1,-1,zb),T(1,1,zb),T(0,1,zb)],'wire',(0,0,1))
    for i in range(1,8):
        xf=i/8; _q(b,[T(xf-0.03,-1,zb+0.001),T(xf+0.03,-1,zb+0.001),T(xf+0.03,1,zb+0.001),T(xf-0.03,1,zb+0.001)],'slot_dk',(0,0,1))
    # child seat flap (folded up against the back) + handle
    bx=L/2-0.06
    b.box((bx-0.02,0,zt-0.30),(0.012,W-0.06,0.28),'wire',ch=0)
    b.box((bx-0.026,0,zt-0.26),(0.002,W-0.14,0.18),'cart_red',ch=0)
    b.sweep([V(bx,-W/2,zt),V(bx+0.14,-W/2,zt+0.06),V(bx+0.14,W/2,zt+0.06),V(bx,W/2,zt)],0.009,sg(hi,4,8),'wire',cap0=False,cap1=False)
    b.tube(V(bx+0.145,-W/2+0.04,zt+0.065),V(bx+0.145,W/2-0.04,zt+0.065),0.018,0.018,sg(hi,8,12),'cart_red',cap0=True,cap1=True)
    b.box((bx+0.13,0,zt+0.075),(0.06,0.10,0.05),'cart_red')                                       # coin lock
    # chassis: tubes down to casters, bottom tray
    for xf,xc in ((0.0,-L/2+0.10),(1.0,L/2-0.10)):
        for sd in (-1,1):
            p=T(xf,sd,zb); b.tube(p,V(xc,sd*(W/2-0.05),0.12),0.010,0.010,4,'wire',cap0=False,cap1=False)
            b.box((xc,sd*(W/2-0.05),0.09),(0.04,0.03,0.035),'steel_dk')
            b.tube(V(xc-0.006,sd*(W/2-0.05)-0.016,0.055),V(xc-0.006,sd*(W/2-0.05)+0.016,0.055),0.055,0.055,sg(hi,8,12),'tv_grey' if xf else 'tv_grey',cap0=True,cap1=True)
    b.box((0,0,0.16),(L-0.26,W-0.10,0.01),'wire',ch=0)
    for i in range(1,7): b.box((-L/2+0.13+i*(L-0.26)/7,0,0.161),(0.02,W-0.11,0.002),'slot_dk',ch=0)
    b.box((bx+0.11,0,zt+0.128),(0.04,0.08,0.002),'badge',ch=0)
    b.cbox((0.071,0,0),(L+0.26,W,zt+0.1))

# ------------------------------------------------------------------ security_mirror
def security_mirror(b, hi=False):
    """convex anti-theft dome mirror, 46 cm, on an adjustable wall arm (ceiling-corner height): black ABS rim,
    domed mirror face tilted down toward the aisle."""
    yb=0.20; zc=2.25; r=0.23; n=sg(hi,16,32)
    b.box((0,yb-0.01,zc+0.10),(0.10,0.02,0.14),'stand_blk')
    b.box((0,yb-0.0205,zc+0.20),(0.07,0.002,0.03),'badge',ch=0)
    b.tube((0,yb-0.02,zc+0.16),(0,yb-0.20,zc+0.09),0.012,0.012,sg(hi,6,10),'stand_blk',cap0=False,cap1=False)
    # dome: lathe about its own axis, then tilt 30 deg down and push to the arm end
    prof=[(r+0.012,-0.012),(r+0.014,0.012),(r,0.016),(r*0.93,0.034),(r*0.78,0.055),(r*0.55,0.073),(r*0.28,0.084),(0.0,0.088)]
    n0=nfaces(b)
    b.lathe(prof[:3],n,'stand_blk',cap_top=False,cap_bot=True)
    b.lathe(prof[2:],n,'mirror_dome',cap_top=False,cap_bot=False)
    import mathutils
    M=mathutils.Matrix.Rotation(math.radians(90+28),3,'X')
    xform(b,n0,lambda co: M@co+V(0,yb-0.22,zc))
    b.cbox((0,yb-0.20,zc-0.215),(0.50,0.40,0.475))

# ------------------------------------------------------------------ candle_shelf
def candle_shelf(b, hi=False):
    """botanica candle wall: dark pine open shelving (4 shelves) packed with 7-day glass prayer candles in
    coloured glass, white wax showing at the top, printed saint labels on the front row."""
    W,D,H=1.00,0.30,1.80; yb=D/2
    for sx in (-1,1): b.box((sx*(W/2-0.01),0,0),(0.02,D,H),'walnut')
    b.box((0,yb-0.006,0),(W,0.012,H),'walnut_dk')
    keys=['cg_r','cg_w','cg_g','cg_y','cg_b','cg_p','cg_r','cg_w']
    for k,z in enumerate((0.08,0.50,0.92,1.34,H-0.02)):
        b.box((0,0,z-0.02),(W-0.04,D,0.02),'walnut')
        if z>H-0.1: continue
        _q(b,[(-W/2+0.02,-D/2-0.0008,z-0.018),(W/2-0.02,-D/2-0.0008,z-0.018),(W/2-0.02,-D/2-0.0008,z-0.004),(-W/2+0.02,-D/2-0.0008,z-0.004)],'brass',(0,-1,0))
        for row,yy in enumerate((-0.07,0.05)):
            for i in range(6 if row==0 else 5):
                x=-W/2+0.10+i*0.16+(0.08 if row else 0); key=keys[(k*3+i+row)%8]
                b.tube((x,yy,z),(x,yy,z+0.20),0.030,0.030,sg(hi,6,12),key,cap0=False,cap1=False)
                _q(b,ring_pts((x,yy),0.030,sg(hi,6,12),z+0.19),'wax',(0,0,1))
                if row==0: b.box((x,yy-0.0305,z+0.04),(0.038,0.002,0.11),'label',ch=0)
    b.cbox((0,0,0),(W,D,H))

# ------------------------------------------------------------------ herb_jar_wall
def herb_jar_wall(b, hi=False):
    """botanica / herbalist wall of apothecary jars: oak shelves on black brackets, glass jars with black lids,
    dried herbs, roots, flowers and resins inside, handwritten labels."""
    W,H=1.20,1.00; yb=0.13; z0=0.95
    b.box((0,yb-0.009,z0),(W,0.018,H),'paint_cream')
    keys=['herb_g','herb_b','herb_r','herb_y','herb_p','herb_g','herb_b']
    R=random.Random(6)
    for k,z in enumerate((z0+0.05,z0+0.38,z0+0.71)):
        b.box((0,yb-0.13,z-0.025),(W,0.24,0.025),'oak')
        for x in (-W/2+0.15,W/2-0.15): b.box((x,yb-0.07,z-0.16),(0.02,0.12,0.13),'paint_black')
        n=7
        for i in range(n):
            x=-W/2+0.09+i*(W-0.18)/(n-1); r=0.045 if i%3 else 0.055; h=0.20 if i%2 else 0.16; key=keys[(i+k*2)%7]
            y=yb-0.13
            if hi:
                b.tube((x,y,z),(x,y,z+h*0.75),r*0.92,r*0.92,12,key,cap0=False,cap1=True)       # contents
                b.tube((x,y,z),(x,y,z+h),r,r,12,'jar',cap0=False,cap1=False)
            else:
                b.tube((x,y,z),(x,y,z+h*0.75),r,r,6,key,cap0=False,cap1=False)
                b.tube((x,y,z+h*0.75),(x,y,z+h),r,r,6,'jar',cap0=False,cap1=False)
            b.tube((x,y,z+h),(x,y,z+h+0.02),r*0.85,r*0.85,sg(hi,6,12),'lid_blk',cap0=False,cap1=True)
            _q(b,[(x-r*0.55,y-r-0.0015,z+0.05),(x+r*0.55,y-r-0.0015,z+0.05),(x+r*0.55,y-r-0.0015,z+0.095),(x-r*0.55,y-r-0.0015,z+0.095)],'label',(0,-1,0))
    for i,x in enumerate((-0.42,-0.24,-0.06,0.12,0.30,0.46)):                              # dried bundles
        zt=z0+0.025; L_=0.20+0.04*(i%2); y=yb-0.20
        b.tube((x,y,zt),(x,y,zt-0.03),0.003,0.003,3,'lace',cap0=False,cap1=False)
        b.tube((x,y,zt-0.03),(x,y,zt-0.03-L_),0.012,0.04,sg(hi,5,10),('herb_g','herb_y','herb_p','herb_b')[i%4],cap0=True,cap1=True)
        b.tube((x,y,zt-0.045),(x,y,zt-0.06),0.014,0.016,sg(hi,5,10),'lace',cap0=False,cap1=False)
    b.cbox((0,yb-0.13,z0-0.25),(W,0.26,H+0.25))

# ------------------------------------------------------------------ guitar_wall
def guitar(b, x, z, yb, body, pick, hi, kind='acoustic'):
    """hanging guitar (headstock on the hanger): body outline prism, neck + fretboard, headstock, soundhole or
    pickups, bridge, strings as a thin light strip"""
    sc=1.0 if kind=='acoustic' else 0.86
    O=[(0.00,0.00),(0.13,0.02),(0.19,0.10),(0.17,0.20),(0.11,0.27),(0.14,0.35),(0.13,0.44),(0.07,0.50),(0.00,0.51)]
    O=O+[(-px,pz) for px,pz in O[::-1][1:-1]]
    t=0.10 if kind=='acoustic' else 0.045; y0=yb-0.07-t
    pts=[(x+px*sc,z-0.98+pz*sc) for px,pz in O]
    b.prism(pts,y0,y0+t,body)
    zt=z-0.98+0.51*sc
    b.box((x,y0+0.010,zt-0.02),(0.05,0.022,0.98-0.51*sc-0.17+0.02),'walnut')                    # neck
    b.box((x,y0+0.003,zt-0.02),(0.052,0.004,0.98-0.51*sc-0.17+0.02),'rosewood',ch=0)
    b.box((x,y0+0.010,z-0.19),(0.085,0.018,0.19),'gt_blk' if body!='gt_blk' else 'walnut_dk')    # headstock
    for k in range(3 if hi else 0):
        for sx in (-1,1): b.tube((x+sx*0.045,y0+0.018,z-0.06-k*0.045),(x+sx*0.06,y0+0.018,z-0.06-k*0.045),0.006,0.006,4,'chrome',cap0=False,cap1=True)
    if not hi:
        for sx in (-1,1): _q(b,[(x+sx*0.0425,y0+0.012,z-0.16),(x+sx*0.058,y0+0.012,z-0.16),(x+sx*0.058,y0+0.012,z-0.03),(x+sx*0.0425,y0+0.012,z-0.03)],'chrome',(0,-1,0))
    yf=y0-0.0008
    if kind=='acoustic':
        _q(b,[V(x+0.045*math.cos(2*math.pi*i/10),yf,z-0.98+0.33*sc+0.045*math.sin(2*math.pi*i/10)) for i in range(10)],'hole',(0,-1,0))
        _q(b,[(x+0.05,yf-0.0004,z-0.98+0.25),(x+0.11,yf-0.0004,z-0.98+0.25),(x+0.09,yf-0.0004,z-0.98+0.31),(x+0.05,yf-0.0004,z-0.98+0.30)],pick,(0,-1,0))
        b.box((x,yf,z-0.98+0.11),(0.14,0.012,0.022),'rosewood')
    else:
        _q(b,[(x-0.03,yf,z-0.98+0.10),(x+0.13,yf,z-0.98+0.12),(x+0.10,yf,z-0.98+0.36),(x-0.06,yf,z-0.98+0.40)],pick,(0,-1,0))
        for zz in (0.18,0.28): b.box((x,yf-0.002,z-0.98+zz*sc),(0.075,0.006,0.02),'gt_blk',ch=0)
        b.box((x,yf-0.002,z-0.98+0.10),(0.08,0.008,0.016),'chrome',ch=0)
    for sx in (-0.007,0.007): _q(b,[(x+sx-0.0012,yf-0.006,z-0.98+0.11),(x+sx+0.0012,yf-0.006,z-0.98+0.11),(x+sx+0.0012,yf-0.006,z-0.17),(x+sx-0.0012,yf-0.006,z-0.17)],'steel_dk',(0,-1,0))
def guitar_wall(b, hi=False):
    """pawn / music shop guitar wall: slatwall with six guitars on yoke hangers (sunburst and natural acoustics,
    red, black and cream electrics, a bass), price tags on strings."""
    W,H=1.80,1.40; yb=0.10; z0=0.60
    slatwall(b,W,H,yb,z0)
    set_=[('sunburst','gt_blk','acoustic'),('gt_red','gt_cream','electric'),('oak','gt_blk','acoustic'),('gt_blk','gt_cream','electric'),('gt_cream','gt_blk','electric'),('walnut','gt_cream','acoustic')]
    for i,(body,pick,kind) in enumerate(set_):
        x=-W/2+0.17+i*(W-0.34)/5; z=z0+H-0.06
        b.box((x,yb-0.03,z-0.02),(0.06,0.04,0.03),'stand_blk')
        guitar(b,x,z-0.02,yb,body,pick,hi,kind)
        b.box((x+0.06,yb-0.12-0.0,z-0.40),(0.04,0.002,0.06),'label',ch=0)
    b.cbox((0,yb-0.10,z0-0.0),(W,0.20,H))

# ------------------------------------------------------------------ tv_electronics_stack
def tv(b, c, w, h, d, shell, hi, crt=False, stand=True):
    x,y,z=c
    if crt:
        b.box((x,y,z),(w,d*0.45,h),shell)
        b.tube(V(x,y+d*0.2,z+h/2),V(x,y+d*0.9,z+h/2),h*0.42,h*0.22,4,shell,cap0=False,cap1=True,phase=math.pi/4)
        b.box((x-w*0.06,y-d*0.225-0.002,z+0.06),(w*0.72,0.004,h-0.10),'screen',ch=0)
        for k in range(3): b.box((x+w*0.38,y-d*0.225-0.004,z+h*0.70-k*0.05),(0.02,0.006,0.02),'steel_dk',ch=0)
    else:
        if stand:
            b.box((x,y,z),(w*0.35,0.16,0.012),shell); b.box((x,y+0.02,z),(0.05,0.03,0.10),shell)
            z=z+0.07
        b.box((x,y,z),(w,0.035,h),shell)
        b.box((x,y-0.0185,z+0.012),(w-0.024,0.002,h-0.024),'screen',ch=0)
def tv_electronics_stack(b, hi=False):
    """pawn shop electronics bay: grey steel shelving (3 levels) with flat TVs, two old CRTs, a hi-fi stack,
    speakers, games consoles and a boxed camera, each with a swing tag."""
    W,D,H=1.40,0.50,1.70
    for sx in (-1,1):
        for sy in (-1,1): b.box((sx*(W/2-0.02),sy*(D/2-0.02),0),(0.035,0.035,H),'steel_dk')
    zs=(0.10,0.62,1.14,H-0.03)
    for z in zs:
        b.box((0,0,z-0.02),(W,D,0.03),'tv_grey')
        if z<1.5: _q(b,[(-W/2+0.04,-D/2-0.0008,z-0.018),(W/2-0.04,-D/2-0.0008,z-0.018),(W/2-0.04,-D/2-0.0008,z+0.008),(-W/2+0.04,-D/2-0.0008,z+0.008)],'lotto_yel' if z<0.5 else 'mag_white',(0,-1,0))
    tv(b,(-0.36,0.03,0.11),0.52,0.42,0.40,'tv_beige',hi,crt=True)
    tv(b,(0.30,0.03,0.11),0.48,0.36,0.38,'tv_grey',hi,crt=True)
    tv(b,(-0.30,0.0,0.63),0.70,0.40,0.0,'tv_blk',hi)
    tv(b,(0.38,0.05,0.63),0.50,0.30,0.0,'tv_blk',hi)
    tv(b,(0.25,0.06,1.15),0.80,0.45,0.0,'tv_blk',hi)
    # hi-fi stack + speakers (top shelf, left)
    for k,(h,key) in enumerate(((0.10,'chrome'),(0.08,'tv_blk'),(0.11,'alum'))):
        z=1.15+sum((0.10,0.08,0.11)[:k])
        b.box((-0.40,0.0,z),(0.43,0.33,h-0.004),key)
        b.box((-0.40,-0.167,z+h*0.3),(0.30,0.002,h*0.35),'tv_blk' if key!='tv_blk' else 'screen',ch=0)
        b.tube((-0.25,-0.166,z+h*0.5),(-0.25,-0.175,z+h*0.5),0.018,0.018,6,'steel_dk',cap0=False,cap1=True)
    for sx in (-0.65,-0.15):
        b.box((sx,0.0,1.15),(0.14,0.22,0.30),'walnut')
        for zz,r in ((1.37,0.035),(1.24,0.055)):
            b.tube((sx,-0.111,zz),(sx,-0.116,zz),r,r*0.6,sg(hi,8,14),'tv_blk',cap0=False,cap1=True)
    # console + box on the floor shelf front
    b.box((0.0,-0.15,0.11),(0.30,0.20,0.06),'tv_blk'); b.box((0.0,-0.251,0.125),(0.20,0.002,0.006),'hole',ch=0)
    b.box((0.62,-0.10,0.63),(0.13,0.10,0.16),'label')
    for (x,z) in ((-0.36,0.55),(0.30,0.49),(-0.30,1.06),(0.38,0.96),(0.25,1.65)):
        b.box((x+0.10,-0.06,z-0.04),(0.035,0.002,0.05),'lotto_yel',ch=0)                          # swing tags
    b.cbox((-0.010,0.069,0),(W+0.02,D+0.14,H))

# ------------------------------------------------------------------ phone_display_table
def phone_display_table(b, hi=False):
    """phone shop experience table: white solid-surface table with a light-oak inset strip, ten phones and two
    tablets on angled pucks with coiled security tethers, a branded riser card."""
    L,D,H=1.60,0.80,0.90
    b.box((0,0,H-0.04),(L,D,0.04),'plinth')
    b.box((0,0,0),(L-0.30,D-0.30,H-0.04),'plinth')
    for sy in (-1,1):
        yy=sy*((D-0.30)/2+0.0008)
        _q(b,[(-(L-0.30)/2+0.04,yy,H-0.12),((L-0.30)/2-0.04,yy,H-0.12),((L-0.30)/2-0.04,yy,H-0.105),(-(L-0.30)/2+0.04,yy,H-0.105)],'oak',(0,sy,0))
        _q(b,[(-0.08,yy,0.40),(0.08,yy,0.40),(0.08,yy,0.48),(-0.08,yy,0.48)],'tv_grey',(0,sy,0))
    b.box((0,0,0),(L-0.26,D-0.26,0.06),'steel_dk',skip=('bottom',))
    b.box((0,0,H),(L-0.20,0.16,0.002),'oak',ch=0,skip=('bottom',))
    R=random.Random(8)
    def device(x,y,w,h,shell,yaw):
        ca,sa=math.cos(yaw),math.sin(yaw)
        b.tube((x,y,H),(x,y,H+0.012),0.03,0.03,sg(hi,8,12),'tv_grey',cap0=False,cap1=True)
        # leaning device on the puck, 20 deg back
        t=0.35; c=V(x,y,H+0.012)
        up=V(0,math.sin(t),math.cos(t)); fw=V(0,-math.cos(t),math.sin(t))
        R2=__import__('mathutils').Matrix.Rotation(yaw,3,'Z')
        up=R2@up; fw=R2@fw; rt=R2@V(1,0,0)
        P=lambda a,bb,cc: c+rt*a+up*bb+fw*cc
        corners=[P(-w/2,0,0),P(w/2,0,0),P(w/2,h,0),P(-w/2,h,0)]
        _q(b,corners,'screen',tuple(fw))
        bk=[P(-w/2,0,-0.008),P(w/2,0,-0.008),P(w/2,h,-0.008),P(-w/2,h,-0.008)]
        _q(b,bk,shell,tuple(-fw))
        for i in range(4):
            j=(i+1)%4; _q(b,[corners[i],corners[j],bk[j],bk[i]],shell,tuple((corners[i]+corners[j])/2-(corners[0]+corners[2])/2))
        b.sweep([V(x,y+0.02,H+0.005),V(x+0.03,y+0.08,H+0.003),V(x-0.02,y+0.12,H+0.002)],0.003,3,'stand_blk',cap0=False,cap1=False)
    shells=['tv_blk','phone_wht','tv_grey','np_blue','tv_blk']
    for i in range(5):
        for sy in (-1,1):
            x=-L/2+0.20+i*0.30; y=sy*0.24
            yaw=0.0 if sy<0 else math.pi
            if i==2: device(x,y,0.17,0.24,shells[i],yaw)
            else: device(x,y,0.072,0.152,shells[(i+(sy>0))%5],yaw)
    b.box((0,0.0,H),(0.40,0.02,0.20),'paint_navy',ch=0); b.box((0,-0.011,H+0.03),(0.34,0.002,0.14),'label' if not hi else 'screen',ch=0)
    b.cbox((0,0,0),(L,D,H+0.2))

# ------------------------------------------------------------------ skateboard_deck_wall
def deck(b, x, z, yb, keys, hi, w=0.205, L=0.80):
    """skateboard deck hung graphic-side out: popsicle outline prism (maple ply edge), black grip on the back,
    graphic = base colour + two bands + logo patch, nose/tail colour caps"""
    n=sg(hi,4,10); O=[]
    for i in range(n+1): a=math.pi*i/n; O.append((w/2*math.cos(a),L/2-w/2+w/2*math.sin(a)))
    for i in range(n+1): a=math.pi+math.pi*i/n; O.append((w/2*math.cos(a),-L/2+w/2+w/2*math.sin(a)))
    y0=yb-0.045; t=0.012
    b.prism([(x+px,z+pz) for px,pz in O],y0,y0+t,'maple',back_key='grip')
    yf=y0-0.0006; m=0.006
    def band(z0_,z1_,key,dy=0.0,inset=m):
        _q(b,[(x-w/2+inset,yf-dy,z+z0_),(x+w/2-inset,yf-dy,z+z0_),(x+w/2-inset,yf-dy,z+z1_),(x-w/2+inset,yf-dy,z+z1_)],key,(0,-1,0))
    zs=L/2-w/2
    band(-zs,zs,keys[0])                                  # base graphic between the kicks
    band(-zs*0.55,-zs*0.15,keys[1],0.0004)                # lower band
    band(zs*0.20,zs*0.42,keys[2],0.0004)                  # upper band
    band(-0.035,0.045,keys[3],0.0008,0.045)               # logo patch
    # nose / tail graphic caps: half-disc fans in the base colour
    for sgn in (1,-1):
        c=(x,z+sgn*zs); pts=[(c[0]+(w/2-m)*math.cos(math.pi*i/n),yf,c[1]+sgn*(w/2-m)*math.sin(math.pi*i/n)) for i in range(n+1)]
        _q(b,pts,keys[0],(0,-1,0))
def skateboard_deck_wall(b, hi=False):
    """skate shop deck wall: slatwall with two rows of six decks on pegs, bright graphics (colour bands + logo),
    plus a top row of two complete boards (trucks + wheels) on brackets."""
    W,H=1.70,1.78; yb=0.08; z0=0.22
    slatwall(b,W,H,yb,z0)
    pals=[('sl_0','sl_4','sl_3','sl_2'),('sl_1','sl_2','sl_1','sl_4'),('sl_3','sl_0','sl_3','mag_white'),('sl_5','sl_4','sl_5','sl_3'),('sl_6','sl_2','sl_3','sl_4'),('sl_7','sl_1','sl_7','sl_4'),
          ('sl_2','sl_3','sl_2','sl_0'),('sl_4','sl_6','sl_4','sl_3'),('sl_1','sl_7','sl_0','sl_4'),('sl_3','sl_5','sl_2','sl_4'),('sl_0','sl_1','sl_0','sl_2'),('sl_5','sl_3','sl_4','sl_0')]
    i=0
    for zc in (z0+0.46,z0+1.32):
        for cidx in range(6):
            x=-W/2+0.16+cidx*(W-0.32)/5
            b.box((x,yb-0.03,zc+0.37),(0.02,0.03,0.02),'chrome')
            deck(b,x,zc,yb,pals[i],hi); i+=1
    b.box((W/2-0.15,yb-0.0195,z0+0.03),(0.10,0.002,0.03),'badge',ch=0)
    b.cbox((0,yb-0.04,z0),(W,0.10,H))

# ------------------------------------------------------------------ boot_display_wall
def boot(b, x, y, z, key, sole, hi, mirror=False):
    """lace-up work boot in side profile facing the aisle (x-z outline extruded 10 cm in y): lugged sole,
    padded collar, toe cap seam, laces up the instep"""
    s_=-1 if mirror else 1; w=0.10
    prof=[(-0.11,0.0),(0.16,0.0),(0.185,0.025),(0.175,0.06),(0.12,0.085),(0.04,0.105),(0.00,0.14),(-0.02,0.25),(-0.12,0.25),(-0.125,0.06)]
    pts=[(x+px*s_,z+pz) for px,pz in prof]
    if mirror: pts=pts[::-1]
    b.prism(pts,y-w/2,y+w/2,key)
    b.box((x+0.025*s_,y,z-0.025),(0.32,w+0.008,0.025),sole,ch=0)
    yf=y-w/2-0.0045
    for k in range(5):   # lugs on the visible sole edge
        xx=x+(-0.11+k*0.065)*s_
        _q(b,[(xx-0.012,yf-0.0005,z-0.025),(xx+0.012,yf-0.0005,z-0.025),(xx+0.012,yf-0.0005,z-0.012),(xx-0.012,yf-0.0005,z-0.012)],'stand_blk',(0,-1,0))
    # toe cap seam + heel counter
    _q(b,[(x+0.10*s_,y-w/2-0.0006,z+0.004),(x+0.108*s_,y-w/2-0.0006,z+0.004),(x+0.108*s_,y-w/2-0.0006,z+0.088),(x+0.10*s_,y-w/2-0.0006,z+0.088)][::s_],'walnut_dk',(0,-1,0))
    b.box((x-0.07*s_,y,z+0.235),(0.08,w+0.006,0.026),'leather_br' if key!='leather_br' else 'walnut_dk',ch=0)   # collar pad
    for k in range(5):   # brass eyelets along the lace line (visible side)
        t=k/4.0; ex=x+(0.035-0.05*t)*s_; ez=z+0.10+0.13*t
        _q(b,[(ex-0.006,y-w/2-0.0008,ez-0.006),(ex+0.006,y-w/2-0.0008,ez-0.006),(ex+0.006,y-w/2-0.0008,ez+0.006),(ex-0.006,y-w/2-0.0008,ez+0.006)],'brass',(0,-1,0))
    _q(b,[(x-0.125*s_,y-0.012,z+0.25),(x-0.125*s_,y+0.012,z+0.25),(x-0.135*s_,y+0.012,z+0.28),(x-0.135*s_,y-0.012,z+0.28)],'walnut_dk',(-s_,0,0.3))   # pull tab
    for k in range(4):   # laces across the instep slope
        t=k/3.5; px=0.03-0.045*t; pz=0.11+0.12*t
        cx=x+px*s_; cz=z+pz+0.004
        _q(b,[(cx-0.01,y-w*0.32,cz),(cx+0.01,y-w*0.32,cz),(cx+0.01,y+w*0.32,cz),(cx-0.01,y+w*0.32,cz)],'lace',(0,0,1))
def boot_display_wall(b, hi=False):
    """workwear boot wall: oak back panel with three angled acrylic-lipped shelves, eight work boots (tan and
    brown leather, black or honey soles) shown in side profile, size sign."""
    W,H=1.40,1.20; yb=0.14; z0=0.40
    b.box((0,yb-0.01,z0),(W,0.02,H),'oak')
    for sx in (-1,1): b.box((sx*(W/2+0.01),yb-0.15,z0),(0.02,0.30,H),'walnut')
    ks=[('leather_tan','sole_y'),('leather_br','sole'),('leather_tan','sole'),('sl_3','sole'),('leather_br','sole_y'),('leather_tan','sole_y'),('sl_3','sole_y'),('leather_br','sole')]
    i=0
    for k,z in enumerate((z0+0.05,z0+0.45,z0+0.85)):
        b.box((0,yb-0.15,z-0.02),(W,0.28,0.02),'walnut')
        b.box((0,yb-0.29,z),(W,0.008,0.03),'glass',ch=0)
        for x in ((-0.46,-0.18,0.18,0.46) if k!=1 else (-0.32,0.32)):
            if i>=len(ks): break
            key,sole=ks[i]; i+=1
            boot(b,x,yb-0.16,z+0.025,key,sole,hi,mirror=(x<0))
    b.box((W/2-0.16,yb-0.021,z0+H-0.12),(0.22,0.002,0.10),'label' if hi else 'boot_sign',ch=0)
    if hi:
        import pg as _pg
        _pg.add_text(b,'WORK BOOTS',0.035,(W/2-0.16,yb-0.0225,z0+H-0.07),(1,0,0),(0,0,1),0.0015,'paint_black')
    b.cbox((0,yb-0.15,z0),(W+0.04,0.30,H))

# ------------------------------------------------------------------ tshirt_wall
def tee(b, x, z, yb, key, prt, hi):
    O=[(-0.12,0.0),(0.12,0.0),(0.12,0.36),(0.20,0.30),(0.25,0.38),(0.15,0.48),(0.05,0.48),(0.0,0.45),(-0.05,0.48),(-0.15,0.48),(-0.25,0.38),(-0.20,0.30),(-0.12,0.36)]
    y0=yb-0.02-0.012
    pts=[(x+px,z+pz) for px,pz in O]
    for poly in ([0,1,2,6,7,8,12],[2,3,4,5,6],[8,9,10,11,12]):
        _q(b,[V(pts[i][0],y0,pts[i][1]) for i in poly],key,(0,-1,0))
    for i in range(len(O)):
        j=(i+1)%len(O); a,c=pts[i],pts[j]
        _q(b,[V(a[0],y0,a[1]),V(c[0],y0,c[1]),V(c[0],y0+0.012,c[1]),V(a[0],y0+0.012,a[1])],key,(c[1]-a[1],0,-(c[0]-a[0])))
    _q(b,[V(x-0.07,y0-0.0008,z+0.20),V(x+0.07,y0-0.0008,z+0.20),V(x+0.07,y0-0.0008,z+0.33),V(x-0.07,y0-0.0008,z+0.33)],prt,(0,-1,0))
    _q(b,[V(x-0.05,y0-0.0012,z+0.235),V(x+0.05,y0-0.0012,z+0.235),V(x+0.05,y0-0.0012,z+0.26),V(x-0.05,y0-0.0012,z+0.26)],'mag_white' if prt!='mag_white' else 'sl_3',(0,-1,0))
def tshirt_wall(b, hi=False):
    """souvenir shop tee wall: white grid panel, nine shirts pinned flat in three rows (bright colours with chest
    prints), folded stock in cubbies below, size strip."""
    W,H=1.50,2.00; yb=0.18; z0=0.0
    b.box((0,yb-0.01,0.45),(W,0.02,H-0.45),'paint_white')
    for sx in (-1,1): b.box((sx*(W/2-0.01),yb-0.18,0),(0.02,0.36,H),'oak')
    # cubbies
    b.box((0,yb-0.18,0),(W,0.36,0.04),'oak'); b.box((0,yb-0.18,0.43),(W,0.36,0.02),'oak'); b.box((0,yb-0.18,0.22),(W-0.04,0.36,0.02),'oak')
    for x in (-0.25,0.25): b.box((x,yb-0.18,0.04),(0.02,0.36,0.39),'oak')
    cols=['ts_0','ts_1','ts_2','ts_3','ts_4','ts_5','ts_6','ts_7','ts_1']
    prints=['mag_white','sl_2','sl_0','sl_2','sl_1','mag_white','sl_3','mag_white','sl_4']
    for r,zr in enumerate((1.48,1.00,0.52)):
        for cidx in range(3):
            i=r*3+cidx; tee(b,-0.48+cidx*0.48,zr,yb,cols[i],prints[i],hi)
    for i,x in enumerate((-0.50,0.0,0.50)):
        for zz in (0.045,0.245):
            b.box((x,yb-0.20,zz),(0.40,0.28,0.15),cols[(i*2+int(zz*10))%8],ch=0)
            _q(b,[(x-0.20,yb-0.3408,zz+0.05),(x+0.20,yb-0.3408,zz+0.05),(x+0.20,yb-0.3408,zz+0.053),(x-0.20,yb-0.3408,zz+0.053)],'slot_dk',(0,-1,0))
            _q(b,[(x-0.20,yb-0.3408,zz+0.10),(x+0.20,yb-0.3408,zz+0.10),(x+0.20,yb-0.3408,zz+0.103),(x-0.20,yb-0.3408,zz+0.103)],'slot_dk',(0,-1,0))
    b.box((0,yb-0.03,H-0.02),(W,0.04,0.14),'paint_navy')
    b.box((0,yb-0.051,H-0.005),(0.56,0.002,0.11),'tee_sign' if not hi else 'paint_navy',ch=0)
    if hi:
        import pg as _pg
        _pg.add_text(b,'T-SHIRTS',0.09,(0,yb-0.0525,H+0.05),(1,0,0),(0,0,1),0.0015,'label')
    b.cbox((0,yb-0.18,0),(W,0.36,H+0.12))

# ------------------------------------------------------------------ postcard_rack
def postcard_rack(b, hi=False):
    """souvenir postcard spinner: black wire tower on a round base, four faces x five tiers of postcard pockets,
    cards printed (photo label) with coloured borders, a 'POSTCARDS' header."""
    H=1.55; n=sg(hi,10,16)
    b.tube((0,0,0),(0,0,0.03),0.24,0.24,n,'stand_blk',cap0=False,cap1=True)
    b.tube((0,0,0.03),(0,0,H),0.012,0.012,6,'chrome',cap0=False,cap1=True)
    keys=['sl_1','sl_0','sl_5','sl_2','sl_6','sl_7']
    for f in range(4):
        a=math.pi/2*f; nx,ny=-math.sin(a),-math.cos(a)   # face normal (f=0 faces -Y)
        rx,ry=math.cos(a),-math.sin(a)
        def P(u,v,d): return V(rx*u+nx*d, ry*u+ny*d, v)
        _q(b,[P(-0.16,0.35,0.10),P(0.16,0.35,0.10),P(0.16,H-0.15,0.10),P(-0.16,H-0.15,0.10)],'stand_blk',(nx,ny,0))
        for t in range(5):
            z=0.40+t*0.20
            for c in range(2):
                u=-0.08+c*0.16
                _q(b,[P(u-0.072,z,0.12),P(u+0.072,z,0.12),P(u+0.072,z+0.105,0.11),P(u-0.072,z+0.105,0.11)],keys[(f*3+t*2+c)%6],(nx,ny,0.1))
                _q(b,[P(u-0.062,z+0.01,0.1205),P(u+0.062,z+0.01,0.1205),P(u+0.062,z+0.095,0.1105),P(u-0.062,z+0.095,0.1105)],'label' if hi else 'mag_white',(nx,ny,0.1))
                _q(b,[P(u-0.075,z-0.005,0.13),P(u+0.075,z-0.005,0.13),P(u+0.075,z+0.03,0.13),P(u-0.075,z+0.03,0.13)],'wire',(nx,ny,0))   # pocket lip
    b.box((0,0,H-0.14),(0.34,0.34,0.12),'lotto_yel')
    b.box((0,-0.171,H-0.12),(0.30,0.002,0.08),'post_sign' if not hi else 'paint_navy',ch=0)
    if hi:
        import pg as _pg
        _pg.add_text(b,'POSTCARDS',0.045,(0,-0.1725,H-0.08),(1,0,0),(0,0,1),0.0015,'label')
    b.ccyl((0,0,0),0.24,H)

# ------------------------------------------------------------------ display_plinth
def display_plinth(b, hi=False):
    """gallery plinth: matt white box with a recessed black shadow-gap base, a bronze abstract sculpture
    (twisted ribbon on a short stem) and a small wall-text card on the face."""
    W,H=0.45,1.00
    b.box((0,0,0),(W-0.04,W-0.04,0.06),'paint_black',skip=('bottom',))
    b.box((0,0,0.06),(W,W,H-0.06),'plinth')
    b.tube((0,0,H),(0,0,H+0.10),0.012,0.012,sg(hi,6,12),'bronze',cap0=False,cap1=False)
    b.box((0,0,H),(0.12,0.12,0.02),'bronze')
    # twisted ribbon: a swept band rotating as it rises
    nseg=sg(hi,8,16); prev=None
    for i in range(nseg+1):
        t=i/nseg; a=2.4*t; r=0.10*math.sin(math.pi*t)+0.02; z=H+0.10+0.38*t
        c=V(r*math.cos(a*1.3),r*math.sin(a*1.3),z); d=V(math.cos(a),math.sin(a),0)*0.07
        cur=(c-d,c+d)
        if prev:
            nn=((prev[1]-prev[0]).cross(cur[0]-prev[0])).normalized(); o=nn*0.004
            _q(b,[prev[0]+o,prev[1]+o,cur[1]+o,cur[0]+o],'bronze',tuple(nn))
            _q(b,[prev[1]-o,prev[0]-o,cur[0]-o,cur[1]-o],'bronze',tuple(-nn))
            for e0 in (0,1):
                _q(b,[prev[e0]+o,cur[e0]+o,cur[e0]-o,prev[e0]-o],'bronze',tuple((prev[e0]-prev[1-e0]).normalized()))
        prev=cur
    b.box((0.10,-W/2-0.001,H-0.18),(0.09,0.002,0.06),'label',ch=0)
    b.cbox((0,0,0),(W,W,H+0.5))

# ------------------------------------------------------------------ foot_measure_stool
def foot_measure_stool(b, hi=False):
    """shoe-shop fitting stool: walnut box stool on a recessed black plinth, tufted red vinyl seat with piping,
    sloped fitting ramp at the front with a ribbed rubber mat and a chrome nosing, a metal Brannock-style
    foot measure on the ramp, shoehorn hanging on a cord."""
    W=0.42; yc=0.07
    b.box((0,yc,0),(W-0.04,0.28,0.035),'paint_black',skip=('bottom',))                # shadow-gap plinth
    b.box((0,yc,0.035),(W,0.32,0.265),'walnut')
    b.box((0,yc,0.30),(W+0.02,0.34,0.065),'vinyl_red')
    b.box((0,yc,0.296),(W+0.026,0.346,0.008),'walnut_dk',ch=0)                       # piping
    for bx_ in (-0.10,0.10):                                                          # tufting buttons
        _q(b,[(bx_-0.012,yc-0.012,0.3655),(bx_+0.012,yc-0.012,0.3655),(bx_+0.012,yc+0.012,0.3655),(bx_-0.012,yc+0.012,0.3655)],'walnut_dk',(0,0,1))
    # ramp: walnut cheeks + sloped deck from z=0.07 at the front to 0.22 at the stool face
    y0,y1=-0.33,-0.09; zf,zb=0.07,0.22; hw=0.18
    for sx in (-1,1):
        P=[V(sx*hw,y1,0.0),V(sx*hw,y0,0.0),V(sx*hw,y0,zf),V(sx*hw,y1,zb)]
        _q(b,P,'walnut',(sx,0,0))
    _q(b,[V(-hw,y0,0.0),V(hw,y0,0.0),V(hw,y0,zf),V(-hw,y0,zf)],'walnut',(0,-1,0))
    _q(b,[V(-hw,y0,zf),V(hw,y0,zf),V(hw,y1,zb),V(-hw,y1,zb)],'walnut',(0,-0.53,0.85))
    t=math.atan2(zb-zf,y1-y0); nv=V(0,-math.sin(t),math.cos(t)); al=V(0,math.cos(t),math.sin(t))
    o=V(0,y0,zf)
    def P(u,v,w=0.0): return o+V(u,0,0)+al*v+nv*w
    Ls=math.hypot(zb-zf,y1-y0)
    _q(b,[P(-hw+0.015,0.03,0.002),P(hw-0.015,0.03,0.002),P(hw-0.015,Ls-0.01,0.002),P(-hw+0.015,Ls-0.01,0.002)],'rubber',tuple(nv))
    for k in range(6 if hi else 4):                                                     # mat ribs
        v=0.05+k*(Ls-0.08)/(5 if hi else 3)
        _q(b,[P(-hw+0.02,v,0.0035),P(-0.075,v,0.0035),P(-0.075,v+0.006,0.0035),P(-hw+0.02,v+0.006,0.0035)],'steel_dk',tuple(nv))
        _q(b,[P(0.075,v,0.0035),P(hw-0.02,v,0.0035),P(hw-0.02,v+0.006,0.0035),P(0.075,v+0.006,0.0035)],'steel_dk',tuple(nv))
    b.tube(V(-hw,y0+0.004,zf+0.002),V(hw,y0+0.004,zf+0.002),0.009,0.009,sg(hi,5,10),'chrome',cap0=True,cap1=True)   # nosing
    # Brannock device on the ramp centre
    _q(b,[P(-0.06,0.04,0.006),P(0.06,0.04,0.006),P(0.06,0.25,0.006),P(-0.06,0.25,0.006)],'brannock',tuple(nv))
    for k in range(10 if hi else 6):
        v=0.07+k*(0.016 if hi else 0.027)
        _q(b,[P(-0.052,v,0.0065),P(-0.022 if k%2 else -0.032,v,0.0065),P(-0.022 if k%2 else -0.032,v+0.003,0.0065),P(-0.052,v+0.003,0.0065)],'paint_black',tuple(nv))
    hc=P(0,0.045,0.006); b.box((hc.x,hc.y,hc.z),(0.12,0.018,0.028),'brannock',rx=t)    # heel cup
    sl=P(0.055,0.17,0.006); b.box((sl.x,sl.y,sl.z),(0.016,0.035,0.016),'brannock',rx=t)  # width slider
    _q(b,[P(0.0,0.12,0.0063),P(0.045,0.12,0.0063),P(0.045,0.21,0.0063),P(0.0,0.21,0.0063)],'paint_black' if not hi else 'brannock',tuple(nv))
    # shoehorn on a cord from the seat side
    b.sweep([V(W/2+0.01,0.08,0.33),V(W/2+0.03,0.06,0.26),V(W/2+0.025,0.05,0.17)],0.002,3,'stand_blk',cap0=False,cap1=False)
    b.box((W/2+0.026,0.05,0.05),(0.004,0.04,0.12),'brass',ch=0)
    b.box((0.0,yc+0.161,0.14),(0.08,0.002,0.025),'badge',ch=0)
    b.cbox((0,yc,0),(W+0.03,0.35,0.37)); b.cbox((0,-0.21,0),(2*hw,0.24,0.20))

# ------------------------------------------------------------------ registry
_C=dict(dir='props/indoor/retailfx',pdir='indoor_retailfx',trim=TR,trim_tint=TINT,page='i',
        conds=['clean'],cat='prop',max_side=80,bevel=0.003)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d
W_=dict(cage=0.04,ray=0.12)
PROPS=[
    _p('shopping_basket_stack',shopping_basket_stack,'small',600,**W_),
    _p('lottery_atm_stand',lottery_atm_stand,'medium',1200,side=96,**W_),
    _p('magazine_rack',magazine_rack,'medium',1200,side=80,shift=(0.0,0.071)),
    _p('wetsuit_rack',wetsuit_rack,'medium',1200),
    _p('helmet_wall',helmet_wall,'medium',1200,mount='wall',shift=(0.0,0.096),**W_),
    _p('folded_stack_table',folded_stack_table,'medium',1100),
    _p('bargain_bin',bargain_bin,'medium',1100,**W_),
    _p('flower_bucket_stand',flower_bucket_stand,'medium',1200),
    _p('shopping_cart',shopping_cart,'medium',1100,shift=(-0.071,0.0)),
    _p('security_mirror',security_mirror,'small',400,mount='wall'),
    _p('candle_shelf',candle_shelf,'medium',1200),
    _p('herb_jar_wall',herb_jar_wall,'medium',1200,mount='wall'),
    _p('guitar_wall',guitar_wall,'medium',1200,mount='wall'),
    _p('tv_electronics_stack',tv_electronics_stack,'medium',1200,shift=(0.010,-0.069)),
    _p('phone_display_table',phone_display_table,'medium',1200),
    _p('skateboard_deck_wall',skateboard_deck_wall,'medium',1200,mount='wall'),
    _p('boot_display_wall',boot_display_wall,'medium',1200,mount='wall',**W_),
    _p('tshirt_wall',tshirt_wall,'medium',1200,side=80,mount='wall'),
    _p('postcard_rack',postcard_rack,'small',600,**W_),
    _p('display_plinth',display_plinth,'small',400),
    _p('foot_measure_stool',foot_measure_stool,'small',500),
]
INDOOR_LOOK=True
