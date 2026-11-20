# west fill tree layer: candidate spots by the tree plan's rules per area kind, checked, written as t_w_* pieces
import sys, json, math, numpy as np
sys.path.insert(0,'/tmp/claude-0/-home-user-NewMap/07ce0345-793c-5370-94bb-91a011bbb531/scratchpad/tools')
import rast
D=json.load(open('OUT/area/w_dump.json')); rows={r['piece']:r for r in json.load(open('OUT/area/w_layout.json'))['instances']}
H,P,M,names=rast.raster('OUT/area/wmine',(-1010,10),(-1410,410),0.5)
U0,V0,RS=-1010,-1410,0.5
def cell(u,v):
    i=int((u-U0)/RS); j=int((v-V0)/RS)
    if 0<=j<H.shape[0] and 0<=i<H.shape[1] and P[j,i]>=0: return float(H[j,i]),str(M[j,i]),names[P[j,i]]
    return None,'-','-'
blds=[(b[0],b[2],b[3],b[4],b[5]) for b in D['blds']]
props=[(p[0],p[1],p[2],p[4]) for p in D['props']]
fences=[(x,z) for (pc,nm,x,z) in props if nm.startswith('fence_')]
others=[(x,z,nm) for (pc,nm,x,z) in props if not nm.startswith('fence_') and not nm.startswith(('tree_','palm_','plant_'))]
from collections import defaultdict
grid=defaultdict(list)
for (x,z,nm) in others: grid[(int(x//10),int(z//10))].append((x,z,nm))
fgrid=defaultdict(list)
for (x,z) in fences: fgrid[(int(x//10),int(z//10))].append((x,z))
def near(g,x,z,r):
    out=[]
    for i in range(int((x-r)//10),int((x+r)//10)+1):
        for j in range(int((z-r)//10),int((z+r)//10)+1): out+=g.get((i,j),[])
    return out
def ok(u,v,piece):
    for du,dv in [(0,0),(1,0),(-1,0),(0,1),(0,-1)]:
        h,m,pn=cell(u+du,v+dv)
        if m not in ('grass','mulch') or pn!=piece: return False
    for du,dv in [(3,0),(-3,0),(0,3),(0,-3),(2.2,2.2),(-2.2,2.2),(2.2,-2.2),(-2.2,-2.2)]:
        if cell(u+du,v+dv)[2]!=piece: return False     # 3 m inside its own piece: clear of the neighbours' props
    for (pc,x0,z0,x1,z1) in blds:
        if math.hypot(max(x0-u,0,u-x1),max(z0-v,0,v-z1))<4.0: return False
    for (x,z) in near(fgrid,u,v,2): 
        if math.hypot(x-u,z-v)<1.5: return False
    for (x,z,nm) in near(grid,u,v,3):
        if math.hypot(x-u,z-v)<2.2: return False
    return True
KIND={}
for p in ['n_w_c2','n_w_c7','n_w_h1','n_w_h2','n_w_h3','n_w_h4','n_w_p1','n_w_q1','n_w_q2','n_w_q3','n_w_q4','n_w_w7','n_w_w0a','n_w_w0b','n_w_w2b','n_w_c4','n_w_s2c','n_w_e1b','n_w_c1','n_w_c3','n_w_c6','n_w_c10','n_w_c11']: KIND[p]='park'
for p in ['n_w_w3','n_w_w4','n_w_w5','n_w_w6','n_w_x1']: KIND[p]='yards'
for p in ['n_w_e1','n_w_e2','n_w_e3','n_w_e4']: KIND[p]='beach'
for p in ['n_w_s1','n_w_s2a','n_w_w2a']: KIND[p]='court'
KIND['n_w_g1']='gritty'
BROAD=['tree_jacaranda_a','tree_coral_a','tree_magnolia_a','tree_ficus_a','tree_jacaranda_b','tree_coral_b','tree_magnolia_b','tree_ficus_b']
cands=[]
rng=np.random.default_rng(20)
seats=[(pc,x,z,nm) for (pc,nm,x,z) in props if any(s in nm for s in ('park_bench','picnic_table','adirondack','cafe_table','play_structure','bbq_kettle','patio_set'))]
for (pc,x,z,nm) in seats:
    k=KIND.get(pc)
    if k in ('park','court'):
        for ang in (0.4,2.5,4.6):
            r=5.5; u=x+r*math.cos(ang+rng.random()); v=z+r*math.sin(ang+rng.random())
            cands.append((u,v,pc,k,'%s: shade round the seating (%s)'%('park' if k=='park' else 'court',nm.split('_worn')[0].split('_normal')[0].replace('prop_',''))))
    elif k in ('yards','beach') and ('bbq' in nm or 'patio' in nm or 'adirondack' in nm or 'picnic' in nm):
        u=x+3.5; v=z+1.5
        cands.append((u,v,pc,k,'back yard: a yard tree by the patio'))
for pc,k in KIND.items():
    if k=='gritty':
        r=rows[pc]; cands.append((r['pos'][0]+16,r['pos'][2]+100,pc,k,'vacant lot: one scrappy tree that seeded itself'))
    if pc=='n_w_w0a':
        r=rows[pc]
        for z in range(10,200,16): cands.append((r['pos'][0]+6,r['pos'][2]+z,pc,'park','buffer: the windbreak along the ring road'))
chosen=[]
for (u,v,pc,k,why) in cands:
    if not ok(u,v,pc): continue
    if any(math.hypot(u-a,v-b)<7.0 for (a,b,*_) in chosen): continue
    if k=='yards' and sum(1 for c in chosen if c[2]==pc)>=12: continue
    chosen.append((u,v,pc,k,why))
# species
out=[]
for i,(u,v,pc,k,why) in enumerate(chosen):
    if k=='beach': sp=['palm_queen_a','palm_queen_b','palm_mexican_fan_a'][i%3]
    elif k=='gritty': sp='tree_eucalyptus_b'
    elif pc=='n_w_w0a': sp=['tree_eucalyptus_a','tree_eucalyptus_b'][i%2]
    elif pc in ('n_w_w6','n_w_w7'): sp=['tree_torrey_pine_a','tree_torrey_pine_b','tree_coral_a','tree_jacaranda_b'][i%4]
    else: sp=BROAD[i%len(BROAD)]
    out.append([u,v,sp,why,pc])
# the in-view cap from every street / path point near my pieces: drop broadleaf first where over
streets=[]
for r in rows.values():
    pass
pts=[(u,v) for u in range(-1000,0,10) for v in range(-1400,400,10) if cell(u,v)[1] in ('concrete','asphalt','plaza')]
def counts(px,pz):
    nb=0; na=0
    for t in out:
        if math.hypot(t[0]-px,t[1]-pz)<=60:
            na+=1; nb+= 0 if t[2].startswith(('palm_','tree_torrey')) else 1
    return nb,na
changed=True; dropped=0
while changed:
    changed=False
    for (px,pz) in pts:
        nb,na=counts(px,pz)
        if nb>8 or na>12:
            near_t=sorted([t for t in out if math.hypot(t[0]-px,t[1]-pz)<=60],key=lambda t:(t[2].startswith(('palm_','tree_torrey')), -math.hypot(t[0]-px,t[1]-pz)))
            out.remove(near_t[0]); dropped+=1; changed=True; break
print('candidates',len(cands),'chosen',len(chosen),'after cap',len(out),'dropped',dropped)
# write pieces by area
areas={'t_w_north':lambda u,v: v<-800,'t_w_civic':lambda u,v: -800<=v<200 and u>-410,'t_w_strip':lambda u,v: -800<=v<200 and u<=-410,'t_w_edge':lambda u,v: v>=200}
for nm,f in areas.items():
    ts=[t for t in out if f(t[0],t[1])]
    lines=',\n'.join('\t[%.2f, %.2f, %.3f, "%s", %.2f, "%s"]'%(t[0],t[1],cell(t[0],t[1])[0],t[2],0.85 if not t[2].startswith('palm') else 1.0,t[3].replace('"',"'")) for t in ts)
    src='''extends SceneTree
## Piece %s: hand-placed TREES of the west fill (University session, 20 Nov; docs/TREE_PLAN.md), world frame (layout
## row (0, 0, 0): x = u, z = v, y absolute). Each tree: place, species, size, the reason it is there. Rules applied when
## the spots were chosen (OUT/trees_w.py): trunk on grass or mulch (and 1 m round it) of the piece it stands in, 4 m
## from every building, 1.5 m from fences, 2.2 m from other props, 7 m between trees; parks and courts: clumps round
## the seating; house yards: one per two houses by the patio; the beach side: palms; the ridge: pines; the gritty
## edge: one scrappy tree; industrial and the shop fronts: none; at most 8 broadleaf / 12 trees within 60 m of any
## paved point of the west fill. %d trees.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const TREES := [
%s]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("%s")
	for t: Array in TREES:
		c.put(String(t[3]), "normal", Vector3(float(t[0]), float(t[2]), float(t[1])), c.rr.randf_range(0, 360), String(t[5]), false, float(t[4]))
	c.root.set_meta("stalls", [])
	c.props.build(c.root, L.K)
	print("%s: trees %%d" %% c.props.count())
	L.K.save_piece(c.root, "%s")
	quit()
'''%(nm,len(ts),lines,nm,nm,nm)
    open('tools/city/pilot/pieces/%s.gd'%nm,'w').write(src); print(nm,len(ts))
