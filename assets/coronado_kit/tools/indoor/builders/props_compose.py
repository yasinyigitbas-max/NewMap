import os
"""compose shipped props atlas pages = base pages + baked prop tiles (slots.json).
Outputs atlases/props_color_{clean,worn,dirty}.png (2048 RGBA), props_normal.png (2048), props_orm.png (1024)"""
import json, os, numpy as np
from PIL import Image
K=__import__('os').environ.get('IN_KIT','/workspace/coronado_kit_v2/_staging/indoor/kit'); SRC=K+'/props/_bake_src'; T=K+'/props/_bake/tiles'
import sys
PG=sys.argv[1] if len(sys.argv)>1 else ''   # '' page A (2048 with regions) | 'b' page B (1024, tiles only)
SP=K+'/props/_bake/slots.json' if not PG else K+f'/props/_bake/slots_{PG}.json'
S=json.load(open(SP))['slots'] if os.path.exists(SP) else {}
if not PG:
    cols={c:np.array(Image.open(f'{SRC}/props_base_color_{c}.png').convert('RGBA')) for c in ('clean','worn','dirty')}
    nor=np.array(Image.open(SRC+'/props_base_normal.png').convert('RGB')); orm=np.array(Image.open(SRC+'/props_base_orm.png').convert('RGB'))
else:
    Z=512 if PG=='c' else 1024 if PG in ('w','i','j','k') else int(os.environ.get('PAGE_B_SIZE','1024')); cols={c:np.full((Z,Z,4),(128,128,128,255),np.uint8) for c in ('clean','worn','dirty')}
    nor=np.full((Z,Z,3),(128,128,255),np.uint8); orm=np.full((Z,Z,3),(255,200,0),np.uint8)
    BB=SRC+f'/props_{PG}_base_'   # page B base: tiling trim tiles (trim_regions.py)
    if os.path.exists(BB+'normal.png') and Image.open(BB+'normal.png').size[0]==Z:
        cols={c:np.array(Image.open(f'{BB}color_{c}.png').convert('RGBA')) for c in ('clean','worn','dirty')}
        nor=np.array(Image.open(BB+'normal.png').convert('RGB')); orm=np.array(Image.open(BB+'orm.png').convert('RGB'))
PP='props_' if not PG else f'props_{PG}_'
n=0
for name,rects in S.items():
    if not os.path.exists(f'{T}/{name}_nor.png'): continue
    x,y,w,h=rects[0]
    nn=np.array(Image.open(f'{T}/{name}_nor.png').convert('RGB')); oo=np.array(Image.open(f'{T}/{name}_orm.png').convert('RGB'))
    if nn.shape[0]!=h: continue
    nor[y:y+h,x:x+w]=nn; orm[y:y+h,x:x+w]=oo
    for cond in cols:
        p=f'{T}/{name}_{cond}_col.png'
        if not os.path.exists(p): p=f'{T}/{name}_clean_col.png'
        cols[cond][y:y+h,x:x+w,:3]=np.array(Image.open(p).convert('RGB')); cols[cond][y:y+h,x:x+w,3]=255
    n+=1
def _save(im,p):   # atomic write: concurrent Blender readers never see a half-written PNG
    t=f'{p}.{os.getpid()}.tmp.png'; im.save(t); os.replace(t,p)
if PG in ('w','i','j','k'):   # pages W, I, J, K ship at colour 1024, normal 512, ORM 256 (1.75 MB)
    _save(Image.fromarray(cols['clean']),f'{K}/atlases/{PP}color_clean.png')
    _nn=np.array(Image.fromarray(nor).resize((512,512),Image.LANCZOS)).astype(np.float32)/127.5-1; _nn/=np.maximum(np.linalg.norm(_nn,axis=2,keepdims=True),1e-6)
    _save(Image.fromarray(((_nn*.5+.5)*255+.5).astype(np.uint8)),f'{K}/atlases/{PP}normal.png'); _save(Image.fromarray(orm).resize((256,256),Image.LANCZOS),f'{K}/atlases/{PP}orm.png')
else:
  for c,a in cols.items(): _save(Image.fromarray(a),f'{K}/atlases/{PP}color_{c}.png')
  _save(Image.fromarray(nor),f'{K}/atlases/{PP}normal.png'); _save(Image.fromarray(orm).resize((orm.shape[1]//2,orm.shape[0]//2),Image.LANCZOS),f'{K}/atlases/{PP}orm.png')
print('composed',n,'baked props')
