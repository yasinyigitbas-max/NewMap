#!/usr/bin/env python3
"""Texture arrays for the runtime bake (18 Nov). The kit keeps props on 4 atlas pages, plants on 4, and the ground
uses 9 tiling textures; one material per page means one draw per page. Stacked into arrays (one layer per page),
every prop of a cell can share ONE material, every plant another, the whole ground a third.
Writes map_dc/coronado/city_kit/runtime_tex/arr_<name>.png (layers stacked top to bottom, 1024 x 1024 each) with a
Godot .import (2D array, VRAM compressed, mipmaps) and arrays.json (which texture is which layer; bake_runtime.gd
reads it). Sources are never changed. Run from the repo root, then `godot --headless --path . --import`."""
import json, os
from PIL import Image
K = 'assets/coronado_kit/'
OUT = 'map_dc/coronado/city_kit/runtime_tex/'
SIZE = 1024
PROP = ['props', 'props_b', 'props_c', 'props_w', 'props_i']
FOL = ['trees_palms', 'trees_broadleaf', 'trees_conifer', 'trees_shrubs']
SETS = {
    'prop_albedo': [K + 'atlases/%s_color_clean.png' % p for p in PROP],
    'prop_normal': [K + 'atlases/%s_normal.png' % p for p in PROP],
    'prop_orm': [K + 'atlases/%s_orm.png' % p for p in PROP],
    # plants, then the two prop pages whose cut-out parts (chain-link panels) use the same shader
    'fol_albedo': [K + 'atlases/%s_color.png' % p for p in FOL] + [K + 'atlases/props_color_clean.png', K + 'atlases/props_b_color_clean.png'],
    'fol_normal': [K + 'atlases/%s_normal.png' % p for p in FOL] + [K + 'atlases/props_normal.png', K + 'atlases/props_b_normal.png'],
    'ground': ['assets/roads/asphalt026c_color.jpg', 'assets/roads/concrete034_color.jpg', 'map_dc/coronado/terrain/textures/grass004/grass_albedo.jpg',
               'map_dc/coronado/terrain/textures/ground037/dry_albedo.jpg', 'map_dc/coronado/terrain/textures/travertine009/albedo.jpg',
               'assets/roads/roadlines022a_white_worn.png', 'assets/roads/roadlines022a_yellow_worn.png',
               'map_dc/coronado/terrain/textures/gravel022/gravel_albedo.jpg', 'map_dc/coronado/terrain/textures/ground054/sand_albedo.jpg',
               # the fill (21 Nov): the cobble beach and the rock of the bluffs; appended, so the nine layers above keep their numbers
               'map_dc/coronado/terrain/textures/gray_rocks/gray_rocks_diff_1k.jpg', 'map_dc/coronado/terrain/textures/rock030/rock_albedo.jpg'],
}
IMPORT = '''[remap]

importer="2d_array_texture"
type="CompressedTexture2DArray"

[deps]

source_file="res://%s"

[params]

compress/mode=2
compress/high_quality=%s
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
slices/horizontal=1
slices/vertical=%d
'''
os.makedirs(OUT, exist_ok=True)
info = {}
for name, files in SETS.items():
    rgba = name in ('prop_albedo', 'fol_albedo')
    sheet = Image.new('RGBA' if rgba else 'RGB', (SIZE, SIZE * len(files)))
    for i, f in enumerate(files):
        im = Image.open(f).convert('RGBA' if rgba else 'RGB')
        if im.size != (SIZE, SIZE): im = im.resize((SIZE, SIZE), Image.LANCZOS)
        sheet.paste(im, (0, i * SIZE))
    p = OUT + 'arr_%s.png' % name
    sheet.save(p)
    imp = p + '.import'
    if not os.path.exists(imp):     # keep Godot's own file (uid, paths) once it exists
        open(imp, 'w').write(IMPORT % (p, 'true' if 'normal' in name else 'false', len(files)))
    else:                           # ... but with the layer count of now (21 Nov: the ground went from 9 to 11 layers)
        import re
        t = open(imp).read(); t2 = re.sub(r'slices/vertical=\d+', 'slices/vertical=%d' % len(files), t)
        if t2 != t: open(imp, 'w').write(t2)
    info[name] = ['res://' + f for f in files]
    print(name, len(files), 'layers', os.path.getsize(p) // 1024, 'KB')
json.dump(info, open(OUT + 'arrays.json', 'w'), indent=1)
