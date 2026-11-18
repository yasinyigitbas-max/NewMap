"""Merge/bake step: turn a finished modular assembly (layout.json = placed pieces) into ONE runtime building:
  mod_<name>_near.glb / _mid.glb : all placed pieces merged into one mesh, one primitive, one material (shared atlas)
  mod_<name>_far.glb             : one closed hull baked from the snapped outline + openings (far atlas)
  mod_<name>_col.glb             : <=12 collision boxes from the same outline
=> 1 draw call per tier (plus its shadow pass), validated exactly like a regular building (validate.check_file).
Loose pieces are for editor authoring only; ship only the merged output.

usage: merge_assembly.py <layout.json> [<layout.json> ...]
layout.json (written by assemble.py, or exported from the Godot editor with godot/export_layout.gd):
  {"name":..., "group":"houses"|"shops"|"urban", "outline":{"kind":"house"|"shop"|"block"|"tower"|"warehouse","W":..,"D":..,"wall":..,"tint":[..],"roof":..,
   "budget":..}, "pieces":[{"piece":..,"x":..,"z":..,"rot_y":0|90|180|270}, ...]}
No Blender needed (pure numpy + the kit's exporter), so it never competes with a running Blender."""
import sys, os, json, math, shutil
import numpy as np
HERE=os.path.dirname(os.path.abspath(__file__))

def _setup(group):
    os.environ['KIT_ATLAS']={'houses':'house','shops':'city','urban':'city'}[group]
    sys.path.insert(0,HERE)
    from mod_core import KIT
    sys.path.insert(0,KIT+'/tools')
    return KIT

SIDE_OF={0:'front',90:'right',180:'back',270:'left'}
# snap-in house cap (SPEC §7: snap-in houses 1650 cap, approved by Yasin 15 Nov 2026 19:36); regular classes come from export.BUDGET
MOD_BUDGET={'mod_house_small':(1650,500,40)}

def rot(th):
    t=math.radians(th); c,s=round(math.cos(t),9),round(math.sin(t),9)
    return np.array([[c,0,s],[0,1,0],[-s,0,c]])

def merge_tier(P,g,pieces,tier):
    import validate as V
    M={k:[] for k in ('pos','nor','tan','uv','col','idx')}; base=0
    for it in pieces:
        n=it['piece']; gg=it.get('group',g); gl,acc=V.load(f'{P}/{gg}/{n}/mod_{n}_{tier}.glb')
        assert len(gl.meshes)==1 and len(gl.meshes[0].primitives)==1, f'{n}: piece must be one primitive'
        p=gl.meshes[0].primitives[0]; a=p.attributes; R=rot(it['rot_y']).astype(np.float32)
        pos=acc(a.POSITION).astype(np.float32); M['pos'].append(pos@R.T+np.array([it['x'],float(it.get('y',0)),it['z']],np.float32))
        M['nor'].append(acc(a.NORMAL).astype(np.float32)@R.T)
        t=acc(a.TANGENT).astype(np.float32).copy(); t[:,:3]=t[:,:3]@R.T; M['tan'].append(t)
        M['uv'].append(acc(a.TEXCOORD_0).astype(np.float32)); M['col'].append(acc(a.COLOR_0)[:,:3].astype(np.float32))
        M['idx'].append(acc(p.indices).astype(np.uint32)+base); base+=len(pos)
    out={k:np.concatenate(v) for k,v in M.items()}
    # cutters (e.g. a chimney stack buried in the roof): drop other pieces' triangles lying entirely inside them
    cuts=[]; owner=np.concatenate([np.full(len(i),j) for j,i in enumerate(M['idx'])])
    for j,it in enumerate(pieces):
        cb=json.load(open(f"{P}/{it.get('group',g)}/{it['piece']}/stats.json"))['snap'].get('cut_box') if isinstance(json.load(open(f"{P}/{it.get('group',g)}/{it['piece']}/stats.json")).get('snap'),dict) else None
        if cb:
            assert it['rot_y'] in (0,180)
            x0,x1,y0,y1,z0,z1=cb; cuts.append((j,it['x']+min(x0,x1)-1e-3,it['x']+max(x0,x1)+1e-3,y0-1e-3,y1+1e-3,it['z']+min(z0,z1)-1e-3,it['z']+max(z0,z1)+1e-3))
    if cuts:
        T=out['pos'][out['idx'].reshape(-1,3)]; keep=np.ones(len(T),bool)
        for (j,x0,x1,y0,y1,z0,z1) in cuts:
            inside=((T[:,:,0]>=x0)&(T[:,:,0]<=x1)&(T[:,:,1]>=y0)&(T[:,:,1]<=y1)&(T[:,:,2]>=z0)&(T[:,:,2]<=z1)).all(1)
            keep&=~(inside&(owner.reshape(-1,3)[:,0]!=j))
        out['idx']=out['idx'].reshape(-1,3)[keep].reshape(-1)
    return out

def world_openings(P,g,pieces):
    """openings of the wall pieces in building coordinates, per side (for the far facade bake)"""
    ops={}
    for it in pieces:
        st=json.load(open(f"{P}/{it.get('group',g)}/{it['piece']}/stats.json"))
        if not st.get('openings') or it['rot_y'] not in SIDE_OF: continue
        sd=SIDE_OF[it['rot_y']]; x,z=it['x'],it['z']
        dy=float(it.get('y',0))
        for o in st['openings']:
            o=dict(o); c=o['c']; o['c']=round({'front':x+c,'right':z-c,'back':x-c,'left':z+c}[sd],3)
            if dy:
                o['t0']=round(o['t0']+dy,3); o['t1']=round(o['t1']+dy,3)
            ops.setdefault(sd,[]).append(o)
    return ops

def outline_building(name,ol,ops):
    from mod_core import FL,HW,SW,PAR,GF
    from build import Building
    W,D=ol['W'],ol['D']
    if ol['kind']=='house':
        eq=Building(name,'mod',wall=ol['wall'],tint=tuple(ol['tint']),roof=ol['roof'],style='modular'); eq.floor=FL; eq.storeys=1; eq.budget=ol['budget'].replace('mod_','')
        eq.add('block',x0=-W/2,x1=W/2,z0=-D/2,z1=D/2,W=HW,roof='gable',axis='x',pitch=ol.get('pitch',0.45),o=0.45,f=0.18,rake=0.3,openings=ops,downspouts=(),foundation=True)
    elif ol['kind']=='shop':
        eq=Building(name,'mod',wall=ol['wall'],tint=tuple(ol['tint']),roof='R_flat',style='modular'); eq.floor=0.0; eq.storeys=1; eq.budget=ol['budget']; eq.frontage=W
        eq.floor_lines=[GF]
        eq.add('block',x0=-W/2,x1=W/2,z0=-D/2,z1=D/2,W=SW,roof='flat',parapet=PAR,cap='T_white',gutters=False,openings=ops,foundation=False)
    else:
        # block / warehouse / tower: flat-roof hull; far facade and tile come from the outline
        fl=float(ol.get('floor',0.3)); st=float(ol.get('storey',3.0)); sty=int(ol.get('storeys',1))
        Ht=fl+sty*st
        eq=Building(name,'mod',wall=ol['wall'],tint=tuple(ol['tint']),roof='R_flat',style='modular')
        eq.floor=fl; eq.storeys=sty; eq.budget=ol['budget']; eq.floor_lines=[fl+st*i for i in range(1,sty+1)]
        if ol['budget']=='shop': eq.frontage=W
        mid=None
        try:
            from city_urban import mid_ops
            mid=mid_ops(ops, fl=fl, st=st)
        except Exception:
            mid=None
        kw=dict(openings=ops,sills=ol.get('sills',False),foundation=ol.get('foundation',True),
                gutters=False,parapet=float(ol.get('parapet',0.9)),cap='T_white',roof='flat')
        if mid is not None: kw['openings_mid']=mid
        if ol.get('far_facade'): kw['far_facade']=ol['far_facade']; kw['far_tile']=ol.get('far_tile',6.0 if ol['kind']=='tower' else 3.0)
        eq.add('block',x0=-W/2,x1=W/2,z0=-D/2,z1=D/2,W=Ht,**kw)
    return eq

def merge_layout(path,out_dir=None):
    L=json.load(open(path)); KIT=_setup(L['group'])
    from geom import write_glb
    from export import export_building, BUDGET
    P=KIT+'/modular/pieces'; name=L['name']; d=out_dir or os.path.dirname(os.path.abspath(path)); os.makedirs(d,exist_ok=True)
    tri={}
    for tier in ('near','mid'):
        m=merge_tier(P,L['group'],L['pieces'],tier); write_glb(f'{d}/mod_{name}_{tier}.glb',m,tier,f'mod_{name}_{tier}'); tri[tier]=len(m['idx'])//3
    ol=L['outline']; eq=outline_building(name,ol,world_openings(P,L['group'],L['pieces']))
    tmp=KIT+'/_tmp_eq'   # same folder depth as buildings/<cat>/<name>/ so texture URIs stay valid after the copy
    try:
        st=export_building(eq,tmp,category_dir='eq')
        for t in ('far','col'): shutil.copy(f'{tmp}/eq/{name}/mod_{name}_{t}.glb',f'{d}/mod_{name}_{t}.glb')
    finally: shutil.rmtree(tmp,ignore_errors=True)
    tri['far']=st['far']['tris']
    bud=list(MOD_BUDGET.get(ol['budget']) or BUDGET[ol['budget']])
    if ol['budget']=='shop': bud=[v*int(round(ol['W']/6.0)) for v in bud]
    if ol['budget']=='tower': nu=max(1.0,float(ol.get('storeys',10))/10.0); bud=[int(round(v*nu)) for v in bud]
    L.update(budget_class=ol['budget'],budget=bud,tris=tri,col_boxes=st['col_boxes'],far_from='snapped outline hull',
             merged={'near_mid':'pieces merged, 1 mesh/1 primitive/1 material','far_col':'outline hull + <=12 boxes'})
    json.dump(L,open(f'{d}/layout.json','w'),indent=1)
    return L

def draw_calls(glb):
    """draw calls a glb costs in Godot (one surface = one draw call per pass): primitives across all mesh nodes"""
    from pygltflib import GLTF2
    g=GLTF2().load(glb); return sum(len(g.meshes[n.mesh].primitives) for n in g.nodes if n.mesh is not None)

if __name__=='__main__':
    for p in sys.argv[1:]:
        L=merge_layout(p); print(L['name'],L['tris'],'budget',L['budget'],flush=True)
