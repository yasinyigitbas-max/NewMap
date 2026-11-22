#!/bin/bash
# quick review pass: grips + occlusion fix + hero/back renders for the given props -> renders/r/<tag>_sheet.png
cd /workspace/coronado_kit_v2/_staging/carry; T=$1; shift
G=()
for N in "$@"; do
  IN_KIT=$PWD/kit python3 kit/props/_tools/c_grips.py incarry $N >/dev/null
  python3 fix_occ.py kit/props/indoor/carry/prop_${N}_clean_near.glb >/dev/null
  G+=(kit/props/indoor/carry/prop_${N}_clean_near.glb)
done
CR_VIEWS=${CR_VIEWS:-hero,back} CR_RES=${CR_RES:-480} CR_SAMPLES=${CR_SAMPLES:-12} ./rend.sh renders/r $T "${G[@]}"
python3 - "$T" "$@" <<'P'
import sys; from PIL import Image, ImageDraw
T=sys.argv[1]; ns=sys.argv[2:]; import os
vs=[v for v in os.environ.get('CR_VIEWS','hero,back').split(',')]
ims=[]
for n in ns:
    row=[Image.open(f'renders/r/{n}_{T}_{v}.png').convert('RGB') for v in vs if os.path.exists(f'renders/r/{n}_{T}_{v}.png')]
    if row: ims.append((n,row))
w=sum(i.width for i in ims[0][1]); h=ims[0][1][0].height
cols=2; rows=(len(ims)+1)//2
S=Image.new('RGB',(w*cols,h*rows),(40,40,40)); d=ImageDraw.Draw(S)
for k,(n,row) in enumerate(ims):
    x=(k%cols)*w; y=(k//cols)*h
    for im in row: S.paste(im,(x,y)); x+=im.width
    d.text(((k%cols)*w+6,y+6),n,fill=(255,255,0))
S.save(f'renders/r/{T}_sheet.png'); print('SHEET',f'renders/r/{T}_sheet.png',S.size)
P
