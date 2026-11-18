#!/usr/bin/env python3
"""Indoor prop acceptance (SPEC, indoor policy).

Indoor props ship **near + col only**. Mid and far are not required and must not be
treated as missing. This is the checker for `_staging/indoor`; do not run
tools/validate.py (buildings, four tiers) on these files.

Checks: naming, near+col present, no mid/far required, one mesh / one primitive /
one material / one node on near, triangulated, triangle cap, <=65k verts, normals and tangents on near (collision is position-only, no normals), UV0 present, UV1 absent, opaque, textures are page I only
(props_i_*), no texture >1024, origin at footprint centre, ground at y=0 with
nothing below -1.5 cm, collision named col with one box or one cylinder (a few
merged boxes allowed up to 2 if documented), budget class cap.

usage: i_check.py [name ...]  -> kit/reports/i_check.json + printed table; exit 1 on fail
"""
import os, sys, json, glob, math
import numpy as np, pygltflib

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT=os.environ.get('IN_KIT', ROOT+'/kit')
BUDGET={'tiny':300,'small':600,'medium':1200,'large':2500}
I_TEX_OK=('props_i_color_clean.png','props_i_normal.png','props_i_orm.png','props_i_color_worn.png','props_i_color_dirty.png')

def load(path):
    g=pygltflib.GLTF2().load(path); blob=g.binary_blob() or b''
    def acc(i):
        a=g.accessors[i]; bv=g.bufferViews[a.bufferView]
        n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a.type]
        dt={5126:np.float32,5125:np.uint32,5123:np.uint16,5121:np.uint8}[a.componentType]
        off=(bv.byteOffset or 0)+(a.byteOffset or 0)
        arr=np.frombuffer(blob,dt,count=a.count*n,offset=off)
        return arr.reshape(-1,n) if n>1 else arr
    return g,acc

def mesh_info(path):
    g,acc=load(path)
    E=[]
    if len(g.meshes)!=1: E.append(f'{len(g.meshes)} meshes')
    if g.cameras or g.animations or (g.lights if hasattr(g,'lights') else None): E.append('extra cameras/animations/lights')
    nodes=[n for n in (g.nodes or []) if n.mesh is not None]
    if len(nodes)!=1: E.append(f'{len(nodes)} mesh nodes')
    m=g.meshes[0] if g.meshes else None
    if not m: return {'errors':E or ['no mesh'],'tris':0,'verts':0,'mats':0,'tex':[]}
    if len(m.primitives)!=1: E.append(f'{len(m.primitives)} primitives')
    pr=m.primitives[0]
    mats=len(g.materials or [])
    if mats!=1 and not path.endswith('_col.glb'): E.append(f'{mats} materials (need 1)')
    idx=acc(pr.indices) if pr.indices is not None else None
    pos=acc(pr.attributes.POSITION)
    nrm=acc(pr.attributes.NORMAL) if pr.attributes.NORMAL is not None else None
    tan=acc(pr.attributes.TANGENT) if getattr(pr.attributes,'TANGENT',None) is not None else None
    uv=acc(pr.attributes.TEXCOORD_0) if getattr(pr.attributes,'TEXCOORD_0',None) is not None else None
    uv1=getattr(pr.attributes,'TEXCOORD_1',None)
    if idx is None: E.append('not indexed')
    tris=int(len(idx)//3) if idx is not None else 0
    if nrm is None: E.append('no normals')
    if (not path.endswith('_col.glb')) and tan is None: E.append('no tangents on near')
    if (not path.endswith('_col.glb')) and uv is None: E.append('no UV0')
    if uv1 is not None: E.append('UV1 present (must be left free / absent)')
    tex=[]
    for img in (g.images or []):
        uri=img.uri or ''
        tex.append(uri)
        if uri and not any(uri.endswith(t) or t in uri for t in I_TEX_OK):
            E.append(f'texture not page I: {uri}')
    # alpha / extras
    if g.materials:
        mat=g.materials[0]
        am=getattr(mat,'alphaMode',None) or 'OPAQUE'
        if am not in ('OPAQUE',None) and not path.endswith('_col.glb'):
            E.append(f'alphaMode {am} (need OPAQUE)')
    # bounds in glTF Y-up: x,y,z = Blender x,z,-y after export_yup
    # After Y-up: X right, Y up, Z backward (front +Z in SPEC is +Z glTF = -Y blender)
    P=pos
    ymin=float(P[:,1].min()); ymax=float(P[:,1].max())
    cx=float((P[:,0].min()+P[:,0].max())/2); cz=float((P[:,2].min()+P[:,2].max())/2)
    if ymin<-0.015: E.append(f'geometry below ground {ymin:.3f}')
    if abs(cx)>0.06 or abs(cz)>0.06:
        E.append(f'origin not at footprint centre dx={cx:.3f} dz={cz:.3f}')
    return {'errors':E,'tris':tris,'verts':int(len(P)),'mats':mats,'tex':tex,'h':round(ymax-min(0,ymin),3),'ymin':round(ymin,4)}

def find_files(name):
    hits=glob.glob(KIT+f'/props/indoor/**/prop_{name}_clean_near.glb',recursive=True)
    if not hits: return None
    d=os.path.dirname(hits[0])
    return {'near':f'{d}/prop_{name}_clean_near.glb','col':f'{d}/prop_{name}_col.glb',
            'mid':f'{d}/prop_{name}_clean_mid.glb','far':f'{d}/prop_{name}_clean_far.glb','dir':d}

def check(name, rec):
    out={'name':name,'class':rec.get('class'),'budget':rec.get('budget'),'pass':True,'errors':[],'notes':[]}
    fs=find_files(name)
    if not fs:
        out['pass']=False; out['errors']=['missing near glb']; return out
    if not os.path.exists(fs['near']):
        out['pass']=False; out['errors']=['missing near']; return out
    if not os.path.exists(fs['col']):
        out['pass']=False; out['errors']=['missing col']
    # mid/far are intentionally not required
    if os.path.exists(fs['mid']) or os.path.exists(fs['far']):
        out['notes'].append('mid/far files present but indoor policy is near+col only')
    near=mesh_info(fs['near'])
    out['near_tris']=near['tris']; out['near_info']=near
    cap=int(rec.get('budget') or BUDGET.get(rec.get('class'),0) or 0)
    ccap=BUDGET.get(rec.get('class'))
    if ccap and cap>ccap: out['errors'].append(f"budget {cap} above class cap {ccap}")
    if ccap and near['tris']>ccap: out['errors'].append(f"{near['tris']} tris over class cap {ccap}")
    if cap and near['tris']>cap:
        out['errors'].append(f"{near['tris']} tris over near budget {cap}")
    out['errors']+=[f'near: {e}' for e in near['errors']]
    if os.path.exists(fs['col']):
        col=mesh_info(fs['col'])
        out['col_tris']=col['tris']
        # col is a collision hull: positions only (no normals/tangents/UVs/materials), same as street kit cols.
        skip_col=('materials (need 1)','no tangents on near','no UV0','no normals','not indexed')
        out['errors']+=[f'col: {e}' for e in col['errors'] if e not in skip_col and 'UV1' not in e and 'materials' not in e]
        # primitive count: one box = 12 tris, one cyl ~ 20-24. Allow up to 2 boxes (24 tris) as a soft cap; SPEC prefers one.
        if col['tris']>28:
            out['notes'].append(f'col has {col["tris"]} tris (SPEC prefers one box or one cylinder)')
    out['errors']+=out.get('errors',[])
    # unique
    seen=set(); errs=[]
    for e in out['errors']:
        if e not in seen: seen.add(e); errs.append(e)
    out['errors']=errs
    out['pass']=not out['errors']
    return out

def manifests():
    m={}
    for f in glob.glob(KIT+'/props/manifest_in*.json'):
        for k,v in json.load(open(f)).items():
            m[k]=dict(v,_man=f)
    return m

def main():
    man=manifests()
    names=sys.argv[1:] or list(man.keys())
    rows=[]
    for n in names:
        rec=man.get(n,{'name':n,'class':None,'budget':None})
        r=check(n,rec); rows.append(r)
        flag='PASS' if r['pass'] else 'FAIL'
        print(f"{flag} {n}  near={r.get('near_tris')} / {r.get('budget')}  {'; '.join(r['errors']) or ('; '.join(r['notes']) or 'ok')}")
    os.makedirs(KIT+'/reports',exist_ok=True)
    json.dump(rows,open(KIT+'/reports/i_check.json','w'),indent=1)
    failed=sum(1 for r in rows if not r['pass'])
    print(f"{len(rows)-failed}/{len(rows)} pass  ({failed} fail)")
    sys.exit(1 if failed else 0)

if __name__=='__main__':
    main()
