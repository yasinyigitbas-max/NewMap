"""Residential brick bay (Yasin 21 Nov 17:28): the ck_brk3 shopfront bay without the shop. Same 6 m x 0.45 m slab, 3
storeys, snap and parapet as urb_brk_front_6m_3sty; ground floor = a front door on a stoop (rails, entry hood, sconces,
house number) at c=+1.9 (where the shop door was, so the walks laid to it still lead to a door) and a double-hung sash
window at c=-1.4 under the upper windows; white belt course over the ground floor; brick lintels/sills from the kit."""
from mod_phased import *
def brk_front_res(storeys=3):
    w=6.0; H=UFL+storeys*UST
    door_c=1.9
    ops=[dr('apt_door',door_c,0,w=1.0,h=2.2),
         wn('dh_div',-1.4,0,w=1.2,h=1.5,sill=0.8)]
    for lv in range(1,storeys):
        ops+=[wn('dh_div',-1.4,lv,w=1.2,h=1.5,sill=0.8),wn('dh_div',1.4,lv,w=1.2,h=1.5,sill=0.8)]
    def ex(b,w_):
        b.add('stoop',side='front',c=door_c,wall=0.0,w=1.6,depth=1.3,rails=True)
        b.add('hood',c=door_c,wall=0.0,y=UFL+2.40,w=1.6,depth=0.9,pitch=0.10,brackets=False)
        b.add('fixtures',side='front',wall=0.0,items=[('sconce',door_c-0.8,UFL+2.15),('number',door_c+0.75,UFL+1.55),('meter',-2.6,0.9)])
        BT={'t':'trim','mat':'T_white','tint':(0.94,0.93,0.90)}
        b.add('box',x0=-w_/2+0.02,x1=w_/2-0.02,y0=UFL+UST-0.16,y1=UFL+UST-0.02,z0=0.002,z1=0.07,
              top=BT,side=BT,bottom=BT,tiers=('near','mid'),meta={'type':'trim'},name='belt',overlay=True,
              drop=((1,0,0),(-1,0,0)))
    return slab(f'urb_brk_front_6m_{storeys}sty_res',w,T_F,H,ops,'brk_front',(900,260,16),'W_brick',BRK,
                parapet=1.0,sills=True,extra=ex,no_door=False,**FAR_BRICK)

# ---- pass 1 (review: "plain above the belt"): stone lintels over every window and a stepped brick-top cornice
LT={'t':'trim','mat':'T_concrete','tint':(0.86,0.84,0.80)}
CT={'t':'trim','mat':'T_white','tint':(0.94,0.93,0.90)}
def add_trims(b, w, ops, H):
    for o in ops:
        if not str(o['k']).startswith('dh'): continue
        hw=o['w']/2+0.10
        b.add('box',x0=o['c']-hw,x1=o['c']+hw,y0=o['t1']+0.03,y1=o['t1']+0.21,z0=0.0,z1=0.06,top=LT,side=LT,bottom=LT,
              tiers=('near',),meta={'type':'trim'},name='lintel',overlay=True,drop=((0,0,-1),))
    # pass 2: a stone plinth along the foot of the bay (the brick met the ground with no base)
    b.add('box',x0=-w/2,x1=w/2,y0=0.0,y1=0.42,z0=0.0,z1=0.05,top=LT,side=LT,bottom=LT,
          tiers=('near','mid'),meta={'type':'trim'},name='plinth',overlay=True,drop=((0,0,-1),(0,-1,0)))
    # cornice at the plate line: a deep band and a thinner drip over it (front only; the ends are capped)
    b.add('box',x0=-w/2,x1=w/2,y0=H-0.10,y1=H+0.14,z0=0.0,z1=0.16,top=CT,side=CT,bottom=CT,
          tiers=('near','mid'),meta={'type':'trim'},name='cornice',overlay=True,drop=((0,0,-1),))
    b.add('box',x0=-w/2,x1=w/2,y0=H+0.14,y1=H+0.22,z0=0.0,z1=0.24,top=CT,side=CT,bottom=CT,
          tiers=('near','mid'),meta={'type':'trim'},name='cornice_drip',overlay=True,drop=((0,0,-1),))

def _ops(b):
    return [o for p_ in b.parts if p_.kind=='block' for o in p_.kw.get('openings',{}).get('front',[])]

def brk_front_res_t(storeys=3):
    b=brk_front_res(storeys); H=UFL+storeys*UST; add_trims(b,6.0,_ops(b),H); return b

def brk_front_walkup_t(storeys=3):
    b=brk_front_walkup(storeys); b.name=f'urb_brk_front_6m_{storeys}sty_walkup_t'; H=UFL+storeys*UST
    add_trims(b,6.0,_ops(b),H); return b
