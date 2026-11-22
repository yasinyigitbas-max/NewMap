"""Add hand attach points to carry-prop near glbs as empty child nodes of the mesh node (Godot imports them as Node3D
children named grip_r / grip_l) and record them in manifest_<batch>.json. Run after run.py (plain python3).
c_grips.py <batch> [names...]   positions are given in Blender space (Z up, front -Y) in the builder's GRIPS."""
import sys, os, json, struct, importlib, types
K=os.environ['IN_KIT']; batch=sys.argv[1]; only=sys.argv[2:]
src=open(os.path.join(os.path.dirname(os.path.abspath(__file__)),f'b_{batch}.py')).read()
GR={}; exec('GRIPS='+src.split('\nGRIPS=')[1].split('\n}\n')[0]+'\n}\n',GR)   # GRIPS literal only (no bpy import)
G=GR['GRIPS']; man_p=f'{K}/props/manifest_{batch}.json'; man=json.load(open(man_p))
for name,g in G.items():
    if only and name not in only: continue
    rec=man[name]; d=os.path.join(K,'props/indoor/carry'); p=f'{d}/{rec["file_base"]}_clean_near.glb'
    data=open(p,'rb').read(); magic,ver,_=struct.unpack('<III',data[:12]); jl,_=struct.unpack('<II',data[12:20]); js=json.loads(data[20:20+jl]); rest=data[20+jl:]
    mesh_nodes=[i for i,n in enumerate(js['nodes']) if 'mesh' in n]; assert len(mesh_nodes)==1; mi=mesh_nodes[0]
    js['nodes']=[n for n in js['nodes'] if not n.get('name','').startswith('grip')]   # idempotent (grip nodes are appended last)
    js['nodes'][mi].pop('children',None)
    kids=[]; out={}
    for k,v in g.items():
        if not k.startswith('grip'): continue
        x,y,z=v; t=[round(x,4),round(z,4),round(-y,4)]   # Blender Z-up -> glTF Y-up
        js['nodes'].append({'name':k,'translation':t}); kids.append(len(js['nodes'])-1); out[k]=t
    js['nodes'][mi]['children']=kids
    j=json.dumps(js,separators=(',',':')).encode(); j+=b' '*((4-len(j)%4)%4)
    open(p,'wb').write(struct.pack('<III',magic,ver,12+8+len(j)+len(rest))+struct.pack('<II',len(j),0x4E4F534A)+j+rest)
    rec['grips']={'space':'glTF / Godot local, metres, Y up, front +Z','points':out,'hold':g.get('hold'),
                  'axes':'+X along the handle bar, +Y up (prop hangs along -Y)'}
    print('grips',name,out)
json.dump(man,open(man_p,'w'),indent=1)
