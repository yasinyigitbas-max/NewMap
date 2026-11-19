#!/usr/bin/env python3
"""Contact sheet from official four-side previews, with near / budget labels."""
import sys, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

def main():
    batch=sys.argv[1]
    names=sys.argv[2:]
    root=Path('/workspace/coronado_kit_v2/_staging/house')
    kit=root/'kit'
    man=kit/'props'/f'manifest_{batch}.json'
    counts={}
    if man.exists():
        d=json.loads(man.read_text())
        recs=d if isinstance(d,list) else list(d.values()) if isinstance(d,dict) else []
        for r in recs:
            if not isinstance(r,dict):
                continue
            n=(r.get('name') or r.get('file_base','')).replace('prop_','')
            tiers=r.get('tiers') or {}
            near=tiers.get('near') if isinstance(tiers,dict) else None
            if isinstance(near,dict):
                near=near.get('tris') or near.get('triangles')
            near=near or r.get('near') or r.get('tris')
            bud=r.get('budget')
            cls=r.get('class')
            if n and near:
                counts[n]=(near,bud,cls)
    if not names and man.exists():
        d=json.loads(man.read_text())
        names=list(d.keys()) if isinstance(d,dict) else []
    pdir=None
    pre=kit/'previews'
    if names and pre.exists():
        for cand in sorted(pre.iterdir()):
            if cand.is_dir() and (cand/f'prop_{names[0]}.png').exists():
                pdir=cand; break
    if pdir is None:
        sys.exit(f'no previews for {names[:1]}')
    out=root/'previews'/f'{pdir.name}_sheet.png'
    W=2000
    label_h=36
    try:
        font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 22)
    except Exception:
        font=ImageFont.load_default()
    rows=[]
    for n in names:
        im=Image.open(pdir/f'prop_{n}.png').convert('RGB')
        im=im.resize((W, int(im.height*W/im.width)), Image.Resampling.LANCZOS)
        bar=Image.new('RGB',(W,label_h+im.height),(245,245,242))
        d=ImageDraw.Draw(bar)
        d.rectangle((0,0,W,label_h), fill=(40,44,48))
        extra=''
        if n in counts:
            near,bud,cls=counts[n]
            extra=f'    near {near}' + (f' / {bud}' if bud else '') + (f'  {cls}' if cls else '')
        d.text((12,6), f'{n}{extra}', fill=(245,245,242), font=font)
        bar.paste(im,(0,label_h))
        rows.append(bar)
    H=sum(r.height for r in rows)
    sheet=Image.new('RGB',(W,H),(245,245,242))
    y=0
    for r in rows:
        sheet.paste(r,(0,y)); y+=r.height
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, optimize=True)
    print('wrote', out, sheet.size, out.stat().st_size)

if __name__=='__main__':
    main()
