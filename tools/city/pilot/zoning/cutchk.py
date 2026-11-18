import numpy as np, matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
from load import *; from plan import CUT
m,H,C=terrain(); ox,oz=m["origin_xz"]; cr=m["class_res"]
x0,x1,z0,z1=-2600,1000,3300,7200
Cc=C[int((z0-oz)/cr):int((z1-oz)/cr),int((x0-ox)/cr):int((x1-ox)/cr)]
fig,ax=plt.subplots(figsize=(9,10)); ax.imshow(np.isin(Cc,[0,7,9]),extent=[x0,x1,z1,z0],cmap="Blues")
p=np.array(CUT+[CUT[0]]); ax.plot(p[:,0],p[:,1],"r-"); ax.set_aspect("equal"); ax.grid(alpha=.3)
plt.savefig("/tmp/claude-0/-home-user-coronado-source/eb746224-af68-52a3-91df-ef414b5ad74a/scratchpad/zoning/cut.png",bbox_inches="tight")
