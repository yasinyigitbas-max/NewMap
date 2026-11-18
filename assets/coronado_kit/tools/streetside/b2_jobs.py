"""render jobs for the batch-2 pieces: 4 near views with the 1.8 m figure (wall pieces: 3 front-side views + top, against a wall)"""
import json,glob,os,sys,numpy as np
sys.path.insert(0,os.path.dirname(__file__)); import wf_glb as G
K='/workspace/coronado_kit_v2/_staging/waterfront/kit/props/batch2'; O='/workspace/coronado_kit_v2/_staging/props_batch2/work'
WALL={'balcony_clutter':(-2.5,0.0,2.5,0.25,3.2),'buzzer_panel':(-0.9,0.0,0.9,0.2,2.6),'dingbat_stair':(-3.3,0.5,3.1,0.75,4.0)}   # stair: building wall at y=+0.5
names=sys.argv[1:]
jobs=[]
for f in sorted(glob.glob(K+'/**/prop_*_clean_near.glb',recursive=True)):
    n=os.path.basename(f)[5:-15]
    if names and n not in names: continue
    P=G.mesh(f)['P']; D=float(np.linalg.norm(P.max(0)-P.min(0))); D=max(D,1.0)
    views=[(-35,22),(55,18),(145,18),(235,18)] if n not in WALL else [(-35,18),(0,8),(35,18),(0,60)]
    for i,(az,el) in enumerate(views):
        J=dict(out=f'{O}/r_{n}_{i}.png',glbs=[f],fig=True,az=az,el=el,res=[560,420],samples=14,ground_ext=4.0,dist=D*1.7+1.2)
        if n in WALL: J['land']=WALL[n]
        if n=='buzzer_panel': J.update(glbs=[],extra=[{'glb':f,'loc':[0,0,1.15]}],dist=3.4)   # mounted at 1.15 m on an apartment wall
        jobs.append(J)
json.dump(jobs,open(O+'/jobs.json','w'),indent=0); print(len(jobs),'jobs')
