"""glb helpers for the waterfront checks: load one-mesh glbs, z-buffered ortho rasteriser (texture x COLOR_0, linear), write COLOR_0."""
import json, struct, os, numpy as np
from PIL import Image
CT={5120:np.int8,5121:np.uint8,5122:np.int16,5123:np.uint16,5125:np.uint32,5126:np.float32}
NC={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}
def load(p):
    d=open(p,'rb').read(); jl=struct.unpack('<I',d[12:16])[0]; js=json.loads(d[20:20+jl]); o=20+jl
    bl=struct.unpack('<I',d[o:o+4])[0]; return js,bytearray(d[o+8:o+8+bl]),d
def _acc_info(js,i):
    a=js['accessors'][i]; bv=js['bufferViews'][a['bufferView']]; n=NC[a['type']]; dt=CT[a['componentType']]
    off=bv.get('byteOffset',0)+a.get('byteOffset',0); st=bv.get('byteStride',0) or np.dtype(dt).itemsize*n
    return a,dt,n,off,st
def acc(js,b,i,raw=False):
    a,dt,n,off,st=_acc_info(js,i); cnt=a['count']; isz=np.dtype(dt).itemsize*n
    r=np.frombuffer(bytes(b),np.uint8,count=st*cnt,offset=off).reshape(cnt,st)[:,:isz].copy().view(dt).reshape(cnt,n)
    if raw: return r
    if a.get('normalized'): r=r.astype(np.float32)/np.iinfo(dt).max
    return r.astype(np.float64)
def mesh(p):
    js,b,_=load(p); pr=js['meshes'][0]['primitives'][0]; at=pr['attributes']
    P=acc(js,b,at['POSITION']); I=acc(js,b,pr['indices']).astype(np.int64).reshape(-1,3)
    UV=acc(js,b,at['TEXCOORD_0']) if 'TEXCOORD_0' in at else np.zeros((len(P),2))
    C=acc(js,b,at['COLOR_0'])[:,:3] if 'COLOR_0' in at else np.ones((len(P),3))
    N=acc(js,b,at['NORMAL']) if 'NORMAL' in at else None
    tex=None
    if js.get('images'):
        u=js['images'][0]['uri']; tp=os.path.normpath(os.path.join(os.path.dirname(p),u))
        if os.path.exists(tp): tex=srgb2lin(np.asarray(Image.open(tp).convert('RGB')).astype(np.float32)/255)
    return dict(P=P,I=I,UV=UV,C=C,N=N,tex=tex,js=js,b=b)
def srgb2lin(c): return np.where(c<=0.04045,c/12.92,((c+0.055)/1.055)**2.4)
def lin2srgb(c): c=np.clip(c,0,1); return np.where(c<=0.0031308,c*12.92,1.055*c**(1/2.4)-0.055)
# view axes in glTF space (Y up, front +Z): (right, up, toward-viewer)
VIEWS={'front':((1,0,0),(0,1,0),(0,0,1)),'back':((-1,0,0),(0,1,0),(0,0,-1)),'left':((0,0,1),(0,1,0),(-1,0,0)),
       'right':((0,0,-1),(0,1,0),(1,0,0)),'top':((1,0,0),(0,0,-1),(0,1,0)),'bottom':((1,0,0),(0,0,1),(0,-1,0))}
def raster(m,view,frame,res=0.03):
    """returns colour (H,W,3 linear) with nan where empty, depth, mask; frame=(u0,u1,v0,v1) in view coords"""
    R,U,F=[np.array(v,float) for v in VIEWS[view]]
    P=m['P']; u=P@R; v=P@U; d=P@F
    u0,u1,v0,v1=frame; W=max(2,int(np.ceil((u1-u0)/res))); H=max(2,int(np.ceil((v1-v0)/res)))
    Z=np.full((H,W),-1e9); col=np.full((H,W,3),np.nan); I=m['I']; UV=m['UV']; C=m['C']; tex=m['tex']
    px=(u-u0)/res; py=(v1-v)/res
    for t in I:
        x=px[t]; y=py[t]
        xmn=max(int(np.floor(x.min())),0); xmx=min(int(np.ceil(x.max())),W-1); ymn=max(int(np.floor(y.min())),0); ymx=min(int(np.ceil(y.max())),H-1)
        if xmn>xmx or ymn>ymx: continue
        gx,gy=np.meshgrid(np.arange(xmn,xmx+1)+0.5,np.arange(ymn,ymx+1)+0.5)
        x0,x1,x2=x; y0,y1,y2=y; den=(y1-y2)*(x0-x2)+(x2-x1)*(y0-y2)
        if abs(den)<1e-12:   # edge-on: draw the edge as a 1 px line (thin plates seen side-on still occupy the silhouette)
            continue
        a=((y1-y2)*(gx-x2)+(x2-x1)*(gy-y2))/den; bb=((y2-y0)*(gx-x2)+(x0-x2)*(gy-y2))/den; c=1-a-bb
        ins=(a>=-1e-6)&(bb>=-1e-6)&(c>=-1e-6)
        if not ins.any(): continue
        dz=a*d[t[0]]+bb*d[t[1]]+c*d[t[2]]
        sub=Z[ymn:ymx+1,xmn:xmx+1]; upd=ins&(dz>sub)
        if not upd.any(): continue
        sub[upd]=dz[upd]
        uv=(a[...,None]*UV[t[0]]+bb[...,None]*UV[t[1]]+c[...,None]*UV[t[2]])[upd]
        vc=(a[...,None]*C[t[0]]+bb[...,None]*C[t[1]]+c[...,None]*C[t[2]])[upd]
        if tex is not None:
            th,tw=tex.shape[:2]; ti=np.clip((uv[:,1]*th).astype(int),0,th-1); tj=np.clip((uv[:,0]*tw).astype(int),0,tw-1); tc=tex[ti,tj]
        else: tc=np.ones((len(uv),3))*0.8
        cs=col[ymn:ymx+1,xmn:xmx+1]; cs[upd]=tc*vc
    mask=~np.isnan(col[...,0]); return col,Z,mask
def frame_of(ms,view,pad=0.1):
    R,U,F=[np.array(v,float) for v in VIEWS[view]]
    us=np.concatenate([m['P']@R for m in ms]); vs=np.concatenate([m['P']@U for m in ms])
    return (us.min()-pad,us.max()+pad,vs.min()-pad,vs.max()+pad)
def write_color0(path,m,newC):
    js,b,d=m['js'],m['b'],None
    pr=js['meshes'][0]['primitives'][0]; i=pr['attributes']['COLOR_0']
    a,dt,n,off,st=_acc_info(js,i); cnt=a['count']
    arr=np.ones((cnt,n),np.float64); arr[:,:3]=np.clip(newC,0,1)
    if dt==np.float32: raw=arr.astype(np.float32)
    else: raw=np.round(arr*np.iinfo(dt).max).astype(dt)
    isz=np.dtype(dt).itemsize*n; rb=raw.tobytes()
    for k in range(cnt): b[off+k*st:off+k*st+isz]=rb[k*isz:(k+1)*isz]
    jj=json.dumps(js,separators=(',',':')).encode(); jj+=b' '*((4-len(jj)%4)%4)
    bb=bytes(b); bb+=b'\0'*((4-len(bb)%4)%4)
    out=struct.pack('<III',0x46546C67,2,12+8+len(jj)+8+len(bb))+struct.pack('<II',len(jj),0x4E4F534A)+jj+struct.pack('<II',len(bb),0x004E4942)+bb
    open(path,'wb').write(out)
