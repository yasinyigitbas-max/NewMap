"""Texture array for merged room shells (18 Nov, rooms on all shops): every room texture (the interiors' ambientCG set,
map_dc/coronado/shops/interior/assets/tex, plus the kit's pavement for door slabs) as one layer of 512 x 512, plus a
white layer for the plain-coloured parts (frames, skirting, light fittings: their colour rides in the vertex colour).
One array = one material for every room's walls, floors, ceilings and fittings: one draw per room shell.
Writes map_dc/coronado/city_kit/runtime_tex/arr_room.png (+ .import as a 2D array) and arr_room.json (layer names).
Derived data like the other arrays (runtime_tex is not in git). Run from the repo root: python3 -I tools/city/rooms/make_room_array.py
"""
import json
import os
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
TEX = os.path.join(ROOT, "map_dc/coronado/shops/interior/assets/tex")
OUT = os.path.join(ROOT, "map_dc/coronado/city_kit/runtime_tex")
S = 512

IMPORT = """[remap]

importer="2d_array_texture"
type="CompressedTexture2DArray"

[deps]

source_file="res://map_dc/coronado/city_kit/runtime_tex/arr_room.png"

[params]

compress/mode=2
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
slices/horizontal=1
slices/vertical=%d
"""


def main():
    names = sorted({f.rsplit("_", 2)[0] for f in os.listdir(TEX) if f.endswith("_color.jpg")})
    layers = [("white", Image.new("RGB", (S, S), (255, 255, 255)))]
    for n in names:
        f = [x for x in os.listdir(TEX) if x.startswith(n + "_") and x.endswith("_color.jpg")][0]
        layers.append((n, Image.open(os.path.join(TEX, f)).convert("RGB").resize((S, S), Image.LANCZOS)))
    pave = os.path.join(ROOT, "assets/roads/concrete034_color.jpg")
    if os.path.exists(pave):
        layers.append(("pave", Image.open(pave).convert("RGB").resize((S, S), Image.LANCZOS)))
    strip = Image.new("RGB", (S, S * len(layers)))
    for i, (_, im) in enumerate(layers):
        strip.paste(im, (0, i * S))
    os.makedirs(OUT, exist_ok=True)
    strip.save(os.path.join(OUT, "arr_room.png"))
    open(os.path.join(OUT, "arr_room.png.import"), "w").write(IMPORT % len(layers))
    json.dump({"layers": [n for n, _ in layers]}, open(os.path.join(OUT, "arr_room.json"), "w"), indent=1)
    print("ROOM_ARRAY layers=%d -> %s" % (len(layers), os.path.join(OUT, "arr_room.png")))


if __name__ == "__main__":
    main()
