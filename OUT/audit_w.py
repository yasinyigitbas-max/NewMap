# west fill own audit: (1) every ground prop against its own piece's ground (sunk / floating); (2) seats, tables and play
# items on asphalt; (3) bins and dumpsters more than 1.5 m from any building wall or fence (Yasin: never in the open)
import sys, json, math, numpy as np
sys.path.insert(0,'/tmp/claude-0/-home-user-NewMap/07ce0345-793c-5370-94bb-91a011bbb531/scratchpad/tools')
import rast
from collections import defaultdict
D=json.load(open('OUT/area/w_dump.json'))
H,P,M,names=rast.raster('OUT/area/wmine',(-1010,10),(-1410,410),0.5)
U0,V0,RS=-1010,-1410,0.5
def cell(u,v):
    i=int((u-U0)/RS); j=int((v-V0)/RS)
    if 0<=j<H.shape[0] and 0<=i<H.shape[1] and P[j,i]>=0: return float(H[j,i]),str(M[j,i])
    return None,'-'
WALL=('meter','ac_condenser','vent_box','buzzer','poster_case','menu_board')
ON=('gallery',)
blds=[(b[2],b[3],b[4],b[5]) for b in D['blds']]
fences=defaultdict(list)
for p in D['props']:
    if p[1].startswith('fence_'): fences[(int(p[2]//10),int(p[4]//10))].append((p[2],p[4]))
def near_fence(x,z,r):
    for i in range(int((x-r)//10),int((x+r)//10)+1):
        for j in range(int((z-r)//10),int((z+r)//10)+1):
            for (a,b) in fences.get((i,j),[]):
                if math.hypot(a-x,b-z)<r: return True
    return False
float_=[];sunk=[];onasph=[];openbin=[]
for pc,nm,x,y,z in D['props']:
    base=nm.split('_worn')[0].split('_normal')[0].split('_clean')[0].split('_rusty')[0]
    h,m=cell(x,z)
    if h is None: continue
    if not any(w in base for w in WALL) and not base.startswith(('fence_','tree_','palm_')):
        dy=y-h
        if dy>0.06: float_.append((round(dy,2),pc,base,round(x,1),round(z,1)))
        if dy<-0.06: sunk.append((round(dy,2),pc,base,round(x,1),round(z,1)))
    if any(s in base for s in ('park_bench','picnic_table','cafe_table','cafe_chair','adirondack','play_structure','swing_set','slide','patio_set')) and m=='asphalt':
        onasph.append((pc,base,round(x,1),round(z,1)))
    if any(s in base for s in ('trash_receptacle','recycling_receptacle','dumpster')):
        dw=min(math.hypot(max(x0-x,0,x-x1),max(z0-z,0,z-z1)) for (x0,z0,x1,z1) in blds) if blds else 99
        if dw>1.5 and not near_fence(x,z,1.5): openbin.append((pc,base,round(x,1),round(z,1),round(dw,1)))
print('FLOATING >6 cm:',len(float_)); [print('  ',t) for t in sorted(float_,reverse=True)[:15]]
print('SUNK >6 cm:',len(sunk)); [print('  ',t) for t in sorted(sunk)[:15]]
print('SEATS/PLAY ON ASPHALT:',len(onasph)); [print('  ',t) for t in onasph[:20]]
print('BINS IN THE OPEN:',len(openbin)); [print('  ',t) for t in openbin[:40]]
json.dump({'float':float_,'sunk':sunk,'asph':onasph,'bins':openbin},open('OUT/area/audit_w.json','w'))
