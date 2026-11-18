#!/usr/bin/env python3
"""Vertical contact sheet from official four-side previews."""
import sys, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

def counts_from_check(names, root):
    # prefer manifest if present; else leave blank
    return {}

def main():
    batch=sys.argv[1]
    names=sys.argv[2:]
    root=Path('/workspace/coronado_kit_v2/_staging/indoor')
    kit=root/'kit'
    # try manifest for near counts
    man=kit/'props'/f'manifest_{batch}.json'
    counts={}
    if man.exists():
        d=json.loads(man.read_text())
        recs=d if isinstance(d,list) else d.get('props') or d.get('items') or []
        if isinstance(d,dict) and not recs:
            recs=list(d.values()) if d and isinstance(next(iter(d.values()),None),dict) else []
        for r in recs if isinstance(recs,list) else []:
            if not isinstance(r,dict):
                continue
            n=r.get('name') or r.get('file_base','')
            n=n.replace('prop_','')
            tiers=r.get('tiers') or {}
            near=None
            if 'near' in tiers and isinstance(tiers['near'],dict):
                near=tiers['near'].get('tris') or tiers['near'].get('triangles')
            near=near or r.get('near') or r.get('tris')
            bud=r.get('budget')
            if n and near:
                counts[n]=(near,bud)
    src=kit/'previews'/f'indoor_{batch.replace("in","")}' if False else None
    # pdir convention: indoor_<cat>
    # guess from first preview dir that contains prop_<name>
    pdir=None
    for cand in (kit/'previews').iterdir() if (kit/'previews').exists() else []:
        if (cand/f'prop_{names[0]}.png').exists():
            pdir=cand; break
    if pdir is None:
        sys.exit(f'no previews for {names[0]}')
    out=root/'previews'/f'indoor_{pdir.name.replace("indoor_","")}_sheet.png'
    # if pdir is indoor_grocery, sheet is indoor_grocery_sheet.png — good
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
            near,bud=counts[n]
            extra=f'    near {near}' + (f' / {bud}' if bud else '')
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
