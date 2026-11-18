"""render jobs for the small waterfront props: hero (front 3/4) + back 3/4 + a close-up per piece, a beach / fuel-dock assembly"""
import json
R='/workspace/coronado_kit_v2/_staging/waterfront'; D=R+'/kit/props/waterfront/small'; O=R+'/previews/work/small'
import os; os.makedirs(O,exist_ok=True)
g=lambda n: f'{D}/prop_{n}_clean_near.glb'
L=json.load(open(R+'/tools/wf_small_list.json')); J=[]
for n,z,dist,tz,water in L:
    for i,(az,el,f) in enumerate(((-35,16,1.0),(150,20,1.0),(-20,8,0.45))):
        J.append(dict(out=f'{O}/{n}_{i}.png',glbs=[],extra=[{'glb':g(n),'loc':[0,0,z]}],az=az,el=el,dist=dist*f,res=[720,480],samples=16,
                      water=1.5 if water else None,bed=bool(water),fig=False if (water or i==2) else [dist*0.18,-0.5,0.0],ground_ext=3.0,target=[0,0,tz]))
# beach assembly: volleyball net, umbrellas, shower, kayak rack, trailer, life-ring stand
A=[{'glb':g('volleyball_net'),'loc':[0,4,0]},{'glb':g('beach_umbrella'),'loc':[-6.5,-2.0,0],'rz':20},{'glb':g('beach_umbrella'),'loc':[-4.0,-2.6,0],'rz':-15},
   {'glb':g('beach_umbrella_closed'),'loc':[-2.0,-2.2,0]},{'glb':g('beach_shower'),'loc':[1.5,-3.0,0]},{'glb':g('kayak_rack'),'loc':[5.5,-3.0,0],'rz':90},
   {'glb':g('boat_trailer'),'loc':[9.5,-1.0,0],'rz':180},{'glb':g('lifering_stand'),'loc':[3.0,-4.2,0]},{'glb':g('fuel_pump'),'loc':[-8.5,-4.0,0]}]
for i,(az,el) in enumerate(((-28,24),(200,20))):
    J.append(dict(out=f'{O}/assembly_{i}.png',glbs=[],extra=A,az=az,el=el,dist=22,res=[1400,760],samples=16,water=None,bed=False,fig=[0.0,-1.0,0.0],ground_ext=5.0,target=[0.5,0,1.0]))
# buoy field on the harbour datum
B=[{'glb':g('buoy_mooring'),'loc':[0,0,0]},{'glb':g('buoy_nun'),'loc':[3.0,1.0,0]},{'glb':g('buoy_can'),'loc':[-3.0,1.0,0]}]
J.append(dict(out=f'{O}/assembly_buoys.png',glbs=[],extra=B,az=-30,el=14,dist=10,res=[1200,640],samples=16,water=1.5,bed=True,fig=False,ground_ext=4.0,target=[0,0.5,1.5]))
json.dump(J,open(O+'/jobs.json','w'),indent=0); print(len(J))
