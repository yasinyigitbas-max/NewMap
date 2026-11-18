"""contact sheet: rows of renders with labels.  python3 wf_sheet.py out.png title 'label=img' ['label=img|label=img' (side by side)] ..."""
import sys
from PIL import Image, ImageDraw, ImageFont
out,title=sys.argv[1],sys.argv[2]; rows=sys.argv[3:]; W=1800
try: F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',22); FT=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',30)
except Exception: F=FT=ImageFont.load_default()
ims=[]
for r in rows:
    cells=[c.split('=',1) for c in r.split('|')]; w=W//len(cells); line=[]
    for lab,p in cells:
        im=Image.open(p).convert('RGB'); im=im.resize((w,int(im.height*w/im.width)),Image.LANCZOS); line.append((lab,im))
    h=max(im.height for _,im in line); row=Image.new('RGB',(W,h+34),(245,245,245)); x=0; d=ImageDraw.Draw(row)
    for lab,im in line: row.paste(im,(x,34)); d.text((x+8,5),lab,fill=(20,20,20),font=F); x+=w
    ims.append(row)
H=50+sum(i.height for i in ims); S=Image.new('RGB',(W,H),(245,245,245)); d=ImageDraw.Draw(S); d.text((12,10),title,fill=(0,0,0),font=FT); y=50
for i in ims: S.paste(i,(0,y)); y+=i.height
S.save(out); print(out,S.size)
