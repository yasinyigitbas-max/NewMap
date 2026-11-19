"""House carpets and rugs — page H, near+col only, walkable thin collision.

Eight floor pieces. Origin at the footprint centre, underside on y=0.
Patterns live in the page-H reserve at y=192–255. Game should ignore
the thin collision for the player (manifest walkable=True).
"""
import math
from mathutils import Vector

def sg(hi, lo, hi_n):
    return hi_n if hi else lo

def maker_plate(b, c, hi=False, w=0.05, h=0.012, rz=0.0, key='badge'):
    b.box(c,(w,0.005,h),key,rz=rz)

def fringe_y(b, W, D, H, n, length=0.06, key='jute'):
    """Short fringe along the ±Y edges (short sides of a rectangle in XY)."""
    # builder space: X width, Y depth, Z up
    w=W/max(n,1)
    for sign in (-1,1):
        y=sign*(D*0.5+length*0.35)
        for i in range(n):
            x=-W*0.5 + (i+0.5)*w
            # slightly irregular length
            L=length*(0.85+0.15*((i*7)%5)/5)
            b.box((x, y - sign*L*0.15, 0.0), (max(0.010,w*0.55), L, max(0.006,H*0.55)), key)

def fringe_x(b, W, D, H, n, length=0.06, key='jute'):
    """Fringe along the ±X edges (for a runner whose ends are the short X sides)."""
    w=D/max(n,1)
    for sign in (-1,1):
        x=sign*(W*0.5+length*0.35)
        for i in range(n):
            y=-D*0.5 + (i+0.5)*w
            L=length*(0.85+0.15*((i*7)%5)/5)
            b.box((x - sign*L*0.15, y, 0.0), (L, max(0.010,w*0.55), max(0.006,H*0.55)), key)

def bound_rect(b, W, D, H, t=0.04, key='bind'):
    """Slightly raised bound edge around a rectangular rug."""
    bh=H+0.004
    b.box((0, -(D*0.5)+t*0.5, 0.0), (W, t, bh), key)
    b.box((0,  (D*0.5)-t*0.5, 0.0), (W, t, bh), key)
    b.box((-(W*0.5)+t*0.5, 0, 0.0), (t, D-2*t, bh), key)
    b.box(( (W*0.5)-t*0.5, 0, 0.0), (t, D-2*t, bh), key)

def slab(b, W, D, H, key, decal=False, side=None):
    """Padded field: top face is the pattern, sides are pile or a bind."""
    side=side or ('bind' if decal else key)
    keys={f:side for f in ('front','back','left','right')}
    keys['top']=key
    b.box((0,0,0.0),(W,D,H), side, skip=('bottom',),
          decal=({'top':key} if decal else None), keys=keys)

def disc_rug(b, R, H, n, key, decal=True):
    """Round rug with a vertical pile wall and a bound rim."""
    n=max(n,12)
    # top + bottom rings
    top=[Vector((R*math.cos(2*math.pi*i/n), R*math.sin(2*math.pi*i/n), H)) for i in range(n)]
    bot=[Vector((R*math.cos(2*math.pi*i/n), R*math.sin(2*math.pi*i/n), 0.0)) for i in range(n)]
    # top cap, UVs in a circle 0-1
    c=Vector((0,0,H))
    luv_cap=[[(0.5,0.5),
              (0.5+0.5*math.cos(2*math.pi*i/n), 0.5+0.5*math.sin(2*math.pi*i/n)),
              (0.5+0.5*math.cos(2*math.pi*(i+1)/n), 0.5+0.5*math.sin(2*math.pi*(i+1)/n))] for i in range(n)]
    b.faces([c]+top, [(0,i+1,1+((i+1)%n)) for i in range(n)], key, luv_cap, decal=decal)
    # side wall
    for i in range(n):
        j=(i+1)%n
        b.quad([bot[i], bot[j], top[j], top[i]], key)
    # bound rim (slightly proud ring on the top)
    r0,r1=R*0.92, R+0.012
    for i in range(n):
        a0=2*math.pi*i/n; a1=2*math.pi*(i+1)/n
        p=[Vector((r0*math.cos(a0), r0*math.sin(a0), H+0.003)),
           Vector((r1*math.cos(a0), r1*math.sin(a0), H+0.003)),
           Vector((r1*math.cos(a1), r1*math.sin(a1), H+0.003)),
           Vector((r0*math.cos(a1), r0*math.sin(a1), H+0.003))]
        b.quad(p, 'bind')

def oval_rug(b, W, D, H, n, key):
    """Elliptical shag with a slightly soft, lower pile edge."""
    n=max(n,16)
    rx,ry=W*0.5, D*0.5
    top=[Vector((rx*math.cos(2*math.pi*i/n), ry*math.sin(2*math.pi*i/n), H)) for i in range(n)]
    # skirt sits a little outside and lower so the rim reads as a soft pile falloff
    s=1.045
    skirt=[Vector((rx*s*math.cos(2*math.pi*i/n), ry*s*math.sin(2*math.pi*i/n), H*0.32)) for i in range(n)]
    bot=[Vector((rx*s*math.cos(2*math.pi*i/n), ry*s*math.sin(2*math.pi*i/n), 0.0)) for i in range(n)]
    c=Vector((0,0,H))
    luv=[[(0,0),(top[i].x,top[i].y),(top[(i+1)%n].x,top[(i+1)%n].y)] for i in range(n)]
    b.faces([c]+top, [(0,i+1,1+((i+1)%n)) for i in range(n)], key, luv)
    for i in range(n):
        j=(i+1)%n
        b.quad([top[i], top[j], skirt[j], skirt[i]], key)
        b.quad([bot[i], bot[j], skirt[j], skirt[i]], key)

# ------------------------------------------------------------------ props

def rug_living_mcm(b, hi=False):
    W,D,H=2.40,1.70,0.025
    slab(b,W-0.08,D-0.08,H,'mcm', decal=True)
    bound_rect(b,W,D,H,0.04,'bind')
    fringe_y(b,W*0.96,D,H, sg(hi,10,12), 0.07, 'fringe')
    maker_plate(b,(0,0,0.001),hi,w=0.06,h=0.012)
    b.cbox((0,0,0),(W+0.08,D+0.10,max(H,0.02)))

def rug_living_jute(b, hi=False):
    W,D,H=2.00,1.40,0.020
    slab(b,W,D,H,'jute')
    # stitched edge: thin darker bind, no fringe
    bound_rect(b,W,D,H,0.025,'bind')
    maker_plate(b,(0,0,0.001),hi,w=0.05,h=0.010)
    b.cbox((0,0,0),(W,D,max(H,0.02)))

def rug_motel_floral(b, hi=False):
    W,D,H=1.80,1.20,0.020
    # tiled floral field; wine/gold bind carries the border so the tile can be sharp
    slab(b,W-0.08,D-0.08,H,'floral')
    bound_rect(b,W,D,H,0.04,'floral_bind')
    maker_plate(b,(0,0,0.001),hi,w=0.05,h=0.010)
    b.cbox((0,0,0),(W,D,max(H,0.02)))

def rug_runner(b, hi=False):
    W,D,H=2.40,0.70,0.018
    slab(b,W-0.02,D,H,'runner')
    bound_rect(b,W-0.02,D,H,0.022,'bind')
    # fringe on the short ends (X)
    fringe_x(b,W-0.02,D,H, sg(hi,8,10), 0.08, 'fringe')
    maker_plate(b,(0,0,0.001),hi,w=0.04,h=0.010)
    b.cbox((0,0,0),(W+0.10,D,max(H,0.02)))

def rug_accent(b, hi=False):
    W,D,H=1.20,0.80,0.018
    slab(b,W,D,H,'accent', decal=True)
    bound_rect(b,W,D,H,0.030,'bind')
    maker_plate(b,(0,0,0.001),hi,w=0.04,h=0.010)
    b.cbox((0,0,0),(W,D,max(H,0.02)))

def rug_round(b, hi=False):
    R,H=0.75,0.020
    disc_rug(b,R,H, sg(hi,20,28), 'round', decal=True)
    maker_plate(b,(0,0,0.001),hi,w=0.04,h=0.010)
    b.ccyl((0,0,0), R+0.012, H+0.004)

def bath_mat(b, hi=False):
    W,D,H=0.80,0.50,0.025
    slab(b,W-0.04,D-0.04,H,'terry')
    # hem
    bound_rect(b,W,D,H,0.022,'hem')
    maker_plate(b,(0,0,0.001),hi,w=0.035,h=0.008)
    b.cbox((0,0,0),(W,D,max(H,0.02)))

def rug_shag_oval(b, hi=False):
    W,D,H=1.60,1.10,0.040
    oval_rug(b,W,D,H, sg(hi,24,32), 'shag')
    maker_plate(b,(0,0,0.001),hi,w=0.04,h=0.010)
    # thin box collision (game walkable); slightly larger than the oval
    b.cbox((0,0,0),(W,D,max(H,0.02)))

# ------------------------------------------------------------------ materials

PM=(0.50,0.50)  # unused default; each rug key sets its own period below
TR={
    'mcm':    ('tr_rug_mcm',    (2.32, 1.62)),
    'jute':   ('tr_rug_jute',   (0.40, 0.40)),
    'floral': ('tr_rug_floral', (0.45, 0.40)),
    'floral_bind': ('th_walnut', (0.875, 0.875)),
    'runner': ('tr_rug_runner', (0.70, 0.35)),
    'accent': ('tr_rug_accent', (1.20, 0.80)),
    'round':  ('tr_rug_round',  (1.50, 1.50)),
    'terry':  ('tr_rug_terry',  (0.25, 0.25)),
    'shag':   ('tr_rug_shag',   (0.40, 0.40)),
    # edges / fringe / hem / plate
    'bind':   ('th_walnut', (0.875, 0.875)),
    'fringe': ('th_linen',  (0.875, 0.875)),
    'hem':    ('th_linen',  (0.875, 0.875)),
}
TINT={
    'mcm':(1,1,1),'jute':(1,1,1),'floral':(1,1,1),'runner':(1,1,1),
    'accent':(1,1,1),'round':(1,1,1),'terry':(1,1,1),'shag':(1,1,1),
    'bind':(0.28,0.16,0.12),'fringe':(0.85,0.76,0.56),'hem':(0.90,0.88,0.82),
    'badge':(1,1,1),
}

INDOOR_LOOK=True

_C=dict(dir='props/house/rugs',pdir='house_rugs',trim=TR,trim_tint=TINT,page='h',
        conds=['clean'],cat='prop',max_side=80,bevel=0.002,walkable=True,no_ch=True)
def _p(name,fn,cls,budget=None,**kw):
    d=dict(_C,name=name,near=lambda b,fn=fn: fn(b,False),high=lambda b,fn=fn: fn(b,True),cls=cls,**kw)
    if budget is not None: d['budget']=budget
    return d

PROPS=[
    _p('rug_living_mcm',   rug_living_mcm,   'small', 480),  # raised from 450; fringe, still under cap 600
    _p('rug_living_jute',  rug_living_jute,  'small', 400),
    _p('rug_motel_floral', rug_motel_floral, 'small', 400),
    _p('rug_runner',       rug_runner,       'small', 350),
    _p('rug_accent',       rug_accent,       'tiny',  250),
    _p('rug_round',        rug_round,        'small', 450),
    _p('bath_mat',         bath_mat,         'tiny',  200),
    _p('rug_shag_oval',    rug_shag_oval,    'small', 450),
]
