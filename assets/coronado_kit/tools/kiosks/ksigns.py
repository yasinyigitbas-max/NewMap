"""Hand-drawn (PIL) printed / painted sign artwork for the kiosks. Generic, unbranded wording only.
draw(sign_id, w_m, h_m, px_per_m) -> RGBA float image (H, W, 4) in sRGB 0..1, top row = top of the sign."""
import math, glob
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
G = '/usr/share/fonts/truetype/sand-box/google/'
def F(name, size):
    f = glob.glob(G+name+'/*.ttf'); return ImageFont.truetype(sorted(f)[0], max(int(size), 6))
BEBAS, OSWALD, PACIFICO, MARKER, ALFA, LUCKY, CHEWY, KALAM, LOBSTER, SHRIK, TITAN, RIGHT = (
    'Bebas Neue', 'Oswald', 'Pacifico', 'Permanent Marker', 'Alfa Slab One', 'Luckiest Guy', 'Chewy', 'Kalam', 'Lobster', 'Shrikhand',
    'Titan One', 'Righteous')

def text(d, xy, s, font, fill, anchor='mm', stroke=0, sfill=None):
    d.text(xy, s, font=font, fill=fill, anchor=anchor, stroke_width=stroke, stroke_fill=sfill)

def fit_font(name, s, max_w, max_h):
    size = int(max_h)
    while size > 6:
        f = F(name, size); bb = f.getbbox(s)
        if bb[2]-bb[0] <= max_w and bb[3]-bb[1] <= max_h: return f
        size = int(size*0.92)
    return F(name, 6)

# ---------------------------------------------------------------- little illustrations
def hotdog_icon(d, cx, cy, s):
    d.ellipse([cx-s*1.1, cy-s*0.28, cx+s*1.1, cy+s*0.42], fill=(214, 150, 70))           # bun back
    d.rounded_rectangle([cx-s*1.25, cy-s*0.22, cx+s*1.25, cy+s*0.12], radius=s*0.17, fill=(160, 52, 34))  # sausage
    pts = [(cx-s*1.0+i*s*0.25, cy-s*0.05 + (s*0.08 if i % 2 else -s*0.08)) for i in range(9)]
    d.line(pts, fill=(250, 205, 30), width=max(int(s*0.09), 1))                          # mustard
    d.chord([cx-s*1.15, cy-s*0.1, cx+s*1.15, cy+s*0.55], 0, 180, fill=(232, 176, 92))    # bun front
def popsicle_icon(d, cx, cy, s, col, bite=False):
    d.rectangle([cx-s*0.07, cy+s*0.45, cx+s*0.07, cy+s*0.95], fill=(222, 190, 140))
    d.rounded_rectangle([cx-s*0.32, cy-s*0.7, cx+s*0.32, cy+s*0.5], radius=s*0.3, fill=col)
    d.rounded_rectangle([cx-s*0.2, cy-s*0.6, cx-s*0.1, cy+s*0.2], radius=s*0.05, fill=tuple(min(255, int(c*1.25+30)) for c in col))
    if bite: d.ellipse([cx+s*0.12, cy-s*0.85, cx+s*0.5, cy-s*0.45], fill=(0, 0, 0, 0))
def lemon_icon(d, cx, cy, s, col=(250, 214, 40)):
    d.ellipse([cx-s*0.6, cy-s*0.42, cx+s*0.6, cy+s*0.42], fill=col, outline=(200, 160, 20), width=max(int(s*0.04), 1))
    d.ellipse([cx+s*0.5, cy-s*0.1, cx+s*0.7, cy+s*0.1], fill=col)
    d.polygon([(cx-s*0.1, cy-s*0.38), (cx+s*0.25, cy-s*0.75), (cx+s*0.4, cy-s*0.5)], fill=(70, 150, 60))
def taco_icon(d, cx, cy, s):
    d.chord([cx-s, cy-s*0.8, cx+s, cy+s*0.9], 180, 360, fill=(236, 190, 90))
    for i, c in enumerate([(70, 160, 60), (200, 40, 30), (240, 240, 230), (120, 70, 40)]):
        d.ellipse([cx-s*0.75+i*s*0.38, cy-s*0.55, cx-s*0.3+i*s*0.38, cy-s*0.1], fill=c)
    d.chord([cx-s*0.95, cy-s*0.7, cx+s*0.95, cy+s*0.85], 180, 360, outline=(196, 140, 50), width=max(int(s*0.08), 1))
def shaveice_icon(d, cx, cy, s, cols=((240, 60, 80), (255, 170, 30), (70, 140, 240))):
    d.polygon([(cx-s*0.55, cy), (cx+s*0.55, cy), (cx+s*0.38, cy+s*0.9), (cx-s*0.38, cy+s*0.9)], fill=(250, 250, 245), outline=(200, 200, 200))
    for i, c in enumerate(cols):
        d.pieslice([cx-s*0.62, cy-s*0.75, cx+s*0.62, cy+s*0.45], 180+i*60, 240+i*60, fill=c)
def wave(d, x0, y0, x1, amp, per, col, width):
    pts = [(x, y0 + amp*math.sin((x-x0)/per*2*math.pi)) for x in np.linspace(x0, x1, 80)]
    d.line(pts, fill=col, width=width)
def palm(d, x, y, s, col):
    d.line([(x, y), (x+s*0.15, y-s*1.2)], fill=col, width=max(int(s*0.08), 1))
    for a in (-160, -125, -90, -55, -20):
        r = math.radians(a); d.line([(x+s*0.15, y-s*1.2), (x+s*0.15+s*0.6*math.cos(r), y-s*1.2+s*0.6*math.sin(r)*0.6+s*0.15)], fill=col, width=max(int(s*0.07), 1))

# ---------------------------------------------------------------- signs
def draw(sid, w_m, h_m, ppm):
    W = max(int(w_m*ppm*2), 16); H = max(int(h_m*ppm*2), 16)   # drawn at 2x, downsampled
    im = Image.new('RGBA', (W, H), (255, 255, 255, 255)); d = ImageDraw.Draw(im)
    u = min(W, H)
    if sid == 'hotdog_front':
        d.rectangle([0, 0, W, H], fill=(22, 76, 158))
        d.rectangle([0, int(H*0.70), W, H], fill=(246, 196, 34))
        d.rectangle([0, int(H*0.68), W, int(H*0.70)], fill=(250, 250, 245))
        text(d, (W*0.40, H*0.33), 'HOT DOGS', fit_font(LUCKY, 'HOT DOGS', W*0.62, H*0.42), (250, 206, 40), stroke=int(u*0.025), sfill=(160, 30, 30))
        hotdog_icon(d, W*0.84, H*0.36, u*0.22)
        text(d, (W*0.5, H*0.85), 'HOT DOG $4   CHILI DOG $5   SODA $2   CHIPS $1.50', fit_font(OSWALD, 'HOT DOG $4   CHILI DOG $5   SODA $2   CHIPS $1.50', W*0.92, H*0.18), (30, 40, 70))
        text(d, (W*0.40, H*0.60), 'ALL BEEF  ·  GRILLED FRESH', fit_font(OSWALD, 'ALL BEEF  ·  GRILLED FRESH', W*0.6, H*0.1), (235, 240, 250))
    elif sid == 'hotdog_pole':
        d.rectangle([0, 0, W, H], fill=(246, 196, 34))
        d.rectangle([int(u*0.03), int(u*0.03), W-int(u*0.03), H-int(u*0.03)], outline=(22, 76, 158), width=int(u*0.03))
        text(d, (W*0.5, H*0.38), 'HOT DOGS', fit_font(LUCKY, 'HOT DOGS', W*0.84, H*0.42), (190, 30, 30), stroke=int(u*0.015), sfill=(255, 255, 255))
        text(d, (W*0.5, H*0.76), 'COLD DRINKS', fit_font(OSWALD, 'COLD DRINKS', W*0.7, H*0.22), (22, 76, 158))
    elif sid == 'paleta_side':
        d.rectangle([0, 0, W, H], fill=(250, 250, 246))
        for i, c in enumerate([(230, 60, 90), (255, 160, 30), (120, 190, 60), (70, 150, 230), (160, 90, 200)]):
            d.rectangle([int(W*i/5), int(H*0.86), int(W*(i+1)/5), H], fill=c)
        text(d, (W*0.5, H*0.22), 'PALETAS', fit_font(SHRIK, 'PALETAS', W*0.8, H*0.3), (220, 40, 90), stroke=int(u*0.02), sfill=(255, 255, 255))
        cols = [(240, 70, 80), (255, 190, 40), (130, 200, 80), (250, 140, 170), (120, 80, 50), (90, 170, 240)]
        for i, c in enumerate(cols):
            popsicle_icon(d, W*(0.1+i*0.16), H*0.56, u*0.26, c)
        text(d, (W*0.5, H*0.79), 'FRUTA FRESCA  ·  HELADOS', fit_font(OSWALD, 'FRUTA FRESCA  ·  HELADOS', W*0.8, H*0.08), (60, 60, 70))
    elif sid == 'paleta_front':
        d.rectangle([0, 0, W, H], fill=(250, 250, 246))
        text(d, (W*0.5, H*0.3), 'PALETAS', fit_font(SHRIK, 'PALETAS', W*0.84, H*0.36), (230, 60, 100), stroke=int(u*0.02), sfill=(255, 255, 255))
        for i, c in enumerate([(240, 70, 80), (255, 190, 40), (130, 200, 80)]):
            popsicle_icon(d, W*(0.3+i*0.2), H*0.7, u*0.22, c)
    elif sid == 'taco_banner':
        d.rectangle([0, 0, W, H], fill=(250, 244, 226))
        cols = [(214, 40, 40), (250, 160, 30), (40, 150, 80), (40, 90, 170), (230, 70, 140)]
        n = 30
        for i in range(n):  # papel picado band
            c = cols[i % 5]; x0 = W*i/n; x1 = W*(i+1)/n
            d.polygon([(x0, 0), (x1, 0), (x1, H*0.12), ((x0+x1)/2, H*0.17), (x0, H*0.12)], fill=c)
        text(d, (W*0.40, H*0.59), 'TACOS', fit_font(ALFA, 'TACOS', W*0.50, H*0.80), (190, 24, 24), stroke=max(int(u*0.03), 2), sfill=(255, 255, 255))
        taco_icon(d, W*0.10, H*0.80, u*0.58)
        menu = ['AL PASTOR', 'ASADA', 'POLLO']
        for i, s in enumerate(menu):
            text(d, (W*0.84, H*(0.32+i*0.24)), s+'  $3', fit_font(OSWALD, 'AL PASTOR  $3', W*0.26, H*0.21), (40, 40, 40))
    elif sid == 'taco_chalk':
        d.rectangle([0, 0, W, H], fill=(38, 44, 40))
        text(d, (W*0.5, H*0.13), 'TACOS', fit_font(MARKER, 'TACOS', W*0.8, H*0.16), (250, 210, 70))
        lines = [('AL PASTOR', '$3'), ('ASADA', '$3'), ('POLLO', '$3'), ('PESCADO', '$4'), ('BURRITO', '$10'), ('AGUA FRESCA', '$3')]
        for i, (a, b) in enumerate(lines):
            y = H*(0.30+i*0.11)
            col = [(240, 240, 235), (250, 170, 170), (170, 230, 250)][i % 3]
            text(d, (W*0.08, y), a, F(KALAM, H*0.07), col, anchor='lm'); text(d, (W*0.92, y), b, F(KALAM, H*0.07), col, anchor='rm')
        wave(d, W*0.1, H*0.95, W*0.9, H*0.01, W*0.1, (240, 240, 235), max(int(u*0.01), 1))
    elif sid == 'shave_fascia':
        d.rectangle([0, 0, W, H], fill=(250, 246, 232))
        wave(d, 0, H*0.86, W, H*0.03, W*0.12, (40, 170, 190), max(int(H*0.05), 2))
        wave(d, 0, H*0.95, W, H*0.03, W*0.12, (25, 120, 170), max(int(H*0.05), 2))
        text(d, (W*0.5, H*0.42), 'Shave Ice', fit_font(PACIFICO, 'Shave Ice', W*0.6, H*0.62), (232, 70, 110), stroke=int(H*0.025), sfill=(255, 255, 255))
        shaveice_icon(d, W*0.1, H*0.3, H*0.38); shaveice_icon(d, W*0.9, H*0.3, H*0.38, ((250, 220, 40), (80, 200, 120), (240, 90, 160)))
    elif sid == 'shave_menu':
        d.rectangle([0, 0, W, H], fill=(250, 250, 244))
        d.rectangle([0, 0, W, int(H*0.16)], fill=(30, 150, 170))
        text(d, (W*0.5, H*0.08), 'FLAVORS', fit_font(BEBAS, 'FLAVORS', W*0.8, H*0.12), (255, 255, 255))
        fl = [('MANGO', (255, 170, 30)), ('LILIKOI', (250, 210, 60)), ('STRAWBERRY', (230, 40, 60)), ('BLUE RASPBERRY', (40, 110, 230)),
              ('COCONUT', (240, 240, 235)), ('LIME', (120, 210, 60)), ('GRAPE', (130, 60, 170)), ('CHERRY', (190, 20, 40))]
        for i, (s, c) in enumerate(fl):
            y = H*(0.22+i*0.085)
            d.ellipse([W*0.08, y-H*0.03, W*0.08+H*0.06, y+H*0.03], fill=c, outline=(80, 80, 80))
            text(d, (W*0.08+H*0.09, y), s, fit_font(OSWALD, 'BLUE RASPBERRY', W*0.7, H*0.06), (50, 50, 60), anchor='lm')
        text(d, (W*0.5, H*0.93), 'SMALL $4  ·  LARGE $6', fit_font(OSWALD, 'SMALL $4  ·  LARGE $6', W*0.86, H*0.07), (232, 70, 110))
    elif sid == 'lemon_front':
        d.rectangle([0, 0, W, H], fill=(250, 248, 238))
        text(d, (W*0.5, H*0.28), 'Fresh', fit_font(LOBSTER, 'Fresh', W*0.4, H*0.3), (60, 140, 60))
        text(d, (W*0.5, H*0.62), 'LEMONADE', fit_font(TITAN, 'LEMONADE', W*0.8, H*0.34), (246, 196, 20), stroke=int(u*0.02), sfill=(150, 110, 10))
        for x in (0.1, 0.9): lemon_icon(d, W*x, H*0.45, u*0.25)
        text(d, (W*0.5, H*0.88), 'SQUEEZED TO ORDER', fit_font(OSWALD, 'SQUEEZED TO ORDER', W*0.6, H*0.1), (90, 90, 90))
    elif sid == 'lemon_chalk':
        d.rectangle([0, 0, W, H], fill=(40, 46, 42))
        text(d, (W*0.5, H*0.12), 'TODAY', fit_font(MARKER, 'TODAY', W*0.7, H*0.13), (250, 230, 90))
        for i, (a, b) in enumerate([('LEMONADE', '$4'), ('STRAWBERRY', '$5'), ('ORANGE JUICE', '$5'), ('ICED TEA', '$3')]):
            y = H*(0.33+i*0.15); col = [(250, 240, 120), (250, 160, 170), (250, 190, 110), (220, 240, 230)][i]
            text(d, (W*0.07, y), a, fit_font(KALAM, 'ORANGE JUICE', W*0.62, H*0.085), col, anchor='lm'); text(d, (W*0.93, y), b, F(KALAM, H*0.085), col, anchor='rm')
        lemon_icon(d, W*0.8, H*0.12, u*0.1)
    else:
        d.rectangle([0, 0, W, H], fill=(200, 200, 200))
    im = im.resize((W//2, H//2), Image.LANCZOS)
    return np.asarray(im).astype(np.float32)/255.0

if __name__ == '__main__':
    import sys
    for sid, w, h in (('hotdog_front', 1.04, 0.40), ('hotdog_pole', 0.44, 0.3), ('paleta_side', 0.8, 0.4), ('taco_banner', 2.9, 0.4),
                      ('taco_chalk', 0.6, 0.85), ('shave_fascia', 2.6, 0.45), ('shave_menu', 0.55, 0.8), ('lemon_front', 1.5, 0.6), ('lemon_chalk', 0.45, 0.6)):
        a = draw(sid, w, h, 300); Image.fromarray((a*255).astype(np.uint8)).save(f'/tmp/sign_{sid}.png')
    print('ok')
