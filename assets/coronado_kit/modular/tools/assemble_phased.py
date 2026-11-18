"""Assemble Phase D snap-in examples (brick row, warehouse, service row, apartment, storage, 10-sty office).
usage: python3 assemble_phased.py [name ...]
Writes layout.json under modular/examples/<name>/ then merge_assembly.py (no Blender)."""
import sys, os, json, math
HERE=os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.environ['KIT_ATLAS']='city'
from merge_assembly import merge_layout
from mod_phased import UFL, UST, TWR_H, TWR_W, TWR_D, WH_H, WH_D, WH_W, SVC_H, SVC_D, APT_D
from mod_core import KIT

OUT=KIT+'/modular/examples'
BRK=(1.0,1.0,1.0); GREY=(0.82,0.82,0.80); WHITE=(0.97,0.96,0.93); CREAM=(0.93,0.86,0.72); WARM=(0.92,0.86,0.78)

def item(piece,x,z,rot_y=0,y=0,group='urban'):
    it={'piece':piece,'x':round(x,3),'z':round(z,3),'rot_y':int(rot_y)}
    if y: it['y']=round(y,3)
    if group!='urban': it['group']=group
    return it

def sides_front(names, W, D, T, y=0, group='urban'):
    # left to right as seen from +Z, origin at facade (z = D/2 - T/2)
    out=[]; s0=0.0; # widths from 6 or 8 or 12 known by naming? pass pairs
    return out

def layout(name, kind, W, D, storeys, wall, tint, budget, pieces, **ol):
    o=dict(kind=kind,W=W,D=D,storeys=storeys,wall=wall,tint=list(tint),budget=budget,
           floor=ol.get('floor',UFL),storey=ol.get('storey',UST),parapet=ol.get('parapet',0.9),
           sills=ol.get('sills',False),foundation=ol.get('foundation',True))
    if ol.get('far_facade'): o['far_facade']=ol['far_facade']; o['far_tile']=ol.get('far_tile',3.0)
    for k in ('roof',):
        if k in ol: o[k]=ol[k]
    return {'name':name,'group':'urban','outline':o,'pieces':pieces}

def brk_row():
    # 3 bays x 14 m, 3 storeys — same footprint as urb_brick_row
    W,D,sty,T=18.0,14.0,3,0.45
    fronts=['urb_brk_front_6m_3sty']*3
    backs=['urb_brk_back_6m_3sty']*3
    pcs=[]
    for i,n in enumerate(fronts):
        c=-W/2+3.0+6.0*i
        pcs.append(item(n,c, D/2-T/2, 0))
    for i,n in enumerate(backs):
        c=W/2-3.0-6.0*i
        pcs.append(item(n,c, -D/2+0.15, 180))
    pcs.append(item('urb_brk_side_14m_3sty',  W/2-0.15, 0.0, 90))
    pcs.append(item('urb_brk_side_14m_3sty', -W/2+0.15, 0.0, 270))
    for i in range(3):
        pcs.append(item('urb_brk_roof_6x14_3sty', -W/2+3.0+6.0*i, 0.0, 0))
    return layout('mod_brk_row', 'block', W, D, sty, 'W_brick', BRK, 'apartment', pcs,
                  parapet=1.0, sills=True, foundation=False, far_facade='F_c_tower_3', far_tile=3.0)

def wh_shed():
    # 2 bays: office + rollup, 24 x 24 m
    W,D,T=24.0,24.0,0.45
    pcs=[]
    pcs.append(item('urb_wh_front_12m_office', -6.0, D/2-T/2, 0))
    pcs.append(item('urb_wh_front_12m_rollup',  6.0, D/2-T/2, 0))
    pcs.append(item('urb_wh_back_12m',  6.0, -D/2+0.15, 180))
    pcs.append(item('urb_wh_back_12m', -6.0, -D/2+0.15, 180))
    pcs.append(item('urb_wh_side_24m',  W/2-0.15, 0.0, 90))
    pcs.append(item('urb_wh_side_24m', -W/2+0.15, 0.0, 270))
    pcs.append(item('urb_wh_roof_12x24', -6.0, 0.0, 0))
    pcs.append(item('urb_wh_roof_12x24',  6.0, 0.0, 0))
    return layout('mod_wh_shed', 'warehouse', W, D, 1, 'W_stucco', GREY, 'warehouse', pcs,
                  floor=0.0, storey=6.6, parapet=0.8, sills=False, foundation=False, far_facade='F_c_tower_3', far_tile=6.0)

def svc_row():
    # pharmacy + laundry, reuse shop sides / backs / roofs
    W,D,T=12.0,12.0,0.45
    pcs=[]
    pcs.append(item('urb_svc_front_6m_pharmacy', -3.0, D/2-T/2, 0))
    pcs.append(item('urb_svc_front_6m_laundry',   3.0, D/2-T/2, 0))
    pcs.append(item('shop_back_6m_stucco',  3.0, -D/2+0.15, 180, group='shops'))
    pcs.append(item('shop_back_6m_stucco', -3.0, -D/2+0.15, 180, group='shops'))
    pcs.append(item('shop_side_12m_stucco',   W/2-0.15, 0.0, 90, group='shops'))
    pcs.append(item('shop_side_12m_stucco_l',-W/2+0.15, 0.0, 270, group='shops'))
    pcs.append(item('shop_roof_6m_end', -3.0, 0.0, 0, group='shops'))
    pcs.append(item('shop_roof_6m_end',  3.0, 0.0, 180, group='shops'))
    return layout('mod_svc_row', 'shop', W, D, 1, 'W_stucco', CREAM, 'shop', pcs,
                  floor=0.0, storey=4.2, parapet=0.9, sills=False, foundation=False)

def apt_row():
    W,D,T=18.0,12.0,0.45
    pcs=[]
    for i in range(3):
        pcs.append(item('urb_apt_front_6m_open', -W/2+3.0+6.0*i, D/2-T/2, 0))
        pcs.append(item('urb_apt_back_6m',        W/2-3.0-6.0*i, -D/2+0.15, 180))
    pcs.append(item('urb_apt_side_12m',  W/2-0.15, 0.0, 90))
    pcs.append(item('urb_apt_side_12m', -W/2+0.15, 0.0, 270))
    return layout('mod_apt_row', 'block', W, D, 3, 'W_stucco', WHITE, 'apartment', pcs,
                  parapet=0.8, sills=True, foundation=True, far_facade='F_c_tower_3', far_tile=3.0)

def stg_row():
    W,D,T=18.0,12.0,0.45
    pcs=[]
    for i in range(3):
        pcs.append(item('urb_stg_front_6m', -W/2+3.0+6.0*i, D/2-T/2, 0))
        pcs.append(item('urb_stg_back_6m',   W/2-3.0-6.0*i, -D/2+0.15, 180))
    pcs.append(item('urb_stg_side_12m',  W/2-0.15, 0.0, 90))
    pcs.append(item('urb_stg_side_12m', -W/2+0.15, 0.0, 270))
    return layout('mod_stg_row', 'warehouse', W, D, 1, 'W_stucco', GREY, 'warehouse', pcs,
                  floor=0.0, storey=4.2, parapet=0.6, sills=False, foundation=False, far_facade='F_c_tower_3', far_tile=6.0)

def twr_office():
    # two 8 m bays (16 x 20 m): three bays summed to 5200 / 4000 on the 10-storey cap
    W,D,T=16.0,20.0,0.45
    pcs=[]
    for i in range(2):
        pcs.append(item('urb_twr_front_8m_10sty', -W/2+4.0+8.0*i, D/2-T/2, 0))
        pcs.append(item('urb_twr_back_8m_10sty',   W/2-4.0-8.0*i, -D/2+0.15, 180))
        pcs.append(item('urb_twr_roof_8x20',      -W/2+4.0+8.0*i, 0.0, 0))
    pcs.append(item('urb_twr_side_20m_10sty',  W/2-0.15, 0.0, 90))
    pcs.append(item('urb_twr_side_20m_10sty', -W/2+0.15, 0.0, 270))
    return layout('mod_twr_office', 'tower', W, D, 10, 'W_stucco', GREY, 'tower', pcs,
                  parapet=0.9, sills=False, foundation=True, far_facade='F_c_tower_3', far_tile=6.0)

DESIGNS={
    'mod_brk_row': brk_row,
    'mod_wh_shed': wh_shed,
    'mod_svc_row': svc_row,
    'mod_apt_row': apt_row,
    'mod_stg_row': stg_row,
    'mod_twr_office': twr_office,
}

if __name__=='__main__':
    want=set(sys.argv[1:])
    for name,fn in DESIGNS.items():
        if want and name not in want: continue
        L=fn(); d=f'{OUT}/{name}'; os.makedirs(d, exist_ok=True)
        path=f'{d}/layout.json'; json.dump(L, open(path,'w'), indent=1)
        M=merge_layout(path, d)
        print(name, M.get('tris'), 'budget', M.get('budget'), flush=True)
