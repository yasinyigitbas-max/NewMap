"""render jobs for the promenade: railing module (hero / back / close-up), wall-end module against a wall slab, boardwalk strip, assembly"""
import json
D='/workspace/coronado_kit_v2/_staging/waterfront/kit/props/waterfront/promenade'; O='/workspace/coronado_kit_v2/_staging/waterfront/previews/work/promenade'
g=lambda n: f'{D}/prop_{n}_clean_near.glb'
J=[]
def job(n,extra,az,el,dist,target,land=None,fig=False,res=(720,480)):
    j=dict(out=f'{O}/{n}.png',glbs=[],extra=extra,az=az,el=el,dist=dist,res=list(res),samples=16,bed=True,fig=fig,ground_ext=3.0,target=target)
    if land: j['land']=land
    J.append(j)
job('rail_0',[{'glb':g('prom_rail'),'loc':[0,0,0]}],-30,14,5.2,[0,0,0.6],fig=[2.6,-0.6,0.0])
job('rail_1',[{'glb':g('prom_rail'),'loc':[0,0,0]}],160,16,5.2,[0,0,0.6])
job('rail_2',[{'glb':g('prom_rail'),'loc':[0,0,0]},{'glb':g('prom_rail'),'loc':[4,0,0]}],-40,22,1.6,[2.0,0,0.7])          # snapped twin post joint
job('rail_wall_0',[{'glb':g('prom_rail_wall'),'loc':[0,0,0]}],-35,16,3.6,[0.2,0,0.6],land=[1.0,-0.8,1.4,0.8,2.6])
job('rail_wall_1',[{'glb':g('prom_rail_wall'),'loc':[0,0,0]}],-70,10,1.4,[0.9,0,0.6],land=[1.0,-0.8,1.4,0.8,2.6])        # flange close-up
job('boardwalk_0',[{'glb':g('prom_boardwalk'),'loc':[0,0,0]}],-30,24,6.5,[0,0,0.2],fig=[1.0,0.4,0.32])
job('boardwalk_1',[{'glb':g('prom_boardwalk'),'loc':[0,0,0]}],-80,8,2.6,[1.8,-1.2,0.2])
A=[{'glb':g('prom_boardwalk'),'loc':[x,0,0]} for x in (-6,-2,2)]+[{'glb':g('prom_rail'),'loc':[x,-1.38,0.32]} for x in (-6,-2)]+[{'glb':g('prom_rail_wall'),'loc':[1,-1.38,0.32]}]
job('assembly_0',A,-25,20,11,[-1.5,0,0.8],land=[2.0,-2.6,4.0,-0.2,3.2],fig=[-3.0,-0.6,0.32],res=(1400,700))
job('assembly_1',A,200,18,11,[-1.5,0,0.8],land=[2.0,-2.6,4.0,-0.2,3.2],res=(1400,700))
json.dump(J,open(O+'/jobs.json','w'),indent=0); print(len(J))
