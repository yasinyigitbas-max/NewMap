"""batch-2 contact sheets, one per group: per piece 4 near views (1.8 m figure) + the near|mid|far tier strip, and a
check line (tris per tier, page-W slot, collision, railcheck, far match)"""
import json,os,sys
from PIL import Image, ImageDraw, ImageFont
B='/workspace/coronado_kit_v2/_staging/props_batch2'; K='/workspace/coronado_kit_v2/_staging/waterfront/kit'
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',19); FB=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',22); FT=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',30)
GROUP={'signage':['pylon_sign','drive_thru_menu','bus_stop_sign'],'motel':['vending_soda','vending_snack','ice_chest'],
       'parking':['wheel_stop_concrete','wheel_stop_rubber','shopping_cart','cart_corral'],'residential':['balcony_clutter','dingbat_stair','buzzer_panel','clothesline']}
S=json.load(open(K+'/props/_bake/slots_w.json'))['slots']
man={}
for b in ('b2a','b2b'):
    p=K+f'/props/manifest_{b}.json'
    if os.path.exists(p): man.update({k:dict(v,_b=b) for k,v in json.load(open(p)).items()})
W=2200; CW=W//5
for g,ns in GROUP.items():
    blocks=[]
    for n in ns:
        r=json.load(open(f'{B}/reports/{n}.json')); t=r['tiers']; sl=S[n][0]
        fm=r['far_match']; rc=r.get('rail_ok'); cs=r['col_split']
        try: nre=len(eval(r['railcheck'])) if rc is not None else 0
        except Exception: nre=0
        l1=f"{n}  [{r['class']}]   near {t['near']}/{r['budget']}  ·  mid {t['mid']}  ·  far {t['far']}   ·   page W slot {sl[2]}² ({man[n].get('bake_px_per_m','?')} px/m)   ·   {'PASS' if r['pass'] else 'FAIL'}"
        l2=(f"collision {cs['main']} main + {cs['rail']} rail   ·   railcheck {'PASS' if rc else 'FAIL'} ({nre} rail ends)" if rc is not None else f"collision {cs['main']} main + {cs['rail']} rail   ·   railcheck n/a (no rails)")+ \
           f"   ·   far match front IoU {fm['front']['iou']:.2f} ΔE {fm['front']['dE']:.1f}, top IoU {fm['top']['iou']:.2f} ΔE {fm['top']['dE']:.1f}   ·   validator {'PASS' if r['validator_ok'] else 'FAIL'}   ·   UV source {'PASS' if r['uvsrc_ok'] else 'FAIL'}"
        cells=[Image.open(f'{B}/work/r_{n}_{i}.png').convert('RGB') for i in range(4)]
        tp=f"{K}/previews/props_{man[n]['_b']}/prop_{n}.png"
        cells.append(Image.open(tp).convert('RGB') if os.path.exists(tp) else Image.new('RGB',(560,420),(200,200,200)))
        cells=[c.resize((CW,int(c.height*CW/c.width)),Image.LANCZOS) for c in cells]
        h=max(c.height for c in cells)
        blk=Image.new('RGB',(W,h+64),(246,246,246)); d=ImageDraw.Draw(blk)
        d.text((10,4),l1,fill=(10,10,10) if r['pass'] else (170,0,0),font=FB); d.text((10,34),l2,fill=(40,40,40),font=F)
        for i,c in enumerate(cells): blk.paste(c,(i*CW,64))
        d.text((4*CW+8,68),'tiers: near | mid | far',fill=(20,20,20),font=F)
        blocks.append(blk)
    H=60+sum(b.height+8 for b in blocks); sh=Image.new('RGB',(W,H),(225,225,225)); d=ImageDraw.Draw(sh)
    d.text((14,12),f'Coronado kit · props batch 2 · {g}   (staging, page W, clean)',fill=(0,0,0),font=FT); y=60
    for b in blocks: sh.paste(b,(0,y)); y+=b.height+8
    out=f'{B}/previews/props_batch2_{g}_sheet.png'; sh.save(out); print(out,sh.size)
