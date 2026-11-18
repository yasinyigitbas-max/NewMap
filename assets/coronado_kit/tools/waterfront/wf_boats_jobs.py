"""render jobs for the moored boats: per boat a hero + quarter-back view afloat (placed at z = 1.5 - WL), a dry underbody view, plus an assembly at the marina"""
import json,sys
D='/workspace/coronado_kit_v2/_staging/waterfront/kit/props/waterfront'; O='/workspace/coronado_kit_v2/_staging/waterfront/previews/work/boats'
g=lambda n,s='boats': f'{D}/{s}/prop_{n}_clean_near.glb'
WL={'boat_sloop':1.40,'boat_express':0.70,'boat_troller':1.35,'boat_skiff':0.30,'boat_ferry':1.20}
DIST={'boat_sloop':17,'boat_express':13,'boat_troller':17,'boat_skiff':7,'boat_ferry':26}
TZ={'boat_sloop':4.5,'boat_express':2.2,'boat_troller':3.5,'boat_skiff':1.6,'boat_ferry':3.5}
names=[a for a in sys.argv[1:] if a in WL] or ([] if sys.argv[1:]==['asm'] else [k for k in WL if k!='boat_ferry'])
jobs=[]
for n in names:
    z=1.5-WL[n]
    for i,(az,el,w) in enumerate(((-35,14,1.5),(145,18,1.5),(-80,4,None))):
        J=dict(out=f'{O}/{n}_{i}.png',glbs=[],extra=[{'glb':g(n),'loc':[0,0,z if w else 0]}],az=az,el=el,dist=DIST[n]*(0.8 if i==2 else 1),res=[720,480],samples=16,
               water=w,bed=bool(w),fig=False,ground_ext=4.0,target=[0,0,TZ[n] if i<2 else 1.0])
        jobs.append(J)
    BOW={'boat_sloop':(-4.7,2.6),'boat_express':(-5.0,2.0),'boat_troller':(-6.3,3.2),'boat_skiff':(-2.6,1.0),'boat_ferry':(-9.5,3.0)}
    by,bz=BOW[n]
    SIDE={'boat_sloop':(-1.2,2.4),'boat_express':(-1.6,1.4),'boat_troller':(-2.5,2.4),'boat_skiff':(-1.0,0.6),'boat_ferry':(0,3.0)}
    sy_,sz_=SIDE[n]
    jobs.append(dict(out=f'{O}/{n}_side.png',glbs=[],extra=[{'glb':g(n),'loc':[0,0,z]}],az=-95,el=6,dist=max(3.5,DIST[n]*0.35),res=[720,480],samples=16,
                     water=1.5,bed=True,fig=False,ground_ext=4.0,target=[0,sy_,sz_+z]))   # hull-side close-up (ports / stripes)
    for k,(az,el) in enumerate(((-25,12),(-150,40))):   # bow close-ups (quarter + high from ahead)
        jobs.append(dict(out=f'{O}/{n}_bow{k}.png',glbs=[],extra=[{'glb':g(n),'loc':[0,0,z]}],az=az,el=el,dist=max(3.0,DIST[n]*0.28),res=[720,480],samples=16,
                         water=1.5,bed=True,fig=False,ground_ext=4.0,target=[0,by+0.8,bz+z-0.3]))
json.dump(jobs,open(O+'/jobs.json','w'),indent=0); print(len(jobs))
# assembly: the four boats in slips at the marina floats (bows to the float, rz 180), floats at z 1.2, boats at z 1.5 - WL
if not sys.argv[1:] or 'asm' in sys.argv[1:]:
    jobs=[j for j in jobs if 'assembly' not in j['out']] if sys.argv[1:]==['asm'] else jobs
    if sys.argv[1:]==['asm']: jobs=[]
    M=lambda n: f'{D}/marina/prop_{n}_clean_near.glb'
    A=[{'glb':M('marina_float'),'loc':[x,0,1.2]} for x in (0,6,12,18)]+[{'glb':M('marina_finger'),'loc':[x,-1.25,1.2]} for x in (1.5,7.5,13.5,19.5)]
    A+=[{'glb':M('marina_pedestal'),'loc':[x,-0.95,1.95]} for x in (3.0,9.0,15.0)]+[{'glb':M('dock_box'),'loc':[x,0.55,1.95]} for x in (4.4,10.4)]
    A+=[{'glb':g('boat_sloop'),'loc':[4.5,-6.55,1.5-WL['boat_sloop']],'rz':180},{'glb':g('boat_express'),'loc':[10.5,-7.2,1.5-WL['boat_express']],'rz':180},
        {'glb':g('boat_troller'),'loc':[16.5,-8.7,1.5-WL['boat_troller']],'rz':180},{'glb':g('boat_skiff'),'loc':[-0.15,-4.6,1.5-WL['boat_skiff']],'rz':180}]
    for i,(az,el) in enumerate(((-28,22),(205,18))):
        jobs.append(dict(out=f'{O}/assembly_{i}.png',glbs=[],extra=A,az=az,el=el,dist=30,res=[1400,760],samples=16,water=1.5,bed=True,fig=[3.0,-0.3,1.95],ground_ext=6.0,target=[9,-5,3]))
    json.dump(jobs,open(O+'/jobs.json','w'),indent=0); print(len(jobs))
