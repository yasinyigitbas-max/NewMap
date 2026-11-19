#!/usr/bin/env python3
"""Tight 3/4 close-up contact sheet for house decor.

One tile per prop, no 1.8 m figure, ortho camera auto-framed so the
prop fills about 80 % of the tile. Writes previews/house_decor_detail.jpg.

Run (only when no other Blender is on the box):

    /workspace/coronado_kit_v2/_staging/house/tools/h_detail.sh

or:

    blender -b -noaudio -t 2 --python-exit-code 1 -P tools/h_detail.py
    python3 tools/h_detail.py --composite
"""
from __future__ import annotations
import math, os, sys, json
from pathlib import Path

ROOT = Path('/workspace/coronado_kit_v2/_staging/house')
KIT = Path(os.environ.get('IN_KIT', ROOT/'kit'))
TILE_DIR = ROOT/'previews'/'house_decor_detail_tiles'
OUT = ROOT/'previews'/'house_decor_detail.jpg'
TILE = 512
FILL = 0.80
SAMPLES = 32

def names_from_man(man):
    d=json.loads(Path(man).read_text())
    if isinstance(d, dict):
        # run.py writes {name: rec}
        return list(d.keys())
    names=[]
    for r in d:
        n=(r.get('name') or r.get('file_base','')).replace('prop_','')
        if n: names.append(n)
    return names

def all_manifests(batch=None):
    if batch:
        man=KIT/'props'/f'manifest_{batch}.json'
        if not man.exists():
            raise SystemExit(f'missing {man}')
        return names_from_man(man)
    names=[]
    for man in sorted((KIT/'props').glob('manifest_h*.json')):
        names += names_from_man(man)
    return names

def prop_names(only=None, batch=None):
    names=all_manifests(batch=batch)
    if only:
        want=set(only)
        names=[n for n in names if n in want] or list(only)
    return names

def find_glb(name):
    hits=list((KIT/'props'/'house').rglob(f'prop_{name}_clean_near.glb'))
    return hits[0] if hits else None

def composite(names=None, out=None, title=None, batch=None):
    from PIL import Image, ImageDraw, ImageFont
    names = names or prop_names(batch=batch)
    out = Path(out) if out else OUT
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 18)
        font_s = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
    except Exception:
        font = font_s = ImageFont.load_default()
    label_h = 32
    pad = 8
    cols = 6
    rows = math.ceil(len(names)/cols)
    cell_w, cell_h = TILE+pad, TILE+label_h+pad
    W = cols*cell_w + pad
    H = rows*cell_h + pad + 36
    sheet = Image.new('RGB', (W,H), (32,34,36))
    dr = ImageDraw.Draw(sheet)
    dr.text((pad, 8), title or 'house decor  —  3/4 close-up, ~80% fill, no figure', fill=(230,230,226), font=font)
    missing=[]
    for i,n in enumerate(names):
        p = TILE_DIR/f'{n}.png'
        r,c = divmod(i, cols)
        x = pad + c*cell_w
        y = 36 + pad + r*cell_h
        if p.exists():
            im = Image.open(p).convert('RGB')
            if im.size!=(TILE,TILE):
                im = im.resize((TILE,TILE), Image.Resampling.LANCZOS)
            sheet.paste(im, (x, y))
        else:
            missing.append(n)
            dr.rectangle((x,y,x+TILE,y+TILE), fill=(20,20,22))
        dr.text((x, y+TILE+6), n, fill=(220,220,216), font=font_s)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, quality=90, optimize=True, subsampling=0)
    print('wrote', out, sheet.size, out.stat().st_size, 'missing', missing or 0)

def render_tiles(names=None):
    import bpy
    from mathutils import Vector
    names = names or prop_names()
    TILE_DIR.mkdir(parents=True, exist_ok=True)
    # factory file starts with a cube; a tight 80% frame would photograph its face
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for me in list(bpy.data.meshes):
        if me.users==0: bpy.data.meshes.remove(me)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = SAMPLES
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 4
    sc.render.film_transparent = False
    sc.view_settings.view_transform = 'AgX'
    sc.view_settings.look = 'None'
    sc.render.threads_mode = 'FIXED'
    sc.render.threads = 2
    sc.render.resolution_x = TILE
    sc.render.resolution_y = TILE
    sc.render.image_settings.file_format = 'PNG'
    sc.render.film_transparent = False

    w = bpy.data.worlds.get('W') or bpy.data.worlds.new('W')
    sc.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes['Background']
    bg.inputs[0].default_value = (0.55, 0.58, 0.62, 1)
    bg.inputs[1].default_value = 0.55

    # studio lights
    def add_sun(name, energy, rot):
        sun = bpy.data.lights.new(name, 'SUN')
        sun.energy = energy
        sun.angle = 0.18
        so = bpy.data.objects.new(name, sun)
        sc.collection.objects.link(so)
        so.rotation_euler = rot
        return so
    add_sun('key', 3.4, (math.radians(50), 0, math.radians(-40)))
    add_sun('fill', 0.9, (math.radians(20), 0, math.radians(50)))
    add_sun('rim', 0.6, (math.radians(15), 0, math.radians(180)))

    cam = bpy.data.cameras.new('detail_cam')
    cam.type = 'ORTHO'
    cam_ob = bpy.data.objects.new('detail_cam', cam)
    sc.collection.objects.link(cam_ob)
    sc.camera = cam_ob

    ground = None

    def clear_imported(keep):
        for o in list(bpy.data.objects):
            if o not in keep:
                bpy.data.objects.remove(o, do_unlink=True)
        for me in list(bpy.data.meshes):
            if me.users == 0:
                bpy.data.meshes.remove(me)
        for img in list(bpy.data.images):
            if img.users == 0:
                bpy.data.images.remove(img)

    keep = {cam_ob, *sc.objects}  # lights + cam + world empty? objects currently in scene
    keep = set(bpy.data.objects)

    yaw = math.radians(38)
    pitch = math.radians(24)

    for i, name in enumerate(names):
        glb = find_glb(name)
        if glb is None or not glb.exists():
            print('MISSING', glb, flush=True)
            continue
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=str(glb))
        imported = [o for o in bpy.data.objects if o not in before]
        if not imported:
            print('IMPORT_EMPTY', name, flush=True)
            continue
        # world bbox of all imported mesh objects
        pts=[]
        for o in imported:
            if o.type!='MESH':
                continue
            for c in o.bound_box:
                pts.append(o.matrix_world @ Vector(c))
        if not pts:
            print('NO_MESH', name, flush=True)
            clear_imported(keep)
            continue
        mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        target = (mn+mx)*0.5
        size = mx-mn
        # rugs and other wide flat pieces: a shallow 24° pitch fits the long
        # side to 80% and leaves large short-side margins. Steepen so the
        # face fills the square tile, still in 3/4.
        if size.z < 0.15 and max(size.x, size.y) > 0.6:
            yaw_i, pitch_i = math.radians(28), math.radians(52)
        else:
            yaw_i, pitch_i = yaw, pitch
        diag = size.length
        dist = max(3.0, diag*4.0)
        loc = target + Vector((
            dist * math.sin(yaw_i) * math.cos(pitch_i),
            -dist * math.cos(yaw_i) * math.cos(pitch_i),
            dist * math.sin(pitch_i),
        ))
        cam_ob.location = loc
        cam_ob.rotation_euler = (target - loc).to_track_quat('-Z', 'Y').to_euler()
        bpy.context.view_layer.update()
        inv = cam_ob.matrix_world.inverted()
        cam_pts = [inv @ p for p in pts]
        ext = max(max(p.x for p in cam_pts)-min(p.x for p in cam_pts),
                  max(p.y for p in cam_pts)-min(p.y for p in cam_pts))
        cam.ortho_scale = max(ext, 1e-4) / FILL

        # small ground under the prop (helps table pieces read)
        if ground is not None:
            bpy.data.objects.remove(ground, do_unlink=True)
            ground = None
        span = max(mx.x-mn.x, mx.y-mn.y, 0.05)*6
        bpy.ops.mesh.primitive_plane_add(size=1, location=(target.x, target.y, mn.z-0.0005))
        ground = bpy.context.active_object
        ground.scale = (span, span, 1)
        gm = bpy.data.materials.get('detail_ground') or bpy.data.materials.new('detail_ground')
        gm.use_nodes = True
        gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.40, 0.39, 0.36, 1)
        gm.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 0.7
        if gm.name not in [m.name for m in ground.data.materials]:
            ground.data.materials.clear()
            ground.data.materials.append(gm)
        keep_now = keep | {ground, cam_ob}

        out = TILE_DIR/f'{name}.png'
        sc.render.filepath = str(out)
        bpy.ops.render.render(write_still=True)
        print(f'RENDERED {i+1}/{len(names)} {name}  ext={ext:.3f}  scale={cam.ortho_scale:.3f}', flush=True)

        # remove imported + ground for the next prop (keep lights/cam)
        for o in list(imported):
            if o.name in bpy.data.objects:
                bpy.data.objects.remove(o, do_unlink=True)
        if ground is not None:
            bpy.data.objects.remove(ground, do_unlink=True)
            ground = None
        for me in list(bpy.data.meshes):
            if me.users==0: bpy.data.meshes.remove(me)
        for img in list(bpy.data.images):
            if img.users==0: bpy.data.images.remove(img)

    print('tiles written to', TILE_DIR)


def _parse(args):
    out=title=batch=None
    names=[]
    skip=set()
    i=0
    while i<len(args):
        a=args[i]
        if a in ('--composite','composite','--render','render'):
            i+=1; continue
        if a=='--out' and i+1<len(args):
            out=args[i+1]; i+=2; continue
        if a=='--title' and i+1<len(args):
            title=args[i+1]; i+=2; continue
        if a=='--batch' and i+1<len(args):
            batch=args[i+1]; i+=2; continue
        names.append(a); i+=1
    return names,out,title,batch

if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else sys.argv[1:]
    names,out,title,batch=_parse(args)
    if batch and not names:
        names=prop_names(batch=batch)
    if 'bpy' in sys.modules and '--composite' not in args:
        render_tiles(names or None)
        try:
            composite(names=names or None, out=out, title=title, batch=batch)
        except Exception as e:
            print('composite deferred:', e)
    else:
        flags=[a for a in args if a.startswith('--') or a in ('composite','render')]
        if args and not names and not batch and '--composite' not in args and 'composite' not in args:
            sys.exit('usage: python3 h_detail.py --composite [--batch hfurn] [--out path] [--title text] [names...]')
        composite(names=names or None, out=out, title=title, batch=batch)
