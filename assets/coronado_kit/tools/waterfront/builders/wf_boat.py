"""Boat building helpers (waterfront set 4). Builder coords: Z up, bow towards -Y (front), beam along X, origin = keel bottom centre.
A hull is lofted from stations t in [0 (stem), 1 (transom)] with per-station sections (starboard half, keel -> sheer) that always
carry explicit points at the designed waterline and the boot-top line, so the antifouling / boot stripe / topsides split is exact
(each band is its own key -> its own page-W trim tile + tint)."""
import math
from mathutils import Vector
import wf_parts as P
V=Vector
def lerp(a,b,t): return a+(b-a)*t
def taper(t,te=0.05): return min(1.0,max(0.0,t/te))   # lateral offsets fade to 0 at the stem so trims mitre on the stem line
def face(b,pts,key,out=None,smooth=False):
    """n-gon with outward hint; metre UVs from a planar basis (u horizontal in the face plane)"""
    pts=[V(p) for p in pts]; n=V((0,0,0))
    for i in range(len(pts)): n+=pts[i].cross(pts[(i+1)%len(pts)])
    if n.length<1e-10: return
    if out is not None and n.dot(V(out))<0: pts=pts[::-1]; n=-n
    n.normalize(); u=n.cross(V((0,0,1)))
    if u.length<1e-4: u=V((0,1,0))
    u.normalize(); v=n.cross(u)
    b.faces(pts,[tuple(range(len(pts)))],key,[[(p.dot(u),p.dot(v)) for p in pts]],smooth=smooth)
class Hull:
    """L: length; y runs bow (-L/2) -> stern (+L/2). fns: hs(t) sheer half-beam, hw(t) waterline half-beam, zs(t) sheer z,
    zk(t) keel (canoe body) z, chine=(hc(t),zc(t)) for hard-chine hulls (else round bilge). WL, boot: waterline z and boot height."""
    def __init__(s,L,hs,hw,zs,zk,WL,boot=0.09,chine=None,flare=0.0,keys=('paint_red','paint_navy','paint_white'),y0=None,rake=None):
        s.L=L; s.hs=hs; s.hw=hw; s.zs=zs; s.zk=zk; s.WL=WL; s.boot=boot; s.chine=chine; s.flare=flare; s.keys=keys
        s.y0=-L/2 if y0 is None else y0; s.rake=rake   # rake=(R,t_end): raked stem, y shifts forward by R*(z-WL) fading out by t_end
    def y(s,t): return s.y0+s.L*t
    def yz(s,t,z):
        if not s.rake: return s.y(t)
        R,te=s.rake; return s.y(t)-R*max(0.0,z-s.WL)*max(0.0,1-t/te)**1.5
    def sec(s,t,lod='near'):
        hs,hw,zs,zk,WL=s.hs(t),s.hw(t),s.zs(t),s.zk(t),s.WL
        zb=WL+s.boot; zk=min(zk,WL-0.02)
        pts=[(0.0,zk)]
        if s.chine:
            hc,zc=s.chine[0](t),s.chine[1](t); zc=min(max(zc,zk+0.01),WL-0.01)
            if lod!='mid': pts.append((hc*0.5,lerp(zk,zc,0.62)))
            pts.append((hc,zc))
        elif lod=='mid': pts.append((hw*0.82,lerp(zk,WL,0.55)))
        else: pts+= [(hw*0.55,lerp(zk,WL,0.22)),(hw*0.88,lerp(zk,WL,0.62))]
        pts+= [(hw,WL),(lerp(hw,hs,0.10),zb)]
        if lod!='mid': pts.append((lerp(hw,hs,0.62)+s.flare*hs,lerp(zb,zs,0.55)))
        band=getattr(s,'band',0.0)
        if band and lod!='mid':   # extra edge loop just under the sheer, ON the existing topside line (no shape change): keeps the
            xp,zp=pts[-1]          # rub-rail AO confined to a thin band instead of smearing down long triangles as wedges
            if zs-band>zp+0.02: f=(zs-band-zp)/(zs-zp); pts.append((lerp(xp,hs,f),zs-band))
        pts.append((hs,zs))
        if t<=1e-6: pts=[(0.0,z) for _,z in pts]   # stem line: port + starboard share these vertices (welded, closed bow)
        return pts
    def hsx(s,t): return 0.0 if t<=1e-6 else s.hs(t)
    def x_at(s,t,z):
        """half-breadth of the lofted section at station t, height z (0 on the stem line)"""
        pts=s.sec(t)
        for (xa,za),(xc,zc) in zip(pts[:-1],pts[1:]):
            if za<=z<=zc: return xa+(xc-xa)*(z-za)/max(zc-za,1e-9)
        return pts[-1][0]
    def surf(s,t,z,sx=1,off=0.0):
        """point on the hull skin (station t, height z), pushed `off` outward (tapering to 0 at the stem)"""
        T=getattr(s,'ts_built',None)
        if T and len(T)>1 and T[0]<=t<=T[-1]:   # on the faceted skin: interpolate between the two built stations around t
            i=next(k for k in range(len(T)-1) if T[k]<=t<=T[k+1]); a,c=T[i],T[i+1]; f=(t-a)/max(c-a,1e-9)
            x=s.x_at(a,z)*(1-f)+s.x_at(c,z)*f; y=s.yz(a,z)*(1-f)+s.yz(c,z)*f
        else: x=s.x_at(t,z); y=s.yz(t,z)
        return V((sx*(x+off*taper(t)),y,z))
    def key(s,zm):
        return s.keys[0] if zm<s.WL-1e-4 else (s.keys[1] if zm<s.WL+s.boot-1e-4 else s.keys[2])
    def build(s,b,ts,lod='near',transom=True,smooth=True):
        s.ts_built=list(ts); secs=[(t,s.sec(t,lod)) for t in ts]
        for sx in (1,-1):
            for i in range(len(secs)-1):
                (ta,A),(tc,C)=secs[i],secs[i+1]
                for j in range(len(A)-1):
                    p=[V((sx*A[j][0],s.yz(ta,A[j][1]),A[j][1])),V((sx*C[j][0],s.yz(tc,C[j][1]),C[j][1])),V((sx*C[j+1][0],s.yz(tc,C[j+1][1]),C[j+1][1])),V((sx*A[j+1][0],s.yz(ta,A[j+1][1]),A[j+1][1]))]
                    if (p[0]-p[3]).length<1e-5 and (p[1]-p[2]).length<1e-5: continue
                    zm=(A[j][1]+A[j+1][1]+C[j][1]+C[j+1][1])/4
                    c=sum(p,V())/4; zm=(s.zk(ts[i])+s.zs(ts[i]))/2
                    # outward hint: side sign (never the tiny |x| at the stem), forward near the bow, down/up about the mid-depth
                    out=V((sx,-0.6 if ts[i]<0.2 else 0.0,(c.z-zm)*1.5))
                    if (p[0]-p[3]).length<1e-5: p=[p[0],p[1],p[2]]
                    elif (p[1]-p[2]).length<1e-5: p=[p[0],p[1],p[3]]
                    face(b,p,s.key(zm),out,smooth=smooth)
        # stem cap: closes the narrow t=0 section (stem band) so the bow never shows the hull's open interior
        t0,A=secs[0]
        for j in range(len(A)-1):
            if A[j][0]<1e-4 and A[j+1][0]<1e-4: continue
            p=[V((-A[j][0],s.yz(t0,A[j][1]),A[j][1])),V((-A[j+1][0],s.yz(t0,A[j+1][1]),A[j+1][1])),V((A[j+1][0],s.yz(t0,A[j+1][1]),A[j+1][1])),V((A[j][0],s.yz(t0,A[j][1]),A[j][1]))]
            if A[j][0]<1e-4: p=[p[0],p[1],p[2]]
            face(b,p,s.key((A[j][1]+A[j+1][1])/2),(0,-1,0))
        if transom:
            y,A=s.y(secs[-1][0]),secs[-1][1]
            for j in range(len(A)-1):
                p=[V((A[j][0],y,A[j][1])),V((A[j+1][0],y,A[j+1][1])),V((-A[j+1][0],y,A[j+1][1])),V((-A[j][0],y,A[j][1]))]
                if A[j][0]<1e-4 and A[j+1][0]<1e-4: continue
                if A[j][0]<1e-4: p=p[:3]
                face(b,p,s.key((A[j][1]+A[j+1][1])/2),(0,1,0))
        return secs
    def sheer(s,t): return V((s.hsx(t),s.yz(t,s.zs(t)),s.zs(t)))
    def ys(s,t): return s.yz(t,s.zs(t))
def deck(b,H,ts,inner=None,key='stucco',camber=0.04,z_off=0.0):
    """deck between the sheers over stations ts; inner(t): half-width of an opening (cabin / cockpit) or None (full deck, cambered)"""
    for i in range(len(ts)-1):
        ta,tc=ts[i],ts[i+1]; za,zc=H.zs(ta)+z_off,H.zs(tc)+z_off; ya,yc=H.yz(ta,za),H.yz(tc,zc); ha,hc=H.hsx(ta),H.hsx(tc)
        if inner is None:
            pa=[V((-ha,ya,za)),V((0,ya,za+camber)),V((ha,ya,za))]; pc=[V((-hc,yc,zc)),V((0,yc,zc+camber)),V((hc,yc,zc))]
            for k in range(2): face(b,[pa[k],pc[k],pc[k+1],pa[k+1]],key,(0,0,1))
        else:
            ia,ic=min(inner(ta),ha-0.02),min(inner(tc),hc-0.02)
            for sx in (1,-1): face(b,[V((sx*ia,ya,za)),V((sx*ha,ya,za)),V((sx*hc,yc,zc)),V((sx*ic,yc,zc))],key,(0,0,1))
def sheer_strip(b,H,ts,key,h=0.04,off=0.0,dz=0.0,both=True):
    """strip standing on the sheer (toe rail / bulwark cap: dz>=0) or a stripe on the topsides below it (dz<0: follows the
    lofted skin at that height). Lateral offsets taper to 0 at the stem, so both sides meet (mitre) on the stem line."""
    for sx in ((1,-1) if both else (1,)):
        for i in range(len(ts)-1):
            ta,tc=ts[i],ts[i+1]
            if dz<0:
                za0,zc0=H.zs(ta)+dz,H.zs(tc)+dz
                pts=[H.surf(ta,za0,sx,off),H.surf(tc,zc0,sx,off),H.surf(tc,min(zc0+h,H.zs(tc)),sx,off),H.surf(ta,min(za0+h,H.zs(ta)),sx,off)]
            else:
                pa=H.sheer(ta); pc=H.sheer(tc); pa.x*=sx; pc.x*=sx
                oa=V((sx*off*taper(ta),0,dz)); oc=V((sx*off*taper(tc),0,dz))
                pts=[pa+oa,pc+oc,pc+oc+V((0,0,h)),pa+oa+V((0,0,h))]
            face(b,pts,key,(sx,-0.3 if ta<0.1 else 0,0))
def rubrail(b,H,ts,key='rubber_black',w=0.05,h=0.07,seg=None):
    """rub rail on the sheer: 3-face D section (top, out, bottom) following the sheer; its width tapers to 0 at the stem
    so port and starboard rails mitre into one another on the stem line"""
    for sx in (1,-1):
        for i in range(len(ts)-1):
            ta,tc=ts[i],ts[i+1]
            a=H.sheer(ta); c=H.sheer(tc); a.x*=sx; c.x*=sx
            oa=V((sx*w*taper(ta),0,0)); oc=V((sx*w*taper(tc),0,0)); dz=V((0,0,-h))
            ab=H.surf(ta,a.z-h,sx); cb=H.surf(tc,c.z-h,sx)
            out=(sx,-0.3 if ta<0.1 else 0,0)
            face(b,[a,c,c+oc*0.6+dz*0.15,a+oa*0.6+dz*0.15],key,(sx,0,1))
            face(b,[a+oa*0.6+dz*0.15,c+oc*0.6+dz*0.15,c+oc*0.6+dz*0.85,a+oa*0.6+dz*0.85],key,out)
            face(b,[a+oa*0.6+dz*0.85,c+oc*0.6+dz*0.85,cb,ab],key,(sx,0,-1))
def wire(b,p0,p1,r,key,seg=4,rec=None):
    b.tube(V(p0),V(p1),r,r,seg,key,cap0=False,cap1=False,smooth=True)
    if rec: P.rec(rec,tuple(p0),tuple(p1),r)
def fender(b,c,L,r,key,lod,line_to=None,linekey='wood_white'):
    seg={'hi':16,'mid':5}.get(P.TIER['t'],6); x,y,z=c
    prof=[(0.0,z-L/2-0.03),(r*0.8,z-L/2+0.03),(r,z-L/4),(r,z+L/4),(r*0.8,z+L/2-0.03),(0.0,z+L/2+0.03)]
    if P.TIER['t']=='hi': prof=[(0.0,z-L/2-0.03),(r*0.35,z-L/2-0.02),(r*0.9,z-L/2+0.06),(r,z-L/4),(r,z+L/4),(r*0.9,z+L/2-0.06),(r*0.35,z+L/2+0.02),(0.0,z+L/2+0.03)]
    b.lathe(prof,seg,key,c=(x,y,0),cap_top=False)
    if line_to is not None: b.tube(V((x,y,z+L/2+0.03)),V(line_to),0.006,0.006,3,linekey,cap0=False,cap1=False)
def cleat_small(b,c,rz,key='aluminium',L=0.20):
    x,y,z=c; d=V((math.cos(rz),math.sin(rz),0))
    for s in (-1,1): b.tube(V((x,y,z))+d*s*0.04,V((x,y,z+0.03))+d*s*0.035,0.012,0.010,4,key,cap0=False,cap1=False)
    b.tube(V((x,y,z+0.035))-d*L/2,V((x,y,z+0.035))+d*L/2,0.012,0.010,4,key,cap0=True,cap1=True)
def winch(b,c,r,h,key='cast_iron',seg=8):
    x,y,z=c
    if P.TIER['t']=='hi': b.lathe([(r*1.15,z),(r*1.15,z+0.02),(r,z+0.03),(r*0.85,z+h*0.7),(r*0.95,z+h*0.75),(r*0.6,z+h),(0.0,z+h+0.01)],seg,key,c=(x,y,0),cap_top=False)
    else: b.lathe([(r*1.15,z),(r*0.9,z+h*0.7),(r*0.6,z+h),(0.0,z+h+0.01)],min(seg,6),key,c=(x,y,0),cap_top=False)
