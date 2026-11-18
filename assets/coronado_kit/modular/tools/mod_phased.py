"""Phase D snap-in pieces (city atlas). Loose pieces are editor-only; ship merged assemblies.
Brick downtown bays, warehouse bays, service fronts, apartment / boarded bays, self-storage units,
and a 10-storey office tower bay. Front = +Z; origin = bottom centre of the footprint."""
import numpy as np
from mod_core import *

# city floor / storey (same language as tools/city_urban.py)
UFL=0.3; UST=3.0
T_U=0.30          # typical wall slab
T_F=0.45          # shop-like front slab (recessed door)
BRK=(1.0,1.0,1.0); WHITE=(0.97,0.96,0.93); GREY=(0.82,0.82,0.80)
CREAM=(0.93,0.86,0.72); WARM=(0.92,0.86,0.78); GT=(0.45,0.38,0.31)
X,Y,Z=0,1,2
WH_H=6.6; WH_PAR=0.8; WH_D=24.0; WH_W=12.0
SVC_H=4.2; SVC_PAR=0.9; SVC_D=12.0
APT_D=12.0
TWR_STY=10; TWR_W=8.0; TWR_D=20.0
TWR_H=UFL+TWR_STY*UST; TWR_PAR=0.9

def _tri_prism(s,tier,x0,x1,y0,y1,z0,z1,top=None,side=None,bottom=None,
               tiers=('near','mid'),meta=None,name='tri',overlay=False,**kw):
    """Triangular prism in XY: base x0..x1 at y0, peak at mid-x, y1; extruded z0..z1."""
    if tier not in tiers: return []
    from geom import Solid
    hw=0.5*(x1-x0); xm=0.5*(x0+x1); H=max(y1-y0,1e-6)
    pl=[]; rl=[]
    pl.append(((0.0,0.0,1.0), float(z1))); rl.append(side)
    pl.append(((0.0,0.0,-1.0), float(-z0))); rl.append(side)
    pl.append(((0.0,-1.0,0.0), float(-y0))); rl.append(bottom)
    # left rake through (x0,y0) and (xm,y1), outward to -X
    nl=np.array([-H, hw, 0.0], float); nl=nl/(np.linalg.norm(nl)+1e-12)
    pl.append((tuple(nl), float(nl[0]*x0+nl[1]*y0))); rl.append(side)
    # right rake through (x1,y0) and (xm,y1), outward to +X
    nr=np.array([ H, hw, 0.0], float); nr=nr/(np.linalg.norm(nr)+1e-12)
    pl.append((tuple(nr), float(nr[0]*x1+nr[1]*y0))); rl.append(side)
    so=Solid(pl,rl,name)
    if overlay: so.nocut=True; so.overlay=True
    return [(so,rl, meta or {'type':'trim'})]
from build import Building
Building._tri_prism=_tri_prism


def wn(k,c,lvl,w=1.0,h=1.4,sill=0.9,fl=UFL,st=UST,**kw):
    t0=round(fl+lvl*st+sill,3); return dict(k=k,c=round(c,3),w=w,t0=t0,t1=round(t0+h,3),**kw)
def dr(k,c,lvl,w=1.0,h=2.2,fl=UFL,st=UST,**kw):
    t0=round(fl+lvl*st,3); return dict(k=k,c=round(c,3),w=w,t0=t0,t1=round(t0+h,3),**kw)

def slab(name,w,depth,H,ops,cls,budget,wall,tint,parapet=0.9,parapet_sides=('front',),foundation=False,sills=False,extra=None,no_door=True,**bkw):
    """open-ended wall slab: drop left/right ends, the back, and the plate (parapet/roof sit on top)."""
    b=Piece(name,cls,snap=None,drop=[(X,-w/2,-1),(X,w/2,1),(Z,-depth,-1),(Y,H,1)],budget=budget,wall=wall,tint=tint,
            roof='R_flat',trim=(0.95,0.94,0.90),style='modular')
    b.floor=UFL; b.floor_lines=[UFL+UST*i for i in range(1, max(1,int(round((H-UFL)/UST)))+1)]
    b.abuts_all=True; b.no_door=no_door
    b.add('block',x0=-w/2,x1=w/2,z0=-depth,z1=0.0,W=H,roof='flat',parapet=parapet,parapet_sides=parapet_sides,cap='T_white',
          gutters=False,openings={'front':ops},sills=sills,sill_tint=(0.95,0.94,0.90),foundation=foundation,**bkw)
    if extra: extra(b,w)
    b.snap={'grid':GRID,'module':w,'type':cls,'ends':[[-w/2,0,depth/2],[w/2,0,depth/2]],'face_z':depth/2,'plate_y':H,
            'parapet_top':H+parapet}
    return b
# far-atlas facade stamps (same bake merge_assembly uses). far_color is full; these are shared strips.
FAR_GLASS=dict(far_facade='F_c_glass_3', far_tile=3.0)
FAR_TOWER=dict(far_facade='F_c_tower_3', far_tile=3.0)
FAR_SHOP=dict(far_facade='F_c_shop_1', far_u0=-3.0)
FAR_SHOP2=dict(far_facade='F_c_shop_2')
FAR_BRICK=dict(far_facade='F_c_brick_3', far_tile=3.0)
FAR_APT=dict(far_facade='F_c_apt_3')
FAR_BLANK=dict(far_facade='F_stucco_blank', far_tile=3.0)
FAR_STUCCO=dict(far_facade='F_stucco_2')
# F_c_tower_3 is a shared cream city stamp; office mid is charcoal, so tint only the far hull.
FAR_OFFICE=dict(far_facade='F_c_tower_3', far_tile=3.0, far_tint=(0.44,0.45,0.48))


# ------------------------------------------------------------------ brick downtown (3 / 4 storey, 6 m bay)
def brk_front(storeys=3,tag='shop'):
    w=6.0; H=UFL+storeys*UST
    door_c=1.9; shop_c=-0.8
    ops=[dict(k='shopdoor',c=door_c,w=1.6,t0=0.0,t1=3.0,depth=0.35),
         dict(k='storefront',c=shop_c,w=3.2,t0=0.0,t1=3.0,depth=0.12)]
    for lv in range(1,storeys):
        ops+=[wn('dh_div',-1.4,lv,w=1.2,h=1.5,sill=0.8),wn('dh_div',1.4,lv,w=1.2,h=1.5,sill=0.8)]
    aw=('AW_red','AW_green','AW_navy')[storeys%3]
    def ex(b,w_):
        b.add('awning',side='front',wall=0.0,s0=-2.7,s1=2.7,y_top=3.15,depth=1.15,drop=0.45,region=aw)
        b.add('sign',side='front',wall=0.0,c=0.0,y=3.25,w=2.4,h=0.5,region='T_dark')
        b.add('gooseneck',side='front',wall=0.0,c=-1.8,y=4.15)
        b.add('gooseneck',side='front',wall=0.0,c=1.8,y=4.15)
    b=slab(f'urb_brk_front_6m_{storeys}sty',w,T_F,H,ops,'brk_front',(900,260,16), 'W_brick',BRK,parapet=1.0,sills=True,extra=ex,no_door=False,**FAR_BRICK)
    return b

def brk_side(storeys=3,depth=14.0):
    w=depth; H=UFL+storeys*UST
    ops=[]
    for lv in range(storeys):
        ops+=[wn('dh_div',-w/2+3.0,lv,w=1.2,h=1.5,sill=0.8),wn('dh_div',w/2-3.0,lv,w=1.2,h=1.5,sill=0.8)]
    ops.append(dict(k='vent',c=-w/2+0.5,t0=H-0.85,t1=H-0.45,w=0.6))
    def ex(b,w_):
        b.add('fixtures',side='front',wall=0.0,items=[('sconce',w_/2-1.2,2.3)])
    return slab(f'urb_brk_side_{int(depth)}m_{storeys}sty',w,T_U,H,ops,'brk_side',(700,200,16),'W_brick',BRK,parapet=1.0,sills=True,extra=ex,**FAR_BRICK)

def brk_back(storeys=3):
    w=6.0; H=UFL+storeys*UST
    ops=[dr('apt_door',0.0,0,w=1.0,h=2.2), wn('small',1.6,0,w=0.7,h=0.7,sill=1.5)]
    for lv in range(1,storeys):
        ops.append(wn('dh',0.0,lv,w=1.2,h=1.4,sill=0.9))
    def ex(b,w_):
        b.add('stoop',side='front',c=0.0,wall=0.0,w=1.6,depth=1.2)
        b.add('fixtures',side='front',wall=0.0,items=[('lamp',0.8,UFL+2.2),('meter',-2.2,1.0)])
    b=slab(f'urb_brk_back_6m_{storeys}sty',w,T_U,H,ops,'brk_back',(500,150,16),'W_brick',BRK,parapet=1.0,sills=True,extra=ex,no_door=False,**FAR_BRICK)
    return b

def brk_roof(storeys=3,depth=14.0):
    w=6.0; H=UFL+storeys*UST; xi=0.02
    # X ends stay open on the bay snap planes so adjacent decks and an end-bay parapet do not see a cap
    b=Piece(f'urb_brk_roof_6x{int(depth)}_{storeys}sty','brk_roof',snap=None,drop=[(X,-w/2+xi,-1),(X,w/2-xi,1)],budget=(180,60,8),wall='W_brick',tint=BRK,roof='R_flat',style='modular')
    b.floor=0.0; b.no_door=True; b.col_mode='bbox'
    TB={'t':'trim','mat':'T_white','tint':(0.92,0.92,0.9)}; RF={'t':'roof','mat':'R_flat','tint':(1,1,1),'flat_deck':True}
    # inset in X so adjacent bays do not share a face; inset in Z so the deck does not sit under the parapet
    b.add('box',x0=-w/2+xi,x1=w/2-xi,y0=H,y1=H+0.12,z0=-depth/2+0.25,z1=depth/2-0.25,top=RF,side=TB,bottom={'t':'swatch','mat':'S_soffit','tint':(0.9,0.9,0.88)},meta={'type':'roof'},drop=((1,0,0),(-1,0,0)))
    b.add('rtu',x=0.0,z=-2.0,y=H+0.12,w=1.2,d=0.9,h=0.7)
    b.origin=(0.0,0.0,w,depth); b.base_y=H
    b.snap={'grid':GRID,'type':'brk_roof','module':w,'depth':depth,'plate_y':H}
    return b

# ------------------------------------------------------------------ warehouse (12 m bay, 24 m depth, one tall storey)
def wh_front(kind='rollup'):
    w=WH_W; H=WH_H
    if kind=='rollup':
        ops=[dict(k='rollup',c=0.0,w=4.4,t0=0.0,t1=4.4),
             dict(k='steel',c=-4.2,w=1.2,t0=1.2,t1=2.6) if False else dict(k='casement',c=-4.2,w=1.2,t0=1.2,t1=2.6)]
        # 'steel' may not exist; casement is fine
        no_door=True  # rollup is a garage
    else:
        ops=[dict(k='apt_door',c=-3.6,w=1.0,t0=0.2,t1=2.4),
             dict(k='casement',c=-1.2,w=1.4,t0=1.0,t1=2.5),
             dict(k='casement',c=1.6,w=1.4,t0=1.0,t1=2.5),
             dict(k='casement',c=4.0,w=1.4,t0=1.0,t1=2.5)]
        no_door=False
    def ex(b,w_):
        b.add('sign',side='front',wall=0.0,c=0.0,y=5.0,w=4.0,h=0.5,region='T_dark')
        if kind=='office':
            b.add('stoop',side='front',c=-3.6,wall=0.0,w=1.6,depth=1.2,floor=0.2)
            b.add('fixtures',side='front',wall=0.0,items=[('sconce',-2.6,2.3),('sconce',-4.6,2.3)])
        else:
            b.add('fixtures',side='front',wall=0.0,items=[('sconce',-3.0,4.6),('sconce',3.0,4.6)])
    b=slab(f'urb_wh_front_12m_{kind}',w,T_F,H,ops,'wh_front',(600,180,12),'W_stucco',GREY,parapet=WH_PAR,sills=False,extra=ex,no_door=no_door,foundation=False,**FAR_STUCCO)
    if kind=='rollup': b.no_door=True
    else: b.no_door=False
    return b

def wh_side():
    w=WH_D; H=WH_H
    ops=[dict(k='casement',c=-8.0,w=1.4,t0=1.2,t1=2.8),dict(k='casement',c=0.0,w=1.4,t0=1.2,t1=2.8),
         dict(k='casement',c=8.0,w=1.4,t0=1.2,t1=2.8),dict(k='louver',c=-4.0,w=1.2,t0=4.4,t1=5.4),
         dict(k='louver',c=4.0,w=1.2,t0=4.4,t1=5.4)]
    def ex(b,w_):
        b.add('fixtures',side='front',wall=0.0,items=[('meter',-10.0,1.0),('sconce',10.5,2.4)])
    return slab('urb_wh_side_24m',w,T_U,H,ops,'wh_side',(550,160,12),'W_stucco',GREY,parapet=WH_PAR,sills=False,extra=ex,**FAR_STUCCO)

def wh_back():
    w=WH_W; H=WH_H
    ops=[dict(k='apt_door',c=-3.5,w=1.0,t0=0.2,t1=2.4),dict(k='rollup',c=2.0,w=3.6,t0=0.0,t1=4.0),
         dict(k='louver',c=-1.2,w=1.0,t0=4.6,t1=5.5)]
    def ex(b,w_):
        b.add('stoop',side='front',c=-3.5,wall=0.0,w=1.6,depth=1.2,floor=0.2)
        b.add('fixtures',side='front',wall=0.0,items=[('lamp',-2.5,2.3),('meter',-5.0,1.0)])
    return slab('urb_wh_back_12m',w,T_U,H,ops,'wh_back',(500,150,12),'W_stucco',GREY,parapet=WH_PAR,sills=False,extra=ex,no_door=False,**FAR_STUCCO)

def wh_roof():
    w=WH_W; d=WH_D; H=WH_H; xi=0.02
    b=Piece('urb_wh_roof_12x24','wh_roof',snap=None,drop=[(X,-w/2+xi,-1),(X,w/2-xi,1)],budget=(200,70,8),wall='W_stucco',tint=GREY,roof='R_flat',style='modular')
    b.floor=0.0; b.no_door=True; b.col_mode='bbox'
    TB={'t':'trim','mat':'T_white','tint':(0.9,0.9,0.88)}; RF={'t':'roof','mat':'R_flat','tint':(1,1,1),'flat_deck':True}
    b.add('box',x0=-w/2+xi,x1=w/2-xi,y0=H,y1=H+0.14,z0=-d/2+0.25,z1=d/2-0.25,top=RF,side=TB,bottom={'t':'swatch','mat':'S_soffit','tint':(0.9,0.9,0.88)},meta={'type':'roof'},drop=((1,0,0),(-1,0,0)))
    b.add('rtu',x=0.0,z=-6.0,y=H+0.14,w=1.6,d=1.1,h=0.9)
    b.add('roofvent',x=3.0,z=6.0,y=H+0.14,vk='stack')
    b.origin=(0.0,0.0,w,d); b.base_y=H
    b.snap={'grid':GRID,'type':'wh_roof','module':w,'depth':d,'plate_y':H}
    return b

# ------------------------------------------------------------------ service fronts (6 m, shop height; sides/roofs may come from the shops group)
def svc_front(tag, awning='AW_navy'):
    w=6.0; H=SVC_H; PIL=0.28
    ops=[dict(k='shopdoor',c=1.6,w=1.6,t0=0.0,t1=3.0,depth=0.35),
         dict(k='storefront',c=-1.2,w=3.2,t0=0.0,t1=3.0,depth=0.12)]
    def ex(b,w_):
        b.add('sign',side='front',wall=0.0,c=0.0,y=3.15,w=3.4,h=0.52,region='T_dark')
        b.add('awning',side='front',wall=0.0,s0=-2.6,s1=2.6,y_top=3.06,depth=1.1,drop=0.45,region=awning)
        b.add('fixtures',side='front',wall=0.0,items=[('sconce',-2.4,2.3),('sconce',2.4,2.3)])
        for c in (-w_/2+PIL/2+0.04,w_/2-PIL/2-0.04):
            b.add('pilaster',side='front',wall=0.0,c=c,y1=H+SVC_PAR-0.3,w=PIL)
    b=slab(f'urb_svc_front_6m_{tag}',w,T_F,H,ops,'svc_front',(650,200,12),'W_stucco',CREAM,parapet=SVC_PAR,sills=False,extra=ex,no_door=False,foundation=False,**FAR_SHOP)
    b.floor=0.0; b.floor_lines=[3.8]
    return b

def svc_front_fastfood():
    """drive-thru window on the front plus a pedestrian door; canopy is a shallow hood."""
    w=6.0; H=SVC_H
    ops=[dict(k='shopdoor',c=-1.8,w=1.6,t0=0.0,t1=3.0,depth=0.35),
         dict(k='storefront',c=1.4,w=2.8,t0=0.8,t1=2.4,depth=0.10)]
    def ex(b,w_):
        b.add('sign',side='front',wall=0.0,c=0.0,y=3.2,w=4.0,h=0.55,region='T_dark')
        b.add('hood',c=1.4,wall=0.0,y=2.55,w=3.2,depth=1.4,pitch=0.08)
        b.add('stoop',side='front',c=-1.8,wall=0.0,w=1.8,depth=1.4,rails=True)
        b.add('fixtures',side='front',wall=0.0,items=[('sconce',-2.8,2.3),('sconce',2.8,2.3)])
    b=slab('urb_svc_front_6m_fastfood',w,T_F,H,ops,'svc_front',(700,210,12),'W_stucco',WARM,parapet=SVC_PAR,sills=False,extra=ex,no_door=False,foundation=False,**FAR_SHOP)
    b.floor=0.0; b.floor_lines=[3.8]
    return b

# ------------------------------------------------------------------ apartments (3 storey, 6 m bay, 12 m depth)
def apt_front(boarded=False):
    w=6.0; H=UFL+3*UST; tag='boarded' if boarded else 'open'
    # same window openings as the open bay; boarded nails plywood over them (keeps near dense enough vs mid)
    ops=[dr('apt_door',0.0,0,w=1.0,h=2.2),
         wn('apt_slider',-1.8,0,w=1.6,h=1.3,sill=0.85),
         wn('apt_slider',1.8,0,w=1.6,h=1.3,sill=0.85)]
    for lv in range(1,3):
        ops+=[wn('apt_slider',-1.6,lv,w=1.8,h=1.3,sill=0.85),wn('apt_slider',1.6,lv,w=1.8,h=1.3,sill=0.85)]
    if boarded:
        pass  # door stays enterable; boards cover the sliders below
    def ex(b,w_):
        b.add('stoop',side='front',c=0.0,wall=0.0,w=1.6,depth=1.2)
        if boarded:
            # plank panels over the window positions (no half openings)
            BR={'t':'trim','mat':'T_dark','tint':(0.35,0.30,0.24)}
            for (c,y0,y1) in ((-1.8,UFL+0.85,UFL+2.15),(1.8,UFL+0.85,UFL+2.15),
                              (-1.6,UFL+UST+0.85,UFL+UST+2.15),(1.6,UFL+UST+0.85,UFL+UST+2.15),
                              (-1.6,UFL+2*UST+0.85,UFL+2*UST+2.15),(1.6,UFL+2*UST+0.85,UFL+2*UST+2.15)):
                b.add('box',x0=c-0.9,x1=c+0.9,y0=y0,y1=y1,z0=0.002,z1=0.05,top=BR,side=BR,bottom=BR,name='board',overlay=True,tiers=('near','mid'))
        else:
            b.add('fixtures',side='front',wall=0.0,items=[('sconce',-0.8,UFL+2.1),('sconce',0.8,UFL+2.1),('number',1.1,UFL+1.6)])
    return slab(f'urb_apt_front_6m_{tag}',w,T_F,H,ops,'apt_front',(800,240,16),'W_stucco',WHITE,parapet=0.8,sills=not boarded,extra=ex,no_door=False,**FAR_APT)

def apt_side():
    w=APT_D; H=UFL+3*UST
    ops=[]
    for lv in range(3):
        ops.append(wn('casement',0.0,lv,w=1.2,h=1.4,sill=0.9))
    ops.append(dict(k='vent',c=-w/2+0.5,t0=H-0.85,t1=H-0.45,w=0.6))
    return slab('urb_apt_side_12m',w,T_U,H,ops,'apt_side',(500,150,16),'W_stucco',WHITE,parapet=0.8,sills=True,**FAR_APT)

def apt_back():
    w=6.0; H=UFL+3*UST
    ops=[dr('apt_door',0.0,0,w=1.0,h=2.2)]
    for lv in range(3):
        ops.append(wn('casement',-1.8,lv,w=1.2,h=1.4,sill=0.9))
    def ex(b,w_):
        b.add('stoop',side='front',c=0.0,wall=0.0,w=1.6,depth=1.2)
        b.add('fixtures',side='front',wall=0.0,items=[('lamp',0.8,UFL+2.2),('meter',-1.4,1.0)])
    return slab('urb_apt_back_6m',w,T_U,H,ops,'apt_back',(450,140,16),'W_stucco',WHITE,parapet=0.8,sills=True,extra=ex,no_door=False,**FAR_APT)

# ------------------------------------------------------------------ self-storage (6 m unit front, 6.0 m eave)
def stg_front():
    w=6.0; H=4.2
    ops=[dict(k='rollup',c=0.0,w=3.6,t0=0.0,t1=3.2)]
    def ex(b,w_):
        b.add('sign',side='front',wall=0.0,c=0.0,y=3.5,w=2.4,h=0.35,region='T_dark')
    return slab('urb_stg_front_6m',w,T_F,H,ops,'stg_front',(400,120,8),'W_stucco',GREY,parapet=0.6,sills=False,extra=ex,foundation=False,**FAR_BLANK)

def stg_side():
    w=12.0; H=4.2
    ops=[dict(k='louver',c=0.0,w=0.9,t0=2.8,t1=3.5)]
    b=slab('urb_stg_side_12m',w,T_U,H,ops,'stg_side',(280,90,6),'W_stucco',GREY,parapet=0.6,foundation=False,**FAR_BLANK)
    b.floor_lines=[H]   # single-storey: do not invent a 3.3 m floor under the louver
    return b

def stg_back():
    w=6.0; H=4.2
    ops=[dict(k='louver',c=0.0,w=0.9,t0=2.8,t1=3.5)]
    b=slab('urb_stg_back_6m',w,T_U,H,ops,'stg_back',(220,70,6),'W_stucco',GREY,parapet=0.6,foundation=False,**FAR_BLANK)
    b.floor_lines=[H]
    return b

# ------------------------------------------------------------------ 10-storey office tower bay (8 m front, 20 m side)
def twr_front():
    w=TWR_W; H=TWR_H
    ops=[dict(k='shopdoor',c=0.0,w=1.8,t0=UFL,t1=UFL+3.0,depth=0.15),
         dict(k='storefront',c=-2.6,w=2.2,t0=UFL+0.25,t1=UFL+2.9,depth=0.10),
         dict(k='storefront',c=2.6,w=2.2,t0=UFL+0.25,t1=UFL+2.9,depth=0.10)]
    for lv in range(1,TWR_STY):
        if lv==1: ops.append(wn('ribbon',0.0,lv,w=6.4,h=1.5,sill=0.7))  # skip nothing; hood sits under t0
        else: ops.append(wn('ribbon',0.0,lv,w=6.4,h=1.5,sill=0.7))
    def ex(b,w_):
        b.add('stoop',side='front',c=0.0,wall=0.0,w=3.6,depth=1.8,rails=True)
        b.add('hood',c=0.0,wall=0.0,y=UFL+3.15,w=5.0,depth=1.6,pitch=0.10)
        b.add('fixtures',side='front',wall=0.0,items=[('sconce',-2.0,UFL+2.3),('sconce',2.0,UFL+2.3)])
    return slab('urb_twr_front_8m_10sty',w,T_F,H,ops,'twr_front',(1400,280,32),'W_stucco',GREY,parapet=TWR_PAR,sills=False,extra=ex,no_door=False,foundation=True,**FAR_OFFICE)

def twr_side():
    w=TWR_D; H=TWR_H
    ops=[]
    for lv in range(TWR_STY):
        ops.append(wn('ribbon',0.0,lv,w=12.0,h=1.5 if lv else 1.8,sill=0.7))
    ops.append(dict(k='vent',c=-w/2+0.5,t0=H-0.9,t1=H-0.5,w=0.6))
    return slab('urb_twr_side_20m_10sty',w,T_U,H,ops,'twr_side',(1200,240,32),'W_stucco',GREY,parapet=TWR_PAR,sills=False,foundation=True,**FAR_OFFICE)

def twr_back():
    w=TWR_W; H=TWR_H
    ops=[dr('apt_door',0.0,0,w=1.0,h=2.2)]
    for lv in range(TWR_STY):
        if lv==0: continue
        ops.append(wn('ribbon',0.0,lv,w=6.4,h=1.5,sill=0.7))
    def ex(b,w_):
        b.add('stoop',side='front',c=0.0,wall=0.0,w=1.6,depth=1.2)
        b.add('fixtures',side='front',wall=0.0,items=[('lamp',0.8,UFL+2.2),('meter',1.8,1.0)])
    return slab('urb_twr_back_8m_10sty',w,T_U,H,ops,'twr_back',(900,200,32),'W_stucco',GREY,parapet=TWR_PAR,sills=False,extra=ex,no_door=False,foundation=True,**FAR_OFFICE)

def twr_roof():
    w=TWR_W; d=TWR_D; H=TWR_H; xi=0.02
    b=Piece('urb_twr_roof_8x20','twr_roof',snap=None,drop=[(X,-w/2+xi,-1),(X,w/2-xi,1)],budget=(220,80,8),wall='W_stucco',tint=GREY,roof='R_flat',style='modular')
    b.floor=0.0; b.no_door=True; b.col_mode='bbox'
    TB={'t':'trim','mat':'T_white','tint':(0.9,0.9,0.88)}; RF={'t':'roof','mat':'R_flat','tint':(1,1,1),'flat_deck':True}
    b.add('box',x0=-w/2+xi,x1=w/2-xi,y0=H,y1=H+0.14,z0=-d/2+0.25,z1=d/2-0.25,top=RF,side=TB,bottom={'t':'swatch','mat':'S_soffit','tint':(0.9,0.9,0.88)},meta={'type':'roof'},drop=((1,0,0),(-1,0,0)))
    b.add('rtu',x=0.0,z=-6.0,y=H+0.14,w=1.6,d=1.1,h=0.9)
    b.origin=(0.0,0.0,w,d); b.base_y=H
    b.snap={'grid':GRID,'type':'twr_roof','module':w,'depth':d,'plate_y':H}
    return b

# ------------------------------------------------------------------ Phase D vocabulary expansion
def _cols(b,xs,z,y0,y1,q=0.28,tint=WHITE):
    """Doric-ish free-standing columns: square plinth, torus, octagonal shaft with entasis,
    echinus and abacus. type=post so stacked segments merge into one collision box each.
    Capital stops 1 cm below y1 (the beam soffit). Mid keeps an octagon shaft + abacus."""
    STU={'t':'swatch','mat':'S_stucco','tint':tint}; CAP={'t':'trim','mat':'T_white','tint':(0.96,0.95,0.93)}
    cap_top=y1-0.012
    for x in xs:
        # plinth (square) + torus (octagonal ring)
        b.add('box',x0=x-q-0.10,x1=x+q+0.10,y0=y0,y1=y0+0.16,z0=z-q-0.10,z1=z+q+0.10,
              top=CAP,side=STU,bottom=STU,tiers=('near','mid'),meta={'type':'post'},name='plinth',overlay=True)
        b.add('prism_y',cx=x,cz=z,y0=y0+0.162,y1=y0+0.28,r=q+0.06,sides=8,
              top=CAP,side=STU,bottom=CAP,tiers=('near',),meta={'type':'post'},name='torus',overlay=True)
        # shaft: two octagonal drums, the upper one slightly thinner (entasis)
        mid_y=y0+0.28+0.62*((cap_top-0.26)-(y0+0.28))
        b.add('prism_y',cx=x,cz=z,y0=y0+0.282,y1=mid_y,r=q,sides=8,
              top=STU,side=STU,bottom=STU,tiers=('near',),meta={'type':'post'},name='shaft_lo',overlay=True)
        b.add('prism_y',cx=x,cz=z,y0=mid_y+0.002,y1=cap_top-0.26,r=q*0.88,sides=8,
              top=STU,side=STU,bottom=STU,tiers=('near',),meta={'type':'post'},name='shaft_hi',overlay=True)
        # echinus (swelling octagon) + square abacus
        b.add('prism_y',cx=x,cz=z,y0=cap_top-0.258,y1=cap_top-0.10,r=q+0.04,sides=8,
              top=CAP,side=CAP,bottom=CAP,tiers=('near',),meta={'type':'post'},name='echinus',overlay=True)
        b.add('box',x0=x-q-0.10,x1=x+q+0.10,y0=cap_top-0.098,y1=cap_top,z0=z-q-0.10,z1=z+q+0.10,
              top=CAP,side=CAP,bottom=CAP,tiers=('near','mid'),meta={'type':'post'},name='abacus',overlay=True)
        # mid shaft: one octagon, base to echinus
        b.add('prism_y',cx=x,cz=z,y0=y0+0.162,y1=cap_top-0.10,r=q*0.94,sides=8,
              top=STU,side=STU,bottom=STU,tiers=('mid',),meta={'type':'post'},name='shaft_mid',overlay=True)

def brk_front_corner(storeys=3):
    """corner-entry brick bay: door at the right, storefront to the left, a corner pilaster."""
    w=6.0; H=UFL+storeys*UST
    ops=[dict(k='shopdoor',c=1.9,w=1.6,t0=0.0,t1=3.0,depth=0.35),
         dict(k='storefront',c=-0.9,w=3.2,t0=0.0,t1=3.0,depth=0.12)]
    for lv in range(1,storeys):
        ops+=[wn('dh_div',-1.6,lv,w=1.2,h=1.5,sill=0.8),wn('dh_div',1.0,lv,w=1.2,h=1.5,sill=0.8)]
    def ex(b,w_):
        PI={'t':'swatch','mat':'S_brick','tint':BRK}; CP={'t':'trim','mat':'T_white','tint':(0.95,0.94,0.90)}
        # corner pilaster at the +X end, stopped below the parapet
        b.add('box',x0=w_/2-0.36,x1=w_/2-0.02,y0=0.0,y1=H-0.02,z0=0.002,z1=0.18,
              top=CP,side=PI,bottom=None,tiers=('near','mid'),meta={'type':'trim'},name='corner_pier',overlay=True)
        b.add('awning',side='front',wall=0.0,s0=-2.7,s1=1.0,y_top=3.15,depth=1.15,drop=0.45,region='AW_red')
        b.add('sign',side='front',wall=0.0,c=-0.6,y=3.25,w=2.2,h=0.5,region='T_dark')
        b.add('gooseneck',side='front',wall=0.0,c=-1.8,y=4.15)
        b.add('gooseneck',side='front',wall=0.0,c=1.2,y=4.15)
    return slab(f'urb_brk_front_6m_{storeys}sty_corner',w,T_F,H,ops,'brk_front',(950,280,16),'W_brick',BRK,parapet=1.0,sills=True,extra=ex,no_door=False,**FAR_BRICK)

def brk_corner_pier(storeys=3):
    """1 m square brick corner pier: rusticated plinth, corner quoins, floor belts, stepped coping."""
    w=1.0; H=UFL+storeys*UST; par=1.0
    b=Piece(f'urb_brk_corner_pier_{storeys}sty','brk_corner',snap=None,drop=[],budget=(440,100,40),wall='W_brick',tint=BRK,roof='R_flat',style='modular')
    b.floor=UFL; b.no_door=True; b.abuts_all=False
    PI={'t':'swatch','mat':'S_brick','tint':BRK}; CP={'t':'trim','mat':'T_white','tint':(0.95,0.94,0.90)}
    QT={'t':'swatch','mat':'S_brick','tint':(0.95,0.90,0.86)}
    b.add('box',x0=-w/2,x1=w/2,y0=0.0,y1=0.50,z0=-w/2,z1=w/2,
          top=CP,side=PI,bottom=PI,tiers=('far',),meta={'type':'walls','W':H+par,'box':(-w/2,w/2,0.0,H+par,-w/2,w/2)},name='pier_far_plinth',overlay=True)
    b.add('box',x0=-w/2+0.12,x1=w/2-0.12,y0=0.50,y1=H+par,z0=-w/2+0.12,z1=w/2-0.12,
          top=CP,side=PI,bottom=PI,tiers=('far',),meta={'type':'walls','W':H+par},name='pier_far_shaft',overlay=True)
    b.add('box',x0=-w/2,x1=w/2,y0=0.0,y1=0.50,z0=-w/2,z1=w/2,
          top=CP,side=PI,bottom=None,tiers=('near','mid'),meta={'type':'walls','W':H+par,'box':(-w/2,w/2,0.0,H+par,-w/2,w/2)},name='plinth')
    b.add('box',x0=-w/2+0.12,x1=w/2-0.12,y0=0.52,y1=H+par-0.22,z0=-w/2+0.12,z1=w/2-0.12,
          top=None,side=PI,bottom=None,tiers=('near','mid'),meta={'type':'walls','W':H+par},name='shaft')
    # one quoin block per corner per storey (proud of the shaft, inside the 1 m module)
    for lv in range(storeys):
        y=UFL+lv*UST+0.55
        h=0.70
        if y+h>H+par-0.28: continue
        # 8 cm cubes in the 10 cm margin around the shaft, 2 cm gap off the shaft
        s=0.08
        for sx,sz in ((-1,-1),(-1,1),(1,-1),(1,1)):
            cx=sx*(w/2-s/2-0.015); cz=sz*(w/2-s/2-0.015)
            b.add('box',x0=cx-s/2,x1=cx+s/2,y0=y,y1=y+h,z0=cz-s/2,z1=cz+s/2,
                  top=QT,side=QT,bottom=QT,tiers=('near',),meta={'type':'trim'},name='quoin',overlay=True)
    for lv in range(storeys+1):
        yy=UFL+lv*UST
        if yy<0.70 or yy>H+par-0.30: continue
        b.add('box',x0=-w/2+0.02,x1=w/2-0.02,y0=yy-0.05,y1=yy+0.08,z0=-w/2+0.02,z1=w/2-0.02,
              top=PI,side=PI,bottom=PI,tiers=('near',),meta={'type':'trim'},name='belt',overlay=True)
    b.add('box',x0=-w/2+0.08,x1=w/2-0.08,y0=H+par-0.20,y1=H+par-0.12,z0=-w/2+0.08,z1=w/2-0.08,
          top=CP,side=CP,bottom=CP,tiers=('near','mid'),meta={'type':'cap'},name='neck',overlay=True)
    b.add('box',x0=-w/2+0.01,x1=w/2-0.01,y0=H+par-0.10,y1=H+par-0.04,z0=-w/2+0.01,z1=w/2-0.01,
          top=CP,side=CP,bottom=CP,tiers=('near','mid'),meta={'type':'cap'},name='coping',overlay=True)
    b.add('box',x0=-w/2+0.06,x1=w/2-0.06,y0=H+par-0.02,y1=H+par,z0=-w/2+0.06,z1=w/2-0.06,
          top=CP,side=CP,bottom=CP,tiers=('near',),meta={'type':'cap'},name='coping_lip',overlay=True)
    b.origin=(0.0,0.0,w,w)
    b.snap={'grid':GRID,'module':w,'type':'brk_corner','ends':[[-w/2,0,0],[w/2,0,0]],'face_z':w/2,'plate_y':H,'parapet_top':H+par}
    return b

def storefront_bay():
    """6 m glass storefront bay (ground storey), city vocabulary."""
    w=6.0; H=SVC_H
    ops=[dict(k='shopdoor',c=1.9,w=1.4,t0=0.0,t1=3.0,depth=0.35),
         dict(k='storefront',c=-0.9,w=3.2,t0=0.0,t1=3.0,depth=0.12)]
    def ex(b,w_):
        b.add('sign',side='front',wall=0.0,c=0.0,y=3.25,w=4.4,h=0.50,region='T_dark')
        b.add('gooseneck',side='front',wall=0.0,c=-2.0,y=4.05)
        b.add('gooseneck',side='front',wall=0.0,c=2.0,y=4.05)
    return slab('urb_storefront_6m',w,T_F,H,ops,'storefront',(700,210,12),'W_stucco',WHITE,parapet=SVC_PAR,sills=False,extra=ex,no_door=False,foundation=False,**FAR_SHOP)

def _curtain_relief(b,w,H,sty=TWR_STY,door_gap=None):
    """Proud slab-edge bands and spandrels (silhouette) plus mullions (near) on a curtain-wall face at z=0.
    Overlays stay within 0.12 m of the wall so the inward-face exemption applies; mullions are segmented
    in Y so they do not run through the slab or spandrel boxes."""
    MT={'t':'trim','mat':'T_metal','tint':(0.20,0.20,0.22)}
    SP={'t':'trim','mat':'T_dark','tint':(0.30,0.30,0.32)}
    SL={'t':'trim','mat':'T_white','tint':(0.84,0.84,0.82)}
    inset=0.22
    ends=((1,0,0),(-1,0,0))
    for lv in range(sty+1):
        y=UFL+lv*UST
        if y>H+0.05: continue
        st=('near','mid') if lv%2==0 else ('near',)
        y0=y-0.06 if lv else UFL+0.02  # do not hang the grade-level band through the stoop
        b.add('box',x0=-w/2+inset,x1=w/2-inset,y0=y0,y1=y+0.16,z0=0.02,z1=0.10,
              top=SL,side=SL,bottom=SL,tiers=st,meta={'type':'trim'},name='slab_edge',overlay=True,
              drop=ends)
        if lv<sty:
            b.add('box',x0=-w/2+inset,x1=w/2-inset,y0=y+0.18,y1=y+0.40,z0=0.02,z1=0.07,
                  top=SP,side=SP,bottom=SP,tiers=('near',),meta={'type':'trim'},name='spandrel',overlay=True,
                  drop=ends)
    span=w-2*inset
    n=max(3,int(round(span/2.0)))
    for i in range(n+1):
        x=-w/2+inset+i*(span/n)
        # every other storey keeps the back-bay mullions inside the 1000-tri cap
        for lv in range(0,sty,2):
            y0=UFL+lv*UST+0.42
            y1=UFL+(lv+1)*UST-0.08
            if y1-y0<0.20: continue
            if door_gap and lv==0 and door_gap[0]-0.10<=x<=door_gap[1]+0.10:
                continue
            b.add('box',x0=x-0.035,x1=x+0.035,y0=y0,y1=y1,z0=0.02,z1=0.09,
                  top=None,side=MT,bottom=None,tiers=('near',),meta={'type':'trim'},name='mullion',overlay=True)

def twr_front_glass():
    """10-storey curtain-wall front bay, 8 m, with slab-edge, spandrel and mullion relief."""
    w=TWR_W; H=TWR_H
    ops=[dict(k='shopdoor',c=0.0,w=1.8,t0=UFL,t1=UFL+3.0,depth=0.12)]
    ops+=[dict(k='glass',c=-2.6,w=2.4,t0=UFL+0.20,t1=UFL+2.90,depth=0.08),
          dict(k='glass',c=2.6,w=2.4,t0=UFL+0.20,t1=UFL+2.90,depth=0.08)]
    for lv in range(1,TWR_STY):
        ops.append(wn('glass',0.0,lv,w=7.0,h=2.2,sill=0.40))
    def ex(b,w_):
        b.add('stoop',side='front',c=0.0,wall=0.0,w=3.6,depth=1.8,rails=True)
        b.add('fixtures',side='front',wall=0.0,items=[('sconce',-2.0,UFL+2.3),('sconce',2.0,UFL+2.3)])
        _curtain_relief(b,w_,H,door_gap=(-0.95,0.95))
    return slab('urb_twr_front_8m_10sty_glass',w,T_F,H,ops,'twr_front',(1600,320,32),'W_stucco',GREY,parapet=TWR_PAR,sills=False,extra=ex,no_door=False,foundation=True,**FAR_GLASS)

def twr_side_glass():
    w=TWR_D; H=TWR_H
    ops=[]
    for lv in range(TWR_STY):
        ops.append(wn('glass',0.0,lv,w=16.0,h=2.2 if lv else 2.4,sill=0.40))
    ops.append(dict(k='vent',c=-w/2+0.5,t0=H-0.9,t1=H-0.5,w=0.6))
    def ex(b,w_):
        _curtain_relief(b,w_,H)
    return slab('urb_twr_side_20m_10sty_glass',w,T_U,H,ops,'twr_side',(1400,280,32),'W_stucco',GREY,parapet=TWR_PAR,sills=False,extra=ex,foundation=True,**FAR_GLASS)

def twr_back_glass():
    w=TWR_W; H=TWR_H
    ops=[dr('apt_door',0.0,0,w=1.0,h=2.2)]
    for lv in range(1,TWR_STY):
        ops.append(wn('glass',0.0,lv,w=7.0,h=2.2,sill=0.40))
    def ex(b,w_):
        b.add('stoop',side='front',c=0.0,wall=0.0,w=1.6,depth=1.2)
        b.add('fixtures',side='front',wall=0.0,items=[('lamp',0.8,UFL+2.2),('meter',1.8,1.0)])
        _curtain_relief(b,w_,H,door_gap=(-0.55,0.55))
    return slab('urb_twr_back_8m_10sty_glass',w,T_U,H,ops,'twr_back',(1000,220,32),'W_stucco',GREY,parapet=TWR_PAR,sills=False,extra=ex,no_door=False,foundation=True,**FAR_GLASS)

def twr_corner_pier():
    """1 m curtain-wall corner pier, 10 storeys: rusticated plinth, pilaster strips, slab-edge rings, stepped cap."""
    w=1.0; H=TWR_H; par=TWR_PAR
    b=Piece('urb_twr_corner_pier_10sty','twr_corner',snap=None,drop=[],budget=(480,140,40),wall='W_stucco',tint=GREY,roof='R_flat',style='modular')
    b.floor=UFL; b.no_door=True
    ST={'t':'swatch','mat':'S_stucco','tint':GREY}; MT={'t':'trim','mat':'T_metal','tint':(0.22,0.22,0.23)}
    CP={'t':'trim','mat':'T_white','tint':(0.9,0.9,0.88)}
    RS={'t':'swatch','mat':'S_stucco','tint':(0.70,0.70,0.68)}
    b.add('box',x0=-w/2,x1=w/2,y0=0.0,y1=UFL+0.16,z0=-w/2,z1=w/2,
          top=CP,side=ST,bottom=ST,tiers=('far',),meta={'type':'walls','W':H+par,'box':(-w/2,w/2,0.0,H+par,-w/2,w/2)},name='pier_far_plinth',overlay=True)
    b.add('box',x0=-w/2+0.10,x1=w/2-0.10,y0=UFL+0.16,y1=H+par,z0=-w/2+0.10,z1=w/2-0.10,
          top=CP,side=ST,bottom=ST,tiers=('far',),meta={'type':'walls','W':H+par},name='pier_far_shaft',overlay=True)
    b.add('box',x0=-w/2,x1=w/2,y0=0.0,y1=UFL+0.16,z0=-w/2,z1=w/2,
          top=CP,side=RS,bottom=None,tiers=('near','mid'),meta={'type':'walls','W':H+par,'box':(-w/2,w/2,0.0,H+par,-w/2,w/2)},name='plinth')
    b.add('box',x0=-w/2+0.10,x1=w/2-0.10,y0=UFL+0.18,y1=H+par-0.18,z0=-w/2+0.10,z1=w/2-0.10,
          top=None,side=ST,bottom=None,tiers=('near','mid'),meta={'type':'walls','W':H+par},name='shaft')
    pw=0.28
    strips=[
        dict(tiers=('near','mid'), x0=-pw/2,x1=pw/2, z0=w/2-0.07, z1=w/2-0.03),
        dict(tiers=('near','mid'), x0=w/2-0.07,x1=w/2-0.03, z0=-pw/2, z1=pw/2),
        dict(tiers=('near',),      x0=-pw/2,x1=pw/2, z0=-w/2+0.03, z1=-w/2+0.07),
        dict(tiers=('near',),      x0=-w/2+0.03,x1=-w/2+0.07, z0=-pw/2, z1=pw/2),
    ]
    for s_ in strips:
        b.add('box',x0=s_['x0'],x1=s_['x1'],y0=UFL+0.22,y1=H+par-0.22,z0=s_['z0'],z1=s_['z1'],
              top=ST,side=ST,bottom=ST,tiers=s_['tiers'],meta={'type':'trim'},name='pilaster',overlay=True)
    # metal slab-edge rings as four face strips (not a solid through the shaft)
    for lv in range(0, TWR_STY+1, 2):
        y=UFL+lv*UST
        if y>H+par-0.20: continue
        y0,y1=y-0.05,y+0.12
        # 2 cm off the shaft (shaft at ±0.40), 3 cm proud, stay inside ±0.50
        b.add('box',x0=-w/2+0.06,x1=w/2-0.06,y0=y0,y1=y1,z0=w/2-0.07,z1=w/2-0.03,
              top=MT,side=MT,bottom=MT,tiers=('near',),meta={'type':'trim'},name='slab_ring',overlay=True)
        b.add('box',x0=-w/2+0.06,x1=w/2-0.06,y0=y0,y1=y1,z0=-w/2+0.03,z1=-w/2+0.07,
              top=MT,side=MT,bottom=MT,tiers=('near',),meta={'type':'trim'},name='slab_ring',overlay=True)
        b.add('box',x0=w/2-0.07,x1=w/2-0.03,y0=y0,y1=y1,z0=-w/2+0.06,z1=w/2-0.06,
              top=MT,side=MT,bottom=MT,tiers=('near',),meta={'type':'trim'},name='slab_ring',overlay=True)
        b.add('box',x0=-w/2+0.03,x1=-w/2+0.07,y0=y0,y1=y1,z0=-w/2+0.06,z1=w/2-0.06,
              top=MT,side=MT,bottom=MT,tiers=('near',),meta={'type':'trim'},name='slab_ring',overlay=True)
    b.add('box',x0=-w/2+0.01,x1=w/2-0.01,y0=H+par-0.16,y1=H+par-0.06,z0=-w/2+0.01,z1=w/2-0.01,
          top=CP,side=CP,bottom=CP,tiers=('near','mid'),meta={'type':'cap'},name='coping',overlay=True)
    b.add('box',x0=-w/2+0.08,x1=w/2-0.08,y0=H+par-0.04,y1=H+par,z0=-w/2+0.08,z1=w/2-0.08,
          top=CP,side=CP,bottom=CP,tiers=('near',),meta={'type':'cap'},name='coping_lip',overlay=True)
    b.origin=(0.0,0.0,w,w)
    b.snap={'grid':GRID,'module':w,'type':'twr_corner','ends':[[-w/2,0,0],[w/2,0,0]],'face_z':w/2,'plate_y':H,'parapet_top':H+par}
    return b

def civ_column():
    """Single civic column, plinth at grade to 0.80 then shaft to 4.00. Collision is type=post."""
    w=1.0; y0,y1=0.80,4.00
    b=Piece('urb_civ_column','civ_col',snap=None,drop=[],budget=(280,90,40),wall='W_stucco',tint=WHITE,roof='R_flat',style='modular')
    b.floor=0.0; b.no_door=True
    PL={'t':'swatch','mat':'S_concrete','tint':(0.72,0.70,0.66)}
    b.add('box',x0=-0.36,x1=0.36,y0=0.0,y1=y0-0.02,z0=-0.36,z1=0.36,
          top=PL,side=PL,bottom=None,tiers=('near','mid'),meta={'type':'post'},name='plinth')
    _cols(b,[0.0],0.0,y0,y1,q=0.28,tint=WHITE)
    STU={'t':'swatch','mat':'S_stucco','tint':WHITE}
    b.add('box',x0=-0.36,x1=0.36,y0=0.0,y1=0.96,z0=-0.36,z1=0.36,
          top=STU,side=STU,bottom=STU,tiers=('far',),meta={'type':'post'},name='col_far_plinth',overlay=True)
    b.add('box',x0=-0.26,x1=0.26,y0=0.96,y1=y1-0.10,z0=-0.26,z1=0.26,
          top=STU,side=STU,bottom=STU,tiers=('far',),meta={'type':'post'},name='col_far_shaft',overlay=True)
    b.add('box',x0=-0.38,x1=0.38,y0=y1-0.10,y1=y1,z0=-0.38,z1=0.38,
          top=STU,side=STU,bottom=STU,tiers=('far',),meta={'type':'post'},name='col_far_cap',overlay=True)
    b.origin=(0.0,0.0,w,w)
    b.snap={'grid':GRID,'module':w,'type':'civ_col','ends':[[-w/2,0,0],[w/2,0,0]],'face_z':0.0,'plate_y':y1}
    return b

def civ_colonnade():
    """6 m colonnade bay: two columns, entablature (no collision), railed stoop that meets the posts."""
    w=6.0; depth=3.20; fl=0.80; beam=4.00
    b=Piece('urb_civ_colonnade_6m','civ_colonnade',snap=None,drop=[(0,-w/2,-1),(0,w/2,1)],budget=(800,220,56),
            wall='W_stucco',tint=WHITE,roof='R_flat',style='modular')
    b.floor=fl; b.no_door=True
    # official stoop so the side rails are legal; front opening is the stair
    b.add('stoop',side='front',c=0.0,wall=0.0,w=w-0.20,depth=depth,floor=fl,rails=True)
    # cheek plates at the official rail_flange x so the wall-return feet meet a wall
    CK={'t':'swatch','mat':'S_stucco','tint':WHITE}
    stoop_w=w-0.20
    for xr in (-stoop_w/2+0.14, stoop_w/2-0.14):
        b.add('box',x0=xr-0.06,x1=xr+0.06,y0=fl,y1=fl+0.95,z0=-0.08,z1=0.0,
              top=CK,side=CK,bottom=None,tiers=('near','mid'),meta={'type':'trim'},name='rail_return')
    xs=(-1.80,1.80)
    zc=depth-0.40
    _cols(b,xs,zc,fl+0.02,beam,q=0.28,tint=WHITE)
    BE={'t':'swatch','mat':'S_stucco','tint':WHITE}; SOF={'t':'swatch','mat':'S_soffit','tint':(0.90,0.88,0.84)}
    C={'t':'trim','mat':'T_white','tint':(0.95,0.94,0.90)}
    # entablature as solid stacked mouldings (architrave / frieze / cornice), not a hollow C-slab.
    # Open at the snap ends so bays can join; each layer is a solid so the side reads as a profile.
    # type=entablature / porch_roof: walk under it, no collision.
    ends=((1,0,0),(-1,0,0))
    b.add('box',x0=-w/2,x1=w/2,y0=beam,y1=beam+0.14,z0=0.14,z1=depth,
          top=C,side=BE,bottom=SOF,tiers=('near','mid'),meta={'type':'entablature'},name='architrave',drop=ends)
    b.add('box',x0=-w/2,x1=w/2,y0=beam+0.142,y1=beam+0.30,z0=0.18,z1=depth-0.04,
          top=BE,side=BE,bottom=BE,tiers=('near','mid'),meta={'type':'entablature'},name='frieze',drop=ends)
    b.add('box',x0=-w/2,x1=w/2,y0=beam+0.302,y1=beam+0.50,z0=0.00,z1=depth+0.08,
          top=C,side=C,bottom=SOF,tiers=('near','mid'),meta={'type':'entablature'},name='cornice',drop=ends)
    # dentils under the cornice soffit, proud of the frieze, near only
    x=-w/2+0.28
    while x<w/2-0.22:
        b.add('box',x0=x,x1=x+0.10,y0=beam+0.268,y1=beam+0.300,z0=0.02,z1=0.17,
              top=C,side=C,bottom=C,tiers=('near',),meta={'type':'trim'},name='dentil',overlay=True)
        x+=0.45
    eht=beam+0.50
    # far hull follows the mid silhouette: stoop, two posts, entablature (not a solid portico slab)
    b.add('box',x0=-stoop_w/2,x1=stoop_w/2,y0=0.0,y1=fl,z0=0.0,z1=depth,
          top=CK,side=CK,bottom=CK,tiers=('far',),meta={'type':'stoop'},name='far_stoop',overlay=True)
    qf=0.32
    for x in xs:
        b.add('box',x0=x-qf,x1=x+qf,y0=fl,y1=beam,z0=zc-qf,z1=zc+qf,
              top=BE,side=BE,bottom=BE,tiers=('far',),meta={'type':'post'},name='far_col',overlay=True)
    b.add('box',x0=-w/2,x1=w/2,y0=beam,y1=eht,z0=0.0,z1=depth+0.08,
          top=C,side=BE,bottom=SOF,tiers=('far',),meta={'type':'entablature'},name='far_entablature',
          drop=((1,0,0),(-1,0,0)),overlay=True)
    b.origin=(0.0,depth/2,w,depth)
    b.snap={'grid':GRID,'module':w,'type':'civ_colonnade','ends':[[-w/2,0,depth/2],[w/2,0,depth/2]],'face_z':depth,'plate_y':eht}
    return b

def civ_pediment():
    """6 m pediment: horizontal cornice, straight raking cornices at ~20 deg,
    recessed tympanum, dentil row, triangular far hull. No stepped ziggurat."""
    import math
    w=6.0
    # rise 1.10 m over a 5.80 m base: atan(1.10/2.90) = 20.8 deg
    base=5.80; rise=1.10; y_c=0.24; y_peak=y_c+rise
    b=Piece('urb_civ_pediment_6m','civ_pediment',snap=None,drop=[(0,-w/2,-1),(0,w/2,1)],budget=(360,120,24),
            wall='W_stucco',tint=WHITE,roof='R_flat',style='modular')
    b.no_door=True
    ST={'t':'swatch','mat':'S_stucco','tint':WHITE}; SOF={'t':'swatch','mat':'S_soffit','tint':(0.90,0.88,0.84)}
    C={'t':'trim','mat':'T_white','tint':(0.95,0.94,0.90)}
    # horizontal cornice: bed + projecting corona
    b.add('box',x0=-w/2,x1=w/2,y0=0.00,y1=0.10,z0=-0.18,z1=0.18,
          top=C,side=C,bottom=SOF,tiers=('near','mid'),meta={'type':'porch_roof'},name='ped_bed',
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=0.12,y1=y_c,z0=-0.24,z1=0.24,
          top=C,side=C,bottom=C,tiers=('near','mid'),meta={'type':'porch_roof'},name='ped_corona',
          drop=((1,0,0),(-1,0,0)))
    # dentil row under the corona soffit (near)
    x=-w/2+0.22
    while x<w/2-0.18:
        b.add('box',x0=x,x1=x+0.10,y0=0.102,y1=0.118,z0=0.04,z1=0.24,
              top=C,side=C,bottom=C,tiers=('near',),meta={'type':'trim'},name='ped_dentil',overlay=True)
        x+=0.28
    # recessed tympanum: one smooth triangle, inset from the rakes
    inset=0.22
    b.add('tri_prism',x0=-base/2+inset,x1=base/2-inset,y0=y_c,y1=y_peak-inset*rise/(base/2),
          z0=-0.07,z1=0.07,top=ST,side=ST,bottom=None,
          tiers=('near','mid'),meta={'type':'porch_roof'},name='tympanum')
    # straight raking cornices sit ON the slope (offset outward) so they do not
    # intersect the tympanum or the corona; trimmed at the peak and at the bed.
    for sign in (-1,1):
        p0=np.array([sign*base/2, y_c, 0.0])
        p1=np.array([0.0, y_peak, 0.0])
        d=p1-p0; L=float(np.linalg.norm(d)) or 1.0
        ax_s=d/L
        ax_z=np.array([0.0,0.0,1.0])
        ax_p=np.cross(ax_z, ax_s); ax_p=ax_p/(np.linalg.norm(ax_p)+1e-12)
        mid=0.5*(p0+p1)
        inside=np.array([0.0, y_c+0.20, 0.0])
        if np.dot(ax_p, mid-inside)<0:
            ax_p=-ax_p  # outward
        p0t=p0+ax_s*0.10
        p1t=p1-ax_s*0.16
        thick=0.08
        c=0.5*(p0t+p1t)+ax_p*(thick+0.02)
        hs=(0.5*float(np.linalg.norm(p1t-p0t)), 0.22, thick)
        roles=[C,C,C,C,C,C]
        b.add('obox',c=(c[0],c[1],0.0),ax=(ax_s,ax_z,ax_p),hs=hs,roles=roles,
              name='rake',overlay=True,tiers=('near','mid'),meta={'type':'porch_roof'})
    # small peak acroterion, near only so the far hull stays a clean triangle
    b.add('box',x0=-0.16,x1=0.16,y0=y_peak-0.02,y1=y_peak+0.16,z0=-0.16,z1=0.16,
          top=C,side=C,bottom=C,tiers=('near',),meta={'type':'porch_roof'},name='peak',overlay=True)
    # far: cornice bar + triangular tympanum, so the silhouette matches mid (not a rectangular slab)
    b.add('box',x0=-w/2,x1=w/2,y0=0.00,y1=y_c,z0=-0.24,z1=0.24,
          top=ST,side=ST,bottom=SOF,tiers=('far',),meta={'type':'porch_roof'},name='ped_far_bed',
          drop=((1,0,0),(-1,0,0)))
    b.add('tri_prism',x0=-w/2,x1=w/2,y0=y_c,y1=y_peak+0.12,z0=-0.22,z1=0.22,
          top=ST,side=ST,bottom=None,tiers=('far',),meta={'type':'porch_roof'},name='ped_far')
    b.origin=(0.0,0.0,w,0.48)
    b.snap={'grid':GRID,'module':w,'type':'civ_pediment','ends':[[-w/2,0,0],[w/2,0,0]],'face_z':0.24,'plate_y':y_peak}
    return b


def civ_cornice():
    """6 m moulded cornice: fascia, bed mould, corona, cymatium, mutules under the soffit."""
    w=6.0
    b=Piece('urb_civ_cornice_6m','civ_cornice',snap=None,drop=[(0,-w/2,-1),(0,w/2,1)],budget=(160,50,16),
            wall='W_stucco',tint=WHITE,roof='R_flat',style='modular')
    b.no_door=True
    C={'t':'trim','mat':'T_white','tint':(0.95,0.94,0.90)}
    SOF={'t':'swatch','mat':'S_soffit','tint':(0.90,0.88,0.84)}
    # fascia, bed mould, corona, cymatium — 2 cm Y-gaps, open at the snap ends
    b.add('box',x0=-w/2,x1=w/2,y0=0.00,y1=0.08,z0=0.00,z1=0.08,
          top=C,side=C,bottom=SOF,tiers=('near','mid'),meta={'type':'trim'},name='fascia',
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=0.10,y1=0.16,z0=0.00,z1=0.16,
          top=C,side=C,bottom=SOF,tiers=('near','mid'),meta={'type':'trim'},name='bed',
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=0.18,y1=0.32,z0=0.00,z1=0.28,
          top=C,side=C,bottom=SOF,tiers=('near','mid'),meta={'type':'trim'},name='corona',
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=0.34,y1=0.44,z0=0.00,z1=0.18,
          top=C,side=C,bottom=C,tiers=('near',),meta={'type':'trim'},name='cyma',
          drop=((1,0,0),(-1,0,0)))
    # mutules hanging under the corona soffit, proud of the bed mould (near)
    x=-w/2+0.28
    while x<w/2-0.22:
        b.add('box',x0=x,x1=x+0.14,y0=0.162,y1=0.178,z0=0.16,z1=0.28,
              top=C,side=C,bottom=C,tiers=('near',),meta={'type':'trim'},name='mutule',overlay=True)
        x+=0.72
    # closed far hull
    b.add('box',x0=-w/2,x1=w/2,y0=0.00,y1=0.44,z0=0.00,z1=0.28,
          top=C,side=C,bottom=SOF,tiers=('far',),meta={'type':'trim'},name='cornice_far',
          drop=((1,0,0),(-1,0,0)))
    b.origin=(0.0,0.14,w,0.28)
    b.snap={'grid':GRID,'module':w,'type':'civ_cornice','ends':[[-w/2,0,0],[w/2,0,0]],'face_z':0.28,'plate_y':0.44}
    return b

def civ_parapet():
    """6 m parapet: base mould, paneled die, drip coping with a throating."""
    w=6.0
    b=Piece('urb_civ_parapet_6m','civ_parapet',snap=None,drop=[(0,-w/2,-1),(0,w/2,1)],budget=(140,50,16),
            wall='W_stucco',tint=WHITE,roof='R_flat',style='modular')
    b.no_door=True
    ST={'t':'swatch','mat':'S_stucco','tint':WHITE}; C={'t':'trim','mat':'T_white','tint':(0.95,0.94,0.90)}
    # die with a slightly wider base mould in the same solid (no stacked gap)
    b.add('box',x0=-w/2,x1=w/2,y0=0.00,y1=0.86,z0=-0.12,z1=0.12,
          top=None,side=ST,bottom=None,tiers=('near','mid'),meta={'type':'trim'},name='parapet',
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=0.00,y1=0.10,z0=0.13,z1=0.16,
          top=C,side=C,bottom=C,tiers=('near',),meta={'type':'trim'},name='base',overlay=True,
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=0.00,y1=0.10,z0=-0.16,z1=-0.13,
          top=C,side=C,bottom=C,tiers=('near',),meta={'type':'trim'},name='base',overlay=True,
          drop=((1,0,0),(-1,0,0)))
    for c in (-1.80,0.00,1.80):
        b.add('box',x0=c-0.72,x1=c+0.72,y0=0.20,y1=0.74,z0=0.13,z1=0.17,
              top=ST,side=ST,bottom=ST,tiers=('near',),meta={'type':'trim'},name='panel_frame',overlay=True)
        b.add('box',x0=c-0.56,x1=c+0.56,y0=0.28,y1=0.66,z0=0.17,z1=0.185,
              top=ST,side=ST,bottom=ST,tiers=('near',),meta={'type':'trim'},name='panel',overlay=True)
    b.add('box',x0=-w/2,x1=w/2,y0=0.86,y1=0.98,z0=-0.20,z1=0.20,
          top=C,side=C,bottom=C,tiers=('near','mid'),meta={'type':'cap'},name='coping',
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=0.82,y1=0.86,z0=-0.16,z1=-0.12,
          top=C,side=C,bottom=C,tiers=('near',),meta={'type':'cap'},name='throat',overlay=True,
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=0.82,y1=0.86,z0=0.12,z1=0.16,
          top=C,side=C,bottom=C,tiers=('near',),meta={'type':'cap'},name='throat',overlay=True,
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2+0.04,x1=w/2-0.04,y0=1.00,y1=1.08,z0=-0.14,z1=0.14,
          top=C,side=C,bottom=C,tiers=('near','mid'),meta={'type':'cap'},name='coping_lip',
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=0.00,y1=1.08,z0=-0.20,z1=0.20,
          top=C,side=ST,bottom=None,tiers=('far',),meta={'type':'trim'},name='parapet_far',
          drop=((1,0,0),(-1,0,0)))
    b.origin=(0.0,0.0,w,0.40)
    b.snap={'grid':GRID,'module':w,'type':'civ_parapet','ends':[[-w/2,0,0],[w/2,0,0]],'face_z':0.20,'plate_y':1.08}
    return b

def canopy_6m():
    """6 m x 3.2 m commercial / gas-station canopy.
    4.0 m soffit clearance, 0.80 m fascia with a trim line, recessed soffit lights,
    post base plates and collars, a downspout on one post. Far is the deck slab only.
    Collision on the posts; the deck and fascia are porch_roof."""
    w=6.0; depth=3.20; sof=4.00; deck=0.28; fas=0.80
    y0=sof; y1=sof+deck          # soffit, deck top
    fb=sof-fas                   # fascia bottom 3.20
    b=Piece('urb_canopy_6m','canopy',snap=None,drop=[(0,-w/2,-1),(0,w/2,1)],budget=(380,120,16),
            wall='W_stucco',tint=WHITE,roof='R_flat',style='modular')
    b.no_door=True
    CAN={'t':'trim','mat':'T_white','tint':(0.92,0.92,0.90)}
    TR={'t':'trim','mat':'T_white','tint':(0.78,0.78,0.76)}
    SOF={'t':'swatch','mat':'S_soffit','tint':(0.86,0.86,0.84)}
    DK={'t':'trim','mat':'T_dark','tint':(0.18,0.18,0.19)}
    MT={'t':'trim','mat':'T_metal','tint':(0.16,0.16,0.18)}
    LT={'t':'trim','mat':'T_white','tint':(0.95,0.93,0.82)}
    # deck (porch_roof: walk under it)
    b.add('box',x0=-w/2,x1=w/2,y0=y0,y1=y1,z0=0.0,z1=depth,
          top=DK,side=CAN,bottom=SOF,tiers=('near','mid'),meta={'type':'porch_roof'},name='canopy',
          drop=((1,0,0),(-1,0,0)))
    # deep fascia all around, 0.80 m, hanging from the soffit to just below
    t=0.12
    b.add('box',x0=-w/2,x1=w/2,y0=fb,y1=y1,z0=depth-t,z1=depth,
          top=CAN,side=CAN,bottom=CAN,tiers=('near','mid'),meta={'type':'porch_roof'},name='fascia_front',
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=fb,y1=y1,z0=0.0,z1=t,
          top=CAN,side=CAN,bottom=CAN,tiers=('near','mid'),meta={'type':'porch_roof'},name='fascia_back',
          drop=((1,0,0),(-1,0,0)))
    for x0,x1,nm in ((-w/2,-w/2+t,'fascia_l'),(w/2-t,w/2,'fascia_r')):
        b.add('box',x0=x0,x1=x1,y0=fb,y1=y1,z0=t,z1=depth-t,
              top=CAN,side=CAN,bottom=CAN,tiers=('near',),meta={'type':'porch_roof'},name=nm)
    # trim line around the fascia (near; front also mid)
    ty0,ty1=fb+0.36,fb+0.44
    b.add('box',x0=-w/2+0.02,x1=w/2-0.02,y0=ty0,y1=ty1,z0=depth,z1=depth+0.03,
          top=TR,side=TR,bottom=TR,tiers=('near','mid'),meta={'type':'porch_roof'},name='fascia_trim',
          drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2+0.02,x1=w/2-0.02,y0=ty0,y1=ty1,z0=-0.03,z1=0.0,
          top=TR,side=TR,bottom=TR,tiers=('near',),meta={'type':'porch_roof'},name='fascia_trim',
          drop=((1,0,0),(-1,0,0)))
    for x0,x1 in ((-w/2+0.00,-w/2+0.03),(w/2-0.03,w/2-0.00)):
        b.add('box',x0=x0,x1=x1,y0=ty0,y1=ty1,z0=t+0.02,z1=depth-t-0.02,
              top=TR,side=TR,bottom=TR,tiers=('near',),meta={'type':'porch_roof'},name='fascia_trim')
    # recessed soffit lights (near): shallow trays just under the soffit
    for px,pz in ((-1.50,1.00),(-1.50,2.20),(1.50,1.00),(1.50,2.20)):
        b.add('box',x0=px-0.16,x1=px+0.16,y0=y0-0.04,y1=y0-0.004,z0=pz-0.16,z1=pz+0.16,
              top=LT,side=MT,bottom=LT,tiers=('near',),meta={'type':'porch_roof'},name='soffit_light',overlay=True)
    q=0.28
    posts=((-w/2+0.18,0.18),(-w/2+0.18,depth-0.46),(w/2-0.46,0.18),(w/2-0.46,depth-0.46))
    for i,(px,pz) in enumerate(posts):
        # base plate
        b.add('box',x0=px-0.10,x1=px+q+0.10,y0=0.0,y1=0.06,z0=pz-0.10,z1=pz+q+0.10,
              top=MT,side=MT,bottom=None,tiers=('near',),meta={'type':'post'},name='canopy_plate')
        # base collar
        b.add('box',x0=px-0.04,x1=px+q+0.04,y0=0.08,y1=0.18,z0=pz-0.04,z1=pz+q+0.04,
              top=MT,side=MT,bottom=MT,tiers=('near',),meta={'type':'post'},name='canopy_collar')
        # shaft, 2 cm gaps; mid is a single shaft from the plate to the soffit
        b.add('box',x0=px,x1=px+q,y0=0.20,y1=y0-0.16,z0=pz,z1=pz+q,
              top=None,side=MT,bottom=None,tiers=('near',),meta={'type':'post'},name='canopy_post')
        b.add('box',x0=px,x1=px+q,y0=0.08,y1=y0-0.02,z0=pz,z1=pz+q,
              top=None,side=MT,bottom=None,tiers=('mid',),meta={'type':'post'},name='canopy_post')
        # top collar under the soffit
        b.add('box',x0=px-0.04,x1=px+q+0.04,y0=y0-0.14,y1=y0-0.02,z0=pz-0.04,z1=pz+q+0.04,
              top=MT,side=MT,bottom=MT,tiers=('near',),meta={'type':'post'},name='canopy_cap')
        if i==0:
            # downspout on the front-left post, from the fascia to a shoe at the plate
            sx,sz=px-0.10,pz+q*0.5-0.035
            b.add('box',x0=sx,x1=sx+0.07,y0=0.20,y1=fb+0.02,z0=sz,z1=sz+0.07,
                  top=MT,side=MT,bottom=MT,tiers=('near','mid'),meta={'type':'trim'},name='downspout')
            b.add('box',x0=sx-0.02,x1=sx+0.09,y0=0.08,y1=0.18,z0=sz-0.04,z1=sz+0.11,
                  top=MT,side=MT,bottom=MT,tiers=('near',),meta={'type':'trim'},name='downspout_shoe')
    # far: deck slab (and the fascia silhouette) only — not a box to the ground
    b.add('box',x0=-w/2,x1=w/2,y0=fb,y1=y1,z0=0.0,z1=depth,
          top=DK,side=CAN,bottom=SOF,tiers=('far',),meta={'type':'porch_roof'},name='canopy_far',
          drop=((1,0,0),(-1,0,0)))
    b.origin=(0.0,depth/2,w,depth)
    b.snap={'grid':GRID,'module':w,'type':'canopy','ends':[[-w/2,0,depth/2],[w/2,0,depth/2]],'face_z':depth,'plate_y':y1}
    return b

def awning_6m():
    """6 m wall-mounted striped awning: iron frame, valance, end caps and a wall plate. No canvas collision."""
    w=6.0; depth=1.20
    b=Piece('urb_awning_6m','awning',snap=None,drop=[(0,-w/2,-1),(0,w/2,1)],budget=(160,60,16),
            wall='W_stucco',tint=WHITE,roof='R_flat',style='modular')
    b.no_door=True; b.base_y=0.04
    b.add('awning',side='front',wall=0.0,s0=-w/2+0.14,s1=w/2-0.14,y_top=1.05,depth=depth,drop=0.45,valance=0.22,region='AW_navy',arms=True)
    WP={'t':'swatch','mat':'S_stucco','tint':WHITE}
    IR={'t':'trim','mat':'T_metal','tint':(0.10,0.10,0.10)}
    CV={'t':'trim','mat':'T_dark','tint':(0.10,0.16,0.28)}
    # structural wall plate (type=walls) so collision is the mount, not the canvas
    b.add('box',x0=-w/2,x1=w/2,y0=0.90,y1=1.04,z0=-0.10,z1=-0.02,
          top=WP,side=WP,bottom=WP,tiers=('near','mid'),meta={'type':'walls','W':1.04,'box':(-w/2,w/2,0.90,1.04,-0.10,-0.02)},name='awn_wall',
          drop=((1,0,0),(-1,0,0),(0,0,1)))
    # front rail just outside the valance (2 cm gap off the canvas)
    b.add('box',x0=-w/2+0.16,x1=w/2-0.16,y0=0.58,y1=0.64,z0=depth+0.03,z1=depth+0.07,
          top=IR,side=IR,bottom=IR,tiers=('near','mid'),meta={'type':'awning'},name='awn_rail',overlay=True)
    # end caps covering the open canvas / valance ends (near)
    for sx in (-w/2+0.10, w/2-0.16):
        b.add('box',x0=sx,x1=sx+0.06,y0=0.38,y1=0.64,z0=depth-0.06,z1=depth+0.03,
              top=CV,side=IR,bottom=CV,tiers=('near',),meta={'type':'awning'},name='awn_endcap',overlay=True)
    # iron wall brackets at the arms
    for sx in (-w/2+0.20,w/2-0.26):
        b.add('box',x0=sx,x1=sx+0.06,y0=0.70,y1=0.98,z0=0.02,z1=0.10,
              top=IR,side=IR,bottom=IR,tiers=('near',),meta={'type':'trim'},name='awn_bracket',overlay=True,
              drop=((0,0,-1),))
    # closed far hull at the snap ends
    AW={'t':'trim','mat':'T_dark','tint':(0.10,0.16,0.28)}
    b.add('box',x0=-w/2,x1=w/2,y0=0.38,y1=1.08,z0=0.0,z1=depth,
          top=AW,side=AW,bottom=AW,tiers=('far',),meta={'type':'awning'},name='awning_far')
    b.origin=(0.0,depth/2,w,depth)
    b.snap={'grid':GRID,'module':w,'type':'awning','ends':[[-w/2,0,0],[w/2,0,0]],'face_z':depth,'plate_y':1.08}
    return b

def wh_roof_sawtooth():
    """12 x 24 m sawtooth roof: three monitor bays on the warehouse plate."""
    w,d,H=WH_W,WH_D,WH_H
    b=Piece('urb_wh_roof_sawtooth_12x24','wh_roof',snap=None,drop=[],budget=(360,120,16),wall='W_stucco',tint=GREY,roof='R_flat',style='modular')
    b.floor=0.0; b.no_door=True; b.col_mode='roof'
    RF={'t':'roof','mat':'R_flat','tint':(1,1,1),'flat_deck':True}
    TB={'t':'trim','mat':'T_white','tint':(0.9,0.9,0.88)}
    GL={'t':'trim','mat':'T_dark','tint':(0.20,0.24,0.28)}
    SOF={'t':'swatch','mat':'S_soffit','tint':(0.9,0.9,0.88)}
    bay=d/3.0
    for i in range(3):
        z0=-d/2+i*bay+0.03; z1=z0+bay-0.06
        # low deck, vertical glazed monitor, high lip — gapped in Y so stacked boxes stay clean
        b.add('box',x0=-w/2+0.02,x1=w/2-0.02,y0=H,y1=H+0.14,z0=z0,z1=z1-2.10,
              top=RF,side=TB,bottom=SOF,tiers=('near','mid'),meta={'type':'roof'},name='tooth_deck',drop=((1,0,0),(-1,0,0)))
        b.add('box',x0=-w/2+0.02,x1=w/2-0.02,y0=H+0.16,y1=H+1.40,z0=z1-2.10,z1=z1-1.96,
              top=None,side=GL,bottom=None,tiers=('near','mid'),meta={'type':'cap'},name='tooth_monitor',
              drop=((1,0,0),(-1,0,0)))
        b.add('box',x0=-w/2+0.02,x1=w/2-0.02,y0=H+1.26,y1=H+1.40,z0=z1-1.94,z1=z1,
              top=RF,side=TB,bottom=SOF,tiers=('near','mid'),meta={'type':'roof'},name='tooth_lip',drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=H,y1=H+1.40,z0=-d/2,z1=d/2,
          top=RF,side=TB,bottom=SOF,tiers=('far',),meta={'type':'roof'},name='tooth_far')
    b.origin=(0.0,0.0,w,d); b.base_y=H
    b.snap={'grid':GRID,'type':'wh_roof','module':w,'depth':d,'plate_y':H}
    return b

def wh_roof_shed():
    """12 x 24 m shed roof, stepped toward +Z."""
    w,d,H=WH_W,WH_D,WH_H
    b=Piece('urb_wh_roof_shed_12x24','wh_roof',snap=None,drop=[],budget=(280,100,16),wall='W_stucco',tint=GREY,roof='R_flat',style='modular')
    b.floor=0.0; b.no_door=True; b.col_mode='roof'
    RF={'t':'roof','mat':'R_flat','tint':(1,1,1),'flat_deck':True}
    TB={'t':'trim','mat':'T_white','tint':(0.9,0.9,0.88)}
    SOF={'t':'swatch','mat':'S_soffit','tint':(0.9,0.9,0.88)}
    # solid terraces from the plate up so the mid front elevation matches the closed far hull
    steps=((0.00,0.16,-d/2, -d/2+8.0),(0.00,1.16,-d/2+8.04,-d/2+16.0),(0.00,2.16,-d/2+16.04,d/2))
    for y0,y1,z0,z1 in steps:
        b.add('box',x0=-w/2+0.02,x1=w/2-0.02,y0=H+y0,y1=H+y1,z0=z0,z1=z1,
              top=RF,side=TB,bottom=SOF,tiers=('near','mid'),meta={'type':'roof'},name='shed_deck',drop=((1,0,0),(-1,0,0)))
    b.add('box',x0=-w/2,x1=w/2,y0=H,y1=H+2.16,z0=-d/2,z1=d/2,
          top=RF,side=TB,bottom=SOF,tiers=('far',),meta={'type':'roof'},name='shed_far')
    b.origin=(0.0,0.0,w,d); b.base_y=H
    b.snap={'grid':GRID,'type':'wh_roof','module':w,'depth':d,'plate_y':H}
    return b

def wh_dock():
    """12 m loading dock in front of a warehouse wall, with a railed stair and bumpers."""
    w=12.0; depth=2.40; fl=1.10
    b=Piece('urb_wh_dock_12m','wh_dock',snap=None,drop=[(0,-w/2,-1),(0,w/2,1)],budget=(360,120,32),
            wall='W_stucco',tint=GREY,roof='R_flat',style='modular')
    b.floor=fl; b.no_door=True
    DK={'t':'swatch','mat':'S_concrete','tint':(0.62,0.62,0.60)}
    BM={'t':'trim','mat':'T_dark','tint':(0.18,0.18,0.18)}
    b.add('box',x0=-w/2,x1=w/2,y0=0.0,y1=fl,z0=0.0,z1=depth,
          top=DK,side=DK,bottom=None,tiers=('near','mid','far'),
          meta={'type':'floor','top':fl,'rect':(-w/2,w/2,0.0,depth),'side':'front'},name='dock')
    # stair at the left end, official stoop, rails meet posts
    b.add('stoop',side='front',c=-w/2+1.10,wall=depth,w=2.00,depth=1.80,floor=fl,rails=True)
    # cheek plates at the official rail_flange x so the wall-return feet meet a wall
    CK={'t':'swatch','mat':'S_concrete','tint':(0.62,0.62,0.60)}
    c_st=-w/2+1.10; stoop_w=2.00
    for xr in (c_st-stoop_w/2+0.14, c_st+stoop_w/2-0.14):
        b.add('box',x0=xr-0.06,x1=xr+0.06,y0=fl,y1=fl+0.95,z0=depth-0.08,z1=depth,
              top=CK,side=CK,bottom=None,tiers=('near','mid'),meta={'type':'trim'},name='rail_return')
    # dock bumpers along the front edge
    for x in (-4.0,0.0,4.0):
        b.add('box',x0=x-0.45,x1=x+0.45,y0=fl-0.22,y1=fl+0.08,z0=depth+0.02,z1=depth+0.16,
              top=BM,side=BM,bottom=BM,tiers=('near','mid'),meta={'type':'trim'},name='bumper',overlay=True)
    # far hull covers the railed stair so mid/far silhouettes line up (SPEC §2)
    b.add('box',x0=c_st-stoop_w/2,x1=c_st+stoop_w/2,y0=0.0,y1=fl+0.95,z0=depth,z1=depth+1.80,
          top=CK,side=CK,bottom=None,tiers=('far',),meta={'type':'trim'},name='stair_far')
    b.origin=(0.0,depth/2,w,depth+1.80)
    b.snap={'grid':GRID,'module':w,'type':'wh_dock','ends':[[-w/2,0,depth/2],[w/2,0,depth/2]],'face_z':depth,'plate_y':fl}
    return b

def svc_front_cinema():
    w=6.0; H=SVC_H
    ops=[dict(k='shopdoor',c=0.0,w=1.6,t0=0.0,t1=3.0,depth=0.35),
         dict(k='storefront',c=-2.0,w=1.6,t0=0.80,t1=2.80,depth=0.10),
         dict(k='storefront',c=2.0,w=1.6,t0=0.80,t1=2.80,depth=0.10)]
    def ex(b,w_):
        MR={'t':'trim','mat':'T_dark','tint':(0.12,0.12,0.12)}; LT={'t':'trim','mat':'T_white','tint':(0.95,0.90,0.70)}
        # marquee soffit + fascia (porch_roof: walk under it)
        b.add('box',x0=-2.6,x1=2.6,y0=3.10,y1=3.22,z0=0.02,z1=1.50,
              top=MR,side=MR,bottom={'t':'swatch','mat':'S_soffit','tint':(0.9,0.9,0.88)},
              tiers=('near','mid'),meta={'type':'porch_roof'},name='marquee')
        b.add('box',x0=-2.6,x1=2.6,y0=3.24,y1=3.70,z0=1.32,z1=1.50,
              top=LT,side=LT,bottom=LT,tiers=('near','mid'),meta={'type':'porch_roof'},name='marquee_fascia')
        b.add('sign',side='front',wall=0.0,c=0.0,y=3.85,w=3.6,h=0.50,region='T_dark')
        b.add('fixtures',side='front',wall=0.0,items=[('sconce',-2.6,2.3),('sconce',2.6,2.3)])
    return slab('urb_svc_front_6m_cinema',w,T_F,H,ops,'svc_front',(750,220,12),'W_stucco',(0.62,0.16,0.16),parapet=SVC_PAR,sills=False,extra=ex,no_door=False,foundation=False)

def svc_front_bigbox():
    w=6.0; H=5.40
    ops=[dict(k='shopdoor',c=0.0,w=1.8,t0=0.0,t1=3.0,depth=0.35),
         dict(k='storefront',c=-1.9,w=1.5,t0=0.80,t1=3.00,depth=0.10),
         dict(k='storefront',c=1.9,w=1.5,t0=0.80,t1=3.00,depth=0.10)]
    def ex(b,w_):
        b.add('sign',side='front',wall=0.0,c=0.0,y=3.40,w=5.2,h=0.80,region='T_dark')
        # entry canopy on posts
        CAN={'t':'trim','mat':'T_white','tint':(0.90,0.90,0.88)}; MT={'t':'trim','mat':'T_metal','tint':(0.2,0.2,0.21)}
        SOF={'t':'swatch','mat':'S_soffit','tint':(0.88,0.88,0.86)}
        b.add('box',x0=-2.2,x1=2.2,y0=3.05,y1=3.20,z0=0.04,z1=1.80,
              top=CAN,side=CAN,bottom=SOF,tiers=('near','mid'),meta={'type':'porch_roof'},name='entry_canopy')
        for px in (-2.04,1.88):
            b.add('box',x0=px,x1=px+0.16,y0=0.0,y1=3.03,z0=1.58,z1=1.74,
                  top=MT,side=MT,bottom=None,tiers=('near','mid'),meta={'type':'post'},name='canopy_post')
        b.add('fixtures',side='front',wall=0.0,items=[('sconce',-2.7,2.4),('sconce',2.7,2.4)])
    b=slab('urb_svc_front_6m_bigbox',w,T_F,H,ops,'svc_front',(800,240,12),'W_stucco',GREY,parapet=1.10,sills=False,extra=ex,no_door=False,foundation=False,**FAR_SHOP)
    b.floor=0.0; b.floor_lines=[4.2]
    return b

def grt_front_boarded():
    w=6.0; H=UFL+UST+0.6
    ops=[dict(k='shopdoor',c=-1.6,w=1.2,t0=0.0,t1=3.0,depth=0.25)]
    def ex(b,w_):
        BR={'t':'trim','mat':'T_dark','tint':(0.35,0.30,0.24)}
        BL={'t':'swatch','mat':'S_brick','tint':(0.62,0.38,0.30)}
        b.add('hood',c=-1.6,wall=0.0,y=3.15,w=2.0,depth=0.9,pitch=0.10)
        # boarded window panels (no half openings)
        for (c,y0,y1,hw) in ((0.6,1.10,2.50,1.3),(2.2,1.10,2.50,1.0)):
            b.add('box',x0=c-hw/2,x1=c+hw/2,y0=y0,y1=y1,z0=0.002,z1=0.05,
                  top=BR,side=BR,bottom=BR,name='board',overlay=True,tiers=('near','mid'),drop=((1,0,0),(-1,0,0)))
        # water table, inset from ends, no ground bottom
        b.add('box',x0=-w_/2+0.50,x1=w_/2-0.50,y0=0.00,y1=0.42,z0=0.00,z1=0.06,
              top=BL,side=BL,bottom=None,tiers=('near','mid'),meta={'type':'trim'},name='belt',overlay=True,
              drop=((1,0,0),(-1,0,0)))
        b.add('sign',side='front',wall=0.0,c=1.0,y=3.20,w=2.4,h=0.40,region='T_dark')
    return slab('urb_grt_front_6m_boarded',w,T_F,H,ops,'grt_front',(600,180,12),'W_stucco',(0.78,0.76,0.72),parapet=0.80,sills=False,extra=ex,no_door=False,foundation=False,**FAR_BLANK)

def grt_front_abandoned():
    w=6.0; H=4.20
    ops=[dict(k='apt_door',c=0.0,w=1.0,t0=0.0,t1=2.2,depth=0.20)]
    def ex(b,w_):
        BR={'t':'trim','mat':'T_dark','tint':(0.35,0.30,0.24)}
        BL={'t':'swatch','mat':'S_brick','tint':(0.62,0.38,0.30)}
        ST={'t':'swatch','mat':'S_stucco','tint':(0.78,0.76,0.72)}
        b.add('box',x0=-1.0,x1=-0.15,y0=1.10,y1=2.40,z0=0.002,z1=0.05,
              top=BR,side=BR,bottom=BR,name='board',overlay=True,tiers=('near',),drop=((1,0,0),(-1,0,0)))
        b.add('box',x0=0.15,x1=1.0,y0=1.10,y1=2.40,z0=0.002,z1=0.05,
              top=BR,side=BR,bottom=BR,name='board',overlay=True,tiers=('near',),drop=((1,0,0),(-1,0,0)))
        b.add('box',x0=-w_/2+0.50,x1=w_/2-0.50,y0=0.00,y1=0.42,z0=0.002,z1=0.06,
              top=BL,side=BL,bottom=None,tiers=('near','mid'),meta={'type':'trim'},name='belt',overlay=True,
              drop=((1,0,0),(-1,0,0)))
        # proud false-front panel on the parapet face only (no underside under the coping)
        b.add('box',x0=-w_/2+0.04,x1=w_/2-0.04,y0=H+0.20,y1=H+1.70,z0=0.002,z1=0.08,
              top=None,side=ST,bottom=None,tiers=('near','mid'),meta={'type':'cap'},name='false_front',overlay=True,
              drop=((0,1,0),(0,-1,0),(0,0,-1)))
        b.add('sign',side='front',wall=0.0,c=0.0,y=3.30,w=2.8,h=0.40,region='T_dark')
    b=slab('urb_grt_front_6m_abandoned',w,T_F,H,ops,'grt_front',(650,200,12),'W_stucco',(0.76,0.74,0.70),parapet=1.85,sills=False,extra=ex,no_door=False,foundation=False,**FAR_BLANK)
    b.floor=0.0; b.floor_lines=[H]
    return b

def grt_fireescape():
    """3-storey fire escape that stands in front of a 6 m wall. Posts type=post; rails type=rail and meet the posts."""
    w=6.0; x0,x1=-1.60,1.60; depth=1.20; q=0.06
    b=Piece('urb_grt_fireescape_6m','grt_escape',snap=None,drop=[],budget=(500,160,120),
            wall='W_stucco',tint=WHITE,roof='R_flat',style='modular')
    b.no_door=True
    SL={'t':'swatch','mat':'S_concrete','tint':(0.50,0.50,0.48)}
    MT={'t':'trim','mat':'T_metal','tint':(0.20,0.18,0.16)}
    wall=0.0; z0,z1=wall+0.004,wall+depth
    levels=[UFL+UST,UFL+2*UST]; rh=1.00
    top=max(levels)+rh
    y_lo,y_hi=levels
    def post(px,pz,ya,yb,tiers):
        # 2 cm Y-gaps so stacked boxes are not booleaned into extra tris
        # bottoms are kept so the far cage is a closed hull
        b.add('box',x0=px,x1=px+q,y0=ya,y1=yb,z0=pz,z1=pz+q,
              top=MT,side=MT,bottom=MT,tiers=tiers,meta={'type':'post'},name='fe_post')
    def rail(xa,xb,za,zb,ya,yb):
        b.add('box',x0=xa,x1=xb,y0=ya,y1=yb,z0=za,z1=zb,
              top=MT,side=MT,bottom=MT,tiers=('near',),meta={'type':'rail'},name='fe_rail',overlay=True)
    # landings on every tier so mid and far share the front silhouette
    for y in levels:
        b.add('box',x0=x0,x1=x1,y0=y-0.10,y1=y,z0=z0,z1=z1,
              top=SL,side=SL,bottom=SL,tiers=('near','mid','far'),meta={'type':'stoop'},name='fe_land')
        # near posts sit on each landing, gapped above the deck
        for px,pz in ((x0,z0),(x1-q,z0),(x0,z1-q),(x1-q,z1-q)):
            post(px,pz,y+0.02,y+rh,('near',))
        rail(x0+q+0.002,x1-q-0.002,z1-q,z1,y+rh-0.05,y+rh)
        rail(x0,x0+q,z0+q+0.002,z1-q-0.002,y+rh-0.05,y+rh)
        rail(x1-q,x1,z0+q+0.002,z1-q-0.002,y+rh-0.05,y+rh)
    # mid/far: only the two front posts (back posts coincide in the front elevation), segmented around landings
    for px,pz in ((x0,z1-q),(x1-q,z1-q)):
        post(px,pz,0.0,y_lo-0.12,('mid','far'))
        post(px,pz,y_lo+0.02,y_hi-0.12,('mid','far'))
        post(px,pz,y_hi+0.02,top,('mid','far'))
    # inter-landing stair along the front, between the posts and between the decks
    sx0,sx1=x0+q+0.08,x0+1.50
    b.add('box',x0=sx0,x1=sx1,y0=y_lo+0.02,y1=y_hi-0.12,z0=z1-0.18,z1=z1,
          top=MT,side=MT,bottom=MT,tiers=('mid','far'),meta={'type':'trim'},name='fe_stair_hull')
    n_tr=8; rise=(y_hi-y_lo)/n_tr; run=(sx1-sx0)/n_tr
    for i in range(n_tr):
        yy=y_lo+i*rise; xx=sx0+i*run
        b.add('box',x0=xx,x1=xx+run+0.02,y0=yy,y1=yy+0.04,z0=z1-0.18,z1=z1,
              top=SL,side=MT,bottom=None,tiers=('near',),meta={'type':'stoop'},name='fe_tread',overlay=True)
    # drop ladder in front of the lowest landing (does not intersect the landing boxes)
    lz=z1+0.02; lx0=x0+0.15
    for px in (lx0,lx0+0.55):
        post(px,lz,0.0,y_lo-0.12,('near',))
    rail(x0,x0+q,z1+0.002,lz-0.002,y_lo-0.05,y_lo)
    n=max(5,int(y_lo/0.32))
    for i in range(1,n):
        yy=i*(y_lo/n)
        b.add('box',x0=lx0+q,x1=lx0+0.55,y0=yy-0.02,y1=yy+0.02,z0=lz,z1=lz+q,
              top=MT,side=MT,bottom=MT,tiers=('near',),meta={'type':'trim'},name='fe_rung',overlay=True)
    b.add('box',x0=lx0,x1=lx0+0.55+q,y0=0.0,y1=y_lo-0.12,z0=lz,z1=lz+q,
          top=MT,side=MT,bottom=MT,tiers=('mid','far'),meta={'type':'trim'},name='fe_ladder_hull')
    b.origin=(0.0,depth/2,w,depth+0.20)
    b.snap={'grid':GRID,'module':w,'type':'grt_escape','ends':[[-w/2,0,depth/2],[w/2,0,depth/2]],'face_z':depth,'plate_y':top}
    b.ground_reach=True
    return b

def catalogue(group):
    if group!='urban': return []
    out=[]
    for fn in (
        lambda: brk_front(3), lambda: brk_side(3,14.0), lambda: brk_back(3), lambda: brk_roof(3,14.0),
        lambda: brk_front(4), lambda: brk_side(4,16.0), lambda: brk_back(4), lambda: brk_roof(4,16.0),
        lambda: brk_front_corner(3), lambda: brk_front_corner(4),
        lambda: brk_corner_pier(3), lambda: brk_corner_pier(4),
        lambda: wh_front('rollup'), lambda: wh_front('office'), wh_side, wh_back, wh_roof,
        wh_roof_sawtooth, wh_roof_shed, wh_dock,
        lambda: svc_front('pharmacy','AW_navy'), lambda: svc_front('laundry','AW_green'),
        lambda: svc_front('pawn','AW_black'), svc_front_fastfood, svc_front_cinema, svc_front_bigbox,
        lambda: apt_front(False), lambda: apt_front(True), apt_side, apt_back,
        stg_front, stg_side, stg_back,
        twr_front, twr_side, twr_back, twr_roof,
        twr_front_glass, twr_side_glass, twr_back_glass, twr_corner_pier,
        storefront_bay, civ_column, civ_colonnade, civ_pediment, civ_cornice, civ_parapet,
        canopy_6m, awning_6m,
        grt_front_boarded, grt_front_abandoned, grt_fireescape,
    ):
        out.append(('urban', fn()))
    return out
