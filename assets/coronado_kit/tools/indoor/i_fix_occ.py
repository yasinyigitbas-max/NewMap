"""repo convention (game assets branch): near glb material carries occlusionTexture -> ORM (index 2, AO in R)"""
import sys,json,struct
for p in sys.argv[1:]:
    d=open(p,'rb').read(); magic,ver,_=struct.unpack('<III',d[:12]); jl,_=struct.unpack('<II',d[12:20]); js=json.loads(d[20:20+jl]); rest=d[20+jl:]
    for m in js['materials']:
        mr=m.get('pbrMetallicRoughness',{}).get('metallicRoughnessTexture')
        if mr: m['occlusionTexture']={'index':mr['index']}
    j=json.dumps(js,separators=(',',':')).encode(); j+=b' '*((4-len(j)%4)%4)
    open(p,'wb').write(struct.pack('<III',magic,ver,12+8+len(j)+len(rest))+struct.pack('<II',len(j),0x4E4F534A)+j+rest); print('occ',p)
