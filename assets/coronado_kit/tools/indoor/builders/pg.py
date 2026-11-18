"""Prop generator library (runs inside Blender 4.5). Author Z-up, front = -Y (exports to glTF Y-up, front +Z).
Every builder part stores normalised region-local UVs + a region key; finalize(cond) maps into the shared atlas."""
import bpy, bmesh, math, json, os, random, struct
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
K=__import__('os').environ.get('IN_KIT','/workspace/coronado_kit_v2/_staging/indoor/kit')
ATL=json.load(open(K+'/atlases/props_atlas.json'))
REG=ATL['regions']

TRIM={}      # builder key -> (trim region base name, (Pu,Pv) metres per tile)   (set per prop by run.py from defn['trim'])
TKEYS=[]     # trim region names; face attribute 'trim' = index+1 (0 = unique bake / normal region)
FOCAL=[]     # [((x0,y0,z0),(x1,y1,z1)), ...] builder-space boxes kept on the unique bake (lettering, decals, plates)
MAXCELLS=600
def _focal(c, sym=1):
    if not FOCAL: return False
    c=Vector(c)
    if sym==MIRROR and c.x>0: c=Vector((-c.x,c.y,c.z))
    elif sym==MIRROR_Y and c.y>0: c=Vector((c.x,-c.y,c.z))
    elif 1<sym<MIRROR_Y:
        k=rot_sector(sym,c); c=Matrix.Rotation(-k*2*math.pi/sym,3,'Z')@c
    return any(all(a[i]-1e-6<=c[i]<=b[i]+1e-6 for i in range(3)) for a,b in FOCAL)
def is_trim(me):
    if 'trim' not in me.attributes: return [0]*len(me.polygons)
    return [d.value for d in me.attributes['trim'].data]
def trim_uv(ob, cond):
    """trim faces -> their tiling region (page-relative uv rect stored in the region entry)"""
    me=ob.data; tr=is_trim(me); uv=me.uv_layers['UVMap'].data; src=STORE[ob.name]
    for p in me.polygons:
        t=tr[p.index]
        if not t: continue
        nm=TKEYS[t-1]; rname=f'{nm}.{cond}' if f'{nm}.{cond}' in REG else f'{nm}.clean'
        u0,v0,u1,v1=REG[rname]['uv']
        for li in p.loop_indices:
            nu,nv=src[li]; uv[li].uv=(u0+nu*(u1-u0), 1-(v0+(1-nv)*(v1-v0)))
class B:
    def __init__(s, seed=1):
        s.bm=bmesh.new(); s.uvl=s.bm.loops.layers.uv.new('UVMap')
        s.rk=s.bm.faces.layers.int.new('reg'); s.sy=s.bm.faces.layers.int.new('sym'); s.keys=[]; s.cur_sym=1; s.rnd=random.Random(seed)
        s.tr=s.bm.faces.layers.int.new('trim'); s.trim_on=False; s.trim_scale=1.0
        s.col=[]   # collision primitives
    def _k(s,key):
        if key not in s.keys: s.keys.append(key)
        return s.keys.index(key)
    def _region_m(s,key):
        r=REG.get(key+'.clean')
        if r is None: return 1.0, 1.0
        return r['m'][0],r['m'][1]
    # --- core: add faces with metre uvs, then fit island into region
    def faces(s, verts, polys, key, luv, smooth=False, decal=False, sharp=None, fit='stretch'):
        """verts list of Vector; polys list of index tuples; luv: per poly list of (u,v) in metres (or None for decal fit)"""
        if s.trim_on and not decal and key in TRIM: return s._trim_faces(verts,polys,key,luv,smooth)
        if s.trim_on and decal and key in TRIM and TRIM[key][0].startswith('tbd_'): return s._decal_trim(verts,polys,key,luv,smooth)
        bv=[s.bm.verts.new(v) for v in verts]
        fs=[]
        for pi,p in enumerate(polys):
            try: f=s.bm.faces.new([bv[i] for i in p])
            except ValueError: continue
            f.smooth=smooth; f[s.rk]=s._k(key); f[s.sy]=s.cur_sym; fs.append((f,luv[pi]))
        # island fit
        Rw,Rh=s._region_m(key)
        us=[u for _,l in fs for (u,v) in l]; vs=[v for _,l in fs for (u,v) in l]
        if not us: return []
        u0,u1,v0,v1=min(us),max(us),min(vs),max(vs)
        eu=max(u1-u0,1e-6); ev=max(v1-v0,1e-6)
        if decal:
            su,sv=1/eu,1/ev; ou=ov=0
        elif getattr(s,'_abs',False):   # absolute-grid tiling (face already split to one tile): real-scale, seamless
            su,sv=1/Rw,1/Rh; ou=(u0-math.floor(u0/Rw+1e-6)*Rw)*su; ov=(v0-math.floor(v0/Rh+1e-6)*Rh)*sv
        else:
            su=min(1/Rw, 1/eu); sv=min(1/Rh,1/ev)
            ou=s.rnd.uniform(0,max(0,1-eu*su)); ov=s.rnd.uniform(0,max(0,1-ev*sv))
        for f,l in fs:
            for loop,(u,v) in zip(f.loops,l):
                loop[s.uvl].uv=(ou+(u-u0)*su, ov+(v-v0)*sv)
        if sharp is not None:
            pass
        return [f for f,_ in fs]
    def _decal_trim(s, verts, polys, key, luv, smooth):
        """decal face on a page B copy of its page A decal region (tbd_*): stretch-fit like a decal, flagged as a trim face
        so it samples the copied region at the decal's own density instead of the unique bake"""
        tname=TRIM[key][0]
        if tname not in TKEYS: TKEYS.append(tname)
        ti=TKEYS.index(tname)+1; ki=s._k(key); bv=[s.bm.verts.new(v) for v in verts]; fs=[]
        for pi,p in enumerate(polys):
            try: f=s.bm.faces.new([bv[i] for i in p])
            except ValueError: continue
            f.smooth=smooth; f[s.rk]=ki; f[s.sy]=s.cur_sym; f[s.tr]=ti; fs.append((f,luv[pi]))
        us=[u for _,l in fs for (u,v) in l]; vs=[v for _,l in fs for (u,v) in l]
        if not us: return []
        u0,v0=min(us),min(vs); eu=max(max(us)-u0,1e-6); ev=max(max(vs)-v0,1e-6)
        for f,l in fs:
            for loop,(u,v) in zip(f.loops,l): loop[s.uvl].uv=((u-u0)/eu,(v-v0)/ev)
        return [f for f,_ in fs]
    def _trim_faces(s, verts, polys, key, luv, smooth):
        """low-poly faces on a tiling trim region (periodic tile): each face is cut into round(len/P) cells per direction
        and every cell maps the whole tile (cell edges = tile edges, so neighbouring cells and faces join seamlessly);
        faces narrower than 0.6 P take a sub-range at true scale. Cells whose centre is in a FOCAL box (lettering,
        decals, bolted plates) stay on the prop's unique bake instead."""
        spec=TRIM[key]; tname,(Pu,Pv)=spec[0],spec[1]; long_m=(spec[2] if len(spec)>2 else 0.0)*s.trim_scale; Pu*=s.trim_scale; Pv*=s.trim_scale
        if tname not in TKEYS: TKEYS.append(tname)
        ti=TKEYS.index(tname)+1; ki=s._k(key); out=[]
        for p,l in zip(polys,luv):
            Vs=[Vector(verts[i]) for i in p]; L=[Vector((x[0],x[1])) for x in l]
            if len(p)==4:
                e01=L[1]-L[0]; s_is_u=abs(e01.x)>=abs(e01.y)
                Ls=max((L[1]-L[0]).length,(L[2]-L[3]).length); Lt=max((L[2]-L[1]).length,(L[3]-L[0]).length)
                Ps,Pt=(Pu,Pv) if s_is_u else (Pv,Pu)
                ns=max(1,round(Ls/Ps)) if Ls>=0.6*Ps else 0; nt=max(1,round(Lt/Pt)) if Lt>=0.6*Pt else 0
                if long_m and min(Ls,Lt)<0.5*min(Ps,Pt) and max(Ls,Lt)>4*min(Ls,Lt):   # thin member face: few long cells (strip-like stretch)
                    if Ls>Lt: ns=max(1,round(Ls/long_m))
                    else: nt=max(1,round(Lt/long_m))
                while max(ns,1)*max(nt,1)>MAXCELLS: ns=max(1,ns//2) if ns else 0; nt=max(1,nt//2) if nt else 0
                NS,NT=max(ns,1),max(nt,1)
                ms=min((x.x if s_is_u else x.y) for x in L); mt=min((x.y if s_is_u else x.x) for x in L)
                os_=0.0 if ns else min((ms/Ps)%1.0,max(0.0,1-Ls/Ps)); ot=0.0 if nt else min((mt/Pt)%1.0,max(0.0,1-Lt/Pt))
                if not ns and s_is_u and getattr(s,'u_start',None) is not None: os_=(s.u_start/Ps)%1.0   # curved runs: continuous u along the run (caller splits at tile edges)
                bil=lambda a,c: Vs[0]*(1-a)*(1-c)+Vs[1]*a*(1-c)+Vs[2]*a*c+Vs[3]*(1-a)*c
                G=[[s.bm.verts.new(bil(i/NS,j/NT)) for j in range(NT+1)] for i in range(NS+1)]
                for i in range(NS):
                    for j in range(NT):
                        qi=[(i,j),(i+1,j),(i+1,j+1),(i,j+1)]
                        try: f=s.bm.faces.new([G[a][c] for a,c in qi])
                        except ValueError: continue
                        f.smooth=smooth; f[s.rk]=ki; f[s.sy]=s.cur_sym
                        cen=sum((G[a][c].co for a,c in qi),Vector())/4
                        f[s.tr]=0 if _focal(cen,s.cur_sym) else ti
                        for loop,(a,c) in zip(f.loops,qi):
                            A=(a-i) if ns else os_+(Ls/Ps if a==i+1 else 0.0)
                            C=(c-j) if nt else ot+(Lt/Pt if c==j+1 else 0.0)
                            loop[s.uvl].uv=(A,C) if s_is_u else (C,A)
                        out.append(f)
            else:
                bv=[s.bm.verts.new(v) for v in Vs]
                try: f=s.bm.faces.new(bv)
                except ValueError: continue
                us=[x.x for x in L]; vs_=[x.y for x in L]; u0,v0=min(us),min(vs_); eu=max(us)-u0; ev=max(vs_)-v0
                su=1/max(eu,Pu); sv=1/max(ev,Pv); ou=s.rnd.uniform(0,max(0,1-eu*su)); ov=s.rnd.uniform(0,max(0,1-ev*sv))
                f.smooth=smooth; f[s.rk]=ki; f[s.sy]=s.cur_sym
                f[s.tr]=0 if _focal(sum(Vs,Vector())/len(Vs),s.cur_sym) else ti
                for loop,x in zip(f.loops,L): loop[s.uvl].uv=(ou+(x.x-u0)*su, ov+(x.y-v0)*sv)
                out.append(f)
        return out
    # --- primitives
    def quad(s, pts, key, decal=False, flip=False):
        pts=[Vector(p) for p in pts]
        if flip: pts=pts[::-1]
        n=Vector((0,0,0))
        for i in range(len(pts)): n+=pts[i].cross(pts[(i+1)%len(pts)])  # Newell normal
        n.normalize()
        up=Vector((0,0,1))
        if abs(n.z)>0.9: e1=Vector((1,0,0)) if n.z>0 else Vector((1,0,0))
        else: e1=up.cross(n).normalized()
        e2=n.cross(e1).normalized()
        l=[(p.dot(e1),p.dot(e2)) for p in pts]
        if key in getattr(s,'tile_keys',()) and not decal and len(pts)==4:
            return s._tiled(pts,n,e1,e2,l,key)
        return s.faces(pts,[tuple(range(len(pts)))],key,[l],decal=decal)
    def _tiled(s, pts, n, e1, e2, l, key):
        """split a planar rectangle on the absolute region grid so the material tiles at real scale (high-poly bakes)"""
        Rw,Rh=s._region_m(key); us=[a for a,_ in l]; vs=[b for _,b in l]
        u0,u1,v0,v1=min(us),max(us),min(vs),max(vs); d=pts[0].dot(n)
        def cuts(a,b,R):
            c=[a]; k=math.floor(a/R+1e-6)+1
            while k*R<b-1e-6: c.append(k*R); k+=1
            return c+[b]
        cu=cuts(u0,u1,Rw); cv=cuts(v0,v1,Rh); out=[]
        P=lambda u,v: n*d+e1*u+e2*v
        s._abs=True
        try:
            for i in range(len(cu)-1):
                for j in range(len(cv)-1):
                    q=[P(cu[i],cv[j]),P(cu[i+1],cv[j]),P(cu[i+1],cv[j+1]),P(cu[i],cv[j+1])]
                    out+=s.faces(q,[(0,1,2,3)],key,[[(cu[i],cv[j]),(cu[i+1],cv[j]),(cu[i+1],cv[j+1]),(cu[i],cv[j+1])]])
        finally: s._abs=False
        return out
    def poly(s, pts, key, decal=False):
        return s.quad(pts,key,decal)
    def box(s, c, size, key, skip=(), decal=None, rz=0.0, keys=None, rx=0.0):
        """c=(x,y,z0) bottom centre; size=(w,d,h). decal={'front':'sign_x'}; keys={'top':'k2'} per-face material"""
        x,y,z=c; w,d,h=size; decal=decal or {}; keys=keys or {}
        R=Matrix.Rotation(rz,3,'Z')@Matrix.Rotation(rx,3,'X')
        def P(a,b,cz): return Vector((x,y,z))+R@Vector((a,b,cz))
        hw,hd=w/2,d/2
        F={'front':[P(-hw,-hd,0),P(hw,-hd,0),P(hw,-hd,h),P(-hw,-hd,h)],
           'back':[P(hw,hd,0),P(-hw,hd,0),P(-hw,hd,h),P(hw,hd,h)],
           'left':[P(-hw,hd,0),P(-hw,-hd,0),P(-hw,-hd,h),P(-hw,hd,h)],
           'right':[P(hw,-hd,0),P(hw,hd,0),P(hw,hd,h),P(hw,-hd,h)],
           'top':[P(-hw,-hd,h),P(hw,-hd,h),P(hw,hd,h),P(-hw,hd,h)],
           'bottom':[P(-hw,hd,0),P(hw,hd,0),P(hw,-hd,0),P(-hw,-hd,0)]}
        out=[]
        for nm,pts in F.items():
            if nm in skip: continue
            if nm in decal: out+=s.quad(pts,decal[nm],decal=True)
            else: out+=s.quad(pts,keys.get(nm,key))
        return out
    def tube(s, p0, p1, r0, r1, seg, key, cap0=False, cap1=True, smooth=True, phase=0.0, decal_cap=None, sq=False):
        """cylinder / cone frustum between points; sq=True -> square section (seg ignored=4)"""
        p0=Vector(p0); p1=Vector(p1); ax=(p1-p0); L=ax.length; ax.normalize()
        t=Vector((0,0,1)) if abs(ax.z)<0.99 else Vector((1,0,0)); bx=ax.cross(t).normalized(); by=ax.cross(bx).normalized()
        if sq: seg=4; phase=math.pi/4
        vs=[];
        for ring,(p,r) in enumerate(((p0,r0),(p1,r1))):
            for i in range(seg+1):
                a=phase+2*math.pi*i/seg
                vs.append(p+(bx*math.cos(a)+by*math.sin(a))*r*(1.4142 if sq else 1))
        polys=[];luv=[]
        rm=max(r0,r1)*(1.4142 if sq else 1)
        for i in range(seg):
            polys.append((i,i+1,seg+1+i+1,seg+1+i))
            u0=2*math.pi*rm*i/seg; u1=2*math.pi*rm*(i+1)/seg
            luv.append([(u0,0),(u1,0),(u1,L),(u0,L)])
        out=s.faces(vs,polys,key,luv,smooth=smooth and not sq)
        for cap,(p,r,sgn) in ((cap0,(p0,r0,-1)),(cap1,(p1,r1,1))):
            if cap and r>1e-5:
                ring=[p+(bx*math.cos(phase+2*math.pi*i/seg)+by*math.sin(phase+2*math.pi*i/seg))*r*(1.4142 if sq else 1) for i in range(seg)]
                if sgn<0: ring=ring[::-1]
                if decal_cap and sgn>0: out+=s.quad(ring,decal_cap,decal=True)
                else: out+=s.quad(ring,key)
        return out
    def lathe(s, prof, seg, key, c=(0,0,0), cap_top=True, cap_bot=False, smooth=True, decal_top=None, phase=0.0, sym=None):
        """prof: [(r,z),...] bottom->top. sym: list per band of rotational UV symmetry (1 = unique)"""
        if sym is not None and not isinstance(sym,(list,tuple)): sym=[sym]*(len(prof)-1)
        c=Vector(c); vs=[]
        for (r,z) in prof:
            for i in range(seg+1):
                a=phase+2*math.pi*i/seg; vs.append(c+Vector((r*math.cos(a),r*math.sin(a),z)))
        polys=[];luv=[]; acc=0; rm=max(p[0] for p in prof); band_of=[]
        for j in range(len(prof)-1):
            dl=math.hypot(prof[j+1][0]-prof[j][0],prof[j+1][1]-prof[j][1])
            for i in range(seg):
                a=j*(seg+1)+i; b=(j+1)*(seg+1)+i
                if prof[j][0]<1e-6 and prof[j+1][0]<1e-6: continue
                polys.append((a,a+1,b+1,b)); u0=2*math.pi*rm*i/seg; u1=2*math.pi*rm*(i+1)/seg
                luv.append([(u0,acc),(u1,acc),(u1,acc+dl),(u0,acc+dl)]); band_of.append(j)
            acc+=dl
        out=s.faces(vs,polys,key,luv,smooth=smooth) if polys else []
        if sym is not None:
            for f,j in zip(out,band_of): f[s.sy]=sym[j]
        # hard profile corners: mark ring edges sharp where the profile turns > 12 deg (avoids smooth-normal gradients
        # across long faces, which show as diagonal shading seams with a baked normal map)
        sz=[]
        for j in range(1,len(prof)-1):
            d1=Vector((prof[j][0]-prof[j-1][0],prof[j][1]-prof[j-1][1])); d2=Vector((prof[j+1][0]-prof[j][0],prof[j+1][1]-prof[j][1]))
            if d1.length>1e-6 and d2.length>1e-6 and d1.angle(d2)>math.radians(12): sz.append(c.z+prof[j][1])
        if sz:
            for f in out:
                for e in f.edges:
                    z0=e.verts[0].co.z; z1=e.verts[1].co.z
                    if abs(z0-z1)<1e-6 and any(abs(z0-z)<1e-6 for z in sz): e.smooth=False
        if cap_top and prof[-1][0]>1e-5:
            r,z=prof[-1]; ring=[c+Vector((r*math.cos(phase+2*math.pi*i/seg),r*math.sin(phase+2*math.pi*i/seg),z)) for i in range(seg)]
            out+=s.quad(ring,decal_top or key,decal=bool(decal_top))
        if cap_bot and prof[0][0]>1e-5:
            r,z=prof[0]; ring=[c+Vector((r*math.cos(phase+2*math.pi*i/seg),r*math.sin(phase+2*math.pi*i/seg),z)) for i in range(seg)][::-1]
            out+=s.quad(ring,key)
        return out
    def sweep(s, pts, r, seg, key, cap0=True, cap1=True, sq=False):
        """tube along polyline with mitred joints"""
        pts=[Vector(p) for p in pts]; n=len(pts)
        if sq: seg=4
        frames=[]
        prev_bx=None
        for i,p in enumerate(pts):
            if i==0: t=(pts[1]-pts[0]).normalized()
            elif i==n-1: t=(pts[-1]-pts[-2]).normalized()
            else: t=((pts[i]-pts[i-1]).normalized()+(pts[i+1]-pts[i]).normalized()).normalized()
            if prev_bx is None:
                up=Vector((0,0,1)) if abs(t.z)<0.95 else Vector((1,0,0)); bx=t.cross(up).normalized()
            else:
                bx=(prev_bx-t*prev_bx.dot(t)).normalized()
            by=t.cross(bx).normalized(); prev_bx=bx
            sc=1.0
            if 0<i<n-1:
                d=(pts[i]-pts[i-1]).normalized(); sc=1/max(0.35,d.dot(t))
            frames.append((p,bx,by,sc,t))
        vs=[]; ph=math.pi/4 if sq else 0
        rr=r*(1.4142 if sq else 1)
        for i,(p,bx,by,sc,t) in enumerate(frames):
            bend=None
            if 0<i<n-1:
                d1=(pts[i]-pts[i-1]).normalized(); d2=(pts[i+1]-pts[i]).normalized(); bd=d2-d1; bd=bd-t*bd.dot(t)
                if bd.length>1e-6: bend=bd.normalized()
            for k in range(seg+1):
                a=ph+2*math.pi*k/seg; off=(bx*math.cos(a)+by*math.sin(a))*rr
                if bend is not None: off=off+bend*off.dot(bend)*(sc-1)
                vs.append(p+off)
        polys=[];luv=[]; acc=0
        for i in range(n-1):
            L=(pts[i+1]-pts[i]).length
            for k in range(seg):
                a=i*(seg+1)+k; b=(i+1)*(seg+1)+k
                polys.append((a,a+1,b+1,b)); u0=2*math.pi*rr*k/seg; u1=2*math.pi*rr*(k+1)/seg
                luv.append([(u0,acc),(u1,acc),(u1,acc+L),(u0,acc+L)])
            acc+=L
        out=s.faces(vs,polys,key,luv,smooth=not sq)
        for cap,fi,sgn in ((cap0,0,-1),(cap1,n-1,1)):
            if cap:
                p,bx,by,sc,t=frames[fi]; ring=[p+(bx*math.cos(ph+2*math.pi*k/seg)+by*math.sin(ph+2*math.pi*k/seg))*rr for k in range(seg)]
                if sgn<0: ring=ring[::-1]
                out+=s.quad(ring,key)
        return out
    def prism(s, pts2, y0, y1, key, decal_front=None, decal_back=None, sides=True, back=True, front=True, back_key=None, top_only=False):
        """extrude polygon given in XZ (x,z) between y0 (front, -Y side) and y1"""
        out=[]
        F=[Vector((x,y0,z)) for x,z in pts2]; Bk=[Vector((x,y1,z)) for x,z in pts2][::-1]
        if front: out+=s.quad(F,decal_front or key,decal=bool(decal_front))
        if back: out+=s.quad(Bk,decal_back or back_key or key,decal=bool(decal_back))
        if sides:
            m=len(pts2)
            for i in range(m):
                a=pts2[i]; b=pts2[(i+1)%m]
                if top_only and not (a[1]>0.0 and b[1]>0.0 and min(a[1],b[1])>=max(p[1] for p in pts2)-1e-4): pass
                q=[Vector((b[0],y0,b[1])),Vector((a[0],y0,a[1])),Vector((a[0],y1,a[1])),Vector((b[0],y1,b[1]))]
                out+=s.quad(q,key)
        return out
    # --- collision
    def cbox(s,c,size,rz=0.0): s.col.append(('box',c,size,rz))
    def ccyl(s,c,r,h): s.col.append(('cyl',c,r,h))
    def tris(s):
        return sum(len(f.verts)-2 for f in s.bm.faces)

# ------------------------------------------------------------------ object creation
HARD_ANGLE=50
def to_object(b, name):
    bm=b.bm.copy()
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.triangulate(bm, faces=bm.faces, quad_method='BEAUTY', ngon_method='BEAUTY')
    # drop degenerate
    deg=[f for f in bm.faces if f.calc_area()<1e-9]
    if deg: bmesh.ops.delete(bm, geom=deg, context='FACES')
    for e in bm.edges:
        if len(e.link_faces)==2 and e.calc_face_angle(0)>math.radians(HARD_ANGLE): e.smooth=False
    me=bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob=bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    # sharp edges by angle (flat parts) : use smooth-by-angle behaviour
    for e in me.edges: pass
    return ob

def bake_ao(ob, ground=True, wall_y=None, dist=None, rays=48, strength=0.85):
    """per-corner AO into colour attribute 'Col' (baked AO, multiplied into base colour in glTF COLOR_0)"""
    me=ob.data
    bm=bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table()
    tree=BVHTree.FromBMesh(bm)
    dims=ob.dimensions; size=max(dims); dist=dist or max(0.25,min(1.5,size*0.35))
    rng=random.Random(5)
    # fixed cosine hemisphere samples
    S=[]
    for i in range(rays):
        u=(i+0.5)/rays; v=(i*0.618034)%1
        r=math.sqrt(u); th=2*math.pi*v; S.append((r*math.cos(th),r*math.sin(th),math.sqrt(max(0,1-u))))
    if 'Col' in me.color_attributes: me.color_attributes.remove(me.color_attributes['Col'])
    ca=me.color_attributes.new('Col','BYTE_COLOR','CORNER')
    vals=[1.0]*len(me.loops)
    for f in bm.faces:
        n=f.normal; cen=f.calc_center_median()
        t=Vector((0,0,1)) if abs(n.z)<0.9 else Vector((1,0,0)); tx=n.cross(t).normalized(); ty=n.cross(tx)
        for l in f.loops:
            p=l.vert.co.lerp(cen,0.2)+n*0.002
            occ=0.0
            for (a,b,c) in S:
                d=tx*a+ty*b+n*c
                hit=tree.ray_cast(p,d,dist)
                h=hit[0] is not None
                if not h and ground and d.z<-1e-4:
                    tg=-p.z/d.z
                    h=0<tg<dist
                if not h and wall_y is not None and d.y>1e-4:
                    tw=(wall_y-p.y)/d.y; h=0<tw<dist
                if h: occ+=1
            ao=1-strength*occ/rays
            vals[l.index]=ao
    bm.free()
    for i,v in enumerate(vals): ca.data[i].color=(v,v,v,1.0)
    me.color_attributes.active_color=ca
    AOS[ob.name]=vals
WX=None   # waterfront weathering (dict) for the clean colour bake
AOS={}
DIRT=(0.52,0.45,0.36)
AO_ZONLY=False
def cond_colors(ob, ci, ground=True, tint=None, keys=None, gmask=None, ttint=None):
    """COLOR_0 = baked AO x condition grime (dirt splash / grime at the base for worn & dirty variants)"""
    me=ob.data; vals=AOS[ob.name]; ca=me.color_attributes['Col']
    if AO_ZONLY and not ob.name.endswith('near') and len(me.polygons)<40:
        # walls mid/far: AO as a function of height only (per-corner AO differences made a diagonal seam across big quads)
        grp={}
        for li,l in enumerate(me.loops): grp.setdefault(round(me.vertices[l.vertex_index].co.z,2),[]).append(vals[li])
        vals=[sum(grp[round(me.vertices[l.vertex_index].co.z,2)])/len(grp[round(me.vertices[l.vertex_index].co.z,2)]) for l in me.loops]
    amt={0:0.0,1:0.30,2:0.55}[ci]; fall={0:1,1:0.22,2:0.38}[ci]
    ltp={}; trf=is_trim(me)
    if tint or ttint:
        for p in me.polygons:
            for li in p.loop_indices: ltp[li]=p.index
    for li,l in enumerate(me.loops):
        z=me.vertices[l.vertex_index].co.z; a=vals[li]
        g=amt*math.exp(-max(z,0)/fall) if (ground or (gmask and li in gmask)) else 0.0
        col=[a*((1-g)+g*DIRT[k]/0.8) for k in range(3)]
        if tint:
            kk=keys[me.attributes['reg'].data[ltp[li]].value]
            if kk in tint: col=[col[k]*tint[kk][k] for k in range(3)]
        if ttint and trf[ltp[li]]:
            kk=keys[me.attributes['reg'].data[ltp[li]].value]
            if kk in ttint: col=[col[k]*ttint[kk][k] for k in range(3)]
        ca.data[li].color=(min(col[0],1),min(col[1],1),min(col[2],1),1.0)

def apply_uv(ob, keys, cond):
    me=ob.data; uv=me.uv_layers['UVMap'].data; rk=me.attributes['reg'].data
    tr=is_trim(me)
    for p in me.polygons:
        if tr[p.index]: continue
        key=keys[rk[p.index].value]
        rname=f'{key}.{cond}' if f'{key}.{cond}' in REG else f'{key}.clean'
        u0,v0,u1,v1=REG[rname]['uv']
        for li in p.loop_indices:
            nu,nv=STORE[ob.name][li]
            uv[li].uv=(u0+nu*(u1-u0), 1-(v0+(1-nv)*(v1-v0)))
    if any(tr): trim_uv(ob,cond)
STORE={}
def store_uv(ob):
    me=ob.data; STORE[ob.name]=[tuple(l.uv) for l in me.uv_layers['UVMap'].data]

# ------------------------------------------------------------------ materials for preview (export material rewritten later)
def preview_mat(kind='near', alpha=False, cond='clean'):
    pp=f'props_{PAGE}_' if (PAGE and (kind=='near' or MID_ON_PAGE)) else 'props_'
    nm=f'{pp}atlas_{kind}_{cond}{"_a" if alpha else ""}'
    if nm in bpy.data.materials: return bpy.data.materials[nm]
    m=bpy.data.materials.new(nm); m.use_nodes=True; nt=m.node_tree; N=nt.nodes; L=nt.links
    bs=N['Principled BSDF']
    def img(p,cs):
        n=N.new('ShaderNodeTexImage'); n.image=bpy.data.images.load(p,check_existing=True); n.image.colorspace_settings.name=cs; n.interpolation='Linear'; n.extension='EXTEND'; return n
    c=img(K+f'/atlases/{pp}color_{cond}.png','sRGB'); va=N.new('ShaderNodeVertexColor'); va.layer_name='Col'
    mul=N.new('ShaderNodeMix'); mul.data_type='RGBA'; mul.blend_type='MULTIPLY'; mul.inputs[0].default_value=1
    L.new(c.outputs['Color'],mul.inputs[6]); L.new(va.outputs['Color'],mul.inputs[7]); L.new(mul.outputs[2],bs.inputs['Base Color'])
    if kind=='near':
        nn=img(K+f'/atlases/{pp}normal.png','Non-Color'); nm_=N.new('ShaderNodeNormalMap'); L.new(nn.outputs['Color'],nm_.inputs['Color']); L.new(nm_.outputs['Normal'],bs.inputs['Normal'])
        o=img(K+f'/atlases/{pp}orm.png','Non-Color'); sp=N.new('ShaderNodeSeparateColor'); L.new(o.outputs['Color'],sp.inputs[0])
        L.new(sp.outputs[1],bs.inputs['Roughness']); L.new(sp.outputs[2],bs.inputs['Metallic'])
    else:
        bs.inputs['Roughness'].default_value=0.7; bs.inputs['Metallic'].default_value=0
    if alpha:
        L.new(c.outputs['Alpha'],bs.inputs['Alpha']); m.blend_method='CLIP' if hasattr(m,'blend_method') else None
    return m

# ------------------------------------------------------------------ export
def clear_scene():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
    for me in list(bpy.data.meshes): bpy.data.meshes.remove(me)

DZ=0.0  # vertical shift applied at export (wall props: mount height -> origin at bottom of bbox)
def export_glb(ob, path, tier='near', alpha=False, double=False, cond='clean'):
    os.makedirs(os.path.dirname(path),exist_ok=True)
    if DZ:
        ob.data.transform(Matrix.Translation((0,0,DZ)))
        try: return _export_glb(ob,path,tier,alpha,double,cond)
        finally: ob.data.transform(Matrix.Translation((0,0,-DZ)))
    return _export_glb(ob,path,tier,alpha,double,cond)
def _export_glb(ob, path, tier='near', alpha=False, double=False, cond='clean'):
    for o in bpy.context.scene.objects: o.select_set(False)
    ob.select_set(True); bpy.context.view_layer.objects.active=ob
    kw=dict(filepath=path, export_format='GLB', use_selection=True, export_apply=True, export_texcoords=True, export_normals=True,
            export_tangents=(tier=='near'), export_materials='EXPORT', export_image_format='NONE', export_yup=True,
            export_animations=False, export_cameras=False, export_lights=False, export_extras=False)
    try: bpy.ops.export_scene.gltf(**kw, export_vertex_color='ACTIVE')
    except TypeError: bpy.ops.export_scene.gltf(**kw, export_colors=True)
    fix_glb(path, tier, alpha, double, cond)

def fix_glb(path, tier, alpha, double, cond='clean'):
    """rewrite material to reference the shared atlases by relative URI"""
    data=open(path,'rb').read()
    magic,ver,ln=struct.unpack('<III',data[:12]); jl,jt=struct.unpack('<II',data[12:20]); js=json.loads(data[20:20+jl])
    rest=data[20+jl:]
    rel=os.path.relpath(K+'/atlases',os.path.dirname(path)).replace(os.sep,'/')
    pp=f'props_{PAGE}_' if (PAGE and (tier=='near' or MID_ON_PAGE)) else 'props_'
    js['images']=[{'uri':f'{rel}/{pp}color_{cond}.png'}]+([{'uri':f'{rel}/{pp}normal.png'},{'uri':f'{rel}/{pp}orm.png'}] if tier=='near' else [])
    js['samplers']=[{'magFilter':9729,'minFilter':9987,'wrapS':33071,'wrapT':33071}]
    js['textures']=[{'sampler':0,'source':i} for i in range(len(js['images']))]
    m={'name':(pp+'atlas') if not alpha else (pp+'atlas_cutout'),'pbrMetallicRoughness':{'baseColorTexture':{'index':0,'texCoord':0}}}
    if tier=='near':
        m['pbrMetallicRoughness'].update({'metallicRoughnessTexture':{'index':2},'metallicFactor':1.0,'roughnessFactor':1.0})
        m['normalTexture']={'index':1}
    else:
        m['pbrMetallicRoughness'].update({'metallicFactor':0.0,'roughnessFactor':0.75})
    if alpha: m['alphaMode']='MASK'; m['alphaCutoff']=0.5
    if double: m['doubleSided']=True
    js['materials']=[m]
    for me in js.get('meshes',[]):
        for p in me['primitives']: p['material']=0
    js.pop('extensionsUsed',None)
    j=json.dumps(js,separators=(',',':')).encode(); j+=b' '*((4-len(j)%4)%4)
    out=struct.pack('<III',magic,ver,12+8+len(j)+len(rest))+struct.pack('<II',len(j),0x4E4F534A)+j+rest
    open(path,'wb').write(out)

def col_object(b, name='col'):
    bm=bmesh.new()
    for c in b.col:
        if c[0]=='box':
            _,(x,y,z),(w,d,h),rz=c
            m=Matrix.Translation((x,y,z+h/2))@Matrix.Rotation(rz,4,'Z')@Matrix.Diagonal((w,d,h,1))
            bmesh.ops.create_cube(bm,size=1.0,matrix=m)
        else:
            _,(x,y,z),r,h=c
            bmesh.ops.create_cone(bm,cap_ends=True,segments=12,radius1=r,radius2=r,depth=h,matrix=Matrix.Translation((x,y,z+h/2)))
    bmesh.ops.triangulate(bm,faces=bm.faces)
    if DZ: bmesh.ops.translate(bm,vec=(0,0,DZ),verts=bm.verts)
    me=bpy.data.meshes.new('col'); bm.to_mesh(me); bm.free()
    ob=bpy.data.objects.new('col',me); bpy.context.scene.collection.objects.link(ob); return ob

def export_col(b, path):
    ob=col_object(b)
    for o in bpy.context.scene.objects: o.select_set(False)
    ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_materials='NONE', export_texcoords=False,
                              export_normals=False, export_animations=False, export_yup=True)
    bpy.data.objects.remove(ob,do_unlink=True)

# ================================================================== high-poly -> low-poly baking into unique atlas slots
BAKE_DIR=K+'/props/_bake'; os.makedirs(BAKE_DIR+'/tiles',exist_ok=True)
SLOTS_P=BAKE_DIR+'/slots.json'
PAGE=''        # '' = props page A (2048, shared regions); 'b' = props page B (1024, baked tiles only: phase-D industrial props)
MID_ON_PAGE=False   # mid/far tiers sample the near bake on the same page (uv_from_near)
PAGE_SIZE={'':2048,'b':int(os.environ.get('PAGE_B_SIZE','1024')),'c':512,'w':1024,'i':1024}
def _slots_p(): return SLOTS_P if not PAGE else BAKE_DIR+f'/slots_{PAGE}.json'
def _jdump(S_):
    P_=_slots_p(); t=P_+'.tmp'; json.dump(S_,open(t,'w'),indent=1); os.replace(t,P_)
def _slots():
    P_=_slots_p(); return json.load(open(P_)) if os.path.exists(P_) else {'shelf':None,'slots':{}}
def _place(occ, gw, gh, cs):
    """first free cs x cs (grid cells) square, lowest row first (fills holes)"""
    import numpy as np
    for gy in range(0,gh-cs+1):
        row=occ[gy:gy+cs]
        if row.shape[0]<cs: break
        colfree=~row.any(axis=0)
        run=0
        for gx in range(gw):
            run=run+1 if colfree[gx] else 0
            if run>=cs: return gx-cs+1,gy
    return None
def _grid(S_, skip=None):
    import numpy as np
    # whole page: the region rows above bake_area are free for tiles wherever no region rect sits (unused cells)
    G=16; x0,y0=0,0; gw=PAGE_SIZE[PAGE]//G; gh=PAGE_SIZE[PAGE]//G; by=ATL['bake_area'][1] if not PAGE else 0
    occ=np.zeros((gh,gw),bool)
    for k,v in REG.items():
        if v.get('page','')!=PAGE: continue
        x,y,w,h=v['px']
        if v.get('trim'): occ[y//G:(y+h+G-1)//G,x//G:(x+w+G-1)//G]=True   # tiling trim tiles (any row, either page)
        elif y<by and not PAGE: occ[y//G:min(by,y+h+G-1)//G+0,x//G:(x+w+G-1)//G]=True
    if PAGE=='w': occ[:384//G,:]=True   # page W rows 0-383 reserved for waterfront trim tiles (incl. future ones)
    if PAGE=='i': occ[:256//G,:]=True   # page I rows 0-255 reserved for indoor trim tiles
    for nm,rs in S_['slots'].items():
        if nm==skip: continue
        for x,y,w,h in rs: occ[(y-y0)//G:(y-y0+h+G-1)//G,(x-x0)//G:(x-x0+w+G-1)//G]=True
    return occ,gw,gh,G,x0,y0
def alloc_slot(name, side, n=1):
    """persistent allocation of square tiles in the bake area: free-space grid, fills holes left by earlier props"""
    S_=_slots()
    if name in S_['slots'] and S_['slots'][name][0][2]==side: return S_['slots'][name]
    occ,gw,gh,G,x0,y0=_grid(S_,skip=name); out=[]
    cs=(side+G-1)//G
    for i in range(n):
        p=_place(occ,gw,gh,cs)
        if p is None: raise RuntimeError('bake area full (%d px)'%side)
        occ[p[1]:p[1]+cs,p[0]:p[0]+cs]=True; out.append([x0+p[0]*G,y0+p[1]*G,side,side])
    S_['slots'][name]=out; S_['shelf']=None; _jdump(S_)
    return out
def repack_slots():
    S_=_slots(); items=sorted(S_['slots'].items(),key=lambda t:-t[1][0][2]); S_['slots']={}
    occ,gw,gh,G,x0,y0=_grid(S_)
    for nm,rs in items:
        side=rs[0][2]; cs=(side+G-1)//G; out=[]
        for r in rs:
            p=_place(occ,gw,gh,cs); occ[p[1]:p[1]+cs,p[0]:p[0]+cs]=True; out.append([x0+p[0]*G,y0+p[1]*G,side,side])
        S_['slots'][nm]=out
    _jdump(S_); return S_
def bake_free_frac():
    occ,gw,gh,G,x0,y0=_grid(_slots()); return 1-occ.mean()
def surface_area(ob): return sum(p.area for p in ob.data.polygons)
SHARE_THIN=0.0    # metres; >0 (with SQUASH_LONG): thin strips narrower than this share one UV rect per material
SQUASH_LONG=0.0   # metres; >0: long thin plain islands (legs, rails, rods) are compressed lengthwise to this length before packing
def _squash_long(ob, limit):
    """edit-mode helper: thin UV islands (aspect>5) longer than `limit` metres are scaled down along their long axis,
    so a 20 m leg strip does not set the packing scale of the whole prop (plain painted members tolerate lengthwise stretch)"""
    import bmesh
    bm=bmesh.from_edit_mesh(ob.data); lay=bm.loops.layers.uv.active; bm.faces.ensure_lookup_table()
    a2=sum(f.calc_area() for f in bm.faces)
    def uva(f):
        p=[l[lay].uv for l in f.loops]; return abs(sum(p[i].x*p[i-1].y-p[i-1].x*p[i].y for i in range(len(p))))/2
    u2=sum(uva(f) for f in bm.faces)
    if a2<=0 or u2<=0: return {}
    k=math.sqrt(u2/a2)   # uv units per metre
    seen=set(); _st=[0,0,0]; _rl=bm.faces.layers.int.get('reg'); share={}
    for f0 in bm.faces:
        if f0.index in seen: continue
        isl=[]; st=[f0]; seen.add(f0.index)
        while st:
            f=st.pop(); isl.append(f)
            for l in f.loops:
                for l2 in l.edge.link_loops:
                    g=l2.face
                    if g.index in seen or g is f: continue
                    # same island if the shared edge has matching uvs on both sides
                    a0=l[lay].uv; a1=l.link_loop_next[lay].uv; b0=l2[lay].uv; b1=l2.link_loop_next[lay].uv
                    if ((a0-b1).length<1e-6 and (a1-b0).length<1e-6) or ((a0-b0).length<1e-6 and (a1-b1).length<1e-6):
                        seen.add(g.index); st.append(g)
        ls=[l[lay] for f in isl for l in f.loops]
        c=sum((u.uv for u in ls),Vector((0,0)))/len(ls)
        sxx=sum((u.uv.x-c.x)**2 for u in ls); syy=sum((u.uv.y-c.y)**2 for u in ls); sxy=sum((u.uv.x-c.x)*(u.uv.y-c.y) for u in ls)
        th=0.5*math.atan2(2*sxy,sxx-syy); d=Vector((math.cos(th),math.sin(th))); n=Vector((-d.y,d.x))
        pd=[(u.uv-c).dot(d) for u in ls]; pn=[(u.uv-c).dot(n) for u in ls]
        L=max(pd)-min(pd); W=max(pn)-min(pn)
        _st[0]+=1
        if os.environ.get('SQDBG'): print('ISL',len(isl),round(L/k,2),round(W/k,3),isl[0].material_index,flush=True)
        if W<=0 or L/W<5: continue
        if SHARE_THIN and W/k<SHARE_THIN:
            # thin rod / rail / rung strip: every such strip of one material shares one canonical rect; only the first
            # (representative) is packed, the rest are copied onto it after packing, so margins no longer eat the page
            mi=isl[0][_rl] if _rl is not None else isl[0].material_index; d0=min(pd); n0=min(pn)
            ab=[((a_-d0)/L,(b_-n0)/W) for a_,b_ in zip(pd,pn)]
            for u,(a_,b_) in zip(ls,ab): u.uv=Vector((0.5+a_*1.2*k,0.5+b_*0.06*k))
            loops=[(f.index,j) for f in isl for j in range(len(f.loops))]
            g=share.setdefault(mi,[]); g.append((loops,ab))
            if len(g)>1:
                for f in isl: f.select=False
            continue
        if L/k<=limit: continue
        f_=limit*k/L
        for u in ls:
            r=u.uv-c; u.uv=c+d*(r.dot(d)*f_)+n*r.dot(n)
    bmesh.update_edit_mesh(ob.data)
    return share
def _share_apply(ob, share):
    import bmesh, numpy as np
    bm=bmesh.from_edit_mesh(ob.data); lay=bm.loops.layers.uv.active; bm.faces.ensure_lookup_table()
    for g in share.values():
        loops,ab=g[0]
        A=np.array([[a,b_,1.0] for a,b_ in ab]); Y=np.array([list(bm.faces[fi].loops[j][lay].uv) for fi,j in loops])
        M,_,_,_=np.linalg.lstsq(A,Y,rcond=None)
        for loops2,ab2 in g[1:]:
            for (fi,j),(a,b_) in zip(loops2,ab2):
                bm.faces[fi].loops[j][lay].uv=Vector(tuple(np.array([a,b_,1.0])@M))
    for f in bm.faces: f.select=True
    bmesh.update_edit_mesh(ob.data)
def unique_uv(ob, margin_px=4, side=128):
    """unique non-overlapping unwrap of the game mesh, normalised to 0..1 (stored in STORE as normalised)"""
    bpy.context.view_layer.objects.active=ob
    for o in bpy.context.scene.objects: o.select_set(False)
    ob.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(34), island_margin=0.0, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    share=_squash_long(ob, SQUASH_LONG) if SQUASH_LONG else None
    bpy.ops.uv.pack_islands(rotate=True, margin=margin_px*1.5/side, shape_method='CONCAVE', **({'margin_method':'FRACTION'} if SQUASH_LONG else {}))
    if share: _share_apply(ob, share)
    bpy.ops.object.mode_set(mode='OBJECT')
    if SQUASH_LONG:   # the packer leaves a strip unused when islands are long: rescale the packed set to fill the slot
        uv=ob.data.uv_layers.active.data; us=[l.uv[0] for l in uv]; vs=[l.uv[1] for l in uv]; m=margin_px/side
        u0,v0=min(us),min(vs); sc=(1-2*m)/max(max(us)-u0,max(vs)-v0)
        if os.environ.get('SQDBG'):
            import collections; print('BBOX',u0,v0,max(us),max(vs),sc,flush=True)
            for p in ob.data.polygons:
                pu=[uv[i].uv for i in p.loop_indices]
                if max(x[1] for x in pu)>0.8 or max(x[0] for x in pu)>0.8: print('HI',p.index,p.center[:],[tuple(round(c,3) for c in x) for x in pu],flush=True)
        if sc>1.0:
            for l in uv: l.uv=((l.uv[0]-u0)*sc+m,(l.uv[1]-v0)*sc+m)

def planar_uv_xy(ob, radius, margin=0.02):
    """Unique faces only: XY planar unwrap centred in 0..1 (v-up, +Y -> v=1).
    radius is the world radius that maps to 0.5±(0.5-margin)."""
    me=ob.data; tr=is_trim(me); uv=me.uv_layers.active.data
    s=0.5-margin
    for p in me.polygons:
        if tr[p.index]: continue
        for li in p.loop_indices:
            v=me.vertices[me.loops[li].vertex_index].co
            uv[li].uv=(0.5+v.x/radius*s, 0.5+v.y/radius*s)

def slot_uv(ob, rect, store_key=None):
    """map the 0..1 unwrap into an atlas rect (blender uv, v up)"""
    x,y,w,h=rect; N_=float(PAGE_SIZE[PAGE]); uv=ob.data.uv_layers.active.data
    src=STORE.setdefault((store_key or ob.name)+'#u',[tuple(l.uv) for l in uv])
    tr=is_trim(ob.data); skip=set()
    if any(tr):
        for p in ob.data.polygons:
            if tr[p.index]: skip.update(p.loop_indices)
    for i,(u,v) in enumerate(src):
        if i in skip: continue
        uv[i].uv=((x+u*w)/N_, 1-((y+(1-v)*h)/N_))
def src_mat():
    nm='props_bake_src2'
    if nm in bpy.data.materials: return bpy.data.materials[nm]
    m=bpy.data.materials.new(nm); m.use_nodes=True; nt=m.node_tree; N=nt.nodes; L=nt.links; bs=N['Principled BSDF']
    def img(p,cs):
        n=N.new('ShaderNodeTexImage'); n.image=bpy.data.images.load(p,check_existing=True); n.image.colorspace_settings.name=cs; n.extension='EXTEND'; return n
    c=img(K+'/props/_bake_src/props_src_color_clean.png','sRGB'); c.name='src_color'; L.new(c.outputs['Color'],bs.inputs['Base Color'])
    nn=img(K+'/props/_bake_src/props_src_normal.png','Non-Color'); nm_=N.new('ShaderNodeNormalMap'); L.new(nn.outputs['Color'],nm_.inputs['Color']); L.new(nm_.outputs['Normal'],bs.inputs['Normal'])
    o=img(K+'/props/_bake_src/props_src_orm.png','Non-Color'); sp=N.new('ShaderNodeSeparateColor'); L.new(o.outputs['Color'],sp.inputs[0])
    L.new(sp.outputs[1],bs.inputs['Roughness']); L.new(sp.outputs[2],bs.inputs['Metallic'])
    em=N.new('ShaderNodeEmission'); em.name='metal_emit'; L.new(sp.outputs[2],em.inputs['Color'])
    em2=N.new('ShaderNodeEmission'); em2.name='rough_emit'; L.new(sp.outputs[1],em2.inputs['Color'])
    geo=N.new('ShaderNodeNewGeometry'); sx=N.new('ShaderNodeSeparateXYZ'); L.new(geo.outputs['Position'],sx.inputs[0])
    sn=N.new('ShaderNodeSeparateXYZ'); L.new(geo.outputs['Normal'],sn.inputs[0])
    cmb=N.new('ShaderNodeCombineXYZ'); L.new(sx.outputs['Z'],cmb.inputs['X']); L.new(sn.outputs['Z'],cmb.inputs['Y'])
    em3=N.new('ShaderNodeEmission'); em3.name='geo_emit'; L.new(cmb.outputs[0],em3.inputs['Color'])
    em4=N.new('ShaderNodeEmission'); em4.name='albedo_emit'; L.new(c.outputs['Color'],em4.inputs['Color'])   # albedo incl. metals (DIFFUSE bakes metal as black)
    return m
def _bake(low, high, img, btype, **kw):
    sc=bpy.context.scene
    mat=low.data.materials[0]; nt=mat.node_tree
    tn=nt.nodes.get('bake_target') or nt.nodes.new('ShaderNodeTexImage'); tn.name='bake_target'; tn.image=img
    nt.nodes.active=tn
    for o in sc.objects: o.select_set(False)
    high.select_set(True); low.select_set(True); bpy.context.view_layer.objects.active=low
    b=sc.render.bake; b.use_selected_to_active=True; b.cage_extrusion=kw.get('cage',float(os.environ.get('BAKE_CAGE','0.015'))); b.max_ray_distance=kw.get('ray',float(os.environ.get('BAKE_RAY','0.06')))
    b.margin=kw.get('margin',6); b.margin_type='EXTEND'; b.target='IMAGE_TEXTURES'
    if btype=='DIFFUSE': b.use_pass_direct=False; b.use_pass_indirect=False; b.use_pass_color=True
    bpy.ops.object.bake(type=btype, pass_filter={'COLOR'} if btype=='DIFFUSE' else set(), use_selected_to_active=True,
                        cage_extrusion=b.cage_extrusion, max_ray_distance=b.max_ray_distance, margin=b.margin)
def _emit_switch(high, which):
    m=high.data.materials[0]; nt=m.node_tree; out=nt.nodes['Material Output']
    src=nt.nodes['Principled BSDF'] if which is None else nt.nodes[which]
    nt.links.new(src.outputs[0],out.inputs['Surface'])
def _novis(o):
    # the bake target must not occlude the high-poly's AO rays (coplanar low faces darkened one triangle of big flat walls)
    for a in ('visible_diffuse','visible_glossy','visible_transmission','visible_volume_scatter','visible_shadow'):
        if hasattr(o,a): setattr(o,a,False)
def _keep_proxy(low):
    """bake only on the source copy of mirror / repeat-shared faces: their UVs overlap the source texels, and letting the
    copies bake too overwrote the shared texels with whatever the copy's rays hit (diagonal artefacts on walls)"""
    import bmesh
    me=low.data
    if 'sym' not in me.attributes: return low
    sy=me.attributes['sym'].data; drop=[]; trf=is_trim(me)
    for i,p in enumerate(me.polygons):
        v=sy[i].value
        if trf[i]: drop.append(i); continue
        if (v==MIRROR and p.center.x>1e-4 and not _span(me,p,0)) or (v==MIRROR_Y and p.center.y>1e-4 and not _span(me,p,1)) or (v>=REP_BASE and _repk(me,p,v)!=0) or (1<v<MIRROR_Y and rot_sector(v,p.center)!=0): drop.append(i)
    if not drop: return low
    px=low.copy(); px.data=me.copy(); bpy.context.scene.collection.objects.link(px)
    bm=bmesh.new(); bm.from_mesh(px.data); bm.faces.ensure_lookup_table(); ds=set(drop)
    bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.index in ds],context='FACES_ONLY'); bm.to_mesh(px.data); bm.free()
    low.hide_render=True
    _novis(px)
    return px
def bake_prop(name, low, high, keys_high, side, conds=3, ground=True, wall_y=None, dirt_ao=(0.0,0.35,0.6), wear=1.0):
    """bake normal / AO / roughness / metal once and colour per condition from high-poly onto low-poly unique UVs.
    Writes tiles; returns slot rects."""
    import numpy as np
    sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=64; sc.cycles.device='CPU'
    helpers=[]
    if ground:
        bpy.ops.mesh.primitive_plane_add(size=6,location=(0,0,-0.0005)); helpers.append(bpy.context.active_object)
    if wall_y is not None:
        bpy.ops.mesh.primitive_plane_add(size=6,location=(0,wall_y+0.0005,1.5),rotation=(math.pi/2,0,0)); helpers.append(bpy.context.active_object)
    m=src_mat(); high.data.materials.clear(); high.data.materials.append(m)
    bm_=bpy.data.materials.get('bake_low') or bpy.data.materials.new('bake_low'); bm_.use_nodes=True
    low.data.materials.clear(); low.data.materials.append(bm_)
    _lp=_keep_proxy(low)
    if _lp is not low: helpers.append(_lp); low=_lp
    else: _novis(low)
    def newimg(nm,cs):
        im=bpy.data.images.get(nm)
        if im: bpy.data.images.remove(im)
        im=bpy.data.images.new(nm,side,side,alpha=False,float_buffer=(cs=='Non-Color')); im.colorspace_settings.name=cs; return im
    def arr(im): return np.array(im.pixels[:],dtype=np.float32).reshape(side,side,4)[::-1,:,:3]
    def save(a,path):
        h_,w_=a.shape[:2]; im=bpy.data.images.new('tmp_save',w_,h_,alpha=True)
        im.colorspace_settings.name='Non-Color'
        rgba=np.ones((h_,w_,4),np.float32); rgba[...,:3]=np.clip(a,0,1)
        im.pixels.foreach_set(rgba[::-1].ravel()); im.filepath_raw=path; im.file_format='PNG'; im.save()
        bpy.data.images.remove(im)
    # normal
    pg_apply_high(high,keys_high,'clean'); _emit_switch(high,None)
    im=newimg('bk_n','Non-Color'); _bake(low,high,im,'NORMAL'); N_=arr(im)
    im=newimg('bk_ao','Non-Color'); sc.cycles.samples=96; _bake(low,high,im,'AO'); AO=arr(im)[...,0:1]; sc.cycles.samples=16
    _emit_switch(high,'rough_emit'); im=newimg('bk_r','Non-Color'); _bake(low,high,im,'EMIT'); R_=arr(im)[...,0:1]
    _emit_switch(high,'metal_emit'); im=newimg('bk_m','Non-Color'); _bake(low,high,im,'EMIT'); M_=arr(im)[...,0:1]
    _emit_switch(high,'geo_emit'); im=newimg('bk_g','Non-Color'); _bake(low,high,im,'EMIT'); G_=arr(im)
    _emit_switch(high,None)
    Z=G_[...,0:1]; UP=G_[...,1:2]
    hz=np.clip(1-Z/0.45,0,1)**1.5                      # near the ground
    nts=N_*2-1; edge=np.clip((1-np.clip(nts[...,2:3],0,1))*5,0,1)   # bevels / convex edges (from baked normal)
    cav=np.clip((1-AO)*2.2,0,1)                         # recesses
    top=np.clip(UP,0,1)**2                              # up-facing (dust)
    save(N_,f'{BAKE_DIR}/tiles/{name}_nor.png')
    save(np.concatenate([AO,R_,M_],axis=2),f'{BAKE_DIR}/tiles/{name}_orm.png')
    DIRT=np.array([.34,.29,.22],np.float32)
    cols=[]
    for ci,cond in enumerate(['clean','worn','dirty'][:conds]):
        pg_apply_high(high,keys_high,cond)
        cn=high.data.materials[0].node_tree.nodes['src_color']; cn.image=bpy.data.images.load(K+f'/props/_bake_src/props_src_color_{cond}.png',check_existing=True)
        _emit_switch(high,'albedo_emit'); im=newimg('bk_c','Non-Color'); _bake(low,high,im,'EMIT'); _emit_switch(high,None)
        lin=np.clip(np.array(im.pixels[:],dtype=np.float32).reshape(side,side,4)[::-1,:,:3],0,1)
        cols.append(np.where(lin<=0.0031308,lin*12.92,1.055*lin**(1/2.4)-0.055))   # emit bake is linear -> sRGB
    C0=cols[0]
    for ci,C in enumerate(cols):
        cond=['clean','worn','dirty'][ci]
        if ci==1:   # wear concentrates on edges, recesses, low parts; flat upper faces keep paint (but faded)
            w_=np.clip(0.55+0.9*edge+0.6*cav+0.7*hz,0,1); C=C0*0.15+C*0.85; C=C0+(C-C0)*w_
            C=C*(1-0.25*hz*0.6*wear)+DIRT*0.25*hz*0.6*wear
        if ci==2:
            w_=np.clip(0.50+1.2*hz+0.9*edge+0.7*cav,0,1)
            fade=cols[1]*0.6+C0*0.4 if len(cols)>1 else C0
            C=fade+(C-fade)*w_
            C=C*(1-0.38*hz*wear)+DIRT*0.38*hz*wear               # dirt splash at the base
            C=C*(1-0.20*top)+np.array([.62,.58,.50])*0.20*top   # dust/salt on tops
        if WX is not None and ci==0:   # waterfront weathering baked into the shipped clean colour (WF set)
            rs=np.random.default_rng(__import__("zlib").crc32(name.encode()))
            def _nz(sc):
                n_=max(2,side//sc); g=rs.random((n_+1,n_+1)).astype(np.float32)
                t=np.linspace(0,n_,side,endpoint=False); i0=t.astype(int); f=(t-i0)[:,None]; fx=(t-i0)[None,:]
                a=g[i0][:,i0]; b_=g[i0][:,i0+1]; c_=g[i0+1][:,i0]; d_=g[i0+1][:,i0+1]
                return ((a*(1-fx)+b_*fx)*(1-f)+(c_*(1-fx)+d_*fx)*f)[...,None]
            n1=_nz(4); n2=_nz(16); sp=(rs.random((side,side,1))>0.985).astype(np.float32)
            wl=WX.get('water',None)
            if wl is not None:
                dz=Z-wl
                sub=np.clip(-dz/0.25,0,1); band=np.exp(-((dz+0.15)/0.35)**2)
                C=C*(1-0.35*sub)+np.array([.16,.19,.13])*0.35*sub                          # wet, dark below the line
                alg=np.clip(band*(0.55+0.6*n2[...,0:1]),0,1)*WX.get('algae',0.6)
                C=C*(1-alg)+np.array([.20,.27,.12])*alg                                     # green-brown algae band
                bar=np.clip(band*1.2,0,1)*np.clip((n1-0.62)*4,0,1)*WX.get('barnacle',0.6)
                C=C*(1-bar)+np.array([.78,.76,.68])*bar                                    # barnacle speckle
            salt=np.clip(top*0.6+edge*0.25,0,1)*np.clip(n2*1.3-0.25,0,1)*WX.get('salt',0.35)
            C=C*(1-salt)+np.array([.86,.85,.80])*salt                                       # salt bloom on tops and arrises
            ew=np.clip(edge*1.4-0.2,0,1)*np.clip(n1*1.6-0.4,0,1)*WX.get('edge',0.30)
            C=C*(1-ew)+np.clip(C*1.35+0.05,0,1)*ew                                         # worn arrises
            st=np.clip(n2*1.4-0.6,0,1)*np.clip(1-UP,0,1)*WX.get('streak',0.20)
            C=C*(1-0.5*st)                                                                   # weather streaking on verticals
            C=C*(1-0.25*sp*WX.get('pit',0.5))
        k=dirt_ao[ci]*wear; C=C*(1-k*cav)+DIRT*k*cav       # grime in recesses
        mf=np.clip(M_,0,1); C=C*((0.40+0.60*AO)*(1-mf)+(0.72+0.28*AO)*mf)   # AO baked into base colour (spec); bare metal keeps its brightness (its look is mostly reflection)
        save(C,f'{BAKE_DIR}/tiles/{name}_{cond}_col.png')
    for h in helpers: bpy.data.objects.remove(h,do_unlink=True)
    for o in bpy.context.scene.objects:
        if o.name.endswith(('_near','_mid','_far')):
            o.hide_render=False
            for a in ('visible_diffuse','visible_glossy','visible_transmission','visible_volume_scatter','visible_shadow'):
                if hasattr(o,a): setattr(o,a,True)
def pg_apply_high(high, keys, cond):
    me=high.data; uv=me.uv_layers['UVMap'].data; rk=me.attributes['reg'].data
    for p in me.polygons:
        key=keys[rk[p.index].value]; rname=f'{key}.{cond}' if f'{key}.{cond}' in REG else f'{key}.clean'
        u0,v0,u1,v1=REG[rname]['uv']
        for li in p.loop_indices:
            nu,nv=STORE[high.name][li]; uv[li].uv=(u0+nu*(u1-u0), 1-(v0+(1-nv)*(v1-v0)))

def add_text(b, text, size, origin, xdir, ydir, depth, key, font=None, res=3, back=True, simplify=0, sides=True):
    """raised cast lettering: real glyph geometry (Blender font curve -> mesh), placed on a plane"""
    cu=bpy.data.curves.new('txt','FONT'); cu.body=text; cu.size=size; cu.extrude=depth/2; cu.align_x='CENTER'; cu.align_y='CENTER'
    cu.font=bpy.data.fonts.load(font or '/usr/share/fonts/truetype/sand-box/google/Barlow Condensed/BarlowCondensed-Bold.ttf',check_existing=True)
    cu.resolution_u=res
    ob=bpy.data.objects.new('txt',cu); bpy.context.scene.collection.objects.link(ob)
    dg=bpy.context.evaluated_depsgraph_get(); me=ob.evaluated_get(dg).to_mesh()
    o=Vector(origin); X=Vector(xdir).normalized(); Y=Vector(ydir).normalized(); Z=X.cross(Y)
    vs=[o+X*v.co.x+Y*v.co.y+Z*(v.co.z+depth/2) for v in me.vertices]
    if simplify:
        import bmesh as _bm
        bm=_bm.new(); bm.from_mesh(me)
        _bm.ops.remove_doubles(bm,verts=bm.verts,dist=1e-5)
        if not back: _bm.ops.delete(bm,geom=[f for f in bm.faces if f.normal.z<-0.5],context='FACES')
        _bm.ops.dissolve_limit(bm,angle_limit=math.radians(simplify),verts=bm.verts,edges=bm.edges)
        _bm.ops.triangulate(bm,faces=bm.faces)
        me2=bpy.data.meshes.new('t2'); bm.to_mesh(me2); bm.free()
        vs=[o+X*v.co.x+Y*v.co.y+Z*(v.co.z+depth/2) for v in me2.vertices]
        polys=[tuple(p.vertices) for p in me2.polygons]
        bpy.data.meshes.remove(me2)
    else: polys=[tuple(p.vertices) for p in me.polygons if (back or p.normal.z>-0.5) and (sides or abs(p.normal.z)>0.5)]
    luv=[[( (vs[i]-o).dot(X),(vs[i]-o).dot(Y)) for i in p] for p in polys]
    b.faces(vs,polys,key,luv)
    ob.evaluated_get(dg).to_mesh_clear(); bpy.data.objects.remove(ob,do_unlink=True); bpy.data.curves.remove(cu)
REP_BASE=100000
MIRROR_Y=99998 # face tag: front/back (y) mirror-shared (symmetric walls)
MIRROR=99999   # face tag: mirror-shared across x=0 (never on lettering/decals)
def rep(step_m, i):
    """face tag: instance i of an element repeated every step_m along X (shares instance-0 texels)"""
    return int(round(step_m*1000))*REP_BASE+i
def repy(step_m, i):
    """face tag: rep(step_m,i) AND front/back (y) mirror-shared: long faces tile along X and share both sides"""
    return rep(step_m,i)+200
def repY(step_m, i, mirror_x=False):
    """face tag: instance i of an element repeated every step_m along Y (optionally also mirror-shared across x=0)"""
    return rep(step_m,i)+(600 if mirror_x else 400)
def _repk(me,p,v):
    """sector index of a rep face (0 = the texel source): instance + 1000 if on the mirrored side"""
    r=v%REP_BASE; k=r%200; fl=r//200
    if fl==1 and p.center.y>1e-4 and not _span(me,p,1): k+=1000
    if fl==3 and p.center.x>1e-4 and not _span(me,p,0): k+=1000
    return k
def _tagbase(v): return v-(v%REP_BASE)%200 if v>=REP_BASE else v
def _span(me,p,ax):
    """face straddles the mirror plane (perpendicular end caps, tops): it is its own mirror -> keep it unique"""
    cs=[me.vertices[v].co[ax] for v in p.vertices]; return min(cs)<-1e-4 and max(cs)>1e-4
ROT_PHASE=0.0037   # sector boundaries sit just off the +X axis so faces centred on a symmetry line never straddle two sectors
def rot_sector(n, c):
    a=(math.atan2(c.y,c.x)-ROT_PHASE)%(2*math.pi); return int(a/(2*math.pi/n))%n
def unique_uv_sym(ob, side, margin_px=4):
    """unique unwrap, but faces tagged with rotational symmetry n>1 share the UVs of their sector-0 copy
    (bolted flanges, ribbed dome): saves atlas space so the hero prop can reach high texel density"""
    import bmesh
    me=ob.data; sy=me.attributes['sym'].data
    cen=[p.center.copy() for p in me.polygons]
    def sector(i):
        n=sy[i].value
        if n==MIRROR: return 1 if (cen[i].x>1e-4 and not _span(me,me.polygons[i],0)) else 0   # bilateral mirror across x=0
        if n==MIRROR_Y: return 1 if (cen[i].y>1e-4 and not _span(me,me.polygons[i],1)) else 0
        if n>=REP_BASE: return _repk(me,me.polygons[i],n)      # translational repeat (fence pickets, rails): instance index
        if n<=1: return 0
        return rot_sector(n,cen[i])
    trf=is_trim(me)
    keep=[i for i in range(len(me.polygons)) if sector(i)==0 and not trf[i]]
    if not keep:
        return  # all-trim mesh: nothing to unwrap into a bake slot
    prox=ob.copy(); prox.data=me.copy(); bpy.context.scene.collection.objects.link(prox)
    bm=bmesh.new(); bm.from_mesh(prox.data); bm.faces.ensure_lookup_table()
    ks=set(keep); bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.index not in ks],context='FACES_ONLY'); bm.to_mesh(prox.data); bm.free()
    unique_uv(prox,margin_px,side)
    puv=prox.data.uv_layers.active.data
    # map proxy faces (same order as 'keep') back
    uv=me.uv_layers.active.data; pmap={}
    for pi,oi in enumerate(keep):
        pp=prox.data.polygons[pi]; op=me.polygons[oi]
        for a,b_ in zip(pp.loop_indices,op.loop_indices): uv[b_].uv=puv[a].uv
        pmap[oi]=pp
    from mathutils.kdtree import KDTree
    kd=KDTree(len(keep))
    for j,oi in enumerate(keep): kd.insert(cen[oi],j)
    kd.balance()
    for i,p in enumerate(me.polygons):
        k=sector(i)
        if k==0 or trf[i]: continue
        n=sy[i].value
        if n==MIRROR:
            X=lambda co: Vector((-co.x,co.y,co.z))
        elif n==MIRROR_Y:
            X=lambda co: Vector((co.x,-co.y,co.z))
        elif n>=REP_BASE:
            fl=(n%REP_BASE)//200; d_=(k%1000)*(n//REP_BASE)/1000.0; fm=-1.0 if k>=1000 else 1.0
            off=Vector((d_,0,0)) if fl<2 else Vector((0,d_,0))
            if fl==3: X=lambda co,off=off,fm=fm: Vector(((co-off).x*fm,(co-off).y,co.z))
            else: X=lambda co,off=off,fm=fm: Vector(((co-off).x,(co-off).y*fm,co.z))
        else:
            R=Matrix.Rotation(-k*2*math.pi/n,3,'Z'); X=lambda co,R=R: R@co
        RY=n>=REP_BASE and (n%REP_BASE)//200 in (1,3)
        if n in (MIRROR,MIRROR_Y) or 1<n<MIRROR_Y or RY:
            # mirrored triangulation differs from the source side: map each loop by barycentric lookup in the
            # coplanar source face that contains the mirrored point (nearest-vertex snapping stretched diagonals)
            mn_=X(p.normal); mn_=Vector((mn_.x,mn_.y,mn_.z)) if n==MIRROR else Vector((p.normal.x,-p.normal.y,p.normal.z))
            if n==MIRROR: mn_=Vector((-p.normal.x,p.normal.y,p.normal.z))
            if 1<n<MIRROR_Y: mn_=X(p.normal)   # rotated copy (triangulation can differ per sector too)
            if RY: f_=-1.0 if k>=1000 else 1.0; mn_=Vector((p.normal.x,p.normal.y*f_,p.normal.z)) if (n%REP_BASE)//200==1 else Vector((p.normal.x*f_,p.normal.y,p.normal.z))
            cands=[keep[j] for (_,j,_) in kd.find_n(X(cen[i]),24)]
            cands=[c for c in cands if me.polygons[c].normal.dot(mn_)>0.95] or [keep[kd.find(X(cen[i]))[1]]]
            for li in p.loop_indices:
                vp=X(me.vertices[me.loops[li].vertex_index].co); best=None
                for c in cands:
                    op=me.polygons[c]; L_=list(op.loop_indices)
                    for t in range(1,len(L_)-1):
                        tri=[L_[0],L_[t],L_[t+1]]; A,B,C=[me.vertices[me.loops[l].vertex_index].co for l in tri]
                        v0=B-A; v1=C-A; v2=vp-A; d00=v0.dot(v0); d01=v0.dot(v1); d11=v1.dot(v1); d20=v2.dot(v0); d21=v2.dot(v1)
                        den=d00*d11-d01*d01
                        if abs(den)<1e-14: continue
                        bv=(d11*d20-d01*d21)/den; bw=(d00*d21-d01*d20)/den; bu=1-bv-bw
                        out=max(0,-bu)+max(0,-bv)+max(0,-bw)+abs(op.normal.dot(vp-A))
                        if _tagbase(sy[c].value)!=_tagbase(n): out+=0.02   # tie-break: a vertex on a shared edge belongs to the same-tag source island
                        if best is None or out<best[0]: best=(out,tri,(bu,bv,bw))
                if best:
                    tri,(bu,bv,bw)=best[1],best[2]; bu,bv,bw=max(bu,0.0),max(bv,0.0),max(bw,0.0); sm=bu+bv+bw or 1.0; bu,bv,bw=bu/sm,bv/sm,bw/sm   # clamp: never extrapolate outside the source island
                    uv[li].uv=uv[tri[0]].uv*bu+uv[tri[1]].uv*bv+uv[tri[2]].uv*bw
            continue
        co,j,d=kd.find(X(cen[i])); oi=keep[j]; op=me.polygons[oi]
        for li in p.loop_indices:
            vp=X(me.vertices[me.loops[li].vertex_index].co)
            best=min(op.loop_indices,key=lambda l2:(me.vertices[me.loops[l2].vertex_index].co-vp).length)
            uv[li].uv=uv[best].uv
    bpy.data.objects.remove(prox,do_unlink=True)
def unique_area(ob):
    sy=ob.data.attributes['sym'].data; trf=is_trim(ob.data)
    tot=0.0
    for i,p in enumerate(ob.data.polygons):
        if trf[i]: continue
        v=sy[i].value
        if v==MIRROR: tot+=p.area if (p.center.x<=1e-4 or _span(ob.data,p,0)) else 0.0
        elif v==MIRROR_Y: tot+=p.area if (p.center.y<=1e-4 or _span(ob.data,p,1)) else 0.0
        elif v>=REP_BASE: tot+=p.area if _repk(ob.data,p,v)==0 else 0.0
        else: tot+=p.area/max(1,v)
    return tot
def transfer_uv(src, dst, maxd=0.12, mode="face"):
    """mid / far tiers that reuse the near tier's baked tile (real-scale masonry instead of a stretched region):
    each dst face takes the affine UV map of the coplanar near-tier face under its centre, clamped to that near
    face's planar island (parts hidden behind other masses just smear the island edge)"""
    from mathutils.bvhtree import BVHTree
    from mathutils.geometry import barycentric_transform
    sm=src.data; _st=is_trim(sm); _keep=[p.index for p in sm.polygons if not _st[p.index]]   # trim / decal faces are not transfer sources
    tv=BVHTree.FromPolygons([v.co for v in sm.vertices],[sm.polygons[i].vertices for i in _keep])
    _rc=tv.ray_cast
    def _ray(o,d,dist):
        loc,nor,fi,dd=_rc(o,d,dist); return loc,nor,(_keep[fi] if fi is not None else None),dd
    suv=sm.uv_layers.active.data; duv=dst.data.uv_layers.active.data; dm=dst.data; miss=0
    vf={}
    for p in sm.polygons:
        if _st[p.index]: continue
        for v in p.vertices: vf.setdefault(v,[]).append(p.index)
    def island(fi):
        p0=sm.polygons[fi]; n0=p0.normal; d0=n0.dot(p0.center); seen={fi}; st=[fi]
        while st:
            f=st.pop()
            for v in sm.polygons[f].vertices:
                for g in vf[v]:
                    if g in seen: continue
                    q=sm.polygons[g]
                    if q.normal.dot(n0)>0.999 and abs(q.center.dot(n0)-d0)<1e-3: seen.add(g); st.append(g)
        us=[suv[l].uv for f in seen for l in sm.polygons[f].loop_indices]
        return min(u.x for u in us),max(u.x for u in us),min(u.y for u in us),max(u.y for u in us)
    if mode=='vertex':   # per corner (nudged into its face): mid tiers that follow repeated near features (corrugation)
        dtr=is_trim(dm)
        for p in dm.polygons:
            if dtr[p.index]: continue
            c=p.center; n=p.normal
            for li in p.loop_indices:
                v=dm.vertices[dm.loops[li].vertex_index].co; q=v+(c-v)*0.04; hit=None
                for off in (0.004,0.03,maxd):
                    loc,nor,fi,d=_ray(q+n*off,-n,off+0.08)
                    if fi is not None and nor.dot(n)>0.45: hit=fi; break
                if hit is None: miss+=1; continue
                sp=sm.polygons[hit]; L=list(sp.loop_indices)
                A,B,C=[sm.vertices[sm.loops[l].vertex_index].co for l in L[:3]]
                ua,ub,uc=[Vector((suv[l].uv.x,suv[l].uv.y,0)) for l in L[:3]]
                r=barycentric_transform(loc,A,B,C,ua,ub,uc); duv[li].uv=(r.x,r.y)
        return miss
    dtr=is_trim(dm)
    for p in dm.polygons:
        if dtr[p.index]: continue
        c=p.center; n=p.normal; hit=None
        for off in (0.002,0.03,maxd):
            loc,nor,fi,d=_ray(c+n*off,-n,off+0.06)
            if fi is not None and nor.dot(n)>0.9: hit=fi; break
        if hit is None: miss+=1; continue
        sp=sm.polygons[hit]; L=list(sp.loop_indices); x0,x1,y0,y1=island(hit)
        A,B,C=[sm.vertices[sm.loops[l].vertex_index].co for l in L[:3]]
        ua,ub,uc=[Vector((suv[l].uv.x,suv[l].uv.y,0)) for l in L[:3]]
        for li in p.loop_indices:
            v=dm.vertices[dm.loops[li].vertex_index].co
            vp=v-sp.normal*(v-A).dot(sp.normal)
            r=barycentric_transform(vp,A,B,C,ua,ub,uc); duv[li].uv=(min(max(r.x,x0),x1),min(max(r.y,y0),y1))
    return miss
