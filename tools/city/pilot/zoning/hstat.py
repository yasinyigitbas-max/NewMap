import numpy as np, sys
from load import *; from grid import *
m,H,C=terrain(); ox,oz=m["origin_xz"]; cr=m["class_res"]
def h(u,v):
    x,z=to_world(u,v); return H[int(round((z-oz)/4)),int(round((x-ox)/4))]
def cls(u,v):
    x,z=to_world(u,v); return C[int((z-oz)/cr),int((x-ox)/cr)]
def stat(cu,cv,x0,x1,z0,z1):
    hs=[];cl=[]
    for x in np.arange(x0,x1+1,10):
        for z in np.arange(z0,z1+1,10):
            hs.append(h(cu+x,cv+z)); cl.append(cls(cu+x,cv+z))
    hs=np.array(hs); import collections
    return hs.min(),hs.max(),np.median(hs),collections.Counter(cl).most_common(4)
if __name__=="__main__":
    a=[float(s) for s in sys.argv[1:]]
    lo,hi,med,cl=stat(*a); print("h %.1f..%.1f med %.1f  classes %s"%(lo,hi,med,cl))
