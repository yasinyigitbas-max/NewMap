"""blender -b -P vrender.py -- <out_dir> <vehicle> [<vehicle> ...]
Imports veh_<name>.glb as the game gets it (proves the URIs and the node pivots), tints the paint as car_paint.gdshader
does (colour x paint where the map's alpha is 1), and renders: front 3/4, rear 3/4, and all openings open."""
import bpy, sys, os, math, json
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
argv = sys.argv[sys.argv.index('--') + 1:]
OUT = argv[0]
os.makedirs(OUT, exist_ok=True)
man = json.load(open(os.path.join(ROOT, 'vehicles', 'manifest_vehicles.json')))
names = argv[1:] or list(man)
PAINTS = [(0.55, 0.06, 0.05), (0.08, 0.16, 0.38), (0.6, 0.6, 0.62), (0.05, 0.05, 0.055), (0.75, 0.75, 0.73)]
sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.samples = int(os.environ.get('V_SAMPLES', '32'))
sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = 960, 600
sc.view_settings.view_transform = 'AgX'
sc.render.film_transparent = False


def setup():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    wd = bpy.data.worlds.new('W'); sc.world = wd; wd.use_nodes = True
    wd.node_tree.nodes['Background'].inputs[0].default_value = (0.58, 0.62, 0.68, 1)
    wd.node_tree.nodes['Background'].inputs[1].default_value = 0.8
    bpy.ops.mesh.primitive_plane_add(size=80)
    gm = bpy.data.materials.new('g'); gm.use_nodes = True
    gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.25, 0.25, 0.26, 1)
    bpy.context.object.data.materials.append(gm)
    ld = bpy.data.lights.new('sun', 'SUN'); ld.energy = 3.0; ld.angle = math.radians(8)
    lo = bpy.data.objects.new('sun', ld); sc.collection.objects.link(lo); lo.rotation_euler = (math.radians(45), 0, math.radians(40))
    cd = bpy.data.cameras.new('c'); cd.lens = 45
    cam = bpy.data.objects.new('c', cd); sc.collection.objects.link(cam); sc.camera = cam
    return cam


def tint(paint):
    for m in bpy.data.materials:
        if not m.use_nodes or not m.name.startswith('veh_'):
            continue
        nt = m.node_tree
        bsdf = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        tex = next((n for n in nt.nodes if n.type == 'TEX_IMAGE' and n.image and n.image.name.endswith('_color.png')), None)
        if not bsdf or not tex:
            continue
        for l in list(bsdf.inputs['Base Color'].links):
            nt.links.remove(l)
        for l in list(bsdf.inputs['Alpha'].links):
            nt.links.remove(l)
        gt = nt.nodes.new('ShaderNodeMath'); gt.operation = 'GREATER_THAN'; gt.inputs[1].default_value = 0.75
        nt.links.new(tex.outputs['Alpha'], gt.inputs[0])
        mx = nt.nodes.new('ShaderNodeMix'); mx.data_type = 'RGBA'; mx.blend_type = 'MULTIPLY'
        nt.links.new(gt.outputs[0], mx.inputs[0]); nt.links.new(tex.outputs['Color'], mx.inputs[6])
        mx.inputs[7].default_value = (*paint, 1)
        nt.links.new(mx.outputs[2], bsdf.inputs['Base Color'])
        if m.name.endswith('_glass'):
            bsdf.inputs['Alpha'].default_value = 0.55
            m.surface_render_method = 'BLENDED' if hasattr(m, 'surface_render_method') else m.blend_method


for vi, name in enumerate(names):
    cam = setup()
    bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT, 'vehicles', 'veh_%s.glb' % name))
    tint(PAINTS[vi % len(PAINTS)])
    objs = {o.name: o for o in bpy.data.objects}
    sz = man[name]['size']
    Lg = max(sz[1], sz[0] * 2)

    def shot(fn, d, tgt=None):
        d = Vector(d).normalized()
        t = Vector(tgt or (0, 0, sz[2] * 0.45))
        cam.location = t + d * Lg * 1.35
        cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
        sc.render.filepath = os.path.join(OUT, '%s_%s.png' % (name, fn))
        bpy.ops.render.render(write_still=True)
    shot('front', (-0.9, -1.0, 0.42))
    shot('rear', (-0.8, 1.0, 0.45))
    for n, o in objs.items():
        o.rotation_mode = 'XYZ'
        if n.startswith('door'):
            s = 1 if '_l' in n[-2:] else -1
            o.rotation_euler.z += s * math.radians(-62)
        elif n == 'bonnet':
            o.rotation_euler.x += math.radians(-55)
        elif n in ('boot', 'tailgate'):
            o.rotation_euler.x += math.radians(70)
        elif n.startswith('back_door'):
            s = 1 if n.endswith('_l') else -1
            o.rotation_euler.z += s * math.radians(100)
    shot('open', (-1.0, -0.55, 0.65))
    print('RENDERED', name)
