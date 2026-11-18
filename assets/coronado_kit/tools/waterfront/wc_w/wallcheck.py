#!/usr/bin/env python3
"""Grazing-light wall blotch check.
For each side of a near-tier model: render (a) full material, (b) flat reference (no texture/normal/vertex colour),
(c) a wall-texel mask, all under the same grazing sun. ratio = full/flat isolates what the surfacing adds;
its low-frequency residual (after removing intended per-row bands: foundation, eave shade, sill streaks)
must not contain large blobs. usage: wallcheck.py <near.glb> <outdir> -> prints JSON, exit 1 on fail"""
import sys, os, subprocess, json, numpy as np, cv2
HERE=os.path.dirname(os.path.abspath(__file__)); BL='/workspace/tools/blender/blender'
def render(near,out,mode,env):
    e=dict(os.environ); e.update(env); e.setdefault('DIAG_RES','0.5'); e.setdefault('DIAG_SAMPLES','16')
    subprocess.run([BL,'-t','2','-b','-P',HERE+'/render_diag.py','--',out,near,mode],env=e,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,check=True)
    return cv2.imread(out).astype(np.float32)/255
def lum(a): return a[...,2]*0.2126+a[...,1]*0.7152+a[...,0]*0.0722
PCT=float(os.environ.get('WC_PCT','75'))
def judge(full,flat,mimg,sd,b=None,pct=None,fine=False,relief=False):
    # relief=True: shingle/brick/stone cladding. Its own holes and courses are intended texture, so blotches are judged at
    # ~1 m scale (sigma 2.5% of width, 7% threshold), not at the texture-feature scale. Tuned on mcm_teal/white stone:
    # clean walls pass, 1 m blotches at -15% fail
    # fine=True: for facades that are mostly openings behind galleries (thin wall strips), small fixed kernels
    pct=PCT if pct is None else pct
    EL,MINPX=(3,1500) if fine else (15,2000)
    mask=mimg[...,2]>0.5                               # BGR: R channel = wall texels
    dep=mimg[...,0] if sd in ('front','back') else mimg[...,1]   # blender y (front/back) or x (left/right), fract(v/16)
    plane=np.round(dep*255/3).astype(np.int32)         # ~0.2 m depth buckets -> separate wall planes
    mask=cv2.erode(mask.astype(np.uint8),np.ones((7,7),np.uint8))>0
    # only directly sun-lit wall: cast shadows are geometry, and grazing normals behave differently in shade
    # lit threshold per wall plane: a bright tower facet catching the grazing sun must not push the main wall planes
    # below the global threshold (that left the main walls unjudged); each plane is judged against its own lit level
    lit=np.zeros_like(mask)
    for pid in np.unique(plane[mask]):
        pm=mask&(plane==pid)
        if pm.sum()<200: continue
        lit|=pm&(flat>0.7*np.percentile(flat[pm],pct))   # p75: a small bright turret facet sharing the plane bucket must not set the level
    lit=cv2.erode(lit.astype(np.uint8),np.ones((EL,EL),np.uint8))>0
    mask&=lit
    if mask.sum()<MINPX: return {'skipped':'no lit wall'}
    r=np.where(mask,full/(flat+1e-3),0)
    sig=full.shape[1]*(0.004 if fine else 0.025 if relief else 0.012)
    num=cv2.GaussianBlur(r,(0,0),sig); den=cv2.GaussianBlur(mask.astype(np.float32),(0,0),sig)
    lp=np.where(mask,num/(den+1e-6),0)
    med=np.median(lp[mask])
    # intended bands (foundation, eave shade, sill streaks) run along rows of each wall plane: remove per plane, per row
    resid=np.zeros_like(lp)
    for pid in np.unique(plane[mask]):
        pm=mask&(plane==pid)
        if pm.sum()<200: mask&=~pm; continue
        rows=np.where(pm.any(1))[0]
        for y in rows:
            v=lp[y][pm[y]]
            if len(v)>10: resid[y][pm[y]]=v/(np.median(v)+1e-6)-1
            else: mask[y]&=~pm[y]
    lp=lp  # (per-plane normalised above)
    ck=1 if fine else int(sig*1.0) if relief else int(sig*2.5)
    core=cv2.erode(mask.astype(np.uint8),np.ones((ck*2+1,)*2,np.uint8))>0   # judge wall interiors: edges carry blur bias and legit contact AO
    bad=(np.abs(resid)>(0.07 if relief else 0.10))&core   # relief: tighter threshold on the coarser low-pass
    n,lab,st,_=cv2.connectedComponentsWithStats(bad.astype(np.uint8))
    big=[int(a) for a in st[1:,4]] if n>1 else []
    worst=max(big) if big else 0
    frac=worst/mask.sum()
    vis=np.dstack([np.clip(0.5+resid*2.5,0,1)]*3); vis[~mask]=(0.2,0.2,0.2); vis[bad]=(0,0,1)
    if b: cv2.imwrite(b+'_resid.png',(vis*255).astype(np.uint8))
    return {'wall_px':int(mask.sum()),'resid_std':round(float(resid[mask].std()),4),'worst_blob_frac':round(float(frac),4),'pass':bool(frac<0.004 and resid[mask].std()<0.025)}

# house atlas relief rows in blender v (1 - atlas_px/2048): shingle 268-396, brick 400-528, half-timber 532-596, stone 600-664
RELIEF='0.806,0.870;0.741,0.806;0.708,0.741;0.675,0.708'
def check(near,outdir,sides=('front','left','right','back')):
    os.makedirs(outdir,exist_ok=True); res={}
    ok=True
    for sd in sides:
        b=f'{outdir}/{sd}'
        # shading render: albedo replaced by flat grey, keeps vertex colour (baked AO/grime) + normal map + tangents;
        # albedo patchiness is checked separately on the atlas (atlas_check)
        full=lum(render(near,b+'_full.png','graze_'+sd,{'DIAG_NOTEX':'1'}))
        flat=lum(render(near,b+'_flat.png','graze_'+sd,{'DIAG_NOTEX':'1','DIAG_NONORMAL':'1','DIAG_NOVC':'1'}))
        mimg=render(near,b+'_mask.png','wall_'+sd,{'DIAG_MASK':'1'})
        res[sd]=judge(full,flat,mimg,sd,b)
        if 'skipped' in res[sd]:
            # no directly lit wall at the first grazing angle (porch/wing shadow): re-judge with the sun from the other end
            full=lum(render(near,b+'_full2.png','graze_'+sd,{'DIAG_NOTEX':'1','DIAG_FLIP':'1'}))
            flat=lum(render(near,b+'_flat2.png','graze_'+sd,{'DIAG_NOTEX':'1','DIAG_NONORMAL':'1','DIAG_NOVC':'1','DIAG_FLIP':'1'}))
            r2=judge(full,flat,mimg,sd,b+'_2')
            if 'skipped' in r2:
                # still unlit: facade is mostly openings behind a gallery (thin wall strips) -> fine kernels on both renders
                f1=lum(cv2.imread(b+'_full.png').astype(np.float32)/255); l1=lum(cv2.imread(b+'_flat.png').astype(np.float32)/255)
                r2=judge(f1,l1,mimg,sd,b+'_fine',fine=True)
                if 'skipped' in r2: r2=judge(full,flat,mimg,sd,b+'_fine2',fine=True)
                if 'skipped' in r2:
                    # relief cladding (shingle / brick / half-timber / stone, and the city atlas brick row which
                    # shares those v-bands) is left out of the smooth-wall mask by design. Judge it anyway with
                    # those rows added to the mask. Used to be gated on '/houses/' in the path, which skipped
                    # every city / urban / staged building.
                    mR=render(near,b+'_maskR.png','wall_'+sd,{'DIAG_MASK':'1','MASK_EXTRA':RELIEF})
                    r2=judge(f1,l1,mR,sd,b+'_relief',relief=True)
                    if 'skipped' in r2: r2=judge(full,flat,mR,sd,b+'_relief2',relief=True)
                    if 'skipped' not in r2: r2['mode']='relief'
                if 'skipped' in r2: res[sd]={'skipped':'no lit wall (2 sun angles + fine + relief)','unjudged':True,'pass':False}; ok=False; continue   # unjudged is not a pass
                r2.setdefault('mode','fine')
            r2.setdefault('sun','flipped'); res[sd]=r2
        ok&=res[sd]['pass']
    res['pass']=bool(ok); return res
def atlas_check(limit=0.03):
    """low-frequency albedo variation of plain wall strips (big dark/light patches baked in source photos)"""
    L=json.load(open(os.path.dirname(HERE)+'/textures/atlas_layout.json'))['regions']
    C=cv2.imread(os.path.dirname(HERE)+'/textures/bld_color.png').astype(np.float32)/255
    out={}
    for k in ('W_stucco','W_siding','W_bb','W_brick'):
        x0,y0,x1,y1=L[k]['px']; a=C[y0:y1,x0:x1].mean(2); h=y1-y0
        lp=cv2.GaussianBlur(np.pad(a,60,mode='wrap'),(0,0),h/5)[60:-60,60:-60]
        out[k]=round(float(lp.std()/lp.mean()),4)
    return {'lowfreq':out,'pass':all(v<limit for v in out.values())}
if __name__=='__main__':
    if sys.argv[1]=='--atlas': r=atlas_check(); print(json.dumps(r)); sys.exit(0 if r['pass'] else 1)
    r=check(sys.argv[1],sys.argv[2]); print(json.dumps(r)); sys.exit(0 if r['pass'] else 1)
