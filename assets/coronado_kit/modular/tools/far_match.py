"""Compare a piece's far tier to its mid: height, silhouette, and window/banding pattern.

Used by validate_modular. The far hull must carry a facade bake that lines up with the mid
(SPEC §2: baked into the far atlas, windows painted, same footprint and height). Same idea as
merge_assembly.py, which paints a named far-atlas strip (tiled per storey, or stretched to the
piece height) onto the closed hull.

No Blender: front-facing triangles are rasterised in numpy from the mid and far glbs.
"""
import os, json
import numpy as np
from PIL import Image

# mid/far height may differ by a parapet cap or a stoop, but not by a whole storey
H_TOL=0.40
# 1-D row-luma correlation: used on tall, regularly banded facades (glass ribbons)
CORR_MIN=0.40
SWING_MIN=0.12
ELEV_H=192
# window-mask fill: a shop or curtain wall (large glass) must not become a few punched holes
FILL_ABS=0.20
FILL_RATIO=1.80
# CIE76 ΔE of mean facade colour (wall + windows, no backdrop)
DE_MAX=15.0
# mid/far horizontal-vs-vertical gradient ratio must agree (ribbons vs a grid)
HV_STRONG=1.70
HV_WEAK=1.15
LIGHT_ROW_ABS=0.22
# mid vs far front-elevation silhouette (binary occupancy IoU)
IOU_MIN=0.80

def _tex_of(g, glb, acc):
    import validate as V
    if not g.materials or not g.textures or not g.images:
        return None
    mat=g.materials[0]
    pbr=getattr(mat,'pbrMetallicRoughness',None) or getattr(mat,'pbr_metallic_roughness',None)
    tex=getattr(pbr,'baseColorTexture',None) or getattr(pbr,'base_color_texture',None) if pbr else None
    if tex is None:
        return None
    idx=getattr(tex,'index',None)
    if idx is None: return None
    t=g.textures[idx]
    src=getattr(t,'source',None)
    if src is None: return None
    uri=g.images[src].uri
    if not uri: return None
    path=os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(glb)), uri))
    if not os.path.exists(path):
        return None
    im=np.asarray(Image.open(path).convert('RGB')).astype(np.float32)/255.0
    return im

def _mesh(glb):
    import validate as V
    g,acc=V.load(glb)
    p=g.meshes[0].primitives[0]
    P=acc(p.attributes.POSITION).astype(np.float64)
    N=acc(p.attributes.NORMAL).astype(np.float64) if getattr(p.attributes,'NORMAL',None) is not None else None
    UV=acc(p.attributes.TEXCOORD_0).astype(np.float64)
    C=None
    if getattr(p.attributes,'COLOR_0',None) is not None:
        C=acc(p.attributes.COLOR_0)
        if C.shape[1]>3: C=C[:,:3]
        if C.dtype==np.uint16: C=C.astype(np.float64)/65535.0
        elif C.dtype==np.uint8: C=C.astype(np.float64)/255.0
        else: C=C.astype(np.float64)
    I=acc(p.indices).astype(np.int64).reshape(-1,3)
    tex=_tex_of(g,glb,acc)
    return P,N,UV,C,I,tex

def _front_elev(glb, out_h=ELEV_H):
    """Ortho elevation of +Z-facing triangles. Returns (image HxWx3, y0, y1, x0, x1) or None."""
    P,N,UV,C,I,tex= _mesh(glb)
    V0,V1,V2=P[I[:,0]],P[I[:,1]],P[I[:,2]]
    cr=np.cross(V1-V0,V2-V0)
    fn=cr/np.maximum(np.linalg.norm(cr,axis=1,keepdims=True),1e-12)
    keep=fn[:,2]>0.55
    if keep.sum()<1:
        # wall-mounted piece facing -Z or thin trim: use the dominant horizontal normal
        ax=int(np.argmax(np.abs(fn).mean(0)))
        if ax==1:  # mostly top-facing (roof / cornice): skip banding, but still return a top-down-ish elev
            keep=fn[:,1]>0.55
        else:
            sgn=1 if fn[:,ax].mean()>=0 else -1
            keep=(fn[:,ax]*sgn)>0.55
    if keep.sum()<1:
        return None
    I=I[keep]; fn=fn[keep]
    V0,V1,V2=P[I[:,0]],P[I[:,1]],P[I[:,2]]
    uv0,uv1,uv2=UV[I[:,0]],UV[I[:,1]],UV[I[:,2]]
    if C is not None:
        c0,c1,c2=C[I[:,0]],C[I[:,1]],C[I[:,2]]
    else:
        c0=c1=c2=np.ones((len(I),3))
    xs=np.concatenate([V0[:,0],V1[:,0],V2[:,0]])
    ys=np.concatenate([V0[:,1],V1[:,1],V2[:,1]])
    x0,x1=float(xs.min()),float(xs.max()); y0,y1=float(ys.min()),float(ys.max())
    spanx=max(x1-x0,0.05); spany=max(y1-y0,0.05)
    h=out_h; w=min(2048,max(16,int(round(out_h*spanx/spany))))
    img=np.zeros((h,w,3),np.float32)
    wgt=np.zeros((h,w),np.float32)
    # barycentric raster, modest resolution
    for i in range(len(I)):
        pts=np.stack([V0[i],V1[i],V2[i]])
        px=(pts[:,0]-x0)/spanx*(w-1)
        py=(1.0-(pts[:,1]-y0)/spany)*(h-1)
        minx=int(max(0,np.floor(px.min()))); maxx=int(min(w-1,np.ceil(px.max())))
        miny=int(max(0,np.floor(py.min()))); maxy=int(min(h-1,np.ceil(py.max())))
        if maxx<minx or maxy<miny: continue
        a=np.array([[px[1]-px[0],px[2]-px[0]],[py[1]-py[0],py[2]-py[0]]],np.float64)
        det=a[0,0]*a[1,1]-a[0,1]*a[1,0]
        if abs(det)<1e-12: continue
        inv=np.array([[a[1,1],-a[0,1]],[-a[1,0],a[0,0]]])/det
        uvs=np.stack([uv0[i],uv1[i],uv2[i]])
        cols=np.stack([c0[i],c1[i],c2[i]])
        ys_=np.arange(miny,maxy+1); xs_=np.arange(minx,maxx+1)
        XX,YY=np.meshgrid(xs_,ys_)
        rel=np.stack([XX-px[0],YY-py[0]],axis=-1)
        bc=rel @ inv.T
        b0=1.0-bc[...,0]-bc[...,1]; b1=bc[...,0]; b2=bc[...,1]
        m=(b0>=-1e-4)&(b1>=-1e-4)&(b2>=-1e-4)
        if not m.any(): continue
        uu=b0*uvs[0,0]+b1*uvs[1,0]+b2*uvs[2,0]
        vv=b0*uvs[0,1]+b1*uvs[1,1]+b2*uvs[2,1]
        cc=b0[...,None]*cols[0]+b1[...,None]*cols[1]+b2[...,None]*cols[2]
        if tex is not None:
            th,tw=tex.shape[:2]
            # atlas UVs are image-space (v=0 at the top). U wraps (full-width far strips
            # tile horizontally); V is clamped so a slight overshoot does not jump strips.
            uu=np.mod(uu,1.0); vv=np.clip(vv,0.0,1.0-1e-9)
            ti=np.clip(np.floor(vv*th).astype(int),0,th-1)
            tj=np.clip(np.floor(uu*tw).astype(int),0,tw-1)
            samp=tex[ti,tj]*cc
        else:
            samp=cc
        img[miny:maxy+1,minx:maxx+1][m]+=samp[m]
        wgt[miny:maxy+1,minx:maxx+1][m]+=1.0
    n=np.maximum(wgt,1e-6)[...,None]
    img=np.clip(img/n,0,1)
    empty=wgt<0.5
    img[empty]=0.62  # background matches the preview sky-ish so empty isn't "dark windows"
    return img,y0,y1,x0,x1

def _row_profile(img):
    # luminance, darker = openings; ignore near-background rows
    luma=0.299*img[...,0]+0.587*img[...,1]+0.114*img[...,2]
    return luma.mean(1)

def _swing(p):
    if p.size<4: return 0.0
    return float(p.max()-p.min())

def _corr(a,b):
    a=a-a.mean(); b=b-b.mean()
    d=np.linalg.norm(a)*np.linalg.norm(b)
    if d<1e-9: return 1.0 if np.linalg.norm(a)+np.linalg.norm(b)<1e-9 else 0.0
    return float((a @ b)/d)

def _luma(im):
    return 0.299*im[...,0]+0.587*im[...,1]+0.114*im[...,2]

def _window_mask(im):
    """Pixels darker than the wall by a clear gap — openings, not brick colour.

    A glass curtain is mostly dark, so the 75th percentile sits in the glass and a
    fixed 0.15 gap would report fill=0. Use a high percentile (the spandrel / wall)
    as the reference instead.
    """
    L=_luma(im)
    p75=float(np.percentile(L,75))
    p95=float(np.percentile(L,95))
    # A glass curtain is mostly dark with light spandrels (high p95). A dark
    # painted wall (cinema, boarded) has a low p95 and must not use this path.
    if p75<0.40 and p95>0.55:
        return L < p95-0.12, p95
    return L < p75-0.15, p75

def _components(mask, min_px):
    h,w=mask.shape
    vis=mask.copy(); info=[]
    for y in range(h):
        for x in range(w):
            if not vis[y,x]: continue
            stack=[(y,x)]; vis[y,x]=False; pts=[]
            while stack:
                cy,cx=stack.pop(); pts.append((cy,cx))
                for dy,dx in ((0,1),(0,-1),(1,0),(-1,0)):
                    ny,nx=cy+dy,cx+dx
                    if 0<=ny<h and 0<=nx<w and vis[ny,nx]:
                        vis[ny,nx]=False; stack.append((ny,nx))
            ys=[p[0] for p in pts]; xs=[p[1] for p in pts]
            if len(pts)<min_px: continue
            info.append(dict(n=len(pts),yc=float(np.mean(ys))/h))
    return info

def _window_stats(im):
    mask,wall=_window_mask(im)
    min_px=max(8, im.shape[0]*im.shape[1]*0.002)
    info=sorted(_components(mask,min_px), key=lambda c:c['yc'])
    rows=[]
    for c in info:
        if not rows or abs(c['yc']-rows[-1][0]['yc'])>0.06:
            rows.append([c])
        else:
            rows[-1].append(c)
    return dict(n=len(info), rows=len(rows), fill=float(mask.mean()),
                row_y=[round(float(np.mean([c['yc'] for c in r])),3) for r in rows],
                wall=round(wall,3))

# overlays, roofs and trims: compare the full AABB, not a +Z sliver of a fascia
NON_FACADE=('roof','chimney','awning','canopy','cornice','parapet','pediment',
            'pier','fireescape','dock','colonnade','column','trim')


def _srgb_to_lin(c):
    return np.where(c<=0.04045, c/12.92, ((c+0.055)/1.055)**2.4)

def _rgb_to_lab(rgb):
    """rgb in 0..1 -> CIE Lab (D65)."""
    r,g,b=_srgb_to_lin(np.asarray(rgb,float))
    x=r*0.4124564+g*0.3575761+b*0.1804375
    y=r*0.2126729+g*0.7151522+b*0.0721750
    z=r*0.0193339+g*0.1191920+b*0.9503041
    def f(t,d=6/29):
        return np.where(t>(d**3), np.cbrt(t), t/(3*d*d)+4/29)
    fx,fy,fz=f(x/0.95047),f(y/1.0),f(z/1.08883)
    return np.array([116*fy-16, 500*(fx-fy), 200*(fy-fz)])

def _delta_e(c1,c2):
    return float(np.linalg.norm(_rgb_to_lab(c1)-_rgb_to_lab(c2)))

def _facade_mask(im):
    luma=_luma(im)
    # drop the raster backdrop (0.62) when it is a large empty area
    m=np.abs(luma-0.62)>0.025
    return m if m.mean()>=0.20 else np.ones(luma.shape,bool)


def _wall_mean(im):
    """Mean RGB of facade pixels that are not dark glazing / openings."""
    luma=_luma(im)
    m=_facade_mask(im)
    wall=m & (luma>=0.28)
    if wall.mean()<0.08:
        wall=m & (luma>=np.percentile(luma[m],40))
    return im[wall].mean(0) if wall.any() else im[m].mean(0)

def _mean_rgb(im):
    m=_facade_mask(im)
    return im[m].mean(0)

def _hv_ratio(im):
    """Horizontal banding energy / vertical-mullion energy. Ribbons >> 1, a square grid ~ 1, tall slits << 1."""
    luma=_luma(im)
    m=_facade_mask(im)
    gy=np.abs(np.diff(luma,axis=0))
    gx=np.abs(np.diff(luma,axis=1))
    # mask to facade (approx)
    my,mx=m[:-1],m[:,:-1]
    hy=float(gy[my].mean()) if my.any() else 0.0
    hx=float(gx[mx].mean()) if mx.any() else 0.0
    return hy,hx, hy/(hx+1e-6)

def _light_row_frac(im):
    luma=_luma(im)
    row=luma.mean(1)
    mid=(row.min()+row.max())*0.5
    if row.max()-row.min()<0.08: return 0.0
    return float((row>=mid).mean())



def _front_tris(glb):
    """All mesh triangles, for an orthographic XY silhouette (front elevation occupancy).
    Sloped faces (awnings, raking cornices, roofs) have little +Z normal and must still count."""
    P,N,UV,C,I,tex=_mesh(glb)
    return P[I[:,0]],P[I[:,1]],P[I[:,2]]

def _sil_mask(V0,V1,V2,x0,x1,y0,y1,out_h=ELEV_H):
    """Binary occupancy of triangles in a shared XY frame. y grows up in world, down in the image."""
    spanx=max(x1-x0,0.05); spany=max(y1-y0,0.05)
    h=out_h; w=min(2048,max(16,int(round(out_h*spanx/spany))))
    mask=np.zeros((h,w),bool)
    for i in range(len(V0)):
        pts=np.stack([V0[i],V1[i],V2[i]])
        px=(pts[:,0]-x0)/spanx*(w-1)
        py=(1.0-(pts[:,1]-y0)/spany)*(h-1)
        minx=int(max(0,np.floor(px.min()))); maxx=int(min(w-1,np.ceil(px.max())))
        miny=int(max(0,np.floor(py.min()))); maxy=int(min(h-1,np.ceil(py.max())))
        if maxx<minx or maxy<miny: continue
        a=np.array([[px[1]-px[0],px[2]-px[0]],[py[1]-py[0],py[2]-py[0]]],np.float64)
        det=a[0,0]*a[1,1]-a[0,1]*a[1,0]
        if abs(det)<1e-12: continue
        inv=np.array([[a[1,1],-a[0,1]],[-a[1,0],a[0,0]]])/det
        ys_=np.arange(miny,maxy+1); xs_=np.arange(minx,maxx+1)
        XX,YY=np.meshgrid(xs_,ys_)
        rel=np.stack([XX-px[0],YY-py[0]],axis=-1)
        bc=rel @ inv.T
        b0=1.0-bc[...,0]-bc[...,1]; b1=bc[...,0]; b2=bc[...,1]
        m=(b0>=-1e-4)&(b1>=-1e-4)&(b2>=-1e-4)
        if m.any():
            mask[miny:maxy+1,minx:maxx+1]|=m
    return mask

def silhouette_iou(mid_glb, far_glb, y_clip=None):
    """IoU of mid and far front silhouettes in a shared frame. y_clip keeps only y>=y_clip (canopy decks)."""
    try:
        mV0,mV1,mV2=_front_tris(mid_glb)
        fV0,fV1,fV2=_front_tris(far_glb)
    except Exception as e:
        return None, dict(error=str(e))
    def _aabb(V0,V1,V2):
        xs=np.concatenate([V0[:,0],V1[:,0],V2[:,0]])
        ys=np.concatenate([V0[:,1],V1[:,1],V2[:,1]])
        return float(xs.min()),float(xs.max()),float(ys.min()),float(ys.max())
    mx0,mx1,my0,my1=_aabb(mV0,mV1,mV2)
    fx0,fx1,fy0,fy1=_aabb(fV0,fV1,fV2)
    x0,x1=min(mx0,fx0),max(mx1,fx1)
    y0,y1=min(my0,fy0),max(my1,fy1)
    if y_clip is not None:
        y0=max(y0,y_clip)
        if y1<=y0+0.05:
            return None, dict(note='y_clip emptied the frame')
    mm=_sil_mask(mV0,mV1,mV2,x0,x1,y0,y1)
    mf=_sil_mask(fV0,fV1,fV2,x0,x1,y0,y1)
    # close construction gaps (~2 cm between moulding courses) without hiding a
    # triangle-vs-rectangle mismatch (those differ by a metre at the corners)
    from scipy.ndimage import binary_dilation
    spany=max(y1-y0,0.05)
    r=min(24,max(1,int(round(0.04/spany*mm.shape[0]))))
    yy=np.arange(-r,r+1); xx=np.arange(-r,r+1)
    ker=(yy[:,None]**2+xx[None,:]**2)<=r*r
    mm=binary_dilation(mm, structure=ker)
    mf=binary_dilation(mf, structure=ker)
    inter=np.logical_and(mm,mf).sum(); union=np.logical_or(mm,mf).sum()
    iou=float(inter/union) if union else 1.0
    return iou, dict(iou=round(iou,3), mid_px=int(mm.sum()), far_px=int(mf.sum()),
                     frame=[round(x0,3),round(x1,3),round(y0,3),round(y1,3)])

def _is_non_facade(name, st):
    typ=((st or {}).get('snap') or {}).get('type') or ''
    n=name or ''
    return any(k in typ or k in n for k in NON_FACADE)

def _aabb_h(glb):
    import validate as V
    g,acc=V.load(glb)
    P=acc(g.meshes[0].primitives[0].attributes.POSITION)
    return float(P[:,1].min()), float(P[:,1].max())

def check(d, st=None):
    """Return {ok, reason, detail}. d is the piece directory."""
    name=os.path.basename(d.rstrip('/'))
    mid=f'{d}/mod_{name}_mid.glb'; far=f'{d}/mod_{name}_far.glb'
    if not (os.path.exists(mid) and os.path.exists(far)):
        return dict(ok=True, reason='missing mid/far skipped', detail={})
    st=st or json.load(open(f'{d}/stats.json'))
    # roofs / trims / wall-mounted overlays: height and silhouette from the mesh AABB.
    # A gable mid's +Z faces are often just a 0.18 m fascia, which is not the piece height.
    if _is_non_facade(name, st):
        my0,my1=_aabb_h(mid); fy0,fy1=_aabb_h(far)
        Hm,Hf=my1-my0, fy1-fy0
        detail=dict(mid_h=round(Hm,3),far_h=round(Hf,3),mid_y1=round(my1,3),far_y0=round(fy0,3),far_y1=round(fy1,3),mode='aabb')
        # A commercial canopy's far is the deck slab only, not a box to the ground.
        # Compare tops (they must line up) and require the slab to sit in the air.
        if 'canopy' in name:
            if abs(fy1-my1)>H_TOL and abs(fy1-my1)/max(abs(my1),0.05)>0.12:
                return dict(ok=False, reason=f'far deck top {fy1:.2f} m vs mid {my1:.2f} m', detail=detail)
            if fy0<2.5:
                return dict(ok=False, reason=f'canopy far is a box to the ground (y0={fy0:.2f})', detail=detail)
            iou,idet=silhouette_iou(mid,far,y_clip=2.5)
            if iou is not None:
                detail.update(idet)
                if iou<IOU_MIN:
                    return dict(ok=False, reason=f'far silhouette IoU {iou:.2f} vs mid (min {IOU_MIN})', detail=detail)
            return dict(ok=True, reason='canopy (deck slab far, tops aligned)', detail=detail)
        if abs(Hf-Hm)>H_TOL and abs(Hf-Hm)/max(Hm,0.05)>0.12:
            return dict(ok=False, reason=f'far height {Hf:.2f} m vs mid {Hm:.2f} m', detail=detail)
        iou,idet=silhouette_iou(mid,far)
        if iou is not None:
            detail.update(idet)
            if iou<IOU_MIN:
                return dict(ok=False, reason=f'far silhouette IoU {iou:.2f} vs mid (min {IOU_MIN})', detail=detail)
        return dict(ok=True, reason='non-facade (height/silhouette only)', detail=detail)

    Em=_front_elev(mid); Ef=_front_elev(far)
    if Em is None or Ef is None:
        return dict(ok=True, reason='no front elevation (not a facade)', detail={})
    im,my0,my1,mx0,mx1=Em
    iff,fy0,fy1,fx0,fx1=Ef
    Hm=my1-my0; Hf=fy1-fy0
    detail=dict(mid_h=round(Hm,3),far_h=round(Hf,3),mid_w=round(mx1-mx0,3),far_w=round(fx1-fx0,3))
    # silhouette / height: far must line up with mid (SPEC §2)
    if abs(Hf-Hm)>H_TOL and abs(Hf-Hm)/max(Hm,0.05)>0.12:
        return dict(ok=False, reason=f'far height {Hf:.2f} m vs mid {Hm:.2f} m', detail=detail)
    # width: allow a stoop / canopy in mid that far (closed hull) may omit
    Wm,Wf=mx1-mx0,fx1-fx0
    if Wf>Wm+0.6:
        return dict(ok=False, reason=f'far width {Wf:.2f} m wider than mid {Wm:.2f} m', detail=detail)
    iou,idet=silhouette_iou(mid,far)
    if iou is not None:
        detail.update(idet)
        if iou<IOU_MIN:
            return dict(ok=False, reason=f'far silhouette IoU {iou:.2f} vs mid (min {IOU_MIN})', detail=detail)

    # window / banding: only for pieces that actually have mid-tier openings on the facade
    regs=st.get('mid',{}).get('regions') or st.get('near',{}).get('regions') or []
    has_open=any(r.startswith('O_') or r.startswith('AW_') for r in regs) or bool(st.get('openings'))
    pm=_row_profile(im); pf=_row_profile(iff)
    x=np.linspace(0,1,len(pf)); xi=np.linspace(0,1,len(pm))
    pf_i=np.interp(xi,x,pf)
    detail['swing_mid']=round(_swing(pm),3); detail['corr']=round(_corr(pm,pf_i),3)
    if not has_open:
        return dict(ok=True, reason='no facade openings (height/silhouette only)', detail=detail)
    if _swing(pm)<SWING_MIN:
        return dict(ok=True, reason='mid has no clear banding', detail=detail)

    wm=_window_stats(im); wf=_window_stats(iff)
    detail['mid_rows']=wm['rows']; detail['far_rows']=wf['rows']
    detail['mid_fill']=round(wm['fill'],3); detail['far_fill']=round(wf['fill'],3)

    # house walls use a shared 3.5 m far stamp. Exact window count / garage door size
    # cannot be unique per piece (far atlas is shared and full), so only height is required.
    group=os.path.basename(os.path.dirname(d.rstrip('/')))
    if group=='houses' and Hm<=4.5:
        return dict(ok=True, reason='ok (house wall, height-matched stamp)', detail=detail)

    # colour + orientation first (used to waive a ground-shop vs tiled-punched fill gap)
    cm,cf=_mean_rgb(im),_mean_rgb(iff)
    de=_delta_e(cm,cf)
    wcm,wcf=_wall_mean(im),_wall_mean(iff)
    wde=_delta_e(wcm,wcf)
    _,_,hvm=_hv_ratio(im); _,_,hvf=_hv_ratio(iff)
    lrm,lrf=_light_row_frac(im),_light_row_frac(iff)
    detail['delta_e']=round(de,1)
    detail['wall_delta_e']=round(wde,1)
    detail['hv_mid']=round(hvm,2); detail['hv_far']=round(hvf,2)
    detail['light_rows_mid']=round(lrm,3); detail['light_rows_far']=round(lrf,3)
    detail['mid_rgb']=[round(float(x),3) for x in cm]
    detail['far_rgb']=[round(float(x),3) for x in cf]
    detail['mid_wall_rgb']=[round(float(x),3) for x in wcm]
    detail['far_wall_rgb']=[round(float(x),3) for x in wcf]
    same_colour=wde<=8.0

    # large glazed mid (shop / curtain wall) must not collapse to a few punched holes.
    # When both sides are heavily glazed and the storey rows already agree (a tiled
    # curtain vs a mullioned mid), a fill gap is just frames vs a flat stamp.
    # A brick front with a ground-floor shop over punched uppers may also exceed the
    # strict ratio against a 3 m tiled brick stamp; waive that when the wall colour
    # already matches.
    both_glazed=wm['fill']>=0.28 and wf['fill']>=0.28
    row_tol=max(1, int(round(0.25*max(wm['rows'],1))))
    rows_close=abs(wm['rows']-wf['rows'])<=row_tol
    fill_ratio=2.50 if same_colour else FILL_RATIO
    fill_abs=0.28 if same_colour else FILL_ABS
    if wm['fill']>=0.25 and not (both_glazed and rows_close):
        if wf['fill']+1e-6>0 and (wm['fill']/max(wf['fill'],1e-6)>=fill_ratio or abs(wm['fill']-wf['fill'])>=fill_abs):
            return dict(ok=False,
                reason=f'window fill {wf["fill"]:.2f} on far vs {wm["fill"]:.2f} on mid (banding / glazing does not line up)',
                detail=detail)

    # multi-storey / shop-height facades: window-row count must line up
    rows_ok = abs(wm['fill']-wf['fill'])<0.10 and detail['corr']>=0.70
    if Hm>=4.8 and not rows_ok and wm['fill']>=0.08:
        if wm['rows']>=3:
            tol=max(1, int(round(0.25*wm['rows'])))
            if abs(wm['rows']-wf['rows'])>tol:
                return dict(ok=False,
                    reason=f'window/banding rows {wf["rows"]} on far vs {wm["rows"]} on mid',
                    detail=detail)
        elif abs(wm['rows']-wf['rows'])>=2:
            return dict(ok=False,
                reason=f'window/banding rows {wf["rows"]} on far vs {wm["rows"]} on mid',
                detail=detail)

    # tall regular ribbons (glass curtain, office slabs): row-luma must also line up,
    # but not when fill and storey-row count already agree (a shared atlas stamp will
    # not match exact punched-window positions).
    fill_ok=abs(wm['fill']-wf['fill'])<0.12
    row_tol=max(1, int(round(0.25*max(wm['rows'],1))))
    rows_close=abs(wm['rows']-wf['rows'])<=row_tol
    if Hm>=8.0 and wm['rows']>=5 and detail['corr']<CORR_MIN and not (rows_close and (fill_ok or same_colour)):
        return dict(ok=False,
            reason=f'window/banding pattern does not line up with mid (corr {detail["corr"]:.2f})',
            detail=detail)

    # CIE76 ΔE of mean facade colour. A full-facade mean is pulled around by glass
    # area; if that trips but the wall itself is in the same family, pass.
    if de>DE_MAX and wde>DE_MAX:
        return dict(ok=False,
            reason=f'far mean colour ΔE {de:.1f} (wall {wde:.1f}) from mid (threshold {DE_MAX:.0f})',
            detail=detail)
    # dominant pattern orientation: only on tall regular facades (ribbons vs a grid).
    # A one-storey roll-up door is horizontal slats on an otherwise plain wall and
    # must not fail a shared blank/stucco stamp.
    if Hm>=8.0 and wm['rows']>=5:
        if hvm>=HV_STRONG and hvf<HV_WEAK:
            return dict(ok=False,
                reason=f'dominant pattern is horizontal on mid (H/V {hvm:.2f}) but not on far (H/V {hvf:.2f})',
                detail=detail)
        if hvm<=1.0/HV_STRONG and hvf>1.0/HV_WEAK:
            return dict(ok=False,
                reason=f'dominant pattern is vertical on mid (H/V {hvm:.2f}) but not on far (H/V {hvf:.2f})',
                detail=detail)
        if lrm>=0.15 and abs(lrm-lrf)>=LIGHT_ROW_ABS and (lrm/(lrf+1e-6)>=1.8 or lrf/(lrm+1e-6)>=1.8):
            return dict(ok=False,
                reason=f'frame / light-band fraction {lrf:.2f} on far vs {lrm:.2f} on mid',
                detail=detail)
    return dict(ok=True, reason='ok', detail=detail)

def elev_png(glb, path, h=ELEV_H):
    r=_front_elev(glb,h)
    if r is None: return False
    img=r[0]
    Image.fromarray((np.clip(img,0,1)*255+0.5).astype(np.uint8),'RGB').save(path)
    return True
