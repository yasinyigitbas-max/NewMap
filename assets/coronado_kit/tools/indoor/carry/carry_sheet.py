"""contact sheet of all carry props (hero + back), label: name, near tris / budget, bake slot, hold"""
import json, sys
from PIL import Image, ImageDraw, ImageFont
m=json.load(open('kit/props/manifest_incarry.json')); s=json.load(open('kit/props/_bake/slots_j.json'))['slots']
order=['bag_paper_kraft','bag_paper_boutique','bag_paper_grocery','bag_plastic_thankyou','bag_plastic_corner','bag_tote_woven',
 'briefcase_leather','briefcase_aluminium','briefcase_laptop','backpack_daypack','backpack_school','backpack_canvas',
 'box_ship_small','box_moving','box_open','box_long','box_stack','box_produce','crate_produce','crate_wine','crate_rope']
T=300; cols=4; rows=(len(order)+cols-1)//cols; W=2*T
S=Image.new('RGB',(W*cols,(T+44)*rows+60),(32,32,34)); d=ImageDraw.Draw(S)
f=ImageFont.truetype('/usr/share/fonts/truetype/sand-box/google/Barlow Condensed/BarlowCondensed-Bold.ttf',22)
fs=ImageFont.truetype('/usr/share/fonts/truetype/sand-box/google/Barlow Condensed/BarlowCondensed-Bold.ttf',18)
d.text((12,14),'NewMap carry props - page J (1024): 21 props, red dots = grip_r / grip_l',fill=(255,220,120),font=f)
for i,n in enumerate(order):
    x=(i%cols)*W; y=60+(i//cols)*(T+44)
    for k,v in enumerate(('hero','back')):
        S.paste(Image.open(f'renders/final/{n}_f_{v}.png').convert('RGB').resize((T,T)),(x+k*T,y))
    e=m[n]; sl=s.get(n); tex=f'slot {sl[0][2]} px' if sl else 'trims only'
    hold='2 hands' if e['grips']['hold']=='two_hand_sides' else '1 hand'
    d.text((x+8,y+T+4),n,fill=(255,255,255),font=f)
    d.text((x+8+250,y+T+8),f"{e['tiers']['near']}/{e['budget']} tris  ·  {tex}  ·  {hold}",fill=(200,200,200),font=fs)
S.save(sys.argv[1]); print(S.size)
