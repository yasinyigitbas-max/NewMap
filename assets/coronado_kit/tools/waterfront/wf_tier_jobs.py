"""tier strip jobs: near / mid / far of each piece from the same camera (for the contact sheets).
python3 wf_tier_jobs.py <group> -> previews/work/<group>/tiers.json"""
import json,sys
R='/workspace/coronado_kit_v2/_staging/waterfront'; D=R+'/kit/props/waterfront'
G={'boats':[('boat_sloop',0.10,17,4.5,True),('boat_express',0.8,13,2.2,True),('boat_troller',0.15,17,3.5,True),('boat_skiff',1.2,7,1.6,True)],
   'promenade':[('prom_rail',0,5.2,0.6,False),('prom_rail_wall',0,3.6,0.6,False),('prom_boardwalk',0,6.5,0.2,False)],
   'small':[]}
SM=json.load(open(R+'/tools/wf_small_list.json')) if sys.argv[1]=='small' else []
G['small']=[tuple(x) for x in SM]
grp=sys.argv[1]; sub={'small':'small'}.get(grp,grp); O=f'{R}/previews/work/{grp}'; J=[]
for n,z,dist,tz,water in G[grp]:
    for tier in ('near','mid','far'):
        J.append(dict(out=f'{O}/tier_{n}_{tier}.png',glbs=[],extra=[{'glb':f'{D}/{sub}/prop_{n}_clean_{tier}.glb','loc':[0,0,z]}],az=-35,el=16,dist=dist,
                      res=[480,320],samples=12,water=1.5 if water else None,bed=bool(water),fig=False,ground_ext=4.0,target=[0,0,tz]))
json.dump(J,open(O+'/tiers.json','w'),indent=0); print(len(J))
