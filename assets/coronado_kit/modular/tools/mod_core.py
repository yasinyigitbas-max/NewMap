"""Modular starter kit core: a piece is a Building whose faces on its snap planes are dropped (open ends / open back /
open top), so pieces butt together on the grid with no hidden or coincident faces. City atlas (houses + storefronts in one
material)."""
import os, sys, numpy as np
os.environ.setdefault('KIT_ATLAS','house')   # houses: house atlas (bld_*); storefronts: city atlas (make_modular sets it per group)
KIT=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0,KIT+'/tools')
from build import Building
from geom import clip
import city_parts   # noqa: attaches shared parts

GRID=0.5          # sub-grid (m)
MOD=3.0           # house wall module (m)
SHOP=6.0          # storefront bay module (m)
FL=0.5            # house floor / foundation height
HW=FL+3.0         # house plate (eave) height
T_H=0.30          # house wall slab depth
GF=3.8; SW=GF+0.4; PAR=0.9   # shop ground storey, shop plate height, parapet
T_S=0.60          # shop front slab depth (recessed door 0.45)

class Piece(Building):
    """drop: list of (axis, value, sign) planes; a face whose normal == sign*axis and which lies on the plane is dropped.
    keep_y: (lo,hi) optional clip of faces on a dropped soffit. base_y: snap height of the piece (0 for walls)."""
    def __init__(s,name,cls,snap,drop,budget,**kw):
        super().__init__(name,'mod',**kw)
        s.cls=cls; s.snap=snap; s.drop=drop; s.mbudget=budget; s.budget='shop'; s.storeys=1; s.floor=0.0
        s.clip_soffit=None; s.base_y=0.0; s.no_door=True; s.extra_drop=[]; s.hidden=None   # hidden(face,centre)->True drops it
    def build(s,tier):
        faces,sol=Building.build(s,tier)
        out=[]
        # details stopped 2 mm short of an abutting end (gutters, copings) are snapped onto the snap plane, so their end
        # caps land on it and are dropped like every other face there
        for f in faces:
            for dd in s.drop:
                ax,val=dd[0],dd[1]
                if ax!=0: continue
                f.pts=[np.array([val,p[1],p[2]]) if abs(p[0]-val)<0.0031 else p for p in f.pts]
        for f in faces:
            c=np.mean(f.pts,axis=0); kill=False
            for dd in s.drop+s.extra_drop:
                ax,val,sg=dd[:3]; ymax=dd[3] if len(dd)>3 else 1e9
                e=np.zeros(3); e[ax]=sg
                if np.dot(f.n,e)>0.999 and abs(c[ax]-val)<2e-3 and all(abs(p[ax]-val)<2e-3 for p in f.pts) and max(p[1] for p in f.pts)<=ymax+2e-3: kill=True; break
            if not kill and s.hidden is not None and s.hidden(f,c): kill=True
            if not kill and s.clip_soffit and f.n[1]<-0.999:
                # roof underside: keep only the eave overhang strips outside the wall line
                y,zf,zb=s.clip_soffit
                if abs(c[1]-y)<2e-3:
                    a=clip(f.pts,np.array([0,0,-1.0]),-zf)    # z>=zf
                    b=clip(f.pts,np.array([0,0,1.0]),zb)      # z<=zb
                    for q in (a,b):
                        if len(q)>=3: out.append(f.copy(np.array(q)))
                    continue
            if not kill: out.append(f)
        if tier=='near': s._fix_sloped_bands(out)
        if getattr(s,'roof_cut',None) and tier!='far': out=s._clip_above_roof(out)
        return out,sol

    def _clip_above_roof(s,faces):
        """keep only the parts of the faces above a symmetric gable roof surface y = ridge - pitch*|z| (a chimney whose
        foot is buried in the roof): nothing is left inside the attic"""
        rid,pt=s.roof_cut; out=[]
        for f in faces:
            for sg in (1,-1):
                q=clip(f.pts,np.array([0,0,-sg*1.0]),0.0)                       # sg*z >= 0
                if len(q)<3: continue
                q=clip(q,np.array([0,-1.0,-sg*pt]),-rid)                       # y >= rid - pt*sg*z
                if len(q)>=3:
                    A=np.array(q); cr=np.cross(A[1]-A[0],A[2]-A[0])
                    area=0.5*np.linalg.norm(sum(np.cross(A[i],A[(i+1)%len(A)]) for i in range(len(A))))
                    if area>1e-6: out.append(f.copy(A))
        return out

    def _fix_sloped_bands(s,faces):
        """clay barrel-end 'band' strips are mapped with v across the face height: right for the level eave fascia, but on
        the sloped rake fascia of a gable end the 64 px tile row smears into diagonal streaks (and the clay row can only
        wrap along u, so it cannot be laid along the slope). Sloped band faces become a terracotta barge strip
        (T_terracotta stretch trim, u along the slope), like a mortared barge-tile edge."""
        from geom import trim_face
        out=[]
        for f in faces:
            if f.kind=='band' and len(f.pts)>=3:
                P=np.array(f.pts,float); E=[P[(i+1)%len(P)]-P[i] for i in range(len(P))]
                e=max(E,key=lambda v:np.linalg.norm(v)); e=e/np.linalg.norm(e)
                if abs(e[1])>=0.05:
                    out+=trim_face([np.array(p) for p in f.pts],f.n,'T_terracotta',(1,1,1),f.sid,'trim'); continue
            out.append(f)
        faces[:]=out

    abuts_all=False; abut_sides=None
    def _abuts(s,x0,x1,z0,z1,eps=0.05):
        if s.abut_sides is not None: return set(s.abut_sides)
        if s.abuts_all: return {'left','right'}
        return Building._abuts(s,x0,x1,z0,z1,eps)
    origin=None
    def footprint_center(s):
        if s.origin is not None:
            cx,cz,w,d=s.origin; return np.array([cx,0,cz]),(w,d)
        return Building.footprint_center(s)
