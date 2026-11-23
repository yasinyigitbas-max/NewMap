"""The main character's skin: ken1138_caucasian_male_tattooed_skin (CC0) with a SLEEVE on each forearm - the knotwork
from rehmanpolanski_skin_viking_tattoos (CC0, the shoulders' pieces) laid into the forearm islands of the MakeHuman UV
(found from the Game-engine rig's lowerarm groups: right x 20-225, left x 1320-1535, y 235-470 of 2048), as ink: the
piece's darkening against its own skin multiplied onto Ken's skin. Writes the texture and a .mhmat beside it in MPFB's
skins folder (hero_tattooed_skin), which make_hero.py uses.
  python3 -I tools/people/mpfb/hero_skin.py <mpfb data dir>"""
import os, sys, shutil
from PIL import Image, ImageFilter, ImageChops

D = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.config/blender/5.3/mpfb/data")
ken = os.path.join(D, "skins", "ken1138_caucasian_male_tattooed_skin")
vik = os.path.join(D, "skins", "rehmanpolanski_skin_viking_tattoos", "viking_male_diffuse.png")
out = os.path.join(D, "skins", "hero_tattooed_skin"); os.makedirs(out, exist_ok=True)
skin = Image.open(os.path.join(ken, "Caucasion_TatooedMale_Skin_Difuse.png")).convert("RGB")
v = Image.open(vik).convert("RGB")
vs = v.width / 2048.0
def ink(box):
    """the piece's ink: its colour over its own blurred skin (1 = no ink), a multiply layer"""
    c = v.crop(tuple(int(b * vs) for b in box))
    bg = c.filter(ImageFilter.GaussianBlur(radius=max(4, c.width // 6)))
    bg = Image.eval(bg, lambda x: max(x, 1))
    r = Image.merge("RGB", [Image.eval(ImageChops.multiply(a, Image.new("L", a.size, 255)), lambda x: x) for a in c.split()])
    # ratio c / bg per channel, darkened a little for fresh ink
    import numpy as np
    a = np.asarray(c, dtype=np.float32); b = np.asarray(bg, dtype=np.float32)
    k = np.clip(a / b, 0.0, 1.0) ** 1.3
    return k
import numpy as np
S = np.asarray(skin, dtype=np.float32)
def lay(k, x0, y0, w, h, rot=0):
    im = Image.fromarray((k * 255).astype(np.uint8))
    if rot: im = im.rotate(rot, expand=True)
    im = im.resize((w, h), Image.LANCZOS)
    kk = np.asarray(im, dtype=np.float32) / 255.0
    S[y0:y0 + h, x0:x0 + w] *= kk
# (the knotwork pieces on the viking's shoulders: left and right of his neck)
k1 = ink((440, 45, 690, 350)); k2 = ink((863, 45, 1126, 350))
lay(k1, 35, 250, 180, 200, rot=90)     # (his right forearm)
lay(k2, 1335, 250, 180, 200, rot=-90)  # (his left forearm)
Image.fromarray(np.clip(S, 0, 255).astype(np.uint8)).save(os.path.join(out, "hero_tattooed_skin_diffuse.png"))
m = open(os.path.join(ken, "ken1138_caucasian_male_tattooed_skin.mhmat")).read()
m = m.replace("Caucasion_TatooedMale_Skin_Difuse.png", "hero_tattooed_skin_diffuse.png").replace("ken1138_caucasian_male_tattooed_skin", "hero_tattooed_skin")
open(os.path.join(out, "hero_tattooed_skin.mhmat"), "w").write(m)
print("SKIN", out)
