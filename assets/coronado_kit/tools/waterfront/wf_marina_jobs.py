"""render jobs for the marina group: per piece a hero + a back view at the float datum (floats at z 1.2 on WL 1.5), plus an assembly"""
import json
D='/workspace/coronado_kit_v2/_staging/waterfront/kit/props/waterfront/marina'; O='/workspace/coronado_kit_v2/_staging/waterfront/previews/work/marina'
g=lambda n: f'{D}/prop_{n}_clean_near.glb'
Z={'marina_float':1.2,'marina_finger':1.2,'marina_pile':0.0,'dock_box':1.95,'marina_pedestal':1.95}
jobs=[]
for n,dist in (('marina_float',9.0),('marina_finger',10.0),('marina_pile',7.5),('dock_box',3.4),('marina_pedestal',2.8)):
    for i,(az,el) in enumerate(((-35,24),(150,20))):
        J=dict(out=f'{O}/{n}_{i}.png',glbs=[],extra=[{'glb':g(n),'loc':[0,0,Z[n]]}],az=az,el=el,dist=dist,res=[720,480],samples=16,
               water=1.5,bed=True,fig=[-1.0 if n!='marina_finger' else -1.2,0.0 if n!='marina_pile' else -0.9,1.95] if n!='marina_pile' else False,ground_ext=4.0)
        if n=='marina_pile': J['extra'].append({'glb':g('marina_float'),'loc':[0,0.40+1.33,1.2]})   # float beside the hoop for context
        if n in ('dock_box','marina_pedestal'): J['extra'].append({'glb':g('marina_float'),'loc':[0,0,1.2]}); J['target']=[0,0,2.3]
        jobs.append(J)
A=[{'glb':g('marina_float'),'loc':[0,0,1.2]},{'glb':g('marina_float'),'loc':[6,0,1.2]},
   {'glb':g('marina_finger'),'loc':[1.5,-1.25,1.2]},{'glb':g('marina_finger'),'loc':[7.5,-1.25,1.2]},
   {'glb':g('marina_pile'),'loc':[2.08+0.40,-7.75,0],'rz':90},{'glb':g('marina_pile'),'loc':[6.92-0.40,-7.75,0],'rz':-90},
   {'glb':g('dock_box'),'loc':[-1.6,0.55,1.95]},{'glb':g('dock_box'),'loc':[4.4,0.55,1.95]},
   {'glb':g('marina_pedestal'),'loc':[3.0,-0.95,1.95]},{'glb':g('marina_pedestal'),'loc':[9.0,-0.95,1.95]}]
for i,(az,el) in enumerate(((-30,30),(200,22))):
    jobs.append(dict(out=f'{O}/assembly_{i}.png',glbs=[],extra=A,az=az,el=el,dist=19,res=[1200,640],samples=16,water=1.5,bed=True,fig=[0.6,-0.3,1.95],ground_ext=6.0))
json.dump(jobs,open(O+'/jobs.json','w'),indent=0); print(len(jobs))
