"""pilot sheet: six near views + scale reference + the page-J bake tile, with tris / texture stats"""
import sys,json
from PIL import Image,ImageDraw,ImageFont
out,tag,name=sys.argv[1:4]
K='kit/'; M=json.load(open(K+'props/manifest_incarry.json'))[name]; S=json.load(open(K+'props/_bake/slots_j.json'))['slots'][name][0]
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',30); f2=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',21); f3=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',20)
T=460; W=3*T+700; H=110+2*(T+34)+40
I=Image.new('RGB',(W,H),(30,31,34)); d=ImageDraw.Draw(I)
d.text((20,16),f'Carry props pilot - {name}  (paper shopping bag, kraft, twisted-cord handles)',font=F,fill=(240,240,240))
d.text((20,58),f"near {M['tiers']['near']} tris / budget {M['budget']} (tiny)  |  1 material, page J (new)  |  bake slot {S[2]}x{S[3]} px = {100*S[2]*S[3]/1024**2:.1f}% of page J  |  "
       f"{M['footprint_w']:.2f} x {M['footprint_d']:.2f} x {M['height']:.2f} m  |  col: 1 box  |  grip_r / grip_l (red dot)",font=f2,fill=(170,220,170))
views=['hero','front','side','back','top','low']
for i,v in enumerate(views):
    x=20+(i%3)*T; y=110+(i//3)*(T+34)
    I.paste(Image.open(f'renders/p/{name}_{tag}_{v}.png').convert('RGB').resize((T-10,T-10),Image.LANCZOS),(x,y))
    d.text((x+6,y+T-6),v,font=f3,fill=(220,220,220))
sc=Image.open(f'renders/p/{name}_{tag}_scale.png').convert('RGB'); sw=600; sh=int(sc.size[1]*sw/sc.size[0]); sc=sc.resize((sw,sh),Image.LANCZOS).crop((0,int(sh*0.12),sw,int(sh*0.12)+620))
I.paste(sc,(20+3*T,110)); d.text((30+3*T,110+626),'scale: 1.8 m figure, carried by grip_r + on the floor',font=f3,fill=(220,220,220))
at=Image.open(K+'atlases/props_j_color_clean.png').convert('RGB'); x0,y0,w0,h0=S
tile=at.crop((x0,y0,x0+w0,y0+h0)).resize((300,300),Image.NEAREST).transpose(Image.FLIP_TOP_BOTTOM); I.paste(tile,(20+3*T,110+660))
d.text((330+3*T,110+670),'bake tile (page J, 192 px, shown upright)',font=f3,fill=(220,220,220))
d.text((330+3*T,110+700),'front/back share it (180 deg)',font=f2,fill=(180,180,180))
d.text((330+3*T,110+730),'inside + glue patch: tiling',font=f2,fill=(180,180,180))
d.text((330+3*T,110+756),'kraft cell (no extra space)',font=f2,fill=(180,180,180))
I.save(out); print(out,I.size)
