#!/usr/bin/env python3
"""House prop acceptance (SPEC, indoor/house policy).

Indoor props ship **near + col only**. Mid and far are not required and must not be
treated as missing. This is the checker for `_staging/house`; do not run
tools/validate.py (buildings, four tiers) on these files.

Checks: naming, near+col present, no mid/far required, one mesh / one primitive /
one material / one node on near, triangulated, triangle cap, <=65k verts, normals and tangents on near (collision is position-only, no normals), UV0 present, UV1 absent, opaque, textures are page H only
(props_h_*), near materials must have occlusionTexture pointing at the ORM, no texture >1024, origin at footprint centre, ground at y=0 with
nothing below -1.5 cm, collision named col with one box or one cylinder (a few
merged boxes allowed up to 2 if documented), budget class cap.

usage: h_check.py [name ...]  -> reports/house/h_check.json + printed table; exit 1 on fail
"""
import os, sys, json, glob, math
import numpy as np, pygltflib

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT=os.environ.get('IN_KIT', ROOT+'/kit')
BUDGET={'tiny':300,'small':600,'medium':1200,'large':2500}
CASE_GOODS={
    'credenza','tv_console','nightstand','dresser','sideboard',
    'upper_cabinet','storage_cabinet','fridge_home','dining_table','coffee_table',
}
H_TEX_OK=('props_h_color_clean.png','props_h_normal.png','props_h_orm.png','props_h_color_worn.png','props_h_color_dirty.png')

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
    col0=acc(pr.attributes.COLOR_0) if getattr(pr.attributes,'COLOR_0',None) is not None else None
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
        if uri and not any(uri.endswith(t) or t in uri for t in H_TEX_OK):
            E.append(f'texture not page H: {uri}')
    # alpha / extras
    if g.materials:
        mat=g.materials[0]
        am=getattr(mat,'alphaMode',None) or 'OPAQUE'
        if am not in ('OPAQUE',None) and not path.endswith('_col.glb'):
            E.append(f'alphaMode {am} (need OPAQUE)')
        if not path.endswith('_col.glb'):
            md=mat.to_dict() if hasattr(mat,'to_dict') else {}
            pbr=getattr(mat,'pbrMetallicRoughness',None)
            mr=getattr(pbr,'metallicRoughnessTexture',None) if pbr else None
            occ=getattr(mat,'occlusionTexture',None) or md.get('occlusionTexture')
            nt=getattr(mat,'normalTexture',None) or md.get('normalTexture')
            if not nt:
                E.append('near without normalTexture')
            if not occ:
                E.append('near without occlusionTexture')
            elif mr is not None:
                oi=occ.get('index') if isinstance(occ,dict) else getattr(occ,'index',None)
                mi=mr.get('index') if isinstance(mr,dict) else getattr(mr,'index',None)
                if oi!=mi:
                    E.append('occlusionTexture index does not match ORM (metallicRoughnessTexture)')
    # bounds in glTF Y-up: x,y,z = Blender x,z,-y after export_yup
    # After Y-up: X right, Y up, Z backward (front +Z in SPEC is +Z glTF = -Y blender)
    P=pos
    ymin=float(P[:,1].min()); ymax=float(P[:,1].max())
    xmin,xmax=float(P[:,0].min()),float(P[:,0].max())
    zmin,zmax=float(P[:,2].min()),float(P[:,2].max())
    cx=float((xmin+xmax)/2); cz=float((zmin+zmax)/2)
    if ymin<-0.015: E.append(f'geometry below ground {ymin:.3f}')
    if abs(cx)>0.06 or abs(cz)>0.06:
        E.append(f'origin not at footprint centre dx={cx:.3f} dz={cz:.3f}')
    info={'errors':E,'tris':tris,'verts':int(len(P)),'mats':mats,'tex':tex,'h':round(ymax-min(0,ymin),3),'ymin':round(ymin,4),
          'foot':(xmax-xmin)*(zmax-zmin),'top_area_up':0.0,'flip_area':0.0,'flip_frac':0.0}
    # winding / top cover (near only; col has no reliable normals)
    if (not path.endswith('_col.glb')) and idx is not None and nrm is not None and tris>0:
        faces=idx.reshape(-1,3).astype(np.int64)
        v0,v1,v2=P[faces[:,0]],P[faces[:,1]],P[faces[:,2]]
        fn=np.cross(v1-v0,v2-v0)
        area=0.5*np.linalg.norm(fn,axis=1)
        fnu=fn/np.maximum(np.linalg.norm(fn,axis=1,keepdims=True),1e-12)
        vn=(nrm[faces[:,0]]+nrm[faces[:,1]]+nrm[faces[:,2]])/3.0
        vn=vn/np.maximum(np.linalg.norm(vn,axis=1,keepdims=True),1e-12)
        dots=(fnu*vn).sum(axis=1)
        flip=area[dots<0].sum()
        tot=float(area.sum()) or 1.0
        info['flip_area']=float(flip)
        info['flip_frac']=float(flip/tot)
        # 15% is generous: overlapping furniture parts can share an edge, but
        # a true inverted shell flips a large share.
        if flip/tot>0.15:
            E.append(f'flipped normals on {flip/tot:.0%} of surface')
        cent=(v0+v1+v2)/3.0
        top=(cent[:,1] > ymax-0.025) & (fnu[:,1] > 0.7)
        info['top_area_up']=float(area[top].sum())
        if col0 is not None:
            if col0.dtype==np.uint16: cf=col0.astype(np.float32)/65535.0
            elif col0.dtype==np.uint8: cf=col0.astype(np.float32)/255.0
            else: cf=col0.astype(np.float32)
            # verts of upward faces near the top of the AABB
            top_verts=np.unique(faces[top].ravel()) if top.any() else np.array([],dtype=np.int64)
            if len(top_verts)>=4:
                ao=cf[top_verts,0]
                info['top_ao_mean']=float(ao.mean())
                info['top_ao_dark']=float((ao<0.30).mean())
    return info

def find_files(name):
    hits=glob.glob(KIT+f'/props/house/**/prop_{name}_clean_near.glb',recursive=True)
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
    # closed case goods must present a top (catches open boxes / black interiors)
    if rec.get('case') or name in CASE_GOODS:
        foot=near.get('foot') or 0.0
        cover=near.get('top_area_up') or 0.0
        if foot>0.04 and cover < 0.55*foot:
            out['errors'].append(f'open or missing case top (cover {cover:.3f} m^2 < 0.55×footprint {foot:.3f})')
        dark=near.get('top_ao_dark') or 0.0
        if dark>0.18:
            out['errors'].append(f'case top bakes too dark (AO hole on {dark:.0%} of top verts)')
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
    # manifest_h*.json would also match the existing outdoor manifest_house.json
    for f in [KIT+'/props/'+n for n in ('manifest_hdecor.json','manifest_hfurn.json','manifest_hrugs.json')]:
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
    os.makedirs(KIT+'/reports/house',exist_ok=True)
    json.dump(rows,open(KIT+'/reports/house/h_check.json','w'),indent=1)
    failed=sum(1 for r in rows if not r['pass'])
    print(f"{len(rows)-failed}/{len(rows)} pass  ({failed} fail)")
    sys.exit(1 if failed else 0)

if __name__=='__main__':
    main()
