"""Clean-named copies of the phase-B urban examples. modular/examples/mod_<x>/ ships mod_mod_<x>_<tier>.glb (layout name
'mod_<x>' + merge's 'mod_' prefix). This copies each to modular/examples_renamed/<x>/mod_<x>_<tier>.glb with the glTF
node / mesh / material names renamed the same way, geometry byte-identical. The originals are not touched."""
import os, glob, json, shutil, pygltflib
M=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
for d in sorted(glob.glob(M+'/examples/mod_*/')):
    L=json.load(open(d+'layout.json')); old=L['name']; new=old[4:]
    o=f'{M}/examples_renamed/{new}'; os.makedirs(o,exist_ok=True)
    for t in ('near','mid','far','col'):
        g=pygltflib.GLTF2().load(f'{d}mod_{old}_{t}.glb')
        for coll in (g.nodes,g.meshes,g.materials,g.scenes):
            for e in coll or []:
                if getattr(e,'name',None): e.name=e.name.replace('mod_mod_','mod_')
        g.save_binary(f'{o}/mod_{new}_{t}.glb')
    for img in glob.glob(d+'*.png'): shutil.copy(img,o)
    L['name']=new; L['renamed_from']=f'modular/examples/{old}/mod_{old}_*.glb'
    json.dump(L,open(f'{o}/layout.json','w'),indent=1)
    print(old,'->',new)
