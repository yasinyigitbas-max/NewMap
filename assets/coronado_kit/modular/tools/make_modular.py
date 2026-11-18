"""export every modular piece (pure python): modular/pieces/<group>/<name>/mod_<name>_{near,mid,far,col}.glb + stats.json"""
import sys, os, json
GROUP=sys.argv[1]; os.environ["KIT_ATLAS"]={"houses":"house","shops":"city","urban":"city"}[GROUP]
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import mod_pieces as MP
if GROUP=="urban": import mod_phased as MP
from mod_core import KIT
import export as EX
from export import export_building
import numpy as np
_cb=EX.collision_boxes
def _col(b,sol):
    mode=getattr(b,'col_mode','walls')
    if mode=='walls':
        r=_cb(b,sol)
        if r: return r
    pts=[]
    for (so,rl,m) in sol:
        if mode=='roof' and m.get('type') not in ('roof',): continue
        pts+=[v for (_,pol) in so.faces for v in pol]
    P=np.array(pts); e=0.001
    return [(P[:,0].min()+e,P[:,0].max()-e,max(P[:,1].min(),0.0),P[:,1].max()-e,P[:,2].min()+e,P[:,2].max()-e)]
EX.collision_boxes=_col
OUT=KIT+'/modular/pieces'
def run(only=None):
    res=[]
    for g,b in MP.catalogue(GROUP):
        if only and not any(o in b.name for o in only): continue
        shift,_=b.footprint_center()
        st=export_building(b,OUT,category_dir=g)
        st['open_planes']=[[int(d[0]),round(float(d[1]-shift[d[0]]),4),int(d[2]),(round(float(d[3]),4) if len(d)>3 else None)] for d in b.drop+b.extra_drop]
        st['shift']=[round(float(v),4) for v in shift]
        ops=[o for p_ in b.parts if p_.kind=='block' for o in p_.kw.get('openings',{}).get('front',[])]; st['openings']=ops; st['budget']=list(b.mbudget); st['budget_class']='mod_'+b.cls; st['snap']=b.snap; st['no_door']=b.no_door; st['base_y']=b.base_y; st['ground_reach']=getattr(b,'ground_reach',False)
        json.dump(st,open(f'{OUT}/{g}/{b.name}/stats.json','w'),indent=1)
        print(b.name,st['near']['tris'],st['mid']['tris'],st['far']['tris'],'logic',st['logic_errors'],flush=True); res.append(st)
    return res
if __name__=='__main__': run(sys.argv[2:] or None)
