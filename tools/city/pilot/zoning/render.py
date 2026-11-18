import numpy as np, json, matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
from load import *; from grid import *; from plan import *; from zones import *
m,H,C=terrain(); d=roads(); ox,oz=m["origin_xz"]; cr=m["class_res"]
x0,x1,z0,z1=-3450,-150,1480,4250
W2=lambda pts:[to_world(u,v) for u,v in pts]
fig,ax=plt.subplots(figsize=(20,20*(z1-z0)/(x1-x0)),dpi=110)
ci0=int((x0-ox)/cr); ci1=int((x1-ox)/cr); cj0=int((z0-oz)/cr); cj1=int((z1-oz)/cr)
Cc=C[cj0:cj1,ci0:ci1]
pal=np.array([[120,170,205],[236,233,224],[240,226,175],[205,225,180],[185,215,160],[214,210,222],[200,200,200],[120,170,205],[170,210,150],[120,170,205],[195,225,175],[214,216,190],[200,190,180],[185,215,160],[205,205,205],[226,222,210]],dtype=np.uint8)
import shapely
from shapely.geometry import Polygon as SP, Point
cut=SP(CUT)
gx=np.linspace(x0,x1,Cc.shape[1],endpoint=False)+cr/2; gz=np.linspace(z0,z1,Cc.shape[0],endpoint=False)+cr/2
GX,GZ=np.meshgrid(gx,gz); incut=shapely.contains_xy(cut,GX,GZ)
Cc=Cc.copy(); Cc[incut]=0
ax.imshow(pal[Cc],extent=[x0,x1,z1,z0],zorder=0)
for k,(lab,col,polys) in Z.items():
    for p in polys:
        g=SP(W2(p)).difference(cut)
        for gg in (g.geoms if hasattr(g,"geoms") else [g]):
            if gg.is_empty: continue
            ax.add_patch(Polygon(list(gg.exterior.coords),closed=True,fc=col,ec=col,alpha=0.38,lw=1.2,zorder=1))
# water drawn again over zones so zones never paint the sea
wm=np.isin(Cc,[0,7,9]); wimg=np.zeros(Cc.shape+(4,)); wimg[wm]=[120/255,170/255,205/255,1]
ax.imshow(wimg,extent=[x0,x1,z1,z0],zorder=2)
mil=np.isin(Cc,[5,6,14]); mimg=np.zeros(Cc.shape+(4,)); mimg[mil]=[0.55,0.55,0.6,0.35]
ax.imshow(mimg,extent=[x0,x1,z1,z0],zorder=2)
Wd={"service":0.3,"residential":0.9,"unclassified":0.7,"tertiary":1.4,"secondary":1.8,"primary":2.2,"trunk":2.6,"motorway":2.6}
for e in d["edges"]:
    p=np.array(e["pts"])
    if p[:,0].max()<x0 or p[:,0].min()>x1 or p[:,2].max()<z0 or p[:,2].min()>z1: continue
    keep=~shapely.contains_xy(cut,p[:,0],p[:,2])
    if not keep.any(): continue
    p=np.where(keep[:,None],p,np.nan)
    ax.plot(p[:,0],p[:,2],color="#555" if e["hw"]!="service" else "#aaa",lw=Wd.get(e["hw"],0.4),zorder=3,solid_capstyle="round")
cl=np.array(CUT[:6]); ax.plot(cl[:,0],cl[:,1],color="#d00",lw=2.5,ls="--",zorder=9)
ax.text(cl[1][0]-250,cl[1][1]+170,"coast cut here (Yasin): the Strand, the Shores and the south base become sea;\nthe new shore gets a rounded beach + seawall, no straight edge",color="#d00",fontsize=9,fontweight="bold",zorder=9)
# invented relief contours (metres added to the real ground)
U,V=np.meshgrid(np.arange(-1350,1450,8.0),np.arange(-1800,850,8.0)); F=field(U,V)
X=O[0]+B[0]*U+A[0]*V; Zw=O[1]+B[1]*U+A[1]*V
cs=ax.contour(X,Zw,F,levels=[2,4,6,8,10,12],colors="#6d4c1f",linewidths=1.1,linestyles="--",zorder=4)
ax.clabel(cs,fmt="+%d m",fontsize=8,colors="#6d4c1f")
for n,c,r,hh,lab in HILLS:
    off={"Crown Hill":(-250,40),"Glorietta Heights":(0,120)}.get(n,(0,0)); x,z=to_world(c[0]+off[0],c[1]+off[1]); ax.text(x,z,lab+"\n+%d m"%hh,fontsize=9,color="#5a3a10",ha="center",va="center",fontweight="bold",zorder=6,style="italic")
# locked samples
for s in SAMPLES:
    ax.add_patch(Polygon(W2(rect_g(s,BUF0)),closed=True,fill=False,ec="#222",lw=0.9,ls=":",zorder=5))
    ax.add_patch(Polygon(W2(rect_g(s)),closed=True,fc="white",ec="#111",lw=2.2,alpha=0.85,hatch="//",zorder=5))
    cx=np.mean([p[0] for p in W2(rect_g(s))]); cz=np.mean([p[1] for p in W2(rect_g(s))])
    if s[0]=="V": cx,cz=to_world(*s2g(s,0,40))
    ax.text(cx,cz,s[4]+("\n(locked: flat high street,\nhill rows rise +5.9 m)" if s[0]=="P" else "\n(locked, flat)"),fontsize=7.5,ha="center",va="center",fontweight="bold",zorder=7,
            bbox=dict(fc="white",ec="none",alpha=0.75,pad=1))
for nm,txt,(u,v) in MUST:
    x,z=to_world(u,v); ax.plot(x,z,marker="*",ms=24,mfc="#ffd400",mec="#b00",mew=1.6,zorder=8)
    ax.text(x+32,z+5,nm+"\n"+txt,fontsize=8.5,color="#900",fontweight="bold",zorder=8,bbox=dict(fc="white",ec="#b00",alpha=0.85,pad=2))
for nm,(u,v) in HERO:
    x,z=to_world(u,v); ax.plot(x,z,marker="D",ms=11,mfc="#fff",mec="#000",zorder=8)
    ax.text(x+25,z-12,nm,fontsize=7.5,zorder=8,bbox=dict(fc="white",ec="none",alpha=0.7,pad=1))
for a,b,t in TRANS:
    xa,za=to_world(*a); xb,zb=to_world(*b)
    ax.annotate("",xy=(xb,zb),xytext=(xa,za),arrowprops=dict(arrowstyle="<->",color="#333",lw=1.2),zorder=8)
# place names
for t,(u,v) in [("NAVAL AIR STATION\n(military, outside the city kit)",(-1600,-1150)),("GOLF",(700,-500)),("park at the\nbridge foot",(850,-1230)),("GLORIETTA BAY",(900,280)),
                ("PACIFIC BEACH",(-500,520)),("SAN DIEGO BAY",(300,-1850)),("bridge to San Diego",(1150,-1000)),("Sunset Park / golf",(-1400,-200))]:
    x,z=to_world(u,v)
    if x0<x<x1 and z0<z<z1: ax.text(x,z,t,fontsize=9,color="#234",ha="center",style="italic",zorder=6)
for t,u,v in [("Amber Ave",15,-1500),("4th St (bridge route)",-560,-1072),("3rd St",-560,-1250),("10th St",-450,-12)]:
    x,z=to_world(u,v); ax.text(x,z,t,fontsize=7,color="#000",rotation=-63 if "Amber" in t else -26,zorder=6)
# legend
from matplotlib.patches import Patch
from matplotlib.lines import Line2D
h=[Patch(fc=c,alpha=0.5,label=l) for l,c,_ in Z.values()]
h+=[Patch(fc="white",ec="#111",hatch="//",label="Locked sample: stays exactly as built (its own ground)"),
    Line2D([],[],color="#222",ls=":",label="40 m flat margin round each sample"),
    Line2D([],[],color="#6d4c1f",ls="--",label="New hills: height added (+2..+12 m), max 8 %"),
    Line2D([],[],marker="*",ls="",ms=15,mfc="#ffd400",mec="#b00",label="MUST site"),
    Line2D([],[],marker="D",ls="",ms=9,mfc="#fff",mec="#000",label="Hero site (hand-made)"),
    Patch(fc=(0.55,0.55,0.6,0.35),label="Military / airfield (unchanged)")]
ax.legend(handles=h,loc="lower left",fontsize=9,framealpha=0.92)
# north arrow + scale
ax.annotate("N",xy=(x1-120,z0+60),xytext=(x1-120,z0+230),ha="center",fontsize=14,fontweight="bold",arrowprops=dict(arrowstyle="-|>",lw=2))
ax.plot([x1-760,x1-260],[z1-80,z1-80],color="k",lw=4); ax.text(x1-510,z1-105,"500 m",ha="center",fontsize=10)
ax.set_xlim(x0,x1); ax.set_ylim(z1,z0); ax.set_aspect("equal"); ax.set_xticks([]); ax.set_yticks([])
ax.set_title("Coronado zoning map (APPROVED 17 Nov, locked): samples on flat ground, hills only in the transitions and extensions",fontsize=14)
import os; plt.savefig(os.path.join(os.path.dirname(os.path.abspath(__file__)),"../../../../map_dc/coronado/city_kit/zoning/zoning_map.png"),bbox_inches="tight")
print("ok")
