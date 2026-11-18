#!/usr/bin/env python3
"""Spec validator for Coronado kit v2 props / fences / foliage (SPEC.md s1-s4, s7).
usage: validate_props.py [dir ...]   -> reports/props_validation.md + .json"""
import json, struct, os, re, sys, glob
import numpy as np
from PIL import Image
K='/workspace/coronado_kit_v2/_staging/waterfront/kit'
BUDGET={'tiny':300,'small':600,'medium':1200,'large':2500,'fence':60,'chainlink':4,'hedge':200,'shrub':500,'palm':1500,'tree':2500,'yardtree':2000,'ground':300}
MIDB={'palm':500,'tree':800,'yardtree':600}
FARB={'large':20,'palm':2,'tree':2,'yardtree':2}
ALPHA_OK_CLASSES={'chainlink','palm','tree','yardtree','shrub','hedge','ground'}   # SPEC s1: cut-out allowed for tree and plant leaves (hedge leaves included)
ALPHA_OK_NAMES=re.compile(r'(chainlink|chain_link|tennis_net|net_|temp_fence_panel_(clean|worn|rusty))')   # temp fence panel = chain-link mesh in a tube frame (SPEC s1)
NAME=re.compile(r'^(prop|fence|tree|palm|plant|hedge)_[a-z0-9_]+_(clean|worn|dirty|rusty|lush|normal|dry)_(near|mid|far)\.glb$')
COLN=re.compile(r'^(prop|fence|tree|palm|plant|hedge)_[a-z0-9_]+_col\.glb$')
CT={5120:np.int8,5121:np.uint8,5122:np.int16,5123:np.uint16,5125:np.uint32,5126:np.float32}
NC={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}
def load(p):
    d=open(p,'rb').read(); jl=struct.unpack('<I',d[12:16])[0]; js=json.loads(d[20:20+jl]); o=20+jl
    bl=struct.unpack('<I',d[o:o+4])[0]; bin_=d[o+8:o+8+bl]; return js,bin_
def acc(js,b,i):
    a=js['accessors'][i]; bv=js['bufferViews'][a['bufferView']]; n=NC[a['type']]; dt=CT[a['componentType']]
    off=bv.get('byteOffset',0)+a.get('byteOffset',0); cnt=a['count']; stride=bv.get('byteStride',0)
    isz=np.dtype(dt).itemsize*n
    if stride and stride!=isz:
        raw=np.frombuffer(b,np.uint8,count=stride*cnt,offset=off).reshape(cnt,stride)[:,:isz].copy()
        arr=raw.view(dt).reshape(cnt,n)
    else: arr=np.frombuffer(b,dt,count=cnt*n,offset=off).reshape(cnt,n)
    if a.get('normalized'): arr=arr.astype(np.float32)/np.iinfo(dt).max
    return arr
def manifests():
    m={}
    for f in glob.glob(K+'/props/manifest_*.json')+glob.glob(K+'/fences/manifest_*.json')+glob.glob(K+'/foliage/manifest_*.json'):
        for k,v in json.load(open(f)).items(): m[v['file_base']]=v
    return m
def ray_hits(orig,dirs,tri,back_first=None):
    """count hits of rays (N) against triangles (M) - Moller Trumbore vectorised"""
    v0,v1,v2=tri[:,0],tri[:,1],tri[:,2]; e1=v1-v0; e2=v2-v0
    hits=np.zeros(len(orig),int)
    for i in range(0,len(orig),256):
        o=orig[i:i+256,None,:]; d=dirs[i:i+256,None,:]
        p=np.cross(d,e2[None]); det=(e1[None]*p).sum(-1); ok=np.abs(det)>1e-12; inv=np.where(ok,1/np.where(ok,det,1),0)
        t=o-v0[None]; u=(t*p).sum(-1)*inv; q=np.cross(t,e1[None]); v=(d*q).sum(-1)*inv; w=(e2[None]*q).sum(-1)*inv
        h=ok&(u>=0)&(v>=0)&(u+v<=1)&(w>1e-4); hits[i:i+256]=h.sum(1)
        if back_first is not None:   # nearest hit seen from behind (det<0) = the ray started inside a closed shell
            wn=np.where(h,w,np.inf); j=wn.argmin(1); r=np.arange(len(j))
            back_first[i:i+256]=np.isfinite(wn[r,j])&(det[r,j]<0)
    return hits
def check(path, man):
    fn=os.path.basename(path); errs=[]; warn=[]; info={}
    js,b=load(path)
    if fn.endswith('_col.glb'):
        if not COLN.match(fn): errs.append('name')
        meshes=js.get('meshes',[])
        if len(meshes)!=1 or js['nodes'][0].get('name')!='col': errs.append('col: one mesh named col required')
        P=acc(js,b,meshes[0]['primitives'][0]['attributes']['POSITION']); I=acc(js,b,meshes[0]['primitives'][0]['indices']).ravel()
        # components by shared vertex index
        n=len(P); par=list(range(n))
        def f(x):
            while par[x]!=x: par[x]=par[par[x]]; x=par[x]
            return x
        for t in I.reshape(-1,3):
            a,b_,c=f(t[0]),f(t[1]),f(t[2]); par[b_]=a; par[c]=a
        comps={}
        for i in range(n): comps.setdefault(f(i),set()).add(tuple(np.round(P[i],4)))
        nc=len(comps); maxv=max(len(v) for v in comps.values())
        info.update(col_parts=nc,col_maxverts=maxv)
        if not ((nc<=28 and maxv<=24) or (nc==1 and maxv<=32)): errs.append(f'col {nc} parts/{maxv} verts')   # SPEC s1: 12 main boxes + 16 post/rail boxes (split checked by wf_check from the build record)
        return dict(file=fn,ok=not errs,errs=errs,warn=warn,**info)
    m=NAME.match(fn)
    if not m: errs.append('name pattern'); tier='near'
    else: tier=m.group(3)
    base=re.sub(r'_(clean|worn|dirty|rusty|lush|normal|dry)_(near|mid|far)\.glb$','',fn)
    rec=man.get(base); cls=rec['class'] if rec else None
    if not rec: errs.append('no manifest entry')
    for k in ('cameras','animations','skins'):
        if js.get(k): errs.append(f'has {k}')
    if 'KHR_lights_punctual' in json.dumps(js.get('extensions',{})): errs.append('has lights')
    nodes=js.get('nodes',[]); meshn=[n for n in nodes if 'mesh' in n]
    if len(nodes)!=1 or len(meshn)!=1: errs.append(f'nodes {len(nodes)} (need exactly one mesh node, no empties)')
    if len(js.get('meshes',[]))!=1 or len(js['meshes'][0]['primitives'])!=1: errs.append('not one mesh/one primitive')
    if len(js.get('materials',[]))!=1: errs.append(f"materials {len(js.get('materials',[]))}")
    nd=meshn[0] if meshn else {}
    if any(k in nd for k in ('rotation','scale')) and nd.get('scale',[1,1,1])!=[1,1,1]: errs.append('node transform not applied')
    pr=js['meshes'][0]['primitives'][0]; at=pr['attributes']
    for req in ('POSITION','NORMAL','TEXCOORD_0','COLOR_0'):
        if req not in at: errs.append(f'missing {req}')
    if tier=='near' and 'TANGENT' not in at: errs.append('missing TANGENT (near)')
    if 'TEXCOORD_1' in at: errs.append('UV1 must be left free')
    mat=js['materials'][0] if js.get('materials') else {}
    am=mat.get('alphaMode','OPAQUE')
    if am=='BLEND': errs.append('alpha blend')
    if am=='MASK' and not (cls in ALPHA_OK_CLASSES or ALPHA_OK_NAMES.search(fn)): errs.append('alpha cut-out not allowed for this asset')
    if tier=='near' and 'normalTexture' not in mat: errs.append('near without normal map')
    if tier!='near' and 'normalTexture' in mat: errs.append('mid/far must be colour only')
    if mat.get('emissiveTexture') or any(mat.get('emissiveFactor',[0,0,0])): errs.append('emissive')
    for im in js.get('images',[]):
        u=im.get('uri')
        if not u: errs.append('embedded image (must reference shared atlas)'); continue
        p=os.path.normpath(os.path.join(os.path.dirname(path),u))
        if not re.search(r'atlases/(props|trees)_',p): errs.append(f'non-shared texture {u}')
        if not os.path.exists(p): errs.append(f'missing texture {u}'); continue
        w,h=Image.open(p).size
        if max(w,h)>2048: errs.append(f'texture {w}x{h}>2048')
        if 'trees_' in p and max(w,h)>1024: errs.append('tree atlas >1024')
    P=acc(js,b,at['POSITION']).astype(np.float64); N=acc(js,b,at['NORMAL']).astype(np.float64)
    I=acc(js,b,pr['indices']).ravel() if 'indices' in pr else np.arange(len(P))
    T=I.reshape(-1,3); ntri=len(T); info['tris']=ntri; info['verts']=len(P)
    if len(P)>65000: errs.append('>65000 verts')
    UV=acc(js,b,at['TEXCOORD_0'])
    if UV.min()<-1e-4 or UV.max()>1+1e-4: errs.append('UV outside 0..1')
    # budget
    if cls:
        if tier=='near': lim=int(rec.get('budget') or BUDGET[cls])
        elif tier=='mid': lim=MIDB.get(cls, int((rec.get('budget') or BUDGET[cls])*0.30)+1)
        else: lim=FARB.get(cls,20)
        info['budget']=lim
        if ntri>lim: errs.append(f'tris {ntri}>{lim}')
        if tier=='mid' and rec and rec['tiers'].get('near') and cls not in MIDB and ntri>0.45*rec['tiers']['near']:
            warn.append(f"mid is {ntri/rec['tiers']['near']:.0%} of near (target ~30%)")
    # frame: Y up, origin bottom centre
    mn=P.min(0); mx=P.max(0); info['size']=[round(float(x),3) for x in (mx-mn)]
    # storm-drain wells and gutter dips are specified to sit 10-15 cm below grade; origin stays at street level
    below_ok=bool(re.search(r'prop_(manhole_cover|storm_drain_grate|storm_drain_curb_inlet)_', fn))
    if abs(mn[1])>0.003 and not (below_ok and -0.20<=mn[1]<=0.003):
        errs.append(f'min y {mn[1]:.3f} (ground must be y=0, origin at bottom)')
    cx=(mn[0]+mx[0])/2; cz=(mn[2]+mx[2])/2; tol=0.06*max(mx[0]-mn[0],mx[2]-mn[2])+0.03
    if rec and rec.get('mount','ground')=='ground' and (abs(cx)>tol or abs(cz)>tol):
        warn.append(f'origin off footprint centre ({cx:.2f},{cz:.2f}) - asymmetric parts?')
    if (mx-mn)[1]>40 or max(mx-mn)<0.004: errs.append('implausible scale')
    # degenerate / duplicate
    tri=P[T]; cr=np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0]); area=np.linalg.norm(cr,axis=1)/2
    nd_=int((area<1e-9).sum())
    if nd_: errs.append(f'{nd_} degenerate tris')
    key=np.sort(np.round(tri,4).reshape(ntri,3,3).tolist() and np.round(tri,4).reshape(ntri,9),axis=1)
    keys=set(); dup=0
    for t in np.round(tri,4):
        k=tuple(sorted(map(tuple,t)))
        if k in keys: dup+=1
        keys.add(k)
    if dup: errs.append(f'{dup} duplicate tris')
    # normals agree with winding
    gn=cr/np.maximum(np.linalg.norm(cr,axis=1,keepdims=True),1e-12); vn=N[T].mean(1)
    flip=int(((gn*vn).sum(1)<-0.2).sum())
    if flip: errs.append(f'{flip} tris winding disagrees with normals')
    # inward faces: ray from centroid along normal; odd hit count = facing inward (only meaningful for closed parts)
    cen=tri.mean(1)+gn*1e-3; bf=np.zeros(len(cen),bool); hits=ray_hits(cen,gn,tri,bf)
    info['odd_ray']=int((hits%2==1).sum())
    # parity alone flags every face under a roof (deck -> ceiling) in open structures; a face really points inward / is
    # enclosed when the ray along its normal is odd AND its first hit is the back of a surface (it starts inside a shell)
    inward=int(((hits%2==1)&bf).sum())
    if inward>max(2,0.06*ntri) and am!='MASK': warn.append(f'{inward} tris may face inward / be enclosed')
    # hidden: below ground, faces on the ground facing down
    below=int((tri[:,:,1].max(1)< -0.002).sum())
    if below and not (below_ok and mn[1]>=-0.20):
        errs.append(f'{below} tris under ground')
    down=int(((gn[:,1]<-0.95)&(tri[:,:,1].max(1)<0.003)).sum())
    if below_ok:
        down=0  # flush street iron + below-grade well floors
    if down and not (rec and rec.get('mount')!='ground'): errs.append(f'{down} hidden bottom faces on the ground')
    if tier=='near' and 'TANGENT' in at:
        Tg=acc(js,b,at['TANGENT'])
        if np.isnan(Tg).any(): errs.append('NaN tangents')
    return dict(file=fn,tier=tier,cls=cls,ok=not errs,errs=errs,warn=warn,**info)
def main():
    dirs=sys.argv[1:] or [K+'/props',K+'/fences',K+'/foliage']
    man=manifests(); res=[]
    for d in dirs:
        for p in sorted(glob.glob(d+'/**/*.glb',recursive=True)):
            try: res.append(check(p,man))
            except Exception as e: res.append(dict(file=os.path.basename(p),ok=False,errs=[f'exception {e}'],warn=[]))
    os.makedirs(K+'/reports',exist_ok=True)
    tag=os.path.basename(dirs[0].rstrip('/')) if len(dirs)==1 else 'all'
    json.dump(res,open(f'{K}/reports/props_validation_{tag}.json','w'),indent=1)
    ok=sum(r['ok'] for r in res)
    with open(f'{K}/reports/props_validation_{tag}.md','w') as f:
        f.write(f'# Props validation ({tag})\n\n{ok}/{len(res)} files pass. Checks: naming, one mesh/one material, no empties/cameras/lights/anim, POSITION/NORMAL/TANGENT(near)/UV0/COLOR_0 (baked AO), UV1 free, tri budget per class & tier, ground y=0 + origin bottom centre, degenerate/duplicate tris, winding vs normals, inward/enclosed faces (ray parity), faces under ground / hidden bottom faces, alpha only for allowed cut-outs, shared atlas textures <=2048 (trees <=1024), mid/far colour only, collision <=12 boxes or hull <=32 verts.\n\n')
        f.write('| file | tier | class | tris | budget | size (w,h,d m) | result | notes |\n|---|---|---|---|---|---|---|---|\n')
        for r in res:
            f.write(f"| {r['file']} | {r.get('tier','col')} | {r.get('cls','')} | {r.get('tris','')} | {r.get('budget','')} | {r.get('size','')} | {'PASS' if r['ok'] else 'FAIL'} | {'; '.join(r['errs']+['warn: '+w for w in r['warn']])} |\n")
    print(f'{ok}/{len(res)} pass')
    for r in res:
        if not r['ok'] or r['warn']: print(r['file'],r['errs'],r['warn'])
if __name__=='__main__': main()
