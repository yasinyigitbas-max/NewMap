"""Assemble example buildings from modular pieces on the grid.
near/mid = the placed pieces merged (one mesh, one material: the pieces share one atlas);
far + col = generated from the snapped outline (one closed hull with the baked far facade, <=12 boxes), because a sum of
per-piece far tiers would not be a closed hull and would exceed the far budget.
usage: assemble.py houses|shops"""
import sys, os, json, math, shutil
GROUP=sys.argv[1]; os.environ['KIT_ATLAS']={'houses':'house','shops':'city'}[GROUP]
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from mod_core import *
from mod_pieces import CREAM,WHITE,BLUEG
import numpy as np
sys.path.insert(0,KIT+'/tools')
import validate as V
from geom import write_glb
from export import export_building
P=KIT+'/modular/pieces'; OUT=KIT+'/modular/examples'
SIDES={'front':0,'right':90,'back':180,'left':270}

def rot(th):
    t=math.radians(th); c,s=round(math.cos(t),9),round(math.sin(t),9)
    return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def load_piece(g,n,tier):
    gl,acc=V.load(f'{P}/{g}/{n}/mod_{n}_{tier}.glb'); p=gl.meshes[0].primitives[0]; a=p.attributes
    return dict(pos=acc(a.POSITION).astype(np.float32),nor=acc(a.NORMAL).astype(np.float32),tan=acc(a.TANGENT).astype(np.float32),
                uv=acc(a.TEXCOORD_0).astype(np.float32),col=acc(a.COLOR_0)[:,:3].astype(np.float32),idx=acc(p.indices).astype(np.uint32))
def stats(g,n): return json.load(open(f'{P}/{g}/{n}/stats.json'))

def side_items(W,D,side,names,T,g):
    """pieces along one side, left to right as seen from outside; returns (name,x,z,rot) and world openings"""
    L=W if side in ('front','back') else D
    widths=[stats(g,n)['snap']['module'] for n in names]
    assert abs(sum(widths)-L)<1e-6, f'{side}: modules {widths} do not fill {L} m'
    items=[]; ops=[]; s0=0.0
    for n,w in zip(names,widths):
        sc=s0+w/2; s0+=w
        if side=='front': x,z=-W/2+sc,D/2-T/2
        elif side=='right': x,z=W/2-T/2,D/2-sc
        elif side=='back': x,z=W/2-sc,-D/2+T/2
        else: x,z=-W/2+T/2,-D/2+sc
        items.append((n,x,z,SIDES[side]))
        for o in stats(g,n)['openings']:
            o=dict(o); c=o['c']
            o['c']=round({'front':x+c,'right':z-c,'back':x-c,'left':z+c}[side],3)
            ops.append((side,o))
    return items,ops

def merge(g,items,tier):
    M={k:[] for k in ('pos','nor','tan','uv','col','idx')}; base=0
    for (n,x,z,th) in items:
        m=load_piece(g,n,tier); R=rot(th).astype(np.float32)
        M['pos'].append(m['pos']@R.T+np.array([x,0,z],np.float32)); M['nor'].append(m['nor']@R.T)
        t=m['tan'].copy(); t[:,:3]=t[:,:3]@R.T; M['tan'].append(t); M['uv'].append(m['uv']); M['col'].append(m['col'])
        M['idx'].append(m['idx']+base); base+=len(m['pos'])
    return {k:np.concatenate(v) for k,v in M.items()}

def house(name,W,D,sides,roof_tag,end_tag,wall='W_stucco',tint=CREAM,roofmat='R_comp',budget='mod_house_small',corners=False):
    g='houses'; items=[]; ops={}
    for sd,names in sides.items():
        it,op=side_items(W,D,sd,names,T_H,g); items+=it
        for (s_,o) in op: ops.setdefault(s_,[]).append(o)
    if corners:   # corner boards belong to sided houses; stucco corners are plain
        for (cx,cz,th) in ((W/2,D/2,0),(W/2,-D/2,90),(-W/2,-D/2,180),(-W/2,D/2,270)): items.append(('house_trim_corner_white',cx,cz,th))
    nr=int(round(W/3.0)); assert abs(nr*3.0-W)<1e-6 and abs(D-7.5)<1e-6
    for i in range(nr):
        x=-W/2+1.5+3.0*i
        if i==0: items.append((f'house_roof_gable_endl_3m_{end_tag}',x,0.0,0))
        elif i==nr-1: items.append((f'house_roof_gable_endr_3m_{end_tag}',x,0.0,0))
        else: items.append((f'house_roof_gable_run_3m_{roof_tag}',x,0.0,0))
    # brick chimney on the ridge, over the second roof piece from the left (living-room end), 0.5 m grid
    items.append(('house_roof_chimney_brick'+('_clay' if roofmat=='R_clay' else ''),-W/2+3.0+1.0,0.0,0))   # the clay roofs are lower-pitched: matching chimney
    # equivalent monolithic hull for far + collision
    from build import Building
    eq=Building(name,'mod',wall=wall,tint=tint,roof=roofmat,style='modular'); eq.floor=FL; eq.storeys=1; eq.budget=budget
    from mod_pieces import CPITCH, PITCH
    pt=CPITCH if roofmat=='R_clay' else PITCH
    eq.add('block',x0=-W/2,x1=W/2,z0=-D/2,z1=D/2,W=HW,roof='gable',axis='x',pitch=pt,o=0.45,f=0.18,rake=0.3,openings=ops,downspouts=(),foundation=True)
    eq._outline=dict(kind='house',W=W,D=D,wall=wall,tint=list(tint),roof=roofmat,budget=budget,pitch=pt)
    return g,items,eq,budget

def shop(name,bays,D=12.0,tint=CREAM,budget=None):
    g='shops'; W=6.0*len(bays); items=[]; ops={}
    it,op=side_items(W,D,'front',[f'shop_front_6m_{b}' for b in bays],T_S,g); items+=it
    for sd,pc in (('right','shop_side_12m_stucco'),('left','shop_side_12m_stucco_l')):   # mirrored pair: service doors toward the back
        it,op2=side_items(W,D,sd,[pc],0.3,g); items+=it; op+=op2
    it,op3=side_items(W,D,'back',['shop_back_6m_stucco']*len(bays),0.3,g); items+=it; op+=op3
    for (s_,o) in op: ops.setdefault(s_,[]).append(o)
    items+=[('shop_trim_cornice_corner_r',W/2,D/2,0),('shop_trim_cornice_corner_l',-W/2,D/2,0)]
    for i in range(len(bays)):
        x=-W/2+3.0+6.0*i
        if len(bays)==1: items.append(('shop_roof_6m_single',x,0.0,0))
        elif i==0: items.append(('shop_roof_6m_end',x,0.0,0))
        elif i==len(bays)-1: items.append(('shop_roof_6m_end',x,0.0,180))
        else: items.append(('shop_roof_6m_mid',x,0.0,0))
    from build import Building
    budget=budget or ('shop' if len(bays)>1 else 'corner_shop')
    eq=Building(name,'mod',wall='W_stucco',tint=tint,roof='R_flat',style='modular'); eq.floor=0.0; eq.storeys=1; eq.budget=budget; eq.frontage=W
    eq.floor_lines=[GF]
    eq.add('block',x0=-W/2,x1=W/2,z0=-D/2,z1=D/2,W=SW,roof='flat',parapet=PAR,cap='T_white',gutters=False,openings=ops,foundation=False)
    eq._outline=dict(kind='shop',W=W,D=D,wall='W_stucco',tint=list(tint),roof='R_flat',budget=budget)
    return g,items,eq,budget

EX={'houses':[
    ('ex_house_ranch_stucco',lambda: house('ex_house_ranch_stucco',9.0,7.5,{
        'front':['house_wall_3m_window_stucco','house_wall_3m_door_stucco','house_wall_3m_window_stucco'],
        'right':['house_wall_4p5m_window_small_stucco','house_wall_3m_window_stucco'],
        'back':['house_wall_4p5m_utility_stucco','house_wall_4p5m_window_small_stucco'],
        'left':['house_wall_3m_window_stucco','house_wall_4p5m_utility_stucco']},'comp','comp_stucco')),
    ('ex_house_garage_siding',lambda: house('ex_house_garage_siding',9.0,7.5,{
        'front':['house_wall_3m_garage_siding','house_wall_3m_door_siding','house_wall_3m_window_siding'],
        'right':['house_wall_3m_window_siding','house_wall_4p5m_utility_siding'],
        'back':['house_wall_4p5m_window_small_siding','house_wall_4p5m_utility_siding'],
        'left':['house_wall_4p5m_window_small_siding','house_wall_3m_window_siding']},'comp','comp_siding',wall='W_siding',tint=BLUEG,corners=True)),
    ('ex_house_cottage_clay',lambda: house('ex_house_cottage_clay',9.0,7.5,{
        'front':['house_wall_3m_window_pair_stucco_white','house_wall_3m_door_stucco_white_clayhood','house_wall_3m_window_stucco_white'],
        'right':['house_wall_3m_window_stucco_white','house_wall_4p5m_utility_stucco_white'],
        'back':['house_wall_4p5m_window_small_stucco_white','house_wall_4p5m_window_small_stucco_white'],
        'left':['house_wall_4p5m_window_small_stucco_white','house_wall_3m_window_stucco_white']},'clay','clay_stucco_white',roofmat='R_clay',tint=WHITE)),
  ],'shops':[
    ('ex_shop_row_cafe_books',lambda: shop('ex_shop_row_cafe_books',['cafe_red','books_green'])),
    ('ex_shop_corner_bakery',lambda: shop('ex_shop_corner_bakery',['bakery_navy'],tint=(0.97,0.88,0.62))),
  ]}

def run():
    """write each example's layout.json (the authoring result), then bake it with merge_assembly (the runtime step)"""
    import merge_assembly as MA
    res={}
    for name,fn in EX[GROUP]:
        g,items,eq,budget=fn()
        d=f'{OUT}/{name}'; os.makedirs(d,exist_ok=True)
        lay={'name':name,'group':g,'outline':eq._outline,'pieces':[dict(piece=n,x=round(x,3),z=round(z,3),rot_y=th) for (n,x,z,th) in items]}
        json.dump(lay,open(f'{d}/layout.json','w'),indent=1)
        info=MA.merge_layout(f'{d}/layout.json'); tri,bud=info['tris'],info['budget']
        over=[t for t,k in zip(('near','mid','far'),range(3)) if tri[t]>bud[k]]
        print(name,tri,'budget',bud,'OVER' if over else 'ok',over,flush=True); res[name]=info
    return res
if __name__=='__main__': run()
